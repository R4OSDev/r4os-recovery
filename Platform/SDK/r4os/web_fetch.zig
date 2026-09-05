const std = @import("std");

pub const max_headers: usize = 64;
pub const max_name_bytes: usize = 64;
pub const max_value_bytes: usize = 1024;
pub const max_serialized_bytes: usize = 16 * 1024;

pub const Error = error{
    HeaderLimit,
    NameTooLong,
    ValueTooLong,
    InvalidName,
    InvalidValue,
    SerializedTooLong,
    InvalidSerialized,
};

const Header = struct {
    name: [max_name_bytes]u8 = undefined,
    name_len: usize = 0,
    value: [max_value_bytes]u8 = undefined,
    value_len: usize = 0,

    fn nameBytes(self: *const Header) []const u8 {
        return self.name[0..self.name_len];
    }

    fn valueBytes(self: *const Header) []const u8 {
        return self.value[0..self.value_len];
    }
};

pub const Headers = struct {
    entries: [max_headers]Header = undefined,
    count: usize = 0,

    pub fn init(serialized: []const u8) Error!Headers {
        var headers = Headers{};
        if (serialized.len == 0) return headers;
        var lines = std.mem.splitScalar(u8, serialized, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidSerialized;
            if (colon == 0) return error.InvalidSerialized;
            try headers.append(line[0..colon], line[colon + 1 ..]);
        }
        return headers;
    }

    pub fn append(self: *Headers, raw_name: []const u8, raw_value: []const u8) Error!void {
        if (self.count >= self.entries.len) return error.HeaderLimit;
        const entry = try makeHeader(raw_name, raw_value);
        self.entries[self.count] = entry;
        self.count += 1;
    }

    pub fn delete(self: *Headers, raw_name: []const u8) Error!void {
        var normalized: [max_name_bytes]u8 = undefined;
        const normalized_name = try normalizeName(raw_name, normalized[0..]);
        var write: usize = 0;
        for (self.entries[0..self.count]) |entry| {
            if (std.mem.eql(u8, entry.nameBytes(), normalized_name)) continue;
            self.entries[write] = entry;
            write += 1;
        }
        self.count = write;
    }

    pub fn has(self: *const Headers, raw_name: []const u8) Error!bool {
        var normalized: [max_name_bytes]u8 = undefined;
        const normalized_name = try normalizeName(raw_name, normalized[0..]);
        for (self.entries[0..self.count]) |*entry| if (std.mem.eql(u8, entry.nameBytes(), normalized_name)) return true;
        return false;
    }

    pub fn set(self: *Headers, raw_name: []const u8, raw_value: []const u8) Error!void {
        const replacement = try makeHeader(raw_name, raw_value);
        var first: ?usize = null;
        var write: usize = 0;
        for (self.entries[0..self.count]) |entry| {
            if (std.mem.eql(u8, entry.nameBytes(), replacement.nameBytes())) {
                if (first == null) {
                    first = write;
                    self.entries[write] = replacement;
                    write += 1;
                }
                continue;
            }
            self.entries[write] = entry;
            write += 1;
        }
        if (first == null) {
            if (write >= self.entries.len) return error.HeaderLimit;
            self.entries[write] = replacement;
            write += 1;
        }
        self.count = write;
    }

    pub fn get(self: *const Headers, raw_name: []const u8, output: []u8) Error!?[]const u8 {
        var normalized: [max_name_bytes]u8 = undefined;
        const normalized_name = try normalizeName(raw_name, normalized[0..]);
        var length: usize = 0;
        var found = false;
        for (self.entries[0..self.count]) |*entry| {
            if (!std.mem.eql(u8, entry.nameBytes(), normalized_name)) continue;
            if (found) try appendSlice(output, &length, ", ");
            try appendSlice(output, &length, entry.valueBytes());
            found = true;
        }
        return if (found) output[0..length] else null;
    }

    pub fn getSetCookie(self: *const Headers, values: *[max_headers][]const u8) usize {
        var count: usize = 0;
        for (self.entries[0..self.count]) |*entry| {
            if (!std.mem.eql(u8, entry.nameBytes(), "set-cookie")) continue;
            values[count] = entry.valueBytes();
            count += 1;
        }
        return count;
    }

    pub fn serialize(self: *const Headers, output: []u8) Error![]const u8 {
        var length: usize = 0;
        for (self.entries[0..self.count]) |*entry| {
            try appendSlice(output, &length, entry.nameBytes());
            try appendSlice(output, &length, ":");
            try appendSlice(output, &length, entry.valueBytes());
            try appendSlice(output, &length, "\n");
        }
        return output[0..length];
    }

    pub fn ordered(self: *const Headers, indices: *[max_headers]usize) []const usize {
        for (0..self.count) |index| indices[index] = index;
        var current: usize = 1;
        while (current < self.count) : (current += 1) {
            const selected = indices[current];
            var position = current;
            while (position > 0 and less(self, selected, indices[position - 1])) : (position -= 1)
                indices[position] = indices[position - 1];
            indices[position] = selected;
        }
        return indices[0..self.count];
    }

    pub fn name(self: *const Headers, index: usize) []const u8 {
        return self.entries[index].nameBytes();
    }

    pub fn value(self: *const Headers, index: usize) []const u8 {
        return self.entries[index].valueBytes();
    }
};

