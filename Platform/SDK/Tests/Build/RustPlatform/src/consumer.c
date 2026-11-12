#include <r4os/gui_bridge.h>
static int ok(R4SdkGuiSlot s){return !s.status && !(s.flags&R4SDK_GUI_NATIVE_ERROR);}
int32_t sdk58_audio_c(R4SdkAudioAudio *audio){
    R4Timeout timeout={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=2000000000};
    R4SdkAudioOpenResult opened;R4SdkAudioAudioStream stream;R4SdkAudioWriteResult written;R4SdkAudioResult closed;
    if(!ok(R4SdkAudioAudio_openStream(0,audio,48000,2,1,0x10000,&timeout,&opened)))return 1;
    R4SdkGuiSlot tag=R4SdkAudioOpenResult_inspect(&opened);
    if(!ok(tag) || tag.bits!=R4SdkAudioOpenResult_TAG_stream || !ok(R4SdkAudioOpenResult_get_stream(&opened,&stream)))return 2;
    uint8_t silence[64]={0};int result=0;
    if(!ok(R4SdkAudioAudioStream_writeOnce(0,&stream,silence,sizeof(silence),&timeout,&written)))result=3;
    else{
        tag=R4SdkAudioWriteResult_inspect(&written);
        if(!ok(tag) || tag.bits!=R4SdkAudioWriteResult_TAG_written || R4SdkAudioWriteResult_get_written(&written).bits!=sizeof(silence))result=4;
    }
    if(!ok(R4SdkAudioAudioStream_close(0,&stream,&timeout,&closed)))return 5;
    tag=R4SdkAudioResult_inspect(&closed);
    if(!ok(tag) || tag.bits!=R4SdkAudioResult_TAG_ok || R4SdkAudioAudioStream_valid(0,&stream).bits)return 6;
    return result;
}
