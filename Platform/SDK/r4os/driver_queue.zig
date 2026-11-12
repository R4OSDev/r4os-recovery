const abi = @import("r4os_contract").abi;

pub const Context = struct {
    table: abi.GfxDriverQueueApi,

    /// Logical lifetime only. Neither closure nor job counts prove GPU stop.
    pub fn queueOwnerInfo(self: *const Context, binding: *const abi.GfxBackendBinding, timeline: u64, output: *abi.GfxQueueOwnerInfo) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "queue_owner_info") + 8 or self.table.queue_owner_info == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding, u64, *abi.GfxQueueOwnerInfo) callconv(.c) i32 = @ptrFromInt(self.table.queue_owner_info);
        var temporary: abi.GfxQueueOwnerInfo = .{};
        const rc = callback(binding, timeline, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }

    pub fn supportsScanout(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverQueueApi, "scanout_retire_requested") + 8 and
            self.table.retain_scanout != 0 and self.table.begin_scanout != 0 and self.table.scanout_retire_requested != 0;
    }
    pub fn retainScanout(self: *const Context, fence: *const abi.GfxFence, output: *abi.GfxBufferReference) i32 {
        if (!self.supportsScanout()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxBufferReference);
        const callback: *const fn (*const abi.GfxFence, *abi.GfxBufferReference) callconv(.c) i32 = @ptrFromInt(self.table.retain_scanout);
        return callback(fence, output);
    }
    pub fn beginScanout(self: *const Context, fence: *const abi.GfxFence) i32 {
        if (!self.supportsScanout()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxFence) callconv(.c) i32 = @ptrFromInt(self.table.begin_scanout);
        return callback(fence);
    }
    pub fn scanoutRetireRequested(self: *const Context, fence: *const abi.GfxFence) i32 {
        if (!self.supportsScanout()) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxFence) callconv(.c) i32 = @ptrFromInt(self.table.scanout_retire_requested);
        return callback(fence);
    }

    pub fn supportsRenderList(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverQueueApi, "read_render_list") + 8 and self.table.read_render_list != 0;
    }
    pub fn supportsRenderGridList(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverQueueApi, "read_render_grid_list") + 8 and self.table.read_render_grid_list != 0;
    }
    pub fn supportsRenderColorList(self: *const Context) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.GfxDriverQueueApi, "read_render_color_list") + 8 and self.table.read_render_color_list != 0;
    }
    pub fn readRenderColorList(self: *const Context, fence: *const abi.GfxFence, output: *abi.GfxRenderColorList) i32 {
        if (!self.supportsRenderColorList()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxRenderColorList);
        const callback: *const fn (*const abi.GfxFence, *abi.GfxRenderColorList) callconv(.c) i32 = @ptrFromInt(self.table.read_render_color_list);
        return callback(fence, output);
    }
    pub fn readRenderGridList(self: *const Context, fence: *const abi.GfxFence, output: *abi.GfxRenderGridList) i32 {
        if (!self.supportsRenderGridList()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxRenderGridList);
        const callback: *const fn (*const abi.GfxFence, *abi.GfxRenderGridList) callconv(.c) i32 = @ptrFromInt(self.table.read_render_grid_list);
        return callback(fence, output);
    }
    pub fn readRenderList(self: *const Context, fence: *const abi.GfxFence, output: *abi.GfxRenderList) i32 {
        if (!self.supportsRenderList()) return abi.err_no_fn;
        output.version = 1; output.size = @sizeOf(abi.GfxRenderList);
        const callback: *const fn (*const abi.GfxFence, *abi.GfxRenderList) callconv(.c) i32 = @ptrFromInt(self.table.read_render_list);
        return callback(fence, output);
    }

    pub fn updateOperations(self: *const Context, input: *const abi.GfxBackendBinding, operations: u64) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "update_operations") + 8 or self.table.update_operations == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding, u64) callconv(.c) i32 = @ptrFromInt(self.table.update_operations);
        return callback(input, operations);
    }

    pub fn registerProfile(self: *const Context, input: *const abi.GfxBackendRegistration, profile: *const abi.GfxBackendProfile, output: *abi.GfxBackendBinding) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "register_profile") + 8 or self.table.register_profile == 0) return abi.err_no_fn;
        output.version = 1;
        output.size = @sizeOf(abi.GfxBackendBinding);
        const callback: *const fn (*const abi.GfxBackendRegistration, *const abi.GfxBackendProfile, *abi.GfxBackendBinding) callconv(.c) i32 = @ptrFromInt(self.table.register_profile);
        return callback(input, profile, output);
    }
    pub fn publishProperties(self: *const Context, binding: *const abi.GfxBackendBinding, properties: *const abi.GfxBackendProperties) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "publish_properties") + 8 or self.table.publish_properties == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding, *const abi.GfxBackendProperties) callconv(.c) i32 = @ptrFromInt(self.table.publish_properties);
        return callback(binding, properties);
    }
    pub fn nativeInfo(self: *const Context, fence: *const abi.GfxFence, output: *abi.GfxNativeJobInfo) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "read_native_info") + 8 or self.table.read_native_info == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxFence, *abi.GfxNativeJobInfo) callconv(.c) i32 = @ptrFromInt(self.table.read_native_info);
        var temporary: abi.GfxNativeJobInfo = .{};
        const rc = callback(fence, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }
    pub fn nativeData(self: *const Context, fence: *const abi.GfxFence, offset: u32, output: []u8) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "read_native_data") + 8 or self.table.read_native_data == 0) return abi.err_no_fn;
        if (output.len == 0 or output.len > abi.gfx_native_read_capacity) return abi.gfx_queue_error_invalid;
        const callback: *const fn (*const abi.GfxFence, u32, [*]u8, u32) callconv(.c) i32 = @ptrFromInt(self.table.read_native_data);
        return callback(fence, offset, output.ptr, @intCast(output.len));
    }
    pub fn nativeBinding(self: *const Context, fence: *const abi.GfxFence, index: u32, output: *abi.GfxNativeBinding) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "read_native_binding") + 8 or self.table.read_native_binding == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxFence, u32, *abi.GfxNativeBinding) callconv(.c) i32 = @ptrFromInt(self.table.read_native_binding);
        var temporary: abi.GfxNativeBinding = .{};
        const rc = callback(fence, index, &temporary);
        if (rc == 1) output.* = temporary;
        return rc;
    }

    pub fn register(self: *const Context, input: *const abi.GfxBackendRegistration, output: *abi.GfxBackendBinding) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "register_backend") + 8 or self.table.register_backend == 0) return abi.err_no_fn;
        output.version = 1;
        output.size = @sizeOf(abi.GfxBackendBinding);
        const callback: *const fn (*const abi.GfxBackendRegistration, *abi.GfxBackendBinding) callconv(.c) i32 = @ptrFromInt(self.table.register_backend);
        return callback(input, output);
    }

    pub fn unregister(self: *const Context, input: *const abi.GfxBackendBinding, quiesced: u32) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "unregister_backend") + 8 or self.table.unregister_backend == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxBackendBinding, u32) callconv(.c) i32 = @ptrFromInt(self.table.unregister_backend);
        return callback(input, quiesced);
    }

    pub fn take(self: *const Context, input: *const abi.GfxBackendBinding, output: *abi.GfxDriverJob) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "take") + 8 or self.table.take == 0) return abi.err_no_fn;
        output.version = 1;
        output.size = @sizeOf(abi.GfxDriverJob);
        const callback: *const fn (*const abi.GfxBackendBinding, *abi.GfxDriverJob) callconv(.c) i32 = @ptrFromInt(self.table.take);
        return callback(input, output);
    }

    pub fn complete(self: *const Context, input: *const abi.GfxFence, result: u32, quiesced: u32) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "complete") + 8 or self.table.complete == 0) return abi.err_no_fn;
        const callback: *const fn (*const abi.GfxFence, u32, u32) callconv(.c) i32 = @ptrFromInt(self.table.complete);
        return callback(input, result, quiesced);
    }

    pub fn reset(self: *const Context, input: *const abi.GfxBackendBinding, quiesced: u32, output: *abi.GfxBackendBinding) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "reset") + 8 or self.table.reset == 0) return abi.err_no_fn;
        output.version = 1;
        output.size = @sizeOf(abi.GfxBackendBinding);
        const callback: *const fn (*const abi.GfxBackendBinding, u32, *abi.GfxBackendBinding) callconv(.c) i32 = @ptrFromInt(self.table.reset);
        return callback(input, quiesced, output);
    }

    pub fn segment(self: *const Context, input: *const abi.GfxFence, which: u32, offset: u64, mask: u64, output: *abi.GfxDmaSegment) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "segment") + 8 or self.table.segment == 0) return abi.err_no_fn;
        output.version = 1;
        output.size = @sizeOf(abi.GfxDmaSegment);
        const callback: *const fn (*const abi.GfxFence, u32, u64, u64, *abi.GfxDmaSegment) callconv(.c) i32 = @ptrFromInt(self.table.segment);
        return callback(input, which, offset, mask, output);
    }

    // Source=0, target=1 of an active job. The returned reference retains
    // backing only: describe, DMA/GPU residency and release are supported.
    // CPU maps, sharing and additional execution through it are forbidden.
    pub fn retainResource(self: *const Context, input: *const abi.GfxFence, which: u32, output: *abi.GfxBufferReference) i32 {
        if (self.table.version != 1 or self.table.size < @offsetOf(abi.GfxDriverQueueApi, "retain_resource") + 8 or self.table.retain_resource == 0) return abi.err_no_fn;
        output.version = 1;
        output.size = @sizeOf(abi.GfxBufferReference);
        const callback: *const fn (*const abi.GfxFence, u32, *abi.GfxBufferReference) callconv(.c) i32 = @ptrFromInt(self.table.retain_resource);
        return callback(input, which, output);
    }
};
