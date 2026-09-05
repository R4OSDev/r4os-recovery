const std = @import("std");

pub const max_width: u32 = 128;
pub const max_height: u32 = 128;
pub const max_pixels: usize = @as(usize, max_width) * @as(usize, max_height);
pub const default_background: u32 = 0x00FFFFFF;

pub const Error = error{
    InvalidSize,
    TooLarge,
};

pub const Image = struct {
    width: u32 = 0,
    height: u32 = 0,
    storage: []u32,

    pub fn pixelCount(self: Image) usize {
        return @as(usize, self.width) * @as(usize, self.height);
    }

    pub fn pixels(self: Image) []u32 {
        return self.storage[0..self.pixelCount()];
    }

    pub fn pixelsConst(self: Image) []const u32 {
        return self.storage[0..self.pixelCount()];
    }

    pub fn row(self: Image, y: u32) ?[]u32 {
        if (y >= self.height) return null;
        const start = @as(usize, y) * @as(usize, self.width);
        return self.storage[start .. start + @as(usize, self.width)];
    }

    pub fn setPixel(self: Image, x: u32, y: u32, color: u32) bool {
        if (x >= self.width or y >= self.height) return false;
        self.storage[self.index(x, y)] = normalizeColor(color);
        return true;
    }

    pub fn pixelAt(self: Image, x: u32, y: u32) ?u32 {
        if (x >= self.width or y >= self.height) return null;
        return self.storage[self.index(x, y)];
    }

    pub fn fill(self: Image, color: u32) void {
        @memset(self.storage[0..self.pixelCount()], normalizeColor(color));
    }

    pub fn resize(self: *Image, width: u32, height: u32, background: u32) Error!void {
        const needed = try requiredPixels(width, height);
        if (needed > self.storage.len) return Error.TooLarge;

        const old_width = self.width;
        const old_height = self.height;
        const keep_w = @min(old_width, width);
        const keep_h = @min(old_height, height);
        const bg = normalizeColor(background);

        if (width > old_width) {
            var y = keep_h;
            while (y > 0) {
                y -= 1;
                var x = keep_w;
                while (x > 0) {
                    x -= 1;
                    self.storage[@as(usize, y) * @as(usize, width) + x] = self.storage[@as(usize, y) * @as(usize, old_width) + x];
                }
            }
        } else {
            var y: u32 = 0;
            while (y < keep_h) : (y += 1) {
                var x: u32 = 0;
                while (x < keep_w) : (x += 1) {
                    self.storage[@as(usize, y) * @as(usize, width) + x] = self.storage[@as(usize, y) * @as(usize, old_width) + x];
                }
            }
        }

        self.width = width;
        self.height = height;
        var y: u32 = 0;
        while (y < height) : (y += 1) {
            var x: u32 = 0;
            while (x < width) : (x += 1) {
                if (x < keep_w and y < keep_h) continue;
                self.storage[@as(usize, y) * @as(usize, width) + x] = bg;
            }
        }
        if (needed < self.storage.len) @memset(self.storage[needed..], 0);
    }

    fn index(self: Image, x: u32, y: u32) usize {
        return @as(usize, y) * @as(usize, self.width) + @as(usize, x);
    }
};

pub fn init(storage: []u32, width: u32, height: u32, background: u32) Error!Image {
    const needed = try requiredPixels(width, height);
    if (needed > storage.len) return Error.TooLarge;
    var image = Image{ .width = width, .height = height, .storage = storage };
    image.fill(background);
    if (needed < storage.len) @memset(storage[needed..], 0);
    return image;
}

pub fn requiredPixels(width: u32, height: u32) Error!usize {
    if (width == 0 or height == 0) return Error.InvalidSize;
    if (width > max_width or height > max_height) return Error.TooLarge;
    const pixels = @as(u64, width) * @as(u64, height);
    if (pixels > max_pixels) return Error.TooLarge;
    return @intCast(pixels);
}

pub fn normalizeColor(color: u32) u32 {
    return color & 0x00FFFFFF;
}

pub fn rgb(r: u8, g: u8, b: u8) u32 {
    return (@as(u32, r) << 16) | (@as(u32, g) << 8) | b;
}

pub fn red(color: u32) u8 {
    return @intCast((color >> 16) & 0xFF);
}

pub fn green(color: u32) u8 {
    return @intCast((color >> 8) & 0xFF);
}

pub fn blue(color: u32) u8 {
    return @intCast(color & 0xFF);
}

test "raster view fills sets pixels and preserves overlap on resize" {
    var pixels: [16]u32 = .{0} ** 16;
    var image = try init(pixels[0..], 2, 2, rgb(255, 255, 255));
    try std.testing.expectEqual(@as(usize, 4), image.pixelCount());
    try std.testing.expect(image.setPixel(1, 0, rgb(1, 2, 3)));
    try std.testing.expectEqual(@as(?u32, rgb(1, 2, 3)), image.pixelAt(1, 0));
    try std.testing.expect(!image.setPixel(4, 0, 0));

    try image.resize(3, 3, rgb(9, 9, 9));
    try std.testing.expectEqual(@as(?u32, rgb(1, 2, 3)), image.pixelAt(1, 0));
    try std.testing.expectEqual(@as(?u32, rgb(9, 9, 9)), image.pixelAt(2, 2));

    try image.resize(1, 1, rgb(0, 0, 0));
    try std.testing.expectEqual(@as(usize, 1), image.pixelCount());
    try std.testing.expectEqual(@as(?u32, rgb(255, 255, 255)), image.pixelAt(0, 0));
}

test "raster size contract rejects empty and oversized images" {
    try std.testing.expectError(Error.InvalidSize, requiredPixels(0, 1));
    try std.testing.expectError(Error.TooLarge, requiredPixels(max_width + 1, 1));
    try std.testing.expectError(Error.TooLarge, requiredPixels(max_width, max_height + 1));
}
