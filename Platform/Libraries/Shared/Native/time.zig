// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Mesa's private OS-time transport. No POSIX clock/file-descriptor ABI.
const std = @import("std");
const a = @import("r4os").abi;
const threads = @import("threads.zig");
const ns_per_second: u64 = 1_000_000_000;

fn function(comptime name: []const u8) @field(a.R4SysFns, name) {
    return threads.system.required(name);
}
pub fn read() ?a.MonotonicClockInfo {
    var info: a.MonotonicClockInfo = .{};
    if (function("monotonic_clock")(&info) <= 0 or
        info.flags & a.monotonic_clock_flag_valid == 0 or
        info.frequency_hz != ns_per_second) return null;
    return info;
}
pub export fn os_time_get_nano() callconv(.c) i64 {
    const info = read() orelse @trap(); // Mesa's helper has no error return.
    return std.math.cast(i64, info.instant_ns) orelse @trap();
}
pub export fn os_time_get_absolute_timeout(timeout: u64) callconv(.c) i64 {
    if (timeout > std.math.maxInt(i64)) return -1;
    return std.math.add(i64, os_time_get_nano(), @intCast(timeout)) catch -1;
}
pub export fn os_time_nanosleep_until(deadline: i64) callconv(.c) void {
    if (deadline <= 0) return;
    const until: u64 = @intCast(deadline);
    while (true) {
        const info = read() orelse @trap();
        if (info.instant_ns >= until) return;
        // The event source is only the wakeup cadence, not the time origin.
        // Round upwards and recheck the actual monotonic deadline after wake.
        const numerator = info.event_frequency_numerator;
        const denominator: u128 = @as(u128, info.event_frequency_denominator) * ns_per_second;
        if (numerator == 0 or denominator == 0) @trap();
        const duration: u128 = @as(u128, until - info.instant_ns) * numerator;
        const ticks = duration / denominator + @intFromBool(duration % denominator != 0);
        function("sleep_ticks")(@intCast(@min(ticks, std.math.maxInt(u64) - 1)));
    }
}
pub export fn os_time_sleep(microseconds: i64) callconv(.c) void {
    if (microseconds <= 0) return;
    const target: i128 = @as(i128, os_time_get_nano()) + @as(i128, microseconds) * 1000;
    os_time_nanosleep_until(@intCast(@min(target, std.math.maxInt(i64))));
}
pub export fn os_wait_until_zero_abs_timeout(value: *const c_int, timeout: i64) callconv(.c) bool {
    while (@atomicLoad(c_int, value, .acquire) != 0) {
        if (timeout != -1 and os_time_get_nano() >= timeout) return false;
        // This Mesa utility observes a plain atomic integer, not a notified
        // condition. Yield between observations; never invent a wakeup source.
        function("task_yield")();
    }
    return true;
}
pub export fn os_wait_until_zero(value: *const c_int, timeout: u64) callconv(.c) bool {
    if (@atomicLoad(c_int, value, .acquire) == 0) return true;
    if (timeout == 0) return false;
    return os_wait_until_zero_abs_timeout(value, os_time_get_absolute_timeout(timeout));
}
