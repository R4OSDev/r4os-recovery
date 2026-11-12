// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const c = @import("r4l_contract");
const shared = @import("r4cache_codec");
pub const max_code_bytes = 16 * 1024 * 1024;
// The native build hashes the complete source/toolchain/port input closure.
extern fn r4aco_native_identity() callconv(.c) *const [32]u8;

pub fn span(address: usize, size: usize) bool {
    return shared.validSpan(address, size);
}
pub fn overlaps(a: usize, a_size: usize, b: usize, b_size: usize) bool {
    return shared.overlaps(a, a_size, b, b_size);
}
fn nonzero(d: c.R4AcoDigest) bool {
    return d.h0 | d.h1 | d.h2 | d.h3 != 0;
}
fn validKey(key: *const c.R4AcoCacheKey) bool {
    return key.version == 1 and key.size == @sizeOf(c.R4AcoCacheKey) and key.vendor_id == 0x1002 and
        key.gfx_profile == (@import("gpu_profile.zig").select(key.device_id, key.chip_revision) orelse return false) and
        (key.stage == 0 or key.stage == 4 or key.stage == 5) and (key.resource_abi == 1 or key.resource_abi == 2) and
        key.driver_version != 0 and key.command_abi != 0 and key.reserved == 0 and
        (key.stage == 5 or key.format != 0) and key.device_generation != 0 and key.reset_generation != 0 and key.pipeline_layout != 0 and
        nonzero(key.source_hash) and nonzero(key.pipeline_hash);
}
fn validBinary(key: *const c.R4AcoCacheKey, binary: *const c.R4AcoBinary, bytes: usize) bool {
    if (!(binary.version == 1 and binary.size == @sizeOf(c.R4AcoBinary) and binary.status == 0 and binary.reserved == 0 and
        binary.device_id == key.device_id and binary.chip_revision == key.chip_revision and binary.stage == key.stage and
        binary.gfx_profile == key.gfx_profile and binary.resource_abi == key.resource_abi and binary.sgprs >= 16 and binary.sgprs <= 112 and binary.sgprs % 16 == 0 and
        binary.vgprs >= 4 and binary.vgprs <= 256 and binary.vgprs % 4 == 0 and binary.lds_bytes <= 65536 and
        binary.scratch_bytes_per_wave <= 64 * 1024 * 1024 and binary.float_mode <= 255 and
        bytes > 0 and bytes <= max_code_bytes and bytes % 4 == 0 and binary.code_bytes == bytes and
        binary.exec_bytes != 0 and binary.exec_bytes <= bytes and binary.exec_bytes % 4 == 0 and binary.symbol_count <= 32 and
        std.meta.eql(binary.source_hash, key.source_hash))) return false;
    if (binary.stage == 5) {
        if (binary.workgroup_x == 0 or binary.workgroup_x > 1024 or binary.workgroup_y == 0 or binary.workgroup_y > 1024 or
            binary.workgroup_z == 0 or binary.workgroup_z > 1024 or
            @as(u64, binary.workgroup_x) * binary.workgroup_y * binary.workgroup_z > 1024 or
            binary.user_sgprs != 9 or binary.input_vgprs != 3 or binary.spi_ps_input_ena != 0 or
            binary.spi_ps_input_addr != 0 or binary.spi_shader_col_format != 0) return false;
    } else {
        if (binary.workgroup_x != 0 or binary.workgroup_y != 0 or binary.workgroup_z != 0 or binary.lds_bytes != 0) return false;
        if (binary.stage == 0) {
            if (binary.user_sgprs != 9 or binary.input_vgprs != 4 or binary.spi_ps_input_ena != 0 or
                binary.spi_ps_input_addr != 0 or binary.spi_shader_col_format != 0) return false;
        } else if (binary.user_sgprs != 6 or binary.input_vgprs != 24 or binary.spi_ps_input_ena != 0xffff or
            binary.spi_ps_input_addr != 0xffff or binary.spi_shader_col_format != 9) return false;
    }
    const symbols: *const [32]u64 = @ptrCast(&binary.symbols);
    for (symbols, 0..) |symbol, i| {
        if (i >= binary.symbol_count) {
            if (symbol != 0) return false;
            continue;
        }
        const kind: u32 = @truncate(symbol);
        const offset = symbol >> 32;
        if (kind < 1 or kind > 3 or offset >= binary.exec_bytes / 4) return false;
        for (symbols[0..i]) |previous| if (previous >> 32 == offset) return false;
    }
    return true;
}
// Shared format mechanics; these actual vendor predicates/identity stay local.
const CachePolicy = struct {
    pub const magic = "R4ACOC01".*;
    pub const format_revision: u32 = 1;
    pub const compiler_revision = c.compiler_revision;
    pub const max_payload_bytes = max_code_bytes;
    pub const transient_fields: []const []const u8 = &.{ "peak_bytes", "elapsed_ns", "log_length" };
    pub const valid_key = validKey;
    pub const valid_metadata = validBinary;
    pub fn compilerIdentity() [32]u8 {
        return r4aco_native_identity().*;
    }
};
const Codec = shared.CanonicalCacheEnvelope(c.R4AcoCacheKey, c.R4AcoBinary, CachePolicy);
pub const code_offset = Codec.payload_offset;
pub export fn r4aco_cache_write_impl(key: *const c.R4AcoCacheKey, binary: *const c.R4AcoBinary, code: [*]const u8, code_length: u64, bytes: [*]u8, capacity: u64, written: *u64) callconv(.c) i32 {
    _ = Codec.encode(key, binary, code, code_length, bytes, capacity, written) catch |err| return if (err == error.Capacity) c.status_capacity else c.status_invalid;
    return c.status_ok;
}
pub export fn r4aco_cache_read_impl(key: *const c.R4AcoCacheKey, bytes: [*]const u8, length: u64, output: *c.R4AcoBinary, code: [*]u8, capacity: u64) callconv(.c) i32 {
    _ = Codec.decode(key, bytes, length, output, code, capacity) catch |err| return switch (err) {
        error.Capacity => c.status_capacity,
        error.InvalidArgument, error.Overflow, error.Overlap => c.status_invalid,
        else => c.status_cache_miss,
    };
    return c.status_ok;
}
