const std = @import("std");
const a = @import("r4os").abi;
const encode = @import("binding");

fn sameLayout(comptime Left: type, comptime Right: type) !void {
    try std.testing.expectEqual(@sizeOf(Left), @sizeOf(Right));
    try std.testing.expectEqual(@alignOf(Left), @alignOf(Right));
    inline for (@typeInfo(Left).@"struct".fields) |field| {
        try std.testing.expectEqual(@offsetOf(Left, field.name), @offsetOf(Right, field.name));
        try std.testing.expect(field.type == @FieldType(Right, field.name));
    }
}

test "ENCODE_V1 retains canonical BO and queue-fence identities" {
    try sameLayout(encode.R4EncBuffer, a.GfxBufferHandle);
    try sameLayout(encode.R4EncFence, a.GfxFence);
    try @import("input.zig").run();
    try @import("flow.zig").run();
    try @import("gpu_encoder.zig").run();
    try @import("gpu_input.zig").run();
    try @import("amd_encoder.zig").run();
    try @import("recording.zig").run();
}
