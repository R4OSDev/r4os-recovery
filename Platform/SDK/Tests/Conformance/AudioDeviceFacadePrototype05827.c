#include <r4os/r4os.h>
#include <string.h>

static int timeout_next;
static int stream_open;
static uint32_t open_connections;

static int32_t fake_service_open(const uint8_t *name, R4ServiceInfo *out) {
    (void)name; *out = (R4ServiceInfo){0}; out->handle = 77u; ++open_connections; return 0;
}
static int32_t fake_service_close(uint32_t handle) {
    if (handle != 77u || open_connections == 0u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE;
    --open_connections; return 0;
}
static int32_t fake_service_call(uint32_t handle, uint16_t op, const uint8_t *request, uint32_t request_len, R4ServiceMessageHeader *header, uint8_t *response, uint32_t capacity, uint64_t timeout) {
    (void)handle; (void)timeout;
    *header = (R4ServiceMessageHeader){0}; header->magic = R4OS_SERVICE_API_MAGIC; header->version = R4OS_SERVICE_API_VERSION; header->op = op; header->status = 0;
    if (timeout_next) { timeout_next = 0; return R4OS_SERVICE_API_RESULT_TIMEOUT; }
    if (op == R4OS_AUDIO_SERVICE_OP_MASTER_STATUS || op == R4OS_AUDIO_SERVICE_OP_SET_MASTER_STATE) {
        if (capacity < sizeof(R4AudioServiceMasterState)) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL;
        R4AudioServiceMasterState state = {0}; state.magic = R4OS_AUDIO_MASTER_STATE_MAGIC; state.version = R4OS_AUDIO_MASTER_STATE_VERSION; state.size = sizeof(state); state.master_revision = 4u; state.selected_volume_fixed = 0x8000u; state.last_audible_volume_fixed = 0x8000u;
        if (op == R4OS_AUDIO_SERVICE_OP_SET_MASTER_STATE) {
            R4AudioServiceMasterRequest master;
            if (request_len != sizeof(master)) return R4OS_SERVICE_API_RESULT_INVALID;
            memcpy(&master, request, sizeof(master));
            if (master.magic != R4OS_AUDIO_MASTER_REQUEST_MAGIC || master.version != R4OS_AUDIO_MASTER_REQUEST_VERSION || master.size != sizeof(master)) return R4OS_SERVICE_API_RESULT_INVALID;
            if ((master.flags & R4OS_AUDIO_MASTER_REQUEST_FLAG_MUTED) != 0u) state.flags |= R4OS_AUDIO_MASTER_STATE_FLAG_MUTED;
        }
        memcpy(response, &state, sizeof(state)); return (int32_t)sizeof(state);
    }
    if (capacity < sizeof(R4AudioWireResult)) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL;
    R4AudioWireResult result = {0}; result.magic = R4OS_AUDIO_SERVICE_RESULT_MAGIC; result.version = R4OS_AUDIO_SERVICE_RESULT_VERSION; result.action = op; result.stream_id = 91u;
    if (op == R4OS_AUDIO_SERVICE_OP_OPEN_STREAM) stream_open = 1;
    else if (op == R4OS_AUDIO_SERVICE_OP_WRITE_STREAM) {
        if (!stream_open || request_len < sizeof(R4AudioWireWriteRequest)) result.result = -1;
        else { R4AudioWireWriteRequest wire; memcpy(&wire, request, sizeof(wire)); result.bytes = wire.byte_count; result.result = (int32_t)wire.byte_count; }
    } else if (op == R4OS_AUDIO_SERVICE_OP_SET_STREAM_VOLUME) { if (!stream_open) result.result = -1; }
    else if (op == R4OS_AUDIO_SERVICE_OP_CLOSE_STREAM) { if (stream_open) stream_open = 0; else result.result = -1; }
    memcpy(response, &result, sizeof(result)); return (int32_t)sizeof(result);
}

static int32_t fake_audio_open(uint32_t rate, uint16_t channels, uint16_t format) { (void)rate; (void)channels; (void)format; return 1; }
static int32_t fake_sid_acquire(void) { return 11; }
static int32_t fake_sid_write(uint32_t handle, uint8_t reg, uint8_t value) { (void)handle; (void)reg; (void)value; return 0; }
static int32_t fake_sid_release(uint32_t handle) { (void)handle; return 0; }
static int32_t fake_midi_open(const uint8_t *backend) { (void)backend; return 12; }
static int32_t fake_midi_send(uint32_t handle, uint8_t channel, uint8_t status, uint8_t data1, uint8_t data2) { (void)handle; (void)channel; (void)status; (void)data1; (void)data2; return 0; }
static int32_t fake_midi_close(uint32_t handle) { (void)handle; return 0; }
static int32_t fake_opl_write(uint8_t bank, uint8_t reg, uint8_t value) { (void)bank; (void)reg; (void)value; return 0; }
static int32_t fake_opl_simple(void) { return 0; }

static int32_t fake_inventory_summary(R4DeviceInventorySummary *out) { *out = (R4DeviceInventorySummary){0}; out->total = 2u; out->with_driver = 1u; return 1; }
static int32_t fake_inventory_record(uint32_t index, R4DeviceInventoryRecord *out) { *out = (R4DeviceInventoryRecord){0}; out->bus = (uint8_t)(index + 1u); return 1; }
static int32_t fake_memory_summary(R4ProgramMemorySummary *out) { *out = (R4ProgramMemorySummary){0}; out->physical_bytes = 64u * 1024u * 1024u; return 0; }
static uint32_t fake_memory_count(void) { return 3u; }
static int32_t fake_memory_block(uint32_t index, R4ProgramMemoryBlockInfo *out) { *out = (R4ProgramMemoryBlockInfo){0}; out->id = index; return 1; }
static int32_t fake_pressure(R4ProgramMemoryPressureSnapshot *out) { *out = (R4ProgramMemoryPressureSnapshot){0}; out->pressure_level = R4OS_MEMORY_PRESSURE_LEVEL_NORMAL; return 1; }
static int32_t fake_performance(R4ProgramPerformanceSummary *out) { *out = (R4ProgramPerformanceSummary){0}; out->audio_stream_writes = 9u; return 1; }
static int32_t fake_program_instance_storage_legacy(R4ProgramInstanceStorageSummary *out) { memset(out, 0, 256u); out->version = 1u; out->size = 256u; out->active_instances = 4u; out->active_service_instances = 2u; out->current_payload_bytes = 4096u; out->payload_allocations = 11u; out->payload_releases = 7u; return 1; }
static int32_t fake_program_instance_storage_v2(R4ProgramInstanceStorageSummary *out) { if (out->version < 2u || out->size < sizeof(*out)) return -1; *out = (R4ProgramInstanceStorageSummary){0}; out->version = 2u; out->size = sizeof(*out); out->active_instances = 4u; out->active_service_instances = 2u; out->current_payload_bytes = 4096u; out->payload_allocations = 11u; out->payload_releases = 7u; out->current_gui_frame_bytes = 8192u; return 1; }
static int32_t fake_program_instance_storage_self_test(R4ProgramInstanceStorageSelfTestResult *out) { *out = (R4ProgramInstanceStorageSelfTestResult){0}; out->version = 1u; out->size = sizeof(*out); out->cases = 27u; out->passed_cases = 27u; out->flags = 0xFu; out->allocation_failures_before = 2u; out->allocation_failures_after = 4u; return 1; }
static int32_t fake_execution_inventory(R4ProgramInventorySummary *out) { *out = (R4ProgramInventorySummary){0}; out->version = R4OS_PROGRAM_INVENTORY_VERSION; out->size = sizeof(*out); out->program_total = 17u; out->task_total = 29u; out->thread_total = 23u; out->program_peak = 41u; return R4OS_PROGRAM_HANDLE_OK; }
static int32_t fake_task(uint32_t index, R4ProgramTaskPerformanceInfo *out) { *out = (R4ProgramTaskPerformanceInfo){0}; out->id = index; return 1; }
static int32_t fake_storage(uint32_t index, R4ProgramStoragePerformanceInfo *out) { *out = (R4ProgramStoragePerformanceInfo){0}; out->index = index; return 1; }
static int32_t fake_boot(uint32_t index, R4ProgramBootPhasePerformanceInfo *out) { (void)index; *out = (R4ProgramBootPhasePerformanceInfo){0}; return 1; }
static int32_t fake_hardware(R4HardwareSummary *out) { *out = (R4HardwareSummary){0}; out->cpu_logical_processors = 4u; return 1; }

static R4Timeout poll_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_POLL; return value; }
static R4Timeout forever_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FOREVER; return value; }

