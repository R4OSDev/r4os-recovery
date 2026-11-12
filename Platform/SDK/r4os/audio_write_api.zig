//! Explicit owner; native Query2 handles stay with the original resource owner.
const owner = @import("audio_write.zig");
const platform = @import("platform2.zig");
pub const Writer = owner.Writer;
pub const Provider = owner.Provider;
pub const Progress = owner.Progress;
pub const codes = owner;
pub const Binding = struct { status: i32, provider: Provider = .{} };
pub fn provider2(context: *const platform.Context, channel: u32, stream: u32, frame_bytes: u32) Binding {
    var call: u64 = 0;
    var clock: u64 = 0;
    var rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "service_call"), &call);
    if (rc != 0) return .{ .status = rc };
    rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "monotonic_clock"), &clock);
    if (rc != 0) return .{ .status = rc };
    return .{ .status = 0, .provider = .{ .call = @ptrFromInt(call), .monotonic = @ptrFromInt(clock), .service_handle = channel, .stream_id = stream, .frame_bytes = frame_bytes } };
}
