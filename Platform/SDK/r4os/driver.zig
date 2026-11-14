const abi = @import("r4os_contract").abi;

/// Private transfer storage with separate caller and device references.
/// A device reference is dropped only after its mapping has been retired.
/// The metadata page is outside the payload address submitted to hardware.
pub const SharedDmaBuffer = struct {
    region: abi.DmaBuffer,
    references: u32 = 1,
    payload_bytes: u32,

    const payload_offset: u32 = 4096;

    pub fn create(ctx: *const Context, bytes: u32, max_phys: u64) ?*SharedDmaBuffer {
        return createSharedDmaBuffer(ctx, bytes, max_phys);
    }

    pub fn data(self: *const SharedDmaBuffer) []u8 {
        const payload: [*]u8 = @ptrFromInt(self.region.virt_addr + payload_offset);
        return payload[0..self.payload_bytes];
    }

    /// The caller already owns a reference; retaining performs no allocation.
    pub fn retain(self: *SharedDmaBuffer) void {
        const previous = @atomicRmw(u32, &self.references, .Add, 1, .monotonic);
        if (previous == 0 or previous == 0xffff_ffff) unreachable;
    }

    pub fn release(self: *SharedDmaBuffer, ctx: *const Context) void {
        releaseSharedDmaBuffer(self, ctx);
    }
};

// One allocation/refcount owner for both explicit technical generations.
// Generic entry points are not foreign helper ABI exports.
pub fn createSharedDmaBuffer(ctx: anytype, bytes: u32, max_phys: u64) ?*SharedDmaBuffer {
    if (bytes == 0 or bytes > abi.dma_mapping_max_bytes) return null;
    var region: abi.DmaBuffer = .{};
    if (ctx.allocDmaRegionConstrained(bytes + SharedDmaBuffer.payload_offset, SharedDmaBuffer.payload_offset, max_phys, &region) != 0) return null;
    if (region.virt_addr == 0 or region.bytes < bytes + SharedDmaBuffer.payload_offset) {
        ctx.freeDmaRegion(&region);
        return null;
    }
    const self: *SharedDmaBuffer = @ptrFromInt(region.virt_addr);
    self.* = .{ .region = region, .payload_bytes = bytes };
    return self;
}
pub fn releaseSharedDmaBuffer(self: *SharedDmaBuffer, ctx: anytype) void {
    const previous = @atomicRmw(u32, &self.references, .Sub, 1, .acq_rel);
    if (previous == 0) unreachable;
    if (previous != 1) return;
    // The descriptor passed to free must outlive the allocation it frees.
    var region = self.region;
    ctx.freeDmaRegion(&region);
}

/// Version 3 adds the canonical output callbacks to the unchanged v2 prefix.
pub const r4d_shutdown_entry_offset: u32 = 5;

pub fn entriesAsm(comptime init_target: []const u8, comptime shutdown_target: []const u8) []const u8 {
    return ".section .text.r4d_entries,\"ax\"\n" ++
        ".global DriverInit2\n" ++
        "DriverInit2:\n" ++
        "    jmp " ++ init_target ++ "\n" ++
        ".global DriverShutdown\n" ++
        "DriverShutdown:\n" ++
        "    jmp " ++ shutdown_target ++ "\n";
}

pub const Context = @import("driver2.zig").Context;
