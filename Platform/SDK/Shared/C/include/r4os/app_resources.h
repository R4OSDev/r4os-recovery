#ifndef R4OS_APP_RESOURCES_H
#define R4OS_APP_RESOURCES_H

#include "app_contract.h"
#include "poll_budget.h"

typedef struct R4Resources { R4App *app; } R4Resources;

/* A current context still admits each optional slot by its real readable end.
 * No dereference of an absent tail and no emulation of an older OS table. */
static inline int r4_resource_sys_has(const R4App *app, size_t offset) {
    return app && app->system.table && offset <= app->system.table->size &&
        sizeof(uintptr_t) <= app->system.table->size - offset;
}
static inline int r4_resource_desk_has(const R4App *app, size_t offset) {
    return app && app->desktop.table && offset <= app->desktop.table->size &&
        sizeof(uintptr_t) <= app->desktop.table->size - offset;
}
#define R4_RESOURCE_SYS_HAS(app, field) ((app) && R4SYS_HAS(&(app)->system, field))
static inline uintptr_t r4_resource_desk_callback(const R4App *app, size_t offset1, uint32_t offset2) {
    if (!app) return 0;
    if (app->system.generation2) {
        uint64_t address;
        return R4OS2ContextFunction(app->system.generation2, 2, offset2, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!r4_resource_desk_has(app, offset1)) return 0;
    return *(const uintptr_t *)((const uint8_t *)app->desktop.table + offset1);
}
#define R4_RESOURCE_DESK_SLOT(app, field) r4_resource_desk_callback((app), offsetof(R4XStartR4Desk, field), offsetof(R4XStartR4Desk2, field))
#define R4_RESOURCE_DESK_HAS(app, field) (R4_RESOURCE_DESK_SLOT((app), field) != 0)


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
    if (!R4_RESOURCE_SYS_HAS(app, time_state)) return 0u;
    R4TimeState state = {0};
    ((R4SysTimeStateFn)(uintptr_t)R4SYS_SLOT(&app->system, time_state))(&state);
    return state.monotonic_hz;
}

static inline int32_t r4_resource_wait_ticks(R4App *app, R4Timeout timeout, uint64_t *out) {
    if (!out || !app) return R4_BUDGET_INVALID;
    if (!app->system.generation2) return r4_timeout_to_ticks(timeout, r4_resource_monotonic_hz(app), out);
    uint32_t hz = 0;
    if (timeout.kind == R4OS_TIMEOUT_KIND_FINITE && timeout.nanoseconds != 0) {
        if (!R4SYS_HAS(&app->system, monotonic_clock)) return R4_BUDGET_CLOCK_UNAVAILABLE;
        R4MonotonicClockInfo info = {0};
        const int32_t rc = ((R4SysMonotonicClockFn)(uintptr_t)R4SYS_SLOT(&app->system, monotonic_clock))(&info);
        if (rc <= 0) return R4_BUDGET_CLOCK_UNAVAILABLE;
        R4SdkClockSample sample;
        const int32_t checked = R4SdkClockSampleRead(&info, &sample);
        if (checked != 0) return checked;
        hz = sample.identity.tick_hz;
    }
    R4SdkBudgetValue budget;
    const int32_t rc = R4SdkTimeoutTicksChecked(timeout, hz, &budget);
    return rc != 0 ? rc : R4SdkBudgetToWaitTicks(&budget, out);
}

static inline void r4_resource_yield(R4App *app) {
    if (app == 0) return;
    if (R4_RESOURCE_SYS_HAS(app, task_yield)) {
        ((R4SysTaskYieldFn)(uintptr_t)R4SYS_SLOT(&app->system, task_yield))();
        return;
    }
    if (app->system.generation2) { (void)R4OS2ContextYield(app->system.generation2); return; }
    if (app->context != 0 && app->context->yield != 0) {
        ((R4XStartYieldFn)(uintptr_t)app->context->yield)(app->context);
    }
}

