const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4audio = @import("r4audio.zig");
const r4sys = @import("r4sys.zig");
const services_facade = @import("app_services.zig");
const time_contract = @import("time_contract.zig");
const stream_reply = @import("audio_stream_reply.zig");

pub const Timeout = time_contract.Timeout;
pub const default_volume: u32 = 0x0001_0000;
pub const max_write_payload: usize = abi.service_api_max_payload - @sizeOf(abi.AudioServiceStreamWriteRequest);
pub const PcmFormat = enum(u16) { s16le = @intFromEnum(abi.AudioFormat.s16le), _ };

pub const MasterUpdate = struct {
    volume_fixed: ?u32 = null,
    muted: ?bool = null,
    expected_revision: u64 = 0,
};

pub const Result = union(enum) {
    ok,
    timed_out,
    failure: i32,
};

pub const WriteResult = union(enum) {
    written: usize,
    busy: usize,
    timed_out: usize,
    failure: struct { raw: i32, written: usize },
};

pub const WriteOutcome = enum {
    complete,
    retry,
    timed_out,
    failure,
    invalid,
};

pub const WriteAdvance = struct {
    accepted: usize = 0,
    outcome: WriteOutcome,
    raw: i32 = 0,
};

/// Tracks frame-aligned progress across interrupted stream writes. A caller
/// still decides when to retry, but can no longer lose bytes accepted before
/// Busy, timeout, or a hard failure.
pub const WriteCursor = struct {
    total: usize,
    accepted: usize = 0,
    frame_bytes: usize,

    pub fn init(total: usize, frame_bytes: usize) ?WriteCursor {
        if (frame_bytes == 0 or total == 0 or total % frame_bytes != 0) return null;
        return .{ .total = total, .frame_bytes = frame_bytes };
    }

    pub fn remaining(self: *const WriteCursor) usize {
        return self.total - self.accepted;
    }

    pub fn done(self: *const WriteCursor) bool {
        return self.accepted == self.total;
    }

    pub fn apply(self: *WriteCursor, result: WriteResult) WriteAdvance {
        if (self.done()) return invalidAdvance();
        var advance: WriteAdvance = switch (result) {
            .written => |bytes| .{ .accepted = bytes, .outcome = .complete },
            .busy => |bytes| .{ .accepted = bytes, .outcome = .retry, .raw = abi.service_api_result_busy },
            .timed_out => |bytes| .{ .accepted = bytes, .outcome = .timed_out, .raw = abi.service_api_result_timeout },
            .failure => |failure| .{ .accepted = failure.written, .outcome = .failure, .raw = failure.raw },
        };
        if (advance.accepted > self.remaining() or advance.accepted % self.frame_bytes != 0) return invalidAdvance();

        self.accepted += advance.accepted;
        if ((advance.outcome == .complete and !self.done()) or (advance.outcome == .retry and self.done())) {
            advance.outcome = .invalid;
            advance.raw = abi.service_api_result_invalid;
        }
        return advance;
    }
};

fn invalidAdvance() WriteAdvance {
    return .{ .outcome = .invalid, .raw = abi.service_api_result_invalid };
}

pub const OpenResult = union(enum) {
    stream: AudioStream,
    timed_out,
    no_service: i32,
    failure: i32,
};

