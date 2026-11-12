//! A presentation source must already use the acknowledged output encoding.
//! Color conversion belongs to COLOR_V1, never to an implicit present copy.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;

pub fn canonical(source: *const d.Resource) bool {
    if (source.image.format != c.format_xrgb8888) return false;
    const description = source.color orelse return true; // Legacy RGBX contract.
    return matches(description, .{ .flags = 7, .format = c.format_xrgb8888, .bpc = 8, .primaries = 1, .transfer = 1, .range = 1,
        .reference_white = 1_000_000, .peak = 1_000_000 });
}
fn matches(description: c.R4GfxColorDescription, state: a.GfxOutputColorState) bool {
    return description.alpha == c.color_alpha_opaque and description.precision == state.bpc and
        description.primaries == state.primaries and description.transfer == state.transfer and description.range == state.range and
        description.reference_white == state.reference_white and description.peak == state.peak and description.black == state.black;
}
pub fn validate(device: *d.Device, source: *const d.Resource, output: ?a.GfxOutputTarget) d.Error!void {
    const base = device.base();
    if (!base.hasDrawFn("gfx_output_color")) {
        if (!canonical(source)) return error.Unsupported;
        return;
    }
    var selected = output;
    if (selected == null or selected.?.connector_id == 0) {
        selected = null;
        // Only the old, untargeted presentation entry uses this bounded
        // lookup. Modern swapchains carry their exact target already.
        for (0..8) |head| {
            var info: a.DisplayPresentationInfo = .{};
            if (base.displayPresentationInfo(@intCast(head), &info) != a.gfx_output_ok or
                info.flags & a.display_presentation_info_native == 0 or !std.meta.eql(info.backend, device.selected.binding)) continue;
            var target: a.GfxOutputTarget = .{};
            if (base.displayOutputTarget(info.backend.adapter_id, @intCast(head), &target) != a.gfx_output_ok) return error.Unavailable;
            selected = target; break;
        }
    }
    const target = selected orelse return error.Unavailable;
    const identity: a.GfxOutputId = .{ .adapter_id = target.adapter_id, .connector_id = target.connector_id,
        .device_generation = target.device_generation, .connection_generation = target.connection_generation };
    var state: a.GfxOutputColorState = .{};
    switch (base.gfxOutputColor(&identity, &state)) {
        a.gfx_output_ok => {},
        a.gfx_output_error_unsupported, a.err_no_fn => { if (!canonical(source)) return error.Unsupported; return; },
        a.gfx_output_error_stale => return error.Stale,
        a.gfx_output_error_busy => return error.Busy,
        else => return error.Unavailable,
    }
    if (state.version != 1 or state.size < 128 or state.flags & 7 != 7 or
        !std.meta.eql(state.identity, identity)) return error.Stale;
    if (source.image.format != state.format) return error.Unsupported;
    if (source.color) |description| {
        if (!matches(description, state)) return error.Unsupported;
    } else if (!canonical(source) or state.bpc != 8 or state.primaries != 1 or state.transfer != 1 or state.range != 1 or
        state.reference_white != 1_000_000 or state.peak != 1_000_000 or state.black != 0) return error.Unsupported;
}
