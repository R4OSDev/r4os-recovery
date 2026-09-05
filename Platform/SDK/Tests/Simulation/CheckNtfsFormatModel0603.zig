// Host model tests for the shared NTFS structure core (0.60.3).
//
// Pure property tests without fixture images: runlist encode/decode
// roundtrips with sign-extension edges, fixup install/apply roundtrips and
// torn-write detection, boot sector decoding, index entry iteration and
// $UpCase collation.

const std = @import("std");
const ntfs = @import("ntfs_format");

fn buildUpcase(buf: []u8) void {
    var unit: usize = 0;
    while (unit < ntfs.UPCASE_ENTRIES) : (unit += 1) {
        var mapped: u16 = @intCast(unit);
        if (mapped >= 'a' and mapped <= 'z') mapped -= 32;
        std.mem.writeInt(u16, buf[unit * 2 ..][0..2], mapped, .little);
    }
}

test "runlist roundtrip with mixed deltas and sparse runs" {
    const cases = [_]struct { len: u64, delta: ?i64 }{
        .{ .len = 1, .delta = 100 },
        .{ .len = 255, .delta = -1 },
        .{ .len = 256, .delta = 127 },
        .{ .len = 1000, .delta = -128 },
        .{ .len = 7, .delta = 128 },
        .{ .len = 3, .delta = -129 },
        .{ .len = 42, .delta = null },
        .{ .len = 65536, .delta = 0x7FFFFF },
        .{ .len = 9, .delta = -0x800000 },
        .{ .len = 5, .delta = 0x123456789A },
        .{ .len = 1, .delta = -0x123456789A },
    };

    var mapping: [256]u8 = undefined;
    var offset: usize = 0;
    var expected_lcn: i64 = 0;
    var expected: [cases.len]ntfs.Run = undefined;
    for (cases, 0..) |case, i| {
        const written = ntfs.encodeRun(mapping[offset..], case.len, case.delta) orelse return error.EncodeFailed;
        offset += written;
        if (case.delta) |delta| {
            expected_lcn += delta;
            try std.testing.expect(expected_lcn >= 0);
            expected[i] = .{ .length_clusters = case.len, .lcn = @intCast(expected_lcn) };
        } else {
            expected[i] = .{ .length_clusters = case.len, .lcn = null };
        }
    }
    mapping[offset] = 0;
    offset += 1;

    var iterator = ntfs.RunlistIterator.init(mapping[0..offset]);
    for (expected) |want| {
        const got = iterator.next() orelse return error.DecodeEnded;
        try std.testing.expectEqual(want.length_clusters, got.length_clusters);
        if (want.lcn) |lcn| {
            try std.testing.expectEqual(lcn, got.lcn.?);
        } else {
            try std.testing.expect(got.lcn == null);
        }
    }
    try std.testing.expect(iterator.next() == null);
    try std.testing.expect(!iterator.hadError());
}

test "runlist encoder never sets the top bit of the highest length byte" {
    // 128 clusters must use two length bytes (0x80 0x00), Windows style.
    var out: [16]u8 = undefined;
    const written = ntfs.encodeRun(out[0..], 128, 100) orelse return error.EncodeFailed;
    try std.testing.expectEqual(@as(usize, 4), written);
    try std.testing.expectEqual(@as(u8, 0x12), out[0]);
    try std.testing.expectEqual(@as(u8, 0x80), out[1]);
    try std.testing.expectEqual(@as(u8, 0x00), out[2]);

    // 0x8000 clusters need three length bytes.
    const written2 = ntfs.encodeRun(out[0..], 0x8000, null) orelse return error.EncodeFailed;
    try std.testing.expectEqual(@as(usize, 4), written2);
    try std.testing.expectEqual(@as(u8, 0x03), out[0]);
}

