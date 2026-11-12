#ifndef R4OS_DRIVER_MEMORY_H
#define R4OS_DRIVER_MEMORY_H
#include "r4draw.h"

/* Obtained by the R4D v25 gfx_memory_query tail. Calls require the current
 * driver callback context. No global CPU pointer is a DMA or GPU address. */

/* Immutable boot-map coverage proof; does not allocate or map memory. */
static inline int32_t r4driver_memory_reserved_span(const R4GfxDriverMemoryApi *table, uint64_t base, uint64_t bytes) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, reserved_span) + sizeof(uint64_t) || table->reserved_span == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t, uint64_t);
    return ((Callback)(uintptr_t)table->reserved_span)(base, bytes);
}

/* Negative system-memory proof; actual device storage is measured by its driver. */
static inline int32_t r4driver_memory_unmanaged_span(const R4GfxDriverMemoryApi *table, uint64_t base, uint64_t bytes) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, unmanaged_span) + sizeof(uint64_t) || table->unmanaged_span == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t, uint64_t);
    return ((Callback)(uintptr_t)table->unmanaged_span)(base, bytes);
}

static inline int32_t r4driver_memory_device_lost(const R4GfxDriverMemoryApi *table, uint32_t adapter, uint64_t generation, uint32_t quiesced) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, device_lost) + sizeof(uint64_t) || table->device_lost == 0) return R4OS_ERR_NO_FN;
    if (quiesced > 1) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(uint32_t, uint64_t, uint32_t);
    return ((Callback)(uintptr_t)table->device_lost)(adapter, generation, quiesced);
}

static inline int32_t r4driver_telemetry_exchange(const R4GfxDriverMemoryApi *table, const R4GfxTelemetryState *input, R4GfxTelemetryDemand *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, telemetry_exchange) + sizeof(uint64_t) || table->telemetry_exchange == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxTelemetryState *, R4GfxTelemetryDemand *);
    R4GfxTelemetryDemand temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = ((Callback)(uintptr_t)table->telemetry_exchange)(input, &temporary);
    if (rc == R4OS_GFX_BUFFER_RESULT_OK) *output = temporary;
    return rc;
}

static inline int32_t r4driver_memory_budget(const R4GfxDriverMemoryApi *table, const R4GfxDeviceBudgetRequest *input, R4GfxDeviceBudgetState *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, memory_budget) + sizeof(uint64_t) || table->memory_budget == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxDeviceBudgetRequest *, R4GfxDeviceBudgetState *);
    R4GfxDeviceBudgetState temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = ((Callback)(uintptr_t)table->memory_budget)(input, &temporary);
    if (rc == R4OS_GFX_BUFFER_RESULT_OK) *output = temporary;
    return rc;
}

static inline int32_t r4driver_memory_virtual_register(const R4GfxDriverMemoryApi *table, const R4GfxNativeProvider * input, R4GfxBufferHandle * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, virtual_register) + sizeof(uint64_t) || table->virtual_register == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxNativeProvider *, R4GfxBufferHandle *);
    Callback callback = (Callback)(uintptr_t)table->virtual_register;
    R4GfxBufferHandle temporary = {0};
    int32_t rc = callback(input, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4driver_memory_virtual_unregister(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * provider) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, virtual_unregister) + sizeof(uint64_t) || table->virtual_unregister == 0) return R4OS_ERR_NO_FN;
    if (provider == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *);
    Callback callback = (Callback)(uintptr_t)table->virtual_unregister;
    return callback(provider);
}

static inline int32_t r4driver_memory_virtual_take(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * provider, R4GfxVirtualJob * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, virtual_take) + sizeof(uint64_t) || table->virtual_take == 0) return R4OS_ERR_NO_FN;
    if (provider == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, R4GfxVirtualJob *);
    Callback callback = (Callback)(uintptr_t)table->virtual_take;
    R4GfxVirtualJob temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(provider, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4driver_memory_virtual_complete(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle *provider, const R4GfxVirtualCompletion *completion) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, virtual_complete) + sizeof(uint64_t) || table->virtual_complete == 0) return R4OS_ERR_NO_FN;
    if (provider == 0 || completion == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, const R4GfxVirtualCompletion *);
    return ((Callback)(uintptr_t)table->virtual_complete)(provider, completion);
}

