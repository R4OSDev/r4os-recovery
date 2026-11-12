//! Actual generation2 context used by normal App2 and explicit technical
//! probes. No process-global context binding or implicit generation fallback.
const std = @import("std");
pub const abi = @import("r4os_contract2");
pub const Error = error{ InvalidContext, InvalidImports, MixedGeneration, DuplicateGroup, MissingSystem, InvalidTable };

/// SDK C-facing view. Context's native Zig layout is never exposed through
/// FFI; this explicit projection borrows the same resident start/import data.
pub const CView = extern struct {
    raw: *const abi.R4XStartContext2,
    tables: [6]u64,
};

pub const Context = struct {
    raw: *const abi.R4XStartContext2,
    tables: [6]u64 = @splat(0),

    pub fn cView(self: *const Context) CView {
        return .{ .raw = self.raw, .tables = self.tables };
    }

    pub fn init(raw: *const abi.R4XStartContext2) Error!Context {
        if (raw.magic != abi.start_magic or raw.abi_major != 2 or raw.size < @sizeOf(abi.R4XStartContext2)) return error.InvalidContext;
        if (raw.args_len > std.math.maxInt(isize) or (raw.args_len != 0 and raw.args == 0) or @addWithOverflow(raw.args, raw.args_len)[1] != 0) return error.InvalidContext;
        if (raw.import_count > 32 or (raw.import_count != 0 and (raw.imports == 0 or raw.imports % @alignOf(abi.R4XStartImport) != 0))) return error.InvalidImports;
        if (@addWithOverflow(raw.imports, @as(u64, raw.import_count) * @sizeOf(abi.R4XStartImport))[1] != 0) return error.InvalidImports;
        var result: Context = .{ .raw = raw };
        var seen: u8 = 0;
        if (raw.import_count != 0) {
            const imports: [*]const abi.R4XStartImport = @ptrFromInt(raw.imports);
            for (imports[0..raw.import_count]) |item| {
                if (item.group_id == 0) continue; // independent R4L interfaces
                if (item.group_id > 6) return error.InvalidImports;
                // Query2 export revision is separate from the table revision.
                if (item.resolved_version != abi.query_version) return error.MixedGeneration;
                const index: usize = @intCast(item.group_id - 1);
                const bit: u8 = @as(u8, 1) << @as(u3, @intCast(index));
                if (seen & bit != 0) return error.DuplicateGroup;
                seen |= bit;
                result.tables[index] = item.table;
            }
        }
        if (result.tables[0] == 0) return error.MissingSystem;
        if (result.system() == null) return error.InvalidTable;
        return result;
    }

    pub fn group(self: *const Context, comptime Table: type, id: u32) ?*const Table {
        if (id == 0 or id > 6) return null;
        const raw = self.tables[id - 1];
        if (raw == 0 or raw % @alignOf(Table) != 0) return null;
        const t: *const Table = @ptrFromInt(raw);
        const expected: Table = .{};
        if (t.magic != expected.magic or t.abi_version < 1 or t.size < 16) return null;
        return t;
    }
    pub fn system(self: *const Context) ?*const abi.R4XStartR4Sys2 {
        return self.group(abi.R4XStartR4Sys2, 1);
    }
    pub fn desktop(self: *const Context) ?*const abi.R4XStartR4Desk2 {
        return self.group(abi.R4XStartR4Desk2, 2);
    }
    pub fn drawing(self: *const Context) ?*const abi.R4XStartR4Draw2 {
        return self.group(abi.R4XStartR4Draw2, 3);
    }
    pub fn network(self: *const Context) ?*const abi.R4XStartR4Net2 {
        return self.group(abi.R4XStartR4Net2, 4);
    }
    pub fn audio(self: *const Context) ?*const abi.R4XStartR4Audio2 {
        return self.group(abi.R4XStartR4Audio2, 5);
    }
    pub fn devices(self: *const Context) ?*const abi.R4XStartR4Dev2 {
        return self.group(abi.R4XStartR4Dev2, 6);
    }

    pub fn args(self: *const Context) []const u8 {
        if (self.raw.args_len == 0) return &.{};
        const data: [*]const u8 = @ptrFromInt(self.raw.args);
        return data[0..@intCast(self.raw.args_len)];
    }
    pub fn findImportNamed(self: *const Context, module: []const u8, symbol: []const u8) ?*const abi.R4XStartImport {
        if (self.raw.import_count == 0) return null;
        const items: [*]const abi.R4XStartImport = @ptrFromInt(self.raw.imports);
        const equal = @import("runtime_r4l.zig").importNameEquals;
        for (items[0..self.raw.import_count]) |*item| {
            if (equal(item.module_name, module) and equal(item.symbol_name, symbol)) return item;
        }
        return null;
    }
    pub fn shouldClose(self: *const Context) bool {
        if (self.raw.flags & abi.shared.r4xstart_flag_close_supported == 0 or self.raw.should_close == 0) return true;
        const callback: abi.R4XStartShouldCloseFn2 = @ptrFromInt(self.raw.should_close);
        return callback(self.raw) != 0;
    }
    pub fn yieldCurrent(self: *const Context) bool {
        if (self.raw.flags & abi.shared.r4xstart_flag_yield_supported == 0 or self.raw.yield == 0) return false;
        const callback: abi.R4XStartYieldFn2 = @ptrFromInt(self.raw.yield);
        callback(self.raw);
        return true;
    }

    /// Resolves an explicitly typed caller's slot; errors preserve output.
    /// The contract owns its byte offset and C callback signature.
    pub fn lookup(self: *const Context, id: u32, offset: u32, output: *u64) i32 {
        inline for (.{ abi.R4XStartR4Sys2, abi.R4XStartR4Desk2, abi.R4XStartR4Draw2, abi.R4XStartR4Net2, abi.R4XStartR4Audio2, abi.R4XStartR4Dev2 }, 1..) |T, group_id| {
            if (id == group_id) {
                const table = self.group(T, id) orelse return abi.shared.err_no_group;
                if (offset < 16 or offset % 8 != 0 or @as(u64, offset) + 8 > table.size) return abi.shared.err_no_fn;
                const address = std.math.add(usize, @intFromPtr(table), offset) catch return abi.shared.err_no_fn;
                const slot: *const u64 = @ptrFromInt(address);
                if (slot.* == 0) return abi.shared.err_no_fn;
                output.* = slot.*;
                return 0;
            }
        }
        return abi.shared.err_no_group;
    }
};

