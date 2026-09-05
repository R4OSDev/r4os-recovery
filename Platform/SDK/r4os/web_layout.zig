const std = @import("std");
const html = @import("html.zig");
const css = @import("css.zig");

pub const max_render_ops: usize = 3072;
pub const max_text_bytes: usize = 48 * 1024;
pub const max_layout_depth: usize = 96;
const max_control_text_bytes: usize = 512;

pub const Error = error{
    RenderLimit,
    TextLimit,
    DepthLimit,
};

pub const Rect = struct {
    x: i32 = 0,
    y: i32 = 0,
    w: i32 = 0,
    h: i32 = 0,

    pub fn right(self: Rect) i32 {
        return self.x + self.w;
    }

    pub fn bottom(self: Rect) i32 {
        return self.y + self.h;
    }

    pub fn intersects(self: Rect, other: Rect) bool {
        return self.w > 0 and self.h > 0 and other.w > 0 and other.h > 0 and
            self.x < other.right() and self.right() > other.x and self.y < other.bottom() and self.bottom() > other.y;
    }
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

pub const RenderKind = enum(u8) {
    background,
    css_background,
    border,
    image,
    text,
    canvas,
    shadow,
    control,
};

pub const PixelEdges = struct {
    top: i32 = 0,
    right: i32 = 0,
    bottom: i32 = 0,
    left: i32 = 0,
};

pub const PixelRadius = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn any(self: PixelRadius) bool {
        return self.x > 0 or self.y > 0;
    }
};

pub const PixelRadii = struct {
    top_left: PixelRadius = .{},
    top_right: PixelRadius = .{},
    bottom_right: PixelRadius = .{},
    bottom_left: PixelRadius = .{},

    pub fn any(self: PixelRadii) bool {
        return self.top_left.any() or self.top_right.any() or self.bottom_right.any() or self.bottom_left.any();
    }
};

pub const ShadowVisual = struct {
    enabled: bool = false,
    inset: bool = false,
    offset_x: i32 = 0,
    offset_y: i32 = 0,
    blur: i32 = 0,
    spread: i32 = 0,
    color: u32 = 0,
    alpha: u8 = 0,
};

pub const ClipRegion = struct {
    rect: Rect = .{},
    x: bool = false,
    y: bool = false,

    pub fn enabled(self: ClipRegion) bool {
        return self.x or self.y;
    }
};

pub const ImageState = enum(u8) {
    missing,
    loading,
    ready,
    failed,
};

pub const ImageIntrinsic = struct {
    state: ImageState = .missing,
    width: u32 = 0,
    height: u32 = 0,
};

pub const ImageRole = enum(u8) {
    content,
    css_background,
};

pub const ImageResolver = struct {
    context: ?*anyopaque = null,
    resolve: ?*const fn (?*anyopaque, u16) ImageIntrinsic = null,
    resolve_role: ?*const fn (?*anyopaque, u16, ImageRole) ImageIntrinsic = null,

    pub fn intrinsic(self: ImageResolver, node: u16) ImageIntrinsic {
        return self.intrinsicForRole(node, .content);
    }

    pub fn intrinsicForRole(self: ImageResolver, node: u16, role: ImageRole) ImageIntrinsic {
        if (self.resolve_role) |callback| return callback(self.context, node, role);
        if (role != .content) return .{};
        const callback = self.resolve orelse return .{};
        return callback(self.context, node);
    }
};

pub const CssBackgroundVisual = struct {
    raw_value: []const u8 = "",
    base_url: []const u8 = "",
    repeat: css.BackgroundRepeat = .repeat,
    position: css.BackgroundPosition = .{},
    size: css.BackgroundSize = .{},
};

pub const FontFace = struct {
    id: u32 = 0,
    height: i32 = 8,
    line_height: i32 = 8,
    baseline: i32 = 7,
    max_advance: i32 = 8,
};

pub const TextMetrics = struct {
    valid: bool = false,
    width: i32 = 0,
    height: i32 = 0,
    line_height: i32 = 0,
    baseline: i32 = 0,
    visible_bytes: usize = 0,
};

pub const FontProvider = struct {
    context: ?*anyopaque = null,
    resolve: ?*const fn (?*anyopaque, []const u8, i32, u16, bool, ?u32) FontFace = null,
    measure: ?*const fn (?*anyopaque, u32, []const u8) TextMetrics = null,

    pub fn face(self: FontProvider, style: *const css.ComputedStyle, codepoint: ?u32) FontFace {
        if (self.resolve) |callback| return callback(self.context, style.font_family, style.font_size, style.font_weight, style.italic, codepoint);
        const line_height = @max(1, style.line_height);
        return .{
            .height = @max(1, style.font_size),
            .line_height = line_height,
            .baseline = @max(0, @min(line_height - 1, style.font_size - 2)),
            .max_advance = approximateCharWidth(style.font_size, style.font_weight),
        };
    }

    pub fn measureFace(self: FontProvider, face_info: FontFace, value: []const u8) TextMetrics {
        if (self.measure) |callback| {
            const result = callback(self.context, face_info.id, value);
            if (result.valid) return result;
        }
        return .{
            .valid = true,
            .width = unicodeColumns(value) * @max(1, face_info.max_advance),
            .height = @max(1, face_info.height),
            .line_height = @max(1, face_info.line_height),
            .baseline = @max(0, face_info.baseline),
            .visible_bytes = value.len,
        };
    }
};

pub const RenderOp = struct {
    kind: RenderKind = .text,
    rect: Rect = .{},
    color: u32 = 0,
    background: u32 = 0xFFFFFF,
    border_color: u32 = 0,
    border: PixelEdges = .{},
    padding: PixelEdges = .{},
    radii: PixelRadii = .{},
    shadow: ShadowVisual = .{},
    clip: ClipRegion = .{},
    node: u16 = html.none,
    image_role: ImageRole = .content,
    image_intrinsic: ImageIntrinsic = .{},
    css_background: CssBackgroundVisual = .{},
    text: StringRef = .{},
    font_family: []const u8 = "sans-serif",
    font_size: i32 = 16,
    font_weight: u16 = 400,
    italic: bool = false,
    font_id: u32 = 0,
    font_height: i32 = 8,
    font_line_height: i32 = 8,
    font_baseline: i32 = 7,
    underline: bool = false,
    text_align: css.TextAlign = .left,
    disabled: bool = false,
    fixed: bool = false,
};

pub const Viewport = struct {
    width: i32,
    height: i32,
};

pub const InteractionState = struct {
    hovered_node: u16 = html.none,
    focused_node: u16 = html.none,
    active_node: u16 = html.none,
};

pub const LayoutStats = struct {
    render_ops: usize,
    text_bytes: usize,
    content_width: i32,
    content_height: i32,
    structural_hash: u64,
};

