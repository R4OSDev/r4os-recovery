#include <assert.h>
#include <stdint.h>

#include <r4os/r4os.h>

static uint64_t now_ticks = 100u;
static uint32_t activity_waits;
static uint32_t clipboard_revision = 7u;
static uint32_t event_index;
static uint32_t draw_count;
static uint32_t present_count;
static uint32_t alpha8_count;
static int32_t alpha8_x;
static int32_t alpha8_y;
static uint32_t alpha8_width;
static uint32_t alpha8_height;
static uint32_t alpha8_stride;
static uint8_t alpha8_first;
static uint32_t frame_begin_count;
static uint32_t frame_append_count;
static uint32_t frame_commit_count;
static uint32_t frame_cancel_count;

static const R4GuiEvent events[] = {
    {.kind = R4_GUI_RAW_EVENT_RESIZE, .window_id = 4, .tick = 10u},
    {.kind = R4_GUI_RAW_EVENT_KEY_DOWN, .window_id = 4, .key = 'A', .modifiers = 2u, .tick = 11u},
    {.kind = R4_GUI_RAW_EVENT_MOUSE_DOWN, .window_id = 4, .x = 8, .y = 9, .buttons = 1u, .tick = 12u},
    {.kind = R4_GUI_RAW_EVENT_MOUSE_UP, .window_id = 4, .x = 10, .y = 11, .tick = 13u},
    {.kind = R4_GUI_RAW_EVENT_MOUSE_MOVE, .window_id = 4, .x = 12, .y = 13, .tick = 14u},
    {.kind = R4_GUI_RAW_EVENT_CLOSE, .window_id = 4, .tick = 15u},
};

static uint64_t fake_ticks(void) { return now_ticks; }
static uint32_t fake_should_close(void) { return 0u; }
static void fake_time_state(R4TimeState *out) {
    *out = (R4TimeState){0};
    out->monotonic_ticks = now_ticks;
    out->monotonic_hz = 1000u;
    out->valid = 1u;
}
static int32_t fake_window_id(void) { return 4; }
static int32_t fake_window_info(R4GuiWindowInfo *out) {
    *out = (R4GuiWindowInfo){0};
    out->window_id = 4;
    out->client_w = 320;
    out->client_h = 200;
    return 0;
}
static int32_t fake_poll_event(R4GuiEvent *out) {
    if (event_index >= sizeof(events) / sizeof(events[0])) return 0;
    *out = events[event_index++];
    return 1;
}
static int32_t fake_set_title(const uint8_t *title) { return title != 0 ? 0 : -1; }
static int32_t fake_set_minimum_size(int32_t width, int32_t height) { return width == 100 && height == 80 ? 0 : -1; }
static uint32_t fake_clipboard_revision(void) { return clipboard_revision; }
static int32_t fake_activity_wait(uint64_t sequence, uint64_t timeout, uint64_t *out_sequence) {
    ++activity_waits;
    now_ticks = UINT64_MAX - now_ticks < timeout ? UINT64_MAX : now_ticks + timeout;
    *out_sequence = sequence;
    return 0;
}
static int32_t fake_clear(uint32_t rgb) { (void)rgb; ++draw_count; return 0; }
static int32_t fake_rect(int32_t x, int32_t y, uint32_t width, uint32_t height, uint32_t rgb) {
    (void)x; (void)y; (void)width; (void)height; (void)rgb; ++draw_count; return 0;
}
static int32_t fake_text(int32_t x, int32_t y, const uint8_t *text, uint32_t fg, uint32_t bg) {
    (void)x; (void)y; (void)text; (void)fg; (void)bg; ++draw_count; return 0;
}
static int32_t fake_alpha8(int32_t x, int32_t y, uint32_t width, uint32_t height,
                           uint32_t stride, uint32_t rgb, const uint8_t *alpha,
                           uint32_t alpha_len) {
    (void)rgb;
    assert(alpha != 0 && alpha_len >= width);
    ++alpha8_count;
    alpha8_x = x;
    alpha8_y = y;
    alpha8_width = width;
    alpha8_height = height;
    alpha8_stride = stride;
    alpha8_first = alpha[0];
    return 0;
}
static int32_t fake_present(void) { ++present_count; return 0; }
static int32_t fake_frame_begin(void) { ++frame_begin_count; return R4OS_GUI_FRAME_RESULT_OK; }
static int32_t fake_frame_append(const R4GuiFrameCommand *commands, uint64_t command_count,
                                 const uint8_t *resources, uint64_t resource_len) {
    ++frame_append_count;
    return (commands == 0 && command_count != 0u) || (resources == 0 && resource_len != 0u)
        ? R4OS_GUI_FRAME_ERROR_INVALID : R4OS_GUI_FRAME_RESULT_OK;
}
static int32_t fake_frame_commit(void) { ++frame_commit_count; return R4OS_GUI_FRAME_RESULT_OK; }
static int32_t fake_frame_cancel(void) { ++frame_cancel_count; return R4OS_GUI_FRAME_RESULT_OK; }
static int32_t fake_frame_info(const R4ProgramProcessHandle *handle, R4GuiFrameInfo *out) {
    if (out->version < R4OS_GUI_FRAME_INFO_VERSION || out->size < R4OS_GUI_FRAME_INFO_SIZE) return R4OS_GUI_FRAME_ERROR_INVALID;
    *out = (R4GuiFrameInfo){0};
    out->version = R4OS_GUI_FRAME_INFO_VERSION;
    out->size = R4OS_GUI_FRAME_INFO_SIZE;
    if (handle != 0) out->owner = *handle;
    out->committed_generation = 7u;
    out->committed_command_count = 1u;
    out->committed_resource_bytes = 4u;
    return R4OS_GUI_FRAME_RESULT_OK;
}
static int32_t fake_frame_read(const R4ProgramProcessHandle *handle, uint64_t expected_generation,
                               R4GuiFrameCommand *commands, uint64_t command_capacity,
                               uint8_t *resources, uint64_t resource_capacity,
                               R4GuiFrameInfo *out) {
    (void)handle;
    if (out->version < R4OS_GUI_FRAME_INFO_VERSION || out->size < R4OS_GUI_FRAME_INFO_SIZE) return R4OS_GUI_FRAME_ERROR_INVALID;
    *out = (R4GuiFrameInfo){0};
    out->version = R4OS_GUI_FRAME_INFO_VERSION;
    out->size = R4OS_GUI_FRAME_INFO_SIZE;
    out->committed_generation = 7u;
    out->committed_command_count = 1u;
    out->committed_resource_bytes = 4u;
    if ((commands == 0 && command_capacity != 0u) ||
        (resources == 0 && resource_capacity != 0u)) return R4OS_GUI_FRAME_ERROR_INVALID;
    if (expected_generation != 7u) return R4OS_GUI_FRAME_ERROR_STALE;
    if (command_capacity < 1u || resource_capacity < 4u) return R4OS_GUI_FRAME_ERROR_BUFFER_TOO_SMALL;
    commands[0] = (R4GuiFrameCommand){0}; commands[0].kind = R4OS_GUI_FRAME_COMMAND_KIND_TEXT; commands[0].resource_bytes = 4u;
    resources[0] = 'R'; resources[1] = '4'; resources[2] = 'O'; resources[3] = 'S';
    return R4OS_GUI_FRAME_RESULT_OK;
}

