const std = @import("std");
const html = @import("html.zig");
const navigation = @import("web_navigation.zig");

pub const max_controls: usize = 128;
pub const max_focusables: usize = html.max_nodes;
pub const max_events: usize = 256;
pub const max_name_bytes: usize = 95;
pub const max_value_bytes: usize = 511;

pub const Error = error{
    ControlLimit,
    FocusLimit,
    NameTooLong,
    ValueTooLong,
    InvalidUtf8,
    NotAControl,
    NoForm,
    UnsupportedMethod,
    UrlTooLong,
    InvalidAction,
};

pub const SubmissionMethod = enum(u8) {
    get,
    post,
};

pub const Submission = struct {
    method: SubmissionMethod,
    target: []const u8,
    body: []const u8,
    content_type: []const u8,
};

pub const ControlKind = enum(u8) {
    text,
    search,
    hidden,
    checkbox,
    radio,
    select,
    submit,
    button,
};

pub const EventKind = enum(u8) {
    focus,
    blur,
    input,
    change,
    click,
    submit,
};

pub const Event = struct {
    kind: EventKind,
    target: u16,
    bubbles: bool,
    cancelable: bool,
    default_prevented: bool = false,
};

pub const Control = struct {
    node: u16 = html.none,
    form_node: u16 = html.none,
    kind: ControlKind = .text,
    disabled: bool = false,
    checked: bool = false,
    selected_option: u16 = html.none,
    dirty: bool = false,
    name_storage: [max_name_bytes + 1]u8 = .{0} ** (max_name_bytes + 1),
    name_len: usize = 0,
    value_storage: [max_value_bytes + 1]u8 = .{0} ** (max_value_bytes + 1),
    value_len: usize = 0,
    label_storage: [max_value_bytes + 1]u8 = .{0} ** (max_value_bytes + 1),
    label_len: usize = 0,
    cursor: usize = 0,

    pub fn name(self: *const Control) []const u8 {
        return self.name_storage[0..self.name_len];
    }

    pub fn value(self: *const Control) []const u8 {
        return self.value_storage[0..self.value_len];
    }

    pub fn displayValue(self: *const Control) []const u8 {
        return if (self.label_len > 0) self.label_storage[0..self.label_len] else self.value();
    }

    pub fn isFocusable(self: *const Control) bool {
        return !self.disabled and self.kind != .hidden;
    }

    fn setName(self: *Control, input: []const u8) Error!void {
        if (input.len > max_name_bytes) return error.NameTooLong;
        @memset(self.name_storage[0..], 0);
        if (input.len > 0) @memcpy(self.name_storage[0..input.len], input);
        self.name_len = input.len;
    }

    pub fn setValue(self: *Control, input: []const u8) Error!void {
        if (input.len > max_value_bytes) return error.ValueTooLong;
        if (!std.unicode.utf8ValidateSlice(input)) return error.InvalidUtf8;
        @memset(self.value_storage[0..], 0);
        if (input.len > 0) @memcpy(self.value_storage[0..input.len], input);
        self.value_len = input.len;
        self.cursor = input.len;
        self.dirty = true;
    }

    fn setLabel(self: *Control, input: []const u8) Error!void {
        if (input.len > max_value_bytes) return error.ValueTooLong;
        if (!std.unicode.utf8ValidateSlice(input)) return error.InvalidUtf8;
        @memset(self.label_storage[0..], 0);
        if (input.len > 0) @memcpy(self.label_storage[0..input.len], input);
        self.label_len = input.len;
    }
};

