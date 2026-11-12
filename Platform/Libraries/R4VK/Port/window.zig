// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const a = @import("r4os").abi;
const window = @import("r4native").window;
const application = @import("r4native").application;
pub export fn r4vk_application_snapshot(raw: *const anyopaque, output: *u64) callconv(.c) bool {
    if (!application.bindAddress(@intFromPtr(raw))) return false;
    output.* = (application.snapshot() orelse return false).address();
    return true;
}
pub export fn r4vk_window_query(raw: u64, id: u32, expected: ?*const a.WindowGraphicsSurface, out: *a.WindowGraphicsReply) callconv(.c) i32 {
    return window.query(raw, id, expected, out);
}
pub export fn r4vk_window_request(raw: u64, request: *const a.WindowGraphicsRequest, out: *a.WindowGraphicsReply) callconv(.c) bool {
    return window.request(raw, request, out);
}
pub export fn r4vk_window_service_dead(raw: u64, service: *const a.ProgramProcessHandle) callconv(.c) bool {
    return window.service_dead(raw, service);
}
pub export fn r4vk_window_wait(raw: u64, owner: *const a.ProgramProcessHandle, revision: u64, ns: u64) callconv(.c) void {
    window.wait(raw, owner, revision, ns);
}
