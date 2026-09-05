const abi = @import("r4os_contract").abi;
const driver = @import("driver.zig");
const program = @import("program.zig");
const protocol = @import("protocol.zig");
const std = @import("std");

pub const name = "R4DEV";
pub const import_query = "R4DEV:Query:1";
pub const group = abi.R4LGroup.r4dev;
pub const abi_version = abi.r4l_abi_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4dev.h";
pub const query_contract = "Repositories/Contract/ABI/R4LQuery.txt";
pub const DriverApi = abi.DriverApi;
pub const ProtocolApi = abi.ProtocolApi;
pub const DriverContext = driver.Context;
pub const ProtocolContext = protocol.Context;
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
    base: program.Context,

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

    pub fn programInstanceStorageSummaryLegacy(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        return self.base.programInstanceStorageSummaryLegacy(out);
    }

    pub fn programInstanceStorageSummaryV2(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        return self.base.programInstanceStorageSummaryV2(out);
    }

    pub fn programInstanceStorageSelfTest(self: *const Context, out: *abi.ProgramInstanceStorageSelfTestResult) i32 {
        return self.base.programInstanceStorageSelfTest(out);
    }

    pub fn programRegistrySummary(self: *const Context, out: *abi.ProgramRegistrySummary) i32 {
        return self.base.programRegistrySummary(out);
    }

    pub fn programRegistrySelfTest(self: *const Context, out: *abi.ProgramRegistrySelfTestResult) i32 {
        return self.base.programRegistrySelfTest(out);
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

    pub fn programRegistrySummaryLegacy(self: *const Context, out: *abi.ProgramRegistrySummary) i32 {
        return self.programRegistrySummary(out);
    }

    pub fn programRegistrySelfTestLegacy(self: *const Context, out: *abi.ProgramRegistrySelfTestResult) i32 {
        return self.programRegistrySelfTest(out);
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
    try std.testing.expectEqualStrings("R4DEV:Query:1", import_query);
    try std.testing.expectEqual(@as(u32, 6), @intFromEnum(group));
    try std.testing.expectEqual(abi.r4l_abi_version, abi_version);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4dev.h", c_header);
}
