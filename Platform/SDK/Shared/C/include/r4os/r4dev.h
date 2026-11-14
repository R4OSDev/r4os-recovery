#ifndef R4OS_R4DEV_H
#define R4OS_R4DEV_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

/* R4DEV is a built-in platform API provided by the kernel. It is resolved as
 * a group_interface import and has no R4L file. The table layout is declared
 * in <r4os/r4xstart.h> (R4XStartR4Dev2). */

typedef struct R4Dev {
    const R4XStartR4Dev2 *table;
    const R4OS2Context *generation2;
} R4Dev;

static inline int r4dev_available(const R4Dev *dev) {
    return dev && (dev->generation2 ? R4OS2ContextGroup(dev->generation2, 6) != NULL : (dev->table && dev->table->magic == R4OS2_R4DEV_MAGIC && dev->table->abi_version >= 1 && dev->table->size >= 16));
}
static inline uintptr_t r4dev_callback(const R4Dev *dev, size_t offset) {
    if (!dev || offset > UINT32_MAX) return 0;
    if (dev->generation2) {
        uint64_t address;
        return R4OS2ContextFunction(dev->generation2, 6, offset, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!(dev->table && dev->table->magic == R4OS2_R4DEV_MAGIC && dev->table->abi_version >= 1 && dev->table->size >= 16) || offset > dev->table->size || sizeof(uintptr_t) > dev->table->size - offset) return 0;
    return *(const uintptr_t *)((const uint8_t *)dev->table + offset);
}
#define R4DEV_SLOT(dev, field) r4dev_callback((dev), offsetof(R4XStartR4Dev2, field))
#define R4DEV_HAS(dev, field) (R4DEV_SLOT((dev), field) != 0)
static inline int32_t r4dev_init2(const R4OS2Context *context, R4Dev *out) {
    if (!out || !context || !R4OS2ContextGroup(context, 6)) return R4OS_ERR_NO_GROUP;
    *out = (R4Dev){.table = NULL, .generation2 = context};
    return 0;
}

/* Query is passive. Offline/online require the exact current epoch; errors
 * preserve output and may require a fresh query after a partial safe drain. */
/* Optional catalogue prefix; errors from old providers preserve caller buffers. */
static inline int32_t r4dev_cpu_capabilities(const R4Dev *dev, uint32_t cpu, R4CpuCapabilitiesInfo *out) {
    if (out == 0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_capabilities) ||
        R4DEV_SLOT(dev, cpu_capabilities) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuCapabilitiesFn)(uintptr_t)R4DEV_SLOT(dev, cpu_capabilities))(cpu, out);
}
static inline int32_t r4dev_cpu_feature(const R4Dev *dev, uint32_t cpu, uint64_t epoch, uint32_t index, R4CpuFeatureInfo *out) {
    if (out == 0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_feature) ||
        R4DEV_SLOT(dev, cpu_feature) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuFeatureFn)(uintptr_t)R4DEV_SLOT(dev, cpu_feature))(cpu, epoch, index, out);
}
static inline int32_t r4dev_cpu_register_read(const R4Dev *dev, uint32_t cpu, uint64_t epoch, uint32_t id, R4CpuRegisterInfo *out) {
    if (out == 0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_register_read) ||
        R4DEV_SLOT(dev, cpu_register_read) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuRegisterReadFn)(uintptr_t)R4DEV_SLOT(dev, cpu_register_read))(cpu, epoch, id, out);
}
static inline int32_t r4dev_cpu_power_info(const R4Dev *dev, uint32_t cpu, uint64_t epoch, R4CpuPowerInfo *out) {
    if (out == 0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_power_info) ||
        R4DEV_SLOT(dev, cpu_power_info) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuPowerInfoFn)(uintptr_t)R4DEV_SLOT(dev, cpu_power_info))(cpu, epoch, out);
}
/* Explicit local operation; return0 provides a receipt, whose state/error must
 * be checked. A request readback is not achieved physical performance. */
static inline int32_t r4dev_cpu_performance(const R4Dev *dev, const R4CpuPerformanceRequest *request, R4CpuPerformanceInfo *out) {
    if (!request || !out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_performance) || !R4DEV_SLOT(dev, cpu_performance)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuPerformanceFn)(uintptr_t)R4DEV_SLOT(dev, cpu_performance))(request, out);
}

