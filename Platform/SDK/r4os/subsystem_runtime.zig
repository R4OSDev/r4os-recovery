const std = @import("std");
const abi = @import("r4os_contract").abi;
const app_audio = @import("app_audio.zig");
const r4sys = @import("r4sys.zig");
const time_contract = @import("time_contract.zig");

pub const default_slice_budget: u32 = 262_144;
pub const default_max_input_events: u16 = 64;
pub const default_max_wait_ticks: u64 = abi.io_wait_forever;
pub const default_idle_retry_ticks: u64 = 1;
pub const default_active_yield_nanoseconds: u64 = 8 * std.time.ns_per_ms;
pub const default_sample_rate: u32 = 48_000;
pub const default_channels: u16 = 2;
pub const default_quantum_frames: u32 = 480;
pub const default_target_quanta: u16 = 2;
pub const default_max_catchup_quanta: u16 = 2;
pub const default_busy_retry_nanoseconds: u64 = 10 * std.time.ns_per_ms;
const audio_open_retry_limit: u16 = 3;
const audio_open_retry_nanoseconds: u64 = 50 * std.time.ns_per_ms;
pub const audio_error_timeout: i32 = -9601;
pub const audio_error_unavailable: i32 = -9602;
pub const runtime_error_guest_audio: i32 = -9610;
pub const runtime_error_guest_reset: i32 = -9611;
pub const runtime_error_host_poll: i32 = -9612;
pub const runtime_error_host_present: i32 = -9613;

pub const host_present_unchanged: i32 = 0;
pub const host_presented: i32 = 1;
pub const host_present_hidden: i32 = 2;
pub const host_present_dropped: i32 = 3;

pub const Error = error{
    UnknownFrequency,
    InvalidConfiguration,
    InvalidAudioConfiguration,
    AudioQueueTooSmall,
    AudioScratchTooSmall,
    Overflow,
};

pub const LifecycleState = enum {
    ready,
    running,
    paused,
    completed,
    failed,
    closed,
};

pub const LifecycleCommand = enum {
    none,
    pause,
    resume_running,
    toggle_pause,
    reset,
    mute,
    unmute,
    toggle_mute,
    close,
};

pub const StepStatus = enum {
    progress,
    waiting,
    completed,
    failed,
};

pub const StepResult = struct {
    status: StepStatus = .progress,
    frame_ready: bool = false,
    wake_guest_ns: u64 = 0,
    exit_code: i32 = 0,
    /// Operations actually completed by this slice. The configured budget is
    /// only an upper bound and is accounted separately by RuntimeStats.
    operations: u32 = 0,

    pub fn progress(frame_ready: bool) StepResult {
        return .{ .frame_ready = frame_ready };
    }

    pub fn waitUntil(wake_guest_ns: u64, frame_ready: bool) StepResult {
        return .{ .status = .waiting, .frame_ready = frame_ready, .wake_guest_ns = wake_guest_ns };
    }

    pub fn complete(exit_code: i32, frame_ready: bool) StepResult {
        return .{ .status = .completed, .frame_ready = frame_ready, .exit_code = exit_code };
    }

    pub fn fail(exit_code: i32) StepResult {
        return .{ .status = .failed, .exit_code = exit_code };
    }

    pub fn withOperations(self: StepResult, operations: u32) StepResult {
        var result = self;
        result.operations = operations;
        return result;
    }
};

pub const HostPollResult = union(enum) {
    idle,
    /// A raw host event was consumed intentionally, but it neither changed
    /// guest-visible state nor warrants waking an event-only guest.
    ignored,
    handled,
    present,
    command: LifecycleCommand,
    failure: i32,
};

/// Progress at the service boundary of one guest audio stream. Accepted
/// source bytes have reached AudioService; they must not be interpreted as
/// hardware-played bytes. The current platform ABI exposes no per-stream
/// hardware playback cursor, so `playback_frames` remains null until such a
/// cursor exists.
pub const AudioFeedback = struct {
    state: AudioState,
    muted: bool,
    accepted_bytes: u64 = 0,
    suppressed_bytes: u64 = 0,
    discarded_bytes: u64 = 0,
    playback_frames: ?u64 = null,
};

pub const GuestDriver = struct {
    context: *anyopaque,
    step_fn: *const fn (*anyopaque, u32, u64) StepResult,
    reset_fn: *const fn (*anyopaque) i32,
    render_audio_fn: *const fn (*anyopaque, []u8) i32,
    audio_feedback_fn: ?*const fn (*anyopaque, AudioFeedback) bool = null,

    pub fn step(self: GuestDriver, budget: u32, guest_now_ns: u64) StepResult {
        return self.step_fn(self.context, budget, guest_now_ns);
    }

    pub fn reset(self: GuestDriver) i32 {
        return self.reset_fn(self.context);
    }

    pub fn renderAudio(self: GuestDriver, out: []u8) i32 {
        return self.render_audio_fn(self.context, out);
    }

    /// Returns true when transport progress made an event-only guest runnable.
    pub fn audioFeedback(self: GuestDriver, feedback: AudioFeedback) bool {
        return if (self.audio_feedback_fn) |callback| callback(self.context, feedback) else false;
    }
};

pub const HostDriver = struct {
    context: *anyopaque,
    poll_fn: *const fn (*anyopaque) HostPollResult,
    present_fn: *const fn (*anyopaque) i32,
    wait_fn: ?*const fn (*anyopaque, u64) i32 = null,
    should_close_fn: ?*const fn (*anyopaque) bool = null,

    pub fn poll(self: HostDriver) HostPollResult {
        return self.poll_fn(self.context);
    }

    pub fn present(self: HostDriver) i32 {
        return self.present_fn(self.context);
    }

    pub fn wait(self: HostDriver, timeout_ticks: u64) ?i32 {
        return if (self.wait_fn) |wait_fn| wait_fn(self.context, timeout_ticks) else null;
    }

    pub fn shouldClose(self: HostDriver) ?bool {
        return if (self.should_close_fn) |should_close_fn| should_close_fn(self.context) else null;
    }
};

pub const GuestClock = struct {
    monotonic_hz: u32,
    last_host_tick: u64 = 0,
    guest_ns: u64 = 0,
    remainder: u64 = 0,
    paused: bool = false,

    pub fn init(monotonic_hz: u32, host_tick: u64) Error!GuestClock {
        if (monotonic_hz == 0) return Error.UnknownFrequency;
        return .{ .monotonic_hz = monotonic_hz, .last_host_tick = host_tick };
    }

    pub fn sync(self: *GuestClock, host_tick: u64) u64 {
        const delta = host_tick -| self.last_host_tick;
        self.last_host_tick = host_tick;
        if (self.paused or delta == 0) return self.guest_ns;

        const product = @as(u128, delta) * time_contract.nanoseconds_per_second + self.remainder;
        const advanced = product / self.monotonic_hz;
        self.remainder = @intCast(product % self.monotonic_hz);
        self.guest_ns +|= if (advanced > std.math.maxInt(u64)) std.math.maxInt(u64) else @intCast(advanced);
        return self.guest_ns;
    }

    pub fn pause(self: *GuestClock, host_tick: u64) void {
        _ = self.sync(host_tick);
        self.paused = true;
    }

    pub fn resumeAt(self: *GuestClock, host_tick: u64) void {
        self.last_host_tick = host_tick;
        self.paused = false;
    }

    pub fn reset(self: *GuestClock, host_tick: u64) void {
        self.last_host_tick = host_tick;
        self.guest_ns = 0;
        self.remainder = 0;
        self.paused = false;
    }

    pub fn ticksUntil(self: *const GuestClock, guest_deadline_ns: u64) u64 {
        if (guest_deadline_ns <= self.guest_ns) return 0;
        const delta = guest_deadline_ns - self.guest_ns;
        const product = @as(u128, delta) * self.monotonic_hz;
        const ticks = (product + time_contract.nanoseconds_per_second - 1) / time_contract.nanoseconds_per_second;
        return if (ticks > std.math.maxInt(u64)) std.math.maxInt(u64) else @intCast(ticks);
    }
};

pub const Pacer = struct {
    interval_ns: u64,
    next_ns: u64 = 0,

    pub fn initHz(rate_hz: u32) Error!Pacer {
        if (rate_hz == 0) return Error.InvalidConfiguration;
        return .{ .interval_ns = ceilDiv(time_contract.nanoseconds_per_second, rate_hz) };
    }

    pub fn reset(self: *Pacer, guest_now_ns: u64) void {
        self.next_ns = guest_now_ns;
    }

    pub fn take(self: *Pacer, guest_now_ns: u64) bool {
        if (guest_now_ns < self.next_ns) return false;
        if (self.next_ns == 0) self.next_ns = guest_now_ns;
        const elapsed = guest_now_ns -| self.next_ns;
        const periods = elapsed / self.interval_ns + 1;
        self.next_ns +|= periods *| self.interval_ns;
        return true;
    }

    pub fn deadline(self: *const Pacer) u64 {
        return self.next_ns;
    }
};

