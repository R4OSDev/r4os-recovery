/* Included after the unchanged original subsystem Model/dispatcher. */
#include <r4os/published_frame.h>
#define PF26_CHECK(x,n) do {if(!(x))return(n);}while(0)
uint32_t sdk_published26_color(const void *user,uint32_t index){const Model *model=user;return index<256?model->pixels[index]:0;}
int32_t sdk_published26_c_case(void){
 Model model;sdk65_fixture_init(&model);
 R4SdkSubsystemCallbackTable table;
 R4SdkSubsystemSlot slot=R4SdkSubsystemCallbackTable_from_fields(&table,(R4SdkSubsystemSlot){.ptr=&model,.flags=1},sdk65_fixture_mask()&~(UINT64_C(1)<<R4SdkSubsystemCallbackKind_video_indexed8),(R4SdkSubsystemSlot){.ptr=(void *)&sdk65_fixture_dispatch,.flags=1});
 PF26_CHECK(slot.status==0&&!(slot.flags&R4SDKSUBSYSTEM_NATIVE_ERROR),1);
 uint32_t scratch[128*128],pixels[64];for(uint32_t i=0;i<64;i++)pixels[i]=0x112233;
 R4SdkPublishedFrameBridge bridge;R4SdkPublishedFrameAcquisition acquired;R4SdkPublishedFramePresentation out;R4SdkPublishedFrameProgress progress;
 PF26_CHECK(!R4SdkPublishedFrameInit(&table,scratch,128*128,0,&bridge)&&!R4SdkPublishedFrameBind(&bridge,1),2);
 R4SdkPublishedFrameLease lease={.pixels={(uintptr_t)pixels,sizeof(pixels)},.binding_generation=1,.revision=1,.width=8,.height=8,.stride_bytes=32,.format=1,.flags=1};
 PF26_CHECK(!R4SdkPublishedFrameSync(&bridge,lease,&acquired)&&acquired.kind==1,3);
 PF26_CHECK(!R4SdkPublishedFramePresent(&bridge,acquired.ticket,16,16,&out)&&out.kind==2&&out.mode==0&&out.viewport.integer_scale==2,4);
 for(uint32_t i=0;i<256;i++)PF26_CHECK(model.pixels[i]==0x112233,5);
 PF26_CHECK(!R4SdkPublishedFrameRelease(&bridge,acquired.ticket),6);
 pixels[9]=0x334455;lease.revision=2;lease.damage_kind=1;lease.damage_base_revision=1;lease.damage=(R4SdkPublishedFrameRect){1,1,1,1};
 PF26_CHECK(!R4SdkPublishedFrameSync(&bridge,lease,&acquired)&&!R4SdkPublishedFramePresent(&bridge,acquired.ticket,16,16,&out)&&out.kind==2&&out.mode==1&&out.damage_regions==1&&model.pixels[2*16+2]==0x334455,7);
 PF26_CHECK(R4SdkPublishedFrameBind(&bridge,2)==R4_PUBLISHED_BUSY,8);
 PF26_CHECK(!R4SdkPublishedFrameClose(&bridge)&&!R4SdkPublishedFrameGetProgress(&bridge,&progress)&&progress.state==3&&!progress.active_ticket,9);
 PF26_CHECK(R4SdkPublishedFramePresent(&bridge,acquired.ticket,16,16,&out)==R4_PUBLISHED_ENDED,10);
 return 0;
}
#undef PF26_CHECK