pub const Interaction = struct {
    controls: [max_controls]Control = .{Control{}} ** max_controls,
    control_count: usize = 0,
    focusables: [max_focusables]u16 = .{html.none} ** max_focusables,
    focusable_count: usize = 0,
    focused_node: u16 = html.none,
    events: [max_events]Event = undefined,
    event_count: usize = 0,

    pub fn reset(self: *Interaction) void {
        self.control_count = 0;
        self.focusable_count = 0;
        self.focused_node = html.none;
        self.event_count = 0;
    }

    pub fn rebuild(self: *Interaction, document: *const html.Document) Error!void {
        self.reset();
        var node_index: usize = 0;
        while (node_index < document.node_count) : (node_index += 1) {
            if (document.nodes[node_index].kind != .element) continue;
            const node: u16 = @intCast(node_index);
            const name = document.nodeName(node);
            if (std.ascii.eqlIgnoreCase(name, "a") and document.attribute(node, "href") != null) try self.addFocusable(node);
            const kind = controlKind(document, node, name) orelse continue;
            if (self.control_count >= self.controls.len) return error.ControlLimit;
            var control = Control{
                .node = node,
                .form_node = nearestForm(document, node),
                .kind = kind,
                .disabled = document.attribute(node, "disabled") != null,
                .checked = document.attribute(node, "checked") != null,
            };
            try control.setName(document.attribute(node, "name") orelse "");
            var text_buffer: [max_value_bytes]u8 = undefined;
            const is_button = std.ascii.eqlIgnoreCase(name, "button");
            if (kind == .select) {
                if (selectedOptionNode(document, node)) |option| {
                    try setSelectedOption(&control, document, option, text_buffer[0..]);
                } else {
                    try control.setValue("");
                }
            } else {
                const initial = if (is_button)
                    document.attribute(node, "value") orelse ""
                else if (std.ascii.eqlIgnoreCase(name, "textarea"))
                    try descendantText(document, node, text_buffer[0..])
                else if (kind == .checkbox or kind == .radio)
                    document.attribute(node, "value") orelse "on"
                else
                    document.attribute(node, "value") orelse "";
                try control.setValue(initial);
            }
            if (is_button) {
                const label = if (document.attribute(node, "aria-label")) |accessible|
                    accessible
                else if (document.attribute(node, "title")) |title|
                    title
                else
                    try descendantLabelText(document, node, text_buffer[0..]);
                try control.setLabel(if (label.len > 0) label else control.value());
            }
            control.dirty = false;
            self.controls[self.control_count] = control;
            if (control.isFocusable()) try self.addFocusable(node);
            self.control_count += 1;
        }
    }

    pub fn controlForNode(self: *Interaction, node: u16) ?*Control {
        var index: usize = 0;
        while (index < self.control_count) : (index += 1) {
            if (self.controls[index].node == node) return &self.controls[index];
        }
        return null;
    }

    pub fn controlForNodeConst(self: *const Interaction, node: u16) ?*const Control {
        var index: usize = 0;
        while (index < self.control_count) : (index += 1) {
            if (self.controls[index].node == node) return &self.controls[index];
        }
        return null;
    }

    pub fn focusedControl(self: *Interaction) ?*Control {
        if (self.focused_node == html.none) return null;
        return self.controlForNode(self.focused_node);
    }

    pub fn focus(self: *Interaction, node: u16) void {
        if (node == self.focused_node) return;
        if (self.focusedControl()) |old| {
            if (old.dirty) {
                self.pushEvent(.{ .kind = .change, .target = old.node, .bubbles = true, .cancelable = false });
                old.dirty = false;
            }
        }
        if (self.focused_node != html.none) self.pushEvent(.{ .kind = .blur, .target = self.focused_node, .bubbles = false, .cancelable = false });
        self.focused_node = html.none;
        if (!self.isFocusableNode(node)) return;
        self.focused_node = node;
        self.pushEvent(.{ .kind = .focus, .target = node, .bubbles = false, .cancelable = false });
    }

    pub fn focusNext(self: *Interaction, reverse: bool) bool {
        if (self.focusable_count == 0) return false;
        var start: usize = if (reverse) 0 else self.focusable_count - 1;
        if (self.focused_node != html.none) {
            var current: usize = 0;
            while (current < self.focusable_count and self.focusables[current] != self.focused_node) : (current += 1) {}
            start = if (current < self.focusable_count) current else start;
        }
        var step: usize = 1;
        while (step <= self.focusable_count) : (step += 1) {
            const index = if (reverse)
                (start + self.focusable_count - (step % self.focusable_count)) % self.focusable_count
            else
                (start + step) % self.focusable_count;
            self.focus(self.focusables[index]);
            return true;
        }
        return false;
    }

    pub fn insertText(self: *Interaction, value: []const u8) Error!bool {
        if (!std.unicode.utf8ValidateSlice(value)) return error.InvalidUtf8;
        const control = self.focusedControl() orelse return false;
        if (control.kind != .text and control.kind != .search) return false;
        if (value.len > max_value_bytes - control.value_len) return error.ValueTooLong;
        const tail_len = control.value_len - control.cursor;
        std.mem.copyBackwards(
            u8,
            control.value_storage[control.cursor + value.len .. control.cursor + value.len + tail_len],
            control.value_storage[control.cursor .. control.cursor + tail_len],
        );
        @memcpy(control.value_storage[control.cursor .. control.cursor + value.len], value);
        control.cursor += value.len;
        control.value_len += value.len;
        control.value_storage[control.value_len] = 0;
        control.dirty = true;
        self.pushEvent(.{ .kind = .input, .target = control.node, .bubbles = true, .cancelable = false });
        return true;
    }

    pub fn backspace(self: *Interaction) bool {
        const control = self.focusedControl() orelse return false;
        if ((control.kind != .text and control.kind != .search) or control.cursor == 0) return false;
        const previous = previousUtf8Start(control.value(), control.cursor);
        removeRange(control, previous, control.cursor);
        control.cursor = previous;
        control.dirty = true;
        self.pushEvent(.{ .kind = .input, .target = control.node, .bubbles = true, .cancelable = false });
        return true;
    }

    pub fn deleteForward(self: *Interaction) bool {
        const control = self.focusedControl() orelse return false;
        if ((control.kind != .text and control.kind != .search) or control.cursor >= control.value_len) return false;
        const next = nextUtf8End(control.value(), control.cursor);
        removeRange(control, control.cursor, next);
        control.dirty = true;
        self.pushEvent(.{ .kind = .input, .target = control.node, .bubbles = true, .cancelable = false });
        return true;
    }

    pub fn moveCursor(self: *Interaction, direction: enum { left, right, home, end }) bool {
        const control = self.focusedControl() orelse return false;
        const before = control.cursor;
        control.cursor = switch (direction) {
            .left => previousUtf8Start(control.value(), control.cursor),
            .right => nextUtf8End(control.value(), control.cursor),
            .home => 0,
            .end => control.value_len,
        };
        return control.cursor != before;
    }

    pub fn click(self: *Interaction, node: u16) void {
        self.pushEvent(.{ .kind = .click, .target = node, .bubbles = true, .cancelable = true });
    }

    pub fn selectNext(self: *Interaction, document: *const html.Document, node: u16) Error!bool {
        const control = self.controlForNode(node) orelse return error.NotAControl;
        if (control.kind != .select or control.disabled) return false;
        var first: u16 = html.none;
        var next: u16 = html.none;
        var saw_current = false;
        var index: usize = 0;
        while (index < document.node_count) : (index += 1) {
            const option: u16 = @intCast(index);
            if (!isSelectableOption(document, option, node)) continue;
            if (first == html.none) first = option;
            if (saw_current) {
                next = option;
                break;
            }
            if (option == control.selected_option) saw_current = true;
        }
        if (next == html.none) next = first;
        if (next == html.none or next == control.selected_option) return false;
        var text_buffer: [max_value_bytes]u8 = undefined;
        try setSelectedOption(control, document, next, text_buffer[0..]);
        control.dirty = true;
        self.pushEvent(.{ .kind = .input, .target = node, .bubbles = true, .cancelable = false });
        self.pushEvent(.{ .kind = .change, .target = node, .bubbles = true, .cancelable = false });
        return true;
    }

    pub fn submit(
        self: *Interaction,
        document: *const html.Document,
        submitter_node: u16,
        base: *const navigation.Url,
        target_out: []u8,
        body_out: []u8,
    ) Error!Submission {
        const submitter = self.controlForNode(submitter_node) orelse return error.NotAControl;
        const form_node = submitter.form_node;
        if (form_node == html.none) return error.NoForm;
        const method_text = document.attribute(form_node, "method") orelse "get";
        const method: SubmissionMethod = if (std.ascii.eqlIgnoreCase(method_text, "get"))
            .get
        else if (std.ascii.eqlIgnoreCase(method_text, "post"))
            .post
        else
            return error.UnsupportedMethod;
        const enctype = document.attribute(form_node, "enctype") orelse "application/x-www-form-urlencoded";
        if (method == .post and !std.ascii.eqlIgnoreCase(enctype, "application/x-www-form-urlencoded")) {
            return error.UnsupportedMethod;
        }
        const action = document.attribute(form_node, "action") orelse "";
        const resolved = if (action.len == 0)
            base.*
        else if (navigation.isDocumentRelativeReference(action))
            navigation.resolve(base, action) catch return error.InvalidAction
        else
            navigation.parse(action) catch return error.InvalidAction;

        const base_bytes = resolved.bytes();
        const fragment = std.mem.indexOfScalar(u8, base_bytes, '#') orelse base_bytes.len;
        const query = if (method == .get)
            std.mem.indexOfScalar(u8, base_bytes[0..fragment], '?') orelse fragment
        else
            fragment;
        var target_len: usize = 0;
        if (!append(target_out, &target_len, base_bytes[0..query])) return error.UrlTooLong;

        var body_len: usize = 0;
        var wrote_pair = false;
        var index: usize = 0;
        while (index < self.control_count) : (index += 1) {
            const control = &self.controls[index];
            if (control.form_node != form_node or control.disabled or control.name_len == 0) continue;
            if (control.kind == .button) continue;
            if ((control.kind == .checkbox or control.kind == .radio) and !control.checked) continue;
            if (control.kind == .submit and control.node != submitter_node) continue;
            const pair_out = if (method == .get) target_out else body_out;
            const pair_len = if (method == .get) &target_len else &body_len;
            if (!append(pair_out, pair_len, if (wrote_pair or method == .post) "&" else "?")) return error.UrlTooLong;
            try appendFormEncoded(pair_out, pair_len, control.name());
            if (!append(pair_out, pair_len, "=")) return error.UrlTooLong;
            try appendFormEncoded(pair_out, pair_len, control.value());
            wrote_pair = true;
        }
        self.pushEvent(.{ .kind = .submit, .target = form_node, .bubbles = true, .cancelable = true });
        const body_start: usize = if (method == .post and body_len > 0) 1 else 0;
        return .{
            .method = method,
            .target = target_out[0..target_len],
            .body = body_out[body_start..body_len],
            .content_type = "application/x-www-form-urlencoded",
        };
    }

    pub fn preventDefault(self: *Interaction, event_index: usize) bool {
        if (event_index >= self.event_count or !self.events[event_index].cancelable) return false;
        self.events[event_index].default_prevented = true;
        return true;
    }

    fn pushEvent(self: *Interaction, event: Event) void {
        if (self.event_count == self.events.len) {
            var index: usize = 1;
            while (index < self.events.len) : (index += 1) self.events[index - 1] = self.events[index];
            self.event_count -= 1;
        }
        self.events[self.event_count] = event;
        self.event_count += 1;
    }

    fn addFocusable(self: *Interaction, node: u16) Error!void {
        if (self.focusable_count >= self.focusables.len) return error.FocusLimit;
        self.focusables[self.focusable_count] = node;
        self.focusable_count += 1;
    }

    fn isFocusableNode(self: *const Interaction, node: u16) bool {
        var index: usize = 0;
        while (index < self.focusable_count) : (index += 1) if (self.focusables[index] == node) return true;
        return false;
    }
};

