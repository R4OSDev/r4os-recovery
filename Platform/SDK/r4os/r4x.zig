//! Current raw start aliases; no alternate admission or global binding.
const start = @import("r4xstart.zig");
pub const StartContext = @import("r4os_contract2").R4XStartContext2;
pub const Import = @import("r4os_contract").abi.R4XStartImport;
pub const Context = start.Context;
pub const R4Sys = start.R4Sys;
pub const R4Desk = start.R4Desk;
pub const R4Draw = start.R4Draw;
pub const entryAsm = start.entryAsm;
pub fn init(raw: *const StartContext) @import("platform2.zig").Error!Context {
    return Context.init(raw);
}
