const std = @import("std");
const r4os = @import("r4os");
pub const abi = @import("r4img_abi.zig");

pub const name = abi.module_name;
pub const import_api_v1 = "R4IMG:API_V1:1";
pub const import_png_v1 = "R4IMG:PNG_V1:1";
pub const import_raster_v1 = "R4IMG:RASTER_V1:1";
/// Shared image/color orchestration. Pass the imported R4GFX binding type;
/// neither decoder ABI nor codec implementation acquires a color dependency.
pub const ColorDecoder = @import("color.zig").Decoder;
/// Optional AMD baseline JPEG -> canonical NV12 consumer over VIDEO_V1.
pub const NativeJpeg = @import("native_jpeg.zig").Consumer;
pub const max_dimension: u32 = abi.max_dimension;
pub const max_pixels: usize = @intCast(abi.max_pixels);
pub const max_scratch_bytes: usize = @intCast(abi.max_scratch_bytes);
pub const max_svg_source_bytes: usize = @intCast(abi.max_svg_source_bytes);

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
    InvalidArgument,
};

pub const SvgGlyphRowFn = *const fn (?*anyopaque, u32, u32) callconv(.c) u64;
pub const SvgLinkRecordFn = *const fn (?*anyopaque, u16, i32, i32, i32, i32) callconv(.c) void;

pub const SvgGlyphProvider = struct {
    context: ?*anyopaque = null,
    width: u16 = 8,
    height: u16 = 8,
    advance: u16 = 8,
    baseline: i16 = 7,
    row: ?SvgGlyphRowFn = null,
};

pub const SvgLinkSink = struct {
    context: ?*anyopaque = null,
    record: ?SvgLinkRecordFn = null,
};

pub const SvgRenderOptions = struct {
    glyphs: ?SvgGlyphProvider = null,
    links: ?SvgLinkSink = null,
    background: ?u32 = null,
};

pub const Info = struct {
    format: Format,
    width: u32,
    height: u32,
    channels: u8,

    pub fn pixelCount(self: Info) Error!usize {
        if (self.width == 0 or self.height == 0 or self.width > max_dimension or self.height > max_dimension) return error.InvalidDimensions;
        const count = std.math.mul(usize, self.width, self.height) catch return error.TooLarge;
        if (count > max_pixels) return error.TooLarge;
        return count;
    }
};

pub const Image = struct {
    info: Info,
    pixels: []u32,
};
pub const PngColor = abi.R4ImgPngColor;
pub const RasterColor = abi.R4ImgRasterColor;
pub const RasterContext = struct {
    client: abi.RasterV1Client,
    pub fn init(raw: *const r4os.abi.R4XStartContext) ?RasterContext {
        return .{ .client = abi.RasterV1Client.init(raw) catch return null };
    }
    pub fn init2(raw: *const r4os.platform2.abi.R4XStartContext2) ?RasterContext {
        return .{ .client = abi.RasterV1Client.init2(raw) catch return null };
    }
    pub fn color(self: *const RasterContext, bytes: []const u8) Error!RasterColor {
        var output: RasterColor = undefined;
        try errorForStatus(self.client.raster_color_info(bytes.ptr, bytes.len, &output));
        return output;
    }
    pub fn iccProfile(self: *const RasterContext, bytes: []const u8, output: []u8) Error![]u8 {
        var count: u64 = 0;
        try errorForStatus(self.client.raster_icc_profile(bytes.ptr, bytes.len, output.ptr, output.len, &count));
        if (count > output.len) return error.TooLarge;
        return output[0..@intCast(count)];
    }
};
pub const Image16 = struct { info: Info, color: PngColor, rgba: []u16 };

pub const DecoderDiagnostic = struct {
    scratch_peak: usize,
    allocation_failed: bool,
};

fn errorForStatus(status: i32) Error!void {
    return switch (status) {
        abi.status_ok => {},
        abi.status_empty => error.Empty,
        abi.status_unsupported_format => error.UnsupportedFormat,
        abi.status_invalid_image => error.InvalidImage,
        abi.status_invalid_dimensions => error.InvalidDimensions,
        abi.status_too_large => error.TooLarge,
        abi.status_pixel_buffer_too_small => error.PixelBufferTooSmall,
        abi.status_scratch_buffer_too_small => error.ScratchBufferTooSmall,
        abi.status_decode_failed => error.DecodeFailed,
        abi.status_unsupported_feature => error.UnsupportedFeature,
        abi.status_invalid_argument => error.InvalidArgument,
        else => error.InvalidArgument,
    };
}

