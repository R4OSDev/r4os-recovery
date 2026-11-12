#include <r4os/r4os.h>
#include <string.h>

static int timeout_next;
static int stream_open;
static uint32_t open_connections;
static R4Timeout forever_timeout(void);
static uint16_t reply_action;
static uint32_t reply_fault, reply_at, reply_calls, short_writes, write_calls, last_request_stream;
static void reply_mode(uint16_t action, uint32_t fault, uint32_t at) {
    reply_action=action;reply_fault=fault;reply_at=at;reply_calls=0u;write_calls=0u;
}

static int32_t fake_cpu_lifecycle(uint32_t operation, uint32_t cpu, uint64_t epoch, R4CpuLifecycleInfo *out) {
    if (operation != 2u || cpu != 63u || epoch != UINT64_C(0x1234567885abcdef)) return -99;
    out->epoch = epoch + 1u;
    return -63;
}
static int32_t fake_cpu_lifecycle_check(R4ProgramKernelCpuLifecycleCheck *out) {
    out->new_epoch = UINT64_C(0x1234567885abcdf0);
    return 1;
}
static int cpu_lifecycle_facade_probe(void) {
    R4XStartR4Dev table = {0};
    R4Dev dev = { &table };
    R4CpuLifecycleInfo info = {0}; info.epoch = 71u;
    R4ProgramKernelCpuLifecycleCheck check = {0}; check.new_epoch = 72u;
    table.cpu_lifecycle = (uintptr_t)&fake_cpu_lifecycle;
    table.kernel_cpu_lifecycle_check = (uintptr_t)&fake_cpu_lifecycle_check;
    for (uint32_t size = 552u; size < 560u; ++size) {
        table.size = size;
        if (r4dev_cpu_lifecycle(&dev, 2u, 63u, UINT64_C(0x1234567885abcdef), &info) != R4OS_ERR_NO_FN || info.epoch != 71u) return 1;
    }
    table.size = 560u;
    if (r4dev_cpu_lifecycle(&dev, 2u, 63u, UINT64_C(0x1234567885abcdef), &info) != -63 || info.epoch != UINT64_C(0x1234567885abcdf0)) return 2;
    if (r4dev_kernel_cpu_lifecycle_check(&dev, &check) != R4OS_ERR_NO_FN || check.new_epoch != 72u) return 3;
    table.size = 568u;
    if (r4dev_kernel_cpu_lifecycle_check(&dev, &check) != 1 || check.new_epoch != UINT64_C(0x1234567885abcdf0)) return 4;
    table.cpu_lifecycle = 0u; table.kernel_cpu_lifecycle_check = 0u;
    if (r4dev_cpu_lifecycle(&dev, 2u, 63u, UINT64_C(0x1234567885abcdef), &info) != R4OS_ERR_NO_FN || r4dev_kernel_cpu_lifecycle_check(&dev, &check) != R4OS_ERR_NO_FN) return 5;
    return 0;
}

