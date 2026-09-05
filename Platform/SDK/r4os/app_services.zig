const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4sys = @import("r4sys.zig");
const time_contract = @import("time_contract.zig");

pub const Timeout = time_contract.Timeout;

pub const Services = struct {
    sys: r4sys.Context,

    pub fn available(self: *const Services) bool {
        return self.sys.hasFn("service_open") and self.sys.hasFn("service_close") and
            self.sys.hasFn("service_call") and self.sys.hasFn("service_endpoint_register") and
            self.sys.hasFn("service_endpoint_unregister") and self.sys.hasFn("service_endpoint_wait") and
            self.sys.hasFn("service_endpoint_recv") and self.sys.hasFn("service_endpoint_reply");
    }

    pub fn open(self: *const Services, name: [*:0]const u8) ServiceOpen {
        var info: abi.ServiceInfo = .{};
        const raw = self.sys.serviceOpen(name, &info);
        if (raw != abi.service_api_result_ok or info.handle == 0) {
            return .{ .failure = if (raw == abi.service_api_result_ok) abi.service_api_result_no_endpoint else raw };
        }
        return .{ .connection = .{ .sys = self.sys, .raw = info.handle, .owned = true, .info = info } };
    }

    pub fn register(self: *const Services, name: [*:0]const u8, flags: u32) EndpointOpen {
        var info: abi.ServiceInfo = .{};
        const raw = self.sys.serviceEndpointRegister(name, flags, &info);
        if (raw != abi.service_api_result_ok or info.handle == 0) {
            return .{ .failure = if (raw == abi.service_api_result_ok) abi.service_api_result_no_endpoint else raw };
        }
        return .{ .endpoint = .{ .sys = self.sys, .raw = info.handle, .owned = true, .info = info } };
    }
};

pub const ServiceOpen = union(enum) {
    connection: ServiceConnection,
    failure: i32,
};

pub const EndpointOpen = union(enum) {
    endpoint: ServiceEndpoint,
    failure: i32,
};

pub const ServiceResponse = struct {
    header: abi.ServiceMessageHeader,
    bytes: usize,
};

pub const ServiceCall = union(enum) {
    response: ServiceResponse,
    timed_out,
    remote_failure: i32,
    failure: i32,
};

pub fn TypedServiceCall(comptime T: type) type {
    return union(enum) {
        value: T,
        timed_out,
        remote_failure: i32,
        failure: i32,
    };
}

pub const ServiceConnection = struct {
    sys: r4sys.Context,
    raw: u32 = 0,
    owned: bool = false,
    info: abi.ServiceInfo = .{},

    pub fn valid(self: *const ServiceConnection) bool {
        return self.raw != 0;
    }

    pub fn call(self: *ServiceConnection, op: u16, request: []const u8, response: []u8, timeout: Timeout) ServiceCall {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var header: abi.ServiceMessageHeader = .{};
        const raw = self.sys.serviceCallTimeout(self.raw, op, request, &header, response, timeout);
        if (raw == abi.service_api_result_timeout) return .timed_out;
        if (raw == abi.service_api_result_bad_handle or raw == abi.service_api_result_not_running) {
            self.raw = 0;
            return .{ .failure = raw };
        }
        if (raw < 0) return .{ .failure = raw };
        if (header.status == abi.service_api_result_timeout) return .timed_out;
        if (header.status != abi.service_api_result_ok) return .{ .remote_failure = header.status };
        return .{ .response = .{ .header = header, .bytes = @intCast(raw) } };
    }

    pub fn callTyped(self: *ServiceConnection, comptime Request: type, comptime Response: type, op: u16, request: *const Request, timeout: Timeout) TypedServiceCall(Response) {
        var response: Response = undefined;
        const response_bytes = std.mem.asBytes(&response);
        return switch (self.call(op, std.mem.asBytes(request), response_bytes, timeout)) {
            .response => |result| if (result.bytes == @sizeOf(Response)) .{ .value = response } else .{ .failure = abi.service_api_result_buffer_too_small },
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .remote_failure = raw },
            .failure => |raw| .{ .failure = raw },
        };
    }

    pub fn close(self: *ServiceConnection) i32 {
        if (!self.valid()) return abi.err_closed;
        if (!self.owned) return abi.err_not_owned;
        const raw = self.sys.serviceClose(self.raw);
        if (raw == abi.service_api_result_ok or raw == abi.service_api_result_bad_handle) {
            self.raw = 0;
            self.info = .{};
            return if (raw == abi.service_api_result_ok) raw else abi.err_closed;
        }
        return raw;
    }
};

pub const EndpointWait = union(enum) {
    ready: u32,
    timed_out,
    failure: i32,
};

