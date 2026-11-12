#include <r4os/gui_bridge.h>
/* The same fixed 4x3 pixels as the original GuiFacadePrototype05824 replay. */
int32_t sdk57_fill(R4SdkGuiDrawContext *draw,const R4GfxBufferHandle *reference) {
    const uint32_t pixels[]={0x112233,0x445566,0,0,0,0xffffff,0xcc0000,0xcc0000,0xffffff,0,0,0x010203};
    R4GfxBufferMap map={0};
    R4SdkGuiSlot r=R4SdkGuiDrawContext_gfxBufferMap(0,draw,reference,1,0,4096,&map);
    if(r.status || (int32_t)r.bits!=1)return 1;
    if(!map.cpu_address || (map.cpu_address&3) || map.byte_length<sizeof(pixels))return 2;
    uint32_t *output=(void *)(uintptr_t)map.cpu_address;
    for(uint32_t i=0;i<12;++i)output[i]=pixels[i];
    r=R4SdkGuiDrawContext_gfxBufferUnmap(0,draw,&map.lease);
    return r.status || (int32_t)r.bits!=1 ? 3 : 0;
}