pub const AudioConfig = struct {
    sample_rate: u32 = default_sample_rate,
    channels: u16 = default_channels,
    volume: u32 = app_audio.default_volume,
    quantum_frames: u32 = default_quantum_frames,
    target_quanta: u16 = default_target_quanta,
    max_catchup_quanta: u16 = default_max_catchup_quanta,
    busy_retry_nanoseconds: u64 = default_busy_retry_nanoseconds,

    pub fn frameBytes(self: AudioConfig) Error!usize {
        if (self.sample_rate == 0 or self.channels == 0) return Error.InvalidAudioConfiguration;
        return std.math.mul(usize, @as(usize, self.channels), @sizeOf(i16)) catch Error.Overflow;
    }

    pub fn quantumBytes(self: AudioConfig) Error!usize {
        if (self.quantum_frames == 0) return Error.InvalidAudioConfiguration;
        return std.math.mul(usize, try self.frameBytes(), @as(usize, self.quantum_frames)) catch Error.Overflow;
    }

    pub fn targetBytes(self: AudioConfig) Error!usize {
        if (self.target_quanta == 0) return Error.InvalidAudioConfiguration;
        return std.math.mul(usize, try self.quantumBytes(), @as(usize, self.target_quanta)) catch Error.Overflow;
    }
};

pub const AudioSink = struct {
    context: *anyopaque,
    open_fn: *const fn (*anyopaque, AudioConfig) i32,
    write_fn: *const fn (*anyopaque, []const u8) i32,
    volume_fn: *const fn (*anyopaque, u32) i32,
    close_fn: *const fn (*anyopaque) i32,

    fn open(self: AudioSink, config: AudioConfig) i32 {
        return self.open_fn(self.context, config);
    }

    fn write(self: AudioSink, data: []const u8) i32 {
        return self.write_fn(self.context, data);
    }

    fn setVolume(self: AudioSink, volume: u32) i32 {
        return self.volume_fn(self.context, volume);
    }

    fn close(self: AudioSink) i32 {
        return self.close_fn(self.context);
    }
};

pub const R4AudioSink = struct {
    audio: app_audio.Audio,
    stream: ?app_audio.AudioStream = null,
    timeout: time_contract.Timeout = time_contract.timeoutFinite(.{ .nanoseconds = 100 * std.time.ns_per_ms }),
    close_timeout: time_contract.Timeout = time_contract.timeoutFinite(.{ .nanoseconds = 100 * std.time.ns_per_ms }),

    pub fn init(audio: app_audio.Audio) R4AudioSink {
        return .{ .audio = audio };
    }

    pub fn initWithTimeout(audio: app_audio.Audio, timeout_nanoseconds: u64) R4AudioSink {
        return .{
            .audio = audio,
            .timeout = time_contract.timeoutFinite(.{ .nanoseconds = timeout_nanoseconds }),
            .close_timeout = time_contract.timeoutFinite(.{ .nanoseconds = timeout_nanoseconds }),
        };
    }

    /// Keeps short interactive Open/Write/Volume calls independent from a
    /// normal Close that may drain already accepted PCM in the audio service.
    pub fn initWithTimeouts(audio: app_audio.Audio, timeout_nanoseconds: u64, close_timeout_nanoseconds: u64) R4AudioSink {
        return .{
            .audio = audio,
            .timeout = time_contract.timeoutFinite(.{ .nanoseconds = timeout_nanoseconds }),
            .close_timeout = time_contract.timeoutFinite(.{ .nanoseconds = close_timeout_nanoseconds }),
        };
    }

    pub fn sink(self: *R4AudioSink) AudioSink {
        return .{
            .context = self,
            .open_fn = r4AudioOpen,
            .write_fn = r4AudioWrite,
            .volume_fn = r4AudioVolume,
            .close_fn = r4AudioClose,
        };
    }
};

pub const AudioState = enum {
    disabled,
    ready,
    active,
    degraded,
    closed,
};

pub const AudioStats = struct {
    generated_bytes: u64 = 0,
    submitted_bytes: u64 = 0,
    discarded_bytes: u64 = 0,
    silence_bytes: u64 = 0,
    muted_bytes: u64 = 0,
    underflows: u64 = 0,
    open_retries: u64 = 0,
    writes: u64 = 0,
    busy_writes: u64 = 0,
    write_failures: u64 = 0,
    late_resyncs: u64 = 0,
    suppressed_bytes: u64 = 0,
    idle_quanta: u64 = 0,
    lazy_opens: u64 = 0,
    idle_closes: u64 = 0,
    active_cycles: u64 = 0,
    silent_cycles: u64 = 0,
    paused_cycles: u64 = 0,
    muted_cycles: u64 = 0,
    active_quanta: u64 = 0,
    silent_quanta: u64 = 0,
    paused_bytes: u64 = 0,
    service_operations: u64 = 0,
    open_operations: u64 = 0,
    write_operations: u64 = 0,
    close_operations: u64 = 0,
    maximum_service_operations_per_cycle: u16 = 0,
};

pub const PcmQueue = struct {
    storage: []u8,
    frame_bytes: usize = 1,
    read_pos: usize = 0,
    len: usize = 0,

    pub fn init(storage: []u8, frame_bytes: usize) Error!PcmQueue {
        if (frame_bytes == 0 or storage.len < frame_bytes or storage.len % frame_bytes != 0) return Error.AudioQueueTooSmall;
        return .{ .storage = storage, .frame_bytes = frame_bytes };
    }

    pub fn available(self: *const PcmQueue) usize {
        return self.len;
    }

    pub fn free(self: *const PcmQueue) usize {
        return self.storage.len - self.len;
    }

    pub fn clear(self: *PcmQueue) void {
        self.read_pos = 0;
        self.len = 0;
    }

    pub fn write(self: *PcmQueue, data: []const u8) usize {
        const requested = @min(data.len, self.free());
        const count = requested - requested % self.frame_bytes;
        const write_pos = (self.read_pos + self.len) % self.storage.len;
        const first = @min(count, self.storage.len - write_pos);
        @memcpy(self.storage[write_pos..][0..first], data[0..first]);
        if (first < count) @memcpy(self.storage[0 .. count - first], data[first..count]);
        self.len += count;
        return count;
    }

    pub fn peek(self: *const PcmQueue, out: []u8) usize {
        const requested = @min(out.len, self.len);
        const count = requested - requested % self.frame_bytes;
        const first = @min(count, self.storage.len - self.read_pos);
        @memcpy(out[0..first], self.storage[self.read_pos..][0..first]);
        if (first < count) @memcpy(out[first..count], self.storage[0 .. count - first]);
        return count;
    }

    pub fn discard(self: *PcmQueue, byte_count: usize) usize {
        const requested = @min(byte_count, self.len);
        const count = requested - requested % self.frame_bytes;
        self.read_pos = (self.read_pos + count) % self.storage.len;
        self.len -= count;
        if (self.len == 0) self.read_pos = 0;
        return count;
    }

    pub fn read(self: *PcmQueue, out: []u8) usize {
        const count = self.peek(out);
        _ = self.discard(count);
        return count;
    }
};

pub const AudioOptions = struct {
    config: AudioConfig = .{},
    queue_storage: []u8,
    scratch: []u8,
    sink: ?AudioSink = null,
};

const empty_audio_storage = [_]u8{};

const SubmitResult = enum {
    submitted,
    idle,
    busy,
    failed,
};

