const std = @import("std");
const abi = @import("r4os_contract").abi;

pub const Error = error{ UnknownFrequency, InvalidTimeout };
pub const Duration = abi.R4Duration;
pub const MonotonicInstant = abi.R4MonotonicInstant;
pub const Deadline = abi.R4Deadline;
pub const UtcTime = abi.R4UtcTime;
pub const Timeout = abi.R4Timeout;

pub const nanoseconds_per_second: u64 = abi.nanoseconds_per_second;

pub fn durationFromNanoseconds(nanoseconds: u64) Duration {
    return .{ .nanoseconds = nanoseconds };
}

pub fn resolutionNanoseconds(monotonic_hz: u32) Error!u64 {
    if (monotonic_hz == 0) return Error.UnknownFrequency;
    return ceilDiv(nanoseconds_per_second, monotonic_hz);
}

pub fn durationToTicks(duration: Duration, monotonic_hz: u32) Error!u64 {
    if (monotonic_hz == 0) return Error.UnknownFrequency;
    if (duration.nanoseconds == 0) return 0;
    const product = @as(u128, duration.nanoseconds) * monotonic_hz;
    const rounded = (product + nanoseconds_per_second - 1) / nanoseconds_per_second;
    return if (rounded > std.math.maxInt(u64)) std.math.maxInt(u64) else @intCast(rounded);
}

pub fn durationFromTicks(ticks: u64, monotonic_hz: u32) Error!Duration {
    if (monotonic_hz == 0) return Error.UnknownFrequency;
    if (ticks == 0) return .{};
    const product = @as(u128, ticks) * nanoseconds_per_second;
    const rounded = (product + monotonic_hz - 1) / monotonic_hz;
    return .{ .nanoseconds = if (rounded > std.math.maxInt(u64)) std.math.maxInt(u64) else @intCast(rounded) };
}

pub fn monotonicFromTicks(ticks: u64, monotonic_hz: u32) Error!MonotonicInstant {
    const duration = try durationFromTicks(ticks, monotonic_hz);
    return .{ .nanoseconds = duration.nanoseconds };
}

pub fn deadlineAfter(now: MonotonicInstant, duration: Duration) Deadline {
    return .{ .nanoseconds = now.nanoseconds +| duration.nanoseconds };
}

pub fn timeoutPoll() Timeout {
    return .{ .kind = abi.timeout_kind_poll };
}

pub fn timeoutFinite(duration: Duration) Timeout {
    return .{ .kind = abi.timeout_kind_finite, .nanoseconds = duration.nanoseconds };
}

pub fn timeoutForever() Timeout {
    return .{ .kind = abi.timeout_kind_forever };
}

pub fn timeoutToTicks(timeout: Timeout, monotonic_hz: u32) Error!u64 {
    return switch (timeout.kind) {
        abi.timeout_kind_poll => 0,
        abi.timeout_kind_finite => durationToTicks(.{ .nanoseconds = timeout.nanoseconds }, monotonic_hz),
        abi.timeout_kind_forever => abi.io_wait_forever,
        else => Error.InvalidTimeout,
    };
}

pub fn timeoutDeadline(timeout: Timeout, now: MonotonicInstant) Error!?Deadline {
    return switch (timeout.kind) {
        abi.timeout_kind_poll => .{ .nanoseconds = now.nanoseconds },
        abi.timeout_kind_finite => .{ .nanoseconds = now.nanoseconds +| timeout.nanoseconds },
        abi.timeout_kind_forever => null,
        else => Error.InvalidTimeout,
    };
}

pub fn remainingTicks(deadline: Deadline, now: MonotonicInstant, monotonic_hz: u32) Error!u64 {
    if (now.nanoseconds >= deadline.nanoseconds) return 0;
    return durationToTicks(.{ .nanoseconds = deadline.nanoseconds - now.nanoseconds }, monotonic_hz);
}

fn ceilDiv(value: u64, divisor: u32) u64 {
    return value / divisor + @intFromBool(value % divisor != 0);
}

test "duration conversion rounds positive values up at representative rates" {
    for ([_]u32{ 100, 128, 333, 1000 }) |hz| {
        try std.testing.expectEqual(@as(u64, 1), try durationToTicks(durationFromNanoseconds(1), hz));
        const one_second = try durationToTicks(durationFromNanoseconds(nanoseconds_per_second), hz);
        try std.testing.expectEqual(@as(u64, hz), one_second);
        try std.testing.expect((try resolutionNanoseconds(hz)) > 0);
    }
}

test "duration and deadline arithmetic saturate and reject unknown frequency" {
    try std.testing.expectEqual(std.math.maxInt(u64), (deadlineAfter(.{ .nanoseconds = std.math.maxInt(u64) - 1 }, .{ .nanoseconds = 8 })).nanoseconds);
    try std.testing.expectError(Error.UnknownFrequency, durationToTicks(.{ .nanoseconds = 1 }, 0));
    const huge = try durationToTicks(.{ .nanoseconds = std.math.maxInt(u64) }, std.math.maxInt(u32));
    try std.testing.expectEqual(std.math.maxInt(u64), huge);
}

test "tagged timeout removes raw poll and forever sentinels from callers" {
    try std.testing.expectEqual(@as(u64, 0), try timeoutToTicks(timeoutPoll(), 1000));
    try std.testing.expectEqual(@as(u64, 1), try timeoutToTicks(timeoutFinite(durationFromNanoseconds(1)), 1000));
    try std.testing.expectEqual(abi.io_wait_forever, try timeoutToTicks(timeoutForever(), 1000));
    try std.testing.expectError(Error.InvalidTimeout, timeoutToTicks(.{ .kind = 99 }, 1000));
}

test "deadline budget is absolute saturating and never resets between waits" {
    const now = MonotonicInstant{ .nanoseconds = 100 };
    const deadline = (try timeoutDeadline(timeoutFinite(.{ .nanoseconds = 10 }), now)).?;
    try std.testing.expectEqual(@as(u64, 1), try remainingTicks(deadline, .{ .nanoseconds = 109 }, 1000));
    try std.testing.expectEqual(@as(u64, 0), try remainingTicks(deadline, .{ .nanoseconds = 110 }, 1000));
    const saturated = (try timeoutDeadline(timeoutFinite(.{ .nanoseconds = 10 }), .{ .nanoseconds = std.math.maxInt(u64) - 1 })).?;
    try std.testing.expectEqual(std.math.maxInt(u64), saturated.nanoseconds);
    try std.testing.expect((try timeoutDeadline(timeoutForever(), now)) == null);
    try std.testing.expectError(Error.InvalidTimeout, timeoutDeadline(.{ .kind = 99 }, now));
}
