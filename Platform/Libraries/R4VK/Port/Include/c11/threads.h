/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_C11_THREADS_H
#define R4VK_C11_THREADS_H
#include <stdint.h>
#include <time.h>

typedef struct {
   uint32_t state, owner, depth, flags;
   uint64_t notification;
} mtx_t;
typedef struct {
   uint64_t notification;
   uint32_t waiters, reserved;
} cnd_t;
typedef struct {
   uint32_t thread_id, instance_id;
   uint64_t thread_generation, instance_generation, reserved;
} thrd_t;
typedef struct {
   uint32_t state, reserved;
   uint64_t notification;
} once_flag;
typedef int (*thrd_start_t)(void *);

enum { thrd_success, thrd_timedout, thrd_error, thrd_busy, thrd_nomem };
enum { mtx_plain = 1, mtx_recursive = 2, mtx_timed = 4 };
#define ONCE_FLAG_INIT {0}
#define _MTX_INITIALIZER_NP {0}

#ifdef __cplusplus
extern "C" {
#endif

int mtx_init(mtx_t *, int);
void mtx_destroy(mtx_t *);
int mtx_lock(mtx_t *);
int mtx_trylock(mtx_t *);
int mtx_unlock(mtx_t *);
int cnd_init(cnd_t *);
void cnd_destroy(cnd_t *);
int cnd_wait(cnd_t *, mtx_t *);
int cnd_signal(cnd_t *);
int cnd_broadcast(cnd_t *);
int thrd_create(thrd_t *, thrd_start_t, void *);
int thrd_join(thrd_t, int *);
thrd_t thrd_current(void);
int thrd_equal(thrd_t, thrd_t);
void thrd_yield(void);
void thrd_exit(int) __attribute__((noreturn));
void call_once(once_flag *, void (*)(void));
#ifdef __cplusplus
}
#endif
#endif
