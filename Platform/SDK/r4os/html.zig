const std = @import("std");
const web_encoding = @import("web_encoding.zig");

pub const max_source_bytes: usize = 256 * 1024;
pub const max_string_bytes: usize = 160 * 1024;
pub const max_nodes: usize = 4096;
pub const max_attributes: usize = 6144;
pub const max_depth: usize = 96;
pub const max_view_bytes: usize = 128 * 1024;
pub const max_view_lines: usize = 2048;
pub const none: u16 = std.math.maxInt(u16);

pub const Error = error{
    SourceTooLarge,
    UnsupportedEncoding,
    StringLimit,
    NodeLimit,
    AttributeLimit,
    DepthLimit,
    ViewLimit,
    InvalidNode,
    UnsupportedMediaType,
};

pub const Encoding = enum(u8) {
    utf8,
    windows_1252,
};

pub const DocumentMode = enum(u8) {
    no_quirks,
    limited_quirks,
    quirks,
};

pub const MediaType = enum(u8) {
    html,
    plain_text,
    unsupported,
};

pub const NodeKind = enum(u8) {
    document,
    doctype,
    element,
    text,
    comment,
};

pub const StringRef = struct {
    offset: u32 = 0,
    len: u32 = 0,

    pub fn bytes(self: StringRef, storage: []const u8) []const u8 {
        const start: usize = self.offset;
        const length: usize = self.len;
        if (start > storage.len or length > storage.len - start) return "";
        return storage[start .. start + length];
    }
};

pub const Node = struct {
    kind: NodeKind = .text,
    name: StringRef = .{},
    value: StringRef = .{},
    parent: u16 = none,
    first_child: u16 = none,
    last_child: u16 = none,
    next_sibling: u16 = none,
    first_attribute: u16 = none,
};

pub const Attribute = struct {
    name: StringRef = .{},
    value: StringRef = .{},
    next: u16 = none,
};

pub const ParseOptions = struct {
    content_type: []const u8 = "",
    require_html_mime: bool = false,
};

pub const ParseStats = struct {
    encoding: Encoding,
    mode: DocumentMode,
    source_bytes: usize,
    decoded_bytes: usize,
    nodes: usize,
    attributes: usize,
    recoveries: usize,
};

