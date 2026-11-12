//! Caller-owned wire bytes. No native record casts, allocation or I/O.
//! State stays separate from its borrowed storage; marks never extend a loan.
const std = @import("std");
pub const Error = error{ Truncated, Capacity, LengthOverflow, InvalidBuffer, InvalidState, InvalidMark, InvalidOrder, InvalidWidth, ValueOverflow };
pub const Order = enum(u32) { little = 0, big = 1 };
pub const Span = extern struct {
    address: usize = 0,
    length: usize = 0,
    pub fn validate(self: Span) Error!void {
        if (self.length != 0 and self.address == 0) return error.InvalidBuffer;
        _ = std.math.add(usize, self.address, self.length) catch return error.LengthOverflow;
    }
    pub fn bytes(self: Span) Error![]const u8 {
        try self.validate();
        if (self.length == 0) return &.{};
        return @as([*]const u8, @ptrFromInt(self.address))[0..self.length];
    }
};
pub const Mark = extern struct {
    address: usize,
    length: usize,
    position: usize,
    kind: u32,
    reserved: u32 = 0,
};
fn validate(address: usize, length: usize, position: usize) Error!void {
    try (Span{ .address = address, .length = length }).validate();
    if (position > length) return error.InvalidState;
}
fn restore(address: usize, length: usize, mark: Mark, kind: u32) Error!usize {
    if (mark.reserved != 0 or mark.kind != kind or mark.address != address or mark.length != length or mark.position > length) return error.InvalidMark;
    return mark.position;
}
fn width(comptime T: type) comptime_int {
    if (@typeInfo(T) != .int) @compileError("Wire integers must be unsigned8/16/32/64");
    if (@typeInfo(T).int.signedness != .unsigned or (@bitSizeOf(T) != 8 and @bitSizeOf(T) != 16 and @bitSizeOf(T) != 32 and @bitSizeOf(T) != 64)) @compileError("Wire integers must be unsigned8/16/32/64");
    return @sizeOf(T);
}
fn endian(order: Order) std.builtin.Endian {
    return switch (order) {
        .little => .little,
        .big => .big,
    };
}
pub const Reader = extern struct {
    address: usize = 0,
    length: usize = 0,
    position: usize = 0,
    pub fn init(bytes: []const u8) Error!Reader {
        const result = Reader{ .address = @intFromPtr(bytes.ptr), .length = bytes.len };
        try validate(result.address, result.length, 0);
        return result;
    }
    /// Failed fields do not consume a prefix. Zero-length spans are valid.
    pub fn take(self: *Reader, count: usize) Error!Span {
        try validate(self.address, self.length, self.position);
        if (count > self.length - self.position) return error.Truncated;
        const result = Span{ .address = self.address + self.position, .length = count };
        self.position += count;
        return result;
    }
    pub fn readInt(self: *Reader, comptime T: type, order: Order) Error!T {
        const count = width(T);
        var candidate = self.*;
        const span = try candidate.take(count);
        const bytes = try span.bytes();
        const value = std.mem.readInt(T, @as(*const [count]u8, @ptrCast(bytes.ptr)), endian(order));
        self.position = candidate.position;
        return value;
    }
    pub fn checkpoint(self: *const Reader) Error!Mark {
        try validate(self.address, self.length, self.position);
        return .{ .address = self.address, .length = self.length, .position = self.position, .kind = 1 };
    }
    pub fn restoreMark(self: *Reader, mark: Mark) Error!void {
        try validate(self.address, self.length, self.position);
        self.position = try restore(self.address, self.length, mark, 1);
    }
};
pub const Writer = extern struct {
    address: usize = 0,
    length: usize = 0,
    position: usize = 0,
    pub fn init(bytes: []u8) Error!Writer {
        const result = Writer{ .address = @intFromPtr(bytes.ptr), .length = bytes.len };
        try validate(result.address, result.length, 0);
        return result;
    }
    /// Whole-field commit; overlapping input/output has memmove semantics.
    pub fn put(self: *Writer, bytes: []const u8) Error!void {
        try validate(self.address, self.length, self.position);
        try (Span{ .address = @intFromPtr(bytes.ptr), .length = bytes.len }).validate();
        if (bytes.len > self.length - self.position) return error.Capacity;
        if (bytes.len == 0) return;
        const destination = self.address + self.position;
        const output = @as([*]u8, @ptrFromInt(destination))[0..bytes.len];
        const source = @intFromPtr(bytes.ptr);
        if (destination > source and destination - source < bytes.len) std.mem.copyBackwards(u8, output, bytes) else std.mem.copyForwards(u8, output, bytes);
        self.position += bytes.len;
    }
    pub fn writeInt(self: *Writer, comptime T: type, value: T, order: Order) Error!void {
        var bytes: [width(T)]u8 = undefined;
        std.mem.writeInt(T, &bytes, value, endian(order));
        try self.put(&bytes);
    }
    pub fn checkpoint(self: *const Writer) Error!Mark {
        try validate(self.address, self.length, self.position);
        return .{ .address = self.address, .length = self.length, .position = self.position, .kind = 2 };
    }
    /// Restores position, never undoes previously written bytes. Marks bind a
    /// span/direction, not a globally unique cursor instance or allocation.
    pub fn restoreMark(self: *Writer, mark: Mark) Error!void {
        try validate(self.address, self.length, self.position);
        self.position = try restore(self.address, self.length, mark, 2);
    }
};

test "wire owner unaligned endian fields checkpoint and atomic failure" {
    const bytes align(8) = [_]u8{ 0xff, 1, 2, 3, 4, 5, 6, 7, 8 };
    var reader = try Reader.init(bytes[1..]);
    try std.testing.expectEqual(@as(u16, 0x0102), try reader.readInt(u16, .big));
    const mark = try reader.checkpoint();
    try std.testing.expectEqual(@as(u32, 0x06050403), try reader.readInt(u32, .little));
    const before = reader;
    try std.testing.expectError(error.Truncated, reader.readInt(u32, .big));
    try std.testing.expectEqualDeep(before, reader);
    try reader.restoreMark(mark);
    try std.testing.expectEqual(@as(u16, 0x0304), try reader.readInt(u16, .big));
    var wrong = mark;
    wrong.kind = 2;
    try std.testing.expectError(error.InvalidMark, reader.restoreMark(wrong));
    var null_reader: Reader = .{};
    try std.testing.expectEqual(@as(usize, 0), (try null_reader.take(0)).length);
    try std.testing.expectError(error.Truncated, null_reader.take(1));
}
test "wire owner writer memmove and whole field capacity with no hidden rollback" {
    var bytes = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7 };
    var writer = try Writer.init(&bytes);
    writer.position = 2;
    try writer.put(bytes[0..6]);
    try std.testing.expectEqualSlices(u8, &.{ 0, 1, 0, 1, 2, 3, 4, 5 }, &bytes);
    const mark = try writer.checkpoint();
    const before = bytes;
    try std.testing.expectError(error.Capacity, writer.writeInt(u16, 0xabcd, .big));
    try std.testing.expectEqualDeep(before, bytes);
    try std.testing.expectEqual(mark.position, writer.position);
    var first = try Writer.init(bytes[1..]);
    try first.writeInt(u32, 0x12345678, .big);
    try std.testing.expectEqualSlices(u8, &.{ 0x12, 0x34, 0x56, 0x78 }, bytes[1..5]);
    var overflow: Reader = .{ .address = std.math.maxInt(usize) - 1, .length = 8 };
    try std.testing.expectError(error.LengthOverflow, overflow.take(1));
}
