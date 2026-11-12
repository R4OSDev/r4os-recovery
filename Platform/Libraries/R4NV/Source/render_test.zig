const std = @import("std");
const t = std.testing;
const render = @import("render.zig");
const hw = @import("Generated/Render/c797.zig");
fn word(data: []const u8, offset: usize) u32 { return std.mem.readInt(u32, data[offset..][0..4], .little); }
fn state(program: *const render.Program, method: u32) !u32 {
    var at: usize = 0;
    var found: ?u32 = null;
    while (at < program.count) {
        const header = program.data[at];
        try t.expectEqual(@as(u32,0x20000000), header & 0xe0000000);
        const count = (header >> 16) & 0x1fff;
        try t.expect(count > 0 and at + count < program.count);
        const start = (header & 0x1fff) * 4;
        for (0..count) |index| if (start + index * 4 == method) { found = program.data[at+1+index]; };
        at += count + 1;
    }
    return found orelse error.MissingState;
}
pub fn check() !void {
    try render.reference_model.check();
    try checkColorPackets();
    try checkYuvPackets();
    try checkEncodePackets();
    var binding: render.Binding = .{
        .draw = .{
            .target = .{ .address = 0x100000, .bytes = 65536, .width = 128, .height = 128, .pitch = 512, .format = .argb8888, .layout = .linear },
            .source = .{ .address = 0x200000, .bytes = 16384, .width = 64, .height = 64, .pitch = 256, .format = .argb8888, .layout = .linear },
            .destination = .{ .x = -16, .y = 0, .width = 128, .height = 64 },
            .source_rect = .{ .x = 0, .y = 0, .width = 64, .height = 64 },
            .scissor = .{ .x = 0, .y = 8, .width = 64, .height = 64 }, .blend = .over, .opacity = 128,
        },
        .programs = .{ .address = 0x300000, .bytes = render.shader_bytes },
        .packet = .{ .address = 0x400000, .bytes = render.packet_bytes },
    };
    var packet: [render.packet_bytes]u8 = undefined;
    try checkGenerations(binding);
    // Disjoint scissor slices cover the original clipped draw exactly once,
    // while UV interpolation and blend coordinates remain unchanged.
    var visited: [128 * 128]bool = @splat(false);
    var slice_offset: u64 = 0;
    while (true) {
        const part = try render.slice(binding.draw, slice_offset, 70);
        try t.expect(part.next > slice_offset and part.next - slice_offset <= 70);
        try t.expectEqualDeep(binding.draw.destination, part.draw.destination);
        try t.expectEqualDeep(binding.draw.source_rect, part.draw.source_rect);
        try t.expectEqualDeep(binding.draw.grid, part.draw.grid);
        const clip = try part.draw.clip();
        for (clip[1]..clip[3]) |y| for (clip[0]..clip[2]) |x| {
            try t.expect(!visited[y * 128 + x]); visited[y * 128 + x] = true;
        };
        slice_offset = part.next;
        if (part.next == part.total) break;
    }
    const original_clip = try binding.draw.clip();
    for (0..128) |y| for (0..128) |x| {
        try t.expectEqual(x >= original_clip[0] and x < original_clip[2] and y >= original_clip[1] and y < original_clip[3], visited[y * 128 + x]);
    };
    try t.expectError(error.Bounds, render.slice(binding.draw, slice_offset, 70));
    var program: render.Program = .{};
    var shader_data: [render.shader_bytes]u8 = undefined;
    try render.shaderUpload(&shader_data);
    try t.expectEqual(@as(u32,0x02020481), word(&shader_data,0));
    try t.expectEqual(@as(u32,0x00025482), word(&shader_data,render.shaderOffset(1)));
    try render.packetUpload(binding.draw, &packet);
    const top_left: render.Vertex = @bitCast(packet[768..808].*);
    const bottom_right: render.Vertex = @bitCast(packet[888..928].*);
    try t.expectEqualSlices(f32, &.{-1.25,-1,0,1}, &top_left.position);
    try t.expectEqualSlices(f32, &.{0.75,0,0,1}, &bottom_right.position);
    try t.expectEqualSlices(f32, &.{0,0}, &top_left.uv);
    try t.expectEqualSlices(f32, &.{1,1}, &bottom_right.uv);
    try t.expectApproxEqAbs(@as(f32,128.0/255.0), top_left.tint[3], 0.000001);
    try t.expectEqualSlices(u8, &(@as([160]u8,@splat(0))), packet[352..512]);
    try render.encode(binding,&program);
    try t.expect(program.count < render.max_words - 11);
    try t.expectEqual(@as(u32,1), try state(&program,hw.SET_SCISSOR_ENABLE));
    try t.expectEqual(@as(u32,64<<16), try state(&program,hw.SET_SCISSOR_ENABLE+4));
    try t.expectEqual(@as(u32,8|(64<<16)), try state(&program,hw.SET_SCISSOR_ENABLE+8));
    try t.expectEqual(@as(u32,4), try state(&program,hw.DRAW_VERTEX_ARRAY_BEGIN_END_A+4));
    try t.expectEqual(@as(u32,1), try state(&program,hw.SET_BLEND));
    try t.expectEqual(@as(u32,0x4303), try state(&program,hw.SET_BLEND_PER_TARGET_SEPARATE_FOR_ALPHA+12));
    try t.expectEqual(@as(u32,160), try state(&program,hw.SET_VERTEX_STREAM_SIZE_A+4));
    try t.expectEqual(@as(u32,0x11), try state(&program,hw.BIND_GROUP_CONSTANT_BUFFER+128));
    try t.expectEqual(@as(u32,4), try state(&program,hw.SET_PIPELINE_BINDING+5*64));
    // Maximal sampled lists fit the existing 4 KB ring. Geometry and alpha
    // have separate packets; immutable shader/target state is encoded once.
    var draws: [render.batch_capacity]render.Draw = @splat(binding.draw);
    for (&draws, 0..) |*draw, index| { draw.opacity = @intCast(index + 1); draw.scissor.x = @intCast(index); }
    var packets: [render.packet_capacity_bytes]u8 = undefined;
    var batch = binding; batch.draw = draws[0]; batch.additional = draws[1..]; batch.packet.bytes = packets.len;
    try render.packetUploadList(&draws, &packets);
    try render.encode(batch, &program);
    try t.expect(program.count + 11 <= 1024);
    try t.expectEqual(@as(u32,@intCast(binding.packet.address + 15 * render.packet_bytes + 768)), try state(&program, hw.SET_VERTEX_STREAM_A_FORMAT + 8));
    for (draws, 0..) |draw, index| {
        const vertex: render.Vertex = @bitCast(packets[index * render.packet_bytes + 768..][0..40].*);
        try t.expectApproxEqAbs(@as(f32,@floatFromInt(draw.opacity)) / 255.0, vertex.tint[3], 0.000001);
    }
    const unchanged = packets;
    draws[15].target.address += 65536;
    try t.expectError(error.Unsupported, render.packetUploadList(&draws, &packets));
    try t.expectEqualSlices(u8, &unchanged, &packets);
    std.debug.print("render list: 16 sampled draws; {d} words including one release; {d} upload bytes\n", .{program.count + 11, packets.len});
    // Every fixed fragment profile binds its own immutable header/code pair.
    for ([_]render.Transfer{.identity,.decode_srgb,.encode_srgb}) |transfer| {
        binding.draw.transfer = transfer;
        try render.encode(binding,&program);
        try t.expectEqual(@as(u32,@intCast(binding.programs.address+render.shaderOffset(binding.draw.profile()-1))), try state(&program,hw.SET_PIPELINE_PROGRAM_ADDRESS_A+5*64+4));
    }
    binding.draw.transfer = .identity;
    binding.draw.source = null;
    binding.draw.color = 0x80402010;
    try render.packetUpload(binding.draw,&packet);
    const solid: render.Vertex = @bitCast(packet[768..808].*);
    try t.expectApproxEqAbs(@as(f32,64.0/255.0*128.0/255.0), solid.tint[0], 0.000001);
    try render.encode(binding,&program);
    try t.expectEqual(@as(u32,0x10), try state(&program,hw.BIND_GROUP_CONSTANT_BUFFER+128));
    try t.expectEqual(@as(u32,@intCast(binding.programs.address+render.shaderOffset(5))), try state(&program,hw.SET_PIPELINE_PROGRAM_ADDRESS_A+64+4));
    try t.expectEqual(@as(u32,0xf0f),word(&shader_data,render.shaderOffset(5)+24));
    binding.draw.color = 0x40ff0000;
    try t.expectError(error.Bounds,render.packetUpload(binding.draw,&packet));
    binding.draw.color = 0x80402010;
    binding.draw.scissor.x = 200;
    try t.expectError(error.Empty,render.encode(binding,&program));
    binding.draw.scissor.x = 0;
    binding.programs.address += 4;
    try t.expectError(error.Bounds,render.encode(binding,&program));
    binding.programs.address -= 4;
    binding.packet.address = binding.draw.target.address;
    try t.expectError(error.Unsupported,render.encode(binding,&program));
    binding.packet.address = 0x400000;
    binding.draw.source = binding.draw.target;
    try t.expectError(error.Unsupported,render.encode(binding,&program));
    binding.draw.source = null;
    binding.draw.target.address = 1<<40;
    _ = try render.image.texture(binding.draw.target);
    try t.expectError(error.Unsupported,render.encode(binding,&program));
}