pub const EndpointMessage = struct {
    header: abi.ServiceMessageHeader,
    bytes: usize,
};

pub const EndpointReceive = union(enum) {
    message: EndpointMessage,
    would_block,
    failure: i32,
};

pub const service_loop_default_stop_check_ms: u64 = 200;

pub const ServiceLoopOptions = struct {
    stop_check_ms: u64 = service_loop_default_stop_check_ms,
    drain_limit: u32 = @intCast(abi.service_api_endpoint_queue_depth),
};

pub const ServiceLoopMetrics = struct {
    wait_calls: u64 = 0,
    request_wakes: u64 = 0,
    deadline_wakes: u64 = 0,
    idle_wakes: u64 = 0,
    stop_wakes: u64 = 0,
    wait_failures: u64 = 0,
    announced_requests: u64 = 0,
    batches: u64 = 0,
    drain_polls: u64 = 0,
    empty_drain_polls: u64 = 0,
    drained_requests: u64 = 0,
    limited_batches: u64 = 0,
    fairness_yields: u64 = 0,
    max_batch: u32 = 0,
};

pub const ServiceLoopWake = union(enum) {
    requests: u32,
    deadline,
    idle,
    stop,
    failure: i32,
};

pub const ServiceBatchStep = union(enum) {
    request,
    complete,
    yielded,
    failure: i32,
};

const WaitBudget = struct {
    ticks: u64,
    deadline_due: bool,
};

/// Gemeinsame Hauptschleifenmechanik fuer R4X-Dienste. Fachliche Arbeit und
/// deren naechste absolute Tickdeadline bleiben beim jeweiligen Dienst.
/// Der endliche Stopcheck bleibt eine Sicherheitsgrenze; regulaere SERVMAN-
/// Stopps invalidieren den Endpoint und wecken dessen WaitQueue unmittelbar.
pub const ServiceLoop = struct {
    sys: r4sys.Context,
    endpoint_handle: u32,
    started_tick: u64,
    stop_check_ticks: u64,
    drain_limit: u32,
    metrics: ServiceLoopMetrics = .{},

    pub fn init(sys: r4sys.Context, endpoint_handle: u32, options: ServiceLoopOptions) ServiceLoop {
        const configured_stop_ticks = sys.ticksFromMilliseconds(options.stop_check_ms);
        return .{
            .sys = sys,
            .endpoint_handle = endpoint_handle,
            .started_tick = sys.ticks(),
            .stop_check_ticks = if (configured_stop_ticks == 0) 1 else configured_stop_ticks,
            .drain_limit = normalizeDrainLimit(options.drain_limit),
        };
    }

    /// Wartet bis zu einem Endpointrequest, einer absoluten fachlichen
    /// Deadline oder dem zentral begrenzten Stopcheck. Ein null-Deadlinewert
    /// bezeichnet einen reinen Endpointdienst ohne periodische Facharbeit.
    pub fn wait(self: *ServiceLoop, deadline_tick: ?u64) ServiceLoopWake {
        if (self.sys.programShouldClose()) {
            self.metrics.stop_wakes +%= 1;
            return .stop;
        }

        const budget = serviceLoopWaitBudget(self.sys.ticks(), deadline_tick, self.stop_check_ticks);
        if (budget.deadline_due) {
            self.metrics.deadline_wakes +%= 1;
            return .deadline;
        }

        self.metrics.wait_calls +%= 1;
        const pending = self.sys.serviceEndpointWait(self.endpoint_handle, budget.ticks);
        if (pending < 0) {
            // SERVMAN invalidiert den Endpoint beim Uebergang auf stopping und
            // weckt damit dessen WaitQueue. Diese erwartete Cancellation ist
            // nach der Close-Anforderung ein Stop-Wake, kein Dienstfehler.
            if (self.sys.programShouldClose()) {
                self.metrics.stop_wakes +%= 1;
                return .stop;
            }
            self.metrics.wait_failures +%= 1;
            return .{ .failure = pending };
        }
        if (self.sys.programShouldClose()) {
            self.metrics.stop_wakes +%= 1;
            return .stop;
        }
        if (pending > 0) {
            const queued: u32 = @intCast(pending);
            self.metrics.request_wakes +%= 1;
            self.metrics.announced_requests +%= queued;
            return .{ .requests = queued };
        }
        if (deadline_tick) |deadline| {
            if (self.sys.ticks() >= deadline) {
                self.metrics.deadline_wakes +%= 1;
                return .deadline;
            }
        }
        self.metrics.idle_wakes +%= 1;
        return .idle;
    }

    pub fn beginBatch(self: *ServiceLoop, announced_requests: u32) ServiceRequestBatch {
        self.metrics.batches +%= 1;
        return .{
            .loop = self,
            .announced = announced_requests,
        };
    }

    /// Fuehrt einen dienstspezifischen Einzelrequest-Handler unter der
    /// gemeinsamen Batch-, Poll- und Fairnesspolicy aus. `args` ist das
    /// Argumenttupel fuer `handler` und der Handler liefert einen i32-Code.
    pub fn drain(self: *ServiceLoop, announced_requests: u32, comptime handler: anytype, args: anytype) i32 {
        var batch = self.beginBatch(announced_requests);
        while (true) switch (batch.next()) {
            .request => {
                const rc: i32 = @call(.auto, handler, args);
                if (rc < 0) return rc;
            },
            .complete, .yielded => return 0,
            .failure => |raw| return raw,
        };
    }

    /// Gibt beim regulären Dienststopp genau eine maschinenlesbare Zahlenzeile
    /// aus. Reihenfolge nach Name: Laufzeit, Stopbudget, Drainlimit, Waits,
    /// Request-/Deadline-/Idle-/Stop-Wakes, Fehler, angekuendigte Requests,
    /// Batches, Drain-/Leerpolls, abgearbeitete Requests, limitierte Batches,
    /// Fairness-Yields und groesster Batch.
    pub fn report(self: *const ServiceLoop, service_name: []const u8) void {
        var line_buffer: [384]u8 = undefined;
        const line = self.formatReport(service_name, line_buffer[0..]) orelse return;
        self.sys.println(line);
    }

    pub fn formatReport(self: *const ServiceLoop, service_name: []const u8, out: []u8) ?[]const u8 {
        return std.fmt.bufPrint(
            out,
            "SVCLOOP|1|{s}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}|{d}",
            .{
                service_name,
                self.sys.ticks() -| self.started_tick,
                self.stop_check_ticks,
                self.drain_limit,
                self.metrics.wait_calls,
                self.metrics.request_wakes,
                self.metrics.deadline_wakes,
                self.metrics.idle_wakes,
                self.metrics.stop_wakes,
                self.metrics.wait_failures,
                self.metrics.announced_requests,
                self.metrics.batches,
                self.metrics.drain_polls,
                self.metrics.empty_drain_polls,
                self.metrics.drained_requests,
                self.metrics.limited_batches,
                self.metrics.fairness_yields,
                self.metrics.max_batch,
            },
        ) catch null;
    }
};

