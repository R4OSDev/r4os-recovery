const std = @import("std");

pub const max_data_url_bytes: usize = 128 * 1024;

pub const default_supported_types = [_][]const u8{
    "image/png",
    "image/x-png",
    "image/jpeg",
    "image/jpg",
    "image/pjpeg",
    "image/bmp",
    "image/x-ms-bmp",
    "image/svg+xml",
};

pub const Context = struct {
    viewport_width: u32 = 800,
    viewport_height: u32 = 600,
    /// Fixed-point device pixel ratio. 1000 is DPR 1, 2000 is DPR 2.
    device_pixel_ratio_milli: u32 = 1000,
    supported_types: []const []const u8 = &default_supported_types,

    pub fn dpr(self: Context) u32 {
        return @max(1, self.device_pixel_ratio_milli);
    }

    pub fn supportsType(self: Context, input: []const u8) bool {
        const mime = mimeType(input);
        if (mime.len == 0) return true;
        for (self.supported_types) |supported| {
            if (std.ascii.eqlIgnoreCase(mime, mimeType(supported))) return true;
        }
        return false;
    }
};

pub const SourceKind = enum(u8) {
    img_src,
    img_srcset,
    picture,
    css_url,
    css_image_set,
};

pub const Selection = struct {
    url: []const u8,
    density_milli: u32 = 1000,
    source_width: u32 = 0,
    kind: SourceKind,
};

pub const PictureSource = struct {
    srcset: []const u8,
    sizes: []const u8 = "",
    media: []const u8 = "",
    mime_type: []const u8 = "",
};

pub const DataUrl = struct {
    media_type: []const u8,
    bytes: []const u8,
    base64: bool,
};

pub const DataUrlError = error{
    NotDataUrl,
    MissingComma,
    InvalidEscape,
    InvalidBase64,
    TooLarge,
    BufferTooSmall,
};

const Candidate = struct {
    url: []const u8,
    density_milli: u32 = 1000,
    source_width: u32 = 0,
};

const CandidateChoice = struct {
    selected: ?Candidate = null,
    selected_density: u32 = 0,
    largest: ?Candidate = null,
    largest_density: u32 = 0,

    fn consider(self: *CandidateChoice, candidate: Candidate, density: u32, wanted: u32) void {
        if (density >= wanted and (self.selected == null or density < self.selected_density)) {
            self.selected = candidate;
            self.selected_density = density;
        }
        if (self.largest == null or density > self.largest_density) {
            self.largest = candidate;
            self.largest_density = density;
        }
    }

    fn result(self: CandidateChoice) ?Candidate {
        return self.selected orelse self.largest;
    }
};

/// Selects the effective source for an IMG element. The implementation is
/// deliberately bounded to the interoperable `x` and `w` descriptor forms.
/// Unknown or malformed candidates are ignored, never guessed.
pub fn selectImg(
    src: []const u8,
    srcset: []const u8,
    sizes: []const u8,
    context: Context,
) ?Selection {
    return selectCandidateSet(src, srcset, sizes, context, .img_srcset) orelse fallbackSelection(src, .img_src);
}

/// Applies PICTURE sources in document order. A SOURCE only participates when
/// its media query and explicit MIME type are supported. The IMG attributes are
/// the final fallback and are selected with the same candidate algorithm.
pub fn selectPicture(
    sources: []const PictureSource,
    img_src: []const u8,
    img_srcset: []const u8,
    img_sizes: []const u8,
    context: Context,
) ?Selection {
    for (sources) |source| {
        if (!context.supportsType(source.mime_type) or !mediaMatches(source.media, context)) continue;
        if (selectCandidateSet("", source.srcset, source.sizes, context, .picture)) |selected| return selected;
    }
    return selectImg(img_src, img_srcset, img_sizes, context);
}

