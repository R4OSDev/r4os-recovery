// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/headers/nvidia/classes/clb097tex.h
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/headers/nvidia/classes/cl9097tex.h
// /*
//  * SPDX-FileCopyrightText: Copyright (c) 2001-2010 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//  * SPDX-License-Identifier: MIT
//  *
//  * Permission is hereby granted, free of charge, to any person obtaining a
//  * copy of this software and associated documentation files (the "Software"),
//  * to deal in the Software without restriction, including without limitation
//  * the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  * and/or sell copies of the Software, and to permit persons to whom the
//  * Software is furnished to do so, subject to the following conditions:
//  *
//  * The above copyright notice and this permission notice shall be included in
//  * all copies or substantial portions of the Software.
//  *
//  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  * DEALINGS IN THE SOFTWARE.
//  */
// 
// ExFiles/Reference/GFX/Nvidia/OpenKernelModules-570.144/src/common/sdk/nvidia/inc/class/clc797.h
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/headers/nvidia/classes/clc797.h
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/headers/nvidia/classes/clc597.h
// /*******************************************************************************
//     Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
// 
//     Permission is hereby granted, free of charge, to any person obtaining a
//     copy of this software and associated documentation files (the "Software"),
//     to deal in the Software without restriction, including without limitation
//     the rights to use, copy, modify, merge, publish, distribute, sublicense,
//     and/or sell copies of the Software, and to permit persons to whom the
//     Software is furnished to do so, subject to the following conditions:
// 
//     The above copyright notice and this permission notice shall be included in
//     all copies or substantial portions of the Software.
// 
//     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
//     THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//     FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//     DEALINGS IN THE SOFTWARE.
// 
// *******************************************************************************/
// 
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/vulkan/nvk_cmd_draw.c
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/vulkan/nvk_shader.c
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/vulkan/nvk_sampler.c
// Copyright © 2022 Collabora Ltd. and Red Hat Inc.
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 
// 
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/nil/descriptor.rs
// Copyright © 2024 Collabora, Ltd.
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 
// 
// DevKit/Toolchains/MesaNAK/26.2.2-2e3c65ad5e8b8e15/Source/src/nouveau/nil/nil_formats.csv
// Copyright 2024 Collabora Ltd.
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//! Bounded class-specific rectangle profiles over acknowledged GPU views.
//! The canonical queue/driver hold every range through physical completion.
const std = @import("std");
pub const image = @import("render_image.zig");
pub const profiles = @import("render_profiles.zig");
pub const Error = image.Error || error{Empty};
pub const packet_bytes = 1280;
pub const batch_capacity = 16;
pub const packet_capacity_bytes = packet_bytes * batch_capacity;
pub const shader_bytes = profiles.get(0xc797).?.bytes();
pub const max_shader_bytes = profiles.max_bytes;
pub fn shaderBytesFor(class: u32) Error!u32 { return (profiles.get(class) orelse return error.Unsupported).bytes(); }
// The driver's graphics ring has one 4 KB slot, including its 11-word release.
pub const max_words = 1024 - 11;
pub const Range = struct {
    address: u64,
    bytes: u64,
    pub fn validate(self: Range, alignment: u64, minimum: u64) Error!void {
        if (self.address == 0 or self.address & (alignment - 1) != 0 or self.address >= (1 << 40) or
            self.bytes < minimum or self.bytes > (1 << 40) - self.address) return error.Bounds;
    }
    pub fn overlaps(a: Range, b: Range) bool {
        return a.address < b.address +| b.bytes and b.address < a.address +| a.bytes;
    }
};
pub const Rect = struct {
    x: i32, y: i32, width: u32, height: u32,
    fn valid(self: Rect) bool {
        return self.x >= -32768 and self.y >= -32768 and self.width > 0 and self.height > 0 and
            self.width <= 32768 and self.height <= 32768 and
            @as(i64, self.x) + self.width <= 32768 and @as(i64, self.y) + self.height <= 32768;
    }
};
pub const Blend = enum { replace, over };
pub const Transfer = enum { identity, decode_srgb, encode_srgb, color };
pub const ColorProgram = @import("render_color.zig").Program;
pub const YuvSampling = @import("render_yuv.zig").Sampling;
pub const EncodeSampling = @import("render_encode.zig").Sampling;
pub const reference_model = if (@import("builtin").is_test) @import("render_reference.zig") else struct {};
pub const Draw = struct {
    target: image.Image,
    source: ?image.Image = null,
    destination: Rect,
    source_rect: Rect = .{ .x = 0, .y = 0, .width = 1, .height = 1 },
    scissor: Rect,
    filter: image.Filter = .nearest,
    blend: Blend = .replace,
    transfer: Transfer = .identity,
    color_program: ?ColorProgram = null,
    yuv: ?YuvSampling = null,
    encode_input: ?EncodeSampling = null,
    color: u32 = 0,
    opacity: u8 = 255,
    /// YUV/COLOR callers retain their normalized16-bit opacity through the
    /// float vertex attribute. Existing8-bit render commands remain unchanged.
    opacity_linear: ?f32 = null,
    grid: @import("render_grid.zig").Grid = .{},

    pub fn profile(self: Draw) u32 {
        if (self.encode_input != null) return 9;
        if (self.yuv != null) return 8;
        if (self.source == null) return 5;
        return switch (self.transfer) { .identity => 2, .decode_srgb => 3, .encode_srgb => 4, .color => 7 };
    }
    pub fn validate(self: Draw) Error!void {
        if (self.encode_input) |sampling| {
            const source = self.source orelse return error.Unsupported;
            try sampling.validate(source, self.target);
            if (self.yuv != null or self.transfer != .identity or self.color_program != null or
                self.opacity != 255 or self.opacity_linear != null or self.blend != .replace or
                self.filter != .nearest or self.grid.enabled != 0 or self.color != 0 or
                self.source_rect.x != 0 or self.source_rect.y != 0 or self.source_rect.width != sampling.extent[0] or
                self.source_rect.height != sampling.extent[1] or self.destination.x != 0 or self.destination.y != 0 or
                self.destination.width != self.target.width or self.destination.height != self.target.height)
                return error.Unsupported;
        }
        if (self.opacity_linear) |value| {
            if (self.yuv == null or !std.math.isFinite(value) or value < 0 or value > 1) return error.Bounds;
        }
        if (self.yuv) |sampling| {
            try sampling.validate(self.source orelse return error.Unsupported);
            if (self.transfer != .color or self.grid.enabled != 0) return error.Unsupported;
        }
        if ((self.transfer == .color) != (self.color_program != null)) return error.Unsupported;
        if (self.color_program) |program| {
            try program.validate();
            if (self.source == null or (self.yuv == null and self.filter != .nearest)) return error.Unsupported;
            if (self.yuv != null and (program.words[3] != 1 or program.scalar(160) != 1 or program.scalar(164) != 0)) return error.Unsupported;
            if (self.blend == .over and (program.words[0] & 1 != 0 or program.words[2] != 2 or program.words[4] != 4 or
                self.target.format != .abgr16161616f)) return error.Unsupported;
            if (self.target.format == .abgr16161616f and program.words[0] & 2 != 0) return error.Unsupported;
        }
        _ = try image.target(self.target);
        if (!self.destination.valid() or !self.scissor.valid()) return error.Bounds;
        if (self.source) |source| {
            _ = try image.texture(source);
            if (!self.source_rect.valid() or self.source_rect.x < 0 or self.source_rect.y < 0 or
                @as(u64, @intCast(self.source_rect.x)) + self.source_rect.width > source.width or
                @as(u64, @intCast(self.source_rect.y)) + self.source_rect.height > source.height) return error.Bounds;
            // Read/write aliasing cannot be made safe by a cache invalidate.
            // The resource layer may arrange a bounded CE scratch copy first.
            if (Range.overlaps(.{ .address = source.address, .bytes = source.bytes }, .{ .address = self.target.address, .bytes = self.target.bytes })) return error.Unsupported;
            if ((self.yuv == null and ((source.format == .r8) != (self.target.format == .r8))) or self.color != 0) return error.Unsupported;
            if (self.yuv) |sampling| {
                if (self.target.format == .r8) return error.Unsupported;
                for ([_]?image.Image{ sampling.chroma, sampling.second }) |plane| if (plane) |view| {
                    if (Range.overlaps(.{ .address = view.address, .bytes = view.bytes }, .{ .address = self.target.address, .bytes = self.target.bytes })) return error.Unsupported;
                };
            }
            if (self.encode_input) |sampling| for ([_]?image.Image{ sampling.chroma, sampling.second }) |plane| if (plane) |view| {
                if (Range.overlaps(.{ .address = view.address, .bytes = view.bytes }, .{ .address = self.target.address, .bytes = self.target.bytes })) return error.Unsupported;
            };
        } else if (self.transfer != .identity) return error.Unsupported;
        if (self.target.format == .r8 and (self.blend != .replace or self.transfer != .identity)) return error.Unsupported;
        if (self.source == null and self.target.format.hasAlpha()) {
            const alpha = self.color >> 24;
            if ((self.color & 255) > alpha or ((self.color >> 8) & 255) > alpha or ((self.color >> 16) & 255) > alpha) return error.Bounds;
        }
        const clipped = try self.clip();
        if (self.grid.enabled != 0 and (self.source == null or self.filter != .nearest or
            (self.transfer != .identity and self.transfer != .color))) return error.Unsupported;
        try self.grid.validate(self.source_rect, Rect{ .x = @intCast(clipped[0]), .y = @intCast(clipped[1]),
            .width = clipped[2] - clipped[0], .height = clipped[3] - clipped[1] });
    }
    pub fn clip(self: Draw) Error![4]u32 {
        const left = @max(0, @max(self.destination.x, self.scissor.x));
        const top = @max(0, @max(self.destination.y, self.scissor.y));
        const right = @min(@as(i64, self.target.width), @min(@as(i64, self.destination.x) + self.destination.width, @as(i64, self.scissor.x) + self.scissor.width));
        const bottom = @min(@as(i64, self.target.height), @min(@as(i64, self.destination.y) + self.destination.height, @as(i64, self.scissor.y) + self.scissor.height));
        if (right <= left or bottom <= top) return error.Empty;
        return .{@intCast(left), @intCast(top), @intCast(right), @intCast(bottom)};
    }
};
pub const Slice = struct { draw: Draw, next: u64, total: u64 };
/// Bound raster work without changing destination/source coordinates, sample
/// grids or blending order. Only the scissor changes, so adjacent slices use
/// the original interpolation and never shade a destination pixel twice.
pub fn slice(draw: Draw, offset: u64, pixel_limit: u64) Error!Slice {
    try draw.validate();
    const clip = try draw.clip();
    const width: u64 = clip[2] - clip[0];
    const height: u64 = clip[3] - clip[1];
    const total = width * height;
    if (pixel_limit == 0 or offset >= total) return error.Bounds;
    const row = offset / width;
    const column = offset % width;
    const columns = @min(width - column, pixel_limit);
    const rows = if (column == 0 and width <= pixel_limit) @min(height - row, pixel_limit / width) else 1;
    var out = draw;
    out.scissor = .{ .x = @intCast(clip[0] + column), .y = @intCast(clip[1] + row),
        .width = @intCast(columns), .height = @intCast(rows) };
    try out.validate();
    return .{ .draw = out, .next = offset + columns * rows, .total = total };
}
pub const Binding = struct {
    class: u32 = 0xc797,
    draw: Draw,
    additional: []const Draw = &.{},
    programs: Range,
    packet: Range,
    pub fn validate(self: Binding) Error!void {
        try self.draw.validate();
        if (self.additional.len >= batch_capacity) return error.Bounds;
        for (self.additional) |draw| {
            try draw.validate();
            if (!compatible(self.draw, draw)) return error.Unsupported;
        }
        try self.programs.validate(128, try shaderBytesFor(self.class));
        try self.packet.validate(256, packet_bytes * (1 + self.additional.len));
        const target: Range = .{ .address = self.draw.target.address, .bytes = self.draw.target.bytes };
        if (Range.overlaps(self.programs, self.packet) or Range.overlaps(self.programs, target) or Range.overlaps(self.packet, target)) return error.Unsupported;
        if (self.draw.source) |src| {
            const source: Range = .{ .address = src.address, .bytes = src.bytes };
            if (Range.overlaps(self.programs, source) or Range.overlaps(self.packet, source)) return error.Unsupported;
        }
        if (self.draw.yuv) |sampling| for ([_]?image.Image{ sampling.chroma, sampling.second }) |plane| if (plane) |view| {
            const source: Range = .{ .address = view.address, .bytes = view.bytes };
            if (Range.overlaps(self.programs, source) or Range.overlaps(self.packet, source)) return error.Unsupported;
        };
        if (self.draw.encode_input) |sampling| for ([_]?image.Image{ sampling.chroma, sampling.second }) |plane| if (plane) |view| {
            const source: Range = .{ .address = view.address, .bytes = view.bytes };
            if (Range.overlaps(self.programs, source) or Range.overlaps(self.packet, source)) return error.Unsupported;
        };
    }
    pub fn matches(self: Binding, draws: []const Draw) bool {
        if (draws.len != 1 + self.additional.len or !std.meta.eql(self.draw, draws[0])) return false;
        for (self.additional, draws[1..]) |left, right| if (!std.meta.eql(left, right)) return false;
        return true;
    }
};
pub fn compatible(first: Draw, next: Draw) bool {
    return std.meta.eql(first.target, next.target) and std.meta.eql(first.source, next.source) and
        first.filter == next.filter and first.blend == next.blend and first.transfer == next.transfer and
        std.meta.eql(first.color_program, next.color_program) and std.meta.eql(first.yuv, next.yuv) and
        std.meta.eql(first.encode_input, next.encode_input);
}
pub fn shaderOffset(index: usize) u32 {
    return profiles.get(0xc797).?.offset(index);
}
/// Once per device generation, into a driver-owned upload allocation.
pub fn shaderUpload(out: []u8) Error!void {
    return shaderUploadFor(0xc797, out);
}
pub fn shaderUploadFor(class: u32, out: []u8) Error!void {
    const profile = profiles.get(class) orelse return error.Unsupported;
    if (out.len != profile.bytes()) return error.Bounds;
    @memset(out, 0);
    for (profile.programs, 0..) |program, index| {
        const offset = profile.offset(index);
        @memcpy(out[offset..][0..128], std.mem.asBytes(&program.header));
        @memcpy(out[offset + 128..][0..program.code.len], program.code);
    }
}
pub const Vertex = extern struct { position: [4]f32, uv: [2]f32, tint: [4]f32 };
comptime { if (@sizeOf(Vertex) != 40) @compileError("rectangle vertex stride"); }
/// Fixed small upload: TIC, TSC, CBuf1 and four vertices. Image pixels are
/// never mapped, scaled or copied by this encoder.
pub fn packetUpload(draw: Draw, out: []u8) Error!void {
    try draw.validate();
    if (out.len != packet_bytes) return error.Bounds;
    @memset(out, 0);
    if (draw.color_program) |program| @memcpy(out[1024..1280], std.mem.asBytes(&program));
    if (draw.source) |source| {
        const tic = try image.textureTyped(source, if (draw.yuv != null or draw.encode_input != null) .unsigned_integer else .normalized);
        @memcpy(out[0..32], std.mem.asBytes(&tic));
        if (draw.yuv) |sampling| {
            const cb = try image.textureTyped(sampling.chroma, .unsigned_integer);
            @memcpy(out[32..64], std.mem.asBytes(&cb));
            std.mem.writeInt(u32, out[516..520], 1, .little);
            if (sampling.second) |plane| {
                const cr = try image.textureTyped(plane, .unsigned_integer);
                @memcpy(out[64..96], std.mem.asBytes(&cr));
                std.mem.writeInt(u32, out[520..524], 2, .little);
            }
            const parameters = sampling.program(source, draw.source_rect, draw.filter);
            // Integer texel fetches need no sampler. Reuse the TSC region
            // for CBuf3, preserving the1280-byte packet and existing offsets.
            @memcpy(out[256..512], std.mem.asBytes(&parameters));
        } else if (draw.encode_input) |sampling| {
            const cb = try image.textureTyped(sampling.chroma, .unsigned_integer);
            @memcpy(out[32..64], std.mem.asBytes(&cb));
            std.mem.writeInt(u32, out[516..520], 1, .little);
            if (sampling.second) |plane| {
                const cr = try image.textureTyped(plane, .unsigned_integer);
                @memcpy(out[64..96], std.mem.asBytes(&cr));
                std.mem.writeInt(u32, out[520..524], 2, .little);
            }
            const parameters = sampling.program(draw.target);
            @memcpy(out[256..512], std.mem.asBytes(&parameters));
        } else {
            const tsc = image.sampler(draw.filter);
            @memcpy(out[256..288], std.mem.asBytes(&tsc));
        }
        // TIC[0] | (TSC[0] << 20), one descriptor of each in this packet.
        std.mem.writeInt(u32, out[512..516], 0, .little);
        // CBuf1 ABI2: clamp UVs to the selected source's first/last texel
        // centers. Filtering a subrectangle never requires a copied image.
        const extent: [2]f32 = .{ @floatFromInt(source.width), @floatFromInt(source.height) };
        const origin: [2]f32 = .{ @floatFromInt(draw.source_rect.x), @floatFromInt(draw.source_rect.y) };
        const bounds: [4]f32 = .{ (origin[0] + 0.5) / extent[0], (origin[1] + 0.5) / extent[1],
            (origin[0] + @as(f32, @floatFromInt(draw.source_rect.width)) - 0.5) / extent[0],
            (origin[1] + @as(f32, @floatFromInt(draw.source_rect.height)) - 0.5) / extent[1] };
        @memcpy(out[528..544], std.mem.asBytes(&bounds));
        var grid = draw.grid;
        if (grid.enabled == 0 and draw.filter == .nearest and draw.yuv == null and draw.encode_input == null) {
            // Ordinary pixel-center nearest uses the same integer sampling
            // shader as logical grids. At scale 60 its first stage produces
            // 2*x+1, so a doubled destination gives exact rational centers.
            // Interpolated float UVs can fall below an exact texel boundary
            // (e.g. source 64 -> destination 160 at pixel 157 selects 62).
            // Draw admission bounds every covered relative coordinate below
            // 2*32768; its product with the source extent still fits u32.
            grid = .{ .enabled = 1, .scale = 60,
                .pixel_width = draw.target.width, .pixel_height = draw.target.height,
                .viewport_x = draw.destination.x * 2, .viewport_y = draw.destination.y * 2,
                .viewport_width = draw.destination.width * 2, .viewport_height = draw.destination.height * 2,
                .guest_width = draw.source_rect.width, .guest_height = draw.source_rect.height };
        }
        @memcpy(out[544..608], std.mem.asBytes(&grid));
        const rectangle: [4]u32 = .{ @intCast(draw.source_rect.x), @intCast(draw.source_rect.y), draw.source_rect.width, draw.source_rect.height };
        @memcpy(out[608..624], std.mem.asBytes(&rectangle));
        @memcpy(out[624..632], std.mem.asBytes(&extent));
    }
    const factor: f32 = draw.opacity_linear orelse (@as(f32, @floatFromInt(draw.opacity)) / 255.0);
    var tint: [4]f32 = @splat(factor);
    if (draw.source == null) {
        if (draw.target.format == .r8) {
            tint = .{ @as(f32, @floatFromInt(draw.color & 255)) / 255.0 * factor, 0, 0, factor };
        } else {
            for ([_]u5{16,8,0,24}, 0..) |shift, i|
                tint[i] = @as(f32, @floatFromInt((draw.color >> shift) & 255)) / 255.0 * factor;
            if (!draw.target.format.hasAlpha()) tint[3] = factor;
        }
    }
    const width: f32 = @floatFromInt(draw.target.width);
    const height: f32 = @floatFromInt(draw.target.height);
    for (0..4) |index| {
        const x: f32 = @floatFromInt(@as(i64, draw.destination.x) + (if (index & 1 != 0) @as(i64, draw.destination.width) else 0));
        const y: f32 = @floatFromInt(@as(i64, draw.destination.y) + (if (index & 2 != 0) @as(i64, draw.destination.height) else 0));
        var vertex: Vertex = .{ .position = .{ x / width * 2.0 - 1.0, y / height * 2.0 - 1.0, 0, 1 }, .uv = .{0,0}, .tint = tint };
        if (draw.source) |source| {
            vertex.uv[0] = @as(f32, @floatFromInt(@as(i64, draw.source_rect.x) + (if (index & 1 != 0) @as(i64, draw.source_rect.width) else 0))) / @as(f32, @floatFromInt(source.width));
            vertex.uv[1] = @as(f32, @floatFromInt(@as(i64, draw.source_rect.y) + (if (index & 2 != 0) @as(i64, draw.source_rect.height) else 0))) / @as(f32, @floatFromInt(source.height));
        }
        @memcpy(out[768 + index * 40..][0..40], std.mem.asBytes(&vertex));
    }
}
pub fn packetUploadList(draws: []const Draw, out: []u8) Error!void {
    if (draws.len == 0 or draws.len > batch_capacity or out.len != draws.len * packet_bytes) return error.Bounds;
    // Reject the entire list before modifying any upload bytes.
    for (draws) |draw| {
        try draw.validate();
        if (!compatible(draws[0], draw)) return error.Unsupported;
    }
    for (draws, 0..) |draw, index| try packetUpload(draw, out[index * packet_bytes..][0..packet_bytes]);
}
pub const Program = struct {
    data: [max_words]u32 = undefined,
    count: usize = 0,
    pub fn slice(self: *const Program) []const u32 { return self.data[0..self.count]; }
    fn words(self: *Program, method: u32, values: []const u32) Error!void {
        if (values.len == 0 or self.count + values.len + 1 > self.data.len or method & 3 != 0 or method > 0x7ffc) return error.Bounds;
        self.data[self.count] = 0x20000000 | (@as(u32, @intCast(values.len)) << 16) | (method >> 2);
        @memcpy(self.data[self.count+1..][0..values.len], values);
        self.count += values.len + 1;
    }
    fn one(self: *Program, method: u32, value: u32) Error!void { try self.words(method, &.{value}); }
};
fn bindShader(comptime hw: type, profile: profiles.Profile, out: *Program, programs: Range, index: usize) Error!void {
    const shader = profile.programs[index];
    const pipeline: u32 = if (shader.stage == 0) 1 else 5;
    const stride = pipeline * 64;
    const address = programs.address + profile.offset(index);
    try out.one(hw.SET_PIPELINE_SHADER + stride, 1 | (pipeline << 4));
    // C597 defines only address A/B. C797 and later append the seven-bit
    // prefetch size, including the shader header, as in pinned NVK.
    const address_words = [_]u32{
        @intCast(address >> 32), @truncate(address),
        @intCast(@min(127, (128 + shader.code.len + 255) / 256)),
    };
    try out.words(hw.SET_PIPELINE_PROGRAM_ADDRESS_A + stride,
        address_words[0..if (profile.class >= 0xc797) 3 else 2]);
    try out.words(hw.SET_PIPELINE_REGISTER_COUNT + stride, &.{shader.gprs, shader.stage});
}
pub fn encode(binding: Binding, out: *Program) Error!void {
    try binding.validate();
    return switch (binding.class) {
        0xc597 => encodeFor(@import("Generated/Render/c597.zig"), binding, out),
        0xc797 => encodeFor(@import("Generated/Render/c797.zig"), binding, out),
        0xc997 => encodeFor(@import("Generated/Render/c997.zig"), binding, out),
        0xcd97 => encodeFor(@import("Generated/Render/cd97.zig"), binding, out),
        else => error.Unsupported,
    };
}
fn encodeFor(comptime hw: type, binding: Binding, out: *Program) Error!void {
    out.count = 0;
    const profile = profiles.get(binding.class).?;
    const draw = binding.draw;
    const target = try image.target(draw.target);
    // CE upload must already have a real completion. WFI precedes reuse of
    // descriptor/constant/vertex state; invalidation makes those writes visible.
    try out.one(hw.SET_OBJECT, binding.class);
    try out.one(hw.WAIT_FOR_IDLE, 0);
    try out.one(hw.INVALIDATE_SHADER_CACHES, 0x1011);
    try out.one(hw.INVALIDATE_TEXTURE_DATA_CACHE, 0);
    try out.one(hw.INVALIDATE_TEXTURE_HEADER_CACHE, 0);
    try out.one(hw.INVALIDATE_SAMPLER_CACHE, 0);
    for (hw.initial) |pair| try out.one(pair[0], pair[1]);
    // All shader stages and vertex attributes outside this fixed ABI are off.
    for (0..6) |stage| if (stage != 1 and stage != 5) { try out.one(hw.SET_PIPELINE_SHADER + @as(u32,@intCast(stage)) * 64, @as(u32,@intCast(stage)) << 4); };
    for (0..32) |attribute| {
        const value = switch (attribute) { 0 => hw.vertex_vec4, 1 => if (draw.source != null) hw.vertex_vec2 | (16 << 7) else hw.vertex_inactive, 2 => hw.vertex_vec4 | (24 << 7), else => hw.vertex_inactive };
        try out.one(hw.SET_VERTEX_ATTRIBUTE_A + @as(u32,@intCast(attribute)) * 4, value);
        if (attribute != 0) try out.one(hw.SET_VERTEX_STREAM_A_FORMAT + @as(u32,@intCast(attribute)) * 16, 0);
    }
    try out.words(hw.SET_COLOR_TARGET_A, &target.words);
    // Surface clip is a separate hardware rectangle, not inferred from
    // target storage or viewport. Per-draw scissor applies inside it.
    try out.words(hw.SET_SURFACE_CLIP_HORIZONTAL, &.{draw.target.width << 16, draw.target.height << 16});
    const half_width = @as(f32,@floatFromInt(draw.target.width)) / 2.0;
    const half_height = @as(f32,@floatFromInt(draw.target.height)) / 2.0;
    try out.words(hw.SET_VIEWPORT_SCALE_X, &.{@bitCast(half_width), @bitCast(half_height), @bitCast(@as(f32,0.5)), @bitCast(half_width), @bitCast(half_height), @bitCast(@as(f32,0.5))});
    try out.words(hw.SET_VIEWPORT_CLIP_HORIZONTAL, &.{draw.target.width << 16, draw.target.height << 16, 0, @bitCast(@as(f32,1))});
    try out.one(hw.SET_CT_WRITE, if (draw.target.format == .r8) hw.color_write_r else hw.color_write_rgba);
    try out.one(hw.SET_BLEND, @intFromBool(draw.blend == .over));
    try out.words(hw.SET_BLEND_PER_TARGET_SEPARATE_FOR_ALPHA, &.{1, hw.blend_add, hw.blend_one, if (draw.blend == .over) hw.blend_inverse_alpha else hw.blend_zero, hw.blend_add, hw.blend_one, if (draw.blend == .over) hw.blend_inverse_alpha else hw.blend_zero});
    try bindShader(hw, profile, out, binding.programs, if (draw.source == null or draw.encode_input != null) 5 else 0);
    try bindShader(hw, profile, out, binding.programs, draw.profile()-1);
    try encodeDraw(hw, draw, binding.packet.address, out);
    for (binding.additional, 1..) |next, index| try encodeDraw(hw, next, binding.packet.address + index * packet_bytes, out);
    // The driver's private GR semaphore release follows the entire list.
}
fn encodeDraw(comptime hw: type, draw: Draw, packet: u64, out: *Program) Error!void {
    const clip = try draw.clip();
    try out.words(hw.SET_SCISSOR_ENABLE, &.{1, clip[0] | (clip[2] << 16), clip[1] | (clip[3] << 16)});
    const vertices = packet + 768;
    try out.words(hw.SET_VERTEX_STREAM_A_FORMAT, &.{hw.vertex_stride, @intCast(vertices >> 32), @truncate(vertices), 1});
    try out.words(hw.SET_VERTEX_STREAM_SIZE_A, &.{0, 160});
    try out.one(hw.SET_VERTEX_STREAM_INSTANCE_A, 0);
    if (draw.source != null) {
        const sampler_address = packet + 256;
        const constants = packet + 512;
        try out.words(hw.SET_TEX_HEADER_POOL_A, &.{@intCast(packet >> 32), @truncate(packet),
            if (draw.yuv) |sampling| sampling.planeCount() - 1 else if (draw.encode_input) |sampling| sampling.planeCount() - 1 else 0});
        if (draw.yuv == null and draw.encode_input == null) try out.words(hw.SET_TEX_SAMPLER_POOL_A, &.{@intCast(sampler_address >> 32), @truncate(sampler_address), 0});
        try out.words(hw.SET_CONSTANT_BUFFER_SELECTOR_A, &.{256, @intCast(constants >> 32), @truncate(constants)});
        try out.one(hw.BIND_GROUP_CONSTANT_BUFFER + 4 * 32, 1 | (1 << 4));
    } else try out.one(hw.BIND_GROUP_CONSTANT_BUFFER + 4 * 32, 1 << 4);
    if (draw.color_program != null) {
        const constants = packet + 1024;
        try out.words(hw.SET_CONSTANT_BUFFER_SELECTOR_A, &.{256, @intCast(constants >> 32), @truncate(constants)});
        try out.one(hw.BIND_GROUP_CONSTANT_BUFFER + 4 * 32, 1 | (2 << 4));
    }
    if (draw.yuv != null or draw.encode_input != null) {
        const constants = packet + 256;
        try out.words(hw.SET_CONSTANT_BUFFER_SELECTOR_A, &.{256, @intCast(constants >> 32), @truncate(constants)});
        try out.one(hw.BIND_GROUP_CONSTANT_BUFFER + 4 * 32, 1 | (3 << 4));
    }
    try out.words(hw.SET_DRAW_CONTROL_A, &.{hw.draw_control, 1});
    try out.words(hw.DRAW_VERTEX_ARRAY_BEGIN_END_A, &.{0, 4});
}
