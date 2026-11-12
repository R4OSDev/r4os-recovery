//! Concrete context/callback initialization only; transport and policy stay
//! in the original SDK owners. Job buffers/descriptors remain pinned to join.
const std = @import("std");
const a = @import("r4os_contract").abi;
const program = @import("program.zig");
const web = @import("app_web.zig");
const jobs = @import("app_web_jobs.zig");
const runtime_jobs = @import("web_runtime_jobs.zig");
const cb = @import("web_callback_bridge.zig");
pub const Error = error{MissingCallback};
pub const Context = struct { bundle: program.Bundle, transport: web.WebTransport };
pub fn open(output: *Context, raw: *const a.R4XStartContext) bool {
    output.bundle = program.bundleValueFromR4XStart(raw) orelse return false;
    output.transport = .{ .network = .{ .sys = .init(&output.bundle), .net = .init(&output.bundle) }, .dev = .init(&output.bundle) };
    return true;
}
pub fn transport(self: *Context) *web.WebTransport {
    return &self.transport;
}
pub fn job(output: *jobs.Job, ctx: *const Context) void {
    output.* = .{ .transport = ctx.transport };
}
pub fn requestJob(output: *runtime_jobs.RequestJob, ctx: *const Context, allocator: std.mem.Allocator, request_owner: runtime_jobs.Owner) void {
    output.* = .{ .job = .{ .transport = ctx.transport }, .allocator = allocator, .owner = request_owner };
}
pub fn owner(table: *const cb.Table) Error!runtime_jobs.Owner {
    if (!table.has(.runtime_lookup)) return error.MissingCallback;
    return .{ .context = @ptrCast(@constCast(table)), .find = cb.pointer(@FieldType(runtime_jobs.Owner, "find"), 0, .runtime_lookup) };
}
pub fn fetchCallbacks(options: *web.FetchOptions, table: *const cb.Table) void {
    const ctx: *anyopaque = @ptrCast(@constCast(table));
    options.progress_context = ctx;
    options.cookie_context = ctx;
    options.target_authorization_context = ctx;
    options.progress = if (table.has(.network_progress)) cb.pointer(@typeInfo(@FieldType(web.FetchOptions, "progress")).optional.child, 0, .network_progress) else null;
    options.cookie_provider = if (table.has(.cookie_provider)) cb.pointer(web.CookieProvider, 0, .cookie_provider) else null;
    options.cookie_sink = if (table.has(.cookie_sink)) cb.pointer(web.CookieSink, 0, .cookie_sink) else null;
    options.target_authorizer = if (table.has(.target_authorize)) cb.pointer(web.TargetAuthorizer, 0, .target_authorize) else null;
}
pub fn downloadCallbacks(options: *web.DownloadOptions, table: *const cb.Table) void {
    const ctx: *anyopaque = @ptrCast(@constCast(table));
    options.progress_context = ctx;
    options.target_authorization_context = ctx;
    options.progress = if (table.has(.download_progress)) cb.pointer(web.DownloadProgress, 0, .download_progress) else null;
    options.head_context = ctx;
    options.head_observer = if (table.has(.download_head)) cb.pointer(web.DownloadHeadObserver, 0, .download_head) else null;
    options.target_authorizer = if (table.has(.target_authorize)) cb.pointer(web.TargetAuthorizer, 0, .target_authorize) else null;
}
pub fn sink(table: *const cb.Table) Error!web.DownloadSink {
    if (!table.has(.download_write)) return error.MissingCallback;
    return .{ .context = @ptrCast(@constCast(table)), .write_fn = cb.pointer(web.DownloadWrite, 0, .download_write) };
}
pub fn postStreamCallbacks(options: *web.PostStreamOptions, table: *const cb.Table) void {
    fetchCallbacks(&options.request, table);
    options.reader_context = @ptrCast(@constCast(table));
    options.reader = if (table.has(.post_stream_read)) cb.pointer(web.PostStreamRead, 0, .post_stream_read) else null;
}
pub fn postStreamSink(table: *const cb.Table) Error!web.PostStreamSink {
    if (!table.has(.post_stream_write)) return error.MissingCallback;
    return .{ .context = @ptrCast(@constCast(table)), .write = cb.pointer(web.PostStreamWrite, 0, .post_stream_write) };
}
pub fn postStreamInit(output: *web.PostStream, ctx: *Context, url: []const u8, buffers: web.PostStreamBuffers, stream_sink: web.PostStreamSink, options: web.PostStreamOptions) web.PostStreamReport {
    return output.init(&ctx.transport, url, buffers, stream_sink, options);
}
pub fn postStreamRun(stream: *web.PostStream) web.PostStreamReport {
    return stream.run();
}
pub fn postStreamReport(stream: *const web.PostStream) web.PostStreamReport {
    return stream.report();
}
pub fn postStreamResponse(stream: *const web.PostStream) ?@import("http.zig").Response {
    return stream.response();
}
pub fn postStreamCancel(stream: *web.PostStream) void {
    stream.cancel();
}
pub fn postStreamClose(stream: *web.PostStream, timeout: web.Timeout) bool {
    return stream.close(timeout);
}
pub fn postStreamCanRelease(stream: *const web.PostStream) bool {
    return stream.canRelease();
}