pub const Layout = struct {
    ops: [max_render_ops]RenderOp = undefined,
    text_storage: [max_text_bytes]u8 = undefined,
    op_count: usize = 0,
    text_len: usize = 0,
    content_width: i32 = 0,
    content_height: i32 = 0,
    viewport: Viewport = .{ .width = 1, .height = 1 },
    interaction: InteractionState = .{},
    image_resolver: ImageResolver = .{},
    font_provider: FontProvider = .{},

    pub fn reset(self: *Layout, viewport: Viewport) void {
        self.op_count = 0;
        self.text_len = 0;
        self.content_width = @max(1, viewport.width);
        self.content_height = 0;
        self.viewport = .{
            .width = clamp(viewport.width, 1, 8192),
            .height = clamp(viewport.height, 1, 8192),
        };
        self.interaction = .{};
    }

    pub fn reflow(self: *Layout, document: *const html.Document, sheet: *const css.Stylesheet, viewport: Viewport) Error!LayoutStats {
        return self.reflowInteractive(document, sheet, viewport, .{});
    }

    pub fn reflowInteractive(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        viewport: Viewport,
        interaction: InteractionState,
    ) Error!LayoutStats {
        return self.reflowInteractiveWithImages(document, sheet, viewport, interaction, .{});
    }

    pub fn reflowInteractiveWithImages(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        viewport: Viewport,
        interaction: InteractionState,
        image_resolver: ImageResolver,
    ) Error!LayoutStats {
        return self.reflowInteractiveWithProviders(document, sheet, viewport, interaction, image_resolver, .{});
    }

    pub fn reflowInteractiveWithProviders(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        viewport: Viewport,
        interaction: InteractionState,
        image_resolver: ImageResolver,
        font_provider: FontProvider,
    ) Error!LayoutStats {
        self.reset(viewport);
        self.interaction = interaction;
        self.image_resolver = image_resolver;
        self.font_provider = font_provider;
        const root_style = css.ComputedStyle{ .display = .block, .font_size = 16, .line_height = 19 };
        const available = self.viewport.width;
        var y: i32 = 0;
        var child = if (document.node_count > 0) document.nodes[0].first_child else html.none;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const style = sheet.computeForViewportSize(document, child, &root_style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (style.display != .none) {
                    if (isBlockDisplay(style.display)) {
                        y = try self.layoutBlock(document, sheet, child, 0, y, available, &root_style, 0, 0xFFFFFF);
                    } else {
                        var flow = Flow.init(self, document, sheet, 0, y, available, root_style, 0xFFFFFF);
                        try flow.layoutNode(child, 0);
                        y = flow.finish();
                    }
                }
            }
            child = document.nodes[child].next_sibling;
        }
        self.content_height = @max(self.viewport.height, y);
        return self.stats();
    }

    pub fn stats(self: *const Layout) LayoutStats {
        return .{
            .render_ops = self.op_count,
            .text_bytes = self.text_len,
            .content_width = self.content_width,
            .content_height = self.content_height,
            .structural_hash = self.structuralHash(),
        };
    }

    pub fn text(self: *const Layout, op: RenderOp) []const u8 {
        return op.text.bytes(self.text_storage[0..self.text_len]);
    }

    fn lengthPixels(self: *const Layout, length: css.Length, basis: i32, em: i32, fallback: i32) i32 {
        return length.pixelsForViewport(basis, em, fallback, self.viewport.width, self.viewport.height);
    }

    pub fn measureStyledText(self: *const Layout, style: *const css.ComputedStyle, value: []const u8) TextMetrics {
        if (value.len == 0) return .{ .valid = true };
        var result = TextMetrics{ .valid = true };
        var cursor: usize = 0;
        var run_start: usize = 0;
        var current_face = self.font_provider.face(style, decodeUtf8Scalar(value, 0).codepoint);
        while (cursor < value.len) {
            const decoded = decodeUtf8Scalar(value, cursor);
            const next_face = self.font_provider.face(style, decoded.codepoint);
            if (cursor > run_start and next_face.id != current_face.id) {
                combineTextMetrics(&result, self.font_provider.measureFace(current_face, value[run_start..cursor]));
                run_start = cursor;
                current_face = next_face;
            }
            cursor += decoded.consumed;
        }
        if (run_start < value.len) combineTextMetrics(&result, self.font_provider.measureFace(current_face, value[run_start..]));
        return result;
    }

    pub fn effectiveLineHeight(self: *const Layout, style: *const css.ComputedStyle) i32 {
        if (style.line_height_value.kind != .normal) return @max(0, style.line_height);
        return @max(1, self.font_provider.face(style, null).line_height);
    }

    pub fn structuralHash(self: *const Layout) u64 {
        var hash: u64 = 14695981039346656037;
        mixInt(&hash, self.content_width);
        mixInt(&hash, self.content_height);
        var index: usize = 0;
        while (index < self.op_count) : (index += 1) {
            const op = self.ops[index];
            mixInt(&hash, @intFromEnum(op.kind));
            mixInt(&hash, op.rect.x);
            mixInt(&hash, op.rect.y);
            mixInt(&hash, op.rect.w);
            mixInt(&hash, op.rect.h);
            mixInt(&hash, op.color);
            mixInt(&hash, op.background);
            mixInt(&hash, op.border_color);
            mixInt(&hash, op.border.top);
            mixInt(&hash, op.border.right);
            mixInt(&hash, op.border.bottom);
            mixInt(&hash, op.border.left);
            mixInt(&hash, op.padding.top);
            mixInt(&hash, op.padding.right);
            mixInt(&hash, op.padding.bottom);
            mixInt(&hash, op.padding.left);
            mixInt(&hash, op.radii.top_left.x);
            mixInt(&hash, op.radii.top_left.y);
            mixInt(&hash, op.radii.top_right.x);
            mixInt(&hash, op.radii.top_right.y);
            mixInt(&hash, op.radii.bottom_right.x);
            mixInt(&hash, op.radii.bottom_right.y);
            mixInt(&hash, op.radii.bottom_left.x);
            mixInt(&hash, op.radii.bottom_left.y);
            mixInt(&hash, @intFromBool(op.shadow.enabled));
            mixInt(&hash, @intFromBool(op.shadow.inset));
            mixInt(&hash, op.shadow.offset_x);
            mixInt(&hash, op.shadow.offset_y);
            mixInt(&hash, op.shadow.blur);
            mixInt(&hash, op.shadow.spread);
            mixInt(&hash, op.shadow.color);
            mixInt(&hash, op.shadow.alpha);
            mixInt(&hash, @intFromBool(op.clip.x));
            mixInt(&hash, @intFromBool(op.clip.y));
            mixInt(&hash, op.clip.rect.x);
            mixInt(&hash, op.clip.rect.y);
            mixInt(&hash, op.clip.rect.w);
            mixInt(&hash, op.clip.rect.h);
            mixInt(&hash, op.node);
            mixInt(&hash, op.image_role);
            mixInt(&hash, op.image_intrinsic.state);
            mixInt(&hash, op.image_intrinsic.width);
            mixInt(&hash, op.image_intrinsic.height);
            mixBytes(&hash, op.css_background.raw_value);
            mixBytes(&hash, op.css_background.base_url);
            mixInt(&hash, op.css_background.repeat);
            mixCssLength(&hash, op.css_background.position.x);
            mixCssLength(&hash, op.css_background.position.y);
            mixInt(&hash, op.css_background.size.kind);
            mixCssLength(&hash, op.css_background.size.width);
            mixCssLength(&hash, op.css_background.size.height);
            mixInt(&hash, op.font_size);
            mixInt(&hash, op.font_weight);
            mixInt(&hash, op.font_id);
            mixInt(&hash, op.font_height);
            mixInt(&hash, op.font_line_height);
            mixInt(&hash, op.font_baseline);
            mixInt(&hash, @intFromEnum(op.text_align));
            mixInt(&hash, @intFromBool(op.disabled));
            mixBytes(&hash, op.font_family);
            mixBytes(&hash, self.text(op));
        }
        return hash;
    }

    fn layoutBlock(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        node_index: u16,
        containing_x: i32,
        normal_y: i32,
        available_width: i32,
        parent_style: *const css.ComputedStyle,
        depth: usize,
        inherited_background: u32,
    ) Error!i32 {
        return self.layoutBlockSized(document, sheet, node_index, containing_x, normal_y, available_width, parent_style, depth, inherited_background, null, null);
    }

    fn layoutBlockSized(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        node_index: u16,
        containing_x: i32,
        normal_y: i32,
        available_width: i32,
        parent_style: *const css.ComputedStyle,
        depth: usize,
        inherited_background: u32,
        forced_box_width: ?i32,
        forced_box_height: ?i32,
    ) Error!i32 {
        if (depth >= max_layout_depth) return error.DepthLimit;
        const style = sheet.computeForViewportSize(document, node_index, parent_style, elementState(document, node_index, self.interaction), .none, self.viewport.width, self.viewport.height);
        if (style.display == .none) return normal_y;
        if (style.display == .contents) {
            var flow = Flow.init(self, document, sheet, containing_x, normal_y, available_width, style, inherited_background);
            try flow.layoutInlineElement(node_index, style, depth + 1);
            return flow.finish();
        }
        const content_op_start = self.op_count;
        const previous_content_width = self.content_width;
        const previous_content_height = self.content_height;

        const em = style.font_size;
        const auto_margin_left = style.margin.left.kind == .auto;
        const auto_margin_right = style.margin.right.kind == .auto;
        var margin_left = if (auto_margin_left) 0 else self.lengthPixels(style.margin.left, available_width, em, 0);
        var margin_right = if (auto_margin_right) 0 else self.lengthPixels(style.margin.right, available_width, em, 0);
        const margin_top = self.lengthPixels(style.margin.top, available_width, em, 0);
        const margin_bottom = self.lengthPixels(style.margin.bottom, available_width, em, 0);
        const border_left = nonNegative(self.lengthPixels(style.border.left, available_width, em, 0));
        const border_right = nonNegative(self.lengthPixels(style.border.right, available_width, em, 0));
        const border_top = nonNegative(self.lengthPixels(style.border.top, available_width, em, 0));
        const border_bottom = nonNegative(self.lengthPixels(style.border.bottom, available_width, em, 0));
        const padding_left = nonNegative(self.lengthPixels(style.padding.left, available_width, em, 0));
        const padding_right = nonNegative(self.lengthPixels(style.padding.right, available_width, em, 0));
        const padding_top = nonNegative(self.lengthPixels(style.padding.top, available_width, em, 0));
        const padding_bottom = nonNegative(self.lengthPixels(style.padding.bottom, available_width, em, 0));
        const horizontal_chrome = border_left + border_right + padding_left + padding_right;
        const vertical_chrome = border_top + border_bottom + padding_top + padding_bottom;

        var box_width: i32 = undefined;
        if (forced_box_width) |forced| {
            box_width = @max(1, forced);
        } else {
            box_width = self.lengthPixels(
                style.width,
                available_width,
                em,
                @max(1, available_width - margin_left - margin_right),
            );
            if (style.width.kind != .auto and style.box_sizing == .content_box) box_width += horizontal_chrome;
            if (style.min_width.kind != .auto) {
                var minimum = self.lengthPixels(style.min_width, available_width, em, 0);
                if (style.box_sizing == .content_box) minimum += horizontal_chrome;
                box_width = @max(box_width, minimum);
            }
            if (style.max_width.kind != .auto) {
                var maximum = self.lengthPixels(style.max_width, available_width, em, box_width);
                if (style.box_sizing == .content_box) maximum += horizontal_chrome;
                box_width = @min(box_width, maximum);
            }
        }
        box_width = clamp(box_width, 1, @max(1, available_width - margin_left - margin_right));

        const automatic_margin_space = @max(0, available_width - box_width - margin_left - margin_right);
        if (auto_margin_left and auto_margin_right) {
            margin_left += @divTrunc(automatic_margin_space, 2);
            margin_right += automatic_margin_space - @divTrunc(automatic_margin_space, 2);
        } else if (auto_margin_left) {
            margin_left += automatic_margin_space;
        } else if (auto_margin_right) {
            margin_right += automatic_margin_space;
        }

        var box_x = containing_x + margin_left;
        var box_y = normal_y + margin_top;
        const out_of_flow = style.position == .absolute or style.position == .fixed;
        if (out_of_flow) {
            box_x = containing_x + self.lengthPixels(style.left, available_width, em, margin_left);
            box_y = self.lengthPixels(style.top, self.viewport.height, em, normal_y + margin_top);
        } else if (style.position == .relative) {
            box_x += self.lengthPixels(style.left, available_width, em, 0);
            box_y += self.lengthPixels(style.top, self.viewport.height, em, 0);
        }

        const content_x = box_x + border_left + padding_left;
        const content_y = box_y + border_top + padding_top;
        const content_width = @max(1, box_width - border_left - border_right - padding_left - padding_right);
        const background = style.background_color orelse inherited_background;
        var target_box_height = forced_box_height orelse 0;
        if (style.height.kind != .auto) {
            var requested = nonNegative(self.lengthPixels(style.height, self.viewport.height, em, 0));
            if (style.box_sizing == .content_box) requested += vertical_chrome;
            target_box_height = @max(target_box_height, requested);
        }
        if (style.min_height.kind != .auto) {
            var minimum = nonNegative(self.lengthPixels(style.min_height, self.viewport.height, em, 0));
            if (style.box_sizing == .content_box) minimum += vertical_chrome;
            target_box_height = @max(target_box_height, minimum);
        }
        if (style.max_height.kind != .auto) {
            var maximum = nonNegative(self.lengthPixels(style.max_height, self.viewport.height, em, target_box_height));
            if (style.box_sizing == .content_box) maximum += vertical_chrome;
            if (maximum > 0) target_box_height = @min(target_box_height, maximum);
        }
        const target_content_height = @max(0, target_box_height - vertical_chrome);
        var content_bottom = content_y;
        var control_buffer: [max_control_text_bytes]u8 = undefined;
        const control_text = blockControlText(document, node_index, control_buffer[0..]);
        const block_control = isFormControl(document.nodeName(node_index));

        if (block_control) {
            content_bottom = content_y + @max(self.effectiveLineHeight(&style), 16);
        } else if (isImageElement(document.nodeName(node_index))) {
            var flow = Flow.init(self, document, sheet, content_x, content_y, content_width, style, background);
            try flow.emitImage(node_index, &style);
            content_bottom = flow.finish();
        } else if (style.display == .flex and style.flex_direction == .row) {
            content_bottom = try self.layoutFlexRow(document, sheet, node_index, content_x, content_y, content_width, target_content_height, &style, depth + 1, background);
        } else if (style.display == .flex and style.flex_direction == .column) {
            content_bottom = try self.layoutFlexColumn(document, sheet, node_index, content_x, content_y, content_width, target_content_height, &style, depth + 1, background);
        } else if (style.display == .grid) {
            content_bottom = try self.layoutColumns(document, sheet, node_index, content_x, content_y, content_width, &style, depth + 1, background);
        } else {
            var flow = Flow.init(self, document, sheet, content_x, content_y, content_width, style, background);
            const before = sheet.computeForViewportSize(document, node_index, &style, elementState(document, node_index, self.interaction), .before, self.viewport.width, self.viewport.height);
            try flow.emitGeneratedContent(&before, node_index);

            var child = document.nodes[node_index].first_child;
            while (child != html.none) {
                if (document.nodes[child].kind == .element) {
                    const child_style = sheet.computeForViewportSize(document, child, &style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                    if (isBlockDisplay(child_style.display)) {
                        flow.flushLine();
                        flow.y = try self.layoutBlock(document, sheet, child, content_x, flow.y, content_width, &style, depth + 1, background);
                        flow.resetLine();
                    } else if (child_style.display != .none) {
                        try flow.layoutInlineElement(child, child_style, depth + 1);
                    }
                } else if (document.nodes[child].kind == .text) {
                    try flow.emitValue(document.nodeValue(child), &style, node_index);
                }
                child = document.nodes[child].next_sibling;
            }

            const after = sheet.computeForViewportSize(document, node_index, &style, elementState(document, node_index, self.interaction), .after, self.viewport.width, self.viewport.height);
            try flow.emitGeneratedContent(&after, node_index);
            content_bottom = flow.finish();
        }

        const content_height = @max(0, content_bottom - content_y);
        const automatic_minimum = if (style.height.kind == .auto and style.min_height.kind == .auto and forced_box_height == null) self.effectiveLineHeight(&style) else 0;
        var box_height = if (style.height.kind != .auto)
            @max(vertical_chrome, target_box_height)
        else
            @max(automatic_minimum, @max(vertical_chrome + content_height, target_box_height));
        if (style.max_height.kind != .auto) {
            var maximum = nonNegative(self.lengthPixels(style.max_height, self.viewport.height, em, box_height));
            if (style.box_sizing == .content_box) maximum += vertical_chrome;
            if (maximum > 0) box_height = @min(box_height, maximum);
        }
        const box_rect = Rect{ .x = box_x, .y = box_y, .w = box_width, .h = box_height };
        const overflow_clip = ClipRegion{
            .rect = .{
                .x = box_rect.x + border_left,
                .y = box_rect.y + border_top,
                .w = @max(0, box_rect.w - border_left - border_right),
                .h = @max(0, box_rect.h - border_top - border_bottom),
            },
            .x = style.overflow_x.clips(),
            .y = style.overflow_y.clips(),
        };
        if (overflow_clip.enabled()) {
            self.applyClip(content_op_start, self.op_count, overflow_clip);
            if (overflow_clip.x) self.content_width = previous_content_width;
            if (overflow_clip.y) self.content_height = previous_content_height;
        }
        if (style.clip_empty) {
            self.op_count = content_op_start;
            self.content_width = previous_content_width;
            self.content_height = previous_content_height;
        } else {
            if (block_control and control_text.len > 0) {
                const final_content_height = @max(1, box_height - vertical_chrome);
                const text_line_height = self.effectiveLineHeight(&style);
                const text_y = content_y + @max(0, @divTrunc(final_content_height - text_line_height, 2));
                _ = try self.addTextOp(
                    .{ .x = content_x, .y = text_y, .w = content_width, .h = @min(final_content_height, @max(text_line_height, 16)) },
                    control_text,
                    &style,
                    node_index,
                    background,
                );
            }
            if (block_control) try self.emitControlOp(box_rect, &style, node_index, style.position == .fixed, background, control_text);
            try self.emitBox(box_rect, &style, node_index, style.position == .fixed, inherited_background);
            self.content_width = @max(self.content_width, box_rect.right() + margin_right);
            self.content_height = @max(self.content_height, box_rect.bottom() + margin_bottom);
        }
        if (out_of_flow) return normal_y;
        return box_rect.bottom() + margin_bottom;
    }

    fn layoutFlexRow(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        parent: u16,
        x: i32,
        y: i32,
        width: i32,
        target_height: i32,
        style: *const css.ComputedStyle,
        depth: usize,
        background: u32,
    ) Error!i32 {
        var child_count: usize = 0;
        var base_total: i32 = 0;
        var minimum_total: i32 = 0;
        var grow_total: u32 = 0;
        var auto_margin_count: usize = 0;
        var child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (child_style.display != .none and child_style.position != .absolute and child_style.position != .fixed) {
                    child_count += 1;
                    const base = flexItemBaseWidthForViewport(self, document, sheet, child, &child_style, width, depth);
                    base_total += base;
                    minimum_total += flexItemMinimumWidthForViewport(self, document, child, &child_style, width, base, self.viewport);
                    grow_total += child_style.flex_grow;
                    if (child_style.margin.left.kind == .auto) auto_margin_count += 1;
                    if (child_style.margin.right.kind == .auto) auto_margin_count += 1;
                }
            } else if (document.nodes[child].kind == .text and hasVisibleText(document.nodeValue(child))) {
                child_count += 1;
                base_total += flexTextNaturalWidth(self, document.nodeValue(child), style);
                minimum_total += flexTextMinimumWidth(self, document.nodeValue(child), style);
            }
            child = document.nodes[child].next_sibling;
        }
        if (child_count == 0) return y;

        const gap_total = style.gap * @as(i32, @intCast(child_count - 1));
        const usable_width = @max(1, width - gap_total);
        const free_width = @max(0, usable_width - base_total);
        const auto_margin_share = if (grow_total == 0 and auto_margin_count > 0)
            @divTrunc(free_width, @as(i32, @intCast(auto_margin_count)))
        else
            0;
        const justify_free = if (grow_total == 0 and auto_margin_count == 0) free_width else 0;
        var leading: i32 = 0;
        var distributed_gap: i32 = 0;
        switch (style.justify_content) {
            .start => {},
            .end => leading = justify_free,
            .center => leading = @divTrunc(justify_free, 2),
            .space_between => if (child_count > 1) {
                distributed_gap = @divTrunc(justify_free, @as(i32, @intCast(child_count - 1)));
            },
            .space_around => {
                distributed_gap = @divTrunc(justify_free, @as(i32, @intCast(child_count)));
                leading = @divTrunc(distributed_gap, 2);
            },
            .space_evenly => {
                distributed_gap = @divTrunc(justify_free, @as(i32, @intCast(child_count + 1)));
                leading = distributed_gap;
            },
        }
        var cursor_x = x + leading;
        var row_bottom = y;
        var item_index: usize = 0;
        var distributed: i32 = 0;
        child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (child_style.display != .none) {
                    if (child_style.position == .absolute or child_style.position == .fixed) {
                        _ = try self.layoutBlock(document, sheet, child, x, y, width, style, depth, background);
                    } else {
                        if (child_style.margin.left.kind == .auto) cursor_x += auto_margin_share;
                        const base = flexItemBaseWidthForViewport(self, document, sheet, child, &child_style, width, depth);
                        const minimum = flexItemMinimumWidthForViewport(self, document, child, &child_style, width, base, self.viewport);
                        var item_width: i32 = base;
                        if (base_total > usable_width) {
                            if (minimum_total >= usable_width) {
                                item_width = @max(1, @divTrunc(minimum * usable_width, @max(1, minimum_total)));
                            } else {
                                const shrinkable_total = @max(1, base_total - minimum_total);
                                const shrinkable_space = usable_width - minimum_total;
                                item_width = minimum + @divTrunc(@max(0, base - minimum) * shrinkable_space, shrinkable_total);
                            }
                        } else if (grow_total > 0 and child_style.flex_grow > 0) {
                            item_width += @divTrunc(free_width * @as(i32, child_style.flex_grow), @as(i32, @intCast(grow_total)));
                        }
                        item_index += 1;
                        if (item_index == child_count and (base_total > usable_width or grow_total > 0)) {
                            item_width = @max(1, usable_width - distributed);
                        }
                        const natural_height = if (target_height > 0 and (style.align_items == .center or style.align_items == .end))
                            try self.measureBlockHeight(document, sheet, child, item_width, style, depth, background)
                        else
                            0;
                        var item_y = y;
                        if (style.align_items == .center) {
                            item_y += @divTrunc(@max(0, target_height - natural_height), 2);
                        } else if (style.align_items == .end) {
                            item_y += @max(0, target_height - natural_height);
                        }
                        const stretched_height: ?i32 = if (style.align_items == .stretch and target_height > 0 and child_style.height.kind == .auto)
                            @max(1, target_height)
                        else
                            null;
                        const item_margin_width = (if (child_style.margin.left.kind == .auto) 0 else self.lengthPixels(child_style.margin.left, width, child_style.font_size, 0)) +
                            (if (child_style.margin.right.kind == .auto) 0 else self.lengthPixels(child_style.margin.right, width, child_style.font_size, 0));
                        const bottom = try self.layoutBlockSized(document, sheet, child, cursor_x, item_y, item_width, style, depth, background, @max(1, item_width - item_margin_width), stretched_height);
                        row_bottom = @max(row_bottom, bottom);
                        distributed += item_width;
                        cursor_x += item_width + style.gap + distributed_gap;
                        if (child_style.margin.right.kind == .auto) cursor_x += auto_margin_share;
                    }
                }
            } else if (document.nodes[child].kind == .text and hasVisibleText(document.nodeValue(child))) {
                const base = flexTextNaturalWidth(self, document.nodeValue(child), style);
                const minimum = flexTextMinimumWidth(self, document.nodeValue(child), style);
                var item_width = base;
                if (base_total > usable_width) {
                    if (minimum_total >= usable_width) {
                        item_width = @max(1, @divTrunc(minimum * usable_width, @max(1, minimum_total)));
                    } else {
                        const shrinkable_total = @max(1, base_total - minimum_total);
                        const shrinkable_space = usable_width - minimum_total;
                        item_width = minimum + @divTrunc(@max(0, base - minimum) * shrinkable_space, shrinkable_total);
                    }
                }
                item_index += 1;
                if (item_index == child_count and base_total > usable_width) item_width = @max(1, usable_width - distributed);
                const text_line_height = self.effectiveLineHeight(style);
                const flex_height = if (target_height > 0) target_height else self.lengthPixels(style.height, self.viewport.height, style.font_size, text_line_height);
                const text_y = y + switch (style.align_items) {
                    .center => @divTrunc(@max(0, flex_height - text_line_height), 2),
                    .end => @max(0, flex_height - text_line_height),
                    else => 0,
                };
                var flow = Flow.init(self, document, sheet, cursor_x, text_y, item_width, style.*, background);
                try flow.emitValue(document.nodeValue(child), style, parent);
                row_bottom = @max(row_bottom, flow.finish());
                distributed += item_width;
                cursor_x += item_width + style.gap + distributed_gap;
            }
            child = document.nodes[child].next_sibling;
        }
        return @max(row_bottom, y + target_height);
    }

    fn layoutFlexColumn(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        parent: u16,
        x: i32,
        y: i32,
        width: i32,
        target_height: i32,
        style: *const css.ComputedStyle,
        depth: usize,
        background: u32,
    ) Error!i32 {
        var child_count: usize = 0;
        var natural_total: i32 = 0;
        var grow_total: u32 = 0;
        var grow_count: usize = 0;
        var auto_margin_count: usize = 0;
        var child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (child_style.display != .none and child_style.position != .absolute and child_style.position != .fixed) {
                    child_count += 1;
                    natural_total += try self.measureBlockHeight(document, sheet, child, width, style, depth, background);
                    grow_total += child_style.flex_grow;
                    if (child_style.flex_grow > 0) grow_count += 1;
                    if (child_style.margin.top.kind == .auto) auto_margin_count += 1;
                    if (child_style.margin.bottom.kind == .auto) auto_margin_count += 1;
                }
            } else if (document.nodes[child].kind == .text and hasVisibleText(document.nodeValue(child))) {
                child_count += 1;
                natural_total += self.effectiveLineHeight(style);
            }
            child = document.nodes[child].next_sibling;
        }
        if (child_count == 0) return y + target_height;

        const gap_total = style.gap * @as(i32, @intCast(child_count - 1));
        const free_height = @max(0, target_height - natural_total - gap_total);
        const auto_share = if (grow_total == 0 and auto_margin_count > 0)
            @divTrunc(free_height, @as(i32, @intCast(auto_margin_count)))
        else
            0;
        const justify_free = if (grow_total == 0 and auto_margin_count == 0) free_height else 0;
        var leading: i32 = 0;
        var between: i32 = 0;
        switch (style.justify_content) {
            .start => {},
            .end => leading = justify_free,
            .center => leading = @divTrunc(justify_free, 2),
            .space_between => if (child_count > 1) {
                between = @divTrunc(justify_free, @as(i32, @intCast(child_count - 1)));
            },
            .space_around => {
                between = @divTrunc(justify_free, @as(i32, @intCast(child_count)));
                leading = @divTrunc(between, 2);
            },
            .space_evenly => {
                between = @divTrunc(justify_free, @as(i32, @intCast(child_count + 1)));
                leading = between;
            },
        }

        var cursor_y = y + leading;
        var item_index: usize = 0;
        var grown_count: usize = 0;
        var grown_height: i32 = 0;
        child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (child_style.display != .none) {
                    if (child_style.position == .absolute or child_style.position == .fixed) {
                        _ = try self.layoutBlock(document, sheet, child, x, cursor_y, width, style, depth, background);
                    } else {
                        const natural = try self.measureBlockHeight(document, sheet, child, width, style, depth, background);
                        if (child_style.margin.top.kind == .auto) cursor_y += auto_share;
                        const margin_top = if (child_style.margin.top.kind == .auto) 0 else self.lengthPixels(child_style.margin.top, width, child_style.font_size, 0);
                        const margin_bottom = if (child_style.margin.bottom.kind == .auto) 0 else self.lengthPixels(child_style.margin.bottom, width, child_style.font_size, 0);
                        var grow_height: i32 = 0;
                        if (grow_total > 0 and child_style.flex_grow > 0) {
                            grown_count += 1;
                            grow_height = if (grown_count == grow_count)
                                free_height - grown_height
                            else
                                @divTrunc(free_height * @as(i32, child_style.flex_grow), @as(i32, @intCast(grow_total)));
                            grown_height += grow_height;
                        }

                        var item_width = width;
                        var item_x = x;
                        if (style.align_items != .stretch) {
                            item_width = @min(width, flexItemBaseWidthForViewport(self, document, sheet, child, &child_style, width, depth));
                            switch (style.align_items) {
                                .end => item_x += width - item_width,
                                .center => item_x += @divTrunc(width - item_width, 2),
                                else => {},
                            }
                        }
                        const forced_height = @max(1, natural - margin_top - margin_bottom + grow_height);
                        const forced_width: ?i32 = if (style.align_items == .stretch)
                            null
                        else
                            @max(1, item_width - edgesHorizontalPixels(child_style.margin, width, child_style.font_size, self.viewport));
                        const bottom = try self.layoutBlockSized(document, sheet, child, item_x, cursor_y, item_width, style, depth, background, forced_width, forced_height);
                        cursor_y = @max(cursor_y + natural + grow_height, bottom);
                        if (child_style.margin.bottom.kind == .auto) cursor_y += auto_share;
                        item_index += 1;
                        if (item_index < child_count) cursor_y += style.gap + between;
                    }
                }
            } else if (document.nodes[child].kind == .text and hasVisibleText(document.nodeValue(child))) {
                var text_x = x;
                const text_width = @min(width, flexTextNaturalWidth(self, document.nodeValue(child), style));
                if (style.align_items == .center) text_x += @divTrunc(width - text_width, 2) else if (style.align_items == .end) text_x += width - text_width;
                var flow = Flow.init(self, document, sheet, text_x, cursor_y, if (style.align_items == .stretch) width else text_width, style.*, background);
                try flow.emitValue(document.nodeValue(child), style, parent);
                cursor_y = @max(cursor_y + self.effectiveLineHeight(style), flow.finish());
                item_index += 1;
                if (item_index < child_count) cursor_y += style.gap + between;
            }
            child = document.nodes[child].next_sibling;
        }
        return @max(cursor_y, y + target_height);
    }

    fn measureBlockHeight(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        node: u16,
        width: i32,
        parent_style: *const css.ComputedStyle,
        depth: usize,
        background: u32,
    ) Error!i32 {
        const saved_op_count = self.op_count;
        const saved_text_len = self.text_len;
        const saved_content_width = self.content_width;
        const saved_content_height = self.content_height;
        errdefer {
            self.op_count = saved_op_count;
            self.text_len = saved_text_len;
            self.content_width = saved_content_width;
            self.content_height = saved_content_height;
        }
        const bottom = try self.layoutBlock(document, sheet, node, 0, 0, width, parent_style, depth, background);
        self.op_count = saved_op_count;
        self.text_len = saved_text_len;
        self.content_width = saved_content_width;
        self.content_height = saved_content_height;
        return @max(0, bottom);
    }

    fn layoutColumns(
        self: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        parent: u16,
        x: i32,
        y: i32,
        width: i32,
        style: *const css.ComputedStyle,
        depth: usize,
        background: u32,
    ) Error!i32 {
        var child_count: usize = 0;
        var child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (child_style.display != .none and child_style.position != .absolute and child_style.position != .fixed) child_count += 1;
            }
            child = document.nodes[child].next_sibling;
        }
        if (child_count == 0) return y;
        const requested: usize = @min(child_count, style.grid_columns);
        const columns: usize = @max(@as(usize, 1), requested);
        const gap_total = style.gap * @as(i32, @intCast(columns - 1));
        const column_width = @max(1, @divTrunc(width - gap_total, @as(i32, @intCast(columns))));
        var index: usize = 0;
        var row_y = y;
        var row_bottom = y;
        child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element) {
                const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, self.interaction), .none, self.viewport.width, self.viewport.height);
                if (child_style.display != .none) {
                    if (child_style.position == .absolute or child_style.position == .fixed) {
                        _ = try self.layoutBlock(document, sheet, child, x, row_y, width, style, depth, background);
                    } else {
                        const column = index % columns;
                        if (column == 0 and index > 0) {
                            row_y = row_bottom + style.gap;
                            row_bottom = row_y;
                        }
                        const child_x = x + @as(i32, @intCast(column)) * (column_width + style.gap);
                        const bottom = try self.layoutBlock(document, sheet, child, child_x, row_y, column_width, style, depth, background);
                        row_bottom = @max(row_bottom, bottom);
                        index += 1;
                    }
                }
            }
            child = document.nodes[child].next_sibling;
        }
        return row_bottom;
    }

    fn emitBox(self: *Layout, rect: Rect, style: *const css.ComputedStyle, node: u16, fixed: bool, inherited_background: u32) Error!void {
        if (style.visibility != .visible) return;
        const radii = self.pixelRadii(style.border_radius, rect, style.font_size);
        const border = self.pixelEdges(style.border, rect.w, style.font_size);
        for (style.box_shadow.slice()) |source_shadow| {
            const shadow = self.shadowVisual(source_shadow, rect, style.font_size);
            try self.addOp(.{
                .kind = .shadow,
                .rect = rect,
                .color = shadow.color,
                .background = inherited_background,
                .radii = radii,
                .shadow = shadow,
                .node = node,
                .fixed = fixed,
            });
        }
        if (style.background_color) |color| {
            try self.addOp(.{ .kind = .background, .rect = rect, .color = color, .background = color, .radii = radii, .node = node, .fixed = fixed });
        }
        const supported_background_image = switch (style.background_image.kind) {
            .url, .image_set => style.background_image.raw_value.len > 0,
            .none => false,
        };
        if (supported_background_image) {
            try self.addOp(.{
                .kind = .css_background,
                .rect = rect,
                .background = style.background_color orelse inherited_background,
                .radii = radii,
                .node = node,
                .image_role = .css_background,
                .image_intrinsic = self.image_resolver.intrinsicForRole(node, .css_background),
                .css_background = .{
                    .raw_value = style.background_image.raw_value,
                    .base_url = style.background_image.base_url,
                    .repeat = style.background_repeat,
                    .position = style.background_position,
                    .size = style.background_size,
                },
                .fixed = fixed,
            });
        }
        if (border.top > 0 or border.right > 0 or border.bottom > 0 or border.left > 0) {
            try self.addOp(.{ .kind = .border, .rect = rect, .color = style.border_color, .background = style.background_color orelse inherited_background, .border = border, .radii = radii, .node = node, .fixed = fixed });
        }
    }

    fn applyClip(self: *Layout, start: usize, end: usize, clip: ClipRegion) void {
        var index = start;
        while (index < end and index < self.op_count) : (index += 1) {
            var op = &self.ops[index];
            if (op.fixed) continue;
            if (clip.x) {
                const left = if (op.clip.x) @max(op.clip.rect.x, clip.rect.x) else clip.rect.x;
                const right = if (op.clip.x) @min(op.clip.rect.right(), clip.rect.right()) else clip.rect.right();
                op.clip.rect.x = left;
                op.clip.rect.w = @max(0, right - left);
                op.clip.x = true;
            }
            if (clip.y) {
                const top = if (op.clip.y) @max(op.clip.rect.y, clip.rect.y) else clip.rect.y;
                const bottom = if (op.clip.y) @min(op.clip.rect.bottom(), clip.rect.bottom()) else clip.rect.bottom();
                op.clip.rect.y = top;
                op.clip.rect.h = @max(0, bottom - top);
                op.clip.y = true;
            }
        }
    }

    fn emitControlOp(self: *Layout, rect: Rect, style: *const css.ComputedStyle, node: u16, fixed: bool, background: u32, value: []const u8) Error!void {
        if (style.visibility != .visible) return;
        const face = self.font_provider.face(style, if (value.len > 0) decodeUtf8Scalar(value, 0).codepoint else null);
        try self.addOp(.{
            .kind = .control,
            .rect = rect,
            .color = style.color,
            .background = style.background_color orelse background,
            .border_color = style.border_color,
            .border = self.pixelEdges(style.border, rect.w, style.font_size),
            .padding = self.pixelEdges(style.padding, rect.w, style.font_size),
            .radii = self.pixelRadii(style.border_radius, rect, style.font_size),
            .node = node,
            .font_family = style.font_family,
            .font_size = style.font_size,
            .font_weight = style.font_weight,
            .italic = style.italic,
            .font_id = face.id,
            .font_height = face.height,
            .font_line_height = face.line_height,
            .font_baseline = face.baseline,
            .text_align = style.text_align,
            .disabled = style.disabled,
            .fixed = fixed,
        });
    }

    fn pixelEdges(self: *const Layout, edges: css.Edges, basis: i32, em: i32) PixelEdges {
        return .{
            .top = nonNegative(self.lengthPixels(edges.top, basis, em, 0)),
            .right = nonNegative(self.lengthPixels(edges.right, basis, em, 0)),
            .bottom = nonNegative(self.lengthPixels(edges.bottom, basis, em, 0)),
            .left = nonNegative(self.lengthPixels(edges.left, basis, em, 0)),
        };
    }

    fn pixelRadii(self: *const Layout, source: css.BorderRadii, rect: Rect, em: i32) PixelRadii {
        const width = @max(1, rect.w);
        const height = @max(1, rect.h);
        return .{
            .top_left = .{ .x = nonNegative(self.lengthPixels(source.top_left.x, width, em, 0)), .y = nonNegative(self.lengthPixels(source.top_left.y, height, em, 0)) },
            .top_right = .{ .x = nonNegative(self.lengthPixels(source.top_right.x, width, em, 0)), .y = nonNegative(self.lengthPixels(source.top_right.y, height, em, 0)) },
            .bottom_right = .{ .x = nonNegative(self.lengthPixels(source.bottom_right.x, width, em, 0)), .y = nonNegative(self.lengthPixels(source.bottom_right.y, height, em, 0)) },
            .bottom_left = .{ .x = nonNegative(self.lengthPixels(source.bottom_left.x, width, em, 0)), .y = nonNegative(self.lengthPixels(source.bottom_left.y, height, em, 0)) },
        };
    }

    fn shadowVisual(self: *const Layout, source: css.BoxShadowLayer, rect: Rect, em: i32) ShadowVisual {
        return .{
            .enabled = true,
            .inset = source.inset,
            .offset_x = clamp(self.lengthPixels(source.offset_x, rect.w, em, 0), -256, 256),
            .offset_y = clamp(self.lengthPixels(source.offset_y, rect.h, em, 0), -256, 256),
            .blur = clamp(self.lengthPixels(source.blur, rect.w, em, 0), 0, 64),
            .spread = clamp(self.lengthPixels(source.spread, rect.w, em, 0), -64, 64),
            .color = source.color,
            .alpha = source.alpha,
        };
    }

    fn addTextOp(self: *Layout, rect: Rect, value: []const u8, style: *const css.ComputedStyle, node: u16, background: u32) Error!usize {
        if (value.len == 0 or style.visibility != .visible) return self.op_count;
        const face = self.font_provider.face(style, decodeUtf8Scalar(value, 0).codepoint);
        const reference = try self.storeText(value);
        const index = self.op_count;
        try self.addOp(.{
            .kind = .text,
            .rect = rect,
            .color = style.color,
            .background = background,
            .node = node,
            .text = reference,
            .font_family = style.font_family,
            .font_size = style.font_size,
            .font_weight = style.font_weight,
            .italic = style.italic,
            .font_id = face.id,
            .font_height = face.height,
            .font_line_height = face.line_height,
            .font_baseline = face.baseline,
            .underline = style.underline,
            .text_align = style.text_align,
            .disabled = style.disabled,
            .fixed = style.position == .fixed,
        });
        return index;
    }

    fn addOp(self: *Layout, op: RenderOp) Error!void {
        if (self.op_count >= self.ops.len) return error.RenderLimit;
        self.ops[self.op_count] = op;
        self.op_count += 1;
    }

    fn storeText(self: *Layout, value: []const u8) Error!StringRef {
        if (value.len > self.text_storage.len -| self.text_len) return error.TextLimit;
        const start = self.text_len;
        @memcpy(self.text_storage[start .. start + value.len], value);
        self.text_len += value.len;
        return .{ .offset = @intCast(start), .len = @intCast(value.len) };
    }
};

