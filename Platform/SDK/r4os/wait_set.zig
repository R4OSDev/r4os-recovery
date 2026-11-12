//! Explicit Query2 wait-any. Each Set belongs to its creating native Task;
//! do not copy or move it to another task. Same-process peers may close handle.
//! Context/table/code live through the scope. No source work or buffer release
//! follows from a readiness/timeout/cancellation observation.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const platform = @import("platform2.zig");
const checked = @import("time_budget.zig");
pub const Source = abi.WaitSource;
pub const Deadline = abi.WaitSetDeadline;
pub const Event = abi.WaitSetEvent;
pub const Batch = abi.WaitSetBatch;
pub const Request = abi.WaitSourceRequest;
/// Preparation observes the CURRENT legacy IO/endpoint incarnation. Keep the
/// returned descriptor; never reconstruct its opaque generation. A later
/// Enroll can return Stale after source close. This grants no resource retain.
pub fn prepare(context: *const platform.Context, request: Request, output: *Source) i32 {
    var address: u64 = 0;
    const code = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "waitset_source_prepare"), &address);
    if (code != 0) return code;
    const call: abi.R4SysFns.waitset_source_prepare = @ptrFromInt(address);
    return call(&request, output);
}
pub fn io(request_id: u32, tag: u64) Request {
    return .{ .kind = abi.waitset_source_io, .object = request_id, .user_tag = tag };
}
pub fn process(handle: abi.ProgramProcessHandle, tag: u64) Request {
    return .{ .kind = abi.waitset_source_process, .object = handle.instance_id, .generation = handle.generation, .flags = @intFromBool(handle.reserved != 0), .user_tag = tag };
}
pub fn thread(handle: abi.ProgramJoinHandle, tag: u64) Request {
    return .{ .kind = abi.waitset_source_thread, .object = handle.thread_id, .generation = handle.thread_generation, .scope_id = handle.instance_id, .scope_generation = handle.instance_generation, .flags = @intFromBool(handle.reserved != 0), .user_tag = tag };
}
pub fn endpoint(handle: u32, tag: u64) Request {
    return .{ .kind = abi.waitset_source_service_endpoint, .object = handle, .user_tag = tag };
}
/// Only the current Main GUI may prepare/enroll its activity channel. Workers
/// report completion through their own sources; the owner pumps ordinary GUI.
pub fn guiActivity(observed: u64, tag: u64) Request {
    return .{ .kind = abi.waitset_source_gui_activity, .observed_revision = observed, .user_tag = tag };
}
pub fn notification(handle: u64, observed: u64, tag: u64, stop: bool) Source {
    return .{ .kind = abi.waitset_source_notification, .object = handle, .observed_revision = observed, .user_tag = tag, .flags = if (stop) abi.waitset_source_flag_stop else 0 };
}
pub fn timer(sample: checked.ClockSample, absolute_ns: u64, tag: u64) checked.Error!Source {
    try sample.validate();
    if (sample.identity.tick_hz == 0) return error.UnknownFrequency;
    return .{ .kind = abi.waitset_source_timer, .user_tag = tag, .deadline_ns = absolute_ns, .clock_source = sample.identity.source, .clock_generation = sample.identity.generation, .event_backend = sample.identity.event_backend, .tick_hz = sample.identity.tick_hz };
}
pub fn deadline(budget: checked.DeadlineBudget) checked.Error!Deadline {
    if (budget.kind > 2 or budget.reserved != 0) return error.InvalidBudget;
    if (budget.kind != 1) return .{ .kind = budget.kind };
    if (budget.identity.source == 0 or budget.identity.generation == 0) return error.ClockUnavailable;
    if (budget.identity.tick_hz == 0) return error.UnknownFrequency;
    return .{ .kind = 1, .absolute_ns = budget.deadline_ns, .last_ns = budget.last_ns, .clock_source = budget.identity.source, .clock_generation = budget.identity.generation, .event_backend = budget.identity.event_backend, .tick_hz = budget.identity.tick_hz };
}
pub const Provider = struct {
    create: abi.R4SysFns.waitset_create,
    enroll: abi.R4SysFns.waitset_enroll,
    rearm: abi.R4SysFns.waitset_rearm,
    remove: abi.R4SysFns.waitset_remove,
    wait: abi.R4SysFns.waitset_wait,
    close: abi.R4SysFns.waitset_close,

    pub fn fromContext(context: *const platform.Context, output: *Provider) i32 {
        var addresses: [6]u64 = @splat(0);
        inline for (.{ "waitset_create", "waitset_enroll", "waitset_rearm", "waitset_remove", "waitset_wait", "waitset_close" }, 0..) |name, index| {
            const code = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, name), &addresses[index]);
            if (code != 0) return code;
        }
        output.* = .{ .create = @ptrFromInt(addresses[0]), .enroll = @ptrFromInt(addresses[1]), .rearm = @ptrFromInt(addresses[2]), .remove = @ptrFromInt(addresses[3]), .wait = @ptrFromInt(addresses[4]), .close = @ptrFromInt(addresses[5]) };
        return 0;
    }
};
pub const Set = struct {
    provider: Provider,
    handle: u64,
    pub fn init(context: *const platform.Context, capacity: u32, output: *Set) i32 {
        var provider: Provider = undefined;
        const resolved = Provider.fromContext(context, &provider);
        if (resolved != 0) return resolved;
        var handle: u64 = 0;
        const code = provider.create(capacity, &handle);
        if (code != 0) return code;
        output.* = .{ .provider = provider, .handle = handle };
        return 0;
    }
    pub fn enroll(self: *Set, source: Source, registration: *u64) i32 {
        return self.provider.enroll(self.handle, &source, registration);
    }
    pub fn rearm(self: *Set, registration: u64, source: Source) i32 {
        return self.provider.rearm(self.handle, registration, &source);
    }
    pub fn remove(self: *Set, registration: u64) i32 {
        return self.provider.remove(self.handle, registration);
    }
    pub fn wait(self: *Set, limit: Deadline, events: []Event, batch: *Batch) i32 {
        if (events.len == 0 or events.len > abi.waitset_max_sources) return abi.waitset_error_invalid;
        return self.provider.wait(self.handle, &limit, events.ptr, @intCast(events.len), batch);
    }
    /// Retry Release failures with the same handle. Only success clears it;
    /// exact creator retirement also drains any remaining resident owner.
    pub fn close(self: *Set) i32 {
        if (self.handle == 0) return 0;
        const code = self.provider.close(self.handle);
        if (code == 0 or code == abi.waitset_error_stale) self.handle = 0;
        return code;
    }
};