pub fn linkTarget(document: *const html.Document, node_input: u16) ?[]const u8 {
    var node = node_input;
    var visited: usize = 0;
    while (node != html.none and visited < html.max_depth) : (visited += 1) {
        if (node >= document.node_count) return null;
        if (document.nodes[node].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "a")) {
            return document.attribute(node, "href");
        }
        node = document.nodes[node].parent;
    }
    return null;
}

pub fn interactiveAncestor(document: *const html.Document, node_input: u16) u16 {
    var node = node_input;
    var visited: usize = 0;
    while (node != html.none and visited < html.max_depth) : (visited += 1) {
        if (node >= document.node_count) return html.none;
        if (document.nodes[node].kind == .element) {
            const name = document.nodeName(node);
            if ((std.ascii.eqlIgnoreCase(name, "a") and document.attribute(node, "href") != null) or
                controlKind(document, node, name) != null) return node;
        }
        node = document.nodes[node].parent;
    }
    return html.none;
}

fn controlKind(document: *const html.Document, node: u16, name: []const u8) ?ControlKind {
    if (std.ascii.eqlIgnoreCase(name, "textarea")) return .text;
    if (std.ascii.eqlIgnoreCase(name, "select")) return .select;
    if (std.ascii.eqlIgnoreCase(name, "button")) {
        const button_type = document.attribute(node, "type") orelse "submit";
        return if (std.ascii.eqlIgnoreCase(button_type, "button") or std.ascii.eqlIgnoreCase(button_type, "reset")) .button else .submit;
    }
    if (!std.ascii.eqlIgnoreCase(name, "input")) return null;
    const input_type = document.attribute(node, "type") orelse "text";
    if (std.ascii.eqlIgnoreCase(input_type, "text")) return .text;
    if (std.ascii.eqlIgnoreCase(input_type, "search")) return .search;
    if (std.ascii.eqlIgnoreCase(input_type, "hidden")) return .hidden;
    if (std.ascii.eqlIgnoreCase(input_type, "checkbox")) return .checkbox;
    if (std.ascii.eqlIgnoreCase(input_type, "radio")) return .radio;
    if (std.ascii.eqlIgnoreCase(input_type, "submit")) return .submit;
    if (std.ascii.eqlIgnoreCase(input_type, "button")) return .button;
    return .text;
}

