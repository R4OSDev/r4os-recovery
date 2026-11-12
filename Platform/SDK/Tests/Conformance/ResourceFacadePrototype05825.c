#include <r4os/r4os.h>
#include <r4os/driver_resources.h>
#include <r4os/driver_heap.h>
#include <r4os/driver_threads.h>
#include <r4os/driver_semaphores.h>
#include <r4os/driver_display.h>

static uint32_t power_query_mode;
static int32_t power_register(const R4CpuPowerBackend *backend,uint64_t *cookie){*cookie=backend->context;return 0;}
static int32_t power_unregister(uint64_t cookie){return cookie==UINT64_C(0x1234567885abcdef)?-83:-99;}
static uint32_t power_current(void){return 63;}
static int32_t power_cap(uint32_t cpu,R4CpuCapabilitiesInfo *out){out->epoch=cpu;return -84;}
static int32_t power_topology(uint32_t cpu,R4CpuTopologyInfo *out){out->start_epoch=cpu;return -85;}
static int32_t power_read(uint32_t cpu,uint64_t epoch,uint32_t id,R4CpuRegisterInfo *out){if(cpu!=63||id!=17)return -99;out->value=epoch;return -86;}
static int32_t power_clock(R4MonotonicClockInfo *out){out->instant_ns=UINT64_C(0x1234567885abcdef);return 1;}
static int32_t power_pair(uint32_t cpu,uint64_t epoch,R4CpuPowerCounters *out){if(cpu!=63)return -99;out->aperf=epoch;out->mperf=epoch+1;return -88;}
static int32_t power_query(R4DriverCpuPowerApi *out){
    if(out->version!=1||out->size!=sizeof(R4DriverCpuPowerApi))return -99;
    *out=(R4DriverCpuPowerApi){.version=1,.size=72,.register_backend=(uintptr_t)&power_register,.unregister_backend=(uintptr_t)&power_unregister,
        .current_cpu=(uintptr_t)&power_current,.capabilities=(uintptr_t)&power_cap,.topology=(uintptr_t)&power_topology,
        .register_read=(uintptr_t)&power_read,.clock=(uintptr_t)&power_clock,.counters_read=(uintptr_t)&power_pair};
    if(power_query_mode==5)out->size=64;
    if(power_query_mode==1)out->version=2; if(power_query_mode==2)out->size=63; if(power_query_mode==3)out->clock=0;
    return power_query_mode==4?-87:0;
}
static int power_checks(void){
    R4DriverResourceApi resources={.version=1,.size=64,.cpu_power_query=(uintptr_t)&power_query};
    R4DriverCpuPowerApi ctx={.version=71};
    for(uint32_t size=56;size<64;size++){resources.size=size;
        if(r4driver_resource_cpu_power(&resources,&ctx)!=R4OS_ERR_NO_FN||ctx.version!=71)return 1;}
    resources.size=64;
    for(power_query_mode=1;power_query_mode<5;power_query_mode++){
        if(r4driver_resource_cpu_power(&resources,&ctx)>=0||ctx.version!=71)return 2;}
    power_query_mode=0;
    if(r4driver_resource_cpu_power(&resources,&ctx)!=0)return 3;
    uint64_t identity=UINT64_C(0x1234567885abcdef),cookie=71;
    R4CpuPowerBackend backend={.context=identity}; R4CpuCapabilitiesInfo cap={0}; R4CpuTopologyInfo topo={0};
    R4CpuRegisterInfo raw={0}; R4MonotonicClockInfo clock={0};
    if(r4driver_cpu_power_register(&ctx,&backend,&cookie)!=0||cookie!=identity||r4driver_cpu_power_unregister(&ctx,cookie)!=-83||r4driver_cpu_power_current(&ctx)!=63)return 4;
    if(r4driver_cpu_power_capabilities(&ctx,63,&cap)!=-84||cap.epoch!=63||r4driver_cpu_power_topology(&ctx,63,&topo)!=-85||topo.start_epoch!=63)return 5;
    if(r4driver_cpu_power_read(&ctx,63,identity,17,&raw)!=-86||raw.value!=identity||r4driver_cpu_power_clock(&ctx,&clock)!=1||clock.instant_ns!=identity)return 6;
    R4CpuPowerCounters pair={0};
    if(r4driver_cpu_power_counters(&ctx,63,identity,&pair)!=-88||pair.aperf!=identity||pair.mperf!=identity+1)return 8;
    for(uint32_t size=64;size<72;size++){ctx.size=size;if(r4driver_cpu_power_counters(&ctx,63,identity,&pair)!=R4OS_ERR_NO_FN||pair.aperf!=identity)return 9;}
    power_query_mode=5;
    if(r4driver_resource_cpu_power(&resources,&ctx)!=0||r4driver_cpu_power_current(&ctx)!=63||r4driver_cpu_power_counters(&ctx,63,identity,&pair)!=R4OS_ERR_NO_FN||pair.aperf!=identity)return 10;
    ctx=(R4DriverCpuPowerApi){.version=1,.size=64};
    if(r4driver_cpu_power_register(&ctx,&backend,&cookie)!=R4OS_ERR_NO_FN||cookie!=identity||r4driver_cpu_power_current(&ctx)!=R4OS_CPU_POWER_CPU_NONE||
        r4driver_cpu_power_unregister(&ctx,identity)!=R4OS_ERR_NO_FN||r4driver_cpu_power_capabilities(&ctx,63,&cap)!=R4OS_ERR_NO_FN||cap.epoch!=63||
        r4driver_cpu_power_topology(&ctx,63,&topo)!=R4OS_ERR_NO_FN||topo.start_epoch!=63||r4driver_cpu_power_read(&ctx,63,identity,17,&raw)!=R4OS_ERR_NO_FN||raw.value!=identity||
        r4driver_cpu_power_clock(&ctx,&clock)!=R4OS_ERR_NO_FN||clock.instant_ns!=identity||r4driver_cpu_power_counters(&ctx,63,identity,&pair)!=R4OS_ERR_NO_FN||pair.aperf!=identity)return 7;
    return 0;
}

