const std = @import("std");
const r4os = @import("r4os");

test "normal App2 file facade preserves wide metadata and restarts buffered directory observations" {
    const a = r4os.abi;
    const a2 = r4os.platform2.abi;
    const Provider = struct {
        var changed = false;
        fn open(_: *const a2.R4XStartContext2) callconv(.c) u32 {
            return 0;
        }
        fn info(_: [*:0]const u8, out: *a.FileMetadata2) callconv(.c) i32 {
            out.* = .{ .flags = a.file_metadata2_flag_exists | a.file_metadata2_flag_byte_size_valid | a.file_metadata2_flag_backend_node_valid, .byte_size = 0x100000003, .backend_node = 0x100000007, .drive_letter = 'C' };
            return 1;
        }
        fn batch(path: ?[*:0]const u8, cursor: *a.DirectoryMetadataCursor2, rows: ?[*]a.DirectoryMetadataEntry2, capacity: u32) callconv(.c) i32 {
            if (capacity == 0) {
                std.debug.assert(path == null and rows == null);
                return if (changed) -10 else 0;
            }
            if (cursor.namespace_generation != 0) return -5;
            std.debug.assert(path != null and rows != null and capacity == 4);
            cursor.namespace_generation = 9;
            rows.?[0] = .{};
            _ = info("C:\\WIDE.TXT", &rows.?[0].info);
            @memcpy(rows.?[0].path[0..11], "C:\\WIDE.TXT");
            rows.?[1] = rows.?[0];
            return 2;
        }
    };
    const table: a2.R4XStartR4Sys2 = .{
        .file_read = @intFromPtr(&fakeFileRead),
        .file_read_at = @intFromPtr(&fakeFileReadAt),
        .file_write = @intFromPtr(&fakeFileWrite),
        .file_append = @intFromPtr(&fakeFileAppend),
        .file_metadata2 = @intFromPtr(&Provider.info),
        .directory_metadata_batch2 = @intFromPtr(&Provider.batch),
    };
    const imported: a.R4XStartImport = .{ .group_id = 1, .min_version = 2, .resolved_version = 2, .flags = a.r4xstart_import_flag_group_interface, .module_name = @intFromPtr("R4SYS"), .symbol_name = @intFromPtr("Query2"), .table = @intFromPtr(&table) };
    const raw: a2.R4XStartContext2 = .{ .app_class = 1, .instance_id = 42, .flags = a.r4xstart_flag_imports_valid | a.r4xstart_flag_close_supported, .should_close = @intFromPtr(&Provider.open), .imports = @intFromPtr(&imported), .import_count = 1 };
    const app = switch (r4os.App2.init(&raw, .console)) {
        .value => |v| v,
        .failure => return error.App2Init,
    };
    const files = app.files() orelse return error.NoFiles;
    const path = try r4os.path.FilePath.parse("C:\\WIDE.TXT");
    switch (files.metadata(path.asZ())) {
        .found => |v| {
            try std.testing.expectEqual(@as(u64, 0x100000003), v.byte_size);
            try std.testing.expectEqual(@as(u64, 0x100000007), v.backend_node);
        },
        else => return error.Metadata,
    }
    try std.testing.expectEqual(a.file_metadata2_error_unsupported, files.info(path.asZ()).failure);
    Provider.changed = false;
    var scan = files.iterate(path.asZ());
    var name: [64]u8 = undefined;
    const row = scan.next(&name).entry;
    try std.testing.expectEqual(@as(u64, 0x100000007), row.metadata.?.backend_node);
    try std.testing.expect(row.info == null);
    Provider.changed = true;
    try std.testing.expectEqual(a.file_metadata2_error_restart, scan.next(&name).failure);
    Provider.changed = false;
    var next = files.iterate(path.asZ());
    _ = next.next(&name).entry;
    next.revisitAfterRemoval();
    try std.testing.expectEqual(a.file_metadata2_error_restart, next.next(&name).failure);
}

test "storage parity includes the path recent registry and bounded text owners" {
    std.testing.refAllDecls(r4os.path);
    std.testing.refAllDecls(r4os.recent_documents);
    std.testing.refAllDecls(r4os.registry);
    std.testing.refAllDecls(r4os.bounded_text);
}