pub const AudioPump = struct {
    config: AudioConfig = .{},
    queue: PcmQueue = .{ .storage = @constCast(empty_audio_storage[0..]) },
    scratch: []u8 = @constCast(empty_audio_storage[0..]),
    sink: ?AudioSink = null,
    state: AudioState = .disabled,
    last_error: i32 = 0,
    muted: bool = false,
    next_deadline_tick: u64 = 0,
    quantum_ticks: u64 = 1,
    busy_retry_ticks: u64 = 1,
    open_retry_ticks: u64 = 1,
    open_retry_attempts: u16 = 0,
    resync_prefill_quanta: u16 = 0,
    sink_open: bool = false,
    close_pending: bool = false,
    render_progress_pending: bool = false,
    service_operations_cycle: u16 = 0,
    stats: AudioStats = .{},

    fn init(options: AudioOptions, monotonic_hz: u32) Error!AudioPump {
        const frame_bytes = try options.config.frameBytes();
        const quantum_bytes = try options.config.quantumBytes();
        const target_bytes = try options.config.targetBytes();
        if (options.config.max_catchup_quanta == 0 or options.config.busy_retry_nanoseconds == 0) return Error.InvalidAudioConfiguration;
        if (options.queue_storage.len < target_bytes) return Error.AudioQueueTooSmall;
        if (options.scratch.len < quantum_bytes) return Error.AudioScratchTooSmall;
        const quantum_ns_product = @as(u128, options.config.quantum_frames) * time_contract.nanoseconds_per_second;
        const quantum_ns: u64 = @intCast((quantum_ns_product + options.config.sample_rate - 1) / options.config.sample_rate);
        const quantum_ticks = time_contract.durationToTicks(.{ .nanoseconds = quantum_ns }, monotonic_hz) catch return Error.UnknownFrequency;
        const busy_retry_ticks = time_contract.durationToTicks(.{ .nanoseconds = options.config.busy_retry_nanoseconds }, monotonic_hz) catch return Error.UnknownFrequency;
        const open_retry_ticks = time_contract.durationToTicks(.{ .nanoseconds = audio_open_retry_nanoseconds }, monotonic_hz) catch return Error.UnknownFrequency;
        return .{
            .config = options.config,
            .queue = try PcmQueue.init(options.queue_storage, frame_bytes),
            .scratch = options.scratch[0..quantum_bytes],
            .sink = options.sink,
            .state = .ready,
            .quantum_ticks = @max(@as(u64, 1), quantum_ticks),
            .busy_retry_ticks = @max(@as(u64, 1), busy_retry_ticks),
            .open_retry_ticks = @max(@as(u64, 1), open_retry_ticks),
        };
    }

    fn start(self: *AudioPump, now: u64) void {
        _ = now;
        if (self.state == .disabled or self.state == .active or self.state == .degraded) return;
        self.queue.clear();
        self.next_deadline_tick = 0;
    }

    fn beginCycle(self: *AudioPump) void {
        self.service_operations_cycle = 0;
    }

    fn noteServiceOperation(self: *AudioPump) void {
        self.service_operations_cycle +|= 1;
        self.stats.service_operations +%= 1;
        self.stats.maximum_service_operations_per_cycle = @max(
            self.stats.maximum_service_operations_per_cycle,
            self.service_operations_cycle,
        );
    }

    fn tryOpen(self: *AudioPump, now: u64) bool {
        if (self.close_pending or self.service_operations_cycle != 0) return false;
        const sink = self.sink orelse {
            self.degrade(audio_error_unavailable);
            return false;
        };
        self.noteServiceOperation();
        self.stats.open_operations +%= 1;
        const rc = sink.open(self.config);
        if (rc < 0) {
            self.last_error = rc;
            if (retryableOpenError(rc) and self.open_retry_attempts < audio_open_retry_limit) {
                self.open_retry_attempts += 1;
                self.stats.open_retries +%= 1;
                self.next_deadline_tick = now +| self.open_retry_ticks;
                return false;
            }
            self.degrade(rc);
            return false;
        }
        self.state = .active;
        self.sink_open = true;
        self.last_error = 0;
        self.open_retry_attempts = 0;
        self.resync_prefill_quanta = self.config.target_quanta;
        self.stats.lazy_opens +%= 1;
        // Opening consumes this cycle's one permitted service operation. The
        // first prefill write is therefore due in a fresh host cycle.
        self.next_deadline_tick = if (now == 0) 1 else now;
        return true;
    }

    fn reset(self: *AudioPump, now: u64) void {
        _ = now;
        if (self.state == .disabled or self.state == .degraded or self.state == .closed) return;
        self.enterIdle();
    }

    fn pause(self: *AudioPump, now: u64) void {
        _ = now;
        if (self.state == .disabled or self.state == .degraded or self.state == .closed) return;
        self.stats.paused_bytes +%= self.queue.available();
        self.enterIdle();
    }

    fn setMuted(self: *AudioPump, muted: bool, now: u64) void {
        _ = now;
        if (self.muted == muted) return;
        self.muted = muted;
        if (self.state == .degraded) return;
        if (muted) {
            self.stats.muted_bytes +%= self.queue.available();
            self.enterIdle();
        }
    }

    fn fill(self: *AudioPump, guest: GuestDriver) i32 {
        self.render_progress_pending = false;
        if ((self.state != .ready and self.state != .active) or self.muted) return 0;
        const target = self.config.targetBytes() catch return runtime_error_guest_audio;
        const frame_bytes = self.config.frameBytes() catch return runtime_error_guest_audio;
        while (self.queue.available() < target) {
            const wanted_raw = @min(self.scratch.len, @min(target - self.queue.available(), self.queue.free()));
            const wanted = wanted_raw - wanted_raw % frame_bytes;
            if (wanted == 0) break;
            const rendered = guest.renderAudio(self.scratch[0..wanted]);
            if (rendered < 0) return rendered;
            const count: usize = @intCast(rendered);
            if (count == 0) {
                self.stats.silent_cycles +%= 1;
                break;
            }
            if (count > wanted or count % frame_bytes != 0) return runtime_error_guest_audio;
            self.stats.generated_bytes +%= count;
            if (isZeroPcm(self.scratch[0..count])) {
                self.stats.silence_bytes +%= count;
                self.stats.suppressed_bytes +%= count;
                self.stats.idle_quanta +%= 1;
                self.stats.silent_quanta +%= 1;
                self.render_progress_pending = true;
                break;
            }
            if (self.queue.write(self.scratch[0..count]) != count) return runtime_error_guest_audio;
        }
        return 0;
    }

    fn resyncLate(self: *AudioPump, now: u64) void {
        if ((self.state != .ready and self.state != .active) or self.next_deadline_tick == 0 or now < self.next_deadline_tick) return;
        const catchup_ticks = @as(u64, self.config.max_catchup_quanta) *| self.quantum_ticks;
        if (now - self.next_deadline_tick < catchup_ticks) return;
        const discarded = self.queue.available();
        self.queue.clear();
        self.stats.discarded_bytes +%= discarded;
        self.next_deadline_tick = now;
        self.resync_prefill_quanta = self.config.target_quanta;
        self.stats.late_resyncs +%= 1;
    }

    fn pump(self: *AudioPump, now: u64, running: bool) void {
        if (self.close_pending) {
            self.closeSink(false);
            return;
        }
        if (self.state != .ready and self.state != .active) return;
        if (!running) {
            self.enterIdle();
            return;
        }
        if (self.muted) {
            self.stats.muted_cycles +%= 1;
            self.enterIdle();
            return;
        }
        if (self.queue.available() != 0 or self.state == .active) self.stats.active_cycles +%= 1;
        if (self.state == .ready) {
            if (self.queue.available() == 0) {
                self.next_deadline_tick = 0;
                return;
            }
            if (self.next_deadline_tick != 0 and now < self.next_deadline_tick) return;
            _ = self.tryOpen(now);
            return;
        }
        if (self.service_operations_cycle != 0) return;
        if (now < self.next_deadline_tick) return;
        if (self.resync_prefill_quanta != 0) {
            switch (self.submitQuantum(running)) {
                .submitted => {
                    self.resync_prefill_quanta -= 1;
                    self.next_deadline_tick = if (self.resync_prefill_quanta == 0)
                        now +| self.quantum_ticks
                    else
                        now;
                },
                .busy => self.next_deadline_tick = now +| self.busy_retry_ticks,
                .idle, .failed => {},
            }
            return;
        }
        switch (self.submitQuantum(running)) {
            .submitted => self.next_deadline_tick +|= self.quantum_ticks,
            .busy => self.next_deadline_tick = now +| self.busy_retry_ticks,
            .idle, .failed => {},
        }
    }

    fn submitQuantum(self: *AudioPump, running: bool) SubmitResult {
        var copied: usize = 0;
        if (running) copied = self.queue.peek(self.scratch);
        if (!running or self.muted or copied == 0 or isZeroPcm(self.scratch[0..copied])) {
            if (copied != 0) {
                _ = self.queue.discard(copied);
                self.stats.silence_bytes +%= copied;
                self.stats.suppressed_bytes +%= copied;
            }
            self.stats.idle_quanta +%= 1;
            self.enterIdle();
            return .idle;
        }

        if (self.state != .active) {
            return .failed;
        }
        const sink = self.sink orelse {
            self.degrade(audio_error_unavailable);
            return .failed;
        };
        const payload = self.scratch[0..copied];
        self.noteServiceOperation();
        self.stats.write_operations +%= 1;
        const written = sink.write(payload);
        if (written == abi.service_api_result_busy) {
            self.stats.busy_writes +%= 1;
            return .busy;
        }
        if (written != @as(i32, @intCast(payload.len))) {
            self.stats.write_failures +%= 1;
            if (written > 0) {
                const submitted: usize = @min(@as(usize, @intCast(written)), payload.len);
                _ = self.queue.discard(submitted);
                self.stats.submitted_bytes +%= submitted;
            }
            self.degrade(if (written < 0) written else audio_error_unavailable);
            return .failed;
        }
        _ = self.queue.discard(copied);
        if (copied < self.scratch.len) self.stats.underflows +%= 1;
        self.stats.writes +%= 1;
        self.stats.submitted_bytes +%= copied;
        self.stats.active_quanta +%= 1;
        return .submitted;
    }

    fn enterIdle(self: *AudioPump) void {
        const discarded = self.queue.available();
        self.queue.clear();
        self.stats.discarded_bytes +%= discarded;
        self.resync_prefill_quanta = 0;
        self.next_deadline_tick = 0;
        self.open_retry_attempts = 0;
        if (self.sink_open) {
            if (self.service_operations_cycle == 0) {
                self.closeSink(true);
            } else {
                self.close_pending = true;
            }
        }
        if (self.state != .disabled and self.state != .degraded and self.state != .closed) {
            self.state = .ready;
            self.last_error = 0;
        }
    }

    fn degrade(self: *AudioPump, error_code: i32) void {
        if (self.sink_open) self.close_pending = true;
        const discarded = self.queue.available();
        self.queue.clear();
        self.stats.discarded_bytes +%= discarded;
        self.resync_prefill_quanta = 0;
        self.next_deadline_tick = 0;
        self.open_retry_attempts = 0;
        self.state = .degraded;
        self.last_error = if (error_code < 0) error_code else audio_error_unavailable;
    }

    fn closeSink(self: *AudioPump, idle: bool) void {
        if (!self.sink_open) {
            self.close_pending = false;
            return;
        }
        const sink = self.sink orelse {
            self.sink_open = false;
            self.close_pending = false;
            self.state = .degraded;
            self.last_error = audio_error_unavailable;
            return;
        };
        self.noteServiceOperation();
        self.stats.close_operations +%= 1;
        const rc = sink.close();
        self.sink_open = false;
        self.close_pending = false;
        if (rc < 0) {
            self.state = .degraded;
            self.last_error = rc;
            return;
        }
        if (idle) self.stats.idle_closes +%= 1;
    }

    fn close(self: *AudioPump) void {
        if (self.state == .closed or self.state == .disabled) return;
        if (self.sink_open) self.closeSink(false);
        const discarded = self.queue.available();
        self.queue.clear();
        self.stats.discarded_bytes +%= discarded;
        self.close_pending = false;
        self.state = .closed;
    }
};

