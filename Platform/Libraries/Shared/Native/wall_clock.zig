// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Consumers supply r4native_date as the canonical R4STD/Source/date.zig
// module. Calendar conversion has one owner; no host clock is used here.
const date = @import("r4native_date");
const a = @import("r4os").abi;
const threads = @import("threads.zig");
const sync = @import("threading.zig");
const monotonic = @import("time.zig");
pub const Timespec = extern struct { seconds: i64, nanoseconds: i64 };

pub fn read() ?Timespec {
    const get = threads.system.function("time_state") orelse return null;
    var value: a.TimeState = .{};
    get(&value);
    if (value.valid == 0) return null;
    const calendar = date.fromTimeState(value) orelse return null;
    const utc = date.utcFromDateTime(calendar, 0) orelse return null;
    // R4SYS currently supplies UTC calendar seconds, without a subsecond
    // phase. Do not manufacture fractional precision from the boot clock.
    return .{ .seconds = utc.seconds_since_unix_epoch, .nanoseconds = 0 };
}

pub export fn time(output: ?*i64) callconv(.c) i64 {
    const value = read() orelse {
        if (output) |result| result.* = -1;
        return -1;
    };
    if (output) |result| result.* = value.seconds;
    return value.seconds;
}

pub export fn timespec_get(output: *Timespec, base: c_int) callconv(.c) c_int {
    if (base != 1) return 0; // TIME_UTC
    const value = read() orelse return 0;
    output.* = value;
    return base;
}

pub export fn cnd_timedwait(condition: *sync.Condition, mutex: *sync.Mutex, absolute: *const Timespec) callconv(.c) c_int {
    if (absolute.nanoseconds < 0 or absolute.nanoseconds >= 1_000_000_000) return sync.failed;
    const host = sync.Host.bound() orelse return sync.failed;
    const target = @as(i128, absolute.seconds) * 1_000_000_000 + absolute.nanoseconds;
    while (true) {
        const wall = read() orelse return sync.failed;
        const clock = monotonic.read() orelse return sync.failed;
        const now = @as(i128, wall.seconds) * 1_000_000_000 + wall.nanoseconds;
        // UTC may be changed while waiting. Bound a monotonic wait slice,
        // then reread UTC; only UTC reaching the target means timed out.
        const remaining: u64 = @intCast(@min(@max(target - now, 0), 100_000_000));
        const result = condition.wait(&host, mutex, clock.instant_ns +| remaining);
        if (result != sync.timedout) return result;
        const after = read() orelse return sync.failed;
        if (@as(i128, after.seconds) * 1_000_000_000 + after.nanoseconds >= target) return sync.timedout;
    }
}
