const std = @import("std");
const r4font = @import("r4font");

const Fixture = struct {
    name: []const u8,
    bytes: []const u8,
    format: r4font.Format,
    glyph_index: u32,
    family: []const u8,
    style: []const u8,
    glyph_count: u32,
    units_per_em: u32,
    ascender: i32,
    descender: i32,
    line_height: i32,
    advance_x: i32,
    advance_y: i32,
    bearing_x: i32,
    bearing_y: i32,
    glyph_width: i32,
    glyph_height: i32,
    raster_width: u32,
    raster_height: u32,
    raster_sha256: []const u8,
    bold: bool,
    italic: bool,
};

const fixtures = [_]Fixture{
    .{
        .name = "sample-glyf.ttf",
        .bytes = @embedFile("../Fixtures/sample-glyf.ttf"),
        .format = .ttf,
        .glyph_index = 8,
        .family = "CanvasTest",
        .style = "Medium",
        .glyph_count = 13,
        .units_per_em = 1024,
        .ascender = 1745,
        .descender = -805,
        .line_height = 2642,
        .advance_x = 1024,
        .advance_y = 1024,
        .bearing_x = 0,
        .bearing_y = 768,
        .glyph_width = 1024,
        .glyph_height = 768,
        .raster_width = 32,
        .raster_height = 24,
        .raster_sha256 = "069af124b2f3cf012a5020a5fbb99a474031f732f11b3429aac3f1e6beb13aab",
        .bold = false,
        .italic = false,
    },
    .{
        .name = "sample-cff.otf",
        .bytes = @embedFile("../Fixtures/sample-cff.otf"),
        .format = .otf_cff,
        .glyph_index = 1,
        .family = "embeded",
        .style = "Regular",
        .glyph_count = 9,
        .units_per_em = 1000,
        .ascender = 1000,
        .descender = 0,
        .line_height = 1090,
        .advance_x = 800,
        .advance_y = 1000,
        .bearing_x = 50,
        .bearing_y = 800,
        .glyph_width = 700,
        .glyph_height = 800,
        .raster_width = 23,
        .raster_height = 26,
        .raster_sha256 = "95d4030d41b5e78db39c563f9991708a16526682f7a240f1c7fc0a5625888e33",
        .bold = false,
        .italic = false,
    },
    .{
        .name = "sample-cff.woff",
        .bytes = @embedFile("../Fixtures/sample-cff.woff"),
        .format = .woff,
        .glyph_index = 1,
        .family = "ExTest",
        .style = "Regular",
        .glyph_count = 2,
        .units_per_em = 1024,
        .ascender = 768,
        .descender = -256,
        .line_height = 1116,
        .advance_x = 1024,
        .advance_y = 1024,
        .bearing_x = 0,
        .bearing_y = 128,
        .glyph_width = 1024,
        .glyph_height = 128,
        .raster_width = 32,
        .raster_height = 4,
        .raster_sha256 = "e9175db65a9789096ca9cb5524d3abc2107df03e3c9ba3af1aca628f9c5d3bd2",
        .bold = false,
        .italic = false,
    },
    .{
        .name = "sample-glyf.woff2",
        .bytes = @embedFile("../Fixtures/sample-glyf.woff2"),
        .format = .woff2,
        .glyph_index = 3,
        .family = "IcTestFullWidth",
        .style = "Regular",
        .glyph_count = 4,
        .units_per_em = 1024,
        .ascender = 819,
        .descender = -205,
        .line_height = 1116,
        .advance_x = 1024,
        .advance_y = 1024,
        .bearing_x = 200,
        .bearing_y = 500,
        .glyph_width = 600,
        .glyph_height = 300,
        .raster_width = 19,
        .raster_height = 10,
        .raster_sha256 = "8487990ceae5ea7e458d2ac3729a540d29da2175989cba56ff06be8d9b2a4773",
        .bold = false,
        .italic = false,
    },
};

