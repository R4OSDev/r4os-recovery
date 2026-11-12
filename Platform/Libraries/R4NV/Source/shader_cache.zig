// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Immutable fixed-program cache. No allocation, compiler, file or GPU access.
const std = @import("std");
const c = @import("r4l_contract");
const profiles = @import("render_profiles.zig");
const Sha256 = std.crypto.hash.sha2.Sha256;
const prefix_bytes = 352;
const header_offset = 224;
const code_offset = c.shader_cache_header_bytes;

comptime {
    for (profiles.catalog) |target| {
    if (target.compiler_abi != c.shader_abi or target.resource_abi != c.shader_resource_abi)
        @compileError("Regenerate the fixed shaders for the current shader/resource ABI");
    for (target.programs) |program| {
        if (program.code.len == 0 or program.code.len % 16 != 0 or program.code.len + code_offset > c.shader_cache_max_bytes)
            @compileError("Fixed shader exceeds the versioned cache bounds");
    }
    }
}
fn span(address: usize, length: usize) bool {
    return address != 0 and length != 0 and length <= std.math.maxInt(usize) - address;
}
fn pointer(comptime T: type, address: usize) bool {
    return address % @alignOf(T) == 0 and span(address, @sizeOf(T));
}
// Only call after checking both ranges for overflow.
fn overlaps(left: usize, left_bytes: usize, right: usize, right_bytes: usize) bool {
    return left < right + right_bytes and right < left + left_bytes;
}
fn nonzero(digest: c.R4NvDigest) bool {
    return digest.word0 | digest.word1 | digest.word2 | digest.word3 != 0;
}
fn validateKey(key: *const c.R4NvShaderKey) i32 {
    if (key.version != 1 or key.size != @sizeOf(c.R4NvShaderKey) or key.device_id == 0 or key.device_id > 0xffff or
        key.input_format == 0 or key.output_format == 0 or key.driver_build == 0 or !nonzero(key.device_uuid) or !nonzero(key.pipeline_state))
        return c.status_invalid;
    const target = profiles.get(key.graphics_class) orelse return c.status_unsupported;
    if (key.vendor_id != 0x10de or key.shader_model != target.sm or
        key.rm_release != c.rm_release or key.command_abi != c.command_abi or key.shader_abi != c.shader_abi or key.resource_abi != c.shader_resource_abi)
        return c.status_unsupported;
    return c.status_ok;
}
fn digestValue(bytes: *const [32]u8) c.R4NvDigest {
    return .{ .word0 = std.mem.readInt(u64, bytes[0..8], .little), .word1 = std.mem.readInt(u64, bytes[8..16], .little),
        .word2 = std.mem.readInt(u64, bytes[16..24], .little), .word3 = std.mem.readInt(u64, bytes[24..32], .little) };
}
fn infoFor(target: profiles.Profile, program: *const profiles.Program) c.R4NvShaderInfo {
    return .{ .version = 1, .size = @sizeOf(c.R4NvShaderInfo), .profile = program.profile, .stage = program.stage,
        .shader_model = target.sm, .registers = program.gprs, .code_bytes = @intCast(program.code.len),
        .instructions = program.instructions, .scratch_bytes = 0, .stack_bytes = 0, .header_bytes = 128,
        .resource_abi = target.resource_abi, .max_warps_per_sm = program.max_warps_per_sm, .reserved = 0,
        .compiler_id = digestValue(&target.compiler_id) };
}
fn put(comptime T: type, bytes: []u8, offset: usize, value: T) void {
    std.mem.writeInt(T, bytes[offset..][0..@sizeOf(T)], value, .little);
}
fn putDigest(bytes: []u8, offset: usize, digest: c.R4NvDigest) void {
    put(u64, bytes, offset, digest.word0); put(u64, bytes, offset + 8, digest.word1);
    put(u64, bytes, offset + 16, digest.word2); put(u64, bytes, offset + 24, digest.word3);
}
// All integers are explicitly little endian. No host pointers or padding are serialized.
fn prefix(target: profiles.Profile, program: *const profiles.Program, key: *const c.R4NvShaderKey) [prefix_bytes]u8 {
    var bytes: [prefix_bytes]u8 = @splat(0);
    @memcpy(bytes[0..8], "R4NVSC01");
    put(u32, &bytes, 8, 1); put(u32, &bytes, 12, code_offset);
    put(u32, &bytes, 16, @intCast(code_offset + program.code.len));
    put(u32, &bytes, 20, program.profile); put(u32, &bytes, 24, @intCast(program.code.len));
    @memcpy(bytes[32..64], &target.compiler_id);
    inline for (std.meta.fields(c.R4NvShaderKey)) |field| {
        const offset = 64 + @offsetOf(c.R4NvShaderKey, field.name);
        if (field.type == c.R4NvDigest) putDigest(&bytes, offset, @field(key, field.name))
        else put(field.type, &bytes, offset, @field(key, field.name));
    }
    for ([_]u32{ program.stage, target.sm, program.gprs, program.instructions,
        program.max_warps_per_sm, 0, 0, target.resource_abi }, 0..) |value, i| put(u32, &bytes, 192 + i * 4, value);
    for (&program.header, 0..) |value, i| put(u32, &bytes, header_offset + i * 4, value);
    return bytes;
}
fn checksum(head: []const u8, code: []const u8) [32]u8 {
    var hash = Sha256.init(.{});
    hash.update(head); hash.update(code);
    return hash.finalResult();
}

