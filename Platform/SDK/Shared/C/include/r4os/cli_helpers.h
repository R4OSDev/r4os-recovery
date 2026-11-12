#ifndef R4OS_CLI_HELPERS_H
#define R4OS_CLI_HELPERS_H
#include "abi.h"
#include "poll_budget.h"

/* Shared static SDK implementation. Input/storage/metadata stay separate,
 * mapped and caller-owned. No extra R4L, parser in the kernel or logging
 * service. Argument offsets refer to immutable original UTF8 bytes. */
enum { R4_ARG_NO_QUOTES=0, R4_ARG_FULL_TOKEN_QUOTES=1, R4_ARG_SLASH=1, R4_ARG_DASH=2 };
enum { R4_ARG_POLICY=-1, R4_ARG_TOO_LONG=-2, R4_ARG_ENCODING=-3,
       R4_ARG_TEXT=-4, R4_ARG_UNCLOSED_QUOTE=-5, R4_ARG_INVALID_QUOTE=-6,
       R4_ARG_STATE=-7, R4_ARG_LENGTH_OVERFLOW=-8 };
typedef struct R4SdkArgPolicy { uint32_t quotes,switches; uintptr_t max_bytes; } R4SdkArgPolicy;
typedef struct R4SdkArgFailure { int32_t code; uint32_t reserved; uintptr_t offset; } R4SdkArgFailure;
typedef struct R4SdkArgToken {
    uintptr_t raw_start,raw_end,value_start,value_end;
    uint32_t flags,switch_prefix;
} R4SdkArgToken;
typedef struct R4SdkArgCursor {
    uintptr_t address,length,position;
    R4SdkArgPolicy policy;
    uint32_t state;
    int32_t error_code;
    uintptr_t error_offset;
} R4SdkArgCursor;
typedef struct R4SdkArgSwitch {
    uintptr_t name_start,name_length,value_start,value_length;
    uint32_t is_switch,has_value;
} R4SdkArgSwitch;
int32_t R4SdkArgInit(const uint8_t *,uintptr_t,R4SdkArgPolicy,R4SdkArgCursor *,R4SdkArgFailure *);
/* Next returns0 token,1 end,negative error. Errors/end are sticky. On error
 * token output and cursor position stay unchanged; error state is published.
 * UTF8 errors identify the malformed sequence's start, quote errors the
 * opening/offending byte. No backslash escape or host argv concatenation. */
int32_t R4SdkArgNext(R4SdkArgCursor *,R4SdkArgToken *,R4SdkArgFailure *);
/* trim0 retains the exact suffix; trim1 removes leading space/tab only.
 * Empty spans and empty quoted operands are distinct from end. */
int32_t R4SdkArgRemaining(const R4SdkArgCursor *,uint32_t trim,uintptr_t *start,uintptr_t *length);
int32_t R4SdkArgSwitchParts(const uint8_t *,uintptr_t,R4SdkArgToken,R4SdkArgSwitch *);

enum { R4_DIAG_ACCEPTED=0, R4_DIAG_FULL=1, R4_DIAG_RECORD_TOO_LARGE=2 };
enum { R4_DIAG_SINK_ACCEPTED=0, R4_DIAG_SINK_WOULD_BLOCK=1,
       R4_DIAG_SINK_FAILED=2, R4_DIAG_SINK_UNCERTAIN=3 };
enum { R4_DIAG_EMPTY=0, R4_DIAG_PROGRESS=1, R4_DIAG_WOULD_BLOCK=2,
       R4_DIAG_FAILED=3, R4_DIAG_UNCERTAIN=4, R4_DIAG_POISONED=5, R4_DIAG_INVALID_SINK=6 };
enum { R4_DIAG_BUFFER=-1, R4_DIAG_STATE=-2, R4_DIAG_BUSY=-3,
       R4_DIAG_TEXT=-4, R4_DIAG_SEVERITY=-5, R4_DIAG_ALIASING=-6,
       R4_DIAG_BUDGET=-7, R4_DIAG_LENGTH_OVERFLOW=-8 };
