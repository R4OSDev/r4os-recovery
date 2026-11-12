/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_ERRNO_H
#define R4NATIVE_ERRNO_H
#ifdef __cplusplus
extern "C" {
#endif
/* Private C runtime of the consuming R4L, bound to its current caller/thread. */
int *r4native_errno_location(void);
#ifdef __cplusplus
}
#endif
#endif
