# Öffentliche API-Payloads

Diese Datei wird deterministisch aus `API/ApiContract.json` erzeugt. Manuelle Änderungen sind nicht zulässig.

Kernel-, Zig- und C-Program-ABI, R4L-Identitaeten, Contractlayouts, API-Referenzen und Conformance-Fixtures werden produktiv aus diesem Schema erzeugt; handgeschriebene Dateien bleiben nur Fassaden oder erklaerende Texte.

- Schema: v11, Baseline `standalone-contract-0.64.11`
- Reachability: 153 von 153 Typen aufgelöst oder explizit klassifiziert
- Zentrale SDK-only-Wurzeln: 0; Runtime-R4Ls besitzen libraryeigene Vertraege
- Operationen: 0; Fehlerdomänen: 63; Konstanten: 1434; Limits: 109

## App-Profile

| Profil | R4X-Klasse | Pflichtgruppen | Optionale Gruppen |
|---|---|---|---|
| `console` | `console` | `R4SYS` | `R4DESK`, `R4DRAW`, `R4NET`, `R4AUDIO`, `R4DEV` |
| `desktop` | `gui` | `R4SYS`, `R4DESK`, `R4DRAW` | `R4NET`, `R4AUDIO`, `R4DEV` |
| `service` | `service` | `R4SYS` | `R4DESK`, `R4DRAW`, `R4NET`, `R4AUDIO`, `R4DEV` |

## Layoutvertrag

| Typ | Klasse | Repräsentation | Schema | Kernel | Zig | C-Vertrag |
|---|---|---|---:|---:|---:|---:|
| `BootInfoSummary` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `BootInfoMemoryEntry` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `Mouse` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `ProgramStatus` | fixed_layout | extern_struct | 8/4 | 8/4 | 8/4 | 8/4 |
| `ProgramInstanceInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `ThreadEntryFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `ProgramThreadInfo` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `ProgramIoInfo` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `ProgramMemorySummary` | fixed_layout | extern_struct | 360/8 | 360/8 | 360/8 | 360/8 |
| `ProgramMemoryPressureSnapshot` | extensible | extern_struct | 200/8 | 200/8 | 200/8 | 200/8 |
| `ProgramMemoryReclaimProbe` | extensible | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `ProgramMemoryBackingStoreProbe` | extensible | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `ProgramMemoryBackingStoreSlotProbe` | extensible | extern_struct | 232/8 | 232/8 | 232/8 | 232/8 |
| `ProgramMemoryPagerGateProbe` | extensible | extern_struct | 248/8 | 248/8 | 248/8 | 248/8 |
| `ProgramMemoryPageIoProbe` | extensible | extern_struct | 304/8 | 304/8 | 304/8 | 304/8 |
| `ProgramMemoryVmPageStateProbe` | extensible | extern_struct | 288/8 | 288/8 | 288/8 | 288/8 |
| `ProgramPerformanceSummary` | extensible | extern_struct | 6352/8 | 6352/8 | 6352/8 | 6352/8 |
| `ProgramTaskPerformanceInfo` | fixed_layout | extern_struct | 304/8 | 304/8 | 304/8 | 304/8 |
| `ProgramStoragePerformanceInfo` | fixed_layout | extern_struct | 440/8 | 440/8 | 440/8 | 440/8 |
| `ProgramBootPhasePerformanceInfo` | fixed_layout | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `ProgramBootPhaseClockInfo` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `ProgramBootPerformanceInfo` | fixed_layout | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `ProgramIrqTimingInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `ProgramMemoryBlockInfo` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `ProgramVmReserveProbe` | fixed_layout | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `ProgramVmRegionInfo` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `PagingSummary` | fixed_layout | extern_struct | 152/8 | 152/8 | 152/8 | 152/8 |
| `DisplayDamageRect` | fixed_layout | extern_struct | 16/4 | 16/4 | 16/4 | 16/4 |
| `DisplayPresentCapabilities` | fixed_layout | extern_struct | 80/4 | 80/4 | 80/4 | 80/4 |
| `DisplayPresentCompletion` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `DisplayPresentRequest` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `DisplayPresentResult` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `DisplaySummary` | fixed_layout | extern_struct | 200/8 | 200/8 | 200/8 | 200/8 |
| `GuiWindowInfo` | fixed_layout | extern_struct | 40/4 | 40/4 | 40/4 | 40/4 |
| `GuiSize` | fixed_layout | extern_struct | 8/4 | 8/4 | 8/4 | 8/4 |
| `GuiEvent` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `PhysicalKeyEvent` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GuiCommand` | fixed_layout | extern_struct | 120/4 | 120/4 | 120/4 | 120/4 |
| `GuiFrameCommand` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `GuiPathSegment` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `GuiShapeResource` | fixed_layout | extern_struct | 160/4 | 160/4 | 160/4 | 160/4 |
| `GuiFrameGenerationInfo` | extensible | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `GuiFrameInfo` | extensible | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `GuiIndexed8Resource` | fixed_layout | extern_struct | 64/4 | 64/4 | 64/4 | 64/4 |
| `GuiFontInfo` | fixed_layout | extern_struct | 316/4 | 316/4 | 316/4 | 316/4 |
| `GuiTextMetrics` | fixed_layout | extern_struct | 24/4 | 24/4 | 24/4 | 24/4 |
| `ClipboardInfo` | fixed_layout | extern_struct | 16/4 | 16/4 | 16/4 | 16/4 |
| `RemoteFrameInfo` | fixed_layout | extern_struct | 80/4 | 80/4 | 80/4 | 80/4 |
| `RemoteFrameMapInfo` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `RemoteInputEvent` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `RemoteInputStatus` | fixed_layout | extern_struct | 64/4 | 64/4 | 64/4 | 64/4 |
| `ProgramHostLaunchRequest` | fixed_layout | extern_struct | 264/4 | 264/4 | 264/4 | 264/4 |
| `ConsoleState` | fixed_layout | extern_struct | 64/4 | 64/4 | 64/4 | 64/4 |
| `KernelVersion` | extensible | extern_struct | 24/4 | 24/4 | 24/4 | 24/4 |
| `TimeState` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `MonotonicClockInfo` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `KeyboardLayoutInfo` | fixed_layout | extern_struct | 36/4 | 36/4 | 36/4 | 36/4 |
| `DriveInfo` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `FileInfo` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `BootLogInfo` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `DeviceInventorySummary` | fixed_layout | extern_struct | 20/4 | 20/4 | 20/4 | 20/4 |
| `DeviceInventoryRecord` | fixed_layout | extern_struct | 224/2 | 224/2 | 224/2 | 224/2 |
| `HardwareSummary` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `ProtocolStatus` | fixed_layout | extern_struct | 80/4 | 80/4 | 80/4 | 80/4 |
| `ProtocolBuffer` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `SerialLinkStatus` | fixed_layout | extern_struct | 736/8 | 736/8 | 736/8 | 736/8 |
| `SerialLinkMessage` | fixed_layout | extern_struct | 260/2 | 260/2 | 260/2 | 260/2 |
| `RegistryBatchOperation` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `RegistryBatchResult` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `RegistrySnapshotCursor` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `RegistrySnapshotEntry` | fixed_layout | extern_struct | 80/4 | 80/4 | 80/4 | 80/4 |
| `RegistrySnapshotPageInfo` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `RegistryKeyInfo` | fixed_layout | extern_struct | 72/4 | 72/4 | 72/4 | 72/4 |
| `RegistryValueInfo` | fixed_layout | extern_struct | 72/4 | 72/4 | 72/4 | 72/4 |
| `ServiceInfo` | fixed_layout | extern_struct | 216/8 | 216/8 | 216/8 | 216/8 |
| `ServiceDetail` | fixed_layout | extern_struct | 520/8 | 520/8 | 520/8 | 520/8 |
| `ServiceMessageHeader` | fixed_layout | extern_struct | 28/4 | 28/4 | 28/4 | 28/4 |
| `IpcSummary` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `IpcPerformanceSummary` | extensible | extern_struct | 240/8 | 240/8 | 240/8 | 240/8 |
| `IpcChannelInfo` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `TcpSummary` | fixed_layout | extern_struct | 160/8 | 160/8 | 160/8 | 160/8 |
| `TcpConnectionInfo` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `TcpAcceptResult` | fixed_layout | extern_struct | 8/4 | 8/4 | 8/4 | 8/4 |
| `NetIpv4Packet` | fixed_layout | extern_struct | 16/4 | 16/4 | 16/4 | 16/4 |
| `NetConfigSnapshot` | fixed_layout | extern_struct | 128/4 | 128/4 | 128/4 | 128/4 |
| `NetConfigRequest` | fixed_layout | extern_struct | 68/4 | 68/4 | 68/4 | 68/4 |
| `DhcpStatus` | fixed_layout | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `NetDetailProtocolRuntime` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `NetDetailAdapter` | fixed_layout | extern_struct | 312/8 | 312/8 | 312/8 | 312/8 |
| `NetDetailEthernet` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `NetDetailArp` | fixed_layout | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `NetDetailIpv4` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `NetDetailIcmp` | fixed_layout | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `NetDetailUdp` | fixed_layout | extern_struct | 104/8 | 104/8 | 104/8 | 104/8 |
| `NetDetailDns` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `NetDetailSnapshot` | fixed_layout | extern_struct | 2752/8 | 2752/8 | 2752/8 | 2752/8 |
| `NetDiagTiming` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `NetDiagBackpressure` | fixed_layout | extern_struct | 296/8 | 296/8 | 296/8 | 296/8 |
| `NetDiagCleanup` | fixed_layout | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `NetDiagDriver` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `NetDiagErrors` | fixed_layout | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `NetDiagR4p` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `NetDiagResult` | fixed_layout | extern_struct | 760/8 | 760/8 | 760/8 | 760/8 |
| `R4TextView` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `R4Duration` | fixed_layout | extern_struct | 8/8 | 8/8 | 8/8 | 8/8 |
| `R4MonotonicInstant` | fixed_layout | extern_struct | 8/8 | 8/8 | 8/8 | 8/8 |
| `R4Deadline` | fixed_layout | extern_struct | 8/8 | 8/8 | 8/8 | 8/8 |
| `R4UtcTime` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `R4Timeout` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `R4StopFlag` | fixed_layout | extern_struct | 4/4 | 4/4 | 4/4 | 4/4 |
| `ProgramInstanceStorageSummary` | extensible | extern_struct | 336/8 | 336/8 | 336/8 | 336/8 |
| `ProgramInstanceStorageSelfTestResult` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `ProgramProcessHandle` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `ProgramProcessCompletion` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `ProgramRegistrySummary` | extensible | extern_struct | 160/8 | 160/8 | 160/8 | 160/8 |
| `ProgramRegistrySummaryV2` | extensible | extern_struct | 224/8 | 224/8 | 224/8 | 224/8 |
| `ProgramRegistrySelfTestResult` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `ProgramRegistrySelfTestResultV2` | extensible | extern_struct | 136/8 | 136/8 | 136/8 | 136/8 |
| `ProgramJoinHandle` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `ProgramInventoryCursor` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `ProgramInventoryPageInfo` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `ProgramInstanceSnapshot` | extensible | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `ProgramTaskSnapshot` | extensible | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `ProgramThreadSnapshot` | extensible | extern_struct | 136/8 | 136/8 | 136/8 | 136/8 |
| `ProgramInventorySummary` | extensible | extern_struct | 160/8 | 160/8 | 160/8 | 160/8 |
| `ProgramDriverWorkPerformanceMetrics` | fixed_layout | extern_struct | 640/8 | 640/8 | 640/8 | 640/8 |
| `ProgramDriverWorkPerformanceInfo` | extensible | extern_struct | 928/8 | 928/8 | 928/8 | 928/8 |
| `ProgramPciInventoryPerformanceInfo` | extensible | extern_struct | 280/8 | 280/8 | 280/8 | 280/8 |
| `ProgramInputPerformanceInfo` | extensible | extern_struct | 408/8 | 408/8 | 408/8 | 408/8 |
| `ServiceDeadlineFooter` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `AudioServiceMasterRequest` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `AudioServiceMasterState` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `TrayServiceRequest` | fixed_layout | extern_struct | 1184/8 | 1184/8 | 1184/8 | 1184/8 |
| `TrayEvent` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `TrayServiceResponse` | fixed_layout | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `TrayDesktopExchange` | fixed_layout | extern_struct | 1344/8 | 1344/8 | 1344/8 | 1344/8 |
| `GuiGlyphBitmap` | fixed_layout | extern_struct | 344/8 | 344/8 | 344/8 | 344/8 |
| `GuiXrgb32Resource` | fixed_layout | extern_struct | 64/4 | 64/4 | 64/4 | 64/4 |
| `GuiFrameStreamInfo` | extensible | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `GuiSharedRasterHandle` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `GuiSharedRasterCreateInfo` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GuiSharedRasterWriteMap` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GuiSharedRasterLease` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GuiSharedRasterMap` | fixed_layout | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `GuiSharedRasterResource` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `TcpPerformanceInfo` | extensible | extern_struct | 208/8 | 208/8 | 208/8 | 208/8 |
| `StorageDeviceRef` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `StorageVolumeRef` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `StorageTarget` | fixed_layout | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `StorageInventory` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `StorageDeviceInfo` | fixed_layout | extern_struct | 288/8 | 288/8 | 288/8 | 288/8 |
| `StoragePartitionInfo` | fixed_layout | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `StorageVolumeInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |

## Typdetails

### `BootInfoSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `flags` | 0 | 4 | 4 | `u32` | - |
| `memory_map_count` | 4 | 4 | 4 | `u32` | - |
| `max_memory_map_entries` | 8 | 4 | 4 | `u32` | - |
| `hhdm_offset` | 16 | 8 | 8 | `u64` | - |
| `framebuffer_address` | 24 | 8 | 8 | `u64` | - |
| `framebuffer_width` | 32 | 8 | 8 | `u64` | - |
| `framebuffer_height` | 40 | 8 | 8 | `u64` | - |
| `framebuffer_pitch` | 48 | 8 | 8 | `u64` | - |
| `framebuffer_bpp` | 56 | 2 | 2 | `u16` | - |
| `framebuffer_memory_model` | 58 | 1 | 1 | `u8` | - |
| `framebuffer_red_mask_size` | 59 | 1 | 1 | `u8` | - |
| `framebuffer_red_mask_shift` | 60 | 1 | 1 | `u8` | - |
| `framebuffer_green_mask_size` | 61 | 1 | 1 | `u8` | - |
| `framebuffer_green_mask_shift` | 62 | 1 | 1 | `u8` | - |
| `framebuffer_blue_mask_size` | 63 | 1 | 1 | `u8` | - |
| `framebuffer_blue_mask_shift` | 64 | 1 | 1 | `u8` | - |
| `edid_size` | 72 | 8 | 8 | `u64` | - |
| `edid_address` | 80 | 8 | 8 | `u64` | - |
| `rsdp_address` | 88 | 8 | 8 | `u64` | - |
| `bootloader_name` | 96 | 32 | 1 | `[32]u8` | - |

### `BootInfoMemoryEntry`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `base` | 0 | 8 | 8 | `u64` | - |
| `length` | 8 | 8 | 8 | `u64` | - |
| `kind` | 16 | 1 | 1 | `u8` | - |
| `reserved` | 17 | 7 | 1 | `[7]u8` | - |

### `Mouse`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `x` | 0 | 4 | 4 | `i32` | - |
| `y` | 4 | 4 | 4 | `i32` | - |
| `dx` | 8 | 4 | 4 | `i32` | - |
| `dy` | 12 | 4 | 4 | `i32` | - |
| `wheel` | 16 | 4 | 4 | `i32` | - |
| `buttons` | 20 | 1 | 1 | `u8` | - |
| `present` | 21 | 1 | 1 | `u8` | - |
| `reserved` | 22 | 2 | 2 | `u16` | - |
| `packets` | 24 | 8 | 8 | `u64` | - |

### `ProgramStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `foreground_running` | 0 | 1 | 1 | `u8` | - |
| `shell_running` | 1 | 1 | 1 | `u8` | - |
| `display_used` | 2 | 1 | 1 | `u8` | - |
| `instance_count` | 3 | 1 | 1 | `u8` | - |
| `last_exit_code` | 4 | 4 | 4 | `i32` | - |

### `ProgramInstanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `task_id` | 4 | 4 | 4 | `u32` | - |
| `role` | 8 | 1 | 1 | `u8` | - |
| `app_class` | 9 | 1 | 1 | `u8` | - |
| `state` | 10 | 1 | 1 | `u8` | - |
| `flags` | 11 | 1 | 1 | `u8` | - |
| `exit_code` | 12 | 4 | 4 | `i32` | - |
| `window_id` | 16 | 4 | 4 | `i32` | - |
| `memory_profile` | 20 | 1 | 1 | `u8` | - |
| `reserved0` | 21 | 3 | 1 | `[3]u8` | - |
| `memory_reserved_limit` | 24 | 8 | 8 | `u64` | - |
| `memory_committed_limit` | 32 | 8 | 8 | `u64` | - |
| `memory_resident_limit` | 40 | 8 | 8 | `u64` | - |
| `memory_reserved_bytes` | 48 | 8 | 8 | `u64` | - |
| `memory_committed_bytes` | 56 | 8 | 8 | `u64` | - |
| `memory_resident_bytes` | 64 | 8 | 8 | `u64` | - |
| `memory_peak_resident_bytes` | 72 | 8 | 8 | `u64` | - |
| `stack_reserved_bytes` | 80 | 8 | 8 | `u64` | - |
| `stack_committed_bytes` | 88 | 8 | 8 | `u64` | - |
| `memory_tag` | 96 | 16 | 1 | `[16]u8` | - |

### `ThreadEntryFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `ProgramThreadInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `thread_id` | 8 | 4 | 4 | `u32` | - |
| `instance_id` | 12 | 4 | 4 | `u32` | - |
| `task_id` | 16 | 4 | 4 | `u32` | - |
| `state` | 20 | 4 | 4 | `u32` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `exit_code` | 28 | 4 | 4 | `i32` | - |
| `stack_base` | 32 | 8 | 8 | `u64` | - |
| `stack_reserved_bytes` | 40 | 8 | 8 | `u64` | - |
| `stack_committed_bytes` | 48 | 8 | 8 | `u64` | - |
| `stack_guard_base` | 56 | 8 | 8 | `u64` | - |
| `created_tick` | 64 | 8 | 8 | `u64` | - |
| `finished_tick` | 72 | 8 | 8 | `u64` | - |
| `join_count` | 80 | 4 | 4 | `u32` | - |
| `reserved0` | 84 | 4 | 4 | `u32` | - |

### `ProgramIoInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `request_id` | 8 | 4 | 4 | `u32` | - |
| `kind` | 12 | 4 | 4 | `u32` | - |
| `state` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `status` | 24 | 4 | 4 | `i32` | - |
| `result` | 28 | 4 | 4 | `i32` | - |
| `requested_bytes` | 32 | 8 | 8 | `u64` | - |
| `processed_bytes` | 40 | 8 | 8 | `u64` | - |
| `submitted_tick` | 48 | 8 | 8 | `u64` | - |
| `completed_tick` | 56 | 8 | 8 | `u64` | - |
| `owner_instance` | 64 | 4 | 4 | `u32` | - |
| `task_id` | 68 | 4 | 4 | `u32` | - |
| `reserved0` | 72 | 8 | 8 | `u64` | - |

### `ProgramMemorySummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 360 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `total_slots_used` | 0 | 8 | 8 | `u64` | - |
| `active_blocks` | 8 | 8 | 8 | `u64` | - |
| `released_blocks` | 16 | 8 | 8 | `u64` | - |
| `error_blocks` | 24 | 8 | 8 | `u64` | - |
| `physical_bytes` | 32 | 8 | 8 | `u64` | - |
| `virtual_bytes` | 40 | 8 | 8 | `u64` | - |
| `reserved_bytes` | 48 | 8 | 8 | `u64` | - |
| `committed_bytes` | 56 | 8 | 8 | `u64` | - |
| `free_physical_bytes` | 64 | 8 | 8 | `u64` | - |
| `largest_free_phys_base` | 72 | 8 | 8 | `u64` | - |
| `largest_free_phys_len` | 80 | 8 | 8 | `u64` | - |
| `largest_free_virtual_base` | 88 | 8 | 8 | `u64` | - |
| `largest_free_virtual_len` | 96 | 8 | 8 | `u64` | - |
| `app_system_reserve_frames` | 104 | 8 | 8 | `u64` | - |
| `app_available_frames` | 112 | 8 | 8 | `u64` | - |
| `by_kind` | 120 | 112 | 8 | `[14]u64` | - |
| `by_owner` | 232 | 64 | 8 | `[8]u64` | - |
| `by_status` | 296 | 56 | 8 | `[7]u64` | - |
| `overflow` | 352 | 4 | 4 | `u32` | - |
| `reserved0` | 356 | 4 | 4 | `u32` | - |

### `ProgramMemoryPressureSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 200 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `pressure_level` | 12 | 4 | 4 | `u32` | - |
| `oom_policy_flags` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `total_physical_bytes` | 24 | 8 | 8 | `u64` | - |
| `free_physical_bytes` | 32 | 8 | 8 | `u64` | - |
| `used_physical_bytes` | 40 | 8 | 8 | `u64` | - |
| `largest_free_physical_bytes` | 48 | 8 | 8 | `u64` | - |
| `app_system_reserve_bytes` | 56 | 8 | 8 | `u64` | - |
| `app_available_bytes` | 64 | 8 | 8 | `u64` | - |
| `virtual_reserved_bytes` | 72 | 8 | 8 | `u64` | - |
| `virtual_committed_bytes` | 80 | 8 | 8 | `u64` | - |
| `virtual_resident_bytes` | 88 | 8 | 8 | `u64` | - |
| `largest_free_virtual_bytes` | 96 | 8 | 8 | `u64` | - |
| `committed_nonresident_bytes` | 104 | 8 | 8 | `u64` | - |
| `commit_budget_bytes` | 112 | 8 | 8 | `u64` | - |
| `commit_headroom_bytes` | 120 | 8 | 8 | `u64` | - |
| `reclaimable_bytes` | 128 | 8 | 8 | `u64` | - |
| `dirty_bytes` | 136 | 8 | 8 | `u64` | - |
| `non_reclaimable_bytes` | 144 | 8 | 8 | `u64` | - |
| `fault_count` | 152 | 8 | 8 | `u64` | - |
| `failed_faults` | 160 | 8 | 8 | `u64` | - |
| `reserved1` | 168 | 32 | 8 | `[4]u64` | - |

### `ProgramMemoryReclaimProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `reason` | 8 | 4 | 4 | `u32` | - |
| `requested_frames` | 12 | 4 | 4 | `u32` | - |
| `returned_frames` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `returned_bytes` | 24 | 8 | 8 | `u64` | - |
| `dirty_drains` | 32 | 8 | 8 | `u64` | - |
| `failed_drains` | 40 | 8 | 8 | `u64` | - |
| `before_free_frames` | 48 | 8 | 8 | `u64` | - |
| `after_free_frames` | 56 | 8 | 8 | `u64` | - |
| `elapsed_ticks` | 64 | 8 | 8 | `u64` | - |
| `total_attempts` | 72 | 8 | 8 | `u64` | - |
| `total_successes` | 80 | 8 | 8 | `u64` | - |
| `total_failures` | 88 | 8 | 8 | `u64` | - |
| `fs_returned_frames` | 96 | 4 | 4 | `u32` | - |
| `vm_returned_frames` | 100 | 4 | 4 | `u32` | - |
| `vm_page_outs_lo` | 104 | 4 | 4 | `u32` | - |
| `vm_failures_lo` | 108 | 4 | 4 | `u32` | - |
| `fs_returned_bytes` | 112 | 8 | 8 | `u64` | - |
| `vm_returned_bytes` | 120 | 8 | 8 | `u64` | - |
| `vm_page_outs` | 128 | 8 | 8 | `u64` | - |
| `vm_failures` | 136 | 8 | 8 | `u64` | - |
| `reserved1` | 144 | 32 | 8 | `[4]u64` | - |

### `ProgramMemoryBackingStoreProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `blockers` | 16 | 4 | 4 | `u32` | - |
| `pager_enabled` | 20 | 4 | 4 | `u32` | - |
| `anonymous_paging_enabled` | 24 | 4 | 4 | `u32` | - |
| `cluster_bytes` | 28 | 4 | 4 | `u32` | - |
| `requested_bytes` | 32 | 8 | 8 | `u64` | - |
| `available_bytes` | 40 | 8 | 8 | `u64` | - |
| `file_size` | 48 | 8 | 8 | `u64` | - |
| `first_cluster` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |
| `total_probes` | 64 | 8 | 8 | `u64` | - |
| `total_ready` | 72 | 8 | 8 | `u64` | - |
| `total_failures` | 80 | 8 | 8 | `u64` | - |
| `reserved1` | 88 | 32 | 8 | `[4]u64` | - |

### `ProgramMemoryBackingStoreSlotProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 232 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `operation` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `blockers` | 20 | 4 | 4 | `u32` | - |
| `slot_bytes` | 24 | 4 | 4 | `u32` | - |
| `max_ranges` | 28 | 4 | 4 | `u32` | - |
| `pager_enabled` | 32 | 4 | 4 | `u32` | - |
| `eviction_enabled` | 36 | 4 | 4 | `u32` | - |
| `page_in_enabled` | 40 | 4 | 4 | `u32` | - |
| `page_out_enabled` | 44 | 4 | 4 | `u32` | - |
| `reservation_id` | 48 | 4 | 4 | `u32` | - |
| `owner_kind` | 52 | 4 | 4 | `u32` | - |
| `owner_id` | 56 | 4 | 4 | `u32` | - |
| `region_id` | 60 | 4 | 4 | `u32` | - |
| `range_count` | 64 | 4 | 4 | `u32` | - |
| `reserved0` | 68 | 4 | 4 | `u32` | - |
| `capacity_slots` | 72 | 8 | 8 | `u64` | - |
| `requested_slots` | 80 | 8 | 8 | `u64` | - |
| `reserved_slots` | 88 | 8 | 8 | `u64` | - |
| `free_slots` | 96 | 8 | 8 | `u64` | - |
| `valid_slots` | 104 | 8 | 8 | `u64` | - |
| `dirty_slots` | 112 | 8 | 8 | `u64` | - |
| `error_slots` | 120 | 8 | 8 | `u64` | - |
| `first_slot` | 128 | 8 | 8 | `u64` | - |
| `slot_count` | 136 | 8 | 8 | `u64` | - |
| `generation` | 144 | 8 | 8 | `u64` | - |
| `total_probes` | 152 | 8 | 8 | `u64` | - |
| `total_reserves` | 160 | 8 | 8 | `u64` | - |
| `total_releases` | 168 | 8 | 8 | `u64` | - |
| `total_error_marks` | 176 | 8 | 8 | `u64` | - |
| `total_recoveries` | 184 | 8 | 8 | `u64` | - |
| `total_failures` | 192 | 8 | 8 | `u64` | - |
| `lifecycle_cleanup_count` | 200 | 8 | 8 | `u64` | - |
| `lifecycle_released_ranges` | 208 | 8 | 8 | `u64` | - |
| `lifecycle_released_slots` | 216 | 8 | 8 | `u64` | - |
| `reserved1` | 224 | 8 | 8 | `[1]u64` | - |

### `ProgramMemoryPagerGateProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 248 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `blockers` | 16 | 4 | 4 | `u32` | - |
| `region_id` | 20 | 4 | 4 | `u32` | - |
| `owner_id` | 24 | 4 | 4 | `u32` | - |
| `slot_bytes` | 28 | 4 | 4 | `u32` | - |
| `requested_bytes` | 32 | 8 | 8 | `u64` | - |
| `committed_bytes` | 40 | 8 | 8 | `u64` | - |
| `resident_bytes` | 48 | 8 | 8 | `u64` | - |
| `nonresident_bytes` | 56 | 8 | 8 | `u64` | - |
| `requested_slots` | 64 | 8 | 8 | `u64` | - |
| `prepared_slots` | 72 | 8 | 8 | `u64` | - |
| `capacity_slots` | 80 | 8 | 8 | `u64` | - |
| `free_before_slots` | 88 | 8 | 8 | `u64` | - |
| `free_after_slots` | 96 | 8 | 8 | `u64` | - |
| `reserved_before_slots` | 104 | 8 | 8 | `u64` | - |
| `reserved_after_slots` | 112 | 8 | 8 | `u64` | - |
| `slot_reservation_id` | 120 | 4 | 4 | `u32` | - |
| `rollback_completed` | 124 | 4 | 4 | `u32` | - |
| `commit_gate_enabled` | 128 | 4 | 4 | `u32` | - |
| `fault_gate_enabled` | 132 | 4 | 4 | `u32` | - |
| `pager_enabled` | 136 | 4 | 4 | `u32` | - |
| `eviction_enabled` | 140 | 4 | 4 | `u32` | - |
| `page_in_enabled` | 144 | 4 | 4 | `u32` | - |
| `page_out_enabled` | 148 | 4 | 4 | `u32` | - |
| `reserved0` | 152 | 8 | 4 | `[2]u32` | - |
| `slot_generation` | 160 | 8 | 8 | `u64` | - |
| `fault_count` | 168 | 8 | 8 | `u64` | - |
| `failed_faults` | 176 | 8 | 8 | `u64` | - |
| `total_probes` | 184 | 8 | 8 | `u64` | - |
| `total_ready` | 192 | 8 | 8 | `u64` | - |
| `total_rollbacks` | 200 | 8 | 8 | `u64` | - |
| `total_failures` | 208 | 8 | 8 | `u64` | - |
| `reserved1` | 216 | 32 | 8 | `[4]u64` | - |

### `ProgramMemoryPageIoProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 304 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `operation` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `blockers` | 20 | 4 | 4 | `u32` | - |
| `region_id` | 24 | 4 | 4 | `u32` | - |
| `reservation_id` | 28 | 4 | 4 | `u32` | - |
| `owner_kind` | 32 | 4 | 4 | `u32` | - |
| `owner_id` | 36 | 4 | 4 | `u32` | - |
| `slot_bytes` | 40 | 4 | 4 | `u32` | - |
| `io_bytes` | 44 | 4 | 4 | `u32` | - |
| `io_status` | 48 | 4 | 4 | `i32` | - |
| `page_count_lo` | 52 | 4 | 4 | `u32` | - |
| `region_offset` | 56 | 8 | 8 | `u64` | - |
| `committed_bytes` | 64 | 8 | 8 | `u64` | - |
| `resident_bytes` | 72 | 8 | 8 | `u64` | - |
| `slot_index` | 80 | 8 | 8 | `u64` | - |
| `page_count` | 88 | 8 | 8 | `u64` | - |
| `transfer_bytes` | 96 | 8 | 8 | `u64` | - |
| `expected_generation` | 104 | 8 | 8 | `u64` | - |
| `backing_slot` | 112 | 8 | 8 | `u64` | - |
| `backing_offset` | 120 | 8 | 8 | `u64` | - |
| `capacity_slots` | 128 | 8 | 8 | `u64` | - |
| `reserved_slots` | 136 | 8 | 8 | `u64` | - |
| `valid_slots` | 144 | 8 | 8 | `u64` | - |
| `dirty_slots` | 152 | 8 | 8 | `u64` | - |
| `error_slots` | 160 | 8 | 8 | `u64` | - |
| `pager_enabled` | 168 | 4 | 4 | `u32` | - |
| `eviction_enabled` | 172 | 4 | 4 | `u32` | - |
| `page_in_enabled` | 176 | 4 | 4 | `u32` | - |
| `page_out_enabled` | 180 | 4 | 4 | `u32` | - |
| `slot_generation` | 184 | 8 | 8 | `u64` | - |
| `total_prepares` | 192 | 8 | 8 | `u64` | - |
| `total_page_outs` | 200 | 8 | 8 | `u64` | - |
| `total_page_ins` | 208 | 8 | 8 | `u64` | - |
| `total_failures` | 216 | 8 | 8 | `u64` | - |
| `retry_limit` | 224 | 4 | 4 | `u32` | - |
| `backoff_ticks` | 228 | 4 | 4 | `u32` | - |
| `reserved1` | 232 | 8 | 4 | `[2]u32` | - |
| `total_retry_attempts` | 240 | 8 | 8 | `u64` | - |
| `total_retryable_failures` | 248 | 8 | 8 | `u64` | - |
| `total_permanent_failures` | 256 | 8 | 8 | `u64` | - |
| `total_retry_limit_hits` | 264 | 8 | 8 | `u64` | - |
| `total_failed_page_outs` | 272 | 8 | 8 | `u64` | - |
| `total_failed_page_ins` | 280 | 8 | 8 | `u64` | - |
| `total_data_preserved_pages` | 288 | 8 | 8 | `u64` | - |
| `total_data_lost_pages` | 296 | 8 | 8 | `u64` | - |

### `ProgramMemoryVmPageStateProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 288 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `operation` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `blockers` | 20 | 4 | 4 | `u32` | - |
| `region_id` | 24 | 4 | 4 | `u32` | - |
| `page_size` | 28 | 4 | 4 | `u32` | - |
| `max_spans` | 32 | 4 | 4 | `u32` | - |
| `span_count` | 36 | 4 | 4 | `u32` | - |
| `slot_reservation_id` | 40 | 4 | 4 | `u32` | - |
| `page_count_lo` | 44 | 4 | 4 | `u32` | - |
| `region_offset` | 48 | 8 | 8 | `u64` | - |
| `page_count` | 56 | 8 | 8 | `u64` | - |
| `committed_pages` | 64 | 8 | 8 | `u64` | - |
| `resident_pages` | 72 | 8 | 8 | `u64` | - |
| `nonresident_pages` | 80 | 8 | 8 | `u64` | - |
| `dirty_pages` | 88 | 8 | 8 | `u64` | - |
| `clean_pages` | 96 | 8 | 8 | `u64` | - |
| `pinned_pages` | 104 | 8 | 8 | `u64` | - |
| `busy_pages` | 112 | 8 | 8 | `u64` | - |
| `error_pages` | 120 | 8 | 8 | `u64` | - |
| `slot_bound_pages` | 128 | 8 | 8 | `u64` | - |
| `slot_index` | 136 | 8 | 8 | `u64` | - |
| `slot_generation` | 144 | 8 | 8 | `u64` | - |
| `total_transitions` | 152 | 8 | 8 | `u64` | - |
| `dirty_marks` | 160 | 8 | 8 | `u64` | - |
| `clean_marks` | 168 | 8 | 8 | `u64` | - |
| `slot_binds` | 176 | 8 | 8 | `u64` | - |
| `slot_clears` | 184 | 8 | 8 | `u64` | - |
| `pinned_marks` | 192 | 8 | 8 | `u64` | - |
| `pinned_clears` | 200 | 8 | 8 | `u64` | - |
| `busy_marks` | 208 | 8 | 8 | `u64` | - |
| `busy_clears` | 216 | 8 | 8 | `u64` | - |
| `error_marks` | 224 | 8 | 8 | `u64` | - |
| `error_clears` | 232 | 8 | 8 | `u64` | - |
| `table_full_failures` | 240 | 8 | 8 | `u64` | - |
| `cleanup_pages` | 248 | 8 | 8 | `u64` | - |
| `reserved1` | 256 | 32 | 8 | `[4]u64` | - |

### `ProgramPerformanceSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 15 / 6352 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `missing_flags` | 12 | 4 | 4 | `u32` | - |
| `ticks` | 16 | 8 | 8 | `u64` | - |
| `tick_hz` | 24 | 4 | 4 | `u32` | - |
| `current_task_index` | 28 | 4 | 4 | `u32` | - |
| `task_max_count` | 32 | 4 | 4 | `u32` | - |
| `task_count` | 36 | 4 | 4 | `u32` | - |
| `task_ready` | 40 | 4 | 4 | `u32` | - |
| `task_running` | 44 | 4 | 4 | `u32` | - |
| `task_blocked` | 48 | 4 | 4 | `u32` | - |
| `task_dead` | 52 | 4 | 4 | `u32` | - |
| `task_workers` | 56 | 4 | 4 | `u32` | - |
| `scheduler_yields` | 64 | 8 | 8 | `u64` | - |
| `scheduler_sleeps` | 72 | 8 | 8 | `u64` | - |
| `scheduler_wakes` | 80 | 8 | 8 | `u64` | - |
| `scheduler_idle_waits` | 88 | 8 | 8 | `u64` | - |
| `boot_phase_count` | 96 | 4 | 4 | `u32` | - |
| `boot_current_phase` | 100 | 4 | 4 | `u32` | - |
| `reserved0` | 104 | 4 | 4 | `u32` | - |
| `boot_transition_count` | 112 | 8 | 8 | `u64` | - |
| `boot_total_ticks` | 120 | 8 | 8 | `u64` | - |
| `storage_device_count` | 128 | 4 | 4 | `u32` | - |
| `storage_queue_depth_total` | 132 | 4 | 4 | `u32` | - |
| `storage_queue_used_total` | 136 | 4 | 4 | `u32` | - |
| `storage_queue_high_water_total` | 140 | 4 | 4 | `u32` | - |
| `storage_busy_devices` | 144 | 4 | 4 | `u32` | - |
| `storage_failed_devices` | 148 | 4 | 4 | `u32` | - |
| `storage_read_ops` | 152 | 8 | 8 | `u64` | - |
| `storage_read_sectors` | 160 | 8 | 8 | `u64` | - |
| `storage_read_failures` | 168 | 8 | 8 | `u64` | - |
| `storage_write_ops` | 176 | 8 | 8 | `u64` | - |
| `storage_write_sectors` | 184 | 8 | 8 | `u64` | - |
| `storage_write_failures` | 192 | 8 | 8 | `u64` | - |
| `storage_flush_ops` | 200 | 8 | 8 | `u64` | - |
| `storage_flush_failures` | 208 | 8 | 8 | `u64` | - |
| `storage_busy_rejections` | 216 | 8 | 8 | `u64` | - |
| `storage_timeout_failures` | 224 | 8 | 8 | `u64` | - |
| `storage_completions` | 232 | 8 | 8 | `u64` | - |
| `storage_backend_recoveries` | 240 | 8 | 8 | `u64` | - |
| `storage_backend_recovery_failures` | 248 | 8 | 8 | `u64` | - |
| `storage_queued_requests` | 256 | 8 | 8 | `u64` | - |
| `storage_dequeued_requests` | 264 | 8 | 8 | `u64` | - |
| `storage_queue_full_waits` | 272 | 8 | 8 | `u64` | - |
| `storage_queue_full_rejections` | 280 | 8 | 8 | `u64` | - |
| `storage_completion_waits` | 288 | 8 | 8 | `u64` | - |
| `storage_completion_timeouts` | 296 | 8 | 8 | `u64` | - |
| `storage_completion_total_ticks` | 304 | 8 | 8 | `u64` | - |
| `storage_completion_max_ticks` | 312 | 8 | 8 | `u64` | - |
| `storage_completion_last_ticks` | 320 | 8 | 8 | `u64` | - |
| `fs_requests` | 328 | 8 | 8 | `u64` | - |
| `fs_completed` | 336 | 8 | 8 | `u64` | - |
| `fs_failed` | 344 | 8 | 8 | `u64` | - |
| `fs_read_requests` | 352 | 8 | 8 | `u64` | - |
| `fs_write_requests` | 360 | 8 | 8 | `u64` | - |
| `fs_metadata_requests` | 368 | 8 | 8 | `u64` | - |
| `fs_stream_requests` | 376 | 8 | 8 | `u64` | - |
| `fs_lock_acquires` | 384 | 8 | 8 | `u64` | - |
| `fs_lock_contention_waits` | 392 | 8 | 8 | `u64` | - |
| `fs_lock_timeouts` | 400 | 8 | 8 | `u64` | - |
| `fs_boot_bypass` | 408 | 8 | 8 | `u64` | - |
| `fs_total_ticks` | 416 | 8 | 8 | `u64` | - |
| `fs_max_ticks` | 424 | 8 | 8 | `u64` | - |
| `fs_last_ticks` | 432 | 8 | 8 | `u64` | - |
| `fs_active_kind` | 440 | 4 | 4 | `u32` | - |
| `fs_last_kind` | 444 | 4 | 4 | `u32` | - |
| `fs_active_drive` | 448 | 4 | 4 | `u32` | - |
| `fs_last_drive` | 452 | 4 | 4 | `u32` | - |
| `service_max_count` | 456 | 4 | 4 | `u32` | - |
| `services_used` | 460 | 4 | 4 | `u32` | - |
| `services_running` | 464 | 4 | 4 | `u32` | - |
| `service_endpoints` | 468 | 4 | 4 | `u32` | - |
| `service_request_pending` | 472 | 4 | 4 | `u32` | - |
| `service_response_pending` | 476 | 4 | 4 | `u32` | - |
| `service_queue_depth_total` | 480 | 4 | 4 | `u32` | - |
| `service_queue_used_total` | 484 | 4 | 4 | `u32` | - |
| `service_queue_high_water_total` | 488 | 4 | 4 | `u32` | - |
| `service_active_workers` | 492 | 4 | 4 | `u32` | - |
| `service_max_active_workers` | 496 | 4 | 4 | `u32` | - |
| `service_open_handles` | 500 | 4 | 4 | `u32` | - |
| `service_requests` | 504 | 8 | 8 | `u64` | - |
| `service_responses` | 512 | 8 | 8 | `u64` | - |
| `service_drops` | 520 | 8 | 8 | `u64` | - |
| `service_busy_rejections` | 528 | 8 | 8 | `u64` | - |
| `service_timeouts` | 536 | 8 | 8 | `u64` | - |
| `service_cancellations` | 544 | 8 | 8 | `u64` | - |
| `service_completion_waits` | 552 | 8 | 8 | `u64` | - |
| `service_completion_timeouts` | 560 | 8 | 8 | `u64` | - |
| `tcp_max_connections` | 568 | 4 | 4 | `u32` | - |
| `tcp_active_connections` | 572 | 4 | 4 | `u32` | - |
| `tcp_active_listeners` | 576 | 4 | 4 | `u32` | - |
| `tcp_buffer_size` | 580 | 4 | 4 | `u32` | - |
| `tcp_data_tx` | 584 | 8 | 8 | `u64` | - |
| `tcp_data_rx` | 592 | 8 | 8 | `u64` | - |
| `tcp_retransmits` | 600 | 8 | 8 | `u64` | - |
| `tcp_rx_drops` | 608 | 8 | 8 | `u64` | - |
| `tcp_timeouts` | 616 | 8 | 8 | `u64` | - |
| `tcp_checksum_errors` | 624 | 8 | 8 | `u64` | - |
| `display_present_count` | 632 | 8 | 8 | `u64` | - |
| `display_present_bytes_total` | 640 | 8 | 8 | `u64` | - |
| `display_last_present_bytes` | 648 | 8 | 8 | `u64` | - |
| `display_full_present_count` | 656 | 8 | 8 | `u64` | - |
| `display_partial_present_count` | 664 | 8 | 8 | `u64` | - |
| `audio_open_streams` | 672 | 4 | 4 | `u32` | - |
| `audio_registered_backends` | 676 | 4 | 4 | `u32` | - |
| `audio_active_backends` | 680 | 4 | 4 | `u32` | - |
| `audio_registered_synths` | 684 | 4 | 4 | `u32` | - |
| `audio_stream_writes` | 688 | 8 | 8 | `u64` | - |
| `audio_backend_ok` | 696 | 8 | 8 | `u64` | - |
| `audio_backend_fail` | 704 | 8 | 8 | `u64` | - |
| `audio_backend_underruns` | 712 | 8 | 8 | `u64` | - |
| `audio_backend_errors` | 720 | 8 | 8 | `u64` | - |
| `wait_object_waits` | 728 | 8 | 8 | `u64` | - |
| `wait_object_wakes` | 736 | 8 | 8 | `u64` | - |
| `wait_object_timeouts` | 744 | 8 | 8 | `u64` | - |
| `wait_object_cancellations` | 752 | 8 | 8 | `u64` | - |
| `wait_queue_waits` | 760 | 8 | 8 | `u64` | - |
| `wait_queue_wake_one` | 768 | 8 | 8 | `u64` | - |
| `wait_queue_wake_all` | 776 | 8 | 8 | `u64` | - |
| `wait_queue_timeouts` | 784 | 8 | 8 | `u64` | - |
| `wait_queue_cancellations` | 792 | 8 | 8 | `u64` | - |
| `wait_queue_drops` | 800 | 8 | 8 | `u64` | - |
| `lock_acquires` | 808 | 8 | 8 | `u64` | - |
| `lock_releases` | 816 | 8 | 8 | `u64` | - |
| `lock_recursive_acquires` | 824 | 8 | 8 | `u64` | - |
| `lock_contention_waits` | 832 | 8 | 8 | `u64` | - |
| `lock_contention_timeouts` | 840 | 8 | 8 | `u64` | - |
| `lock_order_violations` | 848 | 8 | 8 | `u64` | - |
| `lock_sleep_checks` | 856 | 8 | 8 | `u64` | - |
| `lock_sleep_under_lock` | 864 | 8 | 8 | `u64` | - |
| `lock_sleep_under_no_sleep_lock` | 872 | 8 | 8 | `u64` | - |
| `lock_unlock_mismatches` | 880 | 8 | 8 | `u64` | - |
| `lock_held_slots_used` | 888 | 4 | 4 | `u32` | - |
| `lock_current_depth` | 892 | 4 | 4 | `u32` | - |
| `lock_max_depth` | 896 | 4 | 4 | `u32` | - |
| `lock_tracking_drops` | 900 | 4 | 4 | `u32` | - |
| `preemption_supported` | 904 | 4 | 4 | `u32` | - |
| `preemption_enabled` | 908 | 4 | 4 | `u32` | - |
| `preemption_test_mode` | 912 | 4 | 4 | `u32` | - |
| `preemption_gate_mask` | 916 | 4 | 4 | `u32` | - |
| `preempt_disable_depth` | 920 | 4 | 4 | `u32` | - |
| `preempt_disable_max_depth` | 924 | 4 | 4 | `u32` | - |
| `reserved1` | 928 | 4 | 4 | `u32` | - |
| `preempt_disable_underflows` | 936 | 8 | 8 | `u64` | - |
| `preempt_disable_calls` | 944 | 8 | 8 | `u64` | - |
| `preempt_enable_calls` | 952 | 8 | 8 | `u64` | - |
| `preemption_simulation_ticks` | 960 | 8 | 8 | `u64` | - |
| `fpu_lazy_saves` | 968 | 8 | 8 | `u64` | - |
| `fpu_lazy_skips` | 976 | 8 | 8 | `u64` | - |
| `preemption_eligible_ticks` | 984 | 8 | 8 | `u64` | - |
| `preemption_deferred_disabled` | 992 | 8 | 8 | `u64` | - |
| `preemption_deferred_critical` | 1000 | 8 | 8 | `u64` | - |
| `preemption_deferred_no_task` | 1008 | 8 | 8 | `u64` | - |
| `preemption_deferred_no_ready` | 1016 | 8 | 8 | `u64` | - |
| `preemption_switch_ticks` | 1024 | 8 | 8 | `u64` | - |
| `long_running_task_warnings` | 1032 | 8 | 8 | `u64` | - |
| `starvation_warnings` | 1040 | 8 | 8 | `u64` | - |
| `fpu_state_supported` | 1048 | 4 | 4 | `u32` | - |
| `fpu_state_enabled` | 1052 | 4 | 4 | `u32` | - |
| `fpu_state_backend` | 1056 | 4 | 4 | `u32` | - |
| `fpu_state_bytes` | 1060 | 4 | 4 | `u32` | - |
| `fpu_state_storage_bytes` | 1064 | 4 | 4 | `u32` | - |
| `fpu_task_state_count` | 1068 | 4 | 4 | `u32` | - |
| `fpu_avx_supported` | 1072 | 4 | 4 | `u32` | - |
| `fpu_avx_enabled` | 1076 | 4 | 4 | `u32` | - |
| `fpu_avx2_supported` | 1080 | 4 | 4 | `u32` | - |
| `fpu_avx2_enabled` | 1084 | 4 | 4 | `u32` | - |
| `fpu_simd_abi` | 1088 | 4 | 4 | `u32` | - |
| `fpu_xsave_required_bytes` | 1092 | 4 | 4 | `u32` | - |
| `fpu_xcr0_mask` | 1096 | 8 | 8 | `u64` | - |
| `fpu_save_count` | 1104 | 8 | 8 | `u64` | - |
| `fpu_restore_count` | 1112 | 8 | 8 | `u64` | - |
| `fpu_task_init_count` | 1120 | 8 | 8 | `u64` | - |
| `fpu_task_state_bytes` | 1128 | 8 | 8 | `u64` | - |
| `fs_cache_capacity` | 1136 | 4 | 4 | `u32` | - |
| `fs_cache_sector_bytes` | 1140 | 4 | 4 | `u32` | - |
| `fs_cache_entries_used` | 1144 | 4 | 4 | `u32` | - |
| `fs_cache_dirty_entries` | 1148 | 4 | 4 | `u32` | - |
| `fs_cache_reads` | 1152 | 8 | 8 | `u64` | - |
| `fs_cache_hits` | 1160 | 8 | 8 | `u64` | - |
| `fs_cache_misses` | 1168 | 8 | 8 | `u64` | - |
| `fs_cache_fills` | 1176 | 8 | 8 | `u64` | - |
| `fs_cache_evictions` | 1184 | 8 | 8 | `u64` | - |
| `fs_cache_invalidations` | 1192 | 8 | 8 | `u64` | - |
| `fs_cache_write_through_requests` | 1200 | 8 | 8 | `u64` | - |
| `fs_cache_write_through_updates` | 1208 | 8 | 8 | `u64` | - |
| `fs_cache_flushes` | 1216 | 8 | 8 | `u64` | - |
| `fs_cache_read_errors` | 1224 | 8 | 8 | `u64` | - |
| `fs_cache_write_errors` | 1232 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_waits` | 1240 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_errors` | 1248 | 8 | 8 | `u64` | - |
| `fs_cache_dirty_bytes` | 1256 | 8 | 8 | `u64` | - |
| `fs_cache_dirty_high_water_entries` | 1264 | 4 | 4 | `u32` | - |
| `fs_cache_writeback_queue_depth` | 1268 | 4 | 4 | `u32` | - |
| `fs_cache_writeback_queue_high_water` | 1272 | 4 | 4 | `u32` | - |
| `fs_cache_deferred_write_requests` | 1280 | 8 | 8 | `u64` | - |
| `fs_cache_dirty_sector_updates` | 1288 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_drains` | 1296 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_sectors` | 1304 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_pressure_drains` | 1312 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_flush_drains` | 1320 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_total_ticks` | 1328 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_max_ticks` | 1336 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_last_ticks` | 1344 | 8 | 8 | `u64` | - |
| `fs_cache_writeback_retries` | 1352 | 8 | 8 | `u64` | - |
| `fs_cache_clean_reclaimable_entries` | 1360 | 4 | 4 | `u32` | - |
| `fs_cache_dirty_non_reclaimable_entries` | 1364 | 4 | 4 | `u32` | - |
| `fs_cache_pagefile_ready` | 1368 | 4 | 4 | `u32` | - |
| `fs_cache_pagefile_blockers` | 1372 | 4 | 4 | `u32` | - |
| `fs_cache_clean_reclaimable_bytes` | 1376 | 8 | 8 | `u64` | - |
| `fs_cache_dirty_non_reclaimable_bytes` | 1384 | 8 | 8 | `u64` | - |
| `fs_cache_reclaim_scans` | 1392 | 8 | 8 | `u64` | - |
| `fs_cache_reclaim_clean_entries` | 1400 | 8 | 8 | `u64` | - |
| `fs_cache_reclaim_dirty_drains` | 1408 | 8 | 8 | `u64` | - |
| `fs_cache_reclaim_failed_drains` | 1416 | 8 | 8 | `u64` | - |
| `fs_cache_payload_frame_bytes` | 1424 | 4 | 4 | `u32` | - |
| `fs_cache_payload_frames` | 1428 | 4 | 4 | `u32` | - |
| `fs_cache_payload_bytes` | 1432 | 8 | 8 | `u64` | - |
| `fs_cache_pmm_reclaimable_bytes` | 1440 | 8 | 8 | `u64` | - |
| `fs_cache_pmm_dirty_bytes` | 1448 | 8 | 8 | `u64` | - |
| `fs_cache_payload_allocations` | 1456 | 8 | 8 | `u64` | - |
| `fs_cache_payload_allocation_failures` | 1464 | 8 | 8 | `u64` | - |
| `fs_cache_payload_releases` | 1472 | 8 | 8 | `u64` | - |
| `fs_cache_reclaim_returned_frames` | 1480 | 8 | 8 | `u64` | - |
| `fs_cache_reclaim_returned_bytes` | 1488 | 8 | 8 | `u64` | - |
| `global_reclaim_attempts` | 1496 | 8 | 8 | `u64` | - |
| `global_reclaim_successes` | 1504 | 8 | 8 | `u64` | - |
| `global_reclaim_failures` | 1512 | 8 | 8 | `u64` | - |
| `global_reclaim_requested_frames` | 1520 | 8 | 8 | `u64` | - |
| `global_reclaim_returned_frames` | 1528 | 8 | 8 | `u64` | - |
| `global_reclaim_returned_bytes` | 1536 | 8 | 8 | `u64` | - |
| `global_reclaim_dirty_drains` | 1544 | 8 | 8 | `u64` | - |
| `global_reclaim_failed_drains` | 1552 | 8 | 8 | `u64` | - |
| `global_reclaim_total_ticks` | 1560 | 8 | 8 | `u64` | - |
| `global_reclaim_max_ticks` | 1568 | 8 | 8 | `u64` | - |
| `global_reclaim_last_ticks` | 1576 | 8 | 8 | `u64` | - |
| `global_reclaim_last_reason` | 1584 | 4 | 4 | `u32` | - |
| `global_reclaim_last_requested_frames` | 1588 | 4 | 4 | `u32` | - |
| `global_reclaim_last_returned_frames` | 1592 | 4 | 4 | `u32` | - |
| `global_reclaim_reserved0` | 1596 | 4 | 4 | `u32` | - |
| `global_reclaim_fs_returned_frames` | 1600 | 8 | 8 | `u64` | - |
| `global_reclaim_fs_returned_bytes` | 1608 | 8 | 8 | `u64` | - |
| `global_reclaim_vm_returned_frames` | 1616 | 8 | 8 | `u64` | - |
| `global_reclaim_vm_returned_bytes` | 1624 | 8 | 8 | `u64` | - |
| `global_reclaim_vm_page_outs` | 1632 | 8 | 8 | `u64` | - |
| `global_reclaim_vm_failures` | 1640 | 8 | 8 | `u64` | - |
| `memory_backing_store_status` | 1648 | 4 | 4 | `u32` | - |
| `memory_backing_store_flags` | 1652 | 4 | 4 | `u32` | - |
| `memory_backing_store_blockers` | 1656 | 4 | 4 | `u32` | - |
| `memory_backing_store_cluster_bytes` | 1660 | 4 | 4 | `u32` | - |
| `memory_backing_store_requested_bytes` | 1664 | 8 | 8 | `u64` | - |
| `memory_backing_store_available_bytes` | 1672 | 8 | 8 | `u64` | - |
| `memory_backing_store_file_size` | 1680 | 8 | 8 | `u64` | - |
| `memory_backing_store_probe_count` | 1688 | 8 | 8 | `u64` | - |
| `memory_backing_store_ready_count` | 1696 | 8 | 8 | `u64` | - |
| `memory_backing_store_failure_count` | 1704 | 8 | 8 | `u64` | - |
| `memory_backing_store_first_cluster` | 1712 | 4 | 4 | `u32` | - |
| `memory_backing_store_pager_enabled` | 1716 | 4 | 4 | `u32` | - |
| `memory_backing_store_anonymous_paging_enabled` | 1720 | 4 | 4 | `u32` | - |
| `memory_backing_store_reserved0` | 1724 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_status` | 1728 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_operation` | 1732 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_flags` | 1736 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_blockers` | 1740 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_bytes` | 1744 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_max_ranges` | 1748 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_range_count` | 1752 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_last_owner_kind` | 1756 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_capacity` | 1760 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_reserved` | 1768 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_free` | 1776 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_valid` | 1784 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_dirty` | 1792 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_error` | 1800 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_last_reservation_id` | 1808 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_last_owner_id` | 1812 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_last_region_id` | 1816 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_pager_enabled` | 1820 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_eviction_enabled` | 1824 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_page_in_enabled` | 1828 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_page_out_enabled` | 1832 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_reserved1` | 1836 | 4 | 4 | `u32` | - |
| `memory_backing_store_slot_last_first_slot` | 1840 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_last_slot_count` | 1848 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_generation` | 1856 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_probe_count` | 1864 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_reserve_count` | 1872 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_release_count` | 1880 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_error_mark_count` | 1888 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_recovery_count` | 1896 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_failure_count` | 1904 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_lifecycle_cleanup_count` | 1912 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_lifecycle_released_ranges` | 1920 | 8 | 8 | `u64` | - |
| `memory_backing_store_slot_lifecycle_released_slots` | 1928 | 8 | 8 | `u64` | - |
| `memory_pager_gate_status` | 1936 | 4 | 4 | `u32` | - |
| `memory_pager_gate_flags` | 1940 | 4 | 4 | `u32` | - |
| `memory_pager_gate_blockers` | 1944 | 4 | 4 | `u32` | - |
| `memory_pager_gate_region_id` | 1948 | 4 | 4 | `u32` | - |
| `memory_pager_gate_owner_id` | 1952 | 4 | 4 | `u32` | - |
| `memory_pager_gate_slot_bytes` | 1956 | 4 | 4 | `u32` | - |
| `memory_pager_gate_rollback_completed` | 1960 | 4 | 4 | `u32` | - |
| `memory_pager_gate_reserved0` | 1964 | 4 | 4 | `u32` | - |
| `memory_pager_gate_requested_bytes` | 1968 | 8 | 8 | `u64` | - |
| `memory_pager_gate_committed_bytes` | 1976 | 8 | 8 | `u64` | - |
| `memory_pager_gate_resident_bytes` | 1984 | 8 | 8 | `u64` | - |
| `memory_pager_gate_nonresident_bytes` | 1992 | 8 | 8 | `u64` | - |
| `memory_pager_gate_requested_slots` | 2000 | 8 | 8 | `u64` | - |
| `memory_pager_gate_prepared_slots` | 2008 | 8 | 8 | `u64` | - |
| `memory_pager_gate_capacity_slots` | 2016 | 8 | 8 | `u64` | - |
| `memory_pager_gate_free_before_slots` | 2024 | 8 | 8 | `u64` | - |
| `memory_pager_gate_free_after_slots` | 2032 | 8 | 8 | `u64` | - |
| `memory_pager_gate_reserved_before_slots` | 2040 | 8 | 8 | `u64` | - |
| `memory_pager_gate_reserved_after_slots` | 2048 | 8 | 8 | `u64` | - |
| `memory_pager_gate_last_reservation_id` | 2056 | 4 | 4 | `u32` | - |
| `memory_pager_gate_commit_gate_enabled` | 2060 | 4 | 4 | `u32` | - |
| `memory_pager_gate_fault_gate_enabled` | 2064 | 4 | 4 | `u32` | - |
| `memory_pager_gate_pager_enabled` | 2068 | 4 | 4 | `u32` | - |
| `memory_pager_gate_eviction_enabled` | 2072 | 4 | 4 | `u32` | - |
| `memory_pager_gate_page_in_enabled` | 2076 | 4 | 4 | `u32` | - |
| `memory_pager_gate_page_out_enabled` | 2080 | 4 | 4 | `u32` | - |
| `memory_pager_gate_reserved1` | 2084 | 4 | 4 | `u32` | - |
| `memory_pager_gate_slot_generation` | 2088 | 8 | 8 | `u64` | - |
| `memory_pager_gate_fault_count` | 2096 | 8 | 8 | `u64` | - |
| `memory_pager_gate_failed_faults` | 2104 | 8 | 8 | `u64` | - |
| `memory_pager_gate_probe_count` | 2112 | 8 | 8 | `u64` | - |
| `memory_pager_gate_ready_count` | 2120 | 8 | 8 | `u64` | - |
| `memory_pager_gate_rollback_count` | 2128 | 8 | 8 | `u64` | - |
| `memory_pager_gate_failure_count` | 2136 | 8 | 8 | `u64` | - |
| `memory_page_io_status` | 2144 | 4 | 4 | `u32` | - |
| `memory_page_io_operation` | 2148 | 4 | 4 | `u32` | - |
| `memory_page_io_flags` | 2152 | 4 | 4 | `u32` | - |
| `memory_page_io_blockers` | 2156 | 4 | 4 | `u32` | - |
| `memory_page_io_region_id` | 2160 | 4 | 4 | `u32` | - |
| `memory_page_io_reservation_id` | 2164 | 4 | 4 | `u32` | - |
| `memory_page_io_owner_kind` | 2168 | 4 | 4 | `u32` | - |
| `memory_page_io_owner_id` | 2172 | 4 | 4 | `u32` | - |
| `memory_page_io_slot_bytes` | 2176 | 4 | 4 | `u32` | - |
| `memory_page_io_io_bytes` | 2180 | 4 | 4 | `u32` | - |
| `memory_page_io_io_status` | 2184 | 4 | 4 | `i32` | - |
| `memory_page_io_pager_enabled` | 2188 | 4 | 4 | `u32` | - |
| `memory_page_io_eviction_enabled` | 2192 | 4 | 4 | `u32` | - |
| `memory_page_io_page_in_enabled` | 2196 | 4 | 4 | `u32` | - |
| `memory_page_io_page_out_enabled` | 2200 | 4 | 4 | `u32` | - |
| `memory_page_io_reserved0` | 2204 | 4 | 4 | `u32` | - |
| `memory_page_io_region_offset` | 2208 | 8 | 8 | `u64` | - |
| `memory_page_io_page_count` | 2216 | 8 | 8 | `u64` | - |
| `memory_page_io_transfer_bytes` | 2224 | 8 | 8 | `u64` | - |
| `memory_page_io_expected_generation` | 2232 | 8 | 8 | `u64` | - |
| `memory_page_io_backing_slot` | 2240 | 8 | 8 | `u64` | - |
| `memory_page_io_backing_offset` | 2248 | 8 | 8 | `u64` | - |
| `memory_page_io_capacity_slots` | 2256 | 8 | 8 | `u64` | - |
| `memory_page_io_reserved_slots` | 2264 | 8 | 8 | `u64` | - |
| `memory_page_io_valid_slots` | 2272 | 8 | 8 | `u64` | - |
| `memory_page_io_dirty_slots` | 2280 | 8 | 8 | `u64` | - |
| `memory_page_io_error_slots` | 2288 | 8 | 8 | `u64` | - |
| `memory_page_io_slot_generation` | 2296 | 8 | 8 | `u64` | - |
| `memory_page_io_prepare_count` | 2304 | 8 | 8 | `u64` | - |
| `memory_page_io_page_out_count` | 2312 | 8 | 8 | `u64` | - |
| `memory_page_io_page_in_count` | 2320 | 8 | 8 | `u64` | - |
| `memory_page_io_failure_count` | 2328 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_status` | 2336 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_operation` | 2340 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_flags` | 2344 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_blockers` | 2348 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_region_id` | 2352 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_page_size` | 2356 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_max_spans` | 2360 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_span_count` | 2364 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_slot_reservation_id` | 2368 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_page_count_lo` | 2372 | 4 | 4 | `u32` | - |
| `memory_vm_page_state_reserved0` | 2376 | 8 | 4 | `[2]u32` | - |
| `memory_vm_page_state_region_offset` | 2384 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_page_count` | 2392 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_committed_pages` | 2400 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_resident_pages` | 2408 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_nonresident_pages` | 2416 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_dirty_pages` | 2424 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_clean_pages` | 2432 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_pinned_pages` | 2440 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_busy_pages` | 2448 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_error_pages` | 2456 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_slot_bound_pages` | 2464 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_slot_index` | 2472 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_slot_generation` | 2480 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_transition_count` | 2488 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_dirty_mark_count` | 2496 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_clean_mark_count` | 2504 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_slot_bind_count` | 2512 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_slot_clear_count` | 2520 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_pinned_mark_count` | 2528 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_pinned_clear_count` | 2536 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_busy_mark_count` | 2544 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_busy_clear_count` | 2552 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_error_mark_count` | 2560 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_error_clear_count` | 2568 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_table_full_failures` | 2576 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_cleanup_pages` | 2584 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_fault_page_in_count` | 2592 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_fault_page_in_failure_count` | 2600 | 8 | 8 | `u64` | - |
| `memory_vm_page_state_page_out_nonresident_pages` | 2608 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_attempt_count` | 2616 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_success_count` | 2624 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_failure_count` | 2632 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_candidate_count` | 2640 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_page_out_count` | 2648 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_clean_page_count` | 2656 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_dirty_page_count` | 2664 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_returned_frames` | 2672 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_no_backing_count` | 2680 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_no_candidate_count` | 2688 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_slot_failure_count` | 2696 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_io_failure_count` | 2704 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_skipped_nonresident` | 2712 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_skipped_pinned` | 2720 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_skipped_busy` | 2728 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_skipped_error` | 2736 | 8 | 8 | `u64` | - |
| `memory_vm_eviction_skipped_unmapped` | 2744 | 8 | 8 | `u64` | - |
| `memory_page_io_retry_attempt_count` | 2752 | 8 | 8 | `u64` | - |
| `memory_page_io_retryable_failure_count` | 2760 | 8 | 8 | `u64` | - |
| `memory_page_io_permanent_failure_count` | 2768 | 8 | 8 | `u64` | - |
| `memory_page_io_retry_limit_hit_count` | 2776 | 8 | 8 | `u64` | - |
| `memory_page_io_failed_page_out_count` | 2784 | 8 | 8 | `u64` | - |
| `memory_page_io_failed_page_in_count` | 2792 | 8 | 8 | `u64` | - |
| `memory_page_io_data_preserved_pages` | 2800 | 8 | 8 | `u64` | - |
| `memory_page_io_data_lost_pages` | 2808 | 8 | 8 | `u64` | - |
| `memory_vm_pager_failed_page_out_count` | 2816 | 8 | 8 | `u64` | - |
| `memory_vm_pager_failed_page_in_count` | 2824 | 8 | 8 | `u64` | - |
| `memory_vm_pager_data_preserved_pages` | 2832 | 8 | 8 | `u64` | - |
| `memory_vm_pager_data_lost_pages` | 2840 | 8 | 8 | `u64` | - |
| `memory_vm_pager_dirty_preserved_pages` | 2848 | 8 | 8 | `u64` | - |
| `memory_vm_pager_disabled_eviction_gates` | 2856 | 8 | 8 | `u64` | - |
| `preemption_quantum_ticks` | 2864 | 4 | 4 | `u32` | - |
| `preemption_reserved4` | 2868 | 4 | 4 | `u32` | - |
| `preemption_quantum_expired` | 2872 | 8 | 8 | `u64` | - |
| `preemption_deferred_quantum` | 2880 | 8 | 8 | `u64` | - |
| `preemption_deferred_kernel_ip` | 2888 | 8 | 8 | `u64` | - |
| `preemption_app_code_ticks` | 2896 | 8 | 8 | `u64` | - |
| `scheduler_ready_latency_samples` | 2904 | 8 | 8 | `u64` | - |
| `scheduler_ready_latency_total_ticks` | 2912 | 8 | 8 | `u64` | - |
| `scheduler_ready_latency_max_ticks` | 2920 | 8 | 8 | `u64` | - |
| `scheduler_ready_latency_last_ticks` | 2928 | 8 | 8 | `u64` | - |
| `scheduler_ready_waiting_max_ticks` | 2936 | 8 | 8 | `u64` | - |
| `scheduler_run_without_switch_max_ticks` | 2944 | 8 | 8 | `u64` | - |
| `scheduler_quantum_overrun_count` | 2952 | 8 | 8 | `u64` | - |
| `scheduler_quantum_overrun_max_ticks` | 2960 | 8 | 8 | `u64` | - |
| `scheduler_preemption_deferred_max_ticks` | 2968 | 8 | 8 | `u64` | - |
| `scheduler_long_running_warn_ticks` | 2976 | 8 | 8 | `u64` | - |
| `scheduler_starvation_warn_ticks` | 2984 | 8 | 8 | `u64` | - |
| `wait_object_total_ticks` | 2992 | 8 | 8 | `u64` | - |
| `wait_object_max_ticks` | 3000 | 8 | 8 | `u64` | - |
| `wait_object_last_ticks` | 3008 | 8 | 8 | `u64` | - |
| `wait_queue_total_ticks` | 3016 | 8 | 8 | `u64` | - |
| `wait_queue_max_ticks` | 3024 | 8 | 8 | `u64` | - |
| `wait_queue_last_ticks` | 3032 | 8 | 8 | `u64` | - |
| `driver_work_capacity` | 3040 | 4 | 4 | `u32` | - |
| `driver_work_depth` | 3044 | 4 | 4 | `u32` | - |
| `driver_work_high_water` | 3048 | 4 | 4 | `u32` | - |
| `driver_work_worker_started` | 3052 | 4 | 4 | `u32` | - |
| `driver_work_submitted` | 3056 | 8 | 8 | `u64` | - |
| `driver_work_submitted_from_irq` | 3064 | 8 | 8 | `u64` | - |
| `driver_work_submitted_from_task` | 3072 | 8 | 8 | `u64` | - |
| `driver_work_started` | 3080 | 8 | 8 | `u64` | - |
| `driver_work_completed` | 3088 | 8 | 8 | `u64` | - |
| `driver_work_failed` | 3096 | 8 | 8 | `u64` | - |
| `driver_work_cancelled` | 3104 | 8 | 8 | `u64` | - |
| `driver_work_dropped` | 3112 | 8 | 8 | `u64` | - |
| `driver_work_waits` | 3120 | 8 | 8 | `u64` | - |
| `driver_work_wait_timeouts` | 3128 | 8 | 8 | `u64` | - |
| `driver_work_wait_denied_irq` | 3136 | 8 | 8 | `u64` | - |
| `driver_work_wait_total_ticks` | 3144 | 8 | 8 | `u64` | - |
| `driver_work_wait_max_ticks` | 3152 | 8 | 8 | `u64` | - |
| `driver_work_wait_last_ticks` | 3160 | 8 | 8 | `u64` | - |
| `driver_work_queue_total_ticks` | 3168 | 8 | 8 | `u64` | - |
| `driver_work_queue_max_ticks` | 3176 | 8 | 8 | `u64` | - |
| `driver_work_queue_last_ticks` | 3184 | 8 | 8 | `u64` | - |
| `driver_work_run_total_ticks` | 3192 | 8 | 8 | `u64` | - |
| `driver_work_run_max_ticks` | 3200 | 8 | 8 | `u64` | - |
| `driver_work_run_last_ticks` | 3208 | 8 | 8 | `u64` | - |
| `driver_work_releases` | 3216 | 8 | 8 | `u64` | - |
| `driver_work_invalid_handles` | 3224 | 8 | 8 | `u64` | - |
| `driver_work_cleanup_cancelled` | 3232 | 8 | 8 | `u64` | - |
| `driver_wait_ticks_calls` | 3240 | 8 | 8 | `u64` | - |
| `driver_wait_ticks_denied_irq` | 3248 | 8 | 8 | `u64` | - |
| `driver_wait_ticks_total` | 3256 | 8 | 8 | `u64` | - |
| `storage_worker_started` | 3264 | 4 | 4 | `u32` | - |
| `storage_worker_task_id` | 3268 | 4 | 4 | `u32` | - |
| `storage_worker_wakeups` | 3272 | 8 | 8 | `u64` | - |
| `storage_worker_runs` | 3280 | 8 | 8 | `u64` | - |
| `storage_worker_idle_waits` | 3288 | 8 | 8 | `u64` | - |
| `storage_worker_queue_scans` | 3296 | 8 | 8 | `u64` | - |
| `storage_worker_runtime_requests` | 3304 | 8 | 8 | `u64` | - |
| `storage_worker_runtime_completions` | 3312 | 8 | 8 | `u64` | - |
| `storage_boot_inline_requests` | 3320 | 8 | 8 | `u64` | - |
| `storage_boot_inline_completions` | 3328 | 8 | 8 | `u64` | - |
| `storage_completion_signals` | 3336 | 8 | 8 | `u64` | - |
| `display_present_total_ticks` | 3344 | 8 | 8 | `u64` | - |
| `display_present_max_ticks` | 3352 | 8 | 8 | `u64` | - |
| `display_present_last_ticks` | 3360 | 8 | 8 | `u64` | - |
| `display_present_slow_count` | 3368 | 8 | 8 | `u64` | - |
| `audio_stream_ring_bytes` | 3376 | 8 | 8 | `u64` | - |
| `audio_stream_available_bytes` | 3384 | 8 | 8 | `u64` | - |
| `audio_stream_high_water_bytes` | 3392 | 8 | 8 | `u64` | - |
| `audio_stream_write_truncations` | 3400 | 8 | 8 | `u64` | - |
| `audio_stream_dropped_bytes` | 3408 | 8 | 8 | `u64` | - |
| `audio_stream_write_total_ticks` | 3416 | 8 | 8 | `u64` | - |
| `audio_stream_write_max_ticks` | 3424 | 8 | 8 | `u64` | - |
| `audio_stream_write_last_ticks` | 3432 | 8 | 8 | `u64` | - |
| `audio_backend_write_calls` | 3440 | 8 | 8 | `u64` | - |
| `audio_backend_write_total_ticks` | 3448 | 8 | 8 | `u64` | - |
| `audio_backend_write_max_ticks` | 3456 | 8 | 8 | `u64` | - |
| `audio_backend_write_last_ticks` | 3464 | 8 | 8 | `u64` | - |
| `audio_backend_refills` | 3472 | 8 | 8 | `u64` | - |
| `audio_backend_silence_refills` | 3480 | 8 | 8 | `u64` | - |
| `audio_backend_buffer_bytes` | 3488 | 8 | 8 | `u64` | - |
| `audio_backend_queued_buffers` | 3496 | 8 | 8 | `u64` | - |
| `audio_backend_last_buffer_bytes` | 3504 | 8 | 8 | `u64` | - |
| `audio_backend_refill_total_ticks` | 3512 | 8 | 8 | `u64` | - |
| `audio_backend_refill_max_ticks` | 3520 | 8 | 8 | `u64` | - |
| `audio_backend_refill_last_ticks` | 3528 | 8 | 8 | `u64` | - |
| `loader_initialized` | 3536 | 4 | 4 | `u32` | - |
| `loader_started` | 3540 | 4 | 4 | `u32` | - |
| `loader_completed` | 3544 | 4 | 4 | `u32` | - |
| `loader_r4p_runtime_started` | 3548 | 4 | 4 | `u32` | - |
| `loader_r4p_runtime_completed` | 3552 | 4 | 4 | `u32` | - |
| `loader_service_boot_status` | 3556 | 4 | 4 | `u32` | - |
| `loader_boot_critical_count` | 3560 | 4 | 4 | `u32` | - |
| `loader_lazy_candidate_count` | 3564 | 4 | 4 | `u32` | - |
| `loader_total_ticks` | 3568 | 8 | 8 | `u64` | - |
| `loader_r4p_runtime_total_ticks` | 3576 | 8 | 8 | `u64` | - |
| `loader_service_boot_ticks` | 3584 | 8 | 8 | `u64` | - |
| `loader_config_load_ticks` | 3592 | 8 | 8 | `u64` | - |
| `loader_config_bytes` | 3600 | 8 | 8 | `u64` | - |
| `loader_config_driver_count` | 3608 | 4 | 4 | `u32` | - |
| `loader_config_disabled_count` | 3612 | 4 | 4 | `u32` | - |
| `loader_config_option_count` | 3616 | 4 | 4 | `u32` | - |
| `loader_config_reserved0` | 3620 | 4 | 4 | `u32` | - |
| `loader_r4l_scan_entries` | 3624 | 8 | 8 | `u64` | - |
| `loader_r4l_candidates` | 3632 | 8 | 8 | `u64` | - |
| `loader_r4l_loaded` | 3640 | 8 | 8 | `u64` | - |
| `loader_r4l_failed` | 3648 | 8 | 8 | `u64` | - |
| `loader_r4l_scan_ticks` | 3656 | 8 | 8 | `u64` | - |
| `loader_r4l_read_ticks` | 3664 | 8 | 8 | `u64` | - |
| `loader_r4l_resolve_ticks` | 3672 | 8 | 8 | `u64` | - |
| `loader_r4l_load_ticks` | 3680 | 8 | 8 | `u64` | - |
| `loader_r4d_scan_entries` | 3688 | 8 | 8 | `u64` | - |
| `loader_r4d_candidates` | 3696 | 8 | 8 | `u64` | - |
| `loader_r4d_discovered` | 3704 | 8 | 8 | `u64` | - |
| `loader_r4d_failed` | 3712 | 8 | 8 | `u64` | - |
| `loader_r4d_scan_ticks` | 3720 | 8 | 8 | `u64` | - |
| `loader_r4d_read_ticks` | 3728 | 8 | 8 | `u64` | - |
| `loader_r4d_probe_ticks` | 3736 | 8 | 8 | `u64` | - |
| `loader_r4p_scan_entries` | 3744 | 8 | 8 | `u64` | - |
| `loader_r4p_candidates` | 3752 | 8 | 8 | `u64` | - |
| `loader_r4p_discovered` | 3760 | 8 | 8 | `u64` | - |
| `loader_r4p_active` | 3768 | 8 | 8 | `u64` | - |
| `loader_r4p_blocked` | 3776 | 8 | 8 | `u64` | - |
| `loader_r4p_failed` | 3784 | 8 | 8 | `u64` | - |
| `loader_r4p_scan_ticks` | 3792 | 8 | 8 | `u64` | - |
| `loader_r4p_read_ticks` | 3800 | 8 | 8 | `u64` | - |
| `loader_r4p_resolve_ticks` | 3808 | 8 | 8 | `u64` | - |
| `loader_r4p_init_ticks` | 3816 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_index_capacity` | 3824 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_index_entries` | 3828 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_index_tombstones` | 3832 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_index_probe_max` | 3836 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_index_probe_last` | 3840 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_free_slot_probe_max` | 3844 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_free_slot_probe_last` | 3848 | 4 | 4 | `u32` | - |
| `hot_path_bounded_block_device_scan_max` | 3852 | 4 | 4 | `u32` | - |
| `hot_path_bounded_tcp_connection_scan_max` | 3856 | 4 | 4 | `u32` | - |
| `hot_path_reserved0` | 3860 | 4 | 4 | `u32` | - |
| `hot_path_vm_range_index_lookups` | 3864 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_index_hits` | 3872 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_index_misses` | 3880 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_index_probe_total` | 3888 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_index_rebuilds` | 3896 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_index_insert_failures` | 3904 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_free_slot_lookups` | 3912 | 8 | 8 | `u64` | - |
| `hot_path_vm_range_free_slot_probe_total` | 3920 | 8 | 8 | `u64` | - |
| `loader_file_active_buffers` | 3928 | 8 | 8 | `u64` | - |
| `loader_file_reserved_bytes` | 3936 | 8 | 8 | `u64` | - |
| `loader_file_committed_bytes` | 3944 | 8 | 8 | `u64` | - |
| `loader_file_peak_reserved_bytes` | 3952 | 8 | 8 | `u64` | - |
| `loader_file_peak_committed_bytes` | 3960 | 8 | 8 | `u64` | - |
| `loader_file_full_reads` | 3968 | 8 | 8 | `u64` | - |
| `loader_file_range_reads` | 3976 | 8 | 8 | `u64` | - |
| `loader_file_reserve_failures` | 3984 | 8 | 8 | `u64` | - |
| `loader_file_commit_failures` | 3992 | 8 | 8 | `u64` | - |
| `loader_file_read_failures` | 4000 | 8 | 8 | `u64` | - |
| `loader_file_short_reads` | 4008 | 8 | 8 | `u64` | - |
| `loader_file_release_failures` | 4016 | 8 | 8 | `u64` | - |
| `loader_file_pressure_reclaim_attempts` | 4024 | 8 | 8 | `u64` | - |
| `loader_file_pressure_reclaimed_frames` | 4032 | 8 | 8 | `u64` | - |
| `loader_file_pressure_failures` | 4040 | 8 | 8 | `u64` | - |
| `fat32_read_sectors` | 4048 | 8 | 8 | `u64` | - |
| `fat32_write_sectors` | 4056 | 8 | 8 | `u64` | - |
| `fat32_read_failures` | 4064 | 8 | 8 | `u64` | - |
| `fat32_write_failures` | 4072 | 8 | 8 | `u64` | - |
| `fat32_flushes` | 4080 | 8 | 8 | `u64` | - |
| `fat32_flush_failures` | 4088 | 8 | 8 | `u64` | - |
| `fat32_flush_total_ticks` | 4096 | 8 | 8 | `u64` | - |
| `fat32_flush_max_ticks` | 4104 | 8 | 8 | `u64` | - |
| `fat32_flush_last_ticks` | 4112 | 8 | 8 | `u64` | - |
| `fat32_file_writes` | 4120 | 8 | 8 | `u64` | - |
| `fat32_file_appends` | 4128 | 8 | 8 | `u64` | - |
| `fat32_file_write_ranges` | 4136 | 8 | 8 | `u64` | - |
| `fat32_file_write_bytes` | 4144 | 8 | 8 | `u64` | - |
| `fat32_file_append_bytes` | 4152 | 8 | 8 | `u64` | - |
| `fat32_dir_scans` | 4160 | 8 | 8 | `u64` | - |
| `fat32_dir_entries_scanned` | 4168 | 8 | 8 | `u64` | - |
| `fat32_dir_entry_updates` | 4176 | 8 | 8 | `u64` | - |
| `fat32_cluster_walk_steps` | 4184 | 8 | 8 | `u64` | - |
| `fat32_fat_reads` | 4192 | 8 | 8 | `u64` | - |
| `fat32_fat_writes` | 4200 | 8 | 8 | `u64` | - |
| `fat32_fat_mirror_writes` | 4208 | 8 | 8 | `u64` | - |
| `fat32_alloc_chain_calls` | 4216 | 8 | 8 | `u64` | - |
| `fat32_alloc_clusters` | 4224 | 8 | 8 | `u64` | - |
| `fat32_alloc_search_steps` | 4232 | 8 | 8 | `u64` | - |
| `fat32_operation_failures` | 4240 | 8 | 8 | `u64` | - |
| `fat32_operation_total_ticks` | 4248 | 8 | 8 | `u64` | - |
| `fat32_operation_max_ticks` | 4256 | 8 | 8 | `u64` | - |
| `fat32_operation_last_ticks` | 4264 | 8 | 8 | `u64` | - |
| `fat32_active_operation` | 4272 | 4 | 4 | `u32` | - |
| `fat32_last_operation` | 4276 | 4 | 4 | `u32` | - |
| `fat32_reserved0` | 4280 | 8 | 8 | `u64` | - |
| `fat32_yield_points` | 4288 | 8 | 8 | `u64` | - |
| `fat32_yields` | 4296 | 8 | 8 | `u64` | - |
| `fat32_yield_skips` | 4304 | 8 | 8 | `u64` | - |
| `fat32_alloc_runs` | 4312 | 8 | 8 | `u64` | - |
| `fat32_alloc_run_clusters` | 4320 | 8 | 8 | `u64` | - |
| `fat32_alloc_run_max_clusters` | 4328 | 8 | 8 | `u64` | - |
| `fat32_fat_sector_writes` | 4336 | 8 | 8 | `u64` | - |
| `fat32_read_extent_cache_hits` | 4344 | 8 | 8 | `u64` | - |
| `fat32_read_extent_cache_misses` | 4352 | 8 | 8 | `u64` | - |
| `fat32_read_extent_cache_stores` | 4360 | 8 | 8 | `u64` | - |
| `fat32_read_extent_cache_clusters` | 4368 | 8 | 8 | `u64` | - |
| `fat32_fsinfo_reads` | 4376 | 8 | 8 | `u64` | - |
| `fat32_fsinfo_valid_mounts` | 4384 | 8 | 8 | `u64` | - |
| `fat32_fsinfo_rebuilds` | 4392 | 8 | 8 | `u64` | - |
| `fat32_fsinfo_writes` | 4400 | 8 | 8 | `u64` | - |
| `fat32_inusemap_builds` | 4408 | 8 | 8 | `u64` | - |
| `fat32_inusemap_clusters` | 4416 | 8 | 8 | `u64` | - |
| `fat32_inusemap_alloc_hits` | 4424 | 8 | 8 | `u64` | - |
| `fat32_inusemap_alloc_misses` | 4432 | 8 | 8 | `u64` | - |
| `monotonic_clock_flags` | 4440 | 4 | 4 | `u32` | - |
| `monotonic_clock_source` | 4444 | 4 | 4 | `u32` | - |
| `monotonic_clock_generation` | 4448 | 4 | 4 | `u32` | - |
| `monotonic_event_backend` | 4452 | 4 | 4 | `u32` | - |
| `monotonic_clock_resolution_ns` | 4456 | 8 | 8 | `u64` | - |
| `monotonic_source_frequency_hz` | 4464 | 8 | 8 | `u64` | - |
| `monotonic_event_frequency_numerator` | 4472 | 8 | 8 | `u64` | - |
| `monotonic_event_frequency_denominator` | 4480 | 8 | 8 | `u64` | - |
| `monotonic_event_requested_hz` | 4488 | 4 | 4 | `u32` | - |
| `monotonic_event_effective_hz` | 4492 | 4 | 4 | `u32` | - |
| `boot_timing_valid` | 4496 | 4 | 4 | `u32` | - |
| `boot_timing_unavailable_spans` | 4500 | 4 | 4 | `u32` | - |
| `boot_timing_dropped_spans` | 4504 | 4 | 4 | `u32` | - |
| `loader_timing_valid_spans` | 4508 | 4 | 4 | `u32` | - |
| `loader_timing_unavailable_spans` | 4512 | 4 | 4 | `u32` | - |
| `monotonic_reserved0` | 4516 | 4 | 4 | `u32` | - |
| `boot_total_ns` | 4520 | 8 | 8 | `u64` | - |
| `boot_now_ns` | 4528 | 8 | 8 | `u64` | - |
| `loader_total_ns` | 4536 | 8 | 8 | `u64` | - |
| `loader_r4p_runtime_total_ns` | 4544 | 8 | 8 | `u64` | - |
| `loader_service_boot_ns` | 4552 | 8 | 8 | `u64` | - |
| `loader_config_load_ns` | 4560 | 8 | 8 | `u64` | - |
| `monotonic_reserved1` | 4568 | 8 | 8 | `u64` | - |
| `service_completion_wait_rounds` | 4576 | 8 | 8 | `u64` | - |
| `service_targeted_response_wakes` | 4584 | 8 | 8 | `u64` | - |
| `service_targeted_response_wake_misses` | 4592 | 8 | 8 | `u64` | - |
| `service_admission_waits` | 4600 | 8 | 8 | `u64` | - |
| `service_admission_timeouts` | 4608 | 8 | 8 | `u64` | - |
| `service_payload_copy_bytes` | 4616 | 8 | 8 | `u64` | - |
| `service_payload_clear_bytes` | 4624 | 8 | 8 | `u64` | - |
| `service_slot_metadata_resets` | 4632 | 8 | 8 | `u64` | - |
| `service_endpoint_metadata_resets` | 4640 | 8 | 8 | `u64` | - |
| `service_endpoint_payload_reset_bytes` | 4648 | 8 | 8 | `u64` | - |
| `service_queue_scan_passes` | 4656 | 8 | 8 | `u64` | - |
| `service_queue_scan_slots` | 4664 | 8 | 8 | `u64` | - |
| `service_endpoint_revalidations` | 4672 | 8 | 8 | `u64` | - |
| `service_endpoint_stale_rejections` | 4680 | 8 | 8 | `u64` | - |
| `service_lock_family_count` | 4688 | 4 | 4 | `u32` | - |
| `service_lock_reserved0` | 4692 | 4 | 4 | `u32` | - |
| `service_lock_acquisitions` | 4696 | 56 | 8 | `[7]u64` | - |
| `service_lock_contentions` | 4752 | 56 | 8 | `[7]u64` | - |
| `service_lock_wait_ns` | 4808 | 56 | 8 | `[7]u64` | - |
| `service_lock_wait_max_ns` | 4864 | 56 | 8 | `[7]u64` | - |
| `service_lock_hold_ns` | 4920 | 56 | 8 | `[7]u64` | - |
| `service_lock_hold_max_ns` | 4976 | 56 | 8 | `[7]u64` | - |
| `service_lock_timing_unavailable` | 5032 | 56 | 8 | `[7]u64` | - |
| `service_lock_timing_stride` | 5088 | 4 | 4 | `u32` | - |
| `service_lock_timing_reserved0` | 5092 | 4 | 4 | `u32` | - |
| `service_lock_timing_samples` | 5096 | 56 | 8 | `[7]u64` | - |
| `service_registry_index_queries` | 5152 | 8 | 8 | `u64` | - |
| `service_registry_refresh_requests` | 5160 | 8 | 8 | `u64` | - |
| `service_registry_refresh_visits` | 5168 | 8 | 8 | `u64` | - |
| `service_registry_instance_lookups` | 5176 | 8 | 8 | `u64` | - |
| `service_registry_index_end_markers` | 5184 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_physical_index_entries` | 5192 | 4 | 4 | `u32` | - |
| `hot_path_memory_block_physical_step_max` | 5196 | 4 | 4 | `u32` | - |
| `hot_path_memory_block_id_index_entries` | 5200 | 4 | 4 | `u32` | - |
| `hot_path_memory_block_id_step_max` | 5204 | 4 | 4 | `u32` | - |
| `hot_path_memory_block_free_slot_word_step_max` | 5208 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_range_address_entries` | 5212 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_range_address_probe_max` | 5216 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_range_address_probe_last` | 5220 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_commit_span_active` | 5224 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_commit_span_step_max` | 5228 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_page_state_span_active` | 5232 | 4 | 4 | `u32` | - |
| `hot_path_memory_vm_page_state_span_step_max` | 5236 | 4 | 4 | `u32` | - |
| `hot_path_memory_block_physical_lookups` | 5240 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_physical_steps` | 5248 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_physical_mutations` | 5256 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_physical_rebuilds` | 5264 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_id_lookups` | 5272 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_id_steps` | 5280 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_free_slot_lookups` | 5288 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_free_slot_word_steps` | 5296 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_claim_transactions` | 5304 | 8 | 8 | `u64` | - |
| `hot_path_memory_block_claim_rollbacks` | 5312 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_range_address_lookups` | 5320 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_range_address_probe_total` | 5328 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_commit_span_lookups` | 5336 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_commit_span_steps` | 5344 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_page_state_span_lookups` | 5352 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_page_state_span_steps` | 5360 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_reclaim_range_steps` | 5368 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_reclaim_span_steps` | 5376 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_reclaim_page_steps` | 5384 | 8 | 8 | `u64` | - |
| `hot_path_memory_vm_reclaim_wraps` | 5392 | 8 | 8 | `u64` | - |
| `fs_drive_gate_count` | 5400 | 4 | 4 | `u32` | - |
| `fs_active_requests` | 5404 | 4 | 4 | `u32` | - |
| `fs_parallel_active_max` | 5408 | 4 | 4 | `u32` | - |
| `storage_controller_count` | 5412 | 4 | 4 | `u32` | - |
| `storage_worker_count` | 5416 | 4 | 4 | `u32` | - |
| `storage_worker_parallel_active` | 5420 | 4 | 4 | `u32` | - |
| `storage_worker_parallel_active_max` | 5424 | 4 | 4 | `u32` | - |
| `storage_dispatch_reserved0` | 5428 | 4 | 4 | `u32` | - |
| `fs_single_drive_requests` | 5432 | 8 | 8 | `u64` | - |
| `fs_cross_drive_requests` | 5440 | 8 | 8 | `u64` | - |
| `fs_global_requests` | 5448 | 8 | 8 | `u64` | - |
| `storage_worker_start_failures` | 5456 | 8 | 8 | `u64` | - |
| `storage_direct_requests` | 5464 | 8 | 8 | `u64` | - |
| `storage_direct_bytes` | 5472 | 8 | 8 | `u64` | - |
| `storage_bounce_allocations` | 5480 | 8 | 8 | `u64` | - |
| `storage_bounce_bytes` | 5488 | 8 | 8 | `u64` | - |
| `storage_bounce_copy_bytes` | 5496 | 8 | 8 | `u64` | - |
| `storage_direct_timeout_waits` | 5504 | 8 | 8 | `u64` | - |
| `fs_cache_bulk_write_requests` | 5512 | 8 | 8 | `u64` | - |
| `fs_cache_bulk_write_sectors` | 5520 | 8 | 8 | `u64` | - |
| `fs_cache_selective_flushes` | 5528 | 8 | 8 | `u64` | - |
| `fs_cache_selective_writeback_sectors` | 5536 | 8 | 8 | `u64` | - |
| `fs_cache_selective_foreign_dirty_sectors_skipped` | 5544 | 8 | 8 | `u64` | - |
| `fs_cache_policy_version` | 5552 | 4 | 4 | `u32` | - |
| `fs_cache_policy_device_capacity` | 5556 | 4 | 4 | `u32` | - |
| `fs_cache_policy_dirty_high_pages` | 5560 | 4 | 4 | `u32` | - |
| `fs_cache_policy_dirty_low_pages` | 5564 | 4 | 4 | `u32` | - |
| `fs_cache_policy_max_dirty_age_ticks` | 5568 | 8 | 8 | `u64` | - |
| `fs_cache_policy_background_page_budget` | 5576 | 4 | 4 | `u32` | - |
| `fs_cache_policy_worker_started` | 5580 | 4 | 4 | `u32` | - |
| `fs_cache_policy_worker_task_id` | 5584 | 4 | 4 | `u32` | - |
| `fs_cache_policy_device_dirty_high_water` | 5588 | 4 | 4 | `u32` | - |
| `fs_cache_policy_worker_wakeups` | 5592 | 8 | 8 | `u64` | - |
| `fs_cache_policy_background_drains` | 5600 | 8 | 8 | `u64` | - |
| `fs_cache_policy_background_sectors` | 5608 | 8 | 8 | `u64` | - |
| `fs_cache_policy_background_pressure_drains` | 5616 | 8 | 8 | `u64` | - |
| `fs_cache_policy_background_age_drains` | 5624 | 8 | 8 | `u64` | - |
| `fs_cache_policy_background_errors` | 5632 | 8 | 8 | `u64` | - |
| `fs_cache_policy_clean_device_probes` | 5640 | 8 | 8 | `u64` | - |
| `fs_cache_policy_dirty_device_probes` | 5648 | 8 | 8 | `u64` | - |
| `fs_cache_policy_full_scan_fallbacks` | 5656 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_requests` | 5664 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_issued` | 5672 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_hits` | 5680 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_cancellations` | 5688 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_budget_skips` | 5696 | 8 | 8 | `u64` | - |
| `ntfs_metadata_cache_version` | 5704 | 4 | 4 | `u32` | - |
| `ntfs_metadata_cache_active_volumes` | 5708 | 4 | 4 | `u32` | - |
| `ntfs_metadata_cache_bytes_per_volume` | 5712 | 4 | 4 | `u32` | - |
| `ntfs_metadata_cache_slot_capacity` | 5716 | 4 | 4 | `u32` | - |
| `ntfs_metadata_record_capacity` | 5720 | 4 | 4 | `u32` | - |
| `ntfs_metadata_attribute_capacity` | 5724 | 4 | 4 | `u32` | - |
| `ntfs_metadata_index_capacity` | 5728 | 4 | 4 | `u32` | - |
| `ntfs_metadata_path_capacity` | 5732 | 4 | 4 | `u32` | - |
| `ntfs_metadata_record_entries` | 5736 | 4 | 4 | `u32` | - |
| `ntfs_metadata_attribute_entries` | 5740 | 4 | 4 | `u32` | - |
| `ntfs_metadata_index_entries` | 5744 | 4 | 4 | `u32` | - |
| `ntfs_metadata_path_entries` | 5748 | 4 | 4 | `u32` | - |
| `ntfs_metadata_mount_generation` | 5752 | 8 | 8 | `u64` | - |
| `ntfs_metadata_content_generation` | 5760 | 8 | 8 | `u64` | - |
| `ntfs_metadata_negative_ttl_ticks` | 5768 | 8 | 8 | `u64` | - |
| `ntfs_metadata_record_hits` | 5776 | 8 | 8 | `u64` | - |
| `ntfs_metadata_record_misses` | 5784 | 8 | 8 | `u64` | - |
| `ntfs_metadata_record_stores` | 5792 | 8 | 8 | `u64` | - |
| `ntfs_metadata_record_evictions` | 5800 | 8 | 8 | `u64` | - |
| `ntfs_metadata_attribute_hits` | 5808 | 8 | 8 | `u64` | - |
| `ntfs_metadata_attribute_misses` | 5816 | 8 | 8 | `u64` | - |
| `ntfs_metadata_attribute_stores` | 5824 | 8 | 8 | `u64` | - |
| `ntfs_metadata_attribute_evictions` | 5832 | 8 | 8 | `u64` | - |
| `ntfs_metadata_index_hits` | 5840 | 8 | 8 | `u64` | - |
| `ntfs_metadata_index_misses` | 5848 | 8 | 8 | `u64` | - |
| `ntfs_metadata_index_stores` | 5856 | 8 | 8 | `u64` | - |
| `ntfs_metadata_index_evictions` | 5864 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_queries` | 5872 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_positive_hits` | 5880 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_negative_hits` | 5888 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_misses` | 5896 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_positive_stores` | 5904 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_negative_stores` | 5912 | 8 | 8 | `u64` | - |
| `ntfs_metadata_path_expirations` | 5920 | 8 | 8 | `u64` | - |
| `ntfs_metadata_lookup_tree_walks` | 5928 | 8 | 8 | `u64` | - |
| `ntfs_metadata_recovery_cache_bypasses` | 5936 | 8 | 8 | `u64` | - |
| `ntfs_metadata_mount_invalidations` | 5944 | 8 | 8 | `u64` | - |
| `ntfs_metadata_mutation_invalidations` | 5952 | 8 | 8 | `u64` | - |
| `ntfs_metadata_external_invalidations` | 5960 | 8 | 8 | `u64` | - |
| `ntfs_metadata_invalidated_entries` | 5968 | 8 | 8 | `u64` | - |
| `ntfs_metadata_reclaim_requests` | 5976 | 8 | 8 | `u64` | - |
| `ntfs_metadata_reclaim_scans` | 5984 | 8 | 8 | `u64` | - |
| `ntfs_metadata_reclaimed_entries` | 5992 | 8 | 8 | `u64` | - |
| `fs_cache_capacity_min_pages` | 6000 | 4 | 4 | `u32` | - |
| `fs_cache_capacity_max_pages` | 6004 | 4 | 4 | `u32` | - |
| `fs_cache_capacity_ram_limit_pages` | 6008 | 4 | 4 | `u32` | - |
| `fs_cache_capacity_active_limit_pages` | 6012 | 4 | 4 | `u32` | - |
| `fs_cache_capacity_pressure_level` | 6016 | 4 | 4 | `u32` | - |
| `fs_cache_read_ahead_window_pages` | 6020 | 4 | 4 | `u32` | - |
| `fs_cache_read_ahead_window_max_pages` | 6024 | 4 | 4 | `u32` | - |
| `fs_cache_capacity_reserved0` | 6028 | 4 | 4 | `u32` | - |
| `fs_cache_fill_run_requests` | 6032 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_backend_requests` | 6040 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_pages` | 6048 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_sectors` | 6056 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_bytes` | 6064 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_failures` | 6072 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_retries` | 6080 | 8 | 8 | `u64` | - |
| `fs_cache_fill_run_max_pages` | 6088 | 8 | 8 | `u64` | - |
| `fs_cache_fill_scatter_copy_bytes` | 6096 | 8 | 8 | `u64` | - |
| `fs_cache_read_staging_copy_bytes` | 6104 | 8 | 8 | `u64` | - |
| `fs_cache_read_caller_copy_bytes` | 6112 | 8 | 8 | `u64` | - |
| `fs_cache_read_publish_lock_drops` | 6120 | 8 | 8 | `u64` | - |
| `fs_cache_fill_lock_drops` | 6128 | 8 | 8 | `u64` | - |
| `fs_cache_capacity_reductions` | 6136 | 8 | 8 | `u64` | - |
| `fs_cache_capacity_trimmed_pages` | 6144 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_pages_scheduled` | 6152 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_pages_issued` | 6160 | 8 | 8 | `u64` | - |
| `fs_cache_read_ahead_random_resets` | 6168 | 8 | 8 | `u64` | - |
| `ntfs_metadata_payload_write_retentions` | 6176 | 8 | 8 | `u64` | - |
| `ntfs_metadata_system_write_retentions` | 6184 | 8 | 8 | `u64` | - |
| `ntfs_metadata_targeted_invalidations` | 6192 | 8 | 8 | `u64` | - |
| `ntfs_metadata_targeted_record_invalidations` | 6200 | 8 | 8 | `u64` | - |
| `ntfs_metadata_targeted_attribute_invalidations` | 6208 | 8 | 8 | `u64` | - |
| `ntfs_metadata_targeted_directory_invalidations` | 6216 | 8 | 8 | `u64` | - |
| `ntfs_metadata_global_mutation_invalidations` | 6224 | 8 | 8 | `u64` | - |
| `ntfs_metadata_recovery_invalidations` | 6232 | 8 | 8 | `u64` | - |
| `ntfs_metadata_mutation_invalidated_record_entries` | 6240 | 8 | 8 | `u64` | - |
| `ntfs_metadata_mutation_invalidated_attribute_entries` | 6248 | 8 | 8 | `u64` | - |
| `ntfs_metadata_mutation_invalidated_index_entries` | 6256 | 8 | 8 | `u64` | - |
| `ntfs_metadata_mutation_invalidated_path_entries` | 6264 | 8 | 8 | `u64` | - |
| `loader_file_range_read_bytes` | 6272 | 8 | 8 | `u64` | - |
| `loader_metadata_reader_initializations` | 6280 | 8 | 8 | `u64` | - |
| `loader_metadata_logical_reads` | 6288 | 8 | 8 | `u64` | - |
| `loader_metadata_logical_bytes` | 6296 | 8 | 8 | `u64` | - |
| `loader_metadata_window_hits` | 6304 | 8 | 8 | `u64` | - |
| `loader_metadata_window_fills` | 6312 | 8 | 8 | `u64` | - |
| `loader_metadata_window_fill_bytes` | 6320 | 8 | 8 | `u64` | - |
| `loader_metadata_direct_reads` | 6328 | 8 | 8 | `u64` | - |
| `loader_metadata_direct_bytes` | 6336 | 8 | 8 | `u64` | - |
| `loader_metadata_window_capacity_bytes` | 6344 | 8 | 8 | `u64` | - |

### `ProgramTaskPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 304 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `index` | 0 | 4 | 4 | `u32` | - |
| `id` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `wake_tick` | 16 | 8 | 8 | `u64` | - |
| `blocked_since_tick` | 24 | 8 | 8 | `u64` | - |
| `blocked_ticks` | 32 | 8 | 8 | `u64` | - |
| `created_tick` | 40 | 8 | 8 | `u64` | - |
| `last_scheduled_tick` | 48 | 8 | 8 | `u64` | - |
| `last_yield_tick` | 56 | 8 | 8 | `u64` | - |
| `ticks_since_yield` | 64 | 8 | 8 | `u64` | - |
| `run_ticks` | 72 | 8 | 8 | `u64` | - |
| `switches_in` | 80 | 8 | 8 | `u64` | - |
| `stack_base` | 88 | 8 | 8 | `u64` | - |
| `stack_top` | 96 | 8 | 8 | `u64` | - |
| `stack_bytes` | 104 | 8 | 8 | `u64` | - |
| `blocked_object` | 112 | 8 | 8 | `u64` | - |
| `wait_result` | 120 | 4 | 4 | `u32` | - |
| `preempt_disable_depth` | 124 | 4 | 4 | `u32` | - |
| `preempt_disable_max_depth` | 128 | 4 | 4 | `u32` | - |
| `ticks_since_scheduled` | 136 | 8 | 8 | `u64` | - |
| `preemption_probe_hits` | 144 | 8 | 8 | `u64` | - |
| `preemption_deferred_ticks` | 152 | 8 | 8 | `u64` | - |
| `long_run_warnings` | 160 | 8 | 8 | `u64` | - |
| `starvation_warnings` | 168 | 8 | 8 | `u64` | - |
| `reserved0` | 176 | 8 | 8 | `u64` | - |
| `name` | 184 | 32 | 1 | `[32]u8` | - |
| `wait_reason` | 216 | 32 | 1 | `[32]u8` | - |
| `ready_since_tick` | 248 | 8 | 8 | `u64` | - |
| `last_ready_latency_ticks` | 256 | 8 | 8 | `u64` | - |
| `max_ready_latency_ticks` | 264 | 8 | 8 | `u64` | - |
| `last_wait_ticks` | 272 | 8 | 8 | `u64` | - |
| `max_wait_ticks` | 280 | 8 | 8 | `u64` | - |
| `max_run_without_switch_ticks` | 288 | 8 | 8 | `u64` | - |
| `max_preemption_deferred_ticks` | 296 | 8 | 8 | `u64` | - |

### `ProgramStoragePerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 440 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `index` | 0 | 4 | 4 | `u32` | - |
| `bus` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `source` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `port` | 20 | 4 | 4 | `u32` | - |
| `sector_size` | 24 | 4 | 4 | `u32` | - |
| `max_sectors_per_request` | 28 | 4 | 4 | `u32` | - |
| `queue_depth` | 32 | 4 | 4 | `u32` | - |
| `queue_used` | 36 | 4 | 4 | `u32` | - |
| `queue_high_water` | 40 | 4 | 4 | `u32` | - |
| `timeout_ticks` | 48 | 8 | 8 | `u64` | - |
| `sector_count` | 56 | 8 | 8 | `u64` | - |
| `active_request_id` | 64 | 8 | 8 | `u64` | - |
| `active_request_kind` | 72 | 4 | 4 | `u32` | - |
| `active_request_sectors` | 76 | 4 | 4 | `u32` | - |
| `active_request_lba` | 80 | 8 | 8 | `u64` | - |
| `last_request_id` | 88 | 8 | 8 | `u64` | - |
| `last_request_kind` | 96 | 4 | 4 | `u32` | - |
| `last_request_sectors` | 100 | 4 | 4 | `u32` | - |
| `last_request_lba` | 104 | 8 | 8 | `u64` | - |
| `read_ops` | 112 | 8 | 8 | `u64` | - |
| `read_sectors` | 120 | 8 | 8 | `u64` | - |
| `read_failures` | 128 | 8 | 8 | `u64` | - |
| `write_ops` | 136 | 8 | 8 | `u64` | - |
| `write_sectors` | 144 | 8 | 8 | `u64` | - |
| `write_failures` | 152 | 8 | 8 | `u64` | - |
| `flush_ops` | 160 | 8 | 8 | `u64` | - |
| `flush_failures` | 168 | 8 | 8 | `u64` | - |
| `busy_rejections` | 176 | 8 | 8 | `u64` | - |
| `timeout_failures` | 184 | 8 | 8 | `u64` | - |
| `completions` | 192 | 8 | 8 | `u64` | - |
| `backend_recoveries` | 200 | 8 | 8 | `u64` | - |
| `backend_recovery_failures` | 208 | 8 | 8 | `u64` | - |
| `queued_requests` | 216 | 8 | 8 | `u64` | - |
| `dequeued_requests` | 224 | 8 | 8 | `u64` | - |
| `queue_full_waits` | 232 | 8 | 8 | `u64` | - |
| `queue_full_rejections` | 240 | 8 | 8 | `u64` | - |
| `completion_waits` | 248 | 8 | 8 | `u64` | - |
| `completion_timeouts` | 256 | 8 | 8 | `u64` | - |
| `completion_total_ticks` | 264 | 8 | 8 | `u64` | - |
| `completion_max_ticks` | 272 | 8 | 8 | `u64` | - |
| `completion_last_ticks` | 280 | 8 | 8 | `u64` | - |
| `last_error` | 288 | 4 | 4 | `u32` | - |
| `last_sense_valid` | 292 | 4 | 4 | `u32` | - |
| `last_sense` | 296 | 4 | 4 | `u32` | - |
| `name` | 300 | 32 | 1 | `[32]u8` | - |
| `driver` | 332 | 32 | 1 | `[32]u8` | - |
| `controller` | 364 | 32 | 1 | `[32]u8` | - |
| `completion_signals` | 400 | 8 | 8 | `u64` | - |
| `worker_requests` | 408 | 8 | 8 | `u64` | - |
| `worker_completions` | 416 | 8 | 8 | `u64` | - |
| `boot_inline_requests` | 424 | 8 | 8 | `u64` | - |
| `boot_inline_completions` | 432 | 8 | 8 | `u64` | - |

### `ProgramBootPhasePerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `index` | 0 | 4 | 4 | `u32` | - |
| `phase` | 4 | 4 | 4 | `u32` | - |
| `first_tick` | 8 | 8 | 8 | `u64` | - |
| `last_tick` | 16 | 8 | 8 | `u64` | - |
| `total_ticks` | 24 | 8 | 8 | `u64` | - |
| `transitions` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `name` | 40 | 32 | 1 | `[32]u8` | - |

### `ProgramBootPhaseClockInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `index` | 8 | 4 | 4 | `u32` | - |
| `phase` | 12 | 4 | 4 | `u32` | - |
| `clock_flags` | 16 | 4 | 4 | `u32` | - |
| `clock_source` | 20 | 4 | 4 | `u32` | - |
| `clock_generation` | 24 | 4 | 4 | `u32` | - |
| `transitions` | 28 | 4 | 4 | `u32` | - |
| `first_ns` | 32 | 8 | 8 | `u64` | - |
| `last_ns` | 40 | 8 | 8 | `u64` | - |
| `total_ns` | 48 | 8 | 8 | `u64` | - |
| `unavailable_spans` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |
| `name` | 64 | 32 | 1 | `[32]u8` | - |

### `ProgramBootPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `completion_reason` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `current_phase` | 20 | 4 | 4 | `u32` | - |
| `phase_count` | 24 | 4 | 4 | `u32` | - |
| `timing_span_count` | 28 | 4 | 4 | `u32` | - |
| `timing_unavailable_spans` | 32 | 4 | 4 | `u32` | - |
| `timing_dropped_spans` | 36 | 4 | 4 | `u32` | - |
| `clock_flags` | 40 | 4 | 4 | `u32` | - |
| `clock_source` | 44 | 4 | 4 | `u32` | - |
| `clock_generation` | 48 | 4 | 4 | `u32` | - |
| `configured_attempts` | 52 | 4 | 4 | `u32` | - |
| `fallback_attempts` | 56 | 4 | 4 | `u32` | - |
| `launch_failures` | 60 | 4 | 4 | `u32` | - |
| `shell_instance_id` | 64 | 4 | 4 | `u32` | - |
| `reserved0` | 68 | 4 | 4 | `u32` | - |
| `boot_start_tick` | 72 | 8 | 8 | `u64` | - |
| `boot_end_tick` | 80 | 8 | 8 | `u64` | - |
| `total_ticks` | 88 | 8 | 8 | `u64` | - |
| `boot_start_ns` | 96 | 8 | 8 | `u64` | - |
| `boot_end_ns` | 104 | 8 | 8 | `u64` | - |
| `total_ns` | 112 | 8 | 8 | `u64` | - |
| `clock_resolution_ns` | 120 | 8 | 8 | `u64` | - |
| `transition_count` | 128 | 8 | 8 | `u64` | - |
| `reserved1` | 136 | 8 | 8 | `u64` | - |

### `ProgramIrqTimingInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `irq` | 8 | 1 | 1 | `u8` | - |
| `registered` | 9 | 1 | 1 | `u8` | - |
| `shared` | 10 | 1 | 1 | `u8` | - |
| `masked` | 11 | 1 | 1 | `u8` | - |
| `coverage_flags` | 12 | 4 | 4 | `u32` | - |
| `clock_flags` | 16 | 4 | 4 | `u32` | - |
| `clock_source` | 20 | 4 | 4 | `u32` | - |
| `clock_generation` | 24 | 4 | 4 | `u32` | - |
| `unavailable_samples` | 28 | 4 | 4 | `u32` | - |
| `dispatch_samples` | 32 | 8 | 8 | `u64` | - |
| `handler_samples` | 40 | 8 | 8 | `u64` | - |
| `observer_reads` | 48 | 8 | 8 | `u64` | - |
| `delivery_samples` | 56 | 8 | 8 | `u64` | - |
| `dispatch_total_ns` | 64 | 8 | 8 | `u64` | - |
| `dispatch_max_ns` | 72 | 8 | 8 | `u64` | - |
| `dispatch_last_ns` | 80 | 8 | 8 | `u64` | - |
| `handler_total_ns` | 88 | 8 | 8 | `u64` | - |
| `handler_max_ns` | 96 | 8 | 8 | `u64` | - |
| `handler_last_ns` | 104 | 8 | 8 | `u64` | - |

### `ProgramMemoryBlockInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `kind` | 4 | 1 | 1 | `u8` | - |
| `owner` | 5 | 1 | 1 | `u8` | - |
| `status` | 6 | 1 | 1 | `u8` | - |
| `reserved0` | 7 | 1 | 1 | `u8` | - |
| `owner_id` | 8 | 8 | 8 | `u64` | - |
| `phys_base` | 16 | 8 | 8 | `u64` | - |
| `phys_len` | 24 | 8 | 8 | `u64` | - |
| `virt_base` | 32 | 8 | 8 | `u64` | - |
| `virt_len` | 40 | 8 | 8 | `u64` | - |
| `reserved_bytes` | 48 | 8 | 8 | `u64` | - |
| `committed_bytes` | 56 | 8 | 8 | `u64` | - |
| `name` | 64 | 32 | 1 | `[32]u8` | - |

### `ProgramVmReserveProbe`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `requested_bytes` | 0 | 8 | 8 | `u64` | - |
| `region_id` | 8 | 4 | 4 | `u32` | - |
| `released` | 12 | 4 | 4 | `u32` | - |
| `status` | 16 | 4 | 4 | `i32` | - |
| `base` | 24 | 8 | 8 | `u64` | - |
| `len` | 32 | 8 | 8 | `u64` | - |
| `reserved_bytes` | 40 | 8 | 8 | `u64` | - |
| `committed_bytes` | 48 | 8 | 8 | `u64` | - |
| `phys_len` | 56 | 8 | 8 | `u64` | - |
| `owner_id` | 64 | 8 | 8 | `u64` | - |
| `active_before` | 72 | 8 | 8 | `u64` | - |
| `active_during` | 80 | 8 | 8 | `u64` | - |
| `active_after` | 88 | 8 | 8 | `u64` | - |
| `committed_before` | 96 | 8 | 8 | `u64` | - |
| `committed_during` | 104 | 8 | 8 | `u64` | - |
| `committed_after` | 112 | 8 | 8 | `u64` | - |
| `largest_free_before` | 120 | 8 | 8 | `u64` | - |
| `largest_free_after` | 128 | 8 | 8 | `u64` | - |
| `kind` | 136 | 1 | 1 | `u8` | - |
| `owner` | 137 | 1 | 1 | `u8` | - |
| `block_status` | 138 | 1 | 1 | `u8` | - |
| `reserved0` | 139 | 1 | 1 | `u8` | - |

### `ProgramVmRegionInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `status` | 4 | 1 | 1 | `u8` | - |
| `owner` | 5 | 1 | 1 | `u8` | - |
| `kind` | 6 | 1 | 1 | `u8` | - |
| `window` | 7 | 1 | 1 | `u8` | - |
| `owner_id` | 8 | 8 | 8 | `u64` | - |
| `base` | 16 | 8 | 8 | `u64` | - |
| `len` | 24 | 8 | 8 | `u64` | - |
| `committed_bytes` | 32 | 8 | 8 | `u64` | - |
| `guard_base` | 40 | 8 | 8 | `u64` | - |
| `guard_len` | 48 | 8 | 8 | `u64` | - |
| `flags` | 56 | 8 | 8 | `u64` | - |
| `resident_bytes` | 64 | 8 | 8 | `u64` | - |
| `peak_resident_bytes` | 72 | 8 | 8 | `u64` | - |
| `fault_count` | 80 | 8 | 8 | `u64` | - |
| `failed_faults` | 88 | 8 | 8 | `u64` | - |

### `PagingSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 152 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `flags` | 0 | 4 | 4 | `u32` | - |
| `root_owner` | 4 | 1 | 1 | `u8` | - |
| `reserved0` | 5 | 3 | 1 | `[3]u8` | - |
| `active_root_phys` | 8 | 8 | 8 | `u64` | - |
| `hardware_cr3` | 16 | 8 | 8 | `u64` | - |
| `old_cr3` | 24 | 8 | 8 | `u64` | - |
| `new_cr3` | 32 | 8 | 8 | `u64` | - |
| `page_table_blocks` | 40 | 8 | 8 | `u64` | - |
| `kernel_page_table_blocks` | 48 | 8 | 8 | `u64` | - |
| `bootloader_page_table_blocks` | 56 | 8 | 8 | `u64` | - |
| `page_table_bytes` | 64 | 8 | 8 | `u64` | - |
| `limine_old_table_frames` | 72 | 8 | 8 | `u64` | - |
| `limine_active_table_frames` | 80 | 8 | 8 | `u64` | - |
| `limine_referenced_frames` | 88 | 8 | 8 | `u64` | - |
| `limine_quarantined_frames` | 96 | 8 | 8 | `u64` | - |
| `limine_released_frames` | 104 | 8 | 8 | `u64` | - |
| `limine_retained_frames` | 112 | 8 | 8 | `u64` | - |
| `root_mismatches` | 120 | 8 | 8 | `u64` | - |
| `map_pages` | 128 | 8 | 8 | `u64` | - |
| `unmap_pages` | 136 | 8 | 8 | `u64` | - |
| `invlpg_flushes` | 144 | 8 | 8 | `u64` | - |

### `DisplayDamageRect`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `x` | 0 | 4 | 4 | `i32` | - |
| `y` | 4 | 4 | 4 | `i32` | - |
| `w` | 8 | 4 | 4 | `u32` | - |
| `h` | 12 | 4 | 4 | `u32` | - |

### `DisplayPresentCapabilities`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 2 | 2 | `u16` | - |
| `size` | 2 | 2 | 2 | `u16` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `formats` | 8 | 4 | 4 | `u32` | - |
| `max_regions` | 12 | 4 | 4 | `u32` | - |
| `tile_width` | 16 | 4 | 4 | `u32` | - |
| `tile_height` | 20 | 4 | 4 | `u32` | - |
| `backend_kind` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `backend_name` | 32 | 24 | 1 | `[24]u8` | - |
| `fallback_name` | 56 | 24 | 1 | `[24]u8` | - |

### `DisplayPresentCompletion`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 2 | 2 | `u16` | - |
| `size` | 2 | 2 | 2 | `u16` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `fence` | 8 | 8 | 8 | `u64` | - |
| `completed_fence` | 16 | 8 | 8 | `u64` | - |
| `result` | 24 | 4 | 4 | `i32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `DisplayPresentRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `format` | 12 | 4 | 4 | `u32` | - |
| `source_width` | 16 | 4 | 4 | `u32` | - |
| `source_height` | 20 | 4 | 4 | `u32` | - |
| `source_stride_pixels` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `source_generation` | 32 | 8 | 8 | `u64` | - |
| `input_tick` | 40 | 8 | 8 | `u64` | - |

### `DisplayPresentResult`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 2 | 2 | `u16` | - |
| `size` | 2 | 2 | 2 | `u16` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `source_generation` | 8 | 8 | 8 | `u64` | - |
| `present_generation` | 16 | 8 | 8 | `u64` | - |
| `fence` | 24 | 8 | 8 | `u64` | - |
| `completed_fence` | 32 | 8 | 8 | `u64` | - |
| `region_count` | 40 | 4 | 4 | `u32` | - |
| `pixel_count` | 44 | 4 | 4 | `u32` | - |
| `fallback_regions` | 48 | 4 | 4 | `u32` | - |
| `backend_error` | 52 | 4 | 4 | `i32` | - |
| `present_tick` | 56 | 8 | 8 | `u64` | - |
| `elapsed_ticks` | 64 | 8 | 8 | `u64` | - |
| `backend_name` | 72 | 24 | 1 | `[24]u8` | - |

### `DisplaySummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 200 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `flags` | 0 | 4 | 4 | `u32` | - |
| `backend_kind` | 4 | 1 | 1 | `u8` | - |
| `cache_policy` | 5 | 1 | 1 | `u8` | - |
| `bpp` | 6 | 2 | 2 | `u16` | - |
| `width` | 8 | 4 | 4 | `u32` | - |
| `height` | 12 | 4 | 4 | `u32` | - |
| `pitch` | 16 | 4 | 4 | `u32` | - |
| `last_present_reason` | 20 | 1 | 1 | `u8` | - |
| `last_present_converted` | 21 | 1 | 1 | `u8` | - |
| `reserved0` | 22 | 2 | 1 | `[2]u8` | - |
| `last_present_x` | 24 | 4 | 4 | `u32` | - |
| `last_present_y` | 28 | 4 | 4 | `u32` | - |
| `last_present_w` | 32 | 4 | 4 | `u32` | - |
| `last_present_h` | 36 | 4 | 4 | `u32` | - |
| `present_count` | 40 | 8 | 8 | `u64` | - |
| `present_pixels_total` | 48 | 8 | 8 | `u64` | - |
| `present_bytes_total` | 56 | 8 | 8 | `u64` | - |
| `last_present_pixels` | 64 | 8 | 8 | `u64` | - |
| `last_present_bytes` | 72 | 8 | 8 | `u64` | - |
| `full_present_count` | 80 | 8 | 8 | `u64` | - |
| `partial_present_count` | 88 | 8 | 8 | `u64` | - |
| `fill_present_count` | 96 | 8 | 8 | `u64` | - |
| `rect_present_count` | 104 | 8 | 8 | `u64` | - |
| `packed32_present_count` | 112 | 8 | 8 | `u64` | - |
| `xrgb32_present_count` | 120 | 8 | 8 | `u64` | - |
| `conversion_present_count` | 128 | 8 | 8 | `u64` | - |
| `backend_name` | 136 | 32 | 1 | `[32]u8` | - |
| `present_total_ticks` | 168 | 8 | 8 | `u64` | - |
| `present_max_ticks` | 176 | 8 | 8 | `u64` | - |
| `present_last_ticks` | 184 | 8 | 8 | `u64` | - |
| `present_slow_count` | 192 | 8 | 8 | `u64` | - |

### `GuiWindowInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `window_id` | 0 | 4 | 4 | `i32` | - |
| `frame_x` | 4 | 4 | 4 | `i32` | - |
| `frame_y` | 8 | 4 | 4 | `i32` | - |
| `frame_w` | 12 | 4 | 4 | `i32` | - |
| `frame_h` | 16 | 4 | 4 | `i32` | - |
| `client_x` | 20 | 4 | 4 | `i32` | - |
| `client_y` | 24 | 4 | 4 | `i32` | - |
| `client_w` | 28 | 4 | 4 | `i32` | - |
| `client_h` | 32 | 4 | 4 | `i32` | - |
| `flags` | 36 | 4 | 4 | `u32` | - |

### `GuiSize`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `w` | 0 | 4 | 4 | `i32` | - |
| `h` | 4 | 4 | 4 | `i32` | - |

### `GuiEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 4 | 4 | `u32` | - |
| `window_id` | 4 | 4 | 4 | `i32` | - |
| `x` | 8 | 4 | 4 | `i32` | - |
| `y` | 12 | 4 | 4 | `i32` | - |
| `key` | 16 | 4 | 4 | `u32` | - |
| `buttons` | 20 | 4 | 4 | `u32` | - |
| `modifiers` | 24 | 4 | 4 | `u32` | - |
| `tick` | 32 | 8 | 8 | `u64` | - |

### `PhysicalKeyEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `key` | 12 | 4 | 4 | `u32` | - |
| `modifiers` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `sequence` | 24 | 8 | 8 | `u64` | - |
| `tick` | 32 | 8 | 8 | `u64` | - |

### `GuiCommand`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 4 | 4 | `u32` | - |
| `x` | 4 | 4 | 4 | `i32` | - |
| `y` | 8 | 4 | 4 | `i32` | - |
| `w` | 12 | 4 | 4 | `u32` | - |
| `h` | 16 | 4 | 4 | `u32` | - |
| `rgb` | 20 | 4 | 4 | `u32` | - |
| `fg` | 24 | 4 | 4 | `u32` | - |
| `bg` | 28 | 4 | 4 | `u32` | - |
| `text` | 32 | 64 | 1 | `[64]u8` | - |
| `font_id` | 96 | 4 | 4 | `u32` | - |
| `flags` | 100 | 4 | 4 | `u32` | - |
| `text_w` | 104 | 4 | 4 | `u32` | - |
| `text_h` | 108 | 4 | 4 | `u32` | - |
| `baseline` | 112 | 4 | 4 | `i32` | - |
| `line_height` | 116 | 4 | 4 | `u32` | - |

### `GuiFrameCommand`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `x` | 16 | 4 | 4 | `i32` | - |
| `y` | 20 | 4 | 4 | `i32` | - |
| `w` | 24 | 4 | 4 | `u32` | - |
| `h` | 28 | 4 | 4 | `u32` | - |
| `rgb` | 32 | 4 | 4 | `u32` | - |
| `fg` | 36 | 4 | 4 | `u32` | - |
| `bg` | 40 | 4 | 4 | `u32` | - |
| `font_id` | 44 | 4 | 4 | `u32` | - |
| `text_w` | 48 | 4 | 4 | `u32` | - |
| `text_h` | 52 | 4 | 4 | `u32` | - |
| `baseline` | 56 | 4 | 4 | `i32` | - |
| `line_height` | 60 | 4 | 4 | `u32` | - |
| `resource_offset` | 64 | 8 | 8 | `u64` | - |
| `resource_bytes` | 72 | 8 | 8 | `u64` | - |
| `parameter0` | 80 | 8 | 8 | `u64` | - |
| `parameter1` | 88 | 8 | 8 | `u64` | - |

### `GuiPathSegment`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 4 | 4 | `u32` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `x1_bits` | 8 | 4 | 4 | `u32` | - |
| `y1_bits` | 12 | 4 | 4 | `u32` | - |
| `x2_bits` | 16 | 4 | 4 | `u32` | - |
| `y2_bits` | 20 | 4 | 4 | `u32` | - |
| `x3_bits` | 24 | 4 | 4 | `u32` | - |
| `y3_bits` | 28 | 4 | 4 | `u32` | - |

### `GuiShapeResource`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `geometry_kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `segment_count` | 16 | 4 | 4 | `u32` | - |
| `fill_rule` | 20 | 4 | 4 | `u32` | - |
| `line_join` | 24 | 4 | 4 | `u32` | - |
| `line_cap` | 28 | 4 | 4 | `u32` | - |
| `clip_x` | 32 | 4 | 4 | `i32` | - |
| `clip_y` | 36 | 4 | 4 | `i32` | - |
| `clip_w` | 40 | 4 | 4 | `u32` | - |
| `clip_h` | 44 | 4 | 4 | `u32` | - |
| `fill_argb` | 48 | 4 | 4 | `u32` | - |
| `stroke_argb` | 52 | 4 | 4 | `u32` | - |
| `stroke_width_bits` | 56 | 4 | 4 | `u32` | - |
| `miter_limit_bits` | 60 | 4 | 4 | `u32` | - |
| `geometry_x_bits` | 64 | 4 | 4 | `u32` | - |
| `geometry_y_bits` | 68 | 4 | 4 | `u32` | - |
| `geometry_w_bits` | 72 | 4 | 4 | `u32` | - |
| `geometry_h_bits` | 76 | 4 | 4 | `u32` | - |
| `radius_top_left_x_bits` | 80 | 4 | 4 | `u32` | - |
| `radius_top_left_y_bits` | 84 | 4 | 4 | `u32` | - |
| `radius_top_right_x_bits` | 88 | 4 | 4 | `u32` | - |
| `radius_top_right_y_bits` | 92 | 4 | 4 | `u32` | - |
| `radius_bottom_right_x_bits` | 96 | 4 | 4 | `u32` | - |
| `radius_bottom_right_y_bits` | 100 | 4 | 4 | `u32` | - |
| `radius_bottom_left_x_bits` | 104 | 4 | 4 | `u32` | - |
| `radius_bottom_left_y_bits` | 108 | 4 | 4 | `u32` | - |
| `border_top_bits` | 112 | 4 | 4 | `u32` | - |
| `border_right_bits` | 116 | 4 | 4 | `u32` | - |
| `border_bottom_bits` | 120 | 4 | 4 | `u32` | - |
| `border_left_bits` | 124 | 4 | 4 | `u32` | - |
| `shadow_argb` | 128 | 4 | 4 | `u32` | - |
| `shadow_offset_x_bits` | 132 | 4 | 4 | `u32` | - |
| `shadow_offset_y_bits` | 136 | 4 | 4 | `u32` | - |
| `shadow_spread_bits` | 140 | 4 | 4 | `u32` | - |
| `shadow_blur_bits` | 144 | 4 | 4 | `u32` | - |
| `reserved0` | 148 | 4 | 4 | `u32` | - |
| `reserved1` | 152 | 4 | 4 | `u32` | - |
| `reserved2` | 156 | 4 | 4 | `u32` | - |

### `GuiFrameGenerationInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `damage_count` | 12 | 4 | 4 | `u32` | - |
| `owner` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `generation` | 32 | 8 | 8 | `u64` | - |
| `base_generation` | 40 | 8 | 8 | `u64` | - |
| `command_count` | 48 | 8 | 8 | `u64` | - |
| `resource_bytes` | 56 | 8 | 8 | `u64` | - |
| `total_command_count` | 64 | 8 | 8 | `u64` | - |
| `total_resource_bytes` | 72 | 8 | 8 | `u64` | - |
| `chain_depth` | 80 | 4 | 4 | `u32` | - |
| `command_version` | 84 | 4 | 4 | `u32` | - |
| `command_size` | 88 | 4 | 4 | `u32` | - |
| `region_size` | 92 | 4 | 4 | `u32` | - |
| `delta_commit_count` | 96 | 8 | 8 | `u64` | - |
| `full_commit_count` | 104 | 8 | 8 | `u64` | - |
| `indexed8_command_count` | 112 | 8 | 8 | `u64` | - |
| `indexed8_resource_bytes` | 120 | 8 | 8 | `u64` | - |
| `avoided_clone_bytes` | 128 | 8 | 8 | `u64` | - |
| `generation_read_count` | 136 | 8 | 8 | `u64` | - |

### `GuiFrameInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `owner` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `committed_generation` | 32 | 8 | 8 | `u64` | - |
| `building_generation` | 40 | 8 | 8 | `u64` | - |
| `committed_command_count` | 48 | 8 | 8 | `u64` | - |
| `committed_resource_bytes` | 56 | 8 | 8 | `u64` | - |
| `building_command_count` | 64 | 8 | 8 | `u64` | - |
| `building_resource_bytes` | 72 | 8 | 8 | `u64` | - |
| `current_frame_bytes` | 80 | 8 | 8 | `u64` | - |
| `peak_frame_bytes` | 88 | 8 | 8 | `u64` | - |
| `commit_count` | 96 | 8 | 8 | `u64` | - |
| `cancel_count` | 104 | 8 | 8 | `u64` | - |
| `oom_count` | 112 | 8 | 8 | `u64` | - |
| `snapshot_read_count` | 120 | 8 | 8 | `u64` | - |
| `last_error` | 128 | 4 | 4 | `i32` | - |
| `command_version` | 132 | 4 | 4 | `u32` | - |
| `command_size` | 136 | 4 | 4 | `u32` | - |
| `reserved0` | 140 | 4 | 4 | `u32` | - |
| `reserved1` | 144 | 8 | 8 | `u64` | - |
| `reserved2` | 152 | 8 | 8 | `u64` | - |
| `reserved3` | 160 | 8 | 8 | `u64` | - |
| `reserved4` | 168 | 8 | 8 | `u64` | - |

### `GuiIndexed8Resource`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `source_x` | 8 | 4 | 4 | `u32` | - |
| `source_y` | 12 | 4 | 4 | `u32` | - |
| `source_w` | 16 | 4 | 4 | `u32` | - |
| `source_h` | 20 | 4 | 4 | `u32` | - |
| `guest_w` | 24 | 4 | 4 | `u32` | - |
| `guest_h` | 28 | 4 | 4 | `u32` | - |
| `viewport_x` | 32 | 4 | 4 | `i32` | - |
| `viewport_y` | 36 | 4 | 4 | `i32` | - |
| `viewport_w` | 40 | 4 | 4 | `u32` | - |
| `viewport_h` | 44 | 4 | 4 | `u32` | - |
| `palette_entries` | 48 | 4 | 4 | `u32` | - |
| `palette_offset` | 52 | 4 | 4 | `u32` | - |
| `pixels_offset` | 56 | 4 | 4 | `u32` | - |
| `pixel_stride` | 60 | 4 | 4 | `u32` | - |

### `GuiFontInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 316 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `kind` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `weight` | 12 | 4 | 4 | `u32` | - |
| `style_flags` | 16 | 4 | 4 | `u32` | - |
| `charset_flags` | 20 | 4 | 4 | `u32` | - |
| `width` | 24 | 4 | 4 | `u32` | - |
| `height` | 28 | 4 | 4 | `u32` | - |
| `max_advance` | 32 | 4 | 4 | `u32` | - |
| `line_height` | 36 | 4 | 4 | `u32` | - |
| `baseline` | 40 | 4 | 4 | `i32` | - |
| `glyph_count` | 44 | 4 | 4 | `u32` | - |
| `strike_count` | 48 | 4 | 4 | `u32` | - |
| `path` | 52 | 96 | 1 | `[96]u8` | - |
| `family` | 148 | 40 | 1 | `[40]u8` | - |
| `face` | 188 | 40 | 1 | `[40]u8` | - |
| `style` | 228 | 40 | 1 | `[40]u8` | - |
| `status` | 268 | 48 | 1 | `[48]u8` | - |

### `GuiTextMetrics`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `width` | 0 | 4 | 4 | `u32` | - |
| `height` | 4 | 4 | 4 | `u32` | - |
| `line_height` | 8 | 4 | 4 | `u32` | - |
| `baseline` | 12 | 4 | 4 | `i32` | - |
| `visible_bytes` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |

### `ClipboardInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `capacity` | 0 | 4 | 4 | `u32` | - |
| `length` | 4 | 4 | 4 | `u32` | - |
| `revision` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |

### `RemoteFrameInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `format` | 12 | 4 | 4 | `u32` | - |
| `width` | 16 | 4 | 4 | `u32` | - |
| `height` | 20 | 4 | 4 | `u32` | - |
| `stride_pixels` | 24 | 4 | 4 | `u32` | - |
| `bytes_per_pixel` | 28 | 4 | 4 | `u32` | - |
| `revision` | 32 | 4 | 4 | `u32` | - |
| `frame_pixels` | 36 | 4 | 4 | `u32` | - |
| `frame_bytes` | 40 | 4 | 4 | `u32` | - |
| `dirty_x` | 44 | 4 | 4 | `i32` | - |
| `dirty_y` | 48 | 4 | 4 | `i32` | - |
| `dirty_w` | 52 | 4 | 4 | `u32` | - |
| `dirty_h` | 56 | 4 | 4 | `u32` | - |
| `cursor_x` | 60 | 4 | 4 | `i32` | - |
| `cursor_y` | 64 | 4 | 4 | `i32` | - |
| `cursor_flags` | 68 | 4 | 4 | `u32` | - |
| `reserved0` | 72 | 4 | 4 | `u32` | - |
| `reserved1` | 76 | 4 | 4 | `u32` | - |

### `RemoteFrameMapInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `pixels_addr` | 0 | 8 | 8 | `u64` | - |
| `capacity_pixels` | 8 | 8 | 8 | `u64` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `reserved` | 24 | 8 | 8 | `u64` | - |

### `RemoteInputEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `sequence` | 16 | 4 | 4 | `u32` | - |
| `modifiers` | 20 | 4 | 4 | `u32` | - |
| `key` | 24 | 4 | 4 | `u32` | - |
| `scancode` | 28 | 4 | 4 | `u32` | - |
| `x` | 32 | 4 | 4 | `i32` | - |
| `y` | 36 | 4 | 4 | `i32` | - |
| `wheel` | 40 | 4 | 4 | `i32` | - |
| `buttons` | 44 | 4 | 4 | `u32` | - |
| `timestamp_ticks` | 48 | 8 | 8 | `u64` | - |
| `reserved0` | 56 | 4 | 4 | `u32` | - |
| `reserved1` | 60 | 4 | 4 | `u32` | - |

### `RemoteInputStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `capacity` | 12 | 4 | 4 | `u32` | - |
| `pending` | 16 | 4 | 4 | `u32` | - |
| `dropped` | 20 | 4 | 4 | `u32` | - |
| `pushed` | 24 | 4 | 4 | `u32` | - |
| `polled` | 28 | 4 | 4 | `u32` | - |
| `last_sequence` | 32 | 4 | 4 | `u32` | - |
| `last_kind` | 36 | 4 | 4 | `u32` | - |
| `last_buttons` | 40 | 4 | 4 | `u32` | - |
| `last_key` | 44 | 4 | 4 | `u32` | - |
| `last_x` | 48 | 4 | 4 | `i32` | - |
| `last_y` | 52 | 4 | 4 | `i32` | - |
| `last_wheel` | 56 | 4 | 4 | `i32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |

### `ProgramHostLaunchRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 264 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `path` | 0 | 128 | 1 | `[128]u8` | - |
| `args` | 128 | 128 | 1 | `[128]u8` | - |
| `policy` | 256 | 4 | 4 | `u32` | - |
| `reserved` | 260 | 4 | 4 | `u32` | - |

### `ConsoleState`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `fg` | 0 | 4 | 4 | `u32` | - |
| `bg` | 4 | 4 | 4 | `u32` | - |
| `clear_count` | 8 | 4 | 4 | `u32` | - |
| `cursor_x` | 12 | 4 | 4 | `i32` | - |
| `cursor_y` | 16 | 4 | 4 | `i32` | - |
| `cursor_visible` | 20 | 1 | 1 | `u8` | - |
| `reserved` | 21 | 3 | 1 | `[3]u8` | - |
| `cols` | 24 | 4 | 4 | `u32` | - |
| `rows` | 28 | 4 | 4 | `u32` | - |
| `stdin_pending` | 32 | 4 | 4 | `u32` | - |
| `stdin_bytes` | 36 | 4 | 4 | `u32` | - |
| `stdout_bytes` | 40 | 4 | 4 | `u32` | - |
| `stderr_bytes` | 44 | 4 | 4 | `u32` | - |
| `output_capacity` | 48 | 4 | 4 | `u32` | - |
| `output_len` | 52 | 4 | 4 | `u32` | - |
| `scrollback_lines` | 56 | 4 | 4 | `u32` | - |
| `output_dropped_bytes` | 60 | 4 | 4 | `u32` | - |

### `KernelVersion`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `major` | 8 | 4 | 4 | `u32` | - |
| `minor` | 12 | 4 | 4 | `u32` | - |
| `patch` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |

### `TimeState`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `valid` | 0 | 1 | 1 | `u8` | - |
| `century_source` | 1 | 1 | 1 | `u8` | - |
| `weekday` | 2 | 1 | 1 | `u8` | - |
| `reserved0` | 3 | 1 | 1 | `u8` | - |
| `year` | 4 | 2 | 2 | `u16` | - |
| `month` | 6 | 1 | 1 | `u8` | - |
| `day` | 7 | 1 | 1 | `u8` | - |
| `hour` | 8 | 1 | 1 | `u8` | - |
| `minute` | 9 | 1 | 1 | `u8` | - |
| `second` | 10 | 1 | 1 | `u8` | - |
| `reserved1` | 11 | 1 | 1 | `u8` | - |
| `seconds_since_midnight` | 12 | 4 | 4 | `u32` | - |
| `monotonic_ticks` | 16 | 8 | 8 | `u64` | - |
| `monotonic_hz` | 24 | 4 | 4 | `u32` | - |
| `monotonic_backend` | 28 | 4 | 4 | `u32` | - |

### `MonotonicClockInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `source` | 12 | 4 | 4 | `u32` | - |
| `generation` | 16 | 4 | 4 | `u32` | - |
| `event_backend` | 20 | 4 | 4 | `u32` | - |
| `instant_ns` | 24 | 8 | 8 | `u64` | - |
| `frequency_hz` | 32 | 8 | 8 | `u64` | - |
| `resolution_ns` | 40 | 8 | 8 | `u64` | - |
| `source_frequency_hz` | 48 | 8 | 8 | `u64` | - |
| `event_frequency_numerator` | 56 | 8 | 8 | `u64` | - |
| `event_frequency_denominator` | 64 | 8 | 8 | `u64` | - |
| `event_requested_hz` | 72 | 4 | 4 | `u32` | - |
| `event_effective_hz` | 76 | 4 | 4 | `u32` | - |

### `KeyboardLayoutInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 36 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `name` | 0 | 16 | 1 | `[16]u8` | - |
| `display` | 16 | 8 | 1 | `[8]u8` | - |
| `index` | 24 | 4 | 4 | `u32` | - |
| `count` | 28 | 4 | 4 | `u32` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |

### `DriveInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `mounted` | 0 | 1 | 1 | `u8` | - |
| `letter` | 1 | 1 | 1 | `u8` | - |
| `kind` | 2 | 1 | 1 | `u8` | - |
| `role` | 3 | 1 | 1 | `u8` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `bytes` | 8 | 8 | 8 | `u64` | - |
| `name` | 16 | 16 | 1 | `[16]u8` | - |
| `free_bytes` | 32 | 8 | 8 | `u64` | - |
| `total_clusters` | 40 | 4 | 4 | `u32` | - |
| `free_clusters` | 44 | 4 | 4 | `u32` | - |
| `cluster_bytes` | 48 | 4 | 4 | `u32` | - |

### `FileInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `exists` | 0 | 1 | 1 | `u8` | - |
| `is_dir` | 1 | 1 | 1 | `u8` | - |
| `attr` | 2 | 1 | 1 | `u8` | - |
| `drive` | 3 | 1 | 1 | `u8` | - |
| `size` | 8 | 8 | 8 | `u64` | - |
| `first_cluster` | 16 | 4 | 4 | `u32` | - |
| `created_time` | 20 | 2 | 2 | `u16` | - |
| `created_date` | 22 | 2 | 2 | `u16` | - |
| `access_date` | 24 | 2 | 2 | `u16` | - |
| `modified_time` | 26 | 2 | 2 | `u16` | - |
| `modified_date` | 28 | 2 | 2 | `u16` | - |
| `reserved` | 30 | 2 | 2 | `u16` | - |
| `name` | 32 | 64 | 1 | `[64]u8` | - |

### `BootLogInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `capacity` | 0 | 4 | 4 | `u32` | - |
| `length` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `total_written` | 16 | 8 | 8 | `u64` | - |
| `dropped_bytes` | 24 | 8 | 8 | `u64` | - |

### `DeviceInventorySummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 20 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `total` | 0 | 4 | 4 | `u32` | - |
| `with_driver` | 4 | 4 | 4 | `u32` | - |
| `without_driver` | 8 | 4 | 4 | `u32` | - |
| `unknown` | 12 | 4 | 4 | `u32` | - |
| `truncated` | 16 | 1 | 1 | `u8` | - |
| `reserved` | 17 | 3 | 1 | `[3]u8` | - |

### `DeviceInventoryRecord`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 224 / 2

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `binding` | 0 | 1 | 1 | `u8` | - |
| `bus` | 1 | 1 | 1 | `u8` | - |
| `flags` | 2 | 2 | 2 | `u16` | - |
| `bus_no` | 4 | 1 | 1 | `u8` | - |
| `device_no` | 5 | 1 | 1 | `u8` | - |
| `function_no` | 6 | 1 | 1 | `u8` | - |
| `class_code` | 7 | 1 | 1 | `u8` | - |
| `subclass` | 8 | 1 | 1 | `u8` | - |
| `prog_if` | 9 | 1 | 1 | `u8` | - |
| `reserved0` | 10 | 2 | 2 | `u16` | - |
| `vendor_id` | 12 | 2 | 2 | `u16` | - |
| `device_id` | 14 | 2 | 2 | `u16` | - |
| `name` | 16 | 48 | 1 | `[48]u8` | - |
| `driver` | 64 | 32 | 1 | `[32]u8` | - |
| `status` | 96 | 32 | 1 | `[32]u8` | - |
| `note` | 128 | 96 | 1 | `[96]u8` | - |

### `HardwareSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `flags` | 0 | 4 | 4 | `u32` | - |
| `acpi_tables` | 4 | 4 | 4 | `u32` | - |
| `acpi_invalid_tables` | 8 | 4 | 4 | `u32` | - |
| `pcie_devices` | 12 | 4 | 4 | `u32` | - |
| `legacy_pci_devices` | 16 | 4 | 4 | `u32` | - |
| `storage_controllers` | 20 | 4 | 4 | `u32` | - |
| `network_controllers` | 24 | 4 | 4 | `u32` | - |
| `display_controllers` | 28 | 4 | 4 | `u32` | - |
| `usb_controllers` | 32 | 4 | 4 | `u32` | - |
| `hda_controllers` | 36 | 4 | 4 | `u32` | - |
| `block_devices` | 40 | 4 | 4 | `u32` | - |
| `usb_devices` | 44 | 4 | 4 | `u32` | - |
| `usb_configured` | 48 | 4 | 4 | `u32` | - |
| `driver_records` | 52 | 4 | 4 | `u32` | - |
| `protocol_records` | 56 | 4 | 4 | `u32` | - |
| `irq_controller` | 60 | 1 | 1 | `u8` | - |
| `timer_backend` | 61 | 1 | 1 | `u8` | - |
| `reserved0` | 62 | 2 | 2 | `u16` | - |
| `lapic_count` | 64 | 4 | 4 | `u32` | - |
| `ioapic_count` | 68 | 4 | 4 | `u32` | - |
| `iso_count` | 72 | 4 | 4 | `u32` | - |
| `hpet_frequency_hz` | 80 | 8 | 8 | `u64` | - |
| `cpu_logical_processors` | 88 | 4 | 4 | `u32` | - |
| `cpu_physical_address_bits` | 92 | 1 | 1 | `u8` | - |
| `cpu_virtual_address_bits` | 93 | 1 | 1 | `u8` | - |
| `reserved1` | 94 | 2 | 2 | `u16` | - |

### `ProtocolStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `state` | 0 | 4 | 4 | `u32` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `last_error` | 8 | 4 | 4 | `i32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `note` | 16 | 64 | 1 | `[64]u8` | - |

### `ProtocolBuffer`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `data` | 0 | 8 | 8 | `?*anyopaque` | inout, nullable=true, length=len, borrowed, lifetime=buffer |
| `len` | 8 | 4 | 4 | `u32` | - |
| `capacity` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |

### `SerialLinkStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 736 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `present` | 0 | 4 | 4 | `u32` | - |
| `initialized` | 4 | 4 | 4 | `u32` | - |
| `port_base` | 8 | 2 | 2 | `u16` | - |
| `version` | 10 | 1 | 1 | `u8` | - |
| `reserved0` | 11 | 1 | 1 | `u8` | - |
| `max_payload` | 12 | 2 | 2 | `u16` | - |
| `last_type` | 14 | 1 | 1 | `u8` | - |
| `reserved1` | 15 | 1 | 1 | `u8` | - |
| `last_payload_len` | 16 | 2 | 2 | `u16` | - |
| `last_message_len` | 18 | 2 | 2 | `u16` | - |
| `reserved2` | 20 | 4 | 4 | `u32` | - |
| `loopback_tests` | 24 | 8 | 8 | `u64` | - |
| `host_tests` | 32 | 8 | 8 | `u64` | - |
| `message_tx` | 40 | 8 | 8 | `u64` | - |
| `message_rx` | 48 | 8 | 8 | `u64` | - |
| `tx_skipped` | 56 | 8 | 8 | `u64` | - |
| `tx_frames` | 64 | 8 | 8 | `u64` | - |
| `tx_bytes` | 72 | 8 | 8 | `u64` | - |
| `rx_frames` | 80 | 8 | 8 | `u64` | - |
| `rx_bytes` | 88 | 8 | 8 | `u64` | - |
| `polls` | 96 | 8 | 8 | `u64` | - |
| `bad_magic` | 104 | 8 | 8 | `u64` | - |
| `bad_version` | 112 | 8 | 8 | `u64` | - |
| `bad_length` | 120 | 8 | 8 | `u64` | - |
| `checksum_errors` | 128 | 8 | 8 | `u64` | - |
| `overflows` | 136 | 8 | 8 | `u64` | - |
| `timeouts` | 144 | 8 | 8 | `u64` | - |
| `r4p_build` | 152 | 8 | 8 | `u64` | - |
| `r4p_parse` | 160 | 8 | 8 | `u64` | - |
| `r4p_self` | 168 | 8 | 8 | `u64` | - |
| `r4p_fallbacks` | 176 | 8 | 8 | `u64` | - |
| `r4p_dispatch_failures` | 184 | 8 | 8 | `u64` | - |
| `last_payload` | 192 | 256 | 1 | `[256]u8` | - |
| `last_message` | 448 | 256 | 1 | `[256]u8` | - |
| `last_error` | 704 | 32 | 1 | `[32]u8` | - |

### `SerialLinkMessage`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 260 / 2

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `len` | 0 | 2 | 2 | `u16` | - |
| `reserved` | 2 | 2 | 2 | `u16` | - |
| `data` | 4 | 256 | 1 | `[256]u8` | - |

### `RegistryBatchOperation`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `operation` | 0 | 2 | 2 | `u16` | - |
| `value_type` | 2 | 2 | 2 | `u16` | - |
| `key_path_offset` | 4 | 4 | 4 | `u32` | - |
| `key_path_len` | 8 | 4 | 4 | `u32` | - |
| `value_name_offset` | 12 | 4 | 4 | `u32` | - |
| `value_name_len` | 16 | 4 | 4 | `u32` | - |
| `data_offset` | 20 | 4 | 4 | `u32` | - |
| `data_len` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `RegistryBatchResult`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation_before` | 8 | 8 | 8 | `u64` | - |
| `generation_after` | 16 | 8 | 8 | `u64` | - |
| `operation_count` | 24 | 4 | 4 | `u32` | - |
| `failed_index` | 28 | 4 | 4 | `u32` | - |
| `status` | 32 | 4 | 4 | `i32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |

### `RegistrySnapshotCursor`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `key_index` | 16 | 4 | 4 | `u32` | - |
| `kind` | 20 | 4 | 4 | `u32` | - |
| `next_index` | 24 | 4 | 4 | `u32` | - |
| `total` | 28 | 4 | 4 | `u32` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `restarts` | 36 | 4 | 4 | `u32` | - |
| `reserved0` | 40 | 8 | 8 | `u64` | - |

### `RegistrySnapshotEntry`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 2 | 2 | `u16` | - |
| `value_type` | 2 | 2 | 2 | `u16` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `data_offset` | 8 | 4 | 4 | `u32` | - |
| `data_len` | 12 | 4 | 4 | `u32` | - |
| `name` | 16 | 64 | 1 | `[64]u8` | - |

### `RegistrySnapshotPageInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `total` | 16 | 4 | 4 | `u32` | - |
| `returned` | 20 | 4 | 4 | `u32` | - |
| `next_index` | 24 | 4 | 4 | `u32` | - |
| `data_bytes` | 28 | 4 | 4 | `u32` | - |
| `kind` | 32 | 4 | 4 | `u32` | - |
| `status` | 36 | 4 | 4 | `i32` | - |
| `reserved0` | 40 | 8 | 8 | `u64` | - |

### `RegistryKeyInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `child_count` | 0 | 4 | 4 | `u32` | - |
| `value_count` | 4 | 4 | 4 | `u32` | - |
| `name` | 8 | 64 | 1 | `[64]u8` | - |

### `RegistryValueInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `value_type` | 0 | 2 | 2 | `u16` | - |
| `reserved` | 2 | 2 | 2 | `u16` | - |
| `data_len` | 4 | 4 | 4 | `u32` | - |
| `name` | 8 | 64 | 1 | `[64]u8` | - |

### `ServiceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 216 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `handle` | 0 | 4 | 4 | `u32` | - |
| `state` | 4 | 4 | 4 | `u32` | - |
| `start_mode` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `instance_id` | 16 | 4 | 4 | `u32` | - |
| `exit_code` | 20 | 4 | 4 | `i32` | - |
| `restart_count` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `start_tick` | 32 | 8 | 8 | `u64` | - |
| `uptime_ticks` | 40 | 8 | 8 | `u64` | - |
| `requests` | 48 | 8 | 8 | `u64` | - |
| `responses` | 56 | 8 | 8 | `u64` | - |
| `drops` | 64 | 8 | 8 | `u64` | - |
| `queue_depth` | 72 | 4 | 4 | `u32` | - |
| `queue_used` | 76 | 4 | 4 | `u32` | - |
| `queue_high_water` | 80 | 4 | 4 | `u32` | - |
| `active_workers` | 84 | 4 | 4 | `u32` | - |
| `max_active_workers` | 88 | 4 | 4 | `u32` | - |
| `open_handles` | 92 | 4 | 4 | `u32` | - |
| `busy_rejections` | 96 | 8 | 8 | `u64` | - |
| `timeouts` | 104 | 8 | 8 | `u64` | - |
| `cancellations` | 112 | 8 | 8 | `u64` | - |
| `name` | 120 | 32 | 1 | `[32]u8` | - |
| `last_error` | 152 | 64 | 1 | `[64]u8` | - |

### `ServiceDetail`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 520 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `info` | 0 | 216 | 8 | `r4os.abi.ServiceInfo` | - |
| `path` | 216 | 128 | 1 | `[128]u8` | - |
| `args` | 344 | 96 | 1 | `[96]u8` | - |
| `description` | 440 | 80 | 1 | `[80]u8` | - |

### `ServiceMessageHeader`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 28 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `op` | 6 | 2 | 2 | `u16` | - |
| `request_id` | 8 | 4 | 4 | `u32` | - |
| `client_id` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `payload_len` | 20 | 2 | 2 | `u16` | - |
| `reserved0` | 22 | 2 | 2 | `u16` | - |
| `status` | 24 | 4 | 4 | `i32` | - |

### `IpcSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `max_channels` | 0 | 4 | 4 | `u32` | - |
| `active_channels` | 4 | 4 | 4 | `u32` | - |
| `max_message_size` | 8 | 4 | 4 | `u32` | - |
| `queue_depth` | 12 | 4 | 4 | `u32` | - |
| `sends` | 16 | 8 | 8 | `u64` | - |
| `receives` | 24 | 8 | 8 | `u64` | - |
| `drops` | 32 | 8 | 8 | `u64` | - |
| `errors` | 40 | 8 | 8 | `u64` | - |
| `echo_tests` | 48 | 8 | 8 | `u64` | - |

### `IpcPerformanceSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 240 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `worker_started` | 8 | 4 | 4 | `u32` | - |
| `worker_task_id` | 12 | 4 | 4 | `u32` | - |
| `active_channels` | 16 | 4 | 4 | `u32` | - |
| `queue_used` | 20 | 4 | 4 | `u32` | - |
| `queue_ready` | 24 | 4 | 4 | `u32` | - |
| `queue_running` | 28 | 4 | 4 | `u32` | - |
| `queue_limit` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `handler_queued` | 40 | 8 | 8 | `u64` | - |
| `handler_completed` | 48 | 8 | 8 | `u64` | - |
| `handler_failures` | 56 | 8 | 8 | `u64` | - |
| `handler_direct` | 64 | 8 | 8 | `u64` | - |
| `handler_waits` | 72 | 8 | 8 | `u64` | - |
| `handler_wait_timeouts` | 80 | 8 | 8 | `u64` | - |
| `handler_queue_ns` | 88 | 8 | 8 | `u64` | - |
| `handler_queue_max_ns` | 96 | 8 | 8 | `u64` | - |
| `handler_run_ns` | 104 | 8 | 8 | `u64` | - |
| `handler_run_max_ns` | 112 | 8 | 8 | `u64` | - |
| `handler_e2e_ns` | 120 | 8 | 8 | `u64` | - |
| `handler_e2e_max_ns` | 128 | 8 | 8 | `u64` | - |
| `request_bytes` | 136 | 8 | 8 | `u64` | - |
| `response_bytes` | 144 | 8 | 8 | `u64` | - |
| `payload_copy_bytes` | 152 | 8 | 8 | `u64` | - |
| `payload_clear_bytes` | 160 | 8 | 8 | `u64` | - |
| `queue_full` | 168 | 8 | 8 | `u64` | - |
| `queue_empty` | 176 | 8 | 8 | `u64` | - |
| `admission_waits` | 184 | 8 | 8 | `u64` | - |
| `admission_timeouts` | 192 | 8 | 8 | `u64` | - |
| `recv_buffer_small` | 200 | 8 | 8 | `u64` | - |
| `response_search_slots` | 208 | 8 | 8 | `u64` | - |
| `stale_drops` | 216 | 8 | 8 | `u64` | - |
| `lock_contentions` | 224 | 8 | 8 | `u64` | - |
| `irq_denied` | 232 | 8 | 8 | `u64` | - |

### `IpcChannelInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `active` | 4 | 4 | 4 | `u32` | - |
| `queued` | 8 | 4 | 4 | `u32` | - |
| `queue_depth` | 12 | 4 | 4 | `u32` | - |
| `max_message_size` | 16 | 4 | 4 | `u32` | - |
| `has_handler` | 20 | 4 | 4 | `u32` | - |
| `reserved0` | 24 | 4 | 4 | `u32` | - |
| `reserved1` | 28 | 4 | 4 | `u32` | - |
| `opens` | 32 | 8 | 8 | `u64` | - |
| `closes` | 40 | 8 | 8 | `u64` | - |
| `sends` | 48 | 8 | 8 | `u64` | - |
| `receives` | 56 | 8 | 8 | `u64` | - |
| `drops` | 64 | 8 | 8 | `u64` | - |
| `name` | 72 | 16 | 1 | `[16]u8` | - |

### `TcpSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `max_connections` | 0 | 4 | 4 | `u32` | - |
| `active_connections` | 4 | 4 | 4 | `u32` | - |
| `buffer_size` | 8 | 4 | 4 | `u32` | - |
| `syn_tx` | 16 | 8 | 8 | `u64` | - |
| `synack_rx` | 24 | 8 | 8 | `u64` | - |
| `ack_tx` | 32 | 8 | 8 | `u64` | - |
| `data_tx` | 40 | 8 | 8 | `u64` | - |
| `data_rx` | 48 | 8 | 8 | `u64` | - |
| `fin_tx` | 56 | 8 | 8 | `u64` | - |
| `rst_rx` | 64 | 8 | 8 | `u64` | - |
| `checksum_errors` | 72 | 8 | 8 | `u64` | - |
| `timeouts` | 80 | 8 | 8 | `u64` | - |
| `self_tests` | 88 | 8 | 8 | `u64` | - |
| `active_listeners` | 96 | 4 | 4 | `u32` | - |
| `synack_tx` | 104 | 8 | 8 | `u64` | - |
| `listen_syn_rx` | 112 | 8 | 8 | `u64` | - |
| `accepts` | 120 | 8 | 8 | `u64` | - |
| `retransmits` | 128 | 8 | 8 | `u64` | - |
| `rx_drops` | 136 | 8 | 8 | `u64` | - |
| `last_source_port` | 144 | 2 | 2 | `u16` | - |
| `last_dest_port` | 146 | 2 | 2 | `u16` | - |
| `last_seq` | 148 | 4 | 4 | `u32` | - |
| `last_ack` | 152 | 4 | 4 | `u32` | - |
| `last_payload_len` | 156 | 4 | 4 | `u32` | - |

### `TcpConnectionInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `state` | 4 | 1 | 1 | `u8` | - |
| `local_port` | 6 | 2 | 2 | `u16` | - |
| `remote_port` | 8 | 2 | 2 | `u16` | - |
| `remote_ip` | 10 | 4 | 1 | `[4]u8` | - |
| `tx_bytes` | 16 | 8 | 8 | `u64` | - |
| `rx_bytes` | 24 | 8 | 8 | `u64` | - |
| `pending_rx` | 32 | 4 | 4 | `u32` | - |
| `retransmits` | 36 | 4 | 4 | `u32` | - |
| `rx_window` | 40 | 4 | 4 | `u32` | - |
| `tx_window` | 44 | 4 | 4 | `u32` | - |
| `tx_ack` | 48 | 4 | 4 | `u32` | - |
| `rx_drops` | 52 | 4 | 4 | `u32` | - |
| `seq` | 56 | 4 | 4 | `u32` | - |
| `ack` | 60 | 4 | 4 | `u32` | - |
| `last_seq` | 64 | 4 | 4 | `u32` | - |
| `last_ack` | 68 | 4 | 4 | `u32` | - |
| `last_flags` | 72 | 2 | 2 | `u16` | - |
| `last_payload_len` | 74 | 2 | 2 | `u16` | - |

### `TcpAcceptResult`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `conn_id` | 0 | 4 | 4 | `u32` | - |
| `bytes` | 4 | 4 | 4 | `u32` | - |

### `NetIpv4Packet`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `source_ip` | 0 | 4 | 1 | `[4]u8` | - |
| `dest_ip` | 4 | 4 | 1 | `[4]u8` | - |
| `protocol` | 8 | 1 | 1 | `u8` | - |
| `truncated` | 9 | 1 | 1 | `u8` | - |
| `reserved` | 10 | 2 | 2 | `u16` | - |
| `payload_len` | 12 | 4 | 4 | `u32` | - |

### `NetConfigSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `local_ip` | 0 | 4 | 1 | `[4]u8` | - |
| `netmask` | 4 | 4 | 1 | `[4]u8` | - |
| `gateway_ip` | 8 | 4 | 1 | `[4]u8` | - |
| `dns_ip` | 12 | 4 | 1 | `[4]u8` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `adapter_count` | 20 | 4 | 4 | `u32` | - |
| `invalid_options` | 24 | 4 | 4 | `u32` | - |
| `source` | 28 | 16 | 1 | `[16]u8` | - |
| `adapter_name` | 44 | 32 | 1 | `[32]u8` | - |
| `link` | 76 | 12 | 1 | `[12]u8` | - |
| `last_error` | 88 | 32 | 1 | `[32]u8` | - |
| `mac` | 120 | 6 | 1 | `[6]u8` | - |
| `mtu` | 126 | 2 | 2 | `u16` | - |

### `NetConfigRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 68 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `local_ip` | 0 | 16 | 1 | `[16]u8` | - |
| `netmask` | 16 | 16 | 1 | `[16]u8` | - |
| `gateway_ip` | 32 | 16 | 1 | `[16]u8` | - |
| `dns_ip` | 48 | 16 | 1 | `[16]u8` | - |
| `flags` | 64 | 4 | 4 | `u32` | - |

### `DhcpStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `discover_tx` | 0 | 8 | 8 | `u64` | - |
| `offer_rx` | 8 | 8 | 8 | `u64` | - |
| `request_tx` | 16 | 8 | 8 | `u64` | - |
| `ack_rx` | 24 | 8 | 8 | `u64` | - |
| `nak_rx` | 32 | 8 | 8 | `u64` | - |
| `release_tx` | 40 | 8 | 8 | `u64` | - |
| `retries` | 48 | 8 | 8 | `u64` | - |
| `timeouts` | 56 | 8 | 8 | `u64` | - |
| `release_errors` | 64 | 8 | 8 | `u64` | - |
| `malformed` | 72 | 8 | 8 | `u64` | - |
| `self_tests` | 80 | 8 | 8 | `u64` | - |
| `xid` | 88 | 4 | 4 | `u32` | - |
| `offered_ip` | 92 | 4 | 1 | `[4]u8` | - |
| `server_ip` | 96 | 4 | 1 | `[4]u8` | - |
| `netmask` | 100 | 4 | 1 | `[4]u8` | - |
| `gateway_ip` | 104 | 4 | 1 | `[4]u8` | - |
| `dns_ip` | 108 | 4 | 1 | `[4]u8` | - |
| `lease_seconds` | 112 | 4 | 4 | `u32` | - |
| `renew_seconds` | 116 | 4 | 4 | `u32` | - |
| `rebind_seconds` | 120 | 4 | 4 | `u32` | - |
| `flags` | 124 | 4 | 4 | `u32` | - |
| `last_attempt` | 128 | 1 | 1 | `u8` | - |
| `last_type` | 129 | 1 | 1 | `u8` | - |
| `runtime_state` | 130 | 2 | 2 | `u16` | - |
| `last_error` | 132 | 32 | 1 | `[32]u8` | - |

### `NetDetailProtocolRuntime`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `active_r4p` | 0 | 1 | 1 | `u8` | - |
| `r4p_state` | 1 | 1 | 1 | `u8` | - |
| `builtin_fallback` | 2 | 1 | 1 | `u8` | - |
| `fallback_policy` | 3 | 1 | 1 | `u8` | - |
| `fallback_decision` | 4 | 1 | 1 | `u8` | - |
| `reserved0` | 5 | 3 | 1 | `[3]u8` | - |
| `r4p_rx` | 8 | 8 | 8 | `u64` | - |
| `r4p_tx` | 16 | 8 | 8 | `u64` | - |
| `r4p_control` | 24 | 8 | 8 | `u64` | - |
| `r4p_build` | 32 | 8 | 8 | `u64` | - |
| `r4p_classify` | 40 | 8 | 8 | `u64` | - |
| `fallbacks` | 48 | 8 | 8 | `u64` | - |
| `dispatch_failures` | 56 | 8 | 8 | `u64` | - |

### `NetDetailAdapter`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 312 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `index` | 0 | 4 | 4 | `u32` | - |
| `count` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `lifecycle` | 12 | 4 | 4 | `u32` | - |
| `bus_no` | 16 | 1 | 1 | `u8` | - |
| `device_no` | 17 | 1 | 1 | `u8` | - |
| `function_no` | 18 | 1 | 1 | `u8` | - |
| `class_code` | 19 | 1 | 1 | `u8` | - |
| `subclass` | 20 | 1 | 1 | `u8` | - |
| `prog_if` | 21 | 1 | 1 | `u8` | - |
| `irq_line` | 22 | 1 | 1 | `u8` | - |
| `irq_pin` | 23 | 1 | 1 | `u8` | - |
| `irq_mode` | 24 | 1 | 1 | `u8` | - |
| `irq_registered` | 25 | 1 | 1 | `u8` | - |
| `reserved0` | 26 | 1 | 1 | `u8` | - |
| `vendor_id` | 28 | 2 | 2 | `u16` | - |
| `device_id` | 30 | 2 | 2 | `u16` | - |
| `mac` | 32 | 6 | 1 | `[6]u8` | - |
| `mtu` | 38 | 2 | 2 | `u16` | - |
| `name` | 40 | 32 | 1 | `[32]u8` | - |
| `driver` | 72 | 32 | 1 | `[32]u8` | - |
| `link` | 104 | 12 | 1 | `[12]u8` | - |
| `state` | 116 | 16 | 1 | `[16]u8` | - |
| `last_error` | 132 | 32 | 1 | `[32]u8` | - |
| `registered_tick` | 168 | 8 | 8 | `u64` | - |
| `state_changed_tick` | 176 | 8 | 8 | `u64` | - |
| `rx_packets` | 184 | 8 | 8 | `u64` | - |
| `tx_packets` | 192 | 8 | 8 | `u64` | - |
| `rx_bytes` | 200 | 8 | 8 | `u64` | - |
| `tx_bytes` | 208 | 8 | 8 | `u64` | - |
| `drops` | 216 | 8 | 8 | `u64` | - |
| `errors` | 224 | 8 | 8 | `u64` | - |
| `resets` | 232 | 8 | 8 | `u64` | - |
| `backend_rx_packets` | 240 | 8 | 8 | `u64` | - |
| `backend_tx_packets` | 248 | 8 | 8 | `u64` | - |
| `backend_drops` | 256 | 8 | 8 | `u64` | - |
| `backend_errors` | 264 | 8 | 8 | `u64` | - |
| `irq_count` | 272 | 8 | 8 | `u64` | - |
| `irq_handled` | 280 | 8 | 8 | `u64` | - |
| `poll_count` | 288 | 8 | 8 | `u64` | - |
| `poll_fallbacks` | 296 | 8 | 8 | `u64` | - |
| `last_isr` | 304 | 2 | 2 | `u16` | - |
| `dhcp_retry_round` | 306 | 2 | 2 | `u16` | - |

### `NetDetailEthernet`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `rx` | 0 | 8 | 8 | `u64` | - |
| `tx` | 8 | 8 | 8 | `u64` | - |
| `broadcast` | 16 | 8 | 8 | `u64` | - |
| `own_unicast` | 24 | 8 | 8 | `u64` | - |
| `dropped_short` | 32 | 8 | 8 | `u64` | - |
| `dropped_filter` | 40 | 8 | 8 | `u64` | - |
| `unknown_ethertype` | 48 | 8 | 8 | `u64` | - |
| `test_frames` | 56 | 8 | 8 | `u64` | - |
| `last_ethertype` | 64 | 2 | 2 | `u16` | - |
| `reserved` | 66 | 2 | 2 | `u16` | - |
| `last_error` | 68 | 24 | 1 | `[24]u8` | - |

### `NetDetailArp`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `requests_tx` | 0 | 8 | 8 | `u64` | - |
| `replies_tx` | 8 | 8 | 8 | `u64` | - |
| `replies_rx` | 16 | 8 | 8 | `u64` | - |
| `requests_rx` | 24 | 8 | 8 | `u64` | - |
| `malformed` | 32 | 8 | 8 | `u64` | - |
| `cache_updates` | 40 | 8 | 8 | `u64` | - |
| `cache_hits` | 48 | 8 | 8 | `u64` | - |
| `resolve_attempts` | 56 | 8 | 8 | `u64` | - |
| `resolve_retries` | 64 | 8 | 8 | `u64` | - |
| `resolve_timeouts` | 72 | 8 | 8 | `u64` | - |
| `resolve_misses` | 80 | 8 | 8 | `u64` | - |
| `pending_packets` | 88 | 8 | 8 | `u64` | - |
| `pending_timeouts` | 96 | 8 | 8 | `u64` | - |
| `pending_drops` | 104 | 8 | 8 | `u64` | - |
| `pending_queue_limit` | 112 | 8 | 8 | `u64` | - |
| `last_opcode` | 120 | 2 | 2 | `u16` | - |
| `reserved` | 122 | 2 | 2 | `u16` | - |
| `cache_ip` | 124 | 4 | 1 | `[4]u8` | - |
| `cache_mac` | 128 | 6 | 1 | `[6]u8` | - |
| `reserved1` | 134 | 2 | 2 | `u16` | - |
| `last_error` | 136 | 24 | 1 | `[24]u8` | - |
| `cache_age_ticks` | 160 | 8 | 8 | `u64` | - |
| `cache_ttl_ticks` | 168 | 8 | 8 | `u64` | - |

### `NetDetailIpv4`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `rx_packets` | 0 | 8 | 8 | `u64` | - |
| `tx_packets` | 8 | 8 | 8 | `u64` | - |
| `dropped_short` | 16 | 8 | 8 | `u64` | - |
| `dropped_version` | 24 | 8 | 8 | `u64` | - |
| `dropped_checksum` | 32 | 8 | 8 | `u64` | - |
| `dropped_fragment` | 40 | 8 | 8 | `u64` | - |
| `dropped_destination` | 48 | 8 | 8 | `u64` | - |
| `dropped_tx_too_large` | 56 | 8 | 8 | `u64` | - |
| `malformed` | 64 | 8 | 8 | `u64` | - |
| `last_protocol` | 72 | 1 | 1 | `u8` | - |
| `reserved` | 73 | 3 | 1 | `[3]u8` | - |
| `last_source` | 76 | 4 | 1 | `[4]u8` | - |
| `last_dest` | 80 | 4 | 1 | `[4]u8` | - |
| `last_error` | 84 | 24 | 1 | `[24]u8` | - |

### `NetDetailIcmp`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `rx_packets` | 0 | 8 | 8 | `u64` | - |
| `tx_packets` | 8 | 8 | 8 | `u64` | - |
| `echo_requests_rx` | 16 | 8 | 8 | `u64` | - |
| `echo_replies_rx` | 24 | 8 | 8 | `u64` | - |
| `echo_requests_tx` | 32 | 8 | 8 | `u64` | - |
| `echo_replies_tx` | 40 | 8 | 8 | `u64` | - |
| `destination_unreachable_rx` | 48 | 8 | 8 | `u64` | - |
| `port_unreachable_rx` | 56 | 8 | 8 | `u64` | - |
| `time_exceeded_rx` | 64 | 8 | 8 | `u64` | - |
| `malformed` | 72 | 8 | 8 | `u64` | - |
| `checksum_errors` | 80 | 8 | 8 | `u64` | - |
| `last_type` | 88 | 1 | 1 | `u8` | - |
| `last_code` | 89 | 1 | 1 | `u8` | - |
| `last_id` | 90 | 2 | 2 | `u16` | - |
| `last_seq` | 92 | 2 | 2 | `u16` | - |
| `reserved` | 94 | 2 | 2 | `u16` | - |
| `last_error` | 96 | 24 | 1 | `[24]u8` | - |

### `NetDetailUdp`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 104 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `rx_packets` | 0 | 8 | 8 | `u64` | - |
| `tx_packets` | 8 | 8 | 8 | `u64` | - |
| `dropped_short` | 16 | 8 | 8 | `u64` | - |
| `dropped_length` | 24 | 8 | 8 | `u64` | - |
| `checksum_errors` | 32 | 8 | 8 | `u64` | - |
| `malformed` | 40 | 8 | 8 | `u64` | - |
| `dhcp_rx` | 48 | 8 | 8 | `u64` | - |
| `dns_rx` | 56 | 8 | 8 | `u64` | - |
| `self_tests` | 64 | 8 | 8 | `u64` | - |
| `last_source_port` | 72 | 2 | 2 | `u16` | - |
| `last_dest_port` | 74 | 2 | 2 | `u16` | - |
| `last_error` | 76 | 24 | 1 | `[24]u8` | - |

### `NetDetailDns`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `queries_tx` | 0 | 8 | 8 | `u64` | - |
| `responses_rx` | 8 | 8 | 8 | `u64` | - |
| `a_records` | 16 | 8 | 8 | `u64` | - |
| `resolve_requests` | 24 | 8 | 8 | `u64` | - |
| `timeouts` | 32 | 8 | 8 | `u64` | - |
| `nxdomain` | 40 | 8 | 8 | `u64` | - |
| `tx_errors` | 48 | 8 | 8 | `u64` | - |
| `malformed` | 56 | 8 | 8 | `u64` | - |
| `self_tests` | 64 | 8 | 8 | `u64` | - |
| `last_id` | 72 | 2 | 2 | `u16` | - |
| `reserved` | 74 | 2 | 2 | `u16` | - |
| `last_result` | 76 | 4 | 4 | `i32` | - |
| `last_server` | 80 | 4 | 1 | `[4]u8` | - |
| `last_answer` | 84 | 4 | 1 | `[4]u8` | - |
| `last_error` | 88 | 24 | 1 | `[24]u8` | - |

### `NetDetailSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 2752 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `flags` | 0 | 4 | 4 | `u32` | - |
| `adapter_index` | 4 | 4 | 4 | `u32` | - |
| `config` | 8 | 128 | 4 | `r4os.abi.NetConfigSnapshot` | - |
| `dhcp` | 136 | 168 | 8 | `r4os.abi.DhcpStatus` | - |
| `tcp` | 304 | 160 | 8 | `r4os.abi.TcpSummary` | - |
| `adapter` | 464 | 312 | 8 | `r4os.abi.NetDetailAdapter` | - |
| `ethernet` | 776 | 96 | 8 | `r4os.abi.NetDetailEthernet` | - |
| `arp` | 872 | 176 | 8 | `r4os.abi.NetDetailArp` | - |
| `ipv4` | 1048 | 112 | 8 | `r4os.abi.NetDetailIpv4` | - |
| `icmp` | 1160 | 120 | 8 | `r4os.abi.NetDetailIcmp` | - |
| `udp` | 1280 | 104 | 8 | `r4os.abi.NetDetailUdp` | - |
| `dns` | 1384 | 112 | 8 | `r4os.abi.NetDetailDns` | - |
| `tcp_last_error` | 1496 | 32 | 1 | `[32]u8` | - |
| `protocols` | 1528 | 576 | 8 | `[9]r4os.abi.NetDetailProtocolRuntime` | - |
| `tcp_connection_count` | 2104 | 4 | 4 | `u32` | - |
| `link_generation` | 2108 | 4 | 4 | `u32` | - |
| `tcp_connections` | 2112 | 640 | 8 | `[8]r4os.abi.TcpConnectionInfo` | - |

### `NetDiagTiming`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `ticks` | 0 | 8 | 8 | `u64` | - |
| `hz` | 8 | 8 | 8 | `u64` | - |
| `arp_cache_ttl_ticks` | 16 | 8 | 8 | `u64` | - |
| `arp_resolve_timeout_ticks` | 24 | 8 | 8 | `u64` | - |
| `dhcp_timeout_ticks` | 32 | 8 | 8 | `u64` | - |
| `dns_timeout_ticks` | 40 | 8 | 8 | `u64` | - |
| `tcp_listen_timeout_ticks` | 48 | 8 | 8 | `u64` | - |
| `tcp_retransmit_timeout_ticks` | 56 | 8 | 8 | `u64` | - |
| `tcp_time_wait_ticks` | 64 | 8 | 8 | `u64` | - |
| `service_operation_timeout_ticks` | 72 | 8 | 8 | `u64` | - |
| `operation_status_count` | 80 | 4 | 4 | `u32` | - |
| `reserved` | 84 | 4 | 4 | `u32` | - |

### `NetDiagBackpressure`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 296 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `packet_pool_used` | 0 | 4 | 4 | `u32` | - |
| `packet_pool_limit` | 4 | 4 | 4 | `u32` | - |
| `app_ipv4_queued` | 8 | 4 | 4 | `u32` | - |
| `app_ipv4_queue_limit` | 12 | 4 | 4 | `u32` | - |
| `udp_active_sockets` | 16 | 4 | 4 | `u32` | - |
| `udp_socket_limit` | 20 | 4 | 4 | `u32` | - |
| `udp_queued_packets` | 24 | 4 | 4 | `u32` | - |
| `udp_queue_limit_total` | 28 | 4 | 4 | `u32` | - |
| `tcp_active_connections` | 32 | 4 | 4 | `u32` | - |
| `tcp_connection_limit` | 36 | 4 | 4 | `u32` | - |
| `tcp_active_listeners` | 40 | 4 | 4 | `u32` | - |
| `tcp_listener_limit` | 44 | 4 | 4 | `u32` | - |
| `tcp_buffer_size` | 48 | 4 | 4 | `u32` | - |
| `ipc_service_channels` | 52 | 4 | 4 | `u32` | - |
| `ipc_service_handlers` | 56 | 4 | 4 | `u32` | - |
| `ipc_service_queued` | 60 | 4 | 4 | `u32` | - |
| `ipc_service_queue_limit` | 64 | 4 | 4 | `u32` | - |
| `ipc_service_message_max` | 68 | 4 | 4 | `u32` | - |
| `ipc_service_queue_depth` | 72 | 4 | 4 | `u32` | - |
| `reserved` | 76 | 4 | 4 | `u32` | - |
| `packet_drops` | 80 | 8 | 8 | `u64` | - |
| `app_ipv4_drops` | 88 | 8 | 8 | `u64` | - |
| `udp_drops` | 96 | 8 | 8 | `u64` | - |
| `tcp_rx_drops` | 104 | 8 | 8 | `u64` | - |
| `ipc_service_drops` | 112 | 8 | 8 | `u64` | - |
| `tx_failures` | 120 | 8 | 8 | `u64` | - |
| `tx_no_adapter` | 128 | 8 | 8 | `u64` | - |
| `tx_link_down` | 136 | 8 | 8 | `u64` | - |
| `tx_busy` | 144 | 8 | 8 | `u64` | - |
| `tx_too_large` | 152 | 8 | 8 | `u64` | - |
| `tx_unsupported` | 160 | 8 | 8 | `u64` | - |
| `tx_backend_error` | 168 | 8 | 8 | `u64` | - |
| `resource_queue_full` | 176 | 8 | 8 | `u64` | - |
| `resource_packet_drops` | 184 | 8 | 8 | `u64` | - |
| `resource_buffer_small` | 192 | 8 | 8 | `u64` | - |
| `resource_retries` | 200 | 8 | 8 | `u64` | - |
| `resource_timeouts` | 208 | 8 | 8 | `u64` | - |
| `resource_cancels` | 216 | 8 | 8 | `u64` | - |
| `resource_backend_busy` | 224 | 8 | 8 | `u64` | - |
| `tx_last_result` | 232 | 32 | 1 | `[32]u8` | - |
| `nonblocking_empty_status` | 264 | 32 | 1 | `[32]u8` | - |

### `NetDiagCleanup`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `runs` | 0 | 8 | 8 | `u64` | - |
| `link_down_cleanups` | 8 | 8 | 8 | `u64` | - |
| `adapter_reset_cleanups` | 16 | 8 | 8 | `u64` | - |
| `adapter_unregister_cleanups` | 24 | 8 | 8 | `u64` | - |
| `service_restart_cleanups` | 32 | 8 | 8 | `u64` | - |
| `poweroff_cleanups` | 40 | 8 | 8 | `u64` | - |
| `reboot_cleanups` | 48 | 8 | 8 | `u64` | - |
| `udp_sockets_closed` | 56 | 8 | 8 | `u64` | - |
| `tcp_connections_aborted` | 64 | 8 | 8 | `u64` | - |
| `tcp_listeners_closed` | 72 | 8 | 8 | `u64` | - |
| `dhcp_operations_cancelled` | 80 | 8 | 8 | `u64` | - |
| `dns_operations_cancelled` | 88 | 8 | 8 | `u64` | - |
| `last_udp_closed` | 96 | 4 | 4 | `u32` | - |
| `last_tcp_connections` | 100 | 4 | 4 | `u32` | - |
| `last_tcp_listeners` | 104 | 4 | 4 | `u32` | - |
| `reserved` | 108 | 4 | 4 | `u32` | - |
| `last_reason` | 112 | 32 | 1 | `[32]u8` | - |

### `NetDiagDriver`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `tests` | 0 | 8 | 8 | `u64` | - |
| `cases` | 8 | 8 | 8 | `u64` | - |

### `NetDiagErrors`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `total` | 0 | 8 | 8 | `u64` | - |
| `packet_errors` | 8 | 8 | 8 | `u64` | - |
| `service_errors` | 16 | 8 | 8 | `u64` | - |
| `adapter_errors` | 24 | 8 | 8 | `u64` | - |
| `tx_failures` | 32 | 8 | 8 | `u64` | - |
| `protocol_errors` | 40 | 8 | 8 | `u64` | - |
| `r4p_dispatch_failures` | 48 | 8 | 8 | `u64` | - |
| `last_adapter_error` | 56 | 32 | 1 | `[32]u8` | - |
| `last_protocol_error` | 88 | 32 | 1 | `[32]u8` | - |

### `NetDiagR4p`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `protocol_count` | 0 | 4 | 4 | `u32` | - |
| `active` | 4 | 4 | 4 | `u32` | - |
| `missing` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `r4p_rx` | 16 | 8 | 8 | `u64` | - |
| `r4p_tx` | 24 | 8 | 8 | `u64` | - |
| `r4p_control` | 32 | 8 | 8 | `u64` | - |
| `r4p_build` | 40 | 8 | 8 | `u64` | - |
| `r4p_classify` | 48 | 8 | 8 | `u64` | - |
| `dispatch_failures` | 56 | 8 | 8 | `u64` | - |

### `NetDiagResult`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 760 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `op` | 0 | 4 | 4 | `u32` | - |
| `status` | 4 | 4 | 4 | `i32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `tests` | 16 | 8 | 8 | `u64` | - |
| `cases` | 24 | 8 | 8 | `u64` | - |
| `timing` | 32 | 88 | 8 | `r4os.abi.NetDiagTiming` | - |
| `backpressure` | 120 | 296 | 8 | `r4os.abi.NetDiagBackpressure` | - |
| `cleanup` | 416 | 144 | 8 | `r4os.abi.NetDiagCleanup` | - |
| `driver` | 560 | 16 | 8 | `r4os.abi.NetDiagDriver` | - |
| `errors` | 576 | 120 | 8 | `r4os.abi.NetDiagErrors` | - |
| `r4p` | 696 | 64 | 8 | `r4os.abi.NetDiagR4p` | - |

### `R4TextView`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `ptr` | 0 | 8 | 8 | `?[*]const u8` | input, nullable=true, length=len, borrowed, lifetime=call |
| `len` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |

### `R4Duration`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `nanoseconds` | 0 | 8 | 8 | `u64` | - |

### `R4MonotonicInstant`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `nanoseconds` | 0 | 8 | 8 | `u64` | - |

### `R4Deadline`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `nanoseconds` | 0 | 8 | 8 | `u64` | - |

### `R4UtcTime`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `seconds_since_unix_epoch` | 0 | 8 | 8 | `i64` | - |
| `nanosecond` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |

### `R4Timeout`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 1 | 1 | `u8` | - |
| `reserved` | 1 | 7 | 1 | `[7]u8` | - |
| `nanoseconds` | 8 | 8 | 8 | `u64` | - |

### `R4StopFlag`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 4 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `value` | 0 | 4 | 4 | `u32` | - |

### `ProgramInstanceStorageSummary`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 336 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `core_bytes_per_instance` | 8 | 8 | 8 | `u64` | - |
| `registry_reserved_core_bytes` | 16 | 8 | 8 | `u64` | - |
| `live_core_bytes` | 24 | 8 | 8 | `u64` | - |
| `active_instance_bytes` | 32 | 8 | 8 | `u64` | - |
| `peak_active_instance_bytes` | 40 | 8 | 8 | `u64` | - |
| `reserved_instance_bytes` | 48 | 8 | 8 | `u64` | - |
| `peak_reserved_instance_bytes` | 56 | 8 | 8 | `u64` | - |
| `current_payload_bytes` | 64 | 8 | 8 | `u64` | - |
| `peak_payload_bytes` | 72 | 8 | 8 | `u64` | - |
| `current_runtime_bytes` | 80 | 8 | 8 | `u64` | - |
| `peak_runtime_bytes` | 88 | 8 | 8 | `u64` | - |
| `current_console_bytes` | 96 | 8 | 8 | `u64` | - |
| `peak_console_bytes` | 104 | 8 | 8 | `u64` | - |
| `current_gui_bytes` | 112 | 8 | 8 | `u64` | - |
| `peak_gui_bytes` | 120 | 8 | 8 | `u64` | - |
| `active_instances` | 128 | 4 | 4 | `u32` | - |
| `active_service_instances` | 132 | 4 | 4 | `u32` | - |
| `active_console_instances` | 136 | 4 | 4 | `u32` | - |
| `active_gui_instances` | 140 | 4 | 4 | `u32` | - |
| `runtime_payloads` | 144 | 4 | 4 | `u32` | - |
| `process_payloads` | 148 | 4 | 4 | `u32` | - |
| `environment_payloads` | 152 | 4 | 4 | `u32` | - |
| `console_payloads` | 156 | 4 | 4 | `u32` | - |
| `console_output_payloads` | 160 | 4 | 4 | `u32` | - |
| `gui_payloads` | 164 | 4 | 4 | `u32` | - |
| `gui_command_payloads` | 168 | 4 | 4 | `u32` | - |
| `gui_raster_payloads` | 172 | 4 | 4 | `u32` | - |
| `allocation_attempts` | 176 | 8 | 8 | `u64` | - |
| `payload_allocations` | 184 | 8 | 8 | `u64` | - |
| `payload_releases` | 192 | 8 | 8 | `u64` | - |
| `allocation_failures` | 200 | 8 | 8 | `u64` | - |
| `transaction_rollbacks` | 208 | 8 | 8 | `u64` | - |
| `owner_mismatches` | 216 | 8 | 8 | `u64` | - |
| `header_errors` | 224 | 8 | 8 | `u64` | - |
| `free_failures` | 232 | 8 | 8 | `u64` | - |
| `quarantined_payloads` | 240 | 8 | 8 | `u64` | - |
| `quarantined_bytes` | 248 | 8 | 8 | `u64` | - |
| `current_gui_frame_bytes` | 256 | 8 | 8 | `u64` | - |
| `peak_gui_frame_bytes` | 264 | 8 | 8 | `u64` | - |
| `current_gui_frame_commands` | 272 | 8 | 8 | `u64` | - |
| `peak_gui_frame_commands` | 280 | 8 | 8 | `u64` | - |
| `current_gui_frame_nodes` | 288 | 8 | 8 | `u64` | - |
| `peak_gui_frame_nodes` | 296 | 8 | 8 | `u64` | - |
| `gui_frame_commits` | 304 | 8 | 8 | `u64` | - |
| `gui_frame_cancels` | 312 | 8 | 8 | `u64` | - |
| `gui_frame_oom_failures` | 320 | 8 | 8 | `u64` | - |
| `gui_frame_snapshot_reads` | 328 | 8 | 8 | `u64` | - |

### `ProgramInstanceStorageSelfTestResult`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cases` | 8 | 4 | 4 | `u32` | - |
| `passed_cases` | 12 | 4 | 4 | `u32` | - |
| `failed_case` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `baseline_payload_reserved_bytes` | 24 | 8 | 8 | `u64` | - |
| `final_payload_reserved_bytes` | 32 | 8 | 8 | `u64` | - |
| `peak_payload_reserved_bytes` | 40 | 8 | 8 | `u64` | - |
| `allocation_failures_before` | 48 | 8 | 8 | `u64` | - |
| `allocation_failures_after` | 56 | 8 | 8 | `u64` | - |

### `ProgramProcessHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `instance_id` | 0 | 4 | 4 | `u32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |

### `ProgramProcessCompletion`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `handle` | 0 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `sequence` | 16 | 8 | 8 | `u64` | - |
| `start_tick` | 24 | 8 | 8 | `u64` | - |
| `finish_tick` | 32 | 8 | 8 | `u64` | - |
| `exit_code` | 40 | 4 | 4 | `i32` | - |
| `task_id` | 44 | 4 | 4 | `u32` | - |
| `output_revision` | 48 | 4 | 4 | `u32` | - |
| `output_length` | 52 | 4 | 4 | `u32` | - |
| `flags` | 56 | 4 | 4 | `u32` | - |
| `app_class` | 60 | 1 | 1 | `u8` | - |
| `role` | 61 | 1 | 1 | `u8` | - |
| `exit_reason` | 62 | 1 | 1 | `u8` | - |
| `reserved0` | 63 | 1 | 1 | `u8` | - |
| `console_state` | 64 | 64 | 4 | `r4os.abi.ConsoleState` | - |

### `ProgramRegistrySummary`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `chunk_slots` | 8 | 4 | 4 | `u32` | - |
| `chunk_count` | 12 | 4 | 4 | `u32` | - |
| `slot_capacity` | 16 | 4 | 4 | `u32` | - |
| `free_slots` | 20 | 4 | 4 | `u32` | - |
| `reserved_slots` | 24 | 4 | 4 | `u32` | - |
| `live_slots` | 28 | 4 | 4 | `u32` | - |
| `done_slots` | 32 | 4 | 4 | `u32` | - |
| `retiring_slots` | 36 | 4 | 4 | `u32` | - |
| `pinned_slots` | 40 | 4 | 4 | `u32` | - |
| `warm_chunks` | 44 | 4 | 4 | `u32` | - |
| `last_admission_error` | 48 | 4 | 4 | `i32` | - |
| `flags` | 52 | 4 | 4 | `u32` | - |
| `peak_chunks` | 56 | 8 | 8 | `u64` | - |
| `peak_live` | 64 | 8 | 8 | `u64` | - |
| `growth_attempts` | 72 | 8 | 8 | `u64` | - |
| `growth_failures` | 80 | 8 | 8 | `u64` | - |
| `forced_failures` | 88 | 8 | 8 | `u64` | - |
| `publish_count` | 96 | 8 | 8 | `u64` | - |
| `rollback_count` | 104 | 8 | 8 | `u64` | - |
| `shrink_count` | 112 | 8 | 8 | `u64` | - |
| `id_collisions` | 120 | 8 | 8 | `u64` | - |
| `id_wraps` | 128 | 8 | 8 | `u64` | - |
| `live_id_hash` | 136 | 8 | 8 | `u64` | - |
| `live_address_hash` | 144 | 8 | 8 | `u64` | - |
| `reserved0` | 152 | 8 | 8 | `u64` | - |

### `ProgramRegistrySummaryV2`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 224 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `chunk_slots` | 8 | 4 | 4 | `u32` | - |
| `chunk_count` | 12 | 4 | 4 | `u32` | - |
| `slot_capacity` | 16 | 4 | 4 | `u32` | - |
| `free_slots` | 20 | 4 | 4 | `u32` | - |
| `reserved_slots` | 24 | 4 | 4 | `u32` | - |
| `live_slots` | 28 | 4 | 4 | `u32` | - |
| `done_slots` | 32 | 4 | 4 | `u32` | - |
| `retiring_slots` | 36 | 4 | 4 | `u32` | - |
| `pinned_slots` | 40 | 4 | 4 | `u32` | - |
| `warm_chunks` | 44 | 4 | 4 | `u32` | - |
| `last_admission_error` | 48 | 4 | 4 | `i32` | - |
| `flags` | 52 | 4 | 4 | `u32` | - |
| `peak_chunks` | 56 | 8 | 8 | `u64` | - |
| `peak_live` | 64 | 8 | 8 | `u64` | - |
| `growth_attempts` | 72 | 8 | 8 | `u64` | - |
| `growth_failures` | 80 | 8 | 8 | `u64` | - |
| `forced_failures` | 88 | 8 | 8 | `u64` | - |
| `publish_count` | 96 | 8 | 8 | `u64` | - |
| `rollback_count` | 104 | 8 | 8 | `u64` | - |
| `shrink_count` | 112 | 8 | 8 | `u64` | - |
| `id_collisions` | 120 | 8 | 8 | `u64` | - |
| `id_wraps` | 128 | 8 | 8 | `u64` | - |
| `live_id_hash` | 136 | 8 | 8 | `u64` | - |
| `live_address_hash` | 144 | 8 | 8 | `u64` | - |
| `reserved0` | 152 | 8 | 8 | `u64` | - |
| `next_generation` | 160 | 8 | 8 | `u64` | - |
| `completion_pending` | 168 | 4 | 4 | `u32` | - |
| `completion_ready` | 172 | 4 | 4 | `u32` | - |
| `completion_output_bytes` | 176 | 8 | 8 | `u64` | - |
| `retire_queued` | 184 | 4 | 4 | `u32` | - |
| `retire_deferred` | 188 | 4 | 4 | `u32` | - |
| `history_head` | 192 | 4 | 4 | `u32` | - |
| `history_count` | 196 | 4 | 4 | `u32` | - |
| `history_sequence` | 200 | 8 | 8 | `u64` | - |
| `completion_peak` | 208 | 8 | 8 | `u64` | - |
| `retire_retries` | 216 | 8 | 8 | `u64` | - |

### `ProgramRegistrySelfTestResult`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `operation` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `chunk_count_before` | 16 | 4 | 4 | `u32` | - |
| `slot_capacity_before` | 20 | 4 | 4 | `u32` | - |
| `free_slots_before` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `growth_failures_before` | 32 | 8 | 8 | `u64` | - |
| `growth_failures_after` | 40 | 8 | 8 | `u64` | - |
| `forced_failures_before` | 48 | 8 | 8 | `u64` | - |
| `forced_failures_after` | 56 | 8 | 8 | `u64` | - |

### `ProgramRegistrySelfTestResultV2`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 136 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `operation` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `chunk_count_before` | 16 | 4 | 4 | `u32` | - |
| `slot_capacity_before` | 20 | 4 | 4 | `u32` | - |
| `free_slots_before` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `growth_failures_before` | 32 | 8 | 8 | `u64` | - |
| `growth_failures_after` | 40 | 8 | 8 | `u64` | - |
| `forced_failures_before` | 48 | 8 | 8 | `u64` | - |
| `forced_failures_after` | 56 | 8 | 8 | `u64` | - |
| `lifecycle_phase` | 64 | 4 | 4 | `u32` | - |
| `lifecycle_result` | 68 | 4 | 4 | `i32` | - |
| `retire_queued_before` | 72 | 4 | 4 | `u32` | - |
| `retire_queued_after` | 76 | 4 | 4 | `u32` | - |
| `completion_pending_before` | 80 | 4 | 4 | `u32` | - |
| `completion_pending_after` | 84 | 4 | 4 | `u32` | - |
| `completion_ready_before` | 88 | 4 | 4 | `u32` | - |
| `completion_ready_after` | 92 | 4 | 4 | `u32` | - |
| `retire_retries_before` | 96 | 8 | 8 | `u64` | - |
| `retire_retries_after` | 104 | 8 | 8 | `u64` | - |
| `history_sequence_before` | 112 | 8 | 8 | `u64` | - |
| `history_sequence_after` | 120 | 8 | 8 | `u64` | - |
| `requested_next_id` | 128 | 4 | 4 | `u32` | - |
| `applied_next_id` | 132 | 4 | 4 | `u32` | - |

### `ProgramJoinHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `thread_id` | 0 | 4 | 4 | `u32` | - |
| `instance_id` | 4 | 4 | 4 | `u32` | - |
| `thread_generation` | 8 | 8 | 8 | `u64` | - |
| `instance_generation` | 16 | 8 | 8 | `u64` | - |
| `reserved` | 24 | 8 | 8 | `u64` | - |

### `ProgramInventoryCursor`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `snapshot_generation` | 8 | 8 | 8 | `u64` | - |
| `program_epoch` | 16 | 8 | 8 | `u64` | - |
| `task_epoch` | 24 | 8 | 8 | `u64` | - |
| `thread_epoch` | 32 | 8 | 8 | `u64` | - |
| `program_after_generation` | 40 | 8 | 8 | `u64` | - |
| `task_after_generation` | 48 | 8 | 8 | `u64` | - |
| `thread_after_generation` | 56 | 8 | 8 | `u64` | - |
| `flags` | 64 | 4 | 4 | `u32` | - |
| `restarts` | 68 | 4 | 4 | `u32` | - |
| `reserved0` | 72 | 8 | 8 | `u64` | - |

### `ProgramInventoryPageInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `snapshot_generation` | 8 | 8 | 8 | `u64` | - |
| `next_generation` | 16 | 8 | 8 | `u64` | - |
| `total` | 24 | 4 | 4 | `u32` | - |
| `returned` | 28 | 4 | 4 | `u32` | - |
| `has_more` | 32 | 4 | 4 | `u32` | - |
| `kind` | 36 | 4 | 4 | `u32` | - |
| `status` | 40 | 4 | 4 | `i32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |

### `ProgramInstanceSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `info` | 24 | 112 | 8 | `r4os.abi.ProgramInstanceInfo` | - |
| `state_generation` | 136 | 8 | 8 | `u64` | - |

### `ProgramTaskSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `task_id` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `owner_instance_id` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `instance_generation` | 32 | 8 | 8 | `u64` | - |
| `created_tick` | 40 | 8 | 8 | `u64` | - |
| `last_run_tick` | 48 | 8 | 8 | `u64` | - |
| `wake_tick` | 56 | 8 | 8 | `u64` | - |
| `runtime_ticks` | 64 | 8 | 8 | `u64` | - |
| `exit_code` | 72 | 4 | 4 | `i32` | - |
| `reserved0` | 76 | 4 | 4 | `u32` | - |
| `reserved1` | 80 | 8 | 8 | `u64` | - |
| `reserved2` | 88 | 8 | 8 | `u64` | - |

### `ProgramThreadSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 136 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 32 | 8 | `r4os.abi.ProgramJoinHandle` | - |
| `info` | 40 | 88 | 8 | `r4os.abi.ProgramThreadInfo` | - |
| `state_generation` | 128 | 8 | 8 | `u64` | - |

### `ProgramInventorySummary`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `snapshot_generation` | 8 | 8 | 8 | `u64` | - |
| `program_epoch` | 16 | 8 | 8 | `u64` | - |
| `task_epoch` | 24 | 8 | 8 | `u64` | - |
| `thread_epoch` | 32 | 8 | 8 | `u64` | - |
| `program_total` | 40 | 4 | 4 | `u32` | - |
| `program_active` | 44 | 4 | 4 | `u32` | - |
| `program_done` | 48 | 4 | 4 | `u32` | - |
| `program_retiring` | 52 | 4 | 4 | `u32` | - |
| `completion_total` | 56 | 4 | 4 | `u32` | - |
| `task_total` | 60 | 4 | 4 | `u32` | - |
| `task_running` | 64 | 4 | 4 | `u32` | - |
| `task_ready` | 68 | 4 | 4 | `u32` | - |
| `task_blocked` | 72 | 4 | 4 | `u32` | - |
| `thread_total` | 76 | 4 | 4 | `u32` | - |
| `thread_running` | 80 | 4 | 4 | `u32` | - |
| `thread_done` | 84 | 4 | 4 | `u32` | - |
| `thread_joining` | 88 | 4 | 4 | `u32` | - |
| `program_peak` | 92 | 4 | 4 | `u32` | - |
| `task_peak` | 96 | 4 | 4 | `u32` | - |
| `thread_peak` | 100 | 4 | 4 | `u32` | - |
| `program_create_failures` | 104 | 8 | 8 | `u64` | - |
| `task_create_failures` | 112 | 8 | 8 | `u64` | - |
| `thread_create_failures` | 120 | 8 | 8 | `u64` | - |
| `rollback_failures` | 128 | 8 | 8 | `u64` | - |
| `last_error` | 136 | 4 | 4 | `i32` | - |
| `flags` | 140 | 4 | 4 | `u32` | - |
| `program_reserved` | 144 | 4 | 4 | `u32` | - |
| `heap_active_blocks` | 148 | 4 | 4 | `u32` | - |
| `heap_used_bytes` | 152 | 8 | 8 | `u64` | - |

### `ProgramDriverWorkPerformanceMetrics`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 640 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `submitted` | 0 | 8 | 8 | `u64` | - |
| `submitted_actual_irq` | 8 | 8 | 8 | `u64` | - |
| `submitted_actual_task` | 16 | 8 | 8 | `u64` | - |
| `submitted_irq_class` | 24 | 8 | 8 | `u64` | - |
| `submitted_task_class` | 32 | 8 | 8 | `u64` | - |
| `started` | 40 | 8 | 8 | `u64` | - |
| `started_irq_class` | 48 | 8 | 8 | `u64` | - |
| `started_task_class` | 56 | 8 | 8 | `u64` | - |
| `completed` | 64 | 8 | 8 | `u64` | - |
| `completed_irq_class` | 72 | 8 | 8 | `u64` | - |
| `completed_task_class` | 80 | 8 | 8 | `u64` | - |
| `failed` | 88 | 8 | 8 | `u64` | - |
| `cancelled` | 96 | 8 | 8 | `u64` | - |
| `dropped` | 104 | 8 | 8 | `u64` | - |
| `full_rejections` | 112 | 8 | 8 | `u64` | - |
| `retained_full_rejections` | 120 | 8 | 8 | `u64` | - |
| `waits` | 128 | 8 | 8 | `u64` | - |
| `wait_timeouts` | 136 | 8 | 8 | `u64` | - |
| `wait_denied_irq` | 144 | 8 | 8 | `u64` | - |
| `wait_failed` | 152 | 8 | 8 | `u64` | - |
| `wait_total_ns` | 160 | 8 | 8 | `u64` | - |
| `wait_max_ns` | 168 | 8 | 8 | `u64` | - |
| `wait_last_ns` | 176 | 8 | 8 | `u64` | - |
| `wake_publications` | 184 | 8 | 8 | `u64` | - |
| `wake_waiters` | 192 | 8 | 8 | `u64` | - |
| `wake_misses` | 200 | 8 | 8 | `u64` | - |
| `releases` | 208 | 8 | 8 | `u64` | - |
| `release_busy` | 216 | 8 | 8 | `u64` | - |
| `release_wakes` | 224 | 8 | 8 | `u64` | - |
| `invalid_handles` | 232 | 8 | 8 | `u64` | - |
| `stale_handles` | 240 | 8 | 8 | `u64` | - |
| `publication_pending_releases` | 248 | 8 | 8 | `u64` | - |
| `waiter_blocked_releases` | 256 | 8 | 8 | `u64` | - |
| `claimed_releases` | 264 | 8 | 8 | `u64` | - |
| `queue_total_ns` | 272 | 8 | 8 | `u64` | - |
| `queue_max_ns` | 280 | 8 | 8 | `u64` | - |
| `queue_last_ns` | 288 | 8 | 8 | `u64` | - |
| `run_total_ns` | 296 | 8 | 8 | `u64` | - |
| `run_max_ns` | 304 | 8 | 8 | `u64` | - |
| `run_last_ns` | 312 | 8 | 8 | `u64` | - |
| `e2e_total_ns` | 320 | 8 | 8 | `u64` | - |
| `e2e_max_ns` | 328 | 8 | 8 | `u64` | - |
| `e2e_last_ns` | 336 | 8 | 8 | `u64` | - |
| `timing_unavailable` | 344 | 8 | 8 | `u64` | - |
| `completion_age_current_ns` | 352 | 8 | 8 | `u64` | - |
| `completion_age_max_ns` | 360 | 8 | 8 | `u64` | - |
| `selection_irq` | 368 | 8 | 8 | `u64` | - |
| `selection_task` | 376 | 8 | 8 | `u64` | - |
| `selection_irq_preferred` | 384 | 8 | 8 | `u64` | - |
| `selection_task_fairness` | 392 | 8 | 8 | `u64` | - |
| `selection_empty` | 400 | 8 | 8 | `u64` | - |
| `scan_passes` | 408 | 8 | 8 | `u64` | - |
| `scan_slots` | 416 | 8 | 8 | `u64` | - |
| `critical_sections` | 424 | 8 | 8 | `u64` | - |
| `critical_from_irq` | 432 | 8 | 8 | `u64` | - |
| `critical_timing_samples` | 440 | 8 | 8 | `u64` | - |
| `critical_timing_unavailable` | 448 | 8 | 8 | `u64` | - |
| `critical_total_ns` | 456 | 8 | 8 | `u64` | - |
| `critical_max_ns` | 464 | 8 | 8 | `u64` | - |
| `critical_last_ns` | 472 | 8 | 8 | `u64` | - |
| `cleanup_calls` | 480 | 8 | 8 | `u64` | - |
| `cleanup_quiesced` | 488 | 8 | 8 | `u64` | - |
| `cleanup_failed_context` | 496 | 8 | 8 | `u64` | - |
| `cleanup_queued_cancelled` | 504 | 8 | 8 | `u64` | - |
| `cleanup_waits` | 512 | 8 | 8 | `u64` | - |
| `cleanup_wait_timeouts` | 520 | 8 | 8 | `u64` | - |
| `cleanup_wait_failures` | 528 | 8 | 8 | `u64` | - |
| `cleanup_wait_total_ns` | 536 | 8 | 8 | `u64` | - |
| `cleanup_wait_max_ns` | 544 | 8 | 8 | `u64` | - |
| `cleanup_released` | 552 | 8 | 8 | `u64` | - |
| `cleanup_late_finishes` | 560 | 8 | 8 | `u64` | - |
| `cleanup_scan_passes` | 568 | 8 | 8 | `u64` | - |
| `cleanup_scan_slots` | 576 | 8 | 8 | `u64` | - |
| `long_callbacks` | 584 | 8 | 8 | `u64` | - |
| `waiter_enrollments` | 592 | 8 | 8 | `u64` | - |
| `waiter_wake_returns` | 600 | 8 | 8 | `u64` | - |
| `waiter_cancel_returns` | 608 | 8 | 8 | `u64` | - |
| `sleep_waits` | 616 | 8 | 8 | `u64` | - |
| `sleep_denied_irq` | 624 | 8 | 8 | `u64` | - |
| `sleep_total_ticks` | 632 | 8 | 8 | `u64` | - |

### `ProgramDriverWorkPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 928 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `selected_owner` | 8 | 4 | 4 | `u32` | - |
| `owner_present` | 12 | 4 | 4 | `u32` | - |
| `initialized` | 16 | 4 | 4 | `u32` | - |
| `worker_started` | 20 | 4 | 4 | `u32` | - |
| `worker_task_id` | 24 | 4 | 4 | `u32` | - |
| `worker_count` | 28 | 4 | 4 | `u32` | - |
| `queue_capacity` | 32 | 4 | 4 | `u32` | - |
| `free_slots` | 36 | 4 | 4 | `u32` | - |
| `used_slots` | 40 | 4 | 4 | `u32` | - |
| `queued_slots` | 44 | 4 | 4 | `u32` | - |
| `running_slots` | 48 | 4 | 4 | `u32` | - |
| `completed_slots` | 52 | 4 | 4 | `u32` | - |
| `cancelled_slots` | 56 | 4 | 4 | `u32` | - |
| `irq_queued_slots` | 60 | 4 | 4 | `u32` | - |
| `task_queued_slots` | 64 | 4 | 4 | `u32` | - |
| `queue_high_water` | 68 | 4 | 4 | `u32` | - |
| `used_high_water` | 72 | 4 | 4 | `u32` | - |
| `retained_high_water` | 76 | 4 | 4 | `u32` | - |
| `irq_burst_limit` | 80 | 4 | 4 | `u32` | - |
| `current_irq_burst` | 84 | 4 | 4 | `u32` | - |
| `waiters_current` | 88 | 4 | 4 | `u32` | - |
| `waiters_max` | 92 | 4 | 4 | `u32` | - |
| `last_submitted_owner` | 96 | 4 | 4 | `u32` | - |
| `last_started_owner` | 100 | 4 | 4 | `u32` | - |
| `last_completed_owner` | 104 | 4 | 4 | `u32` | - |
| `last_cleanup_owner` | 108 | 4 | 4 | `u32` | - |
| `owner_used_slots` | 112 | 4 | 4 | `u32` | - |
| `owner_queued_slots` | 116 | 4 | 4 | `u32` | - |
| `owner_running_slots` | 120 | 4 | 4 | `u32` | - |
| `owner_completed_slots` | 124 | 4 | 4 | `u32` | - |
| `owner_cancelled_slots` | 128 | 4 | 4 | `u32` | - |
| `owner_irq_queued_slots` | 132 | 4 | 4 | `u32` | - |
| `owner_task_queued_slots` | 136 | 4 | 4 | `u32` | - |
| `owner_used_high_water` | 140 | 4 | 4 | `u32` | - |
| `owner_retained_high_water` | 144 | 4 | 4 | `u32` | - |
| `monotonic_clock_flags` | 148 | 4 | 4 | `u32` | - |
| `owner_waiters_current` | 152 | 4 | 4 | `u32` | - |
| `owner_waiters_max` | 156 | 4 | 4 | `u32` | - |
| `long_callback_threshold_ns` | 160 | 8 | 8 | `u64` | - |
| `metrics` | 168 | 640 | 8 | `r4os.abi.ProgramDriverWorkPerformanceMetrics` | - |
| `deadline_worker_started` | 808 | 4 | 4 | `u32` | - |
| `deadline_worker_task_id` | 812 | 4 | 4 | `u32` | - |
| `deadline_worker_count` | 816 | 4 | 4 | `u32` | - |
| `deadline_queue_capacity` | 820 | 4 | 4 | `u32` | - |
| `deadline_queued_slots` | 824 | 4 | 4 | `u32` | - |
| `deadline_running_slots` | 828 | 4 | 4 | `u32` | - |
| `deadline_queue_high_water` | 832 | 4 | 4 | `u32` | - |
| `owner_deadline_queued_slots` | 836 | 4 | 4 | `u32` | - |
| `owner_deadline_running_slots` | 840 | 4 | 4 | `u32` | - |
| `owner_deadline_queue_high_water` | 844 | 4 | 4 | `u32` | - |
| `deadline_submitted` | 848 | 8 | 8 | `u64` | - |
| `deadline_started` | 856 | 8 | 8 | `u64` | - |
| `deadline_completed` | 864 | 8 | 8 | `u64` | - |
| `deadline_misses` | 872 | 8 | 8 | `u64` | - |
| `deadline_budget_overruns` | 880 | 8 | 8 | `u64` | - |
| `deadline_queue_rejections` | 888 | 8 | 8 | `u64` | - |
| `deadline_queue_total_ticks` | 896 | 8 | 8 | `u64` | - |
| `deadline_queue_max_ticks` | 904 | 8 | 8 | `u64` | - |
| `deadline_lateness_total_ticks` | 912 | 8 | 8 | `u64` | - |
| `deadline_lateness_max_ticks` | 920 | 8 | 8 | `u64` | - |

### `ProgramPciInventoryPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 280 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `generation` | 12 | 4 | 4 | `u32` | - |
| `capacity` | 16 | 4 | 4 | `u32` | - |
| `mcfg_segment` | 20 | 4 | 4 | `u32` | - |
| `mcfg_start_bus` | 24 | 4 | 4 | `u32` | - |
| `mcfg_end_bus` | 28 | 4 | 4 | `u32` | - |
| `found` | 32 | 8 | 8 | `u64` | - |
| `stored` | 40 | 8 | 8 | `u64` | - |
| `dropped` | 48 | 8 | 8 | `u64` | - |
| `ecam_stored` | 56 | 8 | 8 | `u64` | - |
| `legacy_stored` | 64 | 8 | 8 | `u64` | - |
| `vendor_probes_ecam` | 72 | 8 | 8 | `u64` | - |
| `vendor_probes_legacy` | 80 | 8 | 8 | `u64` | - |
| `class_reads` | 88 | 8 | 8 | `u64` | - |
| `header_reads` | 96 | 8 | 8 | `u64` | - |
| `enumeration_config_reads` | 104 | 8 | 8 | `u64` | - |
| `function_pages` | 112 | 8 | 8 | `u64` | - |
| `early_stops` | 120 | 8 | 8 | `u64` | - |
| `ecam_config_reads` | 128 | 8 | 8 | `u64` | - |
| `ecam_config_writes` | 136 | 8 | 8 | `u64` | - |
| `legacy_config_reads` | 144 | 8 | 8 | `u64` | - |
| `legacy_config_writes` | 152 | 8 | 8 | `u64` | - |
| `mapping_checks` | 160 | 8 | 8 | `u64` | - |
| `mapping_hits` | 168 | 8 | 8 | `u64` | - |
| `mapping_misses` | 176 | 8 | 8 | `u64` | - |
| `mapping_fast_accesses` | 184 | 8 | 8 | `u64` | - |
| `invalid_accesses` | 192 | 8 | 8 | `u64` | - |
| `class_find_calls` | 200 | 8 | 8 | `u64` | - |
| `class_candidates` | 208 | 8 | 8 | `u64` | - |
| `detail_materializations` | 216 | 8 | 8 | `u64` | - |
| `interrupt_dword_reads` | 224 | 8 | 8 | `u64` | - |
| `command_reads` | 232 | 8 | 8 | `u64` | - |
| `bar_reads` | 240 | 8 | 8 | `u64` | - |
| `enumeration_total_ns` | 248 | 8 | 8 | `u64` | - |
| `ecam_enumeration_ns` | 256 | 8 | 8 | `u64` | - |
| `legacy_enumeration_ns` | 264 | 8 | 8 | `u64` | - |
| `timing_unavailable` | 272 | 8 | 8 | `u64` | - |

### `ProgramInputPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 408 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `keyboard_queue_capacity` | 8 | 4 | 4 | `u32` | - |
| `keyboard_queue_pending` | 12 | 4 | 4 | `u32` | - |
| `keyboard_queue_high_water` | 16 | 4 | 4 | `u32` | - |
| `gui_queue_capacity` | 20 | 4 | 4 | `u32` | - |
| `gui_queue_pending` | 24 | 4 | 4 | `u32` | - |
| `gui_queue_high_water` | 28 | 4 | 4 | `u32` | - |
| `gui_queue_active` | 32 | 4 | 4 | `u32` | - |
| `console_queue_capacity` | 36 | 4 | 4 | `u32` | - |
| `console_queue_pending` | 40 | 4 | 4 | `u32` | - |
| `console_queue_high_water` | 44 | 4 | 4 | `u32` | - |
| `console_queue_active` | 48 | 4 | 4 | `u32` | - |
| `program_start_attach_pending` | 52 | 4 | 4 | `u32` | - |
| `i8042_irq1_count` | 56 | 8 | 8 | `u64` | - |
| `i8042_irq12_count` | 64 | 8 | 8 | `u64` | - |
| `i8042_byte_count` | 72 | 8 | 8 | `u64` | - |
| `i8042_keyboard_byte_count` | 80 | 8 | 8 | `u64` | - |
| `i8042_mouse_byte_count` | 88 | 8 | 8 | `u64` | - |
| `i8042_keyboard_bytes_on_irq12` | 96 | 8 | 8 | `u64` | - |
| `i8042_mouse_bytes_on_irq1` | 104 | 8 | 8 | `u64` | - |
| `i8042_drain_limit_hits` | 112 | 8 | 8 | `u64` | - |
| `keyboard_push_attempts` | 120 | 8 | 8 | `u64` | - |
| `keyboard_accepted` | 128 | 8 | 8 | `u64` | - |
| `keyboard_dropped` | 136 | 8 | 8 | `u64` | - |
| `gui_push_attempts` | 144 | 8 | 8 | `u64` | - |
| `gui_accepted` | 152 | 8 | 8 | `u64` | - |
| `gui_mouse_move_coalesced` | 160 | 8 | 8 | `u64` | - |
| `gui_mouse_move_evicted` | 168 | 8 | 8 | `u64` | - |
| `gui_rejected` | 176 | 8 | 8 | `u64` | - |
| `console_push_calls` | 184 | 8 | 8 | `u64` | - |
| `console_batch_calls` | 192 | 8 | 8 | `u64` | - |
| `console_bytes_attempted` | 200 | 8 | 8 | `u64` | - |
| `console_bytes_accepted` | 208 | 8 | 8 | `u64` | - |
| `console_full_events` | 216 | 8 | 8 | `u64` | - |
| `program_launch_attempts` | 224 | 8 | 8 | `u64` | - |
| `program_entries_started` | 232 | 8 | 8 | `u64` | - |
| `program_attach_wait_events` | 240 | 8 | 8 | `u64` | - |
| `console_read_calls` | 248 | 8 | 8 | `u64` | - |
| `console_read_empty` | 256 | 8 | 8 | `u64` | - |
| `console_read_bytes` | 264 | 8 | 8 | `u64` | - |
| `console_wait_calls` | 272 | 8 | 8 | `u64` | - |
| `console_wait_blocks` | 280 | 8 | 8 | `u64` | - |
| `console_wait_immediate` | 288 | 8 | 8 | `u64` | - |
| `console_wait_wakes` | 296 | 8 | 8 | `u64` | - |
| `console_wait_timeouts` | 304 | 8 | 8 | `u64` | - |
| `console_wait_cancellations` | 312 | 8 | 8 | `u64` | - |
| `console_output_write_calls` | 320 | 8 | 8 | `u64` | - |
| `console_output_source_bytes` | 328 | 8 | 8 | `u64` | - |
| `console_output_visible_append_bytes` | 336 | 8 | 8 | `u64` | - |
| `console_output_capture_append_bytes` | 344 | 8 | 8 | `u64` | - |
| `console_output_shared_bytes` | 352 | 8 | 8 | `u64` | - |
| `console_output_revision_batches` | 360 | 8 | 8 | `u64` | - |
| `console_output_desktop_signals` | 368 | 8 | 8 | `u64` | - |
| `console_output_compactions` | 376 | 8 | 8 | `u64` | - |
| `console_output_compaction_bytes` | 384 | 8 | 8 | `u64` | - |
| `console_output_segment_drops` | 392 | 8 | 8 | `u64` | - |
| `console_output_segment_drop_bytes` | 400 | 8 | 8 | `u64` | - |

### `ServiceDeadlineFooter`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `payload_len` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `deadline_tick` | 16 | 8 | 8 | `u64` | - |

### `AudioServiceMasterRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `fixed_volume` | 12 | 4 | 4 | `u32` | - |
| `expected_revision` | 16 | 8 | 8 | `u64` | - |
| `reserved0` | 24 | 8 | 1 | `[8]u8` | - |

### `AudioServiceMasterState`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `service_flags` | 12 | 4 | 4 | `u32` | - |
| `master_revision` | 16 | 8 | 8 | `u64` | - |
| `service_epoch` | 24 | 8 | 8 | `u64` | - |
| `selected_volume_fixed` | 32 | 4 | 4 | `u32` | - |
| `effective_volume_fixed` | 36 | 4 | 4 | `u32` | - |
| `last_audible_volume_fixed` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |
| `persist_writes` | 48 | 8 | 8 | `u64` | - |
| `persist_failures` | 56 | 8 | 8 | `u64` | - |
| `master_changes` | 64 | 8 | 8 | `u64` | - |
| `config_loads` | 72 | 8 | 8 | `u64` | - |
| `reserved1` | 80 | 48 | 1 | `[48]u8` | - |

### `TrayServiceRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1184 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `owner` | 8 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `item_id` | 24 | 8 | 8 | `u64` | - |
| `item_revision` | 32 | 8 | 8 | `u64` | - |
| `item_flags` | 40 | 4 | 4 | `u32` | - |
| `status_flags` | 44 | 4 | 4 | `u32` | - |
| `after_sequence` | 48 | 8 | 8 | `u64` | - |
| `deadline_tick` | 56 | 8 | 8 | `u64` | - |
| `tooltip_length` | 64 | 2 | 2 | `u16` | - |
| `icon_width` | 66 | 2 | 2 | `u16` | - |
| `icon_height` | 68 | 2 | 2 | `u16` | - |
| `icon_format` | 70 | 2 | 2 | `u16` | - |
| `tooltip` | 72 | 64 | 1 | `[64]u8` | - |
| `icon` | 136 | 1024 | 4 | `[256]u32` | - |
| `reserved0` | 1160 | 24 | 1 | `[24]u8` | - |

### `TrayEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `sequence` | 8 | 8 | 8 | `u64` | - |
| `owner` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `item_id` | 32 | 8 | 8 | `u64` | - |
| `item_revision` | 40 | 8 | 8 | `u64` | - |
| `kind` | 48 | 2 | 2 | `u16` | - |
| `flags` | 50 | 2 | 2 | `u16` | - |
| `wheel_delta` | 52 | 4 | 4 | `i32` | - |
| `x` | 56 | 4 | 4 | `i32` | - |
| `y` | 60 | 4 | 4 | `i32` | - |
| `tick` | 64 | 8 | 8 | `u64` | - |
| `dropped_before` | 72 | 4 | 4 | `u32` | - |
| `reserved0` | 76 | 4 | 4 | `u32` | - |

### `TrayServiceResponse`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `result` | 8 | 4 | 4 | `i32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `desktop_epoch` | 16 | 8 | 8 | `u64` | - |
| `registry_revision` | 24 | 8 | 8 | `u64` | - |
| `owner` | 32 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `item_id` | 48 | 8 | 8 | `u64` | - |
| `item_revision` | 56 | 8 | 8 | `u64` | - |
| `item_flags` | 64 | 4 | 4 | `u32` | - |
| `status_flags` | 68 | 4 | 4 | `u32` | - |
| `registered_count` | 72 | 2 | 2 | `u16` | - |
| `visible_count` | 74 | 2 | 2 | `u16` | - |
| `capacity` | 76 | 2 | 2 | `u16` | - |
| `queued_events` | 78 | 2 | 2 | `u16` | - |
| `dropped_events` | 80 | 4 | 4 | `u32` | - |
| `reserved0` | 84 | 4 | 4 | `u32` | - |
| `event` | 88 | 80 | 8 | `r4os.abi.TrayEvent` | - |
| `reserved1` | 168 | 24 | 1 | `[24]u8` | - |

### `TrayDesktopExchange`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1344 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `desktop_owner` | 8 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `known_revision` | 24 | 8 | 8 | `u64` | - |
| `cursor` | 32 | 2 | 2 | `u16` | - |
| `next_cursor` | 34 | 2 | 2 | `u16` | - |
| `flags` | 36 | 4 | 4 | `u32` | - |
| `result` | 40 | 4 | 4 | `i32` | - |
| `registered_count` | 44 | 2 | 2 | `u16` | - |
| `capacity` | 46 | 2 | 2 | `u16` | - |
| `desktop_epoch` | 48 | 8 | 8 | `u64` | - |
| `registry_revision` | 56 | 8 | 8 | `u64` | - |
| `event` | 64 | 80 | 8 | `r4os.abi.TrayEvent` | - |
| `item` | 144 | 1184 | 8 | `r4os.abi.TrayServiceRequest` | - |
| `reserved0` | 1328 | 16 | 1 | `[16]u8` | - |

### `GuiGlyphBitmap`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 344 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `width` | 0 | 4 | 4 | `u32` | - |
| `height` | 4 | 4 | 4 | `u32` | - |
| `advance` | 8 | 4 | 4 | `u32` | - |
| `line_height` | 12 | 4 | 4 | `u32` | - |
| `baseline` | 16 | 4 | 4 | `i32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `rows` | 24 | 320 | 8 | `[40]u64` | - |

### `GuiXrgb32Resource`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `source_x` | 8 | 4 | 4 | `u32` | - |
| `source_y` | 12 | 4 | 4 | `u32` | - |
| `source_w` | 16 | 4 | 4 | `u32` | - |
| `source_h` | 20 | 4 | 4 | `u32` | - |
| `guest_w` | 24 | 4 | 4 | `u32` | - |
| `guest_h` | 28 | 4 | 4 | `u32` | - |
| `viewport_x` | 32 | 4 | 4 | `i32` | - |
| `viewport_y` | 36 | 4 | 4 | `i32` | - |
| `viewport_w` | 40 | 4 | 4 | `u32` | - |
| `viewport_h` | 44 | 4 | 4 | `u32` | - |
| `pixels_offset` | 48 | 4 | 4 | `u32` | - |
| `pixel_stride` | 52 | 4 | 4 | `u32` | - |
| `flags` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |

### `GuiFrameStreamInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `live_generation_count` | 12 | 4 | 4 | `u32` | - |
| `owner` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `committed_generation` | 32 | 8 | 8 | `u64` | - |
| `replacement_commit_count` | 40 | 8 | 8 | `u64` | - |
| `superseded_generation_count` | 48 | 8 | 8 | `u64` | - |
| `coalesced_generation_count` | 56 | 8 | 8 | `u64` | - |
| `reader_retired_generation_count` | 64 | 8 | 8 | `u64` | - |
| `xrgb32_nearest_command_count` | 72 | 8 | 8 | `u64` | - |
| `xrgb32_nearest_resource_bytes` | 80 | 8 | 8 | `u64` | - |
| `current_frame_bytes` | 88 | 8 | 8 | `u64` | - |
| `peak_frame_bytes` | 96 | 8 | 8 | `u64` | - |
| `reserved0` | 104 | 8 | 8 | `u64` | - |
| `shared_publish_count` | 112 | 8 | 8 | `u64` | - |
| `shared_acquire_count` | 120 | 8 | 8 | `u64` | - |
| `shared_release_count` | 128 | 8 | 8 | `u64` | - |
| `shared_backpressure_count` | 136 | 8 | 8 | `u64` | - |
| `shared_published_bytes` | 144 | 8 | 8 | `u64` | - |
| `shared_frame_bytes_avoided` | 152 | 8 | 8 | `u64` | - |
| `shared_acquired_bytes` | 160 | 8 | 8 | `u64` | - |
| `shared_live_bytes` | 168 | 8 | 8 | `u64` | - |

### `GuiSharedRasterHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 8 | 8 | `u64` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |

### `GuiSharedRasterCreateInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `format` | 8 | 4 | 4 | `u32` | - |
| `width` | 12 | 4 | 4 | `u32` | - |
| `height` | 16 | 4 | 4 | `u32` | - |
| `stride_bytes` | 20 | 4 | 4 | `u32` | - |
| `data_offset` | 24 | 4 | 4 | `u32` | - |
| `flags` | 28 | 4 | 4 | `u32` | - |
| `data_bytes` | 32 | 8 | 8 | `u64` | - |
| `reserved0` | 40 | 8 | 8 | `u64` | - |

### `GuiSharedRasterWriteMap`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 16 | 8 | `r4os.abi.GuiSharedRasterHandle` | - |
| `data_address` | 24 | 8 | 8 | `u64` | - |
| `byte_length` | 32 | 8 | 8 | `u64` | - |
| `write_token` | 40 | 8 | 8 | `u64` | - |
| `buffer_index` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |

### `GuiSharedRasterLease`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 16 | 8 | `r4os.abi.GuiSharedRasterHandle` | - |
| `raster_generation` | 24 | 8 | 8 | `u64` | - |
| `lease_token` | 32 | 8 | 8 | `u64` | - |
| `reserved0` | 40 | 8 | 8 | `u64` | - |

### `GuiSharedRasterMap`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `frame_owner` | 8 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `frame_generation` | 24 | 8 | 8 | `u64` | - |
| `lease` | 32 | 48 | 8 | `r4os.abi.GuiSharedRasterLease` | - |
| `data_address` | 80 | 8 | 8 | `u64` | - |
| `byte_length` | 88 | 8 | 8 | `u64` | - |
| `format` | 96 | 4 | 4 | `u32` | - |
| `width` | 100 | 4 | 4 | `u32` | - |
| `height` | 104 | 4 | 4 | `u32` | - |
| `stride_bytes` | 108 | 4 | 4 | `u32` | - |
| `data_offset` | 112 | 4 | 4 | `u32` | - |
| `flags` | 116 | 4 | 4 | `u32` | - |

### `GuiSharedRasterResource`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 16 | 8 | `r4os.abi.GuiSharedRasterHandle` | - |
| `raster_generation` | 24 | 8 | 8 | `u64` | - |
| `format` | 32 | 4 | 4 | `u32` | - |
| `source_x` | 36 | 4 | 4 | `u32` | - |
| `source_y` | 40 | 4 | 4 | `u32` | - |
| `source_w` | 44 | 4 | 4 | `u32` | - |
| `source_h` | 48 | 4 | 4 | `u32` | - |
| `guest_w` | 52 | 4 | 4 | `u32` | - |
| `guest_h` | 56 | 4 | 4 | `u32` | - |
| `viewport_x` | 60 | 4 | 4 | `i32` | - |
| `viewport_y` | 64 | 4 | 4 | `i32` | - |
| `viewport_w` | 68 | 4 | 4 | `u32` | - |
| `viewport_h` | 72 | 4 | 4 | `u32` | - |
| `flags` | 76 | 4 | 4 | `u32` | - |

### `TcpPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 208 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `local_mss` | 8 | 4 | 4 | `u32` | - |
| `catalog_capacity` | 12 | 4 | 4 | `u32` | - |
| `delayed_ack_ms` | 16 | 4 | 4 | `u32` | - |
| `local_window_scale` | 20 | 4 | 4 | `u32` | - |
| `outstanding_segments` | 24 | 4 | 4 | `u32` | - |
| `outstanding_bytes` | 28 | 4 | 4 | `u32` | - |
| `outstanding_segments_peak` | 32 | 4 | 4 | `u32` | - |
| `outstanding_bytes_peak` | 36 | 4 | 4 | `u32` | - |
| `write_calls` | 40 | 8 | 8 | `u64` | - |
| `write_requested_bytes` | 48 | 8 | 8 | `u64` | - |
| `write_completed_bytes` | 56 | 8 | 8 | `u64` | - |
| `write_segments` | 64 | 8 | 8 | `u64` | - |
| `write_partial` | 72 | 8 | 8 | `u64` | - |
| `remote_window_stalls` | 80 | 8 | 8 | `u64` | - |
| `catalog_stalls` | 88 | 8 | 8 | `u64` | - |
| `backend_busy_stalls` | 96 | 8 | 8 | `u64` | - |
| `pure_ack_tx` | 104 | 8 | 8 | `u64` | - |
| `delayed_ack_requests` | 112 | 8 | 8 | `u64` | - |
| `delayed_ack_tx` | 120 | 8 | 8 | `u64` | - |
| `immediate_ack_tx` | 128 | 8 | 8 | `u64` | - |
| `ack_coalesced` | 136 | 8 | 8 | `u64` | - |
| `ack_piggybacked` | 144 | 8 | 8 | `u64` | - |
| `window_update_tx` | 152 | 8 | 8 | `u64` | - |
| `adapter_poll_rounds` | 160 | 8 | 8 | `u64` | - |
| `service_poll_requests` | 168 | 8 | 8 | `u64` | - |
| `service_poll_skips` | 176 | 8 | 8 | `u64` | - |
| `retransmits` | 184 | 8 | 8 | `u64` | - |
| `mss_negotiated` | 192 | 8 | 8 | `u64` | - |
| `window_scale_negotiated` | 200 | 8 | 8 | `u64` | - |

### `StorageDeviceRef`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `slot` | 0 | 4 | 4 | `u32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |

### `StorageVolumeRef`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `slot` | 0 | 4 | 4 | `u32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |

### `StorageTarget`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `device` | 8 | 16 | 8 | `StorageDeviceRef` | - |
| `layout_generation` | 24 | 8 | 8 | `u64` | - |
| `first_lba` | 32 | 8 | 8 | `u64` | - |
| `sector_count` | 40 | 8 | 8 | `u64` | - |
| `partition_number` | 48 | 4 | 4 | `u32` | - |
| `kind` | 52 | 4 | 4 | `u32` | - |
| `partition_guid` | 56 | 16 | 1 | `[16]u8` | - |

### `StorageInventory`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `device_slots` | 16 | 4 | 4 | `u32` | - |
| `volume_slots` | 20 | 4 | 4 | `u32` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |

### `StorageDeviceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 288 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `reference` | 8 | 16 | 8 | `StorageDeviceRef` | - |
| `layout_generation` | 24 | 8 | 8 | `u64` | - |
| `sector_count` | 32 | 8 | 8 | `u64` | - |
| `disk_guid` | 40 | 16 | 1 | `[16]u8` | - |
| `first_usable` | 56 | 8 | 8 | `u64` | - |
| `last_usable` | 64 | 8 | 8 | `u64` | - |
| `bus` | 72 | 4 | 4 | `u32` | - |
| `flags` | 76 | 4 | 4 | `u32` | - |
| `sector_bytes` | 80 | 4 | 4 | `u32` | - |
| `partition_slots` | 84 | 4 | 4 | `u32` | - |
| `last_error` | 88 | 4 | 4 | `i32` | - |
| `reserved` | 92 | 4 | 4 | `u32` | - |
| `model` | 96 | 64 | 1 | `[64]u8` | - |
| `name` | 160 | 32 | 1 | `[32]u8` | - |
| `driver` | 192 | 32 | 1 | `[32]u8` | - |
| `reason` | 224 | 64 | 1 | `[64]u8` | - |

### `StoragePartitionInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `target` | 8 | 72 | 8 | `StorageTarget` | - |
| `type_guid` | 80 | 16 | 1 | `[16]u8` | - |
| `attributes` | 96 | 8 | 8 | `u64` | - |
| `filesystem` | 104 | 4 | 4 | `u32` | - |
| `flags` | 108 | 4 | 4 | `u32` | - |
| `last_error` | 112 | 4 | 4 | `i32` | - |
| `mbr_type` | 116 | 4 | 4 | `u32` | - |
| `name` | 120 | 72 | 2 | `[36]u16` | - |

### `StorageVolumeInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `reference` | 8 | 16 | 8 | `StorageVolumeRef` | - |
| `target` | 24 | 72 | 8 | `StorageTarget` | - |
| `letter` | 96 | 4 | 4 | `u32` | - |
| `filesystem` | 100 | 4 | 4 | `u32` | - |
| `role` | 104 | 4 | 4 | `u32` | - |
| `flags` | 108 | 4 | 4 | `u32` | - |

## Fehlerdomänen

### `arp`

Geltung: `arp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `arp_result_buffer_small` | -4 | `i32` |
| `arp_result_not_arp` | 1 | `i32` |
| `arp_result_ok` | 0 | `i32` |
| `arp_result_opcode` | -3 | `i32` |
| `arp_result_shape` | -2 | `i32` |
| `arp_result_short` | -1 | `i32` |

### `audio_midi`

Geltung: `audio_midi`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `audio_midi_result_bad_event` | -1 | `i32` |
| `audio_midi_result_ok` | 0 | `i32` |
| `audio_midi_result_unsupported` | -2 | `i32` |

### `audio_opl3`

Geltung: `audio_opl3`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `audio_opl3_result_bad_event` | -2 | `i32` |
| `audio_opl3_result_bad_register` | -1 | `i32` |
| `audio_opl3_result_ok` | 0 | `i32` |
| `audio_opl3_result_unsupported` | -3 | `i32` |

### `audio_service`

Geltung: `audio_service`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `audio_service_result_magic` | 1381193025 | `u32` |
| `audio_service_result_version` | 1 | `u16` |

### `audio_sid`

Geltung: `audio_sid`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `audio_sid_result_bad_address` | -3 | `i32` |
| `audio_sid_result_bad_model` | -1 | `i32` |
| `audio_sid_result_bad_register` | -2 | `i32` |
| `audio_sid_result_ok` | 0 | `i32` |
| `audio_sid_result_unsupported` | -4 | `i32` |

### `clipboard`

Geltung: `clipboard`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `clipboard_error_buffer_too_small` | -3 | `i32` |
| `clipboard_error_invalid` | -1 | `i32` |
| `clipboard_error_too_large` | -2 | `i32` |
| `clipboard_error_unsupported` | -4 | `i32` |

### `console_input_wait`

Geltung: `console_input_wait`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `console_input_wait_ready` | 1 | `i32` |
| `console_input_wait_timeout` | 0 | `i32` |
| `console_input_wait_error_invalid` | -1 | `i32` |
| `console_input_wait_error_closed` | -2 | `i32` |
| `console_input_wait_error_failed` | -3 | `i32` |
| `console_input_wait_error_unsupported` | -4 | `i32` |

### `dhcp`

Geltung: `dhcp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `dhcp_result_buffer_small` | -3 | `i32` |
| `dhcp_result_ignored` | 1 | `i32` |
| `dhcp_result_no_type` | -2 | `i32` |
| `dhcp_result_ok` | 0 | `i32` |
| `dhcp_result_shape` | -1 | `i32` |

### `dns`

Geltung: `dns`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `dns_result_aname` | -5 | `i32` |
| `dns_result_answer` | -6 | `i32` |
| `dns_result_atype` | -7 | `i32` |
| `dns_result_buffer_small` | -8 | `i32` |
| `dns_result_header` | -2 | `i32` |
| `dns_result_name` | -9 | `i32` |
| `dns_result_no_server` | -12 | `i32` |
| `dns_result_nxdomain` | -10 | `i32` |
| `dns_result_ok` | 0 | `i32` |
| `dns_result_qname` | -3 | `i32` |
| `dns_result_question` | -4 | `i32` |
| `dns_result_short` | -1 | `i32` |
| `dns_result_timeout` | -11 | `i32` |
| `dns_result_tx` | -13 | `i32` |

### `driver_work`

Geltung: `driver_work`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `driver_work_result_cancelled` | -7 | `i32` |

### `ethernet`

Geltung: `ethernet`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `ethernet_result_buffer_small` | -3 | `i32` |
| `ethernet_result_filtered` | -2 | `i32` |
| `ethernet_result_ok` | 0 | `i32` |
| `ethernet_result_short` | -1 | `i32` |

### `file_stream`

Geltung: `file_stream`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `file_stream_error_exists` | -4 | `i32` |
| `file_stream_error_invalid` | -1 | `i32` |
| `file_stream_error_io` | -5 | `i32` |
| `file_stream_error_not_found` | -3 | `i32` |
| `file_stream_error_offset_mismatch` | -6 | `i32` |
| `file_stream_error_size_mismatch` | -7 | `i32` |
| `file_stream_error_too_large` | -8 | `i32` |
| `file_stream_error_unsupported` | -2 | `i32` |
| `file_stream_result_ok` | 0 | `i32` |

### `gui_frame`

Geltung: `gui_frame`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `gui_frame_error_buffer_too_small` | -5 | `i32` |
| `gui_frame_error_invalid` | -1 | `i32` |
| `gui_frame_error_oom` | -6 | `i32` |
| `gui_frame_error_overflow` | -7 | `i32` |
| `gui_frame_error_stale` | -4 | `i32` |
| `gui_frame_error_state` | -3 | `i32` |
| `gui_frame_error_unavailable` | -2 | `i32` |
| `gui_frame_result_ok` | 0 | `i32` |

### `hid_report`

Geltung: `hid_report`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `hid_report_result_bad_length` | -2 | `i32` |
| `hid_report_result_buffer_small` | -1 | `i32` |
| `hid_report_result_ok` | 0 | `i32` |

### `icmp`

Geltung: `icmp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `icmp_result_buffer_small` | -3 | `i32` |
| `icmp_result_checksum` | -2 | `i32` |
| `icmp_result_not_icmp` | 1 | `i32` |
| `icmp_result_ok` | 0 | `i32` |
| `icmp_result_short` | -1 | `i32` |

### `io`

Geltung: `io`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `io_error_busy` | -7 | `i32` |
| `io_error_cancelled` | -9 | `i32` |
| `io_error_invalid` | -1 | `i32` |
| `io_error_lock_violation` | -11 | `i32` |
| `io_error_no_instance` | -2 | `i32` |
| `io_error_no_slots` | -3 | `i32` |
| `io_error_not_found` | -5 | `i32` |
| `io_error_spawn_failed` | -4 | `i32` |
| `io_error_timeout` | -6 | `i32` |
| `io_error_too_large` | -10 | `i32` |
| `io_error_unsupported` | -8 | `i32` |
| `io_ok` | 0 | `i32` |

### `ipv4`

Geltung: `ipv4`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `ipv4_result_buffer_small` | -7 | `i32` |
| `ipv4_result_checksum` | -5 | `i32` |
| `ipv4_result_destination` | -6 | `i32` |
| `ipv4_result_fragment` | -4 | `i32` |
| `ipv4_result_length` | -3 | `i32` |
| `ipv4_result_not_ipv4` | 1 | `i32` |
| `ipv4_result_ok` | 0 | `i32` |
| `ipv4_result_short` | -1 | `i32` |
| `ipv4_result_version` | -2 | `i32` |

### `irq`

Geltung: `irq`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `irq_result_handled` | 1 | `u32` |

### `mem`

Geltung: `mem`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `mem_error_invalid_alignment` | -2 | `i32` |
| `mem_error_invalid_pointer` | -1 | `i32` |
| `mem_error_invalid_size` | -7 | `i32` |
| `mem_error_no_instance` | -6 | `i32` |
| `mem_error_oom` | -3 | `i32` |
| `mem_error_owner_mismatch` | -4 | `i32` |
| `mem_error_retired` | -8 | `i32` |
| `mem_error_size_mismatch` | -5 | `i32` |
| `mem_ok` | 0 | `i32` |

### `memory_backing_store_slot_status`

Geltung: `memory_backing_store_slot_status`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `memory_backing_store_slot_status_error_marked` | 4 | `u32` |

### `memory_page_io_status_page_in`

Geltung: `memory_page`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `memory_page_io_status_page_in_ok` | 3 | `u32` |

### `memory_page_io_status_page_out`

Geltung: `memory_page`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `memory_page_io_status_page_out_ok` | 2 | `u32` |

### `net_config`

Geltung: `net_config`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_config_ok` | 0 | `i32` |

### `net_config_buffer_small`

Geltung: `net_config`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_config_buffer_small` | -5 | `i32` |

### `net_config_invalid_ip`

Geltung: `net_config`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_config_invalid_ip` | -1 | `i32` |

### `net_config_live_apply_failed`

Geltung: `net_config`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_config_live_apply_failed` | -3 | `i32` |

### `net_config_unsupported`

Geltung: `net_config`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_config_unsupported` | -4 | `i32` |

### `net_config_write_failed`

Geltung: `net_config`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_config_write_failed` | -2 | `i32` |

### `net_diag`

Geltung: `net_diag`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_diag_ok` | 0 | `i32` |

### `net_diag_bad_op`

Geltung: `net_diag`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_diag_bad_op` | -2 | `i32` |

### `net_diag_failed`

Geltung: `net_diag`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_diag_failed` | -1 | `i32` |

### `net_service`

Geltung: `net_service`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_result_bad_op` | -3 | `i32` |
| `net_service_result_bad_request` | -1 | `i32` |
| `net_service_result_bad_service` | -2 | `i32` |
| `net_service_result_ok` | 0 | `i32` |

### `net_service_dhcp`

Geltung: `net_service_dhcp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_dhcp_result_magic` | 1347504196 | `u32` |
| `net_service_dhcp_result_version` | 1 | `u16` |

### `net_service_dns`

Geltung: `net_service_dns`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_dns_result_magic` | 1397900356 | `u32` |
| `net_service_dns_result_version` | 1 | `u16` |

### `net_service_dns_flag`

Geltung: `net_service_dns`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_dns_flag_ok` | 1 | `u32` |

### `net_service_r4sl`

Geltung: `net_service_r4sl`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_r4sl_result_magic` | 1380725842 | `u32` |
| `net_service_r4sl_result_version` | 1 | `u16` |

### `net_service_status`

Geltung: `net_service`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_status_ok` | 2 | `u32` |

### `net_service_tcp`

Geltung: `net_service_tcp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_tcp_result_magic` | 1397900116 | `u32` |
| `net_service_tcp_result_version` | 2 | `u16` |

### `net_service_tcp_flag`

Geltung: `net_service_tcp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_tcp_flag_ok` | 1 | `u32` |

### `net_service_udp`

Geltung: `net_service_udp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_udp_result_magic` | 1380992085 | `u32` |
| `net_service_udp_result_version` | 2 | `u16` |

### `net_service_udp_flag`

Geltung: `net_service_udp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_service_udp_flag_ok` | 1 | `u32` |

### `net_tx`

Geltung: `net_tx`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `net_tx_ok` | 0 | `i32` |

### `performance_flag_memory_pager`

Geltung: `performance_flag_memory_pager`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `performance_flag_memory_pager_error_policy_ready` | 2097152 | `u32` |

### `program_handle`

Geltung: `program_handle`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `program_handle_ok` | 0 | `i32` |
| `program_handle_error_invalid` | -1 | `i32` |
| `program_handle_error_not_found` | -2 | `i32` |
| `program_handle_error_stale` | -3 | `i32` |
| `program_handle_error_not_running` | -4 | `i32` |
| `program_handle_error_would_block` | -5 | `i32` |
| `program_handle_error_timeout` | -6 | `i32` |
| `program_handle_error_self` | -7 | `i32` |
| `program_handle_error_no_memory` | -8 | `i32` |
| `program_handle_error_load_failed` | -9 | `i32` |
| `program_handle_error_task_failed` | -10 | `i32` |
| `program_handle_error_generation_exhausted` | -11 | `i32` |
| `program_handle_error_output_unavailable` | -12 | `i32` |
| `program_handle_error_output_range` | -13 | `i32` |

### `r4l`

Geltung: `r4l`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `r4l_error_not_found` | -2 | `i32` |

### `r4sl`

Geltung: `r4sl`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `r4sl_result_bad_length` | -3 | `i32` |
| `r4sl_result_bad_magic` | -1 | `i32` |
| `r4sl_result_bad_state` | -7 | `i32` |
| `r4sl_result_bad_version` | -2 | `i32` |
| `r4sl_result_buffer_small` | -6 | `i32` |
| `r4sl_result_checksum` | -4 | `i32` |
| `r4sl_result_need_more` | 1 | `i32` |
| `r4sl_result_ok` | 0 | `i32` |
| `r4sl_result_overflow` | -5 | `i32` |

### `registry_api`

Geltung: `registry_api`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `registry_api_result_bad_path` | -2 | `i32` |
| `registry_api_result_buffer_too_small` | -6 | `i32` |
| `registry_api_result_hive_corrupt` | -7 | `i32` |
| `registry_api_result_hive_not_found` | -3 | `i32` |
| `registry_api_result_invalid` | -1 | `i32` |
| `registry_api_result_io` | -8 | `i32` |
| `registry_api_result_key_not_found` | -4 | `i32` |
| `registry_api_result_ok` | 0 | `i32` |
| `registry_api_result_unsupported` | -9 | `i32` |
| `registry_api_result_value_not_found` | -5 | `i32` |

### `remote_frame`

Geltung: `remote_frame`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `remote_frame_error_buffer_too_small` | -3 | `i32` |
| `remote_frame_error_invalid` | -1 | `i32` |
| `remote_frame_error_oom` | -5 | `i32` |
| `remote_frame_error_out_of_range` | -4 | `i32` |
| `remote_frame_error_unavailable` | -2 | `i32` |
| `remote_frame_error_unsupported` | -6 | `i32` |

### `remote_input`

Geltung: `remote_input`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `remote_input_error_empty` | -2 | `i32` |
| `remote_input_error_full` | -3 | `i32` |
| `remote_input_error_invalid` | -1 | `i32` |
| `remote_input_error_unsupported` | -4 | `i32` |

### `sdk_wrapper`

Geltung: `err_no`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `err_buffer_in_use` | -9005 | `i32` |
| `err_closed` | -9003 | `i32` |
| `err_no_fn` | -9002 | `i32` |
| `err_no_group` | -9001 | `i32` |
| `err_not_owned` | -9004 | `i32` |

### `serial_link`

Geltung: `serial_link`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `serial_link_result_failed` | -4 | `i32` |
| `serial_link_result_no_port` | -1 | `i32` |
| `serial_link_result_not_initialized` | -2 | `i32` |
| `serial_link_result_ok` | 0 | `i32` |
| `serial_link_result_too_large` | -3 | `i32` |

### `service_api`

Geltung: `service_api`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `service_api_result_bad_handle` | -9 | `i32` |
| `service_api_result_bad_op` | -11 | `i32` |
| `service_api_result_bad_path` | -13 | `i32` |
| `service_api_result_buffer_too_small` | -6 | `i32` |
| `service_api_result_busy` | -7 | `i32` |
| `service_api_result_config_io` | -14 | `i32` |
| `service_api_result_disabled` | -16 | `i32` |
| `service_api_result_duplicate` | -12 | `i32` |
| `service_api_result_full` | -10 | `i32` |
| `service_api_result_invalid` | -1 | `i32` |
| `service_api_result_no_endpoint` | -4 | `i32` |
| `service_api_result_not_found` | -2 | `i32` |
| `service_api_result_not_running` | -3 | `i32` |
| `service_api_result_ok` | 0 | `i32` |
| `service_api_result_payload_too_large` | -5 | `i32` |
| `service_api_result_running` | -15 | `i32` |
| `service_api_result_self_restart` | -19 | `i32` |
| `service_api_result_spawn_failed` | -17 | `i32` |
| `service_api_result_stop_failed` | -18 | `i32` |
| `service_api_result_timeout` | -8 | `i32` |

### `storage_backend_status`

Geltung: `storage_backend`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `storage_backend_status_ok` | 0 | `i32` |

### `storage_backend_status_error`

Geltung: `storage_backend`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `storage_backend_status_error` | -1 | `i32` |

### `tcp`

Geltung: `tcp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `tcp_result_bad_state` | -2 | `i32` |
| `tcp_result_buffer_small` | -3 | `i32` |
| `tcp_result_checksum` | -5 | `i32` |
| `tcp_result_no_connection` | -1 | `i32` |
| `tcp_result_not_tcp` | 1 | `i32` |
| `tcp_result_ok` | 0 | `i32` |
| `tcp_result_short` | -4 | `i32` |

### `thread`

Geltung: `thread`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `thread_error_busy` | -7 | `i32` |
| `thread_error_invalid` | -1 | `i32` |
| `thread_error_no_instance` | -2 | `i32` |
| `thread_error_no_memory` | -4 | `i32` |
| `thread_error_no_slots` | -3 | `i32` |
| `thread_error_not_found` | -5 | `i32` |
| `thread_error_not_joinable` | -9 | `i32` |
| `thread_error_self_join` | -6 | `i32` |
| `thread_error_timeout` | -8 | `i32` |
| `thread_error_unsupported` | -10 | `i32` |
| `thread_ok` | 0 | `i32` |

### `udp`

Geltung: `udp`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `udp_result_buffer_small` | -4 | `i32` |
| `udp_result_checksum` | -3 | `i32` |
| `udp_result_length` | -2 | `i32` |
| `udp_result_not_udp` | 1 | `i32` |
| `udp_result_ok` | 0 | `i32` |
| `udp_result_short` | -1 | `i32` |

### `usb_hid_boot`

Geltung: `usb_hid_boot`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `usb_hid_boot_result_bad_interface` | -2 | `i32` |
| `usb_hid_boot_result_ignored` | 1 | `i32` |
| `usb_hid_boot_result_ok` | 0 | `i32` |
| `usb_hid_boot_result_short` | -1 | `i32` |

### `usb_msc_bot`

Geltung: `usb_msc_bot`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `usb_msc_bot_result_bad_cdb` | -1 | `i32` |
| `usb_msc_bot_result_bad_csw` | -2 | `i32` |
| `usb_msc_bot_result_command_failed` | 1 | `i32` |
| `usb_msc_bot_result_ok` | 0 | `i32` |
| `usb_msc_bot_result_phase_error` | -5 | `i32` |
| `usb_msc_bot_result_residue` | -4 | `i32` |
| `usb_msc_bot_result_tag_mismatch` | -3 | `i32` |
| `usb_msc_bot_result_unsupported_status` | -6 | `i32` |

### `usb_scsi`

Geltung: `usb_scsi`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `usb_scsi_result_bad_param` | -1 | `i32` |
| `usb_scsi_result_bad_response` | -2 | `i32` |
| `usb_scsi_result_ok` | 0 | `i32` |
| `usb_scsi_result_unsupported` | -3 | `i32` |

### `vm`

Geltung: `vm`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `vm_error_already_committed` | -7 | `i32` |
| `vm_error_guard_range` | -9 | `i32` |
| `vm_error_invalid_alignment` | -2 | `i32` |
| `vm_error_invalid_range` | -1 | `i32` |
| `vm_error_limit_exceeded` | -13 | `i32` |
| `vm_error_map_failed` | -10 | `i32` |
| `vm_error_no_instance` | -12 | `i32` |
| `vm_error_no_space` | -5 | `i32` |
| `vm_error_not_committed` | -8 | `i32` |
| `vm_error_out_of_memory` | -6 | `i32` |
| `vm_error_owner_mismatch` | -3 | `i32` |
| `vm_error_table_full` | -4 | `i32` |
| `vm_error_unsupported_flags` | -11 | `i32` |
| `vm_ok` | 0 | `i32` |

### `window_service`

Geltung: `window_service`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `window_service_result_bad_request` | -3 | `i32` |
| `window_service_result_full` | -2 | `i32` |
| `window_service_result_magic` | 1364676183 | `u32` |
| `window_service_result_not_found` | -1 | `i32` |
| `window_service_result_ok` | 0 | `i32` |
| `window_service_result_version` | 1 | `u16` |

### `storage`

Geltung: `storage`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `storage_result_ok` | 0 | `i32` |
| `storage_result_present` | 1 | `i32` |
| `storage_result_absent` | 0 | `i32` |
| `storage_error_invalid` | -1 | `i32` |
| `storage_error_stale` | -2 | `i32` |
| `storage_error_busy` | -3 | `i32` |
| `storage_error_protected` | -4 | `i32` |
| `storage_error_capacity` | -5 | `i32` |
| `storage_error_owner` | -6 | `i32` |
| `storage_error_io` | -7 | `i32` |
| `storage_error_unsupported` | -8 | `i32` |
| `storage_error_remount` | -9 | `i32` |
| `storage_error_incomplete` | -10 | `i32` |
| `storage_error_not_found` | -11 | `i32` |

## Konstanten

| Name | Wert | Typ | Kategorie | Einheit | Geltung | Stabilität |
|---|---|---|---|---|---|---|
| `arch_x86_64` | `1` | `u16` | value | number | `arch_x86` | fixed_contract |
| `arp_flag_reply` | `2` | `u32` | flag | bitmask | `arp` | fixed_contract |
| `arp_flag_request` | `1` | `u32` | flag | bitmask | `arp` | fixed_contract |
| `arp_op_build_request` | `3` | `u32` | identity | number | `arp_op` | fixed_contract |
| `arp_op_handle_rx` | `1` | `u32` | identity | number | `arp_op` | fixed_contract |
| `arp_op_handle_tx` | `2` | `u32` | identity | number | `arp_op` | fixed_contract |
| `audio_backend_format_s16le` | `1` | `u32` | value | number | `audio_backend` | fixed_contract |
| `audio_backend_format_u8` | `2` | `u32` | value | number | `audio_backend` | fixed_contract |
| `audio_backend_version` | `2` | `u32` | version | number | `audio_backend` | fixed_contract |
| `audio_midi_event_channel_pressure` | `5` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_event_control` | `3` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_event_ignore` | `0` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_event_note_off` | `1` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_event_note_on` | `2` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_event_pitch_bend` | `6` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_event_program` | `4` | `u8` | value | number | `audio_midi` | fixed_contract |
| `audio_midi_op_classify_event` | `1` | `u32` | identity | number | `audio_midi` | fixed_contract |
| `audio_midi_op_self_test` | `2` | `u32` | identity | number | `audio_midi` | fixed_contract |
| `audio_master_request_flag_muted` | `4` | `u32` | flag | bitmask | `audio_master_request` | fixed_contract |
| `audio_master_request_flag_set_muted` | `2` | `u32` | flag | bitmask | `audio_master_request` | fixed_contract |
| `audio_master_request_flag_set_volume` | `1` | `u32` | flag | bitmask | `audio_master_request` | fixed_contract |
| `audio_master_request_magic` | `1296118866` | `u32` | magic | number | `audio_master_request` | fixed_contract |
| `audio_master_request_version` | `1` | `u16` | version | number | `audio_master_request` | fixed_contract |
| `audio_master_state_flag_config_defaulted` | `4` | `u32` | flag | bitmask | `audio_master_state` | fixed_contract |
| `audio_master_state_flag_config_error` | `16` | `u32` | flag | bitmask | `audio_master_state` | fixed_contract |
| `audio_master_state_flag_config_loaded` | `2` | `u32` | flag | bitmask | `audio_master_state` | fixed_contract |
| `audio_master_state_flag_muted` | `1` | `u32` | flag | bitmask | `audio_master_state` | fixed_contract |
| `audio_master_state_flag_persist_pending` | `8` | `u32` | flag | bitmask | `audio_master_state` | fixed_contract |
| `audio_master_state_magic` | `1396782162` | `u32` | magic | number | `audio_master_state` | fixed_contract |
| `audio_master_state_version` | `1` | `u16` | version | number | `audio_master_state` | fixed_contract |
| `audio_opl3_action_all_notes_off` | `5` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_action_control` | `4` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_action_ignore` | `0` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_action_note_off` | `2` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_action_note_on` | `1` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_action_program` | `3` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_op_midi_event` | `3` | `u32` | identity | number | `audio_opl3` | fixed_contract |
| `audio_opl3_op_reset` | `1` | `u32` | identity | number | `audio_opl3` | fixed_contract |
| `audio_opl3_op_self_test` | `4` | `u32` | identity | number | `audio_opl3` | fixed_contract |
| `audio_opl3_op_write_register` | `2` | `u32` | identity | number | `audio_opl3` | fixed_contract |
| `audio_opl3_write_channel` | `3` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_write_global` | `1` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_write_operator` | `2` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_opl3_write_other` | `0` | `u8` | value | number | `audio_opl3` | fixed_contract |
| `audio_service_flag_backend_present` | `1` | `u32` | flag | bitmask | `audio_service` | fixed_contract |
| `audio_service_flag_mixer_present` | `2` | `u32` | flag | bitmask | `audio_service` | fixed_contract |
| `audio_service_flag_service_ready` | `8` | `u32` | flag | bitmask | `audio_service` | fixed_contract |
| `audio_service_flag_sessions_open` | `4` | `u32` | flag | bitmask | `audio_service` | fixed_contract |
| `audio_service_op_close_stream` | `5` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_master_status` | `7` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_open_stream` | `3` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_set_master_volume` | `2` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_set_master_state` | `8` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_set_stream_volume` | `6` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_status` | `1` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_op_write_stream` | `4` | `u16` | identity | number | `audio_service` | fixed_contract |
| `audio_service_request_magic` | `1364350273` | `u32` | magic | number | `audio_service_request` | fixed_contract |
| `audio_service_request_version` | `1` | `u16` | version | number | `audio_service_request` | fixed_contract |
| `audio_service_status_magic` | `1397970241` | `u32` | magic | number | `audio_service_status` | fixed_contract |
| `audio_service_status_version` | `2` | `u16` | version | number | `audio_service_status` | fixed_contract |
| `audio_sid_model_6581` | `2` | `u8` | value | number | `audio_sid` | fixed_contract |
| `audio_sid_model_8580` | `1` | `u8` | value | number | `audio_sid` | fixed_contract |
| `audio_sid_op_configure_model` | `1` | `u32` | identity | number | `audio_sid` | fixed_contract |
| `audio_sid_op_resolve_io` | `3` | `u32` | identity | number | `audio_sid` | fixed_contract |
| `audio_sid_op_self_test` | `4` | `u32` | identity | number | `audio_sid` | fixed_contract |
| `audio_sid_op_write_register` | `2` | `u32` | identity | number | `audio_sid` | fixed_contract |
| `audio_sid_register_filter` | `2` | `u8` | value | number | `audio_sid` | fixed_contract |
| `audio_sid_register_other` | `0` | `u8` | value | number | `audio_sid` | fixed_contract |
| `audio_sid_register_readback` | `4` | `u8` | value | number | `audio_sid` | fixed_contract |
| `audio_sid_register_voice` | `1` | `u8` | value | number | `audio_sid` | fixed_contract |
| `audio_sid_register_volume` | `3` | `u8` | value | number | `audio_sid` | fixed_contract |
| `boot_info_flag_has_edid` | `32` | `u32` | flag | bitmask | `boot_info` | fixed_contract |
| `boot_info_flag_has_framebuffer` | `8` | `u32` | flag | bitmask | `boot_info` | fixed_contract |
| `boot_info_flag_has_hhdm` | `4` | `u32` | flag | bitmask | `boot_info` | fixed_contract |
| `boot_info_flag_has_rsdp` | `16` | `u32` | flag | bitmask | `boot_info` | fixed_contract |
| `boot_info_flag_initialized` | `1` | `u32` | flag | bitmask | `boot_info` | fixed_contract |
| `boot_info_flag_memory_map_truncated` | `2` | `u32` | flag | bitmask | `boot_info` | fixed_contract |
| `boot_log_flag_wrapped` | `1` | `u32` | flag | bitmask | `boot_log` | fixed_contract |
| `boot_memory_kind_acpi_nvs` | `3` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_acpi_reclaimable` | `2` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_bad_memory` | `4` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_bootloader_reclaimable` | `5` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_framebuffer` | `7` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_kernel_and_modules` | `6` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_reserved` | `1` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_unknown` | `8` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `boot_memory_kind_usable` | `0` | `u8` | identity | number | `boot_memory` | fixed_contract |
| `clipboard_flag_has_text` | `1` | `u32` | flag | bitmask | `clipboard` | fixed_contract |
| `clipboard_flag_text` | `2` | `u32` | flag | bitmask | `clipboard` | fixed_contract |
| `clipboard_service_op_clear` | `4` | `u16` | identity | number | `clipboard_service` | fixed_contract |
| `clipboard_service_op_info` | `3` | `u16` | identity | number | `clipboard_service` | fixed_contract |
| `clipboard_service_op_read` | `2` | `u16` | identity | number | `clipboard_service` | fixed_contract |
| `clipboard_service_op_revision` | `5` | `u16` | identity | number | `clipboard_service` | fixed_contract |
| `clipboard_service_op_write` | `1` | `u16` | identity | number | `clipboard_service` | fixed_contract |
| `clock_format_12h` | `1` | `u32` | value | number | `clock_format` | fixed_contract |
| `clock_format_24h` | `0` | `u32` | value | number | `clock_format` | fixed_contract |
| `dhcp_flag_ack` | `8` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_flag_bound` | `16` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_flag_discover` | `1` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_flag_nak` | `32` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_flag_offer` | `2` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_flag_release` | `64` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_flag_request` | `4` | `u32` | flag | bitmask | `dhcp` | fixed_contract |
| `dhcp_op_build_discover` | `1` | `u32` | identity | number | `dhcp_op` | fixed_contract |
| `dhcp_op_build_release` | `4` | `u32` | identity | number | `dhcp_op` | fixed_contract |
| `dhcp_op_build_request` | `2` | `u32` | identity | number | `dhcp_op` | fixed_contract |
| `dhcp_op_handle_message` | `3` | `u32` | identity | number | `dhcp_op` | fixed_contract |
| `dhcp_status_flag_bound` | `1` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `dhcp_status_flag_desired` | `8` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `dhcp_status_flag_dns_configured` | `2` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `dhcp_status_flag_link_up` | `32` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `dhcp_status_flag_pending` | `4` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `dhcp_status_flag_retry_wait` | `64` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `dhcp_status_flag_task_started` | `16` | `u32` | flag | bitmask | `dhcp_status` | fixed_contract |
| `display_damage_max_regions` | `8` | `u32` | value | count | `display_present` | fixed_contract |
| `display_present_backend_bootfb_cpu` | `1` | `u32` | value | number | `display_present` | fixed_contract |
| `display_present_backend_external_blit` | `2` | `u32` | value | number | `display_present` | fixed_contract |
| `display_present_cap_accelerated_blit` | `8` | `u32` | flag | bitmask | `display_present` | fixed_contract |
| `display_present_cap_cpu_fallback` | `1` | `u32` | flag | bitmask | `display_present` | fixed_contract |
| `display_present_cap_exact_regions` | `2` | `u32` | flag | bitmask | `display_present` | fixed_contract |
| `display_present_cap_external_backend` | `16` | `u32` | flag | bitmask | `display_present` | fixed_contract |
| `display_present_cap_sync_fence` | `4` | `u32` | flag | bitmask | `display_present` | fixed_contract |
| `display_present_completion_complete` | `1` | `u32` | flag | bitmask | `display_present_completion` | fixed_contract |
| `display_present_error_invalid` | `-1` | `i32` | value | number | `display_present` | fixed_contract |
| `display_present_error_out_of_range` | `-2` | `i32` | value | number | `display_present` | fixed_contract |
| `display_present_error_unavailable` | `-3` | `i32` | value | number | `display_present` | fixed_contract |
| `display_present_format_xrgb32` | `1` | `u32` | value | number | `display_present` | fixed_contract |
| `display_present_magic` | `1346647122` | `u32` | magic | number | `display_present` | fixed_contract |
| `display_present_request_flag_input_tick_valid` | `1` | `u32` | flag | bitmask | `display_present_request` | fixed_contract |
| `display_present_result_accelerated` | `4` | `u32` | flag | bitmask | `display_present_result` | fixed_contract |
| `display_present_result_completed` | `2` | `u32` | flag | bitmask | `display_present_result` | fixed_contract |
| `display_present_result_fallback` | `8` | `u32` | flag | bitmask | `display_present_result` | fixed_contract |
| `display_present_result_success` | `1` | `u32` | flag | bitmask | `display_present_result` | fixed_contract |
| `display_present_version` | `1` | `u16` | version | number | `display_present` | fixed_contract |
| `display_summary_backend_bootfb` | `1` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_backend_none` | `0` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_cache_bootloader_default` | `1` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_cache_pat_write_combining` | `2` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_cache_unknown` | `0` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_cache_write_combining_failed` | `4` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_cache_write_combining_unsupported` | `3` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_flag_cpu_present` | `8` | `u32` | flag | bitmask | `display_summary` | fixed_contract |
| `display_summary_flag_fixed_mode` | `4` | `u32` | flag | bitmask | `display_summary` | fixed_contract |
| `display_summary_flag_registered` | `1` | `u32` | flag | bitmask | `display_summary` | fixed_contract |
| `display_summary_flag_visible` | `2` | `u32` | flag | bitmask | `display_summary` | fixed_contract |
| `display_summary_flag_xrgb32` | `16` | `u32` | flag | bitmask | `display_summary` | fixed_contract |
| `display_summary_reason_fill` | `1` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_reason_none` | `0` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_reason_packed32_present` | `3` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_reason_rect` | `2` | `u8` | value | number | `display_summary` | fixed_contract |
| `display_summary_reason_xrgb32_present` | `4` | `u8` | value | number | `display_summary` | fixed_contract |
| `dns_flag_a_record` | `1` | `u32` | flag | bitmask | `dns` | fixed_contract |
| `dns_op_build_a_query` | `1` | `u32` | identity | number | `dns_op` | fixed_contract |
| `dns_op_handle_response` | `2` | `u32` | identity | number | `dns_op` | fixed_contract |
| `driver_api_version` | `24` | `u32` | version | number | `driver_api` | fixed_contract |
| `driver_magic` | `826888260` | `u32` | magic | number | `driver` | fixed_contract |
| `driver_work_flag_from_irq` | `1` | `u32` | flag | bitmask | `driver_work` | fixed_contract |
| `driver_work_flag_none` | `0` | `u32` | flag | bitmask | `driver_work` | fixed_contract |
| `driver_work_state_cancelled` | `4` | `u32` | identity | number | `driver_work` | fixed_contract |
| `driver_work_state_completed` | `3` | `u32` | identity | number | `driver_work` | fixed_contract |
| `driver_work_state_free` | `0` | `u32` | identity | number | `driver_work` | fixed_contract |
| `driver_work_state_queued` | `1` | `u32` | identity | number | `driver_work` | fixed_contract |
| `driver_work_state_running` | `2` | `u32` | identity | number | `driver_work` | fixed_contract |
| `driver_work_version` | `1` | `u32` | version | number | `driver_work` | fixed_contract |
| `ethernet_flag_arp` | `8` | `u32` | flag | bitmask | `ethernet` | fixed_contract |
| `ethernet_flag_broadcast` | `1` | `u32` | flag | bitmask | `ethernet` | fixed_contract |
| `ethernet_flag_ipv4` | `4` | `u32` | flag | bitmask | `ethernet` | fixed_contract |
| `ethernet_flag_own_unicast` | `2` | `u32` | flag | bitmask | `ethernet` | fixed_contract |
| `ethernet_flag_r4os_diag` | `16` | `u32` | flag | bitmask | `ethernet` | fixed_contract |
| `ethernet_flag_unknown_type` | `32` | `u32` | flag | bitmask | `ethernet` | fixed_contract |
| `ethernet_op_build_diag_frame` | `4` | `u32` | identity | number | `ethernet_op` | fixed_contract |
| `ethernet_op_frame_type` | `3` | `u32` | identity | number | `ethernet_op` | fixed_contract |
| `ethernet_op_handle_rx` | `1` | `u32` | identity | number | `ethernet_op` | fixed_contract |
| `ethernet_op_handle_tx` | `2` | `u32` | identity | number | `ethernet_op` | fixed_contract |
| `fat_path_component_max_bytes` | `767` | `u16` | value | bytes | `text_path_time` | fixed_contract |
| `file_path_max_bytes` | `1023` | `u16` | value | bytes | `text_path_time` | fixed_contract |
| `file_path_max_chars` | `260` | `u16` | value | chars | `text_path_time` | fixed_contract |
| `file_stream_open_create` | `1` | `u32` | value | number | `file_stream` | fixed_contract |
| `file_stream_open_lease` | `4` | `u32` | value | number | `file_stream` | fixed_contract |
| `file_stream_open_replace` | `3` | `u32` | value | number | `file_stream` | fixed_contract |
| `file_stream_open_truncate` | `2` | `u32` | value | number | `file_stream` | fixed_contract |
| `file_stream_publish_protocol_ftp` | `2` | `u32` | value | number | `file_stream_publish_protocol` | fixed_contract |
| `file_stream_publish_protocol_scp` | `1` | `u32` | value | number | `file_stream_publish_protocol` | fixed_contract |
| `file_stream_publish_protocol_sftp` | `0` | `u32` | value | number | `file_stream_publish_protocol` | fixed_contract |
| `fs_cache_pagefile_blocker_no_global_reclaim` | `8` | `u32` | value | number | `fs_cache` | fixed_contract |
| `fs_cache_pagefile_blocker_no_pagefile` | `1` | `u32` | value | number | `fs_cache` | fixed_contract |
| `fs_cache_pagefile_blocker_no_pager` | `16` | `u32` | value | number | `fs_cache` | fixed_contract |
| `fs_cache_pagefile_blocker_no_swap` | `2` | `u32` | value | number | `fs_cache` | fixed_contract |
| `fs_cache_pagefile_blocker_static_cache` | `4` | `u32` | value | number | `fs_cache` | fixed_contract |
| `gui_frame_command_kind_alpha8` | `5` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_clear` | `1` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_none` | `0` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_raster` | `4` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_rect` | `2` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_text` | `3` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_path_fill` | `6` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_path_stroke` | `7` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_rounded_rect` | `8` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_shadow` | `9` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_argb32` | `10` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_indexed8` | `11` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_command_kind_xrgb32_nearest` | `12` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_path_segment_kind_close` | `5` | `u32` | value | number | `gui_path` | fixed_contract |
| `gui_path_segment_kind_cubic` | `4` | `u32` | value | number | `gui_path` | fixed_contract |
| `gui_path_segment_kind_line` | `2` | `u32` | value | number | `gui_path` | fixed_contract |
| `gui_path_segment_kind_move` | `1` | `u32` | value | number | `gui_path` | fixed_contract |
| `gui_path_segment_kind_quadratic` | `3` | `u32` | value | number | `gui_path` | fixed_contract |
| `gui_path_segment_size` | `32` | `u32` | value | bytes | `gui_path` | fixed_contract |
| `gui_shape_fill_rule_evenodd` | `2` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_fill_rule_nonzero` | `1` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_flag_shadow_inset` | `1` | `u32` | flag | bitmask | `gui_shape` | fixed_contract |
| `gui_shape_geometry_kind_path` | `1` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_geometry_kind_rounded_rect` | `2` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_line_cap_butt` | `1` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_line_cap_round` | `2` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_line_cap_square` | `3` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_line_join_bevel` | `3` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_line_join_miter` | `1` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_line_join_round` | `2` | `u32` | value | number | `gui_shape` | fixed_contract |
| `gui_shape_max_blur_radius` | `64` | `u32` | value | pixels | `gui_shape` | fixed_contract |
| `gui_shape_max_coordinate` | `1048576` | `u32` | value | pixels | `gui_shape` | fixed_contract |
| `gui_shape_max_dimension` | `4096` | `u32` | value | pixels | `gui_shape` | fixed_contract |
| `gui_shape_max_pixels` | `4194304` | `u32` | value | pixels | `gui_shape` | fixed_contract |
| `gui_shape_max_segments` | `4096` | `u32` | value | records | `gui_shape` | fixed_contract |
| `gui_shape_resource_size` | `160` | `u32` | value | bytes | `gui_shape` | fixed_contract |
| `gui_shape_resource_version` | `1` | `u32` | version | number | `gui_shape` | fixed_contract |
| `gui_frame_command_size` | `96` | `u32` | value | bytes | `gui_frame` | fixed_contract |
| `gui_frame_command_version` | `1` | `u32` | version | number | `gui_frame` | fixed_contract |
| `gui_frame_flag_building` | `2` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_flag_committed` | `1` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_flag_last_oom` | `4` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_info_size` | `176` | `u32` | value | bytes | `gui_frame` | fixed_contract |
| `gui_frame_info_version` | `1` | `u32` | version | number | `gui_frame` | fixed_contract |
| `gui_frame_generation_flag_delta` | `2` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_generation_flag_full` | `1` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_generation_flag_indexed8` | `4` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_generation_flag_replacement` | `8` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_frame_generation_info_size` | `144` | `u32` | value | bytes | `gui_frame` | fixed_contract |
| `gui_frame_generation_info_version` | `1` | `u32` | version | number | `gui_frame` | fixed_contract |
| `gui_frame_stream_info_size` | `112` | `u32` | value | bytes | `gui_frame` | fixed_contract |
| `gui_frame_stream_info_version` | `1` | `u32` | version | number | `gui_frame` | fixed_contract |
| `gui_frame_max_damage_regions` | `8` | `u32` | value | records | `gui_frame` | fixed_contract |
| `gui_frame_max_delta_chain` | `32` | `u32` | value | generations | `gui_frame` | fixed_contract |
| `gui_indexed8_palette_entries` | `256` | `u32` | value | entries | `gui_indexed8` | fixed_contract |
| `gui_indexed8_palette_offset` | `64` | `u32` | value | bytes | `gui_indexed8` | fixed_contract |
| `gui_indexed8_pixels_offset` | `1088` | `u32` | value | bytes | `gui_indexed8` | fixed_contract |
| `gui_indexed8_resource_size` | `64` | `u32` | value | bytes | `gui_indexed8` | fixed_contract |
| `gui_indexed8_resource_version` | `1` | `u32` | version | number | `gui_indexed8` | fixed_contract |
| `gui_xrgb32_pixels_offset` | `64` | `u32` | value | bytes | `gui_xrgb32` | fixed_contract |
| `gui_xrgb32_resource_size` | `64` | `u32` | value | bytes | `gui_xrgb32` | fixed_contract |
| `gui_xrgb32_resource_version` | `1` | `u32` | version | number | `gui_xrgb32` | fixed_contract |
| `gui_frame_state_building` | `1` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_state_idle` | `0` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_font_builtin_id` | `0` | `u32` | value | number | `gui_font` | fixed_contract |
| `gui_font_flag_builtin` | `4` | `u32` | flag | bitmask | `gui_font` | fixed_contract |
| `gui_font_flag_renderable` | `1` | `u32` | flag | bitmask | `gui_font` | fixed_contract |
| `gui_font_flag_selected` | `2` | `u32` | flag | bitmask | `gui_font` | fixed_contract |
| `gui_text_flag_clipped` | `1` | `u32` | flag | bitmask | `gui_text` | fixed_contract |
| `hardware_summary_flag_acpi` | `1` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_ahci` | `64` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_hpet` | `16` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_ioapic` | `8` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_legacy_pci` | `4` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_nvme` | `128` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_pcie` | `2` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_usb_configured` | `256` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hardware_summary_flag_xhci` | `32` | `u32` | flag | bitmask | `hardware_summary` | fixed_contract |
| `hid_report_kind_feature` | `2` | `u8` | identity | number | `hid_report` | fixed_contract |
| `hid_report_kind_input` | `0` | `u8` | identity | number | `hid_report` | fixed_contract |
| `hid_report_kind_output` | `1` | `u8` | identity | number | `hid_report` | fixed_contract |
| `hid_report_op_parse` | `1` | `u32` | identity | number | `hid_report` | fixed_contract |
| `hid_report_op_self_test` | `2` | `u32` | identity | number | `hid_report` | fixed_contract |
| `hid_report_reason_not_parsed` | `1` | `u16` | value | number | `hid_report` | fixed_contract |
| `hid_report_reason_parsed` | `0` | `u16` | value | number | `hid_report` | fixed_contract |
| `hid_report_reason_truncated_long_item` | `2` | `u16` | value | number | `hid_report` | fixed_contract |
| `hid_report_reason_truncated_long_payload` | `3` | `u16` | value | number | `hid_report` | fixed_contract |
| `hid_report_reason_truncated_short_item` | `4` | `u16` | value | number | `hid_report` | fixed_contract |
| `icmp_flag_echo_reply` | `2` | `u32` | flag | bitmask | `icmp` | fixed_contract |
| `icmp_flag_echo_request` | `1` | `u32` | flag | bitmask | `icmp` | fixed_contract |
| `icmp_op_build_echo_reply` | `4` | `u32` | identity | number | `icmp_op` | fixed_contract |
| `icmp_op_build_echo_request` | `3` | `u32` | identity | number | `icmp_op` | fixed_contract |
| `icmp_op_handle_rx` | `1` | `u32` | identity | number | `icmp_op` | fixed_contract |
| `icmp_op_handle_tx` | `2` | `u32` | identity | number | `icmp_op` | fixed_contract |
| `icmp_op_is_echo_request` | `5` | `u32` | identity | number | `icmp_op` | fixed_contract |
| `io_file_lock_flag_unlock` | `1` | `u32` | flag | bitmask | `io_file_lock` | fixed_contract |
| `io_info_version` | `1` | `u32` | version | number | `io_info` | fixed_contract |
| `io_kind_file_append` | `4` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_info` | `11` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_lock` | `12` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_read` | `1` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_read_at` | `2` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_stream_abort` | `8` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_stream_begin` | `5` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_stream_finish` | `7` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_stream_write` | `6` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_write` | `3` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_file_write_at` | `10` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_none` | `0` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_kind_service_call` | `9` | `u32` | identity | number | `io_kind` | fixed_contract |
| `io_state_completed` | `3` | `u32` | identity | number | `io_state` | fixed_contract |
| `io_state_failed` | `4` | `u32` | identity | number | `io_state` | fixed_contract |
| `io_state_pending` | `1` | `u32` | identity | number | `io_state` | fixed_contract |
| `io_state_running` | `2` | `u32` | identity | number | `io_state` | fixed_contract |
| `io_state_unused` | `0` | `u32` | identity | number | `io_state` | fixed_contract |
| `ipc_channel_echo` | `1` | `u32` | value | number | `ipc_channel` | fixed_contract |
| `ipc_channel_net_dhcp` | `2` | `u32` | value | number | `ipc_channel` | fixed_contract |
| `ipc_channel_net_dns` | `3` | `u32` | value | number | `ipc_channel` | fixed_contract |
| `ipc_channel_net_tcp` | `4` | `u32` | value | number | `ipc_channel` | fixed_contract |
| `ipc_channel_net_udp` | `5` | `u32` | value | number | `ipc_channel` | fixed_contract |
| `ipv4_op_build_packet` | `3` | `u32` | identity | number | `ipv4_op` | fixed_contract |
| `ipv4_op_handle_rx` | `1` | `u32` | identity | number | `ipv4_op` | fixed_contract |
| `ipv4_op_handle_tx` | `2` | `u32` | identity | number | `ipv4_op` | fixed_contract |
| `irq_flag_level_low` | `2` | `u32` | flag | bitmask | `irq` | fixed_contract |
| `irq_flag_msi` | `4` | `u32` | flag | bitmask | `irq` | fixed_contract |
| `irq_flag_shared` | `1` | `u32` | flag | bitmask | `irq` | fixed_contract |
| `line_ending_crlf` | `2` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `line_ending_lf` | `1` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `line_ending_mixed` | `3` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `line_ending_none` | `0` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `loader_service_boot_status_failed` | `3` | `u32` | value | number | `loader_service` | fixed_contract |
| `loader_service_boot_status_not_attempted` | `0` | `u32` | value | number | `loader_service` | fixed_contract |
| `loader_service_boot_status_not_found` | `2` | `u32` | value | number | `loader_service` | fixed_contract |
| `loader_service_boot_status_ran` | `1` | `u32` | value | number | `loader_service` | fixed_contract |
| `log_record_type_console_output` | `2` | `u8` | value | number | `log_record` | fixed_contract |
| `log_record_type_diagnostic_snapshot` | `3` | `u8` | value | number | `log_record` | fixed_contract |
| `log_record_type_event` | `0` | `u8` | value | number | `log_record` | fixed_contract |
| `log_record_type_file_record` | `4` | `u8` | value | number | `log_record` | fixed_contract |
| `log_record_type_status_snapshot` | `1` | `u8` | value | number | `log_record` | fixed_contract |
| `log_service_export_magic` | `1481066316` | `u32` | magic | number | `log_service_export` | fixed_contract |
| `log_service_op_export` | `1824` | `u16` | identity | number | `log_service` | fixed_contract |
| `log_service_op_records` | `1795` | `u16` | identity | number | `log_service` | fixed_contract |
| `log_service_op_sources` | `1794` | `u16` | identity | number | `log_service` | fixed_contract |
| `log_service_op_status` | `1793` | `u16` | identity | number | `log_service` | fixed_contract |
| `log_service_op_write` | `1808` | `u16` | identity | number | `log_service` | fixed_contract |
| `log_service_page_flag_more` | `1` | `u32` | flag | bitmask | `log_service_page` | fixed_contract |
| `log_service_query_magic` | `1363625804` | `u32` | magic | number | `log_service_query` | fixed_contract |
| `log_service_record_flag_imported` | `2` | `u32` | flag | bitmask | `log_service_record` | fixed_contract |
| `log_service_record_flag_truncated` | `1` | `u32` | flag | bitmask | `log_service_record` | fixed_contract |
| `log_service_record_magic` | `1380140876` | `u32` | magic | number | `log_service_record` | fixed_contract |
| `log_service_record_page_magic` | `1346586444` | `u32` | magic | number | `log_service_record_page` | fixed_contract |
| `log_service_records_per_page` | `16` | `usize` | value | number | `log_service` | fixed_contract |
| `log_service_source_any` | `0` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_application` | `4` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_bootlog` | `1` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_console` | `6` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_diagnostic` | `7` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_driver` | `2` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_file` | `8` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_page_magic` | `1347635020` | `u32` | magic | number | `log_service_source_page` | fixed_contract |
| `log_service_source_protocol` | `3` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_source_service` | `5` | `u32` | value | number | `log_service` | fixed_contract |
| `log_service_sources_per_page` | `8` | `usize` | value | number | `log_service` | fixed_contract |
| `log_service_status_flag_bootlog_loaded` | `1` | `u32` | flag | bitmask | `log_service_status` | fixed_contract |
| `log_service_status_magic` | `1397966668` | `u32` | magic | number | `log_service_status` | fixed_contract |
| `log_service_version` | `1` | `u16` | version | number | `log_service` | fixed_contract |
| `log_service_write_magic` | `1464289100` | `u32` | magic | number | `log_service_write` | fixed_contract |
| `log_severity_debug` | `0` | `u8` | value | number | `log_severity` | fixed_contract |
| `log_severity_error` | `3` | `u8` | value | number | `log_severity` | fixed_contract |
| `log_severity_info` | `1` | `u8` | value | number | `log_severity` | fixed_contract |
| `log_severity_warn` | `2` | `u8` | value | number | `log_severity` | fixed_contract |
| `memory_backing_store_blocker_directory` | `8` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_blocker_invalid_request` | `1` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_blocker_missing_file` | `4` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_blocker_too_small` | `16` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_blocker_unaligned_request` | `64` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_blocker_unsupported_flags` | `2` | `u32` | flag | bitmask | `memory_backing` | fixed_contract |
| `memory_backing_store_blocker_unsupported_fs` | `32` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_flag_existing_file` | `2` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_fat32` | `4` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_file_backed` | `1` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_no_second_io_path` | `64` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_page_aligned_request` | `128` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_pager_disabled` | `16` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_reserve_only` | `8` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_flag_uses_fs_api` | `32` | `u32` | flag | bitmask | `memory_backing_store` | fixed_contract |
| `memory_backing_store_probe_version` | `1` | `u32` | version | number | `memory_backing_store_probe` | fixed_contract |
| `memory_backing_store_slot_blocker_backing_not_ready` | `8` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_invalid_owner` | `1024` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_invalid_request` | `1` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_owner_mismatch` | `512` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_reservation_not_found` | `128` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_table_full` | `64` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_unaligned_backing` | `256` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_unsupported_flags` | `2` | `u32` | flag | bitmask | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_unsupported_operation` | `4` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_flag_backing_ready` | `2` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_eviction_disabled` | `64` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_file_backed` | `1` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_metadata_only` | `4` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_no_page_io` | `128` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_page_sized_slots` | `16` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_pager_disabled` | `32` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_range_table` | `8` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_flag_recovery_available` | `256` | `u32` | flag | bitmask | `memory_backing_store_slot` | fixed_contract |
| `memory_backing_store_slot_operation_mark_error` | `3` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_operation_probe` | `0` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_operation_recover` | `4` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_operation_release` | `2` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_operation_reserve` | `1` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_owner_kind_diagnostic` | `1` | `u32` | identity | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_owner_kind_pager` | `4` | `u32` | identity | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_owner_kind_r4x_instance` | `2` | `u32` | identity | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_owner_kind_vm_region` | `3` | `u32` | identity | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_probe_version` | `2` | `u32` | version | number | `memory_backing_store_slot_probe` | fixed_contract |
| `memory_backing_store_slot_status_backing_unavailable` | `7` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_invalid_request` | `6` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_owner_mismatch` | `13` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_ready` | `1` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_recovered` | `5` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_released` | `3` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_reservation_not_found` | `10` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_reserved` | `2` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_table_full` | `9` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_unavailable` | `0` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_unsupported_flags` | `11` | `u32` | flag | bitmask | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_unsupported_operation` | `12` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_directory` | `4` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_invalid_request` | `2` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_missing_file` | `3` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_ready` | `1` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_too_small` | `5` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_unavailable` | `0` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_backing_store_status_unsupported_flags` | `7` | `u32` | flag | bitmask | `memory_backing` | fixed_contract |
| `memory_backing_store_status_unsupported_fs` | `6` | `u32` | value | number | `memory_backing` | fixed_contract |
| `memory_kind_app_heap` | `6` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_app_stack` | `7` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_boot` | `0` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_dma` | `8` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_framebuffer` | `10` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_free` | `12` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_kernel` | `1` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_kernel_heap` | `2` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_mmio` | `9` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_page_table` | `3` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_program_image` | `5` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_reserved` | `11` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_unknown` | `13` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_kind_virtual_range` | `4` | `u8` | identity | number | `memory_kind` | fixed_contract |
| `memory_owner_bootloader` | `6` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_device` | `5` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_driver` | `1` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_kernel` | `0` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_protocol` | `2` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_r4x_instance` | `3` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_system` | `7` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_owner_task` | `4` | `u8` | value | number | `memory_owner` | fixed_contract |
| `memory_page_io_blocker_backing_not_ready` | `4` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_invalid_owner` | `65536` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_invalid_request` | `1` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_io_failed` | `1024` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_owner_mismatch` | `8192` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_partial_io` | `2048` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_region_offset_outside_commit` | `64` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_reservation_not_found` | `128` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_slot_already_valid` | `32768` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_slot_error` | `4096` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_slot_index_out_of_range` | `256` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_slot_not_valid` | `512` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_stale_generation` | `16384` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_unaligned_region_offset` | `32` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_unsupported_flags` | `2` | `u32` | flag | bitmask | `memory_page` | fixed_contract |
| `memory_page_io_blocker_vm_region_missing` | `8` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_blocker_vm_region_not_r4x` | `16` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_flag_backing_ready` | `2` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_data_preserved` | `8388608` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_eviction_disabled` | `2048` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_eviction_request` | `524288` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_explicit_request` | `128` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_file_backed` | `1` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_generation_checked` | `131072` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_multi_page` | `262144` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_no_second_io_path` | `512` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_no_swap` | `4096` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_owner_matched` | `65536` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_page_in` | `32768` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_page_out` | `16384` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_page_sized_slots` | `8192` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_pager_disabled` | `1024` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_permanent_failure` | `4194304` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_retry_request` | `1048576` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_retryable_failure` | `2097152` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_slot_clean` | `64` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_slot_dirty` | `32` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_slot_reserved` | `8` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_slot_valid` | `16` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_uses_fs_api` | `256` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_flag_vm_region_attached` | `4` | `u32` | flag | bitmask | `memory_page_io` | fixed_contract |
| `memory_page_io_operation_page_in` | `2` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_operation_page_out` | `1` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_probe_version` | `3` | `u32` | version | number | `memory_page_io_probe` | fixed_contract |
| `memory_page_io_status_backing_unavailable` | `5` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_invalid_request` | `4` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_io_failed` | `9` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_owner_mismatch` | `13` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_partial_io` | `10` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_ready` | `1` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_reservation_not_found` | `7` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_slot_already_valid` | `15` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_slot_error` | `12` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_slot_not_valid` | `8` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_stale_generation` | `14` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_unavailable` | `0` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_page_io_status_unsupported_flags` | `11` | `u32` | flag | bitmask | `memory_page` | fixed_contract |
| `memory_page_io_status_vm_region_missing` | `6` | `u32` | value | number | `memory_page` | fixed_contract |
| `memory_pager_gate_blocker_backing_not_ready` | `4` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_invalid_request` | `1` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_no_nonresident_commit` | `32` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_rollback_failed` | `512` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_table_full` | `256` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_unaligned_request` | `64` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_unsupported_flags` | `2` | `u32` | flag | bitmask | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_vm_region_missing` | `8` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_blocker_vm_region_not_r4x` | `16` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_flag_backing_ready` | `2` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_commit_gate` | `16` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_eviction_disabled` | `512` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_fault_gate` | `32` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_file_backed` | `1` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_metadata_only` | `4` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_no_page_io` | `1024` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_no_second_io_path` | `4096` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_no_swap` | `2048` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_page_sized_slots` | `8192` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_pager_disabled` | `256` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_rollback_complete` | `128` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_slot_reservation_tested` | `64` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_flag_vm_region_attached` | `8` | `u32` | flag | bitmask | `memory_pager_gate` | fixed_contract |
| `memory_pager_gate_probe_version` | `1` | `u32` | version | number | `memory_pager_gate_probe` | fixed_contract |
| `memory_pager_gate_status_backing_unavailable` | `3` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_invalid_request` | `2` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_no_nonresident_commit` | `5` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_ready` | `1` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_rollback_failed` | `7` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_table_full` | `9` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_unavailable` | `0` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_unsupported_flags` | `8` | `u32` | flag | bitmask | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_vm_region_missing` | `4` | `u32` | value | number | `memory_pager` | fixed_contract |
| `memory_pressure_flag_commit_limited` | `4` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_demand_commit` | `8` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_fs_cache_reclaim` | `64` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_no_pagefile` | `1` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_no_reclaim` | `32` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_no_swap` | `2` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_profile_limits` | `16` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_flag_vm_page_reclaim` | `128` | `u32` | flag | bitmask | `memory_pressure` | fixed_contract |
| `memory_pressure_level_critical` | `4` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_level_normal` | `1` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_level_unknown` | `0` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_level_warning` | `3` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_level_watch` | `2` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_oom_alloc_returns_null` | `1` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_oom_fault_escalates` | `4` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_oom_no_overcommit` | `8` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_oom_vm_returns_error` | `2` | `u32` | value | number | `memory_pressure` | fixed_contract |
| `memory_pressure_snapshot_version` | `1` | `u32` | version | number | `memory_pressure_snapshot` | fixed_contract |
| `memory_profile_browser` | `7` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_build_tool` | `6` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_desktop` | `3` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_large_service` | `5` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_normal` | `2` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_service` | `4` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_tiny` | `1` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_unknown` | `0` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_profile_workstation` | `8` | `u8` | value | number | `memory_profile` | fixed_contract |
| `memory_reclaim_probe_version` | `1` | `u32` | version | number | `memory_reclaim_probe` | fixed_contract |
| `memory_reclaim_reason_diagnostic` | `1` | `u32` | value | number | `memory_reclaim` | fixed_contract |
| `memory_reclaim_reason_loader_commit` | `4` | `u32` | value | number | `memory_reclaim` | fixed_contract |
| `memory_reclaim_reason_vm_commit` | `2` | `u32` | value | number | `memory_reclaim` | fixed_contract |
| `memory_reclaim_reason_vm_fault` | `3` | `u32` | value | number | `memory_reclaim` | fixed_contract |
| `memory_status_committed` | `2` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_status_error` | `6` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_status_free` | `0` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_status_guard` | `3` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_status_mapped` | `4` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_status_released` | `5` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_status_reserved` | `1` | `u8` | value | number | `memory_status` | fixed_contract |
| `memory_vm_page_state_blocker_invalid_request` | `1` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_not_initialized` | `128` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_outside_commit` | `32` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_region_missing` | `4` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_region_not_r4x` | `8` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_table_full` | `64` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_unaligned_request` | `16` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_unsupported_flags` | `2` | `u32` | flag | bitmask | `memory_vm` | fixed_contract |
| `memory_vm_page_state_blocker_unsupported_operation` | `256` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_flag_busy` | `16` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_committed` | `1` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_dirty` | `4` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_error` | `32` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_eviction_enabled` | `16777216` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_explicit_request` | `262144` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_fault_page_in` | `8388608` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_hardware_dirty_synced` | `65536` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_no_eviction` | `524288` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_no_fault_io` | `2097152` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_no_swap` | `1048576` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_page_sized` | `4194304` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_pinned` | `8` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_resident` | `2` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_slot_bound` | `64` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_flag_vm_owned_state` | `131072` | `u32` | flag | bitmask | `memory_vm_page_state` | fixed_contract |
| `memory_vm_page_state_operation_bind_slot` | `3` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_clear_busy` | `8` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_clear_error` | `10` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_clear_pinned` | `6` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_clear_slot` | `4` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_mark_busy` | `7` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_mark_clean` | `2` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_mark_dirty` | `1` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_mark_error` | `9` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_mark_pinned` | `5` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_operation_query` | `0` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_probe_version` | `1` | `u32` | version | number | `memory_vm_page_state_probe` | fixed_contract |
| `memory_vm_page_state_status_invalid_request` | `2` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_not_initialized` | `8` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_outside_commit` | `6` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_ready` | `1` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_region_missing` | `3` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_region_not_r4x` | `4` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_table_full` | `7` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_unaligned_request` | `5` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_unavailable` | `0` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_unsupported_flags` | `10` | `u32` | flag | bitmask | `memory_vm` | fixed_contract |
| `memory_vm_page_state_status_unsupported_operation` | `9` | `u32` | identity | number | `memory_vm` | fixed_contract |
| `memory_window_app_heap` | `3` | `u8` | value | number | `memory_window` | fixed_contract |
| `memory_window_app_stack` | `4` | `u8` | value | number | `memory_window` | fixed_contract |
| `memory_window_kernel_heap` | `1` | `u8` | value | number | `memory_window` | fixed_contract |
| `memory_window_mmio` | `5` | `u8` | value | number | `memory_window` | fixed_contract |
| `memory_window_program_image` | `2` | `u8` | value | number | `memory_window` | fixed_contract |
| `memory_window_r4x_vm` | `6` | `u8` | value | number | `memory_window` | fixed_contract |
| `memory_window_temp_kernel` | `0` | `u8` | value | number | `memory_window` | fixed_contract |
| `mmio_map_write_combining` | `1` | `u32` | value | number | `mmio_map` | fixed_contract |
| `nanoseconds_per_second` | `1000000000` | `u64` | value | nanoseconds | `text_path_time` | fixed_contract |
| `net_backend_cap_async_tx_completion` | `1024` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_interrupt_moderation` | `128` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_multiqueue` | `512` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_rx_l4_checksum_valid` | `1` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_rx_scatter` | `4` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_rx_vlan_strip` | `16` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_tx_l4_checksum_partial` | `2` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_tx_notification_suppression` | `256` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_tx_scatter` | `8` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_tx_segmentation` | `64` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_cap_tx_vlan_insert` | `32` | `u64` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_flag_broadcast` | `2` | `u32` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_flag_link_up` | `1` | `u32` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_flag_trusted` | `4` | `u32` | flag | bitmask | `net_backend` | fixed_contract |
| `net_backend_negotiation_version` | `1` | `u32` | version | number | `net_backend` | fixed_contract |
| `net_backend_version` | `2` | `u32` | version | number | `net_backend` | fixed_contract |
| `net_buffer_ownership_borrowed_until_return` | `0` | `u32` | value | enumeration | `net_buffer_ownership` | fixed_contract |
| `net_buffer_ownership_transferred_until_completion` | `1` | `u32` | value | enumeration | `net_buffer_ownership` | fixed_contract |
| `net_bus_pci` | `1` | `u8` | value | number | `net_bus` | fixed_contract |
| `net_bus_pcie` | `2` | `u8` | value | number | `net_bus` | fixed_contract |
| `net_bus_serial` | `3` | `u8` | value | number | `net_bus` | fixed_contract |
| `net_bus_unknown` | `0` | `u8` | value | number | `net_bus` | fixed_contract |
| `net_config_flag_adapter_present` | `4` | `u32` | flag | bitmask | `net_config` | fixed_contract |
| `net_config_flag_apply_live` | `512` | `u32` | flag | bitmask | `net_config` | fixed_contract |
| `net_config_flag_configured` | `1` | `u32` | flag | bitmask | `net_config` | fixed_contract |
| `net_config_flag_dns_configured` | `2` | `u32` | flag | bitmask | `net_config` | fixed_contract |
| `net_config_flag_link_up` | `8` | `u32` | flag | bitmask | `net_config` | fixed_contract |
| `net_config_flag_write_persistent` | `256` | `u32` | flag | bitmask | `net_config` | fixed_contract |
| `net_config_no_adapter` | `1` | `i32` | value | number | `net_config` | fixed_contract |
| `net_detail_fallback_decision_keep_recovery` | `1` | `u8` | value | number | `net_detail` | fixed_contract |
| `net_detail_fallback_decision_none` | `0` | `u8` | value | number | `net_detail` | fixed_contract |
| `net_detail_fallback_policy_none` | `0` | `u8` | value | number | `net_detail` | fixed_contract |
| `net_detail_fallback_policy_recovery_only` | `1` | `u8` | value | number | `net_detail` | fixed_contract |
| `net_detail_flag_adapter_present` | `1` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_arp_cache_valid` | `8` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_backend_status` | `64` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_dhcp_bound` | `16` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_dhcp_dns_configured` | `32` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_dns_configured` | `4` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_irq_registered` | `128` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_flag_link_up` | `2` | `u32` | flag | bitmask | `net_detail` | fixed_contract |
| `net_detail_protocol_arp` | `1` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_dhcp` | `5` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_dns` | `6` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_ethernet` | `0` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_icmp` | `3` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_ipv4` | `2` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_serial_link` | `8` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_tcp` | `7` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_protocol_udp` | `4` | `usize` | value | number | `net_detail` | fixed_contract |
| `net_detail_r4p_state_active` | `2` | `u8` | identity | number | `net_detail` | fixed_contract |
| `net_detail_r4p_state_blocked` | `3` | `u8` | identity | number | `net_detail` | fixed_contract |
| `net_detail_r4p_state_disabled` | `5` | `u8` | identity | number | `net_detail` | fixed_contract |
| `net_detail_r4p_state_error` | `4` | `u8` | identity | number | `net_detail` | fixed_contract |
| `net_detail_r4p_state_loaded` | `1` | `u8` | identity | number | `net_detail` | fixed_contract |
| `net_detail_r4p_state_missing` | `0` | `u8` | identity | number | `net_detail` | fixed_contract |
| `net_diag_op_backpressure` | `2` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_cleanup` | `3` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_corpus` | `10` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_driver` | `7` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_environment` | `8` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_errors` | `13` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_lifecycle` | `5` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_negative` | `11` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_power` | `4` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_r4p` | `12` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_reset` | `6` | `u32` | identity | number | `net_diag` | fixed_contract |
| `net_diag_op_timing` | `1` | `u32` | identity | count | `net_diag` | fixed_contract |
| `net_packet_completion_cancelled` | `-2` | `i32` | value | number | `net_packet_completion` | fixed_contract |
| `net_packet_completion_error` | `-1` | `i32` | value | number | `net_packet_completion` | fixed_contract |
| `net_packet_completion_ok` | `0` | `i32` | value | number | `net_packet_completion` | fixed_contract |
| `net_packet_completion_shutdown` | `-4` | `i32` | value | number | `net_packet_completion` | fixed_contract |
| `net_packet_completion_timeout` | `-3` | `i32` | value | number | `net_packet_completion` | fixed_contract |
| `net_packet_flag_rx_l4_checksum_valid` | `1` | `u64` | flag | bitmask | `net_packet` | fixed_contract |
| `net_packet_flag_scatter` | `16` | `u64` | flag | bitmask | `net_packet` | fixed_contract |
| `net_packet_flag_segmentation` | `8` | `u64` | flag | bitmask | `net_packet` | fixed_contract |
| `net_packet_flag_tx_l4_checksum_partial` | `2` | `u64` | flag | bitmask | `net_packet` | fixed_contract |
| `net_packet_flag_vlan_tag_valid` | `4` | `u64` | flag | bitmask | `net_packet` | fixed_contract |
| `net_packet_max_segments` | `8` | `u16` | value | count | `net_packet` | fixed_contract |
| `net_packet_version` | `1` | `u32` | version | number | `net_packet` | fixed_contract |
| `net_rx_handoff_busy` | `-4` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_rx_handoff_invalid_adapter` | `-1` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_rx_handoff_invalid_frame` | `-2` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_rx_handoff_ok` | `0` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_rx_handoff_software_fallback` | `1` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_rx_handoff_unavailable` | `-3` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_rx_handoff_wrong_context` | `-5` | `i32` | value | number | `net_rx_handoff` | fixed_contract |
| `net_service_dhcp_action_acquire` | `1` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_dhcp_action_release` | `3` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_dhcp_action_renew` | `2` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_dhcp_flag_bound` | `1` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_flag_desired` | `8` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_flag_dns_configured` | `4` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_flag_link_up` | `32` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_flag_pending` | `2` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_flag_retry_wait` | `64` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_flag_task_started` | `16` | `u32` | flag | bitmask | `net_service_dhcp` | fixed_contract |
| `net_service_dhcp_status_magic` | `1397770308` | `u32` | magic | number | `net_service_dhcp_status` | fixed_contract |
| `net_service_dhcp_status_version` | `1` | `u16` | version | number | `net_service_dhcp_status` | fixed_contract |
| `net_service_dns_action_resolve_a` | `1` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_dns_action_resolve_a_server` | `2` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_dns_flag_cache_hit` | `8` | `u32` | flag | bitmask | `net_service_dns` | fixed_contract |
| `net_service_dns_flag_cache_valid` | `4` | `u32` | flag | bitmask | `net_service_dns` | fixed_contract |
| `net_service_dns_flag_explicit_server` | `16` | `u32` | flag | bitmask | `net_service_dns` | fixed_contract |
| `net_service_dns_flag_pending` | `2` | `u32` | flag | bitmask | `net_service_dns` | fixed_contract |
| `net_service_dns_status_magic` | `1397966916` | `u32` | magic | number | `net_service_dns_status` | fixed_contract |
| `net_service_dns_status_version` | `1` | `u16` | version | number | `net_service_dns_status` | fixed_contract |
| `net_service_magic` | `1129335118` | `u32` | magic | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_acquire` | `513` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_acquire_result` | `529` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_release` | `515` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_release_result` | `531` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_renew` | `514` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_renew_result` | `530` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dhcp_status_result` | `528` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dns_resolve_a` | `257` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dns_resolve_a_result` | `273` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dns_resolve_a_server` | `258` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dns_resolve_a_server_result` | `274` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_dns_status_result` | `272` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_hosttest` | `1285` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_hosttest_result` | `1301` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_poll` | `1281` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_poll_result` | `1297` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_read_message` | `1283` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_read_message_result` | `1299` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_reset` | `1286` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_reset_result` | `1302` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_selftest` | `1284` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_selftest_result` | `1300` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_send_message` | `1282` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_send_message_result` | `1298` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_r4sl_status_result` | `1296` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_service_restart` | `241` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_status` | `1` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_abort_result` | `794` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_accept` | `778` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_accept_poll_result` | `795` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_accept_read` | `774` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_accept_read_result` | `790` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_accept_result` | `793` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_close` | `772` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_close_listen` | `775` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_close_listen_result` | `791` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_close_result` | `788` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_connect` | `769` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_connect_result` | `785` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_connections` | `776` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_listen` | `773` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_listen_result` | `789` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_poll` | `777` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_poll_result` | `792` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_read` | `771` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_read_result` | `787` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_retransmit_result` | `796` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_status_result` | `784` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_write` | `770` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_tcp_write_result` | `786` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_bind` | `1025` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_bind_result` | `1041` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_close` | `1028` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_close_result` | `1044` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_recv` | `1027` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_recv_result` | `1043` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_sendto` | `1026` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_sendto_result` | `1042` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_op_udp_status_result` | `1040` | `u16` | identity | number | `net_service` | fixed_contract |
| `net_service_r4sl_action_hosttest` | `5` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_r4sl_action_poll` | `1` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_r4sl_action_read_message` | `3` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_r4sl_action_reset` | `6` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_r4sl_action_selftest` | `4` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_r4sl_action_send_message` | `2` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_r4sl_flag_inbox_data` | `4` | `u32` | flag | bitmask | `net_service_r4sl` | fixed_contract |
| `net_service_r4sl_flag_initialized` | `2` | `u32` | flag | bitmask | `net_service_r4sl` | fixed_contract |
| `net_service_r4sl_flag_kernel_message` | `16` | `u32` | flag | bitmask | `net_service_r4sl` | fixed_contract |
| `net_service_r4sl_flag_outbox_data` | `8` | `u32` | flag | bitmask | `net_service_r4sl` | fixed_contract |
| `net_service_r4sl_flag_present` | `1` | `u32` | flag | bitmask | `net_service_r4sl` | fixed_contract |
| `net_service_r4sl_flag_service_queue` | `32` | `u32` | flag | bitmask | `net_service_r4sl` | fixed_contract |
| `net_service_r4sl_status_magic` | `1397503058` | `u32` | magic | number | `net_service_r4sl_status` | fixed_contract |
| `net_service_r4sl_status_version` | `1` | `u16` | version | number | `net_service_r4sl_status` | fixed_contract |
| `net_service_socket_lifecycle_active` | `1` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_bad_handle` | `10` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_closed` | `2` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_dropped` | `13` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_listener` | `12` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_local_abort` | `6` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_local_close` | `7` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_owner_mismatch` | `11` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_peer_gone` | `5` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_pending_close` | `8` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_reset` | `3` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_unknown` | `0` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_would_block` | `9` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_status_cancelled` | `5` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_status_failed` | `4` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_status_idle` | `0` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_status_mask` | `4278190080` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_status_pending` | `1` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_status_shift` | `24` | `comptime_int` | value | number | `net_service` | fixed_contract |
| `net_service_status_would_block` | `6` | `u32` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_abort` | `10` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_accept` | `9` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_accept_poll` | `11` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_accept_read` | `6` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_close` | `4` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_close_listen` | `7` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_connect` | `1` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_listen` | `5` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_poll` | `8` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_read` | `3` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_retransmit` | `12` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_action_write` | `2` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_tcp_flag_conn_valid` | `16` | `u32` | flag | bitmask | `net_service_tcp` | fixed_contract |
| `net_service_tcp_flag_data` | `4` | `u32` | flag | bitmask | `net_service_tcp` | fixed_contract |
| `net_service_tcp_flag_handle_valid` | `8` | `u32` | flag | bitmask | `net_service_tcp` | fixed_contract |
| `net_service_tcp_flag_lifecycle_valid` | `128` | `u32` | flag | bitmask | `net_service_tcp` | fixed_contract |
| `net_service_tcp_flag_listener` | `64` | `u32` | flag | bitmask | `net_service_tcp` | fixed_contract |
| `net_service_tcp_flag_remote_valid` | `32` | `u32` | flag | bitmask | `net_service_tcp` | fixed_contract |
| `net_service_tcp_status_flag_last_segment` | `2` | `u32` | flag | bitmask | `net_service_tcp_status` | fixed_contract |
| `net_service_tcp_status_flag_lifecycle_valid` | `4` | `u32` | flag | bitmask | `net_service_tcp_status` | fixed_contract |
| `net_service_tcp_status_flag_listener_active` | `1` | `u32` | flag | bitmask | `net_service_tcp_status` | fixed_contract |
| `net_service_tcp_status_magic` | `1398031188` | `u32` | magic | number | `net_service_tcp_status` | fixed_contract |
| `net_service_tcp_status_version` | `2` | `u16` | version | number | `net_service_tcp_status` | fixed_contract |
| `net_service_udp_action_bind` | `1` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_udp_action_close` | `4` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_udp_action_recv` | `3` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_udp_action_sendto` | `2` | `u16` | value | number | `net_service` | fixed_contract |
| `net_service_udp_flag_data` | `2` | `u32` | flag | bitmask | `net_service_udp` | fixed_contract |
| `net_service_udp_flag_handle_valid` | `4` | `u32` | flag | bitmask | `net_service_udp` | fixed_contract |
| `net_service_udp_flag_lifecycle_valid` | `16` | `u32` | flag | bitmask | `net_service_udp` | fixed_contract |
| `net_service_udp_flag_remote_valid` | `8` | `u32` | flag | bitmask | `net_service_udp` | fixed_contract |
| `net_service_udp_status_flag_lifecycle_valid` | `16` | `u32` | flag | bitmask | `net_service_udp_status` | fixed_contract |
| `net_service_udp_status_magic` | `1397769301` | `u32` | magic | number | `net_service_udp_status` | fixed_contract |
| `net_service_udp_status_version` | `2` | `u16` | version | number | `net_service_udp_status` | fixed_contract |
| `net_service_version` | `1` | `u16` | version | number | `net_service` | fixed_contract |
| `net_tx_backend_error` | `6` | `i32` | value | number | `net_tx` | fixed_contract |
| `net_tx_busy` | `3` | `i32` | value | number | `net_tx` | fixed_contract |
| `net_tx_link_down` | `2` | `i32` | value | number | `net_tx` | fixed_contract |
| `net_tx_no_adapter` | `1` | `i32` | value | number | `net_tx` | fixed_contract |
| `net_tx_too_large` | `4` | `i32` | value | number | `net_tx` | fixed_contract |
| `net_tx_unsupported` | `5` | `i32` | value | number | `net_tx` | fixed_contract |
| `paging_flag_active_root_matches_hardware` | `2` | `u32` | flag | bitmask | `paging` | fixed_contract |
| `paging_flag_cr3_switch_done` | `8` | `u32` | flag | bitmask | `paging` | fixed_contract |
| `paging_flag_initialized` | `1` | `u32` | flag | bitmask | `paging` | fixed_contract |
| `paging_flag_limine_quarantine` | `16` | `u32` | flag | bitmask | `paging` | fixed_contract |
| `paging_flag_r4os_root_active` | `4` | `u32` | flag | bitmask | `paging` | fixed_contract |
| `paging_root_owner_bootloader` | `1` | `u8` | value | number | `paging_root` | fixed_contract |
| `paging_root_owner_r4os` | `2` | `u8` | value | number | `paging_root` | fixed_contract |
| `paging_root_owner_unknown` | `0` | `u8` | value | number | `paging_root` | fixed_contract |
| `path_component_max_chars` | `255` | `u16` | value | chars | `text_path_time` | fixed_contract |
| `pci_enable_io_space` | `1` | `u32` | value | number | `pci_enable` | fixed_contract |
| `pci_enable_memory_space` | `2` | `u32` | value | number | `pci_enable` | fixed_contract |
| `performance_flag_audio_latency_ready` | `268435456` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_avx_state_ready` | `16777216` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_boot_perf_ready` | `4` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_display_ready` | `2` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_display_responsiveness_ready` | `134217728` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_driver_workqueue_ready` | `33554432` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_fpu_state_ready` | `512` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_fs_page_cache_ready` | `1024` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_fs_pmm_reclaim_ready` | `8192` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_fs_reclaim_ready` | `4096` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_fs_request_ready` | `64` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_fs_writeback_ready` | `2048` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_global_reclaim_ready` | `16384` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_hot_path_index_ready` | `1073741824` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_loader_memory_ready` | `2147483648` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_loader_performance_ready` | `536870912` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_lock_diagnostics_ready` | `16` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_memory_backing_store_ready` | `32768` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_memory_backing_store_slots_ready` | `65536` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_memory_eviction_ready` | `1048576` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_memory_page_io_ready` | `262144` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_memory_pager_gates_ready` | `131072` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_memory_vm_page_state_ready` | `524288` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_preemption_readiness_ready` | `256` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_productive_preemption_ready` | `4194304` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_scheduler_latency_ready` | `8388608` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_scheduler_ready` | `1` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_service_queue_ready` | `128` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_storage_driver_completion_ready` | `67108864` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_storage_request_queue_ready` | `32` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_flag_wait_objects_ready` | `8` | `u32` | flag | bitmask | `performance` | fixed_contract |
| `performance_fpu_backend_fxsave` | `1` | `u32` | value | number | `performance_fpu` | fixed_contract |
| `performance_fpu_backend_none` | `0` | `u32` | value | number | `performance_fpu` | fixed_contract |
| `performance_fpu_backend_xsave` | `2` | `u32` | value | number | `performance_fpu` | fixed_contract |
| `performance_missing_blocked_object` | `1` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_display_latency_histogram` | `16` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_driver_completion_latency` | `32` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_fs_latency_histogram` | `4` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_preemption_latency_histogram` | `128` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_service_latency_histogram` | `64` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_tcp_latency_histogram` | `8` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_missing_wait_latency_histogram` | `2` | `u32` | value | number | `performance_missing` | fixed_contract |
| `performance_preemption_gate_driver_irq` | `8` | `u32` | value | number | `performance_preemption` | fixed_contract |
| `performance_preemption_gate_fpu_state` | `64` | `u32` | identity | number | `performance_preemption` | fixed_contract |
| `performance_preemption_gate_fs_storage` | `16` | `u32` | value | number | `performance_preemption` | fixed_contract |
| `performance_preemption_gate_kernel_critical` | `2` | `u32` | value | number | `performance_preemption` | fixed_contract |
| `performance_preemption_gate_memory_paging` | `4` | `u32` | value | number | `performance_preemption` | fixed_contract |
| `performance_preemption_gate_productive_disabled` | `1` | `u32` | value | number | `performance_preemption` | fixed_contract |
| `performance_preemption_gate_service_program` | `32` | `u32` | value | number | `performance_preemption` | fixed_contract |
| `performance_service_lock_family_endpoint_data` | `4` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_service_lock_family_endpoint_lifecycle` | `3` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_service_lock_family_endpoint_snapshot` | `6` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_service_lock_family_endpoint_wait` | `5` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_service_lock_family_registry_control` | `0` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_service_lock_family_registry_lookup` | `1` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_service_lock_family_registry_snapshot` | `2` | `u32` | value | number | `performance_service_lock` | fixed_contract |
| `performance_simd_abi_avx` | `2` | `u32` | value | number | `performance_simd` | fixed_contract |
| `performance_simd_abi_avx2` | `3` | `u32` | value | number | `performance_simd` | fixed_contract |
| `performance_simd_abi_none` | `0` | `u32` | value | number | `performance_simd` | fixed_contract |
| `performance_simd_abi_sse2` | `1` | `u32` | value | number | `performance_simd` | fixed_contract |
| `performance_snapshot_version` | `15` | `u32` | version | number | `performance_snapshot` | fixed_contract |
| `physical_key_flag_repeat` | `1` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_kind_down` | `1` | `u32` | value | enumeration | `physical_key` | fixed_contract |
| `physical_key_kind_reset` | `3` | `u32` | value | enumeration | `physical_key` | fixed_contract |
| `physical_key_kind_up` | `2` | `u32` | value | enumeration | `physical_key` | fixed_contract |
| `physical_key_magic` | `1263547474` | `u32` | magic | magic | `physical_key` | fixed_contract |
| `physical_key_modifier_left_alt` | `4` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_left_control` | `1` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_left_gui` | `64` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_left_shift` | `16` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_right_alt` | `8` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_right_control` | `2` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_right_gui` | `128` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_modifier_right_shift` | `32` | `u32` | flag | bitmask | `physical_key` | fixed_contract |
| `physical_key_poll_empty` | `0` | `i32` | value | result | `physical_key` | fixed_contract |
| `physical_key_poll_error_invalid` | `-1` | `i32` | value | result | `physical_key` | fixed_contract |
| `physical_key_poll_error_unsupported` | `-2` | `i32` | value | result | `physical_key` | fixed_contract |
| `physical_key_poll_ready` | `1` | `i32` | value | result | `physical_key` | fixed_contract |
| `physical_key_usage_down` | `81` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_enter` | `40` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_keypad_2` | `90` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_keypad_4` | `92` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_keypad_6` | `94` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_keypad_7` | `95` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_keypad_8` | `96` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_keypad_9` | `97` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_left` | `80` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_left_alt` | `226` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_left_control` | `224` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_right` | `79` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_right_alt` | `230` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_right_control` | `228` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_space` | `44` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_usage_up` | `82` | `u32` | identity | hid_usage | `physical_key` | fixed_contract |
| `physical_key_version` | `1` | `u16` | version | number | `physical_key` | fixed_contract |
| `program_completion_flag_display_used` | `4` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_completion_flag_output` | `2` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_completion_flag_owner` | `8` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_completion_flag_ready` | `1` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_exit_reason_close` | `1` | `u8` | value | enumeration | `program_completion` | fixed_contract |
| `program_exit_reason_failed` | `3` | `u8` | value | enumeration | `program_completion` | fixed_contract |
| `program_exit_reason_killed` | `2` | `u8` | value | enumeration | `program_completion` | fixed_contract |
| `program_exit_reason_natural` | `0` | `u8` | value | enumeration | `program_completion` | fixed_contract |
| `program_instance_storage_self_test_flag_heap_ready` | `1` | `u32` | flag | bitmask | `program_instance_storage_self_test` | fixed_contract |
| `program_instance_storage_self_test_flag_payload_balance` | `4` | `u32` | flag | bitmask | `program_instance_storage_self_test` | fixed_contract |
| `program_instance_storage_self_test_flag_rollback_path` | `8` | `u32` | flag | bitmask | `program_instance_storage_self_test` | fixed_contract |
| `program_instance_storage_self_test_flag_storage_baseline_restored` | `2` | `u32` | flag | bitmask | `program_instance_storage_self_test` | fixed_contract |
| `program_inventory_cursor_flag_initialized` | `1` | `u32` | value | bit | `program_inventory` | fixed_contract |
| `program_inventory_kind_program` | `1` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_kind_task` | `2` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_kind_thread` | `3` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_page_max` | `64` | `u16` | value | entries | `program_inventory` | fixed_contract |
| `program_inventory_status_complete` | `0` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_status_invalid` | `3` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_status_more` | `1` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_status_restart` | `2` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_summary_flag_stable` | `1` | `u32` | value | bit | `program_inventory` | fixed_contract |
| `program_inventory_version` | `1` | `u16` | identity | version | `program_inventory` | fixed_contract |
| `program_join_handle_size` | `32` | `u16` | value | bytes | `program_inventory` | fixed_contract |
| `program_registry_self_test_flag_allowed` | `1` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_armed` | `2` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_busy` | `32` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_denied` | `16` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_lifecycle_armed` | `64` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_lifecycle_consumed` | `128` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_lifecycle_recovered` | `1024` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_lifecycle_retried` | `512` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_one_shot` | `8` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_reaper_signalled` | `256` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_flag_reset` | `4` | `u32` | flag | bitmask | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_operation_arm_lifecycle_failure` | `3` | `u32` | value | operation | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_operation_arm_next_growth` | `1` | `u32` | value | operation | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_operation_force_next_id` | `5` | `u32` | value | operation | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_operation_reset` | `2` | `u32` | value | operation | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_operation_signal_reaper` | `4` | `u32` | value | operation | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_cancel_execution` | `8` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_completion_reserve` | `1` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_detach_task` | `9` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_exit_commit` | `7` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_image` | `3` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_image_stack_vm_release` | `12` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_none` | `0` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_output_detach` | `10` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_publish` | `6` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_slot_reclaim` | `13` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_stack` | `4` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_storage` | `2` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_storage_release` | `11` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_self_test_phase_task` | `5` | `u32` | value | enumeration | `program_registry_self_test` | fixed_contract |
| `program_registry_summary_flag_failure_armed` | `1` | `u32` | flag | bitmask | `program_registry_summary` | fixed_contract |
| `protocol_api_version` | `1` | `u32` | version | number | `protocol_api` | fixed_contract |
| `protocol_buffer_flag_rx_l4_checksum_valid` | `1` | `u32` | flag | bitmask | `protocol_buffer` | fixed_contract |
| `protocol_magic` | `826888272` | `u32` | magic | number | `protocol` | fixed_contract |
| `r4d_version` | `1` | `u32` | version | number | `r4d` | fixed_contract |
| `r4l_abi_magic` | `827077714` | `u32` | magic | number | `r4l_abi` | fixed_contract |
| `r4l_abi_version` | `1` | `u32` | version | number | `r4l_abi` | fixed_contract |
| `r4l_handle_test_value` | `2763063329` | `u64` | value | number | `r4l_handle` | fixed_contract |
| `r4p_version` | `1` | `u16` | version | number | `r4p` | fixed_contract |
| `r4sl_op_build_frame` | `1` | `u32` | identity | number | `r4sl_op` | fixed_contract |
| `r4sl_op_reset_parser` | `3` | `u32` | identity | number | `r4sl_op` | fixed_contract |
| `r4sl_op_summary` | `5` | `u32` | identity | number | `r4sl_op` | fixed_contract |
| `r4x_version` | `2` | `u16` | version | number | `r4x` | fixed_contract |
| `r4xstart_abi_major` | `1` | `u16` | value | number | `r4xstart_abi` | fixed_contract |
| `r4xstart_abi_minor` | `1` | `u16` | value | count | `r4xstart_abi` | fixed_contract |
| `r4xstart_flag_close_supported` | `4` | `u32` | flag | bitmask | `r4xstart` | fixed_contract |
| `r4xstart_flag_imports_valid` | `1` | `u32` | flag | bitmask | `r4xstart` | fixed_contract |
| `r4xstart_flag_yield_supported` | `8` | `u32` | flag | bitmask | `r4xstart` | fixed_contract |
| `r4xstart_import_flag_group_interface` | `1` | `u32` | flag | bitmask | `r4xstart_import` | fixed_contract |
| `r4xstart_magic` | `1398289490` | `u32` | magic | number | `r4xstart` | fixed_contract |
| `r4xstart_r4audio_magic` | `827670866` | `u32` | magic | number | `r4xstart_r4audio` | fixed_contract |
| `r4xstart_r4audio_version` | `1` | `u32` | version | number | `r4xstart_r4audio` | fixed_contract |
| `r4xstart_r4desk_magic` | `826623058` | `u32` | magic | number | `r4xstart_r4desk` | fixed_contract |
| `r4xstart_r4desk_version` | `7` | `u32` | version | number | `r4xstart_r4desk` | fixed_contract |
| `r4xstart_r4dev_magic` | `827737170` | `u32` | magic | number | `r4xstart_r4dev` | fixed_contract |
| `r4xstart_r4dev_version` | `8` | `u32` | version | number | `r4xstart_r4dev` | fixed_contract |
| `r4xstart_r4draw_magic` | `827802706` | `u32` | magic | number | `r4xstart_r4draw` | fixed_contract |
| `r4xstart_r4draw_version` | `2` | `u32` | version | number | `r4xstart_r4draw` | fixed_contract |
| `r4xstart_r4net_magic` | `826625618` | `u32` | magic | number | `r4xstart_r4net` | fixed_contract |
| `r4xstart_r4net_version` | `1` | `u32` | version | number | `r4xstart_r4net` | fixed_contract |
| `boot_ready_result_completed` | `0` | `i32` | value | status_code | `boot_ready` | fixed_contract |
| `boot_ready_result_already_completed` | `1` | `i32` | value | status_code | `boot_ready` | fixed_contract |
| `boot_ready_error_not_boot_shell` | `-1` | `i32` | value | status_code | `boot_ready` | fixed_contract |
| `boot_ready_error_boot_failed` | `-2` | `i32` | value | status_code | `boot_ready` | fixed_contract |
| `boot_performance_version` | `1` | `u32` | version | number | `performance_boot_summary` | fixed_contract |
| `boot_performance_size` | `144` | `u32` | value | bytes | `performance_boot_summary` | fixed_contract |
| `boot_performance_state_uninitialized` | `0` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_performance_state_running` | `1` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_performance_state_ready` | `2` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_performance_state_fallback_ready` | `3` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_performance_state_failed` | `4` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_none` | `0` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_configured_shell_ready` | `1` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_terminal_fallback_ready` | `2` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_recovery_fallback_ready` | `3` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_no_shell` | `4` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_fatal_error` | `5` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_completion_reason_shell_exited_before_ready` | `6` | `u32` | value | number | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_initialized` | `1` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_completed` | `2` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_ready` | `4` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_fallback` | `8` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_failed` | `16` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_timing_valid` | `32` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `boot_performance_flag_frozen` | `64` | `u32` | flag | bitmask | `performance_boot_summary` | fixed_contract |
| `performance_irq_coverage_dispatch` | `1` | `u32` | flag | bitmask | `performance_irq_timing` | fixed_contract |
| `performance_irq_coverage_external_handler` | `2` | `u32` | flag | bitmask | `performance_irq_timing` | fixed_contract |
| `performance_irq_coverage_delivery_unavailable` | `4` | `u32` | flag | bitmask | `performance_irq_timing` | fixed_contract |
| `performance_irq_coverage_irq_safe_clock` | `8` | `u32` | flag | bitmask | `performance_irq_timing` | fixed_contract |
| `performance_irq_coverage_mixed_generation` | `16` | `u32` | flag | bitmask | `performance_irq_timing` | fixed_contract |
| `monotonic_clock_frequency_hz` | `1000000000` | `u64` | value | hertz | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_valid` | `1` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_continuous` | `2` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_high_resolution` | `4` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_irq_independent` | `8` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_invariant` | `16` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_early_origin` | `32` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_calibrated` | `64` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_flag_degraded` | `128` | `u32` | flag | bitmask | `monotonic_clock` | fixed_contract |
| `monotonic_clock_source_unavailable` | `0` | `u32` | value | number | `monotonic_clock` | fixed_contract |
| `monotonic_clock_source_tsc` | `1` | `u32` | value | number | `monotonic_clock` | fixed_contract |
| `monotonic_clock_source_hpet` | `2` | `u32` | value | number | `monotonic_clock` | fixed_contract |
| `monotonic_clock_source_periodic_event` | `3` | `u32` | value | number | `monotonic_clock` | fixed_contract |
| `r4xstart_r4sys_magic` | `827937618` | `u32` | magic | number | `r4xstart_r4sys` | fixed_contract |
| `r4xstart_r4sys_version` | `14` | `u32` | version | number | `r4xstart_r4sys` | fixed_contract |
| `registry_batch_blob_max` | `16384` | `u32` | value | bytes | `registry_batch` | fixed_contract |
| `registry_batch_failed_index_none` | `4294967295` | `u32` | value | index | `registry_batch` | fixed_contract |
| `registry_batch_operation_delete` | `2` | `u16` | value | enum_value | `registry_batch` | fixed_contract |
| `registry_batch_operation_max` | `32` | `u32` | value | operations | `registry_batch` | fixed_contract |
| `registry_batch_operation_set` | `1` | `u16` | value | enum_value | `registry_batch` | fixed_contract |
| `registry_batch_status_commit_failed` | `3` | `i32` | value | enum_value | `registry_batch` | fixed_contract |
| `registry_batch_status_committed` | `1` | `i32` | value | enum_value | `registry_batch` | fixed_contract |
| `registry_batch_status_invalid` | `0` | `i32` | value | enum_value | `registry_batch` | fixed_contract |
| `registry_batch_status_validation_failed` | `2` | `i32` | value | enum_value | `registry_batch` | fixed_contract |
| `registry_batch_version` | `1` | `u16` | identity | version | `registry_batch` | fixed_contract |
| `registry_path_max_bytes` | `255` | `u16` | value | bytes | `text_path_time` | fixed_contract |
| `registry_snapshot_cursor_flag_initialized` | `1` | `u32` | flag | bitmask | `registry_snapshot` | fixed_contract |
| `registry_snapshot_data_max` | `16384` | `u32` | value | bytes | `registry_snapshot` | fixed_contract |
| `registry_snapshot_entry_flag_data_omitted` | `2` | `u32` | flag | bitmask | `registry_snapshot` | fixed_contract |
| `registry_snapshot_entry_flag_data_present` | `1` | `u32` | flag | bitmask | `registry_snapshot` | fixed_contract |
| `registry_snapshot_kind_keys` | `1` | `u32` | value | enum_value | `registry_snapshot` | fixed_contract |
| `registry_snapshot_kind_values` | `2` | `u32` | value | enum_value | `registry_snapshot` | fixed_contract |
| `registry_snapshot_page_max` | `32` | `u32` | value | entries | `registry_snapshot` | fixed_contract |
| `registry_snapshot_status_complete` | `1` | `i32` | value | enum_value | `registry_snapshot` | fixed_contract |
| `registry_snapshot_status_invalid` | `0` | `i32` | value | enum_value | `registry_snapshot` | fixed_contract |
| `registry_snapshot_status_more` | `2` | `i32` | value | enum_value | `registry_snapshot` | fixed_contract |
| `registry_snapshot_status_restart` | `3` | `i32` | value | enum_value | `registry_snapshot` | fixed_contract |
| `registry_snapshot_version` | `1` | `u16` | identity | version | `registry_snapshot` | fixed_contract |
| `registry_value_type_binary` | `5` | `u16` | value | number | `registry_value` | fixed_contract |
| `registry_value_type_bool` | `4` | `u16` | value | number | `registry_value` | fixed_contract |
| `registry_value_type_multi_string` | `6` | `u16` | value | number | `registry_value` | fixed_contract |
| `registry_value_type_string` | `1` | `u16` | value | number | `registry_value` | fixed_contract |
| `registry_value_type_u32` | `2` | `u16` | value | number | `registry_value` | fixed_contract |
| `registry_value_type_u64` | `3` | `u16` | value | number | `registry_value` | fixed_contract |
| `remote_frame_cursor_flag_visible` | `1` | `u32` | flag | bitmask | `remote_frame_cursor` | fixed_contract |
| `remote_frame_flag_cursor_valid` | `4` | `u32` | flag | bitmask | `remote_frame` | fixed_contract |
| `remote_frame_flag_dirty_valid` | `2` | `u32` | flag | bitmask | `remote_frame` | fixed_contract |
| `remote_frame_flag_ready` | `1` | `u32` | flag | bitmask | `remote_frame` | fixed_contract |
| `remote_frame_format_xrgb32` | `1` | `u32` | value | number | `remote_frame` | fixed_contract |
| `remote_frame_magic` | `827475538` | `u32` | magic | number | `remote_frame` | fixed_contract |
| `remote_frame_version` | `1` | `u32` | version | number | `remote_frame` | fixed_contract |
| `remote_input_flag_absolute` | `4` | `u32` | flag | bitmask | `remote_input` | fixed_contract |
| `remote_input_flag_down` | `1` | `u32` | flag | bitmask | `remote_input` | fixed_contract |
| `remote_input_flag_up` | `2` | `u32` | flag | bitmask | `remote_input` | fixed_contract |
| `remote_input_kind_key_down` | `1` | `u32` | identity | number | `remote_input` | fixed_contract |
| `remote_input_kind_key_up` | `2` | `u32` | identity | number | `remote_input` | fixed_contract |
| `remote_input_kind_mouse_buttons` | `4` | `u32` | identity | number | `remote_input` | fixed_contract |
| `remote_input_kind_mouse_move` | `3` | `u32` | identity | number | `remote_input` | fixed_contract |
| `remote_input_kind_mouse_wheel` | `5` | `u32` | identity | number | `remote_input` | fixed_contract |
| `remote_input_magic` | `826888786` | `u32` | magic | number | `remote_input` | fixed_contract |
| `remote_input_modifier_alt` | `4` | `u32` | value | number | `remote_input` | fixed_contract |
| `remote_input_modifier_ctrl` | `2` | `u32` | value | number | `remote_input` | fixed_contract |
| `remote_input_modifier_shift` | `1` | `u32` | value | number | `remote_input` | fixed_contract |
| `remote_input_version` | `1` | `u32` | version | number | `remote_input` | fixed_contract |
| `service_api_flag_endpoint` | `1` | `u32` | flag | bitmask | `service_api` | fixed_contract |
| `service_api_flag_queue_backed` | `8` | `u32` | flag | bitmask | `service_api` | fixed_contract |
| `service_api_flag_request_pending` | `2` | `u32` | flag | bitmask | `service_api` | fixed_contract |
| `service_api_flag_response_pending` | `4` | `u32` | flag | bitmask | `service_api` | fixed_contract |
| `service_api_magic` | `1129730898` | `u32` | magic | number | `service_api` | fixed_contract |
| `service_api_version` | `1` | `u16` | version | number | `service_api` | fixed_contract |
| `service_start_auto` | `2` | `u32` | value | number | `service_start` | fixed_contract |
| `service_start_disabled` | `3` | `u32` | value | number | `service_start` | fixed_contract |
| `service_start_manual` | `1` | `u32` | value | number | `service_start` | fixed_contract |
| `service_state_disabled` | `6` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_state_empty` | `0` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_state_failed` | `5` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_state_running` | `3` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_state_starting` | `2` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_state_stopped` | `1` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_state_stopping` | `4` | `u32` | identity | number | `service_state` | fixed_contract |
| `service_stop_policy_graceful` | `0` | `u8` | value | enum_value | `service_stop` | fixed_contract |
| `service_stop_policy_kill_after_grace` | `1` | `u8` | value | enum_value | `service_stop` | fixed_contract |
| `storage_backend_bus_ahci` | `2` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_bus_ata` | `1` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_bus_nvme` | `3` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_bus_ram` | `5` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_bus_unknown` | `0` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_bus_usb` | `4` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_bus_virtio` | `6` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_flag_removable` | `1` | `u32` | flag | bitmask | `storage_backend` | fixed_contract |
| `storage_backend_flag_writable` | `2` | `u32` | flag | bitmask | `storage_backend` | fixed_contract |
| `storage_backend_source_builtin` | `0` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_source_disk` | `2` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_source_preload` | `1` | `u32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_status_busy` | `1` | `i32` | value | number | `storage_backend` | fixed_contract |
| `storage_backend_version` | `2` | `u32` | version | number | `storage_backend` | fixed_contract |
| `synth_engine_flag_midi` | `1` | `u32` | flag | bitmask | `synth_engine` | fixed_contract |
| `synth_engine_flag_opl3` | `2` | `u32` | flag | bitmask | `synth_engine` | fixed_contract |
| `synth_engine_flag_sid` | `4` | `u32` | flag | bitmask | `synth_engine` | fixed_contract |
| `synth_engine_version` | `1` | `u32` | version | number | `synth_engine` | fixed_contract |
| `tcp_flag_ack` | `16` | `u16` | flag | bitmask | `tcp` | fixed_contract |
| `tcp_flag_fin` | `1` | `u16` | flag | bitmask | `tcp` | fixed_contract |
| `tcp_flag_psh` | `8` | `u16` | flag | bitmask | `tcp` | fixed_contract |
| `tcp_flag_rst` | `4` | `u16` | flag | bitmask | `tcp` | fixed_contract |
| `tcp_flag_syn` | `2` | `u16` | flag | bitmask | `tcp` | fixed_contract |
| `tcp_op_build_segment` | `9` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_close` | `4` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_connect` | `1` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_connection_info` | `6` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_handle_rx` | `7` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_handle_tx` | `8` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_read` | `3` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_summary` | `5` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `tcp_op_write` | `2` | `u32` | identity | number | `tcp_op` | fixed_contract |
| `text_encoding_bytes` | `0` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `text_encoding_utf8` | `1` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `text_encoding_utf8_bom` | `2` | `u8` | identity | enum | `text_path_time` | fixed_contract |
| `thread_flag_joinable` | `2` | `u32` | flag | bitmask | `thread` | fixed_contract |
| `thread_flag_joined` | `4` | `u32` | flag | bitmask | `thread` | fixed_contract |
| `thread_flag_main` | `1` | `u32` | flag | bitmask | `thread` | fixed_contract |
| `thread_info_version` | `1` | `u32` | version | number | `thread_info` | fixed_contract |
| `thread_state_exited` | `3` | `u32` | identity | number | `thread_state` | fixed_contract |
| `thread_state_killed` | `4` | `u32` | identity | number | `thread_state` | fixed_contract |
| `thread_state_ready` | `1` | `u32` | identity | number | `thread_state` | fixed_contract |
| `thread_state_running` | `2` | `u32` | identity | number | `thread_state` | fixed_contract |
| `thread_state_unused` | `0` | `u32` | identity | number | `thread_state` | fixed_contract |
| `time_service_config_flag_clock_format` | `4` | `u32` | flag | bitmask | `time_service_config` | fixed_contract |
| `time_service_config_flag_date` | `8` | `u32` | flag | bitmask | `time_service_config` | fixed_contract |
| `time_service_config_flag_timezone_id` | `2` | `u32` | flag | bitmask | `time_service_config` | fixed_contract |
| `time_service_config_flag_timezone_index` | `1` | `u32` | flag | bitmask | `time_service_config` | fixed_contract |
| `time_service_config_magic` | `1129138516` | `u32` | magic | number | `time_service_config` | fixed_contract |
| `time_service_config_version` | `2` | `u16` | version | number | `time_service_config` | fixed_contract |
| `time_service_flag_clock_12h` | `16` | `u32` | flag | bitmask | `time_service` | fixed_contract |
| `time_service_flag_config_loaded` | `1` | `u32` | flag | bitmask | `time_service` | fixed_contract |
| `time_service_flag_config_valid` | `2` | `u32` | flag | bitmask | `time_service` | fixed_contract |
| `time_service_flag_default_utc` | `8` | `u32` | flag | bitmask | `time_service` | fixed_contract |
| `time_service_flag_dst_active` | `4` | `u32` | flag | bitmask | `time_service` | fixed_contract |
| `time_service_op_reload` | `3` | `u16` | identity | number | `time_service` | fixed_contract |
| `time_service_op_set_config` | `2` | `u16` | identity | number | `time_service` | fixed_contract |
| `time_service_op_status` | `1` | `u16` | identity | number | `time_service` | fixed_contract |
| `time_service_status_magic` | `1398033748` | `u32` | magic | number | `time_service_status` | fixed_contract |
| `time_service_status_version` | `2` | `u16` | version | number | `time_service_status` | fixed_contract |
| `timeout_kind_finite` | `1` | `u8` | value | enum_value | `timeout` | fixed_contract |
| `timeout_kind_forever` | `2` | `u8` | value | enum_value | `timeout` | fixed_contract |
| `timeout_kind_poll` | `0` | `u8` | value | enum_value | `timeout` | fixed_contract |
| `udp_op_build_datagram` | `3` | `u32` | identity | number | `udp_op` | fixed_contract |
| `udp_op_handle_rx` | `1` | `u32` | identity | number | `udp_op` | fixed_contract |
| `udp_op_handle_tx` | `2` | `u32` | identity | number | `udp_op` | fixed_contract |
| `usb_hid_boot_flag_report_id_heuristic` | `1` | `u32` | flag | bitmask | `usb_hid_boot` | fixed_contract |
| `usb_hid_boot_kind_keyboard` | `1` | `u8` | identity | number | `usb_hid` | fixed_contract |
| `usb_hid_boot_kind_mouse` | `2` | `u8` | identity | number | `usb_hid` | fixed_contract |
| `usb_hid_boot_kind_none` | `0` | `u8` | identity | number | `usb_hid` | fixed_contract |
| `usb_hid_boot_op_classify_interface` | `1` | `u32` | identity | number | `usb_hid` | fixed_contract |
| `usb_hid_boot_op_decode_keyboard` | `2` | `u32` | identity | number | `usb_hid` | fixed_contract |
| `usb_hid_boot_op_decode_mouse` | `3` | `u32` | identity | number | `usb_hid` | fixed_contract |
| `usb_hid_boot_op_self_test` | `4` | `u32` | identity | number | `usb_hid` | fixed_contract |
| `usb_host_backend_version` | `2` | `u32` | version | number | `usb_host_backend` | fixed_contract |
| `usb_host_direction_in` | `1` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_direction_none` | `0` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_direction_out` | `2` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_endpoint_bulk_in` | `2` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_endpoint_bulk_out` | `3` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_endpoint_control` | `0` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_endpoint_interrupt_in` | `1` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_flag_bulk` | `4` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_control` | `2` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_event_irq` | `16` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_hotplug` | `128` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_interrupt` | `8` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_multi_transfer` | `64` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_poll_fallback` | `32` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_flag_port_scan` | `1` | `u32` | flag | bitmask | `usb_host` | fixed_contract |
| `usb_host_source_builtin` | `0` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_source_disk` | `2` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_source_preload` | `1` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_state_active` | `1` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_state_failed` | `2` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_host_state_registered` | `0` | `u32` | value | number | `usb_host` | fixed_contract |
| `usb_msc_bot_dir_in` | `1` | `u8` | value | number | `usb_msc` | fixed_contract |
| `usb_msc_bot_dir_none` | `0` | `u8` | value | number | `usb_msc` | fixed_contract |
| `usb_msc_bot_dir_out` | `2` | `u8` | value | number | `usb_msc` | fixed_contract |
| `usb_msc_bot_op_build_cbw` | `1` | `u32` | identity | number | `usb_msc` | fixed_contract |
| `usb_msc_bot_op_parse_csw` | `2` | `u32` | identity | number | `usb_msc` | fixed_contract |
| `usb_msc_bot_op_self_test` | `3` | `u32` | identity | number | `usb_msc` | fixed_contract |
| `usb_scsi_dir_in` | `1` | `u8` | value | number | `usb_scsi` | fixed_contract |
| `usb_scsi_dir_none` | `0` | `u8` | value | number | `usb_scsi` | fixed_contract |
| `usb_scsi_dir_out` | `2` | `u8` | value | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_inquiry` | `1` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_mode_sense6` | `5` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_read10` | `6` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_read16` | `14` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_read_capacity10` | `4` | `u32` | identity | bytes | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_read_capacity16` | `13` | `u32` | identity | bytes | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_request_sense` | `3` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_sync_cache10` | `8` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_test_unit_ready` | `2` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_write10` | `7` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_build_write16` | `15` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_parse_capacity10` | `10` | `u32` | identity | bytes | `usb_scsi` | fixed_contract |
| `usb_scsi_op_parse_capacity16` | `16` | `u32` | identity | bytes | `usb_scsi` | fixed_contract |
| `usb_scsi_op_parse_mode_sense6` | `11` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_parse_sense` | `9` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `usb_scsi_op_self_test` | `12` | `u32` | identity | number | `usb_scsi` | fixed_contract |
| `vm_region_flag_executable` | `2` | `u64` | flag | bitmask | `vm_region` | fixed_contract |
| `vm_region_flag_writable` | `1` | `u64` | flag | bitmask | `vm_region` | fixed_contract |
| `vm_region_flags_default` | `1` | `u64` | flag | bitmask | `vm_region` | fixed_contract |
| `wait_state_cancelled` | `3` | `u8` | value | enum_value | `wait_state` | fixed_contract |
| `wait_state_completed` | `0` | `u8` | value | enum_value | `wait_state` | fixed_contract |
| `wait_state_failed` | `4` | `u8` | value | enum_value | `wait_state` | fixed_contract |
| `wait_state_timed_out` | `2` | `u8` | value | enum_value | `wait_state` | fixed_contract |
| `wait_state_would_block` | `1` | `u8` | value | enum_value | `wait_state` | fixed_contract |
| `window_service_flag_closing` | `16` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_focused` | `8` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_fullscreen` | `128` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_gui` | `64` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_maximized` | `4` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_minimized` | `2` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_service_ready` | `256` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_terminal` | `32` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_flag_visible` | `1` | `u32` | flag | bitmask | `window_service` | fixed_contract |
| `window_service_kind_gui` | `2` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_kind_manager` | `3` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_kind_terminal` | `1` | `u16` | identity | count | `window_service` | fixed_contract |
| `window_service_kind_unknown` | `0` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_close` | `1558` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_focus` | `1554` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_maximize` | `1557` | `u16` | identity | count | `window_service` | fixed_contract |
| `window_service_op_minimize` | `1555` | `u16` | identity | count | `window_service` | fixed_contract |
| `window_service_op_register` | `1552` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_remove` | `1559` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_restart_cleanup` | `1561` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_restore` | `1556` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_snapshot` | `1538` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_stale_sweep` | `1560` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_status` | `1537` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_text_status` | `1536` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_op_update` | `1553` | `u16` | identity | number | `window_service` | fixed_contract |
| `window_service_record_magic` | `1381453399` | `u32` | magic | number | `window_service_record` | fixed_contract |
| `window_service_record_version` | `1` | `u16` | version | number | `window_service_record` | fixed_contract |
| `window_service_snapshot_magic` | `1347898967` | `u32` | magic | number | `window_service_snapshot` | fixed_contract |
| `window_service_snapshot_version` | `1` | `u16` | version | number | `window_service_snapshot` | fixed_contract |
| `window_service_status_magic` | `1398230615` | `u32` | magic | number | `window_service_status` | fixed_contract |
| `window_service_status_version` | `1` | `u16` | version | number | `window_service_status` | fixed_contract |
| `tray_event_flag_overflow` | `1` | `u16` | flag | bitmask | `tray_event` | fixed_contract |
| `tray_event_kind_primary` | `1` | `u16` | identity | number | `tray_event` | fixed_contract |
| `tray_event_kind_double` | `2` | `u16` | identity | number | `tray_event` | fixed_contract |
| `tray_event_kind_context` | `3` | `u16` | identity | number | `tray_event` | fixed_contract |
| `tray_event_kind_wheel` | `4` | `u16` | identity | number | `tray_event` | fixed_contract |
| `tray_icon_format_argb32` | `1` | `u16` | identity | number | `tray_icon` | fixed_contract |
| `tray_item_flag_visible` | `1` | `u32` | flag | bitmask | `tray_item` | fixed_contract |
| `tray_item_flag_enabled` | `2` | `u32` | flag | bitmask | `tray_item` | fixed_contract |
| `tray_item_flag_attention` | `4` | `u32` | flag | bitmask | `tray_item` | fixed_contract |
| `tray_response_flag_exists` | `1` | `u32` | flag | bitmask | `tray_response` | fixed_contract |
| `tray_response_flag_layout_visible` | `2` | `u32` | flag | bitmask | `tray_response` | fixed_contract |
| `tray_response_flag_changed` | `4` | `u32` | flag | bitmask | `tray_response` | fixed_contract |
| `tray_response_flag_event` | `8` | `u32` | flag | bitmask | `tray_response` | fixed_contract |
| `tray_service_op_status` | `1792` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_service_op_upsert` | `1793` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_service_op_remove` | `1794` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_service_op_wait_event` | `1795` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_service_op_desktop_sync` | `1796` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_service_op_desktop_activate` | `1797` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_service_op_desktop_visibility` | `1798` | `u16` | identity | number | `tray_service` | fixed_contract |
| `tray_desktop_exchange_magic` | `1146369106` | `u32` | magic | number | `tray_desktop_exchange` | fixed_contract |
| `tray_desktop_exchange_version` | `1` | `u16` | version | number | `tray_desktop_exchange` | fixed_contract |
| `tray_desktop_flag_item` | `1` | `u32` | flag | bitmask | `tray_desktop_exchange` | fixed_contract |
| `tray_desktop_flag_complete` | `2` | `u32` | flag | bitmask | `tray_desktop_exchange` | fixed_contract |
| `tray_desktop_flag_restart` | `4` | `u32` | flag | bitmask | `tray_desktop_exchange` | fixed_contract |
| `tray_desktop_flag_layout_visible` | `8` | `u32` | flag | bitmask | `tray_desktop_exchange` | fixed_contract |
| `tray_desktop_cursor_poll` | `65535` | `u16` | identity | number | `tray_desktop_exchange` | fixed_contract |
| `tray_service_request_magic` | `1364472914` | `u32` | magic | number | `tray_service_request` | fixed_contract |
| `tray_service_request_version` | `1` | `u16` | version | number | `tray_service_request` | fixed_contract |
| `tray_service_response_magic` | `1347695698` | `u32` | magic | number | `tray_service_response` | fixed_contract |
| `tray_service_response_version` | `1` | `u16` | version | number | `tray_service_response` | fixed_contract |
| `tray_event_magic` | `1163146322` | `u32` | magic | number | `tray_event` | fixed_contract |
| `tray_event_version` | `1` | `u16` | version | number | `tray_event` | fixed_contract |
| `tray_result_ok` | `0` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_not_found` | `-1` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_full` | `-2` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_bad_request` | `-3` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_stale` | `-4` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_not_owner` | `-5` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_busy` | `-6` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `tray_result_timeout` | `-7` | `i32` | value | status_code | `tray_result` | fixed_contract |
| `gui_frame_command_kind_shared_raster` | `13` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_frame_generation_flag_shared_raster` | `16` | `u32` | flag | bitmask | `gui_frame` | fixed_contract |
| `gui_shared_raster_buffer_count` | `3` | `u32` | value | buffers | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_create_info_size` | `48` | `u32` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_create_info_version` | `1` | `u32` | version | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_format_alpha8` | `3` | `u32` | value | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_format_indexed8` | `2` | `u32` | value | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_format_xrgb32` | `1` | `u32` | value | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_handle_size` | `16` | `u32` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_lease_size` | `48` | `u32` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_lease_version` | `1` | `u32` | version | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_map_size` | `120` | `u32` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_map_version` | `1` | `u32` | version | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_max_bytes` | `1048576` | `u64` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_max_frame_resources` | `8` | `u32` | value | records | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_resource_size` | `80` | `u32` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_resource_version` | `1` | `u32` | version | number | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_write_map_size` | `56` | `u32` | value | bytes | `gui_shared_raster` | fixed_contract |
| `gui_shared_raster_write_map_version` | `1` | `u32` | version | number | `gui_shared_raster` | fixed_contract |
| `drive_role_data` | `2` | `u8` | identity | number | `drive_role` | fixed_contract |
| `drive_role_none` | `0` | `u8` | identity | number | `drive_role` | fixed_contract |
| `drive_role_ram` | `3` | `u8` | identity | number | `drive_role` | fixed_contract |
| `drive_role_system` | `1` | `u8` | identity | number | `drive_role` | fixed_contract |
| `storage_target_device` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_target_partition` | `2` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_inventory_partial` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_writable` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_table_valid` | `2` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_gpt` | `4` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_mbr` | `8` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_claimed` | `16` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_failed` | `32` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_unsupported` | `64` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_partial` | `128` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_device_ram` | `256` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_partition_claimed` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_partition_mounted` | `2` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_partition_failed` | `4` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_volume_required` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_volume_claimed` | `2` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_claim_end_keep_unmounted` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_filesystem_unknown` | `0` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_filesystem_fat32` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_filesystem_ntfs` | `2` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_filesystem_none` | `3` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_unknown` | `0` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_ata` | `1` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_sata` | `2` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_nvme` | `3` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_usb` | `4` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_ram` | `5` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_raw_max_sectors` | `256` | `u32` | identity | number | `storage` | fixed_contract |
| `storage_bus_virtio` | `6` | `u32` | identity | number | `storage` | fixed_contract |
| `vm_commit_flag_resident` | `1` | `u64` | flag | bitmask | `vm_commit` | fixed_contract |
| `vm_commit_resident_max_bytes` | `262144` | `u64` | value | bytes | `vm_commit` | fixed_contract |

## Limits

| Name | Wert | Typ | Einheit | Geltung | Klassifikation |
|---|---:|---|---|---|---|
| `audio_service_error_bytes` | `32` | `usize` | bytes | `audio_service` | fixed_contract |
| `audio_service_max_sessions` | `8` | `u32` | count | `audio_service` | fixed_contract |
| `audio_service_name_bytes` | `32` | `usize` | bytes | `audio_service` | fixed_contract |
| `boot_info_bootloader_name_bytes` | `32` | `u32` | bytes | `boot_info` | fixed_contract |
| `boot_log_buffer_size` | `65536` | `usize` | bytes | `boot_log` | fixed_contract |
| `clipboard_max_text_bytes` | `4095` | `u32` | bytes | `clipboard_max` | fixed_contract |
| `console_output_capacity` | `16384` | `u32` | bytes | `console_output` | fixed_contract |
| `driver_work_queue_capacity` | `16` | `u32` | bytes | `driver_work` | fixed_contract |
| `pci_inventory_capacity` | `64` | `u32` | count | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_enumerated` | `1` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_ecam` | `2` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_legacy` | `4` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_partial` | `8` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_truncated` | `16` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_ecam_aperture_ready` | `32` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `pci_inventory_flag_ecam_rejected_segment` | `64` | `u32` | bitmask | `pci_inventory` | fixed_contract |
| `environment_block_max` | `2048` | `usize` | count | `environment_block` | fixed_contract |
| `environment_name_max` | `32` | `usize` | count | `environment_name` | fixed_contract |
| `environment_value_max` | `512` | `usize` | count | `environment_value` | fixed_contract |
| `gui_font_name_bytes` | `40` | `u32` | bytes | `gui_font` | fixed_contract |
| `gui_font_path_bytes` | `96` | `u32` | bytes | `gui_font` | fixed_contract |
| `gui_font_status_bytes` | `48` | `u32` | bytes | `gui_font` | fixed_contract |
| `gui_argb32_max_height` | `4096` | `u32` | pixels | `gui_frame` | fixed_contract |
| `gui_argb32_max_pixels` | `4194304` | `u32` | pixels | `gui_frame` | fixed_contract |
| `gui_argb32_max_width` | `4096` | `u32` | pixels | `gui_frame` | fixed_contract |
| `gui_alpha8_max_height` | `512` | `u32` | count | `gui_alpha8` | fixed_contract |
| `gui_alpha8_max_pixels` | `262144` | `u32` | count | `gui_alpha8` | fixed_contract |
| `gui_alpha8_max_width` | `512` | `u32` | count | `gui_alpha8` | fixed_contract |
| `gui_raster_max_height` | `128` | `u32` | count | `gui_raster` | fixed_contract |
| `gui_raster_max_pixels` | `16384` | `u32` | count | `gui_raster` | fixed_contract |
| `gui_raster_max_width` | `128` | `u32` | count | `gui_raster` | fixed_contract |
| `hid_report_max_descriptor` | `512` | `usize` | count | `hid_report` | fixed_contract |
| `hid_report_max_field_usages` | `8` | `usize` | count | `hid_report` | fixed_contract |
| `hid_report_max_fields` | `24` | `usize` | count | `hid_report` | fixed_contract |
| `io_wait_forever` | `18446744073709551615` | `u64` | ticks | `io_wait` | fixed_contract |
| `ipc_max_message_size` | `4096` | `usize` | bytes | `ipc_max` | fixed_contract |
| `ipc_queue_depth` | `8` | `usize` | count | `ipc_queue` | fixed_contract |
| `log_service_error_bytes` | `32` | `usize` | bytes | `log_service` | fixed_contract |
| `log_service_export_text_bytes` | `3600` | `usize` | bytes | `log_service` | fixed_contract |
| `log_service_max_records` | `512` | `usize` | count | `log_service` | fixed_contract |
| `log_service_origin_bytes` | `32` | `usize` | bytes | `log_service` | fixed_contract |
| `log_service_search_bytes` | `64` | `usize` | bytes | `log_service` | fixed_contract |
| `log_service_source_count` | `8` | `usize` | count | `log_service` | fixed_contract |
| `log_service_source_description_bytes` | `80` | `usize` | bytes | `log_service` | fixed_contract |
| `log_service_source_name_bytes` | `32` | `usize` | bytes | `log_service` | fixed_contract |
| `log_service_text_bytes` | `160` | `usize` | bytes | `log_service` | fixed_contract |
| `memory_backing_store_slot_blocker_insufficient_capacity` | `32` | `u32` | bytes | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_blocker_zero_capacity` | `16` | `u32` | bytes | `memory_backing` | fixed_contract |
| `memory_backing_store_slot_status_insufficient_capacity` | `8` | `u32` | bytes | `memory_backing` | fixed_contract |
| `memory_kind_count` | `14` | `usize` | count | `memory_kind` | fixed_contract |
| `memory_owner_count` | `8` | `usize` | count | `memory_owner` | fixed_contract |
| `memory_pager_gate_blocker_insufficient_capacity` | `128` | `u32` | bytes | `memory_pager` | fixed_contract |
| `memory_pager_gate_status_insufficient_capacity` | `6` | `u32` | bytes | `memory_pager` | fixed_contract |
| `memory_status_count` | `7` | `usize` | count | `memory_status` | fixed_contract |
| `net_detail_max_tcp_connections` | `8` | `usize` | count | `net_detail` | fixed_contract |
| `net_detail_protocol_count` | `9` | `usize` | count | `net_detail` | fixed_contract |
| `net_diag_op_limit` | `9` | `u32` | number | `net_diag` | fixed_contract |
| `net_service_header_size` | `24` | `usize` | bytes | `net_service` | fixed_contract |
| `net_service_socket_lifecycle_timeout` | `4` | `u32` | ticks | `net_service` | fixed_contract |
| `net_service_status_timeout` | `3` | `u32` | ticks | `net_service` | fixed_contract |
| `net_service_tcp_flag_timeout` | `2` | `u32` | ticks | `net_service_tcp` | fixed_contract |
| `net_service_tcp_message_payload_max` | `4072` | `usize` | count | `net_service` | fixed_contract |
| `net_service_tcp_read_max` | `3916` | `usize` | count | `net_service` | fixed_contract |
| `net_service_tcp_write_max` | `4068` | `usize` | count | `net_service` | fixed_contract |
| `net_service_udp_read_max` | `3944` | `usize` | count | `net_service` | fixed_contract |
| `net_service_udp_send_max` | `4062` | `usize` | count | `net_service` | fixed_contract |
| `r4l_pointer_size` | `8` | `u32` | bytes | `r4l_pointer` | fixed_contract |
| `r4l_query_struct_size` | `32` | `u32` | bytes | `r4l_query` | fixed_contract |
| `r4sl_op_parse_bytes` | `2` | `u32` | bytes | `r4sl_op` | fixed_contract |
| `r4xstart_context_size` | `128` | `u32` | bytes | `r4xstart_context` | fixed_contract |
| `r4xstart_import_size` | `40` | `u32` | bytes | `r4xstart_import` | fixed_contract |
| `r4xstart_r4audio_size` | `184` | `u32` | bytes | `r4xstart_r4audio` | fixed_contract |
| `r4xstart_r4desk_size` | `432` | `u32` | bytes | `r4xstart_r4desk` | fixed_contract |
| `r4xstart_r4dev_size` | `344` | `u32` | bytes | `r4xstart_r4dev` | fixed_contract |
| `r4xstart_r4draw_size` | `272` | `u32` | bytes | `r4xstart_r4draw` | fixed_contract |
| `r4xstart_r4net_size` | `288` | `u32` | bytes | `r4xstart_r4net` | fixed_contract |
| `r4xstart_r4sys_size` | `1024` | `u32` | bytes | `r4xstart_r4sys` | fixed_contract |
| `registry_name_max` | `64` | `usize` | count | `registry_name` | fixed_contract |
| `serial_link_payload_max` | `256` | `usize` | count | `serial_link` | fixed_contract |
| `service_api_endpoint_queue_depth` | `8` | `usize` | count | `service_api` | fixed_contract |
| `service_api_header_size` | `28` | `usize` | bytes | `service_api` | fixed_contract |
| `service_api_max_payload` | `4096` | `usize` | count | `service_api` | fixed_contract |
| `service_args_bytes` | `96` | `usize` | bytes | `service_args` | fixed_contract |
| `service_description_bytes` | `80` | `usize` | bytes | `service_description` | fixed_contract |
| `service_error_bytes` | `64` | `usize` | bytes | `service` | fixed_contract |
| `service_name_bytes` | `32` | `usize` | bytes | `service_name` | fixed_contract |
| `service_path_bytes` | `128` | `usize` | bytes | `service_path` | fixed_contract |
| `thread_wait_forever` | `18446744073709551615` | `u64` | ticks | `thread_wait` | fixed_contract |
| `time_service_error_bytes` | `32` | `usize` | bytes | `time_service` | fixed_contract |
| `time_service_zone_id_bytes` | `32` | `usize` | bytes | `time_service` | fixed_contract |
| `time_service_zone_label_bytes` | `48` | `usize` | bytes | `time_service` | fixed_contract |
| `usb_hid_boot_max_keys` | `8` | `usize` | count | `usb_hid` | fixed_contract |
| `usb_hid_boot_max_report` | `32` | `usize` | count | `usb_hid` | fixed_contract |
| `usb_msc_bot_cbw_len` | `31` | `usize` | bytes | `usb_msc` | fixed_contract |
| `usb_msc_bot_csw_len` | `13` | `usize` | bytes | `usb_msc` | fixed_contract |
| `usb_msc_bot_max_cdb` | `16` | `usize` | count | `usb_msc` | fixed_contract |
| `usb_scsi_max_cdb` | `16` | `usize` | count | `usb_scsi` | fixed_contract |
| `usb_scsi_max_data` | `64` | `usize` | count | `usb_scsi` | fixed_contract |
| `window_service_error_bytes` | `32` | `usize` | bytes | `window_service` | fixed_contract |
| `window_service_max_windows` | `16` | `usize` | count | `window_service` | fixed_contract |
| `window_service_path_bytes` | `96` | `usize` | bytes | `window_service` | fixed_contract |
| `window_service_title_bytes` | `48` | `usize` | bytes | `window_service` | fixed_contract |
| `tray_event_queue_capacity` | `8` | `usize` | count | `tray_event` | fixed_contract |
| `tray_icon_height` | `16` | `usize` | pixels | `tray_icon` | fixed_contract |
| `tray_icon_pixel_count` | `256` | `usize` | count | `tray_icon` | fixed_contract |
| `tray_icon_width` | `16` | `usize` | pixels | `tray_icon` | fixed_contract |
| `tray_max_items` | `16` | `usize` | count | `tray_registry` | fixed_contract |
| `tray_max_owners` | `16` | `usize` | count | `tray_registry` | fixed_contract |
| `tray_tooltip_bytes` | `64` | `usize` | bytes | `tray_item` | fixed_contract |
