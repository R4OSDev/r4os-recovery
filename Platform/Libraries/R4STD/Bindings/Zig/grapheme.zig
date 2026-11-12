//! Unicode 17.0.0, UAX #29 revision 47 default extended grapheme clusters.
//! Byte offsets only. No normalization, display-width, shaping or BiDi policy.
const std = @import("std");
const utf8 = @import("console_text.zig");
const data = @import("grapheme_properties.zig");
pub const unicode_version = "17.0.0";
pub const uax29_revision = 47;
pub const Error = utf8.Error;
const G = data.Gcb;
const I = data.Incb;

pub const State = struct {
    previous: ?G = null,
    ri_odd: bool = false,
    ep_extend: bool = false,
    zwj_after_ep: bool = false,
    indic: enum { none, consonant, linker } = .none,

    /// Valid Unicode scalar input. Returns whether a cluster starts before it.
    pub fn push(self: *State, scalar: u21) bool {
        const right = data.gcb(scalar);
        const incb = data.incb(scalar);
        const ep = data.extendedPictographic(scalar);
        const boundary = if (self.previous) |left| blk: {
            if (left == .CR and right == .LF) break :blk false; // GB3
            if (control(left) or control(right)) break :blk true; // GB4/5
            if (left == .L and (right == .L or right == .V or right == .LV or right == .LVT)) break :blk false;
            if ((left == .LV or left == .V) and (right == .V or right == .T)) break :blk false;
            if ((left == .LVT or left == .T) and right == .T) break :blk false;
            if (right == .Extend or right == .ZWJ or right == .SpacingMark or left == .Prepend) break :blk false;
            if (self.indic == .linker and incb == .Consonant) break :blk false; // GB9c
            if (self.zwj_after_ep and ep) break :blk false; // GB11
            if (left == .Regional_Indicator and right == .Regional_Indicator and self.ri_odd) break :blk false;
            break :blk true;
        } else true;
        self.zwj_after_ep = right == .ZWJ and self.ep_extend;
        self.ep_extend = ep or (right == .Extend and self.ep_extend);
        self.ri_odd = right == .Regional_Indicator and !self.ri_odd;
        self.indic = switch (incb) {
            .Consonant => .consonant,
            .Linker => if (self.indic != .none) .linker else .none,
            .Extend => self.indic,
            .None => .none,
        };
        self.previous = right;
        return boundary;
    }
    fn control(g: G) bool {
        return g == .CR or g == .LF or g == .Control;
    }
};
pub const Range = struct { start: usize, end: usize };
pub const Iterator = struct {
    bytes: []const u8,
    offset: usize = 0,
    state: State = .{},
    pub fn next(self: *Iterator) Error!?Range {
        if (self.offset == self.bytes.len) return null;
        const start = self.offset;
        while (self.offset < self.bytes.len) {
            const scalar = try utf8.decode(self.bytes[self.offset..]);
            var trial = self.state;
            if (trial.push(scalar.value) and self.offset != start) break;
            self.state = trial;
            self.offset += scalar.len;
        }
        return .{ .start = start, .end = self.offset };
    }
};
pub fn valid(bytes: []const u8) bool {
    var it = Iterator{ .bytes = bytes };
    while (it.next() catch return false) |_| {}
    return true;
}
/// Scan the complete input, including beyond capacity; invalid suffixes fail.
pub fn prefix(bytes: []const u8, capacity: usize) Error!usize {
    var it = Iterator{ .bytes = bytes };
    var end: usize = 0;
    while (try it.next()) |range| if (range.end <= capacity) {
        end = range.end;
    };
    return end;
}
pub fn floor(bytes: []const u8, index: usize) Error!usize {
    var it = Iterator{ .bytes = bytes };
    const target = @min(index, bytes.len);
    var result: usize = 0;
    while (try it.next()) |range| if (range.end <= target) {
        result = range.end;
    };
    return result;
}
pub fn ceil(bytes: []const u8, index: usize) Error!usize {
    var it = Iterator{ .bytes = bytes };
    const target = @min(index, bytes.len);
    var result: usize = bytes.len;
    if (target == 0) result = 0;
    while (try it.next()) |range| if (range.start < target and target <= range.end) {
        result = range.end;
    };
    return result;
}
pub fn previous(bytes: []const u8, index: usize) Error!usize {
    var it = Iterator{ .bytes = bytes };
    const target = @min(index, bytes.len);
    var result: usize = 0;
    while (try it.next()) |range| if (range.start < target) {
        result = range.start;
    };
    return result;
}
pub fn next(bytes: []const u8, index: usize) Error!usize {
    var it = Iterator{ .bytes = bytes };
    const target = @min(index, bytes.len);
    var result: usize = bytes.len;
    var found = false;
    while (try it.next()) |range| if (!found and range.end > target) {
        result = range.end;
        found = true;
    };
    return result;
}
/// The caller retains bytes. Events never imply that the current cluster has
/// ended; only the next break_before or a successful finish establishes that.
/// Thus arbitrarily long combining runs need no unbounded internal buffer.
pub const Stream = struct {
    state: State = .{},
    pending: [4]u8 = undefined,
    len: usize = 0,
    offset: usize = 0,
    failed: bool = false,
    pub const Event = struct { offset: usize, scalar: u21, byte_length: usize, break_before: bool };
    pub fn push(self: *Stream, byte: u8) Error!?Event {
        if (self.failed) return error.InvalidUtf8;
        self.pending[self.len] = byte;
        self.len += 1;
        const scalar = utf8.decode(self.pending[0..self.len]) catch |err| {
            if (err == error.Incomplete) return null;
            self.failed = true;
            return err;
        };
        const event = Event{ .offset = self.offset, .scalar = scalar.value, .byte_length = scalar.len, .break_before = self.state.push(scalar.value) };
        self.offset += scalar.len;
        self.len = 0;
        return event;
    }
    pub fn finish(self: *const Stream) Error!usize {
        if (self.failed) return error.InvalidUtf8;
        if (self.len != 0) return error.Incomplete;
        return self.offset;
    }
};

