//! Shared pure SDK boundary for C/Rust wire/native/checksum/geometry helpers.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const wire = @import("binary_cursor.zig");
const native = @import("native_protocol_view.zig");
const checksum = @import("internet_checksum.zig");
const block = @import("block_transfer.zig");
fn wireError(err: wire.Error) i32 {
    return switch (err) {
        error.Truncated => -1,
        error.Capacity => -2,
        error.LengthOverflow => -3,
        error.InvalidBuffer => -4,
        error.InvalidState => -5,
        error.InvalidMark => -6,
        error.InvalidOrder => -7,
        error.InvalidWidth => -8,
        error.ValueOverflow => -9,
    };
}
fn span(data: ?[*]const u8, count: usize) wire.Error!wire.Span {
    const result = wire.Span{ .address = if (data) |p| @intFromPtr(p) else 0, .length = count };
    try result.validate();
    return result;
}
pub export fn R4SdkWireReaderInit(data: ?[*]const u8, length: usize, out: ?*wire.Reader) callconv(.c) i32 {
    const output = out orelse return -4;
    const bytes = span(data, length) catch |err| return wireError(err);
    output.* = .{ .address = bytes.address, .length = length };
    return 0;
}
pub export fn R4SdkWireWriterInit(data: ?[*]u8, length: usize, out: ?*wire.Writer) callconv(.c) i32 {
    const output = out orelse return -4;
    const bytes = span(data, length) catch |err| return wireError(err);
    output.* = .{ .address = bytes.address, .length = length };
    return 0;
}
pub export fn R4SdkWireTake(reader: ?*wire.Reader, count: usize, out: ?*wire.Span) callconv(.c) i32 {
    const output = out orelse return -4;
    const owner = reader orelse return -5;
    output.* = owner.take(count) catch |err| return wireError(err);
    return 0;
}
pub export fn R4SdkWireReadInteger(reader: ?*wire.Reader, width: u32, raw_order: u32, out: ?*u64) callconv(.c) i32 {
    const output = out orelse return -4;
    const owner = reader orelse return -5;
    const order = std.enums.fromInt(wire.Order, raw_order) orelse return -7;
    const value: u64 = switch (width) {
        1 => owner.readInt(u8, order) catch |err| return wireError(err),
        2 => owner.readInt(u16, order) catch |err| return wireError(err),
        4 => owner.readInt(u32, order) catch |err| return wireError(err),
        8 => owner.readInt(u64, order) catch |err| return wireError(err),
        else => return -8,
    };
    output.* = value;
    return 0;
}
pub export fn R4SdkWirePut(writer: ?*wire.Writer, data: ?[*]const u8, length: usize) callconv(.c) i32 {
    const owner = writer orelse return -5;
    const bytes = span(data, length) catch |err| return wireError(err);
    owner.put(bytes.bytes() catch |err| return wireError(err)) catch |err| return wireError(err);
    return 0;
}
pub export fn R4SdkWireWriteInteger(writer: ?*wire.Writer, width: u32, raw_order: u32, value: u64) callconv(.c) i32 {
    const owner = writer orelse return -5;
    const order = std.enums.fromInt(wire.Order, raw_order) orelse return -7;
    switch (width) {
        1 => {
            if (value > std.math.maxInt(u8)) return -9;
            owner.writeInt(u8, @intCast(value), order) catch |err| return wireError(err);
        },
        2 => {
            if (value > std.math.maxInt(u16)) return -9;
            owner.writeInt(u16, @intCast(value), order) catch |err| return wireError(err);
        },
        4 => {
            if (value > std.math.maxInt(u32)) return -9;
            owner.writeInt(u32, @intCast(value), order) catch |err| return wireError(err);
        },
        8 => owner.writeInt(u64, value, order) catch |err| return wireError(err),
        else => return -8,
    }
    return 0;
}
pub export fn R4SdkWireReaderMark(reader: ?*const wire.Reader, out: ?*wire.Mark) callconv(.c) i32 {
    const output = out orelse return -4;
    output.* = (reader orelse return -5).checkpoint() catch |err| return wireError(err);
    return 0;
}
pub export fn R4SdkWireWriterMark(writer: ?*const wire.Writer, out: ?*wire.Mark) callconv(.c) i32 {
    const output = out orelse return -4;
    output.* = (writer orelse return -5).checkpoint() catch |err| return wireError(err);
    return 0;
}
pub export fn R4SdkWireReaderRestore(reader: ?*wire.Reader, mark: wire.Mark) callconv(.c) i32 {
    (reader orelse return -5).restoreMark(mark) catch |err| return wireError(err);
    return 0;
}
pub export fn R4SdkWireWriterRestore(writer: ?*wire.Writer, mark: wire.Mark) callconv(.c) i32 {
    (writer orelse return -5).restoreMark(mark) catch |err| return wireError(err);
    return 0;
}
fn checksumError(err: checksum.Error) i32 {
    return switch (err) {
        error.LengthOverflow => -1,
        error.InvalidState => -2,
    };
}
pub export fn R4SdkChecksumInit(out: ?*checksum.Checksum16) callconv(.c) i32 {
    (out orelse return -2).* = .{};
    return 0;
}
pub export fn R4SdkChecksumAdd(state: ?*checksum.Checksum16, data: ?[*]const u8, length: usize) callconv(.c) i32 {
    const owner = state orelse return -2;
    const bytes = span(data, length) catch |err| return if (err == error.LengthOverflow) -1 else -3;
    owner.add(bytes.bytes() catch return -3) catch |err| return checksumError(err);
    return 0;
}
pub export fn R4SdkChecksumFinish(state: ?*const checksum.Checksum16, out: ?*u16) callconv(.c) i32 {
    const output = out orelse return -3;
    output.* = (state orelse return -2).finish() catch |err| return checksumError(err);
    return 0;
}
fn nativeError(err: native.Error) i32 {
    return switch (err) {
        error.NullBuffer => -1,
        error.TooShort => -2,
        error.LengthMismatch => -3,
        error.Misaligned => -4,
        error.UnsupportedVersion => -5,
        error.InvalidHeaderSize => -6,
        error.InvalidDirection => -7,
        error.InvalidFlags => -8,
        error.InvalidPolicy => -9,
        error.LengthOverflow => -10,
    };
}
pub export fn R4SdkNativeAdmit(buffer: ?*const abi.ProtocolBuffer, policy: native.Policy, raw_access: u32, out: ?*usize) callconv(.c) i32 {
    const output = out orelse return -1;
    const access = std.enums.fromInt(native.Direction, raw_access) orelse return -7;
    output.* = native.admit(buffer orelse return -1, policy, access) catch |err| return nativeError(err);
    return 0;
}
pub export fn R4SdkNativePublish(buffer: ?*abi.ProtocolBuffer, policy: native.Policy, written: u32) callconv(.c) i32 {
    native.publish(buffer orelse return -1, policy, written) catch |err| return nativeError(err);
    return 0;
}
fn blockError(err: block.Error) i32 {
    return switch (err) {
        error.ZeroCount => -1,
        error.UnknownGeometry => -2,
        error.UnsupportedShape => -3,
        error.OutOfRange => -4,
        error.LengthMismatch => -5,
        error.Overflow => -6,
    };
}
pub export fn R4SdkBlockTransfer(lba: u64, count: u64, block_bytes: u64, buffer_bytes: u64, limits: block.Limits, out: ?*block.Shape) callconv(.c) i32 {
    const output = out orelse return -7;
    output.* = block.validate(lba, count, block_bytes, buffer_bytes, limits) catch |err| return blockError(err);
    return 0;
}