/// Bounded Drain ueber die gemeinsame Endpointqueue. Bei weiter gefuellter
/// Queue wird nach dem Budget genau einmal kooperativ abgegeben, aber kein
/// kuenstlicher Tick geschlafen.
pub const ServiceRequestBatch = struct {
    loop: *ServiceLoop,
    announced: u32,
    processed: u32 = 0,
    done: bool = false,

    pub fn next(self: *ServiceRequestBatch) ServiceBatchStep {
        if (self.done) return .complete;
        if (self.processed >= self.loop.drain_limit) return self.finishLimit();

        if (self.announced == 0) {
            self.loop.metrics.drain_polls +%= 1;
            const pending = self.loop.sys.serviceEndpointPoll(self.loop.endpoint_handle);
            if (pending < 0) {
                self.done = true;
                return .{ .failure = pending };
            }
            if (pending == 0) {
                self.loop.metrics.empty_drain_polls +%= 1;
                self.done = true;
                return .complete;
            }
            self.announced = @intCast(pending);
        }

        self.announced -= 1;
        self.processed += 1;
        self.loop.metrics.drained_requests +%= 1;
        if (self.processed > self.loop.metrics.max_batch) self.loop.metrics.max_batch = self.processed;
        return .request;
    }

    fn finishLimit(self: *ServiceRequestBatch) ServiceBatchStep {
        var pending = self.announced;
        if (pending == 0) {
            self.loop.metrics.drain_polls +%= 1;
            const raw = self.loop.sys.serviceEndpointPoll(self.loop.endpoint_handle);
            if (raw < 0) {
                self.done = true;
                return .{ .failure = raw };
            }
            pending = @intCast(raw);
            if (pending == 0) self.loop.metrics.empty_drain_polls +%= 1;
        }
        self.done = true;
        if (pending == 0) return .complete;
        self.loop.metrics.limited_batches +%= 1;
        self.loop.metrics.fairness_yields +%= 1;
        self.loop.sys.taskYield();
        return .yielded;
    }
};

fn serviceLoopWaitBudget(now: u64, deadline_tick: ?u64, stop_check_ticks: u64) WaitBudget {
    const stop_ticks = if (stop_check_ticks == 0) 1 else stop_check_ticks;
    const deadline = deadline_tick orelse return .{ .ticks = stop_ticks, .deadline_due = false };
    if (now >= deadline) return .{ .ticks = 0, .deadline_due = true };
    return .{ .ticks = @min(stop_ticks, deadline - now), .deadline_due = false };
}

