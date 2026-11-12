/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "c_runtime.h"
typedef long clock_t;
#define CLOCKS_PER_SEC 1000000
clock_t clock(void);
size_t strftime(char *, size_t, const char *, const struct tm *);
struct tm *gmtime(const time_t *);
struct tm *gmtime_r(const time_t *, struct tm *);
struct tm *localtime(const time_t *);
time_t mktime(struct tm *);
