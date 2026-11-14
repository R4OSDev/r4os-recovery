const std = @import("std");
const r4os = @import("r4os");
const c = @import("r4l_contract");
const render = @import("cpu_render.zig");
const device = @import("device.zig");
const swapchain = @import("device_swapchain.zig");
const color_api = @import("color_api.zig");
comptime {
    _ = @import("color_icc.zig");
}

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}

fn pixelBytes(format: u32) ?u64 {
    return switch (format) {
        c.format_xrgb8888, c.format_argb8888 => 4,
        c.format_r8 => 1,
        else => null,
    };
}
fn linear(width: u32, height: u32, format: u32, alignment: u64) !c.R4GfxLinearLayout {
    if (width == 0 or height == 0 or alignment == 0 or !std.math.isPowerOfTwo(alignment)) return error.Invalid;
    const bpp = pixelBytes(format) orelse return error.Unsupported;
    const row = try std.math.mul(u64, width, bpp);
    const pitch = (try std.math.add(u64, row, alignment - 1)) & ~(alignment - 1);
    return .{ .byte_length = try std.math.mul(u64, pitch, height), .pitch = pitch, .width = width, .height = height, .format = format, .reserved = 0 };
}
pub fn r4gfx_linear_layout_impl(width: u32, height: u32, format: u32, alignment: u64, output: *c.R4GfxLinearLayout) callconv(.c) i32 {
    if (@intFromPtr(output) == 0) return c.status_invalid;
    output.* = linear(width, height, format, alignment) catch |err| return switch (err) {
        error.Invalid => c.status_invalid,
        error.Unsupported => c.status_unsupported,
        else => c.status_overflow,
    };
    return c.status_ok;
}
pub fn r4gfx_fill_rect_impl(image: *const c.R4GfxCpuImage, rect: *const c.R4GfxRect, color: u32) callconv(.c) i32 {
    if (@intFromPtr(image) == 0 or @intFromPtr(rect) == 0 or image.cpu_address == 0 or image.reserved != 0) return c.status_invalid;
    const bpp = pixelBytes(image.format) orelse return c.status_unsupported;
    const shape = linear(image.width, image.height, image.format, 1) catch return c.status_invalid;
    if (image.pitch < shape.pitch or rect.x > image.width or rect.y > image.height or
        rect.width > image.width - rect.x or rect.height > image.height - rect.y) return c.status_invalid;
    const span = std.math.mul(u64, image.pitch, image.height) catch return c.status_overflow;
    if (span > image.byte_length) return c.status_invalid;
    _ = std.math.add(u64, image.cpu_address, span) catch return c.status_overflow;
    const pixels: [*]u8 = @ptrFromInt(image.cpu_address);
    var y: u64 = rect.y;
    while (y < @as(u64, rect.y) + rect.height) : (y += 1) {
        var x: u64 = rect.x;
        while (x < @as(u64, rect.x) + rect.width) : (x += 1) {
            const offset = y * image.pitch + x * bpp;
            if (bpp == 1) pixels[offset] = @truncate(color) else {
                // Unaligned CPU maps are legal; no padding or VRAM reads.
                const value = if (image.format == c.format_xrgb8888) color & 0x00FFFFFF else color;
                std.mem.writeInt(u32, pixels[offset..][0..4], value, .little);
            }
        }
    }
    return c.status_ok;
}
pub export var r4gfx_api_v1: c.ApiV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.api_v1_header,
    .linear_layout = r4gfx_linear_layout_impl,
    .fill_rect = r4gfx_fill_rect_impl,
};
pub export var r4gfx_render_v1: c.RenderV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.render_v1_header,
    .capabilities = render.capabilities,
    .execute_cpu = render.execute,
};
pub export var r4gfx_device_v1: c.DeviceV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.device_v1_header,
    .storage_size = device.storageSize,
    .device_open = device.open,
    .device_close = device.close,
    .device_info = device.info,
    .device_refresh = device.refresh,
    .resource_create = device.createResource,
    .resource_retain = device.retainResource,
    .resource_release = device.releaseResource,
    .resource_info = device.resourceInfo,
    .render = device.render,
    .copy_submit = device.submitCopy,
    .job_info = device.jobInfo,
    .job_cancel = device.cancelJob,
    .job_release = device.releaseJob,
    .copy_submit_ex = device.submitCopyEx,
    .job_fence = device.jobFence,
    .render_submit = device.submitRender,
    .image_prepare = device.prepareImage,
    .image_present = device.presentImage,
    .render_submit_list = device.submitRenderList,
    .render_submit_grid_list = device.submitRenderGridList,
    .presentation_info = swapchain.presentationInfo,
    .swapchain_open = swapchain.open,
    .swapchain_acquire = swapchain.acquire,
    .swapchain_present = swapchain.present,
    .swapchain_poll = swapchain.poll,
    .swapchain_release = swapchain.release,
    .swapchain_resize = swapchain.resize,
    .swapchain_close = swapchain.close,
    .presentation_plan = swapchain.plan,
    .memory_info = device.memoryInfo,
    .memory_trim = device.memoryTrim,
    .resource_resident = device.resourceResident,
    .resource_priority = device.resourcePriority,
};
pub export var r4gfx_color_v1: c.ColorV1 align(8) linksection(".data.r4l_exports") = color_api.table;
test "bounded color conversion preserves reference and error semantics" {
    try @import("color_test.zig").check(&r4gfx_color_v1);
}
test "layout overflow and rejected rectangles preserve bytes including padding" {
    try @import("device_test.zig").check();
    try @import("swapchain_state_test.zig").check();
    try @import("cpu_render_test.zig").check();
    const t = std.testing;
    var layout: c.R4GfxLinearLayout = undefined;
    try t.expectEqual(c.status_ok, r4gfx_linear_layout_impl(3, 2, c.format_xrgb8888, 16, &layout));
    try t.expectEqual(@as(u64, 32), layout.byte_length);
    const original = layout;
    try t.expectEqual(c.status_overflow, r4gfx_linear_layout_impl(0xFFFFFFFF, 0xFFFFFFFF, c.format_xrgb8888, 4096, &layout));
    try t.expectEqualDeep(original, layout);
    var bytes: [32]u8 = .{0xA5} ** 32;
    var image = c.R4GfxCpuImage{ .cpu_address = @intFromPtr(&bytes), .byte_length = bytes.len, .pitch = 16, .width = 3, .height = 2, .format = c.format_xrgb8888, .reserved = 0 };
    try t.expectEqual(c.status_invalid, r4gfx_fill_rect_impl(&image, &.{ .x = 2, .y = 0, .width = 2, .height = 1 }, 0));
    try t.expectEqualSlices(u8, &(.{0xA5} ** 32), &bytes);
    try t.expectEqual(c.status_ok, r4gfx_fill_rect_impl(&image, &.{ .x = 1, .y = 0, .width = 2, .height = 2 }, 0xFF123456));
    try t.expectEqualSlices(u8, &.{ 0x56, 0x34, 0x12, 0 }, bytes[4..8]);
    try t.expectEqualSlices(u8, &(.{0xA5} ** 4), bytes[12..16]);
    image.pitch = std.math.maxInt(u64);
    try t.expectEqual(c.status_overflow, r4gfx_fill_rect_impl(&image, &.{ .x = 0, .y = 0, .width = 1, .height = 1 }, 0));
}

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4gfx_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
