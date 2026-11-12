#ifndef R4OS_DRIVER_THREADS_H
#define R4OS_DRIVER_THREADS_H
#include "r4dev.h"

/* Obtain DriverThreadApi through DriverApi32 during R4D init. Handles and
 * caller ownership are checked by the provider, including after close.
 * Join has a finite timeout; stop requests cooperation, never forced exit. */
typedef int32_t (*R4DriverThreadHandler)(uintptr_t context);
#define R4DRIVER_THREAD_HAS(table, member) ((table) != 0 && (table)->version == 1 && (table)->size >= offsetof(R4DriverThreadApi, member) + sizeof(uint64_t) && (table)->member != 0)

/* Original start request of the actual current dedicated Task. Context
 * ownership stays with its caller until Task retirement. */
static inline int32_t r4driver_thread_current_request(const R4DriverThreadApi *table, R4DriverThreadRequest *output) {
    if (output == 0) return R4OS_DRIVER_THREAD_ERROR_INVALID;
    if (!R4DRIVER_THREAD_HAS(table, current_request)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(R4DriverThreadRequest *);
    return ((Callback)(uintptr_t)table->current_request)(output);
}

/* Synchronous self-abort of an explicitly abortable dedicated callback.
 * Accepted negative results do not return. Refusals return normally; no
 * foreign Task or kernel owner is unwound. Module defers are bypassed. */
static inline int32_t r4driver_thread_abort_current(const R4DriverThreadApi *table, int32_t result) {
    if (!R4DRIVER_THREAD_HAS(table, abort_current)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(int32_t);
    return ((Callback)(uintptr_t)table->abort_current)(result);
}

static inline int32_t r4driver_thread_start(const R4DriverThreadApi *table, R4DriverThreadHandler handler, uintptr_t context, uint32_t flags, uint64_t *handle) {
    if (handle == 0) return R4OS_DRIVER_THREAD_ERROR_INVALID;
    *handle = 0;
    if (!R4DRIVER_THREAD_HAS(table, start)) return R4OS_ERR_NO_FN;
    if ((flags & R4OS_DRIVER_THREAD_FLAG_ABORTABLE) && !R4DRIVER_THREAD_HAS(table, abort_current)) return R4OS_ERR_NO_FN;
    const R4DriverThreadRequest request = { .version = 1, .size = sizeof(request), .handler = (uint64_t)(uintptr_t)handler, .context = context, .flags = flags };
    typedef int32_t (*Callback)(const R4DriverThreadRequest *, uint64_t *);
    return ((Callback)(uintptr_t)table->start)(&request, handle);
}
static inline int32_t r4driver_thread_stop(const R4DriverThreadApi *table, uint64_t handle) {
    if (!R4DRIVER_THREAD_HAS(table, stop)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t);
    return ((Callback)(uintptr_t)table->stop)(handle);
}
static inline int32_t r4driver_thread_join(const R4DriverThreadApi *table, uint64_t handle, uint64_t timeout_ticks, int32_t *result) {
    if (result == 0) return R4OS_DRIVER_THREAD_ERROR_INVALID;
    *result = 0;
    if (!R4DRIVER_THREAD_HAS(table, join)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t, uint64_t, int32_t *);
    return ((Callback)(uintptr_t)table->join)(handle, timeout_ticks, result);
}
static inline int32_t r4driver_thread_release(const R4DriverThreadApi *table, uint64_t handle) {
    if (!R4DRIVER_THREAD_HAS(table, release)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t);
    return ((Callback)(uintptr_t)table->release)(handle);
}
static inline int32_t r4driver_thread_status(const R4DriverThreadApi *table, uint64_t handle, R4DriverThreadStatus *output) {
    if (!R4DRIVER_THREAD_HAS(table, status)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_DRIVER_THREAD_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, R4DriverThreadStatus *);
    return ((Callback)(uintptr_t)table->status)(handle, output);
}
static inline uint64_t r4driver_thread_current(const R4DriverThreadApi *table) {
    if (!R4DRIVER_THREAD_HAS(table, current)) return 0;
    typedef uint64_t (*Callback)(void);
    return ((Callback)(uintptr_t)table->current)();
}
static inline int32_t r4driver_thread_sleep_ticks(const R4DriverThreadApi *table, uint64_t ticks) {
    if (!R4DRIVER_THREAD_HAS(table, sleep_ticks)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t);
    return ((Callback)(uintptr_t)table->sleep_ticks)(ticks);
}
static inline int32_t r4driver_thread_stats(const R4DriverThreadApi *table, R4DriverThreadStats *output) {
    if (!R4DRIVER_THREAD_HAS(table, stats)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_DRIVER_THREAD_ERROR_INVALID;
    typedef int32_t (*Callback)(R4DriverThreadStats *);
    return ((Callback)(uintptr_t)table->stats)(output);
}
#undef R4DRIVER_THREAD_HAS
#endif
