//! Exclusive synchronous Query2 client for the existing DNS/TCP/UDP services.
//! Copied bounded records only. No automatic retry after uncertain mutations.
const std = @import("std");
pub const common = @import("network_common.zig");
pub const abi = common.abi;
pub const deadline = common.deadline;
pub const fromBudget = common.fromBudget;
const platform = @import("platform2.zig");
pub const Service = enum { dns, tcp, udp };
pub const Client = struct {
    call: abi.R4SysFns.service_call,
    close_call: abi.R4SysFns.service_close,
    handle: u32,
    service: Service,
    timeout_ticks: u64 = 500,
    pub fn connect(context: *const platform.Context, service: Service, out: *Client) i32 {
        const table = context.system();
        const open = platform.abi.function(platform.abi.R4SysFns2, table, "service_open") orelse return abi.err_no_fn;
        const call = platform.abi.function(platform.abi.R4SysFns2, table, "service_call") orelse return abi.err_no_fn;
        const close_call = platform.abi.function(platform.abi.R4SysFns2, table, "service_close") orelse return abi.err_no_fn;
        return openWith(open, call, close_call, service, out);
    }
    /// Use the caller's actual start generation for the copied service
    /// contract. A failed generation2 lookup never enters the legacy path.
    pub fn connectProvider(sys: @import("r4sys.zig").Context, service: Service, out: *Client) i32 {
        if (sys.base.generation2) |context| return connect(context, service, out);
        if (!sys.hasFn("service_open") or !sys.hasFn("service_call") or !sys.hasFn("service_close")) return abi.err_no_fn;
        const bundle = sys.base.bundle orelse return abi.err_no_group;
        const table = bundle.sys orelse return abi.err_no_group;
        return openWith(@ptrFromInt(table.service_open), @ptrFromInt(table.service_call), @ptrFromInt(table.service_close), service, out);
    }
    fn openWith(open: abi.R4SysFns.service_open, call: abi.R4SysFns.service_call, close_call: abi.R4SysFns.service_close, service: Service, out: *Client) i32 {
        const name: [*:0]const u8 = switch (service) {
            .dns => "DNSSVC",
            .tcp => "TCPSVC",
            .udp => "UDPSVC",
        };
        var endpoint: abi.ServiceInfo = .{};
        const rc = open(name, &endpoint);
        if (rc != 0) return rc;
        if (endpoint.handle == 0) return abi.service_api_result_no_endpoint;
        out.* = .{ .call = call, .close_call = close_call, .handle = endpoint.handle, .service = service };
        return 0;
    }
    pub fn close(self: *Client) i32 {
        if (self.handle == 0) return abi.network_error_bad_socket;
        const rc = self.close_call(self.handle);
        if (rc >= 0) self.handle = 0;
        return rc;
    }
    fn rpc(self: *const Client, op: u16, request: []const u8, response: []u8) i32 {
        if (self.handle == 0) return abi.network_error_bad_socket;
        var header: abi.ServiceMessageHeader = .{};
        const rc = self.call(self.handle, op, request.ptr, @intCast(request.len), &header, response.ptr, @intCast(response.len), self.timeout_ticks);
        if (rc < 0) return rc;
        if (header.status == abi.service_api_result_bad_op) return abi.err_no_fn;
        if (header.status != 0) return if (header.status < 0) header.status else abi.network_error_invalid;
        return rc;
    }
    pub fn info(self: *const Client, out: *abi.NetworkProviderInfo) i32 {
        var bytes: [@sizeOf(abi.NetworkProviderInfo)]u8 = undefined;
        const rc = self.rpc(abi.network_op_info, "", &bytes);
        if (rc < 0) return rc;
        const value = common.record(abi.NetworkProviderInfo, bytes[0..@intCast(@min(rc, bytes.len))]) catch return abi.network_error_invalid;
        if (rc != bytes.len or value.provider == 0 or value.reserved != 0 or value.capabilities & ~@as(u64, 4095) != 0 or value.max_send > 3968 or value.max_recv > 4008 or value.max_answers > 32 or value.page_capacity > 16) return abi.network_error_invalid;
        out.* = value;
        return 0;
    }
    /// Read/Recv return payload in data_out. Write/Send return an accepted byte
    /// prefix in result.bytes and no payload. Result/output stay untouched on
    /// malformed/negative replies. Caller retains every unaccepted suffix.
    pub fn socket(self: *const Client, op: u16, request: abi.NetworkSocketRequest, data_in: []const u8, data_out: []u8, out: *abi.NetworkSocketResult) i32 {
        if (self.service == .dns or op < abi.network_op_connect or op > abi.network_op_accept or op == abi.network_op_resolve or request.version != 1 or request.size != @sizeOf(@TypeOf(request)) or request.provider == 0 or data_in.len > 3968 or data_out.len > 4008) return abi.network_error_invalid;
        const sending = op == abi.network_op_write or op == abi.network_op_send;
        const receiving = op == abi.network_op_read or op == abi.network_op_recv;
        if (data_in.len != (if (sending) request.bytes else @as(u32, 0)) or receiving and request.bytes > data_out.len) return abi.network_error_invalid;
        var payload: [4096]u8 = undefined;
        @memcpy(payload[0..@sizeOf(@TypeOf(request))], std.mem.asBytes(&request));
        @memcpy(payload[@sizeOf(@TypeOf(request))..][0..data_in.len], data_in);
        var response: [4096]u8 = undefined;
        const rc = self.rpc(op, payload[0 .. @sizeOf(@TypeOf(request)) + data_in.len], &response);
        if (rc < 0) return rc;
        if (rc < @sizeOf(abi.NetworkSocketResult) or rc > response.len) return abi.network_error_invalid;
        const value = common.record(abi.NetworkSocketResult, response[0..@sizeOf(abi.NetworkSocketResult)]) catch return abi.network_error_invalid;
        const accepted = op == abi.network_op_accept and value.state == abi.network_state_ready;
        if (value.provider != request.provider or value.socket == 0 or value.generation == 0 or request.socket != 0 and !accepted and (value.socket != request.socket or value.generation != request.generation) or accepted and value.socket == request.socket and value.generation == request.generation or !common.endpointValid(value.endpoint) or value.state < 1 or value.state > 6 or value.flags & ~@as(u32, abi.network_flag_truncated) != 0) return abi.network_error_invalid;
        if (value.bytes > request.bytes or value.original_bytes < value.bytes or rc != @sizeOf(abi.NetworkSocketResult) + (if (receiving) value.bytes else @as(u32, 0))) return abi.network_error_invalid;
        if (op != abi.network_op_recv and (value.flags != 0 or value.original_bytes != value.bytes) or op == abi.network_op_recv and ((value.flags & abi.network_flag_truncated != 0) != (value.original_bytes > value.bytes))) return abi.network_error_invalid;
        if (receiving) @memcpy(data_out[0..value.bytes], response[@sizeOf(abi.NetworkSocketResult)..][0..value.bytes]);
        out.* = value;
        return 0;
    }
    pub fn resolve(self: *const Client, request: abi.NetworkResolveRequest, answers: []abi.NetworkResolveAnswer, out: *abi.NetworkResolvePage) i32 {
        if (self.service != .dns or request.capacity == 0 or request.capacity > 16 or request.capacity > answers.len) return abi.network_error_invalid;
        var response: [4096]u8 = undefined;
        const rc = self.rpc(abi.network_op_resolve, std.mem.asBytes(&request), &response);
        if (rc < 0) return rc;
        if (rc < @sizeOf(abi.NetworkResolvePage) or rc > response.len) return abi.network_error_invalid;
        const page = common.record(abi.NetworkResolvePage, response[0..@sizeOf(abi.NetworkResolvePage)]) catch return abi.network_error_invalid;
        if (page.provider != request.provider or page.provider == 0 or page.query == 0 or request.query != 0 and page.query != request.query or page.expires_ns == 0 or page.total == 0 or page.total > 32 or page.count == 0 or page.count > request.capacity or request.cursor > page.total or page.count > page.total - request.cursor or page.next != request.cursor + page.count or page.flags != (if (page.next < page.total) @as(u32, abi.network_flag_more) else 0) or rc != @sizeOf(abi.NetworkResolvePage) + page.count * @sizeOf(abi.NetworkResolveAnswer)) return abi.network_error_invalid;
        for (0..page.count) |i| {
            var answer: abi.NetworkResolveAnswer = undefined;
            @memcpy(std.mem.asBytes(&answer), response[@sizeOf(abi.NetworkResolvePage) + i * @sizeOf(abi.NetworkResolveAnswer) ..][0..@sizeOf(abi.NetworkResolveAnswer)]);
            if (!common.addressValid(answer.address) or answer.reserved != 0 or request.query == 0 and answer.address.family != request.family) return abi.network_error_invalid;
        }
        @memcpy(std.mem.sliceAsBytes(answers[0..page.count]), response[@sizeOf(abi.NetworkResolvePage)..][0 .. page.count * @sizeOf(abi.NetworkResolveAnswer)]);
        out.* = page;
        return 0;
    }
    pub fn release(self: *const Client, provider: u64, query: u64) i32 {
        if (self.service != .dns) return abi.network_error_invalid;
        const request: abi.NetworkResolveRequest = .{ .provider = provider, .query = query, .family = 0, .capacity = 0 };
        var bytes: [1]u8 = undefined;
        const rc = self.rpc(abi.network_op_release, std.mem.asBytes(&request), &bytes);
        return if (rc <= 0) rc else abi.network_error_invalid;
    }
};

