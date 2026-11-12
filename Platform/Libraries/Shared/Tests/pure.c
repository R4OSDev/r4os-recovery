#include <r4std_helpers.h>
#include <r4img_helpers.h>
#include <r4font_helpers.h>
#include <string.h>
static int32_t topology_bounds(void) {
    R4GfxTopologyOutput outputs[2];
    for (uint32_t i=0;i<2;i++) {
        R4GfxTopologyKey key; R4GfxTopologyPoint point; R4GfxTopologyViewport view;
        if(R4GfxTopologyKey_create(&key).status || R4GfxTopologyKey_set_connector(&key,i+1).status ||
            R4GfxTopologyPoint_from_fields(&point,i ? 0 : -640,0).status ||
            R4GfxTopologyViewport_from_fields(&view,&point,640,480,120,0).status ||
            R4GfxTopologyOutput_from_fields(&outputs[i],&key,&view,1,i==0,0,60000).status)return 13;
    }
    R4GfxTopologyLayout layout;
    R4LibrariesSlot value=R4GfxTopologyLayout_init(0,outputs,2,1,&layout);
    if(value.status || value.flags!=R4LIBRARIES_PRESENT)return 14;
    for(uint32_t i=0;i<2;i++) {
        R4GfxTopologyPoint point; R4GfxTopologyViewport view;
        if(R4GfxTopologyPoint_from_fields(&point,i ? INT32_MAX-640 : INT32_MIN,0).status ||
            R4GfxTopologyViewport_from_fields(&view,&point,640,480,120,0).status ||
            R4GfxTopologyOutput_set_view(&outputs[i],&view).status)return 15;
    }
    unsigned char before[sizeof(layout)]; memcpy(before,&layout,sizeof(layout));
    value=R4GfxTopologyLayout_init(0,outputs,2,2,&layout);
    if(value.status || !(value.flags&R4LIBRARIES_NATIVE_ERROR) || memcmp(before,&layout,sizeof(layout)))return 16;
    R4GfxTopologyRect rect;
    if(R4GfxTopologyRect_from_fields(&rect,INT32_MAX-127,0,128,1).status)return 17;
    value=R4GfxTopologyRect_valid(0,&rect);
    return value.status || value.flags!=R4LIBRARIES_PRESENT || value.bits ? 18 : 0;
}
int32_t r4libraries59_pure(void) {
    int32_t topology=topology_bounds();if(topology)return topology;
    if(R4StdCodecMode_controls!=0 || R4StdCodecMode_pc_graphics!=1)return 12;
    const uint8_t text[]={'A',0xcc,0x88,'B'},invalid[]={'A',0xff};
    R4LibrariesSlot value=R4StdGrapheme_prefix(0,text,sizeof(text),2);
    if(value.status || value.flags!=R4LIBRARIES_PRESENT || value.bits)return 1;
    value=R4StdGrapheme_prefix(0,text,sizeof(text),3);
    if(value.status || value.bits!=3)return 2;
    value=R4StdGrapheme_prefix(0,invalid,sizeof(invalid),1);
    if(value.status || !(value.flags&R4LIBRARIES_NATIVE_ERROR))return 3;
    if(!R4LibrariesVerifyAbi(R4Libraries_ABI_FINGERPRINT^1))return 4;
    value=R4LibrariesConstruct(R4Libraries_ABI_FINGERPRINT^1,0,0,0,(void *)(uintptr_t)1);
    if(!value.status)return 5;
    R4StdGraphemeIterator it;R4StdGraphemeRange range;
    if(R4StdGraphemeIterator_create(&it,text,sizeof(text)).status)return 6;
    value=R4StdGraphemeIterator_next(0,&it,&range);
    if(value.flags!=R4LIBRARIES_PRESENT || R4StdGraphemeRange_get_end(&range).bits!=3)return 7;
    value=R4StdGraphemeIterator_next(0,&it,&range);
    if(value.flags!=R4LIBRARIES_PRESENT || R4StdGraphemeRange_get_end(&range).bits!=4)return 8;
    value=R4StdGraphemeIterator_next(0,&it,&range);
    if(value.flags || value.status)return 9;
    R4XStartContext invalid_start={0};
    R4LibraryColorClient color;
    R4Lib_R4VIDEO_Bindings_Zig_r4video_VideoV1Client video;
    value=R4Library_colorClient(0,&invalid_start,&color);
    if(value.status || !(value.flags&R4LIBRARIES_NATIVE_ERROR))return 10;
    value=R4Library_videoClient(0,&invalid_start,&video);
    return value.status || !(value.flags&R4LIBRARIES_NATIVE_ERROR) ? 11 : 0;
}
