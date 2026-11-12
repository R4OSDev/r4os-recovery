//! Module-local terminal callback for the shared C/Rust facade object.
//! Bind after normal entry validation, before workers/callbacks. Copy only
//! the resident callback; no root App or loader-context loan is retained.
const std = @import("std");
const abi = @import("r4os_contract").abi;
var terminal: usize = 0;

pub fn bind(function: ?abi.R4SysFns.program_exit) void {
    @atomicStore(usize, &terminal, if (function) |f| @intFromPtr(f) else 0, .release);
}
pub const panic = std.debug.FullPanic(struct {
    fn panic(_: []const u8, _: ?usize) noreturn {
        const address = @atomicLoad(usize, &terminal, .acquire);
        if (address != 0) {
            const exit: abi.R4SysFns.program_exit = @ptrFromInt(address);
            _ = exit(-104, abi.program_exit_reason_failed);
        }
        @trap();
    }
}.panic);
