const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4net = @import("r4net.zig");
const r4sys = @import("r4sys.zig");
const services_facade = @import("app_services.zig");
const service_deadline = @import("service_deadline.zig");
const time_contract = @import("time_contract.zig");

const dns_service: [*:0]const u8 = "DNSSVC";
const tcp_service: [*:0]const u8 = "TCPSVC";
const udp_service: [*:0]const u8 = "UDPSVC";

pub const Timeout = time_contract.Timeout;

pub const Ipv4Address = struct {
    octets: [4]u8 = .{ 0, 0, 0, 0 },

    pub fn init(a: u8, b: u8, c: u8, d: u8) Ipv4Address {
        return .{ .octets = .{ a, b, c, d } };
    }

    pub fn fromBytes(value: [4]u8) Ipv4Address {
        return .{ .octets = value };
    }

    pub fn parseCanonical(text: []const u8) ?Ipv4Address {
        var octets: [4]u8 = undefined;
        var part: usize = 0;
        var value: u16 = 0;
        var digits: usize = 0;
        for (text) |character| {
            if (character == '.') {
                if (part >= 3 or digits == 0) return null;
                octets[part] = @intCast(value);
                part += 1;
                value = 0;
                digits = 0;
                continue;
            }
            if (character < '0' or character > '9' or digits >= 3 or (digits == 1 and value == 0)) return null;
            value = value * 10 + (character - '0');
            if (value > 255) return null;
            digits += 1;
        }
        if (part != 3 or digits == 0) return null;
        octets[3] = @intCast(value);
        return fromBytes(octets);
    }

    pub fn isUnspecified(self: Ipv4Address) bool {
        return std.mem.eql(u8, &self.octets, &.{ 0, 0, 0, 0 });
    }
};

pub const SocketAddress = struct {
    address: Ipv4Address,
    port: u16,
};

pub const ResolveResult = union(enum) {
    address: Ipv4Address,
    timed_out,
    not_found,
    no_service,
    failure: i32,
};

pub const SocketIo = union(enum) {
    bytes: usize,
    would_block,
    timed_out,
    reset,
    peer_closed,
    closed,
    failure: i32,
};

pub const TcpOpen = union(enum) {
    socket: TcpSocket,
    would_block,
    timed_out,
    reset,
    peer_closed,
    no_service,
    failure: i32,
};

pub const ListenerOpen = union(enum) {
    listener: TcpListener,
    timed_out,
    no_service,
    failure: i32,
};

pub const TcpAccept = union(enum) {
    socket: TcpSocket,
    would_block,
    timed_out,
    reset,
    closed,
    no_service,
    failure: i32,
};

/// A validated close reply releases the TCPSVC frontend handle. A lifecycle
/// of pending_close still has a network shutdown in progress.
pub const TcpCloseReceipt = struct {
    outcome: SocketIo = .{ .failure = abi.err_closed },
    operation: u16 = abi.net_service_op_tcp_close_result,
    action: u16 = 0,
    ack: u32 = 0,
    lifecycle_cause: u32 = abi.net_service_socket_lifecycle_unknown,
    service_status: u32 = abi.net_service_status_idle,
    accepted: bool = false,
    pending_shutdown: bool = false,
    frontend_released: bool = false,
    submitted: bool = false,
    reply_valid: bool = false,
};

pub const UdpOpen = union(enum) {
    socket: UdpSocket,
    timed_out,
    no_service,
    failure: i32,
};

pub const Datagram = struct {
    source: SocketAddress,
    destination: SocketAddress,
    bytes: usize,
};

pub const UdpReceive = union(enum) {
    datagram: Datagram,
    would_block,
    timed_out,
    reset,
    peer_closed,
    closed,
    no_service,
    failure: i32,
};

