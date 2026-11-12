// Bounded receiver-data parser. No I/O, allocator, hardware policy or globals.
// Protocol facts: locally pinned libdisplay-info interfaces and fixtures.
const std = @import("std");
pub const timing = @import("timing.zig");
pub const color = @import("color_signal.zig");
pub const refresh = @import("refresh_range.zig");
pub const vrr = @import("vrr.zig");
pub const eld = @import("eld.zig");
pub const links = @import("links.zig");
const cta = @import("cta_timings.zig");
pub const max_blocks = 32;
pub const max_modes = 128;
pub const max_audio = 32;
pub const Error = error{ InvalidBase, InvalidLength, TooLarge, Capacity };
pub const Warning = struct {
    pub const missing: u32 = 1;
    pub const checksum: u32 = 2;
    pub const malformed: u32 = 4;
    pub const unknown: u32 = 8;
    pub const extra: u32 = 16;
    pub const timing_incomplete: u32 = 32;
};
pub const Audio = struct { format: u8 = 0, channels: u8 = 0, rates: u8 = 0, detail: u8 = 0 };
pub const Report = struct {
    manufacturer: [3]u8 = .{0} ** 3,
    product: u16 = 0,
    serial: u32 = 0,
    name: [13]u8 = .{0} ** 13,
    digital: bool = false,
    bits_per_color: u8 = 0,
    // EDID coordinates are exact10-bit fractions of1024, ordered Rxy,
    // Gxy, Bxy, Wxy. Zero/degenerate values remain unspecified facts.
    chromaticity: [8]u16 = @splat(0),
    gamma_hundredths: u16 = 0,
    srgb_default: bool = false,
    refresh: refresh.Facts = .{},
    // RGB, YCbCr444, YCbCr422, YCbCr420. Sink facts, not source capabilities.
    colors: u8 = 1,
    declared_extensions: u8 = 0,
    valid_extensions: u8 = 0,
    warnings: u32 = 0,
    basic_audio: bool = false,
    cta_revision: u8 = 0,
    audio_infoframes: bool = false,
    audio_latency: u8 = 0,
    hdmi: bool = false,
    hdmi_links: ?links.Hdmi = null,
    max_tmds_hz: u64 = 0,
    scdc: bool = false,
    scrambling_low_rates: bool = false,
    // HDMI DC30/DC36/DC48, independent of the base EDID input depth.
    hdmi_deep_color: u8 = 0,
    hdmi_deep_color_y444: bool = false,
    hdmi_deep_color_420: u8 = 0,
    video_capability: ?u8 = null,
    rgb_quantization_selectable: bool = false,
    ycc_quantization_selectable: bool = false,
    colorimetry: u16 = 0,
    hdr_eotf: u8 = 0,
    hdr_static: u8 = 0,
    hdr_present: bool = false,
    // Optional max, frame-average and min luminance codes; zero means
    // unspecified. Keep signal codes intact rather than inventing defaults.
    hdr_luminance: [3]u8 = @splat(0),
    hdr_luminance_count: u8 = 0,
    speakers: u32 = 0,
    modes: [max_modes]timing.Timing = .{timing.Timing{}} ** max_modes,
    mode_count: usize = 0,
    audio: [max_audio]Audio = .{Audio{}} ** max_audio,
    audio_count: usize = 0,

    pub fn complete(self: *const Report) bool {
        return self.warnings & (Warning.missing | Warning.checksum | Warning.malformed | Warning.extra) == 0;
    }
    fn add(self: *Report, mode: timing.Timing) Error!void {
        if (!mode.valid() and mode.flags & timing.incomplete == 0) return;
        for (self.modes[0..self.mode_count]) |*existing| if (existing.sameMode(mode)) {
            const only420 = existing.flags & mode.flags & timing.y420_only;
            existing.flags = ((existing.flags | mode.flags) & ~timing.y420_only) | only420;
            // A base DTD may precede its identical CTA timing. Retain the
            // first explicit VIC so wire range/signaling does not treat that
            // CTA mode as an unclassified full-range PC timing.
            if (existing.vic == 0) existing.vic = mode.vic;
            return;
        };
        if (self.mode_count == self.modes.len) return error.Capacity;
        self.modes[self.mode_count] = mode;
        self.mode_count += 1;
    }
};
fn le16(bytes: []const u8) u32 {
    return @as(u32, bytes[0]) | (@as(u32, bytes[1]) << 8);
}
fn le24(bytes: []const u8) u32 {
    return le16(bytes) | (@as(u32, bytes[2]) << 16);
}
fn checksum(bytes: []const u8) bool {
    var sum: u8 = 0;
    for (bytes) |byte| sum +%= byte;
    return sum == 0;
}
fn zero(bytes: []const u8) bool {
    for (bytes) |byte| if (byte != 0) return false;
    return true;
}
fn detailed(bytes: []const u8) ?timing.Timing {
    if (bytes.len < 18 or le16(bytes) == 0) return null;
    const width = @as(u32, bytes[2]) | (@as(u32, bytes[4] & 0xf0) << 4);
    const height = @as(u32, bytes[5]) | (@as(u32, bytes[7] & 0xf0) << 4);
    const hb = @as(u32, bytes[3]) | (@as(u32, bytes[4] & 15) << 8);
    const vb = @as(u32, bytes[6]) | (@as(u32, bytes[7] & 15) << 8);
    const hf = @as(u32, bytes[8]) | (@as(u32, bytes[11] & 0xc0) << 2);
    const hs = @as(u32, bytes[9]) | (@as(u32, bytes[11] & 0x30) << 4);
    const vf = @as(u32, bytes[10] >> 4) | (@as(u32, bytes[11] & 12) << 2);
    const vs = @as(u32, bytes[10] & 15) | (@as(u32, bytes[11] & 3) << 4);
    const interlace = bytes[17] & 0x80 != 0;
    const scale: u32 = if (interlace) 2 else 1;
    var mode = timing.Timing{
        .width = width,
        .height = height * scale,
        .h_total = width + hb,
        .h_start = width + hf,
        .h_end = width + hf + hs,
        .v_total = (height + vb) * scale + @intFromBool(interlace),
        .v_start = (height + vf) * scale,
        .v_end = (height + vf + vs) * scale,
        .clock_hz = @as(u64, le16(bytes)) * 10000,
        .flags = if (interlace) timing.interlaced else 0,
    };
    // Composite/stereo/bordered modes remain recognizable but cannot be used
    // as a separate-sync scanout timing without a richer negotiated contract.
    if (bytes[17] & 0x18 != 0x18 or bytes[17] & 0x61 != 0 or bytes[15] != 0 or bytes[16] != 0) {
        mode.flags |= timing.incomplete;
    } else {
        if (bytes[17] & 2 != 0) mode.flags |= timing.h_positive;
        if (bytes[17] & 4 != 0) mode.flags |= timing.v_positive;
    }
    return if (mode.valid()) mode else null;
}