fn nearestForm(document: *const html.Document, node_input: u16) u16 {
    var node = document.nodes[node_input].parent;
    var visited: usize = 0;
    while (node != html.none and visited < html.max_depth) : (visited += 1) {
        if (node >= document.node_count) return html.none;
        if (document.nodes[node].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "form")) return node;
        node = document.nodes[node].parent;
    }
    return html.none;
}

fn descendantText(document: *const html.Document, node: u16, out: []u8) Error![]const u8 {
    return document.textContent(node, out) catch return error.ValueTooLong;
}

fn descendantLabelText(document: *const html.Document, node: u16, out: []u8) Error![]const u8 {
    const raw = try descendantText(document, node, out);
    var read: usize = 0;
    var written: usize = 0;
    var pending_space = false;
    while (read < raw.len) {
        if (std.ascii.isWhitespace(raw[read])) {
            pending_space = written > 0;
            read += 1;
            continue;
        }
        if (pending_space) {
            out[written] = ' ';
            written += 1;
            pending_space = false;
        }
        out[written] = raw[read];
        written += 1;
        read += 1;
    }
    return out[0..written];
}

fn setSelectedOption(control: *Control, document: *const html.Document, option: u16, out: []u8) Error!void {
    const text = try descendantText(document, option, out);
    try control.setValue(document.attribute(option, "value") orelse text);
    try control.setLabel(document.attribute(option, "label") orelse text);
    control.selected_option = option;
}

