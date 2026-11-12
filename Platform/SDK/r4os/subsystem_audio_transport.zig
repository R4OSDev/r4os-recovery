//! One owned native Async Service request per stream. The interactive caller
//! only submits/polls; no worker or additional PCM backlog is introduced.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const audio = @import("app_audio.zig");
const services = @import("app_services.zig");
const r4sys = @import("r4sys.zig");
const time = @import("time_contract.zig");
const stream_reply = @import("audio_stream_reply.zig");

pub const pending: i32 = -9603;
pub const Operation = enum { open, write, volume, close, fence, progress };
pub const Completion = struct { operation: Operation, request_id: u32, generation: u64, result: i32, requests: u16 = 1, progress: ?abi.AudioServiceStreamProgressState = null };
pub const Finish = struct { completion: ?Completion = null, error_code: i32 = 0, control_requests: u32 = 0, progress: ?abi.AudioServiceStreamProgressState = null };
const Stage = enum { ordinary, discover, configure, tracked, key };

pub const Transport = struct {
    sys: r4sys.Context,
    timeout: time.Timeout,
    close_timeout: time.Timeout,
    connection: ?services.ServiceConnection = null,
    stream_id: u32 = 0,
    frame_bytes: usize = 0,
    generation: u64 = 0,
    request_id: u32 = 0,
    operation: Operation = .open,
    stage: Stage = .ordinary,
    continuous: bool = false,
    low_water_frames: u32 = 960,
    high_water_frames: u32 = 1920,
    sample_rate: u32 = 48000,
    service_epoch: u64 = 0,
    stream_generation: u64 = 0,
    flow_configured: bool = false,
    source_start_ns: u64 = 0,
    accepted_source_frames: u64 = 0,
    source_due_ns: u64 = 0,
    chain_requests: u16 = 0,
    chain_started: u64 = 0,
    chain_budget: u64 = 0,
    control_key: abi.AudioServiceStreamProgressRequest = .{},
    control_flow: abi.AudioServiceStreamFlowRequest = .{},
    progress_response: abi.AudioServiceStreamProgressState = .{},
    latest_progress: ?abi.AudioServiceStreamProgressState = null,
    request_generation: u64 = 0,
    payload: [abi.service_api_max_payload]u8 = undefined,
    header: abi.ServiceMessageHeader = .{},
    response: abi.AudioServiceStreamResult = .{},
    status: abi.AudioServiceStatus = .{},
    copied_bytes: usize = 0,
    // A timed-out Open has no usable stream ID. AUDSVC abandons that lazy
    // session when its reply fails; a same-endpoint status reply fences it.
    uncertain_open: bool = false,

    pub fn create(sys: r4sys.Context, timeout: time.Timeout, close_timeout: time.Timeout) ?*Transport {
        const p = sys.allocator().create(Transport) catch return null;
        p.* = .{ .sys = sys, .timeout = timeout, .close_timeout = close_timeout };
        return p;
    }

    pub fn open(self: *Transport, rate: u32, channels: u16, fixed: u32) i32 {
        if (self.request_id != 0 or self.stream_id != 0 or self.uncertain_open) return abi.service_api_result_busy;
        if (self.generation == std.math.maxInt(u64)) return abi.service_api_result_invalid;
        if (rate == 0 or rate > 192000 or channels == 0 or channels > 2) return abi.service_api_result_invalid;
        if (self.connection == null) {
            const facade = services.Services{ .sys = self.sys };
            self.connection = switch (facade.open("AUDSVC")) {
                .connection => |c| c,
                .failure => |code| return code,
            };
        }
        self.generation += 1;
        self.frame_bytes = @as(usize, channels) * 2;
        self.sample_rate = rate;
        self.service_epoch = 0;
        self.stream_generation = 0;
        self.flow_configured = false;
        self.source_start_ns = 0;
        self.accepted_source_frames = 0;
        self.latest_progress = null;
        self.stage = .ordinary;
        self.chain_requests = 0;
        const request = abi.AudioServiceStreamOpenRequest{ .rate = rate, .channels = channels, .format = @intFromEnum(audio.PcmFormat.s16le), .fixed_volume = fixed };
        @memcpy(self.payload[0..@sizeOf(@TypeOf(request))], std.mem.asBytes(&request));
        const rc = self.submit(.open, @sizeOf(@TypeOf(request)), self.timeout);
        if (rc == pending) self.uncertain_open = true;
        return rc;
    }

    pub fn write(self: *Transport, bytes: []const u8) i32 {
        if (self.request_id != 0) return abi.service_api_result_busy;
        if (self.stream_id == 0) return abi.err_closed;
        if (self.frame_bytes == 0 or bytes.len == 0 or bytes.len % self.frame_bytes != 0) return abi.service_api_result_invalid;
        const header_size: usize = if (self.continuous) @sizeOf(abi.AudioServiceStreamTrackedWriteRequest) else @sizeOf(abi.AudioServiceStreamWriteRequest);
        const limit = @min(bytes.len, abi.service_api_max_payload - header_size);
        self.copied_bytes = limit - limit % self.frame_bytes;
        self.chain_requests = 0;
        if (self.continuous) {
            self.stage = if (self.stream_generation == 0) .discover else if (!self.flow_configured) .configure else .tracked;
            if (self.source_start_ns == 0) self.source_start_ns = self.sys.monotonicNanoseconds() orelse return abi.service_api_result_invalid;
            const end = std.math.add(u64, self.accepted_source_frames, self.copied_bytes / self.frame_bytes) catch return abi.service_api_result_invalid;
            const duration = (@as(u128, end) * std.time.ns_per_s + self.sample_rate - 1) / self.sample_rate;
            self.source_due_ns = std.math.add(u64, self.source_start_ns, std.math.cast(u64, duration) orelse return abi.service_api_result_invalid) catch return abi.service_api_result_invalid;
            self.prepareTrackedHeader();
            @memcpy(self.payload[header_size..][0..self.copied_bytes], bytes[0..self.copied_bytes]);
            self.prepareControl();
            return self.submit(.write, header_size + self.copied_bytes, self.timeout);
        }
        self.stage = .ordinary;
        const request = abi.AudioServiceStreamWriteRequest{ .stream_id = self.stream_id, .byte_count = @intCast(self.copied_bytes) };
        const header_bytes = @sizeOf(@TypeOf(request));
        @memcpy(self.payload[0..header_bytes], std.mem.asBytes(&request));
        @memcpy(self.payload[header_bytes..][0..self.copied_bytes], bytes[0..self.copied_bytes]);
        return self.submit(.write, header_bytes + self.copied_bytes, self.timeout);
    }

    pub fn volume(self: *Transport, fixed: u32) i32 {
        if (self.request_id != 0) return abi.service_api_result_busy;
        if (self.stream_id == 0) return abi.err_closed;
        self.stage = .ordinary;
        self.chain_requests = 0;
        const request = abi.AudioServiceStreamControlRequest{ .stream_id = self.stream_id, .fixed_volume = fixed };
        @memcpy(self.payload[0..@sizeOf(@TypeOf(request))], std.mem.asBytes(&request));
        return self.submit(.volume, @sizeOf(@TypeOf(request)), self.timeout);
    }

    pub fn close(self: *Transport) i32 {
        return self.closeWithTimeout(self.close_timeout);
    }

    fn closeWithTimeout(self: *Transport, budget: time.Timeout) i32 {
        if (self.request_id != 0) return abi.service_api_result_busy;
        self.chain_requests = 0;
        self.stage = .ordinary;
        if (self.stream_id == 0) {
            if (self.uncertain_open) return self.submit(.fence, 0, budget);
            return 0;
        }
        if (self.continuous and self.stream_generation != 0) {
            self.stage = .key;
            self.prepareControl();
            return self.submit(.close, 0, budget);
        }
        const request = abi.AudioServiceStreamControlRequest{ .stream_id = self.stream_id };
        @memcpy(self.payload[0..@sizeOf(@TypeOf(request))], std.mem.asBytes(&request));
        return self.submit(.close, @sizeOf(@TypeOf(request)), budget);
    }

    fn submit(self: *Transport, operation: Operation, len: usize, timeout: time.Timeout) i32 {
        if (self.request_id != 0) return abi.service_api_result_busy;
        const connection = &(self.connection orelse return abi.err_closed);
        if (self.chain_requests == 0) {
            self.chain_budget = time.timeoutToTicks(timeout, self.sys.monotonicHz()) catch return abi.service_api_result_invalid;
            self.chain_started = self.sys.ticks();
        }
        const budget = if (self.chain_budget == abi.io_wait_forever) self.chain_budget else self.chain_budget -| (self.sys.ticks() -| self.chain_started);
        if (budget == 0) return abi.service_api_result_timeout;
        self.operation = operation;
        self.request_generation = self.generation;
        self.header = .{};
        self.response = .{};
        self.status = .{};
        self.progress_response = .{};
        const response = if (operation == .fence) std.mem.asBytes(&self.status) else if (self.stage != .ordinary) std.mem.asBytes(&self.progress_response) else std.mem.asBytes(&self.response);
        const request = switch (self.stage) {
            .discover, .key => std.mem.asBytes(&self.control_key),
            .configure => std.mem.asBytes(&self.control_flow),
            .ordinary, .tracked => self.payload[0..len],
        };
        const rc = self.sys.ioServiceCall(connection.raw, self.activeWireOp(operation), request, &self.header, response, budget, 0, &self.request_id);
        if (rc != abi.io_ok) {
            self.request_id = 0;
            return rc;
        }
        self.chain_requests +|= 1;
        return pending;
    }

    /// A caller timeout is not permission to recycle this exact storage. Even
    /// terminal publication is followed by actual ioClose/retirement success.
    pub fn poll(self: *Transport) ?Completion {
        if (self.request_id == 0) return null;
        var info: abi.ProgramIoInfo = .{};
        const rc = self.sys.ioStatus(self.request_id, &info);
        // Transient status contention is not a zero-byte write receipt. Do
        // not retire a concurrently completed request without reading it.
        if (rc != abi.io_ok and rc != abi.io_error_not_found) return null;
        if (rc == abi.io_ok and info.state != abi.io_state_completed and info.state != abi.io_state_failed) return null;
        const closed = self.sys.ioClose(self.request_id);
        if (closed != abi.io_ok and closed != abi.io_error_not_found) return null;
        const id = self.request_id;
        self.request_id = 0;
        var result = if (rc != abi.io_ok) rc else if (info.request_id != id or info.kind != abi.io_kind_service_call or self.request_generation != self.generation)
            abi.service_api_result_invalid
        else if (info.state != abi.io_state_completed and info.result >= 0) abi.service_api_result_invalid else if (info.result < 0) info.result else self.decode(info.result);
        if (result == 0 and self.operation == .write and (self.stage == .discover or self.stage == .configure)) {
            self.stage = if (self.stage == .discover) .configure else .tracked;
            self.prepareTrackedHeader();
            self.prepareControl();
            const next = self.submit(.write, @sizeOf(abi.AudioServiceStreamTrackedWriteRequest) + self.copied_bytes, self.timeout);
            if (next == pending) return null;
            result = next;
        }
        return .{ .operation = if (self.operation == .fence) .close else self.operation, .request_id = id, .generation = self.request_generation, .result = result, .requests = self.chain_requests, .progress = self.latest_progress };
    }

    fn decode(self: *Transport, bytes: i32) i32 {
        if (self.header.magic != abi.service_api_magic or self.header.version != abi.service_api_version or self.header.op != self.activeWireOp(self.operation) or self.header.request_id == 0) return abi.service_api_result_invalid;
        if (self.header.status != abi.service_api_result_ok) return if (self.header.status < 0) self.header.status else abi.service_api_result_invalid;
        if (self.operation == .fence) {
            if (bytes != @sizeOf(abi.AudioServiceStatus) or self.status.magic != abi.audio_service_status_magic or self.status.version != abi.audio_service_status_version) return abi.service_api_result_invalid;
            self.uncertain_open = false;
            return 0;
        }
        if (self.stage != .ordinary) return self.decodeProgress(bytes);
        if (bytes != @sizeOf(abi.AudioServiceStreamResult) or !stream_reply.validate(std.mem.asBytes(&self.response), wireOp(self.operation), self.stream_id, @intCast(self.copied_bytes), self.frame_bytes)) return abi.service_api_result_invalid;
        if (self.response.result < 0) return self.response.result;
        if (self.operation == .open) {
            self.stream_id = self.response.stream_id;
            self.uncertain_open = false;
            return 0;
        }
        if (self.operation == .write) {
            return @intCast(self.response.bytes);
        }
        if (self.operation == .close) self.stream_id = 0;
        return 0;
    }

    fn drain(self: *Transport) Completion {
        while (true) {
            if (self.poll()) |value| return value;
            var info: abi.ProgramIoInfo = .{};
            const waited = self.request_id;
            const rc = self.sys.ioWait(waited, abi.io_wait_forever, &info);
            if (rc == abi.io_ok and (info.state == abi.io_state_completed or info.state == abi.io_state_failed)) {
                // Wait publication is not retirement. Try the actual status /
                // close owner before backing off, retaining storage on BUSY.
                if (self.poll()) |value| return value;
                if (self.request_id != waited) continue;
            }
            if (self.request_id != 0) self.sys.sleepTicks(1);
        }
    }

    fn activeWireOp(self: *const Transport, operation: Operation) u16 {
        return switch (self.stage) {
            .discover => abi.audio_service_op_stream_progress,
            .configure => abi.audio_service_op_stream_expectation,
            .tracked => abi.audio_service_op_write_stream_tracked,
            .key => if (operation == .close) abi.audio_service_op_close_stream_progress else abi.audio_service_op_stream_progress,
            .ordinary => wireOp(operation),
        };
    }

    fn prepareTrackedHeader(self: *Transport) void {
        const request = abi.AudioServiceStreamTrackedWriteRequest{ .stream_id = self.stream_id, .byte_count = @intCast(self.copied_bytes), .service_epoch = self.service_epoch, .stream_generation = self.stream_generation, .source_due_ns = self.source_due_ns };
        @memcpy(self.payload[0..@sizeOf(@TypeOf(request))], std.mem.asBytes(&request));
    }

    fn prepareControl(self: *Transport) void {
        self.control_key = .{ .stream_id = self.stream_id, .service_epoch = self.service_epoch, .stream_generation = self.stream_generation };
        self.control_flow = .{ .stream = self.control_key, .expectation = .{ .flags = abi.audio_flow_continuous, .source_due_ns = self.source_due_ns, .low_water_frames = self.low_water_frames, .high_water_frames = self.high_water_frames } };
    }

    pub fn progress(self: *Transport) i32 {
        if (self.request_id != 0) return abi.service_api_result_busy;
        if (!self.continuous or self.stream_id == 0 or self.stream_generation == 0 or !self.flow_configured) return abi.err_closed;
        self.stage = .key;
        self.chain_requests = 0;
        self.prepareControl();
        return self.submit(.progress, 0, self.timeout);
    }

    fn decodeProgress(self: *Transport, bytes: i32) i32 {
        const r = &self.progress_response;
        const expected = abi.AudioServiceStreamProgressState{};
        if (bytes != @sizeOf(@TypeOf(expected)) or r.magic != expected.magic or r.version != expected.version or r.size != @sizeOf(@TypeOf(expected)) or r.stream_id != self.stream_id) return abi.service_api_result_invalid;
        if (r.result < 0) {
            if (self.operation == .close and r.result == abi.service_api_result_not_found) {
                self.stream_id = 0;
                self.stream_generation = 0;
                return 0;
            }
            return r.result;
        }
        if (r.service_epoch == 0 or r.stream_generation == 0) return abi.service_api_result_invalid;
        if (self.stage == .discover) {
            self.service_epoch = r.service_epoch;
            self.stream_generation = r.stream_generation;
        } else if (r.service_epoch != self.service_epoch or r.stream_generation != self.stream_generation) return abi.service_api_result_invalid;
        if (r.progress.version != 1 or r.progress.size != @sizeOf(abi.AudioStreamProgress) or r.progress.reserved0 != 0 or r.progress.reserved1 != 0) return abi.service_api_result_invalid;
        self.latest_progress = r.*;
        if (self.stage == .configure) self.flow_configured = true;
        if (self.stage == .tracked) {
            const accepted = std.math.cast(usize, r.result) orelse return abi.service_api_result_invalid;
            if (accepted == 0 or accepted > self.copied_bytes or accepted % self.frame_bytes != 0) return abi.service_api_result_invalid;
            self.accepted_source_frames = std.math.add(u64, self.accepted_source_frames, accepted / self.frame_bytes) catch return abi.service_api_result_invalid;
            return r.result;
        }
        if (r.result != 0) return abi.service_api_result_invalid;
        if (self.operation == .close) {
            self.stream_id = 0;
            self.stream_generation = 0;
            self.flow_configured = false;
        }
        return 0;
    }

    /// Terminal shutdown only. The original finite RPC budget and an unlimited
    /// wait for actual buffer release are separate. Close retries consume one
    /// absolute drain budget; a failed remote close is returned, never success.
    pub fn finish(self: *Transport) Finish {
        var result = Finish{};
        if (self.request_id != 0) result.completion = self.drain();
        const started = self.sys.ticks();
        const ticks = time.timeoutToTicks(self.close_timeout, self.sys.monotonicHz()) catch 0;
        while (self.stream_id != 0 or self.uncertain_open) {
            const elapsed = self.sys.ticks() -| started;
            const remaining = if (ticks == abi.io_wait_forever) ticks else ticks -| elapsed;
            if (remaining == 0) {
                result.error_code = abi.service_api_result_timeout;
                break;
            }
            const duration = time.durationFromTicks(remaining, self.sys.monotonicHz()) catch time.Duration{};
            const budget = if (remaining == abi.io_wait_forever) time.timeoutForever() else time.timeoutFinite(duration);
            const submitted = self.closeWithTimeout(budget);
            if (submitted == pending) result.control_requests += 1;
            const code = if (submitted == pending) self.drain().result else submitted;
            if (code == 0) break;
            if (code != abi.service_api_result_busy and code != abi.service_api_result_timeout) {
                result.error_code = code;
                break;
            }
            self.sys.sleepTicks(1);
        }
        std.debug.assert(self.request_id == 0);
        if (self.connection) |*c| {
            const closed = c.close();
            if (closed != 0 and closed != abi.err_closed and result.error_code == 0) result.error_code = if (closed < 0) closed else abi.service_api_result_invalid;
        }
        const allocator = self.sys.allocator();
        result.progress = self.latest_progress;
        allocator.destroy(self);
        return result;
    }
};