fn retryableOpenError(raw: i32) bool {
    return raw == audio_error_timeout or
        raw == abi.service_api_result_timeout or
        raw == abi.service_api_result_busy or
        raw == abi.service_api_result_full or
        raw == abi.service_api_result_no_endpoint or
        raw == abi.service_api_result_not_running;
}

pub const Config = struct {
    slice_budget: u32 = default_slice_budget,
    max_input_events: u16 = default_max_input_events,
    max_wait_ticks: u64 = default_max_wait_ticks,
    idle_retry_ticks: u64 = default_idle_retry_ticks,
};

pub const RuntimeStats = struct {
    cycles: u64 = 0,
    slices: u64 = 0,
    requested_operations: u64 = 0,
    executed_operations: u64 = 0,
    host_polls: u64 = 0,
    close_checks: u64 = 0,
    poll_budget_exhaustions: u64 = 0,
    input_events: u64 = 0,
    ignored_input_events: u64 = 0,
    active_cycles: u64 = 0,
    waiting_cycles: u64 = 0,
    paused_cycles: u64 = 0,
    present_attempts: u64 = 0,
    presents: u64 = 0,
    skipped_presents: u64 = 0,
    unchanged_presents: u64 = 0,
    hidden_presents: u64 = 0,
    dropped_presents: u64 = 0,
    pauses: u64 = 0,
    resumes: u64 = 0,
    resets: u64 = 0,
    active_continues: u64 = 0,
    yields: u64 = 0,
    sleeps: u64 = 0,
    event_waits: u64 = 0,
    event_wakes: u64 = 0,
    event_timeouts: u64 = 0,
    event_wait_failures: u64 = 0,
    zero_progress_waits: u64 = 0,
};

pub const CycleResult = union(enum) {
    wait: u64,
    finished: struct {
        state: LifecycleState,
        exit_code: i32,
    },
};

pub const Runtime = struct {
    config: Config,
    clock: GuestClock,
    audio: AudioPump = .{},
    state: LifecycleState = .ready,
    exit_code: i32 = 0,
    guest_wake_ns: u64 = 0,
    guest_waiting: bool = false,
    present_pending: bool = false,
    guest_idle_polling: bool = false,
    host_backlog_pending: bool = false,
    post_present_poll_pending: bool = false,
    active_yield_ticks: u64,
    next_yield_tick: u64 = 0,
    started: bool = false,
    resources_closed: bool = false,
    audio_feedback_submitted_bytes: u64 = 0,
    audio_feedback_suppressed_bytes: u64 = 0,
    audio_feedback_discarded_bytes: u64 = 0,
    audio_feedback_state: AudioState = .disabled,
    audio_feedback_muted: bool = false,
    audio_feedback_initialized: bool = false,
    stats: RuntimeStats = .{},

    pub fn init(config: Config, monotonic_hz: u32, host_tick: u64, audio: ?AudioOptions) Error!Runtime {
        if (config.slice_budget == 0 or config.max_input_events == 0 or config.max_wait_ticks == 0 or config.idle_retry_ticks == 0) return Error.InvalidConfiguration;
        return .{
            .config = config,
            .clock = try GuestClock.init(monotonic_hz, host_tick),
            .audio = if (audio) |options| try AudioPump.init(options, monotonic_hz) else .{},
            .active_yield_ticks = ticksForNanoseconds(monotonic_hz, default_active_yield_nanoseconds),
        };
    }

    pub fn start(self: *Runtime, host_tick: u64) void {
        if (self.started) return;
        self.clock.reset(host_tick);
        self.audio.start(host_tick);
        self.state = .running;
        self.next_yield_tick = host_tick +| self.active_yield_ticks;
        self.started = true;
        self.resources_closed = false;
    }

    pub fn request(self: *Runtime, command: LifecycleCommand, host_tick: u64, guest: GuestDriver) void {
        if (isTerminal(self.state)) return;
        switch (command) {
            .none => {},
            .pause => if (self.state == .running) {
                self.clock.pause(host_tick);
                self.audio.pause(host_tick);
                self.state = .paused;
                self.stats.pauses +%= 1;
            },
            .resume_running => if (self.state == .paused) {
                self.clock.resumeAt(host_tick);
                self.audio.reset(host_tick);
                self.state = .running;
                self.stats.resumes +%= 1;
            },
            .toggle_pause => self.request(if (self.state == .paused) .resume_running else .pause, host_tick, guest),
            .reset => {
                const rc = guest.reset();
                if (rc < 0) {
                    self.fail(rc);
                    return;
                }
                self.clock.reset(host_tick);
                self.audio.reset(host_tick);
                self.guest_wake_ns = 0;
                self.guest_waiting = false;
                self.guest_idle_polling = false;
                self.present_pending = true;
                self.state = .running;
                self.stats.resets +%= 1;
            },
            .mute => self.audio.setMuted(true, host_tick),
            .unmute => self.audio.setMuted(false, host_tick),
            .toggle_mute => self.audio.setMuted(!self.audio.muted, host_tick),
            .close => {
                self.state = .closed;
                self.exit_code = 0;
            },
        }
    }

    pub fn cycle(self: *Runtime, host_tick: u64, guest: GuestDriver, host: HostDriver) CycleResult {
        if (!self.started) self.start(host_tick);
        self.audio.beginCycle();
        self.stats.cycles +%= 1;
        self.post_present_poll_pending = false;
        var guest_now_ns = self.clock.sync(host_tick);

        if (host.shouldClose()) |should_close| {
            self.stats.close_checks +%= 1;
            if (should_close) {
                self.request(.close, host_tick, guest);
                return self.finish();
            }
        }

        var polled: u16 = 0;
        while (polled < self.config.max_input_events) : (polled += 1) {
            self.stats.host_polls +%= 1;
            switch (host.poll()) {
                .idle => break,
                .ignored => self.stats.ignored_input_events +%= 1,
                .handled => {
                    self.stats.input_events +%= 1;
                    self.guest_waiting = false;
                },
                .present => {
                    self.stats.input_events +%= 1;
                    self.present_pending = true;
                },
                .command => |command| {
                    self.stats.input_events +%= 1;
                    self.request(command, host_tick, guest);
                    if (isTerminal(self.state)) break;
                },
                .failure => |raw| {
                    self.fail(if (raw < 0) raw else runtime_error_host_poll);
                    break;
                },
            }
        }
        self.host_backlog_pending = polled == self.config.max_input_events;
        if (self.host_backlog_pending) self.stats.poll_budget_exhaustions +%= 1;

        if (isTerminal(self.state)) return self.finish();
        guest_now_ns = self.clock.guest_ns;

        // Drop source PCM which missed the complete bounded catch-up window
        // before the guest observes the new time. A guest audio renderer can
        // then advance its own timeline and refill from the current point;
        // stale samples are never submitted first and replayed late.
        if (self.state == .running) self.audio.resyncLate(host_tick);
        self.deliverAudioFeedback(guest);

        const guest_ready = !self.guest_waiting or
            (self.guest_wake_ns != 0 and guest_now_ns >= self.guest_wake_ns);
        if (self.state == .running and guest_ready) {
            self.guest_wake_ns = 0;
            const step = guest.step(self.config.slice_budget, guest_now_ns);
            self.stats.slices +%= 1;
            self.stats.requested_operations +%= self.config.slice_budget;
            self.stats.executed_operations +%= step.operations;
            self.guest_idle_polling = step.status == .progress and step.operations == 0 and step.wake_guest_ns == 0;
            if (self.guest_idle_polling) self.stats.zero_progress_waits +%= 1;
            self.present_pending = self.present_pending or step.frame_ready;
            switch (step.status) {
                .progress => {
                    self.guest_wake_ns = step.wake_guest_ns;
                    self.guest_waiting = step.wake_guest_ns != 0;
                },
                .waiting => {
                    self.guest_wake_ns = step.wake_guest_ns;
                    self.guest_waiting = true;
                },
                .completed => {
                    self.state = .completed;
                    self.exit_code = step.exit_code;
                },
                .failed => self.fail(step.exit_code),
            }
        }

        // A ready frame is published before any potentially blocking audio
        // service operation. Audio can therefore delay neither this frame nor
        // host input handling in the current cycle.
        if (self.present_pending and self.state != .failed and self.state != .closed) {
            self.stats.present_attempts +%= 1;
            const presented = host.present();
            if (presented < 0) {
                self.fail(presented);
            } else if (presented == host_presented) {
                self.stats.presents +%= 1;
                self.present_pending = false;
                self.post_present_poll_pending = true;
            } else {
                self.stats.skipped_presents +%= 1;
                switch (presented) {
                    host_present_hidden => self.stats.hidden_presents +%= 1,
                    host_present_dropped => self.stats.dropped_presents +%= 1,
                    else => self.stats.unchanged_presents +%= 1,
                }
                self.present_pending = false;
            }
        }

        if (self.state == .running) {
            const audio_fill = self.audio.fill(guest);
            if (audio_fill < 0) self.fail(audio_fill);
        }
        self.audio.pump(host_tick, self.state == .running);
        self.deliverAudioFeedback(guest);

        switch (self.state) {
            .running => if (self.guest_waiting or self.guest_idle_polling) {
                self.stats.waiting_cycles +%= 1;
            } else {
                self.stats.active_cycles +%= 1;
            },
            .paused => {
                self.stats.paused_cycles +%= 1;
                self.audio.stats.paused_cycles +%= 1;
            },
            else => {},
        }

        if (isTerminal(self.state)) return self.finish();
        return .{ .wait = self.nextWait(host_tick) };
    }

    pub fn run(self: *Runtime, sys: *const r4sys.Context, guest: GuestDriver, host: HostDriver) i32 {
        var host_tick = sys.ticks();
        self.start(host_tick);
        defer self.shutdown();
        while (true) {
            switch (self.cycle(host_tick, guest, host)) {
                .finished => |finished| return finished.exit_code,
                .wait => |ticks| {
                    if (ticks == 0) {
                        host_tick = sys.ticks();
                        self.stats.active_continues +%= 1;
                        if (host_tick >= self.next_yield_tick) {
                            self.stats.yields +%= 1;
                            sys.taskYield();
                            self.next_yield_tick = host_tick +| self.active_yield_ticks;
                        }
                        continue;
                    } else if (host.wait(ticks)) |raw| {
                        self.stats.event_waits +%= 1;
                        if (raw < 0) {
                            self.stats.event_wait_failures +%= 1;
                            self.fail(raw);
                            return self.exit_code;
                        }
                        if (raw == 0) {
                            self.stats.event_timeouts +%= 1;
                        } else {
                            self.stats.event_wakes +%= 1;
                        }
                    } else {
                        self.stats.sleeps +%= 1;
                        sys.sleepTicks(if (ticks == abi.io_wait_forever) self.config.idle_retry_ticks else ticks);
                    }
                },
            }
            host_tick = sys.ticks();
        }
    }

    pub fn shutdown(self: *Runtime) void {
        if (self.resources_closed) return;
        self.audio.close();
        self.resources_closed = true;
    }

    fn fail(self: *Runtime, raw: i32) void {
        self.state = .failed;
        self.exit_code = if (raw == 0) -1 else raw;
    }

    fn finish(self: *Runtime) CycleResult {
        self.shutdown();
        return .{ .finished = .{ .state = self.state, .exit_code = self.exit_code } };
    }

    fn deliverAudioFeedback(self: *Runtime, guest: GuestDriver) void {
        const accepted = self.audio.stats.submitted_bytes -| self.audio_feedback_submitted_bytes;
        const suppressed = self.audio.stats.suppressed_bytes -| self.audio_feedback_suppressed_bytes;
        const discarded = self.audio.stats.discarded_bytes -| self.audio_feedback_discarded_bytes;
        const state_changed = !self.audio_feedback_initialized or
            self.audio_feedback_state != self.audio.state or
            self.audio_feedback_muted != self.audio.muted;
        const unavailable_wait = self.guest_waiting and (self.audio.muted or switch (self.audio.state) {
            .disabled, .degraded, .closed => true,
            .ready, .active => false,
        });
        if (!state_changed and accepted == 0 and suppressed == 0 and discarded == 0 and !unavailable_wait) return;

        self.audio_feedback_submitted_bytes = self.audio.stats.submitted_bytes;
        self.audio_feedback_suppressed_bytes = self.audio.stats.suppressed_bytes;
        self.audio_feedback_discarded_bytes = self.audio.stats.discarded_bytes;
        self.audio_feedback_state = self.audio.state;
        self.audio_feedback_muted = self.audio.muted;
        self.audio_feedback_initialized = true;
        if (guest.audioFeedback(.{
            .state = self.audio.state,
            .muted = self.audio.muted,
            .accepted_bytes = accepted,
            .suppressed_bytes = suppressed,
            .discarded_bytes = discarded,
            .playback_frames = null,
        })) {
            self.guest_wake_ns = 0;
            self.guest_waiting = false;
            self.guest_idle_polling = false;
        }
    }

    fn nextWait(self: *const Runtime, host_tick: u64) u64 {
        if (self.host_backlog_pending or self.post_present_poll_pending or self.audio.close_pending or self.audio.render_progress_pending) return 0;
        var wait = self.config.max_wait_ticks;
        if (self.state == .running) {
            if (self.guest_idle_polling) {
                wait = @min(wait, self.config.idle_retry_ticks);
            } else if (!self.guest_waiting) {
                return 0;
            } else if (self.guest_wake_ns != 0) {
                wait = @min(wait, self.clock.ticksUntil(self.guest_wake_ns));
            }
        }
        if ((self.audio.state == .ready or self.audio.state == .active) and self.audio.next_deadline_tick != 0) {
            const audio_wait = if (host_tick >= self.audio.next_deadline_tick) @as(u64, 0) else self.audio.next_deadline_tick - host_tick;
            wait = @min(wait, audio_wait);
        }
        return wait;
    }
};

