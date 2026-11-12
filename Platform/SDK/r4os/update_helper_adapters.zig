//! Concrete specializations only; all transaction, format and I/O policy
//! remains in the original update/storage owners.
const std = @import("std");
const a = @import("r4os_contract").abi;
const data = @import("data_helper_adapters.zig");
const tools = @import("storage_tools.zig");
const recovery = @import("system_update_recovery.zig");
const backup = @import("system_update_backup.zig");
const cb = @import("update_callback_bridge.zig");
pub const Error = error{MissingCallback};
pub const Replay = struct {
    table: *const cb.Table,
    pub fn persist(self: *Replay, journal: *recovery.TransactionJournal) bool {
        return cb.pointer(*const fn (*const cb.Table, *recovery.TransactionJournal) bool, 0, .journal_persist)(self.table, journal);
    }
    pub fn rollbackPayload(self: *Replay, payload: *const recovery.JournalPayload) recovery.MutationStatus {
        return cb.pointer(*const fn (*const cb.Table, *const recovery.JournalPayload) recovery.MutationStatus, 0, .payload_rollback)(self.table, payload);
    }
    pub fn commitPayload(self: *Replay, payload: *const recovery.JournalPayload) recovery.MutationStatus {
        return cb.pointer(*const fn (*const cb.Table, *const recovery.JournalPayload) recovery.MutationStatus, 0, .payload_commit)(self.table, payload);
    }
    pub fn cleanupPayload(self: *Replay, payload: *const recovery.JournalPayload) recovery.MutationStatus {
        return cb.pointer(*const fn (*const cb.Table, *const recovery.JournalPayload) recovery.MutationStatus, 0, .payload_cleanup)(self.table, payload);
    }
    pub fn pathState(self: *Replay, path: []const u8, size: u64, checksum: u32) recovery.PathState {
        return cb.pointer(*const fn (*const cb.Table, []const u8, u64, u32) recovery.PathState, 0, .path_state)(self.table, path, size, checksum);
    }
    pub fn presence(self: *Replay, path: []const u8) recovery.PresenceState {
        return cb.pointer(*const fn (*const cb.Table, []const u8) recovery.PresenceState, 0, .path_presence)(self.table, path);
    }
};
fn require(table: *const cb.Table, comptime kinds: anytype) Error!void {
    inline for (kinds) |kind| if (!table.has(kind)) return error.MissingCallback;
}
pub fn checkLastGood(table: *const cb.Table, journal: *const recovery.TransactionJournal) Error!recovery.ReplayStatus {
    try require(table, .{ .path_state, .path_presence });
    var io: Replay = .{ .table = table };
    return recovery.checkLastGood(&io, journal);
}
pub fn rollbackToTerminal(table: *const cb.Table, journal: *recovery.TransactionJournal) Error!recovery.ReplayStatus {
    try require(table, .{ .journal_persist, .payload_rollback });
    var io: Replay = .{ .table = table };
    return recovery.rollbackToTerminal(&io, journal);
}
pub fn resumeBatchForward(table: *const cb.Table, journal: *recovery.TransactionJournal) Error!recovery.ReplayStatus {
    try require(table, .{ .journal_persist, .payload_commit, .path_state });
    var io: Replay = .{ .table = table };
    return recovery.resumeBatchForward(&io, journal);
}
pub fn cleanupToTerminal(table: *const cb.Table, journal: *recovery.TransactionJournal) Error!recovery.ReplayStatus {
    try require(table, .{ .journal_persist, .payload_cleanup, .path_state, .path_presence });
    var io: Replay = .{ .table = table };
    return recovery.cleanupToTerminal(&io, journal);
}
const Archive = struct {
    table: *const cb.Table,
    fn step(self: *Archive, comptime kind: cb.Kind) bool {
        return cb.pointer(*const fn (*const cb.Table) bool, 0, kind)(self.table);
    }
    pub fn unreferenced(self: *Archive) bool {
        return self.step(.archive_unreferenced);
    }
    pub fn copy(self: *Archive) bool {
        return self.step(.archive_copy);
    }
    pub fn verify(self: *Archive) bool {
        return self.step(.archive_verify);
    }
    pub fn remove(self: *Archive) bool {
        return self.step(.archive_remove);
    }
};
pub fn archive(table: *const cb.Table) (Error || backup.Error)!void {
    try require(table, .{ .archive_unreferenced, .archive_copy, .archive_verify, .archive_remove });
    var io: Archive = .{ .table = table };
    try backup.archive(&io);
}
pub fn referenced(journal: *const recovery.TransactionJournal, path: []const u8) bool {
    return backup.referenced(journal, path);
}
pub fn device(table: *const cb.Table, sectors: u64, exclusive: bool, progress: ?*tools.io.Progress) Error!tools.io.Device {
    try require(table, .{ .block_read, .block_write, .block_flush });
    return .{ .context = @ptrCast(@constCast(table)), .sectors = sectors, .exclusive = exclusive, .progress = progress, .read_fn = cb.pointer(@FieldType(tools.io.Device, "read_fn"), 0, .block_read), .write_fn = cb.pointer(@FieldType(tools.io.Device, "write_fn"), 0, .block_write), .flush_fn = cb.pointer(@FieldType(tools.io.Device, "flush_fn"), 0, .block_flush), .cancel_context = @ptrCast(@constCast(table)), .continue_fn = if (table.has(.block_continue)) cb.pointer(@typeInfo(@FieldType(tools.io.Device, "continue_fn")).optional.child, 0, .block_continue) else null };
}
pub const SourceError = error{ SourceBounds, ReadFailed, SourceRead, Cancelled, Io };
fn readSource(context: *const anyopaque, at: usize, out: []u8) anyerror!void {
    return cb.pointer(*const fn (*const anyopaque, usize, []u8) SourceError!void, 0, .source_read)(context, at, out);
}
pub fn source(table: *const cb.Table, length: usize) Error!tools.byte_source.Source {
    try require(table, .{.source_read});
    return .{ .context = @ptrCast(table), .length = length, .read_fn = readSource };
}
pub fn guestTarget(output: *@import("storage_tools_guest.zig").Target, ctx: *const data.Context, target: a.StorageTarget) void {
    output.* = .{ .storage = .{ .sys = &ctx.system }, .target = target };
}
const Reader = struct {
    source: tools.byte_source.Source,
    pub fn readAt(self: Reader, offset: u64, out: []u8) bool {
        const at = std.math.cast(usize, offset) orelse return false;
        self.source.read(at, out) catch return false;
        return true;
    }
};
pub fn inspectArtifact(value: tools.byte_source.Source, size: u64) ?@import("r4u_artifact.zig").Identity {
    return @import("r4u_artifact.zig").inspect(Reader{ .source = value }, size);
}

