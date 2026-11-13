# Plattformgruppe R4DRAW

<!-- R4OS-APIREF:BEGIN R4DRAW (generiert von ApiContractGen aus ApiContract.json - NICHT von Hand editieren) -->
## Tabellen-Referenz R4DRAW (generiert)

Kernel-Gruppentabelle `R4XStartR4Draw2` v2, 920 Bytes, 113 Funktionsfelder und 113 Slots insgesamt.
Signatur-Wahrheit: `abi.R4DrawFns2` (Feldname == Tabellenfeld).
Ein Feld ist nutzbar, wenn `hasFn("feld")` es als vorhanden meldet.

| Slot | Offset | Zustand | Tabellenfeld | Signatur |
| ---: | ---: | --- | --- | --- |
| 0 | 16 | function | `screen_width` | `*const fn () callconv(.c) u32` |
| 1 | 24 | function | `screen_height` | `*const fn () callconv(.c) u32` |
| 2 | 32 | function | `clear` | `*const fn (u32) callconv(.c) void` |
| 3 | 40 | function | `rect` | `*const fn (i32, i32, u32, u32, u32) callconv(.c) void` |
| 4 | 48 | function | `text` | `*const fn (i32, i32, [*:0]const u8, u32, u32) callconv(.c) void` |
| 5 | 56 | function | `display_revision` | `*const fn () callconv(.c) u32` |
| 6 | 64 | function | `display_begin_frame` | `*const fn () callconv(.c) i32` |
| 7 | 72 | function | `display_begin_frame_rect` | `*const fn (i32, i32, u32, u32) callconv(.c) i32` |
| 8 | 80 | function | `display_present` | `*const fn () callconv(.c) i32` |
| 9 | 88 | function | `display_blit_xrgb32` | `*const fn (i32, i32, u32, u32, [*]const u32, u32) callconv(.c) i32` |
| 10 | 96 | function | `gui_clear` | `*const fn (u32) callconv(.c) i32` |
| 11 | 104 | function | `gui_rect` | `*const fn (i32, i32, u32, u32, u32) callconv(.c) i32` |
| 12 | 112 | function | `gui_draw_text` | `*const fn (i32, i32, [*:0]const u8, u32, u32) callconv(.c) i32` |
| 13 | 120 | function | `gui_draw_text_ex` | `*const fn (i32, i32, [*:0]const u8, u32, u32, u32, u32) callconv(.c) i32` |
| 14 | 128 | function | `gui_blit` | `*const fn (i32, i32, u32, u32, u32, [*]const u32, u32) callconv(.c) i32` |
| 15 | 136 | function | `gui_raster_read` | `*const fn (u32, u32, [*]u32, u32) callconv(.c) i32` |
| 16 | 144 | function | `gui_present` | `*const fn () callconv(.c) i32` |
| 17 | 152 | function | `font_count` | `*const fn () callconv(.c) u32` |
| 18 | 160 | function | `font_info` | `*const fn (u32, *GuiFontInfo) callconv(.c) i32` |
| 19 | 168 | function | `font_measure` | `*const fn (u32, [*:0]const u8, *GuiTextMetrics) callconv(.c) i32` |
| 20 | 176 | function | `gui_set_font` | `*const fn (u32) callconv(.c) i32` |
| 21 | 184 | function | `gui_font` | `*const fn (u32, *GuiFontInfo) callconv(.c) i32` |
| 22 | 192 | function | `text_font` | `*const fn (u32, i32, i32, [*:0]const u8, u32, u32) callconv(.c) void` |
| 23 | 200 | function | `font_reload` | `*const fn () callconv(.c) i32` |
| 24 | 208 | function | `font_glyph_row` | `*const fn (u32, u32, u32) callconv(.c) u64` |
| 25 | 216 | function | `gui_blend_alpha8` | `*const fn (i32, i32, u32, u32, u32, u32, [*]const u8, u32) callconv(.c) i32` |
| 26 | 224 | function | `gui_frame_begin` | `*const fn () callconv(.c) i32` |
| 27 | 232 | function | `gui_frame_append` | `*const fn (?[*]const GuiFrameCommand, u64, ?[*]const u8, u64) callconv(.c) i32` |
| 28 | 240 | function | `gui_frame_commit` | `*const fn () callconv(.c) i32` |
| 29 | 248 | function | `gui_frame_cancel` | `*const fn () callconv(.c) i32` |
| 30 | 256 | function | `gui_frame_info` | `*const fn (?*const ProgramProcessHandle, *GuiFrameInfo) callconv(.c) i32` |
| 31 | 264 | function | `gui_frame_read` | `*const fn (*const ProgramProcessHandle, u64, ?[*]GuiFrameCommand, u64, ?[*]u8, u64, *GuiFrameInfo) callconv(.c) i32` |
| 32 | 272 | function | `display_blit_xrgb32_stride` | `*const fn (i32, i32, u32, u32, [*]const u32, u32, u32) callconv(.c) i32` |
| 33 | 280 | function | `display_present_regions` | `*const fn (*const DisplayPresentRequest, [*]const u32, u32, [*]const DisplayDamageRect, u32, *DisplayPresentResult) callconv(.c) i32` |
| 34 | 288 | function | `display_present_capabilities` | `*const fn (*DisplayPresentCapabilities) callconv(.c) i32` |
| 35 | 296 | function | `display_present_completion` | `*const fn (u64, *DisplayPresentCompletion) callconv(.c) i32` |
| 36 | 304 | function | `gui_frame_begin_damage` | `*const fn ([*]const DisplayDamageRect, u32) callconv(.c) i32` |
| 37 | 312 | function | `gui_frame_generation_info` | `*const fn (*const ProgramProcessHandle, u64, *GuiFrameGenerationInfo) callconv(.c) i32` |
| 38 | 320 | function | `gui_frame_generation_read` | `*const fn (*const ProgramProcessHandle, u64, ?[*]GuiFrameCommand, u64, ?[*]u8, u64, ?[*]DisplayDamageRect, u32, *GuiFrameGenerationInfo) callconv(.c) i32` |
| 39 | 328 | function | `font_glyph_bitmap` | `*const fn (u32, u32, *GuiGlyphBitmap) callconv(.c) i32` |
| 40 | 336 | function | `font_revision` | `*const fn () callconv(.c) u32` |
| 41 | 344 | function | `gui_frame_begin_replace` | `*const fn ([*]const DisplayDamageRect, u32) callconv(.c) i32` |
| 42 | 352 | function | `gui_frame_stream_info` | `*const fn (*const ProgramProcessHandle, *GuiFrameStreamInfo) callconv(.c) i32` |
| 43 | 360 | function | `gui_shared_raster_create` | `*const fn (*const GuiSharedRasterCreateInfo, *GuiSharedRasterHandle) callconv(.c) i32` |
| 44 | 368 | function | `gui_shared_raster_destroy` | `*const fn (*const GuiSharedRasterHandle) callconv(.c) i32` |
| 45 | 376 | function | `gui_shared_raster_map_write` | `*const fn (*const GuiSharedRasterHandle, *GuiSharedRasterWriteMap) callconv(.c) i32` |
| 46 | 384 | function | `gui_shared_raster_publish` | `*const fn (*const GuiSharedRasterWriteMap, *u64) callconv(.c) i32` |
| 47 | 392 | function | `gui_shared_raster_acquire` | `*const fn (*const ProgramProcessHandle, u64, *const GuiSharedRasterHandle, u64, *GuiSharedRasterMap) callconv(.c) i32` |
| 48 | 400 | function | `gui_shared_raster_release` | `*const fn (*const GuiSharedRasterLease) callconv(.c) i32` |
| 49 | 408 | function | `gfx_buffer_create` | `*const fn (*const GfxBufferDescriptor, *GfxBufferReference) callconv(.c) i32` |
| 50 | 416 | function | `gfx_buffer_describe` | `*const fn (*const GfxBufferHandle, *GfxBufferDescriptor) callconv(.c) i32` |
| 51 | 424 | function | `gfx_buffer_import` | `*const fn (*const GfxBufferHandle, *GfxBufferReference) callconv(.c) i32` |
| 52 | 432 | function | `gfx_buffer_release` | `*const fn (*const GfxBufferHandle) callconv(.c) i32` |
| 53 | 440 | function | `gfx_buffer_map` | `*const fn (*const GfxBufferHandle, u32, u64, u64, *GfxBufferMap) callconv(.c) i32` |
| 54 | 448 | function | `gfx_buffer_unmap` | `*const fn (*const GfxBufferHandle) callconv(.c) i32` |
| 55 | 456 | function | `gfx_buffer_export_raster` | `*const fn (*const GuiSharedRasterLease, *GfxBufferReference) callconv(.c) i32` |
| 56 | 464 | function | `gfx_buffer_stats` | `*const fn (*GfxBufferStats) callconv(.c) i32` |
| 57 | 472 | function | `gfx_queue_open` | `*const fn (*const GfxQueueConfig, *GfxQueueHandle) callconv(.c) i32` |
| 58 | 480 | function | `gfx_queue_close` | `*const fn (*const GfxQueueHandle) callconv(.c) i32` |
| 59 | 488 | function | `gfx_queue_submit` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *GfxFenceStatus) callconv(.c) i32` |
| 60 | 496 | function | `gfx_fence_query` | `*const fn (*const GfxFence, *GfxFenceStatus) callconv(.c) i32` |
| 61 | 504 | function | `gfx_fence_wait` | `*const fn (*const GfxFence, u64, u32, *GfxFenceStatus) callconv(.c) i32` |
| 62 | 512 | function | `gfx_fence_cancel` | `*const fn (*const GfxFence) callconv(.c) i32` |
| 63 | 520 | function | `gfx_fence_release` | `*const fn (*const GfxFence) callconv(.c) i32` |
| 64 | 528 | function | `gfx_queue_backend` | `*const fn (u32, *GfxBackendBinding) callconv(.c) i32` |
| 65 | 536 | function | `gfx_output_revision` | `*const fn (*GfxDisplayRevision) callconv(.c) i32` |
| 66 | 544 | function | `gfx_output_info` | `*const fn (u32, *GfxOutputInfo) callconv(.c) i32` |
| 67 | 552 | function | `gfx_output_mode` | `*const fn (*const GfxOutputId, u32, *GfxOutputMode) callconv(.c) i32` |
| 68 | 560 | function | `gfx_output_edid` | `*const fn (*const GfxOutputId, u32, *GfxEdidBlock) callconv(.c) i32` |
| 69 | 568 | function | `gfx_atomic_test` | `*const fn (*const GfxAtomicState, *GfxAtomicResult) callconv(.c) i32` |
| 70 | 576 | function | `gfx_atomic_commit` | `*const fn (*const GfxAtomicState, *GfxAtomicResult) callconv(.c) i32` |
| 71 | 584 | function | `gfx_atomic_submit` | `*const fn (*const GfxAtomicState, u32, *GfxModeStatus) callconv(.c) i32` |
| 72 | 592 | function | `gfx_atomic_status` | `*const fn (u64, *GfxModeStatus) callconv(.c) i32` |
| 73 | 600 | function | `gfx_atomic_resolve` | `*const fn (u64, u32, *GfxModeStatus) callconv(.c) i32` |
| 74 | 608 | function | `display_presentation_stats` | `*const fn (u32, *DisplayPresentationStats) callconv(.c) i32` |
| 75 | 616 | function | `display_cursor_info` | `*const fn (*DisplayCursorInfo) callconv(.c) i32` |
| 76 | 624 | function | `display_cursor_submit` | `*const fn (*const DisplayCursorRequest, *DisplayCursorStatus) callconv(.c) i32` |
| 77 | 632 | function | `display_cursor_status` | `*const fn (*DisplayCursorStatus) callconv(.c) i32` |
| 78 | 640 | function | `gfx_queue_backend_info` | `*const fn (u32, *GfxBackendInfo) callconv(.c) i32` |
| 79 | 648 | function | `gfx_native_start` | `*const fn (*const GfxNativeAllocation, *GfxNativeStatus) callconv(.c) i32` |
| 80 | 656 | function | `gfx_native_query` | `*const fn (*const GfxBufferHandle, *GfxNativeStatus) callconv(.c) i32` |
| 81 | 664 | function | `gfx_native_receive` | `*const fn (*const GfxBufferHandle, *GfxBufferReference) callconv(.c) i32` |
| 82 | 672 | function | `gfx_native_close` | `*const fn (*const GfxBufferHandle) callconv(.c) i32` |
| 83 | 680 | function | `gfx_native_wait` | `*const fn (*const GfxBufferHandle, u64, *GfxNativeStatus) callconv(.c) i32` |
| 84 | 688 | function | `gfx_queue_submit_render_list` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *const GfxRenderList, *GfxFenceStatus) callconv(.c) i32` |
| 85 | 696 | function | `display_presentation_info` | `*const fn (u32, *DisplayPresentationInfo) callconv(.c) i32` |
| 86 | 704 | function | `display_presentation_feedback` | `*const fn (u32, *const GfxFence, *DisplayPresentationStats) callconv(.c) i32` |
| 87 | 712 | function | `display_output_target` | `*const fn (u32, u32, *GfxOutputTarget) callconv(.c) i32` |
| 88 | 720 | function | `gfx_queue_submit_output` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *const GfxOutputTarget, *GfxFenceStatus) callconv(.c) i32` |
| 89 | 728 | function | `display_output_presentation_info` | `*const fn (*const GfxOutputTarget, *DisplayPresentationInfo) callconv(.c) i32` |
| 90 | 736 | function | `display_output_presentation_feedback` | `*const fn (*const GfxOutputTarget, *const GfxFence, *DisplayPresentationStats) callconv(.c) i32` |
| 91 | 744 | function | `gfx_queue_submit_render_grid_list` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *const GfxRenderGridList, *GfxFenceStatus) callconv(.c) i32` |
| 92 | 752 | function | `gfx_output_color` | `*const fn (*const GfxOutputId, *GfxOutputColorState) callconv(.c) i32` |
| 93 | 760 | function | `gfx_queue_submit_render_color_list` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *const GfxRenderColorList, *GfxFenceStatus) callconv(.c) i32` |
| 94 | 768 | function | `gfx_atomic_test_color` | `*const fn (*const GfxModeColorRequest, *GfxAtomicResult) callconv(.c) i32` |
| 95 | 776 | function | `gfx_atomic_submit_color` | `*const fn (*const GfxModeColorRequest, u32, *GfxModeStatus) callconv(.c) i32` |
| 96 | 784 | function | `gfx_output_refresh` | `*const fn (*const GfxOutputTarget, *GfxOutputRefresh) callconv(.c) i32` |
| 97 | 792 | function | `gfx_refresh_request` | `*const fn (*const GfxRefreshRequest, *GfxRefreshRequest) callconv(.c) i32` |
| 98 | 800 | function | `gfx_memory_budget` | `*const fn (*const GfxDeviceBudgetRequest, *GfxDeviceBudgetState) callconv(.c) i32` |
| 99 | 808 | function | `gfx_telemetry` | `*const fn (*const GfxTelemetryRequest, *GfxTelemetryState) callconv(.c) i32` |
| 100 | 816 | function | `gfx_output_power` | `*const fn (*const GfxOutputId, *GfxOutputPower) callconv(.c) i32` |
| 101 | 824 | function | `gfx_power_request` | `*const fn (*const GfxPowerRequest, *GfxPowerRequest) callconv(.c) i32` |
| 102 | 832 | function | `gfx_virtual_start` | `*const fn (*const GfxVirtualRequest, *GfxVirtualStatus) callconv(.c) i32` |
| 103 | 840 | function | `gfx_virtual_query` | `*const fn (*const GfxBufferHandle, *GfxVirtualStatus) callconv(.c) i32` |
| 104 | 848 | function | `gfx_virtual_close` | `*const fn (*const GfxBufferHandle, u32) callconv(.c) i32` |
| 105 | 856 | function | `gfx_virtual_wait` | `*const fn (*const GfxBufferHandle, u32, u64, *GfxVirtualStatus) callconv(.c) i32` |
| 106 | 864 | function | `gfx_buffer_map_persistent` | `*const fn (*const GfxBufferHandle, u32, u64, u64, *GfxBufferMap) callconv(.c) i32` |
| 107 | 872 | function | `gfx_queue_backend_properties` | `*const fn (*const GfxBackendBinding, *GfxBackendProperties) callconv(.c) i32` |
| 108 | 880 | function | `gfx_queue_submit_native` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *const GfxNativeSubmission, *GfxFenceStatus) callconv(.c) i32` |
| 109 | 888 | function | `gfx_queue_submit_render_color_grid_list` | `*const fn (*const GfxQueueHandle, *const GfxSubmission, *const GfxRenderColorGridList, *GfxFenceStatus) callconv(.c) i32` |
| 110 | 896 | function | `gfx_output_brightness` | `*const fn (*const GfxOutputId, *GfxOutputBrightness) callconv(.c) i32` |
| 111 | 904 | function | `gfx_brightness_request` | `*const fn (*const GfxBrightnessRequest, *GfxBrightnessRequest) callconv(.c) i32` |
| 112 | 912 | function | `font_prefix_metrics2` | `*const fn (u32, ?[*]const u8, u32, ?[*]FontAdvance2, u32, *FontAdvanceInfo2) callconv(.c) i32` |
<!-- R4OS-APIREF:END R4DRAW -->