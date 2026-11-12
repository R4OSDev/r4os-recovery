// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Existing component case: staged-writer bounds/errors. Independent demux and
// pixel comparison of real encoded packets lives in the07941 recording proof.
const std = @import("std");
const t = std.testing;
const mux = @import("recording_mux");
const enc = @import("r4nv_encode");
const Sink = struct {
    data: [4096]u8 = undefined,
    count: usize = 0,
    writes: usize = 0,
    fail_after: ?usize = null,
    pub fn write(self: *Sink, bytes: []const u8) bool {
        std.debug.assert(bytes.len <= 65536);
        if (self.fail_after) |limit| if (self.writes >= limit) return false;
        if (bytes.len > self.data.len - self.count) return false;
        @memcpy(self.data[self.count..][0..bytes.len], bytes);
        self.count += bytes.len;
        self.writes += 1;
        return true;
    }
};
pub fn run() !void {
    return runWithAllocator(t.allocator);
}
pub fn runWithAllocator(allocator: std.mem.Allocator) !void {
    try pixels(allocator);
    const parameters = try enc.parameterSets(.{ .width = 64, .height = 64, .qp = 26, .fps_num = 30, .fps_den = 1 });
    var raw: [512]u8 = undefined;
    @memcpy(raw[0..parameters.length], parameters.bytes());
    raw[parameters.length..][0..6].* = .{ 0, 0, 0, 1, 0x65, 0x80 };
    const idr = raw[0 .. parameters.length + 6];
    const p = [_]u8{ 0, 0, 1, 0x41, 0x80 };
    var sink: Sink = .{};
    var writer: mux.Writer = .{ .width = 64, .height = 64 };
    try t.expectError(error.Invalid, writer.packet(&sink, &p, false, 0, 33_000_000));
    try t.expectEqual(@as(usize, 0), sink.count);
    try writer.packet(&sink, idr, true, 1_000_000_000, 33_000_000);
    try writer.packet(&sink, &p, false, 1_033_000_000, 100_000_000);
    const before = sink.count;
    try t.expectError(error.Invalid, writer.packet(&sink, &p, false, 1_033_000_000, 1));
    try t.expectError(error.Invalid, writer.packet(&sink, &p, true, 1_133_000_000, 1));
    try t.expectError(error.Invalid, writer.packet(&sink, &.{ 0, 0, 1 }, false, 1_133_000_000, 1));
    try t.expectError(error.Invalid, writer.packet(&sink, &p, false, 1_133_000_000, 0));
    try t.expectEqual(before, sink.count);
    raw[6] ^= 0x20; // A changed SPS must rotate the file before any write.
    try t.expectError(error.FormatChange, writer.packet(&sink, idr, true, 1_133_000_000, 1));
    raw[6] ^= 0x20;
    try t.expectEqual(before, sink.count);
    try t.expect(!writer.failed and writer.frames == 2);
    try writer.packet(&sink, idr, true, 1_133_000_000, 500_000_000);
    // Partial sink effects cannot be rolled back; the caller must abort its
    // staged file. Retrying that writer is rejected without another write.
    sink = .{ .fail_after = 1 };
    writer = .{ .width = 64, .height = 64 };
    try t.expectError(error.Write, writer.packet(&sink, idr, true, 0, 1));
    const partial = sink.count;
    try t.expect(partial != 0 and writer.failed and writer.frames == 0);
    try t.expectError(error.Closed, writer.packet(&sink, idr, true, 0, 1));
    try t.expectEqual(partial, sink.count);
    std.debug.print("recording Matroska: bounded AnnexB/AVC, ordered time, format rotation and sticky partial-write failure: OK\n", .{});
}

