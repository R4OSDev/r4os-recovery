const std = @import("std");
const r4os = @import("r4os");
const contract = @import("r4l_contract");

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}

const CDecoder = opaque {};
const CFace = opaque {};

const AllocFn = *const fn (?*anyopaque, usize, usize) callconv(.c) ?*anyopaque;
const ReallocFn = *const fn (?*anyopaque, ?*anyopaque, usize, usize, usize) callconv(.c) ?*anyopaque;
const FreeFn = *const fn (?*anyopaque, ?*anyopaque, usize, usize) callconv(.c) void;

const CAllocator = extern struct {
    user: ?*anyopaque,
    alloc: AllocFn,
    realloc: ReallocFn,
    free: FreeFn,
};

const CDiagnostics = extern struct {
    current_bytes: usize,
    peak_bytes: usize,
    allocation_count: usize,
    reallocation_count: usize,
    reallocation_failure_count: usize,
    allocation_limit: usize,
    allocation_failed: c_int,
};

const CFaceInfo = extern struct {
    face_count: u32,
    face_index: u32,
    glyph_count: u32,
    units_per_em: u32,
    ascender: i32,
    descender: i32,
    line_height: i32,
    max_advance: i32,
    style_flags: u32,
    family: ?[*:0]const u8,
    style: ?[*:0]const u8,
};

const CGlyphMetrics = extern struct {
    glyph_index: u32,
    advance_x: i32,
    advance_y: i32,
    bearing_x: i32,
    bearing_y: i32,
    width: i32,
    height: i32,
};

const CRaster = extern struct {
    glyph_index: u32,
    width: u32,
    height: u32,
    left: i32,
    top: i32,
    advance_x_26_6: i32,
    required_bytes: usize,
};

extern fn r4font_sniff(bytes: [*]const u8, length: usize) callconv(.c) c_int;
extern fn r4font_decoder_create(allocator: CAllocator, allocation_limit: usize, output: *?*CDecoder) callconv(.c) c_int;
extern fn r4font_decoder_destroy(decoder: ?*CDecoder) callconv(.c) void;
extern fn r4font_decoder_diagnostics(decoder: ?*const CDecoder) callconv(.c) CDiagnostics;
extern fn r4font_decoder_open_face(decoder: ?*CDecoder, bytes: [*]const u8, length: usize, face_index: u32, output: *?*CFace) callconv(.c) c_int;
extern fn r4font_close_face(face: ?*CFace) callconv(.c) void;
extern fn r4font_face_info(face: ?*CFace, output: *CFaceInfo) callconv(.c) c_int;
extern fn r4font_glyph_index(face: ?*CFace, codepoint: u32) callconv(.c) u32;
extern fn r4font_glyph_metrics(face: ?*CFace, glyph_index: u32, output: *CGlyphMetrics) callconv(.c) c_int;
extern fn r4font_kerning(face: ?*CFace, left_glyph: u32, right_glyph: u32, output_x: *i32, output_y: *i32) callconv(.c) c_int;
extern fn r4font_rasterize(face: ?*CFace, glyph_index: u32, pixel_height: u32, output: ?[*]u8, output_capacity: usize, output_raster: *CRaster) callconv(.c) c_int;

fn length(value: u64) ?usize {
    return std.math.cast(usize, value);
}

fn pointer(comptime T: type, address: u64) ?*T {
    if (address == 0) return null;
    return @ptrFromInt(std.math.cast(usize, address) orelse return null);
}

fn contextPointer(address: u64) ?*anyopaque {
    if (address == 0) return null;
    return @ptrFromInt(std.math.cast(usize, address) orelse return null);
}

fn functionPointer(comptime T: type, address: u64) ?T {
    if (address == 0) return null;
    return @ptrFromInt(std.math.cast(usize, address) orelse return null);
}

fn stringAddress(value: ?[*:0]const u8) u64 {
    return if (value) |text| @intFromPtr(text) else 0;
}

