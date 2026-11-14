//! The same module-local initialization as Shared/Zig/r4app_startup.zig.
//! Called once after declared start validation, before publishing workers or
//! callbacks. bindProgram copies resident functions, never the local Bundle.
const abi = @import("r4os_contract").abi;
const program = @import("program.zig");
pub export fn R4SdkBindProgramEntropy(raw: *const @import("r4os_contract2").R4XStartContext2) callconv(.c) i32 {
    const bundle = program.bundleValueFromR4XStart(raw) orelse return abi.io_error_invalid;
    const context = program.Context.initBundle(&bundle);
    @import("secure_random.zig").bindProgram(&context);
    @import("runtime_fault.zig").bind(if (bundle.sys) |table| @import("allocator_source.zig").Source.system2(table).function("program_exit") else null);
    return 0;
}