/// Decimal IPv4 input used by the existing network tools. Leading zeroes
/// remain decimal. The independent canonical parser remains stricter.
pub fn parseIpv4(text: []const u8) ?[4]u8 {
    var result: [4]u8 = undefined;
    var parts = std.mem.splitScalar(u8, text, '.');
    for (&result) |*part| {
        const value = parts.next() orelse return null;
        if (value.len == 0) return null;
        var number: u16 = 0;
        for (value) |byte| {
            if (byte < '0' or byte > '9') return null;
            number = number * 10 + byte - '0';
            if (number > 255) return null;
        }
        part.* = @intCast(number);
    }
    if (parts.next() != null) return null;
    return result;
}

pub fn linkLocal(bytes: [16]u8) bool {
    return bytes[0] == 0xfe and bytes[1] & 0xc0 == 0x80;
}

/// Bare unicast address with an explicit numeric interface identity for
/// link-local IPv6. Native host interface names never enter this contract.
pub fn parseAddress(text: []const u8) ?abi.NetworkAddress {
    if (parseIpv4(text)) |bytes| return common.v4Endpoint(bytes, 0).address;
    if (text.len > 64) return null;
    const percent = std.mem.indexOfScalar(u8, text, '%');
    const literal = text[0..(percent orelse text.len)];
    const parsed = switch (std.Io.net.Ip6Address.Unresolved.parse(literal)) {
        .success => |value| value,
        else => return null,
    };
    if (parsed.interface_name != null or parsed.bytes[0] == 0xff or std.mem.allEqual(u8, &parsed.bytes, 0) or
        std.mem.allEqual(u8, parsed.bytes[0..10], 0) and parsed.bytes[10] == 0xff and parsed.bytes[11] == 0xff) return null;
    var scope: u32 = 0;
    if (percent) |at| {
        const digits = text[at + 1 ..];
        if (digits.len == 0) return null;
        for (digits) |byte| if (byte < '0' or byte > '9') return null;
        scope = std.fmt.parseInt(u32, digits, 10) catch return null;
        if (scope == 0) return null;
    }
    if (linkLocal(parsed.bytes) != (scope != 0)) return null;
    return .{ .family = 6, .scope_id = scope, .interface_id = scope, .bytes = parsed.bytes };
}

