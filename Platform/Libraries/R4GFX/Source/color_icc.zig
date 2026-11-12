//! RGB ICC v2/v4 transforms, including LUT profiles, via the pinned LittleCMS
//! core. A profile's explicit intent is checked; no matrix-only substitution.
const std = @import("std");
comptime {
    _ = @import("color_c.zig");
}
pub const max_profile_bytes = 4 * 1024 * 1024;
pub const max_arena_bytes = 64 * 1024 * 1024;
pub const max_profile_tags = 100; // Exact capacity of the pinned ICC engine.
pub const Error = error{ Invalid, Unsupported, Memory, Alias, NonFinite };
pub const Direction = enum(u32) { input = 0, output = 1 };
pub const Intent = enum(u32) { perceptual = 0, relative = 1, saturation = 2, absolute = 3 };
pub const Arena = struct {
    bytes: []align(16) u8,
    used: usize = 0,
    failed: bool = false,
    error_code: u32 = 0,
    generation: u64 = 0,
    active: ?*anyopaque = null,
    pub fn init(bytes: []align(16) u8) Error!Arena {
        if (bytes.len < 1024 or bytes.len > max_arena_bytes) return error.Invalid;
        return .{ .bytes = bytes };
    }
    fn allocate(self: *Arena, count: usize) ?*anyopaque {
        if (count == 0) return null;
        const size = std.mem.alignForward(usize, count, 16);
        if (size > self.bytes.len - self.used or 16 > self.bytes.len - self.used - size) {
            self.failed = true;
            return null;
        }
        const header = self.bytes[self.used..][0..16];
        std.mem.writeInt(u64, header[0..8], count, .little);
        std.mem.writeInt(u64, header[8..16], @intFromPtr(self), .little);
        const data = self.bytes.ptr + self.used + 16;
        self.used += size + 16;
        return data;
    }
};
fn arena(context: ?*anyopaque) ?*Arena {
    const ptr = context orelse return null;
    return @ptrCast(@alignCast(ptr));
}
export fn r4gfx_icc_alloc(context: ?*anyopaque, count: u32) callconv(.c) ?*anyopaque {
    const owner = arena(context) orelse return null;
    return owner.allocate(count);
}
export fn r4gfx_icc_realloc(context: ?*anyopaque, previous: ?*anyopaque, count: u32) callconv(.c) ?*anyopaque {
    const owner = arena(context) orelse return null;
    const old = previous orelse return owner.allocate(count);
    const start = @intFromPtr(owner.bytes.ptr);
    const address = @intFromPtr(old);
    if (address < start + 16 or address >= start + owner.used) return null;
    const header: *const [16]u8 = @ptrFromInt(address - 16);
    if (std.mem.readInt(u64, header[8..16], .little) != @intFromPtr(owner)) return null;
    const old_size = std.mem.readInt(u64, header[0..8], .little);
    if (old_size > start + owner.used - address) return null;
    const next = owner.allocate(count) orelse return null;
    const to: [*]u8 = @ptrCast(next);
    const from: [*]const u8 = @ptrCast(old);
    @memcpy(to[0..@min(old_size, count)], from[0..@min(old_size, count)]);
    return next;
}
export fn r4gfx_icc_error(context: ?*anyopaque, code: u32) callconv(.c) void {
    const owner = arena(context) orelse return;
    if (owner.error_code == 0) owner.error_code = code;
}
extern fn r4gfx_icc_open(*Arena, [*]const u8, u32, u32, u32, u32, u32, *?*anyopaque) callconv(.c) c_int;
extern fn r4gfx_icc_close(?*anyopaque) callconv(.c) void;
extern fn r4gfx_icc_apply(*anyopaque, [*]const f32, [*]f32, u32) callconv(.c) c_int;
extern fn r4gfx_icc_builtin(*Arena, u32, ?[*]u8, *u32) callconv(.c) c_int;
extern fn r4gfx_icc_generate(*Arena, u32, u32, *const [11]f64, [*]u8, *u32) callconv(.c) c_int;
fn overlaps(left: usize, n: usize, right: usize, m: usize) bool {
    return n != 0 and m != 0 and left < right +| m and right < left +| n;
}
const Tag = struct { signature: u32, offset: usize, size: usize };
fn tag(bytes: []const u8, index: usize) Tag {
    const record = bytes[132 + index * 12 ..][0..12];
    return .{ .signature = std.mem.readInt(u32, record[0..4], .big), .offset = std.mem.readInt(u32, record[4..8], .big), .size = std.mem.readInt(u32, record[8..12], .big) };
}
fn validateProfile(bytes: []const u8) Error!void {
    if (bytes.len < 132 or bytes.len > max_profile_bytes or std.mem.readInt(u32, bytes[0..4], .big) != bytes.len or
        !std.mem.eql(u8, bytes[36..40], "acsp") or (bytes[8] != 2 and bytes[8] != 4)) return error.Invalid;
    const count = std.mem.readInt(u32, bytes[128..132], .big);
    if (count == 0) return error.Invalid;
    if (count > max_profile_tags) return error.Unsupported;
    const table_end = 132 + @as(usize, count) * 12;
    if (table_end > bytes.len) return error.Invalid;
    for (0..count) |i| {
        const item = tag(bytes, i);
        if (item.offset < table_end or item.offset % 4 != 0 or item.offset > bytes.len or
            item.size < 8 or item.size > bytes.len - item.offset) return error.Invalid;
        for (0..i) |j| {
            const prior = tag(bytes, j);
            if (item.signature == prior.signature) return error.Invalid;
            if (item.offset == prior.offset and item.size == prior.size) continue;
            if (overlaps(item.offset, item.size, prior.offset, prior.size)) return error.Invalid;
        }
    }
    // ICC4.4 requires contiguous unique tag elements, with zero padding.
    // Older versions retain their historical layout allowance.
    if (bytes[8] == 4 and bytes[9] >= 0x40) {
        var next = table_end;
        while (next < bytes.len) {
            var found: ?Tag = null;
            for (0..count) |i| {
                const item = tag(bytes, i);
                if (item.offset == next) {
                    found = item;
                    break;
                }
            }
            const item = found orelse return error.Invalid;
            const end = item.offset + item.size;
            next = std.mem.alignForward(usize, end, 4);
            if (next > bytes.len or !std.mem.allEqual(u8, bytes[end..next], 0)) return error.Invalid;
        }
    }
}