static int32_t control_write(uint32_t cpu,uint64_t epoch,uint64_t token,uint32_t id,uint64_t expected,uint64_t requested,R4CpuRegisterWriteInfo *out){
    if(cpu!=63||epoch!=UINT64_C(0x1234567885abcdef)||token!=epoch||id!=20||expected!=epoch+1||requested!=epoch+2)return -99;
    out->observed_after=requested;return -95;
}
static int control_checks(void){
    uint64_t identity=UINT64_C(0x1234567885abcdef);R4CpuRegisterWriteInfo out={.observed_after=71};
    R4DriverCpuPowerApi table={.version=1,.size=112,.register_compare_write=(uintptr_t)&control_write};
    if(r4driver_cpu_power_compare_write(&table,63,identity,identity,20,identity+1,identity+2,&out)!=-95||out.observed_after!=identity+2)return 1;
    for(uint32_t size=72;size<112;size++){table.size=size;if(r4driver_cpu_power_compare_write(&table,63,identity,identity,20,identity+1,identity+2,&out)!=R4OS_ERR_NO_FN||out.observed_after!=identity+2)return 2;}
    table.size=112;table.register_compare_write=0;
    if(r4driver_cpu_power_compare_write(&table,63,identity,identity,20,identity+1,identity+2,&out)!=R4OS_ERR_NO_FN||out.observed_after!=identity+2)return 3;
    return 0;
}

static int32_t cppc_register(uint64_t cookie,const R4CpuCppcBackend *b){return cookie==b->context?-97:-99;}
static int32_t cppc_rank(const R4CpuPerformanceHint *in,uint64_t *seq){if(in->cpu_index!=63)return -99;*seq=in->epoch;return -98;}
static int cppc_checks(void){
    const uint64_t identity=UINT64_C(0x1234567885abcdef);R4CpuCppcBackend backend={.context=identity};R4CpuPerformanceHint in={.cpu_index=63,.epoch=identity};uint64_t sequence=71;
    R4DriverCpuPowerApi t={.version=1,.size=128,.register_cppc=(uintptr_t)&cppc_register,.rank_publish=(uintptr_t)&cppc_rank};
    for(uint32_t size=112;size<120;size++){t.size=size;if(r4driver_cpu_power_register_cppc(&t,identity,&backend)!=R4OS_ERR_NO_FN)return 1;}
    t.size=120;if(r4driver_cpu_power_register_cppc(&t,identity,&backend)!=-97)return 2;
    for(uint32_t size=112;size<128;size++){t.size=size;if(r4driver_cpu_power_rank_publish(&t,&in,&sequence)!=R4OS_ERR_NO_FN||sequence!=71)return 3;}
    t.size=128;if(r4driver_cpu_power_rank_publish(&t,&in,&sequence)!=-98||sequence!=identity)return 4;
    t.rank_publish=0;t.register_cppc=0;if(r4driver_cpu_power_rank_publish(&t,&in,&sequence)!=R4OS_ERR_NO_FN||sequence!=identity||r4driver_cpu_power_register_cppc(&t,identity,&backend)!=R4OS_ERR_NO_FN)return 5;
    return 0;
}

static uint64_t platform_root_probe(void) { return UINT64_C(0x100000080035); }
static int32_t platform_view_probe(uint64_t physical, uint64_t bytes, uint64_t *out) {
    if (physical != UINT64_C(0x100000080035) || bytes != 65536) return -1;
    *out = UINT64_C(0xffff800000080035); return 0;
}
static int32_t platform_input_probe(uint32_t kind, uint32_t value) { return kind == 3 && value == 2 ? 0 : -1; }
static int32_t platform_query_probe(R4DriverPlatformApi *out) {
    if(out->version != 1 || out->size != 32) return -1;
    *out = (R4DriverPlatformApi){.version=1,.size=32,.rsdp=(uintptr_t)&platform_root_probe,.physical_view=(uintptr_t)&platform_view_probe,.input_submit=(uintptr_t)&platform_input_probe}; return 0;
}
static int32_t platform_snapshot_probe(R4PlatformInputSnapshot *out) {
    if(out->version != 1 || out->size != 64) return -1;
    out->brightness_up = UINT64_C(0x200000080035); return 1;
}
static int platform_checks(void) {
    R4DriverResourceApi resource = {.version=1,.size=48,.platform_query=(uintptr_t)&platform_query_probe};
    R4DriverPlatformApi platform;
    if(r4driver_resource_platform(&resource,&platform) != R4OS_ERR_NO_FN) return 1;
    resource.size=55;
    if(r4driver_resource_platform(&resource,&platform) != R4OS_ERR_NO_FN) return 2;
    resource.size=56;
    if(r4driver_resource_platform(&resource,&platform) != 0 || r4driver_platform_rsdp(&platform) != UINT64_C(0x100000080035)) return 3;
    uint64_t view=0;
    if(r4driver_platform_view(&platform,UINT64_C(0x100000080035),65536,&view) != 0 || view != UINT64_C(0xffff800000080035) || r4driver_platform_input(&platform,3,2) != 0) return 4;
    R4XStartR4Sys table = {.size=1248,.platform_input_snapshot=(uintptr_t)&platform_snapshot_probe};
    R4Sys sys={.table=&table}; R4PlatformInputSnapshot snapshot;
    if(r4sys_platform_input_snapshot(&sys,&snapshot) != R4OS_ERR_NO_FN) return 5;
    table.size=1256;
    if(r4sys_platform_input_snapshot(&sys,&snapshot) != 1 || snapshot.brightness_up != UINT64_C(0x200000080035)) return 6;
    table.platform_input_snapshot=0;
    if(r4sys_platform_input_snapshot(&sys,&snapshot) != R4OS_ERR_NO_FN || r4sys_platform_input_snapshot(&sys,0) != R4OS_ERROR_INVALID) return 7;
    return 0;
}