test "runlist decoder stops on malformed input without panicking" {
    // Header claims more bytes than available.
    var truncated = [_]u8{ 0x31, 0x05 };
    var iterator = ntfs.RunlistIterator.init(truncated[0..]);
    try std.testing.expect(iterator.next() == null);
    try std.testing.expect(iterator.hadError());

    // Zero run length is invalid.
    var zero_length = [_]u8{ 0x11, 0x00, 0x01, 0x00 };
    iterator = ntfs.RunlistIterator.init(zero_length[0..]);
    try std.testing.expect(iterator.next() == null);
    try std.testing.expect(iterator.hadError());

    // Negative absolute LCN is invalid.
    var negative = [_]u8{ 0x11, 0x01, 0x80, 0x00 };
    iterator = ntfs.RunlistIterator.init(negative[0..]);
    try std.testing.expect(iterator.next() == null);
    try std.testing.expect(iterator.hadError());
}

fn buildRecordSkeleton(buf: []u8, usa_ofs: u16, usa_count: u16) void {
    @memset(buf, 0xAB);
    std.mem.writeInt(u32, buf[0..4], ntfs.FILE_MAGIC, .little);
    std.mem.writeInt(u16, buf[4..6], usa_ofs, .little);
    std.mem.writeInt(u16, buf[6..8], usa_count, .little);
}

test "fixup install and apply roundtrip over three sectors" {
    var record: [1536]u8 = undefined;
    buildRecordSkeleton(record[0..], 0x30, 4);
    var original: [1536]u8 = undefined;
    // Distinct end-of-sector words that the fixups must preserve.
    std.mem.writeInt(u16, record[510..512], 0x1111, .little);
    std.mem.writeInt(u16, record[1022..1024], 0x2222, .little);
    std.mem.writeInt(u16, record[1534..1536], 0x3333, .little);
    @memcpy(original[0..], record[0..]);

    try std.testing.expectEqual(ntfs.FixupError.ok, ntfs.installFixups(record[0..], 7));
    const usn = std.mem.readInt(u16, record[0x30..0x32], .little);
    try std.testing.expectEqual(@as(u16, 8), usn);
    try std.testing.expectEqual(usn, std.mem.readInt(u16, record[510..512], .little));
    try std.testing.expectEqual(usn, std.mem.readInt(u16, record[1022..1024], .little));
    try std.testing.expectEqual(usn, std.mem.readInt(u16, record[1534..1536], .little));

    try std.testing.expectEqual(ntfs.FixupError.ok, ntfs.applyFixups(record[0..]));
    // Content identical except the stored USN/array area itself.
    try std.testing.expectEqualSlices(u8, original[0..0x30], record[0..0x30]);
    try std.testing.expectEqualSlices(u8, original[0x38..], record[0x38..]);
}

test "fixup USN wraparound skips zero and 0xFFFF" {
    var record: [512]u8 = undefined;
    buildRecordSkeleton(record[0..], 0x30, 2);
    try std.testing.expectEqual(ntfs.FixupError.ok, ntfs.installFixups(record[0..], 0xFFFE));
    try std.testing.expectEqual(@as(u16, 1), std.mem.readInt(u16, record[0x30..0x32], .little));
}

test "fixup apply detects a torn sector" {
    var record: [1024]u8 = undefined;
    buildRecordSkeleton(record[0..], 0x30, 3);
    try std.testing.expectEqual(ntfs.FixupError.ok, ntfs.installFixups(record[0..], 1));
    // Simulate a torn write: second sector still carries an old end word.
    std.mem.writeInt(u16, record[1022..1024], 0xDEAD, .little);
    try std.testing.expectEqual(ntfs.FixupError.usn_mismatch, ntfs.applyFixups(record[0..]));
}

fn buildBootSector(buf: *[512]u8) void {
    @memset(buf, 0);
    @memcpy(buf[3..11], "NTFS    ");
    std.mem.writeInt(u16, buf[0x0B..0x0D], 512, .little);
    buf[0x0D] = 8; // 4 KB clusters
    buf[0x15] = 0xF8;
    std.mem.writeInt(u64, buf[0x28..0x30], 65536, .little);
    std.mem.writeInt(u64, buf[0x30..0x38], 4, .little);
    std.mem.writeInt(u64, buf[0x38..0x40], 500, .little);
    buf[0x40] = 0xF6; // -10 => 1024 byte records
    buf[0x44] = 0x01; // one cluster => 4096 byte index blocks
    std.mem.writeInt(u64, buf[0x48..0x50], 0x1122334455667788, .little);
    buf[510] = 0x55;
    buf[511] = 0xAA;
}

