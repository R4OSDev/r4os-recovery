const std = @import("std");
const abi = @import("r4os_contract").abi;

pub const Error = error{
    Empty,
    TooLong,
    ComponentTooLong,
    EmbeddedNul,
    InvalidCharacter,
    ExpectedAbsolute,
    ExpectedRelative,
    RootTraversal,
};

pub const file_path_max: usize = abi.file_path_max_bytes;
pub const component_max: usize = abi.fat_path_component_max_bytes;
pub const registry_path_max: usize = abi.registry_path_max_bytes;
/// Windows-parity character limits (0.60.19): paths count at most 260
/// characters including the drive root, components at most 255 characters.
/// The byte limits above are the UTF-8 (BMP) worst case of these character
/// limits; both are enforced, neither truncates.  NT long paths (\\?\) are
/// deliberately out of contract.
pub const file_path_max_chars: usize = abi.file_path_max_chars;
pub const component_max_chars: usize = abi.path_component_max_chars;
pub const path_rollback_entries: usize = 160;
pub const path_rollback_storage_bytes: usize = 2 * path_rollback_entries * @sizeOf(u16);

pub const PathZ = struct {
    ptr: [*:0]const u8,
    len: u16,

    pub fn bytes(self: PathZ) []const u8 {
        return self.ptr[0..self.len];
    }
};

pub const FilePath = struct {
    storage: [file_path_max + 1:0]u8 = .{0} ** (file_path_max + 1),
    len: u16 = 0,
    absolute: bool = false,

    pub fn parse(input: []const u8) Error!FilePath {
        var result: FilePath = undefined;
        const normalized = try normalizeFile(input, null, &result.storage);
        result.len = @intCast(normalized.len);
        result.absolute = normalized.absolute;
        return result;
    }

    pub fn bytes(self: *const FilePath) []const u8 {
        return self.storage[0..self.len];
    }

    pub fn asZ(self: *const FilePath) PathZ {
        return .{ .ptr = @ptrCast(&self.storage), .len = self.len };
    }
};

pub const AbsoluteFilePath = struct {
    storage: [file_path_max + 1:0]u8 = .{0} ** (file_path_max + 1),
    len: u16 = 0,

    pub fn parse(input: []const u8) Error!AbsoluteFilePath {
        var result: AbsoluteFilePath = undefined;
        const normalized = try normalizeFile(input, true, &result.storage);
        result.len = @intCast(normalized.len);
        return result;
    }

    pub fn bytes(self: *const AbsoluteFilePath) []const u8 {
        return self.storage[0..self.len];
    }

    pub fn asZ(self: *const AbsoluteFilePath) PathZ {
        return .{ .ptr = @ptrCast(&self.storage), .len = self.len };
    }
};

pub const RelativeFilePath = struct {
    storage: [file_path_max + 1:0]u8 = .{0} ** (file_path_max + 1),
    len: u16 = 0,

    pub fn parse(input: []const u8) Error!RelativeFilePath {
        var result: RelativeFilePath = undefined;
        const normalized = try normalizeFile(input, false, &result.storage);
        result.len = @intCast(normalized.len);
        return result;
    }

    pub fn bytes(self: *const RelativeFilePath) []const u8 {
        return self.storage[0..self.len];
    }

    pub fn asZ(self: *const RelativeFilePath) PathZ {
        return .{ .ptr = @ptrCast(&self.storage), .len = self.len };
    }
};

