#ifndef R4OS_APP_GUI_H
#define R4OS_APP_GUI_H

#include "app_contract.h"
#include "desktop_actions.h"
#include "poll_budget.h"

typedef struct R4CommandId { uint32_t value; } R4CommandId;
typedef struct R4TimerId { uint32_t value; } R4TimerId;

enum {
    R4_GUI_RAW_EVENT_CLOSE = R4ABI_GUI_EVENT_KIND_CLOSE,
    R4_GUI_RAW_EVENT_RESIZE = R4ABI_GUI_EVENT_KIND_RESIZE,
    R4_GUI_RAW_EVENT_MOUSE_DOWN = R4ABI_GUI_EVENT_KIND_MOUSE_DOWN,
    R4_GUI_RAW_EVENT_MOUSE_UP = R4ABI_GUI_EVENT_KIND_MOUSE_UP,
    R4_GUI_RAW_EVENT_MOUSE_MOVE = R4ABI_GUI_EVENT_KIND_MOUSE_MOVE,
    R4_GUI_RAW_EVENT_KEY_DOWN = R4ABI_GUI_EVENT_KIND_KEY_DOWN,
    R4_GUI_RAW_EVENT_FONT_CHANGED = R4ABI_GUI_EVENT_KIND_FONT_CHANGED,
    R4_GUI_RAW_EVENT_FOCUS_GAINED = R4ABI_GUI_EVENT_KIND_FOCUS_GAINED,
    R4_GUI_RAW_EVENT_FOCUS_LOST = R4ABI_GUI_EVENT_KIND_FOCUS_LOST,
    R4_GUI_RAW_EVENT_MOUSE_WHEEL = R4ABI_GUI_EVENT_KIND_MOUSE_WHEEL,
    R4_GUI_RAW_EVENT_MOUSE_RELATIVE = R4ABI_GUI_EVENT_KIND_MOUSE_RELATIVE,
    R4_GUI_RAW_EVENT_CAPTURE_CHANGED = R4ABI_GUI_EVENT_KIND_CAPTURE_CHANGED,
    R4_GUI_RAW_EVENT_INPUT_RESET = R4ABI_GUI_EVENT_KIND_INPUT_RESET
};

#define R4_GUI_WINDOW_FLAG_VISIBLE R4ABI_GUI_WINDOW_FLAG_VISIBLE
#define R4_GUI_WINDOW_FLAG_MINIMIZED R4ABI_GUI_WINDOW_FLAG_MINIMIZED
#define R4_GUI_WINDOW_FLAG_MAXIMIZED R4ABI_GUI_WINDOW_FLAG_MAXIMIZED
#define R4_GUI_WINDOW_FLAG_CLOSE_REQUESTED R4ABI_GUI_WINDOW_FLAG_CLOSE_REQUESTED
#define R4_GUI_WINDOW_FLAG_FULLSCREEN R4OS_GUI_WINDOW_FLAG_FULLSCREEN

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
typedef struct R4FocusMessage { int32_t window_id; uint64_t tick; } R4FocusMessage;
/* A change notification: query the current font/metrics when handling it. */
typedef struct R4FontChangedMessage { int32_t window_id; uint64_t tick; } R4FontChangedMessage;

typedef struct R4WheelMessage {
    int32_t window_id,x,y,delta;
    uint32_t buttons,modifiers;
    uint64_t tick;
} R4WheelMessage;
typedef struct R4RelativeMouseMessage {
    int32_t window_id,dx,dy;
    uint32_t buttons,source,modifiers;
    uint64_t tick;
} R4RelativeMouseMessage;
typedef struct R4PointerCaptureMessage {
    int32_t window_id;
    uint32_t state,reason,mode;
    uint64_t capture_id,tick;
} R4PointerCaptureMessage;

/* Cancel all local pressed/repeat/drag state; do not synthesize a click. */
typedef struct R4InputResetMessage {
    int32_t window_id;
    uint32_t reason;
    uint64_t tick;
} R4InputResetMessage;