test "R4FONT opens every promised container through caller owned memory" {
    var context = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer context.deinit();

    for (fixtures) |fixture| {
        try std.testing.expectEqual(fixture.format, r4font.sniff(fixture.bytes).?);
        var face = context.openFace(fixture.bytes, 0) catch |err| {
            std.debug.print("fixture {s} failed: {s}\n", .{ fixture.name, @errorName(err) });
            return err;
        };
        defer face.deinit();
        const info = try face.info();
        try std.testing.expectEqualStrings(fixture.family, info.family);
        try std.testing.expectEqualStrings(fixture.style, info.style);
        try std.testing.expectEqual(@as(u32, 1), info.face_count);
        try std.testing.expectEqual(@as(u32, 0), info.face_index);
        try std.testing.expectEqual(fixture.glyph_count, info.glyph_count);
        try std.testing.expectEqual(fixture.units_per_em, info.units_per_em);
        try std.testing.expectEqual(fixture.ascender, info.ascender);
        try std.testing.expectEqual(fixture.descender, info.descender);
        try std.testing.expectEqual(fixture.line_height, info.line_height);
        try std.testing.expectEqual(fixture.bold, info.bold);
        try std.testing.expectEqual(fixture.italic, info.italic);

        const metrics = try face.glyphMetrics(fixture.glyph_index);
        try std.testing.expectEqual(fixture.glyph_index, metrics.glyph_index);
        try std.testing.expectEqual(fixture.advance_x, metrics.advance_x);
        try std.testing.expectEqual(fixture.advance_y, metrics.advance_y);
        try std.testing.expectEqual(fixture.bearing_x, metrics.bearing_x);
        try std.testing.expectEqual(fixture.bearing_y, metrics.bearing_y);
        try std.testing.expectEqual(fixture.glyph_width, metrics.width);
        try std.testing.expectEqual(fixture.glyph_height, metrics.height);

        var pixels: [r4font.max_raster_dimension * r4font.max_raster_dimension]u8 = undefined;
        const raster = try face.rasterize(fixture.glyph_index, 32, pixels[0..]);
        try std.testing.expectEqual(fixture.raster_width, raster.width);
        try std.testing.expectEqual(fixture.raster_height, raster.height);
        try std.testing.expectEqual(@as(usize, raster.width * raster.height), raster.alpha.len);
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(raster.alpha, &digest, .{});
        const digest_hex = std.fmt.bytesToHex(digest, .lower);
        try std.testing.expectEqualStrings(fixture.raster_sha256, &digest_hex);
    }

    const diagnostics = context.diagnostics();
    try std.testing.expect(diagnostics.peak_bytes > 0);
    try std.testing.expect(!diagnostics.allocation_failed);
}

test "R4FONT metrics and alpha raster are deterministic across repeated faces" {
    var context = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer context.deinit();

    var expected_hash: ?[32]u8 = null;
    var iteration: usize = 0;
    while (iteration < 8) : (iteration += 1) {
        var face = try context.openFace(fixtures[0].bytes, 0);
        defer face.deinit();
        const glyph = face.glyphIndex('A');
        try std.testing.expect(glyph != 0);
        const metrics = try face.glyphMetrics(glyph);
        try std.testing.expect(metrics.advance_x > 0);
        var pixels: [r4font.max_raster_dimension * r4font.max_raster_dimension]u8 = undefined;
        const raster = try face.rasterize(glyph, 32, pixels[0..]);
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(raster.alpha, &digest, .{});
        if (expected_hash) |expected| {
            try std.testing.expectEqualSlices(u8, &expected, &digest);
        } else {
            expected_hash = digest;
        }
    }
}

test "R4FONT exposes deterministic regular bold italic and combined style flags" {
    const StyleCase = struct { bold: bool, italic: bool };
    const cases = [_]StyleCase{
        .{ .bold = false, .italic = false },
        .{ .bold = true, .italic = false },
        .{ .bold = false, .italic = true },
        .{ .bold = true, .italic = true },
    };
    var decoder = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer decoder.deinit();
    const baseline = decoder.diagnostics().current_bytes;

    for (cases) |case| {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
        defer std.testing.allocator.free(bytes);
        try setStyleFlags(bytes, case.bold, case.italic);
        var face = try decoder.openFace(bytes, 0);
        const info = try face.info();
        try std.testing.expectEqual(case.bold, info.bold);
        try std.testing.expectEqual(case.italic, info.italic);
        face.deinit();
        try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
    }
}

