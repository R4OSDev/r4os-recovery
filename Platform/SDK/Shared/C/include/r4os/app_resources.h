#ifndef R4OS_APP_RESOURCES_H
#define R4OS_APP_RESOURCES_H

#include "app_contract.h"

typedef struct R4Resources { R4App *app; } R4Resources;

typedef enum R4ResourceWaitKind {
    R4_RESOURCE_WAIT_EXITED = 0,
    R4_RESOURCE_WAIT_WOULD_BLOCK = 1,
    R4_RESOURCE_WAIT_TIMED_OUT = 2,
    R4_RESOURCE_WAIT_FAILED = 3
} R4ResourceWaitKind;

typedef struct R4ResourceWait {
    R4ResourceWaitKind kind;
    int32_t value;
} R4ResourceWait;

typedef R4ProgramProcessCompletion R4OS_ProcessCompletion;

typedef struct R4Process {
    R4App *app;
    uint32_t raw;
    uint8_t owned;
    uint8_t reserved[3];
    uint64_t generation;
    uint32_t handle_reserved;
    uint32_t extension_reserved;
} R4Process;

typedef R4Process R4OS_ProcessHandle;

typedef struct R4JoinHandle {
    R4App *app;
    R4ProgramJoinHandle handle;
    uint8_t owned;
    uint8_t reserved[7];
} R4JoinHandle;

typedef struct R4VmRegion {
    R4App *app;
    uint32_t raw;
    uint8_t owned;
    uint8_t reserved[3];
    R4ProgramVmRegionInfo last_info;
} R4VmRegion;

typedef enum R4IoBufferKind {
    R4_IO_BUFFER_NONE = 0,
    R4_IO_BUFFER_MUTABLE = 1,
    R4_IO_BUFFER_READ_ONLY = 2
} R4IoBufferKind;

typedef struct R4IoRequest {
    R4App *app;
    uint32_t raw;
    uint8_t owned;
    uint8_t buffer_kind;
    uint8_t reserved[2];
    void *mutable_buffer;
    const void *read_only_buffer;
    uint64_t buffer_length;
    R4ProgramIoInfo last_info;
} R4IoRequest;

static inline R4Resources r4_app_resources(R4App *app) { R4Resources result = {app}; return result; }
static inline int r4os_process_valid(const R4OS_ProcessHandle *process) {
    return process != 0 && process->app != 0 && process->raw != 0u &&
        process->generation != 0u && process->handle_reserved == 0u &&
        process->extension_reserved == 0u;
}
static inline int r4_process_valid(const R4Process *process) { return r4os_process_valid(process); }
static inline R4ProgramProcessHandle r4os_process_abi_handle(const R4OS_ProcessHandle *process) {
    R4ProgramProcessHandle handle = {0};
    if (process != 0) {
        handle.instance_id = process->raw;
        handle.reserved = process->handle_reserved;
        handle.generation = process->generation;
    }
    return handle;
}
static inline void r4os_process_store_abi_handle(R4OS_ProcessHandle *process, const R4ProgramProcessHandle *handle) {
    process->raw = handle->instance_id;
    process->generation = handle->generation;
    process->handle_reserved = handle->reserved;
    process->extension_reserved = 0u;
}
static inline void r4os_process_invalidate(R4OS_ProcessHandle *process) {
    process->raw = 0u;
    process->generation = 0u;
    process->handle_reserved = 0u;
    process->extension_reserved = 0u;
}
static inline int r4_join_handle_valid(const R4JoinHandle *handle) {
    return handle != 0 && handle->app != 0 &&
        handle->handle.thread_id != 0u && handle->handle.instance_id != 0u &&
        handle->handle.thread_generation != 0u && handle->handle.instance_generation != 0u &&
        handle->handle.reserved == 0u;
}
static inline void r4_join_handle_invalidate(R4JoinHandle *handle) {
    if (handle != 0) handle->handle = (R4ProgramJoinHandle){0};
}
static inline int r4_vm_region_valid(const R4VmRegion *region) { return region != 0 && region->app != 0 && region->raw != 0u; }
static inline int r4_io_request_valid(const R4IoRequest *request) { return request != 0 && request->app != 0 && request->raw != 0u; }

static inline uint32_t r4_resource_monotonic_hz(R4App *app) {
    if (app == 0 || app->system.table == 0 || app->system.table->time_state == 0) return 0u;
    R4TimeState state = {0};
    ((R4SysTimeStateFn)(uintptr_t)app->system.table->time_state)(&state);
    return state.monotonic_hz;
}