pub export fn r4font_sniff_impl(bytes: [*]const u8, bytes_length: u64, output_format: *u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    const byte_count = length(bytes_length) orelse return contract.status_invalid_argument;
    output_format.* = @intCast(r4font_sniff(bytes, byte_count));
    return contract.status_ok;
}

pub export fn r4font_decoder_create_impl(allocator: *const contract.R4FontAllocator, allocation_limit: u64, output_decoder: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    output_decoder.* = 0;
    const limit = length(allocation_limit) orelse return contract.status_too_large;
    if (limit == 0) return contract.status_invalid_argument;
    const native_allocator = CAllocator{
        .user = contextPointer(allocator.user),
        .alloc = functionPointer(AllocFn, allocator.alloc) orelse return contract.status_invalid_argument,
        .realloc = functionPointer(ReallocFn, allocator.realloc) orelse return contract.status_invalid_argument,
        .free = functionPointer(FreeFn, allocator.free) orelse return contract.status_invalid_argument,
    };
    var decoder: ?*CDecoder = null;
    const status = r4font_decoder_create(native_allocator, limit, &decoder);
    if (status != contract.status_ok) return status;
    output_decoder.* = if (decoder) |value| @intFromPtr(value) else return contract.status_decoder_failure;
    return contract.status_ok;
}

pub export fn r4font_decoder_destroy_impl(decoder: u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CDecoder, decoder) orelse return contract.status_invalid_argument;
    r4font_decoder_destroy(value);
    return contract.status_ok;
}

pub export fn r4font_decoder_diagnostics_impl(decoder: u64, output: *contract.R4FontDiagnostics) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CDecoder, decoder) orelse return contract.status_invalid_argument;
    const diagnostic = r4font_decoder_diagnostics(value);
    output.* = .{
        .current_bytes = diagnostic.current_bytes,
        .peak_bytes = diagnostic.peak_bytes,
        .allocation_count = diagnostic.allocation_count,
        .reallocation_count = diagnostic.reallocation_count,
        .reallocation_failure_count = diagnostic.reallocation_failure_count,
        .allocation_limit = diagnostic.allocation_limit,
        .allocation_failed = @intFromBool(diagnostic.allocation_failed != 0),
        .reserved = 0,
    };
    return contract.status_ok;
}

pub export fn r4font_decoder_open_face_impl(decoder: u64, bytes: [*]const u8, bytes_length: u64, face_index: u32, output_face: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    output_face.* = 0;
    const value = pointer(CDecoder, decoder) orelse return contract.status_invalid_argument;
    const byte_count = length(bytes_length) orelse return contract.status_too_large;
    var face: ?*CFace = null;
    const status = r4font_decoder_open_face(value, bytes, byte_count, face_index, &face);
    if (status != contract.status_ok) return status;
    output_face.* = if (face) |opened| @intFromPtr(opened) else return contract.status_decoder_failure;
    return contract.status_ok;
}

pub export fn r4font_face_close_impl(face: u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CFace, face) orelse return contract.status_invalid_argument;
    r4font_close_face(value);
    return contract.status_ok;
}

pub export fn r4font_face_info_impl(face: u64, output: *contract.R4FontFaceInfo) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CFace, face) orelse return contract.status_invalid_argument;
    var info: CFaceInfo = undefined;
    const status = r4font_face_info(value, &info);
    if (status != contract.status_ok) return status;
    output.* = .{
        .face_count = info.face_count,
        .face_index = info.face_index,
        .glyph_count = info.glyph_count,
        .units_per_em = info.units_per_em,
        .ascender = info.ascender,
        .descender = info.descender,
        .line_height = info.line_height,
        .max_advance = info.max_advance,
        .style_flags = info.style_flags,
        .reserved = 0,
        .family_address = stringAddress(info.family),
        .style_address = stringAddress(info.style),
    };
    return contract.status_ok;
}