test "R4FONT rejects signatures malformed faces and hard allocation limits" {
    try std.testing.expect(r4font.sniff("not a font") == null);
    var roomy = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    const initialized_bytes = roomy.diagnostics().current_bytes;
    try std.testing.expectError(error.UnsupportedFormat, roomy.openFace("not a font", 0));
    try std.testing.expectError(error.InvalidFont, roomy.openFace("wOFFbad payload", 0));
    roomy.deinit();

    var tight = try r4font.Decoder.init(std.testing.allocator, initialized_bytes + 16);
    defer tight.deinit();
    try std.testing.expectError(error.OutOfMemory, tight.openFace(fixtures[0].bytes, 0));
    try std.testing.expect(tight.diagnostics().allocation_failed);
}

test "R4FONT exposes legacy kern and basic GPOS pair positioning" {
    var context = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer context.deinit();

    var legacy = try context.openFace(@embedFile("../Fixtures/sample-kern.woff"), 0);
    defer legacy.deinit();
    const legacy_a = legacy.glyphIndex('A');
    const legacy_v = legacy.glyphIndex('V');
    try std.testing.expectEqual(@as(u32, 1), legacy_a);
    try std.testing.expectEqual(@as(u32, 2), legacy_v);
    try std.testing.expectEqual([2]i32{ -115, 0 }, try legacy.kerning(legacy_a, legacy_v));

    var gpos = try context.openFace(@embedFile("../Fixtures/sample-gpos.woff"), 0);
    defer gpos.deinit();
    const gpos_a = gpos.glyphIndex('A');
    const gpos_t = gpos.glyphIndex('T');
    try std.testing.expectEqual(@as(u32, 1), gpos_a);
    try std.testing.expectEqual(@as(u32, 3), gpos_t);
    try std.testing.expectEqual([2]i32{ -93, 0 }, try gpos.kerning(gpos_a, gpos_t));
}

test "R4FONT opens independent faces from an SFNT collection" {
    const collection = try buildTestCollection(std.testing.allocator, fixtures[0].bytes);
    defer std.testing.allocator.free(collection);
    try std.testing.expectEqual(r4font.Format.collection, r4font.sniff(collection).?);

    var context = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer context.deinit();
    var first = try context.openFace(collection, 0);
    defer first.deinit();
    var second = try context.openFace(collection, 1);
    defer second.deinit();
    const first_info = try first.info();
    const second_info = try second.info();
    try std.testing.expectEqual(@as(u32, 2), first_info.face_count);
    try std.testing.expectEqual(@as(u32, 2), second_info.face_count);
    try std.testing.expectEqual(@as(u32, 0), first_info.face_index);
    try std.testing.expectEqual(@as(u32, 1), second_info.face_index);
    try std.testing.expectEqual(first.glyphIndex('A'), second.glyphIndex('A'));
    try std.testing.expectError(error.InvalidFaceIndex, context.openFace(collection, 2));
}

test "R4FONT releases every partial WOFF2 decode under allocator fault injection" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationFailureRun, .{});
}

test "R4FONT rejects every truncated container without retaining decoder memory" {
    var context = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer context.deinit();
    const baseline = context.diagnostics().current_bytes;
    for (fixtures) |fixture| {
        var cut: usize = 0;
        while (cut < fixture.bytes.len) : (cut += 1) {
            if (context.openFace(fixture.bytes[0..cut], 0)) |opened| {
                var unexpected = opened;
                unexpected.deinit();
                std.debug.print("truncated fixture {s} opened at {d}/{d}\n", .{ fixture.name, cut, fixture.bytes.len });
                return error.InvalidFont;
            } else |err| switch (err) {
                error.InvalidArgument, error.UnsupportedFormat, error.InvalidFont => {},
                else => return err,
            }
            try std.testing.expectEqual(baseline, context.diagnostics().current_bytes);
        }
    }
}

