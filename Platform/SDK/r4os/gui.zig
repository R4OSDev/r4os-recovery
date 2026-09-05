const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4sys = @import("r4sys.zig");
const r4desk = @import("r4desk.zig");
const r4draw = @import("r4draw.zig");

pub const font_w: i32 = 8;
pub const font_h: i32 = 8;
const clipboard_buffer_size: usize = @as(usize, abi.clipboard_max_text_bytes) + 1;

pub const Align = enum {
    left,
    center,
    right,
};

pub const Palette = struct {
    text: u32 = 0x000000,
    disabled_text: u32 = 0x707070,
    face: u32 = 0xC0C0C0,
    face_light: u32 = 0xFFFFFF,
    face_shadow: u32 = 0x808080,
    client_bg: u32 = 0xFFFFFF,
    select_bg: u32 = 0x000080,
    select_text: u32 = 0xFFFFFF,
    title_bg: u32 = 0x000080,
    title_text: u32 = 0xFFFFFF,
};

pub const default_palette = Palette{};

pub const ControlMetrics = struct {
    bevel: i32 = 1,
    frame_inset: i32 = 2,
    text_pad_x: i32 = 4,
    text_pad_y: i32 = 3,
    menu_text_pad_x: i32 = 8,
    menu_bar_h: i32 = 22,
    menu_bar_pad_x: i32 = 8,
    menu_popup_min_w: i32 = 96,
    dialog_title_h: i32 = 18,
    dialog_button_w: i32 = 72,
    dialog_button_h: i32 = 24,
    dialog_min_w: i32 = 160,
    dialog_min_h: i32 = 90,
    dialog_outer_pad: i32 = 10,
    dialog_button_gap: i32 = 8,
    dialog_button_margin: i32 = 12,
    dialog_status_h: i32 = 16,
    text_field_h: i32 = 22,
    list_row_h: i32 = 16,
    menu_row_h: i32 = 18,
    toolbar_button_w: i32 = 26,
    toolbar_button_h: i32 = 24,
    status_bar_h: i32 = 18,
    scrollbar_w: i32 = 16,
    tab_h: i32 = 22,
    table_header_h: i32 = 18,
    gap: i32 = 8,
};

pub const default_metrics = ControlMetrics{};

pub const FontMetrics = struct {
    id: u32 = abi.gui_font_builtin_id,
    max_advance: i32 = font_w,
    height: i32 = font_h,
    line_height: i32 = font_h,
    baseline: i32 = font_h - 1,
};

pub const Key = struct {
    pub const ctrl_a: u8 = 0x01;
    pub const ctrl_c: u8 = 0x03;
    pub const ctrl_v: u8 = 0x16;
    pub const ctrl_x: u8 = 0x18;
    pub const backspace: u8 = 0x08;
    pub const tab: u8 = '\t';
    pub const enter: u8 = '\r';
    pub const escape: u8 = 0x1B;
    pub const delete: u8 = 0x7F;
    pub const up: u8 = 0x80;
    pub const down: u8 = 0x81;
    pub const f3: u8 = 0x82;
    pub const shift_tab: u8 = 0x84;
    pub const left: u8 = 0x88;
    pub const right: u8 = 0x89;
    pub const home: u8 = 0x8A;
    pub const end: u8 = 0x8B;
    pub const start_menu: u8 = 0x8C;
    pub const page_up: u8 = 0x8D;
    pub const page_down: u8 = 0x8E;
    pub const menu_focus: u8 = 0x8F;
    pub const f10: u8 = 0x90;
};

pub const ControlAction = enum {
    none,
    clicked,
    changed,
    submitted,
    cancelled,
    selection_changed,
};

pub const FocusDirection = enum {
    next,
    previous,
};

pub const FocusItem = struct {
    enabled: bool = true,
};

pub const FocusResult = struct {
    action: ControlAction = .none,
    index: usize = 0,
};

pub const FocusState = struct {
    index: usize = 0,

    pub fn normalize(self: *FocusState, items: []const FocusItem) bool {
        if (items.len == 0) {
            self.index = 0;
            return false;
        }
        if (self.index < items.len and items[self.index].enabled) return true;
        if (firstEnabledFocusIndex(items)) |first| {
            self.index = first;
            return true;
        }
        self.index = 0;
        return false;
    }

    pub fn set(self: *FocusState, items: []const FocusItem, index: usize) bool {
        if (index >= items.len or !items[index].enabled) return false;
        self.index = index;
        return true;
    }

    pub fn move(self: *FocusState, items: []const FocusItem, direction: FocusDirection) bool {
        if (items.len == 0) return false;
        const start = if (self.index < items.len) self.index else 0;
        var current = start;
        var steps: usize = 0;
        while (steps < items.len) : (steps += 1) {
            current = switch (direction) {
                .next => if (current + 1 >= items.len) 0 else current + 1,
                .previous => if (current == 0) items.len - 1 else current - 1,
            };
            if (items[current].enabled) {
                self.index = current;
                return current != start or !items[start].enabled;
            }
        }
        return false;
    }

    pub fn handleKey(self: *FocusState, items: []const FocusItem, key: u8) FocusResult {
        if (!self.normalize(items)) return .{};
        return switch (key) {
            Key.tab => if (self.move(items, .next)) .{ .action = .changed, .index = self.index } else .{ .index = self.index },
            Key.shift_tab => if (self.move(items, .previous)) .{ .action = .changed, .index = self.index } else .{ .index = self.index },
            Key.enter => .{ .action = .submitted, .index = self.index },
            Key.escape => .{ .action = .cancelled, .index = self.index },
            ' ' => .{ .action = .clicked, .index = self.index },
            else => .{ .index = self.index },
        };
    }
};

pub const MouseCapture = struct {
    target: ?usize = null,
    action: ControlAction = .none,

    pub fn begin(self: *MouseCapture, target: usize, action: ControlAction) void {
        self.target = target;
        self.action = action;
    }

    pub fn release(self: *MouseCapture, target: usize, hot: bool) ControlAction {
        if (self.target == null or self.target.? != target) return .none;
        const result = if (hot) self.action else .none;
        self.clear();
        return result;
    }

    pub fn clear(self: *MouseCapture) void {
        self.target = null;
        self.action = .none;
    }

    pub fn isActive(self: MouseCapture, target: usize) bool {
        return self.target != null and self.target.? == target;
    }
};

pub const SelectionStep = struct {
    action: ControlAction = .none,
    index: usize = 0,
};

pub const TextRange = struct {
    start: usize = 0,
    end: usize = 0,

    pub fn normalized(start: usize, end: usize) TextRange {
        return if (start <= end) .{ .start = start, .end = end } else .{ .start = end, .end = start };
    }

    pub fn isEmpty(self: TextRange) bool {
        return self.start >= self.end;
    }

    pub fn count(self: TextRange) usize {
        return if (self.end > self.start) self.end - self.start else 0;
    }
};

pub const TextAreaPoint = struct {
    line: usize = 0,
    column: usize = 0,
};

pub const TextAreaView = struct {
    visible_cols: usize = 80,
    visible_rows: usize = 25,
    wrap_cols: usize = 80,

    pub fn init(visible_cols: usize, visible_rows: usize) TextAreaView {
        const cols = @max(@as(usize, 1), visible_cols);
        return .{
            .visible_cols = cols,
            .visible_rows = @max(@as(usize, 1), visible_rows),
            .wrap_cols = cols,
        };
    }

    pub fn effectiveVisibleCols(self: TextAreaView) usize {
        return @max(@as(usize, 1), self.visible_cols);
    }

    pub fn effectiveVisibleRows(self: TextAreaView) usize {
        return @max(@as(usize, 1), self.visible_rows);
    }

    pub fn effectiveWrapCols(self: TextAreaView) usize {
        if (self.wrap_cols == 0) return std.math.maxInt(usize) / 4;
        return @max(@as(usize, 1), self.wrap_cols);
    }
};

pub const MenuKeyResult = struct {
    action: ControlAction = .none,
    index: ?usize = null,
    command_id: u32 = 0,
};

pub const MenubarResult = struct {
    action: ControlAction = .none,
    menu_index: ?usize = null,
    item_index: ?usize = null,
    command_id: u32 = 0,

    pub fn hasCommand(self: MenubarResult) bool {
        return self.action == .submitted and self.menu_index != null and self.item_index != null;
    }
};

pub const MenubarHitPart = enum {
    none,
    header,
    item,
    backdrop,
};

pub const MenubarHit = struct {
    part: MenubarHitPart = .none,
    menu_index: ?usize = null,
    item_index: ?usize = null,
    command_id: u32 = 0,
};

pub const Rect = struct {
    x: i32 = 0,
    y: i32 = 0,
    w: i32 = 0,
    h: i32 = 0,

    pub fn isEmpty(self: Rect) bool {
        return self.w <= 0 or self.h <= 0;
    }

    pub fn inset(self: Rect, dx: i32, dy: i32) Rect {
        return .{
            .x = self.x + dx,
            .y = self.y + dy,
            .w = @max(0, self.w - dx * 2),
            .h = @max(0, self.h - dy * 2),
        };
    }

    pub fn contains(self: Rect, x: i32, y: i32) bool {
        return x >= self.x and y >= self.y and x < self.x + self.w and y < self.y + self.h;
    }

    pub fn right(self: Rect) i32 {
        return self.x + self.w;
    }

    pub fn bottom(self: Rect) i32 {
        return self.y + self.h;
    }

    pub fn translated(self: Rect, dx: i32, dy: i32) Rect {
        return .{
            .x = self.x + dx,
            .y = self.y + dy,
            .w = self.w,
            .h = self.h,
        };
    }
};

pub const LayoutCursor = struct {
    remaining_rect: Rect,

    pub fn init(rect: Rect) LayoutCursor {
        return .{ .remaining_rect = rect };
    }

    pub fn remaining(self: LayoutCursor) Rect {
        return self.remaining_rect;
    }

    pub fn takeTop(self: *LayoutCursor, height: i32, gap: i32) Rect {
        const h = @min(@max(0, height), @max(0, self.remaining_rect.h));
        const result = Rect{ .x = self.remaining_rect.x, .y = self.remaining_rect.y, .w = self.remaining_rect.w, .h = h };
        const consumed = @min(self.remaining_rect.h, h + @max(0, gap));
        self.remaining_rect.y += consumed;
        self.remaining_rect.h = @max(0, self.remaining_rect.h - consumed);
        return result;
    }

    pub fn takeBottom(self: *LayoutCursor, height: i32, gap: i32) Rect {
        const h = @min(@max(0, height), @max(0, self.remaining_rect.h));
        const result = Rect{ .x = self.remaining_rect.x, .y = self.remaining_rect.y + self.remaining_rect.h - h, .w = self.remaining_rect.w, .h = h };
        const consumed = @min(self.remaining_rect.h, h + @max(0, gap));
        self.remaining_rect.h = @max(0, self.remaining_rect.h - consumed);
        return result;
    }

    pub fn takeLeft(self: *LayoutCursor, width: i32, gap: i32) Rect {
        const w = @min(@max(0, width), @max(0, self.remaining_rect.w));
        const result = Rect{ .x = self.remaining_rect.x, .y = self.remaining_rect.y, .w = w, .h = self.remaining_rect.h };
        const consumed = @min(self.remaining_rect.w, w + @max(0, gap));
        self.remaining_rect.x += consumed;
        self.remaining_rect.w = @max(0, self.remaining_rect.w - consumed);
        return result;
    }

    pub fn takeRight(self: *LayoutCursor, width: i32, gap: i32) Rect {
        const w = @min(@max(0, width), @max(0, self.remaining_rect.w));
        const result = Rect{ .x = self.remaining_rect.x + self.remaining_rect.w - w, .y = self.remaining_rect.y, .w = w, .h = self.remaining_rect.h };
        const consumed = @min(self.remaining_rect.w, w + @max(0, gap));
        self.remaining_rect.w = @max(0, self.remaining_rect.w - consumed);
        return result;
    }
};

pub const HostedAppFrame = struct {
    info: abi.GuiWindowInfo = .{},
    canvas: Canvas,
    client: Rect = .{},
    should_close: bool = false,

    pub fn refresh(self: *HostedAppFrame, sys: *const r4sys.Context, desk: *const r4desk.Context, draw: *const r4draw.Context, fallback_w: i32, fallback_h: i32) void {
        self.* = hostedAppFrame(sys, desk, draw, fallback_w, fallback_h);
    }
};

pub const Label = struct {
    rect: Rect,
    text: []const u8,
    alignment: Align = .left,
    disabled: bool = false,
    fg: u32 = default_palette.text,
    bg: u32 = default_palette.client_bg,
    palette: Palette = default_palette,

    pub fn draw(self: Label, canvas: Canvas, scratch: []u8) i32 {
        const fg = if (self.disabled) self.palette.disabled_text else self.fg;
        return drawTextInRect(canvas, self.rect, scratch, self.text, self.alignment, fg, self.bg);
    }
};

pub const ButtonState = enum {
    normal,
    hover,
    pressed,
    disabled,
};

pub const Button = struct {
    rect: Rect,
    text: []const u8,
    state: ButtonState = .normal,
    focused: bool = false,
    is_default: bool = false,
    is_cancel: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: Button, canvas: Canvas, scratch: []u8) i32 {
        return drawButtonEx(canvas, self.rect, scratch, self.text, self.state, self.focused, self.is_default, self.is_cancel, self.palette);
    }

    pub fn contains(self: Button, x: i32, y: i32) bool {
        return self.state != .disabled and self.rect.contains(x, y);
    }

    pub fn minWidth(self: Button) i32 {
        return buttonMinWidth(self.text);
    }
};

pub const List = struct {
    rect: Rect,
    items: []const []const u8,
    selected_index: usize = 0,
    hover_index: ?usize = null,
    first_index: usize = 0,
    disabled_index: ?usize = null,
    focused: bool = false,
    row_h: i32 = 16,
    palette: Palette = default_palette,

    pub fn draw(self: List, canvas: Canvas, scratch: []u8) i32 {
        const result = drawListEx(canvas, self.rect, scratch, self.items, self.selected_index, self.hover_index, self.first_index, self.disabled_index, self.row_h, self.palette);
        if (self.focused) drawFocusRect(canvas, self.rect.inset(3, 3), self.palette);
        return result;
    }

    pub fn indexAt(self: List, x: i32, y: i32) ?usize {
        return listIndexAtEx(self.rect, self.items.len, self.first_index, self.disabled_index, self.row_h, x, y);
    }

    pub fn visibleRows(self: List) usize {
        return visibleListRows(self.rect, self.row_h);
    }

    pub fn firstIndexForSelection(self: List) usize {
        return listFirstIndexForSelection(self.items.len, self.visibleRows(), self.selected_index, self.first_index);
    }

    pub fn keyAction(self: List, key: u8) SelectionStep {
        _ = self.first_index;
        if (key == Key.enter) return .{ .action = .submitted, .index = self.selected_index };
        return selectionStep(self.items.len, self.selected_index, key);
    }
};

pub const Orientation = enum {
    vertical,
    horizontal,
};

pub const ScrollbarPart = enum {
    none,
    decrement,
    increment,
    page_decrement,
    page_increment,
    thumb,
};

pub const ScrollbarStep = struct {
    action: ControlAction = .none,
    first_index: usize = 0,
    part: ScrollbarPart = .none,
};

pub const Scrollbar = struct {
    rect: Rect,
    orientation: Orientation = .vertical,
    total_items: usize = 0,
    visible_items: usize = 0,
    first_index: usize = 0,
    disabled: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: Scrollbar, canvas: Canvas, scratch: []u8) i32 {
        return drawScrollbar(canvas, self, scratch);
    }

    pub fn maxFirst(self: Scrollbar) usize {
        if (self.total_items <= self.visible_items) return 0;
        return self.total_items - self.visible_items;
    }

    pub fn clampedFirst(self: Scrollbar) usize {
        return @min(self.first_index, self.maxFirst());
    }

    pub fn decrementRect(self: Scrollbar) Rect {
        return scrollbarButtonRect(self.rect, self.orientation, .decrement);
    }

    pub fn incrementRect(self: Scrollbar) Rect {
        return scrollbarButtonRect(self.rect, self.orientation, .increment);
    }

    pub fn trackRect(self: Scrollbar) Rect {
        return scrollbarTrackRect(self.rect, self.orientation);
    }

    pub fn thumbRect(self: Scrollbar) Rect {
        return scrollbarThumbRect(self.rect, self.orientation, self.total_items, self.visible_items, self.first_index);
    }

    pub fn partAt(self: Scrollbar, x: i32, y: i32) ScrollbarPart {
        return scrollbarPartAt(self, x, y);
    }

    pub fn step(self: Scrollbar, part: ScrollbarPart) ScrollbarStep {
        return scrollbarStep(self, part);
    }

    pub fn wheel(self: Scrollbar, delta: i32) ScrollbarStep {
        if (delta == 0) return .{ .first_index = self.clampedFirst() };
        return self.step(if (delta > 0) .decrement else .increment);
    }
};

pub const ToolbarButton = struct {
    rect: Rect,
    text: []const u8,
    state: ButtonState = .normal,
    focused: bool = false,
    selected: bool = false,
    disabled: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: ToolbarButton, canvas: Canvas, scratch: []u8) i32 {
        const state = if (self.disabled) ButtonState.disabled else if (self.selected and self.state == .normal) ButtonState.pressed else self.state;
        return drawToolbarButton(canvas, self.rect, scratch, self.text, state, self.focused, self.selected, self.palette);
    }

    pub fn contains(self: ToolbarButton, x: i32, y: i32) bool {
        return !self.disabled and self.rect.contains(x, y);
    }
};

pub const TabItem = struct {
    text: []const u8,
    enabled: bool = true,
};

pub const TabBar = struct {
    rect: Rect,
    items: []const TabItem,
    selected_index: usize = 0,
    hover_index: ?usize = null,
    focused: bool = false,
    tab_h: i32 = 22,
    palette: Palette = default_palette,

    pub fn draw(self: TabBar, canvas: Canvas, scratch: []u8) i32 {
        return drawTabBar(canvas, self, scratch);
    }

    pub fn tabRect(self: TabBar, index: usize) Rect {
        return tabBarItemRect(self.rect, self.items, index, self.tab_h);
    }

    pub fn indexAt(self: TabBar, x: i32, y: i32) ?usize {
        return tabBarIndexAt(self.rect, self.items, self.tab_h, x, y);
    }

    pub fn keyAction(self: TabBar, key: u8) SelectionStep {
        if (self.items.len == 0) return .{};
        const selected = @min(self.selected_index, self.items.len - 1);
        const next_index = switch (key) {
            Key.left, Key.up => enabledTabIndex(self.items, selected, .previous) orelse selected,
            Key.right, Key.down => enabledTabIndex(self.items, selected, .next) orelse selected,
            Key.home => firstEnabledTabIndex(self.items) orelse selected,
            Key.end => lastEnabledTabIndex(self.items) orelse selected,
            Key.enter, ' ' => return .{ .action = .submitted, .index = selected },
            else => return .{ .index = selected },
        };
        return .{
            .action = if (next_index == selected) .none else .selection_changed,
            .index = next_index,
        };
    }
};

pub const TableColumn = struct {
    title: []const u8,
    width: i32 = 80,
    alignment: Align = .left,
};

pub const TableView = struct {
    rect: Rect,
    columns: []const TableColumn,
    cells: []const []const u8,
    row_count: usize = 0,
    selected_index: usize = 0,
    hover_index: ?usize = null,
    first_index: usize = 0,
    focused: bool = false,
    row_h: i32 = 16,
    header_h: i32 = 18,
    palette: Palette = default_palette,

    pub fn draw(self: TableView, canvas: Canvas, scratch: []u8) i32 {
        return drawTableView(canvas, self, scratch);
    }

    pub fn effectiveRowCount(self: TableView) usize {
        if (self.row_count != 0) return self.row_count;
        if (self.columns.len == 0) return 0;
        return @divTrunc(self.cells.len, self.columns.len);
    }

    pub fn headerRect(self: TableView) Rect {
        return tableHeaderRect(self.rect, self.header_h);
    }

    pub fn bodyRect(self: TableView) Rect {
        return tableBodyRect(self.rect, self.header_h, self.needsScrollbar());
    }

    pub fn scrollbarRect(self: TableView) Rect {
        return tableScrollbarRect(self.rect, self.header_h);
    }

    pub fn needsScrollbar(self: TableView) bool {
        return self.effectiveRowCount() > self.visibleRows();
    }

    pub fn visibleRows(self: TableView) usize {
        return visibleTableRows(tableBodyRect(self.rect, self.header_h, false), self.row_h);
    }

    pub fn indexAt(self: TableView, x: i32, y: i32) ?usize {
        return listIndexAtEx(self.bodyRect(), self.effectiveRowCount(), self.first_index, null, self.row_h, x, y);
    }

    pub fn firstIndexForSelection(self: TableView) usize {
        return listFirstIndexForSelection(self.effectiveRowCount(), self.visibleRows(), self.selected_index, self.first_index);
    }

    pub fn keyAction(self: TableView, key: u8) SelectionStep {
        if (key == Key.enter) return .{ .action = .submitted, .index = self.selected_index };
        return selectionStepPaged(self.effectiveRowCount(), self.visibleRows(), self.selected_index, key);
    }

    pub fn cell(self: TableView, row: usize, column: usize) []const u8 {
        if (column >= self.columns.len) return "";
        const index = row * self.columns.len + column;
        if (index >= self.cells.len) return "";
        return self.cells[index];
    }
};

pub const Checkbox = struct {
    rect: Rect,
    text: []const u8,
    checked: bool = false,
    disabled: bool = false,
    focused: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: Checkbox, canvas: Canvas, scratch: []u8) i32 {
        return drawCheckbox(canvas, self.rect, scratch, self.text, self.checked, self.disabled, self.focused, self.palette);
    }

    pub fn contains(self: Checkbox, x: i32, y: i32) bool {
        return !self.disabled and self.rect.contains(x, y);
    }
};

pub const RadioButton = struct {
    rect: Rect,
    text: []const u8,
    selected: bool = false,
    disabled: bool = false,
    focused: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: RadioButton, canvas: Canvas, scratch: []u8) i32 {
        return drawRadioButton(canvas, self.rect, scratch, self.text, self.selected, self.disabled, self.focused, self.palette);
    }

    pub fn contains(self: RadioButton, x: i32, y: i32) bool {
        return !self.disabled and self.rect.contains(x, y);
    }
};

pub const GroupBox = struct {
    rect: Rect,
    title: []const u8 = "",
    palette: Palette = default_palette,

    pub fn draw(self: GroupBox, canvas: Canvas, scratch: []u8) i32 {
        return drawGroupBox(canvas, self.rect, scratch, self.title, self.palette);
    }
};

pub const Separator = struct {
    rect: Rect,
    vertical: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: Separator, canvas: Canvas) i32 {
        return drawSeparator(canvas, self.rect, self.vertical, self.palette);
    }
};

pub const Dropdown = struct {
    rect: Rect,
    items: []const []const u8,
    selected_index: usize = 0,
    hover_index: ?usize = null,
    first_index: usize = 0,
    max_visible_rows: usize = 0,
    open: bool = false,
    disabled: bool = false,
    focused: bool = false,
    palette: Palette = default_palette,

    pub fn draw(self: Dropdown, canvas: Canvas, scratch: []u8) i32 {
        return drawDropdownEx(canvas, self.rect, scratch, self.items, self.selected_index, self.hover_index, self.first_index, self.max_visibleRows(), self.open, self.disabled, self.focused, self.palette);
    }

    pub fn contains(self: Dropdown, x: i32, y: i32) bool {
        return !self.disabled and self.rect.contains(x, y);
    }

    pub fn listRect(self: Dropdown) Rect {
        return dropdownListRectEx(self.rect, self.items.len, self.max_visibleRows());
    }

    pub fn indexAt(self: Dropdown, x: i32, y: i32) ?usize {
        if (!self.open or self.disabled) return null;
        return listIndexAtEx(self.listRect(), self.items.len, self.first_index, null, default_metrics.list_row_h, x, y);
    }

    pub fn keyAction(self: Dropdown, key: u8) SelectionStep {
        if (self.disabled) return .{};
        return switch (key) {
            Key.escape => .{ .action = .cancelled, .index = self.selected_index },
            Key.enter, ' ' => .{ .action = .submitted, .index = self.selected_index },
            else => selectionStep(self.items.len, self.selected_index, key),
        };
    }

    pub fn firstIndexForSelection(self: Dropdown) usize {
        return listFirstIndexForSelection(self.items.len, self.visibleRows(), self.selected_index, self.first_index);
    }

    pub fn visibleRows(self: Dropdown) usize {
        return visibleListRows(self.listRect(), default_metrics.list_row_h);
    }

    fn max_visibleRows(self: Dropdown) usize {
        if (self.max_visible_rows == 0) return self.items.len;
        return self.max_visible_rows;
    }
};

pub const MenuItem = struct {
    text: []const u8,
    id: u32 = 0,
    shortcut: []const u8 = "",
    enabled: bool = true,
    separator_before: bool = false,
};

pub const Menu = struct {
    rect: Rect,
    items: []const MenuItem,
    selected_index: ?usize = null,
    hover_index: ?usize = null,
    row_h: i32 = 18,
    palette: Palette = default_palette,

    pub fn draw(self: Menu, canvas: Canvas, scratch: []u8) i32 {
        return drawMenuEx(canvas, self.rect, scratch, self.items, self.selected_index, self.hover_index, self.row_h, self.palette);
    }

    pub fn indexAt(self: Menu, x: i32, y: i32) ?usize {
        return menuIndexAt(self.rect, self.items, self.row_h, x, y);
    }

    pub fn keyAction(self: Menu, key: u8) MenuKeyResult {
        return menuKeyAction(self.items, self.selected_index, key);
    }
};

pub const MenubarMenu = struct {
    text: []const u8,
    items: []const MenuItem,
    enabled: bool = true,
    min_popup_w: i32 = 0,
};

