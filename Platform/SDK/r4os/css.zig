const std = @import("std");
const html = @import("html.zig");

pub const max_source_bytes: usize = 128 * 1024;
pub const max_rules: usize = 1024;
pub const max_declarations: usize = 4096;
pub const max_selector_parts: usize = 12;
pub const max_custom_properties: usize = 16;
pub const max_layers: usize = 32;
pub const max_source_sections: usize = max_rules;
pub const max_font_face_rules: usize = max_rules;
pub const max_base_url_bytes: usize = 64 * 1024;

pub const Error = error{
    SourceTooLarge,
    RuleLimit,
    DeclarationLimit,
    LayerLimit,
    SourceSectionLimit,
    FontFaceRuleLimit,
    BaseUrlLimit,
    SelectorLimit,
    Malformed,
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

pub const Rule = struct {
    selector: StringRef = .{},
    declaration_start: u16 = 0,
    declaration_count: u16 = 0,
    specificity: u16 = 0,
    order: u16 = 0,
    layer: u8 = 0,
    source_section: u16 = 0,
    media: MediaConstraint = .{},
};

pub const SourceSection = struct {
    source_start: u32 = 0,
    source_len: u32 = 0,
    /// The final URL of the stylesheet response. An empty value identifies
    /// document-owned CSS, whose relative URLs use the document URL.
    base_url: StringRef = .{},
};

const FontFaceRule = struct {
    source: StringRef = .{},
    source_section: u16 = 0,
    media: MediaConstraint = .{},
};

/// A complete, currently active `@font-face` rule tied to the exact source
/// section and final response URL retained by the cascade.
pub const ActiveFontFaceRule = struct {
    source_section: usize,
    rule_text: []const u8,
    final_base_url: []const u8,
};

/// Allocation-free view over the active font-face rules. Multiple matching
/// branches of one comma-separated media query yield the source rule once.
pub const ActiveFontFaceRuleIterator = struct {
    stylesheet: *const Stylesheet,
    viewport_width: i32,
    viewport_height: i32,
    next_rule: usize = 0,

    pub fn next(self: *ActiveFontFaceRuleIterator) ?ActiveFontFaceRule {
        while (self.next_rule < self.stylesheet.font_face_rule_count) {
            const rule_index = self.next_rule;
            self.next_rule += 1;
            const rule = self.stylesheet.font_face_rules[rule_index];
            if (!rule.media.matches(self.viewport_width, self.viewport_height)) continue;

            var earlier_index: usize = 0;
            var already_exported = false;
            while (earlier_index < rule_index) : (earlier_index += 1) {
                const earlier = self.stylesheet.font_face_rules[earlier_index];
                if (earlier.source_section != rule.source_section or
                    earlier.source.offset != rule.source.offset or
                    earlier.source.len != rule.source.len or
                    !earlier.media.matches(self.viewport_width, self.viewport_height)) continue;
                already_exported = true;
                break;
            }
            if (already_exported) continue;

            return .{
                .source_section = rule.source_section,
                .rule_text = rule.source.bytes(self.stylesheet.source[0..self.stylesheet.source_len]),
                .final_base_url = self.stylesheet.sourceSectionBase(rule.source_section),
            };
        }
        return null;
    }
};

pub const Layer = struct {
    name: StringRef = .{},
    order: u8 = 0,
};

pub const MediaOrientation = enum(u8) {
    any,
    portrait,
    landscape,
};

pub const MediaConstraint = struct {
    min_width: i32 = 0,
    max_width: i32 = std.math.maxInt(i32),
    min_height: i32 = 0,
    max_height: i32 = std.math.maxInt(i32),
    orientation: MediaOrientation = .any,
    never: bool = false,

    pub fn matches(self: MediaConstraint, viewport_width: i32, viewport_height: i32) bool {
        if (self.never or viewport_width < self.min_width or viewport_width > self.max_width or
            viewport_height < self.min_height or viewport_height > self.max_height) return false;
        return switch (self.orientation) {
            .any => true,
            .portrait => viewport_height >= viewport_width,
            .landscape => viewport_width > viewport_height,
        };
    }

    fn combine(self: MediaConstraint, other: MediaConstraint) MediaConstraint {
        const orientation = if (self.orientation == .any)
            other.orientation
        else if (other.orientation == .any or self.orientation == other.orientation)
            self.orientation
        else
            MediaOrientation.any;
        const combined = MediaConstraint{
            .min_width = @max(self.min_width, other.min_width),
            .max_width = @min(self.max_width, other.max_width),
            .min_height = @max(self.min_height, other.min_height),
            .max_height = @min(self.max_height, other.max_height),
            .orientation = orientation,
            .never = self.never or other.never or
                (self.orientation != .any and other.orientation != .any and self.orientation != other.orientation),
        };
        if (combined.min_width > combined.max_width or combined.min_height > combined.max_height) return .{ .never = true };
        return combined;
    }
};

pub const Declaration = struct {
    name: StringRef = .{},
    value: StringRef = .{},
    important: bool = false,
};

pub const ParseStats = struct {
    rules: usize,
    declarations: usize,
    ignored_rules: usize,
};

pub const Display = enum(u8) {
    none,
    contents,
    block,
    inline_flow,
    inline_block,
    flex,
    inline_flex,
    grid,
    inline_grid,
};

pub const Position = enum(u8) {
    static,
    relative,
    absolute,
    fixed,
};

pub const Visibility = enum(u8) {
    visible,
    hidden,
    collapse,
};

pub const Overflow = enum(u8) {
    visible,
    hidden,
    clip,
    scroll,
    auto,

    pub fn clips(self: Overflow) bool {
        return self != .visible;
    }
};

pub const WhiteSpace = enum(u8) {
    normal,
    pre,
    nowrap,
};

pub const TextAlign = enum(u8) {
    left,
    center,
    right,
};

pub const FlexDirection = enum(u8) {
    row,
    column,
};

pub const JustifyContent = enum(u8) {
    start,
    end,
    center,
    space_between,
    space_around,
    space_evenly,
};

pub const AlignItems = enum(u8) {
    stretch,
    start,
    end,
    center,
};

pub const BoxSizing = enum(u8) {
    content_box,
    border_box,
};

pub const LineHeightKind = enum(u8) {
    normal,
    number,
    length,
};

pub const LineHeightValue = struct {
    kind: LineHeightKind = .normal,
    number_hundred: i32 = 120,
    length: Length = .{ .kind = .px, .value = 19 },
};

pub const LengthKind = enum(u8) {
    auto,
    px,
    percent,
    em,
    rem,
    vw,
    vh,
    calc,
};

pub const Length = struct {
    kind: LengthKind = .auto,
    value: i32 = 0,
    calc_px: i32 = 0,
    calc_percent: i32 = 0,
    calc_em: i32 = 0,
    calc_rem: i32 = 0,
    calc_vw: i32 = 0,
    calc_vh: i32 = 0,

    pub fn pixels(self: Length, basis: i32, em: i32, fallback: i32) i32 {
        return self.pixelsForViewport(basis, em, fallback, basis, basis);
    }

    pub fn pixelsForViewport(self: Length, basis: i32, em: i32, fallback: i32, viewport_width: i32, viewport_height: i32) i32 {
        return switch (self.kind) {
            .auto => fallback,
            .px => self.value,
            .percent => @divTrunc(basis * self.value, 100),
            .em => @divTrunc(em * self.value, 100),
            .rem => @divTrunc(16 * self.value, 100),
            .vw => fixedLengthPixels(viewport_width, self.value),
            .vh => fixedLengthPixels(viewport_height, self.value),
            .calc => calcLengthPixels(self, basis, em, viewport_width, viewport_height),
        };
    }
};

fn fixedLengthPixels(basis: i32, fixed_hundred: i32) i32 {
    return clampI64ToI32(@divTrunc(@as(i64, basis) * fixed_hundred, 10_000));
}

fn calcLengthPixels(length: Length, basis: i32, em: i32, viewport_width: i32, viewport_height: i32) i32 {
    var hundredths: i64 = length.calc_px;
    hundredths += @divTrunc(@as(i64, basis) * length.calc_percent, 100);
    hundredths += @divTrunc(@as(i64, em) * length.calc_em, 100);
    hundredths += @divTrunc(@as(i64, 16) * length.calc_rem, 100);
    hundredths += @divTrunc(@as(i64, viewport_width) * length.calc_vw, 100);
    hundredths += @divTrunc(@as(i64, viewport_height) * length.calc_vh, 100);
    return clampI64ToI32(@divTrunc(hundredths, 100));
}

fn clampI64ToI32(value: i64) i32 {
    return @intCast(@max(@as(i64, std.math.minInt(i32)), @min(@as(i64, std.math.maxInt(i32)), value)));
}

pub const Edges = struct {
    top: Length = .{ .kind = .px },
    right: Length = .{ .kind = .px },
    bottom: Length = .{ .kind = .px },
    left: Length = .{ .kind = .px },

    pub fn horizontalPixels(self: Edges, basis: i32, em: i32) i32 {
        return self.left.pixels(basis, em, 0) + self.right.pixels(basis, em, 0);
    }

    pub fn verticalPixels(self: Edges, basis: i32, em: i32) i32 {
        return self.top.pixels(basis, em, 0) + self.bottom.pixels(basis, em, 0);
    }
};

pub const BorderRadius = struct {
    x: Length = .{ .kind = .px },
    y: Length = .{ .kind = .px },
};

pub const BorderRadii = struct {
    top_left: BorderRadius = .{},
    top_right: BorderRadius = .{},
    bottom_right: BorderRadius = .{},
    bottom_left: BorderRadius = .{},
};

pub const BoxShadowLayer = struct {
    inset: bool = false,
    offset_x: Length = .{ .kind = .px },
    offset_y: Length = .{ .kind = .px },
    blur: Length = .{ .kind = .px },
    spread: Length = .{ .kind = .px },
    color: u32 = 0x000000,
    alpha: u8 = 64,
};

pub const max_box_shadow_layers: usize = 8;

pub const BoxShadow = struct {
    layers: [max_box_shadow_layers]BoxShadowLayer = .{BoxShadowLayer{}} ** max_box_shadow_layers,
    count: u8 = 0,

    pub fn slice(self: *const BoxShadow) []const BoxShadowLayer {
        return self.layers[0..self.count];
    }
};

pub const BackgroundImageKind = enum(u8) {
    none,
    url,
    image_set,
};

pub const BackgroundImage = struct {
    kind: BackgroundImageKind = .none,
    /// The complete, trimmed CSS value. URL resolution and image-set candidate
    /// selection deliberately belong to the resource consumer.
    raw_value: []const u8 = "",
    /// Final URL of the external stylesheet that supplied `raw_value`.
    /// Empty means that the document URL is the resolution base (STYLE or
    /// an inline style attribute).
    base_url: []const u8 = "",
};

pub const BackgroundRepeat = enum(u8) {
    repeat,
    no_repeat,
    repeat_x,
    repeat_y,
};

pub const BackgroundPosition = struct {
    x: Length = .{ .kind = .percent, .value = 0 },
    y: Length = .{ .kind = .percent, .value = 0 },
};

pub const BackgroundSizeKind = enum(u8) {
    auto,
    contain,
    cover,
    explicit,
};

pub const BackgroundSize = struct {
    kind: BackgroundSizeKind = .auto,
    width: Length = .{},
    height: Length = .{},
};

pub const PseudoElement = enum(u8) {
    none,
    before,
    after,
};

pub const ElementState = struct {
    link: bool = false,
    hover: bool = false,
    focus: bool = false,
    focus_within: bool = false,
    active: bool = false,
    disabled: bool = false,
    hovered_node: u16 = html.none,
    focused_node: u16 = html.none,
    active_node: u16 = html.none,
};

pub const CustomProperty = struct {
    name: []const u8 = "",
    value: []const u8 = "",
    score: u64 = 0,
    sequence: u32 = 0,
    base_url: []const u8 = "",
};

pub const ComputedStyle = struct {
    display: Display = .inline_flow,
    position: Position = .static,
    visibility: Visibility = .visible,
    width: Length = .{},
    height: Length = .{},
    min_width: Length = .{},
    max_width: Length = .{},
    min_height: Length = .{},
    max_height: Length = .{},
    box_sizing: BoxSizing = .content_box,
    left: Length = .{},
    top: Length = .{},
    right: Length = .{},
    bottom: Length = .{},
    margin: Edges = .{},
    padding: Edges = .{},
    border: Edges = .{},
    border_radius: BorderRadii = .{},
    box_shadow: BoxShadow = .{},
    color: u32 = 0x000000,
    background_color: ?u32 = null,
    background_image: BackgroundImage = .{},
    background_repeat: BackgroundRepeat = .repeat,
    background_position: BackgroundPosition = .{},
    background_size: BackgroundSize = .{},
    border_color: u32 = 0x000000,
    font_family: []const u8 = "sans-serif",
    font_size: i32 = 16,
    font_weight: u16 = 400,
    italic: bool = false,
    line_height: i32 = 19,
    line_height_value: LineHeightValue = .{},
    text_align: TextAlign = .left,
    underline: bool = false,
    disabled: bool = false,
    white_space: WhiteSpace = .normal,
    flex_direction: FlexDirection = .row,
    flex_wrap: bool = false,
    flex_grow: u16 = 0,
    flex_shrink: u16 = 1,
    flex_basis: Length = .{},
    justify_content: JustifyContent = .start,
    align_items: AlignItems = .stretch,
    gap: i32 = 0,
    grid_columns: u8 = 1,
    overflow_x: Overflow = .visible,
    overflow_y: Overflow = .visible,
    clip_empty: bool = false,
    content: []const u8 = "",
    content_is_expression: bool = false,
    custom: [max_custom_properties]CustomProperty = .{CustomProperty{}} ** max_custom_properties,
    custom_count: u8 = 0,
};

const Property = enum(u8) {
    display,
    position,
    visibility,
    width,
    height,
    min_width,
    max_width,
    min_height,
    max_height,
    box_sizing,
    left,
    top,
    right,
    bottom,
    margin,
    margin_top,
    margin_right,
    margin_bottom,
    margin_left,
    padding,
    padding_top,
    padding_right,
    padding_bottom,
    padding_left,
    border,
    border_style,
    border_width,
    border_top,
    border_right,
    border_bottom,
    border_left,
    border_radius,
    border_top_left_radius,
    border_top_right_radius,
    border_bottom_right_radius,
    border_bottom_left_radius,
    box_shadow,
    color,
    background,
    background_color,
    background_image,
    background_repeat,
    background_position,
    background_size,
    border_color,
    font_family,
    font_size,
    font_weight,
    font_style,
    line_height,
    text_align,
    text_decoration,
    white_space,
    flex_direction,
    flex_wrap,
    flex,
    flex_grow,
    flex_shrink,
    flex_basis,
    justify_content,
    align_items,
    gap,
    grid_template_columns,
    overflow,
    overflow_x,
    overflow_y,
    clip,
    content,
};

const property_count = @typeInfo(Property).@"enum".fields.len;

const Winner = struct {
    present: bool = false,
    score: u64 = 0,
    sequence: u32 = 0,
    value: []const u8 = "",
    base_url: []const u8 = "",
};

pub const Stylesheet = struct {
    source: [max_source_bytes]u8 = undefined,
    base_urls: [max_base_url_bytes]u8 = undefined,
    rules: [max_rules]Rule = undefined,
    declarations: [max_declarations]Declaration = undefined,
    layers: [max_layers]Layer = undefined,
    source_sections: [max_source_sections]SourceSection = undefined,
    font_face_rules: [max_font_face_rules]FontFaceRule = undefined,
    source_len: usize = 0,
    base_url_len: usize = 0,
    rule_count: usize = 0,
    declaration_count: usize = 0,
    layer_count: usize = 0,
    source_section_count: usize = 0,
    font_face_rule_count: usize = 0,
    ignored_rules: usize = 0,

    pub fn reset(self: *Stylesheet) void {
        self.source_len = 0;
        self.base_url_len = 0;
        self.rule_count = 0;
        self.declaration_count = 0;
        self.layer_count = 0;
        self.source_section_count = 0;
        self.font_face_rule_count = 0;
        self.ignored_rules = 0;
    }

    pub fn parse(self: *Stylesheet, source: []const u8) Error!ParseStats {
        self.reset();
        try self.append(source);
        return self.stats();
    }

    pub fn append(self: *Stylesheet, source: []const u8) Error!void {
        try self.appendWithBase(source, "");
    }

    /// Appends one stylesheet response together with its final response URL.
    /// Redirect handling and URL normalization remain the caller's job; this
    /// module only retains the supplied base for the cascade winner.
    pub fn appendWithBase(self: *Stylesheet, source: []const u8, final_base_url: []const u8) Error!void {
        if (source.len == 0) return;
        if (source.len > self.source.len -| self.source_len) return error.SourceTooLarge;
        if (self.source_section_count >= self.source_sections.len) return error.SourceSectionLimit;

        const previous_source_len = self.source_len;
        const previous_base_url_len = self.base_url_len;
        const previous_rule_count = self.rule_count;
        const previous_declaration_count = self.declaration_count;
        const previous_layer_count = self.layer_count;
        const previous_source_section_count = self.source_section_count;
        const previous_font_face_rule_count = self.font_face_rule_count;
        const previous_ignored_rules = self.ignored_rules;
        errdefer {
            self.source_len = previous_source_len;
            self.base_url_len = previous_base_url_len;
            self.rule_count = previous_rule_count;
            self.declaration_count = previous_declaration_count;
            self.layer_count = previous_layer_count;
            self.source_section_count = previous_source_section_count;
            self.font_face_rule_count = previous_font_face_rule_count;
            self.ignored_rules = previous_ignored_rules;
        }

        const base_url = try self.internBaseUrl(final_base_url);
        const base = self.source_len;
        @memcpy(self.source[base .. base + source.len], source);
        self.source_len += source.len;
        const source_section: u16 = @intCast(self.source_section_count);
        self.source_sections[self.source_section_count] = .{
            .source_start = @intCast(base),
            .source_len = @intCast(source.len),
            .base_url = base_url,
        };
        self.source_section_count += 1;
        try self.parseRange(base, base + source.len, .{}, 0, source_section, true);
    }

    pub fn appendDocumentStyles(self: *Stylesheet, document: *const html.Document) Error!void {
        var index: usize = 0;
        while (index < document.node_count) : (index += 1) {
            if (document.nodes[index].kind != .element or !equalsIgnoreCase(document.nodeName(@intCast(index)), "style")) continue;
            var child = document.nodes[index].first_child;
            while (child != html.none) {
                if (document.nodes[child].kind == .text) try self.append(document.nodeValue(child));
                child = document.nodes[child].next_sibling;
            }
        }
    }

    pub fn rebuildDocumentStyles(self: *Stylesheet, document: *const html.Document, external_source: []const u8) Error!void {
        self.reset();
        try self.appendDocumentStyles(document);
        if (external_source.len > 0) try self.append(external_source);
    }

    pub fn stats(self: *const Stylesheet) ParseStats {
        return .{
            .rules = self.rule_count,
            .declarations = self.declaration_count,
            .ignored_rules = self.ignored_rules,
        };
    }

    pub fn sourceSectionBase(self: *const Stylesheet, source_section: usize) []const u8 {
        if (source_section >= self.source_section_count) return "";
        return self.source_sections[source_section].base_url.bytes(self.base_urls[0..self.base_url_len]);
    }

    /// Number of source units retained by the cascade.  Consumers such as the
    /// document-scoped web-font registry use the same exact stylesheet bytes
    /// and final response base URL instead of maintaining a second source
    /// catalogue.
    pub fn sourceSectionCount(self: *const Stylesheet) usize {
        return self.source_section_count;
    }

    pub fn sourceSectionText(self: *const Stylesheet, source_section: usize) []const u8 {
        if (source_section >= self.source_section_count) return "";
        const section = self.source_sections[source_section];
        const start: usize = section.source_start;
        const length: usize = section.source_len;
        if (start > self.source_len or length > self.source_len - start) return "";
        return self.source[start .. start + length];
    }

    /// Iterates complete `@font-face` source rules whose conditional media
    /// chain matches the supplied viewport. Each result retains its original
    /// source-section identity and final stylesheet response URL.
    pub fn activeFontFaceRulesForViewportSize(
        self: *const Stylesheet,
        viewport_width: i32,
        viewport_height: i32,
    ) ActiveFontFaceRuleIterator {
        return .{
            .stylesheet = self,
            .viewport_width = viewport_width,
            .viewport_height = viewport_height,
        };
    }

    fn internBaseUrl(self: *Stylesheet, final_base_url: []const u8) Error!StringRef {
        if (final_base_url.len == 0) return .{};
        var index: usize = 0;
        while (index < self.source_section_count) : (index += 1) {
            const existing = self.source_sections[index].base_url;
            if (std.mem.eql(u8, existing.bytes(self.base_urls[0..self.base_url_len]), final_base_url)) return existing;
        }
        if (final_base_url.len > self.base_urls.len -| self.base_url_len) return error.BaseUrlLimit;
        const start = self.base_url_len;
        @memcpy(self.base_urls[start .. start + final_base_url.len], final_base_url);
        self.base_url_len += final_base_url.len;
        return .{ .offset = @intCast(start), .len = @intCast(final_base_url.len) };
    }

    pub fn compute(
        self: *const Stylesheet,
        document: *const html.Document,
        node_index: u16,
        parent: ?*const ComputedStyle,
        state: ElementState,
        pseudo: PseudoElement,
    ) ComputedStyle {
        return self.computeForViewport(document, node_index, parent, state, pseudo, std.math.maxInt(i32));
    }

    pub fn computeForViewport(
        self: *const Stylesheet,
        document: *const html.Document,
        node_index: u16,
        parent: ?*const ComputedStyle,
        state: ElementState,
        pseudo: PseudoElement,
        viewport_width: i32,
    ) ComputedStyle {
        return self.computeForViewportSize(document, node_index, parent, state, pseudo, viewport_width, viewport_width);
    }

    pub fn computeForViewportSize(
        self: *const Stylesheet,
        document: *const html.Document,
        node_index: u16,
        parent: ?*const ComputedStyle,
        state: ElementState,
        pseudo: PseudoElement,
        viewport_width: i32,
        viewport_height: i32,
    ) ComputedStyle {
        var style = initialStyle(document, node_index, parent, state, pseudo);
        const reverted_style = style;
        var winners: [property_count]Winner = .{Winner{}} ** property_count;
        var custom_winners: [max_custom_properties]CustomProperty = .{CustomProperty{}} ** max_custom_properties;
        var custom_count: usize = 0;

        if (parent) |inherited| {
            var index: usize = 0;
            while (index < inherited.custom_count and index < custom_winners.len) : (index += 1) {
                custom_winners[index] = inherited.custom[index];
                custom_winners[index].score = 0;
                custom_winners[index].sequence = 0;
            }
            custom_count = inherited.custom_count;
        }

        var rule_index: usize = 0;
        while (rule_index < self.rule_count) : (rule_index += 1) {
            const rule = self.rules[rule_index];
            if (!rule.media.matches(viewport_width, viewport_height)) continue;
            const selector = rule.selector.bytes(self.source[0..self.source_len]);
            if (!selectorMatches(document, node_index, selector, state, pseudo)) continue;
            const base_url = self.sourceSectionBase(rule.source_section);
            var declaration_index: usize = rule.declaration_start;
            const end = declaration_index + rule.declaration_count;
            while (declaration_index < end and declaration_index < self.declaration_count) : (declaration_index += 1) {
                const declaration = self.declarations[declaration_index];
                const name = declaration.name.bytes(self.source[0..self.source_len]);
                const value = declaration.value.bytes(self.source[0..self.source_len]);
                const score = cascadeScore(declaration.important, false, rule.specificity, rule.order, rule.layer);
                collectWinner(&winners, &custom_winners, &custom_count, name, value, score, @intCast(declaration_index), base_url);
            }
        }

        if (pseudo == .none) {
            if (document.attribute(node_index, "style")) |inline_style| {
                collectInlineWinners(inline_style, &winners, &custom_winners, &custom_count);
            }
        }

        style.custom_count = @intCast(@min(custom_count, style.custom.len));
        var custom_index: usize = 0;
        while (custom_index < style.custom_count) : (custom_index += 1) style.custom[custom_index] = custom_winners[custom_index];

        applyWinners(&style, &winners, parent, &reverted_style);
        if (isHiddenInput(document, node_index)) style.display = .none;
        normalizeStyle(&style);
        return style;
    }

    fn parseRange(
        self: *Stylesheet,
        start: usize,
        end: usize,
        media: MediaConstraint,
        layer: u8,
        source_section: u16,
        font_faces_allowed: bool,
    ) Error!void {
        var cursor = start;
        while (cursor < end) {
            skipWhitespaceAndComments(self.source[0..end], &cursor);
            if (cursor >= end) break;
            if (self.source[cursor] == '@') {
                const at_start = cursor;
                cursor += 1;
                const name_start = cursor;
                while (cursor < end and isIdentByte(self.source[cursor])) : (cursor += 1) {}
                const name = self.source[name_start..cursor];
                if (equalsIgnoreCase(name, "font-face")) {
                    const block_start = findAtRuleBlockStart(self.source[0..end], cursor) orelse {
                        self.ignored_rules += 1;
                        cursor = at_start;
                        skipAtRule(self.source[0..end], &cursor);
                        continue;
                    };
                    const block_end = findMatchingBrace(self.source[0..end], block_start) orelse {
                        self.ignored_rules += 1;
                        cursor = end;
                        continue;
                    };
                    var prelude_end = cursor;
                    skipWhitespaceAndComments(self.source[0..block_start], &prelude_end);
                    if (!font_faces_allowed or prelude_end != block_start) {
                        self.ignored_rules += 1;
                        cursor = block_end + 1;
                        continue;
                    }
                    try self.recordFontFaceRule(at_start, block_end + 1, media, source_section);
                    cursor = block_end + 1;
                    continue;
                }
                if (equalsIgnoreCase(name, "media")) {
                    const condition_start = cursor;
                    const block_start = findAtRuleBlockStart(self.source[0..end], cursor) orelse {
                        self.ignored_rules += 1;
                        cursor = at_start;
                        skipAtRule(self.source[0..end], &cursor);
                        continue;
                    };
                    const block_end = findMatchingBrace(self.source[0..end], block_start) orelse {
                        self.ignored_rules += 1;
                        cursor = end;
                        continue;
                    };
                    const parsed_queries = try self.parseMediaQueryList(
                        self.source[condition_start..block_start],
                        block_start + 1,
                        block_end,
                        media,
                        layer,
                        source_section,
                        font_faces_allowed,
                    );
                    if (parsed_queries == 0) self.ignored_rules += 1;
                    cursor = block_end + 1;
                    continue;
                }
                if (equalsIgnoreCase(name, "layer")) {
                    if (findAtRuleBlockStart(self.source[0..end], cursor)) |block_start| {
                        const block_end = findMatchingBrace(self.source[0..end], block_start) orelse {
                            self.ignored_rules += 1;
                            cursor = end;
                            continue;
                        };
                        const layer_name = trimRange(self.source[0..self.source_len], cursor, block_start);
                        const block_layer = if (layer_name.end > layer_name.start)
                            try self.ensureLayer(layer_name)
                        else
                            try self.addAnonymousLayer();
                        try self.parseRange(block_start + 1, block_end, media, block_layer, source_section, font_faces_allowed);
                        cursor = block_end + 1;
                        continue;
                    }
                    var statement_end = cursor;
                    while (statement_end < end and self.source[statement_end] != ';') : (statement_end += 1) {}
                    if (statement_end >= end or try self.registerLayerList(cursor, statement_end) == 0) self.ignored_rules += 1;
                    cursor = if (statement_end < end) statement_end + 1 else end;
                    continue;
                }
                self.ignored_rules += 1;
                cursor = at_start;
                skipAtRule(self.source[0..end], &cursor);
                continue;
            }
            const selector_start = cursor;
            while (cursor < end and self.source[cursor] != '{') : (cursor += 1) {}
            if (cursor >= end) {
                if (trim(self.source[selector_start..end]).len != 0) self.ignored_rules += 1;
                break;
            }
            const selector_end = cursor;
            const block_end = findMatchingBrace(self.source[0..end], selector_end) orelse {
                self.ignored_rules += 1;
                cursor = end;
                break;
            };
            const body_start = selector_end + 1;
            const body_end = block_end;
            cursor = block_end + 1;
            try self.addSelectorList(selector_start, selector_end, body_start, body_end, media, layer, source_section);
        }
    }

    fn addSelectorList(
        self: *Stylesheet,
        selector_start: usize,
        selector_end: usize,
        body_start: usize,
        body_end: usize,
        media: MediaConstraint,
        layer: u8,
        source_section: u16,
    ) Error!void {
        var start = selector_start;
        var cursor = selector_start;
        var bracket_depth: usize = 0;
        var paren_depth: usize = 0;
        while (cursor <= selector_end) : (cursor += 1) {
            const at_end = cursor == selector_end;
            const byte: u8 = if (at_end) ',' else self.source[cursor];
            if (!at_end) {
                if (byte == '[') bracket_depth += 1 else if (byte == ']' and bracket_depth > 0) bracket_depth -= 1;
                if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
            }
            if (byte != ',' or bracket_depth != 0 or paren_depth != 0) continue;
            const selector = trimRange(self.source[0..self.source_len], start, cursor);
            start = cursor + 1;
            if (selector.end <= selector.start) continue;
            if (self.rule_count >= self.rules.len) return error.RuleLimit;
            const declaration_start = self.declaration_count;
            try self.parseDeclarations(body_start, body_end);
            if (self.declaration_count == declaration_start) continue;
            self.rules[self.rule_count] = .{
                .selector = refFor(selector.start, selector.end),
                .declaration_start = @intCast(declaration_start),
                .declaration_count = @intCast(self.declaration_count - declaration_start),
                .specificity = selectorSpecificity(self.source[selector.start..selector.end]),
                .order = @intCast(self.rule_count),
                .layer = layer,
                .source_section = source_section,
                .media = media,
            };
            self.rule_count += 1;
        }
    }

    fn parseMediaQueryList(
        self: *Stylesheet,
        query_list: []const u8,
        block_start: usize,
        block_end: usize,
        parent_media: MediaConstraint,
        layer: u8,
        source_section: u16,
        font_faces_allowed: bool,
    ) Error!usize {
        var parsed: usize = 0;
        var start: usize = 0;
        var cursor: usize = 0;
        var paren_depth: usize = 0;
        while (cursor <= query_list.len) : (cursor += 1) {
            const at_end = cursor == query_list.len;
            if (!at_end) {
                const byte = query_list[cursor];
                if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
                if (byte != ',' or paren_depth != 0) continue;
            }
            const query = trim(query_list[start..cursor]);
            start = cursor + 1;
            if (query.len == 0) continue;
            const constraint = parseMediaConstraint(query) orelse continue;
            try self.parseRange(block_start, block_end, parent_media.combine(constraint), layer, source_section, font_faces_allowed);
            parsed += 1;
        }
        return parsed;
    }

    fn recordFontFaceRule(
        self: *Stylesheet,
        start: usize,
        end: usize,
        media: MediaConstraint,
        source_section: u16,
    ) Error!void {
        var existing_index: usize = 0;
        while (existing_index < self.font_face_rule_count) : (existing_index += 1) {
            const existing = self.font_face_rules[existing_index];
            if (existing.source_section == source_section and
                existing.source.offset == start and
                existing.source.len == end - start and
                std.meta.eql(existing.media, media)) return;
        }
        if (self.font_face_rule_count >= self.font_face_rules.len) return error.FontFaceRuleLimit;
        self.font_face_rules[self.font_face_rule_count] = .{
            .source = refFor(start, end),
            .source_section = source_section,
            .media = media,
        };
        self.font_face_rule_count += 1;
    }

    fn registerLayerList(self: *Stylesheet, start: usize, end: usize) Error!usize {
        var registered: usize = 0;
        var item_start = start;
        var cursor = start;
        while (cursor <= end) : (cursor += 1) {
            if (cursor != end and self.source[cursor] != ',') continue;
            const name = trimRange(self.source[0..self.source_len], item_start, cursor);
            item_start = cursor + 1;
            if (name.end <= name.start) continue;
            _ = try self.ensureLayer(name);
            registered += 1;
        }
        return registered;
    }

    fn ensureLayer(self: *Stylesheet, name: Range) Error!u8 {
        const source = self.source[0..self.source_len];
        const wanted = source[name.start..name.end];
        var index: usize = 0;
        while (index < self.layer_count) : (index += 1) {
            const existing = self.layers[index].name.bytes(source);
            if (existing.len != 0 and equalsIgnoreCase(existing, wanted)) return self.layers[index].order;
        }
        if (self.layer_count >= self.layers.len) return error.LayerLimit;
        const order: u8 = @intCast(self.layer_count + 1);
        self.layers[self.layer_count] = .{ .name = refFor(name.start, name.end), .order = order };
        self.layer_count += 1;
        return order;
    }

    fn addAnonymousLayer(self: *Stylesheet) Error!u8 {
        if (self.layer_count >= self.layers.len) return error.LayerLimit;
        const order: u8 = @intCast(self.layer_count + 1);
        self.layers[self.layer_count] = .{ .order = order };
        self.layer_count += 1;
        return order;
    }

    fn parseDeclarations(self: *Stylesheet, start: usize, end: usize) Error!void {
        var cursor = start;
        while (cursor < end) {
            skipWhitespaceAndComments(self.source[0..end], &cursor);
            while (cursor < end and self.source[cursor] == ';') : (cursor += 1) {}
            if (cursor >= end) break;
            const name_start = cursor;
            while (cursor < end and self.source[cursor] != ':' and self.source[cursor] != ';') : (cursor += 1) {}
            if (cursor >= end or self.source[cursor] != ':') {
                while (cursor < end and self.source[cursor] != ';') : (cursor += 1) {}
                continue;
            }
            const name_range = trimRange(self.source[0..self.source_len], name_start, cursor);
            cursor += 1;
            const value_start = cursor;
            var quote: u8 = 0;
            var paren_depth: usize = 0;
            while (cursor < end) : (cursor += 1) {
                const byte = self.source[cursor];
                if (quote != 0) {
                    if (byte == quote) quote = 0;
                    continue;
                }
                if (byte == '"' or byte == '\'') quote = byte else if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1 else if (byte == ';' and paren_depth == 0) break;
            }
            var value_range = trimRange(self.source[0..self.source_len], value_start, cursor);
            var important = false;
            const value = self.source[value_range.start..value_range.end];
            if (endsWithIgnoreCase(value, "!important")) {
                important = true;
                value_range.end -= "!important".len;
                while (value_range.end > value_range.start and isSpace(self.source[value_range.end - 1])) value_range.end -= 1;
            }
            if (name_range.end > name_range.start and value_range.end > value_range.start) {
                if (self.declaration_count >= self.declarations.len) return error.DeclarationLimit;
                self.declarations[self.declaration_count] = .{
                    .name = refFor(name_range.start, name_range.end),
                    .value = refFor(value_range.start, value_range.end),
                    .important = important,
                };
                self.declaration_count += 1;
            }
            if (cursor < end) cursor += 1;
        }
    }
};

const Range = struct {
    start: usize,
    end: usize,
};

fn refFor(start: usize, end: usize) StringRef {
    return .{ .offset = @intCast(start), .len = @intCast(end - start) };
}

fn initialStyle(
    document: *const html.Document,
    node_index: u16,
    parent: ?*const ComputedStyle,
    state: ElementState,
    pseudo: PseudoElement,
) ComputedStyle {
    var style = ComputedStyle{};
    if (parent) |inherited| {
        style.color = inherited.color;
        style.font_family = inherited.font_family;
        style.font_size = inherited.font_size;
        style.font_weight = inherited.font_weight;
        style.italic = inherited.italic;
        style.line_height = inherited.line_height;
        style.line_height_value = inherited.line_height_value;
        if (style.line_height_value.kind == .length) {
            style.line_height_value.length = .{ .kind = .px, .value = inherited.line_height };
        }
        style.text_align = inherited.text_align;
        style.white_space = inherited.white_space;
        style.visibility = inherited.visibility;
    }
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element or pseudo != .none) return style;
    style.disabled = state.disabled;
    const name = document.nodeName(node_index);
    style.display = defaultDisplay(name);
    if (equalsIgnoreCase(name, "h1")) {
        style.font_size = 32;
        style.font_weight = 700;
        style.line_height = 38;
        style.margin.top.value = 11;
        style.margin.bottom.value = 11;
    } else if (equalsIgnoreCase(name, "h2")) {
        style.font_size = 24;
        style.font_weight = 700;
        style.line_height = 29;
        style.margin.top.value = 10;
        style.margin.bottom.value = 10;
    } else if (equalsIgnoreCase(name, "h3") or equalsIgnoreCase(name, "h4") or equalsIgnoreCase(name, "h5") or equalsIgnoreCase(name, "h6")) {
        style.font_size = 19;
        style.font_weight = 700;
        style.line_height = 23;
        style.margin.top.value = 8;
        style.margin.bottom.value = 8;
    } else if (equalsIgnoreCase(name, "p") or equalsIgnoreCase(name, "ul") or equalsIgnoreCase(name, "ol") or equalsIgnoreCase(name, "blockquote")) {
        style.margin.top.value = 8;
        style.margin.bottom.value = 8;
    } else if (equalsIgnoreCase(name, "body")) {
        style.margin.top.value = 8;
        style.margin.right.value = 8;
        style.margin.bottom.value = 8;
        style.margin.left.value = 8;
    } else if (equalsIgnoreCase(name, "center")) {
        style.text_align = .center;
    } else if (equalsIgnoreCase(name, "pre") or equalsIgnoreCase(name, "code")) {
        style.font_family = "monospace";
        style.white_space = .pre;
    } else if (equalsIgnoreCase(name, "a") or state.link) {
        style.color = 0x0000CC;
        style.underline = true;
    } else if (equalsIgnoreCase(name, "button") or equalsIgnoreCase(name, "input") or equalsIgnoreCase(name, "select") or equalsIgnoreCase(name, "textarea")) {
        style.display = .inline_flow;
        style.background_color = 0xFFFFFF;
        style.border.top.value = 1;
        style.border.right.value = 1;
        style.border.bottom.value = 1;
        style.border.left.value = 1;
        style.padding.top.value = 2;
        style.padding.right.value = 4;
        style.padding.bottom.value = 2;
        style.padding.left.value = 4;
    }
    return style;
}

