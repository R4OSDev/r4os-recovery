const std = @import("std");

pub const url_capacity: usize = 767;
pub const history_capacity: usize = 32;

pub const UrlError = error{
    Empty,
    TooLong,
    InvalidCharacter,
    UnsupportedScheme,
    MissingHost,
    UnsupportedRelativeBase,
};

pub const Scheme = enum {
    about,
    http,
    https,
};

pub const Url = struct {
    storage: [url_capacity + 1]u8 = .{0} ** (url_capacity + 1),
    len: usize = 0,
    scheme: Scheme = .about,

    pub fn bytes(self: *const Url) []const u8 {
        return self.storage[0..self.len];
    }

    pub fn z(self: *const Url) [*:0]const u8 {
        return @ptrCast(&self.storage);
    }
};

pub fn parse(raw: []const u8) UrlError!Url {
    const input = trim(raw);
    if (input.len == 0) return error.Empty;
    try validateCharacters(input);

    if (startsWithIgnoreCase(input, "about:")) return parseAbout(input);

    var expanded: [url_capacity + 1]u8 = .{0} ** (url_capacity + 1);
    const absolute = if (hasExplicitScheme(input)) input else blk: {
        const prefix = "https://";
        if (prefix.len + input.len > url_capacity) return error.TooLong;
        @memcpy(expanded[0..prefix.len], prefix);
        @memcpy(expanded[prefix.len .. prefix.len + input.len], input);
        break :blk expanded[0 .. prefix.len + input.len];
    };

    const scheme: Scheme = if (startsWithIgnoreCase(absolute, "https://"))
        .https
    else if (startsWithIgnoreCase(absolute, "http://"))
        .http
    else
        return error.UnsupportedScheme;
    return normalizeHttp(absolute, scheme);
}

pub fn resolve(base: *const Url, raw_reference: []const u8) UrlError!Url {
    const reference = trim(raw_reference);
    if (reference.len == 0) return base.*;
    try validateCharacters(reference);
    if (hasExplicitScheme(reference) or startsWithIgnoreCase(reference, "about:")) return parse(reference);
    if (base.scheme == .about) return error.UnsupportedRelativeBase;

    const base_bytes = base.bytes();
    const colon = std.mem.indexOfScalar(u8, base_bytes, ':') orelse return error.UnsupportedRelativeBase;
    const authority_start = colon + 3;
    const authority_end = findFirstOf(base_bytes, authority_start, "/?#");
    if (authority_end <= authority_start) return error.MissingHost;

    var candidate: [url_capacity + 1]u8 = .{0} ** (url_capacity + 1);
    var len: usize = 0;
    if (std.mem.startsWith(u8, reference, "//")) {
        try append(&candidate, &len, base_bytes[0 .. colon + 1]);
        try append(&candidate, &len, reference);
    } else if (reference[0] == '/') {
        try append(&candidate, &len, base_bytes[0..authority_end]);
        try append(&candidate, &len, reference);
    } else if (reference[0] == '?') {
        const end = findFirstOf(base_bytes, authority_end, "?#");
        try append(&candidate, &len, base_bytes[0..end]);
        try append(&candidate, &len, reference);
    } else if (reference[0] == '#') {
        const end = std.mem.indexOfScalar(u8, base_bytes, '#') orelse base_bytes.len;
        try append(&candidate, &len, base_bytes[0..end]);
        try append(&candidate, &len, reference);
    } else {
        const clean_end = findFirstOf(base_bytes, authority_end, "?#");
        const slash = std.mem.lastIndexOfScalar(u8, base_bytes[0..clean_end], '/') orelse authority_end;
        try append(&candidate, &len, base_bytes[0 .. slash + 1]);
        try append(&candidate, &len, reference);
    }
    return parse(candidate[0..len]);
}