pub const MenubarState = struct {
    active_menu: ?usize = null,
    selected_item: ?usize = null,
    hover_menu: ?usize = null,
    pressed_menu: ?usize = null,
    keyboard_active: bool = false,

    pub fn isOpen(self: MenubarState) bool {
        return self.active_menu != null;
    }

    pub fn close(self: *MenubarState) void {
        self.active_menu = null;
        self.selected_item = null;
        self.hover_menu = null;
        self.pressed_menu = null;
        self.keyboard_active = false;
    }

    pub fn open(self: *MenubarState, menus: []const MenubarMenu, menu_index: usize, keyboard: bool) bool {
        if (!menubarMenuEnabled(menus, menu_index)) return false;
        self.active_menu = menu_index;
        self.hover_menu = menu_index;
        self.pressed_menu = menu_index;
        self.keyboard_active = keyboard;
        self.selected_item = enabledMenuIndex(menus[menu_index].items, null, .next);
        return true;
    }

    pub fn openFirst(self: *MenubarState, menus: []const MenubarMenu) bool {
        const index = firstEnabledMenubarMenu(menus) orelse return false;
        return self.open(menus, index, true);
    }

    pub fn switchMenu(self: *MenubarState, menus: []const MenubarMenu, direction: FocusDirection) bool {
        const next = enabledMenubarMenuIndex(menus, self.active_menu, direction) orelse return false;
        return self.open(menus, next, self.keyboard_active);
    }

    pub fn keyAction(self: *MenubarState, menus: []const MenubarMenu, key: u8) MenubarResult {
        if (menus.len == 0) return .{};
        if (!self.isOpen()) {
            if (key == Key.menu_focus or key == Key.f10) {
                if (self.openFirst(menus)) return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            }
            return .{};
        }

        const active = self.active_menu orelse return .{};
        switch (key) {
            Key.escape, Key.menu_focus, Key.f10 => {
                self.close();
                return .{ .action = .cancelled };
            },
            Key.left => {
                _ = self.switchMenu(menus, .previous);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            Key.right => {
                _ = self.switchMenu(menus, .next);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            Key.up => {
                self.selected_item = enabledMenuIndex(menus[active].items, self.selected_item, .previous);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            Key.down => {
                self.selected_item = enabledMenuIndex(menus[active].items, self.selected_item, .next);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            Key.home => {
                self.selected_item = enabledMenuIndex(menus[active].items, null, .next);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            Key.end => {
                self.selected_item = enabledMenuIndex(menus[active].items, null, .previous);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            Key.enter, ' ' => {
                const result = self.commandResult(menus);
                if (result.hasCommand()) self.close();
                return result;
            },
            else => return .{ .menu_index = self.active_menu, .item_index = self.selected_item },
        }
    }

    pub fn mouseMove(self: *MenubarState, rect: Rect, menus: []const MenubarMenu, x: i32, y: i32) MenubarResult {
        const hit = menubarHitTest(rect, menus, self.active_menu, x, y);
        switch (hit.part) {
            .header => {
                self.hover_menu = hit.menu_index;
                if (self.isOpen() and hit.menu_index != null) _ = self.open(menus, hit.menu_index.?, false);
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            .item => {
                self.hover_menu = hit.menu_index;
                self.active_menu = hit.menu_index;
                self.selected_item = hit.item_index;
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
            },
            else => return .{ .menu_index = self.active_menu, .item_index = self.selected_item },
        }
    }

    pub fn mouseDown(self: *MenubarState, rect: Rect, menus: []const MenubarMenu, x: i32, y: i32) MenubarResult {
        const hit = menubarHitTest(rect, menus, self.active_menu, x, y);
        switch (hit.part) {
            .header => {
                if (hit.menu_index) |menu_index| {
                    if (self.active_menu != null and self.active_menu.? == menu_index) {
                        self.close();
                        return .{ .action = .cancelled };
                    }
                    _ = self.open(menus, menu_index, false);
                    return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item };
                }
            },
            .item => {
                self.active_menu = hit.menu_index;
                self.selected_item = hit.item_index;
                return .{ .action = .selection_changed, .menu_index = self.active_menu, .item_index = self.selected_item, .command_id = hit.command_id };
            },
            .backdrop => {
                self.close();
                return .{ .action = .cancelled };
            },
            else => {},
        }
        return .{};
    }

    pub fn mouseUp(self: *MenubarState, rect: Rect, menus: []const MenubarMenu, x: i32, y: i32) MenubarResult {
        const hit = menubarHitTest(rect, menus, self.active_menu, x, y);
        if (hit.part == .item and hit.menu_index != null and hit.item_index != null) {
            const result = MenubarResult{ .action = .submitted, .menu_index = hit.menu_index, .item_index = hit.item_index, .command_id = hit.command_id };
            self.close();
            return result;
        }
        return .{ .menu_index = self.active_menu, .item_index = self.selected_item };
    }

    fn commandResult(self: MenubarState, menus: []const MenubarMenu) MenubarResult {
        const menu_index = self.active_menu orelse return .{};
        if (menu_index >= menus.len) return .{};
        const item_index = self.selected_item orelse return .{ .menu_index = menu_index };
        if (item_index >= menus[menu_index].items.len) return .{ .menu_index = menu_index };
        const item = menus[menu_index].items[item_index];
        if (!menuItemActionable(item)) return .{ .menu_index = menu_index, .item_index = item_index };
        return .{ .action = .submitted, .menu_index = menu_index, .item_index = item_index, .command_id = item.id };
    }
};

pub const Menubar = struct {
    rect: Rect,
    menus: []const MenubarMenu,
    state: MenubarState = .{},
    palette: Palette = default_palette,

    pub fn draw(self: Menubar, canvas: Canvas, scratch: []u8) i32 {
        return drawMenubar(canvas, self.rect, scratch, self.menus, self.state, self.palette);
    }

    pub fn headerRect(self: Menubar, index: usize) Rect {
        return menubarHeaderRect(self.rect, self.menus, index);
    }

    pub fn popupRect(self: Menubar, index: usize) Rect {
        return menubarPopupRect(self.rect, self.menus, index);
    }

    pub fn menuIndexAt(self: Menubar, x: i32, y: i32) ?usize {
        return menubarMenuIndexAt(self.rect, self.menus, x, y);
    }

    pub fn hitTest(self: Menubar, x: i32, y: i32) MenubarHit {
        return menubarHitTest(self.rect, self.menus, self.state.active_menu, x, y);
    }
};

pub const DialogAction = enum {
    none,
    ok,
    cancel,
    select,
    previous,
    next,
    yes,
    no,
};

pub const DialogButtonRole = enum {
    normal,
    default,
    cancel,
};

pub const DialogButtonAlign = enum {
    center,
    right,
};

pub const DialogButton = struct {
    action: DialogAction = .none,
    text: []const u8 = "",
    role: DialogButtonRole = .normal,
    enabled: bool = true,
};

pub const DialogFocusItem = struct {
    action: DialogAction = .none,
    enabled: bool = true,
};

pub const DialogEvent = struct {
    action: DialogAction = .none,
    focus_action: DialogAction = .none,
    pressed_action: DialogAction = .none,
    captured: bool = false,
};

pub const ModalHitPart = enum {
    none,
    backdrop,
    frame,
    title,
    content,
    button,
};

pub const ModalHit = struct {
    part: ModalHitPart = .none,
    action: DialogAction = .none,
};

pub const DialogState = struct {
    focus_action: DialogAction = .none,
    pressed_action: DialogAction = .none,

    pub fn normalizeFocus(self: *DialogState, items: []const DialogFocusItem) void {
        if (dialogFocusIndex(items, self.focus_action) == null) {
            self.focus_action = dialogFirstFocusAction(items);
        }
    }

    pub fn keyAction(self: *DialogState, items: []const DialogFocusItem, buttons: []const DialogButton, key: u8) DialogAction {
        self.normalizeFocus(items);
        return switch (key) {
            Key.tab => blk: {
                self.focus_action = dialogFocusStep(items, self.focus_action, .next);
                break :blk .next;
            },
            Key.shift_tab => blk: {
                self.focus_action = dialogFocusStep(items, self.focus_action, .previous);
                break :blk .previous;
            },
            Key.enter, '\n', ' ' => dialogSubmitAction(buttons, self.focus_action),
            Key.escape => dialogCancelAction(buttons),
            else => .none,
        };
    }

    pub fn mouseDown(self: *DialogState, dialog: ModalDialog, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) DialogEvent {
        if (!dialog.rect.contains(x, y)) {
            self.pressed_action = .none;
            return .{ .focus_action = self.focus_action, .captured = true };
        }
        const action = dialog.buttonActionAt(buttons, button_align, x, y);
        if (action != .none) {
            self.focus_action = action;
            self.pressed_action = action;
        }
        return .{ .focus_action = self.focus_action, .pressed_action = self.pressed_action, .captured = true };
    }

    pub fn mouseUp(self: *DialogState, dialog: ModalDialog, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) DialogEvent {
        const pressed = self.pressed_action;
        self.pressed_action = .none;
        if (pressed == .none) return .{ .focus_action = self.focus_action, .captured = dialog.rect.contains(x, y) };
        const released = dialog.buttonActionAt(buttons, button_align, x, y);
        return .{
            .action = if (released == pressed) released else .none,
            .focus_action = self.focus_action,
            .pressed_action = self.pressed_action,
            .captured = true,
        };
    }
};

pub const ModalDialog = struct {
    rect: Rect,
    title: []const u8 = "",
    focus_action: DialogAction = .none,
    pressed_action: DialogAction = .none,
    palette: Palette = default_palette,

    pub fn centered(parent: Rect, width: i32, height: i32, title: []const u8) ModalDialog {
        return .{ .rect = modalDialogRect(parent, width, height), .title = title };
    }

    pub fn titleRect(self: ModalDialog) Rect {
        return dialogTitleRect(self.rect);
    }

    pub fn contentRect(self: ModalDialog) Rect {
        return dialogContentRect(self.rect);
    }

    pub fn buttonBarRect(self: ModalDialog) Rect {
        return dialogButtonBarRect(self.rect);
    }

    pub fn statusRect(self: ModalDialog) Rect {
        return dialogStatusRect(self.rect);
    }

    pub fn buttonRect(self: ModalDialog, count: usize, index: usize, button_align: DialogButtonAlign) Rect {
        return dialogButtonRect(self.rect, count, index, button_align);
    }

    pub fn buttonActionAt(self: ModalDialog, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) DialogAction {
        return dialogButtonActionAt(self.rect, buttons, button_align, x, y);
    }

    pub fn hitTest(self: ModalDialog, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) ModalHit {
        if (!self.rect.contains(x, y)) return .{ .part = .backdrop };
        const action = self.buttonActionAt(buttons, button_align, x, y);
        if (action != .none) return .{ .part = .button, .action = action };
        if (self.titleRect().contains(x, y)) return .{ .part = .title };
        if (self.contentRect().contains(x, y)) return .{ .part = .content };
        return .{ .part = .frame };
    }

    pub fn drawFrame(self: ModalDialog, canvas: Canvas, scratch: []u8) i32 {
        return drawDialogFrame(canvas, self.rect, scratch, self.title, self.palette);
    }

    pub fn drawButtons(self: ModalDialog, canvas: Canvas, scratch: []u8, buttons: []const DialogButton, button_align: DialogButtonAlign) i32 {
        return drawDialogButtons(canvas, self.rect, scratch, buttons, self.focus_action, self.pressed_action, button_align, self.palette);
    }
};

pub const ModalOverlay = struct {
    bounds: Rect,
    dialog: ModalDialog,
    active: bool = true,
    close_on_backdrop: bool = false,

    pub fn capturesInput(self: ModalOverlay, x: i32, y: i32) bool {
        return self.active and self.bounds.contains(x, y);
    }

    pub fn hitTest(self: ModalOverlay, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) ModalHit {
        if (!self.capturesInput(x, y)) return .{};
        return self.dialog.hitTest(buttons, button_align, x, y);
    }

    pub fn actionAt(self: ModalOverlay, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) DialogAction {
        const hit = self.hitTest(buttons, button_align, x, y);
        if (hit.part == .button) return hit.action;
        if (hit.part == .backdrop and self.close_on_backdrop) return .cancel;
        return .none;
    }
};

pub const MessageKind = enum {
    info,
    warning,
    failure,
    question,
};

pub const MessageButtons = enum {
    ok,
    ok_cancel,
    yes_no,
};

pub const FileDialogMode = enum {
    open,
    save,
};

pub const MessageDialog = struct {
    rect: Rect,
    title: []const u8,
    message: []const u8,
    kind: MessageKind = .info,
    buttons: MessageButtons = .ok,
    ok_text: []const u8 = "OK",
    cancel_text: []const u8 = "Cancel",
    yes_text: []const u8 = "Yes",
    no_text: []const u8 = "No",
    ok_pressed: bool = false,
    pressed_action: DialogAction = .none,
    palette: Palette = default_palette,

    pub fn draw(self: MessageDialog, canvas: Canvas, scratch: []u8) i32 {
        return drawMessageBox(canvas, self.rect, scratch, self.title, self.message, self.kind, self.buttons, self.ok_text, self.cancel_text, self.yes_text, self.no_text, self.pressedAction(), self.palette);
    }

    pub fn okRect(self: MessageDialog) Rect {
        return messageDialogOkRectFor(self.rect, self.buttons);
    }

    pub fn yesRect(self: MessageDialog) Rect {
        return dialogButtonRect(self.rect, 2, 0, .right);
    }

    pub fn noRect(self: MessageDialog) Rect {
        return dialogButtonRect(self.rect, 2, 1, .right);
    }

    pub fn cancelRect(self: MessageDialog) Rect {
        return messageDialogCancelRect(self.rect);
    }

    pub fn actionAt(self: MessageDialog, x: i32, y: i32) DialogAction {
        return switch (self.buttons) {
            .ok => blk: {
                const buttons = [_]DialogButton{.{ .action = .ok, .text = self.ok_text, .role = .default }};
                break :blk dialogButtonActionAt(self.rect, buttons[0..], .center, x, y);
            },
            .ok_cancel => blk: {
                const buttons = [_]DialogButton{
                    .{ .action = .ok, .text = self.ok_text, .role = .default },
                    .{ .action = .cancel, .text = self.cancel_text, .role = .cancel },
                };
                break :blk dialogButtonActionAt(self.rect, buttons[0..], .right, x, y);
            },
            .yes_no => blk: {
                const buttons = [_]DialogButton{
                    .{ .action = .yes, .text = self.yes_text, .role = .default },
                    .{ .action = .no, .text = self.no_text, .role = .cancel },
                };
                break :blk dialogButtonActionAt(self.rect, buttons[0..], .right, x, y);
            },
        };
    }

    pub fn keyAction(self: MessageDialog, key: u8) DialogAction {
        switch (self.buttons) {
            .ok => {
                const buttons = [_]DialogButton{.{ .action = .ok, .text = self.ok_text, .role = .default }};
                return dialogKeyAction(buttons[0..], .ok, key);
            },
            .ok_cancel => {
                const buttons = [_]DialogButton{
                    .{ .action = .ok, .text = self.ok_text, .role = .default },
                    .{ .action = .cancel, .text = self.cancel_text, .role = .cancel },
                };
                return dialogKeyAction(buttons[0..], .ok, key);
            },
            .yes_no => {
                const buttons = [_]DialogButton{
                    .{ .action = .yes, .text = self.yes_text, .role = .default },
                    .{ .action = .no, .text = self.no_text, .role = .cancel },
                };
                if (key == 'y' or key == 'Y') return .yes;
                if (key == 'n' or key == 'N') return .no;
                return dialogKeyAction(buttons[0..], .yes, key);
            },
        }
    }

    fn pressedAction(self: MessageDialog) DialogAction {
        if (self.pressed_action != .none) return self.pressed_action;
        if (self.ok_pressed) return .ok;
        return .none;
    }
};

pub const FileDialog = struct {
    rect: Rect,
    title: []const u8,
    path: []const u8,
    items: []const []const u8,
    mode: FileDialogMode = .open,
    file_name: []const u8 = "",
    selected_index: usize = 0,
    hover_index: ?usize = null,
    first_index: usize = 0,
    max_visible_rows: usize = 0,
    ok_text: []const u8 = "",
    cancel_text: []const u8 = "Cancel",
    focus_action: DialogAction = .none,
    pressed_action: DialogAction = .none,
    palette: Palette = default_palette,

    pub fn draw(self: FileDialog, canvas: Canvas, scratch: []u8) i32 {
        return drawFileDialogEx(canvas, self.rect, scratch, self.title, self.path, self.items, self.selected_index, self.hover_index, self.first_index, self.max_visible_rows, self.mode, self.file_name, self.ok_text, self.cancel_text, self.focus_action, self.pressed_action, self.palette);
    }

    pub fn listRect(self: FileDialog) Rect {
        return fileDialogListRect(self.rect);
    }

    pub fn fileNameRect(self: FileDialog) Rect {
        return fileDialogFileNameRect(self.rect);
    }

    pub fn okRect(self: FileDialog) Rect {
        return fileDialogOkRect(self.rect);
    }

    pub fn cancelRect(self: FileDialog) Rect {
        return fileDialogCancelRect(self.rect);
    }

    pub fn indexAt(self: FileDialog, x: i32, y: i32) ?usize {
        return listIndexAtEx(self.listRect(), self.items.len, self.first_index, null, default_metrics.list_row_h, x, y);
    }

    pub fn visibleRows(self: FileDialog) usize {
        if (self.max_visible_rows == 0) return visibleListRows(self.listRect(), default_metrics.list_row_h);
        return @min(self.max_visible_rows, visibleListRows(self.listRect(), default_metrics.list_row_h));
    }

    pub fn firstIndexForSelection(self: FileDialog) usize {
        return listFirstIndexForSelection(self.items.len, self.visibleRows(), self.selected_index, self.first_index);
    }

    pub fn actionAt(self: FileDialog, x: i32, y: i32) DialogAction {
        const buttons = [_]DialogButton{
            .{ .action = .ok, .text = fileDialogOkText(self.mode, self.ok_text), .role = .default },
            .{ .action = .cancel, .text = self.cancel_text, .role = .cancel },
        };
        const button_action = dialogButtonActionAt(self.rect, buttons[0..], .right, x, y);
        if (button_action != .none) return button_action;
        if (self.indexAt(x, y) != null) return .select;
        return .none;
    }

    pub fn keyAction(self: FileDialog, key: u8) DialogAction {
        return switch (key) {
            Key.escape, Key.enter, '\n', ' ' => blk: {
                const buttons = [_]DialogButton{
                    .{ .action = .ok, .text = fileDialogOkText(self.mode, self.ok_text), .role = .default },
                    .{ .action = .cancel, .text = self.cancel_text, .role = .cancel },
                };
                break :blk dialogKeyAction(buttons[0..], self.focus_action, key);
            },
            Key.up => .previous,
            Key.down => .next,
            Key.tab => .next,
            Key.shift_tab => .previous,
            else => .none,
        };
    }

    pub fn selectedIndexForAction(self: FileDialog, action: DialogAction) usize {
        if (self.items.len == 0) return 0;
        const selected = @min(self.selected_index, self.items.len - 1);
        return switch (action) {
            .previous => if (selected == 0) self.items.len - 1 else selected - 1,
            .next => if (selected + 1 >= self.items.len) 0 else selected + 1,
            else => selected,
        };
    }
};

pub const InputDialog = struct {
    rect: Rect,
    title: []const u8,
    label: []const u8,
    value: []const u8,
    ok_text: []const u8 = "OK",
    cancel_text: []const u8 = "Cancel",
    focus_action: DialogAction = .select,
    pressed_action: DialogAction = .none,
    palette: Palette = default_palette,

    pub fn draw(self: InputDialog, canvas: Canvas, scratch: []u8) i32 {
        return drawInputDialog(canvas, self, scratch);
    }

    pub fn valueRect(self: InputDialog) Rect {
        return inputDialogValueRect(self.rect);
    }

    pub fn okRect(self: InputDialog) Rect {
        return inputDialogOkRect(self.rect);
    }

    pub fn cancelRect(self: InputDialog) Rect {
        return inputDialogCancelRect(self.rect);
    }

    pub fn actionAt(self: InputDialog, x: i32, y: i32) DialogAction {
        const buttons = [_]DialogButton{
            .{ .action = .ok, .text = self.ok_text, .role = .default },
            .{ .action = .cancel, .text = self.cancel_text, .role = .cancel },
        };
        const button_action = dialogButtonActionAt(self.rect, buttons[0..], .right, x, y);
        if (button_action != .none) return button_action;
        if (self.valueRect().contains(x, y)) return .select;
        return .none;
    }

    pub fn keyAction(self: InputDialog, key: u8) DialogAction {
        return switch (key) {
            Key.escape, Key.enter, '\n', ' ' => blk: {
                const buttons = [_]DialogButton{
                    .{ .action = .ok, .text = self.ok_text, .role = .default },
                    .{ .action = .cancel, .text = self.cancel_text, .role = .cancel },
                };
                break :blk dialogKeyAction(buttons[0..], self.focus_action, key);
            },
            Key.tab => .next,
            Key.shift_tab => .previous,
            else => .none,
        };
    }
};

pub fn TextArea(comptime capacity: usize) type {
    if (capacity < 2) @compileError("TextArea capacity must be at least 2 bytes");
    return struct {
        const Self = @This();

        buffer: [capacity]u8 = .{0} ** capacity,
        len: usize = 0,
        cursor: usize = 0,
        selection_anchor: ?usize = null,
        scroll_line: usize = 0,
        scroll_col: usize = 0,
        preferred_col: ?usize = null,
        focused: bool = false,
        disabled: bool = false,
        palette: Palette = default_palette,

        pub fn maxTextLen(self: *const Self) usize {
            _ = self;
            return capacity - 1;
        }

        pub fn value(self: *const Self) []const u8 {
            return self.buffer[0..self.len];
        }

        pub fn isFull(self: *const Self) bool {
            return self.len >= self.maxTextLen();
        }

        pub fn available(self: *const Self) usize {
            return self.maxTextLen() - self.len;
        }

        pub fn set(self: *Self, value_text: []const u8) void {
            self.clear();
            _ = self.insertSliceRaw(value_text);
            self.cursor = self.len;
            self.clearSelection();
            self.scroll_line = 0;
            self.scroll_col = 0;
            self.preferred_col = null;
        }

        pub fn clear(self: *Self) void {
            @memset(self.buffer[0..], 0);
            self.len = 0;
            self.cursor = 0;
            self.selection_anchor = null;
            self.scroll_line = 0;
            self.scroll_col = 0;
            self.preferred_col = null;
        }

        pub fn selectAll(self: *Self) void {
            self.selection_anchor = 0;
            self.cursor = self.len;
            self.preferred_col = null;
        }

        pub fn clearSelection(self: *Self) void {
            self.selection_anchor = null;
        }

        pub fn hasSelection(self: *const Self) bool {
            return self.selection_anchor != null and self.selection_anchor.? != self.cursor;
        }

        pub fn selectionRange(self: *const Self) TextRange {
            const anchor = self.selection_anchor orelse self.cursor;
            return TextRange.normalized(@min(anchor, self.len), @min(self.cursor, self.len));
        }

        pub fn setSelection(self: *Self, start: usize, end: usize) void {
            self.selection_anchor = utf8FloorBoundary(self.value(), start);
            self.cursor = utf8FloorBoundary(self.value(), end);
            self.preferred_col = null;
        }

        pub fn selectedValue(self: *const Self) []const u8 {
            if (!self.hasSelection()) return "";
            const range = self.selectionRange();
            return self.buffer[range.start..range.end];
        }

        pub fn copySelection(self: *const Self, out: []u8) bool {
            if (!self.hasSelection() or out.len == 0) return false;
            const selected = self.selectedValue();
            if (selected.len + 1 > out.len) return false;
            @memset(out, 0);
            if (selected.len > 0) @memcpy(out[0..selected.len], selected);
            out[selected.len] = 0;
            return true;
        }

        pub fn cutSelection(self: *Self, out: []u8) bool {
            if (self.disabled) return false;
            if (!self.copySelection(out)) return false;
            return self.deleteSelection();
        }

        pub fn copyToClipboard(self: *const Self, ctx: *const r4desk.Context) bool {
            if (!self.hasSelection()) return false;
            const selected = self.selectedValue();
            if (selected.len == 0) return false;
            return ctx.clipboardWrite(selected) >= 0;
        }

        pub fn cutToClipboard(self: *Self, ctx: *const r4desk.Context) bool {
            if (self.disabled) return false;
            if (!self.copyToClipboard(ctx)) return false;
            return self.deleteSelection();
        }

        pub fn pasteFromClipboard(self: *Self, ctx: *const r4desk.Context, view: TextAreaView) bool {
            if (self.disabled) return false;
            var data: [clipboard_buffer_size]u8 = .{0} ** clipboard_buffer_size;
            const len_read = ctx.clipboardRead(data[0..]);
            if (len_read <= 0) return false;
            return self.pasteSlice(data[0..@as(usize, @intCast(len_read))], view);
        }

        pub fn pasteSlice(self: *Self, value_text: []const u8, view: TextAreaView) bool {
            if (self.disabled) return false;
            const deleted = self.deleteSelection();
            const inserted = self.insertSliceRaw(value_text);
            const changed = deleted or inserted > 0;
            if (changed) self.afterEdit(view);
            return changed;
        }

        pub fn insertByte(self: *Self, ch: u8, view: TextAreaView) bool {
            if (self.disabled) return false;
            const normalized = normalizeTextAreaByte(ch) orelse return false;
            _ = self.deleteSelection();
            if (!self.insertByteRaw(normalized)) return false;
            self.afterEdit(view);
            return true;
        }

        pub fn insertSlice(self: *Self, value_text: []const u8, view: TextAreaView) bool {
            if (self.disabled) return false;
            const deleted = self.deleteSelection();
            const inserted = self.insertSliceRaw(value_text);
            const changed = deleted or inserted > 0;
            if (changed) self.afterEdit(view);
            return changed;
        }

        pub fn deleteSelection(self: *Self) bool {
            if (!self.hasSelection()) return false;
            const range = self.selectionRange();
            self.removeRange(range.start, range.end);
            self.cursor = range.start;
            self.clearSelection();
            self.preferred_col = null;
            return true;
        }

        pub fn deleteBackward(self: *Self, view: TextAreaView) bool {
            if (self.disabled) return false;
            if (self.deleteSelection()) {
                self.afterEdit(view);
                return true;
            }
            if (self.cursor == 0) return false;
            const target = utf8PreviousIndex(self.value(), self.cursor);
            self.removeRange(target, self.cursor);
            self.cursor = @min(target, self.len);
            self.afterEdit(view);
            return true;
        }

        pub fn deleteForward(self: *Self, view: TextAreaView) bool {
            if (self.disabled) return false;
            if (self.deleteSelection()) {
                self.afterEdit(view);
                return true;
            }
            if (self.cursor >= self.len) return false;
            self.removeRange(self.cursor, utf8NextIndex(self.value(), self.cursor));
            self.afterEdit(view);
            return true;
        }

        pub fn removeRange(self: *Self, start: usize, end: usize) void {
            const safe_start = @min(start, self.len);
            const safe_end = @min(end, self.len);
            if (safe_start >= safe_end) return;
            const count = safe_end - safe_start;
            var index = safe_start;
            while (index + count <= self.len) : (index += 1) self.buffer[index] = self.buffer[index + count];
            self.len -= count;
            if (self.len < self.buffer.len) self.buffer[self.len] = 0;
            if (self.len + 1 < self.buffer.len) @memset(self.buffer[self.len + 1 ..], 0);
            if (self.cursor > safe_end) {
                self.cursor -= count;
            } else if (self.cursor > safe_start) {
                self.cursor = safe_start;
            }
            if (self.selection_anchor) |anchor| {
                self.selection_anchor = if (anchor > safe_end) anchor - count else if (anchor > safe_start) safe_start else anchor;
            }
        }

        pub fn moveCursorTo(self: *Self, index: usize, extend_selection: bool, view: TextAreaView) bool {
            const target = utf8FloorBoundary(self.value(), index);
            if (target == self.cursor and (extend_selection or !self.hasSelection())) return false;
            self.setCursorInternal(target, extend_selection);
            self.preferred_col = null;
            self.ensureCursorVisible(view);
            return true;
        }

        pub fn moveLeft(self: *Self, extend_selection: bool, view: TextAreaView) bool {
            if (!extend_selection and self.hasSelection()) return self.moveCursorTo(self.selectionRange().start, false, view);
            if (self.cursor == 0) return false;
            return self.moveCursorTo(utf8PreviousIndex(self.value(), self.cursor), extend_selection, view);
        }

        pub fn moveRight(self: *Self, extend_selection: bool, view: TextAreaView) bool {
            if (!extend_selection and self.hasSelection()) return self.moveCursorTo(self.selectionRange().end, false, view);
            if (self.cursor >= self.len) return false;
            return self.moveCursorTo(utf8NextIndex(self.value(), self.cursor), extend_selection, view);
        }

        pub fn moveHome(self: *Self, extend_selection: bool, view: TextAreaView) bool {
            const point = textAreaVisualPoint(self.value(), self.cursor, view.effectiveWrapCols());
            return self.moveCursorTo(textAreaIndexForVisualPosition(self.value(), point.line, 0, view.effectiveWrapCols()), extend_selection, view);
        }

        pub fn moveEnd(self: *Self, extend_selection: bool, view: TextAreaView) bool {
            const point = textAreaVisualPoint(self.value(), self.cursor, view.effectiveWrapCols());
            return self.moveCursorTo(textAreaVisualLineRange(self.value(), point.line, view.effectiveWrapCols()).end, extend_selection, view);
        }

        pub fn moveVertical(self: *Self, delta: i32, extend_selection: bool, view: TextAreaView) bool {
            if (delta == 0) return false;
            const wrap_cols = view.effectiveWrapCols();
            const point = textAreaVisualPoint(self.value(), self.cursor, wrap_cols);
            const last_line = textAreaVisualLineCount(self.value(), wrap_cols) - 1;
            const base_col = self.preferred_col orelse point.column;
            var target_line = point.line;
            if (delta < 0) {
                const amount: usize = @intCast(-delta);
                target_line = if (amount > target_line) 0 else target_line - amount;
            } else {
                const amount: usize = @intCast(delta);
                target_line = @min(last_line, target_line + amount);
            }
            const target_index = textAreaIndexForVisualPosition(self.value(), target_line, base_col, wrap_cols);
            const changed = target_index != self.cursor or (extend_selection and !self.hasSelection());
            self.setCursorInternal(target_index, extend_selection);
            self.preferred_col = base_col;
            self.ensureCursorVisible(view);
            return changed;
        }

        pub fn handleKey(self: *Self, key: u8, view: TextAreaView) bool {
            return self.handleKeyEx(key, false, view);
        }

        pub fn handleKeyEx(self: *Self, key: u8, extend_selection: bool, view: TextAreaView) bool {
            return self.handleCodepointEx(key, extend_selection, view);
        }

        pub fn handleCodepointEx(self: *Self, codepoint: u32, extend_selection: bool, view: TextAreaView) bool {
            if (self.disabled) return false;
            switch (codepoint) {
                Key.ctrl_a => {
                    self.selectAll();
                    self.ensureCursorVisible(view);
                    return true;
                },
                Key.left => return self.moveLeft(extend_selection, view),
                Key.right => return self.moveRight(extend_selection, view),
                Key.up => return self.moveVertical(-1, extend_selection, view),
                Key.down => return self.moveVertical(1, extend_selection, view),
                Key.page_up => return self.moveVertical(-@as(i32, @intCast(view.effectiveVisibleRows())), extend_selection, view),
                Key.page_down => return self.moveVertical(@intCast(view.effectiveVisibleRows()), extend_selection, view),
                Key.home => return self.moveHome(extend_selection, view),
                Key.end => return self.moveEnd(extend_selection, view),
                Key.backspace => return self.deleteBackward(view),
                Key.delete => return self.deleteForward(view),
                Key.enter, '\n' => return self.insertByte('\n', view),
                Key.tab => return self.insertByte('\t', view),
                else => {},
            }
            if (!isTextCodepoint(codepoint)) return false;
            var encoded: [4]u8 = undefined;
            const len = encodeUtf8Codepoint(codepoint, &encoded);
            if (len == 0) return false;
            return self.insertSlice(encoded[0..len], view);
        }

        pub fn handleClipboardKey(self: *Self, ctx: *const r4desk.Context, key: u8, view: TextAreaView) bool {
            return switch (key) {
                Key.ctrl_c => self.copyToClipboard(ctx),
                Key.ctrl_x => self.cutToClipboard(ctx),
                Key.ctrl_v => self.pasteFromClipboard(ctx, view),
                else => self.handleKey(key, view),
            };
        }

        pub fn beginMouseSelection(self: *Self, index: usize, view: TextAreaView) void {
            const safe_index = @min(index, self.len);
            self.cursor = safe_index;
            self.selection_anchor = safe_index;
            self.preferred_col = null;
            self.ensureCursorVisible(view);
        }

        pub fn dragMouseSelection(self: *Self, index: usize, view: TextAreaView) void {
            self.setCursorInternal(@min(index, self.len), true);
            self.preferred_col = null;
            self.ensureCursorVisible(view);
        }

        pub fn finishMouseSelection(self: *Self) void {
            if (!self.hasSelection()) self.clearSelection();
        }

        pub fn hitTest(self: *const Self, x: i32, y: i32, char_w: i32, line_h: i32, view: TextAreaView) usize {
            const cell_w = @max(1, char_w);
            const cell_h = @max(1, line_h);
            const local_col: usize = if (x <= 0) 0 else @intCast(@divTrunc(x, cell_w));
            const local_line: usize = if (y <= 0) 0 else @intCast(@divTrunc(y, cell_h));
            return textAreaIndexForVisualPosition(
                self.value(),
                self.scroll_line + local_line,
                self.scroll_col + local_col,
                view.effectiveWrapCols(),
            );
        }

        pub fn scrollTo(self: *Self, line: usize, column: usize, view: TextAreaView) void {
            self.scroll_line = line;
            self.scroll_col = column;
            self.clampScroll(view);
        }

        pub fn scrollByLines(self: *Self, delta: i32, view: TextAreaView) void {
            if (delta < 0) {
                const amount: usize = @intCast(-delta);
                self.scroll_line = if (amount > self.scroll_line) 0 else self.scroll_line - amount;
            } else {
                self.scroll_line += @intCast(delta);
            }
            self.clampScroll(view);
        }

        pub fn clampScroll(self: *Self, view: TextAreaView) void {
            const line_count = textAreaVisualLineCount(self.value(), view.effectiveWrapCols());
            const rows = view.effectiveVisibleRows();
            const max_first = if (line_count > rows) line_count - rows else 0;
            if (self.scroll_line > max_first) self.scroll_line = max_first;
            const max_col = if (view.wrap_cols == 0) blk: {
                const widest_line = textAreaVisualMaxColumns(self.value(), 0);
                break :blk if (widest_line > view.effectiveVisibleCols()) widest_line - view.effectiveVisibleCols() else 0;
            } else 0;
            if (self.scroll_col > max_col) self.scroll_col = max_col;
        }

        pub fn ensureCursorVisible(self: *Self, view: TextAreaView) void {
            const point = textAreaVisualPoint(self.value(), self.cursor, view.effectiveWrapCols());
            const rows = view.effectiveVisibleRows();
            const cols = view.effectiveVisibleCols();
            if (point.line < self.scroll_line) {
                self.scroll_line = point.line;
            } else if (point.line >= self.scroll_line + rows) {
                self.scroll_line = point.line + 1 - rows;
            }
            if (point.column < self.scroll_col) {
                self.scroll_col = point.column;
            } else if (point.column >= self.scroll_col + cols) {
                self.scroll_col = point.column + 1 - cols;
            }
            self.clampScroll(view);
        }

        pub fn draw(self: *const Self, canvas: Canvas, rect: Rect, scratch: []u8) i32 {
            return drawTextAreaEx(canvas, rect, scratch, self.value(), self.cursor, self.selectionRange(), self.scroll_line, self.scroll_col, self.focused, self.disabled, self.palette);
        }

        fn afterEdit(self: *Self, view: TextAreaView) void {
            self.preferred_col = null;
            self.ensureCursorVisible(view);
        }

        fn setCursorInternal(self: *Self, index: usize, extend_selection: bool) void {
            const old_cursor = self.cursor;
            self.cursor = @min(index, self.len);
            if (extend_selection) {
                if (self.selection_anchor == null) self.selection_anchor = old_cursor;
            } else {
                self.clearSelection();
            }
        }

        fn insertSliceRaw(self: *Self, value_text: []const u8) usize {
            var inserted: usize = 0;
            var i: usize = 0;
            while (i < value_text.len) {
                const source_index = i;
                var ch = value_text[i];
                i += 1;
                if (ch == '\r') {
                    if (i < value_text.len and value_text[i] == '\n') i += 1;
                    ch = '\n';
                }
                if (ch >= 0x80) {
                    const sequence_len = utf8SequenceLengthAt(value_text, source_index);
                    if (sequence_len > 1) {
                        if (self.len + sequence_len >= self.buffer.len) break;
                        var offset: usize = 0;
                        while (offset < sequence_len) : (offset += 1) {
                            _ = self.insertByteRaw(value_text[source_index + offset]);
                        }
                        i = source_index + sequence_len;
                        inserted += sequence_len;
                        continue;
                    }
                }
                const normalized = normalizeTextAreaByte(ch) orelse continue;
                if (!self.insertByteRaw(normalized)) break;
                inserted += 1;
            }
            return inserted;
        }

        fn insertByteRaw(self: *Self, ch: u8) bool {
            if (self.isFull()) return false;
            var index = self.len;
            while (index > self.cursor) : (index -= 1) self.buffer[index] = self.buffer[index - 1];
            self.buffer[self.cursor] = ch;
            self.len += 1;
            self.buffer[self.len] = 0;
            self.cursor += 1;
            return true;
        }
    };
}

pub fn TextField(comptime capacity: usize) type {
    if (capacity == 0) @compileError("TextField capacity must be greater than zero");
    return struct {
        const Self = @This();

        buffer: [capacity]u8 = .{0} ** capacity,
        len: usize = 0,
        cursor: usize = 0,
        selection_anchor: ?usize = null,
        focused: bool = false,
        disabled: bool = false,
        palette: Palette = default_palette,

        pub fn value(self: *const Self) []const u8 {
            return self.buffer[0..self.len];
        }

        pub fn set(self: *Self, value_text: []const u8) void {
            @memset(self.buffer[0..], 0);
            self.len = utf8PrefixBytes(value_text, std.math.maxInt(usize), self.buffer.len - 1);
            @memcpy(self.buffer[0..self.len], value_text[0..self.len]);
            self.cursor = self.len;
            self.selection_anchor = null;
        }

        pub fn clear(self: *Self) void {
            @memset(self.buffer[0..], 0);
            self.len = 0;
            self.cursor = 0;
            self.selection_anchor = null;
        }

        pub fn selectAll(self: *Self) void {
            self.selection_anchor = 0;
            self.cursor = self.len;
        }

        pub fn clearSelection(self: *Self) void {
            self.selection_anchor = null;
        }

        pub fn hasSelection(self: *const Self) bool {
            return self.selection_anchor != null and self.selection_anchor.? != self.cursor;
        }

        pub fn selectionRange(self: *const Self) struct { start: usize, end: usize } {
            const anchor = self.selection_anchor orelse self.cursor;
            return if (anchor <= self.cursor)
                .{ .start = anchor, .end = self.cursor }
            else
                .{ .start = self.cursor, .end = anchor };
        }

        pub fn handleKey(self: *Self, key: u8) bool {
            return self.handleCodepoint(key);
        }

        pub fn handleCodepoint(self: *Self, codepoint: u32) bool {
            if (self.disabled) return false;
            switch (codepoint) {
                Key.ctrl_a => {
                    self.selectAll();
                    return true;
                },
                Key.left => {
                    if (self.cursor == 0) return false;
                    self.cursor = utf8PreviousIndex(self.value(), self.cursor);
                    self.clearSelection();
                    return true;
                },
                Key.right => {
                    if (self.cursor >= self.len) return false;
                    self.cursor = utf8NextIndex(self.value(), self.cursor);
                    self.clearSelection();
                    return true;
                },
                Key.home => {
                    if (self.cursor == 0 and !self.hasSelection()) return false;
                    self.cursor = 0;
                    self.clearSelection();
                    return true;
                },
                Key.end => {
                    if (self.cursor == self.len and !self.hasSelection()) return false;
                    self.cursor = self.len;
                    self.clearSelection();
                    return true;
                },
                Key.backspace => {
                    if (self.deleteSelection()) return true;
                    if (self.cursor == 0) return false;
                    const target = utf8PreviousIndex(self.value(), self.cursor);
                    self.removeRange(target, self.cursor);
                    self.cursor = target;
                    return true;
                },
                Key.delete => {
                    if (self.deleteSelection()) return true;
                    if (self.cursor >= self.len) return false;
                    self.removeRange(self.cursor, utf8NextIndex(self.value(), self.cursor));
                    return true;
                },
                else => {},
            }
            if (!isTextCodepoint(codepoint)) return false;
            _ = self.deleteSelection();
            var encoded: [4]u8 = undefined;
            const encoded_len = encodeUtf8Codepoint(codepoint, &encoded);
            if (encoded_len == 0 or self.len + encoded_len >= self.buffer.len) return false;
            for (encoded[0..encoded_len]) |ch| _ = self.insertPrintable(ch);
            return true;
        }

        pub fn handleClipboardKey(self: *Self, ctx: *const r4desk.Context, key: u8) bool {
            return switch (key) {
                Key.ctrl_c => self.copyToClipboard(ctx),
                Key.ctrl_x => self.cutToClipboard(ctx),
                Key.ctrl_v => self.pasteFromClipboard(ctx),
                else => self.handleKey(key),
            };
        }

        pub fn copyToClipboard(self: *const Self, ctx: *const r4desk.Context) bool {
            return ctx.clipboardWrite(self.clipboardValue()) >= 0;
        }

        pub fn cutToClipboard(self: *Self, ctx: *const r4desk.Context) bool {
            if (self.disabled) return false;
            if (!self.copyToClipboard(ctx)) return false;
            if (!self.deleteSelection()) self.clear();
            return true;
        }

        pub fn pasteFromClipboard(self: *Self, ctx: *const r4desk.Context) bool {
            if (self.disabled) return false;
            var data: [clipboard_buffer_size]u8 = .{0} ** clipboard_buffer_size;
            const len = ctx.clipboardRead(data[0..]);
            if (len <= 0) return false;
            _ = self.deleteSelection();
            const input_len = @min(data.len, @as(usize, @intCast(len)));
            const input = data[0..input_len];
            var changed = false;
            var i: usize = 0;
            while (i < input.len) {
                const ch = data[i];
                if (ch == 0) break;
                if (ch < 0x20 or ch == 0x7F) {
                    i += 1;
                    continue;
                }
                const sequence_len = utf8SequenceLengthAt(input, i);
                if (sequence_len > 1) {
                    if (self.len + sequence_len >= self.buffer.len) break;
                    var offset: usize = 0;
                    while (offset < sequence_len) : (offset += 1) changed = self.insertPrintable(input[i + offset]) or changed;
                    i += sequence_len;
                    continue;
                }
                changed = self.insertPrintable(ch) or changed;
                i += 1;
            }
            return changed;
        }

        pub fn draw(self: *const Self, canvas: Canvas, rect: Rect, scratch: []u8) i32 {
            return drawTextFieldEx(canvas, rect, scratch, self.value(), self.cursor, self.selectionRange(), self.focused, self.disabled, self.palette);
        }

        fn deleteSelection(self: *Self) bool {
            if (!self.hasSelection()) return false;
            const range = self.selectionRange();
            self.removeRange(range.start, range.end);
            self.cursor = range.start;
            self.clearSelection();
            return true;
        }

        fn removeRange(self: *Self, start: usize, end: usize) void {
            if (start >= end or end > self.len) return;
            const count = end - start;
            var index = start;
            while (index + count <= self.len) : (index += 1) self.buffer[index] = self.buffer[index + count];
            self.len -= count;
            @memset(self.buffer[self.len + 1 ..], 0);
        }

        fn clipboardValue(self: *const Self) []const u8 {
            if (!self.hasSelection()) return self.value();
            const range = self.selectionRange();
            return self.buffer[range.start..range.end];
        }

        fn insertPrintable(self: *Self, ch: u8) bool {
            if (ch < 0x20 or ch == 0x7F) return false;
            if (self.len >= self.buffer.len - 1) return false;
            var index = self.len;
            while (index > self.cursor) : (index -= 1) self.buffer[index] = self.buffer[index - 1];
            self.buffer[self.cursor] = ch;
            self.len += 1;
            self.buffer[self.len] = 0;
            self.cursor += 1;
            return true;
        }
    };
}

/// Per-frame accounting for the buffered Canvas path.  Every append or legacy
/// draw call is one R4DRAW transition and one entry into the frame mutation
/// path; BEGIN, COMMIT and PRESENT are deliberately not included.
pub const FrameCanvasStats = struct {
    logical_commands: u64 = 0,
    resource_bytes: u64 = 0,
    flushes: u64 = 0,
    append_calls: u64 = 0,
    direct_chunks: u64 = 0,
    legacy_calls: u64 = 0,
    failed_calls: u64 = 0,

    pub fn drawTransitions(self: FrameCanvasStats) u64 {
        return self.append_calls +| self.legacy_calls;
    }

    pub fn frameMutationEntries(self: FrameCanvasStats) u64 {
        return self.drawTransitions();
    }
};

/// Bounded command builder used by Canvas inside an app_gui PaintContext.
/// Both slices remain caller-owned.  R4DRAW snapshots every flushed chunk,
/// therefore the same storage can be reused until the final transactional
/// commit.  A failed chunk is latched so PaintContext can cancel the complete
/// frame instead of publishing a prefix.
pub const FrameCanvas = struct {
    ctx: *const r4draw.Context,
    commands: []abi.GuiFrameCommand,
    resources: []u8,
    transactional: bool,
    command_len: usize = 0,
    resource_len: usize = 0,
    active: bool = true,
    submitted: bool = false,
    failure: i32 = 0,
    stats: FrameCanvasStats = .{},

    const Reservation = struct {
        command: *abi.GuiFrameCommand,
        resource: []u8,
    };

    pub fn init(ctx: *const r4draw.Context, commands: []abi.GuiFrameCommand, resources: []u8, transactional: bool) FrameCanvas {
        return .{
            .ctx = ctx,
            .commands = commands,
            .resources = resources,
            .transactional = transactional,
        };
    }

    pub fn bind(self: *FrameCanvas, canvas: Canvas) Canvas {
        var result = canvas;
        result.frame_canvas = self;
        return result;
    }

    pub fn finish(self: *FrameCanvas) i32 {
        if (!self.active) return abi.gui_frame_error_state;
        if (self.failure < 0) return self.failure;
        return self.flush();
    }

    pub fn complete(self: *FrameCanvas) void {
        self.command_len = 0;
        self.resource_len = 0;
        self.active = false;
    }

    pub fn cancel(self: *FrameCanvas) void {
        self.complete();
    }

    pub fn clear(self: *FrameCanvas, rgb: u32) i32 {
        if (!self.beginLogicalCommand(0)) return self.currentFailure();
        if (!self.transactional) return self.legacyResult(self.ctx.guiClear(rgb));

        // Legacy CLEAR starts a fresh frame.  Pending commands have not crossed
        // the ABI yet and can simply be forgotten.  Once a chunk was submitted,
        // use the legacy operation inside the same private transaction to retain
        // the exact reset semantics.
        self.command_len = 0;
        self.resource_len = 0;
        if (self.submitted) return self.legacyResult(self.ctx.guiClear(rgb));
        return self.queueWithoutAccounting(.{ .kind = abi.gui_frame_command_kind_clear, .rgb = rgb }, &.{});
    }

    pub fn rect(self: *FrameCanvas, x: i32, y: i32, w: u32, h: u32, rgb: u32) i32 {
        if (!self.beginLogicalCommand(0)) return self.currentFailure();
        if (!self.transactional) return self.legacyResult(self.ctx.guiRect(x, y, w, h, rgb));
        return self.queueWithoutAccounting(.{ .kind = abi.gui_frame_command_kind_rect, .x = x, .y = y, .w = w, .h = h, .rgb = rgb }, &.{});
    }

    pub fn text(self: *FrameCanvas, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32, font: FontMetrics) i32 {
        const resource = std.mem.span(value);
        if (!self.beginLogicalCommand(resource.len)) return self.currentFailure();
        if (!self.transactional) return self.legacyResult(self.ctx.guiDrawTextEx(x, y, value, fg, bg, font.id, 0));
        const text_width = fallbackTextWidthZ(value, font.max_advance);
        return self.queueWithoutAccounting(.{
            .kind = abi.gui_frame_command_kind_text,
            .x = x,
            .y = y,
            .fg = fg,
            .bg = bg,
            .font_id = font.id,
            .text_w = @intCast(@max(0, text_width)),
            .text_h = @intCast(@max(1, font.height)),
            .baseline = font.baseline,
            .line_height = @intCast(@max(1, font.line_height)),
        }, resource);
    }

    pub fn raster(self: *FrameCanvas, x: i32, y: i32, width: u32, height: u32, scale: u32, pixels: []const u32) i32 {
        const pixel_count_u64 = @as(u64, width) * @as(u64, height);
        const resource_bytes_u64 = std.math.mul(u64, pixel_count_u64, @sizeOf(u32)) catch {
            if (!self.beginLogicalCommand(0)) return self.currentFailure();
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlit(x, y, width, height, scale, pixels));
        };
        const resource_bytes = std.math.cast(usize, resource_bytes_u64) orelse {
            if (!self.beginLogicalCommand(0)) return self.currentFailure();
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlit(x, y, width, height, scale, pixels));
        };
        if (!self.beginLogicalCommand(resource_bytes)) return self.currentFailure();
        if (!self.transactional or width == 0 or height == 0 or width > abi.gui_raster_max_width or height > abi.gui_raster_max_height or
            pixel_count_u64 > abi.gui_raster_max_pixels or pixels.len < pixel_count_u64)
        {
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlit(x, y, width, height, scale, pixels));
        }

        const reservation = self.reserve(resource_bytes) orelse {
            if (self.failure < 0) return self.failure;
            return self.legacyResult(self.ctx.guiBlit(x, y, width, height, scale, pixels));
        };
        const scale_value = if (scale == 0) @as(u32, 1) else @min(scale, @as(u32, 16));
        reservation.command.* = .{
            .kind = abi.gui_frame_command_kind_raster,
            .x = x,
            .y = y,
            .w = width,
            .h = height,
            .resource_offset = @intCast(self.resource_len - resource_bytes),
            .resource_bytes = @intCast(resource_bytes),
            .parameter0 = scale_value,
        };
        for (pixels[0..@intCast(pixel_count_u64)], 0..) |pixel, index| {
            const color = pixel & 0x00FF_FFFF;
            const offset = index * @sizeOf(u32);
            reservation.resource[offset] = @truncate(color);
            reservation.resource[offset + 1] = @truncate(color >> 8);
            reservation.resource[offset + 2] = @truncate(color >> 16);
            reservation.resource[offset + 3] = 0;
        }
        return abi.gui_frame_result_ok;
    }

    pub fn alpha8(self: *FrameCanvas, x: i32, y: i32, width: u32, height: u32, stride: u32, rgb: u32, alpha: []const u8) i32 {
        const resource_bytes_u64 = @as(u64, width) * @as(u64, height);
        const resource_bytes = std.math.cast(usize, resource_bytes_u64) orelse {
            if (!self.beginLogicalCommand(0)) return self.currentFailure();
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlendAlpha8(x, y, width, height, stride, rgb, alpha));
        };
        if (!self.beginLogicalCommand(resource_bytes)) return self.currentFailure();
        if (!self.transactional or width == 0 or height == 0 or width > abi.gui_alpha8_max_width or height > abi.gui_alpha8_max_height or
            resource_bytes_u64 > abi.gui_alpha8_max_pixels or stride < width)
        {
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlendAlpha8(x, y, width, height, stride, rgb, alpha));
        }
        const source_bytes = std.math.add(u64, std.math.mul(u64, height - 1, stride) catch {
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlendAlpha8(x, y, width, height, stride, rgb, alpha));
        }, width) catch {
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlendAlpha8(x, y, width, height, stride, rgb, alpha));
        };
        if (source_bytes > alpha.len) {
            if (!self.flushBeforeLegacy()) return self.failure;
            return self.legacyResult(self.ctx.guiBlendAlpha8(x, y, width, height, stride, rgb, alpha));
        }

        const reservation = self.reserve(resource_bytes) orelse {
            if (self.failure < 0) return self.failure;
            return self.legacyResult(self.ctx.guiBlendAlpha8(x, y, width, height, stride, rgb, alpha));
        };
        reservation.command.* = .{
            .kind = abi.gui_frame_command_kind_alpha8,
            .x = x,
            .y = y,
            .w = width,
            .h = height,
            .rgb = rgb & 0x00FF_FFFF,
            .resource_offset = @intCast(self.resource_len - resource_bytes),
            .resource_bytes = @intCast(resource_bytes),
        };
        const row_bytes: usize = @intCast(width);
        const source_stride: usize = @intCast(stride);
        for (0..@as(usize, @intCast(height))) |row| {
            const source_offset = row * source_stride;
            const target_offset = row * row_bytes;
            @memcpy(reservation.resource[target_offset .. target_offset + row_bytes], alpha[source_offset .. source_offset + row_bytes]);
        }
        return abi.gui_frame_result_ok;
    }

    /// Adds a prebuilt shape or another GuiFrameCommand resource.  The builder
    /// owns offset rebasing; callers describe exactly one command/resource pair.
    pub fn appendCommand(self: *FrameCanvas, command: abi.GuiFrameCommand, resource: []const u8) i32 {
        if (!self.beginLogicalCommand(resource.len)) return self.currentFailure();
        if (!self.transactional) {
            var direct = command;
            direct.resource_offset = 0;
            direct.resource_bytes = @intCast(resource.len);
            return self.legacyResult(self.ctx.guiFrameAppend((&[_]abi.GuiFrameCommand{direct})[0..], resource));
        }
        return self.queueWithoutAccounting(command, resource);
    }

    fn beginLogicalCommand(self: *FrameCanvas, resource_bytes: usize) bool {
        if (!self.active) {
            if (self.failure >= 0) self.failure = abi.gui_frame_error_state;
            return false;
        }
        if (self.failure < 0) return false;
        self.stats.logical_commands +|= 1;
        self.stats.resource_bytes +|= @intCast(resource_bytes);
        return true;
    }

    fn currentFailure(self: *const FrameCanvas) i32 {
        return if (self.failure < 0) self.failure else abi.gui_frame_error_state;
    }

    fn latchFailure(self: *FrameCanvas, raw: i32) i32 {
        if (raw < 0 and self.failure >= 0) self.failure = raw;
        if (raw < 0) self.stats.failed_calls +|= 1;
        return raw;
    }

    fn legacyResult(self: *FrameCanvas, raw: i32) i32 {
        self.stats.legacy_calls +|= 1;
        if (raw >= 0) self.submitted = true;
        return self.latchFailure(raw);
    }

    fn appendResult(self: *FrameCanvas, raw: i32, direct: bool) i32 {
        self.stats.append_calls +|= 1;
        if (direct) self.stats.direct_chunks +|= 1 else self.stats.flushes +|= 1;
        if (raw >= 0) self.submitted = true;
        return self.latchFailure(raw);
    }

    fn reserve(self: *FrameCanvas, resource_bytes: usize) ?Reservation {
        if (self.commands.len == 0 or resource_bytes > self.resources.len) {
            if (self.command_len != 0 and self.flush() < 0) return null;
            return null;
        }
        if (self.command_len == self.commands.len or resource_bytes > self.resources.len - self.resource_len) {
            if (self.flush() < 0) return null;
        }
        if (self.command_len == self.commands.len or resource_bytes > self.resources.len - self.resource_len) return null;
        const command = &self.commands[self.command_len];
        const start = self.resource_len;
        self.command_len += 1;
        self.resource_len += resource_bytes;
        return .{ .command = command, .resource = self.resources[start..self.resource_len] };
    }

    fn flushBeforeLegacy(self: *FrameCanvas) bool {
        if (!self.transactional or self.command_len == 0) return self.failure >= 0;
        return self.flush() >= 0;
    }

    fn queueWithoutAccounting(self: *FrameCanvas, source_command: abi.GuiFrameCommand, resource: []const u8) i32 {
        if (self.failure < 0) return self.failure;
        if (self.reserve(resource.len)) |reservation| {
            var command = source_command;
            // Resource-less commands must keep the canonical zero offset. A
            // running cursor is meaningful only when this command references
            // bytes from the batch resource buffer.
            command.resource_offset = if (resource.len == 0) 0 else @intCast(self.resource_len - resource.len);
            command.resource_bytes = @intCast(resource.len);
            reservation.command.* = command;
            @memcpy(reservation.resource, resource);
            return abi.gui_frame_result_ok;
        }
        if (self.failure < 0) return self.failure;

        var command = source_command;
        command.resource_offset = 0;
        command.resource_bytes = @intCast(resource.len);
        const direct = [_]abi.GuiFrameCommand{command};
        return self.appendResult(self.ctx.guiFrameAppend(direct[0..], resource), true);
    }

    fn flush(self: *FrameCanvas) i32 {
        if (self.failure < 0) return self.failure;
        if (self.command_len == 0) {
            self.resource_len = 0;
            return abi.gui_frame_result_ok;
        }
        const command_len = self.command_len;
        const resource_len = self.resource_len;
        self.command_len = 0;
        self.resource_len = 0;
        return self.appendResult(self.ctx.guiFrameAppend(self.commands[0..command_len], self.resources[0..resource_len]), false);
    }
};

