const std = @import("std");

pub const ParseError = error{
    Truncated,
    NotIcon,
    BadDirectory,
    BadImage,
    UnsupportedCompression,
    UnsupportedBpp,
};

pub const Directory = struct {
    count: u16,
};

pub const Entry = struct {
    width: u16,
    height: u16,
    color_count: u8,
    planes: u16,
    bit_count: u16,
    bytes_in_res: u32,
    image_offset: u32,
};

pub const BitmapImage = struct {
    width: u32,
    height: u32,
    bpp: u16,
    pixel_offset: usize,
    stride: usize,
    palette_offset: usize = 0,
    palette_count: u32 = 0,
    mask_offset: usize = 0,
    mask_stride: usize = 0,
};

pub const Pixel = struct {
    rgb: u32,
    alpha: u8,
};

pub fn parseDirectory(bytes: []const u8) ParseError!Directory {
    if (bytes.len < 6) return ParseError.Truncated;
    if (readU16(bytes, 0) != 0 or readU16(bytes, 2) != 1) return ParseError.NotIcon;
    const count = readU16(bytes, 4);
    if (count == 0) return ParseError.BadDirectory;
    const needed = 6 + @as(usize, count) * 16;
    if (bytes.len < needed) return ParseError.Truncated;
    return .{ .count = count };
}

pub fn entryAt(bytes: []const u8, index: usize) ParseError!Entry {
    const dir = try parseDirectory(bytes);
    if (index >= dir.count) return ParseError.BadDirectory;
    const off = 6 + index * 16;
    return .{
        .width = iconDimension(bytes[off]),
        .height = iconDimension(bytes[off + 1]),
        .color_count = bytes[off + 2],
        .planes = readU16(bytes, off + 4),
        .bit_count = readU16(bytes, off + 6),
        .bytes_in_res = readU32(bytes, off + 8),
        .image_offset = readU32(bytes, off + 12),
    };
}

/// Dateityp-Icons (0.61.15): welche Dateinamen das Standard-Icon fuer
/// Textdateien bekommen. Bewusst im SDK - Desktop UND Explorer konsumieren
/// DIESELBE Endungsliste, eine zweite Wahrheit gaebe es sonst gratis.
/// Anfangsumfang .TXT und .MD; alles andere behaelt sein generisches
/// Symbol. Fehlt die Datei auf der Platte, faellt der Konsument auf sein
/// codegezeichnetes Symbol zurueck - kein Absturz, kein schwarzes Rechteck.
pub const textfile_icon_path = "C:\\R4OS\\Media\\Icons\\Textfile.ico";

pub fn isTextFileName(name: []const u8) bool {
    return endsWithIgnoreCase(name, ".TXT") or endsWithIgnoreCase(name, ".MD");
}

fn endsWithIgnoreCase(name: []const u8, suffix: []const u8) bool {
    if (name.len < suffix.len) return false;
    const tail = name[name.len - suffix.len ..];
    for (tail, suffix) |a, b| {
        const la = if (a >= 'A' and a <= 'Z') a + 32 else a;
        const lb = if (b >= 'A' and b <= 'Z') b + 32 else b;
        if (la != lb) return false;
    }
    return true;
}

test "text file names match case-insensitively and only on real suffixes" {
    try @import("std").testing.expect(isTextFileName("README.TXT"));
    try @import("std").testing.expect(isTextFileName("notes.txt"));
    try @import("std").testing.expect(isTextFileName("Doku.Md"));
    try @import("std").testing.expect(!isTextFileName("BILD.BMP"));
    try @import("std").testing.expect(!isTextFileName("TXT"));
    try @import("std").testing.expect(!isTextFileName("archiv.txt.bak"));
}

pub fn chooseBest(bytes: []const u8, preferred_size: u16) ParseError!Entry {
    const dir = try parseDirectory(bytes);
    var best = try entryAt(bytes, 0);
    var best_score = scoreEntry(best, preferred_size);
    var i: usize = 1;
    while (i < dir.count) : (i += 1) {
        const candidate = try entryAt(bytes, i);
        const candidate_score = scoreEntry(candidate, preferred_size);
        if (candidate_score < best_score) {
            best = candidate;
            best_score = candidate_score;
        }
    }
    return best;
}

