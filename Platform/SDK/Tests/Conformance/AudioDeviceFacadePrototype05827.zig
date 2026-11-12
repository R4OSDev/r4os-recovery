const std = @import("std");
const r4os = @import("r4os");

fn fakeOutputCatalog(rows: [*]r4os.abi.AudioOutputInfo, capacity: u32, out: *r4os.abi.AudioOutputCatalog) callconv(.c) i32 {
    std.debug.assert(capacity == 257);
    rows[0].preferred_rate = 48000;
    out.* = .{ .registry_generation = 0x1234_5678_0000_0055, .count = 1, .provider_count = 1 };
    out.providers[0] = .{ .registration = 0x2345_6789_0000_0055, .generation = 0x3456_789a_0000_0055, .count = 1, .active_index = 0 };
    return 1;
}
test "audio catalog facade negotiates the complete optional slot and forwards full provider witnesses" {
    const a = r4os.abi;
    const t = std.testing;
    const facade = initFacades().audio.raw;
    var rows: [257]a.AudioOutputInfo = @splat(.{});
    var receipt: a.AudioOutputCatalog = .{ .registry_generation = 71 };
    audio_table.audio_output_catalog = @intFromPtr(&fakeOutputCatalog);
    for (224..232) |size| {
        audio_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.audioOutputCatalog(&rows, &receipt));
        try t.expectEqual(@as(u64, 71), receipt.registry_generation);
    }
    audio_table.size = 232;
    try t.expectEqual(@as(i32, 1), facade.audioOutputCatalog(&rows, &receipt));
    try t.expectEqual(@as(u64, 0x1234_5678_0000_0055), receipt.registry_generation);
    try t.expectEqual(@as(u64, 0x2345_6789_0000_0055), receipt.providers[0].registration);
    try t.expectEqual(@as(u64, 0x3456_789a_0000_0055), receipt.providers[0].generation);
    try t.expectEqual(@as(u32, 48000), rows[0].preferred_rate);
    try t.expectEqual(@as(u32, 0), rows[256].preferred_rate);
    audio_table.audio_output_catalog = 0;
    try t.expectEqual(a.err_no_fn, facade.audioOutputCatalog(&rows, &receipt));
}

var sys_table: r4os.abi.R4XStartR4Sys = .{};
var audio_table: r4os.abi.R4XStartR4Audio = .{};
var dev_table: r4os.abi.R4XStartR4Dev = .{};
var context: r4os.abi.R4XStartContext = .{};
var timeout_next = false;
var stream_open = false;
var open_connections: u32 = 0;
const ReplyFault = enum(u32) { none, stream, result, bytes, magic, version, action, short, long, open_zero_result, open_zero_stream, open_negative_stream, busy_bytes, write_zero, write_large, write_unaligned, remote_error };
var reply_fault: ReplyFault = .none;
var reply_action: u16 = 0;
var reply_at: u32 = 0;
var reply_calls: u32 = 0;
var platform_stream_id: u32 = 91;
var last_request_stream: u32 = 0;

pub export fn sdk_platform_oracle_reply_fault(action: u16, fault: u32, at: u32) callconv(.c) void {
    reply_action = action;
    reply_fault = @enumFromInt(fault);
    reply_at = at;
    reply_calls = 0;
}
pub export fn sdk_platform_oracle_last_stream() callconv(.c) u32 {
    return last_request_stream;
}

fn fakeCpuLifecycle(op: u32, cpu: u32, epoch: u64, out: *r4os.abi.CpuLifecycleInfo) callconv(.c) i32 {
    std.debug.assert(op == 2 and cpu == 63 and epoch == 0x1234_5678_85ab_cdef);
    out.epoch = epoch + 1;
    return -63;
}
fn fakeCpuLifecycleCheck(out: *r4os.abi.ProgramKernelCpuLifecycleCheck) callconv(.c) i32 {
    out.new_epoch = 0x1234_5678_85ab_cdf0;
    return 1;
}
test "CPU lifecycle facades negotiate both optional slots and forward full epochs without truncation" {
    const a = r4os.abi;
    const t = std.testing;
    const facade = initFacades().devices.raw;
    var info: a.CpuLifecycleInfo = .{ .epoch = 71 };
    var report: a.ProgramKernelCpuLifecycleCheck = .{ .new_epoch = 72 };
    dev_table.cpu_lifecycle = @intFromPtr(&fakeCpuLifecycle);
    dev_table.kernel_cpu_lifecycle_check = @intFromPtr(&fakeCpuLifecycleCheck);
    for ([_]u32{ 552, 553, 559 }) |size| {
        dev_table.size = size;
        try t.expectEqual(a.err_no_fn, facade.cpuLifecycle(2, 63, 0x1234_5678_85ab_cdef, &info));
        try t.expectEqual(@as(u64, 71), info.epoch);
    }
    dev_table.size = 560;
    try t.expectEqual(@as(i32, -63), facade.cpuLifecycle(2, 63, 0x1234_5678_85ab_cdef, &info));
    try t.expectEqual(@as(u64, 0x1234_5678_85ab_cdf0), info.epoch);
    try t.expectEqual(a.err_no_fn, facade.kernelCpuLifecycleCheck(&report));
    try t.expectEqual(@as(u64, 72), report.new_epoch);
    dev_table.size = 568;
    try t.expectEqual(@as(i32, 1), facade.kernelCpuLifecycleCheck(&report));
    dev_table.cpu_lifecycle = 0;
    dev_table.kernel_cpu_lifecycle_check = 0;
    try t.expectEqual(a.err_no_fn, facade.cpuLifecycle(2, 63, 0x1234_5678_85ab_cdef, &info));
    try t.expectEqual(a.err_no_fn, facade.kernelCpuLifecycleCheck(&report));
}

