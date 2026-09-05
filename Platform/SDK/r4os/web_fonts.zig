const std = @import("std");

pub const max_stylesheet_bytes: usize = 256 * 1024;
pub const max_faces: usize = 64;
pub const max_source_sections: usize = max_faces;
pub const max_sources: usize = 256;
pub const max_sources_per_face: usize = 16;
pub const max_unicode_ranges: usize = 512;
pub const max_unicode_ranges_per_face: usize = 32;
pub const max_descriptors_per_face: usize = 64;
pub const max_string_bytes: usize = 64 * 1024;
pub const max_family_bytes: usize = 256;
pub const max_source_value_bytes: usize = 2048;
pub const max_format_bytes: usize = 64;
pub const max_base_url_bytes: usize = 2048;
pub const max_family_list_bytes: usize = 4096;
pub const max_text_run_bytes: usize = 64 * 1024;
pub const max_css_depth: usize = 32;

pub const Error = error{
    StylesheetTooLarge,
    SourceSectionLimit,
    FaceLimit,
    SourceLimit,
    UnicodeRangeLimit,
    DescriptorLimit,
    StringLimit,
    CssDepthLimit,
    FamilyListTooLong,
    TextRunTooLong,
    OutputLimit,
};

pub const StringRef = struct {
    offset: u32 = 0,
    len: u32 = 0,

    pub fn bytes(self: StringRef, storage: []const u8) []const u8 {
        const start: usize = self.offset;
        const length: usize = self.len;
        if (start > storage.len or length > storage.len - start) return "";
        return storage[start .. start + length];
    }
};

pub const SourceKind = enum(u8) {
    local,
    url,
};

pub const FontFormat = enum(u8) {
    unspecified,
    woff2,
    woff,
    truetype,
    opentype,
    embedded_opentype,
    collection,
    svg,
    unknown,

    pub fn loadable(self: FontFormat) bool {
        return self == .unspecified or self == .woff2 or self == .woff or self == .truetype or self == .opentype;
    }
};

pub const FontSource = struct {
    kind: SourceKind = .url,
    value: StringRef = .{},
    format: FontFormat = .unspecified,
    format_label: StringRef = .{},
};

pub const FontStyle = enum(u8) {
    normal,
    italic,
    oblique,
};

pub const StyleRange = struct {
    auto: bool = false,
    kind: FontStyle = .normal,
    min_angle_tenth: i16 = 0,
    max_angle_tenth: i16 = 0,
};

pub const WeightRange = struct {
    auto: bool = false,
    min: u16 = 400,
    max: u16 = 400,

    pub fn contains(self: WeightRange, value: u16) bool {
        return value >= self.min and value <= self.max;
    }
};

/// Percentage in hundredths: 10000 means 100%, 6250 means 62.5%.
pub const StretchRange = struct {
    auto: bool = false,
    min_hundred: u32 = 10_000,
    max_hundred: u32 = 10_000,

    pub fn contains(self: StretchRange, value: u32) bool {
        return value >= self.min_hundred and value <= self.max_hundred;
    }
};

pub const UnicodeRange = struct {
    first: u32 = 0,
    last: u32 = 0x10FFFF,

    pub fn contains(self: UnicodeRange, codepoint: u32) bool {
        return codepoint >= self.first and codepoint <= self.last;
    }
};

pub const FontDisplay = enum(u8) {
    auto,
    block,
    swap,
    fallback,
    optional,
};

pub const Face = struct {
    family: StringRef = .{},
    source_start: u16 = 0,
    source_count: u8 = 0,
    unicode_range_start: u16 = 0,
    unicode_range_count: u8 = 0,
    weight: WeightRange = .{},
    style: StyleRange = .{},
    stretch: StretchRange = .{},
    display: FontDisplay = .auto,
    source_section: u8 = 0,
    rule_offset: u32 = 0,
};

pub const SourceSection = struct {
    final_base_url: StringRef = .{},
    face_start: u16 = 0,
    face_count: u16 = 0,
};

pub const ParseStats = struct {
    faces_added: usize = 0,
    invalid_faces: usize = 0,
    source_sections: usize = 0,
};

pub const MatchRequest = struct {
    family_list: []const u8,
    text: []const u8,
    weight: u16 = 400,
    style: FontStyle = .normal,
    oblique_angle_tenth: i16 = 140,
    stretch_hundred: u32 = 10_000,
};

pub const FaceMatch = struct {
    document_id: u64,
    face_index: u16,
};

pub const NeededRun = struct {
    match: FaceMatch,
    byte_start: u32,
    byte_len: u32,
};

pub const NeededRunIterator = struct {
    registry: *const Registry,
    request: MatchRequest,
    cursor: usize = 0,

    pub fn next(self: *NeededRunIterator) ?NeededRun {
        while (self.cursor < self.request.text.len) {
            const start = self.cursor;
            const decoded = decodeScalar(self.request.text, self.cursor);
            self.cursor += decoded.len;
            const first_match = self.registry.matchCodepoint(self.request, decoded.codepoint) orelse continue;
            var end = self.cursor;
            while (end < self.request.text.len) {
                const following = decodeScalar(self.request.text, end);
                const following_match = self.registry.matchCodepoint(self.request, following.codepoint);
                if (following_match == null or following_match.?.face_index != first_match.face_index) break;
                end += following.len;
            }
            self.cursor = end;
            return .{
                .match = first_match,
                .byte_start = @intCast(start),
                .byte_len = @intCast(end - start),
            };
        }
        return null;
    }
};

