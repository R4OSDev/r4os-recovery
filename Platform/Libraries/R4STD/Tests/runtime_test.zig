const std = @import("std");
const project = @import("project");
const r4std = @import("r4std");
const r4os = @import("r4os");

const module_name: [:0]const u8 = "R4STD";
const export_names = [_][:0]const u8{ "TEXT_V1", "SETTINGS_V1", "DATE_V1", "TIME_V1", "CONFIG_V1" };

test "CONFIG_V1 uses actual generation2 caller and refuses invalid admission before IO" {
    const Backend = struct {
        var calls: u32 = 0;
        const document = "\xef\xbb\xbfNAME=Generation2\r\n";
        fn read(_: [*:0]const u8, output: [*]u8, capacity: u32) callconv(.c) i32 {
            calls += 1;
            if (capacity < document.len) return -1;
            @memcpy(output[0..document.len], document);
            return document.len;
        }
    };
    Backend.calls = 0;
    const read: r4os.abi.R4SysFns.file_read = &Backend.read;
    const sys: r4os.platform2.abi.R4XStartR4Sys2 = .{ .file_read = @intFromPtr(read) };
    var descriptor = project.r4std_query2;
    const imports = [_]r4os.abi.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) },
        .{ .module_name = @intFromPtr(module_name.ptr), .symbol_name = @intFromPtr(@as([*:0]const u8, "Query2")), .min_version = 2, .resolved_version = 2, .table = @intFromPtr(&descriptor) },
        .{ .module_name = @intFromPtr(module_name.ptr), .symbol_name = @intFromPtr(export_names[4].ptr), .min_version = 1, .resolved_version = 1, .table = @intFromPtr(&project.r4std_config_v1) },
    };
    const raw: r4os.platform2.abi.R4XStartContext2 = .{ .imports = @intFromPtr(&imports), .import_count = imports.len };
    const client = try r4std.abi.ConfigV1Client.init2(&raw);
    var output: [32]u8 = @splat(0xa5);
    var scalar: u64 = 77;
    const path = "C:\\TEST.R4S";
    try std.testing.expectEqual(r4std.config.result_ok, client.read(@intFromPtr(&raw), path, path.len, "NAME", 4, r4std.abi.config_kind_string, "fallback", 8, 0, &output, output.len, &scalar));
    try std.testing.expectEqualStrings("Generation2", std.mem.sliceTo(&output, 0));
    try std.testing.expectEqual(@as(u32, 1), Backend.calls);
    descriptor.size = 16;
    try std.testing.expectError(error.InvalidQuery, r4std.abi.ConfigV1Client.init2(&raw));
    try std.testing.expectEqual(@as(u32, 1), Backend.calls);
    var invalid = raw;
    invalid.size = 16;
    output = @splat(0xa5);
    scalar = 77;
    try std.testing.expectEqual(r4std.abi.status_unavailable, project.r4std_config_read_impl(@intFromPtr(&invalid), path, path.len, "NAME", 4, r4std.abi.config_kind_string, "fallback", 8, 0, &output, output.len, &scalar));
    try std.testing.expectEqual(@as(u64, 77), scalar);
    try std.testing.expectEqualSlices(u8, &@as([32]u8, @splat(0xa5)), &output);
    try std.testing.expectEqual(@as(u32, 1), Backend.calls);
}

fn makeContext(imports: []const r4os.abi.R4XStartImport) r4os.abi.R4XStartContext {
    return .{
        .flags = r4os.abi.r4xstart_flag_imports_valid,
        .imports = @intFromPtr(imports.ptr),
        .import_count = @intCast(imports.len),
    };
}

fn makeImports() [5]r4os.abi.R4XStartImport {
    const tables = [_]usize{
        @intFromPtr(&project.r4std_text_v1),
        @intFromPtr(&project.r4std_settings_v1),
        @intFromPtr(&project.r4std_date_v1),
        @intFromPtr(&project.r4std_time_v1),
        @intFromPtr(&project.r4std_config_v1),
    };
    var imports: [5]r4os.abi.R4XStartImport = undefined;
    for (&imports, export_names, tables) |*item, export_name, table| {
        item.* = .{
            .group_id = 0,
            .min_version = 1,
            .resolved_version = 1,
            .flags = 0,
            .module_name = @intFromPtr(module_name.ptr),
            .symbol_name = @intFromPtr(export_name.ptr),
            .table = table,
        };
    }
    return imports;
}

