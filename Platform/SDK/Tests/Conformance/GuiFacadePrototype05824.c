#include <assert.h>
#include <stdint.h>

#include <r4os/r4os.h>
#include <r4os/driver_memory.h>
#include <r4os/driver_queue.h>
#include <r4os/driver_outputs.h>
#include <string.h>
#include <r4os/driver_display.h>

_Static_assert(sizeof(R4Message) == 48 && sizeof(R4MessageNext) == 56, "existing C message layout");
_Static_assert(sizeof(R4FocusMessage) == 16 && offsetof(R4FocusMessage, tick) == 8, "focus payload");
_Static_assert(sizeof(R4FontChangedMessage) == 16 && offsetof(R4FontChangedMessage, tick) == 8, "font notification payload");

_Static_assert(sizeof(R4GfxReceiverSource) == 16, "receiver source layout");
_Static_assert(sizeof(R4GfxReceiverInfo) == 8224 && offsetof(R4GfxReceiverInfo, modes) == 32 && offsetof(R4GfxReceiverInfo, edid) == 4128, "receiver record layout");
_Static_assert(sizeof(R4GfxReceiverUpdate) == 48 && offsetof(R4GfxReceiverUpdate, receivers) == 40, "receiver update layout");
_Static_assert(sizeof(R4GfxDriverOutputApi) == 176 && offsetof(R4GfxDriverOutputApi, register_source) == 24 && offsetof(R4GfxDriverOutputApi, mode_enable) == 48 && offsetof(R4GfxDriverOutputApi, audio_publish) == 72 && offsetof(R4GfxDriverOutputApi, output_pause) == 88 && offsetof(R4GfxDriverOutputApi, mode_restore) == 96 && offsetof(R4GfxDriverOutputApi, mode_status) == 104 && offsetof(R4GfxDriverOutputApi, color_publish) == 112 && offsetof(R4GfxDriverOutputApi, mode_read_color) == 120 && offsetof(R4GfxDriverOutputApi, refresh_publish) == 128 && offsetof(R4GfxDriverOutputApi, refresh_read) == 136 && offsetof(R4GfxDriverOutputApi, power_publish) == 144 && offsetof(R4GfxDriverOutputApi, power_read) == 152, "legacy output prefix and optional tails");
_Static_assert(sizeof(R4GfxOutputPower) == 96 && sizeof(R4GfxPowerRequest) == 64, "screen power payloads");
_Static_assert(sizeof(R4GfxOutputColorState) == 192 && offsetof(R4GfxOutputColorState, revision) == 32 && offsetof(R4GfxOutputColorState, max_tmds_clock_hz) == 112 && offsetof(R4GfxOutputColorState, link_kind) == 128, "output color compatible prefix and link tail");

static int32_t capture_acquire_probe(uint32_t expected, R4RemoteFrameInfo *info, R4RemoteFrameLease *lease) {
    assert(expected == 73); info->revision = expected;
    *lease = (R4RemoteFrameLease){.version=1,.size=48,.id=UINT64_C(0x100000003),.epoch=UINT64_C(0x200000009)}; return 0;
}
static int32_t capture_release_probe(const R4RemoteFrameLease *lease) {
    assert(lease->id == UINT64_C(0x100000003) && lease->epoch == UINT64_C(0x200000009)); return 0;
}
static int32_t capture_reset_probe(void) { return 0; }
static int32_t capture_stats_probe(R4RemoteFrameCaptureStats *out) { out->snapshot_copy_bytes=UINT64_C(0x300000007); return 0; }
static void capture_facade_probe(void) {
    R4XStartR4Desk table = {.size=496,.remote_frame_snapshot_acquire=(uintptr_t)capture_acquire_probe,
        .remote_frame_snapshot_release=(uintptr_t)capture_release_probe,.remote_frame_source_reset=(uintptr_t)capture_reset_probe,
        .remote_frame_capture_stats=(uintptr_t)capture_stats_probe};
    R4Desk desk={.table=&table}; R4RemoteFrameInfo info={.revision=17}; R4RemoteFrameLease lease={.id=19};
    R4RemoteFrameCaptureStats stats={.snapshot_copy_bytes=23};
    assert(r4desk_remote_frame_snapshot_acquire(&desk,73,&info,&lease)==R4OS_ERR_NO_FN && info.revision==17 && lease.id==19);
    assert(r4desk_remote_frame_snapshot_release(&desk,&lease)==R4OS_ERR_NO_FN);
    assert(r4desk_remote_frame_source_reset(&desk)==R4OS_ERR_NO_FN);
    assert(r4desk_remote_frame_capture_stats(&desk,&stats)==R4OS_ERR_NO_FN && stats.snapshot_copy_bytes==23);
    table.size=sizeof(table);
    assert(r4desk_remote_frame_snapshot_acquire(&desk,73,&info,&lease)==0 && info.revision==73);
    assert(r4desk_remote_frame_snapshot_release(&desk,&lease)==0);
    assert(r4desk_remote_frame_source_reset(&desk)==0);
    assert(r4desk_remote_frame_capture_stats(&desk,&stats)==0 && stats.snapshot_copy_bytes==UINT64_C(0x300000007));
}

static int32_t cursor_info_probe(R4DisplayCursorInfo *out) {
    assert(out->version == 1 && out->size == 80); out->display_generation = UINT64_C(0x100000079); return 1;
}
static int32_t cursor_status_probe(R4DisplayCursorStatus *out) {
    assert(out->version == 1 && out->size == 72); out->completed = UINT64_C(0x200000079); return 1;
}
static int32_t cursor_submit_probe(const R4DisplayCursorRequest *in, R4DisplayCursorStatus *out) {
    assert(in->display_generation == UINT64_C(0x100000079) && in->image_sequence == UINT64_C(0x300000079) && in->x == -17);
    return cursor_status_probe(out);
}
static int32_t cursor_configure_probe(const R4DisplayCursorInfo *in) {
    assert(in->display_generation == UINT64_C(0x100000079)); return 1;
}
static int32_t cursor_take_probe(const R4GfxBackendBinding *in, R4GfxDriverCursorJob *out) {
    assert(in->reset_generation == UINT64_C(0x400000079) && out->version == 1 && out->size == 160);
    out->sequence = UINT64_C(0x200000079); out->barrier_point = UINT64_C(0x500000079); return 1;
}
static int32_t cursor_complete_probe(const R4GfxDriverCursorCompletion *in) {
    assert(in->sequence == UINT64_C(0x200000079) && in->display_generation == UINT64_C(0x100000079)); return -4;
}
static void cursor_facade_probe(void) {
    R4XStartR4Draw table = {.size=sizeof(table),.display_cursor_info=(uintptr_t)cursor_info_probe,
        .display_cursor_submit=(uintptr_t)cursor_submit_probe,.display_cursor_status=(uintptr_t)cursor_status_probe};
    R4Draw draw = {.table=&table};
    R4DisplayCursorInfo info = {0}; R4DisplayCursorStatus status = {.completed=79};
    R4DisplayCursorRequest request = {.display_generation=UINT64_C(0x100000079),.image_sequence=UINT64_C(0x300000079),.x=-17};
    for (unsigned size=616; size<640; ++size) {
        table.size=size; assert(!r4draw_supports_display_cursor(&draw));
        assert(r4draw_display_cursor_info(&draw,&info)==R4OS_ERR_NO_FN);
        assert(r4draw_display_cursor_submit(&draw,&request,&status)==R4OS_ERR_NO_FN);
        assert(r4draw_display_cursor_status(&draw,&status)==R4OS_ERR_NO_FN);
        assert(info.display_generation==0 && status.completed==79);
    }
    table.size=640;
    assert(r4draw_display_cursor_info(&draw,&info)==1);
    assert(r4draw_display_cursor_submit(&draw,&request,&status)==1);
    assert(r4draw_display_cursor_status(&draw,&status)==1);
    R4GfxDriverDisplayApi driver = {.version=1,.size=96,.cursor_configure=(uintptr_t)cursor_configure_probe,
        .cursor_take=(uintptr_t)cursor_take_probe,.cursor_complete=(uintptr_t)cursor_complete_probe};
    R4GfxDriverCursorJob job={0}; R4GfxBackendBinding binding={.reset_generation=UINT64_C(0x400000079)};
    R4GfxDriverCursorCompletion receipt={.sequence=UINT64_C(0x200000079),.display_generation=UINT64_C(0x100000079)};
    for (unsigned size=72; size<96; ++size) {
        driver.size=size; assert(!r4driver_display_supports_cursor(&driver));
        assert(r4driver_display_cursor_configure(&driver,&info)==R4OS_ERR_NO_FN);
        assert(r4driver_display_cursor_take(&driver,&binding,&job)==R4OS_ERR_NO_FN);
        assert(r4driver_display_cursor_complete(&driver,&receipt)==R4OS_ERR_NO_FN && job.sequence==0);
    }
    driver.size=96;
    assert(r4driver_display_cursor_configure(&driver,&info)==1);
    assert(r4driver_display_cursor_take(&driver,&binding,&job)==1 && job.sequence==UINT64_C(0x200000079) && job.barrier_point==UINT64_C(0x500000079));
    assert(r4driver_display_cursor_complete(&driver,&receipt)==R4OS_GFX_OUTPUT_ERROR_BUSY);
}

static int32_t display_transition_probe(uint64_t generation, uint32_t operation, R4GfxNativeState *output) {
    assert(generation == UINT64_C(0x100000007) && operation == 2);
    output->generation = generation + 1; output->outcome = 3; output->retained = 1; return 1;
}
static int32_t display_schedule_probe(const R4GfxBackendBinding *binding) {
    assert(binding->reset_generation == UINT64_C(0x30000000b)); return -4;
}
static int32_t display_device_reset_probe(const R4GfxBackendBinding *binding, uint64_t generation, uint32_t quiesced, R4GfxNativeState *output) {
    assert(binding->reset_generation == UINT64_C(0x30000000b) && generation == UINT64_C(0x100000007) && quiesced <= 1);
    assert(output->version == 1 && output->size == sizeof(*output));
    if (quiesced) return R4OS_GFX_OUTPUT_ERROR_BUSY;
    *output = (R4GfxNativeState){.version=1,.size=sizeof(*output),.generation=generation+1,.outcome=R4OS_GFX_OUTPUT_OUTCOME_LOST,.retained=1};
    return R4OS_GFX_OUTPUT_OK;
}
static int32_t display_prepare_reset_probe(const R4GfxNativeRegistration *input, uint64_t held_generation, uint64_t reset_generation, R4GfxNativeState *output) {
    assert(input->backend.reset_generation == UINT64_C(0x30000000b) && held_generation == UINT64_C(0x200000079) && reset_generation == UINT64_C(0x100000008));
    assert(output->version == 1 && output->size == sizeof(*output));
    *output = (R4GfxNativeState){.version=1,.size=sizeof(*output),.generation=reset_generation+1,.outcome=R4OS_GFX_OUTPUT_OUTCOME_VALIDATED,.retained=1};
    return R4OS_GFX_OUTPUT_OK;
}
static int32_t presentation_read_probe(uint32_t head, R4DisplayPresentationStats *output) {
    assert(head == 3 && output->version == 1 && output->size == 208);
    output->visible_sequence = UINT64_C(0x100000079); output->source_point = UINT64_C(0x200000079);
    return R4OS_GFX_OUTPUT_OK;
}
static int32_t presentation_publish_probe(const R4DisplayPresentationStats *input) {
    assert(input->version == 1 && input->size == 208 && input->visible_sequence == UINT64_C(0x100000079) && input->source_point == UINT64_C(0x200000079));
    return R4OS_GFX_OUTPUT_ERROR_STALE;
}

