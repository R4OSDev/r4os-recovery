/* Existing C compatibility cases and the original Zig callback/pixel oracle.
 * Assertions remain enabled in optimized builds. No separate renderer. */
#define main sdk_gui_legacy_c_case
#include "../Conformance/GuiFacadePrototype05824.c"
#undef main
#include "PointerBindings.c"
#include <r4os/gui_bridge.h>
#include <r4os/poll_budget.h>

int32_t sdk_gui_clipboard_formats_no_provider(void) {
    R4SdkGuiType0 clipboard;
    const uint8_t image[20] = {1, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0x33, 0x22, 0x11, 0};
    uint8_t scratch[20];
    memset(scratch, 0xa5, sizeof(scratch));
    assert(R4SdkGuiType0_create(&clipboard).status == 0);
    R4SdkGuiSlot copied = R4SdkGuiType0_copyFormat(0, &clipboard, R4OS_CLIPBOARD_OFFER_FORMAT_XRGB32, image, sizeof(image));
    assert(copied.status == 0 && (int32_t)copied.bits == R4OS_CLIPBOARD_OFFER_ERROR_CLOSED);
    R4SdkGuiSlot read = R4SdkGuiType0_readFormat(0, &clipboard, R4OS_CLIPBOARD_OFFER_FORMAT_XRGB32, scratch, sizeof(scratch));
    assert(read.status == 0 && (int32_t)read.bits == R4OS_CLIPBOARD_OFFER_ERROR_CLOSED);
    for (size_t index = 0; index < sizeof(scratch); ++index) assert(scratch[index] == 0xa5);
    R4SdkGuiSlot closed = R4SdkGuiType0_close(0, &clipboard);
    assert(closed.status == 0 && (int32_t)closed.bits == 0);
    return 0;
}