#define CPU_CATALOG_EPOCH UINT64_C(0x1234567885abcdef)
static int32_t fake_cpu_capabilities(uint32_t cpu, R4CpuCapabilitiesInfo *out) {
    if (cpu != 63u) return -99; out->epoch = CPU_CATALOG_EPOCH; return 0;
}
static int32_t fake_cpu_feature(uint32_t cpu, uint64_t epoch, uint32_t index, R4CpuFeatureInfo *out) {
    if (cpu != 63u || epoch != CPU_CATALOG_EPOCH || index != 37u) return -99; out->epoch = epoch; return 0;
}
static int32_t fake_cpu_register(uint32_t cpu, uint64_t epoch, uint32_t id, R4CpuRegisterInfo *out) {
    if (cpu != 63u || epoch != CPU_CATALOG_EPOCH || id != 7u) return -99; out->value = epoch; return 0;
}
static int32_t fake_cpu_register_check(uint32_t cpu, uint64_t epoch, R4ProgramKernelCpuRegisterCheck *out) {
    if (cpu != 63u || epoch != CPU_CATALOG_EPOCH) return -99; out->epoch = epoch; return 0;
}
static int cpu_catalogue_facade_probe(void) {
    R4XStartR4Dev table = {0}; R4Dev dev = { &table };
    R4CpuCapabilitiesInfo cap = {0}; cap.epoch = 71;
    R4CpuFeatureInfo feature = {0}; feature.epoch = 72;
    R4CpuRegisterInfo reg = {0}; reg.value = 73;
    R4ProgramKernelCpuRegisterCheck report = {0}; report.epoch = 74;
    table.cpu_capabilities = (uintptr_t)&fake_cpu_capabilities;
    table.cpu_feature = (uintptr_t)&fake_cpu_feature;
    table.cpu_register_read = (uintptr_t)&fake_cpu_register;
    table.kernel_cpu_register_check = (uintptr_t)&fake_cpu_register_check;
    for (uint32_t size = 568; size < 576; ++size) { table.size = size;
        if (r4dev_cpu_capabilities(&dev, 63, &cap) != R4OS_ERR_NO_FN || cap.epoch != 71) return 1; }
    table.size = 576; if (r4dev_cpu_capabilities(&dev, 63, &cap) != 0 || cap.epoch != CPU_CATALOG_EPOCH) return 2;
    for (uint32_t size = 576; size < 584; ++size) { table.size = size;
        if (r4dev_cpu_feature(&dev, 63, CPU_CATALOG_EPOCH, 37, &feature) != R4OS_ERR_NO_FN || feature.epoch != 72) return 3; }
    table.size = 584; if (r4dev_cpu_feature(&dev, 63, CPU_CATALOG_EPOCH, 37, &feature) != 0 || feature.epoch != CPU_CATALOG_EPOCH) return 4;
    for (uint32_t size = 584; size < 592; ++size) { table.size = size;
        if (r4dev_cpu_register_read(&dev, 63, CPU_CATALOG_EPOCH, 7, &reg) != R4OS_ERR_NO_FN || reg.value != 73) return 5; }
    table.size = 592; if (r4dev_cpu_register_read(&dev, 63, CPU_CATALOG_EPOCH, 7, &reg) != 0 || reg.value != CPU_CATALOG_EPOCH) return 6;
    for (uint32_t size = 592; size < 600; ++size) { table.size = size;
        if (r4dev_kernel_cpu_register_check(&dev, 63, CPU_CATALOG_EPOCH, &report) != R4OS_ERR_NO_FN || report.epoch != 74) return 7; }
    table.size = 600; if (r4dev_kernel_cpu_register_check(&dev, 63, CPU_CATALOG_EPOCH, &report) != 0 || report.epoch != CPU_CATALOG_EPOCH) return 8;
    table.cpu_capabilities = table.cpu_feature = table.cpu_register_read = table.kernel_cpu_register_check = 0;
    if (r4dev_cpu_capabilities(&dev, 63, &cap) != R4OS_ERR_NO_FN || r4dev_cpu_feature(&dev, 63, CPU_CATALOG_EPOCH, 37, &feature) != R4OS_ERR_NO_FN ||
        r4dev_cpu_register_read(&dev, 63, CPU_CATALOG_EPOCH, 7, &reg) != R4OS_ERR_NO_FN || r4dev_kernel_cpu_register_check(&dev, 63, CPU_CATALOG_EPOCH, &report) != R4OS_ERR_NO_FN) return 9;
    return 0;
}

static int32_t fake_cpu_power(uint32_t cpu, uint64_t epoch, R4CpuPowerInfo *out) {
    if(cpu!=63 || epoch!=CPU_CATALOG_EPOCH) return -99;
    out->provider_generation=epoch; return -77;
}
static int cpu_power_facade_probe(void) {
    R4XStartR4Dev table={0}; R4Dev dev={&table}; R4CpuPowerInfo value={.provider_generation=71};
    table.cpu_power_info=(uintptr_t)&fake_cpu_power; table.cpu_power_capture=(uintptr_t)&fake_cpu_power;
    for(uint32_t size=600;size<608;size++){ table.size=size;
        if(r4dev_cpu_power_info(&dev,63,CPU_CATALOG_EPOCH,&value)!=R4OS_ERR_NO_FN || value.provider_generation!=71) return 1; }
    table.size=608;
    if(r4dev_cpu_power_info(&dev,63,CPU_CATALOG_EPOCH,&value)!=-77 || value.provider_generation!=CPU_CATALOG_EPOCH) return 2;
    for(uint32_t size=608;size<616;size++){ table.size=size;
        if(r4dev_cpu_power_capture(&dev,63,CPU_CATALOG_EPOCH,&value)!=R4OS_ERR_NO_FN || value.provider_generation!=CPU_CATALOG_EPOCH) return 3; }
    table.size=616;
    if(r4dev_cpu_power_capture(&dev,63,CPU_CATALOG_EPOCH,&value)!=-77) return 4;
    table.cpu_power_info=0; table.cpu_power_capture=0;
    if(r4dev_cpu_power_info(&dev,63,CPU_CATALOG_EPOCH,&value)!=R4OS_ERR_NO_FN ||
        r4dev_cpu_power_capture(&dev,63,CPU_CATALOG_EPOCH,&value)!=R4OS_ERR_NO_FN ||
        value.provider_generation!=CPU_CATALOG_EPOCH || r4dev_cpu_power_capture(&dev,63,CPU_CATALOG_EPOCH,0)!=R4OS_CPU_CAPABILITIES_ERROR_INVALID) return 5;
    return 0;
}