pub const Document = struct {
    source: [max_source_bytes]u8 = undefined,
    strings: [max_string_bytes]u8 = undefined,
    nodes: [max_nodes]Node = undefined,
    attributes: [max_attributes]Attribute = undefined,
    source_len: usize = 0,
    string_len: usize = 0,
    node_count: usize = 0,
    attribute_count: usize = 0,
    encoding: Encoding = .utf8,
    mode: DocumentMode = .quirks,
    recovery_count: usize = 0,

    pub fn reset(self: *Document) void {
        self.source_len = 0;
        self.string_len = 0;
        self.node_count = 0;
        self.attribute_count = 0;
        self.encoding = .utf8;
        self.mode = .quirks;
        self.recovery_count = 0;
    }

    pub fn parse(self: *Document, input: []const u8, options: ParseOptions) Error!ParseStats {
        self.reset();
        if (options.require_html_mime and classifyMediaType(options.content_type) != .html) return error.UnsupportedMediaType;
        self.encoding = try sniffEncoding(input, options.content_type);
        try self.decodeSource(input);
        _ = try self.addNode(.document, .{}, .{}, none);

        var stack: [max_depth]u16 = undefined;
        stack[0] = 0;
        var depth: usize = 1;
        var cursor: usize = 0;
        while (cursor < self.source_len) {
            const current = stack[depth - 1];
            if (self.nodes[current].kind == .element and isRawTextElement(self.nodeName(current))) {
                const closing = findRawTextClose(self.source[0..self.source_len], cursor, self.nodeName(current));
                if (closing) |close_start| {
                    if (close_start > cursor) _ = try self.addTextNode(current, self.source[cursor..close_start], false);
                    cursor = close_start;
                } else {
                    if (cursor < self.source_len) _ = try self.addTextNode(current, self.source[cursor..self.source_len], false);
                    cursor = self.source_len;
                    break;
                }
            }

            if (cursor >= self.source_len) break;
            if (self.source[cursor] != '<') {
                const next = std.mem.indexOfScalarPos(u8, self.source[0..self.source_len], cursor, '<') orelse self.source_len;
                _ = try self.addTextNode(stack[depth - 1], self.source[cursor..next], true);
                cursor = next;
                continue;
            }
            if (startsWithAt(self.source[0..self.source_len], cursor, "<!--")) {
                cursor = try self.parseComment(stack[depth - 1], cursor);
                continue;
            }
            if (startsWithIgnoreCaseAt(self.source[0..self.source_len], cursor, "<!doctype")) {
                cursor = try self.parseDoctype(stack[depth - 1], cursor);
                continue;
            }
            if (startsWithAt(self.source[0..self.source_len], cursor, "</")) {
                cursor = self.parseEndTag(&stack, &depth, cursor);
                continue;
            }
            if (cursor + 1 < self.source_len and isNameStart(self.source[cursor + 1])) {
                cursor = try self.parseStartTag(&stack, &depth, cursor);
                continue;
            }
            _ = try self.addTextNode(stack[depth - 1], "<", false);
            cursor += 1;
            self.recovery_count += 1;
        }

        return .{
            .encoding = self.encoding,
            .mode = self.mode,
            .source_bytes = input.len,
            .decoded_bytes = self.source_len,
            .nodes = self.node_count,
            .attributes = self.attribute_count,
            .recoveries = self.recovery_count,
        };
    }

    pub fn nodeName(self: *const Document, index: u16) []const u8 {
        if (index >= self.node_count) return "";
        return self.nodes[index].name.bytes(self.strings[0..self.string_len]);
    }

    pub fn nodeValue(self: *const Document, index: u16) []const u8 {
        if (index >= self.node_count) return "";
        return self.nodes[index].value.bytes(self.strings[0..self.string_len]);
    }

    pub fn attribute(self: *const Document, node_index: u16, wanted: []const u8) ?[]const u8 {
        if (node_index >= self.node_count) return null;
        var cursor = self.nodes[node_index].first_attribute;
        var visited: usize = 0;
        while (cursor != none and visited < self.attribute_count) : (visited += 1) {
            if (cursor >= self.attribute_count) return null;
            const item = self.attributes[cursor];
            if (std.ascii.eqlIgnoreCase(item.name.bytes(self.strings[0..self.string_len]), wanted)) {
                return item.value.bytes(self.strings[0..self.string_len]);
            }
            cursor = item.next;
        }
        return null;
    }

    pub fn findFirstElement(self: *const Document, wanted: []const u8) ?u16 {
        var index: usize = 0;
        while (index < self.node_count) : (index += 1) {
            if (self.nodes[index].kind == .element and std.ascii.eqlIgnoreCase(self.nodeName(@intCast(index)), wanted)) {
                return @intCast(index);
            }
        }
        return null;
    }

    pub fn findElementById(self: *const Document, wanted: []const u8) ?u16 {
        var index: usize = 0;
        while (index < self.node_count) : (index += 1) {
            if (self.nodes[index].kind != .element) continue;
            const value = self.attribute(@intCast(index), "id") orelse continue;
            if (std.mem.eql(u8, value, wanted)) return @intCast(index);
        }
        return null;
    }

    pub fn querySelector(self: *const Document, selector_input: []const u8) ?u16 {
        const selector = trimAscii(selector_input);
        if (selector.len == 0) return null;
        if (selector[0] == '#') return self.findElementById(selector[1..]);
        var index: usize = 0;
        while (index < self.node_count) : (index += 1) {
            if (self.nodes[index].kind != .element) continue;
            const node_index: u16 = @intCast(index);
            if (selector[0] == '.') {
                const classes = self.attribute(node_index, "class") orelse continue;
                if (containsAsciiToken(classes, selector[1..])) return node_index;
            } else if (std.ascii.eqlIgnoreCase(self.nodeName(node_index), selector)) {
                return node_index;
            }
        }
        return null;
    }

    pub fn appendElement(self: *Document, parent: u16, name: []const u8) Error!u16 {
        try self.validateParent(parent);
        const normalized = try self.storeLower(name);
        return self.addNode(.element, normalized, .{}, parent);
    }

    pub fn appendText(self: *Document, parent: u16, value: []const u8) Error!u16 {
        try self.validateParent(parent);
        return (try self.addTextNode(parent, value, true)) orelse return error.StringLimit;
    }

    pub fn createTextNode(self: *Document, value: []const u8) Error!u16 {
        return self.addNode(.text, .{}, try self.store(value), none);
    }

    pub fn setAttribute(self: *Document, node_index: u16, name: []const u8, value: []const u8) Error!void {
        if (node_index >= self.node_count or self.nodes[node_index].kind != .element) return error.InvalidNode;
        var cursor = self.nodes[node_index].first_attribute;
        var last: u16 = none;
        while (cursor != none) {
            if (cursor >= self.attribute_count) return error.InvalidNode;
            if (std.ascii.eqlIgnoreCase(self.attributes[cursor].name.bytes(self.strings[0..self.string_len]), name)) {
                self.attributes[cursor].value = try self.storeEntityDecoded(value);
                return;
            }
            last = cursor;
            cursor = self.attributes[cursor].next;
        }
        const attribute_index = try self.addAttribute(try self.storeLower(name), try self.storeEntityDecoded(value));
        if (last == none) {
            self.nodes[node_index].first_attribute = attribute_index;
        } else {
            self.attributes[last].next = attribute_index;
        }
    }

    pub fn hasAttribute(self: *const Document, node_index: u16, name: []const u8) bool {
        return self.attribute(node_index, name) != null;
    }

    pub fn removeAttribute(self: *Document, node_index: u16, name: []const u8) Error!bool {
        if (node_index >= self.node_count or self.nodes[node_index].kind != .element) return error.InvalidNode;
        var cursor = self.nodes[node_index].first_attribute;
        var previous: u16 = none;
        while (cursor != none) {
            if (cursor >= self.attribute_count) return error.InvalidNode;
            if (std.ascii.eqlIgnoreCase(self.attributes[cursor].name.bytes(self.strings[0..self.string_len]), name)) {
                if (previous == none) self.nodes[node_index].first_attribute = self.attributes[cursor].next else self.attributes[previous].next = self.attributes[cursor].next;
                self.attributes[cursor].next = none;
                return true;
            }
            previous = cursor;
            cursor = self.attributes[cursor].next;
        }
        return false;
    }

    pub fn previousSibling(self: *const Document, node_index: u16) ?u16 {
        if (node_index >= self.node_count) return null;
        const parent = self.nodes[node_index].parent;
        if (parent == none or parent >= self.node_count) return null;
        var cursor = self.nodes[parent].first_child;
        var previous: ?u16 = null;
        while (cursor != none and cursor < self.node_count) {
            if (cursor == node_index) return previous;
            previous = cursor;
            cursor = self.nodes[cursor].next_sibling;
        }
        return null;
    }

    pub fn isConnected(self: *const Document, node_index: u16) bool {
        if (node_index >= self.node_count) return false;
        var current = node_index;
        var depth: usize = 0;
        while (depth <= max_depth and current < self.node_count) : (depth += 1) {
            if (current == 0 and self.nodes[current].kind == .document) return true;
            current = self.nodes[current].parent;
            if (current == none) return false;
        }
        return false;
    }

    pub fn contains(self: *const Document, ancestor_index: u16, node_index: u16) bool {
        if (ancestor_index >= self.node_count or node_index >= self.node_count) return false;
        var current = node_index;
        var depth: usize = 0;
        while (depth <= max_depth and current < self.node_count) : (depth += 1) {
            if (current == ancestor_index) return true;
            current = self.nodes[current].parent;
            if (current == none) return false;
        }
        return false;
    }

    pub fn detach(self: *Document, node_index: u16) Error!void {
        if (node_index == 0 or node_index >= self.node_count) return error.InvalidNode;
        const parent = self.nodes[node_index].parent;
        if (parent == none or parent >= self.node_count) return error.InvalidNode;
        var cursor = self.nodes[parent].first_child;
        var previous: u16 = none;
        while (cursor != none and cursor != node_index) {
            previous = cursor;
            cursor = self.nodes[cursor].next_sibling;
        }
        if (cursor == none) return error.InvalidNode;
        const next = self.nodes[node_index].next_sibling;
        if (previous == none) self.nodes[parent].first_child = next else self.nodes[previous].next_sibling = next;
        if (self.nodes[parent].last_child == node_index) self.nodes[parent].last_child = previous;
        self.nodes[node_index].parent = none;
        self.nodes[node_index].next_sibling = none;
    }

    pub fn attach(self: *Document, parent: u16, node_index: u16) Error!void {
        try self.validateParent(parent);
        if (node_index == 0 or node_index >= self.node_count or node_index == parent) return error.InvalidNode;
        var ancestor = parent;
        var depth: usize = 0;
        while (ancestor != none and ancestor < self.node_count and depth <= max_depth) : (depth += 1) {
            if (ancestor == node_index) return error.InvalidNode;
            ancestor = self.nodes[ancestor].parent;
        }
        if (self.nodes[node_index].parent != none) try self.detach(node_index);
        self.nodes[node_index].parent = parent;
        self.nodes[node_index].next_sibling = none;
        if (self.nodes[parent].last_child == none) {
            self.nodes[parent].first_child = node_index;
            self.nodes[parent].last_child = node_index;
        } else {
            self.nodes[self.nodes[parent].last_child].next_sibling = node_index;
            self.nodes[parent].last_child = node_index;
        }
    }

    pub fn insertBefore(self: *Document, parent: u16, node_index: u16, reference: u16) Error!void {
        try self.validateParent(parent);
        if (node_index == 0 or node_index >= self.node_count or reference >= self.node_count) return error.InvalidNode;
        if (self.nodes[reference].parent != parent) return error.InvalidNode;
        if (node_index == reference) return;
        var ancestor = parent;
        var depth: usize = 0;
        while (ancestor != none and ancestor < self.node_count and depth <= max_depth) : (depth += 1) {
            if (ancestor == node_index) return error.InvalidNode;
            ancestor = self.nodes[ancestor].parent;
        }
        if (self.nodes[node_index].parent != none) try self.detach(node_index);
        var cursor = self.nodes[parent].first_child;
        var previous: u16 = none;
        while (cursor != none and cursor != reference) {
            previous = cursor;
            cursor = self.nodes[cursor].next_sibling;
        }
        if (cursor == none) return error.InvalidNode;
        self.nodes[node_index].parent = parent;
        self.nodes[node_index].next_sibling = reference;
        if (previous == none) self.nodes[parent].first_child = node_index else self.nodes[previous].next_sibling = node_index;
    }

    pub fn removeChild(self: *Document, parent: u16, node_index: u16) Error!void {
        if (parent >= self.node_count or node_index >= self.node_count or self.nodes[node_index].parent != parent) return error.InvalidNode;
        try self.detach(node_index);
    }

    pub fn replaceChild(self: *Document, parent: u16, node_index: u16, replaced: u16) Error!void {
        if (node_index == replaced) return;
        try self.insertBefore(parent, node_index, replaced);
        try self.removeChild(parent, replaced);
    }

    pub fn cloneNode(self: *Document, node_index: u16, deep: bool) Error!u16 {
        if (node_index == 0 or node_index >= self.node_count) return error.InvalidNode;
        const source_node = self.nodes[node_index];
        const clone = try self.addNode(source_node.kind, source_node.name, source_node.value, none);
        var attribute_cursor = source_node.first_attribute;
        while (attribute_cursor != none) {
            if (attribute_cursor >= self.attribute_count) return error.InvalidNode;
            const source_attribute = self.attributes[attribute_cursor];
            try self.setAttribute(clone, source_attribute.name.bytes(self.strings[0..self.string_len]), source_attribute.value.bytes(self.strings[0..self.string_len]));
            attribute_cursor = source_attribute.next;
        }
        if (deep) {
            var child = source_node.first_child;
            while (child != none) {
                if (child >= self.node_count) return error.InvalidNode;
                const next = self.nodes[child].next_sibling;
                const child_clone = try self.cloneNode(child, true);
                try self.attach(clone, child_clone);
                child = next;
            }
        }
        return clone;
    }

    pub fn replaceText(self: *Document, node_index: u16, value: []const u8) Error!void {
        try self.validateParent(node_index);
        var child = self.nodes[node_index].first_child;
        while (child != none) {
            const next = self.nodes[child].next_sibling;
            self.nodes[child].parent = none;
            self.nodes[child].next_sibling = none;
            child = next;
        }
        self.nodes[node_index].first_child = none;
        self.nodes[node_index].last_child = none;
        if (value.len > 0) _ = try self.appendText(node_index, value);
    }

    pub fn setTextContent(self: *Document, node_index: u16, value: []const u8) Error!void {
        if (node_index >= self.node_count) return error.InvalidNode;
        switch (self.nodes[node_index].kind) {
            .text, .comment => self.nodes[node_index].value = try self.storeEntityDecoded(value),
            .document, .element => try self.replaceText(node_index, value),
            .doctype => {},
        }
    }

    pub fn textContent(self: *const Document, node_index: u16, out: []u8) Error![]const u8 {
        if (node_index >= self.node_count) return error.InvalidNode;
        var len: usize = 0;
        try self.appendTextContent(node_index, out, &len, 0);
        return out[0..len];
    }

    fn appendTextContent(self: *const Document, node_index: u16, out: []u8, len: *usize, depth: usize) Error!void {
        if (depth > max_depth or node_index >= self.node_count) return error.InvalidNode;
        const node = self.nodes[node_index];
        if (node.kind == .text) {
            const value = self.nodeValue(node_index);
            if (value.len > out.len -| len.*) return error.StringLimit;
            if (value.len > 0) @memcpy(out[len.* .. len.* + value.len], value);
            len.* += value.len;
            return;
        }
        var child = node.first_child;
        while (child != none) {
            try self.appendTextContent(child, out, len, depth + 1);
            child = self.nodes[child].next_sibling;
        }
    }

    fn validateParent(self: *const Document, parent: u16) Error!void {
        if (parent >= self.node_count) return error.InvalidNode;
        const kind = self.nodes[parent].kind;
        if (kind != .document and kind != .element) return error.InvalidNode;
    }

    fn decodeSource(self: *Document, input: []const u8) Error!void {
        var cursor: usize = if (input.len >= 3 and std.mem.eql(u8, input[0..3], "\xEF\xBB\xBF")) 3 else 0;
        while (cursor < input.len) {
            if (self.encoding == .windows_1252) {
                const byte = input[cursor];
                cursor += 1;
                try appendCodepoint(self.source[0..], &self.source_len, windows1252Codepoint(byte));
                continue;
            }
            const decoded = decodeUtf8(input, cursor);
            try appendCodepoint(self.source[0..], &self.source_len, decoded.codepoint);
            cursor += decoded.consumed;
        }
    }

    fn parseComment(self: *Document, parent: u16, start: usize) Error!usize {
        const content_start = start + 4;
        const close = std.mem.indexOfPos(u8, self.source[0..self.source_len], content_start, "-->") orelse self.source_len;
        const value = try self.store(self.source[content_start..close]);
        _ = try self.addNode(.comment, .{}, value, parent);
        if (close == self.source_len) {
            self.recovery_count += 1;
            return close;
        }
        return close + 3;
    }

    fn parseDoctype(self: *Document, parent: u16, start: usize) Error!usize {
        const close = std.mem.indexOfScalarPos(u8, self.source[0..self.source_len], start + 2, '>') orelse self.source_len;
        var value = trimAscii(self.source[start + 2 .. close]);
        if (startsWithIgnoreCase(value, "doctype")) value = trimAscii(value["doctype".len..]);
        const stored = try self.storeLower(value);
        _ = try self.addNode(.doctype, .{}, stored, parent);
        self.mode = doctypeMode(value);
        if (close == self.source_len) {
            self.recovery_count += 1;
            return close;
        }
        return close + 1;
    }

    fn parseEndTag(self: *Document, stack: *[max_depth]u16, depth: *usize, start: usize) usize {
        var cursor = start + 2;
        skipSpace(self.source[0..self.source_len], &cursor);
        const name_start = cursor;
        while (cursor < self.source_len and isNameByte(self.source[cursor])) : (cursor += 1) {}
        const name = self.source[name_start..cursor];
        const close = std.mem.indexOfScalarPos(u8, self.source[0..self.source_len], cursor, '>') orelse self.source_len;
        if (name.len == 0) {
            self.recovery_count += 1;
            return if (close < self.source_len) close + 1 else close;
        }
        var candidate = depth.*;
        while (candidate > 1) {
            candidate -= 1;
            if (std.ascii.eqlIgnoreCase(self.nodeName(stack[candidate]), name)) {
                depth.* = candidate;
                return if (close < self.source_len) close + 1 else close;
            }
        }
        self.recovery_count += 1;
        return if (close < self.source_len) close + 1 else close;
    }

    fn parseStartTag(self: *Document, stack: *[max_depth]u16, depth: *usize, start: usize) Error!usize {
        var cursor = start + 1;
        const name_start = cursor;
        while (cursor < self.source_len and isNameByte(self.source[cursor])) : (cursor += 1) {}
        const source_name = self.source[name_start..cursor];
        self.applyImpliedEndTags(stack, depth, source_name);
        const parent = stack[depth.* - 1];
        const node_index = try self.addNode(.element, try self.storeLower(source_name), .{}, parent);
        var self_closing = false;
        while (cursor < self.source_len) {
            skipSpace(self.source[0..self.source_len], &cursor);
            if (cursor >= self.source_len) {
                self.recovery_count += 1;
                break;
            }
            if (self.source[cursor] == '>') {
                cursor += 1;
                break;
            }
            if (self.source[cursor] == '/' and cursor + 1 < self.source_len and self.source[cursor + 1] == '>') {
                self_closing = true;
                cursor += 2;
                break;
            }
            const attribute_start = cursor;
            while (cursor < self.source_len and isAttributeNameByte(self.source[cursor])) : (cursor += 1) {}
            if (cursor == attribute_start) {
                cursor += 1;
                self.recovery_count += 1;
                continue;
            }
            const attribute_name = self.source[attribute_start..cursor];
            skipSpace(self.source[0..self.source_len], &cursor);
            var attribute_value: []const u8 = "";
            if (cursor < self.source_len and self.source[cursor] == '=') {
                cursor += 1;
                skipSpace(self.source[0..self.source_len], &cursor);
                if (cursor < self.source_len and (self.source[cursor] == '"' or self.source[cursor] == '\'')) {
                    const quote = self.source[cursor];
                    cursor += 1;
                    const value_start = cursor;
                    while (cursor < self.source_len and self.source[cursor] != quote) : (cursor += 1) {}
                    attribute_value = self.source[value_start..cursor];
                    if (cursor < self.source_len) cursor += 1 else self.recovery_count += 1;
                } else {
                    const value_start = cursor;
                    while (cursor < self.source_len and !isAsciiSpace(self.source[cursor]) and self.source[cursor] != '>') : (cursor += 1) {}
                    attribute_value = self.source[value_start..cursor];
                }
            }
            if (self.attribute(node_index, attribute_name) == null) {
                const stored_name = try self.storeLower(attribute_name);
                const stored_value = try self.storeEntityDecoded(attribute_value);
                const item = try self.addAttribute(stored_name, stored_value);
                self.appendAttribute(node_index, item);
            } else {
                self.recovery_count += 1;
            }
        }
        if (!self_closing and !isVoidElement(source_name)) {
            if (depth.* >= stack.len) return error.DepthLimit;
            stack[depth.*] = node_index;
            depth.* += 1;
        }
        return cursor;
    }

    fn applyImpliedEndTags(self: *Document, stack: *[max_depth]u16, depth: *usize, incoming: []const u8) void {
        if (depth.* <= 1) return;
        if (std.ascii.eqlIgnoreCase(incoming, "body")) {
            var candidate = depth.*;
            while (candidate > 1) {
                candidate -= 1;
                if (std.ascii.eqlIgnoreCase(self.nodeName(stack[candidate]), "head")) {
                    depth.* = candidate;
                    self.recovery_count += 1;
                    return;
                }
            }
        }
        const current = self.nodeName(stack[depth.* - 1]);
        const close_current =
            (std.ascii.eqlIgnoreCase(current, "li") and std.ascii.eqlIgnoreCase(incoming, "li")) or
            ((std.ascii.eqlIgnoreCase(current, "dt") or std.ascii.eqlIgnoreCase(current, "dd")) and
                (std.ascii.eqlIgnoreCase(incoming, "dt") or std.ascii.eqlIgnoreCase(incoming, "dd"))) or
            (isHeading(current) and isHeading(incoming)) or
            (std.ascii.eqlIgnoreCase(current, "p") and isParagraphClosingStart(incoming)) or
            (std.ascii.eqlIgnoreCase(current, "option") and std.ascii.eqlIgnoreCase(incoming, "option")) or
            ((std.ascii.eqlIgnoreCase(current, "td") or std.ascii.eqlIgnoreCase(current, "th")) and
                (std.ascii.eqlIgnoreCase(incoming, "td") or std.ascii.eqlIgnoreCase(incoming, "th"))) or
            (std.ascii.eqlIgnoreCase(current, "tr") and std.ascii.eqlIgnoreCase(incoming, "tr"));
        if (close_current) {
            depth.* -= 1;
            self.recovery_count += 1;
        }
    }

    fn addTextNode(self: *Document, parent: u16, source_value: []const u8, decode_entities: bool) Error!?u16 {
        if (source_value.len == 0) return null;
        const value = if (decode_entities) try self.storeEntityDecoded(source_value) else try self.store(source_value);
        if (value.len == 0) return null;
        return try self.addNode(.text, .{}, value, parent);
    }

    fn addNode(self: *Document, kind: NodeKind, name: StringRef, value: StringRef, parent: u16) Error!u16 {
        if (self.node_count >= self.nodes.len) return error.NodeLimit;
        const index: u16 = @intCast(self.node_count);
        self.node_count += 1;
        self.nodes[index] = .{ .kind = kind, .name = name, .value = value, .parent = parent };
        if (parent != none) {
            if (parent >= self.node_count) return error.InvalidNode;
            const last = self.nodes[parent].last_child;
            if (last == none) {
                self.nodes[parent].first_child = index;
            } else {
                self.nodes[last].next_sibling = index;
            }
            self.nodes[parent].last_child = index;
        }
        return index;
    }

    fn addAttribute(self: *Document, name: StringRef, value: StringRef) Error!u16 {
        if (self.attribute_count >= self.attributes.len) return error.AttributeLimit;
        const index: u16 = @intCast(self.attribute_count);
        self.attribute_count += 1;
        self.attributes[index] = .{ .name = name, .value = value };
        return index;
    }

    fn appendAttribute(self: *Document, node_index: u16, attribute_index: u16) void {
        var cursor = self.nodes[node_index].first_attribute;
        if (cursor == none) {
            self.nodes[node_index].first_attribute = attribute_index;
            return;
        }
        while (self.attributes[cursor].next != none) cursor = self.attributes[cursor].next;
        self.attributes[cursor].next = attribute_index;
    }

    fn store(self: *Document, value: []const u8) Error!StringRef {
        if (value.len > self.strings.len -| self.string_len) return error.StringLimit;
        const start = self.string_len;
        if (value.len > 0) @memcpy(self.strings[start .. start + value.len], value);
        self.string_len += value.len;
        return .{ .offset = @intCast(start), .len = @intCast(value.len) };
    }

    fn storeLower(self: *Document, value: []const u8) Error!StringRef {
        if (value.len > self.strings.len -| self.string_len) return error.StringLimit;
        const start = self.string_len;
        for (value) |byte| {
            self.strings[self.string_len] = std.ascii.toLower(byte);
            self.string_len += 1;
        }
        return .{ .offset = @intCast(start), .len = @intCast(value.len) };
    }

    fn storeEntityDecoded(self: *Document, value: []const u8) Error!StringRef {
        const start = self.string_len;
        var cursor: usize = 0;
        while (cursor < value.len) {
            if (value[cursor] == '&') {
                if (decodeReference(value, cursor)) |reference| {
                    appendCodepoint(self.strings[0..], &self.string_len, reference.codepoint) catch return error.StringLimit;
                    cursor += reference.consumed;
                    continue;
                }
            }
            if (self.string_len >= self.strings.len) return error.StringLimit;
            self.strings[self.string_len] = value[cursor];
            self.string_len += 1;
            cursor += 1;
        }
        return .{ .offset = @intCast(start), .len = @intCast(self.string_len - start) };
    }
};

