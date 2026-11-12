#ifndef R4OS_DEVICE_SNAPSHOT_PLATFORM2_H
#define R4OS_DEVICE_SNAPSHOT_PLATFORM2_H
#include "device_snapshot.h"
#include "platform2.h"
/* Borrow Context/table/code through actual capture return. Missing capability
 * stays err_no_group/err_no_fn; no repeated legacy index fallback. */
static inline int32_t R4SdkDeviceSnapshotProvider2(const R4OS2Context *context,R4SdkDeviceSnapshotProvider *out){
    if(!out)return -1;uint64_t address=0;
    int32_t rc=R4OS2ContextFunction(context,6,offsetof(R4XStartR4Dev2,device_inventory_capture),&address);
    if(rc)return rc;
    *out=(R4SdkDeviceSnapshotProvider){.capture=(R4DevDeviceInventoryCaptureFn)(uintptr_t)address};return 0;
}
#endif
