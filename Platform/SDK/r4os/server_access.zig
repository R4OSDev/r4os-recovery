const std = @import("std");
const abi = @import("r4os_contract").abi;
const services_api = @import("app_services.zig");
const server_targets = @import("server_targets.zig");
const time_contract = @import("time_contract.zig");

pub const service_name: [*:0]const u8 = "R4SRV";
pub const op_ensure: u16 = 1;
const default_timeout = time_contract.timeoutFinite(time_contract.durationFromNanoseconds(15_000_000_000));

pub const Code = enum(i32) {
    ok = 0,
    bad_request = 1,
    profile = 2,
    target = 3,
    network = 4,
    credentials = 5,
    transport_unavailable = 6,
    invalid_secret = 7,
    invalid_reply = 8,
    transport = 9,
    bootstrap = 10,
    credentials_write = 11,
};

/// A forced retry is conditional on the generation observed by the caller.
/// Concurrent readers of one rejected generation therefore share one retry.
pub const EnsureRequest = extern struct {
    component: u8 = 0,
    force: u8 = 0,
    reserved: u16 = 0,
    observed_generation: u32 = 0,
};

pub const EnsureResponse = extern struct {
    code: i32 = @intFromEnum(Code.bad_request),
    detail: u16 = 0,
    profile: u8 = 0,
    attempted: u8 = 0,
    generation: u32 = 0,
    target_ip: [4]u8 = .{0} ** 4,
    port: u16 = 0,
    reserved2: u16 = 0,
};

pub const Call = union(enum) {
    response: EnsureResponse,
    unavailable: i32,
    timed_out,
    malformed,
};

pub const Client = struct {
    services: services_api.Services,

    pub fn ensure(self: *const Client, component: server_targets.Component) Call {
        return self.ensureBounded(component, null, default_timeout);
    }

    /// Use only after a definitive registration_required response to an
    /// idempotent read. Do not use for 403, 429, or an uncertain PUT.
    pub fn retryAfterRegistrationRequired(self: *const Client, component: server_targets.Component, generation: u32) Call {
        return self.ensureBounded(component, generation, default_timeout);
    }

    /// A generation selects the same conditional retry as the default API.
    pub fn ensureBounded(self: *const Client, component: server_targets.Component, generation: ?u32, timeout: time_contract.Timeout) Call {
        const request: EnsureRequest = .{ .component = @intFromEnum(component), .force = @intFromBool(generation != null), .observed_generation = generation orelse 0 };
        var connection = switch (self.services.open(service_name)) {
            .connection => |value| value,
            .failure => |raw| return .{ .unavailable = raw },
        };
        defer _ = connection.close();
        var response: EnsureResponse = .{};
        return switch (connection.call(op_ensure, std.mem.asBytes(&request), std.mem.asBytes(&response), timeout)) {
            .response => |received| if (received.bytes == @sizeOf(EnsureResponse)) .{ .response = response } else .malformed,
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .unavailable = raw },
            .failure => |raw| .{ .unavailable = raw },
        };
    }
};

comptime {
    std.debug.assert(@sizeOf(EnsureRequest) == 8);
    std.debug.assert(@sizeOf(EnsureResponse) == 20);
    std.debug.assert(@sizeOf(EnsureResponse) <= abi.service_api_max_payload);
}
