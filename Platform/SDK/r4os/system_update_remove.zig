//! Application removal owned by SYSUPD, using the same SYSLOCK lease.
//! This is an original-file/installed-inventory operation, never a directory
//! sweep, dependency resolver or library/kernel uninstall policy.
const std = @import("std");
const r = @import("r4os");
const manifest = r.r4u_manifest;
const assets = @import("system_update_asset_system.zig");
pub const Plan = struct {
    schema: u32 = 1,
    request_id: []const u8,
    target: []const u8,
    name: []const u8,
    version: []const u8,
    previous: assets.Digest,

    pub fn validate(self: Plan) !void {
        if (self.schema != 1 or self.request_id.len != 64 or
            !manifest.paths.applicationTarget(self.target) or
            !manifest.validToken(self.name, manifest.component_name_max_bytes) or
            !manifest.validSemanticVersion(self.version) or self.previous.size == 0 or
            self.previous.size > std.math.maxInt(u32)) return error.RemovePlan;
        for (self.request_id) |byte| if (!std.ascii.isHex(byte)) return error.RemovePlan;
        for (self.previous.sha256) |byte| if (!std.ascii.isHex(byte)) return error.RemovePlan;
    }
    pub fn same(self: Plan, other: Plan) bool {
        return self.schema == other.schema and std.mem.eql(u8, self.request_id, other.request_id) and
            manifest.targetEquals(self.target, other.target) and
            std.ascii.eqlIgnoreCase(self.name, other.name) and std.mem.eql(u8, self.version, other.version) and
            std.meta.eql(self.previous, other.previous);
    }
};
pub const Phase = enum { prepared, payload_removed, inventory_removed, completed, cancelled };
pub const Record = struct {
    schema: u32 = 1,
    generation: u64 = 0,
    plan: Plan,
    phase: Phase = .prepared,
    inventory_before: ?assets.Digest = null,
    inventory_after: ?assets.Digest = null,
    pub fn terminal(self: Record) bool {
        return self.phase == .completed or self.phase == .cancelled;
    }
    pub fn validate(self: Record) !void {
        if (self.schema != 1 or self.generation == 0 or (self.inventory_before == null) != (self.inventory_after == null)) return error.RemoveJournal;
        try self.plan.validate();
    }
};
pub const State = enum { waiting_for_close, removed, cancelled };
pub const Outcome = struct { state: State, generation: u64 };

/// The real owner and narrow fault fixtures use the same operation ordering.
/// The caller holds SYSLOCK across this whole invocation. A durable original
/// request and the native compare/delete gate settle an ambiguous reply.
pub fn execute(io: anytype, plan: Plan) !Outcome {
    try plan.validate();
    var record = (try io.load()) orelse Record{ .plan = plan };
    if (try io.history(plan.request_id)) |prior| {
        if (!prior.plan.same(plan)) return error.RemoveRequestChanged;
        if (prior.phase == .cancelled) return .{ .state = .cancelled, .generation = prior.generation };
        if (!try io.absent(plan) or !try io.inventoryAbsent(plan)) return error.RemoveTargetReappeared;
        return .{ .state = .removed, .generation = prior.generation };
    }
    if (!record.plan.same(plan)) {
        if (!record.terminal()) return error.RemoveForeignTransaction;
        try io.archive(record);
        record = .{ .generation = record.generation, .plan = plan };
    } else if (record.terminal()) {
        if (record.phase == .cancelled) return .{ .state = .cancelled, .generation = record.generation };
        if (!try io.absent(plan) or !try io.inventoryAbsent(plan)) return error.RemoveTargetReappeared;
        return .{ .state = .removed, .generation = record.generation };
    }
    if (record.generation == 0 or !try io.recordExists(plan.request_id)) {
        // Actual embedded identity, whole SHA and the exact inventory entry.
        // No destructive operation can precede this durable admission.
        try io.admit(plan);
        try io.persist(&record);
    }
    if (record.phase == .prepared) {
        if (io.cancelled() and !try io.absent(plan)) {
            record.phase = .cancelled;
            try io.persist(&record);
            return .{ .state = .cancelled, .generation = record.generation };
        }
        if (try io.running(plan)) return .{ .state = .waiting_for_close, .generation = record.generation };
        if (!try io.absent(plan)) {
            try io.admit(plan);
            if (try io.running(plan)) return .{ .state = .waiting_for_close, .generation = record.generation };
            try io.delete(plan); // Atomic size/checksum/filesystem identity gate.
        }
        if (!try io.absent(plan)) return error.RemoveReadback;
        record.phase = .payload_removed;
        try io.persist(&record);
    }
    if (record.phase == .payload_removed) {
        if (!try io.absent(plan)) return error.RemoveTargetReappeared;
        // Preserve every other current component, including changes made by
        // an older administrator between a crash and this explicit resume.
        try io.removeInventory(&record);
        record.phase = .inventory_removed;
        try io.persist(&record);
    }
    if (!try io.absent(plan) or !try io.inventoryAbsent(plan)) return error.RemoveReadback;
    record.phase = .completed;
    try io.persist(&record);
    return .{ .state = .removed, .generation = record.generation };
}

