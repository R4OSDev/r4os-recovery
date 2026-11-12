const std = @import("std");
const abi = @import("r4os_technical_abi");
const api2 = @import("r4os_generation2");
const c = @cImport({
    @cInclude("r4os/abi_generated.h");
});

extern fn r4os_c_generation2(*const api2.R4XStartContext2, *const api2.R4XStartR4Sys2) callconv(.c) i32;
extern fn r4os_rust_generation2(*const api2.R4XStartContext2, *const api2.R4XStartR4Sys2) callconv(.c) i32;
test "generation2 C Rust Zig layouts defaults and callable slots agree" {
    const Provider = struct {
        fn write(data: [*]const u8, len: u32) callconv(.c) i32 {
            return if (len == 4 and std.mem.eql(u8, data[0..len], "API2")) -20002 else -1;
        }
    };
    const ctx: api2.R4XStartContext2 = .{};
    const table: api2.R4XStartR4Sys2 = .{ .write = @intFromPtr(&Provider.write) };
    try std.testing.expectEqual(@as(i32, -20002), r4os_c_generation2(&ctx, &table));
    try std.testing.expectEqual(@as(i32, -20002), r4os_rust_generation2(&ctx, &table));
}

test "all canonical C and Rust-projected structures retain every field layout" {
    @setEvalBranchQuota(10000000);
    inline for (comptime std.meta.declarations(abi)) |decl| {
        const T = @field(abi, decl.name);
        if (@TypeOf(T) != type) continue;
        switch (@typeInfo(T)) {
            .@"struct" => |s| {
                if (s.layout != .@"extern") continue;
                const name = if (@hasDecl(c, decl.name)) decl.name else "R4" ++ decl.name;
                const C = @field(c, name);
                try std.testing.expectEqual(@sizeOf(T), @sizeOf(C));
                try std.testing.expectEqual(@alignOf(T), @alignOf(C));
                inline for (s.fields) |field| {
                    // C keywords have a trailing underscore. Their byte
                    // layout and the canonical Zig field name stay intact.
                    const c_field = if (@hasField(C, field.name)) field.name else field.name ++ "_";
                    try std.testing.expectEqual(@offsetOf(T, field.name), @offsetOf(C, c_field));
                    const Field = @TypeOf(@field(@as(C, undefined), c_field));
                    try std.testing.expectEqual(@sizeOf(field.type), @sizeOf(Field));
                    try std.testing.expectEqual(@alignOf(field.type), @alignOf(Field));
                    if (@typeInfo(field.type) == .int) {
                        try std.testing.expectEqual(@typeInfo(field.type).int.signedness, @typeInfo(Field).int.signedness);
                    }
                }
            },
            .@"enum" => {
                const name = if (@hasDecl(c, decl.name)) decl.name else "R4" ++ decl.name;
                const C = @field(c, name);
                try std.testing.expectEqual(@sizeOf(T), @sizeOf(C));
                try std.testing.expectEqual(@alignOf(T), @alignOf(C));
                try std.testing.expectEqual(@typeInfo(@typeInfo(T).@"enum".tag_type).int.signedness, @typeInfo(C).int.signedness);
            },
            else => {},
        }
    }
}

extern fn r4os_rust_protocol_alloc(*const abi.ProtocolApi, u32, u32) callconv(.c) ?*anyopaque;
extern fn r4os_rust_model_name() callconv(.c) [*:0]const u8;
extern fn r4os_c_technical_callbacks(*const fn (*const abi.ProtocolApi, u32, u32) callconv(.c) ?*anyopaque, abi.R4AudioFns.sid_model_name) callconv(.c) i32;
extern fn r4os_c_gui_window_flag(u32) callconv(.c) u32;

test "technical C table roundtrip preserves nullable and sentinel pointer returns" {
    try std.testing.expectEqual(@as(i32, 0), r4os_c_technical_callbacks(r4os_rust_protocol_alloc, r4os_rust_model_name));
    const flags = [_]u32{ abi.GuiWindowFlag.visible, abi.GuiWindowFlag.minimized, abi.GuiWindowFlag.maximized, abi.GuiWindowFlag.close_requested };
    for (flags, 0..) |flag, index| try std.testing.expectEqual(flag, r4os_c_gui_window_flag(@intCast(index)));
    try std.testing.expectEqual(@as(u32, 0), r4os_c_gui_window_flag(flags.len));
}

extern fn r4os_c_console_events(*const abi.ProgramProcessHandle, [*]const abi.ConsoleInputEvent, u32) callconv(.c) i32;
extern fn r4os_rust_console_events(*const abi.ProgramProcessHandle, [*]const abi.ConsoleInputEvent, u32) callconv(.c) i32;

