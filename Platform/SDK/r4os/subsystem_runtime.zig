const std = @import("std");
const abi = @import("r4os_contract").abi;
const app_audio = @import("app_audio.zig");
const r4sys = @import("r4sys.zig");
const time_contract = @import("time_contract.zig");
const transport = @import("subsystem_audio_transport.zig");
pub const AudioCompletion = transport.Completion;
pub const AudioFinish = transport.Finish;

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
/// speaker playback. Optional frame progress is canonical48k PCM attributed
/// to validated DMA consumption, with unconfirmed tails kept separate.
pub const AudioFeedback = struct {
    state: AudioState,
    muted: bool,
    accepted_bytes: u64 = 0,
    suppressed_bytes: u64 = 0,
    discarded_bytes: u64 = 0,
    playback_frames: ?u64 = null,
    backend_frames: u64 = 0,
    dma_frames: u64 = 0,
    unconfirmed_frames: u64 = 0,
    queued_frames: u64 = 0,
    queue_age_ns: u64 = 0,
    source_starvations: u64 = 0,
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
    continuous: bool = false,
    low_water_frames: u32 = 960,
    high_water_frames: u32 = 1920,

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
    poll_fn: ?*const fn (*anyopaque) ?transport.Completion = null,
    finish_fn: ?*const fn (*anyopaque) transport.Finish = null,
    progress_fn: ?*const fn (*anyopaque) i32 = null,

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
    transport_owner: ?*anyopaque = null,
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

    /// Open/Write/Volume/idle Close use one owned Async Service request.
    /// Terminal shutdown separately drains the original request and stream.
    pub fn initWithTimeouts(audio: app_audio.Audio, timeout_nanoseconds: u64, close_timeout_nanoseconds: u64) R4AudioSink {
        return .{
            .audio = audio,
            .timeout = time_contract.timeoutFinite(.{ .nanoseconds = timeout_nanoseconds }),
            .close_timeout = time_contract.timeoutFinite(.{ .nanoseconds = close_timeout_nanoseconds }),
        };
    }

    fn owner(self: *R4AudioSink) ?*transport.Transport {
        return if (self.transport_owner) |raw| @ptrCast(@alignCast(raw)) else null;
    }

    pub fn sink(self: *R4AudioSink) AudioSink {
        return .{
            .context = self,
            .open_fn = r4AudioOpen,
            .write_fn = r4AudioWrite,
            .volume_fn = r4AudioVolume,
            .close_fn = r4AudioClose,
            .poll_fn = r4AudioPoll,
            .progress_fn = r4AudioProgress,
            .finish_fn = r4AudioFinish,
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
    playback_frames: ?u64 = null,
    backend_frames: u64 = 0,
    dma_frames: u64 = 0,
    unconfirmed_frames: u64 = 0,
    queued_frames: u64 = 0,
    queue_age_ns: u64 = 0,
    source_starvations: u64 = 0,
    progress_queries: u64 = 0,
    retired_playback_frames: u64 = 0,
    retired_unconfirmed_frames: u64 = 0,
    backend_generation: u64 = 0,
    output_generation: u64 = 0,
    reset_generation: u64 = 0,
    stream_generation: u64 = 0,
    progress_observed_ns: u64 = 0,
    generated_bytes: u64 = 0,
    submitted_bytes: u64 = 0,
    discarded_bytes: u64 = 0,
    retired_submitted_bytes: u64 = 0,
    retired_discarded_bytes: u64 = 0,
    async_submissions: u64 = 0,
    async_completions: u64 = 0,
    async_pending_cycles: u64 = 0,
    partial_writes: u64 = 0,
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
    pending,
    busy,
    failed,
};

pub const AudioPump = struct {
    const DiscardReason = enum { other, pause, mute };
    config: AudioConfig = .{},
    queue: PcmQueue = .{ .storage = @constCast(empty_audio_storage[0..]) },
    scratch: []u8 = @constCast(empty_audio_storage[0..]),
    sink: ?AudioSink = null,
    state: AudioState = .disabled,
    last_error: i32 = 0,
    muted: bool = false,
    next_deadline_tick: u64 = 0,
    quantum_ticks: u64 = 1,
    monotonic_hz: u32 = 0,
    busy_retry_ticks: u64 = 1,
    open_retry_ticks: u64 = 1,
    open_retry_attempts: u16 = 0,
    resync_prefill_quanta: u16 = 0,
    sink_open: bool = false,
    close_pending: bool = false,
    pending_operation: ?transport.Operation = null,
    pending_bytes: usize = 0,
    pending_idle_close: bool = false,
    discard_after_pending: bool = false,
    pending_discard_reason: DiscardReason = .other,
    retire_pending_feedback: bool = false,
    sink_generation: u64 = 0,
    close_error: i32 = 0,
    close_retry_tick: u64 = 0,
    service_operations_cycle: u16 = 0,
    stats: AudioStats = .{},
    progress_record: abi.AudioServiceStreamProgressState = .{},
    progress_seen: bool = false,
    progress_ready: bool = false,
    progress_due_tick: u64 = 0,
    feedback_retire_current: bool = false,
    progress_record_retired: bool = false,

    fn init(options: AudioOptions, monotonic_hz: u32) Error!AudioPump {
        if (options.sink) |sink| if (sink.poll_fn != null and sink.finish_fn == null) return Error.InvalidAudioConfiguration;
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
            .monotonic_hz = monotonic_hz,
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
        if (self.pending_operation != null) self.stats.async_pending_cycles +%= 1;
    }

    fn noteServiceOperation(self: *AudioPump) void {
        self.service_operations_cycle +|= 1;
        self.stats.service_operations +%= 1;
        self.stats.maximum_service_operations_per_cycle = @max(
            self.stats.maximum_service_operations_per_cycle,
            self.service_operations_cycle,
        );
    }

    fn tryOpen(self: *AudioPump, now: u64, clock: ?*const r4sys.Context) bool {
        if (self.close_pending or self.service_operations_cycle != 0) return false;
        const sink = self.sink orelse {
            self.degrade(audio_error_unavailable);
            return false;
        };
        self.noteServiceOperation();
        self.stats.open_operations +%= 1;
        self.feedback_retire_current = false;
        const rc = sink.open(self.config);
        if (rc == transport.pending and sink.poll_fn != null) {
            self.beginPending(.open, 0);
            // Own even an uncertain Open until its reply/abandonment fence.
            self.sink_open = true;
            return false;
        }
        return self.completeOpen(rc, currentHostTick(clock, now));
    }

    fn completeOpen(self: *AudioPump, rc: i32, now: u64) bool {
        if (rc < 0) {
            if (self.sink_open) self.close_pending = true;
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
        self.progress_ready = false;
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
        self.feedback_retire_current = true;
        self.progress_record_retired = self.progress_seen;
        self.resumePlayback(now);
    }

    fn resumePlayback(self: *AudioPump, now: u64) void {
        if (self.state == .disabled or self.state == .degraded or self.state == .closed) return;
        self.enterIdle();
        // Pause/resume keeps the guest's outstanding PCM: a late Close cursor
        // still retires that exact data. Only a new guest/capture epoch hides it.
        self.next_deadline_tick = if (now == 0) 1 else now;
    }

    fn pause(self: *AudioPump, now: u64) void {
        _ = now;
        if (self.state == .disabled or self.state == .degraded or self.state == .closed) return;
        self.enterIdleAs(.pause);
    }

    fn setMuted(self: *AudioPump, muted: bool, now: u64) void {
        if (self.muted == muted) return;
        self.muted = muted;
        if (self.state == .degraded) return;
        if (muted) {
            self.enterIdleAs(.mute);
        } else {
            self.reset(now);
        }
    }

    fn fill(self: *AudioPump, guest: GuestDriver, now: u64, guest_stepped: bool) i32 {
        if (self.pending_operation != null or self.close_pending) return 0;
        if ((self.state != .ready and self.state != .active) or self.muted) return 0;
        // A waiting producer has no new work until its next step or a due
        // audio quantum. In particular, host polls must not drain future PCM.
        if (!guest_stepped and (self.next_deadline_tick == 0 or now < self.next_deadline_tick)) return 0;
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
            // Silence occupies the same bounded timeline as audible PCM.
            // Suppress it only when due, preserving any following signal.
            if (self.queue.write(self.scratch[0..count]) != count) return runtime_error_guest_audio;
        }
        return 0;
    }

    fn resyncLate(self: *AudioPump, now: u64) void {
        if (self.pending_operation != null) return;
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
        self.pollPending(now, null);
        self.pumpReady(now, running, null);
    }

    fn pumpReady(self: *AudioPump, now: u64, running: bool, clock: ?*const r4sys.Context) void {
        if (self.pending_operation != null) return;
        if (self.close_pending) {
            if (now < self.close_retry_tick) return;
            self.closeSink(false);
            if (self.close_pending and self.pending_operation == null) self.close_retry_tick = currentHostTick(clock, now) +| self.busy_retry_ticks;
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
        if (self.service_operations_cycle != 0) return;
        if (self.config.continuous and self.progress_ready and now >= self.progress_due_tick and
            (self.queue.available() == 0 or now < self.next_deadline_tick))
        {
            if (self.sink) |sink| if (sink.progress_fn) |query| {
                self.noteServiceOperation();
                self.stats.progress_queries +%= 1;
                const rc = query(sink.context);
                self.progress_due_tick = currentHostTick(clock, now) +| @max(self.quantum_ticks / 2, 1);
                if (rc == transport.pending) self.beginPending(.progress, 0) else if (rc < 0 and rc != abi.service_api_result_busy) self.degrade(rc);
                return;
            };
        }
        if (now < self.next_deadline_tick) return;
        const copied = self.queue.peek(self.scratch);
        if (copied == 0) {
            // A transient producer gap is not an explicit silent block.
            // Keep an active stream and retry at a bounded future deadline.
            self.next_deadline_tick = if (self.state == .active) currentHostTick(clock, now) +| self.quantum_ticks else 0;
            return;
        }
        // Only an unmaterialized discrete source may omit initial silence.
        // Null PCM in an active stream still occupies its exact timeline;
        // producer pause/stop/idle, not sample values, owns Close.
        if (!self.config.continuous and !self.sink_open and isZeroPcm(self.scratch[0..copied])) {
            _ = self.queue.discard(copied);
            self.stats.silence_bytes +%= copied;
            self.stats.suppressed_bytes +%= copied;
            self.stats.idle_quanta +%= 1;
            self.stats.silent_quanta +%= 1;
            const frame_ticks = @as(u128, copied / self.queue.frame_bytes) * self.monotonic_hz;
            const duration: u64 = @intCast((frame_ticks + self.config.sample_rate - 1) / self.config.sample_rate);
            self.next_deadline_tick = now +| @max(@as(u64, 1), duration);
            self.resync_prefill_quanta = 0;
            self.open_retry_attempts = 0;
            if (self.state != .degraded) self.state = .ready;
            return;
        }
        if (self.state == .ready) {
            _ = self.tryOpen(now, clock);
            return;
        }
        if (self.resync_prefill_quanta != 0) {
            switch (self.submitQuantum(copied)) {
                .submitted => {
                    self.resync_prefill_quanta -= 1;
                    const accepted_tick = currentHostTick(clock, now);
                    self.next_deadline_tick = if (self.resync_prefill_quanta == 0)
                        accepted_tick +| self.quantum_ticks
                    else
                        accepted_tick;
                },
                .busy => self.next_deadline_tick = currentHostTick(clock, now) +| self.busy_retry_ticks,
                .pending, .failed => {},
            }
            return;
        }
        switch (self.submitQuantum(copied)) {
            .submitted => self.next_deadline_tick +|= self.quantum_ticks,
            .busy => self.next_deadline_tick = currentHostTick(clock, now) +| self.busy_retry_ticks,
            .pending, .failed => {},
        }
    }

    fn submitQuantum(self: *AudioPump, copied: usize) SubmitResult {
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
        if (written == transport.pending and sink.poll_fn != null) {
            self.beginPending(.write, copied);
            return .pending;
        }
        return self.completeWrite(written, copied);
    }

    fn completeWrite(self: *AudioPump, written: i32, copied: usize) SubmitResult {
        if (written == abi.service_api_result_busy) {
            self.stats.busy_writes +%= 1;
            return .busy;
        }
        if (written <= 0 or written > @as(i32, @intCast(copied)) or
            @as(usize, @intCast(written)) % self.queue.frame_bytes != 0)
        {
            self.stats.write_failures +%= 1;
            self.degrade(if (written < 0) written else audio_error_unavailable);
            return .failed;
        }
        const accepted: usize = @intCast(written);
        _ = self.queue.discard(accepted);
        self.stats.submitted_bytes +%= accepted;
        if (isZeroPcm(self.scratch[0..accepted])) self.stats.silence_bytes +%= accepted;
        if (self.config.continuous) {
            if (self.sink) |sink| {
                self.progress_ready = sink.progress_fn != null;
                if (sink.progress_fn == null and self.config.sample_rate == 48000) {
                    const frames = accepted / self.queue.frame_bytes;
                    self.stats.unconfirmed_frames +%= frames;
                    if (self.feedback_retire_current or self.retire_pending_feedback) self.stats.retired_unconfirmed_frames +%= frames;
                }
            }
        }
        if (self.retire_pending_feedback) self.stats.retired_submitted_bytes +%= accepted;
        self.stats.writes +%= 1;
        if (accepted != copied) {
            self.stats.partial_writes +%= 1;
            return .busy;
        }
        if (copied < self.scratch.len) self.stats.underflows +%= 1;
        self.stats.active_quanta +%= 1;
        return .submitted;
    }

    fn beginPending(self: *AudioPump, operation: transport.Operation, bytes: usize) void {
        std.debug.assert(self.pending_operation == null);
        self.pending_operation = operation;
        self.pending_bytes = bytes;
        self.stats.async_submissions +%= 1;
    }

    fn pollPending(self: *AudioPump, now: u64, clock: ?*const r4sys.Context) void {
        if (self.pending_operation == null) return;
        const sink = self.sink orelse return;
        const poll = sink.poll_fn orelse return;
        if (poll(sink.context)) |completion| self.completePending(completion, currentHostTick(clock, now), false);
    }

    fn completePending(self: *AudioPump, completion: transport.Completion, now: u64, terminal: bool) void {
        const operation = self.pending_operation orelse return;
        const generation_ok = if (operation == .open)
            completion.generation > self.sink_generation
        else
            completion.generation == self.sink_generation;
        var rc = completion.result;
        if (completion.operation != operation or completion.request_id == 0 or !generation_ok) rc = abi.service_api_result_invalid;
        if (operation == .open and generation_ok) self.sink_generation = completion.generation;
        const bytes = self.pending_bytes;
        self.pending_operation = null;
        self.pending_bytes = 0;
        self.stats.async_completions +%= 1;
        if (completion.requests > 1) {
            self.stats.async_submissions +%= completion.requests - 1;
            self.stats.async_completions +%= completion.requests - 1;
            self.stats.service_operations +%= completion.requests - 1;
        }
        if (completion.progress) |record| self.applyProgress(record);
        self.progress_due_tick = now +| @max(self.quantum_ticks / 2, 1);
        switch (operation) {
            .open => {
                _ = self.completeOpen(rc, now);
            },
            .write => switch (self.completeWrite(rc, bytes)) {
                .submitted => {
                    if (self.resync_prefill_quanta != 0) {
                        self.resync_prefill_quanta -= 1;
                        self.next_deadline_tick = if (self.resync_prefill_quanta == 0) now +| self.quantum_ticks else now;
                    } else self.next_deadline_tick +|= self.quantum_ticks;
                },
                .busy => self.next_deadline_tick = now +| self.busy_retry_ticks,
                .pending, .failed => {},
            },
            .close => self.completeClose(rc),
            .progress => {
                if (rc < 0 and rc != abi.service_api_result_busy) self.degrade(rc);
            },
            .volume, .fence => self.degrade(abi.service_api_result_invalid),
        }
        if (self.discard_after_pending) {
            const reason = self.pending_discard_reason;
            self.pending_discard_reason = .other;
            self.discard_after_pending = false;
            // Finish has already drained/destroyed its owner. Applying the
            // last receipt must not post another operation into that owner.
            if (terminal) self.discardQueueAs(reason) else self.enterIdleAs(reason);
        }
        self.retire_pending_feedback = false;
    }

    fn applyProgress(self: *AudioPump, record: abi.AudioServiceStreamProgressState) void {
        const p = record.progress;
        if ((p.flags & abi.audio_progress_source_valid) == 0 or p.stream_generation == 0) return;
        if (p.rate != 48000 or p.channels != 2 or p.format != @intFromEnum(abi.AudioFormat.s16le) or
            p.consumed_frames > p.submitted_frames or p.submitted_frames > p.backend_frames or p.backend_frames > p.accepted_frames or
            p.unconfirmed_frames > p.accepted_frames - p.consumed_frames or
            p.queued_frames != p.accepted_frames - p.consumed_frames - p.unconfirmed_frames)
        {
            self.degrade(abi.service_api_result_invalid);
            return;
        }
        const same = self.progress_seen and record.service_epoch == self.progress_record.service_epoch and
            record.stream_generation == self.progress_record.stream_generation and p.stream_generation == self.progress_record.progress.stream_generation;
        const old = if (same) self.progress_record.progress else abi.AudioStreamProgress{};
        if (p.consumed_frames < old.consumed_frames or p.submitted_frames < old.submitted_frames or p.backend_frames < old.backend_frames or
            p.unconfirmed_frames < old.unconfirmed_frames or p.source_starvations < old.source_starvations)
        {
            self.degrade(abi.service_api_result_invalid);
            return;
        }
        if (self.progress_seen and !same) {
            self.stats.unconfirmed_frames +%= self.progress_record.progress.queued_frames;
            if (self.progress_record_retired) self.stats.retired_unconfirmed_frames +%= self.progress_record.progress.queued_frames;
        }
        if (self.stats.playback_frames != null or (p.flags & abi.audio_progress_device_valid) != 0 or p.consumed_frames != 0)
            self.stats.playback_frames = (self.stats.playback_frames orelse 0) +% (p.consumed_frames - old.consumed_frames);
        self.stats.backend_frames +%= p.backend_frames - old.backend_frames;
        self.stats.dma_frames +%= p.submitted_frames - old.submitted_frames;
        self.stats.unconfirmed_frames +%= p.unconfirmed_frames - old.unconfirmed_frames;
        if (self.feedback_retire_current) {
            self.stats.retired_playback_frames +%= p.consumed_frames - old.consumed_frames;
            self.stats.retired_unconfirmed_frames +%= p.unconfirmed_frames - old.unconfirmed_frames;
        }
        self.stats.source_starvations +%= p.source_starvations - old.source_starvations;
        self.stats.queued_frames = p.queued_frames;
        self.stats.queue_age_ns = p.queue_age_ns;
        self.stats.backend_generation = p.backend_generation;
        self.stats.output_generation = p.output_generation;
        self.stats.reset_generation = p.reset_generation;
        self.stats.stream_generation = p.stream_generation;
        self.stats.progress_observed_ns = p.observed_ns;
        self.progress_record = record;
        self.progress_seen = true;
        self.progress_record_retired = self.feedback_retire_current;
    }

    fn discardQueue(self: *AudioPump) void {
        self.discardQueueAs(.other);
    }

    fn discardQueueAs(self: *AudioPump, reason: DiscardReason) void {
        const discarded = self.queue.available();
        self.queue.clear();
        self.stats.discarded_bytes +%= discarded;
        switch (reason) {
            .pause => self.stats.paused_bytes +%= discarded,
            .mute => self.stats.muted_bytes +%= discarded,
            .other => {},
        }
        if (self.retire_pending_feedback) self.stats.retired_discarded_bytes +%= discarded;
    }

    fn enterIdle(self: *AudioPump) void {
        self.enterIdleAs(.other);
    }

    fn enterIdleAs(self: *AudioPump, reason: DiscardReason) void {
        if (self.pending_operation != null) {
            // Keep the first owner's reason until its real receipt excludes
            // the accepted prefix; subsequent resume/reset must not re-label it.
            if (!self.discard_after_pending) self.pending_discard_reason = reason;
            self.discard_after_pending = true;
            self.close_pending = true;
            self.pending_idle_close = true;
        } else self.discardQueueAs(reason);
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
        if (self.pending_operation != null) self.discard_after_pending = true else self.discardQueue();
        self.resync_prefill_quanta = 0;
        self.next_deadline_tick = 0;
        self.open_retry_attempts = 0;
        self.state = .degraded;
        self.last_error = if (error_code < 0) error_code else audio_error_unavailable;
    }

    fn closeSink(self: *AudioPump, idle: bool) void {
        self.pending_idle_close = self.pending_idle_close or idle;
        if (self.pending_operation != null) {
            self.close_pending = true;
            return;
        }
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
        if (rc == transport.pending and sink.poll_fn != null) {
            self.beginPending(.close, 0);
            self.close_pending = true;
            return;
        }
        self.completeClose(rc);
    }

    fn completeClose(self: *AudioPump, rc: i32) void {
        if (rc < 0) {
            if (self.sink) |sink| if (sink.poll_fn != null) {
                self.close_pending = true;
                // A busy mixer reservation or lost finite reply is retried
                // against the same stream; neither permanently degrades a
                // healthy paused/resuming producer nor claims stream absence.
                if (rc != abi.service_api_result_busy and rc != abi.service_api_result_timeout and rc != audio_error_timeout) {
                    self.state = .degraded;
                    self.last_error = rc;
                }
                return;
            };
            self.state = .degraded;
            self.last_error = rc;
        }
        self.progress_ready = false;
        self.sink_open = false;
        self.close_pending = false;
        if (rc == 0 and self.state != .degraded) self.last_error = 0;
        if (rc == 0 and self.pending_idle_close) self.stats.idle_closes +%= 1;
        self.pending_idle_close = false;
    }

    fn close(self: *AudioPump) void {
        if (self.state == .closed or self.state == .disabled) return;
        if (self.sink) |sink| {
            if (sink.finish_fn) |finish| {
                const finished = finish(sink.context);
                self.stats.close_operations +%= finished.control_requests;
                self.stats.service_operations +%= finished.control_requests;
                self.stats.async_submissions +%= finished.control_requests;
                self.stats.async_completions +%= finished.control_requests;
                if (finished.completion) |completion| self.completePending(completion, 0, true);
                if (finished.progress) |record| self.applyProgress(record);
                self.close_error = finished.error_code;
                if (self.pending_operation != null and self.close_error == 0) self.close_error = abi.service_api_result_invalid;
                if (self.close_error < 0) self.last_error = self.close_error;
                self.sink_open = false;
            } else if (self.sink_open) self.closeSink(false);
        }
        self.discardQueue();
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
    audio_feedback_playback_frames: ?u64 = null,
    audio_feedback_unconfirmed_frames: u64 = 0,
    audio_feedback_playback_base: u64 = 0,
    audio_feedback_unconfirmed_base: u64 = 0,
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
                self.audio.resumePlayback(host_tick);
                self.state = .running;
                self.stats.resumes +%= 1;
            },
            .toggle_pause => self.request(if (self.state == .paused) .resume_running else .pause, host_tick, guest),
            .reset => {
                self.audio.retire_pending_feedback = self.audio.pending_operation != null;
                const rc = guest.reset();
                if (rc < 0) {
                    self.fail(rc);
                    return;
                }
                self.clock.reset(host_tick);
                self.audio.reset(host_tick);
                self.audio_feedback_submitted_bytes = self.audio.stats.submitted_bytes -| self.audio.stats.retired_submitted_bytes;
                self.audio_feedback_discarded_bytes = self.audio.stats.discarded_bytes -| self.audio.stats.retired_discarded_bytes;
                self.audio_feedback_suppressed_bytes = self.audio.stats.suppressed_bytes;
                self.audio_feedback_playback_base = (self.audio.stats.playback_frames orelse 0) -| self.audio.stats.retired_playback_frames;
                self.audio_feedback_unconfirmed_base = self.audio.stats.unconfirmed_frames -| self.audio.stats.retired_unconfirmed_frames;
                self.audio_feedback_playback_frames = if (self.audio.stats.playback_frames != null) 0 else null;
                self.audio_feedback_unconfirmed_frames = 0;
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
        return self.cycleWork(host_tick, guest, host, null) orelse .{ .wait = self.nextWait(host_tick) };
    }

    // Only terminal work returns a result. Live callers choose their wait after
    // all guest/presentation/I/O work; cycle retains its explicit tick snapshot.
    // The run clock is borrowed solely through these synchronous calls.
    fn cycleWork(self: *Runtime, host_tick: u64, guest: GuestDriver, host: HostDriver, clock: ?*const r4sys.Context) ?CycleResult {
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
        var guest_stepped = false;
        if (self.state == .running and guest_ready) {
            guest_stepped = true;
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

        // A ready frame is published before any audio service operation.
        // Pending polls can also post the next bounded RPC in a continuous
        // stream's discovery/flow/write chain. Poll only below presentation,
        // then refill the source before choosing the next service operation.
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

        // A completed progress request must release its owned I/O before
        // producer refill. Otherwise frequent queries can keep an empty
        // software queue from receiving already buffered source PCM.
        self.audio.pollPending(host_tick, clock);
        if (self.state == .running) {
            const audio_fill = self.audio.fill(guest, host_tick, guest_stepped);
            if (audio_fill < 0) self.fail(audio_fill);
        }
        self.audio.pumpReady(host_tick, self.state == .running, clock);
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
        return null;
    }

    pub fn run(self: *Runtime, sys: *const r4sys.Context, guest: GuestDriver, host: HostDriver) i32 {
        var host_tick = sys.ticks();
        self.start(host_tick);
        defer self.shutdown();
        while (true) {
            if (self.cycleWork(host_tick, guest, host, sys)) |finished| return finished.finished.exit_code;
            host_tick = sys.ticks();
            const ticks = self.nextWait(host_tick);
            if (ticks == 0) {
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
            host_tick = sys.ticks();
        }
    }

    pub fn shutdown(self: *Runtime) void {
        if (self.resources_closed) return;
        self.audio.close();
        self.resources_closed = self.audio.close_error == 0;
    }

    fn fail(self: *Runtime, raw: i32) void {
        self.state = .failed;
        self.exit_code = if (raw == 0) -1 else raw;
    }

    fn finish(self: *Runtime) CycleResult {
        self.shutdown();
        if (self.audio.close_error < 0 and self.exit_code == 0) {
            self.state = .failed;
            self.exit_code = self.audio.close_error;
        }
        return .{ .finished = .{ .state = self.state, .exit_code = self.exit_code } };
    }

    fn deliverAudioFeedback(self: *Runtime, guest: GuestDriver) void {
        const submitted = self.audio.stats.submitted_bytes -| self.audio.stats.retired_submitted_bytes;
        const discarded_total = self.audio.stats.discarded_bytes -| self.audio.stats.retired_discarded_bytes;
        const accepted = submitted -| self.audio_feedback_submitted_bytes;
        const suppressed = self.audio.stats.suppressed_bytes -| self.audio_feedback_suppressed_bytes;
        const discarded = discarded_total -| self.audio_feedback_discarded_bytes;
        const state_changed = !self.audio_feedback_initialized or
            self.audio_feedback_state != self.audio.state or
            self.audio_feedback_muted != self.audio.muted;
        const unavailable_wait = self.guest_waiting and (self.audio.muted or switch (self.audio.state) {
            .disabled, .degraded, .closed => true,
            .ready, .active => false,
        });
        const playback_frames: ?u64 = if (self.audio.stats.playback_frames) |n| n -| self.audio.stats.retired_playback_frames -| self.audio_feedback_playback_base else null;
        const unconfirmed_frames = self.audio.stats.unconfirmed_frames -| self.audio.stats.retired_unconfirmed_frames -| self.audio_feedback_unconfirmed_base;
        const playback_changed = self.audio_feedback_playback_frames != playback_frames or
            self.audio_feedback_unconfirmed_frames != unconfirmed_frames;
        if (!state_changed and !playback_changed and accepted == 0 and suppressed == 0 and discarded == 0 and !unavailable_wait) return;

        self.audio_feedback_submitted_bytes = submitted;
        self.audio_feedback_suppressed_bytes = self.audio.stats.suppressed_bytes;
        self.audio_feedback_discarded_bytes = discarded_total;
        self.audio_feedback_state = self.audio.state;
        self.audio_feedback_muted = self.audio.muted;
        self.audio_feedback_initialized = true;
        self.audio_feedback_playback_frames = playback_frames;
        self.audio_feedback_unconfirmed_frames = unconfirmed_frames;
        if (guest.audioFeedback(.{
            .state = self.audio.state,
            .muted = self.audio.muted,
            .accepted_bytes = accepted,
            .suppressed_bytes = suppressed,
            .discarded_bytes = discarded,
            .playback_frames = playback_frames,
            .backend_frames = self.audio.stats.backend_frames,
            .dma_frames = self.audio.stats.dma_frames,
            .unconfirmed_frames = unconfirmed_frames,
            .queued_frames = self.audio.stats.queued_frames,
            .queue_age_ns = self.audio.stats.queue_age_ns,
            .source_starvations = self.audio.stats.source_starvations,
        })) {
            self.guest_wake_ns = 0;
            self.guest_waiting = false;
            self.guest_idle_polling = false;
        }
    }

    fn nextWait(self: *const Runtime, host_tick: u64) u64 {
        if (self.host_backlog_pending or self.post_present_poll_pending) return 0;
        var wait = self.config.max_wait_ticks;
        if (self.audio.close_pending and self.audio.pending_operation == null) wait = @min(wait, self.audio.close_retry_tick -| host_tick);
        // GUI activity does not signal completion of the separate audio RPC.
        // Observe an outstanding request on the next scheduler tick. The
        // device-busy delay applies only after an actual busy reply; using it
        // here can spend an entire PCM quantum asleep between chained replies.
        if (self.audio.pending_operation != null) wait = @min(wait, 1);
        if (self.audio.pending_operation == null and self.audio.progress_ready and self.audio.config.continuous)
            wait = @min(wait, self.audio.progress_due_tick -| host_tick);
        if (self.state == .running) {
            if (self.guest_idle_polling) {
                wait = @min(wait, self.config.idle_retry_ticks);
            } else if (!self.guest_waiting) {
                return 0;
            } else if (self.guest_wake_ns != 0) {
                var guest_clock = self.clock;
                _ = guest_clock.sync(host_tick);
                wait = @min(wait, guest_clock.ticksUntil(self.guest_wake_ns));
            }
        }
        if (self.audio.pending_operation == null and (self.audio.state == .ready or self.audio.state == .active) and self.audio.next_deadline_tick != 0) {
            const audio_wait = if (host_tick >= self.audio.next_deadline_tick) @as(u64, 0) else self.audio.next_deadline_tick - host_tick;
            wait = @min(wait, audio_wait);
        }
        return wait;
    }
};

fn currentHostTick(clock: ?*const r4sys.Context, fallback_tick: u64) u64 {
    return if (clock) |sys| sys.ticks() else fallback_tick;
}

fn ticksForNanoseconds(frequency_hz: u32, nanoseconds: u64) u64 {
    const product = @as(u128, frequency_hz) * nanoseconds;
    const ticks = (product + time_contract.nanoseconds_per_second - 1) / time_contract.nanoseconds_per_second;
    return @max(@as(u64, 1), @as(u64, @intCast(ticks)));
}

fn r4AudioOpen(context: *anyopaque, config: AudioConfig) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    if (!self.audio.available()) return audio_error_unavailable;
    if (self.transport_owner == null) self.transport_owner = transport.Transport.create(self.audio.sys, self.timeout, self.close_timeout) orelse return audio_error_unavailable;
    const owner = self.owner().?;
    owner.continuous = config.continuous;
    owner.low_water_frames = config.low_water_frames;
    owner.high_water_frames = config.high_water_frames;
    return owner.open(config.sample_rate, config.channels, config.volume);
}
fn r4AudioWrite(context: *anyopaque, data: []const u8) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    return (self.owner() orelse return abi.err_closed).write(data);
}
fn r4AudioVolume(context: *anyopaque, volume: u32) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    return (self.owner() orelse return abi.err_closed).volume(volume);
}
fn r4AudioClose(context: *anyopaque) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    return (self.owner() orelse return 0).close();
}
fn r4AudioPoll(context: *anyopaque) ?transport.Completion {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    return (self.owner() orelse return null).poll();
}
fn r4AudioProgress(context: *anyopaque) i32 {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    return (self.owner() orelse return abi.err_closed).progress();
}
fn r4AudioFinish(context: *anyopaque) transport.Finish {
    const self: *R4AudioSink = @ptrCast(@alignCast(context));
    const owner = self.owner() orelse return .{};
    self.transport_owner = null;
    return owner.finish();
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

fn playbackTestSnapshot(consumed: u64, unconfirmed: u64) abi.AudioServiceStreamProgressState {
    return .{ .service_epoch = 8, .stream_generation = 2, .progress = .{
        .flags = abi.audio_progress_source_valid | abi.audio_progress_device_valid,
        .stream_id = 7,
        .stream_generation = 9,
        .backend_generation = 10,
        .output_generation = 3,
        .reset_generation = 1,
        .accepted_frames = 480,
        .backend_frames = 480,
        .submitted_frames = 480,
        .consumed_frames = consumed,
        .unconfirmed_frames = unconfirmed,
        .queued_frames = 480 - consumed - unconfirmed,
    } };
}

test "audio progress keeps consumed and reset-unconfirmed frames across stream generations" {
    var pump = AudioPump{};
    pump.applyProgress(playbackTestSnapshot(120, 0));
    try std.testing.expectEqual(@as(?u64, 120), pump.stats.playback_frames);
    var reset_record = playbackTestSnapshot(240, 240);
    reset_record.progress.reset_generation = 2;
    pump.applyProgress(reset_record);
    try std.testing.expectEqual(@as(?u64, 240), pump.stats.playback_frames);
    try std.testing.expectEqual(@as(u64, 240), pump.stats.unconfirmed_frames);
    var next = playbackTestSnapshot(480, 0);
    next.stream_generation = 3;
    next.progress.stream_generation = 10;
    pump.applyProgress(next);
    try std.testing.expectEqual(@as(?u64, 720), pump.stats.playback_frames);
    try std.testing.expectEqual(@as(u64, 960), pump.stats.dma_frames);
    try std.testing.expectEqual(@as(u64, 240), pump.stats.unconfirmed_frames);
}

test "audio reset excludes a late old-stream cursor from the new guest epoch" {
    var pump = AudioPump{};
    pump.applyProgress(playbackTestSnapshot(120, 0));
    const epoch_base: u64 = 120;
    pump.reset(0);
    pump.applyProgress(playbackTestSnapshot(480, 0));
    try std.testing.expectEqual(@as(u64, 360), pump.stats.retired_playback_frames);
    try std.testing.expectEqual(@as(u64, 0), pump.stats.playback_frames.? - pump.stats.retired_playback_frames - epoch_base);
    pump.feedback_retire_current = false;
    var next = playbackTestSnapshot(240, 0);
    next.stream_generation = 3;
    next.progress.stream_generation = 10;
    pump.applyProgress(next);
    try std.testing.expectEqual(@as(u64, 240), pump.stats.playback_frames.? - pump.stats.retired_playback_frames - epoch_base);
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

// Controlled acknowledgements exercise the real Runtime, queue and lifecycle.
// Native request ownership/retirement is tested by the actual transport owner.
const DelayedSink = struct {
    operation: ?transport.Operation = null,
    receipt: ?AudioCompletion = null,
    generation: u64 = 0,
    id: u32 = 0,
    writes: u32 = 0,
    closes: u32 = 0,
    finishes: u32 = 0,
    len: usize = 0,
    copy: [app_audio.max_write_payload]u8 = undefined,
    finish_error: i32 = 0,
    auto_close: bool = true,
    guarded_host: ?*FakeHost = null,
    required_present: u32 = 0,
    polled_before_host: bool = false,

    fn sink(self: *DelayedSink) AudioSink {
        return .{ .context = self, .open_fn = open, .write_fn = write, .volume_fn = volume, .close_fn = close, .poll_fn = poll, .finish_fn = finish };
    }
    fn from(raw: *anyopaque) *DelayedSink {
        return @ptrCast(@alignCast(raw));
    }
    fn post(self: *DelayedSink, op: transport.Operation) i32 {
        std.debug.assert(self.operation == null);
        self.operation = op;
        self.id += 1;
        return transport.pending;
    }
    fn reply(self: *DelayedSink, result: i32) void {
        self.receipt = .{ .operation = self.operation.?, .request_id = self.id, .generation = self.generation, .result = result };
    }
    fn open(raw: *anyopaque, _: AudioConfig) i32 {
        const self = from(raw);
        self.generation += 1;
        const rc = self.post(.open);
        self.reply(0);
        return rc;
    }
    fn write(raw: *anyopaque, bytes: []const u8) i32 {
        const self = from(raw);
        self.writes += 1;
        self.len = bytes.len;
        @memcpy(self.copy[0..bytes.len], bytes);
        return self.post(.write);
    }
    fn volume(_: *anyopaque, _: u32) i32 {
        return 0;
    }
    fn close(raw: *anyopaque) i32 {
        const self = from(raw);
        self.closes += 1;
        const rc = self.post(.close);
        if (self.auto_close) self.reply(0);
        return rc;
    }
    fn poll(raw: *anyopaque) ?AudioCompletion {
        const self = from(raw);
        if (self.guarded_host) |host| {
            if (host.presents < self.required_present or host.handled_left != 0) self.polled_before_host = true;
        }
        const value = self.receipt orelse return null;
        self.receipt = null;
        self.operation = null;
        return value;
    }
    fn finish(raw: *anyopaque) AudioFinish {
        const self = from(raw);
        self.finishes += 1;
        if (self.operation) |op| if (self.receipt == null) self.reply(if (op == .write) @intCast(self.len) else 0);
        return .{ .completion = poll(raw), .error_code = self.finish_error };
    }
};

test "audio continuation polling follows input and ready frame publication" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var guest = FakeGuest{ .audio_byte = 0x55 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(transport.Operation.write, runtime.audio.pending_operation.?);
    sink.guarded_host = &host;
    sink.required_present = host.presents + 1;
    host.handled_left = 1;
    runtime.present_pending = true;
    _ = runtime.cycle(2, guest.driver(), host.driver());
    try std.testing.expect(!sink.polled_before_host);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.submitted_bytes);
}

test "pause resume preserves late device consumption within the same guest epoch" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var controlled = sink.sink();
    controlled.progress_fn = struct {
        fn busy(_: *anyopaque) i32 {
            return abi.service_api_result_busy;
        }
    }.busy;
    var guest = FakeGuest{ .audio_byte = 0x33 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .config = .{ .continuous = true }, .queue_storage = &queue, .scratch = &scratch, .sink = controlled });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(transport.Operation.write, runtime.audio.pending_operation.?);
    runtime.request(.pause, 2, guest.driver());
    sink.reply(1920);
    sink.receipt.?.progress = playbackTestSnapshot(120, 0);
    sink.auto_close = false;
    _ = runtime.cycle(3, guest.driver(), host.driver());
    try std.testing.expectEqual(transport.Operation.close, runtime.audio.pending_operation.?);
    runtime.request(.resume_running, 4, guest.driver());
    sink.reply(0);
    sink.receipt.?.progress = playbackTestSnapshot(480, 0);
    _ = runtime.cycle(5, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.retired_playback_frames);
    try std.testing.expectEqual(@as(?u64, 480), runtime.audio_feedback_playback_frames);
    try std.testing.expectEqual(@as(u64, 1920), runtime.audio.stats.discarded_bytes);
    try std.testing.expectEqual(runtime.audio.stats.discarded_bytes, runtime.audio.stats.paused_bytes);
}

