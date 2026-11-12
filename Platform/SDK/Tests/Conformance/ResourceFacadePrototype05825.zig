const std = @import("std");
const r4os = @import("r4os");

fn idleDeclaration(v: *const r4os.abi.CpuIdleDescriptor) callconv(.c) i32 {
    return if (v.cpu_index == 2 and v.epoch == 0x85_31_1234_5678 and v.firmware_generation == 49) -2 else -99;
}
fn idlePolicy(v: *const r4os.abi.CpuIdlePolicy) callconv(.c) i32 {
    return if (v.provider_generation == 0x85_31_1234_5678 and v.enabled == 1 and v.maximum_latency_us == 100) -4 else -99;
}
test "idle tail refuses old prefixes without dispatch and preserves exact declaration and policy identity" {
    const a = r4os.abi;
    const Ctx = r4os.r4dev.DriverCpuPowerContext;
    var ctx: Ctx = .{ .table = .{ .idle_publish = @intFromPtr(&idleDeclaration), .idle_policy = @intFromPtr(&idlePolicy) } };
    const descriptor: a.CpuIdleDescriptor = .{ .cpu_index = 2, .epoch = 0x85_31_1234_5678, .firmware_generation = 49 };
    const policy: a.CpuIdlePolicy = .{ .provider_generation = 0x85_31_1234_5678, .enabled = 1, .maximum_latency_us = 100, .residency_factor = 4 };
    for (168..176) |size| {
        ctx.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, ctx.idlePublish(&descriptor));
    }
    for (176..184) |size| {
        ctx.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, ctx.idlePolicy(&policy));
    }
    ctx.table.size = 184;
    try std.testing.expectEqual(@as(i32, -2), ctx.idlePublish(&descriptor));
    try std.testing.expectEqual(@as(i32, -4), ctx.idlePolicy(&policy));
    ctx.table.idle_publish = 0;
    ctx.table.idle_policy = 0;
    try std.testing.expectEqual(a.err_no_fn, ctx.idlePublish(&descriptor));
    try std.testing.expectEqual(a.err_no_fn, ctx.idlePolicy(&policy));
}

var power_query_mode: u32 = 0;
fn powerRegister(backend: *const r4os.abi.CpuPowerBackend, cookie: *u64) callconv(.c) i32 {
    std.debug.assert(backend.context == 0x1234_5678_85ab_cdef);
    cookie.* = backend.context;
    return 0;
}
fn powerUnregister(cookie: u64) callconv(.c) i32 {
    return if (cookie == 0x1234_5678_85ab_cdef) -83 else -99;
}
fn powerCurrent() callconv(.c) u32 {
    return 63;
}
fn powerCap(cpu: u32, out: *r4os.abi.CpuCapabilitiesInfo) callconv(.c) i32 {
    out.epoch = cpu;
    return -84;
}
fn powerTopology(cpu: u32, out: *r4os.abi.CpuTopologyInfo) callconv(.c) i32 {
    out.start_epoch = cpu;
    return -85;
}
fn powerRead(cpu: u32, epoch: u64, id: u32, out: *r4os.abi.CpuRegisterInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and id == 17);
    out.value = epoch;
    return -86;
}
fn powerClock(out: *r4os.abi.MonotonicClockInfo) callconv(.c) i32 {
    out.instant_ns = 0x1234_5678_85ab_cdef;
    return 1;
}
fn powerPair(cpu: u32, epoch: u64, out: *r4os.abi.CpuPowerCounters) callconv(.c) i32 {
    std.debug.assert(cpu == 63);
    out.aperf = epoch;
    out.mperf = epoch + 1;
    return -88;
}
fn powerQuery(out: *r4os.abi.DriverCpuPowerApi) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == @sizeOf(r4os.abi.DriverCpuPowerApi));
    out.* = .{ .register_backend = @intFromPtr(&powerRegister), .unregister_backend = @intFromPtr(&powerUnregister), .current_cpu = @intFromPtr(&powerCurrent), .capabilities = @intFromPtr(&powerCap), .topology = @intFromPtr(&powerTopology), .register_read = @intFromPtr(&powerRead), .clock = @intFromPtr(&powerClock) };
    switch (power_query_mode) {
        1 => out.version = 2,
        2 => out.size = 63,
        3 => out.clock = 0,
        4 => return -87,
        5 => out.size = 64,
        else => {},
    }
    out.counters_read = @intFromPtr(&powerPair);
    return 0;
}
test "driver CPU power query validates the full optional tail and keeps typed 64-bit calls" {
    const a = r4os.abi;
    const t = std.testing;
    const Ctx = @import("r4os").r4dev.DriverCpuPowerContext;
    var power_resources = @import("r4os").r4dev.DriverResourceContext{ .table = .{ .cpu_power_query = @intFromPtr(&powerQuery) } };
    for (56..64) |size| {
        power_resources.table.size = @intCast(size);
        try t.expect(power_resources.cpuPower() == null);
    }
    power_resources.table.size = 64;
    for (1..5) |mode| {
        power_query_mode = @intCast(mode);
        try t.expect(power_resources.cpuPower() == null);
    }
    power_query_mode = 0;
    var ctx = power_resources.cpuPower().?;
    const identity: u64 = 0x1234_5678_85ab_cdef;
    const backend: a.CpuPowerBackend = .{ .context = identity };
    var cookie: u64 = 71;
    try t.expectEqual(@as(i32, 0), ctx.register(&backend, &cookie));
    try t.expectEqual(identity, cookie);
    try t.expectEqual(@as(i32, -83), ctx.unregister(cookie));
    try t.expectEqual(@as(u32, 63), ctx.currentCpu());
    var cap: a.CpuCapabilitiesInfo = .{};
    var topo: a.CpuTopologyInfo = .{};
    var raw: a.CpuRegisterInfo = .{};
    var clock: a.MonotonicClockInfo = .{};
    var pair: a.CpuPowerCounters = .{};
    try t.expectEqual(@as(i32, -88), ctx.countersRead(63, identity, &pair));
    try t.expectEqual(identity, pair.aperf);
    try t.expectEqual(identity + 1, pair.mperf);
    power_query_mode = 5;
    const legacy = power_resources.cpuPower().?;
    try t.expectEqual(@as(u32, 63), legacy.currentCpu());
    try t.expectEqual(a.err_no_fn, legacy.countersRead(63, identity, &pair));
    try t.expectEqual(identity, pair.aperf);
    for (64..72) |size| {
        ctx.table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, ctx.countersRead(63, identity, &pair));
        try t.expectEqual(identity, pair.aperf);
    }
    ctx.table.size = 72;
    try t.expectEqual(@as(i32, -84), ctx.capabilities(63, &cap));
    try t.expectEqual(@as(u64, 63), cap.epoch);
    try t.expectEqual(@as(i32, -85), ctx.topology(63, &topo));
    try t.expectEqual(@as(u64, 63), topo.start_epoch);
    try t.expectEqual(@as(i32, -86), ctx.registerRead(63, identity, 17, &raw));
    try t.expectEqual(identity, raw.value);
    try t.expectEqual(@as(i32, 1), ctx.clock(&clock));
    try t.expectEqual(identity, clock.instant_ns);
    inline for (.{ "register_backend", "unregister_backend", "current_cpu", "capabilities", "topology", "register_read", "clock", "counters_read" }) |field| {
        const old = @field(ctx.table, field);
        @field(ctx.table, field) = 0;
        try t.expect(!ctx.has(field));
        @field(ctx.table, field) = old;
        ctx.table.size = @offsetOf(a.DriverCpuPowerApi, field) + 7;
        try t.expect(!ctx.has(field));
        ctx.table.size = 72;
    }
    const missing = Ctx{ .table = .{} };
    try t.expectEqual(a.err_no_fn, missing.register(&backend, &cookie));
    try t.expectEqual(identity, cookie);
    try t.expectEqual(a.err_no_fn, missing.unregister(identity));
    try t.expectEqual(a.cpu_power_cpu_none, missing.currentCpu());
    try t.expectEqual(a.err_no_fn, missing.capabilities(63, &cap));
    try t.expectEqual(@as(u64, 63), cap.epoch);
    try t.expectEqual(a.err_no_fn, missing.topology(63, &topo));
    try t.expectEqual(@as(u64, 63), topo.start_epoch);
    try t.expectEqual(a.err_no_fn, missing.registerRead(63, identity, 17, &raw));
    try t.expectEqual(identity, raw.value);
    try t.expectEqual(a.err_no_fn, missing.clock(&clock));
    try t.expectEqual(identity, clock.instant_ns);
    try t.expectEqual(a.err_no_fn, missing.countersRead(63, identity, &pair));
    try t.expectEqual(identity, pair.aperf);
}

const control_identity: u64 = 0x1234_5678_85ab_cdef;
fn controlFeature(cpu: u32, epoch: u64, ordinal: u32, out: *r4os.abi.CpuFeatureInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == control_identity and ordinal == 54);
    out.epoch = epoch;
    return -91;
}
fn controlRegister(cookie: u64, backend: *const r4os.abi.CpuPerformanceBackend) callconv(.c) i32 {
    std.debug.assert(cookie == control_identity and backend.context == cookie);
    return -92;
}
fn controlAcquire(cpu: u32, epoch: u64, token: *u64) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == control_identity);
    token.* = epoch;
    return -93;
}
fn controlRelease(cpu: u32, epoch: u64, token: u64) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == control_identity and token == epoch);
    return -94;
}
fn controlWrite(cpu: u32, epoch: u64, token: u64, id: u32, expected: u64, requested: u64, out: *r4os.abi.CpuRegisterWriteInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == control_identity and token == epoch and id == 20 and expected == epoch + 1 and requested == epoch + 2);
    out.observed_after = requested;
    return -95;
}
test "optional CPU control tail preserves legacy72 boundaries and full stack arguments" {
    const a = r4os.abi;
    const t = std.testing;
    const Ctx = r4os.r4dev.DriverCpuPowerContext;
    var ctx = Ctx{ .table = .{ .feature = @intFromPtr(&controlFeature), .register_performance = @intFromPtr(&controlRegister), .control_acquire = @intFromPtr(&controlAcquire), .control_release = @intFromPtr(&controlRelease), .register_compare_write = @intFromPtr(&controlWrite) } };
    var feature: a.CpuFeatureInfo = .{};
    const backend: a.CpuPerformanceBackend = .{ .context = control_identity };
    var token: u64 = 71;
    var receipt: a.CpuRegisterWriteInfo = .{};
    try t.expectEqual(@as(i32, -91), ctx.feature(63, control_identity, 54, &feature));
    try t.expectEqual(control_identity, feature.epoch);
    try t.expectEqual(@as(i32, -92), ctx.registerPerformance(control_identity, &backend));
    try t.expectEqual(@as(i32, -93), ctx.controlAcquire(63, control_identity, &token));
    try t.expectEqual(control_identity, token);
    try t.expectEqual(@as(i32, -94), ctx.controlRelease(63, control_identity, token));
    try t.expectEqual(@as(i32, -95), ctx.registerCompareWrite(63, control_identity, token, 20, control_identity + 1, control_identity + 2, &receipt));
    try t.expectEqual(control_identity + 2, receipt.observed_after);
    inline for (.{ "feature", "register_performance", "control_acquire", "control_release", "register_compare_write" }) |field| {
        const slot = @field(ctx.table, field);
        ctx.table.size = @offsetOf(a.DriverCpuPowerApi, field) + 7;
        try t.expect(!ctx.has(field));
        ctx.table.size = @sizeOf(a.DriverCpuPowerApi);
        @field(ctx.table, field) = 0;
        try t.expect(!ctx.has(field));
        @field(ctx.table, field) = slot;
    }
    ctx.table.size = 72;
    try t.expectEqual(a.err_no_fn, ctx.feature(63, control_identity, 54, &feature));
    try t.expectEqual(control_identity, feature.epoch);
    try t.expectEqual(a.err_no_fn, ctx.registerPerformance(control_identity, &backend));
    try t.expectEqual(a.err_no_fn, ctx.controlAcquire(63, control_identity, &token));
    try t.expectEqual(control_identity, token);
    try t.expectEqual(a.err_no_fn, ctx.controlRelease(63, control_identity, token));
    try t.expectEqual(a.err_no_fn, ctx.registerCompareWrite(63, control_identity, token, 20, control_identity + 1, control_identity + 2, &receipt));
    try t.expectEqual(control_identity + 2, receipt.observed_after);
}

