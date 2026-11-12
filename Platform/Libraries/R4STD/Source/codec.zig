const std = @import("std");
const abi = @import("r4l_contract");
const tables = @import("codec_tables.zig");

pub const Error = error{ InvalidArgument, InvalidScalar, UndefinedByte, Unrepresentable, BufferTooSmall };
pub const Decoded = union(enum) { complete: abi.R4StdScalarResult, incomplete: u32, invalid };

pub fn validScalar(scalar: u32) bool {
    return scalar <= 0x10ffff and !(scalar >= 0xd800 and scalar <= 0xdfff);
}

fn tableFor(codepage: u32, mode: u32) Error!*const [256]u32 {
    if (mode != abi.codec_mode_controls and mode != abi.codec_mode_pc_graphics) return error.InvalidArgument;
    return switch (codepage) {
        abi.codepage_cp437 => if (mode == abi.codec_mode_controls) &tables.cp437 else &tables.pc_graphics,
        abi.codepage_windows1252 => if (mode == abi.codec_mode_controls) &tables.windows1252 else error.InvalidArgument,
        // CP850 is a distinct encoding, never a synonym for CP437.
        else => error.InvalidArgument,
    };
}

pub fn legacyDecode(codepage: u32, mode: u32, byte: u32) Error!u32 {
    const table = try tableFor(codepage, mode);
    if (byte > 255) return error.InvalidArgument;
    const scalar = table[byte];
    if (scalar == tables.undefined_scalar) return error.UndefinedByte;
    return scalar;
}

pub fn legacyEncode(codepage: u32, mode: u32, scalar: u32) Error!u8 {
    const table = try tableFor(codepage, mode);
    if (!validScalar(scalar)) return error.InvalidScalar;
    for (table, 0..) |value, byte| if (value == scalar) return @intCast(byte);
    return error.Unrepresentable;
}

/// Strict Unicode scalar UTF-8 (RFC3629/Table3-7), including scalar U+0000.
/// A valid prefix is incomplete; an impossible prefix is invalid immediately.
/// Read no more than four bytes, irrespective of the following text span.
pub fn decode(bytes: []const u8) Decoded {
    if (bytes.len == 0) return .{ .incomplete = 1 };
    const first = bytes[0];
    const required: u32 = switch (first) {
        0...0x7f => 1,
        0xc2...0xdf => 2,
        0xe0...0xef => 3,
        0xf0...0xf4 => 4,
        else => return .invalid,
    };
    var scalar: u32 = switch (required) {
        1 => first,
        2 => first & 0x1f,
        3 => first & 0x0f,
        else => first & 7,
    };
    var index: usize = 1;
    while (index < required and index < bytes.len) : (index += 1) {
        var low: u8 = 0x80;
        var high: u8 = 0xbf;
        if (index == 1) switch (first) {
            0xe0 => low = 0xa0,
            0xed => high = 0x9f,
            0xf0 => low = 0x90,
            0xf4 => high = 0x8f,
            else => {},
        };
        const byte = bytes[index];
        if (byte < low or byte > high) return .invalid;
        scalar = (scalar << 6) | (byte & 0x3f);
    }
    if (bytes.len < required) return .{ .incomplete = required };
    return .{ .complete = .{ .scalar = scalar, .byte_length = required, .required = required, .reserved = 0 } };
}

pub fn encode(scalar: u32, output: []u8) Error!u32 {
    if (!validScalar(scalar)) return error.InvalidScalar;
    const size: u32 = if (scalar < 0x80) 1 else if (scalar < 0x800) 2 else if (scalar < 0x10000) 3 else 4;
    if (output.len < size) return error.BufferTooSmall;
    var bytes: [4]u8 = undefined;
    switch (size) {
        1 => bytes[0] = @intCast(scalar),
        2 => {
            bytes[0] = @intCast(0xc0 | (scalar >> 6));
            bytes[1] = @intCast(0x80 | (scalar & 0x3f));
        },
        3 => {
            bytes[0] = @intCast(0xe0 | (scalar >> 12));
            bytes[1] = @intCast(0x80 | ((scalar >> 6) & 0x3f));
            bytes[2] = @intCast(0x80 | (scalar & 0x3f));
        },
        else => {
            bytes[0] = @intCast(0xf0 | (scalar >> 18));
            bytes[1] = @intCast(0x80 | ((scalar >> 12) & 0x3f));
            bytes[2] = @intCast(0x80 | ((scalar >> 6) & 0x3f));
            bytes[3] = @intCast(0x80 | (scalar & 0x3f));
        },
    }
    @memcpy(output[0..size], bytes[0..size]);
    return size;
}

fn validState(state: *const abi.R4StdUtf8State) bool {
    if (state.length > 3 or state.reserved0 != 0 or state.reserved1 != 0) return false;
    if (state.length == 0) return state.packed_bytes == 0;
    if (state.packed_bytes >> @as(u5, @intCast(state.length * 8)) != 0) return false;
    var bytes: [4]u8 = undefined;
    for (bytes[0..state.length], 0..) |*byte, index| byte.* = @truncate(state.packed_bytes >> @as(u5, @intCast(index * 8)));
    return switch (decode(bytes[0..state.length])) {
        .incomplete => true,
        else => false,
    };
}

/// Invalid input is not consumed and neither state nor result is modified.
/// The caller decides whether to report, replace, discard or retry after reset.
pub fn push(state: *abi.R4StdUtf8State, byte: u32, result: *abi.R4StdScalarResult) i32 {
    if (byte > 255 or !validState(state)) return abi.status_invalid_argument;
    var bytes: [4]u8 = undefined;
    for (bytes[0..state.length], 0..) |*item, index| item.* = @truncate(state.packed_bytes >> @as(u5, @intCast(index * 8)));
    bytes[state.length] = @intCast(byte);
    switch (decode(bytes[0 .. state.length + 1])) {
        .invalid => return abi.status_invalid_text,
        .incomplete => |required| {
            state.packed_bytes |= byte << @as(u5, @intCast(state.length * 8));
            state.length += 1;
            result.* = .{ .scalar = 0, .byte_length = 0, .required = required, .reserved = 0 };
            return abi.codec_incomplete;
        },
        .complete => |value| {
            state.* = std.mem.zeroes(abi.R4StdUtf8State);
            result.* = value;
            return abi.status_ok;
        },
    }
}

pub fn finish(state: *const abi.R4StdUtf8State) i32 {
    if (!validState(state)) return abi.status_invalid_argument;
    return if (state.length == 0) abi.status_ok else abi.codec_incomplete;
}

pub fn status(err: Error) i32 {
    return switch (err) {
        error.InvalidArgument => abi.status_invalid_argument,
        error.InvalidScalar => abi.status_invalid_scalar,
        error.UndefinedByte => abi.status_undefined_byte,
        error.Unrepresentable => abi.status_unrepresentable,
        error.BufferTooSmall => abi.status_buffer_too_small,
    };
}
