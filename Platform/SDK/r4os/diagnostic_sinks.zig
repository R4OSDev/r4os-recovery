//! Synchronous adapters over resolved canonical owner callbacks. No hidden
//! fallback, retry, allocation or implicit newline. Provider/path/context
//! loans outlive each call; LogSink additionally owns a pending close handle.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const diag = @import("diagnostic_buffer.zig");
const budget = @import("time_budget.zig");

pub const invalid: i32 = -10001;
pub const whole_record_required: i32 = -10002;
pub const close_pending: i32 = -10003;
fn failed(code: i32) diag.Ack {
    return .{ .kind = @intFromEnum(diag.SinkKind.failed), .error_code = code };
}
fn streamAck(got: i32, offered: u32) diag.Ack {
    // Negative legacy writes do not prove that no external byte was accepted.
    if (got < 0) return .{ .kind = @intFromEnum(diag.SinkKind.uncertain), .error_code = got };
    const count: u32 = @intCast(got);
    if (count > offered) return .{ .accepted_bytes = count }; // core poisons invalid acknowledgement
    return .{ .accepted_bytes = count, .kind = if (count == 0 and offered != 0) @intFromEnum(diag.SinkKind.would_block) else @intFromEnum(diag.SinkKind.accepted) };
}
pub const ConsoleSink = extern struct {
    write: ?abi.R4DeskFns.console_write = null,
    stream: u32 = 1,
    reserved: u32 = 0,
    pub fn send(raw: ?*anyopaque, chunk: *const diag.Chunk) callconv(.c) diag.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return failed(invalid)));
        if (self.reserved != 0 or (self.stream != 1 and self.stream != 2)) return failed(invalid);
        const write = self.write orelse return failed(abi.err_no_fn);
        return streamAck(write(self.stream, chunk.data, chunk.length), chunk.length);
    }
    pub fn fromContext2(context: *const @import("platform2.zig").Context, stream: u32) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var address: u64 = 0;
        if (context.lookup(2, @offsetOf(a.R4XStartR4Desk2, "console_write"), &address) != 0) return error.NoProvider;
        return .{ .write = @ptrFromInt(address), .stream = stream };
    }
};
pub const FileSink = extern struct {
    append: ?abi.R4SysFns.file_append = null,
    path: ?[*:0]const u8 = null,
    pub fn send(raw: ?*anyopaque, chunk: *const diag.Chunk) callconv(.c) diag.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return failed(invalid)));
        const append = self.append orelse return failed(abi.err_no_fn);
        const path = self.path orelse return failed(invalid);
        return streamAck(append(path, chunk.data, chunk.length), chunk.length);
    }
    pub fn fromContext2(context: *const @import("platform2.zig").Context, path: [*:0]const u8) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var address: u64 = 0;
        if (context.lookup(1, @offsetOf(a.R4XStartR4Sys2, "file_append"), &address) != 0) return error.NoProvider;
        return .{ .append = @ptrFromInt(address), .path = path };
    }
};
pub const LogSink = extern struct {
    open: ?abi.R4SysFns.service_open = null,
    call: ?abi.R4SysFns.service_call = null,
    close: ?abi.R4SysFns.service_close = null,
    origin: ?[*]const u8 = null,
    origin_length: usize = 0,
    /// Tagged logical ticks, prepared with the actual logical tick frequency.
    /// Poll or finite 1..MAX-1 only; raw MAX means forever in the old RPC owner.
    call_ticks: budget.Value = .{},
    active_handle: u32 = 0,
    last_close_error: i32 = 0,
    busy: u32 = 0,
    reserved: u32 = 0,
    pub fn closePending(self: *@This()) i32 {
        if (self.busy != 0) return abi.service_api_result_busy;
        if (self.active_handle == 0) return 0;
        const close = self.close orelse return abi.err_no_fn;
        self.busy = 1;
        const rc = close(self.active_handle);
        self.busy = 0;
        self.last_close_error = rc;
        if (rc == 0 or rc == abi.service_api_result_bad_handle) {
            self.active_handle = 0;
            return 0;
        }
        return rc;
    }
    pub fn send(raw: ?*anyopaque, chunk: *const diag.Chunk) callconv(.c) diag.Ack {
        const self: *@This() = @ptrCast(@alignCast(raw orelse return failed(invalid)));
        if (self.busy != 0) return failed(abi.service_api_result_busy);
        if (self.active_handle != 0) return failed(close_pending);
        if (self.reserved != 0 or self.call_ticks.reserved != 0 or !((self.call_ticks.kind == 0 and self.call_ticks.value == 0) or (self.call_ticks.kind == 1 and self.call_ticks.value > 0 and self.call_ticks.value < std.math.maxInt(u64)))) return failed(invalid);
        if (chunk.offset != 0 or chunk.length != chunk.total) return failed(whole_record_required);
        if (chunk.length >= abi.log_service_text_bytes or chunk.severity > 3 or self.origin_length == 0 or self.origin_length >= abi.log_service_origin_bytes) return failed(invalid);
        const origin = (self.origin orelse return failed(invalid))[0..self.origin_length];
        const text = chunk.data[0..chunk.length];
        if (!std.unicode.utf8ValidateSlice(origin) or !std.unicode.utf8ValidateSlice(text) or std.mem.indexOfScalar(u8, origin, 0) != null or std.mem.indexOfScalar(u8, text, 0) != null) return failed(invalid);
        const open = self.open orelse return failed(abi.err_no_fn);
        const call = self.call orelse return failed(abi.err_no_fn);
        _ = self.close orelse return failed(abi.err_no_fn);
        self.busy = 1;
        var info: abi.ServiceInfo = .{};
        const opened = open(abi.log_r4x_service_name, &info);
        if (opened != 0 or info.handle == 0) {
            self.busy = 0;
            // Preserve any real returned handle even for a malformed provider.
            self.active_handle = info.handle;
            return failed(if (opened != 0) opened else abi.service_api_result_no_endpoint);
        }
        self.active_handle = info.handle;
        var request: abi.LogServiceWriteRequest = .{ .severity = @intCast(chunk.severity), .text_len = @intCast(text.len), .origin_len = @intCast(origin.len) };
        @memcpy(request.text[0..text.len], text);
        @memcpy(request.origin[0..origin.len], origin);
        var header: abi.ServiceMessageHeader = .{};
        var response: abi.LogServiceStatus = .{};
        // Clear magic/version so a provider that writes nothing cannot pass.
        response.magic = 0;
        response.version = 0;
        const got = call(info.handle, abi.log_service_op_write, @ptrCast(&request), @sizeOf(@TypeOf(request)), &header, @ptrCast(&response), @sizeOf(@TypeOf(response)), self.call_ticks.value);
        const expected_header: abi.ServiceMessageHeader = .{};
        const confirmed = got == @sizeOf(abi.LogServiceStatus) and header.magic == expected_header.magic and header.version == expected_header.version and header.op == abi.log_service_op_write and header.payload_len == @sizeOf(abi.LogServiceStatus) and header.status == 0 and response.magic == abi.log_service_status_magic and response.version == abi.log_service_version;
        const call_error: i32 = if (got < 0) got else if (header.status < 0) header.status else invalid;
        self.busy = 0;
        const closed = self.closePending();
        if (!confirmed) return .{ .kind = @intFromEnum(diag.SinkKind.uncertain), .error_code = call_error };
        return .{ .accepted_bytes = chunk.length, .kind = if (closed == 0) @intFromEnum(diag.SinkKind.accepted) else @intFromEnum(diag.SinkKind.failed), .error_code = closed };
    }
    pub fn fromContext2(context: *const @import("platform2.zig").Context, origin: []const u8, call_ticks: budget.Value) error{NoProvider}!@This() {
        const a = @import("r4os_contract2");
        var addresses: [3]u64 = undefined;
        inline for (.{ "service_open", "service_call", "service_close" }, 0..) |name, i| {
            if (context.lookup(1, @offsetOf(a.R4XStartR4Sys2, name), &addresses[i]) != 0) return error.NoProvider;
        }
        return .{ .open = @ptrFromInt(addresses[0]), .call = @ptrFromInt(addresses[1]), .close = @ptrFromInt(addresses[2]), .origin = origin.ptr, .origin_length = origin.len, .call_ticks = call_ticks };
    }
};

