//! Static C/Rust access to the same bounded prepared-text owner.
const owner = @import("text_metrics.zig");
const wire = @import("binary_cursor.zig");
comptime {
    if (@sizeOf(owner.Provider) != 8 or @sizeOf(owner.Key) != 32 or @sizeOf(owner.Progress) != 48 or
        @sizeOf(owner.Cache) != 112 or @offsetOf(owner.Cache, "provider") != 72 or @offsetOf(owner.Cache, "busy") != 100)
        @compileError("Text metrics C/Rust layout drift");
}
pub fn code(err: owner.Error) i32 {
    return switch (err) {
        error.InvalidState => -101,
        error.InvalidStorage => -102,
        error.Busy => -103,
        error.Incomplete => -104,
        error.Stale => -10,
    };
}
pub export fn R4SdkTextMetricsInit(source: wire.Span, storage: wire.Span, capacity: u32, provider: owner.Provider, out: ?*owner.Cache) callconv(.c) i32 {
    const target = out orelse return -101;
    const value = owner.Cache.init(source, storage, capacity, provider) catch |err| return code(err);
    const own = wire.Span{ .address = @intFromPtr(target), .length = @sizeOf(owner.Cache) };
    own.validate() catch return -102;
    if (owner.overlaps(own, source) or owner.overlaps(own, storage)) return -102;
    target.* = value;
    return 0;
}
pub export fn R4SdkTextMetricsPrepare(raw: ?*owner.Cache, text_revision: u64, font_id: u32, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -101;
    const target = out orelse return -101;
    target.* = state.prepare(text_revision, font_id) catch |err| return code(err);
    return target.error_code;
}
pub export fn R4SdkTextMetricsGetProgress(raw: ?*const owner.Cache, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -101;
    const target = out orelse return -101;
    target.* = state.progress() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTextMetricsGetKey(raw: ?*const owner.Cache, out: ?*owner.Key) callconv(.c) i32 {
    const state = raw orelse return -101;
    const target = out orelse return -101;
    target.* = state.key() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTextMetricsGetView(raw: ?*const owner.Cache, out: ?*wire.Span) callconv(.c) i32 {
    const state = raw orelse return -101;
    const target = out orelse return -101;
    target.* = state.view() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTextMetricsHit(raw: ?*const owner.Cache, key: owner.Key, x: i32, out: ?*u32) callconv(.c) i32 {
    const state = raw orelse return -101;
    const target = out orelse return -101;
    target.* = state.hit(key, x) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTextMetricsReset(raw: ?*owner.Cache) callconv(.c) i32 {
    const state = raw orelse return -101;
    state.reset() catch |err| return code(err);
    return 0;
}