static inline int32_t r4_resources_spawn(R4Resources *resources, R4PathZ path, const char *args, uint32_t policy, R4Process *out) {
    if (out != 0) *out = (R4Process){0};
    if (resources == 0 || resources->app == 0 || out == 0 || path.ptr == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(resources->app, program_spawn_handle)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = {0};
    int32_t status = ((R4SysProgramSpawnHandleFn)(uintptr_t)R4SYS_SLOT(&resources->app->system, program_spawn_handle))(
        path.ptr, (const uint8_t *)(args != 0 ? args : ""), policy, &handle);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    out->app = resources->app; out->owned = 1u; r4os_process_store_abi_handle(out, &handle);
    return status;
}

static inline int32_t r4os_spawn_with_console_host(R4Resources *resources, R4PathZ path, const char *args, uint32_t policy, uint32_t host, R4OS_ProcessHandle *out) {
    if (out != 0) *out = (R4OS_ProcessHandle){0};
    if (resources == 0 || resources->app == 0 || out == 0 || path.ptr == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_DESK_HAS(resources->app, program_spawn_with_console_host_handle)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = {0};
    int32_t status = ((R4DeskProgramSpawnWithConsoleHostHandleFn)(uintptr_t)R4_RESOURCE_DESK_SLOT(resources->app, program_spawn_with_console_host_handle))(
        path.ptr, (const uint8_t *)(args != 0 ? args : ""), policy, host, &handle);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    out->app = resources->app; out->owned = 1u; r4os_process_store_abi_handle(out, &handle);
    return status;
}

static inline int32_t r4os_process_status(R4OS_ProcessHandle *process, R4ProgramInstanceInfo *out) {
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!R4_RESOURCE_SYS_HAS(process->app, program_handle_status)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleStatusFn)(uintptr_t)R4SYS_SLOT(&process->app->system, program_handle_status))(&handle, out);
}
static inline int32_t r4_process_status(R4Process *process, R4ProgramInstanceInfo *out) { return r4os_process_status(process, out); }

static inline int32_t r4_resources_open_process(R4Resources *resources, uint32_t instance_id, R4Process *out) {
    if (out != 0) *out = (R4Process){0};
    if (resources == 0 || resources->app == 0 || out == 0 || instance_id == 0u) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(resources->app, program_open_handle)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = {0};
    int32_t status = ((R4SysProgramOpenHandleFn)(uintptr_t)R4SYS_SLOT(&resources->app->system, program_open_handle))(instance_id, &handle);
    if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    out->app = resources->app; out->owned = 0u; r4os_process_store_abi_handle(out, &handle);
    return status;
}

static inline int32_t r4os_process_request_close(R4OS_ProcessHandle *process) {
    if (process == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!R4_RESOURCE_SYS_HAS(process->app, program_handle_request_close)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleRequestCloseFn)(uintptr_t)R4SYS_SLOT(&process->app->system, program_handle_request_close))(&handle);
}
static inline int32_t r4_process_request_close(R4Process *process) { return r4os_process_request_close(process); }

static inline int32_t r4os_process_kill(R4OS_ProcessHandle *process) {
    if (process == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!R4_RESOURCE_SYS_HAS(process->app, program_handle_kill)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleKillFn)(uintptr_t)R4SYS_SLOT(&process->app->system, program_handle_kill))(&handle);
}
static inline int32_t r4_process_kill(R4Process *process) { return r4os_process_kill(process); }

static inline int32_t r4os_process_wait_ready(R4OS_ProcessHandle *process, R4Timeout timeout, R4OS_ProcessCompletion *out) {
    if (out != 0) *out = (R4OS_ProcessCompletion){0};
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!R4_RESOURCE_SYS_HAS(process->app, program_handle_wait)) return R4OS_ERR_NO_FN;
    uint64_t timeout_ticks = 0u;
    if (r4_resource_wait_ticks(process->app, timeout, &timeout_ticks) != R4OS_OK) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramHandleWaitFn)(uintptr_t)R4SYS_SLOT(&process->app->system, program_handle_wait))(&handle, timeout_ticks, out);
}

