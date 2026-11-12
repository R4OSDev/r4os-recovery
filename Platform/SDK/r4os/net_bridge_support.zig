// SDK-local scalar ABI for the existing Zig networking owner. No transport,
// parser, socket state machine or kernel resource owner is implemented here.
const std = @import("std");
pub const abi = @import("r4os_contract").abi;
pub const program = @import("program.zig");
pub const net = @import("r4net.zig");
pub const Options = extern struct { has_server: u32, server: [4]u8 };
pub const Slice = extern struct { ptr: ?[*]const u8 = null, length: usize = 0, valid: u32 = 0, reserved: u32 = 0 };
pub const Request = extern struct { data: [@sizeOf(program.NetSocketRequest)]u8 align(@alignOf(program.NetSocketRequest)) };

pub fn flatRecord(comptime Source: type) type {
    const fields = @typeInfo(Source).@"struct".fields;
    var names: [fields.len][:0]const u8 = undefined;
    var types: [fields.len]type = undefined;
    for (fields, 0..) |field, i| {
        names[i] = field.name;
        types[i] = if (field.type == bool) u8 else field.type;
    }
    return @Struct(.@"extern", null, &names, &types, &@splat(.{}));
}
pub const ResolverResult = flatRecord(program.ResolverResult);
pub const Readiness = flatRecord(program.TcpReadiness);
pub fn flatten(comptime Destination: type, source: anytype) Destination {
    var result: Destination = undefined;
    inline for (@typeInfo(Destination).@"struct".fields) |field| {
        const value = @field(source, field.name);
        @field(result, field.name) = if (@TypeOf(value) == bool) @intFromBool(value) else value;
    }
    return result;
}
pub fn slice(value: ?[]const u8) Slice {
    const bytes = value orelse return .{};
    return .{ .ptr = bytes.ptr, .length = bytes.len, .valid = 1 };
}
pub fn request(value: *Request) *program.NetSocketRequest { return @ptrCast(@alignCast(value)); }
pub fn requestConst(value: *const Request) *const program.NetSocketRequest { return @ptrCast(@alignCast(value)); }
pub fn bundle(context: *const abi.R4XStartContext) ?program.Bundle {
    const result = program.bundleValueFromR4XStart(context) orelse return null;
    const sys = result.sys orelse return null;
    const current = abi.R4XStartR4Sys{};
    if (sys.abi_version < current.abi_version or sys.size < current.size) return null;
    if (result.net) |table| {
        const expected = abi.R4XStartR4Net{};
        if (table.abi_version < expected.abi_version or table.size < expected.size) return null;
    }
    return result;
}
