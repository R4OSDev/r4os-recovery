//! Numerical anchors and invariants inside the existing R4GFX owner test.
const std = @import("std");
const t = std.testing;
const color = @import("color.zig");
const c = @import("r4l_contract");
fn near(expected: f32, actual: f32, tolerance: f32) !void {
    try t.expectApproxEqAbs(expected, actual, tolerance);
}
fn rgbNear(expected: color.Rgb, actual: color.Rgb, tolerance: f32) !void {
    for (expected, actual) |e, a| try near(e, a, tolerance);
}
pub fn check(api: *const c.ColorV1) !void {
    try @import("color_yuv_test.zig").check(api);
    try checkGenerated(api);
    try checkIcc();
    try checkApi(api);
    try checkPixels();
    try checkLookup();
    try checkImages(api);
    try checkSmallBatches(api);
    try checkGpu();
    try near(0, color.srgbDecode(0), 1e-8);
    try near(1, color.srgbDecode(1), 1e-7);
    try near(0.00313080495, color.srgbDecode(0.04045), 1e-8);
    try near(0.21404114048, color.srgbDecode(0.5), 1e-7);
    try near(0.73535698305, color.srgbEncode(0.5), 1e-7);
    try near(-0.21404114048, color.srgbDecode(-0.5), 1e-7);
    try near(92.24570899, color.pqDecode(0.5), 0.0001);
    try near(0.50807842152, color.pqEncode(100), 1e-7);
    try near(0.75182709625, color.pqEncode(1000), 1e-7);
    try near(10000, color.pqDecode(1), 0.001);
    try near(0, color.pqDecode(0), 1e-8);
    try near(1.0 / 12.0, color.hlgSceneDecode(0.5), 1e-8);
    try near(1.2, color.hlgGamma(1000), 1e-7);
    // The primary matrices preserve D65 white and the BT.709 luma of red.
    const matrix = color.primariesMatrix(.srgb, .bt2020);
    try rgbNear(.{ 1, 1, 1 }, matrix.apply(.{ 1, 1, 1 }), 1e-6);
    const red = matrix.apply(.{ 1, 0, 0 });
    try near(0.627404, red[0], 0.000002);
    try near(0.0690973, red[1], 0.000002);
    try near(0.0163914, red[2], 0.000002);
    const inverse = try matrix.inverse();
    try rgbNear(.{ 1, 0, 0 }, inverse.apply(red), 1e-6);
    try t.expectError(error.Singular, (color.Matrix{ .rows = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } } }).inverse());

    var source = color.Description{ .alpha = .electrical };
    var target = color.Description{};
    const encoded = try color.Encoding.init(source);
    const solid = try color.Encoding.init(target);
    const half_white = encoded.decode(.{ 0.5, 0.5, 0.5 }, 0.5);
    try rgbNear(.{ 50, 50, 50 }, half_white.rgb, 0.00002);
    const blended = color.over(half_white, solid.decode(.{ 0, 0, 0 }, 1), 1);
    try near(1, blended.alpha, 1e-7);
    try rgbNear(.{ 0.735357, 0.735357, 0.735357 }, solid.encode(blended).rgb, 1e-6);
    // Straight and both premultiplication domains represent the same light.
    source.alpha = .straight;
    const straight = try color.Encoding.init(source);
    try rgbNear(half_white.rgb, straight.decode(.{ 1, 1, 1 }, 0.5).rgb, 0.00002);
    source.alpha = .optical;
    const optical = try color.Encoding.init(source);
    try rgbNear(half_white.rgb, optical.decode(.{ 0.73535698, 0.73535698, 0.73535698 }, 0.5).rgb, 0.00002);
    try rgbNear(.{ 0, 0, 0 }, optical.decode(.{ 1, 1, 1 }, 0).rgb, 0);
    try near(0.5, encoded.encode(half_white).alpha, 1e-7);
    try rgbNear(.{ 0.5, 0.5, 0.5 }, encoded.encode(half_white).rgb, 1e-6);

    // RGB code ranges: 16..235 at8 bits, 64..940 at10; alpha stays full range.
    source = .{ .range = .limited };
    try rgbNear(.{ 0, 1, 0.5 }, color.unpackRange(source, .{ 16.0 / 255.0, 235.0 / 255.0, 125.5 / 255.0 }), 1e-6);
    source.precision = .unorm10;
    try rgbNear(.{ 64.0 / 1023.0, 940.0 / 1023.0, 502.0 / 1023.0 }, color.packRange(source, .{ 0, 1, 0.5 }), 1e-6);
    source = .{ .primaries = .bt2020, .transfer = .pq, .precision = .unorm10, .reference_white = 203, .peak = 1000 };
    const pq = try color.Encoding.init(source);
    try rgbNear(.{ 1000, 1000, 1000 }, pq.decode(.{ 0.75182709625, 0.75182709625, 0.75182709625 }, 1).rgb, 0.001);
    source.transfer = .hlg;
    const hlg = try color.Encoding.init(source);
    try rgbNear(.{ 1000, 1000, 1000 }, hlg.decode(.{ 1, 1, 1 }, 1).rgb, 0.001);
    try near(203.15215, hlg.decode(.{ 0.75, 0.75, 0.75 }, 1).rgb[0], 0.001);
    // HLG OOTF uses joint luminance, not a separate gamma per channel.
    const hlg_red = hlg.decode(.{ 0.75, 0, 0 }, 1);
    try near(0, hlg_red.rgb[1], 1e-6);
    try t.expect(hlg_red.rgb[0] < 203.15 and hlg_red.rgb[0] > 150);
    try rgbNear(.{ 0.75, 0, 0 }, hlg.encode(hlg_red).rgb, 1e-6);
    source.black = 0.005;
    const black_hlg = try color.Encoding.init(source);
    try rgbNear(.{ 0.005, 0.005, 0.005 }, black_hlg.decode(.{ 0, 0, 0 }, 1).rgb, 1e-6);
    try rgbNear(.{ 0.31, 0.51, 0.91 }, black_hlg.encode(black_hlg.decode(.{ 0.31, 0.51, 0.91 }, 1)).rgb, 1e-6);
    source = .{ .primaries = .bt2020, .transfer = .pq, .precision = .unorm10, .reference_white = 203, .peak = 1000 };
    const tone = try color.ToneMap.init(source, target, true);
    var previous: f32 = -1;
    for (0..1001) |i| {
        const v: f32 = @floatFromInt(i);
        const mapped = tone.apply(.{ .rgb = @splat(v), .alpha = 1 });
        try t.expect(mapped.rgb[0] >= previous and mapped.rgb[0] <= 100.00001);
        previous = mapped.rgb[0];
    }
    try near(100, previous, 1e-5);
    try near(100.0 / 203.0 * 100.0, tone.apply(.{ .rgb = @splat(100), .alpha = 1 }).rgb[0], 1e-5);
    try rgbNear(.{ 0, 0, 0 }, tone.apply(.{ .rgb = @splat(1000), .alpha = 0 }).rgb, 0);
    // SDR reference white scales to the selected203 cd/m2 HDR desktop white.
    const up = try color.ToneMap.init(target, source, true);
    try rgbNear(.{ 203, 203, 203 }, up.apply(.{ .rgb = @splat(100), .alpha = 1 }).rgb, 0.00002);
    // Neutral-axis compression preserves output luminance and bounds channels.
    const out_of_gamut = color.Rgb{ -20, 100, 140 };
    const y = color.luminance(out_of_gamut);
    const mapped = color.gamutMap(out_of_gamut, y, 100);
    for (mapped) |v| try t.expect(v >= -1e-5 and v <= 100.00001);
    try near(y, color.luminance(mapped), 0.00002);

    target.precision = .float16;
    try t.expectError(error.Unsupported, color.Encoding.init(target));
    target.transfer = .linear;
    const linear = try color.Encoding.init(target);
    try rgbNear(.{ -0.25, 2, 1.5 }, linear.encode(linear.decode(.{ -0.25, 2, 1.5 }, 1)).rgb, 1e-6);
    target.range = .limited;
    try t.expectError(error.Unsupported, color.Encoding.init(target));
    source.precision = .unorm8;
    try t.expectError(error.Unsupported, color.Encoding.init(source));
    source.reference_white = std.math.nan(f32);
    try t.expectError(error.Invalid, color.Encoding.init(source));
}