fn selectCandidateSet(
    src: []const u8,
    srcset: []const u8,
    sizes: []const u8,
    context: Context,
    kind: SourceKind,
) ?Selection {
    if (trim(srcset).len == 0) return null;

    var iterator = SrcsetIterator{ .source = srcset };
    var choice = CandidateChoice{};
    var any = false;
    var any_width = false;
    var descriptor_mode: ?bool = null;
    var mixed_descriptors = false;
    var has_one_x = false;
    const slot_width = sourceSize(sizes, context);
    while (iterator.next()) |candidate| {
        const is_width = candidate.source_width != 0;
        if (descriptor_mode) |width_mode| {
            if (width_mode != is_width) mixed_descriptors = true;
        } else {
            descriptor_mode = is_width;
        }
        any = true;
        any_width = any_width or is_width;
        has_one_x = has_one_x or (candidate.source_width == 0 and candidate.density_milli == 1000);
        const density = candidateDensity(candidate, slot_width);
        choice.consider(candidate, density, context.dpr());
    }
    if (!any or mixed_descriptors) return null;

    // In an x-descriptor set SRC is the implicit 1x candidate unless the set
    // already supplies one. Width-descriptor sets derive density from SIZES.
    const fallback = trim(src);
    if (!any_width and !has_one_x and fallback.len != 0) {
        choice.consider(.{ .url = fallback }, 1000, context.dpr());
    }
    const selected = choice.result() orelse return null;
    return .{
        .url = selected.url,
        .density_milli = candidateDensity(selected, slot_width),
        .source_width = selected.source_width,
        .kind = kind,
    };
}

fn fallbackSelection(src: []const u8, kind: SourceKind) ?Selection {
    const value = trim(src);
    if (value.len == 0) return null;
    return .{ .url = value, .kind = kind };
}

fn candidateDensity(candidate: Candidate, slot_width: u32) u32 {
    if (candidate.source_width == 0) return @max(1, candidate.density_milli);
    const numerator = @as(u64, candidate.source_width) * 1000;
    return @intCast(@min(@as(u64, std.math.maxInt(u32)), (numerator + slot_width - 1) / @max(1, slot_width)));
}

const SrcsetIterator = struct {
    source: []const u8,
    cursor: usize = 0,

    fn next(self: *SrcsetIterator) ?Candidate {
        while (self.cursor < self.source.len) {
            while (self.cursor < self.source.len and (isSpace(self.source[self.cursor]) or self.source[self.cursor] == ',')) self.cursor += 1;
            if (self.cursor >= self.source.len) return null;

            const url_start = self.cursor;
            while (self.cursor < self.source.len and !isSpace(self.source[self.cursor])) self.cursor += 1;
            var url_end = self.cursor;
            var comma_terminated = false;
            while (url_end > url_start and self.source[url_end - 1] == ',') {
                url_end -= 1;
                comma_terminated = true;
            }
            const url = self.source[url_start..url_end];
            if (comma_terminated) {
                if (url.len != 0) return .{ .url = url };
                continue;
            }

            while (self.cursor < self.source.len and isSpace(self.source[self.cursor])) self.cursor += 1;
            const descriptor_start = self.cursor;
            var depth: usize = 0;
            var quote: u8 = 0;
            while (self.cursor < self.source.len) : (self.cursor += 1) {
                const byte = self.source[self.cursor];
                if (quote != 0) {
                    if (byte == '\\' and self.cursor + 1 < self.source.len) self.cursor += 1 else if (byte == quote) quote = 0;
                } else if (byte == '"' or byte == '\'') {
                    quote = byte;
                } else if (byte == '(') {
                    depth += 1;
                } else if (byte == ')' and depth > 0) {
                    depth -= 1;
                } else if (byte == ',' and depth == 0) {
                    break;
                }
            }
            const descriptor = trim(self.source[descriptor_start..self.cursor]);
            if (self.cursor < self.source.len) self.cursor += 1;
            if (url.len == 0) continue;
            if (descriptor.len == 0) return .{ .url = url };
            if (parseDescriptor(url, descriptor)) |candidate| return candidate;
        }
        return null;
    }
};

