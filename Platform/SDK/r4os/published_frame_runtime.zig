//! Static ABI over the exact serialized published-frame owner.
const p = @import("published_frame.zig");
comptime {
    if (@sizeOf(p.Bridge) != 864 or @alignOf(p.Bridge) != 8 or @sizeOf(p.Lease) != 112 or
        @sizeOf(p.Acquisition) != 16 or @sizeOf(p.Progress) != 72 or @sizeOf(p.Presentation) != 64 or
        @sizeOf(p.Viewport) != 32 or @sizeOf(p.Rect) != 16) @compileError("Published-frame C/Rust layout drift");
}
pub export fn R4SdkPublishedFrameInit(table: ?*const p.callbacks.Table, scratch: ?[*]u32, count: usize, features: u32, out: ?*p.Bridge) callconv(.c) i32 {
    const target = out orelse return p.invalid;
    const bytes = @import("std").math.mul(usize, count, @sizeOf(u32)) catch return p.invalid_buffer;
    const range = p.wire.Span{ .address = if (scratch) |value| @intFromPtr(value) else 0, .length = bytes };
    range.validate() catch return p.invalid_buffer;
    if (count == 0) return p.scratch_small;
    return p.Bridge.initCallbacks(table orelse return p.no_provider, (scratch orelse return p.invalid_buffer)[0..count], features, target);
}
pub export fn R4SdkPublishedFrameBind(raw: ?*p.Bridge, generation: u64) callconv(.c) i32 {
    return (raw orelse return p.invalid).bind(generation);
}
pub export fn R4SdkPublishedFrameSync(raw: ?*p.Bridge, frame: p.Lease, out: ?*p.Acquisition) callconv(.c) i32 {
    return (raw orelse return p.invalid).syncPublished(frame, out orelse return p.invalid);
}
pub export fn R4SdkPublishedFramePresent(raw: ?*p.Bridge, ticket: u64, width: i32, height: i32, out: ?*p.Presentation) callconv(.c) i32 {
    return (raw orelse return p.invalid).present(ticket, width, height, out orelse return p.invalid);
}
pub export fn R4SdkPublishedFrameRelease(raw: ?*p.Bridge, ticket: u64) callconv(.c) i32 {
    return (raw orelse return p.invalid).release(ticket);
}
pub export fn R4SdkPublishedFramePause(raw: ?*p.Bridge, paused: u32) callconv(.c) i32 {
    if (paused > 1) return p.invalid;
    return (raw orelse return p.invalid).pause(paused != 0);
}
pub export fn R4SdkPublishedFrameClose(raw: ?*p.Bridge) callconv(.c) i32 {
    return (raw orelse return p.invalid).close();
}
pub export fn R4SdkPublishedFrameGetProgress(raw: ?*const p.Bridge, out: ?*p.Progress) callconv(.c) i32 {
    return (raw orelse return p.invalid).progress(out orelse return p.invalid);
}