const Flow = struct {
    layout: *Layout,
    document: *const html.Document,
    sheet: *const css.Stylesheet,
    x: i32,
    y: i32,
    width: i32,
    cursor_x: i32,
    line_height: i32,
    line_baseline: i32,
    line_descent: i32,
    line_op_start: usize,
    line_has_content: bool,
    style: css.ComputedStyle,
    background: u32,

    fn init(
        layout: *Layout,
        document: *const html.Document,
        sheet: *const css.Stylesheet,
        x: i32,
        y: i32,
        width: i32,
        style: css.ComputedStyle,
        background: u32,
    ) Flow {
        return .{
            .layout = layout,
            .document = document,
            .sheet = sheet,
            .x = x,
            .y = y,
            .width = @max(1, width),
            .cursor_x = x,
            .line_height = layout.effectiveLineHeight(&style),
            .line_baseline = 0,
            .line_descent = 0,
            .line_op_start = layout.op_count,
            .line_has_content = false,
            .style = style,
            .background = background,
        };
    }

    fn layoutNode(self: *Flow, node_index: u16, depth: usize) Error!void {
        if (depth >= max_layout_depth) return error.DepthLimit;
        const node = self.document.nodes[node_index];
        switch (node.kind) {
            .text => try self.emitValue(self.document.nodeValue(node_index), &self.style, node_index),
            .element => {
                const style = self.sheet.computeForViewportSize(self.document, node_index, &self.style, elementState(self.document, node_index, self.layout.interaction), .none, self.layout.viewport.width, self.layout.viewport.height);
                if (style.display == .none) return;
                if (isBlockDisplay(style.display)) {
                    self.flushLine();
                    self.y = try self.layout.layoutBlock(self.document, self.sheet, node_index, self.x, self.y, self.width, &self.style, depth + 1, self.background);
                    self.resetLine();
                } else {
                    try self.layoutInlineElement(node_index, style, depth + 1);
                }
            },
            else => {},
        }
    }

    fn layoutInlineElement(self: *Flow, node_index: u16, style: css.ComputedStyle, depth: usize) Error!void {
        if (depth >= max_layout_depth) return error.DepthLimit;
        if (style.clip_empty) return;
        const name = self.document.nodeName(node_index);
        if (equalsIgnoreCase(name, "br")) {
            self.breakLine();
            return;
        }
        if (isFormControl(name) and (style.position == .absolute or style.position == .fixed)) return;
        if (style.display == .inline_block) {
            try self.emitInlineBlock(node_index, &style, depth);
            return;
        }
        const before = self.sheet.computeForViewportSize(self.document, node_index, &style, elementState(self.document, node_index, self.layout.interaction), .before, self.layout.viewport.width, self.layout.viewport.height);
        try self.emitGeneratedContent(&before, node_index);
        if (equalsIgnoreCase(name, "input")) {
            const input_type = self.document.attribute(node_index, "type") orelse "text";
            if (equalsIgnoreCase(input_type, "hidden")) return;
            const input_value = self.document.attribute(node_index, "value") orelse self.document.attribute(node_index, "placeholder") orelse "";
            const value = if (input_value.len > 0) input_value else " ";
            const minimum_width: i32 = if (equalsIgnoreCase(input_type, "submit") or equalsIgnoreCase(input_type, "button") or equalsIgnoreCase(input_type, "reset"))
                64
            else if (equalsIgnoreCase(input_type, "checkbox") or equalsIgnoreCase(input_type, "radio"))
                22
            else
                160;
            try self.emitControl(value, &style, node_index, minimum_width);
        } else if (equalsIgnoreCase(name, "button")) {
            var text_buffer: [max_control_text_bytes]u8 = undefined;
            const value = blockControlText(self.document, node_index, text_buffer[0..]);
            try self.emitControl(value, &style, node_index, 64);
        } else if (equalsIgnoreCase(name, "select")) {
            var text_buffer: [max_control_text_bytes]u8 = undefined;
            const value = selectedOptionText(self.document, node_index, text_buffer[0..]);
            try self.emitControl(if (value.len > 0) value else " ", &style, node_index, 160);
        } else if (equalsIgnoreCase(name, "textarea")) {
            var text_buffer: [max_control_text_bytes]u8 = undefined;
            const value = self.document.textContent(node_index, text_buffer[0..]) catch "";
            const placeholder = self.document.attribute(node_index, "placeholder") orelse "";
            try self.emitControl(if (value.len > 0) value else if (placeholder.len > 0) placeholder else " ", &style, node_index, 160);
        } else if (isImageElement(name)) {
            try self.emitImage(node_index, &style);
        } else if (equalsIgnoreCase(name, "canvas")) {
            try self.emitCanvas(node_index, &style);
        } else {
            var child = self.document.nodes[node_index].first_child;
            while (child != html.none) {
                if (self.document.nodes[child].kind == .text) {
                    try self.emitValue(self.document.nodeValue(child), &style, node_index);
                } else if (self.document.nodes[child].kind == .element) {
                    const child_style = self.sheet.computeForViewportSize(self.document, child, &style, elementState(self.document, child, self.layout.interaction), .none, self.layout.viewport.width, self.layout.viewport.height);
                    if (isBlockDisplay(child_style.display)) {
                        self.flushLine();
                        self.y = try self.layout.layoutBlock(self.document, self.sheet, child, self.x, self.y, self.width, &style, depth + 1, self.background);
                        self.resetLine();
                    } else if (child_style.display != .none) {
                        try self.layoutInlineElement(child, child_style, depth + 1);
                    }
                }
                child = self.document.nodes[child].next_sibling;
            }
        }
        const after = self.sheet.computeForViewportSize(self.document, node_index, &style, elementState(self.document, node_index, self.layout.interaction), .after, self.layout.viewport.width, self.layout.viewport.height);
        try self.emitGeneratedContent(&after, node_index);
    }

    fn emitInlineBlock(self: *Flow, node: u16, style: *const css.ComputedStyle, depth: usize) Error!void {
        const outer_width = @max(1, @min(self.width, preferredInlineOuterWidth(
            self.layout,
            self.document,
            self.sheet,
            node,
            style,
            self.width,
            depth,
        )));
        const margin_left = self.layout.lengthPixels(style.margin.left, self.width, style.font_size, 0);
        const margin_right = self.layout.lengthPixels(style.margin.right, self.width, style.font_size, 0);
        const box_width = @max(1, outer_width - margin_left - margin_right);
        if (self.line_has_content and self.cursor_x + outer_width > self.x + self.width) self.breakLine();
        const bottom = try self.layout.layoutBlockSized(
            self.document,
            self.sheet,
            node,
            self.cursor_x,
            self.y,
            outer_width,
            &self.style,
            depth + 1,
            self.background,
            box_width,
            null,
        );
        self.cursor_x += outer_width;
        self.line_height = @max(self.line_height, bottom - self.y);
        self.line_has_content = true;
    }

    fn emitGeneratedContent(self: *Flow, style: *const css.ComputedStyle, node: u16) Error!void {
        if (style.display == .none or style.content.len == 0) return;
        var generated: [2048]u8 = undefined;
        var generated_len: usize = 0;
        if (!style.content_is_expression) {
            _ = appendGeneratedContent(generated[0..], &generated_len, style.content);
        } else {
            var cursor: usize = 0;
            while (cursor < style.content.len) {
                while (cursor < style.content.len and isWhitespace(style.content[cursor])) : (cursor += 1) {}
                if (cursor >= style.content.len) break;
                const byte = style.content[cursor];
                if (byte == '"' or byte == '\'') {
                    const quote = byte;
                    cursor += 1;
                    const start = cursor;
                    while (cursor < style.content.len and style.content[cursor] != quote) {
                        if (style.content[cursor] == '\\' and cursor + 1 < style.content.len) cursor += 1;
                        cursor += 1;
                    }
                    const decoded = decodeCssContentString(style.content[start..@min(cursor, style.content.len)], generated[generated_len..]);
                    generated_len += decoded.len;
                    if (cursor < style.content.len) cursor += 1;
                    continue;
                }
                if (startsWithIgnoreCase(style.content[cursor..], "attr(")) {
                    const close = contentFunctionEnd(style.content, cursor + "attr".len) orelse break;
                    const argument = trimContentToken(style.content[cursor + "attr(".len .. close]);
                    if (self.document.attribute(node, argument)) |value| _ = appendGeneratedContent(generated[0..], &generated_len, value);
                    cursor = close + 1;
                    continue;
                }
                while (cursor < style.content.len and !isWhitespace(style.content[cursor])) : (cursor += 1) {}
            }
        }
        if (generated_len > 0) try self.emitGeneratedValue(generated[0..generated_len], style, node);
    }

    fn emitGeneratedValue(self: *Flow, value: []const u8, style: *const css.ComputedStyle, node: u16) Error!void {
        var cursor: usize = 0;
        var pending_space = false;
        while (cursor < value.len) {
            while (cursor < value.len and isWhitespace(value[cursor])) : (cursor += 1) pending_space = true;
            if (cursor >= value.len) break;
            const start = cursor;
            while (cursor < value.len and !isWhitespace(value[cursor])) cursor += utf8SequenceLength(value, cursor);
            try self.emitWord(value[start..cursor], style, node, pending_space and self.line_has_content);
            pending_space = false;
        }
    }

    fn emitValue(self: *Flow, value: []const u8, style: *const css.ComputedStyle, node: u16) Error!void {
        if (style.white_space == .pre) {
            try self.emitPreformatted(value, style, node);
            return;
        }
        var cursor: usize = 0;
        while (cursor < value.len) {
            while (cursor < value.len and isWhitespace(value[cursor])) : (cursor += 1) {}
            if (cursor >= value.len) break;
            const start = cursor;
            while (cursor < value.len and !isWhitespace(value[cursor])) cursor += utf8SequenceLength(value, cursor);
            try self.emitWord(value[start..cursor], style, node, self.line_has_content);
        }
    }

    fn emitPreformatted(self: *Flow, value: []const u8, style: *const css.ComputedStyle, node: u16) Error!void {
        var cursor: usize = 0;
        var start: usize = 0;
        while (cursor <= value.len) : (cursor += 1) {
            if (cursor < value.len and value[cursor] != '\n') continue;
            const line = value[start..cursor];
            if (line.len > 0) try self.emitWord(line, style, node, false);
            if (cursor < value.len) self.breakLine();
            start = cursor + 1;
        }
    }

    fn emitControl(self: *Flow, value: []const u8, style: *const css.ComputedStyle, node: u16, minimum_width: i32) Error!void {
        const border = self.layout.pixelEdges(style.border, self.width, style.font_size);
        const padding = self.layout.pixelEdges(style.padding, self.width, style.font_size);
        const horizontal_chrome = border.left + border.right + padding.left + padding.right;
        const vertical_chrome = border.top + border.bottom + padding.top + padding.bottom;
        const measured = self.layout.measureStyledText(style, value);
        const primary_face = self.layout.font_provider.face(style, if (value.len > 0) decodeUtf8Scalar(value, 0).codepoint else null);
        const text_line_height = if (style.line_height_value.kind == .normal)
            @max(primary_face.line_height, measured.line_height)
        else
            @max(1, style.line_height);
        const natural_width = @max(minimum_width, measured.width + horizontal_chrome + 4);
        var control_width = self.layout.lengthPixels(style.width, self.width, style.font_size, natural_width);
        if (style.width.kind != .auto and style.box_sizing == .content_box) control_width += horizontal_chrome;
        if (style.min_width.kind != .auto) {
            var minimum = self.layout.lengthPixels(style.min_width, self.width, style.font_size, 0);
            if (style.box_sizing == .content_box) minimum += horizontal_chrome;
            control_width = @max(control_width, minimum);
        }
        if (style.max_width.kind != .auto) {
            var maximum = self.layout.lengthPixels(style.max_width, self.width, style.font_size, control_width);
            if (style.box_sizing == .content_box) maximum += horizontal_chrome;
            control_width = @min(control_width, maximum);
        }
        control_width = @max(1, control_width);
        const natural_height = @max(22, text_line_height + vertical_chrome);
        var control_height: i32 = @max(1, self.layout.lengthPixels(style.height, natural_height, style.font_size, natural_height));
        if (style.height.kind != .auto and style.box_sizing == .content_box) control_height += vertical_chrome;
        if (style.min_height.kind != .auto) {
            var minimum = self.layout.lengthPixels(style.min_height, self.layout.viewport.height, style.font_size, 0);
            if (style.box_sizing == .content_box) minimum += vertical_chrome;
            control_height = @max(control_height, minimum);
        }
        if (style.max_height.kind != .auto) {
            var maximum = self.layout.lengthPixels(style.max_height, self.layout.viewport.height, style.font_size, control_height);
            if (style.box_sizing == .content_box) maximum += vertical_chrome;
            control_height = @min(control_height, maximum);
        }
        const margin_left = self.layout.lengthPixels(style.margin.left, self.width, style.font_size, 0);
        const margin_right = self.layout.lengthPixels(style.margin.right, self.width, style.font_size, 0);
        const margin_top = self.layout.lengthPixels(style.margin.top, self.width, style.font_size, 0);
        const margin_bottom = self.layout.lengthPixels(style.margin.bottom, self.width, style.font_size, 0);
        if (self.line_has_content and self.cursor_x + margin_left + control_width + margin_right > self.x + self.width) self.breakLine();
        self.cursor_x += margin_left;
        const control_rect = Rect{ .x = self.cursor_x, .y = self.y + margin_top, .w = control_width, .h = control_height };
        try self.layout.emitControlOp(control_rect, style, node, style.position == .fixed, self.background, value);
        const content_x = control_rect.x + border.left + padding.left;
        const content_y = control_rect.y + border.top + padding.top;
        const content_width = @max(1, control_rect.w - horizontal_chrome);
        const content_height = @max(1, control_rect.h - vertical_chrome);
        const text_y = content_y + @max(0, @divTrunc(content_height - text_line_height, 2));
        _ = try self.layout.addTextOp(
            .{ .x = content_x, .y = text_y, .w = content_width, .h = @min(content_height, text_line_height) },
            value,
            style,
            node,
            style.background_color orelse self.background,
        );
        self.cursor_x += control_width + margin_right;
        self.line_height = @max(self.line_height, margin_top + control_height + margin_bottom);
        self.line_has_content = true;
    }

    fn emitCanvas(self: *Flow, node: u16, style: *const css.ComputedStyle) Error!void {
        const requested_width = htmlDimension(self.document.attribute(node, "width"), 300);
        const requested_height = htmlDimension(self.document.attribute(node, "height"), 150);
        const width = @max(1, @min(self.width, self.layout.lengthPixels(style.width, self.width, style.font_size, requested_width)));
        const height = @max(1, self.layout.lengthPixels(style.height, requested_height, style.font_size, requested_height));
        if (self.line_has_content and self.cursor_x + width > self.x + self.width) self.breakLine();
        if (style.visibility == .visible) try self.layout.addOp(.{ .kind = .canvas, .rect = .{ .x = self.cursor_x, .y = self.y, .w = width, .h = height }, .node = node, .background = self.background });
        self.cursor_x += width;
        self.line_height = @max(self.line_height, height);
        self.line_has_content = true;
    }

    fn emitImage(self: *Flow, node: u16, style: *const css.ComputedStyle) Error!void {
        const intrinsic = self.layout.image_resolver.intrinsic(node);
        const html_width = optionalHtmlDimension(self.document.attribute(node, "width"));
        const html_height = optionalHtmlDimension(self.document.attribute(node, "height"));
        const natural_width: i32 = @intCast(if (intrinsic.width > 0) intrinsic.width else html_width orelse 16);
        const natural_height: i32 = @intCast(if (intrinsic.height > 0) intrinsic.height else html_height orelse 16);

        var width: i32 = if (style.width.kind != .auto)
            self.layout.lengthPixels(style.width, self.width, style.font_size, natural_width)
        else if (html_width) |value|
            @intCast(value)
        else if (html_height != null and intrinsic.width > 0 and intrinsic.height > 0)
            @divTrunc(@as(i32, @intCast(intrinsic.width)) * @as(i32, @intCast(html_height.?)), @as(i32, @intCast(intrinsic.height)))
        else
            natural_width;
        var height: i32 = if (style.height.kind != .auto)
            self.layout.lengthPixels(style.height, self.layout.viewport.height, style.font_size, natural_height)
        else if (html_height) |value|
            @intCast(value)
        else if ((style.width.kind != .auto or html_width != null) and intrinsic.width > 0 and intrinsic.height > 0)
            @divTrunc(width * @as(i32, @intCast(intrinsic.height)), @as(i32, @intCast(intrinsic.width)))
        else
            natural_height;
        if (style.min_width.kind != .auto) width = @max(width, self.layout.lengthPixels(style.min_width, self.width, style.font_size, 0));
        if (style.max_width.kind != .auto) width = @min(width, self.layout.lengthPixels(style.max_width, self.width, style.font_size, width));
        width = clamp(width, 1, self.width);
        height = clamp(height, 1, 4096);

        const margin_left = self.layout.lengthPixels(style.margin.left, self.width, style.font_size, 0);
        const margin_right = self.layout.lengthPixels(style.margin.right, self.width, style.font_size, 0);
        const margin_top = self.layout.lengthPixels(style.margin.top, self.width, style.font_size, 0);
        const margin_bottom = self.layout.lengthPixels(style.margin.bottom, self.width, style.font_size, 0);
        if (self.line_has_content and self.cursor_x + margin_left + width + margin_right > self.x + self.width) self.breakLine();
        self.cursor_x += margin_left;
        const rect = Rect{ .x = self.cursor_x, .y = self.y + margin_top, .w = width, .h = height };
        if (style.visibility == .visible) {
            try self.layout.addOp(.{
                .kind = .image,
                .rect = rect,
                .node = node,
                .background = style.background_color orelse self.background,
                .radii = self.layout.pixelRadii(style.border_radius, rect, style.font_size),
                .image_role = .content,
                .image_intrinsic = intrinsic,
                .fixed = style.position == .fixed,
            });
        }
        // Loading and not-yet-discovered resources retain only their neutral
        // replaced-element box.  Alternative text describes a terminal image
        // failure; showing it while a resource is still in flight causes a
        // valid image to flash as broken and makes missing loader state look
        // like a decoder error.
        if (intrinsic.state == .failed) {
            const alt = self.document.attribute(node, "alt") orelse "[broken image]";
            if (alt.len > 0) {
                _ = try self.layout.addTextOp(
                    .{ .x = rect.x + 3, .y = rect.y + 2, .w = @max(1, rect.w - 6), .h = @min(rect.h, @max(self.layout.effectiveLineHeight(style), 16)) },
                    alt,
                    style,
                    node,
                    style.background_color orelse self.background,
                );
            }
        }
        self.cursor_x += width + margin_right;
        self.line_height = @max(self.line_height, margin_top + height + margin_bottom);
        self.line_has_content = true;
    }

    fn emitWord(self: *Flow, word: []const u8, style: *const css.ComputedStyle, node: u16, leading_space: bool) Error!void {
        const soft_hyphen = "\xC2\xAD";
        var segment_start: usize = 0;
        var cursor: usize = 0;
        var first_segment = true;
        while (cursor + soft_hyphen.len <= word.len) {
            if (!std.mem.eql(u8, word[cursor .. cursor + soft_hyphen.len], soft_hyphen)) {
                cursor += utf8SequenceLength(word, cursor);
                continue;
            }
            if (cursor > segment_start) {
                try self.emitWordRaw(word[segment_start..cursor], style, node, leading_space and first_segment);
                first_segment = false;
            }
            cursor += soft_hyphen.len;
            segment_start = cursor;
        }
        if (segment_start > 0) {
            if (segment_start < word.len) {
                try self.emitWordRaw(word[segment_start..], style, node, leading_space and first_segment);
            }
            return;
        }
        try self.emitWordRaw(word, style, node, leading_space);
    }

    fn emitWordRaw(self: *Flow, word: []const u8, style: *const css.ComputedStyle, node: u16, leading_space: bool) Error!void {
        if (word.len == 0) return;
        const space_width = if (leading_space) self.layout.measureStyledText(style, " ").width else 0;
        const word_width = self.layout.measureStyledText(style, word).width;
        if (style.white_space != .nowrap and self.line_has_content and self.cursor_x + space_width + word_width > self.x + self.width) self.breakLine();
        if (leading_space and self.line_has_content) self.cursor_x += space_width;

        if (style.white_space == .nowrap) {
            try self.emitTextRuns(word, style, node);
            return;
        }

        const available_before_split = @max(1, self.x + self.width - self.cursor_x);
        if (word_width <= available_before_split) {
            try self.emitTextRuns(word, style, node);
            return;
        }

        var start: usize = 0;
        while (start < word.len) {
            const available = @max(1, self.x + self.width - self.cursor_x);
            const end = self.fittedTextEnd(word, start, available, style);
            const chunk = word[start..end];
            try self.emitTextRuns(chunk, style, node);
            if (end <= start) break;
            start = end;
            if (start < word.len) self.breakLine();
        }
    }

    fn fittedTextEnd(self: *const Flow, value: []const u8, start: usize, available: i32, style: *const css.ComputedStyle) usize {
        var cursor = start;
        var width: i32 = 0;
        while (cursor < value.len) {
            const decoded = decodeUtf8Scalar(value, cursor);
            const next = cursor + decoded.consumed;
            const scalar_width = self.layout.measureStyledText(style, value[cursor..next]).width;
            if (cursor > start and width + scalar_width > available) break;
            width = saturatingAdd(width, scalar_width);
            cursor = next;
            if (width >= available) break;
        }
        return if (cursor > start) cursor else @min(value.len, start + utf8SequenceLength(value, start));
    }

    fn emitTextRuns(self: *Flow, value: []const u8, style: *const css.ComputedStyle, node: u16) Error!void {
        if (value.len == 0) return;
        var cursor: usize = 0;
        var run_start: usize = 0;
        var face = self.layout.font_provider.face(style, decodeUtf8Scalar(value, 0).codepoint);
        while (cursor < value.len) {
            const decoded = decodeUtf8Scalar(value, cursor);
            const next_face = self.layout.font_provider.face(style, decoded.codepoint);
            if (cursor > run_start and next_face.id != face.id) {
                try self.emitTextRun(value[run_start..cursor], style, node, face);
                run_start = cursor;
                face = next_face;
            }
            cursor += decoded.consumed;
        }
        if (run_start < value.len) try self.emitTextRun(value[run_start..], style, node, face);
    }

    fn emitTextRun(self: *Flow, value: []const u8, style: *const css.ComputedStyle, node: u16, face: FontFace) Error!void {
        const measured = self.layout.font_provider.measureFace(face, value);
        const requested_line_height = if (style.line_height_value.kind == .normal) face.line_height else style.line_height;
        const line_box_height = @max(0, requested_line_height);
        const leading = @divFloor(line_box_height - face.line_height, 2);
        const index = try self.layout.addTextOp(
            .{ .x = self.cursor_x, .y = self.y + leading, .w = @max(0, measured.width), .h = @max(1, face.line_height) },
            value,
            style,
            node,
            self.background,
        );
        if (index < self.layout.op_count) {
            self.layout.ops[index].font_id = face.id;
            self.layout.ops[index].font_height = face.height;
            self.layout.ops[index].font_line_height = face.line_height;
            self.layout.ops[index].font_baseline = face.baseline;
        }
        self.cursor_x = saturatingAdd(self.cursor_x, @max(0, measured.width));
        self.line_baseline = @max(self.line_baseline, leading + face.baseline);
        self.line_descent = @max(self.line_descent, @max(0, line_box_height - leading - face.baseline));
        self.line_height = @max(self.line_height, line_box_height);
        self.line_has_content = true;
    }

    fn breakLine(self: *Flow) void {
        if (!self.line_has_content) {
            self.y += @max(1, self.line_height);
            self.resetLine();
            return;
        }
        self.alignLine();
        self.y += @max(1, self.line_height);
        self.resetLine();
    }

    fn flushLine(self: *Flow) void {
        if (self.line_has_content) self.breakLine();
    }

    fn alignLine(self: *Flow) void {
        const used = self.cursor_x - self.x;
        const spare = @max(0, self.width - used);
        const shift = if (self.style.text_align == .center) @divTrunc(spare, 2) else if (self.style.text_align == .right) spare else 0;
        var index = self.line_op_start;
        while (index < self.layout.op_count) : (index += 1) {
            var op = &self.layout.ops[index];
            if (!op.fixed) op.rect.x += shift;
            if (op.kind == .text) {
                const baseline = op.rect.y - self.y + op.font_baseline;
                op.rect.y += @max(0, self.line_baseline - baseline);
            }
        }
    }

    fn resetLine(self: *Flow) void {
        self.cursor_x = self.x;
        self.line_height = self.layout.effectiveLineHeight(&self.style);
        self.line_baseline = 0;
        self.line_descent = 0;
        self.line_op_start = self.layout.op_count;
        self.line_has_content = false;
    }

    fn finish(self: *Flow) i32 {
        if (self.line_has_content) {
            self.alignLine();
            return self.y + @max(1, self.line_height);
        }
        return self.y;
    }
};