fn checkEncodePackets() !void {
    var draw: render.Draw = .{
        .target = .{ .address = 0x100000, .bytes = 4096, .width = 64, .height = 24, .pitch = 64, .format = .r8, .layout = .blocklinear, .log2_gobs = 1 },
        .source = .{ .address = 0x200000, .bytes = 4096, .width = 62, .height = 46, .pitch = 64, .format = .r8, .layout = .blocklinear, .log2_gobs = 1 },
        .encode_input = .{ .format = .nv12, .plane = .chroma, .extent = .{62, 46},
            .chroma = .{ .address = 0x210000, .bytes = 2048, .width = 31, .height = 23, .pitch = 64, .format = .rg8, .layout = .blocklinear, .log2_gobs = 1 } },
        .destination = .{ .x = 0, .y = 0, .width = 64, .height = 24 },
        .source_rect = .{ .x = 0, .y = 0, .width = 62, .height = 46 },
        .scissor = .{ .x = 0, .y = 0, .width = 64, .height = 24 },
    };
    var packet: [render.packet_bytes]u8 = undefined;
    for ([_]bool{ false, true }) |planar| {
        draw.encode_input.?.format = if (planar) .yuv420p else .nv12;
        draw.encode_input.?.chroma.format = if (planar) .r8 else .rg8;
        draw.encode_input.?.second = if (planar) draw.encode_input.?.chroma else null;
        if (draw.encode_input.?.second) |*second| second.address = 0x220000;
        try render.packetUpload(draw, &packet);
        try t.expectEqual(@as(u32, 9), draw.profile());
        try t.expectEqual(@as(u32, 0x6010021d), word(&packet, 0));
        try t.expectEqual(@as(u32, if (planar) 0x6010021d else 0x60d01218), word(&packet, 32));
        for ([_]u32{ if (planar) 3 else 1, 1, 64, 62, 46 }, 0..) |value, i| try t.expectEqual(value, word(&packet, 256 + 4 * i));
        try t.expect(std.mem.allEqual(u8, packet[276..512], 0));
        for (render.profiles.catalog) |profile| {
            var program: render.Program = .{};
            try render.encode(.{ .class = profile.class, .draw = draw,
                .programs = .{ .address = 0x300000, .bytes = profile.bytes() },
                .packet = .{ .address = 0x400000, .bytes = render.packet_bytes } }, &program);
            try t.expectEqual(@as(u32, 0x300000 + profile.offset(5)), try state(&program, hw.SET_PIPELINE_PROGRAM_ADDRESS_A + 64 + 4));
            try t.expectEqual(@as(u32, 0x300000 + profile.offset(8)), try state(&program, hw.SET_PIPELINE_PROGRAM_ADDRESS_A + 5 * 64 + 4));
            try t.expectError(error.MissingState, state(&program, hw.SET_TEX_SAMPLER_POOL_A));
            try t.expectEqual(@as(u32, 0x31), try state(&program, hw.BIND_GROUP_CONSTANT_BUFFER + 128));
            try t.expectEqual(@as(u32, if (planar) 2 else 1), try state(&program, hw.SET_TEX_HEADER_POOL_A + 8));
            try t.expect(program.count + 11 <= 1024);
            var batch: [render.batch_capacity]render.Draw = @splat(draw);
            for (&batch, 0..) |*entry, i| entry.scissor = .{ .x = 0, .y = @intCast(i), .width = 64, .height = 1 };
            try render.encode(.{ .class = profile.class, .draw = batch[0], .additional = batch[1..],
                .programs = .{ .address = 0x300000, .bytes = profile.bytes() },
                .packet = .{ .address = 0x400000, .bytes = render.packet_capacity_bytes } }, &program);
            try t.expect(program.count + 11 <= 1024);
        }
        // Arbitrary scissor slicing must preserve the shader's global pixel
        // coordinates. Full input/target geometry and CBuf3 remain unchanged.
        const part = try render.slice(draw, 17, 70);
        var sliced: [render.packet_bytes]u8 = undefined;
        try render.packetUpload(part.draw, &sliced);
        try t.expectEqualSlices(u8, packet[256..512], sliced[256..512]);
    }
    const good = draw;
    draw.encode_input.?.second.?.address = draw.target.address;
    const before = packet;
    try t.expectError(error.Unsupported, render.packetUpload(draw, &packet));
    try t.expectEqualSlices(u8, &before, &packet);
    draw = good; draw.opacity = 254;
    try t.expectError(error.Unsupported, draw.validate());
    draw = good; draw.source_rect.width -= 2;
    try t.expectError(error.Unsupported, draw.validate());
    draw = good; draw.target.layout = .linear;
    try t.expectError(error.Unsupported, draw.validate());
    draw = good; draw.encode_input.?.second = null;
    try t.expectError(error.Bounds, draw.validate());
    draw = good; draw.source.?.width = 64; draw.source.?.height = 48;
    draw.encode_input.?.chroma.width = 32; draw.encode_input.?.chroma.height = 24;
    draw.encode_input.?.second.?.width = 32; draw.encode_input.?.second.?.height = 24;
    try render.packetUpload(draw, &packet);
    try t.expectEqual(@as(u32, 62), word(&packet, 268));
    try t.expectEqual(@as(u32, 46), word(&packet, 272));
    try t.expectEqual(@as(u32, 47) | (1 << 31), word(&packet, 20)); // Full TIC storage height.
    draw = good; draw.encode_input.?.plane = .luma;
    try t.expectError(error.Unsupported, draw.validate()); // Wrong target rows.
    draw.target.height = 48; draw.target.bytes = 6144; draw.destination.height = 48; draw.scissor.height = 48;
    try render.packetUpload(draw, &packet);
    try t.expectEqual(@as(u32, 0), word(&packet, 260));
    std.debug.print("render encode input: NV12/I420 integer planes, padding geometry, alias rejection and sliced packing commands: OK\n", .{});
}

