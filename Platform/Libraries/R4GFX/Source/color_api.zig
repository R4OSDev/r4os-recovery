//! COLOR_V1 ownership boundary. ICC contexts and color math stay in R4GFX.
const std = @import("std");
const c = @import("r4l_contract");
const d = @import("device.zig");
const color = @import("color.zig");
const icc = @import("color_icc.zig");
const pipeline = @import("color_pipeline.zig");
pub const table: c.ColorV1 = .{
    .header = c.color_v1_header,
    .color_description_validate = descriptionValidate,
    .color_profile_storage_size = profileStorageSize,
    .color_profile_open = profileOpen,
    .color_profile_info = profileInfo,
    .color_profile_apply = profileApply,
    .color_profile_close = profileClose,
    .color_image_transform = imageTransform,
    .color_resource_create = @import("color_resource.zig").create,
    .color_resource_info = @import("color_resource.zig").info,
    .color_resource_transform = @import("color_resource.zig").transform,
    .color_profile_generate = profileGenerate,
    .color_render_submit = d.submitColorRender,
    .color_render_submit_grid = d.submitColorGridRender,
    .color_yuv_image_transform = yuvImageTransform,
    .color_yuv_render_submit = @import("native_yuv.zig").submit,
};
const live_magic: u64 = 0x3146434349584647;
const closed_magic: u64 = 0x3046434349584647;
const Header = extern struct { magic: u64, generation: u64 };
const State = struct {
    address: u64,
    bytes: u64,
    direction: u32,
    intent: u32,
    flags: u32,
    memory: icc.Arena,
    profile: ?icc.Profile = null,
};
const prefix_bytes = std.mem.alignForward(u64, @sizeOf(Header) + @sizeOf(State), 16);
pub fn description(input: *const c.R4GfxColorDescription) d.Error!color.Description {
    _ = try d.pointer(c.R4GfxColorDescription, @intFromPtr(input));
    const value = input.*;
    if (value.version != 1 or value.size != @sizeOf(c.R4GfxColorDescription) or value.flags != 0 or value.reserved != 0) return error.Invalid;
    const desc: color.Description = .{
        .primaries = std.enums.fromInt(color.Primaries, value.primaries) orelse return error.Unsupported,
        .transfer = std.enums.fromInt(color.Transfer, value.transfer) orelse return error.Unsupported,
        .range = std.enums.fromInt(color.Range, value.range) orelse return error.Unsupported,
        .alpha = std.enums.fromInt(color.Alpha, value.alpha) orelse return error.Unsupported,
        .precision = std.enums.fromInt(color.Precision, value.precision) orelse return error.Unsupported,
        .reference_white = @as(f32, @floatFromInt(value.reference_white)) / 10000,
        .peak = @as(f32, @floatFromInt(value.peak)) / 10000,
        .black = @as(f32, @floatFromInt(value.black)) / 10000,
    };
    desc.validate() catch |err| return if (err == error.Invalid) error.Invalid else error.Unsupported;
    return desc;
}
pub fn descriptionValidate(input: *const c.R4GfxColorDescription) callconv(.c) i32 {
    _ = description(input) catch |err| return d.code(err);
    return c.status_ok;
}
pub fn yuvDescription(desc: c.R4GfxYuvDescription) d.Error!@import("color_yuv.zig").Metadata {
    const yuv = @import("color_yuv.zig");
    if (desc.version != 1 or desc.size != @sizeOf(c.R4GfxYuvDescription) or desc.flags != 0 or desc.reserved != 0) return error.Invalid;
    return .{ .primaries = desc.primaries, .transfer = desc.transfer, .matrix = desc.matrix,
        .range = std.enums.fromInt(yuv.Range, desc.range) orelse return error.Unsupported,
        .chroma = std.enums.fromInt(yuv.Chroma, desc.chroma_location) orelse return error.Unsupported,
        .reference_white = @as(f32, @floatFromInt(desc.reference_white)) / 10000,
        .peak = @as(f32, @floatFromInt(desc.peak)) / 10000, .black = @as(f32, @floatFromInt(desc.black)) / 10000 };
}
pub fn profileStorageSize() callconv(.c) u64 {
    return prefix_bytes + 16 * 1024 * 1024;
}
pub fn profileGenerate(definition: *const c.R4GfxColorProfileDefinition, scratch_address: u64, scratch_bytes: u64, output_address: u64, output_capacity: u64, output_bytes: *u64) callconv(.c) i32 {
    _ = d.pointer(c.R4GfxColorProfileDefinition, @intFromPtr(definition)) catch |err| return d.code(err);
    _ = d.pointer(u64, @intFromPtr(output_bytes)) catch |err| return d.code(err);
    _ = d.pointer(u8, output_address) catch |err| return d.code(err);
    _ = d.pointer(u8, scratch_address) catch |err| return d.code(err);
    const config = definition.*;
    if (config.version != 1 or config.size != @sizeOf(c.R4GfxColorProfileDefinition) or config.reserved != 0 or
        config.color_model < 1 or config.color_model > 2 or config.curve < 1 or config.curve > 2 or scratch_address % 16 != 0) return c.status_invalid;
    if (scratch_bytes < 1024 or scratch_bytes > icc.max_arena_bytes or output_capacity < 132 or output_capacity > icc.max_profile_bytes) return c.status_limit;
    const spans = [_][2]u64{ .{ @intFromPtr(definition), @sizeOf(c.R4GfxColorProfileDefinition) }, .{ @intFromPtr(output_bytes), @sizeOf(u64) }, .{ scratch_address, scratch_bytes }, .{ output_address, output_capacity } };
    for (spans, 0..) |span, i| {
        _ = std.math.add(u64, span[0], span[1]) catch return c.status_overflow;
        for (spans[0..i]) |prior| if (d.overlaps(span[0], span[1], prior[0], prior[1])) return c.status_alias;
    }
    const scratch: [*]align(16) u8 = @ptrFromInt(scratch_address);
    const target: [*]u8 = @ptrFromInt(output_address);
    var arena = icc.Arena.init(scratch[0..scratch_bytes]) catch return c.status_invalid;
    const generated = icc.generate(&arena, .{ .gray = config.color_model == c.color_model_gray, .srgb_curve = config.curve == c.color_curve_srgb, .chromaticities = .{ .white = .{ unit100000(config.white_x), unit100000(config.white_y) }, .red = .{ unit100000(config.red_x), unit100000(config.red_y) }, .green = .{ unit100000(config.green_x), unit100000(config.green_y) }, .blue = .{ unit100000(config.blue_x), unit100000(config.blue_y) } }, .gamma = .{ unit100000(config.gamma_red), unit100000(config.gamma_green), unit100000(config.gamma_blue) } }, target[0..output_capacity]) catch |err| return status(err);
    output_bytes.* = generated;
    return c.status_ok;
}
fn unit100000(value: u32) f64 {
    return @as(f64, @floatFromInt(value)) / 100000;
}
fn status(err: icc.Error) i32 {
    return switch (err) {
        error.Invalid, error.NonFinite => c.status_invalid,
        error.Unsupported => c.status_unsupported,
        error.Memory => c.status_limit,
        error.Alias => c.status_alias,
    };
}
fn stateAt(address: u64) d.Error!*State {
    if (address % 16 != 0) return error.Invalid;
    const next = std.math.add(u64, address, @sizeOf(Header)) catch return error.Overflow;
    return d.pointer(State, next);
}
fn get(input: *const c.R4GfxColorProfile, closed: bool) d.Error!*State {
    _ = try d.pointer(c.R4GfxColorProfile, @intFromPtr(input));
    const handle = input.*;
    const header = try d.pointer(Header, handle.address);
    if (handle.generation == 0 or header.generation != handle.generation) return error.Stale;
    if (header.magic != live_magic and (!closed or header.magic != closed_magic)) return error.Stale;
    const state = try stateAt(handle.address);
    if (state.address != handle.address or state.bytes < prefix_bytes + 1024 or state.bytes > prefix_bytes + icc.max_arena_bytes) return error.Invalid;
    return state;
}
fn separate(state: *const State, pointer: u64, bytes: u64) bool {
    return !d.overlaps(state.address, state.bytes, pointer, bytes);
}
pub fn profileOpen(config: *const c.R4GfxColorProfileConfig, output: *c.R4GfxColorProfile) callconv(.c) i32 {
    open(config, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn open(config: *const c.R4GfxColorProfileConfig, output: *c.R4GfxColorProfile) d.Error!void {
    _ = try d.pointer(c.R4GfxColorProfileConfig, @intFromPtr(config));
    _ = try d.pointer(c.R4GfxColorProfile, @intFromPtr(output));
    const request = config.*;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxColorProfileConfig) or request.reserved != 0 or request.direction > 1 or request.intent > 3 or request.flags & ~@as(u32, 3) != 0 or
        (request.flags & c.color_profile_calibration != 0 and request.direction != c.color_profile_output)) return error.Invalid;
    if (request.storage_bytes < prefix_bytes + 1024 or request.storage_bytes > prefix_bytes + icc.max_arena_bytes or
        request.profile_bytes < 132 or request.profile_bytes > icc.max_profile_bytes) return error.Limit;
    const header = try d.pointer(Header, request.storage_address);
    const state = try stateAt(request.storage_address);
    _ = try d.pointer(u8, request.profile_address);
    _ = std.math.add(u64, request.storage_address, request.storage_bytes) catch return error.Overflow;
    _ = std.math.add(u64, request.profile_address, request.profile_bytes) catch return error.Overflow;
    const metadata = .{ .{ @intFromPtr(config), @sizeOf(c.R4GfxColorProfileConfig) }, .{ @intFromPtr(output), @sizeOf(c.R4GfxColorProfile) }, .{ request.profile_address, request.profile_bytes } };
    inline for (metadata) |span| if (d.overlaps(request.storage_address, request.storage_bytes, span[0], span[1])) return error.Alias;
    if (d.overlaps(@intFromPtr(output), @sizeOf(c.R4GfxColorProfile), @intFromPtr(config), @sizeOf(c.R4GfxColorProfileConfig)) or
        d.overlaps(@intFromPtr(output), @sizeOf(c.R4GfxColorProfile), request.profile_address, request.profile_bytes)) return error.Alias;
    if (header.magic == live_magic) return error.Busy;
    if ((header.magic != closed_magic and header.magic != 0) or (header.magic == 0 and header.generation != 0)) return error.Invalid;
    const generation = std.math.add(u64, header.generation, 1) catch return error.Limit;
    const storage: [*]align(16) u8 = @ptrFromInt(request.storage_address + prefix_bytes);
    header.* = .{ .magic = closed_magic, .generation = generation };
    state.* = .{ .address = request.storage_address, .bytes = request.storage_bytes, .direction = request.direction, .intent = request.intent, .flags = request.flags, .memory = icc.Arena.init(storage[0 .. request.storage_bytes - prefix_bytes]) catch return error.Invalid };
    const bytes: [*]const u8 = @ptrFromInt(request.profile_address);
    state.profile = icc.Profile.open(&state.memory, bytes[0..request.profile_bytes], @enumFromInt(request.direction), @enumFromInt(request.intent), request.flags & c.color_profile_black_compensation != 0, request.flags & c.color_profile_calibration != 0) catch |err| return switch (err) {
        error.Memory => error.Limit,
        error.Unsupported => error.Unsupported,
        error.Alias => error.Alias,
        else => error.Invalid,
    };
    header.magic = live_magic;
    output.* = .{ .address = request.storage_address, .generation = generation };
}
pub fn profileInfo(input: *const c.R4GfxColorProfile, output: *c.R4GfxColorProfileInfo) callconv(.c) i32 {
    const state = get(input, false) catch |err| return d.code(err);
    _ = d.pointer(c.R4GfxColorProfileInfo, @intFromPtr(output)) catch |err| return d.code(err);
    if (!separate(state, @intFromPtr(output), @sizeOf(c.R4GfxColorProfileInfo)) or
        d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxColorProfile), @intFromPtr(output), @sizeOf(c.R4GfxColorProfileInfo))) return c.status_alias;
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxColorProfileInfo), .storage_bytes = state.bytes, .used_bytes = prefix_bytes + state.memory.used, .direction = state.direction, .intent = state.intent, .flags = state.flags, .error_code = state.memory.error_code };
    return c.status_ok;
}
pub fn profileApply(input: *const c.R4GfxColorProfile, request: *const c.R4GfxColorProfileRequest) callconv(.c) i32 {
    const state = get(input, false) catch |err| return d.code(err);
    _ = d.pointer(c.R4GfxColorProfileRequest, @intFromPtr(request)) catch |err| return d.code(err);
    if (!separate(state, @intFromPtr(input), @sizeOf(c.R4GfxColorProfile)) or !separate(state, @intFromPtr(request), @sizeOf(c.R4GfxColorProfileRequest))) return c.status_alias;
    const value = request.*;
    if (value.reserved != 0) return c.status_invalid;
    if (value.pixel_count > 16 * 1024 * 1024) return c.status_limit;
    const bytes: u64 = @as(u64, value.pixel_count) * 12;
    if (value.pixel_count == 0) return c.status_ok;
    _ = d.pointer([3]f32, value.source_address) catch |err| return d.code(err);
    _ = d.pointer([3]f32, value.target_address) catch |err| return d.code(err);
    _ = std.math.add(u64, value.source_address, bytes) catch return c.status_overflow;
    _ = std.math.add(u64, value.target_address, bytes) catch return c.status_overflow;
    if (!separate(state, value.source_address, bytes) or !separate(state, value.target_address, bytes) or
        d.overlaps(value.target_address, bytes, @intFromPtr(input), @sizeOf(c.R4GfxColorProfile)) or
        d.overlaps(value.target_address, bytes, @intFromPtr(request), @sizeOf(c.R4GfxColorProfileRequest))) return c.status_alias;
    const from: [*]const [3]f32 = @ptrFromInt(value.source_address);
    const to: [*][3]f32 = @ptrFromInt(value.target_address);
    if (state.profile) |*profile| {
        profile.apply(from[0..value.pixel_count], to[0..value.pixel_count]) catch |err| return status(err);
    } else return c.status_stale;
    return c.status_ok;
}
pub fn profileClose(input: *const c.R4GfxColorProfile) callconv(.c) i32 {
    const state = get(input, true) catch |err| return d.code(err);
    if (!separate(state, @intFromPtr(input), @sizeOf(c.R4GfxColorProfile))) return c.status_alias;
    if (state.profile) |*profile| profile.close();
    state.profile = null;
    const header: *Header = @ptrFromInt(state.address);
    header.magic = closed_magic;
    return c.status_ok;
}

