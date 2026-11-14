//! Explicit copied AUDSVC capture transport; no hardware or queue owner here.
const std = @import("std");
pub const abi = @import("r4os_contract").abi;
const platform = @import("platform2.zig");
const time = @import("time_budget.zig");
pub const Source = abi.AudioCaptureSourceId;
pub const Format = abi.AudioCaptureFormat;
pub const Handle = abi.AudioCaptureHandle;
pub const Reply = abi.AudioCaptureReply;
/// Infrastructure adapter over the original admitted immutable audio table.
/// AUDSVC owns client queues/policy; normal clients use Client below.
pub const Backend = struct {
    audio: *const @import("r4audio.zig").Context,
    pub fn io(self: *Backend, input: *const abi.AudioCaptureRequest, out: *abi.AudioCaptureReply, bytes: []u8) i32 {
        if (bytes.len > abi.audio_capture_max_read_bytes) return abi.audio_capture_error_capacity;
        if (self.audio.base.generation2) |context| {
            var address: u64 = 0;
            if (context.lookup(5, @offsetOf(platform.abi.R4XStartR4Audio2, "audio_capture_io"), &address) != 0) {
                out.* = .{ .result = abi.audio_capture_error_unsupported };
                return 0;
            }
            const invoke: abi.R4AudioFns.audio_capture_io = @ptrFromInt(address);
            return invoke(input, out, bytes.ptr, @intCast(bytes.len));
        }
        if (!self.audio.hasFn("audio_capture_io")) {
            out.* = .{ .result = abi.audio_capture_error_unsupported };
            return 0;
        }
        // hasFn is the existing sole size/null gate. Context/table/code are
        // borrowed immutable through actual return, so this slot stays valid.
        const table = self.audio.base.bundle.?.audio.?;
        const invoke: abi.R4AudioFns.audio_capture_io = @ptrFromInt(table.audio_capture_io);
        return invoke(input, out, bytes.ptr, @intCast(bytes.len));
    }
};

