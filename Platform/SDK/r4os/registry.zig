const std = @import("std");
const core = @import("registry_core.zig");

pub const CoreError = core.Error;
pub const Error = core.Error || error{InvalidText};

pub const magic = core.magic;
pub const header_size = core.header_size;
pub const key_record_size = core.key_record_size;
pub const value_record_size = core.value_record_size;
pub const invalid_index = core.invalid_index;

pub const HiveKind = core.HiveKind;
pub const ValueType = core.ValueType;
pub const Header = core.Header;
pub const KeyRecord = core.KeyRecord;
pub const ValueRecord = core.ValueRecord;
pub const Value = core.Value;
pub const ParsedRoot = core.ParsedRoot;
pub const HiveView = core.HiveView;
pub const BuildValue = core.BuildValue;
pub const BuildKey = core.BuildKey;
pub const BuildScratch = core.BuildScratch;

pub const parseHive = core.parseHive;
pub const parseRoot = core.parseRoot;
pub const buildHiveInto = core.buildHiveInto;

pub fn buildHive(allocator: std.mem.Allocator, kind: HiveKind, generation: u64, values: []const BuildValue) Error![]u8 {
    const key_capacity = try estimateBuildKeyCapacity(kind, values);
    const file_capacity = try estimateHiveCapacity(kind, values, key_capacity);

    const keys = allocator.alloc(BuildKey, key_capacity) catch return Error.OutOfMemory;
    defer allocator.free(keys);
    const value_key_indices = allocator.alloc(u32, values.len) catch return Error.OutOfMemory;
    defer allocator.free(value_key_indices);
    const flat_key_order = allocator.alloc(u32, key_capacity) catch return Error.OutOfMemory;
    defer allocator.free(flat_key_order);

    const out = allocator.alloc(u8, file_capacity) catch return Error.OutOfMemory;
    errdefer allocator.free(out);

    const built = try core.buildHiveInto(out, .{
        .keys = keys,
        .value_key_indices = value_key_indices,
        .flat_key_order = flat_key_order,
    }, kind, generation, values);

    if (built.len == out.len) return out;
    const resized = allocator.realloc(out, built.len) catch {
        const exact = allocator.alloc(u8, built.len) catch return Error.OutOfMemory;
        @memcpy(exact, built);
        allocator.free(out);
        return exact;
    };
    return resized;
}

pub fn importTextHive(allocator: std.mem.Allocator, text: []const u8, generation: u64) Error![]u8 {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const scratch = arena_state.allocator();

    var values: std.ArrayList(BuildValue) = .empty;
    defer values.deinit(scratch);

    var seen_header = false;
    var current_key: []const u8 = "";
    var hive_kind: ?HiveKind = null;
    var lines = std.mem.splitScalar(u8, stripUtf8Bom(text), '\n');
    while (lines.next()) |raw_line| {
        const line = trimPath(stripLineEnding(raw_line));
        if (line.len == 0 or line[0] == ';' or line[0] == '#') continue;

        if (!seen_header) {
            if (!asciiEqlIgnoreCase(line, "R4REG_FORMAT=1")) return Error.InvalidText;
            seen_header = true;
            continue;
        }

        if (line[0] == '[') {
            if (line.len < 3 or line[line.len - 1] != ']') return Error.InvalidText;
            const section = trimPath(line[1 .. line.len - 1]);
            const parsed = parseRoot(section) orelse return Error.InvalidPath;
            if (hive_kind) |kind| {
                if (kind != parsed.kind) return Error.RootMismatch;
            } else {
                hive_kind = parsed.kind;
            }
            current_key = scratch.dupe(u8, section) catch return Error.OutOfMemory;
            continue;
        }

        if (current_key.len == 0) return Error.InvalidText;
        try parseTextValue(scratch, current_key, line, &values);
    }

    if (!seen_header) return Error.InvalidText;
    const kind = hive_kind orelse return Error.BadHiveKind;
    return buildHive(allocator, kind, generation, values.items);
}

