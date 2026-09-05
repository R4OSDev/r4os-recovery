const std = @import("std");

pub const max_query_bytes: usize = 767;
pub const max_pairs: usize = 64;
const max_decoded_bytes: usize = max_query_bytes * 2;

pub const Error = error{
    TooLong,
    PairLimit,
    InvalidUrl,
};

pub const Parts = struct {
    protocol: []const u8,
    username: []const u8,
    password: []const u8,
    host: []const u8,
    hostname: []const u8,
    port: []const u8,
    pathname: []const u8,
    search: []const u8,
    hash: []const u8,
};

pub fn parts(href: []const u8) Error!Parts {
    const colon = std.mem.indexOfScalar(u8, href, ':') orelse return error.InvalidUrl;
    const protocol = href[0 .. colon + 1];
    var authority_start = colon + 1;
    var authority_end = authority_start;
    if (authority_start + 1 < href.len and href[authority_start] == '/' and href[authority_start + 1] == '/') {
        authority_start += 2;
        authority_end = std.mem.indexOfAnyPos(u8, href, authority_start, "/?#") orelse href.len;
    }
    const authority = href[authority_start..authority_end];
    const at = std.mem.lastIndexOfScalar(u8, authority, '@');
    const user_info = if (at) |index| authority[0..index] else "";
    const host = if (at) |index| authority[index + 1 ..] else authority;
    const user_colon = std.mem.indexOfScalar(u8, user_info, ':');
    const username = if (user_colon) |index| user_info[0..index] else user_info;
    const password = if (user_colon) |index| user_info[index + 1 ..] else "";
    const host_colon = if (host.len > 0 and host[0] != '[') std.mem.lastIndexOfScalar(u8, host, ':') else if (std.mem.lastIndexOfScalar(u8, host, ']')) |close| if (close + 1 < host.len and host[close + 1] == ':') close + 1 else null else null;
    const hostname = if (host_colon) |index| host[0..index] else host;
    const port = if (host_colon) |index| host[index + 1 ..] else "";
    const query_start = std.mem.indexOfScalarPos(u8, href, authority_end, '?');
    const hash_start = std.mem.indexOfScalarPos(u8, href, authority_end, '#');
    const path_end = @min(query_start orelse href.len, hash_start orelse href.len);
    const search_end = hash_start orelse href.len;
    return .{
        .protocol = protocol,
        .username = username,
        .password = password,
        .host = host,
        .hostname = hostname,
        .port = port,
        .pathname = href[authority_end..path_end],
        .search = if (query_start) |start| href[start..search_end] else "",
        .hash = if (hash_start) |start| href[start..] else "",
    };
}

pub const Component = enum {
    protocol,
    username,
    password,
    host,
    hostname,
    port,
    pathname,
    search,
    hash,
};

