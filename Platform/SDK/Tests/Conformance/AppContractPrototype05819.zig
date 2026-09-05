const std = @import("std");
const r4os = @import("r4os");

const contract = r4os.app_contract;

pub fn consolePrototype(context: *const r4os.abi.R4XStartContext) r4os.Outcome(r4os.App) {
    return r4os.App.init(context, .console);
}

pub fn desktopPrototype(context: *const r4os.abi.R4XStartContext) r4os.Outcome(r4os.App) {
    return r4os.App.init(context, .desktop);
}

pub fn servicePrototype(context: *const r4os.abi.R4XStartContext) r4os.Outcome(r4os.App) {
    return r4os.App.init(context, .service);
}

test "console desktop and service prototypes compile" {
    _ = consolePrototype;
    _ = desktopPrototype;
    _ = servicePrototype;
}

test "missing group and function preserve their raw contract codes" {
    var invalid_context: r4os.abi.R4XStartContext = std.mem.zeroes(r4os.abi.R4XStartContext);
    const missing_group = r4os.App.init(&invalid_context, .console);
    switch (missing_group) {
        .value => return error.ExpectedMissingGroup,
        .failure => |failure| {
            try std.testing.expectEqual(contract.ErrorDomain.contract, failure.domain);
            try std.testing.expectEqual(r4os.abi.err_no_group, failure.raw_code);
        },
    }

    const missing_fn = r4os.Failure.fromRaw(.contract, r4os.abi.err_no_fn);
    try std.testing.expectEqual(r4os.abi.err_no_fn, missing_fn.raw_code);
}

test "domain failures preserve every raw code and optional progress" {
    try std.testing.expectEqual(@as(u16, 0), @intFromEnum(contract.ErrorDomain.none));
    try std.testing.expectEqual(@as(u16, 14), @intFromEnum(contract.ErrorDomain.audio));
    try std.testing.expectEqual(@as(u16, 15), @intFromEnum(contract.ErrorDomain.device));
    const cases = [_]struct { domain: contract.ErrorDomain, raw: i32 }{
        .{ .domain = .filesystem, .raw = -101 },
        .{ .domain = .thread, .raw = -202 },
        .{ .domain = .service, .raw = -303 },
        .{ .domain = .network, .raw = -404 },
        .{ .domain = .audio, .raw = -505 },
    };
    for (cases) |item| {
        var failure = r4os.Failure.fromRaw(item.domain, item.raw);
        failure.progress = 17;
        failure.required_size = 4096;
        failure.side_effects = .confirmed_progress;
        try std.testing.expectEqual(item.domain, failure.domain);
        try std.testing.expectEqual(item.raw, failure.raw_code);
        try std.testing.expectEqual(@as(?u64, 17), failure.progress);
        try std.testing.expectEqual(@as(?u64, 4096), failure.required_size);
        try std.testing.expectEqual(contract.SideEffectState.confirmed_progress, failure.side_effects);
    }
}

test "owned handles invalidate after close while borrowed handles remain views" {
    var owned = contract.ThreadHandle.ownedValue(42);
    try std.testing.expect(owned.valid());
    try std.testing.expectEqual(@as(i32, -202), owned.applyCloseResult(-202));
    try std.testing.expect(owned.valid());
    try std.testing.expectEqual(@as(i32, 0), owned.applyCloseResult(0));
    try std.testing.expect(!owned.valid());

    var borrowed = contract.ThreadHandle.borrowedValue(42);
    _ = borrowed.applyCloseResult(0);
    try std.testing.expect(borrowed.valid());

    var window = contract.WindowHandle.ownedValue(7);
    _ = window.applyCloseResult(0);
    try std.testing.expectEqual(@as(i32, -1), window.raw);
    try std.testing.expect(!window.valid());
}

test "path based file operations do not invent a file handle" {
    try std.testing.expect(!@hasDecl(contract, "FileHandle"));
}
