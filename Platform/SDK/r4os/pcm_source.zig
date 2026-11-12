//! Accepted-source schedule only; no stream, sleep or playback receipt.
const std = @import("std");
pub const budget = @import("time_budget.zig");
pub const Error = budget.Error || error{ InvalidState, InvalidRate, InvalidFrame, Paused };
pub const has_end: u32 = 1;
pub const paused: u32 = 2;
pub const SourceDeadline = extern struct {
    identity: budget.ClockIdentity,
    due_ns: u64,
    source_end_ns: u64,
    accepted_frames: u64,
    wait_ns: u64,
    rate: u32,
    frame_bytes: u32,
    flags: u32,
    reserved0: u32 = 0,
};
pub const Pacer = extern struct {
    identity: budget.ClockIdentity,
    end_lo: u64 = 0,
    end_hi: u64 = 0,
    last_ns: u64,
    accepted_frames: u64 = 0,
    lead_frames: u64,
    rate: u32,
    frame_bytes: u32,
    flags: u32 = 0,
    reserved0: u32 = 0,

    pub fn init(rate: u32, frame_bytes: u32, lead_frames: u64, sample: budget.ClockSample) Error!Pacer {
        if (rate == 0) return error.InvalidRate;
        if (frame_bytes == 0) return error.InvalidFrame;
        try sample.validate();
        return .{ .identity = sample.identity, .last_ns = sample.instant_ns, .lead_frames = lead_frames, .rate = rate, .frame_bytes = frame_bytes };
    }
    fn end(self: *const Pacer) u128 {
        return @as(u128, self.end_hi) << 64 | self.end_lo;
    }
    fn ceilNs(scaled: u128, rate: u32) Error!u64 {
        const value = scaled / rate + @intFromBool(scaled % rate != 0);
        return std.math.cast(u64, value) orelse error.BudgetOverflow;
    }
    fn check(self: *const Pacer) Error!void {
        if (self.rate == 0 or self.frame_bytes == 0 or self.reserved0 != 0 or self.flags & ~@as(u32, 3) != 0 or
            self.flags == (has_end | paused) or self.flags & has_end == 0 and self.end() != 0) return error.InvalidState;
        try (budget.ClockSample{ .identity = self.identity, .instant_ns = self.last_ns }).validate();
        if (self.flags & has_end != 0) _ = try ceilNs(self.end(), self.rate);
    }
    fn observe(self: *Pacer, sample: budget.ClockSample) Error!void {
        try self.check();
        try sample.validate();
        if (!std.meta.eql(self.identity, sample.identity)) return error.ClockChanged;
        if (sample.instant_ns < self.last_ns) return error.ClockRegressed;
        self.last_ns = sample.instant_ns;
    }
    /// Value remains unchanged on any failed observation/arithmetic. A wait
    /// budget is a source-time estimate, never permission to release DMA.
    pub fn deadline(self: *Pacer, sample: budget.ClockSample, finish_source: bool) Error!SourceDeadline {
        var value = self.*;
        try value.observe(sample);
        const present = value.flags & has_end != 0;
        const finish = if (present) value.end() else @as(u128, sample.instant_ns) * value.rate;
        const due = if (!present or finish_source) finish else finish -| (@as(u128, value.lead_frames) * std.time.ns_per_s);
        const now = @as(u128, sample.instant_ns) * value.rate;
        const result = SourceDeadline{ .identity = value.identity, .due_ns = try ceilNs(due, value.rate), .source_end_ns = try ceilNs(finish, value.rate), .accepted_frames = value.accepted_frames, .wait_ns = try ceilNs(due -| now, value.rate), .rate = value.rate, .frame_bytes = value.frame_bytes, .flags = value.flags };
        self.* = value;
        return result;
    }
    pub fn accepted(self: *Pacer, bytes: u64, write_started: budget.ClockSample) Error!SourceDeadline {
        var value = self.*;
        try value.observe(write_started);
        if (value.flags & paused != 0) return error.Paused;
        if (bytes % value.frame_bytes != 0) return error.InvalidFrame;
        if (bytes != 0) {
            const frames = bytes / value.frame_bytes;
            const count = std.math.add(u64, value.accepted_frames, frames) catch return error.BudgetOverflow;
            const start = @as(u128, write_started.instant_ns) * value.rate;
            const end_scaled = std.math.add(u128, @max(if (value.flags & has_end != 0) value.end() else start, start), @as(u128, frames) * std.time.ns_per_s) catch return error.BudgetOverflow;
            _ = try ceilNs(end_scaled, value.rate);
            value.accepted_frames = count;
            value.end_lo = @truncate(end_scaled);
            value.end_hi = @truncate(end_scaled >> 64);
            value.flags = has_end;
        }
        const result = try value.deadline(write_started, false);
        self.* = value;
        return result;
    }
    pub fn pause(self: *Pacer, sample: budget.ClockSample) Error!void {
        var value = self.*;
        try value.observe(sample);
        value.flags = paused;
        value.end_lo = 0;
        value.end_hi = 0;
        self.* = value;
    }
    pub fn resumeSource(self: *Pacer, sample: budget.ClockSample) Error!void {
        var value = self.*;
        try value.observe(sample);
        if (value.flags & paused == 0) return error.InvalidState;
        value.flags = 0;
        self.* = value;
    }
    pub fn reset(self: *Pacer, rate: u32, frame_bytes: u32, lead_frames: u64, sample: budget.ClockSample) Error!void {
        self.* = try init(rate, frame_bytes, lead_frames, sample);
    }
};