pub fn exportTextHive(allocator: std.mem.Allocator, hive: HiveView) Error![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "R4REG_FORMAT=1\r\n\r\n");

    var key_index: u32 = 0;
    while (key_index < hive.header.key_count) : (key_index += 1) {
        const key = hive.keyAt(key_index);
        if (key.value_count == 0) continue;

        const path = try keyPathString(allocator, hive, key_index);
        defer allocator.free(path);
        try appendFmt(allocator, &out, "[{s}]\r\n", .{path});

        var value_offset: u32 = 0;
        while (value_offset < key.value_count) : (value_offset += 1) {
            const value = hive.valueAt(key.first_value_index + value_offset);
            try out.appendSlice(allocator, hive.valueName(value));
            try appendFmt(allocator, &out, ":{s}=", .{valueTypeName(value.value_type)});
            try appendTextValueData(allocator, &out, value.value_type, hive.valueData(value));
            try out.appendSlice(allocator, "\r\n");
        }
        try out.appendSlice(allocator, "\r\n");
    }

    return out.toOwnedSlice(allocator) catch return Error.OutOfMemory;
}

fn estimateBuildKeyCapacity(kind: HiveKind, values: []const BuildValue) Error!usize {
    var key_count: usize = 1;
    for (values) |value| {
        const parsed = parseRoot(value.key_path) orelse return Error.InvalidPath;
        if (parsed.kind != kind) return Error.RootMismatch;
        var rest = parsed.rest;
        while (nextPathComponent(&rest)) |_| {
            key_count = try checkedAdd(key_count, 1);
            if (key_count > std.math.maxInt(u32)) return Error.TooManyEntries;
        }
    }
    return key_count;
}

fn estimateHiveCapacity(kind: HiveKind, values: []const BuildValue, key_capacity: usize) Error!usize {
    var string_heap_size: usize = 0;
    var data_heap_size: usize = 0;

    for (values) |value| {
        const parsed = parseRoot(value.key_path) orelse return Error.InvalidPath;
        if (parsed.kind != kind) return Error.RootMismatch;
        var rest = parsed.rest;
        while (nextPathComponent(&rest)) |component| {
            string_heap_size = try checkedAdd(string_heap_size, component.len);
        }
        string_heap_size = try checkedAdd(string_heap_size, value.name.len);
        data_heap_size = try checkedAdd(data_heap_size, value.data.len);
    }

    var file_size: usize = header_size;
    file_size = try checkedAdd(file_size, try checkedMul(key_capacity, key_record_size));
    file_size = try checkedAdd(file_size, try checkedMul(values.len, value_record_size));
    file_size = try checkedAdd(file_size, string_heap_size);
    file_size = try checkedAdd(file_size, data_heap_size);
    if (file_size > std.math.maxInt(u32)) return Error.TooManyEntries;
    return file_size;
}

fn checkedAdd(a: usize, b: usize) Error!usize {
    if (b > std.math.maxInt(usize) - a) return Error.TooManyEntries;
    return a + b;
}

fn checkedMul(a: usize, b: usize) Error!usize {
    if (a != 0 and b > std.math.maxInt(usize) / a) return Error.TooManyEntries;
    return a * b;
}

fn parseTextValue(allocator: std.mem.Allocator, current_key: []const u8, line: []const u8, values: *std.ArrayList(BuildValue)) Error!void {
    const equals = findByte(line, '=') orelse return Error.InvalidText;
    const left = trimPath(line[0..equals]);
    const right = trimPath(line[equals + 1 ..]);

    const colon = findByte(left, ':');
    const name = if (colon) |pos| trimPath(left[0..pos]) else left;
    const value_type = if (colon) |pos| try parseValueTypeName(trimPath(left[pos + 1 ..])) else ValueType.string;

    const name_copy = allocator.dupe(u8, name) catch return Error.OutOfMemory;
    const data = try parseTextData(allocator, value_type, right);
    try values.append(allocator, .{
        .key_path = current_key,
        .name = name_copy,
        .value_type = value_type,
        .data = data,
    });
}

fn parseValueTypeName(text: []const u8) Error!ValueType {
    if (asciiEqlIgnoreCase(text, "string")) return .string;
    if (asciiEqlIgnoreCase(text, "u32")) return .u32;
    if (asciiEqlIgnoreCase(text, "u64")) return .u64;
    if (asciiEqlIgnoreCase(text, "bool")) return .bool;
    if (asciiEqlIgnoreCase(text, "binary")) return .binary;
    if (asciiEqlIgnoreCase(text, "multi_string")) return .multi_string;
    return Error.BadValue;
}