pub const LineKind = enum(u8) {
    text,
    heading1,
    heading2,
    heading3,
    paragraph,
    list_item,
    link,
    quote,
    preformatted,
};

pub const ViewLine = struct {
    text: StringRef,
    kind: LineKind,
    has_link: bool = false,
};

pub const PlainView = struct {
    text_storage: [max_view_bytes]u8 = undefined,
    lines: [max_view_lines]ViewLine = undefined,
    text_len: usize = 0,
    line_count: usize = 0,
    title_ref: StringRef = .{},
    current_start: usize = 0,
    current_kind: LineKind = .text,
    current_has_link: bool = false,
    pending_space: bool = false,

    pub fn reset(self: *PlainView) void {
        self.text_len = 0;
        self.line_count = 0;
        self.title_ref = .{};
        self.current_start = 0;
        self.current_kind = .text;
        self.current_has_link = false;
        self.pending_space = false;
    }

    pub fn build(self: *PlainView, document: *const Document) Error!void {
        self.reset();
        if (document.findFirstElement("title")) |title_node| {
            const start = self.text_len;
            try self.collectTitle(document, title_node);
            self.trimCurrent();
            self.title_ref = .{ .offset = @intCast(start), .len = @intCast(self.text_len - start) };
        }
        self.current_start = self.text_len;
        try self.walk(document, 0, false, .text, 0);
        try self.flush();
    }

    pub fn title(self: *const PlainView) []const u8 {
        return self.title_ref.bytes(self.text_storage[0..self.text_len]);
    }

    pub fn line(self: *const PlainView, index: usize) ?ViewLine {
        if (index >= self.line_count) return null;
        return self.lines[index];
    }

    pub fn lineText(self: *const PlainView, index: usize) []const u8 {
        const item = self.line(index) orelse return "";
        return item.text.bytes(self.text_storage[0..self.text_len]);
    }

    fn collectTitle(self: *PlainView, document: *const Document, node_index: u16) Error!void {
        var child = document.nodes[node_index].first_child;
        while (child != none) {
            if (document.nodes[child].kind == .text) try self.appendCollapsed(document.nodeValue(child), false);
            child = document.nodes[child].next_sibling;
        }
    }

    fn walk(self: *PlainView, document: *const Document, node_index: u16, preformatted: bool, inherited_kind: LineKind, depth: usize) Error!void {
        if (depth > max_depth) return error.DepthLimit;
        const node = document.nodes[node_index];
        switch (node.kind) {
            .text => try self.appendCollapsed(document.nodeValue(node_index), preformatted),
            .comment, .doctype => {},
            .document => {
                var child = node.first_child;
                while (child != none) {
                    try self.walk(document, child, preformatted, inherited_kind, depth + 1);
                    child = document.nodes[child].next_sibling;
                }
            },
            .element => {
                const name = document.nodeName(node_index);
                if (isHiddenElement(name)) return;
                if (std.ascii.eqlIgnoreCase(name, "br")) {
                    try self.flush();
                    return;
                }
                const block_kind = lineKindFor(name);
                const is_block = block_kind != null;
                if (is_block) {
                    try self.flush();
                    self.current_kind = block_kind.?;
                    if (self.current_kind == .list_item) try self.appendLiteral("- ");
                } else {
                    self.current_kind = inherited_kind;
                }
                const link = std.ascii.eqlIgnoreCase(name, "a");
                if (link) {
                    if (self.text_len == self.current_start and self.current_kind == .text) self.current_kind = .link;
                    self.current_has_link = true;
                }
                const child_pre = preformatted or std.ascii.eqlIgnoreCase(name, "pre");
                var child = node.first_child;
                while (child != none) {
                    try self.walk(document, child, child_pre, self.current_kind, depth + 1);
                    child = document.nodes[child].next_sibling;
                }
                if (is_block) {
                    try self.flush();
                    self.current_kind = inherited_kind;
                }
            },
        }
    }

    fn appendCollapsed(self: *PlainView, value: []const u8, preformatted: bool) Error!void {
        if (preformatted) {
            for (value) |byte| {
                if (byte == '\r') continue;
                if (byte == '\n') {
                    try self.flush();
                    self.current_kind = .preformatted;
                } else {
                    try self.appendByte(byte);
                }
            }
            return;
        }
        var cursor: usize = 0;
        while (cursor < value.len) {
            const sequence_len = utf8SequenceLength(value, cursor);
            if (sequence_len == 1 and isAsciiSpace(value[cursor])) {
                if (self.text_len > self.current_start) self.pending_space = true;
                cursor += 1;
                continue;
            }
            if (self.pending_space and self.text_len > self.current_start) try self.appendByte(' ');
            self.pending_space = false;
            try self.appendSlice(value[cursor .. cursor + sequence_len]);
            cursor += sequence_len;
        }
    }

    fn appendLiteral(self: *PlainView, value: []const u8) Error!void {
        self.pending_space = false;
        try self.appendSlice(value);
    }

    fn appendSlice(self: *PlainView, value: []const u8) Error!void {
        if (value.len > self.text_storage.len -| self.text_len) return error.ViewLimit;
        @memcpy(self.text_storage[self.text_len .. self.text_len + value.len], value);
        self.text_len += value.len;
    }

    fn appendByte(self: *PlainView, value: u8) Error!void {
        if (self.text_len >= self.text_storage.len) return error.ViewLimit;
        self.text_storage[self.text_len] = value;
        self.text_len += 1;
    }

    fn trimCurrent(self: *PlainView) void {
        while (self.text_len > self.current_start and isAsciiSpace(self.text_storage[self.text_len - 1])) self.text_len -= 1;
        self.pending_space = false;
    }

    fn flush(self: *PlainView) Error!void {
        self.trimCurrent();
        if (self.text_len > self.current_start) {
            if (self.line_count >= self.lines.len) return error.ViewLimit;
            self.lines[self.line_count] = .{
                .text = .{ .offset = @intCast(self.current_start), .len = @intCast(self.text_len - self.current_start) },
                .kind = self.current_kind,
                .has_link = self.current_has_link,
            };
            self.line_count += 1;
        }
        self.current_start = self.text_len;
        self.current_kind = .text;
        self.current_has_link = false;
        self.pending_space = false;
    }
};

