#ifndef R4FONT_FREESTANDING_STDIO_H
#define R4FONT_FREESTANDING_STDIO_H

#include <stddef.h>
#include <stdarg.h>

typedef struct R4FontFreestandingFile FILE;

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

extern FILE *stderr;
int fclose(FILE *file);
FILE *fopen(const char *path, const char *mode);
size_t fread(void *output, size_t size, size_t count, FILE *file);
int fseek(FILE *file, long offset, int origin);
long ftell(FILE *file);
int snprintf(char *output, size_t capacity, const char *format, ...);
int fprintf(FILE *file, const char *format, ...);
int fflush(FILE *file);

#endif
