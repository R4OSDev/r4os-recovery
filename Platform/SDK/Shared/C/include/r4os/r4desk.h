#ifndef R4OS_R4DESK_H
#define R4OS_R4DESK_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct R4Desk {
    const R4XStartR4Desk *table;
} R4Desk;

static inline int r4desk_import_valid(const R4XStartImport *item) {
    return item != 0 &&
        item->group_id == R4L_GROUP_R4DESK &&
        (item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) != 0 &&
        item->table != 0;
}

static inline int32_t r4desk_init(const R4XStartContext *ctx, R4Desk *out_desk) {
    if (out_desk == 0) return R4OS_ERROR_INVALID;
    out_desk->table = 0;
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

static inline uint32_t r4desk_read_key_codepoint(R4Desk *desk) {
    if (desk == 0 || desk->table == 0) return 0;
    if (desk->table->read_key_codepoint != 0) {
        R4DeskReadKeyCodepointFn fn = (R4DeskReadKeyCodepointFn)(uintptr_t)desk->table->read_key_codepoint;
        return fn();
    }
    if (desk->table->read_key == 0) return 0;
    R4DeskReadKeyFn legacy_fn = (R4DeskReadKeyFn)(uintptr_t)desk->table->read_key;
    return legacy_fn();
}

static inline int32_t r4desk_console_input_wait(R4Desk *desk, uint64_t last_generation, uint64_t timeout_ticks, uint64_t *out_generation) {
    if (out_generation == 0) return R4OS_CONSOLE_INPUT_WAIT_ERROR_INVALID;
    *out_generation = last_generation;
    if (desk == 0 || desk->table == 0 ||
        desk->table->size < offsetof(R4XStartR4Desk, console_input_wait) + sizeof(uintptr_t) ||
        desk->table->console_input_wait == 0) return R4OS_CONSOLE_INPUT_WAIT_ERROR_UNSUPPORTED;
    R4DeskConsoleInputWaitFn fn = (R4DeskConsoleInputWaitFn)(uintptr_t)desk->table->console_input_wait;
    return fn(last_generation, timeout_ticks, out_generation);
}

static inline int32_t r4desk_physical_key_poll(R4Desk *desk, R4PhysicalKeyEvent *out_event) {
    if (out_event == 0) return R4OS_PHYSICAL_KEY_POLL_ERROR_INVALID;
    *out_event = (R4PhysicalKeyEvent){0};
    if (desk == 0 || desk->table == 0 ||
        desk->table->size < offsetof(R4XStartR4Desk, physical_key_poll) + sizeof(uintptr_t) ||
        desk->table->physical_key_poll == 0) return R4OS_PHYSICAL_KEY_POLL_ERROR_UNSUPPORTED;
    R4DeskPhysicalKeyPollFn fn = (R4DeskPhysicalKeyPollFn)(uintptr_t)desk->table->physical_key_poll;
    return fn(out_event);
}

static inline int32_t r4desk_program_window_id(R4Desk *desk) {
    if (desk == 0 || desk->table == 0 || desk->table->program_window_id == 0) return -1;
    R4DeskProgramWindowIdFn fn = (R4DeskProgramWindowIdFn)(uintptr_t)desk->table->program_window_id;
    return fn();
}

static inline int32_t r4desk_program_set_window_handle(R4Desk *desk, const R4ProgramProcessHandle *handle, int32_t window_id) {
    if (desk == 0 || desk->table == 0 || handle == 0 || desk->table->program_set_window_handle == 0) return R4OS_PROGRAM_HANDLE_ERROR_INVALID;
    R4DeskProgramSetWindowHandleFn fn = (R4DeskProgramSetWindowHandleFn)(uintptr_t)desk->table->program_set_window_handle;
    return fn(handle, window_id);
}

static inline int32_t r4desk_gui_window_info(R4Desk *desk, R4GuiWindowInfo *out) {
    if (desk == 0 || desk->table == 0 || desk->table->gui_window_info == 0) return R4OS_ERROR_INVALID;
    R4DeskGuiWindowInfoFn fn = (R4DeskGuiWindowInfoFn)(uintptr_t)desk->table->gui_window_info;
    return fn(out);
}

static inline int32_t r4desk_gui_poll_event(R4Desk *desk, R4GuiEvent *out) {
    if (desk == 0 || desk->table == 0 || desk->table->gui_poll_event == 0) return 0;
    R4DeskGuiPollEventFn fn = (R4DeskGuiPollEventFn)(uintptr_t)desk->table->gui_poll_event;
    return fn(out);
}

static inline int32_t r4desk_gui_set_title(R4Desk *desk, const char *text) {
    if (desk == 0 || desk->table == 0 || desk->table->gui_set_title == 0) return R4OS_ERROR_INVALID;
    R4DeskGuiSetTitleFn fn = (R4DeskGuiSetTitleFn)(uintptr_t)desk->table->gui_set_title;
    return fn((const uint8_t *)(const void *)text);
}

static inline int32_t r4desk_gui_set_min_size(R4Desk *desk, int32_t w, int32_t h) {
    if (desk == 0 || desk->table == 0 || desk->table->gui_set_min_size == 0) return R4OS_ERROR_INVALID;
    R4DeskGuiSetMinSizeFn fn = (R4DeskGuiSetMinSizeFn)(uintptr_t)desk->table->gui_set_min_size;
    return fn(w, h);
}

static inline int32_t r4desk_remote_frame_info(R4Desk *desk, R4RemoteFrameInfo *out) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_frame_info == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameInfoFn fn = (R4DeskRemoteFrameInfoFn)(uintptr_t)desk->table->remote_frame_info;
    return fn(out);
}

