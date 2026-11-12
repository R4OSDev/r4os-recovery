// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Focused owner checks inside the existing allocation case. Real SDK dispatch;
// only the kernel/driver callbacks are modeled. This does not decode pixels.
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const a = r.abi;
const nv = @import("r4nv_binding");
const gpu = @import("gpu_resources");
const amd = @import("r4amd");
const Budget = @import("native_allocation").Budget;
const ff = @cImport(@cInclude("nvdec.h"));
const Decoder = @import("gpu_decoder").Implementation(ff);
const fixture = @import("gpu_model");
const Model = fixture.Model;
const index = fixture.index;
const clock = fixture.clock;
const word = fixture.word;
const virtualBytes = fixture.virtualBytes;
var decoded: struct { mode: enum { none, success, missing, corrupt } = .none, current_slot: u32 = 0, reference_slots: [2]u32 = @splat(0) } = .{};
fn inspectDecode(words: []const u8) void {
    if (decoded.mode != .none) {
        const params = virtualBytes(@as(u64, word(words, 6 * 4)) << 8);
        const status = virtualBytes(@as(u64, word(words, 13 * 4)) << 8);
        // A preceding successful picture must not leave reusable success here.
        for (status[0..56]) |byte| std.debug.assert(byte == 0xff);
        decoded.current_slot = (word(params, 180) >> 2) & 127;
        decoded.reference_slots = .{ word(params, 192) & 127, word(params, 208) & 127 };
        if (decoded.mode != .missing) {
            @memset(status[0..56], 0);
            std.mem.writeInt(u32, status[0..4], word(params, 100) * word(params, 104), .little);
            if (decoded.mode == .corrupt) std.mem.writeInt(u32, status[52..56], 1, .little);
        }
    }
}
fn picture(seq: ff.struct_r4video_nvdec_sequence, number: u32) ff.struct_r4video_nvdec_picture {
    var p = std.mem.zeroes(ff.struct_r4video_nvdec_picture);
    p.sequence = seq;
    p.frame_num = number;
    p.is_reference = 1;
    p.poc = @splat(@as(i32, @intCast(number * 2)));
    p.scaling4 = @splat(@splat(16));
    p.scaling8 = @splat(@splat(16));
    return p;
}
fn decode(ops: *const ff.struct_r4video_nvdec_ops, p: *const ff.struct_r4video_nvdec_picture, expected: c_int) !?*anyopaque {
    var out: ?*anyopaque = null;
    try t.expectEqual(@as(c_int, 0), ops.allocate.?(ops.owner, &p.sequence, &out));
    try t.expect(out != null);
    try t.expectEqual(@as(c_int, 0), ops.begin.?(ops.owner, out, p));
    const nal = [_]u8{ 0x65, 0x88, 0x80 };
    try t.expectEqual(@as(c_int, 0), ops.slice.?(ops.owner, out, &nal, nal.len));
    try t.expectEqual(expected, ops.end.?(ops.owner, out));
    return out;
}