test "platform2 lookup distinguishes missing groups and functions without changing failed outputs" {
    const sinks = @import("diagnostic_sinks.zig");
    const Provider = struct {
        fn write(_: [*]const u8, _: u32) callconv(.c) i32 {
            return -20002;
        }
    };
    var sys: abi.R4XStartR4Sys2 = .{};
    var rows = [_]abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) }};
    const raw: abi.R4XStartContext2 = .{ .imports = @intFromPtr(&rows), .import_count = 1 };
    const context = try Context.init(&raw);
    // The C ABI projection has an explicit layout. Native Context is free to
    // use Zig's own field order; exporting a pointer to it would be invalid.
    try std.testing.expectEqual(@as(usize, 56), @sizeOf(CView));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(CView, "raw"));
    try std.testing.expectEqual(@as(usize, 8), @offsetOf(CView, "tables"));
    const c_view = context.cView();
    try std.testing.expect(c_view.raw == &raw);
    try std.testing.expectEqual(@intFromPtr(&sys), c_view.tables[0]);
    try std.testing.expect(std.mem.allEqual(u64, c_view.tables[1..], 0));
    try std.testing.expectError(error.NoProvider, sinks.ConsoleSink.fromContext2(&context, 1));
    try std.testing.expectError(error.NoProvider, sinks.FileSink.fromContext2(&context, "C:\\X"));
    try std.testing.expectError(error.NoProvider, sinks.LogSink.fromContext2(&context, "T", .{}));
    var output: u64 = 12345;
    try std.testing.expectEqual(abi.shared.err_no_group, context.lookup(7, 16, &output));
    try std.testing.expectEqual(abi.shared.err_no_fn, context.lookup(1, 16, &output));
    try std.testing.expectEqual(@as(u64, 12345), output);
    sys.write = @intFromPtr(&Provider.write);
    try std.testing.expectEqual(@as(i32, 0), context.lookup(1, 16, &output));
    try std.testing.expectEqual(@intFromPtr(&Provider.write), output);
    output = 12345;
    sys.size = 16;
    try std.testing.expectEqual(abi.shared.err_no_fn, context.lookup(1, 16, &output));
    try std.testing.expectEqual(abi.shared.err_no_fn, context.lookup(1, 0xfffffff8, &output));
    try std.testing.expectEqual(@as(u64, 12345), output);
}

