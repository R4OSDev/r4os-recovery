/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NAK_LIBC_H
#define R4NAK_LIBC_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <limits.h>

#ifdef __cplusplus
extern "C" {
#define _Noreturn [[noreturn]]
#endif

typedef struct { int quot, rem; } div_t;
typedef struct { long quot, rem; } ldiv_t;
typedef struct { long long quot, rem; } lldiv_t;
div_t div(int, int);
ldiv_t ldiv(long, long);
lldiv_t lldiv(long long, long long);
typedef long ssize_t;
typedef long off_t;
typedef long time_t;
typedef struct r4nak_file FILE;
struct timespec { time_t tv_sec; long tv_nsec; };
struct tm { int tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, tm_wday, tm_yday, tm_isdst; };
struct lconv { char *decimal_point; };
extern FILE *stdin;
extern FILE *stderr;
extern FILE *stdout;
int *r4native_errno_location(void);
#define errno (*r4native_errno_location())
#define EINVAL 22
#define ETIMEDOUT 110
#define PRIX32 "X"
#define EPERM 1
#define EDEADLK 35
#define EEXIST 17
#define EINTR 4
#define ENOMEM 12
#define ENOSYS 38
#define ERANGE 34
#define EOF (-1)
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#define LC_NUMERIC 1
#define LC_ALL 6
#define TIME_UTC 1
#define PRIdMAX "ld"
#define PRIiMAX "li"
#define PRIuMAX "lu"
#define PRIxMAX "lx"
#define PRIXMAX "lX"
#define PRIiPTR "li"
#define PRIdPTR "ld"
#define PRId64 "ld"
#define PRIi64 "li"
#define PRIu64 "lu"
#define PRIx64 "lx"
#define PRIX64 "lX"
#define PRId32 "d"
#define PRIu32 "u"
#define PRIx32 "x"
#define PRIx16 "x"
#define PRIx8 "x"
#define PRIu16 "u"
#define PRIu8 "u"
#define PRIuPTR "lu"
#define PRIxPTR "lx"
#define SCNu64 "lu"
#define SCNxPTR "lx"
#define SCNuPTR "lu"
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
#ifndef __cplusplus
#define thread_local _Thread_local
#define static_assert _Static_assert
#endif
#define alloca(size) __builtin_alloca(size)

void *malloc(size_t);
void *calloc(size_t, size_t);
void *realloc(void *, size_t);
void *reallocarray(void *, size_t, size_t);
void free(void *);
void *aligned_alloc(size_t, size_t);
int posix_memalign(void **, size_t, size_t);
void *memcpy(void *, const void *, size_t);
void *memmove(void *, const void *, size_t);
void *memset(void *, int, size_t);
int memcmp(const void *, const void *, size_t);
void *memchr(const void *, int, size_t);
size_t strlen(const char *);
size_t strnlen(const char *, size_t);
int strcmp(const char *, const char *);
int strncmp(const char *, const char *, size_t);
int strcasecmp(const char *, const char *);
int strncasecmp(const char *, const char *, size_t);
char *strcpy(char *, const char *);
char *strncpy(char *, const char *, size_t);
char *strcat(char *, const char *);
char *strncat(char *, const char *, size_t);
char *strchr(const char *, int);
char *strrchr(const char *, int);
char *strstr(const char *, const char *);
size_t strcspn(const char *, const char *);
size_t strspn(const char *, const char *);
char *strpbrk(const char *, const char *);
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif
char *strdup(const char *);
char *strndup(const char *, size_t);
char *strtok_r(char *, const char *, char **);
long strtol(const char *, char **, int);
long long strtoll(const char *, char **, int);
unsigned long strtoul(const char *, char **, int);
unsigned long long strtoull(const char *, char **, int);
double strtod(const char *, char **);
float strtof(const char *, char **);
int atoi(const char *);
int rand(void);
int atexit(void (*)(void));
char *strtok(char *, const char *);
double atof(const char *);
int abs(int);
long labs(long);
long long llabs(long long);
char *getenv(const char *);
void qsort(void *, size_t, size_t, int (*)(const void *, const void *));
void *bsearch(const void *, const void *, size_t, size_t, int (*)(const void *, const void *));
int isalnum(int);
int isalpha(int);
int isdigit(int);
int isxdigit(int);
int isspace(int);
int isprint(int);
int tolower(int);
int toupper(int);
_Noreturn void abort(void);
_Noreturn void exit(int);
_Noreturn void r4nak_port_assert(const char *, const char *, int);
#define assert(x) ((x) ? (void)0 : r4nak_port_assert(#x, __FILE__, __LINE__))
int snprintf(char *, size_t, const char *, ...);
int sscanf(const char *, const char *, ...);
int vsscanf(const char *, const char *, va_list);
int vsnprintf(char *, size_t, const char *, va_list);
int sprintf(char *, const char *, ...);
int vsprintf(char *, const char *, va_list);
int printf(const char *, ...);
int vprintf(const char *, va_list);
int fprintf(FILE *, const char *, ...);
int vfprintf(FILE *, const char *, va_list);
int fputs(const char *, FILE *);
int puts(const char *);
int putchar(int);
int fputc(int, FILE *);
size_t fwrite(const void *, size_t, size_t, FILE *);
size_t fread(void *, size_t, size_t, FILE *);
int fflush(FILE *);
int fclose(FILE *);
int remove(const char *);
int close(int);
int isatty(int);
int fileno(FILE *);
time_t time(time_t *);
void srand(unsigned);
int ferror(FILE *);
int getc(FILE *);
void clearerr(FILE *);
int feof(FILE *);
char *fgets(char *, int, FILE *);
char *strerror(int);
int fseek(FILE *, long, int);
long ftell(FILE *);
FILE *open_memstream(char **, size_t *);
FILE *fmemopen(void *, size_t, const char *);
FILE *fopen(const char *, const char *);
struct lconv *localeconv(void);
char *setlocale(int, const char *);
struct tm *localtime_r(const time_t *, struct tm *);
int timespec_get(struct timespec *, int);
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.78539816339744830962
#define M_1_PI 0.31830988618379067154
#define M_SQRT2 1.41421356237309504880
#define M_LOG2E 1.44269504088896340736
#define M_LN2 0.69314718055994530942
#define M_LOG10E 0.43429448190325182765
#define NAN (__builtin_nanf(""))
#define INFINITY (__builtin_inff())
#define HUGE_VAL (__builtin_huge_val())
#define HUGE_VALF (__builtin_huge_valf())
#ifndef __cplusplus
#define isnan(x) __builtin_isnan(x)
#define isinf(x) __builtin_isinf(x)
#define isfinite(x) __builtin_isfinite(x)
#define isnormal(x) __builtin_isnormal(x)
#define signbit(x) __builtin_signbit(x)
#define fpclassify(x) __builtin_fpclassify(FP_NAN, FP_INFINITE, FP_NORMAL, FP_SUBNORMAL, FP_ZERO, x)
#endif
#define FP_NAN 0
#define FP_INFINITE 1
#define FP_ZERO 2
#define FP_SUBNORMAL 3
#define FP_NORMAL 4
#define R4NAK_MATH1(name) double name(double); float name##f(float)
#define R4NAK_MATH2(name) double name(double, double); float name##f(float, float)
R4NAK_MATH1(fabs); R4NAK_MATH1(sqrt); R4NAK_MATH1(cbrt);
R4NAK_MATH1(sin); R4NAK_MATH1(cos); R4NAK_MATH1(tan);
R4NAK_MATH1(asin); R4NAK_MATH1(acos); R4NAK_MATH1(atan);
R4NAK_MATH1(sinh); R4NAK_MATH1(cosh); R4NAK_MATH1(tanh);
R4NAK_MATH1(asinh); R4NAK_MATH1(acosh); R4NAK_MATH1(atanh);
R4NAK_MATH1(exp); R4NAK_MATH1(exp2); R4NAK_MATH1(expm1);
R4NAK_MATH1(log); R4NAK_MATH1(log2); R4NAK_MATH1(log10); R4NAK_MATH1(log1p);
R4NAK_MATH1(floor); R4NAK_MATH1(ceil); R4NAK_MATH1(round); R4NAK_MATH1(roundeven);
R4NAK_MATH1(trunc); R4NAK_MATH1(rint); R4NAK_MATH1(nearbyint);
R4NAK_MATH2(pow); R4NAK_MATH2(fmod); R4NAK_MATH2(remainder); R4NAK_MATH2(atan2);
R4NAK_MATH2(fmin); R4NAK_MATH2(fmax); R4NAK_MATH2(copysign); R4NAK_MATH2(nextafter);
double fma(double, double, double); float fmaf(float, float, float);
double ldexp(double, int); float ldexpf(float, int);
double frexp(double, int *); float frexpf(float, int *);
double modf(double, double *); float modff(float, float *);
long lround(double);
long lroundf(float);
long long llround(double);
long long llroundf(float);
int asprintf(char **, const char *, ...);
int vasprintf(char **, const char *, va_list);
long lrint(double); long lrintf(float);
long long llrint(double); long long llrintf(float);
#ifdef __cplusplus
}
#endif
#endif
