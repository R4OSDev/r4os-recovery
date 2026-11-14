// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r = @import("r4os");
const c = @import("r4l_contract");
const ff = @cImport({
    @cInclude("codec.h");
    @cInclude("nvdec.h");
    @cInclude("pthread.h");
});
const engine = @import("engine.zig").Implementation(ff);
export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}
pub export fn r4video_open_impl(input: *const c.R4VideoStartup, output: *c.R4VideoRuntime) callconv(.c) i32 {
    return engine.open(input, output);
}
pub export fn r4video_query_caps_impl(handle: *const c.R4VideoRuntime, input: *const c.R4VideoCapsQuery, output: *c.R4VideoCaps) callconv(.c) i32 {
    return engine.queryCaps(handle, input, output);
}
pub export fn r4video_create_impl(handle: *const c.R4VideoRuntime, input: *const c.R4VideoConfig, output: *c.R4VideoDecoder) callconv(.c) i32 {
    return engine.create(handle, input, output);
}
pub export fn r4video_send_impl(handle: *const c.R4VideoDecoder, input: *const c.R4VideoPacket) callconv(.c) i32 {
    return engine.send(handle, input);
}
pub export fn r4video_receive_impl(handle: *const c.R4VideoDecoder, output: *c.R4VideoFrame) callconv(.c) i32 {
    return engine.receive(handle, output);
}
pub export fn r4video_release_impl(lease: *const c.R4VideoLease, receipt: *const c.R4VideoReceipt) callconv(.c) i32 {
    return engine.release(lease, receipt);
}
pub export fn r4video_control_impl(handle: *const c.R4VideoDecoder, input: *const c.R4VideoControl, output: *c.R4VideoState) callconv(.c) i32 {
    return engine.control(handle, input, output);
}
pub export fn r4video_destroy_impl(handle: *const c.R4VideoDecoder) callconv(.c) i32 {
    return engine.destroy(handle);
}
pub export fn r4video_finish_impl(handle: *const c.R4VideoRuntime, timeout_ns: u64) callconv(.c) i32 {
    return engine.finish(handle, timeout_ns);
}
pub export var r4video_video_v1: c.VideoV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.video_v1_header,
    .open = r4video_open_impl,
    .query_caps = r4video_query_caps_impl,
    .create = r4video_create_impl,
    .send = r4video_send_impl,
    .receive = r4video_receive_impl,
    .release = r4video_release_impl,
    .control = r4video_control_impl,
    .destroy = r4video_destroy_impl,
    .finish = r4video_finish_impl,
};
// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4video_query2: r.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