pub fn parseEndpoint(text: []const u8, default_port: u16) ?abi.NetworkEndpoint {
    var address = text;
    var port_text: ?[]const u8 = null;
    if (std.mem.startsWith(u8, text, "[")) {
        const end = std.mem.indexOfScalar(u8, text, ']') orelse return null;
        address = text[1..end];
        if (end + 1 < text.len) {
            if (text[end + 1] != ':') return null;
            port_text = text[end + 2 ..];
        }
    } else if (std.mem.indexOfScalar(u8, text, ':')) |at| {
        if (std.mem.indexOfScalar(u8, text, '.') != null and std.mem.indexOfScalarPos(u8, text, at + 1, ':') == null) {
            address = text[0..at];
            port_text = text[at + 1 ..];
        }
    }
    var port = default_port;
    if (port_text) |digits| {
        if (digits.len == 0) return null;
        for (digits) |byte| if (byte < '0' or byte > '9') return null;
        port = std.fmt.parseInt(u16, digits, 10) catch return null;
    }
    if (port == 0) return null;
    return .{ .address = parseAddress(address) orelse return null, .port = port };
}

pub fn addressText(buffer: []u8, address: abi.NetworkAddress) error{ Invalid, NoSpaceLeft }![]const u8 {
    if (!common.addressValid(address)) return error.Invalid;
    if (address.family == 4) return std.fmt.bufPrint(buffer, "{d}.{d}.{d}.{d}", .{ address.bytes[0], address.bytes[1], address.bytes[2], address.bytes[3] });
    const value: std.Io.net.Ip6Address.Unresolved = .{ .bytes = address.bytes, .interface_name = null };
    if (address.scope_id != 0) return std.fmt.bufPrint(buffer, "{f}%{d}", .{ value, address.scope_id });
    return std.fmt.bufPrint(buffer, "{f}", .{value});
}