test "deferred mute discard excludes its genuinely accepted partial prefix" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{ .generation = 1 };
    var pump = try AudioPump.init(.{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() }, 1000);
    defer pump.close();
    pump.start(0);
    var pcm = [_]u8{0x33} ** 3840;
    try std.testing.expectEqual(pcm.len, pump.queue.write(&pcm));
    pump.state = .active;
    pump.sink_open = true;
    pump.sink_generation = 1;
    _ = sink.sink().write_fn(&sink, pcm[0..1920]);
    pump.beginPending(.write, 1920);
    pump.setMuted(true, 1);
    sink.reply(960);
    pump.pollPending(2, null);
    try std.testing.expectEqual(@as(u64, 960), pump.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 2880), pump.stats.discarded_bytes);
    try std.testing.expectEqual(pump.stats.discarded_bytes, pump.stats.muted_bytes);
    try std.testing.expectEqual(@as(u64, 0), pump.stats.paused_bytes);
}

test "completed progress cannot starve buffered PCM while the guest waits" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{ .generation = 1 };
    var guest = FakeGuest{ .audio_byte = 0x44 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .config = .{ .continuous = true }, .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    defer runtime.shutdown();
    runtime.start(0);
    runtime.guest_waiting = true;
    runtime.audio.state = .active;
    runtime.audio.sink_open = true;
    runtime.audio.sink_generation = 1;
    runtime.audio.progress_ready = true;
    runtime.audio.next_deadline_tick = 2;
    _ = sink.post(.progress);
    runtime.audio.beginPending(.progress, 0);
    sink.reply(0);
    sink.receipt.?.progress = playbackTestSnapshot(480, 0);
    _ = runtime.cycle(2, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u32, 0), guest.steps);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    try std.testing.expectEqual(transport.Operation.write, runtime.audio.pending_operation.?);
}

