/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_SCAN_STDIO_H
#define R4NATIVE_SCAN_STDIO_H
#include "r4nak_libc.h"

/* Private musl scan cursor, never an R4OS FILE or file descriptor. The pinned
 * sh_fromstring path uses rend == (void *)-1 and stops at the input's NUL.
 * Keep these symbols/types private to the scanner translation units. */
#define FILE struct r4native_scan_file
struct r4native_scan_file {
   unsigned char *buf, *rpos, *rend, *shend;
   off_t shlim, shcnt;
};
#define hidden __attribute__((visibility("hidden")))
static inline int __uflow(FILE *cursor)
{
   if (cursor->rpos == cursor->rend || !*cursor->rpos) return EOF;
   return *cursor->rpos++;
}
#endif
