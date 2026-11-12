const std = @import("std");
const r4os = @import("r4os");
pub const abi = @import("r4font_abi.zig");

pub const name = abi.module_name;
pub const import_api_v1 = "R4FONT:API_V1:1";
pub const max_source_bytes: usize = @intCast(abi.max_source_bytes);
pub const max_reconstructed_bytes: usize = @intCast(abi.max_reconstructed_bytes);
pub const max_raster_dimension: u32 = abi.max_raster_dimension;
pub const default_allocation_limit: usize = @intCast(abi.default_allocation_limit);

pub const Format = enum(u32) {
    unknown = abi.format_unknown,
    ttf = abi.format_ttf,
    otf_cff = abi.format_otf_cff,
    woff = abi.format_woff,
    woff2 = abi.format_woff2,
    collection = abi.format_collection,
};

pub const Error = error{
    InvalidArgument,
    OutOfMemory,
    UnsupportedFormat,
    InvalidFont,
    InvalidFaceIndex,
    InvalidGlyph,
    BufferTooSmall,
    TooLarge,
    DecoderFailure,
};

const AllocatorState = struct {
    allocator: std.mem.Allocator,
    fail_allocation_after: ?usize = null,
    fail_reallocation_after: ?usize = null,
};

pub const Diagnostics = struct {
    current_bytes: usize,
    peak_bytes: usize,
    allocation_count: usize,
    reallocation_count: usize,
    reallocation_failure_count: usize,
    allocation_limit: usize,
    allocation_failed: bool,
};

pub const TestingFaultInjection = struct {
    allocation_after: ?usize = null,
    reallocation_after: ?usize = null,
};

pub const FaceInfo = struct {
    face_count: u32,
    face_index: u32,
    glyph_count: u32,
    units_per_em: u32,
    ascender: i32,
    descender: i32,
    line_height: i32,
    max_advance: i32,
    bold: bool,
    italic: bool,
    family: []const u8,
    style: []const u8,
};

pub const GlyphMetrics = struct {
    glyph_index: u32,
    advance_x: i32,
    advance_y: i32,
    bearing_x: i32,
    bearing_y: i32,
    width: i32,
    height: i32,
};

pub const Raster = struct {
    glyph_index: u32,
    width: u32,
    height: u32,
    left: i32,
    top: i32,
    advance_x_26_6: i32,
    alpha: []u8,
};

pub const Context = struct {
    client: abi.ApiV1Client,

    pub fn init(raw: *const r4os.abi.R4XStartContext) ?Context {
        return .{ .client = abi.ApiV1Client.init(raw) catch return null };
    }

    pub fn init2(raw: *const r4os.platform2.abi.R4XStartContext2) ?Context {
        return .{ .client = abi.ApiV1Client.init2(raw) catch return null };
    }

    pub fn initTable(table: *const abi.ApiV1) ?Context {
        return initHeader(&table.header);
    }

    pub fn initHeader(header: *const abi.InterfaceHeader) ?Context {
        const expected = abi.api_v1_header;
        if (header.magic != expected.magic or
            header.header_version != expected.header_version or
            header.size < expected.size or
            header.abi_major != expected.abi_major or
            header.abi_minor < expected.abi_minor or
            header.interface_id_lo != expected.interface_id_lo or
            header.interface_id_hi != expected.interface_id_hi)
        {
            return null;
        }
        return .{ .client = .{ .header = header } };
    }

    pub fn sniff(self: *const Context, bytes: []const u8) ?Format {
        var output: u32 = abi.format_unknown;
        resultError(self.client.sniff(bytes.ptr, bytes.len, &output)) catch return null;
        return formatFromAbi(output);
    }

    pub fn createDecoder(self: *const Context, allocator: std.mem.Allocator, allocation_limit: usize) Error!Decoder {
        if (allocation_limit == 0) return error.InvalidArgument;
        const state = allocator.create(AllocatorState) catch return error.OutOfMemory;
        errdefer allocator.destroy(state);
        state.* = .{ .allocator = allocator };
        const descriptor = abi.R4FontAllocator{
            .user = @intFromPtr(state),
            .alloc = @intFromPtr(&allocatorAlloc),
            .realloc = @intFromPtr(&allocatorRealloc),
            .free = @intFromPtr(&allocatorFree),
        };
        var raw: u64 = 0;
        try resultError(self.client.decoder_create(&descriptor, allocation_limit, &raw));
        if (raw == 0) return error.DecoderFailure;
        return .{ .client = self.client, .raw = raw, .state = state };
    }
};

