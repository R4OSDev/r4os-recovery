/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VIDEO_PTHREAD_H
#define R4VIDEO_PTHREAD_H
#include <c11/threads.h>
#include <errno.h>

/* Private FFmpeg transport, not a public POSIX ABI. Join owns the start record. */
struct r4video_thread_start;
typedef struct { thrd_t handle; struct r4video_thread_start *start; } pthread_t;
typedef mtx_t pthread_mutex_t;
typedef cnd_t pthread_cond_t;
typedef once_flag pthread_once_t;
typedef struct { int type; } pthread_mutexattr_t;
typedef struct { int unsupported; } pthread_condattr_t;
typedef struct { int unsupported; } pthread_attr_t;
#define PTHREAD_MUTEX_INITIALIZER {0}
#define PTHREAD_ONCE_INIT ONCE_FLAG_INIT
#define PTHREAD_MUTEX_NORMAL 0
#define PTHREAD_MUTEX_RECURSIVE 1
#define PTHREAD_MUTEX_ERRORCHECK 2

int pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int pthread_join(pthread_t, void **);
/* Bounded retirement for R4VIDEO coordinators. Success clears the exact handle. */
int r4video_pthread_tryjoin(pthread_t *);
int pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *);
int pthread_mutex_destroy(pthread_mutex_t *);
int pthread_mutex_lock(pthread_mutex_t *);
int pthread_mutex_unlock(pthread_mutex_t *);
int pthread_cond_init(pthread_cond_t *, const pthread_condattr_t *);
int pthread_cond_destroy(pthread_cond_t *);
int pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
int pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, const struct timespec *);
int pthread_cond_signal(pthread_cond_t *);
int pthread_cond_broadcast(pthread_cond_t *);
int pthread_once(pthread_once_t *, void (*)(void));
int pthread_mutexattr_init(pthread_mutexattr_t *);
int pthread_mutexattr_settype(pthread_mutexattr_t *, int);
int pthread_mutexattr_destroy(pthread_mutexattr_t *);
#endif