test "platform2 admits only the explicitly selected generation and retains canonical tables" {
    var sys: abi.R4XStartR4Sys2 = .{};
    var rows = [_]abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) }};
    var raw: abi.R4XStartContext2 = .{ .imports = @intFromPtr(&rows), .import_count = 1 };
    const value = try Context.init(&raw);
    try std.testing.expect(value.system().? == &sys);
    rows[0].resolved_version = 1;
    try std.testing.expectError(error.MixedGeneration, Context.init(&raw));
    rows[0].resolved_version = 2;
    sys.magic = (abi.shared.R4XStartR4Sys{}).magic;
    try std.testing.expectError(error.InvalidTable, Context.init(&raw));
    sys = .{};
    raw.abi_major = 1;
    try std.testing.expectError(error.InvalidContext, Context.init(&raw));
    raw.abi_major = 2;
    raw.size = 119;
    try std.testing.expectError(error.InvalidContext, Context.init(&raw));
    raw.size = 120;
    raw.import_count = 33;
    try std.testing.expectError(error.InvalidImports, Context.init(&raw));
    raw.import_count = 1;
    raw.imports += 1;
    try std.testing.expectError(error.InvalidImports, Context.init(&raw));
    raw.imports -= 1;
    rows[0].group_id = 7;
    try std.testing.expectError(error.InvalidImports, Context.init(&raw));
    rows[0].group_id = 2;
    try std.testing.expectError(error.MissingSystem, Context.init(&raw));
    rows[0].group_id = 1;
    sys.size = 15;
    try std.testing.expectError(error.InvalidTable, Context.init(&raw));
    sys.size = 16;
    try std.testing.expect((try Context.init(&raw)).system() != null);
    sys.abi_version = 0;
    try std.testing.expectError(error.InvalidTable, Context.init(&raw));
    sys = .{};
    var duplicate = [_]abi.R4XStartImport{ rows[0], rows[0] };
    duplicate[0].table = 0;
    raw.imports = @intFromPtr(&duplicate);
    raw.import_count = 2;
    try std.testing.expectError(error.DuplicateGroup, Context.init(&raw));
}

/// Build-owned admission facts, never retained after the main entry returns.
pub const StartupInfo = struct { app_class: u32, required_groups: u32, import_count: u32 };
pub fn start(raw: *const abi.R4XStartContext2, expected: StartupInfo, main: *const fn (*const Context) callconv(.c) i32) i32 {
    const context = Context.init(raw) catch return -1;
    if (raw.app_class != expected.app_class or raw.import_count != expected.import_count) return -1;
    for (context.tables, 0..) |table, i| {
        if (expected.required_groups & (@as(u32, 1) << @intCast(i + 1)) != 0 and (table == 0 or !validGroup(&context, @intCast(i + 1)))) return -1;
    }
    return main(&context);
}
fn validGroup(context: *const Context, id: u32) bool {
    inline for (.{ abi.R4XStartR4Sys2, abi.R4XStartR4Desk2, abi.R4XStartR4Draw2, abi.R4XStartR4Net2, abi.R4XStartR4Audio2, abi.R4XStartR4Dev2 }, 1..) |T, group_id| {
        if (id == group_id) return context.group(T, id) != null;
    }
    return false;
}

