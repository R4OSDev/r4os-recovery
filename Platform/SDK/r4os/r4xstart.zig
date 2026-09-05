const abi = @import("r4os_contract").abi;
const std = @import("std");

pub fn entryAsm(comptime target: []const u8) []const u8 {
    return ".section .text.r4xstart_entry,\"ax\"\n" ++
        ".global r4xstart_entry\n" ++
        ".global R4XStart\n" ++
        "r4xstart_entry:\n" ++
        "R4XStart:\n" ++
        "    jmp " ++ target ++ "\n";
}

const WriteFn = *const fn ([*]const u8, u32) callconv(.c) i32;
const PutcFn = *const fn (u8) callconv(.c) void;
const SleepTicksFn = *const fn (u64) callconv(.c) void;
const TicksFn = *const fn () callconv(.c) u64;
const EnvGetFn = *const fn ([*:0]const u8, [*]u8, u32) callconv(.c) i32;
const DirEntryFn = *const fn ([*:0]const u8, u32, [*]u8, u32) callconv(.c) i32;
const VmReserveFn = *const fn (u64, u64, u64, *abi.ProgramVmRegionInfo) callconv(.c) i32;
const VmCommitFn = *const fn (u32, u64, u64, u64) callconv(.c) i32;
const VmDecommitFn = *const fn (u32, u64, u64) callconv(.c) i32;
const VmReleaseFn = *const fn (u32) callconv(.c) i32;
const VmQueryFn = *const fn (u32, *abi.ProgramVmRegionInfo) callconv(.c) i32;
const ThreadCreateFn = *const fn (abi.ThreadEntryFn, u64, u64, u32, *u32) callconv(.c) i32;
const ThreadExitFn = *const fn (i32) callconv(.c) void;
const ThreadJoinFn = *const fn (u32, u64, *i32) callconv(.c) i32;
const ThreadCurrentFn = *const fn () callconv(.c) u32;
const ThreadStatusFn = *const fn (u32, *abi.ProgramThreadInfo) callconv(.c) i32;
const IoFileReadFn = *const fn ([*:0]const u8, [*]u8, u64, u32, *u32) callconv(.c) i32;
const IoFileReadAtFn = *const fn ([*:0]const u8, u64, [*]u8, u64, u32, *u32) callconv(.c) i32;
const IoFileWriteFn = *const fn ([*:0]const u8, [*]const u8, u64, u32, *u32) callconv(.c) i32;
const IoFileAppendFn = *const fn ([*:0]const u8, [*]const u8, u64, u32, *u32) callconv(.c) i32;
const IoFileWriteAtFn = *const fn ([*:0]const u8, u64, [*]const u8, u64, u32, *u32) callconv(.c) i32;
const IoFileInfoFn = *const fn ([*:0]const u8, u32, *u32) callconv(.c) i32;
const IoFileLockFn = *const fn ([*:0]const u8, u64, u64, u32, *u32) callconv(.c) i32;
const IoFileStreamBeginFn = *const fn ([*:0]const u8, u32, *u32) callconv(.c) i32;
const IoFileStreamWriteFn = *const fn ([*:0]const u8, u64, [*]const u8, u64, u32, *u32) callconv(.c) i32;
const IoFileStreamFinishFn = *const fn ([*:0]const u8, u64, u32, *u32) callconv(.c) i32;
const IoFileStreamAbortFn = *const fn ([*:0]const u8, *u32) callconv(.c) i32;
const IoServiceCallFn = *const fn (u32, u16, [*]const u8, u32, *abi.ServiceMessageHeader, [*]u8, u32, u64, u32, *u32) callconv(.c) i32;
const IoStatusFn = *const fn (u32, *abi.ProgramIoInfo) callconv(.c) i32;
const IoWaitFn = *const fn (u32, u64, *abi.ProgramIoInfo) callconv(.c) i32;
const IoCloseFn = *const fn (u32) callconv(.c) i32;
const ShouldCloseFn = *const fn () callconv(.c) u32;
const StartShouldCloseFn = *const fn (*const abi.R4XStartContext) callconv(.c) u32;
const StartYieldFn = *const fn (*const abi.R4XStartContext) callconv(.c) void;
const ProgramClassFn = *const fn ([*:0]const u8, u32) callconv(.c) i32;
const ProgramInstanceFn = *const fn (u32, *abi.ProgramInstanceInfo) callconv(.c) i32;
const ProgramInventoryBeginFn = *const fn (*abi.ProgramInventoryCursor, *abi.ProgramInventorySummary) callconv(.c) i32;
const ProgramInventoryProgramsFn = *const fn (*abi.ProgramInventoryCursor, [*]abi.ProgramInstanceSnapshot, u32, *abi.ProgramInventoryPageInfo) callconv(.c) i32;
const ProgramInventoryTasksFn = *const fn (*abi.ProgramInventoryCursor, [*]abi.ProgramTaskSnapshot, u32, *abi.ProgramInventoryPageInfo) callconv(.c) i32;
const ProgramInventoryThreadsFn = *const fn (*abi.ProgramInventoryCursor, [*]abi.ProgramThreadSnapshot, u32, *abi.ProgramInventoryPageInfo) callconv(.c) i32;
const ThreadCreateHandleFn = *const fn (abi.ThreadEntryFn, u64, u64, u32, *abi.ProgramJoinHandle) callconv(.c) i32;
const ThreadHandleJoinFn = *const fn (*const abi.ProgramJoinHandle, u64, *i32) callconv(.c) i32;
const ThreadHandleStatusFn = *const fn (*const abi.ProgramJoinHandle, *abi.ProgramThreadInfo) callconv(.c) i32;
const ServiceStatusFn = *const fn ([*:0]const u8, *abi.ServiceInfo) callconv(.c) i32;
const ServiceOpenFn = *const fn ([*:0]const u8, *abi.ServiceInfo) callconv(.c) i32;
const ServiceCloseFn = *const fn (u32) callconv(.c) i32;
const ServiceCallFn = *const fn (u32, u16, [*]const u8, u32, *abi.ServiceMessageHeader, [*]u8, u32, u64) callconv(.c) i32;
const ServiceEndpointRegisterFn = *const fn ([*:0]const u8, u32, *abi.ServiceInfo) callconv(.c) i32;
const ServiceEndpointUnregisterFn = *const fn (u32) callconv(.c) i32;
const ServiceEndpointPollFn = *const fn (u32) callconv(.c) i32;
const ServiceEndpointRecvFn = *const fn (u32, *abi.ServiceMessageHeader, [*]u8, u32) callconv(.c) i32;
const ServiceEndpointReplyFn = *const fn (u32, u32, i32, [*]const u8, u32) callconv(.c) i32;
const ServiceDetailByNameFn = *const fn ([*:0]const u8, *abi.ServiceDetail) callconv(.c) i32;
const ServiceStartFn = *const fn ([*:0]const u8, *abi.ServiceInfo) callconv(.c) i32;
const ServiceStopFn = *const fn ([*:0]const u8, *abi.ServiceInfo, u64) callconv(.c) i32;
const ServiceRestartFn = *const fn ([*:0]const u8, *abi.ServiceInfo) callconv(.c) i32;
const ServiceInstallFn = *const fn ([*:0]const u8, [*:0]const u8, [*:0]const u8, u32, [*:0]const u8, *abi.ServiceInfo) callconv(.c) i32;
const ServiceRemoveFn = *const fn ([*:0]const u8) callconv(.c) i32;
const ReadKeyFn = *const fn () callconv(.c) u8;
const ReadKeyCodepointFn = *const fn () callconv(.c) u32;
const MouseStateFn = *const fn (*abi.Mouse) callconv(.c) void;
const VoidFn = *const fn () callconv(.c) void;
const KeyboardLayoutCurrentFn = *const fn (*abi.KeyboardLayoutInfo) callconv(.c) i32;
const KeyboardLayoutAtFn = *const fn (u32, *abi.KeyboardLayoutInfo) callconv(.c) i32;
const KeyboardLayoutSetFn = *const fn ([*:0]const u8) callconv(.c) i32;
const ProgramSetWindowFn = *const fn (u32, i32) callconv(.c) i32;
const ProgramSetConsoleHostFn = *const fn (u32, u32) callconv(.c) i32;
const ProgramRequestHostLaunchFn = *const fn ([*:0]const u8, [*:0]const u8, u32) callconv(.c) i32;
const ProgramTakeHostLaunchFn = *const fn (u32, *abi.ProgramHostLaunchRequest) callconv(.c) i32;
const ProgramWindowIdFn = *const fn () callconv(.c) i32;
const GuiWindowInfoFn = *const fn (*abi.GuiWindowInfo) callconv(.c) i32;
const GuiSetWindowInfoFn = *const fn (u32, *const abi.GuiWindowInfo) callconv(.c) i32;
const GuiPollEventFn = *const fn (*abi.GuiEvent) callconv(.c) i32;
const GuiPushEventFn = *const fn (u32, *const abi.GuiEvent) callconv(.c) i32;
const GuiSetTextFn = *const fn ([*:0]const u8) callconv(.c) i32;
const BufferReadFn = *const fn (u32, [*]u8, u32) callconv(.c) i32;
const RevisionFn = *const fn (u32) callconv(.c) u32;
const GuiCommandFn = *const fn (u32, u32, *abi.GuiCommand) callconv(.c) i32;
const GuiSetTitleFn = *const fn ([*:0]const u8) callconv(.c) i32;
const GuiSetMinSizeFn = *const fn (i32, i32) callconv(.c) i32;
const GuiMinSizeFn = *const fn (u32, *abi.GuiSize) callconv(.c) i32;
const ConsoleStateFn = *const fn (u32, *abi.ConsoleState) callconv(.c) i32;
const ConsoleSetMetricsFn = *const fn (u32, u32, u32) callconv(.c) i32;
const ConsolePushKeyFn = *const fn (u32, u8) callconv(.c) i32;
const ConsolePushInputFn = *const fn (u32, [*]const u8, u32) callconv(.c) i32;
const ConsoleWriteFn = *const fn (u32, [*]const u8, u32) callconv(.c) i32;
const ConsoleReadFn = *const fn ([*]u8, u32) callconv(.c) i32;
const ConsoleInputWaitFn = abi.R4DeskFns.console_input_wait;
const PhysicalKeyPollFn = abi.R4DeskFns.physical_key_poll;
const ClipboardWriteFn = *const fn ([*]const u8, u32) callconv(.c) i32;
const ClipboardReadFn = *const fn ([*]u8, u32) callconv(.c) i32;
const ClipboardRevisionFn = *const fn () callconv(.c) u32;
const ClipboardInfoFn = *const fn (*abi.ClipboardInfo) callconv(.c) i32;
const RemoteFrameInfoFn = *const fn (*abi.RemoteFrameInfo) callconv(.c) i32;
const RemoteFrameReadFn = *const fn (u32, [*]u32, u32, *abi.RemoteFrameInfo) callconv(.c) i32;
const RemoteFrameWaitFn = *const fn (u32, u64, *abi.RemoteFrameInfo) callconv(.c) i32;
const RemoteFramePublishFn = *const fn (*const abi.RemoteFrameInfo, [*]const u32, u32) callconv(.c) i32;
const RemoteFramePublishRegionsFn = abi.R4DeskFns.remote_frame_publish_regions;
const RemoteFrameAcquireFn = *const fn () callconv(.c) i32;
const RemoteFrameReleaseFn = *const fn () callconv(.c) i32;
const RemoteFrameConsumersFn = *const fn () callconv(.c) u32;
const RemoteInputPushFn = *const fn (*const abi.RemoteInputEvent) callconv(.c) i32;
const RemoteInputPollFn = *const fn (*abi.RemoteInputEvent) callconv(.c) i32;
const RemoteInputStatusFn = *const fn (*abi.RemoteInputStatus) callconv(.c) i32;
const ScreenSizeFn = *const fn () callconv(.c) u32;
const ClearFn = *const fn (u32) callconv(.c) void;
const RectFn = *const fn (i32, i32, u32, u32, u32) callconv(.c) void;
const TextFn = *const fn (i32, i32, [*:0]const u8, u32, u32) callconv(.c) void;
const DisplayRevisionFn = *const fn () callconv(.c) u32;
const DisplayBeginFrameFn = *const fn () callconv(.c) i32;
const DisplayBeginFrameRectFn = *const fn (i32, i32, u32, u32) callconv(.c) i32;
const DisplayPresentFn = *const fn () callconv(.c) i32;
const DisplayBlitFn = *const fn (i32, i32, u32, u32, [*]const u32, u32) callconv(.c) i32;
const DisplayBlitStrideFn = *const fn (i32, i32, u32, u32, [*]const u32, u32, u32) callconv(.c) i32;
const DisplayPresentRegionsFn = abi.R4DrawFns.display_present_regions;
const DisplayPresentCapabilitiesFn = abi.R4DrawFns.display_present_capabilities;
const DisplayPresentCompletionFn = abi.R4DrawFns.display_present_completion;
const GuiClearFn = *const fn (u32) callconv(.c) i32;
const GuiRectFn = *const fn (i32, i32, u32, u32, u32) callconv(.c) i32;
const GuiDrawTextFn = *const fn (i32, i32, [*:0]const u8, u32, u32) callconv(.c) i32;
const GuiDrawTextExFn = *const fn (i32, i32, [*:0]const u8, u32, u32, u32, u32) callconv(.c) i32;
const GuiBlitFn = *const fn (i32, i32, u32, u32, u32, [*]const u32, u32) callconv(.c) i32;
const GuiBlendAlpha8Fn = abi.R4DrawFns.gui_blend_alpha8;
const GuiRasterReadFn = *const fn (u32, u32, [*]u32, u32) callconv(.c) i32;
const GuiFrameBeginFn = abi.R4DrawFns.gui_frame_begin;
const GuiFrameAppendFn = abi.R4DrawFns.gui_frame_append;
const GuiFrameCommitFn = abi.R4DrawFns.gui_frame_commit;
const GuiFrameCancelFn = abi.R4DrawFns.gui_frame_cancel;
const GuiFrameInfoFn = abi.R4DrawFns.gui_frame_info;
const GuiFrameReadFn = abi.R4DrawFns.gui_frame_read;
const GuiFrameBeginDamageFn = abi.R4DrawFns.gui_frame_begin_damage;
const GuiFrameGenerationInfoFn = abi.R4DrawFns.gui_frame_generation_info;
const GuiFrameGenerationReadFn = abi.R4DrawFns.gui_frame_generation_read;
const GuiFrameBeginReplaceFn = abi.R4DrawFns.gui_frame_begin_replace;
const GuiFrameStreamInfoFn = abi.R4DrawFns.gui_frame_stream_info;
const FontCountFn = *const fn () callconv(.c) u32;
const FontInfoFn = *const fn (u32, *abi.GuiFontInfo) callconv(.c) i32;
const FontMeasureFn = *const fn (u32, [*:0]const u8, *abi.GuiTextMetrics) callconv(.c) i32;
const FontGlyphRowFn = *const fn (u32, u32, u32) callconv(.c) u64;
const FontGlyphBitmapFn = abi.R4DrawFns.font_glyph_bitmap;
const FontRevisionFn = abi.R4DrawFns.font_revision;
const FontReloadFn = *const fn () callconv(.c) i32;
const GuiSetFontFn = *const fn (u32) callconv(.c) i32;
const GuiFontFn = *const fn (u32, *abi.GuiFontInfo) callconv(.c) i32;
const TextFontFn = *const fn (u32, i32, i32, [*:0]const u8, u32, u32) callconv(.c) void;