const slots = [_][*:0]const u8{ "C:\\R4OS\\UPDATE\\STAGED\\REMOVE0.JRN", "C:\\R4OS\\UPDATE\\STAGED\\REMOVE1.JRN" };
const history_root = "C:\\R4OS\\UPDATE\\REMOVED";
const inventory_path = "C:\\R4OS\\CONFIG\\MODULES.JSON";
const inventory_stage = "C:\\R4OS\\CONFIG\\RMVINV.NEW";
const inventory_backup = "C:\\R4OS\\CONFIG\\RMVINV.BAK";
const record_limit = 16384;
const Envelope = struct { schema: u32 = 1, payload: []const u8, sha256: []const u8 };
fn hash(bytes: []const u8) [64]u8 {
    var hashed: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &hashed, .{});
    return std.fmt.bytesToHex(hashed, .lower);
}
fn digest(bytes: []const u8) assets.Digest {
    var checksum: u32 = 2166136261;
    for (bytes) |byte| checksum = (checksum ^ byte) *% 16777619;
    return .{ .size = bytes.len, .sha256 = hash(bytes), .checksum = checksum };
}
pub const Native = struct {
    ctx: *const r.r4sys.Context,
    arena: std.heap.ArenaAllocator,
    stop: ?*const r.app_contract.StopFlag = null,
    pub fn init(ctx: *const r.r4sys.Context, stop: ?*const r.app_contract.StopFlag) Native {
        return .{ .ctx = ctx, .arena = .init(ctx.allocator()), .stop = stop };
    }
    pub fn deinit(self: *Native) void {
        self.arena.deinit();
    }
    fn allocator(self: *Native) std.mem.Allocator {
        return self.arena.allocator();
    }
    fn info(self: *Native, path: []const u8) !?r.abi.FileInfo {
        return assets.info(self.ctx, path);
    }
    fn bytes(self: *Native, path: []const u8, limit: usize) !?[]u8 {
        const actual = (try self.info(path)) orelse return null;
        if (actual.is_dir != 0 or actual.size == 0 or actual.size > limit) return error.RemoveFileSize;
        const raw = try assets.RawPath.init(path);
        const data = try self.allocator().alloc(u8, @intCast(actual.size));
        if (self.ctx.fileRead(raw.asZ(), data) != data.len) return error.RemoveFileRead;
        return data;
    }
    fn write(self: *Native, path: []const u8, data: []const u8) !void {
        const raw = try assets.RawPath.init(path);
        _ = self.ctx.fileWrite(raw.asZ(), data);
        const back = (try self.bytes(path, data.len)) orelse return error.RemoveWriteReadback;
        if (!std.mem.eql(u8, data, back)) return error.RemoveWriteReadback;
    }
    fn encode(self: *Native, record: Record) ![]u8 {
        const payload = try std.json.Stringify.valueAlloc(self.allocator(), record, .{});
        const sha = hash(payload);
        return std.json.Stringify.valueAlloc(self.allocator(), Envelope{ .payload = payload, .sha256 = &sha }, .{});
    }
    fn decode(self: *Native, data: []const u8) !Record {
        // All parse allocations remain in this invocation's arena; returned
        // record strings are never loans to a freed temporary parse arena.
        const outer = try std.json.parseFromSlice(Envelope, self.allocator(), data, .{ .allocate = .alloc_always });
        if (outer.value.schema != 1 or !std.mem.eql(u8, &hash(outer.value.payload), outer.value.sha256)) return error.RemoveJournal;
        const inner = try std.json.parseFromSlice(Record, self.allocator(), outer.value.payload, .{ .allocate = .alloc_always });
        try inner.value.validate();
        return inner.value;
    }
    pub fn load(self: *Native) !?Record {
        var newest: ?Record = null;
        var invalid = false;
        for (slots) |path| {
            const data = (self.bytes(std.mem.span(path), record_limit) catch |err| {
                if (err != error.RemoveFileSize) return err;
                invalid = true;
                continue;
            }) orelse continue;
            const candidate = self.decode(data) catch |err| {
                if (err == error.OutOfMemory) return err;
                invalid = true;
                continue;
            };
            if (newest == null or candidate.generation > newest.?.generation) {
                newest = candidate;
            } else if (candidate.generation == newest.?.generation and
                (!candidate.plan.same(newest.?.plan) or candidate.phase != newest.?.phase or
                    !std.meta.eql(candidate.inventory_before, newest.?.inventory_before) or
                    !std.meta.eql(candidate.inventory_after, newest.?.inventory_after))) return error.RemoveJournalConflict;
        }
        if (newest == null and invalid) return error.RemoveJournal;
        return newest;
    }
    pub fn recordExists(self: *Native, id: []const u8) !bool {
        const current = (try self.load()) orelse return false;
        return std.mem.eql(u8, current.plan.request_id, id);
    }
    fn receiptPath(self: *Native, id: []const u8) ![]u8 {
        if (id.len != 64) return error.RemovePlan;
        for (id) |byte| if (!std.ascii.isHex(byte)) return error.RemovePlan;
        return std.fmt.allocPrint(self.allocator(), "{s}\\{s}.JSON", .{ history_root, id });
    }
    pub fn history(self: *Native, id: []const u8) !?Record {
        const data = (try self.bytes(try self.receiptPath(id), record_limit)) orelse return null;
        const record = try self.decode(data);
        if (!record.terminal() or !std.mem.eql(u8, id, record.plan.request_id)) return error.RemoveReceipt;
        return record;
    }
    pub fn archive(self: *Native, record: Record) !void {
        if (!record.terminal()) return error.RemoveReceipt;
        const files = r.Files{ .sys = self.ctx.* };
        try @import("system_update_asset.zig").ensureParents(&files, try r.AbsoluteFilePath.parse(history_root));
        const path = try self.receiptPath(record.plan.request_id);
        if (try self.history(record.plan.request_id)) |old| {
            if (!old.plan.same(record.plan) or old.phase != record.phase) return error.RemoveReceipt;
            return;
        }
        try self.write(path, try self.encode(record));
    }
    pub fn persist(self: *Native, record: *Record) !void {
        if (record.generation == std.math.maxInt(u64)) return error.RemoveGenerationExhausted;
        record.generation += 1;
        try record.validate();
        try self.write(std.mem.span(slots[record.generation % 2]), try self.encode(record.*));
    }
    pub fn cancelled(self: *Native) bool {
        return if (self.stop) |flag| flag.requested() else false;
    }
    pub fn running(self: *Native, plan: Plan) !bool {
        const path = try r.AbsoluteFilePath.parse(plan.target);
        const value = self.ctx.programModuleRunning(path.asZ().ptr);
        if (value < 0) return error.RemoveProcessState;
        return value > 0;
    }
    pub fn absent(self: *Native, plan: Plan) !bool {
        return (try self.info(plan.target)) == null;
    }
    fn inventory(self: *Native) !struct { bytes: []u8, value: *r.system_update_inventory.Inventory } {
        const data = (try self.bytes(inventory_path, r.system_update_inventory.max_bytes)) orelse return error.RemoveInventory;
        const value = try self.allocator().create(r.system_update_inventory.Inventory);
        if (!r.system_update_inventory.Inventory.parse(data, value)) return error.RemoveInventory;
        return .{ .bytes = data, .value = value };
    }
    fn entry(self: *Native, value: *const r.system_update_inventory.Inventory, plan: Plan) !?r.system_update_inventory.Entry {
        _ = self;
        var canonical: [1024]u8 = undefined;
        const target = r.r4u_manifest.canonicalInventoryTarget(&canonical, plan.target) orelse return error.RemoveTarget;
        var found: ?r.system_update_inventory.Entry = null;
        for (value.entries[0..value.count]) |candidate| {
            if (r.r4u_manifest.targetEquals(candidate.target, target) or
                (candidate.kind == .r4x and std.ascii.eqlIgnoreCase(candidate.name, plan.name)))
            {
                if (found != null or candidate.kind != .r4x or !std.ascii.eqlIgnoreCase(candidate.name, plan.name) or
                    !r.r4u_manifest.targetEquals(candidate.target, target) or !std.mem.eql(u8, candidate.version, plan.version)) return error.RemoveInventoryChanged;
                if (candidate.module_role != null) return error.RemoveNotApplication;
                found = candidate;
            }
        }
        return found;
    }
    pub fn inventoryAbsent(self: *Native, plan: Plan) !bool {
        const current = try self.inventory();
        return (try self.entry(current.value, plan)) == null;
    }
    pub fn admit(self: *Native, plan: Plan) !void {
        const current = try self.inventory();
        if ((try self.entry(current.value, plan)) == null) return error.RemoveInventoryMissing;
        const identity = try assets.inspect(self.ctx, plan.target);
        if (identity.kind != .r4x or !std.ascii.eqlIgnoreCase(identity.nameText(), plan.name) or
            !std.mem.eql(u8, identity.versionText(), plan.version)) return error.RemoveIdentityChanged;
        const scratch = try self.allocator().alloc(u8, 64 * 1024);
        if (!std.meta.eql(plan.previous, try assets.digest(self.ctx, plan.target, scratch))) return error.RemoveTargetChanged;
    }
    pub fn delete(self: *Native, plan: Plan) !void {
        const target = try r.AbsoluteFilePath.parse(plan.target);
        if (!self.ctx.hasFn("file_delete_if_match")) return error.RemoveUnsupported;
        const value = self.ctx.fileDeleteIfMatch(target.asZ().ptr, plan.previous.size, plan.previous.checksum);
        if (value < 0) return error.RemoveDeleteConflict;
    }
    fn matched(self: *Native, path: []const u8, expected: assets.Digest) !bool {
        if ((try self.info(path)) == null) return false;
        const scratch = try self.allocator().alloc(u8, 64 * 1024);
        return std.meta.eql(expected, try assets.digest(self.ctx, path, scratch));
    }
    fn cleanup(self: *Native, path: []const u8, expected: assets.Digest) !void {
        if ((try self.info(path)) == null) return;
        if (!try self.matched(path, expected)) return error.RemoveInventoryBackupConflict;
        const raw = try r.AbsoluteFilePath.parse(path);
        if (self.ctx.fileDeleteIfMatch(raw.asZ().ptr, expected.size, expected.checksum) < 0 or
            (try self.info(path)) != null) return error.RemoveInventoryCleanup;
    }
    pub fn removeInventory(self: *Native, record: *Record) !void {
        const current = try self.inventory();
        const current_digest = digest(current.bytes);
        if (record.inventory_after) |after| {
            if (std.meta.eql(after, current_digest)) {
                try self.cleanup(inventory_backup, record.inventory_before.?);
                try self.cleanup(inventory_stage, after);
                return;
            }
            if (record.inventory_before == null or !std.meta.eql(record.inventory_before.?, current_digest)) return error.RemoveInventoryChanged;
        }
        if (try self.entry(current.value, record.plan)) |old| {
            if (!current.value.removeExact(.r4x, old.name, old.target)) return error.RemoveInventoryChanged;
        } else return;
        const buffer = try self.allocator().alloc(u8, r.system_update_inventory.max_bytes);
        const updated = current.value.render(buffer) orelse return error.RemoveInventoryRender;
        const after = digest(updated);
        if (record.inventory_before == null) {
            if ((try self.info(inventory_stage)) != null or (try self.info(inventory_backup)) != null) return error.RemoveInventoryBackupConflict;
            record.inventory_before = current_digest;
            record.inventory_after = after;
            try self.persist(record);
        }
        if ((try self.info(inventory_stage)) == null) try self.write(inventory_stage, updated) else if (!try self.matched(inventory_stage, after)) return error.RemoveInventoryStageConflict;
        const target = try r.AbsoluteFilePath.parse(inventory_path);
        const stage = try r.AbsoluteFilePath.parse(inventory_stage);
        const backup = try r.AbsoluteFilePath.parse(inventory_backup);
        _ = self.ctx.fileReplaceAtomic(target.asZ().ptr, stage.asZ().ptr, backup.asZ().ptr, r.r4sys.file_replace_atomic_flag_consume_stage);
        if (!try self.matched(inventory_path, after)) return error.RemoveInventoryReadback;
        try self.cleanup(inventory_backup, current_digest);
        try self.cleanup(inventory_stage, after);
    }
};
