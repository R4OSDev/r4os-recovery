#ifndef R4FONT_FREESTANDING_STDLIB_H
#define R4FONT_FREESTANDING_STDLIB_H

#include <stddef.h>

typedef int (*r4font_compare_fn)(const void *, const void *);

void abort(void);
void exit(int status);
void *malloc(size_t size);
void *calloc(size_t count, size_t size);
void *realloc(void *block, size_t size);
void free(void *block);
char *getenv(const char *name);
long strtol(const char *text, char **end, int base);
void qsort(void *base, size_t count, size_t size, r4font_compare_fn compare);

#endif
