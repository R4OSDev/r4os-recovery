/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4ENC_WELS_THREADS_H
#define R4ENC_WELS_THREADS_H
#include <c11_threads.h>
typedef uintptr_t WELS_THREAD_HANDLE;
typedef void *(*LPWELS_THREAD_ROUTINE)(void *);
typedef mtx_t WELS_MUTEX;
typedef uintptr_t WELS_EVENT;
#define WELS_THREAD_ROUTINE_TYPE void *
#define WELS_THREAD_ROUTINE_RETURN(rc) return (void *)(intptr_t)(rc);
#endif