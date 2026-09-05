const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
pub const model = @import("targets.zig");
const os = @import("os_probe.zig");

pub const Catalog = struct {
    allocator: std.mem.Allocator,
    generation: u64,
    boot: ?model.Boot = null,
    disks: std.ArrayList(model.Disk) = .empty,
    installed: std.ArrayList(model.Installed) = .empty,
    targets: std.ArrayList(model.Target) = .empty,
    excluded_installations: usize = 0,

    pub fn deinit(self: *Catalog) void {
        for (self.disks.items) |disk| self.allocator.free(disk.partitions);
        self.disks.deinit(self.allocator);
        self.installed.deinit(self.allocator);
        self.targets.deinit(self.allocator);
    }
    fn diskIndex(self: *const Catalog, reference: abi.StorageDeviceRef) ?usize {
        for (self.disks.items, 0..) |disk, i| if (model.sameDevice(disk.info.reference, reference)) return i;
        return null;
    }
    pub fn scan(sys: *const r4os.r4sys.Context, operation: model.Operation) !Catalog {
        const storage = r4os.storage.Context{ .sys = sys };
        var inv = abi.StorageInventory{};
        if (storage.inventory(&inv) != abi.storage_result_ok) return error.StorageUnavailable;
        if (inv.device_slots > 16 or inv.volume_slots > 27) return error.InventoryLimit;
        var result = Catalog{ .allocator = sys.allocator(), .generation = inv.generation };
        errdefer result.deinit();
        for (0..inv.device_slots) |i| {
            var info = abi.StorageDeviceInfo{};
            const got = storage.device(inv.generation, @intCast(i), &info);
            if (got < 0) return error.StorageChanged;
            if (got == 0 or info.flags & abi.storage_device_ram != 0) continue;
            if (info.partition_slots > 128) return error.InventoryLimit;
            var parts: std.ArrayList(abi.StoragePartitionInfo) = .empty;
            defer parts.deinit(result.allocator);
            for (0..info.partition_slots) |p| {
                var part = abi.StoragePartitionInfo{};
                const present = storage.partition(inv.generation, &info.reference, @intCast(p), &part);
                if (present < 0) return error.StorageChanged;
                if (present > 0) try parts.append(result.allocator, part);
            }
            const owned = try parts.toOwnedSlice(result.allocator);
            errdefer result.allocator.free(owned);
            try result.disks.append(result.allocator, .{ .info = info, .partitions = owned });
        }
        var volumes: [27]abi.StorageVolumeInfo = undefined;
        var volume_count: usize = 0;
        for (0..inv.volume_slots) |i| {
            var volume = abi.StorageVolumeInfo{};
            const got = storage.volume(inv.generation, @intCast(i), &volume);
            if (got < 0) return error.StorageChanged;
            if (got == 0) continue;
            volumes[volume_count] = volume;
            volume_count += 1;
            // Kernel binds R: only after validating the actual Limine source.
            if (volume.letter == 'R') {
                const disk = result.diskIndex(volume.target.device) orelse return error.BootSourceUnknown;
                if (result.boot != null) return error.BootSourceUnknown;
                result.boot = .{ .device = volume.target.device, .usb = result.disks.items[disk].info.bus == abi.storage_bus_usb };
            }
        }
        for (volumes[0..volume_count]) |volume| {
            const disk_index = result.diskIndex(volume.target.device) orelse continue;
            const disk = &result.disks.items[disk_index];
            if (result.boot) |source| {
                if (!source.usb and disk.info.bus == abi.storage_bus_usb) continue;
            }
            if (volume.letter < 'A' or volume.letter > 'Z' or volume.flags & abi.storage_volume_claimed != 0 or
                (volume.filesystem != abi.storage_filesystem_fat32 and volume.filesystem != abi.storage_filesystem_ntfs)) continue;
            var reader = VolumeReader{ .sys = sys, .letter = @intCast(volume.letter) };
            const root = reader.path("") orelse continue;
            var lease: u64 = 0;
            if (storage.useBegin(root, &lease) != abi.storage_result_ok) continue;
            defer _ = storage.useEnd(&lease);
            var actual = abi.StorageVolumeInfo{};
            if (storage.volume(inv.generation, volume.reference.slot, &actual) != abi.storage_result_present or
                !std.meta.eql(volume.reference, actual.reference) or !model.sameTarget(volume.target, actual.target)) return error.StorageChanged;
            const probe = os.Probe{ .context = &reader, .read_at = VolumeReader.readAt, .entry = VolumeReader.entry };
            disk.systems.merge(probe.detect());
            const manifest = reader.manifest(result.allocator) catch |err| {
                if (err == error.OutOfMemory) return err;
                disk.invalid_manifest = true;
                continue;
            } orelse continue;
            const bound = model.bind(disk.*, volume, manifest.value) orelse {
                disk.invalid_manifest = true;
                continue;
            };
            disk.systems.r4os = true;
            try result.installed.append(result.allocator, .{ .disk = disk_index, .manifest = manifest.value, .hash = manifest.hash, .boot = volume, .parts = bound });
        }
        model.flagAmbiguities(result.disks.items, result.installed.items);
        if (operation == .install) {
            for (result.disks.items, 0..) |disk, i| if (model.allowed(result.boot, disk, operation)) {
                try result.targets.append(result.allocator, .{ .operation = operation, .disk = i });
            };
        } else {
            for (result.installed.items, 0..) |installed, i| {
                if (installed.ambiguous or !model.allowed(result.boot, result.disks.items[installed.disk], operation)) {
                    result.excluded_installations += 1;
                    continue;
                }
                try result.targets.append(result.allocator, .{ .operation = operation, .disk = installed.disk, .installed = i });
            }
            for (result.disks.items) |disk| if (disk.invalid_manifest) {
                result.excluded_installations += 1;
            };
        }
        var end = abi.StorageInventory{};
        if (storage.inventory(&end) != abi.storage_result_ok or end.generation != inv.generation) return error.StorageChanged;
        return result;
    }

    // Re-run both identity and manifest validation. Later mutation owners must
    // revalidate once more under their exclusive claims before the first write.
    pub fn revalidate(self: *const Catalog, sys: *const r4os.r4sys.Context, selected: usize) !void {
        if (selected >= self.targets.items.len) return error.InvalidTarget;
        const target = self.targets.items[selected];
        var fresh = try scan(sys, target.operation);
        defer fresh.deinit();
        if (fresh.generation != self.generation or !std.meta.eql(fresh.boot, self.boot)) return error.StorageChanged;
        for (fresh.targets.items) |candidate| {
            if (!model.unchanged(self.disks.items[target.disk], fresh.disks.items[candidate.disk])) continue;
            if (!model.sameTarget(model.affected(target, self.disks.items, self.installed.items), model.affected(candidate, fresh.disks.items, fresh.installed.items))) continue;
            if (target.installed) |old_index| {
                const before = self.installed.items[old_index];
                const after = fresh.installed.items[candidate.installed orelse continue];
                if (!std.mem.eql(u8, &before.hash, &after.hash) or !std.meta.eql(before.boot.reference, after.boot.reference)) continue;
            }
            return;
        }
        return error.StorageChanged;
    }
};