test "Start2 admits class groups and import count before invoking the callback" {
    const Callback = struct {
        fn run(context: *const Context) callconv(.c) i32 {
            const callback = abi.function(abi.R4SysFns2, context.system(), "write") orelse return -9;
            return callback("API2", 4);
        }
        fn write(bytes: [*]const u8, len: u32) callconv(.c) i32 {
            return if (len == 4 and std.mem.eql(u8, bytes[0..len], "API2")) -20002 else -2;
        }
    };
    var sys: abi.R4XStartR4Sys2 = .{ .write = @intFromPtr(&Callback.write) };
    var imports = [_]abi.R4XStartImport{.{ .group_id = 1, .min_version = 2, .resolved_version = 2, .flags = abi.shared.r4xstart_import_flag_group_interface, .table = @intFromPtr(&sys) }};
    var raw: abi.R4XStartContext2 = .{ .app_class = 1, .imports = @intFromPtr(&imports), .import_count = 1 };
    const expected: StartupInfo = .{ .app_class = 1, .required_groups = 2, .import_count = 1 };
    try std.testing.expectEqual(@as(i32, -20002), start(&raw, expected, &Callback.run));
    raw.app_class = 3;
    try std.testing.expectEqual(@as(i32, -1), start(&raw, expected, &Callback.run));
    raw.app_class = 1;
    try std.testing.expectEqual(@as(i32, -1), start(&raw, .{ .app_class = 1, .required_groups = 2, .import_count = 2 }, &Callback.run));
    try std.testing.expectEqual(@as(i32, -1), start(&raw, .{ .app_class = 1, .required_groups = 10, .import_count = 1 }, &Callback.run));
    raw.size = 119;
    try std.testing.expectEqual(@as(i32, -1), start(&raw, expected, &Callback.run));
}

test "normal App2 validates ordered manifest libraries and keeps exact lifecycle callbacks" {
    const startup = @import("app2.zig");
    const Callback = struct {
        var expected: *const abi.R4XStartContext2 = undefined;
        var yields: u32 = 0;
        fn close(raw: *const abi.R4XStartContext2) callconv(.c) u32 {
            return @intFromBool(raw == expected and raw.size == 120 and raw.magic == abi.start_magic);
        }
        fn yield(raw: *const abi.R4XStartContext2) callconv(.c) void {
            if (raw == expected and raw.size == 120) yields += 1;
        }
        fn write(data: [*]const u8, len: u32) callconv(.c) i32 {
            return if (std.mem.eql(u8, data[0..len], "normal2")) 7 else -99;
        }
    };
    var sys: abi.R4XStartR4Sys2 = .{ .write = @intFromPtr(&Callback.write) };
    var rows = [_]abi.R4XStartImport{
        .{ .group_id = 1, .min_version = 2, .resolved_version = 2, .flags = 1, .module_name = @intFromPtr("R4SYS"), .symbol_name = @intFromPtr("Query2"), .table = @intFromPtr(&sys) },
        .{ .min_version = 1, .module_name = @intFromPtr("OPTIONAL"), .symbol_name = @intFromPtr("TEXT_V1") },
    };
    var raw: abi.R4XStartContext2 = .{
        .app_class = 1,
        .flags = abi.shared.r4xstart_flag_imports_valid | abi.shared.r4xstart_flag_close_supported | abi.shared.r4xstart_flag_yield_supported,
        .imports = @intFromPtr(&rows),
        .import_count = rows.len,
        .args = @intFromPtr("argument"),
        .args_len = 8,
        .should_close = @intFromPtr(&Callback.close),
        .yield = @intFromPtr(&Callback.yield),
    };
    Callback.expected = &raw;
    Callback.yields = 0;
    const specs = [_]startup.ImportSpec{
        .{ .module_name = "R4SYS", .symbol_name = "Query2", .minimum = 2, .optional = 0, .group_id = 1 },
        .{ .module_name = "OPTIONAL", .symbol_name = "TEXT_V1", .minimum = 1, .optional = 1, .group_id = 0 },
    };
    const facts: startup.StartupInfo = .{ .profile = 0, .app_class = 1, .required_groups = 2, .import_count = 2, .imports = &specs };
    var app = switch (startup.App.initDeclared(&raw, &facts)) {
        .value => |a| a,
        .failure => return error.UnexpectedStartFailure,
    };
    try std.testing.expect(app.startContext() == &raw);
    try std.testing.expect(app.lowLevel().bundle == null);
    try std.testing.expect(app.context.system().? == &sys);
    try std.testing.expectEqualStrings("argument", app.args());
    app.lowLevel().write("normal2");
    try std.testing.expect(app.shouldClose());
    app.yield();
    try std.testing.expectEqual(@as(u32, 1), Callback.yields);
    try std.testing.expect(app.allocator() == null);
    raw.app_class = @intFromEnum(abi.shared.R4XStartAppClass.gui);
    try std.testing.expect(startup.App.initDeclared(&raw, &facts) == .value);
    var wrong_facts = facts;
    wrong_facts.app_class = raw.app_class;
    try std.testing.expect(startup.App.initDeclared(&raw, &wrong_facts) == .failure);
    raw.app_class = @intFromEnum(abi.shared.R4XStartAppClass.console);
    rows[1].module_name = @intFromPtr("OTHER");
    try std.testing.expect(startup.App.initDeclared(&raw, &facts) == .failure);
    rows[1].module_name = @intFromPtr("OPTIONAL");
    rows[1].resolved_version = 1;
    try std.testing.expect(startup.App.initDeclared(&raw, &facts) == .failure);
    rows[1].resolved_version = 0;
    std.mem.swap(abi.R4XStartImport, &rows[0], &rows[1]);
    try std.testing.expect(startup.App.initDeclared(&raw, &facts) == .failure);
    std.mem.swap(abi.R4XStartImport, &rows[0], &rows[1]);
    raw.import_count = 1;
    try std.testing.expect(startup.App.initDeclared(&raw, &facts) == .failure);
}

