// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Vulkan-specific deadline helpers use the common native monotonic clock.
const std = @import("std");
const native_time = @import("r4native").time;
const read = native_time.read;
const ns_per_second: u64 = 1_000_000_000;
comptime {
    _ = native_time;
}

pub export fn r4vk_monotonic_time(output: *u64) callconv(.c) c_int {
    const info = read() orelse return -1;
    output.* = info.instant_ns;
    return 0;
}
// Mesa sync waits use absolute monotonic nanoseconds, including zero for a
// poll and UINT64_MAX for infinity. Event ticks are only a wakeup cadence.
pub export fn r4vk_wait_ticks(deadline: u64, output: *u64) callconv(.c) c_int {
    const info = read() orelse return -1;
    if (deadline == std.math.maxInt(u64)) {
        output.* = deadline;
        return 0;
    }
    if (deadline <= info.instant_ns) {
        output.* = 0;
        return 0;
    }
    const numerator: u128 = @as(u128, deadline - info.instant_ns) * info.event_frequency_numerator;
    const denominator: u128 = @as(u128, info.event_frequency_denominator) * ns_per_second;
    if (numerator == 0 or denominator == 0) return -1;
    const ticks = numerator / denominator + @intFromBool(numerator % denominator != 0);
    output.* = @intCast(@min(ticks, std.math.maxInt(u64) - 1));
    return 0;
}
// Finite native resource operations use one clock snapshot for both their
// absolute broker deadline and the rounded event-wait duration. Publish both
// outputs only on success; UINT64_MAX remains the public infinite sentinel.
pub export fn r4vk_operation_deadline(duration: u64, deadline: *u64, timeout_ticks: *u64) callconv(.c) c_int {
    if (duration == 0 or duration > 60 * ns_per_second) return -1;
    const info = read() orelse return -1;
    const until = std.math.add(u64, info.instant_ns, duration) catch return -1;
    if (until == std.math.maxInt(u64)) return -1;
    const numerator: u128 = @as(u128, duration) * info.event_frequency_numerator;
    const denominator: u128 = @as(u128, info.event_frequency_denominator) * ns_per_second;
    if (numerator == 0 or denominator == 0) return -1;
    const ticks = numerator / denominator + @intFromBool(numerator % denominator != 0);
    deadline.* = until;
    timeout_ticks.* = @intCast(@min(ticks, std.math.maxInt(u64) - 1));
    return 0;
}
