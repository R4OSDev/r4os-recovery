#ifndef R4OS_APP_DEVICES_H
#define R4OS_APP_DEVICES_H

#include "app_contract.h"

typedef struct R4Devices { R4App *app; } R4Devices;
typedef struct R4DeviceInventoryView { R4App *app; } R4DeviceInventoryView;
typedef struct R4MemoryView { R4App *app; } R4MemoryView;
typedef struct R4PerformanceView { R4App *app; } R4PerformanceView;

static inline R4Devices r4_app_devices(R4App *app) { R4Devices value = {app}; return value; }
static inline int r4_devices_available(const R4Devices *devices) { const R4Dev *dev = devices != 0 && devices->app != 0 ? &devices->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, device_inventory_summary) != 0u && R4DEV_SLOT(dev, memory_summary) != 0u && R4DEV_SLOT(dev, performance_summary) != 0u; }
static inline R4DeviceInventoryView r4_devices_inventory(R4Devices devices) { R4DeviceInventoryView value = {devices.app}; return value; }
static inline R4MemoryView r4_devices_memory(R4Devices devices) { R4MemoryView value = {devices.app}; return value; }
static inline R4PerformanceView r4_devices_performance(R4Devices devices) { R4PerformanceView value = {devices.app}; return value; }

static inline int32_t r4_devices_display(R4Devices *devices, R4DisplayStateInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (devices == 0 || devices->app == 0) return R4OS_ERR_NO_FN;
    *out = (R4DisplayStateInfo){0};
    out->version = 1u;
    out->size = (uint32_t)sizeof(*out);
    return r4dev_display_state(&devices->app->devices, out);
}

