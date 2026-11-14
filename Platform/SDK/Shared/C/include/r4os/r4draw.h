#ifndef R4OS_R4DRAW_H
#define R4OS_R4DRAW_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct R4Draw {
    const R4XStartR4Draw2 *table;
    const R4OS2Context *generation2;
} R4Draw;

/* Both current table loans use the same canonical offsets. The supplied Context2 is
 * borrowed through the actual calls; no legacy table or start is invented. */
static inline int r4draw_available(const R4Draw *value) {
    return value && (value->generation2 ? R4OS2ContextGroup(value->generation2, 3) != NULL : (value->table && value->table->magic == R4OS2_R4DRAW_MAGIC && value->table->abi_version >= 1 && value->table->size >= 16));
}
static inline int r4draw_reaches(const R4Draw *value, size_t offset) {
    if (!value || offset > UINT32_MAX) return 0;
    if (value->generation2) {
        const R4XStartR4Draw2 *table = (const R4XStartR4Draw2 *)R4OS2ContextGroup(value->generation2, 3);
        return table && offset <= table->size && sizeof(uintptr_t) <= table->size - offset;
    }
    return (value->table && value->table->magic == R4OS2_R4DRAW_MAGIC && value->table->abi_version >= 1 && value->table->size >= 16) && offset <= value->table->size && sizeof(uintptr_t) <= value->table->size - offset;
}
static inline uintptr_t r4draw_callback(const R4Draw *value, size_t offset) {
    if (!value || offset > UINT32_MAX) return 0;
    if (value->generation2) {
        uint64_t address;
        return R4OS2ContextFunction(value->generation2, 3, offset, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!r4draw_reaches(value, offset)) return 0;
    return *(const uintptr_t *)((const uint8_t *)value->table + offset);
}
#define R4DRAW_REACHES(value, field) r4draw_reaches((value), offsetof(R4XStartR4Draw2, field))
#define R4DRAW_SLOT(value, field) r4draw_callback((value), offsetof(R4XStartR4Draw2, field))
#define R4DRAW_HAS(value, field) (R4DRAW_SLOT((value), field) != 0)
static inline int32_t r4draw_init2(const R4OS2Context *context, R4Draw *out) {
    if (!out || !context || !R4OS2ContextGroup(context, 3)) return R4OS_ERR_NO_GROUP;
    *out = (R4Draw){.table = NULL, .generation2 = context};
    return 0;
}

static inline int r4draw_supports_display_blit_stride(const R4Draw *draw) {
    return draw != 0 && r4draw_available(draw) &&
        R4DRAW_REACHES(draw, display_blit_xrgb32_stride) &&
        R4DRAW_SLOT(draw, display_blit_xrgb32_stride) != 0;
}

static inline int32_t r4draw_display_blit_xrgb32_stride(R4Draw *draw,
                                                         int32_t x, int32_t y,
                                                         uint32_t width, uint32_t height,
                                                         uint32_t source_stride_pixels,
                                                         const uint32_t *pixels,
                                                         uint32_t pixel_count) {
    if (!r4draw_supports_display_blit_stride(draw)) return R4OS_ERR_NO_FN;
    if (pixels == 0 || pixel_count == 0u) return R4OS_ERROR_INVALID;
    R4DrawDisplayBlitXrgb32StrideFn fn = (R4DrawDisplayBlitXrgb32StrideFn)(uintptr_t)R4DRAW_SLOT(draw, display_blit_xrgb32_stride);
    return fn(x, y, width, height, pixels, pixel_count, source_stride_pixels);
}

static inline int r4draw_supports_display_present_regions(const R4Draw *draw) {
    return draw != 0 && r4draw_available(draw) &&
        R4DRAW_REACHES(draw, display_present_completion) &&
        R4DRAW_SLOT(draw, display_present_regions) != 0 &&
        R4DRAW_SLOT(draw, display_present_capabilities) != 0 &&
        R4DRAW_SLOT(draw, display_present_completion) != 0;
}

static inline int32_t r4draw_display_present_regions(R4Draw *draw,
                                                      const R4DisplayPresentRequest *request,
                                                      const uint32_t *pixels,
                                                      uint32_t pixel_count,
                                                      const R4DisplayDamageRect *regions,
                                                      uint32_t region_count,
                                                      R4DisplayPresentResult *out_result) {
    if (!r4draw_supports_display_present_regions(draw)) return R4OS_ERR_NO_FN;
    if (request == 0 || pixels == 0 || pixel_count == 0u || regions == 0 ||
        region_count == 0u || region_count > R4OS_DISPLAY_DAMAGE_MAX_REGIONS || out_result == 0) {
        return R4OS_DISPLAY_PRESENT_ERROR_INVALID;
    }
    R4DrawDisplayPresentRegionsFn fn =
        (R4DrawDisplayPresentRegionsFn)(uintptr_t)R4DRAW_SLOT(draw, display_present_regions);
    return fn(request, pixels, pixel_count, regions, region_count, out_result);
}

static inline int32_t r4draw_display_present_capabilities(R4Draw *draw,
                                                           R4DisplayPresentCapabilities *out_capabilities) {
    if (!r4draw_supports_display_present_regions(draw)) return R4OS_ERR_NO_FN;
    if (out_capabilities == 0) return R4OS_DISPLAY_PRESENT_ERROR_INVALID;
    out_capabilities->version = R4OS_DISPLAY_PRESENT_VERSION;
    out_capabilities->size = (uint16_t)sizeof(*out_capabilities);
    R4DrawDisplayPresentCapabilitiesFn fn =
        (R4DrawDisplayPresentCapabilitiesFn)(uintptr_t)R4DRAW_SLOT(draw, display_present_capabilities);
    return fn(out_capabilities);
}

static inline int32_t r4draw_display_present_completion(R4Draw *draw,
                                                         uint64_t fence,
                                                         R4DisplayPresentCompletion *out_completion) {
    if (!r4draw_supports_display_present_regions(draw)) return R4OS_ERR_NO_FN;
    if (fence == 0u || out_completion == 0) return R4OS_DISPLAY_PRESENT_ERROR_INVALID;
    out_completion->version = R4OS_DISPLAY_PRESENT_VERSION;
    out_completion->size = (uint16_t)sizeof(*out_completion);
    R4DrawDisplayPresentCompletionFn fn =
        (R4DrawDisplayPresentCompletionFn)(uintptr_t)R4DRAW_SLOT(draw, display_present_completion);
    return fn(fence, out_completion);
}

static inline int r4draw_supports_display_presentation_stats(const R4Draw *draw) {
    return draw != 0 && r4draw_available(draw) &&
        R4DRAW_REACHES(draw, display_presentation_stats) &&
        R4DRAW_SLOT(draw, display_presentation_stats) != 0;
}
static inline int r4draw_supports_display_presentation_info(const R4Draw *draw) {
    return draw != 0 && r4draw_available(draw) && R4DRAW_REACHES(draw, display_presentation_info) && R4DRAW_SLOT(draw, display_presentation_info) != 0;
}
static inline int32_t r4draw_display_presentation_info(const R4Draw *draw, uint32_t head_id, R4DisplayPresentationInfo *output) {
    if (!r4draw_supports_display_presentation_info(draw)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawDisplayPresentationInfoFn)(uintptr_t)R4DRAW_SLOT(draw, display_presentation_info))(head_id, output);
}
static inline int32_t r4draw_display_presentation_feedback(const R4Draw *draw, uint32_t head_id, const R4GfxFence *source, R4DisplayPresentationStats *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, display_presentation_feedback) || R4DRAW_SLOT(draw, display_presentation_feedback) == 0) return R4OS_ERR_NO_FN;
    if (source == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawDisplayPresentationFeedbackFn)(uintptr_t)R4DRAW_SLOT(draw, display_presentation_feedback))(head_id, source, output);
}

