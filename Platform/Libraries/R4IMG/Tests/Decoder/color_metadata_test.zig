//! Targeted PNG3 metadata and source precision cases within the existing
//! PNG decoder group. Fixtures are original tiny stored-deflate streams.
const std = @import("std");
const t = std.testing;
const image = @import("r4img");
const metadata = image.color_metadata;
const Builder = @import("png_fixture.zig").Builder;
const stored = @import("png_fixture.zig").stored;
pub fn check() !void {
    var plain = Builder.init();
    plain.header();
    plain.finish();
    const info = try image.r4imgProbe(plain.view(), "image/png");
    const scratch = try t.allocator.alloc(u8, try image.pngScratchBytes16(info, plain.used));
    defer t.allocator.free(scratch);
    var pixels: [12]u16 = @splat(0xa5a5);
    const decoded = try image.pngDecode16(plain.view(), &pixels, scratch);
    try t.expectEqual(metadata.Kind.unspecified, decoded.metadata.kind());
    try t.expectEqual(@as(u8, 16), decoded.metadata.bit_depth);
    try t.expectEqualSlices(u16, &.{ 1, 257, 0x1234, 65535, 0xabcd, 0x8001, 3, 0x7ffd }, decoded.rgba);
    try t.expectEqualSlices(u16, &.{ 0xa5a5, 0xa5a5, 0xa5a5, 0xa5a5 }, pixels[8..]);
    const kept = pixels;
    try t.expectError(error.PixelBufferTooSmall, image.pngDecode16(plain.view(), pixels[0..7], scratch));
    try t.expectEqualSlices(u16, &kept, &pixels);
    var tagged = Builder.init();
    tagged.header();
    tagged.chunk("gAMA", &.{ 0, 0, 0xb1, 0x8f }); //45455
    tagged.chunk("sRGB", &.{1});
    const legacy = tagged;
    tagged.chunk("cICP", &.{ 9, 16, 0, 1 });
    const mastering = [_]u8{ 0x8a, 0x48, 0x39, 0x08, 0x21, 0x34, 0x9b, 0xaa, 0x19, 0x96, 0x08, 0xfc, 0x3d, 0x13, 0x40, 0x42, 0, 0x98, 0x96, 0x80, 0, 0, 0, 5 }; //1000nit,0.0005nit
    tagged.chunk("mDCV", &mastering);
    tagged.chunk("cLLI", &.{ 0, 0x98, 0x96, 0x80, 0, 0x3d, 0x09, 0 }); //1000/400nit
    tagged.finish();
    const hdr = try metadata.png(tagged.view());
    try t.expectEqual(metadata.Kind.cicp, hdr.kind());
    try t.expectEqual(@as(u32, 10000000), hdr.mastering.?.maximum);
    try t.expectEqual(@as(u32, 5), hdr.mastering.?.minimum);
    try t.expectEqual(@as(u32, 4000000), hdr.content_light.?[1]);
    var fallback = legacy;
    fallback.chunk("cICP", &.{ 2, 13, 0, 1 });
    fallback.finish();
    try t.expectEqual(metadata.Kind.srgb, (try metadata.png(fallback.view())).kind());
    var bad = legacy;
    bad.chunk("gAMA", &.{ 0, 0, 0xb1, 0x8f });
    bad.finish();
    try t.expectError(error.InvalidImage, metadata.png(bad.view()));
    bad = legacy;
    bad.chunk("cICP", &.{ 9, 16, 1, 1 });
    bad.finish();
    try t.expectError(error.InvalidImage, metadata.png(bad.view()));
    bad = legacy;
    bad.chunk("mDCV", &mastering);
    bad.finish();
    try t.expectError(error.InvalidImage, metadata.png(bad.view()));
    bad = plain;
    bad.bytes[bad.used - 1] ^= 1;
    try t.expectError(error.InvalidImage, metadata.png(bad.view()));
    try t.expectError(error.InvalidImage, metadata.png(plain.bytes[0 .. plain.used - 12]));
    // Explicitly retain and decompress complete ICC bytes. These are a
    // metadata fixture, not a claim of a usable transform profile.
    var profile: [132]u8 = @splat(0);
    std.mem.writeInt(u32, profile[0..4], profile.len, .big);
    profile[8] = 4;
    @memcpy(profile[16..20], "RGB ");
    @memcpy(profile[36..40], "acsp");
    var compression: [200]u8 = undefined;
    var iccp: [220]u8 = undefined;
    @memcpy(iccp[0..9], "Original\x00");
    iccp[9] = 0;
    const compressed = stored(&profile, &compression);
    @memcpy(iccp[10..][0..compressed.len], compressed);
    var embedded = legacy;
    embedded.chunk("iCCP", iccp[0 .. compressed.len + 10]);
    embedded.finish();
    const parsed = try metadata.png(embedded.view());
    try t.expectEqual(metadata.Kind.icc, parsed.kind());
    var recovered: [256]u8 = @splat(0xa5);
    try t.expectEqualSlices(u8, &profile, try parsed.profile(&recovered));
    try t.expectError(error.PixelBufferTooSmall, parsed.profile(recovered[0..131]));
    iccp[10 + compressed.len - 1] ^= 1;
    embedded = legacy;
    embedded.chunk("iCCP", iccp[0 .. compressed.len + 10]);
    embedded.finish();
    try t.expectError(error.InvalidImage, (try metadata.png(embedded.view())).profile(&recovered));
}