pub const Registry = struct {
    document_id: u64 = 0,
    strings: [max_string_bytes]u8 = undefined,
    faces: [max_faces]Face = undefined,
    sources: [max_sources]FontSource = undefined,
    unicode_ranges: [max_unicode_ranges]UnicodeRange = undefined,
    source_sections: [max_source_sections]SourceSection = undefined,
    string_len: usize = 0,
    face_count: usize = 0,
    source_count: usize = 0,
    unicode_range_count: usize = 0,
    source_section_count: usize = 0,

    pub fn beginDocument(self: *Registry, document_id: u64) void {
        self.document_id = document_id;
        self.string_len = 0;
        self.face_count = 0;
        self.source_count = 0;
        self.unicode_range_count = 0;
        self.source_section_count = 0;
    }

    pub fn appendStylesheet(self: *Registry, source: []const u8, final_base_url: []const u8) Error!ParseStats {
        if (source.len > max_stylesheet_bytes) return error.StylesheetTooLarge;
        if (final_base_url.len > max_base_url_bytes) return error.StringLimit;
        if (self.source_section_count >= self.source_sections.len) return error.SourceSectionLimit;

        const old_string_len = self.string_len;
        const old_face_count = self.face_count;
        const old_source_count = self.source_count;
        const old_range_count = self.unicode_range_count;
        const old_section_count = self.source_section_count;
        errdefer {
            self.string_len = old_string_len;
            self.face_count = old_face_count;
            self.source_count = old_source_count;
            self.unicode_range_count = old_range_count;
            self.source_section_count = old_section_count;
        }

        const base_ref = try self.store(final_base_url);
        const section_index = self.source_section_count;
        self.source_sections[section_index] = .{
            .final_base_url = base_ref,
            .face_start = @intCast(self.face_count),
        };
        self.source_section_count += 1;

        var stats = ParseStats{ .source_sections = 1 };
        var cursor: usize = 0;
        while (try nextFontFaceRule(source, &cursor)) |rule| {
            if (!rule.closed) {
                stats.invalid_faces += 1;
                break;
            }
            var parsed = ParsedFace{};
            parseFace(rule.body, &parsed) catch |err| switch (err) {
                error.InvalidFace => {
                    stats.invalid_faces += 1;
                    continue;
                },
                else => return @errorCast(err),
            };
            try self.commitFace(&parsed, @intCast(section_index), @intCast(rule.offset));
            stats.faces_added += 1;
        }
        self.source_sections[section_index].face_count = @intCast(self.face_count - old_face_count);
        return stats;
    }

    pub fn family(self: *const Registry, face_index: usize) []const u8 {
        if (face_index >= self.face_count) return "";
        return self.faces[face_index].family.bytes(self.strings[0..self.string_len]);
    }

    pub fn sourceValue(self: *const Registry, source_index: usize) []const u8 {
        if (source_index >= self.source_count) return "";
        return self.sources[source_index].value.bytes(self.strings[0..self.string_len]);
    }

    pub fn sourceFormatLabel(self: *const Registry, source_index: usize) []const u8 {
        if (source_index >= self.source_count) return "";
        return self.sources[source_index].format_label.bytes(self.strings[0..self.string_len]);
    }

    pub fn sectionBaseUrl(self: *const Registry, section_index: usize) []const u8 {
        if (section_index >= self.source_section_count) return "";
        return self.source_sections[section_index].final_base_url.bytes(self.strings[0..self.string_len]);
    }

    pub fn faceSource(self: *const Registry, face_index: usize, fallback_index: usize) ?FontSource {
        if (face_index >= self.face_count) return null;
        const face = self.faces[face_index];
        if (fallback_index >= face.source_count) return null;
        return self.sources[@as(usize, face.source_start) + fallback_index];
    }

    pub fn neededRuns(self: *const Registry, request: MatchRequest) Error!NeededRunIterator {
        if (request.family_list.len > max_family_list_bytes) return error.FamilyListTooLong;
        if (request.text.len > max_text_run_bytes) return error.TextRunTooLong;
        return .{ .registry = self, .request = request };
    }

    pub fn collectNeededFaces(self: *const Registry, request: MatchRequest, out: []u16) Error!usize {
        var iterator = try self.neededRuns(request);
        var count: usize = 0;
        while (iterator.next()) |run| {
            var present = false;
            for (out[0..count]) |face_index| {
                if (face_index == run.match.face_index) {
                    present = true;
                    break;
                }
            }
            if (present) continue;
            if (count >= out.len) return error.OutputLimit;
            out[count] = run.match.face_index;
            count += 1;
        }
        return count;
    }

    pub fn matchCodepoint(self: *const Registry, request: MatchRequest, codepoint: u32) ?FaceMatch {
        var family_cursor: usize = 0;
        var family_buffer: [max_family_bytes]u8 = undefined;
        while (nextFamilyName(request.family_list, &family_cursor, family_buffer[0..])) |wanted| {
            if (self.matchFamilyCodepoint(wanted, request, codepoint)) |match| return match;
        }
        return null;
    }

    /// Matches one already-parsed CSS family without advancing to a later
    /// fallback.  A document font provider uses this to interleave active
    /// web faces and installed faces while preserving the authored order.
    pub fn matchFamilyCodepoint(
        self: *const Registry,
        wanted: []const u8,
        request: MatchRequest,
        codepoint: ?u32,
    ) ?FaceMatch {
        var best: ?usize = null;
        var best_score: CandidateScore = .{};
        var index: usize = 0;
        while (index < self.face_count) : (index += 1) {
            const face = self.faces[index];
            if (!std.ascii.eqlIgnoreCase(self.family(index), wanted) or
                (codepoint != null and !self.faceCovers(face, codepoint.?))) continue;
            const score = scoreFace(face, request, @intCast(index));
            if (best == null or score.lessThan(best_score)) {
                best = index;
                best_score = score;
            }
        }
        const face_index = best orelse return null;
        return .{ .document_id = self.document_id, .face_index = @intCast(face_index) };
    }

    fn faceCovers(self: *const Registry, face: Face, codepoint: u32) bool {
        if (face.unicode_range_count == 0) return codepoint <= 0x10FFFF;
        const start: usize = face.unicode_range_start;
        const end = start + face.unicode_range_count;
        for (self.unicode_ranges[start..end]) |range| {
            if (range.contains(codepoint)) return true;
        }
        return false;
    }

    fn commitFace(self: *Registry, parsed: *const ParsedFace, section: u8, rule_offset: u32) Error!void {
        if (self.face_count >= self.faces.len) return error.FaceLimit;
        if (parsed.source_count > self.sources.len - self.source_count) return error.SourceLimit;
        if (parsed.range_count > self.unicode_ranges.len - self.unicode_range_count) return error.UnicodeRangeLimit;

        var required = parsed.family_len;
        for (parsed.sources[0..parsed.source_count]) |source| required += source.value_len + source.format_len;
        if (required > self.strings.len - self.string_len) return error.StringLimit;

        const family_ref = try self.store(parsed.family[0..parsed.family_len]);
        const source_start = self.source_count;
        for (parsed.sources[0..parsed.source_count]) |source| {
            self.sources[self.source_count] = .{
                .kind = source.kind,
                .value = try self.store(source.value[0..source.value_len]),
                .format = source.format,
                .format_label = try self.store(source.format_label[0..source.format_len]),
            };
            self.source_count += 1;
        }
        const range_start = self.unicode_range_count;
        for (parsed.ranges[0..parsed.range_count]) |range| {
            self.unicode_ranges[self.unicode_range_count] = range;
            self.unicode_range_count += 1;
        }
        self.faces[self.face_count] = .{
            .family = family_ref,
            .source_start = @intCast(source_start),
            .source_count = @intCast(parsed.source_count),
            .unicode_range_start = @intCast(range_start),
            .unicode_range_count = @intCast(parsed.range_count),
            .weight = parsed.weight,
            .style = parsed.style,
            .stretch = parsed.stretch,
            .display = parsed.display,
            .source_section = section,
            .rule_offset = rule_offset,
        };
        self.face_count += 1;
    }

    fn store(self: *Registry, value: []const u8) Error!StringRef {
        if (value.len == 0) return .{};
        if (value.len > self.strings.len - self.string_len) return error.StringLimit;
        const start = self.string_len;
        @memcpy(self.strings[start .. start + value.len], value);
        self.string_len += value.len;
        return .{ .offset = @intCast(start), .len = @intCast(value.len) };
    }
};

const ParsedSource = struct {
    kind: SourceKind = .url,
    value: [max_source_value_bytes]u8 = undefined,
    value_len: usize = 0,
    format: FontFormat = .unspecified,
    format_label: [max_format_bytes]u8 = undefined,
    format_len: usize = 0,
};

const ParsedFace = struct {
    family: [max_family_bytes]u8 = undefined,
    family_len: usize = 0,
    sources: [max_sources_per_face]ParsedSource = undefined,
    source_count: usize = 0,
    ranges: [max_unicode_ranges_per_face]UnicodeRange = undefined,
    range_count: usize = 0,
    weight: WeightRange = .{},
    style: StyleRange = .{},
    stretch: StretchRange = .{},
    display: FontDisplay = .auto,
};

const RuleSpan = struct {
    body: []const u8,
    offset: usize,
    closed: bool,
};

const FaceParseError = Error || error{InvalidFace};

const OrderedDistance = struct {
    group: u8 = std.math.maxInt(u8),
    distance: u32 = std.math.maxInt(u32),

    fn lessThan(self: OrderedDistance, other: OrderedDistance) bool {
        return self.group < other.group or (self.group == other.group and self.distance < other.distance);
    }
};

const CandidateScore = struct {
    stretch: OrderedDistance = .{},
    style: OrderedDistance = .{},
    weight: OrderedDistance = .{},
    declaration: u16 = std.math.maxInt(u16),

    fn lessThan(self: CandidateScore, other: CandidateScore) bool {
        if (self.stretch.group != other.stretch.group) return self.stretch.group < other.stretch.group;
        if (self.stretch.distance != other.stretch.distance) return self.stretch.distance < other.stretch.distance;
        if (self.style.group != other.style.group) return self.style.group < other.style.group;
        if (self.style.distance != other.style.distance) return self.style.distance < other.style.distance;
        if (self.weight.group != other.weight.group) return self.weight.group < other.weight.group;
        if (self.weight.distance != other.weight.distance) return self.weight.distance < other.weight.distance;
        return self.declaration < other.declaration;
    }
};

fn scoreFace(face: Face, request: MatchRequest, declaration: u16) CandidateScore {
    return .{
        .stretch = stretchDistance(face.stretch, request.stretch_hundred),
        .style = styleDistance(face.style, request.style, request.oblique_angle_tenth),
        .weight = weightDistance(face.weight, request.weight),
        .declaration = declaration,
    };
}

fn stretchDistance(range: StretchRange, requested: u32) OrderedDistance {
    if (range.auto) return .{ .group = 1, .distance = 0 };
    if (range.contains(requested)) return .{ .group = 0, .distance = 0 };
    if (requested <= 10_000) {
        if (range.max_hundred < requested) return .{ .group = 1, .distance = requested - range.max_hundred };
        return .{ .group = 2, .distance = range.min_hundred - requested };
    }
    if (range.min_hundred > requested) return .{ .group = 1, .distance = range.min_hundred - requested };
    return .{ .group = 2, .distance = requested - range.max_hundred };
}

