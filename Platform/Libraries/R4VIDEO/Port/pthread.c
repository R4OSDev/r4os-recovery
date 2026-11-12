/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include <pthread.h>
#include <stdlib.h>

/* Decoder budget/ownership follows workers, not the currently active client. */
void *r4video_task_owner(void);
int r4video_task_enter(void *);
int r4video_worker_acquire(void *);
void r4video_worker_release(void *);
int r4native_mutex_close(mtx_t *);
int r4video_condition_close(cnd_t *);
int r4video_thread_tryjoin(const thrd_t *, int *);

struct r4video_thread_start {
    void *(*entry)(void *);
    void *argument, *result, *owner;
    mtx_t startup_mutex;
    cnd_t startup_condition;
    int ready, admitted;
};
static int status(int code)
{
    switch (code) {
    case thrd_success: return 0;
    case thrd_timedout: return ETIMEDOUT;
    case thrd_nomem: return ENOMEM;
    case thrd_busy: return EBUSY;
    default: return EINVAL;
    }
}
static int run(void *argument)
{
    struct r4video_thread_start *start = argument;
    int admitted = r4video_task_enter(start->owner);
    if (mtx_lock(&start->startup_mutex) != thrd_success) abort();
    start->admitted = admitted;
    start->ready = 1;
    if (cnd_signal(&start->startup_condition) != thrd_success ||
        mtx_unlock(&start->startup_mutex) != thrd_success) abort();
    if (!admitted) return 0;
    start->result = start->entry(start->argument);
    return 0;
}
int pthread_create(pthread_t *output, const pthread_attr_t *attr, void *(*entry)(void *), void *argument)
{
    if (!output || !entry || attr) return EINVAL;
    void *owner = r4video_task_owner();
    if (!owner || !r4video_worker_acquire(owner)) return ENOMEM;
    struct r4video_thread_start *start = malloc(sizeof(*start));
    if (!start) { r4video_worker_release(owner); return ENOMEM; }
    *start = (struct r4video_thread_start){.entry=entry, .argument=argument, .owner=owner};
    int result = mtx_init(&start->startup_mutex, mtx_plain);
    if (result != thrd_success) goto failed;
    result = cnd_init(&start->startup_condition);
    if (result != thrd_success) goto failed_mutex;
    if (mtx_lock(&start->startup_mutex) != thrd_success) abort();
    pthread_t thread = {.start=start};
    result = thrd_create(&thread.handle, run, start);
    if (result == thrd_success) {
        while (!start->ready)
            if (cnd_wait(&start->startup_condition, &start->startup_mutex) != thrd_success) abort();
        if (!start->admitted) result = thrd_nomem;
    }
    if (mtx_unlock(&start->startup_mutex) != thrd_success) abort();
    if (result != thrd_success) {
        if (start->ready && thrd_join(thread.handle, NULL) != thrd_success) abort();
        if (r4video_condition_close(&start->startup_condition) != thrd_success) abort();
        goto failed_mutex;
    }
    *output = thread;
    return 0;
failed_mutex:
    if (r4native_mutex_close(&start->startup_mutex) != thrd_success) abort();
failed:
    free(start);
    r4video_worker_release(owner);
    return status(result);
}
static void retire(pthread_t thread, void **result)
{
    if (result) *result = thread.start->result;
    if (r4video_condition_close(&thread.start->startup_condition) != thrd_success ||
        r4native_mutex_close(&thread.start->startup_mutex) != thrd_success) abort();
    void *owner = thread.start->owner;
    free(thread.start);
    r4video_worker_release(owner);
}
int pthread_join(pthread_t thread, void **result)
{
    if (!thread.start) return EINVAL;
    /* FFmpeg ignores join failures before freeing shared decoder state. */
    if (thrd_join(thread.handle, NULL) != thrd_success) abort();
    retire(thread, result);
    return 0;
}
int r4video_pthread_tryjoin(pthread_t *thread)
{
    if (!thread || !thread->start) return EINVAL;
    int joined = r4video_thread_tryjoin(&thread->handle, NULL);
    if (joined == thrd_busy) return EBUSY;
    if (joined != thrd_success) abort();
    retire(*thread, NULL);
    *thread = (pthread_t){0};
    return 0;
}
int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attr)
{
    int type = attr ? attr->type : PTHREAD_MUTEX_NORMAL;
    if (type < PTHREAD_MUTEX_NORMAL || type > PTHREAD_MUTEX_ERRORCHECK) return EINVAL;
    return status(mtx_init(mutex, type == PTHREAD_MUTEX_RECURSIVE ? mtx_recursive : mtx_plain));
}
int pthread_mutex_destroy(pthread_mutex_t *mutex) { return status(r4native_mutex_close(mutex)); }
int pthread_mutex_lock(pthread_mutex_t *mutex) { return status(mtx_lock(mutex)); }
int pthread_mutex_unlock(pthread_mutex_t *mutex) { return status(mtx_unlock(mutex)); }
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr)
{ return attr ? EINVAL : status(cnd_init(cond)); }
int pthread_cond_destroy(pthread_cond_t *cond) { return status(r4video_condition_close(cond)); }
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex) { return status(cnd_wait(cond, mutex)); }
int pthread_cond_timedwait(pthread_cond_t *cond, pthread_mutex_t *mutex, const struct timespec *deadline)
{ return status(cnd_timedwait(cond, mutex, deadline)); }
int pthread_cond_signal(pthread_cond_t *cond) { return status(cnd_signal(cond)); }
int pthread_cond_broadcast(pthread_cond_t *cond) { return status(cnd_broadcast(cond)); }
int pthread_once(pthread_once_t *once, void (*callback)(void)) { call_once(once, callback); return 0; }
int pthread_mutexattr_init(pthread_mutexattr_t *attr) { attr->type = PTHREAD_MUTEX_NORMAL; return 0; }
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int type)
{
    if (type < PTHREAD_MUTEX_NORMAL || type > PTHREAD_MUTEX_ERRORCHECK) return EINVAL;
    attr->type = type; return 0;
}
int pthread_mutexattr_destroy(pthread_mutexattr_t *attr) { (void)attr; return 0; }
