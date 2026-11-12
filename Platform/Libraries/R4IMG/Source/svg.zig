const std = @import("std");

pub const max_source_bytes: usize = 256 * 1024;
pub const max_nodes: usize = 1024;
pub const max_attributes: usize = 8192;
pub const max_depth: usize = 64;
pub const max_use_depth: usize = 16;
pub const max_clip_depth: usize = 8;
pub const max_path_points: usize = 32 * 1024;
pub const max_subpaths: usize = 2048;
pub const max_dimension: u32 = 4096;
pub const max_pixels: usize = 4 * 1024 * 1024;

const none: u16 = std.math.maxInt(u16);

pub const Error = error{
    Empty,
    InvalidXml,
    MissingRoot,
    UnsupportedFeature,
    SourceTooLarge,
    NodeLimit,
    AttributeLimit,
    DepthLimit,
    PathLimit,
    InvalidNumber,
    InvalidDimensions,
    PixelBufferTooSmall,
    ScratchBufferTooSmall,
    TooLarge,
};

pub const Info = struct {
    width: u32,
    height: u32,
    view_box: Box,
};

pub const GlyphProvider = struct {
    context: ?*anyopaque = null,
    width: u16 = 8,
    height: u16 = 8,
    advance: u16 = 8,
    baseline: i16 = 7,
    row: ?*const fn (?*anyopaque, u32, u32) callconv(.c) u64 = null,

    fn bits(self: GlyphProvider, codepoint: u32, row_index: u32) u64 {
        const callback = self.row orelse return 0;
        if (row_index >= self.height) return 0;
        return callback(self.context, codepoint, row_index);
    }
};

pub const LinkSink = struct {
    context: ?*anyopaque = null,
    record: ?*const fn (?*anyopaque, u16, i32, i32, i32, i32) callconv(.c) void = null,

    fn add(self: LinkSink, node: u16, x: i32, y: i32, width: i32, height: i32) void {
        const callback = self.record orelse return;
        if (width <= 0 or height <= 0) return;
        callback(self.context, node, x, y, width, height);
    }
};

pub const RenderOptions = struct {
    glyphs: ?GlyphProvider = null,
    links: ?LinkSink = null,
    background: ?u32 = null,
};

pub fn sniff(source: []const u8) bool {
    if (source.len == 0) return false;
    var cursor: usize = if (std.mem.startsWith(u8, source, "\xEF\xBB\xBF")) 3 else 0;
    while (cursor < source.len) {
        skipSpace(source, &cursor);
        if (startsAt(source, cursor, "<?")) {
            const end = std.mem.indexOfPos(u8, source, cursor + 2, "?>") orelse return false;
            cursor = end + 2;
            continue;
        }
        if (startsAt(source, cursor, "<!--")) {
            const end = std.mem.indexOfPos(u8, source, cursor + 4, "-->") orelse return false;
            cursor = end + 3;
            continue;
        }
        if (startsAtIgnoreCase(source, cursor, "<!doctype")) {
            const end = std.mem.indexOfScalarPos(u8, source, cursor + 9, '>') orelse return false;
            cursor = end + 1;
            continue;
        }
        return startsAtIgnoreCase(source, cursor, "<svg") and
            cursor + 4 < source.len and (std.ascii.isWhitespace(source[cursor + 4]) or source[cursor + 4] == '>' or source[cursor + 4] == '/');
    }
    return false;
}

pub const Box = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
};

const Ref = struct {
    offset: u32 = 0,
    len: u32 = 0,

    fn bytes(self: Ref, source: []const u8) []const u8 {
        const start: usize = self.offset;
        const length: usize = self.len;
        if (start > source.len or length > source.len - start) return "";
        return source[start .. start + length];
    }
};

const Tag = enum(u8) {
    unknown,
    svg,
    group,
    defs,
    link,
    use,
    symbol,
    clip_path,
    path,
    rect,
    circle,
    ellipse,
    line,
    polyline,
    polygon,
    text,
    text_node,
    image,
    filter,
    mask,
    pattern,
    script,
    style,
    foreign_object,
};

const Attribute = struct {
    name: Ref,
    value: Ref,
};

const Node = struct {
    tag: Tag = .unknown,
    name: Ref = .{},
    text: Ref = .{},
    parent: u16 = none,
    first_child: u16 = none,
    last_child: u16 = none,
    next_sibling: u16 = none,
    attribute_start: u16 = 0,
    attribute_count: u16 = 0,
};

const Document = struct {
    source: []const u8,
    nodes: []Node,
    attributes: []Attribute,
    root: u16,

    fn attribute(self: *const Document, node_index: u16, wanted: []const u8) ?[]const u8 {
        if (node_index >= self.nodes.len) return null;
        const node = self.nodes[node_index];
        const start: usize = node.attribute_start;
        const count: usize = node.attribute_count;
        if (start > self.attributes.len or count > self.attributes.len - start) return null;
        for (self.attributes[start .. start + count]) |item| {
            if (std.ascii.eqlIgnoreCase(item.name.bytes(self.source), wanted)) {
                return item.value.bytes(self.source);
            }
        }
        return null;
    }

    fn findId(self: *const Document, wanted: []const u8) ?u16 {
        if (wanted.len == 0) return null;
        for (self.nodes, 0..) |_, index| {
            const id = self.attribute(@intCast(index), "id") orelse continue;
            if (std.mem.eql(u8, id, wanted)) return @intCast(index);
        }
        return null;
    }
};

const Parser = struct {
    source: []const u8,
    cursor: usize = 0,
    nodes: std.ArrayList(Node) = .empty,
    attributes: std.ArrayList(Attribute) = .empty,
    stack: [max_depth]u16 = [_]u16{none} ** max_depth,
    depth: usize = 0,
    root: u16 = none,

    fn deinit(self: *Parser, allocator: std.mem.Allocator) void {
        self.nodes.deinit(allocator);
        self.attributes.deinit(allocator);
    }

    fn parse(self: *Parser, allocator: std.mem.Allocator) Error!Document {
        if (self.source.len == 0) return error.Empty;
        if (self.source.len > max_source_bytes) return error.SourceTooLarge;
        if (std.mem.startsWith(u8, self.source, "\xEF\xBB\xBF")) self.cursor = 3;

        while (self.cursor < self.source.len) {
            if (self.source[self.cursor] != '<') {
                try self.parseText(allocator);
                continue;
            }
            if (startsAt(self.source, self.cursor, "<!--")) {
                try self.skipDelimited("-->");
                continue;
            }
            if (startsAt(self.source, self.cursor, "<?")) {
                try self.skipDelimited("?>");
                continue;
            }
            if (startsAtIgnoreCase(self.source, self.cursor, "<!doctype")) {
                try self.skipDeclaration();
                continue;
            }
            if (startsAt(self.source, self.cursor, "<![CDATA[")) {
                try self.parseCdata(allocator);
                continue;
            }
            if (startsAt(self.source, self.cursor, "</")) {
                try self.parseClose();
                continue;
            }
            if (startsAt(self.source, self.cursor, "<!")) return error.UnsupportedFeature;
            try self.parseOpen(allocator);
        }
        if (self.root == none or self.depth != 0) return error.MissingRoot;
        return .{
            .source = self.source,
            .nodes = self.nodes.items,
            .attributes = self.attributes.items,
            .root = self.root,
        };
    }

    fn parseText(self: *Parser, allocator: std.mem.Allocator) Error!void {
        const start = self.cursor;
        while (self.cursor < self.source.len and self.source[self.cursor] != '<') self.cursor += 1;
        if (self.depth == 0 or onlyWhitespace(self.source[start..self.cursor])) return;
        try self.appendNode(allocator, .{
            .tag = .text_node,
            .text = makeRef(start, self.cursor - start),
        }, true);
    }

    fn parseCdata(self: *Parser, allocator: std.mem.Allocator) Error!void {
        const start = self.cursor + 9;
        const end = std.mem.indexOfPos(u8, self.source, start, "]]>") orelse return error.InvalidXml;
        self.cursor = end + 3;
        if (self.depth == 0 or onlyWhitespace(self.source[start..end])) return;
        try self.appendNode(allocator, .{
            .tag = .text_node,
            .text = makeRef(start, end - start),
        }, true);
    }

    fn parseOpen(self: *Parser, allocator: std.mem.Allocator) Error!void {
        self.cursor += 1;
        skipSpace(self.source, &self.cursor);
        const name_start = self.cursor;
        while (self.cursor < self.source.len and isNameByte(self.source[self.cursor])) self.cursor += 1;
        if (self.cursor == name_start) return error.InvalidXml;
        const name_ref = makeRef(name_start, self.cursor - name_start);
        const attribute_start = self.attributes.items.len;
        var self_closing = false;

        while (self.cursor < self.source.len) {
            skipSpace(self.source, &self.cursor);
            if (self.cursor >= self.source.len) return error.InvalidXml;
            if (self.source[self.cursor] == '>') {
                self.cursor += 1;
                break;
            }
            if (self.source[self.cursor] == '/' and self.cursor + 1 < self.source.len and self.source[self.cursor + 1] == '>') {
                self.cursor += 2;
                self_closing = true;
                break;
            }
            if (self.attributes.items.len >= max_attributes) return error.AttributeLimit;
            const attribute_name_start = self.cursor;
            while (self.cursor < self.source.len and isNameByte(self.source[self.cursor])) self.cursor += 1;
            if (self.cursor == attribute_name_start) return error.InvalidXml;
            const attribute_name = makeRef(attribute_name_start, self.cursor - attribute_name_start);
            skipSpace(self.source, &self.cursor);
            var value = makeRef(self.cursor, 0);
            if (self.cursor < self.source.len and self.source[self.cursor] == '=') {
                self.cursor += 1;
                skipSpace(self.source, &self.cursor);
                if (self.cursor >= self.source.len) return error.InvalidXml;
                if (self.source[self.cursor] == '"' or self.source[self.cursor] == '\'') {
                    const quote = self.source[self.cursor];
                    self.cursor += 1;
                    const value_start = self.cursor;
                    while (self.cursor < self.source.len and self.source[self.cursor] != quote) self.cursor += 1;
                    if (self.cursor >= self.source.len) return error.InvalidXml;
                    value = makeRef(value_start, self.cursor - value_start);
                    self.cursor += 1;
                } else {
                    const value_start = self.cursor;
                    while (self.cursor < self.source.len and !std.ascii.isWhitespace(self.source[self.cursor]) and
                        self.source[self.cursor] != '>' and self.source[self.cursor] != '/') self.cursor += 1;
                    value = makeRef(value_start, self.cursor - value_start);
                }
            }
            self.attributes.append(allocator, .{ .name = attribute_name, .value = value }) catch return error.ScratchBufferTooSmall;
        }

        if (self.nodes.items.len >= max_nodes) return error.NodeLimit;
        const tag = classifyTag(name_ref.bytes(self.source));
        const node_index: u16 = @intCast(self.nodes.items.len);
        try self.appendNode(allocator, .{
            .tag = tag,
            .name = name_ref,
            .attribute_start = @intCast(attribute_start),
            .attribute_count = @intCast(self.attributes.items.len - attribute_start),
        }, false);
        if (self.root == none and tag == .svg) self.root = node_index;
        if (!self_closing) {
            if (self.depth >= self.stack.len) return error.DepthLimit;
            self.stack[self.depth] = node_index;
            self.depth += 1;
        }
    }

    fn appendNode(self: *Parser, allocator: std.mem.Allocator, initial: Node, text_node: bool) Error!void {
        if (self.nodes.items.len >= max_nodes) return error.NodeLimit;
        var node = initial;
        if (self.depth > 0) node.parent = self.stack[self.depth - 1];
        self.nodes.append(allocator, node) catch return error.ScratchBufferTooSmall;
        const index: u16 = @intCast(self.nodes.items.len - 1);
        if (node.parent != none) {
            const parent = &self.nodes.items[node.parent];
            if (parent.first_child == none) {
                parent.first_child = index;
            } else {
                self.nodes.items[parent.last_child].next_sibling = index;
            }
            parent.last_child = index;
        } else if (text_node) {
            return error.InvalidXml;
        }
    }

    fn parseClose(self: *Parser) Error!void {
        self.cursor += 2;
        skipSpace(self.source, &self.cursor);
        const name_start = self.cursor;
        while (self.cursor < self.source.len and isNameByte(self.source[self.cursor])) self.cursor += 1;
        if (self.cursor == name_start) return error.InvalidXml;
        const name = self.source[name_start..self.cursor];
        skipSpace(self.source, &self.cursor);
        if (self.cursor >= self.source.len or self.source[self.cursor] != '>') return error.InvalidXml;
        self.cursor += 1;
        if (self.depth == 0) return error.InvalidXml;
        const open = self.stack[self.depth - 1];
        if (!std.ascii.eqlIgnoreCase(self.nodes.items[open].name.bytes(self.source), name)) return error.InvalidXml;
        self.depth -= 1;
    }

    fn skipDelimited(self: *Parser, delimiter: []const u8) Error!void {
        const end = std.mem.indexOfPos(u8, self.source, self.cursor + 2, delimiter) orelse return error.InvalidXml;
        self.cursor = end + delimiter.len;
    }

    fn skipDeclaration(self: *Parser) Error!void {
        var quote: u8 = 0;
        var bracket_depth: usize = 0;
        while (self.cursor < self.source.len) : (self.cursor += 1) {
            const byte = self.source[self.cursor];
            if (quote != 0) {
                if (byte == quote) quote = 0;
                continue;
            }
            if (byte == '"' or byte == '\'') {
                quote = byte;
            } else if (byte == '[') {
                bracket_depth += 1;
            } else if (byte == ']') {
                bracket_depth -|= 1;
            } else if (byte == '>' and bracket_depth == 0) {
                self.cursor += 1;
                return;
            }
        }
        return error.InvalidXml;
    }
};

