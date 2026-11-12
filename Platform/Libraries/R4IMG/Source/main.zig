const std = @import("std");
const r4os = @import("r4os");
const contract = @import("r4l_contract");
const codec = @import("codec.zig");
const color_api = @import("color_api.zig");

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}

fn statusForError(err: codec.Error) i32 {
    return switch (err) {
        error.Empty => contract.status_empty,
        error.UnsupportedFormat => contract.status_unsupported_format,
        error.InvalidImage => contract.status_invalid_image,
        error.InvalidDimensions => contract.status_invalid_dimensions,
        error.TooLarge => contract.status_too_large,
        error.PixelBufferTooSmall => contract.status_pixel_buffer_too_small,
        error.ScratchBufferTooSmall => contract.status_scratch_buffer_too_small,
        error.DecodeFailed => contract.status_decode_failed,
        error.UnsupportedFeature => contract.status_unsupported_feature,
    };
}

fn formatToAbi(format: codec.Format) u32 {
    return switch (format) {
        .png => contract.format_png,
        .jpeg => contract.format_jpeg,
        .bmp => contract.format_bmp,
        .svg => contract.format_svg,
    };
}

fn formatFromAbi(value: u32) ?codec.Format {
    return switch (value) {
        contract.format_png => .png,
        contract.format_jpeg => .jpeg,
        contract.format_bmp => .bmp,
        contract.format_svg => .svg,
        else => null,
    };
}

fn infoToAbi(info: codec.Info) contract.R4ImgInfo {
    return .{
        .format = formatToAbi(info.format),
        .width = info.width,
        .height = info.height,
        .channels = info.channels,
    };
}

fn infoFromAbi(info: contract.R4ImgInfo) ?codec.Info {
    const format = formatFromAbi(info.format) orelse return null;
    const channels = std.math.cast(u8, info.channels) orelse return null;
    return .{ .format = format, .width = info.width, .height = info.height, .channels = channels };
}

fn length(value: u64) ?usize {
    return std.math.cast(usize, value);
}

pub export fn r4img_probe_impl(
    encoded: [*]const u8,
    encoded_length: u64,
    content_type: [*]const u8,
    content_type_length: u64,
    output: *contract.R4ImgInfo,
) linksection(".text.r4l_exports") callconv(.c) i32 {
    const encoded_len = length(encoded_length) orelse return contract.status_invalid_argument;
    const content_type_len = length(content_type_length) orelse return contract.status_invalid_argument;
    const info = codec.r4imgProbe(encoded[0..encoded_len], content_type[0..content_type_len]) catch |err| return statusForError(err);
    output.* = infoToAbi(info);
    return contract.status_ok;
}

pub export fn r4img_scratch_bytes_impl(
    info: *const contract.R4ImgInfo,
    encoded_length: u64,
    output_bytes: *u64,
) linksection(".text.r4l_exports") callconv(.c) i32 {
    const local_info = infoFromAbi(info.*) orelse return contract.status_invalid_argument;
    const encoded_len = length(encoded_length) orelse return contract.status_invalid_argument;
    const required = codec.scratchBytesFor(local_info, encoded_len) catch |err| return statusForError(err);
    output_bytes.* = required;
    return contract.status_ok;
}

pub export fn r4img_decode_impl(
    encoded: [*]const u8,
    encoded_length: u64,
    content_type: [*]const u8,
    content_type_length: u64,
    pixels: [*]u32,
    pixel_capacity: u64,
    scratch: [*]u8,
    scratch_length: u64,
    output_info: *contract.R4ImgInfo,
    output_pixel_count: *u64,
) linksection(".text.r4l_exports") callconv(.c) i32 {
    const encoded_len = length(encoded_length) orelse return contract.status_invalid_argument;
    const content_type_len = length(content_type_length) orelse return contract.status_invalid_argument;
    const pixel_len = length(pixel_capacity) orelse return contract.status_invalid_argument;
    const scratch_len = length(scratch_length) orelse return contract.status_invalid_argument;
    const image = codec.r4imgDecode(
        encoded[0..encoded_len],
        content_type[0..content_type_len],
        pixels[0..pixel_len],
        scratch[0..scratch_len],
    ) catch |err| return statusForError(err);
    output_info.* = infoToAbi(image.info);
    output_pixel_count.* = image.pixels.len;
    return contract.status_ok;
}

const GlyphRowFn = *const fn (?*anyopaque, u32, u32) callconv(.c) u64;
const LinkRecordFn = *const fn (?*anyopaque, u16, i32, i32, i32, i32) callconv(.c) void;

fn pointerContext(address: u64) ?*anyopaque {
    return if (address == 0) null else @ptrFromInt(@as(usize, @intCast(address)));
}

fn svgOptionsFromAbi(options: contract.R4ImgSvgOptions) ?codec.SvgRenderOptions {
    const known_flags = contract.svg_flag_glyphs | contract.svg_flag_links | contract.svg_flag_background;
    if (options.flags & ~known_flags != 0 or options.reserved != 0) return null;
    var out = codec.SvgRenderOptions{};
    if (options.flags & contract.svg_flag_glyphs != 0) {
        if (options.glyph_row == 0 or options.glyph_width == 0 or options.glyph_height == 0 or options.glyph_advance == 0) return null;
        out.glyphs = .{
            .context = pointerContext(options.glyph_context),
            .width = options.glyph_width,
            .height = options.glyph_height,
            .advance = options.glyph_advance,
            .baseline = options.glyph_baseline,
            .row = @ptrFromInt(@as(usize, @intCast(options.glyph_row))),
        };
    }
    if (options.flags & contract.svg_flag_links != 0) {
        if (options.link_record == 0) return null;
        out.links = .{
            .context = pointerContext(options.link_context),
            .record = @ptrFromInt(@as(usize, @intCast(options.link_record))),
        };
    }
    if (options.flags & contract.svg_flag_background != 0) out.background = options.background;
    return out;
}

