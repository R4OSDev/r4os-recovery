// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Fixed YUV sampling parameters. R4GFX supplies the color interpretation;
//! this boundary validates views and serializes CBuf3 for profile8.
const std = @import("std");
const image = @import("render_image.zig");
pub const Format = enum(u32) { nv12 = 1, p010 = 2, yuv420p = 3 };
pub const Program = extern struct { words: [64]u32 = @splat(0) };
pub const Sampling = struct {
    format: Format,
    chroma: image.Image,
    second: ?image.Image = null,
    matrix: [3][4]f32,
    origin: [2]f32,
    pub fn planeCount(self: Sampling) u32 { return if (self.format == .yuv420p) 3 else 2; }
    pub fn validate(self: Sampling, luma: image.Image) image.Error!void {
        _ = try image.textureTyped(luma, .unsigned_integer);
        if (luma.format != @as(image.Format, if (self.format == .p010) .r16 else .r8)) return error.Unsupported;
        try plane(luma, self.chroma, switch (self.format) { .nv12 => .rg8, .p010 => .rg16, .yuv420p => .r8 });
        if (self.format == .yuv420p) try plane(luma, self.second orelse return error.Bounds, .r8)
        else if (self.second != null) return error.Unsupported;
        for (self.matrix) |row| for (row) |value| {
            if (!std.math.isFinite(value) or @abs(value) > 16) return error.Bounds;
        };
        if ((self.origin[0] != 0 and self.origin[0] != 0.5) or
            (self.origin[1] != 0 and self.origin[1] != 0.5 and self.origin[1] != 1)) return error.Bounds;
    }
    pub fn program(self: Sampling, luma: image.Image, rect: anytype, filter: image.Filter) Program {
        var result: Program = .{};
        result.words[0] = @intFromEnum(self.format);
        result.words[1] = @intFromBool(filter == .bilinear);
        for (self.matrix, 0..) |row, i| vector(&result, 16 + i * 16, row);
        vector(&result, 64, .{ self.origin[0], self.origin[1], if (self.format == .p010) 1.0 / 1023.0 else 1.0 / 255.0, 0 });
        result.words[19] = if (self.format == .p010) 6 else 0;
        vector(&result, 80, .{ @floatFromInt(rect.x), @floatFromInt(rect.y),
            @floatFromInt(@as(i64, rect.x) + rect.width - 1), @floatFromInt(@as(i64, rect.y) + rect.height - 1) });
        vector(&result, 96, .{ @floatFromInt(luma.width), @floatFromInt(luma.height),
            @floatFromInt(self.chroma.width), @floatFromInt(self.chroma.height) });
        return result;
    }
};
fn plane(luma: image.Image, chroma: image.Image, format: image.Format) image.Error!void {
    if (chroma.format != format or chroma.width != (luma.width + 1) / 2 or chroma.height != (luma.height + 1) / 2) return error.Bounds;
    _ = try image.textureTyped(chroma, .unsigned_integer);
}
fn vector(program: *Program, offset: usize, value: [4]f32) void {
    for (value, 0..) |item, i| program.words[offset / 4 + i] = @bitCast(item);
}
comptime { if (@sizeOf(Program) != 256) @compileError("YUV constant buffer ABI"); }