// On a fatal base/length/capacity error the caller output is untouched.
// Each extension is transactional: one malformed block contributes no modes,
// audio or colors, while earlier validated blocks remain available.
pub fn parse(bytes: []const u8, output: *Report) Error!void {
    if (bytes.len < 128 or bytes.len % 128 != 0) return error.InvalidLength;
    if (bytes.len > max_blocks * 128) return error.TooLarge;
    if (!std.mem.eql(u8, bytes[0..8], &.{ 0, 255, 255, 255, 255, 255, 255, 0 }) or
        !checksum(bytes[0..128]) or bytes[18] != 1 or bytes[19] > 4) return error.InvalidBase;
    var result = Report{ .product = @intCast(le16(bytes[10..])), .serial = le24(bytes[12..]) | (@as(u32, bytes[15]) << 24), .digital = bytes[20] & 0x80 != 0, .declared_extensions = bytes[126] };
    const vendor = (@as(u16, bytes[8]) << 8) | bytes[9];
    for (0..3) |i| {
        const letter = (vendor >> @as(u4, @intCast((2 - i) * 5))) & 31;
        if (letter == 0 or letter > 26 or vendor & 0x8000 != 0) return error.InvalidBase;
        result.manufacturer[i] = @as(u8, @intCast(letter)) + 'A' - 1;
    }
    if (result.digital and bytes[19] >= 4) {
        const depth = (bytes[20] >> 4) & 7;
        if (depth == 7) return error.InvalidBase;
        result.bits_per_color = if (depth == 0) 0 else 4 + depth * 2;
        if (bytes[24] & 8 != 0) result.colors |= 2;
        if (bytes[24] & 16 != 0) result.colors |= 4;
    }
    result.gamma_hundredths = if (bytes[23] == 255) 0 else @as(u16, bytes[23]) + 100;
    result.srgb_default = bytes[24] & 4 != 0;
    result.refresh.continuous_frequency = bytes[19] >= 4 and bytes[24] & 1 != 0;
    for (0..8) |i| {
        const low = (bytes[25 + i / 4] >> @as(u3, @intCast(6 - 2 * (i % 4)))) & 3;
        result.chromaticity[i] = (@as(u16, bytes[27 + i]) << 2) | low;
    }
    for (0..4) |i| {
        const descriptor = bytes[54 + i * 18 ..][0..18];
        if (le16(descriptor) != 0) {
            var mode = detailed(descriptor) orelse return error.InvalidBase;
            if (i == 0 and (bytes[19] >= 4 or bytes[24] & 2 != 0)) mode.flags |= timing.preferred;
            try result.add(mode);
        } else if (descriptor[2] != 0 or (descriptor[3] != 0xfd and descriptor[4] != 0)) {
            return error.InvalidBase;
        } else if (descriptor[3] == 0xfc) {
            for (descriptor[5..18], 0..) |ch, n| {
                if (ch == 10) break;
                if (ch < 32 or ch > 126) return error.InvalidBase;
                result.name[n] = ch;
            }
        } else if (descriptor[3] == 0xfd) {
            // EDID 1.4 rate offsets are metadata, not descriptor padding.
            // Preserve exact limits; never synthesize a CVT/GTF timing here.
            const offsets = descriptor[4];
            if ((bytes[19] < 4 and offsets != 0) or offsets & 0xf0 != 0 or
                offsets & 3 == 1 or (offsets >> 2) & 3 == 1) return error.InvalidBase;
            const limits: refresh.EdidLimits = .{
                .refresh = .{
                    .min_millihz = (@as(u32, descriptor[5]) + (if (offsets & 1 != 0) @as(u32, 255) else 0)) * 1000,
                    .max_millihz = (@as(u32, descriptor[6]) + (if (offsets & 2 != 0) @as(u32, 255) else 0)) * 1000,
                },
                .min_horizontal_hz = (@as(u32, descriptor[7]) + (if (offsets & 4 != 0) @as(u32, 255) else 0)) * 1000,
                .max_horizontal_hz = (@as(u32, descriptor[8]) + (if (offsets & 8 != 0) @as(u32, 255) else 0)) * 1000,
                .max_pixel_clock_hz = @as(u64, descriptor[9]) * 10_000_000,
            };
            if (!limits.refresh.valid() or limits.min_horizontal_hz == 0 or limits.max_horizontal_hz < limits.min_horizontal_hz) return error.InvalidBase;
            if (result.refresh.edid) |prior| if (!std.meta.eql(prior, limits)) return error.InvalidBase;
            result.refresh.edid = limits;
            if (descriptor[10] != 1) result.warnings |= Warning.unknown; // Timing formula unimplemented.
        } else if (descriptor[3] != 0x10 and descriptor[3] != 0xff and descriptor[3] != 0xfe) {
            result.warnings |= Warning.unknown;
        }
    }
    // Established timings carry only a standardized mode identity here.
    // Without a negotiated DMT lookup they cannot supply hardware sync/PLL
    // registers. Keep them visible as nominal facts, like standard pairs.
    const established = [_][3]u32{
        .{ 720, 400, 70 },  .{ 720, 400, 88 },  .{ 640, 480, 60 },  .{ 640, 480, 67 },
        .{ 640, 480, 72 },  .{ 640, 480, 75 },  .{ 800, 600, 56 },  .{ 800, 600, 60 },
        .{ 800, 600, 72 },  .{ 800, 600, 75 },  .{ 832, 624, 75 },  .{ 1024, 768, 87 },
        .{ 1024, 768, 60 }, .{ 1024, 768, 70 }, .{ 1024, 768, 75 }, .{ 1280, 1024, 75 },
        .{ 1152, 870, 75 },
    };
    for (established, 0..) |value, i| {
        if (bytes[35 + i / 8] & (@as(u8, 0x80) >> @as(u3, @intCast(i % 8))) == 0) continue;
        try result.add(.{ .width = value[0], .height = value[1], .nominal_millihz = value[2] * 1000, .flags = timing.incomplete | (if (i == 11) timing.interlaced else @as(u32, 0)) });
        result.warnings |= Warning.timing_incomplete;
    }
    if (bytes[37] & 0x7f != 0) result.warnings |= Warning.unknown;
    // Standard timing pairs describe dimensions/rate, not complete PLL/sync
    // programming. Preserve these facts without synthesizing unknown timing.
    for (0..8) |i| {
        const first = bytes[38 + i * 2];
        const second = bytes[39 + i * 2];
        if (first == 1 and second == 1) continue;
        if (first <= 1) {
            result.warnings |= Warning.malformed;
            continue;
        }
        const width = (@as(u32, first) + 31) * 8;
        const height = switch (second >> 6) {
            0 => if (bytes[19] < 3) width else width * 10 / 16,
            1 => width * 3 / 4,
            2 => width * 4 / 5,
            3 => width * 9 / 16,
            else => unreachable,
        };
        try result.add(.{ .width = width, .height = height, .nominal_millihz = (@as(u32, second & 63) + 60) * 1000, .flags = timing.incomplete });
        result.warnings |= Warning.timing_incomplete;
    }
    const present = bytes.len / 128 - 1;
    if (present < result.declared_extensions) result.warnings |= Warning.missing;
    if (present > result.declared_extensions) result.warnings |= Warning.extra;
    for (0..@min(present, result.declared_extensions)) |i| {
        const block = bytes[(i + 1) * 128 ..][0..128];
        if (!checksum(block)) {
            result.warnings |= Warning.checksum;
            continue;
        }
        var candidate = result;
        const valid = switch (block[0]) {
            0x02 => try parseCta(block, &candidate),
            0x70 => try parseDisplayId(block, &candidate),
            else => blk: {
                candidate.warnings |= Warning.unknown;
                break :blk true;
            },
        };
        if (!valid) {
            result.warnings |= Warning.malformed;
            continue;
        }
        if (block[0] == 0x70 and @as(usize, block[4]) > @min(present, result.declared_extensions) - i - 1)
            candidate.warnings |= Warning.missing;
        candidate.valid_extensions += 1;
        result = candidate;
    }
    output.* = result;
}

