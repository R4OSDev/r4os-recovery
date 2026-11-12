//! Resolves one complete resource batch into the shared software renderer.
//! Each distinct BO is mapped once; no image upload, raster conversion or
//! per-draw service call is part of this fallback.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;
const cpu = @import("cpu_render.zig");
const empty_resource = std.mem.zeroes(c.R4GfxResource);
const empty_rect = std.mem.zeroes(c.R4GfxRect);

fn imageIndex(device: *d.Device, handle: c.R4GfxResource, count: *u32, write: bool) d.Error!u32 {
    const item = try device.resource(handle, true);
    if (item.invalidated) return error.Stale;
    // The legacy integer renderer operates on encoded8-bit channels. Named
    // images use COLOR_V1, which blends and interpolates in linear light.
    if (item.color != null) return error.Unsupported;
    if (item.kind != c.resource_image or (write and item.flags & c.image_target == 0)) return error.Invalid;
    for (device.image_slots[0..count.*], 0..) |slot, i| {
        const prior = &device.resources[slot];
        const same_buffer = item.backing.buffer.id != 0 and std.meta.eql(prior.backing.buffer, item.backing.buffer);
        if (slot != handle.slot - 1 and !same_buffer) continue;
        if (!std.meta.eql(item.image, prior.image)) return error.Alias;
        if (write) {
            // A source-only alias cannot authorize a writable map. Use the
            // reference which actually passed the target admission above.
            device.image_slots[i] = handle.slot - 1;
            device.image_writes[i] = true;
        }
        return @intCast(i);
    }
    if (count.* == device.images.len) return error.Limit;
    const index = count.*;
    device.image_slots[index] = handle.slot - 1;
    device.image_writes[index] = write;
    count.* += 1;
    return index;
}
pub fn execute(device: *d.Device, batch: *const c.R4GfxRenderBatch, output: *c.R4GfxRenderStats) d.Error!i32 {
    _ = try d.pointer(c.R4GfxRenderBatch, @intFromPtr(batch));
    try d.outputSafe(c.R4GfxRenderStats, output, device);
    if (batch.flags != 0 or batch.command_count > c.render_max_commands or batch.pixel_budget > c.render_max_pixels) return error.Limit;
    const bytes = @as(u64, batch.command_count) * @sizeOf(c.R4GfxDraw);
    if (d.overlaps(@intFromPtr(batch), @sizeOf(c.R4GfxRenderBatch), @intFromPtr(device), @sizeOf(d.Device)) or
        d.overlaps(batch.commands, bytes, @intFromPtr(device), @sizeOf(d.Device)) or
        d.overlaps(batch.commands, bytes, @intFromPtr(output), @sizeOf(c.R4GfxRenderStats)) or
        d.overlaps(@intFromPtr(batch), @sizeOf(c.R4GfxRenderBatch), @intFromPtr(output), @sizeOf(c.R4GfxRenderStats))) return error.Alias;
    const commands: []const c.R4GfxDraw = if (batch.command_count == 0) &.{} else blk: {
        _ = try d.pointer(c.R4GfxDraw, batch.commands);
        _ = std.math.add(u64, batch.commands, bytes) catch return error.Overflow;
        break :blk @as([*]const c.R4GfxDraw, @ptrFromInt(batch.commands))[0..batch.command_count];
    };
    if (!device.cleanResources()) return error.Busy;
    defer _ = device.cleanResources();
    var image_count: u32 = 0;
    for (commands, 0..) |*command, i| {
        const pipeline = try device.resource(command.pipeline, true);
        if (pipeline.kind != c.resource_pipeline) return error.Invalid;
        var encoded: c.R4GfxCpuDraw = .{ .operation = pipeline.operation, .source_index = 0,
            .target_index = try imageIndex(device, command.target, &image_count, true), .sampler = 0,
            .source_rect = command.source_rect, .target_rect = command.target_rect,
            .color = command.color, .opacity = command.opacity, .reserved0 = 0, .reserved1 = 0 };
        if (pipeline.operation == c.render_operation_fill) {
            if (!std.meta.eql(command.source, empty_resource) or !std.meta.eql(command.sampler, empty_resource) or !std.meta.eql(command.source_rect, empty_rect)) return error.Invalid;
        } else {
            const sampler = try device.resource(command.sampler, true);
            if (sampler.kind != c.resource_sampler) return error.Invalid;
            encoded.sampler = sampler.sampler;
            encoded.source_index = try imageIndex(device, command.source, &image_count, false);
        }
        device.commands[i] = encoded;
    }
    const memory = device.buffers();
    for (device.image_slots[0..image_count], 0..) |slot, i| {
        const item = &device.resources[slot];
        var image = item.image;
        if (item.backing.reference.id != 0) {
            try d.platform(memory.map(&item.backing.reference, if (device.image_writes[i]) a.gfx_buffer_map_write else a.gfx_buffer_map_read,
                0, image.byte_length, &item.map));
            if (item.map.cpu_address == 0 or item.map.byte_length < image.byte_length or item.map.lease.id == 0 or item.map.lease.generation == 0) return error.Invalid;
            image.cpu_address = item.map.cpu_address;
        }
        if (d.overlaps(image.cpu_address, image.byte_length, @intFromPtr(device), @sizeOf(d.Device)) or
            d.overlaps(image.cpu_address, image.byte_length, @intFromPtr(output), @sizeOf(c.R4GfxRenderStats)) or
            (device.image_writes[i] and (d.overlaps(image.cpu_address, image.byte_length, @intFromPtr(batch), @sizeOf(c.R4GfxRenderBatch)) or
            d.overlaps(image.cpu_address, image.byte_length, batch.commands, bytes)))) return error.Alias;
        device.images[i] = image;
    }
    const cpu_batch: c.R4GfxCpuBatch = .{ .images = @intFromPtr(&device.images), .commands = @intFromPtr(&device.commands),
        .image_count = image_count, .command_count = batch.command_count, .pixel_budget = batch.pixel_budget, .flags = 0, .reserved = 0 };
    var stats: c.R4GfxCpuStats = undefined;
    const rc = cpu.execute(&cpu_batch, &stats);
    if (rc != c.status_ok) return rc;
    device.counters.cpu_read_bytes +|= stats.read_bytes;
    device.counters.cpu_write_bytes +|= stats.write_bytes;
    if (!device.cleanResources()) return error.Busy;
    output.* = .{ .cpu = stats, .backend = c.render_backend_software, .fallback = @intFromBool(device.backend() != c.render_backend_software) };
    return c.status_ok;
}
