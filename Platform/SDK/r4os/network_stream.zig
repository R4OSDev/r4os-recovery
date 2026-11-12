//! Synchronous family sockets over the existing TCPSVC copied-record API.
//! Session and Socket have unique owners. Copies do not retain resources.
const std = @import("std");
const a = @import("r4os_contract").abi;
const family = @import("network_family.zig");
const rpc = @import("rpc_budget.zig");
const core = @import("stream_transfer.zig");
const adapters = @import("stream_adapters.zig");
const sys_api = @import("r4sys.zig");
pub const cancelled = adapters.cancelled;

/// A leading family selector delegates the remaining UTF8 arguments exactly.
pub fn arguments(raw: []const u8, selected: *u32) ?[]const u8 {
    const args = @import("arg_cursor.zig");
    var failure: args.Failure = .{};
    var cursor = args.ArgCursor.init(raw, .{ .switches = args.slash | args.dash }, &failure) catch return null;
    // Validate the complete grammar before any network or file effect.
    while (cursor.next() catch return null) |_| {}
    cursor = args.ArgCursor.init(raw, .{ .switches = args.slash | args.dash }, &failure) catch return null;
    const first = (cursor.next() catch return null) orelse {
        selected.* = 0;
        return raw;
    };
    const value = first.bytes(raw) catch return null;
    selected.* = 0;
    if (!first.quoted() and (std.mem.eql(u8, value, "-4") or std.mem.eql(u8, value, "-6"))) {
        selected.* = if (value[1] == '4') 4 else 6;
        return cursor.remainingArguments() catch null;
    }
    return raw;
}

pub const Session = struct {
    sys: sys_api.Context,
    clock: adapters.PlatformClock,
    client: family.Client,
    info: a.NetworkProviderInfo,
    owned: u32 = 0,
    cleanup_failed: bool = false,

    pub fn open(app: *const @import("app2.zig").App, budget: *rpc.Budget, out: *Session) i32 {
        const clock = app.clock() catch return a.err_no_fn;
        var client: family.Client = undefined;
        const opened = app.networkFamily(.tcp, &client);
        if (opened != 0) return opened;
        client.timeout_ticks = budget.remainingTicks() catch |err| {
            _ = client.close();
            return rpc.code(err);
        };
        var info: a.NetworkProviderInfo = .{};
        const rc = client.info(&info);
        if (rc != 0 or info.capabilities & a.network_cap_tcp == 0 or info.max_send == 0 or info.max_recv == 0) {
            _ = client.close();
            return if (rc != 0) rc else a.network_error_invalid;
        }
        out.* = .{ .sys = app.system(), .clock = clock, .client = client, .info = info };
        return 0;
    }

    pub fn close(self: *Session) i32 {
        const rc = self.client.close();
        return if (rc != 0) rc else if (self.cleanup_failed or self.owned != 0) a.network_error_bad_socket else 0;
    }

    pub fn resolve(self: *Session, host: []const u8, port: u16, selected_family: u32, budget: *rpc.Budget, out: *a.NetworkEndpoint) i32 {
        const text = if (host.len >= 2 and host[0] == '[' and host[host.len - 1] == ']') host[1 .. host.len - 1] else host;
        if (family.parseAddress(text)) |address| {
            if (selected_family != 0 and address.family != selected_family) return a.network_error_unsupported_family;
            out.* = .{ .address = address, .port = port };
            return 0;
        }
        // Invalid numeric/scoped addresses must never become DNS names.
        if (std.mem.indexOfAny(u8, text, ":%[]") != null) return a.network_error_unsupported_scope;
        var dns: family.Client = undefined;
        const opened = family.Client.connectProvider(self.sys, .dns, &dns);
        if (opened != 0) return opened;
        var answers: [32]a.NetworkResolveAnswer = undefined;
        var count: u32 = 0;
        const rc = family.resolveAll(&dns, text, if (selected_family == 0) 4 else selected_family, .{}, budget, &answers, &count);
        const closed = dns.close();
        if (rc != 0) return rc;
        if (closed != 0) return closed;
        if (count == 0) return a.network_error_not_found;
        out.* = .{ .address = answers[0].address, .port = port };
        return 0;
    }

    pub fn create(self: *Session, endpoint: a.NetworkEndpoint, listening: bool, budget: *rpc.Budget, out: *Socket) i32 {
        const capability = if (endpoint.address.family == 6) a.network_cap_ipv6 else a.network_cap_ipv4;
        if (self.info.capabilities & capability == 0 or listening and self.info.capabilities & a.network_cap_listen == 0) return a.network_error_unsupported_family;
        self.client.timeout_ticks = budget.remainingTicks() catch |err| return rpc.code(err);
        var reply: a.NetworkSocketResult = .{};
        const rc = self.client.socket(if (listening) a.network_op_listen else a.network_op_connect, .{
            .provider = self.info.provider,
            .endpoint = endpoint,
            .deadline = family.fromBudget(budget.deadline) catch |err| return family.common.code(err),
        }, "", &.{}, &reply);
        if (rc != 0) return rc;
        self.owned += 1;
        var socket: Socket = .{ .session = self, .id = reply.socket, .generation = reply.generation, .endpoint = reply.endpoint };
        if (reply.state != a.network_state_ready) {
            socket.close();
            return a.network_error_backend;
        }
        out.* = socket;
        return 0;
    }
};