fn cppcRegister(cookie: u64, backend: *const r4os.abi.CpuCppcBackend) callconv(.c) i32 {
    std.debug.assert(cookie == control_identity and backend.context == cookie);
    return -97;
}
fn cppcRank(input: *const r4os.abi.CpuPerformanceHint, sequence: *u64) callconv(.c) i32 {
    std.debug.assert(input.cpu_index == 63 and input.epoch == control_identity);
    sequence.* = input.epoch;
    return -98;
}
test "CPPC mechanism128 independently negotiates both optional slots without touching refused output" {
    const a = r4os.abi;
    const t = std.testing;
    var ctx = r4os.r4dev.DriverCpuPowerContext{ .table = .{ .register_cppc = @intFromPtr(&cppcRegister), .rank_publish = @intFromPtr(&cppcRank) } };
    const backend: a.CpuCppcBackend = .{ .context = control_identity };
    const input: a.CpuPerformanceHint = .{ .cpu_index = 63, .epoch = control_identity };
    var sequence: u64 = 71;
    for (112..120) |size| {
        ctx.table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, ctx.registerCppc(control_identity, &backend));
    }
    ctx.table.size = 120;
    try t.expectEqual(@as(i32, -97), ctx.registerCppc(control_identity, &backend));
    for (112..128) |size| {
        ctx.table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, ctx.rankPublish(&input, &sequence));
        try t.expectEqual(@as(u64, 71), sequence);
    }
    ctx.table.size = 128;
    try t.expectEqual(@as(i32, -98), ctx.rankPublish(&input, &sequence));
    try t.expectEqual(control_identity, sequence);
    ctx.table.register_cppc = 0;
    ctx.table.rank_publish = 0;
    try t.expectEqual(a.err_no_fn, ctx.registerCppc(control_identity, &backend));
    try t.expectEqual(a.err_no_fn, ctx.rankPublish(&input, &sequence));
    try t.expectEqual(control_identity, sequence);
}

fn dmaRangeDevice(mapping: *const r4os.abi.DmaMapping, offset: u32, bytes: u32) callconv(.c) i32 {
    std.debug.assert(mapping.handle == 0x700000000079 and offset == 0xfffffff0 and bytes == 7);
    return -701;
}
fn dmaRangeCpu(mapping: *const r4os.abi.DmaMapping, offset: u32, bytes: u32) callconv(.c) i32 {
    std.debug.assert(mapping.handle == 0x700000000079 and offset == 3 and bytes == 0xffffffff);
    return -702;
}
test "driver DMA range facade keeps the v33 prefix and negotiates each optional callback" {
    try audioIdleFacade();
    try bootDisplayFacade();
    try platformFacade();
    try ownedWorkFacade();
    const a = r4os.abi;
    const t = std.testing;
    try t.expectEqual(@as(usize, 632), @offsetOf(a.DriverApi, "dma_sync_range_for_device"));
    try t.expectEqual(@as(usize, 640), @offsetOf(a.DriverApi, "dma_sync_range_for_cpu"));
    try t.expectEqual(@as(usize, 648), @offsetOf(a.DriverApi, "driver_work_submit_owned"));
    try t.expectEqual(@as(usize, 656), @offsetOf(a.DriverApi, "serial_query"));
    try t.expectEqual(@as(usize, 664), @sizeOf(a.DriverApi));
    var api: a.DriverApi = undefined;
    api.magic = a.driver_magic;
    api.reserved = 0;
    api.version = 33;
    api.size = @sizeOf(a.DriverApi);
    api.dma_sync_range_for_device = &dmaRangeDevice;
    api.dma_sync_range_for_cpu = &dmaRangeCpu;
    var ctx = r4os.r4dev.DriverContext.init(&api);
    const mapping = a.DmaMapping{ .handle = 0x700000000079 };
    try t.expectEqual(a.err_no_fn, ctx.syncDmaRangeForDevice(&mapping, 0xfffffff0, 7));
    try t.expectEqual(a.err_no_fn, ctx.syncDmaRangeForCpu(&mapping, 3, 0xffffffff));
    api.version = 34;
    api.size = 639;
    try t.expectEqual(a.err_no_fn, ctx.syncDmaRangeForDevice(&mapping, 0xfffffff0, 7));
    api.size = 640;
    try t.expectEqual(@as(i32, -701), ctx.syncDmaRangeForDevice(&mapping, 0xfffffff0, 7));
    try t.expectEqual(a.err_no_fn, ctx.syncDmaRangeForCpu(&mapping, 3, 0xffffffff));
    api.size = 648;
    try t.expectEqual(@as(i32, -702), ctx.syncDmaRangeForCpu(&mapping, 3, 0xffffffff));
    api.dma_sync_range_for_device = null;
    api.dma_sync_range_for_cpu = null;
    try t.expectEqual(a.err_no_fn, ctx.syncDmaRangeForDevice(&mapping, 0xfffffff0, 7));
    try t.expectEqual(a.err_no_fn, ctx.syncDmaRangeForCpu(&mapping, 3, 0xffffffff));
}

fn audioIdleRegister(_: [*:0]const u8, raw: *const anyopaque) callconv(.c) i32 {
    const descriptor: *const r4os.r4dev.AudioOutputIdleBackend = @ptrCast(@alignCast(raw));
    std.debug.assert(descriptor.base.base.version == r4os.abi.audio_backend_idle_version);
    std.debug.assert(descriptor.base.base.size == 104);
    std.debug.assert(@intFromPtr(descriptor.base.base.context) == 0x100000000082);
    return descriptor.idle.?(descriptor.base.base.context);
}

fn audioIdleProbe(raw: ?*anyopaque) callconv(.c) i32 {
    std.debug.assert(@intFromPtr(raw) == 0x100000000082);
    return -744;
}

fn audioIdleFacade() !void {
    const a = r4os.abi;
    try std.testing.expectEqual(@as(usize, 72), @sizeOf(a.AudioBackend));
    try std.testing.expectEqual(@as(usize, 96), @sizeOf(r4os.r4dev.AudioOutputBackend));
    try std.testing.expectEqual(@as(usize, 96), @offsetOf(r4os.r4dev.AudioOutputIdleBackend, "idle"));
    try std.testing.expectEqual(@as(usize, 104), @sizeOf(r4os.r4dev.AudioOutputIdleBackend));
    var api: a.DriverApi = undefined;
    api.register_audio_output_backend = audioIdleRegister;
    const ctx = r4os.r4dev.DriverContext.init(&api);
    const descriptor: r4os.r4dev.AudioOutputIdleBackend = .{
        .base = .{ .base = .{ .version = a.audio_backend_idle_version, .size = 104, .context = @ptrFromInt(0x100000000082) }, .outputs = undefined },
        .idle = audioIdleProbe,
    };
    try std.testing.expectEqual(@as(i32, -744), ctx.registerAudioOutputIdle("probe", &descriptor));
}

fn ownedHandler(raw: usize) callconv(.c) i32 {
    return @intCast(raw);
}
fn ownedSubmit(handler: r4os.abi.DriverWorkHandler, raw: usize, out: *u32) callconv(.c) i32 {
    std.debug.assert(handler == &ownedHandler and raw == 79);
    out.* = 313;
    return 0;
}
fn ownedWorkFacade() !void {
    const a = r4os.abi;
    const t = std.testing;
    var api: a.DriverApi = undefined;
    api.magic = a.driver_magic;
    api.version = 35;
    api.size = @sizeOf(a.DriverApi);
    api.driver_work_submit_owned = &ownedSubmit;
    const ctx = r4os.r4dev.DriverContext.init(&api);
    var handle: u32 = 99;
    try t.expectEqual(a.err_no_fn, ctx.workSubmitOwned(ownedHandler, 79, &handle));
    try t.expectEqual(@as(u32, 0), handle);
    api.version = a.driver_api_owned_work_version;
    api.size = 655;
    try t.expectEqual(a.err_no_fn, ctx.workSubmitOwned(ownedHandler, 79, &handle));
    api.size = 656;
    try t.expectEqual(@as(i32, 0), ctx.workSubmitOwned(ownedHandler, 79, &handle));
    try t.expectEqual(@as(u32, 313), handle);
    api.driver_work_submit_owned = null;
    try t.expectEqual(a.err_no_fn, ctx.workSubmitOwned(ownedHandler, 79, &handle));
    try t.expectEqual(@as(u32, 0), handle);
}

