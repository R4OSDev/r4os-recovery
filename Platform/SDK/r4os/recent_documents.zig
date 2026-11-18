const std = @import("std");
const abi = @import("r4os_contract").abi;
const path_contract = @import("path.zig");

pub const root_key = "SYSTEM\\Shell\\RecentDocuments";
pub const max_items: usize = 8;
pub const path_max: usize = path_contract.file_path_max;
pub const app_max: usize = 31;
pub const title_max: usize = 63;

const items_value = "Items";
const packed_magic = "R4RD";
const packed_version: u16 = 2;
const packed_header_size: usize = 8;
const packed_record_size: usize = (path_max + 1) + (app_max + 1) + (title_max + 1);
const packed_max_bytes: usize = packed_header_size + packed_record_size * max_items;

pub const Entry = struct {
    path: [path_max + 1]u8 = .{0} ** (path_max + 1),
    app: [app_max + 1]u8 = .{0} ** (app_max + 1),
    title: [title_max + 1]u8 = .{0} ** (title_max + 1),

    pub fn pathText(self: *const Entry) []const u8 {
        return spanZ(self.path[0..]);
    }

    pub fn appText(self: *const Entry) []const u8 {
        return spanZ(self.app[0..]);
    }

    pub fn titleText(self: *const Entry) []const u8 {
        return spanZ(self.title[0..]);
    }
};

pub fn addOpenedFile(sys: anytype, path: []const u8, app: []const u8) bool {
    if (path.len == 0 or !sys.hasFn("registry_set_value")) return false;
    if (readBool(sys, root_key, "Enabled")) |enabled| {
        if (!enabled) return false;
    }

    var existing: [max_items]Entry = .{Entry{}} ** max_items;
    const existing_count = readEntries(sys, existing[0..]);
    if (existing_count > 0 and entryMatchesOpenedFile(&existing[0], path, app)) return true;

    var updated: [max_items]Entry = .{Entry{}} ** max_items;
    const updated_count = buildUpdatedList(updated[0..], path, app, existing[0..existing_count]);
    if (updated_count == 0) return false;

    return writePackedEntries(sys, updated[0..updated_count]);
}

pub fn readEntries(sys: anytype, out: []Entry) usize {
    if (out.len == 0 or !sys.hasFn("registry_get_value")) return 0;
    if (readBool(sys, root_key, "Enabled")) |enabled| {
        if (!enabled) return 0;
    }
    return readPackedEntries(sys, out);
}

fn writePackedEntries(sys: anytype, entries: []const Entry) bool {
    var data: [packed_max_bytes]u8 = .{0} ** packed_max_bytes;
    const packed_bytes = packEntries(entries, data[0..]) orelse return false;
    return apiOk(sys.registrySetBinary(root_key, items_value, packed_bytes));
}

fn readPackedEntries(sys: anytype, out: []Entry) usize {
    var info: abi.RegistryValueInfo = .{};
    var data: [packed_max_bytes]u8 = .{0} ** packed_max_bytes;
    const result = sys.registryGetValue(root_key, items_value, &info, data[0..]);
    if (result < 0 or info.value_type != abi.registry_value_type_binary) return 0;
    const got: usize = @intCast(result);
    const available = @min(@min(got, @as(usize, @intCast(info.data_len))), data.len);
    return unpackEntries(data[0..available], out);
}

fn packEntries(entries_raw: []const Entry, out: []u8) ?[]const u8 {
    const count = @min(entries_raw.len, max_items);
    const len = packed_header_size + packed_record_size * count;
    if (out.len < len) return null;
    @memset(out[0..len], 0);
    @memcpy(out[0..4], packed_magic);
    writeU16(out[4..], packed_version);
    writeU16(out[6..], @intCast(count));

    var offset: usize = packed_header_size;
    var i: usize = 0;
    while (i < count) : (i += 1) {
        copyZ(out[offset .. offset + path_max + 1], entries_raw[i].pathText());
        offset += path_max + 1;
        copyZ(out[offset .. offset + app_max + 1], entries_raw[i].appText());
        offset += app_max + 1;
        copyZ(out[offset .. offset + title_max + 1], entries_raw[i].titleText());
        offset += title_max + 1;
    }
    return out[0..len];
}