test "cli owner real sink callback contracts preserve partial failure unknown commit and pending close" {
    const P = struct {
        var writes: u32 = 0;
        var closes: u32 = 0;
        var timeout: bool = false;
        fn console(stream: u32, _: [*]const u8, len: u32) callconv(.c) i32 {
            return if (stream == 1 and len > 1) 1 else -8;
        }
        fn append(_: [*:0]const u8, _: [*]const u8, _: u32) callconv(.c) i32 {
            return -8;
        }
        fn open(_: [*:0]const u8, out: *abi.ServiceInfo) callconv(.c) i32 {
            out.* = .{ .handle = 7 };
            return 0;
        }
        fn close(_: u32) callconv(.c) i32 {
            closes += 1;
            return if (closes == 1) abi.service_api_result_busy else 0;
        }
        fn call(_: u32, op: u16, data: [*]const u8, len: u32, header: *abi.ServiceMessageHeader, out: [*]u8, capacity: u32, ticks: u64) callconv(.c) i32 {
            const request: *align(1) const abi.LogServiceWriteRequest = @ptrCast(data);
            if (op != abi.log_service_op_write or len != @sizeOf(abi.LogServiceWriteRequest) or capacity != @sizeOf(abi.LogServiceStatus) or ticks != 2 or request.text_len != 3 or request.origin_len != 1 or !std.mem.eql(u8, request.text[0..3], "€")) return -99;
            writes += 1; // just like the real owner: commit precedes reply
            if (timeout) return -10;
            var status: abi.LogServiceStatus = .{};
            @memcpy(out[0..@sizeOf(abi.LogServiceStatus)], std.mem.asBytes(&status));
            header.* = .{ .op = op, .payload_len = @sizeOf(abi.LogServiceStatus) };
            return @sizeOf(abi.LogServiceStatus);
        }
    };
    var bytes: [32]u8 = undefined;
    var queue = try diag.BoundedDiagnosticBuffer.init(&bytes);
    _ = try queue.appendRecord("€", .info);
    var console: ConsoleSink = .{ .write = P.console };
    try std.testing.expectEqual(@as(u32, 1), (try queue.flushOnce(8, ConsoleSink.send, &console)).accepted_bytes);
    var file: FileSink = .{ .append = P.append, .path = "C:\\X.TXT" };
    try std.testing.expectEqual(@intFromEnum(diag.FlushKind.uncertain), (try queue.flushOnce(8, FileSink.send, &file)).kind);
    _ = try queue.discard();
    _ = try queue.appendRecord("€", .warning);
    var log: LogSink = .{ .open = P.open, .call = P.call, .close = P.close, .origin = "X", .origin_length = 1, .call_ticks = .{ .kind = 1, .value = 2 } };
    try std.testing.expectEqual(@intFromEnum(diag.FlushKind.failed), (try queue.flushOnce(1, LogSink.send, &log)).kind);
    try std.testing.expectEqual(@as(u32, 0), P.writes);
    const confirmed = try queue.flushOnce(8, LogSink.send, &log);
    try std.testing.expectEqual(@as(u32, 1), confirmed.completed_records);
    try std.testing.expectEqual(@intFromEnum(diag.FlushKind.failed), confirmed.kind);
    try std.testing.expectEqual(@as(u32, 7), log.active_handle);
    _ = try queue.appendRecord("€", .info);
    try std.testing.expectEqual(close_pending, (try queue.flushOnce(8, LogSink.send, &log)).error_code);
    try std.testing.expectEqual(@as(i32, 0), log.closePending());
    P.timeout = true;
    try std.testing.expectEqual(@intFromEnum(diag.FlushKind.uncertain), (try queue.flushOnce(8, LogSink.send, &log)).kind);
    _ = try queue.flushOnce(8, LogSink.send, &log);
    try std.testing.expectEqual(@as(u32, 2), P.writes);
    try std.testing.expectEqual(@as(u32, 0), log.active_handle);
    _ = try queue.discard();
    _ = try queue.appendRecord("a\x00b", .info);
    try std.testing.expectEqual(invalid, (try queue.flushOnce(8, LogSink.send, &log)).error_code);
    try std.testing.expectEqual(@as(u32, 2), P.writes);
}
