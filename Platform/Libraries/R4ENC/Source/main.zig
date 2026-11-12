// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r = @import("r4os");
const c = @import("r4l_contract");
const ff = @cImport({
    @cInclude("codec.h");
    @cInclude("vcn_encode.h");
});
const engine = @import("engine.zig").Implementation(ff);
export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}
pub export fn r4enc_open_impl(input: *const c.R4EncStartup, output: *c.R4EncRuntime) callconv(.c) i32 {
    return engine.open(input, output);
}
pub export fn r4enc_query_caps_impl(handle: *const c.R4EncRuntime, input: *const c.R4EncCapsQuery, output: *c.R4EncCaps) callconv(.c) i32 {
    return engine.queryCaps(handle, input, output);
}
pub export fn r4enc_create_impl(handle: *const c.R4EncRuntime, input: *const c.R4EncConfig, output: *c.R4EncEncoder) callconv(.c) i32 {
    return engine.create(handle, input, output);
}
pub export fn r4enc_send_impl(handle: *const c.R4EncEncoder, input: *const c.R4EncFrame) callconv(.c) i32 {
    return engine.send(handle, input);
}
pub export fn r4enc_receive_impl(handle: *const c.R4EncEncoder, output: *c.R4EncPacket) callconv(.c) i32 {
    return engine.receive(handle, output);
}
pub export fn r4enc_release_impl(lease: *const c.R4EncLease) callconv(.c) i32 {
    return engine.release(lease);
}
pub export fn r4enc_control_impl(handle: *const c.R4EncEncoder, input: *const c.R4EncControl, output: *c.R4EncState) callconv(.c) i32 {
    return engine.control(handle, input, output);
}
pub export fn r4enc_destroy_impl(handle: *const c.R4EncEncoder) callconv(.c) i32 {
    return engine.destroy(handle);
}
pub export fn r4enc_finish_impl(handle: *const c.R4EncRuntime, timeout_ns: u64) callconv(.c) i32 {
    return engine.finish(handle, timeout_ns);
}
pub export var r4enc_encode_v1: c.EncodeV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.encode_v1_header,
    .open = r4enc_open_impl,
    .query_caps = r4enc_query_caps_impl,
    .create = r4enc_create_impl,
    .send = r4enc_send_impl,
    .receive = r4enc_receive_impl,
    .release = r4enc_release_impl,
    .control = r4enc_control_impl,
    .destroy = r4enc_destroy_impl,
    .finish = r4enc_finish_impl,
};
pub export var r4enc_query: r.abi.R4LQuery align(8) linksection(".data.r4l_exports") = .{
    .magic = r.abi.r4l_abi_magic,
    .abi_version = r.abi.r4l_abi_version,
    .size = r.abi.r4l_query_struct_size,
    .group = 0,
    .kernel_bridge = 0,
    .reserved = 0,
};

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4enc_query2: r.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
