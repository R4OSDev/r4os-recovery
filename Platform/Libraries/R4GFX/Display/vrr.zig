// Shared admission and frame decisions. Hardware transport/ACKs stay in R4D;
// desktop policy and content ownership stay with the output's presenter.
const std = @import("std");
const timing = @import("timing.zig");
const facts = @import("refresh_range.zig");
pub const observation = @import("refresh_observer.zig");
pub const Error = error{ Incomplete, Unsupported, Timing, Range, Clock, State, Stale };
pub const Link = enum { hdmi, displayport };
pub const Source = struct {
    adaptive: bool = false,
    // Source support and receiver DPCD support must both have been read.
    dp_ignore_msa: bool = false,
    hdmi_emp: bool = false,
    direct_sst: bool = false,
    max_vtotal: u32 = 0,
    max_timeout_us: u32 = 0,
    minimum_span_permille: u32 = 1000,
};
pub const Origin = enum(u32) { edid = 1, dynamic_displayid = 2, adaptive_displayid = 3, hdmi_forum = 4 };
pub const Plan = struct {
    origin: Origin,
    range: facts.Range,
    min_period_ns: u64,
    max_period_ns: u64,
    timeout_us: u32,
    max_vtotal: u32,
    max_increase_ns: u64 = 0,
    max_decrease_ns: u64 = 0,
    // No LFC claim from a wide receiver range. Repeats below the minimum
    // preserve the last frame; LFC requires a separate implemented cadence.
    lfc: bool = false,
};
fn ceilRatio(numerator: u128, denominator: u128) u64 {
    return @intCast((numerator + denominator - 1) / denominator);
}
pub fn admit(receiver: anytype, mode: timing.Timing, link: Link, source: Source) Error!Plan {
    if (!receiver.complete() or !receiver.digital) return error.Incomplete;
    if (!source.adaptive or !source.direct_sst) return error.Unsupported;
    if (!mode.valid() or mode.flags & (timing.interlaced | timing.incomplete | timing.y420_only) != 0 or
        mode.v_start == mode.height or source.max_vtotal < mode.v_total or source.max_vtotal > 131072 or
        source.max_timeout_us == 0 or source.max_timeout_us > 4_194_303 or
        source.minimum_span_permille < 1000 or source.minimum_span_permille > 4000) return error.Timing;
    var selected: facts.Range = .{};
    var origin: Origin = undefined;
    var increase_ns: u64 = 0;
    var decrease_ns: u64 = 0;
    const nominal = mode.millihz();
    const limits = &receiver.refresh;
    switch (link) {
        .hdmi => {
            if (!receiver.hdmi or !source.hdmi_emp) return error.Unsupported;
            selected = (limits.hdmi orelse return error.Incomplete).refresh;
            origin = .hdmi_forum;
        },
        .displayport => {
            if (!source.dp_ignore_msa) return error.Unsupported;
            if (limits.adaptive_count != 0) {
                var chosen: ?facts.Adaptive = null;
                const rounded = (nominal + 500) / 1000 * 1000;
                for (limits.adaptive[0..limits.adaptive_count]) |value| {
                    if (value.refresh.max_millihz != rounded) continue;
                    if (chosen) |prior| {
                        if (prior.native == value.native) return error.Range;
                        if (prior.native) continue;
                    }
                    chosen = value;
                }
                const value = chosen orelse return error.Range;
                if (!value.adaptive_vtotal or !value.seamless) return error.Unsupported;
                selected = value.refresh;
                increase_ns = @as(u64, value.max_increase_us) * 1000;
                decrease_ns = @as(u64, value.max_decrease_us) * 1000;
                origin = .adaptive_displayid;
            } else if (limits.dynamic) |value| {
                if (!value.seamless) return error.Unsupported;
                if (mode.clock_hz < value.min_pixel_clock_hz or mode.clock_hz > value.max_pixel_clock_hz) return error.Timing;
                selected = value.refresh;
                origin = .dynamic_displayid;
            } else if (limits.edid) |value| {
                if (!limits.continuous_frequency) return error.Unsupported;
                const horizontal = mode.clock_hz / mode.h_total;
                if (horizontal < value.min_horizontal_hz or horizontal > value.max_horizontal_hz or
                    (value.max_pixel_clock_hz != 0 and mode.clock_hz > value.max_pixel_clock_hz)) return error.Timing;
                selected = value.refresh;
                origin = .edid;
            } else return error.Incomplete;
        },
    }
    if (!selected.contains(nominal) or @as(u64, nominal) * 1000 < @as(u64, selected.min_millihz) * source.minimum_span_permille) return error.Range;
    // VRR extends blanking only; it never makes this mode scan faster.
    const min_ns = ceilRatio(@as(u128, mode.h_total) * mode.v_total * 1_000_000_000, mode.clock_hz);
    const max_total: u32 = @intCast(@min(source.max_vtotal, @as(u128, mode.clock_hz) * 1000 / (@as(u128, mode.h_total) * selected.min_millihz)));
    const timeout: u32 = @intCast(@min(source.max_timeout_us, @as(u128, max_total) * mode.h_total * 1_000_000 / mode.clock_hz));
    const max_ns = @as(u64, timeout) * 1000;
    if (max_total <= mode.v_total or max_ns <= min_ns) return error.Range;
    return .{ .origin = origin, .range = .{ .min_millihz = @intCast(ceilRatio(1_000_000_000_000, max_ns)), .max_millihz = nominal }, .min_period_ns = min_ns, .max_period_ns = max_ns, .timeout_us = timeout, .max_vtotal = max_total, .max_increase_ns = increase_ns, .max_decrease_ns = decrease_ns };
}

