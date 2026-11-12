#ifndef R4GFX_COLOR_STDIO_H
#define R4GFX_COLOR_STDIO_H
#include <stddef.h>
#include <stdarg.h>
typedef struct R4GfxNoFile FILE;
#define EOF (-1)
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
/* Path/stream and text-export APIs are not part of the R4GFX ICC adapter.
   These fail explicitly; profile memory I/O uses LCMS's own memory handler. */
static inline FILE *fopen(const char *p, const char *m) { (void)p; (void)m; return NULL; }
static inline int fclose(FILE *f) { (void)f; return EOF; }
static inline int fseek(FILE *f, long p, int o) { (void)f; (void)p; (void)o; return -1; }
static inline long ftell(FILE *f) { (void)f; return -1; }
static inline size_t fread(void *p, size_t n, size_t c, FILE *f) { (void)p; (void)n; (void)c; (void)f; return 0; }
static inline size_t fwrite(const void *p, size_t n, size_t c, FILE *f) { (void)p; (void)n; (void)c; (void)f; return 0; }
static inline int remove(const char *p) { (void)p; return -1; }
static inline int fprintf(FILE *f, const char *p, ...) { (void)f; (void)p; return -1; }
static inline int vsnprintf(char *out, size_t n, const char *p, va_list args) { (void)p; (void)args; if (n) out[0] = 0; return -1; }
#endif
