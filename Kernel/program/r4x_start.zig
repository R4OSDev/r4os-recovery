pub fn generation(meta: []const u8, first: bool, second: bool, export_count: u32) ?u8 {
    if (export_count == 0 or first or !second) return null;
    const keys = .{ "r4x.start=", "r4x.entry=", "r4x.start_abi=", "r4x.context=" };
    const expected = .{ "r4xstart2", "R4XStart2", "2", "R4XStartContext2" };
    inline for (keys, expected) |key, value| {
        var count: usize = 0;
        var cursor: usize = 0;
        while (cursor < meta.len) {
            var end = cursor;
            while (end < meta.len and meta[end] != 0) : (end += 1) {}
            const item = meta[cursor..end];
            if (startsWith(item, key)) {
                if (!eql(item[key.len..], value)) return null;
                count += 1;
            }
            cursor = end + 1;
        }
        if (count != 1) return null;
    }
    return 2;
}

pub fn recordExport(first: *bool, second: *bool, name: []const u8, revision: u32) bool {
    if (eql(name, "R4XStart")) {
        first.* = true;
        return false;
    } else if (eql(name, "R4XStart2")) {
        if (second.* or revision != 2) return false;
        second.* = true;
    }
    return true;
}

pub fn importAllowed(selected: u8, platform: bool, symbol: []const u8, minimum: u32, flags: u32) bool {
    if (selected != 2 or minimum == 0 or flags & ~@as(u32, 1) != 0 or (platform and flags != 0)) return false;
    if (platform or eql(symbol, "Query") or eql(symbol, "Query2"))
        return eql(symbol, "Query2") and minimum == selected;
    return true;
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and eql(value[0..prefix.len], prefix);
}

fn eql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        if (left != right) return false;
    }
    return true;
}

test "retired start1 metadata is never admitted" {
    const std = @import("std");
    const cases = [_][]const u8{
        "r4x.name=OK\x00r4x.start=r4xstart\x00",
        "r4x.name=MISSING\x00",
        "r4x.start=invalid\x00",
        "r4x.start=r4xstart\x00r4x.start=r4xstart\x00",
        "r4x.start=r4xstart\x00",
        "r4x.start=r4xstart\x00r4x.start=invalid\x00",
    };
    for (cases) |meta| {
        try std.testing.expectEqual(@as(?u8, null), generation(meta, true, false, 1));
        try std.testing.expectEqual(@as(?u8, null), generation(meta, true, false, 2));
    }
}

test "explicit new start identity never admits mixed duplicate or incomplete metadata" {
    const std = @import("std");
    const valid = "r4x.start=r4xstart2\x00r4x.entry=R4XStart2\x00r4x.start_abi=2\x00r4x.context=R4XStartContext2\x00";
    try std.testing.expectEqual(@as(?u8, null), generation("r4x.start=r4xstart\x00", true, false, 1));
    try std.testing.expectEqual(@as(?u8, 2), generation(valid, false, true, 1));
    try std.testing.expectEqual(@as(?u8, null), generation(valid, true, true, 2));
    try std.testing.expectEqual(@as(?u8, null), generation(valid, false, true, 0));
    try std.testing.expectEqual(@as(?u8, null), generation(valid ++ "r4x.start_abi=2\x00", false, true, 1));
    try std.testing.expectEqual(@as(?u8, null), generation("r4x.start=r4xstart2\x00", false, true, 1));
    var first = false;
    var second = false;
    try std.testing.expect(!recordExport(&first, &second, "R4XStart2", 1));
    try std.testing.expect(recordExport(&first, &second, "R4XStart2", 2));
    try std.testing.expect(!recordExport(&first, &second, "R4XStart2", 2));
    try std.testing.expect(importAllowed(2, false, "API_V1", 1, 1));
    try std.testing.expect(importAllowed(2, false, "Query2", 2, 1));
    try std.testing.expect(importAllowed(2, true, "Query2", 2, 0));
    try std.testing.expect(!importAllowed(2, true, "Query2", 2, 1));
    try std.testing.expect(!importAllowed(2, true, "Query", 1, 0));
    try std.testing.expect(!importAllowed(2, false, "API_V1", 0, 0));
    try std.testing.expect(!importAllowed(2, false, "API_V1", 1, 2));
}