static int32_t fake_cpu_performance(const R4CpuPerformanceRequest *request,R4CpuPerformanceInfo *out){
    if(request->cpu_index!=63||request->epoch!=CPU_CATALOG_EPOCH)return -99;out->lease=request->epoch;return -96;
}
static int cpu_performance_facade_probe(void){
    R4XStartR4Dev table={.cpu_performance=(uintptr_t)&fake_cpu_performance};R4Dev dev={&table};R4CpuPerformanceRequest request={.cpu_index=63,.epoch=CPU_CATALOG_EPOCH};R4CpuPerformanceInfo out={.lease=71};
    for(uint32_t size=616;size<624;size++){table.size=size;if(r4dev_cpu_performance(&dev,&request,&out)!=R4OS_ERR_NO_FN||out.lease!=71)return 1;}
    table.size=624;if(r4dev_cpu_performance(&dev,&request,&out)!=-96||out.lease!=CPU_CATALOG_EPOCH)return 2;
    table.cpu_performance=0;if(r4dev_cpu_performance(&dev,&request,&out)!=R4OS_ERR_NO_FN||out.lease!=CPU_CATALOG_EPOCH)return 3;return 0;
}

static int32_t fake_cppc(const R4CpuPerformanceRequest *in,R4CpuCppcInfo *out){if(in->cpu_index!=63)return -99;out->lease=in->epoch;return -97;}
static int32_t fake_rank(uint32_t cpu,uint64_t epoch,R4CpuPerformanceHintInfo *out){if(cpu!=63)return -99;out->sequence=epoch;return -98;}
static int cppc_facade_probe(void){
    R4XStartR4Dev table={.cpu_cppc=(uintptr_t)&fake_cppc,.cpu_performance_hint=(uintptr_t)&fake_rank};R4Dev dev={&table};
    R4CpuPerformanceRequest in={.cpu_index=63,.epoch=CPU_CATALOG_EPOCH};R4CpuCppcInfo out={.lease=71};R4CpuPerformanceHintInfo rank={.sequence=72};
    for(uint32_t size=624;size<632;size++){table.size=size;if(r4dev_cpu_cppc(&dev,&in,&out)!=R4OS_ERR_NO_FN||out.lease!=71)return 1;}
    table.size=632;if(r4dev_cpu_cppc(&dev,&in,&out)!=-97||out.lease!=CPU_CATALOG_EPOCH)return 2;
    for(uint32_t size=624;size<640;size++){table.size=size;if(r4dev_cpu_performance_hint(&dev,63,in.epoch,&rank)!=R4OS_ERR_NO_FN||rank.sequence!=72)return 3;}
    table.size=640;if(r4dev_cpu_performance_hint(&dev,63,in.epoch,&rank)!=-98||rank.sequence!=in.epoch)return 4;
    table.cpu_cppc=0;table.cpu_performance_hint=0;if(r4dev_cpu_cppc(&dev,&in,&out)!=R4OS_ERR_NO_FN||r4dev_cpu_performance_hint(&dev,63,in.epoch,&rank)!=R4OS_ERR_NO_FN||out.lease!=in.epoch||rank.sequence!=in.epoch)return 5;
    return 0;
}

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
    if (op==reply_action) ++reply_calls;
    const int inject=op==reply_action && reply_fault && (!reply_at || reply_calls==reply_at);
    R4AudioWireResult result = {0}; result.magic = R4OS_AUDIO_SERVICE_RESULT_MAGIC; result.version = R4OS_AUDIO_SERVICE_RESULT_VERSION; result.action = op; result.stream_id = 91u;
    if (op == R4OS_AUDIO_SERVICE_OP_OPEN_STREAM) { stream_open = 1; result.result = 91; }
    else if (op == R4OS_AUDIO_SERVICE_OP_WRITE_STREAM) {
        ++write_calls;
        if (!stream_open || request_len < sizeof(R4AudioWireWriteRequest)) result.result = -1;
        else { R4AudioWireWriteRequest wire; memcpy(&wire, request, sizeof(wire)); last_request_stream=wire.stream_id; result.bytes=short_writes && wire.byte_count>4u?4u:wire.byte_count; result.result=(int32_t)result.bytes; }
    } else if (op == R4OS_AUDIO_SERVICE_OP_SET_STREAM_VOLUME) { if (!stream_open) result.result = -1; }
    else if (op == R4OS_AUDIO_SERVICE_OP_CLOSE_STREAM) { if (stream_open) { if(!inject)stream_open=0; } else result.result=-1; }
    if ((op==R4OS_AUDIO_SERVICE_OP_SET_STREAM_VOLUME || op==R4OS_AUDIO_SERVICE_OP_CLOSE_STREAM) && request_len==sizeof(R4AudioWireControlRequest)) {
        R4AudioWireControlRequest wire;memcpy(&wire,request,sizeof wire);last_request_stream=wire.stream_id;
    }
    if(inject)switch(reply_fault){
      case 1:++result.stream_id;break;
      case 2:++result.result;break;
      case 3:result.bytes+=4u;break;
      case 4:result.magic^=1u;break;
      case 5:++result.version;break;
      case 6:++result.action;break;
      case 7:case 8:break;
      case 9:result.result=0;break;
      case 10:result.stream_id=0u;break;
      case 11:result.result=R4OS_SERVICE_API_RESULT_BAD_HANDLE;break;
      case 12:result.result=R4OS_SERVICE_API_RESULT_BUSY;result.bytes=4u;break;
      case 13:result.result=0;result.bytes=0u;break;
      case 14:{R4AudioWireWriteRequest wire;memcpy(&wire,request,sizeof wire);result.bytes=wire.byte_count+4u;result.result=(int32_t)result.bytes;break;}
      case 15:result.bytes=3u;result.result=3;break;
      case 16:result.result=R4OS_SERVICE_API_RESULT_BAD_HANDLE;result.bytes=0u;if(op==R4OS_AUDIO_SERVICE_OP_OPEN_STREAM)result.stream_id=0u;break;
      default:return R4OS_SERVICE_API_RESULT_INVALID;
    }
    memcpy(response, &result, sizeof(result));
    return (int32_t)sizeof(result)+(inject?(reply_fault==7u?-1:reply_fault==8u?1:0):0);
}

