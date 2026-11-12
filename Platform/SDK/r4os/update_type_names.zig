//! Canonical update type names shared by later SDK boundaries.
const std = @import("std");
pub fn nativeName(comptime s: type, comptime T: type) []const u8 {
    return comptime blk: {
        if (s.owners.sharedType(T)) break :blk s.owners.shared.nativeName(T);
        if (T == s.owners.tools.ntfs.Builder) break :blk "R4SdkUpdateNtfsBuilder";
        if (T == s.owners.tools.ntfs.Meta) break :blk "R4SdkUpdateNtfsMetadata";
        const full = s.stableName(@typeName(T));
        if (s.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4SdkUpdateNativeValue{d}", .{s.typeId(T)});
        const prefixes = .{ .{ "system_update_inventory", "R4SdkUpdateInventory" }, .{ "system_update_recovery", "R4SdkUpdateRecovery" }, .{ "system_update_batch", "R4SdkUpdateBatch" }, .{ "system_update_backup", "R4SdkUpdateBackup" }, .{ "update_catalog", "R4SdkUpdateCatalog" }, .{ "update_callback_bridge", "R4SdkUpdateCallback" }, .{ "update_helper_adapters", "R4SdkUpdate" }, .{ "update_host_file", "R4SdkUpdateHost" }, .{ "storage_tools_guest", "R4SdkUpdateGuest" }, .{ "storage_tools.io", "R4SdkUpdateBlock" }, .{ "storage_tools.byte_source", "R4SdkUpdateByte" }, .{ "storage_tools.partition", "R4SdkUpdatePartition" }, .{ "storage_tools.fat32", "R4SdkUpdateFat32" }, .{ "storage_tools.ntfs_plan", "R4SdkUpdateNtfs" }, .{ "storage_tools", "R4SdkUpdateStorage" }, .{ "ntfs_format", "R4SdkUpdateNtfsFormat" } };
        for (prefixes) |p| if (std.mem.eql(u8, full, p[0])) break :blk p[1] else if (std.mem.startsWith(u8, full, p[0] ++ ".")) break :blk p[1] ++ clean(full[p[0].len + 1 ..]);
        break :blk "R4SdkUpdateNative_" ++ clean(full);
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
