const std = @import("std");
const r4os = @import("r4os");
const p = r4os.platform2;
const a = p.abi;
pub fn r4_app_main(app: *r4os.App2) i32 {
    if (std.mem.eql(u8, app.args(), "initfail")) return -73;
    const allocator = app.allocator() orelse return -60;
    const bytes = allocator.alloc(u8, 4096) catch return -61;
    defer allocator.free(bytes);
    @memset(bytes, 0xa5);
    var entropy: [32]u8 = @splat(0xa5);
    const filled = r4os.secure_random.fill(&entropy);
    if (!filled and !std.mem.allEqual(u8, &entropy, 0)) return -62;
    var source: a.shared.EntropySourceInfo = .{};
    if (app.lowLevel().entropySourceInfo(&source) == 0 and source.state == a.shared.entropy_state_ready) {
        var bound: a.shared.EntropySourceInfo = .{};
        if (!filled or r4os.secure_random.sourceInfo(&bound) != 0 or bound.generation != source.generation) return -65;
    }
    const imports: [*]const a.R4XStartImport = @ptrFromInt(app.raw.imports);
    if (app.raw.import_count < 4 or imports[2].resolved_version != 1 or imports[2].group_id != 0 or imports[2].table == 0 or
        imports[3].resolved_version != 0 or imports[3].table != 0 or imports[3].flags != 0) return -63;
    return run(&app.context);
}
fn print(view: *const p.Context, text: []const u8) void {
    const write = a.function(a.R4SysFns2, view.system(), "write") orelse return;
    _ = write(text.ptr, @intCast(text.len));
}
fn status(view: *const p.Context, comptime format: []const u8, values: anytype) void {
    var buffer: [192]u8 = undefined;
    print(view, std.fmt.bufPrint(&buffer, format, values) catch return);
}
fn run(view: *const p.Context) callconv(.c) i32 {
    const held = std.mem.eql(u8, view.args(), "hold");
    if (view.raw.instance_id == 0 or (!held and view.shouldClose())) return -20;
    const imports: [*]const a.R4XStartImport = @ptrFromInt(view.raw.imports);
    if (imports[1].group_id != 0 or imports[1].resolved_version != 2 or imports[1].table == 0) return -21;
    const query: *const a.R4LQuery2 = @ptrFromInt(imports[1].table);
    if (query.magic != 0x324c3452 or query.size != 24 or query.group != 0 or query.reserved != 0) return -22;
    if (!view.yieldCurrent() or (!held and view.shouldClose()) or query.magic != 0x324c3452) return -23;
    if (std.mem.eql(u8, view.args(), "lifecycle")) return lifecycle(view);
    if (std.mem.eql(u8, view.args(), "negative")) return negative(view);
    print(view, "PASS APP2Z context=120 query=24 borrowed_args/imports callbacks=2\r\n");
    if (std.mem.eql(u8, view.args(), "fault")) @panic("normal App2 Zig fault probe");
    if (std.mem.eql(u8, view.args(), "hold")) while (!view.shouldClose()) {
        _ = view.yieldCurrent();
    };
    return if (std.mem.eql(u8, view.args(), "return")) 37 else 0;
}
fn lifecycle(view: *const p.Context) i32 {
    const sys = view.system();
    const spawn = a.function(a.R4SysFns2, sys, "program_spawn_handle") orelse return -30;
    const close = a.function(a.R4SysFns2, sys, "program_handle_request_close") orelse return -30;
    const kill = a.function(a.R4SysFns2, sys, "program_handle_kill") orelse return -30;
    const wait = a.function(a.R4SysFns2, sys, "program_handle_wait") orelse return -30;
    const reap = a.function(a.R4SysFns2, sys, "program_handle_reap") orelse return -30;
    const sleep = a.function(a.R4SysFns2, sys, "sleep_ticks") orelse return -30;
    for ([_][*:0]const u8{ "C:\\R4OS\\TESTS\\APP2Z.R4X", "C:\\R4OS\\TESTS\\APP2C.R4X", "C:\\R4OS\\TESTS\\APP2R.R4X", "C:\\R4OS\\TESTS\\APP2ZG.R4X", "C:\\R4OS\\TESTS\\APP2CG.R4X", "C:\\R4OS\\TESTS\\APP2RG.R4X", "C:\\R4OS\\TESTS\\APP2ZS.R4X", "C:\\R4OS\\TESTS\\APP2CS.R4X", "C:\\R4OS\\TESTS\\APP2RS.R4X", "C:\\R4OS\\SUBSYSTEMS\\r4os.test.app2z\\APP2ZU.R4X", "C:\\R4OS\\SUBSYSTEMS\\r4os.test.app2c\\APP2CU.R4X", "C:\\R4OS\\SUBSYSTEMS\\r4os.test.app2r\\APP2RU.R4X" }) |path| {
        print(view, "APP2 child ");
        print(view, std.mem.span(path));
        print(view, "\r\n");
        for (0..5) |mode| {
            const args: [*:0]const u8 = switch (mode) {
                0 => "return",
                1, 2 => "hold",
                3 => "fault",
                else => "initfail",
            };
            var handle: a.shared.ProgramProcessHandle = .{};
            const spawn_rc = spawn(path, args, @intFromEnum(a.shared.LaunchPolicy.auto), &handle);
            status(view, "mode={d} spawn={d} handle={d}/{d}\r\n", .{ mode, spawn_rc, handle.instance_id, handle.generation });
            if (spawn_rc != 0 or handle.instance_id == 0 or handle.generation == 0) return -31;
            if (std.mem.endsWith(u8, std.mem.span(path), "G.R4X") or std.mem.endsWith(u8, std.mem.span(path), "U.R4X")) {
                const associate = a.function(a.R4DeskFns2, view.desktop(), "program_set_window_handle") orelse return -35;
                if (associate(&handle, 0) != 0) return -35;
            }
            if (mode == 1 or mode == 2) {
                _ = sleep(3);
                const changed = if (mode == 1) close(&handle) else kill(&handle);
                if (changed != 0) {
                    _ = kill(&handle);
                    var failed: a.shared.ProgramProcessCompletion = .{};
                    _ = wait(&handle, 1000, &failed);
                    _ = reap(&handle, &failed);
                    return -32;
                }
            }
            var completion: a.shared.ProgramProcessCompletion = .{};
            const wait_rc = wait(&handle, 1000, &completion);
            status(view, "wait={d} code={d} reason={d} handle={d}/{d}\r\n", .{ wait_rc, completion.exit_code, completion.exit_reason, completion.handle.instance_id, completion.handle.generation });
            if (wait_rc != 0) {
                _ = kill(&handle);
                _ = wait(&handle, 1000, &completion);
                _ = reap(&handle, &completion);
                return -33;
            }
            const valid = completion.handle.instance_id == handle.instance_id and completion.handle.generation == handle.generation and (if (mode == 0) completion.exit_code == 37 else if (mode == 2) completion.exit_reason == a.shared.program_exit_reason_killed else if (mode == 3) completion.exit_reason == a.shared.program_exit_reason_failed else if (mode == 4) completion.exit_code == -73 else completion.exit_code == 0);
            if (reap(&handle, &completion) != 0 or !valid) return -34;
        }
    }
    print(view, "PASS APP2 lifecycle languages=3 classes=console/gui/service/subsystem return/close/kill/fault/initfail exact_handles=60 reaped=60\r\n");
    return 0;
}
fn negative(view: *const p.Context) i32 {
    const spawn = a.function(a.R4SysFns2, view.system(), "program_spawn_handle") orelse return -40;
    for ([_][*:0]const u8{ "C:\\R4OS\\TESTS\\BAD2VER.R4X", "C:\\R4OS\\TESTS\\BAD2MIX.R4X", "C:\\R4OS\\TESTS\\BAD2META.R4X", "C:\\R4OS\\TESTS\\BAD2ENTRY.R4X" }) |path| {
        var handle: a.shared.ProgramProcessHandle = .{};
        if (spawn(path, "", @intFromEnum(a.shared.LaunchPolicy.console), &handle) != a.shared.program_handle_error_load_failed or handle.instance_id != 0 or handle.generation != 0) return -41;
    }
    print(view, "PASS APP2 malformed=4 rejected before publication no_handle=4\r\n");
    return 0;
}