test "boot sector decode including size byte encodings" {
    var sector: [512]u8 = undefined;
    buildBootSector(&sector);
    var boot: ntfs.BootSector = undefined;
    try std.testing.expectEqual(ntfs.BootSector.ParseError.ok, ntfs.BootSector.parse(sector[0..], &boot));
    try std.testing.expectEqual(@as(u32, 4096), boot.cluster_bytes);
    try std.testing.expectEqual(@as(u32, 1024), boot.file_record_bytes);
    try std.testing.expectEqual(@as(u32, 4096), boot.index_block_bytes);
    try std.testing.expectEqual(@as(u64, 4), boot.mft_lcn);

    sector[3] = 'X';
    try std.testing.expectEqual(ntfs.BootSector.ParseError.bad_oem, ntfs.BootSector.parse(sector[0..], &boot));
    buildBootSector(&sector);
    sector[510] = 0;
    try std.testing.expectEqual(ntfs.BootSector.ParseError.bad_signature, ntfs.BootSector.parse(sector[0..], &boot));
    buildBootSector(&sector);
    sector[0x0D] = 3; // not a power of two
    try std.testing.expectEqual(ntfs.BootSector.ParseError.bad_cluster_size, ntfs.BootSector.parse(sector[0..], &boot));
    buildBootSector(&sector);
    sector[0x0D] = 0xF4; // large-cluster encoding: 2^4 = 16 sectors
    try std.testing.expectEqual(ntfs.BootSector.ParseError.ok, ntfs.BootSector.parse(sector[0..], &boot));
    try std.testing.expectEqual(@as(u32, 8192), boot.cluster_bytes);
}

test "file reference splits record and sequence" {
    const reference = ntfs.FileReference.parse(0x00050000_00000024);
    try std.testing.expectEqual(@as(u64, 0x24), reference.record);
    try std.testing.expectEqual(@as(u16, 5), reference.sequence);
    try std.testing.expectEqual(@as(u64, 0x00050000_00000024), reference.pack());
}

fn writeFileNameKey(buf: []u8, name_ascii: []const u8, namespace: u8) usize {
    @memset(buf[0..0x42], 0);
    buf[0x40] = @intCast(name_ascii.len);
    buf[0x41] = namespace;
    for (name_ascii, 0..) |c, i| {
        buf[0x42 + i * 2] = c;
        buf[0x42 + i * 2 + 1] = 0;
    }
    return 0x42 + name_ascii.len * 2;
}

test "index entry iterator handles keys, sub-nodes and END" {
    var entries: [512]u8 = undefined;
    @memset(entries[0..], 0);
    var offset: usize = 0;

    // Entry 1: name "ALPHA", no sub-node.
    var key_buf: [128]u8 = undefined;
    const key_len = writeFileNameKey(key_buf[0..], "ALPHA", ntfs.NAMESPACE_WIN32_DOS);
    var entry_len: usize = std.mem.alignForward(usize, 0x10 + key_len, 8);
    std.mem.writeInt(u64, entries[offset..][0..8], 0x00010000_00000030, .little);
    std.mem.writeInt(u16, entries[offset + 8 ..][0..2], @intCast(entry_len), .little);
    std.mem.writeInt(u16, entries[offset + 10 ..][0..2], @intCast(key_len), .little);
    std.mem.writeInt(u16, entries[offset + 12 ..][0..2], 0, .little);
    @memcpy(entries[offset + 0x10 .. offset + 0x10 + key_len], key_buf[0..key_len]);
    offset += entry_len;

    // END entry with a sub-node VCN.
    entry_len = 0x18;
    std.mem.writeInt(u16, entries[offset + 8 ..][0..2], @intCast(entry_len), .little);
    std.mem.writeInt(u16, entries[offset + 10 ..][0..2], 0, .little);
    std.mem.writeInt(u16, entries[offset + 12 ..][0..2], ntfs.INDEX_ENTRY_END | ntfs.INDEX_ENTRY_NODE, .little);
    std.mem.writeInt(u64, entries[offset + entry_len - 8 ..][0..8], 42, .little);
    offset += entry_len;

    var iterator = ntfs.IndexEntryIterator.init(entries[0..offset]);
    const first = iterator.next() orelse return error.MissingEntry;
    try std.testing.expect(!first.isEnd());
    try std.testing.expect(!first.hasSubNode());
    const name = first.fileName() orelse return error.MissingKey;
    try std.testing.expectEqual(@as(u8, 5), name.name_length);
    const end = iterator.next() orelse return error.MissingEnd;
    try std.testing.expect(end.isEnd());
    try std.testing.expectEqual(@as(u64, 42), end.sub_node_vcn.?);
    try std.testing.expect(iterator.next() == null);
}

