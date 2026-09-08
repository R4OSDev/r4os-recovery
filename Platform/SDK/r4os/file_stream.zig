const abi = @import("r4os_contract").abi;

pub const WriterState = struct {
    path: [*:0]const u8,
    offset: u64 = 0,
    chunks: u32 = 0,
    max_chunk: u32 = 0,
    active: bool = false,
    error_code: i32 = abi.file_stream_result_ok,
};

pub const CopyResult = struct {
    ok: bool = false,
    bytes: u64 = 0,
    chunks: u32 = 0,
    max_chunk: u32 = 0,
    source_size: u64 = 0,
    error_code: i32 = abi.file_stream_result_ok,
};

pub fn begin(sys: anytype, state: *WriterState, path: [*:0]const u8, flags: u32) bool {
    state.* = .{ .path = path };
    const rc = sys.fileStreamBegin(path, flags);
    state.error_code = rc;
    state.active = rc == abi.file_stream_result_ok;
    return state.active;
}

pub fn write(sys: anytype, state: *WriterState, data: []const u8) bool {
    if (!state.active) return false;
    if (data.len > 0xFFFF_FFFF) {
        state.error_code = abi.file_stream_error_too_large;
        state.active = false;
        return false;
    }

    const rc = sys.fileStreamWrite(state.path, state.offset, data, 0);
    if (rc < 0 or @as(usize, @intCast(rc)) != data.len) {
        state.error_code = if (rc < 0) rc else abi.file_stream_error_io;
        state.active = false;
        return false;
    }

    const chunk_len: u32 = @intCast(data.len);
    state.offset += @intCast(chunk_len);
    state.chunks += 1;
    if (chunk_len > state.max_chunk) state.max_chunk = chunk_len;
    return true;
}

pub fn finish(sys: anytype, state: *WriterState) bool {
    if (!state.active) return false;
    const rc = sys.fileStreamFinish(state.path, state.offset, 0);
    state.error_code = rc;
    state.active = false;
    return rc == abi.file_stream_result_ok;
}

pub fn abort(sys: anytype, state: *WriterState) i32 {
    const rc = sys.fileStreamAbort(state.path);
    state.error_code = rc;
    state.active = false;
    return rc;
}

/// Keep identity lookup and every copy chunk in one provider request. A
/// provider without this optional operation returns unavailable; a sequence
/// of separately gated truncate/read calls cannot safely emulate it.
pub fn copy(sys: anytype, src_path: [*:0]const u8, dst_path: [*:0]const u8, buffer: []u8) CopyResult {
    if (buffer.len == 0 or buffer.len > 0xFFFF_FFFF) return .{ .error_code = abi.file_stream_error_invalid };
    var progress: abi.FileCopyProgress = .{};
    const result = sys.fileCopyBuffered(src_path, dst_path, buffer, &progress);
    return .{
        .ok = result == abi.file_stream_result_ok,
        .bytes = progress.bytes,
        .chunks = progress.chunks,
        .max_chunk = progress.max_chunk,
        .source_size = progress.source_size,
        .error_code = result,
    };
}
