#ifndef R4OS_PCM_SOURCE_H
#define R4OS_PCM_SOURCE_H
#include "poll_budget.h"
typedef struct R4SdkPcmSourceDeadline {
 R4SdkClockIdentity identity;
 uint64_t due_ns,source_end_ns,accepted_frames,wait_ns;
 uint32_t rate,frame_bytes,flags,reserved0;
} R4SdkPcmSourceDeadline;
typedef struct R4SdkPcmSourcePacer {
 R4SdkClockIdentity identity;
 uint64_t end_lo,end_hi,last_ns,accepted_frames,lead_frames;
 uint32_t rate,frame_bytes,flags,reserved0;
} R4SdkPcmSourcePacer;
enum {R4_PCM_SOURCE_HAS_END=1,R4_PCM_SOURCE_PAUSED=2,
 R4_PCM_SOURCE_RATE=-305,R4_PCM_SOURCE_FRAME=-303,R4_PCM_SOURCE_PAUSED_ERROR=-306};
int32_t R4SdkPcmSourceInit(uint32_t,uint32_t,uint64_t,R4SdkClockSample,R4SdkPcmSourcePacer *);
int32_t R4SdkPcmSourceAccepted(R4SdkPcmSourcePacer *,uint64_t,R4SdkClockSample,R4SdkPcmSourceDeadline *);
int32_t R4SdkPcmSourceGetDeadline(R4SdkPcmSourcePacer *,R4SdkClockSample,uint32_t,R4SdkPcmSourceDeadline *);
int32_t R4SdkPcmSourcePause(R4SdkPcmSourcePacer *,R4SdkClockSample,uint32_t);
/* Pure accepted-source estimate: no sleep, stream ownership or playback.
 * Keep whole frames and exact ns*rate fractions. No credit after long gaps.
 * Sample is the actual write start. Pause discards the old source end, keeps
 * diagnostic count; resume starts a fresh schedule. Init on idle state is
 * explicit reset (new rate/frame/clock/lead, zero count). Failed checks leave
 * state unchanged. Output and state must be separate. Clock identity/rate,
 * generation and monotonicity are checked; no clock-frequency fallback. */
_Static_assert(sizeof(R4SdkPcmSourceDeadline)==64u,"source deadline");
_Static_assert(sizeof(R4SdkPcmSourcePacer)==72u,"source pacer");
#endif