static int32_t boot_hold_probe(const R4GfxBootHoldRequest *input, R4GfxNativeState *output) {
    if (input->generation != UINT64_C(0x100000000079) || input->reference.generation != UINT64_C(0x200000079)) return -77;
    output->generation = input->generation + 1; output->retained = 1; return R4OS_GFX_OUTPUT_OK;
}
static int32_t boot_finish_probe(uint64_t generation, uint32_t operation, R4GfxNativeState *output) {
    if (generation != UINT64_C(0x10000000007a) || operation != 2) return -77;
    output->outcome = R4OS_GFX_OUTPUT_OUTCOME_LOST; output->retained = 1; return R4OS_GFX_OUTPUT_OK;
}
static int32_t prepare_held_probe(const R4GfxNativeRegistration *input, uint64_t generation, R4GfxNativeState *output) {
    if (generation != UINT64_C(0x10000000007a) || input->context != UINT64_C(0x200000000079)) return -77;
    output->generation = generation; output->retained = 1; output->outcome = R4OS_GFX_OUTPUT_OUTCOME_VALIDATED;
    return R4OS_GFX_OUTPUT_OK;
}
static int32_t headless_resume_probe(const R4GfxBackendBinding *input, uint64_t generation, R4GfxNativeState *output) {
    if (input->adapter_id != 79 || generation != UINT64_C(0x10000000007a) || output->version != 1 || output->size != sizeof(*output)) return -77;
    output->generation = generation; output->retained = 1; output->state = R4OS_DISPLAY_STATE_RECOVERING;
    output->outcome = R4OS_GFX_OUTPUT_OUTCOME_LOST; return R4OS_GFX_OUTPUT_OK;
}
static int boot_display_checks(void) {
    _Static_assert(offsetof(R4GfxDriverDisplayApi, boot_hold) == 40, "old display prefix");
    _Static_assert(offsetof(R4GfxDriverDisplayApi, boot_finish) == 48, "finish offset");
    _Static_assert(offsetof(R4GfxDriverDisplayApi, prepare_held) == 56, "held native tail");
    _Static_assert(sizeof(R4GfxDriverDisplayApi) >= 64 && sizeof(R4GfxBootHoldRequest) == 56, "boot hold prefix and payload layout");
    R4GfxDriverDisplayApi table = { .version = 1, .size = 40, .boot_hold = (uint64_t)(uintptr_t)&boot_hold_probe, .boot_finish = (uint64_t)(uintptr_t)&boot_finish_probe, .prepare_held = (uint64_t)(uintptr_t)&prepare_held_probe };
    R4GfxBootHoldRequest request = { .version = 1, .size = sizeof(request), .generation = UINT64_C(0x100000000079), .reference = { .id = 7, .generation = UINT64_C(0x200000079) } };
    R4GfxNativeState state = { .version = 1, .size = sizeof(state), .generation = 79 };
    if (r4driver_display_boot_hold(&table, &request, &state) != R4OS_ERR_NO_FN || state.generation != 79) return 1;
    table.size = 48;
    if (r4driver_display_boot_hold(&table, &request, &state) != R4OS_GFX_OUTPUT_OK || state.generation != request.generation + 1) return 2;
    table.size = 55;
    if (r4driver_display_boot_finish(&table, state.generation, 2, &state) != R4OS_ERR_NO_FN) return 3;
    table.size = 56;
    if (r4driver_display_boot_finish(&table, state.generation, 2, &state) != R4OS_GFX_OUTPUT_OK || state.retained != 1 || state.outcome != R4OS_GFX_OUTPUT_OUTCOME_LOST) return 4;
    table.boot_finish = 0;
    if (r4driver_display_boot_finish(&table, state.generation, 2, &state) != R4OS_ERR_NO_FN) return 5;
    R4GfxNativeRegistration candidate = { .version = 1, .size = sizeof(candidate), .context = UINT64_C(0x200000000079) };
    if (r4driver_display_prepare_held(&table, &candidate, state.generation, &state) != R4OS_ERR_NO_FN || state.outcome != R4OS_GFX_OUTPUT_OUTCOME_LOST) return 6;
    table.size = 63;
    if (r4driver_display_prepare_held(&table, &candidate, state.generation, &state) != R4OS_ERR_NO_FN) return 7;
    table.size = 64;
    if (r4driver_display_prepare_held(&table, 0, state.generation, &state) != R4OS_GFX_OUTPUT_ERROR_INVALID ||
        r4driver_display_prepare_held(&table, &candidate, state.generation, 0) != R4OS_GFX_OUTPUT_ERROR_INVALID) return 10;
    if (r4driver_display_prepare_held(&table, &candidate, state.generation, &state) != R4OS_GFX_OUTPUT_OK || state.generation != UINT64_C(0x10000000007a) || state.outcome != R4OS_GFX_OUTPUT_OUTCOME_VALIDATED || state.retained != 1) return 8;
    table.prepare_held = 0;
    if (r4driver_display_prepare_held(&table, &candidate, state.generation, &state) != R4OS_ERR_NO_FN) return 9;
    _Static_assert(offsetof(R4GfxDriverDisplayApi, resume_headless) == 144, "headless resume tail");
    R4GfxBackendBinding backend = { .version = 1, .size = sizeof(backend), .adapter_id = 79 };
    if (r4driver_display_resume_headless(&table, &backend, state.generation, &state) != R4OS_ERR_NO_FN) return 11;
    table.resume_headless = (uint64_t)(uintptr_t)&headless_resume_probe;
    const uint32_t capacities[] = {40, 136, 144, 145, 151};
    for (unsigned i=0; i<sizeof(capacities)/sizeof(capacities[0]); ++i) {
        table.size = capacities[i];
        if (r4driver_display_supports_headless_resume(&table) ||
            r4driver_display_resume_headless(&table, &backend, state.generation, &state) != R4OS_ERR_NO_FN ||
            state.generation != UINT64_C(0x10000000007a)) return 12;
    }
    table.size = 152; table.version = 2;
    if (r4driver_display_resume_headless(&table, &backend, state.generation, &state) != R4OS_ERR_NO_FN) return 13;
    table.version = 1;
    if (r4driver_display_resume_headless(&table, 0, state.generation, &state) != R4OS_GFX_OUTPUT_ERROR_INVALID ||
        r4driver_display_resume_headless(&table, &backend, state.generation, 0) != R4OS_GFX_OUTPUT_ERROR_INVALID) return 14;
    if (!r4driver_display_supports_headless_resume(&table) ||
        r4driver_display_resume_headless(&table, &backend, state.generation, &state) != R4OS_GFX_OUTPUT_OK ||
        state.retained != 1 || state.state != R4OS_DISPLAY_STATE_RECOVERING || state.outcome != R4OS_GFX_OUTPUT_OUTCOME_LOST) return 15;
    table.resume_headless = 0;
    if (r4driver_display_resume_headless(&table, &backend, state.generation, &state) != R4OS_ERR_NO_FN) return 16;
    return 0;
}

