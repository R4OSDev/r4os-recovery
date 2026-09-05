#ifndef R4OS_R4DEV_H
#define R4OS_R4DEV_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

/* R4DEV is a built-in platform API provided by the kernel. It is resolved as
 * a group_interface import and has no R4L file. The table layout is declared
 * in <r4os/r4xstart.h> (R4XStartR4Dev). */

typedef struct R4Dev {
    const R4XStartR4Dev *table;
} R4Dev;

static inline int32_t r4dev_init(const R4XStartContext *ctx, R4Dev *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    out->table = 0;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4DEV);
    if (item == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Dev *table = (const R4XStartR4Dev *)(uintptr_t)item->table;
    if (table->magic != R4XSTART_R4DEV_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4XSTART_R4DEV_VERSION) return R4OS_ERROR_INVALID;
    if (table->size < offsetof(R4XStartR4Dev, performance_summary) + sizeof(uintptr_t)) return R4OS_ERROR_INVALID;
    if (table->performance_summary == 0) return R4OS_ERROR_INVALID;
    out->table = table;
    return R4OS_OK;
}

static inline int r4dev_available(const R4Dev *g) {
    return g != 0 && g->table != 0;
}

static inline int32_t r4dev_program_instance_storage_summary_legacy(
    const R4Dev *dev,
    R4ProgramInstanceStorageSummary *out_summary)
{
    if (out_summary == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        dev->table->size < offsetof(R4XStartR4Dev, program_instance_storage_summary) + sizeof(uintptr_t) ||
        dev->table->program_instance_storage_summary == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevProgramInstanceStorageSummaryFn summary_fn =
        (R4DevProgramInstanceStorageSummaryFn)(uintptr_t)dev->table->program_instance_storage_summary;
    return summary_fn(out_summary);
}

static inline int32_t r4dev_program_instance_storage_summary_v2(
    const R4Dev *dev,
    R4ProgramInstanceStorageSummary *out_summary)
{
    if (out_summary == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        dev->table->size < offsetof(R4XStartR4Dev, program_instance_storage_summary_v2) + sizeof(uintptr_t) ||
        dev->table->program_instance_storage_summary_v2 == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevProgramInstanceStorageSummaryV2Fn summary_fn =
        (R4DevProgramInstanceStorageSummaryV2Fn)(uintptr_t)dev->table->program_instance_storage_summary_v2;
    return summary_fn(out_summary);
}

static inline int32_t r4dev_execution_inventory_summary(
    const R4Dev *dev,
    R4ProgramInventorySummary *out_summary)
{
    if (out_summary == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        dev->table->size < offsetof(R4XStartR4Dev, execution_inventory_summary) + sizeof(uintptr_t) ||
        dev->table->execution_inventory_summary == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevExecutionInventorySummaryFn summary_fn =
        (R4DevExecutionInventorySummaryFn)(uintptr_t)dev->table->execution_inventory_summary;
    return summary_fn(out_summary);
}

static inline int32_t r4dev_performance_driver_work(
    const R4Dev *dev,
    uint32_t owner,
    R4ProgramDriverWorkPerformanceInfo *out_info)
{
    if (out_info == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        dev->table->size < offsetof(R4XStartR4Dev, performance_driver_work) + sizeof(uintptr_t) ||
        dev->table->performance_driver_work == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevPerformanceDriverWorkFn snapshot_fn =
        (R4DevPerformanceDriverWorkFn)(uintptr_t)dev->table->performance_driver_work;
    return snapshot_fn(owner, out_info);
}

static inline int32_t r4dev_performance_pci_inventory(
    const R4Dev *dev,
    R4ProgramPciInventoryPerformanceInfo *out_info)
{
    if (out_info == 0) return R4OS_ERROR_INVALID;
    if (!r4dev_available(dev) ||
        dev->table->size < offsetof(R4XStartR4Dev, performance_pci_inventory) + sizeof(uintptr_t) ||
        dev->table->performance_pci_inventory == 0)
    {
        return R4OS_ERR_NO_FN;
    }
    R4DevPerformancePciInventoryFn snapshot_fn =
        (R4DevPerformancePciInventoryFn)(uintptr_t)dev->table->performance_pci_inventory;
    return snapshot_fn(out_info);
}

#ifdef __cplusplus
}
#endif

#endif
