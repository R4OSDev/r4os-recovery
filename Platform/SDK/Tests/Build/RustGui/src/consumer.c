#include <r4os/gui_bridge.h>
static int ok(R4SdkGuiSlot value){return value.status==0 && !(value.flags&R4SDK_GUI_NATIVE_ERROR);}
int32_t sdk56_gui_c(R4SdkGuiCanvas *canvas){
    uint8_t bytes[24];R4SdkGuiTextField field;
    if(!ok(R4SdkGui_borrowedTextField(0,bytes,sizeof(bytes),&field)))return 1;
    if(!R4SdkGuiTextField_setExact(0,&field,(const uint8_t *)"A\xcc\x81" "B",4).bits)return 2;
    if(!ok(R4SdkGuiTextField_setSelection(0,&field,0,1)))return 3;
    if(!R4SdkGuiTextField_pasteSlice(0,&field,(const uint8_t *)"\xf0\x9f\x99\x82",4).bits)return 4;
    R4SdkGuiSlot view=R4SdkGuiTextField_value(0,&field);
    if(!ok(view) || view.length!=5 || ((const uint8_t *)view.ptr)[4]!='B')return 5;
    // Native floating data passed indirectly, including a returned field.
    union {float f;uint32_t bits;} x={.bits=0x3fa00000},y={.bits=0xc0200000},got={0};
    R4SdkGuiShapePoint point;
    if(!ok(R4SdkGuiShapePoint_create(&point,&x.f,&y.f)) || !ok(R4SdkGuiShapePoint_get_x(&point,&got.f)) || got.bits!=x.bits)return 6;
    R4SdkGuiRect rect;R4SdkGuiButton button;uint8_t scratch[128];
    if(!ok(R4SdkGuiRect_from_fields(&rect,16,72,176,28)))return 7;
    if(!ok(R4SdkGuiButton_create(&button,&rect,(const uint8_t *)"Shared C/Zig button",19)))return 8;
    R4SdkGuiSlot drawn=R4SdkGuiButton_draw(0,&button,canvas,scratch,sizeof(scratch));
    return ok(drawn) && (int32_t)drawn.bits>=0 ? 0 : 9;
}