static int32_t output_test_probe(const R4GfxAtomicState *state, R4GfxAtomicResult *out) {
    assert(state->topology_revision == UINT64_C(0x100000007) && state->assignments[7].output.connection_generation == UINT64_C(0x200000009));
    assert(out->version == 1 && out->size == sizeof(*out)); out->topology_revision = state->topology_revision; return 1;
}
static int32_t mode_enable_probe(const R4GfxBackendBinding *backend) {
    assert(backend->device_generation == UINT64_C(0x100000079)); return 1;
}
static int32_t mode_take_probe(const R4GfxBackendBinding *backend, R4GfxDriverModeJob *output) {
    assert(backend->device_generation == UINT64_C(0x100000079));
    output->ticket = UINT64_C(0x200000079); output->sequence = 3; return 1;
}
static int32_t mode_complete_probe(const R4GfxDriverModeCompletion *input) {
    assert(input->ticket == UINT64_C(0x200000079) && input->sequence == 3 && input->quiesced == 1); return -3;
}
static int32_t mode_submit_probe(const R4GfxAtomicState *state, uint32_t ms, R4GfxModeStatus *output) {
    assert(state->topology_revision == UINT64_C(0x100000007) && ms == 15000 && output->size == 88);
    output->ticket = UINT64_C(0x200000079); output->phase = 1; output->retained = 3; return 1;
}
static int32_t mode_status_probe(uint64_t ticket, R4GfxModeStatus *output) {
    assert(ticket == UINT64_C(0x200000079) && output->size == 88); output->phase = 3; return 1;
}
static int32_t mode_resolve_probe(uint64_t ticket, uint32_t action, R4GfxModeStatus *output) {
    assert(ticket == UINT64_C(0x200000079) && action == 2 && output->size == 88); output->phase = 5; return 1;
}
static int32_t output_publish_probe(const R4GfxOutputPublication *publication, R4GfxOutputId *out) {
    assert(publication->info.edid_bytes == 128 && publication->edid[127] == 0x79);
    out->connection_generation = UINT64_C(0x40000000d); return 1;
}
static int32_t output_color_publish_probe(const R4GfxOutputColorState *input) {
    assert(input->identity.connection_generation == UINT64_C(0x40000000d) && input->formats == 1); return -3;
}
static uint32_t color_probe_prefix = sizeof(R4GfxOutputColorState);
static int32_t color_probe_status = R4OS_GFX_OUTPUT_OK;
static int32_t output_color_probe(const R4GfxOutputId *identity, R4GfxOutputColorState *output) {
    assert(output->version == 1 && output->size == sizeof(*output));
    R4GfxOutputColorState value = {.version=1,.size=color_probe_prefix,.identity=*identity,.revision=UINT64_C(0x600000007),.formats=1,.max_frl_rate=6};
    memcpy(output,&value,color_probe_prefix);
    return color_probe_status;
}
static int32_t output_pause_probe(const R4GfxOutputId *output, uint32_t paused) {
    assert(output->connection_generation == UINT64_C(0x40000000d) && paused <= 1);
    return paused ? 1 : R4OS_GFX_OUTPUT_ERROR_BUSY;
}
static int32_t mode_restore_probe(const R4GfxAtomicState *input, R4GfxModeStatus *out) {
    assert(input->topology_revision == 0 && input->count == 1);
    out->ticket = UINT64_C(0x200000079); return 1;
}
static int32_t audio_route_publish_probe(const R4GfxAudioRoute *input) {
    assert(input->source.generation == UINT64_C(0x100000079) && input->revision == UINT64_C(0x200000015) && input->eld[95] == 0x79);
    return R4OS_GFX_OUTPUT_ERROR_STALE;
}
static int32_t audio_route_query_probe(uint32_t location, uint32_t device, uint32_t index, R4GfxAudioRoute *output) {
    assert(location == 0x01000901 && device == 0x228e10de && output->size == 176);
    if(index != 0)return 0;
    output->source.generation = UINT64_C(0x100000079); output->revision = UINT64_C(0x200000015); output->eld[95] = 0x79;
    return 1;
}
static int32_t receiver_register_probe(uint32_t adapter, R4GfxReceiverSource *out) {
    assert(adapter == 17); out->adapter_id = adapter; out->generation = UINT64_C(0x100000079); return 1;
}
static int32_t receiver_replace_probe(const R4GfxReceiverUpdate *input) {
    assert(input->source.generation == UINT64_C(0x100000079) && input->sequence == UINT64_C(0x200000001) && input->count == 0 && input->receivers == 0); return -4;
}
static int32_t receiver_close_probe(const R4GfxReceiverSource *input) {
    assert(input->generation == UINT64_C(0x100000079)); return 1;
}

static int32_t gfx_wait_probe(const R4GfxFence *fence, uint64_t ticks, uint32_t wait_for, R4GfxFenceStatus *out) {
    assert(fence->point == UINT64_C(0x100000007) && fence->reset_generation == UINT64_C(0x200000001));
    assert(ticks == UINT64_C(0x300000003) && wait_for == 1 && out->version == 1 && out->size == 80);
    out->fence = *fence;
    return 1;
}
static int32_t gfx_complete_probe(const R4GfxFence *fence, uint32_t result, uint32_t quiesced) {
    assert(fence->point == UINT64_C(0x100000007) && result == 6 && quiesced == 0);
    return -4;
}
static int32_t gfx_retain_probe(const R4GfxFence *fence, uint32_t which, R4GfxBufferReference *out) {
    assert(fence->point == UINT64_C(0x100000007) && fence->reset_generation == UINT64_C(0x200000001) && which == 1);
    assert(out->version == 1 && out->size == 48);
    out->reference.generation = UINT64_C(0x400000009);
    out->flags = R4OS_GFX_BUFFER_REFERENCE_MAPPING_ONLY;
    return 1;
}