pub const Socket = struct {
    session: *Session,
    id: u64,
    generation: u64,
    endpoint: a.NetworkEndpoint,

    pub fn accept(self: *Socket, budget: *rpc.Budget, out: *Socket) i32 {
        while (true) {
            if (self.session.sys.programShouldClose()) return cancelled;
            self.session.client.timeout_ticks = budget.remainingTicks() catch |err| return rpc.code(err);
            var reply: a.NetworkSocketResult = .{};
            const rc = self.session.client.socket(a.network_op_accept, .{
                .provider = self.session.info.provider,
                .socket = self.id,
                .generation = self.generation,
                .deadline = family.fromBudget(budget.deadline) catch |err| return family.common.code(err),
            }, "", &.{}, &reply);
            if (rc != 0 and rc != a.network_error_would_block) return rc;
            if (rc == 0 and reply.state == a.network_state_ready) {
                self.session.owned += 1;
                out.* = .{ .session = self.session, .id = reply.socket, .generation = reply.generation, .endpoint = reply.endpoint };
                return 0;
            }
            if (rc == 0 and reply.state != a.network_state_would_block) return a.network_error_backend;
            self.session.sys.sleepTicks(1);
        }
    }

    /// A separate bounded cleanup operation never extends a data deadline.
    /// An unconfirmed close retains the exact identity and fails Session.close.
    pub fn close(self: *Socket) void {
        if (self.id == 0) return;
        var budget = rpc.Budget.fromTimeout(self.session.clock.read, .{ .kind = 1, .nanoseconds = 250_000_000 }) catch {
            self.session.cleanup_failed = true;
            return;
        };
        while (true) {
            self.session.client.timeout_ticks = budget.remainingTicks() catch {
                self.session.cleanup_failed = true;
                return;
            };
            var reply: a.NetworkSocketResult = .{};
            const rc = self.session.client.socket(a.network_op_close, .{
                .provider = self.session.info.provider,
                .socket = self.id,
                .generation = self.generation,
                .deadline = family.fromBudget(budget.deadline) catch {
                    self.session.cleanup_failed = true;
                    return;
                },
            }, "", &.{}, &reply);
            if (rc == a.network_error_would_block or rc == 0 and reply.state == a.network_state_would_block) {
                self.session.sys.sleepTicks(1);
                continue;
            }
            if (rc != 0 or reply.state != a.network_state_local_closed) {
                self.session.cleanup_failed = true;
                return;
            }
            self.id = 0;
            self.session.owned -= 1;
            return;
        }
    }

    fn invoke(self: *Socket, reading: bool, input: []const u8, output: []u8, absolute: *const @import("time_budget.zig").DeadlineBudget) core.Ack {
        var budget: rpc.Budget = .{ .clock = self.session.clock.read, .deadline = absolute.* };
        self.session.client.timeout_ticks = budget.remainingTicks() catch |err| return .{
            .kind = @intFromEnum(if (err == error.TimedOut) core.IoKind.timed_out else core.IoKind.failed),
            .error_code = rpc.code(err),
        };
        const count: u32 = @intCast(@min(if (reading) output.len else input.len, if (reading) @min(self.session.info.max_recv, 4008) else @min(self.session.info.max_send, @min(3968, a.net_service_tcp_write_max))));
        var reply: a.NetworkSocketResult = .{};
        const rc = self.session.client.socket(if (reading) a.network_op_read else a.network_op_write, .{
            .provider = self.session.info.provider,
            .socket = self.id,
            .generation = self.generation,
            .bytes = count,
            .deadline = family.fromBudget(budget.deadline) catch |err| return .{ .kind = @intFromEnum(core.IoKind.failed), .error_code = family.common.code(err) },
        }, if (reading) "" else input[0..count], if (reading) output[0..count] else &.{}, &reply);
        if (rc != 0) return .{ .kind = @intFromEnum(if (rc == a.network_error_would_block) core.IoKind.would_block else core.IoKind.uncertain), .error_code = rc };
        return .{ .bytes = reply.bytes, .kind = @intFromEnum(switch (reply.state) {
            a.network_state_ready => core.IoKind.progress,
            a.network_state_would_block => .would_block,
            a.network_state_eof => .eof,
            a.network_state_timeout => .timed_out,
            a.network_state_local_closed => .closed,
            else => .failed,
        }), .error_code = if (reply.state == a.network_state_reset) a.network_error_reset else 0 };
    }

    pub fn readCallback(raw: ?*anyopaque, _: u64, bytes: [*]u8, count: u32, absolute: *const @import("time_budget.zig").DeadlineBudget) callconv(.c) core.Ack {
        const self: *Socket = @ptrCast(@alignCast(raw.?));
        return self.invoke(true, "", bytes[0..count], absolute);
    }

    pub fn writeCallback(raw: ?*anyopaque, _: u64, bytes: [*]const u8, count: u32, absolute: *const @import("time_budget.zig").DeadlineBudget) callconv(.c) core.Ack {
        const self: *Socket = @ptrCast(@alignCast(raw.?));
        return self.invoke(false, bytes[0..count], &.{}, absolute);
    }

    pub fn writeAll(self: *Socket, bytes: []const u8, budget: *rpc.Budget) core.Error!core.Progress {
        const driver: adapters.Driver = .{ .sys = self.session.sys, .clock = &self.session.clock, .budget = budget };
        return driver.write(bytes, 3968, writeCallback, self);
    }
};

