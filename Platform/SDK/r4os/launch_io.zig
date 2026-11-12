//! Optional copied Start2 bindings; no automatic pipe inheritance or app routing.
//! Stdio snapshots borrow exact child references; copies are never Dup. Close
//! explicitly and retain failed Close identities. Context/code outlive all calls.
const std = @import("std");
const a = @import("r4os_contract").abi;
const platform = @import("platform2.zig");
const pipe = @import("byte_pipe.zig");
pub const Request = a.LaunchIo;
pub const Binding = a.LaunchIoBinding;
pub fn pipeBinding(end: a.BytePipeEnd) Binding {
    return .{ .kind = a.launch_io_pipe, .end = end };
}
pub fn launch(context: *const platform.Context, path: [*:0]const u8, args: [*:0]const u8, request: Request, out: *a.ProgramProcessHandle) i32 {
    var address: u64 = 0;
    const rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "program_launch_io"), &address);
    if (rc != 0) return rc;
    const call: a.R4SysFns.program_launch_io = @ptrFromInt(address);
    return call(path, args, &request, out);
}
fn consolePoll(limit: pipe.Deadline) i32 {
    if (limit.version != 1 or limit.size != @sizeOf(pipe.Deadline) or limit.reserved0 != 0) return a.byte_pipe_error_invalid;
    if (limit.kind != 0) return a.byte_pipe_error_unsupported;
    if (!std.meta.eql(limit, pipe.Deadline{})) return a.byte_pipe_error_invalid;
    return 0;
}
fn validProgress(value: pipe.Progress, count: usize) bool {
    return value.version == 1 and value.size == @sizeOf(pipe.Progress) and value.flags == 0 and
        value.bytes <= count and value.state >= a.byte_pipe_ready and value.state <= a.byte_pipe_closed;
}
/// Pipe operations have full native deadlines. Default Console preserves its
/// existing byte/count/routing behavior: Poll only, no EOF/atomic-write claim.
/// Returned console write count means legacy-call handoff, not pipe queueing
/// or delivery. Original console wait/event APIs remain separate.
pub const Stdio = struct {
    context: *const platform.Context,
    snapshot: Request,
    pipes: ?pipe.Provider,
    pub fn init(context: *const platform.Context, out: *Stdio) i32 {
        var address: u64 = 0;
        const code = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "program_stdio"), &address);
        if (code != 0) return code;
        const call: a.R4SysFns.program_stdio = @ptrFromInt(address);
        var snapshot: Request = .{};
        const rc = call(&snapshot);
        if (rc != 0) return rc;
        if (snapshot.version != 1 or snapshot.size != @sizeOf(Request)) return a.launch_io_error_invalid;
        var any = false;
        for ([_]Binding{ snapshot.stdin_binding, snapshot.stdout_binding, snapshot.stderr_binding }) |b| {
            if (b.reserved != 0 or b.kind > a.launch_io_pipe) return a.launch_io_error_invalid;
            any = any or b.kind == a.launch_io_pipe;
        }
        var provider: ?pipe.Provider = null;
        if (any) {
            var value: pipe.Provider = undefined;
            const resolved = pipe.Provider.fromContext(context, &value);
            if (resolved != 0) return resolved;
            provider = value;
        }
        out.* = .{ .context = context, .snapshot = snapshot, .pipes = provider };
        return 0;
    }
    fn selected(self: *Stdio, stream: u32) ?*Binding {
        return switch (stream) {
            0 => &self.snapshot.stdin_binding,
            1 => &self.snapshot.stdout_binding,
            2 => &self.snapshot.stderr_binding,
            else => null,
        };
    }
    /// Borrowed value only; query/byte copy never retains another end.
    pub fn binding(self: *const Stdio, stream: u32) ?Binding {
        return switch (stream) {
            0 => self.snapshot.stdin_binding,
            1 => self.snapshot.stdout_binding,
            2 => self.snapshot.stderr_binding,
            else => null,
        };
    }
    pub fn read(self: *const Stdio, storage: []u8, limit: pipe.Deadline, out: *pipe.Progress) i32 {
        if (storage.len == 0) return a.byte_pipe_error_invalid;
        const b = self.snapshot.stdin_binding;
        if (b.kind == a.launch_io_pipe) {
            const provider = self.pipes orelse return a.byte_pipe_error_unsupported;
            return provider.read(b.end, storage.ptr, storage.len, &limit, out);
        }
        const valid = consolePoll(limit);
        if (valid != 0) return valid;
        var address: u64 = 0;
        const code = self.context.lookup(2, @offsetOf(platform.abi.R4XStartR4Desk2, "console_read"), &address);
        if (code != 0) return code;
        const call: a.R4DeskFns.console_read = @ptrFromInt(address);
        var staged: [a.byte_pipe_max_step]u8 = undefined;
        const count: usize = @min(storage.len, staged.len);
        const rc = call(&staged, @intCast(count));
        if (rc < 0) return rc;
        const n: usize = @intCast(rc);
        if (n > count) return a.byte_pipe_error_invalid;
        @memcpy(storage[0..n], staged[0..n]);
        out.* = .{ .bytes = n, .state = if (n != 0) a.byte_pipe_ready else a.byte_pipe_would_block };
        return 0;
    }
    pub fn write(self: *const Stdio, stream: u32, bytes: []const u8, limit: pipe.Deadline, out: *pipe.Progress) i32 {
        const b = self.binding(stream) orelse return a.byte_pipe_error_invalid;
        if (stream == 0 or bytes.len == 0) return a.byte_pipe_error_invalid;
        if (b.kind == a.launch_io_pipe) {
            const provider = self.pipes orelse return a.byte_pipe_error_unsupported;
            return provider.write(b.end, bytes.ptr, bytes.len, &limit, out);
        }
        const valid = consolePoll(limit);
        if (valid != 0) return valid;
        var address: u64 = 0;
        const code = self.context.lookup(2, @offsetOf(platform.abi.R4XStartR4Desk2, "console_write"), &address);
        if (code != 0) return code;
        const call: a.R4DeskFns.console_write = @ptrFromInt(address);
        const count: usize = @min(bytes.len, @as(usize, @intCast(a.byte_pipe_max_step)));
        const rc = call(stream, bytes.ptr, @intCast(count));
        if (rc < 0) return rc;
        const n: usize = @intCast(rc);
        if (n > count) return a.byte_pipe_error_invalid;
        out.* = .{ .bytes = n, .state = if (n != 0) a.byte_pipe_ready else a.byte_pipe_would_block };
        return 0;
    }
    /// Validated source composition. Malformed replies keep caller storage
    /// private and leave the public progress target unchanged.
    pub fn readChecked(self: *const Stdio, storage: []u8, limit: pipe.Deadline, out: *pipe.Progress) i32 {
        if (storage.len == 0) return a.byte_pipe_error_invalid;
        var private_bytes: [a.byte_pipe_max_step]u8 = undefined;
        const count = @min(storage.len, private_bytes.len);
        var progress: pipe.Progress = .{};
        const rc = self.read(private_bytes[0..count], limit, &progress);
        if (rc != 0) return rc;
        if (!validProgress(progress, count)) return a.byte_pipe_error_invalid;
        @memcpy(storage[0..@intCast(progress.bytes)], private_bytes[0..@intCast(progress.bytes)]);
        out.* = progress;
        return 0;
    }
    pub fn writeChecked(self: *const Stdio, stream: u32, bytes: []const u8, limit: pipe.Deadline, out: *pipe.Progress) i32 {
        const count = @min(bytes.len, a.byte_pipe_max_step);
        var progress: pipe.Progress = .{};
        const rc = self.write(stream, bytes[0..count], limit, &progress);
        if (rc != 0) return rc;
        if (!validProgress(progress, count)) return a.byte_pipe_error_invalid;
        out.* = progress;
        return 0;
    }
    pub fn cancel(self: *Stdio, stream: u32) i32 {
        const b = self.selected(stream) orelse return a.byte_pipe_error_invalid;
        if (b.kind != a.launch_io_pipe) return a.byte_pipe_error_unsupported;
        const provider = self.pipes orelse return a.byte_pipe_error_unsupported;
        return provider.cancel(b.end);
    }
    pub fn close(self: *Stdio, stream: u32) i32 {
        const b = self.selected(stream) orelse return a.byte_pipe_error_invalid;
        if (b.kind != a.launch_io_pipe) return a.byte_pipe_error_unsupported;
        if (b.end.handle == 0) return 0;
        const provider = self.pipes orelse return a.byte_pipe_error_unsupported;
        const code = provider.close(b.end);
        if (code == 0) b.end = .{};
        return code;
    }
};