pub fn run() !void {
    var state: Model = .{};
    fixture.model = &state;
    var raw: a.R4XStartContext = .{};
    var table: a.R4XStartR4Draw = .{};
    fixture.install(&table);
    var bundle: r.program.Bundle = .{ .raw = &raw, .draw = &table };
    const base = r.program.Context.initBundle(&bundle);
    const device = try gpu.Device.query(base, 9);
    try t.expectEqual(@as(u32, 0xc7b0), device.class);
    try t.expectEqual(@as(u32, 0xc7b7), (try gpu.Device.queryFor(base, 9, .encode)).class);
    try t.expectEqual(gpu.address_limit, device.va_end);
    state.class_chip = 0x192;
    try t.expectEqual(@as(u32, 0xc9b0), (try gpu.Device.query(base, 9)).class);
    try t.expectEqual(@as(u32, 0xc9b7), (try gpu.Device.queryFor(base, 9, .encode)).class);
    state.class_chip = 0x999;
    try t.expectError(error.Unsupported, gpu.Device.query(base, 9));
    state.class_chip = 0x174;
    state.coherent = false;
    try t.expectError(error.Unsupported, gpu.Device.query(base, 9));
    state.coherent = true;
    var budget: Budget = .{ .limit = 8 * 65536 };
    var ctx: gpu.Context = .{ .base = base, .device = device, .budget = &budget, .clock = clock };
    var commands: gpu.Resource = .{};
    var image: gpu.Resource = .{};
    var scratch: gpu.Resource = .{};
    try commands.system(&ctx, 216);
    try scratch.video(&ctx, 129);
    try image.nv12(&ctx, 64, 16);
    try t.expectEqual(@as(u32, 32), image.descriptor.height);
    try t.expectEqual(@as(usize, 4 * 65536), budget.liveBytes());
    try t.expectEqual(@as(u32, 0x601), state.vas[index(&image.range, state.vas.len).?].request.flags);
    @memset((try commands.mappedBytes())[0..216], 0x7a);
    try ctx.submit(&commands, 216, &.{ .{ .resource = &image, .write = true }, .{ .resource = &scratch, .write = false },
        .{ .resource = &scratch, .write = true } });
    try t.expectEqual(@as(usize, 3), state.loan_count);
    try t.expectEqual(@as(u32, 1), state.loans[2].access);
    try t.expectEqual(@as(u64, 0), ctx.fence.timeline);
    try image.close();
    try image.close(); // Repeated cleanup is harmless.
    try scratch.close();
    try commands.close();
    try ctx.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try state.clean();

    // A late MAP reply must keep its BO and accounting alive. Closing the VA
    // cascades to its child; only the explicit retirement ACK permits release.
    state = .{ .bind_timeout = true, .retire_ready = false };
    ctx = .{ .base = base, .device = device, .budget = &budget, .clock = clock };
    try t.expectError(error.Timeout, image.nv12(&ctx, 64, 64));
    const held = budget.liveBytes();
    try t.expect(held > 0);
    try t.expectError(error.Busy, image.close());
    try t.expectEqual(held, budget.liveBytes());
    state.retire_ready = true;
    try image.close();
    try state.clean();

    state = .{ .native_timeout = true };
    try t.expectError(error.Timeout, scratch.video(&ctx, 256));
    try t.expect(state.pending_live);
    try scratch.close();
    try state.clean();

    // Never truncate a GPU VA to the NVDEC method's 40-bit field.
    state = .{ .next_va = gpu.address_limit };
    try t.expectError(error.Unsupported, commands.system(&ctx, 216));
    try commands.close();
    try state.clean();

    // Logical timeout/cancel does not make an active job's BOs reusable.
    state = .{ .queue_timeout = true };
    try commands.system(&ctx, 216);
    try image.nv12(&ctx, 64, 64);
    try t.expectError(error.Timeout, ctx.submit(&commands, 216, &.{.{ .resource = &image, .write = true }}));
    try t.expect(ctx.poisoned);
    try t.expectError(error.Busy, commands.mappedBytes());
    // A missing outstanding fence never proves physical retirement.
    const pending_fence = ctx.fence;
    state.fence_query_result = a.gfx_queue_error_stale;
    try t.expectError(error.Stale, ctx.close());
    try t.expectEqualDeep(pending_fence, ctx.fence);
    try t.expectEqual(@as(usize, 3 * 65536), budget.liveBytes());
    try t.expect(!state.fence_released and !state.queue_closed);
    state.fence_query_result = a.gfx_queue_ok;
    try t.expectError(error.Busy, ctx.close());
    try t.expectEqual(@as(u32, 1), state.cancel_count);
    try t.expectError(error.Busy, image.close());
    try t.expectError(error.Busy, commands.close());
    try t.expectEqual(@as(usize, 3 * 65536), budget.liveBytes());
    state.queue_released = true;
    state.queue_close_result = a.gfx_queue_error_busy;
    try t.expectError(error.Busy, ctx.close());
    try t.expect(ctx.fence.timeline == 0 and ctx.queue.timeline != 0 and !state.queue_closed);
    try t.expectEqual(@as(usize, 3 * 65536), budget.liveBytes());
    state.queue_close_result = a.gfx_queue_error_stale;
    try ctx.close();
    try image.close();
    try commands.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try state.clean();

    budget.limit = 65535;
    ctx.poisoned = false;
    try t.expectError(error.NoMemory, commands.system(&ctx, 1));
    try t.expect(commands.owner == null);
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try decoderChecks(base, device);
    try amdChecks(base);
    try @import("amd_decoder.zig").run(base);
    fixture.model = &state;
    // The shared owner must select only NVENC, without a GR or NVDEC channel.
    // Its submitted BOs remain resident across a logical encode timeout too.
    for ([_]bool{ false, true }) |timeout| {
        state = .{ .engine = .encode, .queue_timeout = timeout };
        budget.limit = 8 * 65536;
        ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = clock };
        try commands.system(&ctx, 216);
        try scratch.video(&ctx, 256);
        const loans = [_]gpu.Context.Loan{.{ .resource = &scratch, .write = true }};
        if (timeout) {
            try t.expectError(error.Timeout, ctx.submit(&commands, 216, &loans));
            try t.expectError(error.Busy, ctx.close());
            try t.expectError(error.Busy, scratch.close());
            try t.expectError(error.Busy, commands.close());
            try t.expectEqual(@as(usize, 2 * 65536), budget.liveBytes());
            state.queue_released = true;
        } else try ctx.submit(&commands, 216, &loans);
        try ctx.close();
        try scratch.close();
        try commands.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try state.clean();
    }
}