/// Retains received suffixes across control lines and following body reads.
pub const Reader = struct {
    socket: *Socket,
    storage: [4008]u8 = undefined,
    start: usize = 0,
    end: usize = 0,

    fn callback(raw: ?*anyopaque, _: u64, bytes: [*]u8, count: u32, absolute: *const @import("time_budget.zig").DeadlineBudget) callconv(.c) core.Ack {
        const self: *Reader = @ptrCast(@alignCast(raw.?));
        if (self.start != self.end) {
            const n: u32 = @intCast(@min(count, self.end - self.start));
            @memcpy(bytes[0..n], self.storage[self.start..][0..n]);
            self.start += n;
            return .{ .bytes = n };
        }
        return Socket.readCallback(self.socket, 0, bytes, count, absolute);
    }

    pub fn read(self: *Reader, out: []u8, exact: bool, budget: *rpc.Budget) core.Error!core.Progress {
        const session = self.socket.session;
        const driver: adapters.Driver = .{ .sys = session.sys, .clock = &session.clock, .budget = budget };
        return driver.read(out, 4008, callback, self, exact);
    }

    pub fn line(self: *Reader, out: []u8, budget: *rpc.Budget) core.Error!?[]const u8 {
        var used: usize = 0;
        while (used < out.len) {
            if (self.start == self.end) {
                const result = try self.read(&self.storage, false, budget);
                if (result.bytes == 0) return if (used != 0 and result.outcome == @intFromEnum(core.Outcome.eof)) out[0..used] else null;
                if (result.flags & core.terminal != 0 and result.outcome != @intFromEnum(core.Outcome.complete) and result.outcome != @intFromEnum(core.Outcome.eof)) return null;
                self.start = 0;
                self.end = @intCast(result.bytes);
            }
            const byte = self.storage[self.start];
            self.start += 1;
            out[used] = byte;
            used += 1;
            if (used >= 2 and std.mem.eql(u8, out[used - 2 .. used], "\r\n")) return out[0..used];
        }
        return null;
    }
};

pub fn complete(progress: core.Progress) bool {
    return progress.outcome == @intFromEnum(core.Outcome.complete);
}

