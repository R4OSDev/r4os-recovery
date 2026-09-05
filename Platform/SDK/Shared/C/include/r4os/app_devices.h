#ifndef R4OS_APP_DEVICES_H
#define R4OS_APP_DEVICES_H

#include "app_contract.h"

typedef struct R4Devices { R4App *app; } R4Devices;
typedef struct R4DeviceInventoryView { R4App *app; } R4DeviceInventoryView;
typedef struct R4MemoryView { R4App *app; } R4MemoryView;
typedef struct R4PerformanceView { R4App *app; } R4PerformanceView;

static inline R4Devices r4_app_devices(R4App *app) { R4Devices value = {app}; return value; }
static inline int r4_devices_available(const R4Devices *devices) { const R4XStartR4Dev *table = devices != 0 && devices->app != 0 ? devices->app->devices.table : 0; return table != 0 && table->device_inventory_summary != 0u && table->memory_summary != 0u && table->performance_summary != 0u; }
static inline R4DeviceInventoryView r4_devices_inventory(R4Devices devices) { R4DeviceInventoryView value = {devices.app}; return value; }
static inline R4MemoryView r4_devices_memory(R4Devices devices) { R4MemoryView value = {devices.app}; return value; }
static inline R4PerformanceView r4_devices_performance(R4Devices devices) { R4PerformanceView value = {devices.app}; return value; }

static inline int32_t r4_device_inventory_summary(R4DeviceInventoryView *view, R4DeviceInventorySummary *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->device_inventory_summary != 0u && out != 0 ? ((R4DevDeviceInventorySummaryFn)(uintptr_t)table->device_inventory_summary)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_device_inventory_record(R4DeviceInventoryView *view, uint32_t index, R4DeviceInventoryRecord *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->device_inventory_record != 0u && out != 0 ? ((R4DevDeviceInventoryRecordFn)(uintptr_t)table->device_inventory_record)(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_device_hardware_summary(R4DeviceInventoryView *view, R4HardwareSummary *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->hardware_summary != 0u && out != 0 ? ((R4DevHardwareSummaryFn)(uintptr_t)table->hardware_summary)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_memory_summary(R4MemoryView *view, R4ProgramMemorySummary *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->memory_summary != 0u && out != 0 ? ((R4DevMemorySummaryFn)(uintptr_t)table->memory_summary)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_memory_pressure(R4MemoryView *view, R4ProgramMemoryPressureSnapshot *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->memory_pressure_snapshot != 0u && out != 0 ? ((R4DevMemoryPressureSnapshotFn)(uintptr_t)table->memory_pressure_snapshot)(out) : R4OS_ERR_NO_FN; }
static inline uint32_t r4_memory_block_count(R4MemoryView *view) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->memory_block_count != 0u ? ((R4DevMemoryBlockCountFn)(uintptr_t)table->memory_block_count)() : 0u; }
static inline int32_t r4_memory_block(R4MemoryView *view, uint32_t index, R4ProgramMemoryBlockInfo *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->memory_block != 0u && out != 0 ? ((R4DevMemoryBlockFn)(uintptr_t)table->memory_block)(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_performance_summary(R4PerformanceView *view, R4ProgramPerformanceSummary *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->performance_summary != 0u && out != 0 ? ((R4DevPerformanceSummaryFn)(uintptr_t)table->performance_summary)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_instance_storage_summary(R4PerformanceView *view, R4ProgramInstanceStorageSummary *out) {
    if (view == 0 || view->app == 0 || out == 0) return R4OS_ERR_NO_FN;
    *out = (R4ProgramInstanceStorageSummary){0};
    out->version = 2u;
    out->size = (uint32_t)sizeof(*out);
    int32_t result = r4dev_program_instance_storage_summary_v2(&view->app->devices, out);
    if (result != R4OS_ERR_NO_FN) return result;
    *out = (R4ProgramInstanceStorageSummary){0};
    return r4dev_program_instance_storage_summary_legacy(&view->app->devices, out);
}
static inline int32_t r4_program_instance_storage_self_test(R4PerformanceView *view, R4ProgramInstanceStorageSelfTestResult *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->program_instance_storage_self_test != 0u && out != 0 ? ((R4DevProgramInstanceStorageSelfTestFn)(uintptr_t)table->program_instance_storage_self_test)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_registry_summary(R4PerformanceView *view, R4ProgramRegistrySummary *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->program_registry_summary != 0u && out != 0 ? ((R4DevProgramRegistrySummaryFn)(uintptr_t)table->program_registry_summary)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_registry_self_test(R4PerformanceView *view, R4ProgramRegistrySelfTestResult *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->program_registry_self_test != 0u && out != 0 ? ((R4DevProgramRegistrySelfTestFn)(uintptr_t)table->program_registry_self_test)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_registry_summary_v2(R4PerformanceView *view, R4ProgramRegistrySummaryV2 *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->program_registry_summary_v2 != 0u && out != 0 ? ((R4DevProgramRegistrySummaryV2Fn)(uintptr_t)table->program_registry_summary_v2)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_program_registry_self_test_v2(R4PerformanceView *view, R4ProgramRegistrySelfTestResultV2 *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->program_registry_self_test_v2 != 0u && out != 0 ? ((R4DevProgramRegistrySelfTestV2Fn)(uintptr_t)table->program_registry_self_test_v2)(out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_execution_inventory_summary(R4PerformanceView *view, R4ProgramInventorySummary *out) {
    if (out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (view == 0 || view->app == 0) return R4OS_ERR_NO_FN;
    return r4dev_execution_inventory_summary(&view->app->devices, out);
}
static inline int32_t r4_program_registry_summary_legacy(R4PerformanceView *view, R4ProgramRegistrySummary *out) { return r4_program_registry_summary(view, out); }
static inline int32_t r4_program_registry_self_test_legacy(R4PerformanceView *view, R4ProgramRegistrySelfTestResult *out) { return r4_program_registry_self_test(view, out); }
static inline int32_t r4_performance_task(R4PerformanceView *view, uint32_t index, R4ProgramTaskPerformanceInfo *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->performance_task != 0u && out != 0 ? ((R4DevPerformanceTaskFn)(uintptr_t)table->performance_task)(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_performance_storage(R4PerformanceView *view, uint32_t index, R4ProgramStoragePerformanceInfo *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->performance_storage != 0u && out != 0 ? ((R4DevPerformanceStorageFn)(uintptr_t)table->performance_storage)(index, out) : R4OS_ERR_NO_FN; }
static inline int32_t r4_performance_boot_phase(R4PerformanceView *view, uint32_t index, R4ProgramBootPhasePerformanceInfo *out) { const R4XStartR4Dev *table = view != 0 && view->app != 0 ? view->app->devices.table : 0; return table != 0 && table->performance_boot_phase != 0u && out != 0 ? ((R4DevPerformanceBootPhaseFn)(uintptr_t)table->performance_boot_phase)(index, out) : R4OS_ERR_NO_FN; }

#endif
