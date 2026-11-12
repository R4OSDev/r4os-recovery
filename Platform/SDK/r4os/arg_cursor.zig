//! R4OS UTF8 argument grammar; explicit quoting/switch policy, no host argv.
//! Caller retains immutable UTF8 input. Offsets are bytes of that same input.
const std = @import("std");
pub const Error = error{ InvalidPolicy, TooLong, InvalidEncoding, InvalidText, UnclosedQuote, InvalidQuote, InvalidState, LengthOverflow };
pub const Quotes = enum(u32) { none = 0, full_token = 1 };
pub const slash: u32 = 1;
pub const dash: u32 = 2;
pub const Policy = extern struct {
    quotes: u32 = 1,
    switches: u32 = slash,
    max_bytes: usize = 4096,
    fn valid(self: Policy) bool {
        return self.quotes <= 1 and self.switches & ~(slash | dash) == 0;
    }
};
pub const Failure = extern struct { code: i32 = 0, reserved: u32 = 0, offset: usize = 0 };
pub fn code(err: Error) i32 {
    return switch (err) {
        error.InvalidPolicy => -1,
        error.TooLong => -2,
        error.InvalidEncoding => -3,
        error.InvalidText => -4,
        error.UnclosedQuote => -5,
        error.InvalidQuote => -6,
        error.InvalidState => -7,
        error.LengthOverflow => -8,
    };
}
fn decode(value: i32) Error {
    return switch (value) {
        -1 => error.InvalidPolicy,
        -2 => error.TooLong,
        -3 => error.InvalidEncoding,
        -4 => error.InvalidText,
        -5 => error.UnclosedQuote,
        -6 => error.InvalidQuote,
        -8 => error.LengthOverflow,
        else => error.InvalidState,
    };
}
fn space(byte: u8) bool {
    return byte == ' ' or byte == '\t';
}
fn reject(failure: *Failure, err: Error, offset: usize) Error {
    failure.* = .{ .code = code(err), .offset = offset };
    return err;
}
pub const Switch = struct { name: []const u8, value: ?[]const u8 };
pub const Token = extern struct {
    raw_start: usize,
    raw_end: usize,
    value_start: usize,
    value_end: usize,
    flags: u32,
    switch_prefix: u32,
    pub fn bytes(self: Token, raw: []const u8) Error![]const u8 {
        if (self.raw_start > self.value_start or self.value_start > self.value_end or self.value_end > self.raw_end or self.raw_end > raw.len) return error.InvalidState;
        return raw[self.value_start..self.value_end];
    }
    pub fn quoted(self: Token) bool {
        return self.flags & 1 != 0;
    }
    /// Lexical switch policy, not a path classifier or option consumer.
    pub fn switchParts(self: Token, raw: []const u8) Error!?Switch {
        if (self.quoted() or self.switch_prefix == 0) return null;
        const value = try self.bytes(raw);
        if (value.len < 2 or (self.switch_prefix == slash and value[0] != '/') or (self.switch_prefix == dash and value[0] != '-') or self.switch_prefix > dash) return error.InvalidState;
        const colon = std.mem.indexOfScalar(u8, value, ':');
        return .{ .name = value[1..(colon orelse value.len)], .value = if (colon) |at| value[at + 1 ..] else null };
    }
    pub fn switchIs(self: Token, raw: []const u8, name: []const u8) Error!bool {
        const parts = (try self.switchParts(raw)) orelse return false;
        return std.ascii.eqlIgnoreCase(parts.name, name);
    }
};
pub const ArgCursor = extern struct {
    address: usize = 0,
    length: usize = 0,
    position: usize = 0,
    policy: Policy = .{},
    state: u32 = 0, // active0, end1, sticky parse failure2
    error_code: i32 = 0,
    error_offset: usize = 0,
    pub fn init(raw: []const u8, policy: Policy, out_failure: *Failure) Error!ArgCursor {
        out_failure.* = .{};
        if (!policy.valid()) return reject(out_failure, error.InvalidPolicy, 0);
        if (raw.len > policy.max_bytes) return reject(out_failure, error.TooLong, policy.max_bytes);
        _ = std.math.add(usize, @intFromPtr(raw.ptr), raw.len) catch return reject(out_failure, error.LengthOverflow, 0);
        var i: usize = 0;
        while (i < raw.len) {
            const first = raw[i];
            if ((first < 0x20 and first != '\t') or first == 0x7f) return reject(out_failure, error.InvalidText, i);
            const width = std.unicode.utf8ByteSequenceLength(first) catch return reject(out_failure, error.InvalidEncoding, i);
            if (width > raw.len - i) return reject(out_failure, error.InvalidEncoding, i);
            _ = std.unicode.utf8Decode(raw[i..][0..width]) catch return reject(out_failure, error.InvalidEncoding, i);
            i += width;
        }
        return .{ .address = @intFromPtr(raw.ptr), .length = raw.len, .policy = policy };
    }
    fn inputBytes(self: *const ArgCursor) Error![]const u8 {
        if (!self.policy.valid() or self.length > self.policy.max_bytes or self.position > self.length or self.state > 2 or (self.length != 0 and self.address == 0)) return error.InvalidState;
        _ = std.math.add(usize, self.address, self.length) catch return error.LengthOverflow;
        if (self.length == 0) return &.{};
        return @as([*]const u8, @ptrFromInt(self.address))[0..self.length];
    }
    fn fail(self: *ArgCursor, err: Error, offset: usize) Error {
        self.state = 2;
        self.error_code = code(err);
        self.error_offset = offset;
        return err;
    }
    pub fn failure(self: *const ArgCursor) Failure {
        return .{ .code = self.error_code, .offset = self.error_offset };
    }
    /// Full immutable input loan; no decoded argv allocation or normalization.
    pub fn sourceBytes(self: *const ArgCursor) Error![]const u8 {
        return self.inputBytes();
    }
    pub fn next(self: *ArgCursor) Error!?Token {
        const input = try self.inputBytes();
        if (self.state == 1) return null;
        if (self.state == 2) return decode(self.error_code);
        var begin = self.position;
        while (begin < input.len and space(input[begin])) : (begin += 1) {}
        if (begin == input.len) {
            self.position = input.len;
            self.state = 1;
            return null;
        }
        const is_quoted = self.policy.quotes == 1 and input[begin] == '"';
        const value_begin = begin + @intFromBool(is_quoted);
        var value_end = value_begin;
        var raw_end: usize = undefined;
        if (is_quoted) {
            while (value_end < input.len and input[value_end] != '"') : (value_end += 1) {}
            if (value_end == input.len) return self.fail(error.UnclosedQuote, begin);
            raw_end = value_end + 1;
            if (raw_end < input.len and !space(input[raw_end])) return self.fail(error.InvalidQuote, raw_end);
        } else {
            while (value_end < input.len and !space(input[value_end])) : (value_end += 1) {
                if (self.policy.quotes == 1 and input[value_end] == '"') return self.fail(error.InvalidQuote, value_end);
            }
            raw_end = value_end;
        }
        const prefix: u32 = if (is_quoted or value_end - value_begin < 2) 0 else if (input[value_begin] == '/' and self.policy.switches & slash != 0) slash else if (input[value_begin] == '-' and self.policy.switches & dash != 0) dash else 0;
        self.position = raw_end;
        return .{ .raw_start = begin, .raw_end = raw_end, .value_start = value_begin, .value_end = value_end, .flags = @as(u32, @intFromBool(is_quoted)) | (if (prefix != 0) @as(u32, 2) else 0), .switch_prefix = prefix };
    }
    /// Exact suffix: delimiters, quotes and trailing bytes remain unchanged.
    pub fn remainingRaw(self: *const ArgCursor) Error![]const u8 {
        return (try self.inputBytes())[self.position..];
    }
    /// Explicit delegation policy, only leading ASCII space/tab removed.
    pub fn remainingArguments(self: *const ArgCursor) Error![]const u8 {
        return std.mem.trimStart(u8, try self.remainingRaw(), " \t");
    }
};

