const std = @import("std");
const r4x_api = @import("../program/r4x_api.zig");
const heap = @import("../memory/heap.zig");
const log_event = @import("log_event.zig");
const r4sys = @import("../program/r4sys.zig");
const registry = @import("../protocol/registry.zig");

pub const MAGIC: u32 = 0x31495050; // "PPI1" little endian
pub const VERSION: u32 = 1;

pub const ProtocolStatus = r4x_api.ProtocolStatus;

pub const ProtocolBuffer = r4x_api.ProtocolBuffer;

pub const Table = extern struct {
    magic: u32,
    version: u32,
    size: u32,
    reserved: u32,
    log_info: *const fn ([*:0]const u8) callconv(.c) void,
    log_warn: *const fn ([*:0]const u8) callconv(.c) void,
    log_error: *const fn ([*:0]const u8) callconv(.c) void,
    register_role: *const fn ([*:0]const u8, u32, u32) callconv(.c) i32,
    set_status: *const fn (u32, [*:0]const u8) callconv(.c) i32,
    dependency_status: *const fn ([*:0]const u8) callconv(.c) i32,
    alloc: *const fn (u32, u32) callconv(.c) ?*anyopaque,
    free: *const fn (?*anyopaque, u32) callconv(.c) void,
    file_read: *const fn ([*:0]const u8, [*]u8, u32) callconv(.c) i32,
};

var current_slot: ?usize = null;

pub var table = initialTable();
fn initialTable() Table {
    return Table{
        .magic = MAGIC,
        .version = VERSION,
        .size = @sizeOf(Table),
        .reserved = 0,
        .log_info = logInfo,
        .log_warn = logWarn,
        .log_error = logError,
        .register_role = registerRole,
        .set_status = setStatus,
        .dependency_status = dependencyStatus,
        .alloc = alloc,
        .free = free,
        .file_read = fileRead,
    };
}

pub fn enter(slot: usize) void {
    current_slot = slot;
}

pub fn leave() void {
    current_slot = null;
}

fn logInfo(text: [*:0]const u8) callconv(.c) void {
    log_event.protocol(log_event.Severity.info, currentSlotId(), text);
}

fn logWarn(text: [*:0]const u8) callconv(.c) void {
    log_event.protocol(log_event.Severity.warn, currentSlotId(), text);
}

fn logError(text: [*:0]const u8) callconv(.c) void {
    log_event.protocol(log_event.Severity.err, currentSlotId(), text);
}

fn registerRole(role_z: [*:0]const u8, category: u32, flags: u32) callconv(.c) i32 {
    _ = category;
    _ = flags;
    const slot = current_slot orelse return -6;
    const role = zSlice(role_z);
    if (!registry.roleMatches(slot, role)) {
        registry.setError(slot, -2, "registered role does not match R4P header");
        return -2;
    }
    return 0;
}

fn setStatus(state: u32, note_z: [*:0]const u8) callconv(.c) i32 {
    const slot = current_slot orelse return -6;
    registry.setStatus(slot, state, zSlice(note_z));
    return 0;
}

fn dependencyStatus(role_z: [*:0]const u8) callconv(.c) i32 {
    return registry.dependencyStatus(zSlice(role_z));
}

fn alloc(bytes: u32, alignment: u32) callconv(.c) ?*anyopaque {
    const mem = heap.alloc(bytes, alignment) orelse return null;
    return mem.ptr;
}

fn free(ptr: ?*anyopaque, bytes: u32) callconv(.c) void {
    const address = ptr orelse return;
    if (bytes == 0) return;
    const mem: [*]u8 = @ptrCast(address);
    _ = heap.free(mem[0..bytes]);
}

fn fileRead(path: [*:0]const u8, out: [*]u8, max_len: u32) callconv(.c) i32 {
    return r4sys.fileRead(path, out, max_len);
}

fn zSlice(text: [*:0]const u8) []const u8 {
    var len: usize = 0;
    while (text[len] != 0 and len < 512) : (len += 1) {}
    return text[0..len];
}

fn currentSlotId() u32 {
    return if (current_slot) |slot| @intCast(slot) else 0xFFFF_FFFF;
}

const api2 = @import("../program/generation2.zig");
pub const table2: api2.abi.ProtocolApi2 = initTable2();
fn initTable2() api2.abi.ProtocolApi2 {
    @setEvalBranchQuota(2_000_000);
    return .{
        .magic = api2.abi.protocol_magic,
        .version = api2.abi.protocol_version,
        .size = @sizeOf(api2.abi.ProtocolApi2),
        .reserved = 0,
        .log_info = api2.callback(@FieldType(api2.abi.ProtocolApi2, "log_info"), &logInfo),
        .log_warn = api2.callback(@FieldType(api2.abi.ProtocolApi2, "log_warn"), &logWarn),
        .log_error = api2.callback(@FieldType(api2.abi.ProtocolApi2, "log_error"), &logError),
        .register_role = api2.callback(@FieldType(api2.abi.ProtocolApi2, "register_role"), &registerRole),
        .set_status = api2.callback(@FieldType(api2.abi.ProtocolApi2, "set_status"), &setStatus),
        .dependency_status = api2.callback(@FieldType(api2.abi.ProtocolApi2, "dependency_status"), &dependencyStatus),
        .alloc = api2.callback(@FieldType(api2.abi.ProtocolApi2, "alloc"), &alloc),
        .free = api2.callback(@FieldType(api2.abi.ProtocolApi2, "free"), &free),
        .file_read = api2.callback(@FieldType(api2.abi.ProtocolApi2, "file_read"), &fileRead),
        .cpu_acceleration_info = api2.callback(@FieldType(api2.abi.ProtocolApi2, "cpu_acceleration_info"), &@import("../platform/cpu_acceleration.zig").info),
        .cpu_acceleration_work = api2.callback(@FieldType(api2.abi.ProtocolApi2, "cpu_acceleration_work"), &@import("../platform/cpu_acceleration.zig").work),
        .entropy_source_info = null,
        .entropy_fill = null,
        .protocol_dispatch = null,
        .link_io = null,
        .process_status = null,
    };
}
