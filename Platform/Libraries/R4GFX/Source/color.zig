//! Userland color arithmetic. Working values are premultiplied, display-linear
//! BT.2020 RGB in cd/m2; alpha is always linear. There is no driver or kernel
//! policy here. Independently implemented from ICC sRGB characterization and
//! ITU-R BT.2100-3, Tables 2/4/5/9. Exact originals: GFX/0.79.25/Sources.json.
const std = @import("std");
pub const Error = error{ Invalid, Unsupported, Singular };
pub const Primaries = enum(u32) { srgb = 1, display_p3 = 2, bt2020 = 3, icc = 4, bt601_625 = 5, bt601_525 = 6 };
pub const Transfer = enum(u32) { srgb = 1, linear = 2, pq = 3, hlg = 4, icc = 5, bt1886 = 6 };
pub const Range = enum(u32) {
    full = 1,
    limited = 2,
    limited8 = 3,
    limited10 = 4,
    limited16 = 5,
    fn bits(self: Range, precision: Precision) u5 {
        return switch (self) {
            .full, .limited => precision.bits(),
            .limited8 => 8,
            .limited10 => 10,
            .limited16 => 16,
        };
    }
};
pub const Alpha = enum(u32) { ignore = 1, straight = 2, electrical = 3, optical = 4 };
pub const Precision = enum(u32) {
    unorm8 = 8,
    unorm10 = 10,
    float16 = 16,
    unorm16 = 17,
    pub fn bits(self: Precision) u5 {
        return switch (self) {
            .unorm8 => 8,
            .unorm10 => 10,
            .float16, .unorm16 => 16,
        };
    }
};
pub const Rgb = [3]f32;
pub const Value = struct { rgb: Rgb = @splat(0), alpha: f32 = 0 };

pub const Description = struct {
    primaries: Primaries = .srgb,
    transfer: Transfer = .srgb,
    range: Range = .full,
    alpha: Alpha = .ignore,
    precision: Precision = .unorm8,
    // Explicit presentation policy, not an assertion of measured panel light.
    reference_white: f32 = 100,
    peak: f32 = 100,
    black: f32 = 0,

    pub fn validate(self: Description) Error!void {
        if (!finite(self.reference_white) or !finite(self.peak) or !finite(self.black) or
            self.reference_white <= 0 or self.peak < self.reference_white or self.peak > 10000 or
            self.black < 0 or self.black >= self.reference_white) return error.Invalid;
        if (self.primaries == .icc or self.transfer == .icc) {
            // ICC owns the complete RGB characterization, including LUTs.
            // Its PCS is relative SDR; an arbitrary LUT cannot be split into
            // a transfer-only stage to implement optical premultiplication.
            if (self.primaries != .icc or self.transfer != .icc or self.range != .full or
                self.black != 0 or self.peak != self.reference_white or self.alpha == .optical) return error.Unsupported;
            return;
        }
        if (self.precision == .float16 and (self.range != .full or self.transfer != .linear)) return error.Unsupported;
        if ((self.transfer == .pq or self.transfer == .hlg) and self.precision == .unorm8) return error.Unsupported;
        if (self.transfer == .pq and self.black != 0) return error.Unsupported;
        if (self.transfer == .hlg) {
            if (self.primaries != .bt2020 or hlgBeta(self) >= 1) return error.Unsupported;
        } else if (self.transfer == .bt1886) {
            if (self.peak != self.reference_white or bt1886Lift(self) >= 1) return error.Unsupported;
        } else if (self.black != 0) return error.Unsupported;
    }
    pub fn hdr(self: Description) bool {
        return self.transfer == .pq or self.transfer == .hlg;
    }
};

pub fn finite(value: f32) bool {
    return std.math.isFinite(value);
}
fn unit(value: f32) f32 {
    return std.math.clamp(value, 0, 1);
}
fn scale(rgb: Rgb, factor: f32) Rgb {
    return .{ rgb[0] * factor, rgb[1] * factor, rgb[2] * factor };
}
pub fn luminance(rgb: Rgb) f32 {
    return rgb[0] * 0.2627 + rgb[1] * 0.6780 + rgb[2] * 0.0593;
}