fn fakeCpuCapabilities(cpu: u32, out: *r4os.abi.CpuCapabilitiesInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63);
    out.epoch = 0x1234_5678_85ab_cdef;
    return 0;
}
fn fakeCpuFeature(cpu: u32, epoch: u64, index: u32, out: *r4os.abi.CpuFeatureInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == 0x1234_5678_85ab_cdef and index == 37);
    out.epoch = epoch;
    return 0;
}
fn fakeCpuRegister(cpu: u32, epoch: u64, id: u32, out: *r4os.abi.CpuRegisterInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == 0x1234_5678_85ab_cdef and id == 7);
    out.value = epoch;
    return 0;
}
fn fakeCpuRegisterCheck(cpu: u32, epoch: u64, out: *r4os.abi.ProgramKernelCpuRegisterCheck) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == 0x1234_5678_85ab_cdef);
    out.epoch = epoch;
    return 0;
}
test "CPU catalogue optional boundaries preserve old clients and forward full epochs" {
    const a = r4os.abi;
    const t = std.testing;
    const facade = initFacades().devices.raw;
    const epoch: u64 = 0x1234_5678_85ab_cdef;
    var cap: a.CpuCapabilitiesInfo = .{ .epoch = 71 };
    var feature: a.CpuFeatureInfo = .{ .epoch = 72 };
    var reg: a.CpuRegisterInfo = .{ .value = 73 };
    var report: a.ProgramKernelCpuRegisterCheck = .{ .epoch = 74 };
    dev_table.cpu_capabilities = @intFromPtr(&fakeCpuCapabilities);
    dev_table.cpu_feature = @intFromPtr(&fakeCpuFeature);
    dev_table.cpu_register_read = @intFromPtr(&fakeCpuRegister);
    dev_table.kernel_cpu_register_check = @intFromPtr(&fakeCpuRegisterCheck);
    for (568..576) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuCapabilities(63, &cap));
        try t.expectEqual(@as(u64, 71), cap.epoch);
    }
    dev_table.size = 576;
    try t.expectEqual(@as(i32, 0), facade.cpuCapabilities(63, &cap));
    try t.expectEqual(epoch, cap.epoch);
    for (576..584) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuFeature(63, epoch, 37, &feature));
        try t.expectEqual(@as(u64, 72), feature.epoch);
    }
    dev_table.size = 584;
    try t.expectEqual(@as(i32, 0), facade.cpuFeature(63, epoch, 37, &feature));
    try t.expectEqual(epoch, feature.epoch);
    for (584..592) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuRegisterRead(63, epoch, 7, &reg));
        try t.expectEqual(@as(u64, 73), reg.value);
    }
    dev_table.size = 592;
    try t.expectEqual(@as(i32, 0), facade.cpuRegisterRead(63, epoch, 7, &reg));
    try t.expectEqual(epoch, reg.value);
    for (592..600) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.kernelCpuRegisterCheck(63, epoch, &report));
        try t.expectEqual(@as(u64, 74), report.epoch);
    }
    dev_table.size = 600;
    try t.expectEqual(@as(i32, 0), facade.kernelCpuRegisterCheck(63, epoch, &report));
    try t.expectEqual(epoch, report.epoch);
    dev_table.cpu_capabilities = 0;
    dev_table.cpu_feature = 0;
    dev_table.cpu_register_read = 0;
    dev_table.kernel_cpu_register_check = 0;
    try t.expectEqual(a.err_no_fn, facade.cpuCapabilities(63, &cap));
    try t.expectEqual(a.err_no_fn, facade.cpuFeature(63, epoch, 37, &feature));
    try t.expectEqual(a.err_no_fn, facade.cpuRegisterRead(63, epoch, 7, &reg));
    try t.expectEqual(a.err_no_fn, facade.kernelCpuRegisterCheck(63, epoch, &report));
}

fn fakeCpuPower(cpu: u32, epoch: u64, out: *r4os.abi.CpuPowerInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == 0x1234_5678_85ab_cdef);
    out.provider_generation = epoch;
    return -77;
}
test "passive CPU power and explicit capture preserve old table boundaries and full epochs" {
    const a = r4os.abi;
    const t = std.testing;
    const facade = initFacades().devices.raw;
    const epoch: u64 = 0x1234_5678_85ab_cdef;
    var value: a.CpuPowerInfo = .{ .provider_generation = 71 };
    dev_table.cpu_power_info = @intFromPtr(&fakeCpuPower);
    dev_table.cpu_power_capture = @intFromPtr(&fakeCpuPower);
    for (600..608) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuPowerInfo(63, epoch, &value));
        try t.expectEqual(@as(u64, 71), value.provider_generation);
    }
    dev_table.size = 608;
    try t.expectEqual(@as(i32, -77), facade.cpuPowerInfo(63, epoch, &value));
    try t.expectEqual(epoch, value.provider_generation);
    for (608..616) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuPowerCapture(63, epoch, &value));
        try t.expectEqual(epoch, value.provider_generation);
    }
    dev_table.size = 616;
    try t.expectEqual(@as(i32, -77), facade.cpuPowerCapture(63, epoch, &value));
    dev_table.cpu_power_info = 0;
    dev_table.cpu_power_capture = 0;
    try t.expectEqual(a.err_no_fn, facade.cpuPowerInfo(63, epoch, &value));
    try t.expectEqual(a.err_no_fn, facade.cpuPowerCapture(63, epoch, &value));
    try t.expectEqual(epoch, value.provider_generation);
}

