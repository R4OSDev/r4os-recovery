// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Focused owner checks inside the existing allocation case. Real SDK dispatch;
// only the kernel/driver callbacks are modeled. Codec hooks inspect native
// commands and synthesize completion records; they never execute a codec.
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const a = r.abi;
const nv = @import("r4nv_binding");
const amd = @import("r4amd");
const media = @import("r4amd_media");
const gpu = @import("gpu_resources");
pub var model: *Model = undefined;
const Bo = struct { descriptor: a.GfxBufferDescriptor = .{}, data: ?[]align(65536) u8 = null, live: bool = false, mapped: bool = false, references: u32 = 0 };
const Va = struct { request: a.GfxVirtualRequest = .{}, status: a.GfxVirtualStatus = .{}, live: bool = false };
pub const Model = struct {
    provider: gpu.Provider = .nvidia,
    raven2: bool = false,
    wrong_amd_profile: bool = false,
    media_ready: bool = true,
    jpeg_ready: bool = true,
    unmap_busy: bool = false,
    map_invalid: bool = false,
    bos: [64]Bo = @splat(.{}),
    vas: [128]Va = @splat(.{}),
    pending: a.GfxNativeAllocation = .{},
    pending_live: bool = false,
    next_va: u64 = 0x100000,
    native_timeout: bool = false,
    bind_timeout: bool = false,
    retire_ready: bool = true,
    queue_timeout: bool = false,
    queue_released: bool = true,
    queue_closed: bool = true,
    queue_close_result: i32 = a.gfx_queue_ok,
    fence_query_result: i32 = a.gfx_queue_ok,
    queue_count: u32 = 0,
    next_timeline: u64 = 91,
    fence_released: bool = true,
    cancel_count: u32 = 0,
    fence: a.GfxFence = .{},
    loan_count: usize = 0,
    loans: [64]a.GfxNativeResource = undefined,
    coherent: bool = true,
    graphics: bool = false,
    class_chip: u32 = 0x174,
    engine: gpu.Engine = .decode,
    mixed_engines: bool = false,
    deadline_ns: u64 = 5_001_000_000,
    push_bytes: u32 = 216,
    on_submit: ?*const fn ([]const u8) void = null,
    pub fn clean(self: *Model) !void {
        for (&self.bos) |*bo| try t.expect(!bo.live and !bo.mapped and bo.data == null);
        for (&self.vas) |*va| try t.expect(!va.live);
        try t.expect(!self.pending_live and self.queue_closed and self.fence_released);
    }
};
fn handle(slot: usize) a.GfxBufferHandle {
    return .{ .id = @intCast(slot + 1), .generation = 17 };
}
pub fn index(h: *const a.GfxBufferHandle, limit: usize) ?usize {
    if (h.id == 0 or h.id > limit or h.generation != 17 or h.reserved0 != 0) return null;
    return h.id - 1;
}
pub fn clock() ?a.MonotonicClockInfo {
    return .{ .instant_ns = 1_000_000, .frequency_hz = 1_000_000_000,
        .event_frequency_numerator = 100, .event_frequency_denominator = 1, .flags = a.monotonic_clock_flag_valid };
}
fn binding() a.GfxBackendBinding {
    return .{ .adapter_id = 9, .device_generation = 23, .reset_generation = 7, .milestone = a.gfx_queue_milestone_device_execution };
}
fn backend(which: u32, output: *a.GfxBackendInfo) callconv(.c) i32 {
    if (which != 0) return 0;
    if (model.provider == .amd) {
        const protocol: amd.R4AmdDriverProfile = .{ .version = 1, .size = @sizeOf(amd.R4AmdDriverProfile),
            .vendor_id = amd.vendor_id, .device_id = 0x15d8, .gc_version = if (model.raven2) amd.gc_9_2_2 else amd.gc_9_1_0,
            .sdma_version = if (model.raven2) amd.sdma_4_1_1 else amd.sdma_4_1_0, .command_abi = amd.command_abi, .reserved = 0 };
        output.* = .{ .binding = binding(), .memory_generation = 31, .operations = 1 << a.gfx_queue_operation_native,
            .profile = .{ .interface_id_lo = amd.backend_v1_header.interface_id_lo, .interface_id_hi = amd.backend_v1_header.interface_id_hi,
                .revision = 1, .data_bytes = @sizeOf(amd.R4AmdDriverProfile) } };
        @memcpy(output.profile.data[0..@sizeOf(amd.R4AmdDriverProfile)], std.mem.asBytes(&protocol));
        return 1;
    }
    const protocol: nv.R4NvDriverProfile = .{ .version = 1, .size = @sizeOf(nv.R4NvDriverProfile),
        .vendor_id = 0x10de, .copy_class = 0xc6b5, .rm_release = nv.rm_release, .command_abi = nv.command_abi,
        .reserved0 = 0, .reserved1 = 0 };
    output.* = .{ .binding = binding(), .memory_generation = 31, .operations = 1 << a.gfx_queue_operation_native,
        .profile = .{ .interface_id_lo = nv.backend_v1_header.interface_id_lo, .interface_id_hi = nv.backend_v1_header.interface_id_hi,
            .revision = 1, .data_bytes = @sizeOf(nv.R4NvDriverProfile) } };
    @memcpy(output.profile.data[0..@sizeOf(nv.R4NvDriverProfile)], std.mem.asBytes(&protocol));
    return 1;
}
fn properties(input: *const a.GfxBackendBinding, output: *a.GfxBackendProperties) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(input.*, binding()));
    if (model.provider == .amd) {
        var value = std.mem.zeroes(amd.R4AmdDeviceFactsV3);
        const facts = &value.facts;
        facts.version = 1; facts.size = @sizeOf(amd.R4AmdDeviceFacts);
        facts.architecture = .{ .version = 1, .size = @sizeOf(amd.R4AmdArchitecture), .vendor_id = amd.vendor_id,
            .device_id = 0x15d8, .gc_version = if (model.raven2) amd.gc_9_2_2 else amd.gc_9_1_0,
            .sdma_version = if (model.raven2 and !model.wrong_amd_profile) amd.sdma_4_1_1 else amd.sdma_4_1_0,
            .gb_addr_config = if (model.raven2) 0x26013041 else 0x24000042,
            .chip_revision = if (model.raven2) 0x82 else 0x42, .bind_alignment = 4096, .memory_generation = 31,
            .flags = 0, .reserved = 0, .max_image_bytes = 64 * 1024 * 1024 };
        facts.flags = 1 | @as(u32, if (model.coherent) 2 else 0) | @as(u32, if (model.media_ready) 4 else 0) | @as(u32, if (model.jpeg_ready) 8 else 0);
        facts.va_start = amd.native_va_start; facts.va_end = amd.native_va_end;
        value.native_binding_capacity = 32; value.max_backing_bytes = 1024 * 1024 * 1024;
        output.* = .{ .interface_id_lo = amd.image_v1_header.interface_id_lo, .interface_id_hi = amd.image_v1_header.interface_id_hi,
            .revision = 3, .data_bytes = @sizeOf(amd.R4AmdDeviceFactsV3) };
        @memcpy(output.data[0..@sizeOf(amd.R4AmdDeviceFactsV3)], std.mem.asBytes(&value));
        return 1;
    }
    var arch = std.mem.zeroes(nv.R4NvArchitecture);
    arch.version = nv.architecture_version;
    arch.size = @sizeOf(nv.R4NvArchitecture);
    arch.vendor_id = 0x10de;
    arch.chipset = model.class_chip;
    arch.rm_release = nv.rm_release;
    arch.flags = nv.architecture_image_layouts | @as(u32, if (model.coherent) nv.architecture_host_coherent else 0);
    arch.bind_alignment = 65536;
    arch.va_start = 65536;
    arch.va_end = 1 << 49;
    arch.memory_generation = 31;
    if (model.graphics) {
        arch.graphics_class = if (model.class_chip == 0x174) 0xc797 else 0xc997;
        arch.shader_model = if (model.class_chip == 0x174) 86 else 89;
    }
    // Deliberately no GR topology/template: it is not NVDEC admission.
    output.* = .{ .interface_id_lo = nv.backend_v1_header.interface_id_lo, .interface_id_hi = nv.backend_v1_header.interface_id_hi,
        .revision = nv.architecture_version, .data_bytes = @sizeOf(nv.R4NvArchitecture) };
    @memcpy(output.data[0..@sizeOf(nv.R4NvArchitecture)], std.mem.asBytes(&arch));
    return 1;
}
fn create(input: *const a.GfxBufferDescriptor, output: *a.GfxBufferReference) callconv(.c) i32 {
    for (&model.bos, 0..) |*bo, i| if (!bo.live) {
        bo.* = .{ .descriptor = input.*, .live = true, .references = 1 };
        if (input.location == a.gfx_buffer_location_system)
            bo.data = t.allocator.alignedAlloc(u8, .fromByteUnits(65536), @intCast(input.byte_length)) catch return -7;
        output.* = .{ .buffer = handle(i), .reference = handle(i) };
        return 1;
    };
    return -9;
}
fn describe(input: *const a.GfxBufferHandle, output: *a.GfxBufferDescriptor) callconv(.c) i32 {
    const i = index(input, model.bos.len) orelse return -3;
    if (!model.bos[i].live) return -3;
    output.* = model.bos[i].descriptor;
    return 1;
}
fn release(input: *const a.GfxBufferHandle) callconv(.c) i32 {
    const bo = &model.bos[index(input, model.bos.len) orelse return -3];
    if (bo.live and bo.references > 1) { bo.references -= 1; return 1; }
    std.debug.assert(bo.live and !bo.mapped);
    for (&model.vas) |*va| std.debug.assert(!va.live or !std.meta.eql(va.request.reference, input.*));
    if (bo.data) |data| t.allocator.free(data);
    bo.* = .{};
    return 1;
}
fn importBo(input: *const a.GfxBufferHandle, output: *a.GfxBufferReference) callconv(.c) i32 {
    const bo = &model.bos[index(input, model.bos.len) orelse return -3];
    if (!bo.live) return -3;
    bo.references += 1;
    output.* = .{ .reference = input.*, .buffer = input.*, .flags = a.gfx_buffer_reference_immutable };
    return 1;
}
fn map(input: *const a.GfxBufferHandle, access: u32, offset: u64, bytes: u64, output: *a.GfxBufferMap) callconv(.c) i32 {
    const bo = &model.bos[index(input, model.bos.len) orelse return -3];
    std.debug.assert(bo.live and !bo.mapped and access == 1 and offset == 0 and bytes == bo.descriptor.byte_length);
    bo.mapped = true;
    output.* = .{ .lease = input.*, .cpu_address = @intFromPtr(bo.data.?.ptr), .byte_length = bytes, .cache_policy = a.gfx_buffer_cache_write_back };
    if (model.map_invalid) output.byte_length -= 1;
    return 1;
}
fn unmap(input: *const a.GfxBufferHandle) callconv(.c) i32 {
    const bo = &model.bos[index(input, model.bos.len) orelse return -3];
    std.debug.assert(bo.mapped);
    if (model.unmap_busy) return a.gfx_buffer_error_busy;
    bo.mapped = false;
    return 1;
}
fn nativeStart(input: *const a.GfxNativeAllocation, output: *a.GfxNativeStatus) callconv(.c) i32 {
    std.debug.assert(!model.pending_live and input.adapter_id == 9 and input.memory_generation == 31);
    model.pending = input.*;
    model.pending_live = true;
    output.* = .{ .request = handle(100), .phase = 0, .deadline_ns = input.deadline_ns };
    return 1;
}
fn nativeWait(input: *const a.GfxBufferHandle, ticks: u64, output: *a.GfxNativeStatus) callconv(.c) i32 {
    std.debug.assert(model.pending_live and input.id == 101 and ticks > 0 and ticks <= 500);
    if (model.native_timeout) return -11;
    output.* = .{ .request = input.*, .phase = 2, .result = 1, .deadline_ns = model.pending.deadline_ns, .completed_ns = 2_000_000 };
    return 1;
}
fn nativeReceive(input: *const a.GfxBufferHandle, output: *a.GfxBufferReference) callconv(.c) i32 {
    std.debug.assert(model.pending_live and input.id == 101);
    const request = model.pending;
    model.pending_live = false;
    var descriptor: a.GfxBufferDescriptor = .{ .location = a.gfx_buffer_location_device_local,
        .adapter_id = 9, .driver_owner = 2, .device_generation = 31, .alignment = 65536,
        .byte_length = request.byte_length, .usage = request.usage };
    if (request.kind == 1) {
        const amd_layout = if (model.provider == .amd) media.Surface.plan(request.width, request.height,
            if (request.format == a.gfx_buffer_format_p010) 10 else 8) catch return -2 else null;
        const pitch: u64 = if (amd_layout) |layout| layout.pitch else std.mem.alignForward(u64, request.width, 64);
        const luma = pitch * std.mem.alignForward(u64, request.height, 16);
        const offset = std.mem.alignForward(u64, luma, 65536);
        descriptor.modifier = if (amd_layout != null) 0 else 0x0300000000606011;
        descriptor.width = request.width;
        descriptor.height = request.height;
        descriptor.format = request.format;
        descriptor.plane_count = 2;
        descriptor.plane_pitches = .{ pitch, pitch, 0, 0 };
        descriptor.plane_offsets = .{ 0, offset, 0, 0 };
        descriptor.byte_length = std.mem.alignForward(u64, offset + pitch * std.mem.alignForward(u64, request.height / 2, 16), 65536);
    }
    return create(&descriptor, output);
}
fn nativeClose(input: *const a.GfxBufferHandle) callconv(.c) i32 {
    std.debug.assert(model.pending_live and input.id == 101);
    model.pending_live = false;
    return 1;
}
fn virtualStart(input: *const a.GfxVirtualRequest, output: *a.GfxVirtualStatus) callconv(.c) i32 {
    std.debug.assert(input.adapter_id == 9 and input.memory_generation == 31 and input.fixed_address == 0);
    for (&model.vas, 0..) |*va, i| if (!va.live) {
        const address = if (input.kind == 1) model.next_va else model.vas[index(&input.parent, model.vas.len).?].status.address;
        if (input.kind == 1) model.next_va += input.byte_length;
        va.* = .{ .live = true, .request = input.*, .status = .{ .resource = handle(i), .parent = input.parent,
            .kind = input.kind, .address = address, .byte_length = input.byte_length, .deadline_ns = input.deadline_ns, .flags = 1, .result = 1 } };
        output.* = va.status;
        return 1;
    };
    return -9;
}
fn virtualWait(input: *const a.GfxBufferHandle, until: u32, ticks: u64, output: *a.GfxVirtualStatus) callconv(.c) i32 {
    const va = &model.vas[index(input, model.vas.len) orelse return -3];
    std.debug.assert(va.live and until <= 1 and ticks > 0 and ticks <= 500);
    if (until == 1) {
        model.retire_ready = true;
        return virtualQuery(input, output);
    }
    if (model.bind_timeout and va.request.kind == 2) return -11;
    output.* = va.status;
    return 1;
}
fn virtualQuery(input: *const a.GfxBufferHandle, output: *a.GfxVirtualStatus) callconv(.c) i32 {
    const va = &model.vas[index(input, model.vas.len) orelse return -3];
    std.debug.assert(va.live);
    if (va.status.flags & 4 != 0 and model.retire_ready and model.queue_released) va.status.flags = 7;
    output.* = va.status;
    return 1;
}
fn virtualClose(input: *const a.GfxBufferHandle, mode: u32) callconv(.c) i32 {
    const va = &model.vas[index(input, model.vas.len) orelse return -3];
    std.debug.assert(va.live and va.request.kind == 1);
    if (mode == 0) {
        va.status.flags = 5;
    } else {
        std.debug.assert(va.status.flags == 7);
        for (&model.vas) |*child| if (child.live and std.meta.eql(child.request.parent, input.*)) { child.* = .{}; };
        va.* = .{};
    }
    return 1;
}
fn queueOpen(input: *const a.GfxQueueConfig, output: *a.GfxQueueHandle) callconv(.c) i32 {
    std.debug.assert(input.adapter_id == 9 and input.milestone == 1 and input.capacity == 1);
    output.* = .{ .timeline = model.next_timeline };
    model.next_timeline += 1;
    model.queue_count += 1;
    model.queue_closed = false;
    return 1;
}
fn fenceStatus() a.GfxFenceStatus {
    return .{ .fence = model.fence, .phase = if (model.queue_released) 2 else 1,
        .result = if (model.queue_released) 1 else 0, .flags = if (model.queue_released) 0 else 3,
        .milestone = 1, .deadline_ns = model.deadline_ns, .completed_ns = if (model.queue_released) 2_000_000 else 0 };
}
fn submit(input: *const a.GfxQueueHandle, common: *const a.GfxSubmission, native: *const a.GfxNativeSubmission, output: *a.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(input.timeline >= 91 and input.timeline < model.next_timeline and common.operation == a.gfx_queue_operation_native and
        native.command_bytes == 48 and native.resource_count > 0 and native.resource_count <= 64 and model.fence_released);
    var push_address: u64 = undefined;
    var push_bytes: u32 = undefined;
    if (model.provider == .amd) {
        const header: *const amd.R4AmdNativeSubmit = @ptrFromInt(native.commands);
        const ib: *const amd.R4AmdNativeIb = @ptrFromInt(native.commands + 32);
        std.debug.assert(native.interface_id_lo == amd.backend_v1_header.interface_id_lo and
            native.interface_id_hi == amd.backend_v1_header.interface_id_hi and native.resource_count <= 32 and
            header.engine == @as(u32, if (model.engine == .jpeg) 4 else if (model.engine == .decode) 2 else 3) and header.ib_count == 1 and
            ib.binding_index == 0 and ib.dwords > 0 and ib.dwords % 16 == 0 and ib.dwords <= 2048);
        push_address = ib.address; push_bytes = ib.dwords * 4;
    } else {
        const header: *const nv.R4NvNativeSubmitHeader = @ptrFromInt(native.commands);
        const push: *const nv.R4NvNativePush = @ptrFromInt(native.commands + 32);
        const engine_matches = if (model.mixed_engines) header.engine_mask == 1 or header.engine_mask == 16 else header.engine_mask == model.engine.mask();
        std.debug.assert(engine_matches and header.push_count == 1);
        push_address = push.address; push_bytes = push.byte_length;
    }
    std.debug.assert(model.push_bytes == 0 or push_bytes == model.push_bytes);
    const loans: [*]const a.GfxNativeResource = @ptrFromInt(native.resources);
    model.loan_count = native.resource_count;
    @memcpy(model.loans[0..model.loan_count], loans[0..model.loan_count]);
    for (model.loans[0..model.loan_count]) |loan| {
        const va = &model.vas[index(&loan.binding, model.vas.len).?];
        std.debug.assert(va.live and va.request.kind == 2 and va.status.flags == 1);
    }
    if (model.provider == .amd and model.engine == .jpeg) {
        const va = &model.vas[index(&loans[0].binding, model.vas.len).?];
        std.debug.assert(!model.bos[index(&va.request.reference, model.bos.len).?].mapped);
    }
    if (model.on_submit) |inspect| inspect(virtualBytes(push_address)[0..push_bytes]);
    model.fence = .{ .adapter_id = 9, .timeline = input.timeline, .point = 1, .device_generation = 23, .reset_generation = 7 };
    model.fence_released = false;
    model.queue_released = !model.queue_timeout;
    model.deadline_ns = common.deadline_ns;
    output.* = fenceStatus();
    return 1;
}
fn fenceWait(input: *const a.GfxFence, ticks: u64, until: u32, output: *a.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(input.*, model.fence) and until == 1 and ticks > 0 and ticks <= 500);
    if (model.queue_timeout) return -11;
    output.* = fenceStatus();
    return 1;
}
fn fenceQuery(input: *const a.GfxFence, output: *a.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(input.*, model.fence) and !model.fence_released);
    if (model.fence_query_result != a.gfx_queue_ok) return model.fence_query_result;
    output.* = fenceStatus();
    return 1;
}
fn fenceCancel(input: *const a.GfxFence) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(input.*, model.fence) and !model.fence_released);
    model.cancel_count += 1;
    return 1;
}
fn fenceRelease(input: *const a.GfxFence) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(input.*, model.fence) and model.queue_released and !model.fence_released);
    model.fence_released = true;
    return 1;
}
fn queueClose(input: *const a.GfxQueueHandle) callconv(.c) i32 {
    std.debug.assert(input.timeline >= 91 and input.timeline < model.next_timeline and !model.queue_closed and
        (model.fence_released or input.timeline != model.fence.timeline));
    if (model.queue_close_result != a.gfx_queue_ok and model.queue_close_result != a.gfx_queue_error_stale)
        return model.queue_close_result;
    // Stale models a reset that has already removed this exact empty queue.
    // An outstanding client fence must still be observed/released separately.
    model.queue_count -= 1;
    model.queue_closed = model.queue_count == 0;
    return model.queue_close_result;
}
pub fn word(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}
pub fn virtualBytes(address: u64) []u8 {
    for (&model.vas) |*va| if (va.live and va.request.kind == 2 and address >= va.status.address and
        address - va.status.address < va.status.byte_length)
    {
        const bo = &model.bos[index(&va.request.reference, model.bos.len).?];
        return bo.data.?[@intCast(address - va.status.address)..];
    };
    @trap();
}