fn checkGpu() !void {
    const gpu = @import("color_gpu.zig");
    const srgb: color.Description = .{};
    const pq: color.Description = .{ .primaries = .bt2020, .transfer = .pq,
        .precision = .unorm10, .range = .limited, .reference_white = 203, .peak = 1000 };
    const program = try gpu.build(srgb, pq, c.color_transform_output | c.color_transform_relative_white | c.color_transform_dither, false);
    try t.expectEqual(@as(usize, 256), @sizeOf(gpu.Program));
    try t.expectEqualSlices(u32, &.{3,1,3,1,1,0,0,0}, program.words[0..8]);
    try near(0.627404, program.scalar(32), 0.000002);
    try near(0.0690973, program.scalar(48), 0.000002);
    try near(0.0163914, program.scalar(64), 0.000002);
    try near(2.03, program.scalar(176), 0.000001);
    try near(203, program.scalar(180), 0.00002);
    try near(0, program.scalar(188), 0);
    try near(876.0 / 1023.0, program.scalar(168), 0.000001);
    try near(64.0 / 1023.0, program.scalar(172), 0.000001);
    try near(1.0 / 1023.0, program.scalar(196), 1e-9);
    for (program.words[50..]) |word| try t.expectEqual(@as(u32, 0), word);
    const capture = try gpu.build(pq, srgb, c.color_transform_output, false);
    try near(1, capture.scalar(176), 0);
    try near(75, capture.scalar(184), 0);
    try near(900.0 / (25.0 * 925.0), capture.scalar(188), 1e-8);
    try t.expectError(error.Unsupported, gpu.build(srgb, pq, 0, true));
    const linear: color.Description = .{ .primaries = .bt2020, .transfer = .linear, .alpha = .optical,
        .precision = .float16, .reference_white = 203, .peak = 1000 };
    _ = try gpu.build(srgb, linear, c.color_transform_relative_white, true);
    try t.expectError(error.Unsupported, gpu.build(srgb, linear, c.color_transform_dither, true));
    var invalid = linear; invalid.peak = std.math.nan(f32);
    try t.expectError(error.Invalid, gpu.build(srgb, invalid, 0, false));
    var hlg = pq; hlg.transfer = .hlg; hlg.black = 0.005;
    const hybrid = try gpu.build(linear, hlg, c.color_transform_output, false);
    try near(1.2, hybrid.scalar(152), 1e-6);
    try t.expect(hybrid.scalar(156) > 0 and hybrid.scalar(156) < 0.03);
}
fn checkGenerated(api: *const c.ColorV1) !void {
    const icc = @import("color_icc.zig");
    const memory = try t.allocator.alignedAlloc(u8, .@"16", 2 * 1024 * 1024);
    defer t.allocator.free(memory);
    var bytes: [4096]u8 = undefined;
    var definition: c.R4GfxColorProfileDefinition = .{ .version = 1, .size = @sizeOf(c.R4GfxColorProfileDefinition), .color_model = c.color_model_rgb, .curve = c.color_curve_power, .white_x = 31270, .white_y = 32900, .red_x = 64000, .red_y = 33000, .green_x = 30000, .green_y = 60000, .blue_x = 15000, .blue_y = 6000, .gamma_red = 220000, .gamma_green = 220000, .gamma_blue = 220000, .reserved = 0 };
    for ([_]u32{ c.color_model_rgb, c.color_model_gray }) |model| {
        definition.color_model = model;
        var count: u64 = 0;
        try t.expectEqual(c.status_ok, api.color_profile_generate(&definition, @intFromPtr(memory.ptr), memory.len, @intFromPtr(&bytes), bytes.len, &count));
        try t.expect(count >= 132 and count <= bytes.len);
        try t.expectEqualSlices(u8, if (model == c.color_model_rgb) "RGB " else "GRAY", bytes[16..20]);
        var arena = try icc.Arena.init(memory);
        var profile = try icc.Profile.open(&arena, bytes[0..count], .input, .relative, false, false);
        defer profile.close();
        var xyz: [1][3]f32 = .{@splat(42)};
        if (model == c.color_model_gray) {
            try t.expectError(error.Invalid, profile.apply(&.{.{ 0.5, 0.4, 0.5 }}, &xyz));
            try rgbNear(@splat(42), xyz[0], 0);
        }
        try profile.apply(&.{@splat(0.5)}, &xyz);
        try near(0.21763764, xyz[0][1], 0.0001);
    }
    definition.color_model = c.color_model_rgb;
    definition.red_x = definition.green_x;
    definition.red_y = definition.green_y;
    @memset(&bytes, 0xa5);
    var count: u64 = 42;
    try t.expectEqual(c.status_invalid, api.color_profile_generate(&definition, @intFromPtr(memory.ptr), memory.len, @intFromPtr(&bytes), bytes.len, &count));
    try t.expectEqual(@as(u64, 42), count);
    for (bytes) |value| try t.expectEqual(@as(u8, 0xa5), value);
}

