const std = @import("std");
const svg = @import("svg.zig");
pub const color_metadata = @import("color_metadata.zig");
pub const raster_color = @import("raster_color.zig");

pub const max_dimension: u32 = 4096;
pub const max_pixels: usize = 4096 * 2160;
pub const max_scratch_bytes: usize = 224 * 1024 * 1024;
pub const max_svg_source_bytes: usize = svg.max_source_bytes;

pub const Format = enum(u8) {
    png,
    jpeg,
    bmp,
    svg,
};

pub const Error = error{
    Empty,
    UnsupportedFormat,
    InvalidImage,
    InvalidDimensions,
    TooLarge,
    PixelBufferTooSmall,
    ScratchBufferTooSmall,
    DecodeFailed,
    UnsupportedFeature,
};

pub const SvgGlyphProvider = svg.GlyphProvider;
pub const SvgLinkSink = svg.LinkSink;
pub const SvgRenderOptions = svg.RenderOptions;

pub const Info = struct {
    format: Format,
    width: u32,
    height: u32,
    channels: u8,

    pub fn pixelCount(self: Info) Error!usize {
        return checkedPixels(self.width, self.height);
    }
};

pub const Image = struct {
    info: Info,
    pixels: []u32,
};

extern fn r4img_stbi_decode(
    bytes: [*]const u8,
    length: usize,
    scratch: [*]u8,
    scratch_length: usize,
    pixels: [*]u32,
    pixel_capacity: usize,
    width: *c_int,
    height: *c_int,
    channels: *c_int,
) callconv(.c) c_int;
extern fn r4img_stbi_arena_peak() callconv(.c) usize;
extern fn r4img_stbi_arena_failed() callconv(.c) c_int;
extern fn r4img_stbi_decode16(bytes: [*]const u8, length: usize, scratch: [*]u8, scratch_length: usize, pixels: [*]u16, pixel_capacity: usize, width: *c_int, height: *c_int, channels: *c_int) callconv(.c) c_int;

pub const Image16 = struct { info: Info, metadata: color_metadata.Info, rgba: []u16 };
pub fn pngScratchBytes16(info: Info, encoded_length: usize) Error!usize {
    if (info.format != .png or encoded_length > color_metadata.max_encoded_bytes) return error.UnsupportedFormat;
    const count = try info.pixelCount();
    const pixel_bytes = std.math.mul(usize, count, 24) catch return error.TooLarge;
    const encoded_bytes = std.math.mul(usize, encoded_length, 2) catch return error.TooLarge;
    const bytes = std.math.add(usize, pixel_bytes, encoded_bytes) catch return error.TooLarge;
    const total = std.math.add(usize, bytes, 65536) catch return error.TooLarge;
    if (total > max_scratch_bytes) return error.TooLarge;
    return total;
}
pub fn pngDecode16(bytes: []const u8, pixels: []u16, scratch: []u8) Error!Image16 {
    const metadata = color_metadata.png(bytes) catch |err| return metadataError(err);
    const info = try r4imgProbe(bytes, "image/png");
    const count = try info.pixelCount();
    if (pixels.len < count * 4) return error.PixelBufferTooSmall;
    const required = try pngScratchBytes16(info, bytes.len);
    if (scratch.len < required) return error.ScratchBufferTooSmall;
    const output = std.mem.sliceAsBytes(pixels[0 .. count * 4]);
    if (spansOverlap(bytes, output) or spansOverlap(bytes, scratch) or spansOverlap(output, scratch)) return error.InvalidImage;
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;
    if (r4img_stbi_decode16(bytes.ptr, bytes.len, scratch.ptr, scratch.len, pixels.ptr, pixels.len / 4, &width, &height, &channels) == 0) return error.DecodeFailed;
    if (width != info.width or height != info.height) return error.InvalidImage;
    return .{ .info = info, .metadata = metadata, .rgba = pixels[0 .. count * 4] };
}
fn metadataError(err: color_metadata.Error) Error {
    return switch (err) {
        error.InvalidImage => error.InvalidImage,
        error.UnsupportedFeature => error.UnsupportedFeature,
        error.TooLarge => error.TooLarge,
        error.PixelBufferTooSmall => error.PixelBufferTooSmall,
    };
}
fn spansOverlap(first: []const u8, second: []const u8) bool {
    const a = @intFromPtr(first.ptr);
    const b = @intFromPtr(second.ptr);
    const end = std.math.add(usize, a, first.len) catch return true;
    const limit = std.math.add(usize, b, second.len) catch return true;
    return first.len != 0 and second.len != 0 and a < limit and b < end;
}

