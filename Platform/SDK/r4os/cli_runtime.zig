//! One shared freestanding argument/diagnostic implementation for C and Rust.
const std = @import("std");
const args = @import("arg_cursor.zig");
const diag = @import("diagnostic_buffer.zig");
const wire = @import("binary_cursor.zig");
const sinks = @import("diagnostic_sinks.zig");
pub export fn R4SdkDiagnosticConsoleSend(context: ?*anyopaque, chunk: *const diag.Chunk) callconv(.c) diag.Ack {
    return sinks.ConsoleSink.send(context, chunk);
}
pub export fn R4SdkDiagnosticFileSend(context: ?*anyopaque, chunk: *const diag.Chunk) callconv(.c) diag.Ack {
    return sinks.FileSink.send(context, chunk);
}
pub export fn R4SdkDiagnosticLogSend(context: ?*anyopaque, chunk: *const diag.Chunk) callconv(.c) diag.Ack {
    return sinks.LogSink.send(context, chunk);
}
pub export fn R4SdkDiagnosticLogClose(raw: ?*sinks.LogSink) callconv(.c) i32 {
    return (raw orelse return sinks.invalid).closePending();
}
fn bytes(data: ?[*]const u8, length: usize) wire.Error![]const u8 {
    const span = wire.Span{ .address = if (data) |p| @intFromPtr(p) else 0, .length = length };
    return span.bytes();
}
fn argFailure(output: ?*args.Failure, err: args.Error, offset: usize) i32 {
    if (output) |out| out.* = .{ .code = args.code(err), .offset = offset };
    return args.code(err);
}
pub export fn R4SdkArgInit(data: ?[*]const u8, length: usize, policy: args.Policy, out: ?*args.ArgCursor, failure: ?*args.Failure) callconv(.c) i32 {
    const target = out orelse return argFailure(failure, error.InvalidState, 0);
    const input = bytes(data, length) catch |err| return argFailure(failure, if (err == error.LengthOverflow) error.LengthOverflow else error.InvalidState, 0);
    var info: args.Failure = .{};
    const result = args.ArgCursor.init(input, policy, &info) catch |err| return argFailure(failure, err, info.offset);
    target.* = result;
    if (failure) |p| p.* = .{};
    return 0;
}
pub export fn R4SdkArgNext(raw: ?*args.ArgCursor, out: ?*args.Token, failure: ?*args.Failure) callconv(.c) i32 {
    const target = out orelse return argFailure(failure, error.InvalidState, 0);
    const cursor = raw orelse return argFailure(failure, error.InvalidState, 0);
    const result = cursor.next() catch |err| return argFailure(failure, err, if (cursor.error_code == args.code(err)) cursor.error_offset else cursor.position);
    if (failure) |p| p.* = .{};
    if (result) |token| {
        target.* = token;
        return 0;
    }
    return 1;
}
pub export fn R4SdkArgRemaining(raw: ?*const args.ArgCursor, trim: u32, start: ?*usize, length: ?*usize) callconv(.c) i32 {
    const begin = start orelse return -7;
    const count = length orelse return -7;
    const cursor = raw orelse return -7;
    if (trim > 1) return -1;
    const suffix = (if (trim == 0) cursor.remainingRaw() else cursor.remainingArguments()) catch |err| return args.code(err);
    begin.* = cursor.length - suffix.len;
    count.* = suffix.len;
    return 0;
}
pub const ArgSwitch = extern struct {
    name_start: usize = 0,
    name_length: usize = 0,
    value_start: usize = 0,
    value_length: usize = 0,
    is_switch: u32 = 0,
    has_value: u32 = 0,
};
pub export fn R4SdkArgSwitchParts(data: ?[*]const u8, length: usize, token: args.Token, out: ?*ArgSwitch) callconv(.c) i32 {
    const target = out orelse return -7;
    const input = bytes(data, length) catch |err| return if (err == error.LengthOverflow) -8 else -7;
    const parts = token.switchParts(input) catch |err| return args.code(err);
    var result: ArgSwitch = .{};
    if (parts) |view| {
        result.is_switch = 1;
        result.name_start = token.value_start + 1;
        result.name_length = view.name.len;
        if (view.value) |value| {
            result.has_value = 1;
            result.value_start = result.name_start + result.name_length + 1;
            result.value_length = value.len;
        }
    }
    target.* = result;
    return 0;
}
fn diagError(err: diag.Error) i32 {
    return switch (err) {
        error.InvalidBuffer => -1,
        error.InvalidState => -2,
        error.Busy => -3,
        error.InvalidText => -4,
        error.InvalidSeverity => -5,
        error.Aliasing => -6,
        error.InvalidBudget => -7,
        error.LengthOverflow => -8,
    };
}
pub export fn R4SdkDiagnosticInit(data: ?[*]u8, length: usize, out: ?*diag.BoundedDiagnosticBuffer) callconv(.c) i32 {
    const target = out orelse return -1;
    const storage = bytes(data, length) catch |err| return if (err == error.LengthOverflow) -8 else -1;
    target.* = diag.BoundedDiagnosticBuffer.init(@constCast(storage)) catch |err| return diagError(err);
    return 0;
}
pub export fn R4SdkDiagnosticAppendRecord(raw: ?*diag.BoundedDiagnosticBuffer, data: ?[*]const u8, length: usize, severity: u32, out: ?*diag.AppendResult) callconv(.c) i32 {
    const target = out orelse return -1;
    const owner = raw orelse return -2;
    const level = std.enums.fromInt(diag.Severity, severity) orelse return -5;
    const text = bytes(data, length) catch |err| return if (err == error.LengthOverflow) -8 else -1;
    target.* = owner.appendRecord(text, level) catch |err| return diagError(err);
    return 0;
}
pub export fn R4SdkDiagnosticFlushOnce(raw: ?*diag.BoundedDiagnosticBuffer, max_bytes: u32, sink: ?diag.Sink, context: ?*anyopaque, out: ?*diag.FlushResult) callconv(.c) i32 {
    const target = out orelse return -1;
    const owner = raw orelse return -2;
    const callback = sink orelse return -1;
    target.* = owner.flushOnce(max_bytes, callback, context) catch |err| return diagError(err);
    return 0;
}
pub export fn R4SdkDiagnosticReadStats(raw: ?*const diag.BoundedDiagnosticBuffer, out: ?*diag.Stats) callconv(.c) i32 {
    const target = out orelse return -1;
    const owner = raw orelse return -2;
    target.* = owner.stats() catch |err| return diagError(err);
    return 0;
}
pub export fn R4SdkDiagnosticDiscardAll(raw: ?*diag.BoundedDiagnosticBuffer, out: ?*diag.DiscardResult) callconv(.c) i32 {
    const target = out orelse return -1;
    const owner = raw orelse return -2;
    target.* = owner.discard() catch |err| return diagError(err);
    return 0;
}