fn bootHoldProbe(input: *const r4os.abi.GfxBootHoldRequest, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(input.generation == 0x100000000079 and input.reference.generation == 0x200000079);
    output.* = .{ .generation = input.generation + 1, .retained = 1 };
    return r4os.abi.gfx_output_ok;
}
fn bootFinishProbe(generation: u64, operation: u32, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(generation == 0x10000000007a and operation == 2);
    output.* = .{ .generation = generation, .retained = 1, .outcome = r4os.abi.gfx_output_outcome_lost };
    return r4os.abi.gfx_output_ok;
}
fn prepareHeldProbe(input: *const r4os.abi.GfxNativeRegistration, generation: u64, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(generation == 0x10000000007a and input.context == 0x200000000079);
    output.* = .{ .generation = generation, .retained = 1, .outcome = r4os.abi.gfx_output_outcome_validated };
    return r4os.abi.gfx_output_ok;
}
fn bootLegacyQuery(output: *r4os.abi.GfxDriverDisplayApi) callconv(.c) i32 {
    const legacy: r4os.abi.GfxDriverDisplayApi = .{ .size = 40 };
    @memcpy(@as([*]u8, @ptrCast(output))[0..40], std.mem.asBytes(&legacy)[0..40]);
    return r4os.abi.gfx_output_ok;
}
fn terminalReleaseProbe(input: *const r4os.abi.GfxBackendBinding, generation: u64, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(input.adapter_id == 79 and input.device_generation == 0x200000082 and generation == 0x100000000082);
    std.debug.assert(output.version == 1 and output.size == @sizeOf(r4os.abi.GfxNativeState));
    output.* = .{ .generation = generation, .retained = 0, .outcome = r4os.abi.gfx_output_outcome_lost };
    return r4os.abi.gfx_output_ok;
}
fn bootDisplayFacade() !void {
    const a = r4os.abi;
    const t = std.testing;
    try t.expectEqual(@as(usize, 40), @offsetOf(a.GfxDriverDisplayApi, "boot_hold"));
    try t.expectEqual(@as(usize, 48), @offsetOf(a.GfxDriverDisplayApi, "boot_finish"));
    try t.expectEqual(@as(usize, 56), @offsetOf(a.GfxDriverDisplayApi, "prepare_held"));
    // This fixture verifies the original 64-byte prefix; later slots append.
    try t.expect(@sizeOf(a.GfxDriverDisplayApi) >= 64);
    try t.expectEqual(@as(usize, 56), @sizeOf(a.GfxBootHoldRequest));
    var table = r4os.driver_display.Context{ .table = .{ .boot_hold = @intFromPtr(&bootHoldProbe), .boot_finish = @intFromPtr(&bootFinishProbe), .prepare_held = @intFromPtr(&prepareHeldProbe) } };
    var state: a.GfxNativeState = .{ .generation = 79 };
    const request: a.GfxBootHoldRequest = .{ .generation = 0x100000000079, .reference = .{ .id = 7, .generation = 0x200000079 } };
    for ([_]u32{ 40, 47 }) |size| {
        table.table.size = size;
        try t.expectEqual(a.err_no_fn, table.bootHold(&request, &state));
        try t.expectEqual(@as(u64, 79), state.generation);
    }
    table.table.size = 48;
    try t.expectEqual(a.gfx_output_ok, table.bootHold(&request, &state));
    try t.expectEqual(@as(u64, 0x10000000007a), state.generation);
    table.table.size = 55;
    try t.expectEqual(a.err_no_fn, table.bootFinish(state.generation, 2, &state));
    table.table.size = 56;
    try t.expectEqual(a.gfx_output_ok, table.bootFinish(state.generation, 2, &state));
    try t.expectEqual(@as(u32, 1), state.retained);
    try t.expectEqual(a.gfx_output_outcome_lost, state.outcome);
    table.table.boot_finish = 0;
    try t.expectEqual(a.err_no_fn, table.bootFinish(state.generation, 2, &state));
    const candidate: a.GfxNativeRegistration = .{ .context = 0x200000000079 };
    for ([_]u32{ 56, 63 }) |size| {
        table.table.size = size;
        try t.expectEqual(a.err_no_fn, table.prepareHeld(&candidate, state.generation, &state));
        try t.expectEqual(a.gfx_output_outcome_lost, state.outcome);
    }
    table.table.size = 64;
    try t.expectEqual(a.gfx_output_ok, table.prepareHeld(&candidate, state.generation, &state));
    try t.expectEqual(a.gfx_output_outcome_validated, state.outcome);
    try t.expectEqual(@as(u64, 0x10000000007a), state.generation);
    table.table.prepare_held = 0;
    try t.expectEqual(a.err_no_fn, table.prepareHeld(&candidate, state.generation, &state));
    var api: a.DriverApi = undefined;
    api.magic = a.driver_magic;
    api.reserved = 0;
    api.version = 28;
    api.size = 592;
    api.gfx_display_query = bootLegacyQuery;
    const context = r4os.r4dev.DriverContext.init(&api);
    const old = context.graphicsDisplay() orelse return error.LegacyDisplayRejected;
    try t.expectEqual(@as(u32, 40), old.table.size);
    try t.expectEqual(a.err_no_fn, old.bootHold(&request, &state));
    try t.expectEqual(a.err_no_fn, old.prepareHeld(&candidate, state.generation, &state));
    try t.expectEqual(@as(usize, 120), @offsetOf(a.GfxDriverDisplayApi, "device_reset"));
    try t.expectEqual(@as(usize, 128), @offsetOf(a.GfxDriverDisplayApi, "prepare_reset"));
    try t.expectEqual(@as(usize, 136), @offsetOf(a.GfxDriverDisplayApi, "terminal_release"));
    const backend: a.GfxBackendBinding = .{ .adapter_id = 79, .device_generation = 0x200000082, .reset_generation = 7 };
    table.table.terminal_release = @intFromPtr(&terminalReleaseProbe);
    const saved_state = state;
    for ([_]u32{ 40, 136, 137, 143 }) |capacity| {
        table.table.size = capacity;
        try t.expect(!table.supportsTerminalRelease());
        try t.expectEqual(a.err_no_fn, table.releaseTerminal(&backend, 0x100000000082, &state));
        try t.expectEqualDeep(saved_state, state);
    }
    table.table.size = @sizeOf(a.GfxDriverDisplayApi);
    table.table.version = 2;
    try t.expectEqual(a.err_no_fn, table.releaseTerminal(&backend, 0x100000000082, &state));
    table.table.version = 1;
    try t.expect(table.supportsTerminalRelease());
    try t.expectEqual(a.gfx_output_ok, table.releaseTerminal(&backend, 0x100000000082, &state));
    try t.expectEqual(@as(u32, 0), state.retained);
    try t.expectEqual(@as(u64, 0x100000000082), state.generation);
    try t.expectEqual(a.gfx_output_outcome_lost, state.outcome);
    table.table.terminal_release = 0;
    try t.expectEqual(a.err_no_fn, table.releaseTerminal(&backend, 0x100000000082, &state));
    try t.expectEqual(@as(usize, 144), @offsetOf(a.GfxDriverDisplayApi, "resume_headless"));
    table.table.resume_headless = @intFromPtr(&terminalReleaseProbe);
    const saved_resume = state;
    for ([_]u32{ 40, 136, 144, 145, 151 }) |capacity| {
        table.table.size = capacity;
        try t.expect(!table.supportsHeadlessResume());
        try t.expectEqual(a.err_no_fn, table.resumeHeadless(&backend, 0x100000000082, &state));
        try t.expectEqualDeep(saved_resume, state);
    }
    table.table.size = 152;
    table.table.version = 2;
    try t.expectEqual(a.err_no_fn, table.resumeHeadless(&backend, 0x100000000082, &state));
    table.table.version = 1;
    try t.expect(table.supportsHeadlessResume());
    try t.expectEqual(a.gfx_output_ok, table.resumeHeadless(&backend, 0x100000000082, &state));
    try t.expectEqual(@as(u64, 0x100000000082), state.generation);
    table.table.resume_headless = 0;
    try t.expectEqual(a.err_no_fn, table.resumeHeadless(&backend, 0x100000000082, &state));
}

const driver_thread_handle: u64 = 0x2000000000079;
fn driverThreadHandler(value: usize) callconv(.c) i32 {
    return if (value == 0x100000000037) 79 else -1;
}
fn driverThreadStart(input: *const r4os.abi.DriverThreadRequest, output: *u64) callconv(.c) i32 {
    std.debug.assert(input.version == 1 and input.size == 32 and input.reserved == 0 and input.flags == r4os.abi.driver_thread_flag_parallel);
    const callback: *const fn (usize) callconv(.c) i32 = @ptrFromInt(input.handler);
    std.debug.assert(callback(input.context) == 79);
    output.* = driver_thread_handle;
    return 0;
}
fn driverThreadStop(handle: u64) callconv(.c) i32 {
    std.debug.assert(handle == driver_thread_handle);
    return r4os.abi.driver_thread_error_closed;
}
fn driverThreadJoin(handle: u64, timeout: u64, output: *i32) callconv(.c) i32 {
    std.debug.assert(handle == driver_thread_handle and timeout == 0x300000000091 and output.* == 0);
    return r4os.abi.driver_thread_error_timeout;
}
fn driverThreadRelease(handle: u64) callconv(.c) i32 {
    std.debug.assert(handle == driver_thread_handle);
    return r4os.abi.driver_thread_error_busy;
}
fn driverThreadStatus(handle: u64, output: *r4os.abi.DriverThreadStatus) callconv(.c) i32 {
    std.debug.assert(handle == driver_thread_handle);
    output.* = .{ .handle = handle, .owner_epoch = 0x100000000001, .task_generation = 0x200000000001, .task_id = 17, .result = -79 };
    return 0;
}
fn driverThreadCurrent() callconv(.c) u64 {
    return driver_thread_handle;
}
fn driverThreadSleep(ticks: u64) callconv(.c) i32 {
    std.debug.assert(ticks == std.math.maxInt(u64));
    return r4os.abi.driver_thread_error_cancelled;
}
fn driverThreadStats(output: *r4os.abi.DriverThreadStats) callconv(.c) i32 {
    output.* = .{ .owner_epoch = 0x100000000001, .records = 0x100000000003, .waiters = 2, .closing = 1 };
    return 0;
}
fn driverThreadAbort(result: i32) callconv(.c) i32 {
    std.debug.assert(result == -76001);
    return r4os.abi.driver_thread_error_busy;
}
fn driverThreadRequest(output: *r4os.abi.DriverThreadRequest) callconv(.c) i32 {
    output.* = .{ .handler = 0xffffc00000007900, .context = 0x200000000079, .flags = r4os.abi.driver_thread_flag_abortable };
    return r4os.abi.driver_thread_error_context;
}
fn driverThreadQuery(output: *r4os.abi.DriverThreadApi) callconv(.c) i32 {
    output.* = .{ .start = @intFromPtr(&driverThreadStart), .stop = @intFromPtr(&driverThreadStop), .join = @intFromPtr(&driverThreadJoin), .release = @intFromPtr(&driverThreadRelease), .status = @intFromPtr(&driverThreadStatus), .current = @intFromPtr(&driverThreadCurrent), .sleep_ticks = @intFromPtr(&driverThreadSleep), .stats = @intFromPtr(&driverThreadStats) };
    return 0;
}
fn driverThreadLegacyQuery(output: *r4os.abi.DriverThreadApi) callconv(.c) i32 {
    var legacy: r4os.abi.DriverThreadApi = .{ .size = r4os.abi.driver_thread_api_min_bytes, .current = @intFromPtr(&driverThreadCurrent) };
    @memcpy(@as([*]u8, @ptrCast(output))[0..r4os.abi.driver_thread_api_min_bytes], std.mem.asBytes(&legacy)[0..r4os.abi.driver_thread_api_min_bytes]);
    return 0;
}
test "driver threads preserve v31 prefix, full identities, optional callbacks and provider errors" {
    const a = r4os.abi;
    try std.testing.expectEqual(@as(usize, 616), @offsetOf(a.DriverApi, "thread_query"));
    try std.testing.expectEqual(@as(usize, 624), @offsetOf(a.DriverApi, "thread_query") + @sizeOf(u64));
    var api: a.DriverApi = undefined;
    api.version = 31;
    api.size = 616;
    const driver = r4os.r4dev.DriverContext.init(&api);
    try std.testing.expect(driver.threads() == null);
    api.version = 32;
    try std.testing.expect(driver.threads() == null);
    api.size = 624;
    api.thread_query = null;
    try std.testing.expect(driver.threads() == null);
    api.thread_query = driverThreadQuery;
    var service = driver.threads() orelse return error.NoThreads;
    var request: a.DriverThreadRequest = .{};
    try std.testing.expect(!service.hasCurrentRequest());
    try std.testing.expectEqual(a.err_no_fn, service.currentRequest(&request));
    service.table.current_request = @intFromPtr(&driverThreadRequest);
    for ([_]u32{ 72, 80, 87 }) |capacity| {
        service.table.size = capacity;
        try std.testing.expect(!service.hasCurrentRequest());
        try std.testing.expectEqual(a.err_no_fn, service.currentRequest(&request));
        try std.testing.expectEqual(@as(u64, 0), request.handler);
    }
    service.table.size = 88;
    try std.testing.expect(service.hasCurrentRequest());
    try std.testing.expectEqual(a.driver_thread_error_context, service.currentRequest(&request));
    try std.testing.expectEqual(@as(u64, 0xffffc00000007900), request.handler);
    try std.testing.expectEqual(@as(u64, 0x200000000079), request.context);
    try std.testing.expectEqual(a.driver_thread_flag_abortable, request.flags);
    try std.testing.expect(!service.canAbort());
    try std.testing.expectEqual(a.err_no_fn, service.abortCurrent(-76001));
    service.table.abort_current = @intFromPtr(&driverThreadAbort);
    try std.testing.expect(service.canAbort());
    try std.testing.expectEqual(a.driver_thread_error_busy, service.abortCurrent(-76001));
    service.table.size = a.driver_thread_api_min_bytes;
    try std.testing.expect(!service.canAbort());
    var rejected_handle: u64 = 99;
    try std.testing.expectEqual(a.err_no_fn, service.start(driverThreadHandler, 0, a.driver_thread_flag_abortable, &rejected_handle));
    try std.testing.expectEqual(@as(u64, 0), rejected_handle);
    service.table.size = @sizeOf(a.DriverThreadApi);
    var handle: u64 = 99;
    try std.testing.expectEqual(@as(i32, 0), service.start(driverThreadHandler, 0x100000000037, a.driver_thread_flag_parallel, &handle));
    try std.testing.expectEqual(driver_thread_handle, handle);
    try std.testing.expectEqual(a.driver_thread_error_closed, service.stop(handle));
    var result: i32 = 123;
    try std.testing.expectEqual(a.driver_thread_error_timeout, service.join(handle, 0x300000000091, &result));
    try std.testing.expectEqual(@as(i32, 0), result);
    try std.testing.expectEqual(a.driver_thread_error_busy, service.release(handle));
    var status: a.DriverThreadStatus = .{};
    try std.testing.expectEqual(@as(i32, 0), service.status(handle, &status));
    try std.testing.expectEqual(@as(u64, 0x200000000001), status.task_generation);
    try std.testing.expectEqual(@as(i32, -79), status.result);
    try std.testing.expectEqual(handle, service.current());
    try std.testing.expectEqual(a.driver_thread_error_cancelled, service.sleepTicks(std.math.maxInt(u64)));
    var stats: a.DriverThreadStats = .{};
    try std.testing.expectEqual(@as(i32, 0), service.stats(&stats));
    try std.testing.expectEqual(@as(u64, 0x100000000003), stats.records);
    service.table.size = @offsetOf(a.DriverThreadApi, "join");
    try std.testing.expectEqual(a.driver_thread_error_closed, service.stop(handle));
    result = 123;
    try std.testing.expectEqual(a.err_no_fn, service.join(handle, 1, &result));
    try std.testing.expectEqual(@as(i32, 0), result);
    service.table.version = 2;
    try std.testing.expectEqual(a.err_no_fn, service.start(driverThreadHandler, 0, 0, &handle));
    try std.testing.expectEqual(@as(u64, 0), handle);
    try std.testing.expectEqual(@as(u64, 0), service.current());
    api.thread_query = driverThreadLegacyQuery;
    const legacy = driver.threads() orelse return error.LegacyThreadsRejected;
    try std.testing.expectEqual(driver_thread_handle, legacy.current());
    try std.testing.expect(!legacy.canAbort());
    try std.testing.expect(!legacy.hasCurrentRequest());
    try std.testing.expectEqual(a.err_no_fn, legacy.currentRequest(&request));
    try std.testing.expectEqual(a.err_no_fn, legacy.abortCurrent(-76001));
}

