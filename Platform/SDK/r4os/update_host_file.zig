//! Host lifetime adapter for the original StorageTools HostFile. Opaque fixed
//! storage keeps std.Io details out of the common R4OS C/Rust layout. Guest
//! calls return HostOnly; physical guest I/O uses StorageTarget claims.
const std = @import("std");
const builtin = @import("builtin");
const original = @import("storage_tools/host_file.zig");
const block = @import("storage_tools/io.zig");
pub const File = struct { storage: [64 * 1024]u8 align(64) = undefined };
const State = struct { io: std.Io.Threaded, adapter: original.File, owned: bool };
fn state(file: *File) *State {
    if (@sizeOf(State) > @sizeOf(File) or @alignOf(State) > @alignOf(File)) @compileError("host I/O owner exceeds its opaque storage");
    return @ptrCast(@alignCast(file));
}
/// Opens an existing file read/write without truncation or creation. Only
/// this adapter owns/ends the returned handle; acquire remains explicit.
pub fn open(out: *File, path: []const u8) anyerror!void {
    if (comptime builtin.os.tag == .freestanding) {
        return error.HostOnly;
    } else {
        const s = state(out);
        s.io = .init(std.heap.page_allocator, .{});
        errdefer s.io.deinit();
        const f = try std.Io.Dir.cwd().openFile(s.io.io(), path, .{ .mode = .read_write });
        errdefer f.close(s.io.io());
        s.adapter = try original.File.init(f, s.io.io());
        s.owned = true;
    }
}
/// Borrows a native Windows handle or POSIX descriptor; close never ends the
/// caller's handle. Its exact identity stays live through release/close.
pub fn borrow(out: *File, handle: usize) anyerror!void {
    if (comptime builtin.os.tag == .freestanding) {
        return error.HostOnly;
    } else {
        const s = state(out);
        s.io = .init(std.heap.page_allocator, .{});
        errdefer s.io.deinit();
        const native: std.Io.File.Handle = if (builtin.os.tag == .windows) @ptrFromInt(handle) else std.math.cast(std.Io.File.Handle, handle) orelse return error.InvalidHandle;
        s.adapter = try original.File.init(.{ .handle = native, .flags = .{ .nonblocking = false } }, s.io.io());
        s.owned = false;
    }
}
pub fn acquire(file: *File) anyerror!void {
    if (comptime builtin.os.tag == .freestanding) return error.HostOnly else try state(file).adapter.acquire();
}
pub fn release(file: *File) anyerror!void {
    if (comptime builtin.os.tag == .freestanding) return error.HostOnly else state(file).adapter.release();
}
pub fn resize(file: *File, sectors: u64) anyerror!void {
    if (comptime builtin.os.tag == .freestanding) return error.HostOnly else try state(file).adapter.resize(sectors);
}
pub fn device(file: *File, progress: ?*block.Progress) anyerror!block.Device {
    if (comptime builtin.os.tag == .freestanding) return error.HostOnly else return state(file).adapter.device(progress);
}
pub fn lastError(file: *File) ?[]const u8 {
    if (comptime builtin.os.tag == .freestanding) return null else {
        const e = state(file).adapter.last_error orelse return null;
        return @errorName(e);
    }
}
/// Release the lock before ending the owned handle/backend. No implicit
/// durability receipt: callers use the original Device.flush explicitly.
pub fn close(file: *File) anyerror!void {
    if (comptime builtin.os.tag == .freestanding) return error.HostOnly else {
        const s = state(file);
        s.adapter.release();
        if (s.owned) s.adapter.file.close(s.io.io());
        s.io.deinit();
    }
}
