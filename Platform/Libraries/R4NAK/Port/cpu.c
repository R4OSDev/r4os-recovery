/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#include "util/u_cpu_detect.h"
#include "fenv.h"

/* A compiler execution profile, not system inventory: one serial worker,
 * x86_64 baseline SSE2, and scalar implementations for optional features. */
struct _util_cpu_caps_state_t _util_cpu_caps_state = {
   .once_flag = 2, .detect_done = 1,
   .caps = { .nr_cpus = 1, .max_cpus = 1, .cacheline = 64,
             .has_sse = 1, .has_sse2 = 1, .max_vector_bits = 128 },
};
void _util_cpu_detect_once(void) { _util_cpu_caps_state.detect_done = 1; }
int fegetround(void)
{
   uint32_t mxcsr;
   __asm__ volatile("stmxcsr %0" : "=m"(mxcsr));
   return (int)((mxcsr >> 3) & 0xc00);
}
int fesetround(int mode)
{
   if (mode != FE_TONEAREST && mode != FE_DOWNWARD && mode != FE_UPWARD && mode != FE_TOWARDZERO) return -1;
   uint32_t mxcsr; uint16_t x87;
   __asm__ volatile("stmxcsr %0" : "=m"(mxcsr));
   __asm__ volatile("fnstcw %0" : "=m"(x87));
   mxcsr = (mxcsr & ~UINT32_C(0x6000)) | ((uint32_t)mode << 3);
   x87 = (uint16_t)((x87 & ~UINT16_C(0xc00)) | mode);
   __asm__ volatile("ldmxcsr %0" : : "m"(mxcsr));
   __asm__ volatile("fldcw %0" : : "m"(x87));
   return 0;
}
