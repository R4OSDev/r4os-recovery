const std = @import("std");
const abi = @import("r4os_contract").abi;

const font_style = struct {
    const monospace: u32 = 0x0000_0001;
    const italic: u32 = 0x0000_0002;
    const bold: u32 = 0x0000_0004;
};

pub const Face = struct {
    found: bool = false,
    id: u32 = abi.gui_font_builtin_id,
    height: i32 = 8,
    line_height: i32 = 8,
    baseline: i32 = 7,
    max_advance: i32 = 8,
};

pub const GlyphSupport = struct {
    context: ?*anyopaque = null,
    callback: ?*const fn (?*anyopaque, u32, u32) bool = null,

    pub fn has(self: GlyphSupport, font_id: u32, codepoint: ?u32) bool {
        const scalar = codepoint orelse return true;
        if (scalar == ' ' or scalar == 0x00A0) return true;
        const check = self.callback orelse return true;
        return check(self.context, font_id, scalar);
    }
};

pub const Catalog = struct {
    entries: []const abi.GuiFontInfo,
    support: GlyphSupport = .{},

    pub fn resolve(
        self: Catalog,
        family_list: []const u8,
        pixel_size: i32,
        weight: u16,
        italic: bool,
        codepoint: ?u32,
    ) Face {
        var cursor: usize = 0;
        var had_family = false;
        while (nextFamily(family_list, &cursor)) |family| {
            had_family = true;
            if (self.bestForFamily(family, pixel_size, weight, italic, codepoint)) |info| return faceFromInfo(info);
        }
        if (!had_family) {
            if (self.bestForFamily("sans-serif", pixel_size, weight, italic, codepoint)) |info| return faceFromInfo(info);
        }
        if (self.bestAvailable(pixel_size, weight, italic, codepoint)) |info| return faceFromInfo(info);
        return .{};
    }

    /// Resolves exactly one CSS family without falling through to an
    /// unrelated installed face.  Composite providers use this while
    /// walking a CSS fallback list that can also contain document fonts.
    pub fn resolveFamily(
        self: Catalog,
        family: []const u8,
        pixel_size: i32,
        weight: u16,
        italic: bool,
        codepoint: ?u32,
    ) ?Face {
        const info = self.bestForFamily(family, pixel_size, weight, italic, codepoint) orelse return null;
        return faceFromInfo(info);
    }

    /// Resolves the best installed fallback independently of a CSS family.
    pub fn resolveAvailable(
        self: Catalog,
        pixel_size: i32,
        weight: u16,
        italic: bool,
        codepoint: ?u32,
    ) Face {
        const info = self.bestAvailable(pixel_size, weight, italic, codepoint) orelse return .{};
        return faceFromInfo(info);
    }

    /// Resolves a previously selected installed face while still applying
    /// the current glyph-support contract.
    pub fn resolveId(self: Catalog, id: u32, codepoint: ?u32) ?Face {
        for (self.entries) |info| {
            if (info.id != id or !renderable(info) or !self.support.has(info.id, codepoint)) continue;
            return faceFromInfo(info);
        }
        return null;
    }

    fn bestForFamily(
        self: Catalog,
        wanted: []const u8,
        pixel_size: i32,
        weight: u16,
        italic: bool,
        codepoint: ?u32,
    ) ?abi.GuiFontInfo {
        var best: ?abi.GuiFontInfo = null;
        var best_score: u64 = std.math.maxInt(u64);
        for (self.entries) |info| {
            if (!renderable(info)) continue;
            const family_penalty = familyPenalty(&info, wanted) orelse continue;
            const score = family_penalty +| faceScore(info, pixel_size, weight, italic);
            if ((score < best_score or (score == best_score and (best == null or info.id < best.?.id))) and
                self.support.has(info.id, codepoint))
            {
                best = info;
                best_score = score;
            }
        }
        return best;
    }

    fn bestAvailable(
        self: Catalog,
        pixel_size: i32,
        weight: u16,
        italic: bool,
        codepoint: ?u32,
    ) ?abi.GuiFontInfo {
        var best: ?abi.GuiFontInfo = null;
        var best_score: u64 = std.math.maxInt(u64);
        for (self.entries) |info| {
            if (!renderable(info)) continue;
            var score = faceScore(info, pixel_size, weight, italic);
            if ((info.flags & abi.gui_font_flag_builtin) != 0) score +|= 1_000_000;
            if ((score < best_score or (score == best_score and (best == null or info.id < best.?.id))) and
                self.support.has(info.id, codepoint))
            {
                best = info;
                best_score = score;
            }
        }
        return best;
    }
};

