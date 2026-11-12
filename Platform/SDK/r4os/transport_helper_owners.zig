//! Current transport/job owners; existing document/data types remain shared.
const std = @import("std");
pub const web = @import("app_web.zig");
pub const http = @import("http.zig");
pub const security = @import("web_security.zig");
pub const cache = @import("web_response_cache.zig");
pub const jobs = @import("app_web_jobs.zig");
pub const runtime_jobs = @import("web_runtime_jobs.zig");
pub const resources = @import("web_resources.zig");
pub const documents = @import("web_documents.zig");
pub const fetch = @import("web_fetch.zig");
pub const callbacks = @import("web_callback_bridge.zig");
pub const adapters = @import("transport_helper_adapters.zig");
pub const shared = @import("web_bridge_schema.zig");
pub const modules = .{ web, http, security, cache, jobs, runtime_jobs, resources, documents, fetch, adapters };
pub fn sharedType(comptime T: type) bool {
    if (T == std.mem.Allocator or T == std.heap.FixedBufferAllocator) return true;
    inline for (shared.types) |V| if (T == V) return true;
    return false;
}
pub fn moduleType(comptime T: type) bool {
    if (T == @This() or T == callbacks.Slot) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return false;
}
pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    if (T == adapters.Context or T == web.PostStream) return true;
    const name = @typeName(T);
    inline for (.{ "array_list.", "hash_map.", "mem.Allocator", "heap.", "atomic.", "crypto.", "program.", "r4sys.", "r4net.", "r4dev.", "Io.", "std." }) |prefix| if (std.mem.startsWith(u8, name, prefix)) return true;
    return false;
}
pub const callbackTypes = .{ web.CookieProvider, web.CookieSink, web.TargetAuthorizer, web.DownloadProgress, web.DownloadWrite, web.DownloadHeadObserver, web.PostStreamRead, web.PostStreamWrite, @FieldType(runtime_jobs.Owner, "find"), @typeInfo(@FieldType(web.FetchOptions, "progress")).optional.child };
