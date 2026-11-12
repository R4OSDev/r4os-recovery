const std = @import("std");
const edid = @import("Display/edid.zig");
const t = std.testing;
const qemu = @embedFile("Tests/Display/Fixtures/qemu.edid");
const television = @embedFile("Tests/Display/Fixtures/hisense-55u8k.edid");
const apple = @embedFile("Tests/Display/Fixtures/apple-xdr-dp.edid");
const ossipc = @embedFile("Tests/Display/Fixtures/ossipc-hisense-base.bin");
fn fix(bytes: []u8) void {
    var sum: u8 = 0;
    for (bytes[0 .. bytes.len - 1]) |byte| sum +%= byte;
    bytes[bytes.len - 1] = 0 -% sum;
}
fn contains(report: *const edid.Report, width: u32, height: u32) bool {
    for (report.modes[0..report.mode_count]) |mode| if (mode.width == width and mode.height == height and mode.valid()) return true;
    return false;
}
fn checkColorMetadata() !void {
    var bytes = qemu[0..256].*;
    bytes[23] = 120;
    bytes[24] |= 4;
    bytes[25] = 0x1b;
    bytes[26] = 0xe4;
    @memcpy(bytes[27..35], &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 });
    bytes[126] = 1;
    fix(bytes[0..128]);
    const block = bytes[128..];
    @memset(block, 0);
    block[0] = 2;
    block[1] = 3;
    block[2] = 26;
    @memcpy(block[4..26], &[_]u8{
        0x67, 3,    12,   0, 0x10, 0,  0xb8, 120,
        0xe6, 6,    13,   1, 96,   64, 128,  0xe2,
        0,    0xc0, 0xe3, 5, 0xe0, 0,
    });
    fix(block);
    var report: edid.Report = .{};
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.srgb_default and report.gamma_hundredths == 220);
    try t.expectEqualSlices(u16, &.{ 4, 9, 14, 19, 23, 26, 29, 32 }, &report.chromaticity);
    try t.expect(report.hdmi_deep_color == 3 and report.hdmi_deep_color_y444 and report.hdmi_deep_color_420 == 0);
    try t.expect(report.rgb_quantization_selectable and report.ycc_quantization_selectable);
    try t.expect(report.hdr_present and report.hdr_eotf == 13 and report.hdr_static == 1 and report.hdr_luminance_count == 3);
    try t.expectEqualSlices(u8, &.{ 96, 64, 128 }, &report.hdr_luminance);
    try checkColorSignal(report);
    const valid = bytes;
    for (0..4) |failure| {
        bytes = valid;
        switch (failure) {
            0 => block[12] = 0xe2, // Missing required descriptor byte.
            1 => block[16] = 0, // Minimum without maximum luminance.
            2 => block[17] = 97, // Frame average exceeds content maximum.
            3 => {
                block[2] = 30;
                @memcpy(block[26..30], &[_]u8{ 0xe3, 6, 5, 1 });
            }, // Conflicting duplicate.
            else => unreachable,
        }
        fix(block);
        try edid.parse(&bytes, &report);
        try t.expect(!report.complete() and !report.hdr_present and report.hdmi_deep_color == 0 and !report.rgb_quantization_selectable);
    }
    bytes = valid;
    block[16] = 0;
    block[17] = 0;
    block[18] = 0;
    fix(block);
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.hdr_present and report.hdr_luminance_count == 3);
    try t.expectEqualSlices(u8, &.{ 0, 0, 0 }, &report.hdr_luminance); // Unknown is preserved.
}
fn checkColorSignal(input: edid.Report) !void {
    const color = @import("Display/color_signal.zig");
    try t.expectEqual(@as(u32, 0xff101010), color.limitedRgb8(0));
    try t.expectEqual(@as(u32, 0xffebebeb), color.limitedRgb8(0xffffff));
    try t.expectEqual(@as(u32, 0xffeb1010), color.limitedRgb8(0xff0000));
    var previous: u32 = 16;
    for (0..256) |value| {
        const pixel = color.limitedRgb8(@intCast(value));
        try t.expect(pixel >> 8 == 0xff1010 and pixel & 255 >= previous and pixel & 255 <= 235);
        previous = pixel & 255;
    }
    var profile_signal = @import("Display/color_preferences.zig").sdr;
    try t.expect(color.profileEncoding(profile_signal));
    profile_signal.range = 2; try t.expect(color.profileEncoding(profile_signal));
    profile_signal.transfer = 3; try t.expect(!color.profileEncoding(profile_signal));
    var receiver = input;
    receiver.bits_per_color = 10;
    const metadata: color.Metadata = .{ .max_mastering = 1000, .min_mastering = 50, .max_cll = 1000, .max_fall = 400 };
    var signal: color.Signal = .{ .format = .xr30, .transfer = .pq, .primaries = .bt2020, .range = .full, .bpc = 10, .reference_white = 2_030_000, .peak = 4_000_000, .metadata = metadata };
    var source: color.Source = .{ .formats = 3, .bpc = 3, .primaries = 3, .ranges = 3, .eotf = 13, .static_metadata = true, .dp_vsc = true };
    var pipeline: color.Pipeline = .{ .linear_composition = true, .output_transform = true, .opaque_output = true };
    const hdmi: color.Link = .{ .hdmi = .{ .max_tmds_hz = 600_000_000, .scdc = true } };
    const native = try color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16);
    try t.expect(native.bpp == 30 and native.tmds_hz == 185_625_000 and !native.clear_hdr and native.metadata_bytes == 30);
    // Independent CTA wire bytes, including checksum and unequal units of
    // maximum1000nits and minimum0.005nits. Unknown xy stays zero.
    try t.expectEqualSlices(u8, &.{ 0x87, 1, 26, 0xc3, 2, 0 }, native.metadata[0..6]);
    for (native.metadata[6..22]) |byte| try t.expect(byte == 0);
    try t.expectEqualSlices(u8, &.{ 0xe8, 3, 50, 0, 0xe8, 3, 0x90, 1 }, native.metadata[22..30]);
    const light = color.luminance(receiver.hdr_luminance);
    try t.expectEqual(@as(f64, 400), light.maximum.?);
    try t.expectEqual(@as(f64, 200), light.frame_average.?);
    try t.expectApproxEqAbs(@as(f64, 1.007858516), light.minimum.?, 0.00000001);
    try t.expectEqualDeep(color.Luminance{}, color.luminance(.{ 0, 0, 0 }));
    try t.expectError(error.Bandwidth, color.admit(&receiver, signal, source, pipeline, hdmi, 594_000_000, 97));
    try t.expectError(error.Bandwidth, color.admit(&receiver, signal, source, pipeline, hdmi, 297_000_000, 95));
    receiver.scdc = true;
    _ = try color.admit(&receiver, signal, source, pipeline, hdmi, 297_000_000, 95);
    pipeline.output_transform = false;
    try t.expectError(error.Incomplete, color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16));
    pipeline.output_transform = true;
    source.formats = 1; // Native8-bit implementation cannot borrow the sink's10-bit claim.
    try t.expectError(error.Unsupported, color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16));
    source.formats = 3;
    source.static_metadata = false;
    try t.expectError(error.Unsupported, color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16));
    source.static_metadata = true;
    receiver.colorimetry = 0;
    try t.expectError(error.Unsupported, color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16));
    receiver.colorimetry = input.colorimetry;
    signal.metadata = null;
    try t.expectError(error.Incomplete, color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16));
    signal.metadata = metadata;
    const dp: color.Link = .{ .displayport = .{ .payload_bits_per_second = 17_280_000_000, .vsc = true, .hdr_sdp = true } };
    const packet = try color.admit(&receiver, signal, source, pipeline, dp, 148_500_000, 16);
    try t.expect(packet.metadata_bytes == 36 and packet.tmds_hz == 0);
    try t.expectEqualSlices(u8, &.{ 0, 0x87, 29, 0x4c, 1, 26 }, packet.metadata[0..6]);
    try t.expectEqualSlices(u8, native.metadata[4..30], packet.metadata[6..32]);
    source.dp_vsc = false;
    try t.expectError(error.Unsupported, color.admit(&receiver, signal, source, pipeline, dp, 148_500_000, 16));
    source.dp_vsc = true;
    try t.expectError(error.Bandwidth, color.admit(&receiver, signal, source, pipeline, .{ .displayport = .{ .payload_bits_per_second = 4_455_000_000, .vsc = true, .hdr_sdp = true } }, 148_500_000, 16));
    signal.transfer = .hlg;
    const hlg = try color.admit(&receiver, signal, source, pipeline, dp, 148_500_000, 16);
    try t.expect(hlg.metadata[6] == 3);
    signal = .{ .format = .xr24, .transfer = .srgb, .primaries = .bt709, .range = .full, .bpc = 8, .reference_white = 1_000_000, .peak = 1_000_000 };
    receiver.rgb_quantization_selectable = false;
    try t.expectError(error.Unsupported, color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16));
    const sdr = try color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 0);
    try t.expect(sdr.clear_hdr and sdr.metadata_bytes == 0 and sdr.bpp == 24);
    const a = @import("r4os").abi;
    var published: a.GfxOutputColorState = .{ .flags = 7, .format = a.gfx_buffer_format_xrgb8888, .bpc = 8, .primaries = 1, .transfer = 1, .range = 1, .reference_white = 1_000_000, .peak = 1_000_000, .formats = 1, .depths = 1, .color_spaces = 1, .ranges = 1, .transfers = 1, .max_tmds_clock_hz = 600_000_000 };
    const confirmed = try color.Source.fromPublished(published, .hdmi);
    try t.expect(!confirmed.static_metadata and !confirmed.dp_vsc and confirmed.eotf == 1);
    _ = try color.admit(&receiver, try color.publishedSignal(published, null), confirmed, pipeline, try color.publishedLink(published, .hdmi), 148_500_000, 0);
    published.flags &= ~@as(u32, 2);
    try t.expectError(error.Incomplete, color.publishedSignal(published, null));
    try t.expectError(error.Incomplete, color.publishedLink(published, .hdmi));
    published.flags = 7;
    published.formats = 4;
    try t.expectError(error.Invalid, color.Source.fromPublished(published, .hdmi));
    published.formats = 1;
    try t.expectError(error.Bandwidth, color.admit(&receiver, try color.publishedSignal(published, null), confirmed, pipeline, try color.publishedLink(published, .displayport), 148_500_000, 0));
    {
        var extended = published;
        extended.formats = 3; extended.depths = 3; extended.flags |= 32 | 16 | 64;
        extended.dp_payload_bits_per_second = 25_920_000_000;
        extended.link_kind = a.gfx_output_link_dp_sst; extended.link_flags = 3;
        extended.link_payload_bits_per_second = 25_142_400_000;
        extended.compressed_bpp_x16 = 256; extended.dsc_depths = 3;
        // Current DSC admits its own RGB8 signal. It cannot admit another
        // color depth using the old PPS or replace fresh candidate admission.
        _ = try color.admit(&receiver, signal, source, pipeline, try color.publishedLink(extended, .displayport), 1_188_000_000, 0);
        try color.preview(&receiver, signal, extended, .displayport, pipeline, 1_188_000_000, 0, 3840, 4400);
        extended.dsc_depths = 0;
        try t.expectError(error.Bandwidth, color.preview(&receiver, signal, extended, .displayport, pipeline, 1_188_000_000, 0, 3840, 4400));
        extended.dsc_depths = 3;
        var ten = signal; ten.format = .xr30; ten.bpc = 10;
        receiver.bits_per_color = 8; // DPCD DSC precision is independent of EDID base depth.
        try t.expectError(error.Unsupported, color.admit(&receiver, ten, source, pipeline, try color.publishedLink(extended, .displayport), 1_188_000_000, 0));
        try color.preview(&receiver, ten, extended, .displayport, pipeline, 1_188_000_000, 0, 3840, 4400);
        extended.dsc_depths = 1;
        try t.expectError(error.Unsupported, color.preview(&receiver, ten, extended, .displayport, pipeline, 1_188_000_000, 0, 3840, 4400));
        extended.dsc_depths = 3; extended.size = 128;
        try t.expectError(error.Bandwidth, color.preview(&receiver, signal, extended, .displayport, pipeline, 1_188_000_000, 0, 3840, 4400));
        extended.size = 192; extended.link_kind = a.gfx_output_link_frl; extended.link_flags = 1;
        extended.compressed_bpp_x16 = 0; extended.link_payload_bits_per_second = 42_666_666_666;
        extended.h_active = 3840; extended.h_total = 4400; extended.max_frl_rate = 6;
        receiver.scdc = true; receiver.hdmi_links = .{ .max_frl = .lanes4_12g };
        _ = try color.admit(&receiver, ten, source, pipeline, try color.publishedLink(extended, .hdmi), 1_188_000_000, 0);
        try color.preview(&receiver, ten, extended, .hdmi, pipeline, 1_188_000_000, 0, 3840, 4400);
        receiver.hdmi_links.?.max_frl = .lanes4_8g;
        try t.expectError(error.Bandwidth, color.preview(&receiver, ten, extended, .hdmi, pipeline, 1_188_000_000, 0, 3840, 4400));
        receiver.hdmi_links.?.max_frl = .lanes4_12g; extended.max_frl_rate = 0;
        try t.expectError(error.Bandwidth, color.preview(&receiver, ten, extended, .hdmi, pipeline, 1_188_000_000, 0, 3840, 4400));
        receiver.hdmi_links.?.dsc = .{ .advertised = true, .supported_fields = true, .bpc_mask = 3,
            .max_frl = .lanes3_6g, .max_slices = 8, .max_slice_clock_mhz = 400, .max_chunk_bytes = 8192 };
        receiver.hdmi_links.?.max_frl = .lanes3_6g;
        extended.max_frl_rate = 2; extended.dsc_depths = 3;
        receiver.hdmi_deep_color = 0;
        try color.preview(&receiver, ten, extended, .hdmi, pipeline, 1_188_000_000, 0, 3840, 4400);
        extended.link_flags = 3; extended.compressed_bpp_x16 = 192; extended.bpc = 10;
        extended.link_payload_bits_per_second = 16_000_000_000;
        _ = try color.admit(&receiver, ten, source, pipeline, try color.publishedLink(extended, .hdmi), 1_188_000_000, 0);
        try t.expectError(error.Unsupported, color.admit(&receiver, signal, source, pipeline, try color.publishedLink(extended, .hdmi), 1_188_000_000, 0));
        extended.dsc_depths = 0;
        try t.expectError(error.Unsupported, color.preview(&receiver, ten, extended, .hdmi, pipeline, 1_188_000_000, 0, 3840, 4400));
        receiver.bits_per_color = 10;
    }
    signal.range = .limited;
    _ = try color.admit(&receiver, signal, source, pipeline, hdmi, 148_500_000, 16);
    var bad = metadata;
    bad.max_cll = 100;
    try t.expectError(error.Invalid, color.hdmiMetadata(.pq, bad));
    bad = metadata;
    bad.primaries[0] = 65535;
    try t.expectError(error.Invalid, color.dpMetadata(.hlg, bad));
}
test "licensed receiver fixtures and actual OssiPC base preserve missing extension uncertainty" {
    var result: edid.Report = .{};
    try edid.parse(ossipc, &result);
    try t.expect(result.declared_extensions > 0);
    try t.expect(!result.complete());
    try t.expect(result.warnings & edid.Warning.missing != 0);
    try t.expectEqual(@as(usize, 0), result.audio_count);
    try t.expect(!result.hdmi and !result.basic_audio);
    try t.expect(!result.scdc and !result.scrambling_low_rates);
    try t.expect(result.mode_count > 0);
    try edid.parse(qemu, &result);
    try t.expect(result.complete());
    try t.expect(contains(&result, 1280, 800));
    try @import("Tests/Display/topology_check.zig").check(&result);
    var base = qemu[0..128].*;
    base[35] = 0x80;
    base[36] = 0;
    base[37] = 0;
    base[126] = 0;
    @memset(base[90..108], 0);
    base[93] = 0x10; // Replace the fixture's original range descriptor.
    @memset(base[108..126], 0);
    base[111] = 0xfd;
    base[112] = 0x0a; // legal EDID 1.4 maximum-rate offsets
    @memcpy(base[113..118], &[_]u8{ 24, 100, 15, 120, 60 });
    base[19] = 4;
    fix(&base);
    try edid.parse(&base, &result);
    var nominal = false;
    for (result.modes[0..result.mode_count]) |mode| {
        if (mode.width == 720 and mode.height == 400 and mode.millihz() == 70_000 and !mode.valid()) nominal = true;
    }
    try t.expect(nominal and result.complete());
    base[112] = 1;
    fix(&base);
    try t.expectError(error.InvalidBase, edid.parse(&base, &result));
    try edid.parse(television, &result);
    // Upstream's .ref diagnoses a 420 bitmap index 24 with only 19 SVDs.
    // The raw receiver blob is malformed; never silently accept its extension.
    try t.expect(result.warnings & edid.Warning.malformed != 0);
    try t.expect(!result.hdmi and result.audio_count == 0);
    try t.expect(!result.scdc and !result.scrambling_low_rates);
    var corrected = television[0..256].*;
    corrected[128 + 105] &= 7; // Test-only repair of the out-of-range bitmap.
    fix(corrected[128..]);
    try edid.parse(&corrected, &result);
    try t.expect(result.complete());
    try t.expect(result.hdmi and result.basic_audio and result.audio_count > 0);
    try t.expect(contains(&result, 3840, 2160));
    try t.expect(result.colors & 8 != 0);
    try t.expect(result.scdc and !result.scrambling_low_rates and result.max_tmds_hz == 600_000_000);
    try edid.parse(apple, &result);
    try t.expect(result.complete());
    try t.expectEqual(@as(u8, 6), result.valid_extensions);
    try t.expect(contains(&result, 6016, 3384));
}
test "extension checksums and malformed lengths cannot leak partial audio or timing claims" {
    try @import("Tests/Display/links_check.zig").check();
    try checkColorMetadata();
    try @import("Tests/Display/vrr_check.zig").check();
    var bytes = television[0..256].*;
    var result: edid.Report = .{};
    bytes[140] ^= 1;
    try edid.parse(&bytes, &result);
    try t.expect(result.warnings & edid.Warning.checksum != 0);
    try t.expect(!result.hdmi and !result.basic_audio and result.audio_count == 0);
    bytes = television[0..256].*;
    bytes[130] = 5; // One-byte collection cannot hold the original first block.
    fix(bytes[128..]);
    try edid.parse(&bytes, &result);
    try t.expect(result.warnings & edid.Warning.malformed != 0);
    try t.expect(!result.hdmi and result.audio_count == 0);
    // Each HF-VSDB flag is independent, and a bad later data block rolls
    // back capabilities from the entire extension, including these flags.
    for ([_]u8{ 0, 8, 128, 136 }) |flags| {
        bytes = qemu[0..256].*;
        @memset(bytes[128..], 0);
        const block = bytes[128..];
        block[0] = 2;
        block[1] = 3;
        block[2] = 12;
        block[4] = 0x67;
        block[5] = 0xd8;
        block[6] = 0x5d;
        block[7] = 0xc4;
        block[8] = 1;
        block[9] = 120;
        block[10] = flags;
        fix(block);
        try edid.parse(&bytes, &result);
        try t.expect(result.complete() and result.hdmi and result.max_tmds_hz == 600_000_000);
        try t.expect(result.scdc == (flags & 128 != 0) and result.scrambling_low_rates == (flags & 8 != 0));
        block[2] = 14;
        block[12] = 0x63;
        block[13] = 1;
        fix(block);
        try edid.parse(&bytes, &result);
        try t.expect(result.warnings & edid.Warning.malformed != 0 and !result.scdc and !result.scrambling_low_rates and !result.hdmi);
    }
    bytes = television[0..256].*;
    bytes[126] = 0;
    fix(bytes[0..128]);
    try edid.parse(&bytes, &result);
    try t.expect(result.warnings & edid.Warning.extra != 0);
    try t.expect(!result.hdmi and result.audio_count == 0);
    try t.expectError(error.Incomplete, edid.eld.encode(&result, @splat(0)));
}

