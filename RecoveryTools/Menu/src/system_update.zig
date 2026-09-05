//! Recovery application workflow: replace SYSTEM at its existing geometry
//! and publish matching BOOT files. No writer can address DATA or RECOVERY.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const tools = r4os.storage_tools;
const block = tools.io;
const setup = tools.installation;
const packages = @import("package_session.zig");
const selection = @import("selection.zig");
const targets = @import("targets.zig");
const boot_config = @import("boot_config.zig");
const GuestTarget = r4os.storage_tools_guest.Target;

pub const Updater = struct {
    session: *packages.Session,
    disk: GuestTarget,
    boot: GuestTarget,
    system: GuestTarget,
    layout: setup.Layout,
    boot_plan: tools.fat32_update.Prepared,
    table: *tools.partition.Plan,
    work: []u8,
    manifest_hash: [32]u8,
    progress: block.Progress = .{},
    native_error: i32 = 0,
    phase: []const u8 = "Preparing system update",
    complete: bool = false,

    pub fn prepare(session: *packages.Session, catalog: *const selection.Catalog, selected: usize) !Updater {
        if (selected >= catalog.targets.items.len) return error.InvalidTarget;
        const selected_target = catalog.targets.items[selected];
        const disk = catalog.disks.items[selected_target.disk];
        const installed = catalog.installed.items[selected_target.installed orelse return error.InvalidTarget];
        if (selected_target.operation != .system or installed.ambiguous or session.target == null or
            !targets.allowed(catalog.boot, disk, .system)) return error.InvalidTarget;
        const a = session.arena.allocator();
        const prepared = session.prepared orelse return error.PackageMissing;
        try packages.source.verifyInstallation(a, prepared, session.tree.?, session.pool.pump);
        var layout = setup.Layout{
            .sectors = disk.info.sector_count,
            .ids = .{ .installation = installed.manifest.installation_id, .disk = installed.manifest.disk_guid, .partitions = undefined },
            .ranges = undefined,
        };
        for (installed.parts, 0..) |part, i| {
            layout.ids.partitions[i] = part.partition_guid;
            layout.ranges[i] = .{ .first = part.first_lba, .count = part.sector_count };
        }
        try layout.ids.validate();
        const storage = r4os.storage.Context{ .sys = session.sys };
        var boot = GuestTarget{ .storage = storage, .target = installed.parts[1] };
        if (boot.target.sector_count > 1024 * 2048) return error.BootVolumeSize;
        const original = try a.alloc(u8, @intCast(boot.target.sector_count * 512));
        const reader = boot.device(null);
        var offset: usize = 0;
        while (offset < original.len) {
            const amount = @min(original.len - offset, block.scratch_bytes);
            try reader.read(offset / 512, original[offset..][0..amount]);
            offset += amount;
            try session.pool.pump.run("Reading existing BOOT", offset, original.len);
        }
        const view = try tools.fat32_view.View.init(original, boot.target.first_lba);
        const old_manifest = try view.readFile(a, "boot/r4os-installation.json", targets.installation.max_bytes);
        var old_hash: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(old_manifest, &old_hash, .{});
        if (!std.mem.eql(u8, &old_hash, &installed.hash)) return error.StorageChanged;
        const config = try view.readFile(a, "boot/limine.conf", 64 * 1024);
        try boot_config.verify(config, layout.ids.partitions[1]);
        const manifest = try layout.manifest(a, prepared.system.?.releaseVersion, prepared.system.?.kernelVersion, prepared.system.?.bootFiles);
        var changes: std.ArrayList(tools.fat32_update.Change) = .empty;
        for (prepared.system.?.bootFiles) |path| {
            const outer = try std.fmt.allocPrint(a, "BOOT/{s}", .{path});
            try changes.append(a, .{ .path = path, .bytes = prepared.archive.get(outer).? });
        }
        try changes.append(a, .{ .path = "boot/r4os-installation.json", .bytes = manifest });
        try session.pool.pump.run("Preparing changes to BOOT files", 0, 0);
        const boot_plan = try tools.fat32_update.prepare(a, original, boot.target.first_lba, changes.items);
        var result = Updater{
            .session = session,
            .boot = boot,
            .system = .{ .storage = storage, .target = installed.parts[2] },
            .disk = .{ .storage = storage, .target = r4os.storage.Context.wholeDevice(disk.info) },
            .layout = layout,
            .boot_plan = boot_plan,
            .table = try a.create(tools.partition.Plan),
            .work = try a.alloc(u8, block.scratch_bytes),
            .manifest_hash = undefined,
        };
        std.crypto.hash.sha2.Sha256.hash(manifest, &result.manifest_hash, .{});
        result.table.* = try tools.partition.Plan.read(result.disk.device(null), result.work);
        try tools.limine.verifyBios(result.disk.device(null), result.table, result.work);
        // All buffers are resident before either exclusive claim is opened.
        try catalog.revalidate(session.sys, selected);
        return result;
    }
    fn checkpoint(raw: ?*anyopaque, _: block.Phase, written: u64) bool {
        const self: *Updater = @ptrCast(@alignCast(raw.?));
        self.session.pool.pump.run(self.phase, written, self.boot.target.sector_count + self.system.target.sector_count) catch return false;
        return true;
    }
    fn device(self: *Updater, target: *GuestTarget) block.Device {
        var result = target.device(&self.progress);
        result.cancel_context = self;
        result.continue_fn = checkpoint;
        return result;
    }
    fn releaseOne(self: *Updater, target: *GuestTarget, keep: bool) !void {
        const deadline = self.session.sys.ticks() + self.session.sys.ticksFromMilliseconds(2000);
        while (true) {
            self.native_error = target.release(keep);
            if (self.native_error != abi.storage_error_busy or self.session.sys.ticks() >= deadline) break;
            self.session.sys.taskYield();
        }
        if (self.native_error != abi.storage_result_ok) return error.TargetRelease;
    }
    pub fn execute(self: *Updater) !void {
        self.native_error = self.boot.acquire();
        if (self.native_error != abi.storage_result_ok) return error.TargetBusy;
        errdefer {
            self.complete = false;
            self.progress.verified = false;
            // A write failure may leave either filesystem incomplete. Keep
            // both offline; errors before the first write restore old mounts.
            self.releaseOne(&self.system, self.progress.write_attempted) catch {};
            self.releaseOne(&self.boot, self.progress.write_attempted) catch {};
        }
        self.native_error = self.system.acquire();
        if (self.native_error != abi.storage_result_ok) return error.TargetBusy;
        self.phase = "Checking exclusive SYSTEM and BOOT identity";
        // These whole-device reads address GPT/BIOS sectors outside both
        // claims. They confer no whole-device write authority.
        try tools.limine.verifyBios(self.device(&self.disk), self.table, self.work);
        try self.boot_plan.checkSource(self.device(&self.boot), self.work);
        self.phase = "Replacing and verifying SYSTEM";
        try self.session.target.?.plan.execute(self.device(&self.system), false, self.work);
        self.phase = "Updating and verifying BOOT files";
        try self.boot_plan.execute(self.device(&self.boot), self.work);
        self.phase = "Publishing updated SYSTEM and BOOT";
        try self.releaseOne(&self.system, false);
        try self.releaseOne(&self.boot, false);
        try self.mountAndVerify();
        self.complete = true;
        self.progress.verified = true;
        self.progress.phase = .complete;
    }
    fn mountAndVerify(self: *Updater) !void {
        const storage = self.boot.storage;
        var inv = abi.StorageInventory{};
        if (storage.inventory(&inv) != abi.storage_result_ok) return error.TargetRemount;
        var info = abi.StorageDeviceInfo{};
        if (storage.device(inv.generation, self.disk.target.device.slot, &info) != abi.storage_result_present or
            !targets.sameDevice(info.reference, self.disk.target.device) or !setup.guid.eql(info.disk_guid, self.layout.ids.disk) or
            info.sector_count != self.layout.sectors) return error.TargetRemount;
        var parts: [5]abi.StorageTarget = undefined;
        for (&parts, 0..) |*part, i| {
            var found = false;
            for (0..info.partition_slots) |slot| {
                var actual = abi.StoragePartitionInfo{};
                if (storage.partition(inv.generation, &info.reference, @intCast(slot), &actual) != abi.storage_result_present) return error.TargetRemount;
                if (!setup.guid.eql(actual.target.partition_guid, self.layout.ids.partitions[i])) continue;
                if (found or !setup.guid.eql(actual.type_guid, setup.Layout.typeGuid(@enumFromInt(i))) or
                    actual.target.first_lba != self.layout.ranges[i].first or actual.target.sector_count != self.layout.ranges[i].count) return error.TargetRemount;
                if ((i == 1 and actual.filesystem != abi.storage_filesystem_fat32) or
                    (i == 2 and actual.filesystem != abi.storage_filesystem_ntfs)) return error.TargetRemount;
                found = true;
                part.* = actual.target;
            }
            if (!found) return error.TargetRemount;
        }
        var boot_letter: u8 = 0;
        for ([_]usize{ 1, 2 }) |i| {
            var mounted: ?abi.StorageVolumeInfo = null;
            if (storage.inventory(&inv) != abi.storage_result_ok) return error.TargetRemount;
            for (0..inv.volume_slots) |slot| {
                var actual = abi.StorageVolumeInfo{};
                const present = storage.volume(inv.generation, @intCast(slot), &actual);
                if (present < 0) return error.TargetRemount;
                if (present > 0 and targets.sameTarget(parts[i], actual.target)) mounted = actual;
            }
            if (mounted == null) {
                var reference = abi.StorageVolumeRef{};
                self.native_error = storage.mount(&parts[i], 0, &reference);
                if (self.native_error != abi.storage_result_ok or storage.inventory(&inv) != abi.storage_result_ok) return error.TargetRemount;
                var actual = abi.StorageVolumeInfo{};
                if (storage.volume(inv.generation, reference.slot, &actual) != abi.storage_result_present or
                    !std.meta.eql(reference, actual.reference) or !targets.sameTarget(parts[i], actual.target)) return error.TargetRemount;
                mounted = actual;
            }
            if (i == 1) boot_letter = @intCast(mounted.?.letter);
        }
        var buffer: [80]u8 = undefined;
        const path = try std.fmt.bufPrintZ(&buffer, "{c}:\\boot\\r4os-installation.json", .{boot_letter});
        var lease: u64 = 0;
        if (storage.useBegin(path, &lease) != abi.storage_result_ok) return error.TargetRemount;
        defer _ = storage.useEnd(&lease);
        const info_file = self.session.sys.fileInfo(path) orelse return error.TargetVerify;
        if (info_file.size == 0 or info_file.size > targets.installation.max_bytes) return error.TargetVerify;
        const bytes = self.work[0..@intCast(info_file.size)];
        if (self.session.sys.fileRead(path, bytes) != bytes.len) return error.TargetVerify;
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
        if (!std.mem.eql(u8, &digest, &self.manifest_hash)) return error.TargetVerify;
    }
};

pub fn message(err: anyerror, wrote: bool) []const u8 {
    if (wrote) return switch (err) {
        error.TargetRelease, error.TargetRemount, error.TargetVerify => "SYSTEM and BOOT were written, but final verification or mounting failed. Restart Recovery before using the target.",
        else => "The system update stopped after writing began and is incomplete. Recovery is still running in RAM. See the diagnostic log.",
    };
    return switch (err) {
        error.TargetBusy => "SYSTEM or BOOT is busy, changed or unavailable. Close its SSH/FTP transfers and try again. No update writes made.",
        error.StorageChanged, error.SourceChanged, error.InvalidTarget => "The selected installation changed. Select it again. No update writes made.",
        error.IncompatibleBootChain => "The installed BIOS loader does not match this Recovery's supported Limine version. No update writes made.",
        error.IncompatibleBootConfig => "The existing Limine configuration does not reference the expected R4OS kernel and preload files. No update writes made.",
        error.ImageFull, error.BootVolumeSize => "The BOOT update cannot fit the existing volume. No update writes made.",
        error.SourceFat, error.SourceAllocation, error.SourceFileMissing => "BOOT has an unsupported or damaged filesystem. No update writes made.",
        else => packages.message(err),
    };
}