const semaphore_handle: u64 = 0x1000000000079;
fn semaphoreCreate(initial: u32, maximum: u32, handle: *u64) callconv(.c) i32 {
    std.debug.assert(initial == 0x80000001 and maximum == 0xffffffff and handle.* == 0);
    handle.* = semaphore_handle;
    return 0;
}
fn semaphoreAcquire(handle: u64, ticks: u64) callconv(.c) i32 {
    std.debug.assert(handle == semaphore_handle and ticks == std.math.maxInt(u64));
    return r4os.abi.driver_semaphore_error_timeout;
}
fn semaphoreRelease(handle: u64) callconv(.c) i32 {
    std.debug.assert(handle == semaphore_handle);
    return r4os.abi.driver_semaphore_error_overflow;
}
fn semaphoreDestroy(handle: u64) callconv(.c) i32 {
    std.debug.assert(handle == semaphore_handle);
    return r4os.abi.driver_semaphore_error_busy;
}
fn semaphoreStatus(handle: u64, output: *r4os.abi.DriverSemaphoreStatus) callconv(.c) i32 {
    std.debug.assert(handle == semaphore_handle);
    output.* = .{ .handle = handle, .owner_epoch = 0x200000000079, .maximum = 0xffffffff, .queued_waiters = 3, .active_acquires = 4 };
    return 0;
}
fn semaphoreStats(output: *r4os.abi.DriverSemaphoreStats) callconv(.c) i32 {
    output.* = .{ .records = 0x300000000079, .closing = 1 };
    return 0;
}
fn semaphoreFlags() callconv(.c) u32 {
    return r4os.abi.driver_semaphore_context_irq;
}
fn semaphoreQuery(output: *r4os.abi.DriverSemaphoreApi) callconv(.c) i32 {
    output.* = .{ .create = @intFromPtr(&semaphoreCreate), .acquire = @intFromPtr(&semaphoreAcquire), .release = @intFromPtr(&semaphoreRelease), .destroy = @intFromPtr(&semaphoreDestroy), .status = @intFromPtr(&semaphoreStatus), .stats = @intFromPtr(&semaphoreStats), .context_flags = @intFromPtr(&semaphoreFlags) };
    return 0;
}
test "driver semaphores preserve v32 prefix, full counters and deadlines, and failed operation ownership" {
    const a = r4os.abi;
    try std.testing.expectEqual(@as(usize, 624), @offsetOf(a.DriverApi, "semaphore_query"));
    try std.testing.expectEqual(@as(usize, 632), @offsetOf(a.DriverApi, "semaphore_query") + @sizeOf(u64));
    var api: a.DriverApi = undefined;
    api.version = 32;
    api.size = 624;
    const driver = r4os.r4dev.DriverContext.init(&api);
    try std.testing.expect(driver.semaphores() == null);
    api.version = 33;
    try std.testing.expect(driver.semaphores() == null);
    api.size = 632;
    api.semaphore_query = null;
    try std.testing.expect(driver.semaphores() == null);
    api.semaphore_query = semaphoreQuery;
    var sem = driver.semaphores() orelse return error.NoSemaphores;
    var handle: u64 = 79;
    try std.testing.expectEqual(@as(i32, 0), sem.create(0x80000001, 0xffffffff, &handle));
    try std.testing.expectEqual(semaphore_handle, handle);
    try std.testing.expectEqual(a.driver_semaphore_error_timeout, sem.acquire(handle, std.math.maxInt(u64)));
    try std.testing.expectEqual(a.driver_semaphore_error_overflow, sem.release(handle));
    try std.testing.expectEqual(a.driver_semaphore_error_busy, sem.destroy(handle));
    var status: a.DriverSemaphoreStatus = .{};
    try std.testing.expectEqual(@as(i32, 0), sem.status(handle, &status));
    try std.testing.expectEqual(@as(u64, 0x200000000079), status.owner_epoch);
    try std.testing.expectEqual(@as(u32, 0xffffffff), status.maximum);
    var stats: a.DriverSemaphoreStats = .{};
    try std.testing.expectEqual(@as(i32, 0), sem.stats(&stats));
    try std.testing.expectEqual(@as(u64, 0x300000000079), stats.records);
    try std.testing.expectEqual(a.driver_semaphore_context_irq, sem.contextFlags());
    sem.table.size = @offsetOf(a.DriverSemaphoreApi, "destroy");
    try std.testing.expectEqual(a.driver_semaphore_error_overflow, sem.release(handle));
    try std.testing.expectEqual(a.err_no_fn, sem.destroy(handle));
    try std.testing.expectEqual(@as(u32, 0), sem.contextFlags());
    sem.table.version = 2;
    try std.testing.expectEqual(a.err_no_fn, sem.create(0, 1, &handle));
    try std.testing.expectEqual(@as(u64, 0), handle);
    sem.table = .{};
    try std.testing.expectEqual(a.err_no_fn, sem.acquire(semaphore_handle, 0));
    try std.testing.expectEqual(a.err_no_fn, sem.status(semaphore_handle, &status));
    try std.testing.expectEqual(a.err_no_fn, sem.stats(&stats));
}

fn driverClockProbe(out: *r4os.abi.MonotonicClockInfo) callconv(.c) i32 {
    out.* = .{ .flags = r4os.abi.monotonic_clock_flag_valid, .instant_ns = 0x10000000003, .resolution_ns = 10000001 };
    return 1;
}
test "driver monotonic clock preserves the old table prefix and nanosecond payload" {
    const a = r4os.abi;
    try std.testing.expectEqual(@as(usize, 608), @offsetOf(a.DriverApi, "monotonic_clock"));
    try std.testing.expectEqual(@as(usize, 616), @offsetOf(a.DriverApi, "monotonic_clock") + @sizeOf(u64));
    var api: a.DriverApi = undefined;
    api.version = 30;
    api.size = @offsetOf(a.DriverApi, "monotonic_clock");
    const driver = r4os.r4dev.DriverContext.init(&api);
    var clock: a.MonotonicClockInfo = .{ .instant_ns = 77 };
    try std.testing.expectEqual(a.err_no_fn, driver.monotonicClock(&clock));
    try std.testing.expectEqual(@as(u64, 0), clock.instant_ns);
    api.version = 31;
    try std.testing.expectEqual(a.err_no_fn, driver.monotonicClock(&clock));
    api.size += 8;
    api.monotonic_clock = null;
    try std.testing.expectEqual(a.err_no_fn, driver.monotonicClock(&clock));
    api.monotonic_clock = driverClockProbe;
    try std.testing.expectEqual(@as(i32, 1), driver.monotonicClock(&clock));
    try std.testing.expectEqual(@as(u64, 0x10000000003), clock.instant_ns);
    try std.testing.expectEqual(@as(u64, 10000001), clock.resolution_ns);
}

fn driverHeapAllocateProbe(bytes: u64, alignment: u32, out: *r4os.abi.DriverHeapAllocation) callconv(.c) i32 {
    std.debug.assert(bytes == 0x100000001 and alignment == 4096);
    out.* = .{ .handle = 0x200000003, .cpu_address = 0xffffc00000001000, .byte_length = bytes, .alignment = alignment };
    return 0;
}
fn driverHeapReleaseProbe(handle: u64) callconv(.c) i32 {
    std.debug.assert(handle == 0x200000003);
    return r4os.abi.driver_heap_error_release;
}
fn driverHeapQueryProbe(out: *r4os.abi.DriverHeapApi) callconv(.c) i32 {
    out.* = .{ .allocate = @intFromPtr(&driverHeapAllocateProbe), .release = @intFromPtr(&driverHeapReleaseProbe) };
    return 0;
}
test "driver CPU heap facade preserves v29 prefix, optional functions and full 64-bit identities" {
    const a = r4os.abi;
    try std.testing.expectEqual(@as(usize, 600), @offsetOf(a.DriverApi, "heap_query"));
    try std.testing.expectEqual(@as(usize, 608), @offsetOf(a.DriverApi, "heap_query") + @sizeOf(u64));
    var api: a.DriverApi = undefined;
    api.magic = a.driver_magic;
    api.version = 29;
    api.size = @offsetOf(a.DriverApi, "heap_query");
    const driver = r4os.r4dev.DriverContext.init(&api);
    try std.testing.expect(driver.apiCompatible() and driver.heap() == null);
    api.version = 30;
    try std.testing.expect(driver.heap() == null);
    api.size += 8;
    api.heap_query = null;
    try std.testing.expect(driver.heap() == null);
    api.heap_query = driverHeapQueryProbe;
    var heap = driver.heap().?;
    var allocation: a.DriverHeapAllocation = .{};
    try std.testing.expectEqual(a.driver_heap_ok, heap.allocate(0x100000001, 4096, &allocation));
    try std.testing.expectEqual(@as(u64, 0x100000001), allocation.byte_length);
    try std.testing.expectEqual(@as(u64, 0xffffc00000001000), allocation.cpu_address);
    try std.testing.expectEqual(a.driver_heap_error_release, heap.release(allocation.handle));
    var stats: a.DriverHeapStats = .{};
    try std.testing.expectEqual(a.err_no_fn, heap.stats(&stats));
    heap.table.size = @offsetOf(a.DriverHeapApi, "release");
    try std.testing.expectEqual(a.err_no_fn, heap.release(1));
    heap.table.version = 2;
    try std.testing.expectEqual(a.err_no_fn, heap.allocate(1, 16, &allocation));
}