test "text settings date and time calls cross local runtime tables" {
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = makeImports();
    var raw = makeContext(&imports);
    raw.imports = @intFromPtr(&imports);
    try std.testing.expect(r4std.init(&raw));

    try std.testing.expect(r4std.config.pathsEqualIgnoreCase("C:\\A.TXT", "c:\\a.txt"));
    try std.testing.expect(!r4std.config.pathsEqualIgnoreCase("C:\\A.TXT", "C:\\B.TXT"));

    const utf8 = try r4std.text.Utf8Text.init("Gru\xC3\x9F");
    try std.testing.expectEqual(@as(usize, 4), utf8.scalarCount());
    var canonical_buffer: [64]u8 = undefined;
    const canonical = try r4std.settings.canonicalizeSystemText("A\nB\r\n", &canonical_buffer);
    try std.testing.expectEqualStrings(r4std.settings.utf8_bom ++ "A\r\nB\r\n", canonical);

    var settings_buffer: [128]u8 = undefined;
    var writer = r4std.settings.Writer.init(&settings_buffer);
    writer.writeHeader("TEST");
    writer.writePairU32("COUNT", 42);
    try std.testing.expect(writer.ok());
    const document = r4std.settings.Document.init(writer.bytes());
    try std.testing.expectEqual(@as(?u32, 42), document.u32Value("COUNT"));

    try std.testing.expect(r4std.date.validDateValue(2000, 2, 29));
    try std.testing.expect(!r4std.date.validDateValue(1900, 2, 29));
    const parsed = r4std.date.parseDateIso("2026-08-14") orelse return error.DateParseFailed;
    var date_buffer: [16]u8 = undefined;
    try std.testing.expectEqualStrings("2026-08-14", r4std.date.formatDateIso(&date_buffer, parsed));

    var time_config = r4std.time.Config{};
    try std.testing.expect(time_config.loadFromBytes("TIMEZONE=Europe/Berlin\r\nCLOCK_FORMAT=12H\r\n"));
    try std.testing.expectEqual(@as(usize, 15), time_config.selectedIndex());
    try std.testing.expectEqual(r4os.abi.clock_format_12h, time_config.selectedClockFormat());
    try std.testing.expectEqual(@as(i16, 60), r4std.time.standardOffsetAt(15));
    var summer = std.mem.zeroes(r4os.abi.TimeState);
    summer.valid = 1;
    summer.year = 2026;
    summer.month = 6;
    summer.day = 1;
    try std.testing.expectEqual(@as(i16, 120), r4std.time.offsetAtState(15, summer));
}

test "writeback state remains caller-owned across table calls" {
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = makeImports();
    var raw = makeContext(&imports);
    raw.imports = @intFromPtr(&imports);
    try std.testing.expect(r4std.init(&raw));

    var state = r4std.settings.Writeback.init(r4std.settings.WritebackPolicy.forHz(.soon, 100));
    state.markDirty(10);
    try std.testing.expect(state.isDirty());
    const Saver = struct {
        pub fn save(_: @This()) i32 {
            return 1;
        }
    };
    const flush = state.flushNow(11, Saver{});
    try std.testing.expect(flush.action == .saved);
    try std.testing.expect(!state.isDirty());
}

fn codecContext() [6]r4os.abi.R4XStartImport {
    var imports: [6]r4os.abi.R4XStartImport = undefined;
    const old = makeImports();
    @memcpy(imports[0..5], &old);
    imports[5] = .{ .group_id = 0, .min_version = 1, .resolved_version = 1, .flags = 0, .module_name = @intFromPtr(module_name.ptr), .symbol_name = @intFromPtr(@as([:0]const u8, "CODEC_V1").ptr), .table = @intFromPtr(&project.r4std_codec_v1) };
    return imports;
}