pub fn replaceComponent(href: []const u8, component: Component, replacement: []const u8, out: []u8) Error![]const u8 {
    const parsed = try parts(href);
    var len: usize = 0;
    switch (component) {
        .protocol => {
            const colon = std.mem.indexOfScalar(u8, href, ':') orelse return error.InvalidUrl;
            try appendSlice(out, &len, std.mem.trimEnd(u8, replacement, ":"));
            try appendSlice(out, &len, href[colon..]);
        },
        .username, .password, .host, .hostname, .port => {
            const protocol_end = parsed.protocol.len;
            const authority_start = protocol_end + if (std.mem.startsWith(u8, href[protocol_end..], "//")) @as(usize, 2) else 0;
            const authority_end = authority_start + (if (std.mem.indexOfAny(u8, href[authority_start..], "/?#")) |index| index else href.len - authority_start);
            try appendSlice(out, &len, href[0..authority_start]);
            if (component == .host) {
                const authority = href[authority_start..authority_end];
                const at = std.mem.lastIndexOfScalar(u8, authority, '@');
                if (at) |index| try appendSlice(out, &len, authority[0 .. index + 1]);
                try appendSlice(out, &len, replacement);
            } else if (component == .username or component == .password) {
                const username = if (component == .username) replacement else parsed.username;
                const password = if (component == .password) replacement else parsed.password;
                if (username.len > 0 or password.len > 0) {
                    try appendUserInfo(out, &len, username);
                    if (password.len > 0) {
                        try appendSlice(out, &len, ":");
                        try appendUserInfo(out, &len, password);
                    }
                    try appendSlice(out, &len, "@");
                }
                try appendSlice(out, &len, parsed.host);
            } else {
                const authority = href[authority_start..authority_end];
                const at = std.mem.lastIndexOfScalar(u8, authority, '@');
                if (at) |index| try appendSlice(out, &len, authority[0 .. index + 1]);
                if (component == .hostname) {
                    try appendSlice(out, &len, replacement);
                    if (parsed.port.len > 0) {
                        try appendSlice(out, &len, ":");
                        try appendSlice(out, &len, parsed.port);
                    }
                } else {
                    try appendSlice(out, &len, parsed.hostname);
                    if (replacement.len > 0) {
                        try appendSlice(out, &len, ":");
                        try appendSlice(out, &len, replacement);
                    }
                }
            }
            try appendSlice(out, &len, href[authority_end..]);
        },
        .pathname => {
            const start = @intFromPtr(parsed.pathname.ptr) - @intFromPtr(href.ptr);
            try appendSlice(out, &len, href[0..start]);
            if (parsed.host.len > 0 and (replacement.len == 0 or replacement[0] != '/')) try appendSlice(out, &len, "/");
            try appendSlice(out, &len, replacement);
            try appendSlice(out, &len, parsed.search);
            try appendSlice(out, &len, parsed.hash);
        },
        .search => {
            const start = if (parsed.search.len > 0) @intFromPtr(parsed.search.ptr) - @intFromPtr(href.ptr) else if (parsed.hash.len > 0) @intFromPtr(parsed.hash.ptr) - @intFromPtr(href.ptr) else href.len;
            try appendSlice(out, &len, href[0..start]);
            if (replacement.len > 0 and replacement[0] != '?') try appendSlice(out, &len, "?");
            try appendSlice(out, &len, replacement);
            try appendSlice(out, &len, parsed.hash);
        },
        .hash => {
            const start = if (parsed.hash.len > 0) @intFromPtr(parsed.hash.ptr) - @intFromPtr(href.ptr) else href.len;
            try appendSlice(out, &len, href[0..start]);
            if (replacement.len > 0 and replacement[0] != '#') try appendSlice(out, &len, "#");
            try appendSlice(out, &len, replacement);
        },
    }
    return out[0..len];
}

fn appendUserInfo(out: []u8, len: *usize, value: []const u8) Error!void {
    const digits = "0123456789ABCDEF";
    for (value) |byte| {
        if (std.ascii.isAlphanumeric(byte) or byte == '-' or byte == '.' or byte == '_' or byte == '~' or byte == '%') {
            try appendSlice(out, len, &.{byte});
        } else {
            try appendSlice(out, len, &.{ '%', digits[byte >> 4], digits[byte & 0x0f] });
        }
    }
}

fn appendSlice(out: []u8, len: *usize, value: []const u8) Error!void {
    if (len.* + value.len > out.len) return error.TooLong;
    @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
}

const SliceRef = struct {
    offset: u16 = 0,
    len: u16 = 0,
};

pub const Pair = struct {
    name: SliceRef = .{},
    value: SliceRef = .{},
};