const file_bytes = "hello";
var name_limits_result: i32 = 0;
fn fakeNameLimits(_: [*:0]const u8, out: *r4os.abi.FileNameLimits) callconv(.c) i32 {
    if (name_limits_result != 0) return name_limits_result;
    out.* = .{ .size = 56, .flags = 3, .provider = 2, .drive_letter = 'C', .mount_slot = 7, .mount_generation = 99, .max_path_bytes = 1023, .max_component_bytes = 765, .max_component_utf16_units = 255, .short_base_bytes = 8, .short_extension_bytes = 3, .name_rules = 7, .atomic_rules = 7 };
    return 0;
}
const config_bytes = "\xEF\xBB\xBFR4S_FORMAT=1\r\nSCHEMA=TEST\r\nTITLE=Configured\r\nCOUNT=27\r\n";
var written: [64]u8 = .{0} ** 64;
var written_len: usize = 0;
var stream_active = false;
var stream_aborted = false;
var registry_set_value: u32 = 0;
var registry_set_wide: u64 = 0;
var registry_set_type: u16 = 0;
var storage_close_result: i32 = 0;
fn fakeStorageEnd(claim: u64, flags: u32) callconv(.c) i32 {
    std.debug.assert(claim == 17 and flags == 0);
    return storage_close_result;
}
fn fakeStorageBegin(_: *const r4os.abi.StorageTarget, out: *u64) callconv(.c) i32 {
    out.* = 17;
    return 0;
}

test "physical storage checks append-only availability and consuming close outcomes" {
    var table = makeSys(true);
    table.size = @offsetOf(r4os.platform2.abi.R4XStartR4Sys2, "storage_claim_begin");
    var imports: [1]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    const app = try makeApp(&table, &imports, &context);
    const sys = app.system();
    const storage = r4os.storage.Context{ .sys = &sys };
    var use: u64 = 123;
    try std.testing.expect(!storage.available());
    try std.testing.expectEqual(r4os.abi.storage_error_unsupported, storage.transferUseBegin("E:\\FILE", &use));
    try std.testing.expectEqual(@as(u64, 0), use);
    table.size = @sizeOf(r4os.platform2.abi.R4XStartR4Sys2);
    table.storage_claim_begin = @intFromPtr(&fakeStorageBegin);
    try std.testing.expectEqual(r4os.abi.storage_error_unsupported, storage.transferUseBegin("E:\\FILE", &use));
    const target = r4os.storage.Context.wholeDevice(.{});
    var bytes: [512]u8 = undefined;
    try std.testing.expectEqual(r4os.abi.storage_error_invalid, storage.read(&target, 0, bytes[0..511]));
    try std.testing.expectEqual(@as(i32, 0), storage.claimBegin(&target, &use));
    table.storage_claim_end = @intFromPtr(&fakeStorageEnd);
    storage_close_result = r4os.abi.storage_error_busy;
    try std.testing.expectEqual(storage_close_result, storage.claimEnd(&use, false));
    try std.testing.expectEqual(@as(u64, 17), use);
    storage_close_result = r4os.abi.storage_error_io;
    try std.testing.expectEqual(storage_close_result, storage.claimEnd(&use, false));
    try std.testing.expectEqual(@as(u64, 0), use);
}

fn pathSpan(path: [*:0]const u8) []const u8 {
    return std.mem.span(path);
}

fn copyOut(source: []const u8, out: [*]u8, capacity: u32) i32 {
    const count = @min(source.len, @as(usize, capacity));
    if (count != 0) @memcpy(out[0..count], source[0..count]);
    return @intCast(count);
}

fn fakeWrite(data: [*]const u8, len: u32) callconv(.c) i32 {
    const count = @min(@as(usize, len), written.len);
    @memcpy(written[0..count], data[0..count]);
    written_len = count;
    return @intCast(count);
}

fn fakePutc(ch: u8) callconv(.c) void {
    if (written_len < written.len) {
        written[written_len] = ch;
        written_len += 1;
    }
}

