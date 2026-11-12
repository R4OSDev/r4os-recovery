// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! New schema/envelope boundaries only. Original vendor/CPU/compiler oracles
//! remain independent; these synthetic bytes never authorize GPU execution.
const std = @import("std");
const t = std.testing;
const cache = @import("cache_codec");
const scalar = cache.ScalarSchemaCodec;

test "cache schema explicit endian signed fields zero padding and transients" {
    const Native = extern struct { a: u32, b: i64, c: u32, transient: u32 };
    const fields = [_]scalar.Field{
        .{ .native_offset = 0, .wire_offset = 0, .width = 4 },
        .{ .native_offset = 8, .wire_offset = 4, .width = 8 },
        .{ .native_offset = 16, .wire_offset = 12, .width = 4 },
        .{ .native_offset = 20, .wire_offset = 16, .width = 4, .flags = scalar.zero },
    };
    const schema: scalar.Schema = .{ .native_bytes = 24, .wire_bytes = 24, .fields = &fields };
    var source: Native = undefined;
    @memset(std.mem.asBytes(&source), 0xa5);
    source.a = 0x01020304;
    source.b = -2;
    source.c = 0xffeeddcc;
    source.transient = 123;
    var wire: [32]u8 = @splat(0xcc);
    try schema.encode(std.mem.asBytes(&source), &wire);
    const expected = [_]u8{ 4, 3, 2, 1, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xcc, 0xdd, 0xee, 0xff, 0, 0, 0, 0, 0, 0, 0, 0 };
    try t.expectEqualSlices(u8, &expected, wire[0..24]);
    for (wire[24..]) |value| try t.expectEqual(@as(u8, 0xcc), value);
    var decoded: Native = undefined;
    try schema.decode(wire[0..24], std.mem.asBytes(&decoded));
    try t.expectEqual(@as(i64, -2), decoded.b);
    try t.expectEqual(source.a, decoded.a);
    try t.expectEqual(source.c, decoded.c);
    try t.expectEqual(@as(u32, 0), decoded.transient);
    for (std.mem.asBytes(&decoded)[4..8]) |value| try t.expectEqual(@as(u8, 0), value);
    const before = decoded;
    wire[23] = 1;
    try t.expectError(error.NonCanonical, schema.decode(wire[0..24], std.mem.asBytes(&decoded)));
    try t.expectEqualDeep(before, decoded);
    wire[23] = 0;
    wire[16] = 1;
    try t.expectError(error.NonCanonical, schema.decode(wire[0..24], std.mem.asBytes(&decoded)));
    try t.expectEqualDeep(before, decoded);
}

test "cache schema invalid layout capacity aliases and descriptor loans are atomic" {
    var field = [_]scalar.Field{.{ .native_offset = 0, .wire_offset = 0, .width = 8 }};
    const schema: scalar.Schema = .{ .native_bytes = 8, .wire_bytes = 8, .fields = &field };
    const source = [_]u8{0} ** 8;
    var output: [32]u8 = @splat(0xcc);
    try t.expectError(error.Capacity, schema.encode(&source, output[0..7]));
    try t.expectError(error.InvalidLength, schema.encode(source[0..7], &output));
    for (output) |byte| try t.expectEqual(@as(u8, 0xcc), byte);
    for ([_]scalar.Field{
        .{ .native_offset = 0, .wire_offset = 0, .width = 3 },
        .{ .native_offset = 0, .wire_offset = 0, .width = 8, .flags = 2 },
        .{ .native_offset = 0, .wire_offset = 0, .width = 8, .reserved = 1 },
        .{ .native_offset = 1, .wire_offset = 0, .width = 8 },
        .{ .native_offset = 0, .wire_offset = 1, .width = 8 },
    }) |invalid| {
        field[0] = invalid;
        try t.expectError(error.InvalidSchema, schema.encode(&source, &output));
        for (output) |byte| try t.expectEqual(@as(u8, 0xcc), byte);
    }
    field[0] = .{ .native_offset = 0, .wire_offset = 0, .width = 8 };
    const descriptor_before = field;
    try t.expectError(error.Overlap, schema.encode(&source, std.mem.asBytes(&field)));
    try t.expectEqualDeep(descriptor_before, field);
    try t.expectError(error.Overlap, schema.decode(&source, std.mem.asBytes(&field)));
    try t.expectEqualDeep(descriptor_before, field);
    try t.expectError(error.Overlap, schema.encode(output[0..8], &output));
    const overlapping = [_]scalar.Field{ .{ .native_offset = 0, .wire_offset = 0, .width = 8 }, .{ .native_offset = 4, .wire_offset = 8, .width = 8 } };
    try t.expectError(error.InvalidSchema, (scalar.Schema{ .native_bytes = 16, .wire_bytes = 16, .fields = &overlapping }).validate());
    try t.expect(!cache.validSpan(std.math.maxInt(usize) - 4, 8));
    try t.expect(cache.overlaps(std.math.maxInt(usize) - 4, 8, 1, 1));
    try t.expect(!cache.overlaps(0, 0, 1, 1));
}