fn isHiddenInput(document: *const html.Document, node_index: u16) bool {
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element) return false;
    if (!equalsIgnoreCase(document.nodeName(node_index), "input")) return false;
    const input_type = document.attribute(node_index, "type") orelse "text";
    return equalsIgnoreCase(input_type, "hidden");
}

fn defaultDisplay(name: []const u8) Display {
    const none_names = [_][]const u8{ "head", "title", "meta", "link", "script", "style", "template", "noscript" };
    for (none_names) |item| if (equalsIgnoreCase(name, item)) return .none;
    const blocks = [_][]const u8{
        "html",   "body", "main", "header",     "footer", "nav",  "section",  "article", "aside", "div",
        "p",      "h1",   "h2",   "h3",         "h4",     "h5",   "h6",       "ul",      "ol",    "li",
        "dl",     "dt",   "dd",   "blockquote", "pre",    "form", "fieldset", "table",   "tr",    "hr",
        "center",
    };
    for (blocks) |item| if (equalsIgnoreCase(name, item)) return .block;
    return .inline_flow;
}

fn cascadeScore(important: bool, inline_style: bool, specificity: u16, order: u16, layer: u8) u64 {
    const bounded_layer: u64 = @min(@as(u64, layer), 62);
    const layer_rank: u64 = if (inline_style)
        63
    else if (important)
        if (layer == 0) 0 else 63 - bounded_layer
    else if (layer == 0)
        63
    else
        bounded_layer;
    return (@as(u64, @intFromBool(important)) << 63) |
        (@as(u64, @intFromBool(inline_style)) << 62) |
        (layer_rank << 56) |
        (@as(u64, specificity) << 32) |
        order;
}

fn collectWinner(
    winners: *[property_count]Winner,
    custom: *[max_custom_properties]CustomProperty,
    custom_count: *usize,
    name: []const u8,
    value: []const u8,
    score: u64,
    sequence: u32,
    base_url: []const u8,
) void {
    if (startsWith(name, "--")) {
        var index: usize = 0;
        while (index < custom_count.*) : (index += 1) {
            if (!equalsIgnoreCase(custom[index].name, name)) continue;
            if (score > custom[index].score or (score == custom[index].score and sequence >= custom[index].sequence)) {
                custom[index] = .{ .name = name, .value = value, .score = score, .sequence = sequence, .base_url = base_url };
            }
            return;
        }
        if (custom_count.* < custom.len) {
            custom[custom_count.*] = .{ .name = name, .value = value, .score = score, .sequence = sequence, .base_url = base_url };
            custom_count.* += 1;
        }
        return;
    }
    if (equalsIgnoreCase(trim(name), "all")) {
        for (winners) |*winner| {
            if (!winner.present or score > winner.score or (score == winner.score and sequence >= winner.sequence)) {
                winner.* = .{ .present = true, .score = score, .sequence = sequence, .value = value };
                winner.base_url = base_url;
            }
        }
        return;
    }
    const property = propertyFromName(name) orelse return;
    if (!propertyValueIsSupported(property, value)) return;
    const index: usize = @intFromEnum(property);
    if (!winners[index].present or score > winners[index].score or (score == winners[index].score and sequence >= winners[index].sequence)) {
        winners[index] = .{ .present = true, .score = score, .sequence = sequence, .value = value, .base_url = base_url };
    }
}

fn propertyValueIsSupported(property: Property, value: []const u8) bool {
    const input = trim(value);
    if (equalsIgnoreCase(input, "initial") or equalsIgnoreCase(input, "inherit") or
        equalsIgnoreCase(input, "unset") or equalsIgnoreCase(input, "revert") or
        equalsIgnoreCase(input, "revert-layer") or isCompleteCssFunction(input, "var")) return true;
    return switch (property) {
        .background => parseBackgroundShorthand(input) != null,
        .background_image => parseBackgroundImage(input) != null,
        .background_repeat => parseBackgroundRepeat(input) != null,
        .background_position => parseBackgroundPosition(input) != null,
        .background_size => parseBackgroundSize(input) != null,
        else => true,
    };
}

fn collectInlineWinners(
    source: []const u8,
    winners: *[property_count]Winner,
    custom: *[max_custom_properties]CustomProperty,
    custom_count: *usize,
) void {
    var cursor: usize = 0;
    var order: u16 = 0;
    while (cursor < source.len) {
        const name_start = cursor;
        while (cursor < source.len and source[cursor] != ':' and source[cursor] != ';') : (cursor += 1) {}
        if (cursor >= source.len or source[cursor] != ':') {
            if (cursor < source.len) cursor += 1;
            continue;
        }
        const name = trim(source[name_start..cursor]);
        cursor += 1;
        const value_start = cursor;
        var paren_depth: usize = 0;
        while (cursor < source.len) : (cursor += 1) {
            if (source[cursor] == '(') paren_depth += 1 else if (source[cursor] == ')' and paren_depth > 0) paren_depth -= 1 else if (source[cursor] == ';' and paren_depth == 0) break;
        }
        var value = trim(source[value_start..cursor]);
        var important = false;
        if (endsWithIgnoreCase(value, "!important")) {
            important = true;
            value = trim(value[0 .. value.len - "!important".len]);
        }
        collectWinner(
            winners,
            custom,
            custom_count,
            name,
            value,
            cascadeScore(important, true, 1000, order, 0),
            @as(u32, max_declarations) + order,
            "",
        );
        order +%= 1;
        if (cursor < source.len) cursor += 1;
    }
}

fn applyWinners(
    style: *ComputedStyle,
    winners: *const [property_count]Winner,
    parent: ?*const ComputedStyle,
    reverted_style: *const ComputedStyle,
) void {
    var ordered: [property_count]usize = undefined;
    var ordered_count: usize = 0;
    for (winners, 0..) |winner, index| {
        if (!winner.present) continue;
        var position = ordered_count;
        while (position > 0 and winnerComesBefore(winner, winners[ordered[position - 1]])) : (position -= 1) {
            ordered[position] = ordered[position - 1];
        }
        ordered[position] = index;
        ordered_count += 1;
    }

    for (ordered[0..ordered_count]) |index| {
        const winner = winners[index];
        const property: Property = @enumFromInt(index);
        const resolved = resolveVariable(style, winner.value, winner.base_url);
        if (applyCssWideKeyword(style, property, resolved.value, parent, reverted_style)) continue;
        applyProperty(style, property, resolved.value);
        const background_value_valid = switch (property) {
            .background => parseBackgroundShorthand(resolved.value) != null,
            .background_image => parseBackgroundImage(resolved.value) != null,
            else => false,
        };
        if (background_value_valid) {
            style.background_image.base_url = if (style.background_image.kind == .none) "" else resolved.base_url;
        }
    }
}

fn winnerComesBefore(left: Winner, right: Winner) bool {
    return left.score < right.score or (left.score == right.score and left.sequence < right.sequence);
}

fn applyCssWideKeyword(
    style: *ComputedStyle,
    property: Property,
    value: []const u8,
    parent: ?*const ComputedStyle,
    reverted_style: *const ComputedStyle,
) bool {
    const keyword = trim(value);
    const initial = ComputedStyle{};
    if (equalsIgnoreCase(keyword, "initial")) {
        copyProperty(style, property, &initial);
        return true;
    }
    if (equalsIgnoreCase(keyword, "inherit")) {
        copyProperty(style, property, parent orelse &initial);
        return true;
    }
    if (equalsIgnoreCase(keyword, "unset")) {
        copyProperty(style, property, if (propertyIsInherited(property)) parent orelse &initial else &initial);
        return true;
    }
    if (equalsIgnoreCase(keyword, "revert") or equalsIgnoreCase(keyword, "revert-layer")) {
        copyProperty(style, property, reverted_style);
        return true;
    }
    return false;
}

fn propertyIsInherited(property: Property) bool {
    return switch (property) {
        .visibility,
        .color,
        .font_family,
        .font_size,
        .font_weight,
        .font_style,
        .line_height,
        .text_align,
        .white_space,
        => true,
        else => false,
    };
}