const DecodedScalar = struct {
    codepoint: u21,
    consumed: usize,
};

const DecodedReference = struct {
    codepoint: u21,
    consumed: usize,
};

pub fn classifyMediaType(content_type_input: []const u8) MediaType {
    const content_type = trimAscii(content_type_input);
    if (content_type.len == 0) return .html;
    const separator = std.mem.indexOfScalar(u8, content_type, ';') orelse content_type.len;
    const essence = trimAscii(content_type[0..separator]);
    if (std.ascii.eqlIgnoreCase(essence, "text/html")) return .html;
    if (std.ascii.eqlIgnoreCase(essence, "text/plain")) return .plain_text;
    return .unsupported;
}

fn doctypeMode(value_input: []const u8) DocumentMode {
    const value = trimAscii(value_input);
    if (std.ascii.eqlIgnoreCase(value, "html") or
        std.ascii.eqlIgnoreCase(value, "html system \"about:legacy-compat\"") or
        std.ascii.eqlIgnoreCase(value, "html system 'about:legacy-compat'"))
    {
        return .no_quirks;
    }
    if (startsWithIgnoreCase(value, "html public") and
        (containsIgnoreCase(value, "xhtml 1.0 transitional") or
            containsIgnoreCase(value, "xhtml 1.0 frameset") or
            ((containsIgnoreCase(value, "html 4.01 transitional") or
                containsIgnoreCase(value, "html 4.01 frameset")) and containsSystemIdentifier(value))))
    {
        return .limited_quirks;
    }
    return .quirks;
}

