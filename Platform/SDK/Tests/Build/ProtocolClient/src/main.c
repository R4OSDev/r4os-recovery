#include <r4os/r4os.h>
typedef struct Request{uint64_t epoch,value,ticket;} Request;
static R4App *app;
static const char *roles[2]={"misc.sdk68.c","misc.sdk68.rust"};
static int32_t call(uint32_t which,uint32_t op,Request *input,Request *output){
 R4ProtocolBuffer in={.data=input,.len=input?sizeof(*input):0,.capacity=input?sizeof(*input):0};
 R4ProtocolBuffer out={.data=output,.capacity=output?sizeof(*output):0};
 R4DevProtocolDispatchFn f=(R4DevProtocolDispatchFn)(uintptr_t)app->devices.table->protocol_dispatch;
 return f((const uint8_t *)roles[which],r4os_cstr_len(roles[which]),op,&in,&out);
}
int32_t r4_app_main(R4App *context){
 app=context;Request info[2],work[2],answer={0};
 /* Rust first requires the actual loader to activate its C dependency. */
 if(call(1,0,0,&info[1]) || call(0,0,0,&info[0]))return -1;
 for(uint32_t i=0;i<2;i++){
  if(!info[i].epoch || info[i].value || info[i].ticket!=1)return -2;
  Request in={.epoch=info[i].epoch,.value=7+i};
  if(call(i,1,&in,&work[i]) || !work[i].ticket || work[i].value!=1)return -3;
 }
 if(info[0].epoch==info[1].epoch)return -4;
 /* Explicit cancellation releases the exact ticket; a fresh generation stays usable. */
 for(uint32_t i=0;i<2;i++){
  Request cancel=work[i];
  if(call(i,3,&cancel,&answer) || call(i,3,&cancel,&answer)>=0)return -14;
  Request in={.epoch=info[i].epoch,.value=7+i};
  if(call(i,1,&in,&work[i]) || work[i].ticket==cancel.ticket)return -15;
 }
 for(uint32_t i=0;i<2;i++){
  if(call(i,4,0,0)!=-6)return -5;
  Request in={.epoch=info[i].epoch,.value=91};
  if(call(i,1,&in,&answer)>=0)return -6;
  Request bad=work[i];bad.epoch--;
  Request sentinel={.epoch=0x1234,.value=0x5678,.ticket=0x9abc};answer=sentinel;
  if(call(i,2,&bad,&answer)!=-3 || answer.epoch!=sentinel.epoch || answer.value!=sentinel.value || answer.ticket!=sentinel.ticket)return -7;
  bad=work[i];bad.ticket++;
  if(call(i,2,&bad,&answer)>=0)return -8;
  if(call(i,0,0,&answer) || answer.value!=1 || answer.ticket!=1)return -9;
  Request finish=work[i];
  if(call(i,2,&finish,&answer) || answer.value!=(7+i)+(i?0x52:0x43))return -10;
  if(call(i,4,0,0))return -11;
  if(call(i,0,0,&answer)!=-5)return -12;
  /* The other provider continues despite exact close of this role. */
  if(i==0 && (call(1,0,0,&answer) || answer.value!=1 || answer.ticket!=1))return -13;
 }
 r4sys_write_cstr(&app->system,"PASS Protocol68 true C/Rust R4P dependency/dispatch/cancel; stale epoch/ticket output unchanged; close Busy backing retained, finish then exact shutdown, other role isolated\n");return 0;
}
