/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_SCAN_MATH_H
#define R4NATIVE_SCAN_MATH_H
#include "r4nak_libc.h"
#include <float.h>

/* Select musl's supported 53-bit internal accumulator. All arithmetic uses
 * SSE/MXCSR, like native C float/double. No public long-double ABI is exposed. */
_Static_assert(sizeof(long double) == 8 && LDBL_MANT_DIG == 53 &&
               LDBL_MAX_EXP == 1024 && FLT_EVAL_METHOD == 0,
               "Scanner requires private binary64 long double and direct evaluation");
double scalbn(double, int);
static inline long double copysignl(long double x, long double y) { return __builtin_copysign((double)x, (double)y); }
static inline long double fabsl(long double x) { return __builtin_fabs((double)x); }
static inline long double fmodl(long double x, long double y) { return fmod((double)x, (double)y); }
static inline long double scalbnl(long double x, int n) { return scalbn((double)x, n); }
#endif