static int strict_reply_probe(R4AudioFacade *audio) {
    static const uint32_t write_faults[]={1,2,3,4,5,6,7,8,12,13,14,15,16};
    uint8_t pcm[8192];memset(pcm,0x42,sizeof pcm);
    for(uint32_t shape=0u;shape<2u;++shape)for(uint32_t f=0u;f<sizeof write_faults/sizeof write_faults[0];++f){
        reply_mode(0u,0u,0u);short_writes=shape==0u;R4AudioStream stream;
        if(r4_audio_open_stream(audio,48000u,2u,R4_AUDIO_FORMAT_S16LE,0x10000u,forever_timeout(),&stream).kind!=R4_AUDIO_RESULT_OK)return 1;
        reply_mode(R4OS_AUDIO_SERVICE_OP_WRITE_STREAM,write_faults[f],2u);
        R4AudioResult result=r4_audio_stream_write(&stream,pcm,shape?8192u:16u,forever_timeout());
        const int32_t expected=write_faults[f]==16u?R4OS_SERVICE_API_RESULT_BAD_HANDLE:R4OS_SERVICE_API_RESULT_INVALID;
        if(result.kind!=R4_AUDIO_RESULT_FAILED || result.raw_code!=expected || result.bytes!=(shape?4076u:4u) || write_calls!=2u)return 2;
        if(!r4_audio_stream_valid(&stream) || stream.stream_id!=91u || !stream.owned || open_connections!=1u || last_request_stream!=91u)return 3;
        reply_mode(0u,0u,0u);if(r4_audio_stream_close(&stream,forever_timeout()).kind!=R4_AUDIO_RESULT_OK || open_connections)return 4;
    }
    const uint16_t operations[]={R4OS_AUDIO_SERVICE_OP_SET_STREAM_VOLUME,R4OS_AUDIO_SERVICE_OP_CLOSE_STREAM};
    for(uint32_t op=0u;op<2u;++op)for(uint32_t index=1u;index<=9u;++index){
        const uint32_t fault=index==9u?16u:index;
        reply_mode(0u,0u,0u);R4AudioStream stream;
        if(r4_audio_open_stream(audio,48000u,2u,R4_AUDIO_FORMAT_S16LE,0x10000u,forever_timeout(),&stream).kind!=R4_AUDIO_RESULT_OK)return 5;
        reply_mode(operations[op],fault,1u);
        R4AudioResult result=op?r4_audio_stream_close(&stream,forever_timeout()):r4_audio_stream_set_volume(&stream,0x8000u,forever_timeout());
        const int32_t expected=fault==7u || fault==8u?R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL:fault==16u?R4OS_SERVICE_API_RESULT_BAD_HANDLE:R4OS_SERVICE_API_RESULT_INVALID;
        if(result.kind!=R4_AUDIO_RESULT_FAILED || result.raw_code!=expected || !r4_audio_stream_valid(&stream) || stream.stream_id!=91u || open_connections!=1u || last_request_stream!=91u)return 6;
        reply_mode(0u,0u,0u);if(r4_audio_stream_close(&stream,forever_timeout()).kind!=R4_AUDIO_RESULT_OK || open_connections)return 7;
    }
    for(uint32_t fault=1u;fault<=11u;++fault){
        reply_mode(R4OS_AUDIO_SERVICE_OP_OPEN_STREAM,fault,1u);R4AudioStream stream;
        R4AudioResult result=r4_audio_open_stream(audio,48000u,2u,R4_AUDIO_FORMAT_S16LE,0x10000u,forever_timeout(),&stream);
        const int32_t expected=fault==7u || fault==8u?R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL:R4OS_SERVICE_API_RESULT_INVALID;
        if(result.kind!=R4_AUDIO_RESULT_FAILED || result.raw_code!=expected || r4_audio_stream_valid(&stream) || open_connections)return 8;
    }
    {reply_mode(R4OS_AUDIO_SERVICE_OP_OPEN_STREAM,16u,1u);R4AudioStream stream;
     R4AudioResult result=r4_audio_open_stream(audio,48000u,2u,R4_AUDIO_FORMAT_S16LE,0x10000u,forever_timeout(),&stream);
     if(result.kind!=R4_AUDIO_RESULT_FAILED || result.raw_code!=R4OS_SERVICE_API_RESULT_BAD_HANDLE || r4_audio_stream_valid(&stream) || open_connections)return 9;}
    reply_mode(0u,0u,0u);short_writes=0u;return 0;
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
static int32_t fake_program_instance_storage_v2(R4ProgramInstanceStorageSummary *out) { if (out->version < 2u || out->size < sizeof(*out)) return -1; *out = (R4ProgramInstanceStorageSummary){0}; out->version = 2u; out->size = sizeof(*out); out->active_instances = 4u; out->active_service_instances = 2u; out->current_payload_bytes = 4096u; out->payload_allocations = 11u; out->payload_releases = 7u; out->current_gui_frame_bytes = 8192u; return 1; }
static int32_t fake_program_instance_storage_self_test(R4ProgramInstanceStorageSelfTestResult *out) { *out = (R4ProgramInstanceStorageSelfTestResult){0}; out->version = 1u; out->size = sizeof(*out); out->cases = 27u; out->passed_cases = 27u; out->flags = 0xFu; out->allocation_failures_before = 2u; out->allocation_failures_after = 4u; return 1; }
static int32_t fake_execution_inventory(R4ProgramInventorySummary *out) { *out = (R4ProgramInventorySummary){0}; out->version = R4OS_PROGRAM_INVENTORY_VERSION; out->size = sizeof(*out); out->program_total = 17u; out->task_total = 29u; out->thread_total = 23u; out->program_peak = 41u; return R4OS_PROGRAM_HANDLE_OK; }
static int32_t fake_task(uint32_t index, R4ProgramTaskPerformanceInfo *out) { *out = (R4ProgramTaskPerformanceInfo){0}; out->id = index; return 1; }
static int32_t fake_storage(uint32_t index, R4ProgramStoragePerformanceInfo *out) { *out = (R4ProgramStoragePerformanceInfo){0}; out->index = index; return 1; }
static int32_t fake_boot(uint32_t index, R4ProgramBootPhasePerformanceInfo *out) { (void)index; *out = (R4ProgramBootPhasePerformanceInfo){0}; return 1; }
static int32_t fake_hardware(R4HardwareSummary *out) { *out = (R4HardwareSummary){0}; out->cpu_logical_processors = 4u; return 1; }
static int32_t fake_display_state(R4DisplayStateInfo *out) {
    if (out->version != 1u || out->size < sizeof(*out)) return -1;
    *out = (R4DisplayStateInfo){0}; out->version = 1u; out->size = sizeof(*out);
    out->device_generation = 7u; out->state = R4OS_DISPLAY_STATE_BOOTFB; out->policy = R4OS_DISPLAY_POLICY_SOFTWARE_ONCE;
    return 1;
}

static R4Timeout poll_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_POLL; return value; }
static R4Timeout forever_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FOREVER; return value; }

