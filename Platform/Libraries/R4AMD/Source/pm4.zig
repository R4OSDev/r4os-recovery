// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 AND MIT
// Copyright 2012, 2016 Advanced Micro Devices, Inc.
// Copyright 2024 Valve Corporation
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
//
//! GC9.1 PM4 packet encoding. Kernel gfx_v9_0.c/soc15d.h and Mesa
//! ac_cmdbuf_cp.c define the packet sizes, cache actions and GFX9 EOP workaround.
//! No memory is allocated, mapped, retained or submitted by this library.
const std = @import("std");
pub const Error = error{ Invalid, Capacity, Overflow, Unsupported };
pub const Engine = enum(u1) { gfx, compute };
pub const limit: u64 = @as(u64, 1) << 48;
pub const max_ib_words = 2048;
pub const nop: u32 = 0xffff1000; // AMD one-DW type-3 NOP (count=0x3fff).
pub fn packet(op: u8, count: u14) u32 { return 0xc0000000 | (@as(u32, count) << 16) | (@as(u32, op) << 8); }
pub fn range(address: u64, bytes: u64, alignment: u64) Error!void {
    if (alignment == 0 or !std.math.isPowerOfTwo(alignment) or address == 0 or address & (alignment - 1) != 0 or
        bytes == 0 or address >= limit or bytes > limit - address) return error.Invalid;
}
pub fn disjoint(a: u64, a_bytes: u64, b: u64, b_bytes: u64) bool { return a + a_bytes <= b or b + b_bytes <= a; }
pub const Frame = struct {
    engine: Engine, ib: u64, words: u32, fence: u64, sequence: u64,
    // GFX9 writes DB occlusion counters before each timestamp fence. Reserve
    // 256 bytes independently of the fence and IB; MEC must pass zero here.
    eop_scratch: u64 = 0, interrupt: bool = false,
};
pub fn encodeFrame(output: []u32, request: Frame) Error!usize {
    if (request.words == 0 or request.words > max_ib_words or request.sequence == 0 or request.sequence == std.math.maxInt(u64)) return error.Invalid;
    try range(request.ib, @as(u64, request.words) * 4, 32); try range(request.fence, 8, 8);
    if (!disjoint(request.ib, @as(u64, request.words) * 4, request.fence, 8)) return error.Invalid;
    if (request.engine == .gfx) {
        try range(request.eop_scratch, 256, 256);
        if (!disjoint(request.eop_scratch, 256, request.fence, 8) or !disjoint(request.eop_scratch, 256, request.ib, @as(u64, request.words) * 4)) return error.Invalid;
    } else if (request.eop_scratch != 0) return error.Invalid;
    const count: usize = if (request.engine == .gfx) 48 else 32;
    if (output.len < count) return error.Capacity;
    // This is an outer VMID0 ring frame. Its IB and resource addresses use
    // VMID1. Register addresses in WAIT_REG_MEM are dwords, SDMA uses bytes.
    const mask: u32 = if (request.engine == .gfx) 1 else 4; // NBIO CP0 / CP2
    var b: Builder = .{ .words = output[0..count] };
    b.add(&.{ packet(0x3c, 5), 3 | (1 << 6) | (if (request.engine == .gfx) @as(u32, 1 << 8) else 0), 0x3898 / 4, 0x389c / 4, mask, mask, 0x20 });
    b.barrier(request.engine);
    if (request.engine == .gfx) {
        // Full state re-emission in each context IB follows this boundary.
        b.add(&.{ packet(0x28, 1), 0x80000000, 0x80000000, packet(0x12, 0), 0,
            packet(0x42, 0), 0 }); // PFP_SYNC_ME after VM/HDP barriers
    }
    b.add(&.{ packet(0x3f, 2), @truncate(request.ib), @truncate(request.ib >> 32),
        request.words | (1 << 24) | (if (request.engine == .compute) @as(u32, 1 << 23) else 0) });
    b.release(request.engine, request.fence, request.sequence, request.eop_scratch, request.interrupt);
    @memset(output[b.used..count], nop);
    return count;
}
pub const Builder = struct {
    words: []u32, used: usize = 0,
    // Private callers preflight their total size before appending packets.
    pub fn add(self: *Builder, words: []const u32) void {
        std.debug.assert(words.len <= self.words.len - self.used);
        @memcpy(self.words[self.used..][0..words.len], words); self.used += words.len;
    }
    pub fn barrier(self: *Builder, engine: Engine) void {
        const shader: u32 = if (engine == .compute) 2 else 0;
        if (engine == .gfx) self.add(&.{ packet(0x46, 0), 0x0f | (4 << 8), packet(0x46, 0), 0x10 | (4 << 8) });
        self.add(&.{ packet(0x46, 0) | shader, 0x07 | (4 << 8) }); // CS_PARTIAL_FLUSH
        self.add(&.{ packet(0x58, 5) | shader, (1 << 18) | (1 << 22) | (1 << 23) | (1 << 27) | (1 << 29),
            0xffffffff, 0xff, 0, 0, 10 }); // 40-bit count of 256B blocks; upper bits reserved
    }
    pub fn release(self: *Builder, engine: Engine, fence: u64, sequence: u64, scratch: u64, interrupt: bool) void {
        if (engine == .gfx) self.add(&.{ packet(0x46, 2), 0x15 | (1 << 8), @truncate(scratch), @truncate(scratch >> 32) }); // ZPASS_DONE workaround
        self.add(&.{ packet(0x49, 6), 0x14 | (5 << 8) | (1 << 15) | (1 << 16) | (1 << 17) | (1 << 21),
            (2 << 29) | (if (interrupt) @as(u32, 2 << 24) else 0), @truncate(fence), @truncate(fence >> 32),
            @truncate(sequence), @truncate(sequence >> 32), 0 });
    }
};
/// Immutable context sizing used by compiler/provider and driver owners. LDS
/// is per workgroup; GDS is a separately reserved part of Picasso's 4KB store.
/// GFX9 scratch addresses are shader descriptors/user SGPRs (compiler stage),
/// not the GFX11 COMPUTE_DISPATCH_SCRATCH_BASE programming model.
pub const Resources = struct {
    scratch: u64 = 0, scratch_bytes: u64 = 0, waves: u32 = 0, bytes_per_wave: u32 = 0,
    lds_bytes: u32 = 0, gds_offset: u32 = 0, gds_bytes: u32 = 0,
    pub fn validate(self: Resources) Error!void {
        if (self.lds_bytes > 64 * 1024 or self.lds_bytes & 511 != 0 or
            self.gds_offset & 255 != 0 or self.gds_bytes & 255 != 0 or self.gds_offset > 4096 or self.gds_bytes > 4096 - self.gds_offset) return error.Invalid;
        if (self.scratch_bytes == 0) {
            if (self.scratch != 0 or self.waves != 0 or self.bytes_per_wave != 0) return error.Invalid;
        } else {
            try range(self.scratch, self.scratch_bytes, 4096);
            if (self.scratch_bytes & 4095 != 0 or self.waves == 0 or self.waves > 0xfff or self.bytes_per_wave == 0 or self.bytes_per_wave & 1023 != 0 or
                self.bytes_per_wave / 1024 > 0x1fff or @as(u64, self.waves) * self.bytes_per_wave > self.scratch_bytes) return error.Invalid;
        }
    }
    pub fn ringSize(self: Resources) Error!u32 { try self.validate(); return self.waves | ((self.bytes_per_wave / 1024) << 12); }
};
/// A PM4 packet boundary parser for bounded internally produced IBs. This
/// verifies lengths only; application shader/descriptor validation belongs to
/// the provider, and this function never claims an arbitrary IB is safe to run.
pub fn packetBoundaries(words: []const u32) Error!void {
    if (words.len == 0 or words.len > max_ib_words) return error.Invalid;
    var offset: usize = 0;
    while (offset < words.len) {
        const header = words[offset];
        if (header == nop) { offset += 1; continue; }
        if (header >> 30 != 3) return error.Invalid;
        const count: usize = ((header >> 16) & 0x3fff) + 2;
        if (count > words.len - offset) return error.Invalid;
        offset += count;
    }
}