fn driverResourceReadProbe(handle: u64, offset: u64, out: [*]u8, bytes: u32, deadline: u64) callconv(.c) i32 {
    std.debug.assert(handle == 0x100000001 and offset == 0x200000003 and deadline == 0x300000005 and bytes == 1);
    out[0] = 79;
    return 1;
}
fn driverResourceQueryProbe(out: *r4os.abi.DriverResourceApi) callconv(.c) i32 {
    const legacy: r4os.abi.DriverResourceApi = .{ .size = 32, .read_at = @intFromPtr(&driverResourceReadProbe) };
    @memcpy(@as([*]u8, @ptrCast(out))[0..32], std.mem.asBytes(&legacy)[0..32]);
    return 0;
}
fn driverResourceAcpiStatProbe(signature: u32, index: u32, output: *r4os.abi.DriverFirmwareTableInfo) callconv(.c) i32 {
    std.debug.assert(signature == std.mem.readInt(u32, "VFCT", .little) and index == 3);
    output.* = .{ .handle = 0x100000001, .generation = 1, .byte_length = 4096, .signature = signature, .revision = 1 };
    return 0;
}
test "driver resource facade preserves old prefix, optional slots and 64-bit ranges" {
    const a = r4os.abi;
    var api: a.DriverApi = undefined;
    api.magic = a.driver_magic;
    api.version = 28;
    api.size = @offsetOf(a.DriverApi, "resource_query");
    const driver = r4os.r4dev.DriverContext.init(&api);
    try std.testing.expect(driver.resources() == null);
    api.version = 29;
    try std.testing.expect(driver.resources() == null);
    api.size += 8;
    api.resource_query = null;
    try std.testing.expect(driver.resources() == null);
    api.resource_query = driverResourceQueryProbe;
    var driver_resources = driver.resources().?;
    var byte: [1]u8 = .{0};
    try std.testing.expectEqual(@as(i32, 1), driver_resources.readAt(0x100000001, 0x200000003, &byte, 0x300000005));
    try std.testing.expectEqual(@as(u8, 79), byte[0]);
    try std.testing.expectEqual(@as(u32, 32), driver_resources.table.size);
    try std.testing.expect(!driver_resources.supportsAcpi());
    var firmware: a.DriverFirmwareTableInfo = .{};
    try std.testing.expectEqual(a.err_no_fn, driver_resources.acpiStat("VFCT".*, 3, &firmware));
    driver_resources.table.acpi_stat = @intFromPtr(&driverResourceAcpiStatProbe);
    driver_resources.table.acpi_read_at = @intFromPtr(&driverResourceReadProbe);
    driver_resources.table.size = 40;
    try std.testing.expect(!driver_resources.supportsAcpi());
    try std.testing.expectEqual(a.driver_resource_ok, driver_resources.acpiStat("VFCT".*, 3, &firmware));
    try std.testing.expectEqual(@as(u64, 0x100000001), firmware.handle);
    try std.testing.expectEqual(a.err_no_fn, driver_resources.acpiReadAt(firmware.handle, 0x200000003, &byte, 0x300000005));
    driver_resources.table.size = 48;
    try std.testing.expect(driver_resources.supportsAcpi());
    try std.testing.expectEqual(@as(i32, 1), driver_resources.acpiReadAt(firmware.handle, 0x200000003, &byte, 0x300000005));
    try std.testing.expectEqual(a.driver_resource_error_invalid, driver_resources.acpiReadAt(firmware.handle, 0, byte[0..0], 10));
    driver_resources.table.size = @offsetOf(a.DriverResourceApi, "read_at");
    try std.testing.expectEqual(a.err_no_fn, driver_resources.readAt(1, 0, &byte, 10));
    try std.testing.expectEqual(std.math.maxInt(u64), driver_resources.nowNs());
    var info: a.DriverResourceInfo = .{};
    try std.testing.expectEqual(a.err_no_fn, driver_resources.stat("firmware", &info));
}

var now_ticks: u64 = 10;
var process_active = false;
var process_done = false;
var process_exit: i32 = 0;
var process_generation: u64 = 0;
var process_slots: u32 = 0;
var thread_active = false;
var thread_exit_code: i32 = 0;
var thread_slots: u32 = 0;
var vm_active = false;
var vm_wrong_owner = false;
var vm_slots: u32 = 0;
var io_active = false;
var io_complete = false;
var io_slots: u32 = 0;
var fake_table: r4os.abi.R4XStartR4Sys = .{};
var fake_desk_table: r4os.abi.R4XStartR4Desk = .{};
var fake_context: r4os.abi.R4XStartContext = .{};

fn fakeTicks() callconv(.c) u64 {
    return now_ticks;
}
fn fakeTimeState(out: *r4os.abi.TimeState) callconv(.c) void {
    out.* = .{ .monotonic_ticks = now_ticks, .monotonic_hz = 1000, .valid = 1 };
}
fn fakeYield() callconv(.c) void {
    now_ticks += 1;
}

fn fakeProgramSpawn(_: [*:0]const u8, _: [*:0]const u8, _: u32) callconv(.c) i32 {
    if (process_active) return -3;
    process_active = true;
    process_done = false;
    process_exit = 0;
    process_slots += 1;
    return 41;
}
fn fakeProgramInstance(index: u32, out: *r4os.abi.ProgramInstanceInfo) callconv(.c) i32 {
    if (!process_active or index != 0) return 0;
    out.* = .{ .id = 41, .state = if (process_done) 2 else 0, .exit_code = process_exit };
    return 1;
}
fn fakeProgramRequestClose(id: u32) callconv(.c) i32 {
    if (!process_active or id != 41) return -1;
    process_done = true;
    return 0;
}
fn fakeProgramKill(id: u32) callconv(.c) i32 {
    if (!process_active or id != 41) return -1;
    process_done = true;
    process_exit = -9;
    return 0;
}
fn fakeProgramReap(id: u32) callconv(.c) i32 {
    if (!process_active or id != 41) return -1;
    if (!process_done) return -2;
    process_active = false;
    process_slots -= 1;
    return process_exit;
}

fn fakeHandleValid(handle: *const r4os.abi.ProgramProcessHandle) i32 {
    if (handle.instance_id == 0 or handle.generation == 0 or handle.reserved != 0) return r4os.abi.program_handle_error_invalid;
    if (!process_active) return r4os.abi.program_handle_error_not_found;
    if (handle.instance_id != 41 or handle.generation != process_generation) return r4os.abi.program_handle_error_stale;
    return r4os.abi.program_handle_ok;
}

fn fakeProgramSpawnHandle(_: [*:0]const u8, _: [*:0]const u8, _: u32, out: *r4os.abi.ProgramProcessHandle) callconv(.c) i32 {
    if (process_active) return r4os.abi.program_handle_error_no_memory;
    process_generation += 1;
    process_active = true;
    process_done = false;
    process_exit = 0;
    process_slots += 1;
    out.* = .{ .instance_id = 41, .generation = process_generation };
    return r4os.abi.program_handle_ok;
}

fn fakeProgramSpawnWithConsoleHostHandle(path: [*:0]const u8, args: [*:0]const u8, policy: u32, _: u32, out: *r4os.abi.ProgramProcessHandle) callconv(.c) i32 {
    return fakeProgramSpawnHandle(path, args, policy, out);
}

fn fakeProgramOpenHandle(id: u32, out: *r4os.abi.ProgramProcessHandle) callconv(.c) i32 {
    if (!process_active or id != 41) return r4os.abi.program_handle_error_not_found;
    out.* = .{ .instance_id = id, .generation = process_generation };
    return r4os.abi.program_handle_ok;
}

fn fakeProgramHandleStatus(handle: *const r4os.abi.ProgramProcessHandle, out: *r4os.abi.ProgramInstanceInfo) callconv(.c) i32 {
    const status = fakeHandleValid(handle);
    if (status != r4os.abi.program_handle_ok) return status;
    out.* = .{ .id = 41, .state = if (process_done) 2 else 0, .exit_code = process_exit };
    return status;
}

fn fakeProgramHandleRequestClose(handle: *const r4os.abi.ProgramProcessHandle) callconv(.c) i32 {
    const status = fakeHandleValid(handle);
    if (status != r4os.abi.program_handle_ok) return status;
    process_done = true;
    return status;
}

fn fakeProgramHandleKill(handle: *const r4os.abi.ProgramProcessHandle) callconv(.c) i32 {
    const status = fakeHandleValid(handle);
    if (status != r4os.abi.program_handle_ok) return status;
    process_done = true;
    process_exit = -9;
    return status;
}

fn fakeCompletion(handle: *const r4os.abi.ProgramProcessHandle) r4os.abi.ProgramProcessCompletion {
    return .{
        .handle = handle.*,
        .sequence = process_generation,
        .start_tick = 10,
        .finish_tick = now_ticks,
        .exit_code = process_exit,
        .output_revision = 1,
        .output_length = 2,
        .flags = r4os.abi.program_completion_flag_ready | r4os.abi.program_completion_flag_output | r4os.abi.program_completion_flag_owner,
        .exit_reason = if (process_exit == -9) r4os.abi.program_exit_reason_killed else r4os.abi.program_exit_reason_close,
    };
}

fn fakeProgramHandleWait(handle: *const r4os.abi.ProgramProcessHandle, timeout: u64, out: *r4os.abi.ProgramProcessCompletion) callconv(.c) i32 {
    const status = fakeHandleValid(handle);
    if (status != r4os.abi.program_handle_ok) return status;
    if (!process_done and timeout == 0) return r4os.abi.program_handle_error_timeout;
    if (!process_done) process_done = true;
    out.* = fakeCompletion(handle);
    return status;
}

fn fakeProgramHandleReap(handle: *const r4os.abi.ProgramProcessHandle, out: *r4os.abi.ProgramProcessCompletion) callconv(.c) i32 {
    const status = fakeHandleValid(handle);
    if (status != r4os.abi.program_handle_ok) return status;
    if (!process_done) return r4os.abi.program_handle_error_would_block;
    out.* = fakeCompletion(handle);
    process_active = false;
    process_slots -= 1;
    return status;
}

fn fakeProgramCompletionRead(handle: *const r4os.abi.ProgramProcessHandle, offset: u32, out: [*]u8, capacity: u32, out_read: *u32) callconv(.c) i32 {
    const status = fakeHandleValid(handle);
    if (status != r4os.abi.program_handle_ok) return status;
    if (!process_done) return r4os.abi.program_handle_error_would_block;
    const text = "OK";
    if (offset > text.len) return r4os.abi.program_handle_error_output_range;
    const count: usize = @min(@as(usize, capacity), text.len - offset);
    if (count != 0) @memcpy(out[0..count], text[offset .. offset + count]);
    out_read.* = @intCast(count);
    return status;
}