static int32_t semaphore_create_probe(uint32_t initial, uint32_t maximum, uint64_t *output) {
    if (initial != UINT32_C(0x80000001) || maximum != UINT32_MAX || *output != 0) return -77;
    *output = UINT64_C(0x100000000079); return 0;
}
static int32_t semaphore_acquire_probe(uint64_t handle, uint64_t ticks) { return handle == UINT64_C(0x100000000079) && ticks == UINT64_MAX ? R4OS_DRIVER_SEMAPHORE_ERROR_TIMEOUT : -77; }
static int32_t semaphore_release_probe(uint64_t handle) { return handle == UINT64_C(0x100000000079) ? R4OS_DRIVER_SEMAPHORE_ERROR_OVERFLOW : -77; }
static int32_t semaphore_destroy_probe(uint64_t handle) { return handle == UINT64_C(0x100000000079) ? R4OS_DRIVER_SEMAPHORE_ERROR_BUSY : -77; }
static int32_t semaphore_status_probe(uint64_t handle, R4DriverSemaphoreStatus *output) {
    if (handle != UINT64_C(0x100000000079)) return -77;
    *output = (R4DriverSemaphoreStatus){ .version = 1, .size = sizeof(*output), .handle = handle, .owner_epoch = UINT64_C(0x200000000079), .maximum = UINT32_MAX, .queued_waiters = 3, .active_acquires = 4 }; return 0;
}
static int32_t semaphore_stats_probe(R4DriverSemaphoreStats *output) { *output = (R4DriverSemaphoreStats){ .version = 1, .size = sizeof(*output), .records = UINT64_C(0x300000000079), .closing = 1 }; return 0; }
static uint32_t semaphore_context_probe(void) { return R4OS_DRIVER_SEMAPHORE_CONTEXT_IRQ; }
static int semaphore_checks(void) {
    R4DriverSemaphoreApi api = { .version = 1, .size = sizeof(api), .create = (uint64_t)(uintptr_t)&semaphore_create_probe, .acquire = (uint64_t)(uintptr_t)&semaphore_acquire_probe, .release = (uint64_t)(uintptr_t)&semaphore_release_probe, .destroy = (uint64_t)(uintptr_t)&semaphore_destroy_probe, .status = (uint64_t)(uintptr_t)&semaphore_status_probe, .stats = (uint64_t)(uintptr_t)&semaphore_stats_probe, .context_flags = (uint64_t)(uintptr_t)&semaphore_context_probe };
    uint64_t handle = 79;
    if (r4driver_semaphore_create(&api, UINT32_C(0x80000001), UINT32_MAX, &handle) != 0 || handle != UINT64_C(0x100000000079)) return 1;
    if (r4driver_semaphore_acquire(&api, handle, UINT64_MAX) != R4OS_DRIVER_SEMAPHORE_ERROR_TIMEOUT || r4driver_semaphore_release(&api, handle) != R4OS_DRIVER_SEMAPHORE_ERROR_OVERFLOW || r4driver_semaphore_destroy(&api, handle) != R4OS_DRIVER_SEMAPHORE_ERROR_BUSY) return 2;
    R4DriverSemaphoreStatus status = {0}; R4DriverSemaphoreStats stats = {0};
    if (r4driver_semaphore_status(&api, handle, &status) != 0 || status.owner_epoch != UINT64_C(0x200000000079) || status.maximum != UINT32_MAX || r4driver_semaphore_stats(&api, &stats) != 0 || stats.records != UINT64_C(0x300000000079) || r4driver_semaphore_context_flags(&api) != R4OS_DRIVER_SEMAPHORE_CONTEXT_IRQ) return 3;
    if (r4driver_semaphore_create(&api, 0, 1, 0) != R4OS_DRIVER_SEMAPHORE_ERROR_INVALID || r4driver_semaphore_status(&api, handle, 0) != R4OS_DRIVER_SEMAPHORE_ERROR_INVALID || r4driver_semaphore_stats(&api, 0) != R4OS_DRIVER_SEMAPHORE_ERROR_INVALID) return 4;
    api.size = offsetof(R4DriverSemaphoreApi, destroy);
    if (r4driver_semaphore_destroy(&api, handle) != R4OS_ERR_NO_FN || r4driver_semaphore_context_flags(&api) != 0 || r4driver_semaphore_release(&api, handle) != R4OS_DRIVER_SEMAPHORE_ERROR_OVERFLOW) return 5;
    api.version = 2;
    if (r4driver_semaphore_create(&api, 0, 1, &handle) != R4OS_ERR_NO_FN || handle != 0) return 6;
    api = (R4DriverSemaphoreApi){ .version = 1, .size = sizeof(api) };
    if (r4driver_semaphore_acquire(&api, 1, 0) != R4OS_ERR_NO_FN || r4driver_semaphore_status(&api, 1, &status) != R4OS_ERR_NO_FN || r4driver_semaphore_stats(&api, &stats) != R4OS_ERR_NO_FN || r4driver_semaphore_release(0, 1) != R4OS_ERR_NO_FN) return 7;
    return 0;
}

