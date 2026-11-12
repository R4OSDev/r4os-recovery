/* Explicit, on-demand public C observer for the real MouseLook guest case.
 * K:pid:gen retains portable completion/output;
 * R:pid:gen:cookie reads completed output and closes; X/C:pid:gen kills/closes.
 * W/A send actual remote wheel/absolute move; S:pid:gen:epoch:window:id
 * proves foreign/stale capture rejection. It neither consumes the Desktop's owner wait/reap nor fabricates input. */
#include <r4os/app_resources.h>
static void text(R4App *a,const char *s){(void)r4sys_write_cstr(&a->system,s);}
static void n(R4App *a,int64_t v){char b[24];uint32_t c=0;uint64_t u=v<0?(uint64_t)(-(v+1))+1:(uint64_t)v;if(v<0)text(a,"-");do{b[c++]=(char)('0'+u%10);u/=10;}while(u);while(c)(void)r4sys_write(&a->system,(const uint8_t *)&b[--c],1);}
static void f(R4App *a,const char *s,int64_t v){text(a,s);n(a,v);}
static int part(const uint8_t *p,uint64_t length,uint64_t *at,uint64_t *out){
 uint64_t v=0,start=*at;while(*at<length&&p[*at]>='0'&&p[*at]<='9'){
  uint64_t d=p[(*at)++]-'0';if(v>(UINT64_MAX-d)/10)return 0;v=v*10+d;
 }if(*at==start)return 0;*out=v;if(*at<length){if(p[(*at)++]!=':')return 0;}return 1;
}
int32_t r4_app_main(R4App *a){
 uint64_t len=0;const uint8_t *args=r4_app_args(a,&len);if(!args||!len)return 2;
 if(args[0]=='W'||args[0]=='A'){
  R4RemoteInputEvent event={.magic=R4_REMOTE_INPUT_MAGIC,.version=R4_REMOTE_INPUT_VERSION,
   .kind=args[0]=='W'?R4_REMOTE_INPUT_KIND_MOUSE_WHEEL:R4_REMOTE_INPUT_KIND_MOUSE_MOVE,
   .wheel=args[0]=='W'?1:0,.x=40,.y=40};
  int32_t rc=r4desk_remote_input_push(&a->desktop,&event);text(a,"M28REMOTE");f(a," kind=",event.kind);f(a," rc=",rc);text(a,"\n");return rc<0?1:0;
 }
 uint64_t at=2,id=0,generation=0,cookie=0;
 if(len<3||args[1]!=':'||!part(args,len,&at,&id)||!part(args,len,&at,&generation)||!id||id>UINT32_MAX||!generation)return 2;
 R4ProgramProcessHandle process={.instance_id=(uint32_t)id,.generation=generation};
 if(args[0]=='S'){
  uint64_t epoch=0,window=0,serial=0;
  if(!part(args,len,&at,&epoch)||!part(args,len,&at,&window)||!part(args,len,&at,&serial)||window>INT32_MAX)return 2;
  R4GuiPointerCaptureHandle token={.window={.owner=process,.epoch=epoch,.window_id=(int32_t)window},.id=serial};
  R4GuiPointerCaptureInfo out;for(uint32_t i=0;i<sizeof out;++i)((uint8_t *)&out)[i]=0xa5;
  int32_t query=r4desk_gui_pointer_capture_info(&a->desktop,&token,&out);
  int32_t release=r4desk_gui_pointer_capture_release(&a->desktop,&token);int untouched=1;
  for(uint32_t i=0;i<sizeof out;++i)if(((uint8_t *)&out)[i]!=0xa5)untouched=0;
  text(a,"M28STALE");f(a," query=",query);f(a," release=",release);f(a," untouched=",untouched);text(a,"\n");
  return query==R4OS_GUI_POINTER_ERROR_STALE&&release==R4OS_GUI_POINTER_ERROR_STALE&&untouched?0:1;
 }
 if(args[0]=='X'||args[0]=='C'){
  int32_t rc=args[0]=='X'?((R4SysProgramHandleKillFn)(uintptr_t)a->system.table->program_handle_kill)(&process)
   :((R4SysProgramHandleRequestCloseFn)(uintptr_t)a->system.table->program_handle_request_close)(&process);
  text(a,"M28CONTROL");f(a," action=",args[0]);f(a," rc=",rc);text(a,"\n");return rc?1:0;
 }
 R4Resources resources={.app=a};R4ProgramObservationHandle observation={.process=process};
 int32_t rc=0;
 if(args[0]=='K'){
  rc=r4_resources_observation_retain(&resources,&process,R4OS_PROGRAM_OBSERVATION_FLAG_PORTABLE,&observation);
  text(a,"M28KEEP");f(a," rc=",rc);f(a," id=",observation.id);text(a,"\n");return rc?1:0;
 }
 if(args[0]!='R'||!part(args,len,&at,&cookie)||!cookie)return 2;observation.id=cookie;
 R4ProgramProcessCompletion completion={0};
 rc=r4_resources_observation_wait(&resources,&observation,r4_timeout_poll(),&completion);
 text(a,"M28OBS");f(a," wait=",rc);f(a," flags=",completion.flags);f(a," length=",completion.output_length);
 f(a," exit=",completion.exit_code);text(a,"\n");
 if(rc)return 0; /* Pending is observable and leaves the portable lease intact. */
 uint32_t offset=0;uint8_t bytes[512];text(a,"M28OUTPUT-BEGIN\n");
 while(offset<completion.output_length){uint32_t got=0;rc=r4_resources_observation_read(&resources,&observation,offset,bytes,sizeof bytes,&got);
  if(rc||!got)break;(void)r4sys_write(&a->system,bytes,got);offset+=got;}
 text(a,"M28OUTPUT-END");f(a," read=",rc);f(a," bytes=",offset);
 f(a," release=",r4_resources_observation_release(&resources,&observation));text(a,"\n");return rc?1:0;
}
