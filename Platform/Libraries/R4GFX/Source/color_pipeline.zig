//! Bounded CPU color execution. Profiles are compiled once by COLOR_V1 and
//! applied in batches. The only working space is premultiplied linear
//! BT.2020, in cd/m2; neither interpolation nor OVER mixes encoded samples.
const std = @import("std");
const c = @import("r4l_contract");
const d = @import("device.zig");
const color = @import("color.zig");
const pixels = @import("color_pixels.zig");
const icc = @import("color_icc.zig");
const yuv = @import("color_yuv.zig");
const tile_width = 64;
const sample_capacity = tile_width * 4;
const Value = color.Value;

fn scaled(rgb: color.Rgb, factor: f32) color.Rgb { return .{ rgb[0] * factor, rgb[1] * factor, rgb[2] * factor }; }

// Bradford adaptation from ICC's D50 PCS to the D65 working white. The
// matrices are derived once, not re-evaluated for individual image pixels.
fn workingFromPcs() color.Matrix {
    const bradford: color.Matrix = .{ .rows = .{ .{ 0.8951, 0.2664, -0.1614 }, .{ -0.7502, 1.7135, 0.0367 }, .{ 0.0389, -0.0685, 1.0296 } } };
    const d50 = [3]f64{ 0.9642, 1, 0.8249 };
    const d65 = [3]f64{ 0.3127 / 0.3290, 1, (1 - 0.3127 - 0.3290) / 0.3290 };
    var diagonal = color.Matrix.identity;
    for (0..3) |i| {
        const row = bradford.rows[i];
        diagonal.rows[i][i] = (row[0] * d65[0] + row[1] * d65[1] + row[2] * d65[2]) /
            (row[0] * d50[0] + row[1] * d50[1] + row[2] * d50[2]);
    }
    const adaptation = (bradford.inverse() catch unreachable).multiply(diagonal).multiply(bradford);
    const inverse = (color.chromaticities(.bt2020).xyz() catch unreachable).inverse() catch unreachable;
    return inverse.multiply(adaptation);
}
const from_pcs = workingFromPcs();
const to_pcs = from_pcs.inverse() catch unreachable;