test "R4FONT container preflight rejects forged lengths table ranges and Brotli data" {
    var context = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer context.deinit();
    const baseline = context.diagnostics().current_bytes;

    const ttf = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
    defer std.testing.allocator.free(ttf);
    const first_table_offset = readBe32(ttf, 12 + 8);
    writeBe32(ttf, 12 + 16 + 8, first_table_offset);
    try std.testing.expectError(error.InvalidFont, context.openFace(ttf, 0));
    try std.testing.expectEqual(baseline, context.diagnostics().current_bytes);

    const woff = try std.testing.allocator.dupe(u8, fixtures[2].bytes);
    defer std.testing.allocator.free(woff);
    writeBe32(woff, 8, @intCast(woff.len - 1));
    try std.testing.expectError(error.InvalidFont, context.openFace(woff, 0));
    try std.testing.expectEqual(baseline, context.diagnostics().current_bytes);

    const woff2 = try std.testing.allocator.dupe(u8, fixtures[3].bytes);
    defer std.testing.allocator.free(woff2);
    @memset(woff2[96..160], 0xA5);
    try std.testing.expectError(error.InvalidFont, context.openFace(woff2, 0));
    try std.testing.expectEqual(baseline, context.diagnostics().current_bytes);

    const collection = try buildTestCollection(std.testing.allocator, fixtures[0].bytes);
    defer std.testing.allocator.free(collection);
    writeBe32(collection, 16, 4);
    try std.testing.expectError(error.InvalidFont, context.openFace(collection, 0));
    try std.testing.expectEqual(baseline, context.diagnostics().current_bytes);
}

test "R4FONT reports stable boundary errors and leaves no partial face" {
    try std.testing.expectError(error.InvalidArgument, r4font.Decoder.init(std.testing.allocator, 0));
    var decoder = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer decoder.deinit();
    const baseline = decoder.diagnostics().current_bytes;

    try std.testing.expectError(error.InvalidArgument, decoder.openFace("", 0));
    try std.testing.expectError(error.UnsupportedFormat, decoder.openFace("BAD!", 0));
    try std.testing.expectError(error.InvalidFont, decoder.openFace("\x00\x01\x00\x00", 0));
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);

    const oversized = try std.testing.allocator.alloc(u8, r4font.max_source_bytes + 1);
    defer std.testing.allocator.free(oversized);
    @memset(oversized, 0);
    @memcpy(oversized[0..4], "\x00\x01\x00\x00");
    try std.testing.expectError(error.InvalidFont, decoder.openFace(oversized[0..r4font.max_source_bytes], 0));
    try std.testing.expectError(error.TooLarge, decoder.openFace(oversized, 0));
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);

    try std.testing.expectError(error.InvalidFaceIndex, decoder.openFace(fixtures[0].bytes, 1));
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);

    var face = try decoder.openFace(fixtures[0].bytes, 0);
    const info = try face.info();
    try std.testing.expectError(error.InvalidGlyph, face.glyphMetrics(info.glyph_count));
    try std.testing.expectError(error.InvalidGlyph, face.kerning(info.glyph_count, 0));
    var tiny = [_]u8{0xA5};
    try std.testing.expectError(error.InvalidGlyph, face.rasterize(info.glyph_count, 32, tiny[0..]));
    try std.testing.expectError(error.InvalidArgument, face.rasterize(fixtures[0].glyph_index, 3, tiny[0..]));
    try std.testing.expectError(error.InvalidArgument, face.rasterize(fixtures[0].glyph_index, 257, tiny[0..]));
    try std.testing.expectError(error.BufferTooSmall, face.rasterize(fixtures[0].glyph_index, 32, tiny[0..]));
    try std.testing.expectEqual(@as(u8, 0xA5), tiny[0]);
    face.deinit();
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
}

