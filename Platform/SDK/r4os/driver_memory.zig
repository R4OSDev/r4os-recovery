const abi = @import("r4os_contract").abi;

// Copyable table view; returned objects/maps retain independent kernel owners.
pub const Context = struct {
    table: abi.GfxDriverMemoryApi,

    pub fn reservedSpan(self: *const Context, physical_base: u64, bytes: u64) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "reserved_span") + 8 or self.table.reserved_span == 0) return abi.err_no_fn;
        const callback: *const fn (u64, u64) callconv(.c) i32 = @ptrFromInt(self.table.reserved_span);
        return callback(physical_base, bytes);
    }

    /// Proves absence of system memory; callers separately measure the actual
    /// device storage. It does not authorize a mapping or transfer ownership.
    pub fn unmanagedSpan(self: *const Context, physical_base: u64, bytes: u64) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "unmanaged_span") + 8 or self.table.unmanaged_span == 0) return abi.err_no_fn;
        const callback: *const fn (u64, u64) callconv(.c) i32 = @ptrFromInt(self.table.unmanaged_span);
        return callback(physical_base, bytes);
    }

    pub fn deviceLost(self: *const Context, adapter: u32, generation: u64, quiesced: bool) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "device_lost") + 8 or self.table.device_lost == 0) return abi.err_no_fn;
        const callback: *const fn (u32, u64, u32) callconv(.c) i32 = @ptrFromInt(self.table.device_lost);
        return callback(adapter, generation, @intFromBool(quiesced));
    }

    pub fn telemetryExchange(self: *const Context, input: *const abi.GfxTelemetryState, output: *abi.GfxTelemetryDemand) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "telemetry_exchange") + 8 or self.table.telemetry_exchange == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxTelemetryState, *abi.GfxTelemetryDemand) callconv(.c) i32 = @ptrFromInt(self.table.telemetry_exchange);
        var temporary: abi.GfxTelemetryDemand = .{};
        const rc = callback(input, &temporary);
        if (rc == abi.gfx_buffer_result_ok) output.* = temporary;
        return rc;
    }

    pub fn memoryBudget(self: *const Context, input: *const abi.GfxDeviceBudgetRequest, output: *abi.GfxDeviceBudgetState) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "memory_budget") + 8 or self.table.memory_budget == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxDeviceBudgetRequest, *abi.GfxDeviceBudgetState) callconv(.c) i32 = @ptrFromInt(self.table.memory_budget);
        var temporary: abi.GfxDeviceBudgetState = .{};
        const rc = callback(input, &temporary);
        if (rc == abi.gfx_buffer_result_ok) output.* = temporary;
        return rc;
    }

    pub fn virtualRegister(self: *const Context, input: *const abi.GfxNativeProvider, output: *abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "virtual_register") + 8 or self.table.virtual_register == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxNativeProvider, *abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.virtual_register);
        var temporary: abi.GfxBufferHandle = .{};
        const rc = callback(input, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }

    pub fn virtualUnregister(self: *const Context, provider: *const abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "virtual_unregister") + 8 or self.table.virtual_unregister == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.virtual_unregister);
        return callback(provider);
    }

    pub fn virtualTake(self: *const Context, provider: *const abi.GfxBufferHandle, output: *abi.GfxVirtualJob) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "virtual_take") + 8 or self.table.virtual_take == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *abi.GfxVirtualJob) callconv(.c) i32 = @ptrFromInt(self.table.virtual_take);
        var temporary: abi.GfxVirtualJob = .{};
        const rc = callback(provider, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }

    pub fn virtualComplete(self: *const Context, provider: *const abi.GfxBufferHandle, completion: *const abi.GfxVirtualCompletion) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "virtual_complete") + 8 or self.table.virtual_complete == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *const abi.GfxVirtualCompletion) callconv(.c) i32 = @ptrFromInt(self.table.virtual_complete);
        return callback(provider, completion);
    }

    pub fn nativeRegister(self: *const Context, input: *const abi.GfxNativeProvider, output: *abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "native_register") + 8 or self.table.native_register == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxNativeProvider, *abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.native_register);
        var temporary: abi.GfxBufferHandle = .{};
        const rc = callback(input, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }

    pub fn nativeUnregister(self: *const Context, provider: *const abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "native_unregister") + 8 or self.table.native_unregister == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.native_unregister);
        return callback(provider);
    }

    pub fn nativeTake(self: *const Context, provider: *const abi.GfxBufferHandle, output: *abi.GfxNativeJob) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "native_take") + 8 or self.table.native_take == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *abi.GfxNativeJob) callconv(.c) i32 = @ptrFromInt(self.table.native_take);
        var temporary: abi.GfxNativeJob = .{};
        const rc = callback(provider, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }

    pub fn nativeComplete(self: *const Context, provider: *const abi.GfxBufferHandle, request: *const abi.GfxBufferHandle, result: i32, reference: *const abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "native_complete") + 8 or self.table.native_complete == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *const abi.GfxBufferHandle, i32, *const abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.native_complete);
        return callback(provider, request, result, reference);
    }

    pub fn bufferCreate(self: *const Context, input: *const abi.GfxBufferDescriptor, output: *abi.GfxBufferReference) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_create") + 8 or self.table.buffer_create == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferDescriptor, *abi.GfxBufferReference) callconv(.c) i32 = @ptrFromInt(self.table.buffer_create);
        return callback(input, output);
    }

    pub fn bufferDescribe(self: *const Context, input: *const abi.GfxBufferHandle, output: *abi.GfxBufferDescriptor) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_describe") + 8 or self.table.buffer_describe == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *abi.GfxBufferDescriptor) callconv(.c) i32 = @ptrFromInt(self.table.buffer_describe);
        return callback(input, output);
    }

    pub fn bufferImport(self: *const Context, input: *const abi.GfxBufferHandle, output: *abi.GfxBufferReference) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_import") + 8 or self.table.buffer_import == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *abi.GfxBufferReference) callconv(.c) i32 = @ptrFromInt(self.table.buffer_import);
        return callback(input, output);
    }

    pub fn bufferRelease(self: *const Context, input: *const abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_release") + 8 or self.table.buffer_release == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.buffer_release);
        return callback(input);
    }

    pub fn bufferMap(self: *const Context, input: *const abi.GfxBufferHandle, access: u32, offset: u64, bytes: u64, output: *abi.GfxBufferMap) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_map") + 8 or self.table.buffer_map == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, u32, u64, u64, *abi.GfxBufferMap) callconv(.c) i32 = @ptrFromInt(self.table.buffer_map);
        return callback(input, access, offset, bytes, output);
    }

    pub fn bufferUnmap(self: *const Context, input: *const abi.GfxBufferHandle) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_unmap") + 8 or self.table.buffer_unmap == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle) callconv(.c) i32 = @ptrFromInt(self.table.buffer_unmap);
        return callback(input);
    }

    pub fn deviceAcquire(self: *const Context, reference: *const abi.GfxBufferHandle, request: *const abi.GfxDeviceRequest, output: *abi.GfxDeviceLease) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "device_acquire") + 8 or self.table.device_acquire == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, *const abi.GfxDeviceRequest, *abi.GfxDeviceLease) callconv(.c) i32 = @ptrFromInt(self.table.device_acquire);
        return callback(reference, request, output);
    }

    pub fn deviceSegment(self: *const Context, lease: *const abi.GfxDeviceLease, offset: u64, output: *abi.GfxDmaSegment) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "device_segment") + 8 or self.table.device_segment == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxDeviceLease, u64, *abi.GfxDmaSegment) callconv(.c) i32 = @ptrFromInt(self.table.device_segment);
        return callback(lease, offset, output);
    }

    pub fn deviceRelease(self: *const Context, lease: *const abi.GfxDeviceLease, quiesced: u32) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "device_release") + 8 or self.table.device_release == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxDeviceLease, u32) callconv(.c) i32 = @ptrFromInt(self.table.device_release);
        return callback(lease, quiesced);
    }

    pub fn mmioMap(self: *const Context, request: *const abi.GfxMmioRequest, output: *abi.GfxMmioWindow) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "mmio_map") + 8 or self.table.mmio_map == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxMmioRequest, *abi.GfxMmioWindow) callconv(.c) i32 = @ptrFromInt(self.table.mmio_map);
        return callback(request, output);
    }

    pub fn mmioUnmap(self: *const Context, window: *const abi.GfxBufferHandle, quiesced: u32) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "mmio_unmap") + 8 or self.table.mmio_unmap == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferHandle, u32) callconv(.c) i32 = @ptrFromInt(self.table.mmio_unmap);
        return callback(window, quiesced);
    }

    pub fn collect(self: *const Context) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "collect") + 8 or self.table.collect == 0) return abi.err_no_fn;
        const callback: *const fn () callconv(.c) i32 = @ptrFromInt(self.table.collect);
        return callback();
    }

    pub fn bufferStats(self: *const Context, output: *abi.GfxBufferStats) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_stats") + 8 or self.table.buffer_stats == 0) return abi.err_no_fn;
        const callback: *const fn (*abi.GfxBufferStats) callconv(.c) i32 = @ptrFromInt(self.table.buffer_stats);
        var value: abi.GfxBufferStats = .{};
        const code = callback(&value);
        if (code == abi.gfx_buffer_result_ok) {
            if (value.version != 1 or value.size < @sizeOf(abi.GfxBufferStats)) return abi.gfx_buffer_error_invalid;
            output.* = value;
        }
        return code;
    }

    pub fn bufferReserve(self: *const Context, input: *const abi.GfxBufferDescriptor, cookie: u64, output: *abi.GfxOwnedBufferReservation) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_reserve") + 8 or self.table.buffer_reserve == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBufferDescriptor, u64, *abi.GfxOwnedBufferReservation) callconv(.c) i32 = @ptrFromInt(self.table.buffer_reserve);
        return callback(input, cookie, output);
    }

    pub fn bufferCommit(self: *const Context, input: *const abi.GfxOwnedBufferReservation, output: *abi.GfxBufferReference) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_commit") + 8 or self.table.buffer_commit == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOwnedBufferReservation, *abi.GfxBufferReference) callconv(.c) i32 = @ptrFromInt(self.table.buffer_commit);
        return callback(input, output);
    }

    pub fn bufferAbort(self: *const Context, input: *const abi.GfxOwnedBufferReservation, quiesced: u32) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_abort") + 8 or self.table.buffer_abort == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOwnedBufferReservation, u32) callconv(.c) i32 = @ptrFromInt(self.table.buffer_abort);
        return callback(input, quiesced);
    }

    pub fn bufferTakeRelease(self: *const Context, adapter: u32, generation: u64, output: *abi.GfxOwnedBufferRelease) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_take_release") + 8 or self.table.buffer_take_release == 0) return abi.err_no_fn;
        const callback: *const fn (u32, u64, *abi.GfxOwnedBufferRelease) callconv(.c) i32 = @ptrFromInt(self.table.buffer_take_release);
        return callback(adapter, generation, output);
    }

    pub fn bufferFinishRelease(self: *const Context, input: *const abi.GfxOwnedBufferRelease, quiesced: u32) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverMemoryApi, "buffer_finish_release") + 8 or self.table.buffer_finish_release == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxOwnedBufferRelease, u32) callconv(.c) i32 = @ptrFromInt(self.table.buffer_finish_release);
        return callback(input, quiesced);
    }
};
