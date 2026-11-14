//! Current raw start view. The caller retains the loader-owned record.
pub const Context = @import("platform2.zig").Context;
pub const R4Sys = @import("r4sys.zig").Context;
pub const R4Desk = @import("r4desk.zig").Context;
pub const R4Draw = @import("r4draw.zig").Context;
pub fn entryAsm(comptime target: []const u8) []const u8 {
    return ".section .text.r4xstart2_entry,\"ax\"\n" ++
        ".global R4XStart2\nR4XStart2:\n    jmp " ++ target ++ "\n";
}
