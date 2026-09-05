#ifndef R4OS_R4SYS_H
#define R4OS_R4SYS_H

#include "r4l.h"

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
    const R4XStartContext *ctx;
    const R4XStartR4Sys *table;
} R4Sys;

#define R4SYS_DIR_ENTRY_RESULT_END (-5)
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

static inline const R4XStartImport *r4xstart_find_import(const R4XStartContext *ctx, uint32_t group_id) {
    uint32_t count = r4xstart_import_count(ctx);
    for (uint32_t i = 0; i < count; i += 1) {
        const R4XStartImport *item = r4xstart_import_at(ctx, i);
        if (item != 0 && item->group_id == group_id) return item;
    }
    return 0;
}

static inline int32_t r4sys_init(const R4XStartContext *ctx, R4Sys *out_sys) {
    if (out_sys == 0) return R4OS_ERROR_INVALID;
    out_sys->ctx = 0;
    out_sys->table = 0;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4SYS);
    if (item == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Sys *table = (const R4XStartR4Sys *)(uintptr_t)item->table;
    if (table->magic != R4XSTART_R4SYS_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4XSTART_R4SYS_VERSION) return R4OS_ERROR_INVALID;
    if (table->size < R4XSTART_R4SYS_SIZE) return R4OS_ERROR_INVALID;
    if (table->write == 0 || table->putc == 0) return R4OS_ERROR_INVALID;
    out_sys->ctx = ctx;
    out_sys->table = table;
    return R4OS_OK;
}

static inline int32_t r4sys_write(R4Sys *sys, const uint8_t *data, uint32_t len) {
    if (sys == 0 || sys->table == 0 || sys->table->write == 0) return R4OS_ERROR_INVALID;
    if (data == 0 || len == 0) return R4OS_OK;
    R4SysWriteFn write_fn = (R4SysWriteFn)(uintptr_t)sys->table->write;
    return write_fn(data, len);
}

static inline void r4sys_putc(R4Sys *sys, uint8_t ch) {
    if (sys == 0 || sys->table == 0 || sys->table->putc == 0) return;
    R4SysPutcFn putc_fn = (R4SysPutcFn)(uintptr_t)sys->table->putc;
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
    if (sys == 0 || sys->table == 0) return;
    if (sys->table->sleep_ticks != 0) {
        R4SysSleepTicksFn sleep_fn = (R4SysSleepTicksFn)(uintptr_t)sys->table->sleep_ticks;
        sleep_fn(ticks);
        return;
    }
    if (sys->ctx != 0 && sys->ctx->yield != 0) {
        R4XStartYieldFn yield_fn = (R4XStartYieldFn)(uintptr_t)sys->ctx->yield;
        yield_fn(sys->ctx);
    }
}

static inline int r4sys_program_should_close(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->ctx != 0 &&
        (sys->ctx->flags & R4XSTART_FLAG_CLOSE_SUPPORTED) != 0 &&
        sys->ctx->should_close != 0)
    {
        R4XStartShouldCloseFn close_fn = (R4XStartShouldCloseFn)(uintptr_t)sys->ctx->should_close;
        return close_fn(sys->ctx) != 0;
    }
    if (sys->table->program_should_close != 0) {
        R4SysProgramShouldCloseFn close_fn = (R4SysProgramShouldCloseFn)(uintptr_t)sys->table->program_should_close;
        return close_fn() != 0;
    }
    return 0;
}

static inline int r4sys_supports_vm(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, vm_query) + sizeof(uintptr_t)) return 0;
    return sys->table->vm_reserve != 0 &&
        sys->table->vm_commit != 0 &&
        sys->table->vm_decommit != 0 &&
        sys->table->vm_release != 0 &&
        sys->table->vm_query != 0;
}

static inline int r4sys_supports_threads(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, thread_status) + sizeof(uintptr_t)) return 0;
    return sys->table->thread_create != 0 &&
        sys->table->thread_exit != 0 &&
        sys->table->thread_join != 0 &&
        sys->table->thread_current != 0 &&
        sys->table->thread_status != 0;
}