fn checkGenerations(original: render.Binding) !void {
    var bytes: [render.max_shader_bytes]u8 = undefined;
    var stream: render.Program = .{};
    // Pinned class headers: shader cache is enabled from Ada, and VPRS
    // selection exists from Ampere. Pipeline addresses use a 64-byte stride.
    for ([_]u32{0xc597,0xc797,0xc997,0xcd97}, [_]u16{75,86,89,120}) |class, sm| {
        const profile = render.profiles.get(class).?;
        try t.expectEqual(sm, profile.sm);
        var binding = original; binding.class = class; binding.programs.bytes = profile.bytes();
        try render.shaderUploadFor(class, bytes[0..profile.bytes()]);
        try render.encode(binding, &stream);
        // GA106 rejected the old 0x1140/data=1 command. NVIDIA class
        // headers place SNORM8_UNORM16_SNORM16 in bit 4, leaving bit 0
        // reserved. Check the emitted stream for every supported class.
        try t.expectEqual(@as(u32, 0x10), try state(&stream, 0x1140));
        // GA106 rejects the additional raster override 0x0fb8. The pinned
        // NVK path configures samples with SET_ANTI_ALIAS (0x15d0) only.
        try t.expectError(error.MissingState, state(&stream, 0x0fb8));
        try t.expectError(error.MissingState, state(&stream, 0x0fa4));
        try t.expectEqual(@as(u32, 0), try state(&stream, 0x15d0));
        for ([_]u32{0x0fbc,0x0fc0,0x0fc4,0x0fc8}) |method|
            try t.expectEqual(@as(u32, 0xffff), try state(&stream, method));
        try t.expectEqual(class, try state(&stream, 0));
        // Render-target surface clip is independent of viewport/scissor.
        // A fresh context must not retain an empty surface clip rectangle.
        try t.expectEqual(binding.draw.target.width << 16, try state(&stream, 0x0ff4));
        try t.expectEqual(binding.draw.target.height << 16, try state(&stream, 0x0ff8));
        try t.expectEqual(@as(u32,@intFromBool(class >= 0xc997)), try state(&stream, 0x0d94));
        if (class == 0xc597) try t.expectError(error.MissingState, state(&stream, 0x02cc))
        else try t.expectEqual(@as(u32,2), try state(&stream, 0x02cc));
        try t.expectEqual(@as(u32,@intCast(binding.programs.address + profile.offset(1))),
            try state(&stream, 0x2018 + 5 * 64));
        // C597 has address A/B but no PREFETCH method. The seven-bit
        // block count exists only from C797, for both bound stages.
        for ([_]u32{1, 5}, [_]usize{0, 1}) |pipeline, shader_index| {
            const method = 0x201c + pipeline * 64;
            if (class == 0xc597) {
                try t.expectError(error.MissingState, state(&stream, method));
            } else {
                const blocks = try state(&stream, method);
                try t.expect(blocks > 0 and blocks <= 127);
                try t.expect(@as(usize, blocks) * 256 >= 128 + profile.programs[shader_index].code.len or blocks == 127);
            }
        }
        try t.expectEqual(@as(u32,0x00025482), word(&bytes, profile.offset(1)));
        binding.programs.bytes -= 1;
        try t.expectError(error.Bounds, render.encode(binding, &stream));
    }
    var bad = original; bad.class = 0xc697;
    try t.expectError(error.Unsupported, render.encode(bad, &stream));
    @memset(&bytes, 0xa5);
    try t.expectError(error.Unsupported, render.shaderUploadFor(0xc697, &bytes));
    try t.expectEqual(@as(u8,0xa5), bytes[0]);
}

