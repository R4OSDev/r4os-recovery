// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Compiled media-host facade over public VIDEO_V1, COLOR_V1 and App-Audio.
//! The caller owns demux/PCM decode, file seeking, target presentation and the
//! event loop. No hidden thread, sleep loop, RGB staging buffer or audio clock.
const std = @import("std");
pub const video = @import("r4video.zig");
const v = video;
const g = @import("r4gfx_binding");
pub const timing = @import("playback_clock.zig");
pub const audio = @import("playback_audio.zig");
pub const composition = @import("playback_composition.zig");
pub const Phase = enum { playing, paused, seeking, draining, ended, failed, closing, closed };
pub const Error = error{ Invalid, Busy, Stale, Failed, Unsupported, ClockRegression, Overflow };
pub const Config = struct {
    decoder: v.R4VideoConfig,
    allow_software_fallback: bool = true,
    color: composition.ColorPolicy,
    late_ns: u64 = 100 * std.time.ns_per_ms,
    render_ahead_ns: u64 = 5 * std.time.ns_per_ms,
    work_timeout_ns: u64 = 2 * std.time.ns_per_s,
    /// Zero rejects frames without PTS. A demuxer may explicitly supply a
    /// constant cadence for an elementary stream which has no timestamps.
    missing_pts_duration_ns: u64 = 0,
};
pub const Output = struct {
    target: composition.Target,
    pts_ns: i64,
    duration_ns: u64,
    stream_generation: u64,
    display: bool,
    result: i32,
};
pub const FrameInfo = struct {
    coded_width: u32,
    coded_height: u32,
    crop: g.R4GfxRect,
    sar_num: u32,
    sar_den: u32,
    pts_ns: i64,
    color: v.R4VideoColor,
};
pub const Step = struct {
    phase: Phase,
    media_ns: i64,
    output: ?Output = null,
    target_accepted: bool = false,
    /// After Flush, seek the demuxer to a preceding random-access point and
    /// acknowledge repositioning. Decode/preroll then skips frames before here.
    reposition_ns: ?i64 = null,
    audio_degraded: bool = false,
};
const Slot = struct {
    order: u64 = 0,
    frame: v.R4VideoFrame = undefined,
    ticket: ?composition.Ticket = null,
    target: ?composition.Target = null,
    returning: bool = false,
    receipt: v.R4VideoReceipt = .{ .version = 1, .size = @sizeOf(v.R4VideoReceipt), .fence = std.mem.zeroes(v.R4VideoFence), .result = 0, .reserved = 0 },
};
const Control = struct { operation: u32, id: u64, deadline: u64, accepted: bool = false };
pub const Session = struct {
    api: v.VideoV1Client,
    runtime: v.R4VideoRuntime,
    decoder: v.R4VideoDecoder,
    config: Config,
    compositor: *composition.Composition,
    sound: ?*audio.Audio = null,
    clock: timing.Clock,
    phase: Phase = .playing,
    backend: u32,
    generation: u64 = 1,
    control_serial: u64 = 0,
    control_pending: ?Control = null,
    close_requested: bool = false,
    decoder_closed: bool = false,
    order: u64 = 0,
    slots: [3]Slot = @splat(.{}),
    cursor: usize = 0,
    last_error: i32 = 0,
    seek_ns: i64,
    seek_ready: bool = false,
    seek_paused: bool = false,
    next_pts_ns: i64,
    input_eos: bool = false,
    output_eos: bool = false,

    /// Admission may block while VIDEO_V1 reserves workers; call outside the
    /// desktop's paint path. Runtime/provider lifetime remains caller-owned.
    pub fn init(api: v.VideoV1Client, runtime: v.R4VideoRuntime, compositor: *composition.Composition, sound: ?*audio.Audio, config: Config, now: u64, position: i64) Error!Session {
        if (config.decoder.frame_leases < 3 or config.work_timeout_ns == 0 or config.work_timeout_ns > 60 * std.time.ns_per_s or
            config.render_ahead_ns > std.time.ns_per_s or config.late_ns > 10 * std.time.ns_per_s) return error.Invalid;
        var chosen = config.decoder;
        var caps: v.R4VideoCaps = undefined;
        var rc = api.query_caps(&runtime, &chosen.query, &caps);
        if (rc == v.error_unsupported and config.allow_software_fallback and (chosen.query.backend == v.backend_nvidia or chosen.query.backend == v.backend_amd)) {
            chosen.query.backend = v.backend_software; chosen.query.adapter_id = 0;
            rc = api.query_caps(&runtime, &chosen.query, &caps);
        }
        if (rc != v.ok) return if (rc == v.error_unsupported) error.Unsupported else error.Failed;
        var decoder: v.R4VideoDecoder = undefined;
        rc = api.create(&runtime, &chosen, &decoder);
        if (rc != v.ok) return if (rc == v.error_unsupported) error.Unsupported else error.Failed;
        return .{ .api = api, .runtime = runtime, .decoder = decoder, .compositor = compositor, .sound = sound,
            .config = config, .backend = chosen.query.backend, .clock = timing.Clock.init(now, position),
            .seek_ns = position, .next_pts_ns = position };
    }
    pub fn send(self: *Session, packet: *const v.R4VideoPacket) i32 {
        if (self.phase != .playing and self.phase != .paused) return v.error_busy;
        if (self.input_eos or self.control_pending != null) return v.error_busy;
        if (packet.stream_generation != self.generation) return v.error_stale;
        return self.api.send(&self.decoder, packet);
    }
    pub fn pcm(self: *Session, epoch: u64, pts: i64, bytes: []const u8) Error!usize {
        if (self.phase != .playing and self.phase != .paused and self.phase != .draining) return error.Busy;
        const sound = self.sound orelse return error.Unsupported;
        return sound.feed(epoch, pts, bytes);
    }
    fn queueControl(self: *Session, operation: u32, now: u64) Error!void {
        if (self.control_pending != null) return error.Busy;
        const id = std.math.add(u64, self.control_serial, 1) catch return error.Overflow;
        const deadline = std.math.add(u64, now, self.config.work_timeout_ns) catch return error.Overflow;
        self.control_serial = id;
        self.control_pending = .{ .operation = operation, .id = id, .deadline = deadline };
    }
    pub fn drain(self: *Session, now: u64) Error!void {
        if (self.phase != .playing or self.input_eos) return error.Busy;
        try self.queueControl(v.control_drain, now);
        self.input_eos = true;
        self.phase = .draining;
    }
    pub fn seek(self: *Session, now: u64, position: i64, paused: bool) Error!void {
        if (self.phase == .closing or self.phase == .closed or self.phase == .seeking or self.phase == .failed) return error.Busy;
        _ = try self.clock.position(now);
        if (self.sound) |sound| if (sound.epoch == std.math.maxInt(u64)) return error.Overflow;
        try self.queueControl(v.control_flush, now);
        try self.clock.setPaused(now, true);
        try self.clock.seek(now, position);
        self.seek_ns = position; self.seek_paused = paused; self.seek_ready = false;
        self.phase = .seeking;
        if (self.sound) |sound| try sound.reset(sound.epoch + 1, !paused);
    }
    /// AUDSVC has no pause/cursor API. Pause therefore uses the same explicit
    /// demux reposition handshake as Seek, including discarding submitted PCM.
    pub fn pause(self: *Session, now: u64) Error!void {
        if (self.phase != .playing) return error.Busy;
        const position = try self.clock.position(now);
        try self.seek(now, position, true);
    }
    pub fn resumePlaying(self: *Session, now: u64) Error!void {
        if (self.phase != .paused) return error.Busy;
        if (self.sound) |sound| {
            if (sound.state == .closing) return error.Busy;
            if (sound.state == .disabled) sound.state = .ready;
        }
        try self.clock.setPaused(now, false);
        self.phase = .playing;
    }
    pub fn repositioned(self: *Session, now: u64) Error!void {
        if (self.phase != .seeking or !self.seek_ready or self.hasFrames()) return error.Busy;
        if (self.sound) |sound| if (sound.state == .closing) return error.Busy;
        try self.clock.seek(now, self.seek_ns);
        try self.clock.setPaused(now, self.seek_paused);
        self.next_pts_ns = self.seek_ns;
        self.input_eos = false; self.output_eos = false; self.seek_ready = false;
        self.phase = if (self.seek_paused) .paused else .playing;
    }
    pub fn close(self: *Session, now: u64) void {
        if (self.phase == .closed) return;
        self.close_requested = true;
        self.phase = .closing;
        self.clock.setPaused(now, true) catch {};
        if (self.sound) |sound| sound.close();
    }
    fn fail(self: *Session, result: i32) void {
        if (self.last_error == 0) self.last_error = result;
        if (!self.close_requested) self.phase = .failed;
        if (self.sound) |sound| sound.close();
    }
    fn hasFrames(self: *const Session) bool {
        for (&self.slots) |*slot| if (slot.order != 0) return true;
        return false;
    }
    /// Metadata for the next composition transition; no decoder lease is
    /// transferred. Choose a target/viewport from the actual new dimensions.
    /// Existing in-flight frames retain their independent old-size targets.
    pub fn pendingFrame(self: *const Session) ?FrameInfo {
        const slot = &self.slots[self.cursor];
        if (slot.order == 0 or slot.returning or slot.ticket != null) return null;
        const frame = &slot.frame;
        return .{ .coded_width = frame.coded_width, .coded_height = frame.coded_height,
            .crop = .{ .x = frame.crop_x, .y = frame.crop_y, .width = frame.crop_width, .height = frame.crop_height },
            .sar_num = frame.sar_num, .sar_den = frame.sar_den, .pts_ns = frame.pts_ns, .color = frame.color };
    }
    fn controlStep(self: *Session, now: u64) void {
        if (self.close_requested and !self.decoder_closed and self.control_pending == null)
            self.queueControl(v.control_close, now) catch { self.fail(v.error_internal); return; };
        const pending = if (self.control_pending) |*value| value else return;
        var state: v.R4VideoState = undefined;
        const request: v.R4VideoControl = .{ .version = 1, .size = @sizeOf(v.R4VideoControl),
            .request_id = if (pending.accepted) 0 else pending.id,
            .operation = if (pending.accepted) v.control_query else pending.operation, .reserved = 0 };
        const rc = self.api.control(&self.decoder, &request, &state);
        if (rc == v.error_busy or rc == v.again) {
            if (now >= pending.deadline) {
                if (!pending.accepted) self.control_pending = null;
                self.fail(v.error_internal);
            }
            return;
        }
        if (rc != v.ok) { self.control_pending = null; self.fail(rc); return; }
        pending.accepted = true;
        if (state.completed_request != pending.id) {
            // Keep the accepted control reachable after timeout. Close waits
            // for its acknowledgement instead of abandoning the worker owner.
            if (now >= pending.deadline) self.fail(v.error_internal);
            return;
        }
        const operation = pending.operation;
        self.control_pending = null;
        if (operation == v.control_close) {
            if (state.phase == v.phase_closed) self.decoder_closed = true else self.fail(v.error_internal);
        } else if (state.phase == v.phase_failed or state.last_error != 0) {
            self.fail(if (state.last_error != 0) state.last_error else v.error_decode);
        } else if (operation == v.control_flush) {
            if (state.stream_generation <= self.generation) { self.fail(v.error_stale); return; }
            self.generation = state.stream_generation;
            self.seek_ready = true;
        }
    }
    fn discard(self: *const Session) bool {
        return self.phase == .seeking or self.phase == .failed or self.close_requested;
    }
    fn firstDisplay(self: *const Session, order: u64) bool {
        for (&self.slots) |*slot| if (slot.order != 0 and slot.order < order and !slot.returning) return false;
        return true;
    }
    fn frameStep(self: *Session, now: u64, media: i64, target: ?composition.Target, transform: g.R4GfxColorTransform, output: *Step) void {
        const slot = &self.slots[self.cursor];
        self.cursor = (self.cursor + 1) % self.slots.len;
        if (slot.order == 0) return;
        if (slot.returning) {
            const rc = self.api.release(&slot.frame.lease, &slot.receipt);
            if (rc == v.ok) slot.* = .{} else if (rc != v.again and rc != v.error_busy) self.fail(rc);
            return;
        }
        const stale = self.discard() or slot.frame.lease.stream_generation != self.generation;
        if (slot.ticket) |ticket| {
            if (stale) self.compositor.cancel(ticket) catch {};
            const state = self.compositor.poll(ticket, now) catch { self.fail(v.error_device_lost); return; };
            if (state != .ready and state != .failed) return;
            if (!stale and state == .ready and (!self.firstDisplay(slot.order) or media < slot.frame.pts_ns or self.clock.paused)) return;
            const result = self.compositor.result(ticket) catch { self.fail(v.error_internal); return; };
            self.compositor.release(ticket) catch { self.fail(v.error_internal); return; };
            slot.ticket = null;
            slot.returning = true;
            slot.receipt.result = if (result == 0 or stale) 0 else v.error_device_lost;
            output.output = .{ .target = slot.target.?, .pts_ns = slot.frame.pts_ns, .duration_ns = slot.frame.duration_ns,
                .stream_generation = slot.frame.lease.stream_generation, .display = !stale and state == .ready, .result = result };
            if (state == .failed and !stale) self.fail(if (result == g.status_unsupported) v.error_unsupported else v.error_device_lost);
            return;
        }
        const end: i128 = @as(i128, slot.frame.pts_ns) + slot.frame.duration_ns;
        const preroll = if (slot.frame.duration_ns == 0) slot.frame.pts_ns < self.seek_ns else end <= self.seek_ns;
        if (stale or preroll or end + self.config.late_ns < media) { slot.returning = true; return; }
        if (self.clock.paused or @as(i128, slot.frame.pts_ns) > @as(i128, media) + self.config.render_ahead_ns) return;
        const destination = target orelse return;
        const deadline = std.math.add(u64, now, self.config.work_timeout_ns) catch { self.fail(v.error_internal); return; };
        slot.ticket = self.compositor.submit(slot.frame, destination, transform, self.config.color, deadline) catch |err| {
            if (err != error.Busy) { slot.returning = true; self.fail(if (err == error.Unsupported) v.error_unsupported else v.error_internal); }
            return;
        };
        slot.target = destination;
        output.target_accepted = true;
    }
    fn receiveStep(self: *Session) void {
        if ((self.phase != .playing and self.phase != .draining) or self.output_eos) return;
        const slot = for (&self.slots) |*entry| { if (entry.order == 0) break entry; } else return;
        if (self.order == std.math.maxInt(u64)) { self.fail(v.error_internal); return; }
        var frame: v.R4VideoFrame = undefined;
        const rc = self.api.receive(&self.decoder, &frame);
        if (rc == v.again or rc == v.error_busy) return;
        if (rc == v.eos) { self.output_eos = true; return; }
        if (rc != v.ok) { self.fail(rc); return; }
        self.order += 1;
        slot.* = .{ .order = self.order, .frame = frame };
        if (frame.flags & v.packet_pts == 0) {
            if (self.config.missing_pts_duration_ns == 0) { slot.returning = true; self.fail(v.error_invalid); return; }
            slot.frame.pts_ns = self.next_pts_ns;
        }
        if (frame.flags & v.packet_duration == 0 or frame.duration_ns == 0) slot.frame.duration_ns = self.config.missing_pts_duration_ns;
        const next: i128 = @as(i128, slot.frame.pts_ns) + slot.frame.duration_ns;
        self.next_pts_ns = std.math.cast(i64, next) orelse { slot.returning = true; self.fail(v.error_invalid); return; };
    }
    /// One decoder operation, one composition transition and one bounded audio
    /// step per call. Pump from the ordinary event loop; never spin until ready.
    /// A supplied target is borrowed only when target_accepted is returned.
    pub fn step(self: *Session, now: u64, target: ?composition.Target, transform: g.R4GfxColorTransform) Step {
        const media = self.clock.position(now) catch blk: { self.fail(v.error_internal); break :blk self.clock.media_ns; };
        var output: Step = .{ .phase = self.phase, .media_ns = media };
        if (self.phase == .closed) return output;
        if (self.sound) |sound| {
            sound.step(media, self.clock.paused or (self.phase != .playing and self.phase != .draining));
            output.audio_degraded = sound.state == .degraded or sound.last_error != 0;
        }
        self.frameStep(now, media, target, transform, &output);
        self.controlStep(now);
        if (self.control_pending == null or self.phase == .draining) self.receiveStep();
        if (self.output_eos and !self.hasFrames() and self.phase == .draining and (self.sound == null or self.sound.?.count == 0)) self.phase = .ended;
        if (self.close_requested and self.decoder_closed and !self.hasFrames() and (self.sound == null or self.sound.?.state == .closed)) {
            const rc = self.api.destroy(&self.decoder);
            if (rc == v.ok) self.phase = .closed else if (rc != v.error_busy) self.fail(rc);
        }
        output.phase = self.phase;
        if (self.phase == .seeking and self.seek_ready and !self.hasFrames() and (self.sound == null or self.sound.?.state != .closing)) output.reposition_ns = self.seek_ns;
        return output;
    }
};
