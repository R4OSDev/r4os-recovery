const std = @import("std");
const r4os = @import("r4os");
const runtime = @import("runtime.zig");
const abi = runtime.abi;

pub const Error = error{
    InvalidUtf8,
    EmbeddedNul,
    InvalidLineEnding,
    InvalidUiText8,
    BufferTooSmall,
    RuntimeUnavailable,
};

pub const Encoding = enum(u8) {
    bytes = abi.encoding_bytes,
    utf8 = abi.encoding_utf8,
    utf8_bom = abi.encoding_utf8_bom,
};

pub const LineEnding = enum(u8) {
    none = abi.line_ending_none,
    lf = abi.line_ending_lf,
    crlf = abi.line_ending_crlf,
    mixed = abi.line_ending_mixed,
};

pub const Bytes = struct {
    bytes: []const u8,

    pub fn init(bytes: []const u8) Bytes {
        return .{ .bytes = bytes };
    }

    pub fn view(self: Bytes) r4os.abi.R4TextView {
        return textView(self.bytes);
    }
};

pub const Utf8Text = struct {
    bytes: []const u8,
    scalar_count: usize,

    pub fn init(bytes: []const u8) Error!Utf8Text {
        const info = try inspect(bytes, abi.text_kind_utf8);
        return .{ .bytes = bytes, .scalar_count = std.math.cast(usize, info.scalar_count) orelse return error.InvalidUtf8 };
    }

    pub fn byteLen(self: Utf8Text) usize {
        return self.bytes.len;
    }

    pub fn scalarCount(self: Utf8Text) usize {
        return self.scalar_count;
    }

    pub fn view(self: Utf8Text) r4os.abi.R4TextView {
        return textView(self.bytes);
    }
};

pub const UiText8 = struct {
    bytes: []const u8,

    pub fn init(bytes: []const u8) Error!UiText8 {
        _ = try inspect(bytes, abi.text_kind_ui);
        return .{ .bytes = bytes };
    }

    pub fn view(self: UiText8) r4os.abi.R4TextView {
        return textView(self.bytes);
    }
};

pub const SystemText = struct {
    content: []const u8,
    source: []const u8,
    canonical_length: usize,

    pub fn parse(bytes: []const u8) Error!SystemText {
        const info = try inspect(bytes, abi.text_kind_system);
        const offset = std.math.cast(usize, info.content_offset) orelse return error.InvalidUtf8;
        const length = std.math.cast(usize, info.content_length) orelse return error.InvalidUtf8;
        if (offset > bytes.len or length > bytes.len - offset) return error.InvalidUtf8;
        return .{
            .content = bytes[offset .. offset + length],
            .source = bytes,
            .canonical_length = std.math.cast(usize, info.canonical_length) orelse return error.BufferTooSmall,
        };
    }

    pub fn canonicalSize(self: SystemText) usize {
        return self.canonical_length;
    }

    pub fn writeCanonical(self: SystemText, out: []u8) Error![]const u8 {
        return write(self.source, abi.text_write_canonical, out);
    }
};

pub const DocumentText = struct {
    bytes: []const u8,
    encoding: Encoding,
    line_ending: LineEnding,

    pub fn init(bytes: []const u8) Error!DocumentText {
        const info = try inspect(bytes, abi.text_kind_document);
        return .{
            .bytes = bytes,
            .encoding = switch (info.encoding) {
                abi.encoding_bytes => .bytes,
                abi.encoding_utf8 => .utf8,
                abi.encoding_utf8_bom => .utf8_bom,
                else => return error.InvalidUtf8,
            },
            .line_ending = switch (info.line_ending) {
                abi.line_ending_none => .none,
                abi.line_ending_lf => .lf,
                abi.line_ending_crlf => .crlf,
                abi.line_ending_mixed => .mixed,
                else => return error.InvalidLineEnding,
            },
        };
    }

    pub fn writeExact(self: DocumentText, out: []u8) Error![]const u8 {
        return write(self.bytes, abi.text_write_exact, out);
    }
};

pub const utf8_bom = "\xEF\xBB\xBF";

pub fn textView(bytes: []const u8) r4os.abi.R4TextView {
    return .{ .ptr = if (bytes.len == 0) null else bytes.ptr, .len = @intCast(bytes.len) };
}

pub fn validateUtf8(bytes: []const u8) Error!void {
    _ = try inspect(bytes, abi.text_kind_utf8);
}

pub fn validateUiText8(bytes: []const u8) Error!void {
    _ = try inspect(bytes, abi.text_kind_ui);
}

fn inspect(bytes: []const u8, kind: u32) Error!abi.R4StdTextInfo {
    if (!runtime.hasText()) return error.RuntimeUnavailable;
    var info = std.mem.zeroes(abi.R4StdTextInfo);
    const status = runtime.text().inspect(bytes.ptr, bytes.len, kind, &info);
    if (status != abi.status_ok) return errorForStatus(status, kind);
    return info;
}

fn write(bytes: []const u8, mode: u32, out: []u8) Error![]const u8 {
    if (!runtime.hasText()) return error.RuntimeUnavailable;
    var written: u64 = 0;
    const status = runtime.text().write(bytes.ptr, bytes.len, mode, out.ptr, out.len, &written);
    if (status != abi.status_ok) return errorForStatus(status, 0);
    const length = std.math.cast(usize, written) orelse return error.BufferTooSmall;
    if (length > out.len) return error.BufferTooSmall;
    return out[0..length];
}

fn errorForStatus(status: i32, kind: u32) Error {
    if (status == abi.status_buffer_too_small) return error.BufferTooSmall;
    if (kind == abi.text_kind_ui) return error.InvalidUiText8;
    if (kind == abi.text_kind_system) return error.InvalidLineEnding;
    return error.InvalidUtf8;
}
