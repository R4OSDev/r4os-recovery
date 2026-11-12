const std = @import("std");
const builtin = @import("builtin");
const abi = @import("r4os_contract").abi;
const program = @import("program.zig");
const events = @import("input_events.zig");
fn push(handle: *const abi.ProgramProcessHandle, input: [*]const abi.ConsoleInputEvent, count: u32) callconv(.c) i32 {
    if (handle.instance_id != 37 or handle.generation != 0xfedcba9876543210 or count != 3) return -1;
    if (input[0].kind != 1 or input[0].value != 0x20ac or input[1].kind != 2 or input[1].value != 0x80 or input[2].kind != 3 or input[2].value != 0x81) return -2;
    return 2;
}
fn read(output: [*]abi.ConsoleInputEvent, capacity: u32) callconv(.c) i32 {
    if (capacity != 1) return -1;
    output[0] = events.text(0x1f600).?;
    return 1;
}
test "new event wrappers preserve kind generation complete-prefix counts and caller tails" {
    const raw: abi.R4XStartContext = .{};
    const table: abi.R4XStartR4Desk = .{ .console_push_events = @intFromPtr(&push), .console_read_events = @intFromPtr(&read) };
    const bundle: program.Bundle = .{ .raw = &raw, .desk = &table };
    const ctx = program.Context.initBundle(&bundle);
    const handle: abi.ProgramProcessHandle = .{ .instance_id = 37, .generation = 0xfedcba9876543210 };
    const input = [_]abi.ConsoleInputEvent{ events.text(0x20ac).?, events.key(0x80), events.utf8Byte(0x81) };
    try std.testing.expectEqual(@as(i32, 2), ctx.consolePushEvents(handle, &input));
    var guarded = [_]abi.ConsoleInputEvent{ events.text('A').?, events.text('Z').? };
    try std.testing.expectEqual(@as(i32, 1), ctx.consoleReadEvents(guarded[0..1]));
    try std.testing.expectEqual(@as(u32, 0x1f600), guarded[0].value);
    try std.testing.expectEqual(@as(u32, 'Z'), guarded[1].value);
}
test "old R4DESK table at inaccessible page refuses absent event tail without touching output" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;
    const page = 4096;
    const region = try std.posix.mmap(null, page * 2, .{ .READ = true, .WRITE = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(region);
    try std.testing.expectEqual(@as(usize, 0), std.os.linux.mprotect(region.ptr + page, page, .{}));
    const old: *abi.R4XStartR4Desk = @ptrCast(@alignCast(region.ptr + page - 536));
    @memset(region[page - 536 .. page], 0);
    old.magic = abi.r4xstart_r4desk_magic;
    old.abi_version = 15;
    old.size = 536;
    const raw: abi.R4XStartContext = .{};
    const bundle: program.Bundle = .{ .raw = &raw, .desk = old };
    const ctx = program.Context.initBundle(&bundle);
    var output = [_]abi.ConsoleInputEvent{events.text(0x401).?};
    try std.testing.expectEqual(abi.err_no_fn, ctx.consoleReadEvents(&output));
    try std.testing.expectEqual(abi.err_no_fn, ctx.consolePushEvents(.{}, &output));
    try std.testing.expectEqual(@as(u32, 0x401), output[0].value);
}
test { _ = events; }

fn textInfo(handle: *const abi.ProgramProcessHandle, out: *abi.ConsoleTextInfo) callconv(.c) i32 {
    if (handle.instance_id != 39 or handle.generation != 0xfedcba9876543210) return -1;
    out.* = .{ .encoding = 437, .pending_bytes = 3, .decode_errors = 7 };
    return 0;
}
fn setEncoding(handle: *const abi.ProgramProcessHandle, encoding: u32) callconv(.c) i32 {
    return if (handle.instance_id == 39 and handle.generation == 0xfedcba9876543210 and encoding == 437) 0 else -2;
}
test "console text wrappers retain exact generation encoding fixed metadata and caller tail" {
    const raw: abi.R4XStartContext = .{};
    const table: abi.R4XStartR4Desk = .{ .console_text_info = @intFromPtr(&textInfo), .console_set_encoding = @intFromPtr(&setEncoding) };
    const bundle: program.Bundle = .{ .raw = &raw, .desk = &table };
    const ctx = program.Context.initBundle(&bundle);
    const handle: abi.ProgramProcessHandle = .{ .instance_id = 39, .generation = 0xfedcba9876543210 };
    var guarded = [_]abi.ConsoleTextInfo{ .{}, .{ .decode_errors = 0xfeed1234 } };
    try std.testing.expectEqual(@as(i32, 0), ctx.consoleTextInfo(handle, &guarded[0]));
    try std.testing.expectEqual(@as(u32, 437), guarded[0].encoding);
    try std.testing.expectEqual(@as(u32, 65001), guarded[0].transcript_encoding);
    try std.testing.expectEqual(@as(u32, 3), guarded[0].pending_bytes);
    try std.testing.expectEqual(@as(u32, 0xfeed1234), guarded[1].decode_errors);
    try std.testing.expectEqual(@as(i32, 0), ctx.consoleSetEncoding(handle, 437));
}
test "R4DESK16 ending at inaccessible page refuses both console text slots" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;
    const page = 4096;
    const region = try std.posix.mmap(null, page * 2, .{ .READ = true, .WRITE = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(region);
    try std.testing.expectEqual(@as(usize, 0), std.os.linux.mprotect(region.ptr + page, page, .{}));
    const old: *abi.R4XStartR4Desk = @ptrCast(@alignCast(region.ptr + page - 552));
    @memset(region[page - 552 .. page], 0);
    old.magic = abi.r4xstart_r4desk_magic;
    old.abi_version = 16;
    old.size = 552;
    const raw: abi.R4XStartContext = .{};
    const bundle: program.Bundle = .{ .raw = &raw, .desk = old };
    const ctx = program.Context.initBundle(&bundle);
    var output: abi.ConsoleTextInfo = .{ .decode_errors = 0x12345678 };
    try std.testing.expectEqual(abi.err_no_fn, ctx.consoleTextInfo(.{}, &output));
    try std.testing.expectEqual(abi.err_no_fn, ctx.consoleSetEncoding(.{}, 437));
    try std.testing.expectEqual(@as(u32, 0x12345678), output.decode_errors);
}