/// Checked normal output, including explicitly supplied child pipe bindings.
/// A write has one bounded deadline. Console counts retain handoff semantics.
pub const Output = struct {
    io: Stdio,
    sys: @import("r4sys.zig").Context,
    clock: @import("stream_adapters.zig").PlatformClock,
    failed: bool = false,
    last: ?@import("stream_transfer.zig").Progress = null,

    pub fn init(app: *const @import("app2.zig").App, out: *Output) i32 {
        var io: Stdio = undefined;
        const rc = app.stdio(&io);
        if (rc != 0) return rc;
        const clock = app.clock() catch return a.err_no_fn;
        out.* = .{ .io = io, .sys = app.system(), .clock = clock };
        return 0;
    }

    fn callback(raw: ?*anyopaque, _: u64, bytes: [*]const u8, count: u32, absolute: *const @import("time_budget.zig").DeadlineBudget) callconv(.c) @import("stream_transfer.zig").Ack {
        const self: *Output = @ptrCast(@alignCast(raw.?));
        const core = @import("stream_transfer.zig");
        const limit: pipe.Deadline = if (self.io.snapshot.stdout_binding.kind == a.launch_io_pipe)
            pipe.deadline(absolute.*) catch return .{ .kind = @intFromEnum(core.IoKind.failed), .error_code = a.byte_pipe_error_clock_changed }
        else
            .{};
        var progress: pipe.Progress = .{};
        const rc = self.io.writeChecked(1, bytes[0..count], limit, &progress);
        if (rc != 0) return .{ .kind = @intFromEnum(core.IoKind.uncertain), .error_code = rc };
        if (progress.bytes > count or progress.state < a.byte_pipe_ready or progress.state > a.byte_pipe_closed) return .{ .kind = @intFromEnum(core.IoKind.uncertain), .error_code = a.byte_pipe_error_invalid };
        return .{ .bytes = @intCast(progress.bytes), .kind = @intFromEnum(switch (progress.state) {
            a.byte_pipe_ready => core.IoKind.progress,
            a.byte_pipe_would_block => .would_block,
            a.byte_pipe_timed_out => .timed_out,
            a.byte_pipe_closed, a.byte_pipe_broken_pipe => .closed,
            else => .failed,
        }), .error_code = if (progress.state == a.byte_pipe_cancelled) @import("stream_adapters.zig").cancelled else 0 };
    }

    pub fn write(self: *Output, bytes: []const u8) void {
        if (self.failed or bytes.len == 0) return;
        const core = @import("stream_transfer.zig");
        const adapters = @import("stream_adapters.zig");
        var budget = @import("rpc_budget.zig").Budget.fromTimeout(self.clock.read, .{ .kind = 1, .nanoseconds = 2_000_000_000 }) catch {
            self.failed = true;
            return;
        };
        const driver: adapters.Driver = .{ .sys = self.sys, .clock = &self.clock, .budget = &budget };
        const progress = driver.write(bytes, a.byte_pipe_max_step, callback, self) catch {
            self.failed = true;
            return;
        };
        self.last = progress;
        self.failed = progress.outcome != @intFromEnum(core.Outcome.complete);
    }

    pub fn recordSink(raw: ?*anyopaque, chunk: *const @import("diagnostic_buffer.zig").Chunk) callconv(.c) @import("diagnostic_buffer.zig").Ack {
        const records = @import("diagnostic_buffer.zig");
        const core = @import("stream_transfer.zig");
        const self: *Output = @ptrCast(@alignCast(raw orelse return .{
            .kind = @intFromEnum(records.SinkKind.failed),
            .error_code = a.byte_pipe_error_invalid,
        }));
        if (self.failed or chunk.offset > chunk.total or chunk.length > chunk.total - chunk.offset) return .{
            .kind = @intFromEnum(records.SinkKind.failed),
            .error_code = a.byte_pipe_error_invalid,
        };
        if (chunk.length == 0) return .{};
        self.last = null;
        self.write(chunk.data[0..chunk.length]);
        const progress = self.last orelse return .{
            .kind = @intFromEnum(records.SinkKind.uncertain),
            .error_code = a.byte_pipe_error_invalid,
        };
        const uncertain = progress.flags & core.effect_uncertain != 0;
        return .{
            .accepted_bytes = @intCast(progress.bytes),
            .kind = @intFromEnum(if (uncertain) records.SinkKind.uncertain else if (self.failed) records.SinkKind.failed else records.SinkKind.accepted),
            .error_code = progress.error_code,
        };
    }

    pub fn put(self: *Output, byte: u8) void {
        self.write(&.{byte});
    }

    pub fn number(self: *Output, value: u64) void {
        var buffer: [20]u8 = undefined;
        self.write(std.fmt.bufPrint(&buffer, "{d}", .{value}) catch unreachable);
    }

    pub fn close(self: *Output) i32 {
        var first: i32 = 0;
        for (0..3) |index| {
            if (self.io.binding(@intCast(index)).?.kind == a.launch_io_pipe) {
                const rc = self.io.close(@intCast(index));
                if (first == 0) first = rc;
            }
        }
        return first;
    }
};