pub const Canvas = struct {
    ctx: *const r4draw.Context,
    w: i32,
    h: i32,
    font: FontMetrics = .{},
    frame_canvas: ?*FrameCanvas = null,

    pub fn init(ctx: *const r4draw.Context, info: abi.GuiWindowInfo) Canvas {
        return initSize(ctx, info.client_w, info.client_h);
    }

    pub fn initSize(ctx: *const r4draw.Context, w: i32, h: i32) Canvas {
        const metrics = currentFontMetrics(ctx);
        return .{
            .ctx = ctx,
            // Window geometry is already bounded by the desktop.  Preserve
            // the complete client area so maximized and high-resolution
            // windows do not silently lose their right or bottom edge.
            .w = @max(w, 1),
            .h = @max(h, 1),
            .font = metrics,
        };
    }

    pub fn bounds(self: Canvas) Rect {
        return .{ .x = 0, .y = 0, .w = self.w, .h = self.h };
    }

    pub fn withFontId(self: Canvas, font_id: u32) Canvas {
        var next = self;
        next.font = fontMetricsForId(self.ctx, font_id);
        return next;
    }

    pub fn clear(self: Canvas, rgb: u32) i32 {
        if (self.frame_canvas) |frame| return frame.clear(rgb);
        return self.ctx.guiClear(rgb);
    }

    pub fn rect(self: Canvas, item: Rect, rgb: u32) i32 {
        if (item.isEmpty()) return 0;
        if (self.frame_canvas) |frame| return frame.rect(item.x, item.y, @intCast(item.w), @intCast(item.h), rgb);
        return self.ctx.guiRect(item.x, item.y, @intCast(item.w), @intCast(item.h), rgb);
    }

    pub fn raster(self: Canvas, x: i32, y: i32, width: u32, height: u32, scale: u32, pixels: []const u32) i32 {
        if (self.frame_canvas) |frame| return frame.raster(x, y, width, height, scale, pixels);
        return self.ctx.guiBlit(x, y, width, height, scale, pixels);
    }

    /// Queues a caller-owned Alpha8 coverage mask.  The visible sub-rectangle
    /// is clipped before crossing the ABI; R4DRAW snapshots it during the call.
    pub fn blendAlpha8(self: Canvas, x: i32, y: i32, width: u32, height: u32, stride: u32, rgb: u32, alpha: []const u8) i32 {
        if (width == 0 or height == 0) return 0;
        if (width > abi.gui_alpha8_max_width or height > abi.gui_alpha8_max_height or stride < width) return -2;
        const source_bytes = @as(u64, height - 1) * @as(u64, stride) + @as(u64, width);
        if (source_bytes > alpha.len) return -3;

        const left: i64 = @max(@as(i64, 0), @as(i64, x));
        const top: i64 = @max(@as(i64, 0), @as(i64, y));
        const right: i64 = @min(@as(i64, self.w), @as(i64, x) + @as(i64, width));
        const bottom: i64 = @min(@as(i64, self.h), @as(i64, y) + @as(i64, height));
        if (right <= left or bottom <= top) return 0;

        const source_x: usize = @intCast(left - @as(i64, x));
        const source_y: usize = @intCast(top - @as(i64, y));
        const visible_width: u32 = @intCast(right - left);
        const visible_height: u32 = @intCast(bottom - top);
        const source_offset = source_y * @as(usize, stride) + source_x;
        const visible_bytes = @as(usize, visible_height - 1) * @as(usize, stride) + @as(usize, visible_width);
        if (source_offset > alpha.len or visible_bytes > alpha.len - source_offset) return -3;
        const visible = alpha[source_offset .. source_offset + visible_bytes];
        if (self.frame_canvas) |frame| return frame.alpha8(
            @intCast(left),
            @intCast(top),
            visible_width,
            visible_height,
            stride,
            rgb,
            visible,
        );
        return self.ctx.guiBlendAlpha8(
            @intCast(left),
            @intCast(top),
            visible_width,
            visible_height,
            stride,
            rgb,
            visible,
        );
    }

    pub fn text(self: Canvas, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) i32 {
        if (self.frame_canvas) |frame| return frame.text(x, y, value, fg, bg, self.font);
        return self.ctx.guiDrawTextEx(x, y, value, fg, bg, self.font.id, 0);
    }

    pub fn textFont(self: Canvas, font_id: u32, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) i32 {
        if (self.frame_canvas) |frame| {
            var metrics = self.font;
            metrics.id = font_id;
            return frame.text(x, y, value, fg, bg, metrics);
        }
        return self.ctx.guiDrawTextEx(x, y, value, fg, bg, font_id, 0);
    }

    pub fn frameCommand(self: Canvas, command: abi.GuiFrameCommand, resource: []const u8) i32 {
        if (self.frame_canvas) |frame| return frame.appendCommand(command, resource);
        var direct = command;
        direct.resource_offset = 0;
        direct.resource_bytes = @intCast(resource.len);
        return self.ctx.guiFrameAppend((&[_]abi.GuiFrameCommand{direct})[0..], resource);
    }

    pub fn textWidthZ(self: Canvas, value: [*:0]const u8) i32 {
        var metrics: abi.GuiTextMetrics = .{};
        if (self.ctx.fontMeasure(self.font.id, value, &metrics) >= 0) return clampU32ToI32(metrics.width);
        return fallbackTextWidthZ(value, self.font.max_advance);
    }

    pub fn charsForWidth(self: Canvas, width_px: i32) usize {
        if (width_px < self.font.max_advance) return 0;
        return @intCast(@divTrunc(width_px, self.font.max_advance));
    }

    pub fn textClipped(self: Canvas, x: i32, y: i32, width_px: i32, scratch: []u8, value: []const u8, fg: u32, bg: u32) i32 {
        const fitted = copyEllipsizedForCanvas(self, scratch, value, width_px);
        if (fitted.len == 0) return 0;
        return self.text(x, y, @ptrCast(scratch.ptr), fg, bg);
    }

    pub fn label(self: Canvas, item: Label, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn button(self: Canvas, item: Button, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn checkbox(self: Canvas, item: Checkbox, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn radioButton(self: Canvas, item: RadioButton, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn groupBox(self: Canvas, item: GroupBox, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn separator(self: Canvas, item: Separator) i32 {
        return item.draw(self);
    }

    pub fn textField(self: Canvas, item: Rect, scratch: []u8, value: []const u8, focused: bool, disabled: bool) i32 {
        return drawTextField(self, item, scratch, value, focused, disabled, default_palette);
    }

    pub fn textArea(self: Canvas, item: Rect, scratch: []u8, value: []const u8, cursor: usize, selection: TextRange, scroll_line: usize, scroll_col: usize, focused: bool, disabled: bool) i32 {
        return drawTextAreaEx(self, item, scratch, value, cursor, selection, scroll_line, scroll_col, focused, disabled, default_palette);
    }

    pub fn list(self: Canvas, item: List, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn scrollbar(self: Canvas, item: Scrollbar, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn toolbarButton(self: Canvas, item: ToolbarButton, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn tabBar(self: Canvas, item: TabBar, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn tableView(self: Canvas, item: TableView, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn menu(self: Canvas, item: Menu, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn menubar(self: Canvas, item: Menubar, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn dropdown(self: Canvas, item: Dropdown, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn messageDialog(self: Canvas, item: MessageDialog, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn fileDialog(self: Canvas, item: FileDialog, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn inputDialog(self: Canvas, item: InputDialog, scratch: []u8) i32 {
        return item.draw(self, scratch);
    }

    pub fn present(self: Canvas) i32 {
        return self.ctx.guiPresent();
    }
};

pub fn hostedAppFrame(sys: *const r4sys.Context, desk: *const r4desk.Context, draw: *const r4draw.Context, fallback_w: i32, fallback_h: i32) HostedAppFrame {
    var info: abi.GuiWindowInfo = .{};
    if (desk.guiWindowInfo(&info) < 0 or info.client_w <= 0 or info.client_h <= 0) {
        info.client_w = fallback_w;
        info.client_h = fallback_h;
    }
    const canvas = Canvas.initSize(draw, info.client_w, info.client_h);
    return .{
        .info = info,
        .canvas = canvas,
        .client = canvas.bounds(),
        .should_close = sys.programShouldClose(),
    };
}

pub fn pollHostedEvent(ctx: *const r4desk.Context, out: *abi.GuiEvent) ?abi.GuiEventKind {
    if (ctx.guiPollEvent(out) <= 0) return null;
    return @enumFromInt(out.kind);
}

pub fn eventKey(event: abi.GuiEvent) u8 {
    return @intCast(event.key & 0xFF);
}

pub fn eventCodepoint(event: abi.GuiEvent) u32 {
    return event.key;
}

pub fn charsForWidth(width_px: i32) usize {
    if (width_px < font_w) return 0;
    return @intCast(@divTrunc(width_px, font_w));
}

pub fn textWidth(value: []const u8) i32 {
    const max_chars: usize = @intCast(@divTrunc(std.math.maxInt(i32), font_w));
    const scalar_count = utf8ScalarCount(value);
    if (scalar_count > max_chars) return std.math.maxInt(i32);
    return @as(i32, @intCast(scalar_count)) * font_w;
}

pub fn copyEllipsized(out: []u8, value: []const u8, width_px: i32) []const u8 {
    if (out.len == 0) return out[0..0];
    @memset(out, 0);

    const capacity_chars = charsForWidth(width_px);
    if (capacity_chars == 0) return out[0..0];

    if (utf8ScalarCount(value) <= capacity_chars and value.len <= out.len - 1) {
        @memcpy(out[0..value.len], value);
        out[value.len] = 0;
        return out[0..value.len];
    }

    if (capacity_chars <= 3 or out.len <= 3) {
        const dot_count = @min(capacity_chars, out.len - 1);
        @memset(out[0..dot_count], '.');
        out[dot_count] = 0;
        return out[0..dot_count];
    }

    const keep = utf8PrefixBytes(value, capacity_chars - 3, out.len - 4);
    @memcpy(out[0..keep], value[0..keep]);
    @memcpy(out[keep .. keep + 3], "...");
    out[keep + 3] = 0;
    return out[0 .. keep + 3];
}

pub fn copyEllipsizedForCanvas(canvas: Canvas, out: []u8, value: []const u8, width_px: i32) []const u8 {
    if (out.len == 0) return out[0..0];
    @memset(out, 0);
    if (width_px <= 0) return out[0..0];

    if (value.len <= out.len - 1) {
        if (value.len > 0) @memcpy(out[0..value.len], value);
        out[value.len] = 0;
        if (canvas.textWidthZ(@ptrCast(out.ptr)) <= width_px) return out[0..value.len];
    }

    var dots: [4]u8 = .{ '.', '.', '.', 0 };
    const ellipsis_w = canvas.textWidthZ(@ptrCast(&dots));
    if (ellipsis_w > width_px or out.len < 4) {
        const dot_capacity = @min(canvas.charsForWidth(width_px), @min(@as(usize, 3), out.len - 1));
        @memset(out[0..dot_capacity], '.');
        out[dot_capacity] = 0;
        return out[0..dot_capacity];
    }

    var keep = @min(value.len, out.len - 4);
    keep = utf8PrefixBytes(value, std.math.maxInt(usize), keep);
    while (keep > 0) : (keep = utf8PreviousIndex(value, keep)) {
        @memset(out, 0);
        @memcpy(out[0..keep], value[0..keep]);
        @memcpy(out[keep .. keep + 3], "...");
        out[keep + 3] = 0;
        if (canvas.textWidthZ(@ptrCast(out.ptr)) <= width_px) return out[0 .. keep + 3];
    }

    @memset(out, 0);
    @memcpy(out[0..3], "...");
    out[3] = 0;
    return out[0..3];
}

pub fn spanZ(value: [*:0]const u8) []const u8 {
    var len: usize = 0;
    while (value[len] != 0) : (len += 1) {}
    return value[0..len];
}

pub fn textAreaClientRect(rect: Rect) Rect {
    return rect.inset(default_metrics.text_pad_x, default_metrics.text_pad_y);
}

pub fn textAreaViewForRect(canvas: Canvas, rect: Rect) TextAreaView {
    const client = textAreaClientRect(rect);
    const char_w = @max(1, canvas.font.max_advance);
    const line_h = @max(1, canvas.font.line_height);
    const cols: usize = @intCast(@max(1, @divTrunc(client.w, char_w)));
    const rows: usize = @intCast(@max(1, @divTrunc(client.h, line_h)));
    return TextAreaView.init(cols, rows);
}

pub fn textAreaVisualPoint(value: []const u8, index: usize, wrap_cols: usize) TextAreaPoint {
    const cols = effectiveTextAreaWrapCols(wrap_cols);
    const safe_index = @min(index, value.len);
    var line: usize = 0;
    var column: usize = 0;
    var i: usize = 0;
    while (i < safe_index) {
        const ch = value[i];
        const next = utf8NextIndex(value, i);
        if (ch == '\r') {
            i = next;
            continue;
        }
        if (ch != '\n' and column >= cols) {
            line += 1;
            column = 0;
        }
        if (ch == '\n') {
            line += 1;
            column = 0;
        } else {
            column += 1;
        }
        i = next;
    }
    if (safe_index < value.len and value[safe_index] != '\r' and value[safe_index] != '\n' and column >= cols) {
        line += 1;
        column = 0;
    }
    return .{ .line = line, .column = column };
}

pub fn textAreaIndexForVisualPosition(value: []const u8, target_line: usize, target_column: usize, wrap_cols: usize) usize {
    const cols = effectiveTextAreaWrapCols(wrap_cols);
    var line: usize = 0;
    var column: usize = 0;
    var i: usize = 0;
    while (i < value.len) {
        const ch = value[i];
        if (ch != '\r' and ch != '\n' and column >= cols) {
            line += 1;
            column = 0;
        }
        if (line > target_line) return i;
        if (line == target_line and column >= target_column) return i;
        if (ch == '\r') {
            i += 1;
            continue;
        }
        if (ch == '\n') {
            if (line == target_line) return i;
            line += 1;
            column = 0;
            i += 1;
            continue;
        }
        column += 1;
        i = utf8NextIndex(value, i);
    }
    return value.len;
}

pub fn textAreaVisualLineRange(value: []const u8, visual_line: usize, wrap_cols: usize) TextRange {
    const cols = effectiveTextAreaWrapCols(wrap_cols);
    const start = textAreaIndexForVisualPosition(value, visual_line, 0, cols);
    var end = start;
    var column: usize = 0;
    while (end < value.len) {
        const ch = value[end];
        if (ch == '\r') {
            end = utf8NextIndex(value, end);
            continue;
        }
        if (ch == '\n') return .{ .start = start, .end = end };
        if (column >= cols) return .{ .start = start, .end = end };
        column += 1;
        end = utf8NextIndex(value, end);
    }
    return .{ .start = start, .end = end };
}

pub fn textAreaVisualLineCount(value: []const u8, wrap_cols: usize) usize {
    return textAreaVisualPoint(value, value.len, wrap_cols).line + 1;
}

pub fn textAreaVisualMaxColumns(value: []const u8, wrap_cols: usize) usize {
    const cols = effectiveTextAreaWrapCols(wrap_cols);
    var widest: usize = 0;
    var column: usize = 0;
    var i: usize = 0;
    while (i < value.len) {
        const ch = value[i];
        i = utf8NextIndex(value, i);
        if (ch == '\r') continue;
        if (ch == '\n') {
            widest = @max(widest, column);
            column = 0;
            continue;
        }
        if (column >= cols) {
            widest = @max(widest, column);
            column = 0;
        }
        column += 1;
    }
    return @max(widest, column);
}

fn utf8SequenceLengthAt(value: []const u8, index: usize) usize {
    if (index >= value.len) return 0;
    const first = value[index];
    if (first < 0x80) return 1;
    if (first >= 0xC2 and first <= 0xDF) {
        if (index + 1 < value.len and isUtf8Continuation(value[index + 1])) return 2;
        return 1;
    }
    if (first >= 0xE0 and first <= 0xEF) {
        if (index + 2 >= value.len or !isUtf8Continuation(value[index + 1]) or !isUtf8Continuation(value[index + 2])) return 1;
        if (first == 0xE0 and value[index + 1] < 0xA0) return 1;
        if (first == 0xED and value[index + 1] >= 0xA0) return 1;
        return 3;
    }
    if (first >= 0xF0 and first <= 0xF4) {
        if (index + 3 >= value.len or !isUtf8Continuation(value[index + 1]) or !isUtf8Continuation(value[index + 2]) or !isUtf8Continuation(value[index + 3])) return 1;
        if (first == 0xF0 and value[index + 1] < 0x90) return 1;
        if (first == 0xF4 and value[index + 1] >= 0x90) return 1;
        return 4;
    }
    return 1;
}

fn isUtf8Continuation(value: u8) bool {
    return value >= 0x80 and value <= 0xBF;
}

fn isTextCodepoint(codepoint: u32) bool {
    if (codepoint < 0x20 or codepoint > 0x10ffff) return false;
    if (codepoint >= 0x7f and codepoint <= 0x9f) return false;
    return codepoint < 0xd800 or codepoint > 0xdfff;
}

fn encodeUtf8Codepoint(codepoint: u32, out: *[4]u8) usize {
    if (codepoint <= 0x7f) {
        out[0] = @intCast(codepoint);
        return 1;
    }
    if (codepoint <= 0x7ff) {
        out[0] = @intCast(0xc0 | (codepoint >> 6));
        out[1] = @intCast(0x80 | (codepoint & 0x3f));
        return 2;
    }
    if (codepoint >= 0xd800 and codepoint <= 0xdfff) return 0;
    if (codepoint <= 0xffff) {
        out[0] = @intCast(0xe0 | (codepoint >> 12));
        out[1] = @intCast(0x80 | ((codepoint >> 6) & 0x3f));
        out[2] = @intCast(0x80 | (codepoint & 0x3f));
        return 3;
    }
    if (codepoint <= 0x10ffff) {
        out[0] = @intCast(0xf0 | (codepoint >> 18));
        out[1] = @intCast(0x80 | ((codepoint >> 12) & 0x3f));
        out[2] = @intCast(0x80 | ((codepoint >> 6) & 0x3f));
        out[3] = @intCast(0x80 | (codepoint & 0x3f));
        return 4;
    }
    return 0;
}

fn utf8NextIndex(value: []const u8, index: usize) usize {
    if (index >= value.len) return value.len;
    return @min(value.len, index + utf8SequenceLengthAt(value, index));
}

fn utf8PreviousIndex(value: []const u8, index: usize) usize {
    const target = @min(index, value.len);
    if (target == 0) return 0;
    var current: usize = 0;
    var previous: usize = 0;
    while (current < target) {
        previous = current;
        const next = utf8NextIndex(value, current);
        if (next >= target) return previous;
        current = next;
    }
    return previous;
}

fn utf8FloorBoundary(value: []const u8, index: usize) usize {
    const target = @min(index, value.len);
    var current: usize = 0;
    while (current < target) {
        const next = utf8NextIndex(value, current);
        if (next > target) return current;
        current = next;
    }
    return current;
}

fn utf8ScalarCount(value: []const u8) usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index < value.len) : (count += 1) index = utf8NextIndex(value, index);
    return count;
}

fn utf8VisualColumnCount(value: []const u8) usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index < value.len) {
        const ch = value[index];
        index = utf8NextIndex(value, index);
        if (ch == '\r') continue;
        if (ch == '\n') break;
        count += 1;
    }
    return count;
}

fn utf8PrefixBytes(value: []const u8, max_scalars: usize, max_bytes: usize) usize {
    var count: usize = 0;
    var index: usize = 0;
    const byte_limit = @min(value.len, max_bytes);
    while (index < byte_limit and count < max_scalars) : (count += 1) {
        const next = utf8NextIndex(value, index);
        if (next > byte_limit) break;
        index = next;
    }
    return index;
}

fn utf8ByteIndexForColumns(value: []const u8, start: usize, end: usize, columns: usize) usize {
    var index = @min(start, value.len);
    const safe_end = @min(end, value.len);
    var used: usize = 0;
    while (index < safe_end and used < columns) {
        const ch = value[index];
        const next = @min(safe_end, utf8NextIndex(value, index));
        index = next;
        if (ch == '\r') continue;
        if (ch == '\n') break;
        used += 1;
    }
    return index;
}

pub fn drawTextInRect(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, alignment: Align, fg: u32, bg: u32) i32 {
    if (rect.isEmpty()) return 0;
    const fitted = copyEllipsizedForCanvas(canvas, scratch, text, rect.w);
    if (fitted.len == 0) return 0;
    const x = alignedTextXWidth(rect, canvas.textWidthZ(@ptrCast(scratch.ptr)), alignment);
    const y = rect.y + @max(0, @divTrunc(rect.h - canvas.font.line_height, 2));
    return canvas.text(x, y, @ptrCast(scratch.ptr), fg, bg);
}

pub fn drawButton(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, state: ButtonState, palette: Palette) i32 {
    return drawButtonEx(canvas, rect, scratch, text, state, false, false, false, palette);
}

pub fn drawButtonEx(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, state: ButtonState, focused: bool, is_default: bool, is_cancel: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;

    _ = canvas.rect(rect, palette.face);
    const pressed = state == .pressed;
    const hover = state == .hover;
    const top_left = if (pressed) palette.face_shadow else palette.face_light;
    const bottom_right = if (pressed) palette.face_light else palette.face_shadow;

    if (is_default) {
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = default_metrics.bevel }, palette.text);
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.text);
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - default_metrics.bevel, .w = rect.w, .h = default_metrics.bevel }, palette.text);
        _ = canvas.rect(.{ .x = rect.x + rect.w - default_metrics.bevel, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.text);
    }

    const bevel_rect = if (is_default) rect.inset(default_metrics.bevel, default_metrics.bevel) else rect;
    _ = canvas.rect(.{ .x = bevel_rect.x, .y = bevel_rect.y, .w = bevel_rect.w, .h = default_metrics.bevel }, top_left);
    _ = canvas.rect(.{ .x = bevel_rect.x, .y = bevel_rect.y, .w = default_metrics.bevel, .h = bevel_rect.h }, top_left);
    _ = canvas.rect(.{ .x = bevel_rect.x, .y = bevel_rect.y + bevel_rect.h - default_metrics.bevel, .w = bevel_rect.w, .h = default_metrics.bevel }, bottom_right);
    _ = canvas.rect(.{ .x = bevel_rect.x + bevel_rect.w - default_metrics.bevel, .y = bevel_rect.y, .w = default_metrics.bevel, .h = bevel_rect.h }, bottom_right);

    const offset: i32 = if (pressed) 1 else 0;
    const text_rect = bevel_rect.inset(default_metrics.text_pad_x, default_metrics.text_pad_y);
    const result = drawTextInRect(
        canvas,
        .{ .x = text_rect.x + offset, .y = text_rect.y + offset, .w = text_rect.w, .h = text_rect.h },
        scratch,
        text,
        .center,
        if (state == .disabled) palette.disabled_text else palette.text,
        palette.face,
    );
    if ((focused or hover) and state != .disabled) drawFocusRect(canvas, bevel_rect.inset(3, 3), palette);
    if (is_cancel and state != .disabled) {
        _ = canvas.rect(.{ .x = text_rect.x, .y = text_rect.y + text_rect.h - 2, .w = @max(0, text_rect.w), .h = 1 }, palette.face_shadow);
    }
    return result;
}

pub fn buttonMinWidth(text: []const u8) i32 {
    return @max(default_metrics.dialog_button_w, textWidth(text) + default_metrics.text_pad_x * 4);
}

pub fn drawTextField(canvas: Canvas, rect: Rect, scratch: []u8, value: []const u8, focused: bool, disabled: bool, palette: Palette) i32 {
    return drawTextFieldEx(canvas, rect, scratch, value, value.len, .{ .start = value.len, .end = value.len }, focused, disabled, palette);
}

pub fn drawTextFieldEx(canvas: Canvas, rect: Rect, scratch: []u8, value: []const u8, cursor: usize, selection: anytype, focused: bool, disabled: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const bg = if (disabled) palette.face else palette.client_bg;
    _ = canvas.rect(rect, bg);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = default_metrics.bevel }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - default_metrics.bevel, .w = rect.w, .h = default_metrics.bevel }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x + rect.w - default_metrics.bevel, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_light);

    const text_rect = rect.inset(default_metrics.text_pad_x, default_metrics.text_pad_y);
    const fitted = copyEllipsizedForCanvas(canvas, scratch, value, text_rect.w);
    const fitted_is_full = fitted.len == value.len and std.mem.eql(u8, fitted, value);
    const visible_value_end = if (fitted_is_full)
        value.len
    else if (fitted.len >= 3 and std.mem.eql(u8, fitted[fitted.len - 3 ..], "..."))
        @min(value.len, fitted.len - 3)
    else
        0;
    const selection_start = @min(selection.start, visible_value_end);
    const selection_end = @min(selection.end, visible_value_end);
    if (selection_start < selection_end and !disabled) {
        const sx = text_rect.x + @as(i32, @intCast(utf8ScalarCount(value[0..selection_start]))) * canvas.font.max_advance;
        const sw = @as(i32, @intCast(utf8ScalarCount(value[selection_start..selection_end]))) * canvas.font.max_advance;
        _ = canvas.rect(.{ .x = sx, .y = text_rect.y + 1, .w = sw, .h = @max(1, text_rect.h - 2) }, palette.select_bg);
    }
    if (fitted.len > 0) {
        const y = text_rect.y + @max(0, @divTrunc(text_rect.h - canvas.font.line_height, 2));
        _ = canvas.text(text_rect.x, y, @ptrCast(scratch.ptr), if (disabled) palette.disabled_text else palette.text, if (selection_start < selection_end) palette.select_bg else bg);
    }

    if (focused and !disabled and text_rect.h > 2) {
        const caret_byte = @min(cursor, visible_value_end);
        const caret_chars = if (cursor > visible_value_end and !fitted_is_full) utf8ScalarCount(fitted) else utf8ScalarCount(value[0..caret_byte]);
        const caret_text_w = @min(@as(i32, @intCast(caret_chars)) * canvas.font.max_advance, @max(0, text_rect.w - 1));
        _ = canvas.rect(.{
            .x = text_rect.x + caret_text_w,
            .y = text_rect.y + 2,
            .w = 1,
            .h = @max(1, text_rect.h - 4),
        }, palette.text);
    }
    return 0;
}

pub fn drawTextArea(canvas: Canvas, rect: Rect, scratch: []u8, value: []const u8, focused: bool, disabled: bool, palette: Palette) i32 {
    return drawTextAreaEx(canvas, rect, scratch, value, value.len, .{ .start = value.len, .end = value.len }, 0, 0, focused, disabled, palette);
}

pub fn drawTextAreaEx(canvas: Canvas, rect: Rect, scratch: []u8, value: []const u8, cursor: usize, selection: TextRange, scroll_line: usize, scroll_col: usize, focused: bool, disabled: bool, palette: Palette) i32 {
    return drawTextAreaExWithWrap(canvas, rect, scratch, value, cursor, selection, scroll_line, scroll_col, true, focused, disabled, palette);
}

pub fn drawTextAreaExWithWrap(canvas: Canvas, rect: Rect, scratch: []u8, value: []const u8, cursor: usize, selection: TextRange, scroll_line: usize, scroll_col: usize, word_wrap: bool, focused: bool, disabled: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const bg = if (disabled) palette.face else palette.client_bg;
    drawInsetFrame(canvas, rect, palette, true);

    const text_rect = textAreaClientRect(rect);
    if (text_rect.isEmpty()) return 0;
    _ = canvas.rect(text_rect, bg);
    const char_w = @max(1, canvas.font.max_advance);
    const line_h = @max(1, canvas.font.line_height);
    const visible_cols: usize = @intCast(@max(1, @divTrunc(text_rect.w, char_w)));
    const visible_rows_raw: usize = @intCast(@max(1, @divTrunc(text_rect.h, line_h)));
    const visible_rows: usize = @min(@as(usize, 128), visible_rows_raw);
    const visible_text_cols = if (scratch.len == 0) @as(usize, 0) else @min(visible_cols, scratch.len - 1);
    const wrap_cols = if (word_wrap) visible_cols else 0;
    const text_color = if (disabled) palette.disabled_text else palette.text;

    var row: usize = 0;
    while (row < visible_rows) : (row += 1) {
        const visual_line = scroll_line + row;
        const line_range = textAreaVisualLineRange(value, visual_line, wrap_cols);
        const draw_start = utf8ByteIndexForColumns(value, line_range.start, line_range.end, scroll_col);
        const draw_end = utf8ByteIndexForColumns(value, draw_start, line_range.end, visible_text_cols);
        const y = text_rect.y + @as(i32, @intCast(row)) * line_h;
        if (draw_end <= draw_start) continue;

        const selected = TextRange.normalized(@min(selection.start, value.len), @min(selection.end, value.len));
        const sel_start = @max(draw_start, selected.start);
        const sel_end = @min(draw_end, selected.end);
        if (!disabled and sel_start < sel_end) {
            drawTextAreaSegment(canvas, scratch, value, draw_start, sel_start, draw_start, text_rect.x, y, char_w, text_color, bg);
            const sx = text_rect.x + @as(i32, @intCast(utf8VisualColumnCount(value[draw_start..sel_start]))) * char_w;
            const sw = @as(i32, @intCast(utf8VisualColumnCount(value[sel_start..sel_end]))) * char_w;
            _ = canvas.rect(.{ .x = sx, .y = y, .w = sw, .h = @min(line_h, @max(1, text_rect.bottom() - y)) }, palette.select_bg);
            drawTextAreaSegment(canvas, scratch, value, sel_start, sel_end, draw_start, text_rect.x, y, char_w, palette.select_text, palette.select_bg);
            drawTextAreaSegment(canvas, scratch, value, sel_end, draw_end, draw_start, text_rect.x, y, char_w, text_color, bg);
        } else {
            drawTextAreaSegment(canvas, scratch, value, draw_start, draw_end, draw_start, text_rect.x, y, char_w, text_color, bg);
        }
    }

    if (focused and !disabled) {
        const caret = textAreaVisualPoint(value, @min(cursor, value.len), wrap_cols);
        if (caret.line >= scroll_line and caret.line < scroll_line + visible_rows and caret.column >= scroll_col and caret.column <= scroll_col + visible_cols) {
            const row_y = text_rect.y + @as(i32, @intCast(caret.line - scroll_line)) * line_h;
            const raw_x = text_rect.x + @as(i32, @intCast(caret.column - scroll_col)) * char_w;
            const x = @min(@max(text_rect.x, raw_x), @max(text_rect.x, text_rect.right() - 1));
            _ = canvas.rect(.{ .x = x, .y = row_y, .w = 1, .h = @min(line_h, @max(1, text_rect.bottom() - row_y)) }, palette.text);
        }
    }
    return 0;
}

pub fn drawCheckbox(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, checked: bool, disabled: bool, focused: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const box = checkboxBoxRect(rect);
    drawInsetFrame(canvas, box, palette, true);
    if (checked) {
        _ = canvas.text(box.x + 3, box.y + 3, "x", if (disabled) palette.disabled_text else palette.text, palette.client_bg);
    }
    const label_rect = Rect{ .x = box.x + box.w + 6, .y = rect.y, .w = @max(0, rect.w - box.w - 6), .h = rect.h };
    _ = drawTextInRect(canvas, label_rect, scratch, text, .left, if (disabled) palette.disabled_text else palette.text, palette.client_bg);
    if (focused and !disabled) drawFocusRect(canvas, label_rect.inset(0, 2), palette);
    return 0;
}

pub fn drawRadioButton(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, selected: bool, disabled: bool, focused: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const dot = checkboxBoxRect(rect);
    _ = canvas.rect(dot, palette.client_bg);
    _ = canvas.rect(.{ .x = dot.x + 2, .y = dot.y, .w = @max(0, dot.w - 4), .h = 1 }, palette.face_shadow);
    _ = canvas.rect(.{ .x = dot.x, .y = dot.y + 2, .w = 1, .h = @max(0, dot.h - 4) }, palette.face_shadow);
    _ = canvas.rect(.{ .x = dot.x + 2, .y = dot.y + dot.h - 1, .w = @max(0, dot.w - 4), .h = 1 }, palette.face_light);
    _ = canvas.rect(.{ .x = dot.x + dot.w - 1, .y = dot.y + 2, .w = 1, .h = @max(0, dot.h - 4) }, palette.face_light);
    if (selected) _ = canvas.rect(.{ .x = dot.x + 4, .y = dot.y + 4, .w = @max(1, dot.w - 8), .h = @max(1, dot.h - 8) }, if (disabled) palette.disabled_text else palette.text);
    const label_rect = Rect{ .x = dot.x + dot.w + 6, .y = rect.y, .w = @max(0, rect.w - dot.w - 6), .h = rect.h };
    _ = drawTextInRect(canvas, label_rect, scratch, text, .left, if (disabled) palette.disabled_text else palette.text, palette.client_bg);
    if (focused and !disabled) drawFocusRect(canvas, label_rect.inset(0, 2), palette);
    return 0;
}

pub fn drawGroupBox(canvas: Canvas, rect: Rect, scratch: []u8, title: []const u8, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const top_y = rect.y + @divTrunc(canvas.font.line_height, 2);
    _ = canvas.rect(.{ .x = rect.x, .y = top_y, .w = rect.w, .h = 1 }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x, .y = top_y + 1, .w = rect.w, .h = 1 }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x, .y = top_y, .w = 1, .h = @max(0, rect.h - @divTrunc(canvas.font.line_height, 2)) }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x + rect.w - 1, .y = top_y, .w = 1, .h = @max(0, rect.h - @divTrunc(canvas.font.line_height, 2)) }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - 1, .w = rect.w, .h = 1 }, palette.face_light);
    if (title.len > 0) {
        const title_rect = Rect{ .x = rect.x + 8, .y = rect.y, .w = @max(0, rect.w - 16), .h = canvas.font.line_height + 2 };
        _ = drawTextInRect(canvas, title_rect, scratch, title, .left, palette.text, palette.face);
    }
    return 0;
}