static inline int32_t r4sys_thread_create(R4Sys *sys, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes, uint32_t *out_thread_id) {
    if (!r4sys_supports_threads(sys) || entry == 0 || out_thread_id == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadCreateFn create_fn = (R4SysThreadCreateFn)(uintptr_t)sys->table->thread_create;
    return create_fn(entry, arg, stack_reserve_bytes, 0, out_thread_id);
}

static inline void r4sys_thread_exit(R4Sys *sys, int32_t exit_code) {
    if (!r4sys_supports_threads(sys)) return;
    R4SysThreadExitFn exit_fn = (R4SysThreadExitFn)(uintptr_t)sys->table->thread_exit;
    exit_fn(exit_code);
}

static inline int32_t r4sys_thread_join(R4Sys *sys, uint32_t thread_id, uint64_t timeout_ticks, int32_t *out_exit_code) {
    if (!r4sys_supports_threads(sys) || out_exit_code == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadJoinFn join_fn = (R4SysThreadJoinFn)(uintptr_t)sys->table->thread_join;
    return join_fn(thread_id, timeout_ticks, out_exit_code);
}

static inline uint32_t r4sys_thread_current(R4Sys *sys) {
    if (!r4sys_supports_threads(sys)) return 0;
    R4SysThreadCurrentFn current_fn = (R4SysThreadCurrentFn)(uintptr_t)sys->table->thread_current;
    return current_fn();
}

static inline int32_t r4sys_thread_status(R4Sys *sys, uint32_t thread_id, R4ProgramThreadInfo *out_info) {
    if (!r4sys_supports_threads(sys) || out_info == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadStatusFn status_fn = (R4SysThreadStatusFn)(uintptr_t)sys->table->thread_status;
    return status_fn(thread_id, out_info);
}

static inline int r4sys_supports_program_inventory(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, program_inventory_threads) + sizeof(uintptr_t)) return 0;
    return sys->table->program_inventory_begin != 0 &&
        sys->table->program_inventory_programs != 0 &&
        sys->table->program_inventory_tasks != 0 &&
        sys->table->program_inventory_threads != 0;
}

static inline int32_t r4sys_program_inventory_begin(
    R4Sys *sys,
    R4ProgramInventoryCursor *cursor,
    R4ProgramInventorySummary *out_summary)
{
    if (cursor == 0 || out_summary == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4sys_supports_program_inventory(sys)) return R4OS_ERR_NO_FN;
    R4SysProgramInventoryBeginFn inventory_fn =
        (R4SysProgramInventoryBeginFn)(uintptr_t)sys->table->program_inventory_begin;
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
        (R4SysProgramInventoryProgramsFn)(uintptr_t)sys->table->program_inventory_programs;
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
        (R4SysProgramInventoryTasksFn)(uintptr_t)sys->table->program_inventory_tasks;
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
        (R4SysProgramInventoryThreadsFn)(uintptr_t)sys->table->program_inventory_threads;
    return inventory_fn(cursor, out, capacity, out_page);
}

static inline int r4sys_supports_registry_snapshot(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, registry_snapshot_page) + sizeof(uintptr_t)) return 0;
    return sys->table->registry_snapshot_begin != 0 && sys->table->registry_snapshot_page != 0;
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
        (R4SysRegistrySnapshotBeginFn)(uintptr_t)sys->table->registry_snapshot_begin;
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
        (R4SysRegistrySnapshotPageFn)(uintptr_t)sys->table->registry_snapshot_page;
    return page_fn(cursor, entries, entry_capacity, data, data_capacity, out_page);
}

static inline int r4sys_supports_registry_batch(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, registry_batch_mutate) + sizeof(uintptr_t)) return 0;
    return sys->table->registry_batch_mutate != 0;
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
        (R4SysRegistryBatchMutateFn)(uintptr_t)sys->table->registry_batch_mutate;
    return batch_fn(operations, operation_count, blob, blob_len, out_result);
}

static inline int r4sys_supports_thread_handles(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, thread_handle_status) + sizeof(uintptr_t)) return 0;
    return sys->table->thread_create_handle != 0 &&
        sys->table->thread_handle_join != 0 &&
        sys->table->thread_handle_status != 0;
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
    if (!r4sys_supports_thread_handles(sys)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadCreateHandleFn create_fn =
        (R4SysThreadCreateHandleFn)(uintptr_t)sys->table->thread_create_handle;
    return create_fn(entry, (uint64_t)arg, stack_reserve_bytes, flags, out_handle);
}

static inline int32_t r4sys_thread_handle_join(
    R4Sys *sys,
    const R4ProgramJoinHandle *handle,
    uint64_t timeout_ticks,
    int32_t *out_exit_code)
{
    if (handle == 0 || out_exit_code == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!r4sys_supports_thread_handles(sys)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadHandleJoinFn join_fn =
        (R4SysThreadHandleJoinFn)(uintptr_t)sys->table->thread_handle_join;
    return join_fn(handle, timeout_ticks, out_exit_code);
}

static inline int32_t r4sys_thread_handle_status(
    R4Sys *sys,
    const R4ProgramJoinHandle *handle,
    R4ProgramThreadInfo *out_info)
{
    if (handle == 0 || out_info == 0) return R4OS_THREAD_ERROR_INVALID;
    if (!r4sys_supports_thread_handles(sys)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4SysThreadHandleStatusFn status_fn =
        (R4SysThreadHandleStatusFn)(uintptr_t)sys->table->thread_handle_status;
    return status_fn(handle, out_info);
}

static inline int r4sys_supports_file_replace_atomic(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, file_replace_atomic) + sizeof(uintptr_t)) return 0;
    return sys->table->file_replace_atomic != 0;
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
        (R4SysFileReplaceAtomicFn)(uintptr_t)sys->table->file_replace_atomic;
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
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, file_delete_if_match) + sizeof(uintptr_t)) return 0;
    return sys->table->file_delete_if_match != 0;
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
        (R4SysFileDeleteIfMatchFn)(uintptr_t)sys->table->file_delete_if_match;
    return delete_fn((const uint8_t *)path, expected_size, expected_checksum);
}