fn copyProperty(target: *ComputedStyle, property: Property, source: *const ComputedStyle) void {
    switch (property) {
        .display => target.display = source.display,
        .position => target.position = source.position,
        .visibility => target.visibility = source.visibility,
        .width => target.width = source.width,
        .height => target.height = source.height,
        .min_width => target.min_width = source.min_width,
        .max_width => target.max_width = source.max_width,
        .min_height => target.min_height = source.min_height,
        .max_height => target.max_height = source.max_height,
        .box_sizing => target.box_sizing = source.box_sizing,
        .left => target.left = source.left,
        .top => target.top = source.top,
        .right => target.right = source.right,
        .bottom => target.bottom = source.bottom,
        .margin => target.margin = source.margin,
        .margin_top => target.margin.top = source.margin.top,
        .margin_right => target.margin.right = source.margin.right,
        .margin_bottom => target.margin.bottom = source.margin.bottom,
        .margin_left => target.margin.left = source.margin.left,
        .padding => target.padding = source.padding,
        .padding_top => target.padding.top = source.padding.top,
        .padding_right => target.padding.right = source.padding.right,
        .padding_bottom => target.padding.bottom = source.padding.bottom,
        .padding_left => target.padding.left = source.padding.left,
        .border, .border_style, .border_width => target.border = source.border,
        .border_top => target.border.top = source.border.top,
        .border_right => target.border.right = source.border.right,
        .border_bottom => target.border.bottom = source.border.bottom,
        .border_left => target.border.left = source.border.left,
        .border_radius => target.border_radius = source.border_radius,
        .border_top_left_radius => target.border_radius.top_left = source.border_radius.top_left,
        .border_top_right_radius => target.border_radius.top_right = source.border_radius.top_right,
        .border_bottom_right_radius => target.border_radius.bottom_right = source.border_radius.bottom_right,
        .border_bottom_left_radius => target.border_radius.bottom_left = source.border_radius.bottom_left,
        .box_shadow => target.box_shadow = source.box_shadow,
        .color => target.color = source.color,
        .background => {
            target.background_color = source.background_color;
            target.background_image = source.background_image;
            target.background_repeat = source.background_repeat;
            target.background_position = source.background_position;
            target.background_size = source.background_size;
        },
        .background_color => target.background_color = source.background_color,
        .background_image => target.background_image = source.background_image,
        .background_repeat => target.background_repeat = source.background_repeat,
        .background_position => target.background_position = source.background_position,
        .background_size => target.background_size = source.background_size,
        .border_color => target.border_color = source.border_color,
        .font_family => target.font_family = source.font_family,
        .font_size => target.font_size = source.font_size,
        .font_weight => target.font_weight = source.font_weight,
        .font_style => target.italic = source.italic,
        .line_height => {
            target.line_height = source.line_height;
            target.line_height_value = source.line_height_value;
            if (target.line_height_value.kind == .length) {
                target.line_height_value.length = .{ .kind = .px, .value = source.line_height };
            }
        },
        .text_align => target.text_align = source.text_align,
        .text_decoration => target.underline = source.underline,
        .white_space => target.white_space = source.white_space,
        .flex_direction => target.flex_direction = source.flex_direction,
        .flex_wrap => target.flex_wrap = source.flex_wrap,
        .flex => {
            target.flex_grow = source.flex_grow;
            target.flex_shrink = source.flex_shrink;
            target.flex_basis = source.flex_basis;
        },
        .flex_grow => target.flex_grow = source.flex_grow,
        .flex_shrink => target.flex_shrink = source.flex_shrink,
        .flex_basis => target.flex_basis = source.flex_basis,
        .justify_content => target.justify_content = source.justify_content,
        .align_items => target.align_items = source.align_items,
        .gap => target.gap = source.gap,
        .grid_template_columns => target.grid_columns = source.grid_columns,
        .overflow => {
            target.overflow_x = source.overflow_x;
            target.overflow_y = source.overflow_y;
        },
        .overflow_x => target.overflow_x = source.overflow_x,
        .overflow_y => target.overflow_y = source.overflow_y,
        .clip => target.clip_empty = source.clip_empty,
        .content => {
            target.content = source.content;
            target.content_is_expression = source.content_is_expression;
        },
    }
}

const ResolvedValue = struct {
    value: []const u8,
    base_url: []const u8,
};

fn resolveVariable(style: *const ComputedStyle, input: []const u8, base_url: []const u8) ResolvedValue {
    return resolveVariableDepth(style, input, base_url, 0);
}

fn resolveVariableDepth(style: *const ComputedStyle, input: []const u8, base_url: []const u8, depth: usize) ResolvedValue {
    const value = trim(input);
    if (depth >= max_custom_properties) return .{ .value = "", .base_url = base_url };
    if (!startsWithIgnoreCase(value, "var(") or value.len < 6 or value[value.len - 1] != ')') {
        return .{ .value = value, .base_url = base_url };
    }
    const inner = trim(value[4 .. value.len - 1]);
    const comma = indexOfScalar(inner, ',');
    const name = trim(inner[0 .. comma orelse inner.len]);
    var index: usize = 0;
    while (index < style.custom_count) : (index += 1) {
        if (equalsIgnoreCase(style.custom[index].name, name)) {
            return resolveVariableDepth(style, style.custom[index].value, style.custom[index].base_url, depth + 1);
        }
    }
    if (comma) |position| return resolveVariableDepth(style, trim(inner[position + 1 ..]), base_url, depth + 1);
    return .{ .value = "", .base_url = base_url };
}

fn applyProperty(style: *ComputedStyle, property: Property, value: []const u8) void {
    switch (property) {
        .display => style.display = parseDisplay(value) orelse style.display,
        .position => style.position = parsePosition(value) orelse style.position,
        .visibility => style.visibility = parseVisibility(value) orelse style.visibility,
        .width => style.width = parseLength(value) orelse style.width,
        .height => style.height = parseLength(value) orelse style.height,
        .min_width => style.min_width = parseLength(value) orelse style.min_width,
        .max_width => style.max_width = parseLength(value) orelse style.max_width,
        .min_height => style.min_height = parseLength(value) orelse style.min_height,
        .max_height => style.max_height = parseLength(value) orelse style.max_height,
        .box_sizing => style.box_sizing = parseBoxSizing(value) orelse style.box_sizing,
        .left => style.left = parseLength(value) orelse style.left,
        .top => style.top = parseLength(value) orelse style.top,
        .right => style.right = parseLength(value) orelse style.right,
        .bottom => style.bottom = parseLength(value) orelse style.bottom,
        .margin => style.margin = parseEdges(value) orelse style.margin,
        .margin_top => style.margin.top = parseLength(value) orelse style.margin.top,
        .margin_right => style.margin.right = parseLength(value) orelse style.margin.right,
        .margin_bottom => style.margin.bottom = parseLength(value) orelse style.margin.bottom,
        .margin_left => style.margin.left = parseLength(value) orelse style.margin.left,
        .padding => style.padding = parseEdges(value) orelse style.padding,
        .padding_top => style.padding.top = parseLength(value) orelse style.padding.top,
        .padding_right => style.padding.right = parseLength(value) orelse style.padding.right,
        .padding_bottom => style.padding.bottom = parseLength(value) orelse style.padding.bottom,
        .padding_left => style.padding.left = parseLength(value) orelse style.padding.left,
        .border => applyBorderShorthand(style, value),
        .border_style => if (containsIgnoreCase(value, "none") or containsIgnoreCase(value, "hidden")) {
            style.border = .{};
        },
        .border_width => style.border = parseEdges(value) orelse style.border,
        .border_top => style.border.top = parseLength(value) orelse style.border.top,
        .border_right => style.border.right = parseLength(value) orelse style.border.right,
        .border_bottom => style.border.bottom = parseLength(value) orelse style.border.bottom,
        .border_left => style.border.left = parseLength(value) orelse style.border.left,
        .border_radius => style.border_radius = parseBorderRadii(value) orelse style.border_radius,
        .border_top_left_radius => style.border_radius.top_left = parseRadius(value) orelse style.border_radius.top_left,
        .border_top_right_radius => style.border_radius.top_right = parseRadius(value) orelse style.border_radius.top_right,
        .border_bottom_right_radius => style.border_radius.bottom_right = parseRadius(value) orelse style.border_radius.bottom_right,
        .border_bottom_left_radius => style.border_radius.bottom_left = parseRadius(value) orelse style.border_radius.bottom_left,
        .box_shadow => style.box_shadow = parseBoxShadow(value) orelse style.box_shadow,
        .color => style.color = parseColor(value) orelse style.color,
        .background => applyBackgroundShorthand(style, value),
        .background_color => style.background_color = if (equalsIgnoreCase(trim(value), "transparent")) null else parseColor(value) orelse style.background_color,
        .background_image => style.background_image = parseBackgroundImage(value) orelse style.background_image,
        .background_repeat => style.background_repeat = parseBackgroundRepeat(value) orelse style.background_repeat,
        .background_position => style.background_position = parseBackgroundPosition(value) orelse style.background_position,
        .background_size => style.background_size = parseBackgroundSize(value) orelse style.background_size,
        .border_color => style.border_color = parseColor(value) orelse style.border_color,
        .font_family => style.font_family = trim(value),
        .font_size => style.font_size = parseFontSize(value, style.font_size) orelse style.font_size,
        .font_weight => style.font_weight = parseFontWeight(value, style.font_weight),
        .font_style => style.italic = equalsIgnoreCase(trim(value), "italic") or startsWithIgnoreCase(trim(value), "oblique"),
        .line_height => style.line_height_value = parseLineHeight(value) orelse style.line_height_value,
        .text_align => style.text_align = parseTextAlign(value) orelse style.text_align,
        .text_decoration => style.underline = containsIgnoreCase(value, "underline"),
        .white_space => style.white_space = parseWhiteSpace(value) orelse style.white_space,
        .flex_direction => style.flex_direction = if (startsWithIgnoreCase(trim(value), "column")) .column else .row,
        .flex_wrap => style.flex_wrap = !equalsIgnoreCase(trim(value), "nowrap"),
        .flex => applyFlexShorthand(style, value),
        .flex_grow => style.flex_grow = parseUnsigned(value) orelse style.flex_grow,
        .flex_shrink => style.flex_shrink = parseUnsigned(value) orelse style.flex_shrink,
        .flex_basis => style.flex_basis = parseLength(value) orelse style.flex_basis,
        .justify_content => style.justify_content = parseJustifyContent(value) orelse style.justify_content,
        .align_items => style.align_items = parseAlignItems(value) orelse style.align_items,
        .gap => style.gap = (parseLength(value) orelse return).pixels(style.font_size, style.font_size, style.gap),
        .grid_template_columns => style.grid_columns = countGridColumns(value),
        .overflow => applyOverflowShorthand(style, value),
        .overflow_x => style.overflow_x = parseOverflow(value) orelse style.overflow_x,
        .overflow_y => style.overflow_y = parseOverflow(value) orelse style.overflow_y,
        .clip => style.clip_empty = parseEmptyClip(value),
        .content => applyContent(style, value),
    }
}

fn normalizeStyle(style: *ComputedStyle) void {
    style.font_size = clamp(style.font_size, 6, 72);
    style.line_height = switch (style.line_height_value.kind) {
        .normal => @divTrunc(style.font_size * 6 + 2, 5),
        .number => @divTrunc(style.font_size * style.line_height_value.number_hundred + 50, 100),
        .length => style.line_height_value.length.pixels(style.font_size, style.font_size, style.line_height),
    };
    style.line_height = clamp(style.line_height, 0, 192);
    style.gap = clamp(style.gap, 0, 128);
    if (style.grid_columns == 0) style.grid_columns = 1;
    if (style.overflow_x == .visible and style.overflow_y != .visible and style.overflow_y != .clip) style.overflow_x = .auto;
    if (style.overflow_y == .visible and style.overflow_x != .visible and style.overflow_x != .clip) style.overflow_y = .auto;
    if (style.overflow_x == .clip and style.overflow_y != .visible and style.overflow_y != .clip) style.overflow_x = .hidden;
    if (style.overflow_y == .clip and style.overflow_x != .visible and style.overflow_x != .clip) style.overflow_y = .hidden;
}

fn propertyFromName(name: []const u8) ?Property {
    const entries = [_]struct { name: []const u8, property: Property }{
        .{ .name = "display", .property = .display },
        .{ .name = "position", .property = .position },
        .{ .name = "visibility", .property = .visibility },
        .{ .name = "width", .property = .width },
        .{ .name = "height", .property = .height },
        .{ .name = "min-width", .property = .min_width },
        .{ .name = "max-width", .property = .max_width },
        .{ .name = "min-height", .property = .min_height },
        .{ .name = "max-height", .property = .max_height },
        .{ .name = "box-sizing", .property = .box_sizing },
        .{ .name = "left", .property = .left },
        .{ .name = "top", .property = .top },
        .{ .name = "right", .property = .right },
        .{ .name = "bottom", .property = .bottom },
        .{ .name = "margin", .property = .margin },
        .{ .name = "margin-top", .property = .margin_top },
        .{ .name = "margin-right", .property = .margin_right },
        .{ .name = "margin-bottom", .property = .margin_bottom },
        .{ .name = "margin-left", .property = .margin_left },
        .{ .name = "padding", .property = .padding },
        .{ .name = "padding-top", .property = .padding_top },
        .{ .name = "padding-right", .property = .padding_right },
        .{ .name = "padding-bottom", .property = .padding_bottom },
        .{ .name = "padding-left", .property = .padding_left },
        .{ .name = "border", .property = .border },
        .{ .name = "border-style", .property = .border_style },
        .{ .name = "border-width", .property = .border_width },
        .{ .name = "border-top-width", .property = .border_top },
        .{ .name = "border-right-width", .property = .border_right },
        .{ .name = "border-bottom-width", .property = .border_bottom },
        .{ .name = "border-left-width", .property = .border_left },
        .{ .name = "border-radius", .property = .border_radius },
        .{ .name = "border-top-left-radius", .property = .border_top_left_radius },
        .{ .name = "border-top-right-radius", .property = .border_top_right_radius },
        .{ .name = "border-bottom-right-radius", .property = .border_bottom_right_radius },
        .{ .name = "border-bottom-left-radius", .property = .border_bottom_left_radius },
        .{ .name = "box-shadow", .property = .box_shadow },
        .{ .name = "color", .property = .color },
        .{ .name = "background", .property = .background },
        .{ .name = "background-color", .property = .background_color },
        .{ .name = "background-image", .property = .background_image },
        .{ .name = "background-repeat", .property = .background_repeat },
        .{ .name = "background-position", .property = .background_position },
        .{ .name = "background-size", .property = .background_size },
        .{ .name = "border-color", .property = .border_color },
        .{ .name = "font-family", .property = .font_family },
        .{ .name = "font-size", .property = .font_size },
        .{ .name = "font-weight", .property = .font_weight },
        .{ .name = "font-style", .property = .font_style },
        .{ .name = "line-height", .property = .line_height },
        .{ .name = "text-align", .property = .text_align },
        .{ .name = "text-decoration", .property = .text_decoration },
        .{ .name = "white-space", .property = .white_space },
        .{ .name = "flex-direction", .property = .flex_direction },
        .{ .name = "flex-wrap", .property = .flex_wrap },
        .{ .name = "flex", .property = .flex },
        .{ .name = "flex-grow", .property = .flex_grow },
        .{ .name = "flex-shrink", .property = .flex_shrink },
        .{ .name = "flex-basis", .property = .flex_basis },
        .{ .name = "justify-content", .property = .justify_content },
        .{ .name = "align-items", .property = .align_items },
        .{ .name = "gap", .property = .gap },
        .{ .name = "grid-template-columns", .property = .grid_template_columns },
        .{ .name = "overflow", .property = .overflow },
        .{ .name = "overflow-x", .property = .overflow_x },
        .{ .name = "overflow-y", .property = .overflow_y },
        .{ .name = "clip", .property = .clip },
        .{ .name = "content", .property = .content },
    };
    for (entries) |entry| if (equalsIgnoreCase(trim(name), entry.name)) return entry.property;
    return null;
}

fn parseEdges(value: []const u8) ?Edges {
    var values: [4]Length = undefined;
    var count: usize = 0;
    var cursor: usize = 0;
    while (cursor < value.len and count < values.len) {
        while (cursor < value.len and isSpace(value[cursor])) : (cursor += 1) {}
        if (cursor >= value.len) break;
        const start = cursor;
        var paren_depth: usize = 0;
        while (cursor < value.len) : (cursor += 1) {
            if (value[cursor] == '(') {
                paren_depth += 1;
            } else if (value[cursor] == ')' and paren_depth > 0) {
                paren_depth -= 1;
            } else if (isSpace(value[cursor]) and paren_depth == 0) {
                break;
            }
        }
        values[count] = parseLength(value[start..cursor]) orelse return null;
        count += 1;
    }
    return switch (count) {
        1 => .{ .top = values[0], .right = values[0], .bottom = values[0], .left = values[0] },
        2 => .{ .top = values[0], .right = values[1], .bottom = values[0], .left = values[1] },
        3 => .{ .top = values[0], .right = values[1], .bottom = values[2], .left = values[1] },
        4 => .{ .top = values[0], .right = values[1], .bottom = values[2], .left = values[3] },
        else => null,
    };
}

const ParsedBackground = struct {
    color: ?u32 = null,
    image: BackgroundImage = .{},
    repeat: BackgroundRepeat = .repeat,
    position: BackgroundPosition = .{},
    size: BackgroundSize = .{},
};

fn applyBackgroundShorthand(style: *ComputedStyle, value: []const u8) void {
    const parsed = parseBackgroundShorthand(value) orelse return;
    style.background_color = parsed.color;
    style.background_image = parsed.image;
    style.background_repeat = parsed.repeat;
    style.background_position = parsed.position;
    style.background_size = parsed.size;
}

fn parseBackgroundShorthand(value: []const u8) ?ParsedBackground {
    const input = trim(value);
    if (input.len == 0 or !hasSingleBackgroundLayer(input)) return null;

    var result = ParsedBackground{};
    var image_seen = false;
    var color_seen = false;
    var slash_seen = false;
    var position_tokens: [2][]const u8 = .{ "", "" };
    var position_count: usize = 0;
    var size_tokens: [2][]const u8 = .{ "", "" };
    var size_count: usize = 0;
    var repeat_tokens: [2][]const u8 = .{ "", "" };
    var repeat_count: usize = 0;
    var cursor: usize = 0;

    while (nextBackgroundToken(input, &cursor)) |token| {
        if (equals(token, "/")) {
            if (slash_seen or position_count == 0) return null;
            slash_seen = true;
            continue;
        }
        if (isBackgroundRepeatToken(token)) {
            if (repeat_count >= repeat_tokens.len) return null;
            repeat_tokens[repeat_count] = token;
            repeat_count += 1;
            continue;
        }
        if (parseBackgroundImage(token)) |image| {
            if (image_seen) return null;
            result.image = image;
            image_seen = true;
            continue;
        }
        if (equalsIgnoreCase(token, "transparent")) {
            if (color_seen) return null;
            result.color = null;
            color_seen = true;
            continue;
        }
        if (parseColor(token)) |color| {
            if (color_seen) return null;
            result.color = color;
            color_seen = true;
            continue;
        }
        if (slash_seen) {
            if (size_count >= size_tokens.len) return null;
            size_tokens[size_count] = token;
            size_count += 1;
        } else {
            if (position_count >= position_tokens.len) return null;
            position_tokens[position_count] = token;
            position_count += 1;
        }
    }

    if (repeat_count > 0) result.repeat = parseBackgroundRepeatTokens(repeat_tokens[0..repeat_count]) orelse return null;
    if (position_count > 0) result.position = parseBackgroundPositionTokens(position_tokens[0..position_count]) orelse return null;
    if (slash_seen) {
        if (size_count == 0) return null;
        result.size = parseBackgroundSizeTokens(size_tokens[0..size_count]) orelse return null;
    }
    return result;
}

fn parseBackgroundImage(value: []const u8) ?BackgroundImage {
    const input = trim(value);
    if (equalsIgnoreCase(input, "none")) return .{};
    if (!hasSingleBackgroundLayer(input)) return null;
    if (isCompleteCssFunction(input, "url")) return .{ .kind = .url, .raw_value = input };
    if (isCompleteCssFunction(input, "image-set")) return .{ .kind = .image_set, .raw_value = input };
    return null;
}

fn parseBackgroundRepeat(value: []const u8) ?BackgroundRepeat {
    const input = trim(value);
    if (input.len == 0 or !hasSingleBackgroundLayer(input)) return null;
    var tokens: [2][]const u8 = .{ "", "" };
    var count: usize = 0;
    var cursor: usize = 0;
    while (nextCssValueToken(input, &cursor)) |token| {
        if (count >= tokens.len) return null;
        tokens[count] = token;
        count += 1;
    }
    return parseBackgroundRepeatTokens(tokens[0..count]);
}

fn parseBackgroundRepeatTokens(tokens: []const []const u8) ?BackgroundRepeat {
    if (tokens.len == 1) {
        if (equalsIgnoreCase(tokens[0], "repeat")) return .repeat;
        if (equalsIgnoreCase(tokens[0], "no-repeat")) return .no_repeat;
        if (equalsIgnoreCase(tokens[0], "repeat-x")) return .repeat_x;
        if (equalsIgnoreCase(tokens[0], "repeat-y")) return .repeat_y;
        return null;
    }
    if (tokens.len != 2) return null;
    const horizontal_repeat = if (equalsIgnoreCase(tokens[0], "repeat"))
        true
    else if (equalsIgnoreCase(tokens[0], "no-repeat"))
        false
    else
        return null;
    const vertical_repeat = if (equalsIgnoreCase(tokens[1], "repeat"))
        true
    else if (equalsIgnoreCase(tokens[1], "no-repeat"))
        false
    else
        return null;
    if (horizontal_repeat and vertical_repeat) return .repeat;
    if (horizontal_repeat) return .repeat_x;
    if (vertical_repeat) return .repeat_y;
    return .no_repeat;
}

fn isBackgroundRepeatToken(value: []const u8) bool {
    return equalsIgnoreCase(value, "repeat") or equalsIgnoreCase(value, "no-repeat") or
        equalsIgnoreCase(value, "repeat-x") or equalsIgnoreCase(value, "repeat-y");
}

fn parseBackgroundPosition(value: []const u8) ?BackgroundPosition {
    const input = trim(value);
    if (input.len == 0 or !hasSingleBackgroundLayer(input)) return null;
    var tokens: [2][]const u8 = .{ "", "" };
    var count: usize = 0;
    var cursor: usize = 0;
    while (nextCssValueToken(input, &cursor)) |token| {
        if (count >= tokens.len) return null;
        tokens[count] = token;
        count += 1;
    }
    return parseBackgroundPositionTokens(tokens[0..count]);
}