fn selectedOptionNode(document: *const html.Document, select_node: u16) ?u16 {
    var first: u16 = html.none;
    var index: usize = 0;
    while (index < document.node_count) : (index += 1) {
        const option: u16 = @intCast(index);
        if (!isSelectableOption(document, option, select_node)) continue;
        if (first == html.none) first = option;
        if (document.attribute(option, "selected") != null) return option;
    }
    return if (first == html.none) null else first;
}

fn isSelectableOption(document: *const html.Document, option: u16, select_node: u16) bool {
    if (option >= document.node_count or document.nodes[option].kind != .element or !std.ascii.eqlIgnoreCase(document.nodeName(option), "option")) return false;
    if (document.attribute(option, "disabled") != null) return false;
    var parent = document.nodes[option].parent;
    var depth: usize = 0;
    while (parent != html.none and parent < document.node_count and depth < html.max_depth) : (depth += 1) {
        if (parent == select_node) return true;
        if (document.nodes[parent].kind == .element) {
            const parent_name = document.nodeName(parent);
            if (std.ascii.eqlIgnoreCase(parent_name, "select")) return false;
            if (std.ascii.eqlIgnoreCase(parent_name, "optgroup") and document.attribute(parent, "disabled") != null) return false;
        }
        parent = document.nodes[parent].parent;
    }
    return false;
}

