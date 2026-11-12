// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const application = @import("application.zig");
const local = @import("process_local.zig");
const threads = @import("threads.zig");
const e = struct { const noent=2; const io=5; const badf=9; const busy=16; const exists=17; const isdir=21; const invalid=22; const notty=25; const big=27; const unsupported=95; };
fn files() ?r.app_storage.Files {
    return .{ .sys = (application.snapshot() orelse return null).system() };
}
fn streamError(code: i32) i32 {
    return -@as(i32, switch (code) {
        a.file_stream_error_exists => e.exists,
        a.file_stream_error_not_found => e.noent,
        a.file_stream_error_invalid => e.invalid,
        a.file_stream_error_too_large => e.big,
        a.file_stream_error_unsupported, a.err_no_fn, a.err_no_group => e.unsupported,
        else => e.io,
    });
}
fn ioError(code: i32) i32 {
    return -@as(i32, switch (code) {
        a.io_error_not_found => e.noent,
        a.io_error_invalid => e.invalid,
        a.io_error_too_large => e.big,
        a.io_error_busy, a.io_error_no_slots, a.io_error_lock_violation => e.busy,
        a.io_error_unsupported, a.err_no_fn, a.err_no_group => e.unsupported,
        else => e.io,
    });
}
fn path(name: [*:0]const u8) ?r.app_storage.AbsoluteFilePath {
    var length: usize = 0;
    while (length <= r.path.file_path_max and name[length] != 0) : (length += 1) {}
    if (length > r.path.file_path_max) return null;
    return r.app_storage.AbsoluteFilePath.parse(name[0..length]) catch null;
}
pub export fn r4native_file_path(name: [*:0]const u8, out: [*]u8, capacity: u32) callconv(.c) i32 {
    const fs = files() orelse return -e.unsupported;
    var length: usize = 0;
    while (length <= r.path.file_path_max and name[length] != 0) : (length += 1) {}
    if (length > r.path.file_path_max) return -e.invalid;
    if (length == 0) return -e.invalid;
    var resolved: r.app_storage.AbsoluteFilePath = undefined;
    if (length >= 2 and name[1] == ':') {
        resolved = r.app_storage.AbsoluteFilePath.parse(name[0..length]) catch return -e.invalid;
    } else {
        var cwd: [r.path.file_path_max + 1]u8 = undefined;
        const size = fs.sys.envGet("CWD", &cwd);
        if (size <= 0 or size >= cwd.len) return -e.io;
        const directory = r.app_storage.AbsoluteFilePath.parse(cwd[0..@intCast(size)]) catch return -e.invalid;
        var joined: [r.path.file_path_max * 2 + 2]u8 = undefined;
        const rooted = name[0] == '/' or name[0] == '\\';
        const prefix = directory.bytes()[0..if (rooted) 2 else directory.len];
        const text = std.fmt.bufPrint(&joined, "{s}{s}{s}", .{prefix, if (rooted) "" else "\\", name[0..length]}) catch return -e.invalid;
        resolved = r.app_storage.AbsoluteFilePath.parse(text) catch return -e.invalid;
    }
    if (resolved.len >= capacity) return -e.invalid;
    @memcpy(out[0..resolved.len], resolved.bytes()); out[resolved.len] = 0;
    return resolved.len;
}
pub export fn r4native_file_size(name: [*:0]const u8, output: *u64) callconv(.c) i32 {
    const fs = files() orelse return -e.unsupported;
    const file = path(name) orelse return -e.invalid;
    switch (fs.info(file.asZ())) {
        .value => |info| { if (info.is_dir != 0) return -e.isdir; output.* = info.size; return 0; },
        .missing => return -e.noent,
        .failure => return -e.io,
    }
}
pub export fn r4native_file_open(name: [*:0]const u8, mode: u32) callconv(.c) i32 {
    const fs = files() orelse return -e.unsupported;
    const file = path(name) orelse return -e.invalid;
    if (mode & ~@as(u32, 63) != 0 or mode & 3 == 0) return -e.invalid;
    const create = mode & 8 != 0; const truncate = mode & 16 != 0; const exclusive = mode & 32 != 0;
    if (!create and !truncate) { var size: u64 = 0; return r4native_file_size(name, &size); }
    // Begin performs create-only/truncate atomically under the existing VFS
    // owner. No stat-then-create emulation of exclusive creation.
    const flags: u32 = (if (create) a.file_stream_open_create else 0) | (if (truncate and !exclusive) a.file_stream_open_truncate else 0);
    var writer = switch (fs.streamWriter(file.asZ(), flags)) {
        .writer => |value| value,
        .failure => |code| {
            if (code == a.file_stream_error_exists and !exclusive and !truncate) {
                var size: u64 = 0; return r4native_file_size(name, &size);
            }
            return streamError(code);
        },
    };
    switch (writer.finish()) {
        .ok => return 0,
        .failure => |code| { _ = writer.abort(); return streamError(code); },
        .missing => { _ = writer.abort(); return -e.noent; },
    }
}
fn available(sys: *const r.r4sys.Context, comptime operation: []const u8) bool {
    return sys.hasFn(operation) and sys.hasFn("io_wait") and sys.hasFn("io_close");
}
fn complete(sys: *const r.r4sys.Context, id: u32) i32 {
    // The stack/caller buffer must remain alive until the real request ends.
    // Timeout is not completion. No lock or borrowed Bundle spans this wait.
    while (true) {
        var info: a.ProgramIoInfo = .{};
        const rc = sys.ioWait(id, std.math.maxInt(u64), &info);
        if (rc == a.io_error_timeout) continue;
        if (info.request_id == id and (info.state == a.io_state_completed or info.state == a.io_state_failed)) {
            if (sys.ioClose(id) == 0) return info.result;
        } else if (rc == a.io_error_not_found or (rc != 0 and sys.ioClose(id) == 0)) return rc;
        // Do not free a caller buffer while the kernel still owns the request.
        threads.thrd_yield();
    }
}
pub export fn r4native_file_read(name: [*:0]const u8, offset: u64, out: [*]u8, count: u32) callconv(.c) i64 {
    const fs = files() orelse return -e.unsupported;
    const file = path(name) orelse return -e.invalid;
    if (count > std.math.maxInt(i32)) return -e.big;
    if (!available(&fs.sys, "io_file_read_at")) return -e.unsupported;
    var id: u32 = 0;
    const rc = fs.sys.ioFileReadAt(file.asZ().ptr, offset, out[0..count], 0, &id);
    if (rc != 0) return ioError(rc);
    const got = complete(&fs.sys, id);
    if (got >= 0) return got;
    // Read completion retains the synchronous filesystem result domain.
    return -@as(i64, switch (got) { -1 => e.invalid, -3 => e.noent, -4 => e.isdir, -7 => e.busy, -8 => e.big, else => e.io });
}
pub export fn r4native_file_write(name: [*:0]const u8, offset: u64, data: [*]const u8, count: u32, mode: u32) callconv(.c) i64 {
    const fs = files() orelse return -e.unsupported;
    const file = path(name) orelse return -e.invalid;
    if (count > std.math.maxInt(i32)) return -e.big;
    if (mode & 4 != 0) return switch (fs.append(file.asZ(), data[0..count])) {
        .bytes => |n| n, .end => 0, .failure => -@as(i64, e.io),
    };
    if (!available(&fs.sys, "io_file_write_at")) return -e.unsupported;
    var id: u32 = 0;
    const rc = fs.sys.ioFileWriteAt(file.asZ().ptr, offset, data[0..count], 0, &id);
    if (rc != 0) return ioError(rc);
    const written = complete(&fs.sys, id);
    return if (written < 0) ioError(written) else written;
}
pub export fn r4native_stdio_state(key: *const anyopaque, bytes: usize, alignment: usize, initialize: local.Initializer) callconv(.c) ?*anyopaque {
    return local.initializedBlob(key, bytes, alignment, initialize);
}
pub export fn r4native_stream_write(stream: u32, bytes: [*]const u8, count: u32) callconv(.c) i32 {
    if (stream != 1 and stream != 2) return -e.badf;
    const fs = files() orelse return -e.unsupported;
    const rc = fs.sys.base.consoleWrite(@enumFromInt(stream), bytes[0..count]);
    return if (rc < 0) -e.io else rc;
}
pub export fn r4native_stream_read(stream: u32, bytes: [*]u8, count: u32) callconv(.c) i32 {
    if (stream != 0) return -e.badf;
    const fs = files() orelse return -e.unsupported;
    if (count == 0) return 0;
    var revision: u64 = 0;
    _ = fs.sys.consoleInputWait(0, 0, &revision);
    while (true) {
        const rc = fs.sys.consoleRead(bytes[0..count]);
        if (rc != 0) return if (rc < 0) -e.io else rc;
        if (fs.sys.programCurrentConsoleHost() == .none) return -e.notty;
        const waited = fs.sys.consoleInputWait(revision, 100, &revision);
        if (waited < 0) return -e.io;
    }
}
pub export fn r4native_stream_terminal(stream: u32) callconv(.c) i32 {
    if (stream > 2) return -e.badf;
    const fs = files() orelse return -e.unsupported;
    return if (fs.sys.programCurrentConsoleHost() != .none) 1 else -e.notty;
}
