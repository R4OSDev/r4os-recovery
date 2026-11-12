/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#include "c11/threads.h"
#define STB_SPRINTF_IMPLEMENTATION
#define STB_SPRINTF_NOUNALIGNED
#include "../ThirdParty/stb/stb_sprintf.h"

extern void *r4nak_port_allocate(size_t size, size_t alignment);
extern void *r4nak_port_reallocate(void *memory, size_t size);
extern void r4nak_port_deallocate(void *memory);
extern _Noreturn void r4nak_port_fail(uint32_t reason);
extern void r4nak_port_log(const char *bytes, size_t length);
extern uint64_t r4nak_port_clock(void);
extern void *r4nak_port_state(unsigned slot, size_t size, size_t alignment);

int errno;
void *malloc(size_t n) { return r4nak_port_allocate(n, 16); }
void free(void *p) { if (p) r4nak_port_deallocate(p); }
void *realloc(void *p, size_t n) { return r4nak_port_reallocate(p, n); }
void *calloc(size_t n, size_t width)
{
   size_t size;
   if (__builtin_mul_overflow(n, width, &size)) r4nak_port_fail(2);
   return memset(malloc(size), 0, size);
}
void *reallocarray(void *p, size_t n, size_t width)
{
   size_t size;
   if (__builtin_mul_overflow(n, width, &size)) r4nak_port_fail(2);
   return realloc(p, size);
}
void *aligned_alloc(size_t align, size_t n) { return r4nak_port_allocate(n, align); }
int posix_memalign(void **p, size_t align, size_t n)
{
   if (align < sizeof(void *) || (align & (align - 1))) return EINVAL;
   *p = aligned_alloc(align, n);
   return 0;
}
_Noreturn void abort(void) { r4nak_port_fail(3); }
_Noreturn void exit(int code) { (void)code; r4nak_port_fail(3); }
_Noreturn void r4nak_port_assert(const char *what, const char *file, int line)
{
   char text[384];
   int n = snprintf(text, sizeof(text), "NAK C assertion: %s (%s:%d)\n", what, file, line);
   if (n > 0) r4nak_port_log(text, (size_t)n < sizeof(text) ? (size_t)n : sizeof(text) - 1);
   r4nak_port_fail(3);
}

size_t strlen(const char *s) { const char *p = s; while (*p) ++p; return (size_t)(p - s); }
size_t strnlen(const char *s, size_t max) { size_t n = 0; while (n < max && s[n]) ++n; return n; }
int strcmp(const char *a, const char *b) { while (*a && *a == *b) { ++a; ++b; } return (unsigned char)*a - (unsigned char)*b; }
int strncmp(const char *a, const char *b, size_t n) { while (n && *a && *a == *b) { ++a; ++b; --n; } return n ? (unsigned char)*a - (unsigned char)*b : 0; }
int tolower(int c) { return c >= 'A' && c <= 'Z' ? c + 32 : c; }
int toupper(int c) { return c >= 'a' && c <= 'z' ? c - 32 : c; }
int strcasecmp(const char *a, const char *b) { while (*a && tolower((unsigned char)*a) == tolower((unsigned char)*b)) { ++a; ++b; } return tolower((unsigned char)*a) - tolower((unsigned char)*b); }
int strncasecmp(const char *a, const char *b, size_t n) { while (n && *a && tolower((unsigned char)*a) == tolower((unsigned char)*b)) { ++a; ++b; --n; } return n ? tolower((unsigned char)*a) - tolower((unsigned char)*b) : 0; }
char *strcpy(char *d, const char *s) { char *p = d; while ((*p++ = *s++)) {} return d; }
char *strncpy(char *d, const char *s, size_t n) { size_t i = 0; while (i < n && s[i]) { d[i] = s[i]; ++i; } while (i < n) d[i++] = 0; return d; }
char *strcat(char *d, const char *s) { strcpy(d + strlen(d), s); return d; }
char *strncat(char *d, const char *s, size_t n) { char *p = d + strlen(d); while (n-- && *s) *p++ = *s++; *p = 0; return d; }
char *strchr(const char *s, int c) { do { if ((unsigned char)*s == (unsigned char)c) return (char *)s; } while (*s++); return NULL; }
char *strrchr(const char *s, int c) { const char *last = NULL; do { if ((unsigned char)*s == (unsigned char)c) last = s; } while (*s++); return (char *)last; }
char *strstr(const char *s, const char *sub) { size_t n = strlen(sub); for (; *s; ++s) if (!strncmp(s, sub, n)) return (char *)s; return n ? NULL : (char *)s; }
size_t strcspn(const char *s, const char *set) { size_t n = 0; while (s[n] && !strchr(set, s[n])) ++n; return n; }
char *strpbrk(const char *s, const char *set) { for (; *s; ++s) if (strchr(set, *s)) return (char *)s; return NULL; }
void *memchr(const void *p, int c, size_t n) { const unsigned char *s = p; for (size_t i = 0; i < n; ++i) if (s[i] == (unsigned char)c) return (void *)(s + i); return NULL; }
char *strdup(const char *s) { size_t n = strlen(s) + 1; return memcpy(malloc(n), s, n); }
char *strndup(const char *s, size_t max) { size_t n = strnlen(s, max); char *d = malloc(n + 1); memcpy(d, s, n); d[n] = 0; return d; }
char *strtok_r(char *s, const char *delim, char **save)
{
   if (!s) s = *save;
   if (!s) return NULL;
   while (*s && strchr(delim, *s)) ++s;
   if (!*s) { *save = s; return NULL; }
   char *start = s;
   while (*s && !strchr(delim, *s)) ++s;
   if (*s) *s++ = 0;
   *save = s;
   return start;
}
int isdigit(int c) { return c >= '0' && c <= '9'; }
int isalpha(int c) { c = tolower(c); return c >= 'a' && c <= 'z'; }
int isalnum(int c) { return isdigit(c) || isalpha(c); }
int isxdigit(int c) { c = tolower(c); return isdigit(c) || (c >= 'a' && c <= 'f'); }
int isspace(int c) { return c == ' ' || (c >= '\t' && c <= '\r'); }
int isprint(int c) { return c >= 32 && c <= 126; }
int abs(int n) { return n < 0 ? -n : n; }
long labs(long n) { return n < 0 ? -n : n; }
long long llabs(long long n) { return n < 0 ? -n : n; }