fn styleDistance(range: StyleRange, requested: FontStyle, requested_angle: i16) OrderedDistance {
    if (range.auto) return .{ .group = 1, .distance = 0 };
    if (range.kind == requested) {
        if (requested != .oblique) return .{ .group = 0, .distance = 0 };
        const clamped = clampI16(requested_angle, range.min_angle_tenth, range.max_angle_tenth);
        return .{ .group = 0, .distance = absoluteI16Difference(clamped, requested_angle) };
    }
    return switch (requested) {
        .normal => if (range.kind == .oblique) .{ .group = 1, .distance = absoluteI16Difference(range.min_angle_tenth, 0) } else .{ .group = 2, .distance = 0 },
        .italic => if (range.kind == .oblique) .{ .group = 1, .distance = absoluteI16Difference(range.min_angle_tenth, 140) } else .{ .group = 2, .distance = 0 },
        .oblique => if (range.kind == .italic) .{ .group = 1, .distance = 0 } else .{ .group = 2, .distance = 0 },
    };
}

fn weightDistance(range: WeightRange, requested: u16) OrderedDistance {
    if (range.auto) return .{ .group = 1, .distance = 0 };
    if (range.contains(requested)) return .{ .group = 0, .distance = 0 };
    if (requested >= 400 and requested <= 500) {
        if (range.min > requested and range.min <= 500) return .{ .group = 1, .distance = range.min - requested };
        if (range.max < requested) return .{ .group = 2, .distance = requested - range.max };
        return .{ .group = 3, .distance = range.min - requested };
    }
    if (requested < 400) {
        if (range.max < requested) return .{ .group = 1, .distance = requested - range.max };
        return .{ .group = 2, .distance = range.min - requested };
    }
    if (range.min > requested) return .{ .group = 1, .distance = range.min - requested };
    return .{ .group = 2, .distance = requested - range.max };
}

fn clampI16(value: i16, minimum: i16, maximum: i16) i16 {
    return @max(minimum, @min(maximum, value));
}

fn absoluteI16Difference(left: i16, right: i16) u32 {
    const left_wide: i32 = left;
    const right_wide: i32 = right;
    return @intCast(@abs(left_wide - right_wide));
}

const DecodedScalar = struct {
    codepoint: u32,
    len: usize,
};

fn decodeScalar(value: []const u8, start: usize) DecodedScalar {
    if (start >= value.len) return .{ .codepoint = 0xFFFD, .len = 0 };
    const sequence_length: usize = std.unicode.utf8ByteSequenceLength(value[start]) catch return .{ .codepoint = 0xFFFD, .len = 1 };
    if (sequence_length > value.len - start) return .{ .codepoint = 0xFFFD, .len = 1 };
    const codepoint = std.unicode.utf8Decode(value[start .. start + sequence_length]) catch return .{ .codepoint = 0xFFFD, .len = 1 };
    return .{ .codepoint = codepoint, .len = sequence_length };
}

fn nextFamilyName(list: []const u8, cursor: *usize, out: []u8) ?[]const u8 {
    while (cursor.* < list.len and (isCssSpace(list[cursor.*]) or list[cursor.*] == ',')) cursor.* += 1;
    while (cursor.* < list.len) {
        const start = cursor.*;
        var quote: u8 = 0;
        var escaped = false;
        while (cursor.* < list.len) : (cursor.* += 1) {
            const byte = list[cursor.*];
            if (quote != 0) {
                if (escaped) {
                    escaped = false;
                } else if (byte == '\\') {
                    escaped = true;
                } else if (byte == quote) {
                    quote = 0;
                }
                continue;
            }
            if (byte == '\'' or byte == '"') {
                quote = byte;
            } else if (byte == ',') {
                break;
            }
        }
        const raw = trimCss(list[start..cursor.*]);
        if (cursor.* < list.len) cursor.* += 1;
        const decoded = decodeCssName(raw, out) catch {
            while (cursor.* < list.len and (isCssSpace(list[cursor.*]) or list[cursor.*] == ',')) cursor.* += 1;
            continue;
        };
        if (decoded.len > 0) return decoded;
        while (cursor.* < list.len and (isCssSpace(list[cursor.*]) or list[cursor.*] == ',')) cursor.* += 1;
    }
    return null;
}

fn nextFontFaceRule(source: []const u8, cursor: *usize) Error!?RuleSpan {
    while (cursor.* < source.len) {
        if (startsComment(source, cursor.*)) {
            cursor.* = skipComment(source, cursor.*);
            continue;
        }
        if (source[cursor.*] == '\'' or source[cursor.*] == '"') {
            cursor.* = skipQuoted(source, cursor.*);
            continue;
        }
        if (source[cursor.*] != '@' or !startsWithIgnoreCaseAt(source, cursor.* + 1, "font-face")) {
            cursor.* += 1;
            continue;
        }
        const rule_offset = cursor.*;
        var after = cursor.* + 1 + "font-face".len;
        if (after < source.len and isNameByte(source[after])) {
            cursor.* += 1;
            continue;
        }
        skipCssTrivia(source, &after);
        if (after >= source.len or source[after] != '{') {
            cursor.* = after;
            continue;
        }
        const open = after;
        var scan = open + 1;
        var depth: usize = 1;
        while (scan < source.len) {
            if (startsComment(source, scan)) {
                scan = skipComment(source, scan);
                continue;
            }
            if (source[scan] == '\'' or source[scan] == '"') {
                scan = skipQuoted(source, scan);
                continue;
            }
            if (source[scan] == '{') {
                depth += 1;
                if (depth > max_css_depth) return error.CssDepthLimit;
            } else if (source[scan] == '}') {
                depth -= 1;
                if (depth == 0) {
                    cursor.* = scan + 1;
                    return .{ .body = source[open + 1 .. scan], .offset = rule_offset, .closed = true };
                }
            }
            scan += 1;
        }
        cursor.* = source.len;
        return .{ .body = source[open + 1 ..], .offset = rule_offset, .closed = false };
    }
    return null;
}

const Declaration = struct {
    name: []const u8,
    value: []const u8,
};

fn nextDeclaration(body: []const u8, cursor: *usize) Error!?Declaration {
    while (cursor.* < body.len) {
        skipCssTrivia(body, cursor);
        while (cursor.* < body.len and body[cursor.*] == ';') {
            cursor.* += 1;
            skipCssTrivia(body, cursor);
        }
        if (cursor.* >= body.len) return null;

        const start = cursor.*;
        var colon: ?usize = null;
        var quote: u8 = 0;
        var escaped = false;
        var paren_depth: usize = 0;
        while (cursor.* < body.len) : (cursor.* += 1) {
            if (quote != 0) {
                const byte = body[cursor.*];
                if (escaped) {
                    escaped = false;
                } else if (byte == '\\') {
                    escaped = true;
                } else if (byte == quote) {
                    quote = 0;
                }
                continue;
            }
            if (startsComment(body, cursor.*)) {
                cursor.* = skipComment(body, cursor.*);
                if (cursor.* >= body.len) break;
                cursor.* -= 1;
                continue;
            }
            const byte = body[cursor.*];
            if (byte == '\'' or byte == '"') {
                quote = byte;
            } else if (byte == '(') {
                paren_depth += 1;
                if (paren_depth > max_css_depth) return error.CssDepthLimit;
            } else if (byte == ')' and paren_depth > 0) {
                paren_depth -= 1;
            } else if (paren_depth == 0 and byte == ':' and colon == null) {
                colon = cursor.*;
            } else if (paren_depth == 0 and byte == ';') {
                break;
            }
        }
        const end = cursor.*;
        if (cursor.* < body.len and body[cursor.*] == ';') cursor.* += 1;
        const separator = colon orelse continue;
        if (separator >= end) continue;
        const name = trimCss(body[start..separator]);
        const value = trimCss(body[separator + 1 .. end]);
        if (name.len == 0 or value.len == 0) continue;
        return .{ .name = name, .value = value };
    }
    return null;
}

