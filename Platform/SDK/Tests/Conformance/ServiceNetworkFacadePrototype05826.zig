const std = @import("std");
test "checked budget driver owner cases" {
    _ = @import("r4os").driver_poll_budget;
    _ = @import("r4os").time_contract.checked;
}
const r4os = @import("r4os");

test "service loop RPC budget retains one tick boundary through progress and rejects changed sources" {
    const rpc = r4os.rpc_budget;
    const abi = r4os.abi;
    const Fake = struct {
        var now: u64 = 1_000_000_000;
        var generation: u32 = 9;
        fn clock(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
            out.* = .{ .flags = abi.monotonic_clock_flag_valid, .source = 1, .generation = generation, .frequency_hz = abi.monotonic_clock_frequency_hz, .resolution_ns = 1, .instant_ns = now, .event_requested_hz = 333, .event_effective_hz = 334 };
            return 1;
        }
    };
    var poll = try rpc.Budget.fromTicks(null, 0);
    var forever = try rpc.Budget.fromTicks(null, abi.io_wait_forever);
    try std.testing.expectEqual(@as(u64, 0), try poll.remainingTicks());
    try std.testing.expectEqual(abi.io_wait_forever, try forever.remainingTicks());
    Fake.now = 1_000_000_000;
    Fake.generation = 9;
    var operation = try rpc.Budget.fromTicks(Fake.clock, 100);
    try std.testing.expectEqual(@as(u64, 100), try operation.remainingTicks());
    Fake.now = 1_150_150_151;
    try std.testing.expectEqual(@as(u64, 50), try operation.remainingTicks());
    Fake.generation = 10;
    const before = operation;
    try std.testing.expectError(error.ClockChanged, operation.remainingTicks());
    try std.testing.expectEqualDeep(before, operation);
    Fake.generation = 9;
    Fake.now = 1_300_300_301;
    try std.testing.expectError(error.TimedOut, operation.remainingTicks());
    Fake.now = 1_000_000_000;
    try std.testing.expectError(error.BudgetOverflow, rpc.Budget.fromTicks(Fake.clock, abi.io_wait_forever - 1));
}

test "service loop Context2 retains checked clock scale deadline and source across actual waits" {
    const a = r4os.abi;
    const p = r4os.platform2;
    const Fake = struct {
        var now: u64 = 1_000_000_000;
        var generation: u32 = 9;
        var hz: u32 = 333;
        var mode: u32 = 0;
        var waits: u32 = 0;
        var ticks_calls: u32 = 0;
        var tick_now: u64 = 9999;
        fn clock(out: *a.MonotonicClockInfo) callconv(.c) i32 {
            out.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = generation, .frequency_hz = a.monotonic_clock_frequency_hz, .resolution_ns = 1, .instant_ns = now, .event_requested_hz = hz, .event_effective_hz = hz + 1 };
            return 1;
        }
        fn ticks() callconv(.c) u64 {
            ticks_calls += 1;
            return tick_now;
        }
        fn close(_: *const p.abi.R4XStartContext2) callconv(.c) u32 {
            return 0;
        }
        fn wait(endpoint: u32, timeout: u64) callconv(.c) i32 {
            std.debug.assert(endpoint == 7 and timeout == 10);
            waits += 1;
            switch (mode) {
                0 => {
                    now += 30_030_031;
                    tick_now += 10;
                },
                1 => generation += 1,
                2 => now -= 1,
                else => tick_now -= 1,
            }
            return 0;
        }
    };
    var sys: p.abi.R4XStartR4Sys2 = .{};
    sys.monotonic_clock = @intFromPtr(&Fake.clock);
    sys.ticks = @intFromPtr(&Fake.ticks);
    sys.service_endpoint_wait = @intFromPtr(&Fake.wait);
    var imports = [_]a.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) }};
    var raw: p.abi.R4XStartContext2 = .{ .instance_id = 7, .app_class = 1, .flags = a.r4xstart_flag_imports_valid | a.r4xstart_flag_close_supported, .should_close = @intFromPtr(&Fake.close), .imports = @intFromPtr(&imports), .import_count = imports.len };
    var app = switch (r4os.App2.init(&raw, .console)) {
        .value => |value| value,
        .failure => return error.App2,
    };
    for (0..4) |mode| {
        Fake.now = 1_000_000_000;
        Fake.generation = 9;
        Fake.hz = 333;
        Fake.mode = @intCast(mode);
        Fake.waits = 0;
        Fake.ticks_calls = 0;
        Fake.tick_now = 9999;
        var loop = r4os.ServiceLoop.init(app.system(), 7, .{ .stop_check_ms = 100 });
        try std.testing.expectEqual(@as(i32, 0), loop.init_error);
        try std.testing.expectEqual(@as(u64, 9999), loop.started_tick);
        try std.testing.expectEqual(@as(u64, 34), loop.stop_check_ticks);
        const result = loop.wait(10009);
        if (mode == 0) try std.testing.expect(result == .deadline) else try std.testing.expectEqual(if (mode == 1) @as(i32, -5) else @as(i32, -6), result.failure);
        try std.testing.expectEqual(@as(u32, 1), Fake.waits);
        try std.testing.expectEqual(if (mode == 0 or mode == 3) @as(u32, 3) else @as(u32, 2), Fake.ticks_calls);
    }
    Fake.now = 1_000_000_000;
    Fake.generation = 9;
    Fake.hz = 1000;
    Fake.waits = 0;
    var overflow = r4os.ServiceLoop.init(app.system(), 7, .{ .stop_check_ms = std.math.maxInt(u64) });
    try std.testing.expectEqual(@as(i32, -3), overflow.init_error);
    try std.testing.expectEqual(@as(i32, -3), overflow.wait(null).failure);
    var batch = overflow.beginBatch(1);
    try std.testing.expectEqual(@as(i32, -3), batch.next().failure);
    Fake.hz = 0;
    const unknown = r4os.ServiceLoop.init(app.system(), 7, .{});
    try std.testing.expectEqual(@as(i32, -1), unknown.init_error);
    try std.testing.expectEqual(@as(u32, 0), Fake.waits);
}

