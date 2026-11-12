//! Full current update/storage owner inventory. Host adapter stays explicit.
const std = @import("std");
pub const tools = @import("storage_tools.zig");
pub const host = @import("update_host_file.zig");
pub const guest = @import("storage_tools_guest.zig");
pub const version = @import("version_info.zig");
pub const metadata = @import("r4u_manifest.zig");
pub const artifact = @import("r4u_artifact.zig");
pub const inventory = @import("system_update_inventory.zig");
pub const recovery = @import("system_update_recovery.zig");
pub const batch = @import("system_update_batch.zig");
pub const backup = @import("system_update_backup.zig");
pub const catalog = @import("update_catalog.zig");
pub const callbacks = @import("update_callback_bridge.zig");
pub const adapters = @import("update_helper_adapters.zig");
pub const shared = @import("data_bridge_schema.zig");
pub const modules = .{ tools, tools.io, tools.byte_source, tools.sparse_image, host, tools.partition, tools.partition.guid, tools.fat32, tools.fat32_image, tools.fat32_view, tools.fat32_update, tools.ntfs_format, tools.ntfs, @import("storage_tools/ntfs_plan.zig"), tools.ntfs_resize, tools.gpt_repair, tools.installation, tools.limine, guest, version, metadata, artifact, inventory, recovery, batch, backup, catalog, callbacks, adapters };
pub fn sharedType(comptime T: type) bool {
    if (T == std.mem.Allocator or T == std.heap.FixedBufferAllocator) return true;
    inline for (shared.types) |V| if (T == V) return true;
    return false;
}
pub fn moduleType(comptime T: type) bool {
    if (T == @This() or T == callbacks.Slot) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return T == tools.host_file or T == metadata.paths or T == @import("r4os_contract").abi;
}
pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    if (T == host.File or T == tools.gpt_repair.Report) return true;
    const n = @typeName(T);
    inline for (.{ "array_list.", "hash_map.", "mem.Allocator", "heap.", "atomic.", "crypto.", "program.", "r4sys.", "r4dev.", "storage.Context", "Io.", "std." }) |prefix| if (std.mem.startsWith(u8, n, prefix)) return true;
    return false;
}
pub const callbackTypes = .{ @FieldType(tools.io.Device, "read_fn"), @FieldType(tools.io.Device, "write_fn"), @FieldType(tools.io.Device, "flush_fn"), @typeInfo(@FieldType(tools.io.Device, "continue_fn")).optional.child, @FieldType(tools.byte_source.Source, "read_fn") };
