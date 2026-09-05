const std = @import("std");
const r4os = @import("r4os");

const ReplyMode = enum { ok, would_block, timeout, reset, peer_close, no_service };

var sys_table: r4os.abi.R4XStartR4Sys = .{};
var net_table: r4os.abi.R4XStartR4Net = .{};
var context: r4os.abi.R4XStartContext = .{};
var reply_mode: ReplyMode = .ok;
var endpoint_ready = false;
var open_handles: u32 = 0;
var endpoint_registered = false;

fn fakeOpen(name_z: [*:0]const u8, out: *r4os.abi.ServiceInfo) callconv(.c) i32 {
    const name = std.mem.span(name_z);
    if (reply_mode == .no_service or std.mem.eql(u8, name, "STOPPED")) return r4os.abi.service_api_result_not_running;
    const handle: u32 = if (std.mem.eql(u8, name, "DNSSVC")) 101 else if (std.mem.eql(u8, name, "TCPSVC")) 102 else if (std.mem.eql(u8, name, "UDPSVC")) 103 else 104;
    out.* = .{ .handle = handle };
    open_handles += 1;
    return r4os.abi.service_api_result_ok;
}

fn fakeClose(handle: u32) callconv(.c) i32 {
    if (handle < 101 or handle > 104 or open_handles == 0) return r4os.abi.service_api_result_bad_handle;
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
    if (handle == 104) {
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
            .bytes = if (op == r4os.abi.net_service_op_tcp_write_result) request_len - 4 else 0,
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

    reply_mode = .ok;
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
    reply_mode = .ok;
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
