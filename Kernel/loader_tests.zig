test {
    _ = @import("kernel/modules.zig");
}

test "partial canonical group provider publishes only actual optional callbacks" {
    const std = @import("std");
    const api = @import("program/r4x_api.zig");
    const Sink = struct {
        fn write(_: [*]const u8, length: u32) callconv(.c) i32 {
            return @intCast(length);
        }
    };
    const table = api.buildR4SysTable(.{ .write = &Sink.write });
    try std.testing.expectEqual(@intFromPtr(&Sink.write), table.write);
    try std.testing.expectEqual(@as(u64, 0), table.putc);
    try std.testing.expectEqual(@as(u64, 0), table.file_read);
    const invoke: api.R4SysFns.write = @ptrFromInt(table.write);
    try std.testing.expectEqual(@as(i32, 3), invoke("abc", 3));
}

test "metadata namespace observation never reuses identity after exhaustion" {
    const std = @import("std");
    const History = @import("fs/directory_changes.zig").History;
    var history: History = .{};
    const mount = @import("storage/access_runtime.zig").MountRef{ .slot = 2, .generation = 3 };
    try std.testing.expectEqual(@as(?u64, 1), history.observation());
    history.publish(mount, 9);
    try std.testing.expectEqual(@as(?u64, 2), history.observation());
    history.sequence = ~@as(u64, 0) - 1;
    try std.testing.expectEqual(@as(?u64, ~@as(u64, 0)), history.observation());
    history.publish(mount, 9);
    try std.testing.expectEqual(@as(?u64, null), history.observation());
    history.publish(mount, 9);
    try std.testing.expectEqual(@as(u64, 0), history.sequence);
    try std.testing.expectEqual(@as(?u64, null), history.observation());
}