static inline void r4_resource_yield(R4App *app) {
    if (app == 0) return;
    if (app->system.table != 0 && app->system.table->task_yield != 0) {
        ((R4SysTaskYieldFn)(uintptr_t)app->system.table->task_yield)();
        return;
    }
    if (app->context != 0 && app->context->yield != 0) {
        ((R4XStartYieldFn)(uintptr_t)app->context->yield)(app->context);
    }
}

static inline int32_t r4_resources_spawn(R4Resources *resources, R4PathZ path, const char *args, uint32_t policy, R4Process *out) {
    if (out != 0) *out = (R4Process){0};
    if (resources == 0 || resources->app == 0 || out == 0 || path.ptr == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (resources->app->system.table == 0 || resources->app->system.table->program_spawn_handle == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = {0};
    int32_t status = ((R4SysProgramSpawnHandleFn)(uintptr_t)resources->app->system.table->program_spawn_handle)(
        path.ptr, (const uint8_t *)(args != 0 ? args : ""), policy, &handle);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    out->app = resources->app; out->owned = 1u; r4os_process_store_abi_handle(out, &handle);
    return status;
}

static inline int32_t r4os_spawn_with_console_host(R4Resources *resources, R4PathZ path, const char *args, uint32_t policy, uint32_t host, R4OS_ProcessHandle *out) {
    if (out != 0) *out = (R4OS_ProcessHandle){0};
    if (resources == 0 || resources->app == 0 || out == 0 || path.ptr == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (resources->app->desktop.table == 0 || resources->app->desktop.table->program_spawn_with_console_host_handle == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = {0};
    int32_t status = ((R4DeskProgramSpawnWithConsoleHostHandleFn)(uintptr_t)resources->app->desktop.table->program_spawn_with_console_host_handle)(
        path.ptr, (const uint8_t *)(args != 0 ? args : ""), policy, host, &handle);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    out->app = resources->app; out->owned = 1u; r4os_process_store_abi_handle(out, &handle);
    return status;
}

static inline int32_t r4os_process_status(R4OS_ProcessHandle *process, R4ProgramInstanceInfo *out) {
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (process->app->system.table == 0 || process->app->system.table->program_handle_status == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleStatusFn)(uintptr_t)process->app->system.table->program_handle_status)(&handle, out);
}
static inline int32_t r4_process_status(R4Process *process, R4ProgramInstanceInfo *out) { return r4os_process_status(process, out); }

static inline int32_t r4_resources_open_process(R4Resources *resources, uint32_t instance_id, R4Process *out) {
    if (out != 0) *out = (R4Process){0};
    if (resources == 0 || resources->app == 0 || out == 0 || instance_id == 0u) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (resources->app->system.table == 0 || resources->app->system.table->program_open_handle == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = {0};
    int32_t status = ((R4SysProgramOpenHandleFn)(uintptr_t)resources->app->system.table->program_open_handle)(instance_id, &handle);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    out->app = resources->app; out->owned = 0u; r4os_process_store_abi_handle(out, &handle);
    return status;
}

static inline int32_t r4os_process_request_close(R4OS_ProcessHandle *process) {
    if (process == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (process->app->system.table == 0 || process->app->system.table->program_handle_request_close == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleRequestCloseFn)(uintptr_t)process->app->system.table->program_handle_request_close)(&handle);
}
static inline int32_t r4_process_request_close(R4Process *process) { return r4os_process_request_close(process); }

static inline int32_t r4os_process_kill(R4OS_ProcessHandle *process) {
    if (process == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (process->app->system.table == 0 || process->app->system.table->program_handle_kill == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleKillFn)(uintptr_t)process->app->system.table->program_handle_kill)(&handle);
}
static inline int32_t r4_process_kill(R4Process *process) { return r4os_process_kill(process); }

static inline int32_t r4os_process_wait_ready(R4OS_ProcessHandle *process, R4Timeout timeout, R4OS_ProcessCompletion *out) {
    if (out != 0) *out = (R4OS_ProcessCompletion){0};
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (process->app->system.table == 0 || process->app->system.table->program_handle_wait == 0) return R4OS_ERR_NO_FN;
    uint64_t timeout_ticks = 0u;
    if (r4_timeout_to_ticks(timeout, r4_resource_monotonic_hz(process->app), &timeout_ticks) != R4OS_OK) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleWaitFn)(uintptr_t)process->app->system.table->program_handle_wait)(&handle, timeout_ticks, out);
}

static inline int32_t r4os_process_completion_read(R4OS_ProcessHandle *process, uint32_t offset, uint8_t *out, uint32_t capacity, uint32_t *out_read) {
    if (out_read != 0) *out_read = 0u;
    if (process == 0 || out == 0 || out_read == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (process->app->system.table == 0 ||
        process->app->system.table->program_completion_read == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramCompletionReadFn)(uintptr_t)process->app->system.table->program_completion_read)(
        &handle, offset, out, capacity, out_read);
}

static inline int32_t r4os_process_reap(R4OS_ProcessHandle *process, R4OS_ProcessCompletion *out) {
    if (out != 0) *out = (R4OS_ProcessCompletion){0};
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!process->owned) return R4OS_ERR_NOT_OWNED;
    if (process->app->system.table == 0 || process->app->system.table->program_handle_reap == 0) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    int32_t status = ((R4SysProgramHandleReapFn)(uintptr_t)process->app->system.table->program_handle_reap)(&handle, out);
    if (status == R4OS_PROGRAM_HANDLE_OK) r4os_process_invalidate(process);
    return status;
}

static inline int32_t r4os_process_wait(R4OS_ProcessHandle *process, R4Timeout timeout, R4OS_ProcessCompletion *out) {
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!process->owned) return R4OS_ERR_NOT_OWNED;
    R4OS_ProcessCompletion observed = {0};
    int32_t status = r4os_process_wait_ready(process, timeout, &observed);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    status = r4os_process_reap(process, out);
    return status;
}