pub const Image = struct {
    storage: c.R4GfxCpuImage,
    description: color.Description,
    format: pixels.Format,
    encoding: ?color.Encoding,
    profile: ?*const icc.Profile,

    pub fn init(storage: c.R4GfxCpuImage, description: color.Description, profile: ?*const icc.Profile) d.Error!Image {
        if (storage.width == 0 or storage.height == 0 or storage.reserved != 0 or storage.cpu_address == 0) return error.Invalid;
        const format = std.enums.fromInt(pixels.Format, storage.format) orelse return error.Unsupported;
        format.validate(description) catch |err| return if (err == error.Invalid) error.Invalid else error.Unsupported;
        if (storage.pitch < @as(u64, storage.width) * format.bytes()) return error.Invalid;
        const length = std.math.mul(u64, storage.pitch, storage.height) catch return error.Overflow;
        if (length > storage.byte_length) return error.Invalid;
        _ = std.math.add(u64, storage.cpu_address, storage.byte_length) catch return error.Overflow;
        if ((description.transfer == .icc) != (profile != null)) return error.Invalid;
        return .{ .storage = storage, .description = description, .format = format, .profile = profile,
            .encoding = if (profile == null) color.Encoding.initFast(description) catch return error.Unsupported else null };
    }
    fn address(self: *const Image, x: u32, y: u32) [*]u8 {
        return @ptrFromInt(self.storage.cpu_address + @as(u64, y) * self.storage.pitch + @as(u64, x) * self.format.bytes());
    }
    fn load(self: *const Image, x: u32, y: u32) Value { return pixels.load(self.format, self.address(x, y)); }
    fn decode(self: *const Image, samples: []Value) d.Error!void {
        if (self.encoding) |*encoding| {
            for (samples) |*value| value.* = encoding.decode(value.rgb, value.alpha);
        } else {
            var input: [sample_capacity]color.Rgb = undefined;
            var output: [sample_capacity]color.Rgb = undefined;
            for (samples, 0..) |*value, i| {
                if (self.description.alpha == .ignore) value.alpha = 1;
                input[i] = if (value.alpha == 0) @splat(0) else if (self.description.alpha == .electrical)
                    scaled(value.rgb, 1 / value.alpha) else value.rgb;
            }
            self.profile.?.apply(input[0..samples.len], output[0..samples.len]) catch |err| return profileError(err);
            for (samples, output[0..samples.len]) |*value, rgb| value.rgb = scaled(from_pcs.applyFast(rgb), self.description.reference_white * value.alpha);
        }
        for (samples) |value| if (!pixels.finite(value)) return error.Invalid;
    }
    fn encode(self: *const Image, samples: []Value) d.Error!void {
        if (self.encoding) |*encoding| {
            for (samples) |*value| value.* = encoding.encode(value.*);
        } else {
            var input: [sample_capacity]color.Rgb = undefined;
            var output: [sample_capacity]color.Rgb = undefined;
            for (samples, 0..) |*value, i| {
                if (self.description.alpha == .ignore) value.alpha = 1;
                input[i] = if (value.alpha == 0) @splat(0) else
                    scaled(to_pcs.applyFast(value.rgb), 1 / (value.alpha * self.description.reference_white));
            }
            self.profile.?.apply(input[0..samples.len], output[0..samples.len]) catch |err| return profileError(err);
            for (samples, output[0..samples.len]) |*value, rgb| value.rgb = if (value.alpha == 0) @splat(0) else
                if (self.description.alpha == .electrical) scaled(rgb, value.alpha) else rgb;
        }
        for (samples) |value| if (!pixels.finite(value)) return error.Invalid;
    }
};
// Both inputs feed the same bounded linear-light composition and output
// policy. YUV reconstruction precedes the EOTF and RGB interpolation.
const Input = union(enum) {
    rgb: Image,
    yuv: yuv.Image,
    fn description(self: *const Input) color.Description {
        return switch (self.*) { .rgb => |*image| image.description, .yuv => |*image| image.encoding.description };
    }
    fn floating(self: *const Input) bool {
        return switch (self.*) { .rgb => |*image| image.format == .abgr16161616f, .yuv => false };
    }
    fn readBytes(self: *const Input) u64 {
        return switch (self.*) { .rgb => |*image| image.format.bytes(), .yuv => |*image| image.readBytes() };
    }
    fn rectangle(self: *const Input, rect: c.R4GfxRect) d.Error!void {
        switch (self.*) {
            .rgb => |image| try rectangleRgb(image, rect),
            .yuv => |*image| try image.rectangle(.{ .x = rect.x, .y = rect.y, .width = rect.width, .height = rect.height }),
        }
    }
    fn aliases(self: *const Input, address: u64, bytes: u64) bool {
        switch (self.*) {
            .rgb => |*image| return d.overlaps(image.storage.cpu_address, image.storage.byte_length, address, bytes),
            .yuv => |*image| for (image.planes) |plane| {
                if (d.overlaps(@intFromPtr(plane.bytes.ptr), plane.bytes.len, address, bytes)) return true;
            },
        }
        return false;
    }
    fn load(self: *const Input, x: u32, y: u32) Value {
        return switch (self.*) { .rgb => |*image| image.load(x, y), .yuv => |*image| image.load(x, y) };
    }
    fn decode(self: *const Input, samples: []Value) d.Error!void {
        switch (self.*) {
            .rgb => |*image| try image.decode(samples),
            .yuv => |*image| for (samples) |*value| { value.* = image.encoding.decode(value.rgb, 1); },
        }
    }
};
fn profileError(err: icc.Error) d.Error {
    return switch (err) { error.Memory => error.Limit, error.Alias => error.Alias, error.Unsupported => error.Unsupported, else => error.Invalid };
}
fn rectangleRgb(image: Image, rect: c.R4GfxRect) d.Error!void {
    if (rect.width == 0 or rect.height == 0 or rect.x >= image.storage.width or rect.y >= image.storage.height or
        rect.width > image.storage.width - rect.x or rect.height > image.storage.height - rect.y) return error.Invalid;
}
const Axis = struct { low: u32, high: u32, weight: f32 };
fn coordinate(value: u32, source: u32, target: u32, linear: bool) Axis {
    const position = (@as(f64, @floatFromInt(value)) + 0.5) * @as(f64, @floatFromInt(source)) / @as(f64, @floatFromInt(target));
    if (!linear) {
        const nearest: u32 = @intFromFloat(@min(@floor(position), @as(f64, @floatFromInt(source - 1))));
        return .{ .low = nearest, .high = nearest, .weight = 0 };
    }
    const clamped = std.math.clamp(position - 0.5, 0, @as(f64, @floatFromInt(source - 1)));
    const low: u32 = @intFromFloat(@floor(clamped));
    return .{ .low = low, .high = @min(low + 1, source - 1), .weight = @floatCast(clamped - @floor(clamped)) };
}
fn gather(source: *const Input, request: c.R4GfxColorTransform, x: u32, y: u32, samples: []Value, weights: [][2]f32) void {
    const linear = request.sampler == c.render_sampler_bilinear;
    const across = if (linear) @as(usize, 4) else 1;
    const sy = coordinate(y, request.source_rect.height, request.target_rect.height, linear);
    for (weights, 0..) |*weight, i| {
        const sx = coordinate(x + @as(u32, @intCast(i)), request.source_rect.width, request.target_rect.width, linear);
        weight.* = .{ sx.weight, sy.weight };
        samples[i * across] = source.load(request.source_rect.x + sx.low, request.source_rect.y + sy.low);
        if (linear) {
            samples[i * across + 1] = source.load(request.source_rect.x + sx.high, request.source_rect.y + sy.low);
            samples[i * across + 2] = source.load(request.source_rect.x + sx.low, request.source_rect.y + sy.high);
            samples[i * across + 3] = source.load(request.source_rect.x + sx.high, request.source_rect.y + sy.high);
        }
    }
}

