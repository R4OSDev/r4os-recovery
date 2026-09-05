const std = @import("std");
const r4os = @import("r4os");

test "tagged timeout and absolute deadline retain one budget" {
    const time = r4os.time_contract;
    const poll = time.timeoutPoll();
    const finite = time.timeoutFinite(.{ .nanoseconds = 10 });
    const forever = time.timeoutForever();
    try std.testing.expectEqual(@as(u64, 0), try time.timeoutToTicks(poll, 1000));
    try std.testing.expectEqual(@as(u64, 1), try time.timeoutToTicks(finite, 1000));
    try std.testing.expectEqual(r4os.abi.io_wait_forever, try time.timeoutToTicks(forever, 1000));
    const deadline = (try time.timeoutDeadline(finite, .{ .nanoseconds = 100 })).?;
    try std.testing.expectEqual(@as(u64, 1), try time.remainingTicks(deadline, .{ .nanoseconds = 109 }, 1000));
    try std.testing.expectEqual(@as(u64, 0), try time.remainingTicks(deadline, .{ .nanoseconds = 110 }, 1000));
}

test "cooperative stop and wait outcomes are explicit" {
    var stop: r4os.app_contract.StopFlag = .{};
    try std.testing.expect(!stop.requested());
    stop.request();
    try std.testing.expect(stop.requested());
    try std.testing.expectEqual(r4os.app_contract.WaitState.timed_out, r4os.app_contract.classifyWait(-8, -8, -9, -10));
    try std.testing.expectEqual(r4os.app_contract.WaitState.cancelled, r4os.app_contract.classifyWait(-9, -8, -9, -10));
    try std.testing.expectEqual(r4os.app_contract.ServiceStopPolicy.kill_after_grace, r4os.program.ServiceStopPolicy.kill_after_grace);
    try std.testing.expect(@hasDecl(r4os.program.Context, "ioWaitTimeout"));
    try std.testing.expect(@hasDecl(r4os.program.Context, "threadJoinTimeout"));
    try std.testing.expect(@hasDecl(r4os.program.Context, "serviceStopWithPolicy"));
    try std.testing.expect(@hasDecl(r4os.program.Context, "consoleInputWait"));
    try std.testing.expect(@hasDecl(r4os.r4desk.Context, "consoleInputWait"));
}