fn checkMapping(codepage: r4std.codec.Codepage, mode: r4std.codec.Mode, hash_hex: []const u8) !void {
    var words: [1024]u8 = undefined;
    for (0..256) |index| {
        const byte: u8 = @intCast(index);
        const scalar = r4std.codec.legacyDecode(codepage, mode, byte) catch |err| {
            try std.testing.expect(codepage == .windows1252 and mode == .controls and (byte == 0x81 or byte == 0x8d or byte == 0x8f or byte == 0x90 or byte == 0x9d));
            try std.testing.expect(err == error.UndefinedByte);
            std.mem.writeInt(u32, words[index * 4 ..][0..4], 0xffffffff, .little);
            continue;
        };
        std.mem.writeInt(u32, words[index * 4 ..][0..4], scalar, .little);
        try std.testing.expectEqual(byte, try r4std.codec.legacyEncode(codepage, mode, scalar));
        var encoded: [4]u8 = @splat(0xaa);
        const utf8 = try r4std.codec.encode(scalar, &encoded);
        const decoded = (try r4std.codec.decode(utf8)).complete;
        try std.testing.expectEqual(scalar, decoded.value);
        try std.testing.expectEqual(utf8.len, decoded.byte_length);
    }
    var actual: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(&words, &actual, .{});
    var expected: [32]u8 = undefined;
    _ = try std.fmt.hexToBytes(&expected, hash_hex);
    try std.testing.expectEqualSlices(u8, &expected, &actual);
}

test "official complete legacy mappings cross real provider and inverse tables" {
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = codecContext();
    var raw = makeContext(&imports);
    try std.testing.expect(r4std.init(&raw));
    try checkMapping(.cp437, .controls, "3b331692abddbdfa697e0e3b15e34d07859840f1d94e36eef8d34985405235ed");
    try checkMapping(.windows1252, .controls, "5ec4fd69b5ccaa999c8d15a2f30f1bed47757c063df0b27f9175cc118ff4f0c5");
    try checkMapping(.cp437, .pc_graphics, "2446a15fd3bc89a9b6eaf0e55d747a700224bac411e77e083c240e69a845939f");
    try std.testing.expectEqual(@as(u32, 0xfc), try r4std.codec.legacyDecode(.cp437, .controls, 0x81));
    try std.testing.expectEqual(@as(u32, 0x2500), try r4std.codec.legacyDecode(.cp437, .controls, 0xc4));
    try std.testing.expectEqual(@as(u32, 1), try r4std.codec.legacyDecode(.cp437, .controls, 1));
    try std.testing.expectEqual(@as(u32, 0x263a), try r4std.codec.legacyDecode(.cp437, .pc_graphics, 1));
    try std.testing.expectError(error.InvalidArgument, r4std.codec.legacyDecode(.cp850, .controls, 0x81));
    try std.testing.expectError(error.InvalidArgument, r4std.codec.legacyDecode(.windows1252, .pc_graphics, 0x81));
    try std.testing.expectError(error.Unrepresentable, r4std.codec.legacyEncode(.cp437, .controls, 0x20ac));
    try std.testing.expectError(error.Unrepresentable, r4std.codec.legacyEncode(.windows1252, .controls, 0x81));
    try std.testing.expectError(error.InvalidScalar, r4std.codec.legacyEncode(.cp437, .controls, 0xd800));
}