static int32_t gfx_map_probe(const R4GfxBufferHandle *ref, uint32_t access, uint64_t offset, uint64_t bytes, R4GfxBufferMap *out) {
    assert(ref->generation == 99 && access == 1 && offset == UINT64_C(0x100000003) && bytes == UINT64_C(0x200000000));
    assert(out->version == 1 && out->size == sizeof(*out));
    out->byte_length = bytes;
    return 1;
}
_Static_assert(sizeof(R4GfxOwnedBufferReservation)==88 && sizeof(R4GfxOwnedBufferRelease)==80 && offsetof(R4GfxDriverMemoryApi,buffer_reserve)==112 && offsetof(R4GfxDriverMemoryApi,native_register)==152 && sizeof(R4GfxDriverMemoryApi)==256 && offsetof(R4GfxDriverMemoryApi,unmanaged_span)==248 && offsetof(R4GfxDriverMemoryApi,reserved_span)==240 && offsetof(R4GfxDriverMemoryApi,virtual_register)==208 && offsetof(R4GfxDriverMemoryApi,virtual_complete)==232 && offsetof(R4GfxDriverMemoryApi,memory_budget)==184 && offsetof(R4GfxDriverMemoryApi,telemetry_exchange)==192 && offsetof(R4GfxDriverMemoryApi,device_lost)==200, "owned BO ABI and optional unmanaged-span tail");
static int32_t device_lost_probe(uint32_t adapter, uint64_t generation, uint32_t quiesced) {
    assert(adapter==17 && generation==UINT64_C(0x300000007) && quiesced<=1);
    return quiesced ? 1 : R4OS_GFX_BUFFER_ERROR_BUSY;
}
static void device_lost_facade_probe(void) {
    R4GfxDriverMemoryApi m={.version=1,.size=208,.device_lost=(uintptr_t)device_lost_probe};
    for(unsigned n=200;n<208;++n){m.size=n;assert(r4driver_memory_device_lost(&m,17,UINT64_C(0x300000007),1)==R4OS_ERR_NO_FN);}
    m.size=208;
    assert(r4driver_memory_device_lost(&m,17,UINT64_C(0x300000007),0)==R4OS_GFX_BUFFER_ERROR_BUSY);
    assert(r4driver_memory_device_lost(&m,17,UINT64_C(0x300000007),1)==1);
    assert(r4driver_memory_device_lost(&m,17,UINT64_C(0x300000007),2)==R4OS_GFX_BUFFER_ERROR_INVALID);
    m.device_lost=0;assert(r4driver_memory_device_lost(&m,17,UINT64_C(0x300000007),1)==R4OS_ERR_NO_FN);
}
static int32_t owned_reserve(const R4GfxBufferDescriptor *d, uint64_t c, R4GfxOwnedBufferReservation *o){assert(d && c==UINT64_C(0x100000003) && o->size==88);o->cookie=c;return 1;}
static int32_t owned_commit(const R4GfxOwnedBufferReservation *r,R4GfxBufferReference *o){assert(r->cookie==UINT64_C(0x100000003) && o->size==48);return 1;}
static int32_t owned_abort(const R4GfxOwnedBufferReservation *r,uint32_t q){assert(r->cookie==UINT64_C(0x100000003) && q==0);return -4;}
static int32_t owned_take(uint32_t a,uint64_t g,R4GfxOwnedBufferRelease *o){assert(a==17 && g==UINT64_C(0x300000007) && o->size==80);o->attempt=UINT64_C(0x400000009);return 1;}
static int32_t owned_finish(const R4GfxOwnedBufferRelease *r,uint32_t q){assert(r->attempt==UINT64_C(0x400000009) && q==1);return 1;}
static int32_t native_complete_probe(const R4GfxBufferHandle *p, const R4GfxBufferHandle *r, int32_t result, const R4GfxBufferHandle *ref) {
    assert(p->generation==UINT64_C(0x100000019) && r->generation==UINT64_C(0x200000019) && result==-6 && ref->id==0); return 1;
}
static int32_t native_take_probe(const R4GfxBufferHandle *p, R4GfxNativeJob *out) {
    assert(p && out->version==1 && out->size==88); out->request.generation=99; return -4;
}
static void native_facade_probe(void) {
    R4GfxDriverMemoryApi m={.version=1,.size=184,.native_complete=(uintptr_t)native_complete_probe,.native_take=(uintptr_t)native_take_probe};
    R4GfxBufferHandle p={.id=1,.generation=UINT64_C(0x100000019)},r={.id=2,.generation=UINT64_C(0x200000019)},ref={0};
    for(unsigned n=176;n<184;++n){m.size=n;assert(r4driver_memory_native_complete(&m,&p,&r,-6,&ref)==R4OS_ERR_NO_FN);}
    m.size=184;assert(r4driver_memory_native_complete(&m,&p,&r,-6,&ref)==1);
    R4GfxNativeJob out={.version=1,.size=88,.request={.generation=77}},before=out;
    assert(r4driver_memory_native_take(&m,&p,&out)==-4 && memcmp(&out,&before,sizeof(out))==0);
    m.size=152;assert(r4driver_memory_native_take(&m,&p,&out)==R4OS_ERR_NO_FN && memcmp(&out,&before,sizeof(out))==0);
}
static int32_t reserved_span_probe(uint64_t base, uint64_t bytes) {
    assert(base==UINT64_C(0x200000000) && bytes==UINT64_C(0x20000000));
    return R4OS_GFX_BUFFER_ERROR_UNSUPPORTED;
}
static void reserved_span_facade_probe(void) {
    R4GfxDriverMemoryApi m={.version=1,.size=248,.reserved_span=(uintptr_t)reserved_span_probe};
    for(unsigned n=240;n<248;++n){m.size=n;assert(r4driver_memory_reserved_span(&m,UINT64_C(0x200000000),UINT64_C(0x20000000))==R4OS_ERR_NO_FN);}
    m.size=248;assert(r4driver_memory_reserved_span(&m,UINT64_C(0x200000000),UINT64_C(0x20000000))==R4OS_GFX_BUFFER_ERROR_UNSUPPORTED);
    m.reserved_span=0;assert(r4driver_memory_reserved_span(&m,0,0)==R4OS_ERR_NO_FN);
    m.unmanaged_span=(uintptr_t)reserved_span_probe;
    for(unsigned n=248;n<256;++n){m.size=n;assert(r4driver_memory_unmanaged_span(&m,UINT64_C(0x200000000),UINT64_C(0x20000000))==R4OS_ERR_NO_FN);}
    m.size=256;assert(r4driver_memory_unmanaged_span(&m,UINT64_C(0x200000000),UINT64_C(0x20000000))==R4OS_GFX_BUFFER_ERROR_UNSUPPORTED);
    m.version=2;assert(r4driver_memory_unmanaged_span(&m,0,0)==R4OS_ERR_NO_FN);
    m.version=1;m.unmanaged_span=0;assert(r4driver_memory_unmanaged_span(&m,0,0)==R4OS_ERR_NO_FN);
}
static void owned_facade_probe(void){
    reserved_span_facade_probe();
    device_lost_facade_probe();
    native_facade_probe();
    R4GfxDriverMemoryApi m={.version=1,.size=152,.buffer_reserve=(uintptr_t)owned_reserve,.buffer_commit=(uintptr_t)owned_commit,.buffer_abort=(uintptr_t)owned_abort,.buffer_take_release=(uintptr_t)owned_take,.buffer_finish_release=(uintptr_t)owned_finish};
    R4GfxBufferDescriptor d={0};R4GfxOwnedBufferReservation r={0};R4GfxBufferReference ref={0};R4GfxOwnedBufferRelease rel={0};
    for(unsigned i=112;i<120;++i){m.size=i;assert(r4driver_memory_buffer_reserve(&m,&d,UINT64_C(0x100000003),&r)==R4OS_ERR_NO_FN && r.cookie==0);}
    m.size=120;assert(r4driver_memory_buffer_reserve(&m,&d,UINT64_C(0x100000003),&r)==1);
    for(unsigned i=120;i<128;++i){m.size=i;assert(r4driver_memory_buffer_commit(&m,&r,&ref)==R4OS_ERR_NO_FN);}
    m.size=128;assert(r4driver_memory_buffer_commit(&m,&r,&ref)==1);
    for(unsigned i=128;i<136;++i){m.size=i;assert(r4driver_memory_buffer_abort(&m,&r,0)==R4OS_ERR_NO_FN);}
    m.size=136;assert(r4driver_memory_buffer_abort(&m,&r,0)==-4);
    for(unsigned i=136;i<144;++i){m.size=i;assert(r4driver_memory_buffer_take_release(&m,17,UINT64_C(0x300000007),&rel)==R4OS_ERR_NO_FN);}
    m.size=144;assert(r4driver_memory_buffer_take_release(&m,17,UINT64_C(0x300000007),&rel)==1);
    for(unsigned i=144;i<152;++i){m.size=i;assert(r4driver_memory_buffer_finish_release(&m,&rel,1)==R4OS_ERR_NO_FN);}
    m.size=152;assert(r4driver_memory_buffer_finish_release(&m,&rel,1)==1);
}
static int32_t profile_register_probe(const R4GfxBackendRegistration *input, const R4GfxBackendProfile *profile, R4GfxBackendBinding *out) {
    assert(input->operations == 13 && input->memory_generation == UINT64_C(0x500000018));
    assert(input->adapter_id == 17 && profile->interface_id_hi == UINT64_C(0x300000017) && profile->data_bytes == 64 && profile->data[63] == 91);
    assert(out->version == 1 && out->size == 32);
    out->adapter_id = 17; out->device_generation = UINT64_C(0x100000017); out->reset_generation = UINT64_C(0x200000017); return 1;
}
static int32_t backend_info_probe(uint32_t index, R4GfxBackendInfo *out) {
    assert(index == 16 && out->version == 1 && out->size == sizeof(*out));
    out->operations = 13; out->memory_generation = UINT64_C(0x500000018);
    out->binding.device_generation = UINT64_C(0x100000017); out->binding.reset_generation = UINT64_C(0x200000017);
    out->profile.interface_id_hi = UINT64_C(0x300000017); out->profile.data_bytes = 64; out->profile.data[63] = 91; return 1;
}
static int32_t operations_probe(const R4GfxBackendBinding *binding, uint64_t operations) {
    assert(binding->device_generation == UINT64_C(0x100000019) && operations == 29);
    return 1;
}
static int32_t motion_probe(R4MouseMotion *output) {
    *output = (R4MouseMotion){.version = 1, .size = sizeof(*output), .motion_x = UINT32_C(0xfffffff1), .motion_y = UINT32_C(0x80000003)};
    return 1;
}
static int32_t grid_submit_probe(const R4GfxQueueHandle *queue, const R4GfxSubmission *request,
    const R4GfxRenderGridList *list, R4GfxFenceStatus *output) {
    assert(queue->timeline == UINT64_C(0x200000017) && request->operation == R4OS_GFX_QUEUE_OPERATION_RENDER_GRID_LIST);
    assert(list->version == 1 && list->size == 2320 && list->count == 1 && list->grids[0].scale == 180 && list->grids[0].rotation == 3);
    output->fence = (R4GfxFence){.slot = 7, .timeline = queue->timeline, .point = UINT64_C(0x300000019)};
    return 1;
}
static int32_t grid_read_probe(const R4GfxFence *fence, R4GfxRenderGridList *output) {
    assert(fence->timeline == UINT64_C(0x200000017) && fence->point == UINT64_C(0x300000019) && output->version == 1 && output->size == 2320);
    *output = (R4GfxRenderGridList){.version = 1, .size = sizeof(*output), .count = 1};
    output->grids[0] = (R4GfxSampleGrid){.enabled = 1, .scale = 180, .rotation = 3}; return 1;
}
static void grid_facade_probe(void) {
    R4XStartR4Desk desk_table = {.size = offsetof(R4XStartR4Desk, mouse_motion), .mouse_motion = (uintptr_t)motion_probe};
    const R4Desk desk = {&desk_table}; R4MouseMotion motion = {.motion_x = 79};
    assert(r4desk_mouse_motion(&desk, &motion) == R4OS_ERR_NO_FN && motion.motion_x == 79);
    desk_table.size += 8;
    assert(r4desk_mouse_motion(&desk, &motion) == 1 && motion.motion_x == UINT32_C(0xfffffff1));
    R4XStartR4Draw table = {.size = offsetof(R4XStartR4Draw, gfx_queue_submit_render_grid_list), .gfx_queue_submit_render_grid_list = (uintptr_t)grid_submit_probe};
    const R4Draw draw = {&table};
    const R4GfxQueueHandle queue = {.timeline = UINT64_C(0x200000017)};
    const R4GfxSubmission request = {.operation = R4OS_GFX_QUEUE_OPERATION_RENDER_GRID_LIST};
    R4GfxRenderGridList list = {.version = 1, .size = sizeof(list), .count = 1, .grids = {{.enabled = 1, .scale = 180, .rotation = 3}}};
    R4GfxFenceStatus result = {.deadline_ns = 79};
    assert(r4draw_gfx_queue_submit_render_grid_list(&draw, &queue, &request, &list, &result) == R4OS_ERR_NO_FN && result.deadline_ns == 79 && result.fence.point == 0);
    table.size += 8;
    assert(r4draw_gfx_queue_submit_render_grid_list(&draw, &queue, &request, &list, &result) == 1);
    R4GfxDriverQueueApi driver = {.version = 1, .read_render_grid_list = (uintptr_t)grid_read_probe};
    list.count = 79;
    for (unsigned size = 112; size < 120; ++size) {
        driver.size = size;
        assert(r4driver_queue_read_render_grid_list(&driver, &result.fence, &list) == R4OS_ERR_NO_FN && list.count == 79);
    }
    driver.size = 120;
    assert(r4driver_queue_read_render_grid_list(&driver, &result.fence, &list) == 1 && list.count == 1 && list.grids[0].rotation == 3 && list.grids[0].scale == 180);
}
static int32_t color_submit_probe(const R4GfxQueueHandle *queue, const R4GfxSubmission *request,
    const R4GfxRenderColorList *list, R4GfxFenceStatus *output) {
    assert(queue->timeline == UINT64_C(0x200000017) && request->operation == R4OS_GFX_QUEUE_OPERATION_RENDER_COLOR_LIST);
    assert(list->size == 1568 && list->count == 1 && list->program.size == 272 && list->program.words[63] == UINT32_C(0x12345678));
    output->fence = (R4GfxFence){.slot = 7, .timeline = queue->timeline, .point = UINT64_C(0x300000019)}; return 1;
}
static int32_t color_read_probe(const R4GfxFence *fence, R4GfxRenderColorList *output) {
    assert(fence->point == UINT64_C(0x300000019) && output->version == 1 && output->size == 1568);
    *output = (R4GfxRenderColorList){.version = 1, .size = sizeof(*output), .count = 1};
    output->program.words[63] = UINT32_C(0x87654321); return 1;
}
static void color_facade_probe(void) {
    R4XStartR4Draw table = {.size = 760, .gfx_queue_submit_render_color_list = (uintptr_t)color_submit_probe};
    const R4Draw draw = {&table};
    const R4GfxQueueHandle queue = {.timeline = UINT64_C(0x200000017)};
    const R4GfxSubmission request = {.operation = R4OS_GFX_QUEUE_OPERATION_RENDER_COLOR_LIST};
    R4GfxRenderColorList list = {.version = 1, .size = sizeof(list), .count = 1, .program = {.version = 1, .size = 272}};
    list.program.words[63] = UINT32_C(0x12345678);
    R4GfxFenceStatus result = {.deadline_ns = 79};
    assert(r4draw_gfx_queue_submit_render_color_list(&draw, &queue, &request, &list, &result) == R4OS_ERR_NO_FN && result.deadline_ns == 79 && result.fence.point == 0);
    table.size = 768;
    assert(r4draw_gfx_queue_submit_render_color_list(&draw, &queue, &request, &list, &result) == 1);
    R4GfxDriverQueueApi driver = {.version = 1, .read_render_color_list = (uintptr_t)color_read_probe};
    for (unsigned size = 120; size < 128; ++size) {
        driver.size = size;
        assert(r4driver_queue_read_render_color_list(&driver, &result.fence, &list) == R4OS_ERR_NO_FN && list.program.words[63] == UINT32_C(0x12345678));
    }
    driver.size = 128;
    assert(r4driver_queue_read_render_color_list(&driver, &result.fence, &list) == 1 && list.program.words[63] == UINT32_C(0x87654321));
}
static int32_t mode_color_test_probe(const R4GfxModeColorRequest *request, R4GfxAtomicResult *output) {
    assert(request->size == 1344 && request->image.id == 23 && request->image.generation == UINT64_C(0x200000017) && request->signal.metadata.max_cll == 1000);
    output->commit_sequence = UINT64_C(0x300000019); return 1;
}
static int32_t mode_color_submit_probe(const R4GfxModeColorRequest *request, uint32_t timeout, R4GfxModeStatus *output) {
    assert(request->image.id == 23 && request->image.generation == UINT64_C(0x200000017) && timeout == 15000);
    output->ticket = UINT64_C(0x300000019); return 1;
}
static int32_t mode_color_read_probe(uint64_t ticket, uint64_t sequence, R4GfxDriverModeColor *output) {
    assert(ticket == UINT64_C(0x300000019) && sequence == 2);
    *output = (R4GfxDriverModeColor){.version = 1, .size = sizeof(*output), .ticket = ticket, .sequence = sequence, .signal = {.metadata = {.max_cll = 1000}}}; return 1;
}
static int32_t refresh_read_probe(const R4GfxOutputTarget *target, R4GfxOutputRefresh *output) {
    assert(output->version == 1 && output->size == 272);
    output->target = *target; output->status.sequence = UINT64_C(0x200000079);
    return target->head_id == 7 ? -3 : 1;
}
static int32_t refresh_intent_probe(const R4GfxRefreshRequest *input, R4GfxRefreshRequest *output) {
    assert(output->version == 1 && output->size == 88);
    *output = *input; output->sequence = UINT64_C(0x300000079);
    return input->target.head_id == 7 ? -3 : 1;
}
static int32_t refresh_driver_read_probe(const R4GfxOutputTarget *target, R4GfxRefreshRequest *output) {
    R4GfxRefreshRequest input = {.version = 1, .size = sizeof(input), .target = *target};
    return refresh_intent_probe(&input, output);
}
static int32_t refresh_publish_probe(const R4GfxOutputRefresh *input) { return input->status.sequence == UINT64_C(0x200000079) ? 1 : -3; }
static void refresh_facade_probe(void) {
    R4XStartR4Draw table = {.size = 791, .gfx_output_refresh = (uintptr_t)refresh_read_probe, .gfx_refresh_request = (uintptr_t)refresh_intent_probe};
    R4Draw draw = {.table = &table};
    R4GfxRefreshRequest request = {.version = 1, .size = sizeof(request), .target = {.display_generation = UINT64_C(0x400000079)}};
    R4GfxOutputRefresh read = {.status = {.sequence = 79}};
    R4GfxRefreshRequest intent = {.sequence = 79};
    assert(r4draw_gfx_output_refresh(&draw, &request.target, &read) == R4OS_ERR_NO_FN && read.status.sequence == 79);
    table.size = 792;
    assert(r4draw_gfx_output_refresh(&draw, &request.target, &read) == 1 && read.target.display_generation == request.target.display_generation);
    assert(r4draw_gfx_refresh_request(&draw, &request, &intent) == R4OS_ERR_NO_FN && intent.sequence == 79);
    table.size = 800;
    assert(r4draw_gfx_refresh_request(&draw, &request, &intent) == 1);
    R4GfxDriverOutputApi driver = {.version = 1, .refresh_publish = (uintptr_t)refresh_publish_probe, .refresh_read = (uintptr_t)refresh_driver_read_probe};
    for (unsigned bytes = 128; bytes < 144; ++bytes) {
        driver.size = bytes;
        assert(!r4driver_output_supports_refresh(&driver) && r4driver_output_read_refresh(&driver, &request.target, &intent) == R4OS_ERR_NO_FN);
    }
    driver.size = 144;
    assert(r4driver_output_publish_refresh(&driver, &read) == 1 && r4driver_output_read_refresh(&driver, &request.target, &intent) == 1);
    R4GfxOutputRefresh old_read = read; R4GfxRefreshRequest old_intent = intent;
    request.target.head_id = 7;
    assert(r4draw_gfx_output_refresh(&draw, &request.target, &read) == -3);
    assert(r4draw_gfx_refresh_request(&draw, &request, &intent) == -3);
    assert(r4driver_output_read_refresh(&driver, &request.target, &intent) == -3);
    assert(memcmp(&read, &old_read, sizeof(read)) == 0 && memcmp(&intent, &old_intent, sizeof(intent)) == 0);
}
static void mode_color_facade_probe(void) {
    R4XStartR4Draw table = {.size = 768, .gfx_atomic_test_color = (uintptr_t)mode_color_test_probe, .gfx_atomic_submit_color = (uintptr_t)mode_color_submit_probe};
    const R4Draw draw = {&table};
    const R4GfxModeColorRequest request = {.version = 1, .size = sizeof(request), .image = {.id = 23, .generation = UINT64_C(0x200000017)}, .signal = {.metadata = {.max_cll = 1000}}};
    R4GfxAtomicResult tested = {.commit_sequence = 79}; R4GfxModeStatus submitted = {.ticket = 79};
    assert(r4draw_gfx_atomic_test_color(&draw, &request, &tested) == R4OS_ERR_NO_FN);
    assert(r4draw_gfx_atomic_submit_color(&draw, &request, 15000, &submitted) == R4OS_ERR_NO_FN && tested.commit_sequence == 79 && submitted.ticket == 79);
    table.size = 776;
    assert(r4draw_gfx_atomic_test_color(&draw, &request, &tested) == 1);
    assert(r4draw_gfx_atomic_submit_color(&draw, &request, 15000, &submitted) == R4OS_ERR_NO_FN && submitted.ticket == 79);
    table.size = 784;
    assert(r4draw_gfx_atomic_submit_color(&draw, &request, 15000, &submitted) == 1);
    R4GfxDriverOutputApi driver = {.version = 1, .mode_enable = 1, .mode_take = 1, .mode_complete = 1, .mode_read_color = (uintptr_t)mode_color_read_probe};
    R4GfxDriverModeColor color = {.ticket = 79};
    for (unsigned size = 120; size < 128; ++size) {
        driver.size = size;
        assert(r4driver_output_read_mode_color(&driver, submitted.ticket, 2, &color) == R4OS_ERR_NO_FN && color.ticket == 79);
    }
    driver.size = 128;
    assert(r4driver_output_read_mode_color(&driver, submitted.ticket, 2, &color) == 1 && color.ticket == tested.commit_sequence && color.sequence == 2 && color.signal.metadata.max_cll == 1000);
}
static int32_t power_read_probe(const R4GfxOutputId *identity, R4GfxOutputPower *output) {
    assert(output->version == 1 && output->size == 96);
    output->identity = *identity; output->sequence = UINT64_C(0x200000079);
    return identity->connector_id == 7 ? -3 : 1;
}
static int32_t power_intent_probe(const R4GfxPowerRequest *input, R4GfxPowerRequest *output) {
    assert(output->version == 1 && output->size == 64);
    *output = *input; output->sequence = UINT64_C(0x300000079);
    return input->identity.connector_id == 7 ? -3 : 1;
}
static int32_t power_driver_read_probe(const R4GfxOutputId *identity, R4GfxPowerRequest *output) {
    R4GfxPowerRequest input = {.version=1, .size=sizeof(input), .identity=*identity};
    return power_intent_probe(&input, output);
}
static int32_t power_publish_probe(const R4GfxOutputPower *input) { return input->sequence == UINT64_C(0x200000079) ? 1 : -3; }
static void power_facade_probe(void) {
    R4XStartR4Draw table = {.gfx_output_power=(uintptr_t)power_read_probe, .gfx_power_request=(uintptr_t)power_intent_probe};
    R4Draw draw = {.table=&table};
    R4GfxPowerRequest request = {.version=1, .size=sizeof(request), .identity={.connection_generation=UINT64_C(0x400000079)}};
    R4GfxOutputPower read = {.sequence=79}; R4GfxPowerRequest intent = {.sequence=79};
    for (unsigned size=816; size<824; ++size) {
        table.size=size; assert(r4draw_gfx_output_power(&draw,&request.identity,&read)==R4OS_ERR_NO_FN && read.sequence==79);
    }
    table.size=824; assert(r4draw_gfx_output_power(&draw,&request.identity,&read)==1 && read.identity.connection_generation==request.identity.connection_generation);
    for (unsigned size=824; size<832; ++size) {
        table.size=size; assert(r4draw_gfx_power_request(&draw,&request,&intent)==R4OS_ERR_NO_FN && intent.sequence==79);
    }
    table.size=832; assert(r4draw_gfx_power_request(&draw,&request,&intent)==1);
    R4GfxDriverOutputApi driver = {.version=1, .power_publish=(uintptr_t)power_publish_probe, .power_read=(uintptr_t)power_driver_read_probe};
    for (unsigned size=144; size<160; ++size) {
        driver.size=size; assert(!r4driver_output_supports_power(&driver) && r4driver_output_read_power(&driver,&request.identity,&intent)==R4OS_ERR_NO_FN);
    }
    driver.size=160; assert(r4driver_output_publish_power(&driver,&read)==1 && r4driver_output_read_power(&driver,&request.identity,&intent)==1);
    R4GfxOutputPower old_read=read; R4GfxPowerRequest old_intent=intent;
    request.identity.connector_id=7;
    assert(r4draw_gfx_output_power(&draw,&request.identity,&read)==-3);
    assert(r4draw_gfx_power_request(&draw,&request,&intent)==-3);
    assert(r4driver_output_read_power(&driver,&request.identity,&intent)==-3);
    assert(memcmp(&read,&old_read,sizeof(read))==0 && memcmp(&intent,&old_intent,sizeof(intent))==0);
}
static int32_t brightness_read_probe(const R4GfxOutputId *identity, R4GfxOutputBrightness *output) {
    assert(output->version == 1 && output->size == 88);
    output->identity = *identity; output->sequence = UINT64_C(0x200000079);
    return identity->connector_id == 7 ? -3 : 1;
}
static int32_t brightness_intent_probe(const R4GfxBrightnessRequest *input, R4GfxBrightnessRequest *output) {
    assert(output->version == 1 && output->size == 48);
    *output = *input; output->sequence = UINT64_C(0x300000079);
    return input->identity.connector_id == 7 ? -3 : 1;
}
static int32_t brightness_driver_read_probe(const R4GfxOutputId *identity, R4GfxBrightnessRequest *output) {
    R4GfxBrightnessRequest input = {.version=1, .size=sizeof(input), .identity=*identity};
    return brightness_intent_probe(&input, output);
}
static int32_t brightness_publish_probe(const R4GfxOutputBrightness *input) { return input->sequence == UINT64_C(0x200000079) ? 1 : -3; }
static void brightness_facade_probe(void) {
    R4XStartR4Draw table = {.gfx_output_brightness=(uintptr_t)brightness_read_probe, .gfx_brightness_request=(uintptr_t)brightness_intent_probe};
    R4Draw draw = {.table=&table};
    R4GfxBrightnessRequest request = {.version=1, .size=sizeof(request), .identity={.connection_generation=UINT64_C(0x400000079)}};
    R4GfxOutputBrightness read = {.sequence=79}; R4GfxBrightnessRequest intent = {.sequence=79};
    for (unsigned size=896; size<904; ++size) {
        table.size=size; assert(r4draw_gfx_output_brightness(&draw,&request.identity,&read)==R4OS_ERR_NO_FN && read.sequence==79);
    }
    table.size=904; assert(r4draw_gfx_output_brightness(&draw,&request.identity,&read)==1 && read.identity.connection_generation==request.identity.connection_generation);
    for (unsigned size=904; size<912; ++size) {
        table.size=size; assert(r4draw_gfx_brightness_request(&draw,&request,&intent)==R4OS_ERR_NO_FN && intent.sequence==79);
    }
    table.size=912; assert(r4draw_gfx_brightness_request(&draw,&request,&intent)==1);
    R4GfxDriverOutputApi driver = {.version=1, .brightness_publish=(uintptr_t)brightness_publish_probe, .brightness_read=(uintptr_t)brightness_driver_read_probe};
    for (unsigned size=160; size<176; ++size) {
        driver.size=size; assert(!r4driver_output_supports_brightness(&driver) && r4driver_output_read_brightness(&driver,&request.identity,&intent)==R4OS_ERR_NO_FN);
    }
    driver.size=176; assert(r4driver_output_publish_brightness(&driver,&read)==1 && r4driver_output_read_brightness(&driver,&request.identity,&intent)==1);
    R4GfxOutputBrightness old_read=read; R4GfxBrightnessRequest old_intent=intent;
    request.identity.connector_id=7;
    assert(r4draw_gfx_output_brightness(&draw,&request.identity,&read)==-3);
    assert(r4draw_gfx_brightness_request(&draw,&request,&intent)==-3);
    assert(r4driver_output_read_brightness(&driver,&request.identity,&intent)==-3);
    assert(memcmp(&read,&old_read,sizeof(read))==0 && memcmp(&intent,&old_intent,sizeof(intent))==0);
}
static int32_t properties_read_probe(const R4GfxBackendBinding *binding, R4GfxBackendProperties *out) {
    assert(binding->device_generation == UINT64_C(0x100000017) && out->version == 1 && out->size == 288);
    out->data[255] = 0x35;
    return binding->adapter_id == 17 ? 1 : -3;
}
static int32_t properties_publish_probe(const R4GfxBackendBinding *binding, const R4GfxBackendProperties *input) {
    assert(binding->device_generation == UINT64_C(0x100000017) && input->data[255] == 0x35);
    return 1;
}
static int32_t native_submit_probe(const R4GfxQueueHandle *queue, const R4GfxSubmission *submission, const R4GfxNativeSubmission *native, R4GfxFenceStatus *out) {
    assert(queue->timeline == UINT64_C(0x100000003) && submission->operation == R4OS_GFX_QUEUE_OPERATION_NATIVE);
    assert(native->commands == UINT64_C(0x200000009) && out->version == 1 && out->size == 80);
    out->fence.point = UINT64_C(0x300000007);
    return native->revision == 1 ? 1 : -3;
}
static int32_t native_info_probe(const R4GfxFence *fence, R4GfxNativeJobInfo *out) {
    assert(out->version == 1 && out->size == 40);
    out->command_bytes = 2051;
    return fence->slot == 7 ? 1 : -3;
}
static int32_t queue_owner_probe(const R4GfxBackendBinding *binding, uint64_t timeline, R4GfxQueueOwnerInfo *out) {
    assert(binding->device_generation == UINT64_C(0x100000017) && timeline == UINT64_C(0x200000009) && out->version == 1 && out->size == 48);
    out->timeline=timeline; out->producer_generation=UINT64_C(0x300000005); out->closing=1;
    return binding->adapter_id == 17 ? 1 : binding->adapter_id == 18 ? 0 : -3;
}
static void properties_facade_probe(void) {
    R4XStartR4Draw raw = {.gfx_queue_submit_native = (uintptr_t)native_submit_probe};
    R4Draw raw_draw = {&raw};
    R4GfxQueueHandle queue = {.timeline=UINT64_C(0x100000003)};
    R4GfxSubmission submission = {.operation=R4OS_GFX_QUEUE_OPERATION_NATIVE};
    R4GfxNativeSubmission input = {.commands=UINT64_C(0x200000009),.revision=1};
    R4GfxFenceStatus out = {0}, before = out;
    for (unsigned size=880; size<888; size++) {
        raw.size=size;
        assert(r4draw_gfx_queue_submit_native(&raw_draw,&queue,&submission,&input,&out)==R4OS_ERR_NO_FN && memcmp(&out,&before,sizeof(out))==0);
    }
    raw.size=888;
    input.revision=2;
    assert(r4draw_gfx_queue_submit_native(&raw_draw,&queue,&submission,&input,&out)==-3 && memcmp(&out,&before,sizeof(out))==0);
    input.revision=1;
    assert(r4draw_gfx_queue_submit_native(&raw_draw,&queue,&submission,&input,&out)==1 && out.fence.point==UINT64_C(0x300000007));
    R4GfxDriverQueueApi native_driver = {.version=1,.read_native_info=(uintptr_t)native_info_probe};
    R4GfxNativeJobInfo job={0}, saved_job=job;
    R4GfxFence fence={.slot=7};
    for (unsigned size=136; size<144; size++) {
        native_driver.size=size;
        assert(r4driver_queue_native_info(&native_driver,&fence,&job)==R4OS_ERR_NO_FN && memcmp(&job,&saved_job,sizeof(job))==0);
    }
    native_driver.size=144; fence.slot=8;
    assert(r4driver_queue_native_info(&native_driver,&fence,&job)==-3 && memcmp(&job,&saved_job,sizeof(job))==0);
    fence.slot=7; assert(r4driver_queue_native_info(&native_driver,&fence,&job)==1 && job.command_bytes==2051);
    R4XStartR4Draw table = {.gfx_queue_backend_properties = (uintptr_t)properties_read_probe};
    R4Draw draw = {&table};
    R4GfxBackendBinding binding = {.adapter_id=17, .device_generation=UINT64_C(0x100000017)};
    R4GfxBackendProperties properties = {0}; properties.data[255]=0xa5;
    for (unsigned size=872; size<880; size++) {
        table.size=size;
        assert(r4draw_gfx_queue_backend_properties(&draw,&binding,&properties)==R4OS_ERR_NO_FN && properties.data[255]==0xa5);
    }
    table.size=880;
    assert(r4draw_gfx_queue_backend_properties(&draw,&binding,&properties)==1 && properties.data[255]==0x35);
    binding.adapter_id=18; properties.data[255]=0xa5;
    assert(r4draw_gfx_queue_backend_properties(&draw,&binding,&properties)==-3 && properties.data[255]==0xa5);
    binding.adapter_id=17; properties.data[255]=0x35;
    R4GfxDriverQueueApi driver = {.version=1,.publish_properties=(uintptr_t)properties_publish_probe};
    for (unsigned size=128; size<136; size++) {
        driver.size=size;
        assert(r4driver_queue_publish_properties(&driver,&binding,&properties)==R4OS_ERR_NO_FN);
    }
    driver.size=136; assert(r4driver_queue_publish_properties(&driver,&binding,&properties)==1);
    driver.queue_owner_info=(uintptr_t)queue_owner_probe;
    R4GfxQueueOwnerInfo owner={0}, saved_owner=owner;
    for (unsigned size=160; size<168; size++) {
        driver.size=size;
        assert(r4driver_queue_owner_info(&driver,&binding,UINT64_C(0x200000009),&owner)==R4OS_ERR_NO_FN && memcmp(&owner,&saved_owner,sizeof(owner))==0);
    }
    driver.size=168; binding.adapter_id=18;
    assert(r4driver_queue_owner_info(&driver,&binding,UINT64_C(0x200000009),&owner)==0 && memcmp(&owner,&saved_owner,sizeof(owner))==0);
    binding.adapter_id=19;
    assert(r4driver_queue_owner_info(&driver,&binding,UINT64_C(0x200000009),&owner)==-3 && memcmp(&owner,&saved_owner,sizeof(owner))==0);
    binding.adapter_id=17;
    assert(r4driver_queue_owner_info(&driver,&binding,UINT64_C(0x200000009),&owner)==1 && owner.producer_generation==UINT64_C(0x300000005) && owner.closing==1);
}
static void backend_profile_probe(void) {
    properties_facade_probe();
    power_facade_probe();
    brightness_facade_probe();
    mode_color_facade_probe();
    refresh_facade_probe();
    color_facade_probe();
    grid_facade_probe();
    R4XStartR4Draw table = {.size = 640, .gfx_queue_backend_info = (uintptr_t)backend_info_probe};
    R4Draw draw = {&table}; R4GfxBackendInfo info = {0};
    assert(r4draw_gfx_queue_backend_info(&draw, 16, &info) == R4OS_ERR_NO_FN && info.binding.device_generation == 0);
    table.size = 648; assert(r4draw_gfx_queue_backend_info(&draw, 16, &info) == 1);
    assert(info.operations == 13 && info.memory_generation == UINT64_C(0x500000018));
    R4GfxDriverQueueApi driver = {.version = 1, .register_profile = (uintptr_t)profile_register_probe};
    R4GfxBackendRegistration registration = {.adapter_id = 17, .operations = info.operations, .memory_generation = info.memory_generation}; R4GfxBackendBinding binding = {0};
    for (unsigned size = 64; size < 72; ++size) {
        driver.size = size;
        assert(r4driver_queue_register_profile(&driver, &registration, &info.profile, &binding) == R4OS_ERR_NO_FN && binding.device_generation == 0);
    }
    driver.size = 72; assert(r4driver_queue_register_profile(&driver, &registration, &info.profile, &binding) == 1);
    assert(binding.device_generation == info.binding.device_generation && binding.reset_generation == info.binding.reset_generation);
    driver.update_operations = (uintptr_t)operations_probe;
    binding.device_generation = UINT64_C(0x100000019);
    for (unsigned n = 72; n < 80; ++n) {
        driver.size = n;
        assert(r4driver_queue_update_operations(&driver, &binding, 29) == R4OS_ERR_NO_FN);
    }
    driver.size = 80;
    assert(r4driver_queue_update_operations(&driver, &binding, 29) == 1);
}
static void gfx_facade_probe(void) {
    owned_facade_probe();
    R4XStartR4Draw table = {0};
    table.size = offsetof(R4XStartR4Draw, gfx_buffer_map);
    table.gfx_buffer_map = (uintptr_t)gfx_map_probe;
    const R4Draw draw = { &table };
    R4GfxBufferHandle ref = { .id = 7, .generation = 99 };
    R4GfxBufferMap output = { .byte_length = 37 };
    assert(r4draw_gfx_buffer_map(&draw, &ref, 1, UINT64_C(0x100000003), UINT64_C(0x200000000), &output) == R4OS_ERR_NO_FN);
    assert(output.byte_length == 37);
    table.size = sizeof(table);
    assert(r4draw_gfx_buffer_map(&draw, &ref, 1, UINT64_C(0x100000003), UINT64_C(0x200000000), &output) == 1);
    table.gfx_buffer_map_persistent = (uintptr_t)gfx_map_probe;
    const R4GfxBufferMap saved = output;
    for (unsigned size = 864; size < 872; size++) {
        table.size = size;
        assert(r4draw_gfx_buffer_map_persistent(&draw, &ref, 1, UINT64_C(0x100000003), UINT64_C(0x200000000), &output) == R4OS_ERR_NO_FN);
        assert(memcmp(&saved, &output, sizeof(saved)) == 0);
    }
    table.size = sizeof(table);
    assert(r4draw_gfx_buffer_map_persistent(&draw, &ref, 1, UINT64_C(0x100000003), UINT64_C(0x200000000), &output) == 1);
    R4GfxDriverMemoryApi memory = { .version = 1, .size = sizeof(memory), .buffer_map = (uintptr_t)gfx_map_probe };
    assert(r4driver_memory_buffer_map(&memory, &ref, 1, UINT64_C(0x100000003), UINT64_C(0x200000000), &output) == 1);
    memory.size = offsetof(R4GfxDriverMemoryApi, buffer_map);
    assert(r4driver_memory_buffer_map(&memory, &ref, 1, 0, 0, &output) == R4OS_ERR_NO_FN);
    R4GfxFence fence = {.slot = 7, .timeline = 23, .point = UINT64_C(0x100000007), .reset_generation = UINT64_C(0x200000001)};
    R4GfxFenceStatus result = {.deadline_ns = 123};
    table.gfx_fence_wait = (uintptr_t)gfx_wait_probe;
    table.size = offsetof(R4XStartR4Draw, gfx_fence_wait);
    assert(r4draw_gfx_fence_wait(&draw, &fence, UINT64_C(0x300000003), 1, &result) == R4OS_ERR_NO_FN);
    assert(result.deadline_ns == 123);
    table.size += sizeof(uintptr_t);
    assert(r4draw_gfx_fence_wait(&draw, &fence, UINT64_C(0x300000003), 1, &result) == 1);
    R4GfxDriverQueueApi native = {.version = 1, .size = sizeof(native), .complete = (uintptr_t)gfx_complete_probe};
    assert(r4driver_queue_complete(&native, &fence, 6, 0) == -4);
    native.size = offsetof(R4GfxDriverQueueApi, complete);
    assert(r4driver_queue_complete(&native, &fence, 6, 0) == R4OS_ERR_NO_FN);
    R4GfxBufferReference retained = {.flags = 79};
    native.retain_resource = (uintptr_t)gfx_retain_probe;
    for (unsigned size = 56; size < 64; ++size) {
        native.size = size;
        assert(r4driver_queue_retain_resource(&native, &fence, 1, &retained) == R4OS_ERR_NO_FN && retained.flags == 79);
    }
    native.size = 64;
    assert(r4driver_queue_retain_resource(&native, &fence, 1, &retained) == 1);
    assert(retained.reference.generation == UINT64_C(0x400000009) && retained.flags == R4OS_GFX_BUFFER_REFERENCE_MAPPING_ONLY);
    backend_profile_probe();
    R4GfxAtomicState state = {.topology_revision = UINT64_C(0x100000007)};
    state.assignments[7].output.connection_generation = UINT64_C(0x200000009);
    R4GfxAtomicResult atomic_result = {.commit_sequence = 77};
    table.abi_version = 11; table.size = 536; table.gfx_atomic_test = (uintptr_t)output_test_probe;
    assert(r4draw_gfx_atomic_test(&draw, &state, &atomic_result) == R4OS_ERR_NO_FN && atomic_result.commit_sequence == 77);
    table.size = sizeof(table);
    assert(r4draw_gfx_atomic_test(&draw, &state, &atomic_result) == 1 && atomic_result.topology_revision == state.topology_revision);
    table.gfx_atomic_submit = (uintptr_t)mode_submit_probe;
    table.gfx_atomic_status = (uintptr_t)mode_status_probe;
    table.gfx_atomic_resolve = (uintptr_t)mode_resolve_probe;
    R4GfxModeStatus mode_status = {0};
    table.size = 584;
    assert(r4draw_gfx_atomic_submit(&draw, &state, 15000, &mode_status) == R4OS_ERR_NO_FN && mode_status.ticket == 0);
    table.size = sizeof(table);
    assert(r4draw_gfx_atomic_submit(&draw, &state, 15000, &mode_status) == 1);
    assert(r4draw_gfx_atomic_status(&draw, mode_status.ticket, &mode_status) == 1);
    assert(r4draw_gfx_atomic_resolve(&draw, mode_status.ticket, 2, &mode_status) == 1 && mode_status.phase == 5 && mode_status.retained == 3);
    R4GfxDriverOutputApi modes = {.version = 1, .size = 72, .mode_enable = (uintptr_t)mode_enable_probe, .mode_take = (uintptr_t)mode_take_probe, .mode_complete = (uintptr_t)mode_complete_probe};
    R4GfxBackendBinding mode_binding = {.device_generation = UINT64_C(0x100000079)};
    R4GfxDriverModeJob mode_job = {0};
    for (unsigned bytes = 24; bytes < 72; ++bytes) {
        modes.size = bytes;
        assert(!r4driver_output_supports_modes(&modes) && r4driver_output_take_mode(&modes, &mode_binding, &mode_job) == R4OS_ERR_NO_FN);
    }
    modes.size = 72;
    assert(r4driver_output_enable_modes(&modes, &mode_binding) == 1 && r4driver_output_take_mode(&modes, &mode_binding, &mode_job) == 1);
    R4GfxDriverModeCompletion completion = {.ticket = mode_job.ticket, .sequence = mode_job.sequence, .quiesced = 1};
    assert(r4driver_output_complete_mode(&modes, &completion) == -3);
    R4GfxDriverOutputApi output_driver = {.version = 1, .size = sizeof(output_driver), .publish = (uintptr_t)output_publish_probe};
    R4GfxDriverOutputApi hotplug = {.version=1,.size=112,.output_pause=(uintptr_t)output_pause_probe,
        .mode_restore=(uintptr_t)mode_restore_probe,.mode_status=(uintptr_t)mode_status_probe};
    R4GfxOutputId port = {.connection_generation=UINT64_C(0x40000000d)};
    R4GfxOutputColorState color_state = {.formats=7};
    R4GfxOutputColorState color_before = color_state;
    R4XStartR4Draw color_table = {.size=752,.gfx_output_color=(uintptr_t)output_color_probe};
    R4Draw color_draw = {.table=&color_table};
    assert(r4draw_gfx_output_color(&color_draw,&port,&color_state)==R4OS_ERR_NO_FN && memcmp(&color_before,&color_state,sizeof(color_state))==0);
    color_table.size=sizeof(color_table);
    assert(r4draw_gfx_output_color(&color_draw,&port,&color_state)==1 && color_state.revision==UINT64_C(0x600000007));
    assert(color_state.max_frl_rate==6);
    color_before=color_state;
    color_probe_prefix=128;
    assert(r4draw_gfx_output_color(&color_draw,&port,&color_state)==R4OS_GFX_OUTPUT_ERROR_INVALID && memcmp(&color_before,&color_state,sizeof(color_state))==0);
    color_probe_prefix=sizeof(R4GfxOutputColorState); color_probe_status=R4OS_GFX_OUTPUT_ERROR_BUSY;
    color_before=color_state;
    assert(r4draw_gfx_output_color(&color_draw,&port,&color_state)==R4OS_GFX_OUTPUT_ERROR_BUSY && memcmp(&color_before,&color_state,sizeof(color_state))==0);
    color_probe_status=R4OS_GFX_OUTPUT_OK;
    R4GfxDriverOutputApi color_driver={.version=1,.color_publish=(uintptr_t)output_color_publish_probe};
    for (unsigned bytes=24;bytes<120;++bytes) {
        color_driver.size=bytes;
        assert(!r4driver_output_supports_color(&color_driver) && r4driver_output_publish_color(&color_driver,&color_state)==R4OS_ERR_NO_FN);
    }
    color_driver.size=120;
    assert(r4driver_output_publish_color(&color_driver,&color_state)==-3);
    R4GfxAtomicState reconnect = {.count=1};
    R4GfxModeStatus restored = {.version=1,.size=sizeof(restored)};
    for (unsigned bytes=24;bytes<112;++bytes) {
        hotplug.size=bytes;
        assert(!r4driver_output_supports_hotplug(&hotplug));
        assert(r4driver_output_pause(&hotplug,&port,1)==R4OS_ERR_NO_FN);
        assert(r4driver_output_restore_mode(&hotplug,&reconnect,&restored)==R4OS_ERR_NO_FN);
        assert(r4driver_output_mode_status(&hotplug,UINT64_C(0x200000079),&restored)==R4OS_ERR_NO_FN && restored.ticket==0);
    }
    hotplug.size=112;
    assert(r4driver_output_pause(&hotplug,&port,1)==1);
    assert(r4driver_output_pause(&hotplug,&port,0)==R4OS_GFX_OUTPUT_ERROR_BUSY);
    assert(r4driver_output_restore_mode(&hotplug,&reconnect,&restored)==1);
    assert(r4driver_output_mode_status(&hotplug,restored.ticket,&restored)==1);
    hotplug.mode_status=0; assert(!r4driver_output_supports_hotplug(&hotplug));
    R4GfxOutputPublication publication = {0}; publication.info.edid_bytes = 128; publication.edid[127] = 0x79;
    R4GfxOutputId identity = {0};
    assert(r4driver_output_publish(&output_driver, &publication, &identity) == 1 && identity.connection_generation == UINT64_C(0x40000000d));
    R4GfxDriverOutputApi audio_routes = {0}; audio_routes.version = 1;
    audio_routes.audio_publish = (uint64_t)(uintptr_t)&audio_route_publish_probe;
    audio_routes.audio_query = (uint64_t)(uintptr_t)&audio_route_query_probe;
    R4GfxAudioRoute audio_route = {0}; audio_route.version = 1; audio_route.size = sizeof(audio_route);
    const uint32_t audio_prefixes[] = {24,48,72,79,80,87};
    for(size_t i=0;i<sizeof(audio_prefixes)/sizeof(audio_prefixes[0]);i++) {
        audio_routes.size = audio_prefixes[i];
        assert(!r4driver_output_supports_audio(&audio_routes));
        assert(r4driver_output_query_audio(&audio_routes,0x01000901,0x228e10de,0,&audio_route) == R4OS_ERR_NO_FN);
        assert(r4driver_output_publish_audio(&audio_routes,&audio_route) == R4OS_ERR_NO_FN);
        assert(audio_route.source.generation == 0 && audio_route.revision == 0 && audio_route.eld[95] == 0);
    }
    audio_routes.size = 88;
    assert(r4driver_output_query_audio(&audio_routes,0x01000901,0x228e10de,0,&audio_route) == 1);
    const R4GfxAudioRoute audio_before = audio_route;
    assert(r4driver_output_query_audio(&audio_routes,0x01000901,0x228e10de,1,&audio_route) == 0 && memcmp(&audio_before,&audio_route,sizeof(audio_route)) == 0);
    assert(r4driver_output_publish_audio(&audio_routes,&audio_route) == R4OS_GFX_OUTPUT_ERROR_STALE);
    output_driver.register_source = (uintptr_t)receiver_register_probe;
    output_driver.replace_receivers = (uintptr_t)receiver_replace_probe;
    output_driver.close_source = (uintptr_t)receiver_close_probe;
    R4GfxReceiverSource receiver_source = {0};
    assert(r4driver_output_supports_receivers(&output_driver));
    assert(r4driver_output_register_source(&output_driver, 17, &receiver_source) == 1);
    R4GfxReceiverUpdate update = {.version = 1, .size = sizeof(update), .source = receiver_source, .sequence = UINT64_C(0x200000001)};
    assert(r4driver_output_replace_receivers(&output_driver, &update) == -4);
    assert(r4driver_output_close_source(&output_driver, &receiver_source) == 1);
    for (unsigned size = 24; size < 48; ++size) {
        output_driver.size = size;
        assert(!r4driver_output_supports_receivers(&output_driver));
        assert(r4driver_output_register_source(&output_driver, 17, &receiver_source) == R4OS_ERR_NO_FN);
        assert(r4driver_output_replace_receivers(&output_driver, &update) == R4OS_ERR_NO_FN);
        assert(r4driver_output_close_source(&output_driver, &receiver_source) == R4OS_ERR_NO_FN);
        assert(receiver_source.generation == UINT64_C(0x100000079));
    }
    output_driver.size = offsetof(R4GfxDriverOutputApi, publish);
    assert(r4driver_output_publish(&output_driver, &publication, &identity) == R4OS_ERR_NO_FN && identity.connection_generation == UINT64_C(0x40000000d));
    R4GfxDriverDisplayApi display = {.version = 1, .size = sizeof(display), .transition = (uintptr_t)display_transition_probe, .schedule = (uintptr_t)display_schedule_probe};
    R4GfxNativeState outcome = {0};
    assert(r4driver_display_transition(&display, UINT64_C(0x100000007), 2, &outcome) == 1);
    assert(outcome.generation == UINT64_C(0x100000008) && outcome.outcome == 3 && outcome.retained == 1);
    R4GfxBackendBinding binding = {.reset_generation = UINT64_C(0x30000000b)};
    assert(r4driver_display_schedule(&display, &binding) == -4);
    display.size = offsetof(R4GfxDriverDisplayApi, schedule);
    assert(r4driver_display_schedule(&display, &binding) == R4OS_ERR_NO_FN);
    display.size = offsetof(R4GfxDriverDisplayApi, transition);
    assert(r4driver_display_transition(&display, 0, 0, &outcome) == R4OS_ERR_NO_FN);
    assert(outcome.generation == UINT64_C(0x100000008) && outcome.retained == 1);
    display = (R4GfxDriverDisplayApi){.version=1,.device_reset=(uintptr_t)display_device_reset_probe,.prepare_reset=(uintptr_t)display_prepare_reset_probe};
    R4GfxNativeRegistration reset_registration = {.backend=binding};
    for (unsigned prefix=40; prefix<136; ++prefix) {
        display.size=prefix;
        assert(!r4driver_display_supports_reset(&display));
        assert(r4driver_display_device_reset(&display,&binding,UINT64_C(0x100000007),0,&outcome)==R4OS_ERR_NO_FN);
        assert(r4driver_display_prepare_reset(&display,&reset_registration,UINT64_C(0x200000079),UINT64_C(0x100000008),&outcome)==R4OS_ERR_NO_FN);
        assert(outcome.generation==UINT64_C(0x100000008));
    }
    display.size=136;
    assert(r4driver_display_device_reset(&display,&binding,UINT64_C(0x100000007),0,&outcome)==R4OS_GFX_OUTPUT_OK);
    assert(r4driver_display_device_reset(&display,&binding,UINT64_C(0x100000007),1,&outcome)==R4OS_GFX_OUTPUT_ERROR_BUSY);
    assert(r4driver_display_device_reset(&display,&binding,UINT64_C(0x100000007),2,&outcome)==R4OS_GFX_OUTPUT_ERROR_INVALID);
    assert(outcome.generation==UINT64_C(0x100000008) && outcome.retained==1);
    assert(r4driver_display_prepare_reset(&display,&reset_registration,UINT64_C(0x200000079),UINT64_C(0x100000008),&outcome)==R4OS_GFX_OUTPUT_OK);
    assert(outcome.generation==UINT64_C(0x100000009) && outcome.retained==1);
    display.device_reset=0; assert(!r4driver_display_supports_reset(&display));
    R4DisplayPresentationStats statistics = {.visible_sequence = 79};
    table.display_presentation_stats = (uintptr_t)presentation_read_probe;
    for (unsigned bytes = 608; bytes < 616; ++bytes) {
        table.size = bytes;
        assert(!r4draw_supports_display_presentation_stats(&draw));
        assert(r4draw_display_presentation_stats(&draw, 3, &statistics) == R4OS_ERR_NO_FN && statistics.visible_sequence == 79);
    }
    table.size = 616;
    assert(r4draw_supports_display_presentation_stats(&draw));
    assert(r4draw_display_presentation_stats(&draw, 3, &statistics) == R4OS_GFX_OUTPUT_OK);
    assert(r4draw_display_presentation_stats(&draw, 3, 0) == R4OS_GFX_OUTPUT_ERROR_INVALID);
    display.presentation_stats = (uintptr_t)presentation_publish_probe;
    for (unsigned bytes = 64; bytes < 72; ++bytes) {
        display.size = bytes;
        assert(!r4driver_display_supports_presentation_stats(&display));
        assert(r4driver_display_presentation_stats(&display, &statistics) == R4OS_ERR_NO_FN);
    }
    display.size = 72;
    assert(r4driver_display_presentation_stats(&display, &statistics) == R4OS_GFX_OUTPUT_ERROR_STALE);
    assert(r4driver_display_presentation_stats(&display, 0) == R4OS_GFX_OUTPUT_ERROR_INVALID);
}