pub const Network = struct {
    sys: r4sys.Context,
    net: r4net.Context,

    pub fn available(self: *const Network) bool {
        const services = services_facade.Services{ .sys = self.sys };
        return services.available() and self.net.hasFn("tcp_connect");
    }

    pub fn resolver(self: *const Network) Resolver {
        return .{ .network = self.* };
    }

    pub fn connectTcp(self: *const Network, remote: SocketAddress, timeout: Timeout) TcpOpen {
        var request: [6]u8 = undefined;
        @memcpy(request[0..4], remote.address.octets[0..]);
        writeU16(request[0..], 4, remote.port);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.tcpServiceCall(abi.net_service_op_tcp_connect_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapTcpOpenFailure(raw);
        const state = classifyTcp(result);
        if (state != .ok) return mapTcpOpenState(state, result.result);
        if ((result.flags & abi.net_service_tcp_flag_handle_valid) == 0 or result.handle == 0) return .{ .failure = abi.service_api_result_invalid };
        return .{ .socket = .{ .network = self.*, .raw = result.handle, .owned = true, .remote = remote } };
    }

    pub fn listenTcp(self: *const Network, port: u16, timeout: Timeout) ListenerOpen {
        var request: [2]u8 = undefined;
        writeU16(request[0..], 0, port);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.tcpServiceCall(abi.net_service_op_tcp_listen_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapListenerFailure(raw);
        return switch (classifyTcp(result)) {
            .ok => .{ .listener = .{ .network = self.*, .port = port, .owned = true } },
            .timed_out => .timed_out,
            .no_service => .no_service,
            else => .{ .failure = result.result },
        };
    }

    pub fn bindUdp(self: *const Network, port: u16, timeout: Timeout) UdpOpen {
        var request: [2]u8 = undefined;
        writeU16(request[0..], 0, port);
        var response: [@sizeOf(abi.NetServiceUdpResult)]u8 = undefined;
        const call = self.serviceCall(udp_service, abi.net_service_op_udp_bind_result, request[0..], response[0..], timeout);
        const result = parseUdpCall(call, response[0..]) catch |raw| return mapUdpOpenFailure(raw);
        const state = classifyUdp(result);
        if (state == .timed_out) return .timed_out;
        if (state == .no_service) return .no_service;
        if (state != .ok or (result.flags & abi.net_service_udp_flag_handle_valid) == 0 or result.handle == 0) return .{ .failure = result.result };
        return .{ .socket = .{ .network = self.*, .raw = result.handle, .owned = true, .local_port = port } };
    }

    fn serviceCall(self: *const Network, service_name: [*:0]const u8, op: u16, request: []const u8, response: []u8, timeout: Timeout) services_facade.ServiceCall {
        const services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open(service_name)) {
            .connection => |value| value,
            .failure => |raw| return .{ .failure = raw },
        };
        defer _ = connection.close();
        const call = connection.call(op, request, response, timeout);
        if (call == .response and call.response.header.op != op) return .{ .failure = abi.service_api_result_invalid };
        return call;
    }

    fn tcpServiceCall(self: *const Network, op: u16, request: []const u8, response: []u8, timeout: Timeout) services_facade.ServiceCall {
        return self.tcpServiceCallTracking(op, request, response, timeout, null);
    }

    fn tcpServiceCallTracking(self: *const Network, op: u16, request: []const u8, response: []u8, timeout: Timeout, submitted: ?*bool) services_facade.ServiceCall {
        if (submitted) |out| out.* = false;
        var encoded: [abi.service_api_max_payload]u8 = undefined;
        const hz = self.sys.monotonicHz();
        const finite = timeout.kind == abi.timeout_kind_finite;
        const started = if (finite) self.sys.ticks() else 0;
        const deadline_tick = service_deadline.deadlineFromTimeout(timeout, started, hz) catch
            return .{ .failure = abi.service_api_result_invalid };
        if (finite and deadline_tick <= started) return .timed_out;
        const payload = service_deadline.append(encoded[0..], request, deadline_tick) orelse
            return .{ .failure = abi.service_api_result_buffer_too_small };
        const services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open(tcp_service)) {
            .connection => |value| value,
            .failure => |raw| return .{ .failure = raw },
        };
        defer _ = connection.close();
        const now = if (finite) self.sys.ticks() else 0;
        if (finite and now >= deadline_tick) return .timed_out;
        const remaining = if (timeout.kind == abi.timeout_kind_poll) 0 else if (deadline_tick == service_deadline.forever_tick) abi.io_wait_forever else deadline_tick - now;
        if (submitted) |out| out.* = true;
        const call = services_facade.callWithTicks(&connection, op, payload, response, remaining);
        if (call == .response and call.response.header.op != op) return .{ .failure = abi.service_api_result_invalid };
        return call;
    }
};

