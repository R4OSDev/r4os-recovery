//! Shared R4OS transport pathname policy. No normalization, OEM guessing,
//! collation or I/O; callers retain the exact admitted UTF8 bytes.
const std = @import("std");
const utf8 = @import("console_text.zig");
pub const component_utf16_units: usize = 255;

/// Strict complete UTF8 text, excluding NUL and ASCII protocol controls.
/// Incremental transports must retain their prefix until the complete record.
pub fn validText(bytes: []const u8) bool {
    var offset: usize = 0;
    while (offset < bytes.len) {
        const scalar = utf8.decode(bytes[offset..]) catch return false;
        if (scalar.value < 0x20 or scalar.value == 0x7f) return false;
        offset += scalar.len;
    }
    return true;
}
fn separator(byte: u8) bool { return byte == '/' or byte == '\\'; }
fn drivePrefix(path: []const u8) usize {
    var start: usize = 0;
    while (start < path.len and separator(path[start])) : (start += 1) {}
    if (path.len - start >= 2 and std.ascii.isAlphabetic(path[start]) and path[start + 1] == ':') return start + 2;
    return 0;
}
/// max_bytes comes from the consumer's actual path/ABI capacity, excluding NUL.
/// A drive prefix (C:, /C:) is syntax; all other colons are forbidden.
pub fn valid(path: []const u8, max_bytes: usize) bool {
    if (path.len > max_bytes or !validText(path)) return false;
    const prefix = drivePrefix(path);
    var offset = prefix;
    var units: usize = 0;
    while (offset < path.len) {
        const scalar = utf8.decode(path[offset..]) catch return false;
        if (scalar.value == '/' or scalar.value == '\\') {
            units = 0;
        } else {
            switch (scalar.value) { ':', '*', '?', '"', '<', '>', '|' => return false, else => {} }
            units += if (scalar.value > 0xffff) @as(usize, 2) else 1;
            if (units > component_utf16_units) return false;
        }
        offset += scalar.len;
    }
    return true;
}
pub fn validComponent(name: []const u8) bool {
    if (name.len == 0 or std.mem.indexOfAny(u8, name, "/\\:") != null or
        std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) return false;
    return valid(name, 3 * component_utf16_units);
}

test "raw transport paths reject malformed and forbidden input before canonicalization" {
    for ([_][]const u8{ "a\x00b", "a\rb", "a\nb", "a\tb", "a\x7fb", "\xc1\xa1", "\xe0\x80\xaf", "\xed\xa0\x80", "\xf4\x90\x80\x80", "x/\xc3/../ok", "x/\xc4", "x/y:z", "x/*", "x/?", "x/\"", "x/<", "x/>", "x/|" }) |bad| {
        try std.testing.expect(!valid(bad, 1023));
    }
    for ([_][]const u8{ "/", "C:", "C:ä", "/C:/ä/🙂", "/C/ä/🙂", "../é", "x/../y", " leading/trailing ", "e\xcc\x81", "é" }) |good| try std.testing.expect(valid(good, 1023));
    try std.testing.expect(!validComponent("C:foo"));
    try std.testing.expect(!validComponent(".."));
    try std.testing.expect(validComponent("ä-🙂.bin"));
    // No rewriting or Unicode normalization is performed by validation.
    try std.testing.expect(!std.mem.eql(u8, "e\xcc\x81", "é"));
}
test "transport byte capacity is distinct from UTF16 component budget" {
    const max_pair = "€" ** 253 ++ "🙂";
    try std.testing.expect(validComponent(max_pair)); // 763bytes,255units
    try std.testing.expect(!validComponent(max_pair ++ "x"));
    try std.testing.expect(valid("C:" ++ max_pair, 765));
    try std.testing.expect(!valid("C:" ++ max_pair, 764));
    const full = "x/" ** 384 ++ "y" ** 255;
    try std.testing.expectEqual(@as(usize, 1023), full.len);
    try std.testing.expect(valid(full, 1023));
    try std.testing.expect(!valid(full ++ "/", 1023));
    try std.testing.expect(!valid("a" ** 256 ++ "/../ok", 1023));
}
