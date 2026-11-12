const std = @import("std");
const t = std.testing;
const render = @import("render_image.zig");
const reference = @embedFile("Fixtures/render-image.bin");
fn word(data: []const u8, at: usize) u32 { return std.mem.readInt(u32, data[at..][0..4], .little); }
fn wide(data: []const u8, at: usize) u64 { return std.mem.readInt(u64, data[at..][0..8], .little); }
pub fn check() !void {
    // Header anchors from NVIDIA clb097tex.h COMPONENTS_SIZES, DATA_TYPE,
    // X/Y/Z/W_SOURCE fields. Integer ONE differs from normalized ONE.
    const formats = [_]render.Format{ .r8, .rg8, .r16, .rg16 };
    const normalized = [_]u32{ 0x7010011d, 0x70d00918, 0x7010011b, 0x70d0090c };
    const integer = [_]u32{ 0x6010021d, 0x60d01218, 0x6010021b, 0x60d0120c };
    for (formats, normalized, integer) |format, norm, raw| {
        var plane: render.Image = .{ .address = 0x200000, .bytes = 4096, .width = 3, .height = 3,
            .pitch = 128, .format = format, .layout = .linear };
        try t.expectEqual(norm, (try render.texture(plane))[0]);
        try t.expectEqual(raw, (try render.textureTyped(plane, .unsigned_integer))[0]);
        plane.layout = .blocklinear; plane.pitch = 64; plane.log2_gobs = 1;
        const tiled = try render.textureTyped(plane, .unsigned_integer);
        try t.expectEqual(raw, tiled[0]);
        try t.expectEqual(@as(u32, 3), (tiled[2] >> 21) & 7);
        if (format != .r8) try t.expectError(error.Unsupported, render.target(plane));
        plane.pitch = 128;
        try t.expectError(error.Unsupported, render.textureTyped(plane, .unsigned_integer));
    }
    try @import("render_test.zig").check();
    for (0..6) |index| {
        const record = reference[index * 108..][0..108];
        var image: render.Image = .{ .address = wide(record, 0), .bytes = wide(record, 8), .width = word(record, 16), .height = word(record, 20),
            .pitch = word(record, 24), .format = @enumFromInt(word(record, 28)), .layout = if (word(record, 32) == 0) .linear else .blocklinear, .log2_gobs = @intCast(word(record, 36)) };
        const tic = try render.texture(image);
        const rt = try render.target(image);
        try t.expectEqualSlices(u8, record[40..72], std.mem.asBytes(&tic));
        try t.expectEqualSlices(u8, record[72..108], std.mem.asBytes(&rt.words));
        image.bytes -= 1; try t.expectError(error.Bounds, render.texture(image)); image.bytes += 1;
        if (image.layout == .linear) {
            image.address += 32;
            _ = try render.texture(image);
            try t.expectError(error.Unsupported, render.target(image));
        } else {
            image.pitch += 64; image.bytes += 64 * std.mem.alignForward(u64, image.height, @as(u64, 8) << @intCast(image.log2_gobs));
            try t.expectError(error.Unsupported, render.texture(image));
        }
    }
    for ([_]render.Filter{.nearest, .bilinear}, 0..) |filter, index| {
        const sampler = render.sampler(filter);
        try t.expectEqualSlices(u8, reference[648 + index * 32..][0..32], std.mem.asBytes(&sampler));
    }
}