fn parseDescriptor(url: []const u8, descriptor: []const u8) ?Candidate {
    var tokens = std.mem.tokenizeAny(u8, descriptor, " \t\r\n\x0c");
    const token = tokens.next() orelse return .{ .url = url };
    if (tokens.next() != null or token.len < 2) return null;
    const suffix = token[token.len - 1];
    const number = token[0 .. token.len - 1];
    return switch (suffix) {
        'x', 'X' => if (parsePositiveDecimalMilli(number)) |density| .{ .url = url, .density_milli = density } else null,
        'w', 'W' => if (parsePositiveU32(number)) |width| .{ .url = url, .source_width = width } else null,
        else => null,
    };
}

fn sourceSize(sizes: []const u8, context: Context) u32 {
    var cursor: usize = 0;
    while (nextTopLevelSegment(sizes, &cursor)) |entry| {
        const pair = splitSizeEntry(entry);
        const length = parseCssLength(pair.length, context) orelse continue;
        if (pair.media.len == 0 or mediaMatches(pair.media, context)) return @max(1, length);
    }
    return @max(1, context.viewport_width);
}

const SizeEntry = struct { media: []const u8, length: []const u8 };

fn splitSizeEntry(input: []const u8) SizeEntry {
    const value = trim(input);
    var cursor = value.len;
    while (cursor > 0 and isSpace(value[cursor - 1])) cursor -= 1;
    const end = cursor;
    var depth: usize = 0;
    while (cursor > 0) {
        cursor -= 1;
        const byte = value[cursor];
        if (byte == ')') depth += 1 else if (byte == '(' and depth > 0) depth -= 1 else if (isSpace(byte) and depth == 0) {
            return .{ .media = trim(value[0..cursor]), .length = trim(value[cursor + 1 .. end]) };
        }
    }
    return .{ .media = "", .length = value[0..end] };
}

fn parseCssLength(input: []const u8, context: Context) ?u32 {
    const value = trim(input);
    if (endsWithIgnoreCase(value, "px")) return parsePositiveDecimalRounded(value[0 .. value.len - 2]);
    if (endsWithIgnoreCase(value, "vw")) {
        const milli = parsePositiveDecimalMilli(value[0 .. value.len - 2]) orelse return null;
        return @intCast(@max(@as(u64, 1), (@as(u64, context.viewport_width) * milli + 99_999) / 100_000));
    }
    if (endsWithIgnoreCase(value, "vh")) {
        const milli = parsePositiveDecimalMilli(value[0 .. value.len - 2]) orelse return null;
        return @intCast(@max(@as(u64, 1), (@as(u64, context.viewport_height) * milli + 99_999) / 100_000));
    }
    return null;
}

/// Evaluates the deliberately bounded media subset shared by PICTURE and
/// SIZES: screen/all, min/max/exact viewport dimensions and orientation.
/// Comma-separated alternatives and `not`/`only` are supported. Unknown
/// features do not match.
pub fn mediaMatches(input: []const u8, context: Context) bool {
    if (trim(input).len == 0) return true;
    var cursor: usize = 0;
    while (nextTopLevelSegment(input, &cursor)) |query| {
        if (mediaQueryMatches(query, context)) return true;
    }
    return false;
}

fn mediaQueryMatches(input: []const u8, context: Context) bool {
    var query = trim(input);
    var negate = false;
    if (takeWordPrefix(query, "not")) |rest| {
        negate = true;
        query = trim(rest);
    } else if (takeWordPrefix(query, "only")) |rest| {
        query = trim(rest);
    }
    var matched = true;
    var start: usize = 0;
    var cursor: usize = 0;
    var depth: usize = 0;
    while (cursor <= query.len) {
        const at_end = cursor == query.len;
        if (!at_end) {
            if (query[cursor] == '(') depth += 1 else if (query[cursor] == ')' and depth > 0) depth -= 1;
        }
        if (at_end or (depth == 0 and wordAt(query, cursor, "and"))) {
            if (!mediaClauseMatches(trim(query[start..cursor]), context)) matched = false;
            if (at_end) break;
            cursor += 3;
            start = cursor;
            continue;
        }
        cursor += 1;
    }
    return if (negate) !matched else matched;
}