fn fakeCpuPerformance(request: *const r4os.abi.CpuPerformanceRequest, out: *r4os.abi.CpuPerformanceInfo) callconv(.c) i32 {
    std.debug.assert(request.cpu_index == 63 and request.epoch == 0x1234_5678_85ab_cdef);
    out.lease = request.epoch;
    return -96;
}
test "explicit CPU performance facade negotiates appended624 boundary without changing legacy output" {
    const a = r4os.abi;
    const t = std.testing;
    const facade = initFacades().devices.raw;
    const request: a.CpuPerformanceRequest = .{ .cpu_index = 63, .epoch = 0x1234_5678_85ab_cdef };
    var value: a.CpuPerformanceInfo = .{ .lease = 71 };
    dev_table.cpu_performance = @intFromPtr(&fakeCpuPerformance);
    for (616..624) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuPerformance(&request, &value));
        try t.expectEqual(@as(u64, 71), value.lease);
    }
    dev_table.size = 624;
    try t.expectEqual(@as(i32, -96), facade.cpuPerformance(&request, &value));
    try t.expectEqual(0x1234_5678_85ab_cdef, value.lease);
    dev_table.cpu_performance = 0;
    try t.expectEqual(a.err_no_fn, facade.cpuPerformance(&request, &value));
    try t.expectEqual(0x1234_5678_85ab_cdef, value.lease);
}

fn fakeCppc(request: *const r4os.abi.CpuPerformanceRequest, out: *r4os.abi.CpuCppcInfo) callconv(.c) i32 {
    std.debug.assert(request.cpu_index == 63 and request.epoch == 0x1234_5678_85ab_cdef);
    out.lease = request.epoch;
    return -97;
}
fn fakeRank(cpu: u32, epoch: u64, out: *r4os.abi.CpuPerformanceHintInfo) callconv(.c) i32 {
    std.debug.assert(cpu == 63 and epoch == 0x1234_5678_85ab_cdef);
    out.sequence = epoch;
    return -98;
}
test "typed CPPC/catalogue facades preserve624/632 legacy boundaries and full epoch data" {
    const a = r4os.abi;
    const t = std.testing;
    const facade = initFacades().devices.raw;
    const request: a.CpuPerformanceRequest = .{ .cpu_index = 63, .epoch = 0x1234_5678_85ab_cdef };
    var out: a.CpuCppcInfo = .{ .lease = 71 };
    var rank: a.CpuPerformanceHintInfo = .{ .sequence = 72 };
    dev_table.cpu_cppc = @intFromPtr(&fakeCppc);
    dev_table.cpu_performance_hint = @intFromPtr(&fakeRank);
    for (624..632) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuCppc(&request, &out));
        try t.expectEqual(@as(u64, 71), out.lease);
    }
    dev_table.size = 632;
    try t.expectEqual(@as(i32, -97), facade.cpuCppc(&request, &out));
    try t.expectEqual(request.epoch, out.lease);
    for (624..640) |size| {
        dev_table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, facade.cpuPerformanceHint(63, request.epoch, &rank));
        try t.expectEqual(@as(u64, 72), rank.sequence);
    }
    dev_table.size = 640;
    try t.expectEqual(@as(i32, -98), facade.cpuPerformanceHint(63, request.epoch, &rank));
    try t.expectEqual(request.epoch, rank.sequence);
    dev_table.cpu_cppc = 0;
    dev_table.cpu_performance_hint = 0;
    try t.expectEqual(a.err_no_fn, facade.cpuCppc(&request, &out));
    try t.expectEqual(a.err_no_fn, facade.cpuPerformanceHint(63, request.epoch, &rank));
    try t.expectEqual(request.epoch, rank.sequence);
}

fn fakeInstrumentation(out: *r4os.abi.ProgramInstrumentationInfo) callconv(.c) i32 {
    if (out.version != 1 or out.size != @sizeOf(r4os.abi.ProgramInstrumentationInfo)) return -1;
    out.* = .{ .mode = 0, .lock_count = 11, .stack_group_count = 13 };
    return 1;
}

fn fakeLock(index: u32, out: *r4os.abi.ProgramLockPerformanceInfo) callconv(.c) i32 {
    if (out.version != 1 or out.size != @sizeOf(r4os.abi.ProgramLockPerformanceInfo)) return -1;
    if (index >= 11) return 0;
    out.* = .{ .index = index, .acquisitions = 17 };
    return 1;
}

fn fakeStack(index: u32, out: *r4os.abi.ProgramStackPerformanceInfo) callconv(.c) i32 {
    if (out.version != 1 or out.size != @sizeOf(r4os.abi.ProgramStackPerformanceInfo)) return -1;
    if (index >= 13) return 0;
    out.* = .{ .index = index, .created = 9 };
    return 1;
}

fn fakeStackFault(index: u32, out: *r4os.abi.ProgramStackFaultInfo) callconv(.c) i32 {
    if (out.version != 1 or out.size < @sizeOf(r4os.abi.ProgramStackFaultInfo)) return -1;
    if (index >= 4) return 0;
    out.* = .{ .cpu_index = index, .sequence = 2, .flags = r4os.abi.stack_fault_flag_task, .task_id = 71, .task_generation = 93 };
    return 1;
}

