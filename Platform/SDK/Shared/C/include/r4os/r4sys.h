#ifndef R4OS_R4SYS_H
#define R4OS_R4SYS_H

#include "r4l.h"
#include "platform2.h"
#include "app_memory.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct R4SysVmAllocation {
    uint32_t magic;
    uint32_t region_id;
    uint64_t region_size;
    uint64_t requested_size;
    uintptr_t user_addr;
} R4SysVmAllocation;

typedef struct R4Sys {
    const R4XStartContext2 *ctx;
    const R4XStartR4Sys2 *table;
    const R4OS2Context *generation2;
    const R4App2Memory *memory2;
} R4Sys;

/* Per-operation slot admission. A file operation does not require an unrelated
 * service transport, nor does a handle status query require thread creation. */
static inline int r4sys_has_callback(const R4Sys *sys, size_t offset) {
    return sys && (sys->table && sys->table->magic == R4OS2_R4SYS_MAGIC && sys->table->abi_version >= 1 && sys->table->size >= 16) && offset <= sys->table->size && sizeof(uintptr_t) <= sys->table->size - offset;
}
static inline int r4sys_available(const R4Sys *sys) {
    return sys && (sys->generation2 ? R4OS2ContextGroup(sys->generation2, 1) != NULL : (sys->table && sys->table->magic == R4OS2_R4SYS_MAGIC && sys->table->abi_version >= 1 && sys->table->size >= 16));
}
static inline uintptr_t r4sys_callback(const R4Sys *sys, size_t offset) {
    if (!sys || offset > UINT32_MAX) return 0;
    if (sys->generation2) {
        uint64_t address;
        return R4OS2ContextFunction(sys->generation2, 1, offset, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!r4sys_has_callback(sys, offset)) return 0;
    return *(const uintptr_t *)((const uint8_t *)sys->table + offset);
}
#define R4SYS_SLOT(sys, field) r4sys_callback((sys), offsetof(R4XStartR4Sys2, field))
#define R4SYS_HAS(sys, field) (R4SYS_SLOT((sys), field) != 0)

/* The caller keeps this actual context view and its tables resident while
 * operations, worker callbacks and buffers borrow the system facade. */
static inline int32_t r4sys_init2(const R4OS2Context *context, const R4App2Memory *memory, R4Sys *out) {
    if (!out || !context || !context->raw || !R4OS2ContextGroup(context, 1)) return R4OS_ERR_NO_GROUP;
    const R4Sys value = {.ctx = NULL, .table = NULL, .generation2 = context, .memory2 = memory};
    *out = value;
    return 0;
}

/* Actual path-mount snapshot; the final file need not exist. Unknown provider
 * or unavailable callback returns UNSUPPORTED and leaves output untouched. */
static inline int32_t r4sys_file_name_limits(const R4Sys *sys, const char *path, R4FileNameLimits *out) {
    if (!path || !out) return R4OS_FILE_STREAM_ERROR_INVALID;
    if (!R4SYS_HAS(sys, file_name_limits)) return R4OS_FILE_STREAM_ERROR_UNSUPPORTED;
    return ((R4SysFileNameLimitsFn)(uintptr_t)R4SYS_SLOT(sys, file_name_limits))((const uint8_t *)path, out);
}

/* Pure replay-scope query: 1 supported, 0 outside scope, negative invalid or
 * unavailable. No mount reservation, file I/O or software-version check. */
static inline int32_t r4sys_system_update_target_supported(const R4Sys *sys, const char *path) {
    if (!path) return R4OS_ERROR_INVALID;
    if (!R4SYS_HAS(sys, system_update_target_supported)) return R4OS_ERR_NO_FN;
    return ((R4SysSystemUpdateTargetSupportedFn)(uintptr_t)R4SYS_SLOT(sys, system_update_target_supported))((const uint8_t *)path);
}

/* Optional explicit blocking orderly transition; accepted work is terminal.
 * Old raw slots remain independent immediate operations. No automatic retry. */
static inline int32_t r4sys_system_power_transition(const R4Sys *sys,uint32_t action,uint64_t timeout_ticks){
    if(action>R4OS_POWER_TRANSITION_ACTION_POWEROFF)return R4OS_POWER_TRANSITION_ERROR_INVALID;
    if(!R4SYS_HAS(sys,system_power_transition))return R4OS_ERR_NO_FN;
    return ((R4SysSystemPowerTransitionFn)(uintptr_t)R4SYS_SLOT(sys,system_power_transition))(action,timeout_ticks);
}


#define R4SYS_DIR_ENTRY_RESULT_END (-5)
static inline int32_t r4sys_platform_input_snapshot(R4Sys *sys, R4PlatformInputSnapshot *output) {
    if (!output) return R4OS_ERROR_INVALID;
    *output = (R4PlatformInputSnapshot){.version = 1, .size = sizeof(*output)};
    if (!r4sys_available(sys)) return R4OS_ERR_NO_GROUP;
    if (!R4SYS_HAS(sys, platform_input_snapshot) || !R4SYS_SLOT(sys, platform_input_snapshot)) return R4OS_ERR_NO_FN;
    return ((R4SysPlatformInputSnapshotFn)(uintptr_t)R4SYS_SLOT(sys, platform_input_snapshot))(output);
}

#define R4SYS_DIR_ENTRY_ERROR_IO (-9)
#define R4SYS_FILE_REPLACE_ATOMIC_OK 0
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_INVALID (-1)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_UNSUPPORTED (-2)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_NOT_FOUND (-3)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_BAD_PATH (-4)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_ALIAS (-5)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_CONFLICT (-6)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_IO (-7)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_NOT_ATOMIC (-8)
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_NAME_NOT_SUPPORTED R4OS_FILE_REPLACE_ATOMIC_ERROR_NAME_NOT_SUPPORTED
#define R4SYS_FILE_REPLACE_ATOMIC_ERROR_NAME_TOO_LONG R4OS_FILE_REPLACE_ATOMIC_ERROR_NAME_TOO_LONG
#define R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE (1u << 0)
#define R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_TARGET_ABSENT (1u << 1)
#define R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_OWNED_STAGE (1u << 2)
#define R4SYS_FILE_DELETE_IF_MATCH_NOT_FOUND 0
#define R4SYS_FILE_DELETE_IF_MATCH_DELETED 1
#define R4SYS_FILE_DELETE_IF_MATCH_ERROR_INVALID (-1)
#define R4SYS_FILE_DELETE_IF_MATCH_ERROR_UNSUPPORTED (-2)
#define R4SYS_FILE_DELETE_IF_MATCH_ERROR_CONFLICT (-3)
#define R4SYS_FILE_DELETE_IF_MATCH_ERROR_IO (-4)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_OK 0
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_INVALID (-1)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_UNSUPPORTED (-2)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_BAD_PATH (-3)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_CONFLICT (-4)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_IO (-5)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_NOT_ATOMIC (-6)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_FORWARD (1u << 0)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ROLLBACK (1u << 1)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_TARGET_EXISTED (1u << 2)
#define R4SYS_FILE_UPDATE_ATOMIC_CHECKED_OLD_KNOWN (1u << 3)
#define R4SYS_FILE_STREAM_OPEN_LEASE R4OS_FILE_STREAM_OPEN_LEASE
#define R4SYS_FILE_STREAM_FINISH_KEEP_OWNERSHIP (1u << 0)

static inline int32_t r4sys_file_copy_buffered(R4Sys *sys, const char *source, const char *target, uint8_t *buffer, uint32_t capacity, R4FileCopyProgress *progress) {
    if (source == 0 || target == 0 || buffer == 0 || capacity == 0 || progress == 0) return R4OS_FILE_STREAM_ERROR_INVALID;
    if (!r4sys_available(sys)) return R4OS_ERR_NO_GROUP;
    if (!R4SYS_HAS(sys, file_copy_buffered) || R4SYS_SLOT(sys, file_copy_buffered) == 0) return R4OS_ERR_NO_FN;
    return ((R4SysFileCopyBufferedFn)(uintptr_t)R4SYS_SLOT(sys, file_copy_buffered))((const uint8_t *)source, (const uint8_t *)target, buffer, capacity, progress);
}

static inline const R4XStartImport *r4xstart_find_import(const R4XStartContext2 *ctx, uint32_t group_id) {
    R4OS2Context validated;
    if (R4OS2ContextInit(ctx, &validated) != R4OS2_CONTEXT_OK) return NULL;
    uint32_t count = r4xstart_import_count(ctx);
    for (uint32_t i = 0; i < count; i += 1) {
        const R4XStartImport *item = r4xstart_import_at(ctx, i);
        if (item != 0 && item->group_id == group_id) return item;
    }
    return 0;
}

static inline int32_t r4sys_init(const R4XStartContext2 *ctx, R4Sys *out_sys) {
    if (out_sys == 0) return R4OS_ERROR_INVALID;
    out_sys->ctx = 0;
    out_sys->table = 0;
    out_sys->generation2 = 0;
    out_sys->memory2 = 0;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4SYS);
    if (item == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Sys2 *table = (const R4XStartR4Sys2 *)(uintptr_t)item->table;
    if (table->magic != R4OS2_R4SYS_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4OS2_R4SYS_VERSION) return R4OS_ERROR_INVALID;
    if (table->size < sizeof(R4XStartR4Sys2)) return R4OS_ERROR_INVALID;
    if (table->write == 0 || table->putc == 0) return R4OS_ERROR_INVALID;
    out_sys->ctx = ctx;
    out_sys->table = table;
    return R4OS_OK;
}

static inline int32_t r4sys_write(R4Sys *sys, const uint8_t *data, uint32_t len) {
    if (!r4sys_available(sys) || R4SYS_SLOT(sys, write) == 0) return R4OS_ERROR_INVALID;
    if (data == 0 || len == 0) return R4OS_OK;
    R4SysWriteFn write_fn = (R4SysWriteFn)(uintptr_t)R4SYS_SLOT(sys, write);
    return write_fn(data, len);
}

static inline void r4sys_putc(R4Sys *sys, uint8_t ch) {
    if (!r4sys_available(sys) || R4SYS_SLOT(sys, putc) == 0) return;
    R4SysPutcFn putc_fn = (R4SysPutcFn)(uintptr_t)R4SYS_SLOT(sys, putc);
    putc_fn(ch);
}

static inline uint32_t r4os_cstr_len(const char *text) {
    uint32_t len = 0;
    if (text == 0) return 0;
    while (text[len] != 0) len += 1;
    return len;
}

static inline int32_t r4sys_write_cstr(R4Sys *sys, const char *text) {
    return r4sys_write(sys, (const uint8_t *)text, r4os_cstr_len(text));
}

static inline int32_t r4sys_write_line(R4Sys *sys, const char *text) {
    int32_t rc = r4sys_write_cstr(sys, text);
    if (rc < 0) return rc;
    r4sys_putc(sys, '\r');
    r4sys_putc(sys, '\n');
    return R4OS_OK;
}

static inline void r4sys_sleep_ticks(R4Sys *sys, uint64_t ticks) {
    if (!r4sys_available(sys)) return;
    if (R4SYS_SLOT(sys, sleep_ticks) != 0) {
        R4SysSleepTicksFn sleep_fn = (R4SysSleepTicksFn)(uintptr_t)R4SYS_SLOT(sys, sleep_ticks);
        sleep_fn(ticks);
        return;
    }
    if (sys->generation2) { (void)R4OS2ContextYield(sys->generation2); return; }
    if (sys->ctx != 0 && sys->ctx->yield != 0) {
        R4XStartYieldFn2 yield_fn = (R4XStartYieldFn2)(uintptr_t)sys->ctx->yield;
        yield_fn(sys->ctx);
    }
}

static inline int r4sys_program_should_close(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (sys->generation2) return R4OS2ContextShouldClose(sys->generation2) != 0;
    if (sys->ctx != 0 &&
        (sys->ctx->flags & R4XSTART_FLAG_CLOSE_SUPPORTED) != 0 &&
        sys->ctx->should_close != 0)
    {
        R4XStartShouldCloseFn2 close_fn = (R4XStartShouldCloseFn2)(uintptr_t)sys->ctx->should_close;
        return close_fn(sys->ctx) != 0;
    }
    if (R4SYS_SLOT(sys, program_should_close) != 0) {
        R4SysProgramShouldCloseFn close_fn = (R4SysProgramShouldCloseFn)(uintptr_t)R4SYS_SLOT(sys, program_should_close);
        return close_fn() != 0;
    }
    return 0;
}

static inline int r4sys_supports_vm(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, vm_query)) return 0;
    return R4SYS_SLOT(sys, vm_reserve) != 0 &&
        R4SYS_SLOT(sys, vm_commit) != 0 &&
        R4SYS_SLOT(sys, vm_decommit) != 0 &&
        R4SYS_SLOT(sys, vm_release) != 0 &&
        R4SYS_SLOT(sys, vm_query) != 0;
}