static inline int32_t r4_device_inventory_summary(R4DeviceInventoryView *view, R4DeviceInventorySummary *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, device_inventory_summary) != 0u && out != 0 ? ((R4DevDeviceInventorySummaryFn)(uintptr_t)R4DEV_SLOT(dev, device_inventory_summary))(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_device_inventory_record(R4DeviceInventoryView *view, uint32_t index, R4DeviceInventoryRecord *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, device_inventory_record) != 0u && out != 0 ? ((R4DevDeviceInventoryRecordFn)(uintptr_t)R4DEV_SLOT(dev, device_inventory_record))(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_device_hardware_summary(R4DeviceInventoryView *view, R4HardwareSummary *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, hardware_summary) != 0u && out != 0 ? ((R4DevHardwareSummaryFn)(uintptr_t)R4DEV_SLOT(dev, hardware_summary))(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_memory_summary(R4MemoryView *view, R4ProgramMemorySummary *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, memory_summary) != 0u && out != 0 ? ((R4DevMemorySummaryFn)(uintptr_t)R4DEV_SLOT(dev, memory_summary))(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_memory_pressure(R4MemoryView *view, R4ProgramMemoryPressureSnapshot *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, memory_pressure_snapshot) != 0u && out != 0 ? ((R4DevMemoryPressureSnapshotFn)(uintptr_t)R4DEV_SLOT(dev, memory_pressure_snapshot))(out) : R4OS_ERR_NO_FN; }
static inline uint32_t r4_memory_block_count(R4MemoryView *view) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, memory_block_count) != 0u ? ((R4DevMemoryBlockCountFn)(uintptr_t)R4DEV_SLOT(dev, memory_block_count))() : 0u; }
static inline int32_t r4_memory_block(R4MemoryView *view, uint32_t index, R4ProgramMemoryBlockInfo *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, memory_block) != 0u && out != 0 ? ((R4DevMemoryBlockFn)(uintptr_t)R4DEV_SLOT(dev, memory_block))(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_performance_instrumentation(R4PerformanceView *view, R4ProgramInstrumentationInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (view == 0 || view->app == 0) return R4OS_ERR_NO_FN;
    *out = (R4ProgramInstrumentationInfo){0};
    out->version = 1u;
    out->size = (uint32_t)sizeof(*out);
    return r4dev_performance_instrumentation(&view->app->devices, out);
}

static inline int32_t r4_performance_lock(R4PerformanceView *view, uint32_t index, R4ProgramLockPerformanceInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (view == 0 || view->app == 0) return R4OS_ERR_NO_FN;
    *out = (R4ProgramLockPerformanceInfo){0};
    out->version = 1u;
    out->size = (uint32_t)sizeof(*out);
    return r4dev_performance_lock(&view->app->devices, index, out);
}

static inline int32_t r4_performance_stack(R4PerformanceView *view, uint32_t index, R4ProgramStackPerformanceInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (view == 0 || view->app == 0) return R4OS_ERR_NO_FN;
    *out = (R4ProgramStackPerformanceInfo){0};
    out->version = 1u;
    out->size = (uint32_t)sizeof(*out);
    return r4dev_performance_stack(&view->app->devices, index, out);
}

/* Caller initializes the version/capacity header; failed reads preserve it. */
static inline int32_t r4_performance_stack_fault(R4PerformanceView *view, uint32_t cpu, R4ProgramStackFaultInfo *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    if (view == 0 || view->app == 0) return R4OS_ERR_NO_FN;
    return r4dev_stack_fault(&view->app->devices, cpu, out);
}

static inline int32_t r4_performance_summary(R4PerformanceView *view, R4ProgramPerformanceSummary *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, performance_summary) != 0u && out != 0 ? ((R4DevPerformanceSummaryFn)(uintptr_t)R4DEV_SLOT(dev, performance_summary))(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_instance_storage_summary(R4PerformanceView *view, R4ProgramInstanceStorageSummary *out) {
    if (!view || !view->app || !out) return R4OS_ERR_NO_FN;
    const R4Dev *dev = &view->app->devices;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, program_instance_storage_summary_v2) ||
        !R4DEV_SLOT(dev, program_instance_storage_summary_v2)) return R4OS_ERR_NO_FN;
    *out = (R4ProgramInstanceStorageSummary){0};
    out->version = 2u; out->size = (uint32_t)sizeof(*out);
    return r4dev_program_instance_storage_summary_v2(&view->app->devices, out);
}
static inline int32_t r4_program_instance_storage_self_test(R4PerformanceView *view, R4ProgramInstanceStorageSelfTestResult *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, program_instance_storage_self_test) != 0u && out != 0 ? ((R4DevProgramInstanceStorageSelfTestFn)(uintptr_t)R4DEV_SLOT(dev, program_instance_storage_self_test))(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_registry_summary_v2(R4PerformanceView *view, R4ProgramRegistrySummaryV2 *out) {
    if (!out) return R4OS_ERROR_INVALID;
    const R4Dev *dev = view && view->app ? &view->app->devices : 0;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, program_registry_summary_v2)) return R4OS_ERR_NO_FN;
    return ((R4DevProgramRegistrySummaryV2Fn)(uintptr_t)R4DEV_SLOT(dev, program_registry_summary_v2))(out);
}
static inline int32_t r4_program_registry_self_test_v2(R4PerformanceView *view, R4ProgramRegistrySelfTestResultV2 *out) {
    if (!out) return R4OS_ERROR_INVALID;
    const R4Dev *dev = view && view->app ? &view->app->devices : 0;
    if (!r4dev_available(dev) || !R4DEV_HAS(dev, program_registry_self_test_v2)) return R4OS_ERR_NO_FN;
    return ((R4DevProgramRegistrySelfTestV2Fn)(uintptr_t)R4DEV_SLOT(dev, program_registry_self_test_v2))(out);
}
static inline int32_t r4_execution_inventory_summary(R4PerformanceView *view, R4ProgramInventorySummary *out) {
    if (out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (view == 0 || view->app == 0) return R4OS_ERR_NO_FN;
    return r4dev_execution_inventory_summary(&view->app->devices, out);
}
static inline int32_t r4_performance_task(R4PerformanceView *view, uint32_t index, R4ProgramTaskPerformanceInfo *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, performance_task) != 0u && out != 0 ? ((R4DevPerformanceTaskFn)(uintptr_t)R4DEV_SLOT(dev, performance_task))(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_performance_storage(R4PerformanceView *view, uint32_t index, R4ProgramStoragePerformanceInfo *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, performance_storage) != 0u && out != 0 ? ((R4DevPerformanceStorageFn)(uintptr_t)R4DEV_SLOT(dev, performance_storage))(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_performance_boot_phase(R4PerformanceView *view, uint32_t index, R4ProgramBootPhasePerformanceInfo *out) { const R4Dev *dev = view != 0 && view->app != 0 ? &view->app->devices : 0; return r4dev_available(dev) && R4DEV_SLOT(dev, performance_boot_phase) != 0u && out != 0 ? ((R4DevPerformanceBootPhaseFn)(uintptr_t)R4DEV_SLOT(dev, performance_boot_phase))(index, out) : R4OS_ERR_NO_FN; }

#endif
