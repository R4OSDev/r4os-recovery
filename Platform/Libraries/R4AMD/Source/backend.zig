// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const c = @import("r4l_contract");
const copy = @import("copy.zig");
const pm4 = @import("pm4.zig");
pub const mediaCaps = @import("media.zig").Provider(c).caps;

pub fn encodePm4Frame(request: *const c.R4AmdPm4Frame, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    if (!disjoint(c.R4AmdPm4Frame, request, commands, capacity, written)) return c.status_invalid;
    if (request.version != 1 or request.size != @sizeOf(c.R4AmdPm4Frame) or request.engine > 1 or request.flags & ~@as(u32, 1) != 0 or
        request.reserved0 != 0 or request.reserved1 != 0) return c.status_invalid;
    const count = pm4.encodeFrame(commands[0..capacity], .{ .engine = @enumFromInt(request.engine), .ib = request.indirect_address,
        .words = request.command_dwords, .fence = request.fence_address, .sequence = request.fence_sequence,
        .eop_scratch = request.eop_scratch, .interrupt = request.flags & 1 != 0 }) catch return c.status_invalid;
    written.* = @intCast(count); return c.status_ok;
}

test "AMD PM4 ABI preserves failure outputs, packet bounds, reserved fields and disjoint ownership" {
    const t = std.testing;
    var request: c.R4AmdPm4Frame = .{ .version = 1, .size = @sizeOf(c.R4AmdPm4Frame), .engine = 0, .flags = 1,
        .indirect_address = 0x8000080000, .fence_address = 0x120010100, .eop_scratch = 0x120075000,
        .fence_sequence = 0x123400000001, .command_dwords = 16, .reserved0 = 0, .reserved1 = 0 };
    var words: [48]u32 = @splat(0xdeadbeef); var written: u32 = 77;
    try t.expectEqual(c.status_ok, encodePm4Frame(&request, &words, words.len, &written));
    try t.expectEqual(@as(u32, 48), written); try pm4.packetBoundaries(&words);
    try t.expectEqual(@as(u32, 0xff), words[16]); // GC9 COHER_SIZE_HI: eight implemented bits
    const original = words; const count = written;
    try t.expectEqual(c.status_invalid, encodePm4Frame(&request, &words, 47, &written));
    try t.expectEqual(c.status_invalid, encodePm4Frame(&request, &words, 48, &words[0]));
    inline for (.{ "version", "size", "engine", "flags", "reserved0", "reserved1" }) |field| {
        const saved = @field(request, field); @field(request, field) = 0xffffffff;
        try t.expectEqual(c.status_invalid, encodePm4Frame(&request, &words, 48, &written)); @field(request, field) = saved;
    }
    try t.expectEqualDeep(original, words); try t.expectEqual(count, written);
    const input = request;
    try t.expectEqual(c.status_invalid, encodePm4Frame(&request, @ptrCast(&request), 1, &written)); try t.expectEqualDeep(input, request);
    request.engine = 1; request.eop_scratch = 0;
    try t.expectEqual(c.status_ok, encodePm4Frame(&request, &words, 32, &written));
    try t.expectEqual(@as(u32, 32), written); try pm4.packetBoundaries(words[0..32]);
    try t.expectEqual(@as(u32, 0xff), words[12]); // Same range encoding on MEC
    request.fence_sequence = 0;
    try t.expectEqual(c.status_invalid, encodePm4Frame(&request, &words, 48, &written));
}

pub fn negotiate(profile: *const c.R4AmdDeviceProfile, output: *c.R4AmdFeatures) callconv(.c) i32 {
    if (@intFromPtr(profile) == 0 or @intFromPtr(output) == 0 or
        @intFromPtr(profile) % @alignOf(c.R4AmdDeviceProfile) != 0 or
        @intFromPtr(output) % @alignOf(c.R4AmdFeatures) != 0) return c.status_invalid;
    const input_end = std.math.add(usize, @intFromPtr(profile), @sizeOf(c.R4AmdDeviceProfile)) catch return c.status_invalid;
    const output_end = std.math.add(usize, @intFromPtr(output), @sizeOf(c.R4AmdFeatures)) catch return c.status_invalid;
    if (@intFromPtr(profile) < output_end and @intFromPtr(output) < input_end) return c.status_invalid;
    if (profile.version != c.profile_version or profile.size != @sizeOf(c.R4AmdDeviceProfile) or
        profile.flags != 0 or profile.reserved != 0 or profile.adapter_id == 0 or
        profile.device_generation == 0 or profile.reset_generation == 0) return c.status_invalid;
    if (profile.vendor_id != c.vendor_id or @import("asic.zig").Profiles(c).engines(profile.device_id, profile.gc_version, profile.sdma_version) == null or
        profile.command_abi != c.command_abi) return c.status_unsupported;
    // These are pure encoder operations. Actual device admission additionally
    // requires AMDGPU ring self-test and common backend capabilities.
    output.* = .{ .version = 1, .size = @sizeOf(c.R4AmdFeatures), .command_abi = c.command_abi,
        .features = c.feature_copy_linear | c.feature_copy_rows | c.feature_fill | c.feature_pm4, .gpu_address_bits = 48, .max_command_words = copy.max_words, .reserved0 = 0, .reserved1 = 0 };
    return c.status_ok;
}