const ReplyMode = enum { ok, would_block, timeout, reset, peer_close, no_service };

// Exercise the real SDK policy against controlled ABI callbacks. Acceptance of
// a kill is deliberately separate from the fixture's physical completion ACK.
const BoundServiceStopPolicy = struct {
    const abi = r4os.abi;
    const Mode = enum { pending, replace_before_stop, replace_after_timeout, kill_completes, replace_at_kill, terminal, starting };
    const original: abi.ProgramProcessHandle = .{ .instance_id = 41, .generation = 3 };
    var mode: Mode = .pending;
    var process: abi.ProgramProcessHandle = original;
    var now: u64 = 100;
    var query_cost: u64 = 0;
    var queries: u32 = 0;
    var bound_calls: u32 = 0;
    var named_calls: u32 = 0;
    var closes: u32 = 0;
    var typed_kills: u32 = 0;
    var killed: u32 = 0;
    var legacy_kills: u32 = 0;
    var wait_budget: u64 = 0;
    var acknowledged = false;

    fn reset(next: Mode) void {
        mode = next;
        process = if (next == .starting) .{} else original;
        now = 100;
        query_cost = 0;
        queries = 0;
        bound_calls = 0;
        named_calls = 0;
        closes = 0;
        typed_kills = 0;
        killed = 0;
        legacy_kills = 0;
        wait_budget = 0;
        acknowledged = next == .terminal;
    }
    fn replace() void {
        // Reuse the numeric ID: only the generation distinguishes the service.
        process.generation = 9;
    }
    fn info() abi.ServiceInfo {
        return .{
            .instance_id = if (acknowledged or mode == .starting) 0 else process.instance_id,
            .state = if (acknowledged) abi.service_state_stopped else if (mode == .starting) abi.service_state_starting else abi.service_state_stopping,
        };
    }
    fn tick() callconv(.c) u64 {
        return now;
    }
    fn clock(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
        out.* = .{ .event_requested_hz = 1000, .event_effective_hz = 1000 };
        return 1;
    }
    fn detail(_: [*:0]const u8, out: *abi.ServiceDetail, handle: *abi.ProgramProcessHandle) callconv(.c) i32 {
        queries += 1;
        if (queries == 1) now += query_cost;
        if (queries == 2 and mode == .replace_after_timeout) replace();
        out.* = .{ .info = info() };
        handle.* = process;
        return abi.service_api_result_ok;
    }
    fn stopBound(_: [*:0]const u8, expected: *const abi.ProgramProcessHandle, out: *abi.ServiceInfo, budget: u64) callconv(.c) i32 {
        bound_calls += 1;
        wait_budget = budget;
        if (mode == .replace_before_stop) replace();
        if (!std.meta.eql(expected.*, process)) return abi.service_api_result_busy;
        closes += 1;
        out.* = info();
        now += budget;
        return abi.service_api_result_timeout;
    }
    fn stopNamed(_: [*:0]const u8, out: *abi.ServiceInfo, budget: u64) callconv(.c) i32 {
        named_calls += 1;
        wait_budget = budget;
        out.* = info();
        return abi.service_api_result_timeout;
    }
    fn kill(expected: *const abi.ProgramProcessHandle) callconv(.c) i32 {
        typed_kills += 1;
        if (mode == .replace_at_kill) replace();
        if (!std.meta.eql(expected.*, process)) return abi.program_handle_error_stale;
        killed += 1;
        if (mode == .kill_completes) acknowledged = true;
        return 0;
    }
    fn legacyKill(_: u32) callconv(.c) i32 {
        legacy_kills += 1;
        return -99;
    }
    fn run(timeout: r4os.time_contract.Timeout, policy: r4os.program.ServiceStopPolicy, omit_query: bool, omit_bound_stop: bool) struct { code: i32, status: abi.ServiceInfo } {
        var raw: abi.R4XStartContext = .{};
        var table: abi.R4XStartR4Sys = .{};
        table.ticks = @intFromPtr(&tick);
        table.monotonic_clock = @intFromPtr(&clock);
        table.service_bound_detail = if (omit_query) 0 else @intFromPtr(&detail);
        table.service_stop_bound = if (omit_bound_stop) 0 else @intFromPtr(&stopBound);
        table.service_stop = @intFromPtr(&stopNamed);
        table.program_handle_kill = @intFromPtr(&kill);
        table.program_kill = @intFromPtr(&legacyKill);
        const bundle = r4os.program.Bundle{ .raw = &raw, .sys = &table };
        const ctx = r4os.program.Context.initBundle(&bundle);
        var status: abi.ServiceInfo = .{};
        return .{ .code = ctx.serviceStopWithPolicy("SVC", &status, timeout, policy), .status = status };
    }
    fn finite() r4os.time_contract.Timeout {
        return r4os.time_contract.timeoutFinite(.{ .nanoseconds = 5_000_000 });
    }
};

test "service stop policy refuses same-ID replacement before Close" {
    const f = BoundServiceStopPolicy;
    f.reset(.replace_before_stop);
    const result = f.run(f.finite(), .kill_after_grace, false, false);
    try std.testing.expectEqual(r4os.abi.service_api_result_busy, result.code);
    try std.testing.expectEqual(@as(u32, 0), f.closes);
    try std.testing.expectEqual(@as(u32, 0), f.typed_kills);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
}

test "service stop policy refuses replacement after graceful timeout" {
    const f = BoundServiceStopPolicy;
    f.reset(.replace_after_timeout);
    try std.testing.expectEqual(r4os.abi.service_api_result_busy, f.run(f.finite(), .kill_after_grace, false, false).code);
    try std.testing.expectEqual(@as(u32, 1), f.closes);
    try std.testing.expectEqual(@as(u32, 0), f.typed_kills);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
}