fn wireOp(operation: Operation) u16 {
    return switch (operation) {
        .open => abi.audio_service_op_open_stream,
        .write => abi.audio_service_op_write_stream,
        .volume => abi.audio_service_op_set_stream_volume,
        .close => abi.audio_service_op_close_stream,
        .fence => abi.audio_service_op_status,
        .progress => abi.audio_service_op_stream_progress,
    };
}

// Explicitly modeled native tables exercise the actual request owner. No host
// test here claims native endpoint scheduling, cancellation or hardware work.
const Probe = struct {
    var table: abi.R4XStartR4Sys = .{};
    var raw: abi.R4XStartContext = .{};
    var bundle: @import("program.zig").Bundle = undefined;
    var next_id: u32 = 400;
    var state: u32 = abi.io_state_running;
    var result: i32 = @sizeOf(abi.AudioServiceStreamResult);
    var close_busy: bool = false;
    var status_busy: bool = false;
    var closes: usize = 0;
    var header: *abi.ServiceMessageHeader = undefined;
    var response: [*]u8 = undefined;
    var operation: u16 = 0;
    var now_ticks: u64 = 0;
    var submitted_budget: u64 = 0;
    const WaitMode = enum { completed, failed, running, transient, close_busy, status_busy, continuous, expired };
    var wait_mode: WaitMode = .completed;
    var waits: usize = 0;
    var sleeps: usize = 0;
    var event_log: [128]u8 = undefined;
    var event_count: usize = 0;
    var watched: ?*Transport = null;
    var retained_at_backoff: bool = true;
    var budgets: [3]u64 = undefined;
    var budget_count: usize = 0;
    fn context() r4sys.Context {
        table = .{};
        raw = .{};
        next_id = 400;
        state = abi.io_state_running;
        result = @sizeOf(abi.AudioServiceStreamResult);
        close_busy = false;
        status_busy = false;
        closes = 0;
        now_ticks = 0;
        submitted_budget = 0;
        wait_mode = .completed;
        waits = 0;
        sleeps = 0;
        event_count = 0;
        watched = null;
        retained_at_backoff = true;
        budget_count = 0;
        table.ticks = @intFromPtr(&ticks);
        table.sleep_ticks = @intFromPtr(&sleep);
        table.monotonic_clock = @intFromPtr(&clock);
        table.io_service_call = @intFromPtr(&submit);
        table.io_status = @intFromPtr(&status);
        table.io_wait = @intFromPtr(&wait);
        table.io_close = @intFromPtr(&close);
        bundle = .{ .raw = &raw, .sys = &table };
        return r4sys.Context.init(&bundle);
    }
    fn clock(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
        out.* = .{ .event_effective_hz = 1000 };
        return 1;
    }
    fn ticks() callconv(.c) u64 {
        return now_ticks;
    }
    fn record(event: u8) void {
        std.debug.assert(event_count < event_log.len);
        event_log[event_count] = event;
        event_count += 1;
    }
    fn sleep(duration: u64) callconv(.c) void {
        record('b');
        std.debug.assert(duration == 1);
        sleeps += 1;
        now_ticks += duration;
        if (watched) |owner| {
            const replacement = [_]u8{0xee} ** 1920;
            retained_at_backoff = retained_at_backoff and owner.request_id == 401 and
                owner.write(&replacement) == abi.service_api_result_busy and
                std.mem.allEqual(u8, owner.payload[@sizeOf(abi.AudioServiceStreamWriteRequest)..][0..1920], 0x6a);
        }
        if (wait_mode == .running or wait_mode == .transient) reply(77, 960);
        if (sleeps >= 2) close_busy = false;
        status_busy = false;
    }
    fn submit(handle: u32, op: u16, _: [*]const u8, _: u32, h: *abi.ServiceMessageHeader, bytes: [*]u8, _: u32, budget: u64, _: u32, id: *u32) callconv(.c) i32 {
        std.debug.assert(handle == 11);
        record('n');
        if (budget_count < budgets.len) budgets[budget_count] = budget;
        budget_count += 1;
        next_id += 1;
        id.* = next_id;
        header = h;
        response = bytes;
        operation = op;
        submitted_budget = budget;
        state = abi.io_state_running;
        return 0;
    }
    fn status(id: u32, out: *abi.ProgramIoInfo) callconv(.c) i32 {
        record('s');
        if (status_busy) return abi.io_error_busy;
        out.* = .{ .request_id = id, .kind = abi.io_kind_service_call, .state = state, .result = result };
        return 0;
    }
    fn close(_: u32) callconv(.c) i32 {
        record('c');
        closes += 1;
        return if (close_busy) abi.io_error_busy else 0;
    }
    fn wait(id: u32, timeout: u64, out: *abi.ProgramIoInfo) callconv(.c) i32 {
        record('w');
        waits += 1;
        std.debug.assert(id == next_id and timeout == abi.io_wait_forever);
        if ((wait_mode == .running or wait_mode == .transient) and waits == 1) {
            out.* = .{ .request_id = id, .kind = abi.io_kind_service_call, .state = state, .result = result };
            return if (wait_mode == .transient) abi.io_error_busy else abi.io_ok;
        }
        if (wait_mode == .continuous or wait_mode == .expired) {
            now_ticks = if (waits == 1) 20 else if (wait_mode == .expired) 201 else 50;
            progressReply(if (waits == 3) 960 else 0);
        } else {
            reply(77, 960);
            if (wait_mode == .failed) {
                state = abi.io_state_failed;
                result = abi.service_api_result_timeout;
            }
            if (waits == 1 and wait_mode == .close_busy) close_busy = true;
            if (waits == 1 and wait_mode == .status_busy) status_busy = true;
        }
        out.* = .{ .request_id = id, .kind = abi.io_kind_service_call, .state = state, .result = result };
        return abi.io_ok;
    }
    fn reply(stream_id: u32, accepted: u32) void {
        header.* = .{ .op = operation, .request_id = 91 };
        const value = abi.AudioServiceStreamResult{ .action = operation, .stream_id = stream_id, .result = @intCast(accepted), .bytes = accepted };
        @memcpy(response[0..@sizeOf(@TypeOf(value))], std.mem.asBytes(&value));
        state = abi.io_state_completed;
    }
    fn progressReply(code: i32) void {
        header.* = .{ .op = operation, .request_id = 93 };
        const value = abi.AudioServiceStreamProgressState{ .stream_id = 77, .service_epoch = 8, .stream_generation = 10, .result = code };
        @memcpy(response[0..@sizeOf(@TypeOf(value))], std.mem.asBytes(&value));
        result = @sizeOf(@TypeOf(value));
        state = abi.io_state_completed;
    }
    fn stream() Transport {
        const sys = context();
        return .{ .sys = sys, .timeout = time.timeoutFinite(.{ .nanoseconds = 200000000 }), .close_timeout = time.timeoutFinite(.{ .nanoseconds = 500000000 }), .connection = .{ .sys = sys, .raw = 11, .owned = true }, .stream_id = 77, .frame_bytes = 4, .generation = 9 };
    }
};