test "console typed scalar key and stream-byte records preserve exact generation and event prefix count across C Rust Zig" {
    const handle: abi.ProgramProcessHandle = .{ .instance_id = 37, .generation = 0xfedcba9876543210 };
    const events = [_]abi.ConsoleInputEvent{
        .{ .kind = abi.console_input_event_text, .value = 0x20ac },
        .{ .kind = abi.console_input_event_key, .value = abi.console_input_key_up },
        .{ .kind = abi.console_input_event_utf8_byte, .value = 0x81 },
        .{ .kind = abi.console_input_event_text, .value = 0x1f600 },
    };
    const callbacks = [_]abi.R4DeskFns.console_push_events{ r4os_c_console_events, r4os_rust_console_events };
    for (callbacks) |callback| try std.testing.expectEqual(@as(i32, 3), callback(&handle, &events, events.len));
}
extern fn r4os_rust_write() callconv(.c) abi.R4SysFns.write;
extern fn r4os_rust_call_write(abi.R4SysFns.write) callconv(.c) i32;
extern fn r4os_rust_service_call() callconv(.c) abi.R4SysFns.service_call;
extern fn r4os_rust_driver_work(*const abi.DriverWorkRequest, *u32) callconv(.c) i32;
extern fn r4os_rust_optional_callback(?abi.DriverWorkHandler, usize) callconv(.c) i32;
extern fn r4os_rust_protocol_buffer(*const abi.ProtocolBuffer, *abi.ProtocolBuffer) callconv(.c) i32;
extern fn r4os_rust_enum(abi.DriverType) callconv(.c) abi.DriverType;
extern fn r4os_rust_default_header(*abi.ServiceMessageHeader) callconv(.c) void;
extern fn r4os_c_rust_call(abi.R4SysFns.write, [*]const u8, u32) callconv(.c) i32;
extern fn r4os_rust_pmu_measure() callconv(.c) abi.R4DevFns.cpu_pmu_measure;
extern fn r4os_c_pmu_work(u64, u32) callconv(.c) i32;
extern fn r4os_rust_acceleration_info() callconv(.c) abi.R4DevFns.cpu_acceleration_info;
extern fn r4os_rust_acceleration_work() callconv(.c) abi.R4DevFns.cpu_acceleration_work;
extern fn r4os_c_pure_work(u64, u32) callconv(.c) i32;

fn zigWrite(data: [*]const u8, size: u32) callconv(.c) i32 {
    if (size != 9 or !std.mem.eql(u8, data[0..size], "R4OS-Rust")) return -1;
    return -32123;
}
fn work(context: usize) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef) -32768 else -1;
}

fn pmuWork(context: u64, iterations: u32) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef and iterations == 4096) -30007 else -1;
}
fn pureWork(context: u64, iterations: u32) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef and iterations == 64) -30017 else -1;
}

test "canonical Rust/Zig/C callbacks, nullability, stack arguments and SIMD consumer" {
    const rust_write = r4os_rust_write();
    try std.testing.expectEqual(@as(i32, -12345), rust_write("R4OS-Rust", 9));
    try std.testing.expectEqual(@as(i32, -32123), r4os_rust_call_write(zigWrite));
    try std.testing.expectEqual(@as(i32, -12345), r4os_c_rust_call(rust_write, "R4OS-Rust", 9));

    var header: abi.ServiceMessageHeader = .{};
    var reply: [3]u8 = undefined;
    const service_call = r4os_rust_service_call();
    try std.testing.expectEqual(@as(i32, -32767), service_call(0xfedc_ba98, 0xabc7, "R4OS-Rust", 9, &header, &reply, 3, 0xfedc_ba98_7654_3210));
    try std.testing.expectEqual(@as(u16, 0xabc7), header.op);
    try std.testing.expectEqual(@as(u32, 0xfedc_ba98), header.request_id);
    try std.testing.expectEqual(@as(i32, -32767), header.status);
    try std.testing.expectEqualStrings("ACK", &reply);

    const request: abi.DriverWorkRequest = .{ .handler = work, .context = 0x8123_4567_89ab_cdef, .serial_key = 0x8123_4567_89ab_cdef, .deadline_tick = 0xfedc_ba98_7654_3210, .budget_ticks = 4 };
    var ticket: u32 = 0;
    try std.testing.expectEqual(@as(i32, -32768), r4os_rust_driver_work(&request, &ticket));
    try std.testing.expectEqual(@as(u32, 0xfedc_ba98), ticket);
    try std.testing.expectEqual(abi.err_no_fn, r4os_rust_optional_callback(null, 0));
    try std.testing.expectEqual(@as(i32, -32768), r4os_rust_optional_callback(work, request.context));

    var data = [_]u8{0} ** 16;
    const source: abi.ProtocolBuffer = .{ .data = &data, .len = 9, .capacity = 16, .flags = 0x8000_0001 };
    var output: abi.ProtocolBuffer = .{};
    try std.testing.expectEqual(@as(i32, 17), r4os_rust_protocol_buffer(&source, &output));
    try std.testing.expectEqual(source.data, output.data);
    try std.testing.expectEqual(source.flags, output.flags);
    var null_source = source;
    null_source.data = null;
    try std.testing.expectEqual(@as(i32, 17), r4os_rust_protocol_buffer(&null_source, &output));
    try std.testing.expectEqual(@as(?*anyopaque, null), output.data);
    try std.testing.expectEqual(abi.DriverType.display, r4os_rust_enum(.net));
    header.status = -1;
    r4os_rust_default_header(&header);
    const original_header: abi.ServiceMessageHeader = .{};
    try std.testing.expectEqual(original_header.magic, header.magic);
    try std.testing.expectEqual(@as(i32, 0), header.status);
}