fn containsSystemIdentifier(value: []const u8) bool {
    var quote_count: usize = 0;
    for (value) |byte| {
        if (byte == '"' or byte == '\'') quote_count += 1;
    }
    return quote_count >= 4;
}

fn containsIgnoreCase(value: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    var cursor: usize = 0;
    while (cursor + needle.len <= value.len) : (cursor += 1) {
        if (std.ascii.eqlIgnoreCase(value[cursor .. cursor + needle.len], needle)) return true;
    }
    return false;
}

fn sniffEncoding(input: []const u8, content_type: []const u8) Error!Encoding {
    if (input.len >= 3 and std.mem.eql(u8, input[0..3], "\xEF\xBB\xBF")) return .utf8;
    if (declaredCharset(content_type)) |name| return charsetEncoding(name);
    const sniff_len = @min(input.len, 1024);
    if (findCharsetDeclaration(input[0..sniff_len])) |name| return charsetEncoding(name);
    return .windows_1252;
}

fn charsetEncoding(name_input: []const u8) Error!Encoding {
    return switch (web_encoding.parseLabel(trimAscii(name_input)) catch return error.UnsupportedEncoding) {
        .utf8 => .utf8,
        .windows_1252 => .windows_1252,
    };
}

fn declaredCharset(value: []const u8) ?[]const u8 {
    var cursor: usize = 0;
    while (cursor + "charset".len <= value.len) : (cursor += 1) {
        if (!std.ascii.eqlIgnoreCase(value[cursor .. cursor + "charset".len], "charset")) continue;
        cursor += "charset".len;
        while (cursor < value.len and isAsciiSpace(value[cursor])) : (cursor += 1) {}
        if (cursor >= value.len or value[cursor] != '=') return null;
        cursor += 1;
        while (cursor < value.len and isAsciiSpace(value[cursor])) : (cursor += 1) {}
        if (cursor >= value.len) return null;
        const quote: ?u8 = if (value[cursor] == '"' or value[cursor] == '\'') value[cursor] else null;
        if (quote != null) cursor += 1;
        const start = cursor;
        while (cursor < value.len) : (cursor += 1) {
            if (quote) |delimiter| {
                if (value[cursor] == delimiter) break;
            } else if (isAsciiSpace(value[cursor]) or value[cursor] == ';' or value[cursor] == '>') {
                break;
            }
        }
        if (cursor > start) return value[start..cursor];
        return null;
    }
    return null;
}