fn checkColorPackets() !void {
    var color: render.ColorProgram = .{};
    color.words[0..5].* = .{ 3, 2, 3, 4, 1 };
    for ([_]usize{32,80}) |base| for (0..3) |i| { color.words[(base + i * 20) / 4] = @bitCast(@as(f32,1)); };
    const scalars = [_]f32{203,1000,1,0, 203,1000,1,0, 1,0,1,0, 1,1000,750,250, 1000,1.0/1023.0};
    for (scalars, 32..) |value, i| color.words[i] = @bitCast(value);
    var video_color = color;
    video_color.words[1] = 6;
    video_color.words[35] = @bitCast(@as(f32, 0.0562341325));
    try video_color.validate();
    video_color.words[2] = 5; // ICC is not executable by the fixed named-color shader.
    try t.expectError(error.Unsupported, video_color.validate());
    const draw: render.Draw = .{
        .target = .{ .address = 0x100000, .bytes = 65536, .width = 128, .height = 128, .pitch = 512, .format = .xrgb2101010, .layout = .linear },
        .source = .{ .address = 0x200000, .bytes = 131072, .width = 128, .height = 128, .pitch = 1024, .format = .abgr16161616f, .layout = .linear },
        .destination = .{ .x = 0, .y = 0, .width = 128, .height = 128 },
        .source_rect = .{ .x = 0, .y = 0, .width = 128, .height = 128 },
        .scissor = .{ .x = 0, .y = 0, .width = 128, .height = 128 }, .transfer = .color, .color_program = color,
    };
    var draws: [render.batch_capacity]render.Draw = @splat(draw);
    for (&draws, 0..) |*item, i| item.grid = .{ .enabled = 1, .rotation = @intCast(i % 4), .scale = 120,
        .pixel_width = 128, .pixel_height = 128, .viewport_width = 128, .viewport_height = 128,
        .guest_width = 128, .guest_height = 128 };
    var packets: [render.packet_capacity_bytes]u8 = undefined;
    try render.packetUploadList(&draws, &packets);
    for (0..draws.len) |i| {
        try t.expectEqualSlices(u8, std.mem.asBytes(&color), packets[i*render.packet_bytes+1024..][0..256]);
        try t.expectEqualSlices(u8, std.mem.asBytes(&draws[i].grid), packets[i*render.packet_bytes+544..][0..64]);
    }
    var program: render.Program = .{};
    const binding: render.Binding = .{ .draw = draws[0], .additional = draws[1..],
        .programs = .{ .address = 0x300000, .bytes = render.shader_bytes }, .packet = .{ .address = 0x400000, .bytes = packets.len } };
    try render.encode(binding, &program);
    try t.expect(program.count + 11 <= 1024);
    try t.expectEqual(@as(u32,0x21), try state(&program,hw.BIND_GROUP_CONSTANT_BUFFER+128));
    try t.expectEqual(@as(u32,0x400000+15*render.packet_bytes+1024), try state(&program,hw.SET_CONSTANT_BUFFER_SELECTOR_A+8));
    try t.expectEqual(@as(u32,0x300000+render.shaderOffset(6)), try state(&program,hw.SET_PIPELINE_PROGRAM_ADDRESS_A+5*64+4));
    const untouched = packets;
    draws[15].color_program.?.words[32] = @bitCast(std.math.nan(f32));
    try t.expectError(error.Bounds, render.packetUploadList(&draws, &packets));
    try t.expectEqualSlices(u8, &untouched, &packets);
    draws[15] = draw; draws[15].filter = .bilinear;
    try t.expectError(error.Unsupported, render.packetUploadList(&draws, &packets));
    draws[15] = draw; draws[15].blend = .over;
    try t.expectError(error.Unsupported, render.packetUploadList(&draws, &packets));
    std.debug.print("render color: FP16 to XR30, copied CBuf2,16 draws fit4KB ring, invalid/torn programs rejected: OK\n", .{});
}