test "stack fault view preserves output for old tables, end and invalid headers" {
    const facades = initFacades();
    const performance = facades.devices.performance();
    var out: r4os.abi.ProgramStackFaultInfo = .{ .task_id = 123 };
    try std.testing.expectEqual(r4os.abi.err_no_fn, performance.stackFault(0, &out));
    try std.testing.expectEqual(@as(u32, 123), out.task_id);
    dev_table.stack_fault = @intFromPtr(&fakeStackFault);
    try std.testing.expectEqual(@as(i32, 1), performance.stackFault(3, &out));
    try std.testing.expectEqual(@as(u32, 71), out.task_id);
    try std.testing.expectEqual(@as(u64, 93), out.task_generation);
    try std.testing.expectEqual(@as(i32, 0), performance.stackFault(4, &out));
    try std.testing.expectEqual(@as(u32, 71), out.task_id);
    out.version = 0;
    try std.testing.expectEqual(@as(i32, -1), performance.stackFault(0, &out));
    try std.testing.expectEqual(@as(u32, 71), out.task_id);
    dev_table.size = @offsetOf(r4os.abi.R4XStartR4Dev, "stack_fault");
    try std.testing.expectEqual(r4os.abi.err_no_fn, performance.stackFault(0, &out));
    try std.testing.expectEqual(@as(u32, 71), out.task_id);
}

test "instrumentation views distinguish missing slots, end of list and disabled details" {
    const facades = initFacades();
    const performance = facades.devices.performance();
    try std.testing.expect(performance.instrumentation() == null);
    dev_table.performance_instrumentation = @intFromPtr(&fakeInstrumentation);
    dev_table.performance_lock = @intFromPtr(&fakeLock);
    dev_table.performance_stack = @intFromPtr(&fakeStack);
    try std.testing.expectEqual(@as(u32, 0), performance.instrumentation().?.mode);
    try std.testing.expectEqual(@as(u64, 17), performance.lock(10).?.acquisitions);
    try std.testing.expectEqual(@as(u64, 9), performance.stack(12).?.created);
    try std.testing.expect(performance.lock(11) == null);
    try std.testing.expect(performance.stack(13) == null);
    dev_table.size = @offsetOf(r4os.abi.R4XStartR4Dev, "performance_instrumentation");
    try std.testing.expect(performance.instrumentation() == null);
    try std.testing.expect(performance.lock(0) == null);
    try std.testing.expect(performance.stack(0) == null);
}

fn fakeServiceOpen(_: [*:0]const u8, out: *r4os.abi.ServiceInfo) callconv(.c) i32 {
    out.* = .{ .handle = 77 };
    open_connections += 1;
    return r4os.abi.service_api_result_ok;
}

fn fakeServiceClose(handle: u32) callconv(.c) i32 {
    if (handle != 77 or open_connections == 0) return r4os.abi.service_api_result_bad_handle;
    open_connections -= 1;
    return r4os.abi.service_api_result_ok;
}

fn copyResponse(response: [*]u8, capacity: u32, value: *const r4os.abi.AudioServiceStreamResult) i32 {
    if (capacity < @sizeOf(r4os.abi.AudioServiceStreamResult)) return r4os.abi.service_api_result_buffer_too_small;
    @memcpy(response[0..@sizeOf(r4os.abi.AudioServiceStreamResult)], std.mem.asBytes(value));
    return @sizeOf(r4os.abi.AudioServiceStreamResult);
}

fn fakeServiceCall(_: u32, op: u16, request: [*]const u8, request_len: u32, header: *r4os.abi.ServiceMessageHeader, response: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
    header.* = .{ .op = op, .status = r4os.abi.service_api_result_ok };
    if (timeout_next) {
        timeout_next = false;
        return r4os.abi.service_api_result_timeout;
    }
    if (op == reply_action) reply_calls += 1;
    const inject = op == reply_action and reply_fault != .none and (reply_at == 0 or reply_calls == reply_at);
    var result = r4os.abi.AudioServiceStreamResult{ .action = op, .result = 0, .stream_id = platform_stream_id };
    switch (op) {
        r4os.abi.audio_service_op_open_stream => {
            stream_open = true;
            result.result = @intCast(platform_stream_id);
        },
        r4os.abi.audio_service_op_write_stream => {
            platform_write_calls += 1;
            if (platform_write_mode == 3 and platform_write_calls == 2) return r4os.abi.service_api_result_timeout;
            if (!stream_open or request_len < @sizeOf(r4os.abi.AudioServiceStreamWriteRequest)) result.result = -1 else {
                var wire: r4os.abi.AudioServiceStreamWriteRequest = .{};
                @memcpy(std.mem.asBytes(&wire), request[0..@sizeOf(r4os.abi.AudioServiceStreamWriteRequest)]);
                last_request_stream = wire.stream_id;
                result.bytes = wire.byte_count;
                result.result = @intCast(wire.byte_count);
                if (platform_write_mode != 0) {
                    result.bytes = @min(wire.byte_count, 4);
                    result.result = @intCast(result.bytes);
                }
                if (platform_write_mode == 2 and platform_write_calls == 2) {
                    result.result = r4os.abi.service_api_result_busy;
                    result.bytes = 0;
                }
                if (platform_write_mode == 4) {
                    result.bytes = 3;
                    result.result = 3;
                }
            }
        },
        r4os.abi.audio_service_op_set_stream_volume => if (!stream_open) {
            result.result = -1;
        },
        r4os.abi.audio_service_op_close_stream => if (stream_open) {
            if (!inject) stream_open = false;
        } else {
            result.result = -1;
        },
        else => result.result = r4os.abi.service_api_result_bad_op,
    }
    if ((op == r4os.abi.audio_service_op_set_stream_volume or op == r4os.abi.audio_service_op_close_stream) and request_len == @sizeOf(r4os.abi.AudioServiceStreamControlRequest)) {
        var wire: r4os.abi.AudioServiceStreamControlRequest = .{};
        @memcpy(std.mem.asBytes(&wire), request[0..@sizeOf(@TypeOf(wire))]);
        last_request_stream = wire.stream_id;
    }
    if (inject) switch (reply_fault) {
        .none => unreachable,
        .stream => result.stream_id += 1,
        .result => result.result += 1,
        .bytes => result.bytes += 4,
        .magic => result.magic ^= 1,
        .version => result.version += 1,
        .action => result.action +%= 1,
        .short, .long => {},
        .open_zero_result => result.result = 0,
        .open_zero_stream => result.stream_id = 0,
        .open_negative_stream => result.result = r4os.abi.service_api_result_bad_handle,
        .busy_bytes => {
            result.result = r4os.abi.service_api_result_busy;
            result.bytes = 4;
        },
        .write_zero => {
            result.result = 0;
            result.bytes = 0;
        },
        .write_large => {
            const raw = request[0..@sizeOf(r4os.abi.AudioServiceStreamWriteRequest)];
            var wire: r4os.abi.AudioServiceStreamWriteRequest = .{};
            @memcpy(std.mem.asBytes(&wire), raw);
            result.bytes = wire.byte_count + 4;
            result.result = @intCast(result.bytes);
        },
        .write_unaligned => {
            result.bytes = 3;
            result.result = 3;
        },
        .remote_error => {
            result.result = r4os.abi.service_api_result_bad_handle;
            result.bytes = 0;
            if (op == r4os.abi.audio_service_op_open_stream) result.stream_id = 0;
        },
    };
    const copied = copyResponse(response, capacity, &result);
    return if (inject and reply_fault == .short) copied - 1 else if (inject and reply_fault == .long) copied + 1 else copied;
}