typedef struct R4SdkDiagnosticAppend { uint32_t kind,accepted_records; uint64_t required_bytes; } R4SdkDiagnosticAppend;
typedef struct R4SdkDiagnosticAck { uint32_t accepted_bytes,kind; int32_t error_code; uint32_t reserved; } R4SdkDiagnosticAck;
typedef struct R4SdkDiagnosticChunk { const uint8_t *data; uint32_t length,total,offset,severity; } R4SdkDiagnosticChunk;
typedef R4SdkDiagnosticAck (*R4SdkDiagnosticSink)(void *,const R4SdkDiagnosticChunk *);
typedef struct R4SdkDiagnosticFlush { uint32_t kind,accepted_bytes,completed_records; int32_t error_code; } R4SdkDiagnosticFlush;
typedef struct R4SdkDiagnosticDiscard { uint64_t records,pending_bytes; uint32_t known_first_prefix,uncertain; } R4SdkDiagnosticDiscard;
typedef struct R4SdkDiagnosticStats {
    uint64_t queued_records,pending_bytes,appended_records,rejected_records,rejected_input_bytes,sent_records,sent_bytes;
    uint32_t counters_saturated,poison;
} R4SdkDiagnosticStats;
typedef struct R4SdkDiagnosticBuffer {
    uintptr_t address,capacity,head,tail;
    uint32_t offset,busy,poison,counters_saturated;
    uint64_t queued_records,pending_bytes,appended_records,rejected_records,rejected_input_bytes,sent_records,sent_bytes;
} R4SdkDiagnosticBuffer;
int32_t R4SdkDiagnosticInit(uint8_t *,uintptr_t,R4SdkDiagnosticBuffer *);
int32_t R4SdkDiagnosticAppendRecord(R4SdkDiagnosticBuffer *,const uint8_t *,uintptr_t,uint32_t severity,R4SdkDiagnosticAppend *);
int32_t R4SdkDiagnosticFlushOnce(R4SdkDiagnosticBuffer *,uint32_t max_bytes,R4SdkDiagnosticSink,void *,R4SdkDiagnosticFlush *);
int32_t R4SdkDiagnosticReadStats(const R4SdkDiagnosticBuffer *,R4SdkDiagnosticStats *);
int32_t R4SdkDiagnosticDiscardAll(R4SdkDiagnosticBuffer *,R4SdkDiagnosticDiscard *);
typedef struct R4SdkDiagnosticConsole { R4DeskConsoleWriteFn write; uint32_t stream,reserved; } R4SdkDiagnosticConsole;
typedef struct R4SdkDiagnosticFile { R4SysFileAppendFn append; const uint8_t *path; } R4SdkDiagnosticFile;
typedef struct R4SdkDiagnosticLog {
    R4SysServiceOpenFn open;
    R4SysServiceCallFn call;
    R4SysServiceCloseFn close;
    const uint8_t *origin;
    uintptr_t origin_length;
    R4SdkBudgetValue call_ticks;
    uint32_t active_handle;
    int32_t last_close_error;
    uint32_t busy,reserved;
} R4SdkDiagnosticLog;
R4SdkDiagnosticAck R4SdkDiagnosticConsoleSend(void *,const R4SdkDiagnosticChunk *);
R4SdkDiagnosticAck R4SdkDiagnosticFileSend(void *,const R4SdkDiagnosticChunk *);
R4SdkDiagnosticAck R4SdkDiagnosticLogSend(void *,const R4SdkDiagnosticChunk *);
int32_t R4SdkDiagnosticLogClose(R4SdkDiagnosticLog *);
/* Resolve canonical callbacks from the actual selected generation; do not
 * manufacture old tables. cli_platform2.h supplies Query2 factories. The log
 * adapter requires a whole record <=159 bytes, nonempty origin <=31 bytes,
 * strict UTF8 without embedded NUL and tagged poll/finite logical ticks <MAX.
 * It keeps a failed close's handle until explicit LogClose succeeds. Never
 * destroy a log config with active_handle!=0. Unknown commit poisons the queue.
 * Confirmed acceptance is transport/LogService receipt, not durable storage. */
_Static_assert(sizeof(R4SdkDiagnosticConsole)==16u,"console sink");
_Static_assert(sizeof(R4SdkDiagnosticFile)==16u,"file sink");
_Static_assert(sizeof(R4SdkDiagnosticLog)==72u,"log sink");
/* Append admits whole UTF8 records or reports full/oversized input requests;
 * invalid text/alias errors do not change rejection counters. Text and state
 * must not overlap storage. Counters saturate with an explicit sticky flag.
 * Flush calls one synchronous sink, borrowing bytes only until real return.
 * Each accepted byte prefix is consumed exactly, even mid-UTF8 or on known
 * failure. Empty records require actual callback acceptance. Unknown/invalid
 * acknowledgement poisons further flushes; discard is explicit local loss,
 * not a peer cancellation, persistence or hardware stop receipt. */
_Static_assert(sizeof(R4SdkArgPolicy)==16u,"argument policy");
_Static_assert(sizeof(R4SdkArgFailure)==16u,"argument failure");
_Static_assert(sizeof(R4SdkArgToken)==40u,"argument token");
_Static_assert(sizeof(R4SdkArgCursor)==56u,"argument cursor");
_Static_assert(sizeof(R4SdkArgSwitch)==40u,"argument switch view");
_Static_assert(sizeof(R4SdkDiagnosticBuffer)==104u,"diagnostic buffer");
_Static_assert(sizeof(R4SdkDiagnosticStats)==64u,"diagnostic stats");
_Static_assert(sizeof(R4SdkDiagnosticAppend)==16u,"diagnostic append");
_Static_assert(sizeof(R4SdkDiagnosticAck)==16u,"diagnostic ack");
_Static_assert(sizeof(R4SdkDiagnosticChunk)==24u,"diagnostic chunk");
_Static_assert(sizeof(R4SdkDiagnosticFlush)==16u,"diagnostic flush");
_Static_assert(sizeof(R4SdkDiagnosticDiscard)==24u,"diagnostic discard");
#endif
