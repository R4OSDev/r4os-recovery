const std = @import("std");
const s = @import("schema");
pub const prefix = "R4SdkSubsystem";
pub const macro = "R4SDKSUBSYSTEM";
pub const extra_include = "r4os/update_helpers.h";
pub fn name(comptime T: type) []const u8 {
    return comptime blk: {
        if (s.owners.sharedType(T)) break :blk s.owners.shared.nativeName(T);
        if (T == s.owners.store.Store) break :blk "R4SdkSubsystemStore";
        if (T == s.owners.store.AsyncStore) break :blk "R4SdkSubsystemAsyncStore";
        if (T == s.owners.store.AsyncStats) break :blk "R4SdkSubsystemAsyncStats";
        if (T == s.owners.store.FailureStage) break :blk "R4SdkSubsystemFailureStage";
        if (T == s.owners.store.RecoveryTestState) break :blk "R4SdkSubsystemRecoveryTestState";
        const full = s.stableName(@typeName(T));
        if (s.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4SdkSubsystemNativeValue{d}", .{s.typeId(T)});
        const prefixes = .{ .{ "subsystem_catalog", "R4SdkSubsystemCatalog" }, .{ "subsystem_launch", "R4SdkSubsystemLaunch" }, .{ "subsystem_host", "R4SdkSubsystemVideo" }, .{ "subsystem_runtime", "R4SdkSubsystemRuntime" }, .{ "subsystem_persistence", "R4SdkSubsystemPersistence" }, .{ "subsystem_callback_bridge", "R4SdkSubsystemCallback" }, .{ "subsystem_helper_adapters", "R4SdkSubsystem" } };
        for (prefixes) |p| if (std.mem.eql(u8, full, p[0])) break :blk p[1] else if (std.mem.startsWith(u8, full, p[0] ++ ".")) break :blk p[1] ++ clean(full[p[0].len + 1 ..]);
        break :blk "R4SdkSubsystemNative_" ++ clean(full);
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