fn addVic(raw: u8, flags: u32, result: *Report) Error!bool {
    if (raw == 0 or raw == 128 or raw >= 254) return false;
    const native = raw >= 129 and raw <= 192;
    const vic = if (native) raw & 127 else raw;
    for (&cta.modes) |entry| if (entry.vic == vic) {
        var mode = entry;
        mode.flags |= flags | (if (native) timing.preferred else @as(u32, 0));
        try result.add(mode);
        return true;
    };
    result.warnings |= Warning.unknown;
    return true;
}
fn parseCta(block: []const u8, result: *Report) Error!bool {
    if (block[1] == 0 or block[1] > 3) return false;
    const end: usize = block[2];
    if (end != 0 and (end < 4 or end > 127)) return false;
    result.cta_revision = @max(result.cta_revision, block[1]);
    if (block[3] & 0x40 != 0) result.basic_audio = true;
    if (block[3] & 0x20 != 0) result.colors |= 2;
    if (block[3] & 0x10 != 0) result.colors |= 4;
    if (end == 0) return zero(block[4..127]);
    var video: [123]u8 = .{0} ** 123;
    var video_count: usize = 0;
    var pos: usize = 4;
    while (pos < end) {
        const tag = block[pos] >> 5;
        const len: usize = block[pos] & 31;
        pos += 1;
        if (len > end - pos) return false;
        const data = block[pos..][0..len];
        pos += len;
        switch (tag) {
            0 => {
                if (!zero(data) or !zero(block[pos..end])) return false;
                break;
            },
            1 => {
                if (len == 0 or len % 3 != 0) return false;
                var a: usize = 0;
                while (a < len) : (a += 3) {
                    const format = (data[a] >> 3) & 15;
                    if (format == 0 or data[a] & 128 != 0 or data[a + 1] == 0 or data[a + 1] & 128 != 0 or
                        (format == 1 and (data[a + 2] & 7 == 0 or data[a + 2] & 0xf8 != 0))) return false;
                    if (result.audio_count == max_audio) return error.Capacity;
                    result.audio[result.audio_count] = .{ .format = format, .channels = (data[a] & 7) + 1, .rates = data[a + 1], .detail = data[a + 2] };
                    result.audio_count += 1;
                }
            },
            2 => for (data) |raw| {
                if (!try addVic(raw, 0, result)) return false;
                if (video_count == video.len) return false;
                video[video_count] = if (raw >= 129 and raw <= 192) raw & 127 else raw;
                video_count += 1;
            },
            3 => {
                if (len < 3) return false;
                const oui = le24(data);
                if (oui == 0x000c03) {
                    if (len < 5) return false;
                    result.hdmi = true;
                    if (len >= 6) {
                        result.audio_infoframes = result.audio_infoframes or data[5] & 0x80 != 0;
                        result.hdmi_deep_color |= (data[5] >> 4) & 7;
                        result.hdmi_deep_color_y444 = result.hdmi_deep_color_y444 or data[5] & 8 != 0;
                    }
                    if (len >= 7) result.max_tmds_hz = @max(result.max_tmds_hz, @as(u64, data[6]) * 5_000_000);
                    if (len >= 8) {
                        const latency = data[7] & 0x80 != 0;
                        const interlaced_latency = data[7] & 0x40 != 0;
                        if ((interlaced_latency and !latency) or (latency and len < 10) or (interlaced_latency and len < 12)) return false;
                        if (latency) result.audio_latency = @max(result.audio_latency, data[9]);
                    }
                } else if (oui == 0xc45dd8) {
                    if (!hdmiForum(data, result)) return false;
                } else result.warnings |= Warning.unknown;
            },
            4 => {
                if (len != 3) return false;
                result.speakers |= le24(data);
            },
            7 => {
                if (len == 0) return false;
                switch (data[0]) {
                    0 => {
                        if (len != 2) return false;
                        if (result.video_capability) |previous| if (previous != data[1]) return false;
                        result.video_capability = data[1];
                        result.rgb_quantization_selectable = data[1] & 64 != 0;
                        result.ycc_quantization_selectable = data[1] & 128 != 0;
                    },
                    5 => {
                        if (len != 3) return false;
                        result.colorimetry |= @intCast(le16(data[1..]));
                    },
                    6 => {
                        if (len < 3 or len > 6) return false;
                        var luminance: [3]u8 = @splat(0);
                        @memcpy(luminance[0 .. len - 3], data[3..]);
                        if ((luminance[2] != 0 and luminance[0] == 0) or
                            (luminance[0] != 0 and luminance[1] > luminance[0])) return false;
                        if (result.hdr_present and (result.hdr_eotf != data[1] & 15 or result.hdr_static != data[2] & 1 or
                            result.hdr_luminance_count != len - 3 or !std.mem.eql(u8, &result.hdr_luminance, &luminance))) return false;
                        if (data[1] & 0xf0 != 0 or data[2] & 0xfe != 0) result.warnings |= Warning.unknown;
                        result.hdr_present = true;
                        result.hdr_eotf = data[1] & 15;
                        result.hdr_static = data[2] & 1;
                        result.hdr_luminance = luminance;
                        result.hdr_luminance_count = @intCast(len - 3);
                    },
                    0x0e => {
                        if (len < 2) return false;
                        for (data[1..]) |raw| if (!try addVic(raw, timing.y420_only | timing.y420_allowed, result)) return false;
                        result.colors |= 8;
                    },
                    0x0f => {}, // Applied in a second bounded pass, after all SVDs.
                    0x79 => {
                        if (len < 3 or data[1] != 0 or data[2] != 0 or !hdmiForum(data, result)) return false;
                    },
                    else => result.warnings |= Warning.unknown,
                }
            },
            else => result.warnings |= Warning.unknown,
        }
    }
    pos = 4;
    while (pos < end) {
        const head = block[pos];
        const len: usize = head & 31;
        pos += 1;
        const data = block[pos..][0..len];
        pos += len;
        if (head == 0) break;
        if (head >> 5 != 7 or data.len == 0 or data[0] != 0x0f) continue;
        result.colors |= 8;
        for (0..@max(video_count, (len - 1) * 8)) |i| {
            const enabled = len == 1 or (i / 8 < len - 1 and data[1 + i / 8] & (@as(u8, 1) << @as(u3, @intCast(i % 8))) != 0);
            if (!enabled) continue;
            if (i >= video_count) return false;
            for (result.modes[0..result.mode_count]) |*mode| if (mode.vic == video[i]) {
                mode.flags |= timing.y420_allowed;
            };
        }
    }
    pos = end;
    var detailed_count: usize = 0;
    while (pos + 18 <= 127) : (pos += 18) {
        if (zero(block[pos..127])) break;
        if (le16(block[pos..]) == 0) {
            // EDID dummy descriptors are legal here (including QEMU's EDID).
            if (block[pos + 2] != 0 or block[pos + 3] != 0x10 or !zero(block[pos + 4 .. pos + 18])) return false;
            continue;
        }
        var mode = detailed(block[pos..][0..18]) orelse return false;
        if (detailed_count < block[3] & 15) mode.flags |= timing.preferred;
        try result.add(mode);
        detailed_count += 1;
    }
    return zero(block[pos..127]);
}

