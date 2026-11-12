/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"

/* Native consumers compile with emulated TLS. Reentrant or nested parsers
 * should use strtok_r with caller storage; strtok retains only this thread's
 * current cursor and never owns the caller's string. */
static _Thread_local char *next_token;
char *strtok(char *text, const char *delimiters)
{
   return strtok_r(text, delimiters, &next_token);
}