static uint64_t now_ticks = 100u;
static uint32_t activity_waits;
static uint32_t gui_activity_waits;
static uint32_t last_gui_subscriptions;
static uint32_t clipboard_revision = 7u;
static uint32_t event_index;
static uint32_t draw_count;
static uint32_t present_count;
static uint32_t alpha8_count;
static int32_t alpha8_x;
static int32_t alpha8_y;
static uint32_t alpha8_width;
static uint32_t alpha8_height;
static uint32_t alpha8_stride;
static uint8_t alpha8_first;
static uint32_t frame_begin_count;
static uint32_t frame_append_count;
static uint32_t frame_commit_count;
static uint32_t frame_cancel_count;

static const R4GuiEvent events[] = {
    {.kind = R4_GUI_RAW_EVENT_RESIZE, .window_id = 4, .tick = 10u},
    {.kind = R4_GUI_RAW_EVENT_KEY_DOWN, .window_id = 4, .key = 'A', .modifiers = 2u, .tick = 11u},
    {.kind = R4_GUI_RAW_EVENT_MOUSE_DOWN, .window_id = 4, .x = 8, .y = 9, .buttons = 1u, .tick = 12u},
    {.kind = R4_GUI_RAW_EVENT_MOUSE_UP, .window_id = 4, .x = 10, .y = 11, .tick = 13u},
    {.kind = R4_GUI_RAW_EVENT_MOUSE_MOVE, .window_id = 4, .x = 12, .y = 13, .tick = 14u},
    {.kind = R4_GUI_RAW_EVENT_CLOSE, .window_id = 4, .tick = 15u},
    {.kind = R4_GUI_RAW_EVENT_FOCUS_GAINED, .window_id = 4, .tick = UINT64_C(0x100000010)},
    {.kind = R4_GUI_RAW_EVENT_FOCUS_LOST, .window_id = 4, .tick = UINT64_C(0x100000011)},
    {.kind = R4_GUI_RAW_EVENT_FONT_CHANGED, .window_id = -1},
    {.kind = R4_GUI_RAW_EVENT_INPUT_RESET, .window_id = 4, .key = R4OS_GUI_INPUT_RESET_REASON_OVERFLOW, .tick = UINT64_C(0x100000014)},
    {.kind = 0xfeedu, .window_id = 4, .x = -7, .y = 13, .key = 0x1f642u, .buttons = 3, .modifiers = 9, .tick = UINT64_C(0x100000012)},
};

