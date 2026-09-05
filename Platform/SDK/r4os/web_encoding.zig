const std = @import("std");

pub const max_input_bytes: usize = 128 * 1024;
pub const max_output_bytes: usize = max_input_bytes * 3 + 3;

pub const Error = error{
    UnknownEncoding,
    InvalidSequence,
    InputTooLarge,
    OutputTooSmall,
};

pub const Encoding = enum {
    utf8,
    windows_1252,

    pub fn name(self: Encoding) []const u8 {
        return switch (self) {
            .utf8 => "utf-8",
            .windows_1252 => "windows-1252",
        };
    }
};

pub fn parseLabel(label: []const u8) Error!Encoding {
    const value = std.mem.trim(u8, label, "\t\n\r\x0c ");
    const utf8_labels = [_][]const u8{
        "unicode-1-1-utf-8", "unicode11utf8", "unicode20utf8", "utf-8", "utf8", "x-unicode20utf8",
    };
    for (utf8_labels) |candidate| if (std.ascii.eqlIgnoreCase(value, candidate)) return .utf8;
    const windows_labels = [_][]const u8{
        "windows-1252", "cp1252",         "x-cp1252",        "iso-8859-1",  "iso8859-1",
        "iso88591",     "iso_8859-1",     "iso_8859-1:1987", "iso-ir-100",  "latin1",
        "l1",           "ibm819",         "cp819",           "csisolatin1", "ascii",
        "us-ascii",     "ansi_x3.4-1968",
    };
    for (windows_labels) |candidate| if (std.ascii.eqlIgnoreCase(value, candidate)) return .windows_1252;
    return error.UnknownEncoding;
}

pub const EncodeIntoResult = struct {
    read: usize,
    written: usize,
};

pub fn encodeInto(source: []const u8, destination: []u8) EncodeIntoResult {
    var cursor: usize = 0;
    var written: usize = 0;
    var read: usize = 0;
    while (cursor < source.len) {
        const sequence_length: usize = std.unicode.utf8ByteSequenceLength(source[cursor]) catch 1;
        const available = @min(sequence_length, source.len - cursor);
        if (written + available > destination.len) break;
        @memcpy(destination[written .. written + available], source[cursor .. cursor + available]);
        const codepoint = std.unicode.utf8Decode(source[cursor .. cursor + available]) catch 0xfffd;
        read += if (codepoint > 0xffff) 2 else 1;
        written += available;
        cursor += available;
    }
    return .{ .read = read, .written = written };
}

