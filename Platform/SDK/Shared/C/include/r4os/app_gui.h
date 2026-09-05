#ifndef R4OS_APP_GUI_H
#define R4OS_APP_GUI_H

#include "app_contract.h"

typedef struct R4CommandId { uint32_t value; } R4CommandId;
typedef struct R4TimerId { uint32_t value; } R4TimerId;

enum {
    R4_GUI_RAW_EVENT_CLOSE = 1,
    R4_GUI_RAW_EVENT_RESIZE = 2,
    R4_GUI_RAW_EVENT_MOUSE_DOWN = 3,
    R4_GUI_RAW_EVENT_MOUSE_UP = 4,
    R4_GUI_RAW_EVENT_MOUSE_MOVE = 5,
    R4_GUI_RAW_EVENT_KEY_DOWN = 6
};

typedef enum R4MouseAction {
    R4_MOUSE_DOWN = 0,
    R4_MOUSE_UP = 1,
    R4_MOUSE_MOVE = 2
} R4MouseAction;

typedef struct R4ResizeMessage {
    int32_t window_id;
    int32_t width;
    int32_t height;
    uint64_t tick;
} R4ResizeMessage;

typedef struct R4KeyMessage {
    int32_t window_id;
    uint8_t key;
    uint8_t reserved[3];
    uint32_t codepoint;
    uint32_t modifiers;
    uint64_t tick;
} R4KeyMessage;

typedef struct R4MouseMessage {
    int32_t window_id;
    R4MouseAction action;
    int32_t x;
    int32_t y;
    uint32_t buttons;
    uint32_t modifiers;
    uint64_t tick;
} R4MouseMessage;

typedef struct R4ClipboardMessage { uint32_t revision; } R4ClipboardMessage;
typedef struct R4TimerMessage { R4TimerId id; uint64_t tick; } R4TimerMessage;

typedef enum R4MessageKind {
    R4_MESSAGE_CLOSE = 1,
    R4_MESSAGE_RESIZE = 2,
    R4_MESSAGE_KEY = 3,
    R4_MESSAGE_MOUSE = 4,
    R4_MESSAGE_COMMAND = 5,
    R4_MESSAGE_CLIPBOARD = 6,
    R4_MESSAGE_TIMER = 7,
    R4_MESSAGE_UNKNOWN = 8
} R4MessageKind;

typedef struct R4Message {
    R4MessageKind kind;
    union {
        int32_t close_window_id;
        R4ResizeMessage resize;
        R4KeyMessage key;
        R4MouseMessage mouse;
        R4CommandId command;
        R4ClipboardMessage clipboard;
        R4TimerMessage timer;
        R4GuiEvent unknown;
    } value;
} R4Message;

typedef enum R4MessageNextState {
    R4_MESSAGE_NEXT_MESSAGE = 0,
    R4_MESSAGE_NEXT_TIMED_OUT = 1,
    R4_MESSAGE_NEXT_FAILED = 2
} R4MessageNextState;

typedef struct R4MessageNext {
    R4MessageNextState state;
    int32_t raw_code;
    R4Message message;
} R4MessageNext;

typedef struct R4Timer {
    R4TimerId id;
    uint64_t deadline_tick;
    uint64_t interval_ticks;
    uint8_t active;
} R4Timer;

typedef struct R4EventLoop {
    R4App *app;
    R4Timer *timers;
    uint32_t timer_count;
    uint64_t activity_sequence;
    uint32_t clipboard_revision;
    R4CommandId pending_command;
    uint8_t has_pending_command;
} R4EventLoop;

typedef struct R4Window {
    R4App *app;
    int32_t id;
    R4EventLoop events;
} R4Window;

typedef struct R4PaintContext {
    R4Window *window;
    R4GuiWindowInfo info;
    uint8_t active;
    uint8_t transactional;
} R4PaintContext;

typedef struct R4Canvas { R4PaintContext *paint; } R4Canvas;

static inline uint32_t r4_gui_monotonic_hz(R4App *app) {
    if (app == 0 || app->system.table == 0 || app->system.table->time_state == 0) return 0u;
    R4TimeState state = {0}; ((R4SysTimeStateFn)(uintptr_t)app->system.table->time_state)(&state); return state.monotonic_hz;
}

