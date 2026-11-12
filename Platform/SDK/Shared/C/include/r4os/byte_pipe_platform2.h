#ifndef R4OS_BYTE_PIPE_PLATFORM2_H
#define R4OS_BYTE_PIPE_PLATFORM2_H
#include "wait_set_platform2.h"
/* Copying an End never duplicates ownership. Close each reference; actual
 * process retirement closes remaining references. Failed Close keeps an exact
 * retry identity. No automatic inheritance, shell pipeline or WaitSource. */
typedef struct R4SdkBytePipeProvider {
 R4SysBytePipeCreateFn create; R4SysBytePipeDupFn duplicate;
 R4SysBytePipeReadFn read; R4SysBytePipeWriteFn write;
 R4SysBytePipeCancelFn cancel; R4SysBytePipeCloseFn close;
 R4SysBytePipeInfoFn info;
} R4SdkBytePipeProvider;
static inline int32_t R4SdkBytePipeProvider2(const R4OS2Context *context,R4SdkBytePipeProvider *out){
 if(!out)return R4OS_BYTE_PIPE_ERROR_INVALID;
 const uint32_t offsets[7]={offsetof(R4XStartR4Sys2,byte_pipe_create),offsetof(R4XStartR4Sys2,byte_pipe_dup),offsetof(R4XStartR4Sys2,byte_pipe_read),offsetof(R4XStartR4Sys2,byte_pipe_write),offsetof(R4XStartR4Sys2,byte_pipe_cancel),offsetof(R4XStartR4Sys2,byte_pipe_close),offsetof(R4XStartR4Sys2,byte_pipe_info)};
 uint64_t a[7]={0};
 for(uint32_t i=0;i<7;++i){int32_t rc=R4OS2ContextFunction(context,1,offsets[i],&a[i]);if(rc)return rc;}
 *out=(R4SdkBytePipeProvider){(R4SysBytePipeCreateFn)(uintptr_t)a[0],(R4SysBytePipeDupFn)(uintptr_t)a[1],(R4SysBytePipeReadFn)(uintptr_t)a[2],(R4SysBytePipeWriteFn)(uintptr_t)a[3],(R4SysBytePipeCancelFn)(uintptr_t)a[4],(R4SysBytePipeCloseFn)(uintptr_t)a[5],(R4SysBytePipeInfoFn)(uintptr_t)a[6]};return 0;
}
static inline R4WaitSetDeadline R4SdkBytePipePoll(void){return (R4WaitSetDeadline){.version=1,.size=sizeof(R4WaitSetDeadline),.kind=0};}
static inline R4WaitSetDeadline R4SdkBytePipeForever(void){return (R4WaitSetDeadline){.version=1,.size=sizeof(R4WaitSetDeadline),.kind=2};}
/* Exact same checked absolute budget as WaitSet, with no dependency on a set. */
static inline int32_t R4SdkBytePipeDeadline(const R4SdkDeadlineBudget *budget,R4WaitSetDeadline *out){return R4SdkWaitSetDeadlineFromBudget(budget,out);}
/* Same explicit ownership helpers as Zig/Rust; no destructor can hide a
 * failed release. Provider/table code must remain live through every call. */
typedef struct R4SdkBytePipeEndpoint {R4SdkBytePipeProvider provider;R4BytePipeEnd value;} R4SdkBytePipeEndpoint;
typedef struct R4SdkBytePipePair {R4SdkBytePipeEndpoint reader,writer;} R4SdkBytePipePair;
static inline int32_t R4SdkBytePipeCreate2(const R4OS2Context *context,uint64_t capacity,R4SdkBytePipePair *out){
 if(!out)return R4OS_BYTE_PIPE_ERROR_INVALID;
 R4SdkBytePipeProvider provider;int32_t rc=R4SdkBytePipeProvider2(context,&provider);if(rc)return rc;
 R4BytePipePair pair={0};rc=provider.create(capacity,&pair);if(!rc)*out=(R4SdkBytePipePair){.reader={provider,pair.reader},.writer={provider,pair.writer}};return rc;
}
static inline int32_t R4SdkBytePipeDuplicate(const R4SdkBytePipeEndpoint *end,R4SdkBytePipeEndpoint *out){
 if(!end||!out||end==out)return R4OS_BYTE_PIPE_ERROR_INVALID;
 R4BytePipeEnd value={0};int32_t rc=end->provider.duplicate(end->value,&value);if(!rc)*out=(R4SdkBytePipeEndpoint){end->provider,value};return rc;
}
static inline int32_t R4SdkBytePipeRead(const R4SdkBytePipeEndpoint *end,uint8_t *data,uint64_t length,const R4WaitSetDeadline *limit,R4BytePipeProgress *out){
 if(!end)return R4OS_BYTE_PIPE_ERROR_INVALID;
 return end->provider.read(end->value,data,length,limit,out);
}
static inline int32_t R4SdkBytePipeWrite(const R4SdkBytePipeEndpoint *end,const uint8_t *data,uint64_t length,const R4WaitSetDeadline *limit,R4BytePipeProgress *out){
 if(!end)return R4OS_BYTE_PIPE_ERROR_INVALID;
 return end->provider.write(end->value,data,length,limit,out);
}
static inline int32_t R4SdkBytePipeCancel(const R4SdkBytePipeEndpoint *end){
 return end?end->provider.cancel(end->value):R4OS_BYTE_PIPE_ERROR_INVALID;
}
static inline int32_t R4SdkBytePipeInfo(const R4SdkBytePipeEndpoint *end,R4BytePipeInfo *out){
 return end?end->provider.info(end->value,out):R4OS_BYTE_PIPE_ERROR_INVALID;
}
static inline int32_t R4SdkBytePipeClose(R4SdkBytePipeEndpoint *end){
 if(!end)return R4OS_BYTE_PIPE_ERROR_INVALID;
 if(!end->value.handle)return 0;
 int32_t rc=end->provider.close(end->value);if(!rc)end->value=(R4BytePipeEnd){0};return rc;
}
_Static_assert(sizeof(R4BytePipeEnd)==24,"pipe end");
_Static_assert(sizeof(R4BytePipePair)==56,"pipe pair");
_Static_assert(sizeof(R4BytePipeProgress)==24,"pipe progress");
_Static_assert(sizeof(R4BytePipeInfo)==48,"pipe info");
#endif