fn elementState(document: *const html.Document, node_index: u16, interaction: InteractionState) css.ElementState {
    return .{
        .link = document.attribute(node_index, "href") != null,
        .hover = interaction.hovered_node == node_index or (interaction.hovered_node != html.none and isDescendantOf(document, interaction.hovered_node, node_index)),
        .focus = interaction.focused_node == node_index,
        .focus_within = interaction.focused_node == node_index or (interaction.focused_node != html.none and isDescendantOf(document, interaction.focused_node, node_index)),
        .active = interaction.active_node == node_index or (interaction.active_node != html.none and isDescendantOf(document, interaction.active_node, node_index)),
        .disabled = document.attribute(node_index, "disabled") != null,
        .hovered_node = interaction.hovered_node,
        .focused_node = interaction.focused_node,
        .active_node = interaction.active_node,
    };
}

fn isBlockDisplay(display: css.Display) bool {
    return display == .block or display == .flex or display == .grid;
}

fn firstTextChild(document: *const html.Document, node: u16) []const u8 {
    var child = document.nodes[node].first_child;
    while (child != html.none) {
        if (document.nodes[child].kind == .text) return document.nodeValue(child);
        child = document.nodes[child].next_sibling;
    }
    return "";
}

fn isFormControl(name: []const u8) bool {
    return equalsIgnoreCase(name, "input") or
        equalsIgnoreCase(name, "button") or
        equalsIgnoreCase(name, "select") or
        equalsIgnoreCase(name, "textarea");
}