pub const Resolver = struct {
    network: Network,

    pub fn resolveA(self: *Resolver, name: []const u8, server: ?Ipv4Address, timeout: Timeout) ResolveResult {
        if (name.len == 0 or name.len > abi.service_api_max_payload - 4) return .{ .failure = abi.dns_result_name };
        if (Ipv4Address.parseCanonical(name)) |address| return .{ .address = address };
        if (self.network.sys.base.generation2) |context| {
            const family = @import("network_family.zig");
            const rpc = @import("rpc_budget.zig");
            const clock = @import("stream_adapters.zig").PlatformClock.fromContext2(context) catch
                return .{ .failure = rpc.code(error.ClockUnavailable) };
            var budget = rpc.Budget.fromTimeout(clock.read, timeout) catch |err|
                return .{ .failure = rpc.code(err) };
            var client: family.Client = undefined;
            const opened = family.Client.connect(context, .dns, &client);
            if (opened == abi.service_api_result_not_found or opened == abi.service_api_result_no_endpoint or opened == abi.service_api_result_not_running) return .no_service;
            if (opened != 0) return .{ .failure = opened };
            defer _ = client.close();
            var answers: [32]abi.NetworkResolveAnswer = undefined;
            var count: u32 = 0;
            const selected_server = if (server) |address| family.common.v4Endpoint(address.octets, 53) else abi.NetworkEndpoint{};
            const result = family.resolveAll(&client, name, 4, selected_server, &budget, &answers, &count);
            if (result == abi.network_error_timeout or result == abi.service_api_result_timeout) return .timed_out;
            if (result == abi.network_error_not_found) return .not_found;
            if (result != 0) return .{ .failure = result };
            if (count == 0) return .not_found;
            return .{ .address = Ipv4Address.fromBytes(answers[0].address.bytes[0..4].*) };
        }
        var request: [abi.service_api_max_payload]u8 = undefined;
        var len: usize = 0;
        const op: u16 = if (server) |address| blk: {
            @memcpy(request[0..4], address.octets[0..]);
            len = 4;
            break :blk abi.net_service_op_dns_resolve_a_server_result;
        } else abi.net_service_op_dns_resolve_a_result;
        @memcpy(request[len .. len + name.len], name);
        len += name.len;

        var response: [@sizeOf(abi.NetServiceDnsResult)]u8 = undefined;
        const call = self.network.serviceCall(dns_service, op, request[0..len], response[0..], timeout);
        const parsed = parseStructCall(abi.NetServiceDnsResult, call, response[0..]) catch |raw| return mapResolveFailure(raw);
        if (parsed.magic != abi.net_service_dns_result_magic or parsed.version != abi.net_service_dns_result_version) return .{ .failure = abi.service_api_result_invalid };
        if (parsed.result == abi.dns_result_ok and (parsed.flags & abi.net_service_dns_flag_ok) != 0) return .{ .address = Ipv4Address.fromBytes(parsed.answer) };
        if (parsed.result == abi.dns_result_timeout) return .timed_out;
        if (parsed.result == abi.dns_result_nxdomain) return .not_found;
        return .{ .failure = parsed.result };
    }
};