static R4App make_app(R4XStartR4Sys *sys, R4XStartR4Desk *desk, R4XStartR4Draw *draw, int drawing_available) {
    *sys = (R4XStartR4Sys){0};
    sys->ticks = (uintptr_t)&fake_ticks;
    sys->time_state = (uintptr_t)&fake_time_state;
    sys->program_should_close = (uintptr_t)&fake_should_close;
    *desk = (R4XStartR4Desk){0};
    desk->program_window_id = (uintptr_t)&fake_window_id;
    desk->gui_window_info = (uintptr_t)&fake_window_info;
    desk->gui_poll_event = (uintptr_t)&fake_poll_event;
    desk->gui_set_title = (uintptr_t)&fake_set_title;
    desk->gui_set_min_size = (uintptr_t)&fake_set_minimum_size;
    desk->clipboard_revision = (uintptr_t)&fake_clipboard_revision;
    desk->desktop_activity_wait = (uintptr_t)&fake_activity_wait;
    *draw = (R4XStartR4Draw){0};
    draw->size = R4XSTART_R4DRAW_SIZE;
    draw->gui_clear = (uintptr_t)&fake_clear;
    draw->gui_rect = (uintptr_t)&fake_rect;
    draw->gui_draw_text = (uintptr_t)&fake_text;
    draw->gui_blend_alpha8 = (uintptr_t)&fake_alpha8;
    if (drawing_available) draw->gui_present = (uintptr_t)&fake_present;
    R4App app = {0};
    app.profile = R4_APP_PROFILE_DESKTOP;
    app.group_mask = (1u << R4L_GROUP_R4SYS) | (1u << R4L_GROUP_R4DESK) | (1u << R4L_GROUP_R4DRAW);
    app.system.table = sys;
    app.desktop.table = desk;
    app.drawing.table = draw;
    return app;
}

