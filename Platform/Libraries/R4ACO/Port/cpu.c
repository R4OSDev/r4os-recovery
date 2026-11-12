/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "util/u_cpu_detect.h"
#include "fenv.h"
/* One serial compiler worker using baseline x86_64 SSE2. This is a compiler
 * execution profile, not the machine's CPU inventory or scheduling capacity. */
struct _util_cpu_caps_state_t _util_cpu_caps_state={
   .once_flag={.state=2},.detect_done=1,
   .caps={.nr_cpus=1,.max_cpus=1,.cacheline=64,.has_sse=1,.has_sse2=1,.max_vector_bits=128},
};
void _util_cpu_detect_once(void) { _util_cpu_caps_state.detect_done=1; }
int fegetround(void) { uint32_t value;__asm__ volatile("stmxcsr %0":"=m"(value));return (value>>3)&0xc00; }
int fesetround(int mode) {
   if(mode!=FE_TONEAREST && mode!=FE_DOWNWARD && mode!=FE_UPWARD && mode!=FE_TOWARDZERO)return -1;
   uint32_t mxcsr;uint16_t x87;
   __asm__ volatile("stmxcsr %0":"=m"(mxcsr));__asm__ volatile("fnstcw %0":"=m"(x87));
   mxcsr=(mxcsr&~UINT32_C(0x6000))|((uint32_t)mode<<3);x87=(x87&~UINT16_C(0xc00))|mode;
   __asm__ volatile("ldmxcsr %0"::"m"(mxcsr));__asm__ volatile("fldcw %0"::"m"(x87));return 0;
}
void r4aco_fp_begin(uint64_t saved[2]) {
   uint32_t mxcsr;uint16_t x87;
   __asm__ volatile("stmxcsr %0":"=m"(mxcsr));__asm__ volatile("fnstcw %0":"=m"(x87));
   saved[0]=mxcsr;saved[1]=x87;mxcsr=0x1f80;x87=0x37f;
   __asm__ volatile("ldmxcsr %0"::"m"(mxcsr));__asm__ volatile("fldcw %0"::"m"(x87));
}
void r4aco_fp_end(const uint64_t saved[2]) {
   uint32_t mxcsr=(uint32_t)saved[0];uint16_t x87=(uint16_t)saved[1];
   __asm__ volatile("ldmxcsr %0"::"m"(mxcsr));__asm__ volatile("fldcw %0"::"m"(x87));
}