test "terminal transport wait checks actual retirement before any backoff" {
    for ([_]Probe.WaitMode{ .completed, .failed }) |mode| {
        var owner = Probe.stream();
        Probe.wait_mode = mode;
        const bytes = [_]u8{0x6a} ** 1920;
        try std.testing.expectEqual(pending, owner.write(&bytes));
        Probe.event_count = 0;
        const receipt = owner.drain();
        try std.testing.expectEqualStrings("swsc", Probe.event_log[0..Probe.event_count]);
        try std.testing.expectEqual(@as(usize, 0), Probe.sleeps);
        try std.testing.expectEqual(@as(usize, 1), Probe.waits);
        try std.testing.expectEqual(@as(usize, 1), Probe.closes);
        try std.testing.expectEqual(@as(i32, if (mode == .failed) abi.service_api_result_timeout else 960), receipt.result);
        try std.testing.expectEqual(@as(u32, 401), receipt.request_id);
        try std.testing.expectEqual(@as(u64, 9), receipt.generation);
        try std.testing.expectEqual(@as(u16, 1), receipt.requests);
        try std.testing.expect(owner.request_id == 0 and owner.stream_id == 77 and owner.poll() == null);
    }
}

test "transport drain backoff retains real copied request through running transient and BUSY replies" {
    for ([_]Probe.WaitMode{ .running, .transient, .close_busy, .status_busy }) |mode| {
        var owner = Probe.stream();
        Probe.wait_mode = mode;
        const bytes = [_]u8{0x6a} ** 1920;
        try std.testing.expectEqual(pending, owner.write(&bytes));
        Probe.watched = &owner;
        Probe.event_count = 0;
        const receipt = owner.drain();
        const expected: []const u8 = switch (mode) {
            .close_busy => "swscbscwscbsc",
            .status_busy => "swsbsc",
            else => "swbsc",
        };
        try std.testing.expectEqualStrings(expected, Probe.event_log[0..Probe.event_count]);
        try std.testing.expectEqual(@as(usize, if (mode == .close_busy) 2 else 1), Probe.sleeps);
        try std.testing.expect(Probe.retained_at_backoff and owner.request_id == 0 and owner.poll() == null);
        try std.testing.expectEqual(@as(i32, 960), receipt.result);
        try std.testing.expectEqual(@as(u32, 401), receipt.request_id);
        try std.testing.expectEqual(@as(u32, 401), Probe.next_id);
        try std.testing.expectEqual(@as(u16, 1), receipt.requests);
    }
}

