// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! GPU-only NV12/I420 preparation into native block-linear NV12 planes, with
//! replicated macroblock/pitch edges. The authenticated render target owns
//! addressing; fragment coordinates remain ordinary sample coordinates.
const std = @import("std");
const image = @import("render_image.zig");
pub const Format = enum(u32) { nv12 = 1, yuv420p = 3 };
pub const Plane = enum(u32) { luma = 0, chroma = 1 };
pub const Program = extern struct { words: [64]u32 = @splat(0) };
pub const Sampling = struct {
    format: Format,
    chroma: image.Image,
    second: ?image.Image = null,
    plane: Plane,
    // Visible input extent, independent of authenticated texture storage.
    // Shrinking a block-linear TIC to a crop can change its tile addressing.
    extent: [2]u32,
    pub fn planeCount(self: Sampling) u32 { return if (self.format == .yuv420p) 3 else 2; }
    pub fn validate(self: Sampling, luma: image.Image, target: image.Image) image.Error!void {
        const width = self.extent[0];
        const height = self.extent[1];
        if (luma.format != .r8 or width < 16 or height < 16 or width > 4096 or
            height > 4096 or (width | height) & 1 != 0 or width > luma.width or height > luma.height) return error.Unsupported;
        _ = try image.textureTyped(luma, .unsigned_integer);
        try checkPlane(self.extent, self.chroma, if (self.format == .nv12) .rg8 else .r8);
        if (self.format == .yuv420p) try checkPlane(self.extent, self.second orelse return error.Bounds, .r8)
        else if (self.second != null) return error.Unsupported;
        // Shared native NV12 allocation has at least32 storage rows. Chroma
        // covers half that extent; it is not separately rounded to16 rows.
        const pitch = std.mem.alignForward(u32, width, 64);
        const storage_rows = @max(std.mem.alignForward(u32, height, 16), 32);
        const rows = if (self.plane == .luma) storage_rows else storage_rows / 2;
        if (target.format != .r8 or target.layout != .blocklinear or target.width != pitch or target.pitch != pitch or
            target.height != rows) return error.Unsupported;
        _ = try image.target(target);
    }
    pub fn program(self: Sampling, target: image.Image) Program {
        var value: Program = .{};
        value.words[0..5].* = .{ @intFromEnum(self.format), @intFromEnum(self.plane), target.pitch, self.extent[0], self.extent[1] };
        return value;
    }
};
fn checkPlane(extent: [2]u32, plane: image.Image, format: image.Format) image.Error!void {
    if (plane.format != format or plane.width < extent[0] / 2 or plane.height < extent[1] / 2) return error.Bounds;
    _ = try image.textureTyped(plane, .unsigned_integer);
}
comptime { if (@sizeOf(Program) != 256) @compileError("encode constant buffer ABI"); }
