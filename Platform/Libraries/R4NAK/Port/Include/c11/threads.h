/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NAK_C11_THREADS_H
#define R4NAK_C11_THREADS_H
#include "r4nak_libc.h"
typedef uint32_t mtx_t;
typedef uint32_t cnd_t;
typedef uint32_t once_flag;
typedef uint64_t thrd_t;
typedef uint32_t tss_t;
enum { thrd_success, thrd_timedout, thrd_error, thrd_busy, thrd_nomem };
enum { mtx_plain = 1, mtx_recursive = 2, mtx_timed = 4 };
#define ONCE_FLAG_INIT 0
#define _MTX_INITIALIZER_NP 0
#define TSS_DTOR_ITERATIONS 1
int mtx_init(mtx_t *, int);
void mtx_destroy(mtx_t *);
int mtx_lock(mtx_t *);
int mtx_trylock(mtx_t *);
int mtx_unlock(mtx_t *);
void call_once(once_flag *, void (*)(void));
thrd_t thrd_current(void);
int thrd_equal(thrd_t, thrd_t);
int cnd_init(cnd_t *);
void cnd_destroy(cnd_t *);
int cnd_wait(cnd_t *, mtx_t *);
int cnd_signal(cnd_t *);
int cnd_broadcast(cnd_t *);
#endif
