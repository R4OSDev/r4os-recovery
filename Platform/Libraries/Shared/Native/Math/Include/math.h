/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_LIBM_TYPES_H
#define R4NATIVE_LIBM_TYPES_H
#include "r4nak_libc.h"
#include <float.h>
_Static_assert(FLT_EVAL_METHOD == 0, "Native libm requires direct SSE scalar evaluation");
typedef float float_t;
typedef double double_t;
double scalbn(double, int);
float scalbnf(float, int);
#endif