test "service stop policy preserves generation across typed kill race" {
    const f = BoundServiceStopPolicy;
    f.reset(.replace_at_kill);
    try std.testing.expectEqual(r4os.abi.service_api_result_busy, f.run(f.finite(), .kill_after_grace, false, false).code);
    try std.testing.expectEqual(@as(u32, 1), f.typed_kills);
    try std.testing.expectEqual(@as(u32, 0), f.killed);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
}

test "service stop policy kill acceptance is not completion" {
    const f = BoundServiceStopPolicy;
    f.reset(.pending);
    const result = f.run(f.finite(), .kill_after_grace, false, false);
    try std.testing.expectEqual(r4os.abi.service_api_result_timeout, result.code);
    try std.testing.expectEqual(f.original.instance_id, result.status.instance_id);
    try std.testing.expectEqual(@as(u32, 1), f.killed);
    try std.testing.expect(!f.acknowledged);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
}

test "service stop policy accepts the exact completion ACK" {
    const f = BoundServiceStopPolicy;
    f.reset(.kill_completes);
    const result = f.run(f.finite(), .kill_after_grace, false, false);
    try std.testing.expectEqual(r4os.abi.service_api_result_ok, result.code);
    try std.testing.expectEqual(@as(u32, 0), result.status.instance_id);
    try std.testing.expect(f.acknowledged);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
}

test "service stop policy charges detail work to its finite budget" {
    const f = BoundServiceStopPolicy;
    f.reset(.pending);
    f.query_cost = 3;
    try std.testing.expectEqual(r4os.abi.service_api_result_timeout, f.run(f.finite(), .kill_after_grace, false, false).code);
    try std.testing.expectEqual(@as(u64, 2), f.wait_budget);
    try std.testing.expectEqual(@as(u64, 105), f.now);
}

test "service stop policy exhausted query budget adds no wait" {
    const f = BoundServiceStopPolicy;
    f.reset(.pending);
    f.query_cost = 7;
    _ = f.run(f.finite(), .kill_after_grace, false, false);
    try std.testing.expectEqual(@as(u64, 0), f.wait_budget);
    try std.testing.expectEqual(@as(u64, 107), f.now);
}

test "service stop policy Poll remains Poll during escalation" {
    const f = BoundServiceStopPolicy;
    f.reset(.pending);
    try std.testing.expectEqual(r4os.abi.service_api_result_timeout, f.run(r4os.time_contract.timeoutPoll(), .kill_after_grace, false, false).code);
    try std.testing.expectEqual(@as(u64, 0), f.wait_budget);
    try std.testing.expectEqual(@as(u64, 100), f.now);
}

test "service stop policy missing capabilities never falls back to bare ID" {
    const f = BoundServiceStopPolicy;
    f.reset(.pending);
    try std.testing.expectEqual(r4os.abi.err_no_fn, f.run(f.finite(), .kill_after_grace, true, false).code);
    try std.testing.expectEqual(@as(u32, 0), f.closes);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
    f.reset(.pending);
    try std.testing.expectEqual(r4os.abi.err_no_fn, f.run(f.finite(), .kill_after_grace, false, true).code);
    try std.testing.expectEqual(@as(u32, 0), f.closes);
    try std.testing.expectEqual(@as(u32, 0), f.legacy_kills);
}

test "service stop policy terminal and unbound starting rows stay distinct" {
    const f = BoundServiceStopPolicy;
    f.reset(.terminal);
    try std.testing.expectEqual(r4os.abi.service_api_result_ok, f.run(f.finite(), .kill_after_grace, false, false).code);
    try std.testing.expectEqual(@as(u32, 0), f.closes);
    f.reset(.starting);
    try std.testing.expectEqual(r4os.abi.service_api_result_busy, f.run(f.finite(), .kill_after_grace, false, false).code);
    try std.testing.expectEqual(@as(u32, 0), f.closes);
}

test "service stop policy graceful and Forever preserve the original stop path" {
    const f = BoundServiceStopPolicy;
    f.reset(.pending);
    _ = f.run(f.finite(), .graceful, true, true);
    try std.testing.expectEqual(@as(u32, 1), f.named_calls);
    try std.testing.expectEqual(@as(u64, 5), f.wait_budget);
    try std.testing.expectEqual(@as(u32, 0), f.queries);
    f.reset(.pending);
    _ = f.run(r4os.time_contract.timeoutForever(), .kill_after_grace, true, true);
    try std.testing.expectEqual(@as(u32, 1), f.named_calls);
    try std.testing.expectEqual(r4os.abi.io_wait_forever, f.wait_budget);
    try std.testing.expectEqual(@as(u32, 0), f.queries);
    try std.testing.expectEqual(@as(u32, 0), f.typed_kills);
}

var sys_table: r4os.abi.R4XStartR4Sys = .{};
var net_table: r4os.abi.R4XStartR4Net = .{};
var context: r4os.abi.R4XStartContext = .{};
var reply_mode: ReplyMode = .ok;
var endpoint_ready = false;
var open_handles: u32 = 0;
var endpoint_registered = false;
var window_reply: r4os.abi.WindowModeReply = .{};
var window_timeout = false;
var window_request: r4os.abi.WindowModeRequest = .{};