pub fn execute(source: Image, target: Image, request: c.R4GfxColorTransform) d.Error!c.R4GfxCpuStats {
    return executeInput(.{ .rgb = source }, target, request);
}
pub fn executeYuv(source: yuv.Image, target: Image, request: c.R4GfxColorTransform) d.Error!c.R4GfxCpuStats {
    return executeInput(.{ .yuv = source }, target, request);
}
fn executeInput(source: Input, target: Image, request: c.R4GfxColorTransform) d.Error!c.R4GfxCpuStats {
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxColorTransform) or request.flags & ~@as(u32, 7) != 0 or request.opacity > 65535) return error.Invalid;
    if ((request.sampler != c.render_sampler_nearest and request.sampler != c.render_sampler_bilinear) or
        (request.operation != c.render_operation_blit and request.operation != c.render_operation_over)) return error.Unsupported;
    const output_mapping = request.flags & c.color_transform_output != 0;
    const blend = request.operation == c.render_operation_over;
    if (target.profile != null and (blend or !output_mapping)) return error.Unsupported;
    try source.rectangle(request.source_rect);
    try rectangleRgb(target, request.target_rect);
    const count: u64 = @as(u64, request.target_rect.width) * request.target_rect.height;
    if (request.pixel_budget > c.render_max_pixels or count > request.pixel_budget) return error.Limit;
    if (source.aliases(target.storage.cpu_address, target.storage.byte_length)) return error.Alias;
    const tone = color.ToneMap.init(source.description(), target.description, request.flags & c.color_transform_relative_white != 0) catch return error.Invalid;
    var mapper = tone;
    mapper.gain = 1;
    if (blend) mapper = color.ToneMap.init(.{ .primaries = .bt2020, .transfer = .linear,
        .reference_white = target.description.reference_white, .peak = @max(tone.source_peak, target.description.peak) }, target.description, false) catch return error.Invalid;
    const across: usize = if (request.sampler == c.render_sampler_bilinear) 4 else 1;
    var samples: [sample_capacity]Value = undefined;
    var destination: [tile_width]Value = undefined;
    var resolved: [tile_width]Value = undefined;
    var weights: [tile_width][2]f32 = undefined;
    var stats: c.R4GfxCpuStats = .{ .pixels = count, .commands = 1, .reserved = 0,
        .read_bytes = count * (source.readBytes() * across + @as(u64, if (blend) target.format.bytes() else 0)), .write_bytes = count * target.format.bytes() };
    // Complete small operations fit in the existing scratch. Gather and
    // validate once before any store, then consume those stable samples.
    // Larger operations keep the whole-request preflight (late NaN/Inf must
    // never cause partial publication), followed by bounded execution chunks.
    const needs_preflight = source.floating() or (blend and target.format == .abgr16161616f);
    const staged = needs_preflight and count <= tile_width;
    if (staged) {
        for (0..request.target_rect.height) |row| {
            const first = row * request.target_rect.width;
            const last = first + request.target_rect.width;
            gather(&source, request, 0, @intCast(row), samples[first * across .. last * across], weights[first..last]);
            if (blend) for (destination[first..last], 0..) |*value, i| {
                value.* = target.load(request.target_rect.x + @as(u32, @intCast(i)), request.target_rect.y + @as(u32, @intCast(row)));
            };
        }
        if (source.floating()) for (samples[0..@as(usize, @intCast(count)) * across]) |value| {
            if (!pixels.finite(value)) return error.Invalid;
        };
        if (blend and target.format == .abgr16161616f) for (destination[0..@intCast(count)]) |value| {
            if (!pixels.finite(value)) return error.Invalid;
        };
    } else if (needs_preflight) {
        var y: u32 = 0;
        while (y < request.target_rect.height) : (y += 1) {
            var x: u32 = 0;
            while (x < request.target_rect.width) {
                const n = @min(tile_width, request.target_rect.width - x);
                if (source.floating()) {
                    gather(&source, request, x, y, samples[0 .. n * across], weights[0..n]);
                    for (samples[0 .. n * across]) |value| if (!pixels.finite(value)) return error.Invalid;
                }
                if (blend and target.format == .abgr16161616f) for (0..n) |i| {
                    if (!pixels.finite(target.load(request.target_rect.x + x + @as(u32, @intCast(i)), request.target_rect.y + y))) return error.Invalid;
                };
                x += n;
            }
        }
        if (source.floating()) stats.read_bytes += count * across * source.readBytes();
        if (blend and target.format == .abgr16161616f) stats.read_bytes += count * target.format.bytes();
    }
    const opacity = @as(f32, @floatFromInt(request.opacity)) / 65535;
    var y: u32 = 0;
    while (y < request.target_rect.height) : (y += 1) {
        var x: u32 = 0;
        while (x < request.target_rect.width) {
            const n = @min(tile_width, request.target_rect.width - x);
            const first: usize = if (staged) @as(usize, y) * request.target_rect.width else 0;
            const tile_samples = samples[first * across ..][0 .. n * across];
            const tile_weights = weights[first..][0..n];
            const tile_destination = destination[first..][0..n];
            if (!staged) gather(&source, request, x, y, tile_samples, tile_weights);
            try source.decode(tile_samples);
            if (blend) {
                if (!staged) for (tile_destination, 0..) |*value, i| {
                    value.* = target.load(request.target_rect.x + x + @as(u32, @intCast(i)), request.target_rect.y + y);
                };
                try target.decode(tile_destination);
            }
            for (resolved[0..n], 0..) |*value, i| {
                value.* = if (across == 1) tile_samples[i] else color.interpolate(
                    color.interpolate(tile_samples[i * 4], tile_samples[i * 4 + 1], tile_weights[i][0]),
                    color.interpolate(tile_samples[i * 4 + 2], tile_samples[i * 4 + 3], tile_weights[i][0]), tile_weights[i][1]);
                // Paper-white scaling belongs to source admission. Output
                // tone mapping happens after this draw's linear blend.
                value.rgb = scaled(value.rgb, tone.gain);
                value.* = if (blend) color.over(value.*, tile_destination[i], opacity) else .{ .rgb = scaled(value.rgb, opacity), .alpha = value.alpha * opacity };
                if (output_mapping) {
                    value.* = mapper.apply(value.*);
                    if (target.encoding) |*encoding| {
                        const alpha = if (target.description.alpha == .ignore) 1 else value.alpha;
                        if (alpha > 0) {
                            const rgb = scaled(encoding.from_working.applyFast(value.rgb), 1 / alpha);
                            const mapped = color.gamutMap(rgb, color.luminance(value.rgb) / alpha, target.description.peak);
                            value.rgb = scaled(encoding.to_working.applyFast(mapped), alpha);
                        }
                    }
                }
            }
            try target.encode(resolved[0..n]);
            for (resolved[0..n], 0..) |value, i| {
                const tx = request.target_rect.x + x + @as(u32, @intCast(i));
                const ty = request.target_rect.y + y;
                pixels.store(target.format, target.address(tx, ty), value, tx, ty, request.flags & c.color_transform_dither != 0);
            }
            x += n;
        }
    }
    return stats;
}