pub fn r4nv_shader_info_impl(profile: u32, output: *c.R4NvShaderInfo) callconv(.c) i32 {
    if (!pointer(c.R4NvShaderInfo, @intFromPtr(output))) return c.status_invalid;
    // Original keyless ABI reports its original SM86 profile. Keyed cache
    // operations select the complete target and return that target's info.
    const target = profiles.get(c.shader_graphics_class_ampere_b).?;
    const program = target.program(profile) orelse return c.status_unsupported;
    output.* = infoFor(target, program);
    return c.status_ok;
}
pub fn r4nv_shader_cache_write_impl(profile: u32, key: *const c.R4NvShaderKey, bytes: [*]u8, capacity: u32, written: *u32) callconv(.c) i32 {
    if (!pointer(c.R4NvShaderKey, @intFromPtr(key)) or !pointer(u32, @intFromPtr(written)) or @intFromPtr(bytes) == 0)
        return c.status_invalid;
    const valid = validateKey(key);
    if (valid != c.status_ok) return valid;
    const target = profiles.get(key.graphics_class).?;
    const program = target.program(profile) orelse return c.status_unsupported;
    const total = code_offset + program.code.len;
    if (capacity < total) return c.status_capacity;
    if (!span(@intFromPtr(bytes), capacity) or
        overlaps(@intFromPtr(bytes), capacity, @intFromPtr(key), @sizeOf(c.R4NvShaderKey)) or
        overlaps(@intFromPtr(bytes), capacity, @intFromPtr(written), 4) or
        overlaps(@intFromPtr(written), 4, @intFromPtr(key), @sizeOf(c.R4NvShaderKey))) return c.status_invalid;
    const head = prefix(target, program, key);
    const digest = checksum(&head, program.code);
    @memcpy(bytes[0..prefix_bytes], &head);
    @memcpy(bytes[prefix_bytes..code_offset], &digest);
    @memcpy(bytes[code_offset..total], program.code);
    written.* = @intCast(total);
    return c.status_ok;
}
pub fn r4nv_shader_cache_read_impl(key: *const c.R4NvShaderKey, bytes: [*]const u8, length: u32, output: *c.R4NvShaderView) callconv(.c) i32 {
    if (!pointer(c.R4NvShaderKey, @intFromPtr(key)) or !pointer(c.R4NvShaderView, @intFromPtr(output)) or @intFromPtr(bytes) == 0)
        return c.status_invalid;
    const valid = validateKey(key);
    if (valid != c.status_ok) return valid;
    if (length < code_offset or length > c.shader_cache_max_bytes) return c.status_cache_miss;
    if (!span(@intFromPtr(bytes), length) or
        overlaps(@intFromPtr(output), @sizeOf(c.R4NvShaderView), @intFromPtr(key), @sizeOf(c.R4NvShaderKey)) or
        overlaps(@intFromPtr(output), @sizeOf(c.R4NvShaderView), @intFromPtr(bytes), length)) return c.status_invalid;
    const profile = std.mem.readInt(u32, bytes[20..24], .little);
    const target = profiles.get(key.graphics_class).?;
    const program = target.program(profile) orelse return c.status_cache_miss;
    if (length != code_offset + program.code.len) return c.status_cache_miss;
    const expected = prefix(target, program, key);
    if (!std.mem.eql(u8, &expected, bytes[0..prefix_bytes]) or !std.mem.eql(u8, program.code, bytes[code_offset..length]))
        return c.status_cache_miss;
    const digest = checksum(bytes[0..prefix_bytes], bytes[code_offset..length]);
    if (!std.mem.eql(u8, &digest, bytes[prefix_bytes..code_offset])) return c.status_cache_miss;
    output.* = .{ .info = infoFor(target, program), .header_address = @intFromPtr(bytes + header_offset), .code_address = @intFromPtr(bytes + code_offset) };
    return c.status_ok;
}
