// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Media time is independent of decode speed, queue occupancy and audio health.
const std = @import("std");
pub const Error = error{ ClockRegression, Overflow, Invalid };
pub const Clock = struct {
    anchor_ns: u64,
    media_ns: i64,
    last_ns: u64,
    paused: bool = false,

    pub fn init(now_ns: u64, position_ns: i64) Clock {
        return .{ .anchor_ns = now_ns, .last_ns = now_ns, .media_ns = position_ns };
    }
    pub fn position(self: *Clock, now_ns: u64) Error!i64 {
        if (now_ns < self.last_ns) return error.ClockRegression;
        const value: i128 = @as(i128, self.media_ns) + if (self.paused) @as(i128, 0) else now_ns - self.anchor_ns;
        const result = std.math.cast(i64, value) orelse return error.Overflow;
        self.last_ns = now_ns;
        return result;
    }
    pub fn setPaused(self: *Clock, now_ns: u64, paused: bool) Error!void {
        const value = try self.position(now_ns);
        self.media_ns = value;
        self.anchor_ns = now_ns;
        self.paused = paused;
    }
    pub fn seek(self: *Clock, now_ns: u64, position_ns: i64) Error!void {
        if (now_ns < self.last_ns) return error.ClockRegression;
        self.media_ns = position_ns;
        self.last_ns = now_ns;
        self.anchor_ns = now_ns;
    }
};

/// Exact rational PCM timestamps: rounding never accumulates per chunk.
pub fn sampleTime(origin_ns: i64, frames: u64, rate: u32) Error!i64 {
    if (rate == 0) return error.Invalid;
    const value = @as(i128, origin_ns) + @divTrunc(@as(i128, frames) * std.time.ns_per_s, rate);
    return std.math.cast(i64, value) orelse error.Overflow;
}