const VolumeReader = struct {
    sys: *const r4os.r4sys.Context,
    letter: u8,
    buffer: [512]u8 = undefined,
    fn path(self: *VolumeReader, relative: []const u8) ?[:0]u8 {
        return std.fmt.bufPrintZ(&self.buffer, "{c}:\\{s}", .{ self.letter, relative }) catch null;
    }
    fn readAt(ctx: *anyopaque, relative: []const u8, offset: u32, out: []u8) ?usize {
        const self: *VolumeReader = @ptrCast(@alignCast(ctx));
        const full = self.path(relative) orelse return null;
        const result = self.sys.fileReadAt(full, offset, out);
        if (result < 0 or result > out.len) return null;
        return @intCast(result);
    }
    fn entry(ctx: *anyopaque, relative: []const u8, index: u32, out: []u8) ?[]const u8 {
        const self: *VolumeReader = @ptrCast(@alignCast(ctx));
        const full = self.path(relative) orelse return null;
        @memset(out, 0);
        const result = self.sys.dirEntry(full, index + 2, out);
        if (result < 0 or result == r4os.r4sys.dir_entry_result_end) return null;
        const text = std.mem.sliceTo(out, 0);
        const start = if (std.mem.lastIndexOfAny(u8, text, "\\/")) |i| i + 1 else 0;
        return text[start..];
    }
    fn manifest(self: *VolumeReader, allocator: std.mem.Allocator) !?struct { value: model.installation.Manifest, hash: [32]u8 } {
        const full = self.path("boot\\r4os-installation.json") orelse return error.Path;
        const info = self.sys.fileInfo(full) orelse return null;
        if (info.exists == 0) return null;
        if (info.is_dir != 0 or info.size == 0 or info.size > model.installation.max_bytes) return error.InvalidManifest;
        const bytes = try allocator.alloc(u8, @intCast(info.size));
        defer allocator.free(bytes);
        if (self.sys.fileRead(full, bytes) != bytes.len) return error.ManifestRead;
        const value = try model.installation.parse(allocator, bytes);
        var hash: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(bytes, &hash, .{});
        return .{ .value = value, .hash = hash };
    }
};