static inline R4ResourceWait r4_process_reap(R4Process *process) {
    R4ResourceWait result = {R4_RESOURCE_WAIT_FAILED, R4OS_ERR_CLOSED};
    R4OS_ProcessCompletion completion = {0};
    int32_t status = r4os_process_reap(process, &completion);
    if (status == R4OS_PROGRAM_HANDLE_ERROR_WOULD_BLOCK) { result.kind = R4_RESOURCE_WAIT_WOULD_BLOCK; result.value = 0; return result; }
    if (status != R4OS_PROGRAM_HANDLE_OK) { result.value = status; return result; }
    result.kind = R4_RESOURCE_WAIT_EXITED; result.value = completion.exit_code; return result;
}

static inline R4ResourceWait r4_process_wait(R4Process *process, R4Timeout timeout) {
    R4ResourceWait result = {R4_RESOURCE_WAIT_FAILED, R4OS_ERR_CLOSED};
    R4OS_ProcessCompletion completion = {0};
    int32_t status = r4os_process_wait(process, timeout, &completion);
    if (status == R4OS_PROGRAM_HANDLE_ERROR_TIMEOUT) { result.kind = R4_RESOURCE_WAIT_TIMED_OUT; result.value = 0; return result; }
    if (status == R4OS_PROGRAM_HANDLE_ERROR_WOULD_BLOCK) { result.kind = R4_RESOURCE_WAIT_WOULD_BLOCK; result.value = 0; return result; }
    if (status != R4OS_PROGRAM_HANDLE_OK) { result.value = status; return result; }
    result.kind = R4_RESOURCE_WAIT_EXITED; result.value = completion.exit_code; return result;
}

