//! Stateless AUDSVC reply validation shared by the SDK's stream facades.
const std = @import("std");
const abi = @import("r4os_contract").abi;

/// A valid negative reply acknowledges no PCM. Invalid replies establish
/// neither stream ownership nor a new accepted prefix; callers keep both.
pub fn validate(bytes: []const u8, action: u16, stream_id: u32, maximum_bytes: u32, frame_bytes: u64) bool {
    if (bytes.len != @sizeOf(abi.AudioServiceStreamResult)) return false;
    var reply: abi.AudioServiceStreamResult = undefined;
    @memcpy(std.mem.asBytes(&reply), bytes);
    if (reply.magic != abi.audio_service_result_magic or reply.version != abi.audio_service_result_version or reply.action != action) return false;
    if (action == abi.audio_service_op_open_stream) {
        if (reply.bytes != 0) return false;
        return if (reply.result < 0)
            reply.stream_id == 0
        else
            reply.result > 0 and reply.stream_id == @as(u32, @intCast(reply.result));
    }
    if (stream_id == 0 or reply.stream_id != stream_id) return false;
    if (action != abi.audio_service_op_write_stream and action != abi.audio_service_op_set_stream_volume and action != abi.audio_service_op_close_stream) return false;
    if (reply.result < 0) return reply.bytes == 0;
    if (action == abi.audio_service_op_write_stream) {
        return reply.bytes != 0 and reply.bytes <= maximum_bytes and frame_bytes != 0 and
            reply.bytes % frame_bytes == 0 and reply.result == reply.bytes;
    }
    return reply.result == 0 and reply.bytes == 0;
}