fn mediaClauseMatches(input: []const u8, context: Context) bool {
    var clause = trim(input);
    if (clause.len == 0) return true;
    if (std.ascii.eqlIgnoreCase(clause, "screen") or std.ascii.eqlIgnoreCase(clause, "all")) return true;
    if (std.ascii.eqlIgnoreCase(clause, "print")) return false;
    if (clause.len < 3 or clause[0] != '(' or clause[clause.len - 1] != ')') return false;
    clause = trim(clause[1 .. clause.len - 1]);
    const colon = std.mem.indexOfScalar(u8, clause, ':') orelse return false;
    const feature = trim(clause[0..colon]);
    const value = trim(clause[colon + 1 ..]);
    if (std.ascii.eqlIgnoreCase(feature, "orientation")) {
        if (std.ascii.eqlIgnoreCase(value, "portrait")) return context.viewport_height >= context.viewport_width;
        if (std.ascii.eqlIgnoreCase(value, "landscape")) return context.viewport_width > context.viewport_height;
        return false;
    }
    const pixels = parsePixelDimension(value) orelse return false;
    const actual = if (endsWithIgnoreCase(feature, "width")) context.viewport_width else if (endsWithIgnoreCase(feature, "height")) context.viewport_height else return false;
    if (startsWithIgnoreCase(feature, "min-")) return actual >= pixels;
    if (startsWithIgnoreCase(feature, "max-")) return actual <= pixels;
    if (std.ascii.eqlIgnoreCase(feature, "width") or std.ascii.eqlIgnoreCase(feature, "height")) return actual == pixels;
    return false;
}

fn parsePixelDimension(value: []const u8) ?u32 {
    if (!endsWithIgnoreCase(trim(value), "px")) return null;
    const clean = trim(value);
    return parsePositiveDecimalRounded(clean[0 .. clean.len - 2]);
}

/// Returns successive CSS url() payloads without allocating. Quoted payloads
/// are unquoted; CSS escape decoding remains the caller's responsibility.
pub fn nextCssUrl(input: []const u8, cursor: *usize) ?[]const u8 {
    while (findFunction(input, cursor.*, "url")) |function| {
        cursor.* = function.after;
        const value = unquote(trim(function.content));
        if (value.len != 0) return value;
    }
    cursor.* = input.len;
    return null;
}

/// Selects a CSS url() or image-set() value. image-set candidates support x
/// descriptors and optional type() hints, using the same type policy as
/// PICTURE. Data URLs remain intact because commas inside functions/quotes are
/// never treated as candidate separators.
pub fn selectCssImage(input: []const u8, context: Context) ?Selection {
    if (findFunction(input, 0, "image-set") orelse findFunction(input, 0, "-webkit-image-set")) |function| {
        if (selectCssImageSet(function.content, context)) |selected| return selected;
    }
    var cursor: usize = 0;
    const url = nextCssUrl(input, &cursor) orelse return null;
    return .{ .url = url, .kind = .css_url };
}

fn selectCssImageSet(input: []const u8, context: Context) ?Selection {
    var cursor: usize = 0;
    var choice = CandidateChoice{};
    while (nextTopLevelSegment(input, &cursor)) |segment| {
        const parsed = parseCssImageSetCandidate(segment, context) orelse continue;
        choice.consider(parsed, parsed.density_milli, context.dpr());
    }
    const result = choice.result() orelse return null;
    return .{ .url = result.url, .density_milli = result.density_milli, .kind = .css_image_set };
}