fn isImageElement(name: []const u8) bool {
    return equalsIgnoreCase(name, "img") or equalsIgnoreCase(name, "svg");
}

fn blockControlText(document: *const html.Document, node: u16, out: []u8) []const u8 {
    const name = document.nodeName(node);
    if (equalsIgnoreCase(name, "input")) {
        const input_type = document.attribute(node, "type") orelse "text";
        if (equalsIgnoreCase(input_type, "hidden")) return "";
        return document.attribute(node, "value") orelse document.attribute(node, "placeholder") orelse " ";
    }
    if (equalsIgnoreCase(name, "button")) {
        if (document.attribute(node, "aria-label")) |accessible| return accessible;
        if (document.attribute(node, "title")) |title| return title;
        const value = document.textContent(node, out) catch "";
        const collapsed = collapseControlWhitespace(value, out);
        return if (collapsed.len > 0) collapsed else "Button";
    }
    if (equalsIgnoreCase(name, "select")) {
        const value = selectedOptionText(document, node, out);
        return if (value.len > 0) value else " ";
    }
    if (equalsIgnoreCase(name, "textarea")) {
        const value = document.textContent(node, out) catch "";
        if (value.len > 0) return value;
        return document.attribute(node, "placeholder") orelse " ";
    }
    return "";
}

fn collapseControlWhitespace(value: []const u8, out: []u8) []const u8 {
    var read: usize = 0;
    var written: usize = 0;
    var pending_space = false;
    while (read < value.len) {
        if (isWhitespace(value[read])) {
            pending_space = written > 0;
            read += 1;
            continue;
        }
        if (pending_space and written < out.len) {
            out[written] = ' ';
            written += 1;
        }
        pending_space = false;
        const sequence_len = utf8SequenceLength(value, read);
        if (sequence_len > out.len - written) break;
        var offset: usize = 0;
        while (offset < sequence_len) : (offset += 1) out[written + offset] = value[read + offset];
        written += sequence_len;
        read += sequence_len;
    }
    return out[0..written];
}

fn flexItemBaseWidthForViewport(
    layout: *const Layout,
    document: *const html.Document,
    sheet: *const css.Stylesheet,
    node: u16,
    style: *const css.ComputedStyle,
    basis: i32,
    depth: usize,
) i32 {
    const viewport = layout.viewport;
    const em = style.font_size;
    const horizontal_margin = edgesHorizontalPixels(style.margin, basis, em, viewport);
    const horizontal_chrome = edgesHorizontalPixels(style.padding, basis, em, viewport) + edgesHorizontalPixels(style.border, basis, em, viewport);
    var natural: i32 = undefined;
    if (style.flex_basis.kind != .auto) {
        natural = style.flex_basis.pixelsForViewport(basis, em, 0, viewport.width, viewport.height);
        if (style.box_sizing == .content_box) natural += horizontal_chrome;
        natural += horizontal_margin;
    } else if (style.width.kind != .auto) {
        natural = style.width.pixelsForViewport(basis, em, 1, viewport.width, viewport.height);
        if (style.box_sizing == .content_box) natural += horizontal_chrome;
        natural += horizontal_margin;
    } else {
        natural = preferredInlineOuterWidth(layout, document, sheet, node, style, basis, depth);
    }
    if (style.min_width.kind != .auto) {
        var minimum = style.min_width.pixelsForViewport(basis, em, 0, viewport.width, viewport.height);
        if (style.box_sizing == .content_box) minimum += horizontal_chrome;
        natural = @max(natural, minimum + horizontal_margin);
    }
    if (style.max_width.kind != .auto) {
        var maximum = style.max_width.pixelsForViewport(basis, em, natural, viewport.width, viewport.height);
        if (style.box_sizing == .content_box) maximum += horizontal_chrome;
        natural = @min(natural, maximum + horizontal_margin);
    }
    return @max(1, natural);
}

fn preferredInlineOuterWidth(
    layout: *const Layout,
    document: *const html.Document,
    sheet: *const css.Stylesheet,
    node: u16,
    style: *const css.ComputedStyle,
    basis: i32,
    depth: usize,
) i32 {
    if (depth >= max_layout_depth) return 1;
    const viewport = layout.viewport;
    const em = style.font_size;
    const margin = edgesHorizontalPixels(style.margin, basis, em, viewport);
    const name = document.nodeName(node);

    if (isFormControl(name)) {
        var text_buffer: [max_control_text_bytes]u8 = undefined;
        const value = blockControlText(document, node, text_buffer[0..]);
        const input_type = document.attribute(node, "type") orelse "text";
        const minimum: i32 = if (equalsIgnoreCase(input_type, "checkbox") or equalsIgnoreCase(input_type, "radio"))
            22
        else if (equalsIgnoreCase(input_type, "submit") or equalsIgnoreCase(input_type, "button") or equalsIgnoreCase(input_type, "reset"))
            64
        else
            160;
        const natural = @max(minimum, layout.measureStyledText(style, value).width + 12);
        var width = layout.lengthPixels(style.width, basis, em, natural);
        if (style.min_width.kind != .auto) width = @max(width, layout.lengthPixels(style.min_width, basis, em, 0));
        if (style.max_width.kind != .auto) width = @min(width, layout.lengthPixels(style.max_width, basis, em, width));
        return @max(1, width + margin);
    }

    if (isImageElement(name) or equalsIgnoreCase(name, "canvas")) {
        const html_width = optionalHtmlDimension(document.attribute(node, "width"));
        const default_width: u32 = if (equalsIgnoreCase(name, "canvas")) 300 else 16;
        const fallback: i32 = @intCast(html_width orelse default_width);
        var width = layout.lengthPixels(style.width, basis, em, fallback);
        if (style.min_width.kind != .auto) width = @max(width, layout.lengthPixels(style.min_width, basis, em, 0));
        if (style.max_width.kind != .auto) width = @min(width, layout.lengthPixels(style.max_width, basis, em, width));
        return @max(1, width + margin);
    }

    const chrome = edgesHorizontalPixels(style.padding, basis, em, viewport) + edgesHorizontalPixels(style.border, basis, em, viewport);
    if (style.width.kind != .auto) {
        var width = layout.lengthPixels(style.width, basis, em, 1);
        if (style.box_sizing == .content_box) width += chrome;
        return @max(1, width + margin);
    }

    const flex_row = (style.display == .flex or style.display == .inline_flex) and style.flex_direction == .row;
    var widest: i32 = 0;
    var line_width: i32 = 0;
    var child = document.nodes[node].first_child;
    while (child != html.none) {
        if (document.nodes[child].kind == .text) {
            line_width += measureCollapsedText(layout, style, document.nodeValue(child));
        } else if (document.nodes[child].kind == .element) {
            const child_style = sheet.computeForViewportSize(document, child, style, elementState(document, child, layout.interaction), .none, viewport.width, viewport.height);
            if (child_style.display != .none and child_style.position != .absolute and child_style.position != .fixed) {
                const child_width = preferredInlineOuterWidth(layout, document, sheet, child, &child_style, basis, depth + 1);
                if (isBlockDisplay(child_style.display) and !flex_row) {
                    widest = @max(widest, line_width);
                    widest = @max(widest, child_width);
                    line_width = 0;
                } else {
                    line_width += child_width;
                }
            }
        }
        child = document.nodes[child].next_sibling;
    }
    if (flex_row) {
        const item_count = directVisibleItemCount(document, node);
        if (item_count > 1) line_width += @as(i32, @intCast(item_count - 1)) * style.gap;
    }
    widest = @max(widest, line_width);
    var result: i32 = @max(1, widest + chrome + margin);
    if (style.min_width.kind != .auto) result = @max(result, layout.lengthPixels(style.min_width, basis, em, 0) + margin);
    if (style.max_width.kind != .auto) result = @min(result, layout.lengthPixels(style.max_width, basis, em, result) + margin);
    return result;
}

fn flexItemMinimumWidthForViewport(layout: *const Layout, document: *const html.Document, node: u16, style: *const css.ComputedStyle, basis: i32, base: i32, viewport: Viewport) i32 {
    if (style.flex_shrink == 0) return base;
    const margin = edgesHorizontalPixels(style.margin, basis, style.font_size, viewport);
    if (style.min_width.kind != .auto) return @max(1, style.min_width.pixelsForViewport(basis, style.font_size, 1, viewport.width, viewport.height) + margin);
    if (style.width.kind == .px or style.width.kind == .em or style.width.kind == .rem or style.width.kind == .vw or style.width.kind == .vh) return base;
    return @min(base, flexItemIntrinsicWidthForViewport(layout, document, node, style, basis, viewport));
}

fn flexItemIntrinsicWidthForViewport(layout: *const Layout, document: *const html.Document, node: u16, style: *const css.ComputedStyle, basis: i32, viewport: Viewport) i32 {
    const em = style.font_size;
    const horizontal_margin = edgesHorizontalPixels(style.margin, basis, em, viewport);
    const horizontal_chrome = edgesHorizontalPixels(style.padding, basis, em, viewport) + edgesHorizontalPixels(style.border, basis, em, viewport);

    var text_buffer: [max_control_text_bytes]u8 = undefined;
    const name = document.nodeName(node);
    var minimum_width: i32 = 1;
    var text_width: i32 = 0;
    if (equalsIgnoreCase(name, "input")) {
        const text_value = blockControlText(document, node, text_buffer[0..]);
        text_width = layout.measureStyledText(style, text_value).width;
        const input_type = document.attribute(node, "type") orelse "text";
        minimum_width = if (equalsIgnoreCase(input_type, "checkbox") or equalsIgnoreCase(input_type, "radio")) 22 else if (equalsIgnoreCase(input_type, "submit") or equalsIgnoreCase(input_type, "button") or equalsIgnoreCase(input_type, "reset")) 64 else 160;
    } else if (equalsIgnoreCase(name, "button")) {
        text_width = layout.measureStyledText(style, blockControlText(document, node, text_buffer[0..])).width;
        minimum_width = 64;
    } else if (equalsIgnoreCase(name, "select") or equalsIgnoreCase(name, "textarea")) {
        text_width = layout.measureStyledText(style, blockControlText(document, node, text_buffer[0..])).width;
        minimum_width = 160;
    } else if (equalsIgnoreCase(name, "svg") or equalsIgnoreCase(name, "img") or equalsIgnoreCase(name, "canvas")) {
        minimum_width = htmlDimension(document.attribute(node, "width"), if (equalsIgnoreCase(name, "svg")) 40 else 16);
    } else {
        text_width = intrinsicTextWidth(layout, document, node, style, 0);
    }
    const natural_width = text_width + horizontal_chrome + horizontal_margin + 12;
    return @max(minimum_width, natural_width);
}

fn flexItemNaturalWidthForViewport(layout: *const Layout, document: *const html.Document, node: u16, style: *const css.ComputedStyle, basis: i32, viewport: Viewport) i32 {
    const em = style.font_size;
    const horizontal_margin = edgesHorizontalPixels(style.margin, basis, em, viewport);
    const horizontal_chrome = edgesHorizontalPixels(style.padding, basis, em, viewport) + edgesHorizontalPixels(style.border, basis, em, viewport);
    const name = document.nodeName(node);
    var text_buffer: [max_control_text_bytes]u8 = undefined;
    const text_width = if (isFormControl(name))
        layout.measureStyledText(style, blockControlText(document, node, text_buffer[0..])).width
    else
        naturalTextWidth(layout, document, node, style, 0);
    const flex_items = if ((style.display == .flex or style.display == .inline_flex) and style.flex_direction == .row)
        directVisibleItemCount(document, node)
    else
        0;
    const item_allowance = if (flex_items > 0) @as(i32, @intCast(flex_items)) * 12 else 12;
    const item_gaps = if (flex_items > 1) @as(i32, @intCast(flex_items - 1)) * style.gap else 0;
    return @max(1, text_width + horizontal_chrome + horizontal_margin + item_allowance + item_gaps);
}

fn directVisibleItemCount(document: *const html.Document, node: u16) usize {
    var count: usize = 0;
    var child = document.nodes[node].first_child;
    while (child != html.none) {
        if (document.nodes[child].kind == .element or (document.nodes[child].kind == .text and hasVisibleText(document.nodeValue(child)))) count += 1;
        child = document.nodes[child].next_sibling;
    }
    return count;
}

fn edgesHorizontalPixels(edges: css.Edges, basis: i32, em: i32, viewport: Viewport) i32 {
    return edges.left.pixelsForViewport(basis, em, 0, viewport.width, viewport.height) +
        edges.right.pixelsForViewport(basis, em, 0, viewport.width, viewport.height);
}

fn intrinsicTextWidth(layout: *const Layout, document: *const html.Document, node: u16, style: *const css.ComputedStyle, depth: usize) i32 {
    if (depth >= max_layout_depth or node >= document.node_count) return 0;
    if (document.nodes[node].kind == .text) return measureLongestTextSegment(layout, style, document.nodeValue(node));
    var maximum: i32 = 0;
    var child = document.nodes[node].first_child;
    while (child != html.none) {
        maximum = @max(maximum, intrinsicTextWidth(layout, document, child, style, depth + 1));
        child = document.nodes[child].next_sibling;
    }
    return maximum;
}

fn naturalTextWidth(layout: *const Layout, document: *const html.Document, node: u16, style: *const css.ComputedStyle, depth: usize) i32 {
    if (depth >= max_layout_depth or node >= document.node_count) return 0;
    if (document.nodes[node].kind == .text) return measureCollapsedText(layout, style, document.nodeValue(node));
    var total: i32 = 0;
    var child = document.nodes[node].first_child;
    while (child != html.none) {
        total = saturatingAdd(total, naturalTextWidth(layout, document, child, style, depth + 1));
        child = document.nodes[child].next_sibling;
    }
    return total;
}

fn collapsedTextColumns(value: []const u8) i32 {
    var columns: i32 = 0;
    var index: usize = 0;
    var pending_space = false;
    while (index < value.len) {
        if (isWhitespace(value[index])) {
            pending_space = columns > 0;
            index += 1;
            continue;
        }
        if (pending_space) columns += 1;
        pending_space = false;
        columns += 1;
        index += utf8SequenceLength(value, index);
    }
    return columns;
}

fn measureCollapsedText(layout: *const Layout, style: *const css.ComputedStyle, value: []const u8) i32 {
    var width: i32 = 0;
    var cursor: usize = 0;
    var have_word = false;
    const space_width = layout.measureStyledText(style, " ").width;
    while (cursor < value.len) {
        while (cursor < value.len and isWhitespace(value[cursor])) cursor += 1;
        if (cursor >= value.len) break;
        if (have_word) width = saturatingAdd(width, space_width);
        const start = cursor;
        while (cursor < value.len and !isWhitespace(value[cursor])) cursor += utf8SequenceLength(value, cursor);
        width = saturatingAdd(width, measureTextWithoutSoftHyphens(layout, style, value[start..cursor]));
        have_word = true;
    }
    return width;
}

fn measureTextWithoutSoftHyphens(layout: *const Layout, style: *const css.ComputedStyle, value: []const u8) i32 {
    var width: i32 = 0;
    var start: usize = 0;
    var cursor: usize = 0;
    while (cursor < value.len) {
        if (cursor + 1 < value.len and value[cursor] == 0xC2 and value[cursor + 1] == 0xAD) {
            if (cursor > start) width = saturatingAdd(width, layout.measureStyledText(style, value[start..cursor]).width);
            cursor += 2;
            start = cursor;
            continue;
        }
        cursor += utf8SequenceLength(value, cursor);
    }
    if (start < value.len) width = saturatingAdd(width, layout.measureStyledText(style, value[start..]).width);
    return width;
}

fn hasVisibleText(value: []const u8) bool {
    for (value) |byte| if (!isWhitespace(byte)) return true;
    return false;
}

fn flexTextNaturalWidth(layout: *const Layout, value: []const u8, style: *const css.ComputedStyle) i32 {
    return @max(1, measureCollapsedText(layout, style, value));
}

fn flexTextMinimumWidth(layout: *const Layout, value: []const u8, style: *const css.ComputedStyle) i32 {
    return @max(1, measureLongestTextSegment(layout, style, value));
}

fn measureLongestTextSegment(layout: *const Layout, style: *const css.ComputedStyle, value: []const u8) i32 {
    var maximum: i32 = 0;
    var start: usize = 0;
    var cursor: usize = 0;
    while (cursor <= value.len) {
        const at_end = cursor == value.len;
        const at_space = !at_end and isWhitespace(value[cursor]);
        const at_soft_hyphen = !at_end and cursor + 1 < value.len and value[cursor] == 0xC2 and value[cursor + 1] == 0xAD;
        if (at_end or at_space or at_soft_hyphen) {
            if (cursor > start) maximum = @max(maximum, layout.measureStyledText(style, value[start..cursor]).width);
            if (at_end) break;
            cursor += if (at_soft_hyphen) 2 else 1;
            start = cursor;
            continue;
        }
        cursor += utf8SequenceLength(value, cursor);
    }
    return maximum;
}

