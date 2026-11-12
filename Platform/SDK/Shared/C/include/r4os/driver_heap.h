#ifndef R4OS_DRIVER_HEAP_H
#define R4OS_DRIVER_HEAP_H
#include "r4dev.h"

/* The R4D init bridge obtains this optional table through DriverApi30. Cached
 * function addresses do not transfer the actual driver's ownership. */
static inline int32_t r4driver_heap_allocate(const R4DriverHeapApi *table, uint64_t bytes, uint32_t alignment, R4DriverHeapAllocation *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4DriverHeapApi, allocate) + sizeof(uint64_t) || table->allocate == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_DRIVER_HEAP_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, uint32_t, R4DriverHeapAllocation *);
    return ((Callback)(uintptr_t)table->allocate)(bytes, alignment, output);
}
static inline int32_t r4driver_heap_release(const R4DriverHeapApi *table, uint64_t handle) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4DriverHeapApi, release) + sizeof(uint64_t) || table->release == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t);
    return ((Callback)(uintptr_t)table->release)(handle);
}
static inline int32_t r4driver_heap_stats(const R4DriverHeapApi *table, R4DriverHeapStats *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4DriverHeapApi, stats) + sizeof(uint64_t) || table->stats == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_DRIVER_HEAP_ERROR_INVALID;
    typedef int32_t (*Callback)(R4DriverHeapStats *);
    return ((Callback)(uintptr_t)table->stats)(output);
}
#endif