/// Collect every pinned page privately, validate one result identity and
/// release the lease before publishing. The caller supplies one operation
/// budget including info, resolution, pagination and release.
pub fn resolveAll(client: *Client, name: []const u8, family: u32, server: abi.NetworkEndpoint, budget: *@import("rpc_budget.zig").Budget, answers: *[32]abi.NetworkResolveAnswer, count: *u32) i32 {
    const rpc = @import("rpc_budget.zig");
    if (name.len == 0 or name.len > 254 or family != 4 and family != 6) return abi.network_error_invalid;
    client.timeout_ticks = budget.remainingTicks() catch |err| return rpc.code(err);
    var info: abi.NetworkProviderInfo = .{};
    var rc = client.info(&info);
    if (rc != 0) return rc;
    const required = if (family == 4) abi.network_cap_dns_a else abi.network_cap_dns_aaaa;
    if (info.capabilities & required == 0) return abi.network_error_unsupported_family;
    var request: abi.NetworkResolveRequest = .{ .provider = info.provider, .family = family, .server = server, .name_len = @intCast(name.len), .capacity = @min(16, info.page_capacity) };
    @memcpy(request.name[0..name.len], name);
    var staged: [32]abi.NetworkResolveAnswer = undefined;
    var used: u32 = 0;
    var first: abi.NetworkResolvePage = .{};
    defer if (first.query != 0) {
        // A failed read never turns a lost mutation reply into a replay.
        if (budget.remainingTicks()) |ticks| {
            client.timeout_ticks = ticks;
            _ = client.release(first.provider, first.query);
        } else |_| {}
    };
    while (true) {
        client.timeout_ticks = budget.remainingTicks() catch |err| return rpc.code(err);
        if (request.query == 0) request.deadline = fromBudget(budget.deadline) catch |err| return common.code(err);
        var page: abi.NetworkResolvePage = .{};
        var batch: [16]abi.NetworkResolveAnswer = undefined;
        rc = client.resolve(request, &batch, &page);
        if (rc != 0) return rc;
        if (first.query == 0) first = page;
        if (page.query != first.query or page.provider != first.provider or page.total != first.total or page.expires_ns != first.expires_ns or used + page.count > staged.len) return abi.network_error_invalid;
        for (batch[0..page.count]) |answer| if (answer.address.family != family) return abi.network_error_invalid;
        @memcpy(staged[used..][0..page.count], batch[0..page.count]);
        used += page.count;
        if (page.flags == 0) break;
        request = .{ .provider = first.provider, .query = first.query, .family = 0, .cursor = page.next, .capacity = @min(16, info.page_capacity) };
    }
    if (used != first.total) return abi.network_error_invalid;
    client.timeout_ticks = budget.remainingTicks() catch |err| return rpc.code(err);
    const query = first.query;
    first.query = 0;
    rc = client.release(first.provider, query);
    if (rc != 0) return rc;
    _ = budget.remainingTicks() catch |err| return rpc.code(err);
    @memcpy(answers[0..used], staged[0..used]);
    count.* = used;
    return 0;
}

/// Copied normal R4DEV dispatch into an existing external protocol owner.
/// Neither a failed dispatch nor a malformed record changes caller output.
pub fn protocolRecord(dev: @import("r4dev.zig").Context, comptime Request: type, comptime Response: type, role: []const u8, op: u32, request: *const Request, out: *Response) i32 {
    var input: abi.ProtocolBuffer = .{ .data = @constCast(std.mem.asBytes(request).ptr), .len = @sizeOf(Request), .capacity = @sizeOf(Request) };
    var bytes: [@sizeOf(Response)]u8 = undefined;
    var output: abi.ProtocolBuffer = .{ .data = &bytes, .capacity = bytes.len };
    const rc = dev.protocolDispatch(role, op, &input, &output);
    if (rc != 0) return rc;
    if (output.len != bytes.len or output.data != @as(?*anyopaque, @ptrCast(&bytes)) or output.capacity != bytes.len or output.flags != 0 or output.reserved != 0) return abi.network_error_invalid;
    const value = common.record(Response, &bytes) catch return abi.network_error_invalid;
    out.* = value;
    return 0;
}