static inline int32_t r4driver_memory_native_register(const R4GfxDriverMemoryApi *table, const R4GfxNativeProvider * input, R4GfxBufferHandle * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, native_register) + sizeof(uint64_t) || table->native_register == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxNativeProvider *, R4GfxBufferHandle *);
    Callback callback = (Callback)(uintptr_t)table->native_register;
    R4GfxBufferHandle temporary = {0};
    int32_t rc = callback(input, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4driver_memory_native_unregister(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * provider) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, native_unregister) + sizeof(uint64_t) || table->native_unregister == 0) return R4OS_ERR_NO_FN;
    if (provider == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *);
    Callback callback = (Callback)(uintptr_t)table->native_unregister;
    return callback(provider);
}

static inline int32_t r4driver_memory_native_take(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * provider, R4GfxNativeJob * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, native_take) + sizeof(uint64_t) || table->native_take == 0) return R4OS_ERR_NO_FN;
    if (provider == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, R4GfxNativeJob *);
    Callback callback = (Callback)(uintptr_t)table->native_take;
    R4GfxNativeJob temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(provider, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4driver_memory_native_complete(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * provider, const R4GfxBufferHandle * request, int32_t result, const R4GfxBufferHandle * reference) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, native_complete) + sizeof(uint64_t) || table->native_complete == 0) return R4OS_ERR_NO_FN;
    if (provider == 0 || request == 0 || reference == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, const R4GfxBufferHandle *, int32_t, const R4GfxBufferHandle *);
    Callback callback = (Callback)(uintptr_t)table->native_complete;
    return callback(provider, request, result, reference);
}

static inline int32_t r4driver_memory_buffer_create(const R4GfxDriverMemoryApi *table, const R4GfxBufferDescriptor * input, R4GfxBufferReference * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_create) + sizeof(uint64_t) || table->buffer_create == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBufferDescriptor *, R4GfxBufferReference *);
    return ((Callback)(uintptr_t)table->buffer_create)(input, output);
}

static inline int32_t r4driver_memory_buffer_describe(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * input, R4GfxBufferDescriptor * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_describe) + sizeof(uint64_t) || table->buffer_describe == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, R4GfxBufferDescriptor *);
    return ((Callback)(uintptr_t)table->buffer_describe)(input, output);
}

static inline int32_t r4driver_memory_buffer_import(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * input, R4GfxBufferReference * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_import) + sizeof(uint64_t) || table->buffer_import == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, R4GfxBufferReference *);
    return ((Callback)(uintptr_t)table->buffer_import)(input, output);
}

static inline int32_t r4driver_memory_buffer_release(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * input) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_release) + sizeof(uint64_t) || table->buffer_release == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *);
    return ((Callback)(uintptr_t)table->buffer_release)(input);
}

static inline int32_t r4driver_memory_buffer_map(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * input, uint32_t access, uint64_t offset, uint64_t bytes, R4GfxBufferMap * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_map) + sizeof(uint64_t) || table->buffer_map == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, uint32_t, uint64_t, uint64_t, R4GfxBufferMap *);
    return ((Callback)(uintptr_t)table->buffer_map)(input, access, offset, bytes, output);
}

static inline int32_t r4driver_memory_buffer_unmap(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * input) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_unmap) + sizeof(uint64_t) || table->buffer_unmap == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *);
    return ((Callback)(uintptr_t)table->buffer_unmap)(input);
}

static inline int32_t r4driver_memory_device_acquire(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * reference, const R4GfxDeviceRequest * request, R4GfxDeviceLease * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, device_acquire) + sizeof(uint64_t) || table->device_acquire == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, const R4GfxDeviceRequest *, R4GfxDeviceLease *);
    return ((Callback)(uintptr_t)table->device_acquire)(reference, request, output);
}

static inline int32_t r4driver_memory_device_segment(const R4GfxDriverMemoryApi *table, const R4GfxDeviceLease * lease, uint64_t offset, R4GfxDmaSegment * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, device_segment) + sizeof(uint64_t) || table->device_segment == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxDeviceLease *, uint64_t, R4GfxDmaSegment *);
    return ((Callback)(uintptr_t)table->device_segment)(lease, offset, output);
}