test "terminal transport drain chains keep exact absolute budgets without inserted ticks" {
    for ([_]Probe.WaitMode{ .continuous, .expired }) |mode| {
        var owner = Probe.stream();
        owner.continuous = true;
        owner.source_start_ns = 1_000_000_000;
        Probe.wait_mode = mode;
        const bytes = [_]u8{0x6a} ** 1920;
        try std.testing.expectEqual(pending, owner.write(&bytes));
        const due = owner.source_due_ns;
        Probe.event_count = 0;
        const receipt = owner.drain();
        const expired = mode == .expired;
        try std.testing.expectEqualStrings(if (expired) "swscnswsc" else "swscnswscnswsc", Probe.event_log[0..Probe.event_count]);
        try std.testing.expectEqual(@as(usize, 0), Probe.sleeps);
        const expected_budgets = [_]u64{ 200, 180, 150 };
        try std.testing.expectEqualSlices(u64, expected_budgets[0 .. if (expired) @as(usize, 2) else 3], Probe.budgets[0..Probe.budget_count]);
        try std.testing.expectEqual(@as(u16, if (expired) 2 else 3), receipt.requests);
        try std.testing.expectEqual(@as(i32, if (expired) abi.service_api_result_timeout else 960), receipt.result);
        try std.testing.expectEqual(@as(u64, if (expired) 0 else 240), owner.accepted_source_frames);
        try std.testing.expect(owner.request_id == 0 and owner.stream_id == 77 and owner.poll() == null);
        try std.testing.expectEqual(due, owner.source_due_ns);
    }
}