fn parseBackgroundPositionTokens(tokens: []const []const u8) ?BackgroundPosition {
    const center = Length{ .kind = .percent, .value = 50 };
    if (tokens.len == 1) {
        const token = tokens[0];
        if (parseBackgroundPositionComponent(token, true)) |horizontal| return .{ .x = horizontal, .y = center };
        if (parseBackgroundPositionComponent(token, false)) |vertical| return .{ .x = center, .y = vertical };
        return null;
    }
    if (tokens.len != 2) return null;
    if (parseBackgroundPositionComponent(tokens[0], true)) |horizontal| {
        if (parseBackgroundPositionComponent(tokens[1], false)) |vertical| return .{ .x = horizontal, .y = vertical };
    }
    if (parseBackgroundPositionComponent(tokens[1], true)) |horizontal| {
        if (parseBackgroundPositionComponent(tokens[0], false)) |vertical| return .{ .x = horizontal, .y = vertical };
    }
    return null;
}

fn parseBackgroundPositionComponent(value: []const u8, horizontal: bool) ?Length {
    if (equalsIgnoreCase(value, "center")) return .{ .kind = .percent, .value = 50 };
    if (horizontal) {
        if (equalsIgnoreCase(value, "left")) return .{ .kind = .percent, .value = 0 };
        if (equalsIgnoreCase(value, "right")) return .{ .kind = .percent, .value = 100 };
    } else {
        if (equalsIgnoreCase(value, "top")) return .{ .kind = .percent, .value = 0 };
        if (equalsIgnoreCase(value, "bottom")) return .{ .kind = .percent, .value = 100 };
    }
    const length = parseLength(value) orelse return null;
    return if (length.kind == .px or length.kind == .percent) length else null;
}

fn parseBackgroundSize(value: []const u8) ?BackgroundSize {
    const input = trim(value);
    if (input.len == 0 or !hasSingleBackgroundLayer(input)) return null;
    var tokens: [2][]const u8 = .{ "", "" };
    var count: usize = 0;
    var cursor: usize = 0;
    while (nextCssValueToken(input, &cursor)) |token| {
        if (count >= tokens.len) return null;
        tokens[count] = token;
        count += 1;
    }
    return parseBackgroundSizeTokens(tokens[0..count]);
}

fn parseBackgroundSizeTokens(tokens: []const []const u8) ?BackgroundSize {
    if (tokens.len == 1) {
        if (equalsIgnoreCase(tokens[0], "auto")) return .{};
        if (equalsIgnoreCase(tokens[0], "contain")) return .{ .kind = .contain };
        if (equalsIgnoreCase(tokens[0], "cover")) return .{ .kind = .cover };
        return .{ .kind = .explicit, .width = parseBackgroundSizeLength(tokens[0]) orelse return null };
    }
    if (tokens.len != 2) return null;
    const width = parseBackgroundSizeLength(tokens[0]) orelse return null;
    const height = parseBackgroundSizeLength(tokens[1]) orelse return null;
    if (width.kind == .auto and height.kind == .auto) return .{};
    return .{ .kind = .explicit, .width = width, .height = height };
}

fn parseBackgroundSizeLength(value: []const u8) ?Length {
    const length = parseLength(value) orelse return null;
    if (length.kind != .auto and length.kind != .px and length.kind != .percent) return null;
    if (length.kind != .auto and length.value < 0) return null;
    return length;
}

fn hasSingleBackgroundLayer(value: []const u8) bool {
    var depth: usize = 0;
    var quote: u8 = 0;
    var escaped = false;
    for (value) |byte| {
        if (quote != 0) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == quote) {
                quote = 0;
            }
            continue;
        }
        if (byte == '\'' or byte == '"') {
            quote = byte;
        } else if (byte == '(') {
            depth += 1;
        } else if (byte == ')') {
            if (depth == 0) return false;
            depth -= 1;
        } else if (byte == ',' and depth == 0) {
            return false;
        }
    }
    return depth == 0 and quote == 0 and !escaped;
}

fn isCompleteCssFunction(value: []const u8, name: []const u8) bool {
    if (value.len <= name.len + 2 or !startsWithIgnoreCase(value, name) or value[name.len] != '(') return false;
    var depth: usize = 0;
    var quote: u8 = 0;
    var escaped = false;
    var cursor = name.len;
    while (cursor < value.len) : (cursor += 1) {
        const byte = value[cursor];
        if (quote != 0) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == quote) {
                quote = 0;
            }
            continue;
        }
        if (byte == '\'' or byte == '"') {
            quote = byte;
        } else if (byte == '(') {
            depth += 1;
        } else if (byte == ')') {
            if (depth == 0) return false;
            depth -= 1;
            if (depth == 0 and cursor + 1 != value.len) return false;
        }
    }
    return depth == 0 and quote == 0 and !escaped;
}

fn nextBackgroundToken(value: []const u8, cursor: *usize) ?[]const u8 {
    while (cursor.* < value.len and isSpace(value[cursor.*])) cursor.* += 1;
    if (cursor.* >= value.len) return null;
    if (value[cursor.*] == '/') {
        const start = cursor.*;
        cursor.* += 1;
        return value[start..cursor.*];
    }
    const start = cursor.*;
    var depth: usize = 0;
    var quote: u8 = 0;
    var escaped = false;
    while (cursor.* < value.len) : (cursor.* += 1) {
        const byte = value[cursor.*];
        if (quote != 0) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == quote) {
                quote = 0;
            }
            continue;
        }
        if (byte == '\'' or byte == '"') {
            quote = byte;
        } else if (byte == '(') {
            depth += 1;
        } else if (byte == ')' and depth > 0) {
            depth -= 1;
        } else if (depth == 0 and (isSpace(byte) or byte == '/')) {
            break;
        }
    }
    return trim(value[start..cursor.*]);
}

fn applyBorderShorthand(style: *ComputedStyle, value: []const u8) void {
    const input = trim(value);
    if (equalsIgnoreCase(input, "none") or equalsIgnoreCase(input, "hidden")) {
        style.border = .{};
        return;
    }
    var width: ?Length = null;
    var color: ?u32 = null;
    var cursor: usize = 0;
    while (nextCssValueToken(input, &cursor)) |token| {
        if (equalsIgnoreCase(token, "none") or equalsIgnoreCase(token, "hidden")) {
            style.border = .{};
            return;
        }
        if (isBorderStyleKeyword(token)) continue;
        if (parseColorWithAlpha(token)) |parsed| {
            color = parsed.rgb;
            continue;
        }
        if (width == null) width = parseLength(token);
    }
    if (width) |length| {
        style.border = .{ .top = length, .right = length, .bottom = length, .left = length };
    }
    if (color) |rgb| style.border_color = rgb;
}

fn isBorderStyleKeyword(value: []const u8) bool {
    const names = [_][]const u8{ "solid", "dotted", "dashed", "double", "groove", "ridge", "inset", "outset" };
    for (names) |name| if (equalsIgnoreCase(value, name)) return true;
    return false;
}

fn parseBorderRadii(value: []const u8) ?BorderRadii {
    const input = trim(value);
    var slash = input.len;
    var depth: usize = 0;
    for (input, 0..) |byte, index| {
        if (byte == '(') depth += 1 else if (byte == ')' and depth > 0) depth -= 1 else if (byte == '/' and depth == 0) {
            slash = index;
            break;
        }
    }
    const horizontal = parseEdges(trim(input[0..slash])) orelse return null;
    const vertical = if (slash < input.len)
        parseEdges(trim(input[slash + 1 ..])) orelse return null
    else
        horizontal;
    return .{
        .top_left = .{ .x = horizontal.top, .y = vertical.top },
        .top_right = .{ .x = horizontal.right, .y = vertical.right },
        .bottom_right = .{ .x = horizontal.bottom, .y = vertical.bottom },
        .bottom_left = .{ .x = horizontal.left, .y = vertical.left },
    };
}

fn parseRadius(value: []const u8) ?BorderRadius {
    var cursor: usize = 0;
    const input = trim(value);
    const first = parseLength(nextCssValueToken(input, &cursor) orelse return null) orelse return null;
    const second = if (nextCssValueToken(input, &cursor)) |token| parseLength(token) orelse return null else first;
    if (nextCssValueToken(input, &cursor) != null) return null;
    return .{ .x = first, .y = second };
}

fn parseBoxShadow(value: []const u8) ?BoxShadow {
    const input = trim(value);
    if (equalsIgnoreCase(input, "none")) return .{};
    var result = BoxShadow{};
    var start: usize = 0;
    var depth: usize = 0;
    var cursor: usize = 0;
    while (cursor <= input.len) : (cursor += 1) {
        const at_end = cursor == input.len;
        const byte = if (at_end) @as(u8, ',') else input[cursor];
        if (!at_end and byte == '(') {
            depth += 1;
            continue;
        }
        if (!at_end and byte == ')' and depth > 0) {
            depth -= 1;
            continue;
        }
        if (byte != ',' or depth != 0) continue;
        if (result.count >= max_box_shadow_layers) return null;
        result.layers[result.count] = parseBoxShadowLayer(trim(input[start..cursor])) orelse return null;
        result.count += 1;
        start = cursor + 1;
    }
    if (depth != 0 or result.count == 0) return null;
    return result;
}

fn parseBoxShadowLayer(input: []const u8) ?BoxShadowLayer {
    if (input.len == 0 or equalsIgnoreCase(input, "none")) return null;
    var lengths: [4]Length = .{Length{ .kind = .px }} ** 4;
    var length_count: usize = 0;
    var result = BoxShadowLayer{};
    var cursor: usize = 0;
    while (nextCssValueToken(input, &cursor)) |token| {
        if (equalsIgnoreCase(token, "inset")) {
            result.inset = true;
            continue;
        }
        if (parseColorWithAlpha(token)) |color| {
            result.color = color.rgb;
            result.alpha = color.alpha;
            continue;
        }
        if (length_count >= lengths.len) return null;
        lengths[length_count] = parseLength(token) orelse return null;
        length_count += 1;
    }
    if (length_count < 2) return null;
    result.offset_x = lengths[0];
    result.offset_y = lengths[1];
    if (length_count >= 3) result.blur = lengths[2];
    if (length_count >= 4) result.spread = lengths[3];
    return result;
}

fn nextCssValueToken(value: []const u8, cursor: *usize) ?[]const u8 {
    while (cursor.* < value.len and isSpace(value[cursor.*])) cursor.* += 1;
    if (cursor.* >= value.len) return null;
    const start = cursor.*;
    var depth: usize = 0;
    while (cursor.* < value.len) : (cursor.* += 1) {
        const byte = value[cursor.*];
        if (byte == '(') {
            depth += 1;
        } else if (byte == ')' and depth > 0) {
            depth -= 1;
        } else if (isSpace(byte) and depth == 0) {
            break;
        }
    }
    return trim(value[start..cursor.*]);
}

fn selectorMatches(document: *const html.Document, node_index: u16, selector_input: []const u8, state: ElementState, pseudo: PseudoElement) bool {
    var selector = trim(selector_input);
    const selector_pseudo = selectorPseudoElement(selector);
    if (selector_pseudo != pseudo) return false;
    if (selector_pseudo != .none) selector = stripPseudoElement(selector);

    var parts: [max_selector_parts]Range = undefined;
    var combinators: [max_selector_parts]u8 = .{' '} ** max_selector_parts;
    const count = splitSelector(selector, &parts, &combinators) catch return false;
    if (count == 0) return false;
    return selectorPartsMatch(document, node_index, node_index, selector, &parts, &combinators, count - 1, state);
}

fn selectorPartsMatch(
    document: *const html.Document,
    target_node: u16,
    current_node: u16,
    selector: []const u8,
    parts: *const [max_selector_parts]Range,
    combinators: *const [max_selector_parts]u8,
    part_index: usize,
    target_state: ElementState,
) bool {
    const state = if (current_node == target_node) target_state else relatedElementState(document, current_node, target_state);
    if (!compoundMatches(document, current_node, selector[parts[part_index].start..parts[part_index].end], state)) return false;
    if (part_index == 0) return true;

    switch (combinators[part_index]) {
        '>' => {
            const parent = elementParent(document, current_node) orelse return false;
            return selectorPartsMatch(document, target_node, parent, selector, parts, combinators, part_index - 1, target_state);
        },
        '+' => {
            const sibling = previousElementSibling(document, current_node) orelse return false;
            return selectorPartsMatch(document, target_node, sibling, selector, parts, combinators, part_index - 1, target_state);
        },
        '~' => {
            var sibling = previousElementSibling(document, current_node);
            while (sibling) |candidate| {
                if (selectorPartsMatch(document, target_node, candidate, selector, parts, combinators, part_index - 1, target_state)) return true;
                sibling = previousElementSibling(document, candidate);
            }
            return false;
        },
        else => {
            var parent = elementParent(document, current_node);
            while (parent) |candidate| {
                if (selectorPartsMatch(document, target_node, candidate, selector, parts, combinators, part_index - 1, target_state)) return true;
                parent = elementParent(document, candidate);
            }
            return false;
        },
    }
}

fn staticElementState(document: *const html.Document, node_index: u16) ElementState {
    return .{
        .link = document.attribute(node_index, "href") != null,
        .disabled = document.attribute(node_index, "disabled") != null,
    };
}

fn relatedElementState(document: *const html.Document, node_index: u16, context: ElementState) ElementState {
    var state = staticElementState(document, node_index);
    state.hovered_node = context.hovered_node;
    state.focused_node = context.focused_node;
    state.active_node = context.active_node;
    state.hover = context.hovered_node != html.none and nodeIsInclusiveAncestor(document, node_index, context.hovered_node);
    state.focus = context.focused_node == node_index;
    state.focus_within = context.focused_node != html.none and nodeIsInclusiveAncestor(document, node_index, context.focused_node);
    state.active = context.active_node != html.none and nodeIsInclusiveAncestor(document, node_index, context.active_node);
    return state;
}

fn nodeIsInclusiveAncestor(document: *const html.Document, ancestor: u16, node: u16) bool {
    if (ancestor >= document.node_count or node >= document.node_count) return false;
    var current = node;
    while (current != html.none and current < document.node_count) {
        if (current == ancestor) return true;
        current = document.nodes[current].parent;
    }
    return false;
}

fn elementParent(document: *const html.Document, node_index: u16) ?u16 {
    if (node_index >= document.node_count) return null;
    const parent = document.nodes[node_index].parent;
    if (parent == html.none or parent >= document.node_count or document.nodes[parent].kind != .element) return null;
    return parent;
}

fn previousElementSibling(document: *const html.Document, node_index: u16) ?u16 {
    if (node_index >= document.node_count) return null;
    const parent = document.nodes[node_index].parent;
    if (parent == html.none or parent >= document.node_count) return null;
    var previous: ?u16 = null;
    var cursor = document.nodes[parent].first_child;
    while (cursor != html.none and cursor < document.node_count and cursor != node_index) {
        if (document.nodes[cursor].kind == .element) previous = cursor;
        cursor = document.nodes[cursor].next_sibling;
    }
    return if (cursor == node_index) previous else null;
}

pub fn matchesSelector(document: *const html.Document, node_index: u16, selector_input: []const u8) bool {
    var start: usize = 0;
    var cursor: usize = 0;
    var bracket_depth: usize = 0;
    var paren_depth: usize = 0;
    while (cursor <= selector_input.len) : (cursor += 1) {
        const at_end = cursor == selector_input.len;
        if (!at_end) {
            const byte = selector_input[cursor];
            if (byte == '[') bracket_depth += 1 else if (byte == ']' and bracket_depth > 0) bracket_depth -= 1;
            if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
            if (byte != ',' or bracket_depth != 0 or paren_depth != 0) continue;
        }
        const selector = trim(selector_input[start..cursor]);
        if (selector.len > 0 and selectorMatches(document, node_index, selector, .{}, .none)) return true;
        start = cursor + 1;
    }
    return false;
}

fn splitSelector(selector: []const u8, parts: *[max_selector_parts]Range, combinators: *[max_selector_parts]u8) Error!usize {
    var count: usize = 0;
    var cursor: usize = 0;
    var pending_combinator: u8 = ' ';
    while (cursor < selector.len) {
        var consumed_space = false;
        while (cursor < selector.len and isSpace(selector[cursor])) : (cursor += 1) consumed_space = true;
        if (cursor >= selector.len) break;
        if (selector[cursor] == '>' or selector[cursor] == '+' or selector[cursor] == '~') {
            pending_combinator = selector[cursor];
            cursor += 1;
            continue;
        }
        if (count > 0 and consumed_space and pending_combinator == ' ') pending_combinator = ' ';
        const start = cursor;
        var bracket_depth: usize = 0;
        var paren_depth: usize = 0;
        var quote: u8 = 0;
        while (cursor < selector.len) : (cursor += 1) {
            const byte = selector[cursor];
            if (quote != 0) {
                if (byte == '\\' and cursor + 1 < selector.len) {
                    cursor += 1;
                } else if (byte == quote) {
                    quote = 0;
                }
                continue;
            }
            if (byte == '"' or byte == '\'') {
                quote = byte;
                continue;
            }
            if (byte == '\\' and cursor + 1 < selector.len) {
                cursor += 1;
                continue;
            }
            if (byte == '[') bracket_depth += 1 else if (byte == ']' and bracket_depth > 0) bracket_depth -= 1;
            if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
            if (bracket_depth == 0 and paren_depth == 0 and (byte == '>' or byte == '+' or byte == '~' or isSpace(byte))) break;
        }
        if (count >= parts.len) return error.SelectorLimit;
        parts[count] = .{ .start = start, .end = cursor };
        combinators[count] = pending_combinator;
        pending_combinator = ' ';
        count += 1;
    }
    return count;
}

fn compoundMatches(document: *const html.Document, node_index: u16, compound: []const u8, state: ElementState) bool {
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element) return false;
    var cursor: usize = 0;
    if (cursor < compound.len and compound[cursor] == '*') {
        cursor += 1;
    } else if (cursor < compound.len and isIdentStart(compound[cursor])) {
        const start = cursor;
        while (cursor < compound.len and isIdentByte(compound[cursor])) : (cursor += 1) {}
        if (!equalsIgnoreCase(document.nodeName(node_index), compound[start..cursor])) return false;
    }
    while (cursor < compound.len) {
        const marker = compound[cursor];
        cursor += 1;
        if (marker == '#') {
            const start = cursor;
            scanCssIdentifier(compound, &cursor);
            if (!cssEscapedEquals(document.attribute(node_index, "id") orelse "", compound[start..cursor])) return false;
        } else if (marker == '.') {
            const start = cursor;
            scanCssIdentifier(compound, &cursor);
            if (!classContainsEscaped(document.attribute(node_index, "class") orelse "", compound[start..cursor])) return false;
        } else if (marker == '[') {
            const close = findClosingDelimiter(compound, cursor - 1, '[', ']') orelse return false;
            const expression = trim(compound[cursor..close]);
            if (!attributeSelectorMatches(document, node_index, expression)) return false;
            cursor = close + 1;
        } else if (marker == ':') {
            if (cursor < compound.len and compound[cursor] == ':') return false;
            const start = cursor;
            while (cursor < compound.len and isIdentByte(compound[cursor])) : (cursor += 1) {}
            const name = compound[start..cursor];
            var argument: []const u8 = "";
            if (cursor < compound.len and compound[cursor] == '(') {
                const close = findClosingDelimiter(compound, cursor, '(', ')') orelse return false;
                argument = trim(compound[cursor + 1 .. close]);
                cursor = close + 1;
            }
            if (!pseudoClassMatches(document, node_index, name, argument, state)) return false;
        } else {
            return false;
        }
    }
    return true;
}

fn findClosingDelimiter(value: []const u8, opening: usize, open: u8, close: u8) ?usize {
    if (opening >= value.len or value[opening] != open) return null;
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
        } else if (byte == '\\' and cursor + 1 < value.len) {
            cursor += 1;
        } else if (byte == open) {
            depth += 1;
        } else if (byte == close) {
            depth -= 1;
            if (depth == 0) return cursor;
        }
    }
    return null;
}

fn attributeSelectorMatches(document: *const html.Document, node_index: u16, expression_input: []const u8) bool {
    const expression = trim(expression_input);
    var operator_start: ?usize = null;
    var operator_len: usize = 0;
    var quote: u8 = 0;
    var cursor: usize = 0;
    while (cursor < expression.len) : (cursor += 1) {
        const byte = expression[cursor];
        if (quote != 0) {
            if (byte == '\\' and cursor + 1 < expression.len) cursor += 1 else if (byte == quote) quote = 0;
            continue;
        }
        if (byte == '"' or byte == '\'') {
            quote = byte;
            continue;
        }
        if (cursor + 1 < expression.len and expression[cursor + 1] == '=' and
            (byte == '~' or byte == '|' or byte == '^' or byte == '$' or byte == '*'))
        {
            operator_start = cursor;
            operator_len = 2;
            break;
        }
        if (byte == '=') {
            operator_start = cursor;
            operator_len = 1;
            break;
        }
    }

    const name = trim(expression[0 .. operator_start orelse expression.len]);
    if (name.len == 0) return false;
    const actual = document.attribute(node_index, name) orelse return false;
    const position = operator_start orelse return true;
    const operator = expression[position .. position + operator_len];
    var expected_source = trim(expression[position + operator_len ..]);
    var insensitive = false;
    if (attributeModifier(expected_source)) |modifier| {
        insensitive = modifier.insensitive;
        expected_source = trim(expected_source[0..modifier.start]);
    }
    const expected = unquote(expected_source);
    if (expected.len == 0 and !std.mem.eql(u8, operator, "=")) return false;

    if (std.mem.eql(u8, operator, "=")) return attributeValueEquals(actual, expected, insensitive);
    if (std.mem.eql(u8, operator, "~=")) return attributeWordContains(actual, expected, insensitive);
    if (std.mem.eql(u8, operator, "|=")) {
        return attributeValueEquals(actual, expected, insensitive) or
            (actual.len > expected.len and actual[expected.len] == '-' and attributeValueEquals(actual[0..expected.len], expected, insensitive));
    }
    if (std.mem.eql(u8, operator, "^=")) return actual.len >= expected.len and attributeValueEquals(actual[0..expected.len], expected, insensitive);
    if (std.mem.eql(u8, operator, "$=")) return actual.len >= expected.len and attributeValueEquals(actual[actual.len - expected.len ..], expected, insensitive);
    if (std.mem.eql(u8, operator, "*=")) return if (insensitive) containsIgnoreCase(actual, expected) else std.mem.indexOf(u8, actual, expected) != null;
    return false;
}

const AttributeModifier = struct {
    start: usize,
    insensitive: bool,
};

fn attributeModifier(value: []const u8) ?AttributeModifier {
    var end = value.len;
    while (end > 0 and isSpace(value[end - 1])) end -= 1;
    if (end == 0) return null;
    const marker = value[end - 1];
    if (marker != 'i' and marker != 'I' and marker != 's' and marker != 'S') return null;
    if (end == 1 or !isSpace(value[end - 2])) return null;
    var start = end - 1;
    while (start > 0 and isSpace(value[start - 1])) start -= 1;
    return .{ .start = start, .insensitive = marker == 'i' or marker == 'I' };
}

fn attributeValueEquals(actual: []const u8, expected: []const u8, insensitive: bool) bool {
    return if (insensitive) equalsIgnoreCase(actual, expected) else std.mem.eql(u8, actual, expected);
}