pub fn probe(source: []const u8) Error!Info {
    if (source.len == 0) return error.Empty;
    if (source.len > max_source_bytes) return error.SourceTooLarge;
    try validateStructure(source);
    var cursor: usize = if (std.mem.startsWith(u8, source, "\xEF\xBB\xBF")) 3 else 0;
    while (cursor < source.len) {
        skipSpace(source, &cursor);
        if (startsAt(source, cursor, "<?")) {
            const end = std.mem.indexOfPos(u8, source, cursor + 2, "?>") orelse return error.InvalidXml;
            cursor = end + 2;
            continue;
        }
        if (startsAt(source, cursor, "<!--")) {
            const end = std.mem.indexOfPos(u8, source, cursor + 4, "-->") orelse return error.InvalidXml;
            cursor = end + 3;
            continue;
        }
        if (startsAtIgnoreCase(source, cursor, "<!doctype")) {
            var preamble = Parser{ .source = source, .cursor = cursor };
            try preamble.skipDeclaration();
            cursor = preamble.cursor;
            continue;
        }
        break;
    }
    if (startsAt(source, cursor, "<!")) return error.UnsupportedFeature;
    if (cursor >= source.len or source[cursor] != '<') return error.MissingRoot;
    cursor += 1;
    skipSpace(source, &cursor);
    const name_start = cursor;
    while (cursor < source.len and isNameByte(source[cursor])) cursor += 1;
    if (cursor == name_start or classifyTag(source[name_start..cursor]) != .svg) return error.MissingRoot;

    var width_value: ?[]const u8 = null;
    var height_value: ?[]const u8 = null;
    var view_box_value: ?[]const u8 = null;
    var attribute_count: usize = 0;
    while (cursor < source.len) {
        skipSpace(source, &cursor);
        if (cursor >= source.len) return error.InvalidXml;
        if (source[cursor] == '>') break;
        if (source[cursor] == '/' and cursor + 1 < source.len and source[cursor + 1] == '>') break;
        if (attribute_count >= max_attributes) return error.AttributeLimit;
        attribute_count += 1;
        const attribute_name_start = cursor;
        while (cursor < source.len and isNameByte(source[cursor])) cursor += 1;
        if (cursor == attribute_name_start) return error.InvalidXml;
        const attribute_name = source[attribute_name_start..cursor];
        skipSpace(source, &cursor);
        var value: []const u8 = "";
        if (cursor < source.len and source[cursor] == '=') {
            cursor += 1;
            skipSpace(source, &cursor);
            if (cursor >= source.len) return error.InvalidXml;
            if (source[cursor] == '"' or source[cursor] == '\'') {
                const quote = source[cursor];
                cursor += 1;
                const value_start = cursor;
                while (cursor < source.len and source[cursor] != quote) cursor += 1;
                if (cursor >= source.len) return error.InvalidXml;
                value = source[value_start..cursor];
                cursor += 1;
            } else {
                const value_start = cursor;
                while (cursor < source.len and !std.ascii.isWhitespace(source[cursor]) and source[cursor] != '>' and source[cursor] != '/') cursor += 1;
                value = source[value_start..cursor];
            }
        }
        if (std.ascii.eqlIgnoreCase(attribute_name, "width")) {
            width_value = value;
        } else if (std.ascii.eqlIgnoreCase(attribute_name, "height")) {
            height_value = value;
        } else if (std.ascii.eqlIgnoreCase(attribute_name, "viewBox")) {
            view_box_value = value;
        }
    }
    return infoFromAttributes(width_value, height_value, view_box_value);
}

fn validateStructure(source: []const u8) Error!void {
    var cursor: usize = if (std.mem.startsWith(u8, source, "\xEF\xBB\xBF")) 3 else 0;
    var stack: [max_depth]Ref = [_]Ref{.{}} ** max_depth;
    var depth: usize = 0;
    var node_count: usize = 0;
    var attribute_count: usize = 0;
    while (cursor < source.len) {
        if (source[cursor] != '<') {
            const start = cursor;
            while (cursor < source.len and source[cursor] != '<') cursor += 1;
            if (depth > 0 and !onlyWhitespace(source[start..cursor])) {
                if (node_count >= max_nodes) return error.NodeLimit;
                node_count += 1;
            }
            continue;
        }
        if (startsAt(source, cursor, "<!--")) {
            const end = std.mem.indexOfPos(u8, source, cursor + 4, "-->") orelse return error.InvalidXml;
            cursor = end + 3;
            continue;
        }
        if (startsAt(source, cursor, "<?")) {
            const end = std.mem.indexOfPos(u8, source, cursor + 2, "?>") orelse return error.InvalidXml;
            cursor = end + 2;
            continue;
        }
        if (startsAtIgnoreCase(source, cursor, "<!doctype")) {
            var declaration = Parser{ .source = source, .cursor = cursor };
            try declaration.skipDeclaration();
            cursor = declaration.cursor;
            continue;
        }
        if (startsAt(source, cursor, "<![CDATA[")) {
            const start = cursor + 9;
            const end = std.mem.indexOfPos(u8, source, start, "]]>") orelse return error.InvalidXml;
            if (depth > 0 and !onlyWhitespace(source[start..end])) {
                if (node_count >= max_nodes) return error.NodeLimit;
                node_count += 1;
            }
            cursor = end + 3;
            continue;
        }
        if (startsAt(source, cursor, "<!")) return error.UnsupportedFeature;
        if (startsAt(source, cursor, "</")) {
            cursor += 2;
            skipSpace(source, &cursor);
            const name_start = cursor;
            while (cursor < source.len and isNameByte(source[cursor])) cursor += 1;
            if (cursor == name_start) return error.InvalidXml;
            const name_end = cursor;
            skipSpace(source, &cursor);
            if (cursor >= source.len or source[cursor] != '>' or depth == 0) return error.InvalidXml;
            const name = source[name_start..name_end];
            const open_name = stack[depth - 1].bytes(source);
            if (!std.ascii.eqlIgnoreCase(open_name, name)) return error.InvalidXml;
            depth -= 1;
            cursor += 1;
            continue;
        }

        cursor += 1;
        skipSpace(source, &cursor);
        const name_start = cursor;
        while (cursor < source.len and isNameByte(source[cursor])) cursor += 1;
        if (cursor == name_start) return error.InvalidXml;
        const name_end = cursor;
        if (node_count >= max_nodes) return error.NodeLimit;
        node_count += 1;
        var self_closing = false;
        while (cursor < source.len) {
            skipSpace(source, &cursor);
            if (cursor >= source.len) return error.InvalidXml;
            if (source[cursor] == '>') {
                cursor += 1;
                break;
            }
            if (source[cursor] == '/' and cursor + 1 < source.len and source[cursor + 1] == '>') {
                cursor += 2;
                self_closing = true;
                break;
            }
            if (attribute_count >= max_attributes) return error.AttributeLimit;
            attribute_count += 1;
            const attribute_name_start = cursor;
            while (cursor < source.len and isNameByte(source[cursor])) cursor += 1;
            if (cursor == attribute_name_start) return error.InvalidXml;
            skipSpace(source, &cursor);
            if (cursor < source.len and source[cursor] == '=') {
                cursor += 1;
                skipSpace(source, &cursor);
                if (cursor >= source.len) return error.InvalidXml;
                if (source[cursor] == '"' or source[cursor] == '\'') {
                    const quote = source[cursor];
                    cursor += 1;
                    while (cursor < source.len and source[cursor] != quote) cursor += 1;
                    if (cursor >= source.len) return error.InvalidXml;
                    cursor += 1;
                } else {
                    const value_start = cursor;
                    while (cursor < source.len and !std.ascii.isWhitespace(source[cursor]) and source[cursor] != '>' and source[cursor] != '/') cursor += 1;
                    if (cursor == value_start) return error.InvalidXml;
                }
            }
        }
        if (!self_closing) {
            if (depth >= stack.len) return error.DepthLimit;
            stack[depth] = makeRef(name_start, name_end - name_start);
            depth += 1;
        }
    }
    if (depth != 0) return error.MissingRoot;
}

pub fn render(source: []const u8, pixels: []u32, width: u32, height: u32, scratch: []u8, options: RenderOptions) Error!void {
    const count = checkedPixels(width, height) catch |err| return err;
    if (pixels.len < count) return error.PixelBufferTooSmall;
    var fixed = std.heap.FixedBufferAllocator.init(scratch);
    const allocator = fixed.allocator();
    var parser = Parser{ .source = source };
    defer parser.deinit(allocator);
    const document = try parser.parse(allocator);
    const info = try rootInfo(&document);
    if (options.background) |background| {
        @memset(pixels[0..count], 0xFF000000 | (background & 0xFFFFFF));
    } else {
        @memset(pixels[0..count], 0);
    }
    var renderer = Renderer{
        .allocator = allocator,
        .document = &document,
        .pixels = pixels[0..count],
        .width = width,
        .height = height,
        .options = options,
    };
    const viewport = viewBoxTransform(info.view_box, width, height, document.attribute(document.root, "preserveAspectRatio"));
    try renderer.renderNode(document.root, .{}, viewport, &.{}, 0, 0);
}

fn rootInfo(document: *const Document) Error!Info {
    if (document.root == none or document.nodes[document.root].tag != .svg) return error.MissingRoot;
    return infoFromAttributes(
        document.attribute(document.root, "width"),
        document.attribute(document.root, "height"),
        document.attribute(document.root, "viewBox"),
    );
}

