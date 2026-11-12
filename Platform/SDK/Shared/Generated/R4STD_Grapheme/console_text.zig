//! Allocation-free UTF-8 snapshot primitives. Console transcripts are canonical
//! UTF-8; font charset metadata never selects the transcript encoding.
const std = @import("std");

pub const Scalar = struct { value: u21, len: usize };
pub const Error = error{ InvalidUtf8, Incomplete };

pub fn decode(bytes: []const u8) Error!Scalar {
    if (bytes.len == 0) return error.Incomplete;
    const len = std.unicode.utf8ByteSequenceLength(bytes[0]) catch return error.InvalidUtf8;
    // Check every available prefix byte as well; an invalid prefix is not a
    // truncated valid scalar (E0 80, ED A0, F4 90, lone continuations, ...).
    const available = @min(bytes.len, len);
    for (bytes[1..available]) |byte| if (byte & 0xc0 != 0x80) return error.InvalidUtf8;
    if (available > 1 and ((bytes[0] == 0xe0 and bytes[1] < 0xa0) or
        (bytes[0] == 0xed and bytes[1] >= 0xa0) or
        (bytes[0] == 0xf0 and bytes[1] < 0x90) or
        (bytes[0] == 0xf4 and bytes[1] >= 0x90))) return error.InvalidUtf8;
    if (bytes.len < len) return error.Incomplete;
    return .{ .value = std.unicode.utf8Decode(bytes[0..len]) catch return error.InvalidUtf8, .len = len };
}

pub fn completePrefix(bytes: []const u8) usize {
    var offset: usize = 0;
    while (offset < bytes.len) {
        const scalar = decode(bytes[offset..]) catch break;
        offset += scalar.len;
    }
    return offset;
}

pub fn printable(scalar: u32) bool {
    return scalar >= 0x20 and scalar != 0x7f and !(scalar >= 0x80 and scalar <= 0x9f);
}

pub fn cells(bytes: []const u8) usize {
    var offset: usize = 0;
    var count: usize = 0;
    while (offset < bytes.len) {
        const scalar = decode(bytes[offset..]) catch break;
        offset += scalar.len;
        if (printable(scalar.value)) count += 1;
    }
    return count;
}

test "complete scalar prefixes and monospaced cells" {
    const text = "A\xc3\xbc\xe2\x94\x80\xf0\x9f\x98\x80";
    for (0..text.len + 1) |cap| {
        const end = completePrefix(text[0..cap]);
        try std.testing.expect(std.unicode.utf8ValidateSlice(text[0..end]));
    }
    try std.testing.expectEqual(@as(usize, 4), cells(text));
    try std.testing.expectEqual(@as(usize, 1), cells("A\r\n\xc2\x81"));
    try std.testing.expectError(error.Incomplete, decode("\xc3"));
    try std.testing.expectError(error.InvalidUtf8, decode("\xe0\x80"));
    try std.testing.expectError(error.InvalidUtf8, decode("\xed\xa0"));
    try std.testing.expectError(error.InvalidUtf8, decode("\xf4\x90"));
}