test "one actual transport request copies PCM and retains all buffers through terminal close BUSY" {
    var owner = Probe.stream();
    var bytes = [_]u8{0x19} ** 1920;
    try std.testing.expectEqual(pending, owner.write(&bytes));
    @memset(&bytes, 0x72);
    try std.testing.expect(std.mem.allEqual(u8, owner.payload[@sizeOf(abi.AudioServiceStreamWriteRequest)..][0..1920], 0x19));
    try std.testing.expectEqual(abi.service_api_result_busy, owner.write(&bytes));
    Probe.status_busy = true;
    try std.testing.expect(owner.poll() == null and Probe.closes == 0);
    Probe.status_busy = false;
    try std.testing.expect(owner.poll() == null and Probe.closes == 0);
    Probe.reply(77, 960);
    Probe.close_busy = true;
    try std.testing.expect(owner.poll() == null and owner.request_id == 401);
    try std.testing.expectEqual(abi.service_api_result_busy, owner.close());
    Probe.close_busy = false;
    const receipt = owner.poll().?;
    try std.testing.expectEqual(@as(i32, 960), receipt.result);
    try std.testing.expectEqual(@as(u64, 9), receipt.generation);
    try std.testing.expectEqual(@as(u32, 401), receipt.request_id);
    try std.testing.expect(owner.request_id == 0 and owner.poll() == null);
}

