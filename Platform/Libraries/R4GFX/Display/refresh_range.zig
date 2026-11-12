// Receiver facts only. A frequency range alone does not enable Adaptive-Sync.
// Wire references: libdisplay-info (MIT), NVIDIA 570.144 timing headers (MIT),
// VESA DisplayID workshop 2023, archived under ExFiles/Reference/GFX/0.79.26.
const std = @import("std");
pub const Range = struct {
    min_millihz: u32 = 0,
    max_millihz: u32 = 0,

    pub fn valid(self: Range) bool {
        return self.min_millihz != 0 and self.max_millihz >= self.min_millihz;
    }
    pub fn contains(self: Range, millihz: u32) bool {
        return self.valid() and millihz >= self.min_millihz and millihz <= self.max_millihz;
    }
};
pub const EdidLimits = struct {
    refresh: Range,
    min_horizontal_hz: u32,
    max_horizontal_hz: u32,
    max_pixel_clock_hz: u64,
};
pub const DynamicLimits = struct {
    refresh: Range,
    min_pixel_clock_hz: u64,
    max_pixel_clock_hz: u64,
    seamless: bool,
};
pub const Hdmi = struct {
    refresh: Range = .{},
    // Keep HDMI QMS/FVA and duration flags distinct from ordinary VRR.
    flags: u8 = 0,
};
pub const Adaptive = struct {
    refresh: Range = .{},
    native: bool = false,
    adaptive_vtotal: bool = false,
    seamless: bool = false,
    increase_without_jitter: bool = false,
    decrease_without_jitter: bool = false,
    // Zero means no advertised successive-frame constraint, not zero delta.
    max_increase_us: u32 = 0,
    max_decrease_us: u32 = 0,
};
pub const Facts = struct {
    continuous_frequency: bool = false,
    edid: ?EdidLimits = null,
    hdmi: ?Hdmi = null,
    dynamic: ?DynamicLimits = null,
    adaptive: [16]Adaptive = @splat(.{}),
    adaptive_count: u8 = 0,

    pub fn addAdaptive(self: *Facts, value: Adaptive) bool {
        for (self.adaptive[0..self.adaptive_count]) |prior| {
            if (std.meta.eql(prior, value)) return true;
            if (prior.refresh.max_millihz == value.refresh.max_millihz and
                prior.native == value.native and prior.adaptive_vtotal == value.adaptive_vtotal) return false;
        }
        if (self.adaptive_count == self.adaptive.len) return false;
        self.adaptive[self.adaptive_count] = value;
        self.adaptive_count += 1;
        return true;
    }
};