fn fakeOpen(name_z: [*:0]const u8, out: *r4os.abi.ServiceInfo) callconv(.c) i32 {
    const name = std.mem.span(name_z);
    if (reply_mode == .no_service or std.mem.eql(u8, name, "STOPPED")) return r4os.abi.service_api_result_not_running;
    const handle: u32 = if (std.mem.eql(u8, name, "DNSSVC")) 101 else if (std.mem.eql(u8, name, "TCPSVC")) 102 else if (std.mem.eql(u8, name, "UDPSVC")) 103 else 104;
    if (std.mem.eql(u8, name, "POWERSVC")) {
        out.* = .{ .handle = 105, .instance_id = if (power_mode == 5) 56 else 55 };
        open_handles += 1;
        return 0;
    }
    out.* = .{ .handle = handle };
    open_handles += 1;
    return r4os.abi.service_api_result_ok;
}

fn fakeClose(handle: u32) callconv(.c) i32 {
    if (handle < 101 or handle > 105 or open_handles == 0) return r4os.abi.service_api_result_bad_handle;
    open_handles -= 1;
    return r4os.abi.service_api_result_ok;
}

fn writeReply(comptime T: type, response: [*]u8, capacity: u32, value: *const T, payload: []const u8) i32 {
    const total = @sizeOf(T) + payload.len;
    if (total > capacity) return r4os.abi.service_api_result_buffer_too_small;
    @memcpy(response[0..@sizeOf(T)], std.mem.asBytes(value));
    if (payload.len != 0) @memcpy(response[@sizeOf(T)..total], payload);
    return @intCast(total);
}

fn socketLifecycle() u32 {
    return switch (reply_mode) {
        .reset => r4os.abi.net_service_socket_lifecycle_reset,
        .peer_close => r4os.abi.net_service_socket_lifecycle_peer_gone,
        .timeout => r4os.abi.net_service_socket_lifecycle_timeout,
        .would_block => r4os.abi.net_service_socket_lifecycle_would_block,
        else => r4os.abi.net_service_socket_lifecycle_active,
    };
}

fn socketStatus() u32 {
    return switch (reply_mode) {
        .timeout => r4os.abi.net_service_status_timeout,
        .would_block => r4os.abi.net_service_status_would_block,
        else => r4os.abi.net_service_status_ok,
    };
}

fn fakeCall(handle: u32, op: u16, request: [*]const u8, request_len: u32, header: *r4os.abi.ServiceMessageHeader, response: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
    header.* = .{ .op = op, .request_id = 77, .status = r4os.abi.service_api_result_ok };
    if (handle == 105) return powerCall(op, request, request_len, header, response, capacity);
    if (handle == 104) {
        if (op == r4os.abi.window_mode_op_query or op == r4os.abi.window_mode_op_request) {
            if (request_len != @sizeOf(r4os.abi.WindowModeRequest)) return r4os.abi.service_api_result_invalid;
            @memcpy(std.mem.asBytes(&window_request), request[0..request_len]);
            if (window_timeout) return r4os.abi.service_api_result_timeout;
            return writeReply(r4os.abi.WindowModeReply, response, capacity, &window_reply, "");
        }
        if (op == 7) {
            if (request_len > capacity) return r4os.abi.service_api_result_buffer_too_small;
            @memcpy(response[0..request_len], request[0..request_len]);
            return @intCast(request_len);
        }
        header.status = r4os.abi.service_api_result_invalid;
        return 0;
    }
    if (handle == 101) {
        var result: r4os.abi.NetServiceDnsResult = .{ .result = r4os.abi.dns_result_ok, .flags = r4os.abi.net_service_dns_flag_ok, .answer = .{ 10, 0, 2, 15 } };
        if (reply_mode == .timeout) result.result = r4os.abi.dns_result_timeout;
        if (reply_mode == .would_block) result.result = r4os.abi.dns_result_nxdomain;
        return writeReply(r4os.abi.NetServiceDnsResult, response, capacity, &result, "");
    }
    if (handle == 102) {
        var result: r4os.abi.NetServiceTcpResult = .{
            .action = op,
            .result = 0,
            .flags = r4os.abi.net_service_tcp_flag_ok | r4os.abi.net_service_tcp_flag_handle_valid,
            .handle = 501,
            .bytes = if (op == r4os.abi.net_service_op_tcp_write_result) @intCast(r4os.service_deadline.split(request[0..request_len]).payload.len - 4) else 0,
            .pending_rx = if (op == r4os.abi.net_service_op_tcp_poll_result) 2 else 0,
            .remote_ip = .{ 10, 0, 2, 2 },
            .remote_port = 1234,
            .lifecycle_cause = socketLifecycle(),
            .service_status = socketStatus(),
        };
        const payload = if (op == r4os.abi.net_service_op_tcp_read_result and reply_mode == .ok) "OK" else "";
        if (op == r4os.abi.net_service_op_tcp_read_result) result.bytes = @intCast(payload.len);
        if (op == r4os.abi.net_service_op_tcp_close_result or op == r4os.abi.net_service_op_tcp_close_listen_result) result.lifecycle_cause = r4os.abi.net_service_socket_lifecycle_local_close;
        return writeReply(r4os.abi.NetServiceTcpResult, response, capacity, &result, payload);
    }
    if (handle == 103) {
        var result: r4os.abi.NetServiceUdpResult = .{
            .action = op,
            .result = 0,
            .flags = r4os.abi.net_service_udp_flag_ok | r4os.abi.net_service_udp_flag_handle_valid,
            .handle = 601,
            .source_ip = .{ 10, 0, 2, 3 },
            .dest_ip = .{ 10, 0, 2, 15 },
            .source_port = 7000,
            .dest_port = 8000,
            .lifecycle_cause = socketLifecycle(),
            .service_status = socketStatus(),
        };
        const payload = if (op == r4os.abi.net_service_op_udp_recv_result and reply_mode == .ok) "UDP" else "";
        result.bytes = if (op == r4os.abi.net_service_op_udp_sendto_result) request_len - 10 else @intCast(payload.len);
        if (op == r4os.abi.net_service_op_udp_close_result) result.lifecycle_cause = r4os.abi.net_service_socket_lifecycle_local_close;
        return writeReply(r4os.abi.NetServiceUdpResult, response, capacity, &result, payload);
    }
    return r4os.abi.service_api_result_bad_handle;
}

