#ifndef R4OS_AUDIO_CAPTURE_PLATFORM2_H
#define R4OS_AUDIO_CAPTURE_PLATFORM2_H
#include "platform2.h"
#include "poll_budget.h"
/* Copied AUDSVC transport. Explicit stream Stop/Close and channel Disconnect;
 * cancellation/timeouts never acknowledge driver DMA/pins or implicit Drop. */
typedef struct R4SdkCaptureClient {
 R4SysServiceCallFn call; R4SysServiceCloseFn disconnect; R4SysMonotonicClockFn clock;
 uint32_t channel; uint64_t client_generation, transport_ticks;
} R4SdkCaptureClient;
static inline int32_t R4SdkCaptureConnect2(const R4OS2Context *ctx,uint64_t ticks,R4SdkCaptureClient *out){
 if(!ctx||!ctx->raw||!out||!ticks||!ctx->raw->instance_id||ctx->raw->instance_id>UINT32_MAX)return R4OS_AUDIO_CAPTURE_ERROR_INVALID;
 uint64_t open=0,call=0,close=0,clock=0,process=0;
 if(R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_open),&open)||R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_call),&call)||R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_close),&close)||R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,monotonic_clock),&clock)||R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,program_open_handle),&process))return R4OS_AUDIO_CAPTURE_ERROR_UNSUPPORTED;
 R4ProgramProcessHandle own={0};if(((R4SysProgramOpenHandleFn)(uintptr_t)process)((uint32_t)ctx->raw->instance_id,&own)!=R4OS_PROGRAM_HANDLE_OK||own.instance_id!=(uint32_t)ctx->raw->instance_id||!own.generation||own.reserved)return R4OS_AUDIO_CAPTURE_ERROR_STALE;
 R4ServiceInfo endpoint={0};int32_t rc=((R4SysServiceOpenFn)(uintptr_t)open)((const uint8_t*)"AUDSVC",&endpoint);if(rc)return rc;if(!endpoint.handle)return R4OS_AUDIO_CAPTURE_ERROR_UNSUPPORTED;
 *out=(R4SdkCaptureClient){.call=(R4SysServiceCallFn)(uintptr_t)call,.disconnect=(R4SysServiceCloseFn)(uintptr_t)close,.clock=(R4SysMonotonicClockFn)(uintptr_t)clock,.channel=endpoint.handle,.client_generation=own.generation,.transport_ticks=ticks};return 0;
}
static inline int32_t R4SdkCaptureDisconnect(R4SdkCaptureClient *c){if(!c||!c->channel)return R4OS_AUDIO_CAPTURE_ERROR_STALE;int32_t rc=c->disconnect(c->channel);if(rc>=0)c->channel=0;return rc;}
static inline int R4SdkCaptureSameHandle(const R4AudioCaptureHandle *a,const R4AudioCaptureHandle *b){const uint8_t *x=(const uint8_t*)a,*y=(const uint8_t*)b;for(uint32_t i=0;i<sizeof(*a);i++)if(x[i]!=y[i])return 0;return 1;}
static inline int32_t R4SdkCaptureSample(const R4SdkCaptureClient *c,R4SdkClockSample *out){if(!c||!out)return R4OS_AUDIO_CAPTURE_ERROR_INVALID;R4MonotonicClockInfo info={0};if(c->clock(&info)<=0||R4SdkClockSampleRead(&info,out))return R4OS_AUDIO_CAPTURE_ERROR_CLOCK_CHANGED;return 0;}
static inline int32_t R4SdkCaptureRequest(const R4SdkCaptureClient *c,const R4AudioCaptureRequest *input,uint8_t *bytes,uint32_t capacity,R4AudioCaptureReply *out,uint64_t ticks){
 if(!c||!c->channel||!input||!out||(!bytes&&capacity)||capacity>R4OS_AUDIO_CAPTURE_MAX_READ_BYTES||!ticks)return R4OS_AUDIO_CAPTURE_ERROR_INVALID;
 R4AudioCaptureRequest q=*input;q.client_generation=c->client_generation;q.buffer_bytes=q.op==R4OS_AUDIO_CAPTURE_OP_READ?capacity:0;R4ServiceMessageHeader header={0};uint8_t payload[sizeof(R4AudioCaptureReply)+R4OS_AUDIO_CAPTURE_MAX_READ_BYTES];
 int32_t rc=c->call(c->channel,R4OS_AUDIO_CAPTURE_OP_SERVICE,(const uint8_t*)&q,sizeof(q),&header,payload,sizeof(payload),ticks);
 if(rc<0)return q.op==R4OS_AUDIO_CAPTURE_OP_CATALOG||q.op==R4OS_AUDIO_CAPTURE_OP_QUERY?rc:R4OS_AUDIO_CAPTURE_ERROR_UNKNOWN_OUTCOME;
 if(header.status==R4OS_SERVICE_API_RESULT_BAD_OP)return R4OS_AUDIO_CAPTURE_ERROR_UNSUPPORTED;
 if(header.status)return header.status<0?header.status:R4OS_AUDIO_CAPTURE_ERROR_INVALID;
 if((uint32_t)rc<sizeof(R4AudioCaptureReply))return R4OS_AUDIO_CAPTURE_ERROR_PROVIDER;
 R4AudioCaptureReply r;__builtin_memcpy(&r,payload,sizeof(r));
 if(r.version!=1||r.size!=sizeof(r)||r.reserved||r.result>0||(r.flags&~31u)||r.bytes>capacity||(uint64_t)r.bytes+sizeof(r)!=(uint32_t)rc||(r.result<0&&(r.bytes||r.frames)))return R4OS_AUDIO_CAPTURE_ERROR_PROVIDER;
 if(r.bytes&&(q.op!=R4OS_AUDIO_CAPTURE_OP_READ||!r.format.frame_bytes||r.frames>q.frames||(uint64_t)r.frames*r.format.frame_bytes!=r.bytes))return R4OS_AUDIO_CAPTURE_ERROR_PROVIDER;
 if(q.op>=R4OS_AUDIO_CAPTURE_OP_READ&&!R4SdkCaptureSameHandle(&q.handle,&r.handle))return R4OS_AUDIO_CAPTURE_ERROR_STALE;
 if(!(r.flags&R4OS_AUDIO_CAPTURE_REPLY_HARDWARE_TIMESTAMP)&&r.first_timestamp)return R4OS_AUDIO_CAPTURE_ERROR_PROVIDER;
 if(r.bytes)__builtin_memcpy(bytes,payload+sizeof(r),r.bytes);*out=r;return r.result;
}
static inline R4AudioCaptureRequest R4SdkCaptureQueryRequest(uint32_t op,R4AudioCaptureHandle id){R4AudioCaptureRequest q={.version=1,.size=sizeof(q),.op=op,.handle=id};return q;}
static inline int32_t R4SdkCaptureCatalog(const R4SdkCaptureClient *c,uint64_t index,R4AudioCaptureReply *out){R4AudioCaptureRequest q={.version=1,.size=sizeof(q),.op=R4OS_AUDIO_CAPTURE_OP_CATALOG,.handle={.source={.source=index}}};return R4SdkCaptureRequest(c,&q,NULL,0,out,c?c->transport_ticks:0);}
static inline int32_t R4SdkCaptureOpen(const R4SdkCaptureClient *c,R4AudioCaptureSourceId source,R4AudioCaptureFormat format,uint32_t queue_frames,R4AudioCaptureReply *out){R4AudioCaptureRequest q={.version=1,.size=sizeof(q),.op=R4OS_AUDIO_CAPTURE_OP_OPEN,.handle={.source=source},.format=format,.queue_frames=queue_frames};return R4SdkCaptureRequest(c,&q,NULL,0,out,c?c->transport_ticks:0);}
static inline int32_t R4SdkCaptureQuery(const R4SdkCaptureClient *c,R4AudioCaptureHandle id,R4AudioCaptureReply *out){R4AudioCaptureRequest q=R4SdkCaptureQueryRequest(R4OS_AUDIO_CAPTURE_OP_QUERY,id);return R4SdkCaptureRequest(c,&q,NULL,0,out,c?c->transport_ticks:0);}
static inline int32_t R4SdkCaptureStop(const R4SdkCaptureClient *c,R4AudioCaptureHandle id,R4AudioCaptureReply *out){R4AudioCaptureRequest q=R4SdkCaptureQueryRequest(R4OS_AUDIO_CAPTURE_OP_STOP,id);return R4SdkCaptureRequest(c,&q,NULL,0,out,c?c->transport_ticks:0);}
static inline int32_t R4SdkCaptureClose(const R4SdkCaptureClient *c,R4AudioCaptureHandle id,R4AudioCaptureReply *out){R4AudioCaptureRequest q=R4SdkCaptureQueryRequest(R4OS_AUDIO_CAPTURE_OP_CLOSE,id);return R4SdkCaptureRequest(c,&q,NULL,0,out,c?c->transport_ticks:0);}
static inline int32_t R4SdkCaptureReadPoll(const R4SdkCaptureClient *c,R4AudioCaptureHandle id,uint32_t frames,uint8_t *bytes,uint32_t capacity,R4AudioCaptureReply *out){R4AudioCaptureRequest q=R4SdkCaptureQueryRequest(R4OS_AUDIO_CAPTURE_OP_READ,id);q.frames=frames;return R4SdkCaptureRequest(c,&q,bytes,capacity,out,c?c->transport_ticks:0);}
typedef struct R4SdkCaptureRead {R4AudioCaptureHandle id;R4SdkDeadlineBudget budget;uint32_t mode,cancelled,done;} R4SdkCaptureRead;
static inline int32_t R4SdkCaptureReadInit(R4AudioCaptureHandle id,R4SdkClockSample sample,R4Timeout timeout,R4SdkCaptureRead *out){
 if(!out)return R4OS_AUDIO_CAPTURE_ERROR_INVALID;R4SdkDeadlineBudget budget;int32_t rc=R4SdkDeadlineBudgetInit(sample,timeout,&budget);if(rc)return rc==R4_BUDGET_INVALID_TIMEOUT?R4OS_AUDIO_CAPTURE_ERROR_INVALID:R4OS_AUDIO_CAPTURE_ERROR_CLOCK_CHANGED;
 *out=(R4SdkCaptureRead){.id=id,.budget=budget,.mode=budget.kind};return 0;
}
static inline void R4SdkCaptureReadCancel(R4SdkCaptureRead *r){if(r)r->cancelled=1;}
static inline int32_t R4SdkCaptureReadStep(R4SdkCaptureRead *r,const R4SdkCaptureClient *c,uint32_t frames,uint8_t *bytes,uint32_t capacity,R4AudioCaptureReply *out){
 if(!r||!c)return R4OS_AUDIO_CAPTURE_ERROR_INVALID;if(r->cancelled){r->done=1;return R4OS_AUDIO_CAPTURE_ERROR_CANCELLED;}if(r->done)return R4OS_AUDIO_CAPTURE_ERROR_STALE;
 R4SdkClockSample now;int32_t rc=R4SdkCaptureSample(c,&now);if(rc){r->done=1;return rc;}R4SdkBudgetValue left;
 if(R4SdkDeadlineBudgetRemaining(&r->budget,now,&left)){r->done=1;return R4OS_AUDIO_CAPTURE_ERROR_CLOCK_CHANGED;}
 if(r->mode==R4_BUDGET_FINITE&&left.kind==R4_BUDGET_POLL){r->done=1;return R4OS_AUDIO_CAPTURE_ERROR_TIMED_OUT;}
 uint64_t ticks=c->transport_ticks;if(left.kind==R4_BUDGET_FINITE){R4Timeout timeout={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=left.value};R4SdkBudgetValue span;if(R4SdkTimeoutTicksChecked(timeout,now.identity.tick_hz,&span)){r->done=1;return R4OS_AUDIO_CAPTURE_ERROR_CLOCK_CHANGED;}if(span.value<ticks)ticks=span.value;}
 R4AudioCaptureRequest q=R4SdkCaptureQueryRequest(R4OS_AUDIO_CAPTURE_OP_READ,r->id);q.frames=frames;rc=R4SdkCaptureRequest(c,&q,bytes,capacity,out,ticks?ticks:1);if(rc!=R4OS_AUDIO_CAPTURE_ERROR_WOULD_BLOCK||r->mode==R4_BUDGET_POLL)r->done=1;return rc;
}
#endif