pub const Audio = struct {
    sys: r4sys.Context,
    raw: r4audio.Context,

    pub fn available(self: *const Audio) bool {
        // This facade uses AUDSVC RPCs. The separate raw/advanced audio
        // operations retain their own direct table admission.
        return self.sys.hasFn("service_open") and self.sys.hasFn("service_close") and self.sys.hasFn("service_call");
    }

    pub fn openStream(self: *const Audio, rate: u32, channels: u16, format: PcmFormat, volume: u32, timeout: Timeout) OpenResult {
        if (rate == 0 or rate > 192_000 or channels == 0 or channels > 2 or format != .s16le) return .{ .failure = abi.service_api_result_invalid };
        var services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open("AUDSVC")) {
            .connection => |value| value,
            .failure => |raw| return .{ .no_service = raw },
        };
        const request = abi.AudioServiceStreamOpenRequest{
            .rate = rate,
            .channels = channels,
            .format = @intFromEnum(format),
            .fixed_volume = volume,
        };
        const called = connection.callTyped(abi.AudioServiceStreamOpenRequest, abi.AudioServiceStreamResult, abi.audio_service_op_open_stream, &request, timeout);
        return switch (called) {
            .value => |response| blk: {
                const valid = validResponse(&response, abi.audio_service_op_open_stream, 0, 0, 0);
                if (!valid or response.result < 0) {
                    _ = connection.close();
                    break :blk .{ .failure = if (valid) response.result else abi.service_api_result_invalid };
                }
                break :blk .{ .stream = .{ .connection = connection, .stream_id = response.stream_id, .owned = true, .frame_bytes = @as(usize, channels) * 2 } };
            },
            .timed_out => blk: {
                _ = connection.close();
                break :blk .timed_out;
            },
            .remote_failure => |raw| blk: {
                _ = connection.close();
                break :blk .{ .failure = raw };
            },
            .failure => |raw| blk: {
                _ = connection.close();
                break :blk .{ .failure = raw };
            },
        };
    }

    pub fn status(self: *const Audio, timeout: Timeout, out: *abi.AudioServiceStatus) Result {
        var services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open("AUDSVC")) {
            .connection => |value| value,
            .failure => |raw| return .{ .failure = raw },
        };
        defer _ = connection.close();
        return switch (connection.call(abi.audio_service_op_status, "", std.mem.asBytes(out), timeout)) {
            .response => |response| if (response.bytes == @sizeOf(abi.AudioServiceStatus) and out.magic == abi.audio_service_status_magic and out.version == abi.audio_service_status_version) .ok else .{ .failure = abi.service_api_result_invalid },
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .failure = raw },
            .failure => |raw| .{ .failure = raw },
        };
    }

    pub fn masterState(self: *const Audio, timeout: Timeout, out: *abi.AudioServiceMasterState) Result {
        return self.callMaster(abi.audio_service_op_master_status, "", timeout, out);
    }

    pub fn outputs(self: *const Audio, request: *const abi.AudioServiceOutputRequest, timeout: Timeout, out: *abi.AudioServiceOutputState) Result {
        return self.callOutputs(abi.audio_service_op_outputs, request, timeout, out);
    }

    pub fn selectOutput(self: *const Audio, request: *const abi.AudioServiceOutputRequest, timeout: Timeout, out: *abi.AudioServiceOutputState) Result {
        return self.callOutputs(abi.audio_service_op_select_output, request, timeout, out);
    }

    fn callOutputs(self: *const Audio, op: u16, request: *const abi.AudioServiceOutputRequest, timeout: Timeout, out: *abi.AudioServiceOutputState) Result {
        var services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open("AUDSVC")) {
            .connection => |value| value,
            .failure => |raw| return .{ .failure = raw },
        };
        defer _ = connection.close();
        return switch (connection.call(op, std.mem.asBytes(request), std.mem.asBytes(out), timeout)) {
            .response => |response| if (response.bytes == @sizeOf(abi.AudioServiceOutputState) and
                out.magic == abi.audio_output_control_magic and out.version == 1 and out.size == @sizeOf(abi.AudioServiceOutputState) and
                out.count <= out.outputs.len and out.total <= 256 and out.index <= 256 and out.count <= out.total -| out.index)
                .ok
            else
                .{ .failure = abi.service_api_result_invalid },
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .failure = raw },
            .failure => |raw| .{ .failure = raw },
        };
    }

    pub fn setMasterState(self: *const Audio, update: MasterUpdate, timeout: Timeout, out: *abi.AudioServiceMasterState) Result {
        if (update.volume_fixed == null and update.muted == null) return .{ .failure = abi.service_api_result_invalid };
        var request = abi.AudioServiceMasterRequest{ .expected_revision = update.expected_revision };
        if (update.volume_fixed) |volume| {
            request.flags |= abi.audio_master_request_flag_set_volume;
            request.fixed_volume = volume;
        }
        if (update.muted) |muted| {
            request.flags |= abi.audio_master_request_flag_set_muted;
            if (muted) request.flags |= abi.audio_master_request_flag_muted;
        }
        return self.callMaster(abi.audio_service_op_set_master_state, std.mem.asBytes(&request), timeout, out);
    }

    fn callMaster(self: *const Audio, op: u16, payload: []const u8, timeout: Timeout, out: *abi.AudioServiceMasterState) Result {
        var services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open("AUDSVC")) {
            .connection => |value| value,
            .failure => |raw| return .{ .failure = raw },
        };
        defer _ = connection.close();
        return switch (connection.call(op, payload, std.mem.asBytes(out), timeout)) {
            .response => |response| if (response.bytes == @sizeOf(abi.AudioServiceMasterState) and
                out.magic == abi.audio_master_state_magic and
                out.version == abi.audio_master_state_version and
                out.size == @sizeOf(abi.AudioServiceMasterState)) .ok else .{ .failure = abi.service_api_result_invalid },
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .failure = raw },
            .failure => |raw| .{ .failure = raw },
        };
    }

    pub fn advanced(self: *const Audio) AdvancedAudio {
        return .{ .raw = self.raw };
    }
};