var platform_write_mode: u32 = 0;
var platform_write_calls: u32 = 0;
pub export fn sdk_platform_oracle_mode(mode: u32) callconv(.c) void {
    platform_write_mode = mode;
    platform_write_calls = 0;
}
pub export fn sdk_platform_oracle_connections() callconv(.c) u32 {
    return open_connections;
}
pub export fn sdk_platform_oracle_tables(sys: *r4os.abi.R4XStartR4Sys, audio: *r4os.abi.R4XStartR4Audio, dev: *r4os.abi.R4XStartR4Dev) callconv(.c) void {
    _ = initFacades();
    sys.* = sys_table;
    audio.* = audio_table;
    dev.* = dev_table;
    stream_open = false;
    open_connections = 0;
    timeout_next = false;
    platform_write_mode = 0;
    platform_write_calls = 0;
    reply_fault = .none;
    reply_action = 0;
    reply_calls = 0;
    platform_stream_id = 91;
    last_request_stream = 0;
}

fn fakeAudioOpen(_: u32, _: u16, _: u16) callconv(.c) i32 {
    return 1;
}
fn fakeSidAcquire() callconv(.c) i32 {
    return 11;
}
fn fakeSidWrite(_: u32, _: u8, _: u8) callconv(.c) i32 {
    return 0;
}
fn fakeSidRelease(_: u32) callconv(.c) i32 {
    return 0;
}
fn fakeMidiOpen(_: [*:0]const u8) callconv(.c) i32 {
    return 12;
}
fn fakeMidiSend(_: u32, _: u8, _: u8, _: u8, _: u8) callconv(.c) i32 {
    return 0;
}
fn fakeMidiClose(_: u32) callconv(.c) i32 {
    return 0;
}
fn fakeOplWrite(_: u8, _: u8, _: u8) callconv(.c) i32 {
    return 0;
}
fn fakeOplSimple() callconv(.c) i32 {
    return 0;
}

fn fakeInventorySummary(out: *r4os.abi.DeviceInventorySummary) callconv(.c) i32 {
    out.* = .{ .total = 2, .with_driver = 1, .without_driver = 1 };
    return 1;
}
fn fakeInventoryRecord(index: u32, out: *r4os.abi.DeviceInventoryRecord) callconv(.c) i32 {
    if (index >= 2) return 0;
    out.* = .{ .bus = @intCast(index + 1) };
    return 1;
}
fn fakeMemorySummary(out: *r4os.abi.ProgramMemorySummary) callconv(.c) i32 {
    out.* = .{ .physical_bytes = 64 * 1024 * 1024 };
    return 0;
}
fn fakeMemoryCount() callconv(.c) u32 {
    return 3;
}
fn fakeMemoryBlock(index: u32, out: *r4os.abi.ProgramMemoryBlockInfo) callconv(.c) i32 {
    out.* = .{ .id = index };
    return 1;
}
fn fakePressure(out: *r4os.abi.ProgramMemoryPressureSnapshot) callconv(.c) i32 {
    out.* = .{ .pressure_level = r4os.abi.memory_pressure_level_normal };
    return 1;
}
fn fakePerformance(out: *r4os.abi.ProgramPerformanceSummary) callconv(.c) i32 {
    out.* = .{ .audio_stream_writes = 9 };
    return 1;
}
fn fakeProgramInstanceStorageV2(out: *r4os.abi.ProgramInstanceStorageSummary) callconv(.c) i32 {
    if (out.version < 2 or out.size < @sizeOf(r4os.abi.ProgramInstanceStorageSummary)) return -1;
    out.* = .{ .active_instances = 4, .active_service_instances = 2, .current_payload_bytes = 4096, .payload_allocations = 11, .payload_releases = 7, .current_gui_frame_bytes = 8192 };
    return 1;
}
fn fakeProgramInstanceStorageSelfTest(out: *r4os.abi.ProgramInstanceStorageSelfTestResult) callconv(.c) i32 {
    out.* = .{ .cases = 27, .passed_cases = 27, .flags = 0xF, .allocation_failures_before = 2, .allocation_failures_after = 4 };
    return 1;
}
fn fakeExecutionInventory(out: *r4os.abi.ProgramInventorySummary) callconv(.c) i32 {
    out.* = .{
        .version = r4os.abi.program_inventory_version,
        .size = @sizeOf(r4os.abi.ProgramInventorySummary),
        .program_total = 17,
        .task_total = 29,
        .thread_total = 23,
        .program_peak = 41,
    };
    return r4os.abi.program_handle_ok;
}
fn fakePerformanceTask(index: u32, out: *r4os.abi.ProgramTaskPerformanceInfo) callconv(.c) i32 {
    out.* = .{ .id = index };
    return 1;
}
fn fakePerformanceStorage(index: u32, out: *r4os.abi.ProgramStoragePerformanceInfo) callconv(.c) i32 {
    out.* = .{ .index = index };
    return 1;
}
fn fakePerformanceBoot(_: u32, out: *r4os.abi.ProgramBootPhasePerformanceInfo) callconv(.c) i32 {
    out.* = .{};
    return 1;
}
fn fakeHardware(out: *r4os.abi.HardwareSummary) callconv(.c) i32 {
    out.* = .{ .cpu_logical_processors = 4 };
    return 1;
}

