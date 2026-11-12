/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Like the C standard header, this intentionally has no inclusion guard:
 * callers may select NDEBUG again before a subsequent inclusion. */
#include "r4nak_libc.h"
#undef assert
#ifdef NDEBUG
#define assert(expression) ((void)0)
#else
#define assert(expression) \
   ((expression) ? (void)0 : r4nak_port_assert(#expression, __FILE__, __LINE__))
#endif
