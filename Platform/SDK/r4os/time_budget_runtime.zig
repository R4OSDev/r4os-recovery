//! C/Rust enter the same checked arithmetic and pure polling owner as Zig.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const time = @import("time_budget.zig");
const poll = @import("driver_poll_budget.zig");
const rpc = @import("rpc_budget.zig");
// New FFI records are borrowed pointers. No callback or output is retained.
pub export fn R4SdkRpcBudgetInit(clock: rpc.Clock, timeout: ?*const abi.R4Timeout, out: ?*rpc.Budget) callconv(.c) i32 {
    const output = out orelse return -7;
    const limit = timeout orelse return -7;
    output.* = rpc.Budget.fromTimeout(clock, limit.*) catch |err| return rpc.code(err);
    return 0;
}
pub export fn R4SdkRpcBudgetRemaining(owner: ?*rpc.Budget, out: ?*u64) callconv(.c) i32 {
    const output = out orelse return -7;
    const budget = owner orelse return -7;
    output.* = budget.remainingTicks() catch |err| return rpc.code(err);
    return 0;
}
pub const failure = time.failure;
fn context(raw: u32) ?poll.Context {
    return std.enums.fromInt(poll.Context, raw);
}
pub export fn R4SdkClockSampleRead(info: ?*const abi.MonotonicClockInfo, out: ?*time.ClockSample) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = time.ClockSample.fromInfo((info orelse return -4).*) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkMillisecondsToTicksChecked(ms: u64, hz: u32, out: ?*u64) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = time.millisecondsToTicks(ms, hz) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkTimeoutTicksChecked(timeout: abi.R4Timeout, hz: u32, out: ?*time.Value) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = time.timeoutTicks(timeout, hz) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkBudgetToWaitTicks(value: ?*const time.Value, out: ?*u64) callconv(.c) i32 {
    const output = out orelse return -7;
    const input = value orelse return -7;
    output.* = time.toWaitTicks(input.*) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkDeadlineBudgetInit(sample: time.ClockSample, timeout: abi.R4Timeout, out: ?*time.DeadlineBudget) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = time.DeadlineBudget.init(sample, timeout) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkDeadlineBudgetRemaining(budget: ?*time.DeadlineBudget, now: time.ClockSample, out: ?*time.Value) callconv(.c) i32 {
    const output = out orelse return -7;
    const owner = budget orelse return -7;
    output.* = owner.remaining(now) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkDriverPollIterations(iterations: u64, mode: u32, out: ?*poll.DriverPollBudget) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = poll.DriverPollBudget.initIterations(iterations, context(mode) orelse return -7);
    return 0;
}
pub export fn R4SdkDriverPollTimed(sample: time.ClockSample, timeout: abi.R4Timeout, max_steps: u64, mode: u32, out: ?*poll.DriverPollBudget) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = poll.DriverPollBudget.initTimed(sample, timeout, max_steps, context(mode) orelse return -7) catch |err| return failure(err);
    return 0;
}
pub export fn R4SdkDriverPollStep(budget: ?*poll.DriverPollBudget, now: ?*const time.ClockSample, stop: u32) callconv(.c) u32 {
    const owner = budget orelse return @intFromEnum(poll.Outcome.invalid_budget);
    if (stop > 1) return @intFromEnum(poll.Outcome.invalid_budget);
    return @intFromEnum(owner.step(if (now) |s| s.* else null, stop != 0));
}
pub export fn R4SdkDriverPollRemaining(budget: ?*poll.DriverPollBudget, now: ?*const time.ClockSample, out: ?*poll.Remaining) callconv(.c) i32 {
    const output = out orelse return -7;
    const owner = budget orelse return -7;
    output.* = owner.remaining(if (now) |s| s.* else null) catch |err| return failure(err);
    return 0;
}
