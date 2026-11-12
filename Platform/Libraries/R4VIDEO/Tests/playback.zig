// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const p = @import("playback");
const v = p.video;
const g = @import("r4gfx_binding");
const r4os = @import("r4os");
const a = r4os.abi;

pub fn run() !void {
    var clock = p.timing.Clock.init(100, -1000);
    try t.expectEqual(-900, try clock.position(200));
    try clock.setPaused(200, true);
    try t.expectEqual(-900, try clock.position(1000));
    try clock.setPaused(2000, false);
    try t.expectEqual(-800, try clock.position(2100));
    try t.expectError(error.ClockRegression, clock.position(2099));
    try clock.seek(2200, 10000);
    try t.expectEqual(10100, try clock.position(2300));
    try t.expectEqual(99999999000, try p.timing.sampleTime(-1000, 4_410_000, 44100));
    clock = p.timing.Clock.init(0, std.math.maxInt(i64));
    try t.expectError(error.Overflow, clock.position(1));
    try Model.check();
    try AudioModel.check();
}
const AudioModel = struct {
    var calls: usize = 0;
    var accepted: usize = 0;
    var closes: usize = 0;
    var fail_write = false;
    var missing = false;
    var lost = false;
    var expected: [1920]u8 = undefined;
    fn open(_: [*:0]const u8, output: *a.ServiceInfo) callconv(.c) i32 {
        if (missing) return -1;
        output.* = .{ .handle = 1 }; return 0;
    }
    fn close(_: u32) callconv(.c) i32 { return 0; }
    fn clock(output: *a.MonotonicClockInfo) callconv(.c) i32 {
        output.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = 1,
            .frequency_hz = a.monotonic_clock_frequency_hz, .resolution_ns = 1,
            .instant_ns = 1_000_000_000, .event_requested_hz = 1000, .event_effective_hz = 1000 }; return 1;
    }
    fn call(_: u32, op: u16, bytes: [*]const u8, len: u32, header: *a.ServiceMessageHeader, response: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
        std.debug.assert(capacity >= @sizeOf(a.AudioServiceStreamResult));
        calls += 1;
        if (lost) return a.service_api_result_not_running;
        var result: a.AudioServiceStreamResult = .{ .action = op, .stream_id = 7 };
        switch (op) {
            a.audio_service_op_open_stream => { result.result = @intCast(result.stream_id); },
            a.audio_service_op_write_stream => {
                const data = bytes[@sizeOf(a.AudioServiceStreamWriteRequest)..len];
                std.debug.assert(std.mem.eql(u8, data, expected[accepted..][0..data.len]));
                if (fail_write) return a.service_api_result_timeout;
                const count = @min(data.len, 400); // deliberately short reply
                accepted += count;
                result.result = @intCast(count); result.bytes = @intCast(count);
            },
            a.audio_service_op_close_stream => {
                closes += 1;
                if (closes == 1) result.result = a.service_api_result_busy;
            },
            else => unreachable,
        }
        @memcpy(response[0..@sizeOf(@TypeOf(result))], std.mem.asBytes(&result));
        header.* = .{ .op = op, .status = 0, .payload_len = @sizeOf(@TypeOf(result)) };
        return @sizeOf(@TypeOf(result));
    }
    fn check() !void {
        var table: a.R4XStartR4Sys = .{};
        table.service_open = @intFromPtr(&open); table.service_close = @intFromPtr(&close);
        table.service_call = @intFromPtr(&call); table.monotonic_clock = @intFromPtr(&clock);
        const bundle: r4os.program.Bundle = .{ .raw = undefined, .sys = &table };
        try checkBase(r4os.program.Context.initBundle(&bundle));
        const a2 = r4os.platform2.abi;
        var table2: a2.R4XStartR4Sys2 = .{};
        table2.service_open = @intFromPtr(&open); table2.service_close = @intFromPtr(&close);
        table2.service_call = @intFromPtr(&call); table2.monotonic_clock = @intFromPtr(&clock);
        var imports = [_]a2.R4XStartImport{.{ .group_id = 1, .resolved_version = a2.query_version, .table = @intFromPtr(&table2) }};
        var raw: a2.R4XStartContext2 = .{ .imports = @intFromPtr(&imports), .import_count = imports.len };
        const caller = try r4os.platform2.Context.init(&raw);
        try checkBase(.{ .generation2 = &caller });
    }
    fn checkBase(base: r4os.program.Context) !void {
        calls = 0; accepted = 0; closes = 0; fail_write = false; missing = false; lost = false;
        const api: r4os.app_audio.Audio = .{ .sys = .{ .base = base }, .raw = .{ .base = base } };
        var storage: [1920]u8 = undefined;
        for (&expected, 0..) |*byte, i| byte.* = @truncate(i * 137 + 19);
        var owner = try p.audio.Audio.init(api, &storage, 48000, 2);
        try t.expectEqual(1920, try owner.feed(1, 0, &expected));
        owner.step(0, false); // open, no write in same event-loop turn
        try t.expect(calls == 1 and accepted == 0 and owner.state == .active);
        for (0..5) |_| {
            const previous = calls;
            owner.step(0, false);
            try t.expect(calls == previous + 1);
        }
        try t.expect(accepted == 1920 and owner.count == 0);
        try t.expectEqual(1920, try owner.feed(1, 20000000, &expected));
        const previous = calls;
        owner.step(0, false); try t.expect(calls == previous); // not due yet
        try owner.reset(2, true);
        owner.step(0, false);
        try t.expect(owner.state == .closing and owner.stream != null);
        try t.expectError(error.Stale, owner.feed(1, 0, &expected));
        owner.step(0, false);
        try t.expect(owner.state == .ready and owner.stream == null and owner.count == 0);
        accepted = 0; fail_write = true;
        _ = try owner.feed(2, 0, &expected);
        owner.step(0, false); owner.step(0, false);
        try t.expect(owner.state == .closing and accepted == 0 and owner.count == 0);
        owner.step(0, false);
        try t.expect(owner.state == .degraded and owner.stream == null);
        // A service death invalidates the connection; close must not wait on
        // it forever or recreate a stream while acknowledging the old one.
        fail_write = false;
        try owner.reset(3, true);
        _ = try owner.feed(3, 0, &expected);
        owner.step(0, false);
        lost = true;
        owner.close();
        const before_loss = calls;
        owner.step(0, false);
        try t.expect(calls == before_loss + 1 and owner.state == .closed and owner.stream == null);
        owner.step(0, false);
        try t.expectEqual(before_loss + 1, calls);
        lost = false;
        // Missing audio remains a degraded independent path. No retries in an
        // event-loop spin and no conversion of accepted bytes into clock time.
        missing = true; fail_write = false;
        try owner.reset(4, true); _ = try owner.feed(4, 0, &expected);
        owner.step(0, false);
        try t.expect(owner.state == .degraded and owner.stream == null);
        owner.close(); try t.expect(owner.state == .closed);
        std.debug.print("media audio: one-call partial writes, bounded lead, seek close ACK, uncertain writes, service death and no service: OK\n", .{});
    }
};
const policy: p.composition.ColorPolicy = .{ .reference_white = 1000000, .peak = 1000000 };
const transform: g.R4GfxColorTransform = .{ .version = 1, .size = @sizeOf(g.R4GfxColorTransform),
    .source_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }, .target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 },
    .sampler = 0, .operation = g.render_operation_blit, .opacity = 65535, .flags = 0, .pixel_budget = 16 };
