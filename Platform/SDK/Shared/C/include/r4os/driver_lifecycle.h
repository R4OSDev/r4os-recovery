#ifndef R4OS_DRIVER_LIFECYCLE_H
#define R4OS_DRIVER_LIFECYCLE_H
#include "r4os/driver.h"
/* One record per actual device incarnation. Do not copy a live token or
 * substitute a slot/BDF for its generation-bearing provider identity. These
 * records have no automatic destructor; callbacks/backing stay resident even
 * when their owner loses a token. Zero only before acquisition or after ACK. */
typedef struct R4DriverDmaLease {
 const R4SdkDriverContext *owner;
 R4DmaPinnedBuffer pin;
 R4DmaMapping mapping;
} R4DriverDmaLease;
/* Caller proves this exact mapping's current device/ring/callback quiescence.
 * Neither timeout, cancellation, old reset nor this function proves it.
 * Any refusal retains both the mapping and pinned backing for retry. */
static inline int32_t r4driver_dma_close_quiesced(R4DriverDmaLease *lease) {
 if(!lease || !lease->owner) return -1;
 int32_t rc;
 if(lease->mapping.handle) {
  rc=r4driver_result(R4SdkDriverContext_unmapDma(0,lease->owner,&lease->mapping));
  if(rc) return rc;
 }
 if(lease->pin.handle) {
  rc=r4driver_result(R4SdkDriverContext_unpinDmaBuffer(0,lease->owner,&lease->pin));
  if(rc) return rc;
 }
 return 0;
}
typedef struct R4DriverWorkLease {const R4SdkDriverContext *owner;uint32_t ticket;} R4DriverWorkLease;
static inline int32_t r4driver_work_release_terminal(R4DriverWorkLease *lease) {
 if(!lease || !lease->owner) return -1;
 if(!lease->ticket) return 0;
 R4DriverCompletionStatus status={.version=1,.size=sizeof(status)};
 int32_t rc=r4driver_result(R4SdkDriverContext_completionStatus(0,lease->owner,lease->ticket,&status));
 if(rc) return rc;
 if(status.state!=R4OS_DRIVER_WORK_STATE_COMPLETED && status.state!=R4OS_DRIVER_WORK_STATE_CANCELLED) return R4OS_DRIVER_WORK_OWNER_BUSY;
 rc=r4driver_result(R4SdkDriverContext_completionRelease(0,lease->owner,lease->ticket));
 if(!rc) lease->ticket=0;
 return rc;
}
#endif