int main(void) {
    R4XStartR4Sys sys;
    R4XStartR4Desk desk;
    R4XStartR4Draw draw;
    R4App app = make_app(&sys, &desk, &draw, 1);
    R4Timer timers[1] = {{0}};
    R4Window window;
    assert(r4_window_open(&app, timers, 1u, &window));
    assert(r4_window_set_title(&window, "Test") == 0);
    assert(r4_window_set_minimum_size(&window, 100, 80) == 0);

    R4Message message;
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_RESIZE && message.value.resize.width == 320);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_KEY && message.value.key.key == 'A' && message.value.key.codepoint == 'A');
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_MOUSE && message.value.mouse.action == R4_MOUSE_DOWN);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_MOUSE && message.value.mouse.action == R4_MOUSE_UP);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_MOUSE && message.value.mouse.action == R4_MOUSE_MOVE);
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_CLOSE && message.value.close_window_id == 4);

    R4PaintContext paint;
    assert(r4_window_begin_paint(&window, &paint));
    R4Canvas canvas = r4_paint_canvas(&paint);
    assert(r4_canvas_clear(canvas, 0u) == 0);
    assert(r4_canvas_rect(canvas, 1, 2, 3u, 4u, 0xFFFFFFu) == 0);
    const uint8_t alpha8[] = {10u, 20u, 30u, 99u, 40u, 50u, 60u};
    assert(r4_canvas_blend_alpha8(canvas, -1, -1, 3u, 2u, 4u, 0x336699u,
                                  alpha8, sizeof(alpha8)) == 0);
    assert(alpha8_count == 1u && alpha8_x == 0 && alpha8_y == 0);
    assert(alpha8_width == 2u && alpha8_height == 1u && alpha8_stride == 4u);
    assert(alpha8_first == 50u);
    assert(r4_paint_present(&paint) == 0);
    assert(r4_paint_present(&paint) == R4OS_ERR_NO_FN);
    assert(draw_count >= 2u && present_count == 1u);

    draw.gui_frame_begin = (uintptr_t)&fake_frame_begin;
    draw.gui_frame_append = (uintptr_t)&fake_frame_append;
    draw.gui_frame_commit = (uintptr_t)&fake_frame_commit;
    draw.gui_frame_cancel = (uintptr_t)&fake_frame_cancel;
    draw.gui_frame_info = (uintptr_t)&fake_frame_info;
    draw.gui_frame_read = (uintptr_t)&fake_frame_read;
    assert(r4draw_supports_gui_frame_contract(&app.drawing));
    assert(r4_window_begin_paint(&window, &paint));
    R4GuiFrameCommand command = {0}; command.version = R4OS_GUI_FRAME_COMMAND_VERSION; command.size = R4OS_GUI_FRAME_COMMAND_SIZE; command.kind = R4OS_GUI_FRAME_COMMAND_KIND_TEXT; command.resource_bytes = 4u;
    assert(r4draw_gui_frame_append(&app.drawing, &command, 1u, (const uint8_t *)"R4OS", 4u) == R4OS_GUI_FRAME_RESULT_OK);
    assert(r4draw_gui_frame_append(&app.drawing, 0, 1u, 0, 0u) == R4OS_GUI_FRAME_ERROR_INVALID);
    assert(frame_append_count == 2u);
    assert(r4_paint_present(&paint) == R4OS_GUI_FRAME_RESULT_OK);
    assert(frame_begin_count == 1u && frame_commit_count == 1u);
    R4ProgramProcessHandle handle = {0}; handle.instance_id = 4u; handle.generation = 9u;
    R4GuiFrameInfo frame_info = {0};
    assert(r4draw_gui_frame_info(&app.drawing, &handle, &frame_info) == R4OS_GUI_FRAME_RESULT_OK);
    assert(frame_info.version == R4OS_GUI_FRAME_INFO_VERSION && frame_info.size == R4OS_GUI_FRAME_INFO_SIZE);
    R4GuiFrameCommand snapshot_commands[1] = {{0}}; uint8_t snapshot_resources[4] = {0};
    frame_info.version = 0u; frame_info.size = 0u;
    assert(r4draw_gui_frame_read(&app.drawing, &handle, frame_info.committed_generation, snapshot_commands, 1u, snapshot_resources, 4u, &frame_info) == R4OS_GUI_FRAME_RESULT_OK);
    assert(snapshot_resources[0] == 'R' && snapshot_resources[3] == 'S');
    frame_info = (R4GuiFrameInfo){0};
    assert(r4draw_gui_frame_read(&app.drawing, &handle, 7u, 0, 1u, snapshot_resources, 4u, &frame_info) == R4OS_GUI_FRAME_ERROR_INVALID);
    assert(frame_info.version == R4OS_GUI_FRAME_INFO_VERSION && frame_info.size == R4OS_GUI_FRAME_INFO_SIZE && frame_info.committed_command_count == 1u);
    assert(r4_window_begin_paint(&window, &paint)); r4_paint_discard(&paint); assert(frame_cancel_count == 1u);

    assert(r4_event_loop_post_command(&window.events, (R4CommandId){42u}));
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_COMMAND && message.value.command.value == 42u);
    clipboard_revision = 8u;
    assert(r4_event_loop_poll(&window.events, &message) && message.kind == R4_MESSAGE_CLIPBOARD && message.value.clipboard.revision == 8u);
    assert(r4_timer_start(&timers[0], &app, (R4TimerId){9u}, (R4Duration){2000000u}, 0));
    R4MessageNext next = r4_window_wait_message(&window, r4_timeout_finite((R4Duration){10000000u}));
    assert(next.state == R4_MESSAGE_NEXT_MESSAGE && next.message.kind == R4_MESSAGE_TIMER && next.message.value.timer.id.value == 9u);
    assert(activity_waits > 0u);
    assert(r4_window_wait_message(&window, r4_timeout_poll()).state == R4_MESSAGE_NEXT_TIMED_OUT);

    R4App missing_draw = make_app(&sys, &desk, &draw, 0);
    assert(!r4_window_open(&missing_draw, timers, 1u, &window));
    return 0;
}