fn parseFace(body: []const u8, parsed: *ParsedFace) FaceParseError!void {
    var have_family = false;
    var have_sources = false;
    var descriptor_count: usize = 0;
    var cursor: usize = 0;
    while (try nextDeclaration(body, &cursor)) |declaration| {
        descriptor_count += 1;
        if (descriptor_count > max_descriptors_per_face) return error.DescriptorLimit;
        if (std.ascii.eqlIgnoreCase(declaration.name, "font-family")) {
            var family: [max_family_bytes]u8 = undefined;
            const family_input = trimCss(declaration.value);
            const quoted_family = isQuotedCssValue(family_input);
            if (!quoted_family and !validUnquotedFamily(family_input)) continue;
            const decoded = decodeCssName(declaration.value, family[0..]) catch |err| switch (err) {
                error.OutputTooSmall => return error.StringLimit,
                error.InvalidName => continue,
            };
            if (decoded.len == 0 or (!quoted_family and isForbiddenFaceFamily(decoded))) continue;
            @memcpy(parsed.family[0..decoded.len], decoded);
            parsed.family_len = decoded.len;
            have_family = true;
        } else if (std.ascii.eqlIgnoreCase(declaration.name, "src")) {
            var sources: [max_sources_per_face]ParsedSource = undefined;
            const count = parseSources(declaration.value, sources[0..]) catch |err| switch (err) {
                error.InvalidFace => continue,
                else => return err,
            };
            @memcpy(parsed.sources[0..count], sources[0..count]);
            parsed.source_count = count;
            have_sources = count > 0;
        } else if (std.ascii.eqlIgnoreCase(declaration.name, "font-weight")) {
            parsed.weight = parseWeightRange(declaration.value) orelse continue;
        } else if (std.ascii.eqlIgnoreCase(declaration.name, "font-style")) {
            parsed.style = parseStyleRange(declaration.value) orelse continue;
        } else if (std.ascii.eqlIgnoreCase(declaration.name, "font-stretch") or std.ascii.eqlIgnoreCase(declaration.name, "font-width")) {
            parsed.stretch = parseStretchRange(declaration.value) orelse continue;
        } else if (std.ascii.eqlIgnoreCase(declaration.name, "unicode-range")) {
            var ranges: [max_unicode_ranges_per_face]UnicodeRange = undefined;
            const count = parseUnicodeRanges(declaration.value, ranges[0..]) catch |err| switch (err) {
                error.InvalidFace => continue,
                else => return err,
            };
            @memcpy(parsed.ranges[0..count], ranges[0..count]);
            parsed.range_count = count;
        } else if (std.ascii.eqlIgnoreCase(declaration.name, "font-display")) {
            parsed.display = parseFontDisplay(declaration.value) orelse continue;
        }
    }
    if (!have_family or !have_sources) return error.InvalidFace;
}

const CssFunction = struct {
    name: []const u8,
    arguments: []const u8,
    end: usize,
};

fn parseSources(value: []const u8, out: []ParsedSource) FaceParseError!usize {
    var count: usize = 0;
    var cursor: usize = 0;
    while (true) {
        skipCssTrivia(value, &cursor);
        if (cursor >= value.len) break;
        const start = cursor;
        var quote: u8 = 0;
        var escaped = false;
        var depth: usize = 0;
        while (cursor < value.len) : (cursor += 1) {
            if (quote != 0) {
                const byte = value[cursor];
                if (escaped) {
                    escaped = false;
                } else if (byte == '\\') {
                    escaped = true;
                } else if (byte == quote) {
                    quote = 0;
                }
                continue;
            }
            if (startsComment(value, cursor)) {
                cursor = skipComment(value, cursor);
                if (cursor >= value.len) break;
                cursor -= 1;
                continue;
            }
            const byte = value[cursor];
            if (byte == '\'' or byte == '"') {
                quote = byte;
            } else if (byte == '(') {
                depth += 1;
                if (depth > max_css_depth) return error.CssDepthLimit;
            } else if (byte == ')') {
                if (depth == 0) return error.InvalidFace;
                depth -= 1;
            } else if (byte == ',' and depth == 0) {
                break;
            }
        }
        if (quote != 0 or depth != 0) return error.InvalidFace;
        const candidate = trimCss(value[start..cursor]);
        if (candidate.len == 0) return error.InvalidFace;
        if (count >= out.len) return error.SourceLimit;
        out[count] = try parseSource(candidate);
        count += 1;
        if (cursor >= value.len) break;
        cursor += 1;
    }
    if (count == 0) return error.InvalidFace;
    return count;
}

fn parseSource(candidate: []const u8) FaceParseError!ParsedSource {
    var cursor: usize = 0;
    skipCssTrivia(candidate, &cursor);
    const primary = parseCssFunction(candidate, cursor) orelse return error.InvalidFace;
    var result = ParsedSource{};
    if (std.ascii.eqlIgnoreCase(primary.name, "local")) {
        result.kind = .local;
        const local_input = trimCss(primary.arguments);
        const quoted_local = isQuotedCssValue(local_input);
        if (!quoted_local and !validUnquotedFamily(local_input)) return error.InvalidFace;
        const decoded = decodeCssName(primary.arguments, result.value[0..]) catch |err| switch (err) {
            error.OutputTooSmall => return error.StringLimit,
            error.InvalidName => return error.InvalidFace,
        };
        if (decoded.len == 0 or (!quoted_local and isForbiddenFaceFamily(decoded))) return error.InvalidFace;
        result.value_len = decoded.len;
    } else if (std.ascii.eqlIgnoreCase(primary.name, "url")) {
        result.kind = .url;
        const decoded = decodeCssUrl(primary.arguments, result.value[0..]) catch |err| switch (err) {
            error.OutputTooSmall => return error.StringLimit,
            error.InvalidName => return error.InvalidFace,
        };
        if (decoded.len == 0) return error.InvalidFace;
        result.value_len = decoded.len;
    } else {
        return error.InvalidFace;
    }

    cursor = primary.end;
    skipCssTrivia(candidate, &cursor);
    if (cursor < candidate.len) {
        if (result.kind == .local) return error.InvalidFace;
        const hint = parseCssFunction(candidate, cursor) orelse return error.InvalidFace;
        if (!std.ascii.eqlIgnoreCase(hint.name, "format")) return error.InvalidFace;
        const decoded = decodeCssName(hint.arguments, result.format_label[0..]) catch |err| switch (err) {
            error.OutputTooSmall => return error.StringLimit,
            error.InvalidName => return error.InvalidFace,
        };
        if (decoded.len == 0) return error.InvalidFace;
        result.format_len = decoded.len;
        result.format = fontFormat(decoded);
        cursor = hint.end;
        skipCssTrivia(candidate, &cursor);
        if (cursor != candidate.len) return error.InvalidFace;
    }
    return result;
}

fn parseCssFunction(value: []const u8, start_input: usize) ?CssFunction {
    var cursor = start_input;
    skipCssTrivia(value, &cursor);
    const name_start = cursor;
    while (cursor < value.len and isNameByte(value[cursor])) cursor += 1;
    if (cursor == name_start) return null;
    const name = value[name_start..cursor];
    skipCssTrivia(value, &cursor);
    if (cursor >= value.len or value[cursor] != '(') return null;
    const open = cursor;
    cursor += 1;
    var depth: usize = 1;
    var quote: u8 = 0;
    var escaped = false;
    while (cursor < value.len) : (cursor += 1) {
        const byte = value[cursor];
        if (quote != 0) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == quote) {
                quote = 0;
            }
            continue;
        }
        if (startsComment(value, cursor)) {
            cursor = skipComment(value, cursor);
            if (cursor >= value.len) return null;
            cursor -= 1;
            continue;
        }
        if (byte == '\'' or byte == '"') {
            quote = byte;
        } else if (byte == '(') {
            depth += 1;
            if (depth > max_css_depth) return null;
        } else if (byte == ')') {
            depth -= 1;
            if (depth == 0) return .{ .name = name, .arguments = value[open + 1 .. cursor], .end = cursor + 1 };
        }
    }
    return null;
}

fn fontFormat(value: []const u8) FontFormat {
    if (std.ascii.eqlIgnoreCase(value, "woff2") or std.ascii.eqlIgnoreCase(value, "woff2-variations")) return .woff2;
    if (std.ascii.eqlIgnoreCase(value, "woff") or std.ascii.eqlIgnoreCase(value, "woff-variations")) return .woff;
    if (std.ascii.eqlIgnoreCase(value, "truetype") or std.ascii.eqlIgnoreCase(value, "ttf") or std.ascii.eqlIgnoreCase(value, "truetype-variations")) return .truetype;
    if (std.ascii.eqlIgnoreCase(value, "opentype") or std.ascii.eqlIgnoreCase(value, "otf") or std.ascii.eqlIgnoreCase(value, "opentype-variations")) return .opentype;
    if (std.ascii.eqlIgnoreCase(value, "embedded-opentype") or std.ascii.eqlIgnoreCase(value, "eot")) return .embedded_opentype;
    if (std.ascii.eqlIgnoreCase(value, "collection") or std.ascii.eqlIgnoreCase(value, "truetype-collection")) return .collection;
    if (std.ascii.eqlIgnoreCase(value, "svg")) return .svg;
    return .unknown;
}

