const std = @import("std");
const t = std.testing;
const color = @import("r4img").raster_color;
const f = @import("raster_fixture.zig");
pub fn check() !void {
    var icc: [132]u8 = @splat(0);
    std.mem.writeInt(u32, icc[0..4], icc.len, .big);
    @memcpy(icc[16..20], "RGB ");
    @memcpy(icc[36..40], "acsp");
    var buffer: [32768]u8 = undefined;
    const jpeg = f.jpeg(&buffer, &icc);
    const parsed = try color.parse(jpeg);
    try t.expectEqual(color.Kind.icc, parsed.kind);
    var recovered: [140]u8 = @splat(0xa5);
    try t.expectEqualSlices(u8, &icc, try parsed.profile(&recovered));
    try t.expectEqual(@as(u8, 0xa5), recovered[132]);
    try t.expectError(error.PixelBufferTooSmall, parsed.profile(recovered[0..131]));
    jpeg[18] = 1; // Duplicate sequence1.
    try t.expectError(error.InvalidImage, color.parse(jpeg));
    jpeg[18] = 2;
    jpeg[19] = 3; // Inconsistent/missing chunk.
    try t.expectError(error.InvalidImage, color.parse(jpeg));
    _ = f.jpeg(&buffer, &icc);
    jpeg[20] ^= 1; // Header byte40 is harmless; corrupt ICC signature via chunk1.
    const first_length = 18 + icc.len - 40;
    jpeg[2 + first_length + 18 + 36] ^= 1;
    try t.expectError(error.InvalidImage, color.parse(jpeg));
    try t.expectEqual(color.Kind.unspecified, (try color.parse(f.baseline)).kind);
    try t.expectEqual(color.Kind.unspecified, (try color.parse(f.progressive)).kind);
    try t.expectError(error.InvalidImage, color.parse(f.baseline[0 .. f.baseline.len - 2]));
    // APP2 after a complete entropy scan still belongs to this image.
    @memcpy(buffer[0 .. f.baseline.len - 2], f.baseline[0 .. f.baseline.len - 2]);
    var at = f.baseline.len - 2;
    at += f.icc(buffer[at..], &icc, 1, 1);
    @memcpy(buffer[at..][0..2], "\xff\xd9");
    try t.expectEqual(color.Kind.icc, (try color.parse(buffer[0 .. at + 2])).kind);
    var exif_buffer: [50]u8 = undefined;
    for ([_]u16{ 1, 0xffff, 2 }) |value| {
        @memcpy(buffer[0..2], "\xff\xd8");
        at = 2 + f.segment(buffer[2..], 0xe1, f.exif(&exif_buffer, value));
        @memcpy(buffer[at..][0 .. f.baseline.len - 2], f.baseline[2..]);
        try t.expectEqual(if (value == 1) color.Kind.srgb else color.Kind.unknown, (try color.parse(buffer[0 .. at + f.baseline.len - 2])).kind);
    }
    var bitmap = f.bmp(&buffer, 0x4d424544, &icc);
    const bmp = try color.parse(bitmap);
    try t.expectEqualSlices(u8, &icc, try bmp.profile(&recovered));
    f.put(u32, bitmap, 126, 124); // Profile overlaps pixels, not a packed DIB.
    try t.expectError(error.InvalidImage, color.parse(bitmap));
    bitmap = f.bmp(&buffer, 0x4c494e4b, "C:\\missing.icc\x00");
    const linked = try color.parse(bitmap);
    try t.expectEqual(color.Kind.linked, linked.kind);
    try t.expectError(error.UnsupportedFeature, linked.profile(&recovered));
    bitmap[bitmap.len - 1] = 'x';
    try t.expectError(error.InvalidImage, color.parse(bitmap));
    try t.expectEqual(color.Kind.srgb, (try color.parse(f.bmp(&buffer, 0x73524742, &.{}))).kind);
    const calibrated = try color.parse(f.bmp(&buffer, 0, &.{}));
    try t.expectEqual(color.Kind.calibrated, calibrated.kind);
    try t.expectEqual(@as(u32, 65536), calibrated.gamma[2]);
    try t.expectEqual(color.Kind.unknown, (try color.parse(f.bmp(&buffer, 0x12345678, &.{}))).kind);
    @memcpy(icc[16..20], "CMYK");
    try t.expectError(error.InvalidImage, color.parse(f.bmp(&buffer, 0x4d424544, &icc)));
}
