// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Existing provider-test cases, through the public backend table.
const std = @import("std");
const c = @import("r4l_contract");
const t = std.testing;
pub fn run(api: *const c.BackendV1) !void {
    const profile: c.R4NvDeviceProfile = .{ .version = 1, .size = @sizeOf(c.R4NvDeviceProfile), .vendor_id = 0x10de,
        .copy_class = 0xc7b5, .rm_release = c.rm_release, .command_abi = c.command_abi, .adapter_id = 3, .flags = 0,
        .device_generation = 7, .reset_generation = 11 };
    var request: c.R4NvImageRequest = .{
        .view = .{ .version = 1, .size = 64, .width = 7, .height = 5, .format = 0x34325241, .location = 0,
            .modifier = 0, .byte_length = 140, .pitch = 28, .alignment = 4096, .usage = 31, .reserved = 0 },
        .uses = c.image_use_texture, .preference = c.image_prefer_compatible, .flags = 0, .reserved = 0,
    };
    var plan: c.R4NvImagePlan = undefined;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    // Seven BGRA texels, five rows:64-byte rows in one eight-row GOB,
    // rounded to the native64KB allocation granule. No image scaling.
    try t.expect(plan.action == c.image_action_convert and plan.reasons == c.image_reason_location and plan.layout == 1 and
        plan.modifier == 0x0300000000606010 and plan.pitch == 64 and plan.byte_length == 512 and plan.allocation_bytes == 65536 and plan.log2_gobs == 0);
    request.preference = c.image_prefer_linear;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.layout == 0 and plan.modifier == 0 and plan.pitch == 256 and plan.byte_length == 1280 and plan.allocation_bytes == 65536);
    request.view = .{ .version = 1, .size = 64, .width = 7, .height = 5, .format = 0x34325241, .location = 1,
        .modifier = 0, .byte_length = 65536, .pitch = 32, .alignment = 65536, .usage = 28, .reserved = 0 };
    request.preference = c.image_prefer_compatible;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_reuse and plan.pitch == 32 and plan.supported_uses == c.image_use_texture);
    request.uses = c.image_use_render_target;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_convert and plan.reasons == c.image_reason_pitch);
    request.view.modifier = 0x0300000000606010; request.view.pitch = 64;
    request.uses = c.image_use_texture|c.image_use_render_target;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_reuse and plan.supported_uses == 3 and plan.pitch == 64);
    request.view.pitch = 128; // Valid CE row geometry, unsuitable TIC stride.
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_convert and plan.reasons == c.image_reason_pitch and plan.pitch == 64);
    request.view.pitch = 64; request.uses = c.image_use_scanout;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_convert and plan.reasons == c.image_reason_usage);
    request.view.usage |= 32;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_reuse and plan.supported_uses == c.image_use_texture|c.image_use_scanout);
    request.flags = c.image_force_copy;
    try t.expectEqual(c.status_ok,api.image_layout(&profile,&request,&plan));
    try t.expect(plan.action == c.image_action_convert and plan.reasons == c.image_reason_forced);
    const accepted = plan;
    const original = request;
    for ([_]u64{1,0x0100000000606010,0x0300000000e06010,0x0300000000606016}) |modifier| {
        request.view.modifier = modifier;
        try t.expectEqual(c.status_unsupported,api.image_layout(&profile,&request,&plan));
        try t.expectEqualDeep(accepted,plan);
    }
    request = original; request.uses |= c.image_use_render_target;
    try t.expectEqual(c.status_unsupported,api.image_layout(&profile,&request,&plan));
    request = original; request.view.format = 0x20203852;
    try t.expectEqual(c.status_unsupported,api.image_layout(&profile,&request,&plan));
    request = original; request.view.byte_length = 511;
    try t.expectEqual(c.status_invalid,api.image_layout(&profile,&request,&plan));
    request = original; request.view.pitch = 65;
    try t.expectEqual(c.status_invalid,api.image_layout(&profile,&request,&plan));
    request = original; request.view.location = 0;
    try t.expectEqual(c.status_unsupported,api.image_layout(&profile,&request,&plan));
    request = original; request.view.usage &= ~@as(u32,4);
    try t.expectEqual(c.status_unsupported,api.image_layout(&profile,&request,&plan));
    request = original;
    try t.expectEqual(c.status_invalid,api.image_layout(&profile,&request,@ptrCast(&request)));
    try t.expectEqualDeep(original,request); try t.expectEqualDeep(accepted,plan);
    var stale = profile; stale.command_abi += 1;
    try t.expectEqual(c.status_unsupported,api.image_layout(&stale,&request,&plan));
    try t.expectEqualDeep(accepted,plan);
}