static inline int32_t r4_resources_create_thread(R4Resources *resources, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes, R4JoinHandle *out) {
    if (out != 0) *out = (R4JoinHandle){0};
    if (resources == 0 || resources->app == 0 || out == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4ProgramJoinHandle handle = {0};
    int32_t raw = r4sys_thread_create_handle(&resources->app->system, entry, arg, stack_reserve_bytes, 0u, &handle);
    if (raw != R4OS_THREAD_OK) return raw;
    out->app = resources->app; out->handle = handle; out->owned = 1u; return raw;
}

static inline int32_t r4_join_status(R4JoinHandle *handle, R4ProgramThreadInfo *out) {
    if (!r4_join_handle_valid(handle)) return R4OS_ERR_CLOSED;
    return r4sys_thread_handle_status(&handle->app->system, &handle->handle, out);
}

static inline R4ResourceWait r4_join_wait(R4JoinHandle *handle, R4Timeout timeout) {
    R4ResourceWait result = {R4_RESOURCE_WAIT_FAILED, R4OS_ERR_CLOSED};
    if (!r4_join_handle_valid(handle)) return result;
    if (!handle->owned) { result.value = R4OS_ERR_NOT_OWNED; return result; }
    uint64_t ticks = 0u; if (r4_timeout_to_ticks(timeout, r4_resource_monotonic_hz(handle->app), &ticks) != R4OS_OK) { result.value = R4OS_THREAD_ERROR_INVALID; return result; }
    int32_t exit_code = 0; int32_t raw = r4sys_thread_handle_join(&handle->app->system, &handle->handle, ticks, &exit_code);
    if (raw == R4OS_THREAD_ERROR_TIMEOUT) { result.kind = R4_RESOURCE_WAIT_TIMED_OUT; result.value = 0; return result; }
    if (raw == R4OS_THREAD_ERROR_NOT_FOUND) { r4_join_handle_invalidate(handle); result.value = R4OS_ERR_CLOSED; return result; }
    if (raw != R4OS_THREAD_OK) { result.value = raw; return result; }
    r4_join_handle_invalidate(handle); result.kind = R4_RESOURCE_WAIT_EXITED; result.value = exit_code; return result;
}

static inline int32_t r4_resources_reserve_vm(R4Resources *resources, uint64_t size, uint64_t alignment, uint64_t flags, R4VmRegion *out) {
    if (out != 0) *out = (R4VmRegion){0};
    if (resources == 0 || resources->app == 0 || out == 0) return R4OS_VM_ERROR_NO_INSTANCE;
    R4ProgramVmRegionInfo info = {0}; int32_t raw = r4sys_vm_reserve(&resources->app->system, size, alignment, flags, &info);
    if (raw != R4OS_VM_OK) return raw;
    out->app = resources->app; out->raw = info.id; out->owned = 1u; out->last_info = info; return raw;
}

static inline int32_t r4_vm_region_query(R4VmRegion *region, R4ProgramVmRegionInfo *out) {
    if (!r4_vm_region_valid(region)) return R4OS_ERR_CLOSED;
    int32_t raw = r4sys_vm_query(&region->app->system, region->raw, out);
    if (raw == R4OS_VM_OK && out != 0) region->last_info = *out;
    return raw;
}

static inline int32_t r4_vm_region_commit(R4VmRegion *region, uint64_t offset, uint64_t len) { return r4_vm_region_valid(region) ? r4sys_vm_commit(&region->app->system, region->raw, offset, len) : R4OS_ERR_CLOSED; }
static inline int32_t r4_vm_region_decommit(R4VmRegion *region, uint64_t offset, uint64_t len) { return r4_vm_region_valid(region) ? r4sys_vm_decommit(&region->app->system, region->raw, offset, len) : R4OS_ERR_CLOSED; }

static inline int32_t r4_vm_region_release(R4VmRegion *region) {
    if (!r4_vm_region_valid(region)) return R4OS_ERR_CLOSED;
    if (!region->owned) return R4OS_ERR_NOT_OWNED;
    int32_t raw = r4sys_vm_release(&region->app->system, region->raw);
    if (raw == R4OS_VM_OK || raw == R4OS_VM_ERROR_INVALID_RANGE) { region->raw = 0u; region->last_info = (R4ProgramVmRegionInfo){0}; return raw == R4OS_VM_OK ? raw : R4OS_ERR_CLOSED; }
    return raw;
}

static inline void r4_io_bind(R4IoRequest *request, R4App *app, uint32_t id, R4IoBufferKind kind, void *mutable_buffer, const void *read_only_buffer, uint64_t length) {
    *request = (R4IoRequest){0}; request->app = app; request->raw = id; request->owned = 1u; request->buffer_kind = (uint8_t)kind; request->mutable_buffer = mutable_buffer; request->read_only_buffer = read_only_buffer; request->buffer_length = length;
}

static inline int32_t r4_resources_async_read(R4Resources *resources, R4PathZ path, uint8_t *out_buffer, uint64_t capacity, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_read(&resources->app->system, (const char *)path.ptr, out_buffer, capacity, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_MUTABLE, out_buffer, 0, capacity); return raw;
}

static inline int32_t r4_resources_async_read_at(R4Resources *resources, R4PathZ path, uint64_t offset, uint8_t *out_buffer, uint64_t capacity, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_read_at(&resources->app->system, (const char *)path.ptr, offset, out_buffer, capacity, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_MUTABLE, out_buffer, 0, capacity); return raw;
}

static inline int32_t r4_resources_async_write(R4Resources *resources, R4PathZ path, const uint8_t *data, uint64_t len, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_write(&resources->app->system, (const char *)path.ptr, data, len, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_READ_ONLY, 0, data, len); return raw;
}

static inline int32_t r4_resources_async_append(R4Resources *resources, R4PathZ path, const uint8_t *data, uint64_t len, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_append(&resources->app->system, (const char *)path.ptr, data, len, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_READ_ONLY, 0, data, len); return raw;
}

static inline int32_t r4_resources_async_stream_begin(R4Resources *resources, R4PathZ path, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_stream_begin(&resources->app->system, (const char *)path.ptr, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_NONE, 0, 0, 0u); return raw;
}

static inline int32_t r4_resources_async_stream_write(R4Resources *resources, R4PathZ path, uint64_t offset, const uint8_t *data, uint64_t len, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_stream_write(&resources->app->system, (const char *)path.ptr, offset, data, len, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_READ_ONLY, 0, data, len); return raw;
}

static inline int32_t r4_resources_async_stream_finish(R4Resources *resources, R4PathZ path, uint64_t expected_size, uint32_t flags, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_stream_finish(&resources->app->system, (const char *)path.ptr, expected_size, flags, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_NONE, 0, 0, 0u); return raw;
}

static inline int32_t r4_resources_async_stream_abort(R4Resources *resources, R4PathZ path, R4IoRequest *out) {
    if (out != 0) *out = (R4IoRequest){0}; if (resources == 0 || resources->app == 0 || out == 0) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0u; int32_t raw = r4sys_io_file_stream_abort(&resources->app->system, (const char *)path.ptr, &id); if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_NONE, 0, 0, 0u); return raw;
}

