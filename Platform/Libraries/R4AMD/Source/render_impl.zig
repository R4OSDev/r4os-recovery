// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Shared runtime and statically linked driver provider, using the same public
//! ABI types. Input validation precedes publication of caller-owned commands.
const std = @import("std");
pub fn Provider(comptime c: type) type {
    return struct {
        const Self = @This();
        pub const programs = @import("Generated/Shaders/shaders.zig").Programs(c).profiles;
        extern fn r4amd_native_pipeline(*const c.R4AmdShader, *const c.R4AmdShader, *const c.R4AmdPipeline, *const c.R4AmdImageDescriptors, *const c.R4AmdDepth, [*]u32, u32, *u32) callconv(.c) i32;
        extern fn r4amd_native_draw(*const c.R4AmdDraw, [*]u32, u32, *u32) callconv(.c) i32;
        const Span = struct { address: usize, bytes: usize, alignment: usize };
        fn span(value: anytype) Span {
            const T = @typeInfo(@TypeOf(value)).pointer.child;
            return .{ .address = @intFromPtr(value), .bytes = @sizeOf(T), .alignment = @alignOf(T) };
        }
        fn disjoint(spans: []const Span) bool {
            for (spans, 0..) |s, i| {
                if (s.address == 0 or s.address % s.alignment != 0 or s.bytes == 0 or s.bytes > std.math.maxInt(usize) - s.address) return false;
                for (spans[0..i]) |other| if (s.address < other.address + other.bytes and other.address < s.address + s.bytes) return false;
            }
            return true;
        }
        pub fn shader(profile: u32, code: [*]u8, capacity: u32, output: *c.R4AmdShader) callconv(.c) i32 {
            if (profile >= programs.len) return c.status_unsupported;
            const p = programs[profile];
            if (capacity < p.code.len or capacity > 65536) return c.status_limit;
            if (!disjoint(&.{ span(output), .{ .address = @intFromPtr(code), .bytes = capacity, .alignment = 1 } })) return c.status_invalid;
            @memcpy(code[0..p.code.len], p.code);
            output.* = p.metadata;
            return c.status_ok;
        }
        pub fn pipeline(vs: *const c.R4AmdShader, ps: *const c.R4AmdShader, state: *const c.R4AmdPipeline, color: *const c.R4AmdImageDescriptors, depth: *const c.R4AmdDepth, output: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
            if (capacity < 384 or capacity > 2048) return c.status_limit;
            if (!disjoint(&.{ span(vs), span(ps), span(state), span(color), span(depth), span(written), .{ .address = @intFromPtr(output), .bytes = @as(usize, capacity) * 4, .alignment = 4 } })) return c.status_invalid;
            var words: [384]u32 = undefined;
            var count: u32 = 0;
            const rc = r4amd_native_pipeline(vs, ps, state, color, depth, &words, words.len, &count);
            if (rc != 0) return rc;
            if (count == 0 or count > words.len) @trap();
            @memcpy(output[0..count], words[0..count]);
            written.* = count;
            return c.status_ok;
        }
        pub fn draw(request: *const c.R4AmdDraw, output: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
            if (capacity < 80 or capacity > 2048) return c.status_limit;
            if (!disjoint(&.{ span(request), span(written), .{ .address = @intFromPtr(output), .bytes = @as(usize, capacity) * 4, .alignment = 4 } })) return c.status_invalid;
            var words: [80]u32 = undefined;
            var count: u32 = 0;
            const rc = r4amd_native_draw(request, &words, words.len, &count);
            if (rc != 0) return rc;
            if (count == 0 or count > words.len) @trap();
            @memcpy(output[0..count], words[0..count]);
            written.* = count;
            return c.status_ok;
        }
        pub fn defaults(gb: u32, over: bool) c.R4AmdPipeline {
            var p = std.mem.zeroes(c.R4AmdPipeline);
            p.version = 1;
            p.size = @sizeOf(c.R4AmdPipeline);
            p.gb_addr_config = gb;
            p.write_mask = 15;
            p.rop = 0xcc;
            p.polygon = 2;
            p.primitive = 3;
            p.depth_clip = 1;
            p.depth_compare = 7;
            p.depth_max = @bitCast(@as(f32, 1));
            p.line_width = @bitCast(@as(f32, 1));
            p.stencil_compare = 7;
            p.back_compare = 7;
            p.stencil_read_mask = 255;
            p.stencil_write_mask = 255;
            p.back_read_mask = 255;
            p.back_write_mask = 255;
            p.blend_enable = @intFromBool(over);
            p.src_rgb = 1;
            p.src_alpha = 1;
            p.dst_rgb = if (over) 5 else 0;
            p.dst_alpha = p.dst_rgb;
            return p;
        }
        pub fn programOffset(profile: usize) usize {
            std.debug.assert(profile < programs.len);
            var offset: usize = 0;
            for (programs[0..profile]) |p| offset += std.mem.alignForward(usize, p.code.len, 256);
            return offset;
        }
        pub fn programBytes() usize {
            return programOffset(programs.len - 1) + std.mem.alignForward(usize, programs[programs.len - 1].code.len, 256);
        }
        pub fn program(profile: usize, base: u64) c.R4AmdShader {
            std.debug.assert(profile < programs.len and base != 0 and base & 255 == 0 and base < (@as(u64, 1) << 48) - programBytes());
            var result = programs[profile].metadata;
            result.code_address = base + programOffset(profile);
            return result;
        }
        pub fn upload(output: []volatile u8) error{Capacity}!void {
            if (output.len != programBytes()) return error.Capacity;
            for (output) |*v| v.* = 0;
            for (programs, 0..) |p, i| {
                for (p.code, output[programOffset(i)..][0..p.code.len]) |src, *dst| dst.* = src;
            }
        }
    };
}