typedef enum R4MessageKind {
    R4_MESSAGE_CLOSE = 1,
    R4_MESSAGE_RESIZE = 2,
    R4_MESSAGE_KEY = 3,
    R4_MESSAGE_MOUSE = 4,
    R4_MESSAGE_COMMAND = 5,
    R4_MESSAGE_CLIPBOARD = 6,
    R4_MESSAGE_TIMER = 7,
    R4_MESSAGE_UNKNOWN = 8,
    R4_MESSAGE_FOCUS_GAINED = 9,
    R4_MESSAGE_FOCUS_LOST = 10,
    R4_MESSAGE_FONT_CHANGED = 11,
    R4_MESSAGE_MOUSE_WHEEL = 12,
    R4_MESSAGE_MOUSE_RELATIVE = 13,
    R4_MESSAGE_POINTER_CAPTURE = 14,
    R4_MESSAGE_INPUT_RESET = 15
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
        R4FocusMessage focus;
        R4FontChangedMessage font_changed;
        R4WheelMessage wheel;
        R4RelativeMouseMessage relative;
        R4PointerCaptureMessage capture;
        R4InputResetMessage input_reset;
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
    uint8_t close_delivered;
    uint8_t action_view_pending;
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
    uint8_t action_view_valid;
    R4DesktopActionToken action_view;
    uint64_t action_view_revision;
} R4PaintContext;

typedef struct R4Canvas { R4PaintContext *paint; } R4Canvas;

static inline uint32_t r4_gui_monotonic_hz(R4App *app) {
    if (app == 0 || !R4SYS_HAS(&app->system,time_state)) return 0u;
    R4TimeState state = {0}; ((R4SysTimeStateFn)(uintptr_t)R4SYS_SLOT(&app->system, time_state))(&state); return state.monotonic_hz;
}
#define R4_GUI_DESK_HAS(desk,field) R4DESK_HAS((desk),field)
#define R4_GUI_DRAW_HAS(draw,field) R4DRAW_HAS((draw),field)

static inline int32_t r4_gui_clock_sample(R4App *app, R4SdkClockSample *out) {
    if (!app || !out || !R4SYS_HAS(&app->system,monotonic_clock)) return R4_BUDGET_CLOCK_UNAVAILABLE;
    R4MonotonicClockInfo info = {0};
    if (((R4SysMonotonicClockFn)(uintptr_t)R4SYS_SLOT(&app->system,monotonic_clock))(&info) <= 0) return R4_BUDGET_CLOCK_UNAVAILABLE;
    return R4SdkClockSampleRead(&info,out);
}

static inline int r4_timer_start(R4Timer *timer, R4App *app, R4TimerId id, R4Duration duration, int repeating) {
    if (timer == 0 || app == 0) return 0;
    uint64_t ticks = 0u;
    if (app->system.generation2) {
        R4SdkClockSample sample; R4SdkBudgetValue value;
        R4Timeout timeout = {.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=duration.nanoseconds};
        if (!R4SYS_HAS(&app->system,ticks) || r4_gui_clock_sample(app,&sample) || !sample.identity.tick_hz ||
            R4SdkTimeoutTicksChecked(timeout,sample.identity.tick_hz,&value) || R4SdkBudgetToWaitTicks(&value,&ticks)) return 0;
    } else if (r4_duration_to_ticks(duration, r4_gui_monotonic_hz(app), &ticks) != R4OS_OK) return 0;
    uint64_t now = r4_app_ticks(app);
    if (app->system.generation2 && UINT64_MAX-now<ticks) return 0;
    uint64_t deadline = UINT64_MAX - now < ticks ? UINT64_MAX : now + ticks;
    *timer = (R4Timer){id, deadline, repeating ? (ticks == 0u ? 1u : ticks) : 0u, 1u}; return 1;
}

static inline void r4_timer_cancel(R4Timer *timer) { if (timer != 0) timer->active = 0u; }

