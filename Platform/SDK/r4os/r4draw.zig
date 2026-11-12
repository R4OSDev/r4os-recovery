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
    pub fn gfxOutputPower(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxOutputPower) i32 { return self.base.gfxOutputPower(identity, output); }
    pub fn gfxPowerRequest(self: *const Context, input: *const abi.GfxPowerRequest, output: *abi.GfxPowerRequest) i32 { return self.base.gfxPowerRequest(input, output); }
    pub fn gfxOutputBrightness(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxOutputBrightness) i32 { return self.base.gfxOutputBrightness(identity, output); }
    pub fn gfxBrightnessRequest(self: *const Context, input: *const abi.GfxBrightnessRequest, output: *abi.GfxBrightnessRequest) i32 { return self.base.gfxBrightnessRequest(input, output); }
    pub fn outputs(self: *const Context) @import("gfx_outputs.zig").Context { return .{ .base = self.base }; }
    pub fn gfxOutputRefresh(self: *const Context, target: *const abi.GfxOutputTarget, output: *abi.GfxOutputRefresh) i32 {
        return self.base.gfxOutputRefresh(target, output);
    }
    pub fn gfxRefreshRequest(self: *const Context, input: *const abi.GfxRefreshRequest, output: *abi.GfxRefreshRequest) i32 {
        return self.base.gfxRefreshRequest(input, output);
    }

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

    pub fn gfxVirtualStart(self: *const Context, input: *const abi.GfxVirtualRequest, output: *abi.GfxVirtualStatus) i32 { return self.base.gfxVirtualStart(input, output); }
    pub fn gfxVirtualQuery(self: *const Context, request: *const abi.GfxBufferHandle, output: *abi.GfxVirtualStatus) i32 { return self.base.gfxVirtualQuery(request, output); }
    pub fn gfxVirtualClose(self: *const Context, request: *const abi.GfxBufferHandle, mode: u32) i32 { return self.base.gfxVirtualClose(request, mode); }
    pub fn gfxVirtualWait(self: *const Context, request: *const abi.GfxBufferHandle, until: u32, timeout_ticks: u64, output: *abi.GfxVirtualStatus) i32 { return self.base.gfxVirtualWait(request, until, timeout_ticks, output); }

    pub fn gfxNativeStart(self: *const Context, input: *const abi.GfxNativeAllocation, output: *abi.GfxNativeStatus) i32 { return self.base.gfxNativeStart(input, output); }

    pub fn gfxNativeQuery(self: *const Context, request: *const abi.GfxBufferHandle, output: *abi.GfxNativeStatus) i32 { return self.base.gfxNativeQuery(request, output); }

    pub fn gfxNativeReceive(self: *const Context, request: *const abi.GfxBufferHandle, output: *abi.GfxBufferReference) i32 { return self.base.gfxNativeReceive(request, output); }

    pub fn gfxNativeClose(self: *const Context, request: *const abi.GfxBufferHandle) i32 { return self.base.gfxNativeClose(request); }

    pub fn gfxNativeWait(self: *const Context, request: *const abi.GfxBufferHandle, timeout_ticks: u64, output: *abi.GfxNativeStatus) i32 { return self.base.gfxNativeWait(request, timeout_ticks, output); }

    pub fn gfxBufferCreate(self: *const Context, descriptor: *const abi.GfxBufferDescriptor, output: *abi.GfxBufferReference) i32 {
        return self.base.gfxBufferCreate(descriptor, output);
    }

    pub fn gfxBufferDescribe(self: *const Context, reference: *const abi.GfxBufferHandle, output: *abi.GfxBufferDescriptor) i32 {
        return self.base.gfxBufferDescribe(reference, output);
    }

    pub fn gfxBufferImport(self: *const Context, source_reference: *const abi.GfxBufferHandle, output: *abi.GfxBufferReference) i32 {
        return self.base.gfxBufferImport(source_reference, output);
    }

    pub fn gfxBufferRelease(self: *const Context, reference: *const abi.GfxBufferHandle) i32 {
        return self.base.gfxBufferRelease(reference);
    }

    pub fn gfxBufferMap(self: *const Context, reference: *const abi.GfxBufferHandle, access: u32, offset: u64, byte_length: u64, output: *abi.GfxBufferMap) i32 {
        return self.base.gfxBufferMap(reference, access, offset, byte_length, output);
    }
    pub fn gfxBufferMapPersistent(self: *const Context, reference: *const abi.GfxBufferHandle, access: u32, offset: u64, byte_length: u64, output: *abi.GfxBufferMap) i32 {
        return self.base.gfxBufferMapPersistent(reference, access, offset, byte_length, output);
    }

    pub fn gfxBufferUnmap(self: *const Context, lease: *const abi.GfxBufferHandle) i32 {
        return self.base.gfxBufferUnmap(lease);
    }

    pub fn gfxBufferExportRaster(self: *const Context, lease: *const abi.GuiSharedRasterLease, output: *abi.GfxBufferReference) i32 {
        return self.base.gfxBufferExportRaster(lease, output);
    }

    pub fn gfxBufferStats(self: *const Context, output: *abi.GfxBufferStats) i32 {
        return self.base.gfxBufferStats(output);
    }

    pub fn gfxMemoryBudget(self: *const Context, input: *const abi.GfxDeviceBudgetRequest, output: *abi.GfxDeviceBudgetState) i32 {
        return self.base.gfxMemoryBudget(input, output);
    }

    pub fn gfxTelemetry(self: *const Context, input: *const abi.GfxTelemetryRequest, output: *abi.GfxTelemetryState) i32 {
        return self.base.gfxTelemetry(input, output);
    }

    pub fn buffers(self: *const Context) @import("gfx_buffers.zig").Context {
        return .{ .base = self.base };
    }

    pub fn gfxOutputRevision(self: *const Context, output: *abi.GfxDisplayRevision) i32 { return self.base.gfxOutputRevision(output); }
    pub fn gfxOutputInfo(self: *const Context, index: u32, output: *abi.GfxOutputInfo) i32 { return self.base.gfxOutputInfo(index, output); }
    pub fn gfxOutputMode(self: *const Context, identity: *const abi.GfxOutputId, index: u32, output: *abi.GfxOutputMode) i32 { return self.base.gfxOutputMode(identity, index, output); }
    pub fn gfxOutputEdid(self: *const Context, identity: *const abi.GfxOutputId, index: u32, output: *abi.GfxEdidBlock) i32 { return self.base.gfxOutputEdid(identity, index, output); }
    pub fn gfxAtomicTest(self: *const Context, state: *const abi.GfxAtomicState, output: *abi.GfxAtomicResult) i32 { return self.base.gfxAtomicTest(state, output); }
    pub fn gfxAtomicCommit(self: *const Context, state: *const abi.GfxAtomicState, output: *abi.GfxAtomicResult) i32 { return self.base.gfxAtomicCommit(state, output); }

    pub fn gfxQueueOpen(self: *const Context, config: *const abi.GfxQueueConfig, output: *abi.GfxQueueHandle) i32 {
        return self.base.gfxQueueOpen(config, output);
    }
    pub fn gfxQueueBackend(self: *const Context, index: u32, output: *abi.GfxBackendBinding) i32 {
        return self.base.gfxQueueBackend(index, output);
    }

    pub fn gfxQueueClose(self: *const Context, queue: *const abi.GfxQueueHandle) i32 {
        return self.base.gfxQueueClose(queue);
    }

    pub fn gfxQueueSubmit(self: *const Context, queue: *const abi.GfxQueueHandle, submission: *const abi.GfxSubmission, output: *abi.GfxFenceStatus) i32 {
        return self.base.gfxQueueSubmit(queue, submission, output);
    }

    pub fn gfxQueueSubmitNative(self: *const Context, queue: *const abi.GfxQueueHandle, submission: *const abi.GfxSubmission, native: *const abi.GfxNativeSubmission, output: *abi.GfxFenceStatus) i32 {
        return self.base.gfxQueueSubmitNative(queue, submission, native, output);
    }

    pub fn gfxFenceQuery(self: *const Context, fence: *const abi.GfxFence, output: *abi.GfxFenceStatus) i32 {
        return self.base.gfxFenceQuery(fence, output);
    }

    pub fn gfxFenceWait(self: *const Context, fence: *const abi.GfxFence, timeout_ticks: u64, wait_for: u32, output: *abi.GfxFenceStatus) i32 {
        return self.base.gfxFenceWait(fence, timeout_ticks, wait_for, output);
    }

    pub fn gfxFenceCancel(self: *const Context, fence: *const abi.GfxFence) i32 {
        return self.base.gfxFenceCancel(fence);
    }

    pub fn gfxFenceRelease(self: *const Context, fence: *const abi.GfxFence) i32 {
        return self.base.gfxFenceRelease(fence);
    }

    pub fn queues(self: *const Context) @import("gfx_queue.zig").Context {
        return .{ .base = self.base };
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
    pub fn supportsDisplayPresentationStats(self: *const Context) bool {
        return self.base.supportsDisplayPresentationStats();
    }
    pub fn supportsDisplayCursor(self: *const Context) bool {
        return self.base.supportsDisplayCursor();
    }
    pub fn displayCursorInfo(self: *const Context, out: *abi.DisplayCursorInfo) i32 {
        return self.base.displayCursorInfo(out);
    }
    pub fn displayCursorSubmit(self: *const Context, input: *const abi.DisplayCursorRequest, out: *abi.DisplayCursorStatus) i32 {
        return self.base.displayCursorSubmit(input, out);
    }
    pub fn displayCursorStatus(self: *const Context, out: *abi.DisplayCursorStatus) i32 {
        return self.base.displayCursorStatus(out);
    }
    pub fn displayPresentationStats(self: *const Context, head_id: u32, out: *abi.DisplayPresentationStats) i32 {
        return self.base.displayPresentationStats(head_id, out);
    }
    pub fn supportsDisplayPresentationInfo(self: *const Context) bool { return self.hasFn("display_presentation_info"); }
    pub fn displayPresentationInfo(self: *const Context, head_id: u32, out: *abi.DisplayPresentationInfo) i32 {
        return self.base.displayPresentationInfo(head_id, out);
    }
    pub fn displayOutputTarget(self: *const Context, adapter_id: u32, head_id: u32, out: *abi.GfxOutputTarget) i32 {
        return self.base.displayOutputTarget(adapter_id, head_id, out);
    }
    pub fn displayOutputPresentationInfo(self: *const Context, target: *const abi.GfxOutputTarget, out: *abi.DisplayPresentationInfo) i32 {
        return self.base.displayOutputPresentationInfo(target, out);
    }
    pub fn displayOutputPresentationFeedback(self: *const Context, target: *const abi.GfxOutputTarget, source: *const abi.GfxFence, out: *abi.DisplayPresentationStats) i32 {
        return self.base.displayOutputPresentationFeedback(target, source, out);
    }
    pub fn displayPresentationFeedback(self: *const Context, head_id: u32, source: *const abi.GfxFence, out: *abi.DisplayPresentationStats) i32 {
        return self.base.displayPresentationFeedback(head_id, source, out);
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
    const header: abi.R4XStartR4Draw = .{};
    // The fixed historical revision is the append-only admission minimum;
    // resolveGroupTable accepts newer initialized tables.
    try std.testing.expect(header.abi_version >= abi.r4xstart_r4draw_version);
    try std.testing.expectEqual(abi.r4xstart_r4draw_magic, header.magic);
    try std.testing.expectEqual(@as(u32, @sizeOf(abi.R4XStartR4Draw)), header.size);
    try std.testing.expectEqual(abi.remote_frame_format_xrgb32, (abi.RemoteFrameInfo{}).format);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4draw.h", c_header);
}