fn hdmiForum(data: []const u8, result: *Report) bool {
    if (data.len < 7 or data[3] != 1 or data.len == 9) return false;
    const link_info = links.Hdmi.parse(data) catch return false;
    if (result.hdmi_links) |prior| if (!std.meta.eql(prior, link_info)) return false;
    result.hdmi_links = link_info;
    var info: refresh.Hdmi = .{};
    if (data.len >= 8) info.flags = data[7];
    if (data.len >= 10) {
        info.refresh = .{ .min_millihz = @as(u32, data[8] & 63) * 1000, .max_millihz = ((@as(u32, data[8] >> 6) << 8) | data[9]) * 1000 };
        if ((info.refresh.min_millihz != 0 or info.refresh.max_millihz != 0) and !info.refresh.valid()) return false;
    }
    if (result.refresh.hdmi) |prior| if (!std.meta.eql(prior, info)) return false;
    result.refresh.hdmi = info;
    result.hdmi = true;
    result.max_tmds_hz = @max(result.max_tmds_hz, @as(u64, data[4]) * 5_000_000);
    result.scdc = result.scdc or data[5] & 0x80 != 0;
    result.scrambling_low_rates = result.scrambling_low_rates or data[5] & 8 != 0;
    result.hdmi_deep_color_420 |= data[6] & 7;
    return true;
}

