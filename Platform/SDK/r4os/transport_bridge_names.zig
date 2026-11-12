const std = @import("std");
const s = @import("schema");
pub const prefix = "R4SdkTransport";
pub const macro = "R4SDKTRANSPORT";
pub const extra_include = "r4os/web_helpers.h";
pub fn name(comptime T: type) []const u8 {
    return comptime blk: {
        if (s.owners.sharedType(T)) break :blk @import("web_bridge_names.zig").nativeName(s.owners.shared, T);
        const full = s.stableName(@typeName(T));
        if (s.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4SdkTransportNativeValue{d}", .{s.typeId(T)});
        const prefixes = .{ .{ "app_web", "R4SdkTransport" }, .{ "http", "R4SdkTransportHttp" }, .{ "web_security", "R4SdkTransportSecurity" }, .{ "web_response_cache", "R4SdkTransportCache" }, .{ "app_web_jobs", "R4SdkTransportJobs" }, .{ "web_runtime_jobs", "R4SdkTransportRuntimeJobs" }, .{ "web_resources", "R4SdkTransportResources" }, .{ "web_documents", "R4SdkTransportDocuments" }, .{ "web_fetch", "R4SdkTransportFetch" }, .{ "transport_helper_adapters", "R4SdkTransport" } };
        for (prefixes) |p| if (std.mem.eql(u8, full, p[0])) break :blk p[1] else if (std.mem.startsWith(u8, full, p[0] ++ ".")) break :blk p[1] ++ clean(full[p[0].len + 1 ..]);
        break :blk "R4SdkTransportNative_" ++ clean(full);
    };
}
fn clean(comptime value: []const u8) []const u8 {
    return comptime blk: {
        var b: [value.len]u8 = undefined;
        for (value, 0..) |v, i| b[i] = if (std.ascii.isAlphanumeric(v) or v == '_') v else '_';
        const result = b;
        break :blk &result;
    };
}