fn parseWeightRange(value: []const u8) ?WeightRange {
    var values: [2][]const u8 = undefined;
    const count = simpleTokens(value, values[0..]) orelse return null;
    if (count == 0 or count > 2) return null;
    if (count == 1 and std.ascii.eqlIgnoreCase(values[0], "auto")) return .{ .auto = true };
    const first = parseWeight(values[0]) orelse return null;
    const second = if (count == 2) parseWeight(values[1]) orelse return null else first;
    return .{ .min = @min(first, second), .max = @max(first, second) };
}

fn parseWeight(value: []const u8) ?u16 {
    if (std.ascii.eqlIgnoreCase(value, "normal")) return 400;
    if (std.ascii.eqlIgnoreCase(value, "bold")) return 700;
    const parsed = std.fmt.parseInt(u16, value, 10) catch return null;
    if (parsed < 1 or parsed > 1000) return null;
    return parsed;
}

fn parseStyleRange(value: []const u8) ?StyleRange {
    var values: [3][]const u8 = undefined;
    const count = simpleTokens(value, values[0..]) orelse return null;
    if (count == 1 and std.ascii.eqlIgnoreCase(values[0], "auto")) return .{ .auto = true };
    if (count == 1 and std.ascii.eqlIgnoreCase(values[0], "normal")) return .{};
    if (count == 1 and std.ascii.eqlIgnoreCase(values[0], "italic")) return .{ .kind = .italic };
    if (count == 0 or count > 3 or !std.ascii.eqlIgnoreCase(values[0], "oblique")) return null;
    if (count == 1) return .{ .kind = .oblique, .min_angle_tenth = 140, .max_angle_tenth = 140 };
    const first = parseDegreeAngle(values[1]) orelse return null;
    const second = if (count == 3) parseDegreeAngle(values[2]) orelse return null else first;
    return .{ .kind = .oblique, .min_angle_tenth = @min(first, second), .max_angle_tenth = @max(first, second) };
}

fn parseDegreeAngle(value: []const u8) ?i16 {
    if (value.len <= 3 or !std.ascii.endsWithIgnoreCase(value, "deg")) return null;
    const angle = parseFixed(value[0 .. value.len - 3], 10) orelse return null;
    if (angle < -900 or angle > 900) return null;
    return @intCast(angle);
}

fn parseStretchRange(value: []const u8) ?StretchRange {
    var values: [2][]const u8 = undefined;
    const count = simpleTokens(value, values[0..]) orelse return null;
    if (count == 0 or count > 2) return null;
    if (count == 1 and std.ascii.eqlIgnoreCase(values[0], "auto")) return .{ .auto = true };
    const first = parseStretch(values[0]) orelse return null;
    const second = if (count == 2) parseStretch(values[1]) orelse return null else first;
    return .{ .min_hundred = @min(first, second), .max_hundred = @max(first, second) };
}

fn parseStretch(value: []const u8) ?u32 {
    const keywords = [_]struct { name: []const u8, fixed: u32 }{
        .{ .name = "ultra-condensed", .fixed = 5000 },
        .{ .name = "extra-condensed", .fixed = 6250 },
        .{ .name = "condensed", .fixed = 7500 },
        .{ .name = "semi-condensed", .fixed = 8750 },
        .{ .name = "normal", .fixed = 10_000 },
        .{ .name = "semi-expanded", .fixed = 11_250 },
        .{ .name = "expanded", .fixed = 12_500 },
        .{ .name = "extra-expanded", .fixed = 15_000 },
        .{ .name = "ultra-expanded", .fixed = 20_000 },
    };
    for (keywords) |entry| {
        if (std.ascii.eqlIgnoreCase(value, entry.name)) return entry.fixed;
    }
    if (value.len < 2 or value[value.len - 1] != '%') return null;
    const fixed = parseFixed(value[0 .. value.len - 1], 100) orelse return null;
    if (fixed < 100 or fixed > 100_000) return null;
    return @intCast(fixed);
}

fn parseUnicodeRanges(value: []const u8, out: []UnicodeRange) FaceParseError!usize {
    var count: usize = 0;
    var cursor: usize = 0;
    while (cursor < value.len) {
        const start = cursor;
        while (cursor < value.len and value[cursor] != ',') cursor += 1;
        const token = trimCss(value[start..cursor]);
        if (token.len == 0) return error.InvalidFace;
        if (count >= out.len) return error.UnicodeRangeLimit;
        out[count] = parseUnicodeRange(token) orelse return error.InvalidFace;
        count += 1;
        if (cursor < value.len) cursor += 1;
    }
    if (count == 0) return error.InvalidFace;
    return count;
}

fn parseUnicodeRange(value: []const u8) ?UnicodeRange {
    if (value.len < 3 or (value[0] != 'u' and value[0] != 'U') or value[1] != '+') return null;
    const body = value[2..];
    if (body.len == 0) return null;
    if (std.mem.indexOfScalar(u8, body, '?')) |_| {
        if (body.len > 6 or std.mem.indexOfScalar(u8, body, '-') != null) return null;
        var wildcard = false;
        var first: u32 = 0;
        var last: u32 = 0;
        for (body) |byte| {
            first *= 16;
            last *= 16;
            if (byte == '?') {
                wildcard = true;
                last += 15;
            } else {
                if (wildcard) return null;
                const digit = hexDigit(byte) orelse return null;
                first += digit;
                last += digit;
            }
        }
        if (last > 0x10FFFF) return null;
        return .{ .first = first, .last = last };
    }
    if (std.mem.indexOfScalar(u8, body, '-')) |separator| {
        const first = parseCodepointHex(body[0..separator]) orelse return null;
        const last = parseCodepointHex(body[separator + 1 ..]) orelse return null;
        if (first > last) return null;
        return .{ .first = first, .last = last };
    }
    const scalar = parseCodepointHex(body) orelse return null;
    return .{ .first = scalar, .last = scalar };
}

fn parseCodepointHex(value: []const u8) ?u32 {
    if (value.len == 0 or value.len > 6) return null;
    var result: u32 = 0;
    for (value) |byte| result = result * 16 + (hexDigit(byte) orelse return null);
    if (result > 0x10FFFF) return null;
    return result;
}

fn parseFontDisplay(value: []const u8) ?FontDisplay {
    var values: [1][]const u8 = undefined;
    const count = simpleTokens(value, values[0..]) orelse return null;
    if (count != 1) return null;
    if (std.ascii.eqlIgnoreCase(values[0], "auto")) return .auto;
    if (std.ascii.eqlIgnoreCase(values[0], "block")) return .block;
    if (std.ascii.eqlIgnoreCase(values[0], "swap")) return .swap;
    if (std.ascii.eqlIgnoreCase(values[0], "fallback")) return .fallback;
    if (std.ascii.eqlIgnoreCase(values[0], "optional")) return .optional;
    return null;
}

fn simpleTokens(value: []const u8, out: [][]const u8) ?usize {
    var cursor: usize = 0;
    var count: usize = 0;
    while (true) {
        skipCssTrivia(value, &cursor);
        if (cursor >= value.len) break;
        const start = cursor;
        while (cursor < value.len and !isCssSpace(value[cursor]) and !startsComment(value, cursor)) cursor += 1;
        if (count >= out.len) return null;
        out[count] = value[start..cursor];
        count += 1;
    }
    return count;
}

fn parseFixed(value: []const u8, scale: i32) ?i32 {
    if (value.len == 0) return null;
    var cursor: usize = 0;
    var negative = false;
    if (value[cursor] == '+' or value[cursor] == '-') {
        negative = value[cursor] == '-';
        cursor += 1;
    }
    if (cursor >= value.len) return null;
    var whole: i64 = 0;
    var have_digit = false;
    while (cursor < value.len and value[cursor] >= '0' and value[cursor] <= '9') : (cursor += 1) {
        have_digit = true;
        whole = whole * 10 + value[cursor] - '0';
        if (whole > 1_000_000) return null;
    }
    var fraction: i64 = 0;
    var fraction_scale: i64 = 1;
    if (cursor < value.len and value[cursor] == '.') {
        cursor += 1;
        while (cursor < value.len and value[cursor] >= '0' and value[cursor] <= '9') : (cursor += 1) {
            have_digit = true;
            if (fraction_scale < 1_000_000) {
                fraction = fraction * 10 + value[cursor] - '0';
                fraction_scale *= 10;
            }
        }
    }
    if (!have_digit or cursor != value.len) return null;
    var result = whole * scale + @divTrunc(fraction * scale, fraction_scale);
    if (negative) result = -result;
    if (result < std.math.minInt(i32) or result > std.math.maxInt(i32)) return null;
    return @intCast(result);
}

