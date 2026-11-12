#ifndef R4OS_AUDIO_WRITE_PLATFORM2_H
#define R4OS_AUDIO_WRITE_PLATFORM2_H
#include "platform2.h"
#include "audio_write.h"
static inline int32_t R4SdkAudioWriterProvider2(const R4OS2Context *context,uint32_t channel,uint32_t stream,uint32_t frame_bytes,R4SdkAudioWriterProvider *out){
 if(!out)return R4_AUDIO_WRITE_INVALID;
 uint64_t call=0,clock=0;
 int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_call),&call);if(rc)return rc;
 rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,monotonic_clock),&clock);if(rc)return rc;
 *out=(R4SdkAudioWriterProvider){.call=(R4SysServiceCallFn)(uintptr_t)call,.monotonic=(R4SysMonotonicClockFn)(uintptr_t)clock,.service_handle=channel,.stream_id=stream,.frame_bytes=frame_bytes};return 0;
}
#endif
