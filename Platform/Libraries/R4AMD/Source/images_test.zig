// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const c = @import("r4l_contract");
const image = @import("images.zig");
fn request() c.R4AmdImageRequest {
    return .{ .version = 1, .size = @sizeOf(c.R4AmdImageRequest), .gb_addr_config = 0x24000042, .chip_revision = 0x41, .device_id = 0x15d8, .gc_version = c.gc_9_1_0, .resource_type = 1, .format = 875713112, .width = 257, .height = 129, .depth = 1, .mip_count = 1, .samples = 1, .usage = 3, .swizzle = 0, .pipe_xor = 0, .pitch = 0, .reserved = 0, .modifier = 0 };
}
test "real linked AddrLib surface, coordinates and bounded callback allocation" {
    for ([_]bool{ false, true }) |raven2| {
    var scratch: [65536]u8 align(16) = undefined;
    var r = request();
    if (raven2) { r.gc_version = c.gc_9_2_2; r.chip_revision = 0x82; r.gb_addr_config = 0x26013041; }
    var layout: c.R4AmdImageLayout = undefined;
    var mips: [15]c.R4AmdMip = undefined;
    const rc = image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15);
    try t.expectEqual(c.status_ok, rc);
    try t.expect(layout.pitch >= r.width * 4 and layout.byte_length >= @as(u64, layout.pitch) * r.height);
    var coord: c.R4AmdCoordinate = .{ .version = 1, .size = @sizeOf(c.R4AmdCoordinate), .x = 17, .y = 19, .slice = 0, .sample = 0, .mip = 0, .reserved = 0 };
    var address: c.R4AmdImageAddress = undefined;
    try t.expectEqual(c.status_ok, image.address(&r, &coord, &scratch, scratch.len, &address));
    try t.expectEqual(@as(u64, layout.pitch) * 19 + 17 * 4, address.offset);
    const before = layout;
    const before_mips = mips;
    try t.expectEqual(c.status_oom, image.calculate(&r, &scratch, 16, &layout, &mips, 15));
    try t.expectEqualDeep(before, layout);
    try t.expectEqualSlices(u8, std.mem.asBytes(&before_mips)[0..64], std.mem.asBytes(&mips)[0..64]);
    r.swizzle = 26;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    r.mip_count = 9;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    try t.expectEqual(@as(u64, 65536), layout.alignment);
    try t.expectEqual(c.status_ok, image.address(&r, &coord, &scratch, scratch.len, &address));
    try t.expect(address.offset != @as(u64, layout.pitch) * 19 + 17 * 4);
    var metadata: c.R4AmdMetadata = undefined;
    try t.expectEqual(c.status_ok, image.metadata(&r, &scratch, scratch.len, &metadata));
    try t.expect(metadata.kind == 1 and metadata.flags == 0 and metadata.byte_length > 0);
    const original = layout;
    r.chip_revision = if (raven2) 0x41 else 0x82;
    try t.expectEqual(c.status_unsupported, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    try t.expectEqualDeep(original, layout);
    }
}
const regs = @cImport({
    @cInclude("amdgfx9regs.h");
});
test "real GFX9 shader/attachment/PM4 integration, indexed range and failure atomicity" {
    try @import("render_checks.zig").run();
    try @import("render_batch_checks.zig").run();
}
test "AddrLib mips, arrays, volumes, MSAA, block formats and descriptor reference fields" {
    var scratch: [65536]u8 align(16) = undefined;
    var layout: c.R4AmdImageLayout = undefined;
    var mips: [15]c.R4AmdMip = undefined;
    var r = request();
    r.width = 128;
    r.height = 128;
    r.depth = 3;
    r.mip_count = 8;
    r.swizzle = 25;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    var addresses: [3]u64 = undefined;
    for (&addresses, 0..) |*offset, slice| {
        var a: c.R4AmdImageAddress = undefined;
        try t.expectEqual(c.status_ok, image.address(&r, &.{ .version = 1, .size = @sizeOf(c.R4AmdCoordinate), .x = 0, .y = 0, .slice = @intCast(slice), .sample = 0, .mip = 7, .reserved = 0 }, &scratch, scratch.len, &a));
        offset.* = a.offset;
    }
    try t.expect(addresses[0] != addresses[1] and addresses[1] != addresses[2]);
    r.resource_type = 2;
    r.depth = 8;
    r.usage = 1;
    r.mip_count = 4;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    try t.expect(mips[3].depth >= 1);
    r = request();
    r.width = 64;
    r.height = 64;
    r.samples = 4;
    r.swizzle = 27;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    var samples: [4]u64 = undefined;
    for (&samples, 0..) |*offset, sample| {
        var a: c.R4AmdImageAddress = undefined;
        try t.expectEqual(c.status_ok, image.address(&r, &.{ .version = 1, .size = @sizeOf(c.R4AmdCoordinate), .x = 2, .y = 3, .slice = 0, .sample = @intCast(sample), .mip = 0, .reserved = 0 }, &scratch, scratch.len, &a));
        offset.* = a.offset;
        for (samples[0..sample]) |old| try t.expect(old != a.offset);
    }
    r.samples = 1;
    r.usage = 1;
    r.swizzle = 25;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    r.mip_count = 7;
    for ([_]u32{ 0x01000101, 0x01000103, 0x01000105, 0x01000107 }) |fmt| {
        r.format = fmt;
        try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
        try t.expectEqual(@as(u32, if (fmt == 0x01000101) 64 else 128), layout.element_bits);
    }
    r = request();
    r.format = 0x01000001;
    r.usage = 17;
    r.swizzle = 24;
    r.modifier = std.math.maxInt(u64);
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    var metadata: c.R4AmdMetadata = undefined;
    try t.expectEqual(c.status_ok, image.metadata(&r, &scratch, scratch.len, &metadata));
    try t.expect(metadata.kind == 2 and metadata.flags == 0 and metadata.slice_bytes > 0);
    r = request();
    r.width = 64;
    r.height = 64;
    r.depth = 2;
    r.mip_count = 7;
    r.swizzle = 26;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    var v: c.R4AmdImageView = .{ .version = 1, .size = @sizeOf(c.R4AmdImageView), .address = 0x123400000000, .byte_length = layout.byte_length, .offset = 0, .first_layer = 1, .last_layer = 1, .first_mip = 2, .last_mip = 5, .sampler = 1, .min_lod = 128, .max_lod = 1024, .lod_bias = -128, .wrap_u = 2, .wrap_v = 1, .wrap_w = 0, .compare = 7, .aniso = 2, .border = 1, .flags = 0, .reserved = 0 };
    var desc: c.R4AmdImageDescriptors = undefined;
    try t.expectEqual(c.status_ok, image.descriptors(&r, &v, &scratch, scratch.len, &desc));
    try t.expectEqual(@as(u32, 0x12), regs.G_008F14_BASE_ADDRESS_HI(desc.texture1));
    try t.expectEqual(@as(u32, 26), regs.G_008F1C_SW_MODE(desc.texture3));
    try t.expectEqual(@as(u32, 6), regs.G_008F1C_DST_SEL_X(desc.texture3));
    try t.expectEqual(@as(u32, 1), regs.G_008F1C_DST_SEL_W(desc.texture3));
    try t.expectEqual(@as(u32, 1), regs.G_028C74_MIP0_DEPTH(desc.color5));
    try t.expectEqual(@as(u32, 1), regs.G_028C74_FORCE_DST_ALPHA_1(desc.color5));
    try t.expectEqual(@as(u32, 2), regs.G_028C6C_MIP_LEVEL(desc.color3));
    try t.expectEqual(@as(u32, 1), regs.G_008F30_COMPAT_MODE(desc.sampler0));
    try t.expectEqual(@as(u32, 1), regs.G_008F38_FILTER_PREC_FIX(desc.sampler2));
    try t.expectEqual(@as(u32, 0), desc.texture6 | desc.texture7 | desc.color6 | desc.color7 | desc.color8 | desc.color9 | desc.color10 | desc.color11 | desc.color12 | desc.color13 | desc.color14);
    const before = desc;
    v.border = 3;
    try t.expectEqual(c.status_invalid, image.descriptors(&r, &v, &scratch, scratch.len, &desc));
    try t.expectEqualDeep(before, desc);
}
test "image import exact modifier/topology/epoch, scanout policy, OOM and unchanged error outputs" {
    var scratch: [65536]u8 align(16) = undefined;
    var r = request();
    r.width = 128;
    r.height = 64;
    r.swizzle = 26;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    var layout: c.R4AmdImageLayout = undefined;
    var mips: [15]c.R4AmdMip = undefined;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    var imported: c.R4AmdImageImport = .{ .version = 1, .size = @sizeOf(c.R4AmdImageImport), .byte_length = layout.byte_length, .alignment = layout.alignment, .offset = 0, .modifier = layout.modifier, .adapter_id = 7, .reserved = 0, .memory_generation = 11, .expected_adapter = 7, .metadata_state = 0, .expected_memory_generation = 11, .pitch = layout.pitch, .usage = 3 };
    try t.expectEqual(c.status_ok, image.importImage(&r, &imported, &scratch, scratch.len, &layout, &mips, 15));
    const before = layout;
    const first = mips[0];
    inline for (.{ "modifier", "metadata_state", "alignment", "pitch", "memory_generation", "expected_memory_generation", "adapter_id", "offset", "reserved" }) |field| {
        const old = @field(imported, field);
        @field(imported, field) = old + 1;
        try t.expect(image.importImage(&r, &imported, &scratch, scratch.len, &layout, &mips, 15) != c.status_ok);
        @field(imported, field) = old;
        try t.expectEqualDeep(before, layout);
        try t.expectEqualDeep(first, mips[0]);
    }
    imported.byte_length -= 1;
    try t.expectEqual(c.status_invalid, image.importImage(&r, &imported, &scratch, scratch.len, &layout, &mips, 15));
    r.modifier |= @as(u64, 1) << 13;
    try t.expectEqual(c.status_unsupported, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    r.gb_addr_config ^= 1;
    try t.expectEqual(c.status_unsupported, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    r = request();
    r.usage = 11;
    r.swizzle = 9;
    r.modifier = image.modifier(r.gb_addr_config, r.swizzle).?;
    try t.expectEqual(c.status_ok, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    try t.expect(layout.flags & c.image_flag_scanout != 0);
    r.depth = 2;
    try t.expectEqual(c.status_unsupported, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
    r = request();
    for ([_]u32{ 16, 40000, 40112, 40128 }) |bytes| try t.expectEqual(c.status_oom, image.calculate(&r, &scratch, bytes, &layout, &mips, 15));
    try t.expectEqual(c.status_invalid, image.calculate(&r, &scratch, scratch.len, @ptrCast(&mips[0]), &mips, 15));
    try t.expectEqual(c.status_invalid, image.calculate(&r, @ptrCast(&r), 80, &layout, &mips, 15));
    r.width = 16384;
    r.height = 16384;
    try t.expectEqual(c.status_limit, image.calculate(&r, &scratch, scratch.len, &layout, &mips, 15));
}