pub const AudioStream = struct {
    connection: services_facade.ServiceConnection,
    stream_id: u32 = 0,
    owned: bool = false,
    frame_bytes: usize = 0,

    pub fn valid(self: *const AudioStream) bool {
        return self.owned and self.stream_id != 0 and self.connection.valid();
    }

    pub fn write(self: *AudioStream, data: []const u8, timeout: Timeout) WriteResult {
        return self.writeBounded(data, timeout, std.math.maxInt(u32));
    }

    /// One service call at most, including short successful writes. Event-loop
    /// producers retain the reported prefix and retry the remainder later.
    pub fn writeOnce(self: *AudioStream, data: []const u8, timeout: Timeout) WriteResult {
        return self.writeBounded(data, timeout, 1);
    }

    fn writeBounded(self: *AudioStream, data: []const u8, timeout: Timeout, max_calls: u32) WriteResult {
        if (!self.valid()) return .{ .failure = .{ .raw = abi.err_closed, .written = 0 } };
        if (self.frame_bytes == 0 or data.len % self.frame_bytes != 0)
            return .{ .failure = .{ .raw = abi.service_api_result_invalid, .written = 0 } };
        var offset: usize = 0;
        var calls: u32 = 0;
        if (data.len == 0) return .{ .written = 0 };
        var operation = self.connection.budget(timeout) catch |err| return .{ .failure = .{ .raw = @import("rpc_budget.zig").code(err), .written = 0 } };
        while (offset < data.len) {
            if (calls == max_calls) return .{ .busy = offset };
            calls += 1;
            // Keep room for the header: an inferred u12 wraps 4096 to zero.
            const chunk_len: usize = @min(max_write_payload, data.len - offset);
            var payload: [abi.service_api_max_payload]u8 = undefined;
            const request = abi.AudioServiceStreamWriteRequest{ .stream_id = self.stream_id, .byte_count = @intCast(chunk_len) };
            @memcpy(payload[0..@sizeOf(abi.AudioServiceStreamWriteRequest)], std.mem.asBytes(&request));
            @memcpy(payload[@sizeOf(abi.AudioServiceStreamWriteRequest)..][0..chunk_len], data[offset..][0..chunk_len]);
            var response: abi.AudioServiceStreamResult = .{};
            const called = self.connection.callBudget(abi.audio_service_op_write_stream, payload[0 .. @sizeOf(abi.AudioServiceStreamWriteRequest) + chunk_len], std.mem.asBytes(&response), &operation);
            switch (called) {
                .response => |meta| {
                    if (meta.bytes != @sizeOf(abi.AudioServiceStreamResult) or !validResponse(&response, abi.audio_service_op_write_stream, self.stream_id, @intCast(chunk_len), self.frame_bytes)) {
                        return .{ .failure = .{ .raw = abi.service_api_result_invalid, .written = offset } };
                    }
                    if (response.result == abi.service_api_result_busy) return .{ .busy = offset };
                    if (response.result < 0) {
                        return .{ .failure = .{ .raw = response.result, .written = offset } };
                    }
                    const advanced: usize = @intCast(response.bytes);
                    offset += advanced;
                },
                .timed_out => return .{ .timed_out = offset },
                .remote_failure => |raw| return .{ .failure = .{ .raw = raw, .written = offset } },
                .failure => |raw| return .{ .failure = .{ .raw = raw, .written = offset } },
            }
        }
        return .{ .written = offset };
    }

    pub fn setVolume(self: *AudioStream, fixed_volume: u32, timeout: Timeout) Result {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const request = abi.AudioServiceStreamControlRequest{ .stream_id = self.stream_id, .fixed_volume = fixed_volume };
        return self.control(abi.audio_service_op_set_stream_volume, &request, timeout, false);
    }

    pub fn close(self: *AudioStream, timeout: Timeout) Result {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const request = abi.AudioServiceStreamControlRequest{ .stream_id = self.stream_id };
        return self.control(abi.audio_service_op_close_stream, &request, timeout, true);
    }

    fn control(self: *AudioStream, op: u16, request: *const abi.AudioServiceStreamControlRequest, timeout: Timeout, closes: bool) Result {
        const called = self.connection.callTyped(abi.AudioServiceStreamControlRequest, abi.AudioServiceStreamResult, op, request, timeout);
        return switch (called) {
            .value => |response| blk: {
                if (!validResponse(&response, op, self.stream_id, 0, 0)) break :blk .{ .failure = abi.service_api_result_invalid };
                if (response.result < 0) break :blk .{ .failure = response.result };
                if (closes) {
                    self.stream_id = 0;
                    self.owned = false;
                    self.frame_bytes = 0;
                    _ = self.connection.close();
                }
                break :blk .ok;
            },
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .failure = raw },
            .failure => |raw| .{ .failure = raw },
        };
    }
};

