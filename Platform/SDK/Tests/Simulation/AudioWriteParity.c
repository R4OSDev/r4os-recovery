/* Shared native language peer: actual Zig owner, controlled wire/clock only. */
#include <r4os/audio_write_platform2.h>
#include <r4os/pcm_source.h>
#include <r4os/app_audio.h>
#include <string.h>
#define AUDIO25_CHECK(test,code) do {if(!(test))return(code);}while(0)
static uint64_t au25_now,au25_ticks[64];
static uint32_t au25_calls,au25_mode,au25_late;
static int32_t au25_clock(R4MonotonicClockInfo *out){
 *out=(R4MonotonicClockInfo){.version=1,.size=sizeof(*out),.flags=R4OS_MONOTONIC_CLOCK_FLAG_VALID,.source=1,.generation=41,.instant_ns=au25_now,.frequency_hz=R4OS_MONOTONIC_CLOCK_FREQUENCY_HZ,.resolution_ns=1,.event_backend=1,.event_requested_hz=1000,.event_effective_hz=999};return 1;
}
static int32_t au25_call(uint32_t channel,uint16_t op,const uint8_t *request,uint32_t length,R4ServiceMessageHeader *header,uint8_t *response,uint32_t capacity,uint64_t ticks){
 if(op==R4OS_AUDIO_SERVICE_OP_OPEN_STREAM||op==R4OS_AUDIO_SERVICE_OP_CLOSE_STREAM){
  AUDIO25_CHECK(channel==7&&capacity>=sizeof(R4AudioServiceStreamResult),-92);
  R4AudioServiceStreamResult control={.magic=R4OS_AUDIO_SERVICE_RESULT_MAGIC,.version=1,.action=op,.stream_id=42,.result=op==R4OS_AUDIO_SERVICE_OP_OPEN_STREAM?42:0};
  *header=(R4ServiceMessageHeader){.magic=R4OS_SERVICE_API_MAGIC,.version=1,.op=op,.payload_len=sizeof(control)};memcpy(response,&control,sizeof(control));return sizeof(control);
 }
 R4AudioServiceStreamWriteRequest input;memcpy(&input,request,sizeof(input));
 AUDIO25_CHECK(channel==7&&op==R4OS_AUDIO_SERVICE_OP_WRITE_STREAM&&capacity==120&&input.stream_id==42&&input.byte_count==length-sizeof(input)&&input.byte_count%4==0,-91);
 if(au25_now>=10000000)au25_late++;
 au25_ticks[au25_calls++]=ticks;au25_now+=3000000;
 if(au25_mode==3)return R4OS_SERVICE_API_RESULT_TIMEOUT;
 uint32_t n=au25_mode==1?0:au25_mode==2?3:4;
 R4AudioServiceStreamResult reply={.magic=R4OS_AUDIO_SERVICE_RESULT_MAGIC,.version=1,.action=op,.stream_id=42,.bytes=n,.result=au25_mode==1?R4OS_SERVICE_API_RESULT_BUSY:(int32_t)n,.flags=24};
 *header=(R4ServiceMessageHeader){.magic=R4OS_SERVICE_API_MAGIC,.version=1,.op=op,.payload_len=sizeof(reply)};
 memcpy(response,&reply,sizeof(reply));return sizeof(reply);
}
static int32_t au25_open(const uint8_t *name,R4ServiceInfo *out){AUDIO25_CHECK(!strcmp((const char *)name,"AUDSVC"),-93);*out=(R4ServiceInfo){.handle=7};return 0;}
static int32_t au25_close(uint32_t channel){return channel==7?0:-94;}
void sdk_audio25_tables(R4XStartR4Sys2 *sys,uint32_t mode){
 au25_now=0;au25_calls=0;au25_late=0;au25_mode=mode;
 *sys=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=2,.size=sizeof(*sys),.service_call=(uintptr_t)&au25_call,.monotonic_clock=(uintptr_t)&au25_clock,.service_open=(uintptr_t)&au25_open,.service_close=(uintptr_t)&au25_close};
}
uint32_t sdk_audio25_calls(void){return au25_calls;}
int32_t sdk_audio25_c_case(void){
 R4XStartR4Sys2 sys;sdk_audio25_tables(&sys,0);
 R4XStartImport imports={.group_id=1,.resolved_version=2,.table=(uintptr_t)&sys};
 R4XStartContext2 raw={.magic=R4OS2_START_MAGIC,.abi_major=2,.size=sizeof(raw),.app_class=R4XSTART_APP_CLASS_CONSOLE,.import_count=1,.imports=(uintptr_t)&imports};R4OS2Context context;
 AUDIO25_CHECK(!R4OS2ContextInit(&raw,&context),1);
 R4SdkAudioWriterProvider provider;AUDIO25_CHECK(!R4SdkAudioWriterProvider2(&context,7,42,4,&provider),2);
 const uint8_t data[64]={0};R4SdkAudioWriter writer;R4SdkAudioWriteProgress p;
 AUDIO25_CHECK(!R4SdkAudioWriterInit((R4SdkWireSpan){(uintptr_t)data,sizeof(data)},provider,(R4Timeout){.kind=1,.nanoseconds=10000000},&writer),3);
 AUDIO25_CHECK(!R4SdkAudioWriterStep(&writer,64,0,&p)&&au25_calls==4&&au25_late==0&&au25_now==12000000&&p.io.bytes==16&&p.accepted_frames==4&&p.io.outcome==4&&p.service_flags_valid==1&&p.last_service_flags==24,4);
 AUDIO25_CHECK(au25_ticks[0]==10&&au25_ticks[1]==7&&au25_ticks[2]==4&&au25_ticks[3]==1,5);
 R4SdkClockSample sample={.identity={.source=1,.generation=41,.tick_hz=1000}};R4SdkPcmSourcePacer pacer;R4SdkPcmSourceDeadline d;
 AUDIO25_CHECK(!R4SdkPcmSourceInit(48000,4,7680,sample,&pacer),6);
 AUDIO25_CHECK(!R4SdkPcmSourceAccepted(&pacer,3840,sample,&d)&&d.accepted_frames==960&&d.source_end_ns==20000000&&d.wait_ns==0,7);
 AUDIO25_CHECK(!R4SdkPcmSourceGetDeadline(&pacer,sample,1,&d)&&d.wait_ns==20000000,8);
 R4SdkPcmSourcePacer before=pacer;AUDIO25_CHECK(R4SdkPcmSourceAccepted(&pacer,3,sample,&d)==-303&&memcmp(&pacer,&before,sizeof(pacer))==0,9);
 AUDIO25_CHECK(!R4SdkPcmSourcePause(&pacer,sample,0)&&!R4SdkPcmSourceGetDeadline(&pacer,sample,1,&d)&&d.wait_ns==0&&d.accepted_frames==960,10);
 /* The ordinary C facade must obey that same total budget too. */
 sdk_audio25_tables(&sys,0);R4App facade;R4App2Memory memory={0};
 AUDIO25_CHECK(!r4_app_init2(&context,&memory,&facade),11);
 R4AudioStream stream={.connection={.app=&facade,.raw=7},.stream_id=42,.owned=1,.frame_bytes=4};
 R4AudioResult result=r4_audio_stream_write(&stream,data,sizeof(data),(R4Timeout){.kind=1,.nanoseconds=10000000});
 AUDIO25_CHECK(result.kind==R4_AUDIO_RESULT_TIMED_OUT&&result.bytes==16&&au25_calls==4&&au25_late==0,12);
 AUDIO25_CHECK(au25_ticks[0]==10&&au25_ticks[1]==7&&au25_ticks[2]==4&&au25_ticks[3]==1&&stream.stream_id==42&&stream.connection.raw==7,13);
 return 0;
}
#undef AUDIO25_CHECK
