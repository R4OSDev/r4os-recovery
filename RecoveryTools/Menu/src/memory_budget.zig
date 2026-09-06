const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;

// Count only RAM that the boot map makes usable by the OS. MMIO, framebuffer,
// firmware reservations and physical address holes are never RAM capacity.
pub fn capacity(dev: *const r4os.r4dev.Context) !u64 {
    const boot = dev.bootInfoSummary() orelse return error.MemoryMap;
    if (boot.flags & abi.boot_info_flag_initialized == 0 or
        boot.flags & abi.boot_info_flag_memory_map_truncated != 0 or
        boot.memory_map_count == 0 or boot.memory_map_count > 128) return error.MemoryMap;
    var entries: [128]abi.BootInfoMemoryEntry = undefined;
    for (entries[0..boot.memory_map_count], 0..) |*entry, index|
        entry.* = dev.bootInfoMemoryEntry(@intCast(index)) orelse return error.MemoryMap;
    return count(entries[0..boot.memory_map_count]);
}

fn isRam(kind: u8) bool {
    return kind == abi.boot_memory_kind_usable or kind == abi.boot_memory_kind_bootloader_reclaimable or kind == abi.boot_memory_kind_kernel_and_modules;
}

fn count(entries: []const abi.BootInfoMemoryEntry) !u64 {
    var bytes: u64 = 0;
    for (entries, 0..) |entry, index| {
        if (!isRam(entry.kind)) continue;
        const end = std.math.add(u64, entry.base, entry.length) catch return error.MemoryMap;
        const start = std.math.add(u64, entry.base, 4095) catch return error.MemoryMap;
        for (entries[0..index]) |prior| {
            if (!isRam(prior.kind)) continue;
            const prior_end = std.math.add(u64, prior.base, prior.length) catch return error.MemoryMap;
            if (entry.base < prior_end and prior.base < end) return error.MemoryMap;
        }
        const first = start & ~@as(u64, 4095);
        const last = end & ~@as(u64, 4095);
        bytes = std.math.add(u64, bytes, last -| first) catch return error.MemoryMap;
    }
    if (bytes == 0) return error.MemoryMap;
    return bytes;
}

pub fn require(bytes: u64, minimum: u64) !void {
    if (bytes == 0) return error.MemoryMap;
    if (bytes < minimum) return error.InsufficientRam;
}

test "RAM minimum excludes device windows, holes and duplicate map ranges" {
    const gb = 1024 * 1024 * 1024;
    var entries = [_]abi.BootInfoMemoryEntry{
        .{ .base = 0, .length = 2 * gb, .kind = abi.boot_memory_kind_usable },
        .{ .base = 4 * gb, .length = 4 * gb, .kind = abi.boot_memory_kind_usable },
        .{ .base = 32 * gb, .length = 16 * gb, .kind = abi.boot_memory_kind_reserved },
        .{ .base = 48 * gb, .length = gb, .kind = abi.boot_memory_kind_framebuffer },
    };
    try std.testing.expectEqual(@as(u64, 6 * gb), try count(&entries));
    try std.testing.expectError(error.InsufficientRam, require(try count(&entries), 7 * gb));
    entries[1].length = 6 * gb - 1024 * 1024;
    try require(try count(&entries), 7 * gb);
    entries[2] = .{ .base = gb, .length = gb, .kind = abi.boot_memory_kind_kernel_and_modules };
    try std.testing.expectError(error.MemoryMap, count(&entries));
    entries[2] = .{ .base = std.math.maxInt(u64) - 4095, .length = 8192, .kind = abi.boot_memory_kind_usable };
    try std.testing.expectError(error.MemoryMap, count(&entries));
}