fn attributeWordContains(actual: []const u8, expected: []const u8, insensitive: bool) bool {
    var cursor: usize = 0;
    while (cursor < actual.len) {
        while (cursor < actual.len and isSpace(actual[cursor])) : (cursor += 1) {}
        const start = cursor;
        while (cursor < actual.len and !isSpace(actual[cursor])) : (cursor += 1) {}
        if (start < cursor and attributeValueEquals(actual[start..cursor], expected, insensitive)) return true;
    }
    return false;
}

fn pseudoClassMatches(document: *const html.Document, node_index: u16, name: []const u8, argument: []const u8, state: ElementState) bool {
    if (equalsIgnoreCase(name, "root")) {
        const parent = document.nodes[node_index].parent;
        return parent != html.none and parent < document.node_count and document.nodes[parent].kind == .document;
    }
    if (equalsIgnoreCase(name, "link") or equalsIgnoreCase(name, "any-link")) return state.link or document.attribute(node_index, "href") != null;
    if (equalsIgnoreCase(name, "hover")) return state.hover;
    if (equalsIgnoreCase(name, "focus")) return state.focus;
    if (equalsIgnoreCase(name, "focus-visible")) return state.focus;
    if (equalsIgnoreCase(name, "focus-within")) return state.focus_within or state.focus;
    if (equalsIgnoreCase(name, "active")) return state.active;
    if (equalsIgnoreCase(name, "disabled")) return supportsEnabledState(document, node_index) and state.disabled;
    if (equalsIgnoreCase(name, "enabled")) return supportsEnabledState(document, node_index) and !state.disabled;
    if (equalsIgnoreCase(name, "checked")) return document.attribute(node_index, "checked") != null or document.attribute(node_index, "selected") != null;
    if (equalsIgnoreCase(name, "required")) return document.attribute(node_index, "required") != null;
    if (equalsIgnoreCase(name, "optional")) return supportsRequiredState(document, node_index) and document.attribute(node_index, "required") == null;
    if (equalsIgnoreCase(name, "read-only")) return document.attribute(node_index, "readonly") != null;
    if (equalsIgnoreCase(name, "read-write")) return supportsReadWriteState(document, node_index) and document.attribute(node_index, "readonly") == null;
    if (equalsIgnoreCase(name, "placeholder-shown")) {
        const value: []const u8 = document.attribute(node_index, "value") orelse "";
        return document.attribute(node_index, "placeholder") != null and value.len == 0;
    }
    if (equalsIgnoreCase(name, "scope")) return true;
    if (equalsIgnoreCase(name, "not")) return !selectorListMatchesState(document, node_index, argument, state);
    if (equalsIgnoreCase(name, "is") or equalsIgnoreCase(name, "where")) return selectorListMatchesState(document, node_index, argument, state);
    if (equalsIgnoreCase(name, "has")) return relativeSelectorListMatches(document, node_index, argument, state);
    if (equalsIgnoreCase(name, "empty")) return elementIsEmpty(document, node_index);
    if (equalsIgnoreCase(name, "lang")) return languageMatches(document, node_index, unquote(trim(argument)));
    if (equalsIgnoreCase(name, "first-child")) return elementSiblingIndex(document, node_index) == 1;
    if (equalsIgnoreCase(name, "last-child")) return isLastElementChild(document, node_index);
    if (equalsIgnoreCase(name, "only-child")) return elementSiblingIndex(document, node_index) == 1 and isLastElementChild(document, node_index);
    if (equalsIgnoreCase(name, "nth-child")) {
        return nthExpressionMatches(elementSiblingIndex(document, node_index), argument);
    }
    if (equalsIgnoreCase(name, "nth-last-child")) return nthExpressionMatches(elementSiblingIndexFromEnd(document, node_index), argument);
    if (equalsIgnoreCase(name, "first-of-type")) return elementTypeSiblingIndex(document, node_index) == 1;
    if (equalsIgnoreCase(name, "last-of-type")) return elementTypeSiblingIndexFromEnd(document, node_index) == 1;
    if (equalsIgnoreCase(name, "only-of-type")) return elementTypeSiblingIndex(document, node_index) == 1 and elementTypeSiblingIndexFromEnd(document, node_index) == 1;
    if (equalsIgnoreCase(name, "nth-of-type")) return nthExpressionMatches(elementTypeSiblingIndex(document, node_index), argument);
    if (equalsIgnoreCase(name, "nth-last-of-type")) return nthExpressionMatches(elementTypeSiblingIndexFromEnd(document, node_index), argument);
    return false;
}

fn selectorListMatchesState(document: *const html.Document, node_index: u16, selector_list: []const u8, state: ElementState) bool {
    var start: usize = 0;
    var cursor: usize = 0;
    var bracket_depth: usize = 0;
    var paren_depth: usize = 0;
    var quote: u8 = 0;
    while (cursor <= selector_list.len) : (cursor += 1) {
        const at_end = cursor == selector_list.len;
        if (!at_end) {
            const byte = selector_list[cursor];
            if (quote != 0) {
                if (byte == '\\' and cursor + 1 < selector_list.len) cursor += 1 else if (byte == quote) quote = 0;
                continue;
            }
            if (byte == '"' or byte == '\'') {
                quote = byte;
                continue;
            }
            if (byte == '[') bracket_depth += 1 else if (byte == ']' and bracket_depth > 0) bracket_depth -= 1;
            if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
            if (byte != ',' or bracket_depth != 0 or paren_depth != 0) continue;
        }
        const selector = trim(selector_list[start..cursor]);
        if (selector.len > 0 and selectorMatches(document, node_index, selector, state, .none)) return true;
        start = cursor + 1;
    }
    return false;
}

fn relativeSelectorListMatches(document: *const html.Document, node_index: u16, selector_list: []const u8, state: ElementState) bool {
    var start: usize = 0;
    var cursor: usize = 0;
    var bracket_depth: usize = 0;
    var paren_depth: usize = 0;
    while (cursor <= selector_list.len) : (cursor += 1) {
        const at_end = cursor == selector_list.len;
        if (!at_end) {
            const byte = selector_list[cursor];
            if (byte == '[') bracket_depth += 1 else if (byte == ']' and bracket_depth > 0) bracket_depth -= 1;
            if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
            if (byte != ',' or bracket_depth != 0 or paren_depth != 0) continue;
        }
        const selector = trim(selector_list[start..cursor]);
        if (selector.len > 0 and relativeSelectorMatches(document, node_index, selector, state)) return true;
        start = cursor + 1;
    }
    return false;
}

fn relativeSelectorMatches(document: *const html.Document, node_index: u16, selector: []const u8, state: ElementState) bool {
    if (selector[0] == '>') {
        const child_selector = trim(selector[1..]);
        var child = document.nodes[node_index].first_child;
        while (child != html.none and child < document.node_count) {
            if (document.nodes[child].kind == .element and selectorMatches(document, child, child_selector, relatedElementState(document, child, state), .none)) return true;
            child = document.nodes[child].next_sibling;
        }
        return false;
    }
    if (selector[0] == '+') {
        const sibling = nextElementSibling(document, node_index) orelse return false;
        return selectorMatches(document, sibling, trim(selector[1..]), relatedElementState(document, sibling, state), .none);
    }
    if (selector[0] == '~') {
        var sibling = nextElementSibling(document, node_index);
        while (sibling) |candidate| {
            if (selectorMatches(document, candidate, trim(selector[1..]), relatedElementState(document, candidate, state), .none)) return true;
            sibling = nextElementSibling(document, candidate);
        }
        return false;
    }
    return descendantMatchesSelector(document, node_index, selector, state);
}

fn descendantMatchesSelector(document: *const html.Document, node_index: u16, selector: []const u8, state: ElementState) bool {
    var child = document.nodes[node_index].first_child;
    while (child != html.none and child < document.node_count) {
        if (document.nodes[child].kind == .element) {
            if (selectorMatches(document, child, selector, relatedElementState(document, child, state), .none)) return true;
            if (descendantMatchesSelector(document, child, selector, state)) return true;
        }
        child = document.nodes[child].next_sibling;
    }
    return false;
}

fn nextElementSibling(document: *const html.Document, node_index: u16) ?u16 {
    if (node_index >= document.node_count) return null;
    var cursor = document.nodes[node_index].next_sibling;
    while (cursor != html.none and cursor < document.node_count) {
        if (document.nodes[cursor].kind == .element) return cursor;
        cursor = document.nodes[cursor].next_sibling;
    }
    return null;
}

fn elementIsEmpty(document: *const html.Document, node_index: u16) bool {
    var child = document.nodes[node_index].first_child;
    while (child != html.none and child < document.node_count) {
        if (document.nodes[child].kind == .element) return false;
        if (document.nodes[child].kind == .text and document.nodeValue(child).len > 0) return false;
        child = document.nodes[child].next_sibling;
    }
    return true;
}

fn languageMatches(document: *const html.Document, node_index: u16, requested: []const u8) bool {
    if (requested.len == 0) return false;
    var current: ?u16 = node_index;
    while (current) |candidate| {
        if (document.attribute(candidate, "lang")) |actual| {
            return equalsIgnoreCase(actual, requested) or
                (actual.len > requested.len and actual[requested.len] == '-' and equalsIgnoreCase(actual[0..requested.len], requested));
        }
        current = elementParent(document, candidate);
    }
    return false;
}

fn nthExpressionMatches(index: u16, expression_input: []const u8) bool {
    if (index == 0) return false;
    var compact_buffer: [64]u8 = undefined;
    var compact_len: usize = 0;
    for (trim(expression_input)) |byte| {
        if (isSpace(byte)) continue;
        if (compact_len >= compact_buffer.len) return false;
        compact_buffer[compact_len] = toLower(byte);
        compact_len += 1;
    }
    const expression = compact_buffer[0..compact_len];
    if (equalsIgnoreCase(expression, "odd")) return index % 2 == 1;
    if (equalsIgnoreCase(expression, "even")) return index % 2 == 0;
    const n_position = indexOfScalar(expression, 'n') orelse {
        const wanted = parseSigned(expression) orelse return false;
        return wanted > 0 and index == @as(u16, @intCast(wanted));
    };
    const a_source = expression[0..n_position];
    const a: i32 = if (a_source.len == 0 or std.mem.eql(u8, a_source, "+"))
        1
    else if (std.mem.eql(u8, a_source, "-"))
        -1
    else
        parseSigned(a_source) orelse return false;
    const b_source = expression[n_position + 1 ..];
    const b: i32 = if (b_source.len == 0) 0 else parseSigned(b_source) orelse return false;
    if (a == 0) return @as(i32, index) == b;
    const delta = @as(i32, index) - b;
    return @rem(delta, a) == 0 and @divTrunc(delta, a) >= 0;
}

fn supportsRequiredState(document: *const html.Document, node_index: u16) bool {
    const element = document.nodeName(node_index);
    return equalsIgnoreCase(element, "input") or equalsIgnoreCase(element, "select") or equalsIgnoreCase(element, "textarea");
}

fn supportsReadWriteState(document: *const html.Document, node_index: u16) bool {
    const element = document.nodeName(node_index);
    return equalsIgnoreCase(element, "input") or equalsIgnoreCase(element, "textarea") or document.attribute(node_index, "contenteditable") != null;
}

fn supportsEnabledState(document: *const html.Document, node_index: u16) bool {
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element) return false;
    const element = document.nodeName(node_index);
    return equalsIgnoreCase(element, "button") or
        equalsIgnoreCase(element, "fieldset") or
        equalsIgnoreCase(element, "input") or
        equalsIgnoreCase(element, "optgroup") or
        equalsIgnoreCase(element, "option") or
        equalsIgnoreCase(element, "select") or
        equalsIgnoreCase(element, "textarea");
}

fn selectorPseudoElement(selector: []const u8) PseudoElement {
    const value = trim(selector);
    if (endsWithIgnoreCase(value, "::before") or endsWithIgnoreCase(value, ":before")) return .before;
    if (endsWithIgnoreCase(value, "::after") or endsWithIgnoreCase(value, ":after")) return .after;
    return .none;
}

fn stripPseudoElement(selector: []const u8) []const u8 {
    const value = trim(selector);
    if (endsWithIgnoreCase(value, "::before")) return trim(value[0 .. value.len - "::before".len]);
    if (endsWithIgnoreCase(value, "::after")) return trim(value[0 .. value.len - "::after".len]);
    if (endsWithIgnoreCase(value, ":before")) return trim(value[0 .. value.len - ":before".len]);
    if (endsWithIgnoreCase(value, ":after")) return trim(value[0 .. value.len - ":after".len]);
    return value;
}

fn selectorSpecificity(selector: []const u8) u16 {
    const specificity = selectorSpecificityComponents(selector);
    return specificity.encode();
}

const Specificity = struct {
    ids: u16 = 0,
    classes: u16 = 0,
    types: u16 = 0,

    fn add(self: *Specificity, other: Specificity) void {
        self.ids +|= other.ids;
        self.classes +|= other.classes;
        self.types +|= other.types;
    }

    fn greaterThan(self: Specificity, other: Specificity) bool {
        if (self.ids != other.ids) return self.ids > other.ids;
        if (self.classes != other.classes) return self.classes > other.classes;
        return self.types > other.types;
    }

    fn encode(self: Specificity) u16 {
        const ids: u16 = @min(self.ids, @as(u16, 15));
        const classes: u16 = @min(self.classes, @as(u16, 31));
        const types: u16 = @min(self.types, @as(u16, 31));
        return ids * 1024 + classes * 32 + types;
    }
};

fn selectorSpecificityComponents(selector: []const u8) Specificity {
    var result = Specificity{};
    var cursor: usize = 0;
    var expect_type = true;
    while (cursor < selector.len) {
        const byte = selector[cursor];
        if (byte == '\\' and cursor + 1 < selector.len) {
            cursor += 2;
            continue;
        }
        if (isSpace(byte) or byte == '>' or byte == '+' or byte == '~' or byte == ',') {
            expect_type = true;
            cursor += 1;
            continue;
        }
        if (byte == '*') {
            expect_type = false;
            cursor += 1;
            continue;
        }
        if (byte == '#') {
            result.ids +|= 1;
            cursor += 1;
            scanCssIdentifier(selector, &cursor);
            expect_type = false;
            continue;
        }
        if (byte == '.') {
            result.classes +|= 1;
            cursor += 1;
            scanCssIdentifier(selector, &cursor);
            expect_type = false;
            continue;
        }
        if (byte == '[') {
            result.classes +|= 1;
            cursor = (findClosingDelimiter(selector, cursor, '[', ']') orelse selector.len - 1) + 1;
            expect_type = false;
            continue;
        }
        if (byte == ':') {
            const pseudo_element = cursor + 1 < selector.len and selector[cursor + 1] == ':';
            cursor += if (pseudo_element) 2 else 1;
            const name_start = cursor;
            while (cursor < selector.len and isIdentByte(selector[cursor])) : (cursor += 1) {}
            const name = selector[name_start..cursor];
            if (pseudo_element or ((!pseudo_element) and (equalsIgnoreCase(name, "before") or equalsIgnoreCase(name, "after")))) {
                result.types +|= 1;
                if (cursor < selector.len and selector[cursor] == '(') cursor = (findClosingDelimiter(selector, cursor, '(', ')') orelse selector.len - 1) + 1;
                expect_type = false;
                continue;
            }
            if (cursor < selector.len and selector[cursor] == '(') {
                const close = findClosingDelimiter(selector, cursor, '(', ')') orelse selector.len;
                const argument = if (close <= selector.len) selector[cursor + 1 .. close] else "";
                if (equalsIgnoreCase(name, "is") or equalsIgnoreCase(name, "not") or equalsIgnoreCase(name, "has")) {
                    result.add(selectorListMaxSpecificity(argument));
                } else if (!equalsIgnoreCase(name, "where")) {
                    result.classes +|= 1;
                }
                cursor = @min(selector.len, close + 1);
            } else {
                result.classes +|= 1;
            }
            expect_type = false;
            continue;
        }
        if (expect_type and isIdentStart(byte)) {
            result.types +|= 1;
            scanCssIdentifier(selector, &cursor);
            expect_type = false;
            continue;
        }
        cursor += 1;
    }
    return result;
}

fn selectorListMaxSpecificity(selector_list: []const u8) Specificity {
    var maximum = Specificity{};
    var start: usize = 0;
    var cursor: usize = 0;
    var bracket_depth: usize = 0;
    var paren_depth: usize = 0;
    var quote: u8 = 0;
    while (cursor <= selector_list.len) : (cursor += 1) {
        const at_end = cursor == selector_list.len;
        if (!at_end) {
            const byte = selector_list[cursor];
            if (quote != 0) {
                if (byte == '\\' and cursor + 1 < selector_list.len) cursor += 1 else if (byte == quote) quote = 0;
                continue;
            }
            if (byte == '"' or byte == '\'') {
                quote = byte;
                continue;
            }
            if (byte == '[') bracket_depth += 1 else if (byte == ']' and bracket_depth > 0) bracket_depth -= 1;
            if (byte == '(') paren_depth += 1 else if (byte == ')' and paren_depth > 0) paren_depth -= 1;
            if (byte != ',' or bracket_depth != 0 or paren_depth != 0) continue;
        }
        const candidate = selectorSpecificityComponents(trim(selector_list[start..cursor]));
        if (candidate.greaterThan(maximum)) maximum = candidate;
        start = cursor + 1;
    }
    return maximum;
}

fn parseDisplay(value: []const u8) ?Display {
    const input = trim(value);
    if (equalsIgnoreCase(input, "none")) return .none;
    if (equalsIgnoreCase(input, "contents")) return .contents;
    if (equalsIgnoreCase(input, "block") or equalsIgnoreCase(input, "flow-root") or equalsIgnoreCase(input, "block flow") or equalsIgnoreCase(input, "block flow-root") or equalsIgnoreCase(input, "list-item")) return .block;
    if (equalsIgnoreCase(input, "inline") or equalsIgnoreCase(input, "inline flow")) return .inline_flow;
    if (equalsIgnoreCase(input, "inline-block") or equalsIgnoreCase(input, "inline-box") or equalsIgnoreCase(input, "inline flow-root")) return .inline_block;
    if (equalsIgnoreCase(input, "flex") or equalsIgnoreCase(input, "block flex")) return .flex;
    if (equalsIgnoreCase(input, "inline-flex") or equalsIgnoreCase(input, "inline flex")) return .inline_flex;
    if (equalsIgnoreCase(input, "grid") or equalsIgnoreCase(input, "block grid")) return .grid;
    if (equalsIgnoreCase(input, "inline-grid") or equalsIgnoreCase(input, "inline grid")) return .inline_grid;
    if (startsWithIgnoreCase(input, "table") or startsWithIgnoreCase(input, "block table")) return .block;
    if (startsWithIgnoreCase(input, "inline table")) return .inline_block;
    return null;
}

fn parsePosition(value: []const u8) ?Position {
    const input = trim(value);
    if (equalsIgnoreCase(input, "static")) return .static;
    if (equalsIgnoreCase(input, "relative")) return .relative;
    if (equalsIgnoreCase(input, "absolute")) return .absolute;
    if (equalsIgnoreCase(input, "fixed")) return .fixed;
    return null;
}

fn parseVisibility(value: []const u8) ?Visibility {
    const input = trim(value);
    if (equalsIgnoreCase(input, "visible")) return .visible;
    if (equalsIgnoreCase(input, "hidden")) return .hidden;
    if (equalsIgnoreCase(input, "collapse")) return .collapse;
    return null;
}

fn parseOverflow(value: []const u8) ?Overflow {
    const input = trim(value);
    if (equalsIgnoreCase(input, "visible")) return .visible;
    if (equalsIgnoreCase(input, "hidden")) return .hidden;
    if (equalsIgnoreCase(input, "clip")) return .clip;
    if (equalsIgnoreCase(input, "scroll")) return .scroll;
    if (equalsIgnoreCase(input, "auto")) return .auto;
    return null;
}

fn applyOverflowShorthand(style: *ComputedStyle, value: []const u8) void {
    var cursor: usize = 0;
    const first = nextCssValueToken(value, &cursor) orelse return;
    const x = parseOverflow(first) orelse return;
    const second = nextCssValueToken(value, &cursor);
    const y = if (second) |token| parseOverflow(token) orelse return else x;
    if (nextCssValueToken(value, &cursor) != null) return;
    style.overflow_x = x;
    style.overflow_y = y;
}

fn applyContent(style: *ComputedStyle, value: []const u8) void {
    const input = trim(value);
    if (equalsIgnoreCase(input, "normal") or equalsIgnoreCase(input, "none")) {
        style.content = "";
        style.content_is_expression = false;
        return;
    }
    if (isSingleCssString(input)) {
        style.content = input[1 .. input.len - 1];
        style.content_is_expression = false;
    } else {
        style.content = input;
        style.content_is_expression = true;
    }
}

fn isSingleCssString(value: []const u8) bool {
    if (value.len < 2 or (value[0] != '"' and value[0] != '\'')) return false;
    const quote = value[0];
    var cursor: usize = 1;
    while (cursor < value.len) : (cursor += 1) {
        if (value[cursor] == '\\' and cursor + 1 < value.len) {
            cursor += 1;
            continue;
        }
        if (value[cursor] == quote) return cursor == value.len - 1;
    }
    return false;
}

fn parseBoxSizing(value: []const u8) ?BoxSizing {
    const input = trim(value);
    if (equalsIgnoreCase(input, "content-box")) return .content_box;
    if (equalsIgnoreCase(input, "border-box")) return .border_box;
    return null;
}

fn parseJustifyContent(value: []const u8) ?JustifyContent {
    const input = trim(value);
    if (equalsIgnoreCase(input, "normal") or equalsIgnoreCase(input, "start") or equalsIgnoreCase(input, "flex-start") or equalsIgnoreCase(input, "left")) return .start;
    if (equalsIgnoreCase(input, "end") or equalsIgnoreCase(input, "flex-end") or equalsIgnoreCase(input, "right")) return .end;
    if (equalsIgnoreCase(input, "center")) return .center;
    if (equalsIgnoreCase(input, "space-between")) return .space_between;
    if (equalsIgnoreCase(input, "space-around")) return .space_around;
    if (equalsIgnoreCase(input, "space-evenly")) return .space_evenly;
    return null;
}

fn parseAlignItems(value: []const u8) ?AlignItems {
    const input = trim(value);
    if (equalsIgnoreCase(input, "normal") or equalsIgnoreCase(input, "stretch")) return .stretch;
    if (equalsIgnoreCase(input, "start") or equalsIgnoreCase(input, "flex-start") or equalsIgnoreCase(input, "baseline")) return .start;
    if (equalsIgnoreCase(input, "end") or equalsIgnoreCase(input, "flex-end")) return .end;
    if (equalsIgnoreCase(input, "center")) return .center;
    return null;
}