fn parseAbout(input: []const u8) UrlError!Url {
    if (input.len > url_capacity) return error.TooLong;
    if (input.len == "about:".len) return error.Empty;
    var result = Url{ .scheme = .about };
    const prefix = "about:";
    @memcpy(result.storage[0..prefix.len], prefix);
    var index = prefix.len;
    var in_query = false;
    while (index < input.len) : (index += 1) {
        const ch = input[index];
        if (ch == '?') {
            if (in_query) return error.InvalidCharacter;
            in_query = true;
            result.storage[index] = ch;
            continue;
        }
        const valid = isAsciiAlphaNumeric(ch) or ch == '-' or ch == '_' or ch == '.' or
            (in_query and (ch == '=' or ch == '&' or ch == '+' or ch == '%' or ch == '~'));
        if (!valid) return error.InvalidCharacter;
        result.storage[index] = if (in_query) ch else toLower(ch);
    }
    result.len = input.len;
    return result;
}

fn normalizeHttp(input: []const u8, scheme: Scheme) UrlError!Url {
    if (input.len > url_capacity) return error.TooLong;
    const scheme_len: usize = if (scheme == .https) 5 else 4;
    const authority_start = scheme_len + 3;
    const authority_end = findFirstOf(input, authority_start, "/?#");
    if (authority_end <= authority_start) return error.MissingHost;
    const authority = input[authority_start..authority_end];
    const at = std.mem.lastIndexOfScalar(u8, authority, '@');
    const user_info = if (at) |index| authority[0 .. index + 1] else "";
    const host_port = if (at) |index| authority[index + 1 ..] else authority;
    if (host_port.len == 0 or host_port[0] == ':') return error.MissingHost;

    var hostname: []const u8 = host_port;
    var port: []const u8 = "";
    if (host_port[0] == '[') {
        const close = std.mem.indexOfScalar(u8, host_port, ']') orelse return error.MissingHost;
        hostname = host_port[0 .. close + 1];
        if (close + 1 < host_port.len) {
            if (host_port[close + 1] != ':') return error.InvalidCharacter;
            port = host_port[close + 2 ..];
        }
    } else if (std.mem.lastIndexOfScalar(u8, host_port, ':')) |colon| {
        hostname = host_port[0..colon];
        port = host_port[colon + 1 ..];
    }
    if (hostname.len == 0) return error.MissingHost;
    if (port.len > 0) {
        var numeric: usize = 0;
        for (port) |byte| {
            if (!std.ascii.isDigit(byte)) return error.InvalidCharacter;
            numeric = std.math.mul(usize, numeric, 10) catch return error.InvalidCharacter;
            numeric = std.math.add(usize, numeric, byte - '0') catch return error.InvalidCharacter;
        }
        if (numeric > std.math.maxInt(u16)) return error.InvalidCharacter;
    } else if (host_port[host_port.len - 1] == ':') {
        return error.InvalidCharacter;
    }

    var result = Url{ .scheme = scheme };
    var len: usize = 0;
    try appendLower(&result.storage, &len, if (scheme == .https) "https://" else "http://");
    try append(&result.storage, &len, user_info);
    try appendLower(&result.storage, &len, hostname);
    const default_port = (scheme == .https and std.mem.eql(u8, port, "443")) or (scheme == .http and std.mem.eql(u8, port, "80"));
    if (port.len > 0 and !default_port) {
        try append(&result.storage, &len, ":");
        try append(&result.storage, &len, port);
    }
    const suffix_start = findFirstOf(input, authority_end, "?#");
    const path = input[authority_end..suffix_start];
    try appendNormalizedPath(&result.storage, &len, path);
    if (suffix_start < input.len) try append(&result.storage, &len, input[suffix_start..]);
    result.len = len;
    return result;
}

fn appendNormalizedPath(out: *[url_capacity + 1]u8, len: *usize, path: []const u8) UrlError!void {
    if (path.len == 0) {
        try append(out, len, "/");
        return;
    }
    var segment_starts: [96]usize = .{0} ** 96;
    var depth: usize = 0;
    var cursor: usize = if (path[0] == '/') 1 else 0;
    const keep_trailing = path[path.len - 1] == '/' or std.mem.endsWith(u8, path, "/.") or std.mem.endsWith(u8, path, "/..");
    while (cursor <= path.len) {
        const rest = path[cursor..];
        const relative_end = std.mem.indexOfScalar(u8, rest, '/') orelse rest.len;
        const segment = rest[0..relative_end];
        if (segment.len == 0 or std.mem.eql(u8, segment, ".")) {
            // Empty and current-directory segments do not affect the path.
        } else if (std.mem.eql(u8, segment, "..")) {
            if (depth > 0) {
                depth -= 1;
                len.* = segment_starts[depth];
                out[len.*] = 0;
            }
        } else {
            if (depth >= segment_starts.len) return error.TooLong;
            segment_starts[depth] = len.*;
            depth += 1;
            try append(out, len, "/");
            try append(out, len, segment);
        }
        if (relative_end == rest.len) break;
        cursor += relative_end + 1;
    }
    if (depth == 0) try append(out, len, "/");
    if (keep_trailing and len.* > 0 and out[len.* - 1] != '/') try append(out, len, "/");
}

