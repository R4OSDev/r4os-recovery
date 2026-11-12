// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Shared R4OS color/grid semantics, independently bound to the AMD shader ABI.
//! Bounds for the integer sampling descriptor consumed by the fixed shader.
//! Only four clipped corners are checked on the CPU; pixels stay on the GPU.
const std = @import("std");
pub const Grid = extern struct {
    enabled: u32 = 0,
    rotation: u32 = 0,
    scale: u32 = 0,
    pixel_width: u32 = 0,
    pixel_height: u32 = 0,
    target_x: i32 = 0,
    target_y: i32 = 0,
    reserved: u32 = 0,
    viewport_x: i32 = 0,
    viewport_y: i32 = 0,
    viewport_width: u32 = 0,
    viewport_height: u32 = 0,
    guest_width: u32 = 0,
    guest_height: u32 = 0,
    source_x: u32 = 0,
    source_y: u32 = 0,

    pub fn validate(self: Grid, source: anytype, clip: anytype) error{Bounds}!void {
        if (self.enabled == 0) {
            if (!std.meta.eql(self, Grid{})) return error.Bounds;
            return;
        }
        if (self.enabled != 1 or self.reserved != 0 or self.rotation > 3 or self.scale < 60 or self.scale > 960 or
            self.pixel_width == 0 or self.pixel_height == 0 or self.viewport_width == 0 or self.viewport_height == 0 or
            self.guest_width == 0 or self.guest_height == 0 or self.target_x < 0 or self.target_y < 0 or
            self.target_x > 32768 or self.target_y > 32768 or self.viewport_x < -32768 or self.viewport_y < -32768 or
            self.viewport_x > 32768 or self.viewport_y > 32768) return error.Bounds;
        for ([_]u32{ self.pixel_width, self.pixel_height, self.viewport_width, self.viewport_height, self.guest_width, self.guest_height }) |value|
            if (value > 32768) return error.Bounds;
        if (@as(u64, self.source_x) + source.width > self.guest_width or @as(u64, self.source_y) + source.height > self.guest_height) return error.Bounds;
        // The two integer divisions are monotone on each rotated axis. Four
        // corners prove the complete rectangular submission stays in source.
        for ([_]i64{ clip.x, @as(i64, clip.x) + clip.width - 1 }) |x|
            for ([_]i64{ clip.y, @as(i64, clip.y) + clip.height - 1 }) |y| {
                const selected = try self.sample(x, y);
                if (selected[0] >= source.width or selected[1] >= source.height) return error.Bounds;
            };
    }
    pub fn sample(self: Grid, x: i64, y: i64) error{Bounds}![2]u32 {
        const px = x + self.target_x;
        const py = y + self.target_y;
        if (px < 0 or py < 0 or px >= self.pixel_width or py >= self.pixel_height) return error.Bounds;
        const oriented: [2]i64 = switch (self.rotation) {
            0 => .{ px, py },
            1 => .{ self.pixel_height - 1 - py, px },
            2 => .{ self.pixel_width - 1 - px, self.pixel_height - 1 - py },
            3 => .{ py, self.pixel_width - 1 - px },
            else => return error.Bounds,
        };
        const logical_x = @divFloor((2 * oriented[0] + 1) * 120, 2 * @as(i64, self.scale)) - self.viewport_x;
        const logical_y = @divFloor((2 * oriented[1] + 1) * 120, 2 * @as(i64, self.scale)) - self.viewport_y;
        if (logical_x < 0 or logical_y < 0 or logical_x >= self.viewport_width or logical_y >= self.viewport_height) return error.Bounds;
        const sx = @divFloor(logical_x * self.guest_width, self.viewport_width) - self.source_x;
        const sy = @divFloor(logical_y * self.guest_height, self.viewport_height) - self.source_y;
        if (sx < 0 or sy < 0) return error.Bounds;
        return .{ @intCast(sx), @intCast(sy) };
    }
};
comptime {
    if (@sizeOf(Grid) != 64) @compileError("fixed grid descriptor");
}
