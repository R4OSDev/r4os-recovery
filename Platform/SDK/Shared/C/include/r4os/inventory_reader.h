#ifndef R4OS_INVENTORY_READER_H
#define R4OS_INVENTORY_READER_H
#include "stream_transfer.h"
/* Caller-private whole-view storage. Initialized state and every output are
 * disjoint mapped ranges. Do not mutate the state fields directly. No retain,
 * lifecycle wait, physical retirement receipt, allocation or implicit retry. */
enum { R4_INV_READER_FULL=0,R4_INV_READER_LIFECYCLE=1 };
enum { R4_INV_READER_INITIAL=0,R4_INV_READER_MORE=1,R4_INV_READER_COMPLETE=2,
       R4_INV_READER_WOULD_BLOCK=3,R4_INV_READER_RESTART=4,R4_INV_READER_FAILED=5,
       R4_INV_READER_NO_PROVIDER=6,R4_INV_READER_CAPACITY=7,R4_INV_READER_CANCELLED=8,
       R4_INV_READER_TIMEOUT=9,R4_INV_READER_CLOCK_FAILED=10,R4_INV_READER_INVALID_PROVIDER=11 };
enum { R4_INV_READER_UNKNOWN=0,R4_INV_READER_FOUND=1,R4_INV_READER_MISSING=2 };
enum { R4_INV_READER_VIEW_COMPLETE=1,R4_INV_READER_TERMINAL=2,
       R4_INV_READER_IN_CALL=4,R4_INV_READER_TOTAL_KNOWN=8 };
typedef R4SdkTransferClockFn R4SdkInventoryClockFn;
typedef struct R4SdkInventoryProvider {
    R4SysProgramInventoryBeginFn full_begin;
    R4SysProgramInventoryProgramsFn full_page;
    R4SysProgramLifecycleBeginFn lifecycle_begin;
    R4SysProgramLifecycleProgramsFn lifecycle_page;
} R4SdkInventoryProvider;
typedef struct R4SdkInventoryProgress {
    uint64_t snapshot_generation;
    uint32_t staged_count,total,status;
    int32_t error_code;
    uint32_t flags,restarts;
} R4SdkInventoryProgress;
typedef struct R4SdkInventoryMatch {
    uint64_t snapshot_generation;
    uint32_t index,disposition,status;
    int32_t error_code;
} R4SdkInventoryMatch;
typedef struct R4SdkInventoryReader {
    R4SdkDeadlineBudget deadline;
    R4ProgramInventoryCursor cursor;
    R4ProgramInventorySummary summary;
    R4SdkInventoryProvider provider;
    R4SdkWireSpan storage;
    uint64_t last_generation;
    uint32_t mode,phase,status;
    int32_t error_code;
    uint32_t capacity,page_limit,count,total,total_known,busy,stop_requested,poll_used,restarts;
} R4SdkInventoryReader;
int32_t R4SdkInventoryInit(uint32_t,R4SdkWireSpan,uint32_t,uint32_t,R4SdkInventoryProvider,R4SdkClockSample,R4Timeout,R4SdkInventoryReader *);
int32_t R4SdkInventoryInitAbsolute(uint32_t,R4SdkWireSpan,uint32_t,uint32_t,R4SdkInventoryProvider,R4SdkDeadlineBudget,R4SdkInventoryReader *);
int32_t R4SdkInventoryGetProgress(const R4SdkInventoryReader *,R4SdkInventoryProgress *);
int32_t R4SdkInventoryCancel(R4SdkInventoryReader *,R4SdkInventoryProgress *);
int32_t R4SdkInventoryRestart(R4SdkInventoryReader *,R4SdkInventoryProgress *);
int32_t R4SdkInventoryStep(R4SdkInventoryReader *,uint32_t,R4SdkInventoryClockFn,void *,R4SdkInventoryProgress *);
int32_t R4SdkInventoryGetView(const R4SdkInventoryReader *,R4SdkWireSpan *);
int32_t R4SdkInventoryFindExact(const R4SdkInventoryReader *,R4ProgramProcessHandle,R4SdkInventoryMatch *);
int32_t R4SdkInventoryGetSummary(const R4SdkInventoryReader *,R4ProgramInventorySummary *);
/* Init does not call a provider. Each Step admits at most one original Begin
 * or Page callback, never sleeps/retries. Full invokes only full callbacks;
 * Lifecycle invokes only lightweight callbacks, never full diagnostics.
 * Storage capacity is in typed records; the span length is bytes. Page limit
 * is1..the canonical page maximum. Even zero capacity can prove empty.
 * WouldBlock preserves cursor and all private staged rows. Restart discards
 * them all, requires explicit Restart, and keeps the same outer deadline.
 * Time/clock/stop/provider/capacity/invalid-generation failures never publish
 * a view or Missing. A reentrant Cancel only requests stop until real return.
 * Poll admits one whole-operation callback; compound traversal normally needs
 * Finite/Forever. A successful poll Begin alone is terminal WouldBlock, Unknown.
 * GetView/GetSummary succeed only after validated Complete. A view is borrowed
 * until next mutation; count alone never makes it complete. FindExact uses
 * nonzero id AND generation; incomplete/failure/invalid identity is Unknown.
 * Snapshot membership is not a process retain or an atomic all-state snapshot.
 * Caller keeps true ProcessHandle/Observation/retirement owners separate. */
_Static_assert(sizeof(R4SdkInventoryProvider)==32u,"inventory provider");
_Static_assert(sizeof(R4SdkInventoryProgress)==32u,"inventory progress");
_Static_assert(sizeof(R4SdkInventoryMatch)==24u,"inventory match");
_Static_assert(sizeof(R4SdkInventoryReader)==392u,"inventory reader");
_Static_assert(offsetof(R4SdkInventoryReader,provider)==280u,"inventory provider offset");
_Static_assert(offsetof(R4SdkInventoryReader,mode)==336u,"inventory mode offset");
_Static_assert(offsetof(R4SdkInventoryReader,restarts)==384u,"inventory restarts offset");
#endif