pub const History = struct {
    entries: [history_capacity]Url = .{Url{}} ** history_capacity,
    entry_ids: [history_capacity]u64 = [_]u64{0} ** history_capacity,
    count: usize = 0,
    index: usize = 0,
    next_entry_id: u64 = 1,

    pub fn init(initial: Url) History {
        var result = History{};
        result.entries[0] = initial;
        result.entry_ids[0] = result.next_entry_id;
        result.next_entry_id += 1;
        result.count = 1;
        return result;
    }

    pub fn current(self: *const History) *const Url {
        return &self.entries[self.index];
    }

    pub fn canBack(self: *const History) bool {
        return self.count > 0 and self.index > 0;
    }

    pub fn canForward(self: *const History) bool {
        return self.count > 0 and self.index + 1 < self.count;
    }

    pub fn navigate(self: *History, url: Url) void {
        if (self.count > 0 and std.mem.eql(u8, self.current().bytes(), url.bytes())) return;
        self.push(url);
    }

    pub fn push(self: *History, url: Url) void {
        if (self.count > 0 and self.index + 1 < self.count) self.count = self.index + 1;
        if (self.count < history_capacity) {
            self.entries[self.count] = url;
            self.entry_ids[self.count] = self.next_entry_id;
            self.next_entry_id +%= 1;
            self.count += 1;
            self.index = self.count - 1;
            return;
        }
        var item: usize = 1;
        while (item < history_capacity) : (item += 1) {
            self.entries[item - 1] = self.entries[item];
            self.entry_ids[item - 1] = self.entry_ids[item];
        }
        self.entries[history_capacity - 1] = url;
        self.entry_ids[history_capacity - 1] = self.next_entry_id;
        self.next_entry_id +%= 1;
        self.index = history_capacity - 1;
    }

    pub fn replaceCurrent(self: *History, url: Url) void {
        if (self.count == 0) {
            self.* = init(url);
            return;
        }
        self.entries[self.index] = url;
    }

    pub fn back(self: *History) bool {
        if (!self.canBack()) return false;
        self.index -= 1;
        return true;
    }

    pub fn forward(self: *History) bool {
        if (!self.canForward()) return false;
        self.index += 1;
        return true;
    }

    pub fn go(self: *History, delta: i32) bool {
        if (delta == 0 or self.count == 0) return false;
        const destination = @as(i64, @intCast(self.index)) + delta;
        if (destination < 0 or destination >= @as(i64, @intCast(self.count))) return false;
        self.index = @intCast(destination);
        return true;
    }
};

pub fn isRelativeReference(input: []const u8) bool {
    const value = trim(input);
    if (value.len == 0 or hasExplicitScheme(value) or startsWithIgnoreCase(value, "about:")) return false;
    return value[0] == '/' or value[0] == '?' or value[0] == '#' or
        std.mem.startsWith(u8, value, "./") or std.mem.startsWith(u8, value, "../");
}

pub fn isDocumentRelativeReference(input: []const u8) bool {
    const value = trim(input);
    return value.len > 0 and !hasExplicitScheme(value) and !startsWithIgnoreCase(value, "about:");
}

fn validateCharacters(value: []const u8) UrlError!void {
    for (value) |ch| {
        if (ch < 0x20 or ch == 0x7F or ch == ' ' or ch == '\\') return error.InvalidCharacter;
    }
}