static inline int r4_io_request_buffers_held(const R4IoRequest *request) { return r4_io_request_valid(request) && request->buffer_kind != R4_IO_BUFFER_NONE; }
static inline int32_t r4_io_request_release_buffers(R4IoRequest *request) { if (r4_io_request_buffers_held(request)) return R4OS_ERR_BUFFER_IN_USE; if (request != 0) { request->buffer_kind = R4_IO_BUFFER_NONE; request->mutable_buffer = 0; request->read_only_buffer = 0; request->buffer_length = 0u; } return R4OS_IO_OK; }

static inline int32_t r4_io_request_status(R4IoRequest *request, R4ProgramIoInfo *out) {
    if (!r4_io_request_valid(request)) return R4OS_ERR_CLOSED; int32_t raw = r4sys_io_status(&request->app->system, request->raw, out); if (raw == R4OS_IO_OK && out != 0) request->last_info = *out; return raw;
}

static inline R4ResourceWait r4_io_request_wait(R4IoRequest *request, R4Timeout timeout) {
    R4ResourceWait result = {R4_RESOURCE_WAIT_FAILED, R4OS_ERR_CLOSED}; if (!r4_io_request_valid(request)) return result;
    uint64_t ticks = 0u; if (r4_timeout_to_ticks(timeout, r4_resource_monotonic_hz(request->app), &ticks) != R4OS_OK) { result.value = R4OS_IO_ERROR_INVALID; return result; }
    R4ProgramIoInfo info = {0}; int32_t raw = r4sys_io_wait(&request->app->system, request->raw, ticks, &info);
    if (raw == R4OS_IO_ERROR_TIMEOUT) { result.kind = R4_RESOURCE_WAIT_TIMED_OUT; result.value = 0; return result; }
    if (raw != R4OS_IO_OK) { result.value = raw; return result; }
    request->last_info = info; result.kind = R4_RESOURCE_WAIT_EXITED; result.value = info.result; return result;
}

static inline int32_t r4_io_request_close(R4IoRequest *request) {
    if (!r4_io_request_valid(request)) return R4OS_ERR_CLOSED; if (!request->owned) return R4OS_ERR_NOT_OWNED;
    int32_t raw = r4sys_io_close(&request->app->system, request->raw);
    if (raw == R4OS_IO_OK || raw == R4OS_IO_ERROR_NOT_FOUND) { request->raw = 0u; request->buffer_kind = R4_IO_BUFFER_NONE; request->mutable_buffer = 0; request->read_only_buffer = 0; request->buffer_length = 0u; return raw == R4OS_IO_OK ? raw : R4OS_ERR_CLOSED; }
    return raw;
}

#endif
