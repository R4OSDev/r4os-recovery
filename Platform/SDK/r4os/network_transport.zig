//! Provider-only copied R4P transport adapter. No socket, route or packet state.
const std = @import("std");
pub const a = @import("r4os_contract").abi;
const technical = @import("technical2.zig");
pub const common = @import("network_common.zig");
pub const Error = common.Error;

pub fn status(code: i32) Error!void {
    if (code == 0) return;
    return switch (code) {
        a.network_error_invalid => error.Invalid,
        a.network_error_unsupported_family => error.UnsupportedFamily,
        a.network_error_unsupported_policy => error.UnsupportedPolicy,
        a.network_error_unsupported_scope => error.UnsupportedScope,
        a.network_error_provider_changed => error.ProviderChanged,
        a.network_error_bad_socket => error.BadSocket,
        a.network_error_capacity => error.Capacity,
        a.network_error_clock_changed => error.ClockChanged,
        a.network_error_timeout => error.Timeout,
        a.network_error_would_block => error.WouldBlock,
        a.network_error_reset => error.Reset,
        a.network_error_not_found => error.NotFound,
        a.network_error_truncated_dns => error.TruncatedDns,
        a.network_error_packet_too_big => error.PacketTooBig,
        else => error.Backend,
    };
}
pub fn put(comptime T: type, value: *const T, bytes: []const u8, output: *a.ProtocolBuffer) Error!void {
    const length = @sizeOf(T) + bytes.len;
    if (output.data == null or output.capacity < length) return error.Capacity;
    const target: [*]u8 = @ptrCast(output.data.?);
    @memcpy(target[0..@sizeOf(T)], std.mem.asBytes(value));
    @memcpy(target[@sizeOf(T)..length], bytes);
    output.len = @intCast(length);
}
pub fn zero(address: a.NetworkAddress) bool {
    return std.mem.allEqual(u8, &address.bytes, 0);
}
pub fn sameAddress(x: a.NetworkAddress, y: a.NetworkAddress) bool {
    return x.family == y.family and x.scope_id == y.scope_id and x.interface_id == y.interface_id and std.mem.eql(u8, &x.bytes, &y.bytes);
}
pub fn sameProcess(x: a.ProgramProcessHandle, y: a.ProgramProcessHandle) bool {
    return x.instance_id == y.instance_id and x.generation == y.generation and x.reserved == 0 and y.reserved == 0;
}
pub fn read16(bytes: []const u8, index: usize) u16 {
    return std.mem.readInt(u16, bytes[index..][0..2], .big);
}
pub fn write16(bytes: []u8, index: usize, value: u16) void {
    std.mem.writeInt(u16, bytes[index..][0..2], value, .big);
}

pub fn providerInfo(dev: @import("r4dev.zig").Context, role: []const u8) Error!a.NetworkProviderInfo {
    var input: a.ProtocolBuffer = .{};
    var info: a.NetworkProviderInfo = .{};
    var output: a.ProtocolBuffer = .{ .data = &info, .capacity = @sizeOf(a.NetworkProviderInfo) };
    try status(dev.protocolDispatch(role, a.network_op_info, &input, &output));
    if (output.len != @sizeOf(a.NetworkProviderInfo) or info.version != 1 or info.size != @sizeOf(a.NetworkProviderInfo) or info.provider == 0 or info.reserved != 0 or info.capabilities & ~@as(u64, 4095) != 0 or info.max_send > 3968 or info.max_recv > 4008 or info.max_answers != 0 or info.page_capacity != 0) return error.Backend;
    return info;
}
pub const Reply = struct { result: a.NetworkSocketResult, data: []const u8 };
/// Explicit provider broker. The service retains the response buffer, exact
/// client identity and front handle; this adapter owns no transport resource.
pub fn broker(sys: @import("r4sys.zig").Context, dev: @import("r4dev.zig").Context, role: []const u8, module_provider: u64, client: a.ProgramProcessHandle, op: u32, request_value: a.NetworkSocketRequest, data: []const u8, response: []u8) Error!Reply {
    const raw_instance = if (sys.base.generation2) |context| context.raw.instance_id else if (sys.base.bundle) |bundle| bundle.raw.instance_id else return error.Backend;
    const id = std.math.cast(u32, raw_instance) orelse return error.Backend;
    const process = try common.owner(sys, id);
    var request_copy = request_value;
    request_copy.provider = process.generation;
    const value: a.NetworkTransportRequest = .{ .provider = module_provider, .broker = process, .owner = client, .request = request_copy };
    if (data.len > 3968 or response.len < @sizeOf(a.NetworkSocketResult)) return error.Capacity;
    var bytes: [@sizeOf(a.NetworkTransportRequest) + 3968]u8 = undefined;
    @memcpy(bytes[0..@sizeOf(a.NetworkTransportRequest)], std.mem.asBytes(&value));
    @memcpy(bytes[@sizeOf(a.NetworkTransportRequest)..][0..data.len], data);
    var input: a.ProtocolBuffer = .{ .data = &bytes, .len = @intCast(@sizeOf(a.NetworkTransportRequest) + data.len), .capacity = bytes.len };
    var output: a.ProtocolBuffer = .{ .data = response.ptr, .capacity = @intCast(response.len) };
    try status(dev.protocolDispatch(role, op, &input, &output));
    if (output.len < @sizeOf(a.NetworkSocketResult) or output.len > response.len) return error.Backend;
    const value_out = try common.record(a.NetworkSocketResult, response[0..@sizeOf(a.NetworkSocketResult)]);
    const no_endpoint = std.mem.allEqual(u8, std.mem.asBytes(&value_out.endpoint), 0);
    if (value_out.provider != module_provider or !common.endpointValid(value_out.endpoint) and !(op == a.network_transport_op_tick and no_endpoint) or value_out.state < 1 or value_out.state > 6 or value_out.flags & ~@as(u32, a.network_flag_truncated) != 0) return error.Backend;
    const body = response[@sizeOf(a.NetworkSocketResult)..output.len];
    if (op == a.network_op_recv or op == a.network_op_read) {
        if (body.len != value_out.bytes or value_out.bytes > request_value.bytes or value_out.original_bytes < value_out.bytes) return error.Backend;
    } else if (body.len != 0 or value_out.bytes > request_value.bytes) return error.Backend;
    return .{ .result = value_out, .data = body };
}

