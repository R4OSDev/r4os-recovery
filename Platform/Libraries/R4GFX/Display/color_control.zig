//! Userland color-mode policy. The driver repeats receiver/link admission at
//! commit; this early check never substitutes for its current hardware facts.
const std = @import("std");
const a = @import("r4os").abi;
const catalog = @import("desktop_outputs.zig");
const color = @import("color_signal.zig");
const preferences = @import("color_preferences.zig");

pub fn matches(state: a.GfxOutputColorState, signal: a.GfxColorSignal) bool {
    return state.flags & 7 == 7 and state.format == signal.format and state.bpc == signal.bpc and
        state.primaries == signal.primaries and state.transfer == signal.transfer and state.range == signal.range and
        state.reference_white == signal.reference_white and state.peak == signal.peak and state.black == signal.black;
}
pub fn canonical(state: a.GfxOutputColorState) bool { return matches(state, preferences.sdr); }
pub fn validate(draw: anytype, entry: *const catalog.Entry, mode: a.GfxOutputMode, request: a.GfxColorSignal) !void {
    const signal = try color.requestedSignal(request);
    const state = entry.color orelse return error.Incomplete;
    if (state.flags & 7 != 7 or !std.meta.eql(state.identity, entry.info.identity) or state.revision != entry.info.topology_revision) return error.Stale;
    const report = try catalog.readReceiver(draw, &entry.info);
    // The exposed timing must be exactly one of this receiver's timings.
    // In particular, geometry alone must not invent the HDMI default range.
    const vic = for (report.modes[0..report.mode_count]) |timing| {
        if (timing.width == mode.width and timing.height == mode.height and timing.clock_hz == mode.pixel_clock_hz and
            timing.h_total == mode.h_total and timing.v_total == mode.v_total and timing.h_start == mode.h_sync_start and
            timing.h_end == mode.h_sync_end and timing.v_start == mode.v_sync_start and timing.v_end == mode.v_sync_end)
            break timing.vic;
    } else return error.Incomplete;
    const transport: color.Transport = if (state.dp_payload_bits_per_second != 0) .displayport else if (report.hdmi) .hdmi else .dvi;
    try color.preview(&report, signal, state, transport,
        .{ .linear_composition = true, .output_transform = true, .opaque_output = true },
        mode.pixel_clock_hz, vic, mode.width, mode.h_total);
}

/// Attempt ledger is independent of mode/display generations changed by a
/// rollback. A saved choice gets one attempt per physical receiver lifetime.
pub const Restoration = struct {
    const Attempt = struct { key: catalog.topology.Key, identity: a.GfxOutputId, signal: a.GfxColorSignal };
    entries: [catalog.topology.capacity]?Attempt = @splat(null),
    pub fn seen(self: *const Restoration, choice: preferences.Choice, identity: a.GfxOutputId) bool {
        for (self.entries) |value| if (value) |entry| if (std.meta.eql(entry, Attempt{ .key = choice.key, .identity = identity, .signal = choice.signal })) return true;
        return false;
    }
    pub fn record(self: *Restoration, choice: preferences.Choice, identity: a.GfxOutputId) void {
        const index = for (self.entries, 0..) |value, i| {
            if (value) |entry| if (std.meta.eql(entry.key, choice.key)) break i;
        } else for (self.entries, 0..) |value, i| { if (value == null) break i; } else 0;
        self.entries[index] = .{ .key = choice.key, .identity = identity, .signal = choice.signal };
    }
};