test "capture backend selects actual2 callbacks without a legacy bundle and preserves missing-prefix and legacy results" {
    const t = std.testing;
    const Audio = @import("r4audio.zig");
    const program = @import("program.zig");
    const P = struct {
        var calls: u32 = 0;
        fn invoke(request: *const abi.AudioCaptureRequest, out: *Reply, bytes: [*]u8, capacity: u32) callconv(.c) i32 {
            if (request.op != abi.audio_capture_op_read or capacity != 4) return -99;
            calls += 1;
            bytes[0] = 0x52;
            out.* = .{};
            return 17;
        }
    };
    var raw2: platform.abi.R4XStartContext2 = .{};
    var table2: platform.abi.R4XStartR4Audio2 = .{};
    table2.audio_capture_io = @intFromPtr(&P.invoke);
    var actual = platform.Context{ .raw = &raw2, .tables = .{ 0, 0, 0, 0, @intFromPtr(&table2), 0 } };
    const audio2 = Audio.Context.fromProgram(.{ .generation2 = &actual });
    try t.expect(audio2.base.bundle == null);
    var backend = Backend{ .audio = &audio2 };
    const request: abi.AudioCaptureRequest = .{ .op = abi.audio_capture_op_read, .buffer_bytes = 4 };
    var reply: Reply = .{};
    var bytes: [4]u8 = @splat(0xA5);
    P.calls = 0;
    try t.expectEqual(@as(i32, 17), backend.io(&request, &reply, &bytes));
    try t.expectEqualSlices(u8, &.{ 0x52, 0xA5, 0xA5, 0xA5 }, &bytes);
    table2.size = @offsetOf(platform.abi.R4XStartR4Audio2, "audio_capture_io");
    try t.expectEqual(@as(i32, 0), backend.io(&request, &reply, &bytes));
    try t.expectEqual(abi.audio_capture_error_unsupported, reply.result);
    try t.expectEqual(@as(u32, 1), P.calls);
    table2.size = @sizeOf(platform.abi.R4XStartR4Audio2);
    table2.audio_capture_io = 0;
    try t.expectEqual(@as(i32, 0), backend.io(&request, &reply, &bytes));
    try t.expectEqual(abi.audio_capture_error_unsupported, reply.result);
    var raw1: @import("r4os_contract2").R4XStartContext2 = .{};
    var table1: @import("r4os_contract2").R4XStartR4Audio2 = .{};
    table1.audio_capture_io = @intFromPtr(&P.invoke);
    const bundle = program.Bundle{ .raw = &raw1, .audio = &table1 };
    const audio1 = Audio.Context.init(&bundle);
    backend.audio = &audio1;
    try t.expectEqual(@as(i32, 17), backend.io(&request, &reply, &bytes));
    try t.expectEqual(@as(u32, 2), P.calls);
    const both = Audio.Context.fromProgram(.{ .bundle = &bundle, .generation2 = &actual });
    backend.audio = &both;
    actual.tables[4] = 0;
    try t.expectEqual(@as(i32, 0), backend.io(&request, &reply, &bytes));
    try t.expectEqual(abi.audio_capture_error_unsupported, reply.result);
    try t.expectEqual(@as(u32, 2), P.calls);
    var oversized: [abi.audio_capture_max_read_bytes + 1]u8 = @splat(0xA5);
    const before = reply;
    try t.expectEqual(abi.audio_capture_error_capacity, backend.io(&request, &reply, &oversized));
    try t.expect(std.meta.eql(before, reply));
}
pub const Client = struct {
    call: abi.R4SysFns.service_call,
    close_call: abi.R4SysFns.service_close,
    clock: abi.R4SysFns.monotonic_clock,
    channel: u32,
    client_generation: u64,
    transport_ticks: u64,
    pub fn connect(context: *const platform.Context, transport_ticks: u64, out: *Client) i32 {
        if (transport_ticks == 0 or context.raw.instance_id == 0 or context.raw.instance_id > std.math.maxInt(u32)) return abi.audio_capture_error_invalid;
        const table = context.system();
        const open_fn = platform.abi.function(platform.abi.R4SysFns2, table, "service_open") orelse return abi.audio_capture_error_unsupported;
        const call = platform.abi.function(platform.abi.R4SysFns2, table, "service_call") orelse return abi.audio_capture_error_unsupported;
        const close_call = platform.abi.function(platform.abi.R4SysFns2, table, "service_close") orelse return abi.audio_capture_error_unsupported;
        const clock = platform.abi.function(platform.abi.R4SysFns2, table, "monotonic_clock") orelse return abi.audio_capture_error_unsupported;
        const process = platform.abi.function(platform.abi.R4SysFns2, table, "program_open_handle") orelse return abi.audio_capture_error_unsupported;
        var identity: abi.ProgramProcessHandle = .{};
        if (process(@intCast(context.raw.instance_id), &identity) != abi.program_handle_ok or identity.generation == 0 or identity.instance_id != context.raw.instance_id or identity.reserved != 0) return abi.audio_capture_error_stale;
        var endpoint: abi.ServiceInfo = .{};
        const rc = open_fn("AUDSVC", &endpoint);
        if (rc != 0) return rc;
        if (endpoint.handle == 0) return abi.audio_capture_error_unsupported;
        out.* = .{ .call = call, .close_call = close_call, .clock = clock, .channel = endpoint.handle, .client_generation = identity.generation, .transport_ticks = transport_ticks };
        return 0;
    }
    /// Closes only the copied service channel. Stream Stop/Close remains explicit.
    pub fn disconnect(self: *Client) i32 {
        if (self.channel == 0) return abi.audio_capture_error_stale;
        const rc = self.close_call(self.channel);
        if (rc >= 0) self.channel = 0;
        return rc;
    }
    pub fn sample(self: *const Client, out: *time.ClockSample) i32 {
        var info: abi.MonotonicClockInfo = .{};
        if (self.clock(&info) <= 0) return abi.audio_capture_error_clock_changed;
        out.* = time.ClockSample.fromInfo(info) catch return abi.audio_capture_error_clock_changed;
        return 0;
    }
    pub fn request(self: *const Client, input: abi.AudioCaptureRequest, bytes: []u8, out: *Reply, ticks: u64) i32 {
        if (self.channel == 0 or ticks == 0 or bytes.len > abi.audio_capture_max_read_bytes) return abi.audio_capture_error_invalid;
        var q = input;
        q.client_generation = self.client_generation;
        q.buffer_bytes = if (q.op == abi.audio_capture_op_read) @intCast(bytes.len) else 0;
        var payload: [@sizeOf(Reply) + abi.audio_capture_max_read_bytes]u8 = undefined;
        var header: abi.ServiceMessageHeader = .{};
        const rc = self.call(self.channel, abi.audio_capture_op_service, @ptrCast(&q), @sizeOf(abi.AudioCaptureRequest), &header, &payload, @intCast(payload.len), ticks);
        if (rc < 0) return if (q.op == abi.audio_capture_op_catalog or q.op == abi.audio_capture_op_query) rc else abi.audio_capture_error_unknown_outcome;
        if (header.status == abi.service_api_result_bad_op) return abi.audio_capture_error_unsupported;
        if (header.status != 0) return if (header.status < 0) header.status else abi.audio_capture_error_invalid;
        if (rc < @sizeOf(Reply)) return abi.audio_capture_error_provider;
        const r = std.mem.bytesToValue(Reply, payload[0..@sizeOf(Reply)]);
        if (r.version != 1 or r.size != @sizeOf(Reply) or r.reserved != 0 or r.result > 0 or r.flags & ~@as(u32, 31) != 0 or r.bytes > bytes.len or @as(u64, r.bytes) + @sizeOf(Reply) != @as(u64, @intCast(rc)) or (r.result < 0 and (r.bytes != 0 or r.frames != 0))) return abi.audio_capture_error_provider;
        if (r.bytes > 0 and (q.op != abi.audio_capture_op_read or r.format.frame_bytes == 0 or r.frames > q.frames or @as(u64, r.frames) * r.format.frame_bytes != r.bytes)) return abi.audio_capture_error_provider;
        if (q.op >= abi.audio_capture_op_read and !std.meta.eql(q.handle, r.handle)) return abi.audio_capture_error_stale;
        if (r.flags & abi.audio_capture_reply_hardware_timestamp == 0 and r.first_timestamp != 0) return abi.audio_capture_error_provider;
        @memcpy(bytes[0..r.bytes], payload[@sizeOf(Reply)..][0..r.bytes]);
        out.* = r;
        return r.result;
    }
    pub fn catalog(self: *const Client, index: u64, out: *Reply) i32 {
        return self.request(.{ .op = abi.audio_capture_op_catalog, .handle = .{ .source = .{ .source = index } } }, &.{}, out, self.transport_ticks);
    }
    pub fn open(self: *const Client, source: Source, format: Format, queue_frames: u32, out: *Reply) i32 {
        return self.request(.{ .op = abi.audio_capture_op_open, .handle = .{ .source = source }, .format = format, .queue_frames = queue_frames }, &.{}, out, self.transport_ticks);
    }
    pub fn query(self: *const Client, id: Handle, out: *Reply) i32 {
        return self.request(.{ .op = abi.audio_capture_op_query, .handle = id }, &.{}, out, self.transport_ticks);
    }
    pub fn stop(self: *const Client, id: Handle, out: *Reply) i32 {
        return self.request(.{ .op = abi.audio_capture_op_stop, .handle = id }, &.{}, out, self.transport_ticks);
    }
    pub fn close(self: *const Client, id: Handle, out: *Reply) i32 {
        return self.request(.{ .op = abi.audio_capture_op_close, .handle = id }, &.{}, out, self.transport_ticks);
    }
    pub fn readPoll(self: *const Client, id: Handle, frames: u32, bytes: []u8, out: *Reply) i32 {
        return self.request(.{ .op = abi.audio_capture_op_read, .handle = id, .frames = frames }, bytes, out, self.transport_ticks);
    }
};
/// Caller pumps steps and waits outside GUI/text/IRQ locks. A cancelled or
/// expired read retains the stream and performs no implicit Stop/Close/Drop.
pub const Read = struct {
    id: Handle,
    budget: time.DeadlineBudget,
    mode: u32,
    cancelled: bool = false,
    done: bool = false,
    pub fn init(id: Handle, sample: time.ClockSample, timeout: abi.R4Timeout, out: *Read) i32 {
        const value = time.fromTimeout(timeout) catch return abi.audio_capture_error_invalid;
        const budget = time.DeadlineBudget.init(sample, timeout) catch return abi.audio_capture_error_clock_changed;
        out.* = .{ .id = id, .budget = budget, .mode = value.kind };
        return 0;
    }
    pub fn cancel(self: *Read) void {
        self.cancelled = true;
    }
    pub fn step(self: *Read, client: *const Client, frames: u32, bytes: []u8, out: *Reply) i32 {
        if (self.cancelled) {
            self.done = true;
            return abi.audio_capture_error_cancelled;
        }
        if (self.done) return abi.audio_capture_error_stale;
        var sample: time.ClockSample = undefined;
        const observed = client.sample(&sample);
        if (observed != 0) {
            self.done = true;
            return observed;
        }
        const remaining = self.budget.remaining(sample) catch {
            self.done = true;
            return abi.audio_capture_error_clock_changed;
        };
        if (self.mode == 1 and remaining.kind == 0) {
            self.done = true;
            return abi.audio_capture_error_timed_out;
        }
        const ticks = if (remaining.kind == 1) @min(client.transport_ticks, time.durationToTicks(.{ .nanoseconds = remaining.value }, sample.identity.tick_hz) catch {
            self.done = true;
            return abi.audio_capture_error_clock_changed;
        }) else client.transport_ticks;
        const rc = client.request(.{ .op = abi.audio_capture_op_read, .handle = self.id, .frames = frames }, bytes, out, @max(ticks, 1));
        if (rc != abi.audio_capture_error_would_block or self.mode == 0) self.done = true;
        return rc;
    }
};
