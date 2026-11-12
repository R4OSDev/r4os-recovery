const std = @import("std");
const s = @import("schema");
pub const prefix = "R4SdkWeb";
pub const macro = "R4SDKWEB";
pub const extra_include = "r4os/data_helpers.h";
fn clean(comptime value: []const u8) []const u8 {
    return comptime blk: {
        var bytes: [value.len]u8 = undefined;
        for (value, 0..) |c, i| bytes[i] = if (std.ascii.isAlphanumeric(c) or c == '_') c else '_';
        const result = bytes;
        break :blk &result;
    };
}
pub fn name(comptime T: type) []const u8 {
    return nativeName(s, T);
}
pub fn nativeName(comptime S: type, comptime T: type) []const u8 {
    return comptime blk: {
        if (T == S.owners.callbacks.Slot) break :blk "R4SdkWebSlot";
        if (T == std.mem.Allocator) break :blk "R4SdkDataAllocator";
        if (T == std.heap.FixedBufferAllocator) break :blk "R4SdkDataArena";
        const full = S.stableName(@typeName(T));
        if (S.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (T == S.owners.run) break :blk "R4SdkWebRunResolver";
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4SdkWebNativeValue{d}", .{S.typeId(T)});
        const prefixes = .{ .{ "html", "R4SdkWebHtml" }, .{ "css", "R4SdkWebCss" }, .{ "web_layout", "R4SdkWebLayout" }, .{ "web_font", "R4SdkWebFont" }, .{ "web_fonts", "R4SdkWebFonts" }, .{ "web_font_cache", "R4SdkWebFontCache" }, .{ "web_font_activation", "R4SdkWebFontActivation" }, .{ "web_images", "R4SdkWebImages" }, .{ "web_background", "R4SdkWebBackground" }, .{ "web_forms", "R4SdkWebForms" }, .{ "web_navigation", "R4SdkWebNavigation" }, .{ "javascript", "R4SdkWebJs" }, .{ "web_runtime", "R4SdkWebRuntime" }, .{ "web_canvas", "R4SdkWebCanvas" }, .{ "web_callback_bridge", "R4SdkWebCallback" }, .{ "web_helper_adapters", "R4SdkWeb" } };
        for (prefixes) |p| if (std.mem.eql(u8, full, p[0])) {
            break :blk p[1];
        } else if (std.mem.startsWith(u8, full, p[0] ++ ".")) {
            break :blk p[1] ++ clean(full[p[0].len + 1 ..]);
        };
        break :blk "R4SdkWebNative_" ++ clean(full);
    };
}