fn parseTextData(allocator: std.mem.Allocator, value_type: ValueType, text: []const u8) Error![]const u8 {
    return switch (value_type) {
        .string => parseQuotedString(allocator, text),
        .u32 => parseIntegerData(allocator, text, 4),
        .u64 => parseIntegerData(allocator, text, 8),
        .bool => parseBoolData(allocator, text),
        .binary => parseBinaryData(allocator, text),
        .multi_string => parseMultiStringData(allocator, text),
    };
}

fn parseQuotedString(allocator: std.mem.Allocator, text: []const u8) Error![]const u8 {
    const parsed = try parseQuotedStringPrefix(allocator, text);
    if (trimPath(parsed.rest).len != 0) return Error.InvalidText;
    return parsed.value;
}

const ParsedTextString = struct {
    value: []const u8,
    rest: []const u8,
};

fn parseQuotedStringPrefix(allocator: std.mem.Allocator, text: []const u8) Error!ParsedTextString {
    const input = trimPath(text);
    if (input.len == 0 or input[0] != '"') return Error.InvalidText;

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var index: usize = 1;
    while (index < input.len) : (index += 1) {
        const ch = input[index];
        if (ch == '"') {
            return .{
                .value = out.toOwnedSlice(allocator) catch return Error.OutOfMemory,
                .rest = input[index + 1 ..],
            };
        }
        if (ch != '\\') {
            try out.append(allocator, ch);
            continue;
        }

        index += 1;
        if (index >= input.len) return Error.InvalidText;
        const escaped = input[index];
        switch (escaped) {
            '\\' => try out.append(allocator, '\\'),
            '"' => try out.append(allocator, '"'),
            'n' => try out.append(allocator, '\n'),
            'r' => try out.append(allocator, '\r'),
            't' => try out.append(allocator, '\t'),
            'x' => {
                if (index + 2 >= input.len) return Error.InvalidText;
                const hi = hexNibble(input[index + 1]) orelse return Error.InvalidText;
                const lo = hexNibble(input[index + 2]) orelse return Error.InvalidText;
                try out.append(allocator, (hi << 4) | lo);
                index += 2;
            },
            else => return Error.InvalidText,
        }
    }
    return Error.InvalidText;
}

fn parseIntegerData(allocator: std.mem.Allocator, text: []const u8, comptime byte_count: usize) Error![]const u8 {
    const value = try parseUnsigned(text);
    if (byte_count == 4 and value > std.math.maxInt(u32)) return Error.BadData;
    const out = allocator.alloc(u8, byte_count) catch return Error.OutOfMemory;
    if (byte_count == 4) {
        writeU32(out, 0, @intCast(value));
    } else {
        writeU64(out, 0, value);
    }
    return out;
}

fn parseUnsigned(text: []const u8) Error!u64 {
    const trimmed = trimPath(text);
    if (trimmed.len == 0) return Error.BadData;
    if (trimmed.len > 2 and trimmed[0] == '0' and (trimmed[1] == 'x' or trimmed[1] == 'X')) {
        if (trimmed.len == 2) return Error.BadData;
        return std.fmt.parseInt(u64, trimmed[2..], 16) catch return Error.BadData;
    }
    return std.fmt.parseInt(u64, trimmed, 10) catch return Error.BadData;
}

fn parseBoolData(allocator: std.mem.Allocator, text: []const u8) Error![]const u8 {
    const trimmed = trimPath(text);
    const value: u8 = if (asciiEqlIgnoreCase(trimmed, "true") or asciiEqlIgnoreCase(trimmed, "1"))
        1
    else if (asciiEqlIgnoreCase(trimmed, "false") or asciiEqlIgnoreCase(trimmed, "0"))
        0
    else
        return Error.BadData;
    const out = allocator.alloc(u8, 1) catch return Error.OutOfMemory;
    out[0] = value;
    return out;
}

fn parseBinaryData(allocator: std.mem.Allocator, text: []const u8) Error![]const u8 {
    var compact: std.ArrayList(u8) = .empty;
    defer compact.deinit(allocator);
    for (text) |ch| {
        if (isSpace(ch)) continue;
        if (hexNibble(ch) == null) return Error.BadData;
        try compact.append(allocator, ch);
    }
    if ((compact.items.len % 2) != 0) return Error.BadData;

    const out = allocator.alloc(u8, compact.items.len / 2) catch return Error.OutOfMemory;
    var out_index: usize = 0;
    var index: usize = 0;
    while (index < compact.items.len) : (index += 2) {
        const hi = hexNibble(compact.items[index]).?;
        const lo = hexNibble(compact.items[index + 1]).?;
        out[out_index] = (hi << 4) | lo;
        out_index += 1;
    }
    return out;
}

