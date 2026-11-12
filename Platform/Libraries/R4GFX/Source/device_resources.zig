const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const d = @import("device.zig");
const c = d.c;
const empty_image = std.mem.zeroes(c.R4GfxCpuImage);

pub fn pixelBytes(format: u32) d.Error!u64 {
    return switch (format) { c.format_xrgb8888, c.format_argb8888, c.format_xrgb2101010, c.format_argb2101010 => 4,
        c.format_abgr16161616f => 8, c.format_r8 => 1, else => error.Unsupported };
}
fn validateColor(format: u32, description: ?c.R4GfxColorDescription) d.Error!void {
    if (description) |value| {
        const desc = try @import("color_api.zig").description(&value);
        if (desc.transfer == .icc) return error.Unsupported;
        const pixels = @import("color_pixels.zig");
        const storage = std.enums.fromInt(pixels.Format, format) orelse return error.Unsupported;
        storage.validate(desc) catch |err| return if (err == error.Invalid) error.Invalid else error.Unsupported;
    } else if (format != c.format_xrgb8888 and format != c.format_argb8888 and format != c.format_r8) return error.Unsupported;
}

pub fn validateImage(image: c.R4GfxCpuImage, borrowed: bool) d.Error!void {
    if (image.width == 0 or image.height == 0 or image.reserved != 0) return error.Invalid;
    const bytes = try pixelBytes(image.format);
    if (image.pitch < @as(u64, image.width) * bytes) return error.Invalid;
    const length = std.math.mul(u64, image.pitch, image.height) catch return error.Overflow;
    if (length > image.byte_length or (borrowed and image.cpu_address == 0) or (!borrowed and image.cpu_address != 0)) return error.Invalid;
    _ = std.math.add(u64, image.cpu_address, image.byte_length) catch return error.Overflow;
}
pub fn validateDescriptor(device: *d.Device, descriptor: a.GfxBufferDescriptor) d.Error!?@import("amd_images.zig").Result {
    if (descriptor.location == a.gfx_buffer_location_device_local and device.backend() == c.render_backend_amd)
        return try @import("amd_images.zig").query(device,descriptor);
    if (descriptor.modifier != 0 and (device.backend() != c.render_backend_nvidia or
        descriptor.modifier & ~@as(u64,15) != @import("native_resource.zig").modifier_base or descriptor.modifier & 15 > 5)) return error.Unsupported;
    return null;
}
pub fn descriptorImage(descriptor: a.GfxBufferDescriptor) d.Error!c.R4GfxCpuImage {
    if (descriptor.version != 1 or descriptor.size < @sizeOf(a.GfxBufferDescriptor) or
        (descriptor.modifier != 0 and descriptor.location != a.gfx_buffer_location_device_local) or
        descriptor.plane_count != 1 or descriptor.plane_offsets[0] != 0 or descriptor.reserved0 != 0) return error.Unsupported;
    for (1..4) |i| if (descriptor.plane_offsets[i] != 0 or descriptor.plane_pitches[i] != 0) return error.Unsupported;
    const image: c.R4GfxCpuImage = .{ .cpu_address = 0, .byte_length = descriptor.byte_length, .pitch = descriptor.plane_pitches[0],
        .width = descriptor.width, .height = descriptor.height, .format = descriptor.format, .reserved = 0 };
    try validateImage(image, false);
    return image;
}
pub fn create(device: *d.Device, input: *const c.R4GfxResourceDesc, output: *c.R4GfxResource) d.Error!i32 {
    _ = try d.pointer(c.R4GfxResourceDesc, @intFromPtr(input));
    return createWithUsage(device,input,output,if (input.source_kind == c.source_create_native_scanout) 60 else 28);
}
/// Internal image preparation can request a separate scanout allocation.
/// The existing public native-image request retains its offscreen usage28.
pub fn createWithUsage(device: *d.Device, input: *const c.R4GfxResourceDesc, output: *c.R4GfxResource, native_usage: u32) d.Error!i32 {
    return createColoredWithUsage(device, input, output, native_usage, null);
}
pub fn createColoredWithUsage(device: *d.Device, input: *const c.R4GfxResourceDesc, output: *c.R4GfxResource, native_usage: u32, color: ?c.R4GfxColorDescription) d.Error!i32 {
    if (native_usage != 28 and native_usage != 60) return error.Invalid;
    _ = try d.pointer(c.R4GfxResourceDesc, @intFromPtr(input));
    try d.outputSafe(c.R4GfxResource, output, device);
    if (d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxResourceDesc), @intFromPtr(output), @sizeOf(c.R4GfxResource))) return error.Alias;
    const request = input.*;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxResourceDesc) or request.reserved != 0) return error.Invalid;
    if (color != null and request.kind != c.resource_image) return error.Invalid;
    var candidate = d.Resource{ .kind = request.kind, .flags = request.flags, .source_kind = request.source_kind,
        .source_generation = request.source_generation, .image = request.image, .color = color, .sampler = request.sampler, .operation = request.operation };
    var raster: a.GuiSharedRasterLease = .{};
    var reference: a.GfxBufferHandle = .{};
    var native: c.R4GfxNativeImage = undefined;
    switch (request.kind) {
        c.resource_sampler, c.resource_pipeline => {
            if (request.flags != 0 or request.source_kind != 0 or request.source_address != 0 or request.source_generation != 0 or !std.meta.eql(request.image, empty_image)) return error.Invalid;
            if (request.kind == c.resource_sampler) {
                if (request.operation != 0) return error.Invalid;
                if (request.sampler != c.render_sampler_nearest and request.sampler != c.render_sampler_bilinear) return error.Unsupported;
            } else {
                if (request.sampler != 0) return error.Invalid;
                if (request.operation != c.render_operation_fill and request.operation != c.render_operation_blit and request.operation != c.render_operation_over) return error.Unsupported;
            }
        },
        c.resource_image => {
            if (request.flags & ~c.image_target != 0 or request.operation != 0 or request.sampler != 0) return error.Invalid;
            switch (request.source_kind) {
                c.source_create_native, c.source_create_native_scanout => {
                    if (request.source_generation != 0 or !std.meta.eql(request.image, empty_image)) return error.Invalid;
                    native = (try d.pointer(c.R4GfxNativeImage, request.source_address)).*;
                    if (native.version != 1 or native.size != @sizeOf(c.R4GfxNativeImage) or native.deadline_ns == 0 or
                        native.deadline_ns == std.math.maxInt(u64) or native.width == 0 or native.height == 0) return error.Invalid;
                    if (native.layout > 1) return error.Unsupported;
                    candidate.native_layout = native.layout;
                    try validateColor(native.format, color);
                    if (device.selected.binding.adapter_id == 0) return error.Unsupported;
                    if (request.source_kind == c.source_create_native_scanout and
                        ((native.format != c.format_xrgb8888 and native.format != c.format_xrgb2101010) or native.layout != 0 or device.gpu_operations & c.device_gpu_direct == 0)) return error.Unsupported;
                },
                c.source_create_system, c.source_borrow_cpu => {
                    if (request.source_address != 0) return error.Invalid;
                    const borrowed = request.source_kind == c.source_borrow_cpu;
                    try validateImage(request.image, borrowed);
                    try validateColor(request.image.format, color);
                    if (borrowed) {
                        if (request.source_generation == 0) return error.Invalid;
                        if (d.overlaps(request.image.cpu_address, request.image.byte_length, @intFromPtr(device), @sizeOf(d.Device))) return error.Alias;
                    } else if (request.source_generation != 0) return error.Invalid;
                },
                c.source_import_buffer => {
                    if (!std.meta.eql(request.image, empty_image)) return error.Invalid;
                    reference = (try d.pointer(a.GfxBufferHandle, request.source_address)).*;
                    if (reference.id == 0 or reference.generation == 0 or reference.reserved0 != 0) return error.Invalid;
                    candidate.source_key = .{ .id = reference.id, .generation = reference.generation };
                },
                c.source_color_view => {
                    if (color == null or request.flags != 0 or request.source_generation != 0 or !std.meta.eql(request.image, empty_image)) return error.Invalid;
                    const origin = (try d.pointer(c.R4GfxResource, request.source_address)).*;
                    const source = try device.resource(origin, true);
                    if (source.invalidated) return error.Stale;
                    if (source.kind != c.resource_image or source.backing.reference.id == 0) return error.Unsupported;
                    if (source.color) |description| if (!std.meta.eql(description, color.?)) return error.Unsupported;
                    reference = source.backing.reference;
                    candidate.source_key = .{ .id = source.backing.buffer.id, .generation = source.backing.buffer.generation };
                },
                c.source_shared_raster => {
                    if (request.flags != 0 or !std.meta.eql(request.image, empty_image) or request.source_generation != 0) return error.Invalid;
                    raster = (try d.pointer(a.GuiSharedRasterLease, request.source_address)).*;
                    if (raster.version != 1 or raster.size < @sizeOf(a.GuiSharedRasterLease) or raster.reserved0 != 0 or
                        raster.handle.id == 0 or raster.handle.generation == 0 or raster.raster_generation == 0 or raster.lease_token == 0) return error.Invalid;
                    candidate.source_key = .{ .id = raster.handle.id, .generation = raster.handle.generation };
                    candidate.source_generation = raster.raster_generation;
                },
                else => return error.Unsupported,
            }
        },
        else => return error.Unsupported,
    }
    // Only live logical resources can be reused; a released reference cannot
    // be resurrected by a job still retaining its old backing.
    for (&device.resources, 0..) |*item, index| {
        if (item.public_refs == 0 or item.kind != candidate.kind or item.flags != candidate.flags or item.source_kind != candidate.source_kind or
            item.source_generation != candidate.source_generation or !std.meta.eql(item.source_key, candidate.source_key) or
            item.sampler != candidate.sampler or item.operation != candidate.operation or !std.meta.eql(item.color, candidate.color)) continue;
        if (candidate.kind == c.resource_image) {
            if (candidate.source_kind == c.source_create_system or candidate.source_kind == c.source_create_native or candidate.source_kind == c.source_create_native_scanout) continue;
            if (candidate.source_kind == c.source_borrow_cpu and !std.meta.eql(item.image, candidate.image)) continue;
            if (candidate.source_kind == c.source_import_buffer or candidate.source_kind == c.source_color_view) continue; // Mutable BO imports have no immutable generation guarantee.
        }
        item.public_refs = std.math.add(u32, item.public_refs, 1) catch return error.Limit;
        output.* = device.resourceHandle(index);
        return c.status_ok;
    }
    _ = device.cleanResources();
    const serial = std.math.add(u64, device.resource_serial, 1) catch return error.Limit;
    const index = for (&device.resources, 0..) |*item, i| { if (item.serial == 0) break i; } else return error.Limit;
    const item = &device.resources[index];
    item.* = candidate;
    item.serial = serial;
    device.resource_serial = serial;
    errdefer _ = device.cleanResource(item); // A failed release stays in this slot, never disappears.
    if (request.kind == c.resource_image and request.source_kind != c.source_borrow_cpu) {
        const memory = device.buffers();
        switch (request.source_kind) {
            c.source_create_native, c.source_create_native_scanout => {
                var status: a.GfxNativeStatus = .{};
                const allocation: a.GfxNativeAllocation = .{ .adapter_id = device.selected.binding.adapter_id,
                    .memory_generation = device.selected.memory_generation, .deadline_ns = native.deadline_ns, .kind = 1,
                    .width = native.width, .height = native.height, .format = native.format, .layout = native.layout,
                    .usage = native_usage };
                try d.platform(memory.nativeStart(&allocation, &status));
                item.allocation_request = status.request;
                try d.platform(memory.nativeWait(&item.allocation_request, std.math.maxInt(u64), &status));
                if (status.result == a.gfx_buffer_error_budget or status.result == a.gfx_buffer_error_oom) {
                    // Start at most one idle image readback. Admission still
                    // retries against the real retained driver charge later.
                    @import("device_residency.zig").trim(device, native.deadline_ns) catch |err| {
                        if (err == error.Busy) return error.Busy;
                        try d.platform(status.result);
                        unreachable;
                    };
                    return error.Busy;
                }
                try d.platform(status.result);
                try d.platform(memory.nativeReceive(&item.allocation_request, &item.backing));
                item.allocation_request = .{};
            },
            c.source_create_system => {
                const image = request.image;
                var descriptor: a.GfxBufferDescriptor = .{ .byte_length = image.byte_length, .width = image.width, .height = image.height,
                    .format = image.format, .plane_count = 1, .plane_pitches = .{ image.pitch, 0, 0, 0 },
                    .usage = a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write | a.gfx_buffer_usage_transfer_source | a.gfx_buffer_usage_transfer_target | a.gfx_buffer_usage_render };
                try d.platform(memory.create(&descriptor, &item.backing));
            },
            c.source_import_buffer, c.source_color_view => try d.platform(memory.import(&reference, &item.backing)),
            c.source_shared_raster => try d.platform(memory.exportRaster(&raster, &item.backing)),
            else => unreachable,
        }
        if (item.backing.reference.id == 0 or item.backing.reference.generation == 0 or item.backing.buffer.id == 0 or item.backing.buffer.generation == 0 or
            item.backing.flags & ~a.gfx_buffer_reference_immutable != 0 or (item.flags & c.image_target != 0 and item.backing.flags & a.gfx_buffer_reference_immutable != 0)) return error.Unsupported;
        try d.platform(memory.describe(&item.backing.reference, &item.descriptor));
        if (item.descriptor.location == a.gfx_buffer_location_device_local and
            (item.descriptor.adapter_id != device.selected.binding.adapter_id or item.descriptor.device_generation != device.selected.memory_generation)) return error.Stale;
        item.amd_image = try validateDescriptor(device,item.descriptor);
        item.image = try descriptorImage(item.descriptor);
        try validateColor(item.image.format, color);
        if (request.source_kind == c.source_create_native_scanout and (item.descriptor.usage != 60 or item.descriptor.modifier != 0 or
            (item.descriptor.format != c.format_xrgb8888 and item.descriptor.format != c.format_xrgb2101010) or
            item.descriptor.location != a.gfx_buffer_location_device_local)) return error.Unsupported;
        if (request.source_kind != c.source_create_system and request.source_kind != c.source_create_native and request.source_kind != c.source_create_native_scanout) {
            device.counters.imports +|= 1;
            device.counters.imported_bytes +|= item.image.byte_length;
        }
    }
    item.public_refs = 1;
    output.* = device.resourceHandle(index);
    return c.status_ok;
}