pub const Matrix = struct {
    rows: [3][3]f64,
    pub const identity: Matrix = .{ .rows = .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } } };
    pub fn apply(self: Matrix, rgb: Rgb) Rgb {
        var result: Rgb = undefined;
        inline for (0..3) |i| result[i] = @floatCast(self.rows[i][0] * rgb[0] + self.rows[i][1] * rgb[1] + self.rows[i][2] * rgb[2]);
        return result;
    }
    pub fn applyFast(self: Matrix, rgb: Rgb) Rgb {
        var result: Rgb = undefined;
        inline for (0..3) |i| result[i] = @as(f32, @floatCast(self.rows[i][0])) * rgb[0] +
            @as(f32, @floatCast(self.rows[i][1])) * rgb[1] + @as(f32, @floatCast(self.rows[i][2])) * rgb[2];
        return result;
    }
    pub fn multiply(self: Matrix, other: Matrix) Matrix {
        var result: Matrix = undefined;
        inline for (0..3) |i| inline for (0..3) |j| {
            result.rows[i][j] = self.rows[i][0] * other.rows[0][j] + self.rows[i][1] * other.rows[1][j] + self.rows[i][2] * other.rows[2][j];
        };
        return result;
    }
    pub fn inverse(self: Matrix) Error!Matrix {
        const m = self.rows;
        for (m) |row| for (row) |v| if (!std.math.isFinite(v)) return error.Invalid;
        const det = m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
            m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
            m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
        if (!std.math.isFinite(det) or @abs(det) < 1e-10) return error.Singular;
        var result: Matrix = undefined;
        inline for (0..3) |i| inline for (0..3) |j| {
            const a = (j + 1) % 3;
            const b = (j + 2) % 3;
            const c = (i + 1) % 3;
            const d = (i + 2) % 3;
            result.rows[i][j] = (m[a][c] * m[b][d] - m[a][d] * m[b][c]) / det;
        };
        return result;
    }
};

pub const Chromaticities = struct {
    red: [2]f64,
    green: [2]f64,
    blue: [2]f64,
    white: [2]f64 = .{ 0.3127, 0.3290 },
    pub fn xyz(self: Chromaticities) Error!Matrix {
        var columns: Matrix = undefined;
        for ([_][2]f64{ self.red, self.green, self.blue }, 0..) |xy, i| {
            if (!std.math.isFinite(xy[0]) or !std.math.isFinite(xy[1]) or xy[0] < 0 or xy[1] <= 0 or xy[0] + xy[1] > 1.000001) return error.Invalid;
            columns.rows[0][i] = xy[0] / xy[1];
            columns.rows[1][i] = 1;
            columns.rows[2][i] = (1 - xy[0] - xy[1]) / xy[1];
        }
        const w = self.white;
        if (!std.math.isFinite(w[0]) or !std.math.isFinite(w[1]) or w[0] <= 0 or w[1] <= 0 or w[0] + w[1] >= 1) return error.Invalid;
        const inverse = try columns.inverse();
        const white = [_]f64{ w[0] / w[1], 1, (1 - w[0] - w[1]) / w[1] };
        for (0..3) |i| {
            const gain = inverse.rows[i][0] * white[0] + inverse.rows[i][1] * white[1] + inverse.rows[i][2] * white[2];
            if (gain <= 0 or !std.math.isFinite(gain)) return error.Invalid;
            for (0..3) |j| columns.rows[j][i] *= gain;
        }
        return columns;
    }
};
pub fn chromaticities(primaries: Primaries) Chromaticities {
    return switch (primaries) {
        .srgb => .{ .red = .{ 0.64, 0.33 }, .green = .{ 0.30, 0.60 }, .blue = .{ 0.15, 0.06 } },
        .display_p3 => .{ .red = .{ 0.68, 0.32 }, .green = .{ 0.265, 0.69 }, .blue = .{ 0.15, 0.06 } },
        .bt2020 => .{ .red = .{ 0.708, 0.292 }, .green = .{ 0.170, 0.797 }, .blue = .{ 0.131, 0.046 } },
        .bt601_625 => .{ .red = .{ 0.64, 0.33 }, .green = .{ 0.29, 0.60 }, .blue = .{ 0.15, 0.06 } },
        .bt601_525 => .{ .red = .{ 0.630, 0.340 }, .green = .{ 0.310, 0.595 }, .blue = .{ 0.155, 0.070 } },
        .icc => unreachable, // An admitted ICC transform supplies its PCS.
    };
}
pub fn primariesMatrix(source: Primaries, target: Primaries) Matrix {
    if (source == target) return .identity;
    const to_xyz = chromaticities(source).xyz() catch unreachable;
    const from_xyz = (chromaticities(target).xyz() catch unreachable).inverse() catch unreachable;
    return from_xyz.multiply(to_xyz);
}

