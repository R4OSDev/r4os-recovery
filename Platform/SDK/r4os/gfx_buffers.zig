const abi = @import("r4os_contract").abi;
const program = @import("program.zig");

pub const Context = struct {
    base: program.Context,

    pub fn nativeStart(self: *const Context, input: *const abi.GfxNativeAllocation, output: *abi.GfxNativeStatus) i32 { return self.base.gfxNativeStart(input, output); }

    pub fn nativeQuery(self: *const Context, request: *const abi.GfxBufferHandle, output: *abi.GfxNativeStatus) i32 { return self.base.gfxNativeQuery(request, output); }

    pub fn nativeReceive(self: *const Context, request: *const abi.GfxBufferHandle, output: *abi.GfxBufferReference) i32 { return self.base.gfxNativeReceive(request, output); }

    pub fn nativeClose(self: *const Context, request: *const abi.GfxBufferHandle) i32 { return self.base.gfxNativeClose(request); }

    pub fn nativeWait(self: *const Context, request: *const abi.GfxBufferHandle, timeout_ticks: u64, output: *abi.GfxNativeStatus) i32 { return self.base.gfxNativeWait(request, timeout_ticks, output); }

    pub fn create(self: *const Context, descriptor: *const abi.GfxBufferDescriptor, output: *abi.GfxBufferReference) i32 {
        return self.base.gfxBufferCreate(descriptor, output);
    }

    pub fn describe(self: *const Context, reference: *const abi.GfxBufferHandle, output: *abi.GfxBufferDescriptor) i32 {
        return self.base.gfxBufferDescribe(reference, output);
    }

    pub fn import(self: *const Context, source_reference: *const abi.GfxBufferHandle, output: *abi.GfxBufferReference) i32 {
        return self.base.gfxBufferImport(source_reference, output);
    }

    pub fn release(self: *const Context, reference: *const abi.GfxBufferHandle) i32 {
        return self.base.gfxBufferRelease(reference);
    }

    pub fn map(self: *const Context, reference: *const abi.GfxBufferHandle, access: u32, offset: u64, byte_length: u64, output: *abi.GfxBufferMap) i32 {
        return self.base.gfxBufferMap(reference, access, offset, byte_length, output);
    }
    pub fn mapPersistent(self: *const Context, reference: *const abi.GfxBufferHandle, access: u32, offset: u64, byte_length: u64, output: *abi.GfxBufferMap) i32 {
        return self.base.gfxBufferMapPersistent(reference, access, offset, byte_length, output);
    }

    pub fn unmap(self: *const Context, lease: *const abi.GfxBufferHandle) i32 {
        return self.base.gfxBufferUnmap(lease);
    }

    pub fn exportRaster(self: *const Context, lease: *const abi.GuiSharedRasterLease, output: *abi.GfxBufferReference) i32 {
        return self.base.gfxBufferExportRaster(lease, output);
    }

    pub fn stats(self: *const Context, output: *abi.GfxBufferStats) i32 {
        return self.base.gfxBufferStats(output);
    }

    pub fn memoryBudget(self: *const Context, input: *const abi.GfxDeviceBudgetRequest, output: *abi.GfxDeviceBudgetState) i32 {
        return self.base.gfxMemoryBudget(input, output);
    }
};
