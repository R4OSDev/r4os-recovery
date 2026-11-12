const std = @import("std");

pub const Mode = enum(u8) {
    normal,
    no_store,
    reload,
    no_cache,
    force_cache,
    only_if_cached,

    pub fn parse(text: []const u8) ?Mode {
        const names = [_][]const u8{ "default", "no-store", "reload", "no-cache", "force-cache", "only-if-cached" };
        for (names, 0..) |name, index| if (std.mem.eql(u8, text, name)) return @enumFromInt(index);
        return null;
    }
};

pub const max_entries = 8;
pub const max_key_bytes = 16 * 1024;
pub const max_header_bytes = 8 * 1024;
pub const Limits = struct { object_bytes: usize = 128 * 1024, total_bytes: usize = 512 * 1024 };
pub const Clock = struct { monotonic_ms: u64, unix_seconds: ?u64 = null };
// The full effective request header block intentionally partitions more
// narrowly than Vary alone. Unknown/different fields cannot produce a hit.
pub const Key = struct { url: []const u8, context: []const u8, headers: []const u8 };
pub const Handle = struct { index: u8, identity: u64 };
pub const Action = enum { miss, hit, revalidate, only_miss };
pub const Lookup = struct { action: Action, handle: ?Handle = null };
pub const View = struct { headers: []const u8, body: []const u8, identity: u64, age_seconds: u64 };
pub const Stats = struct { hits: u64 = 0, misses: u64 = 0, validations: u64 = 0, stores: u64 = 0, evictions: u64 = 0 };

const Entry = struct {
    data: []u8 = &.{},
    ends: [5]usize = .{0} ** 5,
    identity: u64 = 0,
    token: u64 = 0,
    used: u64 = 0,
    pins: u16 = 0,
    retired: bool = false,
    stored_ms: u64 = 0,
    initial_age_ms: u64 = 0,
    lifetime_ms: u64 = 0,
    validate: bool = false,

    fn part(self: *const Entry, index: usize) []const u8 {
        return self.data[if (index == 0) 0 else self.ends[index - 1]..self.ends[index]];
    }
    fn matches(self: *const Entry, key: Key) bool {
        return self.identity != 0 and !self.retired and std.mem.eql(u8, self.part(0), key.url) and
            std.mem.eql(u8, self.part(1), key.context) and std.mem.eql(u8, self.part(2), key.headers);
    }
    fn age(self: *const Entry, now_ms: u64) u64 {
        return self.initial_age_ms +| (now_ms -| self.stored_ms);
    }
};