static uint64_t fake_ticks(void) { return now_ticks; }
static uint32_t close_requested;
static uint32_t fake_should_close(void) { return close_requested; }
static void fake_time_state(R4TimeState *out) {
    *out = (R4TimeState){0};
    out->monotonic_ticks = now_ticks;
    out->monotonic_hz = 1000u;
    out->valid = 1u;
}
static int32_t fake_window_id(void) { return 4; }
static int32_t fake_window_info(R4GuiWindowInfo *out) {
    *out = (R4GuiWindowInfo){0};
    out->window_id = 4;
    out->client_w = 320;
    out->client_h = 200;
    return 0;
}
static int32_t fake_poll_event(R4GuiEvent *out) {
    if (event_index >= sizeof(events) / sizeof(events[0])) return 0;
    *out = events[event_index++];
    return 1;
}
static int32_t fake_set_title(const uint8_t *title) { return title != 0 ? 0 : -1; }
static int32_t fake_set_minimum_size(int32_t width, int32_t height) { return width == 100 && height == 80 ? 0 : -1; }
static uint32_t fake_clipboard_revision(void) { return clipboard_revision; }
static int32_t fake_activity_wait(uint64_t sequence, uint64_t timeout, uint64_t *out_sequence) {
    ++activity_waits;
    now_ticks = UINT64_MAX - now_ticks < timeout ? UINT64_MAX : now_ticks + timeout;
    *out_sequence = sequence;
    return 0;
}
static int32_t fake_gui_activity_wait(uint64_t sequence, uint64_t timeout,
                                      uint32_t subscriptions, uint64_t *out_sequence) {
    assert((subscriptions & ~R4OS_GUI_ACTIVITY_SHARED_ALL) == 0);
    ++gui_activity_waits; last_gui_subscriptions = subscriptions;
    return fake_activity_wait(sequence, timeout, out_sequence);
}
static int32_t fake_clear(uint32_t rgb) { (void)rgb; ++draw_count; return 0; }
static int32_t fake_rect(int32_t x, int32_t y, uint32_t width, uint32_t height, uint32_t rgb) {
    (void)x; (void)y; (void)width; (void)height; (void)rgb; ++draw_count; return 0;
}
static int32_t fake_text(int32_t x, int32_t y, const uint8_t *text, uint32_t fg, uint32_t bg) {
    (void)x; (void)y; (void)text; (void)fg; (void)bg; ++draw_count; return 0;
}
static int32_t fake_alpha8(int32_t x, int32_t y, uint32_t width, uint32_t height,
                           uint32_t stride, uint32_t rgb, const uint8_t *alpha,
                           uint32_t alpha_len) {
    (void)rgb;
    assert(alpha != 0 && alpha_len >= width);
    ++alpha8_count;
    alpha8_x = x;
    alpha8_y = y;
    alpha8_width = width;
    alpha8_height = height;
    alpha8_stride = stride;
    alpha8_first = alpha[0];
    return 0;
}
static int32_t fake_present(void) { ++present_count; return 0; }
static int32_t fake_frame_begin(void) { ++frame_begin_count; return R4OS_GUI_FRAME_RESULT_OK; }
static int32_t fake_frame_append(const R4GuiFrameCommand *commands, uint64_t command_count,
                                 const uint8_t *resources, uint64_t resource_len) {
    ++frame_append_count;
    return (commands == 0 && command_count != 0u) || (resources == 0 && resource_len != 0u)
        ? R4OS_GUI_FRAME_ERROR_INVALID : R4OS_GUI_FRAME_RESULT_OK;
}
static int32_t fake_frame_commit(void) { ++frame_commit_count; return R4OS_GUI_FRAME_RESULT_OK; }
static int32_t fake_frame_cancel(void) { ++frame_cancel_count; return R4OS_GUI_FRAME_RESULT_OK; }
static int32_t fake_frame_info(const R4ProgramProcessHandle *handle, R4GuiFrameInfo *out) {
    if (out->version < R4OS_GUI_FRAME_INFO_VERSION || out->size < R4OS_GUI_FRAME_INFO_SIZE) return R4OS_GUI_FRAME_ERROR_INVALID;
    *out = (R4GuiFrameInfo){0};
    out->version = R4OS_GUI_FRAME_INFO_VERSION;
    out->size = R4OS_GUI_FRAME_INFO_SIZE;
    if (handle != 0) out->owner = *handle;
    out->committed_generation = 7u;
    out->committed_command_count = 1u;
    out->committed_resource_bytes = 4u;
    return R4OS_GUI_FRAME_RESULT_OK;
}
static int32_t fake_frame_read(const R4ProgramProcessHandle *handle, uint64_t expected_generation,
                               R4GuiFrameCommand *commands, uint64_t command_capacity,
                               uint8_t *resources, uint64_t resource_capacity,
                               R4GuiFrameInfo *out) {
    (void)handle;
    if (out->version < R4OS_GUI_FRAME_INFO_VERSION || out->size < R4OS_GUI_FRAME_INFO_SIZE) return R4OS_GUI_FRAME_ERROR_INVALID;
    *out = (R4GuiFrameInfo){0};
    out->version = R4OS_GUI_FRAME_INFO_VERSION;
    out->size = R4OS_GUI_FRAME_INFO_SIZE;
    out->committed_generation = 7u;
    out->committed_command_count = 1u;
    out->committed_resource_bytes = 4u;
    if ((commands == 0 && command_capacity != 0u) ||
        (resources == 0 && resource_capacity != 0u)) return R4OS_GUI_FRAME_ERROR_INVALID;
    if (expected_generation != 7u) return R4OS_GUI_FRAME_ERROR_STALE;
    if (command_capacity < 1u || resource_capacity < 4u) return R4OS_GUI_FRAME_ERROR_BUFFER_TOO_SMALL;
    commands[0] = (R4GuiFrameCommand){0}; commands[0].kind = R4OS_GUI_FRAME_COMMAND_KIND_TEXT; commands[0].resource_bytes = 4u;
    resources[0] = 'R'; resources[1] = '4'; resources[2] = 'O'; resources[3] = 'S';
    return R4OS_GUI_FRAME_RESULT_OK;
}

