const std = @import("std");
const r4os = @import("r4os");
const app_source = @import("r4_app_source");
const facts = @import("r4_startup2");

var panic_write: usize = 0;
var panic_exit: usize = 0;

export fn R4XStart2(raw: *const r4os.platform2.abi.R4XStartContext2) linksection(".text.r4xstart_entry") callconv(.c) i32 {
    var app = switch (r4os.App2.initDeclared(raw, &facts.startup)) {
        .value => |value| value,
        .failure => |failure| return failure.raw_code,
    };
    const low = app.lowLevel();
    r4os.secure_random.bindProgram(&low);
    const functions = r4os.platform2.abi.R4SysFns2;
    const write = r4os.platform2.abi.function(functions, app.context.system(), "write");
    const exit = r4os.platform2.abi.function(functions, app.context.system(), "program_exit");
    @atomicStore(usize, &panic_write, if (write) |f| @intFromPtr(f) else 0, .release);
    @atomicStore(usize, &panic_exit, if (exit) |f| @intFromPtr(f) else 0, .release);
    defer {
        @atomicStore(usize, &panic_write, 0, .release);
        @atomicStore(usize, &panic_exit, 0, .release);
    }
    return app_source.r4_app_main(&app);
}

pub const panic = std.debug.FullPanic(struct {
    fn panic(message: []const u8, _: ?usize) noreturn {
        const write_address = @atomicLoad(usize, &panic_write, .acquire);
        if (write_address != 0) {
            const write: r4os.platform2.abi.R4SysFns2.write = @ptrFromInt(write_address);
            _ = write(message.ptr, @intCast(@min(message.len, std.math.maxInt(u32))));
        }
        const exit_address = @atomicLoad(usize, &panic_exit, .acquire);
        if (exit_address != 0) {
            const exit: r4os.platform2.abi.R4SysFns2.program_exit = @ptrFromInt(exit_address);
            _ = exit(-102, r4os.lowlevel.abi.program_exit_reason_failed);
        }
        @trap();
    }
}.panic);