pub const SearchParams = struct {
    storage: [max_decoded_bytes]u8 = .{0} ** max_decoded_bytes,
    storage_len: usize = 0,
    pairs: [max_pairs]Pair = [_]Pair{.{}} ** max_pairs,
    count: usize = 0,

    pub fn init(query: []const u8) Error!SearchParams {
        var result = SearchParams{};
        try result.replace(query);
        return result;
    }

    pub fn replace(self: *SearchParams, query: []const u8) Error!void {
        self.storage_len = 0;
        self.count = 0;
        const source = if (query.len > 0 and query[0] == '?') query[1..] else query;
        if (source.len > max_query_bytes) return error.TooLong;
        if (source.len == 0) return;
        var fields = std.mem.splitScalar(u8, source, '&');
        while (fields.next()) |field| {
            if (self.count >= self.pairs.len) return error.PairLimit;
            const equal_index = std.mem.indexOfScalar(u8, field, '=') orelse field.len;
            const raw_name = field[0..equal_index];
            const raw_value = if (equal_index < field.len) field[equal_index + 1 ..] else "";
            self.pairs[self.count] = .{
                .name = try self.decode(raw_name),
                .value = try self.decode(raw_value),
            };
            self.count += 1;
        }
    }

    pub fn name(self: *const SearchParams, index: usize) []const u8 {
        return self.bytes(self.pairs[index].name);
    }

    pub fn value(self: *const SearchParams, index: usize) []const u8 {
        return self.bytes(self.pairs[index].value);
    }

    pub fn append(self: *SearchParams, name_text: []const u8, value_text: []const u8) Error!void {
        if (self.count >= self.pairs.len) return error.PairLimit;
        self.compact();
        self.pairs[self.count] = .{
            .name = try self.store(name_text),
            .value = try self.store(value_text),
        };
        self.count += 1;
    }

    pub fn get(self: *const SearchParams, name_text: []const u8) ?[]const u8 {
        for (0..self.count) |index| if (std.mem.eql(u8, self.name(index), name_text)) return self.value(index);
        return null;
    }

    pub fn has(self: *const SearchParams, name_text: []const u8, value_text: ?[]const u8) bool {
        for (0..self.count) |index| {
            if (!std.mem.eql(u8, self.name(index), name_text)) continue;
            if (value_text == null or std.mem.eql(u8, self.value(index), value_text.?)) return true;
        }
        return false;
    }

    pub fn delete(self: *SearchParams, name_text: []const u8, value_text: ?[]const u8) void {
        var write: usize = 0;
        for (0..self.count) |read| {
            const matches = std.mem.eql(u8, self.name(read), name_text) and
                (value_text == null or std.mem.eql(u8, self.value(read), value_text.?));
            if (matches) continue;
            self.pairs[write] = self.pairs[read];
            write += 1;
        }
        self.count = write;
        self.compact();
    }

    pub fn set(self: *SearchParams, name_text: []const u8, value_text: []const u8) Error!void {
        self.compact();
        var first: ?usize = null;
        var write: usize = 0;
        for (0..self.count) |read| {
            if (!std.mem.eql(u8, self.name(read), name_text)) {
                self.pairs[write] = self.pairs[read];
                write += 1;
                continue;
            }
            if (first == null) {
                first = write;
                self.pairs[write] = .{ .name = try self.store(name_text), .value = try self.store(value_text) };
                write += 1;
            }
        }
        self.count = write;
        if (first == null) try self.append(name_text, value_text);
    }

    pub fn sort(self: *SearchParams) void {
        var index: usize = 1;
        while (index < self.count) : (index += 1) {
            const candidate = self.pairs[index];
            var destination = index;
            while (destination > 0 and utf16Less(self.bytes(candidate.name), self.bytes(self.pairs[destination - 1].name))) {
                self.pairs[destination] = self.pairs[destination - 1];
                destination -= 1;
            }
            self.pairs[destination] = candidate;
        }
    }

    pub fn serialize(self: *const SearchParams, out: []u8) Error![]const u8 {
        var len: usize = 0;
        for (0..self.count) |index| {
            if (index > 0) try appendByte(out, &len, '&');
            try encode(self.name(index), out, &len);
            try appendByte(out, &len, '=');
            try encode(self.value(index), out, &len);
        }
        return out[0..len];
    }

    fn bytes(self: *const SearchParams, ref: SliceRef) []const u8 {
        const start: usize = ref.offset;
        return self.storage[start .. start + ref.len];
    }

    fn compact(self: *SearchParams) void {
        var replacement: [max_decoded_bytes]u8 = undefined;
        var replacement_len: usize = 0;
        for (0..self.count) |index| {
            const old_name = self.name(index);
            const name_offset = replacement_len;
            if (old_name.len > 0) @memcpy(replacement[replacement_len .. replacement_len + old_name.len], old_name);
            replacement_len += old_name.len;
            const old_value = self.value(index);
            const value_offset = replacement_len;
            if (old_value.len > 0) @memcpy(replacement[replacement_len .. replacement_len + old_value.len], old_value);
            replacement_len += old_value.len;
            self.pairs[index] = .{
                .name = .{ .offset = @intCast(name_offset), .len = @intCast(old_name.len) },
                .value = .{ .offset = @intCast(value_offset), .len = @intCast(old_value.len) },
            };
        }
        if (replacement_len > 0) @memcpy(self.storage[0..replacement_len], replacement[0..replacement_len]);
        self.storage_len = replacement_len;
    }

    fn store(self: *SearchParams, source: []const u8) Error!SliceRef {
        if (source.len > std.math.maxInt(u16) or self.storage_len + source.len > self.storage.len) return error.TooLong;
        const result = SliceRef{ .offset = @intCast(self.storage_len), .len = @intCast(source.len) };
        if (source.len > 0) @memcpy(self.storage[self.storage_len .. self.storage_len + source.len], source);
        self.storage_len += source.len;
        return result;
    }

    fn decode(self: *SearchParams, source: []const u8) Error!SliceRef {
        var decoded: [max_query_bytes]u8 = undefined;
        var decoded_len: usize = 0;
        var cursor: usize = 0;
        while (cursor < source.len) {
            if (source[cursor] == '+') {
                decoded[decoded_len] = ' ';
                decoded_len += 1;
                cursor += 1;
            } else if (source[cursor] == '%' and cursor + 2 < source.len) {
                const high = hex(source[cursor + 1]);
                const low = hex(source[cursor + 2]);
                if (high != null and low != null) {
                    decoded[decoded_len] = (high.? << 4) | low.?;
                    decoded_len += 1;
                    cursor += 3;
                } else {
                    decoded[decoded_len] = source[cursor];
                    decoded_len += 1;
                    cursor += 1;
                }
            } else {
                decoded[decoded_len] = source[cursor];
                decoded_len += 1;
                cursor += 1;
            }
        }
        const start = self.storage_len;
        cursor = 0;
        while (cursor < decoded_len) {
            const sequence_length = std.unicode.utf8ByteSequenceLength(decoded[cursor]) catch {
                _ = try self.store("\xEF\xBF\xBD");
                cursor += 1;
                continue;
            };
            if (cursor + sequence_length > decoded_len or (std.unicode.utf8Decode(decoded[cursor .. cursor + sequence_length]) catch null) == null) {
                _ = try self.store("\xEF\xBF\xBD");
                cursor += 1;
                continue;
            }
            _ = try self.store(decoded[cursor .. cursor + sequence_length]);
            cursor += sequence_length;
        }
        return .{ .offset = @intCast(start), .len = @intCast(self.storage_len - start) };
    }
};

