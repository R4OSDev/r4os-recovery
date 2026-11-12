//! Shared copied network records and checked provider budgets. No transport state.
const std = @import("std");
pub const abi = @import("r4os_contract").abi;
const checked = @import("time_budget.zig");
pub const Error = error{ Invalid, UnsupportedFamily, UnsupportedPolicy, UnsupportedScope, ProviderChanged, BadSocket, Capacity, ClockChanged, Timeout, WouldBlock, Reset, Backend, NotFound, TruncatedDns, PacketTooBig };
pub fn code(err: Error) i32 {
    return switch (err) {
        error.Invalid => abi.network_error_invalid,
        error.UnsupportedFamily => abi.network_error_unsupported_family,
        error.UnsupportedPolicy => abi.network_error_unsupported_policy,
        error.UnsupportedScope => abi.network_error_unsupported_scope,
        error.ProviderChanged => abi.network_error_provider_changed,
        error.BadSocket => abi.network_error_bad_socket,
        error.Capacity => abi.network_error_capacity,
        error.ClockChanged => abi.network_error_clock_changed,
        error.Timeout => abi.network_error_timeout,
        error.WouldBlock => abi.network_error_would_block,
        error.Reset => abi.network_error_reset,
        error.Backend => abi.network_error_backend,
        error.NotFound => abi.network_error_not_found,
        error.TruncatedDns => abi.network_error_truncated_dns,
        error.PacketTooBig => abi.network_error_packet_too_big,
    };
}
pub fn record(comptime T: type, bytes: []const u8) Error!T {
    if (bytes.len != @sizeOf(T)) return error.Invalid;
    var value: T = undefined;
    @memcpy(std.mem.asBytes(&value), bytes);
    if (value.version != 1 or value.size != @sizeOf(T)) return error.Invalid;
    return value;
}
pub fn addressValid(value: abi.NetworkAddress) bool {
    return value.reserved0 == 0 and value.reserved1 == 0 and
        (value.family == 6 or value.family == 4 and std.mem.allEqual(u8, value.bytes[4..], 0));
}
pub fn endpointValid(value: abi.NetworkEndpoint) bool {
    return value.reserved == 0 and value.flags == 0 and addressValid(value.address);
}
pub fn ipv4(value: abi.NetworkEndpoint, zero_port: bool) Error![4]u8 {
    if (!endpointValid(value)) return error.Invalid;
    if (value.address.family != 4) return error.UnsupportedFamily;
    if (value.address.scope_id != 0 or value.address.interface_id != 0) return error.UnsupportedScope;
    if (!zero_port and value.port == 0) return error.Invalid;
    return value.address.bytes[0..4].*;
}
pub fn v4Endpoint(bytes: [4]u8, port: u16) abi.NetworkEndpoint {
    var value: abi.NetworkEndpoint = .{ .address = .{ .family = 4 }, .port = port };
    @memcpy(value.address.bytes[0..4], &bytes);
    return value;
}
pub fn policy(flags: u32) Error!void {
    if (flags & ~@as(u32, 7) != 0) return error.Invalid;
    if (flags != 0) return error.UnsupportedPolicy;
}
pub fn sample(sys: anytype) Error!checked.ClockSample {
    var info: abi.MonotonicClockInfo = .{};
    if (sys.monotonicClock(&info) <= 0) return error.ClockChanged;
    return checked.ClockSample.fromInfo(info) catch error.ClockChanged;
}
pub fn provider(sys: anytype) Error!u64 {
    const raw_instance = if (sys.base.generation2) |context| context.raw.instance_id else if (sys.base.bundle) |bundle| bundle.raw.instance_id else return error.Backend;
    const instance = std.math.cast(u32, raw_instance) orelse return error.Backend;
    var process: abi.ProgramProcessHandle = .{};
    if (instance == 0 or sys.programOpenHandle(instance, &process) != 0 or process.instance_id != instance or process.reserved != 0 or process.generation == 0) return error.Backend;
    return process.generation;
}
pub fn owner(sys: anytype, id: u32) Error!abi.ProgramProcessHandle {
    if (id == 0) return error.BadSocket;
    var process: abi.ProgramProcessHandle = .{};
    const opened = sys.programOpenHandle(id, &process);
    if (opened != 0) return if (opened == abi.program_handle_error_not_found or opened == abi.program_handle_error_stale) error.BadSocket else error.Backend;
    var info: abi.ProgramInstanceInfo = .{};
    const rc = sys.programHandleStatus(&process, &info);
    if (rc != 0) return if (rc == abi.program_handle_error_not_found or rc == abi.program_handle_error_stale) error.BadSocket else error.Backend;
    if (info.state == @intFromEnum(abi.ProgramInstanceState.done)) return error.BadSocket;
    return process;
}
pub fn ownerAlive(sys: anytype, process: abi.ProgramProcessHandle) bool {
    if (process.instance_id == 0 or process.generation == 0 or process.reserved != 0) return false;
    var info: abi.ProgramInstanceInfo = .{};
    return sys.programHandleStatus(&process, &info) == 0 and info.state != @intFromEnum(abi.ProgramInstanceState.done);
}
pub fn ownerGone(sys: anytype, process: abi.ProgramProcessHandle) bool {
    if (process.instance_id == 0 or process.generation == 0 or process.reserved != 0) return false;
    var info: abi.ProgramInstanceInfo = .{};
    const rc = sys.programHandleStatus(&process, &info);
    if (rc == 0) return info.state == @intFromEnum(abi.ProgramInstanceState.done);
    // Busy/unavailable is not an empty owner. Only exact missing/stale identity
    // or a real terminal state admits automatic resource retirement.
    return rc == abi.program_handle_error_not_found or rc == abi.program_handle_error_stale;
}
pub fn deadline(now: checked.ClockSample, timeout: abi.R4Timeout) Error!abi.NetworkDeadline {
    const budget = checked.DeadlineBudget.init(now, timeout) catch return error.Invalid;
    return fromBudget(budget);
}
pub fn fromBudget(budget: checked.DeadlineBudget) Error!abi.NetworkDeadline {
    if (budget.kind > 2 or budget.reserved != 0 or budget.identity.source == 0 or budget.identity.generation == 0 or
        budget.kind != 2 and budget.deadline_ns < budget.last_ns or budget.kind == 2 and budget.deadline_ns != 0) return error.Invalid;
    return .{ .kind = budget.kind, .absolute_ns = budget.deadline_ns, .last_ns = budget.last_ns, .clock_source = budget.identity.source, .clock_generation = budget.identity.generation, .event_backend = budget.identity.event_backend, .tick_hz = budget.identity.tick_hz };
}
pub fn remaining(sys: anytype, value: abi.NetworkDeadline) Error!checked.Value {
    if (value.version != 1 or value.size != @sizeOf(abi.NetworkDeadline) or value.kind > 2 or value.reserved0 != 0) return error.Invalid;
    if (value.kind == 0 and value.absolute_ns == 0 and value.last_ns == 0 and value.clock_source == 0 and value.clock_generation == 0 and value.event_backend == 0 and value.tick_hz == 0) return .{};
    if (value.kind == 2 and value.absolute_ns != 0 or value.kind != 2 and value.absolute_ns < value.last_ns) return error.Invalid;
    var budget: checked.DeadlineBudget = .{ .kind = value.kind, .deadline_ns = value.absolute_ns, .last_ns = value.last_ns, .identity = .{ .source = value.clock_source, .generation = value.clock_generation, .event_backend = value.event_backend, .tick_hz = value.tick_hz } };
    return budget.remaining(try sample(sys)) catch error.ClockChanged;
}
pub fn tickDeadline(sys: anytype, value: abi.NetworkDeadline) Error!?u64 {
    const left = try remaining(sys, value);
    if (left.kind == 2) return null;
    if (left.kind == 0) return if (value.kind == 0) error.WouldBlock else error.Timeout;
    const ticks = checked.scaleCeil(left.value, value.tick_hz, abi.nanoseconds_per_second) catch return error.Invalid;
    if (value.tick_hz == 0) return error.ClockChanged;
    return std.math.add(u64, sys.ticks(), ticks) catch error.Invalid;
}
pub fn checkAttempt(sys: anytype, value: abi.NetworkDeadline) Error!void {
    const left = try remaining(sys, value);
    if (value.kind == 1 and left.kind == 0) return error.Timeout;
}

// Provider-only optional NIPC handshake. Public managed-service Info requires
// its real process generation; the private kernel adapter deliberately has0.
pub fn backendInfo(net: anytype, channel: u32) ?abi.NetworkProviderInfo {
    var response: [abi.ipc_max_message_size]u8 = undefined;
    const got = net.netServiceRequest(channel, abi.network_op_info, 0x314e4649, "", &response);
    if (got <= 0 or got > response.len) return null;
    var status: i32 = 0;
    const payload = net.netServicePayload(response[0..@intCast(got)], &status) orelse return null;
    if (status != abi.net_service_result_ok) return null;
    const info = record(abi.NetworkProviderInfo, payload) catch return null;
    if (info.provider != 0 or info.reserved != 0 or info.capabilities & ~@as(u64, 4095) != 0 or info.max_send > 3968 or info.max_recv > 4008 or info.max_answers != 0 or info.page_capacity != 0 or info.interface_id != 0) return null;
    return info;
}
