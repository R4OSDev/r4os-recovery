// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include "WelsThreadLib.h"

// The R4ENC coordinator owns exactly one codec worker per stream. OpenH264's
// process-global thread pool is deliberately unavailable in this profile.
// Its entry points fail before acquiring resources; mutexes are real C11
// mutexes because the codec also uses them outside that optional pool.
int WelsMutexInit(WELS_MUTEX *m) { return mtx_init(m, mtx_plain); }
int WelsMutexLock(WELS_MUTEX *m) { return mtx_lock(m); }
int WelsMutexUnlock(WELS_MUTEX *m) { return mtx_unlock(m); }
int WelsMutexDestroy(WELS_MUTEX *m) { mtx_destroy(m); return 0; }
int WelsQueryLogicalProcessInfo(WelsLogicalProcessInfo *info) {
    if (!info) return WELS_THREAD_ERROR_GENERAL;
    info->ProcessorCount = 1;
    return WELS_THREAD_ERROR_OK;
}
int WelsThreadCreate(WELS_THREAD_HANDLE *, LPWELS_THREAD_ROUTINE, void *, WELS_THREAD_ATTR) {
    return WELS_THREAD_ERROR_GENERAL;
}
int WelsThreadSetName(const char *) { return WELS_THREAD_ERROR_GENERAL; }
int WelsThreadJoin(WELS_THREAD_HANDLE) { return WELS_THREAD_ERROR_GENERAL; }
WELS_THREAD_HANDLE WelsThreadSelf() { return 0; }
int WelsEventOpen(WELS_EVENT *, const char *) { return WELS_THREAD_ERROR_GENERAL; }
int WelsEventClose(WELS_EVENT *, const char *) { return WELS_THREAD_ERROR_GENERAL; }
int WelsEventSignal(WELS_EVENT *, WELS_MUTEX *, int *) { return WELS_THREAD_ERROR_GENERAL; }
int WelsEventWait(WELS_EVENT *, WELS_MUTEX *, int &) { return WELS_THREAD_ERROR_GENERAL; }
int WelsEventWaitWithTimeOut(WELS_EVENT *, uint32_t, WELS_MUTEX *) { return WELS_THREAD_ERROR_GENERAL; }
int WelsMultipleEventsWaitSingleBlocking(uint32_t, WELS_EVENT *, WELS_EVENT *, WELS_MUTEX *) {
    return WELS_THREAD_ERROR_GENERAL;
}
// Reaching a pool sleep with no supported worker is a programming error.
void WelsSleep(uint32_t) { abort(); }