static int32_t fake_instrumentation(R4ProgramInstrumentationInfo *out) {
    if (out->version != 1u || out->size != sizeof(*out)) return -1;
    out->mode = 0u; out->lock_count = 11u; out->stack_group_count = 13u;
    return 1;
}
static int32_t fake_lock(uint32_t index, R4ProgramLockPerformanceInfo *out) {
    if (out->version != 1u || out->size != sizeof(*out)) return -1;
    if (index >= 11u) return 0;
    out->index = index; out->acquisitions = 17u;
    return 1;
}
static int32_t fake_stack(uint32_t index, R4ProgramStackPerformanceInfo *out) {
    if (out->version != 1u || out->size != sizeof(*out)) return -1;
    if (index >= 13u) return 0;
    out->index = index; out->created = 9u;
    return 1;
}

static int32_t fake_stack_fault(uint32_t index, R4ProgramStackFaultInfo *out) {
    if (out->version != 1u || out->size < sizeof(*out)) return -1;
    if (index >= 4u) return 0;
    *out = (R4ProgramStackFaultInfo){0}; out->version = 1u; out->size = sizeof(*out);
    out->cpu_index = index; out->sequence = 2u; out->flags = R4OS_STACK_FAULT_FLAG_TASK;
    out->task_id = 71u; out->task_generation = 93u;
    return 1;
}