fn imageDescription(primaries: u32, transfer: u32, alpha: u32, precision: u32, white: u32, peak: u32) c.R4GfxColorDescription {
    return .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription), .primaries = primaries, .transfer = transfer, .range = c.color_range_full, .alpha = alpha, .precision = precision, .flags = 0, .reference_white = white * 10000, .peak = peak * 10000, .black = 0, .reserved = 0 };
}
fn imageView(bytes: []u8, width: u32, height: u32, pitch: u64, format: u32, desc: c.R4GfxColorDescription) c.R4GfxColorImage {
    return .{ .version = 1, .size = @sizeOf(c.R4GfxColorImage), .image = .{ .cpu_address = @intFromPtr(bytes.ptr), .byte_length = bytes.len, .pitch = pitch, .width = width, .height = height, .format = format, .reserved = 0 }, .description = desc, .profile = .{ .address = 0, .generation = 0 } };
}
fn imageRequest(sw: u32, sh: u32, tw: u32, th: u32) c.R4GfxColorTransform {
    return .{ .version = 1, .size = @sizeOf(c.R4GfxColorTransform), .source_rect = .{ .x = 0, .y = 0, .width = sw, .height = sh }, .target_rect = .{ .x = 0, .y = 0, .width = tw, .height = th }, .sampler = c.render_sampler_nearest, .operation = c.render_operation_blit, .opacity = 65535, .flags = 0, .pixel_budget = @as(u64, tw) * th };
}
fn checkImages(api: *const c.ColorV1) !void {
    const pixels = @import("color_pixels.zig");
    const run = api.color_image_transform;
    var source_bytes: [16]u8 = @splat(0xa5);
    var working_bytes: [24]u8 = @splat(0xa5);
    var output_bytes: [16]u8 = @splat(0xa5);
    const source_desc = imageDescription(1, 1, 3, 8, 100, 100);
    const working_desc = imageDescription(3, 2, 4, 16, 100, 1000);
    const output_desc = imageDescription(1, 1, 1, 8, 100, 100);
    var source = imageView(&source_bytes, 2, 1, 16, c.format_argb8888, source_desc);
    var working = imageView(&working_bytes, 2, 1, 24, c.format_abgr16161616f, working_desc);
    var output = imageView(&output_bytes, 2, 1, 16, c.format_xrgb8888, output_desc);
    pixels.store(.argb8888, &source_bytes, .{ .rgb = @splat(128.0 / 255.0), .alpha = 128.0 / 255.0 }, 0, 0, false);
    pixels.store(.argb8888, source_bytes[4..].ptr, .{ .rgb = @splat(0), .alpha = 0 }, 1, 0, false);
    var request = imageRequest(2, 1, 2, 1);
    var stats = std.mem.zeroes(c.R4GfxCpuStats);
    try t.expectEqual(c.status_ok, run(&source, &working, &request, &stats));
    try rgbNear(@splat(128.0 / 255.0), pixels.load(.abgr16161616f, &working_bytes).rgb, 0.0002);
    try t.expectEqualSlices(u8, &(@as([8]u8, @splat(0xa5))), working_bytes[16..24]);
    @memset(output_bytes[0..8], 0);
    request.operation = c.render_operation_over;
    try t.expectEqual(c.status_ok, run(&working, &output, &request, &stats));
    // Gamma-domain blending would produce128; linear light is188.
    try t.expectEqual(@as(u32, 0x00bcbcbc), std.mem.readInt(u32, output_bytes[0..4], .little));
    try t.expectEqual(@as(u32, 0), std.mem.readInt(u32, output_bytes[4..8], .little));
    try t.expectEqualSlices(u8, &(@as([8]u8, @splat(0xa5))), output_bytes[8..16]);
    // Bilinear resampling decodes both taps before interpolation. A black-
    // white ramp reduced to one pixel has half the light, not half the code.
    pixels.store(.argb8888, &source_bytes, .{ .rgb = @splat(0), .alpha = 1 }, 0, 0, false);
    pixels.store(.argb8888, source_bytes[4..].ptr, .{ .rgb = @splat(1), .alpha = 1 }, 1, 0, false);
    request = imageRequest(2, 1, 1, 1);
    request.sampler = c.render_sampler_bilinear;
    try t.expectEqual(c.status_ok, run(&source, &output, &request, &stats));
    try t.expectEqual(@as(u32, 0x00bcbcbc), std.mem.readInt(u32, output_bytes[0..4], .little));
    const saved = output_bytes;
    request.target_rect.x = 2;
    try t.expectEqual(c.status_invalid, run(&source, &output, &request, &stats));
    try t.expectEqualSlices(u8, &saved, &output_bytes);
    request.target_rect.x = 0;
    try t.expectEqual(c.status_alias, run(&source, &source, &request, &stats));
    // NaN in a later sampled FP16 pixel cannot partially overwrite the target.
    std.mem.writeInt(u16, working_bytes[8..10], 0x7e00, .little);
    request = imageRequest(2, 1, 2, 1);
    try t.expectEqual(c.status_invalid, run(&working, &output, &request, &stats));
    try t.expectEqualSlices(u8, &saved, &output_bytes);
    // Retain HDR light in FP16, then encode to real10-bit PQ. SDR white is
    // explicitly mapped from100 to203 nits, without altering PQ's EOTF.
    @memset(source_bytes[0..8], 0xff);
    working.description = imageDescription(3, 2, 4, 16, 203, 1000);
    output.image.format = c.format_xrgb2101010;
    output.description = imageDescription(3, 3, 1, 10, 203, 1000);
    request.flags = c.color_transform_relative_white;
    try t.expectEqual(c.status_ok, run(&source, &working, &request, &stats));
    request.flags = c.color_transform_output;
    try t.expectEqual(c.status_ok, run(&working, &output, &request, &stats));
    const pq = pixels.load(.xrgb2101010, &output_bytes);
    try rgbNear(@splat(color.pqEncode(203)), pq.rgb, 0.0005);
    // A1000-nit neutral maps to the defined SDR peak; FP16 also retains
    // signed gamut excursions until the final output mapping.
    pixels.store(.abgr16161616f, &working_bytes, .{ .rgb = @splat(1000.0 / 203.0), .alpha = 1 }, 0, 0, false);
    output.description = output_desc;
    output.image.format = c.format_xrgb8888;
    request.flags |= c.color_transform_relative_white;
    try t.expectEqual(c.status_ok, run(&working, &output, &request, &stats));
    try t.expectEqual(@as(u32, 0x00ffffff), std.mem.readInt(u32, output_bytes[0..4], .little));
}

