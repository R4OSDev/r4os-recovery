//! Small original wrappers around the existing licensed JPEG fixture and a
//! two-pixel BMP. Metadata/profile payloads are supplied by each caller.
const std = @import("std");
pub const baseline = @embedFile("Fixtures/baseline.jpg");
pub const progressive = @embedFile("Fixtures/progressive.jpg");
pub fn put(comptime T: type, bytes: []u8, at: usize, value: T) void {
    std.mem.writeInt(T, bytes[at..][0..@sizeOf(T)], value, .little);
}
pub fn segment(output: []u8, marker: u8, data: []const u8) usize {
    output[0] = 0xff;
    output[1] = marker;
    std.mem.writeInt(u16, output[2..4], @intCast(data.len + 2), .big);
    @memcpy(output[4..][0..data.len], data);
    return data.len + 4;
}
pub fn icc(output: []u8, payload: []const u8, sequence: u8, count: u8) usize {
    output[0] = 0xff;
    output[1] = 0xe2;
    std.mem.writeInt(u16, output[2..4], @intCast(payload.len + 16), .big);
    @memcpy(output[4..16], "ICC_PROFILE\x00");
    output[16] = sequence;
    output[17] = count;
    @memcpy(output[18..][0..payload.len], payload);
    return payload.len + 18;
}
pub fn jpeg(output: []u8, profile: []const u8) []u8 {
    return jpegWithSource(output, profile, baseline);
}
pub fn jpegWithSource(output: []u8, profile: []const u8, source: []const u8) []u8 {
    @memcpy(output[0..2], "\xff\xd8");
    var at: usize = 2;
    if (profile.len != 0) {
        // Reverse order and split the ICC header itself across two chunks.
        at += icc(output[at..], profile[40..], 2, 2);
        at += icc(output[at..], profile[0..40], 1, 2);
    }
    @memcpy(output[at..][0 .. source.len - 2], source[2..]);
    return output[0 .. at + source.len - 2];
}
pub fn bmp(output: []u8, space: u32, profile: []const u8) []u8 {
    const length = 146 + profile.len;
    @memset(output[0..length], 0);
    @memcpy(output[0..2], "BM");
    put(u32, output, 2, @intCast(length));
    put(u32, output, 10, 138);
    put(u32, output, 14, 124);
    put(u32, output, 18, 2);
    put(u32, output, 22, 1);
    put(u16, output, 26, 1);
    put(u16, output, 28, 24);
    put(u32, output, 34, 8);
    put(u32, output, 70, space);
    // sRGB/D65 XYZ matrix, signed2.30, with linear channel response.
    const matrix = [_]f64{ 0.4123908, 0.2126390, 0.0193308, 0.3575843, 0.7151687, 0.1191948, 0.1804808, 0.0721923, 0.9505322 };
    for (matrix, 0..) |value, i| put(i32, output, 74 + i * 4, @intFromFloat(@round(value * 1073741824.0)));
    for (0..3) |i| put(u32, output, 110 + i * 4, 65536);
    put(u32, output, 122, 2);
    if (profile.len != 0) {
        put(u32, output, 126, 132);
        put(u32, output, 130, @intCast(profile.len));
        @memcpy(output[146..length], profile);
    }
    @memset(output[138..141], 128);
    @memset(output[141..144], 255);
    return output[0..length];
}
pub fn exif(output: []u8, value: u16) []u8 {
    @memset(output[0..50], 0);
    @memcpy(output[0..6], "Exif\x00\x00");
    const tiff = output[6..50];
    @memcpy(tiff[0..2], "II");
    put(u16, tiff, 2, 42);
    put(u32, tiff, 4, 8);
    put(u16, tiff, 8, 1);
    put(u16, tiff, 10, 0x8769);
    put(u16, tiff, 12, 4);
    put(u32, tiff, 14, 1);
    put(u32, tiff, 18, 26);
    put(u16, tiff, 26, 1);
    put(u16, tiff, 28, 0xa001);
    put(u16, tiff, 30, 3);
    put(u32, tiff, 32, 1);
    put(u16, tiff, 36, value);
    return output[0..50];
}
