// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Host-only cases in the existing provider test, through the exported table.
const std = @import("std");
const c = @import("r4l_contract");
const t = std.testing;

pub fn run(api: *const c.ShaderV1) !void {
    var key: c.R4NvShaderKey = .{ .version = 1, .size = @sizeOf(c.R4NvShaderKey), .vendor_id = 0x10de, .device_id = 0x2484,
        .graphics_class = 0xc797, .shader_model = 86, .rm_release = 570144, .command_abi = 1, .shader_abi = 1, .resource_abi = 4,
        .input_format = 875713089, .output_format = 875713112, .driver_build = 0x100000002,
        .device_uuid = .{ .word0 = 0x100000003, .word1 = 4, .word2 = 5, .word3 = 6 },
        .pipeline_state = .{ .word0 = 0x200000007, .word1 = 8, .word2 = 9, .word3 = 10 } };
    const original_key = key;
    // Independent outputs of the pinned Mesa26.2.2 NAK host checkpoint.
    const hashes = [_][]const u8{
        "1efe5eb9bf14ca597f48dda6460b2e09e7a2c335e7c25671cdf5eb63ed6437c9",
        "1d42b2d4e6e9354020c561b97596b3c910d41c63a7dd119f977c5ba7d02084bc",
        "3873884f06b24cdd2fb1e101efae58130c734b003052af415d5b2705c2dc8e25",
        "240fff71918a8d7f6c21782de436cb4698d6d82b772caf1e9b9c8919f36534f6",
        "94811e8c07f6e09dcba8c3c0cce8aacedbab7293b76542935ecbf150abd39984",
        "356c276ffdc82e9cc63e49fb5a79b7602ff82d4981804689f7ec8f8c042ccc04",
        "d4ecf66ff0fa3256d5e080488427720ff212c98c58f19d2d511c0be7c5dc5447",
        "2439c347520463a6c76824c0e8e4435b2838f49281301ab0db7fee83b1ddc49e",
        "dc4b31a3727e861fc64fcb348b4939123371aa0116913fb99f6a45e375572c01",
    };
    const sizes = [_]u32{ 112, 2208, 2736, 2736, 80, 80, 10976, 11056, 624 };
    const instructions = [_]u32{ 7, 138, 171, 171, 5, 5, 686, 691, 39 };
    var storage: [c.shader_cache_max_bytes + 8]u8 align(8) = @splat(0xa5);
    const bytes = storage[1 .. 1 + c.shader_cache_max_bytes]; // ABI promises byte alignment.
    var view: c.R4NvShaderView = std.mem.zeroes(c.R4NvShaderView);
    var info: c.R4NvShaderInfo = undefined;
    var written: u32 = 99;
    for (hashes, sizes, instructions, 1..) |hex, size, count, id| {
        const profile: u32 = @intCast(id);
        try t.expectEqual(c.status_ok, api.shader_info(profile, &info));
        try t.expect(info.code_bytes == size and info.instructions == count and info.registers == @as(u32, if (id == 8) 32 else 24) and info.max_warps_per_sm == 48 and
            info.stage == @as(u32, if (id == 1 or id == 6) 0 else 4) and info.scratch_bytes == 0 and info.stack_bytes == 0 and info.header_bytes == 128);
        try t.expectEqual(c.status_ok, api.shader_cache_write(profile, &key, bytes.ptr, bytes.len, &written));
        try t.expect(written == 384 + size);
        try t.expectEqual(c.status_ok, api.shader_cache_read(&key, bytes.ptr, written, &view));
        try t.expectEqualDeep(info, view.info);
        try t.expect(view.header_address == @intFromPtr(bytes.ptr) + 224 and view.code_address == @intFromPtr(bytes.ptr) + 384);
        var expected: [32]u8 = undefined;
        _ = try std.fmt.hexToBytes(&expected, hex);
        var actual: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(@as([*]const u8, @ptrFromInt(view.code_address))[0..size], &actual, .{});
        try t.expectEqualSlices(u8, &expected, &actual);
    }
    try t.expect(storage[0] == 0xa5 and storage[storage.len - 1] == 0xa5);
    const accepted_info = info;
    try t.expectEqual(c.status_unsupported, api.shader_info(10, &info));
    try t.expectEqualDeep(accepted_info, info);
    try t.expectEqual(c.status_ok, api.shader_cache_write(2, &key, bytes.ptr, bytes.len, &written));
    const good = storage;
    const good_length = written;
    const accepted_view = view;
    // Every byte of the existing texture entry is covered, including reserved bytes,
    // headers, identities, digest and executable instructions.
    for (0..written) |i| {
        bytes[i] ^= 1;
        try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&key, bytes.ptr, written, &view));
        try t.expectEqualDeep(accepted_view, view);
        bytes[i] ^= 1;
    }
    for (0..written) |length| try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&key, bytes.ptr, @intCast(length), &view));
    try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&key, bytes.ptr, written + 1, &view));
    // A valid checksum does not authorize a different program/header.
    bytes[224] ^= 1;
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    hash.update(bytes[0..352]); hash.update(bytes[384..written]);
    @memcpy(bytes[352..384], &hash.finalResult());
    try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&key, bytes.ptr, written, &view));
    storage = good;
    inline for (.{ "device_id", "input_format", "output_format", "driver_build" }) |field| {
        @field(key, field) += 1;
        try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&key, bytes.ptr, written, &view));
        key = original_key;
    }
    inline for (.{ "device_uuid", "pipeline_state" }) |field| inline for (std.meta.fields(c.R4NvDigest)) |word| {
        @field(@field(key, field), word.name) ^= 1;
        try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&key, bytes.ptr, written, &view));
        key = original_key;
    };
    inline for (.{ "vendor_id", "graphics_class", "shader_model", "rm_release", "command_abi", "shader_abi", "resource_abi" }) |field| {
        @field(key, field) += 1;
        try t.expectEqual(c.status_unsupported, api.shader_cache_read(&key, bytes.ptr, written, &view));
        try t.expectEqual(c.status_unsupported, api.shader_cache_write(4, &key, bytes.ptr, bytes.len, &written));
        key = original_key;
    }
    // Earlier resource ABIs lack the separate color program. Their keys must not select
    // these shaders even though public table/payload sizes are unchanged.
    key.resource_abi = 3;
    try t.expectEqual(c.status_unsupported, api.shader_cache_read(&key, bytes.ptr, written, &view));
    try t.expectEqual(c.status_unsupported, api.shader_cache_write(4, &key, bytes.ptr, bytes.len, &written));
    key = original_key;
    key.device_uuid = std.mem.zeroes(c.R4NvDigest);
    try t.expectEqual(c.status_invalid, api.shader_cache_read(&key, bytes.ptr, written, &view));
    key = original_key;
    try t.expectEqualDeep(accepted_view, view);
    written = 99;
    try t.expectEqual(c.status_capacity, api.shader_cache_write(2, &key, bytes.ptr, good_length - 1, &written));
    try t.expectEqual(c.status_unsupported, api.shader_cache_write(10, &key, bytes.ptr, bytes.len, &written));
    try t.expectEqual(c.status_invalid, api.shader_cache_write(4, &key, bytes.ptr, bytes.len, &key.version));
    try t.expectEqual(c.status_invalid, api.shader_cache_write(4, &key, bytes.ptr, bytes.len, @ptrCast(@alignCast(&storage[4]))));
    try t.expectEqual(c.status_invalid, api.shader_cache_write(4, &key, @ptrCast(&key), bytes.len, &written));
    try t.expectEqual(c.status_invalid, api.shader_cache_read(&key, bytes.ptr, bytes.len, @ptrCast(@alignCast(&storage[8]))));
    try t.expectEqual(c.status_invalid, api.shader_cache_read(&key, bytes.ptr, bytes.len, @ptrCast(&key)));
    try t.expectEqualSlices(u8, &good, &storage);
    try t.expectEqualDeep(original_key, key);
    try t.expect(written == 99);
    try t.expectEqual(c.status_ok, api.shader_cache_read(&key, bytes.ptr, good_length, &view));
    try t.expect(view.info.profile == 2);
    // Compiler checkpoints for the other ISAs. SM86 and SM89 happen to
    // share this program's bytes, but must still have distinct cache keys.
    const generation_hashes = [_][]const u8{
        "4e3e7007bbf8abb5cf0fcc4d90ee003c8b613805ed90b7c7a188e344bc813154",
        "d4ecf66ff0fa3256d5e080488427720ff212c98c58f19d2d511c0be7c5dc5447",
        "d4ecf66ff0fa3256d5e080488427720ff212c98c58f19d2d511c0be7c5dc5447",
        "3d816e091c0d105cca2fb82ea36bd0551761bebc86f005218df4049f663ee814",
    };
    const yuv_hashes = [_][]const u8{
        "c38e0a3c5ecd94d79104be2780d5e0a28532663475464e3fb65d3edd2586b092",
        "2439c347520463a6c76824c0e8e4435b2838f49281301ab0db7fee83b1ddc49e",
        "2439c347520463a6c76824c0e8e4435b2838f49281301ab0db7fee83b1ddc49e",
        "23d44c7f2a434ddf583bd1c1288f7fb045e60a3c71256be50c3d2431ef7d9c46",
    };
    const classes = [_]u32{0xc597,0xc797,0xc997,0xcd97};
    const models = [_]u32{75,86,89,120};
    for (classes, models, generation_hashes, yuv_hashes) |class, sm, color_hex, yuv_hex| {
      for ([_]u32{7,8}, [_][]const u8{color_hex,yuv_hex}) |profile, hex| {
        key.graphics_class = class; key.shader_model = sm;
        try t.expectEqual(c.status_ok, api.shader_cache_write(profile, &key, bytes.ptr, bytes.len, &written));
        try t.expectEqual(c.status_ok, api.shader_cache_read(&key, bytes.ptr, written, &view));
        try t.expectEqual(sm, view.info.shader_model);
        try t.expectEqual(@as(u32,if(sm == 75) 32 else 48), view.info.max_warps_per_sm);
        var expected: [32]u8 = undefined; _ = try std.fmt.hexToBytes(&expected, hex);
        var actual: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(bytes[384..written], &actual, .{});
        try t.expectEqualSlices(u8, &expected, &actual);
        for (classes, models) |other, other_sm| {
            if (other == class) continue;
            var alien = key; alien.graphics_class = other; alien.shader_model = other_sm;
            try t.expectEqual(c.status_cache_miss, api.shader_cache_read(&alien, bytes.ptr, written, &view));
            alien.shader_model = sm;
            try t.expectEqual(c.status_unsupported, api.shader_cache_write(profile, &alien, bytes.ptr, bytes.len, &written));
        }
      }
    }
}