test "R4FONT rejects oversized contradictory and cyclic container metadata" {
    var decoder = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer decoder.deinit();
    const baseline = decoder.diagnostics().current_bytes;

    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe16(bytes, 4, 129);
        try expectErrorWithoutState(&decoder, baseline, bytes, error.TooLarge);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
        defer std.testing.allocator.free(bytes);
        @memcpy(bytes[28..32], bytes[12..16]);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe16(bytes, 6, 0);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 20, 12);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[2].bytes);
        defer std.testing.allocator.free(bytes);
        @memcpy(bytes[4..8], "wOFF");
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[2].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 16, @intCast(r4font.max_reconstructed_bytes + 1));
        try expectErrorWithoutState(&decoder, baseline, bytes, error.TooLarge);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[2].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 16, readBe32(bytes, 16) + 4);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[2].bytes);
        defer std.testing.allocator.free(bytes);
        @memcpy(bytes[64..68], bytes[44..48]);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[2].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 28, 4);
        writeBe32(bytes, 32, 4);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[3].bytes);
        defer std.testing.allocator.free(bytes);
        @memcpy(bytes[4..8], "wOF2");
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[3].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 16, @intCast(r4font.max_reconstructed_bytes + 1));
        try expectErrorWithoutState(&decoder, baseline, bytes, error.TooLarge);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[3].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 32, 4);
        writeBe32(bytes, 36, 4);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, fixtures[3].bytes);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 40, @intCast(bytes.len - 2));
        writeBe32(bytes, 44, 8);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }

    const collection = try buildTestCollection(std.testing.allocator, fixtures[0].bytes);
    defer std.testing.allocator.free(collection);
    {
        const bytes = try std.testing.allocator.dupe(u8, collection);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 8, 33);
        try expectErrorWithoutState(&decoder, baseline, bytes, error.TooLarge);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, collection);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 4, 0x00030000);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, collection);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 16, readBe32(bytes, 12));
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, collection);
        defer std.testing.allocator.free(bytes);
        const first_face: usize = readBe32(bytes, 12);
        @memcpy(bytes[first_face .. first_face + 4], "ttcf");
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }
    {
        const bytes = try std.testing.allocator.dupe(u8, collection);
        defer std.testing.allocator.free(bytes);
        writeBe32(bytes, 12, 12);
        try expectInvalidWithoutState(&decoder, baseline, bytes);
    }

    var recovered = try decoder.openFace(fixtures[0].bytes, 0);
    recovered.deinit();
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
}

test "R4FONT allocation and reallocation faults abort atomically and recover" {
    var decoder = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer decoder.deinit();
    const baseline = decoder.diagnostics().current_bytes;

    decoder.testingSetFaultInjection(.{ .allocation_after = 0 });
    try std.testing.expectError(error.OutOfMemory, decoder.openFace(fixtures[3].bytes, 0));
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
    decoder.testingSetFaultInjection(.{});

    var fatal_reallocation_seen = false;
    var total_reallocations: usize = 0;
    for (fixtures) |fixture| {
        const before_probe = decoder.diagnostics();
        var probe = try decoder.openFace(fixture.bytes, 0);
        probe.deinit();
        const after_probe = decoder.diagnostics();
        try std.testing.expectEqual(baseline, after_probe.current_bytes);
        const probe_reallocations = after_probe.reallocation_count - before_probe.reallocation_count;
        total_reallocations += probe_reallocations;

        var failure_index: usize = 0;
        while (failure_index < probe_reallocations) : (failure_index += 1) {
            const before_reallocation_fault = decoder.diagnostics();
            decoder.testingSetFaultInjection(.{ .reallocation_after = failure_index });
            if (decoder.openFace(fixture.bytes, 0)) |opened| {
                var tolerated = opened;
                tolerated.deinit();
            } else |err| {
                try std.testing.expectEqual(error.OutOfMemory, err);
                fatal_reallocation_seen = true;
            }
            decoder.testingSetFaultInjection(.{});
            const after_reallocation_fault = decoder.diagnostics();
            try std.testing.expectEqual(baseline, after_reallocation_fault.current_bytes);
            try std.testing.expectEqual(
                before_reallocation_fault.reallocation_failure_count + 1,
                after_reallocation_fault.reallocation_failure_count,
            );
        }
    }
    try std.testing.expect(total_reallocations > 0);
    try std.testing.expect(fatal_reallocation_seen);

    var recovered = try decoder.openFace(fixtures[3].bytes, 0);
    const recovered_info = try recovered.info();
    try std.testing.expect(recovered_info.glyph_count > 0);
    recovered.deinit();
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
}