fn infoFromAttributes(width_attribute: ?[]const u8, height_attribute: ?[]const u8, view_box_attribute: ?[]const u8) Error!Info {
    const view_box = parseViewBox(view_box_attribute) catch |err| switch (err) {
        error.InvalidNumber => return error.InvalidDimensions,
        else => return err,
    };
    const width_value = parseLength(width_attribute, 0) catch 0;
    const height_value = parseLength(height_attribute, 0) catch 0;
    var width: f32 = width_value;
    var height: f32 = height_value;
    if (!(width > 0)) width = if (view_box.w > 0) view_box.w else 300;
    if (!(height > 0)) height = if (view_box.h > 0) view_box.h else 150;
    if (!std.math.isFinite(width) or !std.math.isFinite(height) or width <= 0 or height <= 0 or
        width > @as(f32, @floatFromInt(max_dimension)) or height > @as(f32, @floatFromInt(max_dimension))) return error.InvalidDimensions;
    const rounded_width: u32 = @intFromFloat(@max(1, @ceil(width)));
    const rounded_height: u32 = @intFromFloat(@max(1, @ceil(height)));
    _ = try checkedPixels(rounded_width, rounded_height);
    return .{
        .width = rounded_width,
        .height = rounded_height,
        .view_box = if (view_box.w > 0 and view_box.h > 0) view_box else .{ .x = 0, .y = 0, .w = width, .h = height },
    };
}

const Matrix = struct {
    a: f32 = 1,
    b: f32 = 0,
    c: f32 = 0,
    d: f32 = 1,
    e: f32 = 0,
    f: f32 = 0,

    fn multiply(self: Matrix, local: Matrix) Matrix {
        return .{
            .a = self.a * local.a + self.c * local.b,
            .b = self.b * local.a + self.d * local.b,
            .c = self.a * local.c + self.c * local.d,
            .d = self.b * local.c + self.d * local.d,
            .e = self.a * local.e + self.c * local.f + self.e,
            .f = self.b * local.e + self.d * local.f + self.f,
        };
    }

    fn point(self: Matrix, value: Point) Point {
        return .{
            .x = self.a * value.x + self.c * value.y + self.e,
            .y = self.b * value.x + self.d * value.y + self.f,
        };
    }

    fn scale(self: Matrix) f32 {
        const sx = @sqrt(self.a * self.a + self.b * self.b);
        const sy = @sqrt(self.c * self.c + self.d * self.d);
        return @max(0.0001, (sx + sy) * 0.5);
    }
};

const Point = struct {
    x: f32 = 0,
    y: f32 = 0,
};

fn viewBoxTransform(box: Box, width: u32, height: u32, preserve: ?[]const u8) Matrix {
    const target_width: f32 = @floatFromInt(width);
    const target_height: f32 = @floatFromInt(height);
    var sx = target_width / box.w;
    var sy = target_height / box.h;
    const value = if (preserve) |raw| std.mem.trim(u8, raw, " \t\r\n") else "";
    if (containsWordIgnoreCase(value, "none")) {
        return .{ .a = sx, .d = sy, .e = -box.x * sx, .f = -box.y * sy };
    }
    const slice = if (containsWordIgnoreCase(value, "slice")) @max(sx, sy) else @min(sx, sy);
    sx = slice;
    sy = slice;
    const extra_x = target_width - box.w * sx;
    const extra_y = target_height - box.h * sy;
    var align_x: f32 = 0.5;
    var align_y: f32 = 0.5;
    if (containsIgnoreCase(value, "xmin")) align_x = 0 else if (containsIgnoreCase(value, "xmax")) align_x = 1;
    if (containsIgnoreCase(value, "ymin")) align_y = 0 else if (containsIgnoreCase(value, "ymax")) align_y = 1;
    return .{
        .a = sx,
        .d = sy,
        .e = -box.x * sx + extra_x * align_x,
        .f = -box.y * sy + extra_y * align_y,
    };
}

const Paint = union(enum) {
    none,
    color: u32,
};

const FillRule = enum { nonzero, evenodd };

const Style = struct {
    fill: Paint = .{ .color = 0xFF000000 },
    stroke: Paint = .none,
    color: u32 = 0xFF000000,
    stroke_width: f32 = 1,
    opacity: f32 = 1,
    fill_opacity: f32 = 1,
    stroke_opacity: f32 = 1,
    fill_rule: FillRule = .nonzero,
    font_size: f32 = 16,
    text_anchor: enum { start, middle, end } = .start,
    visible: bool = true,
    clip: []const u8 = "",
};

const Subpath = struct {
    start: u32,
    count: u32,
    closed: bool,
};

const Geometry = struct {
    allocator: std.mem.Allocator,
    points: std.ArrayList(Point) = .empty,
    subpaths: std.ArrayList(Subpath) = .empty,
    active_start: usize = 0,
    active: bool = false,
    bounds: Box = .{ .x = std.math.inf(f32), .y = std.math.inf(f32), .w = -std.math.inf(f32), .h = -std.math.inf(f32) },

    fn deinit(self: *Geometry) void {
        self.points.deinit(self.allocator);
        self.subpaths.deinit(self.allocator);
    }

    fn moveTo(self: *Geometry, point: Point) Error!void {
        try self.finish(false);
        self.active_start = self.points.items.len;
        self.active = true;
        try self.append(point);
    }

    fn lineTo(self: *Geometry, point: Point) Error!void {
        if (!self.active) try self.moveTo(point) else try self.append(point);
    }

    fn append(self: *Geometry, point: Point) Error!void {
        if (self.points.items.len >= max_path_points) return error.PathLimit;
        self.points.append(self.allocator, point) catch return error.ScratchBufferTooSmall;
        self.bounds.x = @min(self.bounds.x, point.x);
        self.bounds.y = @min(self.bounds.y, point.y);
        self.bounds.w = @max(self.bounds.w, point.x);
        self.bounds.h = @max(self.bounds.h, point.y);
    }

    fn finish(self: *Geometry, closed: bool) Error!void {
        if (!self.active) return;
        const count = self.points.items.len - self.active_start;
        if (count > 0) {
            if (self.subpaths.items.len >= max_subpaths) return error.PathLimit;
            self.subpaths.append(self.allocator, .{
                .start = @intCast(self.active_start),
                .count = @intCast(count),
                .closed = closed,
            }) catch return error.ScratchBufferTooSmall;
        }
        self.active = false;
    }

    fn finalize(self: *Geometry) Error!void {
        try self.finish(false);
    }

    fn transform(self: *Geometry, matrix: Matrix) void {
        self.bounds = .{ .x = std.math.inf(f32), .y = std.math.inf(f32), .w = -std.math.inf(f32), .h = -std.math.inf(f32) };
        for (self.points.items) |*point| {
            point.* = matrix.point(point.*);
            self.bounds.x = @min(self.bounds.x, point.x);
            self.bounds.y = @min(self.bounds.y, point.y);
            self.bounds.w = @max(self.bounds.w, point.x);
            self.bounds.h = @max(self.bounds.h, point.y);
        }
    }
};