/// A bounded four-way index for the installed-font owner's glyph answers.
/// Negative answers are cacheable; every entry carries its catalogue revision.
/// Hash collisions replace one bucket member and never change the answer.
pub const SupportCache = struct {
    const bucket_count = 128;
    const ways = 4;
    const Entry = struct { valid: bool = false, revision: u32 = 0, font_id: u32 = 0, codepoint: u32 = 0, supported: bool = false };
    entries: [bucket_count][ways]Entry = .{.{Entry{}} ** ways} ** bucket_count,
    cursors: [bucket_count]u2 = .{0} ** bucket_count,
    lookups: u64 = 0,
    probes: u64 = 0,
    misses: u64 = 0,

    fn bucket(revision: u32, font_id: u32, codepoint: u32) usize {
        return scalarHash(codepoint ^ (font_id *% 0x9e3779b9) ^ (revision *% 0x85ebca6b)) & (bucket_count - 1);
    }
    pub fn get(self: *SupportCache, revision: u32, font_id: u32, codepoint: u32) ?bool {
        self.lookups +|= 1;
        for (self.entries[bucket(revision, font_id, codepoint)]) |entry| {
            self.probes +|= 1;
            if (entry.valid and entry.revision == revision and entry.font_id == font_id and entry.codepoint == codepoint) return entry.supported;
        }
        self.misses +|= 1;
        return null;
    }
    pub fn put(self: *SupportCache, revision: u32, font_id: u32, codepoint: u32, supported: bool) void {
        const index = bucket(revision, font_id, codepoint);
        var slot: usize = self.cursors[index];
        for (self.entries[index], 0..) |entry, position| {
            if (!entry.valid or entry.revision != revision or (entry.font_id == font_id and entry.codepoint == codepoint)) {
                slot = position;
                break;
            }
        }
        self.entries[index][slot] = .{ .valid = true, .revision = revision, .font_id = font_id, .codepoint = codepoint, .supported = supported };
        self.cursors[index] = @truncate(slot + 1);
    }
};

/// One immutable family/style/provider scope. A repeated scalar reuses the
/// exact composite selection, including document fonts and missing glyphs.
/// A new run creates a fresh resolver; no borrowed style survives that scope.
pub fn RunResolver(comptime FaceType: type) type {
    return struct {
        const Self = @This();
        const Entry = struct { valid: bool = false, codepoint: u32 = 0, face: FaceType = .{} };
        context: ?*anyopaque = null,
        callback: *const fn (?*anyopaque, []const u8, i32, u16, bool, ?u32) FaceType,
        family: []const u8,
        size: i32,
        weight: u16,
        italic: bool,
        entries: [64]Entry = .{Entry{}} ** 64,
        calls: u64 = 0,
        hits: u64 = 0,

        pub fn resolve(self: *Self, codepoint: u32) FaceType {
            const entry = &self.entries[scalarHash(codepoint) & (self.entries.len - 1)];
            if (entry.valid and entry.codepoint == codepoint) {
                self.hits +|= 1;
                return entry.face;
            }
            self.calls +|= 1;
            const face = self.callback(self.context, self.family, self.size, self.weight, self.italic, codepoint);
            entry.* = .{ .valid = true, .codepoint = codepoint, .face = face };
            return face;
        }
    };
}

fn scalarHash(value: u32) u32 {
    var mixed = value;
    mixed ^= mixed >> 16;
    mixed *%= 0x7feb352d;
    mixed ^= mixed >> 15;
    mixed *%= 0x846ca68b;
    return mixed ^ (mixed >> 16);
}

