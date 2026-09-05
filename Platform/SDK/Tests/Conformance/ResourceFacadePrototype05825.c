#include <r4os/r4os.h>

_Static_assert(sizeof(struct R4Process) == sizeof(R4OS_ProcessHandle), "legacy R4Process tag layout drifted");
_Static_assert(sizeof(((struct R4Process *)0)->raw) == sizeof(uint32_t), "legacy R4Process.raw is no longer uint32_t");

static uint64_t now_ticks = 10u;
static uint64_t process_generation;
static uint32_t process_slots, thread_slots, vm_slots, io_slots;
static int process_active, process_done, process_exit;
static int thread_active, thread_exit_code;
static int vm_active, vm_wrong_owner;
static int io_active, io_complete;

static uint64_t fake_ticks(void) { return now_ticks; }
static void fake_time_state(R4TimeState *out) { *out = (R4TimeState){0}; out->monotonic_hz = 1000u; out->valid = 1u; }
static void fake_yield(void) { ++now_ticks; }
static int32_t fake_program_spawn(const uint8_t *path, const uint8_t *args, uint32_t policy) { (void)path; (void)args; (void)policy; if (process_active) return -3; process_active = 1; process_done = 0; process_exit = 0; ++process_slots; return 41; }
static int32_t fake_program_instance(uint32_t index, R4ProgramInstanceInfo *out) { if (!process_active || index != 0u) return 0; *out = (R4ProgramInstanceInfo){0}; out->id = 41u; out->state = (uint8_t)(process_done ? 2u : 0u); return 1; }
static int32_t fake_program_close(uint32_t id) { if (!process_active || id != 41u) return -1; process_done = 1; return 0; }
static int32_t fake_program_kill(uint32_t id) { if (!process_active || id != 41u) return -1; process_done = 1; process_exit = -9; return 0; }
static int32_t fake_program_reap(uint32_t id) { if (!process_active || id != 41u) return -1; if (!process_done) return -2; process_active = 0; --process_slots; return process_exit; }