pub fn srgbDecode(encoded: f32) f32 {
    const x = @abs(encoded);
    const result = if (x <= 0.04045) x / 12.92 else std.math.pow(f32, (x + 0.055) / 1.055, 2.4);
    return std.math.copysign(result, encoded);
}
pub fn srgbEncode(linear: f32) f32 {
    const x = @abs(linear);
    const result = if (x <= 0.0031308) 12.92 * x else 1.055 * std.math.pow(f32, x, 1.0 / 2.4) - 0.055;
    return std.math.copysign(result, linear);
}
// BT.1886 reference display EOTF, not the inverse camera OETF. Its normalized
// form avoids an unbounded black-offset coefficient as black approaches white.
// Original specification: GFX/0.79.40/YuvSources/BT.1886-2011.pdf, Annex 1.
pub fn bt1886Lift(desc: Description) f32 {
    return std.math.pow(f32, desc.black / desc.reference_white, 1.0 / 2.4);
}
fn gamma24Decode(signal: f32) f32 { return std.math.pow(f32, @max(signal, 0), 2.4); }
fn gamma24Encode(light: f32) f32 { return std.math.pow(f32, @max(light, 0), 1.0 / 2.4); }
fn bt1886Decode(desc: Description, lift: f32, signal: f32, lookup: bool) f32 {
    const x = @max((1 - lift) * signal + lift, 0);
    return desc.reference_white * (if (lookup and x <= 1) CurveTable.at(&gamma24_table.decode, x) else gamma24Decode(x));
}
fn bt1886Encode(desc: Description, lift: f32, light: f32, lookup: bool) f32 {
    const x = @max(light / desc.reference_white, 0);
    const root = if (lookup and x <= 1) CurveTable.at(&gamma24_table.encode, @sqrt(x)) else gamma24Encode(x);
    return (root - lift) / (1 - lift);
}
// PQ is absolute. Reference-white policy must never rescale the PQ EOTF.
// f64 intermediates avoid cancellation near the 10000 cd/m2 endpoint.
pub fn pqDecode(encoded: f32) f32 {
    const p = std.math.pow(f64, unit(encoded), 1.0 / 78.84375);
    return @floatCast(10000 * std.math.pow(f64, @max(p - 0.8359375, 0) / (18.8515625 - 18.6875 * p), 1.0 / 0.1593017578125));
}
pub fn pqEncode(nits: f32) f32 {
    const p = std.math.pow(f64, std.math.clamp(@as(f64, nits), 0, 10000) / 10000, 0.1593017578125);
    return @floatCast(std.math.pow(f64, (0.8359375 + 18.8515625 * p) / (1 + 18.6875 * p), 78.84375));
}
pub fn hlgGamma(peak: f32) f32 {
    return if (peak >= 400 and peak <= 2000) 1.2 + 0.42 * @log10(peak / 1000) else 1.2 * std.math.pow(f32, 1.111, @log2(peak / 1000));
}
pub fn hlgBeta(desc: Description) f32 {
    return @sqrt(3 * std.math.pow(f32, desc.black / desc.peak, 1 / hlgGamma(desc.peak)));
}
pub fn hlgSceneDecode(encoded: f32) f32 {
    const x = unit(encoded);
    return if (x <= 0.5) x * x / 3 else (@exp((x - 0.55991073) / 0.17883277) + 0.28466892) / 12;
}
pub fn hlgSceneEncode(scene: f32) f32 {
    const x = unit(scene);
    return if (x <= 1.0 / 12.0) @sqrt(3 * x) else 0.17883277 * @log(12 * x - 0.28466892) + 0.55991073;
}
const CurveTable = struct {
    decode: [4097]f32,
    encode: [4097]f32,
    fn init(comptime decode_fn: fn (f32) f32, comptime encode_fn: fn (f32) f32, maximum: f32, comptime fourth_axis: bool) CurveTable {
        @setEvalBranchQuota(10000000);
        var result: CurveTable = undefined;
        for (0..result.decode.len) |i| {
            const x = @as(f32, @floatFromInt(i)) / 4096;
            result.decode[i] = decode_fn(x);
            // Root axes retain near-black precision. PQ spans10000 cd/m2
            // and needs a fourth-root axis; SDR/HLG need a square-root axis.
            result.encode[i] = encode_fn((if (fourth_axis) x * x * x * x else x * x) * maximum);
        }
        return result;
    }
    fn at(values: *const [4097]f32, x: f32) f32 {
        const position = unit(x) * 4096;
        const index: usize = @intFromFloat(position);
        const weight = position - @as(f32, @floatFromInt(index));
        return values[index] + (values[@min(index + 1, 4096)] - values[index]) * weight;
    }
};
const srgb_table = CurveTable.init(srgbDecode, srgbEncode, 1, false);
const pq_table = CurveTable.init(pqDecode, pqEncode, 10000, true);
const hlg_table = CurveTable.init(hlgSceneDecode, hlgSceneEncode, 1, false);
const gamma24_table = CurveTable.init(gamma24Decode, gamma24Encode, 1, false);
fn hlgDecode(desc: Description, encoded: Rgb, lookup: bool) Rgb {
    const beta = hlgBeta(desc);
    var scene: Rgb = undefined;
    for (&scene, encoded) |*s, e| {
        const lifted = (1 - beta) * unit(e) + beta;
        s.* = if (lookup) CurveTable.at(&hlg_table.decode, lifted) else hlgSceneDecode(lifted);
    }
    const y = luminance(scene);
    if (y <= 0) return @splat(0);
    return scale(scene, desc.peak * std.math.pow(f32, y, hlgGamma(desc.peak) - 1));
}
fn hlgEncode(desc: Description, nits: Rgb, lookup: bool) Rgb {
    const y = @max(luminance(nits) / desc.peak, 0);
    const gamma = hlgGamma(desc.peak);
    const factor = if (y > 0) std.math.pow(f32, y, (1 - gamma) / gamma) / desc.peak else 0;
    const beta = hlgBeta(desc);
    var encoded: Rgb = undefined;
    for (&encoded, nits) |*e, n| {
        const scene = n * factor;
        const signal = if (lookup) CurveTable.at(&hlg_table.encode, @sqrt(unit(scene))) else hlgSceneEncode(scene);
        e.* = unit((signal - beta) / (1 - beta));
    }
    return encoded;
}