fn longestTextSegmentColumns(value: []const u8) i32 {
    var maximum: i32 = 0;
    var current: i32 = 0;
    var cursor: usize = 0;
    while (cursor < value.len) {
        if (isWhitespace(value[cursor])) {
            maximum = @max(maximum, current);
            current = 0;
            cursor += 1;
            continue;
        }
        if (cursor + 1 < value.len and value[cursor] == 0xC2 and value[cursor + 1] == 0xAD) {
            maximum = @max(maximum, current);
            current = 0;
            cursor += 2;
            continue;
        }
        cursor += utf8SequenceLength(value, cursor);
        current += 1;
    }
    return @max(maximum, current);
}

fn selectedOptionText(document: *const html.Document, select_node: u16, out: []u8) []const u8 {
    var first_node: u16 = html.none;
    var selected_node: u16 = html.none;
    var index: usize = 0;
    while (index < document.node_count) : (index += 1) {
        const node: u16 = @intCast(index);
        if (document.nodes[node].kind != .element or !equalsIgnoreCase(document.nodeName(node), "option")) continue;
        if (!isDescendantOf(document, node, select_node)) continue;
        if (first_node == html.none) first_node = node;
        if (document.attribute(node, "selected") != null) {
            selected_node = node;
            break;
        }
    }
    const wanted = if (selected_node != html.none) selected_node else first_node;
    if (wanted == html.none) return "";
    return document.textContent(wanted, out) catch "";
}

fn isDescendantOf(document: *const html.Document, node_input: u16, ancestor: u16) bool {
    var node = document.nodes[node_input].parent;
    var depth: usize = 0;
    while (node != html.none and depth < max_layout_depth) : (depth += 1) {
        if (node == ancestor) return true;
        node = document.nodes[node].parent;
    }
    return false;
}

fn approximateCharWidth(font_size: i32, weight: u16) i32 {
    const weighted: i32 = if (weight >= 700) 1 else 0;
    return @max(8, @divTrunc(font_size * 3 + 2, 5) + weighted);
}

fn combineTextMetrics(target: *TextMetrics, addition: TextMetrics) void {
    target.valid = target.valid and addition.valid;
    target.width = saturatingAdd(target.width, @max(0, addition.width));
    target.height = @max(target.height, addition.height);
    const target_descent = @max(0, target.line_height - target.baseline);
    const addition_descent = @max(0, addition.line_height - addition.baseline);
    target.baseline = @max(target.baseline, addition.baseline);
    target.line_height = saturatingAdd(target.baseline, @max(target_descent, addition_descent));
    target.visible_bytes +|= addition.visible_bytes;
}

const DecodedScalar = struct {
    codepoint: u32,
    consumed: usize,
};

fn decodeUtf8Scalar(value: []const u8, start: usize) DecodedScalar {
    if (start >= value.len) return .{ .codepoint = 0xFFFD, .consumed = 0 };
    const count = utf8SequenceLength(value, start);
    const first = value[start];
    if (count == 1 or first < 0x80) return .{ .codepoint = first, .consumed = 1 };
    var scalar: u32 = first & (@as(u8, 0x7F) >> @intCast(count));
    var index: usize = 1;
    while (index < count) : (index += 1) {
        const continuation = value[start + index];
        if ((continuation & 0xC0) != 0x80) return .{ .codepoint = 0xFFFD, .consumed = 1 };
        scalar = (scalar << 6) | (continuation & 0x3F);
    }
    if (scalar > 0x10FFFF or (scalar >= 0xD800 and scalar <= 0xDFFF)) return .{ .codepoint = 0xFFFD, .consumed = 1 };
    return .{ .codepoint = scalar, .consumed = count };
}

fn saturatingAdd(left: i32, right: i32) i32 {
    if (right > 0 and left > std.math.maxInt(i32) - right) return std.math.maxInt(i32);
    if (right < 0 and left < std.math.minInt(i32) - right) return std.math.minInt(i32);
    return left + right;
}

fn htmlDimension(raw: ?[]const u8, fallback: i32) i32 {
    const value = std.fmt.parseInt(i32, raw orelse return fallback, 10) catch return fallback;
    return clamp(value, 1, 512);
}

fn optionalHtmlDimension(raw: ?[]const u8) ?u32 {
    const value = std.fmt.parseInt(u32, raw orelse return null, 10) catch return null;
    if (value == 0) return null;
    return @min(value, 4096);
}

fn unicodeColumns(value: []const u8) i32 {
    var columns: i32 = 0;
    var cursor: usize = 0;
    while (cursor < value.len) {
        cursor += utf8SequenceLength(value, cursor);
        columns += 1;
    }
    return columns;
}

fn utf8ByteIndexForColumns(value: []const u8, start: usize, columns: usize) usize {
    var cursor = start;
    var count: usize = 0;
    while (cursor < value.len and count < columns) : (count += 1) cursor += utf8SequenceLength(value, cursor);
    return cursor;
}

fn utf8SequenceLength(value: []const u8, start: usize) usize {
    if (start >= value.len) return 0;
    const first = value[start];
    const expected: usize = if (first < 0x80) 1 else if (first < 0xE0) 2 else if (first < 0xF0) 3 else 4;
    return @min(expected, value.len - start);
}

fn mixInt(hash: *u64, value: anytype) void {
    var remaining: u64 = switch (@typeInfo(@TypeOf(value))) {
        .int => if (@typeInfo(@TypeOf(value)).int.signedness == .signed) @bitCast(@as(i64, @intCast(value))) else @intCast(value),
        .@"enum" => @intFromEnum(value),
        else => @compileError("unsupported hash value"),
    };
    var index: usize = 0;
    while (index < 8) : (index += 1) {
        hash.* ^= @truncate(remaining);
        hash.* *%= 1099511628211;
        remaining >>= 8;
    }
}

fn mixCssLength(hash: *u64, value: css.Length) void {
    mixInt(hash, value.kind);
    mixInt(hash, value.value);
    mixInt(hash, value.calc_px);
    mixInt(hash, value.calc_percent);
    mixInt(hash, value.calc_em);
    mixInt(hash, value.calc_rem);
    mixInt(hash, value.calc_vw);
    mixInt(hash, value.calc_vh);
}

fn mixBytes(hash: *u64, value: []const u8) void {
    for (value) |byte| {
        hash.* ^= byte;
        hash.* *%= 1099511628211;
    }
}

fn equalsIgnoreCase(left: []const u8, right: []const u8) bool {
    return std.ascii.eqlIgnoreCase(left, right);
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and equalsIgnoreCase(value[0..prefix.len], prefix);
}

fn contentFunctionEnd(value: []const u8, opening: usize) ?usize {
    if (opening >= value.len or value[opening] != '(') return null;
    var depth: usize = 1;
    var quote: u8 = 0;
    var cursor = opening + 1;
    while (cursor < value.len) : (cursor += 1) {
        const byte = value[cursor];
        if (quote != 0) {
            if (byte == '\\' and cursor + 1 < value.len) cursor += 1 else if (byte == quote) quote = 0;
            continue;
        }
        if (byte == '"' or byte == '\'') {
            quote = byte;
        } else if (byte == '(') {
            depth += 1;
        } else if (byte == ')') {
            depth -= 1;
            if (depth == 0) return cursor;
        }
    }
    return null;
}

fn trimContentToken(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isWhitespace(value[start])) : (start += 1) {}
    while (end > start and isWhitespace(value[end - 1])) : (end -= 1) {}
    var cursor = start;
    while (cursor < end and !isWhitespace(value[cursor]) and value[cursor] != ',') : (cursor += 1) {}
    return value[start..cursor];
}

fn appendGeneratedContent(out: []u8, written: *usize, value: []const u8) bool {
    if (written.* > out.len or value.len > out.len - written.*) return false;
    @memcpy(out[written.* .. written.* + value.len], value);
    written.* += value.len;
    return true;
}

fn decodeCssContentString(value: []const u8, out: []u8) []const u8 {
    var read: usize = 0;
    var written: usize = 0;
    while (read < value.len and written < out.len) {
        if (value[read] != '\\') {
            out[written] = value[read];
            written += 1;
            read += 1;
            continue;
        }
        read += 1;
        if (read >= value.len) break;
        if (value[read] == '\n' or value[read] == '\r' or value[read] == '\x0C') {
            read += 1;
            continue;
        }
        if (contentHexDigit(value[read]) != null) {
            var scalar: u32 = 0;
            var count: usize = 0;
            while (read < value.len and count < 6) : (count += 1) {
                const digit = contentHexDigit(value[read]) orelse break;
                scalar = scalar * 16 + digit;
                read += 1;
            }
            if (read < value.len and isWhitespace(value[read])) read += 1;
            if (scalar == 0 or scalar > 0x10FFFF or (scalar >= 0xD800 and scalar <= 0xDFFF)) scalar = 0xFFFD;
            var encoded: [4]u8 = undefined;
            const length = std.unicode.utf8Encode(@intCast(scalar), encoded[0..]) catch 0;
            if (length > out.len - written) break;
            @memcpy(out[written .. written + length], encoded[0..length]);
            written += length;
            continue;
        }
        out[written] = value[read];
        written += 1;
        read += 1;
    }
    return out[0..written];
}

fn contentHexDigit(value: u8) ?u32 {
    if (value >= '0' and value <= '9') return value - '0';
    if (value >= 'a' and value <= 'f') return value - 'a' + 10;
    if (value >= 'A' and value <= 'F') return value - 'A' + 10;
    return null;
}

fn isWhitespace(value: u8) bool {
    return value == ' ' or value == '\t' or value == '\r' or value == '\n' or value == 0x0C;
}

fn nonNegative(value: i32) i32 {
    return @max(0, value);
}

fn clamp(value: i32, minimum: i32, maximum: i32) i32 {
    return @min(maximum, @max(minimum, value));
}

test "layout creates deterministic responsive structural render lists" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>" ++
            "body { color:#202020; font-family:Terminal; } " ++
            ".cards { display:grid; grid-template-columns:repeat(2, 1fr); gap:8px; } " ++
            ".card { padding:4px; border-width:1px; border-color:#808080; background:#eeeeee; } " ++
            "a:link { color:#0000cc; } .card::before { content:'* '; color:#800000; }" ++
            "</style><body><h1>Responsive</h1><div class=cards>" ++
            "<div class=card>Alpha beta gamma delta</div><div class=card><a href=/next>Unicode Euro €</a></div>" ++
            "</div><p>One two three four five six seven eight nine ten.</p></body>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var narrow = Layout{};
    const narrow_stats = try narrow.reflow(&document, &sheet, .{ .width = 280, .height = 160 });
    var wide = Layout{};
    const wide_stats = try wide.reflow(&document, &sheet, .{ .width = 640, .height = 300 });
    try std.testing.expect(narrow_stats.render_ops > 10);
    try std.testing.expect(wide_stats.render_ops > 10);
    try std.testing.expect(narrow_stats.structural_hash != wide_stats.structural_hash);
    var repeat = Layout{};
    const repeat_stats = try repeat.reflow(&document, &sheet, .{ .width = 280, .height = 160 });
    try std.testing.expectEqual(narrow_stats.structural_hash, repeat_stats.structural_hash);
    try std.testing.expect(narrow_stats.content_height >= 160);
}

test "layout supports flex positioning clipping metadata and long Unicode wrapping" {
    var document = html.Document{};
    _ = try document.parse(
        "<style>.row{display:flex;gap:3px}.row div{flex-grow:1}.fixed{position:fixed;top:2px;left:3px}</style>" ++
            "<body><div class=row><div>ABCDEFGHIJKLMN</div><div>äöü世界</div></div><span class=fixed>F</span></body>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    const stats = try layout.reflow(&document, &sheet, .{ .width = 120, .height = 80 });
    try std.testing.expect(stats.render_ops >= 3);
    var found_fixed = false;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        if (layout.ops[index].fixed) found_fixed = true;
    }
    try std.testing.expect(found_fixed);
}

test "interactive reflow applies focus hover and active pseudo classes" {
    var document = html.Document{};
    _ = try document.parse(
        "<style>input:focus{color:#ff0000}a:hover{color:#00aa00}a:active{font-weight:700}</style>" ++
            "<body><form><input name=q value=Query><a href=/next>Next</a></form></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const input = document.findFirstElement("input").?;
    const link = document.findFirstElement("a").?;
    var layout = Layout{};
    const normal = try layout.reflow(&document, &sheet, .{ .width = 320, .height = 160 });
    const interactive = try layout.reflowInteractive(
        &document,
        &sheet,
        .{ .width = 320, .height = 160 },
        .{ .focused_node = input, .hovered_node = link, .active_node = link },
    );
    try std.testing.expect(normal.structural_hash != interactive.structural_hash);
}

test "consent controls ignore hidden fields honor media width and collapse selects" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>" ++
            ".action{display:inline-flex;height:40px;min-width:182px}" ++
            "@media only screen and (max-width:480px){.wide{display:none}.narrow{display:block}}" ++
            "@media not screen and (max-width:480px){.wide{display:block}.narrow{display:none}}" ++
            "</style><body>" ++
            "<div class=wide><form style='display:inline'><input type=hidden name=token value=wide-secret>" ++
            "<input type=submit class=action value='Wide choice'></form></div>" ++
            "<div class=narrow><form style='display:block'><input type=hidden name=token value=narrow-secret>" ++
            "<input type=submit class=action value='Narrow choice'></form></div>" ++
            "<select><option>English</option><option selected>Deutsch</option><option>Francais</option></select>" ++
            "</body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);

    var wide = Layout{};
    _ = try wide.reflow(&document, &sheet, .{ .width = 800, .height = 300 });
    try std.testing.expect(layoutContainsText(&wide, "Wide choice"));
    try std.testing.expect(!layoutContainsText(&wide, "Narrow choice"));
    try std.testing.expect(!layoutContainsText(&wide, "wide-secret"));
    try std.testing.expect(!layoutContainsText(&wide, "narrow-secret"));
    try std.testing.expect(layoutContainsText(&wide, "Deutsch"));
    try std.testing.expect(!layoutContainsText(&wide, "English"));
    try std.testing.expect(!layoutContainsText(&wide, "Francais"));

    var found_sized_submit = false;
    var found_control_box = false;
    var index: usize = 0;
    while (index < wide.op_count) : (index += 1) {
        const op = wide.ops[index];
        if (op.kind == .text and std.mem.eql(u8, wide.text(op), "Wide choice")) {
            found_sized_submit = op.rect.w == 182 and op.rect.h == 19;
        }
        if (op.kind == .control and document.nodeName(op.node).len > 0 and std.mem.eql(u8, document.attribute(op.node, "value") orelse "", "Wide choice")) {
            found_control_box = op.rect.w == 192 and op.rect.h == 46 and
                op.border.top == 1 and op.border.right == 1 and op.border.bottom == 1 and op.border.left == 1 and
                op.padding.top == 2 and op.padding.right == 4 and op.padding.bottom == 2 and op.padding.left == 4;
        }
    }
    try std.testing.expect(found_sized_submit);
    try std.testing.expect(found_control_box);

    var narrow = Layout{};
    _ = try narrow.reflow(&document, &sheet, .{ .width = 360, .height = 300 });
    try std.testing.expect(!layoutContainsText(&narrow, "Wide choice"));
    try std.testing.expect(layoutContainsText(&narrow, "Narrow choice"));
}

test "nested button labels produce one correctly sized control text run" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><form><button name=choice value=reject>" ++
            "<span>Reject <strong>all</strong></span></button></form></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 360, .height = 200 });
    try std.testing.expect(layoutContainsText(&layout, "Reject all"));
    try std.testing.expect(!layoutContainsText(&layout, "Button"));
}

test "nested block containers do not create synthetic empty lines" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body,div,main,header{margin:0;padding:0}</style>" ++
            "<body><header><div><div>Top</div></div></header>" ++
            "<main><div><div>Bottom</div></div></main></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 320, .height = 100 });

    var top_y: ?i32 = null;
    var bottom_y: ?i32 = null;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text) continue;
        if (std.mem.eql(u8, layout.text(op), "Top")) top_y = op.rect.y;
        if (std.mem.eql(u8, layout.text(op), "Bottom")) bottom_y = op.rect.y;
    }
    try std.testing.expect(top_y != null and bottom_y != null);
    try std.testing.expectEqual(@as(i32, 19), bottom_y.? - top_y.?);
}

test "screen reader clip hides fallback text without reserving page space" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0}</style>" ++
            "<body><a class=sr-only href=#main>Skip To Content</a><main id=main>Visible</main></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 320, .height = 120 });
    try std.testing.expect(!layoutContainsText(&layout, "Skip"));
    try std.testing.expect(!layoutContainsText(&layout, "To"));
    try std.testing.expect(!layoutContainsText(&layout, "Content"));
    try std.testing.expect(layoutContainsText(&layout, "Visible"));
}

test "flex basis keeps a growing search field beside its intrinsic button" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>.row{display:flex;gap:8px}.query{display:block;flex:1 1 0%;width:100%;border-width:1px}.submit{display:block;border-width:1px}</style>" ++
            "<body><form class=row><input class=query value=R4OS><button class=submit>Search</button></form></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 360, .height = 120 });

    var query_rect: ?Rect = null;
    var button_rect: ?Rect = null;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text) continue;
        if (std.mem.eql(u8, layout.text(op), "R4OS")) query_rect = op.rect;
        if (std.mem.eql(u8, layout.text(op), "Search")) button_rect = op.rect;
    }
    try std.testing.expect(query_rect != null and button_rect != null);
    try std.testing.expect(query_rect.?.w > button_rect.?.w);
    try std.testing.expect(query_rect.?.right() <= button_rect.?.x);
}