fn ticksForNanoseconds(frequency_hz: u32, nanoseconds: u64) u64 {
    const product = @as(u128, frequency_hz) * nanoseconds;
    const ticks = (product + time_contract.nanoseconds_per_second - 1) / time_contract.nanoseconds_per_second;
    return @max(@as(u64, 1), @as(u64, @intCast(ticks)));
}

fn r4AudioOpen(context: *anyopaque, config: AudioConfig) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    if (!self.audio.available()) return audio_error_unavailable;
    if (self.stream != null) return abi.service_api_result_busy;
    return switch (self.audio.openStream(config.sample_rate, config.channels, .s16le, config.volume, self.timeout)) {
        .stream => |stream| blk: {
            self.stream = stream;
            break :blk 0;
        },
        .timed_out => audio_error_timeout,
        .no_service => |raw| if (raw < 0) raw else audio_error_unavailable,
        .failure => |raw| if (raw < 0) raw else audio_error_unavailable,
    };
}

fn r4AudioWrite(context: *anyopaque, data: []const u8) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    var stream = &(self.stream orelse return abi.err_closed);
    return switch (stream.write(data, self.timeout)) {
        .written => |bytes| @intCast(bytes),
        .busy => |bytes| if (bytes == 0) abi.service_api_result_busy else @intCast(bytes),
        .timed_out => |bytes| if (bytes == 0) audio_error_timeout else @intCast(bytes),
        .failure => |failure| if (failure.written != 0) @intCast(failure.written) else failure.raw,
    };
}

fn r4AudioVolume(context: *anyopaque, volume: u32) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    var stream = &(self.stream orelse return abi.err_closed);
    return switch (stream.setVolume(volume, self.timeout)) {
        .ok => 0,
        .timed_out => audio_error_timeout,
        .failure => |raw| raw,
    };
}

fn r4AudioClose(context: *anyopaque) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    var stream = &(self.stream orelse return 0);
    const result: i32 = switch (stream.close(self.close_timeout)) {
        .ok => 0,
        .timed_out => audio_error_timeout,
        .failure => |raw| raw,
    };
    if (result < 0) {
        _ = stream.connection.close();
        stream.stream_id = 0;
        stream.owned = false;
    }
    self.stream = null;
    return result;
}

fn isTerminal(state: LifecycleState) bool {
    return state == .completed or state == .failed or state == .closed;
}

fn ceilDiv(value: u64, divisor: u32) u64 {
    return value / divisor + @intFromBool(value % divisor != 0);
}

fn isZeroPcm(data: []const u8) bool {
    for (data) |byte| {
        if (byte != 0) return false;
    }
    return true;
}

test "R4AudioSink separates interactive and draining close timeouts" {
    const app = app_audio.Audio{
        .sys = .{ .base = .{} },
        .raw = .{ .base = .{} },
    };
    const split = R4AudioSink.initWithTimeouts(app, 25 * std.time.ns_per_ms, 500 * std.time.ns_per_ms);
    try std.testing.expectEqual(abi.timeout_kind_finite, split.timeout.kind);
    try std.testing.expectEqual(@as(u64, 25 * std.time.ns_per_ms), split.timeout.nanoseconds);
    try std.testing.expectEqual(abi.timeout_kind_finite, split.close_timeout.kind);
    try std.testing.expectEqual(@as(u64, 500 * std.time.ns_per_ms), split.close_timeout.nanoseconds);

    const compatible = R4AudioSink.initWithTimeout(app, 25 * std.time.ns_per_ms);
    try std.testing.expectEqual(compatible.timeout.nanoseconds, compatible.close_timeout.nanoseconds);
}

const FakeGuest = struct {
    steps: u32 = 0,
    resets: u32 = 0,
    audio_renders: u32 = 0,
    audio_byte: u8 = 1,
    audio_enabled: bool = true,
    complete_after: u32 = 0,
    fail_code: i32 = 0,
    reset_result: i32 = 0,
    zero_progress: bool = false,
    event_waiting: bool = false,
    feedback_calls: u32 = 0,
    feedback_accepted_bytes: u64 = 0,
    feedback_suppressed_bytes: u64 = 0,
    feedback_discarded_bytes: u64 = 0,
    last_budget: u32 = 0,
    last_guest_ns: u64 = 0,

    fn driver(self: *FakeGuest) GuestDriver {
        return .{
            .context = self,
            .step_fn = fakeGuestStep,
            .reset_fn = fakeGuestReset,
            .render_audio_fn = fakeGuestAudio,
            .audio_feedback_fn = fakeGuestAudioFeedback,
        };
    }
};

