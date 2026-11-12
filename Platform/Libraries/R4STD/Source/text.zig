const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;

pub const Error = error{
    InvalidUtf8,
    EmbeddedNul,
    InvalidLineEnding,
    InvalidUiText8,
    BufferTooSmall,
};

pub const Encoding = enum(u8) {
    bytes = abi.text_encoding_bytes,
    utf8 = abi.text_encoding_utf8,
    utf8_bom = abi.text_encoding_utf8_bom,
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

    pub fn view(self: Bytes) abi.R4TextView {
        return textView(self.bytes);
    }
};

pub const Utf8Text = struct {
    bytes: []const u8,

    pub fn init(bytes: []const u8) Error!Utf8Text {
        try validateUtf8(bytes);
        return .{ .bytes = bytes };
    }

    pub fn byteLen(self: Utf8Text) usize {
        return self.bytes.len;
    }

    pub fn scalarCount(self: Utf8Text) usize {
        var count: usize = 0;
        for (self.bytes) |byte| if ((byte & 0xC0) != 0x80) {
            count += 1;
        };
        return count;
    }

    pub fn view(self: Utf8Text) abi.R4TextView {
        return textView(self.bytes);
    }
};

pub const UiText8 = struct {
    bytes: []const u8,

    pub fn init(bytes: []const u8) Error!UiText8 {
        for (bytes) |byte| {
            if ((byte >= 0x20 and byte <= 0x7E) or byte == '\t' or byte == '\r' or byte == '\n') continue;
            return Error.InvalidUiText8;
        }
        return .{ .bytes = bytes };
    }

    pub fn view(self: UiText8) abi.R4TextView {
        return textView(self.bytes);
    }
};

pub const SystemText = struct {
    content: []const u8,

    pub fn parse(bytes: []const u8) Error!SystemText {
        const content = stripBom(bytes);
        try validateUtf8(content);
        try validateLineEndings(content);
        return .{ .content = content };
    }

    pub fn canonicalSize(self: SystemText) usize {
        var size: usize = 3;
        var index: usize = 0;
        while (index < self.content.len) : (index += 1) {
            if (self.content[index] == '\r') {
                size += 2;
                index += 1;
            } else if (self.content[index] == '\n') {
                size += 2;
            } else {
                size += 1;
            }
        }
        return size;
    }

    pub fn writeCanonical(self: SystemText, out: []u8) Error![]const u8 {
        const required = self.canonicalSize();
        if (out.len < required) return Error.BufferTooSmall;
        @memcpy(out[0..3], utf8_bom);
        var pos: usize = 3;
        var index: usize = 0;
        while (index < self.content.len) : (index += 1) {
            const byte = self.content[index];
            if (byte == '\r') {
                out[pos] = '\r';
                out[pos + 1] = '\n';
                pos += 2;
                index += 1;
            } else if (byte == '\n') {
                out[pos] = '\r';
                out[pos + 1] = '\n';
                pos += 2;
            } else {
                out[pos] = byte;
                pos += 1;
            }
        }
        return out[0..pos];
    }
};

pub const DocumentText = struct {
    bytes: []const u8,
    encoding: Encoding,
    line_ending: LineEnding,

    pub fn init(bytes: []const u8) Error!DocumentText {
        const has_bom = startsWithBom(bytes);
        const content = if (has_bom) bytes[3..] else bytes;
        if (has_bom) try validateUtf8(content);
        const encoding: Encoding = if (has_bom)
            .utf8_bom
        else if (std.unicode.utf8ValidateSlice(content) and std.mem.indexOfScalar(u8, content, 0) == null)
            .utf8
        else
            .bytes;
        return .{ .bytes = bytes, .encoding = encoding, .line_ending = detectLineEnding(content) };
    }

    pub fn writeExact(self: DocumentText, out: []u8) Error![]const u8 {
        if (out.len < self.bytes.len) return Error.BufferTooSmall;
        @memcpy(out[0..self.bytes.len], self.bytes);
        return out[0..self.bytes.len];
    }
};

