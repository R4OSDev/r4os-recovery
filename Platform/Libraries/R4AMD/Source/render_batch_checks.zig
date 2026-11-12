// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const a = @import("r4os").abi;
const c = @import("r4l_contract");
const b = @import("render_batch.zig").Provider(c, a);
const y = @import("render_yuv.zig").Provider(c, a);
const p = @import("pm4.zig");
const regs = @cImport({
    @cInclude("amdgfx9regs.h");
});
fn scalar(program: *b.Color, offset: usize, value: f32) void {
    program.words[offset / 4] = @bitCast(value);
}
pub fn color() b.Color {
    var program: b.Color = .{};
    program.words[1] = 2;
    program.words[2] = 2;
    program.words[3] = 1;
    program.words[4] = 4;
    for ([_]usize{ 32, 52, 72, 80, 100, 120 }) |offset| scalar(&program, offset, 1);
    for ([_]usize{ 128, 132, 144, 148, 192 }) |offset| scalar(&program, offset, 100);
    for ([_]usize{ 136, 152, 160, 168, 176, 180 }) |offset| scalar(&program, offset, 1);
    return program;
}
fn draws(words: []const u32) usize {
    var at: usize = 0;
    var count: usize = 0;
    while (at < words.len) {
        if ((words[at] >> 8) & 255 == 0x2d) count += 1;
        at += ((words[at] >> 16) & 0x3fff) + 2;
    }
    return count;
}
pub fn run() !void {
    for ([_]bool{ false, true }) |raven2| {
    var arch: c.R4AmdArchitecture = .{ .version = 1, .size = @sizeOf(c.R4AmdArchitecture), .vendor_id = c.vendor_id, .device_id = 0x15d8, .gc_version = c.gc_9_1_0, .sdma_version = c.sdma_4_1_0, .gb_addr_config = 0x24000042, .chip_revision = 0x41, .bind_alignment = 4096, .memory_generation = 23, .flags = 0, .reserved = 0, .max_image_bytes = 64 * 1024 * 1024 };
    if (raven2) { arch.gc_version = c.gc_9_2_2; arch.sdma_version = c.sdma_4_1_1; arch.chip_revision = 0x82; arch.gb_addr_config = 0x26013041; }
    var scratch: [65536]u8 align(16) = undefined;
    var desc: a.GfxBufferDescriptor = .{ .byte_length = 131072, .alignment = 4096, .width = 256, .height = 128, .format = a.gfx_buffer_format_argb8888, .plane_count = 1, .plane_pitches = .{ 1024, 0, 0, 0 }, .usage = a.gfx_buffer_usage_render | a.gfx_buffer_usage_transfer_source | a.gfx_buffer_usage_transfer_target, .location = a.gfx_buffer_location_device_local, .adapter_id = 7, .driver_owner = 9, .device_generation = 23 };
    const target = try b.image(arch, 7, desc, 0x5100000000, true, 0, &scratch);
    var commands: [16]a.GfxRenderCommand = @splat(.{ .target_rect = .{ .x = -3, .y = 2, .width = 64, .height = 32 }, .scissor = .{ .x = 0, .y = 0, .width = 256, .height = 128 }, .color = 0xff224466, .opacity = 255 });
    var grids: [16]a.GfxSampleGrid = @splat(.{});
    var payload: [4096]u8 = undefined;
    var words: [b.max_words]u32 = undefined;
    const count = try b.encode(null, target, &commands, &grids, null, 0x8100000000, 0x8100008000, &payload, &words);
    try p.packetBoundaries(words[0..count]);
    try t.expectEqual(@as(usize, 16), draws(words[0..count]));
    try t.expect(count <= 2016);
    const push = std.mem.bytesToValue(b.Push, payload[1024..1184]);
    try t.expectApproxEqAbs(@as(f32, 0x22) / 255, push.tint[0], 0.00001);
    commands[15].opacity = 256;
    try t.expectError(error.Invalid, b.encode(null, target, &commands, &grids, null, 0x8100000000, 0x8100008000, &payload, &words));
    commands[15].opacity = 255;
    commands[0].target_rect.x = -200;
    try t.expectEqual(@as(usize, 0), try b.encode(null, target, commands[0..1], grids[0..1], null, 0x8100000000, 0x8100008000, &payload, &words));
    commands[0] = .{ .kind = 1, .filter = 1, .blend = 1, .transfer = 1, .source_rect = .{ .x = 32, .y = 16, .width = 128, .height = 64 }, .target_rect = .{ .width = 256, .height = 128 }, .scissor = .{ .width = 256, .height = 128 }, .opacity = 128 };
    var source = try b.image(arch, 7, desc, 0x5000000000, false, 1, &scratch);
    const sampled = try b.encode(source, target, commands[0..1], grids[0..1], null, 0x8100000000, 0x8100008000, &payload, &words);
    try p.packetBoundaries(words[0..sampled]);
    const transform = std.mem.bytesToValue(b.Push, payload[1024..1184]);
    try t.expectApproxEqAbs(@as(f32, 0.5 / 256.0), transform.mapping[0], 0.0000001);
    try t.expectEqual(@as(u32, 1), transform.flags[0]);
    try t.expectEqual(source.descriptors.texture0, std.mem.readInt(u32, payload[256..260], .little));
    const correct_gc = source.request.gc_version;
    source.request.gc_version = if (raven2) c.gc_9_1_0 else c.gc_9_2_2;
    try t.expectError(error.Unsupported, b.encode(source, target, commands[0..1], grids[0..1], null, 0x8100000000, 0x8100008000, &payload, &words));
    source.request.gc_version = correct_gc;
    // Integer logical sampling is carried once as a fixed 64-byte GPU input.
    commands[0].filter = 0;
    commands[0].transfer = 0;
    commands[0].source_rect = .{ .width = 256, .height = 128 };
    grids[0] = .{ .enabled = 1, .scale = 120, .pixel_width = 256, .pixel_height = 128, .viewport_width = 256, .viewport_height = 128, .guest_width = 256, .guest_height = 128 };
    source = try b.image(arch, 7, desc, 0x5000000000, false, 0, &scratch);
    _ = try b.encode(source, target, commands[0..1], grids[0..1], null, 0x8100000000, 0x8100008000, &payload, &words);
    try t.expectEqualSlices(u8, std.mem.asBytes(&grids[0]), payload[1088..1152]);
    grids[0].scale = 0;
    try t.expectError(error.Bounds, b.encode(source, target, commands[0..1], grids[0..1], null, 0x8100000000, 0x8100008000, &payload, &words));
    grids[0] = .{};
    desc.format = a.gfx_buffer_format_r8;
    desc.plane_pitches[0] = 256;
    const mask = try b.image(arch, 7, desc, 0x5000000000, false, 0, &scratch);
    try t.expectEqual(@as(u32, 4), regs.G_008F1C_DST_SEL_W(mask.descriptors.texture3));
    try t.expectEqual(@as(u32, 4), regs.G_008F1C_DST_SEL_X(mask.descriptors.texture3));
    const program = color();
    try program.validate();
    var packet: y.Packet = std.mem.zeroes(y.Packet);
    packet.color = program.words;
    packet.matrix = .{ .{ 1, 0, 0, 0 }, .{ 0, 1, 0, 0 }, .{ 0, 0, 1, 0 } };
    packet.header = .{ .version = 1, .size = @sizeOf(c.R4AmdYuvHeader), .kind = 1, .format = 1, .filter = 1, .blend = 0, .opacity = 32768, .width = 256, .height = 128, .target_binding = 1, .plane_count = 2, .reserved = 0, .source = .{ .x = 0, .y = 0, .width = 256, .height = 128 }, .destination = .{ .x = 0, .y = 0, .width = 256, .height = 128 }, .scissor = .{ .x = 0, .y = 0, .width = 256, .height = 128 }, .plane0 = .{ .binding = 0, .reserved = 0, .offset = 0, .byte_length = 65536, .pitch = 512, .reserved1 = 0 }, .plane1 = .{ .binding = 0, .reserved = 0, .offset = 65536, .byte_length = 32768, .pitch = 512, .reserved1 = 0 }, .plane2 = std.mem.zeroes(c.R4AmdYuvPlane), .chroma_x = 0, .chroma_y = @bitCast(@as(f32, 0.5)) };
    desc.format = a.gfx_buffer_format_argb8888;
    desc.plane_pitches[0] = 1024;
    const bindings = [_]y.Bound{ .{ .address = 0x5000000000, .descriptor = .{ .byte_length = 131072, .alignment = 4096, .usage = a.gfx_buffer_usage_transfer_source } }, .{ .address = 0x5100000000, .descriptor = desc } };
    for ([_]u32{ 1, 2, 3 }) |format| {
        packet.header.format = format;
        if (format == 3) {
            packet.header.plane_count = 3;
            packet.header.plane2 = .{ .binding = 0, .reserved = 0, .offset = 98304, .byte_length = 32768, .pitch = 512, .reserved1 = 0 };
        }
        const n = try y.encode(arch, 7, packet, &bindings, 0x8100000000, 0x8100008000, &scratch, &payload, &words);
        try p.packetBoundaries(words[0..n]);
        try t.expectEqual(@as(usize, 1), draws(words[0..n]));
        try t.expectEqual(format, std.mem.readInt(u32, payload[768..772], .little));
        try t.expectEqual(@as(u32, if (format == 2) 6 else 0), std.mem.readInt(u32, payload[844..848], .little));
        try t.expectEqual(@as(u32, 4), regs.G_008F14_NUM_FORMAT(std.mem.readInt(u32, payload[260..264], .little)));
        const ypush = std.mem.bytesToValue(b.Push, payload[1024..1184]);
        try t.expectApproxEqAbs(@as(f32, 32768.0 / 65535.0), ypush.tint[3], 0.000001);
    }
    packet.header.plane1.offset = 131072;
    try t.expectError(error.Invalid, y.encode(arch, 7, packet, &bindings, 0x8100000000, 0x8100008000, &scratch, &payload, &words));
    }
}