pub const Decoder = struct {
    client: abi.ApiV1Client,
    raw: u64,
    state: *AllocatorState,

    pub fn deinit(self: *Decoder) void {
        const allocator = self.state.allocator;
        resultError(self.client.decoder_destroy(self.raw)) catch unreachable;
        allocator.destroy(self.state);
        self.* = undefined;
    }

    pub fn diagnostics(self: *const Decoder) Diagnostics {
        var value = std.mem.zeroes(abi.R4FontDiagnostics);
        resultError(self.client.decoder_diagnostics(self.raw, &value)) catch unreachable;
        return .{
            .current_bytes = @intCast(value.current_bytes),
            .peak_bytes = @intCast(value.peak_bytes),
            .allocation_count = @intCast(value.allocation_count),
            .reallocation_count = @intCast(value.reallocation_count),
            .reallocation_failure_count = @intCast(value.reallocation_failure_count),
            .allocation_limit = @intCast(value.allocation_limit),
            .allocation_failed = value.allocation_failed != 0,
        };
    }

    pub fn openFace(self: *Decoder, bytes: []const u8, face_index: u32) Error!Face {
        if (bytes.len == 0) return error.InvalidArgument;
        var raw: u64 = 0;
        try resultError(self.client.decoder_open_face(self.raw, bytes.ptr, bytes.len, face_index, &raw));
        if (raw == 0) return error.DecoderFailure;
        return .{ .client = self.client, .raw = raw };
    }

    pub fn testingSetFaultInjection(self: *Decoder, injection: TestingFaultInjection) void {
        self.state.fail_allocation_after = injection.allocation_after;
        self.state.fail_reallocation_after = injection.reallocation_after;
    }
};

pub const Face = struct {
    client: abi.ApiV1Client,
    raw: u64,

    pub fn deinit(self: *Face) void {
        resultError(self.client.face_close(self.raw)) catch unreachable;
        self.* = undefined;
    }

    pub fn info(self: *const Face) Error!FaceInfo {
        var value = std.mem.zeroes(abi.R4FontFaceInfo);
        try resultError(self.client.face_info(self.raw, &value));
        return .{
            .face_count = value.face_count,
            .face_index = value.face_index,
            .glyph_count = value.glyph_count,
            .units_per_em = value.units_per_em,
            .ascender = value.ascender,
            .descender = value.descender,
            .line_height = value.line_height,
            .max_advance = value.max_advance,
            .bold = (value.style_flags & abi.style_bold) != 0,
            .italic = (value.style_flags & abi.style_italic) != 0,
            .family = borrowedString(value.family_address),
            .style = borrowedString(value.style_address),
        };
    }

    pub fn glyphIndex(self: *const Face, codepoint: u32) u32 {
        var output: u32 = 0;
        resultError(self.client.glyph_index(self.raw, codepoint, &output)) catch unreachable;
        return output;
    }

    pub fn glyphMetrics(self: *const Face, glyph_index: u32) Error!GlyphMetrics {
        var value = std.mem.zeroes(abi.R4FontGlyphMetrics);
        try resultError(self.client.glyph_metrics(self.raw, glyph_index, &value));
        return .{
            .glyph_index = value.glyph_index,
            .advance_x = value.advance_x,
            .advance_y = value.advance_y,
            .bearing_x = value.bearing_x,
            .bearing_y = value.bearing_y,
            .width = value.width,
            .height = value.height,
        };
    }

    pub fn kerning(self: *const Face, left_glyph: u32, right_glyph: u32) Error![2]i32 {
        var value = std.mem.zeroes(abi.R4FontKerning);
        try resultError(self.client.kerning(self.raw, left_glyph, right_glyph, &value));
        return .{ value.x, value.y };
    }

    pub fn rasterize(self: *const Face, glyph_index: u32, pixel_height: u32, output: []u8) Error!Raster {
        var value = std.mem.zeroes(abi.R4FontRaster);
        try resultError(self.client.rasterize(
            self.raw,
            glyph_index,
            pixel_height,
            if (output.len == 0) null else output.ptr,
            output.len,
            &value,
        ));
        const required = std.math.cast(usize, value.required_bytes) orelse return error.TooLarge;
        if (required > output.len) return error.BufferTooSmall;
        return .{
            .glyph_index = value.glyph_index,
            .width = value.width,
            .height = value.height,
            .left = value.left,
            .top = value.top,
            .advance_x_26_6 = value.advance_x_26_6,
            .alpha = output[0..required],
        };
    }
};