fn makeHeader(raw_name: []const u8, raw_value: []const u8) Error!Header {
    var entry = Header{};
    const name = try normalizeName(raw_name, entry.name[0..]);
    entry.name_len = name.len;
    const value = try normalizeValue(raw_value, entry.value[0..]);
    entry.value_len = value.len;
    return entry;
}

fn normalizeName(raw: []const u8, output: []u8) Error![]const u8 {
    if (raw.len == 0) return error.InvalidName;
    if (raw.len > output.len) return error.NameTooLong;
    for (raw, 0..) |byte, index| {
        if (!isToken(byte)) return error.InvalidName;
        output[index] = std.ascii.toLower(byte);
    }
    return output[0..raw.len];
}

fn normalizeValue(raw: []const u8, output: []u8) Error![]const u8 {
    const value = std.mem.trim(u8, raw, " \t");
    if (value.len > output.len) return error.ValueTooLong;
    for (value) |byte| if (byte == 0 or byte == '\r' or byte == '\n' or (byte < 0x20 and byte != '\t') or byte == 0x7f) return error.InvalidValue;
    @memcpy(output[0..value.len], value);
    return output[0..value.len];
}

fn isToken(byte: u8) bool {
    if (std.ascii.isAlphanumeric(byte)) return true;
    return std.mem.indexOfScalar(u8, "!#$%&'*+-.^_`|~", byte) != null;
}

fn appendSlice(output: []u8, length: *usize, value: []const u8) Error!void {
    if (value.len > output.len -| length.*) return error.SerializedTooLong;
    @memcpy(output[length.* .. length.* + value.len], value);
    length.* += value.len;
}

fn less(headers: *const Headers, left_index: usize, right_index: usize) bool {
    const left = &headers.entries[left_index];
    const right = &headers.entries[right_index];
    const name_order = std.mem.order(u8, left.nameBytes(), right.nameBytes());
    if (name_order != .eq) return name_order == .lt;
    return left_index < right_index;
}

test "Headers validates normalizes combines mutates and serializes" {
    var headers = try Headers.init("");
    try headers.append("Content-Type", " text/plain ");
    try headers.append("X-Test", "one");
    try headers.append("x-test", "two");
    var value_buffer: [128]u8 = undefined;
    try std.testing.expectEqualStrings("one, two", (try headers.get("X-TEST", value_buffer[0..])).?);
    try std.testing.expect(try headers.has("content-type"));
    try headers.set("X-Test", "final");
    try std.testing.expectEqualStrings("final", (try headers.get("x-test", value_buffer[0..])).?);
    try headers.delete("CONTENT-TYPE");
    try std.testing.expect(!(try headers.has("content-type")));
    var serialized: [max_serialized_bytes]u8 = undefined;
    try std.testing.expectEqualStrings("x-test:final\n", try headers.serialize(serialized[0..]));
}

test "Headers preserves Set-Cookie fields and sorts names stably" {
    var headers = try Headers.init("z-last:3\nset-cookie:a=1\na-first:1\nset-cookie:b=2\n");
    var cookies: [max_headers][]const u8 = undefined;
    const cookie_count = headers.getSetCookie(&cookies);
    try std.testing.expectEqual(@as(usize, 2), cookie_count);
    try std.testing.expectEqualStrings("a=1", cookies[0]);
    try std.testing.expectEqualStrings("b=2", cookies[1]);
    var indices: [max_headers]usize = undefined;
    const order = headers.ordered(&indices);
    try std.testing.expectEqualStrings("a-first", headers.name(order[0]));
    try std.testing.expectEqualStrings("set-cookie", headers.name(order[1]));
    try std.testing.expectEqualStrings("set-cookie", headers.name(order[2]));
    try std.testing.expectEqualStrings("z-last", headers.name(order[3]));
}

test "Headers rejects malformed names values and fixed-bound overflows" {
    var headers = try Headers.init("");
    try std.testing.expectError(error.InvalidName, headers.append("bad name", "value"));
    try std.testing.expectError(error.InvalidValue, headers.append("good", "line\r\nbreak"));
    var long_value: [max_value_bytes + 1]u8 = [_]u8{'a'} ** (max_value_bytes + 1);
    try std.testing.expectError(error.ValueTooLong, headers.append("good", long_value[0..]));
}
