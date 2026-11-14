//! Concrete allocator/reader/context and hashing specializations only.
const std = @import("std");
const a = @import("r4os_contract").abi;
const p = @import("program.zig");
const owners = @import("data_helper_owners.zig");
pub const Context = struct { dev: @import("r4dev.zig").Context, system: @import("r4sys.zig").Context, context2: ?@import("platform2.zig").Context = null, memory2: @import("allocator_source.zig").Memory = undefined };
/// Initialize at its final address; all derived protocol views borrow it.
pub fn json(output: *owners.json.Document, ctx: *const Context, bytes: []const u8, depth: []u8) void {
    output.* = .init(&ctx.dev, bytes, depth);
}
pub fn zip(ctx: *const Context) owners.zip.Context {
    return .{ .dev = &ctx.dev };
}
/// Bind the exact original instance's entropy callbacks before workers.
pub fn entropyProvider(ctx: *const Context) owners.random.Provider {
    const c = ctx.system.base;
    return .{ .info = c.entropyInfoFunction(), .device = c.entropyFillFunction(), .hardware_info = c.cpuAccelerationInfoFunction(), .hardware = c.cpuAccelerationWorkFunction() };
}
pub fn hashUpdate(self: *owners.hash, ctx: *const Context, bytes: []const u8) void {
    const c = ctx.system.base;
    self.updateWithExecutor(bytes, c.cpuAccelerationWorkFunction());
}
pub fn hashInit(output: *owners.hash) void {
    output.* = .init(.{});
}
pub const Arena = std.heap.FixedBufferAllocator;
pub fn arena(output: *Arena, bytes: []u8) void {
    output.* = .init(bytes);
}
pub fn allocator(self: *Arena) std.mem.Allocator {
    return self.allocator();
}
pub fn reset(self: *Arena) void {
    self.reset();
}
pub fn used(self: *const Arena) usize {
    return self.end_index;
}
pub fn inspectBytes(bytes: []const u8) ?owners.artifact.Identity {
    return owners.artifact.inspect(owners.artifact.SliceReader{ .bytes = bytes }, bytes.len);
}
pub const Reader = struct {
    user: ?*anyopaque = null,
    callback: *const fn (?*anyopaque, u64, [*]u8, usize) callconv(.c) u8,
    pub fn readAt(self: Reader, offset: u64, bytes: []u8) bool {
        return self.callback(self.user, offset, bytes.ptr, bytes.len) != 0;
    }
};
pub fn inspectReader(reader: Reader, size: u64) ?owners.artifact.Identity {
    return owners.artifact.inspect(reader, size);
}

/// The legacy C facade uses the same reply owner as Zig and safe Rust.
pub fn audioStreamReplyValid(bytes: []const u8, action: u16, stream_id: u32, maximum_bytes: u32, frame_bytes: u64) bool {
    return @import("audio_stream_reply.zig").validate(bytes, action, stream_id, maximum_bytes, frame_bytes);
}

/// Initialize at the final pinned address. Every derived helper borrows this
/// exact generation2 context and memory input until its real close/quiescence.
pub fn open2(output: *Context, raw: *const @import("platform2.zig").abi.R4XStartContext2) bool {
    const context = @import("platform2.zig").Context.init(raw) catch return false;
    output.context2 = context;
    output.memory2 = @import("allocator_source.zig").Memory.fromContext2(&output.context2.?);
    const program: p.Context = .{ .generation2 = &output.context2.?, .memory2 = &output.memory2 };
    output.dev = @import("r4dev.zig").Context.fromProgram(program);
    output.system = @import("r4sys.zig").Context.fromProgram(program);
    return true;
}