static uint32_t control_offer_calls;
static int32_t control_offer_clock(R4MonotonicClockInfo *out){
    *out=(R4MonotonicClockInfo){.version=1,.size=sizeof(*out),.flags=R4OS_MONOTONIC_CLOCK_FLAG_VALID,.source=1,.generation=9,.frequency_hz=1000000000,.resolution_ns=1,.instant_ns=1000000000,.event_requested_hz=1000,.event_effective_hz=1001};return 1;
}
static int32_t control_offer_call(uint32_t handle,uint16_t op,const uint8_t *request,uint32_t length,R4ServiceMessageHeader *header,uint8_t *output,uint32_t capacity,uint64_t timeout){
    (void)output;(void)capacity;
    assert(handle==31 && timeout==12345);
    assert(length>=sizeof(R4ClipboardOfferTransfer));
    R4ClipboardOfferTransfer transfer;memcpy(&transfer,request,sizeof(transfer));
    assert(transfer.version==1 && transfer.size==sizeof(transfer) && transfer.provider==UINT64_C(0x100000007) && transfer.id==UINT64_C(0x200000009));
    assert(!transfer.item && transfer.format==R4OS_CLIPBOARD_OFFER_FORMAT_TEXT_UTF8 && !transfer.offset && transfer.total_bytes==9);
    if(op==R4OS_CLIPBOARD_OFFER_OP_DECLARE){assert(!control_offer_calls && length==sizeof(transfer));}
    else{assert(op==R4OS_CLIPBOARD_OFFER_OP_PUT && control_offer_calls==1 && length==sizeof(transfer)+9 && !memcmp(request+sizeof(transfer),"iWe\xcc\x81\xf0\x9f\x99\x82",9));}
    ++control_offer_calls;*header=(R4ServiceMessageHeader){0};return 0;
}
static int32_t control_offer_close(uint32_t handle){assert(handle==31);return 0;}
int sdk_gui_control_clipboard_case(void){
    uint8_t bytes[64];R4SdkGuiTextField field;
    R4SdkGuiSlot opened=R4SdkGui_borrowedTextField(0,bytes,sizeof(bytes),&field);
    assert(!opened.status && (opened.flags&R4SDK_GUI_PRESENT));
    static const uint8_t text[]="iWe\xcc\x81\xf0\x9f\x99\x82";
    R4SdkGuiSlot set=R4SdkGuiTextField_setExact(0,&field,text,9);
    assert(!set.status && set.bits==1);
    R4SdkClipboardOffers client={.call=control_offer_call,.close=control_offer_close,.handle=31,.timeout_ticks=12345,.clock=control_offer_clock};
    R4ClipboardOfferLease lease={.version=1,.size=sizeof(lease),.provider=UINT64_C(0x100000007),.id=UINT64_C(0x200000009),.revision=4,.expires_ns=5,.state=R4OS_CLIPBOARD_OFFER_STATE_WRITING};
    control_offer_calls=0;
    R4SdkGuiSlot staged=R4SdkGuiTextField_stageSelection(0,&field,&client,&lease);
    assert(!staged.status && (int32_t)staged.bits==0 && control_offer_calls==2);
    client.handle=0;
    staged=R4SdkGuiTextField_stageSelection(0,&field,&client,&lease);
    assert(!staged.status && (int32_t)staged.bits==R4OS_CLIPBOARD_OFFER_ERROR_CLOSED && control_offer_calls==2);
    R4SdkGuiSlot value=R4SdkGuiTextField_value(0,&field);
    assert(!value.status && value.length==9 && !memcmp(value.ptr,text,9));
    return 0;
}
int sdk_budget_c_case(void) {
    uint64_t ticks=77;
    assert(R4SdkMillisecondsToTicksChecked(100,333,&ticks)==0 && ticks==34);
    assert(R4SdkMillisecondsToTicksChecked(UINT64_MAX,1000,&ticks)==0 && ticks==UINT64_MAX);
    assert(R4SdkMillisecondsToTicksChecked(UINT64_MAX,1001,&ticks)==R4_BUDGET_OVERFLOW && ticks==UINT64_MAX);
    assert(R4SdkMillisecondsToTicksChecked(0,0,&ticks)==R4_BUDGET_UNKNOWN_FREQUENCY && ticks==UINT64_MAX);
    R4SdkBudgetValue value={7,8,9};
    R4Timeout finite={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=UINT64_MAX};
    assert(R4SdkTimeoutTicksChecked(finite,1000000000,&value)==0 && value.kind==R4_BUDGET_FINITE && value.value==UINT64_MAX);
    R4MonotonicClockInfo info={.version=1,.size=sizeof(info),.flags=R4OS_MONOTONIC_CLOCK_FLAG_VALID,.source=1,.generation=9,.frequency_hz=1000000000,.resolution_ns=1,.instant_ns=100,.event_requested_hz=333,.event_effective_hz=334};
    R4SdkClockSample sample;
    assert(R4SdkClockSampleRead(&info,&sample)==0 && sample.identity.tick_hz==333);
    R4SdkDeadlineBudget deadline;
    finite.nanoseconds=10;
    assert(R4SdkDeadlineBudgetInit(sample,finite,&deadline)==0);
    R4SdkClockSample next=sample;next.identity.generation=10;
    R4SdkDeadlineBudget before=deadline;
    value=(R4SdkBudgetValue){7,8,9};
    assert(R4SdkDeadlineBudgetRemaining(&deadline,next,&value)==R4_BUDGET_CLOCK_CHANGED);
    assert(memcmp(&deadline,&before,sizeof(deadline))==0 && value.kind==7 && value.reserved==8 && value.value==9);
    next=sample;next.instant_ns=109;
    assert(R4SdkDeadlineBudgetRemaining(&deadline,next,&value)==0 && value.kind==R4_BUDGET_FINITE && value.value==1);
    assert(R4SdkDeadlineBudgetRemaining(&deadline,sample,&value)==R4_BUDGET_CLOCK_REGRESSED);
    R4SdkDriverPollBudget spin;
    assert(R4SdkDriverPollTimed(sample,finite,32,R4_POLL_IRQ,&spin)==0);
    for(unsigned i=0;i<32;++i) assert(R4SdkDriverPollStep(&spin,&sample,0)==R4_POLL_PROCEED);
    assert(R4SdkDriverPollStep(&spin,&sample,0)==R4_POLL_EXPIRED);
    assert(R4SdkDriverPollStep(&spin,&sample,1)==R4_POLL_EXPIRED);
    assert(R4SdkDriverPollIterations(1,R4_POLL_NO_SLEEP,&spin)==0);
    assert(R4SdkDriverPollStep(&spin,0,1)==R4_POLL_STOP);
    assert(R4SdkDriverPollStep(&spin,0,0)==R4_POLL_STOP);
    return 0;
}
extern void sdk_gui_oracle_tables(R4XStartR4Sys2 *,R4XStartR4Desk2 *,R4XStartR4Draw2 *);
extern int32_t sdk_gui_oracle_pixels(uint32_t *,uintptr_t);
extern void sdk_gui_oracle_fail_append(uint32_t);
extern uint32_t sdk_gui_oracle_cancelled(void);
extern uint64_t sdk_gui_modern_hash(void);
static uint32_t shared_live,shared_releases;
static uint32_t legacy_rows,font_revision_value;
static uintptr_t replacement_begin;
static uint32_t replacement_calls;
static int32_t replacement_probe(const R4DisplayDamageRect *regions,uint32_t count){
    assert(count==1 && regions[0].x==10 && regions[0].y==10 && regions[0].w==120 && regions[0].h==32);
    ++replacement_calls;
    return ((int32_t (*)(void))replacement_begin)();
}
static uint32_t revision_probe(void){return font_revision_value;}
static uint64_t legacy_row_probe(uint32_t id,uint32_t cp,uint32_t row){(void)id;(void)cp;(void)row;++legacy_rows;return UINT64_MAX;}
static int32_t font_info_probe(uint32_t id,R4GuiFontInfo *out){out->id=id;out->width=8;out->height=8;out->max_advance=8;out->line_height=8;return 1;}
static int32_t shared_acquire(const R4ProgramProcessHandle *owner,uint64_t frame,const R4GuiSharedRasterHandle *handle,uint64_t generation,R4GuiSharedRasterMap *out){
    assert(owner->instance_id==42 && owner->generation==UINT64_C(0x100000007) && frame==UINT64_C(0x200000009));
    assert(handle->id==UINT64_C(0x300000003) && handle->generation==UINT64_C(0x400000005) && out->version==1 && out->size==sizeof(*out));
    if(generation!=UINT64_C(0x500000009))return -4;
    assert(!shared_live);shared_live=1;
    *out=(R4GuiSharedRasterMap){.version=1,.size=sizeof(*out),.frame_owner=*owner,.frame_generation=frame,.lease={.version=1,.size=sizeof(R4GuiSharedRasterLease),.handle=*handle,.raster_generation=generation,.lease_token=UINT64_C(0x60000000b)}};
    return 0;
}
static int32_t shared_release(const R4GuiSharedRasterLease *lease){
    assert(shared_live && lease->handle.id==UINT64_C(0x300000003) && lease->handle.generation==UINT64_C(0x400000005) && lease->raster_generation==UINT64_C(0x500000009) && lease->lease_token==UINT64_C(0x60000000b));
    if(++shared_releases==1)return -3;
    shared_live=0;return 0;
}
void sdk_gui_native_tables(R4XStartR4Sys2 *sys,R4XStartR4Desk2 *desk,R4XStartR4Draw2 *draw){
    sdk_gui_oracle_tables(sys,desk,draw);shared_live=shared_releases=0;
    replacement_begin=draw->gui_frame_begin;replacement_calls=0;
    draw->gui_frame_begin_replace=(uintptr_t)replacement_probe;
    desk->remote_frame_snapshot_acquire=(uintptr_t)capture_acquire_probe;desk->remote_frame_snapshot_release=(uintptr_t)capture_release_probe;
    draw->gui_shared_raster_acquire=(uintptr_t)shared_acquire;draw->gui_shared_raster_release=(uintptr_t)shared_release;
    draw->font_info=(uintptr_t)font_info_probe;draw->font_glyph_row=(uintptr_t)legacy_row_probe;
    legacy_rows=0;font_revision_value=0;
    desk->gui_host_input=(uintptr_t)host_input_probe;
    desk->gui_pointer_capture_info=(uintptr_t)pointer_info;desk->gui_pointer_capture_acquire=(uintptr_t)pointer_acquire;desk->gui_pointer_capture_release=(uintptr_t)pointer_release;
}
static uint32_t host_mode,host_opens,host_closes,host_calls,host_window_queries;
static int32_t host_window_id(void){++host_window_queries;return -1;}
static int32_t host_handle(uint32_t id,R4ProgramProcessHandle *out){
    assert(id==42);*out=(R4ProgramProcessHandle){.instance_id=id,.generation=UINT64_C(0x100000007)};return R4OS_PROGRAM_HANDLE_OK;
}
static int32_t host_open(const uint8_t *name,R4ServiceInfo *out){assert(strcmp((const char *)name,"WINSVC")==0);out->handle=1000+(++host_opens);return 0;}
static int32_t host_close(uint32_t handle){assert(handle>=1001);++host_closes;return 0;}
static int32_t host_call(uint32_t handle,uint16_t op,const uint8_t *data,uint32_t length,R4ServiceMessageHeader *header,uint8_t *output,uint32_t capacity,uint64_t timeout){
    assert(handle>=1001 && op==R4OS_TRAY_SERVICE_OP_DESKTOP_SYNC && length==sizeof(R4TrayDesktopExchange) && capacity==sizeof(R4TrayDesktopExchange) && timeout==250);
    ++host_calls;
    const R4TrayDesktopExchange *request=(const void *)data;
    assert(request->desktop_owner.instance_id==42 && request->desktop_owner.generation==UINT64_C(0x100000007));
    R4TrayDesktopExchange *out=(void *)output;*out=*request;
    out->desktop_epoch=request->desktop_owner.generation;
    if(host_mode==1)out->desktop_owner.generation++;
    if(host_mode==2)return -9;
    if(host_mode==3)out->desktop_epoch--;
    header->status=0;return sizeof(*out);
}
void sdk_gui_host_tables(R4XStartR4Sys2 *sys,R4XStartR4Desk2 *desk,R4XStartR4Draw2 *draw){
    sdk_gui_oracle_tables(sys,desk,draw);
    sys->program_open_handle=(uintptr_t)host_handle;sys->service_open=(uintptr_t)host_open;sys->service_close=(uintptr_t)host_close;sys->service_call=(uintptr_t)host_call;
    desk->program_window_id=(uintptr_t)host_window_id;
    host_mode=host_opens=host_closes=host_calls=host_window_queries=0;
}
void sdk_gui_host_mode(uint32_t mode){host_mode=mode;}
uint32_t sdk_gui_host_count(uint32_t kind){return kind==0?host_opens:kind==1?host_closes:kind==2?host_calls:host_window_queries;}
static void checked(R4SdkGuiSlot value){assert(value.status==0 && !(value.flags&R4SDK_GUI_NATIVE_ERROR));}
static void status(R4SdkGuiSlot value){checked(value);assert((int32_t)value.bits>=0);}
static R4XStartContext2 start_for(R4XStartR4Sys2 *sys,R4XStartR4Desk2 *desk,R4XStartR4Draw2 *draw,R4XStartImport imports[3]){
    imports[0]=(R4XStartImport){.min_version=2,.resolved_version=2,.group_id=R4L_GROUP_R4SYS,.flags=R4XSTART_IMPORT_FLAG_GROUP_INTERFACE,.table=(uintptr_t)sys};
    imports[1]=(R4XStartImport){.min_version=2,.resolved_version=2,.group_id=R4L_GROUP_R4DESK,.flags=R4XSTART_IMPORT_FLAG_GROUP_INTERFACE,.table=(uintptr_t)desk};
    imports[2]=(R4XStartImport){.min_version=2,.resolved_version=2,.group_id=R4L_GROUP_R4DRAW,.flags=R4XSTART_IMPORT_FLAG_GROUP_INTERFACE,.table=(uintptr_t)draw};
    return (R4XStartContext2){.magic=R4OS2_START_MAGIC,.abi_major=2u,.size=sizeof(R4XStartContext2),.app_class=R4XSTART_APP_CLASS_GUI,.instance_id=42,.flags=R4XSTART_FLAG_IMPORTS_VALID,.imports=(uintptr_t)imports,.import_count=3};
}
uint64_t sdk_gui_modern_c_case(void){
    R4XStartR4Sys2 sys;R4XStartR4Desk2 desk;R4XStartR4Draw2 draw;R4XStartImport imports[3];
    sdk_gui_native_tables(&sys,&desk,&draw);R4XStartContext2 start=start_for(&sys,&desk,&draw,imports);
    R4SdkGuiSession s;R4SdkGuiTimer timer;
    assert(R4SdkGuiSessionOpen2(&s,&start,0,&timer,1)==0);
    R4SdkGuiStyle style;checked(R4SdkGuiStyle_light(0,&style));
    R4SdkGuiFontMetrics metrics;checked(R4SdkGuiFontMetrics_create(&metrics));
    R4SdkGuiCanvas legacy;
    checked(R4SdkGuiCanvas_from_fields(&legacy,R4SdkGuiSessionDraw(&s),320,200,&metrics,(R4SdkGuiSlot){0}));
    R4SdkGuiSlot absent=R4SdkGuiCanvas_get_style(&legacy,&style);
    checked(absent);assert(!(absent.flags&R4SDK_GUI_PRESENT));
    R4SdkGuiRect area;checked(R4SdkGuiRect_from_fields(&area,10,10,120,32));
    R4SdkGuiPalette palette;checked(R4SdkGuiPalette_create(&palette));
    R4SdkGuiTabBar old_tabs;
    checked(R4SdkGuiTabBar_from_fields(&old_tabs,&area,0,0,0,(R4SdkGuiSlot){0},0,22,&palette));
    R4SdkGuiSlot advance=R4SdkGuiTabBar_get_text_advance(&old_tabs);checked(advance);assert(advance.bits==8);
    R4GuiFrameCommand commands[16];uint8_t resources[2048],scratch[64];
    assert(R4SdkGuiSessionBegin(&s,commands,16,resources,sizeof resources)==0);
    R4SdkGuiCanvas *canvas=R4SdkGuiSessionCanvas(&s);assert(canvas);
    status(R4SdkGuiCanvas_setStyle(0,canvas,&style));
    status(R4SdkGuiCanvas_actionButton(0,canvas,&area,(const uint8_t *)"Modern",6,R4SdkGuiButtonState_normal,1,1,scratch,sizeof scratch));
    checked(R4SdkGuiRect_from_fields(&area,10,60,120,12));
    status(R4SdkGuiCanvas_progressBar(0,canvas,&area,25,100,0,0));
    assert(R4SdkGuiSessionEnd(&s,1)==0);
    uint64_t result=sdk_gui_modern_hash();assert(result!=0);
    R4DisplayDamageRect region={.x=10,.y=10,.w=120,.h=32};
    R4SdkGuiPaintOpen opened;R4SdkGuiPaintContext regional;
    checked(R4SdkGuiWindow_beginPaintReplace(0,R4SdkGuiSessionWindow(&s),320,200,&region,1,&opened));
    checked(R4SdkGuiPaintOpen_get_paint(&opened,&regional));
    checked(R4SdkGuiPaintContext_discard(0,&regional));assert(replacement_calls==1);
    checked(R4SdkAppGui_beginPaintReplaceForSize(0,R4SdkGuiSessionDraw(&s),320,200,&region,1,&opened));
    checked(R4SdkGuiPaintOpen_get_paint(&opened,&regional));
    checked(R4SdkGuiPaintContext_discard(0,&regional));assert(replacement_calls==2);
    draw.gui_frame_begin_replace=0;
    checked(R4SdkAppGui_beginPaintReplaceForSize(0,R4SdkGuiSessionDraw(&s),320,200,&region,1,&opened));
    R4SdkGuiSlot missing=R4SdkGuiPaintOpen_get_failure(&opened);checked(missing);assert((int32_t)missing.bits==R4OS_ERR_NO_FN);
    R4SdkGuiSessionClose(&s);return result;
}
int32_t sdk_gui_c_case(void){
    assert(sdk_gui_legacy_c_case()==0);
    R4XStartR4Sys2 sys;R4XStartR4Desk2 desk;R4XStartR4Draw2 draw;R4XStartImport imports[3];
    sdk_gui_native_tables(&sys,&desk,&draw);R4XStartContext2 start=start_for(&sys,&desk,&draw,imports);
    R4SdkGuiSession s;R4SdkGuiTimer timer;
    assert(R4SdkGuiSessionOpen2(&s,&start,0,&timer,1)==0);
    assert(R4SdkGuiDrawContext_fontRevision(0,R4SdkGuiSessionDraw(&s)).status==R4OS_ERR_NO_FN);
    R4GuiGlyphBitmap bitmap={0};assert(R4SdkGuiDrawContext_fontGlyphBitmap(0,R4SdkGuiSessionDraw(&s),0,'A',&bitmap).status==R4OS_ERR_NO_FN && legacy_rows==0);
    R4GuiHostInputRequest input_request={.window=pointer_identity(),.operation=R4OS_GUI_HOST_INPUT_OPERATION_POST,
        .event={.kind=R4_GUI_RAW_EVENT_MOUSE_UP,.x=-701,.tick=UINT64_C(0x8000000000000009)}};
    R4GuiPointerWindowIdentity identity=pointer_identity(),untouched=identity;
    uint32_t previous_input_calls=input_calls;
    R4SdkGuiSlot reply=R4SdkGuiDesktopContext_guiHostInput(0,R4SdkGuiSessionDesktop(&s),&input_request,&identity);
    assert(reply.status==0 && (int32_t)reply.bits==R4OS_GUI_HOST_INPUT_ERROR_BUSY && input_calls==previous_input_calls+1);
    assert(!memcmp(&identity,&untouched,sizeof identity));
    R4Timeout poll={.kind=R4OS_TIMEOUT_KIND_POLL};R4SdkGuiEvent event;
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==2 && event.width==320);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==3 && event.codepoint==0x1f642);
    for(unsigned kind=4;kind<=6;kind++)assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==kind);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==1);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==R4SdkGuiEventKind_focus_gained && event.window_id==4 && event.tick==UINT64_C(0x100000010));
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==R4SdkGuiEventKind_focus_lost && event.window_id==4 && event.tick==UINT64_C(0x100000011));
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==R4SdkGuiEventKind_font_changed && event.window_id==-1 && event.tick==0);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==R4SdkGuiEventKind_input_reset && event.window_id==4 && event.id==R4OS_GUI_INPUT_RESET_REASON_OVERFLOW && event.tick==UINT64_C(0x100000014) && event.raw.kind==R4_GUI_RAW_EVENT_INPUT_RESET);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==R4SdkGuiEventKind_unknown && memcmp(&event.raw,&events[10],sizeof(event.raw))==0);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==0);
    assert(R4SdkGuiSessionCommand(&s,42)==0);assert(R4SdkGuiSessionCommand(&s,43)<0);
    assert(R4SdkGuiSessionNext(&s,&poll,&event)==1 && event.kind==7 && event.id==42);
    R4Duration delay={.nanoseconds=2000000};assert(R4SdkGuiSessionTimer(&s,0,7,&delay,0)==0);
    R4Timeout wait={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=10000000};
    assert(R4SdkGuiSessionNext(&s,&wait,&event)==1 && event.kind==9 && event.id==7);
    R4GuiFrameCommand commands[8];uint8_t resources[64];
    assert(R4SdkGuiSessionBegin(&s,commands,8,resources,64)==0);
    assert(R4SdkGuiSessionBegin(&s,commands,8,resources,64)<0);
    R4SdkGuiCanvas *canvas=R4SdkGuiSessionCanvas(&s);assert(canvas);
    status(R4SdkGuiCanvas_clear(0,canvas,0));
    R4SdkGuiRect rect;checked(R4SdkGuiRect_from_fields(&rect,2,1,2,1));status(R4SdkGuiCanvas_rect(0,canvas,&rect,0xcc0000));
    const uint32_t pixels[]={0xaa112233,0xff445566};status(R4SdkGuiCanvas_raster(0,canvas,0,0,2,1,1,pixels,2));
    const uint8_t alpha[]={0,255,77,255,0};status(R4SdkGuiCanvas_blendAlpha8(0,canvas,0,1,2,2,3,0xffffff,alpha,5));
    checked(R4SdkGuiRect_from_fields(&rect,3,2,1,1));status(R4SdkGuiCanvas_rect(0,canvas,&rect,0x010203));
    assert(R4SdkGuiSessionEnd(&s,1)==0);assert(R4SdkGuiSessionEnd(&s,1)<0);
    uint32_t output[12];const uint32_t expected[]={0x112233,0x445566,0,0,0,0xffffff,0xcc0000,0xcc0000,0xffffff,0,0,0x010203};
    assert(sdk_gui_oracle_pixels(output,12)==0 && memcmp(output,expected,sizeof(output))==0);
    R4RemoteFrameInfo capture={0};R4RemoteFrameLease capture_lease={0};
    status(R4SdkGuiDesktopContext_remoteFrameSnapshotAcquire(0,R4SdkGuiSessionDesktop(&s),73,&capture,&capture_lease));
    assert(capture.revision==73 && capture_lease.id==UINT64_C(0x100000003));
    status(R4SdkGuiDesktopContext_remoteFrameSnapshotRelease(0,R4SdkGuiSessionDesktop(&s),&capture_lease));
    R4ProgramProcessHandle owner={.instance_id=42,.generation=UINT64_C(0x100000007)};R4GuiSharedRasterHandle handle={.id=UINT64_C(0x300000003),.generation=UINT64_C(0x400000005)};R4GuiSharedRasterMap map={0};
    status(R4SdkGuiDrawContext_guiSharedRasterAcquire(0,R4SdkGuiSessionDraw(&s),&owner,UINT64_C(0x200000009),&handle,UINT64_C(0x500000009),&map));
    assert(shared_live && map.frame_generation==UINT64_C(0x200000009));
    R4SdkGuiSlot held=R4SdkGuiDrawContext_guiSharedRasterRelease(0,R4SdkGuiSessionDraw(&s),&map.lease);assert(held.status==0 && (int32_t)held.bits==-3 && shared_live && shared_releases==1);
    status(R4SdkGuiDrawContext_guiSharedRasterRelease(0,R4SdkGuiSessionDraw(&s),&map.lease));assert(!shared_live && shared_releases==2);
    // A valid old R4DESK prefix must never read/call its unsupported tail.
    const uint32_t desk_bytes=desk.size;
    desk.size=624;desk.gui_window_appearance=(uintptr_t)1;
    R4Desk old_desk={.table=&desk};
    R4GuiPointerWindowIdentity appearance_identity={.owner=owner,.epoch=UINT64_C(0x600000009),.window_id=1};
    R4GuiWindowAppearance appearance;memset(&appearance,0xa5,sizeof(appearance));
    assert(r4desk_gui_window_appearance(&old_desk,&appearance_identity,&appearance)==R4OS_ERR_NO_FN);
    for(size_t i=0;i<sizeof(appearance);i++)assert(((const uint8_t *)&appearance)[i]==0xa5);
    R4SdkGuiSlot no_appearance=R4SdkGuiDesktopContext_guiWindowAppearance(0,R4SdkGuiSessionDesktop(&s),&appearance_identity,&appearance);
    assert(no_appearance.status==0 && (int32_t)no_appearance.bits==R4OS_ERR_NO_FN);
    for(size_t i=0;i<sizeof(appearance);i++)assert(((const uint8_t *)&appearance)[i]==0xa5);
    desk.size=desk_bytes;desk.gui_window_appearance=0;
    R4SdkGuiSessionClose(&s);
    draw.font_revision=(uintptr_t)revision_probe;draw.gui_frame_begin=0;
    assert(R4SdkGuiSessionOpen2(&s,&start,0,&timer,1)==0);
    R4SdkGuiSlot revision=R4SdkGuiDrawContext_fontRevision(0,R4SdkGuiSessionDraw(&s));checked(revision);assert(revision.bits==0);
    font_revision_value=37;revision=R4SdkGuiDrawContext_fontRevision(0,R4SdkGuiSessionDraw(&s));checked(revision);assert(revision.bits==37);
    assert(R4SdkGuiSessionBegin(&s,commands,8,resources,64)==R4OS_ERR_NO_FN);
    R4SdkGuiSessionClose(&s);
    uint8_t text[24];R4SdkGuiTextField field;checked(R4SdkGui_borrowedTextField(0,text,sizeof(text),&field));
    const uint8_t initial[]="A\xcc\x81" "B";assert(R4SdkGuiTextField_setExact(0,&field,initial,sizeof(initial)-1).bits==1);
    checked(R4SdkGuiTextField_setSelection(0,&field,0,1));
    const uint8_t emoji[]="\xf0\x9f\x99\x82";assert(R4SdkGuiTextField_pasteSlice(0,&field,emoji,4).bits==1);
    R4SdkGuiSlot view=R4SdkGuiTextField_value(0,&field);checked(view);assert(view.length==5 && !memcmp(view.ptr,"\xf0\x9f\x99\x82" "B",5));
    assert(!R4SdkGuiTextField_setExact(0,&field,(const uint8_t *)"\xc0\xaf",2).bits);
    assert(R4SdkGuiTextField_value(0,&field).length==5);
    assert(R4SdkGuiTextField_setExact(0,&field,(const uint8_t *)"",0).bits==1);
    checked(R4SdkGuiTextField_selectAll(0,&field));
    assert(R4SdkGuiTextField_handleCodepoint(0,&field,'a').bits==1);
    assert(R4SdkGuiTextField_handleCodepoint(0,&field,'b').bits==1);
    view=R4SdkGuiTextField_value(0,&field);checked(view);assert(view.length==2 && !memcmp(view.ptr,"ab",2));
    R4SdkGuiShapePoint point;const float x=1.25f,y=-2.5f;checked(R4SdkGuiShapePoint_create(&point,&x,&y));
    float value=0;checked(R4SdkGuiShapePoint_get_x(&point,&value));assert(value==x);
    R4SdkGuiShapePathStyle style;checked(R4SdkGuiShapePathStyle_create(&style));
    uint8_t path_bytes[512];R4SdkGuiShapePathBuilder path;
    checked(R4SdkGuiShapePathBuilder_init(0,path_bytes,sizeof(path_bytes),&style,&path));
    checked(R4SdkGuiShapePathBuilder_moveTo(0,&path,&point));checked(R4SdkGuiShapePathBuilder_lineTo(0,&path,&point));
    checked(R4SdkGuiShapePathBuilder_finish(0,&path));
    const uint32_t nan_bits=0x7fc00000;float nan_value;memcpy(&nan_value,&nan_bits,4);
    checked(R4SdkGuiShapePoint_create(&point,&nan_value,&y));
    R4SdkGuiSlot invalid=R4SdkGuiShapePathBuilder_moveTo(0,&path,&point);
    assert(invalid.status==0 && (invalid.flags&R4SDK_GUI_NATIVE_ERROR) && invalid.length==12 && !memcmp(invalid.ptr,"InvalidValue",12));
    const float zero=0,one=1,gw=16,gh=12;
    R4SdkGuiShapePoint begin,end;checked(R4SdkGuiShapePoint_create(&begin,&zero,&zero));checked(R4SdkGuiShapePoint_create(&end,&gw,&gh));
    R4SdkGuiShapeGradientStop stops[2];checked(R4SdkGuiShapeGradientStop_create(&stops[0],&zero,0xff112233));checked(R4SdkGuiShapeGradientStop_create(&stops[1],&one,0xffaabbcc));
    R4SdkGuiShapeGradient gradient;checked(R4SdkGuiShapeGradient_create(&gradient,&begin,&end,stops,2));
    R4SdkGuiShapeRoundedRect rounded;checked(R4SdkGuiShapeRoundedRect_create(&rounded,&zero,&zero,&gw,&gh));
    uint8_t gradient_bytes[256];R4SdkGuiSlot built=R4SdkGuiShapes_gradientRoundedRect(0,gradient_bytes,sizeof(gradient_bytes),&rounded,&gradient);checked(built);
    assert(built.ptr==gradient_bytes && built.length==208);
    R4GuiGradientPaint paint;memcpy(&paint,gradient_bytes+sizeof(R4GuiShapeResource),sizeof(paint));
    assert(paint.version==1 && paint.size==32 && paint.kind==R4OS_GUI_GRADIENT_KIND_LINEAR && paint.stop_count==2);
    memset(gradient_bytes,0xa5,sizeof(gradient_bytes));built=R4SdkGuiShapes_gradientRoundedRect(0,gradient_bytes,207,&rounded,&gradient);
    assert(built.status==0 && (built.flags&R4SDK_GUI_NATIVE_ERROR));for(size_t i=0;i<sizeof(gradient_bytes);i++)assert(gradient_bytes[i]==0xa5);
    // Invalid transport cannot invoke an arbitrary owner or construct a context.
    assert(R4SdkGuiInvoke(R4SdkGui_ABI_FINGERPRINT,UINT32_MAX,0,0,0).status<0);
    assert(R4SdkGuiInvoke(R4SdkGui_ABI_FINGERPRINT^1u,0,0,0,0).status<0);
    assert(R4SdkGuiConstruct(R4SdkGui_ABI_FINGERPRINT,R4SdkGuiSession_TYPE,0,0,&s).status<0);
    sdk_gui_host_tables(&sys,&desk,&draw);start=start_for(&sys,&desk,&draw,imports);
    assert(R4SdkGuiSessionOpen2(&s,&start,1,0,0)==0 && host_window_queries==0);
    R4Timeout timeout={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=250000000};R4TrayDesktopExchange exchange;
    assert(R4SdkGuiSessionHostClaim(&s,&exchange,&timeout)==0 && host_calls==1 && exchange.desktop_epoch==UINT64_C(0x100000007));
    sdk_gui_host_mode(2);assert(R4SdkGuiSessionHostExchange(&s,R4OS_TRAY_SERVICE_OP_DESKTOP_SYNC,&exchange,&exchange,&timeout)==-9);
    assert(host_closes==1 && host_opens==1);sdk_gui_host_mode(0);
    R4TrayDesktopExchange request=exchange;request.desktop_owner=(R4ProgramProcessHandle){.instance_id=42,.generation=UINT64_C(0x100000007)};
    assert(R4SdkGuiSessionHostExchange(&s,R4OS_TRAY_SERVICE_OP_DESKTOP_SYNC,&request,&exchange,&timeout)<0 && host_opens==1);
    R4SdkGuiSessionHostReset(&s);assert(R4SdkGuiSessionHostClaim(&s,&exchange,&timeout)==0 && host_opens==2);
    R4SdkGuiSessionClose(&s);assert(host_closes==2 && host_window_queries==0);
    return 0;
}

