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
//! Fixed SM86 image/sampler profile. Input addresses belong to held driver
//! allocations; application handles are resolved by the runtime before here.
const std = @import("std");
pub const Error = error{ Bounds, Unsupported };
pub const Format = enum(u32) {
    xrgb8888 = 0x34325258, argb8888 = 0x34325241, r8 = 0x20203852,
    xrgb2101010 = 0x30335258, argb2101010 = 0x30335241, abgr16161616f = 0x48344241,
    // Storage formats for video-plane views. CICP/YUV meaning belongs to the
    // caller's color program; a two-channel texture alone is not a video image.
    rg8 = 0x38385247, r16 = 0x20363152, rg16 = 0x32335247,
    pub fn pixelBytes(self: Format) u32 { return switch (self) { .r8 => 1, .rg8, .r16 => 2, .abgr16161616f => 8, else => 4 }; }
    pub fn hasAlpha(self: Format) bool { return self == .argb8888 or self == .argb2101010 or self == .abgr16161616f; }
};
pub const Layout = enum { linear, blocklinear };
pub const Filter = enum { nearest, bilinear };
pub const Image = struct {
    address: u64,
    bytes: u64,
    width: u32,
    height: u32,
    pitch: u32,
    format: Format,
    layout: Layout,
    log2_gobs: u8 = 0,

    pub fn pixelBytes(self: Image) u32 { return self.format.pixelBytes(); }
    pub fn validate(self: Image) Error!void {
        if (self.width == 0 or self.height == 0 or self.width > 16384 or self.height > 16384 or self.log2_gobs > 5) return error.Bounds;
        const row: u64 = @as(u64, self.width) * self.pixelBytes();
        if (self.address == 0 or self.address >= (@as(u64, 1) << 48) or self.bytes == 0 or self.bytes > (@as(u64, 1) << 48) - self.address or self.pitch < row) return error.Bounds;
        const rows = if (self.layout == .blocklinear) std.mem.alignForward(u64, self.height, @as(u64, 8) << @intCast(self.log2_gobs)) else self.height;
        if (@as(u64, self.pitch) * rows > self.bytes) return error.Bounds;
        if (self.layout == .linear) {
            if (self.log2_gobs != 0 or self.address & 31 != 0 or self.pitch & 31 != 0 or self.pitch >= (1 << 21)) return error.Bounds;
        } else {
            // The initial blocklinear profile has one GOB per tile width.
            // TIC derives its row stride from width; arbitrary extra pitch
            // would interpret a legal CE allocation as a different image.
            if (self.address & 511 != 0 or self.pitch != std.mem.alignForward(u64, row, 64)) return error.Unsupported;
        }
    }
};
pub const Target = struct {
    words: [9]u32,
};
pub fn target(image: Image) Error!Target {
    try image.validate();
    // TIC carries 48 address bits; COLOR_TARGET_A/B carries only 40.
    if (image.address >= (1 << 40) or image.bytes > (1 << 40) - image.address) return error.Unsupported;
    if (image.layout == .linear and (image.address & 127 != 0 or image.pitch & 127 != 0)) return error.Unsupported;
    const tiled = image.layout == .blocklinear;
    const size = @as(u64, image.pitch) * std.mem.alignForward(u64, image.height, @as(u64, 8) << @intCast(image.log2_gobs));
    if (tiled and size / 4 > std.math.maxInt(u32)) return error.Bounds;
    return .{ .words = .{
        @intCast(image.address >> 32), @truncate(image.address),
        if (tiled) image.pitch / image.pixelBytes() else image.pitch, image.height,
        switch (image.format) { .xrgb8888 => 0xe6, .argb8888 => 0xcf, .r8 => 0xf3,
            .xrgb2101010, .argb2101010 => 0xdf, .abgr16161616f => 0xca,
            .rg8, .r16, .rg16 => return error.Unsupported },
        if (tiled) @as(u32, image.log2_gobs) << 4 else @as(u32, 1) << 12,
        1, if (tiled) @intCast(size / 4) else 0, 0,
    } };
}
pub fn texture(image: Image) Error![8]u32 {
    return textureTyped(image, .normalized);
}
pub const SampleType = enum { normalized, unsigned_integer };
// Integer texel loads preserve all storage bits. The video shader shifts
// P010's six low bits before reconstructing chroma; hardware linear filtering
// of normalized16-bit values would blend padding into the meaningful codes.
pub fn textureTyped(image: Image, sample_type: SampleType) Error![8]u32 {
    try image.validate();
    const tiled = image.layout == .blocklinear;
    var out: [8]u32 = @splat(0);
    const plane = image.format == .r8 or image.format == .rg8 or image.format == .r16 or image.format == .rg16;
    const pair = image.format == .rg8 or image.format == .rg16;
    const integer = sample_type == .unsigned_integer;
    if (integer and !plane) return error.Unsupported;
    const rgba = !plane;
    const floating = image.format == .abgr16161616f;
    const kind: u32 = if (integer) 4 else if (floating) 7 else 2;
    const component_types: u32 = if (rgba) (kind << 7) | (kind << 10) | (kind << 13) | (kind << 16)
        else (kind << 7) | (if (pair) kind << 10 else 0);
    const swizzle: u32 = if (rgba) ((if (floating) @as(u32, 2) else 4) << 19) | (3 << 22) |
        ((if (floating) @as(u32, 4) else 2) << 25) | ((if (image.format.hasAlpha()) @as(u32, 5) else 7) << 28)
        else (2 << 19) | (if (pair) @as(u32, 3) << 22 else 0) | ((if (integer) @as(u32, 6) else 7) << 28);
    const components: u32 = switch (image.format) { .r8 => 0x1d, .xrgb8888, .argb8888 => 8,
        .xrgb2101010, .argb2101010 => 9, .abgr16161616f => 3, .rg8 => 0x18, .r16 => 0x1b, .rg16 => 0x0c };
    out[0] = components | component_types | swizzle;
    out[1] = @truncate(image.address);
    out[2] = @as(u32, @intCast(image.address >> 32)) | ((if (tiled) @as(u32, 3) else 2) << 21);
    out[3] = (if (tiled) @as(u32, image.log2_gobs) << 3 else image.pitch >> 5) | (1 << 16) | (1 << 17) | (1 << 18);
    out[4] = (image.width - 1) | ((if (tiled) @as(u32, 1) else 7) << 23) | (7 << 29);
    out[5] = (image.height - 1) | (1 << 31);
    out[6] = (2 << 23) | (1 << 25);
    // One mip, one sample, normalized coordinates, no automatic sRGB decode.
    // The fixed shaders own the documented premultiplied color conversion.
    return out;
}
pub fn sampler(filter: Filter) [8]u32 {
    const value: u32 = if (filter == .nearest) 1 else 2;
    return .{ 2 | (2 << 3) | (2 << 6) | (1 << 14) | (1 << 17),
        value | (value << 4) | (2 << 6), 0, 0, 0, 0, 0, 0 };
}
