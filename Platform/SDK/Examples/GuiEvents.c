/* Public C facade only. Launch as a hosted GUI application from Desktop. */
#include <r4os/app_gui.h>

int32_t r4_app_main(R4App *app) {
    R4Window window;
    if (!r4_window_open(app, 0, 0, &window)) return 1;
    if (r4_window_set_title(&window, "C GUI events") < 0) return 1;
    int focused = 0, dirty = 1;
    for (;;) {
        if (dirty) {
            R4PaintContext paint;
            if (!r4_window_begin_paint(&window, &paint)) return 1;
            R4Canvas canvas = r4_paint_canvas(&paint);
            if (r4_canvas_clear(canvas, 0x182030) < 0 ||
                r4_canvas_text(canvas, 12, 16, focused ? "Focused" : "Unfocused", 0xffffff, 0x182030) < 0 ||
                r4_paint_present(&paint) < 0) {
                r4_paint_discard(&paint);
                return 1;
            }
            dirty = 0;
        }
        R4MessageNext next = r4_window_wait_message(&window, r4_timeout_forever());
        if (next.state == R4_MESSAGE_NEXT_FAILED) return 1;
        if (next.state != R4_MESSAGE_NEXT_MESSAGE) continue;
        switch (next.message.kind) {
            case R4_MESSAGE_CLOSE: return 0;
            case R4_MESSAGE_RESIZE: dirty = 1; break;
            case R4_MESSAGE_FOCUS_GAINED:
            case R4_MESSAGE_FOCUS_LOST:
                focused = next.message.kind == R4_MESSAGE_FOCUS_GAINED;
                (void)r4_window_set_title(&window, focused ? "C GUI focus gained" : "C GUI focus lost");
                dirty = 1;
                break;
            case R4_MESSAGE_FONT_CHANGED:
                /* The next paint reads the current font; no ID is in the event. */
                (void)r4_window_set_title(&window, "C GUI font changed");
                dirty = 1;
                break;
            default: break;
        }
    }
}