pub const DecoderDiagnostic = struct {
    scratch_peak: usize,
    allocation_failed: bool,
};

pub fn decoderDiagnostic() DecoderDiagnostic {
    return .{
        .scratch_peak = r4img_stbi_arena_peak(),
        .allocation_failed = r4img_stbi_arena_failed() != 0,
    };
}

pub fn sniff(bytes: []const u8) ?Format {
    if (bytes.len >= 8 and std.mem.eql(u8, bytes[0..8], "\x89PNG\r\n\x1a\n")) return .png;
    if (bytes.len >= 3 and bytes[0] == 0xFF and bytes[1] == 0xD8 and bytes[2] == 0xFF) return .jpeg;
    if (bytes.len >= 2 and bytes[0] == 'B' and bytes[1] == 'M') return .bmp;
    if (svg.sniff(bytes)) return .svg;
    return null;
}

pub fn r4imgProbe(bytes: []const u8, content_type: []const u8) Error!Info {
    if (bytes.len == 0) return error.Empty;
    const format = sniff(bytes) orelse return error.UnsupportedFormat;
    if (!mimeAllows(content_type, format)) return error.UnsupportedFormat;
    const dimensions = try probeDimensions(bytes, format);
    const info = Info{
        .format = format,
        .width = dimensions.width,
        .height = dimensions.height,
        .channels = dimensions.channels,
    };
    _ = try info.pixelCount();
    return info;
}

const Dimensions = struct { width: u32, height: u32, channels: u8 };

fn probeDimensions(bytes: []const u8, format: Format) Error!Dimensions {
    return switch (format) {
        .png => probePng(bytes),
        .jpeg => probeJpeg(bytes),
        .bmp => probeBmp(bytes),
        .svg => probeSvg(bytes),
    };
}

fn probeSvg(bytes: []const u8) Error!Dimensions {
    const info = svg.probe(bytes) catch |err| return mapSvgError(err);
    return .{ .width = info.width, .height = info.height, .channels = 4 };
}

fn probePng(bytes: []const u8) Error!Dimensions {
    if (bytes.len < 29 or !std.mem.eql(u8, bytes[12..16], "IHDR")) return error.InvalidImage;
    const width = readBe32(bytes, 16);
    const height = readBe32(bytes, 20);
    const channels: u8 = switch (bytes[25]) {
        0 => 1,
        2 => 3,
        3 => 1,
        4 => 2,
        6 => 4,
        else => return error.InvalidImage,
    };
    return .{ .width = width, .height = height, .channels = channels };
}

fn probeJpeg(bytes: []const u8) Error!Dimensions {
    if (bytes.len < 4) return error.InvalidImage;
    var cursor: usize = 2;
    while (cursor + 1 < bytes.len) {
        while (cursor < bytes.len and bytes[cursor] != 0xFF) cursor += 1;
        while (cursor < bytes.len and bytes[cursor] == 0xFF) cursor += 1;
        if (cursor >= bytes.len) break;
        const marker = bytes[cursor];
        cursor += 1;
        if (marker == 0x00 or marker == 0x01 or (marker >= 0xD0 and marker <= 0xD9)) continue;
        if (cursor + 2 > bytes.len) return error.InvalidImage;
        const segment_length = readBe16(bytes, cursor);
        if (segment_length < 2 or segment_length > bytes.len - cursor) return error.InvalidImage;
        if (marker == 0xC0 or marker == 0xC1 or marker == 0xC2) {
            if (segment_length < 8) return error.InvalidImage;
            const height = readBe16(bytes, cursor + 3);
            const width = readBe16(bytes, cursor + 5);
            const channels = bytes[cursor + 7];
            if (channels == 0 or channels > 4) return error.InvalidImage;
            return .{ .width = width, .height = height, .channels = channels };
        }
        cursor += segment_length;
    }
    return error.InvalidImage;
}

fn probeBmp(bytes: []const u8) Error!Dimensions {
    if (bytes.len < 30) return error.InvalidImage;
    const width_signed: i32 = @bitCast(readLe32(bytes, 18));
    const height_signed: i32 = @bitCast(readLe32(bytes, 22));
    if (width_signed <= 0 or height_signed == 0 or height_signed == std.math.minInt(i32)) return error.InvalidDimensions;
    const bpp = readLe16(bytes, 28);
    const channels: u8 = if (bpp == 32) 4 else if (bpp == 24) 3 else return error.InvalidImage;
    return .{
        .width = @intCast(width_signed),
        .height = @intCast(if (height_signed < 0) -height_signed else height_signed),
        .channels = channels,
    };
}