const DecodeError = error{
    InvalidName,
    OutputTooSmall,
};

fn decodeCssName(value: []const u8, out: []u8) DecodeError![]const u8 {
    const input = trimCss(value);
    if (input.len == 0) return error.InvalidName;
    if (input[0] == '\'' or input[0] == '"') {
        const end = skipQuoted(input, 0);
        if (end <= 1 or end > input.len or input[end - 1] != input[0]) return error.InvalidName;
        var trailing = end;
        skipCssTrivia(input, &trailing);
        if (trailing != input.len) return error.InvalidName;
        return decodeCssBytes(input[1 .. end - 1], out, false, false);
    }
    return decodeCssBytes(input, out, true, false);
}

fn decodeCssUrl(value: []const u8, out: []u8) DecodeError![]const u8 {
    const input = trimCss(value);
    if (input.len == 0) return error.InvalidName;
    if (input[0] == '\'' or input[0] == '"') return decodeCssName(input, out);
    return decodeCssBytes(input, out, false, true);
}

fn decodeCssBytes(value: []const u8, out: []u8, collapse_space: bool, url_mode: bool) DecodeError![]const u8 {
    var input_cursor: usize = 0;
    var output_len: usize = 0;
    var pending_space = false;
    while (input_cursor < value.len) {
        if (startsComment(value, input_cursor)) {
            if (url_mode) return error.InvalidName;
            input_cursor = skipComment(value, input_cursor);
            if (collapse_space and output_len > 0) pending_space = true;
            continue;
        }
        const byte = value[input_cursor];
        if (byte == '\\') {
            if (pending_space) {
                try appendByte(out, &output_len, ' ');
                pending_space = false;
            }
            try decodeCssEscape(value, &input_cursor, out, &output_len);
            continue;
        }
        if (byte == '\r' or byte == '\n' or byte == 0x0C) {
            if (!collapse_space or url_mode) return error.InvalidName;
            pending_space = output_len > 0;
            input_cursor += 1;
            continue;
        }
        if (isCssSpace(byte)) {
            if (url_mode) return error.InvalidName;
            if (collapse_space) {
                pending_space = output_len > 0;
            } else {
                try appendByte(out, &output_len, byte);
            }
            input_cursor += 1;
            continue;
        }
        if (url_mode and (byte == '\'' or byte == '"' or byte == '(' or byte == ')' or byte < 0x20 or byte == 0x7F)) return error.InvalidName;
        if (pending_space) {
            try appendByte(out, &output_len, ' ');
            pending_space = false;
        }
        try appendByte(out, &output_len, byte);
        input_cursor += 1;
    }
    while (output_len > 0 and collapse_space and out[output_len - 1] == ' ') output_len -= 1;
    if (output_len == 0) return error.InvalidName;
    return out[0..output_len];
}

fn decodeCssEscape(value: []const u8, cursor: *usize, out: []u8, output_len: *usize) DecodeError!void {
    cursor.* += 1;
    if (cursor.* >= value.len) return error.InvalidName;
    if (value[cursor.*] == '\n' or value[cursor.*] == 0x0C) {
        cursor.* += 1;
        return;
    }
    if (value[cursor.*] == '\r') {
        cursor.* += 1;
        if (cursor.* < value.len and value[cursor.*] == '\n') cursor.* += 1;
        return;
    }
    if (hexDigit(value[cursor.*]) != null) {
        var scalar: u32 = 0;
        var count: usize = 0;
        while (cursor.* < value.len and count < 6) : (count += 1) {
            const digit = hexDigit(value[cursor.*]) orelse break;
            scalar = scalar * 16 + digit;
            cursor.* += 1;
        }
        if (cursor.* < value.len and isCssSpace(value[cursor.*])) cursor.* += 1;
        if (scalar == 0 or scalar > 0x10FFFF or (scalar >= 0xD800 and scalar <= 0xDFFF)) scalar = 0xFFFD;
        var encoded: [4]u8 = undefined;
        const len = std.unicode.utf8Encode(@intCast(scalar), encoded[0..]) catch return error.InvalidName;
        if (len > out.len - output_len.*) return error.OutputTooSmall;
        @memcpy(out[output_len.* .. output_len.* + len], encoded[0..len]);
        output_len.* += len;
        return;
    }
    try appendByte(out, output_len, value[cursor.*]);
    cursor.* += 1;
}

fn appendByte(out: []u8, len: *usize, byte: u8) DecodeError!void {
    if (len.* >= out.len) return error.OutputTooSmall;
    out[len.*] = byte;
    len.* += 1;
}

fn isForbiddenFaceFamily(value: []const u8) bool {
    const forbidden = [_][]const u8{
        "serif",    "sans-serif",    "cursive",      "fantasy",    "monospace",    "system-ui",
        "ui-serif", "ui-sans-serif", "ui-monospace", "ui-rounded", "math",         "fangsong",
        "inherit",  "initial",       "unset",        "revert",     "revert-layer", "default",
    };
    for (forbidden) |name| {
        if (std.ascii.eqlIgnoreCase(value, name)) return true;
    }
    return false;
}

fn isQuotedCssValue(value: []const u8) bool {
    const input = trimCss(value);
    if (input.len < 2 or (input[0] != '\'' and input[0] != '"')) return false;
    const end = skipQuoted(input, 0);
    if (end <= 1 or end > input.len or input[end - 1] != input[0]) return false;
    var trailing = end;
    skipCssTrivia(input, &trailing);
    return trailing == input.len;
}

fn validUnquotedFamily(value: []const u8) bool {
    var cursor: usize = 0;
    var tokens: usize = 0;
    while (true) {
        skipCssTrivia(value, &cursor);
        if (cursor >= value.len) break;
        tokens += 1;
        if (value[cursor] == '-') {
            cursor += 1;
            if (cursor >= value.len) return false;
            if (value[cursor] == '-') {
                cursor += 1;
            } else if (value[cursor] == '\\') {
                if (!skipNameEscape(value, &cursor)) return false;
            } else if (isIdentStartByte(value[cursor])) {
                cursor += 1;
            } else {
                return false;
            }
        } else if (value[cursor] == '\\') {
            if (!skipNameEscape(value, &cursor)) return false;
        } else if (isIdentStartByte(value[cursor])) {
            cursor += 1;
        } else {
            return false;
        }
        while (cursor < value.len and !isCssSpace(value[cursor]) and !startsComment(value, cursor)) {
            if (value[cursor] == '\\') {
                if (!skipNameEscape(value, &cursor)) return false;
            } else if (isNameByte(value[cursor])) {
                cursor += 1;
            } else {
                return false;
            }
        }
    }
    return tokens > 0;
}

fn skipNameEscape(value: []const u8, cursor: *usize) bool {
    if (cursor.* >= value.len or value[cursor.*] != '\\' or cursor.* + 1 >= value.len) return false;
    cursor.* += 1;
    if (value[cursor.*] == '\r' or value[cursor.*] == '\n' or value[cursor.*] == 0x0C) return false;
    if (hexDigit(value[cursor.*]) != null) {
        var count: usize = 0;
        while (cursor.* < value.len and count < 6 and hexDigit(value[cursor.*]) != null) : (count += 1) cursor.* += 1;
        if (cursor.* < value.len and isCssSpace(value[cursor.*])) cursor.* += 1;
        return true;
    }
    cursor.* += 1;
    return true;
}

fn isIdentStartByte(value: u8) bool {
    return (value >= 'a' and value <= 'z') or (value >= 'A' and value <= 'Z') or value == '_' or value >= 0x80;
}

fn startsComment(value: []const u8, start: usize) bool {
    return start + 1 < value.len and value[start] == '/' and value[start + 1] == '*';
}

fn skipComment(value: []const u8, start: usize) usize {
    var cursor = start + 2;
    while (cursor + 1 < value.len) : (cursor += 1) {
        if (value[cursor] == '*' and value[cursor + 1] == '/') return cursor + 2;
    }
    return value.len;
}

fn skipQuoted(value: []const u8, start: usize) usize {
    if (start >= value.len or (value[start] != '\'' and value[start] != '"')) return start;
    const quote = value[start];
    var cursor = start + 1;
    while (cursor < value.len) {
        if (value[cursor] == '\\') {
            cursor += 1;
            if (cursor < value.len and value[cursor] == '\r') {
                cursor += 1;
                if (cursor < value.len and value[cursor] == '\n') cursor += 1;
            } else if (cursor < value.len) {
                cursor += 1;
            }
            continue;
        }
        if (value[cursor] == quote) return cursor + 1;
        cursor += 1;
    }
    return value.len;
}