const StreamProbe = struct {
    var calls: u32 = 0;
    var sleeps: u32 = 0;
    var now: u64 = 1_000_000_000;
    var end_ns: u64 = 0;
    var mode: enum { short_write, lost_write, cancel_write, read_data, read_eof, malformed } = .short_write;
    var stopping: u32 = 0;
    var read_at: usize = 0;
    var sent: [32]u8 = undefined;
    var sent_len: usize = 0;
    const wire = "CONT 12\r\nabcdef";
    fn clock(out: *a.MonotonicClockInfo) callconv(.c) i32 {
        now += 100_000;
        out.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = 9, .instant_ns = now, .resolution_ns = 1, .event_requested_hz = 1000 };
        return 1;
    }
    fn shouldClose() callconv(.c) u32 {
        return stopping;
    }
    fn closeContext(_: *const @import("platform2.zig").abi.R4XStartContext2) callconv(.c) u32 {
        return stopping;
    }
    fn sleep(_: u64) callconv(.c) void {
        sleeps += 1;
    }
    fn close(_: u32) callconv(.c) i32 {
        return 0;
    }
    fn call(_: u32, op: u16, input: [*]const u8, length: u32, header: *a.ServiceMessageHeader, output: [*]u8, _: u32, _: u64) callconv(.c) i32 {
        calls += 1;
        const req = family.common.record(a.NetworkSocketRequest, input[0..@sizeOf(a.NetworkSocketRequest)]) catch return a.network_error_invalid;
        if (req.provider != 13 or req.socket != 17 or req.generation != 19 or req.deadline.absolute_ns != end_ns or length != @sizeOf(a.NetworkSocketRequest) + (if (op == a.network_op_write) req.bytes else @as(u32, 0))) return a.network_error_invalid;
        if (mode == .lost_write) return a.service_api_result_timeout;
        var reply: a.NetworkSocketResult = .{ .provider = 13, .socket = 17, .generation = if (mode == .malformed) 99 else 19, .endpoint = family.common.v4Endpoint(.{ 10, 0, 0, 1 }, 80), .state = a.network_state_ready };
        if (op == a.network_op_write) {
            if (mode == .short_write and calls == 2) reply.state = a.network_state_would_block else {
                reply.bytes = @min(req.bytes, 3);
                @memcpy(sent[sent_len..][0..reply.bytes], input[@sizeOf(a.NetworkSocketRequest)..][0..reply.bytes]);
                sent_len += reply.bytes;
            }
            if (mode == .cancel_write) stopping = 1;
        } else {
            const available = if (mode == .read_eof) "xy" else wire;
            reply.bytes = @intCast(@min(req.bytes, @min(5, available.len - read_at)));
            @memcpy(output[@sizeOf(a.NetworkSocketResult)..][0..reply.bytes], available[read_at..][0..reply.bytes]);
            read_at += reply.bytes;
            if (read_at == available.len) reply.state = a.network_state_eof;
        }
        reply.original_bytes = reply.bytes;
        @memcpy(output[0..@sizeOf(a.NetworkSocketResult)], std.mem.asBytes(&reply));
        const size: u32 = @sizeOf(a.NetworkSocketResult) + (if (op == a.network_op_read) reply.bytes else @as(u32, 0));
        header.* = .{ .op = op, .payload_len = @intCast(size) };
        return @intCast(size);
    }
    fn reset() void {
        calls = 0;
        sleeps = 0;
        stopping = 0;
        read_at = 0;
        sent_len = 0;
        now = 1_000_000_000;
    }
};

test "network stream keeps short prefixes one deadline uncertain writes and cancellation" {
    const platform = @import("platform2.zig");
    var table: platform.abi.R4XStartR4Sys2 = .{ .program_should_close = @intFromPtr(&StreamProbe.shouldClose), .sleep_ticks = @intFromPtr(&StreamProbe.sleep) };
    const imports = [_]platform.abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&table) }};
    const raw: platform.abi.R4XStartContext2 = .{ .import_count = 1, .imports = @intFromPtr(&imports), .flags = a.r4xstart_flag_close_supported, .should_close = @intFromPtr(&StreamProbe.closeContext) };
    const context = try platform.Context.init(&raw);
    var session: Session = .{ .sys = .{ .base = .{ .generation2 = &context } }, .clock = .{ .read = StreamProbe.clock }, .client = .{ .call = StreamProbe.call, .close_call = StreamProbe.close, .handle = 7, .service = .tcp }, .info = .{ .provider = 13, .max_send = 3968, .max_recv = 4008 } };
    var socket: Socket = .{ .session = &session, .id = 17, .generation = 19, .endpoint = family.common.v4Endpoint(.{ 10, 0, 0, 1 }, 80) };
    for ([_]@TypeOf(StreamProbe.mode){ .short_write, .lost_write, .cancel_write }) |mode| {
        StreamProbe.reset();
        StreamProbe.mode = mode;
        var budget = try rpc.Budget.fromTimeout(StreamProbe.clock, .{ .kind = 1, .nanoseconds = 1_000_000_000 });
        StreamProbe.end_ns = budget.deadline.deadline_ns;
        const result = try socket.writeAll("abcdefgh", &budget);
        try std.testing.expectEqual(StreamProbe.end_ns, budget.deadline.deadline_ns);
        try std.testing.expect(budget.deadline.last_ns > 1_000_000_000);
        switch (mode) {
            .short_write => {
                try std.testing.expect(complete(result));
                try std.testing.expectEqualStrings("abcdefgh", StreamProbe.sent[0..StreamProbe.sent_len]);
                try std.testing.expectEqual(@as(u32, 1), StreamProbe.sleeps);
            },
            .lost_write => {
                try std.testing.expectEqual(@intFromEnum(core.Outcome.uncertain), result.outcome);
                try std.testing.expectEqual(@as(u32, 1), StreamProbe.calls);
                try std.testing.expectEqual(@as(u64, 0), result.bytes);
            },
            .cancel_write => {
                try std.testing.expectEqual(@intFromEnum(core.Outcome.cancelled), result.outcome);
                try std.testing.expectEqual(@as(u64, 3), result.bytes);
                try std.testing.expectEqual(@as(u32, 1), StreamProbe.calls);
            },
            else => unreachable,
        }
    }
}