static void init_app(R4App *app, R4XStartR4Sys *sys, R4XStartR4Audio *audio, R4XStartR4Dev *dev) {
    *sys = (R4XStartR4Sys){0}; sys->service_open = (uintptr_t)&fake_service_open; sys->service_close = (uintptr_t)&fake_service_close; sys->service_call = (uintptr_t)&fake_service_call;
    *audio = (R4XStartR4Audio){0}; audio->audio_open_stream = (uintptr_t)&fake_audio_open; audio->sid_acquire = (uintptr_t)&fake_sid_acquire; audio->sid_write_register = (uintptr_t)&fake_sid_write; audio->sid_release = (uintptr_t)&fake_sid_release; audio->midi_open_synth = (uintptr_t)&fake_midi_open; audio->midi_send = (uintptr_t)&fake_midi_send; audio->midi_close = (uintptr_t)&fake_midi_close; audio->opl3_write_register = (uintptr_t)&fake_opl_write; audio->opl3_reset = (uintptr_t)&fake_opl_simple; audio->opl3_render_block = (uintptr_t)&fake_opl_simple; audio->opl3_stop = (uintptr_t)&fake_opl_simple;
    *dev = (R4XStartR4Dev){0}; dev->size = R4XSTART_R4DEV_SIZE; dev->device_inventory_summary = (uintptr_t)&fake_inventory_summary; dev->device_inventory_record = (uintptr_t)&fake_inventory_record; dev->memory_summary = (uintptr_t)&fake_memory_summary; dev->memory_block_count = (uintptr_t)&fake_memory_count; dev->memory_block = (uintptr_t)&fake_memory_block; dev->memory_pressure_snapshot = (uintptr_t)&fake_pressure; dev->performance_summary = (uintptr_t)&fake_performance; dev->performance_task = (uintptr_t)&fake_task; dev->performance_storage = (uintptr_t)&fake_storage; dev->performance_boot_phase = (uintptr_t)&fake_boot; dev->hardware_summary = (uintptr_t)&fake_hardware; dev->program_instance_storage_summary = (uintptr_t)&fake_program_instance_storage_legacy; dev->program_instance_storage_summary_v2 = (uintptr_t)&fake_program_instance_storage_v2; dev->program_instance_storage_self_test = (uintptr_t)&fake_program_instance_storage_self_test; dev->execution_inventory_summary = (uintptr_t)&fake_execution_inventory;
    *app = (R4App){0}; app->system.table = sys; app->audio.table = audio; app->devices.table = dev;
}

