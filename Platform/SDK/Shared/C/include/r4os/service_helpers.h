#ifndef R4OS_SERVICE_HELPERS_H
#define R4OS_SERVICE_HELPERS_H
#include "app_services.h"
#include "poll_budget.h"

/* SDK-local, pointer-free loop state. The original Zig loop owns scheduling,
 * bounded drain and counters. No pointer to a temporary App/Bundle is kept. */
typedef struct R4SdkServiceLoopMetrics {
    uint64_t wait_calls, request_wakes, deadline_wakes, idle_wakes, stop_wakes;
    uint64_t wait_failures, announced_requests, batches, drain_polls;
    uint64_t empty_drain_polls, drained_requests, limited_batches, fairness_yields;
    uint32_t max_batch;
} R4SdkServiceLoopMetrics;
typedef struct R4SdkServiceLoop {
    uint32_t endpoint_handle;
    uint64_t started_tick, stop_check_ticks;
    uint32_t drain_limit;
    R4SdkServiceLoopMetrics metrics;
    R4SdkDeadlineBudget clock_guard;
    uint32_t clock_bound;
    int32_t init_error;
} R4SdkServiceLoop;
typedef struct R4SdkServiceBatch { uint32_t announced, processed, done; } R4SdkServiceBatch;
typedef struct R4SdkServiceStep { uint32_t kind; int32_t value; } R4SdkServiceStep;
typedef struct R4SdkDeadlineView { uintptr_t length; uint64_t deadline_tick; uint32_t has_deadline; } R4SdkDeadlineView;
typedef int32_t (*R4SdkServiceHandler)(void *);
/* Wait kind: requests=0, deadline=1, idle=2, stop=3, failure=4.
 * Batch kind: request=0, complete=1, yielded=2, failure=3.
 * Endpoint must outlive the loop. No overlapping loop calls; callbacks must
 * not reenter this loop or unwind across the C boundary. */
int32_t R4SdkServiceLoopInit(const R4XStartContext *, uint32_t, uint64_t, uint32_t, R4SdkServiceLoop *);
int32_t R4SdkServiceLoopInit2(const R4OS2Context *, uint32_t, uint64_t, uint32_t, R4SdkServiceLoop *);
R4SdkServiceStep R4SdkServiceLoopWait(const R4XStartContext *, R4SdkServiceLoop *, uint32_t, uint64_t);
R4SdkServiceStep R4SdkServiceLoopWait2(const R4OS2Context *, R4SdkServiceLoop *, uint32_t, uint64_t);
int32_t R4SdkServiceLoopBatch(const R4XStartContext *, R4SdkServiceLoop *, uint32_t, R4SdkServiceBatch *);
int32_t R4SdkServiceLoopBatch2(const R4OS2Context *, R4SdkServiceLoop *, uint32_t, R4SdkServiceBatch *);
R4SdkServiceStep R4SdkServiceBatchNext(const R4XStartContext *, R4SdkServiceLoop *, R4SdkServiceBatch *);
R4SdkServiceStep R4SdkServiceBatchNext2(const R4OS2Context *, R4SdkServiceLoop *, R4SdkServiceBatch *);
int32_t R4SdkServiceLoopDrain(const R4XStartContext *, R4SdkServiceLoop *, uint32_t, R4SdkServiceHandler, void *);
int32_t R4SdkServiceLoopDrain2(const R4OS2Context *, R4SdkServiceLoop *, uint32_t, R4SdkServiceHandler, void *);
int32_t R4SdkServiceLoopReport(const R4XStartContext *, const R4SdkServiceLoop *, const uint8_t *, uint32_t, uint8_t *, uint32_t);
int32_t R4SdkServiceLoopReport2(const R4OS2Context *, const R4SdkServiceLoop *, const uint8_t *, uint32_t, uint8_t *, uint32_t);
int32_t R4SdkServiceDetails(const R4XStartContext *, R4ServiceDetail *, uint32_t);
/* control: status=0,start=1,stop=2,restart=3,install=4,remove=5,startmode=6.
 * path/args/description may be null outside install. Stop uses native ticks.
 * Raw status and output remain independent, including failure snapshots. */
int32_t R4SdkServiceControl(const R4XStartContext *, uint32_t, const uint8_t *, const uint8_t *, const uint8_t *, uint32_t, const uint8_t *, uint64_t, R4ServiceInfo *);
int32_t R4SdkServiceInfo(const R4XStartContext *, uint32_t, R4ServiceInfo *);
int32_t R4SdkServiceDetail(const R4XStartContext *, const uint8_t *, R4ServiceDetail *);
/* Same original owners over a borrowed actual SDK Context2 view. */
int32_t R4SdkServiceDetails2(const R4OS2Context *, R4ServiceDetail *, uint32_t);
int32_t R4SdkServiceControl2(const R4OS2Context *, uint32_t, const uint8_t *, const uint8_t *, const uint8_t *, uint32_t, const uint8_t *, uint64_t, R4ServiceInfo *);
int32_t R4SdkServiceInfo2(const R4OS2Context *, uint32_t, R4ServiceInfo *);
int32_t R4SdkServiceDetail2(const R4OS2Context *, const uint8_t *, R4ServiceDetail *);
int32_t R4SdkCompletedReply(int32_t);
int32_t R4SdkDeadlineAppend(uint8_t *, uint32_t, const uint8_t *, uint32_t, uint64_t);
R4SdkDeadlineView R4SdkDeadlineSplit(const uint8_t *, uint32_t);
int32_t R4SdkDeadlineFromTimeout(R4Timeout, uint64_t, uint32_t, uint64_t *);
R4Timeout R4SdkDeadlineRemaining(uint64_t, uint64_t, uint32_t);
int32_t R4SdkDurationFromTicks(uint64_t, uint32_t, R4Duration *);
#endif
