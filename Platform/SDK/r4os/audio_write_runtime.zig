//! Static C/Rust ABI over the same writer and rational source-time owner.
const audio = @import("audio_write.zig");
const pcm = @import("pcm_source.zig");
const abi = audio.abi;
const clock = audio.budget;
comptime {
    if (@sizeOf(audio.Provider) != 40 or @sizeOf(audio.Progress) != 56 or @sizeOf(audio.Writer) != 152 or
        @sizeOf(pcm.Pacer) != 72 or @sizeOf(pcm.SourceDeadline) != 64) @compileError("Audio writer/source C ABI drift");
}
pub export fn R4SdkAudioWriterInit(source: audio.wire.Span, provider: audio.Provider, timeout: abi.R4Timeout, out: ?*audio.Writer) callconv(.c) i32 {
    return audio.Writer.init(source, provider, timeout, out orelse return audio.invalid);
}
pub export fn R4SdkAudioWriterGetProgress(raw: ?*const audio.Writer, out: ?*audio.Progress) callconv(.c) i32 {
    return (raw orelse return audio.invalid).progress(out orelse return audio.invalid);
}
pub export fn R4SdkAudioWriterStep(raw: ?*audio.Writer, calls: u32, stop: u32, out: ?*audio.Progress) callconv(.c) i32 {
    if (stop > 1) return audio.invalid;
    return (raw orelse return audio.invalid).writeBounded(calls, stop != 0, out orelse return audio.invalid);
}
pub export fn R4SdkAudioWriterCancel(raw: ?*audio.Writer, out: ?*audio.Progress) callconv(.c) i32 {
    return (raw orelse return audio.invalid).cancel(out orelse return audio.invalid);
}
fn code(err: pcm.Error) i32 {
    return switch (err) {
        error.InvalidState => -301,
        error.InvalidRate => -305,
        error.InvalidFrame => -303,
        error.Paused => -306,
        else => |other| audio.errorCode(other),
    };
}
pub export fn R4SdkPcmSourceInit(rate: u32, frame_bytes: u32, lead: u64, sample: clock.ClockSample, out: ?*pcm.Pacer) callconv(.c) i32 {
    const target = out orelse return audio.invalid;
    target.* = pcm.Pacer.init(rate, frame_bytes, lead, sample) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkPcmSourceAccepted(raw: ?*pcm.Pacer, bytes: u64, sample: clock.ClockSample, out: ?*pcm.SourceDeadline) callconv(.c) i32 {
    const state = raw orelse return audio.invalid;
    const target = out orelse return audio.invalid;
    target.* = state.accepted(bytes, sample) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkPcmSourceGetDeadline(raw: ?*pcm.Pacer, sample: clock.ClockSample, finish: u32, out: ?*pcm.SourceDeadline) callconv(.c) i32 {
    if (finish > 1) return audio.invalid;
    const state = raw orelse return audio.invalid;
    const target = out orelse return audio.invalid;
    target.* = state.deadline(sample, finish != 0) catch |err| return code(err);
    return 0;
}
pub export fn R4SdkPcmSourcePause(raw: ?*pcm.Pacer, sample: clock.ClockSample, resume_source: u32) callconv(.c) i32 {
    const state = raw orelse return audio.invalid;
    if (resume_source > 1) return audio.invalid;
    if (resume_source == 0) state.pause(sample) catch |err| return code(err) else state.resumeSource(sample) catch |err| return code(err);
    return 0;
}