pub fn drawSeparator(canvas: Canvas, rect: Rect, vertical: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    if (vertical) {
        const x = rect.x + @divTrunc(rect.w, 2);
        _ = canvas.rect(.{ .x = x, .y = rect.y, .w = 1, .h = rect.h }, palette.face_shadow);
        return canvas.rect(.{ .x = x + 1, .y = rect.y, .w = 1, .h = rect.h }, palette.face_light);
    }
    const y = rect.y + @divTrunc(rect.h, 2);
    _ = canvas.rect(.{ .x = rect.x, .y = y, .w = rect.w, .h = 1 }, palette.face_shadow);
    return canvas.rect(.{ .x = rect.x, .y = y + 1, .w = rect.w, .h = 1 }, palette.face_light);
}

pub fn drawDropdown(canvas: Canvas, rect: Rect, scratch: []u8, items: []const []const u8, selected_index: usize, hover_index: ?usize, open: bool, disabled: bool, focused: bool, palette: Palette) i32 {
    return drawDropdownEx(canvas, rect, scratch, items, selected_index, hover_index, 0, items.len, open, disabled, focused, palette);
}

pub fn drawDropdownEx(canvas: Canvas, rect: Rect, scratch: []u8, items: []const []const u8, selected_index: usize, hover_index: ?usize, first_index: usize, max_visible_rows: usize, open: bool, disabled: bool, focused: bool, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const text = if (selected_index < items.len) items[selected_index] else "";
    _ = drawTextField(canvas, rect, scratch, text, false, disabled, palette);
    const arrow = dropdownArrowRect(rect);
    _ = drawButtonEx(canvas, arrow, scratch, "v", if (disabled) .disabled else if (open) .pressed else .normal, false, false, false, palette);
    if (focused and !disabled) drawFocusRect(canvas, rect.inset(3, 3), palette);
    if (open and !disabled) {
        const list_rect = dropdownListRectEx(rect, items.len, max_visible_rows);
        _ = drawListEx(canvas, list_rect, scratch, items, selected_index, hover_index, first_index, null, default_metrics.list_row_h, palette);
    }
    return 0;
}

