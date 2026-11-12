#ifndef R4OS_R4DESK_H
#define R4OS_R4DESK_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct R4Desk {
    const R4XStartR4Desk *table;
    const R4OS2Context *generation2;
} R4Desk;

/* Each generation uses its own canonical offsets. The supplied Context2 is
 * borrowed through the actual calls; no legacy table or start is invented. */
static inline int r4desk_available(const R4Desk *value) {
    return value && (value->generation2 ? R4OS2ContextGroup(value->generation2, 2) != NULL : value->table != NULL);
}
static inline int r4desk_reaches(const R4Desk *value, size_t offset1, uint32_t offset2) {
    if (!value) return 0;
    if (value->generation2) {
        const R4XStartR4Desk2 *table = (const R4XStartR4Desk2 *)R4OS2ContextGroup(value->generation2, 2);
        return table && offset2 <= table->size && sizeof(uintptr_t) <= table->size - offset2;
    }
    return value->table && offset1 <= value->table->size && sizeof(uintptr_t) <= value->table->size - offset1;
}
static inline uintptr_t r4desk_callback(const R4Desk *value, size_t offset1, uint32_t offset2) {
    if (!value) return 0;
    if (value->generation2) {
        uint64_t address;
        return R4OS2ContextFunction(value->generation2, 2, offset2, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!r4desk_reaches(value, offset1, offset2)) return 0;
    return *(const uintptr_t *)((const uint8_t *)value->table + offset1);
}
#define R4DESK_REACHES(value, field) r4desk_reaches((value), offsetof(R4XStartR4Desk, field), offsetof(R4XStartR4Desk2, field))
#define R4DESK_SLOT(value, field) r4desk_callback((value), offsetof(R4XStartR4Desk, field), offsetof(R4XStartR4Desk2, field))
#define R4DESK_HAS(value, field) (R4DESK_SLOT((value), field) != 0)
static inline int32_t r4desk_init2(const R4OS2Context *context, R4Desk *out) {
    if (!out || !context || !R4OS2ContextGroup(context, 2)) return R4OS_ERR_NO_GROUP;
    *out = (R4Desk){.table = NULL, .generation2 = context};
    return 0;
}

/* Exact registered Desktop host only. Success0; output unchanged on failure. */
static inline int32_t r4desk_gui_window_appearance(R4Desk *desk, const R4GuiPointerWindowIdentity *window, R4GuiWindowAppearance *out) {
    if (!window || !out) return R4OS_GUI_HOST_INPUT_ERROR_INVALID;
    if (!R4DESK_HAS(desk,gui_window_appearance)) return R4OS_ERR_NO_FN;
    return ((R4DeskGuiWindowAppearanceFn)(uintptr_t)R4DESK_SLOT(desk, gui_window_appearance))(window,out);
}
/* QUERY/POST/RESET return0 on acknowledgement; Busy retains the suffix. */
static inline int32_t r4desk_gui_host_input(R4Desk *desk, const R4GuiHostInputRequest *request, R4GuiPointerWindowIdentity *out) {
    if (!request || !out) return R4OS_GUI_HOST_INPUT_ERROR_INVALID;
    if (!R4DESK_HAS(desk,gui_host_input)) return R4OS_ERR_NO_FN;
    return ((R4DeskGuiHostInputFn)(uintptr_t)R4DESK_SLOT(desk, gui_host_input))(request,out);
}

static inline int32_t r4desk_gui_pointer_capture_info(R4Desk *desk,const R4GuiPointerCaptureHandle *capture,R4GuiPointerCaptureInfo *out){
    if(!out)return R4OS_GUI_POINTER_ERROR_INVALID;
    if(!R4DESK_HAS(desk,gui_pointer_capture_info))return R4OS_ERR_NO_FN;
    return ((R4DeskGuiPointerCaptureInfoFn)(uintptr_t)R4DESK_SLOT(desk, gui_pointer_capture_info))(capture,out);
}
static inline int32_t r4desk_gui_pointer_capture_acquire(R4Desk *desk,const R4GuiPointerWindowIdentity *window,uint32_t mode,R4GuiPointerCaptureHandle *out){
    if(!window||!out)return R4OS_GUI_POINTER_ERROR_INVALID;
    if(!R4DESK_HAS(desk,gui_pointer_capture_acquire))return R4OS_ERR_NO_FN;
    return ((R4DeskGuiPointerCaptureAcquireFn)(uintptr_t)R4DESK_SLOT(desk, gui_pointer_capture_acquire))(window,mode,out);
}
static inline int32_t r4desk_gui_pointer_capture_release(R4Desk *desk,const R4GuiPointerCaptureHandle *capture){
    if(!capture)return R4OS_GUI_POINTER_ERROR_INVALID;
    if(!R4DESK_HAS(desk,gui_pointer_capture_release))return R4OS_ERR_NO_FN;
    return ((R4DeskGuiPointerCaptureReleaseFn)(uintptr_t)R4DESK_SLOT(desk, gui_pointer_capture_release))(capture);
}
static inline int32_t r4desk_gui_pointer_capture_host(R4Desk *desk,const R4GuiPointerHostRequest *request,R4GuiPointerCaptureInfo *out){
    if(!request||!out)return R4OS_GUI_POINTER_ERROR_INVALID;
    if(!R4DESK_HAS(desk,gui_pointer_capture_host))return R4OS_ERR_NO_FN;
    return ((R4DeskGuiPointerCaptureHostFn)(uintptr_t)R4DESK_SLOT(desk, gui_pointer_capture_host))(request,out);
}

static inline int r4desk_import_valid(const R4XStartImport *item) {
    return item != 0 &&
        item->group_id == R4L_GROUP_R4DESK &&
        (item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) != 0 &&
        item->table != 0;
}

static inline int32_t r4desk_init(const R4XStartContext *ctx, R4Desk *out_desk) {
    if (out_desk == 0) return R4OS_ERROR_INVALID;
    out_desk->table = 0;
    out_desk->generation2 = NULL;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4DESK);
    if (item == 0) return R4OS_ERROR_NOT_FOUND;
    if (!r4desk_import_valid(item)) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Desk *table = (const R4XStartR4Desk *)(uintptr_t)item->table;
    if (table->magic != R4XSTART_R4DESK_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4XSTART_R4DESK_VERSION) return R4OS_ERROR_INVALID;
    if (table->size < R4XSTART_R4DESK_SIZE) return R4OS_ERROR_INVALID;
    if (table->program_window_id == 0 || table->gui_poll_event == 0) return R4OS_ERROR_INVALID;
    out_desk->table = table;
    return R4OS_OK;
}