fn fakeRegister(_: [*:0]const u8, _: u32, out: *r4os.abi.ServiceInfo) callconv(.c) i32 {
    if (endpoint_registered) return r4os.abi.service_api_result_invalid;
    endpoint_registered = true;
    out.* = .{ .handle = 201 };
    return r4os.abi.service_api_result_ok;
}

fn fakeUnregister(handle: u32) callconv(.c) i32 {
    if (!endpoint_registered or handle != 201) return r4os.abi.service_api_result_bad_handle;
    endpoint_registered = false;
    return r4os.abi.service_api_result_ok;
}

fn fakeWait(handle: u32, _: u64) callconv(.c) i32 {
    if (!endpoint_registered or handle != 201) return r4os.abi.service_api_result_bad_handle;
    return if (endpoint_ready) 1 else 0;
}

fn fakeRecv(handle: u32, header: *r4os.abi.ServiceMessageHeader, out: [*]u8, capacity: u32) callconv(.c) i32 {
    if (!endpoint_registered or handle != 201) return r4os.abi.service_api_result_bad_handle;
    if (!endpoint_ready) {
        header.* = .{};
        return 0;
    }
    const payload = [_]u32{42};
    if (capacity < @sizeOf(@TypeOf(payload))) return r4os.abi.service_api_result_buffer_too_small;
    header.* = .{ .op = 9, .request_id = 88, .payload_len = @sizeOf(@TypeOf(payload)) };
    @memcpy(out[0..@sizeOf(@TypeOf(payload))], std.mem.asBytes(&payload));
    endpoint_ready = false;
    return @sizeOf(@TypeOf(payload));
}

fn fakeReply(handle: u32, request_id: u32, status: i32, _: [*]const u8, _: u32) callconv(.c) i32 {
    return if (handle == 201 and request_id == 88 and status == 0) r4os.abi.service_api_result_ok else r4os.abi.service_api_result_invalid;
}

fn fakeTcpMarker(_: u8, _: u8, _: u8, _: u8, _: u16) callconv(.c) i32 {
    return -1;
}

fn initFacades() struct { services: r4os.Services, network: r4os.Network } {
    sys_table = .{};
    sys_table.service_open = @intFromPtr(&fakeOpen);
    sys_table.service_close = @intFromPtr(&fakeClose);
    sys_table.service_call = @intFromPtr(&fakeCall);
    sys_table.service_endpoint_register = @intFromPtr(&fakeRegister);
    sys_table.service_endpoint_unregister = @intFromPtr(&fakeUnregister);
    sys_table.service_endpoint_wait = @intFromPtr(&fakeWait);
    sys_table.service_endpoint_recv = @intFromPtr(&fakeRecv);
    sys_table.service_endpoint_reply = @intFromPtr(&fakeReply);
    net_table = .{};
    net_table.tcp_connect = @intFromPtr(&fakeTcpMarker);
    const bundle = r4os.program.Bundle{ .raw = &context, .sys = &sys_table, .net = &net_table };
    const sys = r4os.r4sys.Context.init(&bundle);
    return .{
        .services = .{ .sys = sys },
        .network = .{ .sys = sys, .net = r4os.r4net.Context.init(&bundle) },
    };
}

test "service connection and endpoint own complete lifecycles" {
    reply_mode = .ok;
    endpoint_ready = false;
    open_handles = 0;
    endpoint_registered = false;
    var facades = initFacades();
    try std.testing.expect(facades.services.available());
    var connection = switch (facades.services.open("EXAMPLE")) {
        .connection => |value| value,
        else => return error.Open,
    };
    const request: u32 = 123;
    try std.testing.expectEqual(request, switch (connection.callTyped(u32, u32, 7, &request, r4os.time_contract.timeoutForever())) {
        .value => |value| value,
        else => return error.Call,
    });
    try std.testing.expectEqual(r4os.abi.service_api_result_invalid, switch (connection.call(999, "", &.{}, r4os.time_contract.timeoutPoll())) {
        .remote_failure => |raw| raw,
        else => 0,
    });
    try std.testing.expectEqual(r4os.abi.service_api_result_ok, connection.close());
    try std.testing.expectEqual(r4os.abi.err_closed, connection.close());
    try std.testing.expect(switch (facades.services.open("STOPPED")) {
        .failure => |raw| raw == r4os.abi.service_api_result_not_running,
        else => false,
    });

    var endpoint = switch (facades.services.register("EXAMPLE", 0)) {
        .endpoint => |value| value,
        else => return error.Register,
    };
    try std.testing.expect(switch (endpoint.wait(r4os.time_contract.timeoutPoll())) {
        .timed_out => true,
        else => false,
    });
    endpoint_ready = true;
    try std.testing.expect(switch (endpoint.wait(r4os.time_contract.timeoutForever())) {
        .ready => true,
        else => false,
    });
    const received = endpoint.recvTyped([1]u32);
    const message = switch (received) {
        .message => |value| value,
        else => return error.Receive,
    };
    try std.testing.expectEqual(@as(u32, 42), message.payload[0]);
    try std.testing.expectEqual(r4os.abi.service_api_result_ok, endpoint.reply(message.header.request_id, 0, "OK"));
    try std.testing.expectEqual(r4os.abi.service_api_result_ok, endpoint.unregister());
    try std.testing.expectEqual(r4os.abi.err_closed, endpoint.unregister());
    try checkWindowModes();
}