// RGB legal range, never applied to alpha. A floating representation has no
// implicit integer/video range. Foot/headroom is retained until final packing.
pub fn unpackRange(desc: Description, encoded: Rgb) Rgb {
    if (desc.range == .full) return encoded;
    const bits = desc.range.bits(desc.precision);
    const shift: u5 = bits - 8;
    const maximum: f32 = @floatFromInt((@as(u32, 1) << bits) - 1);
    const low: f32 = @floatFromInt(@as(u32, 16) << shift);
    const width: f32 = @floatFromInt(@as(u32, 219) << shift);
    var result: Rgb = undefined;
    for (&result, encoded) |*r, e| r.* = (e * maximum - low) / width;
    return result;
}
pub fn packRange(desc: Description, encoded: Rgb) Rgb {
    if (desc.range == .full) return encoded;
    const bits = desc.range.bits(desc.precision);
    const shift: u5 = bits - 8;
    const maximum: f32 = @floatFromInt((@as(u32, 1) << bits) - 1);
    const low: f32 = @floatFromInt(@as(u32, 16) << shift);
    const width: f32 = @floatFromInt(@as(u32, 219) << shift);
    var result: Rgb = undefined;
    for (&result, encoded) |*r, e| r.* = (e * width + low) / maximum;
    return result;
}

pub const Encoding = struct {
    description: Description,
    to_working: Matrix,
    from_working: Matrix,
    lookup: bool = false,
    black_lift: f32 = 0,
    pub fn init(desc: Description) Error!Encoding {
        try desc.validate();
        if (desc.transfer == .icc) return error.Unsupported;
        return .{ .description = desc, .to_working = primariesMatrix(desc.primaries, .bt2020), .from_working = primariesMatrix(.bt2020, desc.primaries),
            .black_lift = if (desc.transfer == .bt1886) bt1886Lift(desc) else 0 };
    }
    pub fn initFast(desc: Description) Error!Encoding {
        var result = try init(desc);
        result.lookup = true;
        return result;
    }
    // Callers validate floating input before any transactional image write.
    pub fn decode(self: *const Encoding, encoded_rgb: Rgb, encoded_alpha: f32) Value {
        const desc = self.description;
        const a = if (desc.alpha == .ignore) 1 else unit(encoded_alpha);
        if (a == 0) return .{};
        var rgb = unpackRange(desc, encoded_rgb);
        if (desc.alpha == .electrical) rgb = scale(rgb, 1 / a);
        if (desc.transfer == .hlg) {
            rgb = hlgDecode(desc, rgb, self.lookup);
        } else for (&rgb) |*channel| channel.* = switch (desc.transfer) {
            .srgb => (if (self.lookup and @abs(channel.*) <= 1) std.math.copysign(CurveTable.at(&srgb_table.decode, @abs(channel.*)), channel.*) else srgbDecode(channel.*)) * desc.reference_white,
            .linear => channel.* * desc.reference_white,
            .bt1886 => bt1886Decode(desc, self.black_lift, channel.*, self.lookup),
            .pq => if (self.lookup) CurveTable.at(&pq_table.decode, channel.*) else pqDecode(channel.*),
            .hlg, .icc => unreachable,
        };
        if (desc.alpha != .optical) rgb = scale(rgb, a);
        return .{ .rgb = if (self.lookup) self.to_working.applyFast(rgb) else self.to_working.apply(rgb), .alpha = a };
    }
    pub fn encode(self: *const Encoding, value: Value) Value {
        const desc = self.description;
        const a = if (desc.alpha == .ignore) 1 else unit(value.alpha);
        var rgb: Rgb = if (a == 0) @splat(0) else if (self.lookup) self.from_working.applyFast(value.rgb) else self.from_working.apply(value.rgb);
        if (a > 0 and desc.alpha != .optical) rgb = scale(rgb, 1 / a);
        if (desc.transfer == .hlg) {
            rgb = hlgEncode(desc, rgb, self.lookup);
        } else for (&rgb) |*channel| channel.* = switch (desc.transfer) {
            .srgb => if (self.lookup and @abs(channel.*) <= desc.reference_white) std.math.copysign(CurveTable.at(&srgb_table.encode, @sqrt(@abs(channel.*) / desc.reference_white)), channel.*) else srgbEncode(channel.* / desc.reference_white),
            .linear => channel.* / desc.reference_white,
            .bt1886 => bt1886Encode(desc, self.black_lift, channel.*, self.lookup),
            .pq => if (self.lookup) CurveTable.at(&pq_table.encode, @sqrt(@sqrt(unit(channel.* / 10000)))) else pqEncode(channel.*),
            .hlg, .icc => unreachable,
        };
        if (desc.alpha == .electrical) rgb = scale(rgb, a);
        if (a == 0) rgb = @splat(0);
        return .{ .rgb = packRange(desc, rgb), .alpha = a };
    }
};