fn decoderChecks(base: r.program.Context, device: gpu.Device) !void {
    decoded = .{ .mode = .success };
    fixture.model.* = .{ .on_submit = &inspectDecode };
    var budget: Budget = .{ .limit = 32 * 1024 * 1024 };
    var decoder: Decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = clock } };
    const ops = decoder.ops();
    const seq: ff.struct_r4video_nvdec_sequence = .{ .profile = 66, .level = 31, .width_mbs = 4, .height_mbs = 4,
        .max_refs = 2, .log2_frame_num = 4, .poc_type = 0, .log2_poc_lsb = 4, .delta_poc_always_zero = 0, .direct_8x8 = 1 };
    var held: [5]?*anyopaque = @splat(null);
    var p = picture(seq, 0);
    held[0] = try decode(&ops, &p, 0);
    try t.expectEqual(@as(u32, 0), decoded.current_slot);
    const first_reference = decoder.describe(held[0]).?.backing.reference;
    p = picture(seq, 1);
    p.reference_count = 1;
    p.references[0] = .{ .image = held[0], .long_term = 0, .frame_index = 0, .poc = @splat(0) };
    held[1] = try decode(&ops, &p, 0);
    try t.expectEqual(@as(u32, 1), decoded.current_slot);
    p = picture(seq, 2);
    p.reference_count = 2;
    p.references[0] = .{ .image = held[0], .long_term = 0, .frame_index = 0, .poc = @splat(0) };
    p.references[1] = .{ .image = held[1], .long_term = 0, .frame_index = 1, .poc = @splat(2) };
    held[2] = try decode(&ops, &p, 0);
    try t.expectEqual(@as(u32, 2), decoded.current_slot);
    p = picture(seq, 3);
    p.reference_count = 2;
    p.references[0] = .{ .image = held[2], .long_term = 0, .frame_index = 2, .poc = @splat(4) };
    p.references[1] = .{ .image = held[1], .long_term = 0, .frame_index = 1, .poc = @splat(2) };
    held[3] = try decode(&ops, &p, 0);
    // Reordered DPB retains actual coloc positions, not the reference-list index.
    try t.expectEqual(@as(u32, 0), decoded.current_slot);
    try t.expectEqual([2]u32{ 2, 1 }, decoded.reference_slots);
    try t.expectEqual(first_reference, decoder.describe(held[0]).?.backing.reference);
    ops.release.?(ops.owner, held[0]);
    try decoder.reap();
    p = picture(seq, 4);
    p.reference_count = 2;
    p.references[0] = .{ .image = held[3], .long_term = 0, .frame_index = 3, .poc = @splat(6) };
    p.references[1] = .{ .image = held[2], .long_term = 0, .frame_index = 2, .poc = @splat(4) };
    held[4] = try decode(&ops, &p, 0);
    try t.expectEqual(@as(u32, 1), decoded.current_slot);
    try t.expectEqual([2]u32{ 0, 2 }, decoded.reference_slots);
    // Flush and close may retire scratch while the caller still holds images.
    decoder.flush();
    var resized = seq;
    resized.width_mbs = 6;
    fixture.model.retire_ready = false;
    p = picture(resized, 0);
    const new_size = try decode(&ops, &p, 0);
    try t.expectEqual(@as(u32, 96), decoder.describe(new_size).?.descriptor.width);
    try t.expectEqual(@as(u32, 64), decoder.describe(held[1]).?.descriptor.width);
    try t.expectError(error.Busy, decoder.close());
    for (held[1..]) |ptr| {
        try t.expect(decoder.describe(ptr) != null);
        ops.release.?(ops.owner, ptr);
    }
    ops.release.?(ops.owner, new_size);
    try decoder.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try fixture.model.clean();

    for ([_]@FieldType(@TypeOf(decoded), "mode"){ .missing, .corrupt }) |failure| {
        decoded = .{ .mode = failure };
        fixture.model.* = .{ .on_submit = &inspectDecode };
        decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = clock } };
        const callbacks = decoder.ops();
        p = picture(seq, 0);
        const ptr = try decode(&callbacks, &p, -6);
        try t.expect(decoder.describe(ptr) == null);
        callbacks.abort.?(callbacks.owner, ptr);
        callbacks.release.?(callbacks.owner, ptr);
        try decoder.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try fixture.model.clean();
    }
    // Begin can run out of budget after the image and some work BOs exist.
    // The copied callback owner must retain and retire every partial resource.
    decoded = .{ .mode = .success };
    fixture.model.* = .{ .on_submit = &inspectDecode };
    budget.limit = 4 * 65536;
    decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = clock } };
    const partial = decoder.ops();
    var image: ?*anyopaque = null;
    p = picture(seq, 0);
    try t.expectEqual(@as(c_int, 0), partial.allocate.?(partial.owner, &seq, &image));
    try t.expectEqual(@as(c_int, -4), partial.begin.?(partial.owner, image, &p));
    partial.abort.?(partial.owner, image);
    partial.release.?(partial.owner, image);
    try decoder.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try fixture.model.clean();
}