fn previousUtf8Start(value: []const u8, cursor: usize) usize {
    if (cursor == 0) return 0;
    var index = @min(cursor, value.len) - 1;
    while (index > 0 and (value[index] & 0xC0) == 0x80) index -= 1;
    return index;
}

fn nextUtf8End(value: []const u8, cursor: usize) usize {
    if (cursor >= value.len) return value.len;
    var index = cursor + 1;
    while (index < value.len and (value[index] & 0xC0) == 0x80) index += 1;
    return index;
}

fn removeRange(control: *Control, start: usize, end: usize) void {
    if (start >= end or end > control.value_len) return;
    const count = end - start;
    const tail = control.value_len - end;
    if (tail > 0) std.mem.copyForwards(u8, control.value_storage[start .. start + tail], control.value_storage[end .. end + tail]);
    control.value_len -= count;
    @memset(control.value_storage[control.value_len .. control.value_len + count + 1], 0);
}

fn appendFormEncoded(out: []u8, len: *usize, value: []const u8) Error!void {
    const digits = "0123456789ABCDEF";
    for (value) |byte| {
        if ((byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or
            (byte >= '0' and byte <= '9') or byte == '*' or byte == '-' or byte == '.' or byte == '_')
        {
            if (!appendByte(out, len, byte)) return error.UrlTooLong;
        } else if (byte == ' ') {
            if (!append(out, len, "+")) return error.UrlTooLong;
        } else {
            const encoded = [_]u8{ '%', digits[byte >> 4], digits[byte & 0x0F] };
            if (!append(out, len, encoded[0..])) return error.UrlTooLong;
        }
    }
}

fn append(out: []u8, len: *usize, value: []const u8) bool {
    if (value.len > out.len -| len.*) return false;
    if (value.len > 0) @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
    return true;
}

fn appendByte(out: []u8, len: *usize, value: u8) bool {
    if (len.* >= out.len) return false;
    out[len.*] = value;
    len.* += 1;
    return true;
}

test "form controls focus edit and dispatch DOM events" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='/find'><input name=q value='Alt'><button name=go value=1>Search</button></form>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqual(@as(usize, 2), interaction.control_count);
    interaction.focus(interaction.controls[0].node);
    try std.testing.expect(try interaction.insertText(" €"));
    try std.testing.expect(interaction.backspace());
    try std.testing.expect(interaction.event_count >= 3);
    interaction.focus(interaction.controls[1].node);
    try std.testing.expectEqual(EventKind.change, interaction.events[interaction.event_count - 3].kind);
    try std.testing.expectEqual(EventKind.blur, interaction.events[interaction.event_count - 2].kind);
    try std.testing.expectEqual(EventKind.focus, interaction.events[interaction.event_count - 1].kind);
}

