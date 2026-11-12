#ifndef R4OS_DRIVER_CPU_POWER_H
#define R4OS_DRIVER_CPU_POWER_H
#include "r4dev.h"

#define R4_CPU_POWER_HAS(t, field) ((t) && (t)->version == 1 && (t)->size >= offsetof(R4DriverCpuPowerApi, field) + sizeof(uint64_t) && (t)->field)
static inline int32_t r4driver_cpu_power_register(const R4DriverCpuPowerApi *t, const R4CpuPowerBackend *backend, uint64_t *cookie) {
    if (!R4_CPU_POWER_HAS(t, register_backend)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(const R4CpuPowerBackend *, uint64_t *);
    return ((Fn)(uintptr_t)t->register_backend)(backend, cookie);
}
static inline int32_t r4driver_cpu_power_unregister(const R4DriverCpuPowerApi *t, uint64_t cookie) {
    if (!R4_CPU_POWER_HAS(t, unregister_backend)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint64_t);
    return ((Fn)(uintptr_t)t->unregister_backend)(cookie);
}
static inline uint32_t r4driver_cpu_power_current(const R4DriverCpuPowerApi *t) {
    if (!R4_CPU_POWER_HAS(t, current_cpu)) return R4OS_CPU_POWER_CPU_NONE;
    typedef uint32_t (*Fn)(void);
    return ((Fn)(uintptr_t)t->current_cpu)();
}
static inline int32_t r4driver_cpu_power_capabilities(const R4DriverCpuPowerApi *t, uint32_t cpu, R4CpuCapabilitiesInfo *out) {
    if (!R4_CPU_POWER_HAS(t, capabilities)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, R4CpuCapabilitiesInfo *);
    return ((Fn)(uintptr_t)t->capabilities)(cpu, out);
}
static inline int32_t r4driver_cpu_power_topology(const R4DriverCpuPowerApi *t, uint32_t cpu, R4CpuTopologyInfo *out) {
    if (!R4_CPU_POWER_HAS(t, topology)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, R4CpuTopologyInfo *);
    return ((Fn)(uintptr_t)t->topology)(cpu, out);
}
static inline int32_t r4driver_cpu_power_read(const R4DriverCpuPowerApi *t, uint32_t cpu, uint64_t epoch, uint32_t id, R4CpuRegisterInfo *out) {
    if (!R4_CPU_POWER_HAS(t, register_read)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, uint64_t, uint32_t, R4CpuRegisterInfo *);
    return ((Fn)(uintptr_t)t->register_read)(cpu, epoch, id, out);
}
static inline int32_t r4driver_cpu_power_clock(const R4DriverCpuPowerApi *t, R4MonotonicClockInfo *out) {
    if (!R4_CPU_POWER_HAS(t, clock)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(R4MonotonicClockInfo *);
    return ((Fn)(uintptr_t)t->clock)(out);
}
static inline int32_t r4driver_cpu_power_counters(const R4DriverCpuPowerApi *t, uint32_t cpu, uint64_t epoch, R4CpuPowerCounters *out) {
    if (!R4_CPU_POWER_HAS(t, counters_read)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, uint64_t, R4CpuPowerCounters *);
    return ((Fn)(uintptr_t)t->counters_read)(cpu, epoch, out);
}
static inline int32_t r4driver_cpu_power_feature(const R4DriverCpuPowerApi *t, uint32_t cpu, uint64_t epoch, uint32_t ordinal, R4CpuFeatureInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, feature)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, uint64_t, uint32_t, R4CpuFeatureInfo *);
    return ((Fn)(uintptr_t)t->feature)(cpu, epoch, ordinal, out);
}
static inline int32_t r4driver_cpu_power_register_performance(const R4DriverCpuPowerApi *t, uint64_t cookie, const R4CpuPerformanceBackend *backend) {
    if (!backend) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, register_performance)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint64_t, const R4CpuPerformanceBackend *);
    return ((Fn)(uintptr_t)t->register_performance)(cookie, backend);
}
static inline int32_t r4driver_cpu_power_control_acquire(const R4DriverCpuPowerApi *t, uint32_t cpu, uint64_t epoch, uint64_t *token) {
    if (!token) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, control_acquire)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, uint64_t, uint64_t *);
    return ((Fn)(uintptr_t)t->control_acquire)(cpu, epoch, token);
}
static inline int32_t r4driver_cpu_power_control_release(const R4DriverCpuPowerApi *t, uint32_t cpu, uint64_t epoch, uint64_t token) {
    if (0) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, control_release)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, uint64_t, uint64_t);
    return ((Fn)(uintptr_t)t->control_release)(cpu, epoch, token);
}
static inline int32_t r4driver_cpu_power_compare_write(const R4DriverCpuPowerApi *t, uint32_t cpu, uint64_t epoch, uint64_t token, uint32_t id, uint64_t expected, uint64_t requested, R4CpuRegisterWriteInfo *out) {
    if (!out) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, register_compare_write)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint32_t, uint64_t, uint64_t, uint32_t, uint64_t, uint64_t, R4CpuRegisterWriteInfo *);
    return ((Fn)(uintptr_t)t->register_compare_write)(cpu, epoch, token, id, expected, requested, out);
}
static inline int32_t r4driver_cpu_power_register_cppc(const R4DriverCpuPowerApi *t, uint64_t cookie, const R4CpuCppcBackend *backend) {
    if (!backend) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, register_cppc)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(uint64_t, const R4CpuCppcBackend *);
    return ((Fn)(uintptr_t)t->register_cppc)(cookie, backend);
}
static inline int32_t r4driver_cpu_power_rank_publish(const R4DriverCpuPowerApi *t, const R4CpuPerformanceHint *input, uint64_t *sequence) {
    if (!input || !sequence) return R4OS_CPU_CAPABILITIES_ERROR_INVALID;
    if (!R4_CPU_POWER_HAS(t, rank_publish)) return R4OS_ERR_NO_FN;
    typedef int32_t (*Fn)(const R4CpuPerformanceHint *, uint64_t *);
    return ((Fn)(uintptr_t)t->rank_publish)(input, sequence);
}

#undef R4_CPU_POWER_HAS
#endif
