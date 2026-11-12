#ifndef R4OS_STREAM_TRANSFER_H
#define R4OS_STREAM_TRANSFER_H
#include "poll_budget.h"
#include "wire_helpers.h"
/* One real synchronous owner call per step. This is not an asynchronous
 * buffer-loan owner. State, input/output, scratch and adapter metadata remain
 * separate, mapped, exclusively caller-owned through actual callback return. */
enum { R4_STREAM_XFER_READ_EXACT=0,R4_STREAM_XFER_WRITE_ALL=1 };
enum { R4_STREAM_XFER_PENDING=0,R4_STREAM_XFER_COMPLETE=1,R4_STREAM_XFER_WOULD_BLOCK=2,
       R4_STREAM_XFER_EOF=3,R4_STREAM_XFER_TIMEOUT=4,R4_STREAM_XFER_CANCELLED=5,
       R4_STREAM_XFER_FAILED=6,R4_STREAM_XFER_UNCERTAIN=7,R4_STREAM_XFER_CLOCK_FAILED=8,
       R4_STREAM_XFER_INVALID_PROGRESS=9,R4_STREAM_XFER_CLOSED=10 };
enum { R4_STREAM_XFER_GOAL_MET=1,R4_STREAM_XFER_TERMINAL=2,
       R4_STREAM_XFER_IN_CALL=4,R4_STREAM_XFER_EFFECT_UNCERTAIN=8 };
enum { R4_STREAM_XFER_IO_PROGRESS=0,R4_STREAM_XFER_IO_EOF=1,R4_STREAM_XFER_IO_WOULD_BLOCK=2,
       R4_STREAM_XFER_IO_TIMEOUT=3,R4_STREAM_XFER_IO_CLOSED=4,
       R4_STREAM_XFER_IO_FAILED=5,R4_STREAM_XFER_IO_UNCERTAIN=6 };
enum { R4_STREAM_XFER_STATE=-1,R4_STREAM_XFER_MODE=-2,R4_STREAM_XFER_BUFFER=-3,
       R4_STREAM_XFER_LIMIT=-4,R4_STREAM_XFER_BUSY=-5,R4_STREAM_XFER_RANGE=-6,
       R4_STREAM_XFER_CLOCK_UNAVAILABLE=-101,R4_STREAM_XFER_CLOCK_CHANGED=-102,
       R4_STREAM_XFER_CLOCK_REGRESSED=-103,R4_STREAM_XFER_BUDGET=-104,
       R4_STREAM_XFER_FREQUENCY=-105,R4_STREAM_XFER_BUDGET_OVERFLOW=-106,
       R4_STREAM_XFER_TIMEOUT_INVALID=-107,R4_STREAM_XFER_ADAPTER_INVALID=-11001,
       R4_STREAM_XFER_OFFSET_UNAVAILABLE=-11002,R4_STREAM_XFER_ADAPTER_CLOCK=-11003 };