test "resolver TCP and UDP classify lifecycle outcomes without fallback" {
    reply_mode = .ok;
    endpoint_registered = false;
    open_handles = 0;
    var facades = initFacades();
    try std.testing.expect(facades.network.available());
    var resolver = facades.network.resolver();
    const address = switch (resolver.resolveA("r4os.local", null, r4os.time_contract.timeoutForever())) {
        .address => |value| value,
        else => return error.Dns,
    };
    try std.testing.expectEqual([4]u8{ 10, 0, 2, 15 }, address.octets);
    reply_mode = .timeout;
    try std.testing.expect(switch (resolver.resolveA("r4os.local", null, r4os.time_contract.timeoutForever())) {
        .timed_out => true,
        else => false,
    });
    reply_mode = .would_block;
    try std.testing.expect(switch (resolver.resolveA("missing.local", null, r4os.time_contract.timeoutForever())) {
        .not_found => true,
        else => false,
    });

    reply_mode = .ok;
    const remote = r4os.SocketAddress{ .address = r4os.Ipv4Address.init(10, 0, 2, 2), .port = 1234 };
    var socket = switch (facades.network.connectTcp(remote, r4os.time_contract.timeoutForever())) {
        .socket => |value| value,
        else => return error.Connect,
    };
    try std.testing.expectEqual(@as(usize, 3), switch (socket.write("GET", r4os.time_contract.timeoutForever())) {
        .bytes => |bytes| bytes,
        else => 0,
    });
    var tcp_data: [8]u8 = undefined;
    try std.testing.expectEqual(@as(usize, 2), switch (socket.read(tcp_data[0..], r4os.time_contract.timeoutForever())) {
        .bytes => |bytes| bytes,
        else => 0,
    });
    try std.testing.expectEqualStrings("OK", tcp_data[0..2]);
    reply_mode = .would_block;
    try std.testing.expect(switch (socket.read(tcp_data[0..], r4os.time_contract.timeoutPoll())) {
        .would_block => true,
        else => false,
    });
    reply_mode = .timeout;
    try std.testing.expect(switch (socket.poll(r4os.time_contract.timeoutForever())) {
        .timed_out => true,
        else => false,
    });
    reply_mode = .peer_close;
    try std.testing.expect(switch (socket.read(tcp_data[0..], r4os.time_contract.timeoutForever())) {
        .peer_closed => true,
        else => false,
    });

    try std.testing.expect(socket.valid());
    reply_mode = .ok;
    try std.testing.expect(switch (socket.close(r4os.time_contract.timeoutForever())) {
        .closed => true,
        else => false,
    });
    var listener = switch (facades.network.listenTcp(8080, r4os.time_contract.timeoutForever())) {
        .listener => |value| value,
        else => return error.Listen,
    };
    var accepted = switch (listener.accept(r4os.time_contract.timeoutForever())) {
        .socket => |value| value,
        else => return error.Accept,
    };
    reply_mode = .reset;
    try std.testing.expect(switch (accepted.poll(r4os.time_contract.timeoutForever())) {
        .reset => true,
        else => false,
    });
    try std.testing.expect(accepted.valid());
    reply_mode = .ok;
    try std.testing.expect(switch (accepted.close(r4os.time_contract.timeoutForever())) {
        .closed => true,
        else => false,
    });
    try std.testing.expect(switch (listener.close(r4os.time_contract.timeoutForever())) {
        .closed => true,
        else => false,
    });

    var udp = switch (facades.network.bindUdp(8000, r4os.time_contract.timeoutForever())) {
        .socket => |value| value,
        else => return error.UdpBind,
    };
    try std.testing.expectEqual(@as(usize, 3), switch (udp.sendTo(remote, "UDP", r4os.time_contract.timeoutForever())) {
        .bytes => |bytes| bytes,
        else => 0,
    });
    var udp_data: [8]u8 = undefined;
    const datagram = switch (udp.receiveFrom(udp_data[0..], r4os.time_contract.timeoutForever())) {
        .datagram => |value| value,
        else => return error.UdpReceive,
    };
    try std.testing.expectEqual(@as(usize, 3), datagram.bytes);
    reply_mode = .would_block;
    try std.testing.expect(switch (udp.receiveFrom(udp_data[0..], r4os.time_contract.timeoutPoll())) {
        .would_block => true,
        else => false,
    });
    reply_mode = .ok;
    try std.testing.expect(switch (udp.close(r4os.time_contract.timeoutForever())) {
        .closed => true,
        else => false,
    });

    reply_mode = .no_service;
    try std.testing.expect(switch (facades.network.connectTcp(remote, r4os.time_contract.timeoutForever())) {
        .no_service => true,
        else => false,
    });
    try std.testing.expectEqual(@as(u32, 0), open_handles);
}

fn checkWindowModes() !void {
    const t = std.testing;
    reply_mode = .ok;
    window_timeout = false;
    const sys = initFacades().services.sys;
    const owner: r4os.abi.ProgramProcessHandle = .{ .instance_id = 7, .generation = 21 };
    const identity: r4os.abi.WindowModeIdentity = .{ .owner = owner, .window_id = 0, .serial = 1, .service = .{ .instance_id = 8, .generation = 22 }, .desktop = .{ .instance_id = 9, .generation = 23 } };
    var client: r4os.window_mode.Client = .{ .owner = owner, .window_id = 0 };
    window_reply = .{ .identity = identity };
    try t.expect(client.poll(&sys));
    window_timeout = true;
    try t.expect(!client.set(&sys, .fullscreen));
    const accepted = window_request;
    try t.expectEqualDeep(accepted, client.pending.?);
    window_timeout = false;
    window_reply = .{ .result = -3 };
    try t.expect(client.poll(&sys));
    try t.expectEqual(@as(i32, -3), client.state.result);
    try t.expect(client.pending != null);
    window_reply = .{ .identity = identity, .phase = 1, .request_id = accepted.request_id, .requested_mode = 1 };
    try t.expect(client.retry(&sys));
    try t.expectEqualDeep(accepted, window_request);
    try t.expect(client.pending != null and client.state.mode == 0);
    window_reply.phase = 2;
    window_reply.mode = 1;
    try t.expect(client.poll(&sys));
    try t.expect(client.pending == null and client.state.mode == 1);
    window_timeout = true;
    try t.expect(!client.set(&sys, .windowed));
    const old = client.pending.?;
    window_timeout = false;
    window_reply = .{ .identity = identity };
    window_reply.identity.service.generation += 1;
    try t.expect(client.poll(&sys));
    try t.expect(client.pending == null and client.last_error == -4);
    try t.expectEqual(@as(u32, 0), window_request.action);
    try t.expect(window_request.request_id != old.request_id);
    try t.expectEqual(@as(u32, 0), open_handles);
}

