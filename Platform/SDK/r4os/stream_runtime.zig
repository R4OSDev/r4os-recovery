//! Shared static transfer owner for C/Rust; all loans follow its synchronous
//! callbacks. No stream/peer handle ownership is transferred here.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const core = @import("stream_transfer.zig");
const adapters = @import("stream_adapters.zig");
const budget = @import("time_budget.zig");
const wire = @import("binary_cursor.zig");
fn code(err: core.Error) i32 {
    return switch (err) {
        error.InvalidState => -1,
        error.InvalidMode => -2,
        error.InvalidBuffer => -3,
        error.InvalidLimit => -4,
        error.Busy => -5,
        error.LengthOverflow => -6,
        error.ClockUnavailable => -101,
        error.ClockChanged => -102,
        error.ClockRegressed => -103,
        error.UnknownFrequency => -105,
        error.BudgetOverflow => -106,
        error.InvalidTimeout => -107,
        error.InvalidBudget => -104,
    };
}
pub export fn R4SdkTransferInit(mode: u32, total: u64, initial: budget.ClockSample, timeout: abi.R4Timeout, out: ?*core.Transfer) callconv(.c) i32 {
    const target = out orelse return -1;
    const selected = std.enums.fromInt(core.Mode, mode) orelse return -2;
    target.* = core.Transfer.init(selected, total, initial, timeout) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTransferInitAbsolute(mode: u32, total: u64, deadline: budget.DeadlineBudget, out: ?*core.Transfer) callconv(.c) i32 {
    const target = out orelse return -1;
    const selected = std.enums.fromInt(core.Mode, mode) orelse return -2;
    target.* = core.Transfer.initAbsolute(selected, total, deadline) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTransferGetProgress(raw: ?*const core.Transfer, out: ?*core.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -3;
    target.* = state.progress() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTransferCancel(raw: ?*core.Transfer, out: ?*core.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -3;
    target.* = state.cancel() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTransferReadStep(raw: ?*core.Transfer, data: ?[*]u8, length: usize, limit: u32, stop: u32, clock: ?core.Clock, clock_context: ?*anyopaque, reader: ?core.Read, context: ?*anyopaque, out: ?*core.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -3;
    if (stop > 1) return -1;
    const span = wire.Span{ .address = if (data) |p| @intFromPtr(p) else 0, .length = length };
    const storage = span.bytes() catch return -3;
    target.* = state.readStep(@constCast(storage), limit, stop != 0, clock orelse return -3, clock_context, reader orelse return -3, context) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTransferWriteStep(raw: ?*core.Transfer, data: ?[*]const u8, length: usize, limit: u32, stop: u32, clock: ?core.Clock, clock_context: ?*anyopaque, writer: ?core.Write, context: ?*anyopaque, out: ?*core.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -3;
    if (stop > 1) return -1;
    const span = wire.Span{ .address = if (data) |p| @intFromPtr(p) else 0, .length = length };
    const input = span.bytes() catch return -3;
    target.* = state.writeStep(input, limit, stop != 0, clock orelse return -3, clock_context, writer orelse return -3, context) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkTransferReadClock(ctx: ?*anyopaque, out: *budget.ClockSample) callconv(.c) i32 {
    return adapters.PlatformClock.sample(ctx, out);
}
pub export fn R4SdkTransferReadFile(ctx: ?*anyopaque, offset: u64, data: [*]u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.FileRead.step(ctx, offset, data, length, deadline);
}
pub export fn R4SdkTransferAppendFile(ctx: ?*anyopaque, offset: u64, data: [*]const u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.FileAppend.step(ctx, offset, data, length, deadline);
}
pub export fn R4SdkTransferFileStreamWrite(ctx: ?*anyopaque, offset: u64, data: [*]const u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.FileStream.step(ctx, offset, data, length, deadline);
}
pub export fn R4SdkTransferTcpRead(ctx: ?*anyopaque, offset: u64, data: [*]u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.Tcp.read(ctx, offset, data, length, deadline);
}
pub export fn R4SdkTransferTcpWrite(ctx: ?*anyopaque, offset: u64, data: [*]const u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.Tcp.write(ctx, offset, data, length, deadline);
}
pub export fn R4SdkTransferServiceWrite(ctx: ?*anyopaque, offset: u64, data: [*]const u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.ServiceSink.write(ctx, offset, data, length, deadline);
}
pub export fn R4SdkTransferServiceRead(ctx: ?*anyopaque, offset: u64, data: [*]u8, length: u32, deadline: *const budget.DeadlineBudget) callconv(.c) core.Ack {
    return adapters.ServiceReply.read(ctx, offset, data, length, deadline);
}
