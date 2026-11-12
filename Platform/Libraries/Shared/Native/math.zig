// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Integer rounding used by Mesa's descriptor bit packing. Decode IEEE values
// directly: ties go away from zero, independently of MXCSR rounding mode, and
// valid inputs never raise FE_INEXACT. x86 conversion raises FE_INVALID for
// non-finite/out-of-range arguments and supplies the integer-indefinite result.
const builtin = @import("builtin");
const std = @import("std");
comptime {
    if (builtin.cpu.arch != .x86_64 or @sizeOf(c_long) != 8) @compileError("Native Mesa math requires the x86_64 C ABI");
}
fn rounded(comptime F: type, value: F) i64 {
    const U = if (F == f32) u32 else u64;
    const fraction_bits = if (F == f32) 23 else 52;
    const bias = if (F == f32) 127 else 1023;
    const bits: U = @bitCast(value);
    const negative = bits >> (@bitSizeOf(F) - 1) != 0;
    const exponent_mask: U = if (F == f32) 0xff else 0x7ff;
    const encoded = (bits >> fraction_bits) & exponent_mask;
    const exponent: i32 = @as(i32, @intCast(encoded)) - bias;
    const fraction = bits & ((@as(U, 1) << fraction_bits) - 1);
    if (exponent >= 63) {
        if (negative and exponent == 63 and fraction == 0) return -9223372036854775808;
        return if (F == f32)
            asm volatile ("cvttss2si %[value], %[result]"
                : [result] "=r" (-> i64),
                : [value] "x" (value),
            )
        else
            asm volatile ("cvttsd2si %[value], %[result]"
                : [result] "=r" (-> i64),
                : [value] "x" (value),
            );
    }
    if (exponent < -1) return 0;
    const mantissa: u64 = @as(u64, 1) << fraction_bits | fraction;
    const magnitude: u64 = if (exponent == -1) 1 else if (exponent >= fraction_bits)
        mantissa << @as(u6, @intCast(exponent - fraction_bits))
    else result: {
        const shift: u6 = @intCast(fraction_bits - exponent);
        break :result (mantissa >> shift) + ((mantissa >> (shift - 1)) & 1);
    };
    return @bitCast(if (negative) @as(u64, 0) -% magnitude else magnitude);
}
pub export fn llroundf(value: f32) callconv(.c) c_longlong {
    return rounded(f32, value);
}
pub export fn llround(value: f64) callconv(.c) c_longlong {
    return rounded(f64, value);
}
pub export fn lroundf(value: f32) callconv(.c) c_long {
    return rounded(f32, value);
}
pub export fn lround(value: f64) callconv(.c) c_long {
    return rounded(f64, value);
}

// C lrint follows the caller's MXCSR rounding mode, unlike lround. The x86
// instruction also supplies C's inexact/invalid exception semantics.
pub export fn lrintf(value: f32) callconv(.c) c_long {
    return asm volatile ("cvtss2si %[value], %[result]"
        : [result] "=r" (-> c_long),
        : [value] "x" (value),
    );
}
pub export fn lrint(value: f64) callconv(.c) c_long {
    return asm volatile ("cvtsd2si %[value], %[result]"
        : [result] "=r" (-> c_long),
        : [value] "x" (value),
    );
}
pub export fn llrintf(value: f32) callconv(.c) c_longlong {
    return lrintf(value);
}
pub export fn llrint(value: f64) callconv(.c) c_longlong {
    return lrint(value);
}

// Integral finite values need no conversion. Smaller values fit exactly in
// i64, and CVT follows MXCSR while retaining the C inexact exception. Restore
// the sign of zero after integer conversion. An arithmetic NaN quiets sNaN.
fn integral(comptime T: type, value: T) T {
    if (std.math.isNan(value)) return value + value;
    const cutoff: T = if (T == f32) 0x1p23 else 0x1p52;
    if (@abs(value) >= cutoff) return value;
    const integer = if (T == f32) lrintf(value) else lrint(value);
    const result: T = @floatFromInt(integer);
    return std.math.copysign(result, value);
}
pub export fn rintf(value: f32) callconv(.c) f32 {
    return integral(f32, value);
}
pub export fn rint(value: f64) callconv(.c) f64 {
    return integral(f64, value);
}

// The pinned Zig stdlib carries the original musl-derived algorithms. These
// C entrypoints are not provided by compiler-rt itself; elementary sin/cos,
// logs, exp, fma, sqrt, floor/ceil/trunc/round remain compiler-rt-owned.
pub export fn acosf(value: f32) callconv(.c) f32 {
    return std.math.acos(value);
}
pub export fn asinf(value: f32) callconv(.c) f32 {
    return std.math.asin(value);
}
pub export fn atanf(value: f32) callconv(.c) f32 {
    return std.math.atan(value);
}
pub export fn atan2f(y: f32, x: f32) callconv(.c) f32 {
    return std.math.atan2(y, x);
}
pub export fn acos(value: f64) callconv(.c) f64 {
    return std.math.acos(value);
}
pub export fn asin(value: f64) callconv(.c) f64 {
    return std.math.asin(value);
}
pub export fn atan(value: f64) callconv(.c) f64 {
    return std.math.atan(value);
}
pub export fn atan2(y: f64, x: f64) callconv(.c) f64 {
    return std.math.atan2(y, x);
}
pub export fn sinh(value: f64) callconv(.c) f64 {
    return std.math.sinh(value);
}
pub export fn cosh(value: f64) callconv(.c) f64 {
    return std.math.cosh(value);
}
pub export fn tanh(value: f64) callconv(.c) f64 {
    return std.math.tanh(value);
}
pub export fn copysignf(value: f32, sign: f32) callconv(.c) f32 {
    return std.math.copysign(value, sign);
}
pub export fn copysign(value: f64, sign: f64) callconv(.c) f64 {
    return std.math.copysign(value, sign);
}
fn decompose(comptime T: type, value: T, exponent: *c_int) T {
    // C leaves a NaN/Inf exponent unspecified. Use a defined zero instead of
    // reading std.math.frexp's deliberately undefined NaN exponent.
    if (!std.math.isFinite(value)) {
        exponent.* = 0;
        return value;
    }
    const result = std.math.frexp(value);
    exponent.* = result.exponent;
    return result.significand;
}
pub export fn frexpf(value: f32, exponent: *c_int) callconv(.c) f32 {
    return decompose(f32, value, exponent);
}
pub export fn frexp(value: f64, exponent: *c_int) callconv(.c) f64 {
    return decompose(f64, value, exponent);
}
