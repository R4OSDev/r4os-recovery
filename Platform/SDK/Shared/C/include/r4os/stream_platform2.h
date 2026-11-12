#ifndef R4OS_STREAM_PLATFORM2_H
#define R4OS_STREAM_PLATFORM2_H
#include "stream_transfer.h"
#include "platform2.h"
/* Borrow actual paths, endpoint/socket handles and their owners. Failed
 * lookup preserves output. No old context/table is manufactured. */
static inline int32_t R4SdkTransferClock2(const R4OS2Context *ctx,R4SdkTransferPlatformClock *out){
    uint64_t fn=0;if(!out)return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,monotonic_clock),&fn);if(rc)return rc;
    *out=(R4SdkTransferPlatformClock){.read=(R4SysMonotonicClockFn)(uintptr_t)fn};return 0;
}
static inline int32_t R4SdkTransferFileRead2(const R4OS2Context *ctx,const uint8_t *path,uint64_t base,R4SdkTransferFileRead *out){
    uint64_t fn=0;if(!out||!path)return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,file_read_at),&fn);if(rc)return rc;
    *out=(R4SdkTransferFileRead){.read=(R4SysFileReadAtFn)(uintptr_t)fn,.path=path,.base_offset=base};return 0;
}
static inline int32_t R4SdkTransferAppend2(const R4OS2Context *ctx,const uint8_t *path,R4SdkTransferFileAppend *out){
    uint64_t fn=0;if(!out||!path)return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,file_append),&fn);if(rc)return rc;
    *out=(R4SdkTransferFileAppend){.append=(R4SysFileAppendFn)(uintptr_t)fn,.path=path};return 0;
}
static inline int32_t R4SdkTransferFileStream2(const R4OS2Context *ctx,const uint8_t *path,uint64_t base,R4SdkTransferFileStream *out){
    uint64_t fn=0;if(!out||!path)return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,file_stream_write),&fn);if(rc)return rc;
    *out=(R4SdkTransferFileStream){.write=(R4SysFileStreamWriteFn)(uintptr_t)fn,.path=path,.base_offset=base};return 0;
}
static inline int32_t R4SdkTransferTcp2(const R4OS2Context *ctx,uint32_t service,uint32_t socket,R4SdkTransferTcp *out){
    uint64_t call=0,mono=0,ticks=0;if(!out||!service||!socket)return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_call),&call);if(rc)return rc;
    rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,monotonic_clock),&mono);if(rc)return rc;
    rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,ticks),&ticks);if(rc)return rc;
    *out=(R4SdkTransferTcp){.call=(R4SysServiceCallFn)(uintptr_t)call,.monotonic=(R4SysMonotonicClockFn)(uintptr_t)mono,.ticks=(R4SysTicksFn)(uintptr_t)ticks,.service_handle=service,.socket_handle=socket};return 0;
}
static inline int32_t R4SdkTransferServiceSink2(const R4OS2Context *ctx,uint32_t service,uint16_t op,R4SdkTransferServiceDecode decode,void *decoder_context,R4SdkTransferServiceSink *out){
    uint64_t call=0,mono=0;if(!out||!service||!decode)return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_call),&call);if(rc)return rc;
    rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,monotonic_clock),&mono);if(rc)return rc;
    *out=(R4SdkTransferServiceSink){.call=(R4SysServiceCallFn)(uintptr_t)call,.monotonic=(R4SysMonotonicClockFn)(uintptr_t)mono,.decode=decode,.decoder_context=decoder_context,.service_handle=service,.op=op};return 0;
}
static inline int32_t R4SdkTransferServiceReply2(const R4OS2Context *ctx,uint32_t service,uint16_t op,const uint8_t *request,uintptr_t request_len,uint8_t *scratch,uintptr_t capacity,R4SdkTransferServiceReply *out){
    uint64_t call=0,mono=0;if(!out||!service||(request_len&&!request)||(capacity&&!scratch))return R4_STREAM_XFER_ADAPTER_INVALID;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_call),&call);if(rc)return rc;
    rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,monotonic_clock),&mono);if(rc)return rc;
    *out=(R4SdkTransferServiceReply){.call=(R4SysServiceCallFn)(uintptr_t)call,.monotonic=(R4SysMonotonicClockFn)(uintptr_t)mono,.service_handle=service,.op=op,.request={(uintptr_t)request,request_len},.scratch={(uintptr_t)scratch,capacity}};return 0;
}
#endif
