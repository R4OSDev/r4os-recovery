const std = @import("std");
const s = @import("schema");
pub const prefix = "R4SdkDriver";
pub const macro = "R4SDKDRIVER";
pub const extra_include = "r4os/update_helpers.h";
pub fn name(comptime T: type) []const u8 {
    return comptime blk: {
        if (s.owners.sharedType(T)) break :blk s.owners.shared.nativeName(T);
        const full = s.stableName(@typeName(T));
        if (s.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4SdkDriverNativeValue{d}", .{s.typeId(T)});
        const prefixes = .{ .{ "driver", "R4SdkDriver" }, .{ "driver_serial", "R4SdkDriverSerial" }, .{ "driver_memory", "R4SdkDriverMemory" }, .{ "driver_entropy", "R4SdkDriverEntropy" }, .{ "driver_resources", "R4SdkDriverResources" }, .{ "driver_queue", "R4SdkDriverQueue" }, .{ "driver_outputs", "R4SdkDriverOutputs" }, .{ "driver_display", "R4SdkDriverDisplay" }, .{ "driver_heap", "R4SdkDriverHeap" }, .{ "driver_threads", "R4SdkDriverThreads" }, .{ "driver_semaphores", "R4SdkDriverSemaphores" }, .{ "driver_cpu_power", "R4SdkDriverCpuPower" } };
        for (prefixes) |p| if (std.mem.eql(u8, full, p[0])) break :blk p[1] else if (std.mem.startsWith(u8, full, p[0] ++ ".")) break :blk p[1] ++ clean(full[p[0].len + 1 ..]);
        break :blk "R4SdkDriverNative_" ++ clean(full);
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
