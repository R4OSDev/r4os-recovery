#ifndef R4OS_TEXT_COMPOSITION_PLATFORM2_H
#define R4OS_TEXT_COMPOSITION_PLATFORM2_H
#include "text_composition.h"
#include "platform2.h"
/* Explicit read-only original WINSVC channel, called outside GUI/text locks.
 * Context/tables/code outlive actual calls and successful explicit Close.
 * No retry, fallback or implicit Drop. Reply.result is distinct from transport.
 * Current WINSVC has no inputmethod engine: NoProvider, feature=false. */
typedef struct R4SdkCompositionClient {R4SysServiceCallFn call;R4SysServiceCloseFn close;uint32_t handle;uint64_t timeout_ticks;} R4SdkCompositionClient;
static inline int32_t R4SdkCompositionConnect2(const R4OS2Context *context,uint64_t timeout,R4SdkCompositionClient *out){
 if(!out||!timeout)return R4OS_COMPOSITION_ERROR_INVALID;
 uint64_t open=0,call=0,close=0;int32_t code=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_open),&open);if(code)return code;
 code=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_call),&call);if(code)return code;
 code=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_close),&close);if(code)return code;
 R4ServiceInfo info={0};code=((R4SysServiceOpenFn)(uintptr_t)open)((const uint8_t*)"WINSVC",&info);if(code)return code;
 if(!info.handle)return R4OS_COMPOSITION_ERROR_UNSUPPORTED;
 *out=(R4SdkCompositionClient){.call=(R4SysServiceCallFn)(uintptr_t)call,.close=(R4SysServiceCloseFn)(uintptr_t)close,.handle=info.handle,.timeout_ticks=timeout};return 0;
}
static inline int32_t R4SdkCompositionClientClose(R4SdkCompositionClient *client){
 if(!client||!client->handle)return R4OS_COMPOSITION_ERROR_INVALID;
 int32_t code=client->close(client->handle);if(code>=0)client->handle=0;return code;
}
static inline int32_t R4SdkCompositionRpc(const R4SdkCompositionClient *client,uint16_t op,const uint8_t *request,uint32_t count,void *out,uint32_t capacity){
 if(!client||!client->handle)return R4OS_COMPOSITION_ERROR_INVALID;R4ServiceMessageHeader header={0};
 int32_t code=client->call(client->handle,op,request,count,&header,(uint8_t*)out,capacity,client->timeout_ticks);if(code<0)return code;
 if(header.status==R4OS_SERVICE_API_RESULT_BAD_OP)return R4OS_COMPOSITION_ERROR_UNSUPPORTED;
 if(header.status)return header.status<0?header.status:R4OS_COMPOSITION_ERROR_INVALID;
 return (uint32_t)code==capacity?0:R4OS_COMPOSITION_ERROR_INVALID;
}
static inline int32_t R4SdkCompositionCapability(const R4SdkCompositionClient *client,R4CompositionCapabilityReply *out){
 if(!out)return R4OS_COMPOSITION_ERROR_INVALID;R4CompositionCapabilityReply value={0};
 int32_t code=R4SdkCompositionRpc(client,R4OS_COMPOSITION_OP_CAPABILITY,(const uint8_t*)"",0,&value,sizeof(value));if(code)return code;
 R4CompositionProvider p=value.provider;
 if(value.reserved||p.version!=1||p.size!=sizeof(p)||!p.max_text_bytes||p.max_text_bytes>R4OS_COMPOSITION_MAX_TEXT_BYTES||p.features>1)return R4OS_COMPOSITION_ERROR_INVALID;
 if(!p.features){if(value.result!=R4OS_COMPOSITION_ERROR_NO_PROVIDER||p.process.instance_id||p.process.reserved||p.process.generation||p.generation)return R4OS_COMPOSITION_ERROR_INVALID;}
 else if(value.result||!p.process.instance_id||p.process.reserved||!p.process.generation||!p.generation)return R4OS_COMPOSITION_ERROR_INVALID;
 *out=value;return 0;
}
static inline int R4SdkCompositionSameWindow(const R4WindowModeIdentity *x,const R4WindowModeIdentity *y){
 const uint8_t *a=(const uint8_t*)x,*b=(const uint8_t*)y;for(uint32_t i=0;i<sizeof(*x);++i)if(a[i]!=b[i])return 0;return 1;
}
static inline int32_t R4SdkCompositionFocus(const R4SdkCompositionClient *client,R4WindowModeIdentity expected,R4CompositionFocusReply *out){
 if(!out)return R4OS_COMPOSITION_ERROR_INVALID;R4CompositionFocusReply value={0};
 int32_t code=R4SdkCompositionRpc(client,R4OS_COMPOSITION_OP_FOCUS,(const uint8_t*)&expected,sizeof(expected),&value,sizeof(value));if(code)return code;
 if(value.reserved||(value.result&&value.result!=R4OS_COMPOSITION_ERROR_NO_FOCUS&&value.result!=R4OS_COMPOSITION_ERROR_STALE_VIEW))return R4OS_COMPOSITION_ERROR_INVALID;
 if(!value.result){R4CompositionFocus f=value.focus;R4ProgramProcessHandle h[3]={f.window.service,f.window.desktop,f.window.owner};
  if(f.version!=1||f.size!=sizeof(f)||f.reserved||f.focused!=1||f.window.reserved||!f.window.serial||!f.view_generation||!f.focus_generation||!f.input_revision||!f.observed_tick||!R4SdkCompositionSameWindow(&f.window,&expected))return R4OS_COMPOSITION_ERROR_INVALID;
  for(uint32_t i=0;i<3;++i)if(!h[i].instance_id||h[i].reserved||!h[i].generation)return R4OS_COMPOSITION_ERROR_INVALID;
 }
 *out=value;return 0;
}
#endif