/// Builds a caller-private enumeration. The caller publishes it only after a
/// nonzero revision matches before and after every successful metadata read.
pub const CatalogReader = struct {
    context: *anyopaque,
    revision: *const fn (*anyopaque) u32,
    count: *const fn (*anyopaque) usize,
    info: *const fn (*anyopaque, u32, *abi.GuiFontInfo) bool,
    pub const Snapshot = struct { count: usize, revision: u32 };

    pub fn read(self: CatalogReader, out: []abi.GuiFontInfo) ?Snapshot {
        for (0..2) |_| {
            const before = self.revision(self.context);
            if (before == 0) return null;
            const count = self.count(self.context);
            if (count > out.len) return null;
            var used: usize = 0;
            var valid = true;
            for (0..count) |index| {
                var entry: abi.GuiFontInfo = .{};
                if (!self.info(self.context, @intCast(index), &entry)) {
                    valid = false;
                    break;
                }
                if (!renderable(entry)) continue;
                out[used] = entry;
                used += 1;
            }
            if (valid and self.revision(self.context) == before) return .{ .count = used, .revision = before };
        }
        return null;
    }
};

pub fn nextFamily(list: []const u8, cursor: *usize) ?[]const u8 {
    while (cursor.* < list.len and (isSpace(list[cursor.*]) or list[cursor.*] == ',')) cursor.* += 1;
    if (cursor.* >= list.len) return null;
    const start = cursor.*;
    var quote: u8 = 0;
    while (cursor.* < list.len) : (cursor.* += 1) {
        const byte = list[cursor.*];
        if (quote != 0) {
            if (byte == '\\' and cursor.* + 1 < list.len) {
                cursor.* += 1;
            } else if (byte == quote) {
                quote = 0;
            }
            continue;
        }
        if (byte == '"' or byte == '\'') {
            quote = byte;
        } else if (byte == ',') {
            break;
        }
    }
    const end = cursor.*;
    if (cursor.* < list.len) cursor.* += 1;
    const value = trim(list[start..end]);
    if (value.len == 0) return nextFamily(list, cursor);
    return unquote(value);
}

pub fn familyMatches(info: *const abi.GuiFontInfo, wanted_input: []const u8) bool {
    return familyPenalty(info, wanted_input) != null;
}

fn familyPenalty(info: *const abi.GuiFontInfo, wanted_input: []const u8) ?u64 {
    const wanted = trim(unquote(wanted_input));
    const family = fixedSpan(info.family[0..]);
    const face = fixedSpan(info.face[0..]);
    if (equalsIgnoreCase(family, wanted) or equalsIgnoreCase(face, wanted)) return 0;
    if (equalsIgnoreCase(wanted, "monospace") or equalsIgnoreCase(wanted, "ui-monospace")) {
        return if ((info.style_flags & font_style.monospace) != 0 or
            containsIgnoreCase(family, "terminal") or containsIgnoreCase(family, "courier") or
            containsIgnoreCase(family, "modern") or containsIgnoreCase(face, "fixed")) 0 else null;
    }
    if (equalsIgnoreCase(wanted, "serif") or equalsIgnoreCase(wanted, "ui-serif")) {
        return if (containsIgnoreCase(family, "serif") or containsIgnoreCase(family, "times") or
            containsIgnoreCase(family, "roman")) 0 else null;
    }
    if (equalsIgnoreCase(wanted, "sans-serif") or equalsIgnoreCase(wanted, "system-ui") or
        equalsIgnoreCase(wanted, "ui-sans-serif"))
    {
        if (containsIgnoreCase(family, "r4 sans") or containsIgnoreCase(family, "sans") or
            containsIgnoreCase(family, "arial") or containsIgnoreCase(family, "helvetica") or
            containsIgnoreCase(family, "tahoma")) return 0;
        return if ((info.flags & abi.gui_font_flag_builtin) != 0) 1_000_000 else null;
    }
    if (equalsIgnoreCase(wanted, "cursive")) return if (containsIgnoreCase(family, "script") or containsIgnoreCase(family, "cursive")) 0 else null;
    if (equalsIgnoreCase(wanted, "fantasy")) return if (containsIgnoreCase(family, "decorative") or containsIgnoreCase(family, "fantasy")) 0 else null;
    return null;
}

fn renderable(info: abi.GuiFontInfo) bool {
    return (info.flags & abi.gui_font_flag_renderable) != 0;
}