fn hasExplicitScheme(value: []const u8) bool {
    var index: usize = 0;
    while (index < value.len) : (index += 1) {
        const ch = value[index];
        if (ch == ':') return index > 0;
        if (ch == '/' or ch == '?' or ch == '#') return false;
        if (!(isAsciiAlphaNumeric(ch) or ch == '+' or ch == '-' or ch == '.')) return false;
    }
    return false;
}

fn findFirstOf(value: []const u8, start: usize, needles: []const u8) usize {
    var index = start;
    while (index < value.len) : (index += 1) {
        if (std.mem.indexOfScalar(u8, needles, value[index]) != null) return index;
    }
    return value.len;
}

fn append(out: *[url_capacity + 1]u8, len: *usize, value: []const u8) UrlError!void {
    if (len.* + value.len > url_capacity) return error.TooLong;
    @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
    out[len.*] = 0;
}

fn appendLower(out: *[url_capacity + 1]u8, len: *usize, value: []const u8) UrlError!void {
    if (len.* + value.len > url_capacity) return error.TooLong;
    for (value) |ch| {
        out[len.*] = toLower(ch);
        len.* += 1;
    }
    out[len.*] = 0;
}

fn trim(value: []const u8) []const u8 {
    return std.mem.trim(u8, value, " \t\r\n");
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    if (value.len < prefix.len) return false;
    for (prefix, 0..) |expected, index| {
        if (toLower(value[index]) != toLower(expected)) return false;
    }
    return true;
}

fn isAsciiAlphaNumeric(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9');
}

fn toLower(ch: u8) u8 {
    return if (ch >= 'A' and ch <= 'Z') ch + ('a' - 'A') else ch;
}

test "URL parsing normalization and relative resolution" {
    const base = try parse(" Example.COM/a/b/index.html?old=1#top ");
    try std.testing.expectEqualStrings("https://example.com/a/b/index.html?old=1#top", base.bytes());
    const path = try resolve(&base, "../next?q=2");
    try std.testing.expectEqualStrings("https://example.com/a/next?q=2", path.bytes());
    const internal = try parse("ABOUT:Search-Results?q=R4OS+Browser");
    try std.testing.expectEqualStrings("about:search-results?q=R4OS+Browser", internal.bytes());
}

test "URL normalization preserves credentials lowers only hosts and removes default ports" {
    const secured = try parse("HTTPS://User:Secret@Example.COM:443/a");
    try std.testing.expectEqualStrings("https://User:Secret@example.com/a", secured.bytes());
    const explicit = try parse("http://User@Example.COM:8080/");
    try std.testing.expectEqualStrings("http://User@example.com:8080/", explicit.bytes());
    try std.testing.expectError(error.InvalidCharacter, parse("https://example.test:invalid/"));
    try std.testing.expectError(error.InvalidCharacter, parse("https://example.test:70000/"));
}

test "bounded history supports replacement branching and eviction" {
    var history = History.init(try parse("about:klickifax"));
    const initial_id = history.entry_ids[0];
    history.navigate(try parse("about:one"));
    history.navigate(try parse("about:two"));
    try std.testing.expect(initial_id != history.entry_ids[1]);
    try std.testing.expect(history.go(-2));
    try std.testing.expectEqual(@as(usize, 0), history.index);
    try std.testing.expect(!history.go(-1));
    try std.testing.expect(history.go(2));
    try std.testing.expect(history.back());
    const replaced_id = history.entry_ids[history.index];
    history.replaceCurrent(try parse("about:redirected"));
    try std.testing.expectEqual(replaced_id, history.entry_ids[history.index]);
    try std.testing.expectEqualStrings("about:redirected", history.current().bytes());
    history.navigate(try parse("about:branch"));
    try std.testing.expect(!history.canForward());
    var index: usize = 0;
    while (index < history_capacity + 3) : (index += 1) {
        var buffer: [64]u8 = undefined;
        history.navigate(try parse(try std.fmt.bufPrint(buffer[0..], "https://example.com/{d}", .{index})));
    }
    try std.testing.expectEqual(history_capacity, history.count);
    for (1..history.count) |entry_index| try std.testing.expect(history.entry_ids[entry_index - 1] != history.entry_ids[entry_index]);
}
