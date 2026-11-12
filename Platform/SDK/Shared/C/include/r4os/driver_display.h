#ifndef R4OS_DRIVER_DISPLAY_H
#define R4OS_DRIVER_DISPLAY_H
#include "r4draw.h"

static inline int r4driver_display_supports_headless_resume(const R4GfxDriverDisplayApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverDisplayApi, resume_headless) + sizeof(uint64_t) &&
        table->resume_headless != 0;
}
static inline int32_t r4driver_display_resume_headless(const R4GfxDriverDisplayApi *table, const R4GfxBackendBinding *backend, uint64_t generation, R4GfxNativeState *output) {
    if (!r4driver_display_supports_headless_resume(table)) return R4OS_ERR_NO_FN;
    if (backend == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((int32_t (*)(const R4GfxBackendBinding *, uint64_t, R4GfxNativeState *))(uintptr_t)table->resume_headless)(backend, generation, output);
}

static inline int r4driver_display_supports_reset(const R4GfxDriverDisplayApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverDisplayApi, prepare_reset) + sizeof(uint64_t) &&
        table->device_reset != 0 && table->prepare_reset != 0;
}
static inline int32_t r4driver_display_device_reset(const R4GfxDriverDisplayApi *table, const R4GfxBackendBinding *backend, uint64_t generation, uint32_t quiesced, R4GfxNativeState *output) {
    if (!r4driver_display_supports_reset(table)) return R4OS_ERR_NO_FN;
    if (backend == 0 || output == 0 || quiesced > 1) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((int32_t (*)(const R4GfxBackendBinding *, uint64_t, uint32_t, R4GfxNativeState *))(uintptr_t)table->device_reset)(backend, generation, quiesced, output);
}
static inline int32_t r4driver_display_prepare_reset(const R4GfxDriverDisplayApi *table, const R4GfxNativeRegistration *input, uint64_t held_generation, uint64_t reset_generation, R4GfxNativeState *output) {
    if (!r4driver_display_supports_reset(table)) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((int32_t (*)(const R4GfxNativeRegistration *, uint64_t, uint64_t, R4GfxNativeState *))(uintptr_t)table->prepare_reset)(input, held_generation, reset_generation, output);
}
static inline int r4driver_display_supports_cursor(const R4GfxDriverDisplayApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverDisplayApi, cursor_complete) + sizeof(uint64_t) &&
        table->cursor_configure != 0 && table->cursor_take != 0 && table->cursor_complete != 0;
}
static inline int32_t r4driver_display_cursor_configure(const R4GfxDriverDisplayApi *table, const R4DisplayCursorInfo *input) {
    if (!r4driver_display_supports_cursor(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4DisplayCursorInfo *);
    return ((Callback)(uintptr_t)table->cursor_configure)(input);
}
static inline int32_t r4driver_display_cursor_take(const R4GfxDriverDisplayApi *table, const R4GfxBackendBinding *backend, R4GfxDriverCursorJob *output) {
    if (!r4driver_display_supports_cursor(table)) return R4OS_ERR_NO_FN;
    if (backend == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    typedef int32_t (*Callback)(const R4GfxBackendBinding *, R4GfxDriverCursorJob *);
    return ((Callback)(uintptr_t)table->cursor_take)(backend, output);
}
static inline int32_t r4driver_display_cursor_complete(const R4GfxDriverDisplayApi *table, const R4GfxDriverCursorCompletion *input) {
    if (!r4driver_display_supports_cursor(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxDriverCursorCompletion *);
    return ((Callback)(uintptr_t)table->cursor_complete)(input);
}

static inline int r4driver_display_supports_presentation_stats(const R4GfxDriverDisplayApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverDisplayApi, presentation_stats) + sizeof(uint64_t) && table->presentation_stats != 0;
}
static inline int r4driver_display_supports_presentation_info(const R4GfxDriverDisplayApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverDisplayApi, presentation_info) + sizeof(uint64_t) && table->presentation_info != 0;
}
static inline int32_t r4driver_display_presentation_info(const R4GfxDriverDisplayApi *table, const R4DisplayPresentationInfo *input) {
    if (!r4driver_display_supports_presentation_info(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4DisplayPresentationInfo *);
    return ((Callback)(uintptr_t)table->presentation_info)(input);
}
static inline int32_t r4driver_display_presentation_stats(const R4GfxDriverDisplayApi *table, const R4DisplayPresentationStats *input) {
    if (!r4driver_display_supports_presentation_stats(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4DisplayPresentationStats *);
    return ((Callback)(uintptr_t)table->presentation_stats)(input);
}

static inline int32_t r4driver_display_boot_hold(const R4GfxDriverDisplayApi *table, const R4GfxBootHoldRequest *input, R4GfxNativeState *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, boot_hold) + sizeof(uint64_t) || table->boot_hold == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBootHoldRequest *, R4GfxNativeState *);
    return ((Callback)(uintptr_t)table->boot_hold)(input, output);
}
static inline int32_t r4driver_display_boot_finish(const R4GfxDriverDisplayApi *table, uint64_t generation, uint32_t operation, R4GfxNativeState *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, boot_finish) + sizeof(uint64_t) || table->boot_finish == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, uint32_t, R4GfxNativeState *);
    return ((Callback)(uintptr_t)table->boot_finish)(generation, operation, output);
}

static inline int32_t r4driver_display_boot_info(const R4GfxDriverDisplayApi *table, R4GfxNativeBootInfo *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, boot_info) + sizeof(uint64_t) || table->boot_info == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(R4GfxNativeBootInfo *);
    return ((Callback)(uintptr_t)table->boot_info)(output);
}
static inline int32_t r4driver_display_prepare_held(const R4GfxDriverDisplayApi *table, const R4GfxNativeRegistration *input, uint64_t generation, R4GfxNativeState *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, prepare_held) + sizeof(uint64_t) || table->prepare_held == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxNativeRegistration *, uint64_t, R4GfxNativeState *);
    return ((Callback)(uintptr_t)table->prepare_held)(input, generation, output);
}
static inline int32_t r4driver_display_prepare(const R4GfxDriverDisplayApi *table, const R4GfxNativeRegistration *input, R4GfxNativeState *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, prepare) + sizeof(uint64_t) || table->prepare == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxNativeRegistration *, R4GfxNativeState *);
    return ((Callback)(uintptr_t)table->prepare)(input, output);
}
static inline int32_t r4driver_display_transition(const R4GfxDriverDisplayApi *table, uint64_t generation, uint32_t operation, R4GfxNativeState *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, transition) + sizeof(uint64_t) || table->transition == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, uint32_t, R4GfxNativeState *);
    return ((Callback)(uintptr_t)table->transition)(generation, operation, output);
}
static inline int32_t r4driver_display_schedule(const R4GfxDriverDisplayApi *table, const R4GfxBackendBinding *input) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverDisplayApi, schedule) + sizeof(uint64_t) || table->schedule == 0) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBackendBinding *);
    return ((Callback)(uintptr_t)table->schedule)(input);
}
#endif
