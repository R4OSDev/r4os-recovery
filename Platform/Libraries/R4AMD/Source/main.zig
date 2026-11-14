// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r4os = @import("r4os");
const c = @import("r4l_contract");

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}

pub export fn r4amd_get_info_impl(output: *c.R4AmdInfo, output_bytes: u32) callconv(.c) i32 {
    if (output_bytes < @sizeOf(c.R4AmdInfo)) return c.status_invalid;
    output.* = .{
        .version = c.info_version,
        .size = @sizeOf(c.R4AmdInfo),
        .mesa_major = 26,
        .mesa_minor = 2,
        .mesa_patch = 2,
        .implementation_stage = 28,
        .capability_flags = 0,
        .reserved = 0,
    };
    return c.status_ok;
}

pub export var r4amd_info_v1: c.InfoV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.info_v1_header,
    .get_info = r4amd_get_info_impl,
};

pub export var r4amd_backend_v1: c.BackendV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.backend_v1_header,
    .negotiate = r4amd_negotiate_impl,
    .encode_copy = r4amd_encode_copy_impl,
    .encode_fill = r4amd_encode_fill_impl,
    .encode_pm4_frame = r4amd_encode_pm4_frame_impl,
    .media_caps = r4amd_media_caps_impl,
};

pub export fn r4amd_negotiate_impl(profile: *const c.R4AmdDeviceProfile, output: *c.R4AmdFeatures) callconv(.c) i32 {
    return @import("backend.zig").negotiate(profile, output);
}

pub export fn r4amd_encode_copy_impl(request: *const c.R4AmdCopy, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    return @import("backend.zig").encodeCopy(request, commands, capacity, written);
}
pub export fn r4amd_encode_fill_impl(request: *const c.R4AmdFill, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    return @import("backend.zig").encodeFill(request, commands, capacity, written);
}

pub export fn r4amd_encode_pm4_frame_impl(request: *const c.R4AmdPm4Frame, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    return @import("backend.zig").encodePm4Frame(request, commands, capacity, written);
}

pub export var r4amd_image_v1: c.ImageV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.image_v1_header,
    .calculate = r4amd_image_calculate_impl,
    .address = r4amd_image_address_impl,
    .metadata = r4amd_image_metadata_impl,
    .import_image = r4amd_image_import_image_impl,
    .descriptors = r4amd_image_descriptors_impl,
};
pub export fn r4amd_image_calculate_impl(r: *const c.R4AmdImageRequest, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageLayout, mips: [*]c.R4AmdMip, capacity: u32) callconv(.c) i32 {
    return @import("images.zig").calculate(r, workspace, bytes, out, mips, capacity);
}
pub export fn r4amd_image_address_impl(r: *const c.R4AmdImageRequest, coord: *const c.R4AmdCoordinate, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageAddress) callconv(.c) i32 {
    return @import("images.zig").address(r, coord, workspace, bytes, out);
}
pub export fn r4amd_image_metadata_impl(r: *const c.R4AmdImageRequest, workspace: [*]u8, bytes: u32, out: *c.R4AmdMetadata) callconv(.c) i32 {
    return @import("images.zig").metadata(r, workspace, bytes, out);
}
pub export fn r4amd_image_import_image_impl(r: *const c.R4AmdImageRequest, imported: *const c.R4AmdImageImport, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageLayout, mips: [*]c.R4AmdMip, capacity: u32) callconv(.c) i32 {
    return @import("images.zig").importImage(r, imported, workspace, bytes, out, mips, capacity);
}
pub export fn r4amd_image_descriptors_impl(r: *const c.R4AmdImageRequest, view: *const c.R4AmdImageView, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageDescriptors) callconv(.c) i32 {
    return @import("images.zig").descriptors(r, view, workspace, bytes, out);
}

const render = @import("render_impl.zig").Provider(c);
pub export fn r4amd_shader_impl(profile: u32, code: [*]u8, capacity: u32, output: *c.R4AmdShader) callconv(.c) i32 {
    return render.shader(profile, code, capacity, output);
}
pub export fn r4amd_encode_pipeline_impl(vs: *const c.R4AmdShader, ps: *const c.R4AmdShader, state: *const c.R4AmdPipeline, color: *const c.R4AmdImageDescriptors, depth: *const c.R4AmdDepth, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    return render.pipeline(vs, ps, state, color, depth, commands, capacity, written);
}
pub export fn r4amd_encode_draw_impl(request: *const c.R4AmdDraw, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    return render.draw(request, commands, capacity, written);
}
pub export var r4amd_render_v1: c.RenderV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.render_v1_header,
    .shader = r4amd_shader_impl,
    .encode_pipeline = r4amd_encode_pipeline_impl,
    .encode_draw = r4amd_encode_draw_impl,
};

pub export fn r4amd_media_caps_impl(query: *const c.R4AmdMediaQuery, output: *c.R4AmdMediaCaps) callconv(.c) i32 {
    return @import("media.zig").Provider(c).caps(query, output);
}

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4amd_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
