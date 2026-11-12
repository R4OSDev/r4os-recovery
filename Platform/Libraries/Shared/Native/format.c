/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#define STB_SPRINTF_IMPLEMENTATION
#define STB_SPRINTF_NOUNALIGNED
#include "../../R4NAK/ThirdParty/stb/stb_sprintf.h"

int vsprintf(char *out, const char *format, va_list args)
{
   return stbsp_vsprintf(out, format, args);
}
int sprintf(char *out, const char *format, ...)
{
   va_list args;
   va_start(args, format);
   int count = vsprintf(out, format, args);
   va_end(args);
   return count;
}
int vsnprintf(char *out, size_t capacity, const char *format, va_list args)
{
   return stbsp_vsnprintf(out, capacity > INT_MAX ? INT_MAX : (int)capacity,
                         format, args);
}
int snprintf(char *out, size_t capacity, const char *format, ...)
{
   va_list args;
   va_start(args, format);
   int count = vsnprintf(out, capacity, format, args);
   va_end(args);
   return count;
}

int vasprintf(char **out, const char *format, va_list args)
{
   *out = NULL;
   va_list measure;
   va_copy(measure, args);
   int count = vsnprintf(NULL, 0, format, measure);
   va_end(measure);
   if (count < 0) return -1;
   char *buffer = malloc((size_t)count + 1);
   if (!buffer) return -1;
   va_list render;
   va_copy(render, args);
   int actual = vsnprintf(buffer, (size_t)count + 1, format, render);
   va_end(render);
   if (actual != count) { free(buffer); return -1; }
   *out = buffer;
   return count;
}

int asprintf(char **out, const char *format, ...)
{
   va_list args;
   va_start(args, format);
   int count = vasprintf(out, format, args);
   va_end(args);
   return count;
}
