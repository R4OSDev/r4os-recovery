const std = @import("std");
const t = std.testing;
const c = @import("r4l_contract");
const render = @import("cpu_render.zig");
const empty = c.R4GfxRect{ .x = 0, .y = 0, .width = 0, .height = 0 };
fn draw(operation: u32, source: u32, target: u32, s: c.R4GfxRect, d: c.R4GfxRect) c.R4GfxCpuDraw {
    return .{ .operation = operation, .source_index = source, .target_index = target, .sampler = 0, .source_rect = s, .target_rect = d, .color = 0, .opacity = if (operation == c.render_operation_fill) 0 else 255, .reserved0 = 0, .reserved1 = 0 };
}
fn image(bytes: []u8, width: u32, height: u32, pitch: u64, format: u32) c.R4GfxCpuImage {
    return .{ .cpu_address = @intFromPtr(bytes.ptr), .byte_length = bytes.len, .pitch = pitch, .width = width, .height = height, .format = format, .reserved = 0 };
}
fn batch(images: []const c.R4GfxCpuImage, commands: []const c.R4GfxCpuDraw) c.R4GfxCpuBatch {
    return .{ .images = @intFromPtr(images.ptr), .commands = @intFromPtr(commands.ptr), .image_count = @intCast(images.len), .command_count = @intCast(commands.len), .pixel_budget = c.render_max_pixels, .flags = 0, .reserved = 0 };
}
pub fn check() !void {
    var caps: c.R4GfxRenderCaps = undefined;
    try t.expectEqual(c.status_ok, render.capabilities(&caps));
    try t.expect(caps.backend == c.render_backend_software and caps.max_pixels == c.render_max_pixels and caps.features & c.render_feature_validate_first != 0);
    // A valid first draw followed by a rejected draw must change neither
    // pixels nor the caller's statistics. Pitch padding and an unaligned
    // pixel base are part of this real execution case.
    var target: [81]u8 align(8) = @splat(0xa5);
    var source: [16]u8 align(8) = @splat(0);
    var images = [_]c.R4GfxCpuImage{ image(target[1..], 4, 4, 20, c.format_xrgb8888), image(&source, 2, 2, 8, c.format_argb8888) };
    var commands = [_]c.R4GfxCpuDraw{ draw(c.render_operation_fill, 0, 0, empty, .{ .x = 0, .y = 0, .width = 4, .height = 4 }), draw(c.render_operation_blit, 1, 0, .{ .x = 0, .y = 0, .width = 2, .height = 2 }, .{ .x = 0, .y = 0, .width = 4, .height = 4 }) };
    commands[0].color = 0x123456;
    var request = batch(&images, &commands);
    var stats: c.R4GfxCpuStats = .{ .read_bytes = 91, .write_bytes = 92, .pixels = 93, .commands = 94, .reserved = 95 };
    const original_stats = stats;
    commands[1].target_rect.width = 5;
    try t.expectEqual(c.status_invalid, render.execute(&request, &stats));
    try t.expectEqualDeep(original_stats, stats);
    try t.expect(std.mem.allEqual(u8, &target, 0xa5));
    commands[1].target_rect.width = 4;
    request.pixel_budget = 31;
    try t.expectEqual(c.status_limit, render.execute(&request, &stats));
    try t.expectEqualDeep(original_stats, stats);
    try t.expect(std.mem.allEqual(u8, &target, 0xa5));
    request.pixel_budget = 32;
    const corners = [_]u32{ 0xffff0000, 0xff00ff00, 0xff0000ff, 0xffffffff };
    for (corners, 0..) |pixel, i| std.mem.writeInt(u32, source[i * 4 ..][0..4], pixel, .little);
    try t.expectEqual(c.status_ok, render.execute(&request, &stats));
    try t.expect(stats.commands == 2 and stats.pixels == 32 and stats.write_bytes == 128 and stats.read_bytes == 64);
    for (0..4) |y| {
        for (0..4) |x| try t.expectEqual(corners[y / 2 * 2 + x / 2] & 0xffffff, std.mem.readInt(u32, target[1 + y * 20 + x * 4 ..][0..4], .little));
        try t.expect(std.mem.allEqual(u8, target[1 + y * 20 + 16 ..][0..4], 0xa5));
    }
    try t.expect(target[0] == 0xa5);
    // Pixel-center bilinear interpolation, clamped to the selected source
    // rectangle. Explicit expected values are independent of the renderer.
    var gray = [_]u8{ 99, 0, 255, 77 };
    var scaled: [8]u8 = @splat(0xa5);
    images = .{ image(&scaled, 4, 1, 8, c.format_r8), image(&gray, 4, 1, 4, c.format_r8) };
    commands[0] = draw(c.render_operation_blit, 1, 0, .{ .x = 1, .y = 0, .width = 2, .height = 1 }, .{ .x = 0, .y = 0, .width = 4, .height = 1 });
    commands[0].sampler = c.render_sampler_bilinear;
    request = batch(&images, commands[0..1]);
    try t.expectEqual(c.status_ok, render.execute(&request, &stats));
    try t.expectEqualSlices(u8, &.{ 0, 64, 191, 255, 0xa5, 0xa5, 0xa5, 0xa5 }, &scaled);
    try t.expect(stats.read_bytes == 16 and stats.write_bytes == 4);
    commands[0].operation = c.render_operation_over;
    try t.expectEqual(c.status_unsupported, render.execute(&request, &stats));
    // Exact premultiplied source-over with an additional opacity factor.
    var destination = [_]u32{ 0xff0000ff, 0xff0000ff };
    var red = [_]u32{0x80800000};
    images = .{ image(std.mem.asBytes(&destination), 2, 1, 8, c.format_argb8888), image(std.mem.asBytes(&red), 1, 1, 4, c.format_argb8888) };
    commands[0] = draw(c.render_operation_over, 1, 0, .{ .x = 0, .y = 0, .width = 1, .height = 1 }, .{ .x = 0, .y = 0, .width = 1, .height = 1 });
    commands[1] = commands[0];
    commands[1].target_rect.x = 1;
    commands[1].opacity = 128;
    request = batch(&images, &commands);
    try t.expectEqual(c.status_ok, render.execute(&request, &stats));
    try t.expectEqualSlices(u32, &.{ 0xff80007f, 0xff4000bf }, &destination);
    // Overlapping equal-view copies are memmoves in both axes. Filtered
    // feedback, source-over feedback and different overlapping views fail.
    var cells: [12]u32 align(8) = undefined;
    for (&cells, 0..) |*cell, i| cell.* = @intCast(i);
    images = .{ image(std.mem.asBytes(&cells), 4, 3, 16, c.format_argb8888), image(std.mem.asBytes(&cells), 4, 3, 16, c.format_argb8888) };
    commands[0] = draw(c.render_operation_blit, 1, 0, .{ .x = 0, .y = 0, .width = 3, .height = 2 }, .{ .x = 1, .y = 1, .width = 3, .height = 2 });
    request = batch(&images, commands[0..1]);
    try t.expectEqual(c.status_ok, render.execute(&request, &stats));
    try t.expectEqualSlices(u32, &.{ 0, 1, 2, 3, 4, 0, 1, 2, 8, 4, 5, 6 }, &cells);
    for (&cells, 0..) |*cell, i| cell.* = @intCast(i);
    std.mem.swap(c.R4GfxRect, &commands[0].source_rect, &commands[0].target_rect);
    try t.expectEqual(c.status_ok, render.execute(&request, &stats));
    try t.expectEqualSlices(u32, &.{ 5, 6, 7, 3, 9, 10, 11, 7, 8, 9, 10, 11 }, &cells);
    const saved = cells;
    commands[0].target_rect.width = 2;
    try t.expectEqual(c.status_alias, render.execute(&request, &stats));
    try t.expectEqualSlices(u32, &saved, &cells);
    commands[0].target_rect.width = 3;
    commands[0].operation = c.render_operation_over;
    try t.expectEqual(c.status_alias, render.execute(&request, &stats));
    commands[0].operation = c.render_operation_blit;
    images[1].width = 3;
    try t.expectEqual(c.status_invalid, render.execute(&request, &stats));
    images[1].width = 4;
    try t.expectEqual(c.status_alias, render.execute(&request, @ptrFromInt(images[0].cpu_address)));
    try t.expectEqualSlices(u32, &saved, &cells);
    images[0].cpu_address = @intFromPtr(&commands);
    try t.expectEqual(c.status_alias, render.execute(&request, &stats));
    images[0].cpu_address = std.math.maxInt(u64) - 4;
    try t.expectEqual(c.status_overflow, render.execute(&request, &stats));
    request.commands = std.math.maxInt(u64) - 3;
    try t.expectEqual(c.status_overflow, render.execute(&request, &stats));
    request = .{ .images = 0, .commands = 0, .image_count = 0, .command_count = 0, .pixel_budget = 0, .flags = 0, .reserved = 0 };
    try t.expectEqual(c.status_ok, render.execute(&request, &stats));
    try t.expect(stats.commands == 0 and stats.pixels == 0 and stats.read_bytes == 0 and stats.write_bytes == 0);
}