static inline int32_t r4os_process_completion_read(R4OS_ProcessHandle *process, uint32_t offset, uint8_t *out, uint32_t capacity, uint32_t *out_read) {
    if (out_read != 0) *out_read = 0u;
    if (process == 0 || out == 0 || out_read == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!R4_RESOURCE_SYS_HAS(process->app, program_completion_read)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    return ((R4SysProgramCompletionReadFn)(uintptr_t)R4SYS_SLOT(&process->app->system, program_completion_read))(
        &handle, offset, out, capacity, out_read);
}

/* An observation is an independent exact-generation evidence reference.
 * Default bindings are reclaimed with the creator; PORTABLE requires release.
 * Releasing an observation never reaps or terminates its target process. */
static inline int32_t r4_resources_observation_retain(R4Resources *resources, const R4ProgramProcessHandle *process,
                                                     uint32_t flags, R4ProgramObservationHandle *out) {
    if (!resources || !resources->app || !process || !out) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(resources->app, program_observation_retain)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramObservationRetainFn)(uintptr_t)R4SYS_SLOT(&resources->app->system, program_observation_retain))(process, flags, out);
}
static inline int32_t r4_resources_observation_wait(R4Resources *resources, const R4ProgramObservationHandle *observation,
                                                   R4Timeout timeout, R4ProgramProcessCompletion *out) {
    if (!resources || !resources->app || !observation || !out) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(resources->app, program_observation_wait)) return R4OS_ERR_NO_FN;
    uint64_t ticks = 0u;
    if (r4_resource_wait_ticks(resources->app, timeout, &ticks) != R4OS_OK) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    return ((R4SysProgramObservationWaitFn)(uintptr_t)R4SYS_SLOT(&resources->app->system, program_observation_wait))(observation, ticks, out);
}
static inline int32_t r4_resources_observation_read(R4Resources *resources, const R4ProgramObservationHandle *observation,
                                                   uint32_t offset, uint8_t *out, uint32_t capacity, uint32_t *out_read) {
    if (!resources || !resources->app || !observation || !out || !out_read) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(resources->app, program_observation_read)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramObservationReadFn)(uintptr_t)R4SYS_SLOT(&resources->app->system, program_observation_read))(observation, offset, out, capacity, out_read);
}
static inline int32_t r4_resources_observation_release(R4Resources *resources, const R4ProgramObservationHandle *observation) {
    if (!resources || !resources->app || !observation) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(resources->app, program_observation_release)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramObservationReleaseFn)(uintptr_t)R4SYS_SLOT(&resources->app->system, program_observation_release))(observation);
}