fn unusedThread(_: u64) callconv(.c) i32 {
    return 0;
}
fn fakeThreadCreate(_: r4os.abi.ThreadEntryFn, arg: u64, _: u64, flags: u32, out: *u32) callconv(.c) i32 {
    if (flags != 0) return r4os.abi.thread_error_unsupported;
    if (thread_active) return r4os.abi.thread_error_no_slots;
    thread_active = true;
    thread_exit_code = @intCast(arg);
    thread_slots += 1;
    out.* = 51;
    return r4os.abi.thread_ok;
}
fn fakeThreadCreateHandle(entry: r4os.abi.ThreadEntryFn, arg: u64, stack: u64, flags: u32, out: *r4os.abi.ProgramJoinHandle) callconv(.c) i32 {
    var id: u32 = 0;
    const status = fakeThreadCreate(entry, arg, stack, flags, &id);
    if (status != r4os.abi.thread_ok) return status;
    out.* = .{ .thread_id = id, .instance_id = 1, .thread_generation = 5, .instance_generation = 9 };
    return status;
}
fn fakeComputeCreate(entry: r4os.abi.ThreadEntryFn, arg: u64, stack: u64, flags: u32, out: *r4os.abi.ProgramJoinHandle) callconv(.c) i32 {
    std.debug.assert(flags == r4os.abi.thread_create_flag_compute_worker);
    std.debug.assert(entry == &unusedThread and arg == 85 and stack == 256 * 1024);
    return fakeThreadCreateHandle(entry, arg, stack, 0, out);
}
fn fakeThreadExit(_: i32) callconv(.c) void {}
fn fakeThreadCurrent() callconv(.c) u32 {
    return 1;
}
fn fakeThreadStatus(id: u32, out: *r4os.abi.ProgramThreadInfo) callconv(.c) i32 {
    if (!thread_active or id != 51) return r4os.abi.thread_error_not_found;
    out.* = .{ .thread_id = id, .state = r4os.abi.thread_state_running, .flags = r4os.abi.thread_flag_joinable };
    return r4os.abi.thread_ok;
}
fn fakeThreadJoin(id: u32, timeout: u64, out: *i32) callconv(.c) i32 {
    if (!thread_active or id != 51) return r4os.abi.thread_error_not_found;
    if (timeout == 0) return r4os.abi.thread_error_timeout;
    out.* = thread_exit_code;
    thread_active = false;
    thread_slots -= 1;
    return r4os.abi.thread_ok;
}
fn fakeThreadHandleValid(handle: *const r4os.abi.ProgramJoinHandle) bool {
    return handle.thread_id == 51 and handle.instance_id == 1 and
        handle.thread_generation == 5 and handle.instance_generation == 9 and handle.reserved == 0;
}
fn fakeThreadHandleStatus(handle: *const r4os.abi.ProgramJoinHandle, out: *r4os.abi.ProgramThreadInfo) callconv(.c) i32 {
    if (!fakeThreadHandleValid(handle)) return r4os.abi.thread_error_not_found;
    return fakeThreadStatus(handle.thread_id, out);
}
fn fakeThreadHandleJoin(handle: *const r4os.abi.ProgramJoinHandle, timeout: u64, out: *i32) callconv(.c) i32 {
    if (!fakeThreadHandleValid(handle)) return r4os.abi.thread_error_not_found;
    return fakeThreadJoin(handle.thread_id, timeout, out);
}

fn fakeVmReserve(size: u64, _: u64, _: u64, out: *r4os.abi.ProgramVmRegionInfo) callconv(.c) i32 {
    if (vm_active) return r4os.abi.vm_error_table_full;
    vm_active = true;
    vm_slots += 1;
    out.* = .{ .id = 61, .base = 0x100000, .len = size };
    return r4os.abi.vm_ok;
}
fn fakeVmCommit(id: u32, _: u64, len: u64, _: u64) callconv(.c) i32 {
    return if (vm_active and id == 61 and len != 0) r4os.abi.vm_ok else r4os.abi.vm_error_invalid_range;
}
fn fakeVmDecommit(id: u32, _: u64, _: u64) callconv(.c) i32 {
    return if (vm_active and id == 61) r4os.abi.vm_ok else r4os.abi.vm_error_invalid_range;
}
fn fakeVmQuery(id: u32, out: *r4os.abi.ProgramVmRegionInfo) callconv(.c) i32 {
    if (!vm_active or id != 61) return r4os.abi.vm_error_invalid_range;
    out.* = .{ .id = 61, .base = 0x100000, .len = 4096, .committed_bytes = 4096 };
    return r4os.abi.vm_ok;
}
fn fakeVmRelease(id: u32) callconv(.c) i32 {
    if (vm_wrong_owner) return r4os.abi.vm_error_owner_mismatch;
    if (!vm_active or id != 61) return r4os.abi.vm_error_invalid_range;
    vm_active = false;
    vm_slots -= 1;
    return r4os.abi.vm_ok;
}

fn fakeIoRead(_: [*:0]const u8, _: [*]u8, _: u64, _: u32, out: *u32) callconv(.c) i32 {
    if (io_active) return r4os.abi.io_error_no_slots;
    io_active = true;
    io_complete = false;
    io_slots += 1;
    out.* = 71;
    return r4os.abi.io_ok;
}
fn fakeIoWrite(_: [*:0]const u8, _: [*]const u8, _: u64, _: u32, out: *u32) callconv(.c) i32 {
    return fakeIoRead("X", @ptrFromInt(1), 0, 0, out);
}
fn fakeIoStreamWrite(_: [*:0]const u8, _: u64, _: [*]const u8, _: u64, _: u32, out: *u32) callconv(.c) i32 {
    return fakeIoRead("X", @ptrFromInt(1), 0, 0, out);
}
fn fakeIoServiceCall(_: u32, _: u16, _: [*]const u8, _: u32, _: *r4os.abi.ServiceMessageHeader, _: [*]u8, _: u32, _: u64, _: u32, out: *u32) callconv(.c) i32 {
    return fakeIoRead("X", @ptrFromInt(1), 0, 0, out);
}
fn fakeIoStatus(id: u32, out: *r4os.abi.ProgramIoInfo) callconv(.c) i32 {
    if (!io_active or id != 71) return r4os.abi.io_error_not_found;
    out.* = .{ .request_id = id, .state = if (io_complete) r4os.abi.io_state_completed else r4os.abi.io_state_running, .result = if (io_complete) 4 else 0 };
    return r4os.abi.io_ok;
}
fn fakeIoWait(id: u32, timeout: u64, out: *r4os.abi.ProgramIoInfo) callconv(.c) i32 {
    if (!io_active or id != 71) return r4os.abi.io_error_not_found;
    if (timeout == 0 and !io_complete) return r4os.abi.io_error_timeout;
    io_complete = true;
    return fakeIoStatus(id, out);
}
fn fakeIoClose(id: u32) callconv(.c) i32 {
    if (!io_active or id != 71) return r4os.abi.io_error_not_found;
    if (!io_complete) return r4os.abi.io_error_busy;
    io_active = false;
    io_slots -= 1;
    return r4os.abi.io_ok;
}

fn resources() r4os.Resources {
    fake_table = .{};
    fake_desk_table = .{};
    fake_table.ticks = @intFromPtr(&fakeTicks);
    fake_table.time_state = @intFromPtr(&fakeTimeState);
    fake_table.task_yield = @intFromPtr(&fakeYield);
    fake_table.program_spawn = @intFromPtr(&fakeProgramSpawn);
    fake_table.program_instance = @intFromPtr(&fakeProgramInstance);
    fake_table.program_request_close = @intFromPtr(&fakeProgramRequestClose);
    fake_table.program_kill = @intFromPtr(&fakeProgramKill);
    fake_table.program_reap_instance = @intFromPtr(&fakeProgramReap);
    fake_table.program_spawn_handle = @intFromPtr(&fakeProgramSpawnHandle);
    fake_table.program_open_handle = @intFromPtr(&fakeProgramOpenHandle);
    fake_table.program_handle_status = @intFromPtr(&fakeProgramHandleStatus);
    fake_table.program_handle_request_close = @intFromPtr(&fakeProgramHandleRequestClose);
    fake_table.program_handle_kill = @intFromPtr(&fakeProgramHandleKill);
    fake_table.program_handle_wait = @intFromPtr(&fakeProgramHandleWait);
    fake_table.program_handle_reap = @intFromPtr(&fakeProgramHandleReap);
    fake_table.program_completion_read = @intFromPtr(&fakeProgramCompletionRead);
    fake_desk_table.program_spawn_with_console_host_handle = @intFromPtr(&fakeProgramSpawnWithConsoleHostHandle);
    fake_table.thread_create = @intFromPtr(&fakeThreadCreate);
    fake_table.thread_exit = @intFromPtr(&fakeThreadExit);
    fake_table.thread_join = @intFromPtr(&fakeThreadJoin);
    fake_table.thread_current = @intFromPtr(&fakeThreadCurrent);
    fake_table.thread_status = @intFromPtr(&fakeThreadStatus);
    fake_table.thread_create_handle = @intFromPtr(&fakeThreadCreateHandle);
    fake_table.thread_handle_join = @intFromPtr(&fakeThreadHandleJoin);
    fake_table.thread_handle_status = @intFromPtr(&fakeThreadHandleStatus);
    fake_table.vm_reserve = @intFromPtr(&fakeVmReserve);
    fake_table.vm_commit = @intFromPtr(&fakeVmCommit);
    fake_table.vm_decommit = @intFromPtr(&fakeVmDecommit);
    fake_table.vm_release = @intFromPtr(&fakeVmRelease);
    fake_table.vm_query = @intFromPtr(&fakeVmQuery);
    fake_table.io_file_read = @intFromPtr(&fakeIoRead);
    fake_table.io_file_write = @intFromPtr(&fakeIoWrite);
    fake_table.io_file_stream_write = @intFromPtr(&fakeIoStreamWrite);
    fake_table.io_service_call = @intFromPtr(&fakeIoServiceCall);
    fake_table.io_status = @intFromPtr(&fakeIoStatus);
    fake_table.io_wait = @intFromPtr(&fakeIoWait);
    fake_table.io_close = @intFromPtr(&fakeIoClose);
    const bundle = r4os.program.Bundle{ .raw = &fake_context, .sys = &fake_table, .desk = &fake_desk_table };
    return .{ .sys = r4os.r4sys.Context.init(&bundle) };
}

var registry_v2_calls: u32 = 0;
fn registrySummaryV2Peer(out: *r4os.abi.ProgramRegistrySummaryV2) callconv(.c) i32 {
    if (out.version < 2 or out.size < @sizeOf(r4os.abi.ProgramRegistrySummaryV2)) return -1;
    registry_v2_calls += 1;
    out.live_slots = 7;
    return 1;
}
fn registryTestV2Peer(out: *r4os.abi.ProgramRegistrySelfTestResultV2) callconv(.c) i32 {
    if (out.version < 2 or out.size < @sizeOf(r4os.abi.ProgramRegistrySelfTestResultV2)) return -1;
    registry_v2_calls += 1;
    out.flags = 17;
    return 1;
}
test "R4DEV current registry V2 is explicit and unavailable without its group" {
    var bundle = r4os.program.Bundle{ .raw = &fake_context };
    const dev = r4os.r4dev.Context.init(&bundle);
    var summary_v2: r4os.abi.ProgramRegistrySummaryV2 = .{};
    var self_test_v2: r4os.abi.ProgramRegistrySelfTestResultV2 = .{};
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySummaryV2(&summary_v2));
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySelfTestV2(&self_test_v2));

    const performance = r4os.PerformanceView{ .raw = dev };
    try std.testing.expect(performance.programRegistryV2() == null);
    try std.testing.expectEqual(r4os.abi.err_no_group, performance.programRegistrySelfTestV2(&self_test_v2));
    var table: r4os.abi.R4XStartR4Dev = .{ .program_registry_summary_v2 = @intFromPtr(&registrySummaryV2Peer), .program_registry_self_test_v2 = @intFromPtr(&registryTestV2Peer) };
    bundle.dev = &table;
    registry_v2_calls = 0;
    table.size = @offsetOf(r4os.abi.R4XStartR4Dev, "program_registry_summary_v2");
    try std.testing.expectEqual(r4os.abi.err_no_fn, dev.programRegistrySummaryV2(&summary_v2));
    try std.testing.expectEqual(@as(u32, 0), registry_v2_calls);
    table.size = @sizeOf(r4os.abi.R4XStartR4Dev);
    try std.testing.expectEqual(@as(i32, 1), dev.programRegistrySummaryV2(&summary_v2));
    try std.testing.expectEqual(@as(u32, 7), summary_v2.live_slots);
    try std.testing.expectEqual(@as(i32, 1), performance.programRegistrySelfTestV2(&self_test_v2));
    try std.testing.expectEqual(@as(u32, 17), self_test_v2.flags);
    try std.testing.expectEqual(@as(u32, 2), registry_v2_calls);
}