fn pixels(allocator: std.mem.Allocator) !void {
    const convert = @import("recording_pixels");
    const layout = try convert.Layout.init(18, 16);
    var rgb: [20 * 16]u32 = undefined;
    var bytes: [65536]u8 = @splat(0xdd);
    for (&rgb, 0..) |*p, i| p.* = @as(u32, @intCast((i * 173) & 255)) << 16 |
        @as(u32, @intCast((i * 43) & 255)) << 8 | @as(u32, @intCast((i * 97) & 255));
    try convert.rows(&rgb, 20, layout, &bytes, 0, 8);
    try t.expectEqual(@as(u8, 0xdd), bytes[8 * layout.pitch]);
    try convert.rows(&rgb, 20, layout, &bytes, 8, 8);
    // Independent floating point BT.709 equations and centered vertical /
    // left horizontal sampling. Check useful pixels and deterministic padding.
    for (0..16) |y| {
        for (0..18) |x| {
            const p = channels(rgb[y * 20 + x]);
            const luma = 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2];
            const expected: i32 = @intFromFloat(@round(16 + luma * 219 / 255));
            try t.expect(@abs(@as(i32, bytes[y * layout.pitch + x]) - expected) <= 1);
        }
        for (bytes[y * layout.pitch + 18 .. (y + 1) * layout.pitch]) |v| try t.expectEqual(@as(u8, 16), v);
    }
    for (0..8) |y| for (0..9) |x| {
        var color: [3]f64 = @splat(0);
        for (0..2) |dy| for (0..3) |tap| {
            const sx = @min(@as(usize, 17), (x * 2 + tap) -| 1);
            const p = channels(rgb[(2 * y + dy) * 20 + sx]);
            for (0..3) |c| color[c] += p[c] * @as(f64, if (tap == 1) 2 else 1) / 8;
        };
        const luma = 0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2];
        const expected = [_]f64{ 128 + (color[2] - luma) / 1.8556 * 224 / 255, 128 + (color[0] - luma) / 1.5748 * 224 / 255 };
        for (expected, 0..) |v, c| try t.expect(@abs(@as(i32, bytes[layout.uv_offset + y * layout.pitch + x * 2 + c]) - @as(i32, @intFromFloat(@round(v)))) <= 1);
    };
    @memset(&rgb, 0xffffff);
    try convert.rows(&rgb, 20, layout, &bytes, 0, 2);
    try t.expect(bytes[0] == 235 and bytes[layout.uv_offset] == 128 and bytes[layout.uv_offset + 1] == 128);
    @memset(&rgb, 0);
    try convert.rows(&rgb, 20, layout, &bytes, 0, 2);
    try t.expect(bytes[0] == 16 and bytes[layout.uv_offset] == 128);
    try t.expectError(error.Bounds, convert.Layout.init(17, 16));
    try t.expectError(error.Bounds, convert.rows(&rgb, 20, layout, &bytes, 1, 2));
    try t.expectError(error.Bounds, convert.rows(&rgb, 20, layout, bytes[0..100], 0, 2));
    try t.expectError(error.Bounds, convert.rows(rgb[0..18], 20, layout, &bytes, 0, 2));
    const amd = try convert.Layout.initAmd(130, 130);
    try t.expect(amd.pitch == 256 and amd.coded_rows == 144 and amd.uv_offset == 36864 and amd.bytes == 65536);
    const captured = try allocator.alloc(u32, 130 * 130);
    defer allocator.free(captured);
    @memset(captured, 0xffffff);
    @memset(&bytes, 0xdd);
    try convert.rows(captured, 130, amd, &bytes, 0, 128);
    try t.expectEqual(@as(u8, 0xdd), bytes[130 * amd.pitch]);
    try convert.rows(captured, 130, amd, &bytes, 128, 2);
    try t.expect(bytes[0] == 235 and bytes[129 * amd.pitch] == 235 and bytes[amd.uv_offset] == 128);
    for (bytes[130 * amd.pitch .. amd.uv_offset]) |value| try t.expectEqual(@as(u8, 16), value);
    for (bytes[amd.uv_offset .. amd.uv_offset + 72 * amd.pitch]) |value| try t.expectEqual(@as(u8, 128), value);
    try t.expectEqual(@as(u8, 0xdd), bytes[amd.uv_offset + 72 * amd.pitch]);
    var corrupted = amd;
    corrupted.coded_rows = 130;
    try t.expectError(error.Bounds, convert.rows(captured, 130, corrupted, &bytes, 0, 130));
    std.debug.print("recording pixels: sRGB/709 limited NV12, left chroma, partial rows and bounds: OK\n", .{});
}
fn channels(p: u32) [3]f64 {
    return .{ @floatFromInt((p >> 16) & 255), @floatFromInt((p >> 8) & 255), @floatFromInt(p & 255) };
}