static inline int r4sys_supports_file_update_atomic_checked(R4Sys *sys) {
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, file_update_atomic_checked) + sizeof(uintptr_t)) return 0;
    return sys->table->file_update_atomic_checked != 0;
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
        (R4SysFileUpdateAtomicCheckedFn)(uintptr_t)sys->table->file_update_atomic_checked;
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
    if (sys == 0 || sys->table == 0) return 0;
    if (sys->table->size < offsetof(R4XStartR4Sys, io_close) + sizeof(uintptr_t)) return 0;
    return sys->table->io_file_read != 0 &&
        sys->table->io_file_write != 0 &&
        sys->table->io_file_stream_write != 0 &&
        sys->table->io_service_call != 0 &&
        sys->table->io_status != 0 &&
        sys->table->io_wait != 0 &&
        sys->table->io_close != 0;
}

static inline int32_t r4sys_io_file_read(R4Sys *sys, const char *path, uint8_t *out, uint64_t capacity, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileReadFn io_fn = (R4SysIoFileReadFn)(uintptr_t)sys->table->io_file_read;
    return io_fn((const uint8_t *)path, out, capacity, flags, out_request_id);
}

static inline int32_t r4sys_io_file_read_at(R4Sys *sys, const char *path, uint64_t offset, uint8_t *out, uint64_t capacity, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || sys->table->io_file_read_at == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileReadAtFn io_fn = (R4SysIoFileReadAtFn)(uintptr_t)sys->table->io_file_read_at;
    return io_fn((const uint8_t *)path, offset, out, capacity, flags, out_request_id);
}

static inline int32_t r4sys_io_file_write(R4Sys *sys, const char *path, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileWriteFn io_fn = (R4SysIoFileWriteFn)(uintptr_t)sys->table->io_file_write;
    return io_fn((const uint8_t *)path, data, len, flags, out_request_id);
}

