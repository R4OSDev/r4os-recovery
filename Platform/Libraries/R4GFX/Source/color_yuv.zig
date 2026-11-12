//! Userland 4:2:0 reconstruction. CICP and sample positions are interpreted
//! here, independently of any decoder or GPU. H.273 (07/2024), equations
//! 30..38/45..47 and Table 8; BT.1886 display EOTF. Pinned originals and
//! libplacebo's EOTF/OETF mapping reference: GFX/0.79.40/YuvSources.
const std = @import("std");
const color = @import("color.zig");
pub const Error = error{ Invalid, Unsupported, Overflow };
pub const Format = enum(u32) { nv12 = 1, p010 = 2, yuv420p = 3 };
pub const Range = enum(u32) { full = 1, limited = 2 };
// Explicit positions, also used by AVChromaLocation. H.273's location type
// is this value minus one. Zero/unspecified is never guessed from resolution.
pub const Chroma = enum(u32) { left = 1, center = 2, top_left = 3, top = 4, bottom_left = 5, bottom = 6 };
pub const Rect = struct { x: u32, y: u32, width: u32, height: u32 };
pub const Metadata = struct {
    primaries: u32, transfer: u32, matrix: u32, range: Range, chroma: Chroma,
    reference_white: f32 = 100, peak: f32 = 100, black: f32 = 0,
    pub fn description(self: Metadata, format: Format) Error!color.Description {
        const desc: color.Description = .{
            .primaries = switch (self.primaries) {
                1 => .srgb, 5 => .bt601_625, 6, 7 => .bt601_525, 9 => .bt2020, 12 => .display_p3,
                else => return error.Unsupported,
            },
            .transfer = switch (self.transfer) {
                1, 6, 7, 14, 15 => .bt1886, 8 => .linear, 13 => .srgb, 16 => .pq, 18 => .hlg,
                else => return error.Unsupported,
            },
            // Y and C ranges have already been removed before RGB decoding.
            .range = .full, .alpha = .ignore, .precision = if (format == .p010) .unorm10 else .unorm8,
            .reference_white = self.reference_white, .peak = self.peak, .black = self.black,
        };
        desc.validate() catch |err| return if (err == error.Invalid) error.Invalid else error.Unsupported;
        return desc;
    }
};

