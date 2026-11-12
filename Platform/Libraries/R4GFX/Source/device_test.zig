//! Focused device integration inside the existing R4GFX provider test.
//! Kernel callbacks below model ownership/retirement; R4NV negotiation and
//! the CPU renderer are the actual providers, not test substitutes.
const std = @import("std");
const t = std.testing;
const a = @import("r4os").abi;
const nv = @import("r4nv_binding");
const nv_provider = @import("r4nv_backend");
const amd = @import("r4amd_binding");
const amd_provider = @import("r4amd_providers").backend;
const amd_images = @import("r4amd_providers").images;
const d = @import("device.zig");
const c = d.c;
const api = &@import("main.zig").r4gfx_device_v1;
const Model = struct {
    const Object = struct { bytes: [131072]u8 align(8) = @splat(0), descriptor: a.GfxBufferDescriptor = .{}, live: bool = false };
    const Ref = struct { object: ?usize = null, generation: u64 = 0, mapped: bool = false };
    const Queue = struct { handle: a.GfxQueueHandle = .{}, config: a.GfxQueueConfig = .{} };
    var objects: [4]Object = @splat(.{});
    var references: [16]Ref = @splat(.{});
    var queues: [4]Queue = @splat(.{});
    var serial: u64 = 0x100000000;
    var exports: usize = 0;
    var maps: usize = 0;
    var fail_unmap = false;
    var premature_closes: usize = 0;
    var inventory_reads: usize = 0;
    var adapters: ?[]const a.GfxBackendInfo = null;
    var reject_adapter: u32 = 0;
    var status: a.GfxFenceStatus = .{};
    var job_live = false;
    var retain_completed = false;
    var completed: [c.device_job_capacity]?a.GfxFenceStatus = @splat(null);
    var submit_error: i32 = 0;
    var job_request: a.GfxSubmission = .{};
    var job_list: a.GfxRenderList = .{};
    var job_grid_list: a.GfxRenderGridList = .{};
    var job_color_list: a.GfxRenderColorList = .{};
    var operations: u64 = 7;
    var dependency_seen = false;
    var native_request: a.GfxNativeAllocation = .{};
    var native_handle: a.GfxBufferHandle = .{};
    var native_result: i32 = 1;
    var native_starts: usize = 0;
    var bad_native_layout = false;
    var clock: u64 = 100;
    var submit_serial: u64 = 0x400000017;
    var presentation_info: a.DisplayPresentationInfo = .{};
    var feedback: ?a.DisplayPresentationStats = null;
    var shown: [16]u32 = @splat(0xabcdef);
    var present_calls: u64 = 0;
    var fail_present = false;
    var retire_requested = false;
    const Output = struct { target: a.GfxOutputTarget = .{}, info: a.DisplayPresentationInfo = .{},
        status: a.GfxFenceStatus = .{}, request: a.GfxSubmission = .{}, live: bool = false, connected: bool = true };
    var outputs: [2]Output = @splat(.{});
    var output_color: a.GfxOutputColorState = .{};
    fn outputColor(identity: *const a.GfxOutputId, out: *a.GfxOutputColorState) callconv(.c) i32 {
        if (!std.meta.eql(identity.*, output_color.identity)) return a.gfx_output_error_stale;
        out.* = output_color; return a.gfx_output_ok;
    }
    var binding: a.GfxBackendBinding = .{ .adapter_id = 9, .milestone = 1, .device_generation = 0x200000017, .reset_generation = 0x300000017 };
    var nv_table: nv.BackendV1 = .{ .header = nv.backend_v1_header,
        .negotiate = @ptrCast(&nv_provider.r4nv_negotiate_impl), .encode_copy = @ptrCast(&nv_provider.r4nv_encode_copy_impl),
        .encode_copy_layout = @ptrCast(&nv_provider.r4nv_encode_copy_layout_impl),
        .image_layout = @ptrCast(&nv_provider.r4nv_image_layout_impl) };
    const encoder = @import("r4nv_render_encoder");
    var nv_render: nv.RenderV1 = .{ .header = nv.render_v1_header,
        .render_info = @ptrCast(&encoder.r4nv_render_info_impl), .render_upload = @ptrCast(&encoder.r4nv_render_upload_impl),
        .encode_yuv = @ptrCast(&encoder.r4nv_encode_yuv_impl) };
    const Virtual = struct { request: a.GfxVirtualRequest = .{}, handle: a.GfxBufferHandle = .{}, address: u64 = 0, closing: bool = false };
    var virtuals: [16]Virtual = @splat(.{});
    var virtual_starts: usize = 0;
    var virtual_closes: usize = 0;
    var virtual_ack = false;
    var virtual_reject_object: ?usize = null;
    var retire_ack = false;
    const AmdPacket = extern struct { header: amd.R4AmdYuvHeader, color: [64]u32, matrix: [3][4]f32 };
    var amd_packet: AmdPacket = undefined;
    var raven2 = false;
    var amd_properties_revision: u32 = 1;
    var amd_properties_short = false;
    fn properties(input: *const a.GfxBackendBinding, out: *a.GfxBackendProperties) callconv(.c) i32 {
        if (input.adapter_id == 3) {
            const arch: amd.R4AmdArchitecture = .{ .version=1,.size=@sizeOf(amd.R4AmdArchitecture),.vendor_id=amd.vendor_id,.device_id=0x15d8,
                .gc_version=if (raven2) amd.gc_9_2_2 else amd.gc_9_1_0,.sdma_version=if (raven2) amd.sdma_4_1_1 else amd.sdma_4_1_0,
                .gb_addr_config=if (raven2) 0x26013041 else 0x24000042,.chip_revision=if (raven2) 0x82 else 0x41,
                .bind_alignment=4096,.memory_generation=97,.flags=0,.reserved=0,.max_image_bytes=64*1024*1024 };
            out.*=.{ .interface_id_lo=amd.image_v1_header.interface_id_lo,.interface_id_hi=amd.image_v1_header.interface_id_hi,
                .revision=amd_properties_revision,.data_bytes=if (amd_properties_revision == 1) @sizeOf(amd.R4AmdArchitecture) else @sizeOf(amd.R4AmdDeviceFacts) };
            if (amd_properties_short) out.data_bytes -= 1;
            @memcpy(out.data[0..@sizeOf(amd.R4AmdArchitecture)],std.mem.asBytes(&arch)); return 1;
        }
        std.debug.assert(std.meta.eql(input.*, binding));
        var arch = std.mem.zeroes(nv.R4NvArchitecture);
        arch.version = nv.architecture_version; arch.size = @sizeOf(nv.R4NvArchitecture);
        arch.vendor_id = 0x10de; arch.rm_release = nv.rm_release; arch.graphics_class = 0xc797; arch.shader_model = 86;
        arch.memory_generation = 73; arch.va_start = 0x10000000; arch.va_end = 0x20000000; arch.bind_alignment = 65536;
        arch.flags = nv.architecture_host_coherent | nv.architecture_image_layouts;
        out.* = .{ .interface_id_lo = nv.backend_v1_header.interface_id_lo, .interface_id_hi = nv.backend_v1_header.interface_id_hi,
            .revision = nv.architecture_version, .data_bytes = @sizeOf(nv.R4NvArchitecture) };
        @memcpy(out.data[0..@sizeOf(nv.R4NvArchitecture)], std.mem.asBytes(&arch));
        return 1;
    }
    fn virtualNode(handle: a.GfxBufferHandle) *Virtual {
        for (&virtuals) |*entry| if (std.meta.eql(entry.handle, handle)) return entry;
        unreachable;
    }
    fn virtualStart(input: *const a.GfxVirtualRequest, out: *a.GfxVirtualStatus) callconv(.c) i32 {
        std.debug.assert(input.adapter_id == binding.adapter_id and input.memory_generation == @as(u64, if (binding.adapter_id == 3) 97 else 73) and input.kind >= 1 and input.kind <= 2);
        for (&virtuals, 0..) |*entry, i| if (entry.handle.id == 0) {
            serial += 1; virtual_starts += 1;
            entry.* = .{ .request = input.*, .handle = .{ .id = @intCast(1000+i), .generation = serial },
                .address = if (input.kind == 1) (if (binding.adapter_id == 3) amd.native_va_start + i * 64 * 1024 * 1024 else 0x10000000 + i * 0x20000) else virtualNode(input.parent).address };
            if (input.kind == 2) _ = ref(input.reference);
            return virtualQuery(&entry.handle, out);
        };
        return a.gfx_buffer_error_capacity;
    }
    fn virtualQuery(input: *const a.GfxBufferHandle, out: *a.GfxVirtualStatus) callconv(.c) i32 {
        const entry = virtualNode(input.*);
        const rejected = entry.request.kind == 2 and virtual_reject_object != null and
            ref(entry.request.reference).object.? == virtual_reject_object.?;
        out.* = .{ .resource = entry.handle, .parent = entry.request.parent, .kind = entry.request.kind,
            .byte_length = entry.request.byte_length, .deadline_ns = entry.request.deadline_ns,
            // The real common owner publishes its active driver claim before
            // the asynchronous create result. Flag 8/result 0 is pending.
            .flags = if (entry.closing) (if (retire_ack) @as(u32,7) else 3) else (if (rejected) @as(u32,7) else if (virtual_ack) @as(u32,1) else 8),
            .result = if (rejected) a.gfx_buffer_error_unsupported else if (virtual_ack) 1 else 0,
            .address = if (virtual_ack and !rejected) entry.address else 0 };
        return 1;
    }
    fn virtualClose(input: *const a.GfxBufferHandle, flags: u32) callconv(.c) i32 {
        const entry = virtualNode(input.*);
        std.debug.assert(!job_live and entry.request.kind == 1);
        if (flags == 0) { entry.closing = true; virtual_closes += 1; return 1; }
        std.debug.assert(flags == 1 and retire_ack and entry.closing);
        for (&virtuals) |*child| if (std.meta.eql(child.request.parent, input.*)) { child.* = .{}; };
        entry.* = .{};
        return 1;
    }
    fn mapPersistent(input: *const a.GfxBufferHandle, access: u32, offset: u64, bytes: u64, out: *a.GfxBufferMap) callconv(.c) i32 {
        const rc = map(input, access, offset, bytes, out);
        out.cache_policy = a.gfx_buffer_cache_write_back;
        return rc;
    }
    fn submitNative(queue: *const a.GfxQueueHandle, input: *const a.GfxSubmission, native: *const a.GfxNativeSubmission, out: *a.GfxFenceStatus) callconv(.c) i32 {
        if (binding.adapter_id == 3) {
            // The real canonical queue compares its registered BACKEND profile,
            // not the unrelated R4L encoder interface identity.
            std.debug.assert(input.operation == a.gfx_queue_operation_native and native.resource_count == 2 and native.command_bytes == 504);
            var backend: a.GfxBackendInfo = .{};
            std.debug.assert(backendInfo(1, &backend) == 1);
            if (native.interface_id_lo != backend.profile.interface_id_lo or native.interface_id_hi != backend.profile.interface_id_hi or native.revision != backend.profile.revision)
                return a.gfx_queue_error_unsupported;
            amd_packet = @as(*const AmdPacket, @ptrFromInt(native.commands)).*;
            const loans = @as([*]const a.GfxNativeResource, @ptrFromInt(native.resources))[0..native.resource_count];
            for (loans, 0..) |loan, i| {
                const entry = virtualNode(loan.binding);
                std.debug.assert(entry.request.kind == 2 and !entry.closing and entry.request.flags == 0 and loan.access == @intFromBool(i == 1));
                _ = ref(entry.request.reference);
            }
            return submit(queue, input, out);
        }
        std.debug.assert(input.operation == a.gfx_queue_operation_native and native.resource_count == 3 and native.command_bytes == 48);
        const header: *const nv.R4NvNativeSubmitHeader = @ptrFromInt(native.commands);
        const push: *const nv.R4NvNativePush = @ptrFromInt(native.commands + 32);
        std.debug.assert(header.engine_mask == nv.native_engine_graphics and header.push_count == 1 and push.byte_length > 0 and push.byte_length <= 4096);
        const loans = @as([*]const a.GfxNativeResource,@ptrFromInt(native.resources))[0..native.resource_count];
        for (loans, 0..) |loan, i| {
            const entry = virtualNode(loan.binding);
            std.debug.assert(entry.request.kind == 2 and !entry.closing and loan.access == @intFromBool(i == 2));
            _ = ref(entry.request.reference);
        }
        const upload = virtualNode(loans[0].binding);
        const object = &objects[ref(upload.request.reference).object.?];
        std.debug.assert(object.descriptor.location == 0 and push.address >= upload.address and push.address + push.byte_length <= upload.address + object.descriptor.byte_length);
        var info: nv.R4NvRenderInfo = undefined;
        std.debug.assert(nv_render.render_info(0xc797, &info) == nv.status_ok);
        const packet = std.mem.alignForward(usize, info.program_bytes, 256);
        std.debug.assert(std.mem.readInt(u32, object.bytes[packet..][0..4], .little) == 0x6010021d and
            std.mem.readInt(u32, object.bytes[packet+32..][0..4], .little) == 0x60d01218 and
            std.mem.readInt(u32, object.bytes[packet+256..][0..4], .little) == 1 and
            std.mem.readInt(u32, object.bytes[packet+332..][0..4], .little) == 0);
        return submit(queue, input, out);
    }

    fn reset() void {
        retain_completed = false; completed = @splat(null); submit_error = 0;
        objects = @splat(.{}); references = @splat(.{}); queues = @splat(.{});
        serial = 0x100000000; exports = 0; maps = 0; fail_unmap = false; premature_closes = 0; inventory_reads = 0; job_live = false;
        binding = .{ .adapter_id = 9, .milestone = 1, .device_generation = 0x200000017, .reset_generation = 0x300000017 };
        nv_table.header = nv.backend_v1_header;
        operations = 7; adapters = null; dependency_seen = false; job_list = .{}; job_grid_list = .{}; job_color_list = .{};
        native_request = .{}; native_handle = .{}; native_result = 1;
        native_starts = 0; bad_native_layout = false;
        clock = 100; submit_serial = 0x400000017; feedback = null; shown = @splat(0xabcdef); present_calls = 0; fail_present = false;
        retire_requested = false;
        outputs = @splat(.{});
        virtuals = @splat(.{}); virtual_starts = 0; virtual_closes = 0; virtual_ack = false; virtual_reject_object = null; retire_ack = false;
        presentation_info = .{ .flags = a.display_presentation_info_active, .head_id = 2, .display_generation = 1,
            .sequence = 1, .width = 4, .height = 4, .format = c.format_xrgb8888, .policies = 7, .buffer_count = 2, .plane_count = 1 };
    }
    fn monotonic(out: *a.MonotonicClockInfo) callconv(.c) i32 {
        clock += 10;
        out.* = .{ .flags = a.monotonic_clock_flag_valid, .instant_ns = clock }; return 1;
    }
    fn presentInfo(head: u32, out: *a.DisplayPresentationInfo) callconv(.c) i32 {
        if (head != presentation_info.head_id) return a.gfx_output_error_unsupported;
        out.* = presentation_info; return a.gfx_output_ok;
    }
    fn presentFeedback(head: u32, source: *const a.GfxFence, out: *a.DisplayPresentationStats) callconv(.c) i32 {
        const value = feedback orelse return a.gfx_output_error_unsupported;
        if (head != value.head_id or source.adapter_id != value.backend.adapter_id or source.device_generation != value.backend.device_generation or
            source.reset_generation != value.backend.reset_generation or source.timeline != value.source_timeline or source.point != value.source_point) return a.gfx_output_error_unsupported;
        out.* = value; return a.gfx_output_ok;
    }
    fn outputTarget(adapter: u32, head: u32, out: *a.GfxOutputTarget) callconv(.c) i32 {
        for (&outputs) |*output| if (output.connected and output.target.connector_id != 0 and output.target.adapter_id == adapter and output.target.head_id == head) {
            out.* = output.target; return a.gfx_output_ok;
        };
        return a.gfx_output_error_unsupported;
    }
    fn outputInfo(target: *const a.GfxOutputTarget, out: *a.DisplayPresentationInfo) callconv(.c) i32 {
        for (&outputs) |*output| if (output.connected and std.meta.eql(output.target, target.*)) {
            out.* = output.info; return a.gfx_output_ok;
        };
        return a.gfx_output_error_stale;
    }
    fn submitOutput(handle: *const a.GfxQueueHandle, request: *const a.GfxSubmission, target: *const a.GfxOutputTarget, out: *a.GfxFenceStatus) callconv(.c) i32 {
        for (&outputs, 0..) |*output, index| if (output.connected and std.meta.eql(output.target, target.*)) {
            if (output.live) return a.gfx_queue_error_busy;
            const queue = for (&queues) |*candidate| { if (candidate.handle.timeline == handle.timeline) break candidate; } else unreachable;
            std.debug.assert(queue.config.adapter_id == target.adapter_id and request.operation == a.gfx_queue_operation_present);
            submit_serial += 1;
            output.status = .{ .fence = .{ .slot = @intCast(index + 2), .timeline = handle.timeline, .point = submit_serial,
                .adapter_id = queue.config.adapter_id, .device_generation = queue.config.device_generation, .reset_generation = queue.config.reset_generation },
                .phase = a.gfx_queue_phase_running, .flags = a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held,
                .milestone = queue.config.milestone };
            output.request = request.*; output.live = true; out.* = output.status; return a.gfx_queue_ok;
        };
        return a.gfx_queue_error_stale;
    }
    fn presentPixels(request: *const a.DisplayPresentRequest, pixels: [*]const u32, pixel_count: u32,
        regions: [*]const a.DisplayDamageRect, region_count: u32, out: *a.DisplayPresentResult) callconv(.c) i32
    {
        std.debug.assert(request.source_width == presentation_info.width and request.source_height == presentation_info.height and
            region_count == 1 and regions[0].x == 0 and regions[0].y == 0 and regions[0].w == request.source_width and regions[0].h == request.source_height);
        if (fail_present) return a.display_present_error_unavailable;
        for (0..request.source_height) |y| for (0..request.source_width) |x| {
            const index = y * request.source_stride_pixels + x;
            std.debug.assert(index < pixel_count);
            shown[y * request.source_width + x] = pixels[index];
        };
        present_calls += 1;
        out.* = .{ .flags = a.display_present_result_success | a.display_present_result_completed,
            .source_generation = request.source_generation, .fence = present_calls, .completed_fence = present_calls };
        return 0;
    }
    fn ref(handle: a.GfxBufferHandle) *Ref {
        std.debug.assert(handle.id != 0 and handle.id <= references.len and handle.reserved0 == 0);
        const value = &references[handle.id - 1];
        std.debug.assert(value.object != null and value.generation == handle.generation);
        return value;
    }
    fn lend(index: usize, out: *a.GfxBufferReference, immutable: bool) i32 {
        std.debug.assert(out.version == 1 and out.size == 48);
        for (&references, 0..) |*value, i| if (value.object == null) {
            serial += 1;
            value.* = .{ .object = index, .generation = serial };
            out.* = .{ .buffer = .{ .id = @intCast(index + 100), .generation = 1 },
                .reference = .{ .id = @intCast(i + 1), .generation = serial }, .flags = if (immutable) a.gfx_buffer_reference_immutable else 0 };
            return 1;
        };
        return a.gfx_buffer_error_capacity;
    }
    fn create(input: *const a.GfxBufferDescriptor, out: *a.GfxBufferReference) callconv(.c) i32 {
        for (&objects, 0..) |*object, i| if (!object.live) {
            std.debug.assert(input.byte_length <= object.bytes.len);
            object.* = .{ .live = true, .descriptor = input.* };
            return lend(i, out, false);
        };
        return a.gfx_buffer_error_capacity;
    }
    fn describe(input: *const a.GfxBufferHandle, out: *a.GfxBufferDescriptor) callconv(.c) i32 {
        out.* = objects[ref(input.*).object.?].descriptor; return 1;
    }
    fn nativeStart(input: *const a.GfxNativeAllocation, out: *a.GfxNativeStatus) callconv(.c) i32 {
        std.debug.assert(native_handle.id == 0 and input.adapter_id == binding.adapter_id and
            input.memory_generation == @as(u64, if (binding.adapter_id == 3) 97 else 73) and input.kind == 1);
        serial += 1;
        native_starts += 1;
        native_request = input.*; native_handle = .{ .id = 1, .generation = serial };
        out.* = .{ .request = native_handle, .deadline_ns = input.deadline_ns };
        return 1;
    }
    fn nativeWait(input: *const a.GfxBufferHandle, ticks: u64, out: *a.GfxNativeStatus) callconv(.c) i32 {
        std.debug.assert(std.meta.eql(input.*, native_handle) and ticks == std.math.maxInt(u64));
        out.* = .{ .request = native_handle, .phase = 2, .result = native_result }; return 1;
    }
    fn nativeQuery(input: *const a.GfxBufferHandle, out: *a.GfxNativeStatus) callconv(.c) i32 {
        std.debug.assert(std.meta.eql(input.*, native_handle));
        out.* = .{ .request = native_handle, .phase = 2, .result = native_result }; return 1;
    }
    fn nativeReceive(input: *const a.GfxBufferHandle, out: *a.GfxBufferReference) callconv(.c) i32 {
        std.debug.assert(std.meta.eql(input.*, native_handle) and native_result == 1);
        if (binding.adapter_id == 3) {
            std.debug.assert(native_request.width == 4 and native_request.height == 4 and native_request.layout == 0);
            const rc = create(&.{ .byte_length = 4096, .alignment = 4096, .width = 4, .height = 4,
                .format = native_request.format, .plane_count = 1, .plane_pitches = .{256,0,0,0}, .usage = native_request.usage,
                .location = 1, .adapter_id = 3, .device_generation = 97, .driver_owner = 80 }, out);
            if (rc == 1) native_handle = .{};
            return rc;
        }
        // This bounded fixture uses4x4 images with the actual native storage
        // geometry. A tiled view is one GOB; the image allocation is64KB.
        std.debug.assert(native_request.width == 4 and native_request.height == 4 and native_request.layout <= 1);
        const modifier: u64 = if (bad_native_layout) 1 else if (native_request.layout == 1) 0x0300000000606010 else 0;
        const rc = create(&.{ .byte_length = 65536, .alignment = 65536, .modifier = modifier,
            .width = native_request.width, .height = native_request.height, .format = native_request.format,
            .plane_count = 1, .plane_pitches = .{if (native_request.layout == 1) 64 else 256, 0, 0, 0}, .usage = native_request.usage, .location = 1,
            .adapter_id = binding.adapter_id, .device_generation = 73, .driver_owner = 79 }, out);
        if (rc == 1) native_handle = .{};
        return rc;
    }
    fn nativeClose(input: *const a.GfxBufferHandle) callconv(.c) i32 {
        std.debug.assert(std.meta.eql(input.*, native_handle)); native_handle = .{}; return 1;
    }
    fn import(input: *const a.GfxBufferHandle, out: *a.GfxBufferReference) callconv(.c) i32 {
        if (input.id == 0 or input.id > references.len or input.reserved0 != 0) return a.gfx_buffer_error_stale;
        const value = &references[input.id - 1];
        if (value.object == null or value.generation != input.generation) return a.gfx_buffer_error_stale;
        return lend(value.object.?, out, false);
    }
    fn release(input: *const a.GfxBufferHandle) callconv(.c) i32 {
        const value = ref(input.*); std.debug.assert(!value.mapped);
        const object = value.object.?; value.object = null;
        for (&references) |*other| if (other.object == object) return 1;
        objects[object].live = false; return 1;
    }
    fn map(input: *const a.GfxBufferHandle, access: u32, offset: u64, bytes: u64, out: *a.GfxBufferMap) callconv(.c) i32 {
        const value = ref(input.*);
        std.debug.assert(!value.mapped and access <= 1 and offset == 0 and bytes == objects[value.object.?].descriptor.byte_length);
        value.mapped = true; maps += 1;
        out.* = .{ .lease = input.*, .cpu_address = @intFromPtr(&objects[value.object.?].bytes), .byte_length = bytes };
        return 1;
    }
    fn unmap(input: *const a.GfxBufferHandle) callconv(.c) i32 {
        const value = ref(input.*); std.debug.assert(value.mapped);
        if (fail_unmap) return a.gfx_buffer_error_busy;
        value.mapped = false; return 1;
    }
    fn exportRaster(input: *const a.GuiSharedRasterLease, out: *a.GfxBufferReference) callconv(.c) i32 {
        std.debug.assert(input.handle.id == 0x100000011 and input.handle.generation == 0x200000011 and input.raster_generation == 7 and input.lease_token == 9);
        exports += 1;
        objects[3] = .{ .live = true, .descriptor = .{ .byte_length = 64, .width = 4, .height = 4, .format = c.format_xrgb8888,
            .plane_count = 1, .plane_pitches = .{ 16, 0, 0, 0 }, .usage = 5 } };
        return lend(3, out, true);
    }
    fn backendInfo(index: u32, out: *a.GfxBackendInfo) callconv(.c) i32 {
        inventory_reads += 1;
        if (adapters) |values| {
            if (index == 0 or index > values.len) return 0;
            out.* = values[index - 1]; return 1;
        }
        if (index != 1) return 0;
        out.* = .{ .binding = binding, .operations = operations, .memory_generation = 73, .profile = .{ .interface_id_lo = nv.backend_v1_header.interface_id_lo,
            .interface_id_hi = nv.backend_v1_header.interface_id_hi, .revision = 1, .data_bytes = 32 } };
        const details: nv.R4NvDriverProfile = .{ .version = 1, .size = 32, .vendor_id = 0x10de, .copy_class = 0xc6b5,
            .rm_release = nv.rm_release, .command_abi = nv.command_abi, .reserved0 = 0, .reserved1 = 0 };
        @memcpy(out.profile.data[0..32], std.mem.asBytes(&details)); return 1;
    }
    fn open(input: *const a.GfxQueueConfig, out: *a.GfxQueueHandle) callconv(.c) i32 {
        if (input.adapter_id != 0 and input.adapter_id == reject_adapter) return a.gfx_queue_error_device_lost;
        if (input.adapter_id != 0) {
            const valid = if (adapters) |values| blk: {
                for (values) |value| if (input.adapter_id == value.binding.adapter_id and
                    input.device_generation == value.binding.device_generation and input.reset_generation == value.binding.reset_generation) break :blk true;
                break :blk false;
            } else input.adapter_id == binding.adapter_id and input.device_generation == binding.device_generation and input.reset_generation == binding.reset_generation;
            std.debug.assert(valid);
        }
        for (&queues) |*queue| if (queue.handle.timeline == 0) {
            serial += 1; queue.* = .{ .handle = .{ .timeline = serial }, .config = input.* }; out.* = queue.handle; return 1;
        };
        return a.gfx_queue_error_capacity;
    }
    fn close(input: *const a.GfxQueueHandle) callconv(.c) i32 {
        for (&outputs) |*output| if (output.live and output.status.fence.timeline == input.timeline) { premature_closes += 1; return a.gfx_queue_error_busy; };
        if (job_live and status.fence.timeline == input.timeline) { premature_closes += 1; return a.gfx_queue_error_busy; }
        for (&queues) |*queue| if (queue.handle.timeline == input.timeline) { queue.* = .{}; return 1; };
        return a.gfx_queue_error_stale;
    }
    fn submit(queue: *const a.GfxQueueHandle, input: *const a.GfxSubmission, out: *a.GfxFenceStatus) callconv(.c) i32 {
        if (submit_error != 0) return submit_error;
        std.debug.assert((input.operation == a.gfx_queue_operation_copy or input.operation == a.gfx_queue_operation_copy_rows or
            input.operation == a.gfx_queue_operation_render or input.operation == a.gfx_queue_operation_render_list or input.operation == a.gfx_queue_operation_present or
            input.operation == a.gfx_queue_operation_direct_present or input.operation == a.gfx_queue_operation_render_grid_list or input.operation == a.gfx_queue_operation_render_color_list or input.operation == a.gfx_queue_operation_render_color_grid_list or input.operation == a.gfx_queue_operation_native) and input.dependency_count <= 1);
        if (input.dependency_count == 1) {
            std.debug.assert(job_live and std.meta.eql(input.dependencies[0], status.fence));
            dependency_seen = true;
        }
        if (job_live) return a.gfx_queue_error_busy;
        const found = for (&queues) |*entry| { if (entry.handle.timeline == queue.timeline) break entry; } else unreachable;
        submit_serial += 1;
        const receipt_slot: u32 = if (retain_completed) blk: {
            for (completed, 0..) |entry, i| if (entry == null) break :blk @intCast(i + 1);
            return a.gfx_queue_error_capacity;
        } else 1;
        status = .{ .fence = .{ .slot = receipt_slot, .timeline = queue.timeline, .point = submit_serial, .adapter_id = found.config.adapter_id,
            .device_generation = found.config.device_generation, .reset_generation = found.config.reset_generation },
            .phase = a.gfx_queue_phase_running, .flags = a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held, .milestone = found.config.milestone };
        job_request = input.*; job_live = true; out.* = status; return 1;
    }
    fn submitList(queue: *const a.GfxQueueHandle, input: *const a.GfxSubmission, list: *const a.GfxRenderList, out: *a.GfxFenceStatus) callconv(.c) i32 {
        std.debug.assert(input.operation == a.gfx_queue_operation_render_list and list.count > 0 and list.count <= 16);
        const rc = submit(queue, input, out);
        if (rc == a.gfx_queue_ok) job_list = list.*;
        return rc;
    }
    fn submitGridList(queue: *const a.GfxQueueHandle, input: *const a.GfxSubmission, list: *const a.GfxRenderGridList, out: *a.GfxFenceStatus) callconv(.c) i32 {
        std.debug.assert(input.operation == a.gfx_queue_operation_render_grid_list and list.count > 0 and list.count <= 16);
        const rc = submit(queue, input, out);
        if (rc == a.gfx_queue_ok) job_grid_list = list.*;
        return rc;
    }
    fn submitColorList(queue: *const a.GfxQueueHandle, input: *const a.GfxSubmission, list: *const a.GfxRenderColorList, out: *a.GfxFenceStatus) callconv(.c) i32 {
        std.debug.assert(input.operation == a.gfx_queue_operation_render_color_list and list.count > 0 and list.count <= 16);
        const rc = submit(queue, input, out);
        if (rc == a.gfx_queue_ok) job_color_list = list.*;
        return rc;
    }
    fn submitColorGridList(queue: *const a.GfxQueueHandle, input: *const a.GfxSubmission, list: *const a.GfxRenderColorGridList, out: *a.GfxFenceStatus) callconv(.c) i32 {
        std.debug.assert(input.operation == a.gfx_queue_operation_render_color_grid_list and list.count > 0 and list.count <= 16);
        const rc = submit(queue, input, out);
        if (rc == a.gfx_queue_ok) {
            job_color_list = .{ .count = list.count, .commands = list.commands, .program = list.program };
            job_grid_list = .{ .count = list.count, .commands = list.commands, .grids = list.grids };
        }
        return rc;
    }
    fn query(input: *const a.GfxFence, out: *a.GfxFenceStatus) callconv(.c) i32 {
        for (completed) |entry| if (entry) |value| if (std.meta.eql(input.*, value.fence)) { out.* = value; return a.gfx_queue_ok; };
        for (&outputs) |*output| if (output.live and std.meta.eql(input.*, output.status.fence)) { out.* = output.status; return a.gfx_queue_ok; };
        std.debug.assert(job_live and std.meta.eql(input.*, status.fence)); out.* = status; return 1;
    }
    fn cancel(input: *const a.GfxFence) callconv(.c) i32 {
        for (&outputs) |*output| if (output.live and std.meta.eql(input.*, output.status.fence)) {
            if (output.status.phase == a.gfx_queue_phase_terminal) return a.gfx_queue_error_already_completed;
            output.status.phase = a.gfx_queue_phase_terminal; output.status.result = a.gfx_queue_result_cancelled; return a.gfx_queue_ok;
        };
        std.debug.assert(job_live and std.meta.eql(input.*, status.fence));
        if (job_request.operation == a.gfx_queue_operation_direct_present and status.phase == a.gfx_queue_phase_terminal and status.flags != 0) {
            retire_requested = true; return a.gfx_queue_ok;
        }
        if (status.phase == a.gfx_queue_phase_terminal) return a.gfx_queue_error_already_completed;
        status.phase = a.gfx_queue_phase_terminal; status.result = a.gfx_queue_result_cancelled; return 1;
    }
    fn drop(input: *const a.GfxFence) callconv(.c) i32 {
        for (&completed) |*entry| if (entry.*) |value| if (std.meta.eql(input.*, value.fence)) { entry.* = null; return a.gfx_queue_ok; };
        for (&outputs) |*output| if (output.live and std.meta.eql(input.*, output.status.fence)) {
            std.debug.assert(output.status.phase == a.gfx_queue_phase_terminal and output.status.flags == 0);
            output.live = false; return a.gfx_queue_ok;
        };
        std.debug.assert(job_live and std.meta.eql(input.*, status.fence) and status.phase == a.gfx_queue_phase_terminal and status.flags == 0);
        job_live = false; return 1;
    }
    fn complete() void {
        const source = ref(job_request.source); const target = ref(job_request.target);
        std.debug.assert(!source.mapped and !target.mapped);
        // Tiled execution belongs to NVIDIA's CE model; this generic fixture
        // must never turn an opaque layout into a linear byte copy.
        std.debug.assert(objects[source.object.?].descriptor.modifier == 0 and objects[target.object.?].descriptor.modifier == 0);
        const count = if (job_request.row_count == 0) 1 else job_request.row_count;
        for (0..count) |row| {
            const src = job_request.source_offset + row * job_request.source_pitch;
            const dst = job_request.target_offset + row * job_request.target_pitch;
            @memcpy(objects[target.object.?].bytes[dst..][0..job_request.byte_length], objects[source.object.?].bytes[src..][0..job_request.byte_length]);
        }
        status.phase = a.gfx_queue_phase_terminal; status.result = a.gfx_queue_result_complete; status.flags = 0;
    }
    fn referenceCount() usize { var count: usize = 0; for (&references) |*value| if (value.object != null) { count += 1; }; return count; }
};

