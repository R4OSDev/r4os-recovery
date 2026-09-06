//! R4OS installation layout and boot references. Both host image creation
//! and guest installation use this owner; physical I/O is supplied by tools.
const std = @import("std");
const partition = @import("partition.zig");
pub const guid = partition.guid;
pub const Role = enum { BIOSBOOT, BOOT, SYSTEM, RECOVERY, DATA };
pub const Medium = enum { local, usb };
pub const standard_bytes: u64 = 2048 * 1024 * 1024;
pub const first_lbas = [_]u64{ 2048, 4096, 266240, 2363392, 3411968 };
// The canonical NTFS builder needs 4096 complete 4-KB clusters plus its
// separately addressed backup boot sector.
pub const minimum_data_sectors: u64 = 16 * 2048 + 1;
pub const boot_paths = [_][]const u8{
    "boot/r4os.elf",           "boot/preload.r4i",        "boot/preload/hidreport.r4p",
    "boot/preload/usbhid.r4p", "boot/preload/usbbot.r4p", "boot/preload/usbscsi.r4p",
    "boot/limine-bios.sys",    "EFI/BOOT/BOOTX64.EFI",
};

pub const Identifiers = struct {
    installation: guid.Guid,
    disk: guid.Guid,
    partitions: [5]guid.Guid,

    /// The caller supplies fresh host/guest entropy. This function applies
    /// the same UUIDv4 bit convention used by R4PART, in GPT field order.
    pub fn fromEntropy(entropy: [7][16]u8) !Identifiers {
        var ids = entropy;
        for (&ids) |*id| {
            id[7] = (id[7] & 15) | 0x40;
            id[8] = (id[8] & 63) | 0x80;
        }
        const result = Identifiers{ .installation = ids[0], .disk = ids[1], .partitions = ids[2..7].* };
        try result.validate();
        return result;
    }
    pub fn validate(self: Identifiers) !void {
        const all = [_]guid.Guid{ self.installation, self.disk } ++ self.partitions;
        for (all, 0..) |id, i| {
            if (guid.isZero(id)) return error.InvalidGuid;
            for (all[0..i]) |other| if (guid.eql(id, other)) return error.DuplicateGuid;
        }
    }
};