static inline int32_t r4driver_memory_device_release(const R4GfxDriverMemoryApi *table, const R4GfxDeviceLease * lease, uint32_t quiesced) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, device_release) + sizeof(uint64_t) || table->device_release == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(const R4GfxDeviceLease *, uint32_t);
    return ((Callback)(uintptr_t)table->device_release)(lease, quiesced);
}

static inline int32_t r4driver_memory_mmio_map(const R4GfxDriverMemoryApi *table, const R4GfxMmioRequest * request, R4GfxMmioWindow * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, mmio_map) + sizeof(uint64_t) || table->mmio_map == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxMmioRequest *, R4GfxMmioWindow *);
    return ((Callback)(uintptr_t)table->mmio_map)(request, output);
}

static inline int32_t r4driver_memory_mmio_unmap(const R4GfxDriverMemoryApi *table, const R4GfxBufferHandle * window, uint32_t quiesced) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, mmio_unmap) + sizeof(uint64_t) || table->mmio_unmap == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(const R4GfxBufferHandle *, uint32_t);
    return ((Callback)(uintptr_t)table->mmio_unmap)(window, quiesced);
}

static inline int32_t r4driver_memory_collect(const R4GfxDriverMemoryApi *table) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, collect) + sizeof(uint64_t) || table->collect == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(void);
    return ((Callback)(uintptr_t)table->collect)();
}

static inline int32_t r4driver_memory_buffer_stats(const R4GfxDriverMemoryApi *table, R4GfxBufferStats * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_stats) + sizeof(uint64_t) || table->buffer_stats == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    R4GfxBufferStats value = {0}; value.version = 1; value.size = sizeof(value);
    typedef int32_t (*Callback)(R4GfxBufferStats *);
    int32_t code = ((Callback)(uintptr_t)table->buffer_stats)(&value);
    if (code == R4OS_GFX_BUFFER_RESULT_OK) {
        if (value.version != 1 || value.size < sizeof(value)) return R4OS_GFX_BUFFER_ERROR_INVALID;
        *output = value;
    }
    return code;
}


static inline int32_t r4driver_memory_buffer_reserve(const R4GfxDriverMemoryApi *table, const R4GfxBufferDescriptor * input, uint64_t cookie, R4GfxOwnedBufferReservation * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_reserve) + sizeof(uint64_t) || table->buffer_reserve == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBufferDescriptor *, uint64_t, R4GfxOwnedBufferReservation *);
    return ((Callback)(uintptr_t)table->buffer_reserve)(input, cookie, output);
}

static inline int32_t r4driver_memory_buffer_commit(const R4GfxDriverMemoryApi *table, const R4GfxOwnedBufferReservation * input, R4GfxBufferReference * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_commit) + sizeof(uint64_t) || table->buffer_commit == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxOwnedBufferReservation *, R4GfxBufferReference *);
    return ((Callback)(uintptr_t)table->buffer_commit)(input, output);
}

static inline int32_t r4driver_memory_buffer_abort(const R4GfxDriverMemoryApi *table, const R4GfxOwnedBufferReservation * input, uint32_t quiesced) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_abort) + sizeof(uint64_t) || table->buffer_abort == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(const R4GfxOwnedBufferReservation *, uint32_t);
    return ((Callback)(uintptr_t)table->buffer_abort)(input, quiesced);
}

static inline int32_t r4driver_memory_buffer_take_release(const R4GfxDriverMemoryApi *table, uint32_t adapter, uint64_t generation, R4GfxOwnedBufferRelease * output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_take_release) + sizeof(uint64_t) || table->buffer_take_release == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(uint32_t, uint64_t, R4GfxOwnedBufferRelease *);
    return ((Callback)(uintptr_t)table->buffer_take_release)(adapter, generation, output);
}

static inline int32_t r4driver_memory_buffer_finish_release(const R4GfxDriverMemoryApi *table, const R4GfxOwnedBufferRelease * input, uint32_t quiesced) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverMemoryApi, buffer_finish_release) + sizeof(uint64_t) || table->buffer_finish_release == 0) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(const R4GfxOwnedBufferRelease *, uint32_t);
    return ((Callback)(uintptr_t)table->buffer_finish_release)(input, quiesced);
}
#endif