static void init_app(R4App *app, R4XStartR4Sys *sys, R4XStartR4Audio *audio, R4XStartR4Dev *dev) {
    *sys = (R4XStartR4Sys){0}; sys->size=sizeof(*sys); sys->service_open = (uintptr_t)&fake_service_open; sys->service_close = (uintptr_t)&fake_service_close; sys->service_call = (uintptr_t)&fake_service_call;
    *audio = (R4XStartR4Audio){0}; audio->size=sizeof(*audio); audio->audio_open_stream = (uintptr_t)&fake_audio_open; audio->sid_acquire = (uintptr_t)&fake_sid_acquire; audio->sid_write_register = (uintptr_t)&fake_sid_write; audio->sid_release = (uintptr_t)&fake_sid_release; audio->midi_open_synth = (uintptr_t)&fake_midi_open; audio->midi_send = (uintptr_t)&fake_midi_send; audio->midi_close = (uintptr_t)&fake_midi_close; audio->opl3_write_register = (uintptr_t)&fake_opl_write; audio->opl3_reset = (uintptr_t)&fake_opl_simple; audio->opl3_render_block = (uintptr_t)&fake_opl_simple; audio->opl3_stop = (uintptr_t)&fake_opl_simple;
    *dev = (R4XStartR4Dev){0}; dev->size = R4XSTART_R4DEV_SIZE; dev->device_inventory_summary = (uintptr_t)&fake_inventory_summary; dev->device_inventory_record = (uintptr_t)&fake_inventory_record; dev->memory_summary = (uintptr_t)&fake_memory_summary; dev->memory_block_count = (uintptr_t)&fake_memory_count; dev->memory_block = (uintptr_t)&fake_memory_block; dev->memory_pressure_snapshot = (uintptr_t)&fake_pressure; dev->performance_summary = (uintptr_t)&fake_performance; dev->performance_task = (uintptr_t)&fake_task; dev->performance_storage = (uintptr_t)&fake_storage; dev->performance_boot_phase = (uintptr_t)&fake_boot; dev->hardware_summary = (uintptr_t)&fake_hardware; dev->program_instance_storage_summary_v2 = (uintptr_t)&fake_program_instance_storage_v2; dev->program_instance_storage_self_test = (uintptr_t)&fake_program_instance_storage_self_test; dev->execution_inventory_summary = (uintptr_t)&fake_execution_inventory;
    *app = (R4App){0}; app->system.table = sys; app->audio.table = audio; app->devices.table = dev;
    dev->display_state = (uintptr_t)&fake_display_state;
    /* The generated SIZE constant is the supported minimum prefix. This mock
       supplies the complete current provider, including the optional tail. */
    dev->size = sizeof(*dev);
}

