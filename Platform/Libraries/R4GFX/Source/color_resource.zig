//! Named image color metadata shares the existing resource/BO owner. ICC
//! decoding precedes upload; no caller profile pointer is retained by a GPU.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;
const resources = @import("device_resources.zig");
const api = @import("color_api.zig");
pub fn create(handle: *const c.R4GfxDevice, input: *const c.R4GfxColorResourceDesc, output: *c.R4GfxResource) callconv(.c) i32 {
    createImage(handle, input, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn createImage(handle: *const c.R4GfxDevice, input: *const c.R4GfxColorResourceDesc, output: *c.R4GfxResource) d.Error!void {
    const device = try d.get(handle, false);
    _ = try d.pointer(c.R4GfxColorResourceDesc, @intFromPtr(input));
    try d.outputSafe(c.R4GfxResource, output, device);
    if (input.version != 1 or input.size != @sizeOf(c.R4GfxColorResourceDesc)) return error.Invalid;
    if (d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxColorResourceDesc), @intFromPtr(device), @sizeOf(d.Device)) or
        d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxColorResourceDesc), @intFromPtr(output), @sizeOf(c.R4GfxResource)) or
        d.overlaps(@intFromPtr(handle), @sizeOf(c.R4GfxDevice), @intFromPtr(output), @sizeOf(c.R4GfxResource))) return error.Alias;
    _ = try api.description(&input.description);
    _ = try resources.createColoredWithUsage(device, &input.resource, output,
        if (input.resource.source_kind == c.source_create_native_scanout) 60 else 28, input.description);
}
pub fn info(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource, output: *c.R4GfxColorDescription) callconv(.c) i32 {
    readInfo(handle, resource, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn readInfo(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource, output: *c.R4GfxColorDescription) d.Error!void {
    const device = try d.get(handle, false);
    _ = try d.pointer(c.R4GfxResource, @intFromPtr(resource));
    try d.outputSafe(c.R4GfxColorDescription, output, device);
    if (d.overlaps(@intFromPtr(handle), @sizeOf(c.R4GfxDevice), @intFromPtr(output), @sizeOf(c.R4GfxColorDescription)) or
        d.overlaps(@intFromPtr(resource), @sizeOf(c.R4GfxResource), @intFromPtr(output), @sizeOf(c.R4GfxColorDescription))) return error.Alias;
    const item = try device.resource(resource.*, true);
    if (item.invalidated) return error.Stale;
    const description = item.color orelse return error.Unsupported;
    if (d.overlaps(item.image.cpu_address, item.image.byte_length, @intFromPtr(output), @sizeOf(c.R4GfxColorDescription))) return error.Alias;
    output.* = description;
}
pub fn transform(handle: *const c.R4GfxDevice, source: *const c.R4GfxResource, target: *const c.R4GfxResource,
    request: *const c.R4GfxColorTransform, output: *c.R4GfxCpuStats) callconv(.c) i32 {
    transformImages(handle, source, target, request, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn transformImages(handle: *const c.R4GfxDevice, source: *const c.R4GfxResource, target: *const c.R4GfxResource,
    request: *const c.R4GfxColorTransform, output: *c.R4GfxCpuStats) d.Error!void {
    const device = try d.get(handle, false);
    try d.outputSafe(c.R4GfxCpuStats, output, device);
    const inputs = .{ handle, source, target, request };
    inline for (inputs) |input| {
        const T = @typeInfo(@TypeOf(input)).pointer.child;
        _ = try d.pointer(T, @intFromPtr(input));
        if (d.overlaps(@intFromPtr(input), @sizeOf(T), @intFromPtr(device), @sizeOf(d.Device)) or
            d.overlaps(@intFromPtr(input), @sizeOf(T), @intFromPtr(output), @sizeOf(c.R4GfxCpuStats))) return error.Alias;
    }
    const from = try device.resource(source.*, true);
    const to = try device.resource(target.*, true);
    if (from == to or (from.backing.buffer.id != 0 and std.meta.eql(from.backing.buffer, to.backing.buffer))) return error.Alias;
    for ([_]*d.Resource{ from, to }, 0..) |item, i| {
        if (item.invalidated) return error.Stale;
        if (item.kind != c.resource_image or (i == 1 and item.flags & c.image_target == 0)) return error.Invalid;
        if (item.color == null or item.descriptor.location == a.gfx_buffer_location_device_local or item.descriptor.modifier != 0) return error.Unsupported;
        if (item.job_refs != 0) return error.Busy;
    }
    if (!device.cleanResources()) return error.Busy;
    defer _ = device.cleanResources();
    var images: [2]c.R4GfxColorImage = undefined;
    for ([_]*d.Resource{ from, to }, 0..) |item, i| {
        var image = item.image;
        if (item.backing.reference.id != 0) {
            try d.platform(device.buffers().map(&item.backing.reference, if (i == 1) a.gfx_buffer_map_write else a.gfx_buffer_map_read,
                0, image.byte_length, &item.map));
            if (item.map.lease.id == 0 or item.map.lease.generation == 0 or item.map.cpu_address == 0 or item.map.byte_length < image.byte_length) return error.Invalid;
            image.cpu_address = item.map.cpu_address;
        }
        if (d.overlaps(image.cpu_address, image.byte_length, @intFromPtr(device), @sizeOf(d.Device)) or
            d.overlaps(image.cpu_address, image.byte_length, @intFromPtr(output), @sizeOf(c.R4GfxCpuStats))) return error.Alias;
        if (i == 1) inline for (inputs) |input| {
            if (d.overlaps(image.cpu_address, image.byte_length, @intFromPtr(input), @sizeOf(@typeInfo(@TypeOf(input)).pointer.child))) return error.Alias;
        };
        images[i] = .{ .version = 1, .size = @sizeOf(c.R4GfxColorImage), .image = image, .description = item.color.?, .profile = .{ .address = 0, .generation = 0 } };
    }
    var stats: c.R4GfxCpuStats = undefined;
    const result = api.imageTransform(&images[0], &images[1], request, &stats);
    if (result != c.status_ok) return switch (result) {
        c.status_unsupported => error.Unsupported, c.status_alias => error.Alias,
        c.status_limit => error.Limit, c.status_overflow => error.Overflow, else => error.Invalid,
    };
    device.counters.cpu_read_bytes +|= stats.read_bytes;
    device.counters.cpu_write_bytes +|= stats.write_bytes;
    if (!device.cleanResources()) return error.Busy;
    output.* = stats;
}

// Existing native transfer shaders remain useful for a named SDR linear
// pipeline. Refuse combinations which need a matrix, LUT, tone mapper or
// encoded-domain alpha blend until the corresponding shader is selected.
pub fn nativeTransition(source: ?*const d.Resource, target: *const d.Resource, transfer: u32, operation: u32, solid: u32) d.Error!void {
    if (target.color == null and (source == null or source.?.color == null)) return;
    const to = try api.description(&(target.color orelse return error.Unsupported));
    if (source == null) {
        if (solid != 0 or transfer != c.render_transfer_identity) return error.Unsupported;
        return;
    }
    const from = try api.description(&(source.?.color orelse return error.Unsupported));
    if (from.range != .full or to.range != .full or from.primaries != to.primaries or
        from.reference_white != to.reference_white or from.black != to.black or
        (operation == c.render_operation_over and to.transfer != .linear)) return error.Unsupported;
    switch (transfer) {
        c.render_transfer_identity => {
            if (from.transfer != to.transfer or from.peak > to.peak or
                (from.alpha != to.alpha and from.alpha != .ignore) or
                (from.alpha != .ignore and from.alpha != .optical and from.alpha != .electrical)) return error.Unsupported;
        },
        c.render_transfer_srgb_decode => {
            if (from.transfer != .srgb or to.transfer != .linear or from.peak > to.peak or
                (from.alpha != .ignore and from.alpha != .electrical) or
                (to.alpha != .ignore and to.alpha != .optical)) return error.Unsupported;
        },
        c.render_transfer_srgb_encode => {
            if (from.transfer != .linear or to.transfer != .srgb or from.peak > to.peak or
                (from.alpha != .ignore and from.alpha != .optical) or
                (to.alpha != .ignore and to.alpha != .electrical)) return error.Unsupported;
        },
        else => return error.Unsupported,
    }
}
