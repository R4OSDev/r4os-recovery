//! Pure decisions only: no device access, allocation, pause, yield or sleep.
//! Expired/Stop do not acknowledge hardware, callbacks, mappings or DMA.
const std = @import("std");
const time = @import("time_budget.zig");
const abi = @import("r4os_contract").abi;
/// Read the original driver clock provider without changing the reflected
/// DriverContext ABI or granting another execution context driver admission.
pub fn clockSample(driver: *const @import("driver.zig").Context) time.Error!time.ClockSample {
    var info: abi.MonotonicClockInfo = .{};
    if (driver.monotonicClock(&info) <= 0) return error.ClockUnavailable;
    return time.ClockSample.fromInfo(info);
}
pub const Context = enum(u32) { task = 0, no_sleep = 1, irq = 2 };
pub const Outcome = enum(u32) { proceed = 0, expired = 1, stop = 2, clock_unavailable = 3, clock_changed = 4, clock_regressed = 5, invalid_budget = 6 };
pub const Remaining = extern struct {
    kind: u32 = 0, // 0 iterations only; 1 nanoseconds AND iterations
    outcome: u32 = 0,
    iterations: u64 = 0,
    time: time.Value = .{},
};
pub const DriverPollBudget = extern struct {
    context: u32 = 0,
    kind: u32 = 0,
    iterations: u64 = 0,
    deadline: time.DeadlineBudget = .{},
    outcome: u32 = 0,
    reserved: u32 = 0,

    pub fn initIterations(iterations: u64, context: Context) DriverPollBudget {
        return .{ .iterations = iterations, .context = @intFromEnum(context) };
    }
    /// Even a stalled clock cannot turn an IRQ/no-sleep spin into an infinite
    /// loop. The caller supplies a separate finite maximum number of steps.
    pub fn initTimed(sample: time.ClockSample, timeout: abi.R4Timeout, max_steps: u64, context: Context) time.Error!DriverPollBudget {
        const duration = try time.fromTimeout(timeout);
        if (duration.kind == 2 or max_steps == 0) return error.InvalidBudget;
        return .{ .kind = 1, .iterations = max_steps, .context = @intFromEnum(context), .deadline = try time.DeadlineBudget.init(sample, timeout) };
    }
    fn valid(self: DriverPollBudget) bool {
        return self.context <= 2 and self.kind <= 1 and self.outcome <= 6 and self.reserved == 0;
    }
    fn finish(self: *DriverPollBudget, outcome: Outcome) Outcome {
        self.outcome = @intFromEnum(outcome);
        return outcome;
    }
    fn failure(err: time.Error) Outcome {
        return switch (err) {
            error.ClockUnavailable => .clock_unavailable,
            error.ClockChanged => .clock_changed,
            error.ClockRegressed => .clock_regressed,
            else => .invalid_budget,
        };
    }
    /// Call before each authorized retry. A proceed consumes exactly one
    /// iteration. Terminal outcomes are sticky. No action is executed here.
    pub fn step(self: *DriverPollBudget, now: ?time.ClockSample, stop_requested: bool) Outcome {
        if (!self.valid()) return .invalid_budget;
        if (self.outcome != 0) return @enumFromInt(self.outcome);
        if (stop_requested) return self.finish(.stop);
        if (self.iterations == 0) return self.finish(.expired);
        if (self.kind == 1) {
            const available = self.deadline.remaining(now orelse return self.finish(.clock_unavailable)) catch |err| return self.finish(failure(err));
            if (available.kind == 0) return self.finish(.expired);
        }
        self.iterations -= 1;
        return .proceed;
    }
    pub fn remaining(self: *DriverPollBudget, now: ?time.ClockSample) time.Error!Remaining {
        if (!self.valid()) return error.InvalidBudget;
        return .{ .kind = self.kind, .outcome = self.outcome, .iterations = self.iterations, .time = if (self.kind == 1) try self.deadline.remaining(now orelse return error.ClockUnavailable) else .{} };
    }
};

test "checked budget IRQ steps stay bounded with a frozen clock and stop stays terminal" {
    const sample = time.ClockSample{ .identity = .{ .source = 1, .generation = 1 }, .instant_ns = 100 };
    var budget = try DriverPollBudget.initTimed(sample, .{ .kind = abi.timeout_kind_finite, .nanoseconds = 20 }, 3, .irq);
    for (0..3) |_| try std.testing.expectEqual(Outcome.proceed, budget.step(sample, false));
    try std.testing.expectEqual(Outcome.expired, budget.step(sample, false));
    try std.testing.expectEqual(Outcome.expired, budget.step(sample, true));
    var retry = DriverPollBudget.initIterations(2, .no_sleep);
    try std.testing.expectEqual(Outcome.proceed, retry.step(null, false));
    try std.testing.expectEqual(@as(u64, 1), (try retry.remaining(null)).iterations);
    try std.testing.expectEqual(Outcome.stop, retry.step(null, true));
    try std.testing.expectEqual(Outcome.stop, retry.step(null, false));
    try std.testing.expectError(error.InvalidBudget, DriverPollBudget.initTimed(sample, .{ .kind = abi.timeout_kind_forever }, 1, .task));
    var unknown = try DriverPollBudget.initTimed(sample, .{ .kind = abi.timeout_kind_finite, .nanoseconds = 20 }, 3, .task);
    try std.testing.expectEqual(Outcome.clock_unavailable, unknown.step(null, false));
}