pub const AdvancedAudio = struct {
    raw: r4audio.Context,

    pub fn sidAcquire(self: *const AdvancedAudio) i32 {
        return self.raw.sidAcquire();
    }
    pub fn sidWriteRegister(self: *const AdvancedAudio, handle: u32, reg: u8, value: u8) i32 {
        return self.raw.sidWriteRegister(handle, reg, value);
    }
    pub fn sidRelease(self: *const AdvancedAudio, handle: u32) i32 {
        return self.raw.sidRelease(handle);
    }
    pub fn sidLoadData(self: *const AdvancedAudio, handle: u32, load_addr: u16, data: []const u8) i32 {
        return self.raw.sidLoadData(handle, load_addr, data);
    }
    pub fn sidInit(self: *const AdvancedAudio, handle: u32, init_addr: u16, song: u16) i32 {
        return self.raw.sidInit(handle, init_addr, song);
    }
    pub fn sidPlayFrame(self: *const AdvancedAudio, handle: u32, play_addr: u16, frame_hz: u16) i32 {
        return self.raw.sidPlayFrame(handle, play_addr, frame_hz);
    }
    pub fn sidStop(self: *const AdvancedAudio, handle: u32) i32 {
        return self.raw.sidStop(handle);
    }
    pub fn sidModelName(self: *const AdvancedAudio) [*:0]const u8 {
        return self.raw.sidModelName();
    }
    pub fn midiOpenSynth(self: *const AdvancedAudio, backend: [*:0]const u8) i32 {
        return self.raw.midiOpenSynth(backend);
    }
    pub fn midiSend(self: *const AdvancedAudio, handle: u32, channel: u8, status: u8, data1: u8, data2: u8) i32 {
        return self.raw.midiSend(handle, channel, status, data1, data2);
    }
    pub fn midiRender(self: *const AdvancedAudio, handle: u32, frames: u16) i32 {
        return self.raw.midiRender(handle, frames);
    }
    pub fn midiClose(self: *const AdvancedAudio, handle: u32) i32 {
        return self.raw.midiClose(handle);
    }
    pub fn opl3WriteRegister(self: *const AdvancedAudio, bank: u8, reg: u8, value: u8) i32 {
        return self.raw.opl3WriteRegister(bank, reg, value);
    }
    pub fn opl3Reset(self: *const AdvancedAudio) i32 {
        return self.raw.opl3Reset();
    }
    pub fn opl3RenderBlock(self: *const AdvancedAudio) i32 {
        return self.raw.opl3RenderBlock();
    }
    pub fn opl3Stop(self: *const AdvancedAudio) i32 {
        return self.raw.opl3Stop();
    }
};

fn validResponse(response: *const abi.AudioServiceStreamResult, action: u16, stream_id: u32, maximum_bytes: u32, frame_bytes: u64) bool {
    return stream_reply.validate(std.mem.asBytes(response), action, stream_id, maximum_bytes, frame_bytes);
}