test "AMD negotiation preserves failures and exposes only implemented SDMA and PM4 encoders" {
    const t = std.testing;
    var profile: c.R4AmdDeviceProfile = .{ .version = 1, .size = @sizeOf(c.R4AmdDeviceProfile),
        .vendor_id = c.vendor_id, .device_id = 0x15d8, .gc_version = c.gc_9_1_0, .sdma_version = c.sdma_4_1_0,
        .command_abi = c.command_abi, .flags = 0, .adapter_id = 7, .reserved = 0, .device_generation = 11, .reset_generation = 13 };
    var result = std.mem.zeroes(c.R4AmdFeatures);
    try t.expectEqual(c.status_ok, negotiate(&profile, &result));
    try t.expect(result.features == c.feature_copy_linear | c.feature_copy_rows | c.feature_fill | c.feature_pm4 and result.max_command_words == copy.max_words and result.gpu_address_bits == 48);
    const original = result;
    profile.gc_version = c.gc_9_2_2;
    try t.expectEqual(c.status_unsupported, negotiate(&profile, &result));
    try t.expectEqualDeep(original, result);
    profile.sdma_version = c.sdma_4_1_1;
    try t.expectEqual(c.status_ok, negotiate(&profile, &result));
    try t.expectEqualDeep(original, result);
    profile.gc_version = c.gc_9_1_0; profile.sdma_version = c.sdma_4_1_0;
    profile.vendor_id = 0x10de;
    try t.expectEqual(c.status_unsupported, negotiate(&profile, &result));
    try t.expectEqualDeep(original, result);
    profile.vendor_id = c.vendor_id; profile.command_abi += 1;
    try t.expectEqual(c.status_unsupported, negotiate(&profile, &result));
    try t.expectEqualDeep(original, result);
    profile.command_abi = c.command_abi; profile.reset_generation = 0;
    try t.expectEqual(c.status_invalid, negotiate(&profile, &result));
    try t.expectEqualDeep(original, result);
    profile.reset_generation = 13;
    const before_alias = profile;
    try t.expectEqual(c.status_invalid, negotiate(&profile, @ptrCast(&profile)));
    try t.expectEqualDeep(before_alias, profile);
}

fn disjoint(comptime T: type, request: *const T, commands: [*]u32, capacity: u32, written: *u32) bool {
    if (@intFromPtr(request) == 0 or @intFromPtr(commands) == 0 or @intFromPtr(written) == 0 or
        @intFromPtr(request) % @alignOf(T) != 0 or @intFromPtr(commands) & 3 != 0 or @intFromPtr(written) & 3 != 0 or capacity == 0 or capacity > copy.max_words) return false;
    const starts = [_]usize{ @intFromPtr(request), @intFromPtr(commands), @intFromPtr(written) };
    const sizes = [_]usize{ @sizeOf(T), @as(usize, capacity) * 4, 4 };
    var ends: [3]usize = undefined;
    for (starts, sizes, 0..) |start, size, i| ends[i] = std.math.add(usize, start, size) catch return false;
    for (0..3) |i| for (i + 1..3) |j| { if (starts[i] < ends[j] and starts[j] < ends[i]) return false; };
    return true;
}
pub fn encodeCopy(request: *const c.R4AmdCopy, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    if (!disjoint(c.R4AmdCopy, request, commands, capacity, written)) return c.status_invalid;
    if (request.version != 1 or request.size != @sizeOf(c.R4AmdCopy) or request.reserved != 0) return c.status_invalid;
    const count = copy.encodeCopy(commands[0..capacity], .{ .source = request.source, .target = request.target, .bytes = request.byte_length,
        .source_pitch = request.source_pitch, .target_pitch = request.target_pitch, .rows = request.row_count,
        .source_modifier = request.source_modifier, .target_modifier = request.target_modifier }) catch |err| return if (err == error.Unsupported) c.status_unsupported else c.status_invalid;
    written.* = @intCast(count); return c.status_ok;
}
pub fn encodeFill(request: *const c.R4AmdFill, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    if (!disjoint(c.R4AmdFill, request, commands, capacity, written)) return c.status_invalid;
    if (request.version != 1 or request.size != @sizeOf(c.R4AmdFill) or request.reserved != 0) return c.status_invalid;
    const count = copy.encodeFill(commands[0..capacity], .{ .target = request.target, .bytes = request.byte_length, .value = request.value }) catch return c.status_invalid;
    written.* = @intCast(count); return c.status_ok;
}