pub fn parseLength(value: []const u8) ?Length {
    const input = trim(value);
    if (equalsIgnoreCase(input, "auto")) return .{};
    if (input.len == 0) return null;
    if (startsWithIgnoreCase(input, "calc(") and input.len > 6 and input[input.len - 1] == ')') {
        return parseCalcLength(input[5 .. input.len - 1]);
    }
    if (endsWithIgnoreCase(input, "px")) return .{ .kind = .px, .value = parseSigned(input[0 .. input.len - 2]) orelse return null };
    if (endsWithIgnoreCase(input, "%")) return .{ .kind = .percent, .value = parseSigned(input[0 .. input.len - 1]) orelse return null };
    if (endsWithIgnoreCase(input, "rem")) return .{ .kind = .rem, .value = (parseFixedHundred(input[0 .. input.len - 3]) orelse return null) };
    if (endsWithIgnoreCase(input, "em")) return .{ .kind = .em, .value = (parseFixedHundred(input[0 .. input.len - 2]) orelse return null) };
    if (endsWithIgnoreCase(input, "vw")) return .{ .kind = .vw, .value = (parseFixedHundred(input[0 .. input.len - 2]) orelse return null) };
    if (endsWithIgnoreCase(input, "vh")) return .{ .kind = .vh, .value = (parseFixedHundred(input[0 .. input.len - 2]) orelse return null) };
    return .{ .kind = .px, .value = parseSigned(input) orelse return null };
}

fn parseCalcLength(expression: []const u8) ?Length {
    var result = Length{ .kind = .calc };
    var cursor: usize = 0;
    var sign: i32 = 1;
    var term_count: usize = 0;
    var expect_term = true;
    while (cursor < expression.len) {
        while (cursor < expression.len and isSpace(expression[cursor])) : (cursor += 1) {}
        if (cursor >= expression.len) break;
        if (expression[cursor] == '+') {
            if (expect_term and term_count > 0) return null;
            sign = 1;
            expect_term = true;
            cursor += 1;
            continue;
        }
        if (expression[cursor] == '-') {
            if (expect_term and term_count > 0) return null;
            sign = -1;
            expect_term = true;
            cursor += 1;
            continue;
        }
        if (!expect_term) return null;
        const start = cursor;
        while (cursor < expression.len and !isSpace(expression[cursor]) and expression[cursor] != '+' and expression[cursor] != '-') : (cursor += 1) {}
        const term = trim(expression[start..cursor]);
        if (term.len == 0) return null;
        if (!appendCalcTerm(&result, term, sign)) return null;
        term_count += 1;
        sign = 1;
        expect_term = false;
    }
    return if (term_count > 0 and !expect_term) result else null;
}

fn appendCalcTerm(result: *Length, term: []const u8, sign: i32) bool {
    var target: *i32 = &result.calc_px;
    var number = term;
    if (endsWithIgnoreCase(term, "rem")) {
        target = &result.calc_rem;
        number = term[0 .. term.len - 3];
    } else if (endsWithIgnoreCase(term, "px")) {
        target = &result.calc_px;
        number = term[0 .. term.len - 2];
    } else if (endsWithIgnoreCase(term, "em")) {
        target = &result.calc_em;
        number = term[0 .. term.len - 2];
    } else if (endsWithIgnoreCase(term, "vw")) {
        target = &result.calc_vw;
        number = term[0 .. term.len - 2];
    } else if (endsWithIgnoreCase(term, "vh")) {
        target = &result.calc_vh;
        number = term[0 .. term.len - 2];
    } else if (endsWithIgnoreCase(term, "%")) {
        target = &result.calc_percent;
        number = term[0 .. term.len - 1];
    } else if (!equalsIgnoreCase(term, "0")) {
        return false;
    }
    const fixed = parseFixedHundred(number) orelse return false;
    target.* = clampI64ToI32(@as(i64, target.*) + @as(i64, fixed) * sign);
    return true;
}

const ParsedColor = struct {
    rgb: u32,
    alpha: u8 = 255,
};

pub fn parseColor(value: []const u8) ?u32 {
    return (parseColorWithAlpha(value) orelse return null).rgb;
}

fn parseColorWithAlpha(value: []const u8) ?ParsedColor {
    const input = trim(value);
    if ((input.len == 4 or input.len == 5) and input[0] == '#') {
        const r = hexDigit(input[1]) orelse return null;
        const g = hexDigit(input[2]) orelse return null;
        const b = hexDigit(input[3]) orelse return null;
        const alpha: u8 = if (input.len == 5) @intCast((hexDigit(input[4]) orelse return null) * 17) else 255;
        return .{ .rgb = (@as(u32, r) * 17 << 16) | (@as(u32, g) * 17 << 8) | (@as(u32, b) * 17), .alpha = alpha };
    }
    if ((input.len == 7 or input.len == 9) and input[0] == '#') {
        const rgb = (@as(u32, hexByte(input[1], input[2]) orelse return null) << 16) |
            (@as(u32, hexByte(input[3], input[4]) orelse return null) << 8) |
            @as(u32, hexByte(input[5], input[6]) orelse return null);
        const alpha = if (input.len == 9) hexByte(input[7], input[8]) orelse return null else 255;
        return .{ .rgb = rgb, .alpha = alpha };
    }
    if ((startsWithIgnoreCase(input, "rgb(") or startsWithIgnoreCase(input, "rgba(")) and input[input.len - 1] == ')') {
        const open = indexOfScalar(input, '(') orelse return null;
        const inner = input[open + 1 .. input.len - 1];
        var components: [4][]const u8 = .{ "", "", "", "" };
        var count: usize = 0;
        var cursor: usize = 0;
        while (cursor <= inner.len and count < components.len) {
            const start = cursor;
            while (cursor < inner.len and inner[cursor] != ',') cursor += 1;
            components[count] = trim(inner[start..cursor]);
            count += 1;
            if (cursor >= inner.len) break;
            cursor += 1;
        }
        if (count < 3) return null;
        const red = parseRgbChannel(components[0]) orelse return null;
        const green = parseRgbChannel(components[1]) orelse return null;
        const blue = parseRgbChannel(components[2]) orelse return null;
        const alpha = if (count >= 4) parseAlphaChannel(components[3]) orelse return null else 255;
        return .{ .rgb = (@as(u32, red) << 16) | (@as(u32, green) << 8) | blue, .alpha = alpha };
    }
    const named = [_]struct { name: []const u8, color: u32 }{
        .{ .name = "black", .color = 0x000000 },  .{ .name = "white", .color = 0xFFFFFF },
        .{ .name = "red", .color = 0xFF0000 },    .{ .name = "green", .color = 0x008000 },
        .{ .name = "blue", .color = 0x0000FF },   .{ .name = "navy", .color = 0x000080 },
        .{ .name = "gray", .color = 0x808080 },   .{ .name = "grey", .color = 0x808080 },
        .{ .name = "silver", .color = 0xC0C0C0 }, .{ .name = "yellow", .color = 0xFFFF00 },
        .{ .name = "maroon", .color = 0x800000 }, .{ .name = "purple", .color = 0x800080 },
        .{ .name = "teal", .color = 0x008080 },   .{ .name = "aqua", .color = 0x00FFFF },
    };
    for (named) |item| if (equalsIgnoreCase(input, item.name)) return .{ .rgb = item.color };
    if (equalsIgnoreCase(input, "transparent")) return .{ .rgb = 0, .alpha = 0 };
    return null;
}

fn hexByte(high: u8, low: u8) ?u8 {
    return @intCast((hexDigit(high) orelse return null) * 16 + (hexDigit(low) orelse return null));
}

fn parseRgbChannel(value: []const u8) ?u8 {
    const input = trim(value);
    if (endsWithIgnoreCase(input, "%")) {
        const fixed = parseFixedHundred(input[0 .. input.len - 1]) orelse return null;
        const scaled = @divTrunc(@as(i64, fixed) * 255, 10_000);
        return @intCast(@max(@as(i64, 0), @min(@as(i64, 255), scaled)));
    }
    return @intCast(clamp(parseSigned(input) orelse return null, 0, 255));
}

fn parseAlphaChannel(value: []const u8) ?u8 {
    const input = trim(value);
    if (endsWithIgnoreCase(input, "%")) {
        const fixed = parseFixedHundred(input[0 .. input.len - 1]) orelse return null;
        const scaled = @divTrunc(@as(i64, fixed) * 255, 10_000);
        return @intCast(@max(@as(i64, 0), @min(@as(i64, 255), scaled)));
    }
    const fixed = parseFixedHundred(input) orelse return null;
    const scaled = @divTrunc(@as(i64, fixed) * 255, 100);
    return @intCast(@max(@as(i64, 0), @min(@as(i64, 255), scaled)));
}

fn parseTextAlign(value: []const u8) ?TextAlign {
    const input = trim(value);
    if (equalsIgnoreCase(input, "left") or equalsIgnoreCase(input, "start")) return .left;
    if (equalsIgnoreCase(input, "center")) return .center;
    if (equalsIgnoreCase(input, "right") or equalsIgnoreCase(input, "end")) return .right;
    return null;
}

fn parseWhiteSpace(value: []const u8) ?WhiteSpace {
    const input = trim(value);
    if (equalsIgnoreCase(input, "normal") or equalsIgnoreCase(input, "pre-wrap")) return .normal;
    if (equalsIgnoreCase(input, "pre")) return .pre;
    if (equalsIgnoreCase(input, "nowrap")) return .nowrap;
    return null;
}

fn parseEmptyClip(value: []const u8) bool {
    const input = trim(value);
    if (!startsWithIgnoreCase(input, "rect(") or input.len < 7 or input[input.len - 1] != ')') return false;
    const inner = input[5 .. input.len - 1];
    if (containsIgnoreCase(inner, "auto")) return false;
    var component_count: usize = 0;
    var cursor: usize = 0;
    while (cursor < inner.len) {
        while (cursor < inner.len and (isSpace(inner[cursor]) or inner[cursor] == ',')) : (cursor += 1) {}
        if (cursor >= inner.len) break;
        const start = cursor;
        while (cursor < inner.len and !isSpace(inner[cursor]) and inner[cursor] != ',') : (cursor += 1) {}
        const component = inner[start..cursor];
        const length = parseLength(component) orelse return false;
        if (length.kind == .auto or length.value != 0) return false;
        component_count += 1;
    }
    return component_count == 4;
}

fn parseFontWeight(value: []const u8, fallback: u16) u16 {
    const input = trim(value);
    if (equalsIgnoreCase(input, "normal")) return 400;
    if (equalsIgnoreCase(input, "bold")) return 700;
    if (equalsIgnoreCase(input, "bolder")) {
        if (fallback < 350) return 400;
        if (fallback < 550) return 700;
        return 900;
    }
    if (equalsIgnoreCase(input, "lighter")) {
        if (fallback > 750) return 700;
        if (fallback > 450) return 400;
        return 100;
    }
    return clampUnsigned(parseUnsigned(input) orelse fallback, 100, 900);
}

fn parseFontSize(value: []const u8, inherited_size: i32) ?i32 {
    const input = trim(value);
    if (equalsIgnoreCase(input, "xx-small")) return 9;
    if (equalsIgnoreCase(input, "x-small")) return 10;
    if (equalsIgnoreCase(input, "small")) return 13;
    if (equalsIgnoreCase(input, "medium")) return 16;
    if (equalsIgnoreCase(input, "large")) return 18;
    if (equalsIgnoreCase(input, "x-large")) return 24;
    if (equalsIgnoreCase(input, "xx-large") or equalsIgnoreCase(input, "xxx-large")) return 32;
    if (equalsIgnoreCase(input, "smaller")) return @divTrunc(inherited_size * 5 + 3, 6);
    if (equalsIgnoreCase(input, "larger")) return @divTrunc(inherited_size * 6 + 2, 5);
    const length = parseLength(input) orelse return null;
    return length.pixels(inherited_size, inherited_size, inherited_size);
}

fn parseLineHeight(value: []const u8) ?LineHeightValue {
    const input = trim(value);
    if (equalsIgnoreCase(input, "normal")) return .{};
    const has_length_unit = endsWithIgnoreCase(input, "px") or endsWithIgnoreCase(input, "%") or
        endsWithIgnoreCase(input, "em") or endsWithIgnoreCase(input, "rem") or
        endsWithIgnoreCase(input, "vw") or endsWithIgnoreCase(input, "vh") or startsWithIgnoreCase(input, "calc(");
    if (has_length_unit) return .{ .kind = .length, .length = parseLength(input) orelse return null };
    const factor = parseFixedHundred(input) orelse return null;
    if (factor < 0) return null;
    return .{ .kind = .number, .number_hundred = factor };
}

fn applyFlexShorthand(style: *ComputedStyle, value: []const u8) void {
    const input = trim(value);
    if (equalsIgnoreCase(input, "none")) {
        style.flex_grow = 0;
        style.flex_shrink = 0;
        style.flex_basis = .{};
        return;
    }
    if (equalsIgnoreCase(input, "auto")) {
        style.flex_grow = 1;
        style.flex_shrink = 1;
        style.flex_basis = .{};
        return;
    }

    var tokens: [3][]const u8 = .{ "", "", "" };
    var token_count: usize = 0;
    var cursor: usize = 0;
    while (cursor < input.len and token_count < tokens.len) {
        while (cursor < input.len and isSpace(input[cursor])) : (cursor += 1) {}
        if (cursor >= input.len) break;
        const start = cursor;
        while (cursor < input.len and !isSpace(input[cursor])) : (cursor += 1) {}
        tokens[token_count] = input[start..cursor];
        token_count += 1;
    }
    if (token_count == 0) return;
    const grow = parseUnsigned(tokens[0]) orelse return;
    style.flex_grow = grow;
    style.flex_shrink = if (token_count >= 2) parseUnsigned(tokens[1]) orelse 1 else 1;
    style.flex_basis = if (token_count >= 3)
        parseLength(tokens[2]) orelse .{}
    else
        .{ .kind = .percent, .value = 0 };
}

fn firstFamily(value: []const u8) []const u8 {
    const input = trim(value);
    const comma = indexOfScalar(input, ',') orelse input.len;
    return unquote(trim(input[0..comma]));
}

fn countGridColumns(value: []const u8) u8 {
    const input = trim(value);
    if (startsWithIgnoreCase(input, "repeat(")) {
        const comma = indexOfScalar(input, ',') orelse return 1;
        return @intCast(clampUnsigned(parseUnsigned(trim(input["repeat(".len..comma])) orelse 1, 1, 8));
    }
    var count: u8 = 0;
    var in_token = false;
    for (input) |byte| {
        if (isSpace(byte)) {
            in_token = false;
        } else if (!in_token) {
            count +|= 1;
            in_token = true;
        }
    }
    return clampUnsigned(count, 1, 8);
}

fn elementSiblingIndex(document: *const html.Document, node_index: u16) u16 {
    const parent = document.nodes[node_index].parent;
    if (parent == html.none or parent >= document.node_count) return 0;
    var index: u16 = 0;
    var child = document.nodes[parent].first_child;
    while (child != html.none) {
        if (document.nodes[child].kind == .element) index +|= 1;
        if (child == node_index) return index;
        child = document.nodes[child].next_sibling;
    }
    return 0;
}

fn elementSiblingIndexFromEnd(document: *const html.Document, node_index: u16) u16 {
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element) return 0;
    var index: u16 = 1;
    var child = document.nodes[node_index].next_sibling;
    while (child != html.none and child < document.node_count) {
        if (document.nodes[child].kind == .element) index +|= 1;
        child = document.nodes[child].next_sibling;
    }
    return index;
}

fn elementTypeSiblingIndex(document: *const html.Document, node_index: u16) u16 {
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element) return 0;
    const parent = document.nodes[node_index].parent;
    if (parent == html.none or parent >= document.node_count) return 0;
    const name = document.nodeName(node_index);
    var index: u16 = 0;
    var child = document.nodes[parent].first_child;
    while (child != html.none and child < document.node_count) {
        if (document.nodes[child].kind == .element and equalsIgnoreCase(document.nodeName(child), name)) index +|= 1;
        if (child == node_index) return index;
        child = document.nodes[child].next_sibling;
    }
    return 0;
}

fn elementTypeSiblingIndexFromEnd(document: *const html.Document, node_index: u16) u16 {
    if (node_index >= document.node_count or document.nodes[node_index].kind != .element) return 0;
    const name = document.nodeName(node_index);
    var index: u16 = 1;
    var child = document.nodes[node_index].next_sibling;
    while (child != html.none and child < document.node_count) {
        if (document.nodes[child].kind == .element and equalsIgnoreCase(document.nodeName(child), name)) index +|= 1;
        child = document.nodes[child].next_sibling;
    }
    return index;
}

fn isLastElementChild(document: *const html.Document, node_index: u16) bool {
    const parent = document.nodes[node_index].parent;
    if (parent == html.none or parent >= document.node_count) return false;
    var child = document.nodes[node_index].next_sibling;
    while (child != html.none) {
        if (document.nodes[child].kind == .element) return false;
        child = document.nodes[child].next_sibling;
    }
    return true;
}

fn toLower(byte: u8) u8 {
    return if (byte >= 'A' and byte <= 'Z') byte + ('a' - 'A') else byte;
}

fn classContains(value: []const u8, wanted: []const u8) bool {
    var cursor: usize = 0;
    while (cursor < value.len) {
        while (cursor < value.len and isSpace(value[cursor])) : (cursor += 1) {}
        const start = cursor;
        while (cursor < value.len and !isSpace(value[cursor])) : (cursor += 1) {}
        if (equals(value[start..cursor], wanted)) return true;
    }
    return false;
}

fn classContainsEscaped(value: []const u8, wanted: []const u8) bool {
    var cursor: usize = 0;
    while (cursor < value.len) {
        while (cursor < value.len and isSpace(value[cursor])) : (cursor += 1) {}
        const start = cursor;
        while (cursor < value.len and !isSpace(value[cursor])) : (cursor += 1) {}
        if (cssEscapedEquals(value[start..cursor], wanted)) return true;
    }
    return false;
}

fn scanCssIdentifier(value: []const u8, cursor: *usize) void {
    while (cursor.* < value.len) {
        if (isIdentByte(value[cursor.*])) {
            cursor.* += 1;
            continue;
        }
        if (value[cursor.*] != '\\' or cursor.* + 1 >= value.len) break;
        cursor.* += 2;
    }
}

fn cssEscapedEquals(actual: []const u8, escaped: []const u8) bool {
    var actual_cursor: usize = 0;
    var escaped_cursor: usize = 0;
    while (escaped_cursor < escaped.len) {
        var expected = escaped[escaped_cursor];
        escaped_cursor += 1;
        if (expected == '\\') {
            if (escaped_cursor >= escaped.len) return false;
            expected = escaped[escaped_cursor];
            escaped_cursor += 1;
        }
        if (actual_cursor >= actual.len or actual[actual_cursor] != expected) return false;
        actual_cursor += 1;
    }
    return actual_cursor == actual.len;
}

fn skipWhitespaceAndComments(source: []const u8, cursor: *usize) void {
    while (cursor.* < source.len) {
        if (isSpace(source[cursor.*])) {
            cursor.* += 1;
            continue;
        }
        if (cursor.* + 1 < source.len and source[cursor.*] == '/' and source[cursor.* + 1] == '*') {
            cursor.* += 2;
            while (cursor.* + 1 < source.len and !(source[cursor.*] == '*' and source[cursor.* + 1] == '/')) cursor.* += 1;
            if (cursor.* + 1 < source.len) cursor.* += 2;
            continue;
        }
        break;
    }
}

fn findAtRuleBlockStart(source: []const u8, start: usize) ?usize {
    var cursor = start;
    var quote: u8 = 0;
    var paren_depth: usize = 0;
    while (cursor < source.len) : (cursor += 1) {
        const byte = source[cursor];
        if (quote != 0) {
            if (byte == quote) quote = 0;
            continue;
        }
        if (byte == '"' or byte == '\'') {
            quote = byte;
        } else if (byte == '(') {
            paren_depth += 1;
        } else if (byte == ')' and paren_depth > 0) {
            paren_depth -= 1;
        } else if (byte == '{' and paren_depth == 0) {
            return cursor;
        } else if (byte == ';' and paren_depth == 0) {
            return null;
        }
    }
    return null;
}

fn findMatchingBrace(source: []const u8, opening: usize) ?usize {
    if (opening >= source.len or source[opening] != '{') return null;
    var cursor = opening + 1;
    var depth: usize = 1;
    var quote: u8 = 0;
    while (cursor < source.len) : (cursor += 1) {
        const byte = source[cursor];
        if (quote != 0) {
            if (byte == quote) quote = 0;
            continue;
        }
        if (byte == '"' or byte == '\'') {
            quote = byte;
        } else if (cursor + 1 < source.len and byte == '/' and source[cursor + 1] == '*') {
            cursor += 2;
            while (cursor + 1 < source.len and !(source[cursor] == '*' and source[cursor + 1] == '/')) : (cursor += 1) {}
            if (cursor + 1 < source.len) cursor += 1;
        } else if (byte == '{') {
            depth += 1;
        } else if (byte == '}') {
            depth -= 1;
            if (depth == 0) return cursor;
        }
    }
    return null;
}

fn parseMediaConstraint(input: []const u8) ?MediaConstraint {
    const query = trim(input);
    if (query.len == 0 or indexOfScalar(query, ',') != null) return null;

    const has_screen = containsIgnoreCase(query, "screen");
    const has_all = containsIgnoreCase(query, "all");
    if (!has_screen and !has_all and query[0] != '(') return null;
    if (containsIgnoreCase(query, "print") and !has_screen) return .{ .never = true };

    var result = MediaConstraint{};
    var conditions: usize = 0;
    var constant_match = true;

    if (mediaDimension(query, "min-width")) |value| {
        result.min_width = value;
        conditions += 1;
    }
    if (mediaDimension(query, "max-width")) |value| {
        result.max_width = value;
        conditions += 1;
    }
    if (mediaDimension(query, "width")) |value| {
        result.min_width = value;
        result.max_width = value;
        conditions += 1;
    }
    if (mediaDimension(query, "min-height")) |value| {
        result.min_height = value;
        conditions += 1;
    }
    if (mediaDimension(query, "max-height")) |value| {
        result.max_height = value;
        conditions += 1;
    }
    if (mediaDimension(query, "height")) |value| {
        result.min_height = value;
        result.max_height = value;
        conditions += 1;
    }
    if (mediaFeatureValue(query, "orientation")) |value| {
        if (equalsIgnoreCase(value, "portrait")) {
            result.orientation = .portrait;
        } else if (equalsIgnoreCase(value, "landscape")) {
            result.orientation = .landscape;
        } else {
            return .{ .never = true };
        }
        conditions += 1;
    }

    const constant_features = [_]struct { name: []const u8, supported_value: []const u8 }{
        .{ .name = "forced-colors", .supported_value = "none" },
        .{ .name = "hover", .supported_value = "hover" },
        .{ .name = "any-hover", .supported_value = "hover" },
        .{ .name = "pointer", .supported_value = "fine" },
        .{ .name = "any-pointer", .supported_value = "fine" },
        .{ .name = "prefers-color-scheme", .supported_value = "light" },
        .{ .name = "prefers-reduced-motion", .supported_value = "no-preference" },
        .{ .name = "scripting", .supported_value = "enabled" },
        .{ .name = "display-mode", .supported_value = "browser" },
        .{ .name = "update", .supported_value = "fast" },
    };
    for (constant_features) |feature| {
        if (mediaFeatureValue(query, feature.name)) |value| {
            constant_match = constant_match and equalsIgnoreCase(value, feature.supported_value);
            conditions += 1;
        }
    }
    if (!mediaClausesKnown(query)) return .{ .never = true };

    result.never = !constant_match or result.min_width > result.max_width or result.min_height > result.max_height;
    const negated = startsWithIgnoreCase(query, "not ");
    if (!negated) return result;
    if (result.never) return .{};

    if (conditions == 1) {
        if (result.min_width > 0 and result.max_width == std.math.maxInt(i32)) return .{ .max_width = @max(0, result.min_width - 1) };
        if (result.max_width < std.math.maxInt(i32) and result.min_width == 0) return .{ .min_width = result.max_width +| 1 };
        if (result.min_height > 0 and result.max_height == std.math.maxInt(i32)) return .{ .max_height = @max(0, result.min_height - 1) };
        if (result.max_height < std.math.maxInt(i32) and result.min_height == 0) return .{ .min_height = result.max_height +| 1 };
        if (result.orientation == .portrait) return .{ .orientation = .landscape };
        if (result.orientation == .landscape) return .{ .orientation = .portrait };
        if (conditions > 0) return .{ .never = true };
    }
    return .{ .never = true };
}