pub const utf8_bom = "\xEF\xBB\xBF";

pub fn textView(bytes: []const u8) abi.R4TextView {
    return .{
        .ptr = if (bytes.len == 0) null else bytes.ptr,
        .len = @intCast(bytes.len),
    };
}

pub fn validateUtf8(bytes: []const u8) Error!void {
    if (std.mem.indexOfScalar(u8, bytes, 0) != null) return Error.EmbeddedNul;
    if (!std.unicode.utf8ValidateSlice(bytes)) return Error.InvalidUtf8;
}

pub fn validateUiText8(bytes: []const u8) Error!void {
    _ = try UiText8.init(bytes);
}

fn startsWithBom(bytes: []const u8) bool {
    return bytes.len >= 3 and std.mem.eql(u8, bytes[0..3], utf8_bom);
}

fn stripBom(bytes: []const u8) []const u8 {
    return if (startsWithBom(bytes)) bytes[3..] else bytes;
}

fn validateLineEndings(bytes: []const u8) Error!void {
    var index: usize = 0;
    while (index < bytes.len) : (index += 1) {
        if (bytes[index] != '\r') continue;
        if (index + 1 >= bytes.len or bytes[index + 1] != '\n') return Error.InvalidLineEnding;
        index += 1;
    }
}

fn detectLineEnding(bytes: []const u8) LineEnding {
    var saw_lf = false;
    var saw_crlf = false;
    var index: usize = 0;
    while (index < bytes.len) : (index += 1) {
        if (bytes[index] == '\r' and index + 1 < bytes.len and bytes[index + 1] == '\n') {
            saw_crlf = true;
            index += 1;
        } else if (bytes[index] == '\n') {
            saw_lf = true;
        }
    }
    if (saw_lf and saw_crlf) return .mixed;
    if (saw_crlf) return .crlf;
    if (saw_lf) return .lf;
    return .none;
}

test "UTF-8 distinguishes bytes scalar count and embedded NUL" {
    const value = try Utf8Text.init("Gr\xC3\xBCn");
    try std.testing.expectEqual(@as(usize, 5), value.byteLen());
    try std.testing.expectEqual(@as(usize, 4), value.scalarCount());
    try std.testing.expectError(Error.InvalidUtf8, Utf8Text.init("\xC3\x28"));
    try std.testing.expectError(Error.EmbeddedNul, Utf8Text.init("A\x00B"));
}

test "SystemText accepts BOM LF and CRLF then writes canonical bytes" {
    const input = utf8_bom ++ "A\nB\r\n";
    const value = try SystemText.parse(input);
    var out: [32]u8 = .{0xCC} ** 32;
    const written = try value.writeCanonical(out[0..]);
    try std.testing.expectEqualStrings(utf8_bom ++ "A\r\nB\r\n", written);
    var tiny: [4]u8 = .{0xCC} ** 4;
    try std.testing.expectError(Error.BufferTooSmall, value.writeCanonical(tiny[0..]));
    try std.testing.expectEqualSlices(u8, &.{ 0xCC, 0xCC, 0xCC, 0xCC }, tiny[0..]);
}

test "DocumentText roundtrips bytes and UI text rejects non ASCII" {
    const original = "A\nB\r\n\xFF";
    const document = try DocumentText.init(original);
    try std.testing.expectEqual(Encoding.bytes, document.encoding);
    try std.testing.expectEqual(LineEnding.mixed, document.line_ending);
    var out: [16]u8 = undefined;
    try std.testing.expectEqualSlices(u8, original, try document.writeExact(out[0..]));
    _ = try UiText8.init("Menu\tCtrl+S\r\n");
    try std.testing.expectError(Error.InvalidUiText8, UiText8.init("Gr\xC3\xBCn"));
}
