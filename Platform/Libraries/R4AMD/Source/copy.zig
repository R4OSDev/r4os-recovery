// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 AND MIT
// Copyright 2012 Advanced Micro Devices, Inc.
// Copyright 2025 Valve Corporation
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
//! SDMA4.1 subset of pinned Mesa ac_cmdbuf_sdma.c and AMD Linux packet formats.
//! Caller-owned, allocation-free packets. Mapping, fences and device ownership
//! stay in AMDGPU. A successful encode alone proves no GPU completion.
const std = @import("std");
pub const Error = error{ Invalid, Unsupported, Capacity, Overflow, Overlap };
pub const address_limit: u64 = @as(u64, 1) << 48;
pub const max_words = 2048;
pub const max_packet_bytes = 4 * 1024 * 1024;
pub const max_transfer_bytes = 64 * 1024 * 1024;
pub const Copy = struct {
    source: u64, target: u64, bytes: u64,
    source_pitch: u64 = 0, target_pitch: u64 = 0, rows: u32 = 1,
    source_modifier: u64 = 0, target_modifier: u64 = 0,
};
pub const Fill = struct { target: u64, bytes: u64, value: u32 };
fn add(x: u64, y: u64) Error!u64 { return std.math.add(u64, x, y) catch error.Overflow; }
fn mul(x: u64, y: u64) Error!u64 { return std.math.mul(u64, x, y) catch error.Overflow; }
pub fn extent(bytes: u64, pitch: u64, rows: u32) Error!u64 {
    if (bytes == 0 or rows == 0 or (rows != 1 and pitch < bytes)) return error.Invalid;
    return add(try mul(rows - 1, pitch), bytes);
}
fn range(address: u64, bytes: u64) Error!void {
    if (address == 0 or bytes == 0 or address >= address_limit or bytes > address_limit - address) return error.Invalid;
}
const Plan = struct { words: usize, contiguous: bool = false, bpp: u32 = 0 };
fn linearWords(bytes: u64, source: u64, target: u64) u64 {
    const tail = bytes % max_packet_bytes;
    return ((bytes + max_packet_bytes - 1) / max_packet_bytes +
        @intFromBool(tail > 4 and tail & 3 != 0 and (source | target) & 3 == 0)) * 7;
}
fn plan(request: Copy) Error!Plan {
    if (request.source_modifier != 0 or request.target_modifier != 0) return error.Unsupported;
    const source_bytes = try extent(request.bytes, request.source_pitch, request.rows);
    const target_bytes = try extent(request.bytes, request.target_pitch, request.rows);
    try range(request.source, source_bytes); try range(request.target, target_bytes);
    if (request.source < request.target + target_bytes and request.target < request.source + source_bytes) return error.Overlap;
    const total = try mul(request.bytes, request.rows);
    if (total > max_transfer_bytes) return error.Capacity;
    if (request.rows == 1 or (request.source_pitch == request.bytes and request.target_pitch == request.bytes))
        return .{ .words = @intCast(linearWords(total, request.source, request.target)), .contiguous = true };
    // Conservative Mesa SDMA4 limits. Use 32-bit elements when possible and
    // byte elements otherwise. Two-dimensional slices have depth exactly one.
    const bpp: u32 = if ((request.source | request.target | request.bytes | request.source_pitch | request.target_pitch) & 3 == 0) 4 else 1;
    if (request.rows <= 16384 and request.bytes / bpp <= 16384 and request.source_pitch / bpp <= 16384 and
        request.target_pitch / bpp <= 16384 and (request.source_pitch | request.target_pitch) & 3 == 0)
        return .{ .words = 13, .bpp = bpp };
    // Odd pitches remain expressible as bounded linear row packets. Capacity
    // is rejected before any output is changed, including very tall images.
    var words: u64 = 0;
    for (0..request.rows) |row| {
        const src = request.source + row * request.source_pitch; const dst = request.target + row * request.target_pitch;
        words += linearWords(request.bytes, src, dst);
        if (words > max_words) return error.Capacity;
    }
    return .{ .words = @intCast(words) };
}
fn linear(out: []u32, source: u64, target: u64, bytes: u64) usize {
    var done: u64 = 0; var index: usize = 0;
    while (done < bytes) {
        var count: u64 = @min(bytes - done, max_packet_bytes);
        if (((source + done) | (target + done)) & 3 == 0 and count > 4) count &= ~@as(u64, 3);
        out[index..][0..7].* = .{ 1, @intCast(count - 1), 0, @truncate(source + done), @truncate((source + done) >> 32), @truncate(target + done), @truncate((target + done) >> 32) };
        index += 7; done += count;
    }
    return index;
}
pub fn encodeCopy(out: []u32, request: Copy) Error!usize {
    const p = try plan(request);
    if (p.words > max_words or out.len < p.words) return error.Capacity;
    if (p.contiguous) return linear(out, request.source, request.target, request.bytes * request.rows);
    if (p.bpp != 0) {
        const shift: u32 = if (p.bpp == 4) 2 else 0;
        out[0..13].* = .{ 1 | (4 << 8) | (shift << 29), @truncate(request.source), @truncate(request.source >> 32), 0,
            @as(u32, @intCast(request.source_pitch / p.bpp - 1)) << 13, 0,
            @truncate(request.target), @truncate(request.target >> 32), 0,
            @as(u32, @intCast(request.target_pitch / p.bpp - 1)) << 13, 0,
            @as(u32, @intCast(request.bytes / p.bpp - 1)) | ((request.rows - 1) << 16), 0 };
        return 13;
    }
    var count: usize = 0;
    for (0..request.rows) |row| count += linear(out[count..], request.source + row * request.source_pitch, request.target + row * request.target_pitch, request.bytes);
    return count;
}
pub fn encodeFill(out: []u32, request: Fill) Error!usize {
    try range(request.target, request.bytes);
    if ((request.target | request.bytes) & 3 != 0) return error.Invalid;
    if (request.bytes > max_transfer_bytes) return error.Capacity;
    // Mesa uses max count 4MB-4 for a 32-bit constant fill on SDMA4.
    const chunk = max_packet_bytes - 4;
    const words = ((request.bytes + chunk - 1) / chunk) * 5;
    if (words > max_words or out.len < words) return error.Capacity;
    var done: u64 = 0; var index: usize = 0;
    while (done < request.bytes) {
        const count = @min(request.bytes - done, chunk);
        out[index..][0..5].* = .{ 11 | (2 << 30), @truncate(request.target + done), @truncate((request.target + done) >> 32), request.value, @intCast(count - 1) };
        done += count; index += 5;
    }
    return index;
}
