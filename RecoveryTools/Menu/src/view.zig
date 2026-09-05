// Application-owned artwork and clipped text rendering. No window system.
const std = @import("std");

pub const labels = [_][]const u8{
    "Install R4OS",      "Update R4OS", "Update Recovery",
    "Manage Partitions", "Terminal",    "Exit and Restart",
};
pub const background: u32 = 0x030303;
pub const foreground: u32 = 0xdddcd2;
pub const muted: u32 = 0xb0aba5;
pub const accent: u32 = 0xd9352d;

pub const Rect = struct {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
    pub fn inset(self: Rect, n: u32) Rect {
        const dx = @min(n, self.w / 2);
        const dy = @min(n, self.h / 2);
        return .{ .x = self.x + dx, .y = self.y + dy, .w = self.w - dx * 2, .h = self.h - dy * 2 };
    }
    pub fn contains(self: Rect, x: u32, y: u32) bool {
        return x >= self.x and y >= self.y and x - self.x < self.w and y - self.y < self.h;
    }
};

pub const Geometry = struct {
    image: Rect,
    monitor: Rect,
    pub fn fit(width: u32, height: u32) Geometry {
        const w: u32 = @intCast(@min(@as(u64, width), @as(u64, height) * 1672 / 941));
        const h: u32 = @intCast(@as(u64, w) * 941 / 1672);
        const image = Rect{ .x = (width - w) / 2, .y = (height - h) / 2, .w = w, .h = h };
        // Interior bounds measured in the unmodified 1672x941 source. Round
        // inward; the surrounding metal frame must never become a text pixel.
        const left: u32 = @intCast((@as(u64, w) * 391 + 1671) / 1672);
        const top: u32 = @intCast((@as(u64, h) * 223 + 940) / 941);
        const right: u32 = @intCast(@as(u64, w) * 1284 / 1672);
        const bottom: u32 = @intCast(@as(u64, h) * 680 / 941);
        return .{ .image = image, .monitor = .{ .x = image.x + left, .y = image.y + top, .w = right -| left, .h = bottom -| top } };
    }
};

pub const Bitmap = struct {
    bytes: []const u8,
    offset: usize,
    width: u32,
    height: u32,
    stride: usize,

    pub fn parse(bytes: []const u8) ?Bitmap {
        if (bytes.len < 54 or !std.mem.eql(u8, bytes[0..2], "BM")) return null;
        const offset = std.mem.readInt(u32, bytes[10..14], .little);
        // This resource reader handles the shipped uncompressed 24-bit BMP.
        // Other image formats remain owned by normal R4OS image libraries.
        if (std.mem.readInt(u32, bytes[14..18], .little) != 40 or
            std.mem.readInt(u16, bytes[26..28], .little) != 1 or
            std.mem.readInt(u16, bytes[28..30], .little) != 24 or
            std.mem.readInt(u32, bytes[30..34], .little) != 0 or offset < 54) return null;
        const width = std.mem.readInt(u32, bytes[18..22], .little);
        const height = std.mem.readInt(u32, bytes[22..26], .little);
        if (width != 1672 or height != 941) return null;
        const stride = (@as(usize, width) * 3 + 3) & ~@as(usize, 3);
        if (@as(u64, offset) + stride * height > bytes.len) return null;
        return .{ .bytes = bytes, .offset = offset, .width = width, .height = height, .stride = stride };
    }
    pub fn pixel(self: Bitmap, x: u32, y: u32) u32 {
        const i = self.offset + (self.height - 1 - y) * self.stride + x * 3;
        return @as(u32, self.bytes[i]) | (@as(u32, self.bytes[i + 1]) << 8) | (@as(u32, self.bytes[i + 2]) << 16);
    }
};