test "PMU typed borrowed callback slot and seven-argument C ABI preserve result tail" {
    const measure = r4os_rust_pmu_measure();
    const sentinel: u64 = 0xfedc_ba98_7654_3210;
    var guarded: extern struct { result: abi.CpuPmuResult = .{}, tail: u64 = sentinel } = .{};
    const callbacks = [_]abi.PmuWorkFn{ pmuWork, r4os_c_pmu_work };
    for (callbacks, [_]i32{ -30007, -30005 }) |callback, expected| {
        guarded.result.size = @sizeOf(@TypeOf(guarded));
        try std.testing.expectEqual(@as(i32, 0), measure(0xfedc_ba98, sentinel, abi.cpu_pmu_event_branch_misses, 4096, &callback, 0x8123_4567_89ab_cdef, &guarded.result));
        try std.testing.expectEqual(sentinel, guarded.tail);
        try std.testing.expectEqual(sentinel, guarded.result.epoch);
        try std.testing.expectEqual(@as(u64, 0x8123_4567_89ab_cdef), guarded.result.generation);
        try std.testing.expectEqual(expected, guarded.result.callback_result);
        try std.testing.expectEqual(@as(u32, 256), guarded.result.size);
        try std.testing.expectEqual(abi.cpu_pmu_result_flag_callback_started | abi.cpu_pmu_result_flag_callback_returned, guarded.result.flags);
    }
    const original = guarded;
    var zero: u64 = 0;
    for ([_]?*const abi.PmuWorkFn{ null, @ptrCast(&zero) }) |callback_slot| {
        try std.testing.expectEqual(abi.cpu_capabilities_error_invalid, measure(0xfedc_ba98, sentinel, abi.cpu_pmu_event_branch_misses, 4096, callback_slot, 0x8123_4567_89ab_cdef, &guarded.result));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&original), std.mem.asBytes(&guarded));
    }
}

test "pure acceleration ABI keeps typed Rust Zig C slots, nullable refusal and128byte tails" {
    const sentinel: u64 = 0xfedc_ba98_7654_3210;
    var info: extern struct { value: abi.CpuAccelerationInfo = .{}, tail: u64 = sentinel } = .{};
    info.value.size = @sizeOf(@TypeOf(info));
    try std.testing.expectEqual(@as(i32, 0), r4os_rust_acceleration_info()(&info.value));
    try std.testing.expectEqual(sentinel, info.tail);
    try std.testing.expectEqual(sentinel, info.value.epoch);
    try std.testing.expectEqual(@as(u32, 128), info.value.size);
    try std.testing.expectEqual(@as(u64, 63), info.value.hardware_mask);
    try std.testing.expectEqual(@as(u64, 31), info.value.common_hardware_mask);
    var value: extern struct { value: abi.CpuAccelerationWork = .{}, tail: u64 = sentinel } = .{};
    const callbacks = [_]abi.CpuPureWorkFn{ pureWork, r4os_c_pure_work };
    const submit = r4os_rust_acceleration_work();
    for (callbacks, [_]i32{ -30017, -30015 }) |callback, expected| {
        value.value.size = @sizeOf(@TypeOf(value));
        try std.testing.expectEqual(@as(i32, 0), submit(abi.cpu_accel_work_kind_sha256, 64, &callback, 0x8123_4567_89ab_cdef, &value.value));
        try std.testing.expectEqual(sentinel, value.tail);
        try std.testing.expectEqual(sentinel, value.value.epoch);
        try std.testing.expectEqual(@as(u32, 128), value.value.size);
        try std.testing.expectEqual(@as(u32, 64), value.value.iterations);
        try std.testing.expectEqual(expected, value.value.callback_result);
        try std.testing.expectEqual(abi.cpu_accel_work_flag_callback_started | abi.cpu_accel_work_flag_callback_returned, value.value.flags);
    }
    const before = value;
    var zero: u64 = 0;
    for ([_]?*const abi.CpuPureWorkFn{ null, @ptrCast(&zero) }) |slot| {
        try std.testing.expectEqual(abi.cpu_capabilities_error_invalid, submit(abi.cpu_accel_work_kind_sha256, 64, slot, 0x8123_4567_89ab_cdef, &value.value));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&before), std.mem.asBytes(&value));
    }
    info.value.version = 0;
    const old = info;
    try std.testing.expectEqual(abi.cpu_capabilities_error_invalid, r4os_rust_acceleration_info()(&info.value));
    try std.testing.expectEqualSlices(u8, std.mem.asBytes(&old), std.mem.asBytes(&info));
}