static inline int32_t r4desk_mouse_motion(const R4Desk *desk, R4MouseMotion *output) {
    if (!desk || !r4desk_available(desk) || !R4DESK_REACHES(desk, mouse_motion) || !R4DESK_SLOT(desk, mouse_motion)) return R4OS_ERR_NO_FN;
    if (!output) return R4OS_ERROR_INVALID;
    return ((R4DeskMouseMotionFn)(uintptr_t)R4DESK_SLOT(desk, mouse_motion))(output);
}

static inline uint32_t r4desk_read_key_codepoint(R4Desk *desk) {
    if (!desk || !r4desk_available(desk) ||
        !R4DESK_REACHES(desk, read_key_codepoint) ||
        !R4DESK_SLOT(desk, read_key_codepoint)) return 0;
    return ((R4DeskReadKeyCodepointFn)(uintptr_t)R4DESK_SLOT(desk, read_key_codepoint))();
}

static inline int32_t r4desk_remote_frame_snapshot_acquire(const R4Desk *desk, uint32_t expected, R4RemoteFrameInfo *info, R4RemoteFrameLease *lease) {
    if (!desk || !r4desk_available(desk) || !R4DESK_REACHES(desk, remote_frame_snapshot_acquire) || !R4DESK_SLOT(desk, remote_frame_snapshot_acquire)) return R4OS_ERR_NO_FN;
    if (!info || !lease) return R4OS_ERROR_INVALID;
    return ((R4DeskRemoteFrameSnapshotAcquireFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_snapshot_acquire))(expected, info, lease);
}
static inline int32_t r4desk_remote_frame_snapshot_release(const R4Desk *desk, const R4RemoteFrameLease *lease) {
    if (!desk || !r4desk_available(desk) || !R4DESK_REACHES(desk, remote_frame_snapshot_release) || !R4DESK_SLOT(desk, remote_frame_snapshot_release)) return R4OS_ERR_NO_FN;
    if (!lease) return R4OS_ERROR_INVALID;
    return ((R4DeskRemoteFrameSnapshotReleaseFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_snapshot_release))(lease);
}
static inline int32_t r4desk_remote_frame_source_reset(const R4Desk *desk) {
    if (!desk || !r4desk_available(desk) || !R4DESK_REACHES(desk, remote_frame_source_reset) || !R4DESK_SLOT(desk, remote_frame_source_reset)) return R4OS_ERR_NO_FN;
    return ((R4DeskRemoteFrameSourceResetFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_source_reset))();
}
static inline int32_t r4desk_remote_frame_capture_stats(const R4Desk *desk, R4RemoteFrameCaptureStats *output) {
    if (!desk || !r4desk_available(desk) || !R4DESK_REACHES(desk, remote_frame_capture_stats) || !R4DESK_SLOT(desk, remote_frame_capture_stats)) return R4OS_ERR_NO_FN;
    if (!output) return R4OS_ERROR_INVALID;
    return ((R4DeskRemoteFrameCaptureStatsFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_capture_stats))(output);
}

