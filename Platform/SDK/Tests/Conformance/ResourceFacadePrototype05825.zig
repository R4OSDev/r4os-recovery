const std = @import("std");
const r4os = @import("r4os");

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

test "R4DEV registry source names keep v1 and expose V2 explicitly" {
    const bundle = r4os.program.Bundle{ .raw = &fake_context };
    const dev = r4os.r4dev.Context.init(&bundle);
    var summary_v1: r4os.abi.ProgramRegistrySummary = .{};
    var self_test_v1: r4os.abi.ProgramRegistrySelfTestResult = .{};
    var summary_v2: r4os.abi.ProgramRegistrySummaryV2 = .{};
    var self_test_v2: r4os.abi.ProgramRegistrySelfTestResultV2 = .{};
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySummary(&summary_v1));
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySelfTest(&self_test_v1));
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySummaryV2(&summary_v2));
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySelfTestV2(&self_test_v2));
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySummaryLegacy(&summary_v1));
    try std.testing.expectEqual(r4os.abi.err_no_group, dev.programRegistrySelfTestLegacy(&self_test_v1));

    const performance = r4os.PerformanceView{ .raw = dev };
    try std.testing.expect(performance.programRegistry() == null);
    try std.testing.expect(performance.programRegistryV2() == null);
    try std.testing.expectEqual(r4os.abi.err_no_group, performance.programRegistrySelfTest(&self_test_v1));
    try std.testing.expectEqual(r4os.abi.err_no_group, performance.programRegistrySelfTestV2(&self_test_v2));
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

test "process thread VM and I/O resources invalidate and retain timeout state" {
    var api = resources();
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
