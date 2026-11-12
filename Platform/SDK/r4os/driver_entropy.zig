const abi = @import("r4os_contract").abi;
/// Cache during init. Unregister remains valid during the exact closing scope;
/// it closes admission and does not acknowledge physical DMA quiescence.
pub const Context = struct {
    table: abi.DriverEntropyApi,
    pub fn register(self: *const Context, backend: *const abi.EntropyBackend, cookie: *u64) i32 {
        const function: *const fn (*const abi.EntropyBackend, *u64) callconv(.c) i32 = @ptrFromInt(self.table.register_backend);
        return function(backend, cookie);
    }
    pub fn unregister(self: *const Context, cookie: u64) i32 {
        const function: *const fn (u64) callconv(.c) i32 = @ptrFromInt(self.table.unregister_backend);
        return function(cookie);
    }
};
