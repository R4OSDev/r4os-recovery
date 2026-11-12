/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "util/log.h"

void os_log_message(const char *text) { fputs(text, stderr); }

void mesa_log_v(enum mesa_log_level level, const char *tag,
                const char *format, va_list args)
{
   if (level > MESA_DEFAULT_LOG_LEVEL) return;
   fprintf(stderr, "%s: ", tag);
   vfprintf(stderr, format, args);
   fputc('\n', stderr);
}
void mesa_log(enum mesa_log_level level, const char *tag,
              const char *format, ...)
{
   va_list args;
   va_start(args, format);
   mesa_log_v(level, tag, format, args);
   va_end(args);
}
void _mesa_log_multiline(enum mesa_log_level level, const char *tag, const char *text)
{
   if (level > MESA_DEFAULT_LOG_LEVEL) return;
   while (*text) {
      const char *end = strchr(text, '\n');
      size_t bytes = end ? (size_t)(end - text) : strlen(text);
      fprintf(stderr, "%s: ", tag);
      fwrite(text, 1, bytes, stderr);
      fputc('\n', stderr);
      text += bytes + (end != NULL);
   }
}
