// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Common 2D commands -> genuine AddrLib descriptors, ACO code and GFX9 PM4.
//! The caller owns backing, VA, immutable shader storage and the completion
//! lifetime of one 4 KB parameter slot. No resource is allocated here.
const std = @import("std");
pub fn Provider(comptime c: type, comptime a: type) type {
    return struct {
        pub const render = @import("render_impl.zig").Provider(c);
        pub const images = @import("images_impl.zig").Provider(c);
        pub const Grid = @import("render_grid.zig").Grid;
        pub const Color = @import("render_color.zig").Program;
        pub const Error = error{ Invalid, Unsupported, Capacity, Bounds };
        pub const payload_bytes = 4096;
        pub const max_words = 2016;
        pub const Image = struct { request: c.R4AmdImageRequest, layout: c.R4AmdImageLayout, descriptors: c.R4AmdImageDescriptors };
        pub const Push = extern struct {
            mapping: [4]f32 = @splat(0),
            bounds: [4]f32 = @splat(0),
            tint: [4]f32 = @splat(0),
            flags: [4]u32 = @splat(0),
            grid: Grid = .{},
            atlas: [4]i32 = @splat(0),
            extent: [4]f32 = @splat(0),
        };
        comptime {
            if (@sizeOf(Push) != 160 or @offsetOf(Push, "grid") != 64) @compileError("AMD push ABI");
        }
        fn result(rc: i32) Error!void {
            switch (rc) {
                c.status_ok => {},
                c.status_unsupported => return error.Unsupported,
                c.status_limit, c.status_oom => return error.Capacity,
                else => return error.Invalid,
            }
        }
        pub fn image(arch: c.R4AmdArchitecture, adapter: u32, desc: a.GfxBufferDescriptor, address: u64, target: bool, filter: u32, scratch: *align(16) [65536]u8) Error!Image {
            if (arch.version != 1 or arch.size != @sizeOf(c.R4AmdArchitecture) or arch.flags != 0 or arch.reserved != 0 or
                arch.vendor_id != c.vendor_id or @import("asic.zig").Profiles(c).engines(arch.device_id, arch.gc_version, arch.sdma_version) == null or arch.bind_alignment != 4096 or
                desc.version != 1 or desc.size < @sizeOf(a.GfxBufferDescriptor) or desc.reserved0 != 0 or desc.plane_count != 1 or desc.plane_offsets[0] != 0 or
                desc.location != a.gfx_buffer_location_device_local or desc.adapter_id != adapter or desc.driver_owner == 0 or
                desc.device_generation != arch.memory_generation or desc.byte_length == 0 or desc.byte_length > 64 * 1024 * 1024 or desc.alignment < 4096 or
                desc.usage & (a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write) != 0 or filter > 1) return error.Invalid;
            for (1..4) |i| if (desc.plane_offsets[i] != 0 or desc.plane_pitches[i] != 0) return error.Invalid;
            if (target and desc.usage & a.gfx_buffer_usage_render == 0) return error.Invalid;
            const pitch = std.math.cast(u32, desc.plane_pitches[0]) orelse return error.Invalid;
            const sw: u32 = if (desc.modifier == 0) 0 else @intCast((desc.modifier >> 8) & 31);
            const usage: u32 = if (target) c.image_usage_color else c.image_usage_texture;
            const request: c.R4AmdImageRequest = .{ .version = 1, .size = @sizeOf(c.R4AmdImageRequest), .gb_addr_config = arch.gb_addr_config, .chip_revision = arch.chip_revision, .device_id = arch.device_id, .gc_version = arch.gc_version, .resource_type = 1, .format = desc.format, .width = desc.width, .height = desc.height, .depth = 1, .mip_count = 1, .samples = 1, .usage = usage, .swizzle = sw, .pipe_xor = 0, .pitch = pitch, .reserved = 0, .modifier = desc.modifier };
            var layout: c.R4AmdImageLayout = undefined;
            var mip: c.R4AmdMip = undefined;
            try result(images.importImage(&request, &.{ .version = 1, .size = @sizeOf(c.R4AmdImageImport), .byte_length = desc.byte_length, .alignment = desc.alignment, .offset = 0, .modifier = desc.modifier, .adapter_id = adapter, .reserved = 0, .memory_generation = arch.memory_generation, .expected_adapter = adapter, .metadata_state = 0, .expected_memory_generation = arch.memory_generation, .pitch = pitch, .usage = usage }, scratch, scratch.len, &layout, @ptrCast(&mip), 1));
            var view = std.mem.zeroes(c.R4AmdImageView);
            view.version = 1;
            view.size = @sizeOf(c.R4AmdImageView);
            view.address = address;
            view.byte_length = desc.byte_length;
            view.sampler = filter;
            view.flags = if (!target and desc.format == 538982482) 2 else 0;
            var descriptor: c.R4AmdImageDescriptors = undefined;
            try result(images.descriptors(&request, &view, scratch, scratch.len, &descriptor));
            return .{ .request = request, .layout = layout, .descriptors = descriptor };
        }
        pub fn bufferDescriptor(address: u64, bytes: u32) [4]u32 {
            std.debug.assert(address != 0 and address < (@as(u64, 1) << 48) and bytes != 0);
            // GFX9 raw R32_FLOAT identity selector; scalar loads address bytes.
            return .{ @truncate(address), @truncate(address >> 32), bytes, 0x00027fac };
        }
        fn store(payload: *[payload_bytes]u8, offset: usize, value: anytype) void {
            @memcpy(payload[offset..][0..@sizeOf(@TypeOf(value))], std.mem.asBytes(&value));
        }
        fn f(value: anytype) f32 {
            return @floatFromInt(value);
        }
        pub fn clip(command: a.GfxRenderCommand, width: u32, height: u32) Error!a.GfxRenderRect {
            const r = command.target_rect;
            const s = command.scissor;
            if (r.width == 0 or r.height == 0 or r.width > 32768 or r.height > 32768 or r.x < -32768 or r.y < -32768 or r.x > 32768 or r.y > 32768 or
                s.width == 0 or s.height == 0) return error.Bounds;
            const x = @max(@as(i64, 0), @max(r.x, s.x));
            const y = @max(@as(i64, 0), @max(r.y, s.y));
            const endx = @min(@as(i64, width), @min(@as(i64, r.x) + r.width, @as(i64, s.x) + s.width));
            const endy = @min(@as(i64, height), @min(@as(i64, r.y) + r.height, @as(i64, s.y) + s.height));
            if (endx <= x or endy <= y) return .{};
            return .{ .x = @intCast(x), .y = @intCast(y), .width = @intCast(endx - x), .height = @intCast(endy - y) };
        }
        /// Transactional in caller-owned scratch. The caller publishes both
        /// outputs only after success; a clipped-empty batch has no GPU draw.
        pub fn encode(source: ?Image, target: Image, commands: []const a.GfxRenderCommand, grids: []const a.GfxSampleGrid, color: ?Color, shader_address: u64, payload_address: u64, payload: *[payload_bytes]u8, words: *[max_words]u32) Error!usize {
            if (commands.len == 0 or commands.len > 16 or grids.len != commands.len or shader_address == 0 or shader_address & 255 != 0 or
                shader_address >= (@as(u64, 1) << 48) - render.programBytes() or payload_address == 0 or payload_address & 4095 != 0 or
                payload_address >= (@as(u64, 1) << 48) - payload_bytes) return error.Invalid;
            const first = commands[0];
            const sampled = first.kind == a.gfx_render_kind_sample;
            if (first.kind > 1 or first.filter > 1 or first.blend > 1 or first.transfer > 3 or sampled != (source != null) or
                (first.transfer == a.gfx_render_transfer_color) != (color != null) or (color != null and (!sampled or first.filter != 0))) return error.Unsupported;
            if (target.request.format == 538982482 and (first.blend != 0 or first.transfer != 0)) return error.Unsupported;
            if (color) |program| {
                try program.validate();
                if (first.blend == 1 and (program.words[0] & 1 != 0 or program.words[2] != 2 or program.words[4] != 4 or target.request.format != 1211384385)) return error.Unsupported;
                if (target.request.format == 1211384385 and program.words[0] & 2 != 0) return error.Unsupported;
            }
            @memset(payload, 0);
            if (color) |program| {
                store(payload, 0, bufferDescriptor(payload_address + 512, 256));
                store(payload, 512, program);
            }
            if (source) |src| {
                const d = src.descriptors;
                store(payload, 256, [8]u32{ d.texture0, d.texture1, d.texture2, d.texture3, d.texture4, d.texture5, d.texture6, d.texture7 });
                store(payload, 288, [4]u32{ d.sampler0, d.sampler1, d.sampler2, d.sampler3 });
            }
            const shader_base = @import("asic.zig").Profiles(c).shaderBase(target.request.device_id, target.request.gc_version, target.request.chip_revision) orelse return error.Unsupported;
            if (source) |input| if (input.request.device_id != target.request.device_id or input.request.gc_version != target.request.gc_version or
                input.request.chip_revision != target.request.chip_revision or input.request.gb_addr_config != target.request.gb_addr_config) return error.Unsupported;
            const vs = render.program(shader_base, shader_address);
            const ps = render.program(shader_base + @as(usize, if (color != null) 4 else if (sampled) 3 else 2), shader_address);
            const state = render.defaults(target.request.gb_addr_config, first.blend == a.gfx_render_blend_over);
            var depth = std.mem.zeroes(c.R4AmdDepth);
            depth.version = 1;
            depth.size = @sizeOf(c.R4AmdDepth);
            var count: u32 = 0;
            try result(render.pipeline(&vs, &ps, &state, &target.descriptors, &depth, words, words.len, &count));
            var draws: usize = 0;
            for (commands, grids, 0..) |cmd, g, index| {
                if (cmd.kind != first.kind or cmd.filter != first.filter or cmd.blend != first.blend or cmd.transfer != first.transfer or cmd.opacity > 255 or cmd.reserved0 != 0) return error.Invalid;
                const bounds = try clip(cmd, target.request.width, target.request.height);
                var push: Push = .{ .flags = .{ cmd.transfer, 0, 0, 0 } };
                const opacity = f(cmd.opacity) / 255.0;
                if (sampled) {
                    if (cmd.color != 0) return error.Invalid;
                    const src = source.?;
                    const rect = cmd.source_rect;
                    if (rect.x < 0 or rect.y < 0 or rect.width == 0 or rect.height == 0 or @as(u64, @intCast(rect.x)) + rect.width > src.request.width or
                        @as(u64, @intCast(rect.y)) + rect.height > src.request.height) return error.Bounds;
                    push.mapping = .{ f(rect.width) / f(cmd.target_rect.width) / f(src.request.width), f(rect.height) / f(cmd.target_rect.height) / f(src.request.height), 0, 0 };
                    push.mapping[2] = (f(rect.x) - f(cmd.target_rect.x) * f(rect.width) / f(cmd.target_rect.width)) / f(src.request.width);
                    push.mapping[3] = (f(rect.y) - f(cmd.target_rect.y) * f(rect.height) / f(cmd.target_rect.height)) / f(src.request.height);
                    push.bounds = .{ (f(rect.x) + 0.5) / f(src.request.width), (f(rect.y) + 0.5) / f(src.request.height), (f(rect.x) + f(rect.width) - 0.5) / f(src.request.width), (f(rect.y) + f(rect.height) - 0.5) / f(src.request.height) };
                    push.tint = @splat(opacity);
                    push.atlas = .{ rect.x, rect.y, 0, 0 };
                    push.extent = .{ f(src.request.width), f(src.request.height), 0, 0 };
                    push.grid = std.mem.bytesToValue(Grid, std.mem.asBytes(&g));
                    if (g.enabled != 0 and cmd.filter != 0) return error.Unsupported;
                    if (bounds.width != 0) try push.grid.validate(rect, bounds);
                } else {
                    if (cmd.filter != 0 or cmd.transfer != 0 or !std.meta.eql(cmd.source_rect, a.GfxRenderRect{}) or !std.meta.eql(g, a.GfxSampleGrid{})) return error.Invalid;
                    const alpha = f((cmd.color >> 24) & 255) / 255.0;
                    push.tint = .{ f((cmd.color >> 16) & 255) / 255.0 * opacity, f((cmd.color >> 8) & 255) / 255.0 * opacity, f(cmd.color & 255) / 255.0 * opacity, alpha * opacity };
                    if (target.request.format == 538982482) {
                        if (cmd.color > 255) return error.Invalid;
                        push.tint = .{ f(cmd.color) / 255.0 * opacity, 0, 0, opacity };
                    } else if (target.request.format == 875713112 or target.request.format == 808669784) {
                        push.tint[3] = opacity; // XRGB targets have no alpha channel.
                    } else if ((cmd.color >> 16) & 255 > (cmd.color >> 24) or (cmd.color >> 8) & 255 > (cmd.color >> 24) or cmd.color & 255 > (cmd.color >> 24)) return error.Invalid;
                }
                if (bounds.width == 0) continue;
                const offset = 1024 + index * @sizeOf(Push);
                store(payload, offset, push);
                var draw = std.mem.zeroes(c.R4AmdDraw);
                draw.version = 1;
                draw.size = @sizeOf(c.R4AmdDraw);
                draw.descriptors = payload_address;
                draw.push_constants = payload_address + offset;
                draw.count = 3;
                draw.instances = 1;
                draw.viewport_width = @bitCast(f(target.request.width));
                draw.viewport_height = @bitCast(f(target.request.height));
                draw.depth_max = @bitCast(@as(f32, 1));
                draw.scissor_x = @intCast(bounds.x);
                draw.scissor_y = @intCast(bounds.y);
                draw.scissor_end_x = draw.scissor_x + bounds.width;
                draw.scissor_end_y = draw.scissor_y + bounds.height;
                if (count > words.len - 80) return error.Capacity;
                var n: u32 = 0;
                try result(render.draw(&draw, words[count..].ptr, @intCast(words.len - count), &n));
                count += n;
                draws += 1;
            }
            return if (draws == 0) 0 else count;
        }
    };
}
