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
        ".global r4p_init_entry\n" ++
        "r4p_init_entry:\n" ++
        "    jmp " ++ init_target ++ "\n" ++
        ".global r4p_shutdown_entry\n" ++
        "r4p_shutdown_entry:\n" ++
        "    jmp " ++ shutdown_target ++ "\n" ++
        ".global r4p_query_entry\n" ++
        "r4p_query_entry:\n" ++
        "    jmp " ++ query_target ++ "\n" ++
        ".global r4p_dispatch_entry\n" ++
        "r4p_dispatch_entry:\n" ++
        "    jmp " ++ dispatch_target ++ "\n";
}

pub const Context = struct {
    api: *const abi.ProtocolApi,

    pub fn init(api: *const abi.ProtocolApi) Context {
        return .{ .api = api };
    }

    pub fn logInfo(self: *const Context, text: [*:0]const u8) void {
        self.api.log_info(text);
    }

    pub fn logWarn(self: *const Context, text: [*:0]const u8) void {
        self.api.log_warn(text);
    }

    pub fn logError(self: *const Context, text: [*:0]const u8) void {
        self.api.log_error(text);
    }

    pub fn registerRole(self: *const Context, role: [*:0]const u8, category: abi.ProtocolCategory, flags: u32) i32 {
        return self.api.register_role(role, @intFromEnum(category), flags);
    }

    pub fn setStatus(self: *const Context, state: abi.ProtocolState, note: [*:0]const u8) i32 {
        return self.api.set_status(@intFromEnum(state), note);
    }

    pub fn dependencyStatus(self: *const Context, role: [*:0]const u8) i32 {
        return self.api.dependency_status(role);
    }

    pub fn alloc(self: *const Context, bytes: u32, alignment: u32) ?*anyopaque {
        return self.api.alloc(bytes, alignment);
    }

    pub fn free(self: *const Context, ptr: ?*anyopaque, bytes: u32) void {
        self.api.free(ptr, bytes);
    }

    pub fn fileRead(self: *const Context, path: [*:0]const u8, out: []u8) i32 {
        return self.api.file_read(path, out.ptr, @intCast(out.len));
    }
};