fn readBe16(bytes: []const u8, offset: usize) u16 {
    return (@as(u16, bytes[offset]) << 8) | bytes[offset + 1];
}

fn readBe32(bytes: []const u8, offset: usize) u32 {
    return (@as(u32, bytes[offset]) << 24) | (@as(u32, bytes[offset + 1]) << 16) |
        (@as(u32, bytes[offset + 2]) << 8) | bytes[offset + 3];
}

fn readLe16(bytes: []const u8, offset: usize) u16 {
    return @as(u16, bytes[offset]) | (@as(u16, bytes[offset + 1]) << 8);
}

fn readLe32(bytes: []const u8, offset: usize) u32 {
    return @as(u32, bytes[offset]) | (@as(u32, bytes[offset + 1]) << 8) |
        (@as(u32, bytes[offset + 2]) << 16) | (@as(u32, bytes[offset + 3]) << 24);
}

pub fn scratchBytesFor(info: Info, encoded_bytes: usize) Error!usize {
    const pixels = try info.pixelCount();
    if (info.format == .svg) {
        const pixel_work = std.math.mul(usize, pixels, 8) catch return error.TooLarge;
        const source_work = std.math.mul(usize, encoded_bytes, 12) catch return error.TooLarge;
        const total = std.math.add(usize, pixel_work, source_work) catch return error.TooLarge;
        const with_margin = std.math.add(usize, total, 128 * 1024) catch return error.TooLarge;
        if (with_margin > max_scratch_bytes) return error.TooLarge;
        return with_margin;
    }
    // stb_image can retain component, coefficient, IDCT and RGBA workspaces at
    // the same time, especially for progressive JPEG. Keep this caller-owned
    // bound proportional to decoded pixels instead of relying on tiny fixtures.
    const pixel_work = std.math.mul(usize, pixels, 16) catch return error.TooLarge;
    const encoded_work = std.math.mul(usize, encoded_bytes, 2) catch return error.TooLarge;
    const total = std.math.add(usize, pixel_work, encoded_work) catch return error.TooLarge;
    const with_margin = std.math.add(usize, total, 64 * 1024) catch return error.TooLarge;
    if (with_margin > max_scratch_bytes) return error.TooLarge;
    return with_margin;
}

pub fn r4imgDecode(bytes: []const u8, content_type: []const u8, pixels: []u32, scratch: []u8) Error!Image {
    const expected = try r4imgProbe(bytes, content_type);
    if (expected.format == .svg) return r4imgDecodeSvg(bytes, content_type, pixels, scratch, .{});
    const count = try expected.pixelCount();
    if (pixels.len < count) return error.PixelBufferTooSmall;
    const required_scratch = try scratchBytesFor(expected, bytes.len);
    if (scratch.len < required_scratch) return error.ScratchBufferTooSmall;
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;
    if (r4img_stbi_decode(
        bytes.ptr,
        bytes.len,
        scratch.ptr,
        scratch.len,
        pixels.ptr,
        pixels.len,
        &width,
        &height,
        &channels,
    ) == 0) return error.DecodeFailed;
    if (width != @as(c_int, @intCast(expected.width)) or height != @as(c_int, @intCast(expected.height))) return error.InvalidImage;
    return .{ .info = expected, .pixels = pixels[0..count] };
}

pub fn r4imgDecodeSvg(bytes: []const u8, content_type: []const u8, pixels: []u32, scratch: []u8, options: SvgRenderOptions) Error!Image {
    const expected = try r4imgProbe(bytes, content_type);
    if (expected.format != .svg) return error.UnsupportedFormat;
    return decodeSvgTarget(bytes, pixels, scratch, expected, options);
}

pub fn r4imgDecodeSvgAt(bytes: []const u8, content_type: []const u8, pixels: []u32, scratch: []u8, width: u32, height: u32, options: SvgRenderOptions) Error!Image {
    const source_info = try r4imgProbe(bytes, content_type);
    if (source_info.format != .svg) return error.UnsupportedFormat;
    const target = Info{ .format = .svg, .width = width, .height = height, .channels = 4 };
    _ = try target.pixelCount();
    return decodeSvgTarget(bytes, pixels, scratch, target, options);
}

