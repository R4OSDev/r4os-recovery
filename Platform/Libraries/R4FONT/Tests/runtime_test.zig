const std = @import("std");
const project = @import("project");
const r4font = @import("r4font");
const r4os = @import("r4os");

const sample = @embedFile("Fixtures/sample-glyf.ttf");
const module_name: [:0]const u8 = "R4FONT";
const test_system: r4os.platform2.abi.R4XStartR4Sys2 = .{};
const api_name: [:0]const u8 = "API_V1";

fn makeContext(imports: []const r4os.abi.R4XStartImport) r4os.platform2.abi.R4XStartContext2 {
    return .{
        .flags = r4os.abi.r4xstart_flag_imports_valid,
        .imports = @intFromPtr(imports.ptr),
        .import_count = @intCast(imports.len),
    };
}

test "productive font decode crosses the named API_V1 table" {
    var imports = [3]r4os.abi.R4XStartImport{ .{
        .group_id = 0,
        .min_version = 1,
        .resolved_version = 1,
        .flags = 0,
        .module_name = @intFromPtr(module_name.ptr),
        .symbol_name = @intFromPtr(api_name.ptr),
        .table = @intFromPtr(&project.r4font_api_v1),
    }, .{ .min_version = 2, .resolved_version = 2, .module_name = @intFromPtr(module_name.ptr), .symbol_name = @intFromPtr("Query2"), .table = @intFromPtr(&project.r4font_query2) }, .{ .group_id = 1, .min_version = 2, .resolved_version = 2, .flags = r4os.abi.r4xstart_import_flag_group_interface, .module_name = @intFromPtr("R4SYS"), .symbol_name = @intFromPtr("Query2"), .table = @intFromPtr(&test_system) } };
    var raw = makeContext(&imports);
    raw.imports = @intFromPtr(&imports);
    var fonts = r4font.Context.init(&raw) orelse return error.MissingRuntimeBinding;
    try std.testing.expectEqual(r4font.Format.ttf, fonts.sniff(sample).?);
    var decoder = try fonts.createDecoder(std.testing.allocator, r4font.default_allocation_limit);
    defer decoder.deinit();
    var face = try decoder.openFace(sample, 0);
    defer face.deinit();
    const info = try face.info();
    try std.testing.expectEqualStrings("CanvasTest", info.family);
    const glyph = face.glyphIndex('A');
    try std.testing.expect(glyph != 0);
    var pixels: [r4font.max_raster_dimension * r4font.max_raster_dimension]u8 = undefined;
    const raster = try face.rasterize(glyph, 32, &pixels);
    try std.testing.expect(raster.alpha.len != 0);
}