static int32_t driver_thread_handler(uintptr_t value) { return value == UINT64_C(0x100000000037) ? 79 : -1; }
static int32_t driver_thread_start_probe(const R4DriverThreadRequest *input, uint64_t *output) {
    if (input->version != 1 || input->size != 32 || input->reserved != 0 || input->flags != R4OS_DRIVER_THREAD_FLAG_PARALLEL) return -77;
    if (((R4DriverThreadHandler)(uintptr_t)input->handler)(input->context) != 79) return -78;
    *output = UINT64_C(0x200000000079);
    return 0;
}
static int32_t driver_thread_join_probe(uint64_t handle, uint64_t timeout, int32_t *result) {
    return handle == UINT64_C(0x200000000079) && timeout == UINT64_C(0x300000000091) && *result == 0 ? R4OS_DRIVER_THREAD_ERROR_TIMEOUT : -77;
}
static int32_t driver_thread_stop_probe(uint64_t handle) { return handle == UINT64_C(0x200000000079) ? R4OS_DRIVER_THREAD_ERROR_CLOSED : -77; }
static int32_t driver_thread_release_probe(uint64_t handle) { return handle == UINT64_C(0x200000000079) ? R4OS_DRIVER_THREAD_ERROR_BUSY : -77; }
static int32_t driver_thread_status_probe(uint64_t handle, R4DriverThreadStatus *output) {
    if (handle != UINT64_C(0x200000000079)) return -77;
    *output = (R4DriverThreadStatus){ .version = 1, .size = sizeof(*output), .handle = handle, .task_generation = UINT64_C(0x200000000001), .result = -79 };
    return 0;
}
static uint64_t driver_thread_current_probe(void) { return UINT64_C(0x200000000079); }
static int32_t driver_thread_abort_probe(int32_t result) { return result == -76001 ? R4OS_DRIVER_THREAD_ERROR_BUSY : -77; }
static int32_t driver_thread_sleep_probe(uint64_t ticks) { return ticks == UINT64_MAX ? R4OS_DRIVER_THREAD_ERROR_CANCELLED : -77; }
static int32_t driver_thread_stats_probe(R4DriverThreadStats *output) {
    *output = (R4DriverThreadStats){ .version = 1, .size = sizeof(*output), .records = UINT64_C(0x100000000003), .closing = 1 };
    return 0;
}
static int32_t driver_thread_request_probe(R4DriverThreadRequest *output) {
    *output = (R4DriverThreadRequest){ .version = 1, .size = sizeof(*output), .handler = UINT64_C(0xffffc00000007900), .context = UINT64_C(0x200000000079), .flags = R4OS_DRIVER_THREAD_FLAG_ABORTABLE };
    return R4OS_DRIVER_THREAD_ERROR_CONTEXT;
}
static int driver_thread_checks(void) {
    R4DriverThreadApi api = { .version = 1, .size = sizeof(api), .start = (uint64_t)(uintptr_t)&driver_thread_start_probe, .stop = (uint64_t)(uintptr_t)&driver_thread_stop_probe, .join = (uint64_t)(uintptr_t)&driver_thread_join_probe, .release = (uint64_t)(uintptr_t)&driver_thread_release_probe, .status = (uint64_t)(uintptr_t)&driver_thread_status_probe, .current = (uint64_t)(uintptr_t)&driver_thread_current_probe, .sleep_ticks = (uint64_t)(uintptr_t)&driver_thread_sleep_probe, .stats = (uint64_t)(uintptr_t)&driver_thread_stats_probe };
    uint64_t handle = 99;
    int32_t result = 123;
    R4DriverThreadRequest request = {0};
    if (r4driver_thread_current_request(&api, &request) != R4OS_ERR_NO_FN) return 1;
    api.current_request = (uint64_t)(uintptr_t)&driver_thread_request_probe;
    const uint32_t capacities[] = {72, 80, 87};
    for (unsigned i = 0; i < sizeof(capacities) / sizeof(capacities[0]); ++i) {
        api.size = capacities[i];
        if (r4driver_thread_current_request(&api, &request) != R4OS_ERR_NO_FN || request.handler != 0) return 1;
    }
    api.size = 88;
    if (r4driver_thread_current_request(&api, &request) != R4OS_DRIVER_THREAD_ERROR_CONTEXT || request.handler != UINT64_C(0xffffc00000007900) || request.context != UINT64_C(0x200000000079) || request.flags != R4OS_DRIVER_THREAD_FLAG_ABORTABLE) return 1;
    if (r4driver_thread_current_request(&api, 0) != R4OS_DRIVER_THREAD_ERROR_INVALID || r4driver_thread_current_request(0, &request) != R4OS_ERR_NO_FN) return 1;
    if (r4driver_thread_abort_current(&api, -76001) != R4OS_ERR_NO_FN) return 1;
    api.abort_current = (uint64_t)(uintptr_t)&driver_thread_abort_probe;
    if (r4driver_thread_abort_current(&api, -76001) != R4OS_DRIVER_THREAD_ERROR_BUSY) return 1;
    api.size = R4OS_DRIVER_THREAD_API_MIN_BYTES;
    if (r4driver_thread_abort_current(&api, -76001) != R4OS_ERR_NO_FN) return 1;
    if (r4driver_thread_start(&api, driver_thread_handler, 0, R4OS_DRIVER_THREAD_FLAG_ABORTABLE, &handle) != R4OS_ERR_NO_FN || handle != 0) return 1;
    api.size = sizeof(api);
    R4DriverThreadStatus status = { .version = 1, .size = sizeof(status) };
    R4DriverThreadStats stats = { .version = 1, .size = sizeof(stats) };
    if (r4driver_thread_start(&api, driver_thread_handler, UINT64_C(0x100000000037), R4OS_DRIVER_THREAD_FLAG_PARALLEL, &handle) != 0 || handle != UINT64_C(0x200000000079)) return 1;
    if (r4driver_thread_join(&api, handle, UINT64_C(0x300000000091), &result) != R4OS_DRIVER_THREAD_ERROR_TIMEOUT || result != 0) return 1;
    if (r4driver_thread_stop(&api, handle) != R4OS_DRIVER_THREAD_ERROR_CLOSED || r4driver_thread_release(&api, handle) != R4OS_DRIVER_THREAD_ERROR_BUSY) return 1;
    if (r4driver_thread_status(&api, handle, &status) != 0 || status.task_generation != UINT64_C(0x200000000001) || status.result != -79) return 1;
    if (r4driver_thread_current(&api) != handle || r4driver_thread_sleep_ticks(&api, UINT64_MAX) != R4OS_DRIVER_THREAD_ERROR_CANCELLED) return 1;
    if (r4driver_thread_stats(&api, &stats) != 0 || stats.records != UINT64_C(0x100000000003)) return 1;
    if (r4driver_thread_start(&api, driver_thread_handler, 0, 0, 0) != R4OS_DRIVER_THREAD_ERROR_INVALID || r4driver_thread_join(&api, 1, 1, 0) != R4OS_DRIVER_THREAD_ERROR_INVALID) return 1;
    if (r4driver_thread_status(&api, 1, 0) != R4OS_DRIVER_THREAD_ERROR_INVALID || r4driver_thread_stats(&api, 0) != R4OS_DRIVER_THREAD_ERROR_INVALID) return 1;
    api.size = offsetof(R4DriverThreadApi, join);
    result = 123;
    if (r4driver_thread_join(&api, handle, 1, &result) != R4OS_ERR_NO_FN || result != 0 || r4driver_thread_release(&api, handle) != R4OS_ERR_NO_FN) return 1;
    api.version = 2;
    if (r4driver_thread_start(&api, driver_thread_handler, 0, 0, &handle) != R4OS_ERR_NO_FN || handle != 0 || r4driver_thread_current(&api) != 0) return 1;
    if (r4driver_thread_stop(0, 1) != R4OS_ERR_NO_FN || r4driver_thread_stats(0, &stats) != R4OS_ERR_NO_FN) return 1;
    return 0;
}

