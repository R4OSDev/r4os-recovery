#include <r4os/r4os.h>
#include "../../../Simulation/SubsystemParity.c"
static void number(R4Console *c,uint64_t n){char s[32];unsigned p=sizeof(s);do{s[--p]=(char)('0'+n%10);n/=10;}while(n);r4_console_write(c,(const uint8_t*)s+p,sizeof(s)-p);}
static int32_t run(R4App *app){
 R4Console console=r4_app_console(app);uint64_t count=0;const uint8_t *args=r4_app_args(app,&count);R4SdkSubsystemLaunchRequest request;
 S parsed=R4SdkSubsystemLaunch_parse(0,args,count,&request);if(!good(parsed))return 1;
 S guest=R4SdkSubsystemLaunchRequest_get_guest_path(&request);const char path[]="C:\\TEMP\\SYNTH65.S65";
 if(guest.length!=sizeof(path)-1||bytes_compare(guest.ptr,path,sizeof(path)-1))return 2;
 int source=sdk65_guest_source(app->context);if(source)return source;
 source=sdk65_guest_catalogue(app->context,"test.sdk65.c");if(source)return source;
 uint64_t summary[7];int rc=sdk65_c_runtime(summary);if(rc)return 10+rc;
 uint64_t video[2];rc=sdk65_c_video(video);if(rc)return 40+rc;
 uint64_t audio[5];rc=sdk65_c_audio(audio);if(rc)return 60+rc;
 const char *names[]={"SDK65 WORK steps="," ops="," resets="," presents="," checksum="," time_ns="};
 for(unsigned i=0;i<6;i++){r4_console_write(&console,(const uint8_t*)names[i],r4os_cstr_len(names[i]));number(&console,summary[i]);}r4_console_write(&console,(const uint8_t*)"\n",1);
 rc=sdk65_guest_media_save(app->context);if(rc)return rc;
 r4_console_line(&console,"PASS SDK65 C guest: canonical launch, same work/video, audio failure, real owned save/reopen/async join and window");return 0;
}

int32_t r4_app_main(R4App *app){int code=run(app);return sdk65_guest_report(app->context,'C',code);}
