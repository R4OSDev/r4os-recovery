const a = @import("r4os_contract").abi;
pub const Handler = *const fn (usize) callconv(.c) i32;

/// Dedicated driver-owned tasks, with opt-in parallel execution and
/// cooperative cancellation. Timeout never destroys another callback.
pub const Context = struct {
    table: a.DriverThreadApi,
    pub fn start(self: *const Context, handler: Handler, context: usize, flags: u32, handle: *u64) i32 {
        handle.* = 0;
        if (!self.has("start")) return a.err_no_fn;
        if (flags & a.driver_thread_flag_abortable != 0 and !self.canAbort()) return a.err_no_fn;
        const request: a.DriverThreadRequest = .{ .handler = @intFromPtr(handler), .context = context, .flags = flags };
        const callback: *const fn (*const a.DriverThreadRequest, *u64) callconv(.c) i32 = @ptrFromInt(self.table.start);
        return callback(&request, handle);
    }
    pub fn stop(self: *const Context, handle: u64) i32 {
        if (!self.has("stop")) return a.err_no_fn;
        const callback: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.stop);
        return callback(handle);
    }
    pub fn join(self: *const Context, handle: u64, timeout_ticks: u64, result: *i32) i32 {
        result.* = 0;
        if (!self.has("join")) return a.err_no_fn;
        const callback: *const fn (u64, u64, *i32) callconv(.c) i32 = @ptrFromInt(self.table.join);
        return callback(handle, timeout_ticks, result);
    }
    pub fn release(self: *const Context, handle: u64) i32 {
        if (!self.has("release")) return a.err_no_fn;
        const callback: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.release);
        return callback(handle);
    }
    pub fn status(self: *const Context, handle: u64, output: *a.DriverThreadStatus) i32 {
        if (!self.has("status")) return a.err_no_fn;
        const callback: *const fn (u64, *a.DriverThreadStatus) callconv(.c) i32 = @ptrFromInt(self.table.status);
        return callback(handle, output);
    }
    pub fn current(self: *const Context) u64 {
        if (!self.has("current")) return 0;
        const callback: *const fn () callconv(.c) u64 = @ptrFromInt(self.table.current);
        return callback();
    }
    pub fn sleepTicks(self: *const Context, ticks: u64) i32 {
        if (!self.has("sleep_ticks")) return a.err_no_fn;
        const callback: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.sleep_ticks);
        return callback(ticks);
    }
    pub fn stats(self: *const Context, output: *a.DriverThreadStats) i32 {
        if (!self.has("stats")) return a.err_no_fn;
        const callback: *const fn (*a.DriverThreadStats) callconv(.c) i32 = @ptrFromInt(self.table.stats);
        return callback(output);
    }
    pub fn canAbort(self: *const Context) bool {
        return self.has("abort_current");
    }
    pub fn hasCurrentRequest(self: *const Context) bool {
        return self.has("current_request");
    }
    /// Current Task's original handler, context and creation flags. No other
    /// Task can be selected; caller-owned context must outlive Task retirement.
    pub fn currentRequest(self: *const Context, output: *a.DriverThreadRequest) i32 {
        if (!self.hasCurrentRequest()) return a.err_no_fn;
        const callback: *const fn (*a.DriverThreadRequest) callconv(.c) i32 = @ptrFromInt(self.table.current_request);
        return callback(output);
    }
    /// Only a negative result in the current abortable dedicated Task is
    /// accepted. Success does not return; refusals keep the callback running.
    /// Module defers are bypassed, so resource recovery belongs to its owner.
    pub fn abortCurrent(self: *const Context, result: i32) i32 {
        if (!self.has("abort_current")) return a.err_no_fn;
        const callback: *const fn (i32) callconv(.c) i32 = @ptrFromInt(self.table.abort_current);
        return callback(result);
    }
    fn has(self: *const Context, comptime field: []const u8) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(a.DriverThreadApi, field) + 8 and @field(self.table, field) != 0;
    }
};