pub fn drawList(canvas: Canvas, rect: Rect, scratch: []u8, items: []const []const u8, selected_index: usize, row_h: i32, palette: Palette) i32 {
    return drawListEx(canvas, rect, scratch, items, selected_index, null, 0, null, row_h, palette);
}

pub fn drawListEx(canvas: Canvas, rect: Rect, scratch: []u8, items: []const []const u8, selected_index: usize, hover_index: ?usize, first_index: usize, disabled_index: ?usize, row_h: i32, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    _ = canvas.rect(rect, palette.client_bg);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = default_metrics.bevel }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - default_metrics.bevel, .w = rect.w, .h = default_metrics.bevel }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x + rect.w - default_metrics.bevel, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_light);

    const inner = rect.inset(default_metrics.frame_inset, default_metrics.frame_inset);
    const effective_row_h = listRowHeight(row_h);
    if (inner.h < effective_row_h) return 0;

    const max_rows: usize = @intCast(@divTrunc(inner.h, effective_row_h));
    const start = @min(first_index, items.len);
    const count = @min(items.len - start, max_rows);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const item_index = start + i;
        const y = inner.y + @as(i32, @intCast(i)) * effective_row_h;
        const row = Rect{ .x = inner.x, .y = y, .w = inner.w, .h = effective_row_h };
        const disabled = disabled_index != null and disabled_index.? == item_index;
        const selected = item_index == selected_index and !disabled;
        const hovered = hover_index != null and hover_index.? == item_index and !selected and !disabled;
        const bg = if (selected) palette.select_bg else palette.client_bg;
        const fg = if (disabled) palette.disabled_text else if (selected) palette.select_text else palette.text;
        _ = canvas.rect(row, bg);
        if (hovered) _ = canvas.rect(.{ .x = row.x + 1, .y = row.y + 1, .w = @max(0, row.w - 2), .h = @max(0, row.h - 2) }, palette.face);
        _ = drawTextInRect(canvas, row.inset(default_metrics.text_pad_x, default_metrics.frame_inset), scratch, items[item_index], .left, fg, if (hovered) palette.face else bg);
    }
    return 0;
}

pub fn drawScrollbar(canvas: Canvas, item: Scrollbar, scratch: []u8) i32 {
    if (item.rect.isEmpty()) return 0;
    const state: ButtonState = if (item.disabled) .disabled else .normal;
    const decrement = item.decrementRect();
    const increment = item.incrementRect();
    _ = drawButtonEx(canvas, decrement, scratch, "", state, false, false, false, item.palette);
    _ = drawButtonEx(canvas, increment, scratch, "", state, false, false, false, item.palette);
    const arrow_color = if (item.disabled) item.palette.disabled_text else item.palette.text;
    drawScrollbarArrow(canvas, decrement, item.orientation, false, arrow_color);
    drawScrollbarArrow(canvas, increment, item.orientation, true, arrow_color);
    _ = canvas.rect(item.trackRect(), item.palette.face);
    if (!item.disabled and item.maxFirst() != 0) {
        const thumb = item.thumbRect();
        _ = canvas.rect(thumb, item.palette.face);
        drawInsetFrame(canvas, thumb, item.palette, false);
    }
    return 0;
}

fn drawScrollbarArrow(canvas: Canvas, rect: Rect, orientation: Orientation, increment: bool, color: u32) void {
    if (rect.isEmpty()) return;
    const center_x = rect.x + @divTrunc(rect.w, 2);
    const center_y = rect.y + @divTrunc(rect.h, 2);
    const widths = [_]i32{ 1, 3, 5, 7 };

    for (widths, 0..) |span, index| {
        const step: i32 = @intCast(index);
        switch (orientation) {
            .vertical => {
                const row = center_y - 3 + step;
                const width = if (increment) widths[widths.len - 1 - index] else span;
                _ = canvas.rect(.{ .x = center_x - @divTrunc(width, 2), .y = row, .w = width, .h = 1 }, color);
            },
            .horizontal => {
                const column = center_x - 3 + step;
                const height = if (increment) widths[widths.len - 1 - index] else span;
                _ = canvas.rect(.{ .x = column, .y = center_y - @divTrunc(height, 2), .w = 1, .h = height }, color);
            },
        }
    }
}

pub fn drawToolbarButton(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, state: ButtonState, focused: bool, selected: bool, palette: Palette) i32 {
    _ = selected;
    return drawButtonEx(canvas, rect, scratch, text, state, focused, false, false, palette);
}

pub fn drawTabBar(canvas: Canvas, item: TabBar, scratch: []u8) i32 {
    if (item.rect.isEmpty()) return 0;
    _ = canvas.rect(item.rect, item.palette.face);
    var index: usize = 0;
    while (index < item.items.len) : (index += 1) {
        const tab = item.tabRect(index);
        if (tab.isEmpty()) continue;
        const info = item.items[index];
        const selected = index == item.selected_index and info.enabled;
        const hot = (item.hover_index != null and item.hover_index.? == index and info.enabled) or selected;
        const bg = if (selected) item.palette.client_bg else item.palette.face;
        const fg = if (!info.enabled) item.palette.disabled_text else item.palette.text;
        _ = canvas.rect(tab, bg);
        _ = canvas.rect(.{ .x = tab.x, .y = tab.y, .w = tab.w, .h = 1 }, item.palette.face_light);
        _ = canvas.rect(.{ .x = tab.x, .y = tab.y, .w = 1, .h = tab.h }, item.palette.face_light);
        _ = canvas.rect(.{ .x = tab.x + tab.w - 1, .y = tab.y, .w = 1, .h = tab.h }, item.palette.face_shadow);
        if (!selected) _ = canvas.rect(.{ .x = tab.x, .y = tab.y + tab.h - 1, .w = tab.w, .h = 1 }, item.palette.face_shadow);
        _ = drawTextInRect(canvas, tab.inset(default_metrics.text_pad_x + 2, default_metrics.text_pad_y), scratch, info.text, .center, fg, bg);
        if (hot and item.focused) drawFocusRect(canvas, tab.inset(3, 3), item.palette);
    }
    _ = canvas.rect(.{ .x = item.rect.x, .y = item.rect.y + tabHeight(item.tab_h), .w = item.rect.w, .h = 1 }, item.palette.face_shadow);
    return 0;
}

pub fn drawTableView(canvas: Canvas, item: TableView, scratch: []u8) i32 {
    if (item.rect.isEmpty()) return 0;
    drawInsetFrame(canvas, item.rect, item.palette, true);

    const header = item.headerRect();
    _ = canvas.rect(header, item.palette.face);
    var x = header.x + default_metrics.frame_inset;
    var col: usize = 0;
    while (col < item.columns.len) : (col += 1) {
        const column = item.columns[col];
        const w = @max(0, column.width);
        const cell_rect = Rect{ .x = x, .y = header.y + default_metrics.frame_inset, .w = @min(w, @max(0, header.right() - x - default_metrics.frame_inset)), .h = @max(0, header.h - default_metrics.frame_inset * 2) };
        if (cell_rect.w > 0) {
            _ = canvas.rect(cell_rect, item.palette.face);
            _ = drawTextInRect(canvas, cell_rect.inset(default_metrics.text_pad_x, 0), scratch, column.title, column.alignment, item.palette.text, item.palette.face);
            _ = canvas.rect(.{ .x = cell_rect.right() - 1, .y = cell_rect.y, .w = 1, .h = cell_rect.h }, item.palette.face_shadow);
        }
        x += w;
    }

    const body = item.bodyRect();
    _ = canvas.rect(body, item.palette.client_bg);
    const row_h = listRowHeight(item.row_h);
    const row_count = item.effectiveRowCount();
    const max_rows = visibleTableRows(body, row_h);
    const start = @min(item.first_index, row_count);
    const count = @min(row_count - start, max_rows);
    var row: usize = 0;
    while (row < count) : (row += 1) {
        const row_index = start + row;
        const y = body.y + @as(i32, @intCast(row)) * row_h;
        const row_rect = Rect{ .x = body.x, .y = y, .w = body.w, .h = row_h };
        const selected = row_index == item.selected_index;
        const hovered = item.hover_index != null and item.hover_index.? == row_index and !selected;
        const bg = if (selected) item.palette.select_bg else if (hovered) item.palette.face else item.palette.client_bg;
        const fg = if (selected) item.palette.select_text else item.palette.text;
        _ = canvas.rect(row_rect, bg);
        x = row_rect.x + default_metrics.frame_inset;
        col = 0;
        while (col < item.columns.len) : (col += 1) {
            const column = item.columns[col];
            const w = @max(0, column.width);
            const cell_rect = Rect{ .x = x, .y = row_rect.y, .w = @min(w, @max(0, row_rect.right() - x - default_metrics.frame_inset)), .h = row_rect.h };
            if (cell_rect.w > 0) {
                _ = drawTextInRect(canvas, cell_rect.inset(default_metrics.text_pad_x, default_metrics.frame_inset), scratch, item.cell(row_index, col), column.alignment, fg, bg);
            }
            x += w;
        }
    }
    if (item.needsScrollbar()) {
        _ = (Scrollbar{
            .rect = item.scrollbarRect(),
            .total_items = row_count,
            .visible_items = max_rows,
            .first_index = item.first_index,
            .palette = item.palette,
        }).draw(canvas, scratch);
    }
    if (item.focused) drawFocusRect(canvas, item.rect.inset(3, 3), item.palette);
    return 0;
}

pub fn listIndexAt(rect: Rect, item_count: usize, row_h: i32, x: i32, y: i32) ?usize {
    return listIndexAtEx(rect, item_count, 0, null, row_h, x, y);
}

pub fn listIndexAtEx(rect: Rect, item_count: usize, first_index: usize, disabled_index: ?usize, row_h: i32, x: i32, y: i32) ?usize {
    const inner = rect.inset(default_metrics.frame_inset, default_metrics.frame_inset);
    if (!inner.contains(x, y)) return null;
    const effective_row_h = listRowHeight(row_h);
    const row: usize = @intCast(@divTrunc(y - inner.y, effective_row_h));
    const index = first_index + row;
    if (index >= item_count) return null;
    if (disabled_index != null and disabled_index.? == index) return null;
    return index;
}

pub fn visibleListRows(rect: Rect, row_h: i32) usize {
    const inner = rect.inset(default_metrics.frame_inset, default_metrics.frame_inset);
    if (inner.isEmpty()) return 0;
    return @intCast(@divTrunc(inner.h, listRowHeight(row_h)));
}

pub fn listFirstIndexForSelection(item_count: usize, visible_rows: usize, selected_index: usize, current_first: usize) usize {
    if (item_count == 0 or visible_rows == 0) return 0;
    const selected = @min(selected_index, item_count - 1);
    if (selected < current_first) return selected;
    if (selected >= current_first + visible_rows) return selected + 1 - visible_rows;
    return @min(current_first, item_count - 1);
}

pub fn selectionStep(item_count: usize, selected_index: usize, key: u8) SelectionStep {
    if (item_count == 0) return .{};
    const selected = @min(selected_index, item_count - 1);
    const next_index = switch (key) {
        Key.up => if (selected == 0) item_count - 1 else selected - 1,
        Key.down => if (selected + 1 >= item_count) 0 else selected + 1,
        Key.home => 0,
        Key.end => item_count - 1,
        else => return .{ .index = selected },
    };
    return .{
        .action = if (next_index == selected) .none else .selection_changed,
        .index = next_index,
    };
}

pub fn selectionStepPaged(item_count: usize, visible_rows: usize, selected_index: usize, key: u8) SelectionStep {
    if (item_count == 0) return .{};
    const selected = @min(selected_index, item_count - 1);
    const page = @max(@as(usize, 1), visible_rows);
    const next_index = switch (key) {
        Key.page_up => if (selected <= page) 0 else selected - page,
        Key.page_down => @min(item_count - 1, selected + page),
        else => return selectionStep(item_count, selected, key),
    };
    return .{
        .action = if (next_index == selected) .none else .selection_changed,
        .index = next_index,
    };
}

pub fn drawMenu(canvas: Canvas, rect: Rect, scratch: []u8, items: []const MenuItem, selected_index: ?usize, row_h: i32, palette: Palette) i32 {
    return drawMenuEx(canvas, rect, scratch, items, selected_index, null, row_h, palette);
}

pub fn drawMenubar(canvas: Canvas, rect: Rect, scratch: []u8, menus: []const MenubarMenu, state: MenubarState, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    _ = canvas.rect(rect, palette.face);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.bottom() - 1, .w = rect.w, .h = 1 }, palette.face_shadow);

    var i: usize = 0;
    while (i < menus.len) : (i += 1) {
        const header = menubarHeaderRect(rect, menus, i);
        if (header.isEmpty()) continue;
        const enabled = menus[i].enabled;
        const hot = enabled and ((state.active_menu != null and state.active_menu.? == i) or (state.hover_menu != null and state.hover_menu.? == i));
        const bg = if (hot) palette.select_bg else palette.face;
        const fg = if (!enabled) palette.disabled_text else if (hot) palette.select_text else palette.text;
        _ = canvas.rect(header.inset(1, 1), bg);
        _ = drawTextInRect(canvas, header.inset(default_metrics.menu_bar_pad_x, default_metrics.text_pad_y), scratch, menus[i].text, .left, fg, bg);
    }

    if (state.active_menu) |menu_index| {
        if (menu_index < menus.len) {
            _ = drawMenuEx(canvas, menubarPopupRect(rect, menus, menu_index), scratch, menus[menu_index].items, state.selected_item, null, default_metrics.menu_row_h, palette);
        }
    }
    return 0;
}

pub fn drawMenuEx(canvas: Canvas, rect: Rect, scratch: []u8, items: []const MenuItem, selected_index: ?usize, hover_index: ?usize, row_h: i32, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    _ = canvas.rect(rect, palette.face);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = default_metrics.bevel }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - default_metrics.bevel, .w = rect.w, .h = default_metrics.bevel }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x + rect.w - default_metrics.bevel, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_shadow);

    const inner = rect.inset(default_metrics.frame_inset, default_metrics.frame_inset);
    const effective_row_h = menuRowHeight(row_h);
    if (inner.h < effective_row_h) return 0;

    const max_rows: usize = @intCast(@divTrunc(inner.h, effective_row_h));
    const count = @min(items.len, max_rows);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const y = inner.y + @as(i32, @intCast(i)) * effective_row_h;
        const row = Rect{ .x = inner.x, .y = y, .w = inner.w, .h = effective_row_h };
        const item = items[i];
        if (item.separator_before) {
            _ = canvas.rect(.{ .x = row.x + 3, .y = row.y, .w = @max(0, row.w - 6), .h = 1 }, palette.face_shadow);
        }

        const selected = selected_index != null and selected_index.? == i and item.enabled;
        const hovered = hover_index != null and hover_index.? == i and item.enabled;
        const hot = selected or hovered;
        const bg = if (hot) palette.select_bg else palette.face;
        const fg = if (!item.enabled) palette.disabled_text else if (hot) palette.select_text else palette.text;
        _ = canvas.rect(row.inset(1, 1), bg);
        const text_rect = row.inset(default_metrics.menu_text_pad_x, default_metrics.text_pad_y);
        if (item.shortcut.len == 0) {
            _ = drawTextInRect(canvas, text_rect, scratch, item.text, .left, fg, bg);
        } else {
            const shortcut_w = textWidth(item.shortcut) + default_metrics.menu_text_pad_x;
            const left_rect = Rect{ .x = text_rect.x, .y = text_rect.y, .w = @max(0, text_rect.w - shortcut_w), .h = text_rect.h };
            const shortcut_rect = Rect{ .x = text_rect.x + @max(0, text_rect.w - shortcut_w), .y = text_rect.y, .w = @min(shortcut_w, text_rect.w), .h = text_rect.h };
            _ = drawTextInRect(canvas, left_rect, scratch, item.text, .left, fg, bg);
            _ = drawTextInRect(canvas, shortcut_rect, scratch, item.shortcut, .right, fg, bg);
        }
    }
    return 0;
}

pub fn menubarHeaderRect(rect: Rect, menus: []const MenubarMenu, index: usize) Rect {
    if (index >= menus.len) return .{};
    var x = rect.x;
    var i: usize = 0;
    while (i < index) : (i += 1) x += menubarHeaderWidth(menus[i].text);
    const w = @min(menubarHeaderWidth(menus[index].text), @max(0, rect.right() - x));
    return .{ .x = x, .y = rect.y, .w = w, .h = @min(default_metrics.menu_bar_h, @max(0, rect.h)) };
}

pub fn menubarPopupRect(rect: Rect, menus: []const MenubarMenu, index: usize) Rect {
    if (index >= menus.len) return .{};
    const header = menubarHeaderRect(rect, menus, index);
    const width = @max(menus[index].min_popup_w, menuPopupWidth(menus[index].items));
    return .{
        .x = header.x,
        .y = rect.y + @min(default_metrics.menu_bar_h, @max(0, rect.h)),
        .w = width,
        .h = menuPopupHeight(menus[index].items, default_metrics.menu_row_h),
    };
}

pub fn menubarMenuIndexAt(rect: Rect, menus: []const MenubarMenu, x: i32, y: i32) ?usize {
    const bar = Rect{ .x = rect.x, .y = rect.y, .w = rect.w, .h = @min(default_metrics.menu_bar_h, @max(0, rect.h)) };
    if (!bar.contains(x, y)) return null;
    var i: usize = 0;
    while (i < menus.len) : (i += 1) {
        if (!menus[i].enabled) continue;
        if (menubarHeaderRect(rect, menus, i).contains(x, y)) return i;
    }
    return null;
}