test "automatic margins center fixed blocks and flex space between keeps readable columns" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.center{display:block;width:400px;margin:0 auto}" ++
            ".row{display:flex;width:800px;justify-content:space-between}.column{display:block;max-width:300px}</style>" ++
            "<body><div class=center>Centered</div><div class=row>" ++
            "<div class=column>Alpha alpha alpha alpha alpha alpha alpha alpha alpha</div>" ++
            "<div class=column>Beta beta beta beta beta beta beta beta beta</div></div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 800, .height = 180 });

    var centered_x: ?i32 = null;
    var alpha_x: ?i32 = null;
    var beta_x: ?i32 = null;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text) continue;
        const value = layout.text(op);
        if (std.mem.eql(u8, value, "Centered")) centered_x = op.rect.x;
        if (alpha_x == null and std.mem.eql(u8, value, "Alpha")) alpha_x = op.rect.x;
        if (beta_x == null and std.mem.eql(u8, value, "Beta")) beta_x = op.rect.x;
    }
    try std.testing.expectEqual(@as(?i32, 200), centered_x);
    try std.testing.expect(alpha_x != null and beta_x != null);
    try std.testing.expect(beta_x.? - alpha_x.? >= 450);
}

test "absolute helper inputs stay out of inline document flow" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>.field{position:absolute;left:0;top:0;width:100%;height:100%;border-width:0}</style>" ++
            "<body><p>IBAN: <span>DE09 3702</span><input class=field readonly value=DE093702></p><p>After</p></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 400, .height = 120 });
    try std.testing.expect(!layoutContainsText(&layout, "DE093702"));
    try std.testing.expect(layoutContainsText(&layout, "After"));
    try std.testing.expect(layout.content_height < 200);
}

test "direct flex text is centered and small CSS text keeps drawable spacing" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.button{display:flex;width:194px;height:28px;align-items:center;justify-content:center}" ++
            ".small{font-size:12px}</style><body><a class=button href=/donate>Online Spenden</a>" ++
            "<p class=small>Prioritizes non-commercial content</p></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 400, .height = 140 });

    var online_x: ?i32 = null;
    var prioritizes: ?Rect = null;
    var commercial: ?Rect = null;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text) continue;
        const value = layout.text(op);
        if (std.mem.eql(u8, value, "Online")) online_x = op.rect.x;
        if (std.mem.eql(u8, value, "Prioritizes")) prioritizes = op.rect;
        if (std.mem.eql(u8, value, "non-commercial")) commercial = op.rect;
    }
    try std.testing.expect(online_x != null and online_x.? > 20);
    try std.testing.expect(prioritizes != null and commercial != null);
    try std.testing.expect(commercial.?.x >= prioritizes.?.x + 11 * 8 + 8);
}

test "soft hyphens create optional breaks without visible glyphs" {
    var document = html.Document{};
    _ = try document.parse("<!doctype html><body><p>2&shy;0</p></body>", .{});
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 320, .height = 100 });

    var two_rect: ?Rect = null;
    var zero_rect: ?Rect = null;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text) continue;
        const value = layout.text(op);
        try std.testing.expect(std.mem.indexOf(u8, value, "\xC2\xAD") == null);
        if (std.mem.eql(u8, value, "2")) two_rect = op.rect;
        if (std.mem.eql(u8, value, "0")) zero_rect = op.rect;
    }
    try std.testing.expect(two_rect != null and zero_rect != null);
    try std.testing.expectEqual(two_rect.?.right(), zero_rect.?.x);
}

test "nested search result flex utilities preserve a usable title width" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>" ++
            ".flex{display:flex}.flex-row{flex-direction:row}.flex-col{flex-direction:column}" ++
            ".grow{flex-grow:1}.flex-1{flex:1 1 0%}.p-4{padding:16px}.ml-5{margin-left:20px}" ++
            "</style><body><div class='p-4 flex'><div class='flex flex-col grow'>" ++
            "<div class=flex><div class='flex flex-col grow'><div class='flex flex-row'>" ++
            "<svg width=40 height=40></svg><div class='flex grow'><div class=flex-1>" ++
            "<h2><a href=/result>2&shy;0&shy;1&shy;8&shy;-&shy;stav-&shy;0&shy;5</a></h2>" ++
            "</div></div></div></div><div class='flex flex-col ml-5'></div></div></div></div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 900, .height = 180 });
    const link = document.findFirstElement("a").?;
    var title_y: ?i32 = null;
    var title_runs: usize = 0;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text or op.node != link) continue;
        title_runs += 1;
        if (title_y) |expected| try std.testing.expectEqual(expected, op.rect.y) else title_y = op.rect.y;
    }
    try std.testing.expect(title_runs >= 8);
}

test "nowrap text overflows one line and formatted button labels collapse" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div style='width:40px'><span style='white-space:nowrap'>Long label</span></div>" ++
            "<button>\n  Search\n</button></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 240, .height = 100 });
    var long_rect: ?Rect = null;
    var label_rect: ?Rect = null;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind != .text) continue;
        if (std.mem.eql(u8, layout.text(op), "Long")) long_rect = op.rect;
        if (std.mem.eql(u8, layout.text(op), "label")) label_rect = op.rect;
    }
    try std.testing.expect(long_rect != null and label_rect != null);
    try std.testing.expectEqual(long_rect.?.y, label_rect.?.y);
    try std.testing.expect(layoutContainsText(&layout, "Search"));
    try std.testing.expect(!layoutContainsText(&layout, "\n  Search\n"));
}

test "web images use intrinsic ratio and show alternatives only after terminal failure" {
    const ResolverContext = struct { ready_node: u16, svg_node: u16, loading_node: u16 };
    const Resolver = struct {
        fn resolve(raw: ?*anyopaque, node: u16) ImageIntrinsic {
            const context: *const ResolverContext = @ptrCast(@alignCast(raw orelse return .{}));
            return if (node == context.ready_node)
                .{ .state = .ready, .width = 200, .height = 100 }
            else if (node == context.svg_node)
                .{ .state = .ready, .width = 120, .height = 80 }
            else if (node == context.loading_node)
                .{ .state = .loading }
            else
                .{ .state = .failed };
        }
    };
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><img src='ready.png' style='width:100px' alt='ready'>" ++
            "<img src='loading.png' alt='not-yet'><img src='broken.png' width='80' height='40' alt='fallback'>" ++
            "<img src='silent.png' alt=''><img src='unnamed.png'>" ++
            "<svg style='width:60px' viewBox='0 0 120 80'><rect width='120' height='80'/></svg></body>",
        .{},
    );
    var ready_node: u16 = html.none;
    var failed_node: u16 = html.none;
    var loading_node: u16 = html.none;
    var svg_node: u16 = html.none;
    for (document.nodes[0..document.node_count], 0..) |node, index| {
        if (node.kind == .element and equalsIgnoreCase(document.nodeName(@intCast(index)), "svg")) {
            svg_node = @intCast(index);
            continue;
        }
        if (node.kind != .element or !equalsIgnoreCase(document.nodeName(@intCast(index)), "img")) continue;
        const src = document.attribute(@intCast(index), "src") orelse continue;
        if (std.mem.eql(u8, src, "ready.png")) ready_node = @intCast(index);
        if (std.mem.eql(u8, src, "broken.png")) failed_node = @intCast(index);
        if (std.mem.eql(u8, src, "loading.png")) loading_node = @intCast(index);
    }
    try std.testing.expect(ready_node != html.none and failed_node != html.none and loading_node != html.none and svg_node != html.none);
    var resolver_context = ResolverContext{ .ready_node = ready_node, .svg_node = svg_node, .loading_node = loading_node };
    var sheet = css.Stylesheet{};
    try sheet.rebuildDocumentStyles(&document, "");
    var layout = Layout{};
    _ = try layout.reflowInteractiveWithImages(
        &document,
        &sheet,
        .{ .width = 640, .height = 480 },
        .{},
        .{ .context = &resolver_context, .resolve = Resolver.resolve },
    );
    var ready: ?RenderOp = null;
    var failed: ?RenderOp = null;
    var svg: ?RenderOp = null;
    var fallback = false;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind == .image and op.node == ready_node) ready = op;
        if (op.kind == .image and op.node == failed_node) failed = op;
        if (op.kind == .image and op.node == svg_node) svg = op;
        if (op.kind == .text and std.mem.eql(u8, layout.text(op), "fallback")) fallback = true;
    }
    try std.testing.expect(ready != null);
    try std.testing.expectEqual(@as(i32, 100), ready.?.rect.w);
    try std.testing.expectEqual(@as(i32, 50), ready.?.rect.h);
    try std.testing.expect(failed != null);
    try std.testing.expectEqual(@as(i32, 80), failed.?.rect.w);
    try std.testing.expectEqual(@as(i32, 40), failed.?.rect.h);
    try std.testing.expect(svg != null);
    try std.testing.expectEqual(@as(i32, 60), svg.?.rect.w);
    try std.testing.expectEqual(@as(i32, 40), svg.?.rect.h);
    try std.testing.expect(fallback);
    try std.testing.expect(!layoutContainsText(&layout, "not-yet"));
    try std.testing.expect(layoutContainsText(&layout, "[broken image]"));
}

test "CSS background image render metadata preserves paint order and image roles" {
    const ResolverContext = struct {
        content_calls: usize = 0,
        background_calls: usize = 0,
    };
    const Resolver = struct {
        fn resolve(raw: ?*anyopaque, _: u16, role: ImageRole) ImageIntrinsic {
            const context: *ResolverContext = @ptrCast(@alignCast(raw orelse return .{}));
            return switch (role) {
                .content => result: {
                    context.content_calls += 1;
                    break :result .{ .state = .ready, .width = 64, .height = 32 };
                },
                .css_background => result: {
                    context.background_calls += 1;
                    break :result .{ .state = .failed, .width = 11, .height = 7 };
                },
            };
        }
    };

    var document = html.Document{};
    _ = try document.parse("<!doctype html><body><img id=dual src=content.png alt='content fallback'></body>", .{});
    var sheet = css.Stylesheet{};
    try sheet.appendWithBase(
        "#dual{display:block;box-sizing:border-box;width:80px;height:40px;background-color:#123456;" ++
            "background-image:image-set(url(tile.png) 1x,url(tile@2x.png) 2x);background-repeat:repeat-x;" ++
            "background-position:25% 75%;background-size:20px 50%;border:2px solid #abcdef;" ++
            "border-radius:12px 8px 6px 4px}",
        "https://example.test/assets/site.css",
    );
    const dual = document.findElementById("dual").?;
    var resolver_context = ResolverContext{};
    var layout = Layout{};
    _ = try layout.reflowInteractiveWithImages(
        &document,
        &sheet,
        .{ .width = 240, .height = 100 },
        .{},
        .{ .context = &resolver_context, .resolve_role = Resolver.resolve },
    );

    var color_index: ?usize = null;
    var image_index: ?usize = null;
    var css_index: ?usize = null;
    var border_index: ?usize = null;
    var image_op: ?RenderOp = null;
    var css_op: ?RenderOp = null;
    for (layout.ops[0..layout.op_count], 0..) |op, index| {
        if (op.node != dual) continue;
        switch (op.kind) {
            .background => color_index = index,
            .css_background => {
                css_index = index;
                css_op = op;
            },
            .border => {
                if (border_index == null) border_index = index;
            },
            .image => {
                image_index = index;
                image_op = op;
            },
            else => {},
        }
    }

    try std.testing.expect(@intFromEnum(RenderKind.background) < @intFromEnum(RenderKind.css_background));
    try std.testing.expect(@intFromEnum(RenderKind.css_background) < @intFromEnum(RenderKind.border));
    try std.testing.expect(color_index != null and css_index != null and border_index != null and image_index != null);
    try std.testing.expect(color_index.? < css_index.? and css_index.? < border_index.?);
    try std.testing.expect(image_op != null and css_op != null);
    try std.testing.expectEqual(ImageRole.content, image_op.?.image_role);
    try std.testing.expectEqual(ImageState.ready, image_op.?.image_intrinsic.state);
    try std.testing.expectEqual(@as(u32, 64), image_op.?.image_intrinsic.width);
    try std.testing.expectEqual(ImageRole.css_background, css_op.?.image_role);
    try std.testing.expectEqual(ImageState.failed, css_op.?.image_intrinsic.state);
    try std.testing.expectEqual(@as(u32, 11), css_op.?.image_intrinsic.width);
    try std.testing.expectEqualStrings("image-set(url(tile.png) 1x,url(tile@2x.png) 2x)", css_op.?.css_background.raw_value);
    try std.testing.expectEqualStrings("https://example.test/assets/site.css", css_op.?.css_background.base_url);
    try std.testing.expectEqual(css.BackgroundRepeat.repeat_x, css_op.?.css_background.repeat);
    try std.testing.expectEqual(css.LengthKind.percent, css_op.?.css_background.position.x.kind);
    try std.testing.expectEqual(@as(i32, 25), css_op.?.css_background.position.x.value);
    try std.testing.expectEqual(css.LengthKind.percent, css_op.?.css_background.position.y.kind);
    try std.testing.expectEqual(@as(i32, 75), css_op.?.css_background.position.y.value);
    try std.testing.expectEqual(css.BackgroundSizeKind.explicit, css_op.?.css_background.size.kind);
    try std.testing.expectEqual(css.LengthKind.px, css_op.?.css_background.size.width.kind);
    try std.testing.expectEqual(@as(i32, 20), css_op.?.css_background.size.width.value);
    try std.testing.expectEqual(css.LengthKind.percent, css_op.?.css_background.size.height.kind);
    try std.testing.expectEqual(@as(i32, 50), css_op.?.css_background.size.height.value);
    try std.testing.expectEqual(PixelRadii{
        .top_left = .{ .x = 12, .y = 12 },
        .top_right = .{ .x = 8, .y = 8 },
        .bottom_right = .{ .x = 6, .y = 6 },
        .bottom_left = .{ .x = 4, .y = 4 },
    }, css_op.?.radii);
    try std.testing.expect(resolver_context.content_calls > 0 and resolver_context.background_calls > 0);
    try std.testing.expect(!layoutContainsText(&layout, "content fallback"));
}

test "CSS background image ops require visible supported single layer values" {
    const Resolver = struct {
        fn resolve(_: ?*anyopaque, _: u16, role: ImageRole) ImageIntrinsic {
            return if (role == .css_background) .{ .state = .failed } else .{};
        }
    };
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div id=url alt='url fallback'></div><div id=set alt='set fallback'></div>" ++
            "<div id=hidden></div><div id=unsupported></div><div id=none></div><div id=gone></div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.append(
        "div{display:block;height:10px}#url{background-image:url(tile.png);background-repeat:no-repeat}" ++
            "#set{background-image:image-set(url(one.png) 1x,url(two.png) 2x)}" ++
            "#hidden{visibility:hidden;background-image:url(hidden.png)}" ++
            "#unsupported{background-image:linear-gradient(red,blue)}#none{background-image:none}" ++
            "#gone{display:none;background-image:url(gone.png)}",
    );
    var layout = Layout{};
    _ = try layout.reflowInteractiveWithImages(
        &document,
        &sheet,
        .{ .width = 200, .height = 100 },
        .{},
        .{ .resolve_role = Resolver.resolve },
    );

    const url_node = document.findElementById("url").?;
    const set_node = document.findElementById("set").?;
    var css_count: usize = 0;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind != .css_background) continue;
        css_count += 1;
        try std.testing.expect(op.node == url_node or op.node == set_node);
        try std.testing.expectEqual(ImageRole.css_background, op.image_role);
    }
    try std.testing.expectEqual(@as(usize, 2), css_count);
    try std.testing.expect(!layoutContainsText(&layout, "url fallback"));
    try std.testing.expect(!layoutContainsText(&layout, "set fallback"));
}

test "viewport flex shell distributes header main and footer without site knowledge" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>" ++
            "html,body{margin:0;min-height:100vh}" ++
            "body{display:flex;flex-direction:column;min-height:100vh}" ++
            "header{display:flex;height:48px;box-sizing:border-box;padding:0 20px;align-items:center;background:#eeeeee}" ++
            ".right{display:flex;margin-left:auto;gap:12px}" ++
            "main{display:flex;flex:1 1 auto;justify-content:center;align-items:center}" ++
            ".panel{display:block;width:calc(100% - 64px);max-width:600px;margin:0 auto}" ++
            ".actions{display:flex;justify-content:center;gap:8px}" ++
            "footer{display:flex;flex-direction:column;background:#e0e0e0;border-top-width:1px;border-color:#202020}" ++
            ".footer-row{display:flex;justify-content:space-between;padding:8px 20px;box-sizing:border-box}" ++
            "</style><body>" ++
            "<header><div>Brand</div><div class=right><span>Help</span><span>Account</span></div></header>" ++
            "<main><section class=panel><h1>Neutral Search</h1><div class=actions><button>Search</button><button>Lucky</button></div></section></main>" ++
            "<footer><div class=footer-row><span>Country</span><span>Climate</span></div>" ++
            "<div class=footer-row><span>Advertising</span><span>Privacy</span></div></footer>" ++
            "</body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 800, .height = 600 });

    var brand: ?Rect = null;
    var account: ?Rect = null;
    var title: ?Rect = null;
    var privacy: ?Rect = null;
    var footer_background: ?Rect = null;
    var footer_rule: ?Rect = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind == .text) {
            const value = layout.text(op);
            if (std.mem.eql(u8, value, "Brand")) brand = op.rect;
            if (std.mem.eql(u8, value, "Account")) account = op.rect;
            if (std.mem.eql(u8, value, "Neutral")) title = op.rect;
            if (std.mem.eql(u8, value, "Privacy")) privacy = op.rect;
        }
        if (op.kind == .background and op.color == 0xE0E0E0 and op.rect.w == 800) footer_background = op.rect;
        if (op.kind == .border and op.color == 0x202020 and op.rect.w == 800) footer_rule = op.rect;
    }
    try std.testing.expect(brand != null);
    try std.testing.expect(account != null);
    try std.testing.expect(title != null);
    try std.testing.expect(privacy != null);
    try std.testing.expectEqual(@as(i32, 20), brand.?.x);
    try std.testing.expect(account.?.x > 680);
    try std.testing.expectEqual(@as(i32, 100), title.?.x);
    try std.testing.expect(title.?.y > 180 and title.?.y < 400);
    try std.testing.expect(privacy.?.y > 520);
    try std.testing.expect(footer_background != null and footer_rule != null);
    try std.testing.expectEqual(@as(i32, 600), footer_background.?.bottom());
    try std.testing.expectEqual(footer_background.?.y, footer_rule.?.y);
    try std.testing.expectEqual(@as(i32, 600), layout.content_height);

    _ = try layout.reflow(&document, &sheet, .{ .width = 480, .height = 600 });
    var narrow_title: ?Rect = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind == .text and std.mem.eql(u8, layout.text(op), "Neutral")) narrow_title = op.rect;
    }
    try std.testing.expectEqual(@as(?i32, 32), if (narrow_title) |rect| rect.x else null);
    try std.testing.expectEqual(@as(i32, 600), layout.content_height);
}

