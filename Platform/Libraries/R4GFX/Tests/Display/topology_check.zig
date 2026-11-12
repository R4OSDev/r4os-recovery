const std = @import("std");
const t = std.testing;
const topology = @import("../../Display/topology.zig");
const Point = topology.Point;
const Rect = topology.Rect;
fn checkDocumentTextContracts() !void {
    const outputs = @import("../../Display/preferences.zig");
    const colors = @import("../../Display/color_preferences.zig");
    const refresh = @import("../../Display/refresh_preferences.zig");
    const brightness = @import("../../Display/brightness_preferences.zig");
    // External complete documents keep independent expectations. Headers and
    // per-schema errors must not become the tolerant R4STD entry grammar.
    inline for (.{ .{ outputs, "GFX_OUTPUTS_1" }, .{ colors, "GFX_COLOR_2" },
        .{ refresh, "GFX_REFRESH_1" }, .{ brightness, "GFX_BRIGHTNESS_1" } }) |document| {
        const Parser = document[0].Config;
        const header = "R4S_FORMAT=1\nSCHEMA=" ++ document[1] ++ "\n";
        const decorated = "\xef\xbb\xbf  # comment\r\n\t; comment\r\n  R4S_FORMAT=1 \t\r\nSCHEMA=" ++ document[1] ++ " \r\n";
        try t.expectEqual(@as(usize, 0), (try Parser.parse(decorated)).count);
        try t.expectError(error.Format, Parser.parse(header ++ "R4S_FORMAT=1\n"));
        try t.expectError(error.Format, Parser.parse(header ++ "SCHEMA=" ++ document[1] ++ "\n"));
        try t.expectError(error.Format, Parser.parse("SCHEMA=" ++ document[1] ++ "\n"));
        try t.expectError(error.Format, Parser.parse(header ++ "UNKNOWN=1\n"));
        try t.expectError(error.Format, Parser.parse("\xef\xbb\xbf" ++ decorated));
        try t.expectError(error.Format, Parser.parse("\xc2\xa0" ++ header));
    }
    const receiver = "01000000000000000000000000000000";
    inline for (.{ .{ refresh, "GFX_REFRESH_1", "1,0,1\n" },
        .{ brightness, "GFX_BRIGHTNESS_1", "1,1\n" } }) |document| {
        const Parser = document[0].Config;
        const header = "R4S_FORMAT=1\nSCHEMA=" ++ document[1] ++ "\n";
        const tail = ",2," ++ receiver ++ "," ++ document[2];
        try t.expectEqual(@as(usize, 1), (try Parser.parse(header ++ "DISPLAY=1" ++ tail)).count);
        try t.expectError(error.Invalid, Parser.parse(header ++ "DISPLAY=+1" ++ tail));
        try t.expectError(error.Invalid, Parser.parse(header ++ "DISPLAY=-1" ++ tail));
        try t.expectError(error.Invalid, Parser.parse(header ++ "DISPLAY=" ++ tail));
        try t.expectError(error.Format, Parser.parse(header ++ "DISPLAY=1\n"));
    }
    // These two original contracts differ from the shared strict unsigned
    // reader: leading plus is accepted; layout padding reports Number.
    const layout_header = "R4S_FORMAT=1\nSCHEMA=GFX_OUTPUTS_1\n";
    const layout_tail = ",2," ++ receiver ++ ",0,0,8,8,120,0,60000,3,0\n";
    try t.expectEqual(@as(usize, 1), (try outputs.Config.parse(layout_header ++ "OUTPUT=+1" ++ layout_tail)).count);
    try t.expectError(error.Number, outputs.Config.parse(layout_header ++ "OUTPUT= 1" ++ layout_tail));
    try t.expectEqual(@as(usize, 1), (try colors.Config.parse(
        "R4S_FORMAT=1\nSCHEMA=GFX_COLOR_1\nDISPLAY=+1,2," ++ receiver ++ ",1,1,NONE\n")).count);
}
pub fn check(report: *const @import("../../Display/edid.zig").Report) !void {
    try checkDocumentTextContracts();
    try checkDiscoveryBusy();
    const key = try topology.Key.fromReport(0x10de250401000900, 4, report);
    try t.expect(key.persistable());
    var refreshed = report.*;
    refreshed.mode_count = 0; // EDID mode changes do not rename the monitor.
    try t.expectEqualDeep(key, try topology.Key.fromReport(key.adapter, key.connector, &refreshed));
    var second = key; second.connector = 8;
    const outputs = [_]topology.Output{
        .{ .key = key, .primary = true, .view = .{ .pixel_w = 3840, .pixel_h = 2160, .scale = 240 }, .refresh_millihz = 60_000 },
        .{ .key = second, .view = .{ .origin = .{ .x = -1080 }, .pixel_w = 1920, .pixel_h = 1080, .rotation = .clockwise90 }, .refresh_millihz = 100_000 },
    };
    const layout = try topology.Layout.init(&outputs, 1);
    const control = @import("../../Display/control.zig");
    const wire_layout = control.encode(&layout);
    try t.expectEqualDeep(layout, try control.decode(&wire_layout));
    var bad_wire = wire_layout; bad_wire.outputs[0].scale = 0;
    try t.expectError(error.Invalid, control.decode(&bad_wire));
    bad_wire = wire_layout; bad_wire.outputs[0].rotation = 4;
    try t.expectError(error.Invalid, control.decode(&bad_wire));
    var translated = layout;
    for (translated.outputs[0..translated.count]) |*value| value.view.origin.x += 123;
    try t.expect(control.matches(&layout, &(try control.normalized(translated))));
    const preferences = @import("../../Display/preferences.zig");
    const saved = try (preferences.Config{}).remember(&layout);
    var text: [preferences.max_bytes]u8 = undefined;
    const encoded = try saved.encode(&text);
    const parsed = try preferences.Config.parse(encoded);
    try t.expectEqualDeep(saved, parsed);
    const colors = @import("../../Display/color_preferences.zig");
    var choice: colors.Choice = .{ .key = key, .intent = 1, .flags = 3 };
    try choice.setPath("C:\\Color Profiles\\Display, calibrated.icc");
    const first_color = try (colors.Config{}).remember(choice);
    var second_color = choice; second_color.key = second;
    try second_color.setPath("");
    const saved_colors = try first_color.remember(second_color);
    var color_bytes: [colors.max_bytes]u8 = undefined;
    const color_text = try saved_colors.encode(&color_bytes);
    try t.expectEqualDeep(saved_colors, try colors.Config.parse(color_text));
    try t.expect(!saved_colors.find(second).?.enabled());
    var changed_receiver = key; changed_receiver.receiver[0] ^= 1;
    try t.expect(saved_colors.find(changed_receiver) == null);
    var invalid_color = choice; invalid_color.key.receiver = @splat(0);
    try t.expectError(error.UnknownReceiver, first_color.remember(invalid_color));
    invalid_color = choice; invalid_color.flags = 4;
    try t.expectError(error.Invalid, first_color.remember(invalid_color));
    try t.expectError(error.Invalid, choice.setPath("relative.icc"));
    try t.expectError(error.Invalid, choice.setPath("C:\\display.icc\nDISPLAY=forged"));
    try t.expectError(error.Format, colors.Config.parse("R4S_FORMAT=1\nSCHEMA=GFX_COLOR_3\n"));
    // Disable one monitor without discarding an absent monitor's profile.
    try choice.setPath("");
    const disabled_color = try saved_colors.remember(choice);
    try t.expect(disabled_color.count == 2 and !disabled_color.find(key).?.enabled());
    var duplicate: [colors.max_bytes]u8 = undefined;
    const row = std.mem.indexOf(u8, color_text, "DISPLAY=").?;
    const line_end = std.mem.indexOfScalarPos(u8, color_text, row, '\n').? + 1;
    @memcpy(duplicate[0..color_text.len], color_text);
    @memcpy(duplicate[color_text.len..][0..line_end - row], color_text[row..line_end]);
    try t.expectError(error.Duplicate, colors.Config.parse(duplicate[0..color_text.len + line_end - row]));
    const catalog = @import("../../Display/desktop_outputs.zig");
    var hdr = second_color;
    hdr.signal = .{ .format = @import("r4os").abi.gfx_buffer_format_xrgb2101010, .bpc = 10, .primaries = 3, .transfer = 3, .range = 2,
        .pipeline = 7, .reference_white = 2_030_000, .peak = 10_000_000, .metadata_valid = 1,
        .metadata = .{ .max_mastering = 1000, .min_mastering = 50, .max_cll = 1000, .max_fall = 400 } };
    const hdr_config = try saved_colors.remember(hdr);
    try t.expectEqualDeep(hdr_config, try colors.Config.parse(try hdr_config.encode(&duplicate)));
    var bad_hdr = hdr; bad_hdr.signal.pipeline = 3;
    try t.expectError(error.Invalid, hdr_config.remember(bad_hdr));
    bad_hdr = hdr; try bad_hdr.setPath("C:\\display.icc");
    try t.expectError(error.Invalid, hdr_config.remember(bad_hdr));
    const old_text = try std.fmt.bufPrint(&duplicate, "R4S_FORMAT=1\nSCHEMA=GFX_COLOR_1\nDISPLAY={x},{d},{s},1,1,C:\\Old, profile.icc\n",
        .{ key.adapter, key.connector, std.fmt.bytesToHex(key.receiver, .lower) });
    const old_color = (try colors.Config.parse(old_text)).find(key).?;
    try t.expectEqualDeep(colors.sdr, old_color.signal);
    try t.expectEqualStrings("C:\\Old, profile.icc", std.mem.span(old_color.profilePath()));
    var first: catalog.Snapshot = .{ .count = 1, .revision = 9 };
    first.entries[0].key = key;
    var next = first;
    next.entries[0].presentation.sequence = 16;
    next.entries[0].presentation.observed_sequence = 15;
    next.entries[0].presentation.observed_ns = 700;
    try t.expect(first.sameOutputs(&next));
    next.entries[0].presentation.flags = @import("r4os").abi.display_presentation_info_occluded;
    try t.expect(!first.sameOutputs(&next));
    var restoration: catalog.modes.Restoration = .{};
    var identity: @import("r4os").abi.GfxOutputId = .{ .adapter_id = 17, .connector_id = 4,
        .device_generation = 3, .connection_generation = 7 };
    var color_restoration: catalog.color_control.Restoration = .{};
    try t.expect(!color_restoration.seen(hdr, identity));
    color_restoration.record(hdr, identity);
    try t.expect(color_restoration.seen(hdr, identity));
    bad_hdr = hdr; bad_hdr.signal.peak = 20_000_000;
    try t.expect(!color_restoration.seen(bad_hdr, identity));
    var reconnected = identity; reconnected.connection_generation += 1;
    try t.expect(!color_restoration.seen(hdr, reconnected));
    try t.expect(!restoration.seen(outputs[0], identity));
    restoration.record(outputs[0], identity);
    try t.expect(restoration.seen(outputs[0], identity));
    var different = outputs[0]; different.refresh_millihz = 100_000;
    try t.expect(!restoration.seen(different, identity));
    identity.connection_generation += 1;
    try t.expect(!restoration.seen(outputs[0], identity));
    restoration.record(outputs[0], identity);
    try t.expect(restoration.seen(outputs[0], identity));
    identity.device_generation += 1;
    try t.expect(!restoration.seen(outputs[0], identity));
    try t.expect(!catalog.modes.sameTiming(outputs[0], different));
    different.refresh_millihz = 0;
    try t.expect(catalog.modes.sameTiming(outputs[0], different));
    var unknown = key; unknown.receiver[0] ^= 1;
    try t.expect(parsed.find(unknown) == null);
    try t.expectEqualDeep(outputs[1], parsed.find(second).?);
    const primary_only = try topology.Layout.init(outputs[0..1], 2);
    const remembered = try parsed.remember(&primary_only);
    try t.expectEqualDeep(outputs[1], remembered.find(second).?);
    try t.expectError(error.Format, preferences.Config.parse("R4S_FORMAT=1\nSCHEMA=UNKNOWN\n"));
    try t.expectError(error.Format, preferences.Config.parse(encoded[0..encoded.len - 4]));
    try t.expectEqualDeep(Rect{ .w = 1920, .h = 1080 }, try outputs[0].view.logical());
    try t.expectEqualDeep(Rect{ .x = -1080, .w = 1080, .h = 1920 }, try outputs[1].view.logical());
    try t.expectEqualDeep(Point{ .x = 0, .y = 1079 }, try outputs[1].view.physical(.{ .x = -1080 }));
    try t.expectEqualDeep(Point{ .x = -1080 }, try outputs[1].view.fromPhysical(.{ .x = 0, .y = 1079 }));
    try t.expectEqual(@as(?usize, 1), layout.at(.{ .x = -1, .y = 700 }));
    try t.expectEqual(@as(?usize, 0), layout.at(.{ .x = 0, .y = 700 }));
    try t.expectEqual(@as(?usize, null), layout.at(.{ .x = 0, .y = 1080 }));
    const gap = layout.nearest(.{ .x = 500, .y = 1200 }).?;
    try t.expect(gap.index == 0 and gap.point.x == 500 and gap.point.y == 1079);
    try t.expect(outputs[0].interval().? == 16_666_666 and outputs[1].interval().? == 10_000_000);
    const desktop_window = Rect{ .x = -900, .y = 100, .w = 600, .h = 700 };
    try t.expectEqualDeep(desktop_window, try layout.rescue(desktop_window, 24));
    const unplugged = try topology.Layout.init(outputs[0..1], 2);
    try t.expectEqualDeep(Rect{ .x = 0, .y = 100, .w = 600, .h = 700 }, try unplugged.rescue(desktop_window, 24));
    try t.expectEqualDeep(Rect{ .x = 0, .y = 0, .w = 4000, .h = 3000 }, try unplugged.rescue(.{ .x = -5000, .y = -3000, .w = 4000, .h = 3000 }, 24));
    var clone = outputs;
    clone[0].clone_group = 1; clone[1].clone_group = 1;
    clone[1].view = .{ .pixel_w = 1920, .pixel_h = 1080 };
    const mirrored = try topology.Layout.init(&clone, 3);
    try t.expectEqual(@as(?usize, 0), mirrored.at(.{ .x = 700, .y = 900 }));
    try t.expect(clone[0].interval() != clone[1].interval()); // Geometry equality does not couple refresh.
    clone[1].view.origin.x = 1;
    try t.expectError(error.Clone, topology.Layout.init(&clone, 4));
    clone[0].clone_group = 0; clone[1].clone_group = 0;
    try t.expectError(error.Overlap, topology.Layout.init(&clone, 4));
    clone = outputs; clone[1].key = key;
    try t.expectError(error.Duplicate, topology.Layout.init(&clone, 4));
    clone = outputs; clone[1].primary = true;
    try t.expectError(error.Primary, topology.Layout.init(&clone, 4));
    clone = outputs; clone[0].enabled = false;
    try t.expectError(error.Primary, topology.Layout.init(&clone, 4));
    var invalid = outputs[0].view; invalid.scale = 0;
    try t.expectError(error.Invalid, invalid.logical());
    invalid = outputs[0].view; invalid.origin.x = std.math.maxInt(i32);
    try t.expectError(error.Bounds, invalid.logical());
    invalid = .{ .origin = .{ .x = std.math.maxInt(i32) - 127 }, .pixel_w = 128, .pixel_h = 1 };
    try t.expectError(error.Bounds, invalid.logical());
    var distant = outputs;
    distant[0].view = .{ .origin = .{ .x = std.math.minInt(i32) }, .pixel_w = 640, .pixel_h = 480 };
    distant[1].view = .{ .origin = .{ .x = std.math.maxInt(i32) - 640 }, .pixel_w = 640, .pixel_h = 480 };
    try t.expectError(error.Bounds, topology.Layout.init(&distant, 1));
    try t.expect(!(Rect{ .x = std.math.minInt(i32), .w = std.math.maxInt(u32), .h = 1 }).valid());
    const edge = topology.Viewport{ .origin = .{ .x = std.math.maxInt(i32) - 640, .y = std.math.maxInt(i32) - 480 },
        .pixel_w = 640, .pixel_h = 480 };
    try t.expectEqual(@as(i64, std.math.maxInt(i32)), (try edge.logical()).right());
    var shifted = outputs[0]; shifted.view = edge;
    const shifted_layout = try topology.Layout.init(&.{shifted}, 1);
    const normalized_edge = try control.normalized(shifted_layout);
    try t.expectEqualDeep(Rect{ .w = 640, .h = 480 }, try normalized_edge.outputs[0].view.logical());
    const fractional = topology.Viewport{ .origin = .{ .x = -2560, .y = -1440 }, .pixel_w = 3840, .pixel_h = 2160, .scale = 180 };
    try t.expectEqualDeep(Rect{ .x = -2560, .y = -1440, .w = 2560, .h = 1440 }, try fractional.logical());
    try t.expectEqualDeep(Rect{ .x = 1, .y = 1, .w = 2, .h = 2 }, (try fractional.physicalDamage(.{ .x = -2559, .y = -1439, .w = 1, .h = 1 })).?);
    for ([_]topology.Rotation{ .normal, .clockwise90, .clockwise180, .clockwise270 }) |rotation| {
        for ([_]u32{ 60, 120, 150, 180, 240 }) |scale| {
            const view = topology.Viewport{ .origin = .{ .x = -13, .y = 29 }, .pixel_w = 17, .pixel_h = 11, .scale = scale, .rotation = rotation };
            const full = try view.logical();
            try t.expectEqualDeep(Rect{ .w = 17, .h = 11 }, (try view.physicalDamage(full)).?);
            // Every native pixel maps into a logical cell whose conservative
            // damage includes it, including fractional and rotated edges.
            for (0..11) |y| for (0..17) |x| {
                const native = Point{ .x = @intCast(x), .y = @intCast(y) };
                const logical = try view.fromPhysical(native);
                try t.expect(full.contains(logical));
                const damage = (try view.physicalDamage(.{ .x = logical.x, .y = logical.y, .w = 1, .h = 1 })).?;
                try t.expect(damage.contains(native));
                const center = try view.physical(logical);
                try t.expect(center.x >= 0 and center.x < 17 and center.y >= 0 and center.y < 11);
                if (scale >= 120) try t.expectEqualDeep(logical, try view.fromPhysical(center));
            };
        }
    }
}