test "upcase collation is case-insensitive with prefix-first order" {
    const allocator = std.testing.allocator;
    const upcase = try allocator.alloc(u8, ntfs.UPCASE_BYTES);
    defer allocator.free(upcase);
    buildUpcase(upcase);

    var a_buf: [32]u8 = undefined;
    var b_buf: [32]u8 = undefined;
    const a_len = ntfs.asciiToUtf16("alpha", a_buf[0..]).?;
    const b_len = ntfs.asciiToUtf16("ALPHB", b_buf[0..]).?;
    try std.testing.expectEqual(std.math.Order.lt, ntfs.compareFileNames(upcase, a_buf[0..a_len], b_buf[0..b_len]));

    const c_len = ntfs.asciiToUtf16("ALPHA", b_buf[0..]).?;
    try std.testing.expectEqual(std.math.Order.eq, ntfs.compareFileNames(upcase, a_buf[0..a_len], b_buf[0..c_len]));

    const d_len = ntfs.asciiToUtf16("ALPH", b_buf[0..]).?;
    try std.testing.expectEqual(std.math.Order.gt, ntfs.compareFileNames(upcase, a_buf[0..a_len], b_buf[0..d_len]));

    try std.testing.expect(ntfs.asciiMatchesUtf16(upcase, "alpha", b_buf[0..c_len]));
    try std.testing.expect(!ntfs.asciiMatchesUtf16(upcase, "alphx", b_buf[0..c_len]));

    var ascii_out: [8]u8 = undefined;
    const ascii_len = ntfs.utf16ToAscii(b_buf[0..c_len], ascii_out[0..]) orelse return error.AsciiFailed;
    try std.testing.expectEqualSlices(u8, "ALPHA", ascii_out[0..ascii_len]);
}

test "attribute list iterator reads typed entries" {
    var value: [64]u8 = undefined;
    @memset(value[0..], 0);
    std.mem.writeInt(u32, value[0..4], @intFromEnum(ntfs.AttrType.data), .little);
    std.mem.writeInt(u16, value[4..6], 0x20, .little);
    value[6] = 0; // no name
    value[7] = 0x1A;
    std.mem.writeInt(u64, value[8..16], 3, .little);
    std.mem.writeInt(u64, value[16..24], 0x0002000000000011, .little);
    std.mem.writeInt(u16, value[24..26], 9, .little);

    var iterator = ntfs.AttributeListIterator.init(value[0..0x20]);
    const entry = iterator.next() orelse return error.MissingEntry;
    try std.testing.expectEqual(ntfs.AttrType.data, entry.typed());
    try std.testing.expectEqual(@as(u64, 3), entry.lowest_vcn);
    try std.testing.expectEqual(@as(u64, 0x11), entry.mft_reference.record);
    try std.testing.expectEqual(@as(u16, 2), entry.mft_reference.sequence);
    try std.testing.expect(iterator.next() == null);
}