static inline int r4draw_supports_display_cursor(const R4Draw *draw) {
    return draw != 0 && r4draw_available(draw) && R4DRAW_REACHES(draw, display_cursor_status) &&
        R4DRAW_SLOT(draw, display_cursor_info) != 0 && R4DRAW_SLOT(draw, display_cursor_submit) != 0 && R4DRAW_SLOT(draw, display_cursor_status) != 0;
}
static inline int32_t r4draw_display_cursor_info(const R4Draw *draw, R4DisplayCursorInfo *output) {
    if (!r4draw_supports_display_cursor(draw)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawDisplayCursorInfoFn)(uintptr_t)R4DRAW_SLOT(draw, display_cursor_info))(output);
}
static inline int32_t r4draw_display_cursor_submit(const R4Draw *draw, const R4DisplayCursorRequest *input, R4DisplayCursorStatus *output) {
    if (!r4draw_supports_display_cursor(draw)) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawDisplayCursorSubmitFn)(uintptr_t)R4DRAW_SLOT(draw, display_cursor_submit))(input, output);
}
static inline int32_t r4draw_display_cursor_status(const R4Draw *draw, R4DisplayCursorStatus *output) {
    if (!r4draw_supports_display_cursor(draw)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawDisplayCursorStatusFn)(uintptr_t)R4DRAW_SLOT(draw, display_cursor_status))(output);
}

static inline int32_t r4draw_display_presentation_stats(const R4Draw *draw, uint32_t head_id,
                                                        R4DisplayPresentationStats *output) {
    if (!r4draw_supports_display_presentation_stats(draw)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1u;
    output->size = (uint32_t)sizeof(*output);
    return ((R4DrawDisplayPresentationStatsFn)(uintptr_t)R4DRAW_SLOT(draw, display_presentation_stats))(head_id, output);
}

static inline int r4draw_import_valid(const R4XStartImport *item) {
    return item != 0 &&
        item->group_id == R4L_GROUP_R4DRAW &&
        (item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) != 0 &&
        item->table != 0;
}

static inline int32_t r4draw_init(const R4XStartContext2 *ctx, R4Draw *out_draw) {
    if (out_draw == 0) return R4OS_ERROR_INVALID;
    out_draw->table = 0;
    out_draw->generation2 = NULL;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4DRAW);
    if (item == 0) return R4OS_ERROR_NOT_FOUND;
    if (!r4draw_import_valid(item)) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Draw2 *table = (const R4XStartR4Draw2 *)(uintptr_t)item->table;
    if (table->magic != R4OS2_R4DRAW_MAGIC) return R4OS_ERROR_INVALID;
    /* Optional append-only tails are checked by their individual facades. */
    if (table->abi_version < 1) return R4OS_ERROR_INVALID;
    if (table->size < offsetof(R4XStartR4Draw2, gui_present) + sizeof(uintptr_t)) return R4OS_ERROR_INVALID;
    if (table->gui_clear == 0 || table->gui_rect == 0 || table->gui_present == 0) return R4OS_ERROR_INVALID;
    out_draw->table = table;
    return R4OS_OK;
}