pub const TcpSocket = struct {
    network: Network,
    raw: u32 = 0,
    owned: bool = false,
    remote: SocketAddress = .{ .address = .{}, .port = 0 },
    close_uncertain: bool = false,

    pub fn valid(self: *const TcpSocket) bool {
        return self.raw != 0;
    }

    pub fn write(self: *TcpSocket, data: []const u8, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (data.len > abi.net_service_tcp_write_max) return .{ .failure = abi.net_tx_too_large };
        var request: [4 + abi.net_service_tcp_write_max]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        @memcpy(request[4 .. 4 + data.len], data);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_write_result, request[0 .. 4 + data.len], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapTcpSocketFailure(raw);
        if (result.bytes > data.len) return .{ .failure = abi.service_api_result_invalid };
        return self.finishIo(result, result.bytes);
    }

    pub fn read(self: *TcpSocket, out: []u8, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const capacity = @min(out.len, abi.net_service_tcp_read_max);
        var request: [6]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        writeU16(request[0..], 4, @intCast(capacity));
        var response: [@sizeOf(abi.NetServiceTcpResult) + abi.net_service_tcp_read_max]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_read_result, request[0..], response[0..], timeout);
        const received = serviceResponse(call, response[0..]) catch |raw| return mapTcpSocketFailure(raw);
        const result = parseTcpCall(call, received) catch |raw| return mapTcpSocketFailure(raw);
        const outcome = self.finishIo(result, result.bytes);
        switch (outcome) {
            .bytes => if (result.bytes != 0) {
                const len: usize = @intCast(result.bytes);
                if (len > capacity or @sizeOf(abi.NetServiceTcpResult) + len > received.len) return .{ .failure = abi.service_api_result_invalid };
                @memcpy(out[0..len], received[@sizeOf(abi.NetServiceTcpResult) .. @sizeOf(abi.NetServiceTcpResult) + len]);
            },
            else => {},
        }
        return outcome;
    }

    /// State-only poll. No transferred bytes; use tcpReadiness for a snapshot.
    pub fn poll(self: *TcpSocket, timeout: Timeout) SocketIo {
        return tcpReadiness(self, timeout).outcome;
    }

    pub fn close(self: *TcpSocket, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        if (self.close_uncertain) return .{ .failure = abi.service_api_result_invalid };
        var request: [4]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_close_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapTcpSocketFailure(raw);
        const state = classifyTcp(result);
        if (state == .ok or state == .closed or (state == .peer_closed and result.lifecycle_cause == abi.net_service_socket_lifecycle_closed)) {
            self.raw = 0;
            return .closed;
        }
        return mapSocketState(state, result.result);
    }

    /// Issues at most one close. An unconfirmed submitted request is retained
    /// as uncertain on this object; callers must not issue a second close.
    pub fn closeReceipt(self: *TcpSocket, timeout: Timeout) TcpCloseReceipt {
        var receipt: TcpCloseReceipt = .{};
        if (!self.valid()) return receipt;
        if (!self.owned) {
            receipt.outcome = .{ .failure = abi.err_not_owned };
            return receipt;
        }
        if (self.close_uncertain) {
            receipt.submitted = true;
            receipt.outcome = .{ .failure = abi.service_api_result_invalid };
            return receipt;
        }
        var request: [4]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCallTracking(receipt.operation, request[0..], response[0..], timeout, &receipt.submitted);
        const result = parseTcpCall(call, response[0..]) catch |raw| {
            if (receipt.submitted) self.close_uncertain = true;
            receipt.outcome = mapTcpSocketFailure(raw);
            return receipt;
        };
        if (result.action != abi.net_service_tcp_action_close or
            (result.flags & abi.net_service_tcp_flag_handle_valid) == 0 or result.handle != self.raw)
        {
            self.close_uncertain = true;
            receipt.outcome = .{ .failure = abi.service_api_result_invalid };
            return receipt;
        }
        receipt.reply_valid = true;
        receipt.action = result.action;
        receipt.ack = result.tx_ack;
        receipt.lifecycle_cause = result.lifecycle_cause;
        receipt.service_status = result.service_status;
        receipt.outcome = mapSocketState(classifyTcp(result), result.result);
        if (result.result == 0) {
            receipt.accepted = true;
            receipt.pending_shutdown = result.lifecycle_cause == abi.net_service_socket_lifecycle_pending_close;
            receipt.frontend_released = true;
            receipt.outcome = .closed;
            self.raw = 0;
        } else {
            // TCPSVC may release its frontend even after a backend failure.
            self.close_uncertain = true;
        }
        return receipt;
    }

    fn finishIo(_: *TcpSocket, result: abi.NetServiceTcpResult, bytes: u32) SocketIo {
        const state = classifyTcp(result);
        // Transport termination does not acknowledge disposal of our frontend.
        return if (bytes != 0 or state == .ok) .{ .bytes = @intCast(bytes) } else mapSocketState(state, result.result);
    }
};

/// A validated snapshot can be both peer-closed and readable. Its pending_rx
/// is buffered availability, never a count transferred by the poll.
pub const TcpPoll = struct {
    outcome: SocketIo,
    readiness: ?r4net.TcpReadiness = null,
};

/// Kept at module scope so the existing GUI value-method ABI does not grow.
pub fn tcpReadiness(socket: *TcpSocket, timeout: Timeout) TcpPoll {
    if (!socket.valid()) return .{ .outcome = .{ .failure = abi.err_closed } };
    var request: [4]u8 = undefined;
    writeU32(request[0..], 0, socket.raw);
    var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
    const call = socket.network.tcpServiceCall(abi.net_service_op_tcp_poll_result, request[0..], response[0..], timeout);
    const result = parseTcpCall(call, response[0..]) catch |raw| return .{ .outcome = mapTcpSocketFailure(raw) };
    var snapshot = r4net.tcpResultReadiness(&result);
    if (result.service_status != abi.net_service_status_idle) snapshot.service_status = result.service_status;
    if (snapshot.would_block) snapshot.service_status = abi.net_service_status_would_block;
    snapshot.would_block = snapshot.service_status == abi.net_service_status_would_block or snapshot.would_block;
    const state = classifyTcp(result);
    return .{
        .outcome = if (state == .ok) .{ .bytes = 0 } else mapSocketState(state, result.result),
        .readiness = snapshot,
    };
}

