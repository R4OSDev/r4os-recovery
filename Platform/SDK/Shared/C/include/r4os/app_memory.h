#ifndef R4OS_APP_MEMORY_H
#define R4OS_APP_MEMORY_H
#include <stddef.h>
#include <stdint.h>
/* SDK-private copied callbacks for the single existing module heap owner. */
typedef struct R4App2Memory {
    uint32_t version, size, generation, flags;
    uint64_t identity;
    uint64_t vm_reserve, vm_commit, vm_decommit, vm_release;
    uint64_t notification_create, notification_query, notification_notify;
    uint64_t notification_wait, notification_close;
    uint64_t sleep_ticks, task_yield, thread_current_handle, program_exit;
} R4App2Memory;
#ifdef __cplusplus
extern "C" {
#endif
int32_t R4SdkHeapBind2(const R4App2Memory *, uint64_t);
void *R4SdkHeapAlloc2(const R4App2Memory *, uint64_t, size_t, size_t);
void *R4SdkHeapRealloc2(const R4App2Memory *, uint64_t, void *, size_t, size_t);
int32_t R4SdkHeapFree2(const R4App2Memory *, uint64_t, void *);
int32_t R4SdkHeapStats2(const R4App2Memory *, uint64_t, uint64_t *, uint32_t);
int32_t R4SdkHeapFinish2(const R4App2Memory *, uint64_t);
#ifdef __cplusplus
}
#endif
#endif