pub const Runtime = struct {
    view: technical.Protocol,
    pub fn init(raw: *const a.ProtocolApi2) Error!Runtime {
        const view = technical.Protocol.init(raw) orelse return error.Backend;
        if (view.function("protocol_dispatch") == null or view.function("link_io") == null or view.function("process_status") == null or view.function("entropy_fill") == null) return error.UnsupportedPolicy;
        return .{ .view = view };
    }
    pub fn identity(self: Runtime) Error!a.NetworkLinkInfo {
        var info: a.NetworkLinkInfo = .{};
        const request: a.NetworkLinkRequest = .{ .op = a.network_link_op_identity };
        try status(self.view.function("link_io").?(&request, &info));
        if (info.version != 1 or info.size != @sizeOf(a.NetworkLinkInfo) or info.provider == 0 or info.reserved != 0) return error.Backend;
        return info;
    }
    pub fn monotonicClock(self: Runtime, out: *a.MonotonicClockInfo) i32 {
        const info = self.identity() catch return 0;
        out.* = info.clock;
        return 1;
    }
    pub fn programHandleStatus(self: Runtime, handle: *const a.ProgramProcessHandle, out: *a.ProgramInstanceInfo) i32 {
        return self.view.function("process_status").?(handle, out);
    }
    pub fn gone(self: Runtime, process: a.ProgramProcessHandle) bool {
        return common.ownerGone(self, process);
    }
    pub fn random(self: Runtime, bytes: []u8) Error!void {
        if (self.view.function("entropy_fill").?(bytes.ptr, @intCast(bytes.len)) != bytes.len) return error.Backend;
    }
    pub fn rpc(self: Runtime, comptime Request: type, comptime Response: type, role: []const u8, op: u32, request: Request) Error!Response {
        var input: a.ProtocolBuffer = .{ .data = @constCast(&request), .len = @sizeOf(Request), .capacity = @sizeOf(Request) };
        var reply: Response = undefined;
        var output: a.ProtocolBuffer = .{ .data = &reply, .capacity = @sizeOf(Response) };
        try status(self.view.function("protocol_dispatch").?(role.ptr, @intCast(role.len), op, &input, &output));
        if (output.len != @sizeOf(Response) or reply.version != 1 or reply.size != @sizeOf(Response)) return error.Backend;
        return reply;
    }
    pub fn interface(self: Runtime, id: u32) Error!a.Ipv6InterfaceInfo {
        var index: u32 = 0;
        while (index < 8) : (index += 1) {
            const info = self.rpc(a.Ipv6InterfaceQuery, a.Ipv6InterfaceInfo, "net.ipv6", a.ipv6_op_info, .{ .index = index }) catch |err| {
                if (err == error.NotFound) continue;
                return err;
            };
            if (id != 0 and info.link.interface_id != id) continue;
            if (info.link.interface_id == 0 or info.link.generation == 0 or info.link.provider == 0 or info.max_packet < 1240 or info.capabilities == 0) {
                if (id != 0) return error.UnsupportedPolicy;
                continue;
            }
            return info;
        }
        return error.NotFound;
    }
    pub fn packet(self: Runtime, info: a.Ipv6InterfaceInfo, next: u32, deadline: a.NetworkDeadline) a.Ipv6Packet {
        _ = self;
        return .{ .provider = info.link.provider, .generation = info.link.generation, .next_header = next, .source = .{ .family = 6, .interface_id = info.link.interface_id }, .destination = .{ .family = 6, .interface_id = info.link.interface_id }, .deadline = deadline };
    }
    pub fn prepare(self: Runtime, source: a.NetworkAddress, destination: a.NetworkAddress, next: u32, deadline: a.NetworkDeadline) Error!a.Ipv6Packet {
        if (!common.addressValid(source) or !common.addressValid(destination)) return error.Invalid;
        if (source.family != 6 or destination.family != 6) return error.UnsupportedFamily;
        const mapped_prefix: [12]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff };
        if (std.mem.eql(u8, source.bytes[0..12], &mapped_prefix) or std.mem.eql(u8, destination.bytes[0..12], &mapped_prefix)) return error.UnsupportedPolicy;
        if (zero(destination) or destination.bytes[0] == 0xff) return error.UnsupportedPolicy;
        if (source.interface_id != 0 and destination.interface_id != 0 and source.interface_id != destination.interface_id) return error.UnsupportedScope;
        const id = if (source.interface_id != 0) source.interface_id else destination.interface_id;
        var index: u32 = 0;
        var last: Error = error.NotFound;
        while (index < 8) : (index += 1) {
            const info = self.rpc(a.Ipv6InterfaceQuery, a.Ipv6InterfaceInfo, "net.ipv6", a.ipv6_op_info, .{ .index = index }) catch |err| {
                if (err == error.NotFound) continue;
                return err;
            };
            if (id != 0 and id != info.link.interface_id) continue;
            var request = self.packet(info, next, deadline);
            request.source = source;
            request.destination = destination;
            request.source.interface_id = info.link.interface_id;
            request.destination.interface_id = info.link.interface_id;
            const result = self.rpc(a.Ipv6Packet, a.Ipv6Packet, "net.ipv6", a.ipv6_op_prepare, request) catch |err| {
                if (id != 0 or err != error.NotFound and err != error.UnsupportedPolicy) return err;
                last = err;
                continue;
            };
            return result;
        }
        return last;
    }
    pub fn checksum(self: Runtime, packet_value: *a.Ipv6Packet, offset: usize) Error!void {
        const length: usize = packet_value.bytes;
        if (length > packet_value.payload.len or offset + 2 > length) return error.Invalid;
        write16(&packet_value.payload, offset, 0);
        var request: a.Icmpv6Message = .{ .source = packet_value.source.bytes, .destination = packet_value.destination.bytes, .next_header = packet_value.next_header, .bytes = @intCast(length) };
        @memcpy(request.payload[0..length], packet_value.payload[0..length]);
        const reply = try self.rpc(a.Icmpv6Message, a.Icmpv6Message, "net.icmpv6", a.icmpv6_op_checksum, request);
        write16(&packet_value.payload, offset, if (reply.checksum == 0) 0xffff else @intCast(reply.checksum));
    }
    pub fn send(self: Runtime, value: a.Ipv6Packet) Error!void {
        _ = try self.rpc(a.Ipv6Packet, a.Ipv6Packet, "net.ipv6", a.ipv6_op_send, value);
    }
    pub fn receive(self: Runtime, info: a.Ipv6InterfaceInfo, next: u32) Error!a.Ipv6Packet {
        return self.rpc(a.Ipv6Packet, a.Ipv6Packet, "net.ipv6", a.ipv6_op_receive, self.packet(info, next, .{}));
    }
    pub fn decodeRequest(self: Runtime, input: *const a.ProtocolBuffer, output: *a.ProtocolBuffer) Error!a.NetworkTransportRequest {
        if (input.flags != 0 or input.reserved != 0 or input.len > input.capacity or input.len < @sizeOf(a.NetworkTransportRequest) or input.data == null or output.flags != 0 or output.reserved != 0) return error.Invalid;
        const bytes: [*]const u8 = @ptrCast(input.data.?);
        const value = try common.record(a.NetworkTransportRequest, bytes[0..@sizeOf(a.NetworkTransportRequest)]);
        const req = value.request;
        if (req.version != 1 or req.size != @sizeOf(a.NetworkSocketRequest) or !common.endpointValid(req.endpoint) and !std.mem.allEqual(u8, std.mem.asBytes(&req.endpoint), 0)) return error.Invalid;
        if (value.provider != (try self.identity()).provider) return error.ProviderChanged;
        if (value.broker.reserved != 0 or value.owner.reserved != 0 or value.broker.instance_id == 0 or value.owner.instance_id == 0 or value.owner.generation == 0 or value.broker.generation == 0 or req.provider != value.broker.generation) return error.Invalid;
        if (self.gone(value.broker)) return error.BadSocket;
        try common.checkAttempt(self, req.deadline);
        return value;
    }
};