const Model = struct {
    var table: a.R4XStartR4Draw = undefined;
    var bundle: r4os.program.Bundle = undefined;
    var video_table: v.VideoV1 = undefined;
    var graphics_table: g.DeviceV1 = undefined;
    var color_table: g.ColorV1 = undefined;
    var pixels: [3][128]u8 = @splat(@splat(128));
    var output_pixels: [64]u8 = @splat(0);
    var generation: u64 = 1;
    var pending: u64 = 0;
    var operation: u32 = 0;
    var completed: u64 = 0;
    var phase: u32 = v.phase_open;
    var frames: usize = 0;
    var leases: usize = 0;
    var maps: usize = 0;
    var converted: usize = 0;
    var released: usize = 0;
    var release_attempts: [16]u8 = @splat(0);
    var unmap_allowed = true;
    var closed = false;
    var job_active = false;
    var job_ack = false;
    var job_physical = false;
    var job_released = false;
    var submit_busy: u32 = 0;
    var receive_error: i32 = 0;
    var maps_ever: usize = 0;
    fn reset() void {
        generation = 1; pending = 0; operation = 0; completed = 0; phase = v.phase_open;
        frames = 0; leases = 0; maps = 0; converted = 0; released = 0; closed = false;
        release_attempts = @splat(0); unmap_allowed = true;
        job_active = false; job_ack = false; job_physical = false; job_released = false;
        submit_busy = 0; receive_error = 0; maps_ever = 0;
    }
    fn query(_: *const v.R4VideoRuntime, input: *const v.R4VideoCapsQuery, _: *v.R4VideoCaps) callconv(.c) i32 {
        return if (input.backend != v.backend_software) v.error_unsupported else v.ok;
    }
    fn create(_: *const v.R4VideoRuntime, input: *const v.R4VideoConfig, output: *v.R4VideoDecoder) callconv(.c) i32 {
        std.debug.assert(input.query.backend == v.backend_software);
        output.* = .{ .address = 1, .generation = 1 }; return v.ok;
    }
    fn send(_: *const v.R4VideoDecoder, input: *const v.R4VideoPacket) callconv(.c) i32 {
        if (input.stream_generation != generation) return v.error_stale;
        frames += 1; return v.ok;
    }
    fn receive(_: *const v.R4VideoDecoder, output: *v.R4VideoFrame) callconv(.c) i32 {
        if (receive_error != 0) return receive_error;
        if (frames == 0) return if (phase == v.phase_drained) v.eos else v.again;
        output.* = frame(released + leases + 1);
        leases += 1; frames -= 1; return v.ok;
    }
    fn release(lease: *const v.R4VideoLease, receipt: *const v.R4VideoReceipt) callconv(.c) i32 {
        // The GFX job owns its fence; VIDEO receives an empty receipt only
        // after its final CPU map/physical job use has retired.
        std.debug.assert(maps == 0 and !job_active and std.meta.eql(receipt.fence, std.mem.zeroes(v.R4VideoFence)));
        const index: usize = @intCast(lease.token);
        release_attempts[index] += 1;
        if (release_attempts[index] == 1) return v.again;
        leases -= 1; released += 1; return v.ok;
    }
    fn control(_: *const v.R4VideoDecoder, input: *const v.R4VideoControl, output: *v.R4VideoState) callconv(.c) i32 {
        if (input.operation != v.control_query) {
            if (pending != 0 and pending != input.request_id) return v.error_busy;
            pending = input.request_id; operation = input.operation;
        } else if (pending != 0 and (operation != v.control_close or leases == 0)) {
            completed = pending; pending = 0;
            switch (operation) {
                v.control_flush => { generation += 1; frames = 0; phase = v.phase_open; },
                v.control_drain => { phase = v.phase_drained; },
                v.control_close => { phase = v.phase_closed; },
                else => unreachable,
            }
        }
        output.* = std.mem.zeroes(v.R4VideoState);
        output.version = 1; output.size = @sizeOf(v.R4VideoState);
        output.stream_generation = generation; output.pending_request = pending;
        output.completed_request = completed; output.phase = phase; output.leased_frames = @intCast(leases);
        return v.ok;
    }
    fn destroy(_: *const v.R4VideoDecoder) callconv(.c) i32 {
        std.debug.assert(leases == 0 and maps == 0 and !job_active and phase == v.phase_closed);
        closed = true; return v.ok;
    }
    fn frame(token: usize) v.R4VideoFrame {
        var result = std.mem.zeroes(v.R4VideoFrame);
        result.version = 1; result.size = @sizeOf(v.R4VideoFrame);
        result.lease = .{ .decoder = .{ .address = 1, .generation = 1 }, .token = token, .stream_generation = generation };
        result.coded_width = 4; result.coded_height = 4; result.crop_width = 4; result.crop_height = 4;
        result.sar_num = 1; result.sar_den = 1; result.format = v.format_yuv420p; result.plane_count = 3;
        result.color = .{ .version = 1, .size = @sizeOf(v.R4VideoColor), .primaries = 1, .transfer = 1, .matrix = 1,
            .range = 2, .chroma_location = 1, .bit_depth = 8, .reference_white = 0, .peak = 0, .black = 0, .flags = 0 };
        const planes = [_]*v.R4VideoPlane{ &result.plane0, &result.plane1, &result.plane2 };
        for (planes, 0..) |plane, i| plane.* = .{ .buffer = .{ .id = @intCast(i+1), .reserved0 = 0, .generation = 1 },
            .reference = .{ .id = @intCast(i+1), .reserved0 = 0, .generation = 1 }, .offset = 0,
            .pitch = 32, .row_bytes = if (i == 0) 4 else 2, .rows = if (i == 0) 4 else 2, .reserved = 0 };
        result.flags = v.packet_pts | v.packet_duration;
        result.duration_ns = 1000000;
        return result;
    }
    fn describe(reference: *const a.GfxBufferHandle, output: *a.GfxBufferDescriptor) callconv(.c) i32 {
        if (reference.id < 1 or reference.id > 3) return a.gfx_buffer_error_stale;
        output.* = .{ .byte_length = 128, .alignment = 4096, .usage = a.gfx_buffer_usage_cpu_read,
            .location = a.gfx_buffer_location_system };
        return a.gfx_buffer_result_ok;
    }
    fn map(reference: *const a.GfxBufferHandle, _: u32, _: u64, _: u64, output: *a.GfxBufferMap) callconv(.c) i32 {
        maps += 1; maps_ever += 1;
        output.* = .{ .lease = reference.*, .cpu_address = @intFromPtr(&pixels[reference.id-1]), .byte_length = 128 };
        return a.gfx_buffer_result_ok;
    }
    fn unmap(_: *const a.GfxBufferHandle) callconv(.c) i32 {
        if (!unmap_allowed) return a.gfx_buffer_error_busy;
        maps -= 1; return a.gfx_buffer_result_ok;
    }
    fn convert(input: *const g.R4GfxYuvImage, target: *const g.R4GfxColorImage, _: *const g.R4GfxColorTransform, _: *g.R4GfxCpuStats) callconv(.c) i32 {
        std.debug.assert(maps == 3 and input.description.reference_white == 1000000 and input.description.matrix == 1);
        @memset(@as([*]u8, @ptrFromInt(target.image.cpu_address))[0..64], 0x55);
        converted += 1; return g.status_ok;
    }
    fn submit(_: *const g.R4GfxDevice, _: *const g.R4GfxYuvRenderRequest, output: *g.R4GfxJob) callconv(.c) i32 {
        if (submit_busy != 0) { submit_busy -= 1; return g.status_busy; }
        std.debug.assert(!job_active and maps == 0);
        output.* = std.mem.zeroes(g.R4GfxJob); output.slot = 1; output.generation = 1;
        job_active = true; return g.status_ok;
    }
    fn jobInfo(_: *const g.R4GfxDevice, _: *const g.R4GfxJob, output: *g.R4GfxJobInfo) callconv(.c) i32 {
        output.* = std.mem.zeroes(g.R4GfxJobInfo);
        output.phase = if (job_ack) a.gfx_queue_phase_terminal else a.gfx_queue_phase_running;
        output.result = a.gfx_queue_result_complete;
        output.flags = if (job_physical) 0 else a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held;
        return g.status_ok;
    }
    fn jobCancel(_: *const g.R4GfxDevice, _: *const g.R4GfxJob) callconv(.c) i32 { return g.status_ok; }
    fn jobRelease(_: *const g.R4GfxDevice, _: *const g.R4GfxJob) callconv(.c) i32 {
        std.debug.assert(job_ack and job_physical and job_active); job_active = false; job_released = true; return g.status_ok;
    }
    fn check() !void {
        reset();
        table = .{};
        table.gfx_buffer_describe = @intFromPtr(&describe); table.gfx_buffer_map = @intFromPtr(&map); table.gfx_buffer_unmap = @intFromPtr(&unmap);
        bundle = .{ .raw = undefined, .draw = &table };
        video_table = undefined;
        video_table.header = v.video_v1_header; video_table.query_caps = query; video_table.create = create;
        video_table.send = send; video_table.receive = receive; video_table.release = release;
        video_table.control = control; video_table.destroy = destroy;
        graphics_table = undefined; graphics_table.header = g.device_v1_header;
        graphics_table.job_info = jobInfo; graphics_table.job_cancel = jobCancel; graphics_table.job_release = jobRelease;
        color_table = undefined; color_table.header = g.color_v1_header;
        color_table.color_yuv_image_transform = convert; color_table.color_yuv_render_submit = submit;
        const base = r4os.program.Context.initBundle(&bundle);
        var compositor: p.composition.Composition = .{ .buffers = .{ .base = base }, .queues = .{ .base = base },
            .color = .{ .header = &color_table.header }, .graphics = .{ .header = &graphics_table.header }, .device = std.mem.zeroes(g.R4GfxDevice) };
        const config: p.Config = .{ .decoder = .{ .version = 1, .size = @sizeOf(v.R4VideoConfig),
            .query = .{ .version = 1, .size = @sizeOf(v.R4VideoCapsQuery), .backend = v.backend_nvidia, .adapter_id = 1,
                .codec = v.codec_h264, .profile = 66, .bit_depth = 8, .chroma = v.chroma_420 },
            .memory_limit = 1024*1024, .max_width = 64, .max_height = 48, .pending_packets = 3, .frame_leases = 3, .threads = 1, .flags = 0 }, .color = policy };
        var amd_config = config;
        amd_config.decoder.query.backend = v.backend_amd;
        amd_config.allow_software_fallback = false;
        try t.expectError(error.Unsupported, p.Session.init(.{ .header = &video_table.header }, .{ .address = 1, .generation = 1 }, &compositor, null, amd_config, 100, 0));
        amd_config.allow_software_fallback = true;
        const amd_fallback = try p.Session.init(.{ .header = &video_table.header }, .{ .address = 1, .generation = 1 }, &compositor, null, amd_config, 100, 0);
        try t.expectEqual(v.backend_software, amd_fallback.backend);
        var session = try p.Session.init(.{ .header = &video_table.header }, .{ .address = 1, .generation = 1 }, &compositor, null, config, 100, 0);
        try t.expect(session.backend == v.backend_software);
        var target = std.mem.zeroes(g.R4GfxColorImage);
        target.image.cpu_address = @intFromPtr(&output_pixels);
        const destination: p.composition.Target = .{ .cpu = target };
        frames = 1;
        var displayed: usize = 0;
        for (0..24) |_| {
            const step = session.step(100, destination, transform);
            if (step.output) |output| { try t.expect(output.display and output.pts_ns == 0); displayed += 1; }
        }
        try t.expect(displayed == 1 and converted == 1 and released == 1 and leases == 0 and maps == 0);
        // Pausing does not advance media time; Flush requires a producer seek
        // handshake and stale-generation input is rejected before dispatch.
        try session.pause(1000);
        for (0..12) |_| _ = session.step(1000, null, transform);
        try t.expect(session.seek_ready and session.generation == 2);
        try session.repositioned(2000);
        try t.expect(session.phase == .paused and try session.clock.position(3000) == 900);
        try session.resumePlaying(3000);
        var packet = std.mem.zeroes(v.R4VideoPacket); packet.stream_generation = 1;
        try t.expect(session.send(&packet) == v.error_stale);
        // Seek while a composed CPU image cannot yet unmap retains its frame.
        frames = 1; unmap_allowed = false;
        for (0..12) |_| _ = session.step(3000, destination, transform);
        try t.expect(maps == 3 and leases == 1);
        try session.seek(3000, 1000000, false);
        for (0..12) |_| _ = session.step(3000, null, transform);
        try t.expect(maps == 3 and leases == 1);
        unmap_allowed = true;
        for (0..15) |_| {
            const step = session.step(3000, null, transform);
            if (step.output) |output| try t.expect(!output.display);
        }
        try t.expect(leases == 0 and maps == 0);
        try session.repositioned(4000);
        session.close(4000);
        for (0..15) |_| _ = session.step(4000, null, transform);
        try t.expect(closed and session.phase == .closed);
        // GPU composition cannot release a VIDEO lease at logical completion.
        reset();
        session = try p.Session.init(.{ .header = &video_table.header }, .{ .address = 1, .generation = 1 }, &compositor, null, config, 100, 0);
        frames = 1; submit_busy = 2;
        const gpu_target: p.composition.Target = .{ .gpu = std.mem.zeroes(g.R4GfxResource) };
        for (0..24) |_| _ = session.step(100, gpu_target, transform);
        try t.expect(job_active and leases == 1 and released == 0 and maps_ever == 0);
        session.close(100);
        job_ack = true;
        for (0..12) |_| _ = session.step(100, null, transform);
        try t.expect(job_active and leases == 1 and !closed);
        job_physical = true;
        for (0..24) |_| {
            const step = session.step(100, null, transform);
            if (step.output) |output| try t.expect(!output.display);
        }
        try t.expect(job_released and leases == 0 and closed and session.phase == .closed);
        // Decoder error is reported without stopping cleanup or changing time.
        reset();
        session = try p.Session.init(.{ .header = &video_table.header }, .{ .address = 1, .generation = 1 }, &compositor, null, config, 100, 0);
        receive_error = v.error_decode;
        const failure = session.step(200, null, transform);
        try t.expect(failure.phase == .failed and failure.media_ns == 100 and session.last_error == v.error_decode);
        session.close(200);
        for (0..12) |_| _ = session.step(200, null, transform);
        try t.expect(session.phase == .closed);
        std.debug.print("media host: clock, explicit fallback, pause/seek, CPU maps, GPU retirement and decoder failure: OK\n", .{});
    }
};
