/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"

static void swap(unsigned char *a, unsigned char *b, size_t bytes)
{
   for (size_t i = 0; i < bytes; i++) {
      unsigned char value = a[i]; a[i] = b[i]; b[i] = value;
   }
}
static void sift(unsigned char *base, size_t root, size_t count, size_t width,
                 int (*compare)(const void *, const void *, void *), void *context)
{
   while (root < count / 2) {
      size_t child = root * 2 + 1;
      if (child + 1 < count && compare(base + child * width, base + (child + 1) * width, context) < 0)
         child++;
      if (compare(base + root * width, base + child * width, context) >= 0)
         break;
      swap(base + root * width, base + child * width, width);
      root = child;
   }
}
/* Mesa's fallback name is retained; the comparator context lives on this
 * call's stack. Nested/concurrent sorts need neither TLS nor shared pointers. */
void util_tls_qsort_r(void *base, size_t count, size_t width,
                      int (*compare)(const void *, const void *, void *), void *context)
{
   if (count < 2 || !width) return;
   if (count > SIZE_MAX / width) __builtin_trap();
   unsigned char *bytes = base;
   for (size_t i = count / 2; i; i--) sift(bytes, i - 1, count, width, compare, context);
   for (size_t i = count - 1; i; i--) {
      swap(bytes, bytes + i * width, width);
      sift(bytes, 0, i, width, compare, context);
   }
}
struct adapter { int (*compare)(const void *, const void *); };
static int compare_plain(const void *a, const void *b, void *context)
{
   return ((struct adapter *)context)->compare(a, b);
}
void qsort(void *base, size_t count, size_t width, int (*compare)(const void *, const void *))
{
   struct adapter adapter = {compare};
   util_tls_qsort_r(base, count, width, compare_plain, &adapter);
}
void *bsearch(const void *key, const void *base, size_t count, size_t width,
               int (*compare)(const void *, const void *))
{
   const unsigned char *bytes = base;
   while (count) {
      size_t middle = count / 2;
      const void *at = bytes + middle * width;
      int result = compare(key, at);
      if (!result) return (void *)at;
      if (result > 0) { bytes += (middle + 1) * width; count -= middle + 1; }
      else count = middle;
   }
   return NULL;
}
