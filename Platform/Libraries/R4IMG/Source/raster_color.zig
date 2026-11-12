//! JPEG ICC/Exif and BMP V4/V5 characterization, independently of pixel
//! decoding. ICC.1:2004 Annex B.5, CIPA DC-X008-2019, Microsoft BITMAPV5HEADER.
//! Original references are archived under ExFiles/Reference/GFX/0.79.25.
const std = @import("std");
const png = @import("color_metadata.zig");
pub const Error = png.Error || error{UnsupportedFormat};
pub const Kind = enum(u32) { unspecified, srgb, icc, calibrated, unknown, linked };
pub const Model = enum(u32) { rgb = 1, gray = 2, cmyk = 3 };
const Span = struct { offset: u32 = 0, length: u32 = 0 };
pub const Info = struct {
    format: enum { jpeg, bmp },
    kind: Kind = .unspecified,
    model: Model = .rgb,
    intent: u32 = 1,
    endpoints: [9]i32 = @splat(0), // RGB XYZ, signed2.30; no CMM arithmetic here.
    gamma: [3]u32 = @splat(0), // Unsigned16.16 decoding exponents.
    profile_bytes: u32 = 0,
    input: []const u8,
    spans: [255]Span = @splat(.{}),
    chunks: u8 = 0,

    fn copyPrefix(self: *const Info, output: []u8) void {
        var cursor: usize = 0;
        for (self.spans[0..self.chunks]) |span| {
            const n = @min(output.len - cursor, span.length);
            @memcpy(output[cursor..][0..n], self.input[span.offset..][0..n]);
            cursor += n;
            if (cursor == output.len) break;
        }
    }
    fn validateProfile(self: *Info, explicit_intent: bool) Error!void {
        if (self.profile_bytes < 132) return error.InvalidImage;
        for (self.spans[0..self.chunks]) |span| if (span.length == 0) return error.InvalidImage;
        var header: [132]u8 = undefined;
        self.copyPrefix(&header);
        if (read(u32, &header, 0, .big) != self.profile_bytes or !same(header[36..40], "acsp") or
            read(u32, &header, 64, .big) > 3 or read(u32, &header, 128, .big) > (self.profile_bytes - 132) / 12) return error.InvalidImage;
        const model = switch (self.model) {
            .rgb => "RGB ",
            .gray => "GRAY",
            .cmyk => "CMYK",
        };
        if (!same(header[16..20], model)) return error.InvalidImage;
        if (!explicit_intent) self.intent = read(u32, &header, 64, .big);
    }
    pub fn profile(self: *const Info, output: []u8) Error![]u8 {
        if (self.kind != .icc) return error.UnsupportedFeature;
        if (output.len < self.profile_bytes) return error.PixelBufferTooSmall;
        const destination = output[0..self.profile_bytes];
        if (@intFromPtr(self.input.ptr) < @intFromPtr(destination.ptr) +| destination.len and
            @intFromPtr(destination.ptr) < @intFromPtr(self.input.ptr) +| self.input.len) return error.InvalidImage;
        self.copyPrefix(destination);
        return destination;
    }
};
fn same(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
fn read(comptime T: type, bytes: []const u8, at: usize, endian: std.builtin.Endian) T {
    return std.mem.readInt(T, bytes[at..][0..@sizeOf(T)], endian);
}
fn directory(bytes: []const u8, offset: u32, endian: std.builtin.Endian) Error![]const u8 {
    if (offset < 8 or offset > bytes.len or bytes.len - offset < 6) return error.InvalidImage;
    const count = read(u16, bytes, offset, endian);
    if (count > 1024 or @as(usize, count) * 12 > bytes.len - offset - 6) return error.InvalidImage;
    return bytes[offset + 2 ..][0 .. @as(usize, count) * 12];
}
fn exif(bytes: []const u8) Error!?u16 {
    if (bytes.len < 8) return error.InvalidImage;
    const endian: std.builtin.Endian = if (same(bytes[0..2], "II")) .little else if (same(bytes[0..2], "MM")) .big else return error.InvalidImage;
    if (read(u16, bytes, 2, endian) != 42) return error.InvalidImage;
    const root = try directory(bytes, read(u32, bytes, 4, endian), endian);
    var exif_offset: ?u32 = null;
    var at: usize = 0;
    while (at < root.len) : (at += 12) {
        if (read(u16, root, at, endian) != 0x8769) continue;
        if (exif_offset != null or read(u16, root, at + 2, endian) != 4 or read(u32, root, at + 4, endian) != 1) return error.InvalidImage;
        exif_offset = read(u32, root, at + 8, endian);
    }
    const entries = try directory(bytes, exif_offset orelse return null, endian);
    var color: ?u16 = null;
    at = 0;
    while (at < entries.len) : (at += 12) {
        if (read(u16, entries, at, endian) != 0xa001) continue;
        if (color != null or read(u16, entries, at + 2, endian) != 3 or read(u32, entries, at + 4, endian) != 1) return error.InvalidImage;
        color = read(u16, entries, at + 8, endian);
    }
    return color;
}
fn jpeg(bytes: []const u8) Error!Info {
    var out: Info = .{ .format = .jpeg, .input = bytes };
    var cursor: usize = 2;
    var entropy = false;
    var frame = false;
    var scan = false;
    var ended = false;
    var has_exif = false;
    while (cursor < bytes.len) {
        if (entropy) {
            while (cursor < bytes.len and bytes[cursor] != 0xff) cursor += 1;
        }
        if (cursor >= bytes.len or bytes[cursor] != 0xff) return error.InvalidImage;
        while (cursor < bytes.len and bytes[cursor] == 0xff) cursor += 1;
        if (cursor == bytes.len) return error.InvalidImage;
        const marker = bytes[cursor];
        cursor += 1;
        if (entropy and (marker == 0 or (marker >= 0xd0 and marker <= 0xd7))) continue;
        entropy = false;
        if (marker == 0xd9) {
            ended = true;
            break;
        }
        if (marker == 1) continue;
        if (marker == 0 or (marker >= 0xd0 and marker <= 0xd8) or bytes.len - cursor < 2) return error.InvalidImage;
        const length = read(u16, bytes, cursor, .big);
        if (length < 2 or length > bytes.len - cursor) return error.InvalidImage;
        const data = bytes[cursor + 2 ..][0 .. length - 2];
        if (marker == 0xe2 and std.mem.startsWith(u8, data, "ICC_PROFILE\x00")) {
            if (data.len <= 14 or data[12] == 0 or data[13] == 0 or data[12] > data[13] or
                (out.chunks != 0 and out.chunks != data[13])) return error.InvalidImage;
            out.chunks = data[13];
            const chunk = &out.spans[data[12] - 1];
            if (chunk.length != 0) return error.InvalidImage;
            chunk.* = .{ .offset = @intCast(cursor + 16), .length = @intCast(data.len - 14) };
            if (chunk.length > png.max_profile_bytes - out.profile_bytes) return error.TooLarge;
            out.profile_bytes += chunk.length;
        } else if (marker == 0xe1 and std.mem.startsWith(u8, data, "Exif\x00\x00")) {
            if (has_exif) return error.InvalidImage;
            has_exif = true;
            if (try exif(data[6..])) |value| out.kind = if (value == 1) .srgb else .unknown;
        } else if (marker == 0xc0 or marker == 0xc1 or marker == 0xc2) {
            if (frame or data.len < 6 or data[0] != 8 or data.len != 6 + @as(usize, data[5]) * 3 or
                read(u16, data, 1, .big) == 0 or read(u16, data, 3, .big) == 0) return error.InvalidImage;
            out.model = switch (data[5]) {
                1 => .gray,
                3 => .rgb,
                4 => .cmyk,
                else => return error.UnsupportedFeature,
            };
            frame = true;
        } else if (marker == 0xda) {
            if (!frame or data.len < 4 or data[0] == 0 or data[0] > 4 or data.len != 4 + @as(usize, data[0]) * 2) return error.InvalidImage;
            entropy = true;
            scan = true;
        }
        cursor += length;
    }
    if (!frame or !scan or !ended) return error.InvalidImage;
    // Trailing bytes are outside this JPEG (e.g. a thumbnail or MPF image).
    // APP markers between scans still belong to this image and were checked.
    if (out.chunks != 0) {
        out.kind = .icc;
        try out.validateProfile(false);
    }
    return out;
}
fn bmp(bytes: []const u8) Error!Info {
    if (bytes.len < 54) return error.InvalidImage;
    const header = read(u32, bytes, 14, .little);
    if (header != 40 and header != 56 and header != 108 and header != 124) return error.UnsupportedFeature;
    if (header > bytes.len - 14) return error.InvalidImage;
    const width = read(i32, bytes, 18, .little);
    const height = read(i32, bytes, 22, .little);
    const bpp = read(u16, bytes, 28, .little);
    const compression = read(u32, bytes, 30, .little);
    if (width <= 0 or width > 4096 or height == 0 or height < -4096 or height > 4096 or
        read(u16, bytes, 26, .little) != 1 or (bpp != 24 and bpp != 32)) return error.InvalidImage;
    if (compression != 0 and compression != 3) return error.UnsupportedFeature;
    const offset = read(u32, bytes, 10, .little);
    const palette = read(u32, bytes, 46, .little);
    const minimum: u64 = 14 + @as(u64, header) + @as(u64, palette) * 4 + @as(u64, if (header == 40 and compression == 3) @as(u32, 12) else 0);
    const pitch: u64 = ((@as(u64, @intCast(width)) * bpp + 31) / 32) * 4;
    const pixel_end: u64 = offset + pitch * @abs(height);
    if (offset < minimum or pixel_end > bytes.len) return error.InvalidImage;
    const file_size = read(u32, bytes, 2, .little);
    if (file_size != 0 and (file_size < pixel_end or file_size > bytes.len)) return error.InvalidImage;
    var out: Info = .{ .format = .bmp, .input = bytes };
    if (header < 108) return out;
    const space = read(u32, bytes, 70, .little);
    var explicit_intent = false;
    if (header == 124) {
        const intent = read(u32, bytes, 122, .little);
        explicit_intent = intent != 0;
        out.intent = switch (intent) {
            0, 2 => 1,
            1 => 2,
            4 => 0,
            8 => 3,
            else => return error.InvalidImage,
        };
        if (read(u32, bytes, 134, .little) != 0) return error.InvalidImage;
    }
    switch (space) {
        0x73524742, 0x57696e20 => out.kind = .srgb, // LCS_sRGB, Windows color space.
        0 => {
            out.kind = .calibrated;
            for (&out.endpoints, 0..) |*v, i| v.* = read(i32, bytes, 74 + i * 4, .little);
            for (&out.gamma, 0..) |*v, i| v.* = read(u32, bytes, 110 + i * 4, .little);
        },
        0x4c494e4b, 0x4d424544 => {
            if (header != 124) return error.InvalidImage;
            const start: u64 = 14 + @as(u64, read(u32, bytes, 126, .little));
            const length = read(u32, bytes, 130, .little);
            // A file's profile follows its bitmap bits, unlike a packed DIB.
            if (length == 0 or start < pixel_end or start > bytes.len or length > bytes.len - start or
                (file_size != 0 and start + length > file_size)) return error.InvalidImage;
            if (space == 0x4c494e4b) {
                if (bytes[@intCast(start + length - 1)] != 0) return error.InvalidImage;
                out.kind = .linked; // Never open a file named by embedded metadata.
            } else {
                if (length > png.max_profile_bytes) return error.TooLarge;
                out.kind = .icc;
                out.chunks = 1;
                out.profile_bytes = length;
                out.spans[0] = .{ .offset = @intCast(start), .length = length };
                try out.validateProfile(explicit_intent);
            }
        },
        else => out.kind = .unknown,
    }
    return out;
}
pub fn parse(bytes: []const u8) Error!Info {
    if (bytes.len > png.max_encoded_bytes) return error.TooLarge;
    if (bytes.len < 2) return error.InvalidImage;
    if (same(bytes[0..2], "\xff\xd8")) return jpeg(bytes);
    if (same(bytes[0..2], "BM")) return bmp(bytes);
    return error.UnsupportedFormat;
}
