/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "stdio_impl.h"
extern int r4native_scan_string64(FILE *, const char *, va_list);

int vsscanf(const char *text, const char *format, va_list arguments)
{
   /* Caller-owned, read-only cursor. Width-limited scanning must have a real
    * end pointer rather than sh_fromstring's unbounded strto* sentinel. */
   FILE cursor = {.buf = (void *)text, .rpos = (void *)text,
                  .rend = (void *)(text + strlen(text))};
   va_list copy;
   va_copy(copy, arguments);
   int result = r4native_scan_string64(&cursor, format, copy);
   va_end(copy);
   return result;
}

int sscanf(const char *text, const char *format, ...)
{
   va_list arguments;
   va_start(arguments, format);
   int result = vsscanf(text, format, arguments);
   va_end(arguments);
   return result;
}
