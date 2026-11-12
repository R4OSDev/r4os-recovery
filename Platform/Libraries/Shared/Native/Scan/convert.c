/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#include "shgetc.h"
#include "floatscan.h"
#undef strtof
#undef strtod
extern float r4native_raw_strtof(const char *, char **);
extern double r4native_raw_strtod(const char *, char **);

static unsigned scan_begin(void)
{
   unsigned saved;
   __asm__ volatile("stmxcsr %0" : "=m"(saved));
   const unsigned clear_inexact = saved & ~0x20u;
   __asm__ volatile("ldmxcsr %0" : : "m"(clear_inexact) : "memory");
   return saved;
}

static void scan_end(unsigned saved, bool tiny)
{
   unsigned current;
   __asm__ volatile("stmxcsr %0" : "=m"(current));
   /* The pinned hexadecimal scanner can round a tiny value before its final
    * exact scaling, missing ERANGE for inexact subnormal results. Attribute
    * only this call's inexact flag, then restore the caller's sticky flag. */
   if (tiny && (current & 0x20)) errno = ERANGE;
   current |= saved & 0x20;
   __asm__ volatile("ldmxcsr %0" : : "m"(current) : "memory");
}

static bool negative_input(const char *text)
{
   while (*text == ' ' || (*text >= '\t' && *text <= '\r')) text++;
   return *text == '-';
}

/* musl's bias subtraction can lose the sign when a hexadecimal tiny value
 * rounds to zero. Keep the parsed input sign for every successful zero result,
 * including underflow; failed conversions still return the raw positive zero. */
float strtof(const char *text, char **end)
{
   char *tail;
   const unsigned saved = scan_begin();
   float value = r4native_raw_strtof(text, &tail);
   union { float f; uint32_t bits; } result = {value};
   scan_end(saved, tail != text && !(result.bits & UINT32_C(0x7f800000)));
   if (end) *end = tail;
   return tail != text && value == 0 ? (negative_input(text) ? -0.0f : 0.0f) : value;
}

double strtod(const char *text, char **end)
{
   char *tail;
   const unsigned saved = scan_begin();
   double value = r4native_raw_strtod(text, &tail);
   union { double f; uint64_t bits; } result = {value};
   scan_end(saved, tail != text && !(result.bits & UINT64_C(0x7ff0000000000000)));
   if (end) *end = tail;
   return tail != text && value == 0 ? (negative_input(text) ? -0.0 : 0.0) : value;
}

/* Same policy for scanf's bounded input cursor and non-rollback grammar. */
long double r4native_scan_float64(FILE *cursor, int precision, int prefix_ok)
{
   const char *text = (const char *)cursor->rpos;
   const unsigned saved = scan_begin();
   long double value = __floatscan(cursor, precision, prefix_ok);
   const bool matched = shcnt(cursor) != 0;
   bool tiny;
   if (precision == 0) {
      union { float f; uint32_t bits; } result = {(float)value};
      tiny = !(result.bits & UINT32_C(0x7f800000));
      value = result.f;
   } else {
      union { double f; uint64_t bits; } result = {(double)value};
      tiny = !(result.bits & UINT64_C(0x7ff0000000000000));
   }
   scan_end(saved, matched && tiny);
   return matched && value == 0 ? (negative_input(text) ? -0.0L : 0.0L) : value;
}