test "write cursor preserves partial progress and never converts errors into success" {
    var cursor = WriteCursor.init(8192, 4) orelse return error.InvalidCursor;
    const busy = cursor.apply(.{ .busy = 4076 });
    try std.testing.expectEqual(@as(usize, 4076), busy.accepted);
    try std.testing.expectEqual(WriteOutcome.retry, busy.outcome);
    try std.testing.expectEqual(@as(usize, 4116), cursor.remaining());

    const complete = cursor.apply(.{ .written = 4116 });
    try std.testing.expectEqual(WriteOutcome.complete, complete.outcome);
    try std.testing.expect(cursor.done());

    var short_cursor = WriteCursor.init(4096, 4) orelse return error.InvalidCursor;
    const short = short_cursor.apply(.{ .written = 2048 });
    try std.testing.expectEqual(@as(usize, 2048), short.accepted);
    try std.testing.expectEqual(WriteOutcome.invalid, short.outcome);
    try std.testing.expect(!short_cursor.done());

    var failed_cursor = WriteCursor.init(4096, 4) orelse return error.InvalidCursor;
    const failed = failed_cursor.apply(.{ .failure = .{ .raw = -77, .written = 2048 } });
    try std.testing.expectEqual(@as(usize, 2048), failed.accepted);
    try std.testing.expectEqual(WriteOutcome.failure, failed.outcome);
    try std.testing.expectEqual(@as(i32, -77), failed.raw);
    try std.testing.expect(!failed_cursor.done());

    var terminal_cursor = WriteCursor.init(4096, 4) orelse return error.InvalidCursor;
    const terminal = terminal_cursor.apply(.{ .failure = .{ .raw = -88, .written = 4096 } });
    try std.testing.expectEqual(WriteOutcome.failure, terminal.outcome);
    try std.testing.expect(terminal_cursor.done());

    var timeout_cursor = WriteCursor.init(4096, 4) orelse return error.InvalidCursor;
    const timed_out = timeout_cursor.apply(.{ .timed_out = 1024 });
    try std.testing.expectEqual(@as(usize, 1024), timed_out.accepted);
    try std.testing.expectEqual(WriteOutcome.timed_out, timed_out.outcome);
    try std.testing.expect(!timeout_cursor.done());

    var invalid_cursor = WriteCursor.init(4096, 4) orelse return error.InvalidCursor;
    const invalid = invalid_cursor.apply(.{ .busy = 1 });
    try std.testing.expectEqual(WriteOutcome.invalid, invalid.outcome);
    try std.testing.expectEqual(@as(usize, 0), invalid_cursor.accepted);
}

