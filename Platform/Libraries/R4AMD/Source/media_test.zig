// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const c = @import("r4l_contract");
const media = @import("media.zig");
const t = std.testing;
test "VCN1 codec profile intersection rejects AV1 MPEG4P2 and Main10 encode without mutating output" {
    const impl = media.Provider(c);
    var query = std.mem.zeroes(c.R4AmdMediaQuery);
    query.version = 1; query.size = @sizeOf(c.R4AmdMediaQuery); query.vendor_id = 0x1002; query.device_id = 0x15d8;
    query.gc_version = c.gc_9_1_0; query.vcn_version = c.vcn_1_0_0; query.firmware_version = c.picasso_vcn_firmware;
    query.codec = 1; query.chroma = 1; query.bit_depth = 8; query.width = 1920; query.height = 1080;
    var caps: c.R4AmdMediaCaps = undefined;
    try t.expectEqual(c.status_ok, impl.caps(&query, &caps)); try t.expectEqual(@as(u32, 17), caps.dpb_slots);
    const saved = caps;
    query.gc_version = c.gc_9_2_2;
    try t.expectEqual(c.status_unsupported, impl.caps(&query, &caps)); try t.expectEqualDeep(saved, caps);
    query.vcn_version = c.vcn_1_0_1; query.firmware_version = c.raven2_vcn_firmware;
    try t.expectEqual(c.status_ok, impl.caps(&query, &caps)); try t.expectEqualDeep(saved, caps);
    query.gc_version = c.gc_9_1_0; query.vcn_version = c.vcn_1_0_0; query.firmware_version = c.picasso_vcn_firmware;
    for ([_]u32{ 7, 8, 0, 9 }) |codec| { query.codec = codec; try t.expectEqual(c.status_unsupported, impl.caps(&query, &caps)); try t.expectEqualDeep(saved, caps); }
    query.codec = 2; query.profile = 2; query.bit_depth = 10;
    try t.expectEqual(c.status_ok, impl.caps(&query, &caps)); try t.expectEqual(@as(u32, 2), caps.format);
    query.operation = 1; try t.expectEqual(c.status_unsupported, impl.caps(&query, &caps));
    query.profile = 1; query.bit_depth = 8;
    try t.expectEqual(c.status_ok, impl.caps(&query, &caps)); try t.expectEqual(@as(u32, 1), caps.active_references);
    try t.expectEqual(@as(u32, 2304), caps.max_height); try t.expectEqual(@as(u32, 7), caps.rate_controls);
    query.firmware_version += 1; try t.expectEqual(c.status_unsupported, impl.caps(&query, &caps));
    query.firmware_version -= 1; query.chroma = 3; try t.expectEqual(c.status_unsupported, impl.caps(&query, &caps));
    query.chroma = 1; query.width = 0; try t.expectEqual(c.status_invalid, impl.caps(&query, &caps));
    query.width = 1920; const input = query;
    try t.expectEqual(c.status_invalid, impl.caps(&query, @ptrCast(&query))); try t.expectEqualDeep(input, query);
}
test "AMD native NV12 P010 geometry retains independent aligned luma and chroma bounds" {
    for ([_]u32{8,10}) |depth| {
        const surface = try media.Surface.plan(1920, 1080, depth);
        try t.expect(surface.pitch % 256 == 0 and surface.rows == 1088 and surface.chroma_rows == 544);
        try t.expect(surface.chroma_offset % 65536 == 0 and surface.bytes % 65536 == 0);
        try t.expect(surface.chroma_offset >= @as(u64, surface.pitch) * surface.rows and surface.bytes - surface.chroma_offset >= @as(u64, surface.pitch) * surface.chroma_rows);
    }
    try t.expectError(error.Unsupported, media.Surface.plan(1921, 1080, 8));
    try t.expectError(error.Unsupported, media.Surface.plan(1920, 1080, 12));
}

comptime { _ = @import("vcn_decode_test.zig"); }
