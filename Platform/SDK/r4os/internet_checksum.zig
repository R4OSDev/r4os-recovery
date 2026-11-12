//! Streaming Internet one's-complement sum; RFC1071 (informational).
//! UDP zero encoding, pseudoheader composition and offload trust stay in the
//! protocol. Explicit pseudoheader bytes enter the same byte stream first.
const std = @import("std");
pub const Error = error{ LengthOverflow, InvalidState };
pub const Checksum16 = extern struct {
    sum: u32 = 0,
    pending: u8 = 0,
    odd: u8 = 0,
    reserved: u16 = 0,
    bytes: u64 = 0,
    fn valid(self: Checksum16) bool {
        return self.sum <= 0xffff and self.odd <= 1 and self.reserved == 0 and self.odd == (self.bytes & 1) and (self.odd != 0 or self.pending == 0);
    }
    fn word(self: *Checksum16, value: u16) void {
        const total = self.sum + value;
        self.sum = (total & 0xffff) + (total >> 16);
    }
    /// Carries and an odd high byte survive chunk boundaries. Process a local
    /// state and commit only on success; input bytes are never retained.
    pub fn add(self: *Checksum16, input: []const u8) Error!void {
        if (!self.valid()) return error.InvalidState;
        var next = self.*;
        next.bytes = std.math.add(u64, next.bytes, input.len) catch return error.LengthOverflow;
        var index: usize = 0;
        if (next.odd != 0 and input.len != 0) {
            next.word(@as(u16, next.pending) << 8 | input[0]);
            next.pending = 0;
            next.odd = 0;
            index = 1;
        }
        while (input.len - index >= 2) : (index += 2) next.word(@as(u16, input[index]) << 8 | input[index + 1]);
        if (index != input.len) {
            next.pending = input[index];
            next.odd = 1;
        }
        self.* = next;
    }
    /// Non-mutating final snapshot; repeated finish and later add are allowed.
    /// Empty input yields ffff; raw zero is not remapped to UDP's ffff.
    pub fn finish(self: Checksum16) Error!u16 {
        if (!self.valid()) return error.InvalidState;
        var next = self;
        if (next.odd != 0) next.word(@as(u16, next.pending) << 8);
        return ~@as(u16, @intCast(next.sum));
    }
};
test "wire owner Internet checksum RFC1071 example all chunk parities and long carry" {
    const data = [_]u8{ 0x00, 0x01, 0xf2, 0x03, 0xf4, 0xf5, 0xf6, 0xf7 };
    for (0..data.len + 1) |cut| {
        var checksum: Checksum16 = .{};
        try checksum.add(data[0..cut]);
        try checksum.add(&.{});
        try checksum.add(data[cut..]);
        try std.testing.expectEqual(@as(u16, 0x220d), try checksum.finish());
        try std.testing.expectEqual(@as(u16, 0x220d), try checksum.finish());
    }
    var empty: Checksum16 = .{};
    try std.testing.expectEqual(@as(u16, 0xffff), try empty.finish());
    try empty.add(&.{ 0xff, 0xff });
    try std.testing.expectEqual(@as(u16, 0), try empty.finish());
    const odd = [_]u8{ 1, 2, 3 };
    for (0..odd.len + 1) |cut| {
        var partial: Checksum16 = .{};
        try partial.add(odd[0..cut]);
        try partial.add(&.{});
        try partial.add(odd[cut..]);
        try std.testing.expectEqual(@as(u16, 0xfbfd), try partial.finish());
    }
    const block = [_]u8{0xff} ** 4096;
    var long: Checksum16 = .{};
    for (0..128) |_| try long.add(&block);
    try std.testing.expectEqual(@as(u16, 0), try long.finish());
    var overflow: Checksum16 = .{ .bytes = std.math.maxInt(u64) - 1 };
    const before = overflow;
    try std.testing.expectError(error.LengthOverflow, overflow.add(&.{ 0, 1 }));
    try std.testing.expectEqualDeep(before, overflow);
}