static inline int r4sys_supports_threads(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, thread_status)) return 0;
    return R4SYS_SLOT(sys, thread_create) != 0 &&
        R4SYS_SLOT(sys, thread_exit) != 0 &&
        R4SYS_SLOT(sys, thread_join) != 0 &&
        R4SYS_SLOT(sys, thread_current) != 0 &&
        R4SYS_SLOT(sys, thread_status) != 0;
}

static inline int32_t r4sys_thread_create(R4Sys *sys, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes, uint32_t *out_thread_id) {
    if (!R4SYS_HAS(sys, thread_create) || entry == 0 || out_thread_id == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadCreateFn create_fn = (R4SysThreadCreateFn)(uintptr_t)R4SYS_SLOT(sys, thread_create);
    return create_fn(entry, arg, stack_reserve_bytes, 0, out_thread_id);
}

static inline void r4sys_thread_exit(R4Sys *sys, int32_t exit_code) {
    if (!R4SYS_HAS(sys, thread_exit)) return;
    R4SysThreadExitFn exit_fn = (R4SysThreadExitFn)(uintptr_t)R4SYS_SLOT(sys, thread_exit);
    exit_fn(exit_code);
}

static inline int32_t r4sys_thread_join(R4Sys *sys, uint32_t thread_id, uint64_t timeout_ticks, int32_t *out_exit_code) {
    if (!R4SYS_HAS(sys, thread_join) || out_exit_code == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadJoinFn join_fn = (R4SysThreadJoinFn)(uintptr_t)R4SYS_SLOT(sys, thread_join);
    return join_fn(thread_id, timeout_ticks, out_exit_code);
}

static inline uint32_t r4sys_thread_current(R4Sys *sys) {
    if (!R4SYS_HAS(sys, thread_current)) return 0;
    R4SysThreadCurrentFn current_fn = (R4SysThreadCurrentFn)(uintptr_t)R4SYS_SLOT(sys, thread_current);
    return current_fn();
}

/* Borrow an exact identity; this does not create a join lease or pin. */
static inline int32_t r4sys_thread_current_handle(R4Sys *sys, R4ProgramJoinHandle *out_handle) {
    if (out_handle == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!r4sys_available(sys) ||
        !R4SYS_HAS(sys, thread_current_handle) ||
        R4SYS_SLOT(sys, thread_current_handle) == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadCurrentHandleFn current_fn = (R4SysThreadCurrentHandleFn)(uintptr_t)R4SYS_SLOT(sys, thread_current_handle);
    return current_fn(out_handle);
}

/* word_capacity0 queries metadata. Explicit sets use the discovered length.
 * New functions remain optional on older kernels; failures preserve outputs. */
static inline int32_t r4sys_thread_placement_get(R4Sys *sys, const R4ProgramJoinHandle *handle,
    R4ThreadPlacementInfo *info, uint64_t *cpus, uint32_t word_capacity) {
    if (!r4sys_available(sys) ||
        !R4SYS_HAS(sys, thread_placement_get) ||
        R4SYS_SLOT(sys, thread_placement_get) == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadPlacementGetFn query = (R4SysThreadPlacementGetFn)(uintptr_t)R4SYS_SLOT(sys, thread_placement_get);
    return query(handle, info, cpus, word_capacity);
}
static inline int32_t r4sys_thread_placement_set(R4Sys *sys, const R4ProgramJoinHandle *handle,
    const R4ThreadPlacementRequest *request, const uint64_t *cpus, uint32_t word_count) {
    if (!r4sys_available(sys) ||
        !R4SYS_HAS(sys, thread_placement_set) ||
        R4SYS_SLOT(sys, thread_placement_set) == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadPlacementSetFn change = (R4SysThreadPlacementSetFn)(uintptr_t)R4SYS_SLOT(sys, thread_placement_set);
    return change(handle, request, cpus, word_count);
}

/* Advisory scheduler capacity, without an affinity or hardware topology claim. */
static inline int32_t r4sys_cpu_capacity(R4Sys *sys, R4CpuCapacity *output) {
    if (output == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!r4sys_available(sys) ||
        !R4SYS_HAS(sys, cpu_capacity) ||
        R4SYS_SLOT(sys, cpu_capacity) == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysCpuCapacityFn query = (R4SysCpuCapacityFn)(uintptr_t)R4SYS_SLOT(sys, cpu_capacity);
    return query(output);
}

/* Process-wide even from a worker; returns only on admission error.
 * Does not run user destructors. Reason is NATURAL or FAILED. */
static inline int32_t r4sys_program_exit(R4Sys *sys, int32_t exit_code, uint32_t reason) {
    if (!r4sys_available(sys) ||
        !R4SYS_HAS(sys, program_exit) ||
        R4SYS_SLOT(sys, program_exit) == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysProgramExitFn terminate = (R4SysProgramExitFn)(uintptr_t)R4SYS_SLOT(sys, program_exit);
    return terminate(exit_code, reason);
}

static inline int32_t r4sys_thread_status(R4Sys *sys, uint32_t thread_id, R4ProgramThreadInfo *out_info) {
    if (!R4SYS_HAS(sys, thread_status) || out_info == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadStatusFn status_fn = (R4SysThreadStatusFn)(uintptr_t)R4SYS_SLOT(sys, thread_status);
    return status_fn(thread_id, out_info);
}

/* Explicit lifecycle metadata capability, independent of diagnostic inventory. */
static inline int r4sys_supports_program_lifecycle(R4Sys *sys) {
    return r4sys_available(sys) &&
        R4SYS_HAS(sys, program_lifecycle_programs) &&
        R4SYS_SLOT(sys, program_lifecycle_begin) != 0 && R4SYS_SLOT(sys, program_lifecycle_programs) != 0;
}
static inline int32_t r4sys_program_lifecycle_begin(R4Sys *sys, R4ProgramInventoryCursor *cursor) {
    if (cursor == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4sys_supports_program_lifecycle(sys)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramLifecycleBeginFn)(uintptr_t)R4SYS_SLOT(sys, program_lifecycle_begin))(cursor);
}
static inline int32_t r4sys_program_lifecycle_programs(R4Sys *sys, R4ProgramInventoryCursor *cursor,
    R4ProgramLifecycleSnapshot *out, uint32_t capacity, R4ProgramInventoryPageInfo *page) {
    if (cursor == 0 || out == 0 || page == 0 || capacity == 0u || capacity > R4OS_PROGRAM_INVENTORY_PAGE_MAX)
        return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4sys_supports_program_lifecycle(sys)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramLifecycleProgramsFn)(uintptr_t)R4SYS_SLOT(sys, program_lifecycle_programs))(cursor, out, capacity, page);
}

static inline int r4sys_supports_program_inventory(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, program_inventory_threads)) return 0;
    return R4SYS_SLOT(sys, program_inventory_begin) != 0 &&
        R4SYS_SLOT(sys, program_inventory_programs) != 0 &&
        R4SYS_SLOT(sys, program_inventory_tasks) != 0 &&
        R4SYS_SLOT(sys, program_inventory_threads) != 0;
}

static inline int32_t r4sys_program_inventory_begin(
    R4Sys *sys,
    R4ProgramInventoryCursor *cursor,
    R4ProgramInventorySummary *out_summary)
{
    if (cursor == 0 || out_summary == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4sys_supports_program_inventory(sys)) return R4OS_ERR_NO_FN;
    R4SysProgramInventoryBeginFn inventory_fn =
        (R4SysProgramInventoryBeginFn)(uintptr_t)R4SYS_SLOT(sys, program_inventory_begin);
    return inventory_fn(cursor, out_summary);
}

static inline int32_t r4sys_program_inventory_programs(
    R4Sys *sys,
    R4ProgramInventoryCursor *cursor,
    R4ProgramInstanceSnapshot *out,
    uint32_t capacity,
    R4ProgramInventoryPageInfo *out_page)
{
    if (cursor == 0 || out == 0 || out_page == 0 ||
        capacity == 0u || capacity > R4OS_PROGRAM_INVENTORY_PAGE_MAX)
    {
        return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    }
    if (!r4sys_supports_program_inventory(sys)) return R4OS_ERR_NO_FN;
    R4SysProgramInventoryProgramsFn inventory_fn =
        (R4SysProgramInventoryProgramsFn)(uintptr_t)R4SYS_SLOT(sys, program_inventory_programs);
    return inventory_fn(cursor, out, capacity, out_page);
}

static inline int32_t r4sys_program_inventory_tasks(
    R4Sys *sys,
    R4ProgramInventoryCursor *cursor,
    R4ProgramTaskSnapshot *out,
    uint32_t capacity,
    R4ProgramInventoryPageInfo *out_page)
{
    if (cursor == 0 || out == 0 || out_page == 0 ||
        capacity == 0u || capacity > R4OS_PROGRAM_INVENTORY_PAGE_MAX)
    {
        return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    }
    if (!r4sys_supports_program_inventory(sys)) return R4OS_ERR_NO_FN;
    R4SysProgramInventoryTasksFn inventory_fn =
        (R4SysProgramInventoryTasksFn)(uintptr_t)R4SYS_SLOT(sys, program_inventory_tasks);
    return inventory_fn(cursor, out, capacity, out_page);
}

static inline int32_t r4sys_program_inventory_threads(
    R4Sys *sys,
    R4ProgramInventoryCursor *cursor,
    R4ProgramThreadSnapshot *out,
    uint32_t capacity,
    R4ProgramInventoryPageInfo *out_page)
{
    if (cursor == 0 || out == 0 || out_page == 0 ||
        capacity == 0u || capacity > R4OS_PROGRAM_INVENTORY_PAGE_MAX)
    {
        return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    }
    if (!r4sys_supports_program_inventory(sys)) return R4OS_ERR_NO_FN;
    R4SysProgramInventoryThreadsFn inventory_fn =
        (R4SysProgramInventoryThreadsFn)(uintptr_t)R4SYS_SLOT(sys, program_inventory_threads);
    return inventory_fn(cursor, out, capacity, out_page);
}

static inline int r4sys_supports_registry_snapshot(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, registry_snapshot_page)) return 0;
    return R4SYS_SLOT(sys, registry_snapshot_begin) != 0 && R4SYS_SLOT(sys, registry_snapshot_page) != 0;
}

static inline int32_t r4sys_registry_snapshot_begin(
    R4Sys *sys,
    const uint8_t *key_path,
    uint32_t kind,
    R4RegistrySnapshotCursor *cursor)
{
    if (key_path == 0 || cursor == 0) return R4OS_REGISTRY_API_RESULT_INVALID;
    if (!r4sys_supports_registry_snapshot(sys)) return R4OS_ERR_NO_FN;
    R4SysRegistrySnapshotBeginFn begin_fn =
        (R4SysRegistrySnapshotBeginFn)(uintptr_t)R4SYS_SLOT(sys, registry_snapshot_begin);
    return begin_fn(key_path, kind, cursor);
}

static inline int32_t r4sys_registry_snapshot_page(
    R4Sys *sys,
    R4RegistrySnapshotCursor *cursor,
    R4RegistrySnapshotEntry *entries,
    uint32_t entry_capacity,
    uint8_t *data,
    uint32_t data_capacity,
    R4RegistrySnapshotPageInfo *out_page)
{
    if (cursor == 0 || entries == 0 || data == 0 || out_page == 0 ||
        entry_capacity == 0u || entry_capacity > R4OS_REGISTRY_SNAPSHOT_PAGE_MAX ||
        data_capacity > R4OS_REGISTRY_SNAPSHOT_DATA_MAX)
    {
        return R4OS_REGISTRY_API_RESULT_INVALID;
    }
    if (!r4sys_supports_registry_snapshot(sys)) return R4OS_ERR_NO_FN;
    R4SysRegistrySnapshotPageFn page_fn =
        (R4SysRegistrySnapshotPageFn)(uintptr_t)R4SYS_SLOT(sys, registry_snapshot_page);
    return page_fn(cursor, entries, entry_capacity, data, data_capacity, out_page);
}

static inline int r4sys_supports_registry_batch(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, registry_batch_mutate)) return 0;
    return R4SYS_SLOT(sys, registry_batch_mutate) != 0;
}

