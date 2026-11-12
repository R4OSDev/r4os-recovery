// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r4os = @import("r4os");
const c = @import("r4l_contract");

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}

pub export fn r4aco_get_info_impl(output: *c.R4AcoInfo, output_bytes: u32) callconv(.c) i32 {
    if (output_bytes < @sizeOf(c.R4AcoInfo)) return c.status_invalid;
    output.* = .{
        .version = c.info_version,
        .size = @sizeOf(c.R4AcoInfo),
        .mesa_major = 26,
        .mesa_minor = 2,
        .mesa_patch = 2,
        .implementation_stage = 14,
        .capability_flags = c.capability_cpu_compile,
        .reserved = 0,
    };
    return c.status_ok;
}

pub export var r4aco_info_v1: c.InfoV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.info_v1_header,
    .get_info = r4aco_get_info_impl,
};

pub const r4aco_compile_impl = @import("runtime.zig").r4aco_compile_impl;
pub const r4aco_cache_write_impl = @import("cache.zig").r4aco_cache_write_impl;
pub const r4aco_cache_read_impl = @import("cache.zig").r4aco_cache_read_impl;
pub export var r4aco_compiler_v1: c.CompilerV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.compiler_v1_header,
    .compile = r4aco_compile_impl,
    .cache_write = r4aco_cache_write_impl,
    .cache_read = r4aco_cache_read_impl,
};

pub export var r4aco_query: r4os.abi.R4LQuery align(8) linksection(".data.r4l_exports") = .{
    .magic = r4os.abi.r4l_abi_magic,
    .abi_version = r4os.abi.r4l_abi_version,
    .size = r4os.abi.r4l_query_struct_size,
    .group = 0,
    .kernel_bridge = 0,
    .reserved = 0,
};

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4aco_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