fn encode(value: []const u8, out: []u8, len: *usize) Error!void {
    const digits = "0123456789ABCDEF";
    for (value) |byte| {
        if (isFormSafe(byte)) {
            try appendByte(out, len, byte);
        } else if (byte == ' ') {
            try appendByte(out, len, '+');
        } else {
            try appendByte(out, len, '%');
            try appendByte(out, len, digits[byte >> 4]);
            try appendByte(out, len, digits[byte & 0x0f]);
        }
    }
}

fn appendByte(out: []u8, len: *usize, byte: u8) Error!void {
    if (len.* >= out.len or len.* >= max_query_bytes) return error.TooLong;
    out[len.*] = byte;
    len.* += 1;
}

fn isFormSafe(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '*' or byte == '-' or byte == '.' or byte == '_';
}

fn hex(byte: u8) ?u8 {
    return if (byte >= '0' and byte <= '9') byte - '0' else if (byte >= 'a' and byte <= 'f') byte - 'a' + 10 else if (byte >= 'A' and byte <= 'F') byte - 'A' + 10 else null;
}

fn utf16Less(left: []const u8, right: []const u8) bool {
    var left_cursor: usize = 0;
    var right_cursor: usize = 0;
    var left_low: ?u16 = null;
    var right_low: ?u16 = null;
    while (left_cursor < left.len or right_cursor < right.len or left_low != null or right_low != null) {
        const left_unit = nextUtf16(left, &left_cursor, &left_low) orelse return right_cursor < right.len or right_low != null;
        const right_unit = nextUtf16(right, &right_cursor, &right_low) orelse return false;
        if (left_unit != right_unit) return left_unit < right_unit;
    }
    return false;
}