fn checkLookup() !void {
    // Compare the bounded lookup path against the independently anchored
    // analytic path, including off-grid values and near-black10-bit codes.
    for ([_]color.Transfer{ .srgb, .pq, .hlg, .bt1886 }) |transfer| {
        const desc: color.Description = .{ .primaries = .bt2020, .transfer = transfer, .precision = .unorm10, .reference_white = 203,
            .peak = if (transfer == .srgb or transfer == .bt1886) 203 else 1000, .black = if (transfer == .bt1886) 0.005 else 0 };
        const exact = try color.Encoding.init(desc);
        const fast = try color.Encoding.initFast(desc);
        for (0..2048) |i| {
            const x = @as(f32, @floatFromInt(i)) / 2047;
            const sample: color.Rgb = .{ x, x * 0.53, x * 0.13 };
            const decoded = exact.decode(sample, 1);
            const quick = fast.decode(sample, 1);
            for (decoded.rgb, quick.rgb) |e, v| try near(e, v, @max(0.00003, @abs(e) * 0.00002));
            const encoded = fast.encode(decoded);
            const oracle = exact.encode(decoded);
            try rgbNear(oracle.rgb, encoded.rgb, 0.0001);
        }
    }
}

fn checkPixels() !void {
    const pixels = @import("color_pixels.zig");
    var precise: [8]u8 = undefined;
    inline for (.{ @as(u16, 1), @as(u16, 257), @as(u16, 0x1234), @as(u16, 0x7ffd) }, 0..) |value, i| std.mem.writeInt(u16, precise[i * 2 ..][0..2], value, .little);
    const precise_value = pixels.load(.abgr16161616, &precise);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / 65535.0), precise_value.rgb[0], 0.000000001);
    var restored: [8]u8 = undefined;
    pixels.store(.abgr16161616, &restored, precise_value, 0, 0, false);
    try std.testing.expectEqualSlices(u8, &precise, &restored);
    const legal: color.Description = .{ .precision = .unorm16, .range = .limited };
    try rgbNear(@splat(0), color.unpackRange(legal, @splat(4096.0 / 65535.0)), 0.000001);
    try rgbNear(@splat(1), color.unpackRange(legal, @splat(60160.0 / 65535.0)), 0.000001);
    var bytes: [12]u8 = @splat(0xa5);
    pixels.store(.argb2101010, bytes[1..].ptr, .{ .rgb = .{ 1, 0.5, 0 }, .alpha = 2.0 / 3.0 }, 0, 0, false);
    try t.expectEqual(@as(u32, 0xbff80000), std.mem.readInt(u32, bytes[1..5], .little));
    const ten = pixels.load(.argb2101010, bytes[1..].ptr);
    try rgbNear(.{ 1, 512.0 / 1023.0, 0 }, ten.rgb, 1e-7);
    try near(2.0 / 3.0, ten.alpha, 1e-7);
    try t.expect(bytes[0] == 0xa5 and bytes[5] == 0xa5);
    pixels.store(.abgr16161616f, bytes[1..].ptr, .{ .rgb = .{ -0.5, 2, 100 }, .alpha = 0.25 }, 0, 0, false);
    try t.expectEqualSlices(u8, &.{ 0x00, 0xb8, 0x00, 0x40, 0x40, 0x56, 0x00, 0x34 }, bytes[1..9]);
    try rgbNear(.{ -0.5, 2, 100 }, pixels.load(.abgr16161616f, bytes[1..].ptr).rgb, 0);
    try t.expect(bytes[0] == 0xa5 and bytes[9] == 0xa5);
    std.mem.writeInt(u16, bytes[1..3], 0x7c00, .little);
    try t.expect(!pixels.finite(pixels.load(.abgr16161616f, bytes[1..].ptr)));
    // A half-code gray distributes evenly without inventing temporal noise.
    var sum: u32 = 0;
    for (0..4) |y| for (0..4) |x| {
        pixels.store(.argb8888, &bytes, .{ .rgb = @splat(0.5), .alpha = 0.5 }, @intCast(x), @intCast(y), true);
        const sample = std.mem.readInt(u32, bytes[0..4], .little);
        sum += sample & 255;
        try t.expect(sample >> 24 == 128 and ((sample >> 8) & 255) == (sample & 255));
    };
    try t.expectEqual(@as(u32, 2040), sum);
    try t.expectError(error.Invalid, pixels.Format.xrgb2101010.validate(.{}));
    try pixels.Format.abgr16161616f.validate(.{ .transfer = .linear, .precision = .float16, .alpha = .optical });
}

