const std = @import("std");
const app_fonts = @import("app_fonts");
const project = @import("project");

const sample = @embedFile("../Fixtures/sample-glyf.ttf");

fn identity() app_fonts.FontContext {
    return app_fonts.FontContext.initHeader(&project.r4font_api_v1.header).?;
}

test "FaceStore shares copied sources and retires faces before their bytes" {
    var store = try app_fonts.FaceStore.init(identity(), std.testing.allocator, .{
        .max_cached_glyphs = 1,
        .max_cached_bytes = app_fonts.default_cached_bytes,
    });
    defer store.deinit();

    var first = try store.openCopy(sample, 0);
    var second = try store.openCopy(sample, 0);
    var diagnostics = store.diagnostics();
    try std.testing.expectEqual(@as(usize, 2), diagnostics.active_faces);
    try std.testing.expectEqual(@as(usize, 1), diagnostics.source_objects);
    try std.testing.expectEqual(@as(usize, sample.len), diagnostics.source_bytes);

    const info = try store.info(first);
    try std.testing.expectEqualStrings("CanvasTest", info.family);
    try std.testing.expectEqualStrings("Medium", info.style);
    const glyph = (try store.glyphIndex(first, 'A')) orelse return error.MissingGlyph;
    try std.testing.expectEqual(@as(u32, 8), glyph);
    try std.testing.expect(!(try store.hasGlyph(first, 0x10FFFF)));

    const face_metrics = try store.faceMetricsAt(first, 32);
    try std.testing.expectEqual(@as(i32, 5100), face_metrics.height);
    try std.testing.expectEqual(@as(i32, 5284), face_metrics.line_height);
    try std.testing.expectEqual(@as(i32, 3490), face_metrics.baseline);
    try std.testing.expect(face_metrics.max_advance > 0);

    const glyph_metrics = try store.glyphMetricsAt(first, glyph, 32);
    try std.testing.expectEqual(@as(i32, 2048), glyph_metrics.advance_x);
    try std.testing.expectEqual(@as(i32, 2048), glyph_metrics.advance_y);
    try std.testing.expectEqual(@as(i32, 0), glyph_metrics.bearing_x);
    try std.testing.expectEqual(@as(i32, 1536), glyph_metrics.bearing_y);
    try std.testing.expectEqual(@as(i32, 2048), glyph_metrics.width);
    try std.testing.expectEqual(@as(i32, 1536), glyph_metrics.height);

    const first_raster = try store.rasterizeCached(first, glyph, 32);
    try std.testing.expectEqual(@as(u32, 32), first_raster.width);
    try std.testing.expectEqual(@as(u32, 24), first_raster.height);
    const first_pointer = @intFromPtr(first_raster.alpha.ptr);
    const cache_hit = try store.rasterizeCached(first, glyph, 32);
    try std.testing.expectEqual(first_pointer, @intFromPtr(cache_hit.alpha.ptr));
    try std.testing.expectEqual(@as(u64, 1), store.diagnostics().cache_hits);

    _ = try store.rasterizeCached(first, glyph, 16);
    diagnostics = store.diagnostics();
    try std.testing.expectEqual(@as(usize, 1), diagnostics.raster_entries);
    try std.testing.expect(diagnostics.raster_bytes > 0);
    try std.testing.expectEqual(@as(u64, 2), diagnostics.cache_misses);

    const stale = first;
    try store.release(&first);
    try std.testing.expectEqual(app_fonts.FaceHandle{}, first);
    try std.testing.expectError(error.InvalidHandle, store.info(stale));
    diagnostics = store.diagnostics();
    try std.testing.expectEqual(@as(usize, 1), diagnostics.active_faces);
    try std.testing.expectEqual(@as(usize, 1), diagnostics.source_objects);
    try std.testing.expectEqual(@as(usize, 0), diagnostics.raster_entries);

    var replacement = try store.openCopy(sample, 0);
    try std.testing.expectEqual(stale.slot, replacement.slot);
    try std.testing.expect(replacement.generation != stale.generation);
    try store.release(&replacement);
    try store.release(&second);
    diagnostics = store.diagnostics();
    try std.testing.expectEqual(@as(usize, 0), diagnostics.active_faces);
    try std.testing.expectEqual(@as(usize, 0), diagnostics.source_objects);
    try std.testing.expectEqual(@as(usize, 0), diagnostics.source_bytes);
    try std.testing.expectEqual(@as(usize, 0), diagnostics.raster_entries);
    try std.testing.expectEqual(@as(usize, 0), diagnostics.raster_bytes);
}

test "FaceStore rejects foreign handles and invalid scale without mutation" {
    var store = try app_fonts.FaceStore.init(identity(), std.testing.allocator, .{});
    defer store.deinit();
    var handle = try store.openCopy(sample, 0);
    defer store.release(&handle) catch {};

    var foreign = handle;
    foreign.owner +%= 1;
    try std.testing.expectError(error.InvalidHandle, store.release(&foreign));
    try std.testing.expect(foreign.owner != 0);
    try std.testing.expectError(error.InvalidArgument, store.faceMetricsAt(handle, 3));
    try std.testing.expectError(error.InvalidArgument, store.rasterizeCached(handle, 1, 257));
    try std.testing.expectEqual(@as(usize, 1), store.diagnostics().active_faces);
}
