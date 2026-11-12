#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

void *memchr(const void *block, int value, size_t length) {
    const unsigned char *bytes = (const unsigned char *)block;
    size_t index;
    for (index = 0; index < length; ++index)
        if (bytes[index] == (unsigned char)value) return (void *)(bytes + index);
    return 0;
}

int memcmp(const void *left, const void *right, size_t length) {
    const unsigned char *a = (const unsigned char *)left;
    const unsigned char *b = (const unsigned char *)right;
    size_t index;
    for (index = 0; index < length; ++index)
        if (a[index] != b[index]) return a[index] < b[index] ? -1 : 1;
    return 0;
}

void *memcpy(void *destination, const void *source, size_t length) {
    unsigned char *output = (unsigned char *)destination;
    const unsigned char *input = (const unsigned char *)source;
    size_t index;
    for (index = 0; index < length; ++index) output[index] = input[index];
    return destination;
}

void *memmove(void *destination, const void *source, size_t length) {
    unsigned char *output = (unsigned char *)destination;
    const unsigned char *input = (const unsigned char *)source;
    size_t index;
    if (output <= input) {
        for (index = 0; index < length; ++index) output[index] = input[index];
    } else {
        for (index = length; index != 0; --index) output[index - 1] = input[index - 1];
    }
    return destination;
}

void *memset(void *destination, int value, size_t length) {
    unsigned char *output = (unsigned char *)destination;
    size_t index;
    for (index = 0; index < length; ++index) output[index] = (unsigned char)value;
    return destination;
}

size_t strlen(const char *text) {
    size_t length = 0;
    while (text[length]) ++length;
    return length;
}

int strcmp(const char *left, const char *right) {
    while (*left && *left == *right) { ++left; ++right; }
    return (unsigned char)*left - (unsigned char)*right;
}

int strncmp(const char *left, const char *right, size_t length) {
    size_t index;
    for (index = 0; index < length; ++index) {
        if (left[index] != right[index] || left[index] == 0)
            return (unsigned char)left[index] - (unsigned char)right[index];
    }
    return 0;
}

char *strcpy(char *destination, const char *source) {
    char *result = destination;
    while ((*destination++ = *source++) != 0) {}
    return result;
}

char *strncpy(char *destination, const char *source, size_t length) {
    size_t index = 0;
    for (; index < length && source[index]; ++index) destination[index] = source[index];
    for (; index < length; ++index) destination[index] = 0;
    return destination;
}

char *strcat(char *destination, const char *source) {
    strcpy(destination + strlen(destination), source);
    return destination;
}

char *strrchr(const char *text, int value) {
    const char *found = 0;
    do {
        if ((unsigned char)*text == (unsigned char)value) found = text;
    } while (*text++);
    return (char *)found;
}

char *strstr(const char *text, const char *needle) {
    size_t needle_length = strlen(needle);
    if (needle_length == 0) return (char *)text;
    while (*text) {
        if (strncmp(text, needle, needle_length) == 0) return (char *)text;
        ++text;
    }
    return 0;
}

void qsort(void *base, size_t count, size_t size, r4font_compare_fn compare) {
    unsigned char *bytes = (unsigned char *)base;
    size_t index;
    if (!bytes || !compare || size == 0) return;
    for (index = 1; index < count; ++index) {
        size_t cursor = index;
        while (cursor != 0 && compare(bytes + (cursor - 1) * size,
                                      bytes + cursor * size) > 0) {
            size_t byte_index;
            for (byte_index = 0; byte_index < size; ++byte_index) {
                unsigned char temporary = bytes[(cursor - 1) * size + byte_index];
                bytes[(cursor - 1) * size + byte_index] = bytes[cursor * size + byte_index];
                bytes[cursor * size + byte_index] = temporary;
            }
            --cursor;
        }
    }
}

long strtol(const char *text, char **end, int base) {
    unsigned long value = 0;
    int negative = 0;
    const char *cursor = text;
    if (base != 0 && (base < 2 || base > 36)) { if (end) *end = (char *)text; return 0; }
    while (*cursor == ' ' || *cursor == '\t' || *cursor == '\n' || *cursor == '\r') ++cursor;
    if (*cursor == '+' || *cursor == '-') { negative = *cursor == '-'; ++cursor; }
    if (base == 0) base = 10;
    while (*cursor) {
        unsigned digit;
        if (*cursor >= '0' && *cursor <= '9') digit = (unsigned)(*cursor - '0');
        else if (*cursor >= 'A' && *cursor <= 'Z') digit = (unsigned)(*cursor - 'A') + 10u;
        else if (*cursor >= 'a' && *cursor <= 'z') digit = (unsigned)(*cursor - 'a') + 10u;
        else break;
        if (digit >= (unsigned)base) break;
        value = value * (unsigned)base + digit;
        ++cursor;
    }
    if (end) *end = (char *)cursor;
    return negative ? -(long)value : (long)value;
}

char *getenv(const char *name) { (void)name; return 0; }
void *malloc(size_t size) { (void)size; return 0; }
void *calloc(size_t count, size_t size) { (void)count; (void)size; return 0; }
void *realloc(void *block, size_t size) { (void)block; (void)size; return 0; }
void free(void *block) { (void)block; }
void abort(void) { __builtin_trap(); }
void exit(int status) { (void)status; __builtin_trap(); }