/* Optional independently typed AMD CPPC/catalogue observation. */
static inline int32_t r4dev_cpu_cppc(const R4Dev *dev, const R4CpuPerformanceRequest *request, R4CpuCppcInfo *out) {
    if (!request || !out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_cppc) || !R4DEV_SLOT(dev, cpu_cppc)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuCppcFn)(uintptr_t)R4DEV_SLOT(dev, cpu_cppc))(request, out);
}
/* Separately negotiated firmware call: may wait for the real external worker.
 * No implicit retry after timeout/uncertainty, and no local-register Session. */
static inline int32_t r4dev_cpu_firmware_performance(const R4Dev *dev, const R4CpuPerformanceRequest *request, R4CpuFirmwareInfo *out) {
    if (!request || !out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_firmware_performance) || !R4DEV_SLOT(dev, cpu_firmware_performance)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuFirmwarePerformanceFn)(uintptr_t)R4DEV_SLOT(dev, cpu_firmware_performance))(request, out);
}
static inline int32_t r4dev_cpu_idle_info(const R4Dev *dev, uint32_t cpu, R4CpuIdleInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_idle_info) || !R4DEV_SLOT(dev, cpu_idle_info)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuIdleInfoFn)(uintptr_t)R4DEV_SLOT(dev, cpu_idle_info))(cpu, out);
}
/* Passive early microcode receipt; no hardware work or reload endpoint. */
static inline int32_t r4dev_cpu_microcode_info(const R4Dev *dev, uint32_t cpu, R4CpuMicrocodeInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_microcode_info) || !R4DEV_SLOT(dev, cpu_microcode_info)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuMicrocodeInfoFn)(uintptr_t)R4DEV_SLOT(dev, cpu_microcode_info))(cpu, out);
}
/* Cached hints never authorize optional ISA; work needs a fresh exact grant.
 * Callback must be resident, bounded, pure, without API/fault/wait/yield. */
static inline int32_t r4dev_cpu_acceleration_info(const R4Dev *dev, R4CpuAccelerationInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_acceleration_info) || !R4DEV_SLOT(dev, cpu_acceleration_info)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuAccelerationInfoFn)(uintptr_t)R4DEV_SLOT(dev, cpu_acceleration_info))(out);
}
static inline int32_t r4dev_cpu_acceleration_work(const R4Dev *dev, uint32_t kind, uint32_t iterations, R4CpuPureWorkFn work, uint64_t context, R4CpuAccelerationWork *out) {
    if (!out || !work) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_acceleration_work) || !R4DEV_SLOT(dev, cpu_acceleration_work)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuAccelerationWorkFn)(uintptr_t)R4DEV_SLOT(dev, cpu_acceleration_work))(kind, iterations, &work, context, out);
}
/* Passive discovery/retained copies; only measure explicitly runs pure work. */
static inline int32_t r4dev_cpu_pmu_info(const R4Dev *dev, uint32_t cpu, R4CpuPmuInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_pmu_info) || !R4DEV_SLOT(dev, cpu_pmu_info)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuPmuInfoFn)(uintptr_t)R4DEV_SLOT(dev, cpu_pmu_info))(cpu, out);
}
/* work must be resident/pure/bounded: no allocation, fault, block, yield or
 * API/placement call. A local copied typed slot keeps the wire ABI portable. */
static inline int32_t r4dev_cpu_pmu_measure(const R4Dev *dev, uint32_t cpu, uint64_t epoch, uint32_t event, uint32_t iterations, R4PmuWorkFn work, uint64_t context, R4CpuPmuResult *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_pmu_measure) || !R4DEV_SLOT(dev, cpu_pmu_measure)) return R4OS_ERR_NO_FN;
    if (!work) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    return ((R4DevCpuPmuMeasureFn)(uintptr_t)R4DEV_SLOT(dev, cpu_pmu_measure))(cpu, epoch, event, iterations, &work, context, out);
}
static inline int32_t r4dev_cpu_pmu_result(const R4Dev *dev, uint32_t cpu, uint64_t epoch, uint64_t generation, R4CpuPmuResult *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_pmu_result) || !R4DEV_SLOT(dev, cpu_pmu_result)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuPmuResultFn)(uintptr_t)R4DEV_SLOT(dev, cpu_pmu_result))(cpu, epoch, generation, out);
}
/* Passive resident MCA copies; no hardware reads or implicit work. */
static inline int32_t r4dev_cpu_machine_info(const R4Dev *dev, uint32_t cpu, R4CpuMachineInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_machine_info) || !R4DEV_SLOT(dev, cpu_machine_info)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuMachineInfoFn)(uintptr_t)R4DEV_SLOT(dev, cpu_machine_info))(cpu, out);
}
static inline int32_t r4dev_cpu_machine_bank(const R4Dev *dev, uint32_t cpu, uint64_t epoch, uint64_t sequence, uint32_t bank, R4CpuMachineBank *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_machine_bank) || !R4DEV_SLOT(dev, cpu_machine_bank)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuMachineBankFn)(uintptr_t)R4DEV_SLOT(dev, cpu_machine_bank))(cpu, epoch, sequence, bank, out);
}

