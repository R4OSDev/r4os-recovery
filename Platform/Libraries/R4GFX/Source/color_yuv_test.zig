//! Video anchors within the existing color owner check; no extra test suite.
const std = @import("std");
const t = std.testing;
const c = @import("r4l_contract");
const color = @import("color.zig");
const yuv = @import("color_yuv.zig");
fn near(expected: f32, actual: f32, tolerance: f32) !void { try t.expectApproxEqAbs(expected, actual, tolerance); }
fn rgb(expected: [3]f32, actual: [3]f32, tolerance: f32) !void { for (expected, actual) |e, a| try near(e, a, tolerance); }
pub fn check(api: *const c.ColorV1) !void {
    const video = try color.Encoding.init(.{ .transfer = .bt1886 });
    try rgb(@splat(18.94645708), video.decode(@splat(0.5), 1).rgb, 0.00002);
    try rgb(@splat(0), video.decode(@splat(-0.1), 1).rgb, 0);
    const black = try color.Encoding.init(.{ .transfer = .bt1886, .black = 0.1 });
    try rgb(@splat(0.1), black.decode(@splat(0), 1).rgb, 0.00001);
    try rgb(@splat(100), black.decode(@splat(1), 1).rgb, 0.00002);
    try rgb(.{ 0.13, 0.51, 0.97 }, black.encode(black.decode(.{ 0.13, 0.51, 0.97 }, 1)).rgb, 0.000002);
    for ([_]color.Primaries{ .bt601_525, .bt601_625 }) |primaries|
        try rgb(@splat(1), color.primariesMatrix(primaries, .bt2020).apply(@splat(1)), 0.000001);
    const program = try @import("color_gpu.zig").build(black.description, .{}, c.color_transform_output, false);
    try t.expectEqual(@as(u32, 6), program.words[1]);
    try near(0.0562341325, program.scalar(140), 0.000001);
    var metadata: yuv.Metadata = .{ .primaries = 1, .transfer = 1, .matrix = 1, .range = .limited, .chroma = .left };
    for ([_]yuv.Format{ .nv12, .p010, .yuv420p }) |format| {
        const matrix = try yuv.Matrix.init(metadata, format);
        const denominator: f32 = if (format == .p010) 1023 else 255;
        const scale: f32 = if (format == .p010) 4 else 1;
        try rgb(@splat(0), matrix.apply(.{ 16 * scale / denominator, 128 * scale / denominator, 128 * scale / denominator }), 0.000001);
        try rgb(@splat(1), matrix.apply(.{ 235 * scale / denominator, 128 * scale / denominator, 128 * scale / denominator }), 0.000001);
        // H.273 BT.709 red: Y'=Kr, Cb'=-Kr/(2*(1-Kb)), Cr'=0.5.
        try rgb(.{ 1, 0, 0 }, matrix.apply(.{ (16 + 219 * 0.2126) * scale / denominator,
            (128 - 224 * 0.2126 / (2 * 0.9278)) * scale / denominator, 240 * scale / denominator }), 0.000001);
    }
    metadata.range = .full;
    try rgb(@splat(0), (try yuv.Matrix.init(metadata, .p010)).apply(.{ 0, 512.0 / 1023.0, 512.0 / 1023.0 }), 0.000001);
    metadata.matrix = 10;
    try t.expectError(error.Unsupported, yuv.Matrix.init(metadata, .p010));
    metadata.matrix = 1; metadata.primaries = 2;
    try t.expectError(error.Unsupported, metadata.description(.p010));
    metadata.primaries = 1;
    try public(api);
}

