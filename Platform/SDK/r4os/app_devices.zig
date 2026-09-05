const abi = @import("r4os_contract").abi;
const r4dev = @import("r4dev.zig");

pub const Devices = struct {
    raw: r4dev.Context,

    pub fn available(self: *const Devices) bool {
        return self.raw.hasFn("device_inventory_summary") and self.raw.hasFn("memory_summary") and self.raw.hasFn("performance_summary");
    }

    pub fn inventory(self: *const Devices) DeviceInventoryView {
        return .{ .raw = self.raw };
    }
    pub fn memory(self: *const Devices) MemoryView {
        return .{ .raw = self.raw };
    }
    pub fn performance(self: *const Devices) PerformanceView {
        return .{ .raw = self.raw };
    }
};

pub const DeviceInventoryView = struct {
    raw: r4dev.Context,

    pub fn summary(self: *const DeviceInventoryView) ?abi.DeviceInventorySummary {
        var out: abi.DeviceInventorySummary = .{};
        return if (self.raw.deviceInventorySummary(&out) >= 0) out else null;
    }

    pub fn record(self: *const DeviceInventoryView, index: u32) ?abi.DeviceInventoryRecord {
        var out: abi.DeviceInventoryRecord = .{};
        return if (self.raw.deviceInventoryRecord(index, &out) >= 0) out else null;
    }

    pub fn hardware(self: *const DeviceInventoryView) ?abi.HardwareSummary {
        return self.raw.hardwareSummary();
    }
};

pub const MemoryView = struct {
    raw: r4dev.Context,

    pub fn summary(self: *const MemoryView) ?abi.ProgramMemorySummary {
        return self.raw.memorySummary();
    }
    pub fn pressure(self: *const MemoryView) ?abi.ProgramMemoryPressureSnapshot {
        return self.raw.memoryPressure();
    }
    pub fn blockCount(self: *const MemoryView) u32 {
        return self.raw.memoryBlockCount();
    }
    pub fn block(self: *const MemoryView, index: u32) ?abi.ProgramMemoryBlockInfo {
        return self.raw.memoryBlock(index);
    }
};

pub const PerformanceView = struct {
    raw: r4dev.Context,

    pub fn summary(self: *const PerformanceView) ?abi.ProgramPerformanceSummary {
        return self.raw.performanceSummary();
    }
    pub fn programInstanceStorage(self: *const PerformanceView) ?abi.ProgramInstanceStorageSummary {
        var out: abi.ProgramInstanceStorageSummary = .{};
        return if (self.raw.programInstanceStorageSummary(&out) > 0) out else null;
    }
    pub fn programInstanceStorageSelfTest(self: *const PerformanceView, out: *abi.ProgramInstanceStorageSelfTestResult) i32 {
        return self.raw.programInstanceStorageSelfTest(out);
    }
    pub fn programRegistry(self: *const PerformanceView) ?abi.ProgramRegistrySummary {
        var out: abi.ProgramRegistrySummary = .{};
        return if (self.raw.programRegistrySummary(&out) > 0) out else null;
    }
    pub fn programRegistrySelfTest(self: *const PerformanceView, out: *abi.ProgramRegistrySelfTestResult) i32 {
        return self.raw.programRegistrySelfTest(out);
    }
    pub fn programRegistryV2(self: *const PerformanceView) ?abi.ProgramRegistrySummaryV2 {
        var out: abi.ProgramRegistrySummaryV2 = .{};
        return if (self.raw.programRegistrySummaryV2(&out) > 0) out else null;
    }
    pub fn programRegistrySelfTestV2(self: *const PerformanceView, out: *abi.ProgramRegistrySelfTestResultV2) i32 {
        return self.raw.programRegistrySelfTestV2(out);
    }
    pub fn executionInventorySummary(self: *const PerformanceView, out: *abi.ProgramInventorySummary) i32 {
        return self.raw.executionInventorySummary(out);
    }
    pub fn executionInventory(self: *const PerformanceView) ?abi.ProgramInventorySummary {
        var out: abi.ProgramInventorySummary = .{};
        return if (self.executionInventorySummary(&out) >= 0) out else null;
    }
    pub fn task(self: *const PerformanceView, index: u32) ?abi.ProgramTaskPerformanceInfo {
        return self.raw.performanceTask(index);
    }
    pub fn storage(self: *const PerformanceView, index: u32) ?abi.ProgramStoragePerformanceInfo {
        return self.raw.performanceStorage(index);
    }
    pub fn bootPhase(self: *const PerformanceView, index: u32) ?abi.ProgramBootPhasePerformanceInfo {
        return self.raw.performanceBootPhase(index);
    }
    pub fn bootPhaseClock(self: *const PerformanceView, index: u32) ?abi.ProgramBootPhaseClockInfo {
        return self.raw.performanceBootPhaseClock(index);
    }
    pub fn irqTiming(self: *const PerformanceView, irq: u32) ?abi.ProgramIrqTimingInfo {
        return self.raw.performanceIrqTiming(irq);
    }
    pub fn driverWork(self: *const PerformanceView, owner: u32) ?abi.ProgramDriverWorkPerformanceInfo {
        return self.raw.performanceDriverWork(owner);
    }
};
