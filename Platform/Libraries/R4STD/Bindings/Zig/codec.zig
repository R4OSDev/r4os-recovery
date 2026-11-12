const std = @import("std");
const runtime = @import("runtime.zig");
const abi = runtime.abi;

pub const Codepage = enum(u32) { cp437 = abi.codepage_cp437, windows1252 = abi.codepage_windows1252, cp850 = abi.codepage_cp850 };
pub const Mode = enum(u32) { controls = abi.codec_mode_controls, pc_graphics = abi.codec_mode_pc_graphics };
pub const Error = error{ RuntimeUnavailable, InvalidArgument, InvalidScalar, InvalidUtf8, UndefinedByte, Unrepresentable, BufferTooSmall, RangesOverlap };
pub const Scalar = struct { value: u32, byte_length: usize };
pub const Decoded = union(enum) { complete: Scalar, incomplete: u32 };

fn table() Error!*const abi.CodecV1Client {
    if (!runtime.hasCodec()) return error.RuntimeUnavailable;
    return runtime.codec();
}
fn check(status: i32) Error!void {
    return switch (status) {
        abi.status_ok => {},
        abi.status_invalid_scalar => error.InvalidScalar,
        abi.status_invalid_text => error.InvalidUtf8,
        abi.status_undefined_byte => error.UndefinedByte,
        abi.status_unrepresentable => error.Unrepresentable,
        abi.status_buffer_too_small => error.BufferTooSmall,
        abi.status_unavailable => error.RuntimeUnavailable,
        else => error.InvalidArgument,
    };
}
fn result(status: i32, value: abi.R4StdScalarResult) Error!Decoded {
    if (status == abi.codec_incomplete) return .{ .incomplete = value.required };
    try check(status);
    return .{ .complete = .{ .value = value.scalar, .byte_length = value.byte_length } };
}

pub fn legacyDecode(codepage: Codepage, mode: Mode, byte: u8) Error!u32 {
    const api = try table();
    var scalar: u32 = 0;
    try check(api.legacy_decode(@intFromEnum(codepage), @intFromEnum(mode), byte, &scalar));
    return scalar;
}
pub fn legacyEncode(codepage: Codepage, mode: Mode, scalar: u32) Error!u8 {
    const api = try table();
    var byte: u8 = 0;
    try check(api.legacy_encode(@intFromEnum(codepage), @intFromEnum(mode), scalar, &byte));
    return byte;
}
pub fn decode(input: []const u8) Error!Decoded {
    const api = try table();
    var value = std.mem.zeroes(abi.R4StdScalarResult);
    const status = api.utf8_decode(input.ptr, input.len, &value);
    return result(status, value);
}
pub fn encode(scalar: u32, output: []u8) Error![]const u8 {
    const api = try table();
    var written: u32 = 0;
    try check(api.utf8_encode(scalar, output.ptr, output.len, &written));
    return output[0..written];
}

/// Each instance owns its own at-most-three-byte pending prefix. No global decoder.
/// Errors consume nothing; explicitly reset/discard/replace and retry as appropriate.
pub const Stream = struct {
    state: abi.R4StdUtf8State = std.mem.zeroes(abi.R4StdUtf8State),

    pub fn push(self: *Stream, byte: u8) Error!Decoded {
        const api = try table();
        var value = std.mem.zeroes(abi.R4StdScalarResult);
        const status = api.utf8_push(&self.state, byte, &value);
        return result(status, value);
    }
    /// false means a valid unfinished scalar, not invalid UTF-8 or an implicit replacement.
    pub fn finish(self: *const Stream) Error!bool {
        const api = try table();
        const status = api.utf8_finish(&self.state);
        if (status == abi.codec_incomplete) return false;
        try check(status);
        return true;
    }
    pub fn reset(self: *Stream) void {
        self.state = std.mem.zeroes(abi.R4StdUtf8State);
    }
};

fn rejectOverlap(input: []const u8, output: []u8) Error!void {
    if (input.len == 0 or output.len == 0) return;
    const a = @intFromPtr(input.ptr);
    const b = @intFromPtr(output.ptr);
    const overlaps = if (a <= b) b - a < input.len else a - b < output.len;
    if (overlaps) return error.RangesOverlap;
}

/// Strict, no guessing/normalization/replacement. Preflight all input and capacity
/// before writing anything. The pinned stateless CODEC_V1 has the same immutable
/// mapping for the second pass. Overlapping spans are explicitly rejected.
pub fn legacyToUtf8(codepage: Codepage, mode: Mode, input: []const u8, output: []u8) Error![]const u8 {
    _ = try legacyDecode(codepage, mode, 0); // Validate even an empty input's policy/runtime.
    try rejectOverlap(input, output);
    var required: usize = 0;
    var scratch: [4]u8 = undefined;
    for (input) |byte| {
        const scalar = try legacyDecode(codepage, mode, byte);
        const encoded = try encode(scalar, &scratch);
        required = std.math.add(usize, required, encoded.len) catch return error.BufferTooSmall;
    }
    if (output.len < required) return error.BufferTooSmall;
    var offset: usize = 0;
    for (input) |byte| {
        const scalar = legacyDecode(codepage, mode, byte) catch unreachable;
        const encoded = encode(scalar, output[offset..]) catch unreachable;
        offset += encoded.len;
    }
    return output[0..offset];
}

pub fn utf8ToLegacy(codepage: Codepage, mode: Mode, input: []const u8, output: []u8) Error![]const u8 {
    _ = try legacyDecode(codepage, mode, 0);
    try rejectOverlap(input, output);
    var offset: usize = 0;
    var required: usize = 0;
    while (offset < input.len) {
        const scalar = switch (try decode(input[offset..])) {
            .complete => |value| value,
            .incomplete => return error.InvalidUtf8, // Complete-span conversion; streaming is separate.
        };
        _ = try legacyEncode(codepage, mode, scalar.value);
        required += 1;
        offset += scalar.byte_length;
    }
    if (output.len < required) return error.BufferTooSmall;
    offset = 0;
    var position: usize = 0;
    while (offset < input.len) {
        const scalar = (decode(input[offset..]) catch unreachable).complete;
        output[position] = legacyEncode(codepage, mode, scalar.value) catch unreachable;
        offset += scalar.byte_length;
        position += 1;
    }
    return output[0..position];
}

/// Counts Unicode scalars only. Grapheme segmentation is a separate contract.
pub fn scalarCount(input: []const u8) Error!usize {
    var count: usize = 0;
    var offset: usize = 0;
    while (offset < input.len) {
        const scalar = switch (try decode(input[offset..])) {
            .complete => |value| value,
            .incomplete => return error.InvalidUtf8,
        };
        offset += scalar.byte_length;
        count += 1;
    }
    return count;
}
