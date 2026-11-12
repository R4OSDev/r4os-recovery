/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_state.h"
#include "util/u_cpu_detect.h"

static const unsigned char cpu_key;
bool r4vk_cpu_state_prepare(void)
{
   return r4vk_state_ensure(&cpu_key, sizeof(struct _util_cpu_caps_state_t),
                            _Alignof(struct _util_cpu_caps_state_t));
}
struct _util_cpu_caps_state_t *r4vk_cpu_state(void)
{
   struct _util_cpu_caps_state_t *state = r4vk_state_get(&cpu_key);
   assert(state); /* Admission prepares this process's metadata first. */
   return state;
}
static void cpuid(unsigned leaf, unsigned subleaf, unsigned result[4])
{
   __asm__ volatile("cpuid" : "=a"(result[0]), "=b"(result[1]),
                    "=c"(result[2]), "=d"(result[3]) : "a"(leaf), "c"(subleaf));
}
static uint64_t xcr0(void)
{
   unsigned lo, hi;
   __asm__ volatile("xgetbv" : "=a"(lo), "=d"(hi) : "c"(0));
   return (uint64_t)hi << 32 | lo;
}
void _util_cpu_detect_once(void)
{
   struct _util_cpu_caps_state_t *state = r4vk_cpu_state();
   struct util_cpu_caps_t *caps = &state->caps;
   unsigned info[4], maximum[4];
   cpuid(0, 0, maximum);
   memset(caps, 0, sizeof(*caps));
   for (unsigned i = 0; i < UTIL_MAX_CPUS; i++) caps->cpu_to_L3[i] = U_CPU_INVALID_L3;
   /* This selected NVK runtime consumes instruction/cache facts only. R4DEV
    * does not expose online/available CPU counts or affinity. Keep topology
    * fields explicitly unknown (zero); never report a fabricated serial CPU.
    * Generic Mesa worker-pool/affinity code must not use this private subset. */
   caps->cacheline = 64; /* x86_64 fallback, replaced by CPUID below. */
   if (maximum[0] >= 1) {
      cpuid(1, 0, info);
      caps->x86_cpu_type = (info[0] >> 8) & 15;
      if (caps->x86_cpu_type == 15) caps->x86_cpu_type += (info[0] >> 20) & 255;
      caps->has_sse = (info[3] >> 25) & 1;
      caps->has_sse2 = (info[3] >> 26) & 1;
      caps->has_sse3 = info[2] & 1;
      caps->has_ssse3 = (info[2] >> 9) & 1;
      caps->has_sse4_1 = (info[2] >> 19) & 1;
      caps->has_sse4_2 = (info[2] >> 20) & 1;
      caps->has_popcnt = (info[2] >> 23) & 1;
      caps->has_daz = caps->has_sse2;
      caps->has_avx = ((info[2] >> 28) & 1) && ((info[2] >> 27) & 1) && (xcr0() & 6) == 6;
      caps->has_f16c = ((info[2] >> 29) & 1) && caps->has_avx;
      caps->has_fma = ((info[2] >> 12) & 1) && caps->has_avx;
      unsigned line = ((info[1] >> 8) & 255) * 8;
      if (line) caps->cacheline = line;
   }
   if (maximum[0] >= 7) {
      cpuid(7, 0, info);
      caps->has_clflushopt = (info[1] >> 23) & 1;
      caps->has_avx2 = caps->has_avx && ((info[1] >> 5) & 1);
      if (caps->has_avx && (xcr0() & 0xe6) == 0xe6) {
         caps->has_avx512f = (info[1] >> 16) & 1;
         caps->has_avx512dq = (info[1] >> 17) & 1;
         caps->has_avx512ifma = (info[1] >> 21) & 1;
         caps->has_avx512pf = (info[1] >> 26) & 1;
         caps->has_avx512er = (info[1] >> 27) & 1;
         caps->has_avx512cd = (info[1] >> 28) & 1;
         caps->has_avx512bw = (info[1] >> 30) & 1;
         caps->has_avx512vl = (info[1] >> 31) & 1;
         caps->has_avx512vbmi = (info[2] >> 1) & 1;
      }
   }
   caps->max_vector_bits = caps->has_avx512f ? 512 : caps->has_avx ? 256 : caps->has_sse ? 128 : 0;
   p_atomic_set(&state->detect_done, 1);
}