static int32_t driver_heap_allocate_probe(uint64_t bytes, uint32_t alignment, R4DriverHeapAllocation *out) {
    if (bytes != UINT64_C(0x100000001) || alignment != 4096) return -77;
    *out = (R4DriverHeapAllocation){ .version = 1, .size = sizeof(*out), .handle = UINT64_C(0x200000003), .cpu_address = UINT64_C(0xffffc00000001000), .byte_length = bytes, .alignment = alignment };
    return 0;
}
static int32_t driver_heap_release_probe(uint64_t handle) {
    return handle == UINT64_C(0x200000003) ? R4OS_DRIVER_HEAP_ERROR_RELEASE : -77;
}
static int driver_heap_checks(void) {
    R4DriverHeapApi api = { .version = 1, .size = sizeof(api), .allocate = (uint64_t)(uintptr_t)&driver_heap_allocate_probe, .release = (uint64_t)(uintptr_t)&driver_heap_release_probe };
    R4DriverHeapAllocation allocation = { .version = 1, .size = sizeof(allocation) };
    if (r4driver_heap_allocate(&api, UINT64_C(0x100000001), 4096, &allocation) != 0 || allocation.byte_length != UINT64_C(0x100000001) || allocation.cpu_address != UINT64_C(0xffffc00000001000)) return 1;
    if (r4driver_heap_release(&api, allocation.handle) != R4OS_DRIVER_HEAP_ERROR_RELEASE) return 1;
    if (r4driver_heap_stats(&api, 0) != R4OS_ERR_NO_FN) return 1;
    if (r4driver_heap_allocate(&api, 1, 16, 0) != R4OS_DRIVER_HEAP_ERROR_INVALID) return 1;
    api.size = offsetof(R4DriverHeapApi, release);
    if (r4driver_heap_release(&api, 1) != R4OS_ERR_NO_FN) return 1;
    api.version = 2;
    if (r4driver_heap_allocate(&api, 1, 16, &allocation) != R4OS_ERR_NO_FN || r4driver_heap_release(0, 1) != R4OS_ERR_NO_FN) return 1;
    return 0;
}

static int32_t driver_resource_probe(uint64_t handle, uint64_t offset, uint8_t *out, uint32_t bytes, uint64_t deadline) {
    if (handle != UINT64_C(0x100000001) || offset != UINT64_C(0x200000003) || deadline != UINT64_C(0x300000005) || bytes != 1) return -77;
    out[0] = 79;
    return 1;
}
static int driver_resource_checks(void) {
    uint8_t byte = 0;
    R4DriverResourceApi api = { .version = 1, .size = sizeof(api), .read_at = (uint64_t)(uintptr_t)&driver_resource_probe };
    if (r4driver_resource_read_at(&api, UINT64_C(0x100000001), UINT64_C(0x200000003), &byte, 1, UINT64_C(0x300000005)) != 1 || byte != 79) return 1;
    api.size = offsetof(R4DriverResourceApi, read_at);
    if (r4driver_resource_read_at(&api, 1, 0, &byte, 1, 10) != R4OS_ERR_NO_FN) return 1;
    if (r4driver_resource_stat(0, 0, 0, 0) != R4OS_ERR_NO_FN || r4driver_resource_now_ns(&api) != UINT64_MAX) return 1;
    return 0;
}

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