test "pending audio permits real input guest and present phases with one bounded copied prefix" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var guest = FakeGuest{ .audio_byte = 0x11 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .config = .{ .max_catchup_quanta = 64 }, .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(transport.Operation.write, runtime.audio.pending_operation.?);
    for (2..201) |tick| {
        host.handled_left = 1;
        guest.audio_byte = 0x22;
        _ = runtime.cycle(tick, guest.driver(), host.driver());
    }
    try std.testing.expect(guest.steps >= 20 and host.presents >= 20 and runtime.stats.input_events >= 199);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(usize, 3840), runtime.audio.queue.available());
    try std.testing.expect(std.mem.allEqual(u8, sink.copy[0..sink.len], 0x11));
    sink.reply(960);
    _ = runtime.cycle(202, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 960), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 1), runtime.audio.stats.partial_writes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.write_failures);
    var head: [1920]u8 = undefined;
    _ = runtime.audio.queue.peek(&head);
    try std.testing.expect(std.mem.allEqual(u8, &head, 0x11));
}

test "pending audio completion wakes an event-waiting guest before the device busy retry" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var guest = FakeGuest{ .audio_byte = 0x35, .event_waiting = true };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{
        .queue_storage = &queue,
        .scratch = &scratch,
        .sink = sink.sink(),
    });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    try std.testing.expectEqual(transport.Operation.write, runtime.audio.pending_operation.?);
    // Input/GPU activity need not arrive while the guest waits for PCM room.
    // An outstanding RPC is not a device-busy reply: observe it next tick.
    try std.testing.expectEqual(@as(u64, 1), runtime.cycle(2, guest.driver(), host.driver()).wait);
    try std.testing.expectEqual(@as(u64, 1), runtime.cycle(3, guest.driver(), host.driver()).wait);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(usize, 3840), runtime.audio.queue.available());

    sink.reply(abi.service_api_result_busy);
    try std.testing.expectEqual(@as(u64, 10), runtime.cycle(4, guest.driver(), host.driver()).wait);
    try std.testing.expectEqual(@as(u64, 1), runtime.cycle(13, guest.driver(), host.driver()).wait);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    _ = runtime.cycle(14, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u32, 2), sink.writes);
    try std.testing.expectEqual(transport.Operation.write, runtime.audio.pending_operation.?);
    sink.reply(960);
    _ = runtime.cycle(15, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 960), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 1), runtime.audio.stats.partial_writes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.write_failures);
}