pub const Layout = struct {
    sectors: u64,
    ids: Identifiers,
    ranges: [5]partition.Range,

    pub fn prepare(sectors: u64, sector_bytes: u32, ids: Identifiers) !Layout {
        try ids.validate();
        if (sector_bytes != 512 or sectors > std.math.maxInt(u64) / 512 or
            sectors < first_lbas[4] + minimum_data_sectors + 33) return error.Geometry;
        return .{ .sectors = sectors, .ids = ids, .ranges = .{
            .{ .first = first_lbas[0], .count = 2048 },
            .{ .first = first_lbas[1], .count = 128 * 2048 },
            .{ .first = first_lbas[2], .count = 1024 * 2048 },
            .{ .first = first_lbas[3], .count = 512 * 2048 },
            .{ .first = first_lbas[4], .count = sectors - 33 - first_lbas[4] },
        } };
    }
    pub fn part(self: Layout, role: Role) partition.Range {
        return self.ranges[@intFromEnum(role)];
    }
    pub fn typeGuid(role: Role) guid.Guid {
        return switch (role) {
            .BIOSBOOT => partition.bios_type,
            .BOOT => partition.esp_type,
            else => partition.basic_type,
        };
    }
    /// Bind a newly read blank table to the prepared geometry. CLEAN and its
    /// confirmation/claim belong to the caller; commit retains the existing
    /// table fingerprint and performs its normal stale-source check.
    pub fn bind(self: Layout, table: *partition.Plan) !void {
        if (table.sectors != self.sectors or table.kind != .none or !table.blank or
            !std.meta.eql(self, try prepare(self.sectors, 512, self.ids))) return error.Geometry;
        try table.initializeGpt(self.ids.disk);
        inline for (std.meta.fields(Role)) |field| {
            const role: Role = @enumFromInt(field.value);
            const range = self.part(role);
            _ = try table.add(.{ .present = true, .first = range.first, .count = range.count, .type_guid = typeGuid(role), .unique_guid = self.ids.partitions[field.value], .name = try partition.asciiName(field.name) });
        }
    }

    pub fn manifest(self: Layout, allocator: std.mem.Allocator, release: []const u8, kernel: []const u8, files: []const []const u8) ![]u8 {
        if (!version(release) or !version(kernel) or files.len == 0 or files.len > 32) return error.Manifest;
        for (files, 0..) |file, i| {
            if (!bootPath(file)) return error.BootPath;
            for (files[0..i]) |other| if (std.ascii.eqlIgnoreCase(file, other)) return error.DuplicateBootPath;
        }
        const Part = struct { partitionGuid: []const u8, typeGuid: []const u8, firstLba: u64, sectorCount: u64 };
        var ids: [5][36]u8 = undefined;
        var types: [5][36]u8 = undefined;
        var parts: [5]Part = undefined;
        inline for (std.meta.fields(Role)) |field| {
            const i = field.value;
            ids[i] = guid.format(self.ids.partitions[i]);
            types[i] = guid.format(typeGuid(@enumFromInt(i)));
            parts[i] = .{ .partitionGuid = &ids[i], .typeGuid = &types[i], .firstLba = self.ranges[i].first, .sectorCount = self.ranges[i].count };
        }
        const installation_id = guid.format(self.ids.installation);
        const disk_id = guid.format(self.ids.disk);
        return std.json.Stringify.valueAlloc(allocator, .{
            .schema = @as(u32, 1),
            .logicalSectorBytes = @as(u32, 512),
            .installationId = @as([]const u8, &installation_id),
            .diskGuid = @as([]const u8, &disk_id),
            .partitions = .{ .BIOSBOOT = parts[0], .BOOT = parts[1], .SYSTEM = parts[2], .RECOVERY = parts[3], .DATA = parts[4] },
            .bootFiles = files,
            .releaseVersion = release,
            .kernelVersion = kernel,
        }, .{ .whitespace = .indent_2 });
    }

    /// Written only on initial installation or USB preparation. Existing
    /// limine.conf is preserved by system and Recovery updates.
    pub fn limineConfig(self: Layout, allocator: std.mem.Allocator, medium: Medium) ![]u8 {
        try self.ids.validate();
        const boot = guid.format(self.ids.partitions[@intFromEnum(Role.BOOT)]);
        const recovery = guid.format(self.ids.partitions[@intFromEnum(Role.RECOVERY)]);
        return std.fmt.allocPrint(allocator, "timeout: 5\ndefault_entry: {d}\n\n/R4OS\n    protocol: limine\n    path: guid({s}):/boot/r4os.elf\n" ++
            "    module_path: guid({s}):/boot/preload.r4i\n    module_string: r4os.preload.image=PRELOAD.R4I\n" ++
            "    module_path: guid({s}):/boot/preload/hidreport.r4p\n    module_string: r4os.preload.usb-r4p=HIDREPORT\n" ++
            "    module_path: guid({s}):/boot/preload/usbhid.r4p\n    module_string: r4os.preload.usb-r4p=USBHID\n" ++
            "    module_path: guid({s}):/boot/preload/usbbot.r4p\n    module_string: r4os.preload.usb-r4p=USBBOT\n" ++
            "    module_path: guid({s}):/boot/preload/usbscsi.r4p\n    module_string: r4os.preload.usb-r4p=USBSCSI\n" ++
            "    resolution: 1280x720x32\n\n/R4OS Recovery\n    protocol: limine\n" ++
            "    path: guid({s}):/CURRENT/recovery.elf\n    module_path: guid({s}):/CURRENT/runtime.img\n" ++
            "    module_string: recovery.runtime=1\n    resolution: 1280x720x32\n\n/R4OS Recovery Previous\n    protocol: limine\n" ++
            "    path: guid({s}):/PREVIOUS/recovery.elf\n    module_path: guid({s}):/PREVIOUS/runtime.img\n" ++
            "    module_string: recovery.runtime=1\n    resolution: 1280x720x32\n", .{ @as(u8, if (medium == .local) 1 else 2), boot, boot, boot, boot, boot, boot, recovery, recovery, recovery, recovery });
    }
};

fn version(text: []const u8) bool {
    if (text.len == 0 or text.len > 63) return false;
    const parsed = std.SemanticVersion.parse(text) catch return false;
    return parsed.pre == null and parsed.build == null;
}
pub fn bootPath(path: []const u8) bool {
    if (path.len == 0 or path.len > 255) return false;
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |part| {
        if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..") or std.ascii.eqlIgnoreCase(part, "limine.conf")) return false;
        if (part[part.len - 1] == '.' or part[part.len - 1] == ' ') return false;
        for (part) |c| if (c < 32 or c > 126 or std.mem.indexOfScalar(u8, "<>:\"\\|?*", c) != null) return false;
    }
    return true;
}
