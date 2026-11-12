//! Minimal private C support for the ICC core, identical in host and R4OS.
const std = @import("std");
export fn r4gfx_c_memcpy(out: [*]u8, input: [*]const u8, n: usize) callconv(.c) ?*anyopaque {
    @memcpy(out[0..n], input[0..n]);
    return out;
}
export fn r4gfx_c_memmove(out: [*]u8, input: [*]const u8, n: usize) callconv(.c) ?*anyopaque {
    if (@intFromPtr(out) < @intFromPtr(input)) std.mem.copyForwards(u8, out[0..n], input[0..n]) else std.mem.copyBackwards(u8, out[0..n], input[0..n]);
    return out;
}
export fn r4gfx_c_memset(out: [*]u8, value: c_int, n: usize) callconv(.c) ?*anyopaque {
    @memset(out[0..n], @truncate(@as(c_uint, @bitCast(value))));
    return out;
}
export fn r4gfx_c_memcmp(left: [*]const u8, right: [*]const u8, n: usize) callconv(.c) c_int {
    return switch (std.mem.order(u8, left[0..n], right[0..n])) { .lt => -1, .eq => 0, .gt => 1 };
}
export fn r4gfx_c_strlen(text: [*:0]const u8) callconv(.c) usize { return std.mem.len(text); }
export fn r4gfx_c_strcpy(out: [*]u8, text: [*:0]const u8) callconv(.c) [*]u8 {
    const n = std.mem.len(text);
    @memcpy(out[0 .. n + 1], text[0 .. n + 1]);
    return out;
}
export fn r4gfx_c_strncpy(out: [*]u8, text: [*]const u8, n: usize) callconv(.c) [*]u8 {
    var i: usize = 0;
    while (i < n and text[i] != 0) : (i += 1) out[i] = text[i];
    @memset(out[i..n], 0);
    return out;
}
export fn r4gfx_c_pow(x: f64, y: f64) callconv(.c) f64 { return std.math.pow(f64, x, y); }
export fn r4gfx_c_log(x: f64) callconv(.c) f64 { return @log(x); }
export fn r4gfx_c_log10(x: f64) callconv(.c) f64 { return @log10(x); }
export fn r4gfx_c_exp(x: f64) callconv(.c) f64 { return @exp(x); }
export fn r4gfx_c_atan(x: f64) callconv(.c) f64 { return std.math.atan(x); }
export fn r4gfx_c_atan2(y: f64, x: f64) callconv(.c) f64 { return std.math.atan2(y, x); }
export fn r4gfx_c_sin(x: f64) callconv(.c) f64 { return @sin(x); }
export fn r4gfx_c_cos(x: f64) callconv(.c) f64 { return @cos(x); }
