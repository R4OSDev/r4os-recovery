// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r = @import("r4os");
const c = @import("r4l_contract");
const runtime = @import("runtime");
export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}
extern fn eglGetProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque;
fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return if (runtime.ready()) eglGetProcAddress(name) else null;
}
pub export fn r4gl_open_impl(input: *const c.R4GlRuntime, output: *c.R4GlLoader) callconv(.c) i32 {
    if (input.version != 1 or input.size < @sizeOf(c.R4GlRuntime) or input.profile > 1 or input.reserved != 0 or
        input.application == 0 or input.application % 8 != 0) return c.error_initialization;
    if (!runtime.bind(input.application, input.profile)) return c.error_initialization;
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GlLoader), .get_proc_address = @intFromPtr(&getProcAddress) };
    return c.success;
}
pub export fn r4gl_release_thread_impl() callconv(.c) i32 {
    return if (runtime.releaseThread()) c.success else c.error_busy;
}
pub export fn r4gl_finish_impl(timeout_ns: u64) callconv(.c) i32 {
    return runtime.finish(timeout_ns);
}
pub export var r4gl_egl_v1: c.EglV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.egl_v1_header,
    .open = r4gl_open_impl,
    .release_thread = r4gl_release_thread_impl,
    .finish = r4gl_finish_impl,
};
// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4gl_query2: r.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
