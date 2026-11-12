//! Typed external policy client. Each call closes its ordinary service handle.
//! An accepted receipt is not a claim that hardware applied a profile; inspect
//! actual masks/state/errors. Timeouts never trigger an automatic mutation retry.
const a = @import("r4os_contract").abi;
const services = @import("app_services.zig");
const system = @import("r4sys.zig");
pub const service_name: [*:0]const u8 = "POWERSVC";
pub const Reply = services.TypedServiceCall(a.PowerProfileInfo);
pub const CpuReply = services.TypedServiceCall(a.PowerCpuProfileInfo);
pub const Open = union(enum) { client: Client, failure: i32 };

pub const Client = struct {
    sys: system.Context,
    info: a.PowerProfileInfo = .{},

    pub fn open(sys: system.Context, timeout: services.Timeout) Open {
        var client: Client = .{ .sys = sys };
        return switch (client.status(timeout)) {
            .value => .{ .client = client },
            .failure, .remote_failure => |reason| .{ .failure = reason },
            .timed_out => .{ .failure = a.service_api_result_timeout },
        };
    }
    pub fn status(self: *Client, timeout: services.Timeout) Reply {
        return self.call(a.power_profile_op_status, 0, 0, timeout);
    }
    pub fn select(self: *Client, profile: u32, sticky_enable: bool, timeout: services.Timeout) Reply {
        if (profile > a.power_profile_saving or (profile == a.power_profile_firmware and sticky_enable))
            return .{ .failure = a.service_api_result_invalid };
        return self.call(a.power_profile_op_select, profile, if (sticky_enable) a.power_profile_request_flag_sticky_enable else 0, timeout);
    }
    pub fn quiesce(self: *Client, timeout: services.Timeout) Reply {
        return self.call(a.power_profile_op_quiesce, 0, 0, timeout);
    }
    pub fn resumeProfile(self: *Client, timeout: services.Timeout) Reply {
        return self.call(a.power_profile_op_resume, 0, 0, timeout);
    }
    pub fn reload(self: *Client, timeout: services.Timeout) Reply {
        return self.call(a.power_profile_op_reload, 0, 0, timeout);
    }
    fn connection(self: *const Client) services.ServiceOpen {
        const source: services.Services = .{ .sys = self.sys };
        const opened = source.open(service_name);
        return switch (opened) {
            .connection => |value| blk: {
                var value_copy = value;
                if (self.info.service_generation != 0 and self.info.service_instance_id != value.info.instance_id) {
                    _ = value_copy.close();
                    break :blk .{ .failure = a.service_api_result_not_running };
                }
                break :blk .{ .connection = value };
            },
            .failure => |reason| .{ .failure = reason },
        };
    }
    fn call(self: *Client, op: u16, profile: u32, flags: u32, timeout: services.Timeout) Reply {
        if (op != a.power_profile_op_status and self.info.service_generation == 0)
            return .{ .failure = a.service_api_result_bad_handle };
        var peer = switch (self.connection()) {
            .connection => |value| value,
            .failure => |reason| return .{ .failure = reason },
        };
        defer _ = peer.close();
        const request: a.PowerProfileRequest = .{
            .profile = profile,
            .flags = flags,
            .expected_service_generation = self.info.service_generation,
            .expected_revision = if (op == a.power_profile_op_status) 0 else self.info.revision,
        };
        return switch (peer.callTyped(a.PowerProfileRequest, a.PowerProfileInfo, op, &request, timeout)) {
            .value => |value| blk: {
                if (!valid(value) or value.service_instance_id != peer.info.instance_id or
                    (self.info.service_generation != 0 and (value.service_generation != self.info.service_generation or value.revision < self.info.revision)))
                    break :blk .{ .failure = a.service_api_result_invalid };
                self.info = value;
                break :blk .{ .value = value };
            },
            .failure => |reason| .{ .failure = reason },
            .remote_failure => |reason| .{ .remote_failure = reason },
            .timed_out => .timed_out,
        };
    }
    pub fn cpu(self: *const Client, index: u32, timeout: services.Timeout) CpuReply {
        if (self.info.service_generation == 0 or index >= self.info.configured_cpus)
            return .{ .failure = a.service_api_result_invalid };
        var peer = switch (self.connection()) {
            .connection => |value| value,
            .failure => |reason| return .{ .failure = reason },
        };
        defer _ = peer.close();
        const request: a.PowerProfileRequest = .{ .cpu_index = index, .expected_service_generation = self.info.service_generation };
        return switch (peer.callTyped(a.PowerProfileRequest, a.PowerCpuProfileInfo, a.power_profile_op_cpu, &request, timeout)) {
            .value => |value| if (value.version == 1 and value.size == @sizeOf(a.PowerCpuProfileInfo) and
                value.cpu_index == index and value.service_generation == self.info.service_generation and value.reserved0 == 0 and value.reserved1 == 0 and
                value.backend <= a.power_profile_backend_acpi_pss and value.state <= a.power_profile_state_quiesced)
                .{ .value = value }
            else
                .{ .failure = a.service_api_result_invalid },
            .failure => |reason| .{ .failure = reason },
            .remote_failure => |reason| .{ .remote_failure = reason },
            .timed_out => .timed_out,
        };
    }
};
pub fn valid(value: a.PowerProfileInfo) bool {
    if (value.version != 1 or value.size != @sizeOf(a.PowerProfileInfo) or value.reserved0 != 0 or
        value.service_generation == 0 or value.service_instance_id == 0 or value.revision == 0 or
        value.state > a.power_profile_state_quiesced or value.selected_profile > a.power_profile_saving or
        value.configured_cpus == 0 or value.configured_cpus > 64 or value.online_cpus > value.configured_cpus or
        value.backend_cpus > value.online_cpus or value.worker_count > value.configured_cpus) return false;
    const mask = if (value.configured_cpus == 64) ~@as(u64, 0) else (@as(u64, 1) << @as(u6, @intCast(value.configured_cpus))) - 1;
    return (value.owned_mask | value.applied_mask | value.pending_mask | value.supported_mask) & ~mask == 0;
}