test "reset retires a late old-stream prefix without feeding the new guest epoch" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var guest = FakeGuest{ .audio_byte = 0x33 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    runtime.request(.reset, 2, guest.driver());
    try std.testing.expectEqual(@as(usize, 3840), runtime.audio.queue.available());
    sink.reply(1920);
    _ = runtime.cycle(3, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 1920), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 1920), runtime.audio.stats.retired_submitted_bytes);
    try std.testing.expectEqual(@as(u64, 1920), runtime.audio.stats.retired_discarded_bytes);
    try std.testing.expectEqual(@as(u64, 0), guest.feedback_accepted_bytes);
    try std.testing.expectEqual(@as(u64, 0), guest.feedback_discarded_bytes);
    try std.testing.expectEqual(@as(u32, 1), sink.closes);
}

test "wrong stream completion never consumes PCM or becomes success" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var guest = FakeGuest{ .audio_byte = 0x44 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    sink.reply(1920);
    sink.receipt.?.generation += 1;
    _ = runtime.cycle(2, guest.driver(), host.driver());
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 1), runtime.audio.stats.write_failures);
    try std.testing.expectEqual(AudioState.degraded, runtime.audio.state);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
}

test "terminal shutdown consumes the exact outstanding acknowledgement and reports drain failure" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var guest = FakeGuest{ .audio_byte = 0x55 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    runtime.shutdown();
    try std.testing.expectEqual(@as(u32, 1), sink.finishes);
    try std.testing.expectEqual(@as(u64, 1920), runtime.audio.stats.submitted_bytes);
    try std.testing.expect(runtime.resources_closed and runtime.audio.pending_operation == null);
    var failed_sink = DelayedSink{ .finish_error = -77 };
    var failed = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = failed_sink.sink() });
    failed.shutdown();
    try std.testing.expect(!failed.resources_closed);
    try std.testing.expectEqual(@as(i32, -77), failed.audio.close_error);
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
    try std.testing.expectEqual(@as(u64, 1920), silent_runtime.audio.stats.suppressed_bytes);
    _ = silent_runtime.cycle(10, silent_guest.driver(), silent_host.driver());
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
        try std.testing.expectEqual(@as(u64, 1920), runtimes[index].audio.stats.suppressed_bytes);
        _ = runtimes[index].cycle(10, guests[index].driver(), hosts[index].driver());
    }
    for (0..8) |index| {
        try std.testing.expectEqual(@as(u32, 0), sinks[index].opens);
        try std.testing.expectEqual(@as(u32, 0), sinks[index].writes);
        try std.testing.expectEqual(@as(u64, 3840), runtimes[index].audio.stats.suppressed_bytes);
        runtimes[index].shutdown();
    }
}

