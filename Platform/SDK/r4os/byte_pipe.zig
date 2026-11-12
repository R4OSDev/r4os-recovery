//! Explicitly owned bounded byte streams. Copying an Endpoint is not Dup.
//! Close every reference; no implicit launch inheritance or WaitSource adapter.
const abi = @import("r4os_contract").abi;
const platform = @import("platform2.zig");
pub const End = abi.BytePipeEnd;
pub const Progress = abi.BytePipeProgress;
pub const Info = abi.BytePipeInfo;
pub const Deadline = abi.WaitSetDeadline;
pub const deadline = @import("wait_set.zig").deadline;
pub const Provider = struct {
    create: abi.R4SysFns.byte_pipe_create,
    duplicate: abi.R4SysFns.byte_pipe_dup,
    read: abi.R4SysFns.byte_pipe_read,
    write: abi.R4SysFns.byte_pipe_write,
    cancel: abi.R4SysFns.byte_pipe_cancel,
    close: abi.R4SysFns.byte_pipe_close,
    info: abi.R4SysFns.byte_pipe_info,
    pub fn fromContext(context: *const platform.Context, output: *Provider) i32 {
        var addresses: [7]u64 = @splat(0);
        inline for (.{ "byte_pipe_create", "byte_pipe_dup", "byte_pipe_read", "byte_pipe_write", "byte_pipe_cancel", "byte_pipe_close", "byte_pipe_info" }, 0..) |name, i| {
            const code = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, name), &addresses[i]);
            if (code != 0) return code;
        }
        output.* = .{ .create = @ptrFromInt(addresses[0]), .duplicate = @ptrFromInt(addresses[1]), .read = @ptrFromInt(addresses[2]), .write = @ptrFromInt(addresses[3]), .cancel = @ptrFromInt(addresses[4]), .close = @ptrFromInt(addresses[5]), .info = @ptrFromInt(addresses[6]) };
        return 0;
    }
};
pub const Endpoint = struct {
    provider: Provider,
    value: End,
    pub fn duplicate(self: *const Endpoint, output: *Endpoint) i32 {
        if (@intFromPtr(self) == @intFromPtr(output)) return abi.byte_pipe_error_invalid;
        var value: End = .{};
        const code = self.provider.duplicate(self.value, &value);
        if (code == 0) output.* = .{ .provider = self.provider, .value = value };
        return code;
    }
    pub fn read(self: *const Endpoint, storage: []u8, limit: Deadline, output: *Progress) i32 {
        return self.provider.read(self.value, storage.ptr, storage.len, &limit, output);
    }
    pub fn write(self: *const Endpoint, bytes: []const u8, limit: Deadline, output: *Progress) i32 {
        return self.provider.write(self.value, bytes.ptr, bytes.len, &limit, output);
    }
    pub fn cancel(self: *const Endpoint) i32 {
        return self.provider.cancel(self.value);
    }
    pub fn info(self: *const Endpoint, output: *Info) i32 {
        return self.provider.info(self.value, output);
    }
    /// Failed backing release retains the exact closed identity for retry.
    pub fn close(self: *Endpoint) i32 {
        if (self.value.handle == 0) return 0;
        const code = self.provider.close(self.value);
        if (code == 0) self.value = .{};
        return code;
    }
};
pub const Pair = struct { reader: Endpoint, writer: Endpoint };
pub fn create(context: *const platform.Context, capacity: u64, output: *Pair) i32 {
    var provider: Provider = undefined;
    const selected = Provider.fromContext(context, &provider);
    if (selected != 0) return selected;
    var pair: abi.BytePipePair = .{};
    const code = provider.create(capacity, &pair);
    if (code == 0) output.* = .{ .reader = .{ .provider = provider, .value = pair.reader }, .writer = .{ .provider = provider, .value = pair.writer } };
    return code;
}