const OperationOrder = struct {
    next: u32 = 0,
    present: u32 = 0,
    open: u32 = 0,
    write: u32 = 0,

    fn mark(self: *OperationOrder) u32 {
        self.next += 1;
        return self.next;
    }
};

const FakeHost = struct {
    commands: [8]LifecycleCommand = .{.none} ** 8,
    command_count: usize = 0,
    command_index: usize = 0,
    presents: u32 = 0,
    present_error: i32 = 0,
    present_result: i32 = host_presented,
    ignored_left: u32 = 0,
    handled_left: u32 = 0,
    waits: u32 = 0,
    wait_result: i32 = 1,
    order: ?*OperationOrder = null,

    fn driver(self: *FakeHost) HostDriver {
        return .{ .context = self, .poll_fn = fakeHostPoll, .present_fn = fakeHostPresent, .wait_fn = fakeHostWait };
    }

    fn push(self: *FakeHost, command: LifecycleCommand) void {
        self.commands[self.command_count] = command;
        self.command_count += 1;
    }
};

const FakeSink = struct {
    open_result: i32 = 0,
    open_failure_result: i32 = 0,
    open_failures_remaining: u32 = 0,
    busy_after: u32 = std.math.maxInt(u32),
    write_error_after: u32 = std.math.maxInt(u32),
    opens: u32 = 0,
    writes: u32 = 0,
    closes: u32 = 0,
    volumes: u32 = 0,
    bytes: u64 = 0,
    all_zero: bool = true,
    order: ?*OperationOrder = null,

    fn sink(self: *FakeSink) AudioSink {
        return .{ .context = self, .open_fn = fakeSinkOpen, .write_fn = fakeSinkWrite, .volume_fn = fakeSinkVolume, .close_fn = fakeSinkClose };
    }
};

fn fakeGuestStep(context: *anyopaque, budget: u32, guest_now_ns: u64) StepResult {
    const self: *FakeGuest = @ptrCast(@alignCast(context));
    self.steps += 1;
    self.last_budget = budget;
    self.last_guest_ns = guest_now_ns;
    if (self.fail_code != 0) return StepResult.fail(self.fail_code);
    if (self.complete_after != 0 and self.steps >= self.complete_after) return StepResult.complete(0, true).withOperations(budget);
    if (self.zero_progress) return StepResult.progress(false);
    if (self.event_waiting) return StepResult.waitUntil(0, true).withOperations(budget);
    return StepResult.waitUntil(guest_now_ns + 10 * std.time.ns_per_ms, true).withOperations(budget);
}

fn fakeGuestReset(context: *anyopaque) i32 {
    const self: *FakeGuest = @ptrCast(@alignCast(context));
    self.resets += 1;
    self.steps = 0;
    return self.reset_result;
}

fn fakeGuestAudio(context: *anyopaque, out: []u8) i32 {
    const self: *FakeGuest = @ptrCast(@alignCast(context));
    self.audio_renders += 1;
    if (!self.audio_enabled) return 0;
    @memset(out, self.audio_byte);
    return @intCast(out.len);
}

fn fakeGuestAudioFeedback(context: *anyopaque, feedback: AudioFeedback) bool {
    const self: *FakeGuest = @ptrCast(@alignCast(context));
    self.feedback_calls += 1;
    self.feedback_accepted_bytes +%= feedback.accepted_bytes;
    self.feedback_suppressed_bytes +%= feedback.suppressed_bytes;
    self.feedback_discarded_bytes +%= feedback.discarded_bytes;
    return false;
}

fn fakeHostPoll(context: *anyopaque) HostPollResult {
    const self: *FakeHost = @ptrCast(@alignCast(context));
    if (self.ignored_left != 0) {
        self.ignored_left -= 1;
        return .ignored;
    }
    if (self.handled_left != 0) {
        self.handled_left -= 1;
        return .handled;
    }
    if (self.command_index >= self.command_count) return .idle;
    const command = self.commands[self.command_index];
    self.command_index += 1;
    return .{ .command = command };
}

fn fakeHostPresent(context: *anyopaque) i32 {
    const self: *FakeHost = @ptrCast(@alignCast(context));
    self.presents += 1;
    if (self.order) |order| order.present = order.mark();
    return if (self.present_error < 0) self.present_error else self.present_result;
}

fn fakeHostWait(context: *anyopaque, _: u64) i32 {
    const self: *FakeHost = @ptrCast(@alignCast(context));
    self.waits += 1;
    return self.wait_result;
}

fn fakeSinkOpen(context: *anyopaque, _: AudioConfig) i32 {
    const self: *FakeSink = @ptrCast(@alignCast(context));
    self.opens += 1;
    if (self.order) |order| order.open = order.mark();
    if (self.open_failures_remaining != 0) {
        self.open_failures_remaining -= 1;
        return self.open_failure_result;
    }
    return self.open_result;
}

fn fakeSinkWrite(context: *anyopaque, data: []const u8) i32 {
    const self: *FakeSink = @ptrCast(@alignCast(context));
    if (self.order) |order| order.write = order.mark();
    if (self.writes >= self.busy_after) return abi.service_api_result_busy;
    if (self.writes >= self.write_error_after) return -77;
    self.writes += 1;
    self.bytes +%= data.len;
    for (data) |byte| self.all_zero = self.all_zero and byte == 0;
    return @intCast(data.len);
}

fn fakeSinkVolume(context: *anyopaque, _: u32) i32 {
    const self: *FakeSink = @ptrCast(@alignCast(context));
    self.volumes += 1;
    return 0;
}

fn fakeSinkClose(context: *anyopaque) i32 {
    const self: *FakeSink = @ptrCast(@alignCast(context));
    self.closes += 1;
    return 0;
}

test "guest clock excludes paused host time and pacer advances without drift catchup" {
    var clock = try GuestClock.init(100, 10);
    try std.testing.expectEqual(@as(u64, 20 * std.time.ns_per_ms), clock.sync(12));
    clock.pause(12);
    try std.testing.expectEqual(@as(u64, 20 * std.time.ns_per_ms), clock.sync(40));
    clock.resumeAt(40);
    try std.testing.expectEqual(@as(u64, 30 * std.time.ns_per_ms), clock.sync(41));
    try std.testing.expectEqual(@as(u64, 2), clock.ticksUntil(50 * std.time.ns_per_ms));
    clock.reset(50);
    try std.testing.expectEqual(@as(u64, 0), clock.guest_ns);

    var pacer = try Pacer.initHz(30);
    try std.testing.expect(pacer.take(0));
    try std.testing.expect(!pacer.take(10 * std.time.ns_per_ms));
    try std.testing.expect(pacer.take(100 * std.time.ns_per_ms));
    try std.testing.expect(pacer.deadline() > 100 * std.time.ns_per_ms);
}

test "pcm queue wraps caller storage without losing byte order" {
    var storage: [8]u8 = undefined;
    var queue = try PcmQueue.init(storage[0..], 2);
    try std.testing.expectEqual(@as(usize, 6), queue.write(&.{ 1, 2, 3, 4, 5, 6 }));
    var first: [4]u8 = undefined;
    try std.testing.expectEqual(@as(usize, 4), queue.read(first[0..]));
    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3, 4 }, first[0..]);
    try std.testing.expectEqual(@as(usize, 6), queue.write(&.{ 7, 8, 9, 10, 11, 12 }));
    var peeked: [4]u8 = undefined;
    try std.testing.expectEqual(@as(usize, 4), queue.peek(peeked[0..]));
    try std.testing.expectEqualSlices(u8, &.{ 5, 6, 7, 8 }, peeked[0..]);
    try std.testing.expectEqual(@as(usize, 4), queue.discard(peeked.len));
    var second: [4]u8 = undefined;
    try std.testing.expectEqual(@as(usize, 4), queue.read(second[0..]));
    try std.testing.expectEqualSlices(u8, &.{ 9, 10, 11, 12 }, second[0..]);
}

test "runtime bounds guest slices and applies pause resume reset and close between slices" {
    var queue_storage: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = FakeSink{};
    var runtime = try Runtime.init(.{ .slice_budget = 123, .max_wait_ticks = 1 }, 100, 0, .{
        .queue_storage = queue_storage[0..],
        .scratch = scratch[0..],
        .sink = sink.sink(),
    });
    var guest = FakeGuest{};
    var host = FakeHost{};

    try std.testing.expect(runtime.cycle(0, guest.driver(), host.driver()) == .wait);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);
    try std.testing.expectEqual(@as(u32, 123), guest.last_budget);

    host.push(.pause);
    _ = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(LifecycleState.paused, runtime.state);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);

    host.push(.resume_running);
    _ = runtime.cycle(5, guest.driver(), host.driver());
    try std.testing.expectEqual(LifecycleState.running, runtime.state);
    try std.testing.expectEqual(@as(u32, 2), guest.steps);

    host.push(.reset);
    _ = runtime.cycle(6, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u32, 1), guest.resets);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);
    try std.testing.expectEqual(@as(u64, 0), guest.last_guest_ns);

    host.push(.close);
    const closed = runtime.cycle(7, guest.driver(), host.driver());
    try std.testing.expectEqual(LifecycleState.closed, closed.finished.state);
    try std.testing.expectEqual(@as(u32, 2), sink.closes);
    try std.testing.expectEqual(@as(u64, 2), runtime.audio.stats.lazy_opens);
    try std.testing.expectEqual(@as(u64, 2), runtime.audio.stats.idle_closes);
    try std.testing.expectEqual(@as(u16, 1), runtime.audio.stats.maximum_service_operations_per_cycle);
    try std.testing.expectEqual(@as(u64, 3), runtime.stats.slices);
    try std.testing.expectEqual(@as(u64, 3 * 123), runtime.stats.requested_operations);
    try std.testing.expectEqual(@as(u64, 3 * 123), runtime.stats.executed_operations);
    try std.testing.expectEqual(runtime.stats.present_attempts, runtime.stats.presents + runtime.stats.skipped_presents);
}

