const abi = @import("r4os_contract").abi;
const program = @import("program.zig");

pub const name = "R4DRAW";
pub const import_query = "R4DRAW:Query:1";
pub const group = abi.R4LGroup.r4draw;
pub const abi_version = abi.r4l_abi_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4draw.h";
pub const query_contract = "Repositories/Contract/ABI/R4LQuery.txt";

pub const Context = struct {
    base: program.Context,

    pub fn init(bundle: *const program.Bundle) Context {
        return .{ .base = program.Context.initBundle(bundle) };
    }

    pub fn fromProgram(ctx: program.Context) Context {
        return .{ .base = ctx };
    }

    // 0.57.2: ehrliche Vertragspruefung (ersetzt supports*-Versionsgates).
    pub fn hasFn(self: *const Context, comptime field: []const u8) bool {
        return self.base.hasDrawFn(field);
    }

    pub fn screenWidth(self: *const Context) u32 {
        return self.base.screenWidth();
    }

    pub fn screenHeight(self: *const Context) u32 {
        return self.base.screenHeight();
    }

    pub fn clear(self: *const Context, rgb: u32) void {
        self.base.clear(rgb);
    }

    pub fn rect(self: *const Context, x: i32, y: i32, w: u32, h: u32, rgb: u32) void {
        self.base.rect(x, y, w, h, rgb);
    }

    pub fn text(self: *const Context, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) void {
        self.base.text(x, y, value, fg, bg);
    }

    pub fn displayRevision(self: *const Context) u32 {
        return self.base.displayRevision();
    }

    pub fn displayBeginFrame(self: *const Context) i32 {
        return self.base.displayBeginFrame();
    }

    pub fn displayBeginFrameRect(self: *const Context, x: i32, y: i32, w: u32, h: u32) i32 {
        return self.base.displayBeginFrameRect(x, y, w, h);
    }

    pub fn displayPresent(self: *const Context) i32 {
        return self.base.displayPresent();
    }

    pub fn displayBlitXrgb32(self: *const Context, x: i32, y: i32, w: u32, h: u32, pixels: []const u32) i32 {
        return self.base.displayXrgb32Blit(x, y, w, h, pixels);
    }

    pub fn displayBlitXrgb32Stride(self: *const Context, x: i32, y: i32, w: u32, h: u32, source_stride_pixels: u32, pixels: []const u32) i32 {
        return self.base.displayXrgb32BlitStride(x, y, w, h, source_stride_pixels, pixels);
    }

    pub fn supportsDisplayPresentRegions(self: *const Context) bool {
        return self.base.supportsDisplayPresentRegions();
    }

    pub fn displayPresentRegions(self: *const Context, request: *const abi.DisplayPresentRequest, pixels: []const u32, regions: []const abi.DisplayDamageRect, out: *abi.DisplayPresentResult) i32 {
        return self.base.displayPresentRegions(request, pixels, regions, out);
    }

    pub fn displayPresentCapabilities(self: *const Context, out: *abi.DisplayPresentCapabilities) i32 {
        return self.base.displayPresentCapabilities(out);
    }

    pub fn displayPresentCompletion(self: *const Context, fence: u64, out: *abi.DisplayPresentCompletion) i32 {
        return self.base.displayPresentCompletion(fence, out);
    }

    pub fn guiClear(self: *const Context, rgb: u32) i32 {
        return self.base.guiClear(rgb);
    }

    pub fn guiRect(self: *const Context, x: i32, y: i32, w: u32, h: u32, rgb: u32) i32 {
        return self.base.guiRect(x, y, w, h, rgb);
    }

    pub fn guiDrawText(self: *const Context, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) i32 {
        return self.base.guiDrawText(x, y, value, fg, bg);
    }

    pub fn guiDrawTextEx(self: *const Context, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32, font_id: u32, flags: u32) i32 {
        return self.base.guiDrawTextEx(x, y, value, fg, bg, font_id, flags);
    }

    pub fn guiBlit(self: *const Context, x: i32, y: i32, w: u32, h: u32, scale: u32, pixels: []const u32) i32 {
        return self.base.guiBlit(x, y, w, h, scale, pixels);
    }

    pub fn guiBlendAlpha8(self: *const Context, x: i32, y: i32, w: u32, h: u32, stride: u32, rgb: u32, alpha: []const u8) i32 {
        return self.base.guiBlendAlpha8(x, y, w, h, stride, rgb, alpha);
    }

    pub fn guiRasterRead(self: *const Context, instance_id: u32, offset: u32, out: []u32) i32 {
        return self.base.guiRasterRead(instance_id, offset, out);
    }

    pub fn supportsGuiFrameContract(self: *const Context) bool {
        return self.base.supportsGuiFrameContract();
    }

    pub fn supportsGuiFrameDamageContract(self: *const Context) bool {
        return self.base.supportsGuiFrameDamageContract();
    }

    pub fn supportsGuiFrameStreamingContract(self: *const Context) bool {
        return self.base.supportsGuiFrameStreamingContract();
    }

    pub fn supportsGuiSharedRasterContract(self: *const Context) bool {
        return self.base.supportsGuiSharedRasterContract();
    }

    pub fn guiFrameBegin(self: *const Context) i32 {
        return self.base.guiFrameBegin();
    }

    pub fn guiFrameBeginDamage(self: *const Context, regions: []const abi.DisplayDamageRect) i32 {
        return self.base.guiFrameBeginDamage(regions);
    }

    pub fn guiFrameBeginReplace(self: *const Context, regions: []const abi.DisplayDamageRect) i32 {
        return self.base.guiFrameBeginReplace(regions);
    }

    pub fn guiFrameAppend(self: *const Context, commands: []const abi.GuiFrameCommand, resources: []const u8) i32 {
        return self.base.guiFrameAppend(commands, resources);
    }

    pub fn guiFrameCommit(self: *const Context) i32 {
        return self.base.guiFrameCommit();
    }

    pub fn guiFrameCancel(self: *const Context) i32 {
        return self.base.guiFrameCancel();
    }

    pub fn guiFrameInfo(self: *const Context, handle: ?*const abi.ProgramProcessHandle, out: *abi.GuiFrameInfo) i32 {
        return self.base.guiFrameInfo(handle, out);
    }

    pub fn guiFrameRead(self: *const Context, handle: *const abi.ProgramProcessHandle, expected_generation: u64, commands: []abi.GuiFrameCommand, resources: []u8, out: *abi.GuiFrameInfo) i32 {
        return self.base.guiFrameRead(handle, expected_generation, commands, resources, out);
    }

    pub fn guiFrameGenerationInfo(self: *const Context, handle: *const abi.ProgramProcessHandle, generation: u64, out: *abi.GuiFrameGenerationInfo) i32 {
        return self.base.guiFrameGenerationInfo(handle, generation, out);
    }

    pub fn guiFrameGenerationRead(self: *const Context, handle: *const abi.ProgramProcessHandle, generation: u64, commands: []abi.GuiFrameCommand, resources: []u8, regions: []abi.DisplayDamageRect, out: *abi.GuiFrameGenerationInfo) i32 {
        return self.base.guiFrameGenerationRead(handle, generation, commands, resources, regions, out);
    }

    pub fn guiFrameStreamInfo(self: *const Context, handle: *const abi.ProgramProcessHandle, out: *abi.GuiFrameStreamInfo) i32 {
        return self.base.guiFrameStreamInfo(handle, out);
    }

    pub fn guiSharedRasterCreate(self: *const Context, info: *const abi.GuiSharedRasterCreateInfo, out_handle: *abi.GuiSharedRasterHandle) i32 {
        return self.base.guiSharedRasterCreate(info, out_handle);
    }

    pub fn guiSharedRasterDestroy(self: *const Context, handle: *const abi.GuiSharedRasterHandle) i32 {
        return self.base.guiSharedRasterDestroy(handle);
    }

    pub fn guiSharedRasterMapWrite(self: *const Context, handle: *const abi.GuiSharedRasterHandle, out_map: *abi.GuiSharedRasterWriteMap) i32 {
        return self.base.guiSharedRasterMapWrite(handle, out_map);
    }

    pub fn guiSharedRasterPublish(self: *const Context, map: *const abi.GuiSharedRasterWriteMap, out_generation: *u64) i32 {
        return self.base.guiSharedRasterPublish(map, out_generation);
    }

    pub fn guiSharedRasterAcquire(
        self: *const Context,
        frame_owner: *const abi.ProgramProcessHandle,
        frame_generation: u64,
        raster_handle: *const abi.GuiSharedRasterHandle,
        raster_generation: u64,
        out_map: *abi.GuiSharedRasterMap,
    ) i32 {
        return self.base.guiSharedRasterAcquire(frame_owner, frame_generation, raster_handle, raster_generation, out_map);
    }

    pub fn guiSharedRasterRelease(self: *const Context, lease: *const abi.GuiSharedRasterLease) i32 {
        return self.base.guiSharedRasterRelease(lease);
    }

    pub fn guiPresent(self: *const Context) i32 {
        return self.base.guiPresent();
    }

    pub fn fontCount(self: *const Context) u32 {
        return self.base.fontCount();
    }

    pub fn fontInfo(self: *const Context, font_id: u32, out: *abi.GuiFontInfo) i32 {
        return self.base.fontInfo(font_id, out);
    }

    pub fn fontMeasure(self: *const Context, font_id: u32, value: [*:0]const u8, out: *abi.GuiTextMetrics) i32 {
        return self.base.fontMeasure(font_id, value, out);
    }

    pub fn fontGlyphRow(self: *const Context, font_id: u32, codepoint: u32, row: u32) u64 {
        return self.base.fontGlyphRow(font_id, codepoint, row);
    }

    pub fn fontGlyphBitmap(self: *const Context, font_id: u32, codepoint: u32, out: *abi.GuiGlyphBitmap) i32 {
        return self.base.fontGlyphBitmap(font_id, codepoint, out);
    }

    pub fn fontRevision(self: *const Context) u32 {
        return self.base.fontRevision();
    }

    pub fn fontReload(self: *const Context) i32 {
        return self.base.fontReload();
    }

    pub fn guiSetFont(self: *const Context, font_id: u32) i32 {
        return self.base.guiSetFont(font_id);
    }

    pub fn guiFont(self: *const Context, instance_id: u32, out: *abi.GuiFontInfo) i32 {
        return self.base.guiFont(instance_id, out);
    }

    pub fn textFont(self: *const Context, font_id: u32, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) void {
        self.base.textFont(font_id, x, y, value, fg, bg);
    }
};

test "r4draw exposes project and present ABI metadata" {
    const std = @import("std");
    try std.testing.expectEqualStrings("R4DRAW", name);
    try std.testing.expectEqualStrings("R4DRAW:Query:1", import_query);
    try std.testing.expectEqual(@as(u32, 3), @intFromEnum(group));
    try std.testing.expectEqual(abi.r4l_abi_version, abi_version);
    try std.testing.expectEqual(abi.r4xstart_r4draw_version, (abi.R4XStartR4Draw{}).abi_version);
    try std.testing.expectEqual(abi.remote_frame_format_xrgb32, (abi.RemoteFrameInfo{}).format);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4draw.h", c_header);
}