fn formatFromAbi(value: u32) Error!Format {
    return switch (value) {
        abi.format_png => .png,
        abi.format_jpeg => .jpeg,
        abi.format_bmp => .bmp,
        abi.format_svg => .svg,
        else => error.InvalidImage,
    };
}

fn infoFromAbi(info: abi.R4ImgInfo) Error!Info {
    return .{
        .format = try formatFromAbi(info.format),
        .width = info.width,
        .height = info.height,
        .channels = std.math.cast(u8, info.channels) orelse return error.InvalidImage,
    };
}

fn infoToAbi(info: Info) abi.R4ImgInfo {
    const format: u32 = switch (info.format) {
        .png => abi.format_png,
        .jpeg => abi.format_jpeg,
        .bmp => abi.format_bmp,
        .svg => abi.format_svg,
    };
    return .{ .format = format, .width = info.width, .height = info.height, .channels = info.channels };
}

fn contextAddress(pointer: ?*anyopaque) u64 {
    return if (pointer) |value| @intFromPtr(value) else 0;
}

fn svgOptionsToAbi(options: SvgRenderOptions) abi.R4ImgSvgOptions {
    var out = abi.R4ImgSvgOptions{
        .flags = 0,
        .background = 0,
        .glyph_context = 0,
        .glyph_row = 0,
        .link_context = 0,
        .link_record = 0,
        .glyph_width = 0,
        .glyph_height = 0,
        .glyph_advance = 0,
        .glyph_baseline = 0,
        .reserved = 0,
    };
    if (options.glyphs) |glyphs| {
        out.flags |= abi.svg_flag_glyphs;
        out.glyph_context = contextAddress(glyphs.context);
        out.glyph_row = if (glyphs.row) |callback| @intFromPtr(callback) else 0;
        out.glyph_width = glyphs.width;
        out.glyph_height = glyphs.height;
        out.glyph_advance = glyphs.advance;
        out.glyph_baseline = glyphs.baseline;
    }
    if (options.links) |links| {
        out.flags |= abi.svg_flag_links;
        out.link_context = contextAddress(links.context);
        out.link_record = if (links.record) |callback| @intFromPtr(callback) else 0;
    }
    if (options.background) |background| {
        out.flags |= abi.svg_flag_background;
        out.background = background;
    }
    return out;
}

pub const Context = struct {
    client: abi.ApiV1Client,

    pub fn init(raw: *const r4os.abi.R4XStartContext) ?Context {
        return .{ .client = abi.ApiV1Client.init(raw) catch return null };
    }
    pub fn init2(raw: *const r4os.platform2.abi.R4XStartContext2) ?Context {
        return .{ .client = abi.ApiV1Client.init2(raw) catch return null };
    }

    pub fn probe(self: *const Context, bytes: []const u8, content_type: []const u8) Error!Info {
        var output = std.mem.zeroes(abi.R4ImgInfo);
        try errorForStatus(self.client.probe(bytes.ptr, bytes.len, content_type.ptr, content_type.len, &output));
        const info = try infoFromAbi(output);
        _ = try info.pixelCount();
        return info;
    }

    pub fn scratchBytesFor(self: *const Context, info: Info, encoded_bytes: usize) Error!usize {
        const input = infoToAbi(info);
        var output: u64 = 0;
        try errorForStatus(self.client.scratch_bytes(&input, encoded_bytes, &output));
        return std.math.cast(usize, output) orelse error.TooLarge;
    }

    pub fn decode(self: *const Context, bytes: []const u8, content_type: []const u8, pixels: []u32, scratch: []u8) Error!Image {
        var output_info = std.mem.zeroes(abi.R4ImgInfo);
        var output_count: u64 = 0;
        try errorForStatus(self.client.decode(
            bytes.ptr,
            bytes.len,
            content_type.ptr,
            content_type.len,
            pixels.ptr,
            pixels.len,
            scratch.ptr,
            scratch.len,
            &output_info,
            &output_count,
        ));
        const count = std.math.cast(usize, output_count) orelse return error.TooLarge;
        if (count > pixels.len) return error.InvalidImage;
        return .{ .info = try infoFromAbi(output_info), .pixels = pixels[0..count] };
    }

    pub fn decodeSvg(self: *const Context, bytes: []const u8, content_type: []const u8, pixels: []u32, scratch: []u8, options: SvgRenderOptions) Error!Image {
        const intrinsic = try self.probe(bytes, content_type);
        if (intrinsic.format != .svg) return error.UnsupportedFormat;
        return self.decodeSvgAt(bytes, content_type, pixels, scratch, intrinsic.width, intrinsic.height, options);
    }

    pub fn decodeSvgAt(self: *const Context, bytes: []const u8, content_type: []const u8, pixels: []u32, scratch: []u8, width: u32, height: u32, options: SvgRenderOptions) Error!Image {
        const input_options = svgOptionsToAbi(options);
        var output_info = std.mem.zeroes(abi.R4ImgInfo);
        var output_count: u64 = 0;
        try errorForStatus(self.client.decode_svg_at(
            bytes.ptr,
            bytes.len,
            content_type.ptr,
            content_type.len,
            pixels.ptr,
            pixels.len,
            scratch.ptr,
            scratch.len,
            width,
            height,
            &input_options,
            &output_info,
            &output_count,
        ));
        const count = std.math.cast(usize, output_count) orelse return error.TooLarge;
        if (count > pixels.len) return error.InvalidImage;
        return .{ .info = try infoFromAbi(output_info), .pixels = pixels[0..count] };
    }

    pub fn scaleComposite(self: *const Context, source: Image, destination: []u32, width: u32, height: u32, background: u32) Error![]u32 {
        const source_info = infoToAbi(source.info);
        var output_count: u64 = 0;
        try errorForStatus(self.client.scale_composite(
            &source_info,
            source.pixels.ptr,
            source.pixels.len,
            destination.ptr,
            destination.len,
            width,
            height,
            background,
            &output_count,
        ));
        const count = std.math.cast(usize, output_count) orelse return error.TooLarge;
        if (count > destination.len) return error.InvalidImage;
        return destination[0..count];
    }

    pub fn decoderDiagnostic(self: *const Context) Error!DecoderDiagnostic {
        var output = std.mem.zeroes(abi.R4ImgDecoderDiagnostic);
        try errorForStatus(self.client.decoder_diagnostic(&output));
        if (output.reserved != 0 or output.allocation_failed > 1) return error.InvalidImage;
        return .{
            .scratch_peak = std.math.cast(usize, output.scratch_peak) orelse return error.TooLarge,
            .allocation_failed = output.allocation_failed != 0,
        };
    }
};