static inline int32_t r4sys_io_file_append(R4Sys *sys, const char *path, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || sys->table->io_file_append == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileAppendFn io_fn = (R4SysIoFileAppendFn)(uintptr_t)sys->table->io_file_append;
    return io_fn((const uint8_t *)path, data, len, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_begin(R4Sys *sys, const char *path, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || sys->table->io_file_stream_begin == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamBeginFn io_fn = (R4SysIoFileStreamBeginFn)(uintptr_t)sys->table->io_file_stream_begin;
    return io_fn((const uint8_t *)path, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_write(R4Sys *sys, const char *path, uint64_t offset, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamWriteFn io_fn = (R4SysIoFileStreamWriteFn)(uintptr_t)sys->table->io_file_stream_write;
    return io_fn((const uint8_t *)path, offset, data, len, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_finish(R4Sys *sys, const char *path, uint64_t expected_size, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || sys->table->io_file_stream_finish == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamFinishFn io_fn = (R4SysIoFileStreamFinishFn)(uintptr_t)sys->table->io_file_stream_finish;
    return io_fn((const uint8_t *)path, expected_size, flags, out_request_id);
}

static inline int32_t r4sys_io_file_stream_abort(R4Sys *sys, const char *path, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || sys->table->io_file_stream_abort == 0 || path == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoFileStreamAbortFn io_fn = (R4SysIoFileStreamAbortFn)(uintptr_t)sys->table->io_file_stream_abort;
    return io_fn((const uint8_t *)path, out_request_id);
}

static inline int32_t r4sys_io_service_call(R4Sys *sys, uint32_t handle, uint16_t op, const uint8_t *request, uint32_t request_len, void *response_header, uint8_t *response, uint32_t response_capacity, uint64_t timeout_ticks, uint32_t flags, uint32_t *out_request_id) {
    if (!r4sys_supports_async_io(sys) || response_header == 0 || response == 0 || out_request_id == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoServiceCallFn io_fn = (R4SysIoServiceCallFn)(uintptr_t)sys->table->io_service_call;
    return io_fn(handle, op, request, request_len, response_header, response, response_capacity, timeout_ticks, flags, out_request_id);
}

static inline int32_t r4sys_io_status(R4Sys *sys, uint32_t request_id, R4ProgramIoInfo *out_info) {
    if (!r4sys_supports_async_io(sys) || out_info == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoStatusFn io_fn = (R4SysIoStatusFn)(uintptr_t)sys->table->io_status;
    return io_fn(request_id, out_info);
}

static inline int32_t r4sys_io_wait(R4Sys *sys, uint32_t request_id, uint64_t timeout_ticks, R4ProgramIoInfo *out_info) {
    if (!r4sys_supports_async_io(sys) || out_info == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoWaitFn io_fn = (R4SysIoWaitFn)(uintptr_t)sys->table->io_wait;
    return io_fn(request_id, timeout_ticks, out_info);
}

static inline int32_t r4sys_io_close(R4Sys *sys, uint32_t request_id) {
    if (!r4sys_supports_async_io(sys)) return R4OS_IO_ERROR_UNSUPPORTED;
    R4SysIoCloseFn io_fn = (R4SysIoCloseFn)(uintptr_t)sys->table->io_close;
    return io_fn(request_id);
}

static inline int32_t r4sys_vm_reserve(R4Sys *sys, uint64_t size, uint64_t alignment, uint64_t flags, R4ProgramVmRegionInfo *out_info) {
    if (!r4sys_supports_vm(sys) || out_info == 0) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmReserveFn vm_fn = (R4SysVmReserveFn)(uintptr_t)sys->table->vm_reserve;
    return vm_fn(size, alignment, flags, out_info);
}

static inline int32_t r4sys_vm_commit(R4Sys *sys, uint32_t region_id, uint64_t offset, uint64_t len) {
    if (!r4sys_supports_vm(sys)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmCommitFn vm_fn = (R4SysVmCommitFn)(uintptr_t)sys->table->vm_commit;
    return vm_fn(region_id, offset, len, 0);
}

static inline int32_t r4sys_vm_commit_flags(R4Sys *sys, uint32_t region_id, uint64_t offset, uint64_t len, uint64_t flags) {
    if (!r4sys_supports_vm(sys)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmCommitFn vm_fn = (R4SysVmCommitFn)(uintptr_t)sys->table->vm_commit;
    return vm_fn(region_id, offset, len, flags);
}

static inline int32_t r4sys_vm_decommit(R4Sys *sys, uint32_t region_id, uint64_t offset, uint64_t len) {
    if (!r4sys_supports_vm(sys)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmDecommitFn vm_fn = (R4SysVmDecommitFn)(uintptr_t)sys->table->vm_decommit;
    return vm_fn(region_id, offset, len);
}

static inline int32_t r4sys_vm_release(R4Sys *sys, uint32_t region_id) {
    if (!r4sys_supports_vm(sys)) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmReleaseFn vm_fn = (R4SysVmReleaseFn)(uintptr_t)sys->table->vm_release;
    return vm_fn(region_id);
}

static inline int32_t r4sys_vm_query(R4Sys *sys, uint32_t region_id, R4ProgramVmRegionInfo *out_info) {
    if (!r4sys_supports_vm(sys) || out_info == 0) return R4OS_VM_ERROR_NO_INSTANCE;
    R4SysVmQueryFn vm_fn = (R4SysVmQueryFn)(uintptr_t)sys->table->vm_query;
    return vm_fn(region_id, out_info);
}

static inline uint64_t r4sys_align_up_u64(uint64_t value, uint64_t alignment) {
    uint64_t mask = alignment - 1u;
    return (value + mask) & ~mask;
}

static inline void *r4sys_vm_alloc(R4Sys *sys, uint64_t size, uint64_t alignment) {
    if (size == 0 || !r4sys_supports_vm(sys)) return 0;
    if (alignment < sizeof(uintptr_t)) alignment = sizeof(uintptr_t);
    if ((alignment & (alignment - 1u)) != 0) return 0;
    uint64_t reserve_alignment = alignment > 4096u ? alignment : 4096u;
    uint64_t need = sizeof(R4SysVmAllocation) + sizeof(uintptr_t) + alignment - 1u + size;
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
    if (ptr == 0 || !r4sys_supports_vm(sys)) return R4OS_ERROR_INVALID;
    uintptr_t user = (uintptr_t)ptr;
    uintptr_t *backref = (uintptr_t *)(user - sizeof(uintptr_t));
    R4SysVmAllocation *header = (R4SysVmAllocation *)(*backref);
    if (header == 0 || header->magic != 0x32434D52u || header->user_addr != user) return R4OS_ERROR_INVALID;
    uint32_t region_id = header->region_id;
    header->magic = 0;
    return r4sys_vm_release(sys, region_id);
}

int32_t r4_main(const R4XStartContext *ctx, R4Sys *sys);

#ifdef __cplusplus
}
#endif

#endif