comptime {
    if (@sizeOf(abi.R4XStartContext) != abi.r4xstart_context_size) {
        @compileError("R4XStartContext ABI size mismatch");
    }
    if (@offsetOf(abi.R4XStartContext, "reserved_runtime") != 112) {
        @compileError("R4XStartContext.reserved_runtime ABI offset mismatch");
    }
    if (@sizeOf(abi.R4XStartImport) != abi.r4xstart_import_size) {
        @compileError("R4XStartImport ABI size mismatch");
    }
    if (@sizeOf(abi.R4XStartR4Sys) != abi.r4xstart_r4sys_size) {
        @compileError("R4XStartR4Sys ABI size mismatch");
    }
    if (@offsetOf(abi.R4XStartR4Sys, "reserved_shell_run") != 408 or
        @offsetOf(abi.R4XStartR4Sys, "system_halt") != 416 or
        @offsetOf(abi.R4XStartR4Sys, "boot_log_read") != 752)
    {
        @compileError("R4XStartR4Sys reserved/following ABI offset mismatch");
    }
    if (@sizeOf(abi.R4XStartR4Desk) < abi.r4xstart_r4desk_size) {
        @compileError("R4XStartR4Desk ABI minimum size mismatch");
    }
    if (@sizeOf(abi.R4XStartR4Draw) < abi.r4xstart_r4draw_size) {
        @compileError("R4XStartR4Draw ABI minimum size mismatch");
    }
    // R4NET-, R4AUDIO- und R4DEV-Gruppentabellen gehoeren zum aktuellen
    // R4XStart-Bundlevertrag.
    if (@sizeOf(abi.R4XStartR4Net) < abi.r4xstart_r4net_size) {
        @compileError("R4XStartR4Net ABI minimum size mismatch");
    }
    if (@sizeOf(abi.R4XStartR4Audio) != abi.r4xstart_r4audio_size) {
        @compileError("R4XStartR4Audio ABI size mismatch");
    }
    if (@sizeOf(abi.R4XStartR4Dev) < abi.r4xstart_r4dev_size) {
        @compileError("R4XStartR4Dev ABI minimum size mismatch");
    }
}

pub const Context = struct {
    raw: *const abi.R4XStartContext,

    pub fn init(raw: *const abi.R4XStartContext) Context {
        return .{ .raw = raw };
    }

    pub fn valid(self: Context) bool {
        return self.raw.magic == abi.r4xstart_magic and
            self.raw.abi_major == abi.r4xstart_abi_major and
            self.raw.size >= abi.r4xstart_context_size;
    }

    pub fn args(self: Context) []const u8 {
        if (self.raw.args == 0 or self.raw.args_len == 0) return "";
        const ptr: [*]const u8 = @ptrFromInt(self.raw.args);
        return ptr[0..@intCast(self.raw.args_len)];
    }

    pub fn importCount(self: Context) u32 {
        if ((self.raw.flags & abi.r4xstart_flag_imports_valid) == 0) return 0;
        return self.raw.import_count;
    }

    pub fn importAt(self: Context, index: usize) ?*const abi.R4XStartImport {
        if (self.raw.imports == 0 or index >= self.importCount()) return null;
        const imports: [*]const abi.R4XStartImport = @ptrFromInt(self.raw.imports);
        return &imports[index];
    }

    pub fn findImport(self: Context, group: abi.R4LGroup) ?*const abi.R4XStartImport {
        var i: usize = 0;
        while (i < self.importCount()) : (i += 1) {
            const item = self.importAt(i) orelse return null;
            if (item.group_id == @intFromEnum(group)) return item;
        }
        return null;
    }

    pub fn findImportNamed(self: Context, module_name: []const u8, symbol_name: []const u8) ?*const abi.R4XStartImport {
        var i: usize = 0;
        while (i < self.importCount()) : (i += 1) {
            const item = self.importAt(i) orelse return null;
            if (importNameEquals(item.module_name, module_name) and
                importNameEquals(item.symbol_name, symbol_name)) return item;
        }
        return null;
    }

    pub fn r4sys(self: Context) ?R4Sys {
        const item = self.findImport(.r4sys) orelse return null;
        if ((item.flags & abi.r4xstart_import_flag_group_interface) == 0) return null;
        if (item.table == 0) return null;
        const table: *const abi.R4XStartR4Sys = @ptrFromInt(item.table);
        if (table.magic != abi.r4xstart_r4sys_magic) return null;
        if (table.abi_version < abi.r4xstart_r4sys_version) return null;
        if (table.size < abi.r4xstart_r4sys_size) return null;
        if (table.write == 0 or table.putc == 0) return null;
        return .{ .raw = self.raw, .table = table };
    }

    pub fn r4desk(self: Context) ?R4Desk {
        const item = self.findImport(.r4desk) orelse return null;
        if ((item.flags & abi.r4xstart_import_flag_group_interface) == 0) return null;
        if (item.table == 0) return null;
        const table: *const abi.R4XStartR4Desk = @ptrFromInt(item.table);
        if (table.magic != abi.r4xstart_r4desk_magic) return null;
        if (table.abi_version < abi.r4xstart_r4desk_version) return null;
        if (table.size < abi.r4xstart_r4desk_size) return null;
        if (table.program_window_id == 0 or table.gui_window_info == 0 or table.gui_poll_event == 0) return null;
        return .{ .raw = self.raw, .table = table };
    }

    pub fn r4draw(self: Context) ?R4Draw {
        const item = self.findImport(.r4draw) orelse return null;
        if ((item.flags & abi.r4xstart_import_flag_group_interface) == 0) return null;
        if (item.table == 0) return null;
        const table: *const abi.R4XStartR4Draw = @ptrFromInt(item.table);
        if (table.magic != abi.r4xstart_r4draw_magic) return null;
        if (table.abi_version < abi.r4xstart_r4draw_version) return null;
        if (table.size < abi.r4xstart_r4draw_size) return null;
        if (table.gui_clear == 0 or table.gui_rect == 0 or table.gui_present == 0) return null;
        return .{ .raw = self.raw, .table = table };
    }
};

fn importNameEquals(raw: u64, expected: []const u8) bool {
    if (raw == 0 or expected.len == 0 or expected.len >= 32) return false;
    const value: [*]const u8 = @ptrFromInt(raw);
    var index: usize = 0;
    while (index < expected.len) : (index += 1) {
        const actual = value[index];
        if (actual == 0 or asciiUpper(actual) != asciiUpper(expected[index])) return false;
    }
    return value[expected.len] == 0;
}

fn asciiUpper(value: u8) u8 {
    return if (value >= 'a' and value <= 'z') value - ('a' - 'A') else value;
}