fn parseMultiStringData(allocator: std.mem.Allocator, text: []const u8) Error![]const u8 {
    const input = trimPath(text);
    if (input.len < 2 or input[0] != '(' or input[input.len - 1] != ')') return Error.InvalidText;

    var items: std.ArrayList([]const u8) = .empty;
    defer items.deinit(allocator);
    var rest = trimPath(input[1 .. input.len - 1]);
    while (rest.len > 0) {
        const parsed = try parseQuotedStringPrefix(allocator, rest);
        if (parsed.value.len > std.math.maxInt(u16)) return Error.BadData;
        try items.append(allocator, parsed.value);
        rest = trimPath(parsed.rest);
        if (rest.len == 0) break;
        if (rest[0] != ',') return Error.InvalidText;
        rest = trimPath(rest[1..]);
        if (rest.len == 0) return Error.InvalidText;
    }

    var total: usize = 4;
    for (items.items) |item| total = try checkedAdd(total, 2 + item.len);
    const out = allocator.alloc(u8, total) catch return Error.OutOfMemory;
    writeU32(out, 0, @intCast(items.items.len));
    var offset: usize = 4;
    for (items.items) |item| {
        writeU16(out, offset, @intCast(item.len));
        offset += 2;
        @memcpy(out[offset .. offset + item.len], item);
        offset += item.len;
    }
    return out;
}

fn appendTextValueData(allocator: std.mem.Allocator, out: *std.ArrayList(u8), value_type: ValueType, data: []const u8) Error!void {
    switch (value_type) {
        .string => try appendEscapedString(allocator, out, data),
        .u32 => try appendFmt(allocator, out, "{d}", .{readU32(data, 0)}),
        .u64 => try appendFmt(allocator, out, "{d}", .{readU64(data, 0)}),
        .bool => try out.appendSlice(allocator, if (data[0] == 0) "false" else "true"),
        .binary => {
            for (data, 0..) |byte, index| {
                if (index != 0) try out.append(allocator, ' ');
                try appendHexByte(allocator, out, byte);
            }
        },
        .multi_string => {
            try out.append(allocator, '(');
            const count = readU32(data, 0);
            var offset: usize = 4;
            var index: u32 = 0;
            while (index < count) : (index += 1) {
                const len = readU16(data, offset);
                offset += 2;
                if (index != 0) try out.append(allocator, ',');
                try appendEscapedString(allocator, out, data[offset .. offset + len]);
                offset += len;
            }
            try out.append(allocator, ')');
        },
    }
}

fn keyPathString(allocator: std.mem.Allocator, hive: HiveView, key_index: u32) Error![]u8 {
    if (key_index >= hive.header.key_count) return Error.BadKey;
    var parts: std.ArrayList([]const u8) = .empty;
    defer parts.deinit(allocator);

    var current = key_index;
    while (current != 0) {
        const key = hive.keyAt(current);
        try parts.append(allocator, hive.keyName(key));
        current = key.parent_index;
        if (current >= hive.header.key_count) return Error.BadKey;
    }

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, hive.header.hive_kind.shortRoot());
    var index = parts.items.len;
    while (index > 0) {
        index -= 1;
        try out.append(allocator, '\\');
        try out.appendSlice(allocator, parts.items[index]);
    }
    return out.toOwnedSlice(allocator) catch return Error.OutOfMemory;
}

fn appendEscapedString(allocator: std.mem.Allocator, out: *std.ArrayList(u8), text: []const u8) Error!void {
    try out.append(allocator, '"');
    for (text) |ch| {
        switch (ch) {
            '\\' => try out.appendSlice(allocator, "\\\\"),
            '"' => try out.appendSlice(allocator, "\\\""),
            '\n' => try out.appendSlice(allocator, "\\n"),
            '\r' => try out.appendSlice(allocator, "\\r"),
            '\t' => try out.appendSlice(allocator, "\\t"),
            else => {
                if (ch < 0x20 or ch == 0x7f) {
                    try out.appendSlice(allocator, "\\x");
                    try appendHexByte(allocator, out, ch);
                } else {
                    try out.append(allocator, ch);
                }
            },
        }
    }
    try out.append(allocator, '"');
}