static int32_t current_identity_probe(R4ProgramJoinHandle *out) {
    *out = (R4ProgramJoinHandle){ .thread_id = 17, .instance_id = 31,
        .thread_generation = UINT64_C(0x10000007939), .instance_generation = UINT64_C(0x20000007939) };
    return R4OS_THREAD_OK;
}
static int current_identity_checks(void) {
    R4XStartR4Sys table = {0};
    R4Sys sys = { .table = &table };
    R4ProgramJoinHandle output = { .thread_generation = 79 };
    table.thread_current_handle = (uintptr_t)&current_identity_probe;
    const uint32_t short_sizes[] = {1224, 1231};
    for (unsigned i = 0; i < 2; ++i) {
        table.size = short_sizes[i];
        if (r4sys_thread_current_handle(&sys, &output) != R4OS_THREAD_ERROR_UNSUPPORTED || output.thread_generation != 79) return 1;
    }
    table.size = 1232; table.thread_current_handle = 0;
    if (r4sys_thread_current_handle(&sys, &output) != R4OS_THREAD_ERROR_UNSUPPORTED || output.thread_generation != 79) return 2;
    table.thread_current_handle = (uintptr_t)&current_identity_probe;
    if (r4sys_thread_current_handle(&sys, 0) != R4OS_THREAD_ERROR_INVALID) return 3;
    if (r4sys_thread_current_handle(&sys, &output) != R4OS_THREAD_OK || output.thread_id != 17 || output.instance_id != 31 ||
        output.thread_generation != UINT64_C(0x10000007939) || output.instance_generation != UINT64_C(0x20000007939) || output.reserved != 0) return 4;
    return 0;
}

static int32_t cpu_capacity_probe(R4CpuCapacity *output) {
    *output = (R4CpuCapacity){ .available_cpus = 3, .configured_cpus = 4 };
    return R4OS_THREAD_OK;
}
static int cpu_capacity_checks(void) {
    R4XStartR4Sys table = {0};
    R4Sys sys = { .table = &table };
    R4CpuCapacity output = { .available_cpus = 79 };
    table.cpu_capacity = (uintptr_t)&cpu_capacity_probe;
    const uint32_t short_sizes[] = {1232, 1239};
    for (unsigned i = 0; i < 2; ++i) {
        table.size = short_sizes[i];
        if (r4sys_cpu_capacity(&sys, &output) != R4OS_THREAD_ERROR_UNSUPPORTED || output.available_cpus != 79) return 1;
    }
    table.size = 1240; table.cpu_capacity = 0;
    if (r4sys_cpu_capacity(&sys, &output) != R4OS_THREAD_ERROR_UNSUPPORTED || output.available_cpus != 79) return 2;
    table.cpu_capacity = (uintptr_t)&cpu_capacity_probe;
    if (r4sys_cpu_capacity(&sys, 0) != R4OS_THREAD_ERROR_INVALID) return 3;
    if (r4sys_cpu_capacity(&sys, &output) != R4OS_THREAD_OK || output.available_cpus != 3 || output.configured_cpus != 4) return 4;
    return 0;
}

static unsigned placement_calls;
static int32_t placement_get_probe(const R4ProgramJoinHandle *handle, R4ThreadPlacementInfo *info, uint64_t *cpus, uint32_t count) {
    if (handle->thread_generation != UINT64_C(0x10000007939)) return -99;
    ++placement_calls; info->cpu_word_count = 2;
    if (count) { if (count != 3) return -99; cpus[0] = 1; cpus[1] = UINT64_C(1) << 13; }
    return 37;
}
static int32_t placement_set_probe(const R4ProgramJoinHandle *handle, const R4ThreadPlacementRequest *request, const uint64_t *cpus, uint32_t count) {
    if (handle->thread_generation != UINT64_C(0x10000007939) || request->work_class != R4OS_THREAD_PLACEMENT_CLASS_BATCH || count != 2 || cpus[1] != (UINT64_C(1) << 13)) return -99;
    ++placement_calls; return 41;
}
static int placement_checks(void) {
    R4XStartR4Sys table = {0}; R4Sys sys = {.table = &table};
    R4ProgramJoinHandle handle = {.thread_generation = UINT64_C(0x10000007939)};
    R4ThreadPlacementInfo info = {.version = 1, .size = 64};
    R4ThreadPlacementRequest request = {.version = 1, .size = 32, .work_class = R4OS_THREAD_PLACEMENT_CLASS_BATCH};
    uint64_t words[3] = {79,79,79}; placement_calls = 0;
    table.thread_placement_get = (uintptr_t)&placement_get_probe;
    table.thread_placement_set = (uintptr_t)&placement_set_probe;
    table.size = 1271;
    if (r4sys_thread_placement_get(&sys,&handle,&info,words,3) != R4OS_THREAD_ERROR_UNSUPPORTED) return 1;
    table.size = 1279;
    if (r4sys_thread_placement_set(&sys,&handle,&request,words,2) != R4OS_THREAD_ERROR_UNSUPPORTED) return 2;
    table.size = 1280; table.thread_placement_get = 0; table.thread_placement_set = 0;
    if (r4sys_thread_placement_get(&sys,&handle,&info,words,3) != R4OS_THREAD_ERROR_UNSUPPORTED || r4sys_thread_placement_set(&sys,&handle,&request,words,2) != R4OS_THREAD_ERROR_UNSUPPORTED || placement_calls || words[0] != 79) return 3;
    table.thread_placement_get = (uintptr_t)&placement_get_probe; table.thread_placement_set = (uintptr_t)&placement_set_probe;
    if (r4sys_thread_placement_get(&sys,&handle,&info,0,0) != 37 || info.cpu_word_count != 2) return 4;
    if (r4sys_thread_placement_get(&sys,&handle,&info,words,3) != 37 || words[0] != 1 || words[1] != (UINT64_C(1)<<13) || words[2] != 79) return 5;
    if (r4sys_thread_placement_set(&sys,&handle,&request,words,2) != 41 || placement_calls != 3) return 6;
    return 0;
}