test "network stream normal output preserves short handoff prefix and closed sink failure" {
    const Peer = struct {
        var bytes: [64]u8 = undefined;
        var used: usize = 0;
        var calls: u32 = 0;
        var fail_after_prefix = false;
        var now: u64 = 1_000_000_000;
        fn clock(out: *a.MonotonicClockInfo) callconv(.c) i32 {
            now += 100_000;
            out.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = 9, .instant_ns = now, .resolution_ns = 1, .event_requested_hz = 1000 };
            return 1;
        }
        fn closeContext(_: *const platform.abi.R4XStartContext2) callconv(.c) u32 {
            return 0;
        }
        fn sleep(_: u64) callconv(.c) void {}
        fn write(_: u32, input: [*]const u8, length: u32) callconv(.c) i32 {
            calls += 1;
            if (fail_after_prefix and calls > 1) return a.byte_pipe_error_stale;
            const count = @min(length, 3);
            @memcpy(bytes[used..][0..count], input[0..count]);
            used += count;
            return @intCast(count);
        }
    };
    var sys_table: platform.abi.R4XStartR4Sys2 = .{ .sleep_ticks = @intFromPtr(&Peer.sleep) };
    var desk_table: platform.abi.R4XStartR4Desk2 = .{ .console_write = @intFromPtr(&Peer.write) };
    const imports = [_]platform.abi.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys_table) },
        .{ .group_id = 2, .resolved_version = 2, .table = @intFromPtr(&desk_table) },
    };
    const raw: platform.abi.R4XStartContext2 = .{ .import_count = imports.len, .imports = @intFromPtr(&imports), .flags = a.r4xstart_flag_close_supported, .should_close = @intFromPtr(&Peer.closeContext) };
    const context = try platform.Context.init(&raw);
    for ([_]bool{ false, true }) |fail| {
        Peer.used = 0;
        Peer.calls = 0;
        Peer.fail_after_prefix = fail;
        var output: Output = .{ .io = .{ .context = &context, .snapshot = .{}, .pipes = null }, .sys = .{ .base = .{ .generation2 = &context } }, .clock = .{ .read = Peer.clock } };
        output.write("abcdefgh");
        try std.testing.expectEqual(fail, output.failed);
        try std.testing.expectEqualStrings(if (fail) "abc" else "abcdefgh", Peer.bytes[0..Peer.used]);
        if (fail) {
            try std.testing.expectEqual(@as(u64, 3), output.last.?.bytes);
            try std.testing.expectEqual(@intFromEnum(@import("stream_transfer.zig").Outcome.uncertain), output.last.?.outcome);
            const calls = Peer.calls;
            output.write("must not replay");
            try std.testing.expectEqual(calls, Peer.calls);
        }
        try std.testing.expectEqual(@as(i32, 0), output.close());

        Peer.used = 0;
        Peer.calls = 0;
        output.failed = false;
        output.last = null;
        const records = @import("diagnostic_buffer.zig");
        var storage: [64]u8 = undefined;
        var buffered = try records.BoundedDiagnosticBuffer.init(&storage);
        _ = try buffered.appendRecord("abcdefgh", .info);
        const flushed = try buffered.flushOnce(8, Output.recordSink, &output);
        try std.testing.expectEqualStrings(if (fail) "abc" else "abcdefgh", Peer.bytes[0..Peer.used]);
        try std.testing.expectEqual(@as(u64, if (fail) 5 else 0), buffered.pending_bytes);
        try std.testing.expectEqual(@as(u32, if (fail) 2 else 0), buffered.poison);
        if (fail) {
            try std.testing.expectEqual(@intFromEnum(records.FlushKind.uncertain), flushed.kind);
            try std.testing.expectEqual(@as(u32, 3), flushed.accepted_bytes);
            const calls = Peer.calls;
            const stopped = try buffered.flushOnce(8, Output.recordSink, &output);
            try std.testing.expectEqual(@intFromEnum(records.FlushKind.poisoned), stopped.kind);
            try std.testing.expectEqual(calls, Peer.calls);
        }
    }
}

