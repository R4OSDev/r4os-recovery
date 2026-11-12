# Plattformgruppe R4DESK

<!-- R4OS-APIREF:BEGIN R4DESK (generiert von ApiContractGen aus ApiContract.json - NICHT von Hand editieren) -->
## Tabellen-Referenz R4DESK (generiert)

Kernel-Gruppentabelle `R4XStartR4Desk` v21, 632 Bytes, 76 Funktionsfelder und 77 Slots insgesamt.
Signatur-Wahrheit: `abi.R4DeskFns` (Feldname == Tabellenfeld).
Ein Feld ist nutzbar, wenn `hasFn("feld")` es als vorhanden meldet.

| Slot | Offset | Zustand | Tabellenfeld | Signatur |
| ---: | ---: | --- | --- | --- |
| 0 | 16 | function | `read_key` | `*const fn () callconv(.c) u8` |
| 1 | 24 | function | `mouse_state` | `*const fn (*Mouse) callconv(.c) void` |
| 2 | 32 | function | `mouse_show` | `*const fn () callconv(.c) void` |
| 3 | 40 | function | `mouse_hide` | `*const fn () callconv(.c) void` |
| 4 | 48 | function | `keyboard_layout_current` | `*const fn (*KeyboardLayoutInfo) callconv(.c) i32` |
| 5 | 56 | function | `keyboard_layout_at` | `*const fn (u32, *KeyboardLayoutInfo) callconv(.c) i32` |
| 6 | 64 | function | `keyboard_layout_set` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 7 | 72 | function | `program_set_window` | `*const fn (u32, i32) callconv(.c) i32` |
| 8 | 80 | function | `program_set_console_host` | `*const fn (u32, u32) callconv(.c) i32` |
| 9 | 88 | function | `program_request_host_launch` | `*const fn ([*:0]const u8, [*:0]const u8, u32) callconv(.c) i32` |
| 10 | 96 | function | `program_take_host_launch` | `*const fn (u32, *ProgramHostLaunchRequest) callconv(.c) i32` |
| 11 | 104 | function | `program_window_id` | `*const fn () callconv(.c) i32` |
| 12 | 112 | function | `gui_window_info` | `*const fn (*GuiWindowInfo) callconv(.c) i32` |
| 13 | 120 | function | `gui_set_window_info` | `*const fn (u32, *const GuiWindowInfo) callconv(.c) i32` |
| 14 | 128 | function | `gui_poll_event` | `*const fn (*GuiEvent) callconv(.c) i32` |
| 15 | 136 | function | `gui_push_event` | `*const fn (u32, *const GuiEvent) callconv(.c) i32` |
| 16 | 144 | function | `gui_set_text` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 17 | 152 | function | `gui_text` | `*const fn (u32, [*]u8, u32) callconv(.c) i32` |
| 18 | 160 | function | `gui_revision` | `*const fn (u32) callconv(.c) u32` |
| 19 | 168 | function | `gui_command` | `*const fn (u32, u32, *GuiCommand) callconv(.c) i32` |
| 20 | 176 | function | `gui_set_title` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 21 | 184 | function | `gui_title` | `*const fn (u32, [*]u8, u32) callconv(.c) i32` |
| 22 | 192 | function | `gui_set_min_size` | `*const fn (i32, i32) callconv(.c) i32` |
| 23 | 200 | function | `gui_min_size` | `*const fn (u32, *GuiSize) callconv(.c) i32` |
| 24 | 208 | function | `console_output` | `*const fn (u32, [*]u8, u32) callconv(.c) i32` |
| 25 | 216 | function | `console_revision` | `*const fn (u32) callconv(.c) u32` |
| 26 | 224 | function | `console_state` | `*const fn (u32, *ConsoleState) callconv(.c) i32` |
| 27 | 232 | function | `console_set_metrics` | `*const fn (u32, u32, u32) callconv(.c) i32` |
| 28 | 240 | function | `console_push_key` | `*const fn (u32, u8) callconv(.c) i32` |
| 29 | 248 | function | `console_write` | `*const fn (u32, [*]const u8, u32) callconv(.c) i32` |
| 30 | 256 | function | `console_read` | `*const fn ([*]u8, u32) callconv(.c) i32` |
| 31 | 264 | function | `clipboard_write` | `*const fn ([*]const u8, u32) callconv(.c) i32` |
| 32 | 272 | function | `clipboard_read` | `*const fn ([*]u8, u32) callconv(.c) i32` |
| 33 | 280 | function | `clipboard_revision` | `*const fn () callconv(.c) u32` |
| 34 | 288 | function | `clipboard_info` | `*const fn (*ClipboardInfo) callconv(.c) i32` |
| 35 | 296 | function | `clipboard_clear` | `*const fn () callconv(.c) i32` |
| 36 | 304 | function | `read_key_codepoint` | `*const fn () callconv(.c) u32` |
| 37 | 312 | reserved | `reserved1` | - |
| 38 | 320 | function | `remote_frame_info` | `*const fn (*RemoteFrameInfo) callconv(.c) i32` |
| 39 | 328 | function | `remote_frame_read` | `*const fn (u32, [*]u32, u32, *RemoteFrameInfo) callconv(.c) i32` |
| 40 | 336 | function | `remote_frame_wait` | `*const fn (u32, u64, *RemoteFrameInfo) callconv(.c) i32` |
| 41 | 344 | function | `remote_frame_publish` | `*const fn (*const RemoteFrameInfo, [*]const u32, u32) callconv(.c) i32` |
| 42 | 352 | function | `remote_input_push` | `*const fn (*const RemoteInputEvent) callconv(.c) i32` |
| 43 | 360 | function | `remote_input_poll` | `*const fn (*RemoteInputEvent) callconv(.c) i32` |
| 44 | 368 | function | `remote_input_status` | `*const fn (*RemoteInputStatus) callconv(.c) i32` |
| 45 | 376 | function | `desktop_activity_wait` | `*const fn (u64, u64, *u64) callconv(.c) i32` |
| 46 | 384 | function | `remote_frame_map` | `*const fn (*RemoteFrameMapInfo) callconv(.c) i32` |
| 47 | 392 | function | `program_current_console_host` | `*const fn () callconv(.c) u32` |
| 48 | 400 | function | `program_request_desktop` | `*const fn () callconv(.c) i32` |
| 49 | 408 | function | `program_spawn_with_console_host` | `*const fn ([*:0]const u8, [*:0]const u8, u32, u32) callconv(.c) i32` |
| 50 | 416 | function | `program_spawn_with_console_host_handle` | `*const fn ([*:0]const u8, [*:0]const u8, u32, u32, *ProgramProcessHandle) callconv(.c) i32` |
| 51 | 424 | function | `program_set_window_handle` | `*const fn (*const ProgramProcessHandle, i32) callconv(.c) i32` |
| 52 | 432 | function | `console_push_input` | `*const fn (u32, [*]const u8, u32) callconv(.c) i32` |
| 53 | 440 | function | `remote_frame_acquire` | `*const fn () callconv(.c) i32` |
| 54 | 448 | function | `remote_frame_release` | `*const fn () callconv(.c) i32` |
| 55 | 456 | function | `remote_frame_consumers` | `*const fn () callconv(.c) u32` |
| 56 | 464 | function | `remote_frame_publish_regions` | `*const fn (*const RemoteFrameInfo, [*]const u32, u32, [*]const DisplayDamageRect, u32) callconv(.c) i32` |
| 57 | 472 | function | `console_input_wait` | `*const fn (u64, u64, *u64) callconv(.c) i32` |
| 58 | 480 | function | `physical_key_poll` | `*const fn (*PhysicalKeyEvent) callconv(.c) i32` |
| 59 | 488 | function | `mouse_motion` | `*const fn (*MouseMotion) callconv(.c) i32` |
| 60 | 496 | function | `remote_frame_snapshot_acquire` | `*const fn (u32, *RemoteFrameInfo, *RemoteFrameLease) callconv(.c) i32` |
| 61 | 504 | function | `remote_frame_snapshot_release` | `*const fn (*const RemoteFrameLease) callconv(.c) i32` |
| 62 | 512 | function | `remote_frame_source_reset` | `*const fn () callconv(.c) i32` |
| 63 | 520 | function | `remote_frame_capture_stats` | `*const fn (*RemoteFrameCaptureStats) callconv(.c) i32` |
| 64 | 528 | function | `desktop_activity_notify` | `*const fn () callconv(.c) i32` |
| 65 | 536 | function | `console_read_events` | `*const fn ([*]ConsoleInputEvent, u32) callconv(.c) i32` |
| 66 | 544 | function | `console_push_events` | `*const fn (*const ProgramProcessHandle, [*]const ConsoleInputEvent, u32) callconv(.c) i32` |
| 67 | 552 | function | `console_text_info` | `*const fn (*const ProgramProcessHandle, *ConsoleTextInfo) callconv(.c) i32` |
| 68 | 560 | function | `console_set_encoding` | `*const fn (*const ProgramProcessHandle, u32) callconv(.c) i32` |
| 69 | 568 | function | `gui_activity_wait` | `*const fn (u64, u64, u32, *u64) callconv(.c) i32` |
| 70 | 576 | function | `gui_activity_notify` | `*const fn (u32) callconv(.c) i32` |
| 71 | 584 | function | `gui_pointer_capture_info` | `*const fn (?*const GuiPointerCaptureHandle, *GuiPointerCaptureInfo) callconv(.c) i32` |
| 72 | 592 | function | `gui_pointer_capture_acquire` | `*const fn (*const GuiPointerWindowIdentity, u32, *GuiPointerCaptureHandle) callconv(.c) i32` |
| 73 | 600 | function | `gui_pointer_capture_release` | `*const fn (*const GuiPointerCaptureHandle) callconv(.c) i32` |
| 74 | 608 | function | `gui_pointer_capture_host` | `*const fn (*const GuiPointerHostRequest, *GuiPointerCaptureInfo) callconv(.c) i32` |
| 75 | 616 | function | `gui_host_input` | `*const fn (*const GuiHostInputRequest, *GuiPointerWindowIdentity) callconv(.c) i32` |
| 76 | 624 | function | `gui_window_appearance` | `*const fn (*const GuiPointerWindowIdentity, *GuiWindowAppearance) callconv(.c) i32` |
<!-- R4OS-APIREF:END R4DESK -->