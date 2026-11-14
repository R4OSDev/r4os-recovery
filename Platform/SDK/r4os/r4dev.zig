const abi = @import("r4os_contract").abi;
const driver = @import("driver.zig");
const program = @import("program.zig");
const protocol = @import("protocol.zig");
const std = @import("std");

pub const name = "R4DEV";
pub const import_query = "R4DEV:Query2:2";
pub const group = abi.R4LGroup.r4dev;
pub const abi_version = @import("r4os_contract2").query_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4dev.h";
pub const query_contract = "Repositories/Contract/ABI/R4LQuery.txt";
pub const DriverApi = DriverApi2;
pub const DriverApi2 = @import("technical2.zig").abi.DriverApi2;
pub const ProtocolApi = ProtocolApi2;
pub const ProtocolApi2 = @import("technical2.zig").abi.ProtocolApi2;
pub const DriverContext = driver.Context;
pub const DriverContext2 = @import("driver2.zig").Context;
pub const DriverSerialContext = @import("driver_serial.zig").Context;
pub const DriverResourceContext = @import("driver_resources.zig").Context;
pub const DriverCpuPowerContext = @import("driver_cpu_power.zig").Context;
pub const DriverPlatformContext = @import("driver_resources.zig").Platform;
pub const DriverHeapContext = @import("driver_heap.zig").Context;
pub const DriverThreadContext = @import("driver_threads.zig").Context;
pub const DriverSemaphoreContext = @import("driver_semaphores.zig").Context;
pub const SharedDmaBuffer = driver.SharedDmaBuffer;
pub const ProtocolContext = protocol.Context;
pub const ProtocolContext2 = @import("protocol2.zig").Context;
pub const r4d_shutdown_entry_offset = driver.r4d_shutdown_entry_offset;
pub const r4p_shutdown_entry_offset = protocol.r4p_shutdown_entry_offset;
pub const r4p_query_entry_offset = protocol.r4p_query_entry_offset;
pub const r4p_dispatch_entry_offset = protocol.r4p_dispatch_entry_offset;

pub fn driverEntriesAsm(comptime init_target: []const u8, comptime shutdown_target: []const u8) []const u8 {
    return driver.entriesAsm(init_target, shutdown_target);
}

pub fn protocolEntriesAsm(
    comptime init_target: []const u8,
    comptime shutdown_target: []const u8,
    comptime query_target: []const u8,
    comptime dispatch_target: []const u8,
) []const u8 {
    return protocol.entriesAsm(init_target, shutdown_target, query_target, dispatch_target);
}

