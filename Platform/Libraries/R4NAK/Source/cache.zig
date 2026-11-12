// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const c = @import("r4l_contract");
const shared = @import("r4cache_codec");
const Sha256 = std.crypto.hash.sha2.Sha256;
pub const max_code_bytes = 16 * 1024 * 1024;
const compiler_id = blk: {
    @setEvalBranchQuota(10000);
    var value: [32]u8 = undefined;
    Sha256.hash("Mesa26.2.2:55b1234c8653dad9b85ba3de7b777a0d957909baf4628f0c00e21d4ba89c004cb687a1dcf8da46ed0a092231dd4f859027509f83ad8c558750845ba470902615;Rust1.85.1;R4NAK-port1;constants4", &value, .{});
    break :blk value;
};
pub fn span(address: usize, size: usize) bool {
    return shared.validSpan(address, size);
}
pub fn overlaps(a: usize, a_size: usize, b: usize, b_size: usize) bool {
    return shared.overlaps(a, a_size, b, b_size);
}
fn nonzero(d: c.R4NakDigest) bool {
    return d.h0 | d.h1 | d.h2 | d.h3 != 0;
}
fn validKey(key: *const c.R4NakCacheKey) bool {
    return key.version == 1 and key.size == @sizeOf(c.R4NakCacheKey) and key.vendor_id == 0x10de and
        key.device_id != 0 and key.device_id <= 0xffff and key.chipset != 0 and
        (key.sm == 75 or key.sm == 86 or key.sm == 89 or key.sm == 120) and
        (key.stage == 0 or key.stage == 4 or key.stage == 5) and
        key.driver_version != 0 and key.command_abi != 0 and key.resource_abi != 0 and key.constants_abi == 4 and
        key.format != 0 and key.device_generation != 0 and key.reset_generation != 0 and key.pipeline_layout != 0 and
        nonzero(key.source_hash) and nonzero(key.pipeline_hash);
}
fn validBinary(key: *const c.R4NakCacheKey, binary: *const c.R4NakBinary, bytes: usize) bool {
    return binary.version == 1 and binary.size == @sizeOf(c.R4NakBinary) and binary.status == 0 and
        binary.sm == key.sm and binary.stage == key.stage and
        binary.gprs >= 4 and binary.gprs <= 255 and binary.max_warps != 0 and
        bytes > 0 and bytes <= max_code_bytes and bytes % 16 == 0 and binary.code_bytes == bytes and
        binary.instructions != 0 and binary.instructions <= bytes / 16 and
        std.meta.eql(binary.source_hash, key.source_hash);
}
// Shared format mechanics; these actual vendor predicates/identity stay local.
const CachePolicy = struct {
    pub const magic = "R4NAKC01".*;
    pub const format_revision: u32 = 1;
    pub const compiler_revision = c.compiler_revision;
    pub const max_payload_bytes = max_code_bytes;
    pub const transient_fields: []const []const u8 = &.{ "peak_bytes", "elapsed_ns", "log_length" };
    pub const valid_key = validKey;
    pub const valid_metadata = validBinary;
    pub fn compilerIdentity() [32]u8 {
        return compiler_id;
    }
};
const Codec = shared.CanonicalCacheEnvelope(c.R4NakCacheKey, c.R4NakBinary, CachePolicy);
pub const code_offset = Codec.payload_offset;
pub export fn r4nak_cache_write_impl(key: *const c.R4NakCacheKey, binary: *const c.R4NakBinary, code: [*]const u8, code_length: u64, bytes: [*]u8, capacity: u64, written: *u64) callconv(.c) i32 {
    _ = Codec.encode(key, binary, code, code_length, bytes, capacity, written) catch |err| return if (err == error.Capacity) c.status_capacity else c.status_invalid;
    return c.status_ok;
}
pub export fn r4nak_cache_read_impl(key: *const c.R4NakCacheKey, bytes: [*]const u8, length: u64, output: *c.R4NakBinary, code: [*]u8, capacity: u64) callconv(.c) i32 {
    _ = Codec.decode(key, bytes, length, output, code, capacity) catch |err| return switch (err) {
        error.Capacity => c.status_capacity,
        error.InvalidArgument, error.Overflow, error.Overlap => c.status_invalid,
        else => c.status_cache_miss,
    };
    return c.status_ok;
}