const power_generation: u64 = 0x1234_5678_abcd_4321;
var power_revision: u64 = 0x1234_5678_1234_abcd;
var power_calls: u32 = 0;
var power_mode: u32 = 0;
var power_last: r4os.abi.PowerProfileRequest = .{};
fn powerCall(op: u16, request: [*]const u8, len: u32, header: *r4os.abi.ServiceMessageHeader, response: [*]u8, capacity: u32) i32 {
    const a = r4os.abi;
    power_calls += 1;
    if (len != @sizeOf(a.PowerProfileRequest)) return a.service_api_result_invalid;
    @memcpy(std.mem.asBytes(&power_last), request[0..len]);
    if (power_mode == 3) {
        header.status = a.service_api_result_timeout;
        return 0;
    }
    if (op != a.power_profile_op_status and op != a.power_profile_op_cpu) {
        std.debug.assert(power_last.expected_service_generation == power_generation and power_last.expected_revision == power_revision);
        power_revision += 1;
    }
    if (op == a.power_profile_op_cpu) {
        const cpu: a.PowerCpuProfileInfo = .{ .cpu_index = power_last.cpu_index, .service_generation = if (power_mode == 1) power_generation + 1 else power_generation };
        return writeReply(a.PowerCpuProfileInfo, response, capacity, &cpu, "");
    }
    const info: a.PowerProfileInfo = .{ .state = a.power_profile_state_unsupported, .selected_profile = power_last.profile, .configured_cpus = 4, .online_cpus = 4, .service_instance_id = 55, .service_generation = if (power_mode == 1) power_generation + 1 else power_generation, .revision = power_revision };
    const count = writeReply(a.PowerProfileInfo, response, capacity, &info, "");
    return if (power_mode == 2) count - 1 else count;
}
test "power profile client binds full service generations and revisions without handle leaks or timeout retries" {
    const a = r4os.abi;
    const testp = std.testing;
    const timeout = r4os.time_contract.timeoutPoll();
    reply_mode = .ok;
    open_handles = 0;
    power_calls = 0;
    power_mode = 0;
    power_revision = 0x1234_5678_1234_abcd;
    const sys = initFacades().services.sys;
    var client = switch (r4os.power_profiles.Client.open(sys, timeout)) {
        .client => |v| v,
        else => return error.PowerOpen,
    };
    try testp.expectEqual(power_generation, client.info.service_generation);
    try testp.expectEqual(@as(u32, 0), open_handles);
    const before = power_calls;
    try testp.expectEqual(a.service_api_result_invalid, switch (client.select(99, false, timeout)) {
        .failure => |e| e,
        else => 0,
    });
    try testp.expectEqual(before, power_calls);
    try testp.expectEqual(a.power_profile_state_unsupported, switch (client.select(a.power_profile_performance, false, timeout)) {
        .value => |v| v.state,
        else => 999,
    });
    try testp.expectEqual(power_generation, power_last.expected_service_generation);
    try testp.expectEqual(@as(u32, 0), open_handles);
    const saved = client.info;
    power_mode = 3;
    const calls = power_calls;
    try testp.expect(switch (client.quiesce(timeout)) {
        .timed_out => true,
        else => false,
    });
    try testp.expectEqual(calls + 1, power_calls);
    try testp.expectEqualDeep(saved, client.info);
    try testp.expectEqual(@as(u32, 0), open_handles);
    power_mode = 1;
    try testp.expectEqual(a.service_api_result_invalid, switch (client.status(timeout)) {
        .failure => |e| e,
        else => 0,
    });
    try testp.expectEqualDeep(saved, client.info);
    power_mode = 2;
    try testp.expectEqual(a.service_api_result_buffer_too_small, switch (client.status(timeout)) {
        .failure => |e| e,
        else => 0,
    });
    try testp.expectEqualDeep(saved, client.info);
    power_mode = 5;
    const old_calls = power_calls;
    try testp.expectEqual(a.service_api_result_not_running, switch (client.resumeProfile(timeout)) {
        .failure => |e| e,
        else => 0,
    });
    try testp.expectEqual(old_calls, power_calls);
    try testp.expectEqual(@as(u32, 0), open_handles);
    power_mode = 0;
}
test "power perCPU client rejects stale independent record and preserves exact CPU queries" {
    const a = r4os.abi;
    const testp = std.testing;
    reply_mode = .ok;
    power_mode = 0;
    open_handles = 0;
    const timeout = r4os.time_contract.timeoutPoll();
    var client = switch (r4os.power_profiles.Client.open(initFacades().services.sys, timeout)) {
        .client => |v| v,
        else => return error.PowerOpen,
    };
    try testp.expectEqual(@as(u32, 3), switch (client.cpu(3, timeout)) {
        .value => |v| v.cpu_index,
        else => 99,
    });
    try testp.expectEqual(power_generation, power_last.expected_service_generation);
    try testp.expectEqual(@as(u64, 0), power_last.expected_revision);
    power_mode = 1;
    try testp.expectEqual(a.service_api_result_invalid, switch (client.cpu(3, timeout)) {
        .failure => |e| e,
        else => 0,
    });
    power_mode = 0;
    try testp.expectEqual(a.service_api_result_invalid, switch (client.cpu(4, timeout)) {
        .failure => |e| e,
        else => 0,
    });
    try testp.expectEqual(@as(u32, 0), open_handles);
}

