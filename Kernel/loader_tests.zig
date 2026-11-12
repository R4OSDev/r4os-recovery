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

test "CPU leaf receipt preserves refused boundaries, callback result and deadline" {
    const std = @import("std");
    const c = @import("program/generation2.zig").abi.shared;
    const window = @import("platform/cpu_acceleration_window.zig");
    const Fake = struct {
        calls: usize = 0, clocks: usize = 0, identities: usize = 0,
        lose_at: usize = 0, missing_clock: usize = 0, end: u64 = 110, result: i32 = 0,
        pub fn current(self: *@This()) bool { self.identities += 1; return self.lose_at == 0 or self.identities != self.lose_at; }
        pub fn now(self: *@This()) ?u64 { self.clocks += 1; if (self.clocks == self.missing_clock) return null; return if (self.clocks == 1) 100 else self.end; }
        pub fn work(self: *@This(), count: u32) i32 { std.debug.assert(count == 4); self.calls += 1; return self.result; }
    };
    const input: c.CpuAccelerationWork = .{ .iterations = 4 };
    var success: Fake = .{};
    const ok = window.run(input, &success);
    try std.testing.expectEqual(@as(usize, 1), success.calls);
    try std.testing.expectEqual(c.cpu_accel_work_status_completed, ok.status);
    try std.testing.expect(ok.flags & (c.cpu_accel_work_flag_callback_returned | c.cpu_accel_work_flag_clock_valid | c.cpu_accel_work_flag_within_budget) == (c.cpu_accel_work_flag_callback_returned | c.cpu_accel_work_flag_clock_valid | c.cpu_accel_work_flag_within_budget));
    for ([_]usize{1,2,3}) |boundary| {
        var fake: Fake = .{ .lose_at = boundary };
        const result = window.run(input, &fake);
        try std.testing.expectEqual(c.cpu_accel_work_status_identity_changed, result.status);
        try std.testing.expectEqual(@as(usize, if (boundary == 3) 1 else 0), fake.calls);
    }
    for ([_]usize{1,2}) |clock| {
        var fake: Fake = .{ .missing_clock = clock };
        try std.testing.expectEqual(c.cpu_accel_work_status_clock_unavailable, window.run(input, &fake).status);
    }
    var regress: Fake = .{ .end = 99 };
    try std.testing.expectEqual(c.cpu_accel_work_status_clock_regressed, window.run(input, &regress).status);
    var late: Fake = .{ .end = 101 + c.cpu_accel_max_window_ns };
    try std.testing.expectEqual(c.cpu_accel_work_status_over_budget, window.run(input, &late).status);
    var aborted: Fake = .{ .result = -1 };
    try std.testing.expectEqual(c.cpu_accel_work_status_callback_aborted, window.run(input, &aborted).status);
}
