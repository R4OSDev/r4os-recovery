#ifndef R4GFX_COLOR_MATH_H
#define R4GFX_COLOR_MATH_H
#define pow r4gfx_c_pow
#define log r4gfx_c_log
#define log10 r4gfx_c_log10
#define exp r4gfx_c_exp
#define atan r4gfx_c_atan
#define atan2 r4gfx_c_atan2
#define sin r4gfx_c_sin
#define cos r4gfx_c_cos
double pow(double, double);
double log(double);
double log10(double);
double exp(double);
double atan(double);
double atan2(double, double);
double sin(double);
double cos(double);
#define sqrt(x) __builtin_sqrt(x)
#define sqrtf(x) __builtin_sqrtf(x)
#define fabs(x) __builtin_fabs(x)
#define fabsf(x) __builtin_fabsf(x)
#define floor(x) __builtin_floor(x)
#define ceil(x) __builtin_ceil(x)
#define isinf(x) __builtin_isinf(x)
#define isnan(x) __builtin_isnan(x)
#define FP_NAN 0
#define FP_INFINITE 1
#define FP_ZERO 2
#define FP_SUBNORMAL 3
#define FP_NORMAL 4
#define fpclassify(x) __builtin_fpclassify(FP_NAN, FP_INFINITE, FP_NORMAL, FP_SUBNORMAL, FP_ZERO, x)
#endif