int main(void) {
    R4App app; R4XStartR4Sys sys; R4XStartR4Audio raw_audio; R4XStartR4Dev raw_dev;
    init_app(&app, &sys, &raw_audio, &raw_dev); stream_open = 0; open_connections = 0u;
    R4AudioFacade audio = r4_app_audio(&app); R4AudioStream stream;
    if (!r4_audio_available(&audio)) return 1;
    R4AudioServiceMasterState master;
    if (r4_audio_master_status(&audio, forever_timeout(), &master).kind != R4_AUDIO_RESULT_OK || master.selected_volume_fixed != 0x8000u) return 21;
    if (r4_audio_set_master_state(&audio, R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_VOLUME | R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_MUTED, 0x8000u, 1, master.master_revision, forever_timeout(), &master).kind != R4_AUDIO_RESULT_OK || (master.flags & R4OS_AUDIO_MASTER_STATE_FLAG_MUTED) == 0u) return 22;
    if (r4_audio_open_stream(&audio, 48000u, 2u, 2u, 0x10000u, poll_timeout(), &stream).kind != R4_AUDIO_RESULT_FAILED) return 2;
    timeout_next = 1; if (r4_audio_open_stream(&audio, 48000u, 2u, R4_AUDIO_FORMAT_S16LE, 0x10000u, poll_timeout(), &stream).kind != R4_AUDIO_RESULT_TIMED_OUT) return 3;
    if (r4_audio_open_stream(&audio, 48000u, 2u, R4_AUDIO_FORMAT_S16LE, 0x10000u, forever_timeout(), &stream).kind != R4_AUDIO_RESULT_OK) return 4;
    uint8_t pcm[2048]; memset(pcm, 1, sizeof(pcm)); R4AudioResult wrote = r4_audio_stream_write(&stream, pcm, sizeof(pcm), forever_timeout());
    if (wrote.kind != R4_AUDIO_RESULT_OK || wrote.bytes != sizeof(pcm)) return 5;
    if (r4_audio_stream_set_volume(&stream, 0x8000u, forever_timeout()).kind != R4_AUDIO_RESULT_OK) return 6;
    if (r4_audio_stream_close(&stream, forever_timeout()).kind != R4_AUDIO_RESULT_OK || r4_audio_stream_close(&stream, forever_timeout()).raw_code != R4OS_ERR_CLOSED || open_connections != 0u) return 7;
    R4AdvancedAudio advanced = r4_audio_advanced(audio);
    if (r4_audio_sid_acquire(&advanced) != 11 || r4_audio_sid_write_register(&advanced, 11u, 0u, 1u) != 0 || r4_audio_midi_open_synth(&advanced, (const uint8_t *)"OPL3") != 12 || r4_audio_midi_send(&advanced, 12u, 0u, 0x90u, 60u, 100u) != 0 || r4_audio_opl3_reset(&advanced) != 0) return 8;

    R4Devices devices = r4_app_devices(&app); if (!r4_devices_available(&devices)) return 9;
    R4DeviceInventoryView inventory = r4_devices_inventory(devices); R4DeviceInventorySummary inv; R4HardwareSummary hardware;
    if (r4_device_inventory_summary(&inventory, &inv) <= 0 || inv.total != 2u || r4_device_hardware_summary(&inventory, &hardware) <= 0 || hardware.cpu_logical_processors != 4u) return 10;
    R4MemoryView memory = r4_devices_memory(devices); R4ProgramMemorySummary mem;
    if (r4_memory_summary(&memory, &mem) != 0 || mem.physical_bytes != 64u * 1024u * 1024u || r4_memory_block_count(&memory) != 3u) return 11;
    R4PerformanceView performance = r4_devices_performance(devices); R4ProgramPerformanceSummary perf;
    if (r4_performance_summary(&performance, &perf) <= 0 || perf.audio_stream_writes != 9u) return 12;
    R4ProgramInstanceStorageSummary instance_storage; R4ProgramInstanceStorageSelfTestResult storage_test;
    if (r4_program_instance_storage_summary(&performance, &instance_storage) <= 0 || instance_storage.version != 2u || instance_storage.size != sizeof(instance_storage) || instance_storage.active_instances != 4u || instance_storage.current_payload_bytes != 4096u || instance_storage.current_gui_frame_bytes != 8192u) return 13;
    if (r4_program_instance_storage_self_test(&performance, &storage_test) <= 0 || storage_test.cases != 27u || storage_test.passed_cases != 27u || storage_test.flags != 0xFu || storage_test.allocation_failures_after <= storage_test.allocation_failures_before) return 14;
    R4ProgramInventorySummary execution;
    if (r4_execution_inventory_summary(&performance, &execution) != R4OS_PROGRAM_HANDLE_OK || execution.version != R4OS_PROGRAM_INVENTORY_VERSION || execution.program_total != 17u || execution.task_total != 29u || execution.thread_total != 23u) return 15;
    if (r4dev_execution_inventory_summary(&app.devices, &execution) != R4OS_PROGRAM_HANDLE_OK || execution.program_peak != 41u) return 16;
    memset(&instance_storage, 0xA5, sizeof(instance_storage));
    if (r4dev_program_instance_storage_summary_legacy(&app.devices, &instance_storage) <= 0 || instance_storage.version != 1u || instance_storage.size != 256u || ((uint8_t *)&instance_storage)[256] != 0xA5u) return 17;
    instance_storage.version = 3u; instance_storage.size = sizeof(instance_storage);
    if (r4dev_program_instance_storage_summary_v2(&app.devices, &instance_storage) <= 0 || instance_storage.version != 2u || instance_storage.size != sizeof(instance_storage)) return 18;
    memset(&instance_storage, 0xB6, sizeof(instance_storage)); instance_storage.version = 0u; instance_storage.size = sizeof(instance_storage) - 1u;
    if (r4dev_program_instance_storage_summary_v2(&app.devices, &instance_storage) != -1 || instance_storage.version != 0u || instance_storage.size != sizeof(instance_storage) - 1u || ((uint8_t *)&instance_storage)[8] != 0xB6u) return 19;
    raw_dev.size = 288u;
    if (r4_program_instance_storage_summary(&performance, &instance_storage) <= 0 || instance_storage.version != 1u || instance_storage.size != 256u || instance_storage.current_gui_frame_bytes != 0u) return 20;
    return 0;
}