static inline int r4_window_open(R4App *app, R4Timer *timers, uint32_t timer_count, R4Window *out) {
    if (app == 0 || out == 0 || (timer_count != 0 && timers == 0) || !r4_app_has_group(app, R4L_GROUP_R4DESK) || !r4_app_has_group(app, R4L_GROUP_R4DRAW)) return 0;
    if (!r4desk_available(&app->desktop) || !r4draw_available(&app->drawing) || !R4_GUI_DESK_HAS(&app->desktop,program_window_id) || !R4_GUI_DESK_HAS(&app->desktop,gui_window_info) || !R4_GUI_DESK_HAS(&app->desktop,gui_poll_event) || !R4_GUI_DESK_HAS(&app->desktop,gui_activity_wait) || !R4_GUI_DRAW_HAS(&app->drawing,gui_clear) || !R4_GUI_DRAW_HAS(&app->drawing,gui_rect) || !R4_GUI_DRAW_HAS(&app->drawing,gui_draw_text) || !R4_GUI_DRAW_HAS(&app->drawing,gui_present)) return 0;
    int32_t id = r4desk_program_window_id(&app->desktop); if (id < 0) return 0;
    *out = (R4Window){0}; out->app = app; out->id = id; out->events.app = app; out->events.timers = timers; out->events.timer_count = timer_count;
    if (R4_GUI_DESK_HAS(&app->desktop,clipboard_revision)) out->events.clipboard_revision = ((R4DeskClipboardRevisionFn)(uintptr_t)R4DESK_SLOT(&app->desktop, clipboard_revision))();
    return 1;
}

/* Keep the explicit identity for the window incarnation being captured.
 * Zero from acquire means PENDING; wait for POINTER_CAPTURE/ACTIVE. */