fn findCharsetDeclaration(value: []const u8) ?[]const u8 {
    return declaredCharset(value);
}

fn decodeUtf8(input: []const u8, start: usize) DecodedScalar {
    const first = input[start];
    if (first == 0) return .{ .codepoint = 0xFFFD, .consumed = 1 };
    if (first < 0x80) return .{ .codepoint = first, .consumed = 1 };
    const expected: usize = if (first >= 0xC2 and first <= 0xDF)
        2
    else if (first >= 0xE0 and first <= 0xEF)
        3
    else if (first >= 0xF0 and first <= 0xF4)
        4
    else
        return .{ .codepoint = 0xFFFD, .consumed = 1 };
    if (start + expected > input.len) return .{ .codepoint = 0xFFFD, .consumed = 1 };
    var codepoint: u32 = first & (@as(u8, 0x7F) >> @intCast(expected));
    var index: usize = 1;
    while (index < expected) : (index += 1) {
        const byte = input[start + index];
        if ((byte & 0xC0) != 0x80) return .{ .codepoint = 0xFFFD, .consumed = 1 };
        codepoint = (codepoint << 6) | (byte & 0x3F);
    }
    if ((expected == 3 and codepoint < 0x800) or
        (expected == 4 and codepoint < 0x10000) or
        codepoint > 0x10FFFF or
        (codepoint >= 0xD800 and codepoint <= 0xDFFF))
    {
        return .{ .codepoint = 0xFFFD, .consumed = 1 };
    }
    return .{ .codepoint = @intCast(codepoint), .consumed = expected };
}

fn windows1252Codepoint(byte: u8) u21 {
    if (byte == 0) return 0xFFFD;
    if (byte < 0x80 or byte >= 0xA0) return byte;
    const map = [_]u21{
        0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
        0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
        0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
        0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
    };
    return map[byte - 0x80];
}

fn appendCodepoint(out: []u8, len: *usize, codepoint_input: u21) Error!void {
    const codepoint: u21 = if (codepoint_input == 0 or
        codepoint_input > 0x10FFFF or
        (codepoint_input >= 0xD800 and codepoint_input <= 0xDFFF))
        0xFFFD
    else
        codepoint_input;
    const needed: usize = if (codepoint < 0x80) 1 else if (codepoint < 0x800) 2 else if (codepoint < 0x10000) 3 else 4;
    if (needed > out.len -| len.*) return error.SourceTooLarge;
    switch (needed) {
        1 => out[len.*] = @intCast(codepoint),
        2 => {
            out[len.*] = @intCast(0xC0 | (codepoint >> 6));
            out[len.* + 1] = @intCast(0x80 | (codepoint & 0x3F));
        },
        3 => {
            out[len.*] = @intCast(0xE0 | (codepoint >> 12));
            out[len.* + 1] = @intCast(0x80 | ((codepoint >> 6) & 0x3F));
            out[len.* + 2] = @intCast(0x80 | (codepoint & 0x3F));
        },
        else => {
            out[len.*] = @intCast(0xF0 | (codepoint >> 18));
            out[len.* + 1] = @intCast(0x80 | ((codepoint >> 12) & 0x3F));
            out[len.* + 2] = @intCast(0x80 | ((codepoint >> 6) & 0x3F));
            out[len.* + 3] = @intCast(0x80 | (codepoint & 0x3F));
        },
    }
    len.* += needed;
}

fn decodeReference(value: []const u8, start: usize) ?DecodedReference {
    if (start >= value.len or value[start] != '&') return null;
    const semicolon = std.mem.indexOfScalarPos(u8, value, start + 1, ';') orelse return null;
    if (semicolon - start > 32) return null;
    const token = value[start + 1 .. semicolon];
    if (token.len == 0) return null;
    var codepoint: ?u21 = null;
    if (token[0] == '#') {
        const hexadecimal = token.len > 1 and (token[1] == 'x' or token[1] == 'X');
        const digits = token[if (hexadecimal) 2 else 1..];
        if (digits.len == 0) return null;
        const parsed = std.fmt.parseInt(u32, digits, if (hexadecimal) 16 else 10) catch return null;
        codepoint = if (parsed == 0 or parsed > 0x10FFFF or (parsed >= 0xD800 and parsed <= 0xDFFF)) 0xFFFD else @intCast(parsed);
    } else {
        const names = [_]struct { name: []const u8, codepoint: u21 }{
            .{ .name = "amp", .codepoint = '&' },
            .{ .name = "lt", .codepoint = '<' },
            .{ .name = "gt", .codepoint = '>' },
            .{ .name = "quot", .codepoint = '"' },
            .{ .name = "apos", .codepoint = '\'' },
            .{ .name = "nbsp", .codepoint = 0xA0 },
            .{ .name = "shy", .codepoint = 0xAD },
            .{ .name = "copy", .codepoint = 0xA9 },
            .{ .name = "reg", .codepoint = 0xAE },
            .{ .name = "hellip", .codepoint = 0x2026 },
            .{ .name = "ndash", .codepoint = 0x2013 },
            .{ .name = "mdash", .codepoint = 0x2014 },
        };
        for (names) |item| {
            if (std.ascii.eqlIgnoreCase(token, item.name)) {
                codepoint = item.codepoint;
                break;
            }
        }
    }
    return .{ .codepoint = codepoint orelse return null, .consumed = semicolon - start + 1 };
}

