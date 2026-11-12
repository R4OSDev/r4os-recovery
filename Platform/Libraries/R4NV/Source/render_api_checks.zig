// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const c = @import("r4l_contract");
const render = @import("render.zig");
fn view(input: render.image.Image) c.R4NvRenderPlane {
    return .{ .address = input.address, .byte_length = input.bytes, .modifier = 0,
        .width = input.width, .height = input.height, .pitch = input.pitch, .format = @intFromEnum(input.format) };
}
fn rect(input: render.Rect) c.R4NvRenderRect { return .{ .x = input.x, .y = input.y, .width = input.width, .height = input.height }; }
pub fn run(api: *const c.RenderV1) !void {
    var info: c.R4NvRenderInfo = undefined;
    try t.expectEqual(c.status_ok, api.render_info(0xc797, &info));
    try t.expect(info.version == 1 and info.size == 32 and info.shader_model == 86 and info.packet_bytes == 1280 and info.max_draws == 16);
    const admitted = info;
    try t.expectEqual(c.status_unsupported, api.render_info(0xc697, &info));
    try t.expectEqualDeep(admitted, info);
    var shader_bytes: [render.max_shader_bytes + 1]u8 = @splat(0xa5);
    var count: u32 = 99;
    try t.expectEqual(c.status_capacity, api.render_upload(0xc797, &shader_bytes, info.program_bytes - 1, &count));
    try t.expect(count == 99 and shader_bytes[0] == 0xa5);
    try t.expectEqual(c.status_ok, api.render_upload(0xc797, &shader_bytes, info.program_bytes, &count));
    try t.expect(count == info.program_bytes and shader_bytes[count] == 0xa5);
    // Shader/profile8 comes from the same matched upload, not a caller's code.
    try t.expectEqual(@as(u32,0x00025482), std.mem.readInt(u32, shader_bytes[render.shaderOffset(7)..][0..4], .little));
    const fixture = @import("render_test.zig").yuvFixture();
    const color = fixture.color_program.?;
    const matrix = fixture.yuv.?.matrix;
    const first: c.R4NvYuvDraw = .{ .luma = view(fixture.source.?), .chroma = view(fixture.yuv.?.chroma),
        .second_chroma = std.mem.zeroes(c.R4NvRenderPlane), .target = view(fixture.target),
        .source_rect = rect(fixture.source_rect), .destination = rect(fixture.destination), .scissor = rect(fixture.scissor),
        .format = 1, .filter = 1, .blend = 1, .opacity = 65535, .chroma_x = 0, .chroma_y = @bitCast(@as(f32,0.5)) };
    var draws: [16]c.R4NvYuvDraw = @splat(first);
    for (&draws, 0..) |*item, i| { item.scissor.x = @intCast(i); item.scissor.width = 1; }
    draws[1].opacity = 32768; draws[2].opacity = 1; draws[3].opacity = 0;
    var request: c.R4NvYuvRender = .{ .version = 1, .size = @sizeOf(c.R4NvYuvRender), .graphics_class = 0xc797,
        .draw_count = draws.len, .draws = @intFromPtr(&draws), .program_address = 0x300000, .program_bytes = info.program_bytes,
        .packet_address = 0x400000, .packet_bytes = draws.len * info.packet_bytes,
        .color_program = @intFromPtr(&color), .yuv_matrix = @intFromPtr(&matrix) };
    var commands: [render.max_words]u32 = @splat(0xa5a5a5a5);
    var packets: [render.packet_capacity_bytes]u8 = @splat(0xa5);
    try t.expectEqual(c.status_ok, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &count));
    try t.expect(count < commands.len and commands[count] == 0xa5a5a5a5);
    for (draws, 0..) |draw, i| {
        const expected: f32 = @as(f32, @floatFromInt(draw.opacity)) / 65535;
        try t.expectEqual(@as(u32, @bitCast(expected)), std.mem.readInt(u32, packets[i * 1280 + 804 ..][0..4], .little));
    }
    const command_snapshot = commands; const packet_snapshot = packets; const original = request;
    const accepted_count = count;
    draws[3].opacity = 65536;
    try t.expectEqual(c.status_invalid, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &count));
    draws[3].opacity = 0;
    try t.expectEqual(c.status_capacity, api.encode_yuv(&request, &commands, count - 1, &packets, packets.len, &count));
    try t.expectEqual(c.status_capacity, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len - 1, &count));
    draws[15].chroma.width -= 1;
    try t.expectEqual(c.status_invalid, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &count));
    draws[15].chroma.width += 1;
    request.packet_address = first.chroma.address; // GPU read/write alias.
    try t.expectEqual(c.status_unsupported, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &count));
    request = original;
    request.color_program = @intFromPtr(&commands); // CPU input/output alias.
    try t.expectEqual(c.status_invalid, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &count));
    request = original;
    try t.expectEqual(c.status_invalid, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &commands[0]));
    draws[15].target.modifier = 1; // Unknown tiling must not become linear.
    try t.expectEqual(c.status_unsupported, api.encode_yuv(&request, &commands, commands.len, &packets, packets.len, &count));
    try t.expectEqual(accepted_count, count);
    try t.expectEqualSlices(u32, &command_snapshot, &commands);
    try t.expectEqualSlices(u8, &packet_snapshot, &packets);
    std.debug.print("render public: matched upload, bounded YUV batch, output atomicity and CPU/GPU alias rejection: OK\n", .{});
}