pub fn yuvFixture() render.Draw {
    var color: render.ColorProgram = .{};
    color.words[0..5].* = .{ 0, 6, 2, 1, 4 };
    for ([_]usize{32,80}) |base| for (0..3) |i| { color.words[(base + i * 20) / 4] = @bitCast(@as(f32,1)); };
    const scalars = [_]f32{203,203,1,0, 203,203,1,0, 1,0,1,0, 1,203,150,53, 203,0};
    for (scalars, 32..) |value, i| color.words[i] = @bitCast(value);
    return .{
        .target = .{ .address = 0x100000, .bytes = 2048, .width = 16, .height = 16, .pitch = 128, .format = .abgr16161616f, .layout = .linear },
        .source = .{ .address = 0x200000, .bytes = 160, .width = 7, .height = 5, .pitch = 32, .format = .r8, .layout = .linear },
        .yuv = .{ .format = .nv12,
            .chroma = .{ .address = 0x210000, .bytes = 96, .width = 4, .height = 3, .pitch = 32, .format = .rg8, .layout = .linear },
            .matrix = .{ .{1.1643836,0,1.7927411,-0.9729451}, .{1.1643836,-0.2132486,-0.5329093,0.3014827}, .{1.1643836,2.1124018,0,-1.1334022} },
            .origin = .{0,0.5} },
        .destination = .{ .x = -1, .y = 0, .width = 18, .height = 16 },
        .source_rect = .{ .x = 1, .y = 1, .width = 5, .height = 3 },
        .scissor = .{ .x = 0, .y = 0, .width = 16, .height = 16 },
        .transfer = .color, .color_program = color, .filter = .bilinear, .blend = .over,
    };
}
fn checkYuvPackets() !void {
    var draw = yuvFixture();
    const color = draw.color_program.?;
    var packet: [render.packet_bytes]u8 = undefined;
    var program: render.Program = .{};
    for ([_]u32{1,2,3}) |format| {
        draw.yuv.?.format = @enumFromInt(format);
        draw.source.?.format = if (format == 2) .r16 else .r8;
        draw.yuv.?.chroma.format = switch (format) { 1 => .rg8, 2 => .rg16, else => .r8 };
        draw.yuv.?.second = if (format == 3) draw.yuv.?.chroma else null;
        if (draw.yuv.?.second) |*second| second.address = 0x220000;
        try render.packetUpload(draw, &packet);
        // Independent class-header anchors: UINT (not UNORM), separate TIC
        // indices, six-bit P010 shift and absolute odd-crop sample centers.
        try t.expectEqual(@as(u32, if (format == 2) 0x6010021b else 0x6010021d), word(&packet, 0));
        try t.expectEqual(@as(u32, switch (format) { 1 => 0x60d01218, 2 => 0x60d0120c, else => 0x6010021d }), word(&packet, 32));
        try t.expectEqual(format, word(&packet, 256));
        try t.expectEqual(@as(u32,1), word(&packet, 260));
        try t.expectEqual(@as(u32, if (format == 2) 6 else 0), word(&packet, 332));
        try t.expectEqual(@as(u32,0), word(&packet, 512));
        try t.expectEqual(@as(u32,1), word(&packet, 516));
        if (format == 3) try t.expectEqual(@as(u32,2), word(&packet, 520));
        for ([_]f32{1,1,5,3}, 0..) |value, i| try t.expectEqual(@as(u32,@bitCast(value)), word(&packet, 336 + i * 4));
        try t.expectEqualSlices(u8, std.mem.asBytes(&color), packet[1024..1280]);
        var draws: [render.batch_capacity]render.Draw = @splat(draw);
        for (&draws, 0..) |*item, i| { item.scissor.x = @intCast(i); item.scissor.width = 1; }
        for ([_]u32{0xc597,0xc797,0xc997,0xcd97}) |class| {
            const profile = render.profiles.get(class).?;
            const binding: render.Binding = .{ .class = class, .draw = draws[0], .additional = draws[1..],
                .programs = .{ .address = 0x300000, .bytes = profile.bytes() },
                .packet = .{ .address = 0x400000, .bytes = render.packet_capacity_bytes } };
            try render.encode(binding, &program);
            try t.expect(program.count + 11 <= 1024);
            try t.expectEqual(@as(u32,if (format == 3) 2 else 1), try state(&program, hw.SET_TEX_HEADER_POOL_A+8));
            try t.expectError(error.MissingState, state(&program, hw.SET_TEX_SAMPLER_POOL_A));
            try t.expectEqual(@as(u32,0x31), try state(&program, hw.BIND_GROUP_CONSTANT_BUFFER+128));
            try t.expectEqual(@as(u32,0x400000+15*render.packet_bytes+256), try state(&program, hw.SET_CONSTANT_BUFFER_SELECTOR_A+8));
            try t.expectEqual(@as(u32,0x300000+profile.offset(7)), try state(&program, hw.SET_PIPELINE_PROGRAM_ADDRESS_A+5*64+4));
        }
    }
    const original = draw;
    const before = packet;
    draw.yuv.?.second.?.address = draw.target.address;
    try t.expectError(error.Unsupported, render.packetUpload(draw, &packet));
    try t.expectEqualSlices(u8, &before, &packet);
    draw = original; draw.yuv.?.chroma.width -= 1;
    try t.expectError(error.Bounds, draw.validate());
    draw = original; draw.yuv.?.origin[1] = 0.25;
    try t.expectError(error.Bounds, draw.validate());
    draw = original; draw.yuv.?.matrix[0][0] = std.math.nan(f32);
    try t.expectError(error.Bounds, draw.validate());
    draw = original; draw.color_program = null;
    try t.expectError(error.Unsupported, draw.validate());
    draw = original; draw.grid.enabled = 1;
    try t.expectError(error.Unsupported, draw.validate());
    draw = original; draw.color_program.?.words[3] = 4;
    try t.expectError(error.Unsupported, draw.validate());
    std.debug.print("render YUV: 3 integer plane layouts, odd crop, P010 packing, four classes,16 draws fit4KB ring: OK\n", .{});
}
