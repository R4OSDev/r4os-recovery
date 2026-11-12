//! Explicit RGB storage, independent of transfer, primaries and alpha domain.
//! FourCC bit layouts follow DRM's documented little-endian formats; bytes are
//! read unaligned, so pitch padding and caller maps impose no hidden casts.
const std = @import("std");
const color = @import("color.zig");
pub const Format = enum(u32) {
    xrgb8888 = 0x34325258,
    argb8888 = 0x34325241,
    xrgb2101010 = 0x30335258,
    argb2101010 = 0x30335241,
    abgr16161616f = 0x48344241,
    abgr16161616 = 0x38344241,
    pub fn bytes(self: Format) u32 {
        return switch (self) {
            .abgr16161616f, .abgr16161616 => 8,
            else => 4,
        };
    }
    pub fn precision(self: Format) color.Precision {
        return switch (self) {
            .xrgb8888, .argb8888 => .unorm8,
            .xrgb2101010, .argb2101010 => .unorm10,
            .abgr16161616f => .float16,
            .abgr16161616 => .unorm16,
        };
    }
    pub fn alpha(self: Format) bool {
        return self != .xrgb8888 and self != .xrgb2101010;
    }
    pub fn validate(self: Format, description: color.Description) color.Error!void {
        try description.validate();
        if (description.precision != self.precision() or (!self.alpha() and description.alpha != .ignore)) return error.Invalid;
    }
};
pub fn load(format: Format, bytes: [*]const u8) color.Value {
    if (format == .abgr16161616) {
        var values: [4]f32 = undefined;
        inline for (0..4) |i| values[i] = @as(f32, @floatFromInt(std.mem.readInt(u16, bytes[i * 2 ..][0..2], .little))) / 65535;
        return .{ .rgb = values[0..3].*, .alpha = values[3] };
    }
    if (format == .abgr16161616f) {
        var values: [4]f32 = undefined;
        inline for (0..4) |i| values[i] = @as(f16, @bitCast(std.mem.readInt(u16, bytes[i * 2 ..][0..2], .little)));
        return .{ .rgb = values[0..3].*, .alpha = values[3] };
    }
    const value = std.mem.readInt(u32, bytes[0..4], .little);
    return if (format.precision() == .unorm8) .{
        .rgb = .{ @as(f32, @floatFromInt((value >> 16) & 255)) / 255, @as(f32, @floatFromInt((value >> 8) & 255)) / 255, @as(f32, @floatFromInt(value & 255)) / 255 },
        .alpha = if (format.alpha()) @as(f32, @floatFromInt(value >> 24)) / 255 else 1,
    } else .{
        .rgb = .{ @as(f32, @floatFromInt((value >> 20) & 1023)) / 1023, @as(f32, @floatFromInt((value >> 10) & 1023)) / 1023, @as(f32, @floatFromInt(value & 1023)) / 1023 },
        .alpha = if (format.alpha()) @as(f32, @floatFromInt(value >> 30)) / 3 else 1,
    };
}
pub fn finite(value: color.Value) bool {
    for (value.rgb) |v| if (!std.math.isFinite(v)) return false;
    return std.math.isFinite(value.alpha) and value.alpha >= 0 and value.alpha <= 1;
}
const bayer = [16]u8{ 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
fn quantize(value: f32, maximum: f32, rounding: f32) u32 {
    return @intFromFloat(@floor(std.math.clamp(value, 0, 1) * maximum + rounding));
}
// Stable, spatially anchored ordered dither; alpha is never dithered. Callers
// perform transfer/range encoding before this final quantization step.
pub fn store(format: Format, bytes: [*]u8, value: color.Value, x: u32, y: u32, dither: bool) void {
    if (format == .abgr16161616f) {
        const channels = [4]f32{ value.rgb[0], value.rgb[1], value.rgb[2], value.alpha };
        inline for (0..4) |i| {
            const half: f16 = @floatCast(std.math.clamp(channels[i], if (i == 3) 0 else -65504, if (i == 3) 1 else 65504));
            std.mem.writeInt(u16, bytes[i * 2 ..][0..2], @bitCast(half), .little);
        }
        return;
    }
    const rounding = if (dither) (@as(f32, @floatFromInt(bayer[(y & 3) * 4 + (x & 3)])) + 0.5) / 16 else 0.5;
    if (format == .abgr16161616) {
        const channels = [4]f32{ value.rgb[0], value.rgb[1], value.rgb[2], value.alpha };
        inline for (0..4) |i| std.mem.writeInt(u16, bytes[i * 2 ..][0..2], @intCast(quantize(channels[i], 65535, if (i == 3) 0.5 else rounding)), .little);
        return;
    }
    var pixel: u32 = 0;
    if (format.precision() == .unorm8) {
        pixel = (quantize(value.rgb[0], 255, rounding) << 16) | (quantize(value.rgb[1], 255, rounding) << 8) | quantize(value.rgb[2], 255, rounding);
        if (format.alpha()) pixel |= quantize(value.alpha, 255, 0.5) << 24;
    } else {
        pixel = (quantize(value.rgb[0], 1023, rounding) << 20) | (quantize(value.rgb[1], 1023, rounding) << 10) | quantize(value.rgb[2], 1023, rounding);
        if (format.alpha()) pixel |= quantize(value.alpha, 3, 0.5) << 30;
    }
    std.mem.writeInt(u32, bytes[0..4], pixel, .little);
}