fn fakeFileRead(path: [*:0]const u8, out: [*]u8, capacity: u32) callconv(.c) i32 {
    return copyOut(if (std.mem.indexOf(u8, pathSpan(path), "CONFIG") != null) config_bytes else file_bytes, out, capacity);
}

fn fakeFileReadAt(path: [*:0]const u8, offset: u32, out: [*]u8, capacity: u32) callconv(.c) i32 {
    _ = path;
    if (offset >= file_bytes.len) return 0;
    return copyOut(file_bytes[offset..], out, capacity);
}

fn fakeFileWrite(path: [*:0]const u8, data: [*]const u8, len: u32) callconv(.c) i32 {
    _ = path;
    return fakeWrite(data, len);
}

fn fakeFileAppend(path: [*:0]const u8, data: [*]const u8, len: u32) callconv(.c) i32 {
    _ = path;
    const count = @min(@as(usize, len), written.len - written_len);
    @memcpy(written[written_len..][0..count], data[0..count]);
    written_len += count;
    return @intCast(count);
}

fn fakeFileInfo(path: [*:0]const u8, out: *r4os.abi.FileInfo) callconv(.c) i32 {
    if (std.mem.indexOf(u8, pathSpan(path), "MISSING") != null) return 0;
    out.* = .{ .exists = 1, .size = file_bytes.len };
    return 1;
}

fn fakeDelete(path: [*:0]const u8) callconv(.c) i32 {
    return if (std.mem.indexOf(u8, pathSpan(path), "MISSING") != null) 0 else 1;
}

fn fakeRename(old: [*:0]const u8, new: [*:0]const u8) callconv(.c) i32 {
    _ = old;
    _ = new;
    return 1;
}

fn fakeDirCreate(path: [*:0]const u8) callconv(.c) i32 {
    _ = path;
    return 1;
}

fn fakeDirEntry(path: [*:0]const u8, index: u32, out: [*]u8, capacity: u32) callconv(.c) i32 {
    _ = path;
    if (index == 2) {
        _ = copyOut("C:\\ONE.TXT\x00", out, capacity);
        return 0;
    }
    if (index == 3) {
        _ = copyOut("C:\\SUB\x00", out, capacity);
        return 1;
    }
    return -5;
}

fn fakeStreamBegin(path: [*:0]const u8, flags: u32) callconv(.c) i32 {
    _ = path;
    _ = flags;
    stream_active = true;
    stream_aborted = false;
    written_len = 0;
    return r4os.abi.file_stream_result_ok;
}

fn fakeStreamWrite(path: [*:0]const u8, offset: u64, data: [*]const u8, len: u32, flags: u32) callconv(.c) i32 {
    _ = flags;
    if (!stream_active or offset != written_len) return r4os.abi.file_stream_error_offset_mismatch;
    return fakeFileAppend(path, data, len);
}

fn fakeStreamFinish(path: [*:0]const u8, expected: u64, flags: u32) callconv(.c) i32 {
    _ = path;
    _ = flags;
    if (!stream_active or expected != written_len) return r4os.abi.file_stream_error_size_mismatch;
    stream_active = false;
    return r4os.abi.file_stream_result_ok;
}

fn fakeStreamAbort(path: [*:0]const u8) callconv(.c) i32 {
    _ = path;
    stream_active = false;
    stream_aborted = true;
    return r4os.abi.file_stream_result_ok;
}

fn fakeRegistryGet(key: [*:0]const u8, name: [*:0]const u8, info: *r4os.abi.RegistryValueInfo, out: [*]u8, capacity: u32) callconv(.c) i32 {
    _ = key;
    const value_name = pathSpan(name);
    if (std.mem.eql(u8, value_name, "MISSING")) return r4os.abi.registry_api_result_value_not_found;
    if (std.mem.eql(u8, value_name, "TEXT")) {
        if (capacity < 2) return r4os.abi.registry_api_result_buffer_too_small;
        info.* = .{ .value_type = r4os.abi.registry_value_type_string, .data_len = 2 };
        out[0] = 'O';
        out[1] = 'K';
        return 2;
    }
    if (std.mem.eql(u8, value_name, "WIDE")) {
        if (capacity < 8) return r4os.abi.registry_api_result_buffer_too_small;
        info.* = .{ .value_type = r4os.abi.registry_value_type_u64, .data_len = 8 };
        const value: u64 = 0x0102030405060708;
        for (0..8) |index| out[index] = @truncate(value >> @intCast(index * 8));
        return 8;
    }
    if (std.mem.eql(u8, value_name, "ENABLED")) {
        if (capacity < 1) return r4os.abi.registry_api_result_buffer_too_small;
        info.* = .{ .value_type = r4os.abi.registry_value_type_bool, .data_len = 1 };
        out[0] = 1;
        return 1;
    }
    if (capacity < 4) return r4os.abi.registry_api_result_buffer_too_small;
    info.* = .{ .value_type = r4os.abi.registry_value_type_u32, .data_len = 4 };
    out[0] = 0x78;
    out[1] = 0x56;
    out[2] = 0x34;
    out[3] = 0x12;
    return 4;
}