fn initFacades() struct { audio: r4os.Audio, devices: r4os.Devices } {
    sys_table = .{};
    sys_table.service_open = @intFromPtr(&fakeServiceOpen);
    sys_table.service_close = @intFromPtr(&fakeServiceClose);
    sys_table.service_call = @intFromPtr(&fakeServiceCall);
    audio_table = .{};
    audio_table.audio_open_stream = @intFromPtr(&fakeAudioOpen);
    audio_table.sid_acquire = @intFromPtr(&fakeSidAcquire);
    audio_table.sid_write_register = @intFromPtr(&fakeSidWrite);
    audio_table.sid_release = @intFromPtr(&fakeSidRelease);
    audio_table.midi_open_synth = @intFromPtr(&fakeMidiOpen);
    audio_table.midi_send = @intFromPtr(&fakeMidiSend);
    audio_table.midi_close = @intFromPtr(&fakeMidiClose);
    audio_table.opl3_write_register = @intFromPtr(&fakeOplWrite);
    audio_table.opl3_reset = @intFromPtr(&fakeOplSimple);
    audio_table.opl3_render_block = @intFromPtr(&fakeOplSimple);
    audio_table.opl3_stop = @intFromPtr(&fakeOplSimple);
    dev_table = .{};
    dev_table.device_inventory_summary = @intFromPtr(&fakeInventorySummary);
    dev_table.device_inventory_record = @intFromPtr(&fakeInventoryRecord);
    dev_table.memory_summary = @intFromPtr(&fakeMemorySummary);
    dev_table.memory_block_count = @intFromPtr(&fakeMemoryCount);
    dev_table.memory_block = @intFromPtr(&fakeMemoryBlock);
    dev_table.memory_pressure_snapshot = @intFromPtr(&fakePressure);
    dev_table.performance_summary = @intFromPtr(&fakePerformance);
    dev_table.program_instance_storage_summary_v2 = @intFromPtr(&fakeProgramInstanceStorageV2);
    dev_table.program_instance_storage_self_test = @intFromPtr(&fakeProgramInstanceStorageSelfTest);
    dev_table.execution_inventory_summary = @intFromPtr(&fakeExecutionInventory);
    dev_table.performance_task = @intFromPtr(&fakePerformanceTask);
    dev_table.performance_storage = @intFromPtr(&fakePerformanceStorage);
    dev_table.performance_boot_phase = @intFromPtr(&fakePerformanceBoot);
    dev_table.hardware_summary = @intFromPtr(&fakeHardware);
    dev_table.display_state = @intFromPtr(&fakeDisplayState);
    const bundle = r4os.program.Bundle{ .raw = &context, .sys = &sys_table, .audio = &audio_table, .dev = &dev_table };
    const sys = r4os.r4sys.Context.init(&bundle);
    return .{
        .audio = .{ .sys = sys, .raw = r4os.r4audio.Context.init(&bundle) },
        .devices = .{ .raw = r4os.r4dev.Context.init(&bundle) },
    };
}

fn fakeDisplayState(out: *r4os.abi.DisplayStateInfo) callconv(.c) i32 {
    if (out.version != 1 or out.size < @sizeOf(r4os.abi.DisplayStateInfo)) return -1;
    out.* = .{ .state = r4os.abi.display_state_bootfb, .device_generation = 7, .policy = r4os.abi.display_policy_software_once };
    return 1;
}