pub const Context = struct {
    pub fn serial(self: *const Context) ?@import("serial.zig").Context {
        if (self.base.generation2) |view| return @import("serial.zig").Context.init(view.devices() orelse return null);
        const bundle = self.base.bundle orelse return null;
        return @import("serial.zig").Context.init(bundle.dev orelse return null);
    }

    base: program.Context,

    pub fn displayState(self: *const Context) ?abi.DisplayStateInfo {
        return self.base.displayState();
    }

    pub fn driverModuleInfo(self: *const Context, owner: u32) ?abi.DriverModuleInfo {
        return self.base.driverModuleInfo(owner);
    }

    pub fn driverModuleInfoRaw(self: *const Context, owner: u32, out: *abi.DriverModuleInfo) i32 {
        return self.base.driverModuleInfoRaw(owner, out);
    }

    pub fn init(bundle: *const program.Bundle) Context {
        return .{ .base = program.Context.initBundle(bundle) };
    }

    pub fn fromProgram(ctx: program.Context) Context {
        return .{ .base = ctx };
    }

    // 0.57.2: ehrliche Vertragspruefung (ersetzt supports*-Versionsgates).
    pub fn hasFn(self: *const Context, comptime field: []const u8) bool {
        return self.base.hasDevFn(field);
    }

    pub fn deviceInventorySummary(self: *const Context, out: *abi.DeviceInventorySummary) i32 {
        return self.base.deviceInventorySummary(out);
    }

    pub fn deviceInventoryRecord(self: *const Context, index: u32, out: *abi.DeviceInventoryRecord) i32 {
        return self.base.deviceInventoryRecord(index, out);
    }

    pub fn memorySummary(self: *const Context) ?abi.ProgramMemorySummary {
        return self.base.memorySummary();
    }

    pub fn memoryBlockCount(self: *const Context) u32 {
        return self.base.memoryBlockCount();
    }

    pub fn memoryBlock(self: *const Context, index: u32) ?abi.ProgramMemoryBlockInfo {
        return self.base.memoryBlock(index);
    }

    pub fn memoryPressure(self: *const Context) ?abi.ProgramMemoryPressureSnapshot {
        return self.base.memoryPressure();
    }

    pub fn memoryReclaimProbe(self: *const Context, requested_frames: u32) ?abi.ProgramMemoryReclaimProbe {
        return self.base.memoryReclaimProbe(requested_frames);
    }

    pub fn kernelHeapCheck(self: *const Context, out: *abi.ProgramKernelHeapCheck) i32 {
        return self.base.kernelHeapCheck(out);
    }

    pub fn kernelSchedulerCheck(self: *const Context, selection: u32, out: *abi.ProgramKernelSchedulerCheck) i32 {
        return self.base.kernelSchedulerCheck(selection, out);
    }

    /// Existing bounded local USB ring/router cases; no live controller work.
    pub fn kernelUsbCheck(self: *const Context, out: *abi.ProgramKernelUsbCheck) i32 {
        return self.base.kernelUsbCheck(out);
    }

    /// Explicit one-request read-only NVMe IRQ proof. Missing capabilities are
    /// unavailable; passive counter progress is not an own completion receipt.
    pub fn kernelNvmeCheck(self: *const Context, out: *abi.ProgramKernelNvmeCheck) i32 {
        return self.base.kernelNvmeCheck(out);
    }

    /// Explicit owned synthetic blockqueue work; raw status leaves unavailable
    /// distinct from a passing check. This never selects a physical disk.
    pub fn kernelBlockQueueCheck(self: *const Context, out: *abi.ProgramKernelBlockQueueCheck) i32 {
        return self.base.kernelBlockQueueCheck(out);
    }

    /// Passive capture/feature queries; register work is always explicit.
    pub fn cpuCapabilities(self: *const Context, cpu: u32, out: *abi.CpuCapabilitiesInfo) i32 {
        return self.base.cpuCapabilities(cpu, out);
    }
    pub fn cpuFeature(self: *const Context, cpu: u32, epoch: u64, index: u32, out: *abi.CpuFeatureInfo) i32 {
        return self.base.cpuFeature(cpu, epoch, index, out);
    }
    pub fn cpuRegisterRead(self: *const Context, cpu: u32, epoch: u64, id: u32, out: *abi.CpuRegisterInfo) i32 {
        return self.base.cpuRegisterRead(cpu, epoch, id, out);
    }
    pub fn cpuPowerInfo(self: *const Context, cpu: u32, epoch: u64, out: *abi.CpuPowerInfo) i32 {
        return self.base.cpuPowerInfo(cpu, epoch, out);
    }
    pub fn cpuPerformance(self: *const Context, request: *const abi.CpuPerformanceRequest, out: *abi.CpuPerformanceInfo) i32 {
        return self.base.cpuPerformance(request, out);
    }

    pub fn cpuCppc(self: *const Context, request: *const abi.CpuPerformanceRequest, out: *abi.CpuCppcInfo) i32 {
        return self.base.cpuCppc(request, out);
    }
    pub fn cpuFirmwarePerformance(self: *const Context, request: *const abi.CpuPerformanceRequest, out: *abi.CpuFirmwareInfo) i32 {
        return self.base.cpuFirmwarePerformance(request, out);
    }
    pub fn cpuIdleInfo(self: *const Context, cpu: u32, out: *abi.CpuIdleInfo) i32 {
        return self.base.cpuIdleInfo(cpu, out);
    }
    pub fn cpuMachineInfo(self: *const Context, cpu: u32, out: *abi.CpuMachineInfo) i32 {
        return self.base.cpuMachineInfo(cpu, out);
    }
    pub fn cpuMicrocodeInfo(self: *const Context, cpu: u32, out: *abi.CpuMicrocodeInfo) i32 {
        return self.base.cpuMicrocodeInfo(cpu, out);
    }

    pub fn fpuObservation(self: *const Context, request: *const abi.FpuObservationRequest, out: *abi.FpuObservationInfo) i32 {
        return self.base.fpuObservation(request, out);
    }

    pub fn cpuAccelerationInfo(self: *const Context, out: *abi.CpuAccelerationInfo) i32 {
        return self.base.cpuAccelerationInfo(out);
    }
    pub fn cpuAccelerationWorkFunction(self: *const Context) ?abi.R4DevFns.cpu_acceleration_work {
        return self.base.cpuAccelerationWorkFunction();
    }
    pub fn cpuAccelerationWork(self: *const Context, kind: u32, iterations: u32, work: ?abi.CpuPureWorkFn, context: u64, out: *abi.CpuAccelerationWork) i32 {
        return self.base.cpuAccelerationWork(kind, iterations, work, context, out);
    }
    pub fn cpuPmuInfo(self: *const Context, cpu: u32, out: *abi.CpuPmuInfo) i32 {
        return self.base.cpuPmuInfo(cpu, out);
    }
    pub fn cpuPmuMeasure(self: *const Context, cpu: u32, epoch: u64, event: u32, iterations: u32, work: ?abi.PmuWorkFn, context: u64, out: *abi.CpuPmuResult) i32 {
        return self.base.cpuPmuMeasure(cpu, epoch, event, iterations, work, context, out);
    }
    pub fn cpuPmuResult(self: *const Context, cpu: u32, epoch: u64, generation: u64, out: *abi.CpuPmuResult) i32 {
        return self.base.cpuPmuResult(cpu, epoch, generation, out);
    }
    pub fn cpuMachineBank(self: *const Context, cpu: u32, epoch: u64, sequence: u64, index: u32, out: *abi.CpuMachineBank) i32 {
        return self.base.cpuMachineBank(cpu, epoch, sequence, index, out);
    }

    pub fn cpuPerformanceHint(self: *const Context, cpu: u32, epoch: u64, out: *abi.CpuPerformanceHintInfo) i32 {
        return self.base.cpuPerformanceHint(cpu, epoch, out);
    }

    pub fn cpuPowerCapture(self: *const Context, cpu: u32, epoch: u64, out: *abi.CpuPowerInfo) i32 {
        return self.base.cpuPowerCapture(cpu, epoch, out);
    }
    pub fn kernelCpuRegisterCheck(self: *const Context, cpu: u32, epoch: u64, out: *abi.ProgramKernelCpuRegisterCheck) i32 {
        return self.base.kernelCpuRegisterCheck(cpu, epoch, out);
    }

    pub fn cpuLifecycle(self: *const Context, operation: u32, cpu: u32, expected_epoch: u64, out: *abi.CpuLifecycleInfo) i32 {
        return self.base.cpuLifecycle(operation, cpu, expected_epoch, out);
    }
    pub fn kernelCpuLifecycleCheck(self: *const Context, out: *abi.ProgramKernelCpuLifecycleCheck) i32 {
        return self.base.kernelCpuLifecycleCheck(out);
    }

    pub fn kernelSmpCheck(self: *const Context, out: *abi.ProgramKernelSmpCheck) i32 {
        return self.base.kernelSmpCheck(out);
    }

    pub fn smpTlbSnapshot(self: *const Context, out: *abi.ProgramSmpTlbSnapshot) i32 {
        return self.base.smpTlbSnapshot(out);
    }

    pub fn cpuTopology(self: *const Context, index: u32, out: *abi.CpuTopologyInfo) i32 {
        return self.base.cpuTopology(index, out);
    }

    pub fn cpuCacheTopology(self: *const Context, index: u32, ordinal: u32, out: *abi.CpuCacheTopologyInfo) i32 {
        return self.base.cpuCacheTopology(index, ordinal, out);
    }

    pub fn memoryBackingStoreProbe(self: *const Context, path: [*:0]const u8, requested_bytes: u64, flags: u32) ?abi.ProgramMemoryBackingStoreProbe {
        return self.base.memoryBackingStoreProbe(path, requested_bytes, flags);
    }

    pub fn memoryBackingStoreSlotProbe(self: *const Context, path: [*:0]const u8, backing_bytes: u64, operation: u32, requested_slots: u64, reservation_id: u32, owner_kind: u32, owner_id: u32, region_id: u32, flags: u32) ?abi.ProgramMemoryBackingStoreSlotProbe {
        return self.base.memoryBackingStoreSlotProbe(path, backing_bytes, operation, requested_slots, reservation_id, owner_kind, owner_id, region_id, flags);
    }

    pub fn memoryPagerGateProbe(self: *const Context, path: [*:0]const u8, backing_bytes: u64, region_id: u32, requested_bytes: u64, flags: u32) ?abi.ProgramMemoryPagerGateProbe {
        return self.base.memoryPagerGateProbe(path, backing_bytes, region_id, requested_bytes, flags);
    }

    pub fn memoryPageIoProbe(self: *const Context, path: [*:0]const u8, backing_bytes: u64, operation: u32, region_id: u32, region_offset: u64, reservation_id: u32, slot_index: u64, page_count: u64, owner_kind: u32, owner_id: u32, expected_generation: u64, page: []u8, flags: u32) ?abi.ProgramMemoryPageIoProbe {
        return self.base.memoryPageIoProbe(path, backing_bytes, operation, region_id, region_offset, reservation_id, slot_index, page_count, owner_kind, owner_id, expected_generation, page, flags);
    }

    pub fn memoryVmPageStateProbe(self: *const Context, region_id: u32, region_offset: u64, page_count: u64, operation: u32, slot_reservation_id: u32, slot_index: u64, slot_generation: u64, flags: u32) ?abi.ProgramMemoryVmPageStateProbe {
        return self.base.memoryVmPageStateProbe(region_id, region_offset, page_count, operation, slot_reservation_id, slot_index, slot_generation, flags);
    }

    pub fn performanceSummary(self: *const Context) ?abi.ProgramPerformanceSummary {
        return self.base.performanceSummary();
    }

    pub fn programInstanceStorageSummary(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        return self.base.programInstanceStorageSummary(out);
    }

    pub fn programInstanceStorageSummaryV2(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        return self.base.programInstanceStorageSummaryV2(out);
    }

    pub fn programInstanceStorageSelfTest(self: *const Context, out: *abi.ProgramInstanceStorageSelfTestResult) i32 {
        return self.base.programInstanceStorageSelfTest(out);
    }

    pub fn programRegistrySummaryV2(self: *const Context, out: *abi.ProgramRegistrySummaryV2) i32 {
        return self.base.programRegistrySummaryV2(out);
    }

    pub fn programRegistrySelfTestV2(self: *const Context, out: *abi.ProgramRegistrySelfTestResultV2) i32 {
        return self.base.programRegistrySelfTestV2(out);
    }

    pub fn executionInventorySummary(self: *const Context, out: *abi.ProgramInventorySummary) i32 {
        return self.base.executionInventorySummary(out);
    }

    pub fn kernelVersion(self: *const Context) ?abi.KernelVersion {
        var out: abi.KernelVersion = .{};
        if (self.base.kernelVersion(&out) <= 0) return null;
        return out;
    }

    pub fn performanceTask(self: *const Context, index: u32) ?abi.ProgramTaskPerformanceInfo {
        return self.base.performanceTask(index);
    }

    pub fn performanceStorage(self: *const Context, index: u32) ?abi.ProgramStoragePerformanceInfo {
        return self.base.performanceStorage(index);
    }

    pub fn performanceBootPhase(self: *const Context, index: u32) ?abi.ProgramBootPhasePerformanceInfo {
        return self.base.performanceBootPhase(index);
    }

    pub fn performanceBootPhaseClock(self: *const Context, index: u32) ?abi.ProgramBootPhaseClockInfo {
        return self.base.performanceBootPhaseClock(index);
    }

    pub fn performanceBootSummary(self: *const Context) ?abi.ProgramBootPerformanceInfo {
        return self.base.performanceBootSummary();
    }

    pub fn performanceDriverWork(self: *const Context, owner: u32) ?abi.ProgramDriverWorkPerformanceInfo {
        return self.base.performanceDriverWork(owner);
    }

    pub fn performancePciInventory(self: *const Context) ?abi.ProgramPciInventoryPerformanceInfo {
        return self.base.performancePciInventory();
    }

    pub fn performanceInput(self: *const Context) ?abi.ProgramInputPerformanceInfo {
        return self.base.performanceInput();
    }

    pub fn performanceInstrumentation(self: *const Context) ?abi.ProgramInstrumentationInfo {
        return self.base.performanceInstrumentation();
    }

    pub fn performanceLock(self: *const Context, index: u32) ?abi.ProgramLockPerformanceInfo {
        return self.base.performanceLock(index);
    }

    pub fn performanceStack(self: *const Context, index: u32) ?abi.ProgramStackPerformanceInfo {
        return self.base.performanceStack(index);
    }

    pub fn stackFault(self: *const Context, index: u32, out: *abi.ProgramStackFaultInfo) i32 {
        return self.base.stackFault(index, out);
    }

    pub fn performanceIrqTiming(self: *const Context, irq: u32) ?abi.ProgramIrqTimingInfo {
        return self.base.performanceIrqTiming(irq);
    }

    pub fn memoryVmReserveProbe(self: *const Context, requested_bytes: u64) ?abi.ProgramVmReserveProbe {
        return self.base.memoryVmReserveProbe(requested_bytes);
    }

    pub fn pagingSummary(self: *const Context) ?abi.PagingSummary {
        return self.base.pagingSummary();
    }

    pub fn displaySummary(self: *const Context) ?abi.DisplaySummary {
        return self.base.displaySummary();
    }

    pub fn hardwareSummary(self: *const Context) ?abi.HardwareSummary {
        return self.base.hardwareSummary();
    }

    pub fn firmwareSystemUuid(self: *const Context) ?abi.FirmwareSystemUuidInfo {
        return self.base.firmwareSystemUuid();
    }

    pub fn bootInfoSummary(self: *const Context) ?abi.BootInfoSummary {
        return self.base.bootInfoSummary();
    }

    pub fn bootInfoMemoryCount(self: *const Context) u32 {
        return self.base.bootInfoMemoryCount();
    }

    pub fn bootInfoMemoryEntry(self: *const Context, index: u32) ?abi.BootInfoMemoryEntry {
        return self.base.bootInfoMemoryEntry(index);
    }

    pub fn protocolStatus(self: *const Context, role: []const u8, out: *abi.ProtocolStatus) i32 {
        return self.base.protocolStatus(role, out);
    }

    pub fn protocolDispatch(self: *const Context, role: []const u8, op: u32, in_buffer: *const abi.ProtocolBuffer, out_buffer: *abi.ProtocolBuffer) i32 {
        return self.base.protocolDispatch(role, op, in_buffer, out_buffer);
    }

    pub fn programStatus(self: *const Context, out: *abi.ProgramStatus) void {
        self.base.programStatus(out);
    }

    pub fn programInstance(self: *const Context, index: u32, out: *abi.ProgramInstanceInfo) i32 {
        return self.base.programInstance(index, out);
    }

    pub fn ipcSummary(self: *const Context, out: *abi.IpcSummary) i32 {
        return self.base.ipcSummary(out);
    }

    pub fn ipcChannel(self: *const Context, channel_id: u32, out: *abi.IpcChannelInfo) i32 {
        return self.base.ipcChannel(channel_id, out);
    }

    pub fn tcpSummary(self: *const Context, out: *abi.TcpSummary) i32 {
        return self.base.tcpSummary(out);
    }

    pub fn tcpConnection(self: *const Context, index: u32, out: *abi.TcpConnectionInfo) i32 {
        return self.base.tcpConnection(index, out);
    }

    pub fn udpStatus(self: *const Context, out: *abi.UdpStatus) i32 {
        return self.base.udpStatus(out);
    }

    pub fn netDetailGet(self: *const Context, adapter_index: u32, out: *abi.NetDetailSnapshot) i32 {
        return self.base.netDetailGet(adapter_index, out);
    }
};

pub fn formatKernelVersion(value: abi.KernelVersion, buffer: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buffer, "{d}.{d}.{d}", .{ value.major, value.minor, value.patch }) catch null;
}

test "r4dev exposes project and ABI metadata" {
    try std.testing.expectEqualStrings("R4DEV", name);
    try std.testing.expectEqualStrings("R4DEV:Query2:2", import_query);
    try std.testing.expectEqual(@as(u32, 6), @intFromEnum(group));
    try std.testing.expectEqual(@as(u32, 2), abi_version);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4dev.h", c_header);
}