pub const Decoder = struct {
    encoding: Encoding,
    fatal: bool = false,
    ignore_bom: bool = false,
    streaming: bool = false,
    bom_seen: bool = false,
    pending: [4]u8 = undefined,
    pending_len: usize = 0,

    pub fn init(encoding: Encoding, fatal: bool, ignore_bom: bool) Decoder {
        return .{ .encoding = encoding, .fatal = fatal, .ignore_bom = ignore_bom };
    }

    pub fn packState(self: *const Decoder) u64 {
        var value: u64 = @intFromEnum(self.encoding);
        if (self.fatal) value |= 1 << 1;
        if (self.ignore_bom) value |= 1 << 2;
        if (self.streaming) value |= 1 << 3;
        if (self.bom_seen) value |= 1 << 4;
        value |= @as(u64, self.pending_len) << 5;
        for (0..self.pending_len) |index| value |= @as(u64, self.pending[index]) << @intCast(8 + index * 8);
        return value;
    }

    pub fn fromPackedState(value: u64) Decoder {
        var decoder = Decoder.init(if ((value & 1) == 0) .utf8 else .windows_1252, (value & (1 << 1)) != 0, (value & (1 << 2)) != 0);
        decoder.streaming = (value & (1 << 3)) != 0;
        decoder.bom_seen = (value & (1 << 4)) != 0;
        decoder.pending_len = @min(@as(usize, @intCast((value >> 5) & 7)), decoder.pending.len);
        for (0..decoder.pending_len) |index| decoder.pending[index] = @truncate(value >> @intCast(8 + index * 8));
        return decoder;
    }

    pub fn decode(self: *Decoder, input: []const u8, output: []u8, stream: bool) Error![]const u8 {
        if (input.len > max_input_bytes) return error.InputTooLarge;
        if (!self.streaming) {
            self.pending_len = 0;
            self.bom_seen = false;
        }
        self.streaming = stream;
        var output_len: usize = 0;
        const decode_result = switch (self.encoding) {
            .utf8 => self.decodeUtf8(input, output, &output_len, stream),
            .windows_1252 => self.decodeWindows1252(input, output, &output_len),
        };
        decode_result catch |err| {
            if (err == error.InvalidSequence) {
                self.streaming = false;
                self.bom_seen = false;
                self.pending_len = 0;
            }
            return err;
        };
        if (!stream) {
            if (self.pending_len != 0) {
                try self.invalid(output, &output_len);
                self.pending_len = 0;
            }
            self.streaming = false;
        }
        return output[0..output_len];
    }

    fn decodeUtf8(self: *Decoder, input: []const u8, output: []u8, output_len: *usize, stream: bool) Error!void {
        var cursor: usize = 0;
        if (self.pending_len != 0) {
            const expected: usize = std.unicode.utf8ByteSequenceLength(self.pending[0]) catch 1;
            while (self.pending_len < expected and cursor < input.len) {
                const byte = input[cursor];
                if ((byte & 0xc0) != 0x80) {
                    try self.invalid(output, output_len);
                    self.pending_len = 0;
                    break;
                }
                self.pending[self.pending_len] = byte;
                self.pending_len += 1;
                cursor += 1;
            }
            if (self.pending_len == expected) {
                const codepoint = std.unicode.utf8Decode(self.pending[0..expected]) catch {
                    try self.invalid(output, output_len);
                    self.pending_len = 0;
                    return self.decodeUtf8(input[cursor..], output, output_len, stream);
                };
                try self.appendCodepoint(codepoint, self.pending[0..expected], output, output_len);
                self.pending_len = 0;
            } else if (self.pending_len != 0) {
                return;
            }
        }

        while (cursor < input.len) {
            const first = input[cursor];
            const sequence_length: usize = std.unicode.utf8ByteSequenceLength(first) catch {
                try self.invalid(output, output_len);
                cursor += 1;
                continue;
            };
            if (cursor + sequence_length > input.len) {
                if (!validUtf8Prefix(input[cursor..])) {
                    try self.invalid(output, output_len);
                    cursor += 1;
                    continue;
                }
                if (stream) {
                    const remaining = input.len - cursor;
                    @memcpy(self.pending[0..remaining], input[cursor..]);
                    self.pending_len = remaining;
                    return;
                }
                try self.invalid(output, output_len);
                cursor = input.len;
                continue;
            }
            const sequence = input[cursor .. cursor + sequence_length];
            const codepoint = std.unicode.utf8Decode(sequence) catch {
                try self.invalid(output, output_len);
                cursor += 1;
                continue;
            };
            try self.appendCodepoint(codepoint, sequence, output, output_len);
            cursor += sequence_length;
        }
    }

    fn decodeWindows1252(self: *Decoder, input: []const u8, output: []u8, output_len: *usize) Error!void {
        for (input) |byte| {
            const codepoint: u21 = windows_1252[byte];
            var encoded: [4]u8 = undefined;
            const length = std.unicode.utf8Encode(codepoint, encoded[0..]) catch unreachable;
            try self.appendCodepoint(codepoint, encoded[0..length], output, output_len);
        }
    }

    fn appendCodepoint(self: *Decoder, codepoint: u21, encoded: []const u8, output: []u8, output_len: *usize) Error!void {
        if (!self.bom_seen) {
            self.bom_seen = true;
            if (!self.ignore_bom and codepoint == 0xfeff) return;
        }
        if (output_len.* + encoded.len > output.len) return error.OutputTooSmall;
        @memcpy(output[output_len.* .. output_len.* + encoded.len], encoded);
        output_len.* += encoded.len;
    }

    fn invalid(self: *Decoder, output: []u8, output_len: *usize) Error!void {
        if (self.fatal) return error.InvalidSequence;
        try self.appendCodepoint(0xfffd, "\xef\xbf\xbd", output, output_len);
    }
};

fn validUtf8Prefix(sequence: []const u8) bool {
    if (sequence.len == 0) return true;
    const first = sequence[0];
    var index: usize = 1;
    while (index < sequence.len) : (index += 1) if ((sequence[index] & 0xc0) != 0x80) return false;
    if (sequence.len < 2) return true;
    const second = sequence[1];
    if (first == 0xe0 and second < 0xa0) return false;
    if (first == 0xed and second > 0x9f) return false;
    if (first == 0xf0 and second < 0x90) return false;
    if (first == 0xf4 and second > 0x8f) return false;
    return true;
}

const windows_1252 = blk: {
    var table: [256]u21 = undefined;
    for (0..256) |index| table[index] = @intCast(index);
    const replacements = [_]u21{
        0x20ac, 0x0081, 0x201a, 0x0192, 0x201e, 0x2026, 0x2020, 0x2021,
        0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008d, 0x017d, 0x008f,
        0x0090, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014,
        0x02dc, 0x2122, 0x0161, 0x203a, 0x0153, 0x009d, 0x017e, 0x0178,
    };
    for (replacements, 0..) |codepoint, index| table[0x80 + index] = codepoint;
    break :blk table;
};