fn parseCssImageSetCandidate(input: []const u8, context: Context) ?Candidate {
    const value = trim(input);
    if (value.len == 0) return null;
    var cursor: usize = 0;
    var url: []const u8 = "";
    if (value[0] == '"' or value[0] == '\'') {
        const quote = value[0];
        cursor = 1;
        const start = cursor;
        while (cursor < value.len and value[cursor] != quote) : (cursor += 1) {
            if (value[cursor] == '\\' and cursor + 1 < value.len) cursor += 1;
        }
        if (cursor >= value.len) return null;
        url = value[start..cursor];
        cursor += 1;
    } else {
        const function = findFunction(value, 0, "url") orelse return null;
        if (trim(value[0..function.start]).len != 0) return null;
        url = unquote(trim(function.content));
        cursor = function.after;
    }
    if (url.len == 0) return null;

    var density: u32 = 1000;
    var saw_density = false;
    while (cursor < value.len) {
        while (cursor < value.len and isSpace(value[cursor])) cursor += 1;
        if (cursor >= value.len) break;
        if (findFunction(value, cursor, "type")) |function| {
            if (function.start == cursor) {
                if (!context.supportsType(unquote(trim(function.content)))) return null;
                cursor = function.after;
                continue;
            }
        }
        const start = cursor;
        while (cursor < value.len and !isSpace(value[cursor])) cursor += 1;
        const token = value[start..cursor];
        if (token.len < 2 or (token[token.len - 1] != 'x' and token[token.len - 1] != 'X') or saw_density) return null;
        density = parsePositiveDecimalMilli(token[0 .. token.len - 1]) orelse return null;
        saw_density = true;
    }
    return .{ .url = url, .density_milli = density };
}

const CssFunction = struct {
    start: usize,
    content: []const u8,
    after: usize,
};

fn findFunction(input: []const u8, from: usize, name: []const u8) ?CssFunction {
    if (from >= input.len) return null;
    var cursor = from;
    while (cursor + name.len < input.len) : (cursor += 1) {
        if (!std.ascii.eqlIgnoreCase(input[cursor .. cursor + name.len], name)) continue;
        if (cursor > 0 and isNameByte(input[cursor - 1])) continue;
        var open = cursor + name.len;
        while (open < input.len and isSpace(input[open])) open += 1;
        if (open >= input.len or input[open] != '(') continue;
        var scan = open + 1;
        var depth: usize = 1;
        var quote: u8 = 0;
        while (scan < input.len) : (scan += 1) {
            const byte = input[scan];
            if (quote != 0) {
                if (byte == '\\' and scan + 1 < input.len) scan += 1 else if (byte == quote) quote = 0;
            } else if (byte == '"' or byte == '\'') {
                quote = byte;
            } else if (byte == '(') {
                depth += 1;
            } else if (byte == ')') {
                depth -= 1;
                if (depth == 0) return .{ .start = cursor, .content = input[open + 1 .. scan], .after = scan + 1 };
            }
        }
        return null;
    }
    return null;
}

fn nextTopLevelSegment(input: []const u8, cursor: *usize) ?[]const u8 {
    while (cursor.* < input.len and (isSpace(input[cursor.*]) or input[cursor.*] == ',')) cursor.* += 1;
    if (cursor.* >= input.len) return null;
    const start = cursor.*;
    var depth: usize = 0;
    var quote: u8 = 0;
    while (cursor.* < input.len) : (cursor.* += 1) {
        const byte = input[cursor.*];
        if (quote != 0) {
            if (byte == '\\' and cursor.* + 1 < input.len) cursor.* += 1 else if (byte == quote) quote = 0;
        } else if (byte == '"' or byte == '\'') {
            quote = byte;
        } else if (byte == '(') {
            depth += 1;
        } else if (byte == ')' and depth > 0) {
            depth -= 1;
        } else if (byte == ',' and depth == 0) {
            const end = cursor.*;
            cursor.* += 1;
            return trim(input[start..end]);
        }
    }
    return trim(input[start..]);
}

