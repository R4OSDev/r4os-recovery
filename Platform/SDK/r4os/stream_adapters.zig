//! Borrowed existing owners; no new file/socket handles, discovery, implicit
//! close, framing policy, peer ACK, retries or network stack.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const core = @import("stream_transfer.zig");
const budget = @import("time_budget.zig");
const footer = @import("service_deadline.zig");
const wire = @import("binary_cursor.zig");
const readiness = @import("r4net.zig").tcpResultReadiness;
pub const invalid: i32 = -11001;
pub const offset_unavailable: i32 = -11002;
pub const clock_unavailable: i32 = -11003;
pub const cancelled: i32 = -11004;

/// Normal synchronous consumer driver. All steps retain the caller's single
/// absolute budget. Only confirmed WouldBlock permits a further owner call.
pub const Driver = struct {
    sys: @import("r4sys.zig").Context,
    clock: *PlatformClock,
    budget: *@import("rpc_budget.zig").Budget,

    pub fn read(self: Driver, bytes: []u8, limit: u32, reader: core.Read, context: ?*anyopaque, exact: bool) core.Error!core.Progress {
        var transfer = try core.Transfer.initAbsolute(.read_exact, bytes.len, self.budget.deadline);
        defer self.budget.deadline = transfer.deadline;
        while (true) {
            const progress = try transfer.readStep(bytes[@intCast(transfer.bytes)..], limit, self.sys.programShouldClose(), PlatformClock.sample, self.clock, reader, context);
            if (progress.flags & core.terminal != 0 or !exact and progress.bytes != 0) return progress;
            if (progress.outcome == @intFromEnum(core.Outcome.would_block)) self.sys.sleepTicks(1);
        }
    }

    pub fn write(self: Driver, bytes: []const u8, limit: u32, writer: core.Write, context: ?*anyopaque) core.Error!core.Progress {
        var transfer = try core.Transfer.initAbsolute(.write_all, bytes.len, self.budget.deadline);
        defer self.budget.deadline = transfer.deadline;
        while (true) {
            const progress = try transfer.writeStep(bytes[@intCast(transfer.bytes)..], limit, self.sys.programShouldClose(), PlatformClock.sample, self.clock, writer, context);
            if (progress.flags & core.terminal != 0) return progress;
            if (progress.outcome == @intFromEnum(core.Outcome.would_block)) self.sys.sleepTicks(1);
        }
    }
};
fn result(kind: core.IoKind, code: i32) core.Ack {
    return .{ .kind = @intFromEnum(kind), .error_code = code };
}
pub const PlatformClock = extern struct {
    read: ?abi.R4SysFns.monotonic_clock = null,
    pub fn sample(raw: ?*anyopaque, out: *budget.ClockSample) callconv(.c) i32 {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return invalid));
        const callback = self.read orelse return abi.err_no_fn;
        var info: abi.MonotonicClockInfo = .{};
        if (callback(&info) <= 0) return clock_unavailable;
        out.* = budget.ClockSample.fromInfo(info) catch return clock_unavailable;
        return 0;
    }
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var address: u64 = 0;
        if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "monotonic_clock"), &address) != 0) return error.NoProvider;
        return .{ .read = @ptrFromInt(address) };
    }
};
fn streamResult(got: i32, read: bool) core.Ack {
    if (got < 0) return result(.uncertain, got);
    return .{ .bytes = @intCast(got), .kind = @intFromEnum(if (got == 0) (if (read) core.IoKind.eof else core.IoKind.would_block) else core.IoKind.progress) };
}
pub const FileRead = extern struct {
    read: ?abi.R4SysFns.file_read_at = null,
    path: ?[*:0]const u8 = null,
    base_offset: u64 = 0,
    pub fn step(raw: ?*anyopaque, offset: u64, out: [*]u8, length: u32, _: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        const callback = self.read orelse return result(.failed, abi.err_no_fn);
        const path = self.path orelse return result(.failed, invalid);
        const absolute = std.math.add(u64, self.base_offset, offset) catch return result(.failed, offset_unavailable);
        // The actual synchronous legacy entry has a32-bit offset. Do not
        // truncate or invent a file handle; wide asynchronous IO stays with
        // its existing request/loan owner. This adapter states its range.
        if (absolute > std.math.maxInt(u32)) return result(.failed, offset_unavailable);
        return streamResult(callback(path, @intCast(absolute), out, length), true);
    }
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context, path: [*:0]const u8, base: u64) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var address: u64 = 0;
        if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "file_read_at"), &address) != 0) return error.NoProvider;
        return .{ .read = @ptrFromInt(address), .path = path, .base_offset = base };
    }
};
pub const FileAppend = extern struct {
    append: ?abi.R4SysFns.file_append = null,
    path: ?[*:0]const u8 = null,
    pub fn step(raw: ?*anyopaque, _: u64, data: [*]const u8, length: u32, _: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        const callback = self.append orelse return result(.failed, abi.err_no_fn);
        const path = self.path orelse return result(.failed, invalid);
        return streamResult(callback(path, data, length), false);
    }
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context, path: [*:0]const u8) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var address: u64 = 0;
        if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "file_append"), &address) != 0) return error.NoProvider;
        return .{ .append = @ptrFromInt(address), .path = path };
    }
};
pub const FileStream = extern struct {
    write: ?abi.R4SysFns.file_stream_write = null,
    path: ?[*:0]const u8 = null,
    base_offset: u64 = 0,
    pub fn step(raw: ?*anyopaque, offset: u64, data: [*]const u8, length: u32, _: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        const callback = self.write orelse return result(.failed, abi.err_no_fn);
        const path = self.path orelse return result(.failed, invalid);
        const absolute = std.math.add(u64, self.base_offset, offset) catch return result(.failed, offset_unavailable);
        return streamResult(callback(path, absolute, data, length, 0), false);
    }
    // Begin/finish/abort/file publish remain with the original stream owner.
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context, path: [*:0]const u8, base: u64) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var address: u64 = 0;
        if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "file_stream_write"), &address) != 0) return error.NoProvider;
        return .{ .write = @ptrFromInt(address), .path = path, .base_offset = base };
    }
};
const Timing = struct { sample: budget.ClockSample, ticks: u64 };
fn ticksRemaining(read: ?abi.R4SysFns.monotonic_clock, deadline: *const budget.DeadlineBudget) error{ NoProvider, Invalid, Timeout }!Timing {
    var clock: PlatformClock = .{ .read = read };
    var sample: budget.ClockSample = .{};
    if (PlatformClock.sample(&clock, &sample) != 0) return error.NoProvider;
    var check = deadline.*;
    const remaining = check.remaining(sample) catch return error.Invalid;
    if (deadline.kind == 1 and remaining.kind == 0) return error.Timeout;
    const ticks: u64 = if (remaining.kind == 0) 0 else if (remaining.kind == 2) abi.io_wait_forever else budget.scaleCeil(remaining.value, sample.identity.tick_hz, abi.nanoseconds_per_second) catch return error.Invalid;
    if (remaining.kind == 1 and (ticks == 0 or ticks == abi.io_wait_forever)) return error.Invalid;
    return .{ .sample = sample, .ticks = ticks };
}
fn timingFailure(err: anyerror) core.Ack {
    return result(if (err == error.Timeout) .timed_out else .failed, if (err == error.NoProvider) abi.err_no_fn else invalid);
}
fn validHeader(header: abi.ServiceMessageHeader, op: u16, got: i32, capacity: usize) bool {
    return got >= 0 and @as(usize, @intCast(got)) <= capacity and header.magic == abi.service_api_magic and header.version == abi.service_api_version and header.op == op and header.payload_len == got;
}
pub const Tcp = extern struct {
    call: ?abi.R4SysFns.service_call = null,
    monotonic: ?abi.R4SysFns.monotonic_clock = null,
    ticks: ?abi.R4SysFns.ticks = null,
    service_handle: u32 = 0,
    socket_handle: u32 = 0,
    fn invoke(self: *Tcp, reading: bool, input: []const u8, output: []u8, deadline: *const budget.DeadlineBudget) core.Ack {
        const call = self.call orelse return result(.failed, abi.err_no_fn);
        const tick = self.ticks orelse return result(.failed, abi.err_no_fn);
        if (self.service_handle == 0 or self.socket_handle == 0) return result(.failed, invalid);
        const timing = ticksRemaining(self.monotonic, deadline) catch |err| return timingFailure(err);
        const now_tick = tick();
        const end_tick = if (deadline.kind == 0) footer.tcp_poll_tick else if (deadline.kind == 2) footer.forever_tick else std.math.add(u64, now_tick, timing.ticks) catch return result(.failed, invalid);
        if (deadline.kind == 1 and end_tick == footer.forever_tick) return result(.failed, invalid);
        var body: [4 + abi.net_service_tcp_write_max]u8 = undefined;
        var writer = wire.Writer.init(&body) catch unreachable;
        writer.writeInt(u32, self.socket_handle, .little) catch unreachable;
        const count = @min(if (reading) output.len else input.len, if (reading) abi.net_service_tcp_read_max else abi.net_service_tcp_write_max);
        if (reading) writer.writeInt(u16, @intCast(count), .little) catch unreachable else writer.put(input[0..count]) catch unreachable;
        var request: [abi.service_api_max_payload]u8 = undefined;
        const payload = footer.append(&request, body[0..writer.position], end_tick) orelse return result(.failed, invalid);
        var response: [abi.service_api_max_payload]u8 = undefined;
        var header: abi.ServiceMessageHeader = .{};
        const op = if (reading) abi.net_service_op_tcp_read_result else abi.net_service_op_tcp_write_result;
        const got = call(self.service_handle, op, payload.ptr, @intCast(payload.len), &header, &response, response.len, timing.ticks);
        if (!validHeader(header, op, got, response.len) or header.status != 0 or got < @sizeOf(abi.NetServiceTcpResult)) return result(.uncertain, if (got < 0) got else if (header.status != 0) header.status else invalid);
        var reply: abi.NetServiceTcpResult = undefined;
        @memcpy(std.mem.asBytes(&reply), response[0..@sizeOf(abi.NetServiceTcpResult)]);
        if (reply.magic != abi.net_service_tcp_result_magic or reply.version != abi.net_service_tcp_result_version or reply.action != (if (reading) abi.net_service_tcp_action_read else abi.net_service_tcp_action_write) or reply.bytes > count or (reading and @sizeOf(abi.NetServiceTcpResult) + reply.bytes > @as(usize, @intCast(got)))) return result(.uncertain, invalid);
        const ready = readiness(&reply);
        const status = if (reply.service_status != abi.net_service_status_idle) reply.service_status else ready.service_status;
        // The original TCPSVC deadline-admission path deliberately returns
        // handle0/bytes0 before looking up a socket. That is confirmed zero,
        // unlike a missing/invalid reply after submission.
        const admission_timeout = reply.handle == 0 and reply.bytes == 0 and status == abi.net_service_status_timeout and ready.lifecycle_cause == abi.net_service_socket_lifecycle_timeout and reply.flags & abi.net_service_tcp_flag_handle_valid == 0;
        if (reply.handle != self.socket_handle and !admission_timeout) return result(.uncertain, invalid);
        if (reading) @memcpy(output[0..reply.bytes], response[@sizeOf(abi.NetServiceTcpResult)..][0..reply.bytes]);
        // A graceful peer close can coexist with buffered received data.
        // Preserve a positive read and obtain EOF from a later zero read;
        // never throw away unread suffixes based on a state snapshot.
        const kind: core.IoKind = if (status == abi.net_service_status_timeout or ready.lifecycle_cause == abi.net_service_socket_lifecycle_timeout) .timed_out else if (ready.reset or ready.lifecycle_cause == abi.net_service_socket_lifecycle_local_close) .closed else if (ready.peer_closed) (if (reading) (if (reply.bytes == 0 and reply.pending_rx == 0) core.IoKind.eof else core.IoKind.progress) else core.IoKind.closed) else if (ready.would_block or status == abi.net_service_status_would_block) .would_block else if (reply.result != 0) .failed else .progress;
        return .{ .bytes = reply.bytes, .kind = @intFromEnum(kind), .error_code = reply.result };
    }
    pub fn read(raw: ?*anyopaque, _: u64, data: [*]u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *Tcp = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        return self.invoke(true, &.{}, data[0..length], deadline);
    }
    pub fn write(raw: ?*anyopaque, _: u64, data: [*]const u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *Tcp = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        return self.invoke(false, data[0..length], &.{}, deadline);
    }
    /// Both handles are borrowed from actual owners in this same client
    /// identity. Transfer completion/timeout does not close or retire them.
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context, service: u32, socket: u32) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var addresses: [3]u64 = undefined;
        inline for (.{ "service_call", "monotonic_clock", "ticks" }, 0..) |name, i| if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, name), &addresses[i]) != 0) return error.NoProvider;
        return .{ .call = @ptrFromInt(addresses[0]), .monotonic = @ptrFromInt(addresses[1]), .ticks = @ptrFromInt(addresses[2]), .service_handle = service, .socket_handle = socket };
    }
};
pub const ServiceDecode = *const fn (?*anyopaque, u64, [*]const u8, u32, *const abi.ServiceMessageHeader, [*]const u8, u32) callconv(.c) core.Ack;
pub const ServiceSink = extern struct {
    call: ?abi.R4SysFns.service_call = null,
    monotonic: ?abi.R4SysFns.monotonic_clock = null,
    decode: ?ServiceDecode = null,
    decoder_context: ?*anyopaque = null,
    service_handle: u32 = 0,
    op: u16 = 0,
    reserved: u16 = 0,
    pub fn write(raw: ?*anyopaque, offset: u64, data: [*]const u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        const call = self.call orelse return result(.failed, abi.err_no_fn);
        const decode = self.decode orelse return result(.failed, abi.err_no_fn);
        if (self.reserved != 0 or self.service_handle == 0 or length > abi.service_api_max_payload) return result(.failed, invalid);
        const timing = ticksRemaining(self.monotonic, deadline) catch |err| return timingFailure(err);
        var response: [abi.service_api_max_payload]u8 = undefined;
        var header: abi.ServiceMessageHeader = .{};
        const got = call(self.service_handle, self.op, data, length, &header, &response, response.len, timing.ticks);
        if (!validHeader(header, self.op, got, response.len)) return result(.uncertain, if (got < 0) got else invalid);
        // Response length is NOT acknowledged request bytes. Only the
        // explicitly selected operation's decoder may confirm a prefix.
        return decode(self.decoder_context, offset, data, length, &header, &response, @intCast(got));
    }
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context, service: u32, op: u16, decode: ServiceDecode, decoder_context: ?*anyopaque) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var addresses: [2]u64 = undefined;
        inline for (.{ "service_call", "monotonic_clock" }, 0..) |name, i| if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, name), &addresses[i]) != 0) return error.NoProvider;
        return .{ .call = @ptrFromInt(addresses[0]), .monotonic = @ptrFromInt(addresses[1]), .decode = decode, .decoder_context = decoder_context, .service_handle = service, .op = op };
    }
};
pub const ServiceReply = extern struct {
    call: ?abi.R4SysFns.service_call = null,
    monotonic: ?abi.R4SysFns.monotonic_clock = null,
    service_handle: u32 = 0,
    op: u16 = 0,
    reserved: u16 = 0,
    request: wire.Span = .{},
    scratch: wire.Span = .{},
    position: usize = 0,
    length: usize = 0,
    loaded: u32 = 0,
    flags: u32 = 0,
    pub fn read(raw: ?*anyopaque, offset: u64, data: [*]u8, count: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return result(.failed, invalid)));
        const call = self.call orelse return result(.failed, abi.err_no_fn);
        if (self.service_handle == 0 or self.reserved != 0 or self.flags != 0 or self.loaded > 1 or self.position != offset or self.position > self.length or self.scratch.length > abi.service_api_max_payload or self.request.length > abi.service_api_max_payload) return result(.failed, invalid);
        const request = self.request.bytes() catch return result(.failed, invalid);
        const storage = @constCast(self.scratch.bytes() catch return result(.failed, invalid));
        if (self.loaded == 0) {
            const timing = ticksRemaining(self.monotonic, deadline) catch |err| return timingFailure(err);
            var header: abi.ServiceMessageHeader = .{};
            const got = call(self.service_handle, self.op, request.ptr, @intCast(request.len), &header, storage.ptr, @intCast(storage.len), timing.ticks);
            if (!validHeader(header, self.op, got, storage.len) or header.status != 0) {
                self.loaded = 2;
                return result(.uncertain, if (got < 0) got else if (header.status != 0) header.status else invalid);
            }
            self.loaded = 1;
            self.length = @intCast(got);
        }
        const n = @min(@as(usize, count), self.length - self.position);
        // Caller keeps state, request, scratch and result spans separate.
        @memcpy(data[0..n], storage[self.position..][0..n]);
        self.position += n;
        return .{ .bytes = @intCast(n), .kind = @intFromEnum(if (self.position == self.length) core.IoKind.eof else core.IoKind.progress) };
    }
    /// One service reply is a bounded source, never an implicit sequence of
    /// repeated RPCs. Scratch remains exclusively borrowed across steps.
    pub fn fromContext2(ctx: *const @import("platform2.zig").Context, service: u32, op: u16, request: []const u8, scratch: []u8) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var addresses: [2]u64 = undefined;
        inline for (.{ "service_call", "monotonic_clock" }, 0..) |name, i| if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, name), &addresses[i]) != 0) return error.NoProvider;
        return .{ .call = @ptrFromInt(addresses[0]), .monotonic = @ptrFromInt(addresses[1]), .service_handle = service, .op = op, .request = .{ .address = @intFromPtr(request.ptr), .length = request.len }, .scratch = .{ .address = @intFromPtr(scratch.ptr), .length = scratch.len } };
    }
};