static inline int32_t r4draw_gui_clear(R4Draw *draw, uint32_t rgb) {
    if (draw == 0 || !r4draw_available(draw) || R4DRAW_SLOT(draw, gui_clear) == 0) return R4OS_ERROR_INVALID;
    R4DrawGuiClearFn fn = (R4DrawGuiClearFn)(uintptr_t)R4DRAW_SLOT(draw, gui_clear);
    return fn(rgb);
}

static inline int32_t r4draw_gui_rect(R4Draw *draw, int32_t x, int32_t y, uint32_t w, uint32_t h, uint32_t rgb) {
    if (draw == 0 || !r4draw_available(draw) || R4DRAW_SLOT(draw, gui_rect) == 0) return R4OS_ERROR_INVALID;
    R4DrawGuiRectFn fn = (R4DrawGuiRectFn)(uintptr_t)R4DRAW_SLOT(draw, gui_rect);
    return fn(x, y, w, h, rgb);
}

static inline int32_t r4draw_gui_draw_text(R4Draw *draw, int32_t x, int32_t y, const char *text, uint32_t fg, uint32_t bg) {
    if (draw == 0 || !r4draw_available(draw) || R4DRAW_SLOT(draw, gui_draw_text) == 0) return R4OS_ERROR_INVALID;
    R4DrawGuiDrawTextFn fn = (R4DrawGuiDrawTextFn)(uintptr_t)R4DRAW_SLOT(draw, gui_draw_text);
    return fn(x, y, (const uint8_t *)(const void *)text, fg, bg);
}

static inline int32_t r4draw_gui_blend_alpha8(R4Draw *draw, int32_t x, int32_t y,
                                               uint32_t width, uint32_t height,
                                               uint32_t stride, uint32_t rgb,
                                               const uint8_t *alpha, size_t alpha_len) {
    if (draw == 0 || !r4draw_available(draw) ||
        !R4DRAW_REACHES(draw, gui_blend_alpha8) ||
        R4DRAW_SLOT(draw, gui_blend_alpha8) == 0) return R4OS_ERR_NO_FN;
    if (alpha == 0 || alpha_len == 0u || alpha_len > UINT32_MAX) return R4OS_ERROR_INVALID;
    R4DrawGuiBlendAlpha8Fn fn = (R4DrawGuiBlendAlpha8Fn)(uintptr_t)R4DRAW_SLOT(draw, gui_blend_alpha8);
    return fn(x, y, width, height, stride, rgb, alpha, (uint32_t)alpha_len);
}

static inline int r4draw_supports_gui_frame_contract(const R4Draw *draw) {
    if (draw == 0 || !r4draw_available(draw)) return 0;
    return R4DRAW_REACHES(draw, gui_frame_read) &&
        R4DRAW_SLOT(draw, gui_frame_begin) != 0 && R4DRAW_SLOT(draw, gui_frame_append) != 0 &&
        R4DRAW_SLOT(draw, gui_frame_commit) != 0 && R4DRAW_SLOT(draw, gui_frame_cancel) != 0 &&
        R4DRAW_SLOT(draw, gui_frame_info) != 0 && R4DRAW_SLOT(draw, gui_frame_read) != 0;
}

static inline int r4draw_supports_gui_frame_damage_contract(const R4Draw *draw) {
    if (!r4draw_supports_gui_frame_contract(draw)) return 0;
    return R4DRAW_REACHES(draw, gui_frame_generation_read) &&
        R4DRAW_SLOT(draw, gui_frame_begin_damage) != 0 && R4DRAW_SLOT(draw, gui_frame_generation_info) != 0 &&
        R4DRAW_SLOT(draw, gui_frame_generation_read) != 0;
}

static inline int r4draw_supports_gui_frame_streaming_contract(const R4Draw *draw) {
    if (!r4draw_supports_gui_frame_damage_contract(draw)) return 0;
    return R4DRAW_REACHES(draw, gui_frame_stream_info) &&
        R4DRAW_SLOT(draw, gui_frame_begin_replace) != 0 && R4DRAW_SLOT(draw, gui_frame_stream_info) != 0;
}

static inline int32_t r4draw_gui_frame_begin(R4Draw *draw) {
    if (draw == 0 || !r4draw_supports_gui_frame_contract(draw)) return R4OS_ERR_NO_FN;
    R4DrawGuiFrameBeginFn fn = (R4DrawGuiFrameBeginFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_begin);
    return fn();
}

static inline int32_t r4draw_gui_frame_begin_damage(R4Draw *draw,
                                                     const R4DisplayDamageRect *regions,
                                                     uint32_t region_count) {
    if (draw == 0 || !r4draw_supports_gui_frame_damage_contract(draw)) return R4OS_ERR_NO_FN;
    if (regions == 0 || region_count == 0u || region_count > R4OS_GUI_FRAME_MAX_DAMAGE_REGIONS) {
        return R4OS_GUI_FRAME_ERROR_INVALID;
    }
    R4DrawGuiFrameBeginDamageFn fn = (R4DrawGuiFrameBeginDamageFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_begin_damage);
    return fn(regions, region_count);
}

static inline int32_t r4draw_gui_frame_begin_replace(R4Draw *draw,
                                                      const R4DisplayDamageRect *regions,
                                                      uint32_t region_count) {
    if (draw == 0 || !r4draw_supports_gui_frame_streaming_contract(draw)) return R4OS_ERR_NO_FN;
    if (regions == 0 || region_count == 0u || region_count > R4OS_GUI_FRAME_MAX_DAMAGE_REGIONS) {
        return R4OS_GUI_FRAME_ERROR_INVALID;
    }
    R4DrawGuiFrameBeginReplaceFn fn = (R4DrawGuiFrameBeginReplaceFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_begin_replace);
    return fn(regions, region_count);
}

