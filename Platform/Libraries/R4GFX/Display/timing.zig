// Register-independent timing facts. All arithmetic is integer and bounded.
const std = @import("std");
pub const interlaced: u32 = 1;
pub const h_positive: u32 = 2;
pub const v_positive: u32 = 4;
pub const preferred: u32 = 8;
pub const y420_only: u32 = 16;
pub const incomplete: u32 = 32;
pub const y420_allowed: u32 = 64;
pub const Timing = struct {
    width: u32 = 0,
    height: u32 = 0,
    h_total: u32 = 0,
    v_total: u32 = 0,
    h_start: u32 = 0,
    h_end: u32 = 0,
    v_start: u32 = 0,
    v_end: u32 = 0,
    clock_hz: u64 = 0,
    flags: u32 = 0,
    vic: u16 = 0,
    nominal_millihz: u32 = 0,

    pub fn valid(self: Timing) bool {
        return self.width > 0 and self.height > 0 and self.width <= 65536 and self.height <= 65536 and
            self.h_total <= 131072 and self.v_total <= 131072 and
            self.width <= self.h_start and self.h_start < self.h_end and self.h_end <= self.h_total and
            self.height <= self.v_start and self.v_start < self.v_end and self.v_end <= self.v_total and
            self.clock_hz > 0 and self.clock_hz <= 20_000_000_000;
    }
    pub fn millihz(self: Timing) u32 {
        if (!self.valid()) return self.nominal_millihz;
        const rate = self.clock_hz * 1000 * (if (self.flags & interlaced != 0) @as(u64, 2) else 1) /
            (@as(u64, self.h_total) * self.v_total);
        return @intCast(@min(rate, std.math.maxInt(u32)));
    }
    pub fn sameMode(a: Timing, b: Timing) bool {
        var x = a;
        var y = b;
        x.flags &= interlaced | h_positive | v_positive | incomplete;
        y.flags &= interlaced | h_positive | v_positive | incomplete;
        x.vic = 0;
        y.vic = 0;
        return std.meta.eql(x, y);
    }
};