fn faceScore(info: abi.GuiFontInfo, pixel_size: i32, weight: u16, italic: bool) u64 {
    const requested_height: u32 = @intCast(@max(1, pixel_size));
    const height_delta = absoluteDifference(info.height, requested_height);
    const weight_delta = absoluteDifference(info.weight, weight);
    const face_italic = (info.style_flags & font_style.italic) != 0;
    const italic_penalty: u64 = if (face_italic == italic) 0 else 100_000;
    return italic_penalty + @as(u64, height_delta) * 4096 + @as(u64, weight_delta) * 4;
}

fn faceFromInfo(info: abi.GuiFontInfo) Face {
    return .{
        .found = true,
        .id = info.id,
        .height = @intCast(@max(@as(u32, 1), info.height)),
        .line_height = @intCast(@max(@as(u32, 1), info.line_height)),
        .baseline = @max(0, info.baseline),
        .max_advance = @intCast(@max(@as(u32, 1), info.max_advance)),
    };
}

fn absoluteDifference(left: u32, right_input: anytype) u32 {
    const right: u32 = @intCast(right_input);
    return if (left >= right) left - right else right - left;
}

fn fixedSpan(buffer: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buffer.len and buffer[len] != 0) : (len += 1) {}
    return buffer[0..len];
}

fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isSpace(value[start])) start += 1;
    while (end > start and isSpace(value[end - 1])) end -= 1;
    return value[start..end];
}

fn unquote(value: []const u8) []const u8 {
    if (value.len >= 2 and ((value[0] == '"' and value[value.len - 1] == '"') or
        (value[0] == '\'' and value[value.len - 1] == '\'')))
    {
        return value[1 .. value.len - 1];
    }
    return value;
}

fn isSpace(value: u8) bool {
    return value == ' ' or value == '\t' or value == '\r' or value == '\n' or value == 0x0C;
}

fn equalsIgnoreCase(left: []const u8, right: []const u8) bool {
    return std.ascii.eqlIgnoreCase(left, right);
}

fn containsIgnoreCase(value: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    var cursor: usize = 0;
    while (cursor + needle.len <= value.len) : (cursor += 1) {
        if (equalsIgnoreCase(value[cursor .. cursor + needle.len], needle)) return true;
    }
    return false;
}

fn setFixed(out: []u8, value: []const u8) void {
    @memset(out, 0);
    const count = @min(out.len -| 1, value.len);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
}

fn testFont(id: u32, family: []const u8, height: u32, weight: u32, style_flags: u32) abi.GuiFontInfo {
    var info = abi.GuiFontInfo{
        .id = id,
        .flags = abi.gui_font_flag_renderable,
        .height = height,
        .line_height = height + 2,
        .baseline = @intCast(height -| 2),
        .max_advance = @max(1, height / 2),
        .weight = weight,
        .style_flags = style_flags,
    };
    setFixed(info.family[0..], family);
    setFixed(info.face[0..], family);
    return info;
}

test "font family iterator preserves quoted names and fallback order" {
    var cursor: usize = 0;
    const list = "  'Missing Font', \"R4 Sans\" , sans-serif";
    try std.testing.expectEqualStrings("Missing Font", nextFamily(list, &cursor).?);
    try std.testing.expectEqualStrings("R4 Sans", nextFamily(list, &cursor).?);
    try std.testing.expectEqualStrings("sans-serif", nextFamily(list, &cursor).?);
    try std.testing.expect(nextFamily(list, &cursor) == null);
}

test "catalog resolves ordered families native sizes weights and styles" {
    var entries = [_]abi.GuiFontInfo{
        testFont(0, "R4OS", 8, 400, 0),
        testFont(1, "Terminal", 16, 400, font_style.monospace),
        testFont(2, "R4 Sans", 12, 400, 0),
        testFont(3, "R4 Sans", 16, 700, font_style.bold),
        testFont(4, "R4 Sans", 16, 400, font_style.italic),
    };
    entries[0].flags |= abi.gui_font_flag_builtin;
    const catalog = Catalog{ .entries = entries[0..] };
    try std.testing.expectEqual(@as(u32, 3), catalog.resolve("Missing, 'R4 Sans', sans-serif", 16, 700, false, null).id);
    try std.testing.expectEqual(@as(u32, 4), catalog.resolve("system-ui", 16, 400, true, null).id);
    try std.testing.expectEqual(@as(u32, 1), catalog.resolve("monospace", 16, 400, false, null).id);
    try std.testing.expectEqual(@as(u32, 2), catalog.resolve("R4 Sans", 13, 400, false, null).id);
}