static inline int32_t r4sys_registry_batch_mutate(
    R4Sys *sys,
    const R4RegistryBatchOperation *operations,
    uint32_t operation_count,
    const uint8_t *blob,
    uint32_t blob_len,
    R4RegistryBatchResult *out_result)
{
    if (operations == 0 || operation_count == 0u || blob == 0 || out_result == 0 ||
        operation_count > R4OS_REGISTRY_BATCH_OPERATION_MAX || blob_len > R4OS_REGISTRY_BATCH_BLOB_MAX)
    {
        return R4OS_REGISTRY_API_RESULT_INVALID;
    }
    if (!r4sys_supports_registry_batch(sys)) return R4OS_ERR_NO_FN;
    R4SysRegistryBatchMutateFn batch_fn =
        (R4SysRegistryBatchMutateFn)(uintptr_t)R4SYS_SLOT(sys, registry_batch_mutate);
    return batch_fn(operations, operation_count, blob, blob_len, out_result);
}

static inline int r4sys_supports_thread_handles(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, thread_handle_status)) return 0;
    return R4SYS_SLOT(sys, thread_create_handle) != 0 &&
        R4SYS_SLOT(sys, thread_handle_join) != 0 &&
        R4SYS_SLOT(sys, thread_handle_status) != 0;
}

