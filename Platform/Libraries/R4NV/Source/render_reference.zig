// GOB sector layout reference: Mesa nil/tiling.rs and nil/copy.rs.
// Copyright (c) 2024 Valve Corp. and Collabora, Ltd.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Host-only semantic execution of the bounded rectangle profile. Reads the
//! actual method stream, descriptors and uploaded constants/vertices. This
//! models f32 sampling/shader behavior; it is not an SM86 ISA emulator or a
//! claim of hardware execution. Frozen CPU/f64 images are the separate oracle.
const std = @import("std");
const r = @import("render.zig");
const hw = @import("Generated/Render/c797.zig");
const shaders = @import("Generated/Shaders/shaders.zig");
pub const cases = @import("render_reference_cases.zig");
const t = std.testing;
fn word(data: []const u8, at: usize) u32 { return std.mem.readInt(u32,data[at..][0..4],.little); }
fn scalar(data: []const u8, at: usize) f32 { return @bitCast(word(data,at)); }
pub fn method(data: []const u8, address: u32) !u32 {
    var at: usize = 0; var value: ?u32 = null;
    while (at < data.len) {
        if (at+4 > data.len) return error.Method;
        const header = word(data,at); const count = (header>>16)&0x1fff;
        if (header&0xe0000000 != 0x20000000 or count == 0 or at+(count+1)*4 > data.len) return error.Method;
        const start = (header&0x1fff)*4;
        for (0..count) |i| if (start+i*4 == address) { value = word(data,at+(i+1)*4); };
        at += (count+1)*4;
    }
    return value orelse error.Method;
}
fn wideMethod(data: []const u8, address: u32) !u64 { return (@as(u64,try method(data,address))<<32)|try method(data,address+4); }
fn boundConstants(data: []const u8, slot: u32) !u64 {
    var at: usize = 0; var result: ?u64 = null;
    while (at < data.len) {
        if (at + 4 > data.len) return error.Method;
        const header = word(data,at); const count = (header>>16)&0x1fff;
        if (header&0xe0000000 != 0x20000000 or count == 0 or at+(count+1)*4 > data.len) return error.Method;
        const start = (header&0x1fff)*4;
        const end = at+(count+1)*4;
        for (0..count) |i| if (start+i*4 == hw.BIND_GROUP_CONSTANT_BUFFER+128) {
            const value = word(data,at+(i+1)*4);
            if (value >> 4 == slot) result = if (value & 1 == 0) null else try wideMethod(data[0..end],hw.SET_CONSTANT_BUFFER_SELECTOR_A+4);
        };
        at = end;
    }
    return result orelse error.Method;
}
pub const Surface = struct {
    address: u64, width: u32, height: u32, pitch: u32, format: r.image.Format, bytes: []u8,
    layout: r.image.Layout = .linear, log2_gobs: u8 = 0,
    pub fn from(image: r.image.Image, bytes: []u8) Surface {
        return .{ .address = image.address, .width = image.width, .height = image.height, .pitch = image.pitch, .format = image.format, .bytes = bytes,
            .layout = image.layout, .log2_gobs = image.log2_gobs };
    }
    fn byteOffset(s: Surface, x: u32, y: u32) usize {
        if (s.layout == .linear) return @as(usize,y)*s.pitch+x;
        // TuringColor2D byte order: GOB rows, tile columns, then the six
        // intra-GOB fields in address order. The CE fixture uses a separate
        // sector lookup; the renderer never calls this host interpreter.
        const height = @as(usize,8)<<@intCast(s.log2_gobs);
        const column: usize = x; const row: usize = y;
        return (row/height)*s.pitch*height+(column/64)*512*(@as(usize,1)<<@intCast(s.log2_gobs)) +
            ((row%height)/8)*512+((column%64)/32)*256+((row%8)/4)*128+((column%32)/16)*64+((row%4)/2)*32+(row%2)*16+column%16;
    }
    fn load(s: Surface, x: u32, y: u32) [4]f32 {
        if (s.format == .r8) return .{ @as(f32,@floatFromInt(s.bytes[s.byteOffset(x,y)]))/255,0,0,1 };
        if (s.format == .abgr16161616f) {
            var rgba: [4]f32 = undefined;
            for (&rgba, 0..) |*value, i| value.* = @as(f16, @bitCast(std.mem.readInt(u16, s.bytes[s.byteOffset(x * 8 + @as(u32, @intCast(i)) * 2, y)..][0..2], .little)));
            return rgba;
        }
        const value = word(s.bytes,s.byteOffset(x*4,y));
        if (s.format == .xrgb2101010 or s.format == .argb2101010) return .{
            @as(f32, @floatFromInt((value >> 20) & 1023)) / 1023, @as(f32, @floatFromInt((value >> 10) & 1023)) / 1023,
            @as(f32, @floatFromInt(value & 1023)) / 1023, if (s.format == .argb2101010) @as(f32, @floatFromInt(value >> 30)) / 3 else 1,
        };
        var color: [4]f32 = undefined;
        for ([_]u5{16,8,0,24},0..) |shift,i| color[i] = @as(f32,@floatFromInt((value>>shift)&255))/255;
        if (s.format == .xrgb8888) color[3] = 1;
        return color;
    }
    fn store(s: Surface, x: u32, y: u32, color: [4]f32) !void {
        if (s.format == .abgr16161616f) {
            for (color, 0..) |v, i| {
                if (!std.math.isFinite(v)) return error.NonFinite;
                const half: f16 = @floatCast(std.math.clamp(v, @as(f32, if (i == 3) 0 else -65504), @as(f32, if (i == 3) 1 else 65504)));
                std.mem.writeInt(u16, s.bytes[s.byteOffset(x * 8 + @as(u32, @intCast(i)) * 2, y)..][0..2], @bitCast(half), .little);
            }
            return;
        }
        if (s.format == .xrgb2101010 or s.format == .argb2101010) {
            var encoded: u32 = 0;
            for ([_]u5{ 20, 10, 0, 30 }, 0..) |shift, i| {
                if (!std.math.isFinite(color[i])) return error.NonFinite;
                if (i != 3 or s.format == .argb2101010) encoded |= @as(u32, @intFromFloat(@round(std.math.clamp(color[i], 0, 1) * @as(f32, if (i == 3) 3 else 1023)))) << shift;
            }
            std.mem.writeInt(u32, s.bytes[s.byteOffset(x * 4, y)..][0..4], encoded, .little);
            return;
        }
        var value: u32 = 0;
        for ([_]u5{16,8,0,24},0..) |shift,i| {
            if (!std.math.isFinite(color[i])) return error.NonFinite;
            value |= @as(u32,@intFromFloat(@round(std.math.clamp(color[i],0,1)*255)))<<shift;
        }
        if (s.format == .r8) s.bytes[y*s.pitch+x] = @truncate(value>>16)
        else std.mem.writeInt(u32,s.bytes[y*s.pitch+x*4..][0..4],if (s.format == .xrgb8888) value&0xffffff else value,.little);
    }
};
fn sample(s: Surface, uv: [2]f32, linear: bool) [4]f32 {
    const width: f32 = @floatFromInt(s.width); const height: f32 = @floatFromInt(s.height);
    if (!linear) return s.load(@intFromFloat(std.math.clamp(@floor(uv[0]*width),0,width-1)),@intFromFloat(std.math.clamp(@floor(uv[1]*height),0,height-1)));
    const x = uv[0]*width-0.5; const y = uv[1]*height-0.5;
    const fx = @floor(x); const fy = @floor(y); const wx = x-fx; const wy = y-fy;
    const x0: u32 = @intFromFloat(std.math.clamp(fx,0,width-1)); const x1: u32 = @intFromFloat(std.math.clamp(fx+1,0,width-1));
    const y0: u32 = @intFromFloat(std.math.clamp(fy,0,height-1)); const y1: u32 = @intFromFloat(std.math.clamp(fy+1,0,height-1));
    const a = s.load(x0,y0); const b = s.load(x1,y0); const c = s.load(x0,y1); const d = s.load(x1,y1);
    var color: [4]f32 = undefined;
    for (0..4) |i| color[i] = (a[i]*(1-wx)+b[i]*wx)*(1-wy)+(c[i]*(1-wx)+d[i]*wx)*wy;
    return color;
}
pub fn transfer(color: [4]f32, encode: bool) [4]f32 {
    var out = color;
    for (0..3) |i| {
        const v = std.math.clamp(color[i]/(if (color[3] > 0) color[3] else 1),0,1);
        const result = if (encode) (if (v <= 0.0031308) 12.92*v else 1.055*std.math.pow(f32,v,1.0/2.4)-0.055)
            else (if (v <= 0.04045) v/12.92 else std.math.pow(f32,(v+0.055)/1.055,2.4));
        out[i] = result*color[3];
    }
    return out;
}
pub fn execute(methods: []const u8, packet: []const u8, program_address: u64, packet_address: u64, target: Surface, source: ?Surface) !void {
    return executeColor(methods,packet,program_address,packet_address,target,source,null);
}
// The consumer supplies an independent numerical oracle for its named-color
// case. This remains a host method/descriptor model, not an SM ISA emulator.
pub const ColorOracle = *const fn (r.ColorProgram, [4]f32, f32, u32, u32) anyerror![4]f32;
pub fn executeColor(methods: []const u8, packet: []const u8, program_address: u64, packet_address: u64, target: Surface, source: ?Surface, color_oracle: ?ColorOracle) !void {
    return executeColorFor(0xc797, methods, packet, program_address, packet_address, target, source, color_oracle);
}
pub fn executeColorFor(class: u32, methods: []const u8, packet: []const u8, program_address: u64, packet_address: u64, target: Surface, source: ?Surface, color_oracle: ?ColorOracle) !void {
    _ = r.profiles.get(class) orelse return error.Shader;
    if (packet.len == 0 or packet.len > r.packet_capacity_bytes or packet.len % r.packet_bytes != 0) return error.Surface;
    var at: usize = 0; var draws: usize = 0;
    while (at < methods.len) {
        if (at + 4 > methods.len) return error.Method;
        const header = word(methods, at); const count = (header >> 16) & 0x1fff;
        if (header & 0xe0000000 != 0x20000000 or count == 0 or at + (count + 1) * 4 > methods.len) return error.Method;
        const start = (header & 0x1fff) * 4;
        at += (count + 1) * 4;
        if (start <= hw.DRAW_VERTEX_ARRAY_BEGIN_END_A + 4 and start + count * 4 > hw.DRAW_VERTEX_ARRAY_BEGIN_END_A + 4) {
            if (draws == r.batch_capacity) return error.Method;
            const vertices = try wideMethod(methods[0..at], hw.SET_VERTEX_STREAM_A_FORMAT + 4);
            if (vertices < packet_address + 768) return error.Surface;
            const offset = vertices - packet_address - 768;
            if (offset % r.packet_bytes != 0 or offset > packet.len - r.packet_bytes) return error.Surface;
            try executeDraw(class, methods[0..at], packet[@intCast(offset)..][0..r.packet_bytes], program_address,
                packet_address + offset, target, source, color_oracle);
            draws += 1;
        }
    }
    if (draws == 0) return error.Method;
}
fn executeDraw(class: u32, methods: []const u8, packet: []const u8, program_address: u64, packet_address: u64, target: Surface, source: ?Surface, color_oracle: ?ColorOracle) !void {
    if (packet.len != r.packet_bytes or target.bytes.len < @as(u64,target.pitch)*target.height) return error.Surface;
    try t.expectEqual(class,try method(methods,hw.SET_OBJECT));
    try t.expectEqual(target.address,try wideMethod(methods,hw.SET_COLOR_TARGET_A));
    try t.expectEqual(target.pitch,try method(methods,hw.SET_COLOR_TARGET_A+8));
    try t.expectEqual(target.height,try method(methods,hw.SET_COLOR_TARGET_A+12));
    try t.expectEqual(@as(u32,switch (target.format) { .argb8888 => 0xcf, .xrgb8888 => 0xe6, .r8 => 0xf3,
        .xrgb2101010, .argb2101010 => 0xdf, .abgr16161616f => 0xca,
        .rg8, .r16, .rg16 => return error.Format }),try method(methods,hw.SET_COLOR_TARGET_A+16));
    try t.expectEqual(@as(u32,0x1000),try method(methods,hw.SET_COLOR_TARGET_A+20)); // Linear reference views only.
    try t.expectEqual(packet_address+768,try wideMethod(methods,hw.SET_VERTEX_STREAM_A_FORMAT+4));
    try t.expectEqual(@as(u32,40),try method(methods,hw.SET_VERTEX_STREAM_A_FORMAT)&0xfff);
    try t.expectEqual(@as(u32,4),try method(methods,hw.DRAW_VERTEX_ARRAY_BEGIN_END_A+4));
    var profile: ?u32 = null;
    var offset: u64 = 0;
    const fragment = try wideMethod(methods,hw.SET_PIPELINE_PROGRAM_ADDRESS_A+5*64);
    for (r.profiles.get(class).?.programs) |shader| {
        if (fragment == program_address+offset) profile = shader.profile;
        offset += std.mem.alignForward(u64,128+shader.code.len,128);
    }
    const id = profile orelse return error.Shader;
    if ((source == null and id != 5) or (source != null and (id < 2 or (id > 4 and id != 7))) or (id == 7 and color_oracle == null)) return error.Shader;
    var linear = false;
    if (source) |src| {
        if (src.bytes.len < @as(u64,src.pitch)*src.height) return error.Surface;
        try t.expectEqual(packet_address,try wideMethod(methods,hw.SET_TEX_HEADER_POOL_A));
        try t.expectEqual(packet_address+256,try wideMethod(methods,hw.SET_TEX_SAMPLER_POOL_A));
        try t.expectEqual(packet_address+512,try boundConstants(methods,1));
        if (id == 7) try t.expectEqual(packet_address+1024,try boundConstants(methods,2));
        try t.expectEqual(@as(u32,0),word(packet,512));
        try t.expectEqual(src.address,@as(u64,word(packet,4))|(@as(u64,word(packet,8)&0xffff)<<32));
        try t.expectEqual(@as(u32,if (src.layout == .linear) 2 else 3),(word(packet,8)>>21)&7);
        if (src.layout == .linear) try t.expectEqual(src.pitch,(word(packet,12)&0xffff)<<5)
        else {
            try t.expectEqual(@as(u32,src.log2_gobs)<<3,word(packet,12)&0xffff);
            try t.expect(src.pitch == std.mem.alignForward(u32,src.width*src.format.pixelBytes(),64));
        }
        try t.expectEqual(src.width,(word(packet,16)&0xffff)+1);
        try t.expectEqual(src.height,(word(packet,20)&0xffff)+1);
        try t.expectEqual(@as(u32,switch (src.format) { .argb8888 => 0x54e24908, .xrgb8888 => 0x74e24908, .r8 => 0x7010011d,
            .xrgb2101010 => 0x74e24909, .argb2101010 => 0x54e24909, .abgr16161616f => 0x58d7ff83,
            .rg8, .r16, .rg16 => return error.Format }),word(packet,0));
        try t.expectEqual(@as(u32,0x24092),word(packet,256));
        const filter = word(packet,260);
        if (filter != 0x91 and filter != 0xa2) return error.Sampler;
        linear = filter == 0xa2;
    }
    const over = try method(methods,hw.SET_BLEND) == 1;
    try t.expectEqual(@as(u32,0x4001),try method(methods,hw.SET_BLEND_PER_TARGET_SEPARATE_FOR_ALPHA+8));
    try t.expectEqual(@as(u32,if (over) 0x4303 else 0x4000),try method(methods,hw.SET_BLEND_PER_TARGET_SEPARATE_FOR_ALPHA+12));
    const sx: f32 = @bitCast(try method(methods,hw.SET_VIEWPORT_SCALE_X));
    const sy: f32 = @bitCast(try method(methods,hw.SET_VIEWPORT_SCALE_X+4));
    const ox: f32 = @bitCast(try method(methods,hw.SET_VIEWPORT_SCALE_X+12));
    const oy: f32 = @bitCast(try method(methods,hw.SET_VIEWPORT_SCALE_X+16));
    const x0 = scalar(packet,768)*sx+ox; const y0 = scalar(packet,772)*sy+oy;
    const x3 = scalar(packet,888)*sx+ox; const y3 = scalar(packet,892)*sy+oy;
    if (x3 <= x0 or y3 <= y0) return error.Vertex;
    const horizontal = try method(methods,hw.SET_SCISSOR_ENABLE+4);
    const vertical = try method(methods,hw.SET_SCISSOR_ENABLE+8);
    try t.expectEqual(@as(u32,1),try method(methods,hw.SET_SCISSOR_ENABLE));
    for (0..target.height) |y| for (0..target.width) |x| {
        const px = @as(f32,@floatFromInt(x))+0.5; const py = @as(f32,@floatFromInt(y))+0.5;
        if (x < horizontal&0xffff or x >= horizontal>>16 or y < vertical&0xffff or y >= vertical>>16 or px < x0 or px >= x3 or py < y0 or py >= y3) continue;
        var color: [4]f32 = @splat(1);
        if (source) |src| {
            const u = scalar(packet,784)+(px-x0)/(x3-x0)*(scalar(packet,904)-scalar(packet,784));
            const v = scalar(packet,788)+(py-y0)/(y3-y0)*(scalar(packet,908)-scalar(packet,788));
            color = sample(src,.{std.math.clamp(u,scalar(packet,528),scalar(packet,536)),std.math.clamp(v,scalar(packet,532),scalar(packet,540))},linear);
            if (word(packet, 544) != 0) {
                if ((id != 2 and id != 3 and id != 4 and id != 7) or linear) return error.Sampler;
                // Decode the actual uploaded CBuf, independently of Draw and
                // its admission helper. These are the shader's integer stages.
                const nx: i64 = @as(i64, @intCast(x)) + @as(i32, @bitCast(word(packet, 564)));
                const ny: i64 = @as(i64, @intCast(y)) + @as(i32, @bitCast(word(packet, 568)));
                const w: i64 = word(packet, 556); const h: i64 = word(packet, 560);
                const oriented: [2]i64 = switch (word(packet, 548)) {
                    0 => .{ nx, ny }, 1 => .{ h - 1 - ny, nx }, 2 => .{ w - 1 - nx, h - 1 - ny },
                    3 => .{ ny, w - 1 - nx }, else => return error.Sampler,
                };
                const scale: i64 = word(packet, 552);
                const lx = @divFloor((oriented[0] * 2 + 1) * 120, scale * 2) - @as(i32, @bitCast(word(packet, 576)));
                const ly = @divFloor((oriented[1] * 2 + 1) * 120, scale * 2) - @as(i32, @bitCast(word(packet, 580)));
                const tx = @divFloor(lx * word(packet, 592), word(packet, 584)) - word(packet, 600) + word(packet, 608);
                const ty = @divFloor(ly * word(packet, 596), word(packet, 588)) - word(packet, 604) + word(packet, 612);
                color = sample(src, .{ (@as(f32, @floatFromInt(tx)) + 0.5) / scalar(packet, 624),
                    (@as(f32, @floatFromInt(ty)) + 0.5) / scalar(packet, 628) }, false);
            }
            if (id == 3) color = transfer(color,false);
        }
        if (id == 7) {
            const program = std.mem.bytesToValue(r.ColorProgram,packet[1024..1280]);
            try program.validate();
            color = try color_oracle.?(program,color,scalar(packet,804),@intCast(x),@intCast(y));
        } else {
            for (0..4) |i| color[i] *= scalar(packet,792+i*4);
        }
        if (id == 4) color = transfer(color,true);
        if (over) {
            const background = target.load(@intCast(x),@intCast(y)); const inverse = 1-color[3];
            for (0..4) |i| color[i] += background[i]*inverse;
        }
        try target.store(@intCast(x),@intCast(y),color);
    };
}
pub fn compare(scene_index: usize, pixels: []const u8) !u8 {
    const scene = cases.scenes[scene_index];
    const expected = @embedFile("Fixtures/render-pixels.bin")[scene_index*cases.target_bytes..][0..cases.target_bytes];
    var maximum: u8 = 0;
    for (expected,pixels,0..) |want,actual,i| {
        const y = i/128; const byte_x = i%128; const bpp: usize = if (scene.format == .r8) 1 else 4;
        const drawn = byte_x < 32*bpp and scene.inside(@intCast(byte_x/bpp),@intCast(y));
        const difference = @max(want,actual)-@min(want,actual);
        if (difference > (if (drawn) scene.tolerance else @as(u8,0))) {
            std.debug.print("render {s}: byte {d} expected {d} actual {d} tolerance {d}\n",.{scene.name,i,want,actual,if (drawn) scene.tolerance else @as(u8,0)});
            return error.ReferenceMismatch;
        }
        maximum = @max(maximum,difference);
    }
    return maximum;
}
pub fn check() !void {
    for (cases.scenes,0..) |scene,i| {
        const draw = scene.draw();
        var source: [cases.source_bytes]u8 = undefined; var pixels: [cases.target_bytes]u8 = undefined;
        cases.initialize(scene,&source,&pixels);
        const binding: r.Binding = .{ .draw = draw, .programs = .{ .address = 0x300000, .bytes = r.shader_bytes }, .packet = .{ .address = 0x400000, .bytes = r.packet_bytes } };
        var program: r.Program = .{}; var packet: [r.packet_bytes]u8 = undefined;
        try r.packetUpload(draw,&packet); try r.encode(binding,&program);
        try execute(std.mem.sliceAsBytes(program.slice()),&packet,binding.programs.address,binding.packet.address,Surface.from(draw.target,&pixels),if (draw.source) |src| Surface.from(src,&source) else null);
        const maximum = try compare(i,&pixels);
        std.debug.print("render reference {s}: max={d}/{d} LSB\n",.{scene.name,maximum,scene.tolerance});
    }
    try checkGrids();
    try checkNearestBoundaries();
    try checkHighPrecision();
}
fn checkNearestBoundaries() !void {
    // Physical GA106 exposed one-neighbor errors exactly at the rational
    // centers of 64 -> 160. Consume the real packet/methods with independent
    // integer expected texels, including a cropped source and signed target.
    var source: [80 * 4]u8 = undefined;
    for (0..80) |x| std.mem.writeInt(u32, source[x * 4..][0..4], 0xff000000 | @as(u32, @intCast(x)) * 0x010101, .little);
    for ([_]i32{ 0, -2, 7 }) |origin| {
        var pixels: [768]u8 = @splat(0xcc);
        const draw: r.Draw = .{
            .source = .{ .address = 0x200000, .bytes = source.len, .width = 80, .height = 1, .pitch = 320, .format = .argb8888, .layout = .linear },
            .target = .{ .address = 0x100000, .bytes = pixels.len, .width = 176, .height = 1, .pitch = 768, .format = .argb8888, .layout = .linear },
            .source_rect = .{ .x = 5, .y = 0, .width = 64, .height = 1 },
            .destination = .{ .x = origin, .y = 0, .width = 160, .height = 1 },
            .scissor = .{ .x = 0, .y = 0, .width = 176, .height = 1 },
        };
        var packet: [r.packet_bytes]u8 = undefined;
        var program: r.Program = .{};
        try r.packetUpload(draw, &packet);
        try t.expectEqual(@as(u32, 1), word(&packet, 544)); // exact integer GPU path
        try r.encode(.{ .draw = draw, .programs = .{ .address = 0x300000, .bytes = r.shader_bytes }, .packet = .{ .address = 0x400000, .bytes = r.packet_bytes } }, &program);
        try execute(std.mem.sliceAsBytes(program.slice()), &packet, 0x300000, 0x400000, Surface.from(draw.target, &pixels), Surface.from(draw.source.?, &source));
        for (0..176) |x| {
            const relative = @as(i64, @intCast(x)) - origin;
            const expected: u32 = if (relative < 0 or relative >= 160) 0xcccccccc else
                0xff000000 | @as(u32, @intCast(5 + @divTrunc((relative * 2 + 1) * 64, 320))) * 0x010101;
            try t.expectEqual(expected, word(&pixels, x * 4));
        }
        for (pixels[704..]) |byte| try t.expectEqual(@as(u8, 0xcc), byte);
    }
}
fn checkHighPrecision() !void {
    // Follow an encoded native draw and its actual TIC/RT descriptors through
    // the independent host interpreter. Extended and negative linear samples
    // must survive FP16; the10-bit alpha and channel order remain distinct.
    var source_bytes: [128]u8 = @splat(0xcd);
    var target_bytes: [128]u8 = @splat(0xcc);
    var draw: r.Draw = .{
        .source = .{ .address = 0x200000, .bytes = 128, .width = 1, .height = 1, .pitch = 128, .format = .argb2101010, .layout = .linear },
        .target = .{ .address = 0x100000, .bytes = 128, .width = 1, .height = 1, .pitch = 128, .format = .abgr16161616f, .layout = .linear },
        .source_rect = .{ .x = 0, .y = 0, .width = 1, .height = 1 }, .destination = .{ .x = 0, .y = 0, .width = 1, .height = 1 },
        .scissor = .{ .x = 0, .y = 0, .width = 1, .height = 1 },
    };
    std.mem.writeInt(u32, source_bytes[0..4], 0xbff80000, .little);
    var packet: [r.packet_bytes]u8 = undefined;
    var program: r.Program = .{};
    const program_address = 0x300000; const packet_address = 0x400000;
    try r.packetUpload(draw, &packet);
    try r.encode(.{ .draw = draw, .programs = .{ .address = program_address, .bytes = r.shader_bytes }, .packet = .{ .address = packet_address, .bytes = r.packet_bytes } }, &program);
    try execute(std.mem.sliceAsBytes(program.slice()), &packet, program_address, packet_address, Surface.from(draw.target, &target_bytes), Surface.from(draw.source.?, &source_bytes));
    const actual = Surface.from(draw.target, &target_bytes).load(0, 0);
    for ([_]f32{ 1, 512.0 / 1023.0, 0, 2.0 / 3.0 }, actual) |expected, value| try t.expectApproxEqAbs(expected, value, 0.0004);
    try t.expectEqualSlices(u8, &(@as([120]u8, @splat(0xcc))), target_bytes[8..]);
    draw.source.?.format = .abgr16161616f;
    try Surface.from(draw.source.?, &source_bytes).store(0, 0, .{ -0.5, 2, 1.5, 0.5 });
    try r.packetUpload(draw, &packet);
    try r.encode(.{ .draw = draw, .programs = .{ .address = program_address, .bytes = r.shader_bytes }, .packet = .{ .address = packet_address, .bytes = r.packet_bytes } }, &program);
    try execute(std.mem.sliceAsBytes(program.slice()), &packet, program_address, packet_address, Surface.from(draw.target, &target_bytes), Surface.from(draw.source.?, &source_bytes));
    const extended = Surface.from(draw.target, &target_bytes).load(0, 0);
    try t.expectEqualSlices(f32, &.{ -0.5, 2, 1.5, 0.5 }, &extended);
}
fn checkGrids() !void {
    var source: [4096]u8 = @splat(0);
    for (0..16) |y| for (0..16) |x|
        std.mem.writeInt(u32, source[y * 256 + x * 4..][0..4], @intCast(0x102030 + y * 0x10000 + x * 0x100), .little);
    for ([_]u32{ 60, 120, 150, 180, 240 }) |scale| for (0..4) |rotation| {
        const logical_width = (8 * 120 + scale - 1) / scale;
        const logical_height = (6 * 120 + scale - 1) / scale;
        const swapped = rotation == 1 or rotation == 3;
        const draw: r.Draw = .{
            .target = .{ .address = 0x100000, .bytes = 4096, .width = 8, .height = 6, .pitch = 256, .format = .xrgb8888, .layout = .linear },
            .source = .{ .address = 0x200000, .bytes = 4096, .width = 16, .height = 16, .pitch = 256, .format = .xrgb8888, .layout = .linear },
            .destination = .{ .x = 0, .y = 0, .width = 8, .height = 6 }, .scissor = .{ .x = 0, .y = 0, .width = 8, .height = 6 },
            .source_rect = .{ .x = 0, .y = 0, .width = if (swapped) logical_height else logical_width, .height = if (swapped) logical_width else logical_height },
            .grid = .{ .enabled = 1, .scale = scale, .rotation = @intCast(rotation), .pixel_width = 8, .pixel_height = 6,
                .viewport_width = if (swapped) logical_height else logical_width, .viewport_height = if (swapped) logical_width else logical_height,
                .guest_width = if (swapped) logical_height else logical_width, .guest_height = if (swapped) logical_width else logical_height },
        };
        const binding: r.Binding = .{ .draw = draw, .programs = .{ .address = 0x300000, .bytes = r.shader_bytes }, .packet = .{ .address = 0x400000, .bytes = r.packet_bytes } };
        var program: r.Program = .{}; var packet: [r.packet_bytes]u8 = undefined; var pixels: [4096]u8 = @splat(0xcc);
        try r.packetUpload(draw, &packet); try r.encode(binding, &program);
        try execute(std.mem.sliceAsBytes(program.slice()), &packet, binding.programs.address, binding.packet.address,
            Surface.from(draw.target, &pixels), Surface.from(draw.source.?, &source));
        for (0..6) |y| for (0..8) |x| {
            const unrotated: [2]usize = switch (rotation) { 0 => .{x,y}, 1 => .{5-y,x}, 2 => .{7-x,5-y}, 3 => .{y,7-x}, else => unreachable };
            const sx = ((2 * unrotated[0] + 1) * 120) / (2 * scale);
            const sy = ((2 * unrotated[1] + 1) * 120) / (2 * scale);
            try t.expectEqual(word(&source, sy * 256 + sx * 4), word(&pixels, y * 256 + x * 4));
        };
        for (0..6) |row| for (pixels[row * 256 + 32..][0..224]) |byte| try t.expectEqual(@as(u8, 0xcc), byte);
        var bad = draw; bad.grid.guest_width = 32769;
        const previous = packet;
        try t.expectError(error.Bounds, r.packetUpload(bad, &packet));
        try t.expectEqualSlices(u8, &previous, &packet);
    };
    std.debug.print("render grid: actual descriptors, four rotations, 50/100/125/150/200 percent, integer texel centers: OK\n", .{});
}
