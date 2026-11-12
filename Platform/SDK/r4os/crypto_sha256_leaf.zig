//! SHA256 compression derived from the pinned Zig standard library sha2.zig.
//! Only the kernel-granted SHA-NI leaf is extracted; streaming stays in std.
// The MIT License (Expat)
//
// Copyright (c) Zig contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

const std = @import("std");
const mem = std.mem;
pub const State = struct { s: [8]u32 align(16) };
pub const Batch = struct { state: State, data: [4096]u8 align(16) };
const W = [64]u32{
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
    0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
    0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
    0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
    0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
    0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
};

// Called only after the exact CPU/OS/IF/task admission; never call to warm it.
pub noinline fn callback(context: u64, blocks: u32) callconv(.c) i32 {
    const batch: *Batch = @ptrFromInt(context);
    var i: usize = 0;
    while (i < blocks) : (i += 1) round(&batch.state, batch.data[i * 64 ..][0..64]);
    return 0;
}
fn round(d: *State, b: *const [64]u8) void {
    var s: [64]u32 align(16) = undefined;
    for (@as(*align(1) const [16]u32, @ptrCast(b)), 0..) |*elem, i| {
        s[i] = mem.readInt(u32, mem.asBytes(elem), .big);
    }

    const V4u32 = @Vector(4, u32);
    var x: V4u32 = [_]u32{ d.s[5], d.s[4], d.s[1], d.s[0] };
    var y: V4u32 = [_]u32{ d.s[7], d.s[6], d.s[3], d.s[2] };
    const s_v = @as(*[16]V4u32, @ptrCast(&s));

    comptime var k: u8 = 0;
    inline while (k < 16) : (k += 1) {
        if (k < 12) {
            var tmp = s_v[k];
            s_v[k + 4] = asm (
                \\ sha256msg1 %[w4_7], %[tmp]
                \\ vpalignr $0x4, %[w8_11], %[w12_15], %[result]
                \\ paddd %[tmp], %[result]
                \\ sha256msg2 %[w12_15], %[result]
                : [tmp] "=&x" (tmp),
                  [result] "=&x" (-> V4u32),
                : [_] "0" (tmp),
                  [w4_7] "x" (s_v[k + 1]),
                  [w8_11] "x" (s_v[k + 2]),
                  [w12_15] "x" (s_v[k + 3]),
            );
        }

        const w: V4u32 = s_v[k] +% @as(V4u32, W[4 * k ..][0..4].*);
        y = asm ("sha256rnds2 %[x], %[y]"
            : [y] "=x" (-> V4u32),
            : [_] "0" (y),
              [x] "x" (x),
              [_] "{xmm0}" (w),
        );

        x = asm ("sha256rnds2 %[y], %[x]"
            : [x] "=x" (-> V4u32),
            : [_] "0" (x),
              [y] "x" (y),
              [_] "{xmm0}" (@as(V4u32, @bitCast(@as(u128, @bitCast(w)) >> 64))),
        );
    }

    d.s[0] +%= x[3];
    d.s[1] +%= x[2];
    d.s[4] +%= x[1];
    d.s[5] +%= x[0];
    d.s[2] +%= y[3];
    d.s[3] +%= y[2];
    d.s[6] +%= y[1];
    d.s[7] +%= y[0];
}