static inline int32_t r4sys_thread_create_handle(
    R4Sys *sys,
    R4ThreadEntryFn entry,
    uintptr_t arg,
    uint64_t stack_reserve_bytes,
    uint32_t flags,
    R4ProgramJoinHandle *out_handle)
{
    if (out_handle != 0) *out_handle = (R4ProgramJoinHandle){0};
    if (entry == 0 || out_handle == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!R4SYS_HAS(sys, thread_create_handle)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadCreateHandleFn create_fn =
        (R4SysThreadCreateHandleFn)(uintptr_t)R4SYS_SLOT(sys, thread_create_handle);
    return create_fn(entry, (uint64_t)arg, stack_reserve_bytes, flags, out_handle);
}

/* Requires META=runtime.workers=owned-v1; native admission owns the policy. */
static inline int32_t r4sys_compute_worker_create(
    R4Sys *sys, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes,
    R4ProgramJoinHandle *out_handle)
{
    return r4sys_thread_create_handle(sys, entry, arg, stack_reserve_bytes,
        R4OS_THREAD_CREATE_FLAG_COMPUTE_WORKER, out_handle);
}

static inline int32_t r4sys_thread_handle_join(
    R4Sys *sys,
    const R4ProgramJoinHandle *handle,
    uint64_t timeout_ticks,
    int32_t *out_exit_code)
{
    if (handle == 0 || out_exit_code == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!R4SYS_HAS(sys, thread_handle_join)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadHandleJoinFn join_fn =
        (R4SysThreadHandleJoinFn)(uintptr_t)R4SYS_SLOT(sys, thread_handle_join);
    return join_fn(handle, timeout_ticks, out_exit_code);
}

static inline int32_t r4sys_thread_handle_status(
    R4Sys *sys,
    const R4ProgramJoinHandle *handle,
    R4ProgramThreadInfo *out_info)
{
    if (handle == 0 || out_info == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!R4SYS_HAS(sys, thread_handle_status)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadHandleStatusFn status_fn =
        (R4SysThreadHandleStatusFn)(uintptr_t)R4SYS_SLOT(sys, thread_handle_status);
    return status_fn(handle, out_info);
}

static inline int r4sys_supports_file_replace_atomic(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, file_replace_atomic)) return 0;
    return R4SYS_SLOT(sys, file_replace_atomic) != 0;
}

static inline int32_t r4sys_file_replace_atomic_flags(
    R4Sys *sys,
    const char *target_path,
    const char *staged_path,
    const char *backup_path,
    uint32_t flags)
{
    if (!r4sys_supports_file_replace_atomic(sys)) return R4SYS_FILE_REPLACE_ATOMIC_ERROR_UNSUPPORTED;
    if (target_path == 0 || staged_path == 0 || backup_path == 0) return R4SYS_FILE_REPLACE_ATOMIC_ERROR_INVALID;
    R4SysFileReplaceAtomicFn replace_fn =
        (R4SysFileReplaceAtomicFn)(uintptr_t)R4SYS_SLOT(sys, file_replace_atomic);
    return replace_fn(
        (const uint8_t *)target_path,
        (const uint8_t *)staged_path,
        (const uint8_t *)backup_path,
        flags);
}

static inline int32_t r4sys_file_replace_atomic(
    R4Sys *sys,
    const char *target_path,
    const char *staged_path,
    const char *backup_path)
{
    return r4sys_file_replace_atomic_flags(
        sys,
        target_path,
        staged_path,
        backup_path,
        R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE);
}

static inline int r4sys_supports_file_delete_if_match(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, file_delete_if_match)) return 0;
    return R4SYS_SLOT(sys, file_delete_if_match) != 0;
}

