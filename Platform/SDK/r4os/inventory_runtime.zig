//! Shared C/Rust staged inventory owner. No partial successful view escapes.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const owner = @import("inventory_reader.zig");
const budget = @import("time_budget.zig");
const wire = @import("binary_cursor.zig");
comptime {
    if (@sizeOf(owner.Provider) != 32 or @sizeOf(owner.Progress) != 32 or @sizeOf(owner.Match) != 24 or @sizeOf(owner.Reader) != 392 or @offsetOf(owner.Reader, "provider") != 280 or @offsetOf(owner.Reader, "mode") != 336 or @offsetOf(owner.Reader, "restarts") != 384) @compileError("Inventory C/Rust bridge layout drift");
}
fn code(err: owner.Error) i32 {
    return switch (err) {
        error.InvalidState => -1,
        error.InvalidStorage => -2,
        error.InvalidLimit => -3,
        error.InvalidMode => -4,
        error.Busy => -5,
        error.Incomplete => -6,
        error.WrongMode => -7,
        error.ClockUnavailable => -101,
        error.ClockChanged => -102,
        error.ClockRegressed => -103,
        error.InvalidBudget => -104,
        error.UnknownFrequency => -105,
        error.BudgetOverflow => -106,
        error.InvalidTimeout => -107,
    };
}
pub export fn R4SdkInventoryInit(mode: u32, storage: wire.Span, capacity: u32, page_limit: u32, provider: owner.Provider, sample: budget.ClockSample, timeout: abi.R4Timeout, out: ?*owner.Reader) callconv(.c) i32 {
    const target = out orelse return -1;
    const chosen = std.enums.fromInt(owner.Mode, mode) orelse return -4;
    target.* = owner.Reader.init(chosen, storage, capacity, page_limit, provider, sample, timeout) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryInitAbsolute(mode: u32, storage: wire.Span, capacity: u32, page_limit: u32, provider: owner.Provider, deadline: budget.DeadlineBudget, out: ?*owner.Reader) callconv(.c) i32 {
    const target = out orelse return -1;
    const chosen = std.enums.fromInt(owner.Mode, mode) orelse return -4;
    target.* = owner.Reader.initAbsolute(chosen, storage, capacity, page_limit, provider, deadline) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryGetProgress(raw: ?*const owner.Reader, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.progress() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryCancel(raw: ?*owner.Reader, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.cancel() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryRestart(raw: ?*owner.Reader, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.restart() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryStep(raw: ?*owner.Reader, stop: u32, clock: ?owner.Clock, context: ?*anyopaque, out: ?*owner.Progress) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    if (stop > 1) return -1;
    target.* = state.step(stop != 0, clock orelse return -2, context) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryGetView(raw: ?*const owner.Reader, out: ?*wire.Span) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.view() catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryFindExact(raw: ?*const owner.Reader, handle: abi.ProgramProcessHandle, out: ?*owner.Match) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    target.* = state.findExact(handle) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkInventoryGetSummary(raw: ?*const owner.Reader, out: ?*abi.ProgramInventorySummary) callconv(.c) i32 {
    const state = raw orelse return -1;
    const target = out orelse return -2;
    _ = state.view() catch |err| return code(err);
    if (state.mode != 0) return -7;
    target.* = state.summary;
    return 0;
}