test "complete CTA audio becomes bounded ELD without widening receiver PCM capabilities" {
    var bytes = qemu[0..256].*;
    @memset(bytes[128..], 0);
    const block = bytes[128..];
    block[0] = 2;
    block[1] = 3;
    block[2] = 18;
    block[3] = 0x40;
    // HDMI VSDB and a compressed-only SAD. Basic Audio still explicitly
    // guarantees 32/44.1/48-kHz stereo S16; ELD must carry that guarantee.
    @memcpy(block[4..14], &[_]u8{ 0x69, 3, 12, 0, 0x10, 0, 0x80, 30, 0x80, 0 });
    block[2] = 19;
    block[14] = 7; // Audio latency, complete advertised latency pair.
    @memcpy(block[15..19], &[_]u8{ 0x23, 0x15, 0x54, 0x32 });
    block[4] = 0x6a;
    fix(block);
    var report: edid.Report = .{};
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.hdmi and report.audio_infoframes and report.audio_latency == 7);
    const port = [8]u8{ 0x10, 0, 0, 0, 0, 0, 0, 0 };
    const encoded = try edid.eld.encode(&report, port);
    try t.expect(encoded.stereo_48k_s16 and encoded.max_frequency == 7);
    try t.expect(encoded.bytes[0] == 16 and encoded.bytes[5] == 0x22 and encoded.bytes[6] == 7);
    try t.expectEqualSlices(u8, &port, encoded.bytes[8..16]);
    const name_len = encoded.bytes[4] & 31;
    try t.expectEqualSlices(u8, &.{ 0x15, 0x54, 0x32, 0x09, 0x07, 0x01 }, encoded.bytes[20 + name_len ..][0..6]);
    try t.expect(encoded.baselineBytes() <= 80);
    for (encoded.bytes[26 + name_len ..]) |byte| try t.expectEqual(@as(u8, 0), byte);
    // Explicit SADs remain distinct. 16-bit at 44.1 kHz plus 24-bit at
    // 48 kHz cannot be merged into 48-kHz S16 support.
    report.basic_audio = false;
    report.audio_count = 2;
    report.audio[0] = .{ .format = 1, .channels = 2, .rates = 2, .detail = 1 };
    report.audio[1] = .{ .format = 1, .channels = 8, .rates = 4, .detail = 4 };
    try t.expect(!(try edid.eld.encode(&report, port)).stereo_48k_s16);
    report.audio[1].detail = 1;
    try t.expect((try edid.eld.encode(&report, port)).stereo_48k_s16);
    report.audio_count = report.audio.len + 1;
    try t.expectError(error.Invalid, edid.eld.encode(&report, port));
    try edid.parse(ossipc, &report);
    try t.expectError(error.Incomplete, edid.eld.encode(&report, port));
    // An extension without data blocks still carries its Basic Audio flag.
    @memset(block, 0);
    block[0] = 2;
    block[1] = 3;
    block[3] = 0x40;
    fix(block);
    try edid.parse(&bytes, &report);
    try t.expect(report.complete() and report.basic_audio and report.cta_revision == 3);
    try t.expectError(error.Unsupported, edid.eld.encode(&report, port)); // no HDMI declaration
    const dp = try edid.eld.encodeTransport(&report, port, .display_port);
    try t.expect(dp.stereo_48k_s16 and dp.bytes[5] & 15 == 4 and dp.bytes[6] == 0);
    try t.expectEqualSlices(u8, &port, dp.bytes[8..16]);
}
test "bounded parser rejects truncated base and preserves output on fatal errors" {
    var sentinel = edid.Report{ .serial = 0xcafe1234 };
    const before = sentinel;
    for (0..128) |len| try t.expectError(error.InvalidLength, edid.parse(qemu[0..len], &sentinel));
    try t.expectEqualDeep(before, sentinel);
    var bytes = qemu[0..256].*;
    bytes[127] ^= 1;
    try t.expectError(error.InvalidBase, edid.parse(&bytes, &sentinel));
    try t.expectEqualDeep(before, sentinel);
    var oversized: [edid.max_blocks * 128 + 128]u8 = .{0} ** (edid.max_blocks * 128 + 128);
    try t.expectError(error.TooLarge, edid.parse(&oversized, &sentinel));
    // Mutate every extension byte with a repaired outer checksum: malformed
    // nested lengths and timing arithmetic must remain bounded in ReleaseSafe.
    for (128..255) |index| {
        for ([_]u8{ 0, 1, 127, 128, 255 }) |value| {
            bytes = qemu[0..256].*;
            bytes[index] = value;
            fix(bytes[128..]);
            edid.parse(&bytes, &sentinel) catch |err| switch (err) {
                error.Capacity => {},
                else => return err,
            };
        }
    }
}
test "DisplayID v2 detailed timing validates its inner checksum and block bounds" {
    var bytes = qemu[0..256].*;
    @memset(bytes[128..], 0);
    const block = bytes[128..];
    block[0] = 0x70;
    block[1] = 0x20;
    block[2] = 23;
    block[3] = 2;
    block[5] = 0x22;
    block[6] = 0;
    block[7] = 20;
    const data = block[8..28];
    // Type VII: 148500 kHz - 1; 1920x1080, total 2200x1125.
    const clock: u32 = 148499;
    data[0] = @truncate(clock);
    data[1] = @truncate(clock >> 8);
    data[2] = @truncate(clock >> 16);
    data[3] = 128;
    for ([_]u16{ 1919, 279, 87, 43, 1079, 44, 3, 4 }, 0..) |value, i| {
        data[4 + 2 * i] = @truncate(value);
        data[5 + 2 * i] = @truncate(value >> 8);
    }
    fix(block[1..29]);
    fix(block);
    var report: edid.Report = .{};
    try edid.parse(&bytes, &report);
    try t.expect(report.complete());
    try t.expect(contains(&report, 1920, 1080));
    block[20] ^= 1;
    fix(block);
    try edid.parse(&bytes, &report);
    try t.expect(report.warnings & edid.Warning.malformed != 0);
    block[2] = 123;
    fix(block);
    try edid.parse(&bytes, &report);
    try t.expect(report.warnings & edid.Warning.malformed != 0);
}
test "CTA 420-only timing never becomes an ordinary RGB mode by accident" {
    var bytes = qemu[0..256].*;
    @memset(bytes[128..], 0);
    const block = bytes[128..];
    block[0] = 2;
    block[1] = 3;
    block[2] = 7;
    block[4] = 0xe2;
    block[5] = 0x0e;
    block[6] = 97;
    fix(block);
    var report: edid.Report = .{};
    try edid.parse(&bytes, &report);
    var found = false;
    for (report.modes[0..report.mode_count]) |mode| if (mode.vic == 97) {
        try t.expect(mode.flags & edid.timing.y420_only != 0);
        found = true;
    };
    try t.expect(found);
    block[2] = 9;
    block[7] = 0x41;
    block[8] = 97;
    fix(block);
    try edid.parse(&bytes, &report);
    for (report.modes[0..report.mode_count]) |mode| if (mode.vic == 97) try t.expect(mode.flags & edid.timing.y420_only == 0);
}
