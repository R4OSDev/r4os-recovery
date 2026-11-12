// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Public pure encoder. No kernel resource, queue or hardware policy lives here.
const std = @import("std");
const c = @import("r4l_contract");
const render = @import("render.zig");
const modifier_base: u64 = 0x0300000000606010;

const Span = struct {
    address: u64,
    bytes: u64,
    fn valid(self: Span, alignment: u64) bool {
        return self.address != 0 and self.address % alignment == 0 and self.bytes != 0 and
            self.bytes <= std.math.maxInt(u64) - self.address;
    }
    fn overlaps(self: Span, other: Span) bool {
        return self.address < other.address + other.bytes and other.address < self.address + self.bytes;
    }
};
fn object(value: anytype) Span {
    return .{ .address = @intFromPtr(value), .bytes = @sizeOf(@typeInfo(@TypeOf(value)).pointer.child) };
}
fn status(err: render.Error) i32 {
    return if (err == error.Unsupported) c.status_unsupported else c.status_invalid;
}
pub fn r4nv_render_info_impl(class: u32, output: *c.R4NvRenderInfo) callconv(.c) i32 {
    if (!object(output).valid(@alignOf(c.R4NvRenderInfo))) return c.status_invalid;
    const profile = render.profiles.get(class) orelse return c.status_unsupported;
    output.* = .{ .version = 1, .size = @sizeOf(c.R4NvRenderInfo), .graphics_class = class, .shader_model = profile.sm,
        .program_bytes = profile.bytes(), .packet_bytes = render.packet_bytes,
        .max_command_words = render.max_words, .max_draws = render.batch_capacity };
    return c.status_ok;
}
pub fn r4nv_render_upload_impl(class: u32, bytes: [*]u8, capacity: u32, written: *u32) callconv(.c) i32 {
    const profile = render.profiles.get(class) orelse return c.status_unsupported;
    if (capacity < profile.bytes()) return c.status_capacity;
    const storage: Span = .{ .address = @intFromPtr(bytes), .bytes = capacity };
    if (!storage.valid(1) or !object(written).valid(4) or storage.overlaps(object(written))) return c.status_invalid;
    render.shaderUploadFor(class, bytes[0..profile.bytes()]) catch unreachable;
    written.* = profile.bytes();
    return c.status_ok;
}
fn view(input: c.R4NvRenderPlane) render.Error!render.image.Image {
    if (input.modifier != 0 and (input.modifier & ~@as(u64,15) != modifier_base or input.modifier & 15 > 5)) return error.Unsupported;
    return .{ .address = input.address, .bytes = input.byte_length,
        .width = input.width, .height = input.height, .pitch = input.pitch,
        .format = std.enums.fromInt(render.image.Format, input.format) orelse return error.Unsupported,
        .layout = if (input.modifier == 0) .linear else .blocklinear, .log2_gobs = @intCast(input.modifier & 15) };
}
fn rect(input: c.R4NvRenderRect) render.Rect { return .{ .x = input.x, .y = input.y, .width = input.width, .height = input.height }; }
fn draw(input: c.R4NvYuvDraw, color: render.ColorProgram, matrix: [3][4]f32) render.Error!render.Draw {
    if (input.format < 1 or input.format > 3 or input.filter > 1 or input.blend > 1 or input.opacity > 65535) return error.Bounds;
    if (input.format != 3 and !std.meta.eql(input.second_chroma, std.mem.zeroes(c.R4NvRenderPlane))) return error.Bounds;
    return .{ .source = try view(input.luma), .target = try view(input.target),
        .source_rect = rect(input.source_rect), .destination = rect(input.destination), .scissor = rect(input.scissor),
        .filter = if (input.filter == 0) .nearest else .bilinear,
        .blend = if (input.blend == 0) .replace else .over, .opacity_linear = @as(f32, @floatFromInt(input.opacity)) / 65535,
        .transfer = .color, .color_program = color,
        .yuv = .{ .format = @enumFromInt(input.format), .chroma = try view(input.chroma),
            .second = if (input.format == 3) try view(input.second_chroma) else null,
            .matrix = matrix, .origin = .{ @bitCast(input.chroma_x), @bitCast(input.chroma_y) } } };
}
pub fn r4nv_encode_yuv_impl(request: *const c.R4NvYuvRender, commands: [*]u32, capacity: u32,
    packets: [*]u8, packet_capacity: u32, written: *u32) callconv(.c) i32
{
    if (!object(request).valid(@alignOf(c.R4NvYuvRender))) return c.status_invalid;
    const input = request.*;
    if (input.version != 1 or input.size != @sizeOf(c.R4NvYuvRender) or input.draw_count == 0 or
        input.draw_count > render.batch_capacity) return c.status_invalid;
    const packet_bytes = input.draw_count * render.packet_bytes;
    if (packet_capacity < packet_bytes) return c.status_capacity;
    const inputs = [_]Span{ object(request), .{ .address = input.draws, .bytes = @as(u64,input.draw_count) * @sizeOf(c.R4NvYuvDraw) },
        .{ .address = input.color_program, .bytes = 256 }, .{ .address = input.yuv_matrix, .bytes = 48 } };
    for (inputs, [_]u64{8,8,4,4}) |span, alignment| if (!span.valid(alignment)) return c.status_invalid;
    const outputs = [_]Span{ .{ .address = @intFromPtr(commands), .bytes = @as(u64,capacity) * 4 },
        .{ .address = @intFromPtr(packets), .bytes = packet_capacity }, object(written) };
    for (outputs, [_]u64{4,1,4}) |span, alignment| if (!span.valid(alignment)) return c.status_invalid;
    for (outputs, 0..) |span, i| {
        for (inputs) |source| if (span.overlaps(source)) return c.status_invalid;
        for (outputs[0..i]) |prior| if (span.overlaps(prior)) return c.status_invalid;
    }
    const color: render.ColorProgram = @as(*const render.ColorProgram,@ptrFromInt(input.color_program)).*;
    const matrix: [3][4]f32 = @as(*const [3][4]f32,@ptrFromInt(input.yuv_matrix)).*;
    const source: [*]const c.R4NvYuvDraw = @ptrFromInt(input.draws);
    var draws: [render.batch_capacity]render.Draw = undefined;
    for (source[0..input.draw_count], 0..) |item, i| draws[i] = draw(item, color, matrix) catch |err| return status(err);
    const binding: render.Binding = .{ .class = input.graphics_class, .draw = draws[0], .additional = draws[1..input.draw_count],
        .programs = .{ .address = input.program_address, .bytes = input.program_bytes },
        .packet = .{ .address = input.packet_address, .bytes = input.packet_bytes } };
    var program: render.Program = .{};
    render.encode(binding, &program) catch |err| return status(err);
    if (capacity < program.count) return c.status_capacity;
    // Validation and encoding above admit all immutable local draws before the
    // first caller-owned byte is changed. No fallible operation follows.
    render.packetUploadList(draws[0..input.draw_count], packets[0..packet_bytes]) catch unreachable;
    @memcpy(commands[0..program.count], program.data[0..program.count]);
    written.* = @intCast(program.count);
    return c.status_ok;
}
