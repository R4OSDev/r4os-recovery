#ifndef R4OS_LAUNCH_IO_PLATFORM2_H
#define R4OS_LAUNCH_IO_PLATFORM2_H
#include "byte_pipe_platform2.h"
/* Explicit optional Start2 launch. Every Pipe binding is retained separately
 * for the exact child generation; parent references remain owned by parent.
 * Copying a binding or stdio snapshot is never Dup. No implicit pipe inheritance. */
static inline R4LaunchIoBinding R4SdkLaunchIoPipe(R4BytePipeEnd end){return (R4LaunchIoBinding){.kind=R4OS_LAUNCH_IO_PIPE,.end=end};}
static inline R4LaunchIo R4SdkLaunchIoDefault(void){return (R4LaunchIo){.version=1,.size=sizeof(R4LaunchIo)};}
static inline int32_t R4SdkLaunchIo2(const R4OS2Context *context,const uint8_t *path,const uint8_t *args,const R4LaunchIo *io,R4ProgramProcessHandle *out){
 if(!path||!args||!io||!out)return R4OS_LAUNCH_IO_ERROR_INVALID;
 uint64_t address=0;int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,program_launch_io),&address);if(rc)return rc;
 return ((R4SysProgramLaunchIoFn)(uintptr_t)address)(path,args,io,out);
}
/* Stdio holds borrowed child refs from one immutable startup snapshot, with
 * explicit Close/Cancel. A failed Close keeps its exact identity for retry.
 * Pipe operations retain full native Poll/Finite/Forever semantics. Default
 * Console uses existing byte/routing/count semantics, Poll only, no EOF or
 * atomic-write guarantee. Existing console wait/event APIs remain separate. */
