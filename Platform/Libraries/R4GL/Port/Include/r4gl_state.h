/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4GL_STATE_H
#define R4GL_STATE_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* A key has one immutable layout/initializer. The process-owned object lives
 * until process retirement. Initialization may allocate and reference other
 * keys, but must not recursively access its own key. All accesses use this
 * entrypoint; no reader may bypass its one-time initialization. */
void *r4gl_process_state(const void *key, size_t bytes, size_t alignment,
                        void (*initialize)(void *));
/* Complete caller executable path, NUL-terminated; zero on failure. */
size_t r4gl_process_exec_path(char *out, size_t capacity);
/* R4SYS scheduler capacity, success=1; failure=0 leaves outputs unchanged. */
int r4gl_cpu_capacity(uint32_t *available, uint32_t *configured);
/* Optional process-local R4GL_STARTUP_TRACE=1 markers. No allocation, option
 * cache, recursive state initialization or GPU/output operations. */
void r4gl_native_startup_trace(const char *message);
/* Optional absolute monotonic timestamps for caller-owned runtime diagnosis. */
void r4gl_native_runtime_trace(const char *stage);
/* Cold diagnostic throttles are process-owned and saturate, so concurrent
 * callers cannot reopen a warning budget through integer wraparound. */
static inline void r4gl_diagnostic_budget_init(void *data)
{
   *(unsigned *)data = 0;
}
static inline int r4gl_take_diagnostic_budget(const void *key, unsigned limit)
{
   unsigned *count = (unsigned *)r4gl_process_state(key, sizeof(unsigned),
                         __alignof__(unsigned), r4gl_diagnostic_budget_init);
   unsigned value = __atomic_load_n(count, __ATOMIC_RELAXED);
   while (value < limit) {
      if (__atomic_compare_exchange_n(count, &value, value + 1, 0,
                                      __ATOMIC_RELAXED, __ATOMIC_RELAXED))
         return 1;
   }
   return 0;
}
#ifdef __cplusplus
}
#endif
#endif