static R4App make_app(R4XStartR4Sys *sys, R4XStartR4Desk *desk, R4XStartR4Draw *draw, int drawing_available) {
    *sys = (R4XStartR4Sys){0};
    sys->size = sizeof(*sys);
    sys->ticks = (uintptr_t)&fake_ticks;
    sys->time_state = (uintptr_t)&fake_time_state;
    sys->program_should_close = (uintptr_t)&fake_should_close;
    *desk = (R4XStartR4Desk){0};
    desk->size = sizeof(*desk);
    desk->program_window_id = (uintptr_t)&fake_window_id;
    desk->gui_window_info = (uintptr_t)&fake_window_info;
    desk->gui_poll_event = (uintptr_t)&fake_poll_event;
    desk->gui_set_title = (uintptr_t)&fake_set_title;
    desk->gui_set_min_size = (uintptr_t)&fake_set_minimum_size;
    desk->clipboard_revision = (uintptr_t)&fake_clipboard_revision;
    desk->desktop_activity_wait = (uintptr_t)&fake_activity_wait;
    desk->gui_activity_wait = (uintptr_t)&fake_gui_activity_wait;
    *draw = (R4XStartR4Draw){0};
    draw->size = R4XSTART_R4DRAW_SIZE;
    draw->gui_clear = (uintptr_t)&fake_clear;
    draw->gui_rect = (uintptr_t)&fake_rect;
    draw->gui_draw_text = (uintptr_t)&fake_text;
    draw->gui_blend_alpha8 = (uintptr_t)&fake_alpha8;
    if (drawing_available) draw->gui_present = (uintptr_t)&fake_present;
    R4App app = {0};
    app.profile = R4_APP_PROFILE_DESKTOP;
    app.group_mask = (1u << R4L_GROUP_R4SYS) | (1u << R4L_GROUP_R4DESK) | (1u << R4L_GROUP_R4DRAW);
    app.system.table = sys;
    app.desktop.table = desk;
    app.drawing.table = draw;
    return app;
}

