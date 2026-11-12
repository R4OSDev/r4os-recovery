//! Test-only reuse of the existing recording owner cases and parameter sets.
const std = @import("std");
const pixels = @import("R4ENC/Bindings/Zig/recording_pixels.zig");
pub const Writer = @import("R4ENC/Bindings/Zig/recording_mux.zig").Writer;
pub const Layout = pixels.Layout;
pub const rows = pixels.rows;
pub const parameterSets = @import("R4NV/Source/encode_headers.zig").parameterSets;
pub export fn R4LibrariesRecordingOracle() callconv(.c) i32 {
    @import("R4ENC/Tests/recording.zig").runWithAllocator(std.heap.page_allocator) catch return -1;
    return 0;
}
pub export fn R4LibrariesAvcOracle(output: [*]u8, capacity: usize) callconv(.c) usize {
    const parameters = parameterSets(.{ .width = 64, .height = 64, .qp = 26, .fps_num = 30, .fps_den = 1 }) catch return 0;
    if (capacity < parameters.length + 6) return 0;
    @memcpy(output[0..parameters.length], parameters.bytes());
    @memcpy(output[parameters.length..][0..6], &[_]u8{ 0, 0, 0, 1, 0x65, 0x80 });
    return parameters.length + 6;
}