fn fakePowerTransition(action: u32, budget: u64) callconv(.c) i32 {
    std.debug.assert(action == r4os.abi.power_transition_action_poweroff and budget == 0x1234_5678_abcd_4321);
    return r4os.abi.power_transition_error_retained;
}
test "explicit blocking system transition negotiates1280/1288 and forwards full wait budget" {
    const a = r4os.abi;
    const t = std.testing;
    const sys = initFacades().services.sys;
    sys_table.system_power_transition = @intFromPtr(&fakePowerTransition);
    for (1280..1288) |size| {
        sys_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, sys.systemPowerTransition(a.power_transition_action_poweroff, 0x1234_5678_abcd_4321));
    }
    sys_table.size = 1288;
    try t.expectEqual(a.power_transition_error_retained, sys.systemPowerTransition(a.power_transition_action_poweroff, 0x1234_5678_abcd_4321));
    try t.expectEqual(a.power_transition_error_invalid, sys.systemPowerTransition(3, 0));
    sys_table.system_power_transition = 0;
    try t.expectEqual(a.err_no_fn, sys.systemPowerTransition(a.power_transition_action_poweroff, 0));
}

// Controlled ABI peer, not a native-kernel qualification.
const InventoryFixture = struct {
    const abi = r4os.abi;
    var mode: enum { normal, once, always, no_end, bad_id } = .normal;
    var calls: u32 = 0;
    var starts: u32 = 0;
    var revision: u64 = 11;
    fn page(cursor: *abi.ServiceInventoryCursor, rows: [*]abi.ServiceInventoryRow, capacity: u32) callconv(.c) i32 {
        calls += 1;
        if (mode == .always or (mode == .once and calls == 2)) {
            revision += 1;
            return abi.service_api_result_restart;
        }
        if (mode == .no_end) {
            cursor.* = .{ .revision = revision, .total = 300, .flags = abi.service_inventory_dynamic };
            return 0;
        }
        const start = cursor.after_id;
        const n: usize = @intCast(@min(300 - start, capacity, abi.service_inventory_page_rows));
        for (0..n) |i| rows[i] = .{ .registration_id = start + i + 1, .start_generation = 91, .process = .{ .instance_id = 77, .generation = 8 } };
        if (mode == .bad_id and n > 1) rows[1].registration_id = rows[0].registration_id;
        cursor.* = .{ .revision = revision, .after_id = start + n, .total = 300, .flags = abi.service_inventory_dynamic | (if (start + n == 300) abi.service_inventory_end else @as(u32, 0)) };
        return @intCast(n);
    }
    fn control(request: *const abi.ServiceControlRequest) callconv(.c) i32 {
        if (request.registration_id != 300 or request.start_generation != 91 or request.process.instance_id != 77 or request.process.generation != 8) return abi.service_api_result_busy;
        starts += 1;
        return 0;
    }
};

test "service inventory grows past 255, discards restarted pages and frees caller storage" {
    const f = InventoryFixture;
    var facades = initFacades();
    sys_table.service_inventory_page = @intFromPtr(&f.page);
    sys_table.service_control_bound = @intFromPtr(&f.control);
    f.mode = .once;
    f.calls = 0;
    f.starts = 0;
    var inventory = switch (r4os.app_services.readInventory(&facades.services.sys, std.testing.allocator)) {
        .complete => |v| v,
        else => return error.Capture,
    };
    defer inventory.deinit();
    try std.testing.expectEqual(@as(usize, 300), inventory.rows.len);
    try std.testing.expect(f.calls > 38);
    try std.testing.expectEqual(f.revision, inventory.revision);
    for (inventory.rows, 1..) |row, id| try std.testing.expectEqual(id, row.registration_id);
    try std.testing.expectEqual(@as(i32, 0), r4os.app_services.controlEntry(&facades.services.sys, &inventory.rows[299], .start));
    var old = inventory.rows[299];
    old.process.generation -= 1;
    try std.testing.expectEqual(f.abi.service_api_result_busy, r4os.app_services.controlEntry(&facades.services.sys, &old, .start));
    try std.testing.expectEqual(@as(u32, 1), f.starts);
}

test "service inventory rejects endless restart, missing END, repeated identity, OOM and absent tail" {
    const f = InventoryFixture;
    var facades = initFacades();
    sys_table.service_inventory_page = @intFromPtr(&f.page);
    sys_table.service_control_bound = @intFromPtr(&f.control);
    f.mode = .always;
    f.calls = 0;
    try std.testing.expectEqual(f.abi.service_api_result_busy, r4os.app_services.readInventory(&facades.services.sys, std.testing.allocator).failure);
    try std.testing.expectEqual(@as(u32, 3), f.calls);
    f.mode = .no_end;
    try std.testing.expectEqual(f.abi.service_api_result_invalid, r4os.app_services.readInventory(&facades.services.sys, std.testing.allocator).failure);
    f.mode = .bad_id;
    try std.testing.expectEqual(f.abi.service_api_result_invalid, r4os.app_services.readInventory(&facades.services.sys, std.testing.allocator).failure);
    f.mode = .normal;
    var tiny: [1]u8 = undefined;
    var allocator = std.heap.FixedBufferAllocator.init(&tiny);
    try std.testing.expectEqual(f.abi.service_api_result_memory, r4os.app_services.readInventory(&facades.services.sys, allocator.allocator()).failure);
    sys_table.size = @offsetOf(f.abi.R4XStartR4Sys, "service_inventory_page");
    try std.testing.expect(!r4os.app_services.inventoryAvailable(&facades.services.sys));
    try std.testing.expectEqual(f.abi.err_no_fn, r4os.app_services.readInventory(&facades.services.sys, std.testing.allocator).failure);
}