static int32_t fake_handle_valid(const R4ProgramProcessHandle *handle) {
    if (handle == 0 || handle->instance_id == 0u || handle->generation == 0u || handle->reserved != 0u) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    if (!process_active) return R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND;
    if (handle->instance_id != 41u || handle->generation != process_generation) return R4OS_PROGRAM_HANDLE_ERROR_STALE;
    return R4OS_PROGRAM_HANDLE_OK;
}
static int32_t fake_program_spawn_handle(const uint8_t *path, const uint8_t *args, uint32_t policy, R4ProgramProcessHandle *out) {
    (void)path; (void)args; (void)policy;
    if (process_active) return R4OS_PROGRAM_HANDLE_ERROR_NO_MEMORY;
    ++process_generation; process_active = 1; process_done = 0; process_exit = 0; ++process_slots;
    *out = (R4ProgramProcessHandle){0}; out->instance_id = 41u; out->generation = process_generation;
    return R4OS_PROGRAM_HANDLE_OK;
}
static int32_t fake_program_spawn_with_console_host_handle(const uint8_t *path, const uint8_t *args, uint32_t policy, uint32_t host, R4ProgramProcessHandle *out) {
    (void)host; return fake_program_spawn_handle(path, args, policy, out);
}
static int32_t fake_program_open_handle(uint32_t id, R4ProgramProcessHandle *out) {
    if (!process_active || id != 41u) return R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND;
    *out = (R4ProgramProcessHandle){0}; out->instance_id = id; out->generation = process_generation;
    return R4OS_PROGRAM_HANDLE_OK;
}
static int32_t fake_program_handle_status(const R4ProgramProcessHandle *handle, R4ProgramInstanceInfo *out) {
    int32_t status = fake_handle_valid(handle); if (status != R4OS_PROGRAM_HANDLE_OK) return status;
    *out = (R4ProgramInstanceInfo){0}; out->id = 41u; out->state = (uint8_t)(process_done ? 2u : 0u); out->exit_code = process_exit;
    return status;
}
static int32_t fake_program_handle_close(const R4ProgramProcessHandle *handle) { int32_t status = fake_handle_valid(handle); if (status == 0) process_done = 1; return status; }
static int32_t fake_program_handle_kill(const R4ProgramProcessHandle *handle) { int32_t status = fake_handle_valid(handle); if (status == 0) { process_done = 1; process_exit = -9; } return status; }
static R4ProgramProcessCompletion fake_completion(const R4ProgramProcessHandle *handle) {
    R4ProgramProcessCompletion value = {0}; value.handle = *handle; value.sequence = process_generation; value.start_tick = 10u; value.finish_tick = now_ticks;
    value.exit_code = process_exit; value.output_revision = 1u; value.output_length = 2u;
    value.flags = R4OS_PROGRAM_COMPLETION_FLAG_READY | R4OS_PROGRAM_COMPLETION_FLAG_OUTPUT | R4OS_PROGRAM_COMPLETION_FLAG_OWNER;
    value.exit_reason = process_exit == -9 ? R4OS_PROGRAM_EXIT_REASON_KILLED : R4OS_PROGRAM_EXIT_REASON_CLOSE; return value;
}
static int32_t fake_program_handle_wait(const R4ProgramProcessHandle *handle, uint64_t timeout, R4ProgramProcessCompletion *out) {
    int32_t status = fake_handle_valid(handle); if (status != 0) return status;
    if (!process_done && timeout == 0u) return R4OS_PROGRAM_HANDLE_ERROR_TIMEOUT;
    if (!process_done) process_done = 1; *out = fake_completion(handle); return status;
}
static int32_t fake_program_handle_reap(const R4ProgramProcessHandle *handle, R4ProgramProcessCompletion *out) {
    int32_t status = fake_handle_valid(handle); if (status != 0) return status;
    if (!process_done) return R4OS_PROGRAM_HANDLE_ERROR_WOULD_BLOCK;
    *out = fake_completion(handle); process_active = 0; --process_slots; return status;
}
static int32_t fake_program_completion_read(const R4ProgramProcessHandle *handle, uint32_t offset, uint8_t *out, uint32_t capacity, uint32_t *out_read) {
    static const uint8_t text[] = {'O', 'K'}; int32_t status = fake_handle_valid(handle); if (status != 0) return status;
    if (!process_done) return R4OS_PROGRAM_HANDLE_ERROR_WOULD_BLOCK; if (offset > 2u) return R4OS_PROGRAM_HANDLE_ERROR_OUTPUT_RANGE;
    uint32_t count = capacity < 2u - offset ? capacity : 2u - offset; for (uint32_t i = 0; i < count; ++i) out[i] = text[offset + i]; *out_read = count; return status;
}

static int32_t unused_thread(uint64_t arg) { return (int32_t)arg; }
static int32_t fake_thread_create(R4ThreadEntryFn entry, uint64_t arg, uint64_t stack, uint32_t flags, uint32_t *out) { (void)entry; (void)stack; if (flags != 0u) return R4OS_THREAD_ERROR_UNSUPPORTED; if (thread_active) return R4OS_THREAD_ERROR_NO_SLOTS; thread_active = 1; thread_exit_code = (int)arg; ++thread_slots; *out = 51u; return R4OS_THREAD_OK; }
static void fake_thread_exit(int32_t code) { (void)code; }
static uint32_t fake_thread_current(void) { return 1u; }
static int32_t fake_thread_status(uint32_t id, R4ProgramThreadInfo *out) { if (!thread_active || id != 51u) return R4OS_THREAD_ERROR_NOT_FOUND; *out = (R4ProgramThreadInfo){0}; out->thread_id = id; out->flags = R4OS_THREAD_FLAG_JOINABLE; return R4OS_THREAD_OK; }
static int32_t fake_thread_join(uint32_t id, uint64_t timeout, int32_t *out) { if (!thread_active || id != 51u) return R4OS_THREAD_ERROR_NOT_FOUND; if (timeout == 0u) return R4OS_THREAD_ERROR_TIMEOUT; *out = thread_exit_code; thread_active = 0; --thread_slots; return R4OS_THREAD_OK; }
static int32_t fake_thread_create_handle(R4ThreadEntryFn entry, uint64_t arg, uint64_t stack, uint32_t flags, R4ProgramJoinHandle *out) { uint32_t id = 0u; int32_t status = fake_thread_create(entry, arg, stack, flags, &id); if (status != R4OS_THREAD_OK) return status; *out = (R4ProgramJoinHandle){0}; out->thread_id = id; out->instance_id = 1u; out->thread_generation = 5u; out->instance_generation = 9u; return status; }
static int fake_thread_handle_valid(const R4ProgramJoinHandle *handle) { return handle != 0 && handle->thread_id == 51u && handle->instance_id == 1u && handle->thread_generation == 5u && handle->instance_generation == 9u && handle->reserved == 0u; }
static int32_t fake_thread_handle_status(const R4ProgramJoinHandle *handle, R4ProgramThreadInfo *out) { return fake_thread_handle_valid(handle) ? fake_thread_status(handle->thread_id, out) : R4OS_THREAD_ERROR_NOT_FOUND; }
static int32_t fake_thread_handle_join(const R4ProgramJoinHandle *handle, uint64_t timeout, int32_t *out) { return fake_thread_handle_valid(handle) ? fake_thread_join(handle->thread_id, timeout, out) : R4OS_THREAD_ERROR_NOT_FOUND; }