static inline int32_t r4sys_file_delete_if_match(
    R4Sys *sys,
    const char *path,
    uint64_t expected_size,
    uint32_t expected_checksum)
{
    if (!r4sys_supports_file_delete_if_match(sys)) return R4SYS_FILE_DELETE_IF_MATCH_ERROR_UNSUPPORTED;
    if (path == 0) return R4SYS_FILE_DELETE_IF_MATCH_ERROR_INVALID;
    R4SysFileDeleteIfMatchFn delete_fn =
        (R4SysFileDeleteIfMatchFn)(uintptr_t)R4SYS_SLOT(sys, file_delete_if_match);
    return delete_fn((const uint8_t *)path, expected_size, expected_checksum);
}

static inline int r4sys_supports_file_update_atomic_checked(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, file_update_atomic_checked)) return 0;
    return R4SYS_SLOT(sys, file_update_atomic_checked) != 0;
}

static inline int32_t r4sys_file_update_atomic_checked(
    R4Sys *sys,
    const char *target_path,
    const char *staged_path,
    const char *backup_path,
    uint64_t new_size,
    uint32_t new_checksum,
    uint64_t old_size,
    uint32_t old_checksum,
    uint32_t flags)
{
    if (!r4sys_supports_file_update_atomic_checked(sys)) {
        return R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_UNSUPPORTED;
    }
    if (target_path == 0 || staged_path == 0 || backup_path == 0) {
        return R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_INVALID;
    }
    R4SysFileUpdateAtomicCheckedFn update_fn =
        (R4SysFileUpdateAtomicCheckedFn)(uintptr_t)R4SYS_SLOT(sys, file_update_atomic_checked);
    return update_fn(
        (const uint8_t *)target_path,
        (const uint8_t *)staged_path,
        (const uint8_t *)backup_path,
        new_size,
        new_checksum,
        old_size,
        old_checksum,
        flags);
}