fn appendHexByte(allocator: std.mem.Allocator, out: *std.ArrayList(u8), byte: u8) Error!void {
    const digits = "0123456789ABCDEF";
    try out.append(allocator, digits[byte >> 4]);
    try out.append(allocator, digits[byte & 0x0f]);
}

fn appendFmt(allocator: std.mem.Allocator, out: *std.ArrayList(u8), comptime fmt: []const u8, args: anytype) Error!void {
    const text = std.fmt.allocPrint(allocator, fmt, args) catch return Error.OutOfMemory;
    defer allocator.free(text);
    try out.appendSlice(allocator, text);
}

fn valueTypeName(value_type: ValueType) []const u8 {
    return switch (value_type) {
        .string => "string",
        .u32 => "u32",
        .u64 => "u64",
        .bool => "bool",
        .binary => "binary",
        .multi_string => "multi_string",
    };
}

fn nextPathComponent(rest: *[]const u8) ?[]const u8 {
    rest.* = trimSeparators(rest.*);
    if (rest.*.len == 0) return null;
    const split = findRootEnd(rest.*);
    const component = rest.*[0..split];
    if (split < rest.*.len) {
        rest.* = rest.*[split + 1 ..];
    } else {
        rest.* = rest.*[split..];
    }
    return component;
}

fn findRootEnd(path: []const u8) usize {
    var index: usize = 0;
    while (index < path.len) : (index += 1) {
        if (path[index] == '\\' or path[index] == '/') return index;
    }
    return path.len;
}

fn findByte(text: []const u8, needle: u8) ?usize {
    for (text, 0..) |ch, index| {
        if (ch == needle) return index;
    }
    return null;
}

fn stripUtf8Bom(text: []const u8) []const u8 {
    if (text.len >= 3 and text[0] == 0xef and text[1] == 0xbb and text[2] == 0xbf) return text[3..];
    return text;
}

fn stripLineEnding(text: []const u8) []const u8 {
    if (text.len > 0 and text[text.len - 1] == '\r') return text[0 .. text.len - 1];
    return text;
}

fn trimPath(path: []const u8) []const u8 {
    var start: usize = 0;
    var end = path.len;
    while (start < end and isSpace(path[start])) : (start += 1) {}
    while (end > start and isSpace(path[end - 1])) : (end -= 1) {}
    return path[start..end];
}

fn trimSeparators(path: []const u8) []const u8 {
    var start: usize = 0;
    var end = path.len;
    while (start < end and (path[start] == '\\' or path[start] == '/')) : (start += 1) {}
    while (end > start and (path[end - 1] == '\\' or path[end - 1] == '/')) : (end -= 1) {}
    return path[start..end];
}

fn hexNibble(ch: u8) ?u8 {
    if (ch >= '0' and ch <= '9') return ch - '0';
    if (ch >= 'a' and ch <= 'f') return ch - 'a' + 10;
    if (ch >= 'A' and ch <= 'F') return ch - 'A' + 10;
    return null;
}

fn asciiEqlIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var index: usize = 0;
    while (index < a.len) : (index += 1) {
        if (asciiUpper(a[index]) != asciiUpper(b[index])) return false;
    }
    return true;
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn readU16(bytes: []const u8, offset: usize) u16 {
    return @as(u16, bytes[offset]) |
        (@as(u16, bytes[offset + 1]) << 8);
}

fn readU32(bytes: []const u8, offset: usize) u32 {
    return @as(u32, bytes[offset]) |
        (@as(u32, bytes[offset + 1]) << 8) |
        (@as(u32, bytes[offset + 2]) << 16) |
        (@as(u32, bytes[offset + 3]) << 24);
}

fn readU64(bytes: []const u8, offset: usize) u64 {
    return @as(u64, readU32(bytes, offset)) |
        (@as(u64, readU32(bytes, offset + 4)) << 32);
}

fn writeU16(bytes: []u8, offset: usize, value: u16) void {
    bytes[offset] = @intCast(value & 0xff);
    bytes[offset + 1] = @intCast((value >> 8) & 0xff);
}