static inline int32_t r4desk_console_input_wait(R4Desk *desk, uint64_t last_generation, uint64_t timeout_ticks, uint64_t *out_generation) {
    if (out_generation == 0) return R4OS_CONSOLE_INPUT_WAIT_ERROR_INVALID;
    *out_generation = last_generation;
    if (desk == 0 || !r4desk_available(desk) ||
        !R4DESK_REACHES(desk, console_input_wait) ||
        R4DESK_SLOT(desk, console_input_wait) == 0) return R4OS_CONSOLE_INPUT_WAIT_ERROR_UNSUPPORTED;
    R4DeskConsoleInputWaitFn fn = (R4DeskConsoleInputWaitFn)(uintptr_t)R4DESK_SLOT(desk, console_input_wait);
    return fn(last_generation, timeout_ticks, out_generation);
}

static inline int32_t r4desk_physical_key_poll(R4Desk *desk, R4PhysicalKeyEvent *out_event) {
    if (out_event == 0) return R4OS_PHYSICAL_KEY_POLL_ERROR_INVALID;
    *out_event = (R4PhysicalKeyEvent){0};
    if (desk == 0 || !r4desk_available(desk) ||
        !R4DESK_REACHES(desk, physical_key_poll) ||
        R4DESK_SLOT(desk, physical_key_poll) == 0) return R4OS_PHYSICAL_KEY_POLL_ERROR_UNSUPPORTED;
    R4DeskPhysicalKeyPollFn fn = (R4DeskPhysicalKeyPollFn)(uintptr_t)R4DESK_SLOT(desk, physical_key_poll);
    return fn(out_event);
}

static inline int32_t r4desk_program_window_id(R4Desk *desk) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, program_window_id) == 0) return -1;
    R4DeskProgramWindowIdFn fn = (R4DeskProgramWindowIdFn)(uintptr_t)R4DESK_SLOT(desk, program_window_id);
    return fn();
}

static inline int32_t r4desk_program_set_window_handle(R4Desk *desk, const R4ProgramProcessHandle *handle, int32_t window_id) {
    if (desk == 0 || !r4desk_available(desk) || handle == 0 || R4DESK_SLOT(desk, program_set_window_handle) == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    R4DeskProgramSetWindowHandleFn fn = (R4DeskProgramSetWindowHandleFn)(uintptr_t)R4DESK_SLOT(desk, program_set_window_handle);
    return fn(handle, window_id);
}

static inline int32_t r4desk_gui_window_info(R4Desk *desk, R4GuiWindowInfo *out) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, gui_window_info) == 0) return R4OS_ERROR_INVALID;
    R4DeskGuiWindowInfoFn fn = (R4DeskGuiWindowInfoFn)(uintptr_t)R4DESK_SLOT(desk, gui_window_info);
    return fn(out);
}

static inline int32_t r4desk_gui_poll_event(R4Desk *desk, R4GuiEvent *out) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, gui_poll_event) == 0) return 0;
    R4DeskGuiPollEventFn fn = (R4DeskGuiPollEventFn)(uintptr_t)R4DESK_SLOT(desk, gui_poll_event);
    return fn(out);
}

static inline int32_t r4desk_gui_set_title(R4Desk *desk, const char *text) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, gui_set_title) == 0) return R4OS_ERROR_INVALID;
    R4DeskGuiSetTitleFn fn = (R4DeskGuiSetTitleFn)(uintptr_t)R4DESK_SLOT(desk, gui_set_title);
    return fn((const uint8_t *)(const void *)text);
}

static inline int32_t r4desk_gui_set_min_size(R4Desk *desk, int32_t w, int32_t h) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, gui_set_min_size) == 0) return R4OS_ERROR_INVALID;
    R4DeskGuiSetMinSizeFn fn = (R4DeskGuiSetMinSizeFn)(uintptr_t)R4DESK_SLOT(desk, gui_set_min_size);
    return fn(w, h);
}

static inline int32_t r4desk_remote_frame_info(R4Desk *desk, R4RemoteFrameInfo *out) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_frame_info) == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameInfoFn fn = (R4DeskRemoteFrameInfoFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_info);
    return fn(out);
}

