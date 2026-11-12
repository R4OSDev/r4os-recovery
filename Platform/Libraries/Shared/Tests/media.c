#include <r4gfx_helpers.h>
#include <r4enc_helpers.h>
#include <r4video_helpers.h>
#include <r4aco_helpers.h>
#include <r4nak_helpers.h>
#include <string.h>
/* Actual public Start2 record crosses the C boundary; the private Zig App2
 * is constructed by its owner. No C/foreign App layout is reinterpreted. */
const void *r4libraries47_start2(void) {
    static R4XStartR4Sys2 sys;
    static R4XStartImport item;
    static R4XStartContext2 start;
    sys=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=R4OS2_R4SYS_VERSION,.size=sizeof(sys)};
    item=(R4XStartImport){.group_id=1,.resolved_version=2,.table=(uintptr_t)&sys};
    start=(R4XStartContext2){.magic=R4OS2_START_MAGIC,.abi_major=2,.size=sizeof(start),
        .flags=R4XSTART_FLAG_IMPORTS_VALID,.instance_id=71,.app_class=R4XSTART_APP_CLASS_CONSOLE,
        .imports=(uintptr_t)&item,.import_count=1};
    return &start;
}
int32_t r4libraries47_compiler_context(void) {
    R4MediaCompilerContext2 context,original;
    const R4XStartContext2 *start=r4libraries47_start2();
    R4LibrariesSlot value=R4MediaCompilerContext2_init(0,start,&context);
    if(value.status || (value.flags&R4LIBRARIES_NATIVE_ERROR))return 1;
    R4XStartR4Desk2 desk={.magic=R4OS2_R4DESK_MAGIC,.abi_version=1,.size=sizeof(desk)};
    R4XStartR4Draw2 draw={.magic=R4OS2_R4DRAW_MAGIC,.abi_version=1,.size=sizeof(draw)};
    R4XStartImport imports[3]={*(const R4XStartImport *)(uintptr_t)start->imports,
        {.group_id=2,.resolved_version=2,.table=(uintptr_t)&desk},
        {.group_id=3,.resolved_version=2,.table=(uintptr_t)&draw}};
    R4XStartContext2 gui=*start;gui.app_class=2;gui.imports=(uintptr_t)imports;gui.import_count=3;
    value=R4MediaCompilerContext2_init(0,&gui,&context);
    if(value.status || (value.flags&R4LIBRARIES_NATIVE_ERROR))return 4;
    R4XStartContext2 service=*start;service.app_class=3;
    value=R4MediaCompilerContext2_init(0,&service,&context);
    if(value.status || (value.flags&R4LIBRARIES_NATIVE_ERROR))return 5;
    memset(&original,0xa5,sizeof(original));context=original;
    R4XStartContext2 wrong=*start;wrong.abi_major=1;
    value=R4MediaCompilerContext2_init(0,&wrong,&context);
    if(!(value.status || (value.flags&R4LIBRARIES_NATIVE_ERROR)) || memcmp(&context,&original,sizeof(context)))return 2;
    wrong=*start;wrong.size=16;
    value=R4MediaCompilerContext2_init(0,&wrong,&context);
    if(!(value.status || (value.flags&R4LIBRARIES_NATIVE_ERROR)) || memcmp(&context,&original,sizeof(context)))return 3;
    return 0;
}
int32_t r4libraries60_transport(void) {
    /* Only the initialized field is inspected; no resource owner is started. */
    R4GfxReadbackOwner readback;
    R4LibrariesSlot why={.ptr=(void *)"Busy",.length=4,.flags=R4LIBRARIES_PRESENT};
    R4LibrariesSlot value=R4GfxReadbackOwner_set_failure(&readback,why);
    if(value.status)return 1;
    value=R4GfxReadbackOwner_get_failure(&readback);
    if(value.status || value.flags!=R4LIBRARIES_PRESENT || value.length!=4 || memcmp(value.ptr,"Busy",4))return 2;
    /* Unknown error is rejected before touching any uninitialized owner data. */
    value=R4GfxReadbackOwner_cancel(0,&readback,(const uint8_t *)"InventedError",13);
    if(!value.status)return 3;
    R4GfxDisplayProfileOwner profile;_Alignas(16) uint8_t storage[32];
    value=R4GfxDisplayProfileOwner_set_storage(&profile,storage,sizeof(storage));
    if(value.status)return 4;
    value=R4GfxDisplayProfileOwner_set_storage(&profile,storage+1,1);
    if(!value.status)return 5;
    value=R4GfxDisplayProfileOwner_get_storage(&profile);
    if(value.status || value.ptr!=storage || value.length!=sizeof(storage))return 6;
    value=R4GfxDisplayProfileOwner_set_storage(&profile,0,0);
    if(value.status || R4GfxDisplayProfileOwner_get_storage(&profile).length)return 7;
    /* Opaque output clients are initialized/selected by their real owners. */
    R4GfxRefreshClientClient refresh;R4GfxRefreshPreferencesChoice refresh_choice;
    R4GfxBrightnessClientClient brightness;R4GfxBrightnessPreferencesChoice brightness_choice;
    if(R4Media_refreshInit(0,&refresh).status || R4GfxRefreshPreferencesChoice_create(&refresh_choice).status ||
       R4Media_refreshSelect(0,&refresh,&refresh_choice).status)return 8;
    if(R4Media_brightnessInit(0,&brightness).status || R4GfxBrightnessPreferencesChoice_create(&brightness_choice).status)return 9;
    R4LibrariesSlot choice={.ptr=&brightness_choice,.flags=R4LIBRARIES_PRESENT};
    if(R4Media_brightnessSelect(0,&brightness,choice).status || R4Media_brightnessSelect(0,&brightness,(R4LibrariesSlot){0}).status)return 10;
    R4GfxColorPreferencesConfig colors,changed;
    if(R4GfxColorPreferencesConfig_create(&colors).status || R4GfxColorPreferencesConfig_create(&changed).status ||
       R4Media_colorPreferencesEqual(0,&colors,&changed).bits!=1)return 11;
    if(R4GfxColorPreferencesConfig_set_count(&changed,1).status || R4Media_colorPreferencesEqual(0,&colors,&changed).bits)return 12;
    R4GfxColorPreferencesChoice color,other;
    if(R4GfxColorPreferencesChoice_create(&color).status || R4GfxColorPreferencesChoice_create(&other).status)return 13;
    R4LibrariesSlot left={.ptr=&color,.flags=R4LIBRARIES_PRESENT},right={.ptr=&other,.flags=R4LIBRARIES_PRESENT};
    if(R4Media_colorChoiceEqual(0,left,right).bits!=1 || R4GfxColorPreferencesChoice_set_intent(&other,2).status ||
       R4Media_colorChoiceEqual(0,left,right).bits || R4Media_colorChoiceEqual(0,(R4LibrariesSlot){0},(R4LibrariesSlot){0}).bits!=1)return 14;
    return 0;
}
struct Collect { uint8_t bytes[4096];uintptr_t length; };
static uint8_t collect(void *context,const uint8_t *bytes,uintptr_t length){
    struct Collect *c=context;if(length>sizeof(c->bytes)-c->length)return 0;
    memcpy(c->bytes+c->length,bytes,length);c->length+=length;return 1;
}
uint64_t r4libraries60_mux_color(const uint8_t *bytes,uintptr_t length,uint8_t transfer,uint8_t centered){
    R4EncMuxWriter writer;R4MediaSink sink;struct Collect c={0};
    R4LibrariesSlot context={.ptr=&c,.flags=R4LIBRARIES_PRESENT};
    if(R4EncMuxWriter_create(&writer,64,64).status || R4MediaSink_from_fields(&sink,context,(uintptr_t)collect).status)return 0;
    R4EncMuxColor color;
    if(R4EncMuxColor_from_fields(&color,transfer,centered).status || R4EncMuxWriter_set_color(&writer,&color).status)return 0;
    R4LibrariesSlot value=R4Media_muxPacket(0,&writer,&sink,bytes,length,1,0,1);
    if(value.status || value.flags&R4LIBRARIES_NATIVE_ERROR || R4EncMuxWriter_get_frames(&writer).bits!=1)return 0;
    uint64_t hash=14695981039346656037ull;
    for(uintptr_t i=0;i<c.length;++i)hash=(hash^c.bytes[i])*1099511628211ull;
    return hash;
}
uint64_t r4libraries60_mux(const uint8_t *bytes,uintptr_t length){return r4libraries60_mux_color(bytes,length,1,0);}
