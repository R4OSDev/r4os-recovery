//! Portable fixed color-program coefficients. R4GFX owns characterization,
//! white scaling, range and tone policy. The queue transports a bounded copy;
//! a native userland backend evaluates it with its fixed fragment shader.
const color = @import("color.zig");
const c = @import("r4l_contract");
pub const Program = extern struct {
    words: [64]u32 = @splat(0),
    fn vector(self: *Program, offset: usize, values: [4]f32) void {
        for (values, 0..) |value, i| self.words[offset / 4 + i] = @bitCast(value);
    }
    fn matrix(self: *Program, offset: usize, value: color.Matrix) void {
        for (value.rows, 0..) |row, i| self.vector(offset + 16 * i,
            .{ @floatCast(row[0]), @floatCast(row[1]), @floatCast(row[2]), 0 });
    }
    pub fn scalar(self: Program, offset: usize) f32 { return @bitCast(self.words[offset / 4]); }
};
fn transfer(desc: color.Description) [4]f32 {
    return .{ desc.reference_white, desc.peak,
        if (desc.transfer == .hlg) color.hlgGamma(desc.peak) else 1,
        if (desc.transfer == .hlg) color.hlgBeta(desc) else if (desc.transfer == .bt1886) color.bt1886Lift(desc) else 0 };
}
pub fn build(source: color.Description, target: color.Description, flags: u32, over: bool) color.Error!Program {
    const from = try color.Encoding.init(source);
    const to = try color.Encoding.init(target);
    if (flags & ~@as(u32, 7) != 0 or source.precision == .unorm16 or target.precision == .unorm16) return error.Unsupported;
    const output = flags & c.color_transform_output != 0;
    const dither = flags & c.color_transform_dither != 0;
    // The fixed-function OVER stage must see linear premultiplied light.
    // Mapping a completed output and reading/blending the destination are
    // distinct draws; encoded-domain OVER is never silently selected.
    if (over and (output or target.transfer != .linear or target.alpha != .optical or target.range != .full)) return error.Unsupported;
    if (dither and (target.precision == .float16 or !output)) return error.Unsupported;
    const mapper = try color.ToneMap.init(source, target, flags & c.color_transform_relative_white != 0);
    var result: Program = .{};
    result.words[0] = @intFromBool(output) | (@as(u32, @intFromBool(dither)) << 1);
    result.words[1] = @intFromEnum(source.transfer);
    result.words[2] = @intFromEnum(target.transfer);
    result.words[3] = @intFromEnum(source.alpha);
    result.words[4] = @intFromEnum(target.alpha);
    result.matrix(32, from.to_working);
    result.matrix(80, to.from_working);
    result.vector(128, transfer(source));
    result.vector(144, transfer(target));
    const source_zero = color.unpackRange(source, @splat(0))[0];
    const source_one = color.unpackRange(source, @splat(1))[0];
    const target_zero = color.packRange(target, @splat(0))[0];
    const target_one = color.packRange(target, @splat(1))[0];
    result.vector(160, .{ source_one - source_zero, source_zero, target_one - target_zero, target_zero });
    result.vector(176, .{ mapper.gain, mapper.source_peak, mapper.knee, mapper.shoulder });
    result.vector(192, .{ target.peak, if (dither) @as(f32, switch (target.precision) {
        .unorm8 => 1.0 / 255.0, .unorm10 => 1.0 / 1023.0, else => return error.Unsupported,
    }) else 0, 0, 0 });
    return result;
}