static inline int32_t r4draw_gui_frame_append(R4Draw *draw,
                                               const R4GuiFrameCommand *commands, uint64_t command_count,
                                               const uint8_t *resources, uint64_t resource_len) {
    if (draw == 0 || !r4draw_supports_gui_frame_contract(draw)) return R4OS_ERR_NO_FN;
    R4DrawGuiFrameAppendFn fn = (R4DrawGuiFrameAppendFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_append);
    return fn(commands, command_count, resources, resource_len);
}

static inline int32_t r4draw_gui_frame_commit(R4Draw *draw) {
    if (draw == 0 || !r4draw_supports_gui_frame_contract(draw)) return R4OS_ERR_NO_FN;
    R4DrawGuiFrameCommitFn fn = (R4DrawGuiFrameCommitFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_commit);
    return fn();
}

static inline int32_t r4draw_gui_frame_cancel(R4Draw *draw) {
    if (draw == 0 || !r4draw_supports_gui_frame_contract(draw)) return R4OS_ERR_NO_FN;
    R4DrawGuiFrameCancelFn fn = (R4DrawGuiFrameCancelFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_cancel);
    return fn();
}

static inline int32_t r4draw_gui_frame_info(R4Draw *draw, const R4ProgramProcessHandle *handle, R4GuiFrameInfo *out_info) {
    if (draw == 0 || !r4draw_supports_gui_frame_contract(draw)) return R4OS_ERR_NO_FN;
    if (out_info == 0) return R4OS_GUI_FRAME_ERROR_INVALID;
    R4DrawGuiFrameInfoFn fn = (R4DrawGuiFrameInfoFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_info);
    out_info->version = R4OS_GUI_FRAME_INFO_VERSION;
    out_info->size = R4OS_GUI_FRAME_INFO_SIZE;
    return fn(handle, out_info);
}

static inline int32_t r4draw_gui_frame_read(R4Draw *draw, const R4ProgramProcessHandle *handle,
                                             uint64_t expected_generation,
                                             R4GuiFrameCommand *commands, uint64_t command_capacity,
                                             uint8_t *resources, uint64_t resource_capacity,
                                             R4GuiFrameInfo *out_info) {
    if (draw == 0 || !r4draw_supports_gui_frame_contract(draw)) return R4OS_ERR_NO_FN;
    if (out_info == 0) return R4OS_GUI_FRAME_ERROR_INVALID;
    out_info->version = R4OS_GUI_FRAME_INFO_VERSION;
    out_info->size = R4OS_GUI_FRAME_INFO_SIZE;
    if (handle == 0) return R4OS_GUI_FRAME_ERROR_INVALID;
    R4DrawGuiFrameReadFn fn = (R4DrawGuiFrameReadFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_read);
    return fn(handle, expected_generation, commands, command_capacity, resources, resource_capacity, out_info);
}

static inline int32_t r4draw_gui_frame_generation_info(R4Draw *draw,
                                                        const R4ProgramProcessHandle *handle,
                                                        uint64_t generation,
                                                        R4GuiFrameGenerationInfo *out_info) {
    if (draw == 0 || !r4draw_supports_gui_frame_damage_contract(draw)) return R4OS_ERR_NO_FN;
    if (handle == 0 || generation == 0u || out_info == 0) return R4OS_GUI_FRAME_ERROR_INVALID;
    out_info->version = R4OS_GUI_FRAME_GENERATION_INFO_VERSION;
    out_info->size = R4OS_GUI_FRAME_GENERATION_INFO_SIZE;
    R4DrawGuiFrameGenerationInfoFn fn = (R4DrawGuiFrameGenerationInfoFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_generation_info);
    return fn(handle, generation, out_info);
}

static inline int32_t r4draw_gui_frame_generation_read(R4Draw *draw,
                                                        const R4ProgramProcessHandle *handle,
                                                        uint64_t generation,
                                                        R4GuiFrameCommand *commands,
                                                        uint64_t command_capacity,
                                                        uint8_t *resources,
                                                        uint64_t resource_capacity,
                                                        R4DisplayDamageRect *regions,
                                                        uint32_t region_capacity,
                                                        R4GuiFrameGenerationInfo *out_info) {
    if (draw == 0 || !r4draw_supports_gui_frame_damage_contract(draw)) return R4OS_ERR_NO_FN;
    if (handle == 0 || generation == 0u || out_info == 0 ||
        (commands == 0 && command_capacity != 0u) || (resources == 0 && resource_capacity != 0u) ||
        (regions == 0 && region_capacity != 0u)) return R4OS_GUI_FRAME_ERROR_INVALID;
    out_info->version = R4OS_GUI_FRAME_GENERATION_INFO_VERSION;
    out_info->size = R4OS_GUI_FRAME_GENERATION_INFO_SIZE;
    R4DrawGuiFrameGenerationReadFn fn = (R4DrawGuiFrameGenerationReadFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_generation_read);
    return fn(handle, generation, commands, command_capacity, resources, resource_capacity, regions, region_capacity, out_info);
}