static inline int32_t r4_window_pointer_identity(R4Window *window,R4GuiPointerWindowIdentity *out){
    if(!window||!window->app||!out)return R4OS_GUI_POINTER_ERROR_INVALID;
    R4GuiPointerCaptureInfo info={0};
    int32_t rc=r4desk_gui_pointer_capture_info(&window->app->desktop,0,&info);
    if(rc)return rc;
    if(info.capture.window.window_id!=window->id||!info.capture.window.epoch)return R4OS_GUI_POINTER_ERROR_UNAVAILABLE;
    *out=info.capture.window;return 0;
}
static inline int32_t r4_window_pointer_capture(R4Window *window,const R4GuiPointerWindowIdentity *identity,uint32_t mode,R4GuiPointerCaptureHandle *out){
    if(!window||!window->app||!identity||!out)return R4OS_GUI_POINTER_ERROR_INVALID;
    if(identity->window_id!=window->id)return R4OS_GUI_POINTER_ERROR_STALE;
    return r4desk_gui_pointer_capture_acquire(&window->app->desktop,identity,mode,out);
}
static inline int32_t r4_window_pointer_status(R4Window *window,const R4GuiPointerCaptureHandle *capture,R4GuiPointerCaptureInfo *out){
    if(!window||!window->app||!capture||!out)return R4OS_GUI_POINTER_ERROR_INVALID;
    return r4desk_gui_pointer_capture_info(&window->app->desktop,capture,out);
}
static inline int32_t r4_window_pointer_release(R4Window *window,const R4GuiPointerCaptureHandle *capture){
    if(!window||!window->app||!capture)return R4OS_GUI_POINTER_ERROR_INVALID;
    return r4desk_gui_pointer_capture_release(&window->app->desktop,capture);
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
            if(raw.key==R4OS_GUI_RESIZE_ACTION_VIEW_KEY)loop->action_view_pending=1u;
            R4GuiWindowInfo info = {0};
            if (r4desk_gui_window_info(&loop->app->desktop, &info) < 0) { result.kind = R4_MESSAGE_UNKNOWN; result.value.unknown = raw; break; }
            result.kind = R4_MESSAGE_RESIZE; result.value.resize = (R4ResizeMessage){raw.window_id, info.client_w, info.client_h, raw.tick}; break;
        }
        case R4_GUI_RAW_EVENT_KEY_DOWN: result.kind = R4_MESSAGE_KEY; result.value.key = (R4KeyMessage){raw.window_id, (uint8_t)raw.key, {0}, raw.key, raw.modifiers, raw.tick}; break;
        case R4_GUI_RAW_EVENT_MOUSE_DOWN: result.kind = R4_MESSAGE_MOUSE; result.value.mouse = r4_mouse_message(raw, R4_MOUSE_DOWN); break;
        case R4_GUI_RAW_EVENT_MOUSE_UP: result.kind = R4_MESSAGE_MOUSE; result.value.mouse = r4_mouse_message(raw, R4_MOUSE_UP); break;
        case R4_GUI_RAW_EVENT_MOUSE_MOVE: result.kind = R4_MESSAGE_MOUSE; result.value.mouse = r4_mouse_message(raw, R4_MOUSE_MOVE); break;
        case R4_GUI_RAW_EVENT_MOUSE_WHEEL:
            result.kind=R4_MESSAGE_MOUSE_WHEEL;result.value.wheel=(R4WheelMessage){raw.window_id,raw.x,raw.y,(int32_t)raw.key,raw.buttons,raw.modifiers,raw.tick};break;
        case R4_GUI_RAW_EVENT_MOUSE_RELATIVE:
            result.kind=R4_MESSAGE_MOUSE_RELATIVE;result.value.relative=(R4RelativeMouseMessage){raw.window_id,raw.x,raw.y,raw.buttons,raw.key,raw.modifiers,raw.tick};break;
        case R4_GUI_RAW_EVENT_INPUT_RESET:
            result.kind=R4_MESSAGE_INPUT_RESET;result.value.input_reset=(R4InputResetMessage){raw.window_id,raw.key,raw.tick};break;
        case R4_GUI_RAW_EVENT_CAPTURE_CHANGED:
            result.kind=R4_MESSAGE_POINTER_CAPTURE;result.value.capture=(R4PointerCaptureMessage){raw.window_id,(uint32_t)raw.x,(uint32_t)raw.y,raw.modifiers,(uint64_t)raw.key|((uint64_t)raw.buttons<<32),raw.tick};break;
        case R4_GUI_RAW_EVENT_FOCUS_GAINED:
        case R4_GUI_RAW_EVENT_FOCUS_LOST:
            result.kind = raw.kind == R4_GUI_RAW_EVENT_FOCUS_GAINED ? R4_MESSAGE_FOCUS_GAINED : R4_MESSAGE_FOCUS_LOST;
            result.value.focus = (R4FocusMessage){raw.window_id, raw.tick}; break;
        case R4_GUI_RAW_EVENT_FONT_CHANGED:
            result.kind = R4_MESSAGE_FONT_CHANGED; result.value.font_changed = (R4FontChangedMessage){raw.window_id, raw.tick}; break;
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
    if (r4desk_gui_poll_event(&loop->app->desktop, &raw) > 0) { if(raw.kind==R4_GUI_RAW_EVENT_CLOSE)loop->close_delivered=1; *out = r4_message_translate(loop, raw); return 1; }
    if (loop->has_pending_command) { *out = (R4Message){0}; out->kind = R4_MESSAGE_COMMAND; out->value.command = loop->pending_command; loop->has_pending_command = 0u; return 1; }
    if (R4_GUI_DESK_HAS(&loop->app->desktop,clipboard_revision)) {
        uint32_t revision = ((R4DeskClipboardRevisionFn)(uintptr_t)R4DESK_SLOT(&loop->app->desktop, clipboard_revision))();
        if (revision != loop->clipboard_revision) { loop->clipboard_revision = revision; *out = (R4Message){0}; out->kind = R4_MESSAGE_CLIPBOARD; out->value.clipboard.revision = revision; return 1; }
    }
    uint64_t now = r4_app_ticks(loop->app);
    for (uint32_t i = 0; i < loop->timer_count; ++i) {
        R4Timer *timer = &loop->timers[i]; if (!timer->active || now < timer->deadline_tick) continue;
        *out = (R4Message){0}; out->kind = R4_MESSAGE_TIMER; out->value.timer = (R4TimerMessage){timer->id, now};
        if (timer->interval_ticks == 0u) timer->active = 0u; else { uint64_t quotient = (now - timer->deadline_tick) / timer->interval_ticks; uint64_t periods = quotient==UINT64_MAX ? UINT64_MAX : quotient+1u; timer->deadline_tick = periods > (UINT64_MAX - timer->deadline_tick) / timer->interval_ticks ? UINT64_MAX : timer->deadline_tick + periods * timer->interval_ticks; }
        return 1;
    }
    if (r4_app_should_close(loop->app)) { if(!loop->close_delivered){loop->close_delivered=1; *out = (R4Message){0}; out->kind = R4_MESSAGE_CLOSE; out->value.close_window_id = r4desk_program_window_id(&loop->app->desktop); return 1;} } else loop->close_delivered=0;
    return 0;
}

