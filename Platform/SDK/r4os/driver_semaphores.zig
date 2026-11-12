const a = @import("r4os_contract").abi;

/// Driver-owned resident counting semaphores. A successful acquire consumes
/// exactly one permit. Close/stop never substitutes for a permit handoff.
pub const Context = struct {
    table: a.DriverSemaphoreApi,
    pub fn create(self: *const Context, initial: u32, maximum: u32, handle: *u64) i32 {
        handle.* = 0;
        if (!self.has("create")) return a.err_no_fn;
        const callback: *const fn (u32, u32, *u64) callconv(.c) i32 = @ptrFromInt(self.table.create);
        return callback(initial, maximum, handle);
    }
    pub fn acquire(self: *const Context, handle: u64, timeout_ticks: u64) i32 {
        if (!self.has("acquire")) return a.err_no_fn;
        const callback: *const fn (u64, u64) callconv(.c) i32 = @ptrFromInt(self.table.acquire);
        return callback(handle, timeout_ticks);
    }
    pub fn release(self: *const Context, handle: u64) i32 {
        if (!self.has("release")) return a.err_no_fn;
        const callback: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.release);
        return callback(handle);
    }
    pub fn destroy(self: *const Context, handle: u64) i32 {
        if (!self.has("destroy")) return a.err_no_fn;
        const callback: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.destroy);
        return callback(handle);
    }
    pub fn status(self: *const Context, handle: u64, output: *a.DriverSemaphoreStatus) i32 {
        if (!self.has("status")) return a.err_no_fn;
        const callback: *const fn (u64, *a.DriverSemaphoreStatus) callconv(.c) i32 = @ptrFromInt(self.table.status);
        return callback(handle, output);
    }
    pub fn stats(self: *const Context, output: *a.DriverSemaphoreStats) i32 {
        if (!self.has("stats")) return a.err_no_fn;
        const callback: *const fn (*a.DriverSemaphoreStats) callconv(.c) i32 = @ptrFromInt(self.table.stats);
        return callback(output);
    }
    pub fn contextFlags(self: *const Context) u32 {
        if (!self.has("context_flags")) return 0;
        const callback: *const fn () callconv(.c) u32 = @ptrFromInt(self.table.context_flags);
        return callback();
    }
    fn has(self: *const Context, comptime field: []const u8) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(a.DriverSemaphoreApi, field) + 8 and @field(self.table, field) != 0;
    }
};
