#include <r4os/protocol.h>
typedef struct Request {uint64_t epoch,value,ticket;} Request;
static R4ProtocolContext context;
static R4ProtocolGate gate={.epoch=0x680043};
static R4ProtocolLease loan;
static uint64_t *backing,sequence,pending;
static int initialized;
static int32_t p68c_shutdown(void){
 if(!initialized)return 0;
 R4ProtocolClosed closed;
 if(r4protocol_gate_close(&gate,&closed))return -6;
 if(backing){r4protocol_free(&context,backing,64);backing=0;}
 if(r4protocol_status(&context,R4ABI_PROTOCOL_STATE_DISABLED,(const uint8_t *)"P68C resources closed"))return -9;
 r4protocol_log_info(&context,(const uint8_t *)"PASS P68C explicit ProtocolShutdown backing=closed calls=0");return 0;
}
static int32_t p68c_init(const R4ProtocolApi *api){
 if(r4protocol_init(&context,api))return -1;
 if(r4protocol_register(&context,(const uint8_t *)"misc.sdk68.wrong",R4ABI_PROTOCOL_CATEGORY_MISC,0)!=-2)return -2;
 if(r4protocol_register(&context,(const uint8_t *)"misc.sdk68.c",R4ABI_PROTOCOL_CATEGORY_MISC,0))return -3;
 backing=r4protocol_alloc(&context,64,8);if(!backing)return -4;
 for(uint32_t i=0;i<8;i++)backing[i]=0;
 initialized=1;
 r4protocol_status(&context,R4ABI_PROTOCOL_STATE_ACTIVE,(const uint8_t *)"P68C real C root");
 r4protocol_log_info(&context,(const uint8_t *)"PASS P68C Init wrong-role rejected current PPI borrowed");return 0;
}
static int32_t p68c_query(R4ProtocolStatus *out){
 *out=(R4ProtocolStatus){.state=gate.phase==2?R4ABI_PROTOCOL_STATE_DISABLED:R4ABI_PROTOCOL_STATE_ACTIVE};return 0;
}
static int32_t respond(R4ProtocolBuffer *out,Request value){
 if(!out || !out->data || out->capacity<sizeof(value))return -2;
 uint8_t *dst=out->data;const uint8_t *src=(const uint8_t *)&value;for(uint32_t i=0;i<sizeof(value);i++)dst[i]=src[i];out->len=sizeof(value);return 0;
}
static int32_t p68c_dispatch(uint32_t op,const R4ProtocolBuffer *in,R4ProtocolBuffer *out){
 if(op==4)return p68c_shutdown();
 if(op==0)return respond(out,(Request){.epoch=gate.epoch,.value=gate.active,.ticket=backing?1:0});
 if(!in || !in->data || in->len!=sizeof(Request) || in->capacity<in->len)return -2;
 Request r;for(uint32_t i=0;i<sizeof(r);i++)((uint8_t *)&r)[i]=((const uint8_t *)in->data)[i];
 if(r.epoch!=gate.epoch)return -3;
 if(op==1){
  if(!out || !out->data || out->capacity<sizeof(Request))return -2;
  if(pending || !backing || sequence==UINT64_MAX)return -6;
  R4ProtocolLease opened;if(r4protocol_gate_enter(&gate,&opened))return -7;
  loan=opened;pending=++sequence;backing[0]=r.value;
  return respond(out,(Request){.epoch=gate.epoch,.value=gate.active,.ticket=pending});
 }
 if((op==2 || op==3) && pending && r.ticket==pending){
  Request result={.epoch=gate.epoch,.value=op==2?backing[0]+0x43:0,.ticket=pending};
  if(!out || !out->data || out->capacity<sizeof(result))return -2;
  if(r4protocol_lease_finish(&loan))return -8;pending=0;return respond(out,result);
 }
 return -4;
}
R4P_ENTRIES(p68c_init,p68c_shutdown,p68c_query,p68c_dispatch);