pub const TcpListener = struct {
    network: Network,
    port: u16 = 0,
    owned: bool = false,

    pub fn valid(self: *const TcpListener) bool {
        return self.port != 0;
    }

    pub fn accept(self: *TcpListener, timeout: Timeout) TcpAccept {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var request: [2]u8 = undefined;
        writeU16(request[0..], 0, self.port);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_accept_poll_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapAcceptFailure(raw);
        const state = classifyTcp(result);
        if (state == .ok and (result.flags & abi.net_service_tcp_flag_handle_valid) != 0 and result.handle != 0) {
            const remote = SocketAddress{ .address = Ipv4Address.fromBytes(result.remote_ip), .port = result.remote_port };
            return .{ .socket = .{ .network = self.network, .raw = result.handle, .owned = true, .remote = remote } };
        }
        return mapAcceptState(state, result.result);
    }

    pub fn close(self: *TcpListener, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        var request: [2]u8 = undefined;
        writeU16(request[0..], 0, self.port);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_close_listen_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapTcpSocketFailure(raw);
        const state = classifyTcp(result);
        if (state == .ok or state == .closed) {
            self.port = 0;
            return .closed;
        }
        return mapSocketState(state, result.result);
    }
};

pub const UdpSocket = struct {
    network: Network,
    raw: u32 = 0,
    owned: bool = false,
    local_port: u16 = 0,

    pub fn valid(self: *const UdpSocket) bool {
        return self.raw != 0;
    }

    pub fn sendTo(self: *UdpSocket, destination: SocketAddress, data: []const u8, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (data.len > abi.net_service_udp_send_max) return .{ .failure = abi.net_tx_too_large };
        var request: [10 + abi.net_service_udp_send_max]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        @memcpy(request[4..8], destination.address.octets[0..]);
        writeU16(request[0..], 8, destination.port);
        @memcpy(request[10 .. 10 + data.len], data);
        var response: [@sizeOf(abi.NetServiceUdpResult)]u8 = undefined;
        const call = self.network.serviceCall(udp_service, abi.net_service_op_udp_sendto_result, request[0 .. 10 + data.len], response[0..], timeout);
        const result = parseUdpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
        if (result.bytes > data.len) return .{ .failure = abi.service_api_result_invalid };
        return self.finishIo(result, result.bytes);
    }

    pub fn receiveFrom(self: *UdpSocket, out: []u8, timeout: Timeout) UdpReceive {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const capacity = @min(out.len, abi.net_service_udp_read_max);
        var request: [6]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        writeU16(request[0..], 4, @intCast(capacity));
        var response: [@sizeOf(abi.NetServiceUdpResult) + abi.net_service_udp_read_max]u8 = undefined;
        const call = self.network.serviceCall(udp_service, abi.net_service_op_udp_recv_result, request[0..], response[0..], timeout);
        const received = serviceResponse(call, response[0..]) catch |raw| return mapUdpReceiveFailure(raw);
        const result = parseUdpCall(call, received) catch |raw| return mapUdpReceiveFailure(raw);
        const state = classifyUdp(result);
        if (state != .ok) {
            if (state == .closed or state == .reset or state == .peer_closed) self.raw = 0;
            return mapUdpReceiveState(state, result.result);
        }
        const len: usize = @intCast(result.bytes);
        if (len > capacity or @sizeOf(abi.NetServiceUdpResult) + len > received.len) return .{ .failure = abi.service_api_result_invalid };
        if (len != 0) @memcpy(out[0..len], received[@sizeOf(abi.NetServiceUdpResult) .. @sizeOf(abi.NetServiceUdpResult) + len]);
        return .{ .datagram = .{
            .source = .{ .address = Ipv4Address.fromBytes(result.source_ip), .port = result.source_port },
            .destination = .{ .address = Ipv4Address.fromBytes(result.dest_ip), .port = result.dest_port },
            .bytes = len,
        } };
    }

    pub fn close(self: *UdpSocket, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        var request: [4]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        var response: [@sizeOf(abi.NetServiceUdpResult)]u8 = undefined;
        const call = self.network.serviceCall(udp_service, abi.net_service_op_udp_close_result, request[0..], response[0..], timeout);
        const result = parseUdpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
        const state = classifyUdp(result);
        if (state == .ok or state == .closed) {
            self.raw = 0;
            return .closed;
        }
        return mapSocketState(state, result.result);
    }

    fn finishIo(self: *UdpSocket, result: abi.NetServiceUdpResult, bytes: u32) SocketIo {
        const state = classifyUdp(result);
        if (state == .closed or state == .reset or state == .peer_closed) self.raw = 0;
        return if (state == .ok) .{ .bytes = @intCast(bytes) } else mapSocketState(state, result.result);
    }
};