test "packet limits keep the complete header and PCM in both audio writers" {
    const program = @import("program.zig");
    const Capture = struct {
        var expected: []const u8 = &.{};
        var accepted: usize = 0;
        var calls: usize = 0;
        var largest: usize = 0;
        var next_limit: ?usize = null;
        var fail_call: usize = 0;
        var report_extra: bool = false;
        fn open(_: [*:0]const u8, out: *abi.ServiceInfo) callconv(.c) i32 {
            out.* = .{ .handle = 1 };
            return 0;
        }
        fn close(_: u32) callconv(.c) i32 {
            return 0;
        }
        fn clock(out: *abi.MonotonicClockInfo) callconv(.c) i32 {
            out.* = .{ .flags = abi.monotonic_clock_flag_valid, .source = 1, .generation = 1, .frequency_hz = abi.monotonic_clock_frequency_hz, .resolution_ns = 1, .instant_ns = 1_000_000_000, .event_requested_hz = 1000, .event_effective_hz = 1001 };
            return 1;
        }
        fn call(_: u32, op: u16, bytes: [*]const u8, len: u32, header: *abi.ServiceMessageHeader, response: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
            const header_size = @sizeOf(abi.AudioServiceStreamWriteRequest);
            if (op != abi.audio_service_op_write_stream or len < header_size or capacity < @sizeOf(abi.AudioServiceStreamResult)) return -1;
            const request = std.mem.bytesToValue(abi.AudioServiceStreamWriteRequest, bytes[0..header_size]);
            const data = bytes[header_size..len];
            if (request.magic != abi.audio_service_request_magic or request.version != abi.audio_service_request_version or
                request.stream_id != 7 or request.byte_count != data.len or data.len > expected.len - accepted or
                !std.mem.eql(u8, data, expected[accepted..][0..data.len])) return -1;
            calls += 1;
            largest = @max(largest, len);
            const failed = calls == fail_call;
            const count = if (failed) 0 else @min(data.len, next_limit orelse data.len);
            next_limit = null;
            accepted += count;
            const result = abi.AudioServiceStreamResult{
                .action = op,
                .result = if (failed) abi.service_api_result_busy else @intCast(count),
                .stream_id = 7,
                .bytes = @intCast(if (report_extra) data.len + 1 else count),
            };
            @memcpy(response[0..@sizeOf(@TypeOf(result))], std.mem.asBytes(&result));
            header.* = .{ .op = op, .status = 0, .payload_len = @sizeOf(@TypeOf(result)) };
            return @sizeOf(@TypeOf(result));
        }
    };
    var raw: @import("r4os_contract2").R4XStartContext2 = .{};
    var table: @import("r4os_contract2").R4XStartR4Sys2 = .{};
    table.service_open = @intFromPtr(&Capture.open);
    table.service_close = @intFromPtr(&Capture.close);
    table.service_call = @intFromPtr(&Capture.call);
    table.monotonic_clock = @intFromPtr(&Capture.clock);
    var bundle: program.Bundle = .{ .raw = &raw, .sys = &table };
    const sys = r4sys.Context.init(&bundle);
    var data: [max_write_payload + 4]u8 = undefined;
    for (&data, 0..) |*byte, i| byte.* = @truncate(i * 137 + 19);
    Capture.expected = data[0..1024];
    Capture.accepted = 0;
    Capture.calls = 0;
    Capture.largest = 0;
    try std.testing.expectEqual(@as(i32, 1024), sys.audioServiceWrite(7, data[0..1024]));
    try std.testing.expectEqual(@as(usize, 2), Capture.calls);
    try std.testing.expectEqual(@as(usize, 1024), Capture.largest);

    // A short reply commits exactly its prefix; the next call must begin with
    // the first unaccepted sample, even when the request spans several packets.
    Capture.expected = data[0..2008];
    Capture.accepted = 0;
    Capture.calls = 0;
    Capture.next_limit = 400;
    try std.testing.expectEqual(@as(i32, 400), sys.audioServiceWrite(7, Capture.expected));
    try std.testing.expectEqual(@as(usize, 1), Capture.calls);
    try std.testing.expectEqual(@as(i32, 1608), sys.audioServiceWrite(7, Capture.expected[400..]));
    try std.testing.expectEqual(Capture.expected.len, Capture.accepted);

    Capture.accepted = 0;
    Capture.calls = 0;
    Capture.fail_call = 2;
    try std.testing.expectEqual(@as(i32, 1004), sys.audioServiceWrite(7, Capture.expected));
    try std.testing.expectEqual(@as(usize, 1004), Capture.accepted);
    Capture.fail_call = 0;
    try std.testing.expectEqual(@as(i32, 1004), sys.audioServiceWrite(7, Capture.expected[1004..]));
    try std.testing.expectEqual(Capture.expected.len, Capture.accepted);

    Capture.accepted = 0;
    Capture.calls = 0;
    Capture.fail_call = 1;
    try std.testing.expectEqual(abi.service_api_result_busy, sys.audioServiceWrite(7, Capture.expected));
    try std.testing.expectEqual(@as(usize, 0), Capture.accepted);
    Capture.fail_call = 0;
    Capture.next_limit = 0;
    try std.testing.expectEqual(@as(i32, 0), sys.audioServiceWrite(7, Capture.expected));
    try std.testing.expectEqual(@as(usize, 2), Capture.calls);
    Capture.report_extra = true;
    try std.testing.expectEqual(abi.service_api_result_invalid, sys.audioServiceWrite(7, Capture.expected));
    Capture.report_extra = false;

    Capture.expected = &data;
    Capture.accepted = 0;
    Capture.calls = 0;
    Capture.largest = 0;
    var stream = AudioStream{ .connection = .{ .sys = sys, .raw = 1 }, .stream_id = 7, .owned = true, .frame_bytes = 4 };
    const result = stream.write(&data, .{ .kind = abi.timeout_kind_forever });
    try std.testing.expectEqual(data.len, result.written);
    try std.testing.expectEqual(@as(usize, 2), Capture.calls);
    try std.testing.expectEqual(@as(usize, abi.service_api_max_payload), Capture.largest);
}