fn checkApi(api: *const c.ColorV1) !void {
    const icc = @import("color_icc.zig");
    const Storage = struct { bytes: [2 * 1024 * 1024]u8 align(16) };
    const storage = try t.allocator.create(Storage);
    defer t.allocator.destroy(storage);
    const profile_memory = try t.allocator.create(Storage);
    defer t.allocator.destroy(profile_memory);
    var memory = try icc.Arena.init(&profile_memory.bytes);
    var profile_bytes: [4096]u8 = undefined;
    const length = try icc.builtin(&memory, 0, &profile_bytes);
    @memset(storage.bytes[0..16], 0);
    var config: c.R4GfxColorProfileConfig = .{ .version = 1, .size = @sizeOf(c.R4GfxColorProfileConfig), .storage_address = @intFromPtr(&storage.bytes), .storage_bytes = storage.bytes.len, .profile_address = @intFromPtr(&profile_bytes), .profile_bytes = length, .direction = c.color_profile_input, .intent = c.color_intent_relative, .flags = 0, .reserved = 0 };
    var profile: c.R4GfxColorProfile = .{ .address = 17, .generation = 19 };
    const original = profile;
    config.reserved = 1;
    try t.expectEqual(c.status_invalid, api.color_profile_open(&config, &profile));
    try t.expectEqualDeep(original, profile);
    config.reserved = 0;
    try t.expectEqual(c.status_alias, api.color_profile_open(&config, @ptrCast(&storage.bytes)));
    try t.expectEqual(c.status_ok, api.color_profile_open(&config, &profile));
    const first = profile;
    var stats: c.R4GfxColorProfileInfo = undefined;
    try t.expectEqual(c.status_ok, api.color_profile_info(&profile, &stats));
    try t.expect(stats.used_bytes > length and stats.used_bytes <= stats.storage_bytes);
    try t.expectEqual(c.status_busy, api.color_profile_open(&config, &profile));
    try t.expectEqualDeep(first, profile);
    const rgb = [_][3]f32{.{ 1, 1, 1 }};
    var xyz = [_][3]f32{.{ 0, 0, 0 }};
    var request: c.R4GfxColorProfileRequest = .{ .source_address = @intFromPtr(&rgb), .target_address = @intFromPtr(&xyz), .pixel_count = 1, .reserved = 0 };
    try t.expectEqual(c.status_ok, api.color_profile_apply(&profile, &request));
    try rgbNear(.{ 0.9642, 1, 0.8249 }, xyz[0], 0.0001);
    request.target_address = @intFromPtr(&profile);
    try t.expectEqual(c.status_alias, api.color_profile_apply(&profile, &request));
    request.target_address = config.storage_address;
    try t.expectEqual(c.status_alias, api.color_profile_apply(&profile, &request));
    request.target_address = @intFromPtr(&xyz);
    var encoded_pixels: [8]u8 = .{ 255, 255, 255, 0, 128, 128, 128, 0 };
    var linear_pixels: [16]u8 = undefined;
    var encoded_image = imageView(&encoded_pixels, 2, 1, 8, c.format_xrgb8888, imageDescription(4, 5, 1, 8, 100, 100));
    encoded_image.profile = profile;
    const linear_image = imageView(&linear_pixels, 2, 1, 16, c.format_abgr16161616f, imageDescription(3, 2, 4, 16, 100, 100));
    var transform = imageRequest(2, 1, 2, 1);
    var image_stats: c.R4GfxCpuStats = undefined;
    try t.expectEqual(c.status_ok, api.color_image_transform(&encoded_image, &linear_image, &transform, &image_stats));
    try rgbNear(@splat(1), @import("color_pixels.zig").load(.abgr16161616f, &linear_pixels).rgb, 0.0005);
    try rgbNear(@splat(color.srgbDecode(128.0 / 255.0)), @import("color_pixels.zig").load(.abgr16161616f, linear_pixels[8..].ptr).rgb, 0.0002);
    try t.expectEqual(c.status_ok, api.color_profile_close(&profile));
    try t.expectEqual(c.status_ok, api.color_profile_close(&profile));
    try t.expectEqual(c.status_stale, api.color_profile_apply(&profile, &request));
    try t.expectEqual(c.status_ok, api.color_profile_open(&config, &profile));
    try t.expect(profile.generation != first.generation);
    try t.expectEqual(c.status_stale, api.color_profile_close(&first));
    try t.expectEqual(c.status_ok, api.color_profile_apply(&profile, &request));
    try t.expectEqual(c.status_ok, api.color_profile_close(&profile));
    // Reuse the exact storage for an output ICC profile. Its D50 PCS must be
    // adapted back from the shared D65 working image; calibration is applied
    // by the retained output transform, never by the source or kernel.
    config.direction = c.color_profile_output;
    config.flags = c.color_profile_calibration;
    try t.expectEqual(c.status_ok, api.color_profile_open(&config, &profile));
    encoded_image.profile = profile;
    transform.flags = c.color_transform_output;
    @memset(&encoded_pixels, 0xa5);
    try t.expectEqual(c.status_ok, api.color_image_transform(&linear_image, &encoded_image, &transform, &image_stats));
    try t.expectEqualSlices(u8, &.{ 255, 255, 255, 0, 128, 128, 128, 0 }, &encoded_pixels);
    transform.operation = c.render_operation_over;
    try t.expectEqual(c.status_unsupported, api.color_image_transform(&linear_image, &encoded_image, &transform, &image_stats));
    try t.expectEqual(c.status_ok, api.color_profile_close(&profile));
    var desc: c.R4GfxColorDescription = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription), .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_srgb, .range = c.color_range_full, .alpha = c.color_alpha_opaque, .precision = c.color_precision_unorm8, .flags = 0, .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 };
    try t.expectEqual(c.status_ok, api.color_description_validate(&desc));
    desc.transfer = c.color_transfer_pq;
    try t.expectEqual(c.status_unsupported, api.color_description_validate(&desc));
    desc.precision = c.color_precision_unorm10;
    try t.expectEqual(c.status_ok, api.color_description_validate(&desc));
    desc.transfer = 0xffff;
    try t.expectEqual(c.status_unsupported, api.color_description_validate(&desc));
}