test "waiting silent producer advances only at due audio time" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = FakeSink{};
    var runtime = try Runtime.init(.{ .max_wait_ticks = 1000 }, 1000, 0, .{
        .queue_storage = &queue,
        .scratch = &scratch,
        .sink = sink.sink(),
    });
    defer runtime.shutdown();
    var guest = FakeGuest{ .audio_byte = 0, .event_waiting = true };
    var host = FakeHost{ .present_result = host_present_unchanged };
    for (0..8) |_| {
        try std.testing.expectEqual(@as(u64, 10), runtime.cycle(0, guest.driver(), host.driver()).wait);
    }
    try std.testing.expectEqual(@as(u32, 1), guest.steps);
    try std.testing.expectEqual(@as(u32, 2), guest.audio_renders);
    try std.testing.expectEqual(@as(u64, 3840), runtime.audio.stats.generated_bytes);
    try std.testing.expectEqual(@as(u64, 1920), guest.feedback_suppressed_bytes);
    try std.testing.expectEqual(@as(u64, 1), runtime.cycle(9, guest.driver(), host.driver()).wait);
    try std.testing.expectEqual(@as(u32, 2), guest.audio_renders);
    try std.testing.expectEqual(@as(u64, 10), runtime.cycle(10, guest.driver(), host.driver()).wait);
    try std.testing.expectEqual(@as(u32, 1), guest.steps);
    try std.testing.expectEqual(@as(u32, 3), guest.audio_renders);
    try std.testing.expectEqual(@as(u64, 3840), guest.feedback_suppressed_bytes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.service_operations);
}