pub const RegistryPath = struct {
    storage: [registry_path_max + 1:0]u8 = .{0} ** (registry_path_max + 1),
    len: u16 = 0,

    pub fn parse(input: []const u8) Error!RegistryPath {
        if (input.len == 0) return Error.Empty;
        if (input.len > registry_path_max) return Error.TooLong;
        var result: RegistryPath = undefined;
        var pos: usize = 0;
        var previous_separator = false;
        for (input) |raw| {
            if (raw == 0) return Error.EmbeddedNul;
            if (raw < 0x20 or raw == 0x7F) return Error.InvalidCharacter;
            const separator = raw == '\\' or raw == '/';
            if (separator) {
                if (pos == 0 or previous_separator) continue;
                result.storage[pos] = '\\';
                pos += 1;
                previous_separator = true;
            } else {
                result.storage[pos] = raw;
                pos += 1;
                previous_separator = false;
            }
        }
        while (pos > 0 and result.storage[pos - 1] == '\\') pos -= 1;
        if (pos == 0) return Error.Empty;
        result.storage[pos] = 0;
        result.len = @intCast(pos);
        return result;
    }

    pub fn bytes(self: *const RegistryPath) []const u8 {
        return self.storage[0..self.len];
    }

    pub fn asZ(self: *const RegistryPath) PathZ {
        return .{ .ptr = @ptrCast(&self.storage), .len = self.len };
    }
};

pub fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| if (asciiUpper(left) != asciiUpper(right)) return false;
    return true;
}

const Normalized = struct { len: usize, absolute: bool };

fn normalizeFile(input: []const u8, require_absolute: ?bool, out: *[file_path_max + 1:0]u8) Error!Normalized {
    if (input.len == 0) return Error.Empty;
    if (input.len > file_path_max) return Error.TooLong;

    const absolute = input.len >= 3 and isAsciiAlpha(input[0]) and input[1] == ':' and isSeparator(input[2]);
    if (require_absolute) |required| {
        if (required and !absolute) return Error.ExpectedAbsolute;
        if (!required and absolute) return Error.ExpectedRelative;
    }
    if (!absolute and isSeparator(input[0])) return Error.ExpectedAbsolute;

    var pos: usize = 0;
    var index: usize = 0;
    if (absolute) {
        out[0] = asciiUpper(input[0]);
        out[1] = ':';
        out[2] = '\\';
        pos = 3;
        index = 3;
    }

    // Byte position AND character count run in parallel: the canonical path
    // may use at most file_path_max bytes and file_path_max_chars characters
    // (drive root `X:\` counts three), each component at most component_max
    // bytes and component_max_chars characters.  Nothing truncates.
    var segment_starts: [path_rollback_entries]u16 = undefined;
    var segment_char_starts: [path_rollback_entries]u16 = undefined;
    var segment_count: usize = 0;
    var chars: usize = if (absolute) 3 else 0;
    while (index < input.len) {
        while (index < input.len and isSeparator(input[index])) : (index += 1) {}
        if (index >= input.len) break;
        const start = index;
        while (index < input.len and !isSeparator(input[index])) : (index += 1) {}
        const segment = input[start..index];
        if (std.mem.eql(u8, segment, ".")) continue;
        if (std.mem.eql(u8, segment, "..")) {
            if (segment_count == 0) return Error.RootTraversal;
            segment_count -= 1;
            pos = segment_starts[segment_count];
            chars = segment_char_starts[segment_count];
            if (absolute and pos == 2) pos = 3;
            if (absolute and chars < 3) chars = 3;
            continue;
        }
        if (segment.len > component_max) return Error.ComponentTooLong;
        const segment_chars = try validateFileSegment(segment);
        if (segment_chars > component_max_chars) return Error.ComponentTooLong;
        if (segment_count >= segment_starts.len) return Error.TooLong;
        const before = pos;
        const before_chars = chars;
        if ((absolute and pos > 3) or (!absolute and pos > 0)) {
            if (pos >= file_path_max) return Error.TooLong;
            out[pos] = '\\';
            pos += 1;
            chars += 1;
        }
        segment_starts[segment_count] = @intCast(before);
        segment_char_starts[segment_count] = @intCast(before_chars);
        segment_count += 1;
        if (segment.len > file_path_max - pos) return Error.TooLong;
        chars += segment_chars;
        if (chars > file_path_max_chars) return Error.TooLong;
        @memcpy(out[pos .. pos + segment.len], segment);
        pos += segment.len;
    }

    if (!absolute and pos == 0) {
        out[0] = '.';
        pos = 1;
    }
    out[pos] = 0;
    return .{ .len = pos, .absolute = absolute };
}

