#include <stddef.h>
#include <stdint.h>
#include <r4os/app2.h>
#include <r4font.h>

static uint8_t font_arena[256u * 1024u];
static size_t font_arena_used;

static void *font_alloc(void *user, size_t size, size_t alignment) {
    size_t start;
    (void)user;
    if (alignment == 0u || (alignment & (alignment - 1u)) != 0u) return 0;
    start = (font_arena_used + alignment - 1u) & ~(alignment - 1u);
    if (start > sizeof(font_arena) || size > sizeof(font_arena) - start) return 0;
    font_arena_used = start + size;
    return font_arena + start;
}

static void *font_realloc(void *user, void *block, size_t old_size,
                          size_t new_size, size_t alignment) {
    uint8_t *replacement = (uint8_t *)font_alloc(user, new_size, alignment);
    size_t index;
    if (!replacement) return 0;
    for (index = 0; block && index < old_size && index < new_size; ++index)
        replacement[index] = ((const uint8_t *)block)[index];
    return replacement;
}

static void font_free(void *user, void *block, size_t size, size_t alignment) {
    (void)user;
    (void)block;
    (void)size;
    (void)alignment;
}

int32_t r4_app_main(R4App2 *app) {
    static const uint8_t font_probe[] = { 0x00, 0x01, 0x00, 0x00 };
    R4FontApiV1Client fonts;
    R4FontAllocator allocator = {
        0,
        (uint64_t)(uintptr_t)font_alloc,
        (uint64_t)(uintptr_t)font_realloc,
        (uint64_t)(uintptr_t)font_free
    };
    uint32_t format = R4FONT_FORMAT_UNKNOWN;
    uint64_t decoder = 0;

    if (r4font_api_v1_init2(app->context.raw, &fonts) != R4L_BINDING_OK) return 41;
    if (r4font_sniff(&fonts, font_probe, sizeof(font_probe), &format) != R4FONT_STATUS_OK) return 42;
    if (format != R4FONT_FORMAT_TTF) return 43;
    if (r4font_decoder_create(&fonts, &allocator, sizeof(font_arena), &decoder) == R4FONT_STATUS_OK)
        (void)r4font_decoder_destroy(&fonts, decoder);
    return 0;
}