test "GET submission uses UTF-8 form encoding and resolves action" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='/search?old=1' method=get>" ++
            "<input name=q value='R4 OS'><input type=hidden name=lang value='de'>" ++
            "<button name=go value='Los'>Search</button></form>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try interaction.controls[0].setValue("Grüße Welt");
    const base = try navigation.parse("https://example.com/start/index.html");
    var out: [navigation.url_capacity + 1]u8 = undefined;
    var body: [512]u8 = undefined;
    const submitted = try interaction.submit(&document, interaction.controls[2].node, &base, out[0..], body[0..]);
    try std.testing.expectEqual(SubmissionMethod.get, submitted.method);
    try std.testing.expectEqualStrings(
        "https://example.com/search?q=Gr%C3%BC%C3%9Fe+Welt&lang=de&go=Los",
        submitted.target,
    );
    try std.testing.expectEqualStrings("", submitted.body);
    try std.testing.expectEqual(EventKind.submit, interaction.events[interaction.event_count - 1].kind);
}

test "POST submission separates action and urlencoded entity" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='https://consent.example/save?hl=en' method=POST>" ++
            "<input type=hidden name=continue value='/search?q=R4 OS'>" ++
            "<button name=choice value=reject>Reject all</button></form>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    const base = try navigation.parse("https://example.com/search?q=R4OS");
    var target: [navigation.url_capacity + 1]u8 = undefined;
    var body: [512]u8 = undefined;
    const submitted = try interaction.submit(&document, interaction.controls[1].node, &base, target[0..], body[0..]);
    try std.testing.expectEqual(SubmissionMethod.post, submitted.method);
    try std.testing.expectEqualStrings("https://consent.example/save?hl=en", submitted.target);
    try std.testing.expectEqualStrings("continue=%2Fsearch%3Fq%3DR4+OS&choice=reject", submitted.body);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", submitted.content_type);
}

test "POST consent submission recognizes input submit and keeps hidden fields" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='https://consent.example/save' method=POST style='display:inline'>" ++
            "<input type=hidden name=continue value='https://search.example/?q=R4OS'>" ++
            "<input type=hidden name=set_eom value=true>" ++
            "<input type=submit value='Reject all'></form>",
        .{},
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqual(@as(usize, 3), interaction.control_count);
    try std.testing.expectEqual(ControlKind.submit, interaction.controls[2].kind);
    try std.testing.expectEqualStrings("Reject all", interaction.controls[2].value());
    const base = try navigation.parse("https://consent.example/page");
    var target: [navigation.url_capacity + 1]u8 = undefined;
    var body: [512]u8 = undefined;
    const submitted = try interaction.submit(&document, interaction.controls[2].node, &base, target[0..], body[0..]);
    try std.testing.expectEqualStrings("https://consent.example/save", submitted.target);
    try std.testing.expectEqualStrings("continue=https%3A%2F%2Fsearch.example%2F%3Fq%3DR4OS&set_eom=true", submitted.body);
}

test "nested button labels stay separate from submitted values" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='/consent' method=POST>" ++
            "<button name=choice value=reject><span>Reject <strong>all</strong></span></button></form>",
        .{},
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqual(@as(usize, 1), interaction.control_count);
    try std.testing.expectEqualStrings("reject", interaction.controls[0].value());
    try std.testing.expectEqualStrings("Reject all", interaction.controls[0].displayValue());

    const base = try navigation.parse("https://consent.example/page");
    var target: [navigation.url_capacity + 1]u8 = undefined;
    var body: [512]u8 = undefined;
    const submitted = try interaction.submit(&document, interaction.controls[0].node, &base, target[0..], body[0..]);
    try std.testing.expectEqualStrings("choice=reject", submitted.body);
}