/// Decodes a data URL into caller-owned storage. The first comma after the
/// metadata is the delimiter; all later commas are payload and are preserved.
/// Decoded payloads above 128 KiB are rejected before writing.
pub fn decodeDataUrl(input: []const u8, output: []u8) DataUrlError!DataUrl {
    if (!startsWithIgnoreCase(input, "data:")) return error.NotDataUrl;
    const comma = std.mem.indexOfScalarPos(u8, input, 5, ',') orelse return error.MissingComma;
    const metadata = input[5..comma];
    const payload = input[comma + 1 ..];
    var media: []const u8 = "text/plain";
    var base64 = false;
    var token_cursor: usize = 0;
    var token_index: usize = 0;
    while (nextMetadataToken(metadata, &token_cursor)) |token| : (token_index += 1) {
        if (token_index == 0 and token.len != 0 and std.mem.indexOfScalar(u8, token, '/') != null) {
            media = trim(token);
        } else if (std.ascii.eqlIgnoreCase(trim(token), "base64")) {
            base64 = true;
        }
    }

    if (base64) {
        const decoder = std.base64.standard.decoderWithIgnore(" \t\r\n");
        const upper = decoder.calcSizeUpperBound(payload.len);
        if (upper > max_data_url_bytes) return error.TooLarge;
        if (upper > output.len) return error.BufferTooSmall;
        const count = decoder.decode(output[0..upper], payload) catch return error.InvalidBase64;
        if (count > max_data_url_bytes) return error.TooLarge;
        return .{ .media_type = media, .bytes = output[0..count], .base64 = true };
    }

    var read: usize = 0;
    var written: usize = 0;
    while (read < payload.len) {
        if (written >= max_data_url_bytes) return error.TooLarge;
        if (written >= output.len) return error.BufferTooSmall;
        if (payload[read] == '%') {
            if (read + 2 >= payload.len) return error.InvalidEscape;
            const high = hex(payload[read + 1]) orelse return error.InvalidEscape;
            const low = hex(payload[read + 2]) orelse return error.InvalidEscape;
            output[written] = high * 16 + low;
            read += 3;
        } else {
            output[written] = payload[read];
            read += 1;
        }
        written += 1;
    }
    return .{ .media_type = media, .bytes = output[0..written], .base64 = false };
}

fn nextMetadataToken(input: []const u8, cursor: *usize) ?[]const u8 {
    if (cursor.* > input.len) return null;
    const start = cursor.*;
    const end = std.mem.indexOfScalarPos(u8, input, start, ';') orelse input.len;
    cursor.* = if (end < input.len) end + 1 else input.len + 1;
    return input[start..end];
}

fn mimeType(input: []const u8) []const u8 {
    const clean = trim(input);
    const semicolon = std.mem.indexOfScalar(u8, clean, ';') orelse clean.len;
    return trim(clean[0..semicolon]);
}

fn parsePositiveU32(input: []const u8) ?u32 {
    if (input.len == 0) return null;
    var value: u64 = 0;
    for (input) |byte| {
        if (byte < '0' or byte > '9') return null;
        value = value * 10 + (byte - '0');
        if (value > std.math.maxInt(u32)) return null;
    }
    if (value == 0) return null;
    return @intCast(value);
}