static uint64_t parse_integer(const char *text, char **end, int base, bool sign, bool *negative, bool *overflow)
{
   const char *p = text;
   while (isspace((unsigned char)*p)) ++p;
   *negative = *p == '-';
   *overflow = false;
   if (*p == '-' || *p == '+') ++p;
   if (base && (base < 2 || base > 36)) { errno = EINVAL; if (end) *end = (char *)text; return 0; }
   if ((!base || base == 16) && p[0] == '0' && tolower(p[1]) == 'x' && isxdigit(p[2])) { base = 16; p += 2; }
   if (!base) base = *p == '0' ? 8 : 10;
   const char *digits = p;
   uint64_t value = 0, limit = sign ? (*negative ? UINT64_C(0x8000000000000000) : INT64_MAX) : UINT64_MAX;
   for (;;) {
      unsigned c = (unsigned char)*p;
      unsigned d = isdigit(c) ? c - '0' : isalpha(c) ? (unsigned)tolower(c) - 'a' + 10 : 36;
      if (d >= (unsigned)base) break;
      if (value > (limit - d) / (unsigned)base) *overflow = true;
      else value = value * (unsigned)base + d;
      ++p;
   }
   if (end) *end = (char *)(p == digits ? text : p);
   if (*overflow) { errno = ERANGE; return limit; }
   return value;
}
long long strtoll(const char *s, char **e, int b) { bool neg, overflow; uint64_t v = parse_integer(s, e, b, true, &neg, &overflow); return (long long)(neg ? UINT64_C(0) - v : v); }
unsigned long long strtoull(const char *s, char **e, int b) { bool neg, overflow; uint64_t v = parse_integer(s, e, b, false, &neg, &overflow); return neg && !overflow ? UINT64_C(0) - v : v; }
long strtol(const char *s, char **e, int b) { return (long)strtoll(s, e, b); }
unsigned long strtoul(const char *s, char **e, int b) { return (unsigned long)strtoull(s, e, b); }
int atoi(const char *s) { return (int)strtol(s, NULL, 10); }
int rand(void) { uint32_t *v = r4nak_port_state(1, sizeof(*v), _Alignof(uint32_t)); *v = *v * UINT32_C(1664525) + UINT32_C(1013904223); return (int)(*v & INT_MAX); }
char *getenv(const char *name) { (void)name; return NULL; }
const char *os_get_option(const char *name) { (void)name; return NULL; }
const char *os_get_option_cached(const char *name) { (void)name; return NULL; }
const char *os_get_option_secure(const char *name) { (void)name; return NULL; }
void os_log_message(const char *s) { r4nak_port_log(s, strlen(s)); }
int64_t os_time_get_nano(void) { return (int64_t)r4nak_port_clock(); }

