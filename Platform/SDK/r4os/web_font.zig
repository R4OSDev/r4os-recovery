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
            if (!renderable(info) or !self.support.has(info.id, codepoint)) continue;
            const family_penalty = familyPenalty(&info, wanted) orelse continue;
            const score = family_penalty +| faceScore(info, pixel_size, weight, italic);
            if (score < best_score or (score == best_score and (best == null or info.id < best.?.id))) {
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
            if (!renderable(info) or !self.support.has(info.id, codepoint)) continue;
            var score = faceScore(info, pixel_size, weight, italic);
            if ((info.flags & abi.gui_font_flag_builtin) != 0) score +|= 1_000_000;
            if (score < best_score or (score == best_score and (best == null or info.id < best.?.id))) {
                best = info;
                best_score = score;
            }
        }
        return best;
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