test "generic sans prefers a proportional system face over the builtin fallback" {
    var entries = [_]abi.GuiFontInfo{
        testFont(0, "R4OS", 8, 400, 0),
        testFont(2, "R4 Sans", 8, 400, 0),
    };
    entries[0].flags |= abi.gui_font_flag_builtin;
    const catalog = Catalog{ .entries = entries[0..] };
    try std.testing.expectEqual(@as(u32, 2), catalog.resolve("system-ui, sans-serif", 8, 400, false, null).id);
    try std.testing.expectEqual(@as(u32, 0), catalog.resolve("R4OS, sans-serif", 8, 400, false, null).id);
}

const TestSupport = struct {
    denied: u32,
};

fn testGlyphSupport(context: ?*anyopaque, font_id: u32, codepoint: u32) bool {
    _ = codepoint;
    const state: *const TestSupport = @ptrCast(@alignCast(context.?));
    return font_id != state.denied;
}

test "catalog advances through family list when a face lacks a glyph" {
    var entries = [_]abi.GuiFontInfo{
        testFont(1, "R4 Sans", 16, 400, 0),
        testFont(2, "Terminal", 16, 400, font_style.monospace),
    };
    var support = TestSupport{ .denied = 1 };
    const catalog = Catalog{
        .entries = entries[0..],
        .support = .{ .context = &support, .callback = testGlyphSupport },
    };
    try std.testing.expectEqual(@as(u32, 2), catalog.resolve("R4 Sans, monospace", 16, 400, false, 0x2605).id);
}

test "catalog exposes exact-family and final-fallback resolution" {
    var entries = [_]abi.GuiFontInfo{
        testFont(1, "R4 Sans", 16, 400, 0),
        testFont(2, "Terminal", 16, 400, font_style.monospace),
    };
    const catalog = Catalog{ .entries = entries[0..] };
    try std.testing.expect(catalog.resolveFamily("Missing", 16, 400, false, null) == null);
    try std.testing.expectEqual(@as(u32, 2), catalog.resolveFamily("monospace", 16, 400, false, null).?.id);
    try std.testing.expectEqual(@as(u32, 1), catalog.resolveAvailable(16, 400, false, null).id);
    try std.testing.expectEqual(@as(u32, 2), catalog.resolveId(2, null).?.id);
    try std.testing.expect(catalog.resolveId(99, null) == null);
}

const IndexedSupportFixture = struct {
    cache: SupportCache = .{},
    revision: u32 = 7,
    glyph_queries: u64 = 0,
    entries: [65]abi.GuiFontInfo = undefined,
    fn init() @This() {
        var self: @This() = .{};
        for (&self.entries, 0..) |*entry, i| entry.* = testFont(@intCast(i), if (i == 64) "Latin" else if (i == 63) "Greek" else "Unrelated", 16, 400, 0);
        self.entries[0].flags |= abi.gui_font_flag_builtin;
        return self;
    }
    fn supports(context: ?*anyopaque, font_id: u32, codepoint: u32) bool {
        const self: *@This() = @ptrCast(@alignCast(context.?));
        if (self.cache.get(self.revision, font_id, codepoint)) |hit| return hit;
        self.glyph_queries += 1;
        const value = (font_id == 64 and codepoint == 'A') or (font_id == 63 and codepoint == 0x03A9);
        self.cache.put(self.revision, font_id, codepoint, value);
        return value;
    }
    fn catalog(self: *@This()) Catalog {
        return .{ .entries = &self.entries, .support = .{ .context = self, .callback = supports } };
    }
    fn resolve(context: ?*anyopaque, family: []const u8, size: i32, weight: u16, italic: bool, codepoint: ?u32) Face {
        const self: *@This() = @ptrCast(@alignCast(context.?));
        return self.catalog().resolve(family, size, weight, italic, codepoint);
    }
};