test "stream owner file adapters retain exact prefixes and expose the actual synchronous offset range" {
    const P = struct {
        var calls: u32 = 0;
        fn read(_: [*:0]const u8, offset: u32, data: [*]u8, length: u32) callconv(.c) i32 {
            calls += 1;
            if (offset >= 3) return 0;
            const n = @min(length, 3 - offset);
            @memcpy(data[0..n], "abc"[offset..][0..n]);
            return @intCast(n);
        }
        fn append(_: [*:0]const u8, _: [*]const u8, _: u32) callconv(.c) i32 {
            return -7;
        }
    };
    const deadline: budget.DeadlineBudget = .{};
    var file: FileRead = .{ .read = P.read, .path = "C:\\X" };
    var out: [4]u8 = undefined;
    try std.testing.expectEqual(@as(u32, 3), FileRead.step(&file, 0, &out, 4, &deadline).bytes);
    try std.testing.expectEqual(@intFromEnum(core.IoKind.eof), FileRead.step(&file, 3, &out, 4, &deadline).kind);
    try std.testing.expectEqual(offset_unavailable, FileRead.step(&file, 0x1_0000_0000, &out, 4, &deadline).error_code);
    try std.testing.expectEqual(@as(u32, 2), P.calls);
    var append: FileAppend = .{ .append = P.append, .path = "C:\\X" };
    try std.testing.expectEqual(@intFromEnum(core.IoKind.uncertain), FileAppend.step(&append, 0, "abc", 3, &deadline).kind);
}

