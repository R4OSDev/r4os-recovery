//! Full replacement is a RecoveryTools workflow. GPT, FAT32, NTFS and
//! BIOS publication use shared SDK owners through one whole-device claim.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const tools = r4os.storage_tools;
const block = tools.io;
const setup = tools.installation;
const packages = @import("package_session.zig");
const selection = @import("selection.zig");
const targets = @import("targets.zig");

pub const Installer = struct {
    session: *packages.Session,
    target: r4os.storage_tools_guest.Target,
    layout: setup.Layout,
    boot: tools.fat32_image.Prepared,
    recovery: tools.fat32_image.Prepared,
    data: packages.source.Target,
    work: []u8,
    before: []u8,
    table: *tools.partition.Plan,
    own_source: bool,
    progress: block.Progress = .{},
    native_error: i32 = 0,
    phase: []const u8 = "Preparing installation",
    complete: bool = false,

    pub fn prepare(session: *packages.Session, catalog: *const selection.Catalog, selected: usize) !Installer {
        if (selected >= catalog.targets.items.len) return error.InvalidTarget;
        const selected_target = catalog.targets.items[selected];
        const disk = catalog.disks.items[selected_target.disk];
        if (selected_target.operation != .install or !targets.allowed(catalog.boot, disk, .install)) return error.InvalidTarget;
        const a = session.arena.allocator();
        const prepared = session.prepared orelse return error.PackageMissing;
        try packages.source.verifyInstallation(a, prepared, session.tree.?, session.pool.pump);
        var entropy: [7][16]u8 = undefined;
        if (!r4os.web_crypto.fillSecureRandom(std.mem.asBytes(&entropy))) return error.EntropyUnavailable;
        const ids = try setup.Identifiers.fromEntropy(entropy);
        const layout = try setup.Layout.prepare(disk.info.sector_count, disk.info.sector_bytes, ids);
        const manifest = try layout.manifest(a, prepared.system.?.releaseVersion, prepared.system.?.kernelVersion, prepared.system.?.bootFiles);
        const config = try layout.limineConfig(a, .local);
        var boot_files: std.ArrayList(tools.fat32_image.File) = .empty;
        for (prepared.system.?.bootFiles) |path| {
            const outer = try std.fmt.allocPrint(a, "BOOT/{s}", .{path});
            try boot_files.append(a, .{ .path = path, .bytes = prepared.archive.get(outer).? });
        }
        try boot_files.append(a, .{ .path = "boot/r4os-installation.json", .bytes = manifest });
        try boot_files.append(a, .{ .path = "boot/limine.conf", .bytes = config });
        const boot_range = layout.part(.BOOT);
        try session.pool.pump.run("Preparing BOOT file tree", 0, 0);
        // Retain the Distribution label: older valid release kernels do not
        // distinguish a BOOT volume label from the boot directory on lookup.
        const boot = try tools.fat32_image.prepare(a, boot_range.count, boot_range.first, "R4OS BOOT", serial32(ids.partitions[1]), boot_files.items);
        var recovery_files: std.ArrayList(tools.fat32_image.File) = .empty;
        for ([_][]const u8{ "CURRENT", "PREVIOUS" }) |slot| {
            try recovery_files.append(a, .{ .path = try std.fmt.allocPrint(a, "{s}/manifest.json", .{slot}), .bytes = prepared.recovery_archive.manifest });
            for (prepared.recovery.files) |file| try recovery_files.append(a, .{
                .path = try std.fmt.allocPrint(a, "{s}/{s}", .{ slot, file.path }),
                .bytes = prepared.recovery_archive.get(file.path).?,
            });
        }
        try recovery_files.append(a, .{ .path = "INSTALL/RELEASE.ZIP", .bytes = prepared.archive.original });
        const recovery_range = layout.part(.RECOVERY);
        try session.pool.pump.run("Preparing Recovery slots and original ZIP", 0, 0);
        const recovery = try tools.fat32_image.prepare(a, recovery_range.count, recovery_range.first, "RECOVERY", serial32(ids.partitions[3]), recovery_files.items);
        try @import("capacity.zig").requireCacheHeadroom((recovery.stats.geometry.sectors - recovery.stats.used_sectors) * @as(u64, 512), prepared.archive.original.len, prepared.recovery_archive.original.len, recovery.stats.geometry.sectors_per_cluster * @as(u64, 512));
        const system_range = layout.part(.SYSTEM);
        try session.targetSystem(system_range.first, system_range.count, serial64(ids.partitions[2]));
        const data_range = layout.part(.DATA);
        var data_builder = try tools.ntfs.Builder.init(a, data_range.count * 512, "DATA", @intCast(data_range.first), tools.standardNtfsMetadata(), 0, serial64(ids.partitions[4]));
        for ([_][]const u8{ "DOCS", "MEDIA", "TEMP" }) |name| _ = try data_builder.addDirectory(data_builder.root(), name);
        const data_plan = try data_builder.prepare();
        var result = Installer{
            .session = session,
            .target = .{ .storage = .{ .sys = session.sys }, .target = r4os.storage.Context.wholeDevice(disk.info) },
            .layout = layout,
            .boot = boot,
            .recovery = recovery,
            .data = .{ .builder = data_builder, .plan = data_plan },
            .work = try a.alloc(u8, block.scratch_bytes),
            .before = try a.alloc(u8, 67 * 512),
            .table = try a.create(tools.partition.Plan),
            .own_source = targets.sameDevice(catalog.boot.?.device, disk.info.reference),
        };
        // Every source, including the original ZIP, and every write-plan
        // buffer now resides in pinned RAM. Only bounded I/O follows.
        try catalog.revalidate(session.sys, selected);
        const source_device = result.target.device(null);
        try source_device.read(0, result.before[0 .. 34 * 512]);
        try source_device.read(source_device.sectors - 33, result.before[34 * 512 ..]);
        return result;
    }

    fn checkpoint(raw: ?*anyopaque, _: block.Phase, written: u64) bool {
        const self: *Installer = @ptrCast(@alignCast(raw.?));
        self.session.pool.pump.run(self.phase, written, self.layout.sectors) catch return false;
        return true;
    }
    fn device(self: *Installer) block.Device {
        var result = self.target.device(&self.progress);
        result.cancel_context = self;
        result.continue_fn = checkpoint;
        return result;
    }
    fn region(self: *Installer, role: setup.Role) block.Region {
        const range = self.layout.part(role);
        return .{ .parent = self.device(), .first = range.first, .count = range.count };
    }
    fn release(self: *Installer) !void {
        const deadline = self.session.sys.ticks() + self.session.sys.ticksFromMilliseconds(2000);
        while (true) {
            self.native_error = self.target.release(self.progress.write_attempted);
            if (self.native_error != abi.storage_error_busy or self.session.sys.ticks() >= deadline) break;
            self.session.sys.taskYield();
        }
        if (self.native_error != abi.storage_result_ok) return error.TargetRelease;
    }
    pub fn execute(self: *Installer) !void {
        self.native_error = self.target.acquire();
        if (self.native_error != abi.storage_result_ok) return error.TargetBusy;
        errdefer {
            self.complete = false;
            self.progress.verified = false;
            if (self.target.claim != 0) self.release() catch {};
        }
        const disk = self.device();
        self.phase = "Checking exclusive target identity";
        try disk.read(0, self.work[0 .. 34 * 512]);
        if (!std.mem.eql(u8, self.work[0 .. 34 * 512], self.before[0 .. 34 * 512])) return error.StorageChanged;
        try disk.read(disk.sectors - 33, self.work[0 .. 33 * 512]);
        if (!std.mem.eql(u8, self.work[0 .. 33 * 512], self.before[34 * 512 ..])) return error.StorageChanged;
        self.phase = "Replacing the partition table";
        try tools.partition.clean(disk, false, self.work);
        // The new BIOS extent can overlap an old filesystem's first sector.
        // This full-replacement workflow owns erasing that extent explicitly.
        const bios = self.layout.part(.BIOSBOOT);
        try disk.fill(bios.first, bios.count, 0, self.work);
        try disk.flush();
        self.table.* = try tools.partition.Plan.read(disk, self.work);
        try self.layout.bind(self.table);
        try self.table.commit(disk, self.work);
        var boot_region = self.region(.BOOT);
        self.phase = "Installing and verifying BOOT";
        try self.boot.execute(try boot_region.device(), false, self.work);
        var system_region = self.region(.SYSTEM);
        self.phase = "Installing and verifying SYSTEM";
        try self.session.target.?.plan.execute(try system_region.device(), false, self.work);
        var recovery_region = self.region(.RECOVERY);
        self.phase = "Installing Recovery and the original ZIP";
        try self.recovery.execute(try recovery_region.device(), false, self.work);
        var data_region = self.region(.DATA);
        self.phase = "Preparing and verifying fresh DATA";
        try self.data.plan.execute(try data_region.device(), false, self.work);
        self.phase = "Installing and verifying the BIOS boot chain";
        self.table.* = try tools.partition.Plan.read(disk, self.work);
        try tools.limine.installBios(disk, self.table, self.work);
        try disk.flush();
        self.phase = "Publishing the new volumes";
        try self.release();
        try self.mountAndVerify();
        self.complete = true;
        self.progress.verified = true;
        self.progress.phase = .complete;
    }

    fn mountAndVerify(self: *Installer) !void {
        const storage = self.target.storage;
        var inv = abi.StorageInventory{};
        if (storage.inventory(&inv) != abi.storage_result_ok) return error.TargetRemount;
        var info = abi.StorageDeviceInfo{};
        if (storage.device(inv.generation, self.target.target.device.slot, &info) != abi.storage_result_present or
            !targets.sameDevice(info.reference, self.target.target.device) or !setup.guid.eql(info.disk_guid, self.layout.ids.disk) or info.partition_slots != 5) return error.TargetRemount;
        var parts: [5]abi.StorageTarget = undefined;
        for (&parts, 0..) |*part, i| {
            var actual = abi.StoragePartitionInfo{};
            if (storage.partition(inv.generation, &info.reference, @intCast(i), &actual) != abi.storage_result_present or
                !setup.guid.eql(actual.target.partition_guid, self.layout.ids.partitions[i]) or !setup.guid.eql(actual.type_guid, setup.Layout.typeGuid(@enumFromInt(i))) or
                actual.target.first_lba != self.layout.ranges[i].first or actual.target.sector_count != self.layout.ranges[i].count) return error.TargetRemount;
            if (i != 0 and actual.filesystem != (if (i == 1 or i == 3) @as(u32, abi.storage_filesystem_fat32) else abi.storage_filesystem_ntfs)) return error.TargetRemount;
            part.* = actual.target;
        }
        var cache_letter: u8 = 0;
        for ([_]usize{ 3, 1, 2, 4 }) |i| {
            var mounted = abi.StorageVolumeRef{};
            self.native_error = storage.mount(&parts[i], if (i == 3 and self.own_source) 'R' else 0, &mounted);
            if (self.native_error != abi.storage_result_ok or storage.inventory(&inv) != abi.storage_result_ok) return error.TargetRemount;
            var volume = abi.StorageVolumeInfo{};
            if (storage.volume(inv.generation, mounted.slot, &volume) != abi.storage_result_present or
                !std.meta.eql(mounted, volume.reference) or !targets.sameTarget(parts[i], volume.target)) return error.TargetRemount;
            if (i == 3) cache_letter = @intCast(volume.letter);
        }
        var path_buffer: [64]u8 = undefined;
        const path = try std.fmt.bufPrintZ(&path_buffer, "{c}:\\INSTALL\\RELEASE.ZIP", .{cache_letter});
        var lease: u64 = 0;
        if (storage.useBegin(path, &lease) != abi.storage_result_ok) return error.TargetRemount;
        defer _ = storage.useEnd(&lease);
        const file = self.session.sys.fileInfo(path) orelse return error.TargetRemount;
        if (file.size != self.session.prepared.?.archive.original.len) return error.TargetVerify;
        var hash = std.crypto.hash.sha2.Sha256.init(.{});
        var offset: usize = 0;
        while (offset < file.size) {
            const amount = @min(self.work.len, file.size - offset);
            if (self.session.sys.fileReadAt(path, @intCast(offset), self.work[0..amount]) != amount) return error.TargetVerify;
            hash.update(self.work[0..amount]);
            offset += amount;
            // Once all writes finished, Escape cannot turn cleanup into a
            // second mutation; still render and yield during this check.
            self.session.pool.pump.run("Checking the installed original ZIP", offset, file.size) catch {};
        }
        if (!std.mem.eql(u8, &hash.finalResult(), &self.session.original_digest)) return error.TargetVerify;
    }
};
fn serial32(id: [16]u8) u32 {
    return std.mem.readInt(u32, id[0..4], .little);
}
fn serial64(id: [16]u8) u64 {
    return std.mem.readInt(u64, id[0..8], .little);
}

pub fn message(err: anyerror, wrote: bool) []const u8 {
    if (wrote) return switch (err) {
        error.TargetRemount, error.TargetRelease => "The target was written, but volume publication failed. Recovery is still running in RAM. Restart Recovery before using this target.",
        error.Cancelled => "Installation stopped after writing began. The target is incomplete. Recovery is still running in RAM.",
        else => "Installation failed after writing began. The target is incomplete. Recovery is still running in RAM; see the diagnostic log.",
    };
    return switch (err) {
        error.TargetBusy => "The target is busy, changed or unavailable. Close its SSH/FTP transfers and try again. No installation writes made.",
        error.StorageChanged, error.InvalidTarget => "The target changed. Select it again. No installation writes made.",
        error.ImageFull, error.RecoveryCapacity => "RECOVERY cannot hold these slots, the original ZIP and update workspace. No installation writes made.",
        error.EntropyUnavailable => "Fresh installation identifiers could not be generated. No installation writes made.",
        else => packages.message(err),
    };
}