fn descriptor(kind: u32) c.R4GfxResourceDesc {
    var value = std.mem.zeroes(c.R4GfxResourceDesc);
    value.version = 1; value.size = @sizeOf(c.R4GfxResourceDesc); value.kind = kind; return value;
}
fn cpuImage(bytes: []u8) c.R4GfxResourceDesc {
    var value = descriptor(c.resource_image); value.flags = c.image_target; value.source_kind = c.source_borrow_cpu; value.source_generation = 1;
    value.image = .{ .cpu_address = @intFromPtr(bytes.ptr), .byte_length = bytes.len, .pitch = 16, .width = 4, .height = 4, .format = c.format_xrgb8888, .reserved = 0 };
    return value;
}
// The actual AMD SDMA encoder participates in common queue routing/lifetime
// checks. Effective capabilities still require a matching live driver profile.
const ProviderProbe = struct {
    var nv_calls: usize = 0;
    var amd_calls: usize = 0;
    fn nvidia(profile: *const nv.R4NvDeviceProfile, output: *nv.R4NvFeatures) callconv(.c) i32 {
        nv_calls += 1;
        return nv_provider.r4nv_negotiate_impl(@ptrCast(profile), @ptrCast(output));
    }
    fn amdgpu(profile: *const amd.R4AmdDeviceProfile, output: *amd.R4AmdFeatures) callconv(.c) i32 {
        amd_calls += 1;
        return amd_provider.negotiate(@ptrCast(profile), @ptrCast(output));
    }
};
fn providerImage(handle: *const c.R4GfxDevice) !c.R4GfxResource {
    var loan: a.GfxBufferReference = .{};
    try t.expectEqual(@as(i32, 1), Model.create(&.{ .byte_length = 4096, .alignment = 4096, .width = 4, .height = 4,
        .format = a.gfx_buffer_format_xrgb8888, .plane_count = 1, .plane_pitches = .{ 256, 0, 0, 0 },
        .location = a.gfx_buffer_location_device_local, .adapter_id = 3, .driver_owner = 80, .device_generation = 97, .usage = 28 }, &loan));
    var desc = descriptor(c.resource_image); desc.flags = c.image_target; desc.source_kind = c.source_import_buffer;
    desc.source_address = @intFromPtr(&loan.reference);
    var resource: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(handle, &desc, &resource));
    try t.expectEqual(@as(i32, 1), Model.release(&loan.reference));
    return resource;
}
fn checkProviders(raw: *const a.R4XStartContext, imports: *[6]a.R4XStartImport) !void {
    const storage = try t.allocator.create(d.Device); defer t.allocator.destroy(storage); storage.* = .{};
    var table: amd.BackendV1 = .{ .header = amd.backend_v1_header, .negotiate = ProviderProbe.amdgpu,
        .encode_copy = @ptrCast(&amd_provider.encodeCopy), .encode_fill = @ptrCast(&amd_provider.encodeFill), .encode_pm4_frame = @ptrCast(&amd_provider.encodePm4Frame), .media_caps = @ptrCast(&amd_provider.mediaCaps) };
    var images_table: amd.ImageV1 = .{ .header=amd.image_v1_header,
        .calculate=@ptrCast(&amd_images.calculate), .address=@ptrCast(&amd_images.address), .metadata=@ptrCast(&amd_images.metadata),
        .import_image=@ptrCast(&amd_images.importImage), .descriptors=@ptrCast(&amd_images.descriptors) };
    imports[5].table=@intFromPtr(&images_table); imports[5].resolved_version=amd.image_v1_revision;
    const old_nv = Model.nv_table.negotiate;
    const old_presentation = Model.presentation_info;
    Model.nv_table.negotiate = ProviderProbe.nvidia;
    ProviderProbe.nv_calls = 0; ProviderProbe.amd_calls = 0;
    defer {
        Model.adapters = null; Model.nv_table.negotiate = old_nv;
        Model.presentation_info = old_presentation; Model.reject_adapter = 0;
        imports[4].table = 0; imports[4].resolved_version = 0;
        imports[5].table = 0; imports[5].resolved_version = 0;
    }
    var nvidia: a.GfxBackendInfo = .{};
    try t.expectEqual(@as(i32, 1), Model.backendInfo(1, &nvidia));
    var amdgpu = nvidia;
    amdgpu.binding.adapter_id = 3;
    amdgpu.memory_generation = 97; // Deliberately not the queue generation.
    amdgpu.operations = 0xfff; // Direct/overlay stays absent even with all raw bits set.
    amdgpu.profile = .{ .interface_id_lo = amd.backend_v1_header.interface_id_lo,
        .interface_id_hi = amd.backend_v1_header.interface_id_hi, .revision = 1, .data_bytes = @sizeOf(amd.R4AmdDriverProfile) };
    const details: amd.R4AmdDriverProfile = .{ .version = 1, .size = @sizeOf(amd.R4AmdDriverProfile),
        .vendor_id = amd.vendor_id, .device_id = 0x15d8, .gc_version = if (Model.raven2) amd.gc_9_2_2 else amd.gc_9_1_0,
        .sdma_version = if (Model.raven2) amd.sdma_4_1_1 else amd.sdma_4_1_0, .command_abi = amd.command_abi, .reserved = 0 };
    @memcpy(amdgpu.profile.data[0..@sizeOf(amd.R4AmdDriverProfile)], std.mem.asBytes(&details));
    var unknown = amdgpu; unknown.binding.adapter_id = 1;
    unknown.profile.interface_id_lo = 0x1af4; // Unrecognized/Virtio profile retains its existing software path.
    var values = [_]a.GfxBackendInfo{ nvidia, amdgpu, unknown };
    Model.adapters = &values;
    Model.presentation_info.backend = amdgpu.binding;
    Model.presentation_info.flags |= a.display_presentation_info_active;
    const config: c.R4GfxDeviceConfig = .{ .version = 1, .size = @sizeOf(c.R4GfxDeviceConfig), .storage_address = @intFromPtr(storage),
        .storage_bytes = api.storage_size(), .start_context = @intFromPtr(raw), .preferred_adapter = 0, .flags = 0 };
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(&config, &handle));
    defer _ = api.device_close(&handle);
    var state: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_info(&handle, &state));
    try t.expectEqual(c.render_backend_nvidia, state.backend); // AMD optional import absent.
    // A queue/device epoch cannot stand in for the independent memory epoch.
    const registry = @import("providers.zig").Registry.init(raw, false);
    const before_short = ProviderProbe.nv_calls;
    for ([_]u32{ 136, 144, @sizeOf(a.GfxBackendInfo) - 1 }) |bytes| {
        values[0] = nvidia; values[0].size = bytes;
        try t.expect(registry.negotiate(values[0]) == null);
        try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
        try t.expectEqual(c.render_backend_software, state.backend);
        try t.expectEqual(before_short, ProviderProbe.nv_calls);
    }
    values[0] = nvidia; values[0].memory_generation = 0;
    try t.expect(registry.negotiate(values[0]) == null);
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    values[0] = nvidia; values[0].operations = 0;
    try t.expect(registry.negotiate(values[0]) == null);
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    try t.expectEqual(before_short, ProviderProbe.nv_calls);
    values[0] = nvidia;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_nvidia, state.backend);
    imports[4].table = @intFromPtr(&table); imports[4].resolved_version = amd.backend_v1_revision;
    table.header.abi_major = 2;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_nvidia, state.backend); // Incompatible optional table.
    table.header = amd.backend_v1_header;
    values[1].operations = 0;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_nvidia, state.backend); // Pure encoder does not bypass missing driver operations.
    values[1].operations = amdgpu.operations;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_amd, state.backend);
    const amd_operations = c.device_gpu_copy | c.device_gpu_copy_rows | c.device_gpu_render | c.device_gpu_render_list |
        c.device_gpu_grid | c.device_gpu_color | c.device_gpu_color_grid | c.device_gpu_present;
    try t.expectEqual(amd_operations, state.gpu_operations);
    std.mem.swap(a.GfxBackendInfo, &values[0], &values[2]);
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_amd, state.backend); // Registration order irrelevant.
    std.mem.swap(a.GfxBackendInfo, &values[0], &values[2]);
    storage.preferred_adapter = 3;
    const nv_before = ProviderProbe.nv_calls;
    values[1].profile.interface_id_lo = nv.backend_v1_header.interface_id_lo;
    values[1].profile.interface_id_hi = nv.backend_v1_header.interface_id_hi;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    try t.expectEqual(nv_before, ProviderProbe.nv_calls); // AMD bytes never enter NVIDIA negotiation.
    values[1] = amdgpu;
    std.mem.writeInt(u32, values[1].profile.data[8..12], 0x10de, .little);
    const amd_before = ProviderProbe.amd_calls;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    try t.expectEqual(amd_before, ProviderProbe.amd_calls);
    values[1] = amdgpu; values[1].memory_generation = 0;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    values[1] = amdgpu; Model.reject_adapter = 3;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(state.backend == c.render_backend_software and state.gpu_operations == 0); // Raced loss on open.
    Model.reject_adapter = 0;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_amd, state.backend);
    const native_profile = try @import("native_resource.zig").Profile.query(storage);
    try t.expectEqual(c.render_backend_amd,native_profile.backend);
    try t.expectEqual(amd.native_va_start,native_profile.va_start);
    try t.expectEqual(amd.native_va_end,native_profile.va_end);
    var image_desc: a.GfxBufferDescriptor = .{ .byte_length=4096, .alignment=4096, .width=4, .height=4,
        .format=a.gfx_buffer_format_xrgb8888, .plane_count=1, .plane_pitches=.{256,0,0,0},
        .location=a.gfx_buffer_location_device_local, .adapter_id=3, .driver_owner=80, .device_generation=97, .usage=28 };
    const image_provider = @import("amd_images.zig");
    const image_layout = try image_provider.query(storage,image_desc);
    try t.expectEqual(@as(u64,1024),image_layout.layout.byte_length);
    image_desc.modifier = 0x0200000000401a01 | (1<<13); // DCC requires implemented transitions.
    try t.expectError(error.Unsupported,image_provider.query(storage,image_desc));
    image_desc.modifier = 0;
    image_desc.device_generation += 1;
    try t.expectError(error.Stale,image_provider.query(storage,image_desc));
    image_desc.device_generation -= 1;
    imports[5].table = 0;
    try t.expectError(error.Unsupported,image_provider.query(storage,image_desc));
    imports[5].table = @intFromPtr(&images_table);
    // A changed protocol payload at the same adapter/memory/queue epoch
    // cannot silently reclassify old native BOs as the new provider profile.
    var obsolete = try providerImage(&handle);
    const before_profile = storage.queue.timeline;
    var replacement = details;
    replacement.gc_version = amd.gc_9_2_2; replacement.sdma_version = amd.sdma_4_1_1;
    @memcpy(values[1].profile.data[0..@sizeOf(amd.R4AmdDriverProfile)], std.mem.asBytes(&replacement));
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(state.backend == c.render_backend_amd and storage.queue.timeline != before_profile);
    var discarded: c.R4GfxJob = undefined;
    try t.expectEqual(c.status_stale, api.copy_submit(&handle, &.{ .source = obsolete, .target = obsolete,
        .source_offset = 0, .target_offset = 0, .byte_length = 64, .deadline_ns = 99999999 }, &discarded));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &obsolete));
    values[1] = amdgpu;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    var resources: [2]c.R4GfxResource = undefined;
    for (&resources) |*resource| resource.* = try providerImage(&handle);
    const request: c.R4GfxCopyRequest = .{ .source = resources[0], .target = resources[1], .source_offset = 0, .target_offset = 0, .byte_length = 64, .deadline_ns = 99999999 };
    var job: c.R4GfxJob = undefined;
    try t.expectEqual(c.status_ok, api.copy_submit(&handle, &request, &job));
    var receipt: c.R4GfxJobInfo = undefined;
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &receipt));
    try t.expectEqual(c.render_backend_amd, receipt.backend);
    const old_timeline = receipt.timeline;
    // Loss preserves the pending AMD receipt and BO loans until retirement.
    values[1].profile.revision = 2;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    Model.complete();
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &receipt));
    try t.expect(receipt.backend == c.render_backend_amd and receipt.timeline == old_timeline);
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.device_info(&handle, &state));
    try t.expectEqual(@as(u64, 64), state.gpu_copy_bytes);
    try t.expectEqual(@as(u64, 0), state.cpu_write_bytes);
    try t.expectEqual(c.status_stale, api.copy_submit(&handle, &request, &job));
    for (&resources) |*resource| try t.expectEqual(c.status_ok, api.resource_release(&handle, resource));
    try t.expectEqual(nv_before, ProviderProbe.nv_calls);
    try t.expectEqual(@as(usize, 0), Model.premature_closes);
    values[1] = amdgpu;
    storage.flags = c.device_software_only;
    const reads = Model.inventory_reads;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(c.render_backend_software, state.backend);
    try t.expectEqual(reads, Model.inventory_reads);
}