static inline int r4sys_supports_async_io(R4Sys *sys) {
    if (!r4sys_available(sys)) return 0;
    if (!R4SYS_HAS(sys, io_close)) return 0;
    return R4SYS_SLOT(sys, io_file_read) != 0 &&
        R4SYS_SLOT(sys, io_file_write) != 0 &&
        R4SYS_SLOT(sys, io_file_stream_write) != 0 &&
        R4SYS_SLOT(sys, io_service_call) != 0 &&
        R4SYS_SLOT(sys, io_status) != 0 &&
        R4SYS_SLOT(sys, io_wait) != 0 &&
        R4SYS_SLOT(sys, io_close) != 0;
}

static inline int32_t r4sys_io_file_read(R4Sys *sys, const char *path, uint8_t *out, uint64_t capacity, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_read) || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileReadFn io_fn = (R4SysIoFileReadFn)(uintptr_t)R4SYS_SLOT(sys, io_file_read);
    return io_fn((const uint8_t *)path, out, capacity, flags, out_request_id);
}

static inline int32_t r4sys_io_file_read_at(R4Sys *sys, const char *path, uint64_t offset, uint8_t *out, uint64_t capacity, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_read_at) || R4SYS_SLOT(sys, io_file_read_at) == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileReadAtFn io_fn = (R4SysIoFileReadAtFn)(uintptr_t)R4SYS_SLOT(sys, io_file_read_at);
    return io_fn((const uint8_t *)path, offset, out, capacity, flags, out_request_id);
}

