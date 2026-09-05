# Plattformgruppe R4AUDIO

<!-- R4OS-APIREF:BEGIN R4AUDIO (generiert von ApiContractGen aus ApiContract.json - NICHT von Hand editieren) -->
## Tabellen-Referenz R4AUDIO (generiert)

Kernel-Gruppentabelle `R4XStartR4Audio` v1, 184 Bytes, 19 Funktionsfelder und 21 Slots insgesamt.
Signatur-Wahrheit: `abi.R4AudioFns` (Feldname == Tabellenfeld).
Ein Feld ist nutzbar, wenn `hasFn("feld")` es als vorhanden meldet.

| Slot | Offset | Zustand | Tabellenfeld | Signatur |
| ---: | ---: | --- | --- | --- |
| 0 | 16 | function | `audio_open_stream` | `*const fn (u32, u16, u16) callconv(.c) i32` |
| 1 | 24 | function | `audio_write` | `*const fn (u32, [*]const u8, u32) callconv(.c) i32` |
| 2 | 32 | function | `audio_close` | `*const fn (u32) callconv(.c) i32` |
| 3 | 40 | function | `audio_set_volume` | `*const fn (u32, u32) callconv(.c) i32` |
| 4 | 48 | function | `sid_acquire` | `*const fn () callconv(.c) i32` |
| 5 | 56 | function | `sid_write_register` | `*const fn (u32, u8, u8) callconv(.c) i32` |
| 6 | 64 | function | `sid_release` | `*const fn (u32) callconv(.c) i32` |
| 7 | 72 | function | `sid_load_data` | `*const fn (u32, u16, [*]const u8, u32) callconv(.c) i32` |
| 8 | 80 | function | `sid_init` | `*const fn (u32, u16, u16) callconv(.c) i32` |
| 9 | 88 | function | `sid_play_frame` | `*const fn (u32, u16, u16) callconv(.c) i32` |
| 10 | 96 | function | `sid_stop` | `*const fn (u32) callconv(.c) i32` |
| 11 | 104 | function | `sid_model_name` | `*const fn () callconv(.c) [*:0]const u8` |
| 12 | 112 | function | `midi_open_synth` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 13 | 120 | function | `midi_send` | `*const fn (u32, u8, u8, u8, u8) callconv(.c) i32` |
| 14 | 128 | function | `midi_close` | `*const fn (u32) callconv(.c) i32` |
| 15 | 136 | function | `opl3_write_register` | `*const fn (u8, u8, u8) callconv(.c) i32` |
| 16 | 144 | function | `opl3_reset` | `*const fn () callconv(.c) i32` |
| 17 | 152 | function | `opl3_render_block` | `*const fn () callconv(.c) i32` |
| 18 | 160 | function | `opl3_stop` | `*const fn () callconv(.c) i32` |
| 19 | 168 | reserved | `reserved0` | - |
| 20 | 176 | reserved | `reserved1` | - |
<!-- R4OS-APIREF:END R4AUDIO -->