fn fakeRegistrySet(key: [*:0]const u8, name: [*:0]const u8, value_type: u16, data: [*]const u8, len: u32) callconv(.c) i32 {
    _ = key;
    _ = name;
    if (len > 8) return r4os.abi.registry_api_result_invalid;
    registry_set_type = value_type;
    registry_set_wide = 0;
    for (0..len) |index| registry_set_wide |= @as(u64, data[index]) << @intCast(index * 8);
    registry_set_value = @truncate(registry_set_wide);
    return r4os.abi.registry_api_result_ok;
}

fn fakeDirectoryBatch(_: ?[*:0]const u8, cursor: *r4os.abi.DirectoryBatchCursor, out: ?[*]r4os.abi.DirectoryBatchEntry, capacity: u32) callconv(.c) i32 {
    if (capacity == 0) return 0;
    if (cursor.backend[0] != 0) return -5;
    cursor.change.mount_generation = 1;
    cursor.backend[0] = 1;
    const count = @min(capacity, 2);
    for (0..count) |i| {
        out.?[i] = .{};
        const raw = fakeDirEntry("C:\\", @intCast(i + 2), &out.?[i].path, out.?[i].path.len);
        out.?[i].info = .{ .exists = 1, .is_dir = @intFromBool(raw == 1) };
    }
    return @intCast(count);
}

fn metadataFromFixture(info: r4os.abi.FileInfo) r4os.abi.FileMetadata2 {
    return .{
        .flags = (if (info.exists != 0) r4os.abi.file_metadata2_flag_exists else @as(u32, 0)) |
            (if (info.is_dir != 0) r4os.abi.file_metadata2_flag_directory else @as(u32, 0)) |
            r4os.abi.file_metadata2_flag_byte_size_valid,
        .byte_size = info.size,
        .drive_letter = 'C',
    };
}

fn fakeMetadata(path: [*:0]const u8, out: *r4os.abi.FileMetadata2) callconv(.c) i32 {
    var info: r4os.abi.FileInfo = .{};
    const result = fakeFileInfo(path, &info);
    out.* = metadataFromFixture(info);
    return result;
}

fn metadataBatchFixture(comptime source: anytype, path: ?[*:0]const u8, cursor: *r4os.abi.DirectoryMetadataCursor2, out: ?[*]r4os.abi.DirectoryMetadataEntry2, capacity: u32) i32 {
    var entries: [4]r4os.abi.DirectoryBatchEntry = @splat(.{});
    std.debug.assert(capacity <= entries.len);
    const result = source(path, &cursor.scan, if (capacity == 0) null else &entries, capacity);
    if (result > 0) {
        for (entries[0..@intCast(result)], 0..) |entry, index| {
            out.?[index] = .{ .path = entry.path, .info = metadataFromFixture(entry.info) };
        }
    }
    return result;
}

fn fakeDirectoryMetadataBatch(path: ?[*:0]const u8, cursor: *r4os.abi.DirectoryMetadataCursor2, out: ?[*]r4os.abi.DirectoryMetadataEntry2, capacity: u32) callconv(.c) i32 {
    return metadataBatchFixture(fakeDirectoryBatch, path, cursor, out, capacity);
}