fn formatFromAbi(value: u32) ?Format {
    return switch (value) {
        abi.format_ttf => .ttf,
        abi.format_otf_cff => .otf_cff,
        abi.format_woff => .woff,
        abi.format_woff2 => .woff2,
        abi.format_collection => .collection,
        else => null,
    };
}

fn borrowedString(address: u64) []const u8 {
    if (address == 0) return "";
    const text: [*:0]const u8 = @ptrFromInt(@as(usize, @intCast(address)));
    return std.mem.span(text);
}

fn allocatorAlloc(user: ?*anyopaque, size: usize, alignment: usize) callconv(.c) ?*anyopaque {
    const state: *AllocatorState = @ptrCast(@alignCast(user orelse return null));
    if (consumeFault(&state.fail_allocation_after)) return null;
    const memory = state.allocator.rawAlloc(size, .fromByteUnits(alignment), @returnAddress()) orelse return null;
    return @ptrCast(memory);
}

fn allocatorRealloc(user: ?*anyopaque, block: ?*anyopaque, old_size: usize, new_size: usize, alignment: usize) callconv(.c) ?*anyopaque {
    const state: *AllocatorState = @ptrCast(@alignCast(user orelse return null));
    const old_pointer: [*]u8 = @ptrCast(block orelse return allocatorAlloc(user, new_size, alignment));
    if (new_size == 0) {
        state.allocator.rawFree(old_pointer[0..old_size], .fromByteUnits(alignment), @returnAddress());
        return null;
    }
    if (consumeFault(&state.fail_reallocation_after)) return null;
    const replacement = state.allocator.rawAlloc(new_size, .fromByteUnits(alignment), @returnAddress()) orelse return null;
    @memcpy(replacement[0..@min(old_size, new_size)], old_pointer[0..@min(old_size, new_size)]);
    state.allocator.rawFree(old_pointer[0..old_size], .fromByteUnits(alignment), @returnAddress());
    return @ptrCast(replacement);
}

fn allocatorFree(user: ?*anyopaque, block: ?*anyopaque, size: usize, alignment: usize) callconv(.c) void {
    const state: *AllocatorState = @ptrCast(@alignCast(user orelse return));
    const memory: [*]u8 = @ptrCast(block orelse return);
    state.allocator.rawFree(memory[0..size], .fromByteUnits(alignment), @returnAddress());
}

fn consumeFault(countdown: *?usize) bool {
    const remaining = countdown.* orelse return false;
    if (remaining == 0) {
        countdown.* = null;
        return true;
    }
    countdown.* = remaining - 1;
    return false;
}

fn resultError(status: i32) Error!void {
    return switch (status) {
        abi.status_ok => {},
        abi.status_invalid_argument => error.InvalidArgument,
        abi.status_out_of_memory => error.OutOfMemory,
        abi.status_unsupported_format => error.UnsupportedFormat,
        abi.status_invalid_font => error.InvalidFont,
        abi.status_invalid_face_index => error.InvalidFaceIndex,
        abi.status_invalid_glyph => error.InvalidGlyph,
        abi.status_buffer_too_small => error.BufferTooSmall,
        abi.status_too_large => error.TooLarge,
        abi.status_decoder_failure => error.DecoderFailure,
        else => error.DecoderFailure,
    };
}

test "R4FONT facade is bound only to the local API table" {
    try std.testing.expectEqualStrings("R4FONT", name);
    try std.testing.expectEqualStrings("R4FONT:API_V1:1", import_api_v1);
    try std.testing.expectEqual(@as(usize, 120), @sizeOf(abi.ApiV1));
}
