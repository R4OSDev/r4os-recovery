const std = @import("std");
const c = @import("r4l_contract");
pub const r4nv_image_layout_impl = @import("image_layout.zig").r4nv_image_layout_impl;
const copy = @import("copy.zig");

pub fn r4nv_negotiate_impl(profile: *const c.R4NvDeviceProfile, output: *c.R4NvFeatures) callconv(.c) i32 {
    if (@intFromPtr(profile) == 0 or @intFromPtr(output) == 0 or
        @intFromPtr(profile) % @alignOf(c.R4NvDeviceProfile) != 0 or @intFromPtr(output) % @alignOf(c.R4NvFeatures) != 0) return c.status_invalid;
    if (profile.version != 1 or profile.size != @sizeOf(c.R4NvDeviceProfile) or profile.flags != 0 or
        profile.adapter_id == 0 or profile.device_generation == 0 or profile.reset_generation == 0) return c.status_invalid;
    if (profile.vendor_id != 0x10de or profile.rm_release != c.rm_release or profile.command_abi != c.command_abi or
        !copy.supported(profile.copy_class)) return c.status_unsupported;
    output.* = .{ .version = 1, .size = @sizeOf(c.R4NvFeatures), .command_abi = c.command_abi,
        .features = c.feature_copy_linear | c.feature_copy_rows | c.feature_copy_graphics_channel |
            (if (copy.supportsBlocks(profile.copy_class)) c.feature_copy_layout | c.feature_image_layout else @as(u32,0)), .copy_class = profile.copy_class,
        .gpu_address_bits = 49, .max_command_words = c.max_layout_command_words, .reserved = 0,
        .max_copy_bytes = std.math.maxInt(u32), .max_rows = std.math.maxInt(u32) };
    return c.status_ok;
}

// Mixed GR queues use GR0/compute1/CE4 (Mesa nouveau/headers/nv_push.h).
// NV906F/NVC56F INCR headers place SUBCHANNEL in bits15:13. The private
// encoder result contains only bounded INCR packets; preserve every operand
// and the compiled independent-CE encoder's existing subchannel0 behavior.
fn copyChannel(program: *copy.Program, flags: u32) error{Invalid}!void {
    if (flags == 0) return;
    if (flags != c.copy_flag_graphics_channel) return error.Invalid;
    const used: usize = program.count;
    if (used > program.data.len) return error.Invalid;
    var cursor: usize = 0;
    while (cursor < used) {
        const header = program.data[cursor];
        const count: usize = @intCast((header >> 16) & 0x1fff);
        if (header >> 29 != 1 or header & (7 << 13) != 0 or count == 0 or count > used - cursor - 1)
            return error.Invalid;
        program.data[cursor] = header | (4 << 13);
        cursor += count + 1;
    }
}

fn block(input: c.R4NvCopyBlock) error{Invalid}!?copy.Block {
    if (input.enabled == 0) {
        if (input.width != 0 or input.height != 0 or input.x != 0 or input.y != 0 or input.log2_gobs != 0) return error.Invalid;
        return null;
    }
    if (input.enabled != 1 or input.log2_gobs > 5) return error.Invalid;
    return .{ .width = input.width, .height = input.height, .x = input.x, .y = input.y, .log2_gobs = @intCast(input.log2_gobs) };
}
pub fn r4nv_encode_copy_layout_impl(request: *const c.R4NvCopyLayout, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    if (@intFromPtr(request) == 0 or @intFromPtr(commands) == 0 or @intFromPtr(written) == 0 or
        @intFromPtr(request) % @alignOf(c.R4NvCopyLayout) != 0 or @intFromPtr(commands) % 4 != 0 or @intFromPtr(written) % 4 != 0) return c.status_invalid;
    const base = request.copy;
    if (base.version != 1 or base.size != @sizeOf(c.R4NvCopy) or base.flags & ~c.copy_flag_graphics_channel != 0 or
        (base.rows == 0 and (base.source_pitch != 0 or base.target_pitch != 0))) return c.status_invalid;
    var program = copy.encodeTransfer(base.copy_class, .{
        .source = base.source, .target = base.target, .bytes = base.bytes,
        .rows = if (base.rows == 0) null else .{ .count = base.rows, .source_pitch = base.source_pitch, .target_pitch = base.target_pitch },
        .source_block = block(request.source_block) catch return c.status_invalid,
        .target_block = block(request.target_block) catch return c.status_invalid,
    }, base.semaphore, base.point) catch |err| return if (err == error.Unsupported) c.status_unsupported else c.status_invalid;
    copyChannel(&program, base.flags) catch return c.status_invalid;
    if (capacity < program.count) return c.status_capacity;
    const command_bytes = @as(u64, program.count) * 4;
    if (overlaps(@intFromPtr(commands), command_bytes, @intFromPtr(request), @sizeOf(c.R4NvCopyLayout)) or
        overlaps(@intFromPtr(written), 4, @intFromPtr(request), @sizeOf(c.R4NvCopyLayout)) or
        overlaps(@intFromPtr(commands), command_bytes, @intFromPtr(written), 4)) return c.status_invalid;
    @memcpy(commands[0..program.count], program.slice());
    written.* = program.count;
    return c.status_ok;
}

fn overlaps(left: u64, left_bytes: u64, right: u64, right_bytes: u64) bool {
    const left_end = std.math.add(u64, left, left_bytes) catch return true;
    const right_end = std.math.add(u64, right, right_bytes) catch return true;
    return left < right_end and right < left_end;
}

pub fn r4nv_encode_copy_impl(request: *const c.R4NvCopy, commands: [*]u32, capacity: u32, written: *u32) callconv(.c) i32 {
    if (@intFromPtr(request) == 0 or @intFromPtr(commands) == 0 or @intFromPtr(written) == 0 or
        @intFromPtr(request) % @alignOf(c.R4NvCopy) != 0 or @intFromPtr(commands) % 4 != 0 or @intFromPtr(written) % 4 != 0)
        return c.status_invalid;
    if (request.version != 1 or request.size != @sizeOf(c.R4NvCopy) or request.flags & ~c.copy_flag_graphics_channel != 0 or
        (request.rows == 0 and (request.source_pitch != 0 or request.target_pitch != 0))) return c.status_invalid;
    var program = copy.encodeTransfer(request.copy_class, .{
        .source = request.source, .target = request.target, .bytes = request.bytes,
        .rows = if (request.rows == 0) null else .{ .count = request.rows, .source_pitch = request.source_pitch, .target_pitch = request.target_pitch },
    }, request.semaphore, request.point) catch |err| return if (err == error.Unsupported) c.status_unsupported else c.status_invalid;
    copyChannel(&program, request.flags) catch return c.status_invalid;
    if (capacity < program.count) return c.status_capacity;
    const command_bytes = @as(u64, program.count) * 4;
    if (overlaps(@intFromPtr(commands), command_bytes, @intFromPtr(request), @sizeOf(c.R4NvCopy)) or
        overlaps(@intFromPtr(written), 4, @intFromPtr(request), @sizeOf(c.R4NvCopy)) or
        overlaps(@intFromPtr(commands), command_bytes, @intFromPtr(written), 4)) return c.status_invalid;
    @memcpy(commands[0..program.count], program.slice());
    written.* = program.count;
    return c.status_ok;
}