fn checkIcc() !void {
    const icc = @import("color_icc.zig");
    const Storage = struct { bytes: [2 * 1024 * 1024]u8 align(16) };
    const first = try t.allocator.create(Storage);
    defer t.allocator.destroy(first);
    const second = try t.allocator.create(Storage);
    defer t.allocator.destroy(second);
    var a = try icc.Arena.init(&first.bytes);
    var b = try icc.Arena.init(&second.bytes);
    var bytes: [4096]u8 = undefined;
    const length = try icc.builtin(&a, 0, &bytes);
    try t.expect(length >= 132 and length <= bytes.len and a.used == 0);
    var input = try icc.Profile.open(&a, bytes[0..length], .input, .relative, false, false);
    defer input.close();
    var output = try icc.Profile.open(&b, bytes[0..length], .output, .relative, false, true);
    defer output.close();
    // Original sRGB anchors in the relative D50 PCS, including a nonlinear
    // mid-gray. Caller bytes can be overwritten after successful profile open.
    @memset(bytes[0..length], 0xa5);
    const rgb = [_][3]f32{ .{ 1, 1, 1 }, .{ 0.5, 0.5, 0.5 }, .{ 1, 0, 0 }, .{ 0, 0, 0 } };
    var xyz: [4][3]f32 = undefined;
    var recovered: [4][3]f32 = undefined;
    try input.apply(&rgb, &xyz);
    try rgbNear(.{ 0.9642, 1, 0.8249 }, xyz[0], 0.0001);
    try near(0.21404114, xyz[1][1], 0.0001);
    try rgbNear(.{ 0.43604, 0.22249, 0.01392 }, xyz[2], 0.0001);
    try rgbNear(.{ 0, 0, 0 }, xyz[3], 1e-6);
    try output.apply(&xyz, &recovered);
    for (rgb, recovered) |e, v| try rgbNear(e, v, 0.0002);
    const original = recovered;
    xyz[3][0] = std.math.nan(f32);
    try t.expectError(error.NonFinite, output.apply(&xyz, &recovered));
    try t.expectEqualDeep(original, recovered);
    try t.expectError(error.Alias, input.apply(&recovered, &recovered));
    var stale = input;
    input.close();
    output.close();
    try t.expect(a.used == 0 and b.used == 0);
    // Repeat creation/teardown after arena reuse; no global allocator or state
    // from another display is needed. Test an invalid profile and bounded OOM.
    const linear_size = try icc.builtin(&a, 1, &bytes);
    var linear = try icc.Profile.open(&a, bytes[0..linear_size], .input, .relative, false, false);
    stale.close();
    try t.expect(a.used != 0 and a.active != null);
    try linear.apply(rgb[1..2], xyz[0..1]);
    try near(0.5, xyz[0][1], 0.0001);
    linear.close();
    const first_tag = bytes[132..144].*;
    const second_tag = bytes[144..156].*;
    std.mem.writeInt(u32, bytes[136..140], @intCast(linear_size - 4), .big);
    try t.expectError(error.Invalid, icc.Profile.open(&a, bytes[0..linear_size], .input, .relative, false, false));
    @memcpy(bytes[132..144], &first_tag);
    @memcpy(bytes[144..148], first_tag[0..4]);
    try t.expectError(error.Invalid, icc.Profile.open(&a, bytes[0..linear_size], .input, .relative, false, false));
    @memcpy(bytes[144..156], &second_tag);
    std.mem.writeInt(u32, bytes[148..152], std.mem.readInt(u32, first_tag[4..8], .big) + 4, .big);
    try t.expectError(error.Invalid, icc.Profile.open(&a, bytes[0..linear_size], .input, .relative, false, false));
    @memcpy(bytes[144..156], &second_tag);
    bytes[36] = 0;
    try t.expectError(error.Invalid, icc.Profile.open(&a, bytes[0..linear_size], .input, .relative, false, false));
    bytes[36] = 'a';
    var tiny: [1024]u8 align(16) = undefined;
    var short = try icc.Arena.init(&tiny);
    try t.expectError(error.Memory, icc.Profile.open(&short, bytes[0..linear_size], .input, .relative, false, false));
    try t.expect(short.failed and short.used == 0);
    const fixtures = @import("profile_fixtures");
    // A real LUT-only display profile (A2B0/B2A0,mft2; no RGB TRC or matrix
    // tags). Its original synthetic cubes map RGB components to equal XYZ
    // components, providing anchors independent of the matrix/TRC path.
    var lut_input = try icc.Profile.open(&a, fixtures.lut, .input, .relative, false, false);
    defer lut_input.close();
    var lut_output = try icc.Profile.open(&b, fixtures.lut, .output, .relative, false, false);
    defer lut_output.close();
    const anchors = [_][3]f32{ .{0.1234,0.6000,0.9100}, .{0.375,0.125,0.25}, .{0,0,0} };
    var lut_values: [3][3]f32 = undefined;
    try lut_input.apply(&anchors, &lut_values);
    for (anchors, lut_values) |expected, value| try rgbNear(expected, value, 0.00008);
    try lut_output.apply(&anchors, &lut_values);
    for (anchors, lut_values) |expected, value| try rgbNear(expected, value, 0.00008);
    lut_input.close(); lut_output.close();
    // Calibration is explicit and applied only once, after the output ICC
    // transform. Real VCGT curves have unequal channel endpoints.
    for ([_]bool{ false, true }) |calibration| {
        var calibrated = try icc.Profile.open(&a, fixtures.calibrated, .output, .relative, false, calibration);
        defer calibrated.close();
        var white: [1][3]f32 = undefined;
        try calibrated.apply(&.{.{0.9642,1,0.8249}}, &white);
        try rgbNear(if (calibration) .{0.75,0.5,1} else .{1,1,1}, white[0], 0.0001);
    }
    try t.expectError(error.Unsupported, icc.Profile.open(&a, fixtures.descending, .output, .relative, false, true));
    try t.expect(a.used == 0 and a.active == null);
}

