const r4os = @import("r4os");

var smoke_writes: u64 = 0;
var smoke_stops: u64 = 0;
var smoke_shutdowns: u64 = 0;
var smoke_last_result: i32 = 0;
var smoke_backend: r4os.abi.AudioBackend = .{};

comptime {
    asm (r4os.r4dev.driverEntriesAsm("sdk_smoke_init", "sdk_smoke_shutdown"));
}

export fn sdk_smoke_init(api: *const r4os.r4dev.DriverApi) callconv(.c) i32 {
    var ctx = r4os.r4dev.DriverContext.init(api);
    ctx.logInfo("SDK R4D smoke init");
    if (!ctx.apiCompatible()) {
        ctx.logError("SDK R4D smoke api mismatch");
        return -1;
    }
    if (ctx.timerFrequency() == 0) {
        ctx.logError("SDK R4D smoke timer unavailable");
        return -2;
    }
    const tick_before = ctx.tickCount();
    ctx.waitTicks(1);
    if (ctx.tickCount() - tick_before == 0) {
        ctx.logError("SDK R4D smoke wait tick failed");
        return -3;
    }
    smoke_backend = .{
        .formats = r4os.abi.audio_backend_format_s16le | r4os.abi.audio_backend_format_u8,
        .min_rate = 8000,
        .max_rate = 48_000,
        .preferred_rate = 48_000,
        .max_channels = 2,
        .write_pcm = smokeWritePcm,
        .stop = smokeStop,
        .shutdown = smokeShutdownBackend,
        .status = smokeStatus,
    };
    if (ctx.registerAudioOutputBackend("SDKSMOKE", &smoke_backend) != 0) {
        ctx.logError("SDK R4D smoke audio backend register failed");
        return -4;
    }
    if (ctx.unregisterAudioBackend("SDKSMOKE") != 0) {
        ctx.logError("SDK R4D smoke audio backend unregister failed");
        return -5;
    }
    ctx.logInfo("SDK R4D smoke contract ok");
    return 0;
}

export fn sdk_smoke_shutdown() callconv(.c) i32 {
    return 0;
}

fn smokeWritePcm(context: ?*anyopaque, data: [*]const u8, len: u32, rate: u32, channels: u16, format: u16) callconv(.c) i32 {
    _ = context;
    _ = data;
    if (len == 0 or rate == 0 or channels == 0 or format == 0) {
        smoke_last_result = -1;
        return -1;
    }
    smoke_writes +%= 1;
    smoke_last_result = 0;
    return 0;
}

fn smokeStop(context: ?*anyopaque) callconv(.c) i32 {
    _ = context;
    smoke_stops +%= 1;
    smoke_last_result = 0;
    return 0;
}

fn smokeShutdownBackend(context: ?*anyopaque) callconv(.c) i32 {
    _ = context;
    smoke_shutdowns +%= 1;
    smoke_last_result = 0;
    return 0;
}

fn smokeStatus(context: ?*anyopaque, out: *r4os.abi.AudioBackendStatus) callconv(.c) i32 {
    _ = context;
    out.* = .{
        .active = 0,
        .writes = smoke_writes,
        .underruns = 0,
        .errors = 0,
        .last_result = smoke_last_result,
        .reserved = 0,
    };
    return 0;
}
