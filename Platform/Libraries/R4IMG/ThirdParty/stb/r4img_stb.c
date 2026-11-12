#include <stddef.h>
#include <stdint.h>

typedef struct R4ImgArenaHeader {
    size_t size;
    size_t previous_used;
} R4ImgArenaHeader;

static unsigned char *r4img_arena_base;
static size_t r4img_arena_capacity;
static size_t r4img_arena_used;
static size_t r4img_arena_peak;
static int r4img_arena_failed;

static void *r4img_memcpy(void *destination, const void *source, size_t length) {
    unsigned char *out = (unsigned char *)destination;
    const unsigned char *in = (const unsigned char *)source;
    size_t index;
    for (index = 0; index < length; ++index) out[index] = in[index];
    return destination;
}

static void *r4img_memmove(void *destination, const void *source, size_t length) {
    unsigned char *out = (unsigned char *)destination;
    const unsigned char *in = (const unsigned char *)source;
    size_t index;
    if (out <= in) {
        for (index = 0; index < length; ++index) out[index] = in[index];
    } else {
        for (index = length; index > 0; --index) out[index - 1] = in[index - 1];
    }
    return destination;
}

static void *r4img_memset(void *destination, int value, size_t length) {
    unsigned char *out = (unsigned char *)destination;
    size_t index;
    for (index = 0; index < length; ++index) out[index] = (unsigned char)value;
    return destination;
}

static int r4img_memcmp(const void *left, const void *right, size_t length) {
    const unsigned char *a = (const unsigned char *)left;
    const unsigned char *b = (const unsigned char *)right;
    size_t index;
    for (index = 0; index < length; ++index) {
        if (a[index] != b[index]) return a[index] < b[index] ? -1 : 1;
    }
    return 0;
}

static int r4img_abs(int value) {
    return value < 0 ? -value : value;
}

static void r4img_arena_reset(unsigned char *memory, size_t capacity) {
    uintptr_t raw = (uintptr_t)memory;
    uintptr_t aligned = (raw + 15u) & ~(uintptr_t)15u;
    size_t skipped = (size_t)(aligned - raw);
    if (skipped > capacity) {
        r4img_arena_base = memory;
        r4img_arena_capacity = 0;
        r4img_arena_used = 0;
        r4img_arena_peak = 0;
        r4img_arena_failed = 1;
        return;
    }
    r4img_arena_base = (unsigned char *)aligned;
    r4img_arena_capacity = capacity - skipped;
    r4img_arena_used = 0;
    r4img_arena_peak = 0;
    r4img_arena_failed = 0;
}

static void *r4img_arena_alloc(size_t size) {
    size_t start = (r4img_arena_used + sizeof(R4ImgArenaHeader) + 15u) & ~(size_t)15u;
    R4ImgArenaHeader *header;
    if (size == 0) size = 1;
    if (start > r4img_arena_capacity || size > r4img_arena_capacity - start) {
        r4img_arena_failed = 1;
        return (void *)0;
    }
    header = (R4ImgArenaHeader *)(r4img_arena_base + start - sizeof(R4ImgArenaHeader));
    header->size = size;
    header->previous_used = r4img_arena_used;
    r4img_arena_used = start + size;
    if (r4img_arena_used > r4img_arena_peak) r4img_arena_peak = r4img_arena_used;
    return r4img_arena_base + start;
}

static void *r4img_arena_realloc(void *pointer, size_t old_size, size_t new_size) {
    void *replacement;
    size_t copy_size;
    size_t start;
    R4ImgArenaHeader *header;
    if (pointer == (void *)0) return r4img_arena_alloc(new_size);
    start = (size_t)((unsigned char *)pointer - r4img_arena_base);
    header = (R4ImgArenaHeader *)((unsigned char *)pointer - sizeof(R4ImgArenaHeader));
    if (old_size == 0) {
        old_size = header->size;
    }
    if (start <= r4img_arena_capacity && header->size <= r4img_arena_capacity - start &&
        start + header->size == r4img_arena_used && new_size <= r4img_arena_capacity - start) {
        header->size = new_size;
        r4img_arena_used = start + new_size;
        if (r4img_arena_used > r4img_arena_peak) r4img_arena_peak = r4img_arena_used;
        return pointer;
    }
    replacement = r4img_arena_alloc(new_size);
    if (replacement == (void *)0) return (void *)0;
    copy_size = old_size < new_size ? old_size : new_size;
    r4img_memcpy(replacement, pointer, copy_size);
    return replacement;
}

