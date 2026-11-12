//! Static C/Rust projection of the same frozen snapshot owner.
const owner = @import("device_snapshot.zig");
const wire = @import("binary_cursor.zig");
comptime {
    if (@sizeOf(owner.Provider) != 8 or @sizeOf(owner.Cursor) != 16 or @sizeOf(owner.PageInfo) != 32 or @sizeOf(owner.Progress) != 80 or @sizeOf(owner.Snapshot) != 112 or @offsetOf(owner.Snapshot, "provider") != 80 or @offsetOf(owner.Snapshot, "busy") != 104) @compileError("Device snapshot C/Rust layout drift");
}
fn code(err: owner.Error) i32 {
    return switch (err) {
        error.InvalidState => -1,
        error.InvalidStorage => -2,
        error.InvalidLimit => -3,
        error.Busy => -4,
        error.Closed => -5,
        error.Incomplete => -6,
        error.InvalidCursor => -7,
        error.NoProvider => -9002,
    };
}
pub export fn R4SdkDeviceSnapshotInit(storage: wire.Span, capacity: u32, provider: owner.Provider, out: ?*owner.Snapshot) callconv(.c) i32 {
    const target = out orelse return -1;
    target.* = owner.Snapshot.init(storage, capacity, provider) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkDeviceSnapshotGetProgress(raw: ?*const owner.Snapshot, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.progress() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkDeviceSnapshotCapture(raw: ?*owner.Snapshot, stop: u32, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    if (stop > 1) return -1;
    target.* = state.capture(stop != 0) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkDeviceSnapshotCancel(raw: ?*owner.Snapshot, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.cancel() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkDeviceSnapshotClose(raw: ?*owner.Snapshot, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.close() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkDeviceSnapshotBeginPages(raw: ?*const owner.Snapshot, out: ?*owner.Cursor) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.beginPages() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkDeviceSnapshotPage(raw: ?*const owner.Snapshot, cursor: ?*owner.Cursor, limit: u32, out_span: ?*wire.Span, out_info: ?*owner.PageInfo) callconv(.c) i32 {
    const state = raw orelse return -1;
    const position = cursor orelse return -1;
    const span = out_span orelse return -2;
    const info = out_info orelse return -2;
    const result = state.page(position, limit) catch |err| return code(err);
    span.* = result.rows;
    info.* = result.info;
    return 0;
}
pub export fn R4SdkDeviceSnapshotGetView(raw: ?*const owner.Snapshot, out: ?*wire.Span) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.view() catch |err| return code(err);
    return 0;
}