pub export fn r4img_decode_svg_at_impl(
    encoded: [*]const u8,
    encoded_length: u64,
    content_type: [*]const u8,
    content_type_length: u64,
    pixels: [*]u32,
    pixel_capacity: u64,
    scratch: [*]u8,
    scratch_length: u64,
    width: u32,
    height: u32,
    options: *const contract.R4ImgSvgOptions,
    output_info: *contract.R4ImgInfo,
    output_pixel_count: *u64,
) linksection(".text.r4l_exports") callconv(.c) i32 {
    const encoded_len = length(encoded_length) orelse return contract.status_invalid_argument;
    const content_type_len = length(content_type_length) orelse return contract.status_invalid_argument;
    const pixel_len = length(pixel_capacity) orelse return contract.status_invalid_argument;
    const scratch_len = length(scratch_length) orelse return contract.status_invalid_argument;
    const local_options = svgOptionsFromAbi(options.*) orelse return contract.status_invalid_argument;
    const image = codec.r4imgDecodeSvgAt(
        encoded[0..encoded_len],
        content_type[0..content_type_len],
        pixels[0..pixel_len],
        scratch[0..scratch_len],
        width,
        height,
        local_options,
    ) catch |err| return statusForError(err);
    output_info.* = infoToAbi(image.info);
    output_pixel_count.* = image.pixels.len;
    return contract.status_ok;
}

pub export fn r4img_scale_composite_impl(
    source_info: *const contract.R4ImgInfo,
    source_pixels: [*]const u32,
    source_pixel_count: u64,
    destination: [*]u32,
    destination_capacity: u64,
    width: u32,
    height: u32,
    background: u32,
    output_pixel_count: *u64,
) linksection(".text.r4l_exports") callconv(.c) i32 {
    const local_info = infoFromAbi(source_info.*) orelse return contract.status_invalid_argument;
    const source_len = length(source_pixel_count) orelse return contract.status_invalid_argument;
    const destination_len = length(destination_capacity) orelse return contract.status_invalid_argument;
    const scaled = codec.scaleComposite(
        .{ .info = local_info, .pixels = @constCast(source_pixels[0..source_len]) },
        destination[0..destination_len],
        width,
        height,
        background,
    ) catch |err| return statusForError(err);
    output_pixel_count.* = scaled.len;
    return contract.status_ok;
}

pub export fn r4img_decoder_diagnostic_impl(output: *contract.R4ImgDecoderDiagnostic) linksection(".text.r4l_exports") callconv(.c) i32 {
    const diagnostic = codec.decoderDiagnostic();
    output.* = .{
        .scratch_peak = diagnostic.scratch_peak,
        .allocation_failed = @intFromBool(diagnostic.allocation_failed),
        .reserved = 0,
    };
    return contract.status_ok;
}

pub export var r4img_api_v1: contract.ApiV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.api_v1_header,
    .probe = r4img_probe_impl,
    .scratch_bytes = r4img_scratch_bytes_impl,
    .decode = r4img_decode_impl,
    .decode_svg_at = r4img_decode_svg_at_impl,
    .scale_composite = r4img_scale_composite_impl,
    .decoder_diagnostic = r4img_decoder_diagnostic_impl,
};
pub export var r4img_png_v1: contract.PngV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.png_v1_header,
    .png_color_info = color_api.info,
    .png_icc_profile = color_api.profile,
    .png_scratch_bytes16 = color_api.scratchBytes,
    .png_decode16 = color_api.decode,
};
pub export var r4img_raster_v1: contract.RasterV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.raster_v1_header,
    .raster_color_info = color_api.rasterInfo,
    .raster_icc_profile = color_api.rasterProfile,
};

pub export var r4img_query: r4os.abi.R4LQuery align(8) linksection(".data.r4l_exports") = .{
    .magic = r4os.abi.r4l_abi_magic,
    .abi_version = r4os.abi.r4l_abi_version,
    .size = r4os.abi.r4l_query_struct_size,
    .group = 0,
    .kernel_bridge = 0,
    .reserved = 0,
};

test "ABI conversion preserves every supported format and fixed layout" {
    inline for (.{ codec.Format.png, codec.Format.jpeg, codec.Format.bmp, codec.Format.svg }) |format| {
        const info = codec.Info{ .format = format, .width = 2, .height = 3, .channels = 4 };
        const roundtrip = infoFromAbi(infoToAbi(info)).?;
        try std.testing.expectEqual(format, roundtrip.format);
        try std.testing.expectEqual(info.width, roundtrip.width);
        try std.testing.expectEqual(info.height, roundtrip.height);
        try std.testing.expectEqual(info.channels, roundtrip.channels);
    }
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(contract.R4ImgInfo));
    try std.testing.expectEqual(@as(usize, 56), @sizeOf(contract.R4ImgSvgOptions));
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(contract.R4ImgDecoderDiagnostic));
}

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4img_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
