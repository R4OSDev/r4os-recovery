//! Image loading policy over the two runtime owners. R4IMG retains source
//! samples and metadata; R4GFX performs all transfer, ICC and gamut arithmetic.
//! No CMM, pixel conversion or profile math is duplicated in this facade.
const std = @import("std");
const img = @import("r4img.zig");
const a = img.abi;
pub fn Decoder(comptime gfx: type) type {
    return struct {
        pub const Policy = struct {
            untagged_srgb: bool = false,
            missing_chromaticities_srgb: bool = false,
            missing_gamma_srgb: bool = false,
            sdr_white: u32 = 1000000,
            hdr_white: u32 = 2030000,
            pq_peak: u32 = 100000000,
            hlg_peak: u32 = 10000000,
        };
        pub const Characterization = struct {
            description: gfx.R4GfxColorDescription,
            definition: ?gfx.R4GfxColorProfileDefinition = null,
            embedded_profile: bool = false,
            assumed: bool = false,
            intent: u32 = 1,
        };
        pub const Result = struct { info: img.Info, metadata: img.PngColor, assumed: bool };
        pub const RasterResult = struct { info: img.Info, metadata: img.RasterColor, assumed: bool };
        const Error = error{ UnsupportedColor, InvalidColor, ColorTransform, ProfileLimit };
        fn accepted(status: i32) Error!void {
            if (status != gfx.status_ok) return error.ColorTransform;
        }
        pub fn characterize(meta: img.PngColor, policy: Policy) Error!Characterization {
            if (meta.version != 1 or meta.size != @sizeOf(img.PngColor) or meta.flags & ~@as(u32, 127) != 0 or
                (meta.bit_depth != 1 and meta.bit_depth != 2 and meta.bit_depth != 4 and meta.bit_depth != 8 and meta.bit_depth != 16)) return error.InvalidColor;
            var result: Characterization = .{ .description = .{
                .version = 1,
                .size = @sizeOf(gfx.R4GfxColorDescription),
                .primaries = gfx.color_primaries_srgb,
                .transfer = gfx.color_transfer_srgb,
                .range = gfx.color_range_full,
                .alpha = gfx.color_alpha_straight,
                .precision = gfx.color_precision_unorm16,
                .flags = 0,
                .reference_white = policy.sdr_white,
                .peak = policy.sdr_white,
                .black = 0,
                .reserved = 0,
            } };
            switch (meta.kind) {
                a.png_color_unspecified => {
                    if (!policy.untagged_srgb) return error.UnsupportedColor;
                    result.assumed = true;
                },
                a.png_color_unknown => return error.UnsupportedColor,
                a.png_color_srgb => {
                    if (meta.flags & a.png_has_srgb == 0 or meta.intent > 3) return error.InvalidColor;
                    result.intent = meta.intent;
                },
                a.png_color_cicp => {
                    if (meta.flags & a.png_has_cicp == 0 or meta.cicp_matrix != 0 or meta.cicp_full_range > 1) return error.InvalidColor;
                    result.description.primaries = switch (meta.cicp_primaries) {
                        1 => gfx.color_primaries_srgb,
                        9 => gfx.color_primaries_bt2020,
                        12 => gfx.color_primaries_display_p3,
                        else => return error.UnsupportedColor,
                    };
                    result.description.transfer = switch (meta.cicp_transfer) {
                        8 => gfx.color_transfer_linear,
                        13 => gfx.color_transfer_srgb,
                        16 => gfx.color_transfer_pq,
                        18 => gfx.color_transfer_hlg,
                        else => return error.UnsupportedColor,
                    };
                    if (meta.cicp_full_range == 0) {
                        // PNG8 -> RGBA16 expands by257. Its normalized code16
                        // black is still16/255, not4096/65535.
                        if (meta.bit_depth != 8 and meta.bit_depth != 16) return error.UnsupportedColor;
                        result.description.range = if (meta.bit_depth == 8) gfx.color_range_limited8 else gfx.color_range_limited16;
                    }
                    if (meta.cicp_transfer == 16 or meta.cicp_transfer == 18) {
                        result.description.reference_white = policy.hdr_white;
                        result.description.peak = if (meta.cicp_transfer == 16) policy.pq_peak else policy.hlg_peak;
                    }
                },
                a.png_color_icc => {
                    if (meta.flags & a.png_has_icc == 0) return error.InvalidColor;
                    result.embedded_profile = true;
                    result.description.primaries = gfx.color_primaries_icc;
                    result.description.transfer = gfx.color_transfer_icc;
                },
                a.png_color_gamma_chroma => {
                    const chroma = meta.flags & a.png_has_chroma != 0;
                    const gamma = meta.flags & a.png_has_gamma != 0;
                    if ((!chroma and !policy.missing_chromaticities_srgb) or (!gamma and !policy.missing_gamma_srgb)) return error.UnsupportedColor;
                    if ((!chroma and !gamma) or (gamma and meta.gamma == 0)) return error.InvalidColor;
                    // PNG stores the encoding exponent; ICC construction wants
                    // its reciprocal decoding exponent, in the same fixed units.
                    const exponent: u64 = if (gamma) @divFloor(@as(u64, 10000000000) + meta.gamma / 2, meta.gamma) else 100000;
                    if (exponent < 1000 or exponent > 10000000) return error.UnsupportedColor;
                    result.definition = .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorProfileDefinition), .color_model = if (meta.color_type == 0 or meta.color_type == 4) gfx.color_model_gray else gfx.color_model_rgb, .curve = if (gamma) gfx.color_curve_power else gfx.color_curve_srgb, .white_x = if (chroma) meta.white_x else 31270, .white_y = if (chroma) meta.white_y else 32900, .red_x = if (chroma) meta.red_x else 64000, .red_y = if (chroma) meta.red_y else 33000, .green_x = if (chroma) meta.green_x else 30000, .green_y = if (chroma) meta.green_y else 60000, .blue_x = if (chroma) meta.blue_x else 15000, .blue_y = if (chroma) meta.blue_y else 6000, .gamma_red = @intCast(exponent), .gamma_green = @intCast(exponent), .gamma_blue = @intCast(exponent), .reserved = 0 };
                    result.assumed = !chroma or !gamma;
                    result.description.primaries = gfx.color_primaries_icc;
                    result.description.transfer = gfx.color_transfer_icc;
                },
                else => return error.UnsupportedColor,
            }
            return result;
        }
        fn chromaticity(values: [3]i64) Error![2]u32 {
            for (values) |value| if (value < 0) return error.UnsupportedColor;
            const sum = values[0] + values[1] + values[2];
            if (sum <= 0 or values[1] == 0) return error.InvalidColor;
            return .{ @intCast(@divTrunc(values[0] * 100000 + @divTrunc(sum, 2), sum)), @intCast(@divTrunc(values[1] * 100000 + @divTrunc(sum, 2), sum)) };
        }
        fn gammaExponent(value: u32) Error!u32 {
            const result = (@as(u64, value) * 100000 + 32768) / 65536;
            if (result < 1000 or result > 10000000) return error.UnsupportedColor;
            return @intCast(result);
        }
        pub fn characterizeRaster(meta: img.RasterColor, policy: Policy) Error!Characterization {
            if (meta.version != 1 or meta.size != @sizeOf(img.RasterColor) or meta.flags != 0 or meta.reserved != 0 or meta.reserved1 != 0 or
                (meta.format != a.format_jpeg and meta.format != a.format_bmp) or meta.intent > 3 or meta.profile_bytes > a.max_color_profile_bytes) return error.InvalidColor;
            // Legacy JPEG decoding converts CMYK/YCCK to RGB before the caller
            // can see its samples; applying the original CMYK ICC afterwards
            // would be incorrect. This color path rejects that source model.
            if (meta.color_model != a.raster_model_rgb and meta.color_model != a.raster_model_gray) return error.UnsupportedColor;
            var result: Characterization = .{ .intent = meta.intent, .description = .{
                .version = 1,
                .size = @sizeOf(gfx.R4GfxColorDescription),
                .primaries = gfx.color_primaries_srgb,
                .transfer = gfx.color_transfer_srgb,
                .range = gfx.color_range_full,
                .alpha = gfx.color_alpha_straight,
                .precision = gfx.color_precision_unorm8,
                .flags = 0,
                .reference_white = policy.sdr_white,
                .peak = policy.sdr_white,
                .black = 0,
                .reserved = 0,
            } };
            switch (meta.kind) {
                a.raster_color_unspecified => {
                    if (!policy.untagged_srgb) return error.UnsupportedColor;
                    result.assumed = true;
                },
                a.raster_color_srgb => {},
                a.raster_color_icc => {
                    if (meta.profile_bytes < 132) return error.InvalidColor;
                    result.embedded_profile = true;
                    result.description.primaries = gfx.color_primaries_icc;
                    result.description.transfer = gfx.color_transfer_icc;
                },
                a.raster_color_calibrated => {
                    if (meta.format != a.format_bmp or meta.color_model != a.raster_model_rgb) return error.InvalidColor;
                    const red = try chromaticity(.{ meta.red_x, meta.red_y, meta.red_z });
                    const green = try chromaticity(.{ meta.green_x, meta.green_y, meta.green_z });
                    const blue = try chromaticity(.{ meta.blue_x, meta.blue_y, meta.blue_z });
                    const white = try chromaticity(.{ @as(i64, meta.red_x) + meta.green_x + meta.blue_x, @as(i64, meta.red_y) + meta.green_y + meta.blue_y, @as(i64, meta.red_z) + meta.green_z + meta.blue_z });
                    result.definition = .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorProfileDefinition), .color_model = gfx.color_model_rgb, .curve = gfx.color_curve_power, .white_x = white[0], .white_y = white[1], .red_x = red[0], .red_y = red[1], .green_x = green[0], .green_y = green[1], .blue_x = blue[0], .blue_y = blue[1], .gamma_red = try gammaExponent(meta.gamma_red), .gamma_green = try gammaExponent(meta.gamma_green), .gamma_blue = try gammaExponent(meta.gamma_blue), .reserved = 0 };
                    result.description.primaries = gfx.color_primaries_icc;
                    result.description.transfer = gfx.color_transfer_icc;
                },
                else => return error.UnsupportedColor,
            }
            return result;
        }
        /// Decode/convert one complete PNG into an explicit caller output image.
        /// The caller discards output on any error. Temporary storage is released
        /// once conversion has completed; the returned metadata has no pointers.
        pub fn decode(allocator: std.mem.Allocator, images: *const img.Context, png: *const img.PngContext, colors: *const gfx.ColorV1Client, bytes: []const u8, target: *const gfx.R4GfxColorImage, request: *const gfx.R4GfxColorTransform, policy: Policy) !Result {
            const info = try images.probe(bytes, "image/png");
            const metadata = try png.pngColor(bytes);
            const source_color = try characterize(metadata, policy);
            try accepted(colors.color_description_validate(&source_color.description));
            const count = try info.pixelCount();
            const channels = try allocator.alloc(u16, count * 4);
            defer allocator.free(channels);
            const scratch = try allocator.alloc(u8, try png.pngScratchBytes16(info, bytes.len));
            defer allocator.free(scratch);
            _ = try png.pngDecode16(bytes, channels, scratch);
            var source: gfx.R4GfxColorImage = .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorImage), .image = .{ .cpu_address = @intFromPtr(channels.ptr), .byte_length = channels.len * 2, .pitch = @as(u64, info.width) * 8, .width = info.width, .height = info.height, .format = gfx.format_abgr16161616, .reserved = 0 }, .description = source_color.description, .profile = std.mem.zeroes(gfx.R4GfxColorProfile) };
            try transform(false, allocator, png, colors, bytes, source_color, &source, target, request);
            return .{ .info = info, .metadata = metadata, .assumed = source_color.assumed };
        }
        /// JPEG/BMP use the existing ARGB8 decoder with explicit retained source
        /// characterization. This does not claim higher precision for BMP masks.
        pub fn decodeRaster(allocator: std.mem.Allocator, images: *const img.Context, raster: *const img.RasterContext, colors: *const gfx.ColorV1Client, bytes: []const u8, target: *const gfx.R4GfxColorImage, request: *const gfx.R4GfxColorTransform, policy: Policy) !RasterResult {
            const info = try images.probe(bytes, "");
            if (info.format != .jpeg and info.format != .bmp) return error.UnsupportedColor;
            const metadata = try raster.color(bytes);
            if (metadata.format != (if (info.format == .jpeg) a.format_jpeg else a.format_bmp)) return error.InvalidColor;
            const source_color = try characterizeRaster(metadata, policy);
            try accepted(colors.color_description_validate(&source_color.description));
            const pixels = try allocator.alloc(u32, try info.pixelCount());
            defer allocator.free(pixels);
            const scratch = try allocator.alloc(u8, try images.scratchBytesFor(info, bytes.len));
            defer allocator.free(scratch);
            const decoded = try images.decode(bytes, "", pixels, scratch);
            if (decoded.info.width != info.width or decoded.info.height != info.height or decoded.info.format != info.format or decoded.pixels.len != pixels.len) return error.InvalidColor;
            var source: gfx.R4GfxColorImage = .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorImage), .image = .{ .cpu_address = @intFromPtr(pixels.ptr), .byte_length = pixels.len * 4, .pitch = @as(u64, info.width) * 4, .width = info.width, .height = info.height, .format = gfx.format_argb8888, .reserved = 0 }, .description = source_color.description, .profile = std.mem.zeroes(gfx.R4GfxColorProfile) };
            try transform(true, allocator, raster, colors, bytes, source_color, &source, target, request);
            return .{ .info = info, .metadata = metadata, .assumed = source_color.assumed };
        }
        fn transform(comptime is_raster: bool, allocator: std.mem.Allocator, metadata_context: anytype, colors: *const gfx.ColorV1Client, bytes: []const u8, source_color: Characterization, source: *gfx.R4GfxColorImage, target: *const gfx.R4GfxColorImage, request: *const gfx.R4GfxColorTransform) !void {
            var profile_storage: ?[]align(16) u8 = null;
            defer if (profile_storage) |storage| allocator.free(storage);
            defer if (source.profile.address != 0) {
                _ = colors.color_profile_close(&source.profile);
            };
            if (source_color.embedded_profile or source_color.definition != null) {
                const size = colors.color_profile_storage_size();
                if (size < 1024 or size > 64 * 1024 * 1024) return error.ProfileLimit;
                profile_storage = try allocator.alignedAlloc(u8, .@"16", @intCast(size));
                @memset(profile_storage.?, 0);
                const profile_bytes = try allocator.alloc(u8, if (source_color.embedded_profile) a.max_color_profile_bytes else 4096);
                defer allocator.free(profile_bytes);
                var profile: []u8 = undefined;
                if (source_color.embedded_profile) profile = if (is_raster) try metadata_context.iccProfile(bytes, profile_bytes) else try metadata_context.pngIccProfile(bytes, profile_bytes) else {
                    var length: u64 = 0;
                    try accepted(colors.color_profile_generate(&source_color.definition.?, @intFromPtr(profile_storage.?.ptr), profile_storage.?.len, @intFromPtr(profile_bytes.ptr), profile_bytes.len, &length));
                    if (length > profile_bytes.len) return error.ProfileLimit;
                    profile = profile_bytes[0..@intCast(length)];
                    // Generation uses temporary scratch; open starts a fresh
                    // retained profile owner, with a zero header.
                    @memset(profile_storage.?[0..16], 0);
                }
                try accepted(colors.color_profile_open(&.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorProfileConfig), .storage_address = @intFromPtr(profile_storage.?.ptr), .storage_bytes = profile_storage.?.len, .profile_address = @intFromPtr(profile.ptr), .profile_bytes = profile.len, .direction = gfx.color_profile_input, .intent = source_color.intent, .flags = 0, .reserved = 0 }, &source.profile));
            }
            var stats: gfx.R4GfxCpuStats = undefined;
            try accepted(colors.color_image_transform(source, target, request, &stats));
        }
    };
}