fn unpackEntries(data: []const u8, out: []Entry) usize {
    if (data.len < packed_header_size) return 0;
    if (!std.mem.eql(u8, data[0..4], packed_magic)) return 0;
    if (readU16(data[4..]) != packed_version) return 0;
    const stored_count = readU16(data[6..]);
    if (stored_count > max_items or data.len < packed_header_size + packed_record_size * @as(usize, stored_count)) return 0;

    var actual: usize = 0;
    var offset: usize = packed_header_size;
    var i: usize = 0;
    while (i < stored_count and actual < out.len) : (i += 1) {
        var entry = Entry{};
        if (!copyPackedZChecked(entry.path[0..], data[offset .. offset + path_max + 1])) {
            offset += packed_record_size;
            continue;
        }
        offset += path_max + 1;
        copyPackedZ(entry.app[0..], data[offset .. offset + app_max + 1]);
        offset += app_max + 1;
        copyPackedZ(entry.title[0..], data[offset .. offset + title_max + 1]);
        offset += title_max + 1;
        if (entry.pathText().len == 0) continue;
        if (entry.titleText().len == 0) copyZ(entry.title[0..], tailName(entry.pathText()));
        out[actual] = entry;
        actual += 1;
    }
    return actual;
}

fn buildUpdatedList(out: []Entry, path: []const u8, app: []const u8, existing: []const Entry) usize {
    if (out.len == 0 or path.len == 0 or path.len > path_max or app.len > app_max) return 0;
    _ = path_contract.FilePath.parse(path) catch return 0;
    var count: usize = 0;
    if (!setEntry(&out[count], path, app)) return 0;
    count += 1;

    for (existing) |entry| {
        if (count >= @min(out.len, max_items)) break;
        const old_path = entry.pathText();
        if (old_path.len == 0 or equalsIgnoreCase(old_path, path)) continue;
        out[count] = entry;
        count += 1;
    }
    return count;
}

fn entryMatchesOpenedFile(entry: *const Entry, path: []const u8, app: []const u8) bool {
    return equalsIgnoreCase(entry.pathText(), path) and equalsIgnoreCase(entry.appText(), app);
}

fn setEntry(out: *Entry, path: []const u8, app: []const u8) bool {
    const title = tailName(path);
    if (path.len == 0 or path.len > path_max or app.len > app_max or title.len > title_max) return false;
    out.* = .{};
    copyZ(out.path[0..], path);
    copyZ(out.app[0..], app);
    copyZ(out.title[0..], title);
    return true;
}

fn readBool(sys: anytype, key: [*:0]const u8, name: [*:0]const u8) ?bool {
    var info: abi.RegistryValueInfo = .{};
    var data: [1]u8 = .{0};
    const result = sys.registryGetValue(key, name, &info, data[0..]);
    if (result < 0 or info.value_type != abi.registry_value_type_bool or info.data_len != 1 or result != 1) return null;
    return data[0] != 0;
}

fn apiOk(result: i32) bool {
    return result == abi.registry_api_result_ok;
}

fn tailName(path: []const u8) []const u8 {
    var start: usize = 0;
    var i: usize = 0;
    while (i < path.len) : (i += 1) {
        if (path[i] == '\\' or path[i] == '/') start = i + 1;
    }
    return path[start..];
}

fn copyZ(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const count = @min(value.len, out.len - 1);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
    out[count] = 0;
}

fn copyPackedZ(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    var count: usize = 0;
    while (count < value.len and count < out.len - 1 and value[count] != 0) : (count += 1) {
        out[count] = value[count];
    }
    out[count] = 0;
}

fn copyPackedZChecked(out: []u8, value: []const u8) bool {
    var len: usize = 0;
    while (len < value.len and value[len] != 0) : (len += 1) {}
    if (len >= out.len) return false;
    copyPackedZ(out, value[0..len]);
    return true;
}

fn spanZ(buffer: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buffer.len and buffer[len] != 0) : (len += 1) {}
    return buffer[0..len];
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (asciiLower(a[i]) != asciiLower(b[i])) return false;
    }
    return true;
}

fn asciiLower(ch: u8) u8 {
    if (ch >= 'A' and ch <= 'Z') return ch + ('a' - 'A');
    return ch;
}

fn writeU16(out: []u8, value: u16) void {
    out[0] = @intCast(value & 0xff);
    out[1] = @intCast((value >> 8) & 0xff);
}

fn readU16(data: []const u8) u16 {
    return @as(u16, data[0]) | (@as(u16, data[1]) << 8);
}

