const std = @import("std");
const api = @import("metadata2.zig");
const platform = @import("platform2.zig");
const abi = api.abi;
const Probe = struct {
    var calls: u32 = 0;
    var code: i32 = 0;
    var legacy_calls: u32 = 0;
    var progress: bool = false;
    fn reset() void {
        calls = 0;
        code = 0;
        legacy_calls = 0;
        progress = false;
    }
    fn oldInfo(_: [*:0]const u8, _: *abi.FileInfo) callconv(.c) i32 {
        legacy_calls += 1;
        return -71;
    }
    fn info(path: [*:0]const u8, out: *abi.FileMetadata2) callconv(.c) i32 {
        calls += 1;
        if (code != 0) return code;
        if (std.mem.eql(u8, std.mem.span(path), "missing")) return 0;
        out.* = .{ .flags = abi.file_metadata2_flag_exists | abi.file_metadata2_flag_identity_valid | abi.file_metadata2_flag_byte_size_valid, .byte_size = 0x100000003, .backend_node = 0x100000001, .identity = .{ .mount_generation = 11, .namespace_generation = 0, .object_hi = 0x100000001, .flags = abi.file_identity2_flag_namespace } };
        return 1;
    }
    fn page(_: ?[*:0]const u8, cursor: *abi.DirectoryMetadataCursor2, rows: ?[*]abi.DirectoryMetadataEntry2, capacity: u32) callconv(.c) i32 {
        calls += 1;
        if (code != 0) return code;
        if (capacity == 0) return if (cursor.flags == 1) 0 else -1;
        if (progress) return 0;
        if (cursor.scan.backend[0] == 2) return -5;
        const index = cursor.scan.backend[0];
        rows.?[0] = .{ .info = .{ .flags = abi.file_metadata2_flag_exists | abi.file_metadata2_flag_identity_valid, .identity = .{ .mount_generation = 11, .namespace_generation = 0, .object_hi = 0x100000000 + index, .flags = abi.file_identity2_flag_namespace } } };
        rows.?[0].path[0] = 'A' + @as(u8, @intCast(index));
        cursor.flags = 1;
        cursor.scan.change.mount_generation = 11;
        cursor.scan.backend[0] += 1;
        return 1;
    }
};
const Fixture = struct {
    table: platform.abi.R4XStartR4Sys2 = .{},
    imports: [1]platform.abi.R4XStartImport = undefined,
    raw: platform.abi.R4XStartContext2 = .{},
    fn context(self: *Fixture) !platform.Context {
        self.table.file_metadata2 = @intFromPtr(&Probe.info);
        self.table.directory_metadata_batch2 = @intFromPtr(&Probe.page);
        self.table.file_info = @intFromPtr(&Probe.oldInfo);
        self.imports = .{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&self.table) }};
        self.raw.import_count = 1;
        self.raw.imports = @intFromPtr(&self.imports);
        return platform.Context.init(&self.raw);
    }
};

test "metadata2 owner exact optional dispatch preserves wide fields and never falls back" {
    Probe.reset();
    var f: Fixture = .{};
    const ctx = try f.context();
    const record = switch (api.info(&ctx, "file")) { .found => |value| value, else => return error.NotFound };
    try std.testing.expectEqual(@as(u64, 0x100000001), record.backend_node);
    try std.testing.expectEqual(@as(?u64, 0x100000003), api.fileSize(&record));
    try std.testing.expectEqual(@as(u64, 0), api.identity(&record).?.namespace_generation);
    try std.testing.expect(api.info(&ctx, "missing") == .missing);
    f.table.size = @offsetOf(platform.abi.R4XStartR4Sys2, "file_metadata2");
    try std.testing.expectEqual(abi.err_no_fn, api.info(&ctx, "file").failure);
    f.table.size = @sizeOf(platform.abi.R4XStartR4Sys2);
    f.table.file_metadata2 = 0;
    try std.testing.expectEqual(abi.err_no_fn, api.info(&ctx, "file").failure);
    try std.testing.expectEqual(@as(u32, 2), Probe.calls);
    try std.testing.expectEqual(@as(u32, 0), Probe.legacy_calls);
}

test "metadata2 owner bounded pages progress end restart and explicit reset stay distinct" {
    Probe.reset();
    var f: Fixture = .{};
    const ctx = try f.context();
    var reader = api.Directory.init(&ctx, "directory");
    try std.testing.expectEqual(@as(u32, 0), Probe.calls);
    try std.testing.expectEqual(@as(i32, -1), reader.validate());
    var rows: [1]abi.DirectoryMetadataEntry2 = undefined;
    Probe.progress = true;
    try std.testing.expect(reader.next(&rows) == .progress);
    try std.testing.expectEqual(@as(u32, 0), reader.cursor.flags);
    Probe.progress = false;
    for (0..2) |i| {
        const result = reader.next(&rows);
        try std.testing.expect(result == .rows);
        try std.testing.expectEqual(@intFromPtr(&rows[0]), @intFromPtr(result.rows.ptr));
        try std.testing.expectEqual(@as(u64, 0x100000000) + i, result.rows[0].info.identity.object_hi);
    }
    try std.testing.expect(reader.next(&rows) == .end);
    try std.testing.expectEqual(@as(i32, 0), reader.validate());
    Probe.code = -10;
    try std.testing.expect(reader.next(&rows) == .restart);
    const calls = Probe.calls;
    reader.reset();
    try std.testing.expectEqual(calls, Probe.calls);
    try std.testing.expectEqual(@as(u32, 0), reader.cursor.flags);
}

test "metadata2 owner unknown fields bounds and failures never become complete rows" {
    Probe.reset();
    var f: Fixture = .{};
    const ctx = try f.context();
    var reader = api.Directory.init(&ctx, "directory");
    var too_many: [9]abi.DirectoryMetadataEntry2 = undefined;
    try std.testing.expectEqual(abi.file_metadata2_error_invalid, reader.next(&too_many).failure);
    try std.testing.expectEqual(@as(u32, 0), Probe.calls);
    Probe.code = -9;
    try std.testing.expectEqual(@as(i32, -9), reader.next(too_many[0..1]).failure);
    try std.testing.expectEqual(@as(i32, -9), api.info(&ctx, "file").failure);
    const unknown: abi.FileMetadata2 = .{ .byte_size = 42, .identity = .{ .object_hi = 123 } };
    try std.testing.expect(api.identity(&unknown) == null and api.fileSize(&unknown) == null);
    try std.testing.expectEqual(@as(u32, 0), Probe.legacy_calls);
}
