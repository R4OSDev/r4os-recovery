const std = @import("std");
pub const r4font = @import("r4font.zig");
pub const abi = r4font.abi;
pub const font_format = @import("font_format.zig");

pub const default_cached_glyphs: usize = 512;
pub const default_cached_bytes: usize = 8 * 1024 * 1024;
pub const min_pixel_height: u32 = 4;
pub const max_pixel_height: u32 = 256;

pub const Error = r4font.Error || error{InvalidHandle};
pub const FontContext = r4font.Context;

/// App-local identity.  It is deliberately unrelated to installed GUI-font
/// IDs and cannot be used by another FaceStore.
pub const FaceHandle = extern struct {
    owner: u64 = 0,
    slot: u32 = 0,
    generation: u32 = 0,
};

pub const Options = struct {
    decoder_allocation_limit: usize = r4font.default_allocation_limit,
    max_cached_glyphs: usize = default_cached_glyphs,
    max_cached_bytes: usize = default_cached_bytes,
};

pub const FaceInfo = r4font.FaceInfo;

pub const FaceMetrics26_6 = struct {
    height: i32,
    line_height: i32,
    baseline: i32,
    max_advance: i32,
};

pub const GlyphMetrics26_6 = struct {
    advance_x: i32,
    advance_y: i32,
    bearing_x: i32,
    bearing_y: i32,
    width: i32,
    height: i32,
};

pub const Kerning26_6 = [2]i32;

pub const BorrowedRaster = struct {
    glyph_index: u32,
    width: u32,
    height: u32,
    left: i32,
    top: i32,
    advance_x_26_6: i32,
    alpha: []const u8,
};

pub const CacheStats = struct {
    entries: usize,
    bytes: usize,
    max_entries: usize,
    max_bytes: usize,
    hits: u64,
    misses: u64,
};

pub const Diagnostics = struct {
    active_faces: usize,
    source_objects: usize,
    source_bytes: usize,
    raster_entries: usize,
    raster_bytes: usize,
    cache_hits: u64,
    cache_misses: u64,
    decoder: r4font.Diagnostics,
};

const Slot = struct {
    generation: u32 = 1,
    retired: bool = false,
    source_slot: ?u32 = null,
    face: ?r4font.Face = null,
};

const SourceObject = struct {
    digest: [32]u8,
    bytes: []u8,
    references: usize,
};

const SourceSlot = struct {
    object: ?SourceObject = null,
};

const CacheEntry = struct {
    slot: u32,
    generation: u32,
    glyph_index: u32,
    pixel_height: u32,
    stamp: u64,
    width: u32,
    height: u32,
    left: i32,
    top: i32,
    advance_x_26_6: i32,
    alpha: []u8,

    fn borrowed(self: *const CacheEntry) BorrowedRaster {
        return .{
            .glyph_index = self.glyph_index,
            .width = self.width,
            .height = self.height,
            .left = self.left,
            .top = self.top,
            .advance_x_26_6 = self.advance_x_26_6,
            .alpha = self.alpha,
        };
    }
};

var next_store_owner: u64 = 0;