const Renderer = struct {
    allocator: std.mem.Allocator,
    document: *const Document,
    pixels: []u32,
    width: u32,
    height: u32,
    options: RenderOptions,
    active_link: u16 = none,

    fn renderNode(
        self: *Renderer,
        node_index: u16,
        inherited: Style,
        parent_matrix: Matrix,
        clips: []const *const Geometry,
        depth: usize,
        use_depth: usize,
    ) Error!void {
        if (depth >= max_depth) return error.DepthLimit;
        if (node_index >= self.document.nodes.len) return error.InvalidXml;
        const node = self.document.nodes[node_index];
        if (node.tag == .text_node or node.tag == .script or node.tag == .style or node.tag == .foreign_object) return;
        const parent_link = self.active_link;
        defer self.active_link = parent_link;
        if (node.tag == .link) {
            self.active_link = none;
            if (self.document.attribute(node_index, "data-r4-node")) |value| {
                self.active_link = std.fmt.parseInt(u16, value, 10) catch none;
            }
        }
        var style = inherited;
        // clip-path applies to this element as a graphical effect. It is not
        // inherited as a presentation property by descendants.
        style.clip = "";
        applyNodeStyle(self.document, node_index, &style);
        if (!style.visible) return;
        const local_matrix = parseTransform(self.document.attribute(node_index, "transform")) catch return error.InvalidNumber;
        var matrix = parent_matrix.multiply(local_matrix);
        if (node.tag == .use) {
            matrix = matrix.multiply(.{
                .e = parseLength(self.document.attribute(node_index, "x"), 0) catch 0,
                .f = parseLength(self.document.attribute(node_index, "y"), 0) catch 0,
            });
        }

        var clip_geometry = Geometry{ .allocator = self.allocator };
        defer clip_geometry.deinit();
        var clip_storage: [max_clip_depth]*const Geometry = undefined;
        var active_clips = clips;
        if (style.clip.len > 0) {
            if (clips.len >= clip_storage.len) return error.DepthLimit;
            const clip_id = functionalId(style.clip) orelse return error.UnsupportedFeature;
            const clip_node = self.document.findId(clip_id) orelse return error.InvalidXml;
            if (self.document.nodes[clip_node].tag != .clip_path) return error.InvalidXml;
            const units = self.document.attribute(clip_node, "clipPathUnits") orelse "userSpaceOnUse";
            if (!std.ascii.eqlIgnoreCase(units, "userSpaceOnUse")) return error.UnsupportedFeature;
            try self.buildClipGeometry(clip_node, matrix, &clip_geometry, 0, 0);
            try clip_geometry.finalize();
            if (clip_geometry.points.items.len == 0) return;
            for (clips, 0..) |clip, index| clip_storage[index] = clip;
            clip_storage[clips.len] = &clip_geometry;
            active_clips = clip_storage[0 .. clips.len + 1];
        }

        switch (node.tag) {
            .defs, .clip_path => return,
            // Rasterizing nested SVG <image> resources belongs to the caller's
            // document-resource pipeline.  An unavailable nested resource must
            // not discard the vector content that can be rendered without it.
            .image => return,
            .filter, .mask, .pattern => return error.UnsupportedFeature,
            .path, .rect, .circle, .ellipse, .line, .polyline, .polygon => {
                var geometry = Geometry{ .allocator = self.allocator };
                defer geometry.deinit();
                try buildGeometry(self.document, node_index, &geometry);
                try geometry.finalize();
                geometry.transform(matrix);
                if (geometry.points.items.len == 0) return;
                switch (style.fill) {
                    .none => {},
                    .color => |color| self.paintFill(&geometry, active_clips, color, style.opacity * style.fill_opacity, style.fill_rule),
                }
                switch (style.stroke) {
                    .none => {},
                    .color => |color| self.paintStroke(&geometry, active_clips, color, style.opacity * style.stroke_opacity, style.stroke_width * matrix.scale()),
                }
                const link_padding: i32 = switch (style.stroke) {
                    .none => 0,
                    .color => @intFromFloat(@ceil(style.stroke_width * matrix.scale() * 0.5)),
                };
                self.recordLink(&geometry, active_clips, link_padding);
            },
            .text => try self.renderText(node_index, style, matrix, active_clips),
            .use => {
                if (use_depth >= max_use_depth) return error.DepthLimit;
                const href = self.document.attribute(node_index, "href") orelse self.document.attribute(node_index, "xlink:href") orelse return;
                if (href.len < 2 or href[0] != '#') return error.UnsupportedFeature;
                const target = self.document.findId(href[1..]) orelse return;
                try self.renderNode(target, style, matrix, active_clips, depth + 1, use_depth + 1);
            },
            else => {
                var child = node.first_child;
                while (child != none) {
                    try self.renderNode(child, style, matrix, active_clips, depth + 1, use_depth);
                    child = self.document.nodes[child].next_sibling;
                }
            },
        }
    }

    fn buildClipGeometry(self: *Renderer, node_index: u16, parent_matrix: Matrix, output: *Geometry, depth: usize, use_depth: usize) Error!void {
        if (depth >= max_depth) return error.DepthLimit;
        if (node_index >= self.document.nodes.len) return error.InvalidXml;
        const node = self.document.nodes[node_index];
        const local = parseTransform(self.document.attribute(node_index, "transform")) catch return error.InvalidNumber;
        var matrix = parent_matrix.multiply(local);
        if (node.tag == .use) {
            matrix = matrix.multiply(.{
                .e = parseLength(self.document.attribute(node_index, "x"), 0) catch 0,
                .f = parseLength(self.document.attribute(node_index, "y"), 0) catch 0,
            });
        }
        switch (node.tag) {
            .path, .rect, .circle, .ellipse, .line, .polyline, .polygon => {
                var geometry = Geometry{ .allocator = self.allocator };
                defer geometry.deinit();
                try buildGeometry(self.document, node_index, &geometry);
                try geometry.finalize();
                geometry.transform(matrix);
                try appendGeometry(output, &geometry);
            },
            .use => {
                if (use_depth >= max_use_depth) return error.DepthLimit;
                const href = self.document.attribute(node_index, "href") orelse self.document.attribute(node_index, "xlink:href") orelse return;
                if (href.len < 2 or href[0] != '#') return error.UnsupportedFeature;
                const target = self.document.findId(href[1..]) orelse return error.InvalidXml;
                try self.buildClipGeometry(target, matrix, output, depth + 1, use_depth + 1);
            },
            // An unresolved image contributes no clip geometry.  Other clip
            // children remain usable, while unsupported graphical effects keep
            // their explicit failure boundary below.
            .image => {},
            .filter, .mask, .pattern => return error.UnsupportedFeature,
            .script, .style, .foreign_object, .text, .text_node => {},
            else => {
                var child = node.first_child;
                while (child != none) {
                    try self.buildClipGeometry(child, matrix, output, depth + 1, use_depth);
                    child = self.document.nodes[child].next_sibling;
                }
            },
        }
    }

    fn renderText(self: *Renderer, node_index: u16, style: Style, matrix: Matrix, clips: []const *const Geometry) Error!void {
        const provider = self.options.glyphs orelse return;
        if (provider.row == null or provider.width == 0 or provider.height == 0 or provider.advance == 0) return;
        const fill = switch (style.fill) {
            .none => return,
            .color => |color| color,
        };
        var text_buffer: [2048]u8 = undefined;
        const text = collectText(self.document, node_index, text_buffer[0..]);
        if (text.len == 0) return;
        const x = parseLength(self.document.attribute(node_index, "x"), 0) catch 0;
        const y = parseLength(self.document.attribute(node_index, "y"), 0) catch 0;
        const scale = @max(0.01, style.font_size / @as(f32, @floatFromInt(provider.height)));
        const glyph_count = utf8ScalarCount(text);
        const total_width = @as(f32, @floatFromInt(glyph_count * provider.advance)) * scale;
        var cursor_x = x - switch (style.text_anchor) {
            .start => 0,
            .middle => total_width * 0.5,
            .end => total_width,
        };
        if (self.active_link != none and self.options.links != null) {
            var link_geometry = Geometry{ .allocator = self.allocator };
            defer link_geometry.deinit();
            try appendRect(
                &link_geometry,
                cursor_x,
                y - @as(f32, @floatFromInt(provider.baseline)) * scale,
                total_width,
                @as(f32, @floatFromInt(provider.height)) * scale,
                0,
                0,
            );
            try link_geometry.finalize();
            link_geometry.transform(matrix);
            self.recordLink(&link_geometry, clips, 0);
        }
        var offset: usize = 0;
        while (offset < text.len) {
            const decoded = decodeUtf8(text, offset);
            offset += decoded.consumed;
            var row: u32 = 0;
            while (row < provider.height) : (row += 1) {
                const bits = provider.bits(decoded.codepoint, row);
                var column: u32 = 0;
                while (column < provider.width) : (column += 1) {
                    if ((bits & (@as(u64, 1) << @intCast(column))) == 0) continue;
                    var geometry = Geometry{ .allocator = self.allocator };
                    defer geometry.deinit();
                    const left = cursor_x + @as(f32, @floatFromInt(column)) * scale;
                    const top = y - @as(f32, @floatFromInt(provider.baseline)) * scale + @as(f32, @floatFromInt(row)) * scale;
                    try appendRect(&geometry, left, top, scale, scale, 0, 0);
                    try geometry.finalize();
                    geometry.transform(matrix);
                    self.paintFill(&geometry, clips, fill, style.opacity * style.fill_opacity, .nonzero);
                }
            }
            cursor_x += @as(f32, @floatFromInt(provider.advance)) * scale;
        }
    }

    fn recordLink(self: *Renderer, geometry: *const Geometry, clips: []const *const Geometry, padding: i32) void {
        if (self.active_link == none) return;
        const sink = self.options.links orelse return;
        var bounds = pixelBounds(geometry.bounds, self.width, self.height, padding);
        for (clips) |clip| {
            const clip_bounds = pixelBounds(clip.bounds, self.width, self.height, 0);
            bounds.left = @max(bounds.left, clip_bounds.left);
            bounds.top = @max(bounds.top, clip_bounds.top);
            bounds.right = @min(bounds.right, clip_bounds.right);
            bounds.bottom = @min(bounds.bottom, clip_bounds.bottom);
        }
        sink.add(
            self.active_link,
            bounds.left,
            bounds.top,
            bounds.right - bounds.left,
            bounds.bottom - bounds.top,
        );
    }

    fn paintFill(self: *Renderer, geometry: *const Geometry, clips: []const *const Geometry, color: u32, opacity: f32, rule: FillRule) void {
        if (opacity <= 0) return;
        const bounds = pixelBounds(geometry.bounds, self.width, self.height, 1);
        if (bounds.right <= bounds.left or bounds.bottom <= bounds.top) return;
        var y = bounds.top;
        while (y < bounds.bottom) : (y += 1) {
            var x = bounds.left;
            while (x < bounds.right) : (x += 1) {
                var covered: u32 = 0;
                for (sample_offsets) |sample| {
                    const point = Point{ .x = @as(f32, @floatFromInt(x)) + sample.x, .y = @as(f32, @floatFromInt(y)) + sample.y };
                    if (insideGeometry(geometry, point, rule) and insideClips(clips, point)) covered += 1;
                }
                if (covered == 0) continue;
                self.blend(@intCast(x), @intCast(y), color, opacity * @as(f32, @floatFromInt(covered)) / sample_offsets.len);
            }
        }
    }

    fn paintStroke(self: *Renderer, geometry: *const Geometry, clips: []const *const Geometry, color: u32, opacity: f32, stroke_width: f32) void {
        if (opacity <= 0 or stroke_width <= 0) return;
        const radius = stroke_width * 0.5;
        const bounds = pixelBounds(geometry.bounds, self.width, self.height, @intFromFloat(@ceil(radius + 1)));
        if (bounds.right <= bounds.left or bounds.bottom <= bounds.top) return;
        var y = bounds.top;
        while (y < bounds.bottom) : (y += 1) {
            var x = bounds.left;
            while (x < bounds.right) : (x += 1) {
                var covered: u32 = 0;
                for (sample_offsets) |sample| {
                    const point = Point{ .x = @as(f32, @floatFromInt(x)) + sample.x, .y = @as(f32, @floatFromInt(y)) + sample.y };
                    if (distanceToGeometry(geometry, point) <= radius and insideClips(clips, point)) covered += 1;
                }
                if (covered == 0) continue;
                self.blend(@intCast(x), @intCast(y), color, opacity * @as(f32, @floatFromInt(covered)) / sample_offsets.len);
            }
        }
    }

    fn blend(self: *Renderer, x: u32, y: u32, color: u32, opacity: f32) void {
        const index = @as(usize, y) * self.width + x;
        const destination = self.pixels[index];
        const source_alpha = @as(u32, @intFromFloat(@round(@as(f32, @floatFromInt((color >> 24) & 0xFF)) * std.math.clamp(opacity, 0, 1))));
        if (source_alpha == 0) return;
        const destination_alpha = (destination >> 24) & 0xFF;
        const inverse = 255 - source_alpha;
        const output_alpha = source_alpha + (destination_alpha * inverse + 127) / 255;
        if (output_alpha == 0) {
            self.pixels[index] = 0;
            return;
        }
        const source_red = (color >> 16) & 0xFF;
        const source_green = (color >> 8) & 0xFF;
        const source_blue = color & 0xFF;
        const destination_red = (destination >> 16) & 0xFF;
        const destination_green = (destination >> 8) & 0xFF;
        const destination_blue = destination & 0xFF;
        const destination_factor = (destination_alpha * inverse + 127) / 255;
        const red = (source_red * source_alpha + destination_red * destination_factor + output_alpha / 2) / output_alpha;
        const green = (source_green * source_alpha + destination_green * destination_factor + output_alpha / 2) / output_alpha;
        const blue = (source_blue * source_alpha + destination_blue * destination_factor + output_alpha / 2) / output_alpha;
        self.pixels[index] = (output_alpha << 24) | (red << 16) | (green << 8) | blue;
    }
};

fn appendGeometry(output: *Geometry, source: *const Geometry) Error!void {
    for (source.subpaths.items) |subpath| {
        const start: usize = subpath.start;
        const count: usize = subpath.count;
        if (count == 0 or start > source.points.items.len or count > source.points.items.len - start) continue;
        try output.moveTo(source.points.items[start]);
        var index: usize = 1;
        while (index < count) : (index += 1) try output.lineTo(source.points.items[start + index]);
        try output.finish(subpath.closed);
    }
}

fn functionalId(value: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, value, " \t\r\n");
    if (trimmed.len < 7 or !startsAtIgnoreCase(trimmed, 0, "url(") or trimmed[trimmed.len - 1] != ')') return null;
    var inner = std.mem.trim(u8, trimmed[4 .. trimmed.len - 1], " \t\r\n");
    if (inner.len >= 2 and ((inner[0] == '"' and inner[inner.len - 1] == '"') or (inner[0] == '\'' and inner[inner.len - 1] == '\''))) {
        inner = inner[1 .. inner.len - 1];
    }
    if (inner.len < 2 or inner[0] != '#') return null;
    return inner[1..];
}

const sample_offsets = [_]Point{
    .{ .x = 0.25, .y = 0.25 },
    .{ .x = 0.75, .y = 0.25 },
    .{ .x = 0.25, .y = 0.75 },
    .{ .x = 0.75, .y = 0.75 },
};

const PixelBounds = struct { left: i32, top: i32, right: i32, bottom: i32 };

