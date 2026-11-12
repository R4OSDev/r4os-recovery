const abi = @import("r4os_contract").abi;
/// Cached owner-authenticated table; registration needs lifecycle-owned init/work.
pub const Context = struct {
    table: abi.DriverSerialApi,
    fn has(self: *const Context, comptime field: []const u8) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.DriverSerialApi, field) + 8 and @field(self.table, field) != 0;
    }
    pub fn register(self: *const Context, descriptor: *const abi.SerialBackend, out: *u64) i32 {
        if (!self.has("register_port")) return abi.err_no_fn;
        const f: *const fn (*const abi.SerialBackend, *u64) callconv(.c) i32 = @ptrFromInt(self.table.register_port);
        return f(descriptor, out);
    }
    pub fn unregister(self: *const Context, registration: u64) i32 {
        if (!self.has("unregister_port")) return abi.err_no_fn;
        const f: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.unregister_port);
        return f(registration);
    }
    pub fn notify(self: *const Context, registration: u64, events: u32) i32 {
        if (!self.has("notify")) return abi.err_no_fn;
        const f: *const fn (u64, u32) callconv(.c) i32 = @ptrFromInt(self.table.notify);
        return f(registration, events);
    }
    pub fn admission(self: *const Context, registration: u64) i32 {
        if (!self.has("admission")) return abi.err_no_fn;
        const f: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.admission);
        return f(registration);
    }
};
