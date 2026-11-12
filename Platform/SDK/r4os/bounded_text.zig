//! Caller-owned UTF8 UI buffer moves. No encoding guess, normalization,
//! glyph or display-width promise. Failed exact assignment changes no byte.
const std = @import("std");
const grapheme = @import("r4std_grapheme");

pub fn valid(value: []const u8) bool {
    return std.unicode.utf8ValidateSlice(value) and std.mem.indexOfScalar(u8, value, 0) == null;
}

pub fn assignZ(out: []u8, value: []const u8) bool {
    if (out.len == 0 or value.len >= out.len or !valid(value)) return false;
    copy(out[0..value.len], value);
    @memset(out[value.len..], 0);
    return true;
}

/// Presentation only: an overlong label gets a whole-grapheme prefix and ... .
/// Never use the result as a file identity or as editable input.
pub fn labelZ(out: []u8, value: []const u8) bool {
    if (out.len == 0 or !valid(value)) return false;
    if (value.len < out.len) return assignZ(out, value);
    const dots: usize = if (out.len >= 4) 3 else 0;
    const end = grapheme.prefix(value, out.len - 1 - dots) catch return false;
    copy(out[0..end], value[0..end]);
    @memset(out[end .. end + dots], '.');
    @memset(out[end + dots ..], 0);
    return true;
}

fn copy(out: []u8, value: []const u8) void {
    if (@intFromPtr(out.ptr) > @intFromPtr(value.ptr)) {
        std.mem.copyBackwards(u8, out, value);
    } else {
        std.mem.copyForwards(u8, out, value);
    }
}

test "bounded text exact values and presentation labels keep complete UTF8" {
    const value = "ä€🙂.txt";
    var storage: [32]u8 = undefined;
    for (0..storage.len + 1) |capacity| {
        @memset(&storage, 0xa5);
        const before = storage;
        const ok = assignZ(storage[0..capacity], value);
        try std.testing.expectEqual(capacity > value.len, ok);
        if (ok) {
            try std.testing.expectEqualStrings(value, std.mem.sliceTo(storage[0..capacity], 0));
        } else try std.testing.expectEqualSlices(u8, &before, &storage);
        @memset(&storage, 0xa5);
        const label_ok = labelZ(storage[0..capacity], value);
        try std.testing.expectEqual(capacity != 0, label_ok);
        if (label_ok) try std.testing.expect(valid(std.mem.sliceTo(storage[0..capacity], 0)));
        try std.testing.expectEqualSlices(u8, before[capacity..], storage[capacity..]);
    }
    for ([_][]const u8{ "\xc3", "\xc1\xa1", "\xed\xa0\x80", "\xf4\x90\x80\x80", "a\x00b" }) |bad| {
        @memset(&storage, 0xa5);
        const before = storage;
        try std.testing.expect(!assignZ(&storage, bad));
        try std.testing.expect(!labelZ(&storage, bad));
        try std.testing.expectEqualSlices(u8, &before, &storage);
    }
    try std.testing.expect(assignZ(&storage, value));
    try std.testing.expect(assignZ(&storage, std.mem.sliceTo(&storage, 0)));
    try std.testing.expectEqualStrings(value, std.mem.sliceTo(&storage, 0));
    try std.testing.expect(assignZ(storage[2..], storage[0..value.len]));
    try std.testing.expectEqualStrings(value, std.mem.sliceTo(storage[2..], 0));
}

/// A bounded file candidate may include one lookahead byte after capacity.
/// At a truncated tail only a boundary proved by the next complete scalar is
/// publishable. The open final cluster (also a split UTF8 scalar) is omitted.
/// Malformed complete prefixes fail; they never become a replacement document.
pub fn loadPrefix(value: []const u8, capacity: usize, truncated: bool) ?usize {
    var it = grapheme.Iterator{ .bytes = value };
    var end: usize = 0;
    while (it.next() catch |err| {
        if (truncated and err == error.Incomplete) return end;
        return null;
    }) |range| {
        if (range.end <= capacity and (!truncated or range.end < value.len)) end = range.end;
    }
    return end;
}

test "bounded text file candidate preserves clusters across 512 byte and capacity cuts" {
    const text = "x" ** 511 ++ "a\u{301}" ++ "z";
    try std.testing.expectEqual(@as(?usize, text.len), loadPrefix(text, text.len, false));
    try std.testing.expectEqual(@as(?usize, 511), loadPrefix(text[0..513], 512, true));
    try std.testing.expectEqual(@as(?usize, 511), loadPrefix(text[0..514], 513, true));
    try std.testing.expectEqual(@as(?usize, 514), loadPrefix(text, 514, true));
    try std.testing.expectEqual(@as(?usize, null), loadPrefix("x\xc3", 2, false));
    try std.testing.expectEqual(@as(?usize, null), loadPrefix("x\xe0\x80", 3, true));
}
