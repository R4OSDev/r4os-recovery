#ifndef R4GFX_COLOR_STDLIB_H
#define R4GFX_COLOR_STDLIB_H
#include <stddef.h>
/* All admitted ICC contexts install the caller's complete memory plugin. */
#define malloc r4gfx_c_no_malloc
#define realloc r4gfx_c_no_realloc
#define free r4gfx_c_no_free
static inline void *malloc(size_t n) { (void)n; return NULL; }
static inline void *realloc(void *p, size_t n) { (void)p; (void)n; return NULL; }
static inline void free(void *p) { (void)p; }
static inline int abs(int n) { return n < 0 ? -n : n; }
#endif
