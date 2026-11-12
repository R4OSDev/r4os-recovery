const std = @import("std");
const a = @import("r4os").abi;
const video = @import("binding");

fn sameLayout(comptime Left: type, comptime Right: type) !void {
    try std.testing.expectEqual(@sizeOf(Left), @sizeOf(Right));
    try std.testing.expectEqual(@alignOf(Left), @alignOf(Right));
    inline for (@typeInfo(Left).@"struct".fields) |field| {
        try std.testing.expectEqual(@offsetOf(Left, field.name), @offsetOf(Right, field.name));
        try std.testing.expect(field.type == @FieldType(Right, field.name));
    }
}

test "VIDEO_V1 uses the actual common BO and queue-fence identities" {
    try sameLayout(video.R4VideoBuffer, a.GfxBufferHandle);
    try sameLayout(video.R4VideoFence, a.GfxFence);
}
