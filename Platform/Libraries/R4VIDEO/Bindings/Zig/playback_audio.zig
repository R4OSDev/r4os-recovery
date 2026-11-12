// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Bounded PCM delivery through the ordinary App-Audio/AUDSVC owner. This API
//! exposes no audible hardware cursor; accepted bytes never drive media time.
const std = @import("std");
const r4os = @import("r4os");
const audio = r4os.app_audio;
const timing = @import("playback_clock.zig");
pub const Error = error{ Invalid, Busy, Stale, Overflow };
pub const State = enum { disabled, ready, active, degraded, closing, closed };
pub const Audio = struct {
    api: audio.Audio,
    storage: []u8,
    rate: u32,
    channels: u16,
    epoch: u64 = 1,
    state: State = .ready,
    stream: ?audio.AudioStream = null,
    count: usize = 0,
    accepted: usize = 0,
    pts_ns: i64 = 0,
    last_error: i32 = 0,
    after_close: State = .ready,
    // A single service call has a finite deadline; no polling loop in a step.
    timeout: audio.Timeout = r4os.time_contract.timeoutFinite(.{ .nanoseconds = std.time.ns_per_ms }),

    pub fn init(api: audio.Audio, storage: []u8, rate: u32, channels: u16) Error!Audio {
        const frame: usize = @as(usize, channels) * 2;
        if (rate == 0 or rate > 192_000 or channels == 0 or channels > 2 or storage.len < frame or storage.len > 65536) return error.Invalid;
        return .{ .api = api, .storage = storage, .rate = rate, .channels = channels };
    }
    pub fn frameBytes(self: *const Audio) usize { return @as(usize, self.channels) * 2; }
    /// Copies only the reported prefix. Caller derives subsequent PTS from its
    /// cumulative sample count, and retains unaccepted bytes under backpressure.
    pub fn feed(self: *Audio, epoch: u64, pts_ns: i64, pcm: []const u8) Error!usize {
        if (epoch != self.epoch) return error.Stale;
        const frame = self.frameBytes();
        if (pcm.len == 0 or pcm.len % frame != 0) return error.Invalid;
        if (self.count != 0 or self.state == .closing or self.state == .closed) return error.Busy;
        const quantum: usize = @max(1, self.rate / 100) * frame;
        const count = @min(pcm.len, @min(self.storage.len / frame * frame, quantum));
        @memcpy(self.storage[0..count], pcm[0..count]);
        self.count = count;
        self.accepted = 0;
        self.pts_ns = pts_ns;
        return count;
    }
    pub fn reset(self: *Audio, epoch: u64, enabled: bool) Error!void {
        if (epoch == 0 or epoch <= self.epoch) return error.Stale;
        self.epoch = epoch;
        self.last_error = 0;
        self.count = 0;
        self.accepted = 0;
        self.after_close = if (enabled) .ready else .disabled;
        self.state = if (self.stream != null) .closing else self.after_close;
    }
    pub fn close(self: *Audio) void {
        self.count = 0;
        self.accepted = 0;
        self.after_close = .closed;
        self.state = if (self.stream != null) .closing else .closed;
    }
    fn fail(self: *Audio, raw: i32) void {
        self.last_error = raw;
        self.count = 0;
        self.accepted = 0;
        self.after_close = .degraded;
        self.state = if (self.stream != null) .closing else .degraded;
    }
    /// media_ns comes from the same monotonic, pause-corrected clock as video.
    /// A maximum10ms lead and one aligned service payload bound producer latency.
    pub fn step(self: *Audio, media_ns: i64, paused: bool) void {
        if (self.state == .closing) {
            if (self.stream) |*stream| switch (stream.close(self.timeout)) {
                .ok => { self.stream = null; self.state = self.after_close; },
                .failure => |raw| {
                    if (raw != r4os.abi.service_api_result_busy) self.last_error = raw;
                    // The service facade invalidates a dead/bad connection.
                    // PCM was copied into service messages; no caller buffer
                    // remains borrowed by that now unreachable endpoint.
                    if (!stream.connection.valid()) { self.stream = null; self.state = self.after_close; }
                },
                .timed_out => { self.last_error = r4os.abi.service_api_result_timeout; },
            };
            return;
        }
        if (self.state == .closed or paused or self.count == 0) return;
        if (self.state == .disabled or self.state == .degraded) { self.count = 0; self.accepted = 0; return; }
        // Trim late PCM instead of speeding up either clock to catch up.
        if (media_ns > self.pts_ns) {
            const late_frames: u128 = @intCast(@as(i128, media_ns) - self.pts_ns);
            const skip = @min(@as(u128, self.count / self.frameBytes()), late_frames * self.rate / std.time.ns_per_s);
            self.accepted = @max(self.accepted, @as(usize, @intCast(skip)) * self.frameBytes());
        }
        if (self.accepted == self.count) { self.count = 0; self.accepted = 0; return; }
        const next = timing.sampleTime(self.pts_ns, self.accepted / self.frameBytes(), self.rate) catch { self.fail(-1); return; };
        if (@as(i128, next) > @as(i128, media_ns) + 10 * std.time.ns_per_ms) return;
        if (self.stream == null) {
            switch (self.api.openStream(self.rate, self.channels, .s16le, audio.default_volume, self.timeout)) {
                .stream => |stream| { self.stream = stream; self.state = .active; self.last_error = 0; },
                .failure, .no_service => |raw| self.fail(raw),
                .timed_out => self.fail(r4os.abi.service_api_result_timeout),
            }
            return;
        }
        const count = @min(self.count - self.accepted, audio.max_write_payload / self.frameBytes() * self.frameBytes());
        var cursor = audio.WriteCursor.init(count, self.frameBytes()).?;
        const advance = cursor.apply(self.stream.?.writeOnce(self.storage[self.accepted..][0..count], self.timeout));
        self.accepted += advance.accepted;
        switch (advance.outcome) {
            .complete, .retry => {},
            // A timed-out remote call has no reliable acceptance receipt. Stop
            // this stream rather than replaying possibly accepted samples.
            .timed_out, .failure, .invalid => { self.fail(advance.raw); return; },
        }
        if (self.accepted == self.count) { self.count = 0; self.accepted = 0; }
    }
};
