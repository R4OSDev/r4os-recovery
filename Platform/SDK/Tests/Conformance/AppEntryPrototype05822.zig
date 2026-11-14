const std = @import("std");
const r4os = @import("r4os");

fn importFor(group: r4os.abi.R4LGroup, table: usize) r4os.abi.R4XStartImport {
    return .{ .group_id = @intFromEnum(group), .resolved_version = 2, .min_version = 2, .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = table };
}

fn context(imports: []const r4os.abi.R4XStartImport, args: []const u8) r4os.platform2.abi.R4XStartContext2 {
    return .{
        .app_class = 1,
        .flags = r4os.abi.r4xstart_flag_imports_valid,
        .args = if (args.len == 0) 0 else @intFromPtr(args.ptr),
        .args_len = args.len,
        .imports = @intFromPtr(imports.ptr),
        .import_count = @intCast(imports.len),
    };
}

test "profiles enforce required groups and expose missing optional groups" {
    var sys: r4os.platform2.abi.R4XStartR4Sys2 = .{};
    var desk: r4os.platform2.abi.R4XStartR4Desk2 = .{};
    var draw: r4os.platform2.abi.R4XStartR4Draw2 = .{};
    const console_imports = [_]r4os.abi.R4XStartImport{importFor(.r4sys, @intFromPtr(&sys))};
    const desktop_imports = [_]r4os.abi.R4XStartImport{
        importFor(.r4sys, @intFromPtr(&sys)),
        importFor(.r4desk, @intFromPtr(&desk)),
        importFor(.r4draw, @intFromPtr(&draw)),
    };
    var console_context = context(&console_imports, "console");
    var desktop_context = context(&desktop_imports, "desktop");
    desktop_context.app_class = 2;
    var console = switch (r4os.App.init(&console_context, .console)) {
        .value => |app| app,
        .failure => return error.UnexpectedFailure,
    };
    try std.testing.expect(console.hasGroup(.r4sys));
    try std.testing.expect(!console.hasGroup(.r4desk));
    try std.testing.expectEqualStrings("console", console.args());
    try std.testing.expect(console.allocator() == null);
    switch (r4os.App.init(&console_context, .desktop)) {
        .failure => |failure| try std.testing.expectEqual(@as(i32, -15), failure.raw_code),
        .value => return error.ExpectedFailure,
    }
    var desktop_app = switch (r4os.App.init(&desktop_context, .desktop)) {
        .value => |app| app,
        .failure => return error.UnexpectedFailure,
    };
    try std.testing.expect(desktop_app.desktop() != null and desktop_app.drawing() != null);
    try std.testing.expectEqual(r4os.abi.R4XStartAppClass.gui, desktop_app.profileMeta().app_class);
}

test "two App objects own independent bundle values" {
    var first_table: r4os.platform2.abi.R4XStartR4Sys2 = .{};
    var second_table: r4os.platform2.abi.R4XStartR4Sys2 = .{};
    const first_imports = [_]r4os.abi.R4XStartImport{importFor(.r4sys, @intFromPtr(&first_table))};
    const second_imports = [_]r4os.abi.R4XStartImport{importFor(.r4sys, @intFromPtr(&second_table))};
    var first_context = context(&first_imports, "one");
    var second_context = context(&second_imports, "two");
    first_context.app_class = 3;
    second_context.app_class = 3;
    var first = switch (r4os.App.init(&first_context, .service)) {
        .value => |app| app,
        .failure => return error.UnexpectedFailure,
    };
    var second = switch (r4os.App.init(&second_context, .service)) {
        .value => |app| app,
        .failure => return error.UnexpectedFailure,
    };
    try std.testing.expect(first.context.system().? != second.context.system().?);
    try std.testing.expectEqualStrings("one", first.args());
    try std.testing.expectEqualStrings("two", second.args());
    try std.testing.expect(@hasDecl(r4os, "lowlevel"));
}