pub fn imageTransform(source: *const c.R4GfxColorImage, target: *const c.R4GfxColorImage, request: *const c.R4GfxColorTransform, output: *c.R4GfxCpuStats) callconv(.c) i32 {
    transform(source, target, request, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn transform(source: *const c.R4GfxColorImage, target: *const c.R4GfxColorImage, request: *const c.R4GfxColorTransform, output: *c.R4GfxCpuStats) d.Error!void {
    _ = try d.pointer(c.R4GfxColorImage, @intFromPtr(source));
    _ = try d.pointer(c.R4GfxColorImage, @intFromPtr(target));
    _ = try d.pointer(c.R4GfxColorTransform, @intFromPtr(request));
    _ = try d.pointer(c.R4GfxCpuStats, @intFromPtr(output));
    const inputs = .{ source, target, request };
    inline for (inputs) |input| {
        const bytes = @sizeOf(@typeInfo(@TypeOf(input)).pointer.child);
        if (d.overlaps(@intFromPtr(input), bytes, @intFromPtr(output), @sizeOf(c.R4GfxCpuStats)) or
            d.overlaps(@intFromPtr(input), bytes, target.image.cpu_address, target.image.byte_length)) return error.Alias;
    }
    var images: [2]pipeline.Image = undefined;
    for ([_]*const c.R4GfxColorImage{ source, target }, 0..) |input, i| {
        if (input.version != 1 or input.size != @sizeOf(c.R4GfxColorImage)) return error.Invalid;
        const desc = try description(&input.description);
        var profile: ?*const icc.Profile = null;
        if (input.profile.address != 0 or input.profile.generation != 0) {
            const state = try get(&input.profile, false);
            if (state.direction != i) return error.Invalid;
            inline for (inputs) |metadata| if (!separate(state, @intFromPtr(metadata), @sizeOf(@typeInfo(@TypeOf(metadata)).pointer.child))) return error.Alias;
            if (!separate(state, @intFromPtr(output), @sizeOf(c.R4GfxCpuStats))) return error.Alias;
            for ([_]*const c.R4GfxColorImage{ source, target }) |image| if (!separate(state, image.image.cpu_address, image.image.byte_length)) return error.Alias;
            profile = if (state.profile) |*value| value else return error.Stale;
        }
        if (d.overlaps(input.image.cpu_address, input.image.byte_length, @intFromPtr(output), @sizeOf(c.R4GfxCpuStats))) return error.Alias;
        images[i] = try pipeline.Image.init(input.image, desc, profile);
    }
    const stats = try pipeline.execute(images[0], images[1], request.*);
    output.* = stats;
}

pub fn yuvImageTransform(source: *const c.R4GfxYuvImage, target: *const c.R4GfxColorImage, request: *const c.R4GfxColorTransform, output: *c.R4GfxCpuStats) callconv(.c) i32 {
    transformYuv(source, target, request, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn transformYuv(source: *const c.R4GfxYuvImage, target: *const c.R4GfxColorImage, request: *const c.R4GfxColorTransform, output: *c.R4GfxCpuStats) d.Error!void {
    const yuv = @import("color_yuv.zig");
    _ = try d.pointer(c.R4GfxCpuStats, @intFromPtr(output));
    const inputs = .{ source, target, request };
    inline for (inputs) |input| {
        const T = @typeInfo(@TypeOf(input)).pointer.child;
        _ = try d.pointer(T, @intFromPtr(input));
        if (d.overlaps(@intFromPtr(input), @sizeOf(T), @intFromPtr(output), @sizeOf(c.R4GfxCpuStats))) return error.Alias;
    }
    const from = source.*; const to = target.*; const operation = request.*;
    if (from.version != 1 or from.size != @sizeOf(c.R4GfxYuvImage) or from.reserved != 0 or
        to.version != 1 or to.size != @sizeOf(c.R4GfxColorImage)) return error.Invalid;
    const format = std.enums.fromInt(yuv.Format, from.format) orelse return error.Unsupported;
    if (from.plane_count != @as(u32, if (format == .yuv420p) 3 else 2)) return error.Invalid;
    const metadata = try yuvDescription(from.description);
    inline for (inputs) |input| if (d.overlaps(@intFromPtr(input), @sizeOf(@typeInfo(@TypeOf(input)).pointer.child), to.image.cpu_address, to.image.byte_length)) return error.Alias;
    if (d.overlaps(@intFromPtr(output), @sizeOf(c.R4GfxCpuStats), to.image.cpu_address, to.image.byte_length)) return error.Alias;
    var planes: [3]yuv.Plane = undefined;
    for ([_]c.R4GfxYuvPlane{ from.plane0, from.plane1, from.plane2 }, &planes, 0..) |plane, *view, i| {
        if (plane.reserved != 0) return error.Invalid;
        if (i >= from.plane_count) {
            if (plane.cpu_address != 0 or plane.byte_length != 0 or plane.pitch != 0) return error.Invalid;
            view.* = .{ .bytes = &.{}, .pitch = 0 };
            continue;
        }
        _ = try d.pointer(u8, plane.cpu_address);
        _ = std.math.add(u64, plane.cpu_address, plane.byte_length) catch return error.Overflow;
        if (d.overlaps(plane.cpu_address, plane.byte_length, @intFromPtr(output), @sizeOf(c.R4GfxCpuStats)) or
            d.overlaps(plane.cpu_address, plane.byte_length, to.image.cpu_address, to.image.byte_length)) return error.Alias;
        const bytes: [*]const u8 = @ptrFromInt(plane.cpu_address);
        view.* = .{ .bytes = bytes[0..plane.byte_length], .pitch = plane.pitch };
    }
    const image = try yuv.Image.init(format, from.width, from.height,
        .{ .x = from.crop.x, .y = from.crop.y, .width = from.crop.width, .height = from.crop.height }, planes, metadata);
    var profile: ?*const icc.Profile = null;
    if (to.profile.address != 0 or to.profile.generation != 0) {
        const state = try get(&to.profile, false);
        if (state.direction != c.color_profile_output) return error.Invalid;
        inline for (inputs) |input| if (!separate(state, @intFromPtr(input), @sizeOf(@typeInfo(@TypeOf(input)).pointer.child))) return error.Alias;
        if (!separate(state, @intFromPtr(output), @sizeOf(c.R4GfxCpuStats)) or !separate(state, to.image.cpu_address, to.image.byte_length)) return error.Alias;
        for (planes) |plane| if (!separate(state, @intFromPtr(plane.bytes.ptr), plane.bytes.len)) return error.Alias;
        profile = if (state.profile) |*value| value else return error.Stale;
    }
    const target_image = try pipeline.Image.init(to.image, try description(&to.description), profile);
    const stats = try pipeline.executeYuv(image, target_image, operation);
    output.* = stats;
}