test "indexed warm mixed run preserves fallback and missing glyphs with bounded probes" {
    var fixture = IndexedSupportFixture.init();
    const scalars = [_]u32{ 'A', 0x03A9, 0x10FFFF };
    const expected = [_]u32{ 64, 63, 0 };
    for (scalars, expected) |cp, id| try std.testing.expectEqual(id, fixture.catalog().resolve("Latin, Greek", 16, 400, false, cp).id);
    fixture.cache.lookups = 0;
    fixture.cache.probes = 0;
    fixture.cache.misses = 0;
    fixture.glyph_queries = 0;
    var run: RunResolver(Face) = .{ .context = &fixture, .callback = IndexedSupportFixture.resolve, .family = "Latin, Greek", .size = 16, .weight = 400, .italic = false };
    for (0..16) |_| for (scalars, expected) |cp, id| {
        const face = run.resolve(cp);
        try std.testing.expectEqual(id, face.id);
        try std.testing.expectEqual(cp != 0x10FFFF, face.found);
    };
    try std.testing.expectEqual(@as(u64, 3), run.calls);
    try std.testing.expectEqual(@as(u64, 45), run.hits);
    try std.testing.expectEqual(@as(u64, 0), fixture.glyph_queries);
    try std.testing.expect(fixture.cache.probes <= fixture.cache.lookups * 4);
    std.debug.print("GLYPHWORK scalars=48 resolutions={d} lookups={d} probes={d} glyph_queries={d}\n", .{ run.calls, fixture.cache.lookups, fixture.cache.probes, fixture.glyph_queries });
    const before = fixture.glyph_queries;
    fixture.revision += 1;
    _ = fixture.catalog().resolve("Latin", 16, 400, false, 'A');
    try std.testing.expectEqual(before + 1, fixture.glyph_queries);
}

test "glyph support hash collisions retain negative identity and revision semantics" {
    var cache: SupportCache = .{};
    var collision: [5]u32 = undefined;
    var used: usize = 0;
    var scalar: u32 = 0;
    const bucket = SupportCache.bucket(4, 3, 0);
    while (used < collision.len) : (scalar += 1) {
        if (SupportCache.bucket(4, 3, scalar) != bucket) continue;
        collision[used] = scalar;
        used += 1;
    }
    for (collision, 0..) |cp, i| cache.put(4, 3, cp, i % 2 == 0);
    try std.testing.expect(cache.get(4, 3, collision[0]) == null);
    for (collision[1..], 1..) |cp, i| try std.testing.expectEqual(@as(?bool, i % 2 == 0), cache.get(4, 3, cp));
    try std.testing.expect(cache.get(5, 3, collision[1]) == null);
    try std.testing.expect(cache.get(4, 4, collision[1]) == null);
}

test "catalogue enumeration retries a revision change and rejects incomplete metadata" {
    const Fixture = struct {
        version: u32 = 1,
        calls: usize = 0,
        fail: bool = false,
        fn cast(p: *anyopaque) *@This() {
            return @ptrCast(@alignCast(p));
        }
        fn revision(p: *anyopaque) u32 {
            return cast(p).version;
        }
        fn count(_: *anyopaque) usize {
            return 2;
        }
        fn info(p: *anyopaque, index: u32, out: *abi.GuiFontInfo) bool {
            const self = cast(p);
            self.calls += 1;
            if (self.fail and index == 1) return false;
            out.* = testFont(index, if (self.version == 1) "Old" else "New", 16, 400, 0);
            if (self.version == 1) self.version = 2;
            return true;
        }
    };
    var fixture: Fixture = .{};
    const reader: CatalogReader = .{ .context = &fixture, .revision = Fixture.revision, .count = Fixture.count, .info = Fixture.info };
    var pending: [2]abi.GuiFontInfo = undefined;
    const result = reader.read(&pending).?;
    try std.testing.expectEqual(@as(u32, 2), result.revision);
    try std.testing.expectEqual(@as(usize, 2), result.count);
    try std.testing.expectEqual(@as(usize, 4), fixture.calls);
    for (pending) |entry| try std.testing.expectEqualStrings("New", fixedSpan(&entry.family));
    fixture.fail = true;
    fixture.calls = 0;
    try std.testing.expect(reader.read(&pending) == null);
    try std.testing.expectEqual(@as(usize, 4), fixture.calls);
}
