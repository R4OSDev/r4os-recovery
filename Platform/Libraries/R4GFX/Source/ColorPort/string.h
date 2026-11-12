#ifndef R4GFX_COLOR_STRING_H
#define R4GFX_COLOR_STRING_H
#include <stddef.h>
#define memcpy r4gfx_c_memcpy
#define memmove r4gfx_c_memmove
#define memset r4gfx_c_memset
#define memcmp r4gfx_c_memcmp
#define strlen r4gfx_c_strlen
#define strcpy r4gfx_c_strcpy
#define strncpy r4gfx_c_strncpy
void *memcpy(void *, const void *, size_t);
void *memmove(void *, const void *, size_t);
void *memset(void *, int, size_t);
int memcmp(const void *, const void *, size_t);
size_t strlen(const char *);
char *strcpy(char *, const char *);
char *strncpy(char *, const char *, size_t);
#endif