fn checkAdapterSelection(storage: *d.Device, handle: *const c.R4GfxDevice) !void {
    var first: a.GfxBackendInfo = .{};
    try t.expectEqual(@as(i32, 1), Model.backendInfo(1, &first));
    var values = [_]a.GfxBackendInfo{ first, first, first };
    values[0].binding.adapter_id = 17; values[1].binding.adapter_id = 3; values[2].binding.adapter_id = 9;
    values[0].operations |= 16; values[2].operations |= 16;
    const presentation = Model.presentation_info;
    defer { Model.adapters = null; Model.presentation_info = presentation; storage.preferred_adapter = 0; }
    Model.adapters = &values;
    Model.presentation_info.head_id = 0;
    Model.presentation_info.backend = values[1].binding;
    var state: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 9), state.adapter_id); // Working render over copy-only boot GPU.
    std.mem.swap(a.GfxBackendInfo, &values[0], &values[2]);
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 9), state.adapter_id); // Enumeration order cannot change the result.
    Model.presentation_info.backend = values[2].binding;
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 17), state.adapter_id); // Equal render engines prefer the display adapter.
    storage.preferred_adapter = 3;
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 3), state.adapter_id);
    storage.preferred_adapter = 99;
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 0), state.adapter_id); // Explicit selection never borrows another GPU.
    storage.preferred_adapter = 0;
    values[0].profile.interface_id_lo ^= 1; values[1].memory_generation = 0; values[2].binding.milestone = 0;
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 0), state.adapter_id); // Unusable backends preserve software.
    Model.adapters = &.{};
    try t.expectEqual(c.status_ok, api.device_refresh(handle, &state));
    try t.expectEqual(@as(u32, 0), state.adapter_id);
}
fn checkAdapterTransfer(raw: *const a.R4XStartContext) !void {
    const gfx = @import("r4gfx_binding");
    const transfer = @import("r4gfx_transfer");
    const client: gfx.DeviceV1Client = .{ .header = @ptrCast(&api.header) };
    const colors: gfx.ColorV1Client = .{ .header = @ptrCast(&d.color_api.table.header) };
    const first = try t.allocator.create(d.Device); defer t.allocator.destroy(first); first.* = .{};
    const second = try t.allocator.create(d.Device); defer t.allocator.destroy(second); second.* = .{};
    var backend: a.GfxBackendInfo = .{};
    try t.expectEqual(@as(i32, 1), Model.backendInfo(1, &backend));
    var adapters = [_]a.GfxBackendInfo{ backend, backend };
    adapters[0].binding.adapter_id = 9; adapters[1].binding.adapter_id = 17;
    adapters[0].operations |= 8; adapters[1].operations |= 8;
    Model.adapters = &adapters;
    defer Model.adapters = null;
    var devices: [2]gfx.R4GfxDevice = undefined;
    for ([_]*d.Device{ first, second }, 0..) |storage, i| {
        const config: gfx.R4GfxDeviceConfig = .{ .version = 1, .size = @sizeOf(gfx.R4GfxDeviceConfig),
            .storage_address = @intFromPtr(storage), .storage_bytes = api.storage_size(), .start_context = @intFromPtr(raw),
            .preferred_adapter = adapters[i].binding.adapter_id, .flags = 0 };
        try t.expectEqual(gfx.status_ok, client.device_open(&config, &devices[i]));
    }
    const description: gfx.R4GfxColorDescription = .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorDescription),
        .primaries = gfx.color_primaries_srgb, .transfer = gfx.color_transfer_srgb, .range = gfx.color_range_full,
        .alpha = gfx.color_alpha_opaque, .precision = gfx.color_precision_unorm8, .flags = 0,
        .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 };
    var resources: [2]gfx.R4GfxResource = undefined;
    var object_ids: [2]usize = undefined;
    for (&resources, 0..) |*resource, i| {
        // Model two driver-owned images, each import validated by the actual
        // provider against its independently selected adapter/memory epoch.
        var reference: a.GfxBufferReference = .{};
        try t.expectEqual(@as(i32, 1), Model.create(&.{ .width = 4, .height = 4, .format = c.format_xrgb8888,
            .plane_count = 1, .plane_pitches = .{256,0,0,0}, .byte_length = 65536, .usage = 28,
            .location = a.gfx_buffer_location_device_local, .adapter_id = adapters[i].binding.adapter_id,
            .device_generation = 73, .driver_owner = @intCast(79 + i) }, &reference));
        object_ids[i] = Model.ref(reference.reference).object.?;
        var desc = std.mem.zeroes(gfx.R4GfxResourceDesc);
        desc.version = 1; desc.size = @sizeOf(gfx.R4GfxResourceDesc); desc.kind = gfx.resource_image;
        desc.source_kind = gfx.source_import_buffer; desc.source_address = @intFromPtr(&reference.reference); desc.flags = gfx.image_target;
        try t.expectEqual(gfx.status_ok, colors.color_resource_create(&devices[i], &.{ .version = 1,
            .size = @sizeOf(gfx.R4GfxColorResourceDesc), .resource = desc, .description = description }, resource));
        try t.expectEqual(@as(i32, 1), Model.release(&reference.reference));
    }
    const before = Model.referenceCount();
    var owner = transfer.Owner.init(&client, &colors, &devices[0], &devices[1], .{ .base = first.base() });
    for (0..3) |scenario| {
        try owner.prepare(4, 4, gfx.format_xrgb8888, description);
        for (&Model.objects[object_ids[0]].bytes, 0..) |*byte, i| byte.* = @truncate(i * 17 + 3);
        @memset(&Model.objects[object_ids[1]].bytes, 0xa5);
        try owner.begin(resources[0], resources[1], &.{}, 1, 99999999);
        try t.expect(owner.sourceHeld() and Model.status.fence.adapter_id == 9 and Model.job_request.dependency_count == 0);
        try t.expect(Model.objects[Model.ref(Model.job_request.source).object.?].descriptor.adapter_id == 9);
        try t.expect(Model.objects[Model.ref(Model.job_request.target).object.?].descriptor.location == a.gfx_buffer_location_system);
        const download = Model.status.fence;
        owner.poll(2);
        try t.expect(owner.phase == .download and owner.sourceHeld());
        try t.expectError(error.Busy, owner.close());
        if (scenario == 1) {
            owner.poll(99999999); // Terminal cancellation still retains DMA.
            try t.expect(owner.phase == .draining and owner.sourceHeld() and Model.job_live);
            try t.expectError(error.Busy, owner.close());
            Model.status.flags = 0;
            owner.poll(99999999);
            try t.expect(owner.phase == .failed and owner.failure.? == error.Deadline and !owner.sourceHeld());
            try t.expect(std.mem.allEqual(u8, &Model.objects[object_ids[1]].bytes, 0xa5));
        } else {
            Model.complete(); owner.poll(3);
            try t.expect(owner.phase == .upload and !owner.sourceHeld() and Model.status.fence.adapter_id == 17);
            try t.expect(Model.status.fence.timeline != download.timeline and Model.job_request.dependency_count == 0);
            try t.expect(Model.objects[Model.ref(Model.job_request.source).object.?].descriptor.location == a.gfx_buffer_location_system);
            try t.expect(Model.objects[Model.ref(Model.job_request.target).object.?].descriptor.adapter_id == 17);
            if (scenario == 2) {
                owner.cancel(error.Stale); owner.poll(4);
                try t.expect(owner.phase == .draining and Model.job_live and owner.target.slot != 0);
                try t.expectError(error.Busy, owner.close());
                Model.status.flags = 0; owner.poll(5);
                try t.expect(owner.phase == .failed and owner.failure.? == error.Stale);
                try t.expect(std.mem.allEqual(u8, &Model.objects[object_ids[1]].bytes, 0xa5));
            } else {
                Model.complete(); owner.poll(4);
                try t.expect(owner.phase == .ready and owner.completed_bytes == 64);
                for (0..4) |row| {
                    try t.expectEqualSlices(u8, Model.objects[object_ids[0]].bytes[row * 256..][0..16],
                        Model.objects[object_ids[1]].bytes[row * 256..][0..16]);
                    try t.expect(std.mem.allEqual(u8, Model.objects[object_ids[1]].bytes[row * 256 + 16..][0..240], 0xa5));
                }
            }
        }
        try owner.acknowledge(); try owner.close();
        try t.expect(!Model.job_live and Model.referenceCount() == before);
    }
    for (&devices, &resources) |*device, *resource| {
        try t.expectEqual(gfx.status_ok, client.resource_release(device, resource));
        try t.expectEqual(gfx.status_ok, client.device_close(device));
    }
}
// The same original callback model runs behind a genuinely separate SYS2/
// DRAW2 layout. No legacy context/table cast or fabricated compatibility table.
fn checkGeneration2(old_sys: *const a.R4XStartR4Sys, old_draw: *const a.R4XStartR4Draw) !void {
    const r = @import("r4os");
    const a2 = r.platform2.abi;
    const binding = @import("r4gfx_binding");
    var sys: a2.R4XStartR4Sys2 = .{};
    var draw: a2.R4XStartR4Draw2 = .{};
    inline for (std.meta.fields(a2.R4XStartR4Sys2)) |field| {
        if (comptime @hasDecl(a.R4SysFns, field.name)) @field(sys, field.name) = @field(old_sys.*, field.name);
    }
    inline for (std.meta.fields(a2.R4XStartR4Draw2)) |field| {
        if (comptime @hasDecl(a.R4DrawFns, field.name)) @field(draw, field.name) = @field(old_draw.*, field.name);
    }
    const imports = [_]a.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) },
        .{ .group_id = 3, .resolved_version = 2, .table = @intFromPtr(&draw) },
        .{ .module_name = @intFromPtr("R4GFX"), .symbol_name = @intFromPtr("Query2"), .min_version = 2, .resolved_version = 2, .table = @intFromPtr(&@import("main.zig").r4gfx_query2) },
        .{ .module_name = @intFromPtr("R4GFX"), .symbol_name = @intFromPtr("DEVICE_V1"), .min_version = 10, .resolved_version = 10, .table = @intFromPtr(api) },
    };
    var raw: a2.R4XStartContext2 = .{ .imports = @intFromPtr(&imports), .import_count = imports.len, .instance_id = 7 };
    const client = try binding.DeviceV1Client.init2(&raw);
    const storage = try t.allocator.create(d.Device); defer t.allocator.destroy(storage); storage.* = .{};
    const config: binding.R4GfxDeviceConfig = .{ .version = 1, .size = @sizeOf(binding.R4GfxDeviceConfig), .storage_address = @intFromPtr(storage),
        .storage_bytes = api.storage_size(), .start_context = @intFromPtr(&raw), .preferred_adapter = 0, .flags = c.device_software_only };
    var handle: binding.R4GfxDevice = .{ .address = 0x1234, .generation = 77 };
    const untouched = handle;
    raw.size = 16;
    try t.expectEqual(c.status_invalid, client.device_open(&config, &handle));
    try t.expectEqualDeep(untouched, handle);
    try t.expect(storage.magic == 0 and storage.generation == 0);
    raw.size = @sizeOf(a2.R4XStartContext2);
    try t.expectEqual(c.status_ok, client.device_open(&config, &handle));
    try t.expect(storage.base().bundle == null and storage.base().generation2 != null);
    try t.expect(storage.caller.generation2.c_view.raw == &storage.caller.generation2.raw);
    try t.expect(storage.caller.address() != @intFromPtr(&raw));
    raw.magic = 0; raw.imports = 0; raw.import_count = 0;
    var info: binding.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, client.device_info(&handle, &info));
    var image = std.mem.zeroes(binding.R4GfxResourceDesc);
    image.version = 1; image.size = @sizeOf(binding.R4GfxResourceDesc); image.kind = c.resource_image; image.flags = c.image_target;
    image.source_kind = c.source_create_system;
    image.image = .{ .cpu_address = 0, .byte_length = 64, .pitch = 16, .width = 4, .height = 4, .format = c.format_xrgb8888, .reserved = 0 };
    var resource: binding.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, client.resource_create(&handle, &image, &resource));
    try t.expectEqual(@as(usize, 1), Model.referenceCount());
    try t.expectEqual(c.status_ok, client.resource_release(&handle, &resource));
    try t.expectEqual(@as(usize, 0), Model.referenceCount());
    try t.expectEqual(c.status_ok, client.device_close(&handle));
    Model.reset();
}
pub fn check() !void {
    Model.reset();
    const storage = try t.allocator.create(d.Device); defer t.allocator.destroy(storage); storage.* = .{};
    const other_storage = try t.allocator.create(d.Device); defer t.allocator.destroy(other_storage); other_storage.* = .{};
    const sys: a.R4XStartR4Sys = .{ .monotonic_clock = @intFromPtr(&Model.monotonic) };
    var draw: a.R4XStartR4Draw = .{ .gfx_buffer_create = @intFromPtr(&Model.create), .gfx_buffer_describe = @intFromPtr(&Model.describe),
        .gfx_native_start = @intFromPtr(&Model.nativeStart), .gfx_native_wait = @intFromPtr(&Model.nativeWait), .gfx_native_query = @intFromPtr(&Model.nativeQuery),
        .gfx_native_receive = @intFromPtr(&Model.nativeReceive), .gfx_native_close = @intFromPtr(&Model.nativeClose),
        .gfx_buffer_import = @intFromPtr(&Model.import), .gfx_buffer_release = @intFromPtr(&Model.release), .gfx_buffer_map = @intFromPtr(&Model.map),
        .gfx_buffer_unmap = @intFromPtr(&Model.unmap), .gfx_buffer_export_raster = @intFromPtr(&Model.exportRaster), .gfx_queue_backend_info = @intFromPtr(&Model.backendInfo),
        .gfx_queue_open = @intFromPtr(&Model.open), .gfx_queue_close = @intFromPtr(&Model.close), .gfx_queue_submit = @intFromPtr(&Model.submit),
        .gfx_queue_submit_render_list = @intFromPtr(&Model.submitList),
        .gfx_queue_submit_render_grid_list = @intFromPtr(&Model.submitGridList),
        .gfx_queue_submit_render_color_list = @intFromPtr(&Model.submitColorList),
        .gfx_queue_submit_render_color_grid_list = @intFromPtr(&Model.submitColorGridList),
        .display_presentation_info = @intFromPtr(&Model.presentInfo), .display_presentation_feedback = @intFromPtr(&Model.presentFeedback),
        .display_present_regions = @intFromPtr(&Model.presentPixels),
        .gfx_queue_backend_properties = @intFromPtr(&Model.properties),
        .gfx_fence_query = @intFromPtr(&Model.query), .gfx_fence_cancel = @intFromPtr(&Model.cancel), .gfx_fence_release = @intFromPtr(&Model.drop) };
    try checkGeneration2(&sys, &draw);
    var imports = [_]a.R4XStartImport{
        .{ .group_id = @intFromEnum(a.R4LGroup.r4sys), .flags = a.r4xstart_import_flag_group_interface, .table = @intFromPtr(&sys) },
        .{ .group_id = @intFromEnum(a.R4LGroup.r4draw), .flags = a.r4xstart_import_flag_group_interface, .table = @intFromPtr(&draw) },
        .{ .module_name = @intFromPtr("R4NV"), .symbol_name = @intFromPtr("BACKEND_V1"), .min_version = nv.backend_v1_revision },
        .{ .module_name = @intFromPtr("R4NV"), .symbol_name = @intFromPtr("RENDER_V1"), .min_version = nv.render_v1_revision },
        .{ .module_name = @intFromPtr("R4AMD"), .symbol_name = @intFromPtr("BACKEND_V1"), .min_version = amd.backend_v1_revision },
        .{ .module_name = @intFromPtr("R4AMD"), .symbol_name = @intFromPtr("IMAGE_V1"), .min_version = amd.image_v1_revision },
    };
    const raw: a.R4XStartContext = .{ .flags = a.r4xstart_flag_imports_valid, .imports = @intFromPtr(&imports), .import_count = imports.len, .instance_id = 7 };
    var config: c.R4GfxDeviceConfig = .{ .version = 1, .size = @sizeOf(c.R4GfxDeviceConfig), .storage_address = @intFromPtr(storage),
        .storage_bytes = api.storage_size(), .start_context = @intFromPtr(&raw), .preferred_adapter = 0, .flags = 0 };
    var handle: c.R4GfxDevice = undefined; var other: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(&config, &handle));
    var state: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_info(&handle, &state));
    try t.expect(state.backend == c.render_backend_software and state.gpu_operations == 0 and Model.inventory_reads == 0);
    try checkColorResources(&handle);
    var alias_bytes: [@sizeOf(c.R4GfxDeviceInfo)]u8 align(8) = @splat(0);
    @memcpy(alias_bytes[0..@sizeOf(c.R4GfxDevice)], std.mem.asBytes(&handle));
    try t.expectEqual(c.status_alias, api.device_info(@ptrCast(&alias_bytes), @ptrCast(&alias_bytes)));
    try t.expectEqualSlices(u8, std.mem.asBytes(&handle), alias_bytes[0..@sizeOf(c.R4GfxDevice)]);
    config.storage_address = @intFromPtr(other_storage); try t.expectEqual(c.status_ok, api.device_open(&config, &other));
    var pixels: [64]u8 align(8) = @splat(0xa5);
    var target: c.R4GfxResource = undefined; var fill: c.R4GfxResource = undefined;
    const image = cpuImage(&pixels);
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image, &target));
    var fill_desc = descriptor(c.resource_pipeline); fill_desc.operation = c.render_operation_fill;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &fill_desc, &fill));
    try t.expectEqual(c.status_stale, api.resource_retain(&other, &target));
    var commands: [2]c.R4GfxDraw = @splat(std.mem.zeroes(c.R4GfxDraw));
    commands[0].target = target; commands[0].pipeline = fill; commands[0].target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }; commands[0].color = 0x123456;
    commands[1] = commands[0]; commands[1].target_rect.width = 5;
    var batch: c.R4GfxRenderBatch = .{ .commands = @intFromPtr(&commands), .command_count = 2, .flags = 0, .pixel_budget = 32 };
    var stats = std.mem.zeroes(c.R4GfxRenderStats); stats.cpu.pixels = 71;
    const aliased_batch: *c.R4GfxRenderBatch = @ptrCast(&storage.images);
    aliased_batch.* = .{ .commands = 0, .command_count = 0, .flags = 0, .pixel_budget = 0 };
    try t.expectEqual(c.status_alias, api.render(&handle, aliased_batch, &stats));
    try t.expectEqual(c.status_invalid, api.render(&handle, &batch, &stats));
    try t.expect(stats.cpu.pixels == 71 and std.mem.allEqual(u8, &pixels, 0xa5));
    batch.command_count = 1;
    try t.expectEqual(c.status_ok, api.render(&handle, &batch, &stats));
    try t.expect(stats.cpu.pixels == 16 and stats.cpu.write_bytes == 64 and stats.fallback == 0 and Model.maps == 0);
    for (0..16) |i| try t.expectEqual(@as(u32, 0x123456), std.mem.readInt(u32, pixels[i * 4 ..][0..4], .little));
    var twin: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image, &twin));
    try t.expectEqualDeep(target, twin);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &twin));
    const old = handle;
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    config.storage_address = @intFromPtr(storage);
    try t.expectEqual(c.status_ok, api.device_open(&config, &handle));
    try t.expect(handle.generation > old.generation);
    try t.expectEqual(c.status_stale, api.resource_retain(&handle, &target));
    try t.expectEqual(c.status_stale, api.device_info(&old, &state));
    try t.expectEqual(c.status_ok, api.device_close(&other));
    // A mismatched optional R4NV interface preserves the same software device.
    imports[2].table = @intFromPtr(&Model.nv_table); imports[2].resolved_version = nv.backend_v1_revision;
    Model.nv_table.header.abi_major = 2;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(state.backend == c.render_backend_software);
    Model.nv_table.header = nv.backend_v1_header;
    draw.size = 640; // Legacy R4DRAW has no profile tail.
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(state.backend == c.render_backend_software);
    draw.size = @sizeOf(a.R4XStartR4Draw);
    try checkProviders(&raw, &imports);
    try checkAdapterSelection(storage, &handle);
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(state.backend == c.render_backend_nvidia and state.gpu_operations == c.device_gpu_copy and state.reset_generation == Model.binding.reset_generation);
    try checkAdapterTransfer(&raw);
    const native_image: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999, .width = 4, .height = 4,
        .format = c.format_xrgb8888, .layout = 0 };
    var create_native = descriptor(c.resource_image); create_native.source_kind = c.source_create_native;
    create_native.source_address = @intFromPtr(&native_image); create_native.flags = c.image_target;
    var allocated: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &create_native, &allocated));
    var allocated_info: c.R4GfxResourceInfo = undefined;
    try t.expectEqual(c.status_ok, api.resource_info(&handle, &allocated, &allocated_info));
    try t.expect(allocated_info.image.pitch == 256 and allocated_info.image.byte_length == 65536 and Model.native_handle.id == 0);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &allocated));
    const untouched = allocated;
    Model.native_result = a.gfx_buffer_error_oom;
    try t.expectEqual(c.status_limit, api.resource_create(&handle, &create_native, &allocated));
    try t.expectEqualDeep(untouched, allocated);
    try t.expect(Model.native_handle.id == 0);
    Model.native_result = 1;
    // Canonical shared raster generation is exported once and never uploaded.
    const lease: a.GuiSharedRasterLease = .{ .handle = .{ .id = 0x100000011, .generation = 0x200000011 }, .raster_generation = 7, .lease_token = 9 };
    var shared_desc = descriptor(c.resource_image); shared_desc.source_kind = c.source_shared_raster; shared_desc.source_address = @intFromPtr(&lease);
    var shared: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &shared_desc, &shared));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &shared_desc, &twin));
    try t.expectEqualDeep(shared, twin); try t.expect(Model.exports == 1);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &twin));
    var system = cpuImage(&pixels); system.source_kind = c.source_create_system; system.source_generation = 0; system.image.cpu_address = 0;
    var source: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &system, &source));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &system, &target));
    // A native imported BO has its own lifetime and must become stale at
    // reset, while the two system images and the immutable raster survive.
    Model.objects[2] = .{ .live = true, .descriptor = Model.objects[0].descriptor };
    Model.objects[2].descriptor.location = a.gfx_buffer_location_device_local;
    Model.objects[2].descriptor.adapter_id = Model.binding.adapter_id;
    Model.objects[2].descriptor.device_generation = Model.binding.device_generation;
    var native_reference: a.GfxBufferReference = .{};
    try t.expectEqual(@as(i32, 1), Model.lend(2, &native_reference, false));
    var native_desc = descriptor(c.resource_image); native_desc.flags = c.image_target;
    native_desc.source_kind = c.source_import_buffer; native_desc.source_address = @intFromPtr(&native_reference.reference);
    var native: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_stale, api.resource_create(&handle, &native_desc, &native));
    Model.objects[2].descriptor.device_generation = 73; // Advertised memory epoch, not queue identity.
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &native_desc, &native));
    try t.expectEqual(@as(i32, 1), Model.release(&native_reference.reference));
    @memset(&Model.objects[0].bytes, 0x31);
    var job: c.R4GfxJob = undefined;
    const copy: c.R4GfxCopyRequest = .{ .source = source, .target = target, .source_offset = 8, .target_offset = 12, .byte_length = 16, .deadline_ns = 99999999 };
    try t.expectEqual(c.status_ok, api.copy_submit(&handle, &copy, &job));
    var receipt: c.R4GfxJobInfo = undefined;
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &receipt));
    const old_reset = receipt.reset_generation;
    Model.binding.reset_generation += 1;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(state.reset_generation != old_reset and Model.premature_closes == 0);
    var native_info: c.R4GfxResourceInfo = undefined;
    try t.expectEqual(c.status_ok, api.resource_info(&handle, &native, &native_info));
    try t.expect(native_info.flags & c.resource_invalidated != 0);
    var invalid_copy = copy; invalid_copy.source = native;
    var rejected_job: c.R4GfxJob = undefined;
    try t.expectEqual(c.status_stale, api.copy_submit(&handle, &invalid_copy, &rejected_job));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &native));
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &source));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expect(Model.referenceCount() == 3); // Two copy sources plus the retained raster.
    Model.complete();
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &receipt));
    try t.expect(receipt.reset_generation == old_reset and receipt.flags == 0);
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 1 and Model.premature_closes == 0);
    try t.expectEqual(c.status_ok, api.device_info(&handle, &state));
    try t.expect(state.gpu_copy_bytes == 16 and state.upload_bytes == 0 and state.imports == 2 and state.imported_bytes == 128 and Model.exports == 1);
    // Cancellation is logical. Close must not lose its still-active fence.
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &system, &source));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &system, &target));
    var row_copy = std.mem.zeroes(c.R4GfxCopyRequestEx);
    row_copy.version = 1; row_copy.size = @sizeOf(c.R4GfxCopyRequestEx);
    row_copy.copy = .{ .source = source, .target = target, .source_offset = 4, .target_offset = 8, .byte_length = 4, .deadline_ns = 99999999 };
    row_copy.row_count = 3; row_copy.source_pitch = 16; row_copy.target_pitch = 16;
    @memset(&Model.objects[0].bytes, 0x37);
    try t.expectEqual(c.status_ok, api.copy_submit_ex(&handle, &row_copy, &job));
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &receipt));
    try t.expectEqual(c.render_backend_software, receipt.backend); // Old native profile lacks row transport.
    var dependency: c.R4GfxCopyFence = undefined;
    try t.expectEqual(c.status_ok, api.job_fence(&handle, &job, &dependency));
    try t.expectEqualDeep(Model.status.fence, @as(a.GfxFence, @bitCast(dependency)));
    row_copy.dependency_count = 1; row_copy.dependencies = @intFromPtr(&dependency);
    try t.expectEqual(c.status_busy, api.copy_submit_ex(&handle, &row_copy, &rejected_job));
    try t.expect(Model.dependency_seen); // Exact identity forwarded; kernel owner case proves admission/order.
    Model.complete();
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.device_info(&handle, &state));
    try t.expect(state.gpu_copy_bytes == 16 and state.cpu_read_bytes == 12 and state.cpu_write_bytes == 12);
    for (0..3) |row| try t.expectEqualSlices(u8, &.{0x37,0x37,0x37,0x37}, Model.objects[1].bytes[8 + row * 16 ..][0..4]);
    Model.operations = 15;
    row_copy.dependency_count = 0; row_copy.dependencies = 0;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expectEqual(@as(u32, 7), state.gpu_operations);
    try t.expectEqual(c.status_ok, api.copy_submit_ex(&handle, &row_copy, &job));
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &receipt));
    try t.expectEqual(c.render_backend_nvidia, receipt.backend);
    Model.complete();
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.device_info(&handle, &state));
    try t.expect(state.gpu_copy_bytes == 28 and state.cpu_read_bytes == 12 and state.cpu_write_bytes == 12);
    var cancelled_copy = copy; cancelled_copy.source = source; cancelled_copy.target = target;
    try t.expectEqual(c.status_ok, api.copy_submit(&handle, &cancelled_copy, &job));
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(Model.status.result == a.gfx_queue_result_cancelled and Model.referenceCount() == 2 and Model.job_live and Model.premature_closes == 0);
    Model.status.flags = 0; // Explicit model acknowledgement of physical stop.
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and !Model.job_live and Model.premature_closes == 0);
    // Failed CPU unmap retains backing until explicit recovery.
    try t.expectEqual(c.status_ok, api.device_open(&config, &handle));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &system, &target));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &fill_desc, &fill));
    commands[0].target = target; commands[0].pipeline = fill;
    Model.fail_unmap = true;
    try t.expectEqual(c.status_busy, api.render(&handle, &batch, &stats));
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 1);
    Model.fail_unmap = false;
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
    try checkNativeRender(&config);
    try checkReceiptPressure(&config);
    try checkResidency(&config, &imports, false);
    try checkResidency(&config, &imports, true);
    try checkNativeColor(&config);
    try checkNativeGrid(&config);
    try checkNativePresent(&config, &imports, false);
    try checkNativePresent(&config, &imports, true);
    Model.raven2 = true;
    try checkNativePresent(&config, &imports, true);
    Model.raven2 = false;
    try checkImagePreparation(&config);
    try checkTiledPreparation(&config);
    try checkSwapchains(&config, &imports);
    draw.display_output_target = @intFromPtr(&Model.outputTarget);
    draw.display_output_presentation_info = @intFromPtr(&Model.outputInfo);
    draw.gfx_queue_submit_output = @intFromPtr(&Model.submitOutput);
    try checkOutputSwapchains(config);
    draw.gfx_buffer_map_persistent = @intFromPtr(&Model.mapPersistent);
    draw.gfx_queue_backend_properties = @intFromPtr(&Model.properties);
    draw.gfx_virtual_start = @intFromPtr(&Model.virtualStart);
    draw.gfx_virtual_query = @intFromPtr(&Model.virtualQuery);
    draw.gfx_virtual_close = @intFromPtr(&Model.virtualClose);
    draw.gfx_queue_submit_native = @intFromPtr(&Model.submitNative);
    imports[3].table = @intFromPtr(&Model.nv_render); imports[3].resolved_version = nv.render_v1_revision;
    try checkNativeYuv(&config);
    try checkNativeYuvRejection(&config);
    try checkAmdYuv(&config, &imports, false);
    Model.amd_properties_revision = 2;
    defer Model.amd_properties_revision = 1;
    try checkAmdYuv(&config, &imports, true);
    Model.raven2 = true;
    defer Model.raven2 = false;
    try checkAmdYuv(&config, &imports, false);
    try checkAmdYuv(&config, &imports, true);
}