pub const Canvas = struct {
    pixels: []u32,
    width: u32,
    height: u32,
    clip: Rect,
    pub fn artwork(self: *Canvas, bitmap: Bitmap, rect: Rect) void {
        @memset(self.pixels, 0);
        for (0..rect.h) |y| for (0..rect.w) |x| {
            const source_x: u32 = @intCast(x * bitmap.width / rect.w);
            const source_y: u32 = @intCast(y * bitmap.height / rect.h);
            self.pixels[(rect.y + y) * self.width + rect.x + x] = bitmap.pixel(source_x, source_y);
        };
    }
    pub fn fill(self: *Canvas, rect: Rect, color: u32) void {
        const left = @max(rect.x, self.clip.x);
        const top = @max(rect.y, self.clip.y);
        const right = @min(@min(rect.x +| rect.w, self.clip.x +| self.clip.w), self.width);
        const bottom = @min(@min(rect.y +| rect.h, self.clip.y +| self.clip.h), self.height);
        if (right <= left or bottom <= top) return;
        for (top..bottom) |y| @memset(self.pixels[y * self.width + left .. y * self.width + right], color);
    }
    pub fn glyph(self: *Canvas, x: u32, y: u32, rows: []const u64, width: u32, color: u32) void {
        for (rows, 0..) |bits, row| {
            const py = y +| @as(u32, @intCast(row));
            for (0..@min(width, 64)) |col| {
                const px = x +| @as(u32, @intCast(col));
                if (bits & (@as(u64, 1) << @intCast(col)) != 0 and px < self.width and py < self.height and self.clip.contains(px, py))
                    self.pixels[@as(usize, py) * self.width + px] = color;
            }
        }
    }
};

// Rebuild the bounded visible console from its canonical transcript. The
// console API owns history, clear, dimensions and the independent session.
pub fn transcript(bytes: []const u8, cells: []u8, cols: usize, rows: usize) void {
    if (cols == 0 or rows == 0 or cols > cells.len / rows) return;
    const grid = cells[0 .. cols * rows];
    @memset(grid, ' ');
    var x: usize = 0;
    var y: usize = 0;
    for (bytes) |ch| {
        switch (ch) {
            '\r' => x = 0,
            '\n' => {
                x = 0;
                y += 1;
            },
            0x0c => {
                @memset(grid, ' ');
                x = 0;
                y = 0;
            },
            0x08 => {
                if (x > 0) x -= 1 else if (y > 0) {
                    y -= 1;
                    x = cols - 1;
                }
                grid[y * cols + x] = ' ';
            },
            else => {
                if (ch < 0x20 or ch == 0x7f) continue;
                grid[y * cols + x] = ch;
                x += 1;
                if (x == cols) {
                    x = 0;
                    y += 1;
                }
            },
        }
        if (y >= rows) {
            std.mem.copyForwards(u8, grid[0 .. (rows - 1) * cols], grid[cols..]);
            @memset(grid[(rows - 1) * cols ..], ' ');
            y = rows - 1;
        }
    }
}

test "artwork and monitor share aspect transform with inward clipping" {
    const t = std.testing;
    for ([_][2]u32{ .{ 640, 480 }, .{ 800, 600 }, .{ 1024, 768 }, .{ 1920, 1080 }, .{ 2560, 1600 }, .{ 17, 9 }, .{ 0, 0 } }) |size| {
        const g = Geometry.fit(size[0], size[1]);
        try t.expect(g.image.x + g.image.w <= size[0] and g.image.y + g.image.h <= size[1]);
        try t.expect(g.monitor.x >= g.image.x and g.monitor.y >= g.image.y);
        try t.expect(g.monitor.x + g.monitor.w <= g.image.x + g.image.w);
        try t.expect(g.monitor.y + g.monitor.h <= g.image.y + g.image.h);
    }
    var pixels: [48]u32 = .{0x123456} ** 48;
    const rect = Rect{ .x = 2, .y = 1, .w = 4, .h = 3 };
    var c = Canvas{ .pixels = &pixels, .width = 8, .height = 6, .clip = rect };
    c.fill(.{ .x = 0, .y = 0, .w = 0xffffffff, .h = 0xffffffff }, 0);
    c.glyph(5, 2, &.{ 0xffff, 0xffff, 0xffff, 0xffff }, 16, 0xffffff);
    for (pixels, 0..) |pixel, i| if (!rect.contains(@intCast(i % 8), @intCast(i / 8))) try t.expectEqual(@as(u32, 0x123456), pixel);
}

test "console deletion wrapping clearing and bounded scroll preserve neighbours" {
    const t = std.testing;
    var data: [12]u8 = .{'!'} ** 12;
    transcript("abcX\x08d\r\nEF\r\nGH", data[2..10], 4, 2);
    try t.expectEqualStrings("EF  GH  ", data[2..10]);
    try t.expectEqualStrings("!!", data[0..2]);
    try t.expectEqualStrings("!!", data[10..12]);
    transcript("old\x0cnew", data[2..10], 4, 2);
    try t.expectEqualStrings("new     ", data[2..10]);
}