pub const Ipv6 = struct {
    dev: @import("r4dev.zig").Context,
    info: abi.Ipv6InterfaceInfo,

    pub fn open(dev: @import("r4dev.zig").Context, index: u32, out: *Ipv6) i32 {
        const request: abi.Ipv6InterfaceQuery = .{ .index = index };
        var info: abi.Ipv6InterfaceInfo = .{};
        const rc = protocolRecord(dev, abi.Ipv6InterfaceQuery, abi.Ipv6InterfaceInfo, "net.ipv6", abi.ipv6_op_info, &request, &info);
        if (rc != 0) return rc;
        const link = info.link;
        if (info.reserved != 0 or link.version != 1 or link.size != @sizeOf(abi.NetworkLinkInfo) or link.index != index or link.interface_id == 0 or link.generation == 0 or link.provider == 0 or link.reserved != 0) return abi.network_error_invalid;
        out.* = .{ .dev = dev, .info = info };
        return 0;
    }
    fn query(self: *const Ipv6, cursor: u32) abi.Ipv6InterfaceQuery {
        return .{ .index = self.info.link.index, .interface_id = self.info.link.interface_id, .provider = self.info.link.provider, .generation = self.info.link.generation, .cursor = cursor };
    }
    pub fn address(self: *const Ipv6, cursor: u32, out: *abi.Ipv6AddressInfo) i32 {
        const request = self.query(cursor);
        var value: abi.Ipv6AddressInfo = .{};
        const rc = protocolRecord(self.dev, abi.Ipv6InterfaceQuery, abi.Ipv6AddressInfo, "net.ipv6", abi.ipv6_op_address, &request, &value);
        if (rc != 0) return rc;
        if (value.provider != request.provider or value.generation != request.generation or value.address.interface_id != request.interface_id or !common.addressValid(value.address) or value.address.family != 6 or value.prefix_length > 128) return abi.network_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn route(self: *const Ipv6, cursor: u32, out: *abi.Ipv6RouteInfo) i32 {
        const request = self.query(cursor);
        var value: abi.Ipv6RouteInfo = .{};
        const rc = protocolRecord(self.dev, abi.Ipv6InterfaceQuery, abi.Ipv6RouteInfo, "net.ipv6", abi.ipv6_op_route, &request, &value);
        if (rc != 0) return rc;
        if (value.provider != request.provider or value.generation != request.generation or value.reserved != 0 or !common.addressValid(value.prefix) or !common.addressValid(value.gateway) or value.prefix.family != 6 or value.gateway.family != 6 or value.prefix_length > 128) return abi.network_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn packet(self: *const Ipv6, op: u32, request: *const abi.Ipv6Packet, out: *abi.Ipv6Packet) i32 {
        if (request.provider != self.info.link.provider or request.generation != self.info.link.generation or request.source.interface_id != self.info.link.interface_id) return abi.network_error_provider_changed;
        var value: abi.Ipv6Packet = .{};
        const rc = protocolRecord(self.dev, abi.Ipv6Packet, abi.Ipv6Packet, "net.ipv6", op, request, &value);
        if (rc != 0) return rc;
        if (value.provider != request.provider or value.generation != request.generation or value.next_header != request.next_header or value.bytes > value.payload.len or value.reserved != 0 or value.flags & ~@as(u32, abi.ipv6_packet_flag_fragmented) != 0 or !common.addressValid(value.source) or !common.addressValid(value.destination) or value.source.family != 6 or value.destination.family != 6 or value.source.interface_id != self.info.link.interface_id or value.destination.interface_id != self.info.link.interface_id) return abi.network_error_invalid;
        out.* = value;
        return 0;
    }
};

/// The DHCPv4 owner retains its existing private copied result contract.
/// Transport/clock failure remains an error, never a fabricated lease.
pub const Dhcp = struct {
    connection: @import("app_services.zig").ServiceConnection,
    pub fn open(sys: @import("r4sys.zig").Context, out: *Dhcp) i32 {
        const services: @import("app_services.zig").Services = .{ .sys = sys };
        return switch (services.open("DHCPSVC")) {
            .connection => |connection| blk: {
                out.* = .{ .connection = connection };
                break :blk 0;
            },
            .failure => |rc| rc,
        };
    }
    pub fn close(self: *Dhcp) i32 {
        return self.connection.close();
    }
    fn call(self: *Dhcp, comptime T: type, op: u16, request: []const u8, budget: *@import("rpc_budget.zig").Budget, out: *T) i32 {
        var bytes: [@sizeOf(T)]u8 = undefined;
        switch (self.connection.callBudget(op, request, &bytes, budget)) {
            .response => |response| {
                if (response.bytes != bytes.len or response.header.op != op or response.header.status != 0) return abi.network_error_invalid;
            },
            .timed_out => return abi.service_api_result_timeout,
            .remote_failure, .failure => |rc| return rc,
        }
        var value: T = undefined;
        @memcpy(std.mem.asBytes(&value), &bytes);
        const expected: T = .{};
        if (value.magic != expected.magic or value.version != expected.version) return abi.network_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn status(self: *Dhcp, budget: *@import("rpc_budget.zig").Budget, out: *abi.NetServiceDhcpStatus) i32 {
        return self.call(abi.NetServiceDhcpStatus, abi.net_service_op_dhcp_status_result, "", budget, out);
    }
    pub fn action(self: *Dhcp, op: u16, budget: *@import("rpc_budget.zig").Budget, out: *abi.NetServiceDhcpResult) i32 {
        const expected: u16 = switch (op) {
            abi.net_service_op_dhcp_acquire_result => abi.net_service_dhcp_action_acquire,
            abi.net_service_op_dhcp_renew_result => abi.net_service_dhcp_action_renew,
            abi.net_service_op_dhcp_release_result => abi.net_service_dhcp_action_release,
            else => return abi.network_error_invalid,
        };
        const ticks = budget.remainingTicks() catch |err| return @import("rpc_budget.zig").code(err);
        const end = std.math.add(u64, self.connection.sys.ticks(), ticks) catch return abi.network_error_invalid;
        if (end == std.math.maxInt(u64)) return abi.network_error_invalid;
        var bytes: [@import("service_deadline.zig").footer_size]u8 = undefined;
        const payload = @import("service_deadline.zig").append(&bytes, "", end) orelse return abi.network_error_invalid;
        var result: abi.NetServiceDhcpResult = .{};
        const rc = self.call(abi.NetServiceDhcpResult, op, payload, budget, &result);
        if (rc != 0) return rc;
        if (result.action != expected) return abi.network_error_invalid;
        out.* = result;
        return 0;
    }
};

test "network family decimal addresses explicit IPv6 scopes and endpoints" {
    try std.testing.expectEqualSlices(u8, &.{ 10, 0, 2, 53 }, &parseIpv4("010.000.002.053").?);
    try std.testing.expect(parseIpv4("256.0.0.1") == null);
    try std.testing.expect(parseAddress("fe80::1") == null);
    try std.testing.expect(parseAddress("fe80::1%eth0") == null);
    try std.testing.expect(parseAddress("fe80::1%0") == null);
    try std.testing.expect(parseAddress("fd00::1%2") == null);
    try std.testing.expect(parseAddress("::ffff:10.0.2.1") == null);
    const endpoint = parseEndpoint("[fe80::1%17]:5353", 53).?;
    try std.testing.expectEqual(@as(u32, 17), endpoint.address.scope_id);
    try std.testing.expectEqual(@as(u32, 17), endpoint.address.interface_id);
    try std.testing.expectEqual(@as(u16, 5353), endpoint.port);
    var buffer: [80]u8 = undefined;
    try std.testing.expectEqualStrings("fe80::1%17", try addressText(&buffer, endpoint.address));
    try std.testing.expectEqualStrings("fd00::123", try addressText(&buffer, parseAddress("fd00::123").?));
    try std.testing.expect(parseEndpoint("[fd00::1]:0", 53) == null);
}

test "network family copied protocol errors preserve output and actual interface identity" {
    const Peer = struct {
        var malformed = false;
        fn dispatch(_: [*]const u8, _: u32, _: u32, _: *const abi.ProtocolBuffer, out: *abi.ProtocolBuffer) callconv(.c) i32 {
            var value: abi.Ipv6InterfaceInfo = .{ .link = .{ .index = 0, .interface_id = 17, .provider = 31, .generation = 43 } };
            if (malformed) value.version = 99;
            const bytes: [*]u8 = @ptrCast(out.data.?);
            @memcpy(bytes[0..@sizeOf(@TypeOf(value))], std.mem.asBytes(&value));
            out.len = @sizeOf(@TypeOf(value));
            return 0;
        }
    };
    var table: platform.abi.R4XStartR4Dev2 = .{ .protocol_dispatch = @intFromPtr(&Peer.dispatch) };
    var sys_table: platform.abi.R4XStartR4Sys2 = .{};
    const imports = [_]platform.abi.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys_table) },
        .{ .group_id = 6, .resolved_version = 2, .table = @intFromPtr(&table) },
    };
    const raw: platform.abi.R4XStartContext2 = .{ .import_count = imports.len, .imports = @intFromPtr(&imports) };
    const context = try platform.Context.init(&raw);
    const dev: @import("r4dev.zig").Context = .{ .base = .{ .generation2 = &context } };
    var client: Ipv6 = undefined;
    try std.testing.expectEqual(@as(i32, 0), Ipv6.open(dev, 0, &client));
    try std.testing.expectEqual(@as(u32, 17), client.info.link.interface_id);
    const before = client;
    Peer.malformed = true;
    try std.testing.expectEqual(abi.network_error_invalid, Ipv6.open(dev, 0, &client));
    try std.testing.expectEqualDeep(before, client);
}