test "cli owner argument UTF8 quotes empty switches exact delegated tail" {
    const input = " \t/JSON \"Grüße Welt\" \"\" C:\\a  /WAIT:3  ";
    var failure: Failure = .{};
    var cursor = try ArgCursor.init(input, .{ .switches = slash | dash }, &failure);
    const first = (try cursor.next()).?;
    try std.testing.expect(try first.switchIs(input, "json"));
    try std.testing.expectEqualStrings(" \"Grüße Welt\" \"\" C:\\a  /WAIT:3  ", try cursor.remainingRaw());
    try std.testing.expectEqualStrings("\"Grüße Welt\" \"\" C:\\a  /WAIT:3  ", try cursor.remainingArguments());
    const quoted = (try cursor.next()).?;
    try std.testing.expect(quoted.quoted());
    try std.testing.expectEqualStrings("Grüße Welt", try quoted.bytes(input));
    try std.testing.expectEqualStrings("", try (try cursor.next()).?.bytes(input));
    try std.testing.expectEqualStrings("C:\\a", try (try cursor.next()).?.bytes(input));
    const wait = (try cursor.next()).?;
    const parts = (try wait.switchParts(input)).?;
    try std.testing.expectEqualStrings("WAIT", parts.name);
    try std.testing.expectEqualStrings("3", parts.value.?);
    try std.testing.expectEqualStrings("  ", try cursor.remainingRaw());
    try std.testing.expectEqual(@as(?Token, null), try cursor.next());
    try std.testing.expectEqual(@as(?Token, null), try cursor.next());
    const operand = "\"/JSON\"";
    cursor = try ArgCursor.init(operand, .{}, &failure);
    try std.testing.expect(!try (try cursor.next()).?.switchIs(operand, "JSON"));
}
test "cli owner argument exact sticky failure offsets and explicit noquotes" {
    var failure: Failure = .{};
    var cursor = try ArgCursor.init("one \"unterminated", .{}, &failure);
    _ = try cursor.next();
    try std.testing.expectError(error.UnclosedQuote, cursor.next());
    try std.testing.expectEqual(@as(usize, 4), cursor.failure().offset);
    try std.testing.expectEqual(@as(usize, 3), cursor.position);
    try std.testing.expectError(error.UnclosedQuote, cursor.next());
    cursor = try ArgCursor.init("\"a\"b", .{}, &failure);
    try std.testing.expectError(error.InvalidQuote, cursor.next());
    try std.testing.expectEqual(@as(usize, 3), cursor.failure().offset);
    cursor = try ArgCursor.init("a\"b", .{}, &failure);
    try std.testing.expectError(error.InvalidQuote, cursor.next());
    try std.testing.expectEqual(@as(usize, 1), cursor.failure().offset);
    try std.testing.expectError(error.InvalidEncoding, ArgCursor.init("a\xff", .{}, &failure));
    try std.testing.expectEqual(@as(usize, 1), failure.offset);
    try std.testing.expectError(error.InvalidText, ArgCursor.init("a\n", .{}, &failure));
    try std.testing.expectEqual(@as(usize, 1), failure.offset);
    try std.testing.expectError(error.TooLong, ArgCursor.init("abc", .{ .max_bytes = 2 }, &failure));
    try std.testing.expectEqual(@as(usize, 2), failure.offset);
    const simple = " a \"two words\" ";
    cursor = try ArgCursor.init(simple, .{ .quotes = 0 }, &failure);
    for ([_][]const u8{ "a", "\"two", "words\"" }) |expected| try std.testing.expectEqualStrings(expected, try (try cursor.next()).?.bytes(simple));
}