test "Encoding labels and canonical names" {
    try std.testing.expectEqual(Encoding.utf8, try parseLabel(" UTF8\t"));
    try std.testing.expectEqual(Encoding.utf8, try parseLabel("x-unicode20utf8"));
    try std.testing.expectEqual(Encoding.windows_1252, try parseLabel("latin1"));
    try std.testing.expectError(error.UnknownEncoding, parseLabel("utf-16"));
    try std.testing.expectEqualStrings("windows-1252", Encoding.windows_1252.name());
}

test "TextEncoder encodeInto preserves scalar boundaries and UTF-16 read units" {
    const source = "A\xe2\x82\xac\xf0\x9f\x98\x80";
    var short: [3]u8 = undefined;
    const first = encodeInto(source, short[0..]);
    try std.testing.expectEqual(@as(usize, 1), first.read);
    try std.testing.expectEqual(@as(usize, 1), first.written);
    var full: [8]u8 = undefined;
    const second = encodeInto(source, full[0..]);
    try std.testing.expectEqual(@as(usize, 4), second.read);
    try std.testing.expectEqual(@as(usize, 8), second.written);
    try std.testing.expectEqualSlices(u8, source, full[0..]);
}

test "TextDecoder replaces or rejects invalid UTF-8" {
    var output: [32]u8 = undefined;
    var decoder = Decoder.init(.utf8, false, false);
    try std.testing.expectEqualStrings("A\xef\xbf\xbd(B", try decoder.decode("A\xe2(B", output[0..], false));
    var fatal = Decoder.init(.utf8, true, false);
    try std.testing.expectError(error.InvalidSequence, fatal.decode("\xff", output[0..], false));
}

test "TextDecoder streams split UTF-8 and flushes incomplete input" {
    var output: [32]u8 = undefined;
    var decoder = Decoder.init(.utf8, false, false);
    try std.testing.expectEqualStrings("", try decoder.decode("\xe2\x82", output[0..], true));
    try std.testing.expectEqualStrings("\xe2\x82\xac", try decoder.decode("\xac", output[0..], true));
    try std.testing.expectEqualStrings("", try decoder.decode("", output[0..], false));
    try std.testing.expectEqualStrings("", try decoder.decode("\xf0\x9f", output[0..], true));
    try std.testing.expectEqualStrings("\xef\xbf\xbd", try decoder.decode("", output[0..], false));
    try std.testing.expectEqualStrings("\xef\xbf\xbd(", try decoder.decode("\xe2(", output[0..], true));
    try std.testing.expectEqualStrings("", try decoder.decode("", output[0..], false));
}

test "TextDecoder resets fatal streaming state after an error" {
    var output: [32]u8 = undefined;
    var decoder = Decoder.init(.utf8, true, false);
    try std.testing.expectEqualStrings("", try decoder.decode("\xe2", output[0..], true));
    try std.testing.expectError(error.InvalidSequence, decoder.decode("(", output[0..], true));
    try std.testing.expectEqualStrings("A", try decoder.decode("A", output[0..], false));
}

test "TextDecoder handles BOM policy and Windows-1252" {
    var output: [32]u8 = undefined;
    var stripped = Decoder.init(.utf8, false, false);
    try std.testing.expectEqualStrings("A", try stripped.decode("\xef\xbb\xbfA", output[0..], false));
    var kept = Decoder.init(.utf8, false, true);
    try std.testing.expectEqualStrings("\xef\xbb\xbfA", try kept.decode("\xef\xbb\xbfA", output[0..], false));
    var legacy = Decoder.init(.windows_1252, false, false);
    try std.testing.expectEqualStrings("\xe2\x82\xac\xe2\x80\x9c", try legacy.decode("\x80\x93", output[0..], false));
}

test "TextDecoder packed host state preserves streaming bytes and policy" {
    var decoder = Decoder.init(.utf8, true, true);
    decoder.streaming = true;
    decoder.bom_seen = true;
    decoder.pending[0] = 0xe2;
    decoder.pending[1] = 0x82;
    decoder.pending_len = 2;
    const restored = Decoder.fromPackedState(decoder.packState());
    try std.testing.expectEqual(decoder.encoding, restored.encoding);
    try std.testing.expectEqual(decoder.fatal, restored.fatal);
    try std.testing.expectEqual(decoder.ignore_bom, restored.ignore_bom);
    try std.testing.expectEqual(decoder.streaming, restored.streaming);
    try std.testing.expectEqual(decoder.bom_seen, restored.bom_seen);
    try std.testing.expectEqualSlices(u8, decoder.pending[0..decoder.pending_len], restored.pending[0..restored.pending_len]);
}