fn public(api: *const c.ColorV1) !void {
    var luma: [24]u8 = @splat(0xcc);
    var chroma: [16]u8 = @splat(0xcc);
    var cb: [8]u8 = @splat(0xcc); var cr: [8]u8 = @splat(0xcc);
    var target: [64]u8 align(16) = @splat(0xa5);
    var from = std.mem.zeroes(c.R4GfxYuvImage);
    from.version = 1; from.size = @sizeOf(c.R4GfxYuvImage);
    from.width = 3; from.height = 3; from.crop = .{ .x = 1, .y = 1, .width = 1, .height = 1 };
    from.description = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvDescription), .primaries = 1, .transfer = 1, .matrix = 1,
        .range = 2, .chroma_location = 1, .flags = 0, .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 };
    var to = std.mem.zeroes(c.R4GfxColorImage);
    to.version = 1; to.size = @sizeOf(c.R4GfxColorImage);
    to.image = .{ .cpu_address = @intFromPtr(&target), .byte_length = target.len, .width = 2, .height = 2, .pitch = 32, .format = c.format_abgr16161616f, .reserved = 0 };
    to.description = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription), .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_linear,
        .range = c.color_range_full, .alpha = c.color_alpha_opaque, .precision = c.color_precision_float16, .reference_white = 1000000, .peak = 1000000, .black = 0, .flags = 0, .reserved = 0 };
    var request = std.mem.zeroes(c.R4GfxColorTransform);
    request.version = 1; request.size = @sizeOf(c.R4GfxColorTransform); request.operation = c.render_operation_blit;
    request.sampler = c.render_sampler_bilinear; request.source_rect = from.crop;
    request.target_rect = .{ .x = 0, .y = 0, .width = 2, .height = 2 }; request.opacity = 65535; request.pixel_budget = 4;
    var stats = std.mem.zeroes(c.R4GfxCpuStats);
    // Odd coded extents and crop, independent padding, 8/10-bit neutral codes.
    for ([_]u32{ c.yuv_format_nv12, c.yuv_format_p010, c.yuv_format_yuv420p }) |format| {
        from.format = format; from.plane_count = if (format == c.yuv_format_yuv420p) 3 else 2;
        const ten = format == c.yuv_format_p010;
        for (0..3) |y| for (0..3) |x| {
            if (ten) std.mem.writeInt(u16, luma[y * 8 + x * 2 ..][0..2], (502 << 6) | 63, .little)
            else luma[y * 8 + x] = 126;
        };
        for (0..2) |y| for (0..2) |x| {
            if (ten) {
                std.mem.writeInt(u16, chroma[y * 8 + x * 4 ..][0..2], (512 << 6) | 63, .little);
                std.mem.writeInt(u16, chroma[y * 8 + x * 4 + 2 ..][0..2], (512 << 6) | 63, .little);
            } else {
                chroma[y * 8 + x * 2] = 128; chroma[y * 8 + x * 2 + 1] = 128;
                cb[y * 4 + x] = 128; cr[y * 4 + x] = 128;
            }
        };
        from.plane0 = .{ .cpu_address = @intFromPtr(&luma), .byte_length = if (ten) 22 else 19, .pitch = 8, .reserved = 0 };
        from.plane1 = .{ .cpu_address = if (from.plane_count == 3) @intFromPtr(&cb) else @intFromPtr(&chroma), .byte_length = if (from.plane_count == 3) 6 else if (ten) 16 else 12,
            .pitch = if (from.plane_count == 3) 4 else 8, .reserved = 0 };
        from.plane2 = if (from.plane_count == 3) .{ .cpu_address = @intFromPtr(&cr), .byte_length = 6, .pitch = 4, .reserved = 0 } else std.mem.zeroes(c.R4GfxYuvPlane);
        @memset(&target, 0xa5);
        try t.expectEqual(c.status_ok, api.color_yuv_image_transform(&from, &to, &request, &stats));
        try t.expectEqual(@as(u64, 4), stats.pixels);
        for (0..2) |y| for (0..2) |x| {
            const value = @import("color_pixels.zig").load(.abgr16161616f, target[y * 32 + x * 8 ..].ptr);
            const expected: f32 = if (ten) 0.1894645708 else 0.19154788;
            try rgb(@splat(expected), value.rgb, 0.00015);
            try near(1, value.alpha, 0);
        };
        for (target[16..32]) |byte| try t.expectEqual(@as(u8, 0xa5), byte);
        for (target[48..64]) |byte| try t.expectEqual(@as(u8, 0xa5), byte);
    }
    const sentinel = target; const previous = stats;
    from.description.chroma_location = 0;
    try t.expectEqual(c.status_unsupported, api.color_yuv_image_transform(&from, &to, &request, &stats));
    try t.expectEqualSlices(u8, &sentinel, &target); try t.expectEqualDeep(previous, stats);
    from.description.chroma_location = 1; from.plane0.byte_length = 18;
    try t.expectEqual(c.status_invalid, api.color_yuv_image_transform(&from, &to, &request, &stats));
    try t.expectEqualSlices(u8, &sentinel, &target);
    from.plane0.byte_length = 19; from.plane1.cpu_address = @intFromPtr(&target);
    try t.expectEqual(c.status_alias, api.color_yuv_image_transform(&from, &to, &request, &stats));
    try t.expectEqualSlices(u8, &sentinel, &target); try t.expectEqualDeep(previous, stats);
    // The six standard phases at absolute luma(1,1), inside an odd crop.
    // Independent scalar filter anchors prevent accidentally recentering UV
    // at crop origin or exchanging planar/semi-planar Cb and Cr.
    from.format = c.yuv_format_nv12; from.plane_count = 2;
    from.plane1 = .{ .cpu_address = @intFromPtr(&chroma), .byte_length = 12, .pitch = 8, .reserved = 0 };
    from.plane2 = std.mem.zeroes(c.R4GfxYuvPlane);
    chroma[0] = 64; chroma[2] = 128; chroma[8] = 192; chroma[10] = 224;
    const cb_codes = [_]f32{ 124, 110, 152, 140, 96, 80 };
    for (cb_codes, 1..) |cb_code, location| {
        from.description.chroma_location = @intCast(location);
        try t.expectEqual(c.status_ok, api.color_yuv_image_transform(&from, &to, &request, &stats));
        const value = @import("color_pixels.zig").load(.abgr16161616f, &target);
        const y: f32 = 110.0 / 219.0; const u = (cb_code - 128) / 224;
        try rgb(.{ std.math.pow(f32, y, 2.4), std.math.pow(f32, y - 0.18732427293 * u, 2.4),
            std.math.pow(f32, y + 1.8556 * u, 2.4) }, value.rgb, 0.00035);
    }
    request.source_rect.x = 0;
    const cropped = target;
    try t.expectEqual(c.status_invalid, api.color_yuv_image_transform(&from, &to, &request, &stats));
    try t.expectEqualSlices(u8, &cropped, &target);
}
