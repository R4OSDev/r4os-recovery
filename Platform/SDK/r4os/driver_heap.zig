const abi = @import("r4os_contract").abi;

/// Resident CPU allocations bound to the actual R4D start, usable from init,
/// shutdown and driver-work callbacks. The cached table grants no ownership
/// to other callers and requires no global lifecycle guard in a worker.
pub const Context = struct {
    table: abi.DriverHeapApi,
    pub fn allocate(self: *const Context, bytes: u64, alignment: u32, output: *abi.DriverHeapAllocation) i32 {
        if (!self.has("allocate")) return abi.err_no_fn;
        const callback: *const fn (u64, u32, *abi.DriverHeapAllocation) callconv(.c) i32 = @ptrFromInt(self.table.allocate);
        return callback(bytes, alignment, output);
    }
    pub fn release(self: *const Context, handle: u64) i32 {
        if (!self.has("release")) return abi.err_no_fn;
        const callback: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.release);
        return callback(handle);
    }
    pub fn stats(self: *const Context, output: *abi.DriverHeapStats) i32 {
        if (!self.has("stats")) return abi.err_no_fn;
        const callback: *const fn (*abi.DriverHeapStats) callconv(.c) i32 = @ptrFromInt(self.table.stats);
        return callback(output);
    }
    fn has(self: *const Context, comptime field: []const u8) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.DriverHeapApi, field) + 8 and @field(self.table, field) != 0;
    }
};