static void swap_bytes(unsigned char *a, unsigned char *b, size_t size) { for (size_t j = 0; j < size; ++j) { unsigned char c = a[j]; a[j] = b[j]; b[j] = c; } }
static void sift(unsigned char *p, size_t start, size_t n, size_t width, int (*cmp)(const void *, const void *, void *), void *context)
{
   while (start < n / 2) {
      size_t child = start * 2 + 1;
      if (child + 1 < n && cmp(p + child * width, p + (child + 1) * width, context) < 0) ++child;
      if (cmp(p + start * width, p + child * width, context) >= 0) break;
      swap_bytes(p + start * width, p + child * width, width);
      start = child;
   }
}
/* The Mesa fallback name is retained, but the comparator context stays on
 * this call's stack. Nested sorts need neither TLS nor shared pointers. */
void util_tls_qsort_r(void *base, size_t n, size_t width, int (*cmp)(const void *, const void *, void *), void *context)
{
   if (n < 2 || !width) return;
   if (n > SIZE_MAX / width) r4nak_port_fail(1);
   unsigned char *p = base;
   for (size_t i = n / 2; i; --i) sift(p, i - 1, n, width, cmp, context);
   for (size_t i = n - 1; i; --i) { swap_bytes(p, p + i * width, width); sift(p, 0, i, width, cmp, context); }
}
struct compare_adapter { int (*compare)(const void *, const void *); };
static int compare_plain(const void *a, const void *b, void *context) { return ((struct compare_adapter *)context)->compare(a, b); }
void qsort(void *base, size_t n, size_t width, int (*cmp)(const void *, const void *)) { struct compare_adapter adapter = { cmp }; util_tls_qsort_r(base, n, width, compare_plain, &adapter); }
void *bsearch(const void *key, const void *base, size_t n, size_t width, int (*cmp)(const void *, const void *))
{
   const unsigned char *p = base;
   while (n) { size_t mid = n / 2; const void *at = p + mid * width; int c = cmp(key, at); if (!c) return (void *)at; if (c > 0) { p += (mid + 1) * width; n -= mid + 1; } else n = mid; }
   return NULL;
}

struct r4nak_file { char *bytes; size_t position, length, capacity; char **out_bytes; size_t *out_length; bool log, fixed, failed; };
static struct r4nak_file log_stream = { .log = true };
FILE *stderr = &log_stream;
FILE *stdout = &log_stream;

FILE *open_memstream(char **bytes, size_t *length)
{
   FILE *f = calloc(1, sizeof(*f));
   f->capacity = 256; f->bytes = malloc(f->capacity); f->bytes[0] = 0;
   f->out_bytes = bytes; f->out_length = length;
   *bytes = f->bytes; *length = 0;
   return f;
}
FILE *fmemopen(void *bytes, size_t length, const char *mode)
{
   FILE *f = calloc(1, sizeof(*f)); f->bytes = bytes; f->capacity = length; f->fixed = true;
   f->length = mode[0] == 'w' ? 0 : length;
   return f;
}
FILE *fopen(const char *path, const char *mode) { (void)path; (void)mode; errno = ENOSYS; return NULL; }
int fflush(FILE *f) { if (f->out_bytes) { *f->out_bytes = f->bytes; *f->out_length = f->length; } return f->failed ? EOF : 0; }
int fclose(FILE *f) { int ret = fflush(f); if (!f->log) free(f); return ret; }
int ferror(FILE *f) { return f->failed; }
size_t fwrite(const void *bytes, size_t width, size_t count, FILE *f)
{
   size_t size, end;
   if (!width || !count) return 0;
   if (__builtin_mul_overflow(width, count, &size) || __builtin_add_overflow(f->position, size, &end) || end == SIZE_MAX) r4nak_port_fail(2);
   if (f->log) { r4nak_port_log(bytes, size); return count; }
   if (f->fixed && end > f->capacity) { f->failed = true; return 0; }
   if (!f->fixed && end + 1 > f->capacity) { size_t cap = f->capacity <= SIZE_MAX / 2 ? f->capacity * 2 : end + 1; if (cap < end + 1) cap = end + 1; f->bytes = realloc(f->bytes, cap); f->capacity = cap; }
   if (f->position > f->length) memset(f->bytes + f->length, 0, f->position - f->length);
   memcpy(f->bytes + f->position, bytes, size); f->position = end;
   if (end > f->length) f->length = end;
   if (!f->fixed || f->length < f->capacity) f->bytes[f->length] = 0;
   return count;
}
size_t fread(void *bytes, size_t width, size_t count, FILE *f)
{
   if (!width || !count || f->position >= f->length) return 0;
   size_t available = (f->length - f->position) / width;
   if (count > available) count = available;
   memcpy(bytes, f->bytes + f->position, width * count); f->position += width * count; return count;
}
int fseek(FILE *f, long offset, int origin)
{
   if (f->log || origin < SEEK_SET || origin > SEEK_END) return -1;
   size_t base = origin == SEEK_SET ? 0 : origin == SEEK_CUR ? f->position : f->length;
   if ((offset < 0 && (uint64_t)(-(offset + 1)) + 1 > base) || (offset >= 0 && (uint64_t)offset > SIZE_MAX - base)) return -1;
   size_t target = offset < 0 ? base - ((uint64_t)(-(offset + 1)) + 1) : base + (size_t)offset;
   if (target > LONG_MAX || (f->fixed && target > f->capacity)) return -1;
   if (!f->fixed && target > f->length) {
      if (target + 1 > f->capacity) { f->bytes = realloc(f->bytes, target + 1); f->capacity = target + 1; }
      memset(f->bytes + f->length, 0, target + 1 - f->length);
      f->length = target;
   }
   f->position = target; return 0;
}
long ftell(FILE *f) { return f->position <= LONG_MAX ? (long)f->position : -1; }
int fputc(int c, FILE *f) { unsigned char b = (unsigned char)c; return fwrite(&b, 1, 1, f) == 1 ? b : EOF; }
int fputs(const char *s, FILE *f) { size_t n = strlen(s); return fwrite(s, 1, n, f) == n ? 0 : EOF; }
int puts(const char *s) { return fputs(s, stdout) < 0 ? EOF : fputc('\n', stdout); }
int putchar(int c) { return fputc(c, stdout); }
int vsnprintf(char *out, size_t n, const char *fmt, va_list args) { return stbsp_vsnprintf(out, n > INT_MAX ? INT_MAX : (int)n, fmt, args); }
int snprintf(char *out, size_t n, const char *fmt, ...) { va_list a; va_start(a, fmt); int r = vsnprintf(out, n, fmt, a); va_end(a); return r; }
int vsprintf(char *out, const char *fmt, va_list args) { return stbsp_vsprintf(out, fmt, args); }
int sprintf(char *out, const char *fmt, ...) { va_list a; va_start(a, fmt); int r = vsprintf(out, fmt, a); va_end(a); return r; }
struct format_sink { FILE *file; char buffer[STB_SPRINTF_MIN]; };
static char *write_format(const char *bytes, void *context, int length)
{
   struct format_sink *s = context;
   return fwrite(bytes, 1, (size_t)length, s->file) == (size_t)length ? s->buffer : NULL;
}
int vfprintf(FILE *f, const char *fmt, va_list a) { struct format_sink s = { .file = f }; int n = stbsp_vsprintfcb(write_format, &s, s.buffer, fmt, a); return f->failed ? EOF : n; }