typedef struct R4SdkStdio {const R4OS2Context *context;R4LaunchIo snapshot;R4SdkBytePipeProvider pipes;} R4SdkStdio;
static inline int32_t R4SdkStdio2(const R4OS2Context *context,R4SdkStdio *out){
 if(!out)return R4OS_LAUNCH_IO_ERROR_INVALID;
 uint64_t address=0;int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,program_stdio),&address);if(rc)return rc;
 R4SdkStdio value={.context=context};rc=((R4SysProgramStdioFn)(uintptr_t)address)(&value.snapshot);if(rc)return rc;
 if(value.snapshot.version!=1||value.snapshot.size!=sizeof(R4LaunchIo))return R4OS_LAUNCH_IO_ERROR_INVALID;
 const R4LaunchIoBinding *b[3]={&value.snapshot.stdin_binding,&value.snapshot.stdout_binding,&value.snapshot.stderr_binding};
 uint32_t any=0;for(uint32_t i=0;i<3;++i){if(b[i]->reserved||b[i]->kind>R4OS_LAUNCH_IO_PIPE)return R4OS_LAUNCH_IO_ERROR_INVALID;any|=b[i]->kind;}
 if(any){rc=R4SdkBytePipeProvider2(context,&value.pipes);if(rc)return rc;}
 *out=value;return 0;
}
static inline R4LaunchIoBinding *R4SdkStdioBinding(R4SdkStdio *io,uint32_t stream){
 if(!io)return NULL;
 return stream==0?&io->snapshot.stdin_binding:stream==1?&io->snapshot.stdout_binding:stream==2?&io->snapshot.stderr_binding:NULL;
}
static inline int32_t R4SdkStdioConsolePoll(const R4WaitSetDeadline *limit){
 if(!limit||limit->version!=1||limit->size!=sizeof(*limit)||limit->reserved0)return R4OS_BYTE_PIPE_ERROR_INVALID;
 if(limit->kind!=0)return R4OS_BYTE_PIPE_ERROR_UNSUPPORTED;
 return limit->absolute_ns||limit->last_ns||limit->clock_source||limit->clock_generation||limit->event_backend||limit->tick_hz?R4OS_BYTE_PIPE_ERROR_INVALID:0;
}
static inline int32_t R4SdkStdioRead(R4SdkStdio *io,uint8_t *data,uint64_t length,const R4WaitSetDeadline *limit,R4BytePipeProgress *out){
 R4LaunchIoBinding *b=R4SdkStdioBinding(io,0);if(!b||!data||!length||!limit||!out)return R4OS_BYTE_PIPE_ERROR_INVALID;
 if(b->kind==R4OS_LAUNCH_IO_PIPE)return io->pipes.read(b->end,data,length,limit,out);
 int32_t rc=R4SdkStdioConsolePoll(limit);if(rc)return rc;
 uint64_t address=0;rc=R4OS2ContextFunction(io->context,2,offsetof(R4XStartR4Desk2,console_read),&address);if(rc)return rc;
 uint32_t count=(uint32_t)(length<4096?length:4096);uint8_t staged[4096];rc=((R4DeskConsoleReadFn)(uintptr_t)address)(staged,count);
 if(rc<0)return rc;if((uint32_t)rc>count)return R4OS_BYTE_PIPE_ERROR_INVALID;
 for(uint32_t i=0;i<(uint32_t)rc;++i)data[i]=staged[i];
 *out=(R4BytePipeProgress){.version=1,.size=sizeof(*out),.bytes=(uint32_t)rc,.state=rc?R4OS_BYTE_PIPE_READY:R4OS_BYTE_PIPE_WOULD_BLOCK};return 0;
}
static inline int32_t R4SdkStdioWrite(R4SdkStdio *io,uint32_t stream,const uint8_t *data,uint64_t length,const R4WaitSetDeadline *limit,R4BytePipeProgress *out){
 R4LaunchIoBinding *b=R4SdkStdioBinding(io,stream);if(!b||stream==0||!data||!length||!limit||!out)return R4OS_BYTE_PIPE_ERROR_INVALID;
 if(b->kind==R4OS_LAUNCH_IO_PIPE)return io->pipes.write(b->end,data,length,limit,out);
 int32_t rc=R4SdkStdioConsolePoll(limit);if(rc)return rc;
 uint64_t address=0;rc=R4OS2ContextFunction(io->context,2,offsetof(R4XStartR4Desk2,console_write),&address);if(rc)return rc;
 uint32_t count=(uint32_t)(length<4096?length:4096);rc=((R4DeskConsoleWriteFn)(uintptr_t)address)(stream,data,count);
 if(rc<0)return rc;if((uint32_t)rc>count)return R4OS_BYTE_PIPE_ERROR_INVALID;
 *out=(R4BytePipeProgress){.version=1,.size=sizeof(*out),.bytes=(uint32_t)rc,.state=rc?R4OS_BYTE_PIPE_READY:R4OS_BYTE_PIPE_WOULD_BLOCK};return 0;
}
static inline int32_t R4SdkStdioCancel(R4SdkStdio *io,uint32_t stream){
 R4LaunchIoBinding *b=R4SdkStdioBinding(io,stream);if(!b)return R4OS_BYTE_PIPE_ERROR_INVALID;
 return b->kind==R4OS_LAUNCH_IO_PIPE?io->pipes.cancel(b->end):R4OS_BYTE_PIPE_ERROR_UNSUPPORTED;
}
static inline int32_t R4SdkStdioClose(R4SdkStdio *io,uint32_t stream){
 R4LaunchIoBinding *b=R4SdkStdioBinding(io,stream);if(!b)return R4OS_BYTE_PIPE_ERROR_INVALID;
 if(b->kind!=R4OS_LAUNCH_IO_PIPE)return R4OS_BYTE_PIPE_ERROR_UNSUPPORTED;
 if(!b->end.handle)return 0;int32_t rc=io->pipes.close(b->end);if(!rc)b->end=(R4BytePipeEnd){0};return rc;
}
_Static_assert(sizeof(R4LaunchIoBinding)==32,"launch binding");
_Static_assert(sizeof(R4LaunchIo)==112,"launch IO");
#endif
