//! Concrete allocator/reader/context and hashing specializations only.
const std = @import("std");
const a = @import("r4os_contract").abi;
const p = @import("program.zig");
const owners = @import("data_helper_owners.zig");
pub const Context = struct { bundle: p.Bundle, dev: @import("r4dev.zig").Context, system: @import("r4sys.zig").Context };
/// Initialize at its final address; all derived protocol views borrow it.
pub fn open(output: *Context, raw: *const a.R4XStartContext) bool {
    output.bundle = p.bundleValueFromR4XStart(raw) orelse return false;
    output.dev = .init(&output.bundle);
    output.system = .init(&output.bundle);
    return true;
}
pub fn json(output: *owners.json.Document, ctx: *const Context, bytes: []const u8, depth: []u8) void {
    output.* = .init(&ctx.dev, bytes, depth);
}
pub fn zip(ctx: *const Context) owners.zip.Context {
    return .{ .dev = &ctx.dev };
}
/// Bind the exact original instance's entropy callbacks before workers.
pub fn entropyProvider(ctx: *const Context) owners.random.Provider {
    const c = p.Context.initBundle(&ctx.bundle);
    return .{ .info = c.entropyInfoFunction(), .device = c.entropyFillFunction(), .hardware_info = c.cpuAccelerationInfoFunction(), .hardware = c.cpuAccelerationWorkFunction() };
}
pub fn hashUpdate(self: *owners.hash, ctx: *const Context, bytes: []const u8) void {
    const c = p.Context.initBundle(&ctx.bundle);
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
