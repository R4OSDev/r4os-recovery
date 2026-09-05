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

    pub fn isUnspecified(self: Ipv4Address) bool {
        return self.octets == .{ 0, 0, 0, 0 };
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
        return connection.call(op, request, response, timeout);
    }

    fn tcpServiceCall(self: *const Network, op: u16, request: []const u8, response: []u8, timeout: Timeout) services_facade.ServiceCall {
        var encoded: [abi.service_api_max_payload]u8 = undefined;
        const deadline_tick = service_deadline.deadlineFromTimeout(timeout, self.sys.ticks(), self.sys.monotonicHz()) catch
            return .{ .failure = abi.service_api_result_invalid };
        const payload = service_deadline.append(encoded[0..], request, deadline_tick) orelse
            return .{ .failure = abi.service_api_result_buffer_too_small };
        return self.serviceCall(tcp_service, op, payload, response, timeout);
    }
};

pub const Resolver = struct {
    network: Network,

    pub fn resolveA(self: *Resolver, name: []const u8, server: ?Ipv4Address, timeout: Timeout) ResolveResult {
        if (name.len == 0 or name.len > abi.service_api_max_payload - 4) return .{ .failure = abi.dns_result_name };
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
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
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
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
        const outcome = self.finishIo(result, result.bytes);
        switch (outcome) {
            .bytes => if (result.bytes != 0) {
                const len: usize = @intCast(result.bytes);
                if (len > capacity or @sizeOf(abi.NetServiceTcpResult) + len > response.len) return .{ .failure = abi.service_api_result_invalid };
                @memcpy(out[0..len], response[@sizeOf(abi.NetServiceTcpResult) .. @sizeOf(abi.NetServiceTcpResult) + len]);
            },
            else => {},
        }
        return outcome;
    }

    pub fn poll(self: *TcpSocket, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var request: [4]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_poll_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
        return self.finishIo(result, result.pending_rx);
    }

    pub fn close(self: *TcpSocket, timeout: Timeout) SocketIo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        var request: [4]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        var response: [@sizeOf(abi.NetServiceTcpResult)]u8 = undefined;
        const call = self.network.tcpServiceCall(abi.net_service_op_tcp_close_result, request[0..], response[0..], timeout);
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
        const state = classifyTcp(result);
        if (state == .ok or state == .closed) {
            self.raw = 0;
            return .closed;
        }
        return mapSocketState(state, result.result);
    }

    fn finishIo(self: *TcpSocket, result: abi.NetServiceTcpResult, bytes: u32) SocketIo {
        const state = classifyTcp(result);
        if (state == .closed or state == .reset or state == .peer_closed) self.raw = 0;
        return if (state == .ok) .{ .bytes = @intCast(bytes) } else mapSocketState(state, result.result);
    }
};

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
        const result = parseTcpCall(call, response[0..]) catch |raw| return mapSocketFailure(raw);
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
        return self.finishIo(result, if (result.bytes != 0) result.bytes else @intCast(data.len));
    }

    pub fn receiveFrom(self: *UdpSocket, out: []u8, timeout: Timeout) UdpReceive {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const capacity = @min(out.len, abi.net_service_udp_read_max);
        var request: [6]u8 = undefined;
        writeU32(request[0..], 0, self.raw);
        writeU16(request[0..], 4, @intCast(capacity));
        var response: [@sizeOf(abi.NetServiceUdpResult) + abi.net_service_udp_read_max]u8 = undefined;
        const call = self.network.serviceCall(udp_service, abi.net_service_op_udp_recv_result, request[0..], response[0..], timeout);
        const result = parseUdpCall(call, response[0..]) catch |raw| return mapUdpReceiveFailure(raw);
        const state = classifyUdp(result);
        if (state != .ok) {
            if (state == .closed or state == .reset or state == .peer_closed) self.raw = 0;
            return mapUdpReceiveState(state, result.result);
        }
        const len: usize = @intCast(result.bytes);
        if (len > capacity or @sizeOf(abi.NetServiceUdpResult) + len > response.len) return .{ .failure = abi.service_api_result_invalid };
        if (len != 0) @memcpy(out[0..len], response[@sizeOf(abi.NetServiceUdpResult) .. @sizeOf(abi.NetServiceUdpResult) + len]);
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

fn parseStructCall(comptime T: type, call: services_facade.ServiceCall, response: []const u8) error{ TimedOut, NoService, RemoteFailure, Invalid }!T {
    const meta = switch (call) {
        .response => |value| value,
        .timed_out => return error.TimedOut,
        .remote_failure => return error.RemoteFailure,
        .failure => |raw| return if (raw == abi.service_api_result_not_found or raw == abi.service_api_result_no_endpoint or raw == abi.service_api_result_not_running) error.NoService else error.RemoteFailure,
    };
    if (meta.bytes < @sizeOf(T) or response.len < @sizeOf(T)) return error.Invalid;
    var value: T = undefined;
    @memcpy(std.mem.asBytes(&value), response[0..@sizeOf(T)]);
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
        error.TimedOut => .timed_out,
        error.NoService => .no_service,
        else => .{ .failure = mapError(raw) },
    };
}

fn mapListenerFailure(raw: anyerror) ListenerOpen {
    return switch (raw) {
        error.TimedOut => .timed_out,
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

fn mapSocketFailure(raw: anyerror) SocketIo {
    return switch (raw) {
        error.TimedOut => .timed_out,
        error.NoService => .{ .failure = abi.service_api_result_no_endpoint },
        else => .{ .failure = mapError(raw) },
    };
}

fn mapAcceptFailure(raw: anyerror) TcpAccept {
    return switch (raw) {
        error.TimedOut => .timed_out,
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