test "facade keeps public metadata and ABI layouts stable" {
    try std.testing.expectEqualStrings("R4IMG", name);
    try std.testing.expectEqualStrings("R4IMG:API_V1:1", import_api_v1);
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(abi.R4ImgInfo));
    try std.testing.expectEqual(@as(usize, 56), @sizeOf(abi.R4ImgSvgOptions));
}

pub const PngContext = struct {
    client: abi.PngV1Client,
    pub fn init(raw: *const r4os.abi.R4XStartContext) ?PngContext {
        return .{ .client = abi.PngV1Client.init(raw) catch return null };
    }
    pub fn init2(raw: *const r4os.platform2.abi.R4XStartContext2) ?PngContext {
        return .{ .client = abi.PngV1Client.init2(raw) catch return null };
    }
    pub fn pngColor(self: *const PngContext, bytes: []const u8) Error!PngColor {
        var output: PngColor = undefined;
        try errorForStatus(self.client.png_color_info(bytes.ptr, bytes.len, &output));
        return output;
    }
    pub fn pngIccProfile(self: *const PngContext, bytes: []const u8, output: []u8) Error![]u8 {
        var count: u64 = 0;
        try errorForStatus(self.client.png_icc_profile(bytes.ptr, bytes.len, output.ptr, output.len, &count));
        if (count > output.len) return error.InvalidImage;
        return output[0..@intCast(count)];
    }
    pub fn pngScratchBytes16(self: *const PngContext, info: Info, encoded_bytes: usize) Error!usize {
        const input = infoToAbi(info);
        var output: u64 = 0;
        try errorForStatus(self.client.png_scratch_bytes16(&input, encoded_bytes, &output));
        return std.math.cast(usize, output) orelse error.TooLarge;
    }
    pub fn pngDecode16(self: *const PngContext, bytes: []const u8, rgba: []u16, scratch: []u8) Error!Image16 {
        var output_info: abi.R4ImgInfo = undefined;
        var output_color: PngColor = undefined;
        var count: u64 = 0;
        try errorForStatus(self.client.png_decode16(bytes.ptr, bytes.len, rgba.ptr, rgba.len, scratch.ptr, scratch.len, &output_info, &output_color, &count));
        const decoded_info = try infoFromAbi(output_info);
        if (count > rgba.len / 4 or count != try decoded_info.pixelCount()) return error.InvalidImage;
        return .{ .info = decoded_info, .color = output_color, .rgba = rgba[0..@intCast(count * 4)] };
    }
};