test "network stream stdio malformed pipe records preserve caller outputs" {
    const Peer = struct {
        var mode: enum { version, size, flags, count } = .version;
        fn result(out: *a.BytePipeProgress, count: u64) void {
            out.* = .{ .bytes = 2, .state = a.byte_pipe_ready };
            switch (mode) {
                .version => out.version = 99,
                .size => out.size = 1,
                .flags => out.flags = 1,
                .count => out.bytes = count + 1,
            }
        }
        fn read(_: a.BytePipeEnd, bytes: [*]u8, count: u64, _: *const a.WaitSetDeadline, out: *a.BytePipeProgress) callconv(.c) i32 {
            @memcpy(bytes[0..2], "zz");
            result(out, count);
            return 0;
        }
        fn write(_: a.BytePipeEnd, _: [*]const u8, count: u64, _: *const a.WaitSetDeadline, out: *a.BytePipeProgress) callconv(.c) i32 {
            result(out, count);
            return 0;
        }
    };
    var table: platform.abi.R4XStartR4Sys2 = .{};
    const imports = [_]platform.abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&table) }};
    const raw: platform.abi.R4XStartContext2 = .{ .import_count = imports.len, .imports = @intFromPtr(&imports) };
    const context = try platform.Context.init(&raw);
    // Only these two operations are reachable in this synchronous fixture.
    var provider: pipe.Provider = undefined;
    provider.read = Peer.read;
    provider.write = Peer.write;
    const io: Stdio = .{ .context = &context, .pipes = provider, .snapshot = .{
        .stdin_binding = pipeBinding(.{ .handle = 13, .generation = 17, .direction = a.byte_pipe_reader }),
        .stdout_binding = pipeBinding(.{ .handle = 19, .generation = 23, .direction = a.byte_pipe_writer }),
    } };
    for ([_]@TypeOf(Peer.mode){ .version, .size, .flags, .count }) |mode| {
        Peer.mode = mode;
        var bytes = [_]u8{'?'} ** 3;
        const before: pipe.Progress = .{ .bytes = 99, .state = a.byte_pipe_eof };
        var progress = before;
        try std.testing.expectEqual(a.byte_pipe_error_invalid, io.readChecked(&bytes, .{}, &progress));
        try std.testing.expectEqualStrings("???", &bytes);
        try std.testing.expectEqualDeep(before, progress);
        try std.testing.expectEqual(a.byte_pipe_error_invalid, io.writeChecked(1, "abc", .{}, &progress));
        try std.testing.expectEqualDeep(before, progress);
    }
}