fn makeSys(full: bool) r4os.platform2.abi.R4XStartR4Sys2 {
    var table: r4os.platform2.abi.R4XStartR4Sys2 = .{};
    table.write = @intFromPtr(&fakeWrite);
    table.putc = @intFromPtr(&fakePutc);
    if (!full) return table;
    table.file_read = @intFromPtr(&fakeFileRead);
    table.file_write = @intFromPtr(&fakeFileWrite);
    table.file_read_at = @intFromPtr(&fakeFileReadAt);
    table.file_append = @intFromPtr(&fakeFileAppend);
    table.file_info = @intFromPtr(&fakeFileInfo);
    table.file_delete = @intFromPtr(&fakeDelete);
    table.file_rename = @intFromPtr(&fakeRename);
    table.dir_create = @intFromPtr(&fakeDirCreate);
    table.dir_delete = @intFromPtr(&fakeDelete);
    table.dir_entry = @intFromPtr(&fakeDirEntry);
    table.directory_batch = @intFromPtr(&fakeDirectoryBatch);
    table.file_metadata2 = @intFromPtr(&fakeMetadata);
    table.directory_metadata_batch2 = @intFromPtr(&fakeDirectoryMetadataBatch);
    table.file_stream_begin = @intFromPtr(&fakeStreamBegin);
    table.file_stream_write = @intFromPtr(&fakeStreamWrite);
    table.file_stream_finish = @intFromPtr(&fakeStreamFinish);
    table.file_stream_abort = @intFromPtr(&fakeStreamAbort);
    table.registry_get_value = @intFromPtr(&fakeRegistryGet);
    table.registry_set_value = @intFromPtr(&fakeRegistrySet);
    return table;
}

fn fixtureShouldClose(_: *const r4os.platform2.abi.R4XStartContext2) callconv(.c) u32 {
    return 0;
}

fn makeApp(table: *r4os.platform2.abi.R4XStartR4Sys2, imports: *[1]r4os.abi.R4XStartImport, context: *r4os.platform2.abi.R4XStartContext2) !r4os.App {
    imports.* = .{
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4sys), .resolved_version = 2, .min_version = 2, .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(table) },
    };
    context.* = .{
        .app_class = 1,
        .flags = r4os.abi.r4xstart_flag_imports_valid | r4os.abi.r4xstart_flag_close_supported,
        .should_close = @intFromPtr(&fixtureShouldClose),
        .imports = @intFromPtr(imports),
        .import_count = imports.len,
    };
    return switch (r4os.App.init(context, .console)) {
        .value => |app| app,
        .failure => error.AppInit,
    };
}