fn decodeSvgTarget(bytes: []const u8, pixels: []u32, scratch: []u8, target: Info, options: SvgRenderOptions) Error!Image {
    const count = try target.pixelCount();
    if (pixels.len < count) return error.PixelBufferTooSmall;
    const required_scratch = try scratchBytesFor(target, bytes.len);
    if (scratch.len < required_scratch) return error.ScratchBufferTooSmall;
    svg.render(bytes, pixels[0..count], target.width, target.height, scratch, options) catch |err| return mapSvgError(err);
    return .{ .info = target, .pixels = pixels[0..count] };
}

fn mapSvgError(err: svg.Error) Error {
    return switch (err) {
        error.Empty => error.Empty,
        error.UnsupportedFeature => error.UnsupportedFeature,
        error.SourceTooLarge, error.NodeLimit, error.AttributeLimit, error.DepthLimit, error.PathLimit, error.TooLarge => error.TooLarge,
        error.PixelBufferTooSmall => error.PixelBufferTooSmall,
        error.ScratchBufferTooSmall => error.ScratchBufferTooSmall,
        error.InvalidXml, error.MissingRoot, error.InvalidNumber, error.InvalidDimensions => error.InvalidImage,
    };
}

pub fn scaleComposite(source: Image, destination: []u32, width: u32, height: u32, background: u32) Error![]u32 {
    const count = try checkedPixels(width, height);
    if (destination.len < count) return error.PixelBufferTooSmall;
    const source_count = try source.info.pixelCount();
    if (source.pixels.len < source_count) return error.InvalidImage;
    const bg_r: u32 = (background >> 16) & 0xFF;
    const bg_g: u32 = (background >> 8) & 0xFF;
    const bg_b: u32 = background & 0xFF;
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        const vertical = sampleAxis(y, height, source.info.height);
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const horizontal = sampleAxis(x, width, source.info.width);
            const p00 = source.pixels[@as(usize, vertical.low) * source.info.width + horizontal.low];
            const p10 = source.pixels[@as(usize, vertical.low) * source.info.width + horizontal.high];
            const p01 = source.pixels[@as(usize, vertical.high) * source.info.width + horizontal.low];
            const p11 = source.pixels[@as(usize, vertical.high) * source.info.width + horizontal.high];
            const top_weight = 256 - vertical.fraction;
            const left_weight = 256 - horizontal.fraction;
            const weights = [4]u32{
                top_weight * left_weight,
                top_weight * horizontal.fraction,
                vertical.fraction * left_weight,
                vertical.fraction * horizontal.fraction,
            };
            const samples = [4]u32{ p00, p10, p01, p11 };
            var alpha_sum: u64 = 0;
            var red_sum: u64 = 0;
            var green_sum: u64 = 0;
            var blue_sum: u64 = 0;
            for (samples, weights) |pixel, weight| {
                const alpha: u64 = (pixel >> 24) & 0xFF;
                alpha_sum += alpha * weight;
                red_sum += @as(u64, (pixel >> 16) & 0xFF) * alpha * weight;
                green_sum += @as(u64, (pixel >> 8) & 0xFF) * alpha * weight;
                blue_sum += @as(u64, pixel & 0xFF) * alpha * weight;
            }
            const alpha: u32 = @intCast((alpha_sum + 32768) >> 16);
            const red_premultiplied: u32 = @intCast((red_sum + 32768) >> 16);
            const green_premultiplied: u32 = @intCast((green_sum + 32768) >> 16);
            const blue_premultiplied: u32 = @intCast((blue_sum + 32768) >> 16);
            const inverse = 255 - alpha;
            const red = @min(@as(u32, 255), (red_premultiplied + bg_r * inverse + 127) / 255);
            const green = @min(@as(u32, 255), (green_premultiplied + bg_g * inverse + 127) / 255);
            const blue = @min(@as(u32, 255), (blue_premultiplied + bg_b * inverse + 127) / 255);
            destination[@as(usize, y) * @as(usize, width) + @as(usize, x)] =
                (@as(u32, red) << @as(u5, 16)) | (@as(u32, green) << @as(u5, 8)) | @as(u32, blue);
        }
    }
    return destination[0..count];
}

const AxisSample = struct {
    low: u32,
    high: u32,
    fraction: u32,
};

