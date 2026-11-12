const std = @import("std");
const abi = @import("r4os_contract").abi;
const storage = @import("app_storage.zig");
const network = @import("app_network.zig");
const r4sys = @import("r4sys.zig");

pub const registration_port: u16 = 4021;
pub const default_ip = "138.201.253.143";

pub const Component = enum {
    app_center,
    updates,
    benchmarks,
};

const Specification = struct {
    path: []const u8,
    default_port: u32,
};

fn specification(component: Component) Specification {
    return switch (component) {
        .app_center => .{ .path = "SYSTEM\\Network\\R4OSServer\\AppCenter", .default_port = 4022 },
        .updates => .{ .path = "SYSTEM\\Network\\R4OSServer\\Updates", .default_port = 4023 },
        .benchmarks => .{ .path = "SYSTEM\\Network\\R4OSServer\\Benchmarks", .default_port = 4024 },
    };
}

pub const Target = struct {
    ip: network.Ipv4Address,
    ip_text: [15]u8,
    ip_len: u8,
    port: u16,

    pub fn host(self: *const Target) []const u8 {
        return self.ip_text[0..self.ip_len];
    }
};

pub const Error = error{
    RegistryUnavailable,
    RegistryReadFailed,
    RegistryWriteFailed,
    TargetMissing,
    InvalidIp,
    InvalidPort,
};

/// Adds only absent values in one registry transaction. Existing values,
/// including malformed values, are never replaced by defaults.
pub fn ensureDefaults(ctx: *const r4sys.Context) Error!u8 {
    const registry = storage.Registry{ .sys = ctx.* };
    if (!registry.available() or !registry.batchAvailable()) return error.RegistryUnavailable;
    var operations: [6]abi.RegistryBatchOperation = undefined;
    var blob: [512]u8 = undefined;
    var batch = storage.RegistryBatchBuilder.init(&operations, &blob);
    inline for (.{ Component.app_center, .updates, .benchmarks }) |component| {
        const spec = specification(component);
        const key = storage.RegistryPath.parse(spec.path) catch unreachable;
        var value: [64]u8 = undefined;
        switch (registry.get(&key, "ServerIP", &value)) {
            .missing => batch.setString(&key, "ServerIP", default_ip) catch return error.RegistryWriteFailed,
            .failure => |raw| if (raw != abi.registry_api_result_buffer_too_small) return error.RegistryReadFailed,
            .value => {},
        }
        switch (registry.get(&key, "Port", &value)) {
            .missing => batch.setU32(&key, "Port", spec.default_port) catch return error.RegistryWriteFailed,
            .failure => |raw| if (raw != abi.registry_api_result_buffer_too_small) return error.RegistryReadFailed,
            .value => {},
        }
    }
    if (batch.operation_count == 0) return 0;
    if (!registry.applyBatch(&batch).committed()) return error.RegistryWriteFailed;
    return @intCast(batch.operation_count);
}

/// Always rereads the registry, so a changed target takes effect on the next
/// request. A malformed or absent value never falls back to another server.
pub fn read(ctx: *const r4sys.Context, component: Component) Error!Target {
    const registry = storage.Registry{ .sys = ctx.* };
    if (!registry.available()) return error.RegistryUnavailable;
    const spec = specification(component);
    const key = storage.RegistryPath.parse(spec.path) catch unreachable;
    var ip_bytes: [64]u8 = undefined;
    const ip_value = switch (registry.get(&key, "ServerIP", &ip_bytes)) {
        .value => |value| value,
        .missing => return error.TargetMissing,
        .failure => return error.RegistryReadFailed,
    };
    if (ip_value.info.value_type != abi.registry_value_type_string or
        ip_value.bytes.len == 0 or ip_value.bytes.len > 15) return error.InvalidIp;
    const parsed_ip = network.Ipv4Address.parseCanonical(ip_value.bytes) orelse return error.InvalidIp;

    var port_bytes: [4]u8 = undefined;
    const port_value = switch (registry.get(&key, "Port", &port_bytes)) {
        .value => |value| value,
        .missing => return error.TargetMissing,
        .failure => return error.RegistryReadFailed,
    };
    const port = port_value.asU32() orelse return error.InvalidPort;
    if (port == 0 or port > 65535) return error.InvalidPort;

    var target = Target{
        .ip = parsed_ip,
        .ip_text = undefined,
        .ip_len = @intCast(ip_value.bytes.len),
        .port = @intCast(port),
    };
    @memcpy(target.ip_text[0..ip_value.bytes.len], ip_value.bytes);
    return target;
}

test "server targets accept canonical IPv4 and reject ambiguous addresses" {
    const address = network.Ipv4Address.parseCanonical("138.201.253.143") orelse unreachable;
    try std.testing.expectEqualSlices(u8, &.{ 138, 201, 253, 143 }, &address.octets);
    try std.testing.expect(network.Ipv4Address.parseCanonical("138.201.253.256") == null);
    try std.testing.expect(network.Ipv4Address.parseCanonical("138.201.253.0143") == null);
    try std.testing.expect(network.Ipv4Address.parseCanonical("138.201.253.143/24") == null);
}