/* Optional independently typed AMD CPPC/catalogue observation. */
static inline int32_t r4dev_cpu_performance_hint(const R4Dev *dev, uint32_t cpu, uint64_t epoch, R4CpuPerformanceHintInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, cpu_performance_hint) || !R4DEV_SLOT(dev, cpu_performance_hint)) return R4OS_ERR_NO_FN;
    return ((R4DevCpuPerformanceHintFn)(uintptr_t)R4DEV_SLOT(dev, cpu_performance_hint))(cpu, epoch, out);
}

static inline int32_t r4dev_cpu_power_capture(const R4Dev *dev, uint32_t cpu, uint64_t epoch, R4CpuPowerInfo *out) {
    if (out == 0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_power_capture) ||
        R4DEV_SLOT(dev, cpu_power_capture) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuPowerCaptureFn)(uintptr_t)R4DEV_SLOT(dev, cpu_power_capture))(cpu, epoch, out);
}
static inline int32_t r4dev_kernel_cpu_register_check(const R4Dev *dev, uint32_t cpu, uint64_t epoch, R4ProgramKernelCpuRegisterCheck *out) {
    if (out == 0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, kernel_cpu_register_check) ||
        R4DEV_SLOT(dev, kernel_cpu_register_check) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevKernelCpuRegisterCheckFn)(uintptr_t)R4DEV_SLOT(dev, kernel_cpu_register_check))(cpu, epoch, out);
}

static inline int32_t r4dev_cpu_lifecycle(const R4Dev *dev, uint32_t operation, uint32_t cpu,
    uint64_t expected_epoch, R4CpuLifecycleInfo *out) {
    if (out == 0) return R4OS_CPU_LIFECYCLE_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_lifecycle) ||
        R4DEV_SLOT(dev, cpu_lifecycle) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuLifecycleFn)(uintptr_t)R4DEV_SLOT(dev, cpu_lifecycle))(operation, cpu, expected_epoch, out);
}
static inline int32_t r4dev_kernel_cpu_lifecycle_check(const R4Dev *dev, R4ProgramKernelCpuLifecycleCheck *out) {
    if (out == 0) return R4OS_CPU_LIFECYCLE_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, kernel_cpu_lifecycle_check) ||
        R4DEV_SLOT(dev, kernel_cpu_lifecycle_check) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevKernelCpuLifecycleCheckFn)(uintptr_t)R4DEV_SLOT(dev, kernel_cpu_lifecycle_check))(out);
}

static inline int32_t r4dev_cpu_topology(const R4Dev *dev, uint32_t cpu_index, R4CpuTopologyInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_topology) ||
        R4DEV_SLOT(dev, cpu_topology) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuTopologyFn)(uintptr_t)R4DEV_SLOT(dev, cpu_topology))(cpu_index, out);
}

static inline int32_t r4dev_cpu_cache_topology(const R4Dev *dev, uint32_t cpu_index, uint32_t cache_index, R4CpuCacheTopologyInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, cpu_cache_topology) ||
        R4DEV_SLOT(dev, cpu_cache_topology) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevCpuCacheTopologyFn)(uintptr_t)R4DEV_SLOT(dev, cpu_cache_topology))(cpu_index, cache_index, out);
}

static inline int32_t r4dev_memory_pressure_snapshot(const R4Dev *dev, R4ProgramMemoryPressureSnapshot *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, memory_pressure_snapshot) ||
        R4DEV_SLOT(dev, memory_pressure_snapshot) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevMemoryPressureSnapshotFn)(uintptr_t)R4DEV_SLOT(dev, memory_pressure_snapshot))(out);
}