static inline int32_t r4draw_gui_frame_stream_info(R4Draw *draw,
                                                    const R4ProgramProcessHandle *handle,
                                                    R4GuiFrameStreamInfo *out_info) {
    if (draw == 0 || !r4draw_supports_gui_frame_streaming_contract(draw)) return R4OS_ERR_NO_FN;
    if (handle == 0 || out_info == 0) return R4OS_GUI_FRAME_ERROR_INVALID;
    out_info->version = R4OS_GUI_FRAME_STREAM_INFO_VERSION;
    out_info->size = R4OS_GUI_FRAME_STREAM_INFO_SIZE;
    R4DrawGuiFrameStreamInfoFn fn = (R4DrawGuiFrameStreamInfoFn)(uintptr_t)R4DRAW_SLOT(draw, gui_frame_stream_info);
    return fn(handle, out_info);
}

static inline int32_t r4draw_gui_present(R4Draw *draw) {
    if (draw == 0 || !r4draw_available(draw) || R4DRAW_SLOT(draw, gui_present) == 0) return R4OS_ERROR_INVALID;
    R4DrawGuiPresentFn fn = (R4DrawGuiPresentFn)(uintptr_t)R4DRAW_SLOT(draw, gui_present);
    return fn();
}


/* Generation-bound graphics buffers. Check each optional tail independently. */
static inline int32_t r4draw_gfx_virtual_start(const R4Draw *draw, const R4GfxVirtualRequest * input, R4GfxVirtualStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_virtual_start) || R4DRAW_SLOT(draw, gfx_virtual_start) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxVirtualStartFn callback = (R4DrawGfxVirtualStartFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_virtual_start);
    R4GfxVirtualStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(input, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_virtual_query(const R4Draw *draw, const R4GfxBufferHandle * request, R4GfxVirtualStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_virtual_query) || R4DRAW_SLOT(draw, gfx_virtual_query) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxVirtualQueryFn callback = (R4DrawGfxVirtualQueryFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_virtual_query);
    R4GfxVirtualStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(request, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_virtual_close(const R4Draw *draw, const R4GfxBufferHandle * request, uint32_t mode) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_virtual_close) || R4DRAW_SLOT(draw, gfx_virtual_close) == 0) return R4OS_ERR_NO_FN;
    if (request == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxVirtualCloseFn callback = (R4DrawGfxVirtualCloseFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_virtual_close);
    return callback(request, mode);
}

static inline int32_t r4draw_gfx_virtual_wait(const R4Draw *draw, const R4GfxBufferHandle * request, uint32_t until, uint64_t timeout_ticks, R4GfxVirtualStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_virtual_wait) || R4DRAW_SLOT(draw, gfx_virtual_wait) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxVirtualWaitFn callback = (R4DrawGfxVirtualWaitFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_virtual_wait);
    R4GfxVirtualStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(request, until, timeout_ticks, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_native_start(const R4Draw *draw, const R4GfxNativeAllocation * input, R4GfxNativeStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_native_start) || R4DRAW_SLOT(draw, gfx_native_start) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxNativeStartFn callback = (R4DrawGfxNativeStartFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_native_start);
    R4GfxNativeStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(input, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_native_query(const R4Draw *draw, const R4GfxBufferHandle * request, R4GfxNativeStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_native_query) || R4DRAW_SLOT(draw, gfx_native_query) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxNativeQueryFn callback = (R4DrawGfxNativeQueryFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_native_query);
    R4GfxNativeStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(request, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_native_receive(const R4Draw *draw, const R4GfxBufferHandle * request, R4GfxBufferReference * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_native_receive) || R4DRAW_SLOT(draw, gfx_native_receive) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxNativeReceiveFn callback = (R4DrawGfxNativeReceiveFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_native_receive);
    R4GfxBufferReference temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(request, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_native_close(const R4Draw *draw, const R4GfxBufferHandle * request) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_native_close) || R4DRAW_SLOT(draw, gfx_native_close) == 0) return R4OS_ERR_NO_FN;
    if (request == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxNativeCloseFn callback = (R4DrawGfxNativeCloseFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_native_close);
    return callback(request);
}

static inline int32_t r4draw_gfx_native_wait(const R4Draw *draw, const R4GfxBufferHandle * request, uint64_t timeout_ticks, R4GfxNativeStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_native_wait) || R4DRAW_SLOT(draw, gfx_native_wait) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4DrawGfxNativeWaitFn callback = (R4DrawGfxNativeWaitFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_native_wait);
    R4GfxNativeStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = callback(request, timeout_ticks, &temporary);
    if (rc == 1) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_buffer_create(const R4Draw *draw, const R4GfxBufferDescriptor * descriptor, R4GfxBufferReference * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_create) || R4DRAW_SLOT(draw, gfx_buffer_create) == 0) return R4OS_ERR_NO_FN;
    if (descriptor == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxBufferReference);
    return ((R4DrawGfxBufferCreateFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_create))(descriptor, output);
}

static inline int32_t r4draw_gfx_buffer_describe(const R4Draw *draw, const R4GfxBufferHandle * reference, R4GfxBufferDescriptor * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_describe) || R4DRAW_SLOT(draw, gfx_buffer_describe) == 0) return R4OS_ERR_NO_FN;
    if (reference == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxBufferDescriptor);
    return ((R4DrawGfxBufferDescribeFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_describe))(reference, output);
}

static inline int32_t r4draw_gfx_buffer_import(const R4Draw *draw, const R4GfxBufferHandle * source_reference, R4GfxBufferReference * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_import) || R4DRAW_SLOT(draw, gfx_buffer_import) == 0) return R4OS_ERR_NO_FN;
    if (source_reference == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxBufferReference);
    return ((R4DrawGfxBufferImportFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_import))(source_reference, output);
}