pub fn install(table: *a.R4XStartR4Draw) void {
    inline for (.{
        .{ "gfx_queue_backend_info", &backend }, .{ "gfx_queue_backend_properties", &properties },
        .{ "gfx_buffer_create", &create }, .{ "gfx_buffer_describe", &describe }, .{ "gfx_buffer_release", &release },
        .{ "gfx_buffer_import", &importBo },
        .{ "gfx_buffer_map_persistent", &map }, .{ "gfx_buffer_unmap", &unmap },
        .{ "gfx_native_start", &nativeStart }, .{ "gfx_native_wait", &nativeWait }, .{ "gfx_native_receive", &nativeReceive }, .{ "gfx_native_close", &nativeClose },
        .{ "gfx_virtual_start", &virtualStart }, .{ "gfx_virtual_wait", &virtualWait }, .{ "gfx_virtual_query", &virtualQuery }, .{ "gfx_virtual_close", &virtualClose },
        .{ "gfx_queue_open", &queueOpen }, .{ "gfx_queue_close", &queueClose }, .{ "gfx_queue_submit_native", &submit },
        .{ "gfx_fence_wait", &fenceWait }, .{ "gfx_fence_query", &fenceQuery }, .{ "gfx_fence_cancel", &fenceCancel }, .{ "gfx_fence_release", &fenceRelease },
    }) |field| @field(table.*, field[0]) = @intFromPtr(field[1]);
}
