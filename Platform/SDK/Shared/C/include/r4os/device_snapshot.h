#ifndef R4OS_DEVICE_SNAPSHOT_H
#define R4OS_DEVICE_SNAPSHOT_H
#include "wire_helpers.h"
/* Static SDK owner. State/storage/cursor/outputs are disjoint mapped ranges.
 * Native provider code and whole record storage live through actual return.
 * Initialized state fields are private; mutate through these functions only. */
enum { R4_DEV_SNAPSHOT_INITIAL=0,R4_DEV_SNAPSHOT_COMPLETE=1,
       R4_DEV_SNAPSHOT_CAPACITY=2,R4_DEV_SNAPSHOT_FAILED=3,
       R4_DEV_SNAPSHOT_NO_PROVIDER=4,R4_DEV_SNAPSHOT_CANCELLED=5,
       R4_DEV_SNAPSHOT_CLOSED=6,R4_DEV_SNAPSHOT_INVALID_PROVIDER=7 };
enum { R4_DEV_SNAPSHOT_VIEW_COMPLETE=1,R4_DEV_SNAPSHOT_TERMINAL=2,
       R4_DEV_SNAPSHOT_IN_CALL=4,R4_DEV_SNAPSHOT_STOP_REQUESTED=8 };
enum { R4_DEV_SNAPSHOT_PAGE_MORE=1,R4_DEV_SNAPSHOT_PAGE_COMPLETE=2,
       R4_DEV_SNAPSHOT_PAGE_RESTART=3,R4_DEV_SNAPSHOT_PAGE_MAX=64 };
typedef struct R4SdkDeviceSnapshotProvider { R4DevDeviceInventoryCaptureFn capture; } R4SdkDeviceSnapshotProvider;
typedef struct R4SdkDeviceSnapshotCursor { uint64_t snapshot_generation;uint32_t next_index,reserved0; } R4SdkDeviceSnapshotCursor;
typedef struct R4SdkDeviceSnapshotPageInfo {
    uint64_t snapshot_generation;uint32_t total,returned,next_index,status,flags,reserved0;
} R4SdkDeviceSnapshotPageInfo;
typedef struct R4SdkDeviceSnapshotProgress {
    R4DeviceInventorySnapshotInfo info;uint32_t status;int32_t error_code;uint32_t flags,reserved0;
} R4SdkDeviceSnapshotProgress;
typedef struct R4SdkDeviceSnapshot {
    R4DeviceInventorySnapshotInfo info;R4SdkWireSpan storage;R4SdkDeviceSnapshotProvider provider;
    uint32_t capacity,phase,status;int32_t error_code;uint32_t busy,stop_requested;
} R4SdkDeviceSnapshot;
int32_t R4SdkDeviceSnapshotInit(R4SdkWireSpan,uint32_t,R4SdkDeviceSnapshotProvider,R4SdkDeviceSnapshot *);
int32_t R4SdkDeviceSnapshotGetProgress(const R4SdkDeviceSnapshot *,R4SdkDeviceSnapshotProgress *);
int32_t R4SdkDeviceSnapshotCapture(R4SdkDeviceSnapshot *,uint32_t,R4SdkDeviceSnapshotProgress *);
int32_t R4SdkDeviceSnapshotCancel(R4SdkDeviceSnapshot *,R4SdkDeviceSnapshotProgress *);
int32_t R4SdkDeviceSnapshotClose(R4SdkDeviceSnapshot *,R4SdkDeviceSnapshotProgress *);
int32_t R4SdkDeviceSnapshotBeginPages(const R4SdkDeviceSnapshot *,R4SdkDeviceSnapshotCursor *);
int32_t R4SdkDeviceSnapshotPage(const R4SdkDeviceSnapshot *,R4SdkDeviceSnapshotCursor *,uint32_t,R4SdkWireSpan *,R4SdkDeviceSnapshotPageInfo *);
int32_t R4SdkDeviceSnapshotGetView(const R4SdkDeviceSnapshot *,R4SdkWireSpan *);
/* Init does no capture. Capture/explicit refresh calls the provider once and
 * invalidates all former views. Capacity/OOM/failure never publish partial
 * success; diagnostic required_count is not a usable row count. Views/pages
 * exist only after validated Complete and borrow the caller copy until next
 * mutation. BeginPages explicitly creates/resets a cursor for this generation;
 * old cursors return Restart with no rows. Discard every partial traversal.
 * Page/progress/view are O(1), without a callback or repeated whole-row scan.
 * Cancel before/during capture requests stop; an active loan ends only at real
 * return. Complete/failed attempts are already terminal; use Close to discard
 * a completed view. Close has no Kernel resource or hardware acknowledgement.
 * The copy is no atomic global hardware revision, current presence or retain.
 * Raw native providers fully initialize every successful record and obey the
 * canonical capture receipt contract; they retain no output pointer. */
_Static_assert(sizeof(R4SdkDeviceSnapshotProvider)==8u,"device provider");
_Static_assert(sizeof(R4SdkDeviceSnapshotCursor)==16u,"device cursor");
_Static_assert(sizeof(R4SdkDeviceSnapshotPageInfo)==32u,"device page");
_Static_assert(sizeof(R4SdkDeviceSnapshotProgress)==80u,"device progress");
_Static_assert(sizeof(R4SdkDeviceSnapshot)==112u,"device state");
_Static_assert(offsetof(R4SdkDeviceSnapshot,provider)==80u,"device provider offset");
_Static_assert(offsetof(R4SdkDeviceSnapshot,busy)==104u,"device busy offset");
#endif