fn nextUtf16(value: []const u8, cursor: *usize, pending_low: *?u16) ?u16 {
    if (pending_low.*) |low| {
        pending_low.* = null;
        return low;
    }
    if (cursor.* >= value.len) return null;
    const sequence_length = std.unicode.utf8ByteSequenceLength(value[cursor.*]) catch {
        cursor.* += 1;
        return 0xfffd;
    };
    if (cursor.* + sequence_length > value.len) {
        cursor.* += 1;
        return 0xfffd;
    }
    const decoded = std.unicode.utf8Decode(value[cursor.* .. cursor.* + sequence_length]) catch {
        cursor.* += 1;
        return 0xfffd;
    };
    cursor.* += sequence_length;
    if (decoded <= 0xffff) return @intCast(decoded);
    const scalar: u32 = @intCast(decoded - 0x10000);
    pending_low.* = @intCast(0xdc00 + (scalar & 0x3ff));
    return @intCast(0xd800 + (scalar >> 10));
}

test "URLSearchParams parses mutates sorts and serializes form data" {
    var params = try SearchParams.init("?b=two+words&a=1&b=%E2%9C%93&empty");
    try std.testing.expectEqual(@as(usize, 4), params.count);
    try std.testing.expectEqualStrings("two words", params.get("b").?);
    try std.testing.expect(params.has("b", "✓"));
    try params.append("space key", "a+b");
    try params.set("a", "first");
    params.delete("b", "two words");
    params.sort();
    var out: [max_query_bytes]u8 = undefined;
    try std.testing.expectEqualStrings("a=first&b=%E2%9C%93&empty=&space+key=a%2Bb", try params.serialize(out[0..]));
}

test "URLSearchParams keeps duplicate order and optional value matching" {
    var params = try SearchParams.init("x=1&x=2&x=1&y=3");
    try std.testing.expect(params.has("x", null));
    try std.testing.expect(params.has("x", "2"));
    params.delete("x", "1");
    var out: [max_query_bytes]u8 = undefined;
    try std.testing.expectEqualStrings("x=2&y=3", try params.serialize(out[0..]));
    try params.set("x", "4");
    try std.testing.expectEqualStrings("x=4&y=3", try params.serialize(out[0..]));

    var invalid = try SearchParams.init("bad=%FF&short=%E2%9C");
    try std.testing.expectEqualStrings("\xEF\xBF\xBD", invalid.get("bad").?);
    try std.testing.expectEqualStrings("\xEF\xBF\xBD\xEF\xBF\xBD", invalid.get("short").?);
    try std.testing.expectEqualStrings("bad=%EF%BF%BD&short=%EF%BF%BD%EF%BF%BD", try invalid.serialize(out[0..]));
}

test "URL parts and component replacement stay synchronized" {
    const href = "https://example.test:8443/a/b?q=one#top";
    const parsed = try parts(href);
    try std.testing.expectEqualStrings("https:", parsed.protocol);
    try std.testing.expectEqualStrings("example.test:8443", parsed.host);
    try std.testing.expectEqualStrings("example.test", parsed.hostname);
    try std.testing.expectEqualStrings("8443", parsed.port);
    try std.testing.expectEqualStrings("/a/b", parsed.pathname);
    try std.testing.expectEqualStrings("?q=one", parsed.search);
    try std.testing.expectEqualStrings("#top", parsed.hash);
    var out: [max_query_bytes]u8 = undefined;
    try std.testing.expectEqualStrings("https://example.test:8443/next?q=one#top", try replaceComponent(href, .pathname, "/next", out[0..]));
    try std.testing.expectEqualStrings("https://example.test:8443/a/b?q=two#top", try replaceComponent(href, .search, "q=two", out[0..]));
    try std.testing.expectEqualStrings("https://example.test:443/a/b?q=one#top", try replaceComponent(href, .port, "443", out[0..]));

    const credentials = "https://user:secret@example.test:8443/path";
    const with_credentials = try parts(credentials);
    try std.testing.expectEqualStrings("user", with_credentials.username);
    try std.testing.expectEqualStrings("secret", with_credentials.password);
    try std.testing.expectEqualStrings("https://new%20user:secret@example.test:8443/path", try replaceComponent(credentials, .username, "new user", out[0..]));
    try std.testing.expectEqualStrings("https://user:p%40ss@example.test:8443/path", try replaceComponent(credentials, .password, "p@ss", out[0..]));
    try std.testing.expectEqualStrings("https://user:secret@other.test/path", try replaceComponent(credentials, .host, "other.test", out[0..]));
}
