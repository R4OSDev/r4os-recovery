const abi = @import("r4os_contract").abi;
const program = @import("program.zig");

pub const name = "R4DESK";
pub const import_query = "R4DESK:Query:1";
pub const group = abi.R4LGroup.r4desk;
pub const abi_version = abi.r4l_abi_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4desk.h";
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
        return self.base.hasDeskFn(field);
    }

    pub fn readKey(self: *const Context) u8 {
        return self.base.readKey();
    }

    pub fn readKeyCodepoint(self: *const Context) u32 {
        return self.base.readKeyCodepoint();
    }

    pub fn mouseState(self: *const Context, out: *abi.Mouse) void {
        self.base.mouseState(out);
    }

    pub fn mouseShow(self: *const Context) void {
        self.base.mouseShow();
    }

    pub fn mouseHide(self: *const Context) void {
        self.base.mouseHide();
    }

    pub fn keyboardLayoutCurrent(self: *const Context, out: *abi.KeyboardLayoutInfo) i32 {
        return self.base.keyboardLayoutCurrent(out);
    }

    pub fn keyboardLayoutAt(self: *const Context, index: u32, out: *abi.KeyboardLayoutInfo) i32 {
        return self.base.keyboardLayoutAt(index, out);
    }

    pub fn keyboardLayoutSet(self: *const Context, name_value: [*:0]const u8) i32 {
        return self.base.keyboardLayoutSet(name_value);
    }

    pub fn programSetWindow(self: *const Context, instance_id: u32, window_id: i32) i32 {
        return self.base.programSetWindow(instance_id, window_id);
    }

    pub fn programSetWindowHandle(self: *const Context, handle: *const abi.ProgramProcessHandle, window_id: i32) i32 {
        return self.base.programSetWindowHandle(handle, window_id);
    }

    pub fn programSetConsoleHost(self: *const Context, instance_id: u32, host: abi.ConsoleHostKind) i32 {
        return self.base.programSetConsoleHost(instance_id, host);
    }

    pub fn programSpawnWithConsoleHost(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind) i32 {
        return self.base.programSpawnWithConsoleHost(path, args, policy, host);
    }

    pub fn programSpawnWithConsoleHostHandle(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind, out_handle: *abi.ProgramProcessHandle) i32 {
        return self.base.programSpawnWithConsoleHostHandle(path, args, policy, host, out_handle);
    }

    pub fn programRequestHostLaunch(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        return self.base.programRequestHostLaunch(path, args, policy);
    }

    pub fn programTakeHostLaunch(self: *const Context, instance_id: u32, out: *abi.ProgramHostLaunchRequest) i32 {
        return self.base.programTakeHostLaunch(instance_id, out);
    }

    pub fn programWindowId(self: *const Context) i32 {
        return self.base.programWindowId();
    }

    pub fn guiWindowInfo(self: *const Context, out: *abi.GuiWindowInfo) i32 {
        return self.base.guiWindowInfo(out);
    }

    pub fn guiSetWindowInfo(self: *const Context, instance_id: u32, info: *const abi.GuiWindowInfo) i32 {
        return self.base.guiSetWindowInfo(instance_id, info);
    }

    pub fn guiPollEvent(self: *const Context, out: *abi.GuiEvent) i32 {
        return self.base.guiPollEvent(out);
    }

    pub fn guiPushEvent(self: *const Context, instance_id: u32, event: *const abi.GuiEvent) i32 {
        return self.base.guiPushEvent(instance_id, event);
    }

    pub fn guiSetText(self: *const Context, value: [*:0]const u8) i32 {
        return self.base.guiSetText(value);
    }

    pub fn guiText(self: *const Context, instance_id: u32, out: []u8) i32 {
        return self.base.guiText(instance_id, out);
    }

    pub fn guiRevision(self: *const Context, instance_id: u32) u32 {
        return self.base.guiRevision(instance_id);
    }

    pub fn guiCommand(self: *const Context, instance_id: u32, index: u32, out: *abi.GuiCommand) i32 {
        return self.base.guiCommand(instance_id, index, out);
    }

    pub fn guiSetTitle(self: *const Context, value: [*:0]const u8) i32 {
        return self.base.guiSetTitle(value);
    }

    pub fn guiTitle(self: *const Context, instance_id: u32, out: []u8) i32 {
        return self.base.guiTitle(instance_id, out);
    }

    pub fn guiSetMinSize(self: *const Context, w: i32, h: i32) i32 {
        return self.base.guiSetMinSize(w, h);
    }

    pub fn guiMinSize(self: *const Context, instance_id: u32, out: *abi.GuiSize) i32 {
        return self.base.guiMinSize(instance_id, out);
    }

    pub fn consoleOutput(self: *const Context, instance_id: u32, out: []u8) i32 {
        return self.base.consoleOutput(instance_id, out);
    }

    pub fn consoleRevision(self: *const Context, instance_id: u32) u32 {
        return self.base.consoleRevision(instance_id);
    }

    pub fn consoleState(self: *const Context, instance_id: u32, out: *abi.ConsoleState) i32 {
        return self.base.consoleState(instance_id, out);
    }

    pub fn consoleSetMetrics(self: *const Context, instance_id: u32, cols: u32, rows: u32) i32 {
        return self.base.consoleSetMetrics(instance_id, cols, rows);
    }

    pub fn consolePushKey(self: *const Context, instance_id: u32, key: u8) i32 {
        return self.base.consolePushKey(instance_id, key);
    }

    pub fn consolePushInput(self: *const Context, instance_id: u32, data: []const u8) i32 {
        return self.base.consolePushInput(instance_id, data);
    }

    pub fn consoleWrite(self: *const Context, stream: abi.ConsoleStream, data: []const u8) i32 {
        return self.base.consoleWrite(stream, data);
    }

    pub fn stdout(self: *const Context, data: []const u8) i32 {
        return self.consoleWrite(.stdout, data);
    }

    pub fn stderr(self: *const Context, data: []const u8) i32 {
        return self.consoleWrite(.stderr, data);
    }

    pub fn consoleRead(self: *const Context, out: []u8) i32 {
        return self.base.consoleRead(out);
    }

    pub fn consoleInputWait(self: *const Context, last_generation: u64, timeout_ticks: u64, out_generation: *u64) i32 {
        return self.base.consoleInputWait(last_generation, timeout_ticks, out_generation);
    }

    pub fn physicalKeyPoll(self: *const Context, out: *abi.PhysicalKeyEvent) i32 {
        return self.base.physicalKeyPoll(out);
    }

    pub fn clipboardWrite(self: *const Context, data: []const u8) i32 {
        return self.base.clipboardWrite(data);
    }

    pub fn clipboardRead(self: *const Context, out: []u8) i32 {
        return self.base.clipboardRead(out);
    }

    pub fn clipboardRevision(self: *const Context) u32 {
        return self.base.clipboardRevision();
    }

    pub fn clipboardInfo(self: *const Context, out: *abi.ClipboardInfo) i32 {
        return self.base.clipboardInfo(out);
    }

    pub fn clipboardClear(self: *const Context) i32 {
        return self.base.clipboardClear();
    }

    pub fn supportsRemoteFrame(self: *const Context) bool {
        return self.base.supportsRemoteFrame();
    }

    pub fn remoteFrameInfo(self: *const Context, out: *abi.RemoteFrameInfo) i32 {
        return self.base.remoteFrameInfo(out);
    }

    pub fn remoteFrameRead(self: *const Context, offset_pixels: u32, out: []u32, out_info: *abi.RemoteFrameInfo) i32 {
        return self.base.remoteFrameRead(offset_pixels, out, out_info);
    }

    pub fn remoteFrameWait(self: *const Context, last_revision: u32, timeout_ticks: u64, out: *abi.RemoteFrameInfo) i32 {
        return self.base.remoteFrameWait(last_revision, timeout_ticks, out);
    }

    pub fn desktopActivityWait(self: *const Context, last_seq: u64, timeout_ticks: u64, out_seq: *u64) i32 {
        return self.base.desktopActivityWait(last_seq, timeout_ticks, out_seq);
    }

    pub fn supportsRemoteFrameMap(self: *const Context) bool {
        return self.base.supportsRemoteFrameMap();
    }

    pub fn remoteFrameMap(self: *const Context, out: *abi.RemoteFrameMapInfo) i32 {
        return self.base.remoteFrameMap(out);
    }

    pub fn remoteFramePublish(self: *const Context, info: *const abi.RemoteFrameInfo, pixels: []const u32) i32 {
        return self.base.remoteFramePublish(info, pixels);
    }

    pub fn supportsRemoteFrameRegions(self: *const Context) bool {
        return self.base.supportsRemoteFrameRegions();
    }

    pub fn remoteFramePublishRegions(self: *const Context, info: *const abi.RemoteFrameInfo, pixels: []const u32, regions: []const abi.DisplayDamageRect) i32 {
        return self.base.remoteFramePublishRegions(info, pixels, regions);
    }

    pub fn supportsRemoteFrameDemand(self: *const Context) bool {
        return self.base.supportsRemoteFrameDemand();
    }

    pub fn remoteFrameAcquire(self: *const Context) i32 {
        return self.base.remoteFrameAcquire();
    }

    pub fn remoteFrameRelease(self: *const Context) i32 {
        return self.base.remoteFrameRelease();
    }

    pub fn remoteFrameConsumers(self: *const Context) u32 {
        return self.base.remoteFrameConsumers();
    }

    pub fn supportsRemoteInput(self: *const Context) bool {
        return self.base.supportsRemoteInput();
    }

    pub fn remoteInputPush(self: *const Context, event: *const abi.RemoteInputEvent) i32 {
        return self.base.remoteInputPush(event);
    }

    pub fn remoteInputPoll(self: *const Context, out: *abi.RemoteInputEvent) i32 {
        return self.base.remoteInputPoll(out);
    }

    pub fn remoteInputStatus(self: *const Context, out: *abi.RemoteInputStatus) i32 {
        return self.base.remoteInputStatus(out);
    }
};

test "r4desk exposes project and remote ABI metadata" {
    const std = @import("std");
    try std.testing.expectEqualStrings("R4DESK", name);
    try std.testing.expectEqualStrings("R4DESK:Query:1", import_query);
    try std.testing.expectEqual(@as(u32, 2), @intFromEnum(group));
    try std.testing.expectEqual(abi.r4l_abi_version, abi_version);
    try std.testing.expectEqual(abi.r4xstart_r4desk_version, (abi.R4XStartR4Desk{}).abi_version);
    try std.testing.expectEqual(abi.remote_frame_version, (abi.RemoteFrameInfo{}).version);
    try std.testing.expectEqual(abi.remote_input_version, (abi.RemoteInputEvent{}).version);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4desk.h", c_header);
}