fn skipCssTrivia(value: []const u8, cursor: *usize) void {
    while (cursor.* < value.len) {
        if (isCssSpace(value[cursor.*])) {
            cursor.* += 1;
        } else if (startsComment(value, cursor.*)) {
            cursor.* = skipComment(value, cursor.*);
        } else {
            break;
        }
    }
}

fn trimCss(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (true) {
        while (start < end and isCssSpace(value[start])) start += 1;
        if (start < end and startsComment(value, start)) {
            start = @min(end, skipComment(value[0..end], start));
            continue;
        }
        break;
    }
    while (true) {
        while (end > start and isCssSpace(value[end - 1])) end -= 1;
        if (end >= start + 2 and value[end - 2] == '*' and value[end - 1] == '/') {
            var comment_start = end - 2;
            while (comment_start > start) : (comment_start -= 1) {
                if (value[comment_start - 1] == '/' and value[comment_start] == '*') {
                    end = comment_start - 1;
                    break;
                }
            } else break;
            continue;
        }
        break;
    }
    return value[start..end];
}

fn startsWithIgnoreCaseAt(value: []const u8, start: usize, needle: []const u8) bool {
    return start <= value.len and needle.len <= value.len - start and std.ascii.eqlIgnoreCase(value[start .. start + needle.len], needle);
}

fn isNameByte(value: u8) bool {
    return (value >= 'a' and value <= 'z') or (value >= 'A' and value <= 'Z') or
        (value >= '0' and value <= '9') or value == '-' or value == '_' or value >= 0x80;
}

fn isCssSpace(value: u8) bool {
    return value == ' ' or value == '\t' or value == '\r' or value == '\n' or value == 0x0C;
}

fn hexDigit(value: u8) ?u32 {
    if (value >= '0' and value <= '9') return value - '0';
    if (value >= 'a' and value <= 'f') return value - 'a' + 10;
    if (value >= 'A' and value <= 'F') return value - 'A' + 10;
    return null;
}

test "font face parser preserves descriptors ordered sources and stylesheet provenance" {
    const stylesheet =
        "/* @font-face{font-family:Fake;src:url(fake.woff2)} */" ++
        ".sample{content:'@font-face{font-family:Also Fake;src:url(fake.woff)}'}" ++
        "@FoNt-FaCe{" ++
        "font-family:'R4 \\53 ans';" ++
        "src:local('R4 Sans Regular'),url('../fonts/r4.woff2') format('woff2')," ++
        "url(data:font/otf;base64,QUJD) format(opentype);" ++
        "font-weight:300 700;font-style:oblique -10deg 20deg;font-stretch:75% 125%;" ++
        "unicode-range:U+0000-00FF,U+4??,U+1F600;font-display:swap;unknown:value}";

    var registry = Registry{};
    registry.beginDocument(41);
    const stats = try registry.appendStylesheet(stylesheet, "https://example.test/css/site.css");
    try std.testing.expectEqual(@as(usize, 1), stats.faces_added);
    try std.testing.expectEqual(@as(usize, 0), stats.invalid_faces);
    try std.testing.expectEqual(@as(usize, 1), registry.face_count);
    try std.testing.expectEqual(@as(usize, 3), registry.source_count);
    try std.testing.expectEqualStrings("R4 Sans", registry.family(0));
    try std.testing.expectEqualStrings("https://example.test/css/site.css", registry.sectionBaseUrl(0));

    const face = registry.faces[0];
    try std.testing.expectEqual(@as(u16, 300), face.weight.min);
    try std.testing.expectEqual(@as(u16, 700), face.weight.max);
    try std.testing.expectEqual(FontStyle.oblique, face.style.kind);
    try std.testing.expectEqual(@as(i16, -100), face.style.min_angle_tenth);
    try std.testing.expectEqual(@as(i16, 200), face.style.max_angle_tenth);
    try std.testing.expectEqual(@as(u32, 7500), face.stretch.min_hundred);
    try std.testing.expectEqual(@as(u32, 12_500), face.stretch.max_hundred);
    try std.testing.expectEqual(FontDisplay.swap, face.display);
    try std.testing.expectEqual(@as(u8, 0), face.source_section);
    try std.testing.expectEqual(@as(u8, 3), face.source_count);
    try std.testing.expectEqual(@as(u8, 3), face.unicode_range_count);
    try std.testing.expectEqual(UnicodeRange{ .first = 0, .last = 0xFF }, registry.unicode_ranges[face.unicode_range_start]);
    try std.testing.expectEqual(UnicodeRange{ .first = 0x400, .last = 0x4FF }, registry.unicode_ranges[face.unicode_range_start + 1]);
    try std.testing.expectEqual(UnicodeRange{ .first = 0x1F600, .last = 0x1F600 }, registry.unicode_ranges[face.unicode_range_start + 2]);

    const local = registry.faceSource(0, 0).?;
    const woff2 = registry.faceSource(0, 1).?;
    const data = registry.faceSource(0, 2).?;
    try std.testing.expectEqual(SourceKind.local, local.kind);
    try std.testing.expectEqualStrings("R4 Sans Regular", registry.sourceValue(face.source_start));
    try std.testing.expectEqual(SourceKind.url, woff2.kind);
    try std.testing.expectEqual(FontFormat.woff2, woff2.format);
    try std.testing.expect(woff2.format.loadable());
    try std.testing.expectEqualStrings("../fonts/r4.woff2", registry.sourceValue(face.source_start + 1));
    try std.testing.expectEqualStrings("woff2", registry.sourceFormatLabel(face.source_start + 1));
    try std.testing.expectEqual(FontFormat.opentype, data.format);
    try std.testing.expectEqualStrings("data:font/otf;base64,QUJD", registry.sourceValue(face.source_start + 2));
}

test "invalid faces are isolated and invalid duplicate descriptors retain prior valid values" {
    const stylesheet =
        "/* @font-face{font-family:Comment;src:url(comment.woff2)} */" ++
        ".fake{content:\"@font-face{font-family:String;src:url(string.woff2)}\"}" ++
        "@font-face{font-family:'Good Face';font-family:serif;src:url(good.woff2) format(woff2);" ++
        "src:paint(bad);font-weight:nonsense;font-display:soon}" ++
        "@font-face{src:url(no-family.woff2)}" ++
        "@font-face{font-family:monospace;src:url(generic.woff2)}" ++
        "@font-face{font-family:Unclosed;src:url(unclosed.woff2)";

    var registry = Registry{};
    registry.beginDocument(9);
    const stats = try registry.appendStylesheet(stylesheet, "https://invalid.test/main.css");
    try std.testing.expectEqual(@as(usize, 1), stats.faces_added);
    try std.testing.expectEqual(@as(usize, 3), stats.invalid_faces);
    try std.testing.expectEqualStrings("Good Face", registry.family(0));
    try std.testing.expectEqual(@as(u8, 1), registry.faces[0].source_count);
    try std.testing.expectEqualStrings("good.woff2", registry.sourceValue(0));
    try std.testing.expectEqual(WeightRange{}, registry.faces[0].weight);
    try std.testing.expectEqual(FontDisplay.auto, registry.faces[0].display);
}

test "quoted generic names auto descriptors and reversed variable ranges remain explicit" {
    const stylesheet =
        "@font-face{font-family:'serif';src:local('serif'),url(variable.ttf) format(truetype-variations);" ++
        "font-weight:700 300;font-style:oblique 20deg -10deg;font-width:125% 75%;font-display:optional}" ++
        "@font-face{font-family:Automatic;src:url(auto.otf) format(opentype-variations);" ++
        "font-weight:auto;font-style:auto;font-stretch:auto}" ++
        "@font-face{font-family:'Bad Local';src:local(System) format(woff2)}" ++
        "@font-face{font-family:Ahem!;src:url(ahem.woff2)}";
    var registry = Registry{};
    registry.beginDocument(12);
    const stats = try registry.appendStylesheet(stylesheet, "https://edge.test/fonts.css");
    try std.testing.expectEqual(@as(usize, 2), stats.faces_added);
    try std.testing.expectEqual(@as(usize, 2), stats.invalid_faces);
    try std.testing.expectEqualStrings("serif", registry.family(0));
    try std.testing.expectEqual(@as(u16, 300), registry.faces[0].weight.min);
    try std.testing.expectEqual(@as(u16, 700), registry.faces[0].weight.max);
    try std.testing.expectEqual(@as(i16, -100), registry.faces[0].style.min_angle_tenth);
    try std.testing.expectEqual(@as(i16, 200), registry.faces[0].style.max_angle_tenth);
    try std.testing.expectEqual(@as(u32, 7500), registry.faces[0].stretch.min_hundred);
    try std.testing.expectEqual(@as(u32, 12_500), registry.faces[0].stretch.max_hundred);
    try std.testing.expectEqual(FontDisplay.optional, registry.faces[0].display);
    try std.testing.expectEqual(FontFormat.truetype, registry.faceSource(0, 1).?.format);
    try std.testing.expect(registry.faces[1].weight.auto);
    try std.testing.expect(registry.faces[1].style.auto);
    try std.testing.expect(registry.faces[1].stretch.auto);
    try std.testing.expectEqual(FontFormat.opentype, registry.faceSource(1, 0).?.format);
}

