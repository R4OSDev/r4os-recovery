#ifndef R4OS_PUBLISHED_FRAME_H
#define R4OS_PUBLISHED_FRAME_H
#include "subsystem_helpers.h"
#include "wire_helpers.h"
/* Opaque native storage, not initialized bytes: initialize through Init and
 * never inspect padding. No self pointers; movable between actual calls.
 * Whole scratch, callback descriptor/code/context stay borrowed until this
 * owner ends. Source and palette stay immutable/mapped until exact ticket
 * Release or completed Close. All state/input/output ranges are separate. */
typedef struct R4SdkPublishedFrameBridge { _Alignas(8) uint8_t opaque_bytes[864]; } R4SdkPublishedFrameBridge;
typedef struct R4SdkPublishedFrameRect { uint32_t x,y,w,h; } R4SdkPublishedFrameRect;
typedef struct R4SdkPublishedFrameLease {
 R4SdkWireSpan pixels,palette;
 uint64_t binding_generation,revision,palette_revision,damage_base_revision;
 uint32_t width,height,stride_bytes,format,damage_kind,flags,reserved0,reserved1;
 R4SdkPublishedFrameRect damage;
} R4SdkPublishedFrameLease;
typedef struct R4SdkPublishedFrameAcquisition {uint64_t ticket;uint32_t kind,reserved0;} R4SdkPublishedFrameAcquisition;
typedef struct R4SdkPublishedFrameViewport {
 int32_t x,y;uint32_t width,height,source_width,source_height,integer_scale,reserved0;
} R4SdkPublishedFrameViewport;
typedef struct R4SdkPublishedFramePresentation {
 uint32_t kind;int32_t error_code;uint32_t mode,flags;
 R4SdkPublishedFrameViewport viewport;
 uint32_t damage_regions,raster_blocks;uint64_t sampled_pixels;
} R4SdkPublishedFramePresentation;
typedef struct R4SdkPublishedFrameProgress {
 uint64_t binding_generation,revision,palette_revision,active_ticket,last_ticket;
 uint32_t width,height,stride_bytes,format,state,flags,last_sync_kind,reserved0;
} R4SdkPublishedFrameProgress;
enum {R4_PUBLISHED_COMPLETE=1,R4_PUBLISHED_INDEXED8=0,R4_PUBLISHED_XRGB32=1,
 R4_PUBLISHED_DAMAGE_FULL=0,R4_PUBLISHED_DAMAGE_RECT=1,R4_PUBLISHED_DAMAGE_NONE=2,
 R4_PUBLISHED_UNBOUND=0,R4_PUBLISHED_RUNNING=1,R4_PUBLISHED_PAUSED=2,R4_PUBLISHED_CLOSED=3,
 R4_PUBLISHED_ACTIVE_LOAN=1,R4_PUBLISHED_IN_CALL=2,R4_PUBLISHED_CLOSE_PENDING=4,R4_PUBLISHED_OBSERVED=8,
 R4_PUBLISHED_COPY_INDEXED8=1,R4_PUBLISHED_COPY_XRGB32_NEAREST=2};
enum {R4_PUBLISHED_INVALID=-401,R4_PUBLISHED_SURFACE=-402,R4_PUBLISHED_BUFFER=-403,
 R4_PUBLISHED_STALE_GENERATION=-404,R4_PUBLISHED_STALE_REVISION=-405,R4_PUBLISHED_STALE_DAMAGE=-406,
 R4_PUBLISHED_BUSY=-407,R4_PUBLISHED_ENDED=-408,R4_PUBLISHED_EXHAUSTED=-409,
 R4_PUBLISHED_NO_PROVIDER=-410,R4_PUBLISHED_UNSUPPORTED=-411,R4_PUBLISHED_NO_LEASE=-412,R4_PUBLISHED_SCRATCH=-413};
int32_t R4SdkPublishedFrameInit(const R4SdkSubsystemCallbackTable *,uint32_t *,uintptr_t,uint32_t,R4SdkPublishedFrameBridge *);
int32_t R4SdkPublishedFrameBind(R4SdkPublishedFrameBridge *,uint64_t);
int32_t R4SdkPublishedFrameSync(R4SdkPublishedFrameBridge *,R4SdkPublishedFrameLease,R4SdkPublishedFrameAcquisition *);
int32_t R4SdkPublishedFramePresent(R4SdkPublishedFrameBridge *,uint64_t,int32_t,int32_t,R4SdkPublishedFramePresentation *);
int32_t R4SdkPublishedFrameRelease(R4SdkPublishedFrameBridge *,uint64_t);
int32_t R4SdkPublishedFramePause(R4SdkPublishedFrameBridge *,uint32_t);
int32_t R4SdkPublishedFrameClose(R4SdkPublishedFrameBridge *);
int32_t R4SdkPublishedFrameGetProgress(const R4SdkPublishedFrameBridge *,R4SdkPublishedFrameProgress *);
/* Complete publications only; the producer proves provenance and never lends
 * working_frame. Init is only for unused/unborrowed storage. Nonzero strictly
 * increasing bind generations; nonzero frame/palette revisions, no wrap.
 * Tight packed indexed8 (256u32 palette) or XRGB32; reject padded formats.
 * Rect/None changes name the exact last observed damage base. First/full is
 * self-contained. Same pixel revision can advance palette revision for full
 * recolor; exact duplicates acquire a fresh scoped ticket with kind0, updates
 * kind1. A new generation resets observation, never the ticket counter.
 * Present kind0 unchanged,1 hidden,2 presented,3 backend failure; mode0 full,
 * 1 damage,2 replace; flags1 validates viewport. Scalar output borrows nothing.
 * Release clears every producer pointer in the actual Presenter; pending
 * damage and scalar viewport state survive for the next complete loan.
 * Close during Present returns Busy and requests closure only. Keep every
 * loan until real return; reentrant Sync/Release/Bind cannot detach it.
 * Only synchronous copied-resource backends; retained/shared/GPU transport
 * requests are Unsupported. No physical display, PPU, DMA or fence receipt.
 * Backend callbacks never retain arguments; serialized host only. */
_Static_assert(sizeof(R4SdkPublishedFrameLease)==112u,"published lease");
_Static_assert(sizeof(R4SdkPublishedFrameAcquisition)==16u,"published acquisition");
_Static_assert(sizeof(R4SdkPublishedFrameProgress)==72u,"published progress");
_Static_assert(sizeof(R4SdkPublishedFrameViewport)==32u,"published viewport");
_Static_assert(sizeof(R4SdkPublishedFramePresentation)==64u,"published presentation");
#endif