static inline uint64_t r4_event_loop_timer_delay(R4EventLoop *loop, uint64_t now, int *found) {
    uint64_t result = UINT64_MAX; *found = 0;
    for (uint32_t i = 0; i < loop->timer_count; ++i) if (loop->timers[i].active) { uint64_t delay = now >= loop->timers[i].deadline_tick ? 0u : loop->timers[i].deadline_tick - now; if (!*found || delay < result) result = delay; *found = 1; }
    return result;
}

static inline R4MessageNext r4_event_loop_wait(R4EventLoop *loop, R4Timeout timeout) {
    R4MessageNext result = {0};
    if (loop == 0 || loop->app == 0 || !R4_GUI_DESK_HAS(&loop->app->desktop,gui_activity_wait)) { result.state = R4_MESSAGE_NEXT_FAILED; result.raw_code = R4OS_ERR_NO_FN; return result; }
    const int generation2 = loop->app->system.generation2 != NULL;
    uint64_t budget = 0u; R4SdkBudgetValue checked_kind = {0}; R4SdkDeadlineBudget deadline2 = {0};
    if (generation2) {
        int32_t rc = R4SdkTimeoutTicksChecked(timeout,1,&checked_kind);
        if (!rc && checked_kind.kind==R4_BUDGET_FINITE) {
            R4SdkClockSample sample; rc=r4_gui_clock_sample(loop->app,&sample);
            if (!rc) rc=R4SdkDeadlineBudgetInit(sample,timeout,&deadline2);
        }
        if (rc) {result.state=R4_MESSAGE_NEXT_FAILED;result.raw_code=rc;return result;}
    } else if (r4_timeout_to_ticks(timeout, r4_gui_monotonic_hz(loop->app), &budget) != R4OS_OK) { result.state = R4_MESSAGE_NEXT_FAILED; result.raw_code = R4_REMOTE_FRAME_ERROR_INVALID; return result; }
    uint64_t started = r4_app_ticks(loop->app); int forever = timeout.kind == R4OS_TIMEOUT_KIND_FOREVER; uint64_t deadline = forever || UINT64_MAX - started < budget ? UINT64_MAX : started + budget;
    for (;;) {
        if (r4_event_loop_poll(loop, &result.message)) { result.state = R4_MESSAGE_NEXT_MESSAGE; return result; }
        uint64_t now = r4_app_ticks(loop->app); uint64_t remaining = forever ? UINT64_MAX : (now >= deadline ? 0u : deadline - now);
        if (generation2) {
            remaining=checked_kind.kind==R4_BUDGET_FOREVER ? UINT64_MAX : 0;
            if (checked_kind.kind==R4_BUDGET_FINITE) {
                R4SdkClockSample sample; R4SdkBudgetValue value; int32_t rc=r4_gui_clock_sample(loop->app,&sample);
                if (!rc) rc=R4SdkDeadlineBudgetRemaining(&deadline2,sample,&value);
                if (!rc && value.kind==R4_BUDGET_FINITE) {
                    R4Timeout rest={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=value.value};
                    rc=R4SdkTimeoutTicksChecked(rest,sample.identity.tick_hz,&value);
                }
                if (!rc) rc=R4SdkBudgetToWaitTicks(&value,&remaining);
                if (rc) {result.state=R4_MESSAGE_NEXT_FAILED;result.raw_code=rc;return result;}
            }
        }
        if (remaining == 0u) { result.state = R4_MESSAGE_NEXT_TIMED_OUT; return result; }
        int timer_found = 0; uint64_t timer_delay = r4_event_loop_timer_delay(loop, now, &timer_found); if (timer_found && timer_delay < remaining) remaining = timer_delay; if (remaining == 0u) continue;
        uint64_t sequence = loop->activity_sequence; int32_t raw = ((R4DeskGuiActivityWaitFn)(uintptr_t)R4DESK_SLOT(&loop->app->desktop, gui_activity_wait))(loop->activity_sequence, remaining, R4OS_GUI_ACTIVITY_SHARED_CLIPBOARD, &sequence); loop->activity_sequence = sequence;
        if (raw < 0) { result.state = R4_MESSAGE_NEXT_FAILED; result.raw_code = raw; return result; }
    }
}