// The catalog is a transaction. An active head or receiver temporarily
// unavailable during native work cannot become a disconnected/session-only
// output in the next successful snapshot.
fn checkDiscoveryBusy() !void {
    const a = @import("r4os").abi;
    const catalog = @import("../../Display/desktop_outputs.zig");
    var draw: DiscoveryDraw = .{};
    const full = try catalog.Snapshot.read(&draw);
    try t.expect(full.count == 1 and full.entries[0].active() and full.entries[0].key.persistable());
    for ([_]i32{ a.gfx_output_error_busy, a.gfx_output_error_stale, a.gfx_output_error_unavailable }) |rc| {
        draw.target_result = rc;
        try t.expectError(error.Stale, catalog.Snapshot.read(&draw));
    }
    draw.target_result = a.gfx_output_ok;
    draw.receiver_result = a.gfx_output_error_busy;
    try t.expectError(error.Stale, catalog.Snapshot.read(&draw));
    draw.receiver_result = a.gfx_output_ok;
    try t.expect(full.sameOutputs(&(try catalog.Snapshot.read(&draw))));
    draw.target_result = a.gfx_output_error_unsupported;
    const absent = try catalog.Snapshot.read(&draw);
    try t.expect(absent.count == 1 and !absent.entries[0].active());
    draw.target_result = a.gfx_output_ok;
    draw.receiver_bytes = 0;
    const anonymous = try catalog.Snapshot.read(&draw);
    try t.expect(anonymous.entries[0].active() and !anonymous.entries[0].key.persistable());
}
const DiscoveryDraw = struct {
    const a = @import("r4os").abi;
    const bytes = @embedFile("Fixtures/qemu.edid");
    const identity: a.GfxOutputId = .{ .adapter_id = 17, .connector_id = 4, .device_generation = 3, .connection_generation = 7 };
    target_result: i32 = a.gfx_output_ok,
    receiver_result: i32 = a.gfx_output_ok,
    receiver_bytes: u32 = bytes.len,
    pub fn outputs(self: *const DiscoveryDraw) *const DiscoveryDraw { return self; }
    pub fn revision(_: *const DiscoveryDraw, out: *a.GfxDisplayRevision) i32 {
        out.* = .{ .revision = 9, .present = 1, .capacity = 32 }; return a.gfx_output_ok;
    }
    pub fn info(self: *const DiscoveryDraw, index: u32, out: *a.GfxOutputInfo) i32 {
        if (index != 0) return a.gfx_output_error_invalid;
        out.* = .{ .identity = identity, .topology_revision = 9, .edid_bytes = self.receiver_bytes,
            .flags = a.gfx_output_flag_connected | a.gfx_output_flag_active }; return a.gfx_output_ok;
    }
    pub fn color(_: *const DiscoveryDraw, _: *const a.GfxOutputId, _: *a.GfxOutputColorState) i32 { return a.gfx_output_error_unsupported; }
    pub fn edid(self: *const DiscoveryDraw, _: *const a.GfxOutputId, index: u32, out: *a.GfxEdidBlock) i32 {
        if (self.receiver_result != a.gfx_output_ok) return self.receiver_result;
        if (index >= bytes.len / 128) return a.gfx_output_error_invalid;
        out.* = .{ .identity = identity, .block_index = index, .byte_count = 128 };
        @memcpy(&out.data, bytes[@as(usize, index) * 128 ..][0..128]); return a.gfx_output_ok;
    }
    pub fn displayOutputTarget(self: *const DiscoveryDraw, _: u32, head: u32, out: *a.GfxOutputTarget) i32 {
        if (head != 0) return a.gfx_output_error_unsupported;
        if (self.target_result != a.gfx_output_ok) return self.target_result;
        out.* = .{ .adapter_id = identity.adapter_id, .connector_id = identity.connector_id, .device_generation = identity.device_generation,
            .connection_generation = identity.connection_generation, .display_generation = 5 }; return a.gfx_output_ok;
    }
    pub fn displayOutputPresentationInfo(_: *const DiscoveryDraw, _: *const a.GfxOutputTarget, out: *a.DisplayPresentationInfo) i32 {
        out.* = .{ .flags = a.display_presentation_info_native | a.display_presentation_info_active | a.display_presentation_info_visibility,
            .width = 1920, .height = 1080, .format = a.gfx_buffer_format_xrgb8888, .buffer_count = 2, .plane_count = 1,
            .interval_ns = 16_666_666, .policies = 3, .path = 1 }; return a.gfx_output_ok;
    }
};