pub export fn r4font_glyph_index_impl(face: u64, codepoint: u32, output_glyph: *u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CFace, face) orelse return contract.status_invalid_argument;
    output_glyph.* = r4font_glyph_index(value, codepoint);
    return contract.status_ok;
}

pub export fn r4font_glyph_metrics_impl(face: u64, glyph_index: u32, output: *contract.R4FontGlyphMetrics) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CFace, face) orelse return contract.status_invalid_argument;
    var metrics: CGlyphMetrics = undefined;
    const status = r4font_glyph_metrics(value, glyph_index, &metrics);
    if (status != contract.status_ok) return status;
    output.* = .{
        .glyph_index = metrics.glyph_index,
        .advance_x = metrics.advance_x,
        .advance_y = metrics.advance_y,
        .bearing_x = metrics.bearing_x,
        .bearing_y = metrics.bearing_y,
        .width = metrics.width,
        .height = metrics.height,
    };
    return contract.status_ok;
}

pub export fn r4font_kerning_impl(face: u64, left_glyph: u32, right_glyph: u32, output: *contract.R4FontKerning) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CFace, face) orelse return contract.status_invalid_argument;
    var x: i32 = 0;
    var y: i32 = 0;
    const status = r4font_kerning(value, left_glyph, right_glyph, &x, &y);
    if (status != contract.status_ok) return status;
    output.* = .{ .x = x, .y = y };
    return contract.status_ok;
}

pub export fn r4font_rasterize_impl(face: u64, glyph_index: u32, pixel_height: u32, output: ?[*]u8, output_capacity: u64, output_raster: *contract.R4FontRaster) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = pointer(CFace, face) orelse return contract.status_invalid_argument;
    const capacity = length(output_capacity) orelse return contract.status_too_large;
    var raster = std.mem.zeroes(CRaster);
    const status = r4font_rasterize(value, glyph_index, pixel_height, output, capacity, &raster);
    output_raster.* = .{
        .glyph_index = raster.glyph_index,
        .width = raster.width,
        .height = raster.height,
        .left = raster.left,
        .top = raster.top,
        .advance_x_26_6 = raster.advance_x_26_6,
        .required_bytes = raster.required_bytes,
    };
    return status;
}

pub export var r4font_api_v1: contract.ApiV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.api_v1_header,
    .sniff = r4font_sniff_impl,
    .decoder_create = r4font_decoder_create_impl,
    .decoder_destroy = r4font_decoder_destroy_impl,
    .decoder_diagnostics = r4font_decoder_diagnostics_impl,
    .decoder_open_face = r4font_decoder_open_face_impl,
    .face_close = r4font_face_close_impl,
    .face_info = r4font_face_info_impl,
    .glyph_index = r4font_glyph_index_impl,
    .glyph_metrics = r4font_glyph_metrics_impl,
    .kerning = r4font_kerning_impl,
    .rasterize = r4font_rasterize_impl,
};

pub export var r4font_query: r4os.abi.R4LQuery align(8) linksection(".data.r4l_exports") = .{
    .magic = r4os.abi.r4l_abi_magic,
    .abi_version = r4os.abi.r4l_abi_version,
    .size = r4os.abi.r4l_query_struct_size,
    .group = 0,
    .kernel_bridge = 0,
    .reserved = 0,
};

test "R4FONT implementation preserves every fixed V1 layout" {
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(contract.R4FontAllocator));
    try std.testing.expectEqual(@as(usize, 56), @sizeOf(contract.R4FontDiagnostics));
    try std.testing.expectEqual(@as(usize, 56), @sizeOf(contract.R4FontFaceInfo));
    try std.testing.expectEqual(@as(usize, 28), @sizeOf(contract.R4FontGlyphMetrics));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(contract.R4FontKerning));
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(contract.R4FontRaster));
    try std.testing.expectEqual(@as(usize, 120), @sizeOf(contract.ApiV1));
}

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4font_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