fn checkSmallBatches(api: *const c.ColorV1) !void {
    const pixels = @import("color_pixels.zig");
    for ([_]bool{ false, true }) |source_float| for ([_]bool{ false, true }) |target_float| {
        if (!source_float and !target_float) continue;
        const sf: pixels.Format = if (source_float) .abgr16161616f else .argb8888;
        const tf: pixels.Format = if (target_float) .abgr16161616f else .xrgb8888;
        const sd = if (source_float) imageDescription(1, 2, 4, 16, 100, 100) else imageDescription(1, 1, 3, 8, 100, 100);
        const td = if (target_float) imageDescription(1, 2, 4, 16, 100, 100) else imageDescription(1, 1, 1, 8, 100, 100);
        var input: [16 * 18 * 8]u8 = @splat(0);
        var short: [8 * 9 * 8]u8 = @splat(0);
        var long: [8 * 9 * 8]u8 = @splat(0);
        for (0..16 * 18) |i| pixels.store(sf, input[i * sf.bytes() ..].ptr,
            .{ .rgb = .{ @as(f32, @floatFromInt(i % 13)) / 32, 0.2, 0.1 }, .alpha = 0.5 }, @intCast(i % 16), @intCast(i / 16), false);
        for ([_]u32{ c.render_sampler_nearest, c.render_sampler_bilinear }) |sampler| for ([_]u32{ c.render_operation_blit, c.render_operation_over }) |operation| {
            for ([_]u32{ 0, 32768, 65535 }) |opacity| {
                for (0..8 * 9) |i| pixels.store(tf, short[i * tf.bytes() ..].ptr,
                    .{ .rgb = .{ 0.2, 0.1, 0.05 }, .alpha = 1 }, @intCast(i % 8), @intCast(i / 8), false);
                long = short;
                var source = imageView(&input, 16, 18, 16 * sf.bytes(), @intFromEnum(sf), sd);
                var small_target = imageView(&short, 8, 9, 8 * tf.bytes(), @intFromEnum(tf), td);
                var big_target = imageView(&long, 8, 9, 8 * tf.bytes(), @intFromEnum(tf), td);
                var small_request = imageRequest(16, 16, 8, 8);
                small_request.sampler = sampler; small_request.operation = operation; small_request.opacity = opacity;
                var big_request = imageRequest(16, 18, 8, 9);
                big_request.sampler = sampler; big_request.operation = operation; big_request.opacity = opacity;
                var small_stats: c.R4GfxCpuStats = undefined; var big_stats: c.R4GfxCpuStats = undefined;
                try t.expectEqual(c.status_ok, api.color_image_transform(&source, &small_target, &small_request, &small_stats));
                try t.expectEqual(c.status_ok, api.color_image_transform(&source, &big_target, &big_request, &big_stats));
                try t.expectEqualSlices(u8, long[0 .. 64 * tf.bytes()], short[0 .. 64 * tf.bytes()]);
                const across: u64 = if (sampler == c.render_sampler_bilinear) 4 else 1;
                try t.expectEqual(@as(u64, 64) * (sf.bytes() * across + @as(u64, if (operation == c.render_operation_over) tf.bytes() else 0)), small_stats.read_bytes);
                if (source_float or (target_float and operation == c.render_operation_over)) try t.expect(big_stats.read_bytes / 72 > small_stats.read_bytes / 64);
            }
        };
    };
    // Late FP16 source/target NaN and both infinities leave every byte intact,
    // both below and above the complete-operation staging threshold.
    for ([_]u32{ 8, 9 }) |height| for ([_]u16{ 0x7e00, 0x7c00, 0xfc00 }) |bad| for ([_]bool{ false, true }) |bad_target| {
        var src: [8 * 9 * 8]u8 = @splat(0); var dst = src;
        const bytes = @as(usize, height) * 8 * 8;
        if (bad_target) std.mem.writeInt(u16, dst[bytes - 8 ..][0..2], bad, .little)
        else std.mem.writeInt(u16, src[bytes - 8 ..][0..2], bad, .little);
        const saved = dst;
        const desc = imageDescription(1, 2, 4, 16, 100, 100);
        var source = imageView(&src, 8, height, 64, c.format_abgr16161616f, desc);
        var target = imageView(&dst, 8, height, 64, c.format_abgr16161616f, desc);
        var request = imageRequest(8, height, 8, height); request.operation = c.render_operation_over;
        var stats: c.R4GfxCpuStats = undefined;
        try t.expectEqual(c.status_invalid, api.color_image_transform(&source, &target, &request, &stats));
        try t.expectEqualSlices(u8, &saved, &dst);
    };
    std.debug.print("[color-batch] 36 staged/un-staged reference pairs and 12 late NaN/Inf source/target failures preserve bytes; small FP16 reads occur once\n", .{});
}