test "button labels collapse source whitespace and prefer accessible text" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form>" ++
            "<button name=plain>\n  <span>Search</span>\n  the web\n</button>" ++
            "<button name=icon aria-label='Search Wikipedia'>&#128269;</button></form>",
        .{},
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqual(@as(usize, 2), interaction.control_count);
    try std.testing.expectEqualStrings("Search the web", interaction.controls[0].displayValue());
    try std.testing.expectEqualStrings("Search Wikipedia", interaction.controls[1].displayValue());
}

test "checked controls without explicit values submit the HTML default" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='/search'>" ++
            "<input type=checkbox name=safe checked>" ++
            "<input type=checkbox name=unused>" ++
            "<input type=radio name=scope checked>" ++
            "<button type=submit>Search</button></form>",
        .{},
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqualStrings("on", interaction.controls[0].value());
    try std.testing.expectEqualStrings("on", interaction.controls[2].value());

    const base = try navigation.parse("https://fixture.example/");
    var target: [navigation.url_capacity + 1]u8 = undefined;
    var body: [512]u8 = undefined;
    const submitted = try interaction.submit(&document, interaction.controls[3].node, &base, target[0..], body[0..]);
    try std.testing.expectEqualStrings("https://fixture.example/search?safe=on&scope=on", submitted.target);
}

test "single select controls expose cycle and submit their selected option" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><form action='/search'>" ++
            "<select name=lang><option value=en>English</option>" ++
            "<optgroup disabled><option value=skip>Disabled</option></optgroup>" ++
            "<option value=de selected>Deutsch</option></select>" ++
            "<button type=submit name=go value=yes>Go</button></form>",
        .{},
    );
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqual(@as(usize, 2), interaction.control_count);
    try std.testing.expectEqual(ControlKind.select, interaction.controls[0].kind);
    try std.testing.expectEqualStrings("de", interaction.controls[0].value());
    try std.testing.expectEqualStrings("Deutsch", interaction.controls[0].displayValue());
    try std.testing.expect(try interaction.selectNext(&document, interaction.controls[0].node));
    try std.testing.expectEqualStrings("en", interaction.controls[0].value());
    try std.testing.expectEqualStrings("English", interaction.controls[0].displayValue());
    try std.testing.expectEqual(EventKind.input, interaction.events[interaction.event_count - 2].kind);
    try std.testing.expectEqual(EventKind.change, interaction.events[interaction.event_count - 1].kind);

    const base = try navigation.parse("https://fixture.example/");
    var target: [navigation.url_capacity + 1]u8 = undefined;
    var body: [512]u8 = undefined;
    const submitted = try interaction.submit(&document, interaction.controls[1].node, &base, target[0..], body[0..]);
    try std.testing.expectEqualStrings("https://fixture.example/search?lang=en&go=yes", submitted.target);
}

test "links resolve through their interactive ancestor" {
    var document = html.Document{};
    _ = try document.parse("<p><a href='../next'><strong>Next</strong></a></p>", .{});
    const strong = document.findFirstElement("strong").?;
    try std.testing.expectEqualStrings("../next", linkTarget(&document, strong).?);
    try std.testing.expect(interactiveAncestor(&document, strong) != html.none);
}

test "focus list covers every node in a large parsed document" {
    const link_count: usize = 256;
    const link = "<a href=/next>Next</a>";
    var source: [link_count * link.len]u8 = undefined;
    var source_len: usize = 0;
    for (0..link_count) |_| {
        @memcpy(source[source_len .. source_len + link.len], link);
        source_len += link.len;
    }

    var document = html.Document{};
    _ = try document.parse(source[0..source_len], .{});
    var interaction = Interaction{};
    try interaction.rebuild(&document);
    try std.testing.expectEqual(link_count, interaction.focusable_count);
    interaction.focus(interaction.focusables[link_count - 1]);
    try std.testing.expectEqual(interaction.focusables[link_count - 1], interaction.focused_node);
}
