// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r4os = @import("r4os");
const c = @import("r4l_contract");
export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}
pub const r4nak_compile_impl = @import("runtime.zig").r4nak_compile_impl;
pub const r4nak_cache_write_impl = @import("cache.zig").r4nak_cache_write_impl;
pub const r4nak_cache_read_impl = @import("cache.zig").r4nak_cache_read_impl;
extern fn r4nak_native_format(u32, *c.R4NakFormat) callconv(.c) i32;
pub export fn r4nak_format_info_impl(format: u32, output: *c.R4NakFormat) callconv(.c) i32 {
    return r4nak_native_format(format, output);
}
pub export var r4nak_compiler_v1: c.CompilerV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.compiler_v1_header,
    .compile = r4nak_compile_impl,
    .cache_write = r4nak_cache_write_impl,
    .cache_read = r4nak_cache_read_impl,
    .format_info = r4nak_format_info_impl,
};
// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4nak_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