fn checkAmdYuv(config: *const c.R4GfxDeviceConfig, imports: *[6]a.R4XStartImport, ten_bit: bool) !void {
    Model.reset(); Model.binding.adapter_id = 3;
    var table: amd.BackendV1 = .{ .header = amd.backend_v1_header, .negotiate = ProviderProbe.amdgpu,
        .encode_copy = @ptrCast(&amd_provider.encodeCopy), .encode_fill = @ptrCast(&amd_provider.encodeFill), .encode_pm4_frame = @ptrCast(&amd_provider.encodePm4Frame), .media_caps = @ptrCast(&amd_provider.mediaCaps) };
    var image_table: amd.ImageV1 = .{ .header = amd.image_v1_header, .calculate = @ptrCast(&amd_images.calculate), .address = @ptrCast(&amd_images.address),
        .metadata = @ptrCast(&amd_images.metadata), .import_image = @ptrCast(&amd_images.importImage), .descriptors = @ptrCast(&amd_images.descriptors) };
    imports[4].table = @intFromPtr(&table); imports[4].resolved_version = amd.backend_v1_revision;
    imports[5].table = @intFromPtr(&image_table); imports[5].resolved_version = amd.image_v1_revision;
    defer {
        imports[4].table = 0; imports[4].resolved_version = 0;
        imports[5].table = 0; imports[5].resolved_version = 0;
        Model.adapters = null;
    }
    var backend = [_]a.GfxBackendInfo{.{ .binding = Model.binding, .operations = (@as(u64, 1) << a.gfx_queue_operation_native) | 29, .memory_generation = 97,
        .profile = .{ .interface_id_lo = amd.backend_v1_header.interface_id_lo, .interface_id_hi = amd.backend_v1_header.interface_id_hi,
            .revision = 1, .data_bytes = @sizeOf(amd.R4AmdDriverProfile) } }};
    const details: amd.R4AmdDriverProfile = .{ .version = 1, .size = @sizeOf(amd.R4AmdDriverProfile), .vendor_id = amd.vendor_id, .device_id = 0x15d8,
        .gc_version = if (Model.raven2) amd.gc_9_2_2 else amd.gc_9_1_0, .sdma_version = if (Model.raven2) amd.sdma_4_1_1 else amd.sdma_4_1_0, .command_abi = amd.command_abi, .reserved = 0 };
    @memcpy(backend[0].profile.data[0..@sizeOf(amd.R4AmdDriverProfile)], std.mem.asBytes(&details));
    Model.adapters = &backend;
    const colors = &@import("main.zig").r4gfx_color_v1;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    var source: a.GfxBufferReference = .{}; var destination: a.GfxBufferReference = .{};
    try t.expectEqual(@as(i32, 1), Model.create(&.{ .byte_length = 131072, .alignment = 4096, .width = 4, .height = 4,
        .format = if (ten_bit) a.gfx_buffer_format_p010 else a.gfx_buffer_format_nv12, .plane_count = 2, .plane_offsets = .{ 0, 65536, 0, 0 }, .plane_pitches = .{ 256, 256, 0, 0 },
        .usage = 28, .location = 1, .adapter_id = 3, .device_generation = 97, .driver_owner = 80 }, &source));
    try t.expectEqual(@as(i32, 1), Model.create(&.{ .byte_length = 4096, .alignment = 4096, .width = 4, .height = 4,
        .format = c.format_abgr16161616f, .plane_count = 1, .plane_pitches = .{ 256, 0, 0, 0 },
        .usage = 28, .location = 1, .adapter_id = 3, .device_generation = 97, .driver_owner = 80 }, &destination));
    var desc: c.R4GfxColorResourceDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxColorResourceDesc), .resource = descriptor(c.resource_image),
        .description = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription), .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_linear,
            .range = c.color_range_full, .alpha = c.color_alpha_optical, .precision = c.color_precision_float16, .flags = 0,
            .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 } };
    desc.resource.flags = c.image_target; desc.resource.source_kind = c.source_import_buffer; desc.resource.source_address = @intFromPtr(&destination.reference);
    var target: c.R4GfxResource = undefined;
    Model.amd_properties_short = true;
    try t.expectEqual(c.status_unsupported, colors.color_resource_create(&handle, &desc, &target));
    Model.amd_properties_short = false;
    try t.expectEqual(c.status_ok, colors.color_resource_create(&handle, &desc, &target));
    try t.expectEqual(@as(i32, 1), Model.release(&destination.reference));
    var request = std.mem.zeroes(c.R4GfxYuvRenderRequest);
    request.version = 1; request.size = @sizeOf(c.R4GfxYuvRenderRequest); request.target = target; request.deadline_ns = 99999999;
    request.source = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvBufferImage), .format = if (ten_bit) c.yuv_format_p010 else c.yuv_format_nv12, .width = 4, .height = 4, .plane_count = 2, .reserved = 0,
        .crop = .{ .x = 1, .y = 1, .width = 3, .height = 3 },
        .description = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvDescription), .primaries = 1, .transfer = 1, .matrix = 1, .range = 2,
            .chroma_location = 1, .flags = 0, .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 },
        .plane0 = .{ .reference_id = source.reference.id, .reference_generation = source.reference.generation, .reserved = 0, .offset = 0, .byte_length = 65536, .pitch = 256 },
        .plane1 = .{ .reference_id = source.reference.id, .reference_generation = source.reference.generation, .reserved = 0, .offset = 65536, .byte_length = 65536, .pitch = 256 },
        .plane2 = std.mem.zeroes(c.R4GfxYuvBufferPlane) };
    request.transform = .{ .version = 1, .size = @sizeOf(c.R4GfxColorTransform), .source_rect = request.source.crop, .target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 },
        .sampler = 1, .operation = c.render_operation_over, .opacity = 32768, .flags = 0, .pixel_budget = 16 };
    var job = std.mem.zeroes(c.R4GfxJob);
    try t.expectEqual(c.status_busy, colors.color_yuv_render_submit(&handle, &request, &job));
    try t.expect(job.slot == 0 and !Model.job_live and Model.maps == 0);
    Model.virtual_ack = true;
    for (0..8) |_| {
        const rc = colors.color_yuv_render_submit(&handle, &request, &job);
        if (rc == c.status_ok) break;
        try t.expectEqual(c.status_busy, rc);
    }
    try t.expect(job.slot != 0 and Model.job_live and Model.maps == 0 and Model.virtual_starts == 4);
    try t.expect(Model.amd_packet.header.target_binding == 1 and Model.amd_packet.header.plane0.binding == 0 and Model.amd_packet.header.plane1.binding == 0);
    try t.expect(Model.amd_packet.header.plane1.offset == 65536 and Model.amd_packet.header.source.x == 1 and Model.amd_packet.header.opacity == 32768);
    try t.expectEqual(@as(u32, if (ten_bit) 2 else 1), Model.amd_packet.header.format);
    const retained = Model.referenceCount();
    var dependency: c.R4GfxCopyFence = undefined;
    try t.expectEqual(c.status_ok, api.job_fence(&handle, &job, &dependency));
    request.dependency_count = 1; request.dependencies = @intFromPtr(&dependency);
    var pending = std.mem.zeroes(c.R4GfxJob);
    try t.expectEqual(c.status_busy, colors.color_yuv_render_submit(&handle, &request, &pending));
    try t.expect(Model.dependency_seen and pending.slot == 0 and Model.referenceCount() == retained);
    request.dependency_count = 0; request.dependencies = 0;
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == retained and Model.virtual_closes == 0);
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, colors.color_yuv_render_submit(&handle, &request, &job));
    try t.expect(Model.virtual_starts == 4 and Model.maps == 0);
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_failed; Model.status.flags = 0;
    var failed: c.R4GfxJobInfo = undefined;
    try t.expectEqual(c.status_ok, api.job_info(&handle, &job, &failed));
    try t.expect(failed.result == a.gfx_queue_result_failed and failed.backend == c.render_backend_amd);
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expectEqual(@as(i32, 1), Model.release(&source.reference));
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(Model.virtual_closes == 2 and Model.referenceCount() == 2);
    Model.retire_ack = true;
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.maps == 0 and Model.premature_closes == 0);
    std.debug.print("AMD native YUV: canonical profile, deduplicated planes, no pixel maps, cached VA, retained fences and retirement: OK\n", .{});
}