test "transient PCM gaps retain the stream and due silence preserves following signal" {
    var storage: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = FakeSink{};
    var pump = try AudioPump.init(.{ .queue_storage = &storage, .scratch = &scratch, .sink = sink.sink() }, 1000);
    defer pump.close();
    const silence = [_]u8{0} ** 1920;
    const signal = [_]u8{0x22} ** 1920;
    _ = pump.queue.write(&silence);
    _ = pump.queue.write(&signal);
    pump.pump(0, true);
    try std.testing.expectEqual(@as(u32, 0), sink.opens);
    try std.testing.expectEqual(@as(usize, 1920), pump.queue.available());
    pump.pump(9, true);
    try std.testing.expectEqual(@as(u32, 0), sink.opens);
    pump.beginCycle();
    pump.pump(10, true);
    pump.beginCycle();
    pump.pump(10, true);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    pump.beginCycle();
    pump.pump(10, true); // Empty producer during prefill; no close or spin.
    try std.testing.expectEqual(@as(u64, 20), pump.next_deadline_tick);
    try std.testing.expectEqual(@as(u32, 0), sink.closes);
    _ = pump.queue.write(&signal);
    pump.beginCycle();
    pump.pump(19, true);
    try std.testing.expectEqual(@as(u32, 1), sink.writes);
    pump.beginCycle();
    pump.pump(20, true);
    try std.testing.expectEqual(@as(u32, 1), sink.opens);
    try std.testing.expectEqual(@as(u32, 2), sink.writes);
    _ = pump.queue.write(&silence);
    _ = pump.queue.write(&signal);
    pump.beginCycle();
    pump.pump(30, true);
    try std.testing.expectEqual(@as(u32, 0), sink.closes);
    try std.testing.expectEqual(@as(usize, 1920), pump.queue.available());
    try std.testing.expectEqual(@as(u64, 0), pump.stats.discarded_bytes);
    pump.beginCycle();
    pump.pump(40, true);
    pump.beginCycle();
    pump.pump(40, true);
    try std.testing.expectEqual(@as(u32, 1), sink.opens);
    try std.testing.expectEqual(@as(u64, 4 * 1920), sink.bytes);
    try std.testing.expectEqual(@as(u64, 1920), pump.stats.suppressed_bytes);
    try std.testing.expectEqual(@as(u64, 2 * 1920), pump.stats.silence_bytes);
    try std.testing.expectEqual(@as(u64, 0), pump.stats.idle_closes);
    // Only confirmed producer idle ends the stream; valid null PCM does not.
    pump.beginCycle();
    pump.pump(41, false);
    try std.testing.expectEqual(@as(u32, 1), sink.closes);
    try std.testing.expectEqual(@as(u64, 1), pump.stats.idle_closes);
    try std.testing.expectEqual(@as(usize, 0), pump.queue.available());
    try std.testing.expectEqual(@as(u64, 0), pump.stats.discarded_bytes);
    _ = pump.queue.write(silence[0..480]); // Initial120frames =2.5ms, rounded up.
    pump.beginCycle();
    pump.pump(42, true);
    try std.testing.expectEqual(@as(u64, 45), pump.next_deadline_tick);
    try std.testing.expectEqual(@as(u64, 2400), pump.stats.suppressed_bytes);
    try std.testing.expectEqual(@as(u16, 1), pump.stats.maximum_service_operations_per_cycle);
}

test "active null PCM keeps async ownership until real acceptance and explicit idle" {
    var storage: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{};
    var pump = try AudioPump.init(.{ .queue_storage = &storage, .scratch = &scratch, .sink = sink.sink() }, 1000);
    defer pump.close();
    const signal = [_]u8{0x22} ** 1920;
    const silence = [_]u8{0} ** 1920;
    _ = pump.queue.write(&signal);
    pump.pump(0, true);
    pump.beginCycle();
    pump.pump(1, true);
    try std.testing.expectEqual(transport.Operation.write, pump.pending_operation.?);
    sink.reply(1920);
    pump.beginCycle();
    pump.pump(2, true);
    _ = pump.queue.write(&silence);
    pump.beginCycle();
    pump.pump(12, true);
    try std.testing.expectEqual(transport.Operation.write, pump.pending_operation.?);
    try std.testing.expect(std.mem.allEqual(u8, sink.copy[0..sink.len], 0));
    try std.testing.expectEqual(@as(u64, 1), sink.generation);
    try std.testing.expectEqual(@as(u32, 0), sink.closes);
    try std.testing.expectEqual(@as(usize, 1920), pump.queue.available());
    pump.pause(13); // No Close/reuse while the zero PCM request still owns bytes.
    try std.testing.expectEqual(@as(u32, 0), sink.closes);
    try std.testing.expectEqual(@as(usize, 1920), pump.queue.available());
    sink.reply(960);
    pump.beginCycle();
    pump.pump(14, true);
    pump.beginCycle();
    pump.pump(15, true);
    try std.testing.expectEqual(@as(u32, 2), sink.writes);
    try std.testing.expectEqual(@as(u64, 1), sink.generation);
    try std.testing.expectEqual(@as(u32, 1), sink.closes);
    try std.testing.expectEqual(@as(u64, 2880), pump.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 960), pump.stats.silence_bytes);
    try std.testing.expectEqual(@as(u64, 960), pump.stats.discarded_bytes);
    try std.testing.expectEqual(@as(u64, 960), pump.stats.paused_bytes);
    try std.testing.expectEqual(@as(usize, 0), pump.queue.available());
    try std.testing.expect(!pump.sink_open and pump.pending_operation == null);
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

test "asynchronous sink must provide a terminal ownership drain" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var delayed = DelayedSink{};
    var sink = delayed.sink();
    sink.finish_fn = null;
    try std.testing.expectError(Error.InvalidAudioConfiguration, Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink }));
}

