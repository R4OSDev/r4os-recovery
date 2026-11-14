const abi = @import("r4os_contract").abi;

pub const r4p_shutdown_entry_offset: u32 = 5;
pub const r4p_query_entry_offset: u32 = 10;
pub const r4p_dispatch_entry_offset: u32 = 15;

pub fn entriesAsm(
    comptime init_target: []const u8,
    comptime shutdown_target: []const u8,
    comptime query_target: []const u8,
    comptime dispatch_target: []const u8,
) []const u8 {
    return ".section .text.r4p_entries,\"ax\"\n" ++
        ".global ProtocolInit2\n" ++
        "ProtocolInit2:\n" ++
        "    jmp " ++ init_target ++ "\n" ++
        ".global ProtocolShutdown\n" ++
        "ProtocolShutdown:\n" ++
        "    jmp " ++ shutdown_target ++ "\n" ++
        ".global ProtocolQuery\n" ++
        "ProtocolQuery:\n" ++
        "    jmp " ++ query_target ++ "\n" ++
        ".global ProtocolDispatch\n" ++
        "ProtocolDispatch:\n" ++
        "    jmp " ++ dispatch_target ++ "\n";
}

pub const Context = @import("protocol2.zig").Context;
