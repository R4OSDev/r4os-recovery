//! Explicit complete full diagnostics or lightweight lifecycle membership.
pub const core = @import("inventory_reader.zig");
pub const Reader = core.Reader;
pub const LifecyclePages = core.LifecyclePages;
pub const Provider = core.Provider;
pub const Mode = core.Mode;
pub const Status = core.Status;
pub const Disposition = core.Disposition;
pub const Progress = core.Progress;
pub const Match = core.Match;
pub const Clock = core.Clock;
pub const Error = core.Error;
pub const PlatformClock = @import("stream_adapters.zig").PlatformClock;

/// Resolve only the selected real owner pair; no provider call or fallback
/// to expensive diagnostics when lightweight lifecycle membership is wanted.
pub fn fromContext2(ctx: *const @import("platform2.zig").Context, mode: Mode) error{NoProvider}!Provider {
    const a = @import("r4os_contract2");
    var begin: u64 = 0;
    var page: u64 = 0;
    switch (mode) {
        .full => {
            if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "program_inventory_begin"), &begin) != 0 or ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "program_inventory_programs"), &page) != 0) return error.NoProvider;
            return .{ .full_begin = @ptrFromInt(begin), .full_page = @ptrFromInt(page) };
        },
        .lifecycle => {
            if (ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "program_lifecycle_begin"), &begin) != 0 or ctx.lookup(1, @offsetOf(a.R4XStartR4Sys2, "program_lifecycle_programs"), &page) != 0) return error.NoProvider;
            return .{ .lifecycle_begin = @ptrFromInt(begin), .lifecycle_page = @ptrFromInt(page) };
        },
    }
}