/// Owns temporary font faces for one application.  Source bytes are copied;
/// an active face is always destroyed before its source allocation is freed.
/// Methods are owner-thread-only, matching the GUI drawing facade.
pub const FaceStore = struct {
    allocator: std.mem.Allocator,
    decoder: r4font.Decoder,
    owner: u64,
    options: Options,
    slots: std.ArrayList(Slot) = .empty,
    sources: std.ArrayList(SourceSlot) = .empty,
    cache: std.ArrayList(CacheEntry) = .empty,
    cache_bytes: usize = 0,
    cache_clock: u64 = 0,
    cache_hits: u64 = 0,
    cache_misses: u64 = 0,
    scratch: ?[]u8 = null,

    pub fn init(identity: r4font.Context, allocator: std.mem.Allocator, options: Options) Error!FaceStore {
        if (options.decoder_allocation_limit == 0 or options.max_cached_glyphs == 0 or options.max_cached_bytes == 0) {
            return error.InvalidArgument;
        }
        var validated_identity = identity;
        return .{
            .allocator = allocator,
            .decoder = try validated_identity.createDecoder(allocator, options.decoder_allocation_limit),
            .owner = allocateOwner(),
            .options = options,
        };
    }

    pub fn deinit(self: *FaceStore) void {
        self.clearRasterCache();
        if (self.scratch) |scratch| self.allocator.free(scratch);
        for (self.slots.items) |*slot| self.closeSlot(slot);
        for (self.sources.items) |*source_slot| {
            if (source_slot.object) |object| self.allocator.free(object.bytes);
            source_slot.object = null;
        }
        self.slots.deinit(self.allocator);
        self.sources.deinit(self.allocator);
        self.cache.deinit(self.allocator);
        self.decoder.deinit();
        self.* = undefined;
    }

    /// Copies the complete source before opening the face.  The caller may
    /// release or reuse its input immediately after this call returns.
    pub fn openCopy(self: *FaceStore, bytes: []const u8, face_index: u32) Error!FaceHandle {
        if (bytes.len == 0 or bytes.len > r4font.max_source_bytes) return error.InvalidArgument;
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});

        var source_slot_index: ?usize = null;
        for (self.sources.items, 0..) |source_slot, index| {
            const source = source_slot.object orelse continue;
            if (std.mem.eql(u8, &source.digest, &digest) and std.mem.eql(u8, source.bytes, bytes)) {
                source_slot_index = index;
                break;
            }
        }

        var new_source: ?[]u8 = null;
        const source_bytes = if (source_slot_index) |index|
            self.sources.items[index].object.?.bytes
        else blk: {
            const copy = self.allocator.dupe(u8, bytes) catch return error.OutOfMemory;
            new_source = copy;
            break :blk copy;
        };
        errdefer if (new_source) |source| self.allocator.free(source);
        var face = try self.decoder.openFace(source_bytes, face_index);
        errdefer face.deinit();

        var slot_index: usize = 0;
        while (slot_index < self.slots.items.len) : (slot_index += 1) {
            const slot = &self.slots.items[slot_index];
            if (!slot.retired and slot.face == null) break;
        }
        if (slot_index == self.slots.items.len) {
            if (slot_index >= std.math.maxInt(u32)) return error.TooLarge;
            try self.slots.append(self.allocator, .{});
        }

        if (source_slot_index == null) {
            var free_source_slot: usize = 0;
            while (free_source_slot < self.sources.items.len and self.sources.items[free_source_slot].object != null) : (free_source_slot += 1) {}
            if (free_source_slot == self.sources.items.len) {
                if (free_source_slot >= std.math.maxInt(u32)) return error.TooLarge;
                try self.sources.append(self.allocator, .{});
            }
            self.sources.items[free_source_slot].object = .{
                .digest = digest,
                .bytes = new_source.?,
                .references = 0,
            };
            new_source = null;
            source_slot_index = free_source_slot;
        }

        const slot = &self.slots.items[slot_index];
        const selected_source = &self.sources.items[source_slot_index.?].object.?;
        selected_source.references += 1;
        slot.source_slot = @intCast(source_slot_index.?);
        slot.face = face;
        return .{ .owner = self.owner, .slot = @intCast(slot_index), .generation = slot.generation };
    }

    pub fn release(self: *FaceStore, handle: *FaceHandle) Error!void {
        const value = handle.*;
        const slot = try self.lookupSlot(value);
        self.purgeHandleCache(value.slot, value.generation);
        self.closeSlot(slot);
        if (slot.generation == std.math.maxInt(u32)) {
            slot.retired = true;
        } else {
            slot.generation += 1;
        }
        handle.* = .{};
    }

    /// Returned strings borrow the face and remain valid only until release.
    pub fn info(self: *FaceStore, handle: FaceHandle) Error!FaceInfo {
        return (try self.lookupFace(handle)).info();
    }

    pub fn glyphIndex(self: *FaceStore, handle: FaceHandle, codepoint: u32) Error!?u32 {
        const glyph = (try self.lookupFace(handle)).glyphIndex(codepoint);
        return if (glyph == 0) null else glyph;
    }

    pub fn hasGlyph(self: *FaceStore, handle: FaceHandle, codepoint: u32) Error!bool {
        return (try self.glyphIndex(handle, codepoint)) != null;
    }

    pub fn faceMetricsAt(self: *FaceStore, handle: FaceHandle, pixel_height: u32) Error!FaceMetrics26_6 {
        try validatePixelHeight(pixel_height);
        const value = try (try self.lookupFace(handle)).info();
        const design_height = @as(i64, value.ascender) - @as(i64, value.descender);
        return .{
            .height = try scale26_6(design_height, pixel_height, value.units_per_em),
            .line_height = try scale26_6(value.line_height, pixel_height, value.units_per_em),
            .baseline = try scale26_6(value.ascender, pixel_height, value.units_per_em),
            .max_advance = try scale26_6(value.max_advance, pixel_height, value.units_per_em),
        };
    }

    pub fn glyphMetricsAt(self: *FaceStore, handle: FaceHandle, glyph_index: u32, pixel_height: u32) Error!GlyphMetrics26_6 {
        try validatePixelHeight(pixel_height);
        const face = try self.lookupFace(handle);
        const value = try face.glyphMetrics(glyph_index);
        const face_info = try face.info();
        return .{
            .advance_x = try scale26_6(value.advance_x, pixel_height, face_info.units_per_em),
            .advance_y = try scale26_6(value.advance_y, pixel_height, face_info.units_per_em),
            .bearing_x = try scale26_6(value.bearing_x, pixel_height, face_info.units_per_em),
            .bearing_y = try scale26_6(value.bearing_y, pixel_height, face_info.units_per_em),
            .width = try scale26_6(value.width, pixel_height, face_info.units_per_em),
            .height = try scale26_6(value.height, pixel_height, face_info.units_per_em),
        };
    }

    pub fn kerningAt(self: *FaceStore, handle: FaceHandle, left_glyph: u32, right_glyph: u32, pixel_height: u32) Error!Kerning26_6 {
        try validatePixelHeight(pixel_height);
        const face = try self.lookupFace(handle);
        const value = try face.kerning(left_glyph, right_glyph);
        const face_info = try face.info();
        return .{
            try scale26_6(value[0], pixel_height, face_info.units_per_em),
            try scale26_6(value[1], pixel_height, face_info.units_per_em),
        };
    }

    pub fn rasterize(self: *FaceStore, handle: FaceHandle, glyph_index: u32, pixel_height: u32, output: []u8) Error!r4font.Raster {
        try validatePixelHeight(pixel_height);
        return (try self.lookupFace(handle)).rasterize(glyph_index, pixel_height, output);
    }

    /// Alpha8 memory is owned by this store.  It remains valid until at least
    /// the next FaceStore call; release, clearRasterCache, or a later cache
    /// miss may evict it.  Hits never rerasterize the glyph.
    pub fn rasterizeCached(self: *FaceStore, handle: FaceHandle, glyph_index: u32, pixel_height: u32) Error!BorrowedRaster {
        try validatePixelHeight(pixel_height);
        const face = try self.lookupFace(handle);
        for (self.cache.items) |*entry| {
            if (entry.slot == handle.slot and entry.generation == handle.generation and
                entry.glyph_index == glyph_index and entry.pixel_height == pixel_height)
            {
                self.cache_hits +%= 1;
                entry.stamp = self.nextCacheStamp();
                return entry.borrowed();
            }
        }
        self.cache_misses +%= 1;

        const scratch = try self.ensureScratch();
        const raster = try face.rasterize(glyph_index, pixel_height, scratch);
        if (raster.alpha.len > self.options.max_cached_bytes) return error.TooLarge;
        self.makeCacheRoom(raster.alpha.len);
        const alpha = self.allocator.dupe(u8, raster.alpha) catch return error.OutOfMemory;
        errdefer self.allocator.free(alpha);
        try self.cache.append(self.allocator, .{
            .slot = handle.slot,
            .generation = handle.generation,
            .glyph_index = raster.glyph_index,
            .pixel_height = pixel_height,
            .stamp = self.nextCacheStamp(),
            .width = raster.width,
            .height = raster.height,
            .left = raster.left,
            .top = raster.top,
            .advance_x_26_6 = raster.advance_x_26_6,
            .alpha = alpha,
        });
        self.cache_bytes += alpha.len;
        return self.cache.items[self.cache.items.len - 1].borrowed();
    }

    pub fn cacheStats(self: *const FaceStore) CacheStats {
        return .{
            .entries = self.cache.items.len,
            .bytes = self.cache_bytes,
            .max_entries = self.options.max_cached_glyphs,
            .max_bytes = self.options.max_cached_bytes,
            .hits = self.cache_hits,
            .misses = self.cache_misses,
        };
    }

    pub fn diagnostics(self: *const FaceStore) Diagnostics {
        var active_faces: usize = 0;
        for (self.slots.items) |slot| if (slot.face != null) {
            active_faces += 1;
        };
        var source_objects: usize = 0;
        var source_bytes: usize = 0;
        for (self.sources.items) |source_slot| if (source_slot.object) |source| {
            source_objects += 1;
            source_bytes += source.bytes.len;
        };
        return .{
            .active_faces = active_faces,
            .source_objects = source_objects,
            .source_bytes = source_bytes,
            .raster_entries = self.cache.items.len,
            .raster_bytes = self.cache_bytes,
            .cache_hits = self.cache_hits,
            .cache_misses = self.cache_misses,
            .decoder = self.decoder.diagnostics(),
        };
    }

    pub fn clearRasterCache(self: *FaceStore) void {
        while (self.cache.items.len != 0) self.evictCacheIndex(self.cache.items.len - 1);
    }

    fn lookupSlot(self: *FaceStore, handle: FaceHandle) Error!*Slot {
        if (handle.owner == 0 or handle.owner != self.owner or handle.slot >= self.slots.items.len) return error.InvalidHandle;
        const slot = &self.slots.items[handle.slot];
        if (slot.retired or slot.generation != handle.generation or slot.face == null or slot.source_slot == null) return error.InvalidHandle;
        return slot;
    }

    fn lookupFace(self: *FaceStore, handle: FaceHandle) Error!*r4font.Face {
        const slot = try self.lookupSlot(handle);
        if (slot.face) |*face| return face;
        return error.InvalidHandle;
    }

    fn ensureScratch(self: *FaceStore) Error![]u8 {
        if (self.scratch) |scratch| return scratch;
        const capacity = r4font.max_raster_dimension * r4font.max_raster_dimension;
        const scratch = self.allocator.alloc(u8, capacity) catch return error.OutOfMemory;
        self.scratch = scratch;
        return scratch;
    }

    fn makeCacheRoom(self: *FaceStore, incoming_bytes: usize) void {
        while (self.cache.items.len != 0 and
            (self.cache.items.len >= self.options.max_cached_glyphs or
                incoming_bytes > self.options.max_cached_bytes -| self.cache_bytes))
        {
            self.evictCacheIndex(self.oldestCacheIndex());
        }
    }

    fn oldestCacheIndex(self: *const FaceStore) usize {
        var oldest: usize = 0;
        var index: usize = 1;
        while (index < self.cache.items.len) : (index += 1) {
            if (self.cache.items[index].stamp < self.cache.items[oldest].stamp) oldest = index;
        }
        return oldest;
    }

    fn evictCacheIndex(self: *FaceStore, index: usize) void {
        const removed = self.cache.swapRemove(index);
        self.cache_bytes -= removed.alpha.len;
        self.allocator.free(removed.alpha);
    }

    fn purgeHandleCache(self: *FaceStore, slot: u32, generation: u32) void {
        var index: usize = 0;
        while (index < self.cache.items.len) {
            const entry = self.cache.items[index];
            if (entry.slot == slot and entry.generation == generation) {
                self.evictCacheIndex(index);
            } else {
                index += 1;
            }
        }
    }

    fn closeSlot(self: *FaceStore, slot: *Slot) void {
        if (slot.face) |*face| face.deinit();
        slot.face = null;
        if (slot.source_slot) |source_slot| self.releaseSource(source_slot);
        slot.source_slot = null;
    }

    fn releaseSource(self: *FaceStore, source_slot: u32) void {
        if (source_slot >= self.sources.items.len) return;
        const slot = &self.sources.items[source_slot];
        const source = if (slot.object) |*object| object else return;
        if (source.references > 1) {
            source.references -= 1;
            return;
        }
        self.allocator.free(source.bytes);
        slot.object = null;
    }

    fn nextCacheStamp(self: *FaceStore) u64 {
        self.cache_clock +%= 1;
        if (self.cache_clock == 0) {
            for (self.cache.items, 0..) |*entry, index| entry.stamp = index + 1;
            self.cache_clock = self.cache.items.len + 1;
        }
        return self.cache_clock;
    }
};