fn mediaDimension(query: []const u8, property: []const u8) ?i32 {
    const source = mediaFeatureValue(query, property) orelse return null;
    var cursor: usize = 0;
    while (cursor < source.len and source[cursor] >= '0' and source[cursor] <= '9') : (cursor += 1) {}
    if (cursor == 0) return null;
    const value = parseSigned(source[0..cursor]) orelse return null;
    while (cursor < source.len and isSpace(source[cursor])) : (cursor += 1) {}
    if (cursor + 2 != source.len or !equalsIgnoreCase(source[cursor .. cursor + 2], "px")) return null;
    return clamp(value, 0, std.math.maxInt(i32) - 1);
}

fn mediaFeatureValue(query: []const u8, wanted_name: []const u8) ?[]const u8 {
    var cursor: usize = 0;
    while (cursor < query.len) : (cursor += 1) {
        if (query[cursor] != '(') continue;
        const close = findClosingDelimiter(query, cursor, '(', ')') orelse return null;
        const expression = trim(query[cursor + 1 .. close]);
        const colon = indexOfScalar(expression, ':') orelse {
            cursor = close;
            continue;
        };
        const name = trim(expression[0..colon]);
        if (equalsIgnoreCase(name, wanted_name)) return trim(expression[colon + 1 ..]);
        cursor = close;
    }
    return null;
}

fn mediaClausesKnown(query: []const u8) bool {
    const known = [_][]const u8{
        "min-width",     "max-width",    "width",     "min-height", "max-height",  "height",               "orientation",
        "forced-colors", "hover",        "any-hover", "pointer",    "any-pointer", "prefers-color-scheme", "prefers-reduced-motion",
        "scripting",     "display-mode", "update",
    };
    var cursor: usize = 0;
    while (cursor < query.len) : (cursor += 1) {
        if (query[cursor] != '(') continue;
        const close = findClosingDelimiter(query, cursor, '(', ')') orelse return false;
        const expression = trim(query[cursor + 1 .. close]);
        const colon = indexOfScalar(expression, ':') orelse return false;
        const name = trim(expression[0..colon]);
        var matched = false;
        for (known) |candidate| {
            if (equalsIgnoreCase(name, candidate)) {
                matched = true;
                break;
            }
        }
        if (!matched) return false;
        cursor = close;
    }
    return true;
}

fn skipAtRule(source: []const u8, cursor: *usize) void {
    var depth: usize = 0;
    while (cursor.* < source.len) : (cursor.* += 1) {
        const byte = source[cursor.*];
        if (byte == '{') depth += 1 else if (byte == '}') {
            if (depth == 0) {
                cursor.* += 1;
                return;
            }
            depth -= 1;
            if (depth == 0) {
                cursor.* += 1;
                return;
            }
        } else if (byte == ';' and depth == 0) {
            cursor.* += 1;
            return;
        }
    }
}

fn trimRange(source: []const u8, start_input: usize, end_input: usize) Range {
    var start = start_input;
    var end = end_input;
    while (start < end and isSpace(source[start])) : (start += 1) {}
    while (end > start and isSpace(source[end - 1])) : (end -= 1) {}
    return .{ .start = start, .end = end };
}

fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isSpace(value[start])) : (start += 1) {}
    while (end > start and isSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn unquote(value: []const u8) []const u8 {
    if (value.len >= 2 and ((value[0] == '"' and value[value.len - 1] == '"') or (value[0] == '\'' and value[value.len - 1] == '\''))) return value[1 .. value.len - 1];
    return value;
}

fn parseUnsigned(value: []const u8) ?u16 {
    const signed = parseSigned(trim(value)) orelse return null;
    if (signed < 0) return null;
    return @intCast(@min(signed, std.math.maxInt(u16)));
}

fn parseSigned(value: []const u8) ?i32 {
    const input = trim(value);
    if (input.len == 0) return null;
    var negative = false;
    var cursor: usize = 0;
    if (input[0] == '-') {
        negative = true;
        cursor = 1;
    } else if (input[0] == '+') {
        cursor = 1;
    }
    if (cursor >= input.len) return null;
    var result: i32 = 0;
    while (cursor < input.len) : (cursor += 1) {
        const byte = input[cursor];
        if (byte < '0' or byte > '9') return null;
        result = result * 10 + (byte - '0');
    }
    return if (negative) -result else result;
}

fn parseFixedHundred(value: []const u8) ?i32 {
    const input = trim(value);
    const dot = indexOfScalar(input, '.');
    if (dot == null) return (parseSigned(input) orelse return null) * 100;
    const position = dot.?;
    const whole = parseSigned(input[0..position]) orelse 0;
    const fraction_slice = input[position + 1 ..];
    var fraction: i32 = 0;
    if (fraction_slice.len > 0 and fraction_slice[0] >= '0' and fraction_slice[0] <= '9') fraction += (fraction_slice[0] - '0') * 10;
    if (fraction_slice.len > 1 and fraction_slice[1] >= '0' and fraction_slice[1] <= '9') fraction += fraction_slice[1] - '0';
    return whole * 100 + fraction;
}

fn hexDigit(value: u8) ?u32 {
    if (value >= '0' and value <= '9') return value - '0';
    if (value >= 'a' and value <= 'f') return value - 'a' + 10;
    if (value >= 'A' and value <= 'F') return value - 'A' + 10;
    return null;
}

fn indexOfScalar(value: []const u8, needle: u8) ?usize {
    return indexOfScalarPos(value, 0, needle);
}

fn indexOfScalarPos(value: []const u8, start: usize, needle: u8) ?usize {
    var cursor = start;
    while (cursor < value.len) : (cursor += 1) if (value[cursor] == needle) return cursor;
    return null;
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and equals(value[0..prefix.len], prefix);
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and equalsIgnoreCase(value[0..prefix.len], prefix);
}

fn endsWithIgnoreCase(value: []const u8, suffix: []const u8) bool {
    return value.len >= suffix.len and equalsIgnoreCase(value[value.len - suffix.len ..], suffix);
}

fn containsIgnoreCase(value: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    var cursor: usize = 0;
    while (cursor + needle.len <= value.len) : (cursor += 1) if (equalsIgnoreCase(value[cursor .. cursor + needle.len], needle)) return true;
    return false;
}

fn indexOfIgnoreCase(value: []const u8, needle: []const u8) ?usize {
    if (needle.len == 0) return 0;
    var cursor: usize = 0;
    while (cursor + needle.len <= value.len) : (cursor += 1) {
        if (equalsIgnoreCase(value[cursor .. cursor + needle.len], needle)) return cursor;
    }
    return null;
}

fn equals(left: []const u8, right: []const u8) bool {
    return std.mem.eql(u8, left, right);
}

fn equalsIgnoreCase(left: []const u8, right: []const u8) bool {
    return std.ascii.eqlIgnoreCase(left, right);
}

fn isSpace(value: u8) bool {
    return value == ' ' or value == '\t' or value == '\r' or value == '\n' or value == 0x0C;
}

fn isIdentStart(value: u8) bool {
    return (value >= 'a' and value <= 'z') or (value >= 'A' and value <= 'Z') or value == '_' or value == '-';
}

fn isIdentByte(value: u8) bool {
    return isIdentStart(value) or (value >= '0' and value <= '9');
}

fn clamp(value: i32, minimum: i32, maximum: i32) i32 {
    return @min(maximum, @max(minimum, value));
}

fn clampUnsigned(value: anytype, minimum: @TypeOf(value), maximum: @TypeOf(value)) @TypeOf(value) {
    return @min(maximum, @max(minimum, value));
}

test "CSS parser handles selectors cascade inheritance variables and pseudo content" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><main id=page class='shell'><p class=note style='color:#123456'>Hello</p><a href=/next>Next</a></main></body>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    var sheet = Stylesheet{};
    const stats = try sheet.parse(
        ":root { --accent: #204080; color: #111; } " ++
            "main > p { color: red; margin-top: 4px; } " ++
            "#page .note { color: var(--accent); padding-left: 2em; } " ++
            "a:link { color: blue; text-decoration: underline; } " ++
            ".note::before { content: 'Note: '; }",
    );
    try std.testing.expectEqual(@as(usize, 5), stats.rules);
    const body = document.findFirstElement("body").?;
    const body_style = sheet.compute(&document, body, null, .{}, .none);
    const main = document.findFirstElement("main").?;
    const main_style = sheet.compute(&document, main, &body_style, .{}, .none);
    const paragraph = document.findFirstElement("p").?;
    const style = sheet.compute(&document, paragraph, &main_style, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0x123456), style.color);
    try std.testing.expectEqual(@as(i32, 32), style.padding.left.pixels(200, style.font_size, 0));
    const before = sheet.compute(&document, paragraph, &main_style, .{}, .before);
    try std.testing.expectEqualStrings("Note: ", before.content);
}

test "CSS selector combinators attributes and structural pseudo classes match" {
    var document = html.Document{};
    _ = try document.parse("<body><ul><li data-kind=x>One</li><li>Two</li></ul></body>", .{});
    var sheet = Stylesheet{};
    _ = try sheet.parse("ul > li:first-child[data-kind=x] { color: #abcdef } li:last-child { font-weight: bold }");
    const body = document.findFirstElement("body").?;
    const body_style = sheet.compute(&document, body, null, .{}, .none);
    const list = document.findFirstElement("ul").?;
    const list_style = sheet.compute(&document, list, &body_style, .{}, .none);
    const first = document.findFirstElement("li").?;
    const first_style = sheet.compute(&document, first, &list_style, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0xABCDEF), first_style.color);
    const second = document.nodes[first].next_sibling;
    const second_style = sheet.compute(&document, second, &list_style, .{}, .none);
    try std.testing.expectEqual(@as(u16, 700), second_style.font_weight);
}

test "CSS width media queries select one responsive branch and preserve inline flex" {
    var document = html.Document{};
    _ = try document.parse(
        "<body><div class=wide>Wide</div><div class=narrow>Narrow</div>" ++
            "<input class=action type=submit value=Continue>" ++
            "<input id=secret type=hidden style='display:block' value=token></body>",
        .{},
    );
    var sheet = Stylesheet{};
    const stats = try sheet.parse(
        ".action{display:inline-flex}" ++
            "@media only screen and (max-width:480px){.wide{display:none}.narrow{display:block}}" ++
            "@media not screen and (max-width:480px){.wide{display:block}.narrow{display:none}}" ++
            "@media screen and (forced-colors:active){.action{display:none}}",
    );
    try std.testing.expectEqual(@as(usize, 6), stats.rules);
    const body = document.findFirstElement("body").?;
    const body_narrow = sheet.computeForViewport(&document, body, null, .{}, .none, 360);
    const wide = document.findFirstElement("div").?;
    const narrow = document.nodes[wide].next_sibling;
    try std.testing.expectEqual(Display.none, sheet.computeForViewport(&document, wide, &body_narrow, .{}, .none, 360).display);
    try std.testing.expectEqual(Display.block, sheet.computeForViewport(&document, narrow, &body_narrow, .{}, .none, 360).display);

    const body_wide = sheet.computeForViewport(&document, body, null, .{}, .none, 800);
    try std.testing.expectEqual(Display.block, sheet.computeForViewport(&document, wide, &body_wide, .{}, .none, 800).display);
    try std.testing.expectEqual(Display.none, sheet.computeForViewport(&document, narrow, &body_wide, .{}, .none, 800).display);
    const action = document.nodes[narrow].next_sibling;
    const secret = document.nodes[action].next_sibling;
    try std.testing.expectEqual(Display.inline_flex, sheet.computeForViewport(&document, action, &body_wide, .{}, .none, 800).display);
    try std.testing.expectEqual(Display.none, sheet.computeForViewport(&document, secret, &body_wide, .{}, .none, 800).display);
}

test "legacy center semantics and inline block formatting stay generic" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><center><span class=atomic>Action</span></center></body>",
        .{},
    );
    var sheet = Stylesheet{};
    _ = try sheet.parse(".atomic{display:inline-block}");
    const body = document.findFirstElement("body").?;
    const body_style = sheet.compute(&document, body, null, .{}, .none);
    const center = document.findFirstElement("center").?;
    const center_style = sheet.compute(&document, center, &body_style, .{}, .none);
    const span = document.findFirstElement("span").?;
    const span_style = sheet.compute(&document, span, &center_style, .{}, .none);
    try std.testing.expectEqual(Display.block, center_style.display);
    try std.testing.expectEqual(TextAlign.center, center_style.text_align);
    try std.testing.expectEqual(Display.inline_block, span_style.display);
}

test "CSS rebuild preserves completed external stylesheets" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>.local{color:#800000}</style>" ++
            "<body><div class=hidden>Hidden</div><div class=local>Local</div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    const external = ".hidden{display:none}.local{font-weight:700}";
    try sheet.rebuildDocumentStyles(&document, external);
    const hidden = document.findFirstElement("div").?;
    const local = document.nodes[hidden].next_sibling;
    try std.testing.expectEqual(Display.none, sheet.compute(&document, hidden, null, .{}, .none).display);
    try std.testing.expectEqual(@as(u16, 700), sheet.compute(&document, local, null, .{}, .none).font_weight);

    try document.setTextContent(local, "Changed");
    try sheet.rebuildDocumentStyles(&document, external);
    try std.testing.expectEqual(Display.none, sheet.compute(&document, hidden, null, .{}, .none).display);
    try std.testing.expectEqual(@as(u16, 700), sheet.compute(&document, local, null, .{}, .none).font_weight);
}

test "CSS flex shorthand exposes grow shrink and basis" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>.one{display:flex;flex:1 1 0%}.auto{flex:auto}.none{flex:none}</style>" ++
            "<body><div class=one></div><div class=auto></div><div class=none></div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const one = document.findFirstElement("div").?;
    const automatic = document.nodes[one].next_sibling;
    const none = document.nodes[automatic].next_sibling;
    const one_style = sheet.compute(&document, one, null, .{}, .none);
    try std.testing.expectEqual(@as(u16, 1), one_style.flex_grow);
    try std.testing.expectEqual(@as(u16, 1), one_style.flex_shrink);
    try std.testing.expectEqual(LengthKind.percent, one_style.flex_basis.kind);
    try std.testing.expectEqual(@as(i32, 0), one_style.flex_basis.value);
    const auto_style = sheet.compute(&document, automatic, null, .{}, .none);
    try std.testing.expectEqual(@as(u16, 1), auto_style.flex_grow);
    try std.testing.expectEqual(LengthKind.auto, auto_style.flex_basis.kind);
    const none_style = sheet.compute(&document, none, null, .{}, .none);
    try std.testing.expectEqual(@as(u16, 0), none_style.flex_grow);
    try std.testing.expectEqual(@as(u16, 0), none_style.flex_shrink);
}

test "CSS escaped utility selectors match literal class tokens responsively" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div class='sm:hidden basis-1/2 max-w-[1400px]'>Utility</div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    try sheet.append(
        ".basis-1\\/2{flex-basis:50%}.max-w-\\[1400px\\]{max-width:1400px}" ++
            "@media (min-width:640px){.sm\\:hidden{display:none}}",
    );
    const node = document.findFirstElement("div").?;
    const parent = ComputedStyle{};
    const narrow = sheet.computeForViewport(&document, node, &parent, .{}, .none, 500);
    const wide = sheet.computeForViewport(&document, node, &parent, .{}, .none, 800);
    try std.testing.expectEqual(Display.block, narrow.display);
    try std.testing.expectEqual(Display.none, wide.display);
    try std.testing.expectEqual(LengthKind.percent, narrow.flex_basis.kind);
    try std.testing.expectEqual(@as(i32, 50), narrow.flex_basis.value);
    try std.testing.expectEqual(LengthKind.px, narrow.max_width.kind);
    try std.testing.expectEqual(@as(i32, 1400), narrow.max_width.value);
}

test "CSS rem lengths remain rooted instead of compounding element font size" {
    var document = html.Document{};
    _ = try document.parse("<!doctype html><style>h1{font-size:1.25rem;line-height:1.75rem;margin-right:2rem}</style><body><h1>Title</h1></body>", .{});
    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const heading = document.findFirstElement("h1").?;
    const style = sheet.compute(&document, heading, null, .{}, .none);
    try std.testing.expectEqual(@as(i32, 20), style.font_size);
    try std.testing.expectEqual(@as(i32, 28), style.line_height);
    try std.testing.expectEqual(@as(i32, 32), style.margin.right.pixels(800, style.font_size, 0));
}

test "CSS line height preserves computed lengths and inherited unitless factors" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>#parent{font-size:20px;line-height:150%}#fixed{font-size:10px;line-height:inherit}" ++
            "#factor{font-size:10px;line-height:1.5}</style><body><div id=parent><span id=fixed></span><span id=factor></span></div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const parent_node = testElementById(&document, "parent");
    const fixed_node = testElementById(&document, "fixed");
    const factor_node = testElementById(&document, "factor");
    const parent_style = sheet.compute(&document, parent_node, null, .{}, .none);
    const fixed_style = sheet.compute(&document, fixed_node, &parent_style, .{}, .none);
    const factor_style = sheet.compute(&document, factor_node, &parent_style, .{}, .none);
    try std.testing.expectEqual(@as(i32, 30), parent_style.line_height);
    try std.testing.expectEqual(@as(i32, 30), fixed_style.line_height);
    try std.testing.expectEqual(LineHeightKind.length, fixed_style.line_height_value.kind);
    try std.testing.expectEqual(LengthKind.px, fixed_style.line_height_value.length.kind);
    try std.testing.expectEqual(@as(i32, 15), factor_style.line_height);
    try std.testing.expectEqual(LineHeightKind.number, factor_style.line_height_value.kind);
}

test "CSS viewport calc sizing and complete flex alignment remain generic" {
    const main_width = parseLength("calc(100% - 64px)").?;
    try std.testing.expectEqual(LengthKind.calc, main_width.kind);
    try std.testing.expectEqual(@as(i32, 736), main_width.pixelsForViewport(800, 16, 0, 800, 600));
    const viewport_height = parseLength("100vh").?;
    try std.testing.expectEqual(@as(i32, 600), viewport_height.pixelsForViewport(800, 16, 0, 800, 600));
    const viewport_width = parseLength("12.5vw").?;
    try std.testing.expectEqual(@as(i32, 100), viewport_width.pixelsForViewport(800, 16, 0, 800, 600));

    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><main style='min-height:100vh;max-height:calc(100vh - 20px);box-sizing:border-box;justify-content:space-evenly;align-items:flex-end'>Content</main></body>",
        .{},
    );
    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const main = document.findFirstElement("main").?;
    const style = sheet.compute(&document, main, null, .{}, .none);
    try std.testing.expectEqual(LengthKind.vh, style.min_height.kind);
    try std.testing.expectEqual(LengthKind.calc, style.max_height.kind);
    try std.testing.expectEqual(BoxSizing.border_box, style.box_sizing);
    try std.testing.expectEqual(JustifyContent.space_evenly, style.justify_content);
    try std.testing.expectEqual(AlignItems.end, style.align_items);
}

test "CSS control visuals preserve border radii shadow RGBA and disabled state" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>.control{border:2px solid rgba(17,34,51,0.5);border-radius:24px 8px 4px / 12px 6px 2px;" ++
            "box-shadow:0 2px 6px 1px rgba(0,0,0,0.25),inset 1px 0 3px #10203080;background:rgb(248,249,250)}" ++
            ".control:disabled{background:#d0d0d0;color:#606060}" ++
            "#plain:enabled,#plain:disabled{color:red}</style>" ++
            "<body><button class=control disabled>Action</button><div id=plain disabled>Plain</div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    const button = document.findFirstElement("button").?;
    const normal = sheet.compute(&document, button, null, .{}, .none);
    try std.testing.expectEqual(LengthKind.px, normal.border.top.kind);
    try std.testing.expectEqual(@as(i32, 2), normal.border.top.value);
    try std.testing.expectEqual(@as(u32, 0x112233), normal.border_color);
    try std.testing.expectEqual(@as(i32, 24), normal.border_radius.top_left.x.value);
    try std.testing.expectEqual(@as(i32, 12), normal.border_radius.top_left.y.value);
    try std.testing.expectEqual(@as(i32, 8), normal.border_radius.top_right.x.value);
    try std.testing.expectEqual(@as(i32, 6), normal.border_radius.top_right.y.value);
    try std.testing.expectEqual(@as(i32, 4), normal.border_radius.bottom_right.x.value);
    try std.testing.expectEqual(@as(i32, 2), normal.border_radius.bottom_right.y.value);
    try std.testing.expectEqual(@as(i32, 8), normal.border_radius.bottom_left.x.value);
    try std.testing.expectEqual(@as(i32, 6), normal.border_radius.bottom_left.y.value);
    try std.testing.expectEqual(@as(u8, 2), normal.box_shadow.count);
    try std.testing.expect(!normal.box_shadow.layers[0].inset);
    try std.testing.expectEqual(@as(i32, 2), normal.box_shadow.layers[0].offset_y.value);
    try std.testing.expectEqual(@as(i32, 6), normal.box_shadow.layers[0].blur.value);
    try std.testing.expectEqual(@as(i32, 1), normal.box_shadow.layers[0].spread.value);
    try std.testing.expectEqual(@as(u8, 63), normal.box_shadow.layers[0].alpha);
    try std.testing.expect(normal.box_shadow.layers[1].inset);
    try std.testing.expectEqual(@as(i32, 1), normal.box_shadow.layers[1].offset_x.value);
    try std.testing.expectEqual(@as(u32, 0x102030), normal.box_shadow.layers[1].color);
    try std.testing.expectEqual(@as(u8, 128), normal.box_shadow.layers[1].alpha);
    try std.testing.expectEqual(@as(u32, 0xF8F9FA), normal.background_color.?);

    const disabled = sheet.compute(&document, button, null, .{ .disabled = true }, .none);
    try std.testing.expect(disabled.disabled);
    try std.testing.expectEqual(@as(u32, 0xD0D0D0), disabled.background_color.?);
    try std.testing.expectEqual(@as(u32, 0x606060), disabled.color);
    const plain = document.findFirstElement("div").?;
    const plain_style = sheet.compute(&document, plain, null, .{ .disabled = true }, .none);
    try std.testing.expectEqual(@as(u32, 0x000000), plain_style.color);
}