// Reports contain private anyerror diagnostic fields, not caller-settable
// transaction state. Re-export every original operation with read-only views.
pub fn gptRead(allocator: std.mem.Allocator, value: tools.io.Device) !*tools.gpt_repair.Report {
    return tools.gpt_repair.Report.read(allocator, value);
}
pub fn gptDeinit(report: *tools.gpt_repair.Report) void {
    report.deinit();
}
pub fn gptRepairable(report: *const tools.gpt_repair.Report) !usize {
    return report.repairable();
}
pub fn gptRepair(report: *const tools.gpt_repair.Report, value: tools.io.Device, work: []u8) !void {
    try report.repair(value, work);
}
pub fn gptStatus(report: *const tools.gpt_repair.Report) tools.gpt_repair.Status {
    return report.status;
}
pub fn gptValid(report: *const tools.gpt_repair.Report, index: usize) bool {
    return index < report.copies.len and report.copies[index].valid();
}
pub fn gptReason(report: *const tools.gpt_repair.Report, index: usize) ?[]const u8 {
    if (index >= report.copies.len) return null;
    return if (report.copies[index].reason) |err| @errorName(err) else null;
}
pub fn gptMbrReason(report: *const tools.gpt_repair.Report) ?[]const u8 {
    return if (report.mbr_reason) |err| @errorName(err) else null;
}

/// The catalogue's generic document contract is the existing JSON.R4P
/// facade. No JSON parser is embedded in an R4X by this specialization.
pub fn parseCatalog(document: *@import("json.zig").Document, profile: @import("system_update_inventory.zig").Profile, local_release: []const u8, workspace: *@import("update_catalog.zig").CatalogRelease, out: *@import("update_catalog.zig").CatalogRelease) @import("update_catalog.zig").ParseError!void {
    return @import("update_catalog.zig").parseDocument(document, profile, local_release, workspace, out);
}