static int32_t fake_vm_reserve(uint64_t size, uint64_t alignment, uint64_t flags, R4ProgramVmRegionInfo *out) { (void)alignment; (void)flags; if (vm_active) return R4OS_VM_ERROR_TABLE_FULL; vm_active = 1; ++vm_slots; *out = (R4ProgramVmRegionInfo){0}; out->id = 61u; out->base = 0x100000u; out->len = size; return R4OS_VM_OK; }
static int32_t fake_vm_commit(uint32_t id, uint64_t offset, uint64_t len, uint64_t flags) { (void)offset; (void)flags; return vm_active && id == 61u && len != 0u ? R4OS_VM_OK : R4OS_VM_ERROR_INVALID_RANGE; }
static int32_t fake_vm_decommit(uint32_t id, uint64_t offset, uint64_t len) { (void)offset; (void)len; return vm_active && id == 61u ? R4OS_VM_OK : R4OS_VM_ERROR_INVALID_RANGE; }
static int32_t fake_vm_query(uint32_t id, R4ProgramVmRegionInfo *out) { if (!vm_active || id != 61u) return R4OS_VM_ERROR_INVALID_RANGE; *out = (R4ProgramVmRegionInfo){0}; out->id = id; out->len = 4096u; return R4OS_VM_OK; }
static int32_t fake_vm_release(uint32_t id) { if (vm_wrong_owner) return R4OS_VM_ERROR_OWNER_MISMATCH; if (!vm_active || id != 61u) return R4OS_VM_ERROR_INVALID_RANGE; vm_active = 0; --vm_slots; return R4OS_VM_OK; }

static int32_t fake_io_read(const uint8_t *path, uint8_t *out, uint64_t capacity, uint32_t flags, uint32_t *id) { (void)path; (void)out; (void)capacity; (void)flags; if (io_active) return R4OS_IO_ERROR_NO_SLOTS; io_active = 1; io_complete = 0; ++io_slots; *id = 71u; return R4OS_IO_OK; }
static int32_t fake_io_write(const uint8_t *path, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *id) { return fake_io_read(path, (uint8_t *)(uintptr_t)data, len, flags, id); }
static int32_t fake_io_stream_write(const uint8_t *path, uint64_t offset, const uint8_t *data, uint64_t len, uint32_t flags, uint32_t *id) { (void)offset; return fake_io_write(path, data, len, flags, id); }
static int32_t fake_io_service(uint32_t handle, uint16_t op, const uint8_t *request, uint32_t request_len, R4ServiceMessageHeader *header, uint8_t *response, uint32_t capacity, uint64_t timeout, uint32_t flags, uint32_t *id) { (void)handle; (void)op; (void)request_len; (void)header; (void)response; (void)capacity; (void)timeout; return fake_io_write((const uint8_t *)"X", request, 0u, flags, id); }
static int32_t fake_io_status(uint32_t id, R4ProgramIoInfo *out) { if (!io_active || id != 71u) return R4OS_IO_ERROR_NOT_FOUND; *out = (R4ProgramIoInfo){0}; out->request_id = id; out->state = io_complete ? R4OS_IO_STATE_COMPLETED : R4OS_IO_STATE_RUNNING; out->result = io_complete ? 4 : 0; return R4OS_IO_OK; }
static int32_t fake_io_wait(uint32_t id, uint64_t timeout, R4ProgramIoInfo *out) { if (!io_active || id != 71u) return R4OS_IO_ERROR_NOT_FOUND; if (timeout == 0u && !io_complete) return R4OS_IO_ERROR_TIMEOUT; io_complete = 1; return fake_io_status(id, out); }
static int32_t fake_io_close(uint32_t id) { if (!io_active || id != 71u) return R4OS_IO_ERROR_NOT_FOUND; if (!io_complete) return R4OS_IO_ERROR_BUSY; io_active = 0; --io_slots; return R4OS_IO_OK; }