static inline int32_t r4sys_io_file_write(R4Sys *sys, const char *path, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_write) || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileWriteFn io_fn = (R4SysIoFileWriteFn)(uintptr_t)R4SYS_SLOT(sys, io_file_write);
    return io_fn((const uint8_t *)path, data, len, flags, out_request_id);
}

static inline int32_t r4sys_io_file_append(R4Sys *sys, const char *path, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_append) || R4SYS_SLOT(sys, io_file_append) == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileAppendFn io_fn = (R4SysIoFileAppendFn)(uintptr_t)R4SYS_SLOT(sys, io_file_append);
    return io_fn((const uint8_t *)path, data, len, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_begin(R4Sys *sys, const char *path, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_stream_begin) || R4SYS_SLOT(sys, io_file_stream_begin) == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamBeginFn io_fn = (R4SysIoFileStreamBeginFn)(uintptr_t)R4SYS_SLOT(sys, io_file_stream_begin);
    return io_fn((const uint8_t *)path, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_write(R4Sys *sys, const char *path, uint64_t offset, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_stream_write) || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamWriteFn io_fn = (R4SysIoFileStreamWriteFn)(uintptr_t)R4SYS_SLOT(sys, io_file_stream_write);
    return io_fn((const uint8_t *)path, offset, data, len, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_finish(R4Sys *sys, const char *path, uint64_t expected_size, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_stream_finish) || R4SYS_SLOT(sys, io_file_stream_finish) == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamFinishFn io_fn = (R4SysIoFileStreamFinishFn)(uintptr_t)R4SYS_SLOT(sys, io_file_stream_finish);
    return io_fn((const uint8_t *)path, expected_size, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_abort(R4Sys *sys, const char *path, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_file_stream_abort) || R4SYS_SLOT(sys, io_file_stream_abort) == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamAbortFn io_fn = (R4SysIoFileStreamAbortFn)(uintptr_t)R4SYS_SLOT(sys, io_file_stream_abort);
    return io_fn((const uint8_t *)path, out_request_id);
}

static inline int32_t r4sys_io_service_call(R4Sys *sys, uint32_t handle, uint16_t op, const uint8_t *request, uint32_t request_len, void *response_header, uint8_t *response, uint32_t response_capacity, uint64_t timeout_ticks, uint32_t flags, uint32_t *out_request_id) {
    if (!R4SYS_HAS(sys, io_service_call) || response_header == 0 || response == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoServiceCallFn io_fn = (R4SysIoServiceCallFn)(uintptr_t)R4SYS_SLOT(sys, io_service_call);
    return io_fn(handle, op, request, request_len, (R4ServiceMessageHeader *)response_header, response, response_capacity, timeout_ticks, flags, out_request_id);
}

static inline int32_t r4sys_io_status(R4Sys *sys, uint32_t request_id, R4ProgramIoInfo *out_info) {
    if (!R4SYS_HAS(sys, io_status) || out_info == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoStatusFn io_fn = (R4SysIoStatusFn)(uintptr_t)R4SYS_SLOT(sys, io_status);
    return io_fn(request_id, out_info);
}

static inline int32_t r4sys_io_wait(R4Sys *sys, uint32_t request_id, uint64_t timeout_ticks, R4ProgramIoInfo *out_info) {
    if (!R4SYS_HAS(sys, io_wait) || out_info == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoWaitFn io_fn = (R4SysIoWaitFn)(uintptr_t)R4SYS_SLOT(sys, io_wait);
    return io_fn(request_id, timeout_ticks, out_info);
}

static inline int32_t r4sys_io_close(R4Sys *sys, uint32_t request_id) {
    if (!R4SYS_HAS(sys, io_close)) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoCloseFn io_fn = (R4SysIoCloseFn)(uintptr_t)R4SYS_SLOT(sys, io_close);
    return io_fn(request_id);
}

static inline int32_t r4sys_vm_reserve(R4Sys *sys, uint64_t size, uint64_t alignment, uint64_t flags, R4ProgramVmRegionInfo *out_info) {
    if (!R4SYS_HAS(sys, vm_reserve) || out_info == 0) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmReserveFn vm_fn = (R4SysVmReserveFn)(uintptr_t)R4SYS_SLOT(sys, vm_reserve);
    return vm_fn(size, alignment, flags, out_info);
}

static inline int32_t r4sys_vm_commit(R4Sys *sys, uint32_t region_id, uint64_t offset, uint64_t len) {
    if (!R4SYS_HAS(sys, vm_commit)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmCommitFn vm_fn = (R4SysVmCommitFn)(uintptr_t)R4SYS_SLOT(sys, vm_commit);
    return vm_fn(region_id, offset, len, 0);
}

static inline int32_t r4sys_vm_commit_flags(R4Sys *sys, uint32_t region_id, uint64_t offset, uint64_t len, uint64_t flags) {
    if (!R4SYS_HAS(sys, vm_commit)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmCommitFn vm_fn = (R4SysVmCommitFn)(uintptr_t)R4SYS_SLOT(sys, vm_commit);
    return vm_fn(region_id, offset, len, flags);
}

static inline int32_t r4sys_vm_decommit(R4Sys *sys, uint32_t region_id, uint64_t offset, uint64_t len) {
    if (!R4SYS_HAS(sys, vm_decommit)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmDecommitFn vm_fn = (R4SysVmDecommitFn)(uintptr_t)R4SYS_SLOT(sys, vm_decommit);
    return vm_fn(region_id, offset, len);
}

static inline int32_t r4sys_vm_release(R4Sys *sys, uint32_t region_id) {
    if (!R4SYS_HAS(sys, vm_release)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmReleaseFn vm_fn = (R4SysVmReleaseFn)(uintptr_t)R4SYS_SLOT(sys, vm_release);
    return vm_fn(region_id);
}

static inline int32_t r4sys_vm_query(R4Sys *sys, uint32_t region_id, R4ProgramVmRegionInfo *out_info) {
    if (!R4SYS_HAS(sys, vm_query) || out_info == 0) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmQueryFn vm_fn = (R4SysVmQueryFn)(uintptr_t)R4SYS_SLOT(sys, vm_query);
    return vm_fn(region_id, out_info);
}

static inline uint64_t r4sys_align_up_u64(uint64_t value, uint64_t alignment) {
    uint64_t mask = alignment - 1u;
    return (value + mask) & ~mask;
}

static inline void *r4sys_vm_alloc(R4Sys *sys, uint64_t size, uint64_t alignment) {
    if (sys && sys->generation2) {
        if (!sys->memory2 || !sys->generation2->raw || !size || size > SIZE_MAX || alignment > SIZE_MAX) return NULL;
        const uint64_t owner = sys->generation2->raw->instance_id;
        if (R4SdkHeapBind2(sys->memory2, owner) != 0) return NULL;
        return R4SdkHeapAlloc2(sys->memory2, owner, (size_t)size, (size_t)alignment);
    }
    if (size == 0 || !r4sys_supports_vm(sys)) return 0;
    if (alignment < sizeof(uintptr_t)) alignment = sizeof(uintptr_t);
    if ((alignment & (alignment - 1u)) != 0) return 0;
    uint64_t reserve_alignment = alignment > 4096u ? alignment : 4096u;
    const uint64_t overhead = sizeof(R4SysVmAllocation) + sizeof(uintptr_t);
    if (size > UINT64_MAX - overhead) return 0;
    uint64_t need = size + overhead;
    if (need > UINT64_MAX - (alignment - 1u)) return 0;
    need += alignment - 1u;
    if (need > UINT64_MAX - 4095u) return 0;
    uint64_t region_size = r4sys_align_up_u64(need, 4096u);
    R4ProgramVmRegionInfo info;
    if (r4sys_vm_reserve(sys, region_size, reserve_alignment, R4OS_VM_REGION_FLAGS_DEFAULT, &info) != R4OS_VM_OK) return 0;
    if (r4sys_vm_commit(sys, info.id, 0, region_size) != R4OS_VM_OK) {
        r4sys_vm_release(sys, info.id);
        return 0;
    }
    uintptr_t base = (uintptr_t)info.base;
    uintptr_t min_user = base + sizeof(R4SysVmAllocation) + sizeof(uintptr_t);
    uintptr_t user = (uintptr_t)r4sys_align_up_u64((uint64_t)min_user, alignment);
    uintptr_t *backref = (uintptr_t *)(user - sizeof(uintptr_t));
    R4SysVmAllocation *header = (R4SysVmAllocation *)base;
    header->magic = 0x32434D52u;
    header->region_id = info.id;
    header->region_size = region_size;
    header->requested_size = size;
    header->user_addr = user;
    *backref = base;
    return (void *)user;
}

static inline int32_t r4sys_vm_free(R4Sys *sys, void *ptr) {
    if (sys && sys->generation2) {
        if (!sys->memory2 || !sys->generation2->raw) return R4OS_ERROR_INVALID;
        return R4SdkHeapFree2(sys->memory2, sys->generation2->raw->instance_id, ptr);
    }
    if (ptr == 0 || !r4sys_supports_vm(sys)) return R4OS_ERROR_INVALID;
    uintptr_t user = (uintptr_t)ptr;
    uintptr_t *backref = (uintptr_t *)(user - sizeof(uintptr_t));
    R4SysVmAllocation *header = (R4SysVmAllocation *)(*backref);
    if (header == 0 || header->magic != 0x32434D52u || header->user_addr != user) return R4OS_ERROR_INVALID;
    uint32_t region_id = header->region_id;
    header->magic = 0;
    return r4sys_vm_release(sys, region_id);
}

int32_t r4_main(const R4XStartContext2 *ctx, R4Sys *sys);

#ifdef __cplusplus
}
#endif

#endif
