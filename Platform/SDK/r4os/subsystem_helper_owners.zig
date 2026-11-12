//! Complete current subsystem helper owners, shared by all languages.
const std = @import("std");
pub const catalog = @import("subsystem_catalog.zig");
pub const launch = @import("subsystem_launch.zig");
pub const host = @import("subsystem_host.zig");
pub const runtime = @import("subsystem_runtime.zig");
pub const persistence = @import("subsystem_persistence.zig");
pub const store = persistence.R4osStore(persistence.Configuration);
pub const callbacks = @import("subsystem_callback_bridge.zig");
pub const adapters = @import("subsystem_helper_adapters.zig");
pub const shared = @import("update_bridge_schema.zig");
pub const modules = .{ catalog, launch, host, runtime, persistence, store, callbacks, adapters };
pub fn sharedType(comptime T: type) bool {
    if (T == std.mem.Allocator or T == std.heap.FixedBufferAllocator) return true;
    inline for (shared.types) |V| if (T == V) return true;
    return false;
}
pub fn moduleType(comptime T: type) bool {
    if (T == @This() or T == callbacks.Slot) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return T == @import("r4os_contract").abi;
}
pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    const n = @typeName(T);
    inline for (.{ "array_list.", "hash_map.", "mem.Allocator", "heap.", "atomic.", "crypto.", "program.", "r4sys.", "r4dev.", "r4desk.", "r4draw.", "app_storage.", "app_audio.", "Io.", "std." }) |prefix| if (std.mem.startsWith(u8, n, prefix)) return true;
    return false;
}
pub const callbackTypes = .{
    @FieldType(catalog.HostVerifier, "check"),
    @FieldType(host.Backend, "raster_fn"),
    @FieldType(runtime.GuestDriver, "step_fn"),
    @FieldType(runtime.HostDriver, "poll_fn"),
    @FieldType(runtime.AudioSink, "open_fn"),
    @typeInfo(@FieldType(runtime.AudioSink, "poll_fn")).optional.child,
    @typeInfo(@FieldType(runtime.AudioSink, "finish_fn")).optional.child,
    @FieldType(persistence.Backend, "write_atomic_fn"),
    @typeInfo(@FieldType(persistence.Configuration, "validate_rtc")).optional.child,
};