static inline int32_t r4draw_gfx_buffer_release(const R4Draw *draw, const R4GfxBufferHandle * reference) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_release) || R4DRAW_SLOT(draw, gfx_buffer_release) == 0) return R4OS_ERR_NO_FN;
    if (reference == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    return ((R4DrawGfxBufferReleaseFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_release))(reference);
}

static inline int32_t r4draw_gfx_buffer_map(const R4Draw *draw, const R4GfxBufferHandle * reference, uint32_t access, uint64_t offset, uint64_t byte_length, R4GfxBufferMap * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_map) || R4DRAW_SLOT(draw, gfx_buffer_map) == 0) return R4OS_ERR_NO_FN;
    if (reference == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxBufferMap);
    return ((R4DrawGfxBufferMapFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_map))(reference, access, offset, byte_length, output);
}

static inline int32_t r4draw_gfx_buffer_unmap(const R4Draw *draw, const R4GfxBufferHandle * lease) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_unmap) || R4DRAW_SLOT(draw, gfx_buffer_unmap) == 0) return R4OS_ERR_NO_FN;
    if (lease == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    return ((R4DrawGfxBufferUnmapFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_unmap))(lease);
}

static inline int32_t r4draw_gfx_buffer_map_persistent(const R4Draw *draw, const R4GfxBufferHandle *reference, uint32_t access, uint64_t offset, uint64_t byte_length, R4GfxBufferMap *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_map_persistent) || R4DRAW_SLOT(draw, gfx_buffer_map_persistent) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4GfxBufferMap temporary = { .version = 1, .size = sizeof(temporary) };
    int32_t rc = ((R4DrawGfxBufferMapPersistentFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_map_persistent))(reference, access, offset, byte_length, &temporary);
    if (rc == R4OS_GFX_BUFFER_RESULT_OK) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_buffer_export_raster(const R4Draw *draw, const R4GuiSharedRasterLease * lease, R4GfxBufferReference * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_export_raster) || R4DRAW_SLOT(draw, gfx_buffer_export_raster) == 0) return R4OS_ERR_NO_FN;
    if (lease == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxBufferReference);
    return ((R4DrawGfxBufferExportRasterFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_export_raster))(lease, output);
}

static inline int32_t r4draw_gfx_telemetry(const R4Draw *draw, const R4GfxTelemetryRequest *input, R4GfxTelemetryState *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_telemetry) || R4DRAW_SLOT(draw, gfx_telemetry) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4GfxTelemetryState temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = ((R4DrawGfxTelemetryFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_telemetry))(input, &temporary);
    if (rc == R4OS_GFX_BUFFER_RESULT_OK) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_memory_budget(const R4Draw *draw, const R4GfxDeviceBudgetRequest *input, R4GfxDeviceBudgetState *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_memory_budget) || R4DRAW_SLOT(draw, gfx_memory_budget) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4GfxDeviceBudgetState temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = ((R4DrawGfxMemoryBudgetFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_memory_budget))(input, &temporary);
    if (rc == R4OS_GFX_BUFFER_RESULT_OK) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_buffer_stats(const R4Draw *draw, R4GfxBufferStats * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_buffer_stats) || R4DRAW_SLOT(draw, gfx_buffer_stats) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_BUFFER_ERROR_INVALID;
    R4GfxBufferStats value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxBufferStatsFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_buffer_stats))(&value);
    if (code == R4OS_GFX_BUFFER_RESULT_OK) {
        if (value.version != 1 || value.size < sizeof(value)) return R4OS_GFX_BUFFER_ERROR_INVALID;
        *output = value;
    }
    return code;
}