test "strict UTF8 scalar boundaries all two-byte prefixes and separate stream instances" {
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = codecContext();
    var raw = makeContext(&imports);
    try std.testing.expect(r4std.init(&raw));
    const values = [_]u32{ 0, 0x7f, 0x80, 0x7ff, 0x800, 0xd7ff, 0xe000, 0xfdd0, 0xffff, 0x10000, 0x1f600, 0x10ffff };
    for (values) |scalar| {
        var expected: [4]u8 = undefined;
        const count = try std.unicode.utf8Encode(@intCast(scalar), &expected);
        var bytes: [4]u8 = @splat(0xaa);
        const result = try r4std.codec.encode(scalar, &bytes);
        try std.testing.expectEqualSlices(u8, expected[0..count], result);
        for (0..result.len + 1) |cut| {
            var stream: r4std.codec.Stream = .{};
            for (result[0..cut]) |byte| _ = try stream.push(byte);
            try std.testing.expectEqual(cut == 0 or cut == result.len, try stream.finish());
            for (result[cut..]) |byte| _ = try stream.push(byte);
            try std.testing.expect(try stream.finish());
            if (cut < result.len) try std.testing.expect((try r4std.codec.decode(result[0..cut])) == .incomplete);
        }
    }
    // Independent std Unicode validator is the oracle for every first/second byte.
    for (0..256) |first| for (0..256) |second| {
        var bytes = [_]u8{ @intCast(first), @intCast(second), 0x80, 0x80 };
        const length = std.unicode.utf8ByteSequenceLength(bytes[0]) catch 0;
        const expected = length != 0 and std.unicode.utf8ValidateSlice(bytes[0..length]);
        const decoded = r4std.codec.decode(bytes[0..2]);
        if (!expected) {
            try std.testing.expectError(error.InvalidUtf8, decoded);
        } else {
            const got = try decoded;
            try std.testing.expectEqual(length > 2, got == .incomplete);
        }
    };
    var one: r4std.codec.Stream = .{};
    var two: r4std.codec.Stream = .{};
    _ = try one.push(0xc3);
    _ = try two.push(0xf0);
    _ = try two.push(0x9f);
    try std.testing.expectEqual(@as(u32, 0xfc), (try one.push(0xbc)).complete.value);
    _ = try two.push(0x98);
    try std.testing.expectEqual(@as(u32, 0x1f600), (try two.push(0x80)).complete.value);
    try std.testing.expect(try one.finish());
    try std.testing.expect(try two.finish());
    try std.testing.expectEqual(@as(usize, 2), try r4std.codec.scalarCount("e\xcc\x81")); // One grapheme is separate.
    try std.testing.expectError(error.InvalidUtf8, r4std.text.Utf8Text.init("A\x00B"));
}

test "codec invalid states and invalid input preserve exact caller outputs" {
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = codecContext();
    var raw = makeContext(&imports);
    try std.testing.expect(r4std.init(&raw));
    var stream: r4std.codec.Stream = .{};
    _ = try stream.push(0xe0);
    const before = stream.state;
    try std.testing.expectError(error.InvalidUtf8, stream.push(0x80));
    try std.testing.expectEqualDeep(before, stream.state);
    try std.testing.expectError(error.InvalidUtf8, stream.push('A'));
    try std.testing.expectEqualDeep(before, stream.state);
    try std.testing.expect(!(try stream.finish()));
    stream.reset();
    try std.testing.expectEqual(@as(u32, 'A'), (try stream.push('A')).complete.value);
    for ([_]r4std.abi.R4StdUtf8State{
        .{ .packed_bytes = 0, .length = 4, .reserved0 = 0, .reserved1 = 0 },
        .{ .packed_bytes = 0, .length = 0, .reserved0 = 1, .reserved1 = 0 },
        .{ .packed_bytes = 1, .length = 0, .reserved0 = 0, .reserved1 = 0 },
        .{ .packed_bytes = 0x80, .length = 1, .reserved0 = 0, .reserved1 = 0 },
        .{ .packed_bytes = 0x100c3, .length = 1, .reserved0 = 0, .reserved1 = 0 },
    }) |bad| {
        stream.state = bad;
        try std.testing.expectError(error.InvalidArgument, stream.push('A'));
        try std.testing.expectEqualDeep(bad, stream.state);
        try std.testing.expectError(error.InvalidArgument, stream.finish());
    }
    for ([_]u32{ 0xd800, 0xdfff, 0x110000, 0xffffffff }) |scalar| {
        var bytes: [4]u8 = @splat(0xa5);
        try std.testing.expectError(error.InvalidScalar, r4std.codec.encode(scalar, &bytes));
        try std.testing.expectEqualSlices(u8, &@as([4]u8, @splat(0xa5)), &bytes);
    }
    var byte: u8 = 0xa5;
    var scalar: u32 = 0xabababab;
    try std.testing.expectEqual(r4std.abi.status_invalid_argument, project.r4std_codec_legacy_decode_impl(437, 0, 256, &scalar));
    try std.testing.expectEqual(@as(u32, 0xabababab), scalar);
    try std.testing.expectEqual(r4std.abi.status_unrepresentable, project.r4std_codec_legacy_encode_impl(437, 0, 0x20ac, &byte));
    try std.testing.expectEqual(@as(u8, 0xa5), byte);
}