fn validateFileByte(byte: u8) Error!void {
    if (byte == 0) return Error.EmbeddedNul;
    if (byte < 0x20 or byte == 0x7F) return Error.InvalidCharacter;
    if (byte == '<' or byte == '>' or byte == '"' or byte == '|' or byte == '?' or byte == '*' or byte == ':') return Error.InvalidCharacter;
}

/// Component validation since 0.60.18: UTF-8 restricted to the BMP.
/// ASCII keeps the reserved-character rules; multi-byte sequences must be
/// well-formed 2- or 3-byte UTF-8 without overlong forms or surrogates.
/// 4-byte sequences (non-BMP) and malformed bytes are visible errors, no
/// silent replacement.  Returns the CHARACTER count of the segment for the
/// Windows-parity character limits (0.60.19).
fn validateFileSegment(segment: []const u8) Error!usize {
    var i: usize = 0;
    var chars: usize = 0;
    while (i < segment.len) {
        const byte = segment[i];
        if (byte < 0x80) {
            try validateFileByte(byte);
            i += 1;
            chars += 1;
            continue;
        }
        if (byte & 0xE0 == 0xC0) {
            if (byte < 0xC2) return Error.InvalidCharacter; // overlong
            if (i + 1 >= segment.len or segment[i + 1] & 0xC0 != 0x80) return Error.InvalidCharacter;
            i += 2;
            chars += 1;
            continue;
        }
        if (byte & 0xF0 == 0xE0) {
            if (i + 2 >= segment.len) return Error.InvalidCharacter;
            const b1 = segment[i + 1];
            const b2 = segment[i + 2];
            if (b1 & 0xC0 != 0x80 or b2 & 0xC0 != 0x80) return Error.InvalidCharacter;
            if (byte == 0xE0 and b1 < 0xA0) return Error.InvalidCharacter; // overlong
            if (byte == 0xED and b1 >= 0xA0) return Error.InvalidCharacter; // surrogate
            i += 3;
            chars += 1;
            continue;
        }
        // Stray continuation byte or 4-byte lead (outside the BMP).
        return Error.InvalidCharacter;
    }
    return chars;
}

fn isSeparator(byte: u8) bool {
    return byte == '\\' or byte == '/';
}

fn isAsciiAlpha(byte: u8) bool {
    const upper = asciiUpper(byte);
    return upper >= 'A' and upper <= 'Z';
}

fn asciiUpper(byte: u8) u8 {
    return if (byte >= 'a' and byte <= 'z') byte - 32 else byte;
}

test "absolute and relative paths normalize separators and dot segments" {
    const absolute = try AbsoluteFilePath.parse("c:/R4OS//CONFIG/./APPS/../TIME.R4S");
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\TIME.R4S", absolute.bytes());
    const relative = try RelativeFilePath.parse("docs/./api/../README.TXT");
    try std.testing.expectEqualStrings("docs\\README.TXT", relative.bytes());
    try std.testing.expectError(Error.RootTraversal, AbsoluteFilePath.parse("C:\\..\\BOOT.R4S"));
    try std.testing.expectError(Error.RootTraversal, RelativeFilePath.parse("..\\BOOT.R4S"));
}

test "normalization writes only its canonical prefix and uses compact rollback offsets" {
    try std.testing.expectEqual(@as(usize, 640), path_rollback_storage_bytes);
    var storage: [file_path_max + 1:0]u8 = .{0xA5} ** (file_path_max + 1);
    const normalized = try normalizeFile("C:/TEMP/../CONFIG/VERSION.R4S", true, &storage);
    try std.testing.expectEqualStrings("C:\\CONFIG\\VERSION.R4S", storage[0..normalized.len]);
    try std.testing.expectEqual(@as(u8, 0), storage[normalized.len]);
    try std.testing.expectEqual(@as(u8, 0xA5), storage[normalized.len + 1]);
}

