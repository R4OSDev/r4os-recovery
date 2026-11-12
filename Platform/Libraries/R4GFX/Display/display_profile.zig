//! Retained display ICC transform. COLOR_V1 owns ICC/PCS arithmetic and VCGT;
//! this consumer owns bounded storage, source bytes and final SDR application.
const std = @import("std");
pub const max_file_bytes = 4 * 1024 * 1024;
pub fn Owner(comptime gfx: type) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        colors: gfx.ColorV1Client,
        storage: []align(16) u8,
        bytes: []u8,
        handle: gfx.R4GfxColorProfile,
        pub fn openFile(allocator: std.mem.Allocator, colors: gfx.ColorV1Client, sys: anytype, path: [*:0]const u8, intent: u32, flags: u32) !Self {
            const info = sys.fileInfo(path) orelse return error.File;
            if (info.is_dir != 0 or info.size < 132 or info.size > max_file_bytes) return error.File;
            const bytes = try allocator.alloc(u8, @intCast(info.size));
            defer allocator.free(bytes);
            if (sys.fileRead(path, bytes) != @as(i32, @intCast(bytes.len))) return error.File;
            return open(allocator, colors, bytes, intent, flags);
        }
        pub fn open(allocator: std.mem.Allocator, colors: gfx.ColorV1Client, bytes: []const u8, intent: u32, flags: u32) !Self {
            if (bytes.len < 132 or bytes.len > max_file_bytes or intent > 3 or flags & ~@as(u32, 3) != 0) return error.Invalid;
            const size = colors.color_profile_storage_size();
            if (size < 1024 or size > 64 * 1024 * 1024 + 4096) return error.Limit;
            const storage = try allocator.alignedAlloc(u8, .@"16", @intCast(size));
            errdefer allocator.free(storage);
            @memset(storage, 0);
            const copy = try allocator.dupe(u8, bytes);
            errdefer allocator.free(copy);
            var handle: gfx.R4GfxColorProfile = undefined;
            if (colors.color_profile_open(&.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorProfileConfig),
                .storage_address = @intFromPtr(storage.ptr), .storage_bytes = storage.len,
                .profile_address = @intFromPtr(copy.ptr), .profile_bytes = copy.len,
                .direction = gfx.color_profile_output, .intent = intent, .flags = flags, .reserved = 0 }, &handle) != gfx.status_ok)
                return error.Profile;
            return .{ .allocator = allocator, .colors = colors, .storage = storage, .bytes = copy, .handle = handle };
        }
        pub fn close(self: *Self) bool {
            if (self.handle.address != 0) {
                if (self.colors.color_profile_close(&self.handle) != gfx.status_ok) return false;
                self.handle = std.mem.zeroes(gfx.R4GfxColorProfile);
            }
            self.allocator.free(self.storage); self.storage = &.{};
            self.allocator.free(self.bytes); self.bytes = &.{};
            return true;
        }
        /// Only an unpublished output image may be passed. Failure can leave
        /// partial conversion and the caller must discard the entire frame.
        /// Keep the canonical SDR composition separately; never reuse encoded
        /// monitor pixels as the input for a subsequent composition/capture.
        pub fn applySdr(self: *const Self, pixels: []u32, width: u32, height: u32) !void {
            if (self.handle.address == 0 or width == 0 or height == 0 or @as(u64, width) * height != pixels.len) return error.Invalid;
            var input: [64]u32 = undefined;
            var cursor: usize = 0;
            while (cursor < pixels.len) {
                const count: usize = @min(input.len, pixels.len - cursor);
                @memcpy(input[0..count], pixels[cursor..][0..count]);
                const source: gfx.R4GfxColorImage = .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorImage),
                    .image = .{ .cpu_address = @intFromPtr(&input), .byte_length = count * 4, .pitch = count * 4,
                        .width = @intCast(count), .height = 1, .format = gfx.format_xrgb8888, .reserved = 0 },
                    .description = sdrDescription(false), .profile = std.mem.zeroes(gfx.R4GfxColorProfile) };
                var target = source;
                target.image.cpu_address = @intFromPtr(pixels[cursor..].ptr);
                target.description = sdrDescription(true); target.profile = self.handle;
                var result: gfx.R4GfxCpuStats = undefined;
                const rect: gfx.R4GfxRect = .{ .x = 0, .y = 0, .width = @intCast(count), .height = 1 };
                if (self.colors.color_image_transform(&source, &target, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorTransform),
                    .source_rect = rect, .target_rect = rect, .sampler = gfx.render_sampler_nearest,
                    .operation = gfx.render_operation_blit, .opacity = 65535, .flags = gfx.color_transform_output,
                    .pixel_budget = count }, &result) != gfx.status_ok) return error.Transform;
                cursor += count;
            }
        }
        fn sdrDescription(profile: bool) gfx.R4GfxColorDescription {
            return .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorDescription),
                .primaries = if (profile) gfx.color_primaries_icc else gfx.color_primaries_srgb,
                .transfer = if (profile) gfx.color_transfer_icc else gfx.color_transfer_srgb,
                .range = gfx.color_range_full, .alpha = gfx.color_alpha_opaque, .precision = gfx.color_precision_unorm8,
                .flags = 0, .reference_white = 1_000_000, .peak = 1_000_000, .black = 0, .reserved = 0 };
        }
    };
}