const SocketState = enum { ok, would_block, timed_out, reset, peer_closed, closed, no_service, failed };

fn classifyTcp(result: abi.NetServiceTcpResult) SocketState {
    const ready = r4net.tcpResultReadiness(&result);
    const service_status = if (result.service_status != abi.net_service_status_idle) result.service_status else ready.service_status;
    if (ready.would_block) return .would_block;
    if (service_status == abi.net_service_status_would_block) return .would_block;
    if (service_status == abi.net_service_status_timeout or ready.lifecycle_cause == abi.net_service_socket_lifecycle_timeout) return .timed_out;
    if (ready.reset) return .reset;
    if (ready.peer_closed) return .peer_closed;
    if (ready.lifecycle_cause == abi.net_service_socket_lifecycle_local_close or ready.lifecycle_cause == abi.net_service_socket_lifecycle_closed or ready.lifecycle_cause == abi.net_service_socket_lifecycle_bad_handle) return .closed;
    if (service_status == abi.net_service_status_failed and result.result == abi.net_tx_backend_error) return .no_service;
    return if (result.result == 0) .ok else .failed;
}

fn classifyUdp(result: abi.NetServiceUdpResult) SocketState {
    const flag_status = (result.flags & abi.net_service_status_mask) >> abi.net_service_status_shift;
    const status = if (result.service_status != abi.net_service_status_idle) result.service_status else flag_status;
    if (status == abi.net_service_status_would_block or result.lifecycle_cause == abi.net_service_socket_lifecycle_would_block) return .would_block;
    if (status == abi.net_service_status_timeout or result.lifecycle_cause == abi.net_service_socket_lifecycle_timeout) return .timed_out;
    if (result.lifecycle_cause == abi.net_service_socket_lifecycle_reset) return .reset;
    if (result.lifecycle_cause == abi.net_service_socket_lifecycle_peer_gone) return .peer_closed;
    if (result.lifecycle_cause == abi.net_service_socket_lifecycle_local_close or result.lifecycle_cause == abi.net_service_socket_lifecycle_closed or result.lifecycle_cause == abi.net_service_socket_lifecycle_bad_handle) return .closed;
    if (status == abi.net_service_status_failed and result.result == abi.net_tx_backend_error) return .no_service;
    return if (result.result == 0) .ok else .failed;
}

fn parseTcpCall(call: services_facade.ServiceCall, response: []const u8) error{ TimedOut, NoService, RemoteFailure, Invalid }!abi.NetServiceTcpResult {
    const result = try parseStructCall(abi.NetServiceTcpResult, call, response);
    if (result.magic != abi.net_service_tcp_result_magic or result.version != abi.net_service_tcp_result_version) return error.Invalid;
    return result;
}

fn parseUdpCall(call: services_facade.ServiceCall, response: []const u8) error{ TimedOut, NoService, RemoteFailure, Invalid }!abi.NetServiceUdpResult {
    const result = try parseStructCall(abi.NetServiceUdpResult, call, response);
    if (result.magic != abi.net_service_udp_result_magic or result.version != abi.net_service_udp_result_version) return error.Invalid;
    return result;
}