fn lineKindFor(name: []const u8) ?LineKind {
    if (std.ascii.eqlIgnoreCase(name, "h1")) return .heading1;
    if (std.ascii.eqlIgnoreCase(name, "h2")) return .heading2;
    if (std.ascii.eqlIgnoreCase(name, "h3") or
        std.ascii.eqlIgnoreCase(name, "h4") or
        std.ascii.eqlIgnoreCase(name, "h5") or
        std.ascii.eqlIgnoreCase(name, "h6")) return .heading3;
    if (std.ascii.eqlIgnoreCase(name, "p")) return .paragraph;
    if (std.ascii.eqlIgnoreCase(name, "li") or std.ascii.eqlIgnoreCase(name, "dt") or std.ascii.eqlIgnoreCase(name, "dd")) return .list_item;
    if (std.ascii.eqlIgnoreCase(name, "blockquote")) return .quote;
    if (std.ascii.eqlIgnoreCase(name, "pre")) return .preformatted;
    if (std.ascii.eqlIgnoreCase(name, "address")) return .paragraph;
    return null;
}

fn isHiddenElement(name: []const u8) bool {
    return std.ascii.eqlIgnoreCase(name, "head") or
        std.ascii.eqlIgnoreCase(name, "title") or
        std.ascii.eqlIgnoreCase(name, "script") or
        std.ascii.eqlIgnoreCase(name, "style") or
        std.ascii.eqlIgnoreCase(name, "template") or
        std.ascii.eqlIgnoreCase(name, "noscript");
}

fn isRawTextElement(name: []const u8) bool {
    return std.ascii.eqlIgnoreCase(name, "script") or std.ascii.eqlIgnoreCase(name, "style");
}

fn findRawTextClose(source: []const u8, start: usize, name: []const u8) ?usize {
    var cursor = start;
    while (cursor + name.len + 2 <= source.len) : (cursor += 1) {
        if (source[cursor] != '<' or source[cursor + 1] != '/') continue;
        if (!std.ascii.eqlIgnoreCase(source[cursor + 2 .. cursor + 2 + name.len], name)) continue;
        const after = cursor + 2 + name.len;
        if (after == source.len or isAsciiSpace(source[after]) or source[after] == '>') return cursor;
    }
    return null;
}

fn isVoidElement(name: []const u8) bool {
    const names = [_][]const u8{ "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr" };
    for (names) |item| if (std.ascii.eqlIgnoreCase(name, item)) return true;
    return false;
}

fn isHeading(name: []const u8) bool {
    return name.len == 2 and (name[0] == 'h' or name[0] == 'H') and name[1] >= '1' and name[1] <= '6';
}

fn isParagraphClosingStart(name: []const u8) bool {
    const names = [_][]const u8{
        "address", "article", "aside", "blockquote", "div", "dl",  "fieldset", "footer",
        "form",    "h1",      "h2",    "h3",         "h4",  "h5",  "h6",       "header",
        "hr",      "main",    "nav",   "ol",         "p",   "pre", "section",  "table",
        "ul",
    };
    for (names) |item| if (std.ascii.eqlIgnoreCase(name, item)) return true;
    return false;
}

fn utf8SequenceLength(value: []const u8, start: usize) usize {
    const decoded = decodeUtf8(value, start);
    return @min(decoded.consumed, value.len - start);
}

fn startsWithAt(value: []const u8, start: usize, needle: []const u8) bool {
    return start <= value.len and needle.len <= value.len - start and std.mem.eql(u8, value[start .. start + needle.len], needle);
}

fn startsWithIgnoreCaseAt(value: []const u8, start: usize, needle: []const u8) bool {
    return start <= value.len and needle.len <= value.len - start and std.ascii.eqlIgnoreCase(value[start .. start + needle.len], needle);
}

fn startsWithIgnoreCase(value: []const u8, needle: []const u8) bool {
    return value.len >= needle.len and std.ascii.eqlIgnoreCase(value[0..needle.len], needle);
}

fn skipSpace(value: []const u8, cursor: *usize) void {
    while (cursor.* < value.len and isAsciiSpace(value[cursor.*])) cursor.* += 1;
}

