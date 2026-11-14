//! Borrowed ProtocolApi2 conveniences. The real table is validated in place;
//! callbacks never acquire an owner or extend its lifetime.
const abi = @import("r4os_contract").abi;
const technical = @import("technical2.zig");
pub const Api = technical.abi.ProtocolApi2;
pub const Context = struct {
    api: *const Api,
    pub fn init(api: *const Api) Context {
        return .{ .api = api };
    }
    pub fn function(self: *const Context, comptime field: []const u8) ?Callback(field) {
        return (technical.Protocol.init(self.api) orelse return null).function(field);
    }
    pub fn requires(self: *const Context, comptime fields: anytype) bool {
        if (technical.Protocol.init(self.api) == null) return false;
        inline for (fields) |field| if (self.function(field) == null) return false;
        return true;
    }
    /// Admit the actual technical table here; the portable entropy owner
    /// receives only its existing typed callback provider. Invalid rebinding
    /// also clears the former scope, without synthesizing another table.
    pub fn bindEntropy(self: *const Context) void {
        const random = @import("secure_random.zig");
        const view = technical.Protocol.init(self.api) orelse {
            random.Provider.bind(.{});
            return;
        };
        (random.Provider{ .info = view.function("entropy_source_info"), .device = view.function("entropy_fill"), .hardware_info = view.function("cpu_acceleration_info"), .hardware = view.function("cpu_acceleration_work") }).bind();
    }
    pub fn logInfo(self: *const Context, text: [*:0]const u8) void {
        if (self.function("log_info")) |log| log(text);
    }
    pub fn logError(self: *const Context, text: [*:0]const u8) void {
        if (self.function("log_error")) |log| log(text);
    }
    pub fn logWarn(self: *const Context, text: [*:0]const u8) void {
        if (self.function("log_warn")) |log| log(text);
    }
    pub fn dependencyStatus(self: *const Context, role: [*:0]const u8) i32 {
        const callback = self.function("dependency_status") orelse return abi.err_no_fn;
        return callback(role);
    }
    pub fn alloc(self: *const Context, bytes: u32, alignment: u32) ?*anyopaque {
        const callback = self.function("alloc") orelse return null;
        return callback(bytes, alignment);
    }
    pub fn free(self: *const Context, memory: ?*anyopaque, bytes: u32) void {
        if (self.function("free")) |callback| callback(memory, bytes);
    }
    pub fn registerRole(self: *const Context, role: [*:0]const u8, category: abi.ProtocolCategory, flags: u32) i32 {
        const register = self.function("register_role") orelse return abi.err_no_fn;
        return register(role, @intFromEnum(category), flags);
    }
    pub fn setStatus(self: *const Context, state: abi.ProtocolState, note: [*:0]const u8) i32 {
        const status = self.function("set_status") orelse return abi.err_no_fn;
        return status(@intFromEnum(state), note);
    }
    pub fn fileRead(self: *const Context, path: [*:0]const u8, out: []u8) i32 {
        if (out.len > 2147483647) return abi.file_stream_error_too_large;
        const read = self.function("file_read") orelse return abi.err_no_fn;
        return read(path, out.ptr, @intCast(out.len));
    }
};
fn Callback(comptime field: []const u8) type {
    const T = @FieldType(Api, field);
    return if (@typeInfo(T) == .optional) @typeInfo(T).optional.child else T;
}