test "network stream buffered split control retains body EOF prefix and malformed output" {
    const platform = @import("platform2.zig");
    var table: platform.abi.R4XStartR4Sys2 = .{ .program_should_close = @intFromPtr(&StreamProbe.shouldClose), .sleep_ticks = @intFromPtr(&StreamProbe.sleep) };
    const imports = [_]platform.abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&table) }};
    const raw: platform.abi.R4XStartContext2 = .{ .import_count = 1, .imports = @intFromPtr(&imports), .flags = a.r4xstart_flag_close_supported, .should_close = @intFromPtr(&StreamProbe.closeContext) };
    const context = try platform.Context.init(&raw);
    var session: Session = .{ .sys = .{ .base = .{ .generation2 = &context } }, .clock = .{ .read = StreamProbe.clock }, .client = .{ .call = StreamProbe.call, .close_call = StreamProbe.close, .handle = 7, .service = .tcp }, .info = .{ .provider = 13, .max_send = 3968, .max_recv = 4008 } };
    var socket: Socket = .{ .session = &session, .id = 17, .generation = 19, .endpoint = family.common.v4Endpoint(.{ 10, 0, 0, 1 }, 80) };
    for ([_]@TypeOf(StreamProbe.mode){ .read_data, .read_eof, .malformed }) |mode| {
        StreamProbe.reset();
        StreamProbe.mode = mode;
        var budget = try rpc.Budget.fromTimeout(StreamProbe.clock, .{ .kind = 1, .nanoseconds = 1_000_000_000 });
        StreamProbe.end_ns = budget.deadline.deadline_ns;
        var reader: Reader = .{ .socket = &socket };
        var bytes = [_]u8{'?'} ** 32;
        if (mode == .read_data) {
            const line = (try reader.line(&bytes, &budget)).?;
            try std.testing.expectEqualStrings("CONT 12\r\n", line);
            const result = try reader.read(bytes[0..6], true, &budget);
            try std.testing.expect(complete(result));
            try std.testing.expectEqualStrings("abcdef", bytes[0..6]);
            try std.testing.expectEqual(@as(u32, 3), StreamProbe.calls);
        } else {
            const result = try reader.read(bytes[0..6], true, &budget);
            if (mode == .read_eof) {
                try std.testing.expectEqual(@intFromEnum(core.Outcome.eof), result.outcome);
                try std.testing.expectEqual(@as(u64, 2), result.bytes);
                try std.testing.expectEqualStrings("xy????", bytes[0..6]);
            } else {
                try std.testing.expectEqual(@intFromEnum(core.Outcome.uncertain), result.outcome);
                try std.testing.expectEqualStrings("??????", bytes[0..6]);
                try std.testing.expectEqual(@as(u32, 1), StreamProbe.calls);
            }
        }
    }
}

test "network stream leading family keeps complete quoted argument grammar" {
    var selected: u32 = 99;
    try std.testing.expectEqualStrings("\"fd00::1\" 1234 \"Grüße Welt\"", arguments("-6 \"fd00::1\" 1234 \"Grüße Welt\"", &selected).?);
    try std.testing.expectEqual(@as(u32, 6), selected);
    try std.testing.expect(arguments("10.0.0.1 80 \"unterminated", &selected) == null);
    try std.testing.expect(arguments("10.0.0.1 80 a\"b", &selected) == null);
}