test "R4FONT rejects a cyclic composite glyph without poisoning its face" {
    const bytes = try std.testing.allocator.dupe(u8, fixtures[0].bytes);
    defer std.testing.allocator.free(bytes);
    const cyclic_glyph = try makeCyclicComposite(bytes);

    var decoder = try r4font.Decoder.init(std.testing.allocator, r4font.default_allocation_limit);
    defer decoder.deinit();
    const baseline = decoder.diagnostics().current_bytes;
    var face = try decoder.openFace(bytes, 0);
    try std.testing.expectError(error.InvalidGlyph, face.glyphMetrics(cyclic_glyph));
    var pixels: [r4font.max_raster_dimension * r4font.max_raster_dimension]u8 = undefined;
    try std.testing.expectError(error.InvalidGlyph, face.rasterize(cyclic_glyph, 32, pixels[0..]));
    _ = try face.glyphMetrics(0);
    face.deinit();
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
}

fn expectInvalidWithoutState(decoder: *r4font.Decoder, baseline: usize, bytes: []const u8) !void {
    try expectErrorWithoutState(decoder, baseline, bytes, error.InvalidFont);
}

fn expectErrorWithoutState(decoder: *r4font.Decoder, baseline: usize, bytes: []const u8, expected: r4font.Error) !void {
    try std.testing.expectError(expected, decoder.openFace(bytes, 0));
    try std.testing.expectEqual(baseline, decoder.diagnostics().current_bytes);
}

fn allocationFailureRun(allocator: std.mem.Allocator) !void {
    var context = try r4font.Decoder.init(allocator, r4font.default_allocation_limit);
    defer context.deinit();
    var face = try context.openFace(fixtures[3].bytes, 0);
    defer face.deinit();
    const glyph = face.glyphIndex(0x6c34);
    if (glyph == 0) return error.InvalidGlyph;
    _ = try face.glyphMetrics(glyph);
    var pixels: [r4font.max_raster_dimension * r4font.max_raster_dimension]u8 = undefined;
    _ = try face.rasterize(glyph, 32, pixels[0..]);
}

fn buildTestCollection(allocator: std.mem.Allocator, sfnt: []const u8) ![]u8 {
    if (sfnt.len < 12) return error.InvalidFont;
    const header_bytes: usize = 20;
    const second_offset = std.mem.alignForward(usize, header_bytes + sfnt.len, 4);
    const total = std.mem.alignForward(usize, second_offset + sfnt.len, 4);
    const output = try allocator.alloc(u8, total);
    errdefer allocator.free(output);
    @memset(output, 0);
    @memcpy(output[header_bytes .. header_bytes + sfnt.len], sfnt);
    @memcpy(output[second_offset .. second_offset + sfnt.len], sfnt);
    @memcpy(output[0..4], "ttcf");
    writeBe32(output, 4, 0x00010000);
    writeBe32(output, 8, 2);
    writeBe32(output, 12, @intCast(header_bytes));
    writeBe32(output, 16, @intCast(second_offset));
    try relocateSfntDirectory(output[header_bytes..], header_bytes);
    try relocateSfntDirectory(output[second_offset..], second_offset);
    return output;
}

fn relocateSfntDirectory(sfnt: []u8, base: usize) !void {
    if (sfnt.len < 12) return error.InvalidFont;
    const table_count = readBe16(sfnt, 4);
    if (@as(usize, table_count) > (sfnt.len - 12) / 16) return error.InvalidFont;
    var index: usize = 0;
    while (index < table_count) : (index += 1) {
        const field = 12 + index * 16 + 8;
        const old_offset = readBe32(sfnt, field);
        const relocated = std.math.add(u32, old_offset, @intCast(base)) catch return error.TooLarge;
        writeBe32(sfnt, field, relocated);
    }
}