fn parsePositiveDecimalMilli(input: []const u8) ?u32 {
    if (input.len == 0) return null;
    var whole: u64 = 0;
    var fraction: u32 = 0;
    var fraction_digits: u8 = 0;
    var saw_digit = false;
    var saw_dot = false;
    for (input) |byte| {
        if (byte == '.' and !saw_dot) {
            saw_dot = true;
            continue;
        }
        if (byte < '0' or byte > '9') return null;
        saw_digit = true;
        if (!saw_dot) {
            whole = whole * 10 + (byte - '0');
            if (whole > std.math.maxInt(u32) / 1000) return null;
        } else if (fraction_digits < 3) {
            fraction = fraction * 10 + (byte - '0');
            fraction_digits += 1;
        }
    }
    if (!saw_digit) return null;
    while (fraction_digits < 3) : (fraction_digits += 1) fraction *= 10;
    const result = whole * 1000 + fraction;
    if (result == 0 or result > std.math.maxInt(u32)) return null;
    return @intCast(result);
}

fn parsePositiveDecimalRounded(input: []const u8) ?u32 {
    const milli = parsePositiveDecimalMilli(trim(input)) orelse return null;
    return @max(1, (milli + 999) / 1000);
}

fn hex(byte: u8) ?u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        'A'...'F' => byte - 'A' + 10,
        else => null,
    };
}

fn takeWordPrefix(input: []const u8, word: []const u8) ?[]const u8 {
    if (!startsWithIgnoreCase(input, word)) return null;
    if (input.len > word.len and !isSpace(input[word.len])) return null;
    return input[word.len..];
}

fn wordAt(input: []const u8, at: usize, word: []const u8) bool {
    if (at + word.len > input.len or !std.ascii.eqlIgnoreCase(input[at .. at + word.len], word)) return false;
    if (at > 0 and !isSpace(input[at - 1])) return false;
    return at + word.len == input.len or isSpace(input[at + word.len]);
}

fn trim(input: []const u8) []const u8 {
    return std.mem.trim(u8, input, " \t\r\n\x0c");
}

fn unquote(input: []const u8) []const u8 {
    if (input.len >= 2 and ((input[0] == '"' and input[input.len - 1] == '"') or (input[0] == '\'' and input[input.len - 1] == '\''))) return input[1 .. input.len - 1];
    return input;
}

fn isSpace(byte: u8) bool {
    return byte == ' ' or byte == '\t' or byte == '\r' or byte == '\n' or byte == 0x0c;
}

fn isNameByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '-' or byte == '_';
}

fn startsWithIgnoreCase(input: []const u8, prefix: []const u8) bool {
    return input.len >= prefix.len and std.ascii.eqlIgnoreCase(input[0..prefix.len], prefix);
}

fn endsWithIgnoreCase(input: []const u8, suffix: []const u8) bool {
    return input.len >= suffix.len and std.ascii.eqlIgnoreCase(input[input.len - suffix.len ..], suffix);
}

test "IMG srcset selects density and width candidates with SIZES" {
    const dpr_one = Context{ .viewport_width = 800, .viewport_height = 600 };
    const density = selectImg("fallback.png", "small.png 1x, large.png 2x", "", dpr_one).?;
    try std.testing.expectEqualStrings("small.png", density.url);
    try std.testing.expectEqual(SourceKind.img_srcset, density.kind);

    const dpr_two = Context{ .viewport_width = 800, .viewport_height = 600, .device_pixel_ratio_milli = 1750 };
    try std.testing.expectEqualStrings("large.png", selectImg("fallback.png", "small.png 1x, large.png 2x", "", dpr_two).?.url);

    const width = selectImg("fallback.png", "narrow.png 400w, medium.png 800w, wide.png 1200w", "(max-width: 600px) 100vw, 50vw", dpr_one).?;
    try std.testing.expectEqualStrings("narrow.png", width.url);
    try std.testing.expectEqual(@as(u32, 400), width.source_width);
}

test "SRC is an implicit one-x candidate and data URL comma stays in srcset URL" {
    const high = Context{ .device_pixel_ratio_milli = 2000 };
    try std.testing.expectEqualStrings("two.png", selectImg("fallback.png", "two.png 2x", "", high).?.url);
    try std.testing.expectEqualStrings("fallback.png", selectImg("fallback.png", "two.png 2x", "", .{}).?.url);
    const selected = selectImg("", "data:image/svg+xml,%3Csvg%3E 1x, two.png 2x", "", .{}).?;
    try std.testing.expectEqualStrings("data:image/svg+xml,%3Csvg%3E", selected.url);
    try std.testing.expectEqualStrings("fallback.png", selectImg("fallback.png", "one.png 1x, wide.png 900w", "", .{}).?.url);
}

