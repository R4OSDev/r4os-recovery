//! Original driver helpers shared by all implementation languages.
const std = @import("std");
pub const driver = @import("driver.zig");
pub const serial = @import("driver_serial.zig");
pub const memory = @import("driver_memory.zig");
pub const entropy = @import("driver_entropy.zig");
pub const resources = @import("driver_resources.zig");
pub const queue = @import("driver_queue.zig");
pub const outputs = @import("driver_outputs.zig");
pub const display = @import("driver_display.zig");
pub const heap = @import("driver_heap.zig");
pub const threads = @import("driver_threads.zig");
pub const semaphores = @import("driver_semaphores.zig");
pub const cpu_power = @import("driver_cpu_power.zig");
pub const shared = @import("update_bridge_schema.zig");
pub const modules = .{ driver, serial, memory, entropy, resources, queue, outputs, display, heap, threads, semaphores, cpu_power };
pub fn sharedType(comptime T: type) bool {
    if (T == std.mem.Allocator or T == std.heap.FixedBufferAllocator) return true;
    inline for (shared.types) |V| if (T == V) return true;
    return false;
}
pub fn moduleType(comptime T: type) bool {
    if (T == @This()) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return T == @import("r4os_contract").abi;
}
pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    const name = @typeName(T);
    inline for (.{ "array_list.", "hash_map.", "mem.Allocator", "std.", "heap.", "atomic.", "crypto.", "Io." }) |prefix| if (std.mem.startsWith(u8, name, prefix)) return true;
    return false;
}
pub const callbackTypes = .{};