fn writeU32(bytes: []u8, offset: usize, value: u32) void {
    bytes[offset] = @intCast(value & 0xff);
    bytes[offset + 1] = @intCast((value >> 8) & 0xff);
    bytes[offset + 2] = @intCast((value >> 16) & 0xff);
    bytes[offset + 3] = @intCast((value >> 24) & 0xff);
}

fn writeU64(bytes: []u8, offset: usize, value: u64) void {
    writeU32(bytes, offset, @intCast(value & 0xffff_ffff));
    writeU32(bytes, offset + 4, @intCast(value >> 32));
}

test "registry root parser accepts plain r4os roots only" {
    const parsed = parseRoot("system\\System\\Boot").?;
    try std.testing.expectEqual(HiveKind.system, parsed.kind);
    try std.testing.expectEqualStrings("System\\Boot", parsed.rest);
    try std.testing.expectEqual(HiveKind.system, parseRoot("SYSTEM/Shell/Desktop").?.kind);
    try std.testing.expectEqual(HiveKind.software, parseRoot("SOFTWARE\\Apps").?.kind);
    try std.testing.expectEqual(HiveKind.desktop, parseRoot("DESKTOP\\Shell").?.kind);
    try std.testing.expectEqual(HiveKind.user, parseRoot("USER\\Console").?.kind);
    try std.testing.expect(parseRoot("R4_SYSTEM\\System") == null);
    try std.testing.expect(parseRoot("R4LM\\System") == null);
    try std.testing.expect(parseRoot("R4SW\\Apps") == null);
    try std.testing.expect(parseRoot("R4DT\\Shell") == null);
    try std.testing.expect(parseRoot("R4CU\\Console") == null);
    try std.testing.expect(parseRoot("HKLM\\System") == null);
}

test "registry builder emits parseable hive and typed values" {
    const allocator = std.testing.allocator;
    const start: [4]u8 = .{ 2, 0, 0, 0 };
    const enabled: [1]u8 = .{1};
    const values = [_]BuildValue{
        .{ .key_path = "SYSTEM\\System\\Services\\TIMESVC", .name = "Start", .value_type = .u32, .data = start[0..] },
        .{ .key_path = "SYSTEM\\System\\Services\\TIMESVC", .name = "Enabled", .value_type = .bool, .data = enabled[0..] },
        .{ .key_path = "SYSTEM\\System\\Boot", .name = "Shell", .value_type = .string, .data = "C:\\R4OS\\SOFTWARE\\DESKTOP\\R4DESK.R4X" },
    };
    const bytes = try buildHive(allocator, .system, 7, values[0..]);
    defer allocator.free(bytes);

    const hive = try HiveView.parse(bytes);
    try std.testing.expectEqual(HiveKind.system, hive.header.hive_kind);
    try std.testing.expectEqual(@as(u64, 7), hive.header.generation);
    try std.testing.expectEqual(@as(?u32, 2), hive.getValue("SYSTEM\\System\\Services\\TIMESVC", "Start").?.asU32());
    try std.testing.expectEqual(@as(?bool, true), hive.getValue("SYSTEM\\System\\Services\\TIMESVC", "Enabled").?.asBool());
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\R4DESK.R4X", hive.getValue("SYSTEM\\System\\Boot", "Shell").?.asString().?);
}

test "registry builder rejects mismatched roots and duplicate values" {
    const allocator = std.testing.allocator;
    const data: [1]u8 = .{1};
    const bad_root = [_]BuildValue{
        .{ .key_path = "SOFTWARE\\Apps", .name = "Enabled", .value_type = .bool, .data = data[0..] },
    };
    try std.testing.expectError(Error.RootMismatch, buildHive(allocator, .system, 1, bad_root[0..]));

    const dupes = [_]BuildValue{
        .{ .key_path = "USER\\Apps\\Notepad", .name = "RecentFiles", .value_type = .string, .data = "A" },
        .{ .key_path = "USER\\Apps\\Notepad", .name = "recentfiles", .value_type = .string, .data = "B" },
    };
    try std.testing.expectError(Error.DuplicateValue, buildHive(allocator, .user, 1, dupes[0..]));
}

