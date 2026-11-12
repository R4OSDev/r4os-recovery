//! Original PNG color metadata reader. W3C PNG Third Edition24June2025,
//! sections4.3,5.6,11.3.2: exact original archived under GFX/0.79.25.
//! Pixel decoding and display policy are separate. No ignored/unknown tag
//! is silently relabelled as sRGB, and no native HDR capability is inferred.
const std = @import("std");
pub const Error = error{ InvalidImage, UnsupportedFeature, TooLarge, PixelBufferTooSmall };
pub const max_encoded_bytes = 128 * 1024 * 1024;
pub const max_profile_bytes = 4 * 1024 * 1024;
pub const Kind = enum(u32) { unspecified = 0, cicp = 1, icc = 2, srgb = 3, gamma_chroma = 4, unknown = 5 };
pub const Mastering = struct { chromaticities: [8]u16, maximum: u32, minimum: u32 };
pub const Info = struct {
    bit_depth: u8 = 0,
    color_type: u8 = 0,
    cicp: ?[4]u8 = null,
    gamma: ?u32 = null,
    chromaticities: ?[8]u32 = null, // White xy, Rxy, Gxy, Bxy; units1/100000.
    intent: ?u8 = null,
    compressed_profile: []const u8 = &.{}, // Retained input, never a hidden allocation.
    mastering: ?Mastering = null, // RGBxy, white xy /50000; luminance /10000.
    content_light: ?[2]u32 = null, // Maximum pixel and average luminance /10000.

    pub fn recognizedCicp(self: Info) bool {
        const value = self.cicp orelse return false;
        return (value[0] == 1 or value[0] == 9 or value[0] == 12) and
            (value[1] == 8 or value[1] == 13 or value[1] == 16 or value[1] == 18) and
            value[2] == 0 and value[3] <= 1 and (value[1] != 18 or value[0] == 9);
    }
    pub fn kind(self: Info) Kind {
        if (self.recognizedCicp()) return .cicp;
        if (self.compressed_profile.len != 0) return .icc;
        if (self.intent != null) return .srgb;
        if (self.gamma != null or self.chromaticities != null) return .gamma_chroma;
        return if (self.cicp != null) .unknown else .unspecified;
    }
    pub fn profile(self: Info, output: []u8) Error![]u8 {
        if (self.compressed_profile.len == 0) return error.UnsupportedFeature;
        if (output.len < 132) return error.PixelBufferTooSmall;
        if (overlaps(self.compressed_profile, output)) return error.InvalidImage;
        // The standard decoder records the zlib footer but does not validate
        // its Adler value. Check it explicitly, along with complete input and
        // the embedded ICC size/color model, before publishing a profile.
        var input: std.Io.Reader = .fixed(self.compressed_profile);
        var history: [std.compress.flate.max_window_len]u8 = undefined;
        var inflate = std.compress.flate.Decompress.init(&input, .zlib, &history);
        var writer: std.Io.Writer = .fixed(output[0..@min(output.len, max_profile_bytes)]);
        const count = inflate.reader.streamRemaining(&writer) catch |err| return if (err == error.WriteFailed) error.PixelBufferTooSmall else error.InvalidImage;
        const bytes = writer.buffered();
        if (count != bytes.len or bytes.len < 132 or input.bufferedLen() != 0 or
            inflate.container_metadata.zlib.adler != std.hash.Adler32.hash(bytes) or
            be32(bytes, 0) != bytes.len or !std.mem.eql(u8, bytes[36..40], "acsp")) return error.InvalidImage;
        const model = if (self.color_type == 0 or self.color_type == 4) "GRAY" else "RGB ";
        if (!std.mem.eql(u8, bytes[16..20], model)) return error.InvalidImage;
        return bytes;
    }
};
fn overlaps(input: []const u8, output: []u8) bool {
    const start = @intFromPtr(input.ptr);
    const target = @intFromPtr(output.ptr);
    const end = std.math.add(usize, start, input.len) catch return true;
    const limit = std.math.add(usize, target, output.len) catch return true;
    return input.len != 0 and output.len != 0 and start < limit and target < end;
}
fn be32(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .big);
}
fn be16(bytes: []const u8, offset: usize) u16 {
    return std.mem.readInt(u16, bytes[offset..][0..2], .big);
}
fn same(name: []const u8, comptime value: []const u8) bool {
    return std.mem.eql(u8, name, value);
}
fn xy(x: u32, y: u32, scale: u32) bool {
    return x <= scale and y > 0 and y <= scale and @as(u64, x) + y <= scale;
}
fn unique(seen: *u32, bit: u5, before_pixels: bool) Error!void {
    const flag: u32 = @as(u32, 1) << bit;
    if (!before_pixels or seen.* & flag != 0) return error.InvalidImage;
    seen.* |= flag;
}
fn keyword(bytes: []const u8) bool {
    if (bytes.len == 0 or bytes.len > 79 or bytes[0] == ' ' or bytes[bytes.len - 1] == ' ') return false;
    var space = false;
    for (bytes) |value| {
        if ((value < 32 or value > 126) and value < 161) return false;
        if (value == ' ' and space) return false;
        space = value == ' ';
    }
    return true;
}
pub fn png(bytes: []const u8) Error!Info {
    if (bytes.len > max_encoded_bytes) return error.TooLarge;
    if (bytes.len < 45 or !std.mem.eql(u8, bytes[0..8], "\x89PNG\r\n\x1a\n")) return error.InvalidImage;
    var result: Info = .{};
    var cursor: usize = 8;
    var count: usize = 0;
    var seen: u32 = 0;
    var palette = false;
    var palette_entries: u32 = 0;
    var transparency = false;
    var idat = false;
    var idat_closed = false;
    var end = false;
    while (cursor < bytes.len) {
        if (bytes.len - cursor < 12 or end) return error.InvalidImage;
        const length = be32(bytes, cursor);
        if (length > 0x7fffffff or length > bytes.len - cursor - 12) return error.InvalidImage;
        const name = bytes[cursor + 4 ..][0..4];
        for (name) |letter| if (!std.ascii.isAlphabetic(letter)) return error.InvalidImage;
        if (name[2] & 32 != 0) return error.InvalidImage;
        const data = bytes[cursor + 8 ..][0..length];
        if (std.hash.crc.Crc32.hash(bytes[cursor + 4 ..][0 .. length + 4]) != be32(bytes, cursor + 8 + length)) return error.InvalidImage;
        if (count == 0 and !same(name, "IHDR")) return error.InvalidImage;
        const before_pixels = !palette and !idat;
        if (same(name, "IHDR")) {
            if (count != 0 or length != 13 or be32(data, 0) == 0 or be32(data, 4) == 0 or
                be32(data, 0) > 4096 or be32(data, 4) > 4096 or data[10] != 0 or data[11] != 0 or data[12] > 1) return error.InvalidImage;
            result.bit_depth = data[8];
            result.color_type = data[9];
            const valid = switch (data[9]) {
                0 => data[8] == 1 or data[8] == 2 or data[8] == 4 or data[8] == 8 or data[8] == 16,
                2, 4, 6 => data[8] == 8 or data[8] == 16,
                3 => data[8] == 1 or data[8] == 2 or data[8] == 4 or data[8] == 8,
                else => false,
            };
            if (!valid) return error.InvalidImage;
        } else if (same(name, "PLTE")) {
            if (palette or idat or transparency or length == 0 or length % 3 != 0 or length > 768 or result.color_type == 0 or result.color_type == 4) return error.InvalidImage;
            if (result.color_type == 3 and length / 3 > @as(u32, 1) << @intCast(result.bit_depth)) return error.InvalidImage;
            palette = true;
            palette_entries = length / 3;
        } else if (same(name, "IDAT")) {
            if (idat_closed or (result.color_type == 3 and !palette)) return error.InvalidImage;
            idat = true;
        } else if (same(name, "IEND")) {
            if (!idat or length != 0) return error.InvalidImage;
            end = true;
        } else if (same(name, "tRNS")) {
            if (transparency or idat or (result.color_type == 3 and (!palette or length == 0 or length > palette_entries)) or
                (result.color_type == 0 and length != 2) or (result.color_type == 2 and length != 6) or
                result.color_type == 4 or result.color_type == 6) return error.InvalidImage;
            transparency = true;
        } else if (same(name, "cICP")) {
            try unique(&seen, 0, before_pixels);
            if (length != 4 or data[2] != 0 or data[3] > 1) return error.InvalidImage;
            result.cicp = data[0..4].*;
        } else if (same(name, "iCCP")) {
            try unique(&seen, 1, before_pixels);
            const separator = std.mem.indexOfScalar(u8, data, 0) orelse return error.InvalidImage;
            if (!keyword(data[0..separator]) or length - separator < 8 or data[separator + 1] != 0) return error.InvalidImage;
            result.compressed_profile = data[separator + 2 ..];
        } else if (same(name, "sRGB")) {
            try unique(&seen, 2, before_pixels);
            if (length != 1 or data[0] > 3) return error.InvalidImage;
            result.intent = data[0];
        } else if (same(name, "gAMA")) {
            try unique(&seen, 3, before_pixels);
            if (length != 4 or be32(data, 0) == 0) return error.InvalidImage;
            result.gamma = be32(data, 0);
        } else if (same(name, "cHRM")) {
            try unique(&seen, 4, before_pixels);
            if (length != 32) return error.InvalidImage;
            var values: [8]u32 = undefined;
            for (&values, 0..) |*value, i| value.* = be32(data, i * 4);
            for (0..4) |i| if (!xy(values[i * 2], values[i * 2 + 1], 100000)) return error.InvalidImage;
            result.chromaticities = values;
        } else if (same(name, "mDCV")) {
            try unique(&seen, 5, before_pixels);
            if (length != 24) return error.InvalidImage;
            var value: Mastering = .{ .chromaticities = undefined, .maximum = be32(data, 16), .minimum = be32(data, 20) };
            for (&value.chromaticities, 0..) |*v, i| v.* = be16(data, i * 2);
            for (0..4) |i| if (!xy(value.chromaticities[i * 2], value.chromaticities[i * 2 + 1], 50000)) return error.InvalidImage;
            if (value.maximum == 0 or value.minimum >= value.maximum) return error.InvalidImage;
            result.mastering = value;
        } else if (same(name, "cLLI")) {
            try unique(&seen, 6, before_pixels);
            if (length != 8) return error.InvalidImage;
            const maximum = be32(data, 0);
            const average = be32(data, 4);
            if (maximum != 0 and average > maximum) return error.InvalidImage;
            result.content_light = .{ maximum, average };
        } else if (same(name, "sBIT")) {
            try unique(&seen, 7, before_pixels);
            const channels: u32 = switch (result.color_type) {
                0 => 1,
                2, 3 => 3,
                4 => 2,
                6 => 4,
                else => unreachable,
            };
            if (length != channels) return error.InvalidImage;
            for (data) |value| if (value == 0 or value > (if (result.color_type == 3) @as(u8, 8) else result.bit_depth)) return error.InvalidImage;
        } else if (name[0] & 32 == 0) return error.UnsupportedFeature;
        if (idat and !same(name, "IDAT")) idat_closed = true;
        cursor += length + 12;
        count += 1;
    }
    if (!end or (result.mastering != null and result.cicp == null)) return error.InvalidImage;
    return result;
}
