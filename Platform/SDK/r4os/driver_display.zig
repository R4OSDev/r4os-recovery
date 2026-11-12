const abi = @import("r4os_contract").abi;
pub const Context = struct {
    table: abi.GfxDriverDisplayApi,
    pub fn supportsHeadlessResume(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "resume_headless") + 8 and
            self.table.resume_headless != 0;
    }
    pub fn resumeHeadless(self: *const Context, input: *const abi.GfxBackendBinding, generation: u64, output: *abi.GfxNativeState) i32 {
        if (!self.supportsHeadlessResume()) return abi.err_no_fn;
        output.* = .{};
        const callback: *const fn (*const abi.GfxBackendBinding, u64, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.resume_headless);
        return callback(input, generation, output);
    }
    pub fn supportsTerminalRelease(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "terminal_release") + 8 and
            self.table.terminal_release != 0;
    }
    pub fn releaseTerminal(self: *const Context, backend: *const abi.GfxBackendBinding, reset_generation: u64, output: *abi.GfxNativeState) i32 {
        if (!self.supportsTerminalRelease()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxNativeState);
        const callback: *const fn (*const abi.GfxBackendBinding, u64, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.terminal_release);
        return callback(backend, reset_generation, output);
    }
    pub fn supportsReset(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "prepare_reset") + 8 and
            self.table.device_reset != 0 and self.table.prepare_reset != 0;
    }
    pub fn deviceReset(self: *const Context, backend: *const abi.GfxBackendBinding, generation: u64, quiesced: bool, output: *abi.GfxNativeState) i32 {
        if (!self.supportsReset()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxNativeState);
        const callback: *const fn (*const abi.GfxBackendBinding, u64, u32, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.device_reset);
        return callback(backend, generation, @intFromBool(quiesced), output);
    }
    pub fn prepareReset(self: *const Context, input: *const abi.GfxNativeRegistration, held_generation: u64, reset_generation: u64, output: *abi.GfxNativeState) i32 {
        if (!self.supportsReset()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxNativeState);
        const callback: *const fn (*const abi.GfxNativeRegistration, u64, u64, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.prepare_reset);
        return callback(input, held_generation, reset_generation, output);
    }
    pub fn supportsOutputs(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "output_transition") + 8 and
            self.table.output_register != 0 and self.table.output_transition != 0;
    }
    pub fn outputRegister(self: *const Context, input: *const abi.GfxAdditionalOutput, output: *abi.GfxOutputTarget) i32 {
        if (!self.supportsOutputs()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxOutputTarget);
        const callback: *const fn (*const abi.GfxAdditionalOutput, *abi.GfxOutputTarget) callconv(.c) i32 = @ptrFromInt(self.table.output_register);
        return callback(input, output);
    }
    pub fn outputTransition(self: *const Context, input: *const abi.GfxOutputTarget, operation: u32, quiesced: bool) i32 {
        if (!self.supportsOutputs()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputTarget, u32, u32) callconv(.c) i32 = @ptrFromInt(self.table.output_transition);
        return callback(input, operation, @intFromBool(quiesced));
    }
    pub fn supportsCursor(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "cursor_complete") + 8 and
            self.table.cursor_configure != 0 and self.table.cursor_take != 0 and self.table.cursor_complete != 0;
    }
    pub fn cursorConfigure(self: *const Context, input: *const abi.DisplayCursorInfo) i32 {
        if (!self.supportsCursor()) return abi.err_no_fn;
        const callback: *const fn (*const abi.DisplayCursorInfo) callconv(.c) i32 = @ptrFromInt(self.table.cursor_configure);
        return callback(input);
    }
    pub fn cursorTake(self: *const Context, backend: *const abi.GfxBackendBinding, out: *abi.GfxDriverCursorJob) i32 {
        if (!self.supportsCursor()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding, *abi.GfxDriverCursorJob) callconv(.c) i32 = @ptrFromInt(self.table.cursor_take);
        return callback(backend, out);
    }
    pub fn cursorComplete(self: *const Context, input: *const abi.GfxDriverCursorCompletion) i32 {
        if (!self.supportsCursor()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxDriverCursorCompletion) callconv(.c) i32 = @ptrFromInt(self.table.cursor_complete);
        return callback(input);
    }
    pub fn supportsPresentationStats(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "presentation_stats") + 8 and self.table.presentation_stats != 0;
    }
    pub fn supportsPresentationInfo(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverDisplayApi, "presentation_info") + 8 and self.table.presentation_info != 0;
    }
    pub fn presentationInfo(self: *const Context, input: *const abi.DisplayPresentationInfo) i32 {
        if (!self.supportsPresentationInfo()) return abi.err_no_fn;
        const callback: *const fn (*const abi.DisplayPresentationInfo) callconv(.c) i32 = @ptrFromInt(self.table.presentation_info);
        return callback(input);
    }
    pub fn presentationStats(self: *const Context, input: *const abi.DisplayPresentationStats) i32 {
        if (!self.supportsPresentationStats()) return abi.err_no_fn;
        const callback: *const fn (*const abi.DisplayPresentationStats) callconv(.c) i32 = @ptrFromInt(self.table.presentation_stats);
        return callback(input);
    }
    pub fn bootHold(self: *const Context, input: *const abi.GfxBootHoldRequest, output: *abi.GfxNativeState) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "boot_hold") + 8 or self.table.boot_hold == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBootHoldRequest, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.boot_hold);
        return callback(input, output);
    }
    pub fn bootFinish(self: *const Context, generation: u64, operation: u32, output: *abi.GfxNativeState) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "boot_finish") + 8 or self.table.boot_finish == 0) return abi.err_no_fn;
        const callback: *const fn (u64, u32, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.boot_finish);
        return callback(generation, operation, output);
    }
    pub fn schedule(self: *const Context, input: *const abi.GfxBackendBinding) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "schedule") + 8 or self.table.schedule == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding) callconv(.c) i32 = @ptrFromInt(self.table.schedule);
        return callback(input);
    }
    pub fn bootInfo(self: *const Context, output: *abi.GfxNativeBootInfo) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "boot_info") + 8 or self.table.boot_info == 0) return abi.err_no_fn;
        const callback: *const fn (*abi.GfxNativeBootInfo) callconv(.c) i32 = @ptrFromInt(self.table.boot_info);
        return callback(output);
    }
    pub fn prepare(self: *const Context, input: *const abi.GfxNativeRegistration, output: *abi.GfxNativeState) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "prepare") + 8 or self.table.prepare == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxNativeRegistration, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.prepare);
        return callback(input, output);
    }
    pub fn prepareHeld(self: *const Context, input: *const abi.GfxNativeRegistration, generation: u64, output: *abi.GfxNativeState) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "prepare_held") + 8 or self.table.prepare_held == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxNativeRegistration, u64, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.prepare_held);
        return callback(input, generation, output);
    }
    pub fn transition(self: *const Context, generation: u64, operation: u32, output: *abi.GfxNativeState) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverDisplayApi, "transition") + 8 or self.table.transition == 0) return abi.err_no_fn;
        const callback: *const fn (u64, u32, *abi.GfxNativeState) callconv(.c) i32 = @ptrFromInt(self.table.transition);
        return callback(generation, operation, output);
    }
};