fn normalizeDrainLimit(configured: u32) u32 {
    const queue_limit: u32 = @intCast(abi.service_api_endpoint_queue_depth);
    if (configured == 0) return 1;
    return @min(configured, queue_limit);
}

pub fn TypedEndpointReceive(comptime T: type) type {
    return union(enum) {
        message: struct { header: abi.ServiceMessageHeader, payload: T },
        would_block,
        failure: i32,
    };
}

pub const ServiceEndpoint = struct {
    sys: r4sys.Context,
    raw: u32 = 0,
    owned: bool = false,
    info: abi.ServiceInfo = .{},

    pub fn valid(self: *const ServiceEndpoint) bool {
        return self.raw != 0;
    }

    pub fn wait(self: *ServiceEndpoint, timeout: Timeout) EndpointWait {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const raw = self.sys.serviceEndpointWaitTimeout(self.raw, timeout);
        if (raw == 0) return .timed_out;
        if (raw == abi.service_api_result_bad_handle or raw == abi.service_api_result_not_running) {
            self.raw = 0;
            return .{ .failure = raw };
        }
        if (raw < 0) return .{ .failure = raw };
        return .{ .ready = @intCast(raw) };
    }

    pub fn recv(self: *ServiceEndpoint, out: []u8) EndpointReceive {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var header: abi.ServiceMessageHeader = .{};
        const raw = self.sys.serviceEndpointRecv(self.raw, &header, out);
        if (raw == 0 and header.magic != abi.service_api_magic) return .would_block;
        if (raw == abi.service_api_result_bad_handle or raw == abi.service_api_result_not_running) {
            self.raw = 0;
            return .{ .failure = raw };
        }
        if (raw < 0) return .{ .failure = raw };
        return .{ .message = .{ .header = header, .bytes = @intCast(raw) } };
    }

    pub fn recvTyped(self: *ServiceEndpoint, comptime T: type) TypedEndpointReceive(T) {
        var payload: T = undefined;
        return switch (self.recv(std.mem.asBytes(&payload))) {
            .message => |message| if (message.bytes == @sizeOf(T)) .{ .message = .{ .header = message.header, .payload = payload } } else .{ .failure = abi.service_api_result_buffer_too_small },
            .would_block => .would_block,
            .failure => |raw| .{ .failure = raw },
        };
    }

    pub fn reply(self: *ServiceEndpoint, request_id: u32, status: i32, payload: []const u8) i32 {
        if (!self.valid()) return abi.err_closed;
        const raw = self.sys.serviceEndpointReply(self.raw, request_id, status, payload);
        if (raw == abi.service_api_result_bad_handle or raw == abi.service_api_result_not_running) self.raw = 0;
        return raw;
    }

    pub fn replyTyped(self: *ServiceEndpoint, comptime T: type, request_id: u32, status: i32, payload: *const T) i32 {
        return self.reply(request_id, status, std.mem.asBytes(payload));
    }

    pub fn unregister(self: *ServiceEndpoint) i32 {
        if (!self.valid()) return abi.err_closed;
        if (!self.owned) return abi.err_not_owned;
        const raw = self.sys.serviceEndpointUnregister(self.raw);
        if (raw == abi.service_api_result_ok or raw == abi.service_api_result_bad_handle) {
            self.raw = 0;
            self.info = .{};
            return if (raw == abi.service_api_result_ok) raw else abi.err_closed;
        }
        return raw;
    }
};

test "service loop wait budget uses the earliest absolute boundary" {
    try std.testing.expectEqual(WaitBudget{ .ticks = 200, .deadline_due = false }, serviceLoopWaitBudget(1000, null, 200));
    try std.testing.expectEqual(WaitBudget{ .ticks = 50, .deadline_due = false }, serviceLoopWaitBudget(1000, 1050, 200));
    try std.testing.expectEqual(WaitBudget{ .ticks = 0, .deadline_due = true }, serviceLoopWaitBudget(1050, 1050, 200));
    try std.testing.expectEqual(WaitBudget{ .ticks = 1, .deadline_due = false }, serviceLoopWaitBudget(1000, null, 0));
}

test "service loop drain budget is nonzero and endpoint bounded" {
    try std.testing.expectEqual(@as(u32, 1), normalizeDrainLimit(0));
    try std.testing.expectEqual(@as(u32, 3), normalizeDrainLimit(3));
    try std.testing.expectEqual(@as(u32, @intCast(abi.service_api_endpoint_queue_depth)), normalizeDrainLimit(std.math.maxInt(u32)));
}