static R4Timeout poll_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_POLL; return value; }
static R4Timeout forever_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FOREVER; return value; }

static void init_app(R4App *app, R4XStartR4Sys *table, R4XStartR4Desk *desk) {
    *table = (R4XStartR4Sys){0}; table->magic = R4XSTART_R4SYS_MAGIC; table->abi_version = R4XSTART_R4SYS_VERSION; table->size = R4XSTART_R4SYS_SIZE;
    table->ticks = (uintptr_t)&fake_ticks; table->time_state = (uintptr_t)&fake_time_state; table->task_yield = (uintptr_t)&fake_yield;
    table->program_spawn = (uintptr_t)&fake_program_spawn; table->program_instance = (uintptr_t)&fake_program_instance; table->program_request_close = (uintptr_t)&fake_program_close; table->program_kill = (uintptr_t)&fake_program_kill; table->program_reap_instance = (uintptr_t)&fake_program_reap;
    table->program_spawn_handle = (uintptr_t)&fake_program_spawn_handle; table->program_open_handle = (uintptr_t)&fake_program_open_handle; table->program_handle_status = (uintptr_t)&fake_program_handle_status; table->program_handle_request_close = (uintptr_t)&fake_program_handle_close; table->program_handle_kill = (uintptr_t)&fake_program_handle_kill; table->program_handle_wait = (uintptr_t)&fake_program_handle_wait; table->program_handle_reap = (uintptr_t)&fake_program_handle_reap; table->program_completion_read = (uintptr_t)&fake_program_completion_read;
    table->thread_create = (uintptr_t)&fake_thread_create; table->thread_exit = (uintptr_t)&fake_thread_exit; table->thread_join = (uintptr_t)&fake_thread_join; table->thread_current = (uintptr_t)&fake_thread_current; table->thread_status = (uintptr_t)&fake_thread_status;
    table->thread_create_handle = (uintptr_t)&fake_thread_create_handle; table->thread_handle_join = (uintptr_t)&fake_thread_handle_join; table->thread_handle_status = (uintptr_t)&fake_thread_handle_status;
    table->vm_reserve = (uintptr_t)&fake_vm_reserve; table->vm_commit = (uintptr_t)&fake_vm_commit; table->vm_decommit = (uintptr_t)&fake_vm_decommit; table->vm_release = (uintptr_t)&fake_vm_release; table->vm_query = (uintptr_t)&fake_vm_query;
    table->io_file_read = (uintptr_t)&fake_io_read; table->io_file_write = (uintptr_t)&fake_io_write; table->io_file_stream_write = (uintptr_t)&fake_io_stream_write; table->io_service_call = (uintptr_t)&fake_io_service; table->io_status = (uintptr_t)&fake_io_status; table->io_wait = (uintptr_t)&fake_io_wait; table->io_close = (uintptr_t)&fake_io_close;
    *desk = (R4XStartR4Desk){0}; desk->magic = R4XSTART_R4DESK_MAGIC; desk->abi_version = R4XSTART_R4DESK_VERSION; desk->size = R4XSTART_R4DESK_SIZE;
    desk->program_spawn_with_console_host_handle = (uintptr_t)&fake_program_spawn_with_console_host_handle;
    *app = (R4App){0}; app->system.table = table; app->desktop.table = desk;
}