test "PCM lifecycle validates format timeout progress and double close" {
    stream_open = false;
    open_connections = 0;
    timeout_next = false;
    reply_fault = .none;
    platform_stream_id = 91;
    platform_write_mode = 0;
    var facades = initFacades();
    try std.testing.expect(facades.audio.available());
    facades.audio.raw = .{ .base = .{} };
    try std.testing.expect(facades.audio.available());
    const invalid_format: r4os.PcmFormat = @enumFromInt(2);
    try std.testing.expect(switch (facades.audio.openStream(48_000, 2, invalid_format, r4os.app_audio.default_volume, r4os.time_contract.timeoutPoll())) {
        .failure => |raw| raw == r4os.abi.service_api_result_invalid,
        else => false,
    });
    timeout_next = true;
    try std.testing.expect(switch (facades.audio.openStream(48_000, 2, .s16le, r4os.app_audio.default_volume, r4os.time_contract.timeoutPoll())) {
        .timed_out => true,
        else => false,
    });
    var stream = switch (facades.audio.openStream(48_000, 2, .s16le, r4os.app_audio.default_volume, r4os.time_contract.timeoutForever())) {
        .stream => |value| value,
        else => return error.Open,
    };
    var pcm: [2048]u8 = .{1} ** 2048;
    try std.testing.expectEqual(pcm.len, switch (stream.write(pcm[0..], r4os.time_contract.timeoutForever())) {
        .written => |bytes| bytes,
        else => 0,
    });
    try std.testing.expect(switch (stream.setVolume(0x8000, r4os.time_contract.timeoutForever())) {
        .ok => true,
        else => false,
    });
    try std.testing.expect(switch (stream.close(r4os.time_contract.timeoutForever())) {
        .ok => true,
        else => false,
    });
    try std.testing.expect(switch (stream.close(r4os.time_contract.timeoutForever())) {
        .failure => |raw| raw == r4os.abi.err_closed,
        else => false,
    });
    try std.testing.expectEqual(@as(u32, 0), open_connections);
}

fn replyTestAudio() r4os.Audio {
    sdk_platform_oracle_tables(&sys_table, &audio_table, &dev_table);
    return initFacades().audio;
}

fn replyTestStream(audio: *const r4os.Audio) !r4os.AudioStream {
    return switch (audio.openStream(48_000, 2, .s16le, r4os.app_audio.default_volume, r4os.time_contract.timeoutForever())) {
        .stream => |stream| stream,
        else => error.Open,
    };
}

test "PCM reply ownership retains only the exact acknowledged prefix across bad writes" {
    const a = r4os.abi;
    for ([_]ReplyFault{ .stream, .result, .bytes, .magic, .version, .action, .short, .long, .busy_bytes, .write_zero, .write_large, .write_unaligned, .remote_error }) |fault| {
        for ([_]usize{ 16, 8192 }) |length| {
            const audio = replyTestAudio();
            var stream = try replyTestStream(&audio);
            sdk_platform_oracle_mode(if (length == 16) 1 else 0);
            sdk_platform_oracle_reply_fault(a.audio_service_op_write_stream, @intFromEnum(fault), 2);
            var bytes: [8192]u8 = .{0x42} ** 8192;
            const result = stream.write(bytes[0..length], r4os.time_contract.timeoutForever());
            const failure = switch (result) {
                .failure => |value| value,
                else => return error.UnacknowledgedBytesAccepted,
            };
            try std.testing.expectEqual(if (fault == .remote_error) a.service_api_result_bad_handle else a.service_api_result_invalid, failure.raw);
            try std.testing.expectEqual(if (length == 16) @as(usize, 4) else r4os.app_audio.max_write_payload, failure.written);
            try std.testing.expectEqual(@as(u32, 2), platform_write_calls);
            try std.testing.expect(stream.valid() and stream.stream_id == 91 and open_connections == 1 and last_request_stream == 91);
            var cursor = r4os.app_audio.WriteCursor.init(length, 4).?;
            try std.testing.expectEqual(r4os.app_audio.WriteOutcome.failure, cursor.apply(result).outcome);
            try std.testing.expectEqual(length - failure.written, cursor.remaining());
            sdk_platform_oracle_reply_fault(0, 0, 0);
            try std.testing.expect(stream.close(r4os.time_contract.timeoutForever()) == .ok);
            try std.testing.expectEqual(@as(u32, 0), open_connections);
        }
    }
}

test "PCM reply ownership rejects foreign and positive control success without releasing stream" {
    const a = r4os.abi;
    for ([_]u16{ a.audio_service_op_set_stream_volume, a.audio_service_op_close_stream }) |operation| {
        for ([_]ReplyFault{ .stream, .result, .bytes, .magic, .version, .action, .short, .long, .remote_error }) |fault| {
            const audio = replyTestAudio();
            var stream = try replyTestStream(&audio);
            sdk_platform_oracle_reply_fault(operation, @intFromEnum(fault), 1);
            const result = if (operation == a.audio_service_op_close_stream) stream.close(r4os.time_contract.timeoutForever()) else stream.setVolume(0x8000, r4os.time_contract.timeoutForever());
            const expected = if (fault == .short or fault == .long) a.service_api_result_buffer_too_small else if (fault == .remote_error) a.service_api_result_bad_handle else a.service_api_result_invalid;
            try std.testing.expectEqual(expected, switch (result) {
                .failure => |raw| raw,
                else => return error.ForeignControlAcknowledged,
            });
            try std.testing.expect(stream.valid() and stream.stream_id == 91 and stream.owned and open_connections == 1 and last_request_stream == 91);
            sdk_platform_oracle_reply_fault(0, 0, 0);
            try std.testing.expect(stream.close(r4os.time_contract.timeoutForever()) == .ok);
            try std.testing.expectEqual(@as(u32, 0), open_connections);
        }
    }
}