test "needed text runs select only covered faces in family and source order" {
    const stylesheet =
        "@font-face{font-family:'Run Face';src:local('Run Local'),url(run-latin.woff2) format(woff2);unicode-range:U+0-7F}" ++
        "@font-face{font-family:'Run Face';src:url(run-greek.woff2) format(woff2);unicode-range:U+370-3FF}" ++
        "@font-face{font-family:'Unused Face';src:url(unused.woff2) format(woff2)}";
    var registry = Registry{};
    registry.beginDocument(77);
    _ = try registry.appendStylesheet(stylesheet, "https://fonts.test/css/run.css");

    const request = MatchRequest{
        .family_list = "'Missing Face', 'Run Face', sans-serif",
        .text = "A\xCE\xA9B",
    };
    var runs = try registry.neededRuns(request);
    const latin_a = runs.next().?;
    const greek = runs.next().?;
    const latin_b = runs.next().?;
    try std.testing.expect(runs.next() == null);
    try std.testing.expectEqual(@as(u64, 77), latin_a.match.document_id);
    try std.testing.expectEqual(@as(u16, 0), latin_a.match.face_index);
    try std.testing.expectEqual(@as(u32, 0), latin_a.byte_start);
    try std.testing.expectEqual(@as(u32, 1), latin_a.byte_len);
    try std.testing.expectEqual(@as(u16, 1), greek.match.face_index);
    try std.testing.expectEqual(@as(u32, 1), greek.byte_start);
    try std.testing.expectEqual(@as(u32, 2), greek.byte_len);
    try std.testing.expectEqual(@as(u16, 0), latin_b.match.face_index);
    try std.testing.expectEqual(@as(u32, 3), latin_b.byte_start);

    var needed: [max_faces]u16 = undefined;
    const needed_count = try registry.collectNeededFaces(request, needed[0..]);
    try std.testing.expectEqual(@as(usize, 2), needed_count);
    try std.testing.expectEqualSlices(u16, &[_]u16{ 0, 1 }, needed[0..needed_count]);
    try std.testing.expectError(error.OutputLimit, registry.collectNeededFaces(request, needed[0..1]));

    var absent = try registry.neededRuns(.{ .family_list = "Run Face", .text = "\xF0\x9F\x98\x80" });
    try std.testing.expect(absent.next() == null);
}

test "face matching orders stretch style weight ranges and declaration ties deterministically" {
    const stylesheet =
        "@font-face{font-family:Match;src:url(300.woff2);font-weight:300}" ++
        "@font-face{font-family:Match;src:url(500.woff2);font-weight:500}" ++
        "@font-face{font-family:Match;src:url(700.woff2);font-weight:700}" ++
        "@font-face{font-family:Match;src:url(italic.woff2);font-weight:400;font-style:italic}" ++
        "@font-face{font-family:Match;src:url(narrow.woff2);font-weight:400;font-stretch:75%}";
    var registry = Registry{};
    registry.beginDocument(5);
    _ = try registry.appendStylesheet(stylesheet, "");

    try std.testing.expectEqual(@as(u16, 1), registry.matchCodepoint(.{ .family_list = "Match", .text = "A", .weight = 400 }, 'A').?.face_index);
    try std.testing.expectEqual(@as(u16, 2), registry.matchCodepoint(.{ .family_list = "Match", .text = "A", .weight = 650 }, 'A').?.face_index);
    try std.testing.expectEqual(@as(u16, 3), registry.matchCodepoint(.{ .family_list = "Match", .text = "A", .weight = 400, .style = .italic }, 'A').?.face_index);
    try std.testing.expectEqual(@as(u16, 4), registry.matchCodepoint(.{ .family_list = "Match", .text = "A", .weight = 400, .stretch_hundred = 7500 }, 'A').?.face_index);
    try std.testing.expectEqual(@as(u16, 2), registry.matchFamilyCodepoint("Match", .{ .family_list = "Ignored", .text = "A", .weight = 650 }, 'A').?.face_index);
    try std.testing.expectEqual(@as(u16, 3), registry.matchFamilyCodepoint("Match", .{ .family_list = "Ignored", .text = "", .weight = 400, .style = .italic }, null).?.face_index);
    try std.testing.expect(registry.matchFamilyCodepoint("Missing", .{ .family_list = "Match", .text = "A" }, 'A') == null);
}

test "registry document reset and source sections keep document lifetime isolated" {
    var registry = Registry{};
    registry.beginDocument(100);
    _ = try registry.appendStylesheet("@font-face{font-family:First;src:url(first.woff2)}", "https://one.test/a.css");
    _ = try registry.appendStylesheet("@font-face{font-family:Second;src:url(second.woff2)}", "https://two.test/b.css");
    try std.testing.expectEqual(@as(usize, 2), registry.source_section_count);
    try std.testing.expectEqualStrings("https://one.test/a.css", registry.sectionBaseUrl(0));
    try std.testing.expectEqualStrings("https://two.test/b.css", registry.sectionBaseUrl(1));
    try std.testing.expectEqual(@as(u8, 1), registry.faces[1].source_section);

    registry.beginDocument(101);
    try std.testing.expectEqual(@as(u64, 101), registry.document_id);
    try std.testing.expectEqual(@as(usize, 0), registry.face_count);
    try std.testing.expectEqual(@as(usize, 0), registry.source_count);
    try std.testing.expectEqual(@as(usize, 0), registry.source_section_count);
    try std.testing.expect(registry.matchCodepoint(.{ .family_list = "First", .text = "A" }, 'A') == null);
}

test "parser and demand APIs fail visibly at fixed boundaries without partial append" {
    var registry = Registry{};
    registry.beginDocument(1);
    const too_many_sources =
        "@font-face{font-family:BeforeLimit;src:url(before.woff2)}" ++
        "@font-face{font-family:Many;src:" ++
        "local(A),local(B),local(C),local(D),local(E),local(F),local(G),local(H),local(I)," ++
        "local(J),local(K),local(L),local(M),local(N),local(O),local(P),local(Q)}";
    try std.testing.expectError(error.SourceLimit, registry.appendStylesheet(too_many_sources, "https://limit.test/a.css"));
    try std.testing.expectEqual(@as(usize, 0), registry.string_len);
    try std.testing.expectEqual(@as(usize, 0), registry.face_count);
    try std.testing.expectEqual(@as(usize, 0), registry.source_section_count);

    var oversized_stylesheet: [max_stylesheet_bytes + 1]u8 = undefined;
    @memset(oversized_stylesheet[0..], 'x');
    try std.testing.expectError(error.StylesheetTooLarge, registry.appendStylesheet(oversized_stylesheet[0..], ""));
    var oversized_base: [max_base_url_bytes + 1]u8 = undefined;
    @memset(oversized_base[0..], 'x');
    try std.testing.expectError(error.StringLimit, registry.appendStylesheet("", oversized_base[0..]));

    var section: usize = 0;
    while (section < max_source_sections) : (section += 1) _ = try registry.appendStylesheet("", "");
    try std.testing.expectError(error.SourceSectionLimit, registry.appendStylesheet("", ""));

    var oversized_family: [max_family_list_bytes + 1]u8 = undefined;
    @memset(oversized_family[0..], 'A');
    try std.testing.expectError(error.FamilyListTooLong, registry.neededRuns(.{ .family_list = oversized_family[0..], .text = "A" }));
    var oversized_text: [max_text_run_bytes + 1]u8 = undefined;
    @memset(oversized_text[0..], 'A');
    try std.testing.expectError(error.TextRunTooLong, registry.neededRuns(.{ .family_list = "A", .text = oversized_text[0..] }));
}
