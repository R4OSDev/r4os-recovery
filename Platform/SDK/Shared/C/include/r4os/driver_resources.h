#ifndef R4OS_DRIVER_RESOURCES_H
#define R4OS_DRIVER_RESOURCES_H
#include "r4dev.h"
#include "driver_cpu_power.h"

static inline int32_t r4driver_resource_cpu_power(const R4DriverResourceApi *table, R4DriverCpuPowerApi *output) {
    if (!output) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!table || table->version != 1 || table->size < offsetof(R4DriverResourceApi, cpu_power_query) + sizeof(uint64_t) || !table->cpu_power_query) return R4OS_ERR_NO_FN;
    R4DriverCpuPowerApi value = {.version = 1, .size = sizeof(value)};
    typedef int32_t (*Fn)(R4DriverCpuPowerApi *);
    int32_t result = ((Fn)(uintptr_t)table->cpu_power_query)(&value);
    if (result == R4OS_CPU_CAPABILITIES_OK) {
        if (value.version != 1 || value.size < 64 || !value.register_backend || !value.unregister_backend || !value.current_cpu || !value.capabilities || !value.topology || !value.register_read || !value.clock) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
        *output = value;
    }
    return result;
}

static inline int32_t r4driver_resource_platform(const R4DriverResourceApi *table, R4DriverPlatformApi *output) {
    if (!output) return R4OS_DRIVER_RESOURCE_ERROR_INVALID;
    *output = (R4DriverPlatformApi){.version = 1, .size = sizeof(*output)};
    if (!table || table->version != 1 || table->size < offsetof(R4DriverResourceApi, platform_query) + sizeof(uint64_t) || !table->platform_query) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(R4DriverPlatformApi *);
    return ((Callback)(uintptr_t)table->platform_query)(output);
}
static inline uint64_t r4driver_platform_rsdp(const R4DriverPlatformApi *table) {
    if (!table || table->version != 1 || table->size < sizeof(*table) || !table->rsdp) return 0;
    typedef uint64_t (*Callback)(void);
    return ((Callback)(uintptr_t)table->rsdp)();
}
static inline int32_t r4driver_platform_view(const R4DriverPlatformApi *table, uint64_t physical, uint64_t bytes, uint64_t *output) {
    if (!output) return R4OS_DRIVER_RESOURCE_ERROR_INVALID;
    if (!table || table->version != 1 || table->size < sizeof(*table) || !table->physical_view) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint64_t, uint64_t, uint64_t *);
    return ((Callback)(uintptr_t)table->physical_view)(physical, bytes, output);
}
static inline int32_t r4driver_platform_input(const R4DriverPlatformApi *table, uint32_t kind, uint32_t value) {
    if (!table || table->version != 1 || table->size < sizeof(*table) || !table->input_submit) return R4OS_ERR_NO_FN;
    typedef int32_t (*Callback)(uint32_t, uint32_t);
    return ((Callback)(uintptr_t)table->input_submit)(kind, value);
}

static inline int32_t r4driver_resource_stat(const R4DriverResourceApi *table, const uint8_t *name, uint32_t length, R4DriverResourceInfo *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4DriverResourceApi, stat) + sizeof(uint64_t) || table->stat == 0) return R4OS_ERR_NO_FN;
    if (name == 0 || length == 0 || length > 63 || output == 0) return R4OS_DRIVER_RESOURCE_ERROR_INVALID;
    typedef int32_t (*Callback)(const uint8_t *, uint32_t, R4DriverResourceInfo *);
    return ((Callback)(uintptr_t)table->stat)(name, length, output);
}
static inline int32_t r4driver_resource_read_at(const R4DriverResourceApi *table, uint64_t handle, uint64_t offset, uint8_t *output, uint32_t length, uint64_t deadline_ns) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4DriverResourceApi, read_at) + sizeof(uint64_t) || table->read_at == 0) return R4OS_ERR_NO_FN;
    if (output == 0 || length == 0 || length > R4OS_DRIVER_RESOURCE_MAX_READ_BYTES) return R4OS_DRIVER_RESOURCE_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, uint64_t, uint8_t *, uint32_t, uint64_t);
    return ((Callback)(uintptr_t)table->read_at)(handle, offset, output, length, deadline_ns);
}
static inline uint64_t r4driver_resource_now_ns(const R4DriverResourceApi *table) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4DriverResourceApi, now_ns) + sizeof(uint64_t) || table->now_ns == 0) return UINT64_MAX;
    typedef uint64_t (*Callback)(void);
    return ((Callback)(uintptr_t)table->now_ns)();
}
#endif
