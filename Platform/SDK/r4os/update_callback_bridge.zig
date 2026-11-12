//! Explicit update/storage I/O hooks. Stable table/user state is borrowed
//! synchronously; callbacks preserve exact device/journal/commit receipts.
const core = @import("native_callback_bridge.zig");
pub const Slot = core.Slot;
pub const Kind = enum(u6) { block_read, block_write, block_flush, block_continue, source_read, journal_persist, payload_rollback, payload_commit, payload_cleanup, path_state, path_presence, archive_unreferenced, archive_copy, archive_verify, archive_remove };
pub const Table = extern struct {
    user: ?*anyopaque = null,
    mask: u64 = 0,
    invoke: ?*const fn (?*anyopaque, u32, [*]const Slot, u32, ?*anyopaque) callconv(.c) Slot = null,
    pub fn has(self: *const Table, kind: Kind) bool {
        return self.invoke != null and self.mask & (@as(u64, 1) << @intFromEnum(kind)) != 0;
    }
};
pub fn pointer(comptime T: type, comptime context_index: usize, comptime kind: Kind) T {
    return core.pointer(Table, T, context_index, kind);
}