pub fn menubarHitTest(rect: Rect, menus: []const MenubarMenu, active_menu: ?usize, x: i32, y: i32) MenubarHit {
    if (menubarMenuIndexAt(rect, menus, x, y)) |menu_index| return .{ .part = .header, .menu_index = menu_index };
    if (active_menu) |menu_index| {
        if (menu_index < menus.len) {
            const popup = menubarPopupRect(rect, menus, menu_index);
            if (menuIndexAt(popup, menus[menu_index].items, default_metrics.menu_row_h, x, y)) |item_index| {
                return .{ .part = .item, .menu_index = menu_index, .item_index = item_index, .command_id = menus[menu_index].items[item_index].id };
            }
        }
    }
    return .{ .part = .backdrop };
}

pub fn menubarHeaderWidth(text: []const u8) i32 {
    return textWidth(text) + default_metrics.menu_bar_pad_x * 2;
}

pub fn menuPopupWidth(items: []const MenuItem) i32 {
    var width = default_metrics.menu_popup_min_w;
    for (items) |item| {
        const shortcut_w = if (item.shortcut.len == 0) 0 else textWidth(item.shortcut) + default_metrics.menu_text_pad_x * 2;
        width = @max(width, textWidth(item.text) + shortcut_w + default_metrics.menu_text_pad_x * 2 + default_metrics.frame_inset * 2);
    }
    return width;
}

pub fn menuPopupHeight(items: []const MenuItem, row_h: i32) i32 {
    return @as(i32, @intCast(items.len)) * menuRowHeight(row_h) + default_metrics.frame_inset * 2;
}

pub fn menuIndexAt(rect: Rect, items: []const MenuItem, row_h: i32, x: i32, y: i32) ?usize {
    const inner = rect.inset(default_metrics.frame_inset, default_metrics.frame_inset);
    if (!inner.contains(x, y)) return null;
    const effective_row_h = menuRowHeight(row_h);
    const row: usize = @intCast(@divTrunc(y - inner.y, effective_row_h));
    if (row >= items.len) return null;
    if (!menuItemActionable(items[row])) return null;
    return row;
}

pub fn menuKeyAction(items: []const MenuItem, selected_index: ?usize, key: u8) MenuKeyResult {
    return switch (key) {
        Key.escape, Key.left => .{ .action = .cancelled, .index = selected_index },
        Key.enter, ' ', Key.right => if (selected_index != null and selected_index.? < items.len and menuItemActionable(items[selected_index.?]))
            .{ .action = .submitted, .index = selected_index, .command_id = items[selected_index.?].id }
        else
            .{},
        Key.up => .{ .action = .selection_changed, .index = enabledMenuIndex(items, selected_index, .previous) },
        Key.down => .{ .action = .selection_changed, .index = enabledMenuIndex(items, selected_index, .next) },
        else => .{ .index = selected_index },
    };
}

pub fn modalDialogRect(parent: Rect, width: i32, height: i32) Rect {
    return centeredRect(parent, @max(default_metrics.dialog_min_w, width), @max(default_metrics.dialog_min_h, height));
}

pub fn dialogTitleRect(rect: Rect) Rect {
    return .{
        .x = rect.x + default_metrics.text_pad_y,
        .y = rect.y + default_metrics.text_pad_y,
        .w = @max(0, rect.w - default_metrics.text_pad_y * 2),
        .h = default_metrics.dialog_title_h,
    };
}

pub fn dialogContentRect(rect: Rect) Rect {
    const top = dialogTitleRect(rect).bottom() + default_metrics.gap;
    const button_top = dialogButtonBarRect(rect).y;
    return .{
        .x = rect.x + default_metrics.dialog_outer_pad,
        .y = top,
        .w = @max(0, rect.w - default_metrics.dialog_outer_pad * 2),
        .h = @max(0, button_top - top - default_metrics.gap),
    };
}

pub fn dialogButtonBarRect(rect: Rect) Rect {
    const h = default_metrics.dialog_button_h + default_metrics.dialog_button_margin;
    return .{
        .x = rect.x + default_metrics.dialog_outer_pad,
        .y = rect.y + @max(0, rect.h - h - default_metrics.dialog_button_margin),
        .w = @max(0, rect.w - default_metrics.dialog_outer_pad * 2),
        .h = h,
    };
}

pub fn dialogStatusRect(rect: Rect) Rect {
    const bar = dialogButtonBarRect(rect);
    return .{
        .x = rect.x + default_metrics.dialog_outer_pad,
        .y = @max(dialogTitleRect(rect).bottom(), bar.y - default_metrics.dialog_status_h - default_metrics.gap),
        .w = @max(0, rect.w - default_metrics.dialog_outer_pad * 2),
        .h = default_metrics.dialog_status_h,
    };
}

pub fn dialogRowRect(rect: Rect, row: usize, height: i32) Rect {
    const content = dialogContentRect(rect);
    const row_h = @max(@max(1, height), default_metrics.text_field_h);
    const y = content.y + @as(i32, @intCast(row)) * (row_h + default_metrics.gap);
    return .{
        .x = content.x,
        .y = y,
        .w = content.w,
        .h = @min(row_h, @max(0, content.bottom() - y)),
    };
}

pub fn dialogLabelRect(row: Rect, label_w: i32) Rect {
    return .{
        .x = row.x,
        .y = row.y,
        .w = @min(@max(0, label_w), row.w),
        .h = row.h,
    };
}

pub fn dialogFieldRect(row: Rect, label_w: i32) Rect {
    const gap = default_metrics.gap;
    const label = @min(@max(0, label_w), row.w);
    return .{
        .x = row.x + label + gap,
        .y = row.y,
        .w = @max(0, row.w - label - gap),
        .h = row.h,
    };
}

pub fn dialogDropdownRect(row: Rect, label_w: i32) Rect {
    return dialogFieldRect(row, label_w);
}

pub fn dialogButtonRect(rect: Rect, count: usize, index: usize, button_align: DialogButtonAlign) Rect {
    if (count == 0 or index >= count) return .{};
    const w = default_metrics.dialog_button_w;
    const h = default_metrics.dialog_button_h;
    const gap = default_metrics.dialog_button_gap;
    const total_w = @as(i32, @intCast(count)) * w + @as(i32, @intCast(count - 1)) * gap;
    const x0 = switch (button_align) {
        .center => rect.x + @max(0, @divTrunc(rect.w - total_w, 2)),
        .right => rect.x + @max(0, rect.w - default_metrics.dialog_button_margin - total_w),
    };
    return .{
        .x = x0 + @as(i32, @intCast(index)) * (w + gap),
        .y = rect.y + @max(0, rect.h - h - default_metrics.dialog_button_margin),
        .w = @min(w, @max(0, rect.w - default_metrics.dialog_button_margin * 2)),
        .h = h,
    };
}

pub fn dialogButtonActionAt(rect: Rect, buttons: []const DialogButton, button_align: DialogButtonAlign, x: i32, y: i32) DialogAction {
    var i: usize = 0;
    while (i < buttons.len) : (i += 1) {
        if (!buttons[i].enabled or buttons[i].action == .none) continue;
        if (dialogButtonRect(rect, buttons.len, i, button_align).contains(x, y)) return buttons[i].action;
    }
    return .none;
}

pub fn dialogDefaultAction(buttons: []const DialogButton) DialogAction {
    for (buttons) |button| {
        if (button.enabled and button.role == .default and button.action != .none) return button.action;
    }
    for (buttons) |button| {
        if (button.enabled and button.action != .none) return button.action;
    }
    return .none;
}

pub fn dialogCancelAction(buttons: []const DialogButton) DialogAction {
    for (buttons) |button| {
        if (button.enabled and button.role == .cancel and button.action != .none) return button.action;
    }
    return dialogDefaultAction(buttons);
}

pub fn dialogSubmitAction(buttons: []const DialogButton, focus_action: DialogAction) DialogAction {
    for (buttons) |button| {
        if (button.enabled and button.action == focus_action and button.action != .none) return button.action;
    }
    return dialogDefaultAction(buttons);
}

pub fn dialogKeyAction(buttons: []const DialogButton, focus_action: DialogAction, key: u8) DialogAction {
    return switch (key) {
        Key.escape => dialogCancelAction(buttons),
        Key.enter, '\n', ' ' => dialogSubmitAction(buttons, focus_action),
        else => .none,
    };
}

pub fn dialogFirstFocusAction(items: []const DialogFocusItem) DialogAction {
    for (items) |item| {
        if (item.enabled and item.action != .none) return item.action;
    }
    return .none;
}

pub fn dialogFocusIndex(items: []const DialogFocusItem, action: DialogAction) ?usize {
    if (action == .none) return null;
    var i: usize = 0;
    while (i < items.len) : (i += 1) {
        if (items[i].enabled and items[i].action == action) return i;
    }
    return null;
}

pub fn dialogFocusStep(items: []const DialogFocusItem, current: DialogAction, direction: FocusDirection) DialogAction {
    if (items.len == 0) return .none;
    var index = dialogFocusIndex(items, current) orelse switch (direction) {
        .next => items.len - 1,
        .previous => 0,
    };
    var steps: usize = 0;
    while (steps < items.len) : (steps += 1) {
        index = switch (direction) {
            .next => if (index + 1 >= items.len) 0 else index + 1,
            .previous => if (index == 0) items.len - 1 else index - 1,
        };
        if (items[index].enabled and items[index].action != .none) return items[index].action;
    }
    return .none;
}

pub fn drawDialogFrame(canvas: Canvas, rect: Rect, scratch: []u8, title: []const u8, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    _ = canvas.rect(rect, palette.face);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = default_metrics.bevel }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_light);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - default_metrics.bevel, .w = rect.w, .h = default_metrics.bevel }, palette.face_shadow);
    _ = canvas.rect(.{ .x = rect.x + rect.w - default_metrics.bevel, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, palette.face_shadow);

    const title_rect = dialogTitleRect(rect);
    _ = canvas.rect(title_rect, palette.title_bg);
    return drawTextInRect(canvas, title_rect.inset(default_metrics.text_pad_x, 0), scratch, title, .left, palette.title_text, palette.title_bg);
}

pub fn drawDialogButtons(canvas: Canvas, rect: Rect, scratch: []u8, buttons: []const DialogButton, focus_action: DialogAction, pressed_action: DialogAction, button_align: DialogButtonAlign, palette: Palette) i32 {
    var result: i32 = 0;
    var i: usize = 0;
    while (i < buttons.len) : (i += 1) {
        const button = buttons[i];
        const state: ButtonState = if (!button.enabled) .disabled else if (button.action == pressed_action) .pressed else .normal;
        result = drawButtonEx(
            canvas,
            dialogButtonRect(rect, buttons.len, i, button_align),
            scratch,
            button.text,
            state,
            button.action == focus_action,
            button.role == .default,
            button.role == .cancel,
            palette,
        );
    }
    return result;
}

pub fn drawDialogStatus(canvas: Canvas, rect: Rect, scratch: []u8, text: []const u8, is_error: bool, palette: Palette) i32 {
    if (text.len == 0) return 0;
    const status = dialogStatusRect(rect);
    const fg: u32 = if (is_error) 0xA00000 else palette.disabled_text;
    return drawTextInRect(canvas, status, scratch, text, .left, fg, palette.face);
}

pub fn drawMessageDialog(canvas: Canvas, rect: Rect, scratch: []u8, title: []const u8, message: []const u8, ok_text: []const u8, ok_pressed: bool, palette: Palette) i32 {
    return drawMessageBox(canvas, rect, scratch, title, message, .info, .ok, ok_text, "Cancel", "Yes", "No", if (ok_pressed) .ok else .none, palette);
}

pub fn drawMessageBox(canvas: Canvas, rect: Rect, scratch: []u8, title: []const u8, message: []const u8, kind: MessageKind, buttons: MessageButtons, ok_text: []const u8, cancel_text: []const u8, yes_text: []const u8, no_text: []const u8, pressed_action: DialogAction, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    _ = drawDialogFrame(canvas, rect, scratch, title, palette);
    drawMessageIcon(canvas, .{ .x = rect.x + 14, .y = rect.y + 38, .w = 28, .h = 28 }, kind, palette);
    _ = drawTextInRect(canvas, .{ .x = rect.x + 52, .y = rect.y + 36, .w = @max(0, rect.w - 64), .h = 36 }, scratch, message, .left, palette.text, palette.face);
    switch (buttons) {
        .ok => {
            const dialog_buttons = [_]DialogButton{.{ .action = .ok, .text = ok_text, .role = .default }};
            return drawDialogButtons(canvas, rect, scratch, dialog_buttons[0..], .ok, pressed_action, .center, palette);
        },
        .ok_cancel => {
            const dialog_buttons = [_]DialogButton{
                .{ .action = .ok, .text = ok_text, .role = .default },
                .{ .action = .cancel, .text = cancel_text, .role = .cancel },
            };
            return drawDialogButtons(canvas, rect, scratch, dialog_buttons[0..], .ok, pressed_action, .right, palette);
        },
        .yes_no => {
            const dialog_buttons = [_]DialogButton{
                .{ .action = .yes, .text = yes_text, .role = .default },
                .{ .action = .no, .text = no_text, .role = .cancel },
            };
            return drawDialogButtons(canvas, rect, scratch, dialog_buttons[0..], .yes, pressed_action, .right, palette);
        },
    }
}

pub fn messageDialogOkRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 1, 0, .center);
}

pub fn messageDialogOkRectFor(rect: Rect, buttons: MessageButtons) Rect {
    return switch (buttons) {
        .ok => dialogButtonRect(rect, 1, 0, .center),
        .ok_cancel => dialogButtonRect(rect, 2, 0, .right),
        .yes_no => dialogButtonRect(rect, 2, 0, .right),
    };
}

pub fn messageDialogYesRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 2, 0, .right);
}

pub fn messageDialogNoRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 2, 1, .right);
}

pub fn messageDialogCancelRect(rect: Rect) Rect {
    return messageDialogNoRect(rect);
}

fn drawMessageIcon(canvas: Canvas, rect: Rect, kind: MessageKind, palette: Palette) void {
    const color: u32 = switch (kind) {
        .info => 0x0040C0,
        .warning => 0xD0A000,
        .failure => 0xC00000,
        .question => 0x008080,
    };
    const glyph: [*:0]const u8 = switch (kind) {
        .info => "i",
        .warning => "!",
        .failure => "x",
        .question => "?",
    };
    _ = canvas.rect(rect, color);
    _ = canvas.rect(.{ .x = rect.x + 2, .y = rect.y + 2, .w = @max(0, rect.w - 4), .h = @max(0, rect.h - 4) }, palette.face);
    _ = canvas.text(rect.x + @divTrunc(@max(0, rect.w - canvas.font.max_advance), 2), rect.y + @divTrunc(@max(0, rect.h - canvas.font.line_height), 2), glyph, color, palette.face);
}

pub fn drawFileDialog(canvas: Canvas, rect: Rect, scratch: []u8, title: []const u8, path: []const u8, items: []const []const u8, selected_index: usize, ok_text: []const u8, cancel_text: []const u8, palette: Palette) i32 {
    return drawFileDialogEx(canvas, rect, scratch, title, path, items, selected_index, null, 0, 0, .open, "", ok_text, cancel_text, .none, .none, palette);
}

pub fn drawFileDialogEx(canvas: Canvas, rect: Rect, scratch: []u8, title: []const u8, path: []const u8, items: []const []const u8, selected_index: usize, hover_index: ?usize, first_index: usize, max_visible_rows: usize, mode: FileDialogMode, file_name: []const u8, ok_text: []const u8, cancel_text: []const u8, focus_action: DialogAction, pressed_action: DialogAction, palette: Palette) i32 {
    if (rect.isEmpty()) return 0;
    const selected_file = if (file_name.len != 0) file_name else if (selected_index < items.len) items[selected_index] else "";
    const file_label = switch (mode) {
        .open => "File:",
        .save => "Name:",
    };
    const file_disabled = mode == .open;

    _ = drawDialogFrame(canvas, rect, scratch, title, palette);
    _ = drawTextInRect(canvas, .{ .x = rect.x + 10, .y = rect.y + 29, .w = 44, .h = 16 }, scratch, "Path:", .left, palette.text, palette.face);
    _ = drawTextField(canvas, .{ .x = rect.x + 56, .y = rect.y + 26, .w = @max(0, rect.w - 68), .h = default_metrics.text_field_h }, scratch, path, false, true, palette);
    _ = drawTextInRect(canvas, .{ .x = rect.x + 10, .y = rect.y + 55, .w = 44, .h = 16 }, scratch, file_label, .left, palette.text, palette.face);
    _ = drawTextField(canvas, fileDialogFileNameRect(rect), scratch, selected_file, focus_action == .select and mode == .save, file_disabled, palette);
    const visible_limit = if (max_visible_rows == 0) visibleListRows(fileDialogListRect(rect), default_metrics.list_row_h) else max_visible_rows;
    _ = (List{ .rect = fileDialogListRect(rect), .items = items, .selected_index = selected_index, .hover_index = hover_index, .first_index = first_index, .focused = focus_action == .select }).draw(canvas, scratch);
    if (items.len > visible_limit and visible_limit > 0) {
        _ = (Scrollbar{
            .rect = fileDialogScrollbarRect(rect),
            .total_items = items.len,
            .visible_items = visible_limit,
            .first_index = first_index,
            .palette = palette,
        }).draw(canvas, scratch);
    }
    const buttons = [_]DialogButton{
        .{ .action = .ok, .text = fileDialogOkText(mode, ok_text), .role = .default },
        .{ .action = .cancel, .text = cancel_text, .role = .cancel },
    };
    return drawDialogButtons(canvas, rect, scratch, buttons[0..], focus_action, pressed_action, .right, palette);
}

pub fn fileDialogFileNameRect(rect: Rect) Rect {
    return .{
        .x = rect.x + 56,
        .y = rect.y + 52,
        .w = @max(0, rect.w - 68),
        .h = default_metrics.text_field_h,
    };
}

pub fn fileDialogListRect(rect: Rect) Rect {
    const list = fileDialogListOuterRect(rect);
    return .{
        .x = list.x,
        .y = list.y,
        .w = @max(0, list.w - default_metrics.scrollbar_w),
        .h = list.h,
    };
}

pub fn fileDialogListOuterRect(rect: Rect) Rect {
    return .{
        .x = rect.x + 10,
        .y = rect.y + 82,
        .w = @max(0, rect.w - 20),
        .h = @max(0, rect.h - 122),
    };
}

pub fn fileDialogScrollbarRect(rect: Rect) Rect {
    const list = fileDialogListOuterRect(rect);
    return .{
        .x = list.x + @max(0, list.w - default_metrics.scrollbar_w),
        .y = list.y,
        .w = @min(default_metrics.scrollbar_w, @max(0, list.w)),
        .h = list.h,
    };
}

pub fn fileDialogOkRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 2, 0, .right);
}

pub fn fileDialogCancelRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 2, 1, .right);
}

fn fileDialogOkText(mode: FileDialogMode, text: []const u8) []const u8 {
    if (text.len != 0) return text;
    return switch (mode) {
        .open => "Open",
        .save => "Save",
    };
}

pub fn drawInputDialog(canvas: Canvas, item: InputDialog, scratch: []u8) i32 {
    if (item.rect.isEmpty()) return 0;
    _ = drawDialogFrame(canvas, item.rect, scratch, item.title, item.palette);
    _ = drawTextInRect(canvas, inputDialogLabelRect(item.rect), scratch, item.label, .left, item.palette.text, item.palette.face);
    _ = drawTextField(canvas, item.valueRect(), scratch, item.value, item.focus_action == .select, false, item.palette);
    const buttons = [_]DialogButton{
        .{ .action = .ok, .text = item.ok_text, .role = .default },
        .{ .action = .cancel, .text = item.cancel_text, .role = .cancel },
    };
    return drawDialogButtons(canvas, item.rect, scratch, buttons[0..], item.focus_action, item.pressed_action, .right, item.palette);
}

pub fn inputDialogLabelRect(rect: Rect) Rect {
    return .{
        .x = rect.x + 10,
        .y = rect.y + 34,
        .w = @max(0, rect.w - 20),
        .h = 16,
    };
}

pub fn inputDialogValueRect(rect: Rect) Rect {
    return .{
        .x = rect.x + 10,
        .y = rect.y + 56,
        .w = @max(0, rect.w - 20),
        .h = default_metrics.text_field_h,
    };
}

pub fn inputDialogOkRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 2, 0, .right);
}

pub fn inputDialogCancelRect(rect: Rect) Rect {
    return dialogButtonRect(rect, 2, 1, .right);
}

pub fn scrollbarButtonRect(rect: Rect, orientation: Orientation, part: ScrollbarPart) Rect {
    const size = default_metrics.scrollbar_w;
    return switch (orientation) {
        .vertical => switch (part) {
            .decrement => .{ .x = rect.x, .y = rect.y, .w = rect.w, .h = @min(size, @max(0, rect.h)) },
            .increment => .{ .x = rect.x, .y = rect.y + @max(0, rect.h - size), .w = rect.w, .h = @min(size, @max(0, rect.h)) },
            else => .{},
        },
        .horizontal => switch (part) {
            .decrement => .{ .x = rect.x, .y = rect.y, .w = @min(size, @max(0, rect.w)), .h = rect.h },
            .increment => .{ .x = rect.x + @max(0, rect.w - size), .y = rect.y, .w = @min(size, @max(0, rect.w)), .h = rect.h },
            else => .{},
        },
    };
}

pub fn scrollbarTrackRect(rect: Rect, orientation: Orientation) Rect {
    const size = default_metrics.scrollbar_w;
    return switch (orientation) {
        .vertical => .{
            .x = rect.x,
            .y = rect.y + @min(size, @max(0, rect.h)),
            .w = rect.w,
            .h = @max(0, rect.h - size * 2),
        },
        .horizontal => .{
            .x = rect.x + @min(size, @max(0, rect.w)),
            .y = rect.y,
            .w = @max(0, rect.w - size * 2),
            .h = rect.h,
        },
    };
}

pub fn scrollbarThumbRect(rect: Rect, orientation: Orientation, total_items: usize, visible_items: usize, first_index: usize) Rect {
    const track = scrollbarTrackRect(rect, orientation);
    if (track.isEmpty() or total_items == 0 or visible_items == 0 or total_items <= visible_items) return track;

    const track_len = if (orientation == .vertical) track.h else track.w;
    const min_thumb = @min(track_len, 8);
    const raw_thumb: i32 = @intCast(@divTrunc(@as(u64, @intCast(track_len)) * @as(u64, @intCast(visible_items)), @as(u64, @intCast(total_items))));
    const thumb_len = @min(track_len, @max(min_thumb, raw_thumb));
    const max_first = total_items - visible_items;
    const first = @min(first_index, max_first);
    const travel = @max(0, track_len - thumb_len);
    const offset: i32 = if (max_first == 0) 0 else @intCast(@divTrunc(@as(u64, @intCast(travel)) * @as(u64, @intCast(first)), @as(u64, @intCast(max_first))));

    return switch (orientation) {
        .vertical => .{ .x = track.x, .y = track.y + offset, .w = track.w, .h = thumb_len },
        .horizontal => .{ .x = track.x + offset, .y = track.y, .w = thumb_len, .h = track.h },
    };
}

pub fn scrollbarPartAt(item: Scrollbar, x: i32, y: i32) ScrollbarPart {
    if (item.disabled or !item.rect.contains(x, y)) return .none;
    if (item.decrementRect().contains(x, y)) return .decrement;
    if (item.incrementRect().contains(x, y)) return .increment;
    const thumb = item.thumbRect();
    if (thumb.contains(x, y)) return .thumb;
    const track = item.trackRect();
    if (!track.contains(x, y)) return .none;
    return switch (item.orientation) {
        .vertical => if (y < thumb.y) .page_decrement else .page_increment,
        .horizontal => if (x < thumb.x) .page_decrement else .page_increment,
    };
}

pub fn scrollbarStep(item: Scrollbar, part: ScrollbarPart) ScrollbarStep {
    const max_first = item.maxFirst();
    const first = item.clampedFirst();
    const page = @max(@as(usize, 1), item.visible_items);
    const next = switch (part) {
        .decrement => if (first == 0) 0 else first - 1,
        .increment => @min(max_first, first + 1),
        .page_decrement => if (first <= page) 0 else first - page,
        .page_increment => @min(max_first, first + page),
        else => first,
    };
    return .{
        .action = if (next == first) .none else .changed,
        .first_index = next,
        .part = part,
    };
}

pub fn tabBarItemRect(rect: Rect, items: []const TabItem, index: usize, tab_h: i32) Rect {
    if (index >= items.len) return .{};
    var x = rect.x;
    var i: usize = 0;
    while (i < index) : (i += 1) {
        x += tabWidth(items[i].text);
    }
    const w = @min(tabWidth(items[index].text), @max(0, rect.right() - x));
    return .{ .x = x, .y = rect.y, .w = w, .h = @min(tabHeight(tab_h), @max(0, rect.h)) };
}

pub fn tabBarIndexAt(rect: Rect, items: []const TabItem, tab_h: i32, x: i32, y: i32) ?usize {
    var index: usize = 0;
    while (index < items.len) : (index += 1) {
        const tab = tabBarItemRect(rect, items, index, tab_h);
        if (tab.contains(x, y)) return if (items[index].enabled) index else null;
    }
    return null;
}

fn tabWidth(text: []const u8) i32 {
    return @max(48, textWidth(text) + default_metrics.text_pad_x * 4);
}

fn tabHeight(tab_h: i32) i32 {
    return @max(default_metrics.tab_h, tab_h);
}

fn firstEnabledTabIndex(items: []const TabItem) ?usize {
    var index: usize = 0;
    while (index < items.len) : (index += 1) {
        if (items[index].enabled) return index;
    }
    return null;
}

fn lastEnabledTabIndex(items: []const TabItem) ?usize {
    var index = items.len;
    while (index > 0) {
        index -= 1;
        if (items[index].enabled) return index;
    }
    return null;
}

fn enabledTabIndex(items: []const TabItem, selected_index: usize, direction: FocusDirection) ?usize {
    if (items.len == 0) return null;
    var current = @min(selected_index, items.len - 1);
    var steps: usize = 0;
    while (steps < items.len) : (steps += 1) {
        current = switch (direction) {
            .next => if (current + 1 >= items.len) 0 else current + 1,
            .previous => if (current == 0) items.len - 1 else current - 1,
        };
        if (items[current].enabled) return current;
    }
    return null;
}

pub fn tableHeaderRect(rect: Rect, header_h: i32) Rect {
    const h = @min(@max(default_metrics.table_header_h, header_h), @max(0, rect.h));
    return .{ .x = rect.x + default_metrics.frame_inset, .y = rect.y + default_metrics.frame_inset, .w = @max(0, rect.w - default_metrics.frame_inset * 2), .h = h };
}

pub fn tableBodyRect(rect: Rect, header_h: i32, with_scrollbar: bool) Rect {
    const header = tableHeaderRect(rect, header_h);
    const w = @max(0, rect.w - default_metrics.frame_inset * 2 - if (with_scrollbar) default_metrics.scrollbar_w else 0);
    return .{
        .x = rect.x + default_metrics.frame_inset,
        .y = header.y + header.h,
        .w = w,
        .h = @max(0, rect.bottom() - default_metrics.frame_inset - (header.y + header.h)),
    };
}