fn checkNativeYuv(config: *const c.R4GfxDeviceConfig) !void {
    Model.reset(); Model.operations = 29 | (@as(u64,1) << a.gfx_queue_operation_native);
    const colors = &@import("main.zig").r4gfx_color_v1;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    var source: a.GfxBufferReference = .{};
    try t.expectEqual(@as(i32,1), Model.create(&.{ .byte_length = 131072, .alignment = 65536, .modifier = 0x0300000000606011,
        .width = 4, .height = 32, .format = a.gfx_buffer_format_nv12, .plane_count = 2, .plane_offsets = .{0,65536,0,0}, .plane_pitches = .{64,64,0,0},
        .usage = 28, .location = 1, .adapter_id = Model.binding.adapter_id, .device_generation = 73, .driver_owner = 79 }, &source));
    var native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_abgr16161616f, .layout = 0 };
    var desc: c.R4GfxColorResourceDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxColorResourceDesc),
        .resource = descriptor(c.resource_image), .description = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription),
            .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_linear, .range = c.color_range_full,
            .alpha = c.color_alpha_optical, .precision = c.color_precision_float16, .flags = 0,
            .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 } };
    desc.resource.flags = c.image_target; desc.resource.source_kind = c.source_create_native; desc.resource.source_address = @intFromPtr(&native);
    var target: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_create(&handle, &desc, &target));
    var request = std.mem.zeroes(c.R4GfxYuvRenderRequest);
    request.version = 1; request.size = @sizeOf(c.R4GfxYuvRenderRequest); request.target = target; request.deadline_ns = native.deadline_ns;
    request.source = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvBufferImage), .format = 1, .width = 4, .height = 4, .plane_count = 2, .reserved = 0,
        .crop = .{ .x = 1, .y = 1, .width = 3, .height = 3 },
        .description = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvDescription), .primaries = 1, .transfer = 1, .matrix = 1, .range = 2,
            .chroma_location = 1, .flags = 0, .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 },
        .plane0 = .{ .reference_id = source.reference.id, .reference_generation = source.reference.generation, .reserved = 0, .offset = 0, .byte_length = 65536, .pitch = 64 },
        .plane1 = .{ .reference_id = source.reference.id, .reference_generation = source.reference.generation, .reserved = 0, .offset = 65536, .byte_length = 65536, .pitch = 64 },
        .plane2 = std.mem.zeroes(c.R4GfxYuvBufferPlane) };
    request.transform = .{ .version = 1, .size = @sizeOf(c.R4GfxColorTransform), .source_rect = request.source.crop,
        .target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }, .sampler = 1, .operation = c.render_operation_over,
        .opacity = 32768, .flags = 0, .pixel_budget = 16 };
    var job = std.mem.zeroes(c.R4GfxJob);
    const empty = job;
    for (0..3) |_| {
        try t.expectEqual(c.status_busy, colors.color_yuv_render_submit(&handle, &request, &job));
        try t.expectEqualDeep(empty, job);
    }
    try t.expect(Model.virtual_starts == 3 and Model.maps == 1 and !Model.job_live);
    // Allocation/VA acknowledgement is separate from acceptance and rendering.
    Model.virtual_ack = true;
    for (0..6) |_| {
        const rc = colors.color_yuv_render_submit(&handle, &request, &job);
        if (rc == c.status_ok) break;
        try t.expectEqual(c.status_busy, rc);
    }
    try t.expect(job.slot != 0 and Model.job_live and Model.virtual_starts == 6 and Model.maps == 1);
    var memory: c.R4GfxMemoryInfo = undefined;
    try t.expectEqual(c.status_ok, api.memory_info(&handle, &memory));
    try t.expect(memory.resident_bytes == 196608 and memory.pinned_bytes == 196608 and memory.system_bytes == 65536);
    try t.expectEqual(c.status_limit, api.memory_trim(&handle, request.deadline_ns));
    try t.expect(Model.virtual_closes == 0);
    const maps = Model.virtual_starts;
    const count = Model.referenceCount();
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == count and Model.virtual_closes == 0);
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    // A second frame reuses both BO mappings and the prepared shader upload.
    try t.expectEqual(c.status_ok, colors.color_yuv_render_submit(&handle, &request, &job));
    try t.expect(Model.virtual_starts == maps and Model.maps == 1);
    Model.binding.reset_generation += 1;
    var refreshed: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &refreshed));
    var rejected = empty;
    try t.expectEqual(c.status_stale, colors.color_yuv_render_submit(&handle, &request, &rejected));
    try t.expectEqualDeep(empty, rejected);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expectEqual(@as(i32,1), Model.release(&source.reference));
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(Model.job_live and Model.virtual_closes == 0 and Model.referenceCount() >= 3);
    Model.status.flags = 0; // Engine stopped; canonical queue loans may retire.
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(!Model.job_live and Model.virtual_closes == 3 and Model.referenceCount() == 3);
    Model.retire_ack = true; // Separate map/RM retirement acknowledgement.
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
    for (Model.virtuals) |entry| try t.expect(entry.handle.id == 0);
    std.debug.print("native YUV: public encoder, one upload/no pixel maps, cached BO/VA reuse, reset and separate engine/map retirement: OK\n", .{});
}

fn checkNativeYuvRejection(config: *const c.R4GfxDeviceConfig) !void {
    Model.reset(); Model.operations = 29 | (@as(u64,1) << a.gfx_queue_operation_native);
    const colors = &@import("main.zig").r4gfx_color_v1;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    var source: a.GfxBufferReference = .{};
    try t.expectEqual(@as(i32,1), Model.create(&.{ .byte_length = 131072, .alignment = 65536, .modifier = 0x0300000000606011,
        .width = 4, .height = 32, .format = a.gfx_buffer_format_nv12, .plane_count = 2, .plane_offsets = .{0,65536,0,0}, .plane_pitches = .{64,64,0,0},
        .usage = 28, .location = 1, .adapter_id = Model.binding.adapter_id, .device_generation = 73, .driver_owner = 79 }, &source));
    var native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_abgr16161616f, .layout = 0 };
    var desc: c.R4GfxColorResourceDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxColorResourceDesc),
        .resource = descriptor(c.resource_image), .description = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription),
            .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_linear, .range = c.color_range_full,
            .alpha = c.color_alpha_optical, .precision = c.color_precision_float16, .flags = 0,
            .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 } };
    desc.resource.flags = c.image_target; desc.resource.source_kind = c.source_create_native; desc.resource.source_address = @intFromPtr(&native);
    var target: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_create(&handle, &desc, &target));
    var request = std.mem.zeroes(c.R4GfxYuvRenderRequest);
    request.version = 1; request.size = @sizeOf(c.R4GfxYuvRenderRequest); request.target = target; request.deadline_ns = native.deadline_ns;
    request.source = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvBufferImage), .format = 1, .width = 4, .height = 4, .plane_count = 2, .reserved = 0,
        .crop = .{ .x = 1, .y = 1, .width = 3, .height = 3 },
        .description = .{ .version = 1, .size = @sizeOf(c.R4GfxYuvDescription), .primaries = 1, .transfer = 1, .matrix = 1, .range = 2,
            .chroma_location = 1, .flags = 0, .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 },
        .plane0 = .{ .reference_id = source.reference.id, .reference_generation = source.reference.generation, .reserved = 0, .offset = 0, .byte_length = 65536, .pitch = 64 },
        .plane1 = .{ .reference_id = source.reference.id, .reference_generation = source.reference.generation, .reserved = 0, .offset = 65536, .byte_length = 65536, .pitch = 64 },
        .plane2 = std.mem.zeroes(c.R4GfxYuvBufferPlane) };
    request.transform = .{ .version = 1, .size = @sizeOf(c.R4GfxColorTransform), .source_rect = request.source.crop,
        .target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }, .sampler = 1, .operation = c.render_operation_over,
        .opacity = 32768, .flags = 0, .pixel_budget = 16 };
    var job = std.mem.zeroes(c.R4GfxJob);
    const empty = job;
    const device = try d.get(&handle, false);
    const target_entry = try device.resource(target, true);
    Model.virtual_reject_object = Model.ref(target_entry.backing.reference).object.?;
    Model.virtual_ack = true;
    // A real asynchronous terminal bind rejection is separate from physical
    // range retirement. It must reach the public caller without another map.
    var rejected = false;
    for (0..8) |_| {
        const rc = colors.color_yuv_render_submit(&handle, &request, &job);
        try t.expectEqualDeep(empty, job);
        if (rc == c.status_unsupported) { rejected = true; break; }
        try t.expectEqual(c.status_busy, rc);
    }
    try t.expect(rejected and !Model.job_live);
    const starts = Model.virtual_starts;
    Model.virtual_reject_object = null;
    // Changing the provider cannot change this exact attempt's rejection.
    // CPU stepping and held retirement must not turn it into retries/BUSY.
    for (0..8) |_| {
        var info: c.R4GfxDeviceInfo = undefined;
        try t.expectEqual(c.status_ok, api.device_info(&handle, &info));
        try t.expectEqual(c.status_unsupported, colors.color_yuv_render_submit(&handle, &request, &job));
        try t.expectEqualDeep(empty, job);
        try t.expect(Model.virtual_starts == starts and !Model.job_live);
    }
    Model.retire_ack = true;
    for (0..4) |_| {
        try t.expectEqual(c.status_unsupported, colors.color_yuv_render_submit(&handle, &request, &job));
        try t.expectEqualDeep(empty, job);
        try t.expect(Model.virtual_starts == starts and !Model.job_live);
    }
    // Import authentication precedes either live or failed cache lookup.
    var stale = request;
    stale.source.plane0.reference_generation += 1;
    try t.expectEqual(c.status_stale, colors.color_yuv_render_submit(&handle, &stale, &job));
    try t.expectEqualDeep(empty, job);
    try t.expect(Model.virtual_starts == starts and !Model.job_live);
    // A fresh attempt may retry the same BO after its actual old range closes.
    request.deadline_ns += 1;
    for (0..8) |_| {
        const rc = colors.color_yuv_render_submit(&handle, &request, &job);
        if (rc == c.status_ok) break;
        try t.expectEqual(c.status_busy, rc);
    }
    try t.expect(job.slot != 0 and Model.job_live and Model.virtual_starts == starts + 2);
    Model.status.phase = a.gfx_queue_phase_terminal;
    Model.status.result = a.gfx_queue_result_complete;
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expectEqual(@as(i32,1), Model.release(&source.reference));
    var closed = false;
    for (0..4) |_| {
        const rc = api.device_close(&handle);
        if (rc == c.status_ok) { closed = true; break; }
        try t.expectEqual(c.status_busy, rc);
    }
    try t.expect(closed and Model.referenceCount() == 0 and Model.premature_closes == 0);
    for (Model.virtuals) |entry| try t.expect(entry.handle.id == 0);
    std.debug.print("native YUV: exact terminal rejection survives held/final map retirement; no retries, stale import rejected, new attempt allowed, full cleanup: OK\n", .{});
}

fn checkResidency(config: *const c.R4GfxDeviceConfig, imports: *[6]a.R4XStartImport, use_amd: bool) !void {
    const residency = @import("device_residency.zig");
    const native_bytes: u64 = if (use_amd) 4096 else 65536;
    Model.reset(); Model.operations = 15;
    var amd_fixture: AmdFixture = .{};
    if (use_amd) amd_fixture.bind(imports, Model.operations);
    defer if (use_amd) amd_fixture.close(imports);
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const device = try d.get(&handle, false);
    const native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_xrgb8888, .layout = 0 };
    var desc = descriptor(c.resource_image); desc.source_kind = c.source_create_native;
    desc.source_address = @intFromPtr(&native); desc.flags = c.image_target;
    var first: c.R4GfxResource = undefined; var pinned: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &desc, &first));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &desc, &pinned));
    const item = try device.resource(first, true);
    const protected = try device.resource(pinned, true);
    try t.expectEqual(c.status_ok, api.resource_priority(&handle, &first, 3));
    try t.expectEqual(c.status_ok, api.resource_priority(&handle, &pinned, c.memory_priority_pinned));
    const original_buffer = item.backing.buffer;
    const first_object = Model.ref(item.backing.reference).object.?;
    for (0..4) |row| {
        for (0..16) |column| Model.objects[first_object].bytes[row * item.image.pitch + column] = @intCast(row * 16 + column);
    }
    item.job_refs = 1;
    try t.expectEqual(c.status_limit, api.memory_trim(&handle, native.deadline_ns));
    item.job_refs = 0;
    const reference = item.backing.reference;
    var alias_desc = descriptor(c.resource_image); alias_desc.source_kind = c.source_import_buffer;
    alias_desc.source_address = @intFromPtr(&reference);
    var alias: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &alias_desc, &alias));
    try t.expectEqual(c.status_limit, api.memory_trim(&handle, native.deadline_ns));
    try t.expect(residency.snapshot(device).resident_bytes == 2 * native_bytes); // Shared BO counted once.
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &alias));
    try t.expectEqual(c.status_ok, api.memory_trim(&handle, native.deadline_ns));
    try t.expect(item.residency_busy and item.job_refs == 1 and device.residency_work.?.index == first.slot - 1);
    try driveResidencyCopy(device);
    // Logical completion alone does not permit replacement or backing release.
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete;
    residency.step(device);
    try t.expect(item.residency_busy and !item.evicted and Model.referenceCount() == 3 and std.meta.eql(item.backing.buffer, original_buffer));
    Model.complete(); residency.step(device); residency.step(device);
    try t.expect(device.residency_work == null and item.evicted and !item.residency_busy and item.job_refs == 0 and
        !std.meta.eql(item.backing.buffer, original_buffer) and std.meta.eql(device.resourceHandle(first.slot - 1), first));
    const saved = Model.ref(item.backing.reference).object.?;
    for (0..64) |index| try t.expect(Model.objects[saved].bytes[index] == index);
    const snapshot = residency.snapshot(device);
    try t.expect(snapshot.evicted_bytes == native_bytes and snapshot.system_bytes == 64 and snapshot.pinned_bytes == native_bytes);
    var memory_info: c.R4GfxMemoryInfo = undefined;
    try t.expectEqual(c.status_ok, api.memory_info(&handle, &memory_info));
    try t.expect(memory_info.version == 1 and memory_info.size == 104 and memory_info.phase == c.memory_phase_idle and
        memory_info.evicted_bytes == native_bytes and memory_info.evictions == 1 and memory_info.memory_generation == @as(u64, if (use_amd) 97 else 73));
    // Two requests wait behind an actual readback. The higher-priority image
    // reconstructs first; equal-priority order is the retained request order.
    try t.expectEqual(c.status_ok, api.resource_priority(&handle, &pinned, 200));
    try t.expectEqual(c.status_ok, api.memory_trim(&handle, native.deadline_ns));
    try driveResidencyCopy(device);
    try t.expectEqual(c.status_busy, api.resource_resident(&handle, &first, native.deadline_ns));
    try t.expect(device.residency_pending == 1);
    Model.complete(); residency.step(device);
    try t.expectEqual(c.status_busy, api.resource_resident(&handle, &pinned, native.deadline_ns));
    try t.expect(device.residency_work.?.index == pinned.slot - 1 and device.residency_pending == 1);
    try driveResidencyCopy(device);
    Model.complete(); residency.step(device); residency.step(device);
    residency.step(device); // Next pending image gets the available worker.
    try t.expect(device.residency_work.?.index == first.slot - 1 and device.residency_pending == 0);
    try driveResidencyCopy(device);
    Model.complete(); residency.step(device); residency.step(device);
    try t.expect(!item.evicted and !protected.evicted and device.residency_evictions == 2 and device.residency_restores == 2);
    try t.expectEqual(c.status_ok, api.resource_priority(&handle, &pinned, c.memory_priority_pinned));
    try t.expectEqual(c.status_ok, api.memory_trim(&handle, native.deadline_ns));
    try driveResidencyCopy(device);
    Model.complete(); residency.step(device); residency.step(device);
    // RAM contents survive a backend reset. Only still-native resources lose
    // their generation; reconstruction must bind the current backend anew.
    Model.binding.reset_generation += 1;
    if (use_amd) amd_fixture.backend[0].binding = Model.binding;
    var state: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &state));
    try t.expect(!item.invalidated and protected.invalidated);
    try t.expectEqual(c.status_busy, api.resource_resident(&handle, &first, native.deadline_ns));
    try driveResidencyCopy(device);
    Model.complete(); residency.step(device); residency.step(device);
    try t.expect(!item.evicted and !item.invalidated and device.residency_restores == 3 and device.residency_evictions == 3 and Model.referenceCount() == 2);
    const restored = Model.ref(item.backing.reference).object.?;
    for (0..4) |row| for (0..16) |column| try t.expect(Model.objects[restored].bytes[row * item.image.pitch + column] == row * 16 + column);
    // Actual failed native allocation starts bounded reclamation; its failed
    // request is closed and does not leak alongside the retained copy.
    Model.native_result = a.gfx_buffer_error_budget;
    var output = first;
    try t.expectEqual(c.status_busy, api.resource_create(&handle, &desc, &output));
    try t.expectEqualDeep(first, output);
    try t.expect(Model.native_handle.id == 0 and device.residency_work != null);
    Model.native_result = 1;
    try driveResidencyCopy(device);
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 2 and Model.premature_closes == 0);
    // App close cancels logically, but both copy endpoints stay held until
    // the modeled engine has stopped. Then the ordinary owner releases all.
    Model.status.flags = 0;
    for (0..5) |_| {
        if (api.device_close(&handle) == c.status_ok) break;
    } else return error.TestUnexpectedResult;
    try t.expect(Model.referenceCount() == 0 and !Model.job_live and Model.premature_closes == 0);
}
fn driveResidencyCopy(device: *d.Device) !void {
    for (0..10) |_| {
        const work = device.residency_work orelse return error.TestUnexpectedResult;
        if (work.phase == .copy) { try t.expect(Model.job_live); return; }
        @import("device_residency.zig").step(device);
    }
    return error.TestUnexpectedResult;
}