pub const R4Sys = struct {
    raw: *const abi.R4XStartContext,
    table: *const abi.R4XStartR4Sys,

    pub fn hasFn(self: *const R4Sys, comptime field: []const u8) bool {
        const end = @offsetOf(abi.R4XStartR4Sys, field) + @sizeOf(usize);
        return self.table.size >= end and @field(self.table.*, field) != 0;
    }

    pub fn argsRaw(self: *const R4Sys) [*:0]const u8 {
        if (self.raw.args == 0) return "";
        return @ptrFromInt(self.raw.args);
    }

    pub fn args(self: *const R4Sys) []const u8 {
        if (self.raw.args == 0 or self.raw.args_len == 0) return "";
        const ptr: [*]const u8 = @ptrFromInt(self.raw.args);
        return ptr[0..@intCast(self.raw.args_len)];
    }

    pub fn write(self: *const R4Sys, text: []const u8) void {
        if (text.len == 0) return;
        const write_fn: WriteFn = @ptrFromInt(self.table.write);
        _ = write_fn(text.ptr, @intCast(text.len));
    }

    pub fn print(self: *const R4Sys, text: []const u8) void {
        self.write(text);
    }

    pub fn println(self: *const R4Sys, text: []const u8) void {
        self.write(text);
        self.write("\r\n");
    }

    pub fn putc(self: *const R4Sys, ch: u8) void {
        const putc_fn: PutcFn = @ptrFromInt(self.table.putc);
        putc_fn(ch);
    }

    pub fn printU64(self: *const R4Sys, value: u64) void {
        var buf: [20]u8 = undefined;
        var pos = buf.len;
        var n = value;
        if (n == 0) {
            self.write("0");
            return;
        }
        while (n > 0) {
            pos -= 1;
            buf[pos] = '0' + @as(u8, @intCast(n % 10));
            n /= 10;
        }
        self.write(buf[pos..]);
    }

    pub fn printI32(self: *const R4Sys, value: i32) void {
        if (value < 0) {
            self.putc('-');
            const magnitude: u64 = @intCast(-@as(i64, value));
            self.printU64(magnitude);
            return;
        }
        self.printU64(@intCast(value));
    }

    pub fn ticks(self: *const R4Sys) u64 {
        if (!self.hasFn("ticks")) return 0;
        const ticks_fn: TicksFn = @ptrFromInt(self.table.ticks);
        return ticks_fn();
    }

    pub fn sleepTicks(self: *const R4Sys, duration: u64) void {
        if (self.hasFn("sleep_ticks")) {
            const sleep_fn: SleepTicksFn = @ptrFromInt(self.table.sleep_ticks);
            sleep_fn(duration);
            return;
        }
        self.taskYield();
    }

    pub fn taskYield(self: *const R4Sys) void {
        if (self.raw.yield == 0) return;
        const yield_fn: StartYieldFn = @ptrFromInt(self.raw.yield);
        yield_fn(self.raw);
    }

    pub fn programShouldClose(self: *const R4Sys) bool {
        if ((self.raw.flags & abi.r4xstart_flag_close_supported) != 0 and self.raw.should_close != 0) {
            const close_fn: StartShouldCloseFn = @ptrFromInt(self.raw.should_close);
            return close_fn(self.raw) != 0;
        }
        if (self.hasFn("program_should_close")) {
            const close_fn: ShouldCloseFn = @ptrFromInt(self.table.program_should_close);
            return close_fn() != 0;
        }
        return false;
    }

    pub fn envGet(self: *const R4Sys, name: [*:0]const u8, out: []u8) i32 {
        if (!self.hasFn("env_get") or out.len == 0) return abi.service_api_result_invalid;
        const env_fn: EnvGetFn = @ptrFromInt(self.table.env_get);
        return env_fn(name, out.ptr, @intCast(out.len));
    }

    pub fn dirEntry(self: *const R4Sys, path: [*:0]const u8, index: u32, out: []u8) i32 {
        if (!self.hasFn("dir_entry") or out.len == 0) return -1;
        const dir_fn: DirEntryFn = @ptrFromInt(self.table.dir_entry);
        return dir_fn(path, index, out.ptr, @intCast(out.len));
    }

    pub fn programClass(self: *const R4Sys, path: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        if (!self.hasFn("program_class")) return -1;
        const class_fn: ProgramClassFn = @ptrFromInt(self.table.program_class);
        return class_fn(path, @intFromEnum(policy));
    }

    pub fn programInstance(self: *const R4Sys, index: u32, out: *abi.ProgramInstanceInfo) i32 {
        if (!self.hasFn("program_instance")) return -1;
        const instance_fn: ProgramInstanceFn = @ptrFromInt(self.table.program_instance);
        return instance_fn(index, out);
    }

    pub fn programInventoryBegin(self: *const R4Sys, cursor: *abi.ProgramInventoryCursor, out: *abi.ProgramInventorySummary) i32 {
        if (!self.hasFn("program_inventory_begin")) return abi.program_handle_error_invalid;
        const inventory_fn: ProgramInventoryBeginFn = @ptrFromInt(self.table.program_inventory_begin);
        return inventory_fn(cursor, out);
    }

    pub fn programInventoryPrograms(self: *const R4Sys, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramInstanceSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        if (!self.hasFn("program_inventory_programs") or out.len == 0 or out.len > @as(usize, abi.program_inventory_page_max)) return abi.program_handle_error_invalid;
        const inventory_fn: ProgramInventoryProgramsFn = @ptrFromInt(self.table.program_inventory_programs);
        return inventory_fn(cursor, out.ptr, @intCast(out.len), page);
    }

    pub fn programInventoryTasks(self: *const R4Sys, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramTaskSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        if (!self.hasFn("program_inventory_tasks") or out.len == 0 or out.len > @as(usize, abi.program_inventory_page_max)) return abi.program_handle_error_invalid;
        const inventory_fn: ProgramInventoryTasksFn = @ptrFromInt(self.table.program_inventory_tasks);
        return inventory_fn(cursor, out.ptr, @intCast(out.len), page);
    }

    pub fn programInventoryThreads(self: *const R4Sys, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramThreadSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        if (!self.hasFn("program_inventory_threads") or out.len == 0 or out.len > @as(usize, abi.program_inventory_page_max)) return abi.program_handle_error_invalid;
        const inventory_fn: ProgramInventoryThreadsFn = @ptrFromInt(self.table.program_inventory_threads);
        return inventory_fn(cursor, out.ptr, @intCast(out.len), page);
    }

    pub fn supportsThreads(self: *const R4Sys) bool {
        return self.hasFn("thread_create") and
            self.hasFn("thread_exit") and
            self.hasFn("thread_join") and
            self.hasFn("thread_current") and
            self.hasFn("thread_status");
    }

    pub fn threadCreateRaw(self: *const R4Sys, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64, flags: u32, out_thread_id: *u32) i32 {
        if (!self.supportsThreads()) return abi.thread_error_unsupported;
        const create_fn: ThreadCreateFn = @ptrFromInt(self.table.thread_create);
        return create_fn(entry, arg, stack_reserve_bytes, flags, out_thread_id);
    }

    pub fn threadCreate(self: *const R4Sys, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64) ?u32 {
        var id: u32 = 0;
        if (self.threadCreateRaw(entry, arg, stack_reserve_bytes, 0, &id) != abi.thread_ok) return null;
        return id;
    }

    pub fn threadCreateHandle(self: *const R4Sys, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64, flags: u32, out_handle: *abi.ProgramJoinHandle) i32 {
        if (!self.hasFn("thread_create_handle")) return abi.thread_error_unsupported;
        const create_fn: ThreadCreateHandleFn = @ptrFromInt(self.table.thread_create_handle);
        return create_fn(entry, arg, stack_reserve_bytes, flags, out_handle);
    }

    pub fn threadExit(self: *const R4Sys, exit_code: i32) noreturn {
        if (self.supportsThreads()) {
            const exit_fn: ThreadExitFn = @ptrFromInt(self.table.thread_exit);
            exit_fn(exit_code);
        }
        while (true) self.taskYield();
    }

    pub fn threadJoin(self: *const R4Sys, thread_id: u32, timeout_ticks: u64, out_exit_code: *i32) i32 {
        if (!self.supportsThreads()) return abi.thread_error_unsupported;
        const join_fn: ThreadJoinFn = @ptrFromInt(self.table.thread_join);
        return join_fn(thread_id, timeout_ticks, out_exit_code);
    }

    pub fn threadHandleJoin(self: *const R4Sys, handle: *const abi.ProgramJoinHandle, timeout_ticks: u64, out_exit_code: *i32) i32 {
        if (!self.hasFn("thread_handle_join")) return abi.thread_error_unsupported;
        const join_fn: ThreadHandleJoinFn = @ptrFromInt(self.table.thread_handle_join);
        return join_fn(handle, timeout_ticks, out_exit_code);
    }

    pub fn threadCurrent(self: *const R4Sys) u32 {
        if (!self.supportsThreads()) return 0;
        const current_fn: ThreadCurrentFn = @ptrFromInt(self.table.thread_current);
        return current_fn();
    }

    pub fn threadStatus(self: *const R4Sys, thread_id: u32, out: *abi.ProgramThreadInfo) i32 {
        if (!self.supportsThreads()) return abi.thread_error_unsupported;
        const status_fn: ThreadStatusFn = @ptrFromInt(self.table.thread_status);
        return status_fn(thread_id, out);
    }

    pub fn threadHandleStatus(self: *const R4Sys, handle: *const abi.ProgramJoinHandle, out: *abi.ProgramThreadInfo) i32 {
        if (!self.hasFn("thread_handle_status")) return abi.thread_error_unsupported;
        const status_fn: ThreadHandleStatusFn = @ptrFromInt(self.table.thread_handle_status);
        return status_fn(handle, out);
    }

    pub fn supportsAsyncIo(self: *const R4Sys) bool {
        return self.hasFn("io_file_read") and
            self.hasFn("io_file_write") and
            self.hasFn("io_file_stream_write") and
            self.hasFn("io_service_call") and
            self.hasFn("io_status") and
            self.hasFn("io_wait") and
            self.hasFn("io_close");
    }

    pub fn ioFileRead(self: *const R4Sys, path: [*:0]const u8, out: []u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        const io_fn: IoFileReadFn = @ptrFromInt(self.table.io_file_read);
        return io_fn(path, out.ptr, @intCast(out.len), flags, out_request_id);
    }

    pub fn ioFileReadAt(self: *const R4Sys, path: [*:0]const u8, offset: u64, out: []u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_read_at")) return abi.io_error_unsupported;
        const io_fn: IoFileReadAtFn = @ptrFromInt(self.table.io_file_read_at);
        return io_fn(path, offset, out.ptr, @intCast(out.len), flags, out_request_id);
    }

    pub fn ioFileWrite(self: *const R4Sys, path: [*:0]const u8, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        const io_fn: IoFileWriteFn = @ptrFromInt(self.table.io_file_write);
        return io_fn(path, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileAppend(self: *const R4Sys, path: [*:0]const u8, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_append")) return abi.io_error_unsupported;
        const io_fn: IoFileAppendFn = @ptrFromInt(self.table.io_file_append);
        return io_fn(path, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileWriteAt(self: *const R4Sys, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_write_at")) return abi.io_error_unsupported;
        const io_fn: IoFileWriteAtFn = @ptrFromInt(self.table.io_file_write_at);
        return io_fn(path, offset, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileInfo(self: *const R4Sys, path: [*:0]const u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_info")) return abi.io_error_unsupported;
        const io_fn: IoFileInfoFn = @ptrFromInt(self.table.io_file_info);
        return io_fn(path, flags, out_request_id);
    }

    pub fn ioFileLock(self: *const R4Sys, path: [*:0]const u8, offset: u64, length: u64, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_lock")) return abi.io_error_unsupported;
        const io_fn: IoFileLockFn = @ptrFromInt(self.table.io_file_lock);
        return io_fn(path, offset, length, flags, out_request_id);
    }

    pub fn ioFileStreamBegin(self: *const R4Sys, path: [*:0]const u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_stream_begin")) return abi.io_error_unsupported;
        const io_fn: IoFileStreamBeginFn = @ptrFromInt(self.table.io_file_stream_begin);
        return io_fn(path, flags, out_request_id);
    }

    pub fn ioFileStreamWrite(self: *const R4Sys, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        const io_fn: IoFileStreamWriteFn = @ptrFromInt(self.table.io_file_stream_write);
        return io_fn(path, offset, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileStreamFinish(self: *const R4Sys, path: [*:0]const u8, expected_size: u64, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_stream_finish")) return abi.io_error_unsupported;
        const io_fn: IoFileStreamFinishFn = @ptrFromInt(self.table.io_file_stream_finish);
        return io_fn(path, expected_size, flags, out_request_id);
    }

    pub fn ioFileStreamAbort(self: *const R4Sys, path: [*:0]const u8, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo() or !self.hasFn("io_file_stream_abort")) return abi.io_error_unsupported;
        const io_fn: IoFileStreamAbortFn = @ptrFromInt(self.table.io_file_stream_abort);
        return io_fn(path, out_request_id);
    }

    pub fn ioServiceCall(self: *const R4Sys, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout_ticks: u64, flags: u32, out_request_id: *u32) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        if (request.len > abi.service_api_max_payload) return abi.service_api_result_payload_too_large;
        if (response.len > abi.service_api_max_payload) return abi.service_api_result_invalid;
        const io_fn: IoServiceCallFn = @ptrFromInt(self.table.io_service_call);
        return io_fn(handle, op, request.ptr, @intCast(request.len), response_header, response.ptr, @intCast(response.len), timeout_ticks, flags, out_request_id);
    }

    pub fn ioStatus(self: *const R4Sys, request_id: u32, out: *abi.ProgramIoInfo) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        const io_fn: IoStatusFn = @ptrFromInt(self.table.io_status);
        return io_fn(request_id, out);
    }

    pub fn ioWait(self: *const R4Sys, request_id: u32, timeout_ticks: u64, out: *abi.ProgramIoInfo) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        const io_fn: IoWaitFn = @ptrFromInt(self.table.io_wait);
        return io_fn(request_id, timeout_ticks, out);
    }

    pub fn ioClose(self: *const R4Sys, request_id: u32) i32 {
        if (!self.supportsAsyncIo()) return abi.io_error_unsupported;
        const io_fn: IoCloseFn = @ptrFromInt(self.table.io_close);
        return io_fn(request_id);
    }

    pub fn supportsVmApi(self: *const R4Sys) bool {
        return self.hasFn("vm_reserve") and
            self.hasFn("vm_commit") and
            self.hasFn("vm_decommit") and
            self.hasFn("vm_release") and
            self.hasFn("vm_query");
    }

    pub fn vmReserve(self: *const R4Sys, size: u64, alignment: u64, flags: u64) ?abi.ProgramVmRegionInfo {
        if (!self.supportsVmApi()) return null;
        var out: abi.ProgramVmRegionInfo = .{};
        const vm_fn: VmReserveFn = @ptrFromInt(self.table.vm_reserve);
        if (vm_fn(size, alignment, flags, &out) != abi.vm_ok) return null;
        return out;
    }

    pub fn vmCommit(self: *const R4Sys, region_id: u32, offset: u64, len: u64) i32 {
        return self.vmCommitFlags(region_id, offset, len, 0);
    }

    pub fn vmCommitFlags(self: *const R4Sys, region_id: u32, offset: u64, len: u64, flags: u64) i32 {
        if (!self.hasFn("vm_commit")) return abi.vm_error_no_instance;
        const vm_fn: VmCommitFn = @ptrFromInt(self.table.vm_commit);
        return vm_fn(region_id, offset, len, flags);
    }

    pub fn vmDecommit(self: *const R4Sys, region_id: u32, offset: u64, len: u64) i32 {
        if (!self.hasFn("vm_decommit")) return abi.vm_error_no_instance;
        const vm_fn: VmDecommitFn = @ptrFromInt(self.table.vm_decommit);
        return vm_fn(region_id, offset, len);
    }

    pub fn vmRelease(self: *const R4Sys, region_id: u32) i32 {
        if (!self.hasFn("vm_release")) return abi.vm_error_no_instance;
        const vm_fn: VmReleaseFn = @ptrFromInt(self.table.vm_release);
        return vm_fn(region_id);
    }

    pub fn vmQuery(self: *const R4Sys, region_id: u32) ?abi.ProgramVmRegionInfo {
        if (!self.hasFn("vm_query")) return null;
        var out: abi.ProgramVmRegionInfo = .{};
        const vm_fn: VmQueryFn = @ptrFromInt(self.table.vm_query);
        if (vm_fn(region_id, &out) != abi.vm_ok) return null;
        return out;
    }

    pub fn supportsServiceApi(self: *const R4Sys) bool {
        return self.hasFn("service_open") and
            self.hasFn("service_call") and
            self.hasFn("service_endpoint_register") and
            self.hasFn("service_endpoint_reply");
    }

    pub fn supportsServiceManager(self: *const R4Sys) bool {
        return self.supportsServiceApi() and
            self.hasFn("service_start") and
            self.hasFn("service_stop") and
            self.hasFn("service_install") and
            self.hasFn("service_remove");
    }

    pub fn serviceStatus(self: *const R4Sys, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        if (!self.hasFn("service_status")) return abi.service_api_result_invalid;
        const service_fn: ServiceStatusFn = @ptrFromInt(self.table.service_status);
        return service_fn(name, out);
    }

    pub fn serviceOpen(self: *const R4Sys, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        if (!self.hasFn("service_open")) return abi.service_api_result_invalid;
        const service_fn: ServiceOpenFn = @ptrFromInt(self.table.service_open);
        return service_fn(name, out);
    }

    pub fn serviceClose(self: *const R4Sys, handle: u32) i32 {
        if (!self.hasFn("service_close")) return abi.service_api_result_invalid;
        const service_fn: ServiceCloseFn = @ptrFromInt(self.table.service_close);
        return service_fn(handle);
    }

    pub fn serviceCall(self: *const R4Sys, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout_ticks: u64) i32 {
        if (!self.hasFn("service_call")) return abi.service_api_result_invalid;
        if (request.len > abi.service_api_max_payload) return abi.service_api_result_payload_too_large;
        if (response.len > abi.service_api_max_payload) return abi.service_api_result_invalid;
        const request_ptr = if (request.len == 0) @as([*]const u8, @ptrCast("")) else request.ptr;
        var empty_response: [1]u8 = .{0};
        const response_ptr = if (response.len == 0) empty_response[0..].ptr else response.ptr;
        const service_fn: ServiceCallFn = @ptrFromInt(self.table.service_call);
        return service_fn(handle, op, request_ptr, @intCast(request.len), response_header, response_ptr, @intCast(response.len), timeout_ticks);
    }

    pub fn serviceEndpointRegister(self: *const R4Sys, name: [*:0]const u8, flags: u32, out: *abi.ServiceInfo) i32 {
        if (!self.hasFn("service_endpoint_register")) return abi.service_api_result_invalid;
        const service_fn: ServiceEndpointRegisterFn = @ptrFromInt(self.table.service_endpoint_register);
        return service_fn(name, flags, out);
    }

    pub fn serviceEndpointUnregister(self: *const R4Sys, handle: u32) i32 {
        if (!self.hasFn("service_endpoint_unregister")) return abi.service_api_result_invalid;
        const service_fn: ServiceEndpointUnregisterFn = @ptrFromInt(self.table.service_endpoint_unregister);
        return service_fn(handle);
    }

    pub fn serviceEndpointPoll(self: *const R4Sys, handle: u32) i32 {
        if (!self.hasFn("service_endpoint_poll")) return abi.service_api_result_invalid;
        const service_fn: ServiceEndpointPollFn = @ptrFromInt(self.table.service_endpoint_poll);
        return service_fn(handle);
    }

    pub fn serviceEndpointRecv(self: *const R4Sys, handle: u32, header: *abi.ServiceMessageHeader, out: []u8) i32 {
        if (!self.hasFn("service_endpoint_recv")) return abi.service_api_result_invalid;
        if (out.len > abi.service_api_max_payload) return abi.service_api_result_invalid;
        var empty_out: [1]u8 = .{0};
        const out_ptr = if (out.len == 0) empty_out[0..].ptr else out.ptr;
        const service_fn: ServiceEndpointRecvFn = @ptrFromInt(self.table.service_endpoint_recv);
        return service_fn(handle, header, out_ptr, @intCast(out.len));
    }

    pub fn serviceEndpointReply(self: *const R4Sys, handle: u32, request_id: u32, status: i32, payload: []const u8) i32 {
        if (!self.hasFn("service_endpoint_reply")) return abi.service_api_result_invalid;
        if (payload.len > abi.service_api_max_payload) return abi.service_api_result_payload_too_large;
        const payload_ptr = if (payload.len == 0) @as([*]const u8, @ptrCast("")) else payload.ptr;
        const service_fn: ServiceEndpointReplyFn = @ptrFromInt(self.table.service_endpoint_reply);
        return service_fn(handle, request_id, status, payload_ptr, @intCast(payload.len));
    }

    pub fn serviceDetailByName(self: *const R4Sys, name: [*:0]const u8, out: *abi.ServiceDetail) i32 {
        if (!self.hasFn("service_detail_by_name")) return abi.service_api_result_invalid;
        const service_fn: ServiceDetailByNameFn = @ptrFromInt(self.table.service_detail_by_name);
        return service_fn(name, out);
    }

    pub fn serviceStart(self: *const R4Sys, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        if (!self.hasFn("service_start")) return abi.service_api_result_invalid;
        const service_fn: ServiceStartFn = @ptrFromInt(self.table.service_start);
        return service_fn(name, out);
    }

    pub fn serviceStop(self: *const R4Sys, name: [*:0]const u8, out: *abi.ServiceInfo, timeout_ticks: u64) i32 {
        if (!self.hasFn("service_stop")) return abi.service_api_result_invalid;
        const service_fn: ServiceStopFn = @ptrFromInt(self.table.service_stop);
        return service_fn(name, out, timeout_ticks);
    }

    pub fn serviceRestart(self: *const R4Sys, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        if (!self.hasFn("service_restart")) return abi.service_api_result_invalid;
        const service_fn: ServiceRestartFn = @ptrFromInt(self.table.service_restart);
        return service_fn(name, out);
    }

    pub fn serviceInstall(self: *const R4Sys, name: [*:0]const u8, path: [*:0]const u8, args_value: [*:0]const u8, start_mode: u32, description: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        if (!self.hasFn("service_install")) return abi.service_api_result_invalid;
        const service_fn: ServiceInstallFn = @ptrFromInt(self.table.service_install);
        return service_fn(name, path, args_value, start_mode, description, out);
    }

    pub fn serviceRemove(self: *const R4Sys, name: [*:0]const u8) i32 {
        if (!self.hasFn("service_remove")) return abi.service_api_result_invalid;
        const service_fn: ServiceRemoveFn = @ptrFromInt(self.table.service_remove);
        return service_fn(name);
    }
};

pub const R4Desk = struct {
    raw: *const abi.R4XStartContext,
    table: *const abi.R4XStartR4Desk,

    pub fn hasFn(self: *const R4Desk, comptime field: []const u8) bool {
        const end = @offsetOf(abi.R4XStartR4Desk, field) + @sizeOf(usize);
        return self.table.size >= end and @field(self.table.*, field) != 0;
    }

    pub fn readKey(self: *const R4Desk) u8 {
        if (!self.hasFn("read_key")) return 0;
        const read_fn: ReadKeyFn = @ptrFromInt(self.table.read_key);
        return read_fn();
    }

    pub fn readKeyCodepoint(self: *const R4Desk) u32 {
        if (!self.hasFn("read_key_codepoint")) return self.readKey();
        const read_fn: ReadKeyCodepointFn = @ptrFromInt(self.table.read_key_codepoint);
        return read_fn();
    }

    pub fn mouseState(self: *const R4Desk, out: *abi.Mouse) void {
        if (!self.hasFn("mouse_state")) {
            out.* = .{ .x = 0, .y = 0, .dx = 0, .dy = 0, .buttons = 0, .present = 0, .reserved = 0, .packets = 0 };
            return;
        }
        const mouse_fn: MouseStateFn = @ptrFromInt(self.table.mouse_state);
        mouse_fn(out);
    }

    pub fn mouseShow(self: *const R4Desk) void {
        if (!self.hasFn("mouse_show")) return;
        const mouse_fn: VoidFn = @ptrFromInt(self.table.mouse_show);
        mouse_fn();
    }

    pub fn mouseHide(self: *const R4Desk) void {
        if (!self.hasFn("mouse_hide")) return;
        const mouse_fn: VoidFn = @ptrFromInt(self.table.mouse_hide);
        mouse_fn();
    }

    pub fn keyboardLayoutCurrent(self: *const R4Desk, out: *abi.KeyboardLayoutInfo) i32 {
        if (!self.hasFn("keyboard_layout_current")) return -1;
        const layout_fn: KeyboardLayoutCurrentFn = @ptrFromInt(self.table.keyboard_layout_current);
        return layout_fn(out);
    }

    pub fn keyboardLayoutAt(self: *const R4Desk, index: u32, out: *abi.KeyboardLayoutInfo) i32 {
        if (!self.hasFn("keyboard_layout_at")) return -1;
        const layout_fn: KeyboardLayoutAtFn = @ptrFromInt(self.table.keyboard_layout_at);
        return layout_fn(index, out);
    }

    pub fn keyboardLayoutSet(self: *const R4Desk, name_value: [*:0]const u8) i32 {
        if (!self.hasFn("keyboard_layout_set")) return -1;
        const layout_fn: KeyboardLayoutSetFn = @ptrFromInt(self.table.keyboard_layout_set);
        return layout_fn(name_value);
    }

    pub fn programSetWindow(self: *const R4Desk, instance_id: u32, window_id: i32) i32 {
        if (!self.hasFn("program_set_window")) return -1;
        const program_fn: ProgramSetWindowFn = @ptrFromInt(self.table.program_set_window);
        return program_fn(instance_id, window_id);
    }

    pub fn programSetConsoleHost(self: *const R4Desk, instance_id: u32, host: abi.ConsoleHostKind) i32 {
        if (!self.hasFn("program_set_console_host")) return -1;
        const program_fn: ProgramSetConsoleHostFn = @ptrFromInt(self.table.program_set_console_host);
        return program_fn(instance_id, @intFromEnum(host));
    }

    pub fn programRequestHostLaunch(self: *const R4Desk, path: [*:0]const u8, args_value: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        if (!self.hasFn("program_request_host_launch")) return -1;
        const program_fn: ProgramRequestHostLaunchFn = @ptrFromInt(self.table.program_request_host_launch);
        return program_fn(path, args_value, @intFromEnum(policy));
    }

    pub fn programTakeHostLaunch(self: *const R4Desk, instance_id: u32, out: *abi.ProgramHostLaunchRequest) i32 {
        if (!self.hasFn("program_take_host_launch")) return -1;
        const program_fn: ProgramTakeHostLaunchFn = @ptrFromInt(self.table.program_take_host_launch);
        return program_fn(instance_id, out);
    }

    pub fn programWindowId(self: *const R4Desk) i32 {
        if (!self.hasFn("program_window_id")) return -1;
        const program_fn: ProgramWindowIdFn = @ptrFromInt(self.table.program_window_id);
        return program_fn();
    }

    pub fn guiWindowInfo(self: *const R4Desk, out: *abi.GuiWindowInfo) i32 {
        if (!self.hasFn("gui_window_info")) return -1;
        const gui_fn: GuiWindowInfoFn = @ptrFromInt(self.table.gui_window_info);
        return gui_fn(out);
    }

    pub fn guiSetWindowInfo(self: *const R4Desk, instance_id: u32, info: *const abi.GuiWindowInfo) i32 {
        if (!self.hasFn("gui_set_window_info")) return -1;
        const gui_fn: GuiSetWindowInfoFn = @ptrFromInt(self.table.gui_set_window_info);
        return gui_fn(instance_id, info);
    }

    pub fn guiPollEvent(self: *const R4Desk, out: *abi.GuiEvent) i32 {
        if (!self.hasFn("gui_poll_event")) return 0;
        const gui_fn: GuiPollEventFn = @ptrFromInt(self.table.gui_poll_event);
        return gui_fn(out);
    }

    pub fn guiPushEvent(self: *const R4Desk, instance_id: u32, event: *const abi.GuiEvent) i32 {
        if (!self.hasFn("gui_push_event")) return -1;
        const gui_fn: GuiPushEventFn = @ptrFromInt(self.table.gui_push_event);
        return gui_fn(instance_id, event);
    }

    pub fn guiSetText(self: *const R4Desk, value: [*:0]const u8) i32 {
        if (!self.hasFn("gui_set_text")) return -1;
        const gui_fn: GuiSetTextFn = @ptrFromInt(self.table.gui_set_text);
        return gui_fn(value);
    }

    pub fn guiText(self: *const R4Desk, instance_id: u32, out: []u8) i32 {
        if (!self.hasFn("gui_text") or out.len == 0) return -1;
        const gui_fn: BufferReadFn = @ptrFromInt(self.table.gui_text);
        return gui_fn(instance_id, out.ptr, @intCast(out.len));
    }

    pub fn guiRevision(self: *const R4Desk, instance_id: u32) u32 {
        if (!self.hasFn("gui_revision")) return 0;
        const gui_fn: RevisionFn = @ptrFromInt(self.table.gui_revision);
        return gui_fn(instance_id);
    }

    pub fn guiCommand(self: *const R4Desk, instance_id: u32, index: u32, out: *abi.GuiCommand) i32 {
        if (!self.hasFn("gui_command")) return -1;
        const gui_fn: GuiCommandFn = @ptrFromInt(self.table.gui_command);
        return gui_fn(instance_id, index, out);
    }

    pub fn guiSetTitle(self: *const R4Desk, value: [*:0]const u8) i32 {
        if (!self.hasFn("gui_set_title")) return -1;
        const gui_fn: GuiSetTitleFn = @ptrFromInt(self.table.gui_set_title);
        return gui_fn(value);
    }

    pub fn guiTitle(self: *const R4Desk, instance_id: u32, out: []u8) i32 {
        if (!self.hasFn("gui_title") or out.len == 0) return -1;
        const gui_fn: BufferReadFn = @ptrFromInt(self.table.gui_title);
        return gui_fn(instance_id, out.ptr, @intCast(out.len));
    }

    pub fn guiSetMinSize(self: *const R4Desk, w: i32, h: i32) i32 {
        if (!self.hasFn("gui_set_min_size")) return -1;
        const gui_fn: GuiSetMinSizeFn = @ptrFromInt(self.table.gui_set_min_size);
        return gui_fn(w, h);
    }

    pub fn guiMinSize(self: *const R4Desk, instance_id: u32, out: *abi.GuiSize) i32 {
        if (!self.hasFn("gui_min_size")) return -1;
        const gui_fn: GuiMinSizeFn = @ptrFromInt(self.table.gui_min_size);
        return gui_fn(instance_id, out);
    }

    pub fn consoleOutput(self: *const R4Desk, instance_id: u32, out: []u8) i32 {
        if (!self.hasFn("console_output") or out.len == 0) return -1;
        const console_fn: BufferReadFn = @ptrFromInt(self.table.console_output);
        return console_fn(instance_id, out.ptr, @intCast(out.len));
    }

    pub fn consoleRevision(self: *const R4Desk, instance_id: u32) u32 {
        if (!self.hasFn("console_revision")) return 0;
        const console_fn: RevisionFn = @ptrFromInt(self.table.console_revision);
        return console_fn(instance_id);
    }

    pub fn consoleState(self: *const R4Desk, instance_id: u32, out: *abi.ConsoleState) i32 {
        if (!self.hasFn("console_state")) return -1;
        const console_fn: ConsoleStateFn = @ptrFromInt(self.table.console_state);
        return console_fn(instance_id, out);
    }

    pub fn consoleSetMetrics(self: *const R4Desk, instance_id: u32, cols: u32, rows: u32) i32 {
        if (!self.hasFn("console_set_metrics")) return -1;
        const console_fn: ConsoleSetMetricsFn = @ptrFromInt(self.table.console_set_metrics);
        return console_fn(instance_id, cols, rows);
    }

    pub fn consolePushKey(self: *const R4Desk, instance_id: u32, key: u8) i32 {
        if (!self.hasFn("console_push_key")) return -1;
        const console_fn: ConsolePushKeyFn = @ptrFromInt(self.table.console_push_key);
        return console_fn(instance_id, key);
    }

    pub fn consolePushInput(self: *const R4Desk, instance_id: u32, data: []const u8) i32 {
        if (!self.hasFn("console_push_input") or data.len > std.math.maxInt(u32)) return -1;
        const console_fn: ConsolePushInputFn = @ptrFromInt(self.table.console_push_input);
        const data_ptr: [*]const u8 = if (data.len == 0) @ptrCast("") else data.ptr;
        return console_fn(instance_id, data_ptr, @intCast(data.len));
    }

    pub fn consoleWrite(self: *const R4Desk, stream: abi.ConsoleStream, data: []const u8) i32 {
        if (!self.hasFn("console_write")) return -1;
        if (data.len == 0) return 0;
        const console_fn: ConsoleWriteFn = @ptrFromInt(self.table.console_write);
        return console_fn(@intFromEnum(stream), data.ptr, @intCast(data.len));
    }

    pub fn stdout(self: *const R4Desk, data: []const u8) i32 {
        return self.consoleWrite(.stdout, data);
    }

    pub fn stderr(self: *const R4Desk, data: []const u8) i32 {
        return self.consoleWrite(.stderr, data);
    }

    pub fn consoleRead(self: *const R4Desk, out: []u8) i32 {
        if (!self.hasFn("console_read") or out.len == 0) return 0;
        const console_fn: ConsoleReadFn = @ptrFromInt(self.table.console_read);
        return console_fn(out.ptr, @intCast(out.len));
    }

    pub fn consoleInputWait(self: *const R4Desk, last_generation: u64, timeout_ticks: u64, out_generation: *u64) i32 {
        out_generation.* = last_generation;
        if (!self.hasFn("console_input_wait")) return abi.console_input_wait_error_unsupported;
        const console_fn: ConsoleInputWaitFn = @ptrFromInt(self.table.console_input_wait);
        return console_fn(last_generation, timeout_ticks, out_generation);
    }

    pub fn physicalKeyPoll(self: *const R4Desk, out: *abi.PhysicalKeyEvent) i32 {
        out.* = .{};
        if (!self.hasFn("physical_key_poll")) return abi.physical_key_poll_error_unsupported;
        const poll_fn: PhysicalKeyPollFn = @ptrFromInt(self.table.physical_key_poll);
        return poll_fn(out);
    }

    pub fn supportsClipboardContract(self: *const R4Desk) bool {
        return self.hasFn("clipboard_write") and self.hasFn("clipboard_read");
    }

    pub fn clipboardWrite(self: *const R4Desk, data: []const u8) i32 {
        if (!self.hasFn("clipboard_write")) return abi.clipboard_error_unsupported;
        const clipboard_fn: ClipboardWriteFn = @ptrFromInt(self.table.clipboard_write);
        const data_ptr = if (data.len == 0) @as([*]const u8, @ptrCast("")) else data.ptr;
        return clipboard_fn(data_ptr, @intCast(data.len));
    }

    pub fn clipboardRead(self: *const R4Desk, out: []u8) i32 {
        if (!self.hasFn("clipboard_read")) return abi.clipboard_error_unsupported;
        if (out.len == 0) return abi.clipboard_error_buffer_too_small;
        const clipboard_fn: ClipboardReadFn = @ptrFromInt(self.table.clipboard_read);
        return clipboard_fn(out.ptr, @intCast(out.len));
    }

    pub fn clipboardRevision(self: *const R4Desk) u32 {
        if (!self.hasFn("clipboard_revision")) return 0;
        const clipboard_fn: ClipboardRevisionFn = @ptrFromInt(self.table.clipboard_revision);
        return clipboard_fn();
    }

    pub fn clipboardInfo(self: *const R4Desk, out: *abi.ClipboardInfo) i32 {
        if (!self.hasFn("clipboard_info")) return abi.clipboard_error_unsupported;
        const clipboard_fn: ClipboardInfoFn = @ptrFromInt(self.table.clipboard_info);
        return clipboard_fn(out);
    }

    pub fn clipboardClear(self: *const R4Desk) i32 {
        if (self.hasFn("clipboard_clear")) {
            const clipboard_fn: *const fn () callconv(.c) i32 = @ptrFromInt(self.table.clipboard_clear);
            return clipboard_fn();
        }
        return self.clipboardWrite("");
    }

    pub fn supportsRemoteFrame(self: *const R4Desk) bool {
        return self.hasFn("remote_frame_info") and
            self.hasFn("remote_frame_read") and
            self.hasFn("remote_frame_wait") and
            self.hasFn("remote_frame_publish");
    }

    pub fn remoteFrameInfo(self: *const R4Desk, out: *abi.RemoteFrameInfo) i32 {
        if (!self.hasFn("remote_frame_info")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFrameInfoFn = @ptrFromInt(self.table.remote_frame_info);
        return frame_fn(out);
    }

    pub fn remoteFrameRead(self: *const R4Desk, offset_pixels: u32, out: []u32, out_info: *abi.RemoteFrameInfo) i32 {
        if (!self.hasFn("remote_frame_read")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFrameReadFn = @ptrFromInt(self.table.remote_frame_read);
        return frame_fn(offset_pixels, out.ptr, @intCast(out.len), out_info);
    }

    pub fn remoteFrameWait(self: *const R4Desk, last_revision: u32, timeout_ticks: u64, out: *abi.RemoteFrameInfo) i32 {
        if (!self.hasFn("remote_frame_wait")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFrameWaitFn = @ptrFromInt(self.table.remote_frame_wait);
        return frame_fn(last_revision, timeout_ticks, out);
    }

    pub fn desktopActivityWait(self: *const R4Desk, last_seq: u64, timeout_ticks: u64, out_seq: *u64) i32 {
        if (!self.hasFn("desktop_activity_wait")) return abi.remote_frame_error_unsupported;
        const wait_fn: *const fn (u64, u64, *u64) callconv(.c) i32 = @ptrFromInt(self.table.desktop_activity_wait);
        return wait_fn(last_seq, timeout_ticks, out_seq);
    }

    pub fn supportsRemoteFrameMap(self: *const R4Desk) bool {
        return self.hasFn("remote_frame_map");
    }

    pub fn remoteFrameMap(self: *const R4Desk, out: *abi.RemoteFrameMapInfo) i32 {
        if (!self.hasFn("remote_frame_map")) return abi.remote_frame_error_unsupported;
        const map_fn: *const fn (*abi.RemoteFrameMapInfo) callconv(.c) i32 = @ptrFromInt(self.table.remote_frame_map);
        return map_fn(out);
    }

    pub fn remoteFramePublish(self: *const R4Desk, info: *const abi.RemoteFrameInfo, pixels: []const u32) i32 {
        if (!self.hasFn("remote_frame_publish")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFramePublishFn = @ptrFromInt(self.table.remote_frame_publish);
        return frame_fn(info, pixels.ptr, @intCast(pixels.len));
    }

    pub fn supportsRemoteFrameRegions(self: *const R4Desk) bool {
        return self.hasFn("remote_frame_publish_regions");
    }

    pub fn remoteFramePublishRegions(self: *const R4Desk, info: *const abi.RemoteFrameInfo, pixels: []const u32, regions: []const abi.DisplayDamageRect) i32 {
        if (!self.hasFn("remote_frame_publish_regions")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFramePublishRegionsFn = @ptrFromInt(self.table.remote_frame_publish_regions);
        return frame_fn(info, pixels.ptr, @intCast(pixels.len), regions.ptr, @intCast(regions.len));
    }

    pub fn supportsRemoteFrameDemand(self: *const R4Desk) bool {
        return self.hasFn("remote_frame_acquire") and
            self.hasFn("remote_frame_release") and
            self.hasFn("remote_frame_consumers");
    }

    pub fn remoteFrameAcquire(self: *const R4Desk) i32 {
        if (!self.hasFn("remote_frame_acquire")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFrameAcquireFn = @ptrFromInt(self.table.remote_frame_acquire);
        return frame_fn();
    }

    pub fn remoteFrameRelease(self: *const R4Desk) i32 {
        if (!self.hasFn("remote_frame_release")) return abi.remote_frame_error_unsupported;
        const frame_fn: RemoteFrameReleaseFn = @ptrFromInt(self.table.remote_frame_release);
        return frame_fn();
    }

    pub fn remoteFrameConsumers(self: *const R4Desk) u32 {
        if (!self.hasFn("remote_frame_consumers")) return 0;
        const frame_fn: RemoteFrameConsumersFn = @ptrFromInt(self.table.remote_frame_consumers);
        return frame_fn();
    }

    pub fn supportsRemoteInput(self: *const R4Desk) bool {
        return self.hasFn("remote_input_push") and
            self.hasFn("remote_input_poll") and
            self.hasFn("remote_input_status");
    }

    pub fn remoteInputPush(self: *const R4Desk, event: *const abi.RemoteInputEvent) i32 {
        if (!self.hasFn("remote_input_push")) return abi.remote_input_error_unsupported;
        const input_fn: RemoteInputPushFn = @ptrFromInt(self.table.remote_input_push);
        return input_fn(event);
    }

    pub fn remoteInputPoll(self: *const R4Desk, out: *abi.RemoteInputEvent) i32 {
        if (!self.hasFn("remote_input_poll")) return abi.remote_input_error_unsupported;
        const input_fn: RemoteInputPollFn = @ptrFromInt(self.table.remote_input_poll);
        return input_fn(out);
    }

    pub fn remoteInputStatus(self: *const R4Desk, out: *abi.RemoteInputStatus) i32 {
        if (!self.hasFn("remote_input_status")) return abi.remote_input_error_unsupported;
        const input_fn: RemoteInputStatusFn = @ptrFromInt(self.table.remote_input_status);
        return input_fn(out);
    }
};

pub const R4Draw = struct {
    raw: *const abi.R4XStartContext,
    table: *const abi.R4XStartR4Draw,

    pub fn hasFn(self: *const R4Draw, comptime field: []const u8) bool {
        const end = @offsetOf(abi.R4XStartR4Draw, field) + @sizeOf(usize);
        return self.table.size >= end and @field(self.table.*, field) != 0;
    }

    pub fn screenWidth(self: *const R4Draw) u32 {
        if (!self.hasFn("screen_width")) return 0;
        const screen_fn: ScreenSizeFn = @ptrFromInt(self.table.screen_width);
        return screen_fn();
    }

    pub fn screenHeight(self: *const R4Draw) u32 {
        if (!self.hasFn("screen_height")) return 0;
        const screen_fn: ScreenSizeFn = @ptrFromInt(self.table.screen_height);
        return screen_fn();
    }

    pub fn clear(self: *const R4Draw, rgb: u32) void {
        if (!self.hasFn("clear")) return;
        const draw_fn: ClearFn = @ptrFromInt(self.table.clear);
        draw_fn(rgb);
    }

    pub fn rect(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32, rgb: u32) void {
        if (!self.hasFn("rect")) return;
        const draw_fn: RectFn = @ptrFromInt(self.table.rect);
        draw_fn(x, y, w, h, rgb);
    }

    pub fn text(self: *const R4Draw, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) void {
        if (!self.hasFn("text")) return;
        const draw_fn: TextFn = @ptrFromInt(self.table.text);
        draw_fn(x, y, value, fg, bg);
    }

    pub fn displayRevision(self: *const R4Draw) u32 {
        if (!self.hasFn("display_revision")) return 0;
        const display_fn: DisplayRevisionFn = @ptrFromInt(self.table.display_revision);
        return display_fn();
    }

    pub fn displayBeginFrame(self: *const R4Draw) i32 {
        if (!self.hasFn("display_begin_frame")) return -1;
        const display_fn: DisplayBeginFrameFn = @ptrFromInt(self.table.display_begin_frame);
        return display_fn();
    }

    pub fn displayBeginFrameRect(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32) i32 {
        if (!self.hasFn("display_begin_frame_rect")) return -1;
        const display_fn: DisplayBeginFrameRectFn = @ptrFromInt(self.table.display_begin_frame_rect);
        return display_fn(x, y, w, h);
    }

    pub fn displayPresent(self: *const R4Draw) i32 {
        if (!self.hasFn("display_present")) return -1;
        const display_fn: DisplayPresentFn = @ptrFromInt(self.table.display_present);
        return display_fn();
    }

    pub fn displayBlitXrgb32(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32, pixels: []const u32) i32 {
        if (!self.hasFn("display_blit_xrgb32")) return -2;
        if (pixels.len == 0) return -1;
        const display_fn: DisplayBlitFn = @ptrFromInt(self.table.display_blit_xrgb32);
        return display_fn(x, y, w, h, pixels.ptr, @intCast(pixels.len));
    }

    pub fn displayBlitXrgb32Stride(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32, source_stride_pixels: u32, pixels: []const u32) i32 {
        if (!self.hasFn("display_blit_xrgb32_stride")) return -2;
        if (pixels.len == 0) return -1;
        const display_fn: DisplayBlitStrideFn = @ptrFromInt(self.table.display_blit_xrgb32_stride);
        return display_fn(x, y, w, h, pixels.ptr, @intCast(pixels.len), source_stride_pixels);
    }

    pub fn supportsDisplayPresentRegions(self: *const R4Draw) bool {
        return self.hasFn("display_present_regions") and
            self.hasFn("display_present_capabilities") and
            self.hasFn("display_present_completion");
    }

    pub fn displayPresentRegions(self: *const R4Draw, request: *const abi.DisplayPresentRequest, pixels: []const u32, regions: []const abi.DisplayDamageRect, out: *abi.DisplayPresentResult) i32 {
        if (!self.hasFn("display_present_regions")) return abi.display_present_error_unavailable;
        const display_fn: DisplayPresentRegionsFn = @ptrFromInt(self.table.display_present_regions);
        return display_fn(request, pixels.ptr, @intCast(pixels.len), regions.ptr, @intCast(regions.len), out);
    }

    pub fn displayPresentCapabilities(self: *const R4Draw, out: *abi.DisplayPresentCapabilities) i32 {
        if (!self.hasFn("display_present_capabilities")) return abi.display_present_error_unavailable;
        const display_fn: DisplayPresentCapabilitiesFn = @ptrFromInt(self.table.display_present_capabilities);
        return display_fn(out);
    }

    pub fn displayPresentCompletion(self: *const R4Draw, fence: u64, out: *abi.DisplayPresentCompletion) i32 {
        if (!self.hasFn("display_present_completion")) return abi.display_present_error_unavailable;
        const display_fn: DisplayPresentCompletionFn = @ptrFromInt(self.table.display_present_completion);
        return display_fn(fence, out);
    }

    pub fn guiClear(self: *const R4Draw, rgb: u32) i32 {
        if (!self.hasFn("gui_clear")) return -1;
        const gui_fn: GuiClearFn = @ptrFromInt(self.table.gui_clear);
        return gui_fn(rgb);
    }

    pub fn guiRect(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32, rgb: u32) i32 {
        if (!self.hasFn("gui_rect")) return -1;
        const gui_fn: GuiRectFn = @ptrFromInt(self.table.gui_rect);
        return gui_fn(x, y, w, h, rgb);
    }

    pub fn guiDrawText(self: *const R4Draw, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) i32 {
        if (!self.hasFn("gui_draw_text")) return -1;
        const gui_fn: GuiDrawTextFn = @ptrFromInt(self.table.gui_draw_text);
        return gui_fn(x, y, value, fg, bg);
    }

    pub fn guiDrawTextEx(self: *const R4Draw, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32, font_id: u32, flags: u32) i32 {
        if (!self.hasFn("gui_draw_text_ex")) return self.guiDrawText(x, y, value, fg, bg);
        const gui_fn: GuiDrawTextExFn = @ptrFromInt(self.table.gui_draw_text_ex);
        return gui_fn(x, y, value, fg, bg, font_id, flags);
    }

    pub fn guiBlit(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32, scale: u32, pixels: []const u32) i32 {
        if (!self.hasFn("gui_blit")) return -4;
        if (pixels.len == 0) return -1;
        const gui_fn: GuiBlitFn = @ptrFromInt(self.table.gui_blit);
        return gui_fn(x, y, w, h, scale, pixels.ptr, @intCast(pixels.len));
    }

    pub fn guiBlendAlpha8(self: *const R4Draw, x: i32, y: i32, w: u32, h: u32, stride: u32, rgb: u32, alpha: []const u8) i32 {
        if (!self.hasFn("gui_blend_alpha8")) return -4;
        if (alpha.len == 0 or alpha.len > std.math.maxInt(u32)) return -1;
        const gui_fn: GuiBlendAlpha8Fn = @ptrFromInt(self.table.gui_blend_alpha8);
        return gui_fn(x, y, w, h, stride, rgb, alpha.ptr, @intCast(alpha.len));
    }

    pub fn guiRasterRead(self: *const R4Draw, instance_id: u32, offset: u32, out: []u32) i32 {
        if (!self.hasFn("gui_raster_read")) return -4;
        if (out.len == 0) return 0;
        const gui_fn: GuiRasterReadFn = @ptrFromInt(self.table.gui_raster_read);
        return gui_fn(instance_id, offset, out.ptr, @intCast(out.len));
    }

    pub fn supportsGuiFrameContract(self: *const R4Draw) bool {
        return self.hasFn("gui_frame_begin") and
            self.hasFn("gui_frame_append") and
            self.hasFn("gui_frame_commit") and
            self.hasFn("gui_frame_cancel") and
            self.hasFn("gui_frame_info") and
            self.hasFn("gui_frame_read");
    }

    pub fn supportsGuiFrameDamageContract(self: *const R4Draw) bool {
        return self.supportsGuiFrameContract() and
            self.hasFn("gui_frame_begin_damage") and
            self.hasFn("gui_frame_generation_info") and
            self.hasFn("gui_frame_generation_read");
    }

    pub fn supportsGuiFrameStreamingContract(self: *const R4Draw) bool {
        return self.supportsGuiFrameDamageContract() and
            self.hasFn("gui_frame_begin_replace") and
            self.hasFn("gui_frame_stream_info");
    }

    pub fn guiFrameBegin(self: *const R4Draw) i32 {
        if (!self.hasFn("gui_frame_begin")) return abi.err_no_fn;
        const gui_fn: GuiFrameBeginFn = @ptrFromInt(self.table.gui_frame_begin);
        return gui_fn();
    }

    pub fn guiFrameBeginDamage(self: *const R4Draw, regions: []const abi.DisplayDamageRect) i32 {
        if (!self.hasFn("gui_frame_begin_damage")) return abi.err_no_fn;
        if (regions.len == 0 or regions.len > abi.gui_frame_max_damage_regions) return abi.gui_frame_error_invalid;
        const gui_fn: GuiFrameBeginDamageFn = @ptrFromInt(self.table.gui_frame_begin_damage);
        return gui_fn(regions.ptr, @intCast(regions.len));
    }

    pub fn guiFrameBeginReplace(self: *const R4Draw, regions: []const abi.DisplayDamageRect) i32 {
        if (!self.hasFn("gui_frame_begin_replace")) return abi.err_no_fn;
        if (regions.len == 0 or regions.len > abi.gui_frame_max_damage_regions) return abi.gui_frame_error_invalid;
        const gui_fn: GuiFrameBeginReplaceFn = @ptrFromInt(self.table.gui_frame_begin_replace);
        return gui_fn(regions.ptr, @intCast(regions.len));
    }

    pub fn guiFrameAppend(self: *const R4Draw, commands: []const abi.GuiFrameCommand, resources: []const u8) i32 {
        if (!self.hasFn("gui_frame_append")) return abi.err_no_fn;
        const command_ptr: ?[*]const abi.GuiFrameCommand = if (commands.len == 0) null else commands.ptr;
        const resource_ptr: ?[*]const u8 = if (resources.len == 0) null else resources.ptr;
        const gui_fn: GuiFrameAppendFn = @ptrFromInt(self.table.gui_frame_append);
        return gui_fn(command_ptr, @intCast(commands.len), resource_ptr, @intCast(resources.len));
    }

    pub fn guiFrameCommit(self: *const R4Draw) i32 {
        if (!self.hasFn("gui_frame_commit")) return abi.err_no_fn;
        const gui_fn: GuiFrameCommitFn = @ptrFromInt(self.table.gui_frame_commit);
        return gui_fn();
    }

    pub fn guiFrameCancel(self: *const R4Draw) i32 {
        if (!self.hasFn("gui_frame_cancel")) return abi.err_no_fn;
        const gui_fn: GuiFrameCancelFn = @ptrFromInt(self.table.gui_frame_cancel);
        return gui_fn();
    }

    pub fn guiFrameInfo(self: *const R4Draw, handle: ?*const abi.ProgramProcessHandle, out: *abi.GuiFrameInfo) i32 {
        if (!self.hasFn("gui_frame_info")) return abi.err_no_fn;
        const gui_fn: GuiFrameInfoFn = @ptrFromInt(self.table.gui_frame_info);
        out.version = abi.gui_frame_info_version;
        out.size = abi.gui_frame_info_size;
        return gui_fn(handle, out);
    }

    pub fn guiFrameRead(self: *const R4Draw, handle: *const abi.ProgramProcessHandle, expected_generation: u64, commands: []abi.GuiFrameCommand, resources: []u8, out: *abi.GuiFrameInfo) i32 {
        if (!self.hasFn("gui_frame_read")) return abi.err_no_fn;
        const command_ptr: ?[*]abi.GuiFrameCommand = if (commands.len == 0) null else commands.ptr;
        const resource_ptr: ?[*]u8 = if (resources.len == 0) null else resources.ptr;
        const gui_fn: GuiFrameReadFn = @ptrFromInt(self.table.gui_frame_read);
        out.version = abi.gui_frame_info_version;
        out.size = abi.gui_frame_info_size;
        return gui_fn(handle, expected_generation, command_ptr, @intCast(commands.len), resource_ptr, @intCast(resources.len), out);
    }

    pub fn guiFrameGenerationInfo(self: *const R4Draw, handle: *const abi.ProgramProcessHandle, generation: u64, out: *abi.GuiFrameGenerationInfo) i32 {
        if (!self.hasFn("gui_frame_generation_info")) return abi.err_no_fn;
        const gui_fn: GuiFrameGenerationInfoFn = @ptrFromInt(self.table.gui_frame_generation_info);
        out.version = abi.gui_frame_generation_info_version;
        out.size = abi.gui_frame_generation_info_size;
        return gui_fn(handle, generation, out);
    }

    pub fn guiFrameGenerationRead(self: *const R4Draw, handle: *const abi.ProgramProcessHandle, generation: u64, commands: []abi.GuiFrameCommand, resources: []u8, regions: []abi.DisplayDamageRect, out: *abi.GuiFrameGenerationInfo) i32 {
        if (!self.hasFn("gui_frame_generation_read")) return abi.err_no_fn;
        const command_ptr: ?[*]abi.GuiFrameCommand = if (commands.len == 0) null else commands.ptr;
        const resource_ptr: ?[*]u8 = if (resources.len == 0) null else resources.ptr;
        const region_ptr: ?[*]abi.DisplayDamageRect = if (regions.len == 0) null else regions.ptr;
        const gui_fn: GuiFrameGenerationReadFn = @ptrFromInt(self.table.gui_frame_generation_read);
        out.version = abi.gui_frame_generation_info_version;
        out.size = abi.gui_frame_generation_info_size;
        return gui_fn(handle, generation, command_ptr, @intCast(commands.len), resource_ptr, @intCast(resources.len), region_ptr, @intCast(regions.len), out);
    }

    pub fn guiFrameStreamInfo(self: *const R4Draw, handle: *const abi.ProgramProcessHandle, out: *abi.GuiFrameStreamInfo) i32 {
        if (!self.hasFn("gui_frame_stream_info")) return abi.err_no_fn;
        const gui_fn: GuiFrameStreamInfoFn = @ptrFromInt(self.table.gui_frame_stream_info);
        out.version = abi.gui_frame_stream_info_version;
        out.size = abi.gui_frame_stream_info_size;
        return gui_fn(handle, out);
    }

    pub fn guiPresent(self: *const R4Draw) i32 {
        if (!self.hasFn("gui_present")) return -1;
        const gui_fn: DisplayPresentFn = @ptrFromInt(self.table.gui_present);
        return gui_fn();
    }

    pub fn supportsGuiFonts(self: *const R4Draw) bool {
        return self.hasFn("font_count") and self.hasFn("font_info") and self.hasFn("font_measure");
    }

    pub fn supportsGuiRaster(self: *const R4Draw) bool {
        return self.hasFn("gui_blit") and self.hasFn("gui_raster_read");
    }

    pub fn fontCount(self: *const R4Draw) u32 {
        if (!self.hasFn("font_count")) return 1;
        const font_fn: FontCountFn = @ptrFromInt(self.table.font_count);
        return font_fn();
    }

    pub fn fontInfo(self: *const R4Draw, font_id: u32, out: *abi.GuiFontInfo) i32 {
        if (!self.hasFn("font_info")) return fallbackFontInfo(font_id, out);
        const font_fn: FontInfoFn = @ptrFromInt(self.table.font_info);
        return font_fn(font_id, out);
    }

    pub fn fontMeasure(self: *const R4Draw, font_id: u32, value: [*:0]const u8, out: *abi.GuiTextMetrics) i32 {
        if (!self.hasFn("font_measure")) {
            out.* = fallbackTextMetrics(value);
            return 0;
        }
        const font_fn: FontMeasureFn = @ptrFromInt(self.table.font_measure);
        return font_fn(font_id, value, out);
    }

    pub fn fontGlyphRow(self: *const R4Draw, font_id: u32, codepoint: u32, row: u32) u64 {
        if (!self.hasFn("font_glyph_row")) return 0;
        const font_fn: FontGlyphRowFn = @ptrFromInt(self.table.font_glyph_row);
        return font_fn(font_id, codepoint, row);
    }

    /// Retrieves one complete glyph snapshot. R4DRAW-v6 resolves and copies
    /// it in one call; older tables are supported through their bounded row
    /// query. The legacy fallback cannot recover proportional per-glyph
    /// metrics, so it reports the face width and maximum advance.
    pub fn fontGlyphBitmap(self: *const R4Draw, font_id: u32, codepoint: u32, out: *abi.GuiGlyphBitmap) i32 {
        if (codepoint > 0x10FFFF) return -1;
        if (self.hasFn("font_glyph_bitmap")) {
            const font_fn: FontGlyphBitmapFn = @ptrFromInt(self.table.font_glyph_bitmap);
            return font_fn(font_id, codepoint, out);
        }
        if (!self.hasFn("font_glyph_row")) return abi.err_no_fn;

        var info: abi.GuiFontInfo = .{};
        const info_result = self.fontInfo(font_id, &info);
        if (info_result <= 0) return if (info_result < 0) info_result else -2;
        var bitmap = abi.GuiGlyphBitmap{
            .width = @min(info.width, 64),
            .height = @min(info.height, @as(u32, bitmap_row_capacity)),
            .advance = info.max_advance,
            .line_height = info.line_height,
            .baseline = info.baseline,
        };
        var row: u32 = 0;
        while (row < bitmap.height) : (row += 1) bitmap.rows[row] = self.fontGlyphRow(font_id, codepoint, row);
        out.* = bitmap;
        return 0;
    }

    /// Returns the generation paired with live font ids. Legacy tables use a
    /// stable generation because they cannot report catalogue reloads.
    pub fn fontRevision(self: *const R4Draw) u32 {
        if (!self.hasFn("font_revision")) return 1;
        const font_fn: FontRevisionFn = @ptrFromInt(self.table.font_revision);
        const revision = font_fn();
        return if (revision == 0) 1 else revision;
    }

    pub fn fontReload(self: *const R4Draw) i32 {
        if (!self.hasFn("font_reload")) return -1;
        const font_fn: FontReloadFn = @ptrFromInt(self.table.font_reload);
        return font_fn();
    }

    pub fn guiSetFont(self: *const R4Draw, font_id: u32) i32 {
        if (!self.hasFn("gui_set_font")) return if (font_id == abi.gui_font_builtin_id) 0 else -2;
        const font_fn: GuiSetFontFn = @ptrFromInt(self.table.gui_set_font);
        return font_fn(font_id);
    }

    pub fn guiFont(self: *const R4Draw, instance_id: u32, out: *abi.GuiFontInfo) i32 {
        if (!self.hasFn("gui_font")) {
            return fallbackFontInfo(abi.gui_font_builtin_id, out);
        }
        const font_fn: GuiFontFn = @ptrFromInt(self.table.gui_font);
        return font_fn(instance_id, out);
    }

    pub fn textFont(self: *const R4Draw, font_id: u32, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) void {
        if (!self.hasFn("text_font")) {
            self.text(x, y, value, fg, bg);
            return;
        }
        const text_fn: TextFontFn = @ptrFromInt(self.table.text_font);
        text_fn(font_id, x, y, value, fg, bg);
    }
};

fn fallbackFontInfo(font_id: u32, out: *abi.GuiFontInfo) i32 {
    if (font_id != abi.gui_font_builtin_id) return 0;
    out.* = .{
        .id = abi.gui_font_builtin_id,
        .kind = 0,
        .flags = abi.gui_font_flag_renderable | abi.gui_font_flag_builtin,
        .weight = 400,
        .width = 8,
        .height = 8,
        .max_advance = 8,
        .line_height = 8,
        .baseline = 7,
        .glyph_count = 95,
        .strike_count = 1,
    };
    copyFixedZ(out.family[0..], "R4OS");
    copyFixedZ(out.face[0..], "Builtin 8x8");
    copyFixedZ(out.style[0..], "Regular");
    copyFixedZ(out.status[0..], "builtin fallback");
    return 1;
}

fn fallbackTextMetrics(value: [*:0]const u8) abi.GuiTextMetrics {
    var line_w: u32 = 0;
    var max_w: u32 = 0;
    var lines: u32 = 1;
    var visible: u32 = 0;
    var index: usize = 0;
    while (index < 4096 and value[index] != 0) {
        const ch = value[index];
        const consumed = fallbackUtf8SequenceLength(value, index, 4096);
        index += consumed;
        if (ch == '\r') continue;
        if (ch == '\n') {
            max_w = @max(max_w, line_w);
            line_w = 0;
            lines += 1;
            visible += @intCast(consumed);
            continue;
        }
        line_w += 8;
        visible += @intCast(consumed);
    }
    max_w = @max(max_w, line_w);
    return .{
        .width = max_w,
        .height = lines * 8,
        .line_height = 8,
        .baseline = 7,
        .visible_bytes = visible,
        .flags = 0,
    };
}

fn fallbackUtf8SequenceLength(value: [*:0]const u8, start: usize, limit: usize) usize {
    const first = value[start];
    if (first < 0x80) return 1;
    const expected: usize = if (first >= 0xC2 and first <= 0xDF)
        2
    else if (first >= 0xE0 and first <= 0xEF)
        3
    else if (first >= 0xF0 and first <= 0xF4)
        4
    else
        return 1;
    if (expected > limit -| start) return 1;
    var offset: usize = 1;
    while (offset < expected) : (offset += 1) {
        if (value[start + offset] == 0 or (value[start + offset] & 0xC0) != 0x80) return 1;
    }
    if (first == 0xE0 and value[start + 1] < 0xA0) return 1;
    if (first == 0xED and value[start + 1] >= 0xA0) return 1;
    if (first == 0xF0 and value[start + 1] < 0x90) return 1;
    if (first == 0xF4 and value[start + 1] >= 0x90) return 1;
    return expected;
}

fn copyFixedZ(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const count = @min(value.len, out.len - 1);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
}

const bitmap_row_capacity: usize = @typeInfo(@TypeOf((abi.GuiGlyphBitmap{}).rows)).array.len;

fn testBulkGlyphBitmap(_: u32, _: u32, out: *abi.GuiGlyphBitmap) callconv(.c) i32 {
    out.* = .{
        .width = 7,
        .height = 2,
        .advance = 9,
        .line_height = 12,
        .baseline = 10,
        .rows = .{ 0x55, 0x2A } ++ .{0} ** (bitmap_row_capacity - 2),
    };
    return 0;
}

fn testFontRevision() callconv(.c) u32 {
    return 19;
}

fn testLegacyFontInfo(font_id: u32, out: *abi.GuiFontInfo) callconv(.c) i32 {
    if (font_id != 7) return 0;
    out.* = .{
        .id = font_id,
        .flags = abi.gui_font_flag_renderable,
        .width = 11,
        .height = 3,
        .max_advance = 12,
        .line_height = 4,
        .baseline = 2,
    };
    return 1;
}

fn testLegacyGlyphRow(_: u32, _: u32, row: u32) callconv(.c) u64 {
    return @as(u64, 1) << @intCast(row);
}

test "R4DRAW bulk glyph dispatch and legacy row fallback stay compatible" {
    var current_table = abi.R4XStartR4Draw{
        .font_glyph_bitmap = @intFromPtr(&testBulkGlyphBitmap),
        .font_revision = @intFromPtr(&testFontRevision),
    };
    const current = R4Draw{ .table = &current_table };
    var bitmap: abi.GuiGlyphBitmap = .{};
    try std.testing.expectEqual(@as(i32, 0), current.fontGlyphBitmap(0, 'A', &bitmap));
    try std.testing.expectEqual(@as(u32, 7), bitmap.width);
    try std.testing.expectEqual(@as(u64, 0x55), bitmap.rows[0]);
    try std.testing.expectEqual(@as(u64, 0x2A), bitmap.rows[1]);
    try std.testing.expectEqual(@as(u32, 19), current.fontRevision());

    var legacy_table = abi.R4XStartR4Draw{
        .abi_version = 5,
        .size = @intCast(@offsetOf(abi.R4XStartR4Draw, "font_glyph_bitmap")),
        .font_info = @intFromPtr(&testLegacyFontInfo),
        .font_glyph_row = @intFromPtr(&testLegacyGlyphRow),
    };
    const legacy = R4Draw{ .table = &legacy_table };
    bitmap = .{};
    try std.testing.expect(!legacy.hasFn("font_glyph_bitmap"));
    try std.testing.expect(!legacy.hasFn("font_revision"));
    try std.testing.expectEqual(@as(u32, 1), legacy.fontRevision());
    try std.testing.expectEqual(@as(i32, 0), legacy.fontGlyphBitmap(7, 0x1F642, &bitmap));
    try std.testing.expectEqual(@as(u32, 11), bitmap.width);
    try std.testing.expectEqual(@as(u32, 3), bitmap.height);
    try std.testing.expectEqual(@as(u32, 12), bitmap.advance);
    try std.testing.expectEqual(@as(i32, 2), bitmap.baseline);
    try std.testing.expectEqual(@as(u64, 1), bitmap.rows[0]);
    try std.testing.expectEqual(@as(u64, 2), bitmap.rows[1]);
    try std.testing.expectEqual(@as(u64, 4), bitmap.rows[2]);
    try std.testing.expectEqual(@as(u64, 0), bitmap.rows[3]);
}
