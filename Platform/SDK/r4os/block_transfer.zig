//! Pure read/write geometry. Device operations, flush, mappings, DMA, pinning
//! and real I/O completion remain with the existing backend owner.
const std = @import("std");
pub const Error = error{ ZeroCount, UnknownGeometry, UnsupportedShape, OutOfRange, LengthMismatch, Overflow };
pub const BufferMode = enum(u32) { exact = 0, at_least = 1 };
pub const Limits = extern struct {
    capacity_blocks: u64,
    max_blocks: u64,
    max_bytes: u64,
    lba_bits: u32,
    buffer_mode: u32 = 0,
};
pub const Shape = extern struct { byte_count: u64, last_lba: u64 };
pub fn validate(lba: u64, count: u64, block_bytes: u64, buffer_bytes: u64, limits: Limits) Error!Shape {
    if (count == 0) return error.ZeroCount;
    if (block_bytes == 0 or limits.capacity_blocks == 0 or limits.max_blocks == 0 or limits.max_bytes == 0) return error.UnknownGeometry;
    if (limits.lba_bits == 0 or limits.lba_bits > 64 or limits.buffer_mode > 1) return error.UnsupportedShape;
    const last = std.math.add(u64, lba, count - 1) catch return error.Overflow;
    const bytes = std.math.mul(u64, count, block_bytes) catch return error.Overflow;
    const address_limit = if (limits.lba_bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(limits.lba_bits))) - 1;
    if (last > address_limit or lba >= limits.capacity_blocks or count > limits.capacity_blocks - lba) return error.OutOfRange;
    if (count > limits.max_blocks or bytes > limits.max_bytes) return error.UnsupportedShape;
    if ((limits.buffer_mode == 0 and bytes != buffer_bytes) or (limits.buffer_mode == 1 and bytes > buffer_bytes)) return error.LengthMismatch;
    return .{ .byte_count = bytes, .last_lba = last };
}
test "wire owner block geometry explicit sector sizes capacity backend and LBA bounds" {
    var limits = Limits{ .capacity_blocks = 1000, .max_blocks = 128, .max_bytes = 1_048_576, .lba_bits = 28 };
    const result = try validate(996, 4, 4096, 16384, limits);
    try std.testing.expectEqual(@as(u64, 999), result.last_lba);
    try std.testing.expectEqual(@as(u64, 16384), result.byte_count);
    try std.testing.expectError(error.OutOfRange, validate(997, 4, 4096, 16384, limits));
    try std.testing.expectError(error.LengthMismatch, validate(996, 4, 4096, 16385, limits));
    limits.buffer_mode = 1;
    _ = try validate(996, 4, 4096, 16385, limits);
    try std.testing.expectError(error.UnknownGeometry, validate(1, 1, 0, 512, limits));
    try std.testing.expectError(error.ZeroCount, validate(1, 0, 512, 0, limits));
    try std.testing.expectError(error.Overflow, validate(std.math.maxInt(u64), 2, 1, 2, limits));
    try std.testing.expectError(error.Overflow, validate(0, 2, std.math.maxInt(u64), std.math.maxInt(u64), limits));
    limits.capacity_blocks = std.math.maxInt(u64);
    try std.testing.expectError(error.OutOfRange, validate(0x0fff_ffff, 2, 512, 1024, limits));
    limits.lba_bits = 64;
    _ = try validate(0x1_0000_0000, 1, 520, 520, limits);
}