const AdapterProbe = struct {
    var calls: u32 = 0;
    var instant_ns: u64 = 100;
    var reply: abi.NetServiceTcpResult = .{ .result = 0, .handle = 11, .bytes = 2, .pending_rx = 2, .lifecycle_cause = abi.net_service_socket_lifecycle_peer_gone };
    var fail_transport: bool = false;
    fn mono(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
        out.* = .{ .flags = abi.monotonic_clock_flag_valid, .source = 1, .generation = 1, .instant_ns = instant_ns, .resolution_ns = 1, .event_requested_hz = 1000 };
        return 1;
    }
    fn ticks() callconv(.c) u64 {
        return 100;
    }
    fn tcp(handle: u32, op: u16, request: [*]const u8, len: u32, header: *abi.ServiceMessageHeader, out: [*]u8, _: u32, wait_ticks: u64) callconv(.c) i32 {
        calls += 1;
        const view = footer.split(request[0..len]);
        if (handle != 7 or view.deadline_tick != 101 or wait_ticks != 1 or std.mem.readInt(u32, view.payload[0..4], .little) != 11) return -99;
        if (fail_transport) return abi.service_api_result_timeout;
        var value = reply;
        value.action = if (op == abi.net_service_op_tcp_read_result) abi.net_service_tcp_action_read else abi.net_service_tcp_action_write;
        @memcpy(out[0..@sizeOf(abi.NetServiceTcpResult)], std.mem.asBytes(&value));
        if (op == abi.net_service_op_tcp_read_result) @memset(out[@sizeOf(abi.NetServiceTcpResult)..][0..value.bytes], 'X');
        const n = @sizeOf(abi.NetServiceTcpResult) + if (op == abi.net_service_op_tcp_read_result) value.bytes else @as(u32, 0);
        header.* = .{ .op = op, .payload_len = @intCast(n) };
        return @intCast(n);
    }
    fn service(_: u32, op: u16, _: [*]const u8, _: u32, header: *abi.ServiceMessageHeader, out: [*]u8, capacity: u32, wait_ticks: u64) callconv(.c) i32 {
        calls += 1;
        if (capacity < 5 or wait_ticks != 1) return -99;
        @memcpy(out[0..5], "reply");
        header.* = .{ .op = op, .payload_len = 5 };
        return 5;
    }
    fn decode(_: ?*anyopaque, _: u64, _: [*]const u8, _: u32, header: *const abi.ServiceMessageHeader, bytes: [*]const u8, len: u32) callconv(.c) core.Ack {
        return if (header.status == 0 and len == 5 and std.mem.eql(u8, bytes[0..5], "reply")) .{ .bytes = 2 } else result(.uncertain, invalid);
    }
    fn deadline() budget.DeadlineBudget {
        return .{ .identity = .{ .source = 1, .generation = 1, .tick_hz = 1000 }, .deadline_ns = 110, .last_ns = 100, .kind = 1 };
    }
};
test "stream owner actual TCP footer keeps peer closed data distinct from EOF admission timeout and missing reply" {
    const P = AdapterProbe;
    P.calls = 0;
    P.instant_ns = 100;
    P.fail_transport = false;
    P.reply = .{ .result = 0, .handle = 11, .bytes = 2, .pending_rx = 2, .lifecycle_cause = abi.net_service_socket_lifecycle_peer_gone };
    var tcp: Tcp = .{ .call = P.tcp, .monotonic = P.mono, .ticks = P.ticks, .service_handle = 7, .socket_handle = 11 };
    var out: [4]u8 = undefined;
    const deadline = P.deadline();
    var ack = Tcp.read(&tcp, 0, &out, out.len, &deadline);
    try std.testing.expectEqual(@intFromEnum(core.IoKind.progress), ack.kind);
    try std.testing.expectEqual(@as(u32, 2), ack.bytes);
    try std.testing.expectEqualStrings("XX", out[0..2]);
    P.reply.bytes = 0;
    P.reply.pending_rx = 0;
    try std.testing.expectEqual(@intFromEnum(core.IoKind.eof), Tcp.read(&tcp, 2, &out, out.len, &deadline).kind);
    P.reply = .{ .result = 0, .service_status = abi.net_service_status_timeout, .lifecycle_cause = abi.net_service_socket_lifecycle_timeout };
    ack = Tcp.write(&tcp, 0, "abcd", 4, &deadline);
    try std.testing.expectEqual(@intFromEnum(core.IoKind.timed_out), ack.kind);
    try std.testing.expectEqual(@as(u32, 0), ack.bytes);
    P.reply.handle = 11;
    P.reply.bytes = 2;
    ack = Tcp.write(&tcp, 0, "abcd", 4, &deadline);
    try std.testing.expectEqual(@as(u32, 2), ack.bytes);
    try std.testing.expectEqual(@intFromEnum(core.IoKind.timed_out), ack.kind);
    P.fail_transport = true;
    try std.testing.expectEqual(@intFromEnum(core.IoKind.uncertain), Tcp.write(&tcp, 0, "abcd", 4, &deadline).kind);
    const before = P.calls;
    P.instant_ns = 110;
    try std.testing.expectEqual(@intFromEnum(core.IoKind.timed_out), Tcp.write(&tcp, 0, "abcd", 4, &deadline).kind);
    try std.testing.expectEqual(before, P.calls);
}
test "stream owner service reply is drained once and response length is never an invented write acknowledgement" {
    const P = AdapterProbe;
    P.calls = 0;
    P.instant_ns = 100;
    const deadline = P.deadline();
    var sink: ServiceSink = .{ .call = P.service, .monotonic = P.mono, .decode = P.decode, .service_handle = 7, .op = 44 };
    try std.testing.expectEqual(@as(u32, 2), ServiceSink.write(&sink, 0, "ABCDEFG", 7, &deadline).bytes);
    sink.decode = null;
    const before = P.calls;
    try std.testing.expectEqual(abi.err_no_fn, ServiceSink.write(&sink, 0, "ABCDEFG", 7, &deadline).error_code);
    try std.testing.expectEqual(before, P.calls);
    var scratch: [16]u8 = undefined;
    var source: ServiceReply = .{ .call = P.service, .monotonic = P.mono, .service_handle = 7, .op = 45, .request = .{ .address = @intFromPtr("query"), .length = 5 }, .scratch = .{ .address = @intFromPtr(&scratch), .length = scratch.len } };
    var out: [5]u8 = undefined;
    try std.testing.expectEqual(@as(u32, 2), ServiceReply.read(&source, 0, &out, 2, &deadline).bytes);
    try std.testing.expectEqual(@as(u32, 2), ServiceReply.read(&source, 2, out[2..].ptr, 2, &deadline).bytes);
    const last = ServiceReply.read(&source, 4, out[4..].ptr, 1, &deadline);
    try std.testing.expectEqual(@as(u32, 1), last.bytes);
    try std.testing.expectEqual(@intFromEnum(core.IoKind.eof), last.kind);
    try std.testing.expectEqualStrings("reply", &out);
    try std.testing.expectEqual(before + 1, P.calls);
}