fn trimAscii(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isAsciiSpace(value[start])) : (start += 1) {}
    while (end > start and isAsciiSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn containsAsciiToken(value: []const u8, wanted: []const u8) bool {
    if (wanted.len == 0) return false;
    var cursor: usize = 0;
    while (cursor < value.len) {
        while (cursor < value.len and isAsciiSpace(value[cursor])) cursor += 1;
        const start = cursor;
        while (cursor < value.len and !isAsciiSpace(value[cursor])) cursor += 1;
        if (std.mem.eql(u8, value[start..cursor], wanted)) return true;
    }
    return false;
}

fn isAsciiSpace(value: u8) bool {
    return value == ' ' or value == '\t' or value == '\r' or value == '\n' or value == 0x0C;
}

fn isNameStart(value: u8) bool {
    return (value >= 'a' and value <= 'z') or (value >= 'A' and value <= 'Z');
}

fn isNameByte(value: u8) bool {
    return isNameStart(value) or (value >= '0' and value <= '9') or value == '-' or value == ':' or value == '_';
}

fn isAttributeNameByte(value: u8) bool {
    return !isAsciiSpace(value) and value != '=' and value != '>' and value != '/' and value != '"' and value != '\'' and value != '<';
}

test "HTML parser builds DOM and decodes references" {
    var document = Document{};
    const stats = try document.parse(
        "<!doctype html><html><head><title>R4 &amp; Web</title></head><body><h1 id='top'>Hello</h1><p>One &lt; two</p><ul><li>A<li>B</ul><a href='/next'>Next</a></body></html>",
        .{ .content_type = "text/html; charset=utf-8" },
    );
    try std.testing.expectEqual(DocumentMode.no_quirks, stats.mode);
    try std.testing.expect(stats.recoveries >= 1);
    const heading = document.findFirstElement("h1") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("top", document.attribute(heading, "id").?);
    const link = document.findFirstElement("a") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("/next", document.attribute(link, "href").?);

    var view = PlainView{};
    try view.build(&document);
    try std.testing.expectEqualStrings("R4 & Web", view.title());
    try std.testing.expect(view.line_count >= 5);
    try std.testing.expectEqualStrings("Hello", view.lineText(0));
    try std.testing.expectEqual(LineKind.heading1, view.lines[0].kind);
}

test "HTML parser decodes soft hyphen references into the DOM" {
    var document = Document{};
    _ = try document.parse("<!doctype html><p>2&shy;0</p>", .{});
    const paragraph = document.findFirstElement("p").?;
    var text_buffer: [16]u8 = undefined;
    const value = try document.textContent(paragraph, text_buffer[0..]);
    try std.testing.expectEqualSlices(u8, &.{ '2', 0xC2, 0xAD, '0' }, value);
}

test "malformed HTML closes paragraphs and ignores unmatched end tags" {
    var document = Document{};
    _ = try document.parse("<html><body></wrong><p>First<div>Second<p>Third", .{ .content_type = "text/html;charset=utf-8" });
    try std.testing.expect(document.recovery_count >= 2);
    var view = PlainView{};
    try view.build(&document);
    try std.testing.expectEqualStrings("First", view.lineText(0));
    try std.testing.expectEqualStrings("Second", view.lineText(1));
    try std.testing.expectEqualStrings("Third", view.lineText(2));
}

test "body start tag implicitly closes an omitted head end tag" {
    var document = Document{};
    _ = try document.parse(
        "<!doctype html><html><head><title>Optional head end</title><link rel=stylesheet href=screen.css><body><main>Visible page</main></body></html>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    const html_node = document.findFirstElement("html") orelse return error.TestUnexpectedResult;
    const head = document.findFirstElement("head") orelse return error.TestUnexpectedResult;
    const body = document.findFirstElement("body") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(html_node, document.nodes[head].parent);
    try std.testing.expectEqual(html_node, document.nodes[body].parent);
    try std.testing.expect(document.recovery_count >= 1);
    var view = PlainView{};
    try view.build(&document);
    try std.testing.expectEqualStrings("Visible page", view.lineText(0));
}

test "Windows-1252 and invalid UTF-8 become valid UTF-8" {
    var document = Document{};
    const legacy = "<meta charset=windows-1252><p>Euro: \x80</p>";
    const stats = try document.parse(legacy, .{});
    try std.testing.expectEqual(Encoding.windows_1252, stats.encoding);
    var view = PlainView{};
    try view.build(&document);
    try std.testing.expectEqualStrings("Euro: \xE2\x82\xAC", view.lineText(0));

    _ = try document.parse("<meta charset=utf-8><p>A\xFFB</p>", .{});
    try std.testing.expect(std.unicode.utf8ValidateSlice(document.source[0..document.source_len]));
}

test "DOM mutation remains document-owned" {
    var document = Document{};
    _ = try document.parse("<!doctype html><body><p id=x>Old</p></body>", .{ .content_type = "text/html;charset=utf-8" });
    const paragraph = document.findFirstElement("p") orelse return error.TestUnexpectedResult;
    try document.setAttribute(paragraph, "class", "notice");
    try std.testing.expectEqualStrings("notice", document.attribute(paragraph, "class").?);
    const child = try document.appendElement(paragraph, "strong");
    _ = try document.appendText(child, "New");
    try document.detach(child);
    try std.testing.expectEqual(none, document.nodes[child].parent);
}

test "DOM structural mutation prevents cycles preserves order and clones subtrees" {
    var document: Document = .{};
    _ = try document.parse("<!doctype html><body><main id='root'><p class='a'>one</p><p class='b'>two</p></main></body>", .{});
    const root = document.findElementById("root").?;
    const first = document.querySelector(".a").?;
    const second = document.querySelector(".b").?;
    try std.testing.expectEqual(first, document.nodes[root].first_child);
    try std.testing.expectEqual(first, document.previousSibling(second).?);

    const inserted = try document.appendElement(0, "span");
    try document.detach(inserted);
    try document.insertBefore(root, inserted, second);
    try std.testing.expectEqual(inserted, document.nodes[first].next_sibling);
    try std.testing.expectEqual(second, document.nodes[inserted].next_sibling);
    try std.testing.expectError(error.InvalidNode, document.attach(first, root));

    const replacement = try document.appendElement(0, "strong");
    try document.detach(replacement);
    try document.replaceChild(root, replacement, inserted);
    try std.testing.expectEqual(replacement, document.nodes[first].next_sibling);
    try std.testing.expectEqual(none, document.nodes[inserted].parent);

    try document.setAttribute(replacement, "data-state", "ready");
    try std.testing.expect(document.hasAttribute(replacement, "data-state"));
    try std.testing.expect(try document.removeAttribute(replacement, "DATA-state"));
    try std.testing.expect(!document.hasAttribute(replacement, "data-state"));

    const clone = try document.cloneNode(root, true);
    try std.testing.expectEqual(none, document.nodes[clone].parent);
    try std.testing.expectEqualStrings("main", document.nodeName(clone));
    try std.testing.expect(document.nodes[clone].first_child != none);
    var text_buffer: [32]u8 = undefined;
    try std.testing.expectEqualStrings("one", try document.textContent(document.nodes[clone].first_child, text_buffer[0..]));
    try std.testing.expect(document.isConnected(root));
    try std.testing.expect(!document.isConnected(clone));
}

test "raw text is hidden and quoted attributes keep markup bytes" {
    var document = Document{};
    _ = try document.parse(
        "<html><head><style>x < y</style><script>if (a < b) x()</script></head><body><p data-x='a>b'>Visible</p></body></html>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    const paragraph = document.findFirstElement("p") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("a>b", document.attribute(paragraph, "data-x").?);
    var view = PlainView{};
    try view.build(&document);
    try std.testing.expectEqual(@as(usize, 1), view.line_count);
    try std.testing.expectEqualStrings("Visible", view.lineText(0));
}

test "source depth node and view limits fail visibly" {
    var document = Document{};
    var oversized: [max_source_bytes + 1]u8 = .{'a'} ** (max_source_bytes + 1);
    try std.testing.expectError(error.SourceTooLarge, document.parse(oversized[0..], .{ .content_type = "text/html;charset=utf-8" }));

    var deep: [max_depth * 5 + 32]u8 = undefined;
    var len: usize = 0;
    while (len + 5 <= deep.len) {
        @memcpy(deep[len .. len + 5], "<div>");
        len += 5;
    }
    try std.testing.expectError(error.DepthLimit, document.parse(deep[0..len], .{ .content_type = "text/html;charset=utf-8" }));
}

test "DOCTYPE selects standards limited quirks and quirks modes" {
    var document = Document{};
    var stats = try document.parse("<!doctype html><p>Standards", .{});
    try std.testing.expectEqual(DocumentMode.no_quirks, stats.mode);
    stats = try document.parse(
        "<!DOCTYPE HTML PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'><p>Limited",
        .{},
    );
    try std.testing.expectEqual(DocumentMode.limited_quirks, stats.mode);
    stats = try document.parse("<!doctype potato><p>Quirks", .{});
    try std.testing.expectEqual(DocumentMode.quirks, stats.mode);
    stats = try document.parse("<p>Missing doctype", .{});
    try std.testing.expectEqual(DocumentMode.quirks, stats.mode);
}

test "loaded document MIME processing accepts HTML and rejects other handlers" {
    try std.testing.expectEqual(MediaType.html, classifyMediaType(" Text/HTML ; charset=utf-8 "));
    try std.testing.expectEqual(MediaType.plain_text, classifyMediaType("text/plain;charset=utf-8"));
    try std.testing.expectEqual(MediaType.unsupported, classifyMediaType("image/png"));
    var document = Document{};
    _ = try document.parse("<!doctype html><p>OK", .{
        .content_type = "text/html;charset=utf-8",
        .require_html_mime = true,
    });
    try std.testing.expectError(error.UnsupportedMediaType, document.parse("<p>No", .{
        .content_type = "application/json",
        .require_html_mime = true,
    }));
}