test "PICTURE honors document order media type and IMG fallback" {
    const sources = [_]PictureSource{
        .{ .srcset = "unsupported.webp", .mime_type = "image/webp" },
        .{ .srcset = "portrait.svg 1x, portrait-2.svg 2x", .media = "screen and (max-width: 500px)", .mime_type = "image/svg+xml" },
        .{ .srcset = "wide.png", .media = "(min-width: 700px)", .mime_type = "image/png" },
    };
    const narrow = Context{ .viewport_width = 480, .viewport_height = 800 };
    try std.testing.expectEqualStrings("portrait.svg", selectPicture(&sources, "fallback.bmp", "", "", narrow).?.url);
    const wide = Context{ .viewport_width = 900, .viewport_height = 600 };
    try std.testing.expectEqualStrings("wide.png", selectPicture(&sources, "fallback.bmp", "", "", wide).?.url);
    const fallback = Context{ .viewport_width = 600, .viewport_height = 600 };
    try std.testing.expectEqualStrings("fallback.bmp", selectPicture(&sources, "fallback.bmp", "", "", fallback).?.url);
}

test "media subset handles alternatives orientation only and unknown features" {
    const context = Context{ .viewport_width = 900, .viewport_height = 500 };
    try std.testing.expect(mediaMatches("only screen and (min-width: 800px) and (orientation: landscape)", context));
    try std.testing.expect(mediaMatches("(max-width: 300px), (min-height: 400px)", context));
    try std.testing.expect(!mediaMatches("print", context));
    try std.testing.expect(!mediaMatches("screen and (prefers-color-scheme: dark)", context));
}

test "CSS URL iterator and image-set preserve data commas and select DPR" {
    const css = "linear-gradient(red, blue), url('fallback.png')";
    var cursor: usize = 0;
    try std.testing.expectEqualStrings("fallback.png", nextCssUrl(css, &cursor).?);
    const set = "image-set(url(data:image/svg+xml,%3Csvg%3E) 1x type('image/svg+xml'), url(two.png) 2x type('image/png'))";
    try std.testing.expectEqualStrings("data:image/svg+xml,%3Csvg%3E", selectCssImage(set, .{}).?.url);
    try std.testing.expectEqualStrings("two.png", selectCssImage(set, .{ .device_pixel_ratio_milli = 2000 }).?.url);
    const unsupported = "image-set(url(no.webp) 1x type('image/webp'), url(ok.png) 2x type('image/png'))";
    try std.testing.expectEqualStrings("ok.png", selectCssImage(unsupported, .{}).?.url);
}

test "data URL percent and base64 decoding is bounded and comma safe" {
    var output: [256]u8 = undefined;
    const percent = try decodeDataUrl("data:image/svg+xml;charset=utf-8,%3Csvg%3Ea,b%3C/svg%3E", &output);
    try std.testing.expectEqualStrings("image/svg+xml", percent.media_type);
    try std.testing.expectEqualStrings("<svg>a,b</svg>", percent.bytes);
    try std.testing.expect(!percent.base64);

    const encoded = try decodeDataUrl("DATA:image/png;base64,AAEC/w==", &output);
    try std.testing.expectEqualSlices(u8, &.{ 0, 1, 2, 255 }, encoded.bytes);
    try std.testing.expect(encoded.base64);
    try std.testing.expectError(error.InvalidEscape, decodeDataUrl("data:,bad%2", &output));
    try std.testing.expectError(error.BufferTooSmall, decodeDataUrl("data:,abcd", output[0..3]));
}