test "ProcessHandle raw remains u32 source compatible" {
    const api = resources();
    var process = r4os.ProcessHandle{ .sys = api.sys, .raw = 73, .owned = true };
    const legacy_id: u32 = process.raw;
    try std.testing.expect(process.raw != 0);
    try std.testing.expectEqual(@as(u32, 73), legacy_id);
    process.raw = 0;
    try std.testing.expectEqual(@as(u32, 0), process.raw);
}

fn fakeCurrentIdentity(out: *r4os.abi.ProgramJoinHandle) callconv(.c) i32 {
    out.* = .{ .thread_id = 17, .instance_id = 31, .thread_generation = 0x10000007939, .instance_generation = 0x20000007939 };
    return r4os.abi.thread_ok;
}
fn currentIdentityFacade(sys: *const r4os.r4sys.Context) !void {
    const a = r4os.abi;
    const t = std.testing;
    var output: a.ProgramJoinHandle = .{ .thread_generation = 79 };
    fake_table.thread_current_handle = @intFromPtr(&fakeCurrentIdentity);
    for ([_]u32{ 1224, 1231 }) |size| {
        fake_table.size = size;
        try t.expectEqual(a.err_no_fn, sys.threadCurrentHandle(&output));
        try t.expectEqual(@as(u64, 79), output.thread_generation);
    }
    fake_table.size = 1232;
    fake_table.thread_current_handle = 0;
    try t.expectEqual(a.err_no_fn, sys.threadCurrentHandle(&output));
    try t.expectEqual(@as(u64, 79), output.thread_generation);
    fake_table.thread_current_handle = @intFromPtr(&fakeCurrentIdentity);
    try t.expectEqual(a.thread_ok, sys.threadCurrentHandle(&output));
    try t.expectEqual(@as(u32, 17), output.thread_id);
    try t.expectEqual(@as(u32, 31), output.instance_id);
    try t.expectEqual(@as(u64, 0x10000007939), output.thread_generation);
    try t.expectEqual(@as(u64, 0x20000007939), output.instance_generation);
    try t.expectEqual(@as(u64, 0), output.reserved);
}

fn fakeCpuCapacity(out: *r4os.abi.CpuCapacity) callconv(.c) i32 {
    out.* = .{ .available_cpus = 3, .configured_cpus = 4 };
    return r4os.abi.thread_ok;
}
fn cpuCapacityFacade(sys: *const r4os.r4sys.Context) !void {
    const a = r4os.abi;
    const t = std.testing;
    var output: a.CpuCapacity = .{ .available_cpus = 79 };
    fake_table.cpu_capacity = @intFromPtr(&fakeCpuCapacity);
    for ([_]u32{ 1232, 1239 }) |size| {
        fake_table.size = size;
        try t.expectEqual(a.err_no_fn, sys.cpuCapacity(&output));
        try t.expectEqual(@as(u32, 79), output.available_cpus);
    }
    fake_table.size = 1240;
    fake_table.cpu_capacity = 0;
    try t.expectEqual(a.err_no_fn, sys.cpuCapacity(&output));
    try t.expectEqual(@as(u32, 79), output.available_cpus);
    fake_table.cpu_capacity = @intFromPtr(&fakeCpuCapacity);
    try t.expectEqual(a.thread_ok, sys.cpuCapacity(&output));
    try t.expectEqual(@as(u32, 3), output.available_cpus);
    try t.expectEqual(@as(u32, 4), output.configured_cpus);
}

var placement_calls: u32 = 0;
fn fakePlacementGet(handle: *const r4os.abi.ProgramJoinHandle, info: *r4os.abi.ThreadPlacementInfo, cpus: ?[*]u64, count: u32) callconv(.c) i32 {
    std.debug.assert(handle.thread_generation == 0x10000007939);
    placement_calls += 1;
    info.cpu_word_count = 2;
    if (count != 0) {
        std.debug.assert(count == 3);
        cpus.?[0] = 1;
        cpus.?[1] = 1 << 13;
    }
    return 37;
}
fn fakePlacementSet(handle: *const r4os.abi.ProgramJoinHandle, request: *const r4os.abi.ThreadPlacementRequest, cpus: ?[*]const u64, count: u32) callconv(.c) i32 {
    std.debug.assert(handle.thread_generation == 0x10000007939 and request.work_class == r4os.abi.thread_placement_class_batch);
    std.debug.assert(count == 2 and cpus.?[1] == 1 << 13);
    placement_calls += 1;
    return 41;
}
fn placementFacade(sys: *const r4os.r4sys.Context) !void {
    const a = r4os.abi;
    const t = std.testing;
    const handle: a.ProgramJoinHandle = .{ .thread_generation = 0x10000007939 };
    var info: a.ThreadPlacementInfo = .{};
    var words: [3]u64 = .{ 79, 79, 79 };
    const request: a.ThreadPlacementRequest = .{ .work_class = a.thread_placement_class_batch };
    placement_calls = 0;
    fake_table.thread_placement_get = @intFromPtr(&fakePlacementGet);
    fake_table.thread_placement_set = @intFromPtr(&fakePlacementSet);
    for ([_]u32{ 1264, 1271 }) |size| {
        fake_table.size = size;
        try t.expectEqual(a.err_no_fn, sys.threadPlacementGet(&handle, &info, &words));
    }
    for ([_]u32{ 1272, 1279 }) |size| {
        fake_table.size = size;
        try t.expectEqual(a.err_no_fn, sys.threadPlacementSet(&handle, &request, words[0..2]));
    }
    fake_table.size = 1280;
    fake_table.thread_placement_get = 0;
    fake_table.thread_placement_set = 0;
    try t.expectEqual(a.err_no_fn, sys.threadPlacementGet(&handle, &info, &words));
    try t.expectEqual(a.err_no_fn, sys.threadPlacementSet(&handle, &request, words[0..2]));
    try t.expectEqual(@as(u32, 0), placement_calls);
    try t.expectEqualDeep([_]u64{ 79, 79, 79 }, words);
    fake_table.thread_placement_get = @intFromPtr(&fakePlacementGet);
    fake_table.thread_placement_set = @intFromPtr(&fakePlacementSet);
    try t.expectEqual(@as(i32, 37), sys.threadPlacementGet(&handle, &info, &.{}));
    try t.expectEqual(@as(u32, 2), info.cpu_word_count);
    try t.expectEqual(@as(i32, 37), sys.threadPlacementGet(&handle, &info, &words));
    try t.expectEqualDeep([_]u64{ 1, 1 << 13, 79 }, words);
    try t.expectEqual(@as(i32, 41), sys.threadPlacementSet(&handle, &request, words[0..2]));
    // CPU77 crosses the first word: the SDK forwards full vectors unchanged.
    try t.expectEqual(@as(u32, 3), placement_calls);
}

fn fakeProgramExit(code: i32, reason: u32) callconv(.c) i32 {
    return if (code == -73 and reason == r4os.abi.program_exit_reason_failed) r4os.abi.thread_error_busy else r4os.abi.thread_error_invalid;
}
fn programExitFacade(sys: *const r4os.r4sys.Context) !void {
    const a = r4os.abi;
    fake_table.program_exit = @intFromPtr(&fakeProgramExit);
    for ([_]u32{ 1240, 1247 }) |size| {
        fake_table.size = size;
        try std.testing.expectEqual(a.err_no_fn, sys.programExit(-73, a.program_exit_reason_failed));
    }
    fake_table.size = 1248;
    fake_table.program_exit = 0;
    try std.testing.expectEqual(a.err_no_fn, sys.programExit(-73, a.program_exit_reason_failed));
    fake_table.program_exit = @intFromPtr(&fakeProgramExit);
    try std.testing.expectEqual(a.thread_error_busy, sys.programExit(-73, a.program_exit_reason_failed));
}

test "process thread VM and I/O resources invalidate and retain timeout state" {
    var api = resources();
    var refused: r4os.abi.ProgramJoinHandle = .{};
    try std.testing.expectEqual(r4os.abi.thread_error_unsupported, api.sys.computeWorkerCreate(unusedThread, 85, 256 * 1024, &refused));
    try std.testing.expectEqual(@as(u32, 0), refused.thread_id);
    fake_table.thread_create_handle = @intFromPtr(&fakeComputeCreate);
    var compute = switch (api.createComputeWorker(unusedThread, 85, 256 * 1024)) {
        .handle => |value| value,
        .failure => return error.ComputeWorker,
    };
    try std.testing.expectEqual(@as(i32, 85), switch (compute.join(r4os.time_contract.timeoutForever())) {
        .exited => |code| code,
        else => -1,
    });
    try std.testing.expect(!compute.valid());
    fake_table.thread_create_handle = @intFromPtr(&fakeThreadCreateHandle);
    try currentIdentityFacade(&api.sys);
    try cpuCapacityFacade(&api.sys);
    try placementFacade(&api.sys);
    try programExitFacade(&api.sys);
    const path = r4os.FilePath.parse("C:\\TEST.R4X") catch unreachable;
    try std.testing.expectEqual(r4os.abi.program_handle_error_invalid, switch (api.openProcess(0)) {
        .failure => |raw| raw,
        else => 0,
    });
    var process = switch (api.spawn(path.asZ(), "", .console)) {
        .process => |value| value,
        .failure => return error.Spawn,
    };
    try std.testing.expect(process.valid());
    var borrowed = switch (api.openProcess(process.instanceId())) {
        .process => |value| value,
        .failure => return error.Open,
    };
    try std.testing.expect(switch (borrowed.status()) {
        .value => true,
        else => false,
    });
    try std.testing.expectEqual(r4os.abi.err_not_owned, switch (borrowed.reap()) {
        .failure => |raw| raw,
        else => 0,
    });
    try std.testing.expect(process.requestClose() == 0);
    const borrowed_ready = switch (borrowed.waitReady(r4os.time_contract.timeoutForever())) {
        .ready => |value| value,
        else => return error.BorrowedWaitReady,
    };
    try std.testing.expectEqual(process.generation, borrowed_ready.handle.generation);
    var borrowed_output: [4]u8 = undefined;
    try std.testing.expectEqual(@as(u32, 2), switch (borrowed.completionRead(0, borrowed_output[0..])) {
        .bytes => |count| count,
        else => 0,
    });
    try std.testing.expectEqualStrings("OK", borrowed_output[0..2]);
    try std.testing.expectEqual(r4os.abi.err_not_owned, switch (borrowed.wait(r4os.time_contract.timeoutForever())) {
        .failure => |raw| raw,
        else => 0,
    });
    const ready = switch (process.waitReady(r4os.time_contract.timeoutForever())) {
        .ready => |value| value,
        else => return error.WaitReady,
    };
    try std.testing.expectEqual(process.generation, ready.handle.generation);
    var output: [4]u8 = undefined;
    try std.testing.expectEqual(@as(u32, 2), switch (process.completionRead(0, output[0..])) {
        .bytes => |count| count,
        else => 0,
    });
    try std.testing.expectEqualStrings("OK", output[0..2]);
    try std.testing.expect(switch (process.reap()) {
        .exited => true,
        else => false,
    });
    try std.testing.expectEqual(@as(u32, 0), process.raw);
    try std.testing.expectEqual(@as(u64, 0), process.generation);
    try std.testing.expectEqual(@as(u32, 0), process.handle_reserved);
    try std.testing.expectEqual(@as(u32, 0), process.extension_reserved);
    try std.testing.expectEqual(r4os.abi.err_closed, switch (process.reap()) {
        .failure => |raw| raw,
        else => 0,
    });

    var join = switch (api.createThread(unusedThread, 17, 0)) {
        .handle => |value| value,
        .failure => return error.Thread,
    };
    try std.testing.expect(switch (join.join(r4os.time_contract.timeoutPoll())) {
        .timed_out => true,
        else => false,
    });
    try std.testing.expect(join.valid());
    try std.testing.expectEqual(@as(i32, 17), switch (join.join(r4os.time_contract.timeoutForever())) {
        .exited => |code| code,
        else => -1,
    });
    try std.testing.expectEqual(r4os.abi.err_closed, switch (join.join(r4os.time_contract.timeoutForever())) {
        .failure => |raw| raw,
        else => 0,
    });

    var region = switch (api.reserveVm(4096, 4096, r4os.abi.vm_region_flags_default)) {
        .region => |value| value,
        .failure => return error.Vm,
    };
    try std.testing.expectEqual(r4os.abi.vm_ok, region.commit(0, 4096));
    try std.testing.expect(switch (region.info()) {
        .value => true,
        else => false,
    });
    vm_wrong_owner = true;
    try std.testing.expectEqual(r4os.abi.vm_error_owner_mismatch, region.release());
    vm_wrong_owner = false;
    var region_copy = region;
    try std.testing.expectEqual(r4os.abi.vm_ok, region.release());
    try std.testing.expectEqual(r4os.abi.err_closed, region_copy.release());

    var buffer: [8]u8 = undefined;
    var request = switch (api.asyncRead(path.asZ(), buffer[0..], 0)) {
        .request => |value| value,
        .failure => return error.Io,
    };
    try std.testing.expect(request.buffersHeld());
    try std.testing.expectEqual(r4os.abi.err_buffer_in_use, request.releaseBuffers());
    try std.testing.expect(switch (request.wait(r4os.time_contract.timeoutPoll())) {
        .timed_out => true,
        else => false,
    });
    try std.testing.expectEqual(r4os.abi.io_error_busy, request.close());
    try std.testing.expect(switch (request.wait(r4os.time_contract.timeoutForever())) {
        .completed => true,
        else => false,
    });
    var request_copy = request;
    try std.testing.expectEqual(r4os.abi.io_ok, request.close());
    try std.testing.expectEqual(r4os.abi.err_closed, request_copy.close());
    try std.testing.expectEqual(@as(u32, 0), process_slots + thread_slots + vm_slots + io_slots);
}