pub const Policy = enum(u32) { off = 0, fullscreen = 1, animated_windows = 2 };
pub const Reason = enum(u32) {
    none = 0,
    policy_off,
    idle,
    windowed,
    unavailable,
    transition,
    hdr,
    topology,
    capture,
    audio_clock,
    link_lost,
    timing_fault,
    user_flicker,
    stale_clock,
};
pub const Scene = struct {
    policy: Policy = .off,
    fullscreen: bool = false,
    animated: bool = false,
    direct_scanout: bool = false,
    composed: bool = false,
    output_ready: bool = false,
    mode_or_color_pending: bool = false,
    hdr_active: bool = false,
    hdr_compatible: bool = false,
    independent_heads: bool = false,
    head_count: u32 = 1,
    capture_active: bool = false,
    audio_clock_independent: bool = true,

    pub fn reason(self: Scene) Reason {
        if (self.policy == .off) return .policy_off;
        if (!self.output_ready or self.direct_scanout == self.composed) return .unavailable;
        if (self.mode_or_color_pending) return .transition;
        if (!self.animated) return .idle;
        if (self.policy == .fullscreen and !self.fullscreen) return .windowed;
        if (self.hdr_active and !self.hdr_compatible) return .hdr;
        if (self.head_count == 0 or (self.head_count > 1 and !self.independent_heads)) return .topology;
        if (self.capture_active) return .capture;
        if (!self.audio_clock_independent) return .audio_clock;
        return .none;
    }
};
pub const State = enum(u32) { fixed = 0, enabling, active, disabling, faulted };
pub const Switch = enum { none, enable, disable };
pub const Frame = struct { submit_ns: u64, deadline_ns: u64, repeat: bool };
pub const Scheduler = struct {
    state: State = .fixed,
    reason: Reason = .policy_off,
    generation: u64 = 0,
    plan: ?Plan = null,
    observed_ns: u64 = 0,
    previous_period_ns: u64 = 0,
    last_now: u64 = 0,
    fault: Reason = .none,

    pub fn configure(self: *Scheduler, generation: u64, plan: ?Plan) Error!void {
        if (generation == 0 or self.state == .active or self.state == .enabling or self.state == .disabling) return error.State;
        self.* = .{ .generation = generation, .plan = plan };
    }
    // Return an operation, not a success claim. The owner must ACK the real
    // driver transaction before active/fixed becomes visible.
    pub fn select(self: *Scheduler, scene: Scene) Switch {
        self.reason = if (self.fault != .none) self.fault else if (self.plan == null) .unavailable else scene.reason();
        if (self.state == .fixed and self.reason == .none) {
            self.state = .enabling;
            return .enable;
        }
        if (self.state == .active and self.reason != .none) {
            self.state = .disabling;
            return .disable;
        }
        return .none;
    }
    pub fn acknowledged(self: *Scheduler, generation: u64, enabled: bool) Error!void {
        if (generation != self.generation) return error.Stale;
        if ((enabled and self.state != .enabling) or (!enabled and self.state != .disabling)) return error.State;
        self.state = if (enabled) .active else if (self.fault == .none) .fixed else .faulted;
        self.observed_ns = 0;
        self.previous_period_ns = 0;
    }
    pub fn observed(self: *Scheduler, generation: u64, ns: u64) Error!void {
        if (generation != self.generation) return error.Stale;
        if (ns == 0 or ns <= self.observed_ns) return error.Clock;
        if (self.observed_ns != 0) self.previous_period_ns = ns - self.observed_ns;
        self.observed_ns = ns;
    }
    pub fn fail(self: *Scheduler, reason: Reason) Switch {
        self.fault = reason;
        self.reason = reason;
        return self.select(.{});
    }
    // Last observed scanout bounds the next frame. A late frame leaves the
    // retained image in place for the hardware minimum-refresh timeout.
    pub fn frame(self: *Scheduler, now: u64, ready_ns: ?u64) Error!Frame {
        if (self.state != .active or self.observed_ns == 0) return error.State;
        const plan = self.plan orelse return error.State;
        if (now < self.last_now or now < self.observed_ns or now == std.math.maxInt(u64)) return error.Clock;
        self.last_now = now;
        const min_ns = std.math.add(u64, self.observed_ns, plan.min_period_ns) catch return error.Clock;
        var max_ns = std.math.add(u64, self.observed_ns, plan.max_period_ns) catch return error.Clock;
        var earliest = min_ns;
        if (self.previous_period_ns != 0) {
            if (plan.max_increase_ns != 0) max_ns = @min(max_ns, std.math.add(u64, self.observed_ns, std.math.add(u64, self.previous_period_ns, plan.max_increase_ns) catch return error.Clock) catch return error.Clock);
            if (plan.max_decrease_ns != 0) earliest = @max(earliest, std.math.add(u64, self.observed_ns, self.previous_period_ns -| plan.max_decrease_ns) catch return error.Clock);
        }
        if (earliest > max_ns) return error.Timing;
        if (now - self.observed_ns > plan.max_period_ns * 3) return error.Clock;
        if (ready_ns) |ready| {
            const submit = @max(now, @max(ready, earliest));
            if (submit <= max_ns) return .{ .submit_ns = submit, .deadline_ns = max_ns, .repeat = false };
        }
        return .{ .submit_ns = max_ns, .deadline_ns = max_ns, .repeat = true };
    }
};