// Rows map meaningful normalized Y/Cb/Cr codes (8 or10 bits) to electrical
// RGB. They do not contain storage-padding bits, an EOTF or primary conversion.
pub const Matrix = struct {
    rows: [3][4]f32,
    pub fn init(metadata: Metadata, format: Format) Error!Matrix {
        const weights: [2]f64 = switch (metadata.matrix) {
            1 => .{ 0.2126, 0.0722 }, 4 => .{ 0.30, 0.11 },
            5, 6 => .{ 0.299, 0.114 }, 7 => .{ 0.212, 0.087 }, 9 => .{ 0.2627, 0.0593 },
            else => return error.Unsupported, // Constant luminance/ICtCp require different math.
        };
        const kr = weights[0]; const kb = weights[1]; const kg = 1 - kr - kb;
        const maximum: f64 = if (format == .p010) 1023 else 255;
        const shift: f64 = if (format == .p010) 4 else 1;
        const yscale = if (metadata.range == .full) 1 else maximum / (219 * shift);
        const ybias: f64 = if (metadata.range == .full) 0 else -16.0 / 219.0;
        const cscale = if (metadata.range == .full) 1 else maximum / (224 * shift);
        const cbias = if (metadata.range == .full) -128 * shift / maximum else -128.0 / 224.0;
        const chroma_rows = [3][2]f64{ .{ 0, 2 * (1 - kr) },
            .{ -2 * kb * (1 - kb) / kg, -2 * kr * (1 - kr) / kg }, .{ 2 * (1 - kb), 0 } };
        var result: Matrix = undefined;
        for (chroma_rows, &result.rows) |coeff, *row| row.* = .{
            @floatCast(yscale), @floatCast(coeff[0] * cscale), @floatCast(coeff[1] * cscale),
            @floatCast(ybias + (coeff[0] + coeff[1]) * cbias),
        };
        return result;
    }
    pub fn apply(self: Matrix, code: [3]f32) color.Rgb {
        var result: color.Rgb = undefined;
        for (self.rows, &result) |row, *out| out.* = row[0] * code[0] + row[1] * code[1] + row[2] * code[2] + row[3];
        return result;
    }
};
pub fn chromaOffset(chroma: Chroma) [2]f32 {
    return switch (chroma) {
        .left => .{ 0, 0.5 }, .center => .{ 0.5, 0.5 }, .top_left => .{ 0, 0 },
        .top => .{ 0.5, 0 }, .bottom_left => .{ 0, 1 }, .bottom => .{ 0.5, 1 },
    };
}
pub const Plane = struct { bytes: []const u8, pitch: u64 };
pub const Image = struct {
    format: Format, width: u32, height: u32, crop: Rect,
    planes: [3]Plane, metadata: Metadata, matrix: Matrix, encoding: color.Encoding,
    pub fn init(format: Format, width: u32, height: u32, crop: Rect, planes: [3]Plane, metadata: Metadata) Error!Image {
        if (width == 0 or height == 0 or width > 16384 or height > 16384) return error.Invalid;
        try bounds(width, height, crop);
        const count: usize = if (format == .yuv420p) 3 else 2;
        for (planes, 0..) |plane, i| {
            if (i >= count) {
                if (plane.bytes.len != 0 or plane.pitch != 0) return error.Invalid;
                continue;
            }
            const rows: u64 = if (i == 0) height else (height + 1) / 2;
            const columns: u64 = if (i == 0) width else (width + 1) / 2;
            const components: u64 = if (i != 0 and format != .yuv420p) 2 else 1;
            const unit: u64 = if (format == .p010) 2 else 1;
            const row_bytes = columns * components * unit;
            if (plane.pitch < row_bytes or plane.pitch % (components * unit) != 0) return error.Invalid;
            const last = std.math.mul(u64, rows - 1, plane.pitch) catch return error.Overflow;
            const needed = std.math.add(u64, last, row_bytes) catch return error.Overflow;
            if (plane.bytes.len < needed) return error.Invalid;
            _ = std.math.add(u64, @intFromPtr(plane.bytes.ptr), plane.bytes.len) catch return error.Overflow;
        }
        const desc = try metadata.description(format);
        return .{ .format = format, .width = width, .height = height, .crop = crop, .planes = planes,
            .metadata = metadata, .matrix = try Matrix.init(metadata, format),
            .encoding = color.Encoding.initFast(desc) catch return error.Unsupported };
    }
    pub fn rectangle(self: *const Image, rect: Rect) Error!void {
        try bounds(self.width, self.height, rect);
        if (rect.x < self.crop.x or rect.y < self.crop.y or
            rect.x + rect.width > self.crop.x + self.crop.width or rect.y + rect.height > self.crop.y + self.crop.height) return error.Invalid;
    }
    pub fn readBytes(self: *const Image) u64 { return if (self.format == .p010) 18 else 9; }
    fn code(self: *const Image, component: usize, x: u32, y: u32) f32 {
        const index: usize = if (self.format == .yuv420p) component else @min(component, 1);
        const lanes: usize = if (component != 0 and self.format != .yuv420p) 2 else 1;
        const lane: usize = if (lanes == 2) component - 1 else 0;
        const unit: usize = if (self.format == .p010) 2 else 1;
        const plane = self.planes[index];
        const offset = y * plane.pitch + (x * lanes + lane) * unit;
        // P010 is little endian with ten MSBs. Ignore padding, even on CPU
        // imports; it must not turn into a fractional chroma/luma code.
        return if (self.format == .p010)
            @as(f32, @floatFromInt(std.mem.readInt(u16, plane.bytes[offset..][0..2], .little) >> 6)) / 1023
        else @as(f32, @floatFromInt(plane.bytes[offset])) / 255;
    }
    // Reconstruct chroma at an absolute coded-luma sample center. Cropping
    // never resets this phase. Only real plane edges clamp the filter taps.
    pub fn load(self: *const Image, x: u32, y: u32) color.Value {
        const offset = chromaOffset(self.metadata.chroma);
        const sx = axis((@as(f32, @floatFromInt(x)) - offset[0]) * 0.5, (self.width + 1) / 2);
        const sy = axis((@as(f32, @floatFromInt(y)) - offset[1]) * 0.5, (self.height + 1) / 2);
        var components: [3]f32 = .{ self.code(0, x, y), 0, 0 };
        for (1..3) |component| {
            const top = mix(self.code(component, sx.low, sy.low), self.code(component, sx.high, sy.low), sx.weight);
            const bottom = mix(self.code(component, sx.low, sy.high), self.code(component, sx.high, sy.high), sx.weight);
            components[component] = mix(top, bottom, sy.weight);
        }
        return .{ .rgb = self.matrix.apply(components), .alpha = 1 };
    }
};
fn bounds(width: u32, height: u32, rect: Rect) Error!void {
    if (rect.width == 0 or rect.height == 0 or rect.x >= width or rect.y >= height or
        rect.width > width - rect.x or rect.height > height - rect.y) return error.Invalid;
}
const Axis = struct { low: u32, high: u32, weight: f32 };
fn axis(position: f32, extent: u32) Axis {
    const p = std.math.clamp(position, 0, @as(f32, @floatFromInt(extent - 1)));
    const low: u32 = @intFromFloat(p);
    return .{ .low = low, .high = @min(low + 1, extent - 1), .weight = p - @as(f32, @floatFromInt(low)) };
}
fn mix(a: f32, b: f32, weight: f32) f32 { return a + (b - a) * weight; }