test "CSS background single layer values cascade reset and remain non inherited" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>" ++
            "#parent{background-color:#010203;background-image:url('../img/paper.svg');background-repeat:no-repeat;" ++
            "background-position:right 25%;background-size:32px 50%}" ++
            "#inherit{background-image:inherit;background-repeat:inherit;background-position:inherit;background-size:inherit}" ++
            "#fallback{background-image:url(fallback.png);background-image:linear-gradient(red,blue)}" ++
            "#multi{background-image:url(a.png),url(b.png)}" ++
            "#set{background-image:image-set(url(icon.png) 1x, url(icon@2x.png) 2x)}" ++
            "#short{background:#abcdef url(bg.svg) no-repeat right 12px/40% auto}" ++
            "</style><body><div id=parent><span id=child></span><span id=inherit></span></div>" ++
            "<div id=fallback></div><div id=multi></div><div id=set></div><div id=short></div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);

    const parent_style = sheet.compute(&document, testElementById(&document, "parent"), null, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0x010203), parent_style.background_color.?);
    try std.testing.expectEqual(BackgroundImageKind.url, parent_style.background_image.kind);
    try std.testing.expectEqualStrings("url('../img/paper.svg')", parent_style.background_image.raw_value);
    try std.testing.expectEqual(BackgroundRepeat.no_repeat, parent_style.background_repeat);
    try std.testing.expectEqual(LengthKind.percent, parent_style.background_position.x.kind);
    try std.testing.expectEqual(@as(i32, 100), parent_style.background_position.x.value);
    try std.testing.expectEqual(LengthKind.percent, parent_style.background_position.y.kind);
    try std.testing.expectEqual(@as(i32, 25), parent_style.background_position.y.value);
    try std.testing.expectEqual(BackgroundSizeKind.explicit, parent_style.background_size.kind);
    try std.testing.expectEqual(LengthKind.px, parent_style.background_size.width.kind);
    try std.testing.expectEqual(@as(i32, 32), parent_style.background_size.width.value);
    try std.testing.expectEqual(LengthKind.percent, parent_style.background_size.height.kind);
    try std.testing.expectEqual(@as(i32, 50), parent_style.background_size.height.value);

    const child_style = sheet.compute(&document, testElementById(&document, "child"), &parent_style, .{}, .none);
    try std.testing.expect(child_style.background_color == null);
    try std.testing.expectEqual(BackgroundImageKind.none, child_style.background_image.kind);
    try std.testing.expectEqual(BackgroundRepeat.repeat, child_style.background_repeat);
    try std.testing.expectEqual(@as(i32, 0), child_style.background_position.x.value);
    try std.testing.expectEqual(BackgroundSizeKind.auto, child_style.background_size.kind);

    const inherited = sheet.compute(&document, testElementById(&document, "inherit"), &parent_style, .{}, .none);
    try std.testing.expectEqual(BackgroundImageKind.url, inherited.background_image.kind);
    try std.testing.expectEqual(BackgroundRepeat.no_repeat, inherited.background_repeat);
    try std.testing.expectEqual(@as(i32, 100), inherited.background_position.x.value);
    try std.testing.expectEqual(BackgroundSizeKind.explicit, inherited.background_size.kind);

    const fallback = sheet.compute(&document, testElementById(&document, "fallback"), null, .{}, .none);
    try std.testing.expectEqual(BackgroundImageKind.url, fallback.background_image.kind);
    try std.testing.expectEqualStrings("url(fallback.png)", fallback.background_image.raw_value);
    const multiple = sheet.compute(&document, testElementById(&document, "multi"), null, .{}, .none);
    try std.testing.expectEqual(BackgroundImageKind.none, multiple.background_image.kind);
    const image_set = sheet.compute(&document, testElementById(&document, "set"), null, .{}, .none);
    try std.testing.expectEqual(BackgroundImageKind.image_set, image_set.background_image.kind);
    try std.testing.expectEqualStrings("image-set(url(icon.png) 1x, url(icon@2x.png) 2x)", image_set.background_image.raw_value);

    const shorthand = sheet.compute(&document, testElementById(&document, "short"), null, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0xABCDEF), shorthand.background_color.?);
    try std.testing.expectEqual(BackgroundImageKind.url, shorthand.background_image.kind);
    try std.testing.expectEqual(BackgroundRepeat.no_repeat, shorthand.background_repeat);
    try std.testing.expectEqual(@as(i32, 100), shorthand.background_position.x.value);
    try std.testing.expectEqual(LengthKind.px, shorthand.background_position.y.kind);
    try std.testing.expectEqual(@as(i32, 12), shorthand.background_position.y.value);
    try std.testing.expectEqual(BackgroundSizeKind.explicit, shorthand.background_size.kind);
    try std.testing.expectEqual(LengthKind.percent, shorthand.background_size.width.kind);
    try std.testing.expectEqual(LengthKind.auto, shorthand.background_size.height.kind);
}

test "CSS background parser keeps its declared single layer boundary" {
    try std.testing.expectEqual(BackgroundRepeat.repeat_x, parseBackgroundRepeat("repeat no-repeat").?);
    try std.testing.expectEqual(BackgroundRepeat.repeat_y, parseBackgroundRepeat("repeat-y").?);
    try std.testing.expectEqual(@as(i32, 0), parseBackgroundPosition("top left").?.x.value);
    try std.testing.expectEqual(@as(i32, 0), parseBackgroundPosition("top left").?.y.value);
    try std.testing.expectEqual(BackgroundSizeKind.contain, parseBackgroundSize("contain").?.kind);
    try std.testing.expectEqual(BackgroundSizeKind.cover, parseBackgroundSize("cover").?.kind);
    try std.testing.expect(parseBackgroundImage("linear-gradient(red, blue)") == null);
    try std.testing.expect(parseBackgroundImage("url(a.png), url(b.png)") == null);
    try std.testing.expect(parseBackgroundSize("10em") == null);
    try std.testing.expect(parseBackgroundRepeat("round") == null);
}

test "CSS background winners retain each external stylesheet final base URL" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><style>#embedded{background-image:url(icon.svg)}</style><body>" ++
            "<div id=first></div><div id=second></div><div id=winner></div>" ++
            "<div id=variable></div><div id=embedded></div>" ++
            "<div id=inline style='background-image:url(icon.svg)'></div></body>",
        .{},
    );

    var sheet = Stylesheet{};
    try sheet.appendDocumentStyles(&document);
    var redirected_base = "https://static-a.example/assets/redirected/theme.css".*;
    const expected_redirected_base = "https://static-a.example/assets/redirected/theme.css";
    try sheet.appendWithBase(
        "#first,#winner{background-image:url(icon.svg)}#variable{--asset:url(icon.svg)}",
        redirected_base[0..],
    );
    try sheet.appendWithBase(
        "#second{background-image:url(icon.svg)}#winner{background:url(icon.svg) no-repeat}" ++
            "#variable{background-image:var(--asset)}",
        "https://static-b.example/css/final/site.css",
    );
    redirected_base[8] = 'X';

    const first = sheet.compute(&document, testElementById(&document, "first"), null, .{}, .none);
    const second = sheet.compute(&document, testElementById(&document, "second"), null, .{}, .none);
    const winner = sheet.compute(&document, testElementById(&document, "winner"), null, .{}, .none);
    const variable = sheet.compute(&document, testElementById(&document, "variable"), null, .{}, .none);
    const embedded = sheet.compute(&document, testElementById(&document, "embedded"), null, .{}, .none);
    const inline_style = sheet.compute(&document, testElementById(&document, "inline"), null, .{}, .none);

    try std.testing.expectEqualStrings("url(icon.svg)", first.background_image.raw_value);
    try std.testing.expectEqualStrings("url(icon.svg)", second.background_image.raw_value);
    try std.testing.expectEqualStrings(expected_redirected_base, first.background_image.base_url);
    try std.testing.expectEqualStrings("https://static-b.example/css/final/site.css", second.background_image.base_url);
    try std.testing.expectEqualStrings("https://static-b.example/css/final/site.css", winner.background_image.base_url);
    try std.testing.expectEqual(BackgroundRepeat.no_repeat, winner.background_repeat);
    try std.testing.expectEqualStrings(expected_redirected_base, variable.background_image.base_url);
    try std.testing.expectEqualStrings(expected_redirected_base, sheet.sourceSectionBase(1));
    try std.testing.expectEqual(@as(usize, 3), sheet.sourceSectionCount());
    try std.testing.expectEqualStrings("#embedded{background-image:url(icon.svg)}", sheet.sourceSectionText(0));
    try std.testing.expectEqualStrings("#first,#winner{background-image:url(icon.svg)}#variable{--asset:url(icon.svg)}", sheet.sourceSectionText(1));
    try std.testing.expectEqualStrings("", sheet.sourceSectionText(99));
    try std.testing.expectEqualStrings("", embedded.background_image.base_url);
    try std.testing.expectEqualStrings("", inline_style.background_image.base_url);
}

test "CSS base URL storage is bounded and failed append is transactional" {
    var sheet = Stylesheet{};
    try sheet.appendWithBase(".kept{background-image:url(kept.png)}", "https://example.test/kept.css");
    const source_len = sheet.source_len;
    const base_url_len = sheet.base_url_len;
    const rule_count = sheet.rule_count;
    const declaration_count = sheet.declaration_count;
    const source_section_count = sheet.source_section_count;

    var oversized_base: [max_base_url_bytes + 1]u8 = undefined;
    @memset(&oversized_base, 'x');
    try std.testing.expectError(error.BaseUrlLimit, sheet.appendWithBase(".discarded{color:red}", &oversized_base));
    try std.testing.expectEqual(source_len, sheet.source_len);
    try std.testing.expectEqual(base_url_len, sheet.base_url_len);
    try std.testing.expectEqual(rule_count, sheet.rule_count);
    try std.testing.expectEqual(declaration_count, sheet.declaration_count);
    try std.testing.expectEqual(source_section_count, sheet.source_section_count);
    try std.testing.expectEqualStrings("https://example.test/kept.css", sheet.sourceSectionBase(0));
}

fn testElementById(document: *const html.Document, wanted: []const u8) u16 {
    var index: u16 = 0;
    while (index < document.node_count) : (index += 1) {
        if (document.nodes[index].kind != .element) continue;
        if (document.attribute(index, "id")) |actual| {
            if (std.mem.eql(u8, actual, wanted)) return index;
        }
    }
    return html.none;
}

test "CSS cascade keeps zero-score rules lexicographic specificity wide keywords and local custom values" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div id=parent><span id=child></span><div id=reset></div><span id=visible></span></div>" ++
            "<p id=zero></p><p id=specific class=many></p><p id=source class=source></p>" ++
            "<p id=important style='color:#010101'></p></body>",
        .{},
    );
    var sheet = Stylesheet{};
    _ = try sheet.parse(
        "*{border-color:#010203}" ++
            "#parent{color:#111111;visibility:hidden;--tone:#111111}" ++
            "span{--tone:#222222;color:var(--tone);visibility:unset}" ++
            "#reset{all:unset}" ++
            "#visible{visibility:visible}" ++
            "#specific{color:#aa0000}.many.many.many.many.many.many.many.many.many.many.many.many{color:#00aa00}" ++
            ".source{color:#121212}.source{color:#343434}" ++
            "#important{color:#abcdef!important}",
    );

    const parent_node = testElementById(&document, "parent");
    const parent_style = sheet.compute(&document, parent_node, null, .{}, .none);
    const child_style = sheet.compute(&document, testElementById(&document, "child"), &parent_style, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0x222222), child_style.color);
    try std.testing.expectEqual(Visibility.hidden, child_style.visibility);

    const reset_style = sheet.compute(&document, testElementById(&document, "reset"), &parent_style, .{}, .none);
    try std.testing.expectEqual(Display.inline_flow, reset_style.display);
    try std.testing.expectEqual(@as(u32, 0x111111), reset_style.color);
    try std.testing.expectEqual(Visibility.hidden, reset_style.visibility);
    const visible_style = sheet.compute(&document, testElementById(&document, "visible"), &parent_style, .{}, .none);
    try std.testing.expectEqual(Visibility.visible, visible_style.visibility);

    const zero_style = sheet.compute(&document, testElementById(&document, "zero"), null, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0x010203), zero_style.border_color);
    try std.testing.expectEqual(@as(u32, 0xAA0000), sheet.compute(&document, testElementById(&document, "specific"), null, .{}, .none).color);
    try std.testing.expectEqual(@as(u32, 0x343434), sheet.compute(&document, testElementById(&document, "source"), null, .{}, .none).color);
    try std.testing.expectEqual(@as(u32, 0xABCDEF), sheet.compute(&document, testElementById(&document, "important"), null, .{}, .none).color);
}

test "CSS selectors cover sibling functional attribute and structural matching" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><section id=group class=parent><span id=lead></span>" ++
            "<span id=target class=target data-tags='alpha beta' data-lang=en-US data-id=pre-middle-end data-case=Mixed></span>" ++
            "<em id=marker></em><span id=tail></span></section></body>",
        .{},
    );
    const group = testElementById(&document, "group");
    const lead = testElementById(&document, "lead");
    const target = testElementById(&document, "target");
    const tail = testElementById(&document, "tail");
    try std.testing.expect(matchesSelector(&document, target, "span + span.target"));
    try std.testing.expect(matchesSelector(&document, target, "#lead ~ .target"));
    try std.testing.expect(matchesSelector(&document, target, "[data-tags~=beta][data-lang|=en][data-id^=pre][data-id$=end][data-id*=middle]"));
    try std.testing.expect(matchesSelector(&document, target, "[data-case=mixed i]"));
    try std.testing.expect(matchesSelector(&document, target, "span:is(.target,.alternate):not(.excluded)"));
    try std.testing.expect(matchesSelector(&document, group, "section:has(> span.target)"));
    try std.testing.expect(matchesSelector(&document, lead, "span:first-child:empty"));
    try std.testing.expect(matchesSelector(&document, target, "span:nth-child(2):nth-of-type(2):nth-last-of-type(2)"));
    try std.testing.expect(matchesSelector(&document, tail, "span:last-child"));
    try std.testing.expect(!matchesSelector(&document, target, "span:not(.target)"));
}

test "CSS media queries use viewport height orientation lists and reject unknown features" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div id=portrait></div><div id=edge></div><div id=unknown></div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    _ = try sheet.parse(
        "#portrait,#edge,#unknown{display:none}" ++
            "@media screen and (min-height:500px) and (orientation:portrait){#portrait{display:block}}" ++
            "@media (max-width:400px), (min-width:900px){#edge{display:block}}" ++
            "@media screen and (unimplemented-feature:active){#unknown{display:block}}",
    );
    const portrait = testElementById(&document, "portrait");
    const edge = testElementById(&document, "edge");
    const unknown = testElementById(&document, "unknown");
    try std.testing.expectEqual(Display.block, sheet.computeForViewportSize(&document, portrait, null, .{}, .none, 420, 700).display);
    try std.testing.expectEqual(Display.none, sheet.computeForViewportSize(&document, portrait, null, .{}, .none, 700, 420).display);
    try std.testing.expectEqual(Display.block, sheet.computeForViewportSize(&document, edge, null, .{}, .none, 360, 600).display);
    try std.testing.expectEqual(Display.none, sheet.computeForViewportSize(&document, edge, null, .{}, .none, 640, 600).display);
    try std.testing.expectEqual(Display.block, sheet.computeForViewportSize(&document, edge, null, .{}, .none, 960, 600).display);
    try std.testing.expectEqual(Display.none, sheet.computeForViewportSize(&document, unknown, null, .{}, .none, 960, 600).display);
}

test "CSS font face export follows media activity and preserves its source section base" {
    var sheet = Stylesheet{};
    try sheet.appendWithBase(
        "@media (max-width:599px){@font-face{font-family:Shared;src:url(compact.woff2)}}" ++
            "@media (min-width:600px){@font-face{font-family:Shared;src:url(wide.woff2)}}" ++
            "@media screen and (unimplemented-feature:active){@font-face{font-family:Shared;src:url(unknown.woff2)}}" ++
            ".host{@font-face{font-family:Nested;src:url(style-nested.woff2)}}" ++
            "@layer fonts{@font-face{font-family:Layered;src:url(layered.woff2)}}" ++
            "@supports(display:grid){@font-face{font-family:Supported;src:url(supported.woff2)}}",
        "https://fonts.example/css/final/site.css",
    );
    var wide = sheet.activeFontFaceRulesForViewportSize(800, 600);
    const wide_rule = wide.next().?;
    try std.testing.expectEqual(@as(usize, 0), wide_rule.source_section);
    try std.testing.expectEqualStrings("https://fonts.example/css/final/site.css", wide_rule.final_base_url);
    try std.testing.expect(std.mem.indexOf(u8, wide_rule.rule_text, "wide.woff2") != null);
    try std.testing.expect(std.mem.indexOf(u8, wide_rule.rule_text, "compact.woff2") == null);
    const wide_layer = wide.next().?;
    try std.testing.expect(std.mem.indexOf(u8, wide_layer.rule_text, "layered.woff2") != null);
    try std.testing.expect(wide.next() == null);

    var compact = sheet.activeFontFaceRulesForViewportSize(480, 800);
    const compact_rule = compact.next().?;
    try std.testing.expect(std.mem.indexOf(u8, compact_rule.rule_text, "compact.woff2") != null);
    try std.testing.expect(std.mem.indexOf(u8, compact_rule.rule_text, "wide.woff2") == null);
    const compact_layer = compact.next().?;
    try std.testing.expect(std.mem.indexOf(u8, compact_layer.rule_text, "layered.woff2") != null);
    try std.testing.expect(compact.next() == null);
}

test "CSS font face export deduplicates matching comma media branches" {
    var sheet = Stylesheet{};
    _ = try sheet.parse(
        "@media (min-width:300px), (max-width:900px){" ++
            "@font-face{font-family:Overlap;src:url(overlap.woff2)}}",
    );

    var overlapping = sheet.activeFontFaceRulesForViewportSize(600, 600);
    const rule = overlapping.next().?;
    try std.testing.expectEqualStrings(
        "@font-face{font-family:Overlap;src:url(overlap.woff2)}",
        rule.rule_text,
    );
    try std.testing.expect(overlapping.next() == null);
}

test "CSS font face limit rolls back the complete appended source section" {
    const face_source = "@font-face{}";
    var saturated_source: [max_font_face_rules * face_source.len]u8 = undefined;
    var face_index: usize = 0;
    while (face_index < max_font_face_rules) : (face_index += 1) {
        const start = face_index * face_source.len;
        @memcpy(saturated_source[start .. start + face_source.len], face_source);
    }

    var sheet = Stylesheet{};
    try sheet.appendWithBase(&saturated_source, "https://fonts.example/full.css");
    try std.testing.expectEqual(max_font_face_rules, sheet.font_face_rule_count);
    const source_len = sheet.source_len;
    const base_url_len = sheet.base_url_len;
    const source_section_count = sheet.source_section_count;

    try std.testing.expectError(
        error.FontFaceRuleLimit,
        sheet.appendWithBase("@font-face{}", "https://fonts.example/rejected.css"),
    );
    try std.testing.expectEqual(source_len, sheet.source_len);
    try std.testing.expectEqual(base_url_len, sheet.base_url_len);
    try std.testing.expectEqual(source_section_count, sheet.source_section_count);
    try std.testing.expectEqual(max_font_face_rules, sheet.font_face_rule_count);
    try std.testing.expectEqualStrings("https://fonts.example/full.css", sheet.sourceSectionBase(0));
}

test "CSS visibility overflow axes and generated content retain explicit computed state" {
    var document = html.Document{};
    _ = try document.parse("<!doctype html><body><div id=label data-code=R4OS></div></body>", .{});
    var sheet = Stylesheet{};
    _ = try sheet.parse(
        "#label{visibility:hidden;overflow:hidden auto}" ++
            "#label::before{content:'[' attr(data-code) ']'}",
    );
    const node = testElementById(&document, "label");
    const style = sheet.compute(&document, node, null, .{}, .none);
    try std.testing.expectEqual(Visibility.hidden, style.visibility);
    try std.testing.expectEqual(Overflow.hidden, style.overflow_x);
    try std.testing.expectEqual(Overflow.auto, style.overflow_y);
    const before = sheet.compute(&document, node, &style, .{}, .before);
    try std.testing.expect(before.content_is_expression);
    try std.testing.expectEqualStrings("'[' attr(data-code) ']'", before.content);
}

test "CSS shorthand and longhand winners follow declaration order in both directions" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div id=margin_shorthand></div><div id=margin_longhand></div>" ++
            "<div id=border_shorthand></div><div id=border_longhand></div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    _ = try sheet.parse(
        "#margin_shorthand{margin-top:9px;margin:1px}" ++
            "#margin_longhand{margin:1px;margin-top:9px}" ++
            "#border_shorthand{border-width:5px;border:2px solid #111111}" ++
            "#border_longhand{border:2px solid #111111;border-width:5px}",
    );
    const margin_shorthand = sheet.compute(&document, testElementById(&document, "margin_shorthand"), null, .{}, .none);
    const margin_longhand = sheet.compute(&document, testElementById(&document, "margin_longhand"), null, .{}, .none);
    const border_shorthand = sheet.compute(&document, testElementById(&document, "border_shorthand"), null, .{}, .none);
    const border_longhand = sheet.compute(&document, testElementById(&document, "border_longhand"), null, .{}, .none);
    try std.testing.expectEqual(@as(i32, 1), margin_shorthand.margin.top.value);
    try std.testing.expectEqual(@as(i32, 9), margin_longhand.margin.top.value);
    try std.testing.expectEqual(@as(i32, 2), border_shorthand.border.top.value);
    try std.testing.expectEqual(@as(i32, 5), border_longhand.border.top.value);
}

test "CSS cascade layers order normal important unlayered and inline declarations" {
    var document = html.Document{};
    _ = try document.parse(
        "<!doctype html><body><div id=layered class=item></div>" ++
            "<div id=inline class=item style='color:#220022!important;background-color:#330033'></div></body>",
        .{},
    );
    var sheet = Stylesheet{};
    _ = try sheet.parse(
        "@layer base, theme;" ++
            "@layer base{.item{color:#aa0000!important;background-color:#aa0000}}" ++
            "@layer theme{#layered,#inline{color:#00aa00!important;background-color:#00aa00;border-color:#00aa00!important}}" ++
            "div{background-color:#0000aa;border-color:#0000aa!important}",
    );

    try std.testing.expectEqual(@as(usize, 2), sheet.layer_count);
    const layered = sheet.compute(&document, testElementById(&document, "layered"), null, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0xAA0000), layered.color);
    try std.testing.expectEqual(@as(u32, 0x0000AA), layered.background_color.?);
    try std.testing.expectEqual(@as(u32, 0x00AA00), layered.border_color);

    const inline_style = sheet.compute(&document, testElementById(&document, "inline"), null, .{}, .none);
    try std.testing.expectEqual(@as(u32, 0x220022), inline_style.color);
    try std.testing.expectEqual(@as(u32, 0x330033), inline_style.background_color.?);
}