static uint32_t stats_probe_bytes = sizeof(R4GfxBufferStats);
static int32_t stats_probe(R4GfxBufferStats *output) {
    assert(output->version == 1 && output->size == 136);
    const R4GfxBufferStats value = {.version=1, .size=stats_probe_bytes, .committed_bytes=UINT64_C(0x100000003), .system_bytes=17, .device_bytes=19};
    memcpy(output, &value, stats_probe_bytes);
    return 1;
}
static int32_t budget_probe_rc = 1;
static int32_t budget_probe(const R4GfxDeviceBudgetRequest *input, R4GfxDeviceBudgetState *output) {
    assert(input->adapter_id == 3 && input->memory_generation == UINT64_C(0x200000007) && output->version == 1 && output->size == 64);
    output->adapter_id = input->adapter_id; output->memory_generation = input->memory_generation;
    output->limit_bytes = UINT64_C(0x400000000); output->charged_bytes = UINT64_C(0x100000003);
    return budget_probe_rc;
}
static void budget_facade_probe(void) {
    _Static_assert(sizeof(R4GfxDeviceBudgetRequest)==32 && sizeof(R4GfxDeviceBudgetState)==64 && offsetof(R4XStartR4Draw,gfx_memory_budget)==800, "memory budget ABI");
    R4GfxDeviceBudgetRequest input = {.version=1,.size=32,.adapter_id=3,.memory_generation=UINT64_C(0x200000007)};
    R4GfxDeviceBudgetState output = {.charged_bytes=79};
    const R4GfxDeviceBudgetState unchanged = output;
    R4GfxDriverMemoryApi memory = {.version=1,.size=192,.memory_budget=(uintptr_t)budget_probe};
    R4XStartR4Draw table = {.size=808,.gfx_memory_budget=(uintptr_t)budget_probe};
    R4Draw draw = {.table=&table};
    for(unsigned n=184;n<192;++n){memory.size=n;assert(r4driver_memory_budget(&memory,&input,&output)==R4OS_ERR_NO_FN);assert(memcmp(&unchanged,&output,sizeof(output))==0);}
    for(unsigned n=800;n<808;++n){table.size=n;assert(r4draw_gfx_memory_budget(&draw,&input,&output)==R4OS_ERR_NO_FN);assert(memcmp(&unchanged,&output,sizeof(output))==0);}
    memory.size=192;table.size=808;budget_probe_rc=R4OS_GFX_BUFFER_ERROR_STALE;
    assert(r4driver_memory_budget(&memory,&input,&output)==budget_probe_rc && memcmp(&unchanged,&output,sizeof(output))==0);
    assert(r4draw_gfx_memory_budget(&draw,&input,&output)==budget_probe_rc && memcmp(&unchanged,&output,sizeof(output))==0);
    budget_probe_rc=1;
    assert(r4driver_memory_budget(&memory,&input,&output)==1 && output.charged_bytes==UINT64_C(0x100000003));
    output=unchanged;
    assert(r4draw_gfx_memory_budget(&draw,&input,&output)==1 && output.limit_bytes==UINT64_C(0x400000000));
}
static int32_t telemetry_probe(const R4GfxTelemetryRequest *input, R4GfxTelemetryState *output) {
    *output = (R4GfxTelemetryState){.version=1, .size=sizeof(*output), .adapter_id=input->adapter_id, .memory_generation=input->memory_generation};
    output->metrics[5] = (R4GfxTelemetryMetric){.status=R4OS_GFX_TELEMETRY_FRESH, .source_stamp=9, .values={-12500,0,0,0}};
    return budget_probe_rc;
}
static int32_t telemetry_driver_probe(const R4GfxTelemetryState *input, R4GfxTelemetryDemand *output) {
    *output = (R4GfxTelemetryDemand){.version=1, .size=sizeof(*output), .adapter_id=input->adapter_id, .memory_generation=input->memory_generation, .metric_mask=0x201, .until_ns=UINT64_C(0x200000001)};
    return budget_probe_rc;
}
static void telemetry_facade_probe(void) {
    R4XStartR4Draw table = {.size=sizeof(table), .gfx_telemetry=(uintptr_t)telemetry_probe};
    R4Draw draw = {.table=&table};
    R4GfxDriverMemoryApi driver = {.version=1, .size=sizeof(driver), .telemetry_exchange=(uintptr_t)telemetry_driver_probe};
    R4GfxTelemetryRequest request = {.version=1, .size=sizeof(request), .adapter_id=3, .memory_generation=UINT64_C(0x200000007), .metric_mask=0x201};
    R4GfxTelemetryState state = {.adapter_id=79}, unchanged = state;
    R4GfxTelemetryDemand demand = {.until_ns=79}, original = demand;
    for(unsigned n=808;n<816;++n){table.size=n;assert(r4draw_gfx_telemetry(&draw,&request,&state)==R4OS_ERR_NO_FN);assert(memcmp(&state,&unchanged,sizeof(state))==0);}
    for(unsigned n=192;n<200;++n){driver.size=n;assert(r4driver_telemetry_exchange(&driver,&state,&demand)==R4OS_ERR_NO_FN);assert(memcmp(&demand,&original,sizeof(demand))==0);}
    table.size=816;driver.size=200;budget_probe_rc=R4OS_GFX_BUFFER_ERROR_STALE;
    assert(r4draw_gfx_telemetry(&draw,&request,&state)==budget_probe_rc && memcmp(&state,&unchanged,sizeof(state))==0);
    assert(r4driver_telemetry_exchange(&driver,&state,&demand)==budget_probe_rc && memcmp(&demand,&original,sizeof(demand))==0);
    budget_probe_rc=1;
    assert(r4draw_gfx_telemetry(&draw,&request,&state)==1 && state.metrics[5].values[0]==-12500 && state.metrics[6].status==R4OS_GFX_TELEMETRY_UNAVAILABLE);
    assert(r4driver_telemetry_exchange(&driver,&state,&demand)==1 && demand.metric_mask==0x201 && demand.until_ns==UINT64_C(0x200000001));
}
static void stats_facade_probe(void) {
    telemetry_facade_probe();
    budget_facade_probe();
    _Static_assert(sizeof(R4GfxBufferStats) == 136 && offsetof(R4GfxBufferStats, system_bytes) == 56, "statistics prefix");
    R4XStartR4Draw table = {.size=sizeof(table), .gfx_buffer_stats=(uintptr_t)stats_probe};
    R4Draw draw = {.table=&table};
    R4GfxBufferStats stats = {.device_bytes=79};
    R4GfxDriverMemoryApi memory = {.version=1, .size=sizeof(memory), .buffer_stats=(uintptr_t)stats_probe};
    const R4GfxBufferStats before_stats=stats;
    const uint32_t short_sizes[]={56,135};
    for(unsigned i=0;i<2;i++) {
        stats_probe_bytes=short_sizes[i];
        assert(r4draw_gfx_buffer_stats(&draw,&stats)==R4OS_GFX_BUFFER_ERROR_INVALID && memcmp(&stats,&before_stats,sizeof(stats))==0);
        assert(r4driver_memory_buffer_stats(&memory,&stats)==R4OS_GFX_BUFFER_ERROR_INVALID && memcmp(&stats,&before_stats,sizeof(stats))==0);
    }
    stats_probe_bytes=sizeof(R4GfxBufferStats);
    assert(r4draw_gfx_buffer_stats(&draw,&stats)==1 && stats.size==136 && stats.committed_bytes==UINT64_C(0x100000003) && stats.system_bytes==17 && stats.device_bytes==19);
    assert(r4driver_memory_buffer_stats(&memory,&stats)==1 && stats.size==136 && stats.system_bytes==17 && stats.device_bytes==19);
}
static int32_t virtual_start_probe(const R4GfxVirtualRequest *input, R4GfxVirtualStatus *output) {
    assert(input->memory_generation == UINT64_C(0x100000035) && input->byte_offset == UINT64_C(0x200000035) && output->size == 80);
    output->address = UINT64_C(0x300000035); return -4;
}
static int32_t virtual_wait_probe(const R4GfxBufferHandle *handle, uint32_t until, uint64_t ticks, R4GfxVirtualStatus *output) {
    assert(handle->generation == UINT64_C(0x400000035) && until == 1 && ticks == UINT64_C(0x500000035) && output->version == 1 && output->size == 80);
    output->address = UINT64_C(0x600000035); return 1;
}
static int32_t virtual_close_probe(const R4GfxBufferHandle *handle, uint32_t mode) {
    assert(handle->generation == UINT64_C(0x400000035) && mode == 1); return 1;
}
static int32_t virtual_take_probe(const R4GfxBufferHandle *provider, R4GfxVirtualJob *output) {
    assert(provider->generation == UINT64_C(0x400000035) && output->version == 1 && output->size == 248);
    output->token.opaque2 = UINT64_C(0x700000035); return -4;
}
static int32_t virtual_complete_probe(const R4GfxBufferHandle *provider, const R4GfxVirtualCompletion *input) {
    assert(provider->generation == UINT64_C(0x400000035) && input->operation == 1 && input->token.opaque2 == UINT64_C(0x800000035)); return 1;
}
static void virtual_facade_probe(void) {
    R4XStartR4Draw table = {.size = sizeof(table), .gfx_virtual_start = (uintptr_t)virtual_start_probe, .gfx_virtual_wait = (uintptr_t)virtual_wait_probe, .gfx_virtual_close = (uintptr_t)virtual_close_probe};
    R4Draw draw = {.table = &table};
    R4GfxBufferHandle handle = {.generation = UINT64_C(0x400000035)};
    R4GfxVirtualRequest input = {.memory_generation = UINT64_C(0x100000035), .byte_offset = UINT64_C(0x200000035)};
    R4GfxVirtualStatus output = {.address = 77};
    for (unsigned size = 832; size < 840; ++size) {
        table.size = size; assert(r4draw_gfx_virtual_start(&draw, &input, &output) == R4OS_ERR_NO_FN && output.address == 77);
    }
    table.size = 840; assert(r4draw_gfx_virtual_start(&draw, &input, &output) == -4 && output.address == 77);
    for (unsigned size = 856; size < 864; ++size) {
        table.size = size; assert(r4draw_gfx_virtual_wait(&draw, &handle, 1, UINT64_C(0x500000035), &output) == R4OS_ERR_NO_FN);
    }
    table.size = 864;
    assert(r4draw_gfx_virtual_wait(&draw, &handle, 1, UINT64_C(0x500000035), &output) == 1 && output.address == UINT64_C(0x600000035));
    assert(r4draw_gfx_virtual_close(&draw, &handle, 1) == 1);
    R4GfxDriverMemoryApi driver = {.version = 1, .size = sizeof(driver), .virtual_take = (uintptr_t)virtual_take_probe, .virtual_complete = (uintptr_t)virtual_complete_probe};
    R4GfxVirtualCompletion completion = {.operation = 1, .token = {.opaque2 = UINT64_C(0x800000035)}};
    for (unsigned size = 232; size < 240; ++size) {
        driver.size = size; assert(r4driver_memory_virtual_complete(&driver, &handle, &completion) == R4OS_ERR_NO_FN);
    }
    driver.size = 240; assert(r4driver_memory_virtual_complete(&driver, &handle, &completion) == 1);
    R4GfxVirtualJob job = {.token = {.opaque2 = 79}}, saved = job;
    assert(r4driver_memory_virtual_take(&driver, &handle, &job) == -4 && memcmp(&job, &saved, sizeof(job)) == 0);
}
static uint32_t current_byte_reads, current_codepoint_reads;
static uint8_t current_byte_read(void) { ++current_byte_reads; return 'A'; }
static uint32_t current_codepoint_read(void) { ++current_codepoint_reads; return 0x1F642u; }
static void test_current_codepoint_contract(void) {
    current_byte_reads = current_codepoint_reads = 0u;
    R4XStartR4Desk table = {0}; table.size = sizeof(table); table.read_key = (uintptr_t)&current_byte_read;
    R4Desk desk = {&table};
    assert(r4desk_read_key_codepoint(&desk) == 0u && current_byte_reads == 0u);
    table.read_key_codepoint = (uintptr_t)&current_codepoint_read;
    table.size = offsetof(R4XStartR4Desk, read_key_codepoint);
    assert(r4desk_read_key_codepoint(&desk) == 0u && current_codepoint_reads == 0u);
    table.size = sizeof(table);
    assert(r4desk_read_key_codepoint(&desk) == 0x1F642u && current_codepoint_reads == 1u && current_byte_reads == 0u);
}