test "normal App2 requires actual class groups and rejects old contexts and group headers" {
    const startup = @import("app2.zig");
    var sys: abi.R4XStartR4Sys2 = .{};
    var desk: abi.R4XStartR4Desk2 = .{};
    var draw: abi.R4XStartR4Draw2 = .{};
    var rows = [_]abi.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) },
        .{ .group_id = 2, .resolved_version = 2, .table = @intFromPtr(&desk) },
        .{ .group_id = 3, .resolved_version = 2, .table = @intFromPtr(&draw) },
    };
    var raw: abi.R4XStartContext2 = .{ .flags = 1, .app_class = 2, .imports = @intFromPtr(&rows), .import_count = 1 };
    try std.testing.expect(startup.App.init(&raw, .desktop) == .failure);
    raw.import_count = 3;
    try std.testing.expect(startup.App.init(&raw, .desktop) == .value);
    raw.app_class = 3;
    try std.testing.expect(startup.App.init(&raw, .service) == .value);
    try std.testing.expect(startup.App.init(&raw, .console) == .failure);
    try std.testing.expect(startup.App.init(&raw, .desktop) == .failure);
    raw.app_class = 1;
    try std.testing.expect(startup.App.init(&raw, .desktop) == .value);
    try std.testing.expect(startup.App.init(&raw, .service) == .failure);
    raw.import_count = 2;
    try std.testing.expect(startup.App.init(&raw, .desktop) == .failure);
    raw.import_count = 3;
    raw.app_class = 0;
    try std.testing.expect(startup.App.init(&raw, .console) == .failure);
    raw.app_class = 1;
    raw.flags = 0;
    try std.testing.expect(startup.App.init(&raw, .console) == .failure);
    raw.flags = 1;
    raw.abi_major = 1;
    try std.testing.expect(startup.App.init(&raw, .console) == .failure);
    raw.abi_major = 2;
    raw.size = 119;
    try std.testing.expect(startup.App.init(&raw, .console) == .failure);
    raw.size = 120;
    sys.magic = abi.shared.r4xstart_r4sys_magic;
    try std.testing.expect(startup.App.init(&raw, .console) == .failure);
}