fn validatePixelHeight(pixel_height: u32) Error!void {
    if (pixel_height < min_pixel_height or pixel_height > max_pixel_height) return error.InvalidArgument;
}

fn scale26_6(value: anytype, pixel_height: u32, units_per_em: u32) Error!i32 {
    if (units_per_em == 0) return error.InvalidFont;
    const numerator = @as(i128, @intCast(value)) * @as(i128, pixel_height) * 64;
    const denominator: i128 = units_per_em;
    const rounded = if (numerator >= 0)
        @divTrunc(numerator + @divTrunc(denominator, 2), denominator)
    else
        -@divTrunc(-numerator + @divTrunc(denominator, 2), denominator);
    if (rounded < std.math.minInt(i32) or rounded > std.math.maxInt(i32)) return error.TooLarge;
    return @intCast(rounded);
}

fn allocateOwner() u64 {
    while (true) {
        const owner = @atomicRmw(u64, &next_store_owner, .Add, 1, .acq_rel) +% 1;
        if (owner != 0) return owner;
    }
}

test "FaceStore public handle and metric layouts remain stable" {
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(FaceHandle));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(FaceHandle, "owner"));
    try std.testing.expectEqual(@as(usize, 8), @offsetOf(FaceHandle, "slot"));
    try std.testing.expectEqual(@as(usize, 12), @offsetOf(FaceHandle, "generation"));
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(FaceMetrics26_6));
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(GlyphMetrics26_6));
}