test "SDMA4 copies fills bounds overlap and ABI output transaction" {
    const t = std.testing;
    var words: [copy.max_words]u32 = @splat(0xcdcdcdcd);
    var request: c.R4AmdCopy = .{ .version = 1, .size = @sizeOf(c.R4AmdCopy), .source = 0x100000000,
        .target = 0x200000000, .byte_length = 4 * 1024 * 1024 + 3, .source_pitch = 0, .target_pitch = 0,
        .source_modifier = 0, .target_modifier = 0, .row_count = 1, .reserved = 0 };
    var written: u32 = 0;
    try t.expectEqual(c.status_ok, encodeCopy(&request, &words, words.len, &written));
    try t.expectEqual(@as(u32, 14), written);
    try t.expectEqual(c.status_ok, encodeCopy(&request, &words, 14, &written));
    try t.expectEqualSlices(u32, &.{ 1, 0x3fffff, 0, 0, 1, 0, 2, 1, 2, 0, 0x400000, 1, 0x400000, 2 }, words[0..written]);
    request.byte_length = 1919 * 4; request.row_count = 1080; request.source_pitch = 1920 * 4; request.target_pitch = 2048 * 4;
    try t.expectEqual(c.status_ok, encodeCopy(&request, &words, words.len, &written));
    try t.expectEqual(@as(u32, 13), written); try t.expectEqual(@as(u32, 0x40000401), words[0]);
    try t.expectEqual(@as(u32, 1919 << 13), words[4]); try t.expectEqual(@as(u32, 2047 << 13), words[9]);
    try t.expectEqual(@as(u32, (1079 << 16) | 1918), words[11]);
    const original = words; const original_written = written;
    request.target = request.source + 4;
    try t.expectEqual(c.status_invalid, encodeCopy(&request, &words, words.len, &written));
    try t.expectEqualDeep(original, words); try t.expectEqual(original_written, written);
    request.target = 0x200000000; request.source_modifier = 1;
    try t.expectEqual(c.status_unsupported, encodeCopy(&request, &words, words.len, &written));
    request.source_modifier = 0; request.row_count = 0;
    try t.expectEqual(c.status_invalid, encodeCopy(&request, &words, words.len, &written));
    request.row_count = 1080;
    try t.expectEqual(c.status_invalid, encodeCopy(&request, &words, 12, &written));
    try t.expectEqual(c.status_invalid, encodeCopy(&request, &words, words.len, &words[0]));
    try t.expectEqualDeep(original, words);
    const input = request;
    try t.expectEqual(c.status_invalid, encodeCopy(&request, @ptrCast(&request), 1, &written));
    try t.expectEqualDeep(input, request);
    request.source = copy.address_limit - 4096;
    try t.expectEqual(c.status_invalid, encodeCopy(&request, &words, words.len, &written));
    var fill: c.R4AmdFill = .{ .version = 1, .size = @sizeOf(c.R4AmdFill), .target = 0x200000000, .byte_length = 4 * 1024 * 1024, .value = 0x12345678, .reserved = 0 };
    try t.expectEqual(c.status_ok, encodeFill(&fill, &words, words.len, &written));
    try t.expectEqual(@as(u32, 10), written);
    try t.expectEqualSlices(u32, &.{ 0x8000000b, 0, 2, 0x12345678, 0x3ffffb, 0x8000000b, 0x3ffffc, 2, 0x12345678, 3 }, words[0..10]);
    const filled = words; fill.byte_length -= 1;
    try t.expectEqual(c.status_invalid, encodeFill(&fill, &words, words.len, &written));
    try t.expectEqualDeep(filled, words);
    // Odd row pitches use bounded linear packets; packed rows collapse to one.
    try t.expectEqual(@as(usize, 21), try copy.encodeCopy(&words, .{ .source = 0x1000, .target = 0x9000, .bytes = 3, .rows = 3, .source_pitch = 5, .target_pitch = 7 }));
    try t.expectEqual(@as(u32, 0x100a), words[17]); try t.expectEqual(@as(u32, 0x900e), words[19]);
    try t.expectEqual(@as(usize, 14), try copy.encodeCopy(&words, .{ .source = 0x1000, .target = 0x9000, .bytes = 3, .rows = 3, .source_pitch = 3, .target_pitch = 3 }));
    try t.expectError(error.Capacity, copy.encodeCopy(&words, .{ .source = 0x100000000, .target = 0x200000000, .bytes = 3, .rows = 300, .source_pitch = 5, .target_pitch = 7 }));
}

comptime { _ = @import("media_test.zig"); }