test "center aligns replaced content and inline blocks remain atomic" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.field,.action{display:inline-block;margin-left:4px}.field{background-color:#dddddd}" ++
            ".box{display:block;background-color:#eeeeee;border-width:1px}.query{width:400px}</style>" ++
            "<body><center><div><img id=logo width=200 height=60 alt=Brand></div><form>" ++
            "<span class=field id=querybox><span class=box><input class=query value=Query></span></span><br>" ++
            "<span class=action><span class=box id=first><input type=submit value=Search></span></span>" ++
            "<span class=action><span class=box id=second><input type=submit value=Lucky></span></span>" ++
            "</form></center></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 800, .height = 300 });

    const logo_node = document.findElementById("logo").?;
    const query_node = document.findElementById("querybox").?;
    const first_node = document.findElementById("first").?;
    const second_node = document.findElementById("second").?;
    var logo: ?Rect = null;
    var query: ?Rect = null;
    var first: ?Rect = null;
    var second: ?Rect = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.node == logo_node and op.kind == .image) logo = op.rect;
        if (op.node == query_node and op.kind == .background) query = op.rect;
        if (op.node == first_node and op.kind == .background) first = op.rect;
        if (op.node == second_node and op.kind == .background) second = op.rect;
    }
    try std.testing.expect(logo != null and query != null and first != null and second != null);
    try std.testing.expectEqual(@as(i32, 300), logo.?.x);
    try std.testing.expect(query.?.x > 190 and query.?.x < 210);
    try std.testing.expectEqual(first.?.y, second.?.y);
    try std.testing.expect(first.?.right() <= second.?.x);
    try std.testing.expect(@abs(@divTrunc(first.?.x + second.?.right(), 2) - 400) <= 2);
}

test "nested intrinsic flex widths keep inline header groups on one row" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.bar{display:flex;justify-content:flex-end;height:64px}" ++
            ".links{padding-right:15px}.item{display:inline-block;padding-left:15px}.item a{display:inline-block;line-height:24px}" ++
            ".tools{position:relative}.icon{display:inline-block;width:40px;height:40px;background-color:#eeeeee}" ++
            ".signin{display:inline-block;box-sizing:border-box;min-width:85px;min-height:40px;padding:10px 12px;" ++
            "margin:12px 16px 12px 10px;text-align:center;line-height:18px;background-color:#2050c0}</style>" ++
            "<body><div class=bar><div><div class=links><div class=item><a>Mail</a></div>" ++
            "<div class=item><a>Images</a></div></div></div><div class=tools><span class=icon></span></div>" ++
            "<a class=signin><span>SignIn</span></a></div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 800, .height = 180 });

    var mail: ?Rect = null;
    var images: ?Rect = null;
    var sign_in: ?Rect = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind != .text) continue;
        const value = layout.text(op);
        if (std.mem.eql(u8, value, "Mail")) mail = op.rect;
        if (std.mem.eql(u8, value, "Images")) images = op.rect;
        if (std.mem.eql(u8, value, "SignIn")) sign_in = op.rect;
    }
    try std.testing.expect(mail != null and images != null and sign_in != null);
    try std.testing.expectEqual(mail.?.y, images.?.y);
    try std.testing.expect(mail.?.right() <= images.?.x);
    try std.testing.expect(images.?.right() <= sign_in.?.x);
}

test "styled controls keep composite search geometry and interaction boxes stable" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.shell{display:flex;align-items:center;width:420px;height:44px;" ++
            "box-sizing:border-box;padding:0 12px;gap:8px;border:1px solid #c0c0c0;border-radius:22px;" ++
            "box-shadow:0 2px 6px rgba(0,0,0,0.25),inset 1px 0 3px #10203080;background:#ffffff}" ++
            ".icon{display:block;width:20px;height:20px;background:#4060a0}.query{flex:1 1 0%;min-width:0;height:36px;" ++
            "box-sizing:border-box;border:0;padding:4px 6px;border-radius:18px}.actions{display:flex;width:420px;" ++
            "justify-content:center;gap:8px;margin-top:12px}.action{box-sizing:border-box;width:120px;height:36px;" ++
            "border:1px solid #dadce0;border-radius:4px;background:#f0f0f0;text-align:center}" ++
            ".action:hover{background:#cfe8ff}.action:focus{background:#ccffcc}.action:active{background:#fff0c0}" ++
            ".action:disabled{background:#d0d0d0;color:#606060}</style><body>" ++
            "<div id=shell class=shell><span id=left class=icon></span><input id=query class=query value=Terms>" ++
            "<span id=right class=icon></span></div><div class=actions><button id=normal class=action>Search</button>" ++
            "<button id=disabled class=action disabled>Disabled</button></div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const shell_node = document.findElementById("shell").?;
    const left_node = document.findElementById("left").?;
    const query_node = document.findElementById("query").?;
    const right_node = document.findElementById("right").?;
    const normal_node = document.findElementById("normal").?;
    const disabled_node = document.findElementById("disabled").?;

    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 640, .height = 240 });
    var shell_shadows: [2]RenderOp = undefined;
    var shell_shadow_count: usize = 0;
    var left: ?Rect = null;
    var query: ?RenderOp = null;
    var right: ?Rect = null;
    var normal: ?RenderOp = null;
    var disabled: ?RenderOp = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.node == shell_node and op.kind == .shadow and shell_shadow_count < shell_shadows.len) {
            shell_shadows[shell_shadow_count] = op;
            shell_shadow_count += 1;
        }
        if (op.node == left_node and op.kind == .background) left = op.rect;
        if (op.node == query_node and op.kind == .control) query = op;
        if (op.node == right_node and op.kind == .background) right = op.rect;
        if (op.node == normal_node and op.kind == .control) normal = op;
        if (op.node == disabled_node and op.kind == .control) disabled = op;
    }
    try std.testing.expect(shell_shadow_count == 2 and left != null and query != null and right != null and normal != null and disabled != null);
    try std.testing.expectEqual(@as(i32, 22), shell_shadows[0].radii.top_left.x);
    try std.testing.expectEqual(@as(i32, 22), shell_shadows[0].radii.top_left.y);
    try std.testing.expectEqual(@as(i32, 6), shell_shadows[0].shadow.blur);
    try std.testing.expect(!shell_shadows[0].shadow.inset and shell_shadows[1].shadow.inset);
    try std.testing.expectEqual(@as(u32, 0x102030), shell_shadows[1].shadow.color);
    try std.testing.expectEqual(@as(u8, 128), shell_shadows[1].shadow.alpha);
    try std.testing.expect(left.?.right() <= query.?.rect.x);
    try std.testing.expect(query.?.rect.right() <= right.?.x);
    try std.testing.expect(query.?.rect.w > 300);
    try std.testing.expectEqual(normal.?.rect.y, disabled.?.rect.y);
    try std.testing.expect(normal.?.rect.right() <= disabled.?.rect.x);
    try std.testing.expect(@abs(@divTrunc(normal.?.rect.x + disabled.?.rect.right(), 2) - 210) <= 1);
    try std.testing.expectEqual(@as(u32, 0xD0D0D0), disabled.?.background);

    const stable_rect = normal.?.rect;
    const states = [_]struct { interaction: InteractionState, background: u32 }{
        .{ .interaction = .{ .hovered_node = normal_node }, .background = 0xCFE8FF },
        .{ .interaction = .{ .focused_node = normal_node }, .background = 0xCCFFCC },
        .{ .interaction = .{ .active_node = normal_node }, .background = 0xFFF0C0 },
    };
    for (states) |wanted| {
        _ = try layout.reflowInteractive(&document, &sheet, .{ .width = 640, .height = 240 }, wanted.interaction);
        var state_op: ?RenderOp = null;
        for (layout.ops[0..layout.op_count]) |op| {
            if (op.node == normal_node and op.kind == .control) state_op = op;
        }
        try std.testing.expect(state_op != null);
        try std.testing.expectEqual(stable_rect, state_op.?.rect);
        try std.testing.expectEqual(wanted.background, state_op.?.background);
    }
}

test "font provider drives proportional flow fallback baselines controls and line height" {
    const Provider = struct {
        fn resolve(_: ?*anyopaque, family: []const u8, size: i32, weight: u16, italic: bool, codepoint: ?u32) FontFace {
            _ = size;
            _ = weight;
            _ = italic;
            std.debug.assert(std.mem.indexOf(u8, family, "Primary") != null);
            if (codepoint == 0x2605) return .{ .id = 2, .height = 16, .line_height = 18, .baseline = 13, .max_advance = 9 };
            return .{ .id = 1, .height = 12, .line_height = 14, .baseline = 10, .max_advance = 10 };
        }

        fn measure(_: ?*anyopaque, font_id: u32, value: []const u8) TextMetrics {
            var width: i32 = 0;
            var cursor: usize = 0;
            while (cursor < value.len) {
                const decoded = decodeUtf8Scalar(value, cursor);
                width += if (font_id == 2) 9 else if (decoded.codepoint == 'i') 2 else if (decoded.codepoint == 'W') 10 else if (decoded.codepoint == ' ') 3 else 6;
                cursor += decoded.consumed;
            }
            return if (font_id == 2)
                .{ .valid = true, .width = width, .height = 16, .line_height = 18, .baseline = 13, .visible_bytes = value.len }
            else
                .{ .valid = true, .width = width, .height = 12, .line_height = 14, .baseline = 10, .visible_bytes = value.len };
        }
    };

    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0;font-family:'Primary',sans-serif;font-size:16px}" ++
            ".center{display:flex;width:100px;justify-content:center}.wrap{display:block;width:25px;line-height:.5}" ++
            "button{display:inline}</style><body><div class=center>iiii</div><div class=wrap>iiii WWWW</div>" ++
            "<div id=fallback>A&#9733;B</div><button>WWWWWWWW</button></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflowInteractiveWithProviders(
        &document,
        &sheet,
        .{ .width = 320, .height = 160 },
        .{},
        .{},
        .{ .resolve = Provider.resolve, .measure = Provider.measure },
    );

    var centered: ?RenderOp = null;
    var narrow: ?RenderOp = null;
    var wide: ?RenderOp = null;
    var button: ?RenderOp = null;
    var fallback_ids: [3]u32 = .{ 0, 0, 0 };
    var fallback_y: [3]i32 = .{ 0, 0, 0 };
    var fallback_count: usize = 0;
    const fallback_node = document.findElementById("fallback").?;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind == .control and document.nodeName(op.node).len > 0 and equalsIgnoreCase(document.nodeName(op.node), "button")) button = op;
        if (op.kind != .text) continue;
        const value = layout.text(op);
        if (std.mem.eql(u8, value, "iiii") and centered == null) centered = op else if (std.mem.eql(u8, value, "iiii")) narrow = op;
        if (value.len > 0 and value[0] == 'W' and wide == null) wide = op;
        if (op.node == fallback_node and fallback_count < fallback_ids.len) {
            fallback_ids[fallback_count] = op.font_id;
            fallback_y[fallback_count] = op.rect.y;
            fallback_count += 1;
        }
    }
    try std.testing.expect(centered != null);
    try std.testing.expect(narrow != null);
    try std.testing.expect(wide != null);
    try std.testing.expect(button != null);
    try std.testing.expectEqual(@as(i32, 46), centered.?.rect.x);
    try std.testing.expectEqual(@as(i32, 8), centered.?.rect.w);
    try std.testing.expect(wide.?.rect.y > narrow.?.rect.y);
    try std.testing.expectEqual(@as(i32, 8), wide.?.rect.y - narrow.?.rect.y);
    try std.testing.expectEqual(@as(i32, 14), wide.?.rect.h);
    try std.testing.expect(button.?.rect.w >= 84);
    try std.testing.expectEqual(@as(usize, 3), fallback_count);
    try std.testing.expectEqual([3]u32{ 1, 2, 1 }, fallback_ids);
    try std.testing.expectEqual(fallback_y[0], fallback_y[2]);
    try std.testing.expect(fallback_y[1] <= fallback_y[0]);
}

fn layoutContainsText(layout: *const Layout, wanted: []const u8) bool {
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.kind == .text and std.mem.eql(u8, layout.text(op), wanted)) return true;
    }
    return false;
}

test "visibility keeps geometry removes hidden paint and permits visible descendants" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.hidden{display:block;height:40px;visibility:hidden}" ++
            ".visible{visibility:visible}.gone{display:none}</style><body>" ++
            "<div class=hidden>Secret<span class=visible>Visible</span></div>" ++
            "<div class=gone>Gone</div><div id=after>After</div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 240, .height = 120 });
    try std.testing.expect(!layoutContainsText(&layout, "Secret"));
    try std.testing.expect(!layoutContainsText(&layout, "Gone"));
    try std.testing.expect(layoutContainsText(&layout, "Visible"));
    try std.testing.expect(layoutContainsText(&layout, "After"));
    var after_y: ?i32 = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind == .text and std.mem.eql(u8, layout.text(op), "After")) after_y = op.rect.y;
    }
    try std.testing.expect(after_y != null and after_y.? >= 40);
}

test "overflow clipping is axis aware bounds paint and contains document extent" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.clip{display:block;width:80px;height:24px;overflow:hidden;white-space:nowrap}" ++
            ".vertical{display:block;width:90px;height:18px;overflow-x:clip;overflow-y:visible}</style><body>" ++
            "<div id=clip class=clip>ABCDEFGHIJKLMNOPQRSTUVWXYZ</div>" ++
            "<div id=vertical class=vertical>Vertical content</div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    const stats = try layout.reflow(&document, &sheet, .{ .width = 200, .height = 100 });
    const clip_node = document.findElementById("clip").?;
    const vertical_node = document.findElementById("vertical").?;
    var clipped_text: ?RenderOp = null;
    var vertical_text: ?RenderOp = null;
    for (layout.ops[0..layout.op_count]) |op| {
        if (op.kind != .text) continue;
        if (op.node == clip_node) clipped_text = op;
        if (op.node == vertical_node) vertical_text = op;
    }
    try std.testing.expect(clipped_text != null and clipped_text.?.clip.x and clipped_text.?.clip.y);
    try std.testing.expectEqual(@as(i32, 80), clipped_text.?.clip.rect.w);
    try std.testing.expectEqual(@as(i32, 24), clipped_text.?.clip.rect.h);
    try std.testing.expect(vertical_text != null and vertical_text.?.clip.x and !vertical_text.?.clip.y);
    try std.testing.expectEqual(@as(i32, 200), stats.content_width);
}

test "generated pseudo content combines strings attributes and escaped Unicode without synthetic gaps" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>body{margin:0}.label::before{content:'[' attr(data-code) ']\\2605 '}.label::after{content:'!'}</style>" ++
            "<body><div class=label data-code=R4OS>Body</div></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 240, .height = 80 });
    try std.testing.expect(layoutContainsText(&layout, "[R4OS]★"));
    try std.testing.expect(layoutContainsText(&layout, "Body"));
    try std.testing.expect(layoutContainsText(&layout, "!"));
}

test "display contents removes the wrapper box while preserving child flow" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div id=wrapper><span>Alpha</span><strong>Beta</strong></div><p>After</p></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    _ = try sheet.parse(
        "#wrapper{display:contents;background:#ff0000;border:8px solid #00ff00;padding:20px}" ++
            "span,strong{display:inline}",
    );
    var layout = Layout{};
    _ = try layout.reflow(&document, &sheet, .{ .width = 320, .height = 200 });

    try std.testing.expect(layoutContainsText(&layout, "Alpha"));
    try std.testing.expect(layoutContainsText(&layout, "Beta"));
    try std.testing.expect(layoutContainsText(&layout, "After"));
    const wrapper = document.findElementById("wrapper").?;
    var wrapper_box = false;
    var index: usize = 0;
    while (index < layout.op_count) : (index += 1) {
        const op = layout.ops[index];
        if (op.node == wrapper and (op.kind == .background or op.kind == .border)) wrapper_box = true;
    }
    try std.testing.expect(!wrapper_box);
}

test "semantic page regions produce deterministic responsive color and visibility inventories" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>html,body{margin:0}body{display:flex;flex-direction:column;min-height:100vh}" ++
            "header{display:flex;height:40px;color:#112233}.left{display:block}.right{display:block;margin-left:auto}" ++
            "main{display:flex;flex-grow:1;justify-content:center;color:#223344}footer{display:flex;height:32px;color:#334455}" ++
            "@media (orientation:portrait){header .right{visibility:hidden}footer{display:none}}</style><body>" ++
            "<header><span class=left>Left</span><span class=right>Right</span></header>" ++
            "<main>Main</main><footer>Footer</footer></body>",
        .{},
    );
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var landscape = Layout{};
    const landscape_stats = try landscape.reflow(&document, &sheet, .{ .width = 640, .height = 360 });
    try std.testing.expect(layoutContainsText(&landscape, "Left"));
    try std.testing.expect(layoutContainsText(&landscape, "Right"));
    try std.testing.expect(layoutContainsText(&landscape, "Main"));
    try std.testing.expect(layoutContainsText(&landscape, "Footer"));
    var main_color: ?u32 = null;
    for (landscape.ops[0..landscape.op_count]) |op| {
        if (op.kind == .text and std.mem.eql(u8, landscape.text(op), "Main")) main_color = op.color;
    }
    try std.testing.expectEqual(@as(?u32, 0x223344), main_color);

    var portrait = Layout{};
    const portrait_stats = try portrait.reflow(&document, &sheet, .{ .width = 360, .height = 640 });
    try std.testing.expect(layoutContainsText(&portrait, "Left"));
    try std.testing.expect(!layoutContainsText(&portrait, "Right"));
    try std.testing.expect(layoutContainsText(&portrait, "Main"));
    try std.testing.expect(!layoutContainsText(&portrait, "Footer"));
    try std.testing.expect(landscape_stats.structural_hash != portrait_stats.structural_hash);
}
