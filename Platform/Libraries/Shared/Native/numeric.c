/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"

/* Consumers may retain a narrower error owner (R4VK's compiler job). Ordinary
 * native C callers use errno.c and their exact-generation thread-local cell. */
#ifndef R4NATIVE_ERRNO_LOCATION
#define R4NATIVE_ERRNO_LOCATION r4native_errno_location
#endif
extern int *R4NATIVE_ERRNO_LOCATION(void);

struct integer_scan {
   unsigned long long value;
   bool negative, overflow;
};

static unsigned digit_value(unsigned char ch)
{
   if (ch >= '0' && ch <= '9') return ch - '0';
   if (ch >= 'a' && ch <= 'z') return ch - 'a' + 10;
   if (ch >= 'A' && ch <= 'Z') return ch - 'A' + 10;
   return 36;
}

/* C-locale C11/C17 integer grammar. Prefixes consume only a following valid
 * digit; no-conversion leaves end at the original string and errno unchanged.
 * Overflow saturates but keeps scanning to the first non-digit. */
static struct integer_scan scan_integer(const char *text, char **end, int base,
                                       unsigned long long positive_limit,
                                       unsigned long long negative_limit)
{
   struct integer_scan result = {0};
   if (end) *end = (char *)text;
   if (base && (base < 2 || base > 36)) {
      *R4NATIVE_ERRNO_LOCATION() = EINVAL;
      return result;
   }
   const char *at = text;
   while (*at == ' ' || (*at >= '\t' && *at <= '\r')) at++;
   result.negative = *at == '-';
   if (*at == '-' || *at == '+') at++;
   if ((!base || base == 16) && at[0] == '0' &&
       (at[1] == 'x' || at[1] == 'X') && digit_value((unsigned char)at[2]) < 16) {
      at += 2;
      base = 16;
   }
   if (!base) base = *at == '0' ? 8 : 10;
   const char *first = at;
   const unsigned long long limit = result.negative ? negative_limit : positive_limit;
   const unsigned long long cutoff = limit / (unsigned)base;
   const unsigned last_digit = (unsigned)(limit % (unsigned)base);
   for (;; at++) {
      const unsigned digit = digit_value((unsigned char)*at);
      if (digit >= (unsigned)base) break;
      if (!result.overflow) {
         if (result.value > cutoff || (result.value == cutoff && digit > last_digit)) {
            result.overflow = true;
            result.value = limit;
         } else {
            result.value = result.value * (unsigned)base + digit;
         }
      }
   }
   if (end && at != first) *end = (char *)at;
   if (result.overflow) *R4NATIVE_ERRNO_LOCATION() = ERANGE;
   return result;
}

long long strtoll(const char *text, char **end, int base)
{
   const struct integer_scan result = scan_integer(text, end, base,
      LLONG_MAX, (unsigned long long)LLONG_MAX + 1);
   if (!result.negative || !result.value) return (long long)result.value;
   return -(long long)(result.value - 1) - 1;
}

long strtol(const char *text, char **end, int base)
{
   const struct integer_scan result = scan_integer(text, end, base,
      LONG_MAX, (unsigned long long)LONG_MAX + 1);
   if (!result.negative || !result.value) return (long)result.value;
   return -(long)(result.value - 1) - 1;
}

unsigned long long strtoull(const char *text, char **end, int base)
{
   const struct integer_scan result = scan_integer(text, end, base, ULLONG_MAX, ULLONG_MAX);
   return result.negative && !result.overflow ? 0ULL - result.value : result.value;
}

unsigned long strtoul(const char *text, char **end, int base)
{
   const struct integer_scan result = scan_integer(text, end, base, ULONG_MAX, ULONG_MAX);
   return (unsigned long)(result.negative && !result.overflow ? 0ULL - result.value : result.value);
}
