//! Bounded ELD v2 encoding from a complete, validated receiver report.
//! HDMI wire facts follow the pinned HDA ELD specification and NVIDIA's
//! ctrl0073dfp.h. No GPU, HDA pin, mode or playback policy is selected here.
const std = @import("std");
const edid = @import("edid.zig");
pub const max_bytes = 96;
pub const max_sads = 15;
pub const Error = error{ Incomplete, Unsupported, Invalid, Capacity };
pub const Transport = enum(u8) { hdmi = 0, display_port = 1 };
pub const Data = struct {
    bytes: [max_bytes]u8 = @splat(0),
    max_frequency: u8 = 0,
    stereo_48k_s16: bool = false,
    pub fn baselineBytes(self: *const Data) usize { return 4 + @as(usize, self.bytes[2]) * 4; }
};

/// The port identity is assigned by the display owner. It is opaque to the
/// encoder and is copied without deriving it from a head index or HDA NID.
pub fn encode(report: *const edid.Report, port_id: [8]u8) Error!Data {
    return encodeTransport(report, port_id, .hdmi);
}
pub fn encodeTransport(report: *const edid.Report, port_id: [8]u8, transport: Transport) Error!Data {
    if (!report.complete()) return error.Incomplete;
    if (!report.digital or (transport == .hdmi and !report.hdmi) or report.cta_revision == 0) return error.Unsupported;
    if (report.cta_revision > 3 or report.audio_count > report.audio.len) return error.Invalid;
    var result: Data = .{};
    var sads: [max_sads]edid.Audio = @splat(.{});
    var count: usize = 0;
    var basic_covered = false;
    for (report.audio[0..report.audio_count]) |sad| {
        if (sad.format == 0 or sad.format > 15 or sad.channels == 0 or sad.channels > 8 or
            sad.rates == 0 or sad.rates & 0x80 != 0 or
            (sad.format == 1 and (sad.detail & 7 == 0 or sad.detail & 0xf8 != 0))) return error.Invalid;
        if (sad.format == 1 and sad.channels >= 2 and sad.rates & 7 == 7 and sad.detail & 1 != 0) basic_covered = true;
        var duplicate = false;
        for (sads[0..count]) |stored| if (std.meta.eql(stored, sad)) { duplicate = true; break; };
        if (duplicate) continue;
        if (count == sads.len) return error.Capacity;
        sads[count] = sad;
        count += 1;
    }
    // CTA Basic Audio is itself an explicit receiver guarantee. ELD has no
    // corresponding flag, so represent its mandatory PCM subset as one SAD.
    // Never combine fields from different SADs to invent a wider format.
    if (report.basic_audio and !basic_covered) {
        if (count == sads.len) return error.Capacity;
        sads[count] = .{ .format = 1, .channels = 2, .rates = 7, .detail = 1 };
        count += 1;
    }
    if (count == 0) return error.Unsupported;
    var name_len: usize = 0;
    while (name_len < report.name.len and report.name[name_len] != 0) : (name_len += 1) {
        if (report.name[name_len] < 32 or report.name[name_len] > 126) return error.Invalid;
    }
    while (name_len != 0 and report.name[name_len - 1] == ' ') name_len -= 1;
    var manufacturer: u16 = 0;
    for (report.manufacturer) |letter| {
        if (letter < 'A' or letter > 'Z') return error.Invalid;
        manufacturer = (manufacturer << 5) | @as(u16, letter - 'A' + 1);
    }
    result.bytes[0] = 2 << 3;
    result.bytes[2] = @intCast((16 + name_len + count * 3 + 3) / 4);
    result.bytes[4] = report.cta_revision << 5 | @as(u8, @intCast(name_len));
    result.bytes[5] = @as(u8, @intCast(count)) << 4 | @intFromEnum(transport) << 2 |
        @as(u8, @intFromBool(transport == .hdmi and report.audio_infoframes)) << 1;
    result.bytes[6] = if (transport == .hdmi) report.audio_latency else 0;
    result.bytes[7] = @truncate(report.speakers);
    @memcpy(result.bytes[8..16], &port_id);
    std.mem.writeInt(u16, result.bytes[16..18], manufacturer, .little);
    std.mem.writeInt(u16, result.bytes[18..20], report.product, .little);
    @memcpy(result.bytes[20..][0..name_len], report.name[0..name_len]);
    for (sads[0..count], 0..) |sad, index| {
        const offset = 20 + name_len + index * 3;
        result.bytes[offset] = sad.format << 3 | (sad.channels - 1);
        result.bytes[offset + 1] = sad.rates;
        result.bytes[offset + 2] = sad.detail;
        result.max_frequency = @max(result.max_frequency, @as(u8, 8) - @clz(sad.rates));
        if (sad.format == 1 and sad.channels >= 2 and sad.rates & 4 != 0 and sad.detail & 1 != 0) result.stereo_48k_s16 = true;
    }
    return result;
}
