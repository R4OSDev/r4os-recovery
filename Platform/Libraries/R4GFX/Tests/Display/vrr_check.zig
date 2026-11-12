// Bounded scenarios within the existing receiver-data test group.
const std = @import("std");
const t = std.testing;
const edid = @import("../../Display/edid.zig");
const qemu = @embedFile("Fixtures/qemu.edid");
fn fix(bytes: []u8) void {
    var sum: u8 = 0;
    for (bytes[0 .. bytes.len - 1]) |value| sum +%= value;
    bytes[bytes.len - 1] = 0 -% sum;
}
fn fixture() [256]u8 {
    var bytes = qemu[0..256].*;
    bytes[19] = 4;
    bytes[24] |= 1;
    bytes[126] = 1;
    for (0..4) |i| {
        const descriptor = bytes[54 + 18 * i ..][0..18];
        if (descriptor[0] == 0 and descriptor[1] == 0 and descriptor[3] == 0xfd) {
            @memset(descriptor, 0);
            descriptor[3] = 0x10;
        }
    }
    @memset(bytes[108..126], 0);
    @memcpy(bytes[111..119], &[_]u8{ 0xfd, 0, 24, 144, 15, 200, 100, 1 });
    fix(bytes[0..128]);
    @memset(bytes[128..], 0);
    return bytes;
}
fn hdmi(bytes: *[256]u8, extended: bool) void {
    const block = bytes[128..];
    @memset(block, 0);
    block[0] = 2;
    block[1] = 3;
    block[2] = 15;
    @memcpy(block[4..15], &[_]u8{ 0x6a, 0xd8, 0x5d, 0xc4, 1, 120, 0x80, 0, 0, 48, 144 });
    if (extended) {
        block[4] = 0xea;
        block[5] = 0x79;
        block[6] = 0;
        block[7] = 0;
    }
    fix(block);
}
fn displayId(bytes: *[256]u8) void {
    const block = bytes[128..];
    @memset(block, 0);
    block[0] = 0x70;
    block[1] = 0x20;
    block[2] = 21;
    block[3] = 2;
    @memcpy(block[5..14], &[_]u8{ 0x2b, 0, 6, 0x27, 34, 48, 143, 0, 39 });
    // 25 MHz .. 600 MHz, seamless 48..144 Hz. DID2 clock units are kHz-1.
    @memcpy(block[14..26], &[_]u8{ 0x25, 1, 9, 0xa7, 0x61, 0, 0xbf, 0x27, 9, 48, 144, 128 });
    fix(block[1..27]);
    fix(block);
}
pub fn check() !void {
    try @import("refresh_client_check.zig").check();
    var bytes = fixture();
    hdmi(&bytes, false);
    var report: edid.Report = .{};
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.refresh.continuous_frequency);
    const limits = report.refresh.edid.?;
    try t.expect(limits.refresh.min_millihz == 24_000 and limits.refresh.max_millihz == 144_000);
    try t.expect(limits.min_horizontal_hz == 15_000 and limits.max_horizontal_hz == 200_000 and limits.max_pixel_clock_hz == 1_000_000_000);
    try t.expect(report.refresh.hdmi.?.refresh.min_millihz == 48_000 and report.refresh.hdmi.?.refresh.max_millihz == 144_000);
    hdmi(&bytes, true);
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.refresh.hdmi.?.refresh.max_millihz == 144_000);
    bytes[112] = 0xf;
    fix(bytes[0..128]);
    try edid.parse(&bytes, &report);
    try t.expect(report.refresh.edid.?.refresh.min_millihz == 279_000 and report.refresh.edid.?.refresh.max_millihz == 399_000);
    try t.expect(report.refresh.edid.?.min_horizontal_hz == 270_000);
    bytes = fixture();
    hdmi(&bytes, false);
    const valid = bytes;
    for (0..5) |fault| {
        bytes = valid;
        const block = bytes[128..];
        switch (fault) {
            0 => block[13] = 0, // Maximum without a minimum.
            1 => block[14] = 30, // Reversed range.
            2 => {
                block[2] = 14;
                block[4] = 0x69;
                block[14] = 0;
            }, // Missing maximum byte.
            3 => {
                block[2] = 26;
                @memcpy(block[15..26], block[4..15]);
                block[25] = 120;
            },
            4 => block[8] = 2, // Unknown HDMI SCDS version.
            else => unreachable,
        }
        fix(block);
        try edid.parse(&bytes, &report);
        try t.expect(!report.complete() and report.refresh.hdmi == null and !report.hdmi);
    }
    bytes = valid;
    bytes[113] = 0;
    fix(bytes[0..128]);
    try t.expectError(error.InvalidBase, edid.parse(&bytes, &report));
    bytes = fixture();
    displayId(&bytes);
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.refresh.adaptive_count == 1);
    const adaptive = report.refresh.adaptive[0];
    try t.expect(adaptive.native and adaptive.adaptive_vtotal and adaptive.seamless);
    try t.expect(adaptive.refresh.min_millihz == 48_000 and adaptive.refresh.max_millihz == 144_000);
    try t.expect(adaptive.max_increase_us == 8500 and adaptive.max_decrease_us == 9750);
    const dynamic = report.refresh.dynamic.?;
    try t.expect(dynamic.seamless and dynamic.min_pixel_clock_hz == 25_000_000 and dynamic.max_pixel_clock_hz == 600_000_000);
    const did = bytes;
    for (0..5) |fault| {
        bytes = did;
        const block = bytes[128..];
        switch (fault) {
            0 => block[8] |= 0x40, // Reserved descriptor flag.
            1 => block[8] |= 8, // Reserved operating mode.
            2 => block[12] = 4, // Reserved high refresh bits.
            3 => block[6] = 0x10, // Unknown descriptor length.
            4 => block[25] |= 4, // Reserved dynamic-range flag.
            else => unreachable,
        }
        fix(block[1..27]);
        fix(block);
        try edid.parse(&bytes, &report);
        try t.expect(!report.complete() and report.refresh.adaptive_count == 0 and report.refresh.dynamic == null);
    }
    bytes = did;
    bytes[136] &= ~@as(u8, 4);
    fix(bytes[129..155]);
    fix(bytes[128..]);
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and !report.refresh.adaptive[0].adaptive_vtotal); // FAVT is not gaming VRR.
    try edid.parse(bytes[0..128], &report);
    try t.expect(!report.complete() and report.refresh.adaptive_count == 0 and report.refresh.edid != null);
    try admissionAndScheduling();
    try observations();
}