double fabs(double x) { return __builtin_fabs(x); }
float fabsf(float x) { return __builtin_fabsf(x); }
double copysign(double x, double y) { return __builtin_copysign(x, y); }
float copysignf(float x, float y) { return __builtin_copysignf(x, y); }
double frexp(double x, int *exponent)
{
   union { double f; uint64_t u; } v = { .f = x };
   unsigned e = (unsigned)((v.u >> 52) & 0x7ff);
   *exponent = 0;
   if (e == 0x7ff || x == 0.0) return x;
   if (!e) { double f = frexp(x * 0x1p54, exponent); *exponent -= 54; return f; }
   *exponent = (int)e - 1022;
   v.u = (v.u & UINT64_C(0x800fffffffffffff)) | UINT64_C(0x3fe0000000000000);
   return v.f;
}
float frexpf(float x, int *exponent) { return (float)frexp((double)x, exponent); }
int fprintf(FILE *f, const char *fmt, ...) { va_list a; va_start(a, fmt); int r = vfprintf(f, fmt, a); va_end(a); return r; }
int vprintf(const char *fmt, va_list a) { return vfprintf(stdout, fmt, a); }
int printf(const char *fmt, ...) { va_list a; va_start(a, fmt); int r = vprintf(fmt, a); va_end(a); return r; }

int mtx_init(mtx_t *m, int type) { if (type != mtx_plain) return thrd_error; *m = 0; return thrd_success; }
void mtx_destroy(mtx_t *m) { assert(!*m); }
int mtx_lock(mtx_t *m) { if (__atomic_exchange_n(m, 1, __ATOMIC_ACQUIRE)) r4nak_port_fail(4); return thrd_success; }
int mtx_trylock(mtx_t *m) { return __atomic_exchange_n(m, 1, __ATOMIC_ACQUIRE) ? thrd_busy : thrd_success; }
int mtx_unlock(mtx_t *m) { if (__atomic_exchange_n(m, 0, __ATOMIC_RELEASE) != 1) r4nak_port_fail(4); return thrd_success; }
void call_once(once_flag *once, void (*fn)(void)) { if (*once == 2) return; if (*once != 0) r4nak_port_fail(4); *once = 1; fn(); *once = 2; }
void util_call_once_data_slow(once_flag *once, void (*fn)(const void *), const void *data) { if (*once == 2) return; if (*once != 0) r4nak_port_fail(4); *once = 1; fn(data); *once = 2; }
