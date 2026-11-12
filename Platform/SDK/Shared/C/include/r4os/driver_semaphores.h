#ifndef R4OS_DRIVER_SEMAPHORES_H
#define R4OS_DRIVER_SEMAPHORES_H
#include "r4dev.h"

/* Cache DriverSemaphoreApi through DriverApi33 during init. Zero acquire
 * timeout tries once; UINT64_MAX waits for a real permit. Stop/close never
 * grants a permit. Quiesce all users before destroying a semaphore. */
#define R4DRIVER_SEMAPHORE_HAS(table, member) ((table) != 0 && (table)->version == 1 && (table)->size >= offsetof(R4DriverSemaphoreApi, member) + sizeof(uint64_t) && (table)->member != 0)
static inline int32_t r4driver_semaphore_create(const R4DriverSemaphoreApi *table, uint32_t initial, uint32_t maximum, uint64_t *handle) {
    if (handle == 0) return R4OS_DRIVER_SEMAPHORE_ERROR_INVALID;
    *handle = 0;
    if (!R4DRIVER_SEMAPHORE_HAS(table, create)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint32_t, uint32_t, uint64_t *);
    return ((Callback)(uintptr_t)table->create)(initial, maximum, handle);
}
static inline int32_t r4driver_semaphore_acquire(const R4DriverSemaphoreApi *table, uint64_t handle, uint64_t ticks) {
    if (!R4DRIVER_SEMAPHORE_HAS(table, acquire)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t, uint64_t);
    return ((Callback)(uintptr_t)table->acquire)(handle, ticks);
}
static inline int32_t r4driver_semaphore_release(const R4DriverSemaphoreApi *table, uint64_t handle) {
    if (!R4DRIVER_SEMAPHORE_HAS(table, release)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t);
    return ((Callback)(uintptr_t)table->release)(handle);
}
static inline int32_t r4driver_semaphore_destroy(const R4DriverSemaphoreApi *table, uint64_t handle) {
    if (!R4DRIVER_SEMAPHORE_HAS(table, destroy)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t);
    return ((Callback)(uintptr_t)table->destroy)(handle);
}
static inline int32_t r4driver_semaphore_status(const R4DriverSemaphoreApi *table, uint64_t handle, R4DriverSemaphoreStatus *output) {
    if (!R4DRIVER_SEMAPHORE_HAS(table, status)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_DRIVER_SEMAPHORE_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, R4DriverSemaphoreStatus *);
    return ((Callback)(uintptr_t)table->status)(handle, output);
}
static inline int32_t r4driver_semaphore_stats(const R4DriverSemaphoreApi *table, R4DriverSemaphoreStats *output) {
    if (!R4DRIVER_SEMAPHORE_HAS(table, stats)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_DRIVER_SEMAPHORE_ERROR_INVALID;
    typedef int32_t (*Callback)(R4DriverSemaphoreStats *);
    return ((Callback)(uintptr_t)table->stats)(output);
}
static inline uint32_t r4driver_semaphore_context_flags(const R4DriverSemaphoreApi *table) {
    if (!R4DRIVER_SEMAPHORE_HAS(table, context_flags)) return 0;
    typedef uint32_t (*Callback)(void);
    return ((Callback)(uintptr_t)table->context_flags)();
}
#undef R4DRIVER_SEMAPHORE_HAS
#endif