test "strict bulk conversion preflights errors and preserves arbitrary document bytes" {
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = codecContext();
    var raw = makeContext(&imports);
    try std.testing.expect(r4std.init(&raw));
    var original: [256]u8 = undefined;
    for (&original, 0..) |*b, i| b.* = @intCast(i);
    var utf8: [768]u8 = @splat(0xa5);
    var back: [256]u8 = @splat(0xa5);
    for ([_]r4std.codec.Mode{ .controls, .pc_graphics }) |mode| {
        const encoded = try r4std.codec.legacyToUtf8(.cp437, mode, &original, &utf8);
        try std.testing.expectEqualSlices(u8, &original, try r4std.codec.utf8ToLegacy(.cp437, mode, encoded, &back));
    }
    const document = try r4std.text.DocumentText.init(&original);
    try std.testing.expect(document.encoding == .bytes);
    try std.testing.expectEqualSlices(u8, &original, try document.writeExact(&back));
    const sentinel: [8]u8 = @splat(0x5a);
    var out = sentinel;
    try std.testing.expectError(error.UndefinedByte, r4std.codec.legacyToUtf8(.windows1252, .controls, "A\x81", &out));
    try std.testing.expectEqualSlices(u8, &sentinel, &out);
    try std.testing.expectError(error.Unrepresentable, r4std.codec.utf8ToLegacy(.cp437, .controls, "A\xf0\x9f\x98\x80", &out));
    try std.testing.expectEqualSlices(u8, &sentinel, &out);
    try std.testing.expectError(error.InvalidUtf8, r4std.codec.utf8ToLegacy(.cp437, .controls, "A\xed\xa0\x80", &out));
    try std.testing.expectEqualSlices(u8, &sentinel, &out);
    try std.testing.expectError(error.BufferTooSmall, r4std.codec.legacyToUtf8(.cp437, .controls, &original, &out));
    try std.testing.expectEqualSlices(u8, &sentinel, &out);
    var overlap: [8]u8 = .{ 'A', 'B', 0x81, 'C', 0, 0, 0, 0 };
    const saved = overlap;
    try std.testing.expectError(error.RangesOverlap, r4std.codec.legacyToUtf8(.cp437, .controls, overlap[0..4], overlap[1..]));
    try std.testing.expectError(error.RangesOverlap, r4std.codec.legacyToUtf8(.cp437, .controls, overlap[1..4], overlap[0..]));
    try std.testing.expectEqualSlices(u8, &saved, &overlap);
}

extern fn r4std_codec_c_transport(api: *const r4std.abi.CodecV1) callconv(.c) c_int;
test "all six codec function signatures cross C and Zig with real provider state" {
    try std.testing.expectEqual(@as(c_int, 0), r4std_codec_c_transport(@ptrCast(&project.r4std_codec_v1)));
    // The five legacy imports remain sufficient and never pretend the new API exists.
    r4std.resetForTesting();
    defer r4std.resetForTesting();
    var imports = makeImports();
    var raw = makeContext(&imports);
    try std.testing.expect(r4std.init(&raw));
    try std.testing.expectError(error.RuntimeUnavailable, r4std.codec.legacyDecode(.cp437, .controls, 0x81));
    try std.testing.expectEqual(@as(usize, 1), (try r4std.text.Utf8Text.init("A")).scalarCount());
}