test "network family pagination keeps complete pinned identity and releases once after lost ACK" {
    const Peer = struct {
        var mode: u8 = 0;
        var pages: u32 = 0;
        var releases: u32 = 0;
        var opens: u32 = 0;
        var closes: u32 = 0;
        fn clock(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
            out.* = .{ .flags = abi.monotonic_clock_flag_valid, .source = 1, .generation = 9, .instant_ns = 1_000_000_000, .resolution_ns = 1, .event_requested_hz = 1000, .event_effective_hz = 1000 };
            return 1;
        }
        fn open(name: [*:0]const u8, out: *abi.ServiceInfo) callconv(.c) i32 {
            if (!std.mem.eql(u8, std.mem.span(name), "DNSSVC")) return abi.service_api_result_no_endpoint;
            opens += 1;
            out.* = .{ .handle = 1 };
            return 0;
        }
        fn close(_: u32) callconv(.c) i32 {
            closes += 1;
            return 0;
        }
        fn call(_: u32, op: u16, input: [*]const u8, length: u32, header: *abi.ServiceMessageHeader, output: [*]u8, _: u32, _: u64) callconv(.c) i32 {
            header.* = .{ .op = op };
            if (op == abi.network_op_info) {
                const info: abi.NetworkProviderInfo = .{ .provider = 13, .capabilities = abi.network_cap_dns_a | abi.network_cap_dns_aaaa, .max_answers = 32, .page_capacity = 16 };
                @memcpy(output[0..@sizeOf(@TypeOf(info))], std.mem.asBytes(&info));
                return @sizeOf(@TypeOf(info));
            }
            const request = common.record(abi.NetworkResolveRequest, input[0..length]) catch return abi.network_error_invalid;
            if (op == abi.network_op_release) {
                releases += 1;
                return if (mode == 2) abi.service_api_result_timeout else 0;
            }
            if (request.query != 0 and (request.family != 0 or request.deadline.kind != 0 or request.name_len != 0)) return abi.network_error_invalid;
            pages += 1;
            const page: abi.NetworkResolvePage = .{ .provider = 13, .query = 17, .expires_ns = if (mode == 1 and pages == 2) 9 else 30_000_000_000, .count = if (pages == 1) 16 else 4, .total = 20, .next = if (pages == 1) 16 else 20, .flags = if (pages == 1) abi.network_flag_more else 0 };
            @memcpy(output[0..@sizeOf(@TypeOf(page))], std.mem.asBytes(&page));
            for (0..page.count) |i| {
                const answer: abi.NetworkResolveAnswer = .{ .address = common.v4Endpoint(.{ 10, 0, 0, @intCast(request.cursor + i + 1) }, 0).address, .ttl_seconds = 60 };
                @memcpy(output[@sizeOf(@TypeOf(page)) + i * @sizeOf(@TypeOf(answer)) ..][0..@sizeOf(@TypeOf(answer))], std.mem.asBytes(&answer));
            }
            return @intCast(@sizeOf(@TypeOf(page)) + page.count * @sizeOf(abi.NetworkResolveAnswer));
        }
    };
    for (0..3) |mode| {
        Peer.mode = @intCast(mode);
        Peer.pages = 0;
        Peer.releases = 0;
        var client: Client = .{ .call = Peer.call, .close_call = Peer.close, .handle = 1, .service = .dns };
        var budget = try @import("rpc_budget.zig").Budget.fromTimeout(Peer.clock, .{ .kind = abi.timeout_kind_finite, .nanoseconds = 5_000_000_000 });
        var answers = [_]abi.NetworkResolveAnswer{.{}} ** 32;
        var count: u32 = 99;
        const rc = resolveAll(&client, "pages.r4os", 4, .{}, &budget, &answers, &count);
        try std.testing.expectEqual(@as(u32, 2), Peer.pages);
        try std.testing.expectEqual(@as(u32, 1), Peer.releases);
        if (mode == 0) {
            try std.testing.expectEqual(@as(i32, 0), rc);
            try std.testing.expectEqual(@as(u32, 20), count);
            try std.testing.expectEqual(@as(u8, 20), answers[19].address.bytes[3]);
        } else {
            try std.testing.expect(rc < 0);
            try std.testing.expectEqual(@as(u32, 99), count);
            try std.testing.expectEqualDeep([_]abi.NetworkResolveAnswer{.{}} ** 32, answers);
        }
        Peer.pages = 0;
        Peer.releases = 0;
        Peer.opens = 0;
        Peer.closes = 0;
        var table: platform.abi.R4XStartR4Sys2 = .{
            .monotonic_clock = @intFromPtr(&Peer.clock),
            .service_open = @intFromPtr(&Peer.open),
            .service_call = @intFromPtr(&Peer.call),
            .service_close = @intFromPtr(&Peer.close),
        };
        const imports = [_]platform.abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&table) }};
        const raw: platform.abi.R4XStartContext2 = .{ .import_count = imports.len, .imports = @intFromPtr(&imports) };
        const context = try platform.Context.init(&raw);
        const program = @import("program.zig").Context{ .generation2 = &context };
        var resolver = @import("app_network.zig").Resolver{ .network = .{
            .sys = @import("r4sys.zig").Context.fromProgram(program),
            .net = .{ .base = program },
        } };
        const answer = resolver.resolveA("pages.r4os", null, .{ .kind = abi.timeout_kind_finite, .nanoseconds = 5_000_000_000 });
        try std.testing.expectEqual(@as(u32, 2), Peer.pages);
        try std.testing.expectEqual(@as(u32, 1), Peer.releases);
        try std.testing.expectEqual(@as(u32, 1), Peer.opens);
        try std.testing.expectEqual(@as(u32, 1), Peer.closes);
        if (mode == 0) {
            try std.testing.expect(answer == .address);
            try std.testing.expectEqual([4]u8{ 10, 0, 0, 1 }, answer.address.octets);
            table.monotonic_clock = 0;
            const unavailable = resolver.resolveA("pages.r4os", null, .{ .kind = abi.timeout_kind_finite, .nanoseconds = 5_000_000_000 });
            try std.testing.expect(unavailable == .failure);
            try std.testing.expectEqual(@import("rpc_budget.zig").code(error.ClockUnavailable), unavailable.failure);
            try std.testing.expectEqual(@as(u32, 1), Peer.opens);
            try std.testing.expectEqual(@as(u32, 2), Peer.pages);
        } else {
            try std.testing.expect(answer != .address);
        }
    }
}