static int32_t fake_output_catalog(R4AudioOutputInfo *rows, uint32_t capacity, R4AudioOutputCatalog *out) {
    if (capacity != 257u) return -1;
    rows[0].preferred_rate = 48000u;
    out->registry_generation = UINT64_C(0x1234567800000055);
    out->providers[0].registration = UINT64_C(0x2345678900000055);
    out->providers[0].generation = UINT64_C(0x3456789a00000055);
    return 1;
}
static int output_catalog_facade_probe(void) {
    R4XStartR4Audio table = {0}; R4Audio audio = { &table };
    R4AudioOutputInfo rows[257] = {0};
    R4AudioOutputCatalog receipt = {0}; receipt.registry_generation = 71u;
    table.audio_output_catalog = (uintptr_t)&fake_output_catalog;
    for (uint32_t size = 224u; size < 232u; ++size) {
        table.size = size;
        if (r4audio_output_catalog(&audio, rows, 257u, &receipt) != R4OS_ERR_NO_FN || receipt.registry_generation != 71u) return 1;
    }
    table.size = 232u;
    if (r4audio_output_catalog(&audio, rows, 257u, &receipt) != 1 || rows[0].preferred_rate != 48000u || rows[256].preferred_rate != 0u) return 2;
    if (receipt.registry_generation != UINT64_C(0x1234567800000055) || receipt.providers[0].registration != UINT64_C(0x2345678900000055) || receipt.providers[0].generation != UINT64_C(0x3456789a00000055)) return 3;
    table.audio_output_catalog = 0;
    if (r4audio_output_catalog(&audio, rows, 257u, &receipt) != R4OS_ERR_NO_FN) return 4;
    return 0;
}
int main(void) {
    if (output_catalog_facade_probe() != 0) return 55;
    if (cpu_lifecycle_facade_probe() != 0) return 63;
    if (cpu_catalogue_facade_probe() != 0) return 64;
    if (cpu_power_facade_probe() != 0) return 65;
    if (cpu_performance_facade_probe() != 0) return 66;
    if (cppc_facade_probe() != 0) return 67;
    R4App app; R4XStartR4Sys sys; R4XStartR4Audio raw_audio; R4XStartR4Dev raw_dev;
    init_app(&app, &sys, &raw_audio, &raw_dev); stream_open = 0; open_connections = 0u;
    R4AudioFacade audio = r4_app_audio(&app); R4AudioStream stream;
    /* Service-only audio deliberately has no direct R4AUDIO import. */
    app.audio.table = 0;
    if (!r4_audio_available(&audio)) return 1;
    if (r4_audio_open_stream(&audio,192001u,2u,R4_AUDIO_FORMAT_S16LE,0x10000u,forever_timeout(),&stream).raw_code!=R4OS_SERVICE_API_RESULT_INVALID) return 71;
    if (r4_audio_open_stream(&audio,48000u,3u,R4_AUDIO_FORMAT_S16LE,0x10000u,forever_timeout(),&stream).raw_code!=R4OS_SERVICE_API_RESULT_INVALID) return 72;
    R4AudioServiceMasterState master;
    if (r4_audio_master_status(&audio, forever_timeout(), &master).kind != R4_AUDIO_RESULT_OK || master.selected_volume_fixed != 0x8000u) return 21;
    if (r4_audio_set_master_state(&audio, R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_VOLUME | R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_MUTED, 0x8000u, 1, master.master_revision, forever_timeout(), &master).kind != R4_AUDIO_RESULT_OK || (master.flags & R4OS_AUDIO_MASTER_STATE_FLAG_MUTED) == 0u) return 22;
    if (r4_audio_open_stream(&audio, 48000u, 2u, 2u, 0x10000u, poll_timeout(), &stream).kind != R4_AUDIO_RESULT_FAILED) return 2;
    timeout_next = 1; if (r4_audio_open_stream(&audio, 48000u, 2u, R4_AUDIO_FORMAT_S16LE, 0x10000u, poll_timeout(), &stream).kind != R4_AUDIO_RESULT_TIMED_OUT) return 3;
    if (r4_audio_open_stream(&audio, 48000u, 2u, R4_AUDIO_FORMAT_S16LE, 0x10000u, forever_timeout(), &stream).kind != R4_AUDIO_RESULT_OK) return 4;
    uint8_t pcm[2048]; memset(pcm, 1, sizeof(pcm)); R4AudioResult wrote = r4_audio_stream_write(&stream, pcm, sizeof(pcm), forever_timeout());
    if (wrote.kind != R4_AUDIO_RESULT_OK || wrote.bytes != sizeof(pcm)) return 5;
    if(r4_audio_stream_write(&stream,pcm,3u,forever_timeout()).raw_code!=R4OS_SERVICE_API_RESULT_INVALID)return 73;
    uint8_t partial[4096]={0};
    R4AudioResult once=r4_audio_stream_write_once(&stream,partial,sizeof(partial),forever_timeout());
    if(once.kind!=R4_AUDIO_RESULT_BUSY || once.bytes!=4076u)return 74;
    if(r4_audio_stream_write(&stream,partial+once.bytes,sizeof(partial)-once.bytes,forever_timeout()).bytes!=20u)return 75;
    if (r4_audio_stream_set_volume(&stream, 0x8000u, forever_timeout()).kind != R4_AUDIO_RESULT_OK) return 6;
    if (r4_audio_stream_close(&stream, forever_timeout()).kind != R4_AUDIO_RESULT_OK || r4_audio_stream_close(&stream, forever_timeout()).raw_code != R4OS_ERR_CLOSED || open_connections != 0u) return 7;
    {int strict=strict_reply_probe(&audio);if(strict)return 80+strict;}
    R4AdvancedAudio advanced = r4_audio_advanced(audio);
    if (r4_audio_sid_acquire(&advanced) != R4OS_ERR_NO_FN) return 76;
    app.audio.table = &raw_audio;
    if (r4_audio_sid_acquire(&advanced) != 11 || r4_audio_sid_write_register(&advanced, 11u, 0u, 1u) != 0 || r4_audio_midi_open_synth(&advanced, (const uint8_t *)"OPL3") != 12 || r4_audio_midi_send(&advanced, 12u, 0u, 0x90u, 60u, 100u) != 0 || r4_audio_opl3_reset(&advanced) != 0) return 8;

    R4Devices devices = r4_app_devices(&app); if (!r4_devices_available(&devices)) return 9;
    R4DisplayStateInfo display_state;
    if (r4_devices_display(&devices, &display_state) != 1 || display_state.device_generation != 7u || display_state.policy != R4OS_DISPLAY_POLICY_SOFTWARE_ONCE) return 30;
    raw_dev.size = offsetof(R4XStartR4Dev, display_state);
    if (r4_devices_display(&devices, &display_state) != R4OS_ERR_NO_FN) return 31;
    raw_dev.size = sizeof(raw_dev);
    R4DeviceInventoryView inventory = r4_devices_inventory(devices); R4DeviceInventorySummary inv; R4HardwareSummary hardware;
    if (r4_device_inventory_summary(&inventory, &inv) <= 0 || inv.total != 2u || r4_device_hardware_summary(&inventory, &hardware) <= 0 || hardware.cpu_logical_processors != 4u) return 10;
    R4MemoryView memory = r4_devices_memory(devices); R4ProgramMemorySummary mem;
    if (r4_memory_summary(&memory, &mem) != 0 || mem.physical_bytes != 64u * 1024u * 1024u || r4_memory_block_count(&memory) != 3u) return 11;
    R4PerformanceView performance = r4_devices_performance(devices); R4ProgramPerformanceSummary perf;
    R4ProgramInstrumentationInfo instrumentation;
    R4ProgramLockPerformanceInfo lock;
    R4ProgramStackPerformanceInfo stack;
    if (r4_performance_instrumentation(&performance, &instrumentation) != R4OS_ERR_NO_FN) return 32;
    raw_dev.performance_instrumentation = (uintptr_t)&fake_instrumentation;
    raw_dev.performance_lock = (uintptr_t)&fake_lock;
    raw_dev.performance_stack = (uintptr_t)&fake_stack;
    if (r4_performance_instrumentation(&performance, &instrumentation) != 1 || instrumentation.mode != 0u) return 33;
    if (r4_performance_lock(&performance, 10u, &lock) != 1 || lock.acquisitions != 17u) return 34;
    if (r4_performance_stack(&performance, 12u, &stack) != 1 || stack.created != 9u) return 35;
    if (r4_performance_lock(&performance, 11u, &lock) != 0 || r4_performance_stack(&performance, 13u, &stack) != 0) return 36;
    raw_dev.size = offsetof(R4XStartR4Dev, performance_instrumentation);
    if (r4_performance_instrumentation(&performance, &instrumentation) != R4OS_ERR_NO_FN ||
        r4_performance_lock(&performance, 0u, &lock) != R4OS_ERR_NO_FN ||
        r4_performance_stack(&performance, 0u, &stack) != R4OS_ERR_NO_FN) return 37;
    raw_dev.size = sizeof(raw_dev);
    R4ProgramStackFaultInfo fault = {0}; fault.version = 1u; fault.size = sizeof(fault); fault.task_id = 123u;
    if (r4_performance_stack_fault(&performance, 0u, &fault) != R4OS_ERR_NO_FN || fault.task_id != 123u) return 38;
    raw_dev.stack_fault = (uintptr_t)&fake_stack_fault;
    if (r4_performance_stack_fault(&performance, 3u, &fault) != 1 || fault.task_id != 71u || fault.task_generation != 93u) return 39;
    if (r4_performance_stack_fault(&performance, 4u, &fault) != 0 || fault.task_id != 71u) return 40;
    fault.version = 0u;
    if (r4_performance_stack_fault(&performance, 0u, &fault) != -1 || fault.task_id != 71u) return 41;
    raw_dev.size = offsetof(R4XStartR4Dev, stack_fault);
    if (r4_performance_stack_fault(&performance, 0u, &fault) != R4OS_ERR_NO_FN || fault.task_id != 71u) return 42;
    raw_dev.size = sizeof(raw_dev);
    if (r4_performance_summary(&performance, &perf) <= 0 || perf.audio_stream_writes != 9u) return 12;
    R4ProgramInstanceStorageSummary instance_storage; R4ProgramInstanceStorageSelfTestResult storage_test;
    if (r4_program_instance_storage_summary(&performance, &instance_storage) <= 0 || instance_storage.version != 2u || instance_storage.size != sizeof(instance_storage) || instance_storage.active_instances != 4u || instance_storage.current_payload_bytes != 4096u || instance_storage.current_gui_frame_bytes != 8192u) return 13;
    if (r4_program_instance_storage_self_test(&performance, &storage_test) <= 0 || storage_test.cases != 27u || storage_test.passed_cases != 27u || storage_test.flags != 0xFu || storage_test.allocation_failures_after <= storage_test.allocation_failures_before) return 14;
    R4ProgramInventorySummary execution;
    if (r4_execution_inventory_summary(&performance, &execution) != R4OS_PROGRAM_HANDLE_OK || execution.version != R4OS_PROGRAM_INVENTORY_VERSION || execution.program_total != 17u || execution.task_total != 29u || execution.thread_total != 23u) return 15;
    if (r4dev_execution_inventory_summary(&app.devices, &execution) != R4OS_PROGRAM_HANDLE_OK || execution.program_peak != 41u) return 16;
    instance_storage.version = 3u; instance_storage.size = sizeof(instance_storage);
    if (r4dev_program_instance_storage_summary_v2(&app.devices, &instance_storage) <= 0 || instance_storage.version != 2u || instance_storage.size != sizeof(instance_storage)) return 18;
    memset(&instance_storage, 0xB6, sizeof(instance_storage)); instance_storage.version = 0u; instance_storage.size = sizeof(instance_storage) - 1u;
    if (r4dev_program_instance_storage_summary_v2(&app.devices, &instance_storage) != -1 || instance_storage.version != 0u || instance_storage.size != sizeof(instance_storage) - 1u || ((uint8_t *)&instance_storage)[8] != 0xB6u) return 19;
    raw_dev.size = 288u;
    if (r4_program_instance_storage_summary(&performance, &instance_storage) != R4OS_ERR_NO_FN) return 20;
    if (instance_storage.version != 0u || instance_storage.size != sizeof(instance_storage) - 1u || ((uint8_t *)&instance_storage)[8] != 0xB6u) return 43;
    return 0;
}