static int32_t program_exit_probe(int32_t code, uint32_t reason) {
    return code == -73 && reason == R4OS_PROGRAM_EXIT_REASON_FAILED ? R4OS_THREAD_ERROR_BUSY : R4OS_THREAD_ERROR_INVALID;
}
static int program_exit_checks(void) {
    R4XStartR4Sys table = {0};
    R4Sys sys = { .table = &table };
    table.program_exit = (uintptr_t)&program_exit_probe;
    const uint32_t short_sizes[] = {1240, 1247};
    for (unsigned i = 0; i < 2; ++i) {
        table.size = short_sizes[i];
        if (r4sys_program_exit(&sys, -73, R4OS_PROGRAM_EXIT_REASON_FAILED) != R4OS_THREAD_ERROR_UNSUPPORTED) return 1;
    }
    table.size = 1248; table.program_exit = 0;
    if (r4sys_program_exit(&sys, -73, R4OS_PROGRAM_EXIT_REASON_FAILED) != R4OS_THREAD_ERROR_UNSUPPORTED) return 2;
    table.program_exit = (uintptr_t)&program_exit_probe;
    if (r4sys_program_exit(&sys, -73, R4OS_PROGRAM_EXIT_REASON_FAILED) != R4OS_THREAD_ERROR_BUSY) return 3;
    return 0;
}

static int32_t compute_create_probe(R4ThreadEntryFn entry, uint64_t arg, uint64_t stack, uint32_t flags, R4ProgramJoinHandle *out) {
    if (flags != R4OS_THREAD_CREATE_FLAG_COMPUTE_WORKER || arg != 85u || stack != 262144u) return -99;
    return fake_thread_create_handle(entry, arg, stack, 0u, out);
}

static int app_resource_checks(void) {
    R4App app; R4XStartR4Sys table; R4XStartR4Desk desk; init_app(&app, &table, &desk); R4Resources resources = r4_app_resources(&app);
    R4ProgramJoinHandle refused = {0};
    if (r4sys_compute_worker_create(&app.system, unused_thread, 85u, 262144u, &refused) != R4OS_THREAD_ERROR_UNSUPPORTED || refused.thread_id != 0u) return 88;
    table.thread_create_handle = (uintptr_t)&compute_create_probe;
    R4JoinHandle compute;
    if (r4_resources_create_compute_worker(&resources, unused_thread, 85u, 262144u, &compute) != 0) return 88;
    R4ResourceWait compute_result = r4_join_wait(&compute, forever_timeout());
    if (compute_result.kind != R4_RESOURCE_WAIT_EXITED || compute_result.value != 85 || r4_join_handle_valid(&compute)) return 88;
    table.thread_create_handle = (uintptr_t)&fake_thread_create_handle;
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

static unsigned registry_v2_calls;
static int32_t registry_summary_v2_peer(R4ProgramRegistrySummaryV2 *out) {
    if(out->version<2 || out->size<sizeof(*out)) return -1;
    ++registry_v2_calls;out->live_slots=7;return 1;
}
static int32_t registry_test_v2_peer(R4ProgramRegistrySelfTestResultV2 *out) {
    if(out->version<2 || out->size<sizeof(*out)) return -1;
    ++registry_v2_calls;out->flags=17;return 1;
}
int main(void) {
    if (platform_checks()) return 100;
    if (program_exit_checks() != 0) return 86;
    if (placement_checks() != 0) return 87;
    if (cpu_capacity_checks() != 0) return 85;
    if (current_identity_checks() != 0) return 84;
    if (boot_display_checks() != 0) return 83;
    if (semaphore_checks() != 0) return 82;
    if (driver_heap_checks() != 0) return 80;
    if (driver_thread_checks() != 0) return 81;
    if (driver_resource_checks() != 0) return 79;
    if (power_checks() != 0) return 89;
    if (control_checks() != 0) return 90;
    if (cppc_checks() != 0) return 91;
    R4App app; R4XStartR4Sys table; R4XStartR4Desk desk; init_app(&app, &table, &desk);
    R4PerformanceView performance = r4_devices_performance(r4_app_devices(&app));
    R4ProgramRegistrySummaryV2 registry_v2 = {0}; R4ProgramRegistrySelfTestResultV2 registry_test_v2 = {0};
    if (r4_program_registry_summary_v2(&performance, &registry_v2) != R4OS_ERR_NO_FN || r4_program_registry_self_test_v2(&performance, &registry_test_v2) != R4OS_ERR_NO_FN) return 32;
    R4XStartR4Dev current_dev={.size=sizeof(current_dev),.program_registry_summary_v2=(uintptr_t)registry_summary_v2_peer,.program_registry_self_test_v2=(uintptr_t)registry_test_v2_peer};
    app.devices.table=&current_dev;
    registry_v2.version=2;registry_v2.size=sizeof(registry_v2);
    registry_test_v2.version=2;registry_test_v2.size=sizeof(registry_test_v2);
    current_dev.size=offsetof(R4XStartR4Dev,program_registry_summary_v2);
    if(r4_program_registry_summary_v2(&performance,&registry_v2)!=R4OS_ERR_NO_FN || registry_v2_calls) return 92;
    current_dev.size=sizeof(current_dev);
    if(r4_program_registry_summary_v2(&performance,&registry_v2)!=1 || registry_v2.live_slots!=7) return 93;
    if(r4_program_registry_self_test_v2(&performance,&registry_test_v2)!=1 || registry_test_v2.flags!=17 || registry_v2_calls!=2) return 94;
    return app_resource_checks();
}