static inline R4MessageNext r4_window_wait_message(R4Window *window, R4Timeout timeout) {
    if (window == 0) { R4MessageNext failed = {0}; failed.state = R4_MESSAGE_NEXT_FAILED; failed.raw_code = R4OS_ERR_NO_FN; return failed; }
    return r4_event_loop_wait(&window->events, timeout);
}

static inline int r4_window_begin_paint(R4Window *window, R4PaintContext *out) {
    if (!window || !out || !window->app ||
        !r4draw_supports_gui_frame_contract(&window->app->drawing)) return 0;
    *out = (R4PaintContext){0}; out->window = window;
    if (r4desk_gui_window_info(&window->app->desktop, &out->info) < 0 || out->info.client_w <= 0 || out->info.client_h <= 0) return 0;
    if(window->events.action_view_pending){
        window->events.action_view_pending=0u;
        R4DesktopActionReply view={0};
        if(r4_desktop_action_app_view(window->app,window->id,&view)==0&&!view.result&&view.current.view_revision){
            R4GuiWindowInfo current={0};
            if(r4desk_gui_window_info(&window->app->desktop,&current)>=0){
                out->info=current;
                if(current.client_x==view.current.info.client_x&&current.client_y==view.current.info.client_y&&current.client_w==view.current.info.client_w&&current.client_h==view.current.info.client_h&&current.flags==view.current.info.flags){
                    out->action_view=view.request.token;out->action_view_revision=view.current.view_revision;out->action_view_valid=1u;
                }
            }
        }
    }
    if(out->info.client_w<=0||out->info.client_h<=0)return 0;
    if (r4draw_gui_frame_begin(&window->app->drawing) < 0) return 0;
    out->transactional = 1u; out->active = 1u; return 1;
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
static inline int32_t r4_paint_present(R4PaintContext *paint) {
    if (paint == 0 || !paint->active) return R4OS_ERR_NO_FN;
    int32_t raw=paint->transactional?r4draw_gui_frame_commit(&paint->window->app->drawing):r4draw_gui_present(&paint->window->app->drawing);
    if(raw>=0){
        paint->active=0u;
        if(paint->transactional&&paint->action_view_valid){
            R4GuiFrameInfo frame={0};R4DesktopActionReply reply={0};
            if(r4draw_gui_frame_info(&paint->window->app->drawing,&paint->action_view.window.owner,&frame)==0)
                (void)r4_desktop_action_app_frame(paint->window->app,&paint->action_view,paint->action_view_revision,frame.committed_generation,paint->info.client_w,paint->info.client_h,&reply);
        }
    }
    return raw;
}
static inline void r4_paint_discard(R4PaintContext *paint) { if (paint != 0) { if (paint->active && paint->transactional) (void)r4draw_gui_frame_cancel(&paint->window->app->drawing); paint->active = 0u; } }

#endif
