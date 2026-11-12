//! Canonical data type names, reusable by later boundaries.
const std = @import("std");
fn clean(comptime value: []const u8) []const u8 {
    return comptime blk: {
        var bytes: [value.len]u8 = undefined;
        for (value, 0..) |ch, i| bytes[i] = if (std.ascii.isAlphanumeric(ch) or ch == '_') ch else '_';
        const result = bytes;
        break :blk &result;
    };
}
pub fn nativeName(comptime S: type, comptime T: type) []const u8 {
    return comptime blk: {
        const full = S.stableName(@typeName(T));
        if (S.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (T == S.owners.hash) break :blk "R4SdkDataSha256";
        if (T == S.owners.adapters.Arena) break :blk "R4SdkDataArena";
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4SdkDataNative_Value{d}", .{S.typeId(T)});
        const prefixes = .{
            .{ "data_helper_adapters", "R4SdkData" },
            .{ "json", "R4SdkDataJson" },
            .{ "zip", "R4SdkDataZip" },
            .{ "ico", "R4SdkDataIco" },
            .{ "raster", "R4SdkDataRaster" },
            .{ "secure_random", "R4SdkDataRandom" },
            .{ "cpu_acceleration", "R4SdkDataCpu" },
            .{ "cpu_memory", "R4SdkDataMemory" },
            .{ "web_crypto", "R4SdkDataCrypto" },
            .{ "web_encoding", "R4SdkDataEncoding" },
            .{ "web_url", "R4SdkDataUrl" },
            .{ "r4cp_convert", "R4SdkDataProjectConvert" },
            .{ "r4cp", "R4SdkDataProject" },
            .{ "module_manifest", "R4SdkDataManifest" },
            .{ "version_info", "R4SdkDataVersion" },
            .{ "r4u_manifest", "R4SdkDataUpdateMetadata" },
            .{ "r4u_artifact", "R4SdkDataArtifact" },
            .{ "mem.Allocator", "R4SdkDataAllocator" },
        };
        for (prefixes) |entry| if (std.mem.eql(u8, full, entry[0])) {
            break :blk entry[1];
        } else if (std.mem.startsWith(u8, full, entry[0] ++ ".")) {
            break :blk entry[1] ++ clean(full[entry[0].len + 1 ..]);
        };
        break :blk "R4SdkDataNative_" ++ clean(full);
    };
}