// Both media engines share these exact native BO/VA/fence owners. No modeled
// codec completion is counted as decoded pixels or a hardware qualification.
fn amdChecks(base: r.program.Context) !void {
    var state: Model = .{ .provider = .amd, .next_va = amd.native_va_start, .push_bytes = 64 };
    fixture.model = &state;
    const device = try gpu.Device.queryProvider(base, 9, .decode, .amd);
    try t.expectEqual(amd.vcn_1_0_0, device.class);
    try t.expectError(error.Unsupported, gpu.Device.queryProvider(base, 9, .decode, .nvidia));
    const h264 = try device.mediaCaps(1, 100, 8, 1);
    try t.expect(h264.dpb_slots == 17 and h264.active_references == 16 and h264.flags == amd.media_caps_source_profile);
    try t.expectEqual(@as(u32, 2), (try device.mediaCaps(2, 2, 10, 1)).format);
    try t.expectError(error.Unsupported, device.mediaCaps(7, 0, 8, 1)); // AV1
    try t.expectError(error.Unsupported, (try gpu.Device.queryFor(base, 9, .encode)).mediaCaps(2, 2, 10, 1));
    state.media_ready = false;
    try t.expectError(error.Unsupported, gpu.Device.queryFor(base, 9, .decode));
    try t.expectEqual(amd.gc_9_1_0, (try gpu.Device.queryFor(base, 9, .graphics)).class);
    state.media_ready = true;
    state.coherent = false;
    try t.expectError(error.Unsupported, gpu.Device.queryFor(base, 9, .encode));
    state.coherent = true;

    state.raven2 = true;
    const rv = try gpu.Device.queryProvider(base, 9, .decode, .amd);
    try t.expectEqual(amd.vcn_1_0_1, rv.class);
    try t.expectEqual(amd.gc_9_2_2, (try gpu.Device.queryFor(base, 9, .graphics)).class);
    try t.expectEqual(h264, try rv.mediaCaps(1, 100, 8, 1));
    try t.expectEqual(@as(u32, 2), (try rv.mediaCaps(2, 2, 10, 1)).format);
    state.wrong_amd_profile = true;
    try t.expectError(error.Unsupported, gpu.Device.queryFor(base, 9, .decode));
    state.wrong_amd_profile = false; state.raven2 = false;

    var budget: Budget = .{ .limit = 32 * 1024 * 1024 };
    var ctx: gpu.Context = .{ .base = base, .device = device, .budget = &budget, .clock = clock };
    var commands: gpu.Resource = .{};
    try commands.system(&ctx, 64);
    @memset((try commands.mappedBytes())[0..64], 0);
    const Pool = gpu.ImagePool(4);
    var pool: Pool = .{};
    const first = try pool.allocate(&ctx, 1920, 1080, 8, 1);
    try t.expectError(error.Invalid, pool.published(first));
    try t.expectError(error.Busy, pool.release(first, .codec));
    const first_resource = try pool.resource(first);
    try t.expect(first_resource.descriptor.modifier == 0 and first_resource.descriptor.format == a.gfx_buffer_format_nv12 and
        first_resource.descriptor.plane_pitches[0] == 2048 and first_resource.mapping.cpu_address == 0);
    try t.expectError(error.Unsupported, ctx.submit(&commands, 60, &.{}));
    try t.expectEqual(@as(u32, 0), state.queue_count); // rejected before opening anything
    try ctx.submit(&commands, 64, &.{.{ .resource = first_resource, .write = true }});
    try pool.finish(first, true);
    try pool.retain(first, .reference);
    try pool.retain(first, .consumer);
    try pool.release(first, .codec);
    const first_bo = (try pool.published(first)).backing;
    const second = try pool.allocate(&ctx, 1920, 1080, 8, 1);
    var references: [17]gpu.Context.Loan = undefined;
    const refs = try pool.references(&.{first}, 1, &references);
    try t.expectEqual(first_resource, refs[0].resource);
    try t.expect(!refs[0].write);
    try t.expectError(error.Stale, pool.references(&.{first}, 2, &references));
    try t.expectError(error.Invalid, pool.references(&.{first,first}, 1, &references));
    try ctx.submit(&commands, 64, &.{ .{ .resource = try pool.resource(second), .write = true }, refs[0], refs[0] });
    try t.expectEqual(@as(usize, 3), state.loan_count); // duplicate DPB loans coalesce
    try pool.finish(second, true);
    try pool.release(first, .reference);
    try pool.reap();
    try t.expectEqual(first_bo, (try pool.published(first)).backing); // display outlives DPB
    try pool.release(second, .codec);
    try pool.reap();
    const ten_bit = try pool.allocate(&ctx, 1280, 720, 10, 2);
    const p010 = try pool.resource(ten_bit);
    try t.expect(p010.descriptor.format == a.gfx_buffer_format_p010 and p010.descriptor.plane_pitches[0] == 2560 and
        p010.descriptor.plane_offsets[1] % 65536 == 0 and p010.mapping.cpu_address == 0);
    try t.expectError(error.Stale, pool.resource(second)); // generation/slot reuse
    try ctx.submit(&commands, 64, &.{.{ .resource = p010, .write = true }});
    try pool.finish(ten_bit, true);
    try pool.retain(ten_bit, .consumer);
    try pool.release(ten_bit, .codec);
    try t.expectError(error.Busy, pool.close());
    try t.expectEqual(first_bo, (try pool.published(first)).backing);
    try pool.release(first, .consumer);
    try pool.release(ten_bit, .consumer);
    try pool.close();
    try commands.close();
    try ctx.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try state.clean();

    // JPEG1 copies the IB on the driver CPU before VMID0 dispatch. A producer
    // write lease must be acknowledged away, including failed unmap retries.
    state = .{ .provider = .amd, .next_va = amd.native_va_start, .push_bytes = 512, .engine = .jpeg };
    ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .jpeg), .budget = &budget, .clock = clock };
    state.jpeg_ready = false;
    try t.expectError(error.Unsupported, gpu.Device.queryFor(base, 9, .jpeg));
    state.jpeg_ready = true;
    try commands.system(&ctx, 512);
    try t.expectError(error.Busy, ctx.submit(&commands, 512, &.{}));
    state.unmap_busy = true;
    try t.expectError(error.Busy, commands.suspendCpu());
    try t.expect((try commands.mappedBytes()).len >= 512);
    try t.expectError(error.Busy, ctx.submit(&commands, 512, &.{}));
    state.unmap_busy = false;
    for (0..2) |_| {
        try commands.resumeCpu();
        (try commands.mappedBytes())[0] = 0xa5;
        try commands.suspendCpu();
        try t.expectError(error.Busy, commands.mappedBytes());
        try ctx.submit(&commands, 512, &.{});
    }
    state.map_invalid = true;
    try t.expectError(error.Unsupported, commands.resumeCpu());
    try t.expectError(error.Busy, commands.mappedBytes());
    try commands.close();
    try ctx.close();
    try state.clean();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());

    for ([_]gpu.Engine{ .decode, .encode, .jpeg }) |engine| {
        state = .{ .provider = .amd, .next_va = amd.native_va_start, .push_bytes = 64, .engine = engine, .queue_timeout = true };
        ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, engine), .budget = &budget, .clock = clock };
        pool = .{};
        try commands.system(&ctx, 64);
        if (engine == .jpeg) try commands.suspendCpu();
        const token = try pool.allocate(&ctx, 64, 64, 8, 3);
        try t.expectError(error.Timeout, ctx.submit(&commands, 64, &.{.{ .resource = try pool.resource(token), .write = true }}));
        try t.expectError(error.Busy, commands.resumeCpu());
        try t.expectError(error.Busy, pool.finish(token, true));
        try pool.abort(token);
        try pool.release(token, .codec);
        const held = budget.liveBytes();
        try t.expectError(error.Busy, pool.close());
        try t.expectEqual(held, budget.liveBytes());
        try t.expectError(error.Busy, commands.close());
        try t.expectError(error.Busy, ctx.close());
        state.queue_released = true;
        try ctx.close();
        try pool.close();
        try commands.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try state.clean();
    }
    state = .{ .provider = .amd, .next_va = amd.native_va_start, .native_timeout = true };
    ctx = .{ .base = base, .device = device, .budget = &budget, .clock = clock };
    pool = .{};
    try t.expectError(error.Timeout, pool.allocate(&ctx, 64, 64, 8, 4));
    try pool.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try state.clean();
    std.debug.print("AMD media owners: NV12/P010, DPB/consumer holds, JPEG CPU handoff, provider admission and three engine timeout retirements: OK\n", .{});
}
