// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! NV12/P010/YUV420P into the same retained shader/descriptor path as 2D.
//! Plane code values are unsigned; P010 padding is discarded before matrix,
//! transfer decoding, RGB filtering, color conversion and final opacity.
const std = @import("std");
pub fn Provider(comptime c: type, comptime a: type) type {
    return struct {
        const b = @import("render_batch.zig").Provider(c, a);
        const images = b.images;
        const render = b.render;
        pub const Packet = extern struct { header: c.R4AmdYuvHeader, color: [64]u32, matrix: [3][4]f32 };
        pub const Bound = struct { descriptor: a.GfxBufferDescriptor, address: u64 };
        comptime {
            if (@sizeOf(Packet) != c.native_yuv_command_bytes or @offsetOf(Packet, "matrix") != 456) @compileError("native YUV wire ABI");
        }
        fn f(v: anytype) f32 {
            return @floatFromInt(v);
        }
        fn rect(r: c.R4AmdRect) a.GfxRenderRect {
            return .{ .x = r.x, .y = r.y, .width = r.width, .height = r.height };
        }
        fn store(out: *[4096]u8, offset: usize, v: anytype) void {
            @memcpy(out[offset..][0..@sizeOf(@TypeOf(v))], std.mem.asBytes(&v));
        }
        fn rc(value: i32) b.Error!void {
            if (value != 0) return error.Unsupported;
        }
        fn plane(arch: c.R4AmdArchitecture, p: c.R4AmdYuvPlane, view: Bound, h: c.R4AmdYuvHeader, index: usize, scratch: *align(16) [65536]u8) b.Error!c.R4AmdImageDescriptors {
            const desc = view.descriptor;
            const width = if (index == 0) h.width else (h.width + 1) / 2;
            const height = if (index == 0) h.height else (h.height + 1) / 2;
            const pair = index != 0 and h.format != 3;
            const p010 = h.format == 2;
            const unit: u32 = @as(u32, if (p010) 2 else 1) * @as(u32, if (pair) 2 else 1);
            if (p.reserved != 0 or p.reserved1 != 0 or p.byte_length == 0 or p.offset >= desc.byte_length or p.byte_length > desc.byte_length - p.offset or
                p.pitch < width * unit or p.pitch > 1024 * 1024 or p.pitch % unit != 0 or desc.modifier != 0 or desc.usage & a.gfx_buffer_usage_transfer_source == 0 or
                p.byte_length < @as(u64, p.pitch) * height) return error.Invalid;
            if (desc.format == a.gfx_buffer_format_nv12 or desc.format == a.gfx_buffer_format_p010) {
                if (index >= 2 or desc.plane_count != 2 or desc.format != @as(u32, if (p010) a.gfx_buffer_format_p010 else a.gfx_buffer_format_nv12) or
                    h.format == 3 or h.width > desc.width or h.height > desc.height or p.offset != desc.plane_offsets[index] or p.pitch != desc.plane_pitches[index]) return error.Unsupported;
            } else if (desc.format == a.gfx_buffer_format_r8) {
                if (pair or p010 or desc.plane_count != 1 or p.offset != desc.plane_offsets[0] or p.pitch != desc.plane_pitches[0] or width > desc.width or height > desc.height) return error.Unsupported;
            } else if (desc.format != a.gfx_buffer_format_bytes or desc.plane_count != 0) return error.Unsupported;
            const format: u32 = if (p010) (if (pair) c.format_rg16 else c.format_r16) else (if (pair) c.format_rg8 else a.gfx_buffer_format_r8);
            const request: c.R4AmdImageRequest = .{ .version = 1, .size = @sizeOf(c.R4AmdImageRequest), .gb_addr_config = arch.gb_addr_config, .chip_revision = arch.chip_revision, .device_id = arch.device_id, .gc_version = arch.gc_version, .resource_type = 1, .format = format, .width = width, .height = height, .depth = 1, .mip_count = 1, .samples = 1, .usage = c.image_usage_texture, .swizzle = 0, .pipe_xor = 0, .pitch = p.pitch, .reserved = 0, .modifier = 0 };
            var iv = std.mem.zeroes(c.R4AmdImageView);
            iv.version = 1;
            iv.size = @sizeOf(c.R4AmdImageView);
            iv.address = view.address + p.offset;
            iv.byte_length = p.byte_length;
            iv.flags = c.view_uint;
            var result: c.R4AmdImageDescriptors = undefined;
            try rc(images.descriptors(&request, &iv, scratch, scratch.len, &result));
            return result;
        }
        pub fn encode(arch: c.R4AmdArchitecture, adapter: u32, packet: Packet, bindings: []const Bound, shader_address: u64, payload_address: u64, scratch: *align(16) [65536]u8, payload: *[4096]u8, words: *[b.max_words]u32) b.Error!usize {
            const h = packet.header;
            if (h.version != 1 or h.size != @sizeOf(c.R4AmdYuvHeader) or h.kind != c.native_yuv_command_kind or h.reserved != 0 or h.format < 1 or h.format > 3 or
                h.filter > 1 or h.blend > 1 or h.opacity > 65535 or h.width == 0 or h.height == 0 or h.width > 16384 or h.height > 16384 or
                h.plane_count != @as(u32, if (h.format == 3) 3 else 2) or bindings.len < 2 or bindings.len > 4 or h.target_binding >= bindings.len or
                shader_address == 0 or shader_address & 255 != 0 or shader_address >= (@as(u64, 1) << 48) - render.programBytes() or
                payload_address == 0 or payload_address & 4095 != 0 or payload_address >= (@as(u64, 1) << 48) - 4096) return error.Invalid;
            if (h.plane_count == 2 and !std.meta.eql(h.plane2, std.mem.zeroes(c.R4AmdYuvPlane))) return error.Invalid;
            const source = h.source;
            const dest = h.destination;
            if (source.x < 0 or source.y < 0 or source.width == 0 or source.height == 0 or @as(u64, @intCast(source.x)) + source.width > h.width or
                @as(u64, @intCast(source.y)) + source.height > h.height) return error.Bounds;
            const program: b.Color = .{ .words = packet.color };
            try program.validate();
            if (program.words[3] != 1 or program.scalar(160) != 1 or program.scalar(164) != 0) return error.Unsupported;
            for (packet.matrix) |row| for (row) |v| if (!std.math.isFinite(v) or @abs(v) > 64) return error.Bounds;
            const origin: [2]f32 = .{ @bitCast(h.chroma_x), @bitCast(h.chroma_y) };
            for (origin) |v| if (!std.math.isFinite(v) or (v != 0 and v != 0.5)) return error.Unsupported;
            const dst = bindings[h.target_binding];
            const target = try b.image(arch, adapter, dst.descriptor, dst.address, true, 0, scratch);
            const fp16 = dst.descriptor.format == 1211384385;
            if (h.blend == 1 and (program.words[0] & 1 != 0 or program.words[2] != 2 or program.words[4] != 4 or !fp16)) return error.Unsupported;
            if (fp16 and program.words[0] & 2 != 0) return error.Unsupported;
            const clipped = try b.clip(.{ .target_rect = rect(dest), .scissor = rect(h.scissor) }, target.request.width, target.request.height);
            @memset(payload, 0);
            store(payload, 0, b.bufferDescriptor(payload_address + 512, 256));
            store(payload, 16, b.bufferDescriptor(payload_address + 768, 256));
            store(payload, 512, program);
            const planes = [_]c.R4AmdYuvPlane{ h.plane0, h.plane1, h.plane2 };
            var used: [4]bool = @splat(false);
            used[h.target_binding] = true;
            for (planes[0..h.plane_count], 0..) |p, i| {
                if (p.binding >= bindings.len or p.binding == h.target_binding) return error.Invalid;
                const src = bindings[p.binding];
                if (src.address < dst.address + dst.descriptor.byte_length and dst.address < src.address + src.descriptor.byte_length) return error.Invalid;
                const image = try plane(arch, p, src, h, i, scratch);
                used[p.binding] = true;
                store(payload, 256 + i * 64, [8]u32{ image.texture0, image.texture1, image.texture2, image.texture3, image.texture4, image.texture5, image.texture6, image.texture7 });
                store(payload, 288 + i * 64, [4]u32{ image.sampler0, image.sampler1, image.sampler2, image.sampler3 });
            }
            for (used[0..bindings.len]) |v| if (!v) return error.Invalid;
            var yuv: [64]u32 = @splat(0);
            yuv[0] = h.format;
            yuv[1] = h.filter;
            for (packet.matrix, 0..) |row, i| for (row, 0..) |v, j| {
                yuv[4 + i * 4 + j] = @bitCast(v);
            };
            yuv[16] = h.chroma_x;
            yuv[17] = h.chroma_y;
            yuv[18] = @bitCast(@as(f32, if (h.format == 2) 1.0 / 1023.0 else 1.0 / 255.0));
            yuv[19] = if (h.format == 2) 6 else 0;
            const bounds: [4]f32 = .{ f(source.x), f(source.y), f(source.x) + f(source.width) - 1, f(source.y) + f(source.height) - 1 };
            const extent: [4]f32 = .{ f(h.width), f(h.height), f((h.width + 1) / 2), f((h.height + 1) / 2) };
            for (bounds, 0..) |v, i| yuv[20 + i] = @bitCast(v);
            for (extent, 0..) |v, i| yuv[24 + i] = @bitCast(v);
            store(payload, 768, yuv);
            var push: b.Push = .{ .tint = @splat(f(h.opacity) / 65535.0), .extent = extent };
            push.mapping = .{ f(source.width) / f(dest.width) / f(h.width), f(source.height) / f(dest.height) / f(h.height), (f(source.x) - f(dest.x) * f(source.width) / f(dest.width)) / f(h.width), (f(source.y) - f(dest.y) * f(source.height) / f(dest.height)) / f(h.height) };
            push.bounds = .{ (bounds[0] + 0.5) / f(h.width), (bounds[1] + 0.5) / f(h.height), (bounds[2] + 0.5) / f(h.width), (bounds[3] + 0.5) / f(h.height) };
            store(payload, 1024, push);
            if (clipped.width == 0) return 0;
            const shader_base = @import("asic.zig").Profiles(c).shaderBase(arch.device_id, arch.gc_version, arch.chip_revision) orelse return error.Unsupported;
            const vs = render.program(shader_base, shader_address);
            const ps = render.program(shader_base + 5, shader_address);
            const state = render.defaults(arch.gb_addr_config, h.blend == 1);
            var depth = std.mem.zeroes(c.R4AmdDepth);
            depth.version = 1;
            depth.size = @sizeOf(c.R4AmdDepth);
            var count: u32 = 0;
            try rc(render.pipeline(&vs, &ps, &state, &target.descriptors, &depth, words, words.len, &count));
            var draw = std.mem.zeroes(c.R4AmdDraw);
            draw.version = 1;
            draw.size = @sizeOf(c.R4AmdDraw);
            draw.descriptors = payload_address;
            draw.push_constants = payload_address + 1024;
            draw.count = 3;
            draw.instances = 1;
            draw.viewport_width = @bitCast(f(target.request.width));
            draw.viewport_height = @bitCast(f(target.request.height));
            draw.depth_max = @bitCast(@as(f32, 1));
            draw.scissor_x = @intCast(clipped.x);
            draw.scissor_y = @intCast(clipped.y);
            draw.scissor_end_x = draw.scissor_x + clipped.width;
            draw.scissor_end_y = draw.scissor_y + clipped.height;
            var n: u32 = 0;
            try rc(render.draw(&draw, words[count..].ptr, @intCast(words.len - count), &n));
            return count + n;
        }
    };
}
