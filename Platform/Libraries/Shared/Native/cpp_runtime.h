/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_CPP_RUNTIME_H
#define R4NATIVE_CPP_RUNTIME_H
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Consumer adapters bind these calls to its real process owner and fatal
 * policy. The callback's code remains pinned for the process lifetime. */
void *r4native_cpp_state(const void *, size_t, size_t, void (*)(void *));
int r4native_register_finalizer(void (*)(void));
void r4native_fatal(const char *) __attribute__((noreturn));
#ifdef __cplusplus
}
#endif
#endif