pub const Cache = struct {
    allocator: std.mem.Allocator,
    limits: Limits,
    entries: [max_entries]Entry = .{Entry{}} ** max_entries,
    bytes: usize = 0,
    serial: u64 = 0,
    next_identity: u64 = 1,
    stats: Stats = .{},

    pub fn init(allocator: std.mem.Allocator, limits: Limits) Cache {
        return .{ .allocator = allocator, .limits = limits };
    }
    pub fn deinit(self: *Cache) void {
        for (&self.entries) |*entry| {
            std.debug.assert(entry.pins == 0);
            self.remove(entry);
        }
    }
    fn remove(self: *Cache, entry: *Entry) void {
        self.bytes -= entry.data.len;
        self.allocator.free(entry.data);
        entry.* = .{};
    }
    fn retire(self: *Cache, entry: *Entry) void {
        if (entry.pins == 0) self.remove(entry) else entry.retired = true;
    }
    pub fn invalidateUrl(self: *Cache, url: []const u8) void {
        for (&self.entries) |*entry| if (entry.identity != 0 and std.mem.eql(u8, entry.part(0), url)) self.retire(entry);
    }
    pub fn invalidate(self: *Cache, key: Key) void {
        for (&self.entries) |*entry| if (entry.matches(key)) self.retire(entry);
    }
    pub fn lookup(self: *Cache, key: Key, mode: Mode, now: Clock) Lookup {
        if (mode != .no_store and mode != .reload) {
            for (&self.entries, 0..) |*entry, index| {
                if (!entry.matches(key) or entry.pins == std.math.maxInt(u16)) continue;
                self.serial +|= 1;
                entry.used = self.serial;
                entry.pins += 1;
                const stale = entry.validate or entry.age(now.monotonic_ms) >= entry.lifetime_ms;
                const hit = mode == .force_cache or mode == .only_if_cached or (mode != .no_cache and !stale);
                if (hit) self.stats.hits +|= 1 else self.stats.validations +|= 1;
                return .{ .action = if (hit) .hit else .revalidate, .handle = .{ .index = @intCast(index), .identity = entry.token } };
            }
        }
        self.stats.misses +|= 1;
        return .{ .action = if (mode == .only_if_cached) .only_miss else .miss };
    }
    fn entryFor(self: *Cache, handle: Handle) ?*Entry {
        if (handle.index >= self.entries.len) return null;
        const entry = &self.entries[handle.index];
        return if (entry.token == handle.identity and entry.pins != 0) entry else null;
    }
    pub fn view(self: *Cache, handle: Handle, now: Clock) ?View {
        const entry = self.entryFor(handle) orelse return null;
        return .{ .headers = entry.part(3), .body = entry.part(4), .identity = entry.identity, .age_seconds = entry.age(now.monotonic_ms) / 1000 };
    }
    pub fn release(self: *Cache, handle: Handle) void {
        const entry = self.entryFor(handle) orelse return;
        entry.pins -= 1;
        if (entry.pins == 0 and entry.retired) self.remove(entry);
    }
    // Network success remains deliverable if storing the optional copy fails.
    // Input spans must belong to the caller, not a borrowed cache view.
    pub fn store(self: *Cache, key: Key, headers: []const u8, body: []const u8, now: Clock, request_started_ms: u64, preserved_identity: ?u64) !?u64 {
        self.invalidate(key);
        const policy = responsePolicy(headers, now, request_started_ms);
        if (!policy.allowed or body.len > self.limits.object_bytes or headers.len > max_header_bytes or
            key.url.len > max_key_bytes or key.context.len > max_key_bytes - key.url.len or
            key.headers.len > max_key_bytes - key.url.len - key.context.len) return null;
        const parts = [_][]const u8{ key.url, key.context, key.headers, headers, body };
        var size: usize = 0;
        for (parts) |part| size = std.math.add(usize, size, part.len) catch return null;
        if (size == 0 or size > self.limits.total_bytes) return null;
        const data = try self.allocator.alloc(u8, size);
        errdefer self.allocator.free(data);
        var offset: usize = 0;
        var ends: [5]usize = undefined;
        for (parts, 0..) |part, index| {
            @memcpy(data[offset .. offset + part.len], part);
            offset += part.len;
            ends[index] = offset;
        }
        var slot: ?*Entry = null;
        while (true) {
            var oldest: ?*Entry = null;
            for (&self.entries) |*entry| {
                if (entry.identity == 0) slot = entry else if (entry.pins == 0 and (oldest == null or entry.used < oldest.?.used)) oldest = entry;
            }
            if (slot != null and self.bytes <= self.limits.total_bytes - size) break;
            const victim = oldest orelse return error.CacheBusy;
            self.remove(victim);
            self.stats.evictions +|= 1;
        }
        const identity = preserved_identity orelse self.newIdentity();
        self.serial +|= 1;
        slot.?.* = .{ .data = data, .ends = ends, .identity = identity, .token = self.newIdentity(), .used = self.serial, .stored_ms = now.monotonic_ms, .initial_age_ms = policy.age_ms, .lifetime_ms = policy.lifetime_ms, .validate = policy.validate };
        self.bytes += size;
        self.stats.stores +|= 1;
        return identity;
    }
    pub fn newIdentity(self: *Cache) u64 {
        const value = self.next_identity;
        self.next_identity +%= 1;
        if (self.next_identity == 0) self.next_identity = 1;
        return value;
    }
};

pub const Header = struct { name: []const u8, value: []const u8 };
pub const HeaderIterator = struct {
    lines: std.mem.SplitIterator(u8, .scalar),
    pub fn init(headers: []const u8) HeaderIterator {
        return .{ .lines = std.mem.splitScalar(u8, headers, '\n') };
    }
    pub fn next(self: *HeaderIterator) ?Header {
        while (self.lines.next()) |line| {
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            return .{ .name = std.mem.trim(u8, line[0..colon], " \t\r"), .value = std.mem.trim(u8, line[colon + 1 ..], " \t\r") };
        }
        return null;
    }
};
pub fn header(headers: []const u8, name: []const u8) ?[]const u8 {
    var iterator = HeaderIterator.init(headers);
    while (iterator.next()) |item| if (std.ascii.eqlIgnoreCase(item.name, name)) return item.value;
    return null;
}