test "actual transport rejects wrong stream partial frame and generation after exact release" {
    for (0..4) |variant| {
        var owner = Probe.stream();
        const bytes = [_]u8{0x22} ** 1920;
        try std.testing.expectEqual(pending, owner.write(&bytes));
        Probe.reply(if (variant == 0) 78 else 77, if (variant == 1) 959 else 960);
        if (variant == 2) owner.request_generation -= 1;
        if (variant == 3) Probe.state = abi.io_state_failed;
        try std.testing.expectEqual(abi.service_api_result_invalid, owner.poll().?.result);
        try std.testing.expect(owner.request_id == 0 and Probe.closes == 1);
    }
}

test "timed out actual Open is fenced on its original endpoint before reusing the stream" {
    var owner = Probe.stream();
    owner.stream_id = 0;
    try std.testing.expectEqual(pending, owner.open(48000, 2, audio.default_volume));
    Probe.state = abi.io_state_failed;
    Probe.result = abi.service_api_result_timeout;
    try std.testing.expectEqual(abi.service_api_result_timeout, owner.poll().?.result);
    try std.testing.expect(owner.uncertain_open);
    try std.testing.expectEqual(abi.service_api_result_busy, owner.open(48000, 2, audio.default_volume));
    try std.testing.expectEqual(pending, owner.close());
    try std.testing.expectEqual(abi.audio_service_op_status, Probe.operation);
    Probe.header.* = .{ .op = Probe.operation, .request_id = 92 };
    const status = abi.AudioServiceStatus{};
    @memcpy(Probe.response[0..@sizeOf(@TypeOf(status))], std.mem.asBytes(&status));
    Probe.state = abi.io_state_completed;
    Probe.result = @sizeOf(@TypeOf(status));
    const receipt = owner.poll().?;
    try std.testing.expectEqual(Operation.close, receipt.operation);
    try std.testing.expectEqual(@as(i32, 0), receipt.result);
    try std.testing.expect(!owner.uncertain_open and owner.stream_id == 0 and owner.request_id == 0);
}

