//! Explicit total-budget AUDSVC writes over the existing transfer owner.
const std = @import("std");
pub const abi = @import("r4os_contract").abi;
const audio = @import("app_audio.zig");
const services = @import("app_services.zig");
const replies = @import("audio_stream_reply.zig");
pub const transfer = @import("stream_transfer.zig");
pub const budget = @import("time_budget.zig");
pub const wire = @import("binary_cursor.zig");
pub const invalid: i32 = -301;
pub const invalid_buffer: i32 = -302;
pub const invalid_frame: i32 = -303;
pub const stream_closed: i32 = -304;
fn overlaps(a: wire.Span, address: usize, length: usize) bool {
    return a.length != 0 and a.address < address + length and address < a.address + a.length;
}
pub fn errorCode(err: transfer.Error) i32 {
    return switch (err) {
        error.InvalidState => -1,
        error.InvalidMode => -2,
        error.InvalidBuffer => -3,
        error.InvalidLimit => -4,
        error.Busy => -5,
        error.LengthOverflow => -6,
        error.ClockUnavailable => -101,
        error.ClockChanged => -102,
        error.ClockRegressed => -103,
        error.InvalidBudget => -104,
        error.UnknownFrequency => -105,
        error.BudgetOverflow => -106,
        error.InvalidTimeout => -107,
    };
}
fn ack(kind: transfer.IoKind, code: i32) transfer.Ack {
    return .{ .kind = @intFromEnum(kind), .error_code = code };
}
pub const Provider = extern struct {
    legacy: ?*audio.AudioStream = null,
    call: ?abi.R4SysFns.service_call = null,
    monotonic: ?abi.R4SysFns.monotonic_clock = null,
    service_handle: u32 = 0,
    stream_id: u32 = 0,
    frame_bytes: u32 = 0,
    reserved0: u32 = 0,
    pub fn fromStream(stream: *audio.AudioStream) Provider {
        return .{ .legacy = stream, .frame_bytes = std.math.cast(u32, stream.frame_bytes) orelse 0 };
    }
    fn shape(self: *const Provider) i32 {
        if (self.reserved0 != 0 or self.frame_bytes != 2 and self.frame_bytes != 4) return invalid_frame;
        if (self.legacy != null) {
            if (self.call != null or self.monotonic != null or self.service_handle != 0 or self.stream_id != 0) return invalid;
        } else {
            if (self.call == null or self.monotonic == null) return abi.err_no_fn;
            if (self.service_handle == 0 or self.stream_id == 0) return stream_closed;
        }
        return 0;
    }
    pub fn clock(raw: ?*anyopaque, out: *budget.ClockSample) callconv(.c) i32 {
        const self: *const Provider = @ptrCast(@alignCast(raw orelse return invalid));
        var info: abi.MonotonicClockInfo = .{};
        if (self.legacy) |stream| {
            const rc = stream.connection.sys.monotonicClock(&info);
            if (rc <= 0) return if (rc < 0) rc else -101;
        } else {
            const read = self.monotonic orelse return abi.err_no_fn;
            const rc = read(&info);
            if (rc <= 0) return if (rc < 0) rc else -101;
        }
        out.* = budget.ClockSample.fromInfo(info) catch return -101;
        return 0;
    }
};
pub const Progress = extern struct {
    io: transfer.Progress,
    accepted_frames: u64,
    last_frames: u32,
    frame_bytes: u32,
    last_service_flags: u32,
    service_flags_valid: u32,
};
pub const Writer = extern struct {
    io: transfer.Transfer,
    source: wire.Span,
    provider: Provider,
    last_service_flags: u32 = 0,
    service_flags_valid: u32 = 0,

    pub fn init(source: wire.Span, input: Provider, timeout: abi.R4Timeout, out: *Writer) i32 {
        source.validate() catch return invalid_buffer;
        if (overlaps(source, @intFromPtr(out), @sizeOf(Writer))) return invalid_buffer;
        var provider = input;
        if (provider.legacy) |stream| {
            if (provider.frame_bytes == 0) provider.frame_bytes = std.math.cast(u32, stream.frame_bytes) orelse return invalid_frame;
        }
        const checked = provider.shape();
        if (checked != 0) return checked;
        if (source.length % provider.frame_bytes != 0) return invalid_frame;
        if (provider.legacy) |stream| {
            if (overlaps(source, @intFromPtr(stream), @sizeOf(audio.AudioStream)) or
                overlaps(.{ .address = @intFromPtr(out), .length = @sizeOf(Writer) }, @intFromPtr(stream), @sizeOf(audio.AudioStream))) return invalid_buffer;
            if (!stream.valid() or stream.frame_bytes != provider.frame_bytes) return stream_closed;
            if (!stream.connection.sys.hasFn("monotonic_clock") or !stream.connection.sys.hasFn("service_call")) return abi.err_no_fn;
        }
        var copy = provider;
        var initial: budget.ClockSample = .{};
        const rc = Provider.clock(&copy, &initial);
        if (rc != 0) return rc;
        const value = transfer.Transfer.init(.write_all, source.length, initial, timeout) catch |err| return errorCode(err);
        out.* = .{ .io = value, .source = source, .provider = provider };
        return 0;
    }
    fn check(self: *const Writer) i32 {
        self.source.validate() catch return invalid_buffer;
        const rc = self.provider.shape();
        if (rc != 0) return rc;
        const p = self.io.progress() catch |err| return errorCode(err);
        if (p.total != self.source.length or self.io.mode != @intFromEnum(transfer.Mode.write_all) or
            p.bytes % self.provider.frame_bytes != 0 or p.last_bytes % self.provider.frame_bytes != 0 or self.service_flags_valid > 1) return invalid;
        return 0;
    }
    pub fn progress(self: *const Writer, out: *Progress) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        const p = self.io.progress() catch |err| return errorCode(err);
        out.* = .{ .io = p, .accepted_frames = p.bytes / self.provider.frame_bytes, .last_frames = p.last_bytes / self.provider.frame_bytes, .frame_bytes = self.provider.frame_bytes, .last_service_flags = self.last_service_flags, .service_flags_valid = self.service_flags_valid };
        return 0;
    }
    /// No callback retains this ephemeral context. State is movable between
    /// calls; an actual legacy stream and source stay borrowed until return.
    fn clock(raw: ?*anyopaque, out: *budget.ClockSample) callconv(.c) i32 {
        const self: *Writer = @ptrCast(@alignCast(raw orelse return invalid));
        return Provider.clock(&self.provider, out);
    }
    fn write(raw: ?*anyopaque, _: u64, data: [*]const u8, length: u32, absolute: *const budget.DeadlineBudget) callconv(.c) transfer.Ack {
        const self: *Writer = @ptrCast(@alignCast(raw orelse return ack(.failed, invalid)));
        var sample: budget.ClockSample = .{};
        const sampled = Provider.clock(&self.provider, &sample);
        if (sampled != 0) return ack(.failed, sampled);
        var deadline = absolute.*;
        const remaining = deadline.remaining(sample) catch |err| return ack(.failed, errorCode(err));
        self.io.deadline.last_ns = deadline.last_ns;
        if (self.io.cancel_requested != 0) return ack(.failed, 0);
        if (absolute.kind == 1 and remaining.kind == 0) return ack(.timed_out, abi.service_api_result_timeout);
        if (remaining.kind == 1 and sample.identity.tick_hz == 0) return ack(.failed, -105);
        const ticks: u64 = if (remaining.kind == 0) 0 else if (remaining.kind == 2) abi.io_wait_forever else budget.scaleCeil(remaining.value, sample.identity.tick_hz, abi.nanoseconds_per_second) catch |err| return ack(.failed, errorCode(err));
        if (remaining.kind == 1 and (ticks == 0 or ticks == abi.io_wait_forever)) return ack(.failed, -106);
        const stream_id = if (self.provider.legacy) |stream| stream.stream_id else self.provider.stream_id;
        if (self.provider.legacy) |stream| if (!stream.valid() or stream.frame_bytes != self.provider.frame_bytes) return ack(.closed, abi.err_closed);
        if (length == 0 or length > audio.max_write_payload or length % self.provider.frame_bytes != 0) return ack(.failed, invalid_frame);
        var payload: [abi.service_api_max_payload]u8 = undefined;
        var request: abi.AudioServiceStreamWriteRequest = .{ .stream_id = stream_id, .byte_count = length };
        const header_bytes = @sizeOf(abi.AudioServiceStreamWriteRequest);
        @memcpy(payload[0..header_bytes], std.mem.asBytes(&request));
        @memcpy(payload[header_bytes..][0..length], data[0..length]);
        var response: abi.AudioServiceStreamResult = .{};
        var header: abi.ServiceMessageHeader = .{};
        var got: usize = 0;
        if (self.provider.legacy) |stream| {
            switch (services.callWithTicks(&stream.connection, abi.audio_service_op_write_stream, payload[0 .. header_bytes + length], std.mem.asBytes(&response), ticks)) {
                .response => |value| {
                    header = value.header;
                    got = value.bytes;
                },
                .timed_out => return ack(.uncertain, abi.service_api_result_timeout),
                .remote_failure, .failure => |code| return ack(.uncertain, code),
            }
        } else {
            const called = self.provider.call.?(self.provider.service_handle, abi.audio_service_op_write_stream, &payload, @intCast(header_bytes + length), &header, @ptrCast(&response), @sizeOf(abi.AudioServiceStreamResult), ticks);
            if (called < 0) return ack(.uncertain, called);
            got = @intCast(called);
        }
        if (got != @sizeOf(abi.AudioServiceStreamResult) or header.magic != abi.service_api_magic or header.version != abi.service_api_version or
            header.op != abi.audio_service_op_write_stream or header.payload_len != got or header.status != abi.service_api_result_ok or
            !replies.validate(std.mem.asBytes(&response), abi.audio_service_op_write_stream, stream_id, length, self.provider.frame_bytes)) return ack(.uncertain, abi.service_api_result_invalid);
        self.last_service_flags = response.flags;
        self.service_flags_valid = 1;
        if (response.result == abi.service_api_result_busy) return ack(.would_block, response.result);
        if (response.result < 0) return ack(.failed, response.result);
        return .{ .bytes = response.bytes };
    }
    pub fn writeOnce(self: *Writer, stop: bool, out: *Progress) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        const bytes = self.source.bytes() catch return invalid_buffer;
        const offset: usize = @intCast(self.io.bytes);
        const maximum: u32 = @intCast(audio.max_write_payload - audio.max_write_payload % self.provider.frame_bytes);
        _ = self.io.writeStep(bytes[offset..], maximum, stop, clock, self, write, self) catch |err| return errorCode(err);
        return self.progress(out);
    }
    pub fn writeBounded(self: *Writer, calls: u32, stop: bool, out: *Progress) i32 {
        if (calls == 0 or calls > 64) return -4;
        for (0..calls) |_| {
            const rc = self.writeOnce(stop, out);
            if (rc != 0) return rc;
            if (out.io.outcome != @intFromEnum(transfer.Outcome.pending) or out.io.flags & transfer.terminal != 0) return 0;
        }
        return 0;
    }
    pub fn cancel(self: *Writer, out: *Progress) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        _ = self.io.cancel() catch |err| return errorCode(err);
        return self.progress(out);
    }
};