pub const Directives = struct { no_store: bool = false, no_cache: bool = false, max_age: ?u64 = null, invalid_age: bool = false };
pub fn directives(headers: []const u8) Directives {
    var result: Directives = .{};
    var iterator = HeaderIterator.init(headers);
    while (iterator.next()) |item| {
        if (!std.ascii.eqlIgnoreCase(item.name, "Cache-Control")) continue;
        var values = std.mem.splitScalar(u8, item.value, ',');
        while (values.next()) |raw| {
            const value = std.mem.trim(u8, raw, " \t");
            const equal = std.mem.indexOfScalar(u8, value, '=') orelse value.len;
            const name = std.mem.trim(u8, value[0..equal], " \t");
            if (std.ascii.eqlIgnoreCase(name, "no-store")) result.no_store = true;
            if (std.ascii.eqlIgnoreCase(name, "no-cache")) result.no_cache = true;
            if (std.ascii.eqlIgnoreCase(name, "max-age")) {
                const number = if (equal < value.len) std.fmt.parseInt(u64, std.mem.trim(u8, value[equal + 1 ..], " \t\""), 10) catch null else null;
                if (result.max_age != null or number == null) result.invalid_age = true;
                result.max_age = number;
            }
        }
    }
    return result;
}
const Policy = struct { allowed: bool = true, age_ms: u64 = 0, lifetime_ms: u64 = 0, validate: bool = false };
pub fn initialAgeSeconds(headers: []const u8, now: Clock, request_started_ms: u64) u64 {
    return responsePolicy(headers, now, request_started_ms).age_ms / 1000;
}

fn responsePolicy(headers: []const u8, now: Clock, request_started_ms: u64) Policy {
    const control = directives(headers);
    var policy: Policy = .{ .allowed = !control.no_store, .validate = control.no_cache or control.invalid_age };
    var iterator = HeaderIterator.init(headers);
    while (iterator.next()) |item| {
        if (std.ascii.eqlIgnoreCase(item.name, "Vary")) {
            var names = std.mem.splitScalar(u8, item.value, ',');
            while (names.next()) |name| if (std.mem.eql(u8, std.mem.trim(u8, name, " \t"), "*")) {
                policy.allowed = false;
            };
        }
        if (std.ascii.eqlIgnoreCase(item.name, "Age")) {
            const age = std.fmt.parseInt(u64, item.value, 10) catch {
                policy.validate = true;
                continue;
            };
            policy.age_ms = @max(policy.age_ms, age *| 1000);
        }
    }
    const date = if (header(headers, "Date")) |text| parseDate(text) else now.unix_seconds;
    if (date) |date_seconds| {
        if (now.unix_seconds) |seconds| policy.age_ms = @max(policy.age_ms, (seconds -| date_seconds) *| 1000) else policy.validate = true;
    } else if (header(headers, "Date") != null) policy.validate = true;
    policy.age_ms +|= now.monotonic_ms -| request_started_ms;
    if (control.max_age) |seconds| {
        policy.lifetime_ms = seconds *| 1000;
    } else if (header(headers, "Expires")) |text| {
        if (parseDate(text)) |expires| if (date) |origin| {
            policy.lifetime_ms = (expires -| origin) *| 1000;
        };
    }
    return policy;
}