int main(void) {
    R4App app; R4XStartR4Sys table; R4XStartR4Desk desk; init_app(&app, &table, &desk); R4Resources resources = r4_app_resources(&app);
    R4PerformanceView performance = r4_devices_performance(r4_app_devices(&app));
    R4ProgramRegistrySummary registry_v1 = {0}; R4ProgramRegistrySelfTestResult registry_test_v1 = {0};
    R4ProgramRegistrySummaryV2 registry_v2 = {0}; R4ProgramRegistrySelfTestResultV2 registry_test_v2 = {0};
    if (r4_program_registry_summary(&performance, &registry_v1) != R4OS_ERR_NO_FN || r4_program_registry_self_test(&performance, &registry_test_v1) != R4OS_ERR_NO_FN) return 32;
    if (r4_program_registry_summary_v2(&performance, &registry_v2) != R4OS_ERR_NO_FN || r4_program_registry_self_test_v2(&performance, &registry_test_v2) != R4OS_ERR_NO_FN) return 32;
    if (r4_program_registry_summary_legacy(&performance, &registry_v1) != R4OS_ERR_NO_FN || r4_program_registry_self_test_legacy(&performance, &registry_test_v1) != R4OS_ERR_NO_FN) return 32;
    struct R4Process legacy_process = {0}; legacy_process.raw = 73u;
    uint32_t legacy_id = legacy_process.raw;
    if (legacy_process.raw == 0u || legacy_id != 73u) return 33;
    legacy_process.raw = 0u; if (legacy_process.raw != 0u) return 33;
    const uint8_t path_bytes[] = "C:\\TEST.R4X"; R4PathZ path = {path_bytes, (uint16_t)(sizeof(path_bytes) - 1u)};
    struct R4Process invalid_process = {0}; R4ProgramInstanceInfo invalid_info = {0};
    if (r4_resources_open_process(&resources, 0u, &invalid_process) != R4OS_PROGRAM_HANDLE_ERROR_INVALID) return 31;
    if (r4_resources_spawn(0, path, "", 1u, &invalid_process) != R4OS_PROGRAM_HANDLE_ERROR_INVALID) return 31;
    if (r4os_process_status(0, &invalid_info) != R4OS_PROGRAM_HANDLE_ERROR_INVALID) return 31;
    if (r4os_process_status(&invalid_process, &invalid_info) != R4OS_ERR_CLOSED) return 31;
    R4Process process; if (r4_resources_spawn(&resources, path, "", 1u, &process) != 0) return 1;
    uintptr_t saved_status = table.program_handle_status; table.program_handle_status = 0u;
    if (r4os_process_status(&process, &invalid_info) != R4OS_ERR_NO_FN) return 31;
    table.program_handle_status = saved_status;
    R4Process borrowed; if (r4_resources_open_process(&resources, process.raw, &borrowed) != 0 || borrowed.owned != 0u) return 1;
    if (r4os_process_reap(&borrowed, &(R4OS_ProcessCompletion){0}) != R4OS_ERR_NOT_OWNED) return 1;
    if (r4_process_request_close(&process) != 0) return 1;
    R4OS_ProcessHandle stale = process; R4OS_ProcessCompletion completion = {0}; uint8_t completion_bytes[4] = {0}; uint32_t completion_read = 0u;
    if (r4os_process_completion_read(&borrowed, 0u, 0, 0u, &completion_read) != R4OS_PROGRAM_HANDLE_ERROR_INVALID) return 2;
    if (r4os_process_wait_ready(&borrowed, forever_timeout(), &completion) != 0 || completion.handle.generation != process.generation) return 2;
    if (r4os_process_completion_read(&borrowed, 0u, completion_bytes, sizeof(completion_bytes), &completion_read) != 0 || completion_read != 2u) return 2;
    if (r4os_process_wait(&borrowed, forever_timeout(), &completion) != R4OS_ERR_NOT_OWNED) return 2;
    if (r4os_process_wait_ready(&process, forever_timeout(), &completion) != 0 || completion.handle.generation != process.generation) return 2;
    if (r4os_process_completion_read(&process, 0u, completion_bytes, sizeof(completion_bytes), &completion_read) != 0 || completion_read != 2u || completion_bytes[0] != 'O' || completion_bytes[1] != 'K') return 2;
    if (r4os_process_reap(&process, &completion) != 0 || process.raw != 0u || process.generation != 0u ||
        process.handle_reserved != 0u || process.extension_reserved != 0u || r4_process_reap(&process).value != R4OS_ERR_CLOSED) return 2;
    if (r4os_spawn_with_console_host(&resources, path, "", 1u, 1u, &process) != 0 || stale.generation == process.generation) return 2;
    R4ProgramInstanceInfo stale_info = {0}; if (r4os_process_status(&stale, &stale_info) != R4OS_PROGRAM_HANDLE_ERROR_STALE) return 2;
    if (r4_process_kill(&process) != 0) return 2;
    R4OS_ProcessHandle fully_reaped = process;
    if (r4_process_wait(&process, forever_timeout()).kind != R4_RESOURCE_WAIT_EXITED) return 2;
    if (r4os_process_status(&fully_reaped, &stale_info) != R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND ||
        r4os_process_request_close(&fully_reaped) != R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND ||
        r4os_process_kill(&fully_reaped) != R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND ||
        r4os_process_wait_ready(&fully_reaped, poll_timeout(), &completion) != R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND ||
        r4os_process_completion_read(&fully_reaped, 0u, completion_bytes, sizeof(completion_bytes), &completion_read) != R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND ||
        r4os_process_reap(&fully_reaped, &completion) != R4OS_PROGRAM_HANDLE_ERROR_NOT_FOUND) return 2;
    R4JoinHandle join; if (r4_resources_create_thread(&resources, unused_thread, 17u, 0u, &join) != 0) return 3;
    if (r4_join_wait(&join, poll_timeout()).kind != R4_RESOURCE_WAIT_TIMED_OUT || !r4_join_handle_valid(&join)) return 4;
    R4ResourceWait joined = r4_join_wait(&join, forever_timeout()); if (joined.kind != R4_RESOURCE_WAIT_EXITED || joined.value != 17 || r4_join_wait(&join, forever_timeout()).value != R4OS_ERR_CLOSED) return 5;
    R4VmRegion region; if (r4_resources_reserve_vm(&resources, 4096u, 4096u, R4OS_VM_REGION_FLAGS_DEFAULT, &region) != 0 || r4_vm_region_commit(&region, 0u, 4096u) != 0) return 6;
    vm_wrong_owner = 1; if (r4_vm_region_release(&region) != R4OS_VM_ERROR_OWNER_MISMATCH) return 7; vm_wrong_owner = 0;
    R4VmRegion region_copy = region; if (r4_vm_region_release(&region) != 0 || r4_vm_region_release(&region_copy) != R4OS_ERR_CLOSED) return 8;
    uint8_t buffer[8] = {0}; R4IoRequest request; if (r4_resources_async_read(&resources, path, buffer, sizeof(buffer), 0u, &request) != 0) return 9;
    if (!r4_io_request_buffers_held(&request) || r4_io_request_release_buffers(&request) != R4OS_ERR_BUFFER_IN_USE) return 10;
    if (r4_io_request_wait(&request, poll_timeout()).kind != R4_RESOURCE_WAIT_TIMED_OUT || r4_io_request_close(&request) != R4OS_IO_ERROR_BUSY) return 11;
    if (r4_io_request_wait(&request, forever_timeout()).kind != R4_RESOURCE_WAIT_EXITED) return 12;
    R4IoRequest request_copy = request; if (r4_io_request_close(&request) != 0 || r4_io_request_close(&request_copy) != R4OS_ERR_CLOSED) return 13;
    for (uint32_t i = 0u; i < 80u; ++i) {
        if (r4_resources_spawn(&resources, path, "", 1u, &process) != 0 || r4_process_kill(&process) != 0) return 20;
        R4ResourceWait killed = r4_process_wait(&process, forever_timeout()); if (killed.kind != R4_RESOURCE_WAIT_EXITED || killed.value != -9) return 20;
        if (r4_resources_create_thread(&resources, unused_thread, i, 0u, &join) != 0 || r4_join_wait(&join, forever_timeout()).kind != R4_RESOURCE_WAIT_EXITED) return 21;
        if (r4_resources_reserve_vm(&resources, 4096u, 4096u, 0u, &region) != 0 || r4_vm_region_release(&region) != 0) return 22;
        if (r4_resources_async_read(&resources, path, buffer, sizeof(buffer), 0u, &request) != 0 || r4_io_request_wait(&request, forever_timeout()).kind != R4_RESOURCE_WAIT_EXITED || r4_io_request_close(&request) != 0) return 23;
    }
    return process_slots == 0u && thread_slots == 0u && vm_slots == 0u && io_slots == 0u ? 0 : 30;
}