fn pixelBounds(box: Box, width: u32, height: u32, padding: i32) PixelBounds {
    if (!std.math.isFinite(box.x) or !std.math.isFinite(box.y) or !std.math.isFinite(box.w) or !std.math.isFinite(box.h)) {
        return .{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    }
    const max_width: i32 = @intCast(width);
    const max_height: i32 = @intCast(height);
    return .{
        .left = std.math.clamp(@as(i32, @intFromFloat(@floor(box.x))) - padding, 0, max_width),
        .top = std.math.clamp(@as(i32, @intFromFloat(@floor(box.y))) - padding, 0, max_height),
        .right = std.math.clamp(@as(i32, @intFromFloat(@ceil(box.w))) + padding, 0, max_width),
        .bottom = std.math.clamp(@as(i32, @intFromFloat(@ceil(box.h))) + padding, 0, max_height),
    };
}

fn insideGeometry(geometry: *const Geometry, point: Point, rule: FillRule) bool {
    var winding: i32 = 0;
    var crossings: u32 = 0;
    for (geometry.subpaths.items) |subpath| {
        const start: usize = subpath.start;
        const count: usize = subpath.count;
        if (count < 2 or start > geometry.points.items.len or count > geometry.points.items.len - start) continue;
        var index: usize = 0;
        while (index < count) : (index += 1) {
            const first = geometry.points.items[start + index];
            const second = geometry.points.items[start + ((index + 1) % count)];
            if ((first.y <= point.y and second.y > point.y) or (first.y > point.y and second.y <= point.y)) {
                const intersection = first.x + (point.y - first.y) * (second.x - first.x) / (second.y - first.y);
                if (intersection > point.x) {
                    crossings += 1;
                    winding += if (second.y > first.y) 1 else -1;
                }
            }
        }
    }
    return if (rule == .evenodd) (crossings & 1) != 0 else winding != 0;
}

fn insideClips(clips: []const *const Geometry, point: Point) bool {
    for (clips) |clip| if (!insideGeometry(clip, point, .nonzero)) return false;
    return true;
}

fn distanceToGeometry(geometry: *const Geometry, point: Point) f32 {
    var best = std.math.inf(f32);
    for (geometry.subpaths.items) |subpath| {
        const start: usize = subpath.start;
        const count: usize = subpath.count;
        if (count < 2 or start > geometry.points.items.len or count > geometry.points.items.len - start) continue;
        const edge_count = if (subpath.closed) count else count - 1;
        var index: usize = 0;
        while (index < edge_count) : (index += 1) {
            const first = geometry.points.items[start + index];
            const second = geometry.points.items[start + ((index + 1) % count)];
            best = @min(best, distanceToSegment(point, first, second));
        }
    }
    return best;
}

fn distanceToSegment(point: Point, first: Point, second: Point) f32 {
    const dx = second.x - first.x;
    const dy = second.y - first.y;
    const length_squared = dx * dx + dy * dy;
    if (length_squared <= 0.000001) {
        const px = point.x - first.x;
        const py = point.y - first.y;
        return @sqrt(px * px + py * py);
    }
    const factor = std.math.clamp(((point.x - first.x) * dx + (point.y - first.y) * dy) / length_squared, 0, 1);
    const px = point.x - (first.x + factor * dx);
    const py = point.y - (first.y + factor * dy);
    return @sqrt(px * px + py * py);
}

fn buildGeometry(document: *const Document, node_index: u16, geometry: *Geometry) Error!void {
    const node = document.nodes[node_index];
    switch (node.tag) {
        .path => try parsePath(document.attribute(node_index, "d") orelse "", geometry),
        .rect => try appendRect(
            geometry,
            parseLength(document.attribute(node_index, "x"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "y"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "width"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "height"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "rx"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "ry"), 0) catch return error.InvalidNumber,
        ),
        .circle => {
            const radius = parseLength(document.attribute(node_index, "r"), 0) catch return error.InvalidNumber;
            try appendEllipse(
                geometry,
                parseLength(document.attribute(node_index, "cx"), 0) catch return error.InvalidNumber,
                parseLength(document.attribute(node_index, "cy"), 0) catch return error.InvalidNumber,
                radius,
                radius,
            );
        },
        .ellipse => try appendEllipse(
            geometry,
            parseLength(document.attribute(node_index, "cx"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "cy"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "rx"), 0) catch return error.InvalidNumber,
            parseLength(document.attribute(node_index, "ry"), 0) catch return error.InvalidNumber,
        ),
        .line => {
            try geometry.moveTo(.{
                .x = parseLength(document.attribute(node_index, "x1"), 0) catch return error.InvalidNumber,
                .y = parseLength(document.attribute(node_index, "y1"), 0) catch return error.InvalidNumber,
            });
            try geometry.lineTo(.{
                .x = parseLength(document.attribute(node_index, "x2"), 0) catch return error.InvalidNumber,
                .y = parseLength(document.attribute(node_index, "y2"), 0) catch return error.InvalidNumber,
            });
        },
        .polyline, .polygon => try parsePoints(document.attribute(node_index, "points") orelse "", geometry, node.tag == .polygon),
        else => {},
    }
}

fn appendRect(geometry: *Geometry, x: f32, y: f32, width: f32, height: f32, rx_input: f32, ry_input: f32) Error!void {
    if (!(width > 0) or !(height > 0)) return;
    var rx = @max(0, rx_input);
    var ry = @max(0, ry_input);
    if (rx == 0 and ry > 0) rx = ry;
    if (ry == 0 and rx > 0) ry = rx;
    rx = @min(rx, width * 0.5);
    ry = @min(ry, height * 0.5);
    if (rx == 0 or ry == 0) {
        try geometry.moveTo(.{ .x = x, .y = y });
        try geometry.lineTo(.{ .x = x + width, .y = y });
        try geometry.lineTo(.{ .x = x + width, .y = y + height });
        try geometry.lineTo(.{ .x = x, .y = y + height });
        try geometry.finish(true);
        return;
    }
    const k: f32 = 0.55228475;
    try geometry.moveTo(.{ .x = x + rx, .y = y });
    try geometry.lineTo(.{ .x = x + width - rx, .y = y });
    try flattenCubic(geometry, .{ .x = x + width - rx + rx * k, .y = y }, .{ .x = x + width, .y = y + ry - ry * k }, .{ .x = x + width, .y = y + ry });
    try geometry.lineTo(.{ .x = x + width, .y = y + height - ry });
    try flattenCubic(geometry, .{ .x = x + width, .y = y + height - ry + ry * k }, .{ .x = x + width - rx + rx * k, .y = y + height }, .{ .x = x + width - rx, .y = y + height });
    try geometry.lineTo(.{ .x = x + rx, .y = y + height });
    try flattenCubic(geometry, .{ .x = x + rx - rx * k, .y = y + height }, .{ .x = x, .y = y + height - ry + ry * k }, .{ .x = x, .y = y + height - ry });
    try geometry.lineTo(.{ .x = x, .y = y + ry });
    try flattenCubic(geometry, .{ .x = x, .y = y + ry - ry * k }, .{ .x = x + rx - rx * k, .y = y }, .{ .x = x + rx, .y = y });
    try geometry.finish(true);
}

fn appendEllipse(geometry: *Geometry, center_x: f32, center_y: f32, radius_x: f32, radius_y: f32) Error!void {
    if (!(radius_x > 0) or !(radius_y > 0)) return;
    const segments: usize = 32;
    var index: usize = 0;
    while (index < segments) : (index += 1) {
        const angle = @as(f32, @floatFromInt(index)) * 2 * std.math.pi / @as(f32, @floatFromInt(segments));
        const point = Point{ .x = center_x + std.math.cos(angle) * radius_x, .y = center_y + std.math.sin(angle) * radius_y };
        if (index == 0) try geometry.moveTo(point) else try geometry.lineTo(point);
    }
    try geometry.finish(true);
}

fn parsePoints(value: []const u8, geometry: *Geometry, closed: bool) Error!void {
    var cursor: usize = 0;
    var first = true;
    while (true) {
        const x = parseNumber(value, &cursor) catch |err| switch (err) {
            error.InvalidNumber => if (first) return else break,
            else => return err,
        };
        const y = try parseNumber(value, &cursor);
        if (first) {
            try geometry.moveTo(.{ .x = x, .y = y });
            first = false;
        } else {
            try geometry.lineTo(.{ .x = x, .y = y });
        }
    }
    try geometry.finish(closed);
}

fn parsePath(value: []const u8, geometry: *Geometry) Error!void {
    var parser = PathParser{ .value = value, .geometry = geometry };
    try parser.parse();
}

const PathParser = struct {
    value: []const u8,
    cursor: usize = 0,
    command: u8 = 0,
    current: Point = .{},
    start: Point = .{},
    cubic_control: Point = .{},
    quadratic_control: Point = .{},
    previous_command: u8 = 0,
    geometry: *Geometry,

    fn parse(self: *PathParser) Error!void {
        while (true) {
            skipNumberSeparators(self.value, &self.cursor);
            if (self.cursor >= self.value.len) break;
            if (isPathCommand(self.value[self.cursor])) {
                self.command = self.value[self.cursor];
                self.cursor += 1;
            } else if (self.command == 0) {
                return error.InvalidNumber;
            }
            const relative = self.command >= 'a' and self.command <= 'z';
            const upper = std.ascii.toUpper(self.command);
            switch (upper) {
                'M' => {
                    var first = true;
                    while (self.hasNumber()) {
                        var next_point = try self.point();
                        if (relative) next_point = addPoint(next_point, self.current);
                        if (first) {
                            try self.geometry.moveTo(next_point);
                            self.start = next_point;
                            first = false;
                        } else {
                            try self.geometry.lineTo(next_point);
                        }
                        self.current = next_point;
                        self.resetControls();
                    }
                    if (first) return error.InvalidNumber;
                    self.command = if (relative) 'l' else 'L';
                },
                'L' => {
                    var found = false;
                    while (self.hasNumber()) {
                        var next_point = try self.point();
                        if (relative) next_point = addPoint(next_point, self.current);
                        try self.geometry.lineTo(next_point);
                        self.current = next_point;
                        self.resetControls();
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'H' => {
                    var found = false;
                    while (self.hasNumber()) {
                        const number = try parseNumber(self.value, &self.cursor);
                        self.current.x = if (relative) self.current.x + number else number;
                        try self.geometry.lineTo(self.current);
                        self.resetControls();
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'V' => {
                    var found = false;
                    while (self.hasNumber()) {
                        const number = try parseNumber(self.value, &self.cursor);
                        self.current.y = if (relative) self.current.y + number else number;
                        try self.geometry.lineTo(self.current);
                        self.resetControls();
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'C' => {
                    var found = false;
                    while (self.hasNumber()) {
                        var first = try self.point();
                        var second = try self.point();
                        var end = try self.point();
                        if (relative) {
                            first = addPoint(first, self.current);
                            second = addPoint(second, self.current);
                            end = addPoint(end, self.current);
                        }
                        try flattenCubic(self.geometry, first, second, end);
                        self.current = end;
                        self.cubic_control = second;
                        self.quadratic_control = end;
                        self.previous_command = 'C';
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'S' => {
                    var found = false;
                    while (self.hasNumber()) {
                        const first = if (self.previous_command == 'C' or self.previous_command == 'S') reflect(self.cubic_control, self.current) else self.current;
                        var second = try self.point();
                        var end = try self.point();
                        if (relative) {
                            second = addPoint(second, self.current);
                            end = addPoint(end, self.current);
                        }
                        try flattenCubic(self.geometry, first, second, end);
                        self.current = end;
                        self.cubic_control = second;
                        self.quadratic_control = end;
                        self.previous_command = 'S';
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'Q' => {
                    var found = false;
                    while (self.hasNumber()) {
                        var control = try self.point();
                        var end = try self.point();
                        if (relative) {
                            control = addPoint(control, self.current);
                            end = addPoint(end, self.current);
                        }
                        try flattenQuadratic(self.geometry, control, end);
                        self.current = end;
                        self.quadratic_control = control;
                        self.cubic_control = end;
                        self.previous_command = 'Q';
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'T' => {
                    var found = false;
                    while (self.hasNumber()) {
                        const control = if (self.previous_command == 'Q' or self.previous_command == 'T') reflect(self.quadratic_control, self.current) else self.current;
                        var end = try self.point();
                        if (relative) end = addPoint(end, self.current);
                        try flattenQuadratic(self.geometry, control, end);
                        self.current = end;
                        self.quadratic_control = control;
                        self.cubic_control = end;
                        self.previous_command = 'T';
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'A' => {
                    var found = false;
                    while (self.hasNumber()) {
                        const radius_x = try parseNumber(self.value, &self.cursor);
                        const radius_y = try parseNumber(self.value, &self.cursor);
                        const rotation = try parseNumber(self.value, &self.cursor);
                        const large = try parseFlag(self.value, &self.cursor);
                        const sweep = try parseFlag(self.value, &self.cursor);
                        var end = try self.point();
                        if (relative) end = addPoint(end, self.current);
                        try flattenArc(self.geometry, self.current, end, radius_x, radius_y, rotation, large, sweep);
                        self.current = end;
                        self.resetControls();
                        self.previous_command = 'A';
                        found = true;
                    }
                    if (!found) return error.InvalidNumber;
                },
                'Z' => {
                    try self.geometry.finish(true);
                    self.current = self.start;
                    self.resetControls();
                    self.previous_command = 'Z';
                    self.command = 0;
                },
                else => return error.UnsupportedFeature,
            }
        }
        try self.geometry.finalize();
    }

    fn hasNumber(self: *PathParser) bool {
        var cursor = self.cursor;
        skipNumberSeparators(self.value, &cursor);
        if (cursor >= self.value.len or isPathCommand(self.value[cursor])) return false;
        return self.value[cursor] == '+' or self.value[cursor] == '-' or self.value[cursor] == '.' or std.ascii.isDigit(self.value[cursor]);
    }

    fn point(self: *PathParser) Error!Point {
        return .{ .x = try parseNumber(self.value, &self.cursor), .y = try parseNumber(self.value, &self.cursor) };
    }

    fn resetControls(self: *PathParser) void {
        self.cubic_control = self.current;
        self.quadratic_control = self.current;
        self.previous_command = std.ascii.toUpper(self.command);
    }
};

fn flattenCubic(geometry: *Geometry, first: Point, second: Point, end: Point) Error!void {
    if (geometry.points.items.len == 0) {
        try geometry.moveTo(end);
        return;
    }
    const start = geometry.points.items[geometry.points.items.len - 1];
    const segments = curveSegments(start, first, second, end);
    var index: usize = 1;
    while (index <= segments) : (index += 1) {
        const t = @as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(segments));
        const inverse = 1 - t;
        try geometry.lineTo(.{
            .x = inverse * inverse * inverse * start.x + 3 * inverse * inverse * t * first.x + 3 * inverse * t * t * second.x + t * t * t * end.x,
            .y = inverse * inverse * inverse * start.y + 3 * inverse * inverse * t * first.y + 3 * inverse * t * t * second.y + t * t * t * end.y,
        });
    }
}

fn flattenQuadratic(geometry: *Geometry, control: Point, end: Point) Error!void {
    if (geometry.points.items.len == 0) {
        try geometry.moveTo(end);
        return;
    }
    const start = geometry.points.items[geometry.points.items.len - 1];
    const control_distance = distanceToSegment(control, start, end);
    const segments: usize = @intFromFloat(std.math.clamp(@ceil(@sqrt(@max(1, control_distance)) * 2), 4, 32));
    var index: usize = 1;
    while (index <= segments) : (index += 1) {
        const t = @as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(segments));
        const inverse = 1 - t;
        try geometry.lineTo(.{
            .x = inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            .y = inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y,
        });
    }
}

fn curveSegments(start: Point, first: Point, second: Point, end: Point) usize {
    const chord = distance(start, end);
    const control = distance(start, first) + distance(first, second) + distance(second, end);
    return @intFromFloat(std.math.clamp(@ceil(@sqrt(@max(1, control - chord)) * 3), 6, 48));
}

fn flattenArc(geometry: *Geometry, start: Point, end: Point, rx_input: f32, ry_input: f32, rotation_degrees: f32, large: bool, sweep: bool) Error!void {
    var rx = @abs(rx_input);
    var ry = @abs(ry_input);
    if (rx == 0 or ry == 0 or (start.x == end.x and start.y == end.y)) {
        try geometry.lineTo(end);
        return;
    }
    const phi = rotation_degrees * std.math.pi / 180;
    const cosine = std.math.cos(phi);
    const sine = std.math.sin(phi);
    const half_x = (start.x - end.x) * 0.5;
    const half_y = (start.y - end.y) * 0.5;
    const transformed_x = cosine * half_x + sine * half_y;
    const transformed_y = -sine * half_x + cosine * half_y;
    const scale = transformed_x * transformed_x / (rx * rx) + transformed_y * transformed_y / (ry * ry);
    if (scale > 1) {
        const factor = @sqrt(scale);
        rx *= factor;
        ry *= factor;
    }
    const numerator = @max(0, rx * rx * ry * ry - rx * rx * transformed_y * transformed_y - ry * ry * transformed_x * transformed_x);
    const denominator = rx * rx * transformed_y * transformed_y + ry * ry * transformed_x * transformed_x;
    const sign: f32 = if (large == sweep) -1 else 1;
    const coefficient = if (denominator <= 0) 0 else sign * @sqrt(numerator / denominator);
    const center_x_prime = coefficient * (rx * transformed_y / ry);
    const center_y_prime = coefficient * (-ry * transformed_x / rx);
    const center = Point{
        .x = cosine * center_x_prime - sine * center_y_prime + (start.x + end.x) * 0.5,
        .y = sine * center_x_prime + cosine * center_y_prime + (start.y + end.y) * 0.5,
    };
    const ux = (transformed_x - center_x_prime) / rx;
    const uy = (transformed_y - center_y_prime) / ry;
    const vx = (-transformed_x - center_x_prime) / rx;
    const vy = (-transformed_y - center_y_prime) / ry;
    const start_angle = std.math.atan2(uy, ux);
    var delta = vectorAngle(ux, uy, vx, vy);
    if (!sweep and delta > 0) delta -= 2 * std.math.pi;
    if (sweep and delta < 0) delta += 2 * std.math.pi;
    const segments: usize = @intFromFloat(std.math.clamp(@ceil(@abs(delta) * @max(rx, ry) / 6), 4, 64));
    var index: usize = 1;
    while (index <= segments) : (index += 1) {
        const angle = start_angle + delta * @as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(segments));
        const x = rx * std.math.cos(angle);
        const y = ry * std.math.sin(angle);
        try geometry.lineTo(.{
            .x = center.x + cosine * x - sine * y,
            .y = center.y + sine * x + cosine * y,
        });
    }
}

fn vectorAngle(ux: f32, uy: f32, vx: f32, vy: f32) f32 {
    return std.math.atan2(ux * vy - uy * vx, ux * vx + uy * vy);
}

fn distance(first: Point, second: Point) f32 {
    const dx = second.x - first.x;
    const dy = second.y - first.y;
    return @sqrt(dx * dx + dy * dy);
}

fn reflect(control: Point, around: Point) Point {
    return .{ .x = around.x * 2 - control.x, .y = around.y * 2 - control.y };
}

fn addPoint(first: Point, second: Point) Point {
    return .{ .x = first.x + second.x, .y = first.y + second.y };
}

fn parseFlag(value: []const u8, cursor: *usize) Error!bool {
    skipNumberSeparators(value, cursor);
    if (cursor.* >= value.len or (value[cursor.*] != '0' and value[cursor.*] != '1')) return error.InvalidNumber;
    const result = value[cursor.*] == '1';
    cursor.* += 1;
    return result;
}

fn parseTransform(value: ?[]const u8) Error!Matrix {
    const input = value orelse return .{};
    var cursor: usize = 0;
    var result = Matrix{};
    while (true) {
        skipSpaceAndComma(input, &cursor);
        if (cursor >= input.len) break;
        const name_start = cursor;
        while (cursor < input.len and std.ascii.isAlphabetic(input[cursor])) cursor += 1;
        if (cursor == name_start) return error.InvalidNumber;
        const name = input[name_start..cursor];
        skipSpace(input, &cursor);
        if (cursor >= input.len or input[cursor] != '(') return error.InvalidNumber;
        cursor += 1;
        var values: [6]f32 = .{0} ** 6;
        var count: usize = 0;
        while (true) {
            skipSpaceAndComma(input, &cursor);
            if (cursor >= input.len) return error.InvalidNumber;
            if (input[cursor] == ')') {
                cursor += 1;
                break;
            }
            if (count >= values.len) return error.InvalidNumber;
            values[count] = try parseNumber(input, &cursor);
            count += 1;
        }
        var local = Matrix{};
        if (std.ascii.eqlIgnoreCase(name, "matrix") and count == 6) {
            local = .{ .a = values[0], .b = values[1], .c = values[2], .d = values[3], .e = values[4], .f = values[5] };
        } else if (std.ascii.eqlIgnoreCase(name, "translate") and (count == 1 or count == 2)) {
            local = .{ .e = values[0], .f = if (count == 2) values[1] else 0 };
        } else if (std.ascii.eqlIgnoreCase(name, "scale") and (count == 1 or count == 2)) {
            local = .{ .a = values[0], .d = if (count == 2) values[1] else values[0] };
        } else if (std.ascii.eqlIgnoreCase(name, "rotate") and (count == 1 or count == 3)) {
            const angle = values[0] * std.math.pi / 180;
            const rotation = Matrix{ .a = std.math.cos(angle), .b = std.math.sin(angle), .c = -std.math.sin(angle), .d = std.math.cos(angle) };
            if (count == 3) {
                local = (Matrix{ .e = values[1], .f = values[2] })
                    .multiply(rotation)
                    .multiply(.{ .e = -values[1], .f = -values[2] });
            } else {
                local = rotation;
            }
        } else if (std.ascii.eqlIgnoreCase(name, "skewX") and count == 1) {
            local.c = std.math.tan(values[0] * std.math.pi / 180);
        } else if (std.ascii.eqlIgnoreCase(name, "skewY") and count == 1) {
            local.b = std.math.tan(values[0] * std.math.pi / 180);
        } else {
            return error.UnsupportedFeature;
        }
        result = result.multiply(local);
    }
    return result;
}

fn applyNodeStyle(document: *const Document, node: u16, style: *Style) void {
    applyStyleProperty(style, "fill", document.attribute(node, "fill"));
    applyStyleProperty(style, "stroke", document.attribute(node, "stroke"));
    applyStyleProperty(style, "color", document.attribute(node, "color"));
    applyStyleProperty(style, "stroke-width", document.attribute(node, "stroke-width"));
    applyStyleProperty(style, "opacity", document.attribute(node, "opacity"));
    applyStyleProperty(style, "fill-opacity", document.attribute(node, "fill-opacity"));
    applyStyleProperty(style, "stroke-opacity", document.attribute(node, "stroke-opacity"));
    applyStyleProperty(style, "fill-rule", document.attribute(node, "fill-rule"));
    applyStyleProperty(style, "font-size", document.attribute(node, "font-size"));
    applyStyleProperty(style, "text-anchor", document.attribute(node, "text-anchor"));
    applyStyleProperty(style, "display", document.attribute(node, "display"));
    applyStyleProperty(style, "visibility", document.attribute(node, "visibility"));
    if (document.attribute(node, "clip-path")) |clip| style.clip = clip;
    if (document.attribute(node, "style")) |inline_style| {
        var cursor: usize = 0;
        while (cursor < inline_style.len) {
            while (cursor < inline_style.len and (std.ascii.isWhitespace(inline_style[cursor]) or inline_style[cursor] == ';')) cursor += 1;
            const name_start = cursor;
            while (cursor < inline_style.len and inline_style[cursor] != ':' and inline_style[cursor] != ';') cursor += 1;
            if (cursor >= inline_style.len or inline_style[cursor] != ':') break;
            const name = std.mem.trim(u8, inline_style[name_start..cursor], " \t\r\n");
            cursor += 1;
            const value_start = cursor;
            while (cursor < inline_style.len and inline_style[cursor] != ';') cursor += 1;
            const value = std.mem.trim(u8, inline_style[value_start..cursor], " \t\r\n");
            applyStyleProperty(style, name, value);
        }
    }
}

fn applyStyleProperty(style: *Style, name: []const u8, optional_value: ?[]const u8) void {
    const raw = optional_value orelse return;
    const value = std.mem.trim(u8, raw, " \t\r\n");
    if (std.ascii.eqlIgnoreCase(name, "fill")) {
        if (parsePaint(value, style.color)) |paint| style.fill = paint;
    } else if (std.ascii.eqlIgnoreCase(name, "stroke")) {
        if (parsePaint(value, style.color)) |paint| style.stroke = paint;
    } else if (std.ascii.eqlIgnoreCase(name, "color")) {
        if (parseColor(value)) |color| style.color = color;
    } else if (std.ascii.eqlIgnoreCase(name, "stroke-width")) {
        style.stroke_width = @max(0, parseLength(value, style.stroke_width) catch style.stroke_width);
    } else if (std.ascii.eqlIgnoreCase(name, "opacity")) {
        style.opacity *= parseOpacity(value);
    } else if (std.ascii.eqlIgnoreCase(name, "fill-opacity")) {
        style.fill_opacity = parseOpacity(value);
    } else if (std.ascii.eqlIgnoreCase(name, "stroke-opacity")) {
        style.stroke_opacity = parseOpacity(value);
    } else if (std.ascii.eqlIgnoreCase(name, "fill-rule")) {
        style.fill_rule = if (std.ascii.eqlIgnoreCase(value, "evenodd")) .evenodd else .nonzero;
    } else if (std.ascii.eqlIgnoreCase(name, "font-size")) {
        style.font_size = @max(1, parseLength(value, style.font_size) catch style.font_size);
    } else if (std.ascii.eqlIgnoreCase(name, "text-anchor")) {
        style.text_anchor = if (std.ascii.eqlIgnoreCase(value, "middle")) .middle else if (std.ascii.eqlIgnoreCase(value, "end")) .end else .start;
    } else if (std.ascii.eqlIgnoreCase(name, "display")) {
        if (std.ascii.eqlIgnoreCase(value, "none")) style.visible = false;
    } else if (std.ascii.eqlIgnoreCase(name, "visibility")) {
        if (std.ascii.eqlIgnoreCase(value, "hidden") or std.ascii.eqlIgnoreCase(value, "collapse")) style.visible = false;
    } else if (std.ascii.eqlIgnoreCase(name, "clip-path")) {
        style.clip = value;
    }
}

fn parsePaint(value: []const u8, current_color: u32) ?Paint {
    if (std.ascii.eqlIgnoreCase(value, "none")) return .none;
    if (std.ascii.eqlIgnoreCase(value, "currentColor")) return .{ .color = current_color };
    return if (parseColor(value)) |color| .{ .color = color } else null;
}

fn parseColor(value: []const u8) ?u32 {
    if (value.len >= 4 and value[0] == '#') {
        if (value.len == 4 or value.len == 5) {
            const red = hex(value[1]) orelse return null;
            const green = hex(value[2]) orelse return null;
            const blue = hex(value[3]) orelse return null;
            const alpha = if (value.len == 5) hex(value[4]) orelse return null else 0xF;
            return (@as(u32, alpha * 17) << 24) | (@as(u32, red * 17) << 16) | (@as(u32, green * 17) << 8) | blue * 17;
        }
        if (value.len == 7 or value.len == 9) {
            const red = hexPair(value[1], value[2]) orelse return null;
            const green = hexPair(value[3], value[4]) orelse return null;
            const blue = hexPair(value[5], value[6]) orelse return null;
            const alpha = if (value.len == 9) hexPair(value[7], value[8]) orelse return null else 0xFF;
            return (@as(u32, alpha) << 24) | (@as(u32, red) << 16) | (@as(u32, green) << 8) | blue;
        }
    }
    if (startsAtIgnoreCase(value, 0, "rgb(") and value[value.len - 1] == ')') {
        var cursor: usize = 4;
        const red = parseNumber(value[0 .. value.len - 1], &cursor) catch return null;
        const green = parseNumber(value[0 .. value.len - 1], &cursor) catch return null;
        const blue = parseNumber(value[0 .. value.len - 1], &cursor) catch return null;
        return 0xFF000000 |
            (@as(u32, @intFromFloat(std.math.clamp(@round(red), 0, 255))) << 16) |
            (@as(u32, @intFromFloat(std.math.clamp(@round(green), 0, 255))) << 8) |
            @as(u32, @intFromFloat(std.math.clamp(@round(blue), 0, 255)));
    }
    const named = [_]struct { name: []const u8, color: u32 }{
        .{ .name = "black", .color = 0xFF000000 },
        .{ .name = "white", .color = 0xFFFFFFFF },
        .{ .name = "red", .color = 0xFFFF0000 },
        .{ .name = "green", .color = 0xFF008000 },
        .{ .name = "blue", .color = 0xFF0000FF },
        .{ .name = "yellow", .color = 0xFFFFFF00 },
        .{ .name = "gray", .color = 0xFF808080 },
        .{ .name = "grey", .color = 0xFF808080 },
        .{ .name = "transparent", .color = 0x00000000 },
    };
    for (named) |entry| if (std.ascii.eqlIgnoreCase(value, entry.name)) return entry.color;
    return null;
}

fn parseOpacity(value: []const u8) f32 {
    if (value.len > 0 and value[value.len - 1] == '%') {
        var cursor: usize = 0;
        return std.math.clamp((parseNumber(value[0 .. value.len - 1], &cursor) catch 100) / 100, 0, 1);
    }
    var cursor: usize = 0;
    return std.math.clamp(parseNumber(value, &cursor) catch 1, 0, 1);
}

fn parseViewBox(value: ?[]const u8) Error!Box {
    const raw = value orelse return .{};
    var cursor: usize = 0;
    const box = Box{
        .x = try parseNumber(raw, &cursor),
        .y = try parseNumber(raw, &cursor),
        .w = try parseNumber(raw, &cursor),
        .h = try parseNumber(raw, &cursor),
    };
    if (!(box.w > 0) or !(box.h > 0)) return error.InvalidDimensions;
    return box;
}

fn parseLength(value: anytype, default_value: f32) Error!f32 {
    const raw: []const u8 = switch (@TypeOf(value)) {
        ?[]const u8 => value orelse return default_value,
        []const u8 => value,
        else => @compileError("unsupported SVG length input"),
    };
    const trimmed = std.mem.trim(u8, raw, " \t\r\n");
    if (trimmed.len == 0) return default_value;
    if (trimmed[trimmed.len - 1] == '%') return error.UnsupportedFeature;
    var cursor: usize = 0;
    const number = try parseNumber(trimmed, &cursor);
    const unit = std.mem.trim(u8, trimmed[cursor..], " \t\r\n");
    if (unit.len == 0 or std.ascii.eqlIgnoreCase(unit, "px")) return number;
    if (std.ascii.eqlIgnoreCase(unit, "pt")) return number * 96 / 72;
    if (std.ascii.eqlIgnoreCase(unit, "pc")) return number * 16;
    if (std.ascii.eqlIgnoreCase(unit, "in")) return number * 96;
    if (std.ascii.eqlIgnoreCase(unit, "cm")) return number * 96 / 2.54;
    if (std.ascii.eqlIgnoreCase(unit, "mm")) return number * 96 / 25.4;
    return error.UnsupportedFeature;
}

fn parseNumber(value: []const u8, cursor: *usize) Error!f32 {
    skipNumberSeparators(value, cursor);
    const start = cursor.*;
    if (cursor.* < value.len and (value[cursor.*] == '+' or value[cursor.*] == '-')) cursor.* += 1;
    var digits = false;
    while (cursor.* < value.len and std.ascii.isDigit(value[cursor.*])) : (cursor.* += 1) digits = true;
    if (cursor.* < value.len and value[cursor.*] == '.') {
        cursor.* += 1;
        while (cursor.* < value.len and std.ascii.isDigit(value[cursor.*])) : (cursor.* += 1) digits = true;
    }
    if (!digits) return error.InvalidNumber;
    if (cursor.* < value.len and (value[cursor.*] == 'e' or value[cursor.*] == 'E')) {
        const exponent_start = cursor.*;
        cursor.* += 1;
        if (cursor.* < value.len and (value[cursor.*] == '+' or value[cursor.*] == '-')) cursor.* += 1;
        var exponent_digits = false;
        while (cursor.* < value.len and std.ascii.isDigit(value[cursor.*])) : (cursor.* += 1) exponent_digits = true;
        if (!exponent_digits) cursor.* = exponent_start;
    }
    return std.fmt.parseFloat(f32, value[start..cursor.*]) catch error.InvalidNumber;
}

fn collectText(document: *const Document, node_index: u16, out: []u8) []const u8 {
    var written: usize = 0;
    var child = document.nodes[node_index].first_child;
    while (child != none and written < out.len) {
        const node = document.nodes[child];
        if (node.tag == .text_node) {
            const source = node.text.bytes(document.source);
            var cursor: usize = 0;
            while (cursor < source.len and written < out.len) {
                if (source[cursor] == '&') {
                    if (decodeEntity(source, &cursor)) |scalar| {
                        var encoded: [4]u8 = undefined;
                        const count = std.unicode.utf8Encode(scalar, &encoded) catch 0;
                        if (count > out.len - written) break;
                        @memcpy(out[written .. written + count], encoded[0..count]);
                        written += count;
                        continue;
                    }
                }
                out[written] = source[cursor];
                written += 1;
                cursor += 1;
            }
        }
        child = node.next_sibling;
    }
    return out[0..written];
}

const Decoded = struct { codepoint: u32, consumed: usize };

fn decodeUtf8(value: []const u8, offset: usize) Decoded {
    const first = value[offset];
    const length: usize = if (first < 0x80) 1 else if (first & 0xE0 == 0xC0) 2 else if (first & 0xF0 == 0xE0) 3 else if (first & 0xF8 == 0xF0) 4 else 1;
    if (length > value.len - offset) return .{ .codepoint = 0xFFFD, .consumed = 1 };
    return .{
        .codepoint = std.unicode.utf8Decode(value[offset .. offset + length]) catch 0xFFFD,
        .consumed = length,
    };
}

fn utf8ScalarCount(value: []const u8) usize {
    var count: usize = 0;
    var cursor: usize = 0;
    while (cursor < value.len) : (count += 1) cursor += decodeUtf8(value, cursor).consumed;
    return count;
}

fn decodeEntity(value: []const u8, cursor: *usize) ?u21 {
    const start = cursor.*;
    const end = std.mem.indexOfScalarPos(u8, value, start + 1, ';') orelse return null;
    if (end - start > 12) return null;
    const name = value[start + 1 .. end];
    const scalar: u21 = if (std.mem.eql(u8, name, "amp"))
        '&'
    else if (std.mem.eql(u8, name, "lt"))
        '<'
    else if (std.mem.eql(u8, name, "gt"))
        '>'
    else if (std.mem.eql(u8, name, "quot"))
        '"'
    else if (std.mem.eql(u8, name, "apos"))
        '\''
    else if (name.len > 1 and name[0] == '#') blk: {
        const number = if (name.len > 2 and (name[1] == 'x' or name[1] == 'X'))
            std.fmt.parseInt(u21, name[2..], 16) catch return null
        else
            std.fmt.parseInt(u21, name[1..], 10) catch return null;
        if (!std.unicode.utf8ValidCodepoint(number)) return null;
        break :blk number;
    } else return null;
    cursor.* = end + 1;
    return scalar;
}

fn checkedPixels(width: u32, height: u32) Error!usize {
    if (width == 0 or height == 0 or width > max_dimension or height > max_dimension) return error.InvalidDimensions;
    const count = std.math.mul(usize, width, height) catch return error.TooLarge;
    if (count > max_pixels) return error.TooLarge;
    return count;
}

fn classifyTag(name: []const u8) Tag {
    const entries = [_]struct { name: []const u8, tag: Tag }{
        .{ .name = "svg", .tag = .svg },
        .{ .name = "g", .tag = .group },
        .{ .name = "defs", .tag = .defs },
        .{ .name = "a", .tag = .link },
        .{ .name = "use", .tag = .use },
        .{ .name = "symbol", .tag = .symbol },
        .{ .name = "clipPath", .tag = .clip_path },
        .{ .name = "path", .tag = .path },
        .{ .name = "rect", .tag = .rect },
        .{ .name = "circle", .tag = .circle },
        .{ .name = "ellipse", .tag = .ellipse },
        .{ .name = "line", .tag = .line },
        .{ .name = "polyline", .tag = .polyline },
        .{ .name = "polygon", .tag = .polygon },
        .{ .name = "text", .tag = .text },
        .{ .name = "image", .tag = .image },
        .{ .name = "filter", .tag = .filter },
        .{ .name = "mask", .tag = .mask },
        .{ .name = "pattern", .tag = .pattern },
        .{ .name = "script", .tag = .script },
        .{ .name = "style", .tag = .style },
        .{ .name = "foreignObject", .tag = .foreign_object },
    };
    for (entries) |entry| if (std.ascii.eqlIgnoreCase(name, entry.name)) return entry.tag;
    return .unknown;
}

fn makeRef(offset: usize, length: usize) Ref {
    return .{ .offset = @intCast(offset), .len = @intCast(length) };
}

fn startsAt(value: []const u8, offset: usize, wanted: []const u8) bool {
    return offset <= value.len and wanted.len <= value.len - offset and std.mem.eql(u8, value[offset .. offset + wanted.len], wanted);
}

fn startsAtIgnoreCase(value: []const u8, offset: usize, wanted: []const u8) bool {
    return offset <= value.len and wanted.len <= value.len - offset and std.ascii.eqlIgnoreCase(value[offset .. offset + wanted.len], wanted);
}

fn containsIgnoreCase(value: []const u8, wanted: []const u8) bool {
    if (wanted.len == 0) return true;
    if (wanted.len > value.len) return false;
    var index: usize = 0;
    while (index + wanted.len <= value.len) : (index += 1) {
        if (std.ascii.eqlIgnoreCase(value[index .. index + wanted.len], wanted)) return true;
    }
    return false;
}

fn containsWordIgnoreCase(value: []const u8, wanted: []const u8) bool {
    var words = std.mem.tokenizeAny(u8, value, " \t\r\n,");
    while (words.next()) |word| if (std.ascii.eqlIgnoreCase(word, wanted)) return true;
    return false;
}

fn onlyWhitespace(value: []const u8) bool {
    for (value) |byte| if (!std.ascii.isWhitespace(byte)) return false;
    return true;
}

fn isNameByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-' or byte == ':' or byte == '.';
}

fn isPathCommand(byte: u8) bool {
    return switch (std.ascii.toUpper(byte)) {
        'M', 'L', 'H', 'V', 'C', 'S', 'Q', 'T', 'A', 'Z' => true,
        else => false,
    };
}

fn skipSpace(value: []const u8, cursor: *usize) void {
    while (cursor.* < value.len and std.ascii.isWhitespace(value[cursor.*])) cursor.* += 1;
}

fn skipSpaceAndComma(value: []const u8, cursor: *usize) void {
    while (cursor.* < value.len and (std.ascii.isWhitespace(value[cursor.*]) or value[cursor.*] == ',')) cursor.* += 1;
}

fn skipNumberSeparators(value: []const u8, cursor: *usize) void {
    skipSpaceAndComma(value, cursor);
}

fn hex(byte: u8) ?u8 {
    return if (byte >= '0' and byte <= '9') byte - '0' else if (byte >= 'a' and byte <= 'f') byte - 'a' + 10 else if (byte >= 'A' and byte <= 'F') byte - 'A' + 10 else null;
}

fn hexPair(high: u8, low: u8) ?u8 {
    return (hex(high) orelse return null) * 16 + (hex(low) orelse return null);
}

fn testGlyphRow(_: ?*anyopaque, codepoint: u32, row: u32) callconv(.c) u64 {
    if (codepoint != 'A') return 0;
    const rows = [_]u8{ 0b0110, 0b1001, 0b1111, 0b1001, 0b1001 };
    return if (row < rows.len) rows[row] else 0;
}

const TestLinkCapture = struct {
    count: usize = 0,
    node: u16 = none,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,

    fn record(context: ?*anyopaque, node: u16, x: i32, y: i32, width: i32, height: i32) callconv(.c) void {
        const self: *TestLinkCapture = @ptrCast(@alignCast(context orelse return));
        self.count += 1;
        self.node = node;
        self.x = x;
        self.y = y;
        self.width = width;
        self.height = height;
    }
};

test "SVG probe uses dimensions and viewBox fallback" {
    const explicit = try probe("<svg xmlns='http://www.w3.org/2000/svg' width='32' height='16' viewBox='0 0 64 32'/>");
    try std.testing.expectEqual(@as(u32, 32), explicit.width);
    try std.testing.expectEqual(@as(u32, 16), explicit.height);
    const inferred = try probe("<?xml version='1.0'?><svg viewBox='5 7 80 40'></svg>");
    try std.testing.expectEqual(@as(u32, 80), inferred.width);
    try std.testing.expectEqual(@as(u32, 40), inferred.height);
}

test "SVG renders shapes paths transforms strokes and alpha" {
    const source =
        "<svg width='32' height='24' viewBox='0 0 32 24'>" ++
        "<rect width='32' height='24' fill='#fff'/>" ++
        "<g transform='translate(2 2)'><path d='M0 0h10v10h-10z' fill='#f00'/>" ++
        "<circle cx='18' cy='7' r='5' fill='blue' opacity='.5'/></g>" ++
        "<line x1='1' y1='20' x2='30' y2='20' stroke='#00ff00' stroke-width='2'/>" ++
        "</svg>";
    var pixels: [32 * 24]u32 = undefined;
    var scratch: [256 * 1024]u8 = undefined;
    try render(source, pixels[0..], 32, 24, scratch[0..], .{});
    try std.testing.expectEqual(@as(u32, 0xFFFF0000), pixels[3 * 32 + 3]);
    try std.testing.expect(((pixels[9 * 32 + 20] >> 24) & 0xFF) > 0);
    try std.testing.expect(((pixels[20 * 32 + 10] >> 8) & 0xFF) > 200);
}

test "SVG keeps vector siblings when an external image is unavailable" {
    const source =
        "<svg width='16' height='8'>" ++
        "<rect x='0' y='0' width='6' height='8' fill='#ff0000'/>" ++
        "<image x='0' y='0' width='16' height='8' href='https://example.invalid/missing.png'/>" ++
        "<path d='M10 0h6v8h-6z' fill='#00ff00'/>" ++
        "</svg>";
    var pixels: [16 * 8]u32 = undefined;
    var scratch: [128 * 1024]u8 = undefined;
    try render(source, pixels[0..], 16, 8, scratch[0..], .{});
    try std.testing.expectEqual(@as(u32, 0xFFFF0000), pixels[4 * 16 + 2]);
    try std.testing.expectEqual(@as(u32, 0xFF00FF00), pixels[4 * 16 + 12]);
    try std.testing.expectEqual(@as(u32, 0), pixels[4 * 16 + 8]);
}

test "SVG with only an unavailable image remains transparent" {
    const source =
        "<svg width='8' height='6'>" ++
        "<image width='8' height='6' xlink:href='unsupported-resource.bin'/>" ++
        "</svg>";
    var pixels: [8 * 6]u32 = undefined;
    @memset(pixels[0..], 0xFFFFFFFF);
    var scratch: [128 * 1024]u8 = undefined;
    try render(source, pixels[0..], 8, 6, scratch[0..], .{});
    for (pixels) |pixel| try std.testing.expectEqual(@as(u32, 0), pixel);
}

test "SVG keeps unsupported graphical effect boundaries explicit" {
    var pixels: [8 * 6]u32 = undefined;
    var scratch: [128 * 1024]u8 = undefined;
    try std.testing.expectError(error.UnsupportedFeature, render(
        "<svg width='8' height='6'><filter/></svg>",
        pixels[0..],
        8,
        6,
        scratch[0..],
        .{},
    ));
    try std.testing.expectError(error.UnsupportedFeature, render(
        "<svg width='8' height='6'><mask/></svg>",
        pixels[0..],
        8,
        6,
        scratch[0..],
        .{},
    ));
    try std.testing.expectError(error.UnsupportedFeature, render(
        "<svg width='8' height='6'><pattern/></svg>",
        pixels[0..],
        8,
        6,
        scratch[0..],
        .{},
    ));
}

test "SVG renders caller supplied font glyphs" {
    const source = "<svg width='16' height='12'><text x='2' y='8' font-size='5' fill='black'>A</text></svg>";
    var pixels: [16 * 12]u32 = undefined;
    var scratch: [128 * 1024]u8 = undefined;
    try render(source, pixels[0..], 16, 12, scratch[0..], .{
        .glyphs = .{ .width = 4, .height = 5, .advance = 5, .baseline = 4, .row = testGlyphRow },
    });
    var painted: usize = 0;
    for (pixels) |pixel| if ((pixel >> 24) != 0) {
        painted += 1;
    };
    try std.testing.expect(painted >= 10);
}

test "SVG applies bounded user-space clip paths" {
    const source =
        "<svg width='16' height='16'><defs><clipPath id='left'><rect width='8' height='16'/></clipPath></defs>" ++
        "<rect width='16' height='16' fill='red' clip-path='url(#left)'/></svg>";
    var pixels: [16 * 16]u32 = undefined;
    var scratch: [128 * 1024]u8 = undefined;
    try render(source, pixels[0..], 16, 16, scratch[0..], .{});
    try std.testing.expectEqual(@as(u32, 0xFFFF0000), pixels[8 * 16 + 3]);
    try std.testing.expectEqual(@as(u32, 0), pixels[8 * 16 + 12]);
}

test "SVG reports transformed inline link regions" {
    const source =
        "<svg width='32' height='16'><a data-r4-node='23'>" ++
        "<rect x='2' y='2' width='8' height='6' transform='translate(3 1)' fill='blue'/>" ++
        "</a></svg>";
    var pixels: [32 * 16]u32 = undefined;
    var scratch: [128 * 1024]u8 = undefined;
    var capture = TestLinkCapture{};
    try render(source, pixels[0..], 32, 16, scratch[0..], .{
        .links = .{ .context = &capture, .record = TestLinkCapture.record },
    });
    try std.testing.expectEqual(@as(usize, 1), capture.count);
    try std.testing.expectEqual(@as(u16, 23), capture.node);
    try std.testing.expectEqual(@as(i32, 5), capture.x);
    try std.testing.expectEqual(@as(i32, 3), capture.y);
    try std.testing.expectEqual(@as(i32, 8), capture.width);
    try std.testing.expectEqual(@as(i32, 6), capture.height);
}

test "SVG rejects external entities deep trees and oversized dimensions" {
    try std.testing.expectError(error.UnsupportedFeature, probe("<!ENTITY x SYSTEM 'file'><svg/>"));
    try std.testing.expectError(error.InvalidDimensions, probe("<svg width='99999' height='1'/>"));
    var deep: [1024]u8 = undefined;
    var length: usize = 0;
    @memcpy(deep[length .. length + 5], "<svg>");
    length += 5;
    for (0..max_depth) |_| {
        @memcpy(deep[length .. length + 3], "<g>");
        length += 3;
    }
    try std.testing.expectError(error.DepthLimit, probe(deep[0..length]));
}