test "program handles reject stale copies and console-host spawn remains owning" {
    var api = resources();
    const path = r4os.FilePath.parse("C:\\TEST.R4X") catch unreachable;
    var first = switch (api.spawn(path.asZ(), "", .console)) {
        .process => |value| value,
        .failure => return error.FirstSpawn,
    };
    var stale = first;
    _ = first.kill();
    _ = first.wait(r4os.time_contract.timeoutForever());
    var second = switch (api.spawnWithConsoleHost(path.asZ(), "", .console, .terminal_window)) {
        .process => |value| value,
        .failure => return error.HostSpawn,
    };
    try std.testing.expectEqual(stale.raw, second.raw);
    try std.testing.expect(stale.generation != second.generation);
    try std.testing.expectEqual(r4os.abi.program_handle_error_stale, switch (stale.status()) {
        .failure => |raw| raw,
        else => 0,
    });
    _ = second.kill();
    var fully_reaped = second;
    _ = second.wait(r4os.time_contract.timeoutForever());
    try std.testing.expect(switch (fully_reaped.status()) {
        .missing => true,
        else => false,
    });
    try std.testing.expectEqual(r4os.abi.program_handle_error_not_found, fully_reaped.requestClose());
    try std.testing.expectEqual(r4os.abi.program_handle_error_not_found, fully_reaped.kill());
    try std.testing.expectEqual(r4os.abi.program_handle_error_not_found, switch (fully_reaped.waitReady(r4os.time_contract.timeoutPoll())) {
        .failure => |raw| raw,
        else => 0,
    });
    var byte: [1]u8 = undefined;
    try std.testing.expectEqual(r4os.abi.program_handle_error_not_found, switch (fully_reaped.completionRead(0, byte[0..])) {
        .failure => |raw| raw,
        else => 0,
    });
    try std.testing.expectEqual(r4os.abi.program_handle_error_not_found, switch (fully_reaped.reap()) {
        .failure => |raw| raw,
        else => 0,
    });
}

test "sequential stress reuses every resource slot" {
    var api = resources();
    const path = r4os.FilePath.parse("C:\\TEST.R4X") catch unreachable;
    var index: u32 = 0;
    while (index < 80) : (index += 1) {
        var process = switch (api.spawn(path.asZ(), "", .console)) {
            .process => |value| value,
            .failure => return error.ProcessLeak,
        };
        _ = process.kill();
        try std.testing.expectEqual(@as(i32, -9), switch (process.wait(r4os.time_contract.timeoutForever())) {
            .exited => |code| code,
            else => 0,
        });
        var join = switch (api.createThread(unusedThread, index, 0)) {
            .handle => |value| value,
            .failure => return error.ThreadLeak,
        };
        _ = join.join(r4os.time_contract.timeoutForever());
        var region = switch (api.reserveVm(4096, 4096, 0)) {
            .region => |value| value,
            .failure => return error.VmLeak,
        };
        _ = region.release();
        var buffer: [4]u8 = undefined;
        var request = switch (api.asyncRead(path.asZ(), buffer[0..], 0)) {
            .request => |value| value,
            .failure => return error.IoLeak,
        };
        _ = request.wait(r4os.time_contract.timeoutForever());
        _ = request.close();
    }
    try std.testing.expectEqual(@as(u32, 0), process_slots + thread_slots + vm_slots + io_slots);
}

fn platformRootProbe() callconv(.c) u64 {
    return 0x100000080035;
}
fn platformViewProbe(physical: u64, bytes: u64, out: *u64) callconv(.c) i32 {
    std.debug.assert(physical == 0x100000080035 and bytes == 65536);
    out.* = 0xffff800000080035;
    return 0;
}
fn platformInputProbe(kind: u32, value: u32) callconv(.c) i32 {
    std.debug.assert(kind == 3 and value == 2);
    return 0;
}
fn platformQueryProbe(out: *r4os.abi.DriverPlatformApi) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == 32);
    out.* = .{ .rsdp = @intFromPtr(&platformRootProbe), .physical_view = @intFromPtr(&platformViewProbe), .input_submit = @intFromPtr(&platformInputProbe) };
    return 0;
}
fn platformSnapshotProbe(out: *r4os.abi.PlatformInputSnapshot) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == 64);
    out.* = .{ .sequence = 0x100000080035, .brightness_up = 0x200000080035, .lid_state = 2, .capabilities = 3, .sources = 1 };
    return 1;
}
fn platformFacade() !void {
    const a = r4os.abi;
    const t = std.testing;
    var resource_ctx: r4os.r4dev.DriverResourceContext = .{ .table = .{ .platform_query = @intFromPtr(&platformQueryProbe) } };
    for ([_]u32{ 32, 48, 55 }) |size| {
        resource_ctx.table.size = size;
        try t.expect(resource_ctx.platform() == null);
    }
    resource_ctx.table.size = 56;
    const platform = resource_ctx.platform() orelse return error.MissingPlatform;
    try t.expectEqual(@as(u64, 0x100000080035), platform.rsdp());
    try t.expectEqual(@as(u64, 0xffff800000080035), @intFromPtr(platform.physicalView(0x100000080035, 65536).?));
    try t.expectEqual(@as(i32, 0), platform.input(3, 2));
    var sys: a.R4XStartR4Sys = .{ .size = 1248, .platform_input_snapshot = @intFromPtr(&platformSnapshotProbe) };
    const raw: r4os.abi.R4XStartContext = .{};
    const bundle: r4os.program.Bundle = .{ .raw = &raw, .sys = &sys };
    const ctx = r4os.program.Context.initBundle(&bundle);
    var snapshot: a.PlatformInputSnapshot = .{};
    try t.expectEqual(a.err_no_fn, ctx.platformInputSnapshot(&snapshot));
    sys.size = 1256;
    try t.expectEqual(@as(i32, 1), ctx.platformInputSnapshot(&snapshot));
    try t.expectEqual(@as(u64, 0x200000080035), snapshot.brightness_up);
    sys.platform_input_snapshot = 0;
    try t.expectEqual(a.err_no_fn, ctx.platformInputSnapshot(&snapshot));
}

fn lifecycleBegin(cursor: *r4os.abi.ProgramInventoryCursor) callconv(.c) i32 {
    cursor.* = .{ .snapshot_generation = 91, .program_epoch = 91, .flags = r4os.abi.program_inventory_cursor_flag_initialized | r4os.abi.program_inventory_cursor_flag_lifecycle };
    return 0;
}
fn lifecyclePrograms(cursor: *r4os.abi.ProgramInventoryCursor, out: [*]r4os.abi.ProgramLifecycleSnapshot, capacity: u32, page: *r4os.abi.ProgramInventoryPageInfo) callconv(.c) i32 {
    std.debug.assert(capacity == 2 and cursor.snapshot_generation == 91);
    out[0] = .{ .handle = .{ .instance_id = 42, .generation = 0x1234567887654321 }, .task_id = 73, .role = 2, .app_class = 1, .state = 1, .flags = 2, .exit_code = -17, .window_id = -1 };
    page.* = .{ .snapshot_generation = 91, .returned = 1, .kind = r4os.abi.program_inventory_kind_lifecycle, .status = r4os.abi.program_inventory_status_complete };
    return 0;
}
test "process thread VM and I/O resources preserve separate metadata-only lifecycle admission" {
    const a = r4os.abi;
    var table: a.R4XStartR4Sys = .{ .program_lifecycle_begin = @intFromPtr(&lifecycleBegin), .program_lifecycle_programs = @intFromPtr(&lifecyclePrograms) };
    const raw: a.R4XStartContext = .{};
    const bundle: r4os.program.Bundle = .{ .raw = &raw, .sys = &table };
    const context = r4os.r4sys.Context.init(&bundle);
    var cursor: a.ProgramInventoryCursor = .{};
    var page: a.ProgramInventoryPageInfo = .{};
    var rows: [2]a.ProgramLifecycleSnapshot = @splat(.{});
    try std.testing.expectEqual(@as(i32, 0), context.programLifecycleBegin(&cursor));
    try std.testing.expectEqual(@as(i32, 0), context.programLifecyclePrograms(&cursor, &rows, &page));
    try std.testing.expectEqual(@as(u64, 0x1234567887654321), rows[0].handle.generation);
    try std.testing.expectEqual(@as(i32, -17), rows[0].exit_code);
    try std.testing.expectEqual(@as(i32, -1), rows[0].window_id);
    try std.testing.expectEqual(a.program_handle_error_invalid, context.programLifecyclePrograms(&cursor, rows[0..0], &page));
    table.program_lifecycle_programs = 0;
    try std.testing.expectEqual(a.err_no_fn, context.programLifecyclePrograms(&cursor, &rows, &page));
    table.program_lifecycle_begin = 0;
    try std.testing.expectEqual(a.err_no_fn, context.programLifecycleBegin(&cursor));
}