fn parseDisplayId(block: []const u8, result: *Report) Error!bool {
    const version = block[1] >> 4;
    if ((version != 1 and version != 2) or block[3] > (if (version == 1) @as(u8, 6) else 8)) return false;
    const end = @as(usize, block[2]) + 5;
    if (end > 126 or !checksum(block[1 .. end + 1]) or !zero(block[end + 1 .. 127])) return false;
    var pos: usize = 5;
    while (pos < end) {
        if (zero(block[pos..end])) break;
        if (end - pos < 3) return false;
        const tag = block[pos];
        const revision = block[pos + 1];
        const len: usize = block[pos + 2];
        pos += 3;
        if (len > end - pos) return false;
        if ((version == 1 and tag == 3) or (version == 2 and tag == 0x22)) {
            if (revision & 7 > (if (version == 1) @as(u8, 1) else 2) or len == 0 or len % 20 != 0) return false;
            var offset: usize = 0;
            while (offset < len) : (offset += 20) {
                const data = block[pos + offset ..][0..20];
                const width = le16(data[4..]) + 1;
                const height = le16(data[12..]) + 1;
                const hs = width + le16(data[8..]) % 32768 + 1;
                const vs = height + le16(data[16..]) % 32768 + 1;
                var mode = timing.Timing{ .width = width, .height = height, .clock_hz = (@as(u64, le24(data)) + 1) * (if (version == 1) @as(u64, 10000) else 1000), .h_total = width + le16(data[6..]) + 1, .v_total = height + le16(data[14..]) + 1, .h_start = hs, .h_end = hs + le16(data[10..]) + 1, .v_start = vs, .v_end = vs + le16(data[18..]) + 1 };
                if (data[3] & 128 != 0) mode.flags |= timing.preferred;
                if (data[3] & 16 != 0) mode.flags |= timing.interlaced | timing.incomplete;
                if (data[3] & 0x60 != 0) mode.flags |= timing.incomplete;
                if (data[9] & 128 != 0) mode.flags |= timing.h_positive;
                if (data[17] & 128 != 0) mode.flags |= timing.v_positive;
                if (!mode.valid()) return false;
                try result.add(mode);
            }
        } else if (version == 2 and tag == 0x25) {
            if (revision > 1 or len != 9) return false;
            const data = block[pos..][0..len];
            if (data[8] & (if (revision == 0) @as(u8, 0x7f) else 0x7c) != 0) return false;
            const limits: refresh.DynamicLimits = .{
                .refresh = .{ .min_millihz = @as(u32, data[6]) * 1000, .max_millihz = (@as(u32, data[7]) | (@as(u32, data[8] & 3) << 8)) * 1000 },
                .min_pixel_clock_hz = (@as(u64, le24(data)) + 1) * 1000,
                .max_pixel_clock_hz = (@as(u64, le24(data[3..])) + 1) * 1000,
                .seamless = data[8] & 128 != 0,
            };
            if (!limits.refresh.valid() or limits.min_pixel_clock_hz > limits.max_pixel_clock_hz) return false;
            if (result.refresh.dynamic) |prior| if (!std.meta.eql(prior, limits)) return false;
            result.refresh.dynamic = limits;
        } else if (version == 2 and tag == 0x2b) {
            if (revision != 0 or len == 0 or len % 6 != 0) return false;
            var offset: usize = 0;
            while (offset < len) : (offset += 6) {
                const data = block[pos + offset ..][0..6];
                if (data[0] & 0xc0 != 0 or (data[0] >> 2) & 3 > 1 or data[4] & 0xfc != 0) return false;
                const value: refresh.Adaptive = .{
                    .refresh = .{ .min_millihz = @as(u32, data[2]) * 1000, .max_millihz = ((@as(u32, data[3]) | (@as(u32, data[4] & 3) << 8)) + 1) * 1000 },
                    .native = data[0] & 1 != 0,
                    .adaptive_vtotal = data[0] & 4 != 0,
                    .seamless = data[0] & 16 == 0,
                    .increase_without_jitter = data[0] & 2 != 0,
                    .decrease_without_jitter = data[0] & 32 != 0,
                    .max_increase_us = @as(u32, data[1]) * 250,
                    .max_decrease_us = @as(u32, data[5]) * 250,
                };
                if (!value.refresh.valid() or !result.refresh.addAdaptive(value)) return false;
            }
        } else result.warnings |= Warning.unknown;
        pos += len;
    }
    return true;
}
