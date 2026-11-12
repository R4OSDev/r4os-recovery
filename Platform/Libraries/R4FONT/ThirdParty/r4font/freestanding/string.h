#ifndef R4FONT_FREESTANDING_STRING_H
#define R4FONT_FREESTANDING_STRING_H

#include <stddef.h>

void *memchr(const void *block, int value, size_t length);
int memcmp(const void *left, const void *right, size_t length);
void *memcpy(void *destination, const void *source, size_t length);
void *memmove(void *destination, const void *source, size_t length);
void *memset(void *destination, int value, size_t length);
char *strcat(char *destination, const char *source);
int strcmp(const char *left, const char *right);
char *strcpy(char *destination, const char *source);
size_t strlen(const char *text);
int strncmp(const char *left, const char *right, size_t length);
char *strncpy(char *destination, const char *source, size_t length);
char *strrchr(const char *text, int value);
char *strstr(const char *text, const char *needle);

#endif