pub const Profile = struct {
    handle: ?*anyopaque = null,
    memory: *Arena,
    generation: u64 = 0,
    pub fn open(memory: *Arena, bytes: []const u8, direction: Direction, intent: Intent, black_compensation: bool, calibration: bool) Error!Profile {
        if (bytes.len < 132 or bytes.len > max_profile_bytes or memory.used != 0 or memory.active != null or (calibration and direction != .output)) return error.Invalid;
        if (overlaps(@intFromPtr(bytes.ptr), bytes.len, @intFromPtr(memory.bytes.ptr), memory.bytes.len) or
            overlaps(@intFromPtr(bytes.ptr), bytes.len, @intFromPtr(memory), @sizeOf(Arena)) or
            overlaps(@intFromPtr(memory), @sizeOf(Arena), @intFromPtr(memory.bytes.ptr), memory.bytes.len)) return error.Alias;
        // The ICC engine deliberately skips some invalid optional entries.
        // Output policy must not silently accept a structurally broken profile.
        try validateProfile(bytes);
        memory.generation = std.math.add(u64, memory.generation, 1) catch return error.Invalid;
        memory.failed = false;
        memory.error_code = 0;
        // The source is copied before LCMS retains its memory I/O handler.
        const copy: [*]u8 = @ptrCast(memory.allocate(bytes.len) orelse return error.Memory);
        @memcpy(copy[0..bytes.len], bytes);
        var result: Profile = .{ .memory = memory, .generation = memory.generation };
        const rc = r4gfx_icc_open(memory, copy, @intCast(bytes.len), @intFromEnum(direction), @intFromEnum(intent), @intFromBool(black_compensation), @intFromBool(calibration), &result.handle);
        if (rc != 0) {
            memory.used = 0;
            return if (memory.failed) error.Memory else error.Unsupported;
        }
        memory.active = result.handle;
        return result;
    }
    pub fn close(self: *Profile) void {
        const handle = self.handle orelse return;
        if (self.generation != self.memory.generation or self.memory.active != handle) {
            self.handle = null;
            return;
        }
        r4gfx_icc_close(handle);
        self.handle = null;
        self.memory.active = null;
        self.memory.used = 0;
    }
    // Float triplets are encoded RGB on the device side and relative XYZ(D50)
    // on the PCS side. The caller owns alpha, luminance scaling and composition.
    pub fn apply(self: *const Profile, input: []const [3]f32, output: [][3]f32) Error!void {
        const handle = self.handle orelse return error.Invalid;
        if (self.generation != self.memory.generation or self.memory.active != handle) return error.Invalid;
        if (input.len != output.len or input.len > 16 * 1024 * 1024) return error.Invalid;
        const in_bytes = std.mem.sliceAsBytes(input);
        const out_bytes = std.mem.sliceAsBytes(output);
        if (overlaps(@intFromPtr(out_bytes.ptr), out_bytes.len, @intFromPtr(in_bytes.ptr), in_bytes.len) or
            overlaps(@intFromPtr(out_bytes.ptr), out_bytes.len, @intFromPtr(self.memory.bytes.ptr), self.memory.bytes.len) or
            overlaps(@intFromPtr(out_bytes.ptr), out_bytes.len, @intFromPtr(self), @sizeOf(Profile)) or
            overlaps(@intFromPtr(out_bytes.ptr), out_bytes.len, @intFromPtr(self.memory), @sizeOf(Arena))) return error.Alias;
        for (input) |rgb| for (rgb) |v| if (!std.math.isFinite(v)) return error.NonFinite;
        if (r4gfx_icc_apply(handle, @ptrCast(input.ptr), @ptrCast(output.ptr), @intCast(input.len)) != 0) return error.Invalid;
        // Complex profile elements can overflow even for finite RGB. Never
        // publish a successful transform containing NaN/Inf to quantizers.
        for (output) |rgb| for (rgb) |v| if (!std.math.isFinite(v)) return error.NonFinite;
    }
};
pub const Definition = struct {
    chromaticities: @import("color.zig").Chromaticities,
    gamma: [3]f64 = @splat(1), // Device -> linear decoding exponents.
    gray: bool = false,
    srgb_curve: bool = false,
};
pub fn generate(memory: *Arena, definition: Definition, output: []u8) Error!usize {
    if (memory.used != 0 or memory.active != null or output.len < 132 or output.len > max_profile_bytes) return error.Invalid;
    if (overlaps(@intFromPtr(output.ptr), output.len, @intFromPtr(memory.bytes.ptr), memory.bytes.len) or
        overlaps(@intFromPtr(output.ptr), output.len, @intFromPtr(memory), @sizeOf(Arena)) or
        overlaps(@intFromPtr(memory), @sizeOf(Arena), @intFromPtr(memory.bytes.ptr), memory.bytes.len)) return error.Alias;
    const chroma = definition.chromaticities;
    if (!definition.gray) {
        _ = chroma.xyz() catch return error.Invalid;
    } else if (!std.math.isFinite(chroma.white[0]) or !std.math.isFinite(chroma.white[1]) or
        chroma.white[0] <= 0 or chroma.white[1] <= 0 or chroma.white[0] + chroma.white[1] >= 1) return error.Invalid;
    for (definition.gamma) |value| if (!std.math.isFinite(value) or value < 0.01 or value > 100) return error.Invalid;
    const values = [11]f64{ chroma.white[0], chroma.white[1], chroma.red[0], chroma.red[1], chroma.green[0], chroma.green[1], chroma.blue[0], chroma.blue[1], definition.gamma[0], definition.gamma[1], definition.gamma[2] };
    memory.failed = false;
    memory.error_code = 0;
    defer memory.used = 0;
    var size: u32 = @intCast(output.len);
    if (r4gfx_icc_generate(memory, @intFromBool(definition.gray), @intFromBool(definition.srgb_curve), &values, output.ptr, &size) != 0) return if (memory.failed) error.Memory else error.Unsupported;
    return size;
}
pub fn builtin(memory: *Arena, kind: u32, output: []u8) Error!usize {
    if (memory.used != 0 or memory.active != null or output.len > max_profile_bytes or kind > 2) return error.Invalid;
    if (overlaps(@intFromPtr(output.ptr), output.len, @intFromPtr(memory.bytes.ptr), memory.bytes.len) or
        overlaps(@intFromPtr(output.ptr), output.len, @intFromPtr(memory), @sizeOf(Arena)) or
        overlaps(@intFromPtr(memory), @sizeOf(Arena), @intFromPtr(memory.bytes.ptr), memory.bytes.len)) return error.Alias;
    memory.failed = false;
    memory.error_code = 0;
    defer memory.used = 0;
    var size: u32 = @intCast(output.len);
    if (r4gfx_icc_builtin(memory, kind, output.ptr, &size) != 0) return if (memory.failed) error.Memory else error.Unsupported;
    return size;
}
