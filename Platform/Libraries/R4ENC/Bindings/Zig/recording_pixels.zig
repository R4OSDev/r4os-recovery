// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Captured sRGB XRGB32 -> NV12 with709 primaries/matrix, limited range,
//! CICP13 transfer and default left-sited chroma. There is no transfer-function
//! approximation: the encoded nonlinear RGB codes retain their sRGB meaning.
//! This CPU fallback consumes the existing immutable CPU capture snapshot;
//! native YUV callers can submit their retained GPU BOs directly to ENCODE_V1.
const std = @import("std");
pub const Error = error{Bounds};
pub const Profile = enum { generic, amd_vcn1 };
pub const Layout = struct {
    width: u32,
    height: u32,
    pitch: u32,
    uv_offset: usize,
    bytes: usize,
    profile: Profile,
    coded_rows: u32,
    pub fn init(width: u32, height: u32) Error!Layout {
        return initProfile(width, height, .generic);
    }
    /// VCN1 reads complete16-row AVC macroblocks. The CPU snapshot retains
    /// visible dimensions; padding belongs to this reusable encoder input.
    pub fn initAmd(width: u32, height: u32) Error!Layout {
        return initProfile(width, height, .amd_vcn1);
    }
    fn initProfile(width: u32, height: u32, profile: Profile) Error!Layout {
        if (width < 16 or height < 16 or width > 4096 or height > 4096 or (width | height) & 1 != 0) return error.Bounds;
        const pitch = std.mem.alignForward(u32, width, if (profile == .amd_vcn1) 256 else 128);
        const coded_rows = if (profile == .amd_vcn1) std.mem.alignForward(u32, height, 16) else height;
        const luma_bytes = @as(usize, pitch) * coded_rows;
        return .{ .width = width, .height = height, .pitch = pitch, .uv_offset = luma_bytes, .bytes = std.mem.alignForward(usize, luma_bytes + @as(usize, pitch) * (coded_rows / 2), 65536), .profile = profile, .coded_rows = coded_rows };
    }
};
fn rgb(pixel: u32) [3]i64 {
    return .{ @intCast((pixel >> 16) & 255), @intCast((pixel >> 8) & 255), @intCast(pixel & 255) };
}
const scale: i64 = 65536 * 255;
fn luma(pixel: u32) u8 {
    const v = rgb(pixel);
    const y = 13933 * v[0] + 46871 * v[1] + 4732 * v[2];
    return @intCast(16 + @divTrunc(y * 219 + scale / 2, scale));
}
fn chroma(value: i64) u8 {
    // Six source pixels weighted1:2:1 horizontally and1:1 vertically. Sum8.
    return @intCast(std.math.clamp(128 + @divFloor(value * 224 + (scale * 8) / 2, scale * 8), 16, 240));
}
/// Caller owns disjoint snapshot/output spans and may release the snapshot
/// immediately after this call. Bounded row ranges allow stop/yield checks in
/// the recording worker; a chroma pair always includes both complete rows.
pub fn rows(source: []const u32, stride: u32, layout: Layout, output: []u8, first: u32, count: u32) Error!void {
    const checked = try Layout.initProfile(layout.width, layout.height, layout.profile);
    if (!std.meta.eql(checked, layout) or stride < layout.width or
        source.len < @as(u64, stride) * layout.height or output.len < layout.bytes or
        first > layout.height or count > layout.height - first or (first | count) & 1 != 0) return error.Bounds;
    const src_begin = @intFromPtr(source.ptr);
    const dst_begin = @intFromPtr(output.ptr);
    if (src_begin < dst_begin +| output.len and dst_begin < src_begin +| (source.len * @sizeOf(u32))) return error.Bounds;
    var y = first;
    while (y < first + count) : (y += 2) {
        const row0 = source[@as(usize, y) * stride ..][0..layout.width];
        const row1 = source[@as(usize, y + 1) * stride ..][0..layout.width];
        const out0 = output[@as(usize, y) * layout.pitch ..][0..layout.pitch];
        const out1 = output[@as(usize, y + 1) * layout.pitch ..][0..layout.pitch];
        for (row0, row1, 0..) |a, b, x| {
            out0[x] = luma(a);
            out1[x] = luma(b);
        }
        @memset(out0[layout.width..], 16);
        @memset(out1[layout.width..], 16);
        const uv = output[layout.uv_offset + @as(usize, y / 2) * layout.pitch ..][0..layout.pitch];
        var x: u32 = 0;
        while (x < layout.width) : (x += 2) {
            const left = x -| 1;
            const right = @min(x + 1, layout.width - 1);
            var sum: [3]i64 = @splat(0);
            for ([_][]const u32{ row0, row1 }) |row| {
                const l = rgb(row[left]);
                const center = rgb(row[x]);
                const rr = rgb(row[right]);
                for (0..3) |channel| sum[channel] += l[channel] + 2 * center[channel] + rr[channel];
            }
            uv[x] = chroma(-7509 * sum[0] - 25259 * sum[1] + 32768 * sum[2]);
            uv[x + 1] = chroma(32768 * sum[0] - 29763 * sum[1] - 3005 * sum[2]);
        }
        @memset(uv[layout.width..], 128);
    }
    if (first + count == layout.height and layout.coded_rows > layout.height) {
        @memset(output[@as(usize, layout.height) * layout.pitch .. layout.uv_offset], 16);
        @memset(output[layout.uv_offset + @as(usize, layout.height / 2) * layout.pitch .. layout.uv_offset + @as(usize, layout.coded_rows / 2) * layout.pitch], 128);
    }
}