test "registry parser rejects corrupted header and payloads" {
    const allocator = std.testing.allocator;
    const enabled: [1]u8 = .{1};
    const values = [_]BuildValue{
        .{ .key_path = "SYSTEM\\Shell\\Desktop\\Settings", .name = "TaskbarClock", .value_type = .bool, .data = enabled[0..] },
    };
    const bytes = try buildHive(allocator, .system, 1, values[0..]);
    defer allocator.free(bytes);

    var corrupted = try allocator.dupe(u8, bytes);
    defer allocator.free(corrupted);
    corrupted[0] = 'X';
    try std.testing.expectError(Error.BadMagic, HiveView.parse(corrupted));

    @memcpy(corrupted, bytes);
    writeU32(corrupted, 16, 12);
    try std.testing.expectError(Error.BadFileSize, HiveView.parse(corrupted));

    @memcpy(corrupted, bytes);
    writeU16(corrupted, header_size + 10, 1);
    try std.testing.expectError(Error.BadReserved, HiveView.parse(corrupted));

    @memcpy(corrupted, bytes);
    const value_table_offset = readU32(corrupted, 40);
    writeU16(corrupted, value_table_offset + 10, 99);
    try std.testing.expectError(Error.BadValue, HiveView.parse(corrupted));
}

test "registry multi string payload validates" {
    const allocator = std.testing.allocator;
    const multi = [_]u8{
        2,    0,   0,   0,
        6,    0,   'C', ':',
        '\\', 'B', 'I', 'N',
        12,   0,   'C', ':',
        '\\', 'S', 'Y', 'S',
        '\\', 'T', 'O', 'O',
        'L',  'S',
    };
    const values = [_]BuildValue{
        .{ .key_path = "USER\\Console", .name = "Path", .value_type = .multi_string, .data = multi[0..] },
    };
    const bytes = try buildHive(allocator, .user, 1, values[0..]);
    defer allocator.free(bytes);
    const hive = try HiveView.parse(bytes);
    const value = hive.getValue("USER\\Console", "Path").?;
    try std.testing.expectEqual(ValueType.multi_string, value.value_type);
    try std.testing.expectEqual(multi.len, value.data.len);
}

test "registry text import export roundtrip" {
    const allocator = std.testing.allocator;
    const text =
        "\xef\xbb\xbfR4REG_FORMAT=1\r\n" ++
        "\r\n" ++
        "; comment\r\n" ++
        "[SYSTEM\\Software\\Classes\\.TXT]\r\n" ++
        "DisplayName=\"Text File\"\r\n" ++
        "DefaultApp:string=\"C:\\\\R4OS\\\\SOFTWARE\\\\DESKTOP\\\\EDIT.R4X\"\r\n" ++
        "Enabled:bool=true\r\n" ++
        "Priority:u32=0x2a\r\n" ++
        "Stamp:u64=42\r\n" ++
        "Magic:binary=DE AD BE EF\r\n" ++
        "SearchPath:multi_string=(\"C:\\\\R4OS\\\\SOFTWARE\\\\TERMINAL\",\"C:\\\\R4OS\\\\SOFTWARE\\\\DESKTOP\")\r\n";

    const bytes = try importTextHive(allocator, text, 3);
    defer allocator.free(bytes);
    const hive = try HiveView.parse(bytes);
    try std.testing.expectEqual(HiveKind.system, hive.header.hive_kind);
    try std.testing.expectEqual(@as(?u32, 42), hive.getValue("SYSTEM\\Software\\Classes\\.TXT", "Priority").?.asU32());
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\EDIT.R4X", hive.getValue("SYSTEM\\Software\\Classes\\.TXT", "DefaultApp").?.asString().?);

    const exported = try exportTextHive(allocator, hive);
    defer allocator.free(exported);
    const imported_again = try importTextHive(allocator, exported, 4);
    defer allocator.free(imported_again);
    const second = try HiveView.parse(imported_again);
    try std.testing.expectEqual(@as(?bool, true), second.getValue("SYSTEM\\Software\\Classes\\.TXT", "Enabled").?.asBool());
    try std.testing.expectEqual(ValueType.binary, second.getValue("SYSTEM\\Software\\Classes\\.TXT", "Magic").?.value_type);
    try std.testing.expectEqual(ValueType.multi_string, second.getValue("SYSTEM\\Software\\Classes\\.TXT", "SearchPath").?.value_type);
}