fn checkColorResources(handle: *const c.R4GfxDevice) !void {
    const original_maps = Model.maps;
    defer Model.maps = original_maps;
    const colors = &@import("main.zig").r4gfx_color_v1;
    const desc: c.R4GfxColorDescription = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription),
        .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_srgb, .range = c.color_range_full,
        .alpha = c.color_alpha_opaque, .precision = c.color_precision_unorm8, .flags = 0,
        .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 };
    var pixels: [64]u8 align(8) = @splat(0xff);
    var source_desc: c.R4GfxColorResourceDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxColorResourceDesc), .resource = cpuImage(&pixels), .description = desc };
    var source: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_create(handle, &source_desc, &source));
    defer _ = api.resource_release(handle, &source);
    var linear = desc;
    linear.transfer = c.color_transfer_linear; linear.precision = c.color_precision_float16; linear.alpha = c.color_alpha_optical;
    var target_desc: c.R4GfxColorResourceDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxColorResourceDesc), .resource = descriptor(c.resource_image), .description = linear };
    target_desc.resource.flags = c.image_target; target_desc.resource.source_kind = c.source_create_system;
    target_desc.resource.image = .{ .cpu_address = 0, .byte_length = 128, .pitch = 32, .width = 4, .height = 4, .format = c.format_abgr16161616f, .reserved = 0 };
    var target: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_unsupported, api.resource_create(handle, &target_desc.resource, &target));
    try t.expectEqual(c.status_ok, colors.color_resource_create(handle, &target_desc, &target));
    defer _ = api.resource_release(handle, &target);
    var metadata: c.R4GfxColorDescription = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_info(handle, &target, &metadata));
    try t.expectEqualDeep(linear, metadata);
    const request: c.R4GfxColorTransform = .{ .version = 1, .size = @sizeOf(c.R4GfxColorTransform),
        .source_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }, .target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 },
        .sampler = c.render_sampler_nearest, .operation = c.render_operation_blit, .opacity = 65535, .flags = 0, .pixel_budget = 16 };
    var stats: c.R4GfxCpuStats = undefined;
    const maps = Model.maps;
    try t.expectEqual(c.status_alias, colors.color_resource_transform(handle, &source, &target, &request, @ptrCast(&pixels)));
    try t.expectEqual(c.status_ok, colors.color_resource_transform(handle, &source, &target, &request, &stats));
    try t.expect(stats.pixels == 16 and stats.write_bytes == 128 and Model.maps == maps + 1);
    const device = try d.get(handle, false);
    const target_item = try device.resource(target, true);
    const object = Model.references[target_item.backing.reference.id - 1].object.?;
    for (0..16) |i| try t.expectEqualSlices(u8, &.{ 0, 0x3c, 0, 0x3c, 0, 0x3c, 0, 0x3c }, Model.objects[object].bytes[i * 8..][0..8]);
    // Same pixels with a distinct color description cannot reuse one logical
    // resource, nor overwrite the first resource's immutable interpretation.
    source_desc.description.transfer = c.color_transfer_linear;
    var alternate: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_create(handle, &source_desc, &alternate));
    defer _ = api.resource_release(handle, &alternate);
    try t.expect(!std.meta.eql(source, alternate));
    try t.expectEqual(c.status_ok, colors.color_resource_info(handle, &source, &metadata));
    try t.expectEqualDeep(desc, metadata);
    const guard = @import("color_resource.zig").nativeTransition;
    const from = try device.resource(source, true);
    try guard(from, target_item, c.render_transfer_srgb_decode, c.render_operation_over, 0);
    try t.expectError(error.Unsupported, guard(from, target_item, c.render_transfer_identity, c.render_operation_over, 0));
    try t.expectError(error.Unsupported, guard(target_item, from, c.render_transfer_srgb_encode, c.render_operation_over, 0));
    Model.fail_unmap = true;
    try t.expectEqual(c.status_busy, colors.color_resource_transform(handle, &source, &target, &request, &stats));
    try t.expect(target_item.map.lease.id != 0);
    Model.fail_unmap = false;
    try t.expect(device.cleanResources());
    // A named read-only view retains the BO after the writer resource is
    // released, while forbidding an incompatible reinterpretation.
    var parent: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_create(handle, &target_desc, &parent));
    var view_desc = target_desc;
    view_desc.resource = descriptor(c.resource_image);
    view_desc.resource.source_kind = c.source_color_view;
    view_desc.resource.source_address = @intFromPtr(&parent);
    var view: c.R4GfxResource = undefined;
    view_desc.description.peak *= 2;
    try t.expectEqual(c.status_unsupported, colors.color_resource_create(handle, &view_desc, &view));
    view_desc.description = linear;
    try t.expectEqual(c.status_ok, colors.color_resource_create(handle, &view_desc, &view));
    defer _ = api.resource_release(handle, &view);
    const parent_item = try device.resource(parent, true);
    const view_item = try device.resource(view, true);
    try t.expectEqualDeep(parent_item.backing.buffer, view_item.backing.buffer);
    try t.expect(!std.meta.eql(parent_item.backing.reference, view_item.backing.reference) and view_item.flags == 0);
    try t.expectEqual(c.status_ok, api.resource_release(handle, &parent));
    try t.expectEqual(c.status_ok, colors.color_resource_info(handle, &view, &metadata));
    try t.expectEqualDeep(linear, metadata);
}

fn checkOutputSwapchains(input: c.R4GfxDeviceConfig) !void {
    Model.reset();
    var config = input;
    config.preferred_adapter = Model.binding.adapter_id; config.flags = c.device_software_only;
    for (&Model.outputs, 0..) |*output, i| {
        output.target = .{ .adapter_id = Model.binding.adapter_id, .connector_id = @intCast(i + 2),
            .device_generation = Model.binding.device_generation, .connection_generation = i + 10, .display_generation = i + 100, .head_id = @intCast(i + 2) };
        output.info = .{ .backend = Model.binding, .flags = a.display_presentation_info_active | a.display_presentation_info_native,
            .head_id = output.target.head_id, .display_generation = output.target.display_generation, .sequence = 1,
            .width = 4, .height = 4, .format = c.format_xrgb8888, .policies = 7, .buffer_count = 2, .plane_count = 1,
            .interval_ns = if (i == 0) 16_666_667 else 10_000_000 };
    }
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(&config, &handle));
    var images: [2][2]c.R4GfxResource = undefined;
    var chains: [2]c.R4GfxSwapchain = undefined;
    var frames: [2]c.R4GfxSwapchainFrame = undefined;
    var statuses: [2]c.R4GfxSwapchainStatus = undefined;
    var resource = descriptor(c.resource_image);
    resource.source_kind = c.source_create_system; resource.flags = c.image_target;
    resource.image = .{ .cpu_address = 0, .byte_length = 64, .pitch = 16, .width = 4, .height = 4, .format = c.format_xrgb8888, .reserved = 0 };
    for (&images, 0..) |*pair, i| {
        for (pair) |*image| try t.expectEqual(c.status_ok, api.resource_create(&handle, &resource, image));
        const desc: c.R4GfxSwapchainDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxSwapchainDesc), .head_id = Model.outputs[i].target.head_id,
            .policy = c.present_policy_fifo, .flags = 0, .count = 2, .display_generation = Model.outputs[i].target.display_generation, .images = @intFromPtr(pair) };
        try t.expectEqual(c.status_ok, api.swapchain_open(&handle, &desc, &chains[i]));
        try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chains[i], 0, &frames[i]));
        try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chains[i], &presentRequest(frames[i])));
        try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chains[i], &statuses[i]));
    }
    try t.expect(Model.outputs[0].live and Model.outputs[1].live and Model.present_calls == 0);
    try t.expect(Model.outputs[0].status.fence.timeline != Model.outputs[1].status.fence.timeline);
    // Resize arrives before either physical output has completed. Admission
    // must preserve the held pool, even if a receiver disappears next.
    const references = Model.referenceCount();
    const mappings = Model.maps;
    const resize: c.R4GfxSwapchainDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxSwapchainDesc),
        .head_id = Model.outputs[0].target.head_id, .policy = c.present_policy_fifo, .flags = 0,
        .count = 2, .display_generation = Model.outputs[0].target.display_generation, .images = @intFromPtr(&images[0]) };
    try t.expectEqual(c.status_busy, api.swapchain_resize(&handle, &chains[0], &resize));
    try t.expect(Model.referenceCount() == references and Model.maps == mappings and Model.premature_closes == 0);
    const slow = Model.outputs[0].status;
    Model.outputs[1].status.phase = a.gfx_queue_phase_terminal;
    Model.outputs[1].status.result = a.gfx_queue_result_complete; Model.outputs[1].status.flags = 0;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chains[1], &statuses[1]));
    try t.expectEqual(c.status_ok, api.swapchain_release(&handle, &chains[1], &frames[1]));
    try t.expectEqualDeep(slow, Model.outputs[0].status);
    // One receiver vanishes while its GPU read still exists. It cannot be
    // retired by the other output's receipt or redirect work to the primary.
    Model.outputs[0].connected = false;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chains[0], &statuses[0]));
    try t.expectEqual(c.status_busy, api.swapchain_close(&handle, &chains[0]));
    try t.expect(Model.outputs[0].live and Model.outputs[0].status.flags != 0);
    Model.outputs[0].status.flags = 0;
    try t.expectEqual(c.status_ok, api.swapchain_close(&handle, &chains[0]));
    // The kernel removes empty old timelines during device reset. The last
    // frame is already released, so closing its absent queue is idempotent.
    const device = try d.get(&handle, true);
    const old_queue = device.chains[chains[1].slot - 1].queue;
    try t.expect(old_queue.timeline != 0 and !Model.outputs[1].live);
    try t.expectEqual(a.gfx_queue_ok, Model.close(&old_queue));
    try t.expectEqual(a.gfx_queue_error_stale, Model.close(&old_queue));
    try t.expectEqual(c.status_ok, api.swapchain_close(&handle, &chains[1]));
    try t.expectEqual(c.status_ok, api.swapchain_close(&handle, &chains[1]));
    for (&images) |*pair| for (pair) |*image| try t.expectEqual(c.status_ok, api.resource_release(&handle, image));
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.maps == 0 and Model.premature_closes == 0 and Model.present_calls == 0);
    for (&Model.objects) |*object| try t.expect(!object.live);
    for (&Model.queues) |*queue| try t.expect(queue.handle.timeline == 0);
    for (&Model.outputs) |*output| try t.expect(!output.live);
}

fn chainFrame(status: c.R4GfxSwapchainStatus, frame: c.R4GfxSwapchainFrame) c.R4GfxSwapchainFrameStatus {
    return switch (frame.slot) { 1 => status.frame0, 2 => status.frame1, 3 => status.frame2, else => unreachable };
}
fn presentRequest(frame: c.R4GfxSwapchainFrame) c.R4GfxSwapchainPresent {
    return .{ .version = 1, .size = @sizeOf(c.R4GfxSwapchainPresent), .frame = frame, .render_job = std.mem.zeroes(c.R4GfxJob),
        .deadline_ns = 100000, .intent = 0, .blockers = 0 };
}
fn checkSwapchains(config: *const c.R4GfxDeviceConfig, imports: *[6]a.R4XStartImport) !void {
    Model.reset();
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    var pixels: [4][64]u8 align(8) = @splat(@splat(0xa5));
    var images: [2]c.R4GfxResource = undefined;
    for (&images, 0..) |*image, i| try t.expectEqual(c.status_ok, api.resource_create(&handle, &cpuImage(&pixels[i]), image));
    var desc: c.R4GfxSwapchainDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxSwapchainDesc), .head_id = 2,
        .policy = c.present_policy_fifo, .flags = c.present_require_vsync, .count = 2, .display_generation = 1, .images = @intFromPtr(&images) };
    var chain = std.mem.zeroes(c.R4GfxSwapchain); chain.generation = 77;
    const untouched = chain;
    try t.expectEqual(c.status_unsupported, api.swapchain_open(&handle, &desc, &chain));
    try t.expectEqualDeep(untouched, chain);
    desc.flags = 0;
    const second = images[1]; images[1] = images[0];
    try t.expectEqual(c.status_alias, api.swapchain_open(&handle, &desc, &chain));
    try t.expectEqualDeep(untouched, chain);
    images[1] = second;
    try t.expectEqual(c.status_ok, api.swapchain_open(&handle, &desc, &chain));
    var first: c.R4GfxSwapchainFrame = undefined; var next: c.R4GfxSwapchainFrame = undefined;
    try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chain, 100, &first));
    try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chain, 0, &next));
    var denied = first;
    try t.expectEqual(c.status_busy, api.swapchain_acquire(&handle, &chain, 0, &denied));
    try t.expectEqualDeep(first, denied);
    var fill_desc = descriptor(c.resource_pipeline); fill_desc.operation = c.render_operation_fill;
    var pipeline: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &fill_desc, &pipeline));
    var draw = std.mem.zeroes(c.R4GfxDraw);
    draw.target = first.image; draw.pipeline = pipeline; draw.color = 0x123456;
    draw.target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 };
    const batch: c.R4GfxRenderBatch = .{ .commands = @intFromPtr(&draw), .command_count = 1, .flags = 0, .pixel_budget = 16 };
    var rendered: c.R4GfxRenderStats = undefined;
    try t.expectEqual(c.status_ok, api.render(&handle, &batch, &rendered));
    try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chain, &presentRequest(first)));
    var status: c.R4GfxSwapchainStatus = undefined;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expectEqualSlices(u32, &(@as([16]u32, @splat(0x123456))), &Model.shown);
    const frame = chainFrame(status, first);
    try t.expect(frame.phase == 4 and frame.result == 2 and frame.visible_ns == 0 and frame.copied_ns >= frame.submitted_ns and
        frame.held_flags == 0 and status.held_count == 0 and frame.input_ns == 100);
    try t.expectEqual(c.status_ok, api.swapchain_release(&handle, &chain, &first));
    Model.fail_present = true;
    try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chain, &presentRequest(next)));
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(chainFrame(status, next).result == 4 and Model.present_calls == 1);
    try t.expectEqualSlices(u32, &(@as([16]u32, @splat(0x123456))), &Model.shown);
    Model.fail_present = false;
    Model.presentation_info.display_generation += 1; Model.presentation_info.width = 2;
    desc.display_generation += 1;
    for (&images, 0..) |*image, i| {
        var resized = cpuImage(&pixels[i + 2]); resized.image.width = 2; resized.source_generation = 2;
        try t.expectEqual(c.status_ok, api.resource_create(&handle, &resized, image));
    }
    try t.expectEqual(c.status_busy, api.swapchain_resize(&handle, &chain, &desc));
    try t.expectEqual(c.status_ok, api.swapchain_release(&handle, &chain, &next));
    try t.expectEqual(c.status_ok, api.swapchain_resize(&handle, &chain, &desc));
    try t.expectEqual(c.status_stale, api.swapchain_release(&handle, &chain, &first));
    Model.presentation_info.flags = a.display_presentation_info_occluded;
    try t.expectEqual(c.status_occluded, api.swapchain_acquire(&handle, &chain, 0, &next));
    Model.presentation_info.flags = a.display_presentation_info_active;
    try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chain, 0, &next));
    try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chain, &presentRequest(next)));
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(chainFrame(status, next).result == 2 and Model.present_calls == 2);
    try t.expectEqual(c.status_ok, api.swapchain_close(&handle, &chain));
    try t.expectEqual(c.status_ok, api.swapchain_close(&handle, &chain));
    try t.expectEqual(c.status_ok, api.device_close(&handle));

    // Actual provider jobs and exact delayed feedback, with native execution
    // deliberately supplied by the existing queue transport fixture.
    for ([_]bool{false, true}) |use_amd| {
    Model.reset(); Model.operations = 61;
    var amd_fixture: AmdFixture = .{};
    if (use_amd) amd_fixture.bind(imports, Model.operations);
    defer if (use_amd) amd_fixture.close(imports);
    Model.presentation_info.backend = Model.binding; Model.presentation_info.path = 1; Model.presentation_info.policies = 3;
    Model.presentation_info.flags = a.display_presentation_info_active | a.display_presentation_info_native |
        a.display_presentation_info_synchronized | a.display_presentation_info_visibility;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 100000, .width = 4, .height = 4, .format = c.format_xrgb8888, .layout = 0 };
    var native_desc = descriptor(c.resource_image); native_desc.flags = c.image_target;
    native_desc.source_kind = c.source_create_native; native_desc.source_address = @intFromPtr(&native);
    for (&images) |*image| try t.expectEqual(c.status_ok, api.resource_create(&handle, &native_desc, image));
    desc.display_generation = 1; desc.flags = c.present_require_vsync;
    try t.expectEqual(c.status_ok, api.swapchain_open(&handle, &desc, &chain));
    try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chain, 0, &first));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &fill_desc, &pipeline));
    var native_draw = std.mem.zeroes(c.R4GfxRenderRequest);
    native_draw.version = 1; native_draw.size = @sizeOf(c.R4GfxRenderRequest); native_draw.deadline_ns = 100000;
    native_draw.target = first.image; native_draw.pipeline = pipeline; native_draw.opacity = 255;
    native_draw.color = 0x123456; native_draw.target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }; native_draw.scissor = native_draw.target_rect;
    var producer: c.R4GfxJob = undefined;
    try t.expectEqual(c.status_ok, api.render_submit(&handle, &native_draw, &producer));
    var queued = presentRequest(first); queued.render_job = producer;
    try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chain, &queued));
    try t.expectEqual(c.status_busy, api.job_release(&handle, &producer));
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(chainFrame(status, first).phase == 2 and status.held_count == 1);
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
    Model.status.completed_ns = Model.clock;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expectEqual(c.status_ok, api.job_release(&handle, &producer));
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(Model.job_request.operation == a.gfx_queue_operation_present and Model.maps == 0);
    const source_fence = Model.status.fence;
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expectEqual(c.status_busy, api.swapchain_release(&handle, &chain, &first));
    try t.expect(status.held_count == 1);
    Model.status.flags = 0; Model.status.completed_ns = Model.clock;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(status.held_count == 0 and chainFrame(status, first).phase == 3 and chainFrame(status, first).visible_ns == 0);
    Model.feedback = .{ .flags = a.display_presentation_flag_available, .head_id = 2, .backend = Model.binding, .display_generation = 1,
        .source_timeline = source_fence.timeline, .source_point = source_fence.point, .visible_ns = Model.clock + 1 };
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(chainFrame(status, first).result == 1 and chainFrame(status, first).visible_ns == Model.feedback.?.visible_ns);
    var copy_info: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_info(&handle, &copy_info));
    try t.expectEqual(@as(u64, 64), copy_info.gpu_copy_bytes);
    try t.expectEqual(c.status_ok, api.swapchain_release(&handle, &chain, &first));
    try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chain, 0, &next));
    try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chain, &presentRequest(next)));
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expectEqual(c.status_busy, api.device_close(&handle));
    try t.expect(Model.job_live and Model.referenceCount() == 2);
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and !Model.job_live and Model.premature_closes == 0);
    }
}