pub fn tableScrollbarRect(rect: Rect, header_h: i32) Rect {
    const header = tableHeaderRect(rect, header_h);
    return .{
        .x = rect.right() - default_metrics.frame_inset - default_metrics.scrollbar_w,
        .y = header.y + header.h,
        .w = default_metrics.scrollbar_w,
        .h = @max(0, rect.bottom() - default_metrics.frame_inset - (header.y + header.h)),
    };
}

pub fn visibleTableRows(rect: Rect, row_h: i32) usize {
    if (rect.isEmpty()) return 0;
    return @intCast(@divTrunc(rect.h, listRowHeight(row_h)));
}

pub fn checkboxBoxRect(rect: Rect) Rect {
    const size: i32 = 13;
    return .{
        .x = rect.x,
        .y = rect.y + @max(0, @divTrunc(rect.h - size, 2)),
        .w = @min(size, @max(0, rect.w)),
        .h = @min(size, @max(0, rect.h)),
    };
}

pub fn dropdownArrowRect(rect: Rect) Rect {
    const w: i32 = @min(20, @max(0, rect.w));
    return .{
        .x = rect.x + @max(0, rect.w - w),
        .y = rect.y,
        .w = w,
        .h = rect.h,
    };
}

pub fn dropdownListRect(rect: Rect, item_count: usize) Rect {
    return dropdownListRectEx(rect, item_count, 6);
}

pub fn dropdownListRectEx(rect: Rect, item_count: usize, max_visible_rows: usize) Rect {
    const row_limit = if (max_visible_rows == 0) item_count else max_visible_rows;
    const rows = @min(item_count, row_limit);
    const h = default_metrics.frame_inset * 2 + @as(i32, @intCast(rows)) * default_metrics.list_row_h;
    return .{
        .x = rect.x,
        .y = rect.y + rect.h,
        .w = rect.w,
        .h = h,
    };
}

pub fn screenRect(w: i32, h: i32) Rect {
    return .{ .x = 0, .y = 0, .w = @max(0, w), .h = @max(0, h) };
}

pub fn paddedRect(rect: Rect, padding: i32) Rect {
    return rect.inset(@max(0, padding), @max(0, padding));
}

pub fn toolbarRect(parent: Rect) Rect {
    return .{ .x = parent.x, .y = parent.y, .w = parent.w, .h = @min(default_metrics.toolbar_button_h + default_metrics.frame_inset * 2, @max(0, parent.h)) };
}

pub fn contentBelowToolbar(parent: Rect) Rect {
    const toolbar = toolbarRect(parent);
    return .{ .x = parent.x, .y = toolbar.bottom(), .w = parent.w, .h = @max(0, parent.bottom() - toolbar.bottom()) };
}

pub fn statusBarRect(parent: Rect) Rect {
    const h = @min(default_metrics.status_bar_h, @max(0, parent.h));
    return .{ .x = parent.x, .y = parent.bottom() - h, .w = parent.w, .h = h };
}

pub fn contentAboveStatus(parent: Rect) Rect {
    const status = statusBarRect(parent);
    return .{ .x = parent.x, .y = parent.y, .w = parent.w, .h = @max(0, status.y - parent.y) };
}

pub fn dialogButtonRowRect(rect: Rect) Rect {
    return .{
        .x = rect.x + default_metrics.gap,
        .y = rect.y + @max(0, rect.h - default_metrics.dialog_button_h - default_metrics.gap),
        .w = @max(0, rect.w - default_metrics.gap * 2),
        .h = default_metrics.dialog_button_h,
    };
}

pub fn dialogButtonFromRightRect(row: Rect, index_from_right: usize) Rect {
    const step = default_metrics.dialog_button_w + default_metrics.gap;
    const offset: i32 = @intCast(index_from_right * @as(usize, @intCast(step)));
    return .{
        .x = row.x + @max(0, row.w - default_metrics.dialog_button_w - offset),
        .y = row.y,
        .w = @min(default_metrics.dialog_button_w, @max(0, row.w)),
        .h = row.h,
    };
}

pub fn centeredRect(parent: Rect, w: i32, h: i32) Rect {
    const width = @min(@max(0, w), @max(0, parent.w));
    const height = @min(@max(0, h), @max(0, parent.h));
    return .{
        .x = parent.x + @max(0, @divTrunc(parent.w - width, 2)),
        .y = parent.y + @max(0, @divTrunc(parent.h - height, 2)),
        .w = width,
        .h = height,
    };
}

fn listRowHeight(row_h: i32) i32 {
    return @max(default_metrics.list_row_h, row_h);
}

fn menuRowHeight(row_h: i32) i32 {
    return @max(default_metrics.menu_row_h, row_h);
}

fn firstEnabledFocusIndex(items: []const FocusItem) ?usize {
    var index: usize = 0;
    while (index < items.len) : (index += 1) {
        if (items[index].enabled) return index;
    }
    return null;
}

fn enabledMenuIndex(items: []const MenuItem, selected_index: ?usize, direction: FocusDirection) ?usize {
    if (items.len == 0) return null;
    var current = selected_index orelse switch (direction) {
        .next => items.len - 1,
        .previous => 0,
    };
    if (current >= items.len) current = 0;
    var steps: usize = 0;
    while (steps < items.len) : (steps += 1) {
        current = switch (direction) {
            .next => if (current + 1 >= items.len) 0 else current + 1,
            .previous => if (current == 0) items.len - 1 else current - 1,
        };
        if (menuItemActionable(items[current])) return current;
    }
    return null;
}

fn menuItemActionable(item: MenuItem) bool {
    return item.enabled and item.text.len != 0;
}

fn menubarMenuEnabled(menus: []const MenubarMenu, index: usize) bool {
    return index < menus.len and menus[index].enabled and menus[index].text.len != 0;
}

fn firstEnabledMenubarMenu(menus: []const MenubarMenu) ?usize {
    var i: usize = 0;
    while (i < menus.len) : (i += 1) {
        if (menubarMenuEnabled(menus, i)) return i;
    }
    return null;
}

fn enabledMenubarMenuIndex(menus: []const MenubarMenu, selected_index: ?usize, direction: FocusDirection) ?usize {
    if (menus.len == 0) return null;
    var current = selected_index orelse switch (direction) {
        .next => menus.len - 1,
        .previous => 0,
    };
    if (current >= menus.len) current = 0;
    var steps: usize = 0;
    while (steps < menus.len) : (steps += 1) {
        current = switch (direction) {
            .next => if (current + 1 >= menus.len) 0 else current + 1,
            .previous => if (current == 0) menus.len - 1 else current - 1,
        };
        if (menubarMenuEnabled(menus, current)) return current;
    }
    return null;
}

fn drawInsetFrame(canvas: Canvas, rect: Rect, palette: Palette, sunken: bool) void {
    const top_left = if (sunken) palette.face_shadow else palette.face_light;
    const bottom_right = if (sunken) palette.face_light else palette.face_shadow;
    _ = canvas.rect(rect, if (sunken) palette.client_bg else palette.face);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = default_metrics.bevel }, top_left);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, top_left);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - default_metrics.bevel, .w = rect.w, .h = default_metrics.bevel }, bottom_right);
    _ = canvas.rect(.{ .x = rect.x + rect.w - default_metrics.bevel, .y = rect.y, .w = default_metrics.bevel, .h = rect.h }, bottom_right);
}

fn drawTextAreaSegment(canvas: Canvas, scratch: []u8, value: []const u8, start: usize, end: usize, draw_start: usize, base_x: i32, y: i32, char_w: i32, fg: u32, bg: u32) void {
    if (scratch.len == 0 or start >= end or start >= value.len) return;
    const safe_end = @min(end, value.len);
    const max_command_text: usize = (abi.GuiCommand{}).text.len - 1;
    const chunk_capacity = @min(scratch.len - 1, max_command_text);
    if (chunk_capacity == 0) return;

    var segment_start = start;
    while (segment_start < safe_end) {
        var count = utf8PrefixBytes(value[segment_start..safe_end], std.math.maxInt(usize), chunk_capacity);
        if (count == 0) count = 1;
        @memset(scratch, 0);
        @memcpy(scratch[0..count], value[segment_start .. segment_start + count]);
        scratch[count] = 0;
        const x = base_x + @as(i32, @intCast(utf8VisualColumnCount(value[draw_start..segment_start]))) * char_w;
        _ = canvas.text(x, y, @ptrCast(scratch.ptr), fg, bg);
        segment_start += count;
    }
}

fn drawFocusRect(canvas: Canvas, rect: Rect, palette: Palette) void {
    if (rect.isEmpty()) return;
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = 1 }, palette.text);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = 1, .h = rect.h }, palette.text);
    _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - 1, .w = rect.w, .h = 1 }, palette.text);
    _ = canvas.rect(.{ .x = rect.x + rect.w - 1, .y = rect.y, .w = 1, .h = rect.h }, palette.text);
}

pub fn alignedTextX(rect: Rect, text_len: usize, alignment: Align) i32 {
    const width = @as(i32, @intCast(text_len)) * font_w;
    return alignedTextXWidth(rect, width, alignment);
}

pub fn alignedTextXWidth(rect: Rect, width: i32, alignment: Align) i32 {
    const free = @max(0, rect.w - width);
    return switch (alignment) {
        .left => rect.x,
        .center => rect.x + @divTrunc(free, 2),
        .right => rect.x + free,
    };
}

fn currentFontMetrics(ctx: *const r4draw.Context) FontMetrics {
    var info: abi.GuiFontInfo = .{};
    if (ctx.guiFont(0, &info) >= 0) return fontMetricsFromInfo(info);
    if (ctx.fontInfo(abi.gui_font_builtin_id, &info) > 0) return fontMetricsFromInfo(info);
    return .{};
}

pub fn fontMetricsForId(ctx: *const r4draw.Context, font_id: u32) FontMetrics {
    var info: abi.GuiFontInfo = .{};
    if (ctx.fontInfo(font_id, &info) > 0) return fontMetricsFromInfo(info);
    return currentFontMetrics(ctx);
}

fn fontMetricsFromInfo(info: abi.GuiFontInfo) FontMetrics {
    return .{
        .id = info.id,
        .max_advance = @max(1, clampU32ToI32(info.max_advance)),
        .height = @max(1, clampU32ToI32(info.height)),
        .line_height = @max(1, clampU32ToI32(info.line_height)),
        .baseline = info.baseline,
    };
}

fn fallbackTextWidthZ(value: [*:0]const u8, advance: i32) i32 {
    var len: usize = 0;
    while (len < 4096 and value[len] != 0) : (len += 1) {}
    const text = value[0..len];
    var width: i32 = 0;
    var i: usize = 0;
    while (i < text.len) {
        const ch = text[i];
        i = utf8NextIndex(text, i);
        if (ch == '\r') continue;
        if (ch == '\n') break;
        if (width > std.math.maxInt(i32) - advance) return std.math.maxInt(i32);
        width += advance;
    }
    return width;
}

fn effectiveTextAreaWrapCols(wrap_cols: usize) usize {
    if (wrap_cols == 0) return std.math.maxInt(usize) / 4;
    return @max(@as(usize, 1), wrap_cols);
}

fn normalizeTextAreaByte(ch: u8) ?u8 {
    if (ch == '\r' or ch == '\n') return '\n';
    if (ch == '\t') return '\t';
    if (ch >= 0x20 and ch != 0x7F) return ch;
    return null;
}

fn clampU32ToI32(value: u32) i32 {
    return if (value > @as(u32, @intCast(std.math.maxInt(i32)))) std.math.maxInt(i32) else @intCast(value);
}

test "rect inset keeps non-negative size" {
    const item = Rect{ .x = 4, .y = 6, .w = 20, .h = 12 };
    try std.testing.expectEqual(Rect{ .x = 6, .y = 8, .w = 16, .h = 8 }, item.inset(2, 2));
    try std.testing.expectEqual(Rect{ .x = 14, .y = 16, .w = 0, .h = 0 }, item.inset(10, 10));
    try std.testing.expect(item.contains(4, 6));
    try std.testing.expect(!item.contains(24, 18));
}

test "text metrics use current bitmap font size" {
    try std.testing.expectEqual(@as(usize, 0), charsForWidth(7));
    try std.testing.expectEqual(@as(usize, 4), charsForWidth(32));
    try std.testing.expectEqual(@as(i32, 40), textWidth("Hello"));
}

test "default control metrics document win98 sized primitives" {
    try std.testing.expectEqual(@as(i32, 1), default_metrics.bevel);
    try std.testing.expectEqual(@as(i32, 2), default_metrics.frame_inset);
    try std.testing.expectEqual(@as(i32, 72), default_metrics.dialog_button_w);
    try std.testing.expectEqual(@as(i32, 24), default_metrics.dialog_button_h);
    try std.testing.expectEqual(@as(i32, 22), default_metrics.text_field_h);
    try std.testing.expectEqual(@as(i32, 16), default_metrics.list_row_h);
    try std.testing.expectEqual(@as(i32, 18), default_metrics.menu_row_h);
    try std.testing.expectEqual(@as(i32, 16), default_metrics.scrollbar_w);
    try std.testing.expectEqual(@as(i32, 22), default_metrics.tab_h);
    try std.testing.expectEqual(@as(i32, 18), default_metrics.table_header_h);
}

test "layout helpers split common app regions" {
    const root = screenRect(320, 200);
    try std.testing.expectEqual(Rect{ .x = 0, .y = 0, .w = 320, .h = 200 }, root);
    try std.testing.expectEqual(Rect{ .x = 0, .y = 0, .w = 320, .h = 28 }, toolbarRect(root));
    try std.testing.expectEqual(Rect{ .x = 0, .y = 28, .w = 320, .h = 172 }, contentBelowToolbar(root));
    try std.testing.expectEqual(Rect{ .x = 0, .y = 182, .w = 320, .h = 18 }, statusBarRect(root));
    try std.testing.expectEqual(Rect{ .x = 0, .y = 0, .w = 320, .h = 182 }, contentAboveStatus(root));

    var cursor = LayoutCursor.init(.{ .x = 10, .y = 20, .w = 100, .h = 80 });
    try std.testing.expectEqual(Rect{ .x = 10, .y = 20, .w = 100, .h = 18 }, cursor.takeTop(18, 4));
    try std.testing.expectEqual(Rect{ .x = 10, .y = 42, .w = 100, .h = 58 }, cursor.remaining());
    try std.testing.expectEqual(Rect{ .x = 75, .y = 42, .w = 35, .h = 58 }, cursor.takeRight(35, 5));
    try std.testing.expectEqual(Rect{ .x = 10, .y = 42, .w = 60, .h = 58 }, cursor.remaining());
}

test "copy ellipsized keeps output nul terminated" {
    var out: [8]u8 = .{0xAA} ** 8;
    try std.testing.expectEqualStrings("R4OS", copyEllipsized(out[0..], "R4OS", 64));
    try std.testing.expectEqual(@as(u8, 0), out[4]);

    try std.testing.expectEqualStrings("R4...", copyEllipsized(out[0..], "R4OS Desktop", 40));
    try std.testing.expectEqual(@as(u8, 0), out[5]);

    try std.testing.expectEqualStrings("..", copyEllipsized(out[0..], "R4OS", 16));
    try std.testing.expectEqual(@as(u8, 0), out[2]);
}

test "text metrics and ellipsizing keep utf8 scalars intact" {
    const value = "Gr\xc3\xbc\xc3\x9fe";
    try std.testing.expectEqual(@as(i32, 5 * font_w), textWidth(value));

    var out: [16]u8 = .{0xAA} ** 16;
    try std.testing.expectEqualStrings("Gr\xc3\xbc...", copyEllipsized(out[0..], value ++ "XY", 6 * font_w));
    try std.testing.expectEqual(@as(u8, 0), out[8]);
}

test "aligned text stays inside rect" {
    const rect = Rect{ .x = 10, .y = 0, .w = 80, .h = 16 };
    try std.testing.expectEqual(@as(i32, 10), alignedTextX(rect, 4, .left));
    try std.testing.expectEqual(@as(i32, 34), alignedTextX(rect, 4, .center));
    try std.testing.expectEqual(@as(i32, 58), alignedTextX(rect, 4, .right));
}

test "button hit test uses its rect" {
    const item = Button{ .rect = .{ .x = 20, .y = 30, .w = 80, .h = 24 }, .text = "OK" };
    try std.testing.expect(item.contains(20, 30));
    try std.testing.expect(item.contains(99, 53));
    try std.testing.expect(!item.contains(100, 53));
    try std.testing.expect(!(Button{ .rect = item.rect, .text = "OK", .state = .disabled }).contains(20, 30));
    try std.testing.expectEqual(default_metrics.dialog_button_w, item.minWidth());
    try std.testing.expect((Button{ .rect = item.rect, .text = "A very long button" }).minWidth() > default_metrics.dialog_button_w);
}

test "list hit test maps points to rows" {
    const items = [_][]const u8{ "One", "Two", "Three" };
    const item = List{ .rect = .{ .x = 10, .y = 20, .w = 100, .h = 52 }, .items = items[0..] };
    try std.testing.expectEqual(@as(?usize, 0), item.indexAt(12, 22));
    try std.testing.expectEqual(@as(?usize, 1), item.indexAt(12, 38));
    try std.testing.expectEqual(@as(?usize, 2), item.indexAt(12, 54));
    try std.testing.expectEqual(@as(?usize, null), item.indexAt(12, 70));
    try std.testing.expectEqual(@as(?usize, null), item.indexAt(4, 22));
}

test "list hit test respects scroll and disabled row" {
    const items = [_][]const u8{ "One", "Two", "Three", "Four" };
    const item = List{
        .rect = .{ .x = 10, .y = 20, .w = 100, .h = 52 },
        .items = items[0..],
        .first_index = 1,
        .disabled_index = 2,
    };
    try std.testing.expectEqual(@as(?usize, 1), item.indexAt(12, 22));
    try std.testing.expectEqual(@as(?usize, null), item.indexAt(12, 38));
    try std.testing.expectEqual(@as(?usize, 3), item.indexAt(12, 54));
    try std.testing.expectEqual(@as(usize, 3), item.visibleRows());
    try std.testing.expectEqual(@as(usize, 1), (List{ .rect = item.rect, .items = items[0..], .selected_index = 3, .first_index = 0 }).firstIndexForSelection());
}

test "list and menu row heights clamp to text-safe minimums" {
    try std.testing.expectEqual(default_metrics.list_row_h, listRowHeight(1));
    try std.testing.expectEqual(default_metrics.menu_row_h, menuRowHeight(1));
    try std.testing.expectEqual(@as(i32, 24), listRowHeight(24));
    try std.testing.expectEqual(@as(i32, 24), menuRowHeight(24));
}

test "scrollbar maps parts and step actions" {
    const item = Scrollbar{ .rect = .{ .x = 0, .y = 0, .w = 16, .h = 100 }, .total_items = 20, .visible_items = 5, .first_index = 5 };
    try std.testing.expectEqual(Rect{ .x = 0, .y = 0, .w = 16, .h = 16 }, item.decrementRect());
    try std.testing.expectEqual(Rect{ .x = 0, .y = 84, .w = 16, .h = 16 }, item.incrementRect());
    try std.testing.expectEqual(Rect{ .x = 0, .y = 16, .w = 16, .h = 68 }, item.trackRect());
    try std.testing.expectEqual(Rect{ .x = 0, .y = 33, .w = 16, .h = 17 }, item.thumbRect());
    try std.testing.expectEqual(ScrollbarPart.decrement, item.partAt(4, 4));
    try std.testing.expectEqual(ScrollbarPart.increment, item.partAt(4, 96));
    try std.testing.expectEqual(ScrollbarPart.page_decrement, item.partAt(4, 20));
    try std.testing.expectEqual(ScrollbarPart.page_increment, item.partAt(4, 70));
    try std.testing.expectEqual(ScrollbarStep{ .action = .changed, .first_index = 4, .part = .decrement }, item.step(.decrement));
    try std.testing.expectEqual(ScrollbarStep{ .action = .changed, .first_index = 10, .part = .page_increment }, item.step(.page_increment));
}

test "tab bar skips disabled tabs" {
    const items = [_]TabItem{
        .{ .text = "General" },
        .{ .text = "Hidden", .enabled = false },
        .{ .text = "Advanced" },
    };
    const tabs = TabBar{ .rect = .{ .x = 10, .y = 20, .w = 220, .h = 28 }, .items = items[0..], .selected_index = 0 };
    try std.testing.expectEqual(@as(?usize, 0), tabs.indexAt(12, 22));
    try std.testing.expectEqual(@as(?usize, null), tabs.indexAt(tabs.tabRect(1).x + 2, 22));
    try std.testing.expectEqual(SelectionStep{ .action = .selection_changed, .index = 2 }, tabs.keyAction(Key.right));
    try std.testing.expectEqual(SelectionStep{ .action = .submitted, .index = 0 }, tabs.keyAction(Key.enter));
}

test "table view maps rows and paged selection" {
    const columns = [_]TableColumn{
        .{ .title = "Name", .width = 80 },
        .{ .title = "Type", .width = 60 },
    };
    const cells = [_][]const u8{
        "AUTOEXEC.BAT", "File",
        "BIN",          "Dir",
        "CONFIG.R4S",   "File",
        "DESKTOP",      "Dir",
        "README.TXT",   "File",
        "SYS",          "Dir",
    };
    const table = TableView{
        .rect = .{ .x = 0, .y = 0, .w = 160, .h = 80 },
        .columns = columns[0..],
        .cells = cells[0..],
        .selected_index = 1,
    };
    try std.testing.expectEqual(@as(usize, 6), table.effectiveRowCount());
    try std.testing.expectEqual(@as(usize, 3), table.visibleRows());
    try std.testing.expect(table.needsScrollbar());
    try std.testing.expectEqual(@as(?usize, 0), table.indexAt(5, 23));
    try std.testing.expectEqual(@as(?usize, 1), table.indexAt(5, 39));
    try std.testing.expectEqual(SelectionStep{ .action = .selection_changed, .index = 4 }, table.keyAction(Key.page_down));
    try std.testing.expectEqual(@as(usize, 3), (TableView{ .rect = table.rect, .columns = columns[0..], .cells = cells[0..], .selected_index = 5 }).firstIndexForSelection());
}

test "new basic controls expose stable hit rectangles" {
    const rect = Rect{ .x = 10, .y = 20, .w = 120, .h = 20 };
    try std.testing.expect((Checkbox{ .rect = rect, .text = "Use DHCP" }).contains(12, 22));
    try std.testing.expect(!(Checkbox{ .rect = rect, .text = "Use DHCP", .disabled = true }).contains(12, 22));
    try std.testing.expect((RadioButton{ .rect = rect, .text = "Static" }).contains(12, 22));
    try std.testing.expectEqual(Rect{ .x = 10, .y = 23, .w = 13, .h = 13 }, checkboxBoxRect(rect));
}

test "dropdown exposes arrow and popup rows" {
    const items = [_][]const u8{ "DHCP", "Static", "Link-local" };
    const dropdown = Dropdown{ .rect = .{ .x = 20, .y = 10, .w = 120, .h = 22 }, .items = items[0..], .open = true };
    try std.testing.expect(dropdown.contains(24, 12));
    try std.testing.expect(dropdownArrowRect(dropdown.rect).contains(139, 20));
    try std.testing.expectEqual(@as(?usize, 0), dropdown.indexAt(22, 34));
    try std.testing.expectEqual(@as(?usize, 1), dropdown.indexAt(22, 50));
    try std.testing.expectEqual(@as(?usize, null), (Dropdown{ .rect = dropdown.rect, .items = items[0..] }).indexAt(22, 34));
}

test "menu hit test ignores disabled items" {
    const items = [_]MenuItem{
        .{ .text = "Open" },
        .{ .text = "Save", .enabled = false },
        .{ .text = "Close", .separator_before = true },
    };
    const item = Menu{ .rect = .{ .x = 10, .y = 20, .w = 120, .h = 60 }, .items = items[0..] };
    try std.testing.expectEqual(@as(?usize, 0), item.indexAt(12, 22));
    try std.testing.expectEqual(@as(?usize, null), item.indexAt(12, 40));
    try std.testing.expectEqual(@as(?usize, 2), item.indexAt(12, 58));
    try std.testing.expectEqual(@as(?usize, null), item.indexAt(12, 80));
}

test "menu carries separate keyboard selection and mouse hover" {
    const items = [_]MenuItem{
        .{ .text = "Open" },
        .{ .text = "Save", .enabled = false },
        .{ .text = "Close", .separator_before = true },
    };
    const item = Menu{ .rect = .{ .x = 10, .y = 20, .w = 120, .h = 60 }, .items = items[0..], .selected_index = 0, .hover_index = 2 };
    try std.testing.expectEqual(@as(?usize, 0), item.selected_index);
    try std.testing.expectEqual(@as(?usize, 2), item.hover_index);
    try std.testing.expectEqual(MenuKeyResult{ .action = .selection_changed, .index = 2 }, item.keyAction(Key.down));
}

test "menubar maps headers popup rows shortcuts and command ids" {
    const file_items = [_]MenuItem{
        .{ .text = "New", .id = 101, .shortcut = "Ctrl+N" },
        .{ .text = "Open", .id = 102, .shortcut = "Ctrl+O" },
        .{ .text = "Save", .id = 103, .shortcut = "Ctrl+S", .enabled = false },
        .{ .text = "Exit", .id = 104, .separator_before = true },
    };
    const edit_items = [_]MenuItem{
        .{ .text = "Copy", .id = 201, .shortcut = "Ctrl+C" },
        .{ .text = "Paste", .id = 202, .shortcut = "Ctrl+V" },
    };
    const empty_items = [_]MenuItem{};
    const menus = [_]MenubarMenu{
        .{ .text = "File", .items = file_items[0..] },
        .{ .text = "Edit", .items = edit_items[0..] },
        .{ .text = "Help", .items = empty_items[0..], .enabled = false },
    };
    const rect = Rect{ .x = 0, .y = 0, .w = 320, .h = default_metrics.menu_bar_h };
    const bar = Menubar{ .rect = rect, .menus = menus[0..], .state = .{ .active_menu = 0, .selected_item = 1 } };
    const edit_header = bar.headerRect(1);
    const help_header = bar.headerRect(2);
    const popup = bar.popupRect(0);

    try std.testing.expectEqual(@as(?usize, 0), bar.menuIndexAt(4, 4));
    try std.testing.expectEqual(@as(?usize, 1), bar.menuIndexAt(edit_header.x + 2, edit_header.y + 2));
    try std.testing.expectEqual(@as(?usize, null), bar.menuIndexAt(help_header.x + 2, help_header.y + 2));
    try std.testing.expect(menuPopupWidth(file_items[0..]) >= default_metrics.menu_popup_min_w);
    try std.testing.expectEqual(@as(?usize, 1), menuIndexAt(popup, file_items[0..], default_metrics.menu_row_h, popup.x + 4, popup.y + default_metrics.frame_inset + default_metrics.menu_row_h + 2));
    try std.testing.expectEqual(@as(?usize, null), menuIndexAt(popup, file_items[0..], default_metrics.menu_row_h, popup.x + 4, popup.y + default_metrics.frame_inset + default_metrics.menu_row_h * 2 + 2));
    try std.testing.expectEqual(MenubarHit{ .part = .item, .menu_index = 0, .item_index = 1, .command_id = 102 }, bar.hitTest(popup.x + 4, popup.y + default_metrics.frame_inset + default_metrics.menu_row_h + 2));
}