test "recent documents write all eight current records through the registry owner" {
    const Mock = struct {
        bytes: [packed_max_bytes]u8 = undefined,
        len: usize = 0,
        pub fn registrySetBinary(self: *@This(), key: [*:0]const u8, name: [*:0]const u8, value: []const u8) i32 {
            if (!std.mem.eql(u8, std.mem.span(key), root_key) or !std.mem.eql(u8, std.mem.span(name), items_value) or value.len > self.bytes.len) return -1;
            @memcpy(self.bytes[0..value.len], value);
            self.len = value.len;
            return abi.registry_api_result_ok;
        }
    };
    var entries: [max_items]Entry = .{Entry{}} ** max_items;
    var path: [213]u8 = undefined;
    @memcpy(path[0..3], "C:\\");
    @memset(path[3..203], 'a');
    @memcpy(path[203..], "\\FILE0.TXT");
    for (&entries, 0..) |*entry, i| {
        path[208] = '0' + @as(u8, @intCast(i));
        try std.testing.expect(setEntry(entry, &path, "EDITOR"));
    }
    var mock = Mock{};
    try std.testing.expect(writePackedEntries(&mock, &entries));
    try std.testing.expectEqual(packed_max_bytes, mock.len);
    var decoded: [max_items]Entry = undefined;
    try std.testing.expectEqual(max_items, unpackEntries(mock.bytes[0..mock.len], &decoded));
    for (entries, decoded) |expected, actual| try std.testing.expectEqualStrings(expected.pathText(), actual.pathText());
}

test "recent document list keeps newest first and deduplicates" {
    var existing: [max_items]Entry = .{Entry{}} ** max_items;
    _ = setEntry(&existing[0], "C:\\TEMP\\A.TXT", "Notepad");
    _ = setEntry(&existing[1], "C:\\TEMP\\B.BMP", "Paint");

    var updated: [max_items]Entry = .{Entry{}} ** max_items;
    const count = buildUpdatedList(updated[0..], "c:\\temp\\a.txt", "Notepad", existing[0..2]);

    try std.testing.expectEqual(@as(usize, 2), count);
    try std.testing.expectEqualStrings("c:\\temp\\a.txt", updated[0].pathText());
    try std.testing.expectEqualStrings("a.txt", updated[0].titleText());
    try std.testing.expectEqualStrings("C:\\TEMP\\B.BMP", updated[1].pathText());
}

test "recent document front match is case insensitive for path and app" {
    var entry = Entry{};
    _ = setEntry(&entry, "C:\\TEMP\\CONFIG.R4S", "Notepad");

    try std.testing.expect(entryMatchesOpenedFile(&entry, "c:\\temp\\config.r4s", "notepad"));
    try std.testing.expect(!entryMatchesOpenedFile(&entry, "c:\\temp\\config.r4s", "Paint"));
}

test "recent document list caps item count" {
    var existing: [max_items]Entry = .{Entry{}} ** max_items;
    var i: usize = 0;
    while (i < existing.len) : (i += 1) {
        var path: [32]u8 = .{0} ** 32;
        const text = try std.fmt.bufPrint(path[0..], "C:\\TEMP\\{d}.TXT", .{i});
        _ = setEntry(&existing[i], text, "Test");
    }

    var updated: [max_items]Entry = .{Entry{}} ** max_items;
    const count = buildUpdatedList(updated[0..], "C:\\TEMP\\NEW.TXT", "Test", existing[0..]);
    try std.testing.expectEqual(@as(usize, max_items), count);
    try std.testing.expectEqualStrings("C:\\TEMP\\NEW.TXT", updated[0].pathText());
}

test "recent document packed payload roundtrips newest first" {
    var entries: [2]Entry = .{ Entry{}, Entry{} };
    _ = setEntry(&entries[0], "C:\\TEMP\\A.TXT", "Notepad");
    _ = setEntry(&entries[1], "C:\\TEMP\\B.BMP", "Paint");

    var packed_data: [packed_max_bytes]u8 = .{0} ** packed_max_bytes;
    const bytes = packEntries(entries[0..], packed_data[0..]).?;

    var decoded: [max_items]Entry = .{Entry{}} ** max_items;
    const count = unpackEntries(bytes, decoded[0..]);

    try std.testing.expectEqual(@as(usize, 2), count);
    try std.testing.expectEqualStrings("C:\\TEMP\\A.TXT", decoded[0].pathText());
    try std.testing.expectEqualStrings("Notepad", decoded[0].appText());
    try std.testing.expectEqualStrings("A.TXT", decoded[0].titleText());
    try std.testing.expectEqualStrings("C:\\TEMP\\B.BMP", decoded[1].pathText());
}

