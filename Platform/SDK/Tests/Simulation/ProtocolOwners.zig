const std = @import("std");
const a = @import("r4os_contract").abi;
const p = @import("protocol");
var memory: [64]u8 align(16) = undefined;
var logs: u32 = 0;
var freed = false;
fn log(text: [*:0]const u8) callconv(.c) void {
    std.debug.assert(text[0] == 'p');
    logs += 1;
}
fn role(text: [*:0]const u8, category: u32, flags: u32) callconv(.c) i32 {
    std.debug.assert(text[0] == 'm' and category == 255 and flags == 7);
    return 0;
}
fn status(state: u32, note: [*:0]const u8) callconv(.c) i32 {
    std.debug.assert(state == 2 and note[0] == 'p');
    return 0;
}
fn dependency(text: [*:0]const u8) callconv(.c) i32 {
    std.debug.assert(text[0] == 'm');
    return 1;
}
fn alloc(bytes: u32, alignment: u32) callconv(.c) ?*anyopaque {
    std.debug.assert(bytes == 64 and alignment == 16);
    return &memory;
}
fn free(pointer: ?*anyopaque, bytes: u32) callconv(.c) void {
    std.debug.assert(pointer == @as(?*anyopaque, @ptrCast(&memory)) and bytes == 64 and !freed);
    freed = true;
}
fn read(path: [*:0]const u8, out: [*]u8, len: u32) callconv(.c) i32 {
    std.debug.assert(path[0] == 'p' and len == 8);
    @memcpy(out[0..4], "p68!");
    return 4;
}
test "original Protocol Context forwards exact current API arguments" {
    const api: a.ProtocolApi = .{ .magic = a.protocol_magic, .version = a.protocol_api_version, .size = @sizeOf(a.ProtocolApi), .reserved = 0, .log_info = log, .log_warn = log, .log_error = log, .register_role = role, .set_status = status, .dependency_status = dependency, .alloc = alloc, .free = free, .file_read = read };
    const c = p.Context.init(&api);
    c.logInfo("p");
    c.logWarn("p");
    c.logError("p");
    try std.testing.expectEqual(@as(u32, 3), logs);
    try std.testing.expectEqual(@as(i32, 0), c.registerRole("misc.p68", .misc, 7));
    try std.testing.expectEqual(@as(i32, 0), c.setStatus(.active, "p"));
    try std.testing.expectEqual(@as(i32, 1), c.dependencyStatus("misc.p68"));
    var bytes: [8]u8 = undefined;
    try std.testing.expectEqual(@as(i32, 4), c.fileRead("p", &bytes));
    try std.testing.expectEqualStrings("p68!", bytes[0..4]);
    const allocation = c.alloc(64, 16) orelse return error.AllocationFailed;
    try std.testing.expect(!freed);
    c.free(allocation, 64);
    try std.testing.expect(freed);
}