test "menubar keyboard opens switches and submits command ids" {
    const file_items = [_]MenuItem{
        .{ .text = "New", .id = 101 },
        .{ .text = "Open", .id = 102 },
        .{ .text = "Save", .id = 103, .enabled = false },
    };
    const edit_items = [_]MenuItem{
        .{ .text = "Copy", .id = 201 },
        .{ .text = "Paste", .id = 202 },
    };
    const empty_items = [_]MenuItem{};
    const menus = [_]MenubarMenu{
        .{ .text = "File", .items = file_items[0..] },
        .{ .text = "Help", .items = empty_items[0..], .enabled = false },
        .{ .text = "Edit", .items = edit_items[0..] },
    };
    var state = MenubarState{};

    try std.testing.expectEqual(MenubarResult{ .action = .selection_changed, .menu_index = 0, .item_index = 0 }, state.keyAction(menus[0..], Key.menu_focus));
    try std.testing.expectEqual(MenubarResult{ .action = .selection_changed, .menu_index = 0, .item_index = 1 }, state.keyAction(menus[0..], Key.down));
    try std.testing.expectEqual(MenubarResult{ .action = .submitted, .menu_index = 0, .item_index = 1, .command_id = 102 }, state.keyAction(menus[0..], Key.enter));
    try std.testing.expect(!state.isOpen());

    _ = state.open(menus[0..], 0, true);
    try std.testing.expectEqual(MenubarResult{ .action = .selection_changed, .menu_index = 2, .item_index = 0 }, state.keyAction(menus[0..], Key.right));
    try std.testing.expectEqual(MenubarResult{ .action = .cancelled }, state.keyAction(menus[0..], Key.escape));
    try std.testing.expect(!state.isOpen());
}

test "menubar mouse opens switches submits and closes on backdrop" {
    const file_items = [_]MenuItem{
        .{ .text = "New", .id = 101 },
        .{ .text = "Open", .id = 102 },
    };
    const edit_items = [_]MenuItem{
        .{ .text = "Copy", .id = 201 },
        .{ .text = "Paste", .id = 202 },
    };
    const menus = [_]MenubarMenu{
        .{ .text = "File", .items = file_items[0..] },
        .{ .text = "Edit", .items = edit_items[0..] },
    };
    const rect = Rect{ .x = 0, .y = 0, .w = 240, .h = default_metrics.menu_bar_h };
    var state = MenubarState{};

    const file_header = menubarHeaderRect(rect, menus[0..], 0);
    try std.testing.expectEqual(MenubarResult{ .action = .selection_changed, .menu_index = 0, .item_index = 0 }, state.mouseDown(rect, menus[0..], file_header.x + 2, file_header.y + 2));

    const edit_header = menubarHeaderRect(rect, menus[0..], 1);
    try std.testing.expectEqual(MenubarResult{ .action = .selection_changed, .menu_index = 1, .item_index = 0 }, state.mouseMove(rect, menus[0..], edit_header.x + 2, edit_header.y + 2));

    const popup = menubarPopupRect(rect, menus[0..], 1);
    const paste_y = popup.y + default_metrics.frame_inset + default_metrics.menu_row_h + 2;
    try std.testing.expectEqual(MenubarResult{ .action = .selection_changed, .menu_index = 1, .item_index = 1, .command_id = 202 }, state.mouseDown(rect, menus[0..], popup.x + 4, paste_y));
    try std.testing.expectEqual(MenubarResult{ .action = .submitted, .menu_index = 1, .item_index = 1, .command_id = 202 }, state.mouseUp(rect, menus[0..], popup.x + 4, paste_y));
    try std.testing.expect(!state.isOpen());

    _ = state.open(menus[0..], 0, false);
    try std.testing.expectEqual(MenubarResult{ .action = .cancelled }, state.mouseDown(rect, menus[0..], 200, 120));
    try std.testing.expect(!state.isOpen());
}

test "focus state maps tab enter escape and space to actions" {
    const items = [_]FocusItem{
        .{},
        .{ .enabled = false },
        .{},
    };
    var focus = FocusState{ .index = 0 };
    try std.testing.expectEqual(FocusResult{ .action = .changed, .index = 2 }, focus.handleKey(items[0..], Key.tab));
    try std.testing.expectEqual(@as(usize, 2), focus.index);
    try std.testing.expectEqual(FocusResult{ .action = .changed, .index = 0 }, focus.handleKey(items[0..], Key.shift_tab));
    try std.testing.expectEqual(FocusResult{ .action = .submitted, .index = 0 }, focus.handleKey(items[0..], Key.enter));
    try std.testing.expectEqual(FocusResult{ .action = .clicked, .index = 0 }, focus.handleKey(items[0..], ' '));
    try std.testing.expectEqual(FocusResult{ .action = .cancelled, .index = 0 }, focus.handleKey(items[0..], Key.escape));
}

test "mouse capture releases action only on same hot target" {
    var capture = MouseCapture{};
    capture.begin(3, .clicked);
    try std.testing.expect(capture.isActive(3));
    try std.testing.expectEqual(ControlAction.none, capture.release(2, true));
    try std.testing.expect(capture.isActive(3));
    capture.begin(3, .changed);
    try std.testing.expectEqual(ControlAction.none, capture.release(3, false));
    capture.begin(3, .changed);
    try std.testing.expectEqual(ControlAction.changed, capture.release(3, true));
}

test "selection and menu keyboard helpers skip disabled entries" {
    const rows = [_][]const u8{ "One", "Two", "Three" };
    const list = List{ .rect = .{ .x = 0, .y = 0, .w = 80, .h = 52 }, .items = rows[0..], .selected_index = 1 };
    try std.testing.expectEqual(SelectionStep{ .action = .selection_changed, .index = 2 }, list.keyAction(Key.down));
    try std.testing.expectEqual(SelectionStep{ .action = .submitted, .index = 1 }, list.keyAction(Key.enter));

    const items = [_]MenuItem{
        .{ .text = "Open" },
        .{ .text = "Save", .enabled = false },
        .{ .text = "Close" },
    };
    const menu = Menu{ .rect = .{ .x = 0, .y = 0, .w = 100, .h = 60 }, .items = items[0..], .selected_index = 0 };
    try std.testing.expectEqual(MenuKeyResult{ .action = .selection_changed, .index = 2 }, menu.keyAction(Key.down));
    try std.testing.expectEqual(MenuKeyResult{ .action = .submitted, .index = 0 }, menu.keyAction(Key.enter));
    try std.testing.expectEqual(MenuKeyResult{ .action = .cancelled, .index = 0 }, menu.keyAction(Key.escape));
}

test "message dialog exposes centered ok action" {
    const rect = centeredRect(.{ .x = 0, .y = 0, .w = 320, .h = 180 }, 180, 92);
    const dialog = MessageDialog{ .rect = rect, .title = "Info", .message = "Hello" };
    try std.testing.expectEqual(Rect{ .x = 70, .y = 44, .w = 180, .h = 92 }, rect);
    try std.testing.expectEqual(DialogAction.ok, dialog.actionAt(dialog.okRect().x, dialog.okRect().y));
    try std.testing.expectEqual(DialogAction.none, dialog.actionAt(rect.x + 4, rect.y + 4));
}

test "message dialog exposes yes no actions" {
    const dialog = MessageDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 120 },
        .title = "Question",
        .message = "Continue?",
        .kind = .question,
        .buttons = .yes_no,
    };
    try std.testing.expectEqual(DialogAction.yes, dialog.actionAt(dialog.yesRect().x, dialog.yesRect().y));
    try std.testing.expectEqual(DialogAction.no, dialog.actionAt(dialog.noRect().x, dialog.noRect().y));
    try std.testing.expectEqual(DialogAction.none, dialog.actionAt(dialog.rect.x + 4, dialog.rect.y + 4));
}

test "message dialog exposes ok cancel actions" {
    const dialog = MessageDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 120 },
        .title = "Question",
        .message = "Apply?",
        .buttons = .ok_cancel,
    };
    try std.testing.expectEqual(DialogAction.ok, dialog.actionAt(dialog.okRect().x, dialog.okRect().y));
    try std.testing.expectEqual(DialogAction.cancel, dialog.actionAt(dialog.cancelRect().x, dialog.cancelRect().y));
    try std.testing.expectEqual(DialogAction.ok, dialog.keyAction(Key.enter));
    try std.testing.expectEqual(DialogAction.cancel, dialog.keyAction(Key.escape));
}

test "message dialog maps modal keyboard actions" {
    const ok_dialog = MessageDialog{ .rect = .{ .x = 0, .y = 0, .w = 160, .h = 90 }, .title = "Info", .message = "Done" };
    const question_dialog = MessageDialog{
        .rect = .{ .x = 0, .y = 0, .w = 180, .h = 100 },
        .title = "Question",
        .message = "Continue?",
        .buttons = .yes_no,
    };
    try std.testing.expectEqual(DialogAction.ok, ok_dialog.keyAction('\r'));
    try std.testing.expectEqual(DialogAction.ok, ok_dialog.keyAction(0x1B));
    try std.testing.expectEqual(DialogAction.yes, question_dialog.keyAction('\r'));
    try std.testing.expectEqual(DialogAction.no, question_dialog.keyAction(0x1B));
    try std.testing.expectEqual(DialogAction.no, question_dialog.keyAction('n'));
}

test "file dialog exposes list and button actions" {
    const items = [_][]const u8{ "README.TXT", "R4OS.SYS" };
    const dialog = FileDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 150 },
        .title = "Open",
        .path = "C:\\",
        .items = items[0..],
    };
    try std.testing.expectEqual(DialogAction.select, dialog.actionAt(dialog.listRect().x + 3, dialog.listRect().y + 3));
    try std.testing.expectEqual(@as(?usize, 0), dialog.indexAt(dialog.listRect().x + 3, dialog.listRect().y + 3));
    try std.testing.expectEqual(DialogAction.ok, dialog.actionAt(dialog.okRect().x, dialog.okRect().y));
    try std.testing.expectEqual(DialogAction.cancel, dialog.actionAt(dialog.cancelRect().x, dialog.cancelRect().y));
}

test "file dialog maps modal keyboard actions" {
    const items = [_][]const u8{ "AUTOEXEC.BAT", "CONFIG.R4S", "DESKTOP" };
    const dialog = FileDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 170 },
        .title = "Open",
        .path = "C:\\",
        .items = items[0..],
        .selected_index = 1,
    };
    try std.testing.expectEqual(DialogAction.ok, dialog.keyAction('\r'));
    try std.testing.expectEqual(DialogAction.cancel, dialog.keyAction(0x1B));
    try std.testing.expectEqual(DialogAction.previous, dialog.keyAction(0x80));
    try std.testing.expectEqual(DialogAction.next, dialog.keyAction(0x81));
    try std.testing.expectEqual(@as(usize, 0), dialog.selectedIndexForAction(.previous));
    try std.testing.expectEqual(@as(usize, 2), dialog.selectedIndexForAction(.next));
}

test "file dialog supports scrolled directory lists" {
    const items = [_][]const u8{ "AUTOEXEC.BAT", "BIN", "CONFIG.R4S", "DESKTOP", "SYS", "TEMP" };
    const dialog = FileDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 170 },
        .title = "Open",
        .path = "C:\\",
        .items = items[0..],
        .selected_index = 4,
        .first_index = 2,
    };
    try std.testing.expectEqual(@as(?usize, 2), dialog.indexAt(dialog.listRect().x + 3, dialog.listRect().y + 3));
    try std.testing.expectEqual(@as(usize, 3), (FileDialog{ .rect = dialog.rect, .title = "Open", .path = "C:\\", .items = items[0..], .selected_index = 4 }).firstIndexForSelection());
}

test "file dialog exposes save filename field" {
    const items = [_][]const u8{ "README.TXT", "R4OS.SYS" };
    const dialog = FileDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 170 },
        .title = "Save",
        .path = "C:\\",
        .items = items[0..],
        .mode = .save,
        .file_name = "NOTES.TXT",
    };
    try std.testing.expect(dialog.fileNameRect().contains(dialog.fileNameRect().x + 3, dialog.fileNameRect().y + 3));
    try std.testing.expectEqual(DialogAction.none, dialog.actionAt(dialog.fileNameRect().x + 3, dialog.fileNameRect().y + 3));
    try std.testing.expectEqualStrings("Save", fileDialogOkText(dialog.mode, dialog.ok_text));
}

test "file dialog carries focus and pressed action state" {
    const items = [_][]const u8{ "README.TXT", "R4OS.SYS" };
    const dialog = FileDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 170 },
        .title = "Open",
        .path = "C:\\",
        .items = items[0..],
        .focus_action = .ok,
        .pressed_action = .cancel,
    };
    try std.testing.expectEqual(DialogAction.ok, dialog.focus_action);
    try std.testing.expectEqual(DialogAction.cancel, dialog.pressed_action);
    try std.testing.expectEqual(DialogAction.cancel, dialog.keyAction(Key.escape));
}

test "input dialog exposes value and button actions" {
    const dialog = InputDialog{
        .rect = .{ .x = 20, .y = 10, .w = 240, .h = 130 },
        .title = "Rename",
        .label = "Name:",
        .value = "README.TXT",
    };
    try std.testing.expectEqual(DialogAction.select, dialog.actionAt(dialog.valueRect().x + 2, dialog.valueRect().y + 2));
    try std.testing.expectEqual(DialogAction.ok, dialog.actionAt(dialog.okRect().x + 2, dialog.okRect().y + 2));
    try std.testing.expectEqual(DialogAction.cancel, dialog.actionAt(dialog.cancelRect().x + 2, dialog.cancelRect().y + 2));
    try std.testing.expectEqual(DialogAction.ok, dialog.keyAction(Key.enter));
    try std.testing.expectEqual(DialogAction.cancel, dialog.keyAction(Key.escape));
    try std.testing.expectEqual(DialogAction.next, dialog.keyAction(Key.tab));
}

test "modal dialog centers and exposes shared layout helpers" {
    const parent = Rect{ .x = 0, .y = 0, .w = 320, .h = 200 };
    const dialog = ModalDialog.centered(parent, 120, 70, "Options");
    try std.testing.expectEqual(Rect{ .x = 80, .y = 55, .w = 160, .h = 90 }, dialog.rect);
    try std.testing.expectEqual(default_metrics.dialog_title_h, dialog.titleRect().h);
    try std.testing.expect(dialog.contentRect().w > 0);
    try std.testing.expect(dialog.buttonBarRect().contains(dialog.buttonRect(2, 1, .right).x, dialog.buttonRect(2, 1, .right).y));

    const row = dialogRowRect(dialog.rect, 0, default_metrics.text_field_h);
    try std.testing.expectEqual(row.x + 52, dialogFieldRect(row, 44).x);
    try std.testing.expectEqual(dialogFieldRect(row, 44), dialogDropdownRect(row, 44));
    try std.testing.expectEqual(default_metrics.dialog_status_h, dialog.statusRect().h);
}

test "modal overlay captures backdrop and button hits" {
    const buttons = [_]DialogButton{
        .{ .action = .ok, .text = "OK", .role = .default },
        .{ .action = .cancel, .text = "Cancel", .role = .cancel },
    };
    const dialog = ModalDialog{ .rect = .{ .x = 40, .y = 30, .w = 220, .h = 120 }, .title = "Settings" };
    const overlay = ModalOverlay{ .bounds = .{ .x = 0, .y = 0, .w = 320, .h = 200 }, .dialog = dialog, .close_on_backdrop = true };
    try std.testing.expectEqual(ModalHit{ .part = .button, .action = .ok }, overlay.hitTest(buttons[0..], .right, dialog.buttonRect(2, 0, .right).x + 2, dialog.buttonRect(2, 0, .right).y + 2));
    try std.testing.expectEqual(DialogAction.cancel, overlay.actionAt(buttons[0..], .right, 10, 10));
    try std.testing.expectEqual(ModalHit{}, overlay.hitTest(buttons[0..], .right, 400, 10));
}

test "dialog state handles focus keys and mouse press release" {
    const buttons = [_]DialogButton{
        .{ .action = .ok, .text = "OK", .role = .default },
        .{ .action = .cancel, .text = "Cancel", .role = .cancel },
    };
    const items = [_]DialogFocusItem{
        .{ .action = .select },
        .{ .action = .ok },
        .{ .action = .cancel },
    };
    const dialog = ModalDialog{ .rect = .{ .x = 10, .y = 10, .w = 240, .h = 120 }, .title = "Rename" };
    var state = DialogState{ .focus_action = .select };
    try std.testing.expectEqual(DialogAction.next, state.keyAction(items[0..], buttons[0..], Key.tab));
    try std.testing.expectEqual(DialogAction.ok, state.focus_action);
    try std.testing.expectEqual(DialogAction.previous, state.keyAction(items[0..], buttons[0..], Key.shift_tab));
    try std.testing.expectEqual(DialogAction.select, state.focus_action);
    try std.testing.expectEqual(DialogAction.ok, state.keyAction(items[0..], buttons[0..], Key.enter));
    try std.testing.expectEqual(DialogAction.cancel, state.keyAction(items[0..], buttons[0..], Key.escape));

    const cancel_rect = dialog.buttonRect(2, 1, .right);
    const down = state.mouseDown(dialog, buttons[0..], .right, cancel_rect.x + 2, cancel_rect.y + 2);
    try std.testing.expect(down.captured);
    try std.testing.expectEqual(DialogAction.cancel, state.pressed_action);
    const up = state.mouseUp(dialog, buttons[0..], .right, cancel_rect.x + 2, cancel_rect.y + 2);
    try std.testing.expectEqual(DialogAction.cancel, up.action);
    try std.testing.expectEqual(DialogAction.none, state.pressed_action);
}

test "text field edits printable keys and backspace" {
    var field = TextField(6){};
    try std.testing.expect(field.handleKey('R'));
    try std.testing.expect(field.handleKey('4'));
    try std.testing.expectEqualStrings("R4", field.value());
    try std.testing.expectEqual(@as(usize, 2), field.cursor);
    try std.testing.expect(field.handleKey(0x08));
    try std.testing.expectEqualStrings("R", field.value());
    try std.testing.expectEqual(@as(usize, 1), field.cursor);
    try std.testing.expect(!field.handleKey('\n'));
}

test "text field keeps capacity and nul terminator" {
    var field = TextField(4){};
    field.set("R4OS");
    try std.testing.expectEqualStrings("R4O", field.value());
    try std.testing.expectEqual(@as(u8, 0), field.buffer[3]);
    try std.testing.expect(!field.handleKey('X'));
}

test "text field supports cursor movement delete home end and select all" {
    var field = TextField(8){};
    field.set("R4OS");
    try std.testing.expect(field.handleKey(Key.left));
    try std.testing.expect(field.handleKey(Key.left));
    try std.testing.expectEqual(@as(usize, 2), field.cursor);
    try std.testing.expect(field.handleKey('X'));
    try std.testing.expectEqualStrings("R4XOS", field.value());
    try std.testing.expect(field.handleKey(Key.delete));
    try std.testing.expectEqualStrings("R4XS", field.value());
    try std.testing.expect(field.handleKey(Key.home));
    try std.testing.expectEqual(@as(usize, 0), field.cursor);
    try std.testing.expect(field.handleKey(Key.end));
    try std.testing.expectEqual(@as(usize, 4), field.cursor);
    try std.testing.expect(field.handleKey(Key.ctrl_a));
    try std.testing.expect(field.hasSelection());
    try std.testing.expect(field.handleKey('Z'));
    try std.testing.expectEqualStrings("Z", field.value());
    try std.testing.expectEqual(@as(usize, 1), field.cursor);
}

test "text area edits multiple lines and normalizes crlf" {
    const view = TextAreaView.init(8, 3);
    var area = TextArea(12){};
    try std.testing.expect(area.handleKey('R', view));
    try std.testing.expect(area.handleKey('4', view));
    try std.testing.expect(area.handleKey(Key.enter, view));
    try std.testing.expect(area.handleKey('O', view));
    try std.testing.expect(area.handleKey('S', view));
    try std.testing.expectEqualStrings("R4\nOS", area.value());
    try std.testing.expectEqual(@as(usize, 5), area.cursor);
    try std.testing.expect(area.handleKey(Key.backspace, view));
    try std.testing.expectEqualStrings("R4\nO", area.value());
    try std.testing.expectEqual(@as(usize, 4), area.cursor);
    area.set("A\r\nB");
    try std.testing.expectEqualStrings("A\nB", area.value());
    try std.testing.expectEqual(@as(u8, 0), area.buffer[area.len]);
}

test "text area selection supports copy cut paste and select all" {
    const view = TextAreaView.init(12, 3);
    var area = TextArea(32){};
    area.set("Hello R4OS");
    area.setSelection(6, 10);
    var out: [8]u8 = .{0} ** 8;
    try std.testing.expect(area.copySelection(out[0..]));
    try std.testing.expectEqualStrings("R4OS", out[0..4]);
    try std.testing.expectEqual(@as(u8, 0), out[4]);
    try std.testing.expect(area.cutSelection(out[0..]));
    try std.testing.expectEqualStrings("Hello ", area.value());
    try std.testing.expectEqual(@as(usize, 6), area.cursor);
    try std.testing.expect(area.pasteSlice("Desk", view));
    try std.testing.expectEqualStrings("Hello Desk", area.value());
    try std.testing.expect(area.handleKey(Key.ctrl_a, view));
    try std.testing.expectEqual(TextRange{ .start = 0, .end = 10 }, area.selectionRange());
}

test "text area maps wrapped visual lines and hit tests cells" {
    const value = "ABCDXY\nZ";
    try std.testing.expectEqual(TextAreaPoint{ .line = 1, .column = 0 }, textAreaVisualPoint(value, 4, 4));
    try std.testing.expectEqual(@as(usize, 4), textAreaIndexForVisualPosition(value, 1, 0, 4));
    try std.testing.expectEqual(TextRange{ .start = 0, .end = 4 }, textAreaVisualLineRange(value, 0, 4));
    try std.testing.expectEqual(TextRange{ .start = 4, .end = 6 }, textAreaVisualLineRange(value, 1, 4));
    try std.testing.expectEqual(TextRange{ .start = 7, .end = 8 }, textAreaVisualLineRange(value, 2, 4));

    const view = TextAreaView{ .visible_cols = 4, .visible_rows = 2, .wrap_cols = 4 };
    var area = TextArea(32){};
    area.set(value);
    try std.testing.expectEqual(@as(usize, 4), area.hitTest(0, 8, 8, 8, view));
    area.beginMouseSelection(area.hitTest(8, 0, 8, 8, view), view);
    try std.testing.expectEqual(@as(usize, 1), area.cursor);
    try std.testing.expect(!area.hasSelection());
    area.dragMouseSelection(area.hitTest(8, 8, 8, 8, view), view);
    try std.testing.expectEqual(TextRange{ .start = 1, .end = 5 }, area.selectionRange());
    area.finishMouseSelection();
    try std.testing.expect(area.hasSelection());
    try std.testing.expect(area.moveCursorTo(7, false, view));
    try std.testing.expectEqual(@as(usize, 1), area.scroll_line);
    area.scrollByLines(99, view);
    try std.testing.expectEqual(@as(usize, 1), area.scroll_line);
    area.scrollByLines(-99, view);
    try std.testing.expectEqual(@as(usize, 0), area.scroll_line);
}

test "text area keyboard navigation follows wrapped rows" {
    const view = TextAreaView{ .visible_cols = 4, .visible_rows = 2, .wrap_cols = 4 };
    var area = TextArea(16){};
    area.set("ABCDXY");
    try std.testing.expect(area.moveHome(false, view));
    try std.testing.expectEqual(@as(usize, 4), area.cursor);
    try std.testing.expect(area.moveEnd(false, view));
    try std.testing.expectEqual(@as(usize, 6), area.cursor);
    try std.testing.expect(area.moveVertical(-1, false, view));
    try std.testing.expectEqual(@as(usize, 2), area.cursor);
    try std.testing.expect(area.handleKeyEx(Key.right, true, view));
    try std.testing.expectEqual(TextRange{ .start = 2, .end = 3 }, area.selectionRange());
}

test "text fields navigate and delete complete utf8 scalars" {
    const value = "A\xc3\xa4B";

    const view = TextAreaView.init(8, 2);
    var area = TextArea(16){};
    area.set(value);
    try std.testing.expectEqual(@as(usize, 4), area.cursor);
    try std.testing.expect(area.moveLeft(false, view));
    try std.testing.expectEqual(@as(usize, 3), area.cursor);
    try std.testing.expect(area.moveLeft(false, view));
    try std.testing.expectEqual(@as(usize, 1), area.cursor);
    try std.testing.expect(area.moveRight(false, view));
    try std.testing.expectEqual(@as(usize, 3), area.cursor);
    try std.testing.expect(area.deleteBackward(view));
    try std.testing.expectEqualStrings("AB", area.value());
    try std.testing.expectEqual(@as(usize, 1), area.cursor);

    var field = TextField(16){};
    field.set(value);
    try std.testing.expect(field.handleKey(Key.left));
    try std.testing.expect(field.handleKey(Key.backspace));
    try std.testing.expectEqualStrings("AB", field.value());
    try std.testing.expectEqual(@as(usize, 1), field.cursor);
}

test "text area inserts Unicode codepoints as complete utf8 scalars" {
    const view = TextAreaView.init(12, 2);
    var area = TextArea(32){};
    try std.testing.expect(area.handleCodepointEx(0x00e4, false, view));
    try std.testing.expect(area.handleCodepointEx(0x00f6, false, view));
    try std.testing.expect(area.handleCodepointEx(0x00fc, false, view));
    try std.testing.expect(area.handleCodepointEx(0x00df, false, view));
    try std.testing.expect(area.handleCodepointEx(0x20ac, false, view));
    try std.testing.expectEqualStrings("\xc3\xa4\xc3\xb6\xc3\xbc\xc3\x9f\xe2\x82\xac", area.value());
    try std.testing.expectEqual(@as(usize, 11), area.cursor);

    var field = TextField(8){};
    try std.testing.expect(field.handleCodepoint(0x00e4));
    try std.testing.expect(field.handleCodepoint(0x00df));
    try std.testing.expectEqualStrings("\xc3\xa4\xc3\x9f", field.value());
}

test "text area visual coordinates count utf8 scalars" {
    const value = "A\xc3\xa4B";
    try std.testing.expectEqual(TextAreaPoint{ .line = 0, .column = 2 }, textAreaVisualPoint(value, 3, 8));
    try std.testing.expectEqual(@as(usize, 3), textAreaIndexForVisualPosition(value, 0, 2, 8));
    try std.testing.expectEqual(TextRange{ .start = 0, .end = 3 }, textAreaVisualLineRange(value, 0, 2));
    try std.testing.expectEqual(TextRange{ .start = 3, .end = 4 }, textAreaVisualLineRange(value, 1, 2));
    try std.testing.expectEqual(@as(usize, 2), textAreaVisualMaxColumns(value, 2));
}

test "text area accepts desktop line feed input" {
    const view = TextAreaView.init(8, 2);
    var area = TextArea(16){};
    try std.testing.expect(area.handleKey('\n', view));
    try std.testing.expectEqualStrings("\n", area.value());
}

test "text area clamps horizontal scroll without word wrap" {
    const view = TextAreaView{ .visible_cols = 4, .visible_rows = 2, .wrap_cols = 0 };
    var area = TextArea(16){};
    area.set("ABCDEF");
    area.scrollTo(0, 99, view);
    try std.testing.expectEqual(@as(usize, 2), area.scroll_col);
    try std.testing.expectEqual(@as(usize, 6), textAreaVisualMaxColumns(area.value(), view.wrap_cols));
}