test "terminal reset applies late Open or Write receipt without posting into a finished owner" {
    for (0..2) |phase| {
        var queue: [3840]u8 = undefined;
        var scratch: [1920]u8 = undefined;
        var sink = DelayedSink{};
        var guest = FakeGuest{ .audio_byte = 0x61 };
        var host = FakeHost{};
        var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
        _ = runtime.cycle(0, guest.driver(), host.driver());
        if (phase == 1) _ = runtime.cycle(1, guest.driver(), host.driver());
        runtime.request(.reset, 2, guest.driver());
        runtime.shutdown();
        try std.testing.expectEqual(@as(u32, 1), sink.finishes);
        try std.testing.expectEqual(@as(u32, 0), sink.closes);
        try std.testing.expect(sink.operation == null and runtime.audio.pending_operation == null and runtime.resources_closed);
        try std.testing.expect(runtime.audio.stats.maximum_service_operations_per_cycle <= 1);
    }
}

test "transient asynchronous Close Busy keeps a healthy paused stream recoverable" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var sink = DelayedSink{ .auto_close = false };
    var guest = FakeGuest{ .audio_byte = 0x62 };
    var host = FakeHost{};
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = sink.sink() });
    defer runtime.shutdown();
    _ = runtime.cycle(0, guest.driver(), host.driver());
    _ = runtime.cycle(1, guest.driver(), host.driver());
    runtime.request(.pause, 2, guest.driver());
    sink.reply(1920);
    _ = runtime.cycle(3, guest.driver(), host.driver());
    try std.testing.expectEqual(transport.Operation.close, runtime.audio.pending_operation.?);
    sink.reply(abi.service_api_result_busy);
    _ = runtime.cycle(4, guest.driver(), host.driver());
    try std.testing.expectEqual(AudioState.ready, runtime.audio.state);
    try std.testing.expect(runtime.audio.close_pending);
    sink.reply(0);
    _ = runtime.cycle(5, guest.driver(), host.driver());
    try std.testing.expectEqual(AudioState.ready, runtime.audio.state);
    try std.testing.expect(!runtime.audio.close_pending and !runtime.audio.sink_open);
    runtime.request(.resume_running, 6, guest.driver());
    _ = runtime.cycle(6, guest.driver(), host.driver());
    try std.testing.expectEqual(LifecycleState.running, runtime.state);
    try std.testing.expect(runtime.audio.state != .degraded);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.write_failures);
}

// Tests the actual run -> cycle -> host.wait/sleep boundary. External callbacks
// advance one controlled host clock while the real runtime owns all scheduling,
// virtual clock, PCM queue, pending receipts and terminal cleanup decisions.
const RunWaitProbe = struct {
    const Mode = enum { guest_due, idle, event, pause };
    var active: ?*RunWaitProbe = null;
    now: u64 = 0,
    mode: Mode = .guest_due,
    step_work: u64 = 0,
    present_work: u64 = 0,
    open_work: u64 = 0,
    write_work: u64 = 0,
    empty_render_work: u64 = 0,
    audio_limit: usize = std.math.maxInt(usize),
    audio_generated: usize = 0,
    audio_accepted: usize = 0,
    write_tick: u64 = 0,
    close_tick: u64 = 0,
    progress_enabled: bool = false,
    progress_work: u64 = 0,
    progress_calls: usize = 0,
    progress_tick: u64 = 0,
    open_busy: bool = false,
    write_busy: bool = false,
    async_open: bool = false,
    open_pending: bool = false,
    audio_enabled: bool = false,
    steps: u32 = 0,
    polls: u32 = 0,
    opens: u32 = 0,
    writes: u32 = 0,
    closes: u32 = 0,
    waits: [16]u64 = .{0} ** 16,
    wait_count: usize = 0,
    sleep_count: usize = 0,
    yields: usize = 0,
    wake_after: usize = 1,
    wake_pending: bool = false,
    pause_sent: bool = false,
    resume_sent: bool = false,

    fn guest(self: *RunWaitProbe) GuestDriver {
        return .{ .context = self, .step_fn = step, .reset_fn = reset, .render_audio_fn = render };
    }
    fn host(self: *RunWaitProbe, use_wait: bool) HostDriver {
        return .{ .context = self, .poll_fn = poll, .present_fn = present, .wait_fn = if (use_wait) wait else null };
    }
    fn sink(self: *RunWaitProbe) AudioSink {
        return .{ .context = self, .open_fn = open, .write_fn = write, .volume_fn = volume, .close_fn = close, .poll_fn = if (self.async_open) pollAudio else null, .finish_fn = if (self.async_open) finishAudio else null, .progress_fn = if (self.progress_enabled) progress else null };
    }
    fn run(self: *RunWaitProbe, runtime: *Runtime, use_wait: bool) i32 {
        const program = @import("program.zig");
        var table: abi.R4XStartR4Sys = .{};
        table.ticks = @intFromPtr(&ticks);
        table.sleep_ticks = @intFromPtr(&sleep);
        table.task_yield = @intFromPtr(&yield);
        const raw: abi.R4XStartContext = .{};
        const bundle: program.Bundle = .{ .raw = &raw, .sys = &table };
        const sys = r4sys.Context.init(&bundle);
        active = self;
        defer active = null;
        return runtime.run(&sys, self.guest(), self.host(use_wait));
    }
    fn ticks() callconv(.c) u64 {
        return active.?.now;
    }
    fn sleep(count: u64) callconv(.c) void {
        active.?.sleep_count += 1;
        _ = wait(active.?, count);
    }
    fn yield() callconv(.c) void {
        active.?.yields += 1;
    }
    fn step(context: *anyopaque, budget: u32, _: u64) StepResult {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.steps += 1;
        if (self.steps == 2) return StepResult.complete(0, false).withOperations(budget);
        self.now += self.step_work;
        return switch (self.mode) {
            .guest_due, .pause => StepResult.waitUntil(10 * std.time.ns_per_ms, self.present_work != 0).withOperations(budget),
            .event => StepResult.waitUntil(0, self.present_work != 0).withOperations(budget),
            .idle => StepResult.progress(false),
        };
    }
    fn reset(_: *anyopaque) i32 {
        return 0;
    }
    fn render(context: *anyopaque, out: []u8) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        if (!self.audio_enabled) return 0;
        const count = @min(out.len, self.audio_limit - self.audio_generated);
        if (count == 0) self.now += self.empty_render_work;
        @memset(out[0..count], 0x62);
        self.audio_generated += count;
        return @intCast(count);
    }
    fn poll(context: *anyopaque) HostPollResult {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.polls += 1;
        if (self.polls > 24) return .{ .command = .close }; // Bounded failure, never a hung test.
        if (self.mode == .pause) {
            if (!self.pause_sent) {
                self.pause_sent = true;
                return .{ .command = .pause };
            }
            if (self.wait_count != 0 and !self.resume_sent) {
                self.resume_sent = true;
                return .{ .command = .resume_running };
            }
        } else if (self.mode == .event and self.wake_pending) {
            self.wake_pending = false;
            return .handled;
        }
        return .idle;
    }
    fn present(context: *anyopaque) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.now += self.present_work;
        return host_present_unchanged;
    }
    fn wait(context: *anyopaque, count: u64) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        if (self.wait_count >= self.waits.len) return -9910;
        self.waits[self.wait_count] = count;
        self.wait_count += 1;
        self.now += if (count == abi.io_wait_forever) 100 else count;
        if (self.wait_count >= self.wake_after) self.wake_pending = true;
        return if (count == abi.io_wait_forever) 1 else 0;
    }
    fn open(context: *anyopaque, _: AudioConfig) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.opens += 1;
        self.now += self.open_work;
        if (self.async_open) {
            self.open_pending = true;
            return transport.pending;
        }
        return if (self.open_busy) abi.service_api_result_busy else 0;
    }
    fn write(context: *anyopaque, data: []const u8) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.writes += 1;
        self.now += self.write_work;
        self.write_tick = self.now;
        if (!self.write_busy) self.audio_accepted += data.len;
        return if (self.write_busy) abi.service_api_result_busy else @intCast(data.len);
    }
    fn volume(_: *anyopaque, _: u32) i32 {
        return 0;
    }
    fn close(context: *anyopaque) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.closes += 1;
        self.close_tick = self.now;
        return 0;
    }
    fn progress(context: *anyopaque) i32 {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        self.progress_calls += 1;
        self.progress_tick = self.now;
        self.now += self.progress_work;
        return abi.service_api_result_busy; // No fabricated playback cursor.
    }
    fn pollAudio(context: *anyopaque) ?transport.Completion {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        if (!self.open_pending) return null;
        self.open_pending = false;
        return .{ .operation = .open, .request_id = 901, .generation = 1, .result = 0, .requests = 1 };
    }
    fn finishAudio(context: *anyopaque) transport.Finish {
        const self: *RunWaitProbe = @ptrCast(@alignCast(context));
        return .{ .completion = pollAudio(self) };
    }
};