/* Asynchronous graphics queues and exact fences. Check each optional tail independently. */
static inline int32_t r4draw_gfx_output_revision(const R4Draw *draw, R4GfxDisplayRevision * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_revision) || R4DRAW_SLOT(draw, gfx_output_revision) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxOutputRevisionFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_revision))(output);
}
static inline int32_t r4draw_gfx_output_info(const R4Draw *draw, uint32_t index, R4GfxOutputInfo * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_info) || R4DRAW_SLOT(draw, gfx_output_info) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxOutputInfoFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_info))(index, output);
}
static inline int32_t r4draw_gfx_output_mode(const R4Draw *draw, const R4GfxOutputId * identity, uint32_t index, R4GfxOutputMode * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_mode) || R4DRAW_SLOT(draw, gfx_output_mode) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxOutputModeFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_mode))(identity, index, output);
}
static inline int32_t r4draw_gfx_output_edid(const R4Draw *draw, const R4GfxOutputId * identity, uint32_t index, R4GfxEdidBlock * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_edid) || R4DRAW_SLOT(draw, gfx_output_edid) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxOutputEdidFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_edid))(identity, index, output);
}
static inline int32_t r4draw_gfx_output_color(const R4Draw *draw, const R4GfxOutputId *identity, R4GfxOutputColorState *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_color) || R4DRAW_SLOT(draw, gfx_output_color) == 0) return R4OS_ERR_NO_FN;
    if (identity == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxOutputColorState value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxOutputColorFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_color))(identity, &value);
    if (code == R4OS_GFX_OUTPUT_OK) {
        if (value.version != 1 || value.size < sizeof(value)) return R4OS_GFX_OUTPUT_ERROR_INVALID;
        *output = value;
    }
    return code;
}
static inline int32_t r4draw_gfx_output_power(const R4Draw *draw, const R4GfxOutputId *identity, R4GfxOutputPower *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_power) || R4DRAW_SLOT(draw, gfx_output_power) == 0) return R4OS_ERR_NO_FN;
    if (identity == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxOutputPower value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxOutputPowerFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_power))(identity, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int32_t r4draw_gfx_power_request(const R4Draw *draw, const R4GfxPowerRequest *input, R4GfxPowerRequest *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_power_request) || R4DRAW_SLOT(draw, gfx_power_request) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxPowerRequest value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxPowerRequestFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_power_request))(input, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int32_t r4draw_gfx_output_brightness(const R4Draw *draw, const R4GfxOutputId *identity, R4GfxOutputBrightness *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_brightness) || R4DRAW_SLOT(draw, gfx_output_brightness) == 0) return R4OS_ERR_NO_FN;
    if (identity == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxOutputBrightness value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxOutputBrightnessFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_brightness))(identity, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int32_t r4draw_gfx_brightness_request(const R4Draw *draw, const R4GfxBrightnessRequest *input, R4GfxBrightnessRequest *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_brightness_request) || R4DRAW_SLOT(draw, gfx_brightness_request) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxBrightnessRequest value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxBrightnessRequestFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_brightness_request))(input, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int32_t r4draw_gfx_output_refresh(const R4Draw *draw, const R4GfxOutputTarget *target, R4GfxOutputRefresh *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_output_refresh) || R4DRAW_SLOT(draw, gfx_output_refresh) == 0) return R4OS_ERR_NO_FN;
    if (target == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxOutputRefresh value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxOutputRefreshFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_output_refresh))(target, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int32_t r4draw_gfx_refresh_request(const R4Draw *draw, const R4GfxRefreshRequest *input, R4GfxRefreshRequest *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_refresh_request) || R4DRAW_SLOT(draw, gfx_refresh_request) == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    R4GfxRefreshRequest value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((R4DrawGfxRefreshRequestFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_refresh_request))(input, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int32_t r4draw_gfx_atomic_test(const R4Draw *draw, const R4GfxAtomicState * state, R4GfxAtomicResult * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_test) || R4DRAW_SLOT(draw, gfx_atomic_test) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicTestFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_test))(state, output);
}
static inline int32_t r4draw_gfx_atomic_test_color(const R4Draw *draw, const R4GfxModeColorRequest *request, R4GfxAtomicResult *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_test_color) || R4DRAW_SLOT(draw, gfx_atomic_test_color) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicTestColorFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_test_color))(request, output);
}
static inline int32_t r4draw_gfx_atomic_submit_color(const R4Draw *draw, const R4GfxModeColorRequest *request, uint32_t confirmation_ms, R4GfxModeStatus *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_submit_color) || R4DRAW_SLOT(draw, gfx_atomic_submit_color) == 0) return R4OS_ERR_NO_FN;
    if (request == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicSubmitColorFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_submit_color))(request, confirmation_ms, output);
}
static inline int32_t r4draw_gfx_atomic_commit(const R4Draw *draw, const R4GfxAtomicState * state, R4GfxAtomicResult * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_commit) || R4DRAW_SLOT(draw, gfx_atomic_commit) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicCommitFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_commit))(state, output);
}
static inline int32_t r4draw_gfx_atomic_submit(const R4Draw *draw, const R4GfxAtomicState *state, uint32_t confirmation_ms, R4GfxModeStatus *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_submit) || R4DRAW_SLOT(draw, gfx_atomic_submit) == 0) return R4OS_ERR_NO_FN;
    if (state == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicSubmitFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_submit))(state, confirmation_ms, output);
}
static inline int32_t r4draw_gfx_atomic_status(const R4Draw *draw, uint64_t ticket, R4GfxModeStatus *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_status) || R4DRAW_SLOT(draw, gfx_atomic_status) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicStatusFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_status))(ticket, output);
}
static inline int32_t r4draw_gfx_atomic_resolve(const R4Draw *draw, uint64_t ticket, uint32_t action, R4GfxModeStatus *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_atomic_resolve) || R4DRAW_SLOT(draw, gfx_atomic_resolve) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxAtomicResolveFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_atomic_resolve))(ticket, action, output);
}

static inline int32_t r4draw_gfx_queue_open(const R4Draw *draw, const R4GfxQueueConfig * config, R4GfxQueueHandle * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_open) || R4DRAW_SLOT(draw, gfx_queue_open) == 0) return R4OS_ERR_NO_FN;
    if (config == 0 || output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxQueueHandle);
    return ((R4DrawGfxQueueOpenFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_open))(config, output);
}

static inline int32_t r4draw_gfx_queue_backend(const R4Draw *draw, uint32_t index, R4GfxBackendBinding *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_backend) || R4DRAW_SLOT(draw, gfx_queue_backend) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxQueueBackendFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_backend))(index, output);
}

static inline int32_t r4draw_gfx_queue_backend_info(const R4Draw *draw, uint32_t index, R4GfxBackendInfo *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_backend_info) || R4DRAW_SLOT(draw, gfx_queue_backend_info) == 0) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxQueueBackendInfoFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_backend_info))(index, output);
}

static inline int32_t r4draw_gfx_queue_backend_properties(const R4Draw *draw, const R4GfxBackendBinding *binding, R4GfxBackendProperties *output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_backend_properties) || R4DRAW_SLOT(draw, gfx_queue_backend_properties) == 0) return R4OS_ERR_NO_FN;
    if (binding == 0 || output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    R4GfxBackendProperties result = { .version = 1, .size = sizeof(result) };
    int32_t code = ((R4DrawGfxQueueBackendPropertiesFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_backend_properties))(binding, &result);
    if (code == 1) *output = result;
    return code;
}