fn mode144() edid.timing.Timing {
    return .{ .width = 1920, .height = 1080, .h_total = 2200, .h_start = 2008, .h_end = 2052, .v_total = 1125, .v_start = 1084, .v_end = 1089, .clock_hz = 356_400_000 };
}
fn admissionAndScheduling() !void {
    const vrr = edid.vrr;
    var bytes = fixture();
    hdmi(&bytes, false);
    var report: edid.Report = .{};
    try edid.parse(&bytes, &report);
    const source: vrr.Source = .{ .adaptive = true, .dp_ignore_msa = true, .hdmi_emp = true, .direct_sst = true, .max_vtotal = 65535, .max_timeout_us = 4_194_303, .minimum_span_permille = 1100 };
    const plan = try vrr.admit(&report, mode144(), .hdmi, source);
    try t.expect(plan.origin == .hdmi_forum and plan.range.max_millihz == 144_000 and !plan.lfc);
    try t.expect(plan.min_period_ns == 6_944_445 and plan.max_period_ns == 20_833_000);
    try t.expect(plan.range.min_millihz == 48_001 and plan.max_vtotal == 3375);
    var rejected = source;
    rejected.adaptive = false;
    try t.expectError(error.Unsupported, vrr.admit(&report, mode144(), .hdmi, rejected));
    rejected = source;
    rejected.dp_ignore_msa = false;
    try t.expectError(error.Unsupported, vrr.admit(&report, mode144(), .displayport, rejected));
    rejected = source;
    rejected.max_vtotal = 1125;
    try t.expectError(error.Range, vrr.admit(&report, mode144(), .hdmi, rejected));
    var invalid = mode144();
    invalid.flags |= edid.timing.interlaced;
    try t.expectError(error.Timing, vrr.admit(&report, invalid, .hdmi, source));
    invalid = mode144();
    invalid.clock_hz = 400_000_000;
    try t.expectError(error.Range, vrr.admit(&report, invalid, .hdmi, source));
    try edid.parse(bytes[0..128], &report);
    try t.expectError(error.Incomplete, vrr.admit(&report, mode144(), .hdmi, source));
    bytes = fixture();
    displayId(&bytes);
    try edid.parse(&bytes, &report);
    const adaptive = try vrr.admit(&report, mode144(), .displayport, source);
    try t.expect(adaptive.origin == .adaptive_displayid and adaptive.max_increase_ns == 8_500_000);
    report.refresh.adaptive[0].adaptive_vtotal = false;
    try t.expectError(error.Unsupported, vrr.admit(&report, mode144(), .displayport, source));
    report.refresh.adaptive_count = 0;
    _ = try vrr.admit(&report, mode144(), .displayport, source);
    report.refresh.dynamic.?.max_pixel_clock_hz = 300_000_000;
    try t.expectError(error.Timing, vrr.admit(&report, mode144(), .displayport, source));
    report.refresh.dynamic = null;
    try t.expect((try vrr.admit(&report, mode144(), .displayport, source)).origin == .edid);
    report.refresh.continuous_frequency = false;
    try t.expectError(error.Unsupported, vrr.admit(&report, mode144(), .displayport, source));
    var scheduler: vrr.Scheduler = .{};
    try scheduler.configure(7, plan);
    var scene: vrr.Scene = .{ .policy = .fullscreen, .fullscreen = true, .animated = true, .composed = true, .output_ready = true };
    try t.expect(scheduler.select(scene) == .enable and scheduler.state == .enabling);
    try t.expectError(error.State, scheduler.frame(1, 1));
    try t.expectError(error.Stale, scheduler.acknowledged(6, true));
    try scheduler.acknowledged(7, true);
    try scheduler.observed(7, 1_000_000_000);
    const fast = try scheduler.frame(1_001_000_000, 1_001_000_000);
    try t.expect(fast.submit_ns == 1_006_944_445 and !fast.repeat); // Above range waits, never tears.
    const inside = try scheduler.frame(1_010_000_000, 1_010_000_000);
    try t.expect(inside.submit_ns == 1_010_000_000 and !inside.repeat);
    const slow = try scheduler.frame(1_011_000_000, 1_030_000_000);
    try t.expect(slow.repeat and slow.submit_ns == 1_020_833_000); // Retained image, not LFC.
    try t.expectError(error.Clock, scheduler.frame(1_010_000_000, null));
    scene.capture_active = true;
    try t.expect(scheduler.select(scene) == .disable and scheduler.state == .disabling and scheduler.reason == .capture);
    try scheduler.acknowledged(7, false);
    scene.capture_active = false;
    scene.mode_or_color_pending = true;
    try t.expect(scheduler.select(scene) == .none and scheduler.reason == .transition);
    scene.mode_or_color_pending = false;
    scene.hdr_active = true;
    try t.expect(scheduler.select(scene) == .none and scheduler.reason == .hdr);
    scene.hdr_compatible = true;
    scene.head_count = 2;
    try t.expect(scheduler.select(scene) == .none and scheduler.reason == .topology);
    scene.independent_heads = true;
    scene.audio_clock_independent = false;
    try t.expect(scheduler.select(scene) == .none and scheduler.reason == .audio_clock);
    scene.audio_clock_independent = true;
    scene.fullscreen = false;
    try t.expect(scheduler.select(scene) == .none and scheduler.reason == .windowed);
    scene.policy = .animated_windows;
    try t.expect(scheduler.select(scene) == .enable);
    try scheduler.acknowledged(7, true);
    try t.expect(scheduler.fail(.user_flicker) == .disable);
    try scheduler.acknowledged(7, false);
    try t.expect(scheduler.state == .faulted and scheduler.select(scene) == .none); // No re-enable loop.
    try scheduler.configure(8, adaptive); // Explicit retry or new output generation.
    try t.expect(scheduler.select(scene) == .enable);
    try scheduler.acknowledged(8, true);
    try scheduler.observed(8, 1_000_000_000);
    try scheduler.observed(8, 1_007_000_000);
    const ramp = try scheduler.frame(1_008_000_000, null);
    try t.expect(ramp.repeat and ramp.submit_ns == 1_022_500_000); // 7 ms + 8.5 ms advertised step limit.
    try t.expectError(error.Clock, scheduler.frame(2_000_000_000, null));
}
fn observations() !void {
    const obs = edid.vrr.observation;
    var observer: obs.Observer = .{};
    observer.reset(9);
    try t.expect(observer.summary().samples == 0);
    try t.expect(observer.feed(9, 1, 65535, 1_000_000_000) == .baseline);
    try t.expect(observer.feed(9, 2, 0, 1_010_000_000) == .sample);
    try t.expect(observer.feed(9, 3, 1, 1_030_000_000) == .sample);
    const value = observer.summary();
    try t.expect(value.samples == 2 and value.min_ns == 10_000_000 and value.max_ns == 20_000_000 and value.mean_ns == 15_000_000 and value.millihz == 66_666);
    try t.expect(observer.feed(8, 4, 2, 1_040_000_000) == .stale);
    try t.expect(observer.feed(9, 3, 1, 1_030_000_000) == .duplicate);
    try t.expect(observer.feed(9, 4, 2, 1_020_000_000) == .clock);
    try t.expect(observer.summary().samples == 2);
    try t.expect(observer.feed(9, 5, 3, 1_050_000_000) == .gap);
    try t.expect(observer.summary().samples == 0 and observer.gaps == 1);
    try t.expect(observer.feed(9, 6, 4, 1_060_000_000) == .sample);
    observer.reset(10);
    try t.expect(observer.summary().samples == 0);
}