/* Generation2 admission uses the real public C view and leaves failed outputs
 * untouched. Kept in the existing C/Rust platform interop runner. */
#include <r4os/platform2.h>
int32_t sdk_platform2_admission(const R4XStartContext2 *raw, int32_t *called) {
    R4OS2Context view = {.raw=(const R4XStartContext2 *)(uintptr_t)8, .tables={1,2,3,4,5,6}};
    R4OS2Context before = view;
    int32_t result = R4OS2ContextInit(raw, &view);
    if (result) {
        assert(memcmp(&before, &view, sizeof(view)) == 0);
        return result;
    }
    assert(view.raw == raw && !R4OS2ContextGroup(&view, 0) && !R4OS2ContextGroup(&view, 7));
    const R4XStartR4Sys2 *sys = R4OS2ContextGroup(&view, 1);
    assert(sys);
    *called = -20001;
    uint64_t address = 12345;
    assert(R4OS2ContextFunction(&view, 7, 16, &address) == R4OS_ERR_NO_GROUP && address == 12345);
    assert(R4OS2ContextFunction(&view, 1, 0, &address) == R4OS_ERR_NO_FN && address == 12345);
    assert(R4OS2ContextFunction(&view, 1, UINT32_C(0xfffffff8), &address) == R4OS_ERR_NO_FN && address == 12345);
    int32_t lookup = R4OS2ContextFunction(&view, 1, offsetof(R4XStartR4Sys2, write), &address);
    assert(lookup == 0 || lookup == R4OS_ERR_NO_FN);
    if (!lookup) {
        R4SysWriteFn write = (R4SysWriteFn)(uintptr_t)address;
        *called = write((const uint8_t *)"API2", 4);
    }
    return 0;
}

static int32_t platform2_start_main(const R4OS2Context *context) {
    uint64_t address = 0;
    if (R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,write),&address)) return -9;
    return ((R4SysWriteFn)(uintptr_t)address)((const uint8_t *)"API2",4);
}
int32_t sdk_platform2_start_case(const R4XStartContext2 *raw, uint32_t app_class, uint32_t mask, uint32_t count) {
    const R4OS2StartupInfo info = {app_class,mask,count};
    return R4OS2Start(raw,&info,platform2_start_main);
}