test "actual transport Open binds positive result and identity before adopting a stream" {
    for (0..5) |variant| {
        var owner = Probe.stream();
        owner.stream_id = 0;
        try std.testing.expectEqual(pending, owner.open(48000, 2, audio.default_volume));
        Probe.reply(77, 0);
        var response: abi.AudioServiceStreamResult = undefined;
        @memcpy(std.mem.asBytes(&response), Probe.response[0..@sizeOf(@TypeOf(response))]);
        response.result = switch (variant) {
            0 => 0,
            1 => 78,
            2 => 77,
            3 => abi.service_api_result_bad_handle,
            else => 77,
        };
        if (variant == 2) response.bytes = 4;
        @memcpy(Probe.response[0..@sizeOf(@TypeOf(response))], std.mem.asBytes(&response));
        const receipt = owner.poll().?;
        try std.testing.expectEqual(if (variant == 4) @as(i32, 0) else abi.service_api_result_invalid, receipt.result);
        try std.testing.expectEqual(@as(u32, if (variant == 4) 77 else 0), owner.stream_id);
        try std.testing.expectEqual(variant != 4, owner.uncertain_open);
        try std.testing.expectEqual(@as(u32, 1), Probe.closes);
    }
}

test "continuous transport keeps copied PCM and one absolute budget through binding and flow" {
    var owner = Probe.stream();
    owner.continuous = true;
    owner.source_start_ns = 1_000_000_000;
    var input = [_]u8{0x42} ** 1920;
    try std.testing.expectEqual(pending, owner.write(&input));
    const due = owner.source_due_ns;
    @memset(&input, 0);
    try std.testing.expectEqual(abi.audio_service_op_stream_progress, Probe.operation);
    Probe.progressReply(0);
    Probe.close_busy = true;
    try std.testing.expect(owner.poll() == null and owner.stream_generation == 0);
    Probe.close_busy = false;
    Probe.now_ticks = 20;
    try std.testing.expect(owner.poll() == null);
    try std.testing.expectEqual(abi.audio_service_op_stream_expectation, Probe.operation);
    try std.testing.expectEqual(@as(u64, 180), Probe.submitted_budget);
    try std.testing.expectEqual(due, owner.control_flow.expectation.source_due_ns);
    Probe.progressReply(0);
    Probe.now_ticks = 50;
    try std.testing.expect(owner.poll() == null);
    try std.testing.expectEqual(abi.audio_service_op_write_stream_tracked, Probe.operation);
    try std.testing.expectEqual(@as(u64, 150), Probe.submitted_budget);
    const offset = @sizeOf(abi.AudioServiceStreamTrackedWriteRequest);
    for (owner.payload[offset..][0..1920]) |byte| try std.testing.expectEqual(@as(u8, 0x42), byte);
    Probe.progressReply(960);
    const completed = owner.poll().?;
    try std.testing.expectEqual(@as(i32, 960), completed.result);
    try std.testing.expectEqual(@as(u16, 3), completed.requests);
    try std.testing.expectEqual(@as(u64, 240), owner.accepted_source_frames);
    try std.testing.expect(owner.request_id == 0);
    try std.testing.expectEqual(pending, owner.write(input[0..960]));
    try std.testing.expectEqual(due, owner.source_due_ns); // Same original remainder deadline.
    Probe.progressReply(960);
    try std.testing.expectEqual(@as(i32, 960), owner.poll().?.result);
}

test "continuous transport expires its original budget before starting PCM" {
    var owner = Probe.stream();
    owner.continuous = true;
    owner.source_start_ns = 1_000_000_000;
    const input = [_]u8{0x42} ** 1920;
    try std.testing.expectEqual(pending, owner.write(&input));
    Probe.progressReply(0);
    Probe.now_ticks = 100;
    try std.testing.expect(owner.poll() == null);
    Probe.progressReply(0);
    Probe.now_ticks = 201;
    const completed = owner.poll().?;
    try std.testing.expectEqual(abi.service_api_result_timeout, completed.result);
    try std.testing.expectEqual(@as(u16, 2), completed.requests);
    try std.testing.expectEqual(abi.audio_service_op_stream_expectation, Probe.operation);
    try std.testing.expect(owner.request_id == 0 and owner.accepted_source_frames == 0);
}
