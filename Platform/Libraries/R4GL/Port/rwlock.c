/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include <stdbool.h>
#include <limits.h>
#include "util/rwlock.h"

/* Reader preference permits recursive read acquisition, as used by EGL's
 * public entry points. A queued writer must not block a reader already holding
 * a read lease. This lock makes no writer-fairness or robust-owner promise. */
int u_rwlock_init(struct u_rwlock *lock)
{
   int result = mtx_init(&lock->mutex, mtx_plain);
   if (result != thrd_success)
      return result;
   result = cnd_init(&lock->changed);
   if (result != thrd_success) {
      mtx_destroy(&lock->mutex);
      return result;
   }
   lock->readers = lock->waiting_writers = 0;
   lock->writer = false;
   return thrd_success;
}

/* The owner must have stopped new entry before destroying the lock. */
int u_rwlock_destroy(struct u_rwlock *lock)
{
   int result = mtx_lock(&lock->mutex);
   if (result != thrd_success)
      return result;
   bool busy = lock->readers || lock->writer || lock->waiting_writers;
   mtx_unlock(&lock->mutex);
   if (busy)
      return thrd_busy;
   cnd_destroy(&lock->changed);
   mtx_destroy(&lock->mutex);
   return thrd_success;
}

int u_rwlock_rdlock(struct u_rwlock *lock)
{
   int result = mtx_lock(&lock->mutex);
   if (result != thrd_success)
      return result;
   while (lock->writer && result == thrd_success)
      result = cnd_wait(&lock->changed, &lock->mutex);
   if (result == thrd_success) {
      if (lock->readers == UINT_MAX)
         result = thrd_error;
      else
         lock->readers++;
   }
   mtx_unlock(&lock->mutex);
   return result;
}

int u_rwlock_rdunlock(struct u_rwlock *lock)
{
   int result = mtx_lock(&lock->mutex);
   if (result != thrd_success)
      return result;
   if (!lock->readers || lock->writer)
      result = thrd_error;
   else if (--lock->readers == 0)
      result = cnd_broadcast(&lock->changed);
   mtx_unlock(&lock->mutex);
   return result;
}

int u_rwlock_wrlock(struct u_rwlock *lock)
{
   int result = mtx_lock(&lock->mutex);
   if (result != thrd_success)
      return result;
   if (lock->waiting_writers == UINT_MAX) {
      mtx_unlock(&lock->mutex);
      return thrd_error;
   }
   lock->waiting_writers++;
   while ((lock->writer || lock->readers) && result == thrd_success)
      result = cnd_wait(&lock->changed, &lock->mutex);
   lock->waiting_writers--;
   if (result == thrd_success)
      lock->writer = true;
   mtx_unlock(&lock->mutex);
   return result;
}

int u_rwlock_wrunlock(struct u_rwlock *lock)
{
   int result = mtx_lock(&lock->mutex);
   if (result != thrd_success)
      return result;
   if (!lock->writer || lock->readers)
      result = thrd_error;
   else {
      lock->writer = false;
      result = cnd_broadcast(&lock->changed);
   }
   mtx_unlock(&lock->mutex);
   return result;
}