static inline int32_t r4desk_remote_frame_read(R4Desk *desk, uint32_t offset_pixels, uint32_t *out, uint32_t pixel_count, R4RemoteFrameInfo *out_info) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_frame_read == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameReadFn fn = (R4DeskRemoteFrameReadFn)(uintptr_t)desk->table->remote_frame_read;
    return fn(offset_pixels, out, pixel_count, out_info);
}

static inline int32_t r4desk_remote_frame_wait(R4Desk *desk, uint32_t last_revision, uint64_t timeout_ticks, R4RemoteFrameInfo *out) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_frame_wait == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameWaitFn fn = (R4DeskRemoteFrameWaitFn)(uintptr_t)desk->table->remote_frame_wait;
    return fn(last_revision, timeout_ticks, out);
}

static inline int32_t r4desk_remote_frame_publish(R4Desk *desk, const R4RemoteFrameInfo *info, const uint32_t *pixels, uint32_t pixel_count) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_frame_publish == 0) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFramePublishFn fn = (R4DeskRemoteFramePublishFn)(uintptr_t)desk->table->remote_frame_publish;
    return fn(info, pixels, pixel_count);
}

static inline int r4desk_supports_remote_frame_regions(const R4Desk *desk) {
    return desk != 0 && desk->table != 0 &&
        desk->table->size >= offsetof(R4XStartR4Desk, remote_frame_publish_regions) + sizeof(uintptr_t) &&
        desk->table->remote_frame_publish_regions != 0;
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
        (R4DeskRemoteFramePublishRegionsFn)(uintptr_t)desk->table->remote_frame_publish_regions;
    return fn(info, pixels, pixel_count, regions, region_count);
}

static inline int r4desk_supports_remote_frame_demand(const R4Desk *desk) {
    return desk != 0 && desk->table != 0 &&
        desk->table->size >= offsetof(R4XStartR4Desk, remote_frame_consumers) + sizeof(uintptr_t) &&
        desk->table->remote_frame_acquire != 0 && desk->table->remote_frame_release != 0 &&
        desk->table->remote_frame_consumers != 0;
}

static inline int32_t r4desk_remote_frame_acquire(R4Desk *desk) {
    if (!r4desk_supports_remote_frame_demand(desk)) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameAcquireFn fn = (R4DeskRemoteFrameAcquireFn)(uintptr_t)desk->table->remote_frame_acquire;
    return fn();
}

static inline int32_t r4desk_remote_frame_release(R4Desk *desk) {
    if (!r4desk_supports_remote_frame_demand(desk)) return R4_REMOTE_FRAME_ERROR_UNSUPPORTED;
    R4DeskRemoteFrameReleaseFn fn = (R4DeskRemoteFrameReleaseFn)(uintptr_t)desk->table->remote_frame_release;
    return fn();
}

static inline uint32_t r4desk_remote_frame_consumers(R4Desk *desk) {
    if (!r4desk_supports_remote_frame_demand(desk)) return 0u;
    R4DeskRemoteFrameConsumersFn fn = (R4DeskRemoteFrameConsumersFn)(uintptr_t)desk->table->remote_frame_consumers;
    return fn();
}

static inline int32_t r4desk_remote_input_push(R4Desk *desk, const R4RemoteInputEvent *event) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_input_push == 0) return R4_REMOTE_INPUT_ERROR_UNSUPPORTED;
    R4DeskRemoteInputPushFn fn = (R4DeskRemoteInputPushFn)(uintptr_t)desk->table->remote_input_push;
    return fn(event);
}

static inline int32_t r4desk_remote_input_poll(R4Desk *desk, R4RemoteInputEvent *out) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_input_poll == 0) return R4_REMOTE_INPUT_ERROR_UNSUPPORTED;
    R4DeskRemoteInputPollFn fn = (R4DeskRemoteInputPollFn)(uintptr_t)desk->table->remote_input_poll;
    return fn(out);
}

static inline int32_t r4desk_remote_input_status(R4Desk *desk, R4RemoteInputStatus *out) {
    if (desk == 0 || desk->table == 0 || desk->table->remote_input_status == 0) return R4_REMOTE_INPUT_ERROR_UNSUPPORTED;
    R4DeskRemoteInputStatusFn fn = (R4DeskRemoteInputStatusFn)(uintptr_t)desk->table->remote_input_status;
    return fn(out);
}

#ifdef __cplusplus
}
#endif

#endif