typedef struct R4SdkTransferAck { uint32_t bytes,kind;int32_t error_code;uint32_t reserved; } R4SdkTransferAck;
typedef struct R4SdkTransferProgress { uint64_t bytes,total;uint32_t last_bytes,outcome;int32_t error_code;uint32_t flags; } R4SdkTransferProgress;
typedef struct R4SdkTransfer {
    uint64_t total,bytes;
    R4SdkDeadlineBudget deadline;
    uint32_t mode,outcome,ended,busy,cancel_requested,poll_used;
    int32_t last_error;
    uint32_t last_bytes;
} R4SdkTransfer;
typedef int32_t (*R4SdkTransferClockFn)(void *,R4SdkClockSample *);
typedef R4SdkTransferAck (*R4SdkTransferReadFn)(void *,uint64_t,uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
typedef R4SdkTransferAck (*R4SdkTransferWriteFn)(void *,uint64_t,const uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
int32_t R4SdkTransferInit(uint32_t,uint64_t,R4SdkClockSample,R4Timeout,R4SdkTransfer *);
int32_t R4SdkTransferInitAbsolute(uint32_t,uint64_t,R4SdkDeadlineBudget,R4SdkTransfer *);
int32_t R4SdkTransferGetProgress(const R4SdkTransfer *,R4SdkTransferProgress *);
int32_t R4SdkTransferCancel(R4SdkTransfer *,R4SdkTransferProgress *);
int32_t R4SdkTransferReadStep(R4SdkTransfer *,uint8_t *,uintptr_t,uint32_t,uint32_t,R4SdkTransferClockFn,void *,R4SdkTransferReadFn,void *,R4SdkTransferProgress *);
int32_t R4SdkTransferWriteStep(R4SdkTransfer *,const uint8_t *,uintptr_t,uint32_t,uint32_t,R4SdkTransferClockFn,void *,R4SdkTransferWriteFn,void *,R4SdkTransferProgress *);
/* One immutable outer deadline, possibly begun before discovery. Clock
 * epochs/regression/expiry are checked before and after the real callback.
 * Finite expiry prevents new steps and retains every confirmed byte. Poll
 * permits one immediate step only. Callback budgets are absolute copies,
 * never a new timeout per short operation. A reentrant Cancel requests stop
 * and reports IN_CALL; only actual return ends the local callback loan.
 * Unknown/invalid acknowledgements are terminal; never automatically replay.
 * Counters acknowledge an owner prefix, not peer ACK, file publish or DMAstop.
 * A blocking admitted owner may delay return beyond the deadline; expiry
 * cannot release an outstanding borrower. No hidden drain/retry/Wait loop. */
typedef struct R4SdkTransferPlatformClock { R4SysMonotonicClockFn read; } R4SdkTransferPlatformClock;
typedef struct R4SdkTransferFileRead { R4SysFileReadAtFn read;const uint8_t *path;uint64_t base_offset; } R4SdkTransferFileRead;
typedef struct R4SdkTransferFileAppend { R4SysFileAppendFn append;const uint8_t *path; } R4SdkTransferFileAppend;
typedef struct R4SdkTransferFileStream { R4SysFileStreamWriteFn write;const uint8_t *path;uint64_t base_offset; } R4SdkTransferFileStream;
typedef struct R4SdkTransferTcp { R4SysServiceCallFn call;R4SysMonotonicClockFn monotonic;R4SysTicksFn ticks;uint32_t service_handle,socket_handle; } R4SdkTransferTcp;
typedef R4SdkTransferAck (*R4SdkTransferServiceDecode)(void *,uint64_t,const uint8_t *,uint32_t,const R4ServiceMessageHeader *,const uint8_t *,uint32_t);
typedef struct R4SdkTransferServiceSink {
    R4SysServiceCallFn call;R4SysMonotonicClockFn monotonic;
    R4SdkTransferServiceDecode decode;void *decoder_context;
    uint32_t service_handle;uint16_t op,reserved;
} R4SdkTransferServiceSink;
typedef struct R4SdkTransferServiceReply {
    R4SysServiceCallFn call;R4SysMonotonicClockFn monotonic;
    uint32_t service_handle;uint16_t op,reserved;
    R4SdkWireSpan request,scratch;uintptr_t position,length;uint32_t loaded,flags;
} R4SdkTransferServiceReply;
int32_t R4SdkTransferReadClock(void *,R4SdkClockSample *);
R4SdkTransferAck R4SdkTransferReadFile(void *,uint64_t,uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
R4SdkTransferAck R4SdkTransferAppendFile(void *,uint64_t,const uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
R4SdkTransferAck R4SdkTransferFileStreamWrite(void *,uint64_t,const uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
R4SdkTransferAck R4SdkTransferTcpRead(void *,uint64_t,uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
R4SdkTransferAck R4SdkTransferTcpWrite(void *,uint64_t,const uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
R4SdkTransferAck R4SdkTransferServiceWrite(void *,uint64_t,const uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
R4SdkTransferAck R4SdkTransferServiceRead(void *,uint64_t,uint8_t *,uint32_t,const R4SdkDeadlineBudget *);
/* Adapters borrow actual paths/handles; no resource creation or close. The
 * synchronous FileReadAt owner has a32-bit offset and explicitly rejects
 * larger absolute offsets. Existing wide asynchronous IO retains its own
 * request/loan contract. FileStreamWrite keeps its real u64 offset.
 * TCP uses original TCPSVC wire records/footer and the existing readiness
 * owner. A valid handle0/bytes0 admission timeout confirms zero; a missing
 * reply is uncertain. Peer-close does not discard buffered received data.
 * ServiceSink requires its operation's explicit prefix decoder: reply length
 * is not acknowledged request bytes. ServiceReply issues at most one RPC
 * and drains its bounded reply scratch; it never invents a byte-stream RPC.
 * The caller retains endpoint/socket owners and performs their real close. */
_Static_assert(sizeof(R4SdkTransferAck)==16u,"transfer ack");
_Static_assert(sizeof(R4SdkTransferProgress)==32u,"transfer progress");
_Static_assert(sizeof(R4SdkTransfer)==88u,"transfer state");
_Static_assert(sizeof(R4SdkTransferPlatformClock)==8u,"transfer clock");
_Static_assert(sizeof(R4SdkTransferFileRead)==24u,"transfer file read");
_Static_assert(sizeof(R4SdkTransferFileAppend)==16u,"transfer append");
_Static_assert(sizeof(R4SdkTransferFileStream)==24u,"transfer file stream");
_Static_assert(sizeof(R4SdkTransferTcp)==32u,"transfer tcp");
_Static_assert(sizeof(R4SdkTransferServiceSink)==40u,"transfer service sink");
_Static_assert(sizeof(R4SdkTransferServiceReply)==80u,"transfer service source");
#endif