test "files directory streams and registry use caller owned state" {
    var table = makeSys(true);
    var imports: [1]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&table, &imports, &context);
    var files = app.files() orelse return error.FilesMissing;
    var file_path = try r4os.FilePath.parse("C:/TEMP/FILE.TXT");
    table.size = @sizeOf(r4os.platform2.abi.R4XStartR4Sys2);
    table.file_name_limits = @intFromPtr(&fakeNameLimits);
    name_limits_result = 0;
    const limits = files.nameLimits(file_path.asZ()).value;
    try std.testing.expectEqual(@as(u64, 99), limits.mount_generation);
    try std.testing.expectEqual(@as(u32, 255), limits.max_component_utf16_units);
    for ([_]i32{ r4os.abi.file_stream_error_name_not_supported, r4os.abi.file_stream_error_name_too_long, r4os.abi.file_stream_error_unsupported }) |code| {
        name_limits_result = code;
        try std.testing.expectEqual(code, files.nameLimits(file_path.asZ()).failure);
    }
    name_limits_result = 0;
    var out: [16]u8 = undefined;
    switch (files.read(file_path.asZ(), out[0..])) {
        .bytes => |count| try std.testing.expectEqualStrings(file_bytes, out[0..count]),
        else => return error.ReadFailed,
    }
    switch (files.write(file_path.asZ(), "A")) {
        .bytes => |count| try std.testing.expectEqual(@as(u32, 1), count),
        else => return error.WriteFailed,
    }
    switch (files.append(file_path.asZ(), "B")) {
        .bytes => |count| try std.testing.expectEqual(@as(u32, 1), count),
        else => return error.AppendFailed,
    }
    try std.testing.expectEqualStrings("AB", written[0..written_len]);

    var directory = try r4os.FilePath.parse("C:\\");
    var iterator = files.iterate(directory.asZ());
    var entry_buffer: [128]u8 = undefined;
    switch (iterator.next(entry_buffer[0..])) {
        .entry => |entry| try std.testing.expect(entry.kind == .file),
        else => return error.EntryMissing,
    }
    switch (iterator.next(entry_buffer[0..])) {
        .entry => |entry| try std.testing.expect(entry.kind == .directory),
        else => return error.EntryMissing,
    }
    try std.testing.expect(iterator.next(entry_buffer[0..]) == .end);
    try std.testing.expect(iterator.next(entry_buffer[0..]) == .end);

    var reader = files.streamReader(file_path.asZ());
    switch (reader.read(out[0..2])) {
        .bytes => |count| try std.testing.expectEqual(@as(u32, 2), count),
        else => return error.StreamRead,
    }
    switch (reader.read(out[0..])) {
        .bytes => |count| try std.testing.expectEqual(@as(u32, 3), count),
        else => return error.StreamRead,
    }
    try std.testing.expect(reader.read(out[0..]) == .end);

    var writer = switch (files.streamWriter(file_path.asZ(), r4os.abi.file_stream_open_replace)) {
        .writer => |value| value,
        .failure => return error.StreamOpen,
    };
    try std.testing.expect(writer.write("stream") == .ok);
    try std.testing.expect(writer.finish() == .ok);
    var abort_writer = switch (files.streamWriter(file_path.asZ(), r4os.abi.file_stream_open_replace)) {
        .writer => |value| value,
        .failure => return error.StreamOpen,
    };
    try std.testing.expect(abort_writer.abort() == .ok and stream_aborted);

    var registry = app.registry() orelse return error.RegistryMissing;
    var key = try r4os.RegistryPath.parse("HKCU/Software/Test");
    switch (registry.get(&key, "COUNT", out[0..])) {
        .value => |value| try std.testing.expectEqual(@as(?u32, 0x12345678), value.asU32()),
        else => return error.RegistryRead,
    }
    try std.testing.expect(registry.setU32(&key, "COUNT", 99) == .ok);
    try std.testing.expectEqual(@as(u32, 99), registry_set_value);
    switch (registry.get(&key, "WIDE", out[0..])) {
        .value => |value| try std.testing.expectEqual(@as(?u64, 0x0102030405060708), value.asU64()),
        else => return error.RegistryRead,
    }
    switch (registry.get(&key, "ENABLED", out[0..])) {
        .value => |value| try std.testing.expectEqual(@as(?bool, true), value.asBool()),
        else => return error.RegistryRead,
    }
    switch (registry.get(&key, "TEXT", out[0..])) {
        .value => |value| try std.testing.expectEqualStrings("OK", value.asString() orelse return error.RegistryType),
        else => return error.RegistryRead,
    }
    try std.testing.expect(registry.setU64(&key, "WIDE", 0x0102030405060708) == .ok);
    try std.testing.expectEqual(r4os.abi.registry_value_type_u64, registry_set_type);
    try std.testing.expectEqual(@as(u64, 0x0102030405060708), registry_set_wide);
    try std.testing.expect(registry.setBool(&key, "ENABLED", true) == .ok);
    try std.testing.expectEqual(r4os.abi.registry_value_type_bool, registry_set_type);
}

test "missing capability and long paths fail before hidden fallback" {
    var table = makeSys(false);
    var imports: [1]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&table, &imports, &context);
    try std.testing.expect(app.files() == null);
    try std.testing.expect(app.registry() == null);
    var too_long: [r4os.path.file_path_max + 1]u8 = .{'A'} ** (r4os.path.file_path_max + 1);
    try std.testing.expectError(error.TooLong, r4os.FilePath.parse(too_long[0..]));
}