test "network family DHCP exact records and uncertain mutation remain unpublished without replay" {
    const Peer = struct {
        var calls: u32 = 0;
        var mode: u8 = 0;
        fn clock(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
            out.* = .{ .flags = abi.monotonic_clock_flag_valid, .source = 1, .generation = 9, .instant_ns = 1_000_000_000, .resolution_ns = 1, .event_requested_hz = 1000 };
            return 1;
        }
        fn ticks() callconv(.c) u64 {
            return 19;
        }
        fn open(_: [*:0]const u8, out: *abi.ServiceInfo) callconv(.c) i32 {
            out.* = .{ .handle = 7 };
            return 0;
        }
        fn close(_: u32) callconv(.c) i32 {
            return 0;
        }
        fn call(_: u32, op: u16, input: [*]const u8, length: u32, header: *abi.ServiceMessageHeader, output: [*]u8, _: u32, _: u64) callconv(.c) i32 {
            calls += 1;
            header.* = .{ .op = op };
            if (op == abi.net_service_op_dhcp_status_result) {
                const value: abi.NetServiceDhcpStatus = .{ .runtime_state = 6, .flags = abi.net_service_dhcp_flag_bound, .offered_ip = .{ 10, 0, 2, 15 } };
                @memcpy(output[0..@sizeOf(@TypeOf(value))], std.mem.asBytes(&value));
                return @sizeOf(@TypeOf(value));
            }
            const footer = @import("service_deadline.zig").split(input[0..length]);
            if (footer.payload.len != 0 or footer.deadline_tick != 5019) return abi.network_error_invalid;
            if (mode == 1) return abi.service_api_result_timeout;
            const value: abi.NetServiceDhcpResult = .{ .action = abi.net_service_dhcp_action_release, .result = abi.net_tx_ok };
            @memcpy(output[0..@sizeOf(@TypeOf(value))], std.mem.asBytes(&value));
            return @sizeOf(@TypeOf(value));
        }
    };
    var table: platform.abi.R4XStartR4Sys2 = .{ .monotonic_clock = @intFromPtr(&Peer.clock), .ticks = @intFromPtr(&Peer.ticks), .service_open = @intFromPtr(&Peer.open), .service_call = @intFromPtr(&Peer.call), .service_close = @intFromPtr(&Peer.close) };
    const imports = [_]platform.abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&table) }};
    const raw: platform.abi.R4XStartContext2 = .{ .import_count = imports.len, .imports = @intFromPtr(&imports) };
    const context = try platform.Context.init(&raw);
    const sys = @import("r4sys.zig").Context.fromProgram(.{ .generation2 = &context });
    var client: Dhcp = undefined;
    try std.testing.expectEqual(@as(i32, 0), Dhcp.open(sys, &client));
    var budget = try @import("rpc_budget.zig").Budget.fromTimeout(Peer.clock, .{ .kind = abi.timeout_kind_finite, .nanoseconds = 5_000_000_000 });
    var status: abi.NetServiceDhcpStatus = .{};
    try std.testing.expectEqual(@as(i32, 0), client.status(&budget, &status));
    try std.testing.expectEqual(@as(u16, 6), status.runtime_state);
    var result: abi.NetServiceDhcpResult = .{};
    try std.testing.expectEqual(@as(i32, 0), client.action(abi.net_service_op_dhcp_release_result, &budget, &result));
    try std.testing.expectEqual(abi.net_tx_ok, result.result);
    Peer.mode = 1;
    const before = result;
    Peer.calls = 0;
    try std.testing.expect(client.action(abi.net_service_op_dhcp_release_result, &budget, &result) < 0);
    try std.testing.expectEqual(@as(u32, 1), Peer.calls);
    try std.testing.expectEqualDeep(before, result);
    try std.testing.expectEqual(@as(i32, 0), client.close());
}