extern fn r4os_rust_entropy_info() callconv(.c) abi.R4SysFns.entropy_source_info;
extern fn r4os_rust_entropy_callback(*const abi.EntropyBackend, [*]u8, u32, *abi.EntropyDeviceReceipt) callconv(.c) i32;
extern fn r4os_c_entropy_read(u64, [*]u8, u32, *abi.EntropyDeviceReceipt) callconv(.c) i32;
fn entropyRead(context: u64, data: [*]u8, bytes: u32, out: *abi.EntropyDeviceReceipt) callconv(.c) i32 {
    if (context != 0xfedc_ba98_7654_3210 or bytes != 17) return -1;
    @memcpy(data[0..17], "entropy-fixture!!");
    out.* = .{ .requested_bytes = bytes, .completed_bytes = bytes, .status = abi.entropy_device_status_bad_completion, .flags = abi.entropy_receipt_flag_retained, .request_generation = context, .available_index_before = 65534, .available_index_after = 3 };
    return -30029;
}
test "entropy source records and C Zig callback pointer bits cross Rust with exact signed results and tails" {
    const sentinel: u64 = 0x8123_4567_89ab_cdef;
    var info: extern struct { value: abi.EntropySourceInfo = .{}, tail: u64 = sentinel } = .{};
    info.value.size = @sizeOf(@TypeOf(info));
    try std.testing.expectEqual(@as(i32, 0), r4os_rust_entropy_info()(&info.value));
    try std.testing.expectEqual(sentinel, info.tail);
    try std.testing.expectEqual(sentinel, info.value.generation);
    try std.testing.expectEqual(@as(u64, 0xfedc_ba98_7654_3210), info.value.owner_epoch);
    try std.testing.expectEqual(@as(u16, 0x1044), info.value.device_id);
    try std.testing.expectEqual(@as(i32, -30021), info.value.last_result);
    try std.testing.expectEqual(@as(u32, 128), info.value.size);
    var receipt: extern struct { value: abi.EntropyDeviceReceipt = .{}, tail: u64 = sentinel } = .{};
    var data: [24]u8 = .{0xa5} ** 24;
    var backend: abi.EntropyBackend = .{ .context = 0xfedc_ba98_7654_3210, .max_request_bytes = 17 };
    for ([_]abi.EntropyReadFn{ entropyRead, r4os_c_entropy_read }, [_]i32{ -30029, -30027 }) |callback, expected| {
        backend.read = @intFromPtr(callback);
        receipt.value.size = @sizeOf(@TypeOf(receipt));
        try std.testing.expectEqual(expected, r4os_rust_entropy_callback(&backend, &data, 17, &receipt.value));
        try std.testing.expectEqualSlices(u8, "entropy-fixture!!", data[0..17]);
        try std.testing.expectEqualSlices(u8, &(.{0xa5} ** 7), data[17..]);
        try std.testing.expectEqual(sentinel, receipt.tail);
        try std.testing.expectEqual(@as(u32, 128), receipt.value.size);
        try std.testing.expectEqual(@as(u64, 0xfedc_ba98_7654_3210), receipt.value.request_generation);
        try std.testing.expectEqual(abi.entropy_device_status_bad_completion, receipt.value.status);
        try std.testing.expectEqual(abi.entropy_receipt_flag_retained, receipt.value.flags);
        try std.testing.expectEqual(@as(u32, 65534), receipt.value.available_index_before);
        try std.testing.expectEqual(@as(u32, 3), receipt.value.available_index_after);
    }
    const before = receipt;
    const before_data = data;
    backend.read = 0;
    try std.testing.expectEqual(abi.entropy_error_invalid, r4os_rust_entropy_callback(&backend, &data, 17, &receipt.value));
    try std.testing.expectEqualSlices(u8, std.mem.asBytes(&before), std.mem.asBytes(&receipt));
    try std.testing.expectEqualSlices(u8, &before_data, &data);
}