static inline int32_t r4draw_gfx_queue_close(const R4Draw *draw, const R4GfxQueueHandle * queue) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_close) || R4DRAW_SLOT(draw, gfx_queue_close) == 0) return R4OS_ERR_NO_FN;
    if (queue == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    return ((R4DrawGfxQueueCloseFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_close))(queue);
}

static inline int32_t r4draw_gfx_queue_submit(const R4Draw *draw, const R4GfxQueueHandle * queue, const R4GfxSubmission * submission, R4GfxFenceStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_submit) || R4DRAW_SLOT(draw, gfx_queue_submit) == 0) return R4OS_ERR_NO_FN;
    if (queue == 0 || submission == 0 || output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxFenceStatus);
    return ((R4DrawGfxQueueSubmitFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_submit))(queue, submission, output);
}

static inline int32_t r4draw_gfx_queue_submit_native(const R4Draw *draw, const R4GfxQueueHandle *queue, const R4GfxSubmission *submission, const R4GfxNativeSubmission *native, R4GfxFenceStatus *output) {
    if (!draw || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_submit_native) || !R4DRAW_SLOT(draw, gfx_queue_submit_native)) return R4OS_ERR_NO_FN;
    if (!queue || !submission || !native || !output) return R4OS_GFX_QUEUE_ERROR_INVALID;
    R4GfxFenceStatus temporary = {0};
    temporary.version = 1; temporary.size = sizeof(temporary);
    int32_t rc = ((R4DrawGfxQueueSubmitNativeFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_submit_native))(queue, submission, native, &temporary);
    if (rc == R4OS_GFX_QUEUE_OK) *output = temporary;
    return rc;
}

static inline int32_t r4draw_gfx_queue_submit_render_list(const R4Draw *draw, const R4GfxQueueHandle *queue, const R4GfxSubmission *submission, const R4GfxRenderList *list, R4GfxFenceStatus *output) {
    if (!draw || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_submit_render_list) || !R4DRAW_SLOT(draw, gfx_queue_submit_render_list)) return R4OS_ERR_NO_FN;
    if (!queue || !submission || !list || !output) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxQueueSubmitRenderListFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_submit_render_list))(queue, submission, list, output);
}
static inline int32_t r4draw_gfx_queue_submit_render_grid_list(const R4Draw *draw, const R4GfxQueueHandle *queue, const R4GfxSubmission *submission, const R4GfxRenderGridList *list, R4GfxFenceStatus *output) {
    if (!draw || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_submit_render_grid_list) || !R4DRAW_SLOT(draw, gfx_queue_submit_render_grid_list)) return R4OS_ERR_NO_FN;
    if (!queue || !submission || !list || !output) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxQueueSubmitRenderGridListFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_submit_render_grid_list))(queue, submission, list, output);
}
static inline int32_t r4draw_gfx_queue_submit_render_color_list(const R4Draw *draw, const R4GfxQueueHandle *queue, const R4GfxSubmission *submission, const R4GfxRenderColorList *list, R4GfxFenceStatus *output) {
    if (!draw || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_queue_submit_render_color_list) || !R4DRAW_SLOT(draw, gfx_queue_submit_render_color_list)) return R4OS_ERR_NO_FN;
    if (!queue || !submission || !list || !output) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(*output);
    return ((R4DrawGfxQueueSubmitRenderColorListFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_queue_submit_render_color_list))(queue, submission, list, output);
}

static inline int32_t r4draw_gfx_fence_query(const R4Draw *draw, const R4GfxFence * fence, R4GfxFenceStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_fence_query) || R4DRAW_SLOT(draw, gfx_fence_query) == 0) return R4OS_ERR_NO_FN;
    if (fence == 0 || output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxFenceStatus);
    return ((R4DrawGfxFenceQueryFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_fence_query))(fence, output);
}

static inline int32_t r4draw_gfx_fence_wait(const R4Draw *draw, const R4GfxFence * fence, uint64_t timeout_ticks, uint32_t wait_for, R4GfxFenceStatus * output) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_fence_wait) || R4DRAW_SLOT(draw, gfx_fence_wait) == 0) return R4OS_ERR_NO_FN;
    if (fence == 0 || output == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    output->version = 1; output->size = sizeof(R4GfxFenceStatus);
    return ((R4DrawGfxFenceWaitFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_fence_wait))(fence, timeout_ticks, wait_for, output);
}

static inline int32_t r4draw_gfx_fence_cancel(const R4Draw *draw, const R4GfxFence * fence) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_fence_cancel) || R4DRAW_SLOT(draw, gfx_fence_cancel) == 0) return R4OS_ERR_NO_FN;
    if (fence == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    return ((R4DrawGfxFenceCancelFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_fence_cancel))(fence);
}

static inline int32_t r4draw_gfx_fence_release(const R4Draw *draw, const R4GfxFence * fence) {
    if (draw == 0 || !r4draw_available(draw) || !R4DRAW_REACHES(draw, gfx_fence_release) || R4DRAW_SLOT(draw, gfx_fence_release) == 0) return R4OS_ERR_NO_FN;
    if (fence == 0) return R4OS_GFX_QUEUE_ERROR_INVALID;
    return ((R4DrawGfxFenceReleaseFn)(uintptr_t)R4DRAW_SLOT(draw, gfx_fence_release))(fence);
}

#ifdef __cplusplus
}
#endif

#endif
