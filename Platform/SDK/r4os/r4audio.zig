const abi = @import("r4os_contract").abi;
const program = @import("program.zig");

pub const name = "R4AUDIO";
pub const import_query = "R4AUDIO:Query:1";
pub const group = abi.R4LGroup.r4audio;
pub const abi_version = abi.r4l_abi_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4audio.h";
pub const query_contract = "Repositories/Contract/ABI/R4LQuery.txt";

pub const Context = struct {
    base: program.Context,

    pub fn init(bundle: *const program.Bundle) Context {
        return .{ .base = program.Context.initBundle(bundle) };
    }

    pub fn fromProgram(ctx: program.Context) Context {
        return .{ .base = ctx };
    }

    // 0.57.2: ehrliche Vertragspruefung (ersetzt supports*-Versionsgates).
    pub fn hasFn(self: *const Context, comptime field: []const u8) bool {
        return self.base.hasAudioFn(field);
    }

    pub fn audioOpenStream(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat) i32 {
        return self.base.audioOpenStream(rate, channels, format);
    }

    pub fn audioWrite(self: *const Context, stream_id: u32, data: []const u8) i32 {
        return self.base.audioWrite(stream_id, data);
    }

    pub fn audioClose(self: *const Context, stream_id: u32) i32 {
        return self.base.audioClose(stream_id);
    }

    pub fn audioSetVolume(self: *const Context, stream_id: u32, fixed_volume: u32) i32 {
        return self.base.audioSetVolume(stream_id, fixed_volume);
    }

    pub fn audioServiceStatus(self: *const Context, out: *abi.AudioServiceStatus) i32 {
        return self.base.audioServiceStatus(out);
    }

    pub fn audioServiceSetMasterVolume(self: *const Context, fixed_volume: u32, out: *abi.AudioServiceStatus) i32 {
        return self.base.audioServiceSetMasterVolume(fixed_volume, out);
    }

    pub fn audioServiceMasterState(self: *const Context, out: *abi.AudioServiceMasterState) i32 {
        return self.base.audioServiceMasterState(out);
    }

    pub fn audioServiceSetMasterState(self: *const Context, request: *const abi.AudioServiceMasterRequest, out: *abi.AudioServiceMasterState) i32 {
        return self.base.audioServiceSetMasterState(request, out);
    }

    pub fn audioServiceOpenStream(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat) i32 {
        return self.base.audioServiceOpenStream(rate, channels, format);
    }

    pub fn audioServiceOpenStreamResult(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat, fixed_volume: u32, out: *abi.AudioServiceStreamResult) i32 {
        return self.base.audioServiceOpenStreamResult(rate, channels, format, fixed_volume, out);
    }

    pub inline fn audioServiceWrite(self: *const Context, stream_id: u32, data: []const u8) i32 {
        return self.base.audioServiceWrite(stream_id, data);
    }

    pub fn audioServiceClose(self: *const Context, stream_id: u32) i32 {
        return self.base.audioServiceClose(stream_id);
    }

    pub fn audioServiceSetVolume(self: *const Context, stream_id: u32, fixed_volume: u32) i32 {
        return self.base.audioServiceSetVolume(stream_id, fixed_volume);
    }

    pub fn sidAcquire(self: *const Context) i32 {
        return self.base.sidAcquire();
    }

    pub fn sidWriteRegister(self: *const Context, handle: u32, reg: u8, value: u8) i32 {
        return self.base.sidWriteRegister(handle, reg, value);
    }

    pub fn sidRelease(self: *const Context, handle: u32) i32 {
        return self.base.sidRelease(handle);
    }

    pub fn sidLoadData(self: *const Context, handle: u32, load_addr: u16, data: []const u8) i32 {
        return self.base.sidLoadData(handle, load_addr, data);
    }

    pub fn sidInit(self: *const Context, handle: u32, init_addr: u16, song: u16) i32 {
        return self.base.sidInit(handle, init_addr, song);
    }

    pub fn sidPlayFrame(self: *const Context, handle: u32, play_addr: u16, frame_hz: u16) i32 {
        return self.base.sidPlayFrame(handle, play_addr, frame_hz);
    }

    pub fn sidStop(self: *const Context, handle: u32) i32 {
        return self.base.sidStop(handle);
    }

    pub fn sidModelName(self: *const Context) [*:0]const u8 {
        return self.base.sidModelName();
    }

    pub fn midiOpenSynth(self: *const Context, backend: [*:0]const u8) i32 {
        return self.base.midiOpenSynth(backend);
    }

    pub fn midiSend(self: *const Context, handle: u32, channel: u8, status: u8, data1: u8, data2: u8) i32 {
        return self.base.midiSend(handle, channel, status, data1, data2);
    }

    pub fn midiRender(self: *const Context, handle: u32, frames: u16) i32 {
        return self.base.midiRender(handle, frames);
    }

    pub fn midiClose(self: *const Context, handle: u32) i32 {
        return self.base.midiClose(handle);
    }

    pub fn opl3WriteRegister(self: *const Context, bank: u8, reg: u8, value: u8) i32 {
        return self.base.opl3WriteRegister(bank, reg, value);
    }

    pub fn opl3Reset(self: *const Context) i32 {
        return self.base.opl3Reset();
    }

    pub fn opl3RenderBlock(self: *const Context) i32 {
        return self.base.opl3RenderBlock();
    }

    pub fn opl3Stop(self: *const Context) i32 {
        return self.base.opl3Stop();
    }
};

test "r4audio exposes project and ABI metadata" {
    const std = @import("std");
    try std.testing.expectEqualStrings("R4AUDIO", name);
    try std.testing.expectEqualStrings("R4AUDIO:Query:1", import_query);
    try std.testing.expectEqual(@as(u32, 5), @intFromEnum(group));
    try std.testing.expectEqual(abi.r4l_abi_version, abi_version);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4audio.h", c_header);
}