int main(void) {
    test_current_codepoint_contract();
    virtual_facade_probe();
    capture_facade_probe();
    stats_facade_probe();
    cursor_facade_probe();
    gfx_facade_probe();
    R4XStartR4Sys sys;
    R4XStartR4Desk desk;
    R4XStartR4Draw draw;
    R4App app = make_app(&sys, &desk, &draw, 1);
    draw.magic = R4XSTART_R4DRAW_MAGIC;
    draw.abi_version = 10;
    draw.size = offsetof(R4XStartR4Draw, gfx_queue_open);
    const R4XStartImport draw_import = {.group_id = R4L_GROUP_R4DRAW, .flags = R4XSTART_IMPORT_FLAG_GROUP_INTERFACE, .table = (uintptr_t)&draw};
    const R4XStartContext old_start = {.magic = R4XSTART_MAGIC, .abi_major = R4XSTART_ABI_MAJOR, .size = sizeof(R4XStartContext), .flags = R4XSTART_FLAG_IMPORTS_VALID, .imports = (uintptr_t)&draw_import, .import_count = 1};
    R4Draw old_draw;
    assert(r4draw_init(&old_start, &old_draw) == R4OS_OK);
    R4GfxQueueConfig old_config = {0};
    R4GfxQueueHandle untouched = {.timeline = 77};
    assert(r4draw_gfx_queue_open(&old_draw, &old_config, &untouched) == R4OS_ERR_NO_FN && untouched.timeline == 77);
    draw.size = R4XSTART_R4DRAW_SIZE;
    R4Timer timers[1] = {{0}};
    R4Window window;
    assert(r4_window_open(&app, timers, 1u, &window));
    assert(r4_window_set_title(&window, "Test") == 0);
    assert(r4_window_set_minimum_size(&window, 100, 80) == 0);

    R4Message message;
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_RESIZE && message.value.resize.width == 320);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_KEY && message.value.key.key == 'A' && message.value.key.codepoint == 'A');
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_MOUSE && message.value.mouse.action == R4_MOUSE_DOWN);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_MOUSE && message.value.mouse.action == R4_MOUSE_UP);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_MOUSE && message.value.mouse.action == R4_MOUSE_MOVE);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_CLOSE && message.value.close_window_id == 4);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_FOCUS_GAINED && message.value.focus.window_id == 4 && message.value.focus.tick == UINT64_C(0x100000010));
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_FOCUS_LOST && message.value.focus.window_id == 4 && message.value.focus.tick == UINT64_C(0x100000011));
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_FONT_CHANGED && message.value.font_changed.window_id == -1 && message.value.font_changed.tick == 0);
    assert(r4_event_loop_poll(&window.events,&message) && message.kind==R4_MESSAGE_INPUT_RESET && message.value.input_reset.window_id==4 && message.value.input_reset.reason==R4OS_GUI_INPUT_RESET_REASON_OVERFLOW && message.value.input_reset.tick==UINT64_C(0x100000014));
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_UNKNOWN && memcmp(&message.value.unknown, &events[10], sizeof(R4GuiEvent)) == 0);
    close_requested=1;
    for(unsigned i=0;i<100;i++)assert(!r4_event_loop_poll(&window.events,&message));
    close_requested=0;assert(!r4_event_loop_poll(&window.events,&message));
    close_requested=1;assert(r4_event_loop_poll(&window.events,&message) && message.kind==R4_MESSAGE_CLOSE);
    assert(!r4_event_loop_poll(&window.events,&message));close_requested=0;

    R4PaintContext paint;
    assert(!r4_window_begin_paint(&window, &paint));
    assert(draw_count == 0u && present_count == 0u && frame_begin_count == 0u);

    draw.gui_frame_begin = (uintptr_t)&fake_frame_begin;
    draw.gui_frame_append = (uintptr_t)&fake_frame_append;
    draw.gui_frame_commit = (uintptr_t)&fake_frame_commit;
    draw.gui_frame_cancel = (uintptr_t)&fake_frame_cancel;
    draw.gui_frame_info = (uintptr_t)&fake_frame_info;
    draw.gui_frame_read = (uintptr_t)&fake_frame_read;
    assert(r4draw_supports_gui_frame_contract(&app.drawing));
    assert(r4_window_begin_paint(&window, &paint));
    R4Canvas canvas = r4_paint_canvas(&paint);
    assert(r4_canvas_clear(canvas, 0u) == 0);
    assert(r4_canvas_rect(canvas, 1, 2, 3u, 4u, 0xFFFFFFu) == 0);
    const uint8_t alpha8[] = {10u, 20u, 30u, 99u, 40u, 50u, 60u};
    assert(r4_canvas_blend_alpha8(canvas, -1, -1, 3u, 2u, 4u, 0x336699u,
                                  alpha8, sizeof(alpha8)) == 0);
    assert(alpha8_count == 1u && alpha8_x == 0 && alpha8_y == 0);
    assert(alpha8_width == 2u && alpha8_height == 1u && alpha8_stride == 4u);
    assert(alpha8_first == 50u);
    R4GuiFrameCommand command = {0}; command.version = R4OS_GUI_FRAME_COMMAND_VERSION; command.size = R4OS_GUI_FRAME_COMMAND_SIZE; command.kind = R4OS_GUI_FRAME_COMMAND_KIND_TEXT; command.resource_bytes = 4u;
    assert(r4draw_gui_frame_append(&app.drawing, &command, 1u, (const uint8_t *)"R4OS", 4u) == R4OS_GUI_FRAME_RESULT_OK);
    assert(r4draw_gui_frame_append(&app.drawing, 0, 1u, 0, 0u) == R4OS_GUI_FRAME_ERROR_INVALID);
    assert(frame_append_count == 2u);
    assert(r4_paint_present(&paint) == R4OS_GUI_FRAME_RESULT_OK);
    assert(frame_begin_count == 1u && frame_commit_count == 1u);
    assert(r4_paint_present(&paint) == R4OS_ERR_NO_FN);
    assert(draw_count >= 2u && present_count == 0u);
    R4ProgramProcessHandle handle = {0}; handle.instance_id = 4u; handle.generation = 9u;
    R4GuiFrameInfo frame_info = {0};
    assert(r4draw_gui_frame_info(&app.drawing, &handle, &frame_info) == R4OS_GUI_FRAME_RESULT_OK);
    assert(frame_info.version == R4OS_GUI_FRAME_INFO_VERSION && frame_info.size == R4OS_GUI_FRAME_INFO_SIZE);
    R4GuiFrameCommand snapshot_commands[1] = {{0}}; uint8_t snapshot_resources[4] = {0};
    frame_info.version = 0u; frame_info.size = 0u;
    assert(r4draw_gui_frame_read(&app.drawing, &handle, frame_info.committed_generation, snapshot_commands, 1u, snapshot_resources, 4u, &frame_info) == R4OS_GUI_FRAME_RESULT_OK);
    assert(snapshot_resources[0] == 'R' && snapshot_resources[3] == 'S');
    frame_info = (R4GuiFrameInfo){0};
    assert(r4draw_gui_frame_read(&app.drawing, &handle, 7u, 0, 1u, snapshot_resources, 4u, &frame_info) == R4OS_GUI_FRAME_ERROR_INVALID);
    assert(frame_info.version == R4OS_GUI_FRAME_INFO_VERSION && frame_info.size == R4OS_GUI_FRAME_INFO_SIZE && frame_info.committed_command_count == 1u);
    assert(r4_window_begin_paint(&window, &paint)); r4_paint_discard(&paint); assert(frame_cancel_count == 1u);

    assert(r4_event_loop_post_command(&window.events, (R4CommandId){42u}));
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_COMMAND && message.value.command.value == 42u);
    clipboard_revision = 8u;
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_CLIPBOARD && message.value.clipboard.revision == 8u);
    assert(r4_timer_start(&timers[0], &app, (R4TimerId){9u}, (R4Duration){2000000u}, 0));
    uint32_t gui_waits_before = gui_activity_waits;
    R4MessageNext next = r4_window_wait_message(&window, r4_timeout_finite((R4Duration){10000000u}));
    assert(next.state == R4_MESSAGE_NEXT_MESSAGE && next.message.kind == R4_MESSAGE_TIMER && next.message.value.timer.id.value == 9u);
    assert(activity_waits > 0u);
    assert(gui_activity_waits > gui_waits_before);
    assert(last_gui_subscriptions == R4OS_GUI_ACTIVITY_SHARED_CLIPBOARD);
    assert(r4_window_wait_message(&window, r4_timeout_poll()).state == R4_MESSAGE_NEXT_TIMED_OUT);
    timers[0]=(R4Timer){.id={17},.deadline_tick=0,.interval_ticks=1,.active=1};now_ticks=UINT64_MAX;
    assert(r4_event_loop_poll(&window.events,&message) && message.kind==R4_MESSAGE_TIMER && timers[0].deadline_tick==UINT64_MAX);
    uint32_t full_sys_size=sys.size;sys.size=offsetof(R4XStartR4Sys,time_state);
    assert(r4_gui_monotonic_hz(&app)==0);sys.size=full_sys_size;

    R4App missing_draw = make_app(&sys, &desk, &draw, 0);
    assert(!r4_window_open(&missing_draw, timers, 1u, &window));
    return 0;
}