var resume_calls: usize = 0;
var resume_stale = false;
fn fakeBoundBatch(_: ?[*:0]const u8, cursor: *r4os.abi.DirectoryBatchCursor, out: ?[*]r4os.abi.DirectoryBatchEntry, capacity: u32) callconv(.c) i32 {
    resume_calls += 1;
    if (resume_stale) return -10;
    if (capacity == 0) return 0;
    if (cursor.backend[0] == 0) {
        cursor.backend[0] = 1;
        cursor.change.mount_generation = 1;
        return 0;
    }
    if (cursor.backend[0] > 1) return -5;
    for (0..2) |i| {
        out.?[i] = .{};
        _ = copyOut(if (i == 0) "C:\\ONE.TXT\x00" else "C:\\TWO.TXT\x00", &out.?[i].path, out.?[i].path.len);
        out.?[i].info = .{ .exists = 1, .size = 123 };
    }
    cursor.backend[0] = 2;
    return 2;
}

fn fakeBoundMetadataBatch(path: ?[*:0]const u8, cursor: *r4os.abi.DirectoryMetadataCursor2, out: ?[*]r4os.abi.DirectoryMetadataEntry2, capacity: u32) callconv(.c) i32 {
    return metadataBatchFixture(fakeBoundBatch, path, cursor, out, capacity);
}

fn snapshotLess(_: void, a: u32, b: u32) bool {
    return a < b;
}
test "directory continuation carries metadata preserves restart and bounds complete snapshots" {
    var table = makeSys(true);
    table.size = @sizeOf(r4os.platform2.abi.R4XStartR4Sys2);
    table.directory_metadata_batch2 = @intFromPtr(&fakeBoundMetadataBatch);
    var imports: [1]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    const app = try makeApp(&table, &imports, &context);
    const files = r4os.Files{ .sys = app.system() };
    var it = files.iterate(.{ .ptr = "C:\\", .len = 3 });
    var path: [128]u8 = undefined;
    resume_calls = 0;
    resume_stale = false;
    var too_small: [4]u8 = undefined;
    try std.testing.expectEqual(@as(i32, -7), it.next(&too_small).failure);
    try std.testing.expectEqual(@as(u32, 0), it.buffer_index);
    const item = it.next(&path).entry;
    try std.testing.expectEqual(@as(u64, 123), item.info.?.size);
    try std.testing.expectEqualStrings("C:\\ONE.TXT", item.path);
    try std.testing.expectEqual(@as(usize, 4), resume_calls);
    resume_stale = true;
    try std.testing.expectEqual(@as(i32, -10), it.next(&path).failure);
    resume_stale = false;
    // A stale generation discards the entire private batch. Restart from a
    // fresh current cursor before exposing either row again.
    it = files.iterate(.{ .ptr = "C:\\", .len = 3 });
    try std.testing.expectEqualStrings("C:\\ONE.TXT", it.next(&path).entry.path);
    try std.testing.expectEqualStrings("C:\\TWO.TXT", it.next(&path).entry.path);
    try std.testing.expect(it.next(&path) == .end);
    const calls = resume_calls;
    try std.testing.expect(it.next(&path) == .end);
    try std.testing.expectEqual(calls, resume_calls);
    // Current metadata traversal requires a fresh cursor after mutation.
    it.revisitAfterRemoval();
    try std.testing.expectEqual(r4os.abi.file_metadata2_error_restart, it.next(&path).failure);
    try std.testing.expectEqual(calls, resume_calls);
    const allocator = std.testing.allocator;
    var snapshot = r4os.directory_page.Snapshot(u32, 257 * 4){};
    defer snapshot.deinit(allocator);
    for (0..257) |i| try snapshot.append(allocator, @intCast(256 - i));
    snapshot.sort({}, snapshotLess);
    for (snapshot.values.items, 0..) |value, i| try std.testing.expectEqual(i, value);
    try std.testing.expectError(error.OutOfMemory, snapshot.append(allocator, 999));
    try std.testing.expectEqual(@as(usize, 257), snapshot.values.items.len);
    var no_memory = std.heap.FixedBufferAllocator.init(&.{});
    var candidate = r4os.directory_page.Snapshot(u32, 4096){};
    defer candidate.deinit(no_memory.allocator());
    try std.testing.expectError(error.OutOfMemory, candidate.append(no_memory.allocator(), 1));
    try std.testing.expectEqual(@as(usize, 0), candidate.values.items.len);
    try std.testing.expectEqual(@as(u32, 256), snapshot.values.items[256]);
}