pub fn parseBmpImage(bytes: []const u8, entry: Entry) ParseError!BitmapImage {
    const image_start: usize = @intCast(entry.image_offset);
    const image_size: usize = @intCast(entry.bytes_in_res);
    if (image_start > bytes.len or image_size > bytes.len - image_start) return ParseError.Truncated;
    const image = bytes[image_start .. image_start + image_size];
    if (image.len < 40) return ParseError.Truncated;
    const header_size = readU32(image, 0);
    if (header_size < 40 or header_size > image.len) return ParseError.BadImage;
    const width_i = readI32(image, 4);
    const height_i = readI32(image, 8);
    if (width_i <= 0 or height_i == 0) return ParseError.BadImage;
    const planes = readU16(image, 12);
    const bpp = readU16(image, 14);
    const compression = readU32(image, 16);
    if (planes != 1) return ParseError.BadImage;
    if (compression != 0) return ParseError.UnsupportedCompression;
    if (bpp != 32 and bpp != 8) return ParseError.UnsupportedBpp;

    const dib_width: u32 = @intCast(width_i);
    const raw_height: u32 = if (height_i < 0) @intCast(-height_i) else @intCast(height_i);
    const icon_height = if (raw_height == @as(u32, entry.height) * 2) @as(u32, entry.height) else raw_height;
    const palette_count = if (bpp == 8) paletteEntryCount(image, entry) else 0;
    if (palette_count > 256) return ParseError.BadImage;
    const palette_offset: usize = if (bpp == 8) header_size else 0;
    const palette_bytes = @as(usize, palette_count) * 4;
    if (palette_offset > image.len or palette_bytes > image.len - palette_offset) return ParseError.Truncated;

    const stride = bitmapStride(dib_width, bpp);
    const pixel_offset: usize = header_size + palette_bytes;
    const pixel_bytes = @as(usize, icon_height) * stride;
    if (pixel_offset > image.len or pixel_bytes > image.len - pixel_offset) return ParseError.Truncated;
    const mask_stride = bitmapMaskStride(dib_width);
    const mask_offset = pixel_offset + pixel_bytes;
    const mask_bytes = @as(usize, icon_height) * mask_stride;
    const has_mask = mask_offset <= image.len and mask_bytes <= image.len - mask_offset;
    return .{
        .width = dib_width,
        .height = icon_height,
        .bpp = bpp,
        .pixel_offset = image_start + pixel_offset,
        .stride = stride,
        .palette_offset = if (bpp == 8) image_start + palette_offset else 0,
        .palette_count = palette_count,
        .mask_offset = if (has_mask) image_start + mask_offset else 0,
        .mask_stride = if (has_mask) mask_stride else 0,
    };
}

pub fn pixelAt(bytes: []const u8, image: BitmapImage, x: u32, y: u32) ?Pixel {
    if (x >= image.width or y >= image.height) return null;
    const src_y = image.height - 1 - y;
    switch (image.bpp) {
        32 => {
            const off = image.pixel_offset + @as(usize, src_y) * image.stride + @as(usize, x) * 4;
            if (off + 4 > bytes.len) return null;
            const b = bytes[off];
            const g = bytes[off + 1];
            const r = bytes[off + 2];
            const a = bytes[off + 3];
            return .{ .rgb = (@as(u32, r) << 16) | (@as(u32, g) << 8) | b, .alpha = a };
        },
        8 => {
            const off = image.pixel_offset + @as(usize, src_y) * image.stride + @as(usize, x);
            if (off >= bytes.len) return null;
            const palette_index = bytes[off];
            if (@as(u32, palette_index) >= image.palette_count) return null;
            const palette_off = image.palette_offset + @as(usize, palette_index) * 4;
            if (palette_off + 4 > bytes.len) return null;
            const b = bytes[palette_off];
            const g = bytes[palette_off + 1];
            const r = bytes[palette_off + 2];
            const alpha: u8 = if (maskTransparent(bytes, image, x, src_y)) 0 else 0xFF;
            return .{ .rgb = (@as(u32, r) << 16) | (@as(u32, g) << 8) | b, .alpha = alpha };
        },
        else => return null,
    }
}

fn paletteEntryCount(image: []const u8, entry: Entry) u32 {
    const used = if (image.len >= 40) readU32(image, 32) else 0;
    if (used != 0) return used;
    if (entry.color_count != 0) return entry.color_count;
    return 256;
}

fn bitmapStride(width: u32, bpp: u16) usize {
    const bits = @as(usize, width) * @as(usize, bpp);
    return ((bits + 31) / 32) * 4;
}