test "zero-operation guest progress blocks for one bounded host tick" {
    var runtime = try Runtime.init(.{ .max_wait_ticks = 1 }, 1000, 0, null);
    var guest = FakeGuest{ .zero_progress = true, .audio_enabled = false };
    var host = FakeHost{};

    const first = runtime.cycle(0, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 1), first.wait);
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.zero_progress_waits);
    try std.testing.expectEqual(@as(u64, 0), runtime.stats.executed_operations);

    const second = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 1), second.wait);
    try std.testing.expectEqual(@as(u64, 2), runtime.stats.zero_progress_waits);
    try std.testing.expectEqual(@as(u32, 2), guest.steps);
}

test "event-only guest waits remain blocked until a handled host event" {
    var runtime = try Runtime.init(.{}, 1000, 0, null);
    var guest = FakeGuest{ .event_waiting = true, .audio_enabled = false };
    var host = FakeHost{};

    const first = runtime.cycle(0, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 0), first.wait);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);
    try std.testing.expect(runtime.guest_waiting);

    const still_waiting = runtime.cycle(50, guest.driver(), host.driver());
    try std.testing.expectEqual(abi.io_wait_forever, still_waiting.wait);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);

    host.ignored_left = 1;
    const ignored = runtime.cycle(50, guest.driver(), host.driver());
    try std.testing.expectEqual(abi.io_wait_forever, ignored.wait);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.ignored_input_events);
    try std.testing.expectEqual(@as(u64, 0), runtime.stats.input_events);

    host.handled_left = 1;
    const woken = runtime.cycle(51, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 0), woken.wait);
    try std.testing.expectEqual(@as(u32, 2), guest.steps);
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.input_events);

    runtime.request(.pause, 51, guest.driver());
    const paused = runtime.cycle(1000, guest.driver(), host.driver());
    try std.testing.expectEqual(abi.io_wait_forever, paused.wait);
    try std.testing.expectEqual(@as(u32, 2), guest.steps);
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.paused_cycles);
}

test "runtime reports hidden unchanged and dropped presentation outcomes separately" {
    var runtime = try Runtime.init(.{}, 1000, 0, null);
    var guest = FakeGuest{ .audio_enabled = false };
    var host = FakeHost{ .present_result = host_present_hidden };

    _ = runtime.cycle(0, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.hidden_presents);
    runtime.present_pending = true;
    host.present_result = host_present_unchanged;
    _ = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.unchanged_presents);
    runtime.present_pending = true;
    host.present_result = host_present_dropped;
    _ = runtime.cycle(2, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.dropped_presents);
    try std.testing.expectEqual(@as(u64, 3), runtime.stats.present_attempts);
    try std.testing.expectEqual(@as(u64, 3), runtime.stats.skipped_presents);
}

test "silent paused muted and active audio paths have separate bounded counters" {
    var silent_queue: [3840]u8 = undefined;
    var silent_scratch: [1920]u8 = undefined;
    var silent_sink = FakeSink{};
    var silent_runtime = try Runtime.init(.{}, 1000, 0, .{
        .queue_storage = silent_queue[0..],
        .scratch = silent_scratch[0..],
        .sink = silent_sink.sink(),
    });
    var silent_guest = FakeGuest{ .audio_byte = 0 };
    var silent_host = FakeHost{};
    _ = silent_runtime.cycle(0, silent_guest.driver(), silent_host.driver());
    _ = silent_runtime.cycle(1, silent_guest.driver(), silent_host.driver());
    try std.testing.expectEqual(@as(u64, 3840), silent_runtime.audio.stats.suppressed_bytes);
    try std.testing.expectEqual(@as(u64, 2), silent_runtime.audio.stats.silent_quanta);
    try std.testing.expectEqual(@as(u64, 3840), silent_guest.feedback_suppressed_bytes);
    try std.testing.expectEqual(@as(u32, 0), silent_sink.opens);
    try std.testing.expectEqual(@as(u32, 0), silent_sink.writes);

    var active_queue: [3840]u8 = undefined;
    var active_scratch: [1920]u8 = undefined;
    var operation_order = OperationOrder{};
    var active_sink = FakeSink{ .order = &operation_order };
    var active_runtime = try Runtime.init(.{}, 1000, 0, .{
        .queue_storage = active_queue[0..],
        .scratch = active_scratch[0..],
        .sink = active_sink.sink(),
    });
    var active_guest = FakeGuest{ .audio_byte = 0x22 };
    var active_host = FakeHost{ .order = &operation_order };
    _ = active_runtime.cycle(1, active_guest.driver(), active_host.driver());
    try std.testing.expectEqual(@as(u32, 1), active_sink.opens);
    try std.testing.expectEqual(@as(u32, 0), active_sink.writes);
    try std.testing.expectEqual(@as(usize, 3840), active_runtime.audio.queue.available());
    try std.testing.expect(operation_order.present < operation_order.open);
    operation_order = .{};
    active_runtime.present_pending = true;
    _ = active_runtime.cycle(1, active_guest.driver(), active_host.driver());
    try std.testing.expectEqual(@as(u32, 1), active_sink.writes);
    try std.testing.expectEqual(@as(u64, 1920), active_guest.feedback_accepted_bytes);
    try std.testing.expectEqual(@as(u64, 1), active_runtime.audio.stats.active_quanta);
    try std.testing.expect(operation_order.present < operation_order.write);

    active_host.push(.pause);
    _ = active_runtime.cycle(2, active_guest.driver(), active_host.driver());
    try std.testing.expectEqual(LifecycleState.paused, active_runtime.state);
    try std.testing.expectEqual(@as(u64, 1920), active_runtime.audio.stats.paused_bytes);
    try std.testing.expectEqual(@as(u64, 1), active_runtime.audio.stats.paused_cycles);
    try std.testing.expectEqual(@as(u32, 1), active_sink.closes);

    active_host.push(.resume_running);
    _ = active_runtime.cycle(3, active_guest.driver(), active_host.driver());
    try std.testing.expectEqual(@as(u32, 2), active_sink.opens);
    active_host.push(.mute);
    _ = active_runtime.cycle(4, active_guest.driver(), active_host.driver());
    try std.testing.expectEqual(@as(u64, 3840), active_runtime.audio.stats.muted_bytes);
    try std.testing.expectEqual(@as(u64, 1), active_runtime.audio.stats.muted_cycles);
    try std.testing.expectEqual(@as(u32, 2), active_sink.closes);
    try std.testing.expectEqual(@as(u16, 1), active_runtime.audio.stats.maximum_service_operations_per_cycle);
}

test "eight silent runtimes open no service sessions" {
    var queue_storage: [8][3840]u8 = undefined;
    var scratch_storage: [8][1920]u8 = undefined;
    var sinks: [8]FakeSink = undefined;
    var guests: [8]FakeGuest = undefined;
    var hosts: [8]FakeHost = undefined;
    var runtimes: [8]Runtime = undefined;
    for (0..8) |index| {
        sinks[index] = .{};
        guests[index] = .{ .audio_byte = 0 };
        hosts[index] = .{};
        runtimes[index] = try Runtime.init(.{}, 1000, 0, .{
            .queue_storage = queue_storage[index][0..],
            .scratch = scratch_storage[index][0..],
            .sink = sinks[index].sink(),
        });
        _ = runtimes[index].cycle(0, guests[index].driver(), hosts[index].driver());
        _ = runtimes[index].cycle(1, guests[index].driver(), hosts[index].driver());
    }
    for (0..8) |index| {
        try std.testing.expectEqual(@as(u32, 0), sinks[index].opens);
        try std.testing.expectEqual(@as(u32, 0), sinks[index].writes);
        try std.testing.expectEqual(@as(u64, 3840), runtimes[index].audio.stats.suppressed_bytes);
        runtimes[index].shutdown();
    }
}

