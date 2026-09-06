const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const tools = r4os.storage_tools;
const packages = @import("package_session.zig");
const targets = @import("targets.zig");
const selection = @import("selection.zig");
const state = @import("recovery_state.zig");
const slots = @import("recovery_slots.zig");
const GuestTarget = r4os.storage_tools_guest.Target;
pub const Updater = struct {
    session: *packages.Session,
    target: GuestTarget,
    disk: GuestTarget,
    table: *tools.partition.Plan,
    plan: slots.Plan,
    work: []u8,
    own_source: bool,
    progress: tools.io.Progress = .{},
    phase: []const u8 = "Preparing Recovery update",
    native_error: i32 = 0,
    complete: bool = false,

    pub fn prepare(session: *packages.Session, catalog: *const selection.Catalog, selected: usize) !Updater {
        if (selected >= catalog.targets.items.len) return error.InvalidTarget;
        const choice = catalog.targets.items[selected];
        const disk = catalog.disks.items[choice.disk];
        const installed = catalog.installed.items[choice.installed orelse return error.InvalidTarget];
        if (choice.operation != .recovery or installed.ambiguous or !targets.allowed(catalog.boot, disk, .recovery)) return error.InvalidTarget;
        const own_source = targets.sameDevice(catalog.boot.?.device, disk.info.reference);
        const a = session.arena.allocator();
        const storage = r4os.storage.Context{ .sys = session.sys };
        var target = GuestTarget{ .storage = storage, .target = installed.parts[3] };
        if (target.target.sector_count > 1024 * 2048) return error.SlotSize;
        // Unknown boot slot must never allow rotation of the running fallback.
        var running_previous = false;
        if (own_source) {
            var facts: [state.maximum]u8 = undefined;
            const size = session.sys.fileRead("C:\\R4OS\\CONFIG\\RECBOOT.R4S", &facts);
            const boot = if (size > 0 and size <= facts.len) state.Boot.parse(facts[0..@intCast(size)]) catch null else null;
            running_previous = if (boot) |b| b.previous or !state.guid.eql(b.disk, disk.info.disk_guid) or !state.guid.eql(b.partition, target.target.partition_guid) else true;
        }
        const original = try a.alloc(u8, @intCast(target.target.sector_count * 512));
        const reader = target.device(null);
        var done: usize = 0;
        while (done < original.len) {
            const amount = @min(original.len - done, tools.io.scratch_bytes);
            try reader.read(done / 512, original[done..][0..amount]);
            done += amount;
            try session.pool.pump.run("Reading RECOVERY and preserving INSTALL", done, original.len);
        }
        var result = Updater{ .session = session, .target = target, .disk = .{ .storage = storage, .target = r4os.storage.Context.wholeDevice(disk.info) },
            .table = try a.create(tools.partition.Plan), .plan = try slots.Plan.prepare(a, original, target.target.first_lba, installed.manifest.installation_id, session.prepared.?, running_previous, session.pool.pump),
            .work = try a.alloc(u8, tools.io.scratch_bytes), .own_source = own_source };
        result.table.* = try tools.partition.Plan.read(result.disk.device(null), result.work);
        try catalog.revalidate(session.sys, selected);
        return result;
    }
    fn checkpoint(raw: ?*anyopaque, _: tools.io.Phase, written: u64) bool {
        const self: *Updater = @ptrCast(@alignCast(raw.?));
        self.session.pool.pump.run(self.phase, written, self.target.target.sector_count) catch return false;
        return true;
    }
    fn device(self: *Updater) tools.io.Device {
        var result = self.target.device(&self.progress);
        result.cancel_context = self;
        result.continue_fn = checkpoint;
        return result;
    }
    fn release(self: *Updater, keep: bool) !void {
        const deadline = self.session.sys.ticks() + self.session.sys.ticksFromMilliseconds(2000);
        while (true) {
            const rc = self.target.release(keep);
            if (rc == abi.storage_result_ok) return;
            if (rc != abi.storage_error_busy or self.session.sys.ticks() >= deadline) {
                self.native_error = rc;
                return error.TargetRelease;
            }
            self.session.sys.taskYield();
        }
    }
    pub fn execute(self: *Updater) !void {
        self.native_error = self.target.acquire();
        if (self.native_error != abi.storage_result_ok) return error.TargetBusy;
        errdefer {
            self.progress.verified = false;
            self.release(self.progress.write_attempted) catch {};
        }
        try self.table.revalidate(self.disk.device(null), self.work);
        if (self.plan.previous) |previous| {
            self.phase = "Saving confirmed CURRENT to PREVIOUS";
            self.session.sys.write("[RECOVERYUPDATE] previous=BEGIN\r\n");
            try previous.execute(self.device(), self.work);
            self.session.sys.write("[RECOVERYUPDATE] previous=VERIFIED current=UNCHANGED\r\n");
            self.progress.verified = false;
        } else self.session.sys.write("[RECOVERYUPDATE] previous=PRESERVED\r\n");
        self.phase = "Replacing CURRENT and recording unconfirmed state";
        self.session.sys.write("[RECOVERYUPDATE] current=BEGIN\r\n");
        try self.plan.current.execute(self.device(), self.work);
        self.phase = "Mounting verified Recovery volume";
        try self.release(false);
        try self.mount();
        self.progress.verified = true;
        self.progress.phase = .complete;
        self.complete = true;
    }
    fn mount(self: *Updater) !void {
        const storage = self.target.storage;
        var inv = abi.StorageInventory{};
        if (storage.inventory(&inv) != abi.storage_result_ok) return error.TargetRemount;
        var part = abi.StoragePartitionInfo{};
        if (storage.partition(inv.generation, &self.target.target.device, @intCast(self.target.target.partition_number - 1), &part) != abi.storage_result_present or
            !state.guid.eql(part.target.partition_guid, self.target.target.partition_guid) or part.target.first_lba != self.target.target.first_lba or
            part.target.sector_count != self.target.target.sector_count or part.filesystem != abi.storage_filesystem_fat32) return error.TargetRemount;
        for (0..inv.volume_slots) |i| {
            var volume = abi.StorageVolumeInfo{};
            const rc = storage.volume(inv.generation, @intCast(i), &volume);
            if (rc < 0) return error.TargetRemount;
            if (rc > 0 and targets.sameTarget(volume.target, part.target)) {
                if (self.own_source and volume.letter != 'R') return error.TargetRemount;
                return;
            }
        }
        var ref = abi.StorageVolumeRef{};
        self.native_error = storage.mount(&part.target, if (self.own_source) 'R' else 0, &ref);
        if (self.native_error != abi.storage_result_ok) return error.TargetRemount;
    }
};
pub fn message(err: anyerror, wrote: bool) []const u8 {
    if (wrote) return "Recovery update is incomplete. The running session is still in RAM. Restart using the fixed Previous entry; use an external USB if the shared filesystem is damaged.";
    return switch (err) {
        error.PreviousUnavailable => "PREVIOUS is damaged or incomplete and CURRENT is unconfirmed. Restore a complete fallback package before updating.",
        error.TargetBusy => "RECOVERY is busy or changed. Close its SSH/FTP transfers and select it again. No update writes made.",
        error.ImageFull, error.SlotSize => "Both Recovery slots and the preserved INSTALL cache do not fit. No update writes made.",
        error.SourceChanged, error.StorageChanged => "The selected Recovery changed. Select it again. No update writes made.",
        error.SourceFat, error.SourceAllocation => "RECOVERY has an unsupported or damaged FAT filesystem. No update writes made.",
        else => packages.message(err),
    };
}