pub fn parseDate(text: []const u8) ?u64 {
    if (text.len != 29 or text[3] != ',' or text[4] != ' ' or text[7] != ' ' or text[11] != ' ' or text[16] != ' ' or text[19] != ':' or text[22] != ':' or !std.mem.eql(u8, text[25..], " GMT")) return null;
    const day = std.fmt.parseInt(u8, text[5..7], 10) catch return null;
    const year = std.fmt.parseInt(u16, text[12..16], 10) catch return null;
    const hour = std.fmt.parseInt(u8, text[17..19], 10) catch return null;
    const minute = std.fmt.parseInt(u8, text[20..22], 10) catch return null;
    const second = std.fmt.parseInt(u8, text[23..25], 10) catch return null;
    const months = [_][]const u8{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
    var month: usize = 0;
    while (month < months.len and !std.mem.eql(u8, text[8..11], months[month])) : (month += 1) {}
    if (month == months.len or year < 1970 or year > 9999 or hour > 23 or minute > 59 or second > 59) return null;
    const leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0);
    const days_in_month = [_]u8{ 31, if (leap) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    if (day == 0 or day > days_in_month[month]) return null;
    const y: u64 = year - 1;
    var days: u64 = (year - 1970) * @as(u64, 365) + (y / 4 - 1969 / 4) - (y / 100 - 1969 / 100) + (y / 400 - 1969 / 400);
    for (days_in_month[0..month]) |count| days += count;
    days += day - 1;
    return days * 86400 + @as(u64, hour) * 3600 + @as(u64, minute) * 60 + second;
}

test "response cache modes freshness validators and context remain distinct" {
    var cache = Cache.init(std.testing.allocator, .{});
    defer cache.deinit();
    const key: Key = .{ .url = "http://cache.example/a", .context = "origin=cache.example;credentials=omit", .headers = "GET /a HTTP/1.1\r\nHost: cache.example\r\nAccept: text/plain\r\n" };
    const start: Clock = .{ .monotonic_ms = 1000, .unix_seconds = 1788868800 };
    try std.testing.expectEqual(Action.only_miss, cache.lookup(key, .only_if_cached, start).action);
    const id = (try cache.store(key, "Cache-Control: max-age=10\r\nETag: \"v1\"\r\nVary: Accept\r\n", "one", start, 1000, null)).?;
    for ([_]Mode{ .normal, .force_cache, .only_if_cached, .no_cache }) |mode| {
        const lookup = cache.lookup(key, mode, start);
        defer cache.release(lookup.handle.?);
        try std.testing.expectEqual(if (mode == .no_cache) Action.revalidate else Action.hit, lookup.action);
        const view = cache.view(lookup.handle.?, start).?;
        try std.testing.expectEqual(id, view.identity);
        try std.testing.expectEqualStrings("one", view.body);
    }
    const late: Clock = .{ .monotonic_ms = 11000 };
    for ([_]Mode{ .normal, .force_cache, .only_if_cached }) |mode| {
        const lookup = cache.lookup(key, mode, late);
        defer cache.release(lookup.handle.?);
        try std.testing.expectEqual(if (mode == .normal) Action.revalidate else Action.hit, lookup.action);
    }
    try std.testing.expectEqual(Action.miss, cache.lookup(key, .no_store, start).action);
    try std.testing.expectEqual(Action.miss, cache.lookup(key, .reload, start).action);
    var variant = key;
    variant.headers = "GET /a HTTP/1.1\r\nHost: cache.example\r\nAccept: application/json\r\n";
    try std.testing.expectEqual(Action.miss, cache.lookup(variant, .normal, start).action);
    variant = key;
    variant.context = "origin=another.example;credentials=omit";
    try std.testing.expectEqual(Action.only_miss, cache.lookup(variant, .only_if_cached, start).action);
    try std.testing.expectEqual(@as(?u64, null), try cache.store(key, "Cache-Control: no-store\r\n", "two", start, 1000, null));
    try std.testing.expectEqual(Action.only_miss, cache.lookup(key, .only_if_cached, start).action);
    try std.testing.expectEqual(@as(?u64, null), try cache.store(key, "Vary: *\r\nCache-Control: max-age=60\r\n", "two", start, 1000, null));
}

test "response cache accounts age dates expiry and invalid freshness conservatively" {
    const date = parseDate("Tue, 08 Sep 2026 12:00:00 GMT").?;
    try std.testing.expectEqual(@as(u64, 1788868800), date);
    try std.testing.expectEqual(@as(?u64, null), parseDate("Sun, 29 Feb 2026 12:00:00 GMT"));
    const now: Clock = .{ .monotonic_ms = 1000, .unix_seconds = date + 4 };
    const aged = responsePolicy("Date: Tue, 08 Sep 2026 12:00:00 GMT\r\nAge: 6\r\nCache-Control: max-age=20\r\n", now, 800);
    try std.testing.expectEqual(@as(u64, 6200), aged.age_ms);
    try std.testing.expectEqual(@as(u64, 20000), aged.lifetime_ms);
    const expires = responsePolicy("Date: Tue, 08 Sep 2026 12:00:00 GMT\r\nExpires: Tue, 08 Sep 2026 12:01:00 GMT\r\n", now, 1000);
    try std.testing.expectEqual(@as(u64, 60000), expires.lifetime_ms);
    try std.testing.expect(responsePolicy("Cache-Control: max-age=20, max-age=30\r\n", now, 1000).validate);
    try std.testing.expect(responsePolicy("Cache-Control: no-cache, max-age=30\r\n", now, 1000).validate);
    try std.testing.expect(responsePolicy("Age: invalid\r\nCache-Control: max-age=30\r\n", now, 1000).validate);
}

test "response cache eviction and invalidation preserve borrowed bytes until release" {
    var cache = Cache.init(std.testing.allocator, .{ .object_bytes = 16, .total_bytes = 100 });
    defer cache.deinit();
    const key: Key = .{ .url = "a", .context = "", .headers = "" };
    const now: Clock = .{ .monotonic_ms = 0 };
    _ = try cache.store(key, "Cache-Control: max-age=10\r\n", "one", now, 0, null);
    const held = cache.lookup(key, .normal, now).handle.?;
    cache.invalidateUrl("a");
    try std.testing.expectEqual(Action.miss, cache.lookup(key, .normal, now).action);
    try std.testing.expectEqualStrings("one", cache.view(held, now).?.body);
    for ([_][]const u8{ "b", "c", "d", "e" }) |url| {
        _ = try cache.store(.{ .url = url, .context = "", .headers = "" }, "Cache-Control: max-age=10\r\n", "two", now, 0, null);
        try std.testing.expect(cache.bytes <= 100);
    }
    try std.testing.expect(cache.stats.evictions > 0);
    try std.testing.expectEqualStrings("one", cache.view(held, now).?.body);
    cache.release(held);
    try std.testing.expect(cache.view(held, now) == null);
    try std.testing.expectEqual(@as(?u64, null), try cache.store(key, "", "12345678901234567", now, 0, null));
}
