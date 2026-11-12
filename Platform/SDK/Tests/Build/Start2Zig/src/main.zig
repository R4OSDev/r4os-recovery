const std = @import("std");
const p = @import("r4os").platform2;
const a = p.abi;
pub export fn R4XStart2(raw: *const a.R4XStartContext2) callconv(.c) i32 {
    return p.start(raw, .{ .app_class = 1, .required_groups = 2, .import_count = 2 }, &run);
}
fn print(view: *const p.Context, text: []const u8) void {
    const write = a.function(a.R4SysFns2, view.system(), "write") orelse return;
    _ = write(text.ptr, @intCast(text.len));
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
    print(view, "PASS START2Z context=120 query=24 borrowed_args/imports callbacks=2\r\n");
    if (std.mem.eql(u8, view.args(), "fault")) asm volatile ("ud2");
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
    for ([_][*:0]const u8{ "C:\\R4OS\\TESTS\\START2Z.R4X", "C:\\R4OS\\TESTS\\START2C.R4X", "C:\\R4OS\\TESTS\\START2R.R4X" }) |path| {
        for (0..4) |mode| {
            const args: [*:0]const u8 = switch (mode) {
                0 => "return",
                1, 2 => "hold",
                else => "fault",
            };
            var handle: a.shared.ProgramProcessHandle = .{};
            if (spawn(path, args, @intFromEnum(a.shared.LaunchPolicy.console), &handle) != 0 or handle.instance_id == 0 or handle.generation == 0) return -31;
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
            if (wait(&handle, 1000, &completion) != 0) {
                _ = kill(&handle);
                _ = wait(&handle, 1000, &completion);
                _ = reap(&handle, &completion);
                return -33;
            }
            const valid = completion.handle.instance_id == handle.instance_id and completion.handle.generation == handle.generation and (if (mode == 0) completion.exit_code == 37 else if (mode == 2) completion.exit_reason == a.shared.program_exit_reason_killed else if (mode == 3) completion.exit_reason == a.shared.program_exit_reason_failed else completion.exit_code == 0);
            if (reap(&handle, &completion) != 0 or !valid) return -34;
        }
    }
    print(view, "PASS START2 lifecycle languages=3 return/close/kill/fault exact_handles=12 reaped=12\r\n");
    return 0;
}
fn negative(view: *const p.Context) i32 {
    const spawn = a.function(a.R4SysFns2, view.system(), "program_spawn_handle") orelse return -40;
    for ([_][*:0]const u8{ "C:\\R4OS\\TESTS\\BAD2VER.R4X", "C:\\R4OS\\TESTS\\BAD2MIX.R4X", "C:\\R4OS\\TESTS\\BAD2META.R4X", "C:\\R4OS\\TESTS\\BAD2ENTRY.R4X" }) |path| {
        var handle: a.shared.ProgramProcessHandle = .{};
        if (spawn(path, "", @intFromEnum(a.shared.LaunchPolicy.console), &handle) != a.shared.program_handle_error_load_failed or handle.instance_id != 0 or handle.generation != 0) return -41;
    }
    print(view, "PASS START2 malformed=4 rejected before publication no_handle=4\r\n");
    return 0;
}
