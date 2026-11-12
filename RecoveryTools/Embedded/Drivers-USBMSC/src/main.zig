const r4os = @import("r4os");

const State = extern struct {
    init_count: u64 = 0,
    status_count: u64 = 0,
    shutdown_count: u64 = 0,
};

var state: State = .{};

comptime {
    if (!@import("builtin").is_test) asm (r4os.technical2.driverEntriesAsm("usbmsc_init", "usbmsc_shutdown"));
}

export fn usbmsc_init(api: *const r4os.r4dev.DriverApi2) callconv(.c) i32 {
    var ctx = r4os.r4dev.DriverContext2.init(api);
    if (!ctx.requires(.{})) {
        ctx.logError("USBMSC.R4D driver api mismatch");
        return -3;
    }
    state.init_count += 1;
    ctx.logInfo("USBMSC.R4D preload storage backend ready; built-in legacy rescue remains data path");
    return 0;
}

export fn usbmsc_shutdown() callconv(.c) i32 {
    state.shutdown_count += 1;
    return 0;
}
