// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Shared diagnostic reference scenes. Expected pixels are frozen outputs of
//! R4GFX's integer CPU renderer, or an independent f64 color calculation.
const std = @import("std");
const r = @import("render.zig");
pub const target_bytes = 128 * 24;
pub const source_bytes = 32 * 5;
pub fn expectedPixels(scene_index: usize) []const u8 {
    const pixels = @embedFile("Fixtures/render-pixels.bin");
    comptime std.debug.assert(pixels.len == target_bytes * scenes.len);
    return pixels[scene_index * target_bytes..][0..target_bytes];
}
pub const Scene = struct {
    name: []const u8,
    format: r.image.Format = .argb8888,
    source_format: r.image.Format = .argb8888,
    solid: bool = false,
    transparent: bool = false,
    destination: r.Rect = .{ .x = 1, .y = 2, .width = 17, .height = 13 },
    source_rect: r.Rect = .{ .x = 1, .y = 1, .width = 5, .height = 3 },
    scissor: r.Rect = .{ .x = 0, .y = 0, .width = 32, .height = 24 },
    filter: r.image.Filter = .nearest,
    blend: r.Blend = .replace,
    transfer: r.Transfer = .identity,
    opacity: u8 = 255,
    tolerance: u8 = 0,
    pub fn draw(s: Scene) r.Draw {
        return .{
            .target = .{ .address = 0x100000, .bytes = target_bytes, .width = 32, .height = 24, .pitch = 128, .format = s.format, .layout = .linear },
            .source = if (s.solid) null else .{ .address = 0x200000, .bytes = source_bytes, .width = 7, .height = 5, .pitch = 32, .format = s.source_format, .layout = .linear },
            .destination = s.destination, .source_rect = s.source_rect, .scissor = s.scissor,
            .filter = s.filter, .blend = s.blend, .transfer = s.transfer, .opacity = s.opacity,
            .color = if (s.solid) 0x80402010 else 0,
        };
    }
    pub fn inside(s: Scene, x: u32, y: u32) bool {
        // Deliberately independent of the encoder's clip() helper.
        return @as(i64,x) >= s.destination.x and @as(i64,y) >= s.destination.y and
            @as(i64,x) < @as(i64,s.destination.x)+s.destination.width and @as(i64,y) < @as(i64,s.destination.y)+s.destination.height and
            @as(i64,x) >= s.scissor.x and @as(i64,y) >= s.scissor.y and
            @as(i64,x) < @as(i64,s.scissor.x)+s.scissor.width and @as(i64,y) < @as(i64,s.scissor.y)+s.scissor.height;
    }
};
pub const scenes = [_]Scene{
    .{ .name = "nearest-crop" },
    .{ .name = "bilinear-crop", .filter = .bilinear, .tolerance = 2 },
    .{ .name = "nearest-over", .blend = .over, .opacity = 137, .tolerance = 1 },
    .{ .name = "bilinear-over-scissor", .filter = .bilinear, .blend = .over, .opacity = 173, .tolerance = 3,
        .scissor = .{ .x = 3, .y = 3, .width = 12, .height = 10 } },
    .{ .name = "bilinear-xrgb", .format = .xrgb8888, .source_format = .xrgb8888, .filter = .bilinear, .tolerance = 2 },
    .{ .name = "bilinear-r8", .format = .r8, .source_format = .r8, .filter = .bilinear, .tolerance = 2 },
    .{ .name = "one-texel-crop", .filter = .bilinear, .source_rect = .{ .x = 3, .y = 2, .width = 1, .height = 1 } },
    .{ .name = "signed-clipped", .filter = .bilinear, .tolerance = 2,
        .destination = .{ .x = -3, .y = -2, .width = 17, .height = 13 } },
    .{ .name = "srgb-decode", .transfer = .decode_srgb, .tolerance = 1 },
    .{ .name = "srgb-encode-over", .transfer = .encode_srgb, .blend = .over, .opacity = 137, .tolerance = 1 },
    .{ .name = "zero-alpha-decode", .transfer = .decode_srgb, .transparent = true },
    .{ .name = "solid-replace", .solid = true },
    .{ .name = "solid-over", .solid = true, .blend = .over, .opacity = 137, .tolerance = 1 },
    .{ .name = "bilinear-one-to-one", .filter = .bilinear,
        .destination = .{ .x = 23, .y = 19, .width = 5, .height = 3 } },
};
pub fn initialize(scene: Scene, source: []u8, target: []u8) void {
    @memset(source, 0xcd); @memset(target, 0xcc);
    for (0..24) |y| for (0..32) |x| {
        if (scene.format == .r8) target[y*128+x] = 61
        else std.mem.writeInt(u32,target[y*128+x*4..][0..4],if (scene.format == .xrgb8888) 0xa5332244 else 0x90402010,.little);
    };
    for (0..5) |y| for (0..7) |x| {
        const border = x == 0 or x == 6 or y == 0 or y == 4;
        if (scene.source_format == .r8) {
            source[y*32+x] = if (border) 255 else @intCast((x*37+y*29)%256);
        } else {
            const alpha: u32 = if (scene.source_format == .xrgb8888) 255 else @intCast((x+2*y)%5*51);
            const red: u32 = @intCast(((x*43+y*17)%256*alpha+127)/255);
            const green: u32 = @intCast(((x*13+y*59)%256*alpha+127)/255);
            const blue: u32 = @intCast(((x*71+y*7)%256*alpha+127)/255);
            const value: u32 = if (scene.transparent) 0 else if (border) 0xffff00ff else
                ((if (scene.source_format == .xrgb8888) @as(u32,0x77) else alpha)<<24)|(red<<16)|(green<<8)|blue;
            std.mem.writeInt(u32,source[y*32+x*4..][0..4],value,.little);
        }
    };
}