static void r4img_arena_free(void *pointer) {
    size_t start;
    R4ImgArenaHeader *header;
    if (pointer == (void *)0) return;
    start = (size_t)((unsigned char *)pointer - r4img_arena_base);
    if (start > r4img_arena_capacity) return;
    header = (R4ImgArenaHeader *)((unsigned char *)pointer - sizeof(R4ImgArenaHeader));
    if (header->size <= r4img_arena_capacity - start && start + header->size == r4img_arena_used) {
        r4img_arena_used = header->previous_used;
    }
}

#define memcpy r4img_memcpy
#define memmove r4img_memmove
#define memset r4img_memset
#define memcmp r4img_memcmp
#define abs r4img_abs
#define STBI_MALLOC(size) r4img_arena_alloc(size)
#define STBI_REALLOC_SIZED(pointer, old_size, new_size) r4img_arena_realloc(pointer, old_size, new_size)
#define STBI_FREE(pointer) r4img_arena_free(pointer)
#define STBI_ASSERT(condition) ((void)0)
#define STBI_NO_STDIO
#define STBI_NO_LINEAR
#define STBI_NO_HDR
#define STBI_NO_SIMD
#define STBI_NO_FAILURE_STRINGS
#define STBI_ONLY_JPEG
#define STBI_ONLY_PNG
#define STBI_ONLY_BMP
#define STBI_MAX_DIMENSIONS 4096
#define STB_IMAGE_STATIC
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

size_t r4img_stbi_arena_peak(void) {
    return r4img_arena_peak;
}

int r4img_stbi_arena_failed(void) {
    return r4img_arena_failed;
}

int r4img_stbi_info(const unsigned char *bytes, size_t length, int *width, int *height, int *channels) {
    static unsigned char info_scratch[65536];
    if (bytes == (const unsigned char *)0 || length == 0 || length > 0x7fffffffu) return 0;
    r4img_arena_reset(info_scratch, sizeof(info_scratch));
    return stbi_info_from_memory(bytes, (int)length, width, height, channels);
}

int r4img_stbi_decode(
    const unsigned char *bytes,
    size_t length,
    unsigned char *scratch,
    size_t scratch_length,
    uint32_t *pixels,
    size_t pixel_capacity,
    int *width,
    int *height,
    int *channels
) {
    stbi_uc *rgba;
    size_t count;
    size_t index;
    if (bytes == (const unsigned char *)0 || length == 0 || length > 0x7fffffffu ||
        scratch == (unsigned char *)0 || pixels == (uint32_t *)0) return 0;
    r4img_arena_reset(scratch, scratch_length);
    rgba = stbi_load_from_memory(bytes, (int)length, width, height, channels, STBI_rgb_alpha);
    if (rgba == (stbi_uc *)0 || *width <= 0 || *height <= 0) return 0;
    count = (size_t)*width * (size_t)*height;
    if ((size_t)*width != 0 && count / (size_t)*width != (size_t)*height) return 0;
    if (count > pixel_capacity) return 0;
    for (index = 0; index < count; ++index) {
        const unsigned char red = rgba[index * 4u + 0u];
        const unsigned char green = rgba[index * 4u + 1u];
        const unsigned char blue = rgba[index * 4u + 2u];
        const unsigned char alpha = rgba[index * 4u + 3u];
        pixels[index] = ((uint32_t)alpha << 24) | ((uint32_t)red << 16) |
            ((uint32_t)green << 8) | (uint32_t)blue;
    }
    return 1;
}

/* Caller-serialized, same bounded arena as the established8-bit decoder.
 * Preserve all16 source bits;8-bit channels expand exactly by257. Alpha is
 * straight, full-range and linear. No transfer or color-profile conversion. */
int r4img_stbi_decode16(const unsigned char *bytes, size_t length,
    unsigned char *scratch, size_t scratch_length, uint16_t *pixels,
    size_t pixel_capacity, int *width, int *height, int *channels)
{
    stbi_us *rgba;
    size_t count;
    if (!bytes || !length || length > 0x7fffffffu || !scratch || !pixels) return 0;
    r4img_arena_reset(scratch, scratch_length);
    rgba = stbi_load_16_from_memory(bytes, (int)length, width, height, channels, STBI_rgb_alpha);
    if (!rgba || *width <= 0 || *height <= 0) return 0;
    count = (size_t)*width * (size_t)*height;
    if (count / (size_t)*width != (size_t)*height || count > pixel_capacity) return 0;
    r4img_memcpy(pixels, rgba, count * 4u * sizeof(uint16_t));
    return 1;
}