fn makeCyclicComposite(sfnt: []u8) !u32 {
    const head = findSfntTable(sfnt, "head") orelse return error.InvalidFont;
    const loca = findSfntTable(sfnt, "loca") orelse return error.InvalidFont;
    const glyf = findSfntTable(sfnt, "glyf") orelse return error.InvalidFont;
    const maxp = findSfntTable(sfnt, "maxp") orelse return error.InvalidFont;
    if (head.length < 52 or maxp.length < 6) return error.InvalidFont;
    const glyph_count = readBe16(sfnt, maxp.offset + 4);
    const long_locations = readBe16(sfnt, head.offset + 50) == 1;
    const entry_size: usize = if (long_locations) 4 else 2;
    if (loca.length < (@as(usize, glyph_count) + 1) * entry_size) return error.InvalidFont;

    var glyph_index: u32 = 1;
    while (glyph_index < glyph_count) : (glyph_index += 1) {
        const start = readGlyphLocation(sfnt, loca.offset, glyph_index, long_locations);
        const end = readGlyphLocation(sfnt, loca.offset, glyph_index + 1, long_locations);
        if (end < start or end - start < 18 or end > glyf.length) continue;
        const offset = glyf.offset + start;
        writeBe16(sfnt, offset, 0xFFFF);
        @memset(sfnt[offset + 2 .. offset + 10], 0);
        writeBe16(sfnt, offset + 10, 0x0003);
        writeBe16(sfnt, offset + 12, @intCast(glyph_index));
        @memset(sfnt[offset + 14 .. offset + 18], 0);
        return glyph_index;
    }
    return error.InvalidFont;
}

fn setStyleFlags(sfnt: []u8, bold: bool, italic: bool) !void {
    const os2 = findSfntTable(sfnt, "OS/2") orelse return error.InvalidFont;
    if (os2.length < 64) return error.InvalidFont;
    const selection_offset = os2.offset + 62;
    var selection = readBe16(sfnt, selection_offset);
    selection &= ~@as(u16, 0x0261);
    if (bold) selection |= 0x0020;
    if (italic) selection |= 0x0001;
    writeBe16(sfnt, selection_offset, selection);
}

const SfntTable = struct {
    offset: usize,
    length: usize,
};

fn findSfntTable(sfnt: []const u8, tag: *const [4]u8) ?SfntTable {
    if (sfnt.len < 12) return null;
    const table_count = readBe16(sfnt, 4);
    if (@as(usize, table_count) > (sfnt.len - 12) / 16) return null;
    var index: usize = 0;
    while (index < table_count) : (index += 1) {
        const record = 12 + index * 16;
        if (!std.mem.eql(u8, sfnt[record .. record + 4], tag)) continue;
        const offset: usize = readBe32(sfnt, record + 8);
        const length: usize = readBe32(sfnt, record + 12);
        if (offset > sfnt.len or length > sfnt.len - offset) return null;
        return .{ .offset = offset, .length = length };
    }
    return null;
}

fn readGlyphLocation(sfnt: []const u8, loca_offset: usize, glyph_index: u32, long_locations: bool) usize {
    const entry = loca_offset + @as(usize, glyph_index) * (if (long_locations) @as(usize, 4) else 2);
    return if (long_locations) @as(usize, readBe32(sfnt, entry)) else @as(usize, readBe16(sfnt, entry)) * 2;
}

fn readBe16(bytes: []const u8, offset: usize) u16 {
    return (@as(u16, bytes[offset]) << 8) | bytes[offset + 1];
}

fn readBe32(bytes: []const u8, offset: usize) u32 {
    return (@as(u32, bytes[offset]) << 24) |
        (@as(u32, bytes[offset + 1]) << 16) |
        (@as(u32, bytes[offset + 2]) << 8) |
        bytes[offset + 3];
}

fn writeBe32(bytes: []u8, offset: usize, value: u32) void {
    bytes[offset] = @truncate(value >> 24);
    bytes[offset + 1] = @truncate(value >> 16);
    bytes[offset + 2] = @truncate(value >> 8);
    bytes[offset + 3] = @truncate(value);
}

fn writeBe16(bytes: []u8, offset: usize, value: u16) void {
    bytes[offset] = @truncate(value >> 8);
    bytes[offset + 1] = @truncate(value);
}
