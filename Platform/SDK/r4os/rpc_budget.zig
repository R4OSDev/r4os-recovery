//! One logical synchronous operation over existing RPC calls. No retry,
//! mutation rollback or resource retirement follows from expiry.
const std = @import("std");
const a = @import("r4os_contract").abi;
const time = @import("time_budget.zig");
pub const Error = time.Error || error{TimedOut};
pub const Clock = ?a.R4SysFns.monotonic_clock;
pub fn code(err: Error) i32 {
    return if (err == error.TimedOut) a.service_api_result_timeout else time.failure(@errorCast(err));
}
fn sample(clock: Clock) time.Error!time.ClockSample {
    var info: a.MonotonicClockInfo = .{};
    if ((clock orelse return error.ClockUnavailable)(&info) <= 0) return error.ClockUnavailable;
    return time.ClockSample.fromInfo(info);
}
pub const Budget = extern struct {
    clock: Clock,
    deadline: time.DeadlineBudget,
    tick_deadline: u64 = 0,
    has_tick_deadline: u32 = 0,
    reserved: u32 = 0,

    pub fn fromTicks(clock: Clock, ticks: u64) Error!Budget {
        if (ticks == 0 or ticks == a.io_wait_forever) return .{ .clock = clock, .deadline = .{ .kind = if (ticks == 0) 0 else 2 } };
        const now = try sample(clock);
        // Preserve the exact logical tick boundary without a lossy ns/tick
        // round trip. The shared indefinite guard validates clock identity.
        const end = std.math.add(u64, try now.ticks(), ticks) catch return error.BudgetOverflow;
        return .{ .clock = clock, .deadline = try time.DeadlineBudget.init(now, .{ .kind = a.timeout_kind_forever }), .tick_deadline = end, .has_tick_deadline = 1 };
    }
    pub fn fromTimeout(clock: Clock, timeout: a.R4Timeout) Error!Budget {
        const value = try time.fromTimeout(timeout);
        if (value.kind != 1) return .{ .clock = clock, .deadline = .{ .kind = value.kind } };
        const now = try sample(clock);
        return .{ .clock = clock, .deadline = try time.DeadlineBudget.init(now, timeout) };
    }
    pub fn remainingTicks(self: *Budget) Error!u64 {
        if (self.has_tick_deadline > 1 or self.reserved != 0) return error.InvalidBudget;
        if (self.has_tick_deadline == 0 and self.deadline.kind != 1) return time.toWaitTicks(.{ .kind = self.deadline.kind });
        const now = try sample(self.clock);
        const remaining = try self.deadline.remaining(now);
        if (self.has_tick_deadline != 0) {
            const end = self.tick_deadline;
            const ticks = try now.ticks();
            if (ticks >= end) return error.TimedOut;
            return time.toWaitTicks(.{ .kind = 1, .value = end - ticks });
        }
        if (remaining.kind == 0) return error.TimedOut;
        return time.toWaitTicks(.{ .kind = 1, .value = try time.durationToTicks(.{ .nanoseconds = remaining.value }, now.identity.tick_hz) });
    }
};

/// Pass the remaining duration to facades that accept R4Timeout.
pub fn remainingTimeout(budget: *Budget) Error!a.R4Timeout {
    if (budget.has_tick_deadline > 1 or budget.reserved != 0) return error.InvalidBudget;
    if (budget.has_tick_deadline == 0 and budget.deadline.kind != 1) {
        _ = try time.toWaitTicks(.{ .kind = budget.deadline.kind });
        return .{ .kind = @intCast(budget.deadline.kind) };
    }
    const now = try sample(budget.clock);
    const remaining = try budget.deadline.remaining(now);
    if (budget.has_tick_deadline != 0) {
        const ticks = try now.ticks();
        if (ticks >= budget.tick_deadline) return error.TimedOut;
        return .{ .kind = 1, .nanoseconds = try time.scaleCeil(budget.tick_deadline - ticks, a.nanoseconds_per_second, now.identity.tick_hz) };
    }
    if (remaining.kind == 0) return error.TimedOut;
    return .{ .kind = 1, .nanoseconds = remaining.value };
}