fn checkTiledPreparation(config: *const c.R4GfxDeviceConfig) !void {
    try checkDirectSwapchain(config);
    for ([_]u32{c.prepare_use_texture,c.prepare_use_scanout}) |uses| {
        Model.reset(); Model.operations = 29;
        var handle: c.R4GfxDevice = undefined;
        try t.expectEqual(c.status_ok,api.device_open(config,&handle));
        const device = try d.get(&handle,false);
        var desc = descriptor(c.resource_image); desc.source_kind = c.source_create_system;
        desc.image = .{ .cpu_address = 0, .byte_length = 64, .pitch = 16, .width = 4, .height = 4, .format = c.format_argb8888, .reserved = 0 };
        var source: c.R4GfxResource = undefined;
        try t.expectEqual(c.status_ok,api.resource_create(&handle,&desc,&source));
        var ready: [1]c.R4GfxCopyFence = undefined;
        var request: c.R4GfxImagePrepareRequest = .{ .version = 1, .size = @sizeOf(c.R4GfxImagePrepareRequest),
            .source = source, .uses = uses, .preference = c.prepare_layout_compatible, .flags = 0,
            .deadline_ns = 99999999, .byte_budget = 65536, .dependency_count = 0, .dependencies = 0,
            .ready_dependencies = @intFromPtr(&ready), .ready_capacity = 1, .reserved = 0 };
        var result: c.R4GfxPreparedImage = undefined;
        const source_resource = try device.resource(source,true);
        source_resource.descriptor.modifier = 1;
        try t.expectEqual(c.status_unsupported,api.image_prepare(&handle,&request,&result));
        try t.expect(Model.native_starts == 0 and Model.referenceCount() == 1);
        source_resource.descriptor.modifier = 0;
        try t.expectEqual(c.status_ok,api.image_prepare(&handle,&request,&result));
        try t.expect(result.flags == c.prepared_copy_pending and Model.maps == 0 and Model.native_request.layout == 1 and
            Model.native_request.usage == @as(u32,if (uses == c.prepare_use_scanout) 60 else 28) and
            Model.job_request.source_pitch == 16 and Model.job_request.target_pitch == 64 and Model.job_request.byte_length == 16);
        // A second conversion forwards readiness to submission. This one-job
        // fixture rejects it as busy; the new target must be cleaned while
        // the first image/job and caller output remain intact.
        request.dependencies = @intFromPtr(&ready); request.dependency_count = 1;
        const untouched = result;
        try t.expectEqual(c.status_busy,api.image_prepare(&handle,&request,&result));
        try t.expectEqualDeep(untouched,result);
        try t.expect(Model.dependency_seen and Model.native_starts == 2 and Model.referenceCount() == 2);
        // Do not fabricate tiled pixel completion in this generic fixture.
        // NVIDIA's separate CE/GR owner case executes and checks those bytes.
        Model.status.phase = a.gfx_queue_phase_terminal; Model.status.flags = 0; Model.status.result = a.gfx_queue_result_failed;
        try t.expectEqual(c.status_ok,api.job_release(&handle,&result.job));
        try t.expectEqual(c.status_ok,api.resource_release(&handle,&result.image));
        try t.expectEqual(c.status_ok,api.resource_release(&handle,&source));
        try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
        try t.expectEqual(c.status_ok,api.device_close(&handle));
    }
}

fn checkDirectSwapchain(config: *const c.R4GfxDeviceConfig) !void {
    Model.reset(); Model.operations = 253;
    Model.presentation_info.backend = Model.binding; Model.presentation_info.path = 1; Model.presentation_info.policies = 3;
    Model.presentation_info.flags = a.display_presentation_info_active | a.display_presentation_info_native |
        a.display_presentation_info_synchronized | a.display_presentation_info_visibility | a.display_presentation_info_direct;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 100000, .width = 4, .height = 4, .format = c.format_xrgb8888, .layout = 0 };
    var resource = descriptor(c.resource_image); resource.flags = c.image_target;
    resource.source_kind = c.source_create_native_scanout; resource.source_address = @intFromPtr(&native);
    var images: [2]c.R4GfxResource = undefined;
    for (&images) |*image| try t.expectEqual(c.status_ok, api.resource_create(&handle, &resource, image));
    try t.expect(Model.native_request.usage == 60 and Model.native_request.layout == 0);
    const desc: c.R4GfxSwapchainDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxSwapchainDesc), .head_id = 2,
        .policy = c.present_policy_fifo, .flags = c.present_require_vsync, .count = 2, .display_generation = 1, .images = @intFromPtr(&images) };
    var chain: c.R4GfxSwapchain = undefined; var frame: c.R4GfxSwapchainFrame = undefined;
    var status: c.R4GfxSwapchainStatus = undefined;
    try t.expectEqual(c.status_ok, api.swapchain_open(&handle, &desc, &chain));
    try t.expectEqual(c.status_ok, api.swapchain_acquire(&handle, &chain, 0, &frame));
    var present = presentRequest(frame); present.intent = 1;
    try t.expectEqual(c.status_ok, api.swapchain_present(&handle, &chain, &present));
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(Model.job_request.operation == a.gfx_queue_operation_direct_present and Model.maps == 0);
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete;
    Model.status.completed_ns = Model.clock;
    Model.feedback = .{ .flags = a.display_presentation_flag_available | a.display_presentation_flag_direct, .head_id = 2,
        .backend = Model.binding, .display_generation = 1, .source_timeline = Model.status.fence.timeline,
        .source_point = Model.status.fence.point, .visible_ns = Model.clock + 1 };
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    const visible = chainFrame(status, frame);
    try t.expect(visible.result == 1 and visible.path == c.present_path_direct and visible.visible_ns != 0 and visible.released_ns == 0 and status.held_count == 1);
    try t.expectEqual(c.status_busy, api.swapchain_release(&handle, &chain, &frame));
    // An unchanged visible front must remain pinned even after its request
    // deadline. Close requests retirement, preserving its completed receipt.
    Model.clock = 100001;
    try t.expectEqual(c.status_busy, api.swapchain_close(&handle, &chain));
    try t.expect(Model.retire_requested and Model.job_live and Model.referenceCount() == 2 and Model.status.result == a.gfx_queue_result_complete);
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.swapchain_poll(&handle, &chain, &status));
    try t.expect(chainFrame(status, frame).released_ns > visible.visible_ns and status.held_count == 0);
    try t.expectEqual(c.status_ok, api.swapchain_close(&handle, &chain));
    // Retirement of a retained direct front is not a copy. Keep the exact
    // completed-receipt accounting check after final retirement, where the
    // old implementation incorrectly charged the complete image size.
    var direct_info: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_info(&handle, &direct_info));
    try t.expectEqual(@as(u64, 0), direct_info.gpu_copy_bytes);
    try t.expect(direct_info.cpu_read_bytes == 0 and direct_info.cpu_write_bytes == 0 and direct_info.upload_bytes == 0);
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
}

fn checkImagePreparation(base_config: *const c.R4GfxDeviceConfig) !void {
    for ([_]bool{false,true}) |software| {
        Model.reset(); Model.operations = 29;
        var config = base_config.*; config.flags = if (software) c.device_software_only else 0;
        var handle: c.R4GfxDevice = undefined;
        try t.expectEqual(c.status_ok,api.device_open(&config,&handle));
        const device = try d.get(&handle,false);
        var source_desc = descriptor(c.resource_image);
        source_desc.source_kind = c.source_create_system;
        source_desc.image = .{ .cpu_address = 0, .byte_length = 64, .pitch = 16, .width = 4, .height = 4, .format = c.format_argb8888, .reserved = 0 };
        var source: c.R4GfxResource = undefined;
        try t.expectEqual(c.status_ok,api.resource_create(&handle,&source_desc,&source));
        const source_resource = try device.resource(source,true);
        @memset(Model.objects[Model.ref(source_resource.backing.reference).object.?].bytes[0..64],0x53);
        var ready: [1]c.R4GfxCopyFence = .{std.mem.zeroes(c.R4GfxCopyFence)}; ready[0].timeline = 79;
        const untouched_ready = ready;
        var output: c.R4GfxPreparedImage = std.mem.zeroes(c.R4GfxPreparedImage); output.flags = 79;
        const untouched = output;
        var request: c.R4GfxImagePrepareRequest = .{ .version = 1, .size = @sizeOf(c.R4GfxImagePrepareRequest),
            .source = source, .uses = c.prepare_use_texture, .preference = c.prepare_layout_linear, .flags = c.prepare_force_copy,
            .deadline_ns = 99999999, .byte_budget = 0, .dependencies = 0, .dependency_count = 0,
            .ready_dependencies = @intFromPtr(&ready), .ready_capacity = 1, .reserved = 0 };
        // A budget/capacity rejection precedes both allocation and output.
        try t.expectEqual(c.status_limit,api.image_prepare(&handle,&request,&output));
        try t.expectEqualDeep(untouched,output); try t.expectEqualDeep(untouched_ready,ready);
        try t.expect(Model.native_starts == 0 and Model.referenceCount() == 1 and !Model.job_live);
        request.byte_budget = if (software) 4096 else 65536;
        request.ready_capacity = 0; request.ready_dependencies = 0;
        try t.expectEqual(c.status_limit,api.image_prepare(&handle,&request,&output));
        request.ready_capacity = 1; request.ready_dependencies = @intFromPtr(&output);
        try t.expectEqual(c.status_alias,api.image_prepare(&handle,&request,&output));
        request.ready_dependencies = @intFromPtr(&ready);
        if (!software) {
            Model.bad_native_layout = true;
            try t.expectEqual(c.status_unsupported,api.image_prepare(&handle,&request,&output));
            try t.expect(Model.referenceCount() == 1 and Model.native_handle.id == 0 and !Model.job_live);
            try t.expectEqualDeep(untouched,output); try t.expectEqualDeep(untouched_ready,ready);
            Model.bad_native_layout = false;
        }
        try t.expectEqual(c.status_ok,api.image_prepare(&handle,&request,&output));
        const copy = output;
        try t.expect(copy.flags == c.prepared_copy_pending|@as(u32,if (software) c.prepared_software else 0) and copy.job.slot != 0 and copy.dependency_count == 1);
        try t.expectEqualDeep(@as(c.R4GfxCopyFence,@bitCast(Model.status.fence)),ready[0]);
        try t.expect(Model.maps == 0 and Model.job_request.operation == a.gfx_queue_operation_copy_rows and
            Model.job_request.byte_length == 16 and Model.job_request.row_count == 4 and Model.job_request.source_pitch == 16 and
            Model.job_request.target_pitch == @as(u64,if (software) 16 else 256));
        if (!software) try t.expect(Model.native_request.layout == 0 and Model.native_request.usage == 28);
        try t.expectEqual(c.status_ok,api.resource_release(&handle,&source));
        try t.expectEqual(c.status_busy,api.job_release(&handle,&copy.job));
        try t.expect(Model.referenceCount() == 2);
        Model.complete();
        const target_resource = try device.resource(copy.image,true);
        const target_data = &Model.objects[Model.ref(target_resource.backing.reference).object.?].bytes;
        for (0..4) |y| for (target_data[y*target_resource.image.pitch..][0..16]) |value| try t.expectEqual(@as(u8,0x53),value);
        var info: c.R4GfxDeviceInfo = undefined;
        var job_info: c.R4GfxJobInfo = undefined;
        try t.expectEqual(c.status_ok,api.job_info(&handle,&copy.job,&job_info));
        try t.expectEqual(c.status_ok,api.device_info(&handle,&info));
        try t.expect(info.gpu_copy_bytes == @as(u64,if (software) 0 else 64) and info.cpu_read_bytes == @as(u64,if (software) 64 else 0) and info.cpu_write_bytes == info.cpu_read_bytes);
        // Reuse retains the image and forwards its still-owned predecessor
        // fence, even when input and output readiness arrays are identical.
        request.source = copy.image; request.flags = 0; request.byte_budget = 0;
        request.dependencies = @intFromPtr(&ready); request.dependency_count = 1;
        const prior = ready;
        const allocations = Model.native_starts;
        try t.expectEqual(c.status_ok,api.image_prepare(&handle,&request,&output));
        try t.expect(output.flags == c.prepared_reused|@as(u32,if (software) c.prepared_software else 0) and output.job.slot == 0 and output.dependency_count == 1);
        try t.expectEqualDeep(copy.image,output.image); try t.expectEqualDeep(prior,ready);
        try t.expect(target_resource.public_refs == 2 and Model.native_starts == allocations);
        // The last public references can close while the copy receipt still
        // owns both BOs; job_release performs the final physical retirement.
        try t.expectEqual(c.status_ok,api.resource_release(&handle,&copy.image));
        try t.expectEqual(c.status_ok,api.resource_release(&handle,&output.image));
        try t.expect(Model.referenceCount() == 2);
        try t.expectEqual(c.status_ok,api.job_release(&handle,&copy.job));
        try t.expect(Model.referenceCount() == 0);
        try t.expectEqual(c.status_ok,api.device_close(&handle));
    }
}

fn checkReceiptPressure(config: *const c.R4GfxDeviceConfig) !void {
    Model.reset(); Model.operations = 29; Model.retain_completed = true;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_argb8888, .layout = 0 };
    var desc = descriptor(c.resource_image);
    desc.flags = c.image_target; desc.source_kind = c.source_create_native; desc.source_address = @intFromPtr(&native);
    var source: c.R4GfxResource = undefined; var target: c.R4GfxResource = undefined; var pipeline: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &desc, &source));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &desc, &target));
    var state = descriptor(c.resource_pipeline); state.operation = c.render_operation_fill;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &state, &pipeline));
    var request = std.mem.zeroes(c.R4GfxRenderRequest);
    request.version = 1; request.size = @sizeOf(c.R4GfxRenderRequest); request.deadline_ns = 99999999;
    request.target = target; request.pipeline = pipeline; request.opacity = 255; request.color = 0xff102030;
    request.target_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }; request.scissor = request.target_rect;
    var retained: [c.device_job_capacity]c.R4GfxJob = undefined;
    for (&retained) |*job| {
        try t.expectEqual(c.status_ok, api.render_submit(&handle, &request, job));
        // Model physical retirement while the caller still owns its receipt.
        // No shader execution is simulated by this admission/lifetime test.
        Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
        Model.completed[Model.status.fence.slot - 1] = Model.status; Model.job_live = false;
    }
    var rejected = std.mem.zeroes(c.R4GfxJob); rejected.generation = 0xfeed;
    const untouched = rejected;
    const serial = Model.submit_serial;
    try t.expectEqual(c.status_busy, api.render_submit(&handle, &request, &rejected));
    const copy: c.R4GfxCopyRequest = .{ .source = source, .target = target, .source_offset = 0, .target_offset = 0, .byte_length = 64, .deadline_ns = 99999999 };
    try t.expectEqual(c.status_busy, api.copy_submit(&handle, &copy, &rejected));
    try t.expectEqualDeep(untouched, rejected); try t.expectEqual(serial, Model.submit_serial);
    for (&retained) |*job| {
        var info: c.R4GfxJobInfo = undefined;
        try t.expectEqual(c.status_ok, api.job_info(&handle, job, &info));
        try t.expect(info.phase == a.gfx_queue_phase_terminal and info.flags == 0);
    }
    try t.expectEqual(c.status_ok, api.job_release(&handle, &retained[0]));
    // Common queue capacity is transient too; OOM and BO budget errors keep
    // their existing Limit meaning. A rejected call never publishes a job.
    for ([_]i32{ a.gfx_queue_error_capacity, a.gfx_buffer_error_oom, a.gfx_buffer_error_budget }) |rc| {
        Model.submit_error = rc;
        const expected = if (rc == a.gfx_queue_error_capacity) c.status_busy else c.status_limit;
        try t.expectEqual(expected, api.render_submit(&handle, &request, &rejected));
        try t.expectEqual(expected, api.copy_submit(&handle, &copy, &rejected));
        try t.expectEqualDeep(untouched, rejected); try t.expectEqual(serial, Model.submit_serial);
    }
    Model.submit_error = 0;
    try t.expectEqual(c.status_ok, api.render_submit(&handle, &request, &rejected));
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &rejected));
    for (retained[1..]) |*job| try t.expectEqual(c.status_ok, api.job_release(&handle, job));
    for ([_]c.R4GfxResource{source, target, pipeline}) |resource| try t.expectEqual(c.status_ok, api.resource_release(&handle, &resource));
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
    std.debug.print("[R4GFX-admission] full receipt pool retries after release; common capacity Busy; OOM/budget Limit; handles and resources preserved\n", .{});
}

fn checkNativeRender(config: *const c.R4GfxDeviceConfig) !void {
    Model.reset(); Model.operations = 13;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const device = try d.get(&handle, false);
    const timeline = device.queue.timeline;
    const image_request: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_argb8888, .layout = 0 };
    var image_desc = descriptor(c.resource_image);
    image_desc.flags = c.image_target; image_desc.source_kind = c.source_create_native; image_desc.source_address = @intFromPtr(&image_request);
    var source: c.R4GfxResource = undefined; var target: c.R4GfxResource = undefined;
    var pipeline: c.R4GfxResource = undefined; var sampler: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image_desc, &target));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image_desc, &source));
    var pipeline_desc = descriptor(c.resource_pipeline); pipeline_desc.operation = c.render_operation_fill;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &pipeline_desc, &pipeline));
    var request = std.mem.zeroes(c.R4GfxRenderRequest);
    request.version = 1; request.size = @sizeOf(c.R4GfxRenderRequest); request.deadline_ns = 99999999;
    request.target = target; request.pipeline = pipeline; request.opacity = 255; request.color = 0x80402010;
    request.target_rect = .{ .x = -2, .y = 0, .width = 6, .height = 4 }; request.scissor = .{ .x = 0, .y = 1, .width = 3, .height = 2 };
    var job = std.mem.zeroes(c.R4GfxJob); job.generation = 79;
    const untouched = job;
    try t.expectEqual(c.status_unsupported, api.render_submit(&handle, &request, &job));
    try t.expectEqualDeep(untouched, job);
    var info: c.R4GfxDeviceInfo = undefined;
    Model.operations = 29;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &info));
    try t.expect(info.gpu_operations & c.device_gpu_render != 0 and device.queue.timeline == timeline);
    try t.expectEqual(c.status_ok, api.render_submit(&handle, &request, &job));
    try t.expect(Model.maps == 0 and Model.job_request.operation == a.gfx_queue_operation_render and Model.job_request.byte_length == 0);
    try t.expect(Model.job_request.source.id == 0 and Model.job_request.target.id != 0);
    try t.expectEqualDeep(@as(a.GfxRenderRect, @bitCast(request.target_rect)), Model.job_request.render.target_rect);
    const copied = Model.job_request.render;
    request.target_rect.x = 123;
    try t.expectEqualDeep(copied, Model.job_request.render);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &pipeline));
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 2);
    // A transport model receipt, not execution of NVIDIA instructions.
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 1);
    try t.expectEqual(c.status_ok, api.device_info(&handle, &info));
    try t.expect(info.gpu_copy_bytes == 0 and info.cpu_write_bytes == 0 and info.cpu_read_bytes == 0);
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image_desc, &target));
    pipeline_desc.operation = c.render_operation_over;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &pipeline_desc, &pipeline));
    var sampler_desc = descriptor(c.resource_sampler); sampler_desc.sampler = c.render_sampler_bilinear;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &sampler_desc, &sampler));
    request.target = target; request.source = source; request.pipeline = pipeline; request.sampler = sampler;
    request.target_rect.x = -2; request.source_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 };
    request.color = 0; request.opacity = 127; request.transfer = c.render_transfer_srgb_decode;
    var invalid = request; invalid.source = target;
    try t.expectEqual(c.status_alias, api.render_submit(&handle, &invalid, &job));
    var commands = [_]c.R4GfxRenderRequest{ request, request };
    commands[1].opacity = 63;
    var list: c.R4GfxRenderListRequest = .{ .version = 1, .size = @sizeOf(c.R4GfxRenderListRequest), .commands = @intFromPtr(&commands), .count = 2, .reserved = 0 };
    const previous_job = job;
    try t.expectEqual(c.status_unsupported, api.render_submit_list(&handle, &list, &job));
    try t.expectEqualDeep(previous_job, job);
    Model.operations = 93;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &info));
    commands[1].target = source;
    try t.expectEqual(c.status_invalid, api.render_submit_list(&handle, &list, &job));
    try t.expect(!Model.job_live and Model.maps == 0); try t.expectEqualDeep(previous_job, job);
    commands[1].target = target; list.count = 17;
    try t.expectEqual(c.status_invalid, api.render_submit_list(&handle, &list, &job));
    list.count = 2;
    try t.expectEqual(c.status_ok, api.render_submit_list(&handle, &list, &job));
    try t.expect(Model.job_request.operation == a.gfx_queue_operation_render_list and Model.job_list.count == 2 and Model.job_list.commands[1].opacity == 63);
    commands[1].opacity = 0;
    try t.expect(Model.job_list.commands[1].opacity == 63 and Model.maps == 0);
    try t.expect(Model.job_request.render.kind == a.gfx_render_kind_sample and Model.job_request.render.filter == 1 and
        Model.job_request.render.blend == 1 and Model.job_request.render.transfer == 1 and Model.job_request.render.opacity == 127);
    var dependency: c.R4GfxCopyFence = undefined;
    try t.expectEqual(c.status_ok, api.job_fence(&handle, &job, &dependency));
    invalid = request; invalid.dependency_count = 1; invalid.dependencies = @intFromPtr(&dependency);
    var denied: c.R4GfxJob = undefined;
    try t.expectEqual(c.status_busy, api.render_submit(&handle, &invalid, &denied));
    try t.expect(Model.dependency_seen);
    Model.operations = 13;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &info));
    try t.expect(info.gpu_operations & c.device_gpu_render == 0 and device.queue.timeline == timeline and Model.premature_closes == 0);
    try t.expectEqual(c.status_unsupported, api.render_submit(&handle, &request, &denied));
    try t.expectEqual(c.status_ok, api.job_cancel(&handle, &job));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &source));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 2 and Model.maps == 0);
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
}

