// A bounded history of consecutive hardware-frame observations. Nominal
// mode clocks, submits, timer wakes and synthetic repeats are not samples.
const std = @import("std");
pub const Result = enum { baseline, sample, duplicate, gap, stale, clock };
pub const Summary = struct {
    samples: u32 = 0,
    last_ns: u64 = 0,
    min_ns: u64 = 0,
    max_ns: u64 = 0,
    mean_ns: u64 = 0,
    millihz: u32 = 0,
};
pub const Observer = struct {
    generation: u64 = 0,
    sequence: u64 = 0,
    frame_counter: u16 = 0,
    observed_ns: u64 = 0,
    periods: [32]u64 = @splat(0),
    count: u8 = 0,
    index: u8 = 0,
    gaps: u64 = 0,

    pub fn reset(self: *Observer, generation: u64) void {
        self.* = .{ .generation = generation };
    }
    pub fn feed(self: *Observer, generation: u64, sequence: u64, frame_counter: u16, ns: u64) Result {
        if (generation == 0 or generation != self.generation or sequence == 0) return .stale;
        if (sequence == self.sequence) return .duplicate;
        if (sequence < self.sequence) return .stale;
        if (ns == 0 or ns == std.math.maxInt(u64) or ns <= self.observed_ns) return .clock;
        var result: Result = .baseline;
        if (self.sequence != 0) {
            if (sequence - self.sequence == 1 and frame_counter -% self.frame_counter == 1) {
                const period = ns - self.observed_ns;
                // A >4-second interval exceeds the display-rate hardware
                // limit. Keep its timestamp as a baseline, not a measurement.
                if (period <= 4_194_303_000) {
                    self.periods[self.index] = period;
                    self.index = @intCast((@as(usize, self.index) + 1) % self.periods.len);
                    self.count = @intCast(@min(@as(usize, self.count) + 1, self.periods.len));
                    result = .sample;
                } else result = .gap;
            } else result = .gap;
        }
        if (result == .gap) {
            self.count = 0;
            self.index = 0;
            self.gaps +|= 1;
        }
        self.sequence = sequence;
        self.frame_counter = frame_counter;
        self.observed_ns = ns;
        return result;
    }
    pub fn summary(self: *const Observer) Summary {
        if (self.count == 0) return .{};
        var result: Summary = .{ .samples = self.count, .min_ns = std.math.maxInt(u64), .last_ns = self.periods[(@as(usize, self.index) + self.periods.len - 1) % self.periods.len] };
        var total: u64 = 0;
        for (self.periods[0..self.count]) |period| {
            result.min_ns = @min(result.min_ns, period);
            result.max_ns = @max(result.max_ns, period);
            total += period;
        }
        result.mean_ns = total / self.count;
        result.millihz = @intCast(@min(std.math.maxInt(u32), 1_000_000_000_000 / result.mean_ns));
        return result;
    }
};