fn bitmapMaskStride(width: u32) usize {
    return ((@as(usize, width) + 31) / 32) * 4;
}

fn maskTransparent(bytes: []const u8, image: BitmapImage, x: u32, src_y: u32) bool {
    if (image.mask_stride == 0) return false;
    const off = image.mask_offset + @as(usize, src_y) * image.mask_stride + @as(usize, x / 8);
    if (off >= bytes.len) return false;
    const bit: u3 = @intCast(7 - (x & 7));
    return (bytes[off] & (@as(u8, 1) << bit)) != 0;
}

fn iconDimension(value: u8) u16 {
    return if (value == 0) 256 else value;
}

fn scoreEntry(entry: Entry, preferred_size: u16) u32 {
    const size_delta = absDiff(entry.width, preferred_size) + absDiff(entry.height, preferred_size);
    const bpp_penalty: u32 = if (entry.bit_count == 32) 0 else @as(u32, 256) - @min(@as(u32, entry.bit_count), 255);
    return @as(u32, size_delta) * 4 + bpp_penalty;
}

fn absDiff(a: u16, b: u16) u16 {
    return if (a > b) a - b else b - a;
}

fn readU16(bytes: []const u8, off: usize) u16 {
    return @as(u16, bytes[off]) | (@as(u16, bytes[off + 1]) << 8);
}

fn readU32(bytes: []const u8, off: usize) u32 {
    return @as(u32, bytes[off]) |
        (@as(u32, bytes[off + 1]) << 8) |
        (@as(u32, bytes[off + 2]) << 16) |
        (@as(u32, bytes[off + 3]) << 24);
}

fn readI32(bytes: []const u8, off: usize) i32 {
    return @bitCast(readU32(bytes, off));
}

test "parse Windows ICO directory and 32bpp BMP image" {
    const bytes = [_]u8{
        0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x02, 0x02,
        0x00, 0x00, 0x01, 0x00, 0x20, 0x00, 0x40, 0x00,
        0x00, 0x00, 0x16, 0x00, 0x00, 0x00, 0x28, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x04, 0x00,
        0x00, 0x00, 0x01, 0x00, 0x20, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00,
        0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };

    const dir = try parseDirectory(bytes[0..]);
    try std.testing.expectEqual(@as(u16, 1), dir.count);
    const entry = try chooseBest(bytes[0..], 32);
    try std.testing.expectEqual(@as(u16, 2), entry.width);
    try std.testing.expectEqual(@as(u16, 2), entry.height);
    const image = try parseBmpImage(bytes[0..], entry);
    try std.testing.expectEqual(@as(u32, 2), image.width);
    try std.testing.expectEqual(@as(u32, 2), image.height);
    try std.testing.expectEqual(@as(u32, 0x0000FF), pixelAt(bytes[0..], image, 0, 0).?.rgb);
    try std.testing.expectEqual(@as(u8, 0xFF), pixelAt(bytes[0..], image, 0, 0).?.alpha);
    try std.testing.expectEqual(@as(u8, 0x00), pixelAt(bytes[0..], image, 1, 0).?.alpha);
}

test "parse 8bpp indexed BMP icon with AND mask" {
    const bytes = [_]u8{
        0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x02, 0x02,
        0x02, 0x00, 0x01, 0x00, 0x08, 0x00, 0x40, 0x00,
        0x00, 0x00, 0x16, 0x00, 0x00, 0x00, 0x28, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x04, 0x00,
        0x00, 0x00, 0x01, 0x00, 0x08, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x40, 0x00, 0x00, 0x00,
    };

    const entry = try chooseBest(bytes[0..], 32);
    const image = try parseBmpImage(bytes[0..], entry);
    try std.testing.expectEqual(@as(u16, 8), image.bpp);
    try std.testing.expectEqual(@as(u32, 2), image.width);
    try std.testing.expectEqual(@as(u32, 2), image.height);
    try std.testing.expectEqual(@as(u32, 0xFF0000), pixelAt(bytes[0..], image, 0, 0).?.rgb);
    try std.testing.expectEqual(@as(u8, 0xFF), pixelAt(bytes[0..], image, 0, 0).?.alpha);
    try std.testing.expectEqual(@as(u32, 0x0000FF), pixelAt(bytes[0..], image, 1, 0).?.rgb);
    try std.testing.expectEqual(@as(u8, 0x00), pixelAt(bytes[0..], image, 1, 0).?.alpha);
}
