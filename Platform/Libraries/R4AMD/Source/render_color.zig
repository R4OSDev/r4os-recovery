// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Shared R4OS color/grid semantics, independently bound to the AMD shader ABI.
//! Fixed userland color-program upload, matching the common 256-byte color ABI.
//! R4GFX supplies coefficients; this boundary validates storage/domains and
//! never infers color or HDR capability from a buffer's pixel format.
const std = @import("std");
pub const Program = extern struct {
    words: [64]u32 = @splat(0),
    pub fn scalar(self: Program, byte: usize) f32 {
        return @bitCast(self.words[byte / 4]);
    }
    pub fn validate(self: Program) error{ Bounds, Unsupported }!void {
        if (self.words[0] & ~@as(u32, 3) != 0 or !supportedTransfer(self.words[1]) or
            !supportedTransfer(self.words[2]) or self.words[3] < 1 or self.words[3] > 4 or self.words[4] < 1 or self.words[4] > 4) return error.Unsupported;
        for (self.words[5..8]) |value| if (value != 0) return error.Bounds;
        for (self.words[50..]) |value| if (value != 0) return error.Bounds;
        for (self.words[8..50]) |word| if (!std.math.isFinite(@as(f32, @bitCast(word)))) return error.Bounds;
        for ([_]usize{ 44, 60, 76, 92, 108, 124 }) |byte| if (self.words[byte / 4] != 0) return error.Bounds;
        for ([_]usize{ 128, 144 }) |byte| {
            const white = self.scalar(byte);
            const peak = self.scalar(byte + 4);
            const gamma = self.scalar(byte + 8);
            const beta = self.scalar(byte + 12);
            if (white <= 0 or white > peak or peak > 10000 or gamma <= 0 or gamma > 4 or beta < 0 or beta >= 1) return error.Bounds;
        }
        if (self.scalar(160) <= 0 or self.scalar(168) <= 0 or self.scalar(176) <= 0 or
            self.scalar(180) <= 0 or self.scalar(184) < 0 or self.scalar(188) < 0 or
            self.scalar(192) <= 0 or self.scalar(192) > 10000 or self.scalar(184) >= self.scalar(192) or
            self.scalar(196) < 0 or self.scalar(196) > 1.0 / 255.0) return error.Bounds;
        if ((self.words[0] & 2 != 0) != (self.scalar(196) != 0) or (self.words[0] & 2 != 0 and self.words[0] & 1 == 0)) return error.Unsupported;
    }
};
fn supportedTransfer(value: u32) bool {
    return (value >= 1 and value <= 4) or value == 6;
}
comptime {
    if (@sizeOf(Program) != 256) @compileError("color constant buffer ABI");
}