static inline int32_t r4dev_performance_instrumentation(const R4Dev *dev, R4ProgramInstrumentationInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, performance_instrumentation) ||
        R4DEV_SLOT(dev, performance_instrumentation) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevPerformanceInstrumentationFn)(uintptr_t)R4DEV_SLOT(dev, performance_instrumentation))(out);
}

static inline int32_t r4dev_performance_lock(const R4Dev *dev, uint32_t index, R4ProgramLockPerformanceInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, performance_lock) ||
        R4DEV_SLOT(dev, performance_lock) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevPerformanceLockFn)(uintptr_t)R4DEV_SLOT(dev, performance_lock))(index, out);
}

static inline int32_t r4dev_performance_stack(const R4Dev *dev, uint32_t index, R4ProgramStackPerformanceInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, performance_stack) ||
        R4DEV_SLOT(dev, performance_stack) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevPerformanceStackFn)(uintptr_t)R4DEV_SLOT(dev, performance_stack))(index, out);
}

static inline int32_t r4dev_stack_fault(const R4Dev *dev, uint32_t index, R4ProgramStackFaultInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, stack_fault) ||
        R4DEV_SLOT(dev, stack_fault) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevStackFaultFn)(uintptr_t)R4DEV_SLOT(dev, stack_fault))(index, out);
}

static inline int32_t r4dev_display_state(const R4Dev *dev, R4DisplayStateInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, display_state) ||
        R4DEV_SLOT(dev, display_state) == 0u) return R4OS_ERR_NO_FN;
    return ((R4DevDisplayStateFn)(uintptr_t)R4DEV_SLOT(dev, display_state))(out);
}

static inline int32_t r4dev_init(const R4XStartContext2 *ctx, R4Dev *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    out->table = 0;
    out->generation2 = 0;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4DEV);
    if (item == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Dev2 *table = (const R4XStartR4Dev2 *)(uintptr_t)item->table;
    if (table->magic != R4OS2_R4DEV_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4OS2_R4DEV_VERSION) return R4OS_ERROR_INVALID;
    if (table->size < offsetof(R4XStartR4Dev2, performance_summary) + sizeof(uintptr_t)) return R4OS_ERROR_INVALID;
    if (table->performance_summary == 0) return R4OS_ERROR_INVALID;
    out->table = table;
    return R4OS_OK;
}

static inline int32_t r4dev_program_instance_storage_summary_v2(
    const R4Dev *dev,
    R4ProgramInstanceStorageSummary *out_summary)
{
    if (out_summary == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, program_instance_storage_summary_v2) ||
        R4DEV_SLOT(dev, program_instance_storage_summary_v2) == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevProgramInstanceStorageSummaryV2Fn summary_fn =
        (R4DevProgramInstanceStorageSummaryV2Fn)(uintptr_t)R4DEV_SLOT(dev, program_instance_storage_summary_v2);
    return summary_fn(out_summary);
}

static inline int32_t r4dev_execution_inventory_summary(
    const R4Dev *dev,
    R4ProgramInventorySummary *out_summary)
{
    if (out_summary == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, execution_inventory_summary) ||
        R4DEV_SLOT(dev, execution_inventory_summary) == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevExecutionInventorySummaryFn summary_fn =
        (R4DevExecutionInventorySummaryFn)(uintptr_t)R4DEV_SLOT(dev, execution_inventory_summary);
    return summary_fn(out_summary);
}

static inline int32_t r4dev_performance_driver_work(
    const R4Dev *dev,
    uint32_t owner,
    R4ProgramDriverWorkPerformanceInfo *out_info)
{
    if (out_info == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, performance_driver_work) ||
        R4DEV_SLOT(dev, performance_driver_work) == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevPerformanceDriverWorkFn snapshot_fn =
        (R4DevPerformanceDriverWorkFn)(uintptr_t)R4DEV_SLOT(dev, performance_driver_work);
    return snapshot_fn(owner, out_info);
}

static inline int32_t r4dev_performance_pci_inventory(
    const R4Dev *dev,
    R4ProgramPciInventoryPerformanceInfo *out_info)
{
    if (out_info == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        !R4DEV_HAS(dev, performance_pci_inventory) ||
        R4DEV_SLOT(dev, performance_pci_inventory) == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevPerformancePciInventoryFn snapshot_fn =
        (R4DevPerformancePciInventoryFn)(uintptr_t)R4DEV_SLOT(dev, performance_pci_inventory);
    return snapshot_fn(out_info);
}

#ifdef __cplusplus
}
#endif

#endif