static inline int32_t r4os_process_reap(R4OS_ProcessHandle *process, R4OS_ProcessCompletion *out) {
    if (out != 0) *out = (R4OS_ProcessCompletion){0};
    if (process == 0 || out == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!r4os_process_valid(process)) return R4OS_ERR_CLOSED;
    if (!process->owned) return R4OS_ERR_NOT_OWNED;
    if (!R4_RESOURCE_SYS_HAS(process->app, program_handle_reap)) return R4OS_ERR_NO_FN;
    R4ProgramProcessHandle handle = r4os_process_abi_handle(process);
    int32_t status = ((R4SysProgramHandleReapFn)(uintptr_t)R4SYS_SLOT(&process->app->system, program_handle_reap))(&handle, out);
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

static inline int32_t r4_resources_create_thread_flags(R4Resources *resources, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes, uint32_t flags, R4JoinHandle *out) {
    if (out != 0) *out = (R4JoinHandle){0};
    if (resources == 0 || resources->app == 0 || out == 0) return R4OS_THREAD_ERROR_UNSUPPORTED;
    R4ProgramJoinHandle handle = {0};
    int32_t raw = r4sys_thread_create_handle(&resources->app->system, entry, arg, stack_reserve_bytes, flags, &handle);
    if (raw != R4OS_THREAD_OK) return raw;
    out->app = resources->app; out->handle = handle; out->owned = 1u; return raw;
}

static inline int32_t r4_resources_create_thread(R4Resources *resources, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes, R4JoinHandle *out) {
    return r4_resources_create_thread_flags(resources, entry, arg, stack_reserve_bytes, 0u, out);
}

static inline int32_t r4_resources_create_compute_worker(R4Resources *resources, R4ThreadEntryFn entry, uintptr_t arg, uint64_t stack_reserve_bytes, R4JoinHandle *out) {
    return r4_resources_create_thread_flags(resources, entry, arg, stack_reserve_bytes, R4OS_THREAD_CREATE_FLAG_COMPUTE_WORKER, out);
}

static inline int32_t r4_join_status(R4JoinHandle *handle, R4ProgramThreadInfo *out) {
    if (!r4_join_handle_valid(handle)) return R4OS_ERR_CLOSED;
    return r4sys_thread_handle_status(&handle->app->system, &handle->handle, out);
}

static inline R4ResourceWait r4_join_wait(R4JoinHandle *handle, R4Timeout timeout) {
    R4ResourceWait result = {R4_RESOURCE_WAIT_FAILED, R4OS_ERR_CLOSED};
    if (!r4_join_handle_valid(handle)) return result;
    if (!handle->owned) { result.value = R4OS_ERR_NOT_OWNED; return result; }
    uint64_t ticks = 0u; if (r4_resource_wait_ticks(handle->app, timeout, &ticks) != R4OS_OK) { result.value = R4OS_THREAD_ERROR_INVALID; return result; }
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
    uint64_t ticks = 0u; if (r4_resource_wait_ticks(request->app, timeout, &ticks) != R4OS_OK) { result.value = R4OS_IO_ERROR_INVALID; return result; }
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


/* Scalar resource operations retain the native generation/cursor contract. */
static inline int r4_resources_available(const R4Resources *resources) {
    R4App *app = resources ? resources->app : 0;
    return R4_RESOURCE_SYS_HAS(app, program_spawn_handle) &&
        R4_RESOURCE_SYS_HAS(app, program_open_handle) &&
        R4_RESOURCE_SYS_HAS(app, program_handle_status) &&
        R4_RESOURCE_SYS_HAS(app, program_handle_request_close) &&
        R4_RESOURCE_SYS_HAS(app, program_handle_kill) &&
        R4_RESOURCE_SYS_HAS(app, program_handle_wait) &&
        R4_RESOURCE_SYS_HAS(app, program_handle_reap) &&
        R4_RESOURCE_SYS_HAS(app, program_completion_read) &&
        R4_RESOURCE_SYS_HAS(app, thread_create_handle) &&
        R4_RESOURCE_SYS_HAS(app, thread_handle_join) &&
        R4_RESOURCE_SYS_HAS(app, thread_handle_status) &&
        R4_RESOURCE_SYS_HAS(app, vm_reserve) &&
        R4_RESOURCE_SYS_HAS(app, vm_release) &&
        R4_RESOURCE_SYS_HAS(app, io_wait) &&
        R4_RESOURCE_SYS_HAS(app, io_close);
}
static inline int32_t r4_resources_borrow_process(R4Resources *resources, const R4ProgramProcessHandle *handle, R4Process *out) {
    if (out) *out = (R4Process){0};
    if (!resources || !resources->app || !handle || !out || !handle->instance_id || !handle->generation || handle->reserved)
        return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    out->app = resources->app; r4os_process_store_abi_handle(out, handle); return R4OS_PROGRAM_HANDLE_OK;
}
static inline int32_t r4_resources_current_thread(R4Resources *resources, R4JoinHandle *out) {
    if (out) *out = (R4JoinHandle){0};
    if (!resources || !resources->app || !out) return R4OS_THREAD_ERROR_INVALID;
    int32_t raw = r4sys_thread_current_handle(&resources->app->system, &out->handle);
    if (raw == R4OS_THREAD_OK) out->app = resources->app;
    return raw;
}
static inline int32_t r4_join_placement(R4JoinHandle *handle, R4ThreadPlacementInfo *info, uint64_t *cpus, uint32_t capacity) {
    if (!r4_join_handle_valid(handle)) return R4OS_ERR_CLOSED;
    return r4sys_thread_placement_get(&handle->app->system, &handle->handle, info, cpus, capacity);
}
static inline int32_t r4_join_set_placement(R4JoinHandle *handle, const R4ThreadPlacementRequest *request, const uint64_t *cpus, uint32_t count) {
    if (!r4_join_handle_valid(handle)) return R4OS_ERR_CLOSED;
    return r4sys_thread_placement_set(&handle->app->system, &handle->handle, request, cpus, count);
}
static inline int32_t r4_vm_region_commit_flags(R4VmRegion *region, uint64_t offset, uint64_t len, uint64_t flags) {
    return r4_vm_region_valid(region) ? r4sys_vm_commit_flags(&region->app->system, region->raw, offset, len, flags) : R4OS_ERR_CLOSED;
}
static inline int32_t r4_resources_cpu_capacity(R4Resources *resources, R4CpuCapacity *out) {
    if (!resources || !resources->app) return R4OS_ERR_NO_FN;
    return r4sys_cpu_capacity(&resources->app->system, out);
}
static inline int32_t r4_resources_program_lifecycle_begin(R4Resources *resources, R4ProgramInventoryCursor *cursor) {
    if (resources == 0 || resources->app == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    return r4sys_program_lifecycle_begin(&resources->app->system, cursor);
}
static inline int32_t r4_resources_program_lifecycle_programs(R4Resources *resources, R4ProgramInventoryCursor *cursor,
    R4ProgramLifecycleSnapshot *out, uint32_t capacity, R4ProgramInventoryPageInfo *page) {
    if (resources == 0 || resources->app == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    return r4sys_program_lifecycle_programs(&resources->app->system, cursor, out, capacity, page);
}
static inline int32_t r4_resources_program_inventory_begin(R4Resources *resources, R4ProgramInventoryCursor *cursor, R4ProgramInventorySummary *summary) {
    if (!resources || !resources->app) return R4OS_ERR_NO_FN;
    return r4sys_program_inventory_begin(&resources->app->system, cursor, summary);
}
static inline int32_t r4_resources_program_inventory_programs(R4Resources *resources, R4ProgramInventoryCursor *cursor, R4ProgramInstanceSnapshot *out, uint32_t capacity, R4ProgramInventoryPageInfo *page) {
    if (!resources || !resources->app) return R4OS_ERR_NO_FN;
    return r4sys_program_inventory_programs(&resources->app->system, cursor, out, capacity, page);
}
static inline int32_t r4_resources_program_inventory_tasks(R4Resources *resources, R4ProgramInventoryCursor *cursor, R4ProgramTaskSnapshot *out, uint32_t capacity, R4ProgramInventoryPageInfo *page) {
    if (!resources || !resources->app) return R4OS_ERR_NO_FN;
    return r4sys_program_inventory_tasks(&resources->app->system, cursor, out, capacity, page);
}
static inline int32_t r4_resources_program_inventory_threads(R4Resources *resources, R4ProgramInventoryCursor *cursor, R4ProgramThreadSnapshot *out, uint32_t capacity, R4ProgramInventoryPageInfo *page) {
    if (!resources || !resources->app) return R4OS_ERR_NO_FN;
    return r4sys_program_inventory_threads(&resources->app->system, cursor, out, capacity, page);
}
static inline int32_t r4_resources_notification_create(R4Resources *resources, uint64_t *out) {
    if (!out) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, notification_create)) return R4OS_ERR_NO_FN;
    return ((R4SysNotificationCreateFn)(uintptr_t)R4SYS_SLOT(&app->system, notification_create))(out);
}
static inline int32_t r4_resources_notification_query(R4Resources *resources, uint64_t handle, uint64_t *sequence) {
    if (!sequence) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, notification_query)) return R4OS_ERR_NO_FN;
    return ((R4SysNotificationQueryFn)(uintptr_t)R4SYS_SLOT(&app->system, notification_query))(handle, sequence);
}
static inline int32_t r4_resources_notification_notify(R4Resources *resources, uint64_t handle, uint32_t count) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, notification_notify)) return R4OS_ERR_NO_FN;
    return ((R4SysNotificationNotifyFn)(uintptr_t)R4SYS_SLOT(&app->system, notification_notify))(handle, count);
}
static inline int32_t r4_resources_notification_wait(R4Resources *resources, uint64_t handle, uint64_t observed, uint64_t ticks) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, notification_wait)) return R4OS_ERR_NO_FN;
    return ((R4SysNotificationWaitFn)(uintptr_t)R4SYS_SLOT(&app->system, notification_wait))(handle, observed, ticks);
}
static inline int32_t r4_resources_notification_close(R4Resources *resources, uint64_t handle) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, notification_close)) return R4OS_ERR_NO_FN;
    return ((R4SysNotificationCloseFn)(uintptr_t)R4SYS_SLOT(&app->system, notification_close))(handle);
}
static inline int32_t r4_resources_program_local_get(R4Resources *resources, uint64_t key, uint64_t *out) {
    if (!out) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_local_get)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramLocalGetFn)(uintptr_t)R4SYS_SLOT(&app->system, program_local_get))(key, out);
}
static inline int32_t r4_resources_program_local_publish(R4Resources *resources, uint64_t key, uint64_t value, uint64_t *out) {
    if (!out) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_local_publish)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramLocalPublishFn)(uintptr_t)R4SYS_SLOT(&app->system, program_local_publish))(key, value, out);
}
static inline int32_t r4_resources_program_run(R4Resources *resources, const uint8_t *path, const uint8_t *args) {
    if (!path || !args) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_run)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramRunFn)(uintptr_t)R4SYS_SLOT(&app->system, program_run))(path, args);
}
static inline int32_t r4_resources_program_launch(R4Resources *resources, const uint8_t *path, const uint8_t *args, uint32_t policy) {
    if (!path || !args) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_launch)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramLaunchFn)(uintptr_t)R4SYS_SLOT(&app->system, program_launch))(path, args, policy);
}
static inline int32_t r4_resources_program_spawn(R4Resources *resources, const uint8_t *path, const uint8_t *args, uint32_t policy) {
    if (!path || !args) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_spawn)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramSpawnFn)(uintptr_t)R4SYS_SLOT(&app->system, program_spawn))(path, args, policy);
}
static inline int32_t r4_resources_program_instance(R4Resources *resources, uint32_t index, R4ProgramInstanceInfo *out) {
    if (!out) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_instance)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramInstanceFn)(uintptr_t)R4SYS_SLOT(&app->system, program_instance))(index, out);
}
static inline int32_t r4_resources_program_class(R4Resources *resources, const uint8_t *path, uint32_t policy) {
    if (!path) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_class)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramClassFn)(uintptr_t)R4SYS_SLOT(&app->system, program_class))(path, policy);
}
static inline int32_t r4_resources_program_module_path(R4Resources *resources, uint8_t *out, uint32_t capacity) {
    if (!out) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_module_path)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramModulePathFn)(uintptr_t)R4SYS_SLOT(&app->system, program_module_path))(out, capacity);
}
static inline int32_t r4_resources_program_module_running(R4Resources *resources, const uint8_t *path) {
    if (!path) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_module_running)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramModuleRunningFn)(uintptr_t)R4SYS_SLOT(&app->system, program_module_running))(path);
}
static inline int32_t r4_resources_program_reap_instance(R4Resources *resources, uint32_t id) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_reap_instance)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramReapInstanceFn)(uintptr_t)R4SYS_SLOT(&app->system, program_reap_instance))(id);
}
static inline int32_t r4_resources_program_request_close(R4Resources *resources, uint32_t id) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_request_close)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramRequestCloseFn)(uintptr_t)R4SYS_SLOT(&app->system, program_request_close))(id);
}
static inline int32_t r4_resources_program_kill(R4Resources *resources, uint32_t id) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_kill)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramKillFn)(uintptr_t)R4SYS_SLOT(&app->system, program_kill))(id);
}
static inline int32_t r4_resources_program_exit(R4Resources *resources, int32_t code, uint32_t reason) {
    if (0) return R4OS_ERROR_INVALID;
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, program_exit)) return R4OS_ERR_NO_FN;
    return ((R4SysProgramExitFn)(uintptr_t)R4SYS_SLOT(&app->system, program_exit))(code, reason);
}
static inline int32_t r4_resources_async_write_at(R4Resources *resources, R4PathZ path, uint64_t offset, const uint8_t *data, uint64_t length, uint32_t flags, R4IoRequest *out) {
    if (out) *out = (R4IoRequest){0};
    R4App *app = resources ? resources->app : 0;
    if (!out || !path.ptr || !R4_RESOURCE_SYS_HAS(app, io_file_write_at)) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0;
    int32_t raw = ((R4SysIoFileWriteAtFn)(uintptr_t)R4SYS_SLOT(&app->system, io_file_write_at))(path.ptr, offset, data, length, flags, &id);
    if (raw == R4OS_IO_OK) r4_io_bind(out, app, id, R4_IO_BUFFER_READ_ONLY, 0, data, length);
    return raw;
}
static inline int32_t r4_resources_async_file_info(R4Resources *resources, R4PathZ path, uint32_t flags, R4IoRequest *out) {
    if (out) *out = (R4IoRequest){0};
    R4App *app = resources ? resources->app : 0;
    if (!out || !path.ptr || !R4_RESOURCE_SYS_HAS(app, io_file_info)) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0;
    int32_t raw = ((R4SysIoFileInfoFn)(uintptr_t)R4SYS_SLOT(&app->system, io_file_info))(path.ptr, flags, &id);
    if (raw == R4OS_IO_OK) r4_io_bind(out, app, id, R4_IO_BUFFER_NONE, 0, 0, 0);
    return raw;
}
static inline int32_t r4_resources_async_file_lock(R4Resources *resources, R4PathZ path, uint64_t offset, uint64_t length, uint32_t flags, R4IoRequest *out) {
    if (out) *out = (R4IoRequest){0};
    R4App *app = resources ? resources->app : 0;
    if (!out || !path.ptr || !R4_RESOURCE_SYS_HAS(app, io_file_lock)) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0;
    int32_t raw = ((R4SysIoFileLockFn)(uintptr_t)R4SYS_SLOT(&app->system, io_file_lock))(path.ptr, offset, length, flags, &id);
    if (raw == R4OS_IO_OK) r4_io_bind(out, app, id, R4_IO_BUFFER_NONE, 0, 0, 0);
    return raw;
}