test "recent documents reject overlong paths and unsupported registry versions" {
    var too_long: [path_max + 1]u8 = .{'A'} ** (path_max + 1);
    too_long[0] = 'C';
    too_long[1] = ':';
    too_long[2] = '\\';
    var updated: [max_items]Entry = .{Entry{}} ** max_items;
    try std.testing.expectEqual(@as(usize, 0), buildUpdatedList(updated[0..], too_long[0..], "Test", &.{}));

    const v1_path_bytes = 192;
    var legacy: [packed_header_size + v1_path_bytes + app_max + 1 + title_max + 1]u8 = @splat(0);
    @memcpy(legacy[0..4], packed_magic);
    writeU16(legacy[6..], 1);
    const path = "C:\\TEMP\\LEGACY.TXT";
    @memcpy(legacy[packed_header_size .. packed_header_size + path.len], path);
    var out: [1]Entry = .{Entry{}};
    for ([_]u16{ 1, 3, 0xffff }) |version| {
        writeU16(legacy[4..], version);
        try std.testing.expectEqual(@as(usize, 0), unpackEntries(&legacy, &out));
    }
}

test "recent document registry keeps readable v2 records and replaces old data only on a successful open" {
    const Registry = struct {
        bytes: [packed_max_bytes]u8 = @splat(0),
        len: usize = 0,
        writes: usize = 0,
        fail_write: bool = false,
        pub fn hasFn(_: *@This(), _: []const u8) bool {
            return true;
        }
        pub fn registryGetValue(self: *@This(), _: [*:0]const u8, name: [*:0]const u8, info: *abi.RegistryValueInfo, out: []u8) i32 {
            if (!std.mem.eql(u8, std.mem.span(name), items_value) or self.len == 0) return -1;
            info.value_type = abi.registry_value_type_binary;
            info.data_len = @intCast(self.len);
            const size = @min(out.len, self.len);
            @memcpy(out[0..size], self.bytes[0..size]);
            return @intCast(size);
        }
        pub fn registrySetBinary(self: *@This(), _: [*:0]const u8, _: [*:0]const u8, data: []const u8) i32 {
            if (self.fail_write) return -1;
            self.len = data.len;
            @memcpy(self.bytes[0..data.len], data);
            self.writes += 1;
            return abi.registry_api_result_ok;
        }
    };
    var registry = Registry{};
    var out: [max_items]Entry = undefined;
    try std.testing.expectEqual(@as(usize, 0), readEntries(&registry, &out));
    try std.testing.expect(addOpenedFile(&registry, "C:\\A.TXT", "Editor"));
    try std.testing.expect(addOpenedFile(&registry, "C:\\B.TXT", "Editor"));
    try std.testing.expectEqual(@as(usize, 2), readEntries(&registry, &out));
    try std.testing.expectEqualStrings("C:\\B.TXT", out[0].pathText());
    try std.testing.expectEqualStrings("C:\\A.TXT", out[1].pathText());
    // A truncated list is invalid even when its caller requests one record.
    const intact = registry;
    registry.len -= 1;
    try std.testing.expectEqual(@as(usize, 0), readEntries(&registry, out[0..1]));
    registry = intact;
    writeU16(registry.bytes[6..], max_items + 1);
    try std.testing.expectEqual(@as(usize, 0), readEntries(&registry, out[0..1]));
    registry = intact;
    @memset(registry.bytes[packed_header_size..][0 .. path_max + 1], 'x');
    try std.testing.expectEqual(@as(usize, 1), readEntries(&registry, &out));
    try std.testing.expectEqual(@as(usize, 1), readEntries(&registry, out[0..1]));
    try std.testing.expectEqualStrings("C:\\A.TXT", out[0].pathText());
    writeU16(registry.bytes[4..], 1);
    const saved = registry;
    try std.testing.expectEqual(@as(usize, 0), readEntries(&registry, &out));
    registry.fail_write = true;
    try std.testing.expect(!addOpenedFile(&registry, "C:\\NEW.TXT", "Editor"));
    try std.testing.expectEqualSlices(u8, &saved.bytes, &registry.bytes);
    try std.testing.expectEqual(saved.writes, registry.writes);
    registry.fail_write = false;
    try std.testing.expect(addOpenedFile(&registry, "C:\\NEW.TXT", "Editor"));
    try std.testing.expectEqual(packed_version, readU16(registry.bytes[4..]));
    try std.testing.expectEqual(@as(usize, 1), readEntries(&registry, &out));
    try std.testing.expectEqualStrings("C:\\NEW.TXT", out[0].pathText());
}