pub fn over(source: Value, target: Value, opacity: f32) Value {
    const a = source.alpha * opacity;
    var rgb: Rgb = undefined;
    for (&rgb, source.rgb, target.rgb) |*r, s, d| r.* = s * opacity + d * (1 - a);
    return .{ .rgb = rgb, .alpha = a + target.alpha * (1 - a) };
}
pub fn interpolate(left: Value, right: Value, weight: f32) Value {
    var rgb: Rgb = undefined;
    for (&rgb, left.rgb, right.rgb) |*r, l, v| r.* = l * (1 - weight) + v * weight;
    return .{ .rgb = rgb, .alpha = left.alpha * (1 - weight) + right.alpha * weight };
}

pub const ToneMap = struct {
    gain: f32,
    source_peak: f32,
    target_peak: f32,
    knee: f32,
    shoulder: f32,
    // A documented R4OS rational shoulder, not a claim of BT.2390 EETF.
    // Preserve reference-white scaling below 75% of the output peak, then
    // join with slope1 and map the declared source peak exactly to output peak.
    pub fn init(source: Description, target: Description, relative_white: bool) Error!ToneMap {
        try source.validate();
        try target.validate();
        const gain = if (relative_white) target.reference_white / source.reference_white else 1;
        const peak = source.peak * gain;
        const knee = target.peak * 0.75;
        return .{ .gain = gain, .source_peak = peak, .target_peak = target.peak, .knee = knee, .shoulder = if (peak > target.peak) (peak - target.peak) / ((target.peak - knee) * (peak - knee)) else 0 };
    }
    pub fn apply(self: ToneMap, input: Value) Value {
        if (input.alpha <= 0) return .{};
        var rgb = scale(input.rgb, self.gain);
        const y = luminance(rgb) / input.alpha;
        if (y > 0) {
            var mapped = @min(y, self.source_peak);
            if (self.shoulder != 0 and mapped > self.knee) {
                const excess = mapped - self.knee;
                mapped = self.knee + excess / (1 + self.shoulder * excess);
            }
            rgb = scale(rgb, @min(mapped, self.target_peak) / y);
        }
        return .{ .rgb = rgb, .alpha = input.alpha };
    }
};

// Compress chroma towards an equal-luminance neutral in output-primary space.
// This keeps the hue direction and luminance, unlike independent RGB clipping.
pub fn gamutMap(rgb: Rgb, y: f32, peak: f32) Rgb {
    const gray = std.math.clamp(y, 0, peak);
    var saturation: f32 = 1;
    for (rgb) |v| {
        const delta = v - gray;
        if (delta > 0) saturation = @min(saturation, (peak - gray) / delta);
        if (delta < 0) saturation = @min(saturation, -gray / delta);
    }
    var result: Rgb = undefined;
    for (&result, rgb) |*r, v| r.* = gray + (v - gray) * saturation;
    return result;
}