fn serviceResponse(call: services_facade.ServiceCall, response: []const u8) error{ TimedOut, NoService, RemoteFailure, Invalid }![]const u8 {
    const meta = switch (call) {
        .response => |value| value,
        .timed_out => return error.TimedOut,
        .remote_failure => return error.RemoteFailure,
        .failure => |raw| return if (raw == abi.service_api_result_not_found or raw == abi.service_api_result_no_endpoint or raw == abi.service_api_result_not_running) error.NoService else error.RemoteFailure,
    };
    if (meta.bytes > response.len or meta.header.magic != abi.service_api_magic or meta.header.version != abi.service_api_version) return error.Invalid;
    return response[0..meta.bytes];
}

fn parseStructCall(comptime T: type, call: services_facade.ServiceCall, response: []const u8) error{ TimedOut, NoService, RemoteFailure, Invalid }!T {
    const received = try serviceResponse(call, response);
    if (received.len < @sizeOf(T)) return error.Invalid;
    var value: T = undefined;
    @memcpy(std.mem.asBytes(&value), received[0..@sizeOf(T)]);
    return value;
}

fn mapError(raw: anyerror) i32 {
    return switch (raw) {
        error.TimedOut => abi.service_api_result_timeout,
        error.NoService => abi.service_api_result_no_endpoint,
        error.RemoteFailure => abi.service_api_result_not_running,
        error.Invalid => abi.service_api_result_invalid,
        else => abi.service_api_result_invalid,
    };
}

fn mapResolveFailure(raw: anyerror) ResolveResult {
    return switch (raw) {
        error.TimedOut => .timed_out,
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

fn mapTcpOpenFailure(raw: anyerror) TcpOpen {
    return switch (raw) {
        error.TimedOut => .{ .failure = abi.service_api_result_timeout },
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

fn mapListenerFailure(raw: anyerror) ListenerOpen {
    return switch (raw) {
        error.TimedOut => .{ .failure = abi.service_api_result_timeout },
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

fn mapUdpOpenFailure(raw: anyerror) UdpOpen {
    return switch (raw) {
        error.TimedOut => .timed_out,
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

// Missing/invalid TCP replies provide no confirmed prefix. In particular,
// a native client timeout is not the structured server timeout state.
fn mapTcpSocketFailure(raw: anyerror) SocketIo {
    return .{ .failure = mapError(raw) };
}

fn mapSocketFailure(raw: anyerror) SocketIo {
    return switch (raw) {
        error.TimedOut => .timed_out,
        error.NoService => .{ .failure = abi.service_api_result_no_endpoint },
        else => .{ .failure = mapError(raw) },
    };
}

fn mapAcceptFailure(raw: anyerror) TcpAccept {
    return switch (raw) {
        error.TimedOut => .{ .failure = abi.service_api_result_timeout },
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

fn mapUdpReceiveFailure(raw: anyerror) UdpReceive {
    return switch (raw) {
        error.TimedOut => .timed_out,
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

fn mapTcpOpenState(state: SocketState, raw: i32) TcpOpen {
    return switch (state) {
        .would_block => .would_block,
        .timed_out => .timed_out,
        .reset => .reset,
        .peer_closed => .peer_closed,
        .no_service => .no_service,
        else => .{ .failure = raw },
    };
}

fn mapAcceptState(state: SocketState, raw: i32) TcpAccept {
    return switch (state) {
        .would_block => .would_block,
        .timed_out => .timed_out,
        .reset => .reset,
        .closed, .peer_closed => .closed,
        .no_service => .no_service,
        else => .{ .failure = raw },
    };
}

fn mapSocketState(state: SocketState, raw: i32) SocketIo {
    return switch (state) {
        .would_block => .would_block,
        .timed_out => .timed_out,
        .reset => .reset,
        .peer_closed => .peer_closed,
        .closed => .closed,
        else => .{ .failure = raw },
    };
}

fn mapUdpReceiveState(state: SocketState, raw: i32) UdpReceive {
    return switch (state) {
        .would_block => .would_block,
        .timed_out => .timed_out,
        .reset => .reset,
        .peer_closed => .peer_closed,
        .closed => .closed,
        .no_service => .no_service,
        else => .{ .failure = raw },
    };
}

fn writeU16(out: []u8, offset: usize, value: u16) void {
    out[offset] = @truncate(value);
    out[offset + 1] = @truncate(value >> 8);
}

fn writeU32(out: []u8, offset: usize, value: u32) void {
    out[offset] = @truncate(value);
    out[offset + 1] = @truncate(value >> 8);
    out[offset + 2] = @truncate(value >> 16);
    out[offset + 3] = @truncate(value >> 24);
}