const Key = extern struct { version: u32 = 1, size: u32 = 16, key: u64 = 42 };
const Metadata = extern struct { version: u32 = 1, size: u32 = 24, code_bytes: u64 = 8, transient: u64 = 123 };
const Rule = struct {
    pub const magic = "R4TEST01".*;
    pub const format_revision: u32 = 1;
    pub const compiler_revision: u32 = 1;
    pub const max_payload_bytes = 64;
    pub const transient_fields: []const []const u8 = &.{"transient"};
    pub fn compilerIdentity() [32]u8 {
        return @splat(3);
    }
    pub fn valid_key(value: *const Key) bool {
        return value.version == 1 and value.size == 16 and value.key == 42;
    }
    pub fn valid_metadata(_: *const Key, value: *const Metadata, length: usize) bool {
        return value.version == 1 and value.size == 24 and value.code_bytes == length and length == 8;
    }
};
const Envelope = cache.CanonicalCacheEnvelope(Key, Metadata, Rule);
test "cache envelope exact independent digest and normalized native metadata" {
    const key: Key = .{};
    const metadata: Metadata = .{};
    const payload = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7 };
    var blob: [256]u8 = @splat(0xcc);
    var written: u64 = 999;
    try t.expectEqual(@as(usize, 144), try Envelope.encode(&key, &metadata, &payload, payload.len, &blob, blob.len, &written));
    try t.expectEqual(@as(u64, 144), written);
    try t.expectEqualStrings("R4TEST01", blob[0..8]);
    try t.expectEqual(@as(u64, 144), std.mem.readInt(u64, blob[16..24], .little));
    // Explicit Python struct/hashlib fixture, independent of these owners.
    const expected_digest = [_]u8{ 0xbe, 0x8b, 0x2e, 0xd9, 0xcf, 0x1d, 0xb2, 0x78, 0xf0, 0xdd, 0xb8, 0x84, 0xe6, 0x08, 0xce, 0x2e, 0x24, 0xd2, 0x43, 0xf2, 0xc8, 0xa5, 0xdb, 0x2b, 0x68, 0x5d, 0x77, 0x6f, 0xaa, 0xcb, 0x14, 0x00 };
    try t.expectEqualSlices(u8, &expected_digest, blob[104..136]);
    for (blob[144..]) |value| try t.expectEqual(@as(u8, 0xcc), value);
    var result: Metadata = .{};
    var code: [16]u8 = @splat(0xdd);
    try t.expectEqual(@as(usize, 8), try Envelope.decode(&key, &blob, written, &result, &code, code.len));
    try t.expectEqual(@as(u64, 0), result.transient);
    try t.expectEqualSlices(u8, &payload, code[0..8]);
    for (code[8..]) |value| try t.expectEqual(@as(u8, 0xdd), value);
}
test "cache envelope wrong identity schema corrupt payload and publish aliases preserve state" {
    const key: Key = .{};
    const metadata: Metadata = .{};
    const payload = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7 };
    var blob: [256]u8 align(8) = @splat(0xcc);
    var written: u64 = 999;
    try t.expectError(error.Capacity, Envelope.encode(&key, &metadata, &payload, payload.len, &blob, 143, &written));
    try t.expectEqual(@as(u64, 999), written);
    for (blob) |value| try t.expectEqual(@as(u8, 0xcc), value);
    try t.expectError(error.Overlap, Envelope.encode(&key, &metadata, &payload, payload.len, &blob, blob.len, @ptrCast(@alignCast(&blob))));
    for (blob) |value| try t.expectEqual(@as(u8, 0xcc), value);
    _ = try Envelope.encode(&key, &metadata, &payload, payload.len, &blob, blob.len, &written);
    var result: Metadata = .{};
    var code: [16]u8 = @splat(0xdd);
    const before = result;
    for ([_]struct { offset: usize, expected: cache.Error }{
        .{ .offset = 0, .expected = error.UnknownFormat },
        .{ .offset = 8, .expected = error.VersionMismatch },
        .{ .offset = 24, .expected = error.InvalidLength },
        .{ .offset = 32, .expected = error.IdentityMismatch },
        .{ .offset = 104, .expected = error.IntegrityMismatch },
        .{ .offset = 143, .expected = error.IntegrityMismatch },
    }) |invalid| {
        blob[invalid.offset] ^= 1;
        try t.expectError(invalid.expected, Envelope.decode(&key, &blob, written, &result, &code, code.len));
        blob[invalid.offset] ^= 1;
        try t.expectEqualDeep(before, result);
        for (code) |value| try t.expectEqual(@as(u8, 0xdd), value);
    }
    try t.expectError(error.Capacity, Envelope.decode(&key, &blob, written, &result, &code, 7));
    const saved = blob;
    try t.expectError(error.Overlap, Envelope.decode(&key, &blob, written, &result, &blob, blob.len));
    try t.expectEqualSlices(u8, &saved, &blob);
    try t.expectError(error.InvalidLength, Envelope.requiredBytes(0));
    try t.expectError(error.InvalidLength, Envelope.requiredBytes(65));
}
