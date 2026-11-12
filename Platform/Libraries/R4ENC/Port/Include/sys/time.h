/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4ENC_SYS_TIME_H
#define R4ENC_SYS_TIME_H
#include <c_runtime.h>
struct timeval { long tv_sec, tv_usec; };
#ifdef __cplusplus
extern "C" {
#endif
int gettimeofday(struct timeval *, void *);
struct tm *localtime(const time_t *);
size_t strftime(char *, size_t, const char *, const struct tm *);
#ifdef __cplusplus
}
#endif
#endif