static inline int r4_timer_start(R4Timer *timer, R4App *app, R4TimerId id, R4Duration duration, int repeating) {
    if (timer == 0 || app == 0) return 0;
    uint64_t ticks = 0u; if (r4_duration_to_ticks(duration, r4_gui_monotonic_hz(app), &ticks) != R4OS_OK) return 0;
    uint64_t now = r4_app_ticks(app); uint64_t deadline = UINT64_MAX - now < ticks ? UINT64_MAX : now + ticks;
    *timer = (R4Timer){id, deadline, repeating ? (ticks == 0u ? 1u : ticks) : 0u, 1u}; return 1;
}

static inline void r4_timer_cancel(R4Timer *timer) { if (timer != 0) timer->active = 0u; }

static inline int r4_window_open(R4App *app, R4Timer *timers, uint32_t timer_count, R4Window *out) {
    if (app == 0 || out == 0 || !r4_app_has_group(app, R4L_GROUP_R4DESK) || !r4_app_has_group(app, R4L_GROUP_R4DRAW)) return 0;
    const R4XStartR4Desk *desk = app->desktop.table; const R4XStartR4Draw *draw = app->drawing.table;
    if (desk == 0 || draw == 0 || desk->program_window_id == 0 || desk->gui_window_info == 0 || desk->gui_poll_event == 0 || desk->desktop_activity_wait == 0 || draw->gui_clear == 0 || draw->gui_rect == 0 || draw->gui_present == 0) return 0;
    int32_t id = r4desk_program_window_id(&app->desktop); if (id < 0) return 0;
    *out = (R4Window){0}; out->app = app; out->id = id; out->events.app = app; out->events.timers = timers; out->events.timer_count = timer_count;
    if (desk->clipboard_revision != 0) out->events.clipboard_revision = ((R4DeskClipboardRevisionFn)(uintptr_t)desk->clipboard_revision)();
    return 1;
}

static inline int32_t r4_window_set_title(R4Window *window, const char *title) {
    return window != 0 && window->app != 0 ? r4desk_gui_set_title(&window->app->desktop, title) : R4OS_ERR_NO_FN;
}

static inline int32_t r4_window_set_minimum_size(R4Window *window, int32_t width, int32_t height) {
    return window != 0 && window->app != 0 ? r4desk_gui_set_min_size(&window->app->desktop, width, height) : R4OS_ERR_NO_FN;
}

static inline R4MouseMessage r4_mouse_message(R4GuiEvent raw, R4MouseAction action) {
    R4MouseMessage result = {raw.window_id, action, raw.x, raw.y, raw.buttons, raw.modifiers, raw.tick}; return result;
}

static inline R4Message r4_message_translate(R4EventLoop *loop, R4GuiEvent raw) {
    R4Message result = {0};
    switch (raw.kind) {
        case R4_GUI_RAW_EVENT_CLOSE: result.kind = R4_MESSAGE_CLOSE; result.value.close_window_id = raw.window_id; break;
        case R4_GUI_RAW_EVENT_RESIZE: {
            R4GuiWindowInfo info = {0};
            if (r4desk_gui_window_info(&loop->app->desktop, &info) < 0) { result.kind = R4_MESSAGE_UNKNOWN; result.value.unknown = raw; break; }
            result.kind = R4_MESSAGE_RESIZE; result.value.resize = (R4ResizeMessage){raw.window_id, info.client_w, info.client_h, raw.tick}; break;
        }
        case R4_GUI_RAW_EVENT_KEY_DOWN: result.kind = R4_MESSAGE_KEY; result.value.key = (R4KeyMessage){raw.window_id, (uint8_t)raw.key, {0}, raw.key, raw.modifiers, raw.tick}; break;
        case R4_GUI_RAW_EVENT_MOUSE_DOWN: result.kind = R4_MESSAGE_MOUSE; result.value.mouse = r4_mouse_message(raw, R4_MOUSE_DOWN); break;
        case R4_GUI_RAW_EVENT_MOUSE_UP: result.kind = R4_MESSAGE_MOUSE; result.value.mouse = r4_mouse_message(raw, R4_MOUSE_UP); break;
        case R4_GUI_RAW_EVENT_MOUSE_MOVE: result.kind = R4_MESSAGE_MOUSE; result.value.mouse = r4_mouse_message(raw, R4_MOUSE_MOVE); break;
        default: result.kind = R4_MESSAGE_UNKNOWN; result.value.unknown = raw; break;
    }
    return result;
}

static inline int r4_event_loop_post_command(R4EventLoop *loop, R4CommandId command) {
    if (loop == 0 || loop->has_pending_command) return 0; loop->pending_command = command; loop->has_pending_command = 1u; return 1;
}

static inline int r4_event_loop_poll(R4EventLoop *loop, R4Message *out) {
    if (loop == 0 || out == 0 || loop->app == 0) return 0;
    R4GuiEvent raw = {0};
    if (r4desk_gui_poll_event(&loop->app->desktop, &raw) > 0) { *out = r4_message_translate(loop, raw); return 1; }
    if (loop->has_pending_command) { *out = (R4Message){0}; out->kind = R4_MESSAGE_COMMAND; out->value.command = loop->pending_command; loop->has_pending_command = 0u; return 1; }
    if (loop->app->desktop.table->clipboard_revision != 0) {
        uint32_t revision = ((R4DeskClipboardRevisionFn)(uintptr_t)loop->app->desktop.table->clipboard_revision)();
        if (revision != loop->clipboard_revision) { loop->clipboard_revision = revision; *out = (R4Message){0}; out->kind = R4_MESSAGE_CLIPBOARD; out->value.clipboard.revision = revision; return 1; }
    }
    uint64_t now = r4_app_ticks(loop->app);
    for (uint32_t i = 0; i < loop->timer_count; ++i) {
        R4Timer *timer = &loop->timers[i]; if (!timer->active || now < timer->deadline_tick) continue;
        *out = (R4Message){0}; out->kind = R4_MESSAGE_TIMER; out->value.timer = (R4TimerMessage){timer->id, now};
        if (timer->interval_ticks == 0u) timer->active = 0u; else { uint64_t periods = (now - timer->deadline_tick) / timer->interval_ticks + 1u; timer->deadline_tick = periods > (UINT64_MAX - timer->deadline_tick) / timer->interval_ticks ? UINT64_MAX : timer->deadline_tick + periods * timer->interval_ticks; }
        return 1;
    }
    if (r4_app_should_close(loop->app)) { *out = (R4Message){0}; out->kind = R4_MESSAGE_CLOSE; out->value.close_window_id = r4desk_program_window_id(&loop->app->desktop); return 1; }
    return 0;
}

static inline uint64_t r4_event_loop_timer_delay(R4EventLoop *loop, uint64_t now, int *found) {
    uint64_t result = UINT64_MAX; *found = 0;
    for (uint32_t i = 0; i < loop->timer_count; ++i) if (loop->timers[i].active) { uint64_t delay = now >= loop->timers[i].deadline_tick ? 0u : loop->timers[i].deadline_tick - now; if (!*found || delay < result) result = delay; *found = 1; }
    return result;
}

static inline R4MessageNext r4_event_loop_wait(R4EventLoop *loop, R4Timeout timeout) {
    R4MessageNext result = {0};
    if (loop == 0 || loop->app == 0 || loop->app->desktop.table == 0 || loop->app->desktop.table->desktop_activity_wait == 0) { result.state = R4_MESSAGE_NEXT_FAILED; result.raw_code = R4OS_ERR_NO_FN; return result; }
    uint64_t budget = 0u; if (r4_timeout_to_ticks(timeout, r4_gui_monotonic_hz(loop->app), &budget) != R4OS_OK) { result.state = R4_MESSAGE_NEXT_FAILED; result.raw_code = R4_REMOTE_FRAME_ERROR_INVALID; return result; }
    uint64_t started = r4_app_ticks(loop->app); int forever = timeout.kind == R4OS_TIMEOUT_KIND_FOREVER; uint64_t deadline = forever || UINT64_MAX - started < budget ? UINT64_MAX : started + budget;
    for (;;) {
        if (r4_event_loop_poll(loop, &result.message)) { result.state = R4_MESSAGE_NEXT_MESSAGE; return result; }
        uint64_t now = r4_app_ticks(loop->app); uint64_t remaining = forever ? UINT64_MAX : (now >= deadline ? 0u : deadline - now);
        if (remaining == 0u) { result.state = R4_MESSAGE_NEXT_TIMED_OUT; return result; }
        int timer_found = 0; uint64_t timer_delay = r4_event_loop_timer_delay(loop, now, &timer_found); if (timer_found && timer_delay < remaining) remaining = timer_delay; if (remaining == 0u) continue;
        uint64_t sequence = loop->activity_sequence; int32_t raw = ((R4DeskDesktopActivityWaitFn)(uintptr_t)loop->app->desktop.table->desktop_activity_wait)(loop->activity_sequence, remaining, &sequence); loop->activity_sequence = sequence;
        if (raw < 0) { result.state = R4_MESSAGE_NEXT_FAILED; result.raw_code = raw; return result; }
    }
}

