//! R4GFX-owned swapchains retain existing image resources. The same bounded
//! lifetime drives synchronous software presentation and native queued copy.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const d = @import("device.zig");
const c = d.c;
pub const lifecycle = @import("swapchain_state.zig");
const s = lifecycle;
const jobs = @import("device_jobs.zig");
const empty_image = std.mem.zeroes(c.R4GfxResource);
const empty_job = std.mem.zeroes(c.R4GfxJob);
const Work = struct {
    render: c.R4GfxJob = empty_job,
    present: c.R4GfxJob = empty_job,
    fence: a.GfxFence = .{},
    map: a.GfxBufferMap = .{},
    copy_ok: bool = false,
    deadline: u64 = 0,
    path: u32 = 0,
    intent: u32 = 0,
    blockers: u32 = 0,
};
pub const Slot = struct {
    serial: u64 = 0,
    closed: bool = true,
    state: s.Chain = .{},
    info: a.DisplayPresentationInfo = .{},
    target: a.GfxOutputTarget = .{},
    queue: a.GfxQueueHandle = .{},
    images: [s.capacity]c.R4GfxResource = @splat(empty_image),
    work: [s.capacity]Work = @splat(.{}),
    path: u32 = 0,
};
fn stateError(err: s.Error) d.Error {
    return switch (err) { error.Exhausted => error.Limit, else => |value| value };
}
fn now(device: *d.Device) d.Error!u64 {
    const value = device.base().monotonicNanoseconds() orelse return error.Unavailable;
    if (value == 0 or value == std.math.maxInt(u64)) return error.Unavailable;
    return value;
}
fn input(comptime T: type, device: *d.Device, value: *const T) d.Error!T {
    _ = try d.pointer(T, @intFromPtr(value));
    if (d.overlaps(@intFromPtr(value), @sizeOf(T), @intFromPtr(device), @sizeOf(d.Device))) return error.Alias;
    return value.*;
}
fn separate(comptime T: type, pointer: *const T, output: anytype) d.Error!void {
    if (d.overlaps(@intFromPtr(pointer), @sizeOf(T), @intFromPtr(output), @sizeOf(@typeInfo(@TypeOf(output)).pointer.child))) return error.Alias;
}
fn get(device: *d.Device, handle: *const c.R4GfxSwapchain) d.Error!*Slot {
    const value = try input(c.R4GfxSwapchain, device, handle);
    if (value.reserved != 0 or value.device_address != device.self_address or value.device_generation != device.generation or
        value.slot == 0 or value.slot > device.chains.len or value.generation == 0) return error.Stale;
    const slot = &device.chains[value.slot - 1];
    if (slot.serial != value.generation) return error.Stale;
    return slot;
}
fn token(device: *d.Device, slot: *Slot, frame: *const c.R4GfxSwapchainFrame) d.Error!s.Token {
    const value = try input(c.R4GfxSwapchainFrame, device, frame);
    const key: s.Token = .{ .slot = value.slot, .generation = value.generation, .serial = value.serial };
    _ = slot.state.frame(key) catch |err| return stateError(err);
    if (value.reserved != 0 or !std.meta.eql(value.image, slot.images[value.slot - 1])) return error.Stale;
    return key;
}
fn frameValue(slot: *const Slot, key: s.Token) c.R4GfxSwapchainFrame {
    return .{ .slot = key.slot, .reserved = 0, .generation = key.generation, .serial = key.serial,
        .image = if (key.slot == 0) empty_image else slot.images[key.slot - 1] };
}
fn describe(device: *d.Device, head: u32) d.Error!a.DisplayPresentationInfo {
    return (try describeOutput(device, head)).info;
}
const Description = struct { info: a.DisplayPresentationInfo, target: a.GfxOutputTarget = .{} };
fn describeOutput(device: *d.Device, head: u32) d.Error!Description {
    var value: a.DisplayPresentationInfo = .{};
    const base = device.base();
    var target: a.GfxOutputTarget = .{};
    if (device.preferred_adapter == 0) {
        try d.platform(base.displayPresentationInfo(head, &value));
        // The implicit primary CPU path remains usable through old R4DRAW
        // tables and through the native bridge's CPU fallback.
        if (value.flags & a.display_presentation_info_native != 0) {
            const rc = base.displayOutputTarget(value.backend.adapter_id, head, &target);
            if (rc != a.err_no_fn) {
                try d.platform(rc);
                try d.platform(base.displayOutputPresentationInfo(&target, &value));
            } else target = .{};
        }
    } else {
        // Explicit adapter selection never degrades into another primary.
        const rc = base.displayOutputTarget(device.preferred_adapter, head, &target);
        if (rc == a.err_no_fn) {
            try d.platform(base.displayPresentationInfo(head, &value));
            if (value.backend.adapter_id != device.preferred_adapter) return error.Unsupported;
            target = .{};
        } else {
            try d.platform(rc);
            try d.platform(base.displayOutputPresentationInfo(&target, &value));
        }
    }
    if (value.version != 1 or value.size < @sizeOf(a.DisplayPresentationInfo) or value.head_id != head or head >= 8 or
        value.display_generation == 0 or value.sequence == 0 or value.width == 0 or value.height == 0 or
        value.flags & ~@as(u32, 511) != 0 or value.policies & ~@as(u32, 7) != 0 or value.policies & 1 == 0 or
        value.buffer_count < 2 or value.buffer_count > 3 or value.plane_count == 0 or value.plane_count > 8 or
        (value.format != c.format_xrgb8888 and value.format != c.format_xrgb2101010) or value.reserved0 != 0 or value.path > 3 or
        value.interval_ns > std.time.ns_per_s or (value.observed_sequence == 0) != (value.observed_ns == 0)) return error.Invalid;
    if (target.connector_id != 0 and (target.adapter_id != value.backend.adapter_id or target.head_id != head or
        target.display_generation != value.display_generation or target.device_generation != value.backend.device_generation)) return error.Stale;
    return .{ .info = value, .target = target };
}
fn projection(device: *d.Device, value: a.DisplayPresentationInfo, target: a.GfxOutputTarget) s.Output {
    var adaptive_info: a.GfxOutputRefresh = .{};
    const adaptive = target.connector_id != 0 and value.flags & a.display_presentation_info_synchronized != 0 and
        device.base().gfxOutputRefresh(&target, &adaptive_info) == a.gfx_output_ok and std.meta.eql(adaptive_info.target, target) and
        adaptive_info.capabilities.flags & a.gfx_refresh_cap_capable != 0 and adaptive_info.status.phase == a.gfx_refresh_phase_active and
        adaptive_info.status.core_point != 0 and adaptive_info.status.receipt != 0;
    return .{ .generation = value.display_generation, .width = value.width, .height = value.height, .policies = value.policies,
        .synchronized = value.flags & a.display_presentation_info_synchronized != 0,
        .visibility = value.flags & a.display_presentation_info_visibility != 0,
        .direct = value.flags & a.display_presentation_info_direct != 0, .overlay = value.flags & a.display_presentation_info_overlay != 0,
        .occluded = value.flags & a.display_presentation_info_occluded != 0,
        // Under confirmed VRR, completed rendering determines submission.
        // The native worker enforces its real observed min/max deadlines.
        .adaptive = adaptive,
        .phase_ns = if (!adaptive and value.interval_ns != 0) value.observed_ns else 0,
        .interval_ns = if (!adaptive and value.observed_ns != 0) value.interval_ns else 0 };
}
pub fn presentationInfo(handle: *const c.R4GfxDevice, head: u32, output: *c.R4GfxPresentationInfo) callconv(.c) i32 {
    const device = d.get(handle, false) catch |err| return d.code(err);
    d.outputSafe(c.R4GfxPresentationInfo, output, device) catch |err| return d.code(err);
    separate(c.R4GfxDevice, handle, output) catch |err| return d.code(err);
    const value = describe(device, head) catch |err| return d.code(err);
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxPresentationInfo), .flags = value.flags, .head_id = value.head_id,
        .adapter_id = value.backend.adapter_id, .width = value.width, .height = value.height, .format = value.format,
        .device_generation = value.backend.device_generation, .reset_generation = value.backend.reset_generation,
        .display_generation = value.display_generation, .sequence = value.sequence, .policies = value.policies,
        .buffer_count = value.buffer_count, .plane_count = value.plane_count, .path = value.path,
        .interval_ns = value.interval_ns, .observed_sequence = value.observed_sequence, .observed_ns = value.observed_ns, .reserved = 0 };
    return c.status_ok;
}
const Pool = struct { config: s.Config, info: a.DisplayPresentationInfo, target: a.GfxOutputTarget, images: [s.capacity]c.R4GfxResource = @splat(empty_image) };
fn pool(device: *d.Device, request: *const c.R4GfxSwapchainDesc) d.Error!Pool {
    const desc = try input(c.R4GfxSwapchainDesc, device, request);
    if (desc.version != 1 or desc.size != @sizeOf(c.R4GfxSwapchainDesc) or desc.flags & ~c.present_require_vsync != 0 or
        desc.policy > 2 or desc.count < 2 or desc.count > s.capacity) return error.Invalid;
    _ = try d.pointer(c.R4GfxResource, desc.images);
    const bytes = desc.count * @as(u64, @sizeOf(c.R4GfxResource));
    _ = std.math.add(u64, desc.images, bytes) catch return error.Overflow;
    if (d.overlaps(desc.images, bytes, @intFromPtr(device), @sizeOf(d.Device))) return error.Alias;
    try device.selectBackend();
    const described = try describeOutput(device, desc.head_id);
    const info = described.info;
    if (info.flags & a.display_presentation_info_lost != 0) return error.Lost;
    if (info.display_generation != desc.display_generation) return error.Suboptimal;
    var result: Pool = .{ .config = .{ .count = desc.count, .policy = @enumFromInt(desc.policy), .require_vsync = desc.flags & c.present_require_vsync != 0 },
        .info = info, .target = described.target };
    var validation: s.Chain = .{};
    validation.configure(result.config, projection(device, info, described.target)) catch |err| return stateError(err);
    @memcpy(result.images[0..desc.count], @as([*]const c.R4GfxResource, @ptrFromInt(desc.images))[0..desc.count]);
    for (result.images[0..desc.count], 0..) |value, index| {
        const image = try device.resource(value, true);
        if (image.invalidated) return error.Stale;
        if (image.kind != c.resource_image or image.flags & c.image_target == 0 or image.image.width != info.width or
            image.image.height != info.height or image.image.format != info.format or image.public_refs == std.math.maxInt(u32)) return error.Unsupported;
        const native = info.flags & a.display_presentation_info_native != 0;
        if (native) try @import("device_output_color.zig").validate(device, image, described.target)
        else if (!@import("device_output_color.zig").canonical(image)) return error.Unsupported;
        if (native) {
            if (image.backing.reference.id == 0 or image.descriptor.usage & a.gfx_buffer_usage_transfer_source == 0) return error.Unsupported;
            if (image.descriptor.location == a.gfx_buffer_location_device_local) {
                if (device.gpu_operations & c.device_gpu_present == 0 or !std.meta.eql(info.backend, device.selected.binding)) return error.Unsupported;
            } else if (described.target.connector_id == 0 or image.descriptor.location != a.gfx_buffer_location_system or image.descriptor.modifier != 0)
                return error.Unsupported;
        } else if (image.descriptor.location != a.gfx_buffer_location_system or image.descriptor.modifier != 0 or
            image.image.pitch & 3 != 0 or image.image.byte_length / 4 > std.math.maxInt(u32)) return error.Unsupported;
        for (result.images[0..index]) |prior| {
            const other = try device.resource(prior, true);
            if (image == other or (image.backing.buffer.id != 0 and std.meta.eql(image.backing.buffer, other.backing.buffer)) or
                (image.image.cpu_address != 0 and other.image.cpu_address != 0 and d.overlaps(image.image.cpu_address, image.image.byte_length,
                    other.image.cpu_address, other.image.byte_length))) return error.Alias;
        }
    }
    return result;
}
fn retainPool(device: *d.Device, value: Pool) void {
    for (value.images[0..value.config.count]) |handle| (device.resource(handle, true) catch unreachable).public_refs += 1;
}
fn releasePool(device: *d.Device, slot: *Slot) d.Error!void {
    for (&slot.images) |*handle| if (handle.slot != 0) {
        const resource = try device.resource(handle.*, false);
        if (resource.public_refs == 0) return error.Stale;
        resource.public_refs -= 1; handle.* = empty_image;
        _ = device.cleanResource(resource);
    };
}
pub fn open(handle: *const c.R4GfxDevice, request: *const c.R4GfxSwapchainDesc, output: *c.R4GfxSwapchain) callconv(.c) i32 {
    return openImpl(handle, request, output) catch |err| d.code(err);
}
fn openImpl(handle: *const c.R4GfxDevice, request: *const c.R4GfxSwapchainDesc, output: *c.R4GfxSwapchain) d.Error!i32 {
    const device = try d.get(handle, false);
    try d.outputSafe(c.R4GfxSwapchain, output, device); try separate(c.R4GfxSwapchainDesc, request, output);
    try separate(c.R4GfxDevice, handle, output);
    const desc = try input(c.R4GfxSwapchainDesc, device, request);
    if (d.overlaps(desc.images, @as(u64, desc.count) * @sizeOf(c.R4GfxResource), @intFromPtr(output), @sizeOf(c.R4GfxSwapchain))) return error.Alias;
    const value = try pool(device, request);
    const index = for (&device.chains, 0..) |*slot, i| { if (slot.closed) break i; } else return error.Limit;
    const serial = std.math.add(u64, device.chain_serial, 1) catch return error.Limit;
    var state: s.Chain = .{};
    state.configure(value.config, projection(device, value.info, value.target)) catch |err| return stateError(err);
    retainPool(device, value);
    device.chains[index] = .{ .serial = serial, .closed = false, .state = state, .info = value.info, .target = value.target, .images = value.images, .path = value.info.path };
    device.chain_serial = serial;
    output.* = .{ .slot = @intCast(index + 1), .reserved = 0, .generation = serial, .device_generation = device.generation, .device_address = device.self_address };
    return c.status_ok;
}
fn refresh(device: *d.Device, slot: *Slot) d.Error!void {
    if (slot.closed) return error.Stale;
    if (slot.state.life == .closing or slot.state.life == .lost) return;
    const described = describeOutput(device, slot.info.head_id) catch |err| {
        if (err == error.Busy) return;
        slot.state.change(.lost); return;
    };
    const info = described.info;
    if (!std.meta.eql(described.target, slot.target)) { slot.state.change(.suboptimal); return; }
    if (info.flags & a.display_presentation_info_lost != 0) { slot.state.change(.lost); return; }
    if (!std.meta.eql(info.backend, slot.info.backend) or info.flags & a.display_presentation_info_native != slot.info.flags & a.display_presentation_info_native) {
        slot.state.change(.suboptimal); return;
    }
    for (slot.images[0..slot.state.config.count]) |handle| {
        const resource = device.resource(handle, false) catch { slot.state.change(.lost); return; };
        if (resource.invalidated) { slot.state.change(.lost); return; }
    }
    slot.state.refresh(projection(device, info, described.target)) catch |err| return stateError(err);
    slot.info = info;
}
pub fn acquire(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, input_ns: u64, output: *c.R4GfxSwapchainFrame) callconv(.c) i32 {
    return acquireImpl(handle, chain, input_ns, output) catch |err| d.code(err);
}
fn acquireImpl(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, input_ns: u64, output: *c.R4GfxSwapchainFrame) d.Error!i32 {
    const device = try d.get(handle, false); const slot = try get(device, chain);
    try d.outputSafe(c.R4GfxSwapchainFrame, output, device); try separate(c.R4GfxSwapchain, chain, output);
    try separate(c.R4GfxDevice, handle, output);
    try refresh(device, slot);
    const key = slot.state.acquire(try now(device), input_ns) catch |err| return stateError(err);
    output.* = frameValue(slot, key);
    return c.status_ok;
}
pub fn present(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, request: *const c.R4GfxSwapchainPresent) callconv(.c) i32 {
    return presentImpl(handle, chain, request) catch |err| d.code(err);
}
fn presentImpl(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, request: *const c.R4GfxSwapchainPresent) d.Error!i32 {
    const device = try d.get(handle, false); const slot = try get(device, chain);
    const value = try input(c.R4GfxSwapchainPresent, device, request);
    if (value.version != 1 or value.size != @sizeOf(c.R4GfxSwapchainPresent) or value.intent > 2 or value.blockers & ~@as(u32, 63) != 0) return error.Invalid;
    const key = try token(device, slot, &value.frame);
    const instant = try now(device);
    if (value.deadline_ns <= instant or value.deadline_ns == std.math.maxInt(u64)) return error.Invalid;
    try refresh(device, slot);
    const render = if (value.render_job.slot != 0) try device.job(value.render_job) else null;
    if (render) |job| {
        if (!std.meta.eql(job.target, value.frame.image) or job.chain_refs == std.math.maxInt(u32)) return error.Invalid;
    } else if (!std.meta.eql(value.render_job, empty_job)) return error.Invalid;
    // Composition/copy is a complete valid fallback. Direct requests are
    // negotiated against real capabilities and consumer exclusions below.
    const path = try presentPath(device, slot, value.frame.image, value.intent, value.blockers);
    slot.state.present(key, instant, path, render != null) catch |err| return stateError(err);
    if (render) |job| job.chain_refs += 1;
    slot.work[key.slot - 1] = .{ .render = value.render_job, .deadline = value.deadline_ns, .path = @intFromEnum(path), .intent = value.intent, .blockers = value.blockers };
    return c.status_ok;
}
fn receipt(device: *d.Device, job: c.R4GfxJob) d.Error!a.GfxFenceStatus {
    const item = try device.job(job);
    var value: a.GfxFenceStatus = .{};
    try d.platform(device.queues().query(&item.fence, &value));
    if (!std.meta.eql(item.fence, value.fence) or value.version != 1 or value.size < @sizeOf(a.GfxFenceStatus)) return error.Stale;
    return value;
}
fn retired(value: a.GfxFenceStatus) bool { return value.phase == a.gfx_queue_phase_terminal and value.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) == 0; }
fn progress(device: *d.Device, slot: *Slot) d.Error!void {
    if (slot.closed) return error.Stale;
    try refresh(device, slot);
    const instant = try now(device);
    for (&slot.state.frames, &slot.work) |*frame, *work| {
        if (frame.phase == .free) continue;
        if (work.deadline != 0 and instant >= work.deadline and frame.result == .pending)
            slot.state.abandon(frame.token, .failed) catch |err| return stateError(err);
        if (frame.result == .discarded or frame.result == .failed or frame.result == .lost) {
            if (work.render.slot != 0) _ = jobs.cancel(device, &work.render) catch c.status_busy;
            if (work.present.slot != 0) _ = jobs.cancel(device, &work.present) catch c.status_busy;
        }
        if (frame.path == .direct and slot.state.life != .active and slot.state.life != .occluded and work.present.slot != 0)
            _ = jobs.cancel(device, &work.present) catch c.status_busy;
        if (work.render.slot != 0) {
            const completed = try receipt(device, work.render);
            if (retired(completed)) {
                const job = try device.job(work.render);
                slot.state.rendered(frame.token, if (completed.completed_ns != 0) completed.completed_ns else instant,
                    completed.result == a.gfx_queue_result_complete) catch |err| return stateError(err);
                std.debug.assert(job.chain_refs != 0); job.chain_refs -= 1; work.render = empty_job;
            }
        }
        if (work.present.slot != 0) {
            const completed = try receipt(device, work.present);
            if (retired(completed)) {
                _ = try jobs.release(device, &work.present); work.present = empty_job;
                slot.state.retired(frame.token, if (frame.path != .direct and completed.completed_ns != 0) completed.completed_ns else instant,
                    completed.result == a.gfx_queue_result_complete) catch |err| return stateError(err);
            }
        }
        if (work.map.lease.id != 0 and device.buffers().unmap(&work.map.lease) == a.gfx_buffer_result_ok) {
            work.map = .{};
            slot.state.retired(frame.token, instant, work.copy_ok) catch |err| return stateError(err);
        }
        if (frame.phase == .submitted and (!frame.consumer_held or frame.path == .direct) and slot.state.output.visibility) {
            var visible: a.DisplayPresentationStats = .{};
            const rc = if (slot.target.connector_id != 0) device.base().displayOutputPresentationFeedback(&slot.target, &work.fence, &visible)
                else device.base().displayPresentationFeedback(slot.info.head_id, &work.fence, &visible);
            if (rc == a.gfx_output_ok) {
                if (visible.version != 1 or visible.size < @sizeOf(a.DisplayPresentationStats) or visible.head_id != slot.info.head_id or
                    visible.flags & a.display_presentation_flag_available == 0 or
                    !std.meta.eql(visible.backend, slot.info.backend) or visible.display_generation != slot.info.display_generation or
                    visible.flags & a.display_presentation_flag_lost != 0) slot.state.change(.lost)
                else if (visible.source_timeline == work.fence.timeline and visible.source_point == work.fence.point and visible.visible_ns != 0 and
                    (visible.flags & a.display_presentation_flag_direct != 0) == (frame.path == .direct))
                    slot.state.visible(frame.token, visible.visible_ns) catch |err| return stateError(err);
            }
        }
    }
    const key = slot.state.candidate() orelse return;
    const work = &slot.work[key.slot - 1];
    const path = try presentPath(device, slot, slot.images[key.slot - 1], work.intent, work.blockers);
    work.path = @intFromEnum(path); slot.state.frames[key.slot - 1].path = path;
    if (slot.info.flags & a.display_presentation_info_native != 0) {
        const request: c.R4GfxImagePresentRequest = .{ .version = 1, .size = @sizeOf(c.R4GfxImagePresentRequest),
            .source = slot.images[key.slot - 1], .frame_key = key.serial, .deadline_ns = work.deadline, .dependencies = 0, .dependency_count = 0, .reserved = 0 };
        var accepted: c.R4GfxJob = undefined;
        const presenter = @import("device_image_present.zig");
        if (slot.target.connector_id != 0 and slot.queue.timeline == 0) {
            const rc = device.queues().open(&.{ .adapter_id = slot.info.backend.adapter_id,
                .device_generation = slot.info.backend.device_generation, .reset_generation = slot.info.backend.reset_generation,
                .milestone = slot.info.backend.milestone, .capacity = s.capacity }, &slot.queue);
            if (rc == a.gfx_queue_error_busy) return;
            try d.platform(rc);
        }
        _ = (if (slot.target.connector_id != 0) presenter.submitOutput(device, &request, &accepted, path == .direct, slot.target, slot.queue)
            else presenter.submitPath(device, &request, &accepted, path == .direct)) catch |err| {
            if (err == error.Busy) return;
            slot.state.abandon(key, .failed) catch unreachable; return;
        };
        work.present = accepted;
        work.fence = (try device.job(work.present)).fence;
        slot.state.submitted(key, instant) catch unreachable;
    } else try submitCpu(device, slot, key, instant);
    slot.path = work.path;
}
fn submitCpu(device: *d.Device, slot: *Slot, key: s.Token, instant: u64) d.Error!void {
    const resource = try device.resource(slot.images[key.slot - 1], true);
    const work = &slot.work[key.slot - 1];
    var address = resource.image.cpu_address;
    if (address == 0) {
        const rc = device.buffers().map(&resource.backing.reference, a.gfx_buffer_map_read, 0, resource.image.byte_length, &work.map);
        if (rc == a.gfx_buffer_error_busy) return;
        try d.platform(rc); address = work.map.cpu_address;
    }
    slot.state.submitted(key, instant) catch unreachable;
    if (address == 0 or address & 3 != 0 or (work.map.lease.id != 0 and work.map.byte_length < resource.image.byte_length)) {
        slot.state.abandon(key, .failed) catch unreachable;
        if (work.map.lease.id == 0) slot.state.retired(key, instant, false) catch unreachable;
        return;
    }
    const image = resource.image;
    const pixels: [*]const u32 = @ptrFromInt(address);
    const rect: a.DisplayDamageRect = .{ .w = image.width, .h = image.height };
    var result: a.DisplayPresentResult = .{};
    const rc = device.base().displayPresentRegions(&.{ .source_width = image.width, .source_height = image.height,
        .source_stride_pixels = @intCast(image.pitch / 4), .source_generation = key.serial }, pixels[0..@intCast(image.byte_length / 4)], (&rect)[0..1], &result);
    work.copy_ok = rc == 0 and result.flags & (a.display_present_result_success | a.display_present_result_completed) ==
        (a.display_present_result_success | a.display_present_result_completed);
    if (work.map.lease.id != 0) {
        if (device.buffers().unmap(&work.map.lease) != a.gfx_buffer_result_ok) return;
        work.map = .{};
    }
    slot.state.retired(key, try now(device), work.copy_ok) catch |err| return stateError(err);
}
fn frameStatus(slot: *const Slot, index: usize) c.R4GfxSwapchainFrameStatus {
    const frame = &slot.state.frames[index]; const stamp = &frame.times;
    return .{ .frame = frameValue(slot, frame.token), .phase = @intFromEnum(frame.phase), .result = @intFromEnum(frame.result), .path = @intFromEnum(frame.path),
        .held_flags = @as(u32, @intFromBool(frame.render_held)) | (@as(u32, @intFromBool(frame.consumer_held)) << 1),
        .input_ns = stamp.input_ns, .acquired_ns = stamp.acquired_ns, .queued_ns = stamp.queued_ns, .render_end_ns = stamp.render_end_ns,
        .selected_ns = stamp.selected_ns, .submitted_ns = stamp.submitted_ns, .copied_ns = stamp.copied_ns, .visible_ns = stamp.visible_ns, .released_ns = stamp.released_ns };
}
pub fn poll(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, output: *c.R4GfxSwapchainStatus) callconv(.c) i32 {
    return pollImpl(handle, chain, output) catch |err| d.code(err);
}
fn pollImpl(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, output: *c.R4GfxSwapchainStatus) d.Error!i32 {
    const device = try d.get(handle, true); const slot = try get(device, chain);
    try d.outputSafe(c.R4GfxSwapchainStatus, output, device); try separate(c.R4GfxSwapchain, chain, output);
    try separate(c.R4GfxDevice, handle, output);
    try progress(device, slot);
    var queued: u32 = 0; var held: u32 = 0;
    for (&slot.state.frames) |*frame| { queued += @intFromBool(frame.phase == .queued); held += @intFromBool(frame.render_held or frame.consumer_held); }
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxSwapchainStatus), .life = @intFromEnum(slot.state.life), .policy = @intFromEnum(slot.state.config.policy),
        .count = slot.state.config.count, .queued_count = queued, .held_count = held, .path = slot.path, .generation = slot.state.generation, .next_start_ns = slot.state.next_start_ns,
        .frame0 = frameStatus(slot, 0), .frame1 = frameStatus(slot, 1), .frame2 = frameStatus(slot, 2) };
    return c.status_ok;
}
pub fn release(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, frame: *const c.R4GfxSwapchainFrame) callconv(.c) i32 {
    return releaseImpl(handle, chain, frame) catch |err| d.code(err);
}
fn releaseImpl(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, frame: *const c.R4GfxSwapchainFrame) d.Error!i32 {
    const device = try d.get(handle, true); const slot = try get(device, chain); const key = try token(device, slot, frame);
    const resource = try device.resource(slot.images[key.slot - 1], false);
    if (resource.job_refs != 0) return error.Busy;
    slot.state.release(key) catch |err| return stateError(err);
    slot.work[key.slot - 1] = .{};
    return c.status_ok;
}
pub fn resize(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, request: *const c.R4GfxSwapchainDesc) callconv(.c) i32 {
    return resizeImpl(handle, chain, request) catch |err| d.code(err);
}
fn resizeImpl(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain, request: *const c.R4GfxSwapchainDesc) d.Error!i32 {
    const device = try d.get(handle, false); const slot = try get(device, chain);
    if (slot.closed or slot.state.life == .lost or slot.state.life == .closing) return error.Stale;
    const value = try pool(device, request);
    slot.state.change(.suboptimal);
    var candidate = slot.state;
    candidate.configure(value.config, projection(device, value.info, value.target)) catch |err| return stateError(err);
    // Validate every old ownership record before either pool is mutated.
    for (slot.images[0..slot.state.config.count]) |image| if ((try device.resource(image, false)).public_refs == 0) return error.Stale;
    try closeQueue(device, slot);
    retainPool(device, value);
    try releasePool(device, slot);
    slot.state = candidate; slot.info = value.info; slot.target = value.target; slot.images = value.images; slot.work = @splat(.{}); slot.path = value.info.path;
    return c.status_ok;
}
pub fn close(handle: *const c.R4GfxDevice, chain: *const c.R4GfxSwapchain) callconv(.c) i32 {
    const device = d.get(handle, true) catch |err| return d.code(err);
    const slot = get(device, chain) catch |err| return d.code(err);
    return closeSlot(device, slot) catch |err| d.code(err);
}
fn closeSlot(device: *d.Device, slot: *Slot) d.Error!i32 {
    if (slot.closed) return c.status_ok;
    slot.state.change(.closing);
    try progress(device, slot);
    for (&slot.state.frames, 0..) |*frame, i| if (frame.phase != .free) {
        if ((try device.resource(slot.images[i], false)).job_refs != 0) return error.Busy;
        slot.state.release(frame.token) catch |err| return stateError(err);
        slot.work[i] = .{};
    };
    try releasePool(device, slot);
    try closeQueue(device, slot);
    slot.closed = true;
    return c.status_ok;
}
fn closeQueue(device: *d.Device, slot: *Slot) d.Error!void {
    if (slot.queue.timeline == 0) return;
    // Reset may already remove an empty queue. Its monotonic timeline cannot
    // name a replacement; all frame jobs were retired before reaching here.
    const rc = device.queues().close(&slot.queue);
    if (rc != a.gfx_queue_error_stale) try d.platform(rc);
    slot.queue = .{};
}
pub fn closeAll(device: *d.Device) bool {
    var okay = true;
    for (&device.chains) |*slot| if (!slot.closed) { _ = closeSlot(device, slot) catch { okay = false; continue; }; };
    return okay;
}
pub fn plan(handle: *const c.R4GfxDevice, request: *const c.R4GfxPresentationPlan, output: *c.R4GfxPresentationDecision) callconv(.c) i32 {
    return planImpl(handle, request, output) catch |err| d.code(err);
}
fn planImpl(handle: *const c.R4GfxDevice, request: *const c.R4GfxPresentationPlan, output: *c.R4GfxPresentationDecision) d.Error!i32 {
    const device = try d.get(handle, false);
    try d.outputSafe(c.R4GfxPresentationDecision, output, device); try separate(c.R4GfxPresentationPlan, request, output);
    try separate(c.R4GfxDevice, handle, output);
    const value = try input(c.R4GfxPresentationPlan, device, request);
    if (value.version != 1 or value.size != @sizeOf(c.R4GfxPresentationPlan) or value.flags & ~@as(u32, 63) != 0 or
        value.intent > 2 or value.reserved != 0) return error.Invalid;
    const described = try describeOutput(device, value.head_id);
    const source = try device.resource(value.source, true);
    output.* = try decision(device, described.info, source, value, described.target);
    return c.status_ok;
}
fn presentPath(device: *d.Device, slot: *Slot, image: c.R4GfxResource, intent: u32, blockers: u32) d.Error!s.Path {
    const source = try device.resource(image, true);
    const full: c.R4GfxRect = .{ .x = 0, .y = 0, .width = source.image.width, .height = source.image.height };
    const result = try decision(device, slot.info, source, .{ .version = 1, .size = @sizeOf(c.R4GfxPresentationPlan),
        .head_id = slot.info.head_id, .flags = (3 & ~blockers) | (blockers & 60), .source = image,
        .source_rect = full, .target_rect = full, .color_space = 0, .transform = 0, .intent = intent, .reserved = 0 }, slot.target);
    return @enumFromInt(result.path);
}
fn decision(device: *d.Device, info: a.DisplayPresentationInfo, source: *d.Resource, value: c.R4GfxPresentationPlan, target: a.GfxOutputTarget) d.Error!c.R4GfxPresentationDecision {
    if (source.invalidated) return error.Stale;
    if (source.kind != c.resource_image or value.source_rect.width == 0 or value.source_rect.height == 0 or
        value.source_rect.x > source.image.width or value.source_rect.y > source.image.height or
        value.source_rect.width > source.image.width - value.source_rect.x or value.source_rect.height > source.image.height - value.source_rect.y or
        value.target_rect.width == 0 or value.target_rect.height == 0 or value.target_rect.x > info.width or value.target_rect.y > info.height or
        value.target_rect.width > info.width - value.target_rect.x or value.target_rect.height > info.height - value.target_rect.y) return error.Invalid;
    var result: c.R4GfxPresentationDecision = .{ .version = 1, .size = @sizeOf(c.R4GfxPresentationDecision),
        .path = if (info.flags & a.display_presentation_info_native != 0) c.present_path_composition else c.present_path_software,
        .reasons = 0, .display_generation = info.display_generation };
    if (value.intent != 0) {
        if (info.flags & a.display_presentation_info_native != 0) {
            @import("device_output_color.zig").validate(device, source, target) catch |err| {
                if (err == error.Unsupported) { result.reasons |= 8; } else return err;
            };
        } else if (!@import("device_output_color.zig").canonical(source)) result.reasons |= 8;
        const overlay = value.intent == 2;
        // Plane geometry is checked below, but DEVICE_V1 currently has no
        // queued overlay submission. A capability bit alone cannot select it.
        if (overlay) result.reasons |= 256;
        if (info.flags & (if (overlay) a.display_presentation_info_overlay else a.display_presentation_info_direct) == 0 or
            info.flags & (a.display_presentation_info_lost | a.display_presentation_info_occluded) != 0 or
            (!overlay and device.gpu_operations & c.device_gpu_direct == 0)) result.reasons |= 256;
        if ((source.image.format != info.format and (!overlay or source.image.format != c.format_argb8888)) or value.flags & 1 == 0) result.reasons |= 1;
        const desc = source.descriptor;
        if (source.backing.reference.id == 0 or desc.location != a.gfx_buffer_location_device_local or desc.modifier != 0 or
            desc.plane_count != 1 or desc.plane_offsets[0] != 0 or desc.plane_pitches[0] & 63 != 0 or
            desc.usage & a.gfx_buffer_usage_scanout == 0 or desc.adapter_id != info.backend.adapter_id or
            desc.device_generation != device.selected.memory_generation or !std.meta.eql(info.backend, device.selected.binding)) result.reasons |= 2;
        if (value.source_rect.x != 0 or value.source_rect.y != 0 or value.source_rect.width != source.image.width or
            value.source_rect.height != source.image.height or value.target_rect.width != source.image.width or value.target_rect.height != source.image.height or
            (!overlay and (value.target_rect.x != 0 or value.target_rect.y != 0 or source.image.width != info.width or source.image.height != info.height))) result.reasons |= 4;
        if (value.color_space != 0 or value.transform != 0) result.reasons |= 8;
        if (value.flags & 4 != 0) result.reasons |= 16;
        if (value.flags & 8 != 0) result.reasons |= 32;
        if (!overlay and value.flags & 2 == 0) result.reasons |= 64;
        if (value.flags & 16 != 0) result.reasons |= 128;
        if (value.flags & 32 != 0) result.reasons |= 512;
        if (result.reasons == 0) result.path = if (overlay) c.present_path_overlay else c.present_path_direct;
    }
    return result;
}