static inline int32_t r4desk_remote_frame_read(R4Desk *desk, uint32_t offset_pixels, uint32_t *out, uint32_t pixel_count, R4RemoteFrameInfo *out_info) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_frame_read) == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameReadFn fn = (R4DeskRemoteFrameReadFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_read);
    return fn(offset_pixels, out, pixel_count, out_info);
}

static inline int32_t r4desk_remote_frame_wait(R4Desk *desk, uint32_t last_revision, uint64_t timeout_ticks, R4RemoteFrameInfo *out) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_frame_wait) == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameWaitFn fn = (R4DeskRemoteFrameWaitFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_wait);
    return fn(last_revision, timeout_ticks, out);
}

static inline int32_t r4desk_remote_frame_publish(R4Desk *desk, const R4RemoteFrameInfo *info, const uint32_t *pixels, uint32_t pixel_count) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_frame_publish) == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFramePublishFn fn = (R4DeskRemoteFramePublishFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_publish);
    return fn(info, pixels, pixel_count);
}

static inline int r4desk_supports_remote_frame_regions(const R4Desk *desk) {
    return desk != 0 && r4desk_available(desk) &&
        R4DESK_REACHES(desk, remote_frame_publish_regions) &&
        R4DESK_SLOT(desk, remote_frame_publish_regions) != 0;
}

static inline int32_t r4desk_remote_frame_publish_regions(R4Desk *desk,
                                                           const R4RemoteFrameInfo *info,
                                                           const uint32_t *pixels,
                                                           uint32_t pixel_count,
                                                           const R4DisplayDamageRect *regions,
                                                           uint32_t region_count) {
    if (!r4desk_supports_remote_frame_regions(desk)) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    if (info == 0 || pixels == 0 || pixel_count == 0u || regions == 0 ||
        region_count == 0u || region_count > R4OS_DISPLAY_DAMAGE_MAX_REGIONS) {
        return R4OS_ERROR_INVALID;
    }
    R4DeskRemoteFramePublishRegionsFn fn =
        (R4DeskRemoteFramePublishRegionsFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_publish_regions);
    return fn(info, pixels, pixel_count, regions, region_count);
}

static inline int r4desk_supports_remote_frame_demand(const R4Desk *desk) {
    return desk != 0 && r4desk_available(desk) &&
        R4DESK_REACHES(desk, remote_frame_consumers) &&
        R4DESK_SLOT(desk, remote_frame_acquire) != 0 && R4DESK_SLOT(desk, remote_frame_release) != 0 &&
        R4DESK_SLOT(desk, remote_frame_consumers) != 0;
}

static inline int32_t r4desk_remote_frame_acquire(R4Desk *desk) {
    if (!r4desk_supports_remote_frame_demand(desk)) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameAcquireFn fn = (R4DeskRemoteFrameAcquireFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_acquire);
    return fn();
}

static inline int32_t r4desk_remote_frame_release(R4Desk *desk) {
    if (!r4desk_supports_remote_frame_demand(desk)) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameReleaseFn fn = (R4DeskRemoteFrameReleaseFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_release);
    return fn();
}

static inline uint32_t r4desk_remote_frame_consumers(R4Desk *desk) {
    if (!r4desk_supports_remote_frame_demand(desk)) return 0u;
    R4DeskRemoteFrameConsumersFn fn = (R4DeskRemoteFrameConsumersFn)(uintptr_t)R4DESK_SLOT(desk, remote_frame_consumers);
    return fn();
}

static inline int32_t r4desk_remote_input_push(R4Desk *desk, const R4RemoteInputEvent *event) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_input_push) == 0) return R4_REMOTE_INPUT_ERROR_UNSUPPORTED;
    R4DeskRemoteInputPushFn fn = (R4DeskRemoteInputPushFn)(uintptr_t)R4DESK_SLOT(desk, remote_input_push);
    return fn(event);
}

static inline int32_t r4desk_remote_input_poll(R4Desk *desk, R4RemoteInputEvent *out) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_input_poll) == 0) return R4_REMOTE_INPUT_ERROR_UNSUPPORTED;
    R4DeskRemoteInputPollFn fn = (R4DeskRemoteInputPollFn)(uintptr_t)R4DESK_SLOT(desk, remote_input_poll);
    return fn(out);
}

static inline int32_t r4desk_remote_input_status(R4Desk *desk, R4RemoteInputStatus *out) {
    if (desk == 0 || !r4desk_available(desk) || R4DESK_SLOT(desk, remote_input_status) == 0) return R4_REMOTE_INPUT_ERROR_UNSUPPORTED;
    R4DeskRemoteInputStatusFn fn = (R4DeskRemoteInputStatusFn)(uintptr_t)R4DESK_SLOT(desk, remote_input_status);
    return fn(out);
}

#ifdef __cplusplus
}
#endif

#endif
