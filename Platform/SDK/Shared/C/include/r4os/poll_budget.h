#ifndef R4OS_POLL_BUDGET_H
#define R4OS_POLL_BUDGET_H
#include "abi.h"
#include <r4os/generation2.h>

/* SDK-local values, no kernel resources. Old timeout helpers retain their
 * saturating/sentinel contract. These new calls return explicit errors and
 * tagged poll/finite/forever values, preserving even finite UINT64_MAX. */
enum { R4_BUDGET_POLL=0, R4_BUDGET_FINITE=1, R4_BUDGET_FOREVER=2 };
enum { R4_BUDGET_UNKNOWN_FREQUENCY=-1, R4_BUDGET_INVALID_TIMEOUT=-2,
       R4_BUDGET_OVERFLOW=-3, R4_BUDGET_CLOCK_UNAVAILABLE=-4,
       R4_BUDGET_CLOCK_CHANGED=-5, R4_BUDGET_CLOCK_REGRESSED=-6,
       R4_BUDGET_INVALID=-7 };
enum { R4_POLL_TASK=0, R4_POLL_NO_SLEEP=1, R4_POLL_IRQ=2 };
enum { R4_POLL_PROCEED=0, R4_POLL_EXPIRED=1, R4_POLL_STOP=2,
       R4_POLL_CLOCK_UNAVAILABLE=3, R4_POLL_CLOCK_CHANGED=4,
       R4_POLL_CLOCK_REGRESSED=5, R4_POLL_INVALID=6 };
typedef struct R4SdkBudgetValue { uint32_t kind, reserved; uint64_t value; } R4SdkBudgetValue;
typedef struct R4SdkClockIdentity { uint32_t source, generation, event_backend, tick_hz; } R4SdkClockIdentity;
typedef struct R4SdkClockSample { R4SdkClockIdentity identity; uint64_t instant_ns; } R4SdkClockSample;
typedef struct R4SdkDeadlineBudget {
    R4SdkClockIdentity identity;
    uint64_t deadline_ns, last_ns;
    uint32_t kind, reserved;
} R4SdkDeadlineBudget;
typedef struct R4SdkDriverPollBudget {
    uint32_t context, kind;
    uint64_t iterations;
    R4SdkDeadlineBudget deadline;
    uint32_t outcome, reserved;
} R4SdkDriverPollBudget;
typedef struct R4SdkPollRemaining {
    uint32_t kind, outcome;
    uint64_t iterations;
    R4SdkBudgetValue time;
} R4SdkPollRemaining;

int32_t R4SdkClockSampleRead(const R4MonotonicClockInfo *, R4SdkClockSample *);
/* One logical RPC/stream operation; expiry never cancels or replays a mutation. */
typedef struct R4SdkRpcBudget {
    R4SysMonotonicClockFn clock;
    R4SdkDeadlineBudget deadline;
    uint64_t tick_deadline;
    uint32_t has_tick_deadline, reserved;
} R4SdkRpcBudget;
int32_t R4SdkRpcBudgetInit(R4SysMonotonicClockFn, const R4Timeout *, R4SdkRpcBudget *);
int32_t R4SdkRpcBudgetRemaining(R4SdkRpcBudget *, uint64_t *);
_Static_assert(sizeof(R4SdkRpcBudget)==64u, "RPC budget");
int32_t R4SdkMillisecondsToTicksChecked(uint64_t, uint32_t, uint64_t *);
int32_t R4SdkTimeoutTicksChecked(R4Timeout, uint32_t, R4SdkBudgetValue *);
/* Only Forever maps to the old sentinel; finite MAX fails unchanged. */
int32_t R4SdkBudgetToWaitTicks(const R4SdkBudgetValue *, uint64_t *);
int32_t R4SdkDeadlineBudgetInit(R4SdkClockSample, R4Timeout, R4SdkDeadlineBudget *);
int32_t R4SdkDeadlineBudgetRemaining(R4SdkDeadlineBudget *, R4SdkClockSample, R4SdkBudgetValue *);
int32_t R4SdkDriverPollIterations(uint64_t, uint32_t, R4SdkDriverPollBudget *);
int32_t R4SdkDriverPollTimed(R4SdkClockSample, R4Timeout, uint64_t, uint32_t, R4SdkDriverPollBudget *);
/* now may be NULL only for an iteration budget. A proceed consumes exactly
 * one retry; terminal outcomes stay terminal. Never accesses registers,
 * sleeps, yields, allocates or acknowledges any device/callback/DMA stop. */
uint32_t R4SdkDriverPollStep(R4SdkDriverPollBudget *, const R4SdkClockSample *now, uint32_t stop_requested);
int32_t R4SdkDriverPollRemaining(R4SdkDriverPollBudget *, const R4SdkClockSample *now, R4SdkPollRemaining *);

static inline int32_t r4_checked_driver_clock(const R4DriverApi2 *api, R4SdkClockSample *out) {
    if (!api || api->magic != R4OS_DRIVER_API2_MAGIC || api->version < 1u || api->reserved != 0 || api->size < offsetof(R4DriverApi2,monotonic_clock)+sizeof(api->monotonic_clock) || !api->monotonic_clock) return R4_BUDGET_CLOCK_UNAVAILABLE;
    R4MonotonicClockInfo info = {0};
    if (api->monotonic_clock(&info) <= 0) return R4_BUDGET_CLOCK_UNAVAILABLE;
    return R4SdkClockSampleRead(&info,out);
}
_Static_assert(sizeof(R4SdkBudgetValue)==16u, "tagged budget");
_Static_assert(sizeof(R4SdkClockSample)==24u, "clock sample");
_Static_assert(sizeof(R4SdkDeadlineBudget)==40u, "clock-bound deadline");
_Static_assert(sizeof(R4SdkDriverPollBudget)==64u, "driver poll budget");
_Static_assert(sizeof(R4SdkPollRemaining)==32u, "explicit poll remainder");
#endif