fn expectRunGuestWait(step_work: u64, present_work: u64, expected: u64) !void {
    for ([_]bool{ true, false }) |use_wait| {
        var probe = RunWaitProbe{ .step_work = step_work, .present_work = present_work };
        var runtime = try Runtime.init(.{ .slice_budget = 123 }, 1000, 0, null);
        try std.testing.expectEqual(@as(i32, 0), probe.run(&runtime, use_wait));
        try std.testing.expectEqual(@as(usize, @intFromBool(expected != 0)), probe.wait_count);
        if (expected != 0) try std.testing.expectEqual(expected, probe.waits[0]);
        try std.testing.expectEqual(@max(@as(u64, 10), step_work + present_work), probe.now);
        try std.testing.expectEqual(@as(u32, 2), probe.steps);
        try std.testing.expectEqual(@as(u64, 246), runtime.stats.executed_operations);
        try std.testing.expect(runtime.resources_closed);
    }
}

test "runtime run ages absolute guest waits after real guest and presentation work" {
    try expectRunGuestWait(3, 4, 3);
}

test "runtime run never sleeps an absolute guest deadline already spent by work" {
    try expectRunGuestWait(8, 7, 0);
}

test "runtime run preserves fresh idle pending open and device Busy intervals" {
    var idle = RunWaitProbe{ .mode = .idle, .step_work = 15 };
    var idle_runtime = try Runtime.init(.{ .idle_retry_ticks = 4 }, 1000, 0, null);
    try std.testing.expectEqual(@as(i32, 0), idle.run(&idle_runtime, true));
    try std.testing.expectEqual(@as(u64, 4), idle.waits[0]);
    try std.testing.expectEqual(@as(u64, 19), idle.now);
    for ([_]bool{ false, true }) |pending| {
        var queue: [3840]u8 = undefined;
        var scratch: [1920]u8 = undefined;
        var probe = RunWaitProbe{ .mode = .event, .audio_enabled = true, .open_work = 15, .open_busy = !pending, .async_open = pending };
        var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = probe.sink() });
        try std.testing.expectEqual(@as(i32, 0), probe.run(&runtime, true));
        try std.testing.expectEqual(@as(usize, 1), probe.wait_count);
        try std.testing.expectEqual(@as(u64, if (pending) 1 else 50), probe.waits[0]);
        try std.testing.expectEqual(@as(u32, 1), probe.opens);
        try std.testing.expectEqual(@as(u32, @intFromBool(pending)), probe.closes);
        try std.testing.expect(runtime.audio.pending_operation == null and runtime.resources_closed);
    }
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var busy = RunWaitProbe{ .mode = .event, .audio_enabled = true, .write_busy = true, .write_work = 15, .wake_after = 2 };
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = busy.sink() });
    try std.testing.expectEqual(@as(i32, 0), busy.run(&runtime, true));
    try std.testing.expectEqual(@as(usize, 2), busy.wait_count);
    try std.testing.expectEqualSlices(u64, &.{ 1, 10 }, busy.waits[0..busy.wait_count]);
    try std.testing.expectEqual(@as(u32, 1), busy.writes);
    try std.testing.expectEqual(@as(u32, 1), busy.closes);
    try std.testing.expect(runtime.resources_closed);

    var gap = RunWaitProbe{ .mode = .event, .audio_enabled = true, .audio_limit = 3840, .empty_render_work = 15, .wake_after = 3 };
    var gap_runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = gap.sink() });
    try std.testing.expectEqual(@as(i32, 0), gap.run(&gap_runtime, true));
    try std.testing.expectEqual(@as(usize, 3), gap.wait_count);
    try std.testing.expectEqualSlices(u64, &.{ 1, 10, 10 }, gap.waits[0..gap.wait_count]);
    try std.testing.expectEqual(@as(usize, 3840), gap.audio_generated);
    try std.testing.expectEqual(@as(usize, 3840), gap.audio_accepted);
    try std.testing.expectEqual(@as(u32, 2), gap.writes);
    try std.testing.expectEqual(@as(u32, 1), gap.closes);
    try std.testing.expectEqual(@as(u64, 0), gap_runtime.audio.stats.discarded_bytes);
    try std.testing.expect(gap_runtime.resources_closed);
}

test "runtime run handles an expired absolute PCM deadline before waiting" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var probe = RunWaitProbe{ .mode = .event, .step_work = 8, .present_work = 7 };
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = probe.sink() });
    // Existing active owner with one exact buffered quantum from an earlier
    // cycle. This setup makes no claim about an external hardware backend.
    runtime.audio.state = .active;
    runtime.audio.sink_open = true;
    runtime.audio.next_deadline_tick = 10;
    const signal = [_]u8{0x62} ** 1920;
    try std.testing.expectEqual(signal.len, runtime.audio.queue.write(&signal));
    runtime.audio.stats.generated_bytes = signal.len;
    try std.testing.expectEqual(@as(i32, 0), probe.run(&runtime, true));
    try std.testing.expectEqual(@as(u64, 15), probe.write_tick);
    try std.testing.expectEqual(@as(usize, 1920), probe.audio_accepted);
    try std.testing.expectEqual(@as(u64, 1920), runtime.audio.stats.submitted_bytes);
    try std.testing.expectEqual(@as(u64, 0), runtime.audio.stats.discarded_bytes);
    try std.testing.expectEqual(@as(usize, 1), probe.wait_count);
    try std.testing.expectEqual(@as(u64, 5), probe.waits[0]); // Keep the original cadence due at20.
    try std.testing.expectEqual(@as(u32, 1), probe.closes);
    try std.testing.expect(runtime.resources_closed);
}

test "runtime run handles an expired absolute close retry before waiting" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var probe = RunWaitProbe{ .mode = .event, .step_work = 8, .present_work = 7 };
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = probe.sink() });
    runtime.audio.state = .degraded;
    runtime.audio.sink_open = true;
    runtime.audio.close_pending = true;
    runtime.audio.close_retry_tick = 10;
    try std.testing.expectEqual(@as(i32, 0), probe.run(&runtime, true));
    try std.testing.expectEqual(@as(u64, 15), probe.close_tick);
    try std.testing.expectEqual(@as(u32, 1), probe.closes);
    try std.testing.expectEqual(@as(usize, 1), probe.wait_count);
    try std.testing.expectEqual(abi.io_wait_forever, probe.waits[0]);
    try std.testing.expect(runtime.resources_closed and !runtime.audio.close_pending);
}

test "runtime run ages old progress due and preserves a newly created query interval" {
    var queue: [3840]u8 = undefined;
    var scratch: [1920]u8 = undefined;
    var probe = RunWaitProbe{ .mode = .event, .step_work = 8, .present_work = 7, .progress_enabled = true, .progress_work = 3 };
    var runtime = try Runtime.init(.{}, 1000, 0, .{ .queue_storage = &queue, .scratch = &scratch, .sink = probe.sink(), .config = .{ .continuous = true } });
    runtime.audio.state = .active;
    runtime.audio.sink_open = true;
    runtime.audio.next_deadline_tick = 100;
    runtime.audio.progress_ready = true;
    runtime.audio.progress_due_tick = 10;
    try std.testing.expectEqual(@as(i32, 0), probe.run(&runtime, true));
    try std.testing.expectEqual(@as(usize, 1), probe.progress_calls);
    try std.testing.expectEqual(@as(u64, 15), probe.progress_tick);
    try std.testing.expectEqual(@as(usize, 1), probe.wait_count);
    try std.testing.expectEqual(@as(u64, 5), probe.waits[0]); // New interval starts after the actual query.
    try std.testing.expectEqual(@as(u32, 1), probe.closes);
    try std.testing.expect(runtime.audio.stats.playback_frames == null and runtime.resources_closed);
}

test "runtime run retains Forever event wake pause resume and sleep fallback" {
    for ([_]bool{ true, false }) |use_wait| {
        var event = RunWaitProbe{ .mode = .event, .step_work = 15 };
        var runtime = try Runtime.init(.{ .idle_retry_ticks = 4 }, 1000, 0, null);
        try std.testing.expectEqual(@as(i32, 0), event.run(&runtime, use_wait));
        try std.testing.expectEqual(@as(usize, 1), event.wait_count);
        try std.testing.expectEqual(@as(u64, if (use_wait) abi.io_wait_forever else 4), event.waits[0]);
        try std.testing.expectEqual(@as(u32, 2), event.steps);
    }
    var pause = RunWaitProbe{ .mode = .pause, .step_work = 3 };
    var runtime = try Runtime.init(.{}, 1000, 0, null);
    try std.testing.expectEqual(@as(i32, 0), pause.run(&runtime, true));
    try std.testing.expectEqual(@as(usize, 2), pause.wait_count);
    try std.testing.expectEqualSlices(u64, &.{ abi.io_wait_forever, 7 }, pause.waits[0..pause.wait_count]);
    try std.testing.expectEqual(@as(u64, 110), pause.now);
    try std.testing.expectEqual(@as(u64, 10 * std.time.ns_per_ms), runtime.clock.guest_ns);
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.pauses);
    try std.testing.expectEqual(@as(u64, 1), runtime.stats.resumes);
}