test "PCM reply ownership binds positive Open result to stream and rejects inconsistent identities" {
    const a = r4os.abi;
    for ([_]ReplyFault{ .stream, .result, .bytes, .magic, .version, .action, .short, .long, .open_zero_result, .open_zero_stream, .open_negative_stream }) |fault| {
        const audio = replyTestAudio();
        sdk_platform_oracle_reply_fault(a.audio_service_op_open_stream, @intFromEnum(fault), 1);
        const expected = if (fault == .short or fault == .long) a.service_api_result_buffer_too_small else a.service_api_result_invalid;
        try std.testing.expectEqual(expected, switch (audio.openStream(48_000, 2, .s16le, 0x10000, r4os.time_contract.timeoutForever())) {
            .failure => |raw| raw,
            else => return error.InconsistentOpenAdopted,
        });
        try std.testing.expectEqual(@as(u32, 0), open_connections);
    }
    for ([_]u32{ 1, 91, std.math.maxInt(i32) }) |id| {
        const audio = replyTestAudio();
        platform_stream_id = id;
        var stream = try replyTestStream(&audio);
        try std.testing.expect(stream.valid() and stream.stream_id == id);
        try std.testing.expect(stream.close(r4os.time_contract.timeoutForever()) == .ok);
        try std.testing.expectEqual(@as(u32, 0), open_connections);
    }
    const audio = replyTestAudio();
    sdk_platform_oracle_reply_fault(a.audio_service_op_open_stream, @intFromEnum(ReplyFault.remote_error), 1);
    try std.testing.expectEqual(a.service_api_result_bad_handle, switch (audio.openStream(48_000, 2, .s16le, 0x10000, r4os.time_contract.timeoutForever())) {
        .failure => |raw| raw,
        else => return error.RemoteErrorLost,
    });
    try std.testing.expectEqual(@as(u32, 0), open_connections);
}

test "advanced synth operations and R4DEV views stay explicit" {
    var facades = initFacades();
    const advanced = facades.audio.advanced();
    try std.testing.expectEqual(@as(i32, 11), advanced.sidAcquire());
    try std.testing.expectEqual(@as(i32, 0), advanced.sidWriteRegister(11, 0, 1));
    try std.testing.expectEqual(@as(i32, 12), advanced.midiOpenSynth("OPL3"));
    try std.testing.expectEqual(@as(i32, 0), advanced.midiSend(12, 0, 0x90, 60, 100));
    try std.testing.expectEqual(@as(i32, 0), advanced.opl3Reset());
    const inventory = facades.devices.inventory();
    const display_state = facades.devices.display().?;
    try std.testing.expectEqual(@as(u64, 7), display_state.device_generation);
    try std.testing.expectEqual(r4os.abi.display_policy_software_once, display_state.policy);
    const full_size = dev_table.size;
    dev_table.size = @offsetOf(r4os.abi.R4XStartR4Dev, "display_state");
    try std.testing.expectEqual(@as(?r4os.abi.DisplayStateInfo, null), facades.devices.display());
    dev_table.size = full_size;
    try std.testing.expectEqual(@as(u32, 2), inventory.summary().?.total);
    try std.testing.expectEqual(@as(u32, 4), inventory.hardware().?.cpu_logical_processors);
    const memory = facades.devices.memory();
    try std.testing.expectEqual(@as(u64, 64 * 1024 * 1024), memory.summary().?.physical_bytes);
    try std.testing.expectEqual(@as(u32, 3), memory.blockCount());
    const performance = facades.devices.performance();
    try std.testing.expectEqual(@as(u64, 9), performance.summary().?.audio_stream_writes);
    const storage = performance.programInstanceStorage().?;
    try std.testing.expectEqual(@as(u32, 2), storage.version);
    try std.testing.expectEqual(@as(u32, @sizeOf(r4os.abi.ProgramInstanceStorageSummary)), storage.size);
    try std.testing.expectEqual(@as(u32, 4), storage.active_instances);
    try std.testing.expectEqual(@as(u64, 4096), storage.current_payload_bytes);
    try std.testing.expectEqual(@as(u64, 8192), storage.current_gui_frame_bytes);
    var current_storage: r4os.abi.ProgramInstanceStorageSummary = .{};
    current_storage.version = 3;
    current_storage.size = @sizeOf(r4os.abi.ProgramInstanceStorageSummary);
    try std.testing.expect(performance.raw.programInstanceStorageSummaryV2(&current_storage) > 0);
    try std.testing.expectEqual(@as(u32, 2), current_storage.version);
    @memset(std.mem.asBytes(&current_storage), 0xB6);
    current_storage.version = 0;
    current_storage.size = @sizeOf(r4os.abi.ProgramInstanceStorageSummary) - 1;
    try std.testing.expectEqual(@as(i32, -1), performance.raw.programInstanceStorageSummaryV2(&current_storage));
    try std.testing.expectEqual(@as(u32, 0), current_storage.version);
    try std.testing.expectEqual(@as(u32, @sizeOf(r4os.abi.ProgramInstanceStorageSummary) - 1), current_storage.size);
    try std.testing.expectEqual(@as(u8, 0xB6), std.mem.asBytes(&current_storage)[8]);
    dev_table.size = 288;
    // Missing current capacity never selects an inactive diagnostic slot.
    try std.testing.expectEqual(@as(?r4os.abi.ProgramInstanceStorageSummary, null), performance.programInstanceStorage());
    var storage_test: r4os.abi.ProgramInstanceStorageSelfTestResult = .{};
    try std.testing.expect(performance.programInstanceStorageSelfTest(&storage_test) > 0);
    try std.testing.expectEqual(@as(u32, 27), storage_test.passed_cases);
    try std.testing.expectEqual(@as(u32, 0xF), storage_test.flags);
    const execution = performance.executionInventory().?;
    try std.testing.expectEqual(r4os.abi.program_inventory_version, execution.version);
    try std.testing.expectEqual(@as(u32, 17), execution.program_total);
    try std.testing.expectEqual(@as(u32, 29), execution.task_total);
    try std.testing.expectEqual(@as(u32, 23), execution.thread_total);
    var direct_execution: r4os.abi.ProgramInventorySummary = .{};
    try std.testing.expectEqual(r4os.abi.program_handle_ok, facades.devices.raw.executionInventorySummary(&direct_execution));
    try std.testing.expectEqual(@as(u32, 41), direct_execution.program_peak);
}