test "Unicode17 official extended grapheme vectors and byte-chunk stream boundaries" {
    const vectors = @embedFile("Data/GraphemeBreakTest.txt");
    var lines = std.mem.splitScalar(u8, vectors, '\n');
    var cases: usize = 0;
    while (lines.next()) |line| {
        const body = line[0 .. std.mem.indexOfScalar(u8, line, '#') orelse line.len];
        var tokens = std.mem.tokenizeAny(u8, body, " \t\r");
        var bytes: [512]u8 = undefined;
        var length: usize = 0;
        var expected: [512]bool = .{false} ** 512;
        var boundary = false;
        var scalars: usize = 0;
        while (tokens.next()) |token| {
            if (std.mem.eql(u8, token, "÷")) {
                boundary = true;
                continue;
            }
            if (std.mem.eql(u8, token, "×")) {
                boundary = false;
                continue;
            }
            const scalar = try std.fmt.parseInt(u21, token, 16);
            expected[length] = boundary;
            length += try std.unicode.utf8Encode(scalar, bytes[length..][0..4]);
            scalars += 1;
        }
        if (scalars == 0) continue;
        expected[length] = true;
        const input = bytes[0..length];
        var it = Iterator{ .bytes = input };
        var count: usize = 0;
        while (try it.next()) |range| {
            try std.testing.expect(expected[range.start] and expected[range.end]);
            count += 1;
        }
        var expected_count: usize = 0;
        for (expected[0..length]) |yes| if (yes) {
            expected_count += 1;
        };
        try std.testing.expectEqual(expected_count, count);
        // Every scalar and multibyte sequence is split across one-byte refills.
        var stream: Stream = .{};
        var events: usize = 0;
        for (input) |byte| if (try stream.push(byte)) |event| {
            try std.testing.expectEqual(expected[event.offset], event.break_before);
            events += 1;
        };
        try std.testing.expectEqual(scalars, events);
        try std.testing.expectEqual(length, try stream.finish());
        // Every capacity, including the middle of a scalar or cluster.
        var last: usize = 0;
        for (0..length + 1) |cap| {
            if (expected[cap]) last = cap;
            try std.testing.expectEqual(last, try prefix(input, cap));
            try std.testing.expectEqual(last, try floor(input, cap));
        }
        cases += 1;
    }
    try std.testing.expectEqual(@as(usize, 766), cases);
}
test "invalid complete input and incomplete stream never masquerade as safe prefixes" {
    try std.testing.expectError(error.InvalidUtf8, prefix("a\xe0\x80", 1));
    try std.testing.expectError(error.Incomplete, floor("a\xc3", 1));
    var stream: Stream = .{};
    try std.testing.expectEqual(@as(?Stream.Event, null), try stream.push(0xf0));
    try std.testing.expectError(error.Incomplete, stream.finish());
    try std.testing.expectError(error.InvalidUtf8, stream.push(0x80));
    try std.testing.expectError(error.InvalidUtf8, stream.push('a'));
    const accent = "a\u{301}";
    try std.testing.expectEqual(@as(usize, 0), try previous(accent, accent.len));
    try std.testing.expectEqual(accent.len, try next(accent, 0));
    try std.testing.expectEqual(accent.len, try ceil(accent, 1));
}