fn checkNativeGrid(config: *const c.R4GfxDeviceConfig) !void {
    Model.reset(); Model.operations = 93;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_argb8888, .layout = 0 };
    var image_desc = descriptor(c.resource_image);
    image_desc.flags = c.image_target; image_desc.source_kind = c.source_create_native; image_desc.source_address = @intFromPtr(&native);
    var source: c.R4GfxResource = undefined; var target: c.R4GfxResource = undefined;
    var pipeline: c.R4GfxResource = undefined; var sampler: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image_desc, &source));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &image_desc, &target));
    var pipeline_desc = descriptor(c.resource_pipeline); pipeline_desc.operation = c.render_operation_over;
    var sampler_desc = descriptor(c.resource_sampler); sampler_desc.sampler = c.render_sampler_nearest;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &pipeline_desc, &pipeline));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &sampler_desc, &sampler));
    var command = std.mem.zeroes(c.R4GfxRenderRequest);
    command.version = 1; command.size = @sizeOf(c.R4GfxRenderRequest); command.deadline_ns = native.deadline_ns;
    command.source = source; command.target = target; command.pipeline = pipeline; command.sampler = sampler;
    command.opacity = 255; command.source_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 };
    command.target_rect = command.source_rect; command.scissor = command.source_rect;
    var commands = [_]c.R4GfxRenderRequest{ command, command };
    var grids: [2]c.R4GfxLogicalGrid = @splat(std.mem.zeroes(c.R4GfxLogicalGrid));
    grids[0].enabled = 1; grids[0].rotation = 1; grids[0].scale = 180;
    grids[0].pixel_width = 4; grids[0].pixel_height = 4;
    grids[0].viewport_width = 4; grids[0].viewport_height = 4;
    grids[0].guest_width = 4; grids[0].guest_height = 4;
    grids[1] = grids[0]; grids[1].rotation = 3;
    var list: c.R4GfxRenderGridListRequest = .{ .version = 1, .size = @sizeOf(c.R4GfxRenderGridListRequest),
        .commands = @intFromPtr(&commands), .grids = @intFromPtr(&grids), .count = 2, .reserved = 0 };
    var job = std.mem.zeroes(c.R4GfxJob); job.generation = 79;
    const untouched = job;
    try t.expectEqual(c.status_unsupported, api.render_submit_grid_list(&handle, &list, &job));
    try t.expectEqualDeep(untouched, job);
    Model.operations |= 256;
    var info: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &info));
    try t.expect(info.gpu_operations & c.device_gpu_grid != 0);
    // Invalid second draw must leave no accepted prefix or retained job.
    grids[1].scale = 0;
    try t.expectEqual(c.status_invalid, api.render_submit_grid_list(&handle, &list, &job));
    try t.expect(!Model.job_live and Model.referenceCount() == 2 and Model.maps == 0);
    try t.expectEqualDeep(untouched, job);
    grids[1].scale = 180;
    const original_grids = grids;
    try t.expectEqual(c.status_ok, api.render_submit_grid_list(&handle, &list, &job));
    try t.expect(Model.job_request.operation == a.gfx_queue_operation_render_grid_list and Model.job_grid_list.count == 2);
    try t.expectEqualDeep(@as(a.GfxSampleGrid, @bitCast(original_grids[1])), Model.job_grid_list.grids[1]);
    grids[1].rotation = 0; commands[1].opacity = 0;
    try t.expect(Model.job_grid_list.grids[1].rotation == 3 and Model.job_grid_list.commands[1].opacity == 255 and Model.maps == 0);
    // Cancellation does not retire either BO until the driver relinquishes
    // the copied work. This is transport evidence, not GPU execution.
    try t.expectEqual(c.status_ok, api.job_cancel(&handle, &job));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &source));
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &target));
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 2);
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 0 and Model.maps == 0);
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.premature_closes == 0);
}

fn checkNativeColor(config: *const c.R4GfxDeviceConfig) !void {
    try checkNativeColorMode(config, false);
    try checkNativeColorMode(config, true);
}
fn submitColorCase(combined: bool, device: *const c.R4GfxDevice, list: *const c.R4GfxRenderListRequest,
    grids: *const [2]c.R4GfxLogicalGrid, flags: u32, output: *c.R4GfxJob) i32 {
    const colors = &@import("main.zig").r4gfx_color_v1;
    if (!combined) return colors.color_render_submit(device, list, flags, output);
    return colors.color_render_submit_grid(device, &.{ .version = 1, .size = @sizeOf(c.R4GfxRenderGridListRequest),
        .count = list.count, .reserved = 0, .commands = list.commands, .grids = @intFromPtr(grids) }, flags, output);
}
fn checkNativeColorMode(config: *const c.R4GfxDeviceConfig, combined: bool) !void {
    const colors = &@import("main.zig").r4gfx_color_v1;
    Model.reset(); Model.operations = 93;
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    var native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_abgr16161616f, .layout = 0 };
    var image_desc: c.R4GfxColorResourceDesc = .{ .version = 1, .size = @sizeOf(c.R4GfxColorResourceDesc),
        .resource = descriptor(c.resource_image), .description = .{ .version = 1, .size = @sizeOf(c.R4GfxColorDescription),
            .primaries = c.color_primaries_srgb, .transfer = c.color_transfer_linear, .range = c.color_range_full,
            .alpha = c.color_alpha_optical, .precision = c.color_precision_float16, .flags = 0,
            .reference_white = 1000000, .peak = 10000000, .black = 0, .reserved = 0 } };
    image_desc.resource.flags = c.image_target; image_desc.resource.source_kind = c.source_create_native;
    image_desc.resource.source_address = @intFromPtr(&native);
    var source: c.R4GfxResource = undefined; var target: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, colors.color_resource_create(&handle, &image_desc, &source));
    native.format = c.format_xrgb2101010;
    image_desc.description.primaries = c.color_primaries_bt2020; image_desc.description.transfer = c.color_transfer_pq;
    image_desc.description.range = c.color_range_limited; image_desc.description.alpha = c.color_alpha_opaque;
    image_desc.description.precision = c.color_precision_unorm10; image_desc.description.reference_white = 2030000;
    try t.expectEqual(c.status_ok, colors.color_resource_create(&handle, &image_desc, &target));
    var pipeline_desc = descriptor(c.resource_pipeline); pipeline_desc.operation = c.render_operation_blit;
    var sampler_desc = descriptor(c.resource_sampler); sampler_desc.sampler = c.render_sampler_nearest;
    var pipeline: c.R4GfxResource = undefined; var sampler: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &pipeline_desc, &pipeline));
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &sampler_desc, &sampler));
    var command = std.mem.zeroes(c.R4GfxRenderRequest);
    command.version = 1; command.size = @sizeOf(c.R4GfxRenderRequest); command.deadline_ns = native.deadline_ns;
    command.source = source; command.target = target; command.pipeline = pipeline; command.sampler = sampler; command.opacity = 255;
    command.source_rect = .{ .x = 0, .y = 0, .width = 4, .height = 4 }; command.target_rect = command.source_rect; command.scissor = command.source_rect;
    var commands = [_]c.R4GfxRenderRequest{command,command}; commands[1].opacity = 127;
    var grids: [2]c.R4GfxLogicalGrid = @splat(std.mem.zeroes(c.R4GfxLogicalGrid));
    grids[1] = .{ .enabled = 1, .rotation = 3, .scale = 120, .reserved = 0,
        .pixel_width = 4, .pixel_height = 4, .target_x = 0, .target_y = 0, .viewport_x = 0, .viewport_y = 0,
        .viewport_width = 4, .viewport_height = 4, .guest_width = 4, .guest_height = 4, .source_x = 0, .source_y = 0 };
    const list: c.R4GfxRenderListRequest = .{ .version = 1, .size = @sizeOf(c.R4GfxRenderListRequest), .commands = @intFromPtr(&commands), .count = 2, .reserved = 0 };
    const flags = c.color_transform_output | c.color_transform_relative_white | c.color_transform_dither;
    var job = std.mem.zeroes(c.R4GfxJob); job.generation = 79; const untouched = job;
    try t.expectEqual(c.status_unsupported, submitColorCase(combined, &handle, &list, &grids, flags, &job));
    try t.expectEqualDeep(untouched,job);
    Model.operations |= 512 | 256;
    var info: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok,api.device_refresh(&handle,&info));
    try t.expect(info.gpu_operations & c.device_gpu_color != 0);
    if (combined) {
        try t.expectEqual(c.status_unsupported, submitColorCase(true, &handle, &list, &grids, flags, &job));
        try t.expectEqualDeep(untouched, job);
        Model.operations |= @as(u64, 1) << a.gfx_queue_operation_render_color_grid_list;
        try t.expectEqual(c.status_ok, api.device_refresh(&handle, &info));
        try t.expect(info.gpu_operations & c.device_gpu_color_grid != 0);
        grids[1].scale = 0;
        try t.expectEqual(c.status_invalid, submitColorCase(true, &handle, &list, &grids, flags, &job));
        try t.expect(!Model.job_live and Model.maps == 0);
        try t.expectEqualDeep(untouched, job);
        grids[1].scale = 120;
    }
    commands[1].transfer = c.render_transfer_srgb_encode;
    try t.expectEqual(c.status_invalid,submitColorCase(combined,&handle,&list,&grids,flags,&job));
    try t.expect(!Model.job_live and Model.maps == 0); try t.expectEqualDeep(untouched,job);
    commands[1].transfer = c.render_transfer_identity;
    try t.expectEqual(c.status_ok,submitColorCase(combined,&handle,&list,&grids,flags,&job));
    if (combined) {
        try t.expectEqualDeep(@as(a.GfxSampleGrid, @bitCast(grids[1])), Model.job_grid_list.grids[1]);
        grids[1].rotation = 0;
        try t.expect(Model.job_grid_list.grids[1].rotation == 3 and Model.maps == 0);
    }
    const copied = Model.job_color_list;
    // Identical XR30 storage is insufficient: PQ/HLG, primaries, range and
    // luminance must match the actual output before any present submission.
    const device = try d.get(&handle, false);
    const draw = @constCast(device.caller.legacy.bundle.draw.?);
    draw.gfx_output_color = @intFromPtr(&Model.outputColor);
    defer draw.gfx_output_color = 0;
    const output_target: a.GfxOutputTarget = .{ .adapter_id = Model.binding.adapter_id, .connector_id = 4,
        .device_generation = Model.binding.device_generation, .connection_generation = 9, .display_generation = 1, .head_id = 2 };
    Model.output_color = .{ .identity = .{ .adapter_id = output_target.adapter_id, .connector_id = 4,
        .device_generation = output_target.device_generation, .connection_generation = 9 }, .flags = 7, .revision = 1,
        .format = c.format_xrgb2101010, .bpc = 10, .primaries = 3, .transfer = 3, .range = 2, .reference_white = 2030000, .peak = 10000000 };
    const retained_image = try device.resource(target, true);
    const output_color = @import("device_output_color.zig");
    try output_color.validate(device, retained_image, output_target);
    Model.output_color.transfer = 4;
    try t.expectError(error.Unsupported, output_color.validate(device, retained_image, output_target));
    Model.output_color.transfer = 3; Model.output_color.range = 1;
    try t.expectError(error.Unsupported, output_color.validate(device, retained_image, output_target));
    Model.output_color.range = 2; Model.output_color.identity.connection_generation += 1;
    try t.expectError(error.Stale, output_color.validate(device, retained_image, output_target));
    try t.expect(copied.count == 2 and copied.commands[1].opacity == 127 and copied.commands[0].transfer == a.gfx_render_transfer_color);
    try t.expectEqualSlices(u32,&.{3,2,3,4,1},copied.program.words[0..5]);
    try t.expectApproxEqAbs(@as(f32,2.03),@as(f32,@bitCast(copied.program.words[44])),0.000001);
    try t.expectApproxEqAbs(@as(f32,64.0/1023.0),@as(f32,@bitCast(copied.program.words[43])),0.000001);
    commands[1].opacity = 0;
    try t.expectEqualDeep(copied,Model.job_color_list);
    try t.expectEqual(c.status_ok,api.job_cancel(&handle,&job));
    try t.expectEqual(c.status_ok,api.resource_release(&handle,&source));
    try t.expectEqual(c.status_ok,api.resource_release(&handle,&target));
    try t.expectEqual(c.status_busy,api.job_release(&handle,&job));
    try t.expect(Model.referenceCount() == 2 and Model.maps == 0);
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok,api.job_release(&handle,&job));
    try t.expectEqual(c.status_ok,api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
}

const AmdFixture = struct {
    table: amd.BackendV1 = .{ .header = amd.backend_v1_header, .negotiate = ProviderProbe.amdgpu,
        .encode_copy = @ptrCast(&amd_provider.encodeCopy), .encode_fill = @ptrCast(&amd_provider.encodeFill),
        .encode_pm4_frame = @ptrCast(&amd_provider.encodePm4Frame), .media_caps = @ptrCast(&amd_provider.mediaCaps) },
    images: amd.ImageV1 = .{ .header = amd.image_v1_header, .calculate = @ptrCast(&amd_images.calculate),
        .address = @ptrCast(&amd_images.address), .metadata = @ptrCast(&amd_images.metadata),
        .import_image = @ptrCast(&amd_images.importImage), .descriptors = @ptrCast(&amd_images.descriptors) },
    backend: [1]a.GfxBackendInfo = undefined,
    fn bind(self: *AmdFixture, imports: *[6]a.R4XStartImport, operations: u64) void {
        Model.binding.adapter_id = 3;
        self.backend[0] = .{ .binding = Model.binding, .operations = operations, .memory_generation = 97,
            .profile = .{ .interface_id_lo = amd.backend_v1_header.interface_id_lo,
                .interface_id_hi = amd.backend_v1_header.interface_id_hi, .revision = 1,
                .data_bytes = @sizeOf(amd.R4AmdDriverProfile) } };
        const profile: amd.R4AmdDriverProfile = .{ .version = 1, .size = @sizeOf(amd.R4AmdDriverProfile),
            .vendor_id = amd.vendor_id, .device_id = 0x15d8, .gc_version = if (Model.raven2) amd.gc_9_2_2 else amd.gc_9_1_0,
            .sdma_version = if (Model.raven2) amd.sdma_4_1_1 else amd.sdma_4_1_0, .command_abi = amd.command_abi, .reserved = 0 };
        @memcpy(self.backend[0].profile.data[0..@sizeOf(amd.R4AmdDriverProfile)], std.mem.asBytes(&profile));
        Model.adapters = &self.backend;
        imports[4].table = @intFromPtr(&self.table); imports[4].resolved_version = amd.backend_v1_revision;
        imports[5].table = @intFromPtr(&self.images); imports[5].resolved_version = amd.image_v1_revision;
    }
    fn close(_: *AmdFixture, imports: *[6]a.R4XStartImport) void {
        Model.adapters = null;
        imports[4].table = 0; imports[4].resolved_version = 0;
        imports[5].table = 0; imports[5].resolved_version = 0;
    }
};

fn checkNativePresent(config: *const c.R4GfxDeviceConfig, imports: *[6]a.R4XStartImport, use_amd: bool) !void {
    Model.reset(); Model.operations = 29;
    var amd_fixture: AmdFixture = .{};
    if (use_amd) amd_fixture.bind(imports, Model.operations);
    defer if (use_amd) amd_fixture.close(imports);
    var handle: c.R4GfxDevice = undefined;
    try t.expectEqual(c.status_ok, api.device_open(config, &handle));
    const device = try d.get(&handle, false);
    const timeline = device.queue.timeline;
    const native: c.R4GfxNativeImage = .{ .version = 1, .size = 32, .deadline_ns = 99999999,
        .width = 4, .height = 4, .format = c.format_xrgb8888, .layout = if (use_amd) 0 else 1 };
    var desc = descriptor(c.resource_image);
    desc.flags = c.image_target; desc.source_kind = c.source_create_native; desc.source_address = @intFromPtr(&native);
    var image: c.R4GfxResource = undefined;
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &desc, &image));
    var request: c.R4GfxImagePresentRequest = .{ .version = 1, .size = 72, .source = image, .deadline_ns = 99999999,
        .frame_key = 7, .dependency_count = 0, .reserved = 0, .dependencies = 0 };
    var job = std.mem.zeroes(c.R4GfxJob); job.generation = 79;
    const original = job;
    try t.expectEqual(c.status_unsupported, api.image_present(&handle, &request, &job));
    try t.expectEqualDeep(original, job);
    Model.operations = 61;
    if (use_amd) amd_fixture.backend[0].operations = Model.operations;
    var info: c.R4GfxDeviceInfo = undefined;
    try t.expectEqual(c.status_ok, api.device_refresh(&handle, &info));
    try t.expect(info.gpu_operations & c.device_gpu_present != 0 and device.queue.timeline == timeline);
    request.reserved = 1;
    try t.expectEqual(c.status_invalid, api.image_present(&handle, &request, &job));
    try t.expectEqualDeep(original, job);
    request.reserved = 0;
    try t.expectEqual(c.status_ok, api.image_present(&handle, &request, &job));
    try t.expect(Model.maps == 0 and Model.job_request.operation == a.gfx_queue_operation_present and
        Model.job_request.target.id == 0 and Model.job_request.source_offset == 0 and Model.job_request.target_offset == 0 and
        Model.job_request.byte_length == 16 and Model.job_request.row_count == 4 and
        Model.job_request.source_pitch == @as(u64, if (use_amd) 256 else 64) and Model.job_request.target_pitch == 0);
    request.frame_key = 8;
    try t.expect(Model.job_request.frame_key == 7);
    var dependency: c.R4GfxCopyFence = undefined;
    try t.expectEqual(c.status_ok, api.job_fence(&handle, &job, &dependency));
    request.dependency_count = 1; request.dependencies = @intFromPtr(&dependency);
    var denied = original;
    try t.expectEqual(c.status_busy, api.image_present(&handle, &request, &denied));
    try t.expectEqualDeep(original, denied);
    try t.expect(Model.dependency_seen);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &image));
    try t.expectEqual(c.status_ok, api.job_cancel(&handle, &job));
    try t.expectEqual(c.status_busy, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 1 and Model.maps == 0);
    Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expect(Model.referenceCount() == 0);
    try t.expectEqual(c.status_ok, api.resource_create(&handle, &desc, &image));
    request.source = image; request.dependency_count = 0; request.dependencies = 0;
    try t.expectEqual(c.status_ok, api.image_present(&handle, &request, &job));
    // Transport receipt only. The driver model tests CE and visible flip.
    Model.status.phase = a.gfx_queue_phase_terminal; Model.status.result = a.gfx_queue_result_complete; Model.status.flags = 0;
    try t.expectEqual(c.status_ok, api.job_release(&handle, &job));
    try t.expectEqual(c.status_ok, api.device_info(&handle, &info));
    try t.expect(info.gpu_copy_bytes == 64 and info.cpu_read_bytes == 0 and info.cpu_write_bytes == 0);
    try t.expectEqual(c.status_ok, api.resource_release(&handle, &image));
    try t.expectEqual(c.status_ok, api.device_close(&handle));
    try t.expect(Model.referenceCount() == 0 and Model.premature_closes == 0);
}
