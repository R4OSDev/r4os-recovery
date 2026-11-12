const r4os = @import("r4os");
var admitted: ?r4os.r4dev.DriverContext2 = null;
comptime { if (!@import("builtin").is_test) asm (r4os.technical2.driverEntriesAsm("recovery_probe_init", "recovery_probe_shutdown")); }
export fn recovery_probe_init(api: *const r4os.r4dev.DriverApi2) callconv(.c) i32 {
    const ctx = r4os.r4dev.DriverContext2.init(api);
    if (!ctx.requires(.{ "log_info", "alloc_dma_region", "free_dma_region", "monotonic_clock", "register_audio_output_backend" })) return -1;
    var clock: r4os.abi.MonotonicClockInfo = .{};
    if (ctx.monotonicClock(&clock) != 1 or clock.generation == 0) return -2;
    var memory: r4os.abi.DmaBuffer = .{};
    if (ctx.allocDmaRegion(4096, 4096, &memory) != 0) return -3;
    ctx.freeDmaRegion(&memory);
    var backend: r4os.abi.AudioBackend2 = .{};
    if (ctx.registerAudioOutputBackend("RECOVERY_API2_PROBE", &backend) != -5) return -4;
    admitted = ctx;
    ctx.logInfo("[RECOVERYAPI2] driver=OK init=2 dma=4096 clock=OK audio=unavailable");
    return 0;
}
export fn recovery_probe_shutdown() callconv(.c) i32 {
    const ctx = admitted orelse return -1;
    ctx.logInfo("[RECOVERYAPI2] driver_shutdown=OK");
    admitted = null;
    return 0;
}