test "open prefill busy and resync use at most one service operation per cycle" {
    var busy_queue: [3840]u8 = undefined;
    var busy_scratch: [1920]u8 = undefined;
    var busy_sink = FakeSink{ .busy_after = 0 };
    var busy_runtime = try Runtime.init(.{}, 1000, 0, .{
        .queue_storage = busy_queue[0..],
        .scratch = busy_scratch[0..],
        .sink = busy_sink.sink(),
    });
    var busy_guest = FakeGuest{ .audio_byte = 0x44 };
    var busy_host = FakeHost{};
    _ = busy_runtime.cycle(1, busy_guest.driver(), busy_host.driver());
    try std.testing.expectEqual(@as(u32, 1), busy_sink.opens);
    try std.testing.expectEqual(@as(u32, 0), busy_sink.writes);
    _ = busy_runtime.cycle(1, busy_guest.driver(), busy_host.driver());
    try std.testing.expectEqual(@as(u64, 1), busy_runtime.audio.stats.busy_writes);
    try std.testing.expectEqual(@as(usize, 3840), busy_runtime.audio.queue.available());
    _ = busy_runtime.cycle(10, busy_guest.driver(), busy_host.driver());
    try std.testing.expectEqual(@as(u64, 1), busy_runtime.audio.stats.busy_writes);
    _ = busy_runtime.cycle(11, busy_guest.driver(), busy_host.driver());
    try std.testing.expectEqual(@as(u64, 2), busy_runtime.audio.stats.busy_writes);
    busy_sink.busy_after = std.math.maxInt(u32);
    _ = busy_runtime.cycle(21, busy_guest.driver(), busy_host.driver());
    try std.testing.expectEqual(@as(u32, 1), busy_sink.writes);
    try std.testing.expectEqual(@as(usize, 1920), busy_runtime.audio.queue.available());
    try std.testing.expectEqual(@as(u16, 1), busy_runtime.audio.stats.maximum_service_operations_per_cycle);

    var resync_queue: [3840]u8 = undefined;
    var resync_scratch: [1920]u8 = undefined;
    var resync_sink = FakeSink{};
    var resync_runtime = try Runtime.init(.{}, 1000, 0, .{
        .queue_storage = resync_queue[0..],
        .scratch = resync_scratch[0..],
        .sink = resync_sink.sink(),
    });
    var resync_guest = FakeGuest{ .audio_byte = 0x33 };
    var resync_host = FakeHost{};
    _ = resync_runtime.cycle(1, resync_guest.driver(), resync_host.driver());
    _ = resync_runtime.cycle(1, resync_guest.driver(), resync_host.driver());
    try std.testing.expectEqual(@as(u32, 1), resync_sink.writes);
    _ = resync_runtime.cycle(25, resync_guest.driver(), resync_host.driver());
    try std.testing.expectEqual(@as(u64, 1), resync_runtime.audio.stats.late_resyncs);
    try std.testing.expectEqual(@as(u64, 1920), resync_runtime.audio.stats.discarded_bytes);
    try std.testing.expectEqual(@as(u32, 2), resync_sink.writes);
    try std.testing.expectEqual(@as(u16, 1), resync_runtime.audio.stats.maximum_service_operations_per_cycle);

    var retry_queue: [3840]u8 = undefined;
    var retry_scratch: [1920]u8 = undefined;
    var retry_sink = FakeSink{ .open_failure_result = audio_error_timeout, .open_failures_remaining = 1 };
    var retry_runtime = try Runtime.init(.{}, 1000, 0, .{
        .queue_storage = retry_queue[0..],
        .scratch = retry_scratch[0..],
        .sink = retry_sink.sink(),
    });
    var retry_guest = FakeGuest{ .audio_byte = 0x55 };
    var retry_host = FakeHost{};
    _ = retry_runtime.cycle(0, retry_guest.driver(), retry_host.driver());
    try std.testing.expectEqual(@as(u32, 1), retry_sink.opens);
    _ = retry_runtime.cycle(49, retry_guest.driver(), retry_host.driver());
    try std.testing.expectEqual(@as(u32, 1), retry_sink.opens);
    _ = retry_runtime.cycle(50, retry_guest.driver(), retry_host.driver());
    try std.testing.expectEqual(@as(u32, 2), retry_sink.opens);
    try std.testing.expectEqual(@as(u32, 0), retry_sink.writes);
    _ = retry_runtime.cycle(50, retry_guest.driver(), retry_host.driver());
    try std.testing.expectEqual(@as(u32, 1), retry_sink.writes);
    try std.testing.expectEqual(@as(u16, 1), retry_runtime.audio.stats.maximum_service_operations_per_cycle);
}

test "guest completion failure and reset failure converge on terminal cleanup" {
    var complete_queue: [3840]u8 = undefined;
    var complete_scratch: [1920]u8 = undefined;
    var complete_sink = FakeSink{};
    var complete_runtime = try Runtime.init(.{}, 100, 0, .{
        .queue_storage = complete_queue[0..],
        .scratch = complete_scratch[0..],
        .sink = complete_sink.sink(),
    });
    var complete_guest = FakeGuest{ .complete_after = 1 };
    var complete_host = FakeHost{};
    const completed = complete_runtime.cycle(0, complete_guest.driver(), complete_host.driver());
    try std.testing.expectEqual(LifecycleState.completed, completed.finished.state);
    try std.testing.expect(complete_runtime.resources_closed);
    try std.testing.expectEqual(@as(u32, 0), complete_sink.closes);

    var fail_queue: [3840]u8 = undefined;
    var fail_scratch: [1920]u8 = undefined;
    var fail_sink = FakeSink{};
    var fail_runtime = try Runtime.init(.{}, 100, 0, .{
        .queue_storage = fail_queue[0..],
        .scratch = fail_scratch[0..],
        .sink = fail_sink.sink(),
    });
    var fail_guest = FakeGuest{ .fail_code = -88 };
    var fail_host = FakeHost{};
    const failed = fail_runtime.cycle(0, fail_guest.driver(), fail_host.driver());
    try std.testing.expectEqual(LifecycleState.failed, failed.finished.state);
    try std.testing.expectEqual(@as(i32, -88), failed.finished.exit_code);
    try std.testing.expect(fail_runtime.resources_closed);
    try std.testing.expectEqual(@as(u32, 0), fail_sink.closes);

    var reset_runtime = try Runtime.init(.{}, 100, 0, null);
    var reset_guest = FakeGuest{ .reset_result = -66 };
    var reset_host = FakeHost{};
    reset_host.push(.reset);
    const reset_failed = reset_runtime.cycle(0, reset_guest.driver(), reset_host.driver());
    try std.testing.expectEqual(LifecycleState.failed, reset_failed.finished.state);
    try std.testing.expectEqual(@as(i32, -66), reset_failed.finished.exit_code);
    try std.testing.expect(reset_runtime.resources_closed);
}

test "two runtimes isolate clock queue host state and an audio failure" {
    var queue_a: [3840]u8 = undefined;
    var scratch_a: [1920]u8 = undefined;
    var sink_a = FakeSink{};
    var runtime_a = try Runtime.init(.{}, 100, 0, .{ .queue_storage = queue_a[0..], .scratch = scratch_a[0..], .sink = sink_a.sink() });
    var guest_a = FakeGuest{ .audio_byte = 0x11 };
    var host_a = FakeHost{};

    var queue_b: [3840]u8 = undefined;
    var scratch_b: [1920]u8 = undefined;
    var sink_b = FakeSink{ .write_error_after = 0 };
    var runtime_b = try Runtime.init(.{}, 100, 0, .{ .queue_storage = queue_b[0..], .scratch = scratch_b[0..], .sink = sink_b.sink() });
    var guest_b = FakeGuest{ .audio_byte = 0x22 };
    var host_b = FakeHost{};

    _ = runtime_a.cycle(0, guest_a.driver(), host_a.driver());
    _ = runtime_b.cycle(0, guest_b.driver(), host_b.driver());
    runtime_a.request(.pause, 0, guest_a.driver());
    _ = runtime_a.cycle(1, guest_a.driver(), host_a.driver());
    _ = runtime_b.cycle(1, guest_b.driver(), host_b.driver());

    try std.testing.expectEqual(LifecycleState.paused, runtime_a.state);
    try std.testing.expectEqual(LifecycleState.running, runtime_b.state);
    try std.testing.expectEqual(AudioState.ready, runtime_a.audio.state);
    try std.testing.expectEqual(AudioState.degraded, runtime_b.audio.state);
    try std.testing.expectEqual(@as(i32, -77), runtime_b.audio.last_error);
    try std.testing.expect(runtime_a.clock.guest_ns < runtime_b.clock.guest_ns);
    try std.testing.expectEqual(@as(u32, 1), guest_a.steps);
    try std.testing.expectEqual(@as(u32, 2), guest_b.steps);
    try std.testing.expectEqual(@as(u64, 0), runtime_a.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 3840), runtime_a.audio.stats.paused_bytes);
    try std.testing.expectEqual(@as(u64, 3840), runtime_a.audio.stats.discarded_bytes);
    try std.testing.expectEqual(@as(u64, 0), runtime_b.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 3840), runtime_b.audio.stats.discarded_bytes);
    try std.testing.expectEqual(@as(usize, 0), runtime_a.audio.queue.available());
    try std.testing.expectEqual(@as(usize, 0), runtime_b.audio.queue.available());
    const degraded_renders = guest_b.audio_renders;
    const degraded_cycle = runtime_b.cycle(100, guest_b.driver(), host_b.driver());
    try std.testing.expectEqual(@as(u64, 0), degraded_cycle.wait);
    try std.testing.expectEqual(degraded_renders, guest_b.audio_renders);
    try std.testing.expectEqual(@as(u64, 3840), runtime_b.audio.stats.discarded_bytes);
    runtime_a.shutdown();
    runtime_b.shutdown();
    try std.testing.expectEqual(@as(u32, 1), sink_a.closes);
    try std.testing.expectEqual(@as(u32, 1), sink_b.closes);
}
