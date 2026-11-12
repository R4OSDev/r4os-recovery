/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef CND_MONOTONIC_H
#define CND_MONOTONIC_H
#include "c11/threads.h"

/* Mesa's queue/sync code uses an absolute monotonic deadline. No UTC
 * timed-wait entrypoint is exposed until the port supplies UTC semantics. */
struct u_cnd_monotonic { cnd_t cond; };
#ifdef __cplusplus
extern "C" {
#endif

int u_cnd_monotonic_init(struct u_cnd_monotonic *);
void u_cnd_monotonic_destroy(struct u_cnd_monotonic *);
int u_cnd_monotonic_signal(struct u_cnd_monotonic *);
int u_cnd_monotonic_broadcast(struct u_cnd_monotonic *);
int u_cnd_monotonic_wait(struct u_cnd_monotonic *, mtx_t *);
int u_cnd_monotonic_timedwait(struct u_cnd_monotonic *, mtx_t *, const struct timespec *);
#ifdef __cplusplus
}
#endif
#endif