static inline R4MessageNext r4_window_wait_message(R4Window *window, R4Timeout timeout) {
    if (window == 0) { R4MessageNext failed = {0}; failed.state = R4_MESSAGE_NEXT_FAILED; failed.raw_code = R4OS_ERR_NO_FN; return failed; }
    return r4_event_loop_wait(&window->events, timeout);
}

static inline int r4_window_begin_paint(R4Window *window, R4PaintContext *out) {
    if (window == 0 || out == 0 || window->app == 0) return 0; *out = (R4PaintContext){0}; out->window = window;
    if (r4desk_gui_window_info(&window->app->desktop, &out->info) < 0 || out->info.client_w <= 0 || out->info.client_h <= 0) return 0;
    out->transactional = (uint8_t)r4draw_supports_gui_frame_contract(&window->app->drawing);
    if (out->transactional && r4draw_gui_frame_begin(&window->app->drawing) < 0) return 0;
    out->active = 1u; return 1;
}

static inline R4Canvas r4_paint_canvas(R4PaintContext *paint) { R4Canvas result = {paint}; return result; }
static inline int32_t r4_canvas_clear(R4Canvas canvas, uint32_t rgb) { return canvas.paint != 0 && canvas.paint->active ? r4draw_gui_clear(&canvas.paint->window->app->drawing, rgb) : R4OS_ERR_NO_FN; }
static inline int32_t r4_canvas_rect(R4Canvas canvas, int32_t x, int32_t y, uint32_t width, uint32_t height, uint32_t rgb) { return canvas.paint != 0 && canvas.paint->active ? r4draw_gui_rect(&canvas.paint->window->app->drawing, x, y, width, height, rgb) : R4OS_ERR_NO_FN; }
static inline int32_t r4_canvas_text(R4Canvas canvas, int32_t x, int32_t y, const char *text, uint32_t fg, uint32_t bg) { return canvas.paint != 0 && canvas.paint->active ? r4draw_gui_draw_text(&canvas.paint->window->app->drawing, x, y, text, fg, bg) : R4OS_ERR_NO_FN; }
static inline int32_t r4_canvas_blend_alpha8(R4Canvas canvas, int32_t x, int32_t y,
                                             uint32_t width, uint32_t height,
                                             uint32_t stride, uint32_t rgb,
                                             const uint8_t *alpha, size_t alpha_len) {
    if (canvas.paint == 0 || !canvas.paint->active || alpha == 0) return R4OS_ERR_NO_FN;
    if (width == 0u || height == 0u) return 0;
    if (width > R4OS_GUI_ALPHA8_MAX_WIDTH || height > R4OS_GUI_ALPHA8_MAX_HEIGHT || stride < width) return R4OS_ERROR_INVALID;
    uint64_t required = (uint64_t)(height - 1u) * stride + width;
    if (required > alpha_len) return R4OS_ERROR_INVALID;

    int64_t left = x < 0 ? 0 : x;
    int64_t top = y < 0 ? 0 : y;
    int64_t right = (int64_t)x + width;
    int64_t bottom = (int64_t)y + height;
    if (right > canvas.paint->info.client_w) right = canvas.paint->info.client_w;
    if (bottom > canvas.paint->info.client_h) bottom = canvas.paint->info.client_h;
    if (right <= left || bottom <= top) return 0;

    size_t source_x = (size_t)(left - x);
    size_t source_y = (size_t)(top - y);
    uint32_t visible_width = (uint32_t)(right - left);
    uint32_t visible_height = (uint32_t)(bottom - top);
    size_t source_offset = source_y * stride + source_x;
    size_t visible_bytes = (size_t)(visible_height - 1u) * stride + visible_width;
    if (source_offset > alpha_len || visible_bytes > alpha_len - source_offset) return R4OS_ERROR_INVALID;
    return r4draw_gui_blend_alpha8(&canvas.paint->window->app->drawing,
                                   (int32_t)left, (int32_t)top,
                                   visible_width, visible_height, stride, rgb,
                                   alpha + source_offset, visible_bytes);
}
static inline int32_t r4_paint_present(R4PaintContext *paint) { if (paint == 0 || !paint->active) return R4OS_ERR_NO_FN; int32_t raw = paint->transactional ? r4draw_gui_frame_commit(&paint->window->app->drawing) : r4draw_gui_present(&paint->window->app->drawing); if (raw >= 0) paint->active = 0u; return raw; }
static inline void r4_paint_discard(R4PaintContext *paint) { if (paint != 0) { if (paint->active && paint->transactional) (void)r4draw_gui_frame_cancel(&paint->window->app->drawing); paint->active = 0u; } }

#endif
