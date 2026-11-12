const abi = @import("r4os_contract").abi;
pub const Context = struct {
    pub fn supportsPower(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "power_read") + 8 and
            self.table.power_publish != 0 and self.table.power_read != 0;
    }
    pub fn publishPower(self: *const Context, input: *const abi.GfxOutputPower) i32 {
        if (!self.supportsPower()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputPower) callconv(.c) i32 = @ptrFromInt(self.table.power_publish);
        return callback(input);
    }
    pub fn readPower(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxPowerRequest) i32 {
        if (!self.supportsPower()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputId, *abi.GfxPowerRequest) callconv(.c) i32 = @ptrFromInt(self.table.power_read);
        var value: abi.GfxPowerRequest = .{};
        const code = callback(identity, &value);
        if (code == abi.gfx_output_ok) output.* = value;
        return code;
    }
    pub fn supportsBrightness(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "brightness_read") + 8 and
            self.table.brightness_publish != 0 and self.table.brightness_read != 0;
    }
    pub fn publishBrightness(self: *const Context, input: *const abi.GfxOutputBrightness) i32 {
        if (!self.supportsBrightness()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputBrightness) callconv(.c) i32 = @ptrFromInt(self.table.brightness_publish);
        return callback(input);
    }
    pub fn readBrightness(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxBrightnessRequest) i32 {
        if (!self.supportsBrightness()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputId, *abi.GfxBrightnessRequest) callconv(.c) i32 = @ptrFromInt(self.table.brightness_read);
        var value: abi.GfxBrightnessRequest = .{};
        const code = callback(identity, &value);
        if (code == abi.gfx_output_ok) output.* = value;
        return code;
    }
    pub fn supportsRefresh(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "refresh_read") + 8 and
            self.table.refresh_publish != 0 and self.table.refresh_read != 0;
    }
    pub fn publishRefresh(self: *const Context, input: *const abi.GfxOutputRefresh) i32 {
        if (!self.supportsRefresh()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputRefresh) callconv(.c) i32 = @ptrFromInt(self.table.refresh_publish);
        return callback(input);
    }
    pub fn readRefresh(self: *const Context, target: *const abi.GfxOutputTarget, output: *abi.GfxRefreshRequest) i32 {
        if (!self.supportsRefresh()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputTarget, *abi.GfxRefreshRequest) callconv(.c) i32 = @ptrFromInt(self.table.refresh_read);
        var value: abi.GfxRefreshRequest = .{};
        const code = callback(target, &value);
        if (code == abi.gfx_output_ok) output.* = value;
        return code;
    }
    table: abi.GfxDriverOutputApi,
    pub fn supportsModeColor(self: *const Context) bool {
        return self.supportsModes() and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "mode_read_color") + 8 and self.table.mode_read_color != 0;
    }
    pub fn readModeColor(self: *const Context, ticket: u64, sequence: u64, output: *abi.GfxDriverModeColor) i32 {
        if (!self.supportsModeColor()) return abi.err_no_fn;
        const callback: *const fn (u64, u64, *abi.GfxDriverModeColor) callconv(.c) i32 = @ptrFromInt(self.table.mode_read_color);
        return callback(ticket, sequence, output);
    }
    pub fn supportsColor(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "color_publish") + 8 and self.table.color_publish != 0;
    }
    pub fn publishColor(self: *const Context, input: *const abi.GfxOutputColorState) i32 {
        if (!self.supportsColor()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputColorState) callconv(.c) i32 = @ptrFromInt(self.table.color_publish);
        return callback(input);
    }
    pub fn supportsHotplug(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "mode_status") + 8 and
            self.table.output_pause != 0 and self.table.mode_restore != 0 and self.table.mode_status != 0;
    }
    pub fn pauseOutput(self: *const Context, output: *const abi.GfxOutputId, paused: bool) i32 {
        if (!self.supportsHotplug()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputId, u32) callconv(.c) i32 = @ptrFromInt(self.table.output_pause);
        return callback(output, @intFromBool(paused));
    }
    pub fn restoreMode(self: *const Context, input: *const abi.GfxAtomicState, output: *abi.GfxModeStatus) i32 {
        if (!self.supportsHotplug()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxAtomicState, *abi.GfxModeStatus) callconv(.c) i32 = @ptrFromInt(self.table.mode_restore);
        return callback(input, output);
    }
    pub fn modeStatus(self: *const Context, ticket: u64, output: *abi.GfxModeStatus) i32 {
        if (!self.supportsHotplug()) return abi.err_no_fn;
        const callback: *const fn (u64, *abi.GfxModeStatus) callconv(.c) i32 = @ptrFromInt(self.table.mode_status);
        return callback(ticket, output);
    }
    pub fn supportsAudio(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "audio_query") + 8 and
            self.table.audio_publish != 0 and self.table.audio_query != 0;
    }
    pub fn publishAudio(self: *const Context, input: *const abi.GfxAudioRoute) i32 {
        if (!self.supportsAudio()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxAudioRoute) callconv(.c) i32 = @ptrFromInt(self.table.audio_publish);
        return callback(input);
    }
    pub fn queryAudio(self: *const Context, location: u32, device: u32, index: u32, output: *abi.GfxAudioRoute) i32 {
        if (!self.supportsAudio()) return abi.err_no_fn;
        const callback: *const fn (u32, u32, u32, *abi.GfxAudioRoute) callconv(.c) i32 = @ptrFromInt(self.table.audio_query);
        return callback(location, device, index, output);
    }
    pub fn supportsModes(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "mode_complete") + 8 and
            self.table.mode_enable != 0 and self.table.mode_take != 0 and self.table.mode_complete != 0;
    }
    pub fn enableModes(self: *const Context, backend: *const abi.GfxBackendBinding) i32 {
        if (!self.supportsModes()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding) callconv(.c) i32 = @ptrFromInt(self.table.mode_enable);
        return callback(backend);
    }
    pub fn takeMode(self: *const Context, backend: *const abi.GfxBackendBinding, output: *abi.GfxDriverModeJob) i32 {
        if (!self.supportsModes()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding, *abi.GfxDriverModeJob) callconv(.c) i32 = @ptrFromInt(self.table.mode_take);
        return callback(backend, output);
    }
    pub fn completeMode(self: *const Context, input: *const abi.GfxDriverModeCompletion) i32 {
        if (!self.supportsModes()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxDriverModeCompletion) callconv(.c) i32 = @ptrFromInt(self.table.mode_complete);
        return callback(input);
    }
    pub fn supportsReceivers(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverOutputApi, "close_source") + 8 and
            self.table.register_source != 0 and self.table.replace_receivers != 0 and self.table.close_source != 0;
    }
    pub fn registerSource(self: *const Context, adapter: u32, output: *abi.GfxReceiverSource) i32 {
        if (!self.supportsReceivers()) return abi.err_no_fn;
        const callback: *const fn (u32, *abi.GfxReceiverSource) callconv(.c) i32 = @ptrFromInt(self.table.register_source);
        return callback(adapter, output);
    }
    pub fn replaceReceivers(self: *const Context, input: *const abi.GfxReceiverUpdate) i32 {
        if (!self.supportsReceivers()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxReceiverUpdate) callconv(.c) i32 = @ptrFromInt(self.table.replace_receivers);
        return callback(input);
    }
    pub fn closeSource(self: *const Context, input: *const abi.GfxReceiverSource) i32 {
        if (!self.supportsReceivers()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxReceiverSource) callconv(.c) i32 = @ptrFromInt(self.table.close_source);
        return callback(input);
    }
    pub fn publish(self: *const Context, input: *const abi.GfxOutputPublication, output: *abi.GfxOutputId) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverOutputApi, "publish") + 8 or self.table.publish == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputPublication, *abi.GfxOutputId) callconv(.c) i32 = @ptrFromInt(self.table.publish);
        return callback(input, output);
    }
    pub fn withdraw(self: *const Context, input: *const abi.GfxOutputId) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverOutputApi, "withdraw") + 8 or self.table.withdraw == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOutputId) callconv(.c) i32 = @ptrFromInt(self.table.withdraw);
        return callback(input);
    }
};
