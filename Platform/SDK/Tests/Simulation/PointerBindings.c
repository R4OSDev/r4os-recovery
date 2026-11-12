/* Binding/decoder proof only. The real desktop/native input contract is
 * qualified separately with the public MouseLook application in a guest. */
#include <assert.h>
#include <string.h>
#include <r4os/app_gui.h>

_Static_assert(sizeof(R4Message)==48,"existing message union prefix/size");
_Static_assert(sizeof(R4PointerCaptureMessage)==32,"typed 64-bit capture notice");
_Static_assert(offsetof(R4Window,app)==0&&offsetof(R4Window,id)==8&&offsetof(R4Window,events)==16,"window prefix");
static uint32_t pointer_calls;
static uint32_t input_calls;
_Static_assert(sizeof(R4GuiHostInputRequest)==80,"exact window+event+operation input request");
static R4GuiPointerWindowIdentity pointer_identity(void) {
    return (R4GuiPointerWindowIdentity){.owner={.instance_id=7,.generation=UINT64_C(0x100000009)},
        .epoch=UINT64_C(0x200000008),.window_id=4};
}
static int32_t pointer_info(const R4GuiPointerCaptureHandle *token,R4GuiPointerCaptureInfo *out) {
    ++pointer_calls;
    if(token)assert(token->id==UINT64_C(0x300000007));
    *out=(R4GuiPointerCaptureInfo){.capture={.window=pointer_identity(),.id=token?token->id:0},
        .state=token?R4OS_GUI_POINTER_STATE_ACTIVE:R4OS_GUI_POINTER_STATE_NONE};
    return 0;
}
static int32_t pointer_acquire(const R4GuiPointerWindowIdentity *identity,uint32_t mode,R4GuiPointerCaptureHandle *out) {
    ++pointer_calls;R4GuiPointerWindowIdentity expected=pointer_identity();
    assert(!memcmp(identity,&expected,sizeof expected));assert(mode==R4OS_GUI_POINTER_MODE_RELATIVE);
    *out=(R4GuiPointerCaptureHandle){.window=*identity,.id=UINT64_C(0x300000007)};return 0;
}
static int32_t pointer_release(const R4GuiPointerCaptureHandle *token) {
    ++pointer_calls;assert(token->id==UINT64_C(0x300000007));
    assert(token->window.epoch==UINT64_C(0x200000008));return R4OS_GUI_POINTER_ERROR_STALE;
}
static int32_t host_input_probe(const R4GuiHostInputRequest *request,R4GuiPointerWindowIdentity *out) {
    R4GuiPointerWindowIdentity expected=pointer_identity();
    assert(!memcmp(&request->window,&expected,sizeof expected));
    assert(request->operation==R4OS_GUI_HOST_INPUT_OPERATION_POST && request->reason==0);
    assert(request->event.kind==R4_GUI_RAW_EVENT_MOUSE_UP && request->event.x==-701);
    assert(request->event.tick==UINT64_C(0x8000000000000009));
    (void)out;++input_calls;return R4OS_GUI_HOST_INPUT_ERROR_BUSY;
}
static void sdk_gui_pointer_binding_case(void) {
    R4XStartR4Desk desk={.magic=R4XSTART_R4DESK_MAGIC,.abi_version=R4XSTART_R4DESK_VERSION,.size=sizeof desk,
        .gui_pointer_capture_info=(uintptr_t)pointer_info,.gui_pointer_capture_acquire=(uintptr_t)pointer_acquire,
        .gui_pointer_capture_release=(uintptr_t)pointer_release};
    R4App app={.desktop={.table=&desk}};R4Window window={.app=&app,.id=4,.events={.app=&app}};
    R4GuiPointerWindowIdentity identity={0};R4GuiPointerCaptureHandle token={0};R4GuiPointerCaptureInfo info={0};
    pointer_calls=0;
    assert(r4_window_pointer_identity(&window,&identity)==0&&identity.epoch==UINT64_C(0x200000008));
    assert(r4_window_pointer_capture(&window,&identity,R4OS_GUI_POINTER_MODE_RELATIVE,&token)==0);
    assert(r4_window_pointer_status(&window,&token,&info)==0&&info.state==R4OS_GUI_POINTER_STATE_ACTIVE);
    assert(r4_window_pointer_release(&window,&token)==R4OS_GUI_POINTER_ERROR_STALE&&pointer_calls==4);
    desk.gui_host_input=(uintptr_t)host_input_probe;
    R4GuiHostInputRequest request={.window=pointer_identity(),.operation=R4OS_GUI_HOST_INPUT_OPERATION_POST,
        .event={.kind=R4_GUI_RAW_EVENT_MOUSE_UP,.x=-701,.tick=UINT64_C(0x8000000000000009)}};
    R4GuiPointerWindowIdentity untouched=identity;
    input_calls=0;
    assert(r4desk_gui_host_input(&app.desktop,&request,&identity)==R4OS_GUI_HOST_INPUT_ERROR_BUSY && input_calls==1);
    assert(!memcmp(&identity,&untouched,sizeof identity));
    desk.size=616;desk.abi_version=19;
    assert(r4desk_gui_host_input(&app.desktop,&request,&identity)==R4OS_ERR_NO_FN && input_calls==1);
    desk.size=584;desk.abi_version=18;
    assert(r4_window_pointer_status(&window,&token,&info)==R4OS_ERR_NO_FN&&pointer_calls==4);
    assert(r4_window_pointer_identity(0,&identity)==R4OS_GUI_POINTER_ERROR_INVALID);
    R4GuiEvent raw={.kind=R4_GUI_RAW_EVENT_MOUSE_RELATIVE,.window_id=4,.x=20000,.y=-40000,
        .key=R4OS_GUI_POINTER_SOURCE_PHYSICAL_RELATIVE,.buttons=3,.tick=UINT64_C(0x500000003)};
    R4Message result=r4_message_translate(&window.events,raw);
    assert(result.kind==R4_MESSAGE_MOUSE_RELATIVE&&result.value.relative.dx==20000&&result.value.relative.dy==-40000);
    assert(result.value.relative.source==R4OS_GUI_POINTER_SOURCE_PHYSICAL_RELATIVE&&result.value.relative.tick==raw.tick);
    raw.kind=R4_GUI_RAW_EVENT_MOUSE_WHEEL;raw.key=(uint32_t)-120;raw.x=-20;raw.y=900;
    result=r4_message_translate(&window.events,raw);
    assert(result.kind==R4_MESSAGE_MOUSE_WHEEL&&result.value.wheel.delta==-120&&result.value.wheel.x==-20);
    raw.kind=R4_GUI_RAW_EVENT_CAPTURE_CHANGED;raw.x=R4OS_GUI_POINTER_STATE_CANCELLED;
    raw.y=R4OS_GUI_POINTER_REASON_INPUT_OVERFLOW;raw.modifiers=R4OS_GUI_POINTER_MODE_RELATIVE;
    raw.key=7;raw.buttons=3;
    result=r4_message_translate(&window.events,raw);
    assert(result.kind==R4_MESSAGE_POINTER_CAPTURE&&result.value.capture.capture_id==UINT64_C(0x300000007));
    assert(result.value.capture.state==R4OS_GUI_POINTER_STATE_CANCELLED&&result.value.capture.reason==R4OS_GUI_POINTER_REASON_INPUT_OVERFLOW);
}
