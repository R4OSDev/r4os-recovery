//! Append-only PNG color/precision API. Container parsing and retained color
//! metadata belong to the decoder; profile interpretation belongs to R4GFX.
const std = @import("std");
const c = @import("r4l_contract");
const codec = @import("codec.zig");
const metadata = codec.color_metadata;

fn status(err: anyerror) i32 {
    return switch (err) {
        error.Empty => c.status_empty,
        error.UnsupportedFormat => c.status_unsupported_format,
        error.InvalidImage => c.status_invalid_image,
        error.InvalidDimensions => c.status_invalid_dimensions,
        error.TooLarge => c.status_too_large,
        error.PixelBufferTooSmall => c.status_pixel_buffer_too_small,
        error.ScratchBufferTooSmall => c.status_scratch_buffer_too_small,
        error.DecodeFailed => c.status_decode_failed,
        error.UnsupportedFeature => c.status_unsupported_feature,
        else => c.status_invalid_argument,
    };
}
fn overlap(a: []const u8, b: []const u8) bool {
    return a.len != 0 and b.len != 0 and @intFromPtr(a.ptr) < @intFromPtr(b.ptr) +| b.len and @intFromPtr(b.ptr) < @intFromPtr(a.ptr) +| a.len;
}
fn separate(spans: []const []const u8) bool {
    for (spans, 0..) |span, i| for (spans[0..i]) |prior| if (overlap(span, prior)) return false;
    return true;
}
fn convert(parsed: metadata.Info) c.R4ImgPngColor {
    var out = std.mem.zeroes(c.R4ImgPngColor);
    out.version = 1;
    out.size = @sizeOf(c.R4ImgPngColor);
    out.kind = @intFromEnum(parsed.kind());
    out.bit_depth = parsed.bit_depth;
    out.color_type = parsed.color_type;
    if (parsed.cicp) |values| {
        out.flags |= c.png_has_cicp;
        out.cicp_primaries = values[0];
        out.cicp_transfer = values[1];
        out.cicp_matrix = values[2];
        out.cicp_full_range = values[3];
    }
    if (parsed.compressed_profile.len != 0) out.flags |= c.png_has_icc;
    if (parsed.intent) |value| {
        out.flags |= c.png_has_srgb;
        out.intent = value;
    }
    if (parsed.gamma) |value| {
        out.flags |= c.png_has_gamma;
        out.gamma = value;
    }
    if (parsed.chromaticities) |values| {
        out.flags |= c.png_has_chroma;
        inline for (.{ "white_x", "white_y", "red_x", "red_y", "green_x", "green_y", "blue_x", "blue_y" }, 0..) |field, i| @field(out, field) = values[i];
    }
    if (parsed.mastering) |value| {
        out.flags |= c.png_has_mastering;
        inline for (.{ "mastering_red_x", "mastering_red_y", "mastering_green_x", "mastering_green_y", "mastering_blue_x", "mastering_blue_y", "mastering_white_x", "mastering_white_y" }, 0..) |field, i| @field(out, field) = value.chromaticities[i];
        out.mastering_maximum = value.maximum;
        out.mastering_minimum = value.minimum;
    }
    if (parsed.content_light) |value| {
        out.flags |= c.png_has_content_light;
        out.content_maximum = value[0];
        out.content_average = value[1];
    }
    return out;
}
pub fn info(encoded: [*]const u8, length: u64, output: *c.R4ImgPngColor) callconv(.c) i32 {
    if (length > metadata.max_encoded_bytes) return c.status_too_large;
    const bytes = encoded[0..@intCast(length)];
    if (overlap(bytes, std.mem.asBytes(output))) return c.status_invalid_argument;
    const parsed = metadata.png(bytes) catch |err| return status(err);
    output.* = convert(parsed);
    return c.status_ok;
}
pub fn profile(encoded: [*]const u8, length: u64, destination: [*]u8, capacity: u64, output_bytes: *u64) callconv(.c) i32 {
    if (length > metadata.max_encoded_bytes or capacity > std.math.maxInt(usize)) return c.status_too_large;
    const bytes = encoded[0..@intCast(length)];
    const output = destination[0..@intCast(@min(capacity, metadata.max_profile_bytes))];
    if (!separate(&.{ bytes, output, std.mem.asBytes(output_bytes) })) return c.status_invalid_argument;
    const parsed = metadata.png(bytes) catch |err| return status(err);
    const extracted = parsed.profile(output) catch |err| return status(err);
    output_bytes.* = extracted.len;
    return c.status_ok;
}
pub fn rasterInfo(encoded: [*]const u8, length: u64, output: *c.R4ImgRasterColor) callconv(.c) i32 {
    if (length > metadata.max_encoded_bytes) return c.status_too_large;
    const bytes = encoded[0..@intCast(length)];
    if (overlap(bytes, std.mem.asBytes(output))) return c.status_invalid_argument;
    const parsed = codec.raster_color.parse(bytes) catch |err| return status(err);
    var out = std.mem.zeroes(c.R4ImgRasterColor);
    out.version = 1;
    out.size = @sizeOf(c.R4ImgRasterColor);
    out.format = if (parsed.format == .jpeg) c.format_jpeg else c.format_bmp;
    out.kind = @intFromEnum(parsed.kind);
    out.color_model = @intFromEnum(parsed.model);
    out.intent = parsed.intent;
    out.profile_bytes = parsed.profile_bytes;
    inline for (.{ "red_x", "red_y", "red_z", "green_x", "green_y", "green_z", "blue_x", "blue_y", "blue_z" }, 0..) |field, i| @field(out, field) = parsed.endpoints[i];
    inline for (.{ "gamma_red", "gamma_green", "gamma_blue" }, 0..) |field, i| @field(out, field) = parsed.gamma[i];
    output.* = out;
    return c.status_ok;
}
pub fn rasterProfile(encoded: [*]const u8, length: u64, destination: [*]u8, capacity: u64, output_bytes: *u64) callconv(.c) i32 {
    if (length > metadata.max_encoded_bytes or capacity > std.math.maxInt(usize)) return c.status_too_large;
    const bytes = encoded[0..@intCast(length)];
    const output = destination[0..@intCast(@min(capacity, metadata.max_profile_bytes))];
    if (!separate(&.{ bytes, output, std.mem.asBytes(output_bytes) })) return c.status_invalid_argument;
    const parsed = codec.raster_color.parse(bytes) catch |err| return status(err);
    const extracted = parsed.profile(output) catch |err| return status(err);
    output_bytes.* = extracted.len;
    return c.status_ok;
}
pub fn scratchBytes(info_input: *const c.R4ImgInfo, length: u64, output_bytes: *u64) callconv(.c) i32 {
    if (length > metadata.max_encoded_bytes) return c.status_too_large;
    if (info_input.format != c.format_png or info_input.channels > 4 or info_input.channels == 0 or
        overlap(std.mem.asBytes(info_input), std.mem.asBytes(output_bytes))) return c.status_invalid_argument;
    const image: codec.Info = .{ .format = .png, .width = info_input.width, .height = info_input.height, .channels = @intCast(info_input.channels) };
    output_bytes.* = codec.pngScratchBytes16(image, @intCast(length)) catch |err| return status(err);
    return c.status_ok;
}
pub fn decode(encoded: [*]const u8, length: u64, channels: [*]u16, capacity: u64, scratch: [*]u8, scratch_length: u64, output_info: *c.R4ImgInfo, output_color: *c.R4ImgPngColor, output_pixel_count: *u64) callconv(.c) i32 {
    if (length > metadata.max_encoded_bytes or capacity > std.math.maxInt(usize) / 2 or scratch_length > codec.max_scratch_bytes) return c.status_too_large;
    const bytes = encoded[0..@intCast(length)];
    const pixels = channels[0..@intCast(capacity)];
    const arena = scratch[0..@intCast(scratch_length)];
    if (!separate(&.{ bytes, std.mem.sliceAsBytes(pixels), arena, std.mem.asBytes(output_info), std.mem.asBytes(output_color), std.mem.asBytes(output_pixel_count) })) return c.status_invalid_argument;
    const image = codec.pngDecode16(bytes, pixels, arena) catch |err| return status(err);
    output_info.* = .{ .format = c.format_png, .width = image.info.width, .height = image.info.height, .channels = image.info.channels };
    output_color.* = convert(image.metadata);
    output_pixel_count.* = image.rgba.len / 4;
    return c.status_ok;
}