fn sampleAxis(position: u32, destination_size: u32, source_size: u32) AxisSample {
    if (source_size <= 1 or destination_size <= 1) return .{ .low = 0, .high = 0, .fraction = 0 };
    const numerator = (@as(u64, position) * 2 + 1) * source_size * 256;
    const centered = @as(i64, @intCast(numerator / (@as(u64, destination_size) * 2))) - 128;
    if (centered <= 0) return .{ .low = 0, .high = @min(@as(u32, 1), source_size - 1), .fraction = 0 };
    const integral: u32 = @intCast(@as(u64, @intCast(centered)) >> 8);
    const low = @min(integral, source_size - 1);
    return .{
        .low = low,
        .high = @min(low + 1, source_size - 1),
        .fraction = if (low + 1 < source_size) @intCast(@as(u64, @intCast(centered)) & 0xFF) else 0,
    };
}

fn checkedPixels(width: u32, height: u32) Error!usize {
    if (width == 0 or height == 0 or width > max_dimension or height > max_dimension) return error.InvalidDimensions;
    const count = std.math.mul(usize, width, height) catch return error.TooLarge;
    if (count > max_pixels) return error.TooLarge;
    return count;
}

fn mimeAllows(content_type: []const u8, format: Format) bool {
    if (content_type.len == 0 or std.ascii.eqlIgnoreCase(content_type, "application/octet-stream")) return true;
    const semicolon = std.mem.indexOfScalar(u8, content_type, ';') orelse content_type.len;
    const mime = std.mem.trim(u8, content_type[0..semicolon], " \t\r\n");
    if (std.ascii.eqlIgnoreCase(mime, "image/*")) return true;
    return switch (format) {
        .png => std.ascii.eqlIgnoreCase(mime, "image/png") or std.ascii.eqlIgnoreCase(mime, "image/x-png"),
        .jpeg => std.ascii.eqlIgnoreCase(mime, "image/jpeg") or std.ascii.eqlIgnoreCase(mime, "image/jpg") or std.ascii.eqlIgnoreCase(mime, "image/pjpeg"),
        .bmp => std.ascii.eqlIgnoreCase(mime, "image/bmp") or std.ascii.eqlIgnoreCase(mime, "image/x-ms-bmp"),
        .svg => std.ascii.eqlIgnoreCase(mime, "image/svg+xml"),
    };
}

test "R4IMG identifies its supported image signatures" {
    try std.testing.expectEqual(Format.png, sniff("\x89PNG\r\n\x1a\nrest").?);
    try std.testing.expectEqual(Format.jpeg, sniff("\xFF\xD8\xFF\xE0").?);
    try std.testing.expectEqual(Format.bmp, sniff("BMrest").?);
    try std.testing.expectEqual(Format.svg, sniff("<?xml version='1.0'?><svg viewBox='0 0 1 1'/>").?);
    try std.testing.expect(sniff("GIF89a") == null);
}

test "R4IMG scratch bound covers realistic JPEG workspaces proportionally" {
    const info = Info{ .format = .jpeg, .width = 325, .height = 480, .channels = 3 };
    try std.testing.expectEqual(@as(usize, 2_672_356), try scratchBytesFor(info, 55_410));
    try std.testing.expect((try scratchBytesFor(info, 55_410)) > 2 * 1024 * 1024);
}

test "R4IMG bounds cover the complete Desktop wallpaper contract" {
    const info = Info{ .format = .bmp, .width = 4096, .height = 2160, .channels = 4 };
    try std.testing.expectEqual(max_pixels, try info.pixelCount());
    try std.testing.expect((try scratchBytesFor(info, 32 * 1024 * 1024)) <= max_scratch_bytes);
}

test "R4IMG bilinear scaling composites transparent ARGB onto the page background" {
    var source_pixels = [_]u32{ 0xFFFF0000, 0x00000000, 0xFF0000FF, 0xFFFFFFFF };
    const source = Image{ .info = .{ .format = .png, .width = 2, .height = 2, .channels = 4 }, .pixels = source_pixels[0..] };
    var destination: [16]u32 = undefined;
    const result = try scaleComposite(source, destination[0..], 4, 4, 0x00FFFFFF);
    try std.testing.expectEqual(@as(usize, 16), result.len);
    try std.testing.expectEqual(@as(u32, 0x00FF0000), result[0]);
    try std.testing.expectEqual(@as(u32, 0x00FFFFFF), result[3]);
    try std.testing.expectEqual(@as(u32, 0x000000FF), result[12]);
    try std.testing.expectEqual(@as(u32, 0x00FFFFFF), result[15]);
}