/* All three service-call buffers are caller-owned through the exact io_close
 * acknowledgement, including timeout/cancellation. Do not release on wait. */
static inline int32_t r4_resources_async_service_call(R4Resources *resources,
    uint32_t service, uint16_t op, const uint8_t *request, uint32_t request_length,
    R4ServiceMessageHeader *header, uint8_t *response, uint32_t response_capacity,
    uint64_t timeout_ticks, uint32_t flags, R4IoRequest *out) {
    if (out) *out = (R4IoRequest){0};
    if (!resources || !resources->app || !out) return R4OS_IO_ERROR_UNSUPPORTED;
    uint32_t id = 0;
    int32_t raw = r4sys_io_service_call(&resources->app->system, service, op, request, request_length,
        header, response, response_capacity, timeout_ticks, flags, &id);
    if (raw == R4OS_IO_OK) r4_io_bind(out, resources->app, id, R4_IO_BUFFER_MUTABLE, response, request, response_capacity);
    return raw;
}
static inline int32_t r4_resource_timeout_ticks(R4Resources *resources, R4Timeout timeout, uint64_t *out) {
    return r4_resource_wait_ticks(resources ? resources->app : 0, timeout, out);
}


static inline int32_t r4_resources_program_status(R4Resources *resources, R4ProgramStatus *out) {
    R4App *app = resources ? resources->app : 0;
    if (!out || !R4_RESOURCE_SYS_HAS(app, program_status)) return R4OS_ERR_NO_FN;
    ((R4SysProgramStatusFn)(uintptr_t)R4SYS_SLOT(&app->system, program_status))(out); return R4OS_OK;
}
static inline int32_t r4_resources_thread_create_raw(R4Resources *resources, R4ThreadEntryFn entry, uint64_t arg, uint64_t reserve, uint32_t flags, uint32_t *out) {
    R4App *app = resources ? resources->app : 0;
    if (out) *out = 0;
    if (!entry || !out) return R4OS_THREAD_ERROR_INVALID;
    if (!R4_RESOURCE_SYS_HAS(app, thread_create)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    return ((R4SysThreadCreateFn)(uintptr_t)R4SYS_SLOT(&app->system, thread_create))(entry, arg, reserve, flags, out);
}
static inline int32_t r4_resources_thread_exit(R4Resources *resources, int32_t code) {
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_SYS_HAS(app, thread_exit)) return R4OS_THREAD_ERROR_UNSUPPORTED;
    ((R4SysThreadExitFn)(uintptr_t)R4SYS_SLOT(&app->system, thread_exit))(code);
    return R4OS_THREAD_ERROR_INVALID; /* A valid terminal callback never returns. */
}
static inline int32_t r4_resources_thread_join_raw(R4Resources *resources, uint32_t id, uint64_t ticks, int32_t *out) {
    if (!resources || !resources->app) return R4OS_THREAD_ERROR_UNSUPPORTED;
    return r4sys_thread_join(&resources->app->system, id, ticks, out);
}
static inline uint32_t r4_resources_thread_current_id(R4Resources *resources) {
    return resources && resources->app ? r4sys_thread_current(&resources->app->system) : 0;
}
static inline int32_t r4_resources_thread_status_raw(R4Resources *resources, uint32_t id, R4ProgramThreadInfo *out) {
    return resources && resources->app ? r4sys_thread_status(&resources->app->system, id, out) : R4OS_THREAD_ERROR_UNSUPPORTED;
}
static inline int32_t r4_resources_program_set_console_host(R4Resources *resources, uint32_t id, uint32_t host) {
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_DESK_HAS(app, program_set_console_host)) return R4OS_ERR_NO_FN;
    return ((R4DeskProgramSetConsoleHostFn)(uintptr_t)R4_RESOURCE_DESK_SLOT(app, program_set_console_host))(id, host);
}
static inline uint32_t r4_resources_program_current_console_host(R4Resources *resources) {
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_DESK_HAS(app, program_current_console_host)) return R4ABI_CONSOLE_HOST_KIND_NONE;
    return ((R4DeskProgramCurrentConsoleHostFn)(uintptr_t)R4_RESOURCE_DESK_SLOT(app, program_current_console_host))();
}
static inline int32_t r4_resources_program_request_desktop(R4Resources *resources) {
    R4App *app = resources ? resources->app : 0;
    if (!R4_RESOURCE_DESK_HAS(app, program_request_desktop)) return R4OS_ERR_NO_FN;
    return ((R4DeskProgramRequestDesktopFn)(uintptr_t)R4_RESOURCE_DESK_SLOT(app, program_request_desktop))();
}
static inline int32_t r4_resources_program_spawn_with_console_host(R4Resources *resources, const uint8_t *path, const uint8_t *args, uint32_t policy, uint32_t host) {
    R4App *app = resources ? resources->app : 0;
    if (!path || !args) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!R4_RESOURCE_DESK_HAS(app, program_spawn_with_console_host)) return R4OS_ERR_NO_FN;
    return ((R4DeskProgramSpawnWithConsoleHostFn)(uintptr_t)R4_RESOURCE_DESK_SLOT(app, program_spawn_with_console_host))(path, args, policy, host);
}
#endif