test "windows-parity character boundaries reject without truncation" {
    // Component: exactly 255 characters pass, 256 fail.
    var comp_255: [255]u8 = .{'A'} ** 255;
    _ = try RelativeFilePath.parse(comp_255[0..]);
    var comp_256: [256]u8 = .{'A'} ** 256;
    try std.testing.expectError(Error.ComponentTooLong, RelativeFilePath.parse(comp_256[0..]));

    // Path: exactly 260 characters (C:\ + 255 + \ + 1) pass, 261 fail.
    var path_260: [260]u8 = undefined;
    path_260[0] = 'C';
    path_260[1] = ':';
    path_260[2] = '\\';
    @memset(path_260[3..258], 'A');
    path_260[258] = '\\';
    path_260[259] = 'B';
    _ = try AbsoluteFilePath.parse(path_260[0..]);
    var path_261: [261]u8 = undefined;
    @memcpy(path_261[0..259], path_260[0..259]);
    path_261[259] = 'B';
    path_261[260] = 'B';
    try std.testing.expectError(Error.TooLong, AbsoluteFilePath.parse(path_261[0..]));

    // Character limits count characters, not bytes: 255 two-byte umlauts
    // (510 bytes) stay a valid component.
    var umlaut_255: [510]u8 = undefined;
    var i: usize = 0;
    while (i < 510) : (i += 2) {
        umlaut_255[i] = 0xC3;
        umlaut_255[i + 1] = 0xA4; // ä
    }
    _ = try RelativeFilePath.parse(umlaut_255[0..]);
    var umlaut_256: [512]u8 = undefined;
    @memcpy(umlaut_256[0..510], umlaut_255[0..]);
    umlaut_256[510] = 0xC3;
    umlaut_256[511] = 0xA4;
    try std.testing.expectError(Error.ComponentTooLong, RelativeFilePath.parse(umlaut_256[0..]));

    try std.testing.expectError(Error.EmbeddedNul, FilePath.parse("C:\\A\x00B"));
    try std.testing.expectError(Error.InvalidCharacter, FilePath.parse("C:\\A?B"));
}

test "utf8 bmp components pass while malformed and non-bmp stay errors" {
    const umlaut = try FilePath.parse("C:\\Gr\xC3\xBCn.txt");
    try std.testing.expectEqualStrings("C:\\Gr\xC3\xBCn.txt", umlaut.bytes());
    const nested = try RelativeFilePath.parse("Namen mit Umlauten/\xC3\x84rger.md");
    try std.testing.expectEqualStrings("Namen mit Umlauten\\\xC3\x84rger.md", nested.bytes());
    // Malformed continuation, overlong form, surrogate half, non-BMP emoji.
    try std.testing.expectError(Error.InvalidCharacter, FilePath.parse("C:\\Gr\xC3\x28.txt"));
    try std.testing.expectError(Error.InvalidCharacter, FilePath.parse("C:\\A\xC0\xAF.txt"));
    try std.testing.expectError(Error.InvalidCharacter, FilePath.parse("C:\\A\xED\xA0\x80.txt"));
    try std.testing.expectError(Error.InvalidCharacter, FilePath.parse("C:\\A\xF0\x9F\x98\x80.txt"));
    // A stray continuation byte alone is malformed.
    try std.testing.expectError(Error.InvalidCharacter, FilePath.parse("C:\\A\xBFB.txt"));
}

test "drive roots registry paths and ASCII case comparison remain distinct" {
    const root = try AbsoluteFilePath.parse("c:/");
    try std.testing.expectEqualStrings("C:\\", root.bytes());
    const registry = try RegistryPath.parse("SYSTEM//Shell\\RecentDocuments");
    try std.testing.expectEqualStrings("SYSTEM\\Shell\\RecentDocuments", registry.bytes());
    try std.testing.expect(equalsIgnoreCase("C:\\Temp\\A.TXT", "c:\\temp\\a.txt"));
}
