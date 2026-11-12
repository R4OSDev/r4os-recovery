//! Original bounded PNG fixture builder shared by existing owner checks.
const std = @import("std");
pub const Builder = struct {
    bytes: [4096]u8 = undefined,
    used: usize = 8,
    pub fn init() Builder {
        var result: Builder = .{};
        @memcpy(result.bytes[0..8], "\x89PNG\r\n\x1a\n");
        return result;
    }
    pub fn chunk(self: *Builder, name: *const [4]u8, data: []const u8) void {
        std.debug.assert(self.used + data.len + 12 <= self.bytes.len);
        const out = self.bytes[self.used..];
        std.mem.writeInt(u32, out[0..4], @intCast(data.len), .big);
        @memcpy(out[4..8], name);
        @memcpy(out[8..][0..data.len], data);
        std.mem.writeInt(u32, out[8 + data.len ..][0..4], std.hash.crc.Crc32.hash(out[4..][0 .. data.len + 4]), .big);
        self.used += data.len + 12;
    }
    pub fn header(self: *Builder) void {
        self.chunk("IHDR", &.{ 0, 0, 0, 2, 0, 0, 0, 1, 16, 6, 0, 0, 0 });
    }
    pub fn finish(self: *Builder) void {
        // Filter0, followed by two RGBA16 big-endian pixels with low bits
        // that cannot survive the old8-bit decoder.
        const scanline = [_]u8{ 0, 0, 1, 1, 1, 0x12, 0x34, 0xff, 0xff, 0xab, 0xcd, 0x80, 1, 0, 3, 0x7f, 0xfd };
        var packed_bytes: [64]u8 = undefined;
        self.chunk("IDAT", stored(&scanline, &packed_bytes));
        self.chunk("IEND", &.{});
    }
    pub fn rgba16(self: *Builder, channels: [8]u16) void {
        var scanline: [17]u8 = undefined;
        scanline[0] = 0;
        for (channels, 0..) |value, i| std.mem.writeInt(u16, scanline[1 + i * 2 ..][0..2], value, .big);
        var compressed: [64]u8 = undefined;
        self.chunk("IDAT", stored(&scanline, &compressed));
        self.chunk("IEND", &.{});
    }
    pub fn view(self: *const Builder) []const u8 {
        return self.bytes[0..self.used];
    }
};
pub fn stored(bytes: []const u8, output: []u8) []u8 {
    std.debug.assert(bytes.len <= 65535 and output.len >= bytes.len + 11);
    output[0] = 0x78;
    output[1] = 0x01;
    output[2] = 1;
    const length: u16 = @intCast(bytes.len);
    std.mem.writeInt(u16, output[3..5], length, .little);
    std.mem.writeInt(u16, output[5..7], ~length, .little);
    @memcpy(output[7..][0..bytes.len], bytes);
    std.mem.writeInt(u32, output[7 + bytes.len ..][0..4], std.hash.Adler32.hash(bytes), .big);
    return output[0 .. bytes.len + 11];
}
