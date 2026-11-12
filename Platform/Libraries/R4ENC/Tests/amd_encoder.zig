// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Real Input/VCN owner/SDK dispatch; firmware completions and Annex-B payloads
// are modeled. These checks do not demonstrate execution on an AMD GPU.
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const a = r.abi;
const c = @import("binding");
const gpu = @import("gpu_resources");
const fixture = @import("gpu_model");
const enc = @import("amd_encoder").Implementation(@cImport(@cInclude("vcn_encode.h")));
const input = @import("encode_input");
const Budget = @import("native_allocation").Budget;
var expected: struct { codec: u32, rate: u32, mode: u32 = 0, serial: u32 = 0, frames: u32 = 0, opens: u32 = 0, closes: u32 = 0, key: bool = true } = undefined;
fn dw(bytes: []const u8, index: usize) u32 {
    return fixture.word(bytes, index * 4);
}
fn address(bytes: []const u8, index: usize) u64 {
    return (@as(u64, dw(bytes, index)) << 32) | dw(bytes, index + 1);
}
fn put(bytes: []u8, index: usize, value: u32) void {
    std.mem.writeInt(u32, bytes[index * 4 ..][0..4], value, .little);
}
fn inspect(bytes: []const u8) void {
    std.debug.assert(bytes.len % 64 == 0 and dw(bytes, 0) == 24 and dw(bytes, 1) == 1 and dw(bytes, 2) == 0x10009);
    std.debug.assert(dw(bytes, 6) == 20 and dw(bytes, 7) == 2 and dw(bytes, 9) > expected.serial);
    expected.serial = dw(bytes, 9);
    var at: usize = 0;
    var operation: u32 = 0;
    var bitstream: u64 = 0;
    var feedback: u64 = 0;
    while (at < bytes.len and fixture.word(bytes, at) != 0) {
        const packet = bytes[at..];
        const size = dw(packet, 0);
        const id = dw(packet, 1);
        std.debug.assert(size >= 8 and size % 4 == 0 and size <= bytes.len - at);
        switch (id) {
            6 => std.debug.assert(dw(packet, 2) == (switch (expected.rate) {
                0 => @as(u32, 0),
                1 => 3,
                else => 2,
            })),
            0xb => {
                std.debug.assert(dw(packet, 2) == (if (expected.key) @as(u32, 2) else 1));
                std.debug.assert(dw(packet, 10) == 0 and dw(packet, 12) < 2);
            },
            0xe => bitstream = address(packet, 3),
            0x10 => feedback = address(packet, 3),
            0x1000001, 0x1000002, 0x1000003 => operation = id,
            else => {},
        }
        at += size;
    }
    std.debug.assert(dw(bytes, 8) == at - 24);
    for (bytes[at..]) |v| std.debug.assert(v == 0);
    switch (operation) {
        0x1000001 => {
            expected.opens += 1;
            std.debug.assert(fixture.model.loan_count == 2);
        },
        0x1000002 => {
            expected.closes += 1;
            std.debug.assert(fixture.model.loan_count == 2);
        },
        0x1000003 => {
            expected.frames += 1;
            std.debug.assert(bitstream != 0 and feedback != 0 and fixture.model.loan_count == 6);
            const status = fixture.virtualBytes(feedback);
            for (status[0..40]) |v| std.debug.assert(v == 255);
            // No input-pixel CPU map exists. Only commands, feedback and
            // compressed output are mapped by this worker.
            var mapped: usize = 0;
            for (&fixture.model.bos) |*bo| if (bo.mapped) {
                mapped += 1;
            };
            std.debug.assert(mapped == 3);
            if (expected.mode == 1) return; // stale/missing feedback
            put(status, 1, 1);
            put(status, 5, 0);
            put(status, 8, 0);
            const output = fixture.virtualBytes(bitstream);
            const avc = [_]u8{ 0, 0, 0, 1, if (expected.key) 0x65 else 0x41, 0x80 };
            const hevc = [_]u8{ 0, 0, 0, 1, if (expected.key) 38 else 2, 1, 0x80 };
            const packet: []const u8 = if (expected.codec == 1) &avc else &hevc;
            @memcpy(output[0..packet.len], packet);
            put(status, 6, if (expected.mode == 2) 0xffffffff else @intCast(packet.len));
            if (expected.mode == 3) put(status, 8, 9);
            if (expected.mode == 4) output[4] = 0xff;
        },
        else => unreachable,
    }
}
fn config(codec: u32, rate: u32) c.R4EncConfig {
    var value = std.mem.zeroes(c.R4EncConfig);
    value.query.backend = 2;
    value.query.codec = codec;
    value.query.profile = if (codec == 1) 66 else 1;
    value.query.bit_depth = 8;
    value.query.chroma = 1;
    value.width = 320;
    value.height = 192;
    value.fps_num = 30;
    value.fps_den = 1;
    value.gop_frames = 3;
    value.max_packet_bytes = 65536;
    value.rate.qp = 26;
    value.rate.min_qp = 1;
    value.rate.max_qp = 51;
    value.color.bit_depth = 8;
    value.color.range = 2;
    value.color.primaries = 1;
    value.color.transfer = 1;
    value.color.matrix = 1;
    value.rate.mode = rate;
    if (rate != 0) {
        value.rate.target_bps = 1000000;
        value.rate.peak_bps = if (rate == 1) 1000000 else 2000000;
        value.rate.buffer_bits = 4000000;
    }
    return value;
}
pub fn run() !void {
    var state: fixture.Model = .{};
    fixture.model = &state;
    var raw: a.R4XStartContext = .{};
    var table: a.R4XStartR4Draw = .{};
    fixture.install(&table);
    var bundle: r.program.Bundle = .{ .raw = &raw, .draw = &table };
    const base = r.program.Context.initBundle(&bundle);
    const memory: r.gfx_buffers.Context = .{ .base = base };
    var budget: Budget = .{ .limit = 16 * 1024 * 1024 };
    var producer_budget: Budget = .{ .limit = 4 * 1024 * 1024 };
    var output: [65536]u8 = undefined;
    for ([_]u32{ 1, 2 }) |codec| for (0..3) |rate| {
        state = .{ .provider = .amd, .next_va = 0x5000000000, .engine = .encode, .push_bytes = 0, .on_submit = &inspect };
        expected = .{ .codec = codec, .rate = @intCast(rate) };
        const device = try gpu.Device.queryProvider(base, 9, .encode, .amd);
        var settings = config(codec, @intCast(rate));
        if (rate == 0) {
            settings.width = 130;
            settings.height = 130;
        }
        var backend = enc.Backend.init(base, device, &budget, fixture.clock, try enc.Config.from(settings));
        var producer: gpu.Context = .{ .base = base, .device = device, .budget = &producer_budget, .clock = fixture.clock };
        var source: [1]gpu.Resource = @splat(.{});
        if (rate == 0) {
            // The recorder owns canonical system NV12, unmaps before Send,
            // and passes coded padding separately from visible dimensions.
            try source[0].system(&producer, 131072);
            try source[0].suspendCpu();
        } else try source[0].nv12(&producer, settings.width, settings.height);
        var owner: input.Input(c) = .{};
        var image = @import("gpu_input.zig").frameFor(&source, settings.width, settings.height, false);
        if (rate == 0) {
            image.plane0.pitch = 256;
            image.plane1.pitch = 256;
            image.plane1.offset = 256 * std.mem.alignForward(u64, settings.height, if (codec == 1) 16 else 64);
        }
        try owner.admit(&memory, &budget, image, settings.width, settings.height);
        for (0..7) |frame| {
            expected.key = frame % 3 == 0;
            const packet = try backend.encode(&owner, false, &output, 5_001_000_000);
            try t.expect(packet.bytes >= 6 and packet.key == expected.key);
            try t.expect(backend.input.owner != null and backend.input.mapping.lease.id == 0);
            try t.expectEqual(@as(u32, if (codec == 1) 2 else 1) * (1 + @as(u32, @intCast(frame % 3))), backend.poc);
            try backend.retireInput();
            try t.expect(backend.input.owner == null);
        }
        try backend.reset();
        expected.key = true;
        _ = try backend.encode(&owner, false, &output, 5_001_000_000);
        try backend.retireInput();
        try backend.close();
        try backend.close();
        try owner.close(&memory);
        try source[0].close();
        try producer.close();
        try t.expectEqual(@as(u32, 1), expected.opens);
        try t.expectEqual(@as(u32, 1), expected.closes);
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try t.expectEqual(@as(usize, 0), producer_budget.liveBytes());
        try state.clean();
    };
    // Missing, invalid and contradictory feedback is never a published packet.
    // An unretired init/encode/close cannot release session or borrowed pixels.
    for (1..8) |mode| {
        state = .{ .provider = .amd, .next_va = 0x5000000000, .engine = .encode, .push_bytes = 0, .on_submit = &inspect };
        expected = .{ .codec = 1, .rate = 0, .mode = if (mode <= 4) @intCast(mode) else 0 };
        const device = try gpu.Device.queryProvider(base, 9, .encode, .amd);
        var backend = enc.Backend.init(base, device, &budget, fixture.clock, try enc.Config.from(config(1, 0)));
        var producer: gpu.Context = .{ .base = base, .device = device, .budget = &producer_budget, .clock = fixture.clock };
        var source: [1]gpu.Resource = @splat(.{});
        try source[0].nv12(&producer, 320, 192);
        var owner: input.Input(c) = .{};
        try owner.admit(&memory, &budget, @import("gpu_input.zig").frameFor(&source, 320, 192, false), 320, 192);
        if (mode >= 6) {
            _ = try backend.encode(&owner, false, &output, 5_001_000_000);
            try backend.retireInput();
            expected.key = false;
        }
        if (mode >= 5) state.queue_timeout = true;
        if (mode == 7) {
            try t.expectError(error.Timeout, backend.close());
        } else {
            const failure: enc.Error = switch (mode) {
                1, 2 => error.MissingStatus,
                3 => error.Encode,
                4 => error.Bitstream,
                else => error.Timeout,
            };
            @memset(&output, 0xa5);
            try t.expectError(failure, backend.encode(&owner, false, &output, 5_001_000_000));
            for (output) |byte| try t.expectEqual(@as(u8, 0xa5), byte);
        }
        if (mode >= 5) {
            const held = budget.liveBytes();
            try t.expectError(error.Busy, backend.retireInput());
            try t.expectEqual(held, budget.liveBytes());
            try t.expect(!backend.closed);
            state.queue_released = true;
            state.queue_timeout = false;
        }
        try backend.retireInput();
        try t.expect(backend.closed);
        try owner.close(&memory);
        try source[0].close();
        try producer.close();
        try t.expectEqual(@as(u32, 1), expected.closes);
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try state.clean();
    }
    var bad = config(2, 0);
    bad.query.profile = 2;
    try t.expectError(error.Unsupported, enc.Config.from(bad));
    bad = config(1, 0);
    bad.query.codec = 7;
    try t.expectError(error.Invalid, enc.Config.from(bad));
    bad = config(1, 1);
    bad.rate.peak_bps += 1;
    try t.expectError(error.Invalid, enc.Config.from(bad));
    bad = config(1, 0);
    bad.width = 4096;
    bad.height = 2304;
    bad.fps_num = 60;
    try t.expectError(error.Unsupported, enc.Config.from(bad)); // AVC5.2 MB/s bound
    try t.expectError(error.Bitstream, enc.checkBitstream(&.{ 0, 0, 1, 0x41, 0x80 }, 1, true));
    try t.expectError(error.Bitstream, enc.checkBitstream(&.{ 0, 0, 1, 38, 1, 0x80 }, 2, false));
    // Independently encoded and decoded IDR/P reference clips. HEVC IDR20
    // remains outside the exact IDR19 template sent to VCN1.
    const reference = @embedFile("Fixture/vcn-reference-nals.bin");
    try t.expectEqualStrings("VCNREF01", reference[0..8]);
    var at: usize = 8;
    while (at < reference.len) {
        const codec = fixture.word(reference, at);
        const key = fixture.word(reference, at + 4) == 1;
        const accepted = fixture.word(reference, at + 8) == 1;
        const bytes = fixture.word(reference, at + 12);
        at += 16;
        const nal = reference[at..][0..bytes];
        if (accepted) try enc.checkBitstream(nal, codec, key) else try t.expectError(error.Bitstream, enc.checkBitstream(nal, codec, key));
        at += bytes;
    }
    std.debug.print("VCN1 encode: CQP/CBR/VBR, H264/HEVC GOP/reset, no input CPU maps, fresh feedback, late init/frame/close ACK: OK\n", .{});
}
