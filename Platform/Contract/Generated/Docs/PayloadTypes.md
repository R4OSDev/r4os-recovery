# Öffentliche API-Payloads

Diese Datei wird deterministisch aus `API/ApiContract.json` erzeugt. Manuelle Änderungen sind nicht zulässig.

Kernel-, Zig- und C-Program-ABI, R4L-Identitaeten, Contractlayouts, API-Referenzen und Conformance-Fixtures werden produktiv aus diesem Schema erzeugt; handgeschriebene Dateien bleiben nur Fassaden oder erklaerende Texte.

- Schema: v11, Baseline `standalone-contract-0.64.11`
- Reachability: 477 von 477 Typen aufgelöst oder explizit klassifiziert
- Zentrale SDK-only-Wurzeln: 0; Runtime-R4Ls besitzen libraryeigene Vertraege
- Operationen: 0; Fehlerdomänen: 72; Konstanten: 3151; Limits: 123

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
| `DeviceInventorySnapshotInfo` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
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
| `ProgramRegistrySummaryV2` | extensible | extern_struct | 224/8 | 224/8 | 224/8 | 224/8 |
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
| `AudioOutputInfo` | fixed_layout | extern_struct | 160/4 | 160/4 | 160/4 | 160/4 |
| `AudioOutputQueryFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `AudioOutputSelectFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `AudioOutputActiveFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `AudioOutputExtension` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `AudioServiceOutputRequest` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `AudioServiceOutputState` | fixed_layout | extern_struct | 1520/8 | 1520/8 | 1520/8 | 1520/8 |
| `DirectoryChangeCursor` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `FileCopyProgress` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `DisplayStateInfo` | extensible | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `GfxBufferHandle` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `GfxBufferDescriptor` | extensible | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `GfxBufferReference` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxBufferMap` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxBufferStats` | extensible | extern_struct | 136/8 | 136/8 | 136/8 | 136/8 |
| `GfxDeviceRequest` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxDeviceLease` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxDmaSegment` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxMmioRequest` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxMmioWindow` | extensible | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GfxOwnedBufferReservation` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `GfxOwnedBufferRelease` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxDriverMemoryApi` | extensible | extern_struct | 256/8 | 256/8 | 256/8 | 256/8 |
| `GfxFence` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxQueueConfig` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxQueueHandle` | extensible | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `GfxSubmission` | extensible | extern_struct | 512/8 | 512/8 | 512/8 | 512/8 |
| `GfxFenceStatus` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxBackendBinding` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxBackendRegistration` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxDriverJob` | extensible | extern_struct | 296/8 | 296/8 | 296/8 | 296/8 |
| `GfxDriverQueueApi` | extensible | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `GfxOutputId` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `GfxOutputMode` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxDisplayLimits` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `GfxOutputInfo` | extensible | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `GfxDisplayRevision` | extensible | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `GfxEdidBlock` | extensible | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `GfxScanoutState` | extensible | extern_struct | 152/8 | 152/8 | 152/8 | 152/8 |
| `GfxAtomicState` | extensible | extern_struct | 1240/8 | 1240/8 | 1240/8 | 1240/8 |
| `GfxAtomicResult` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxOutputPublication` | extensible | extern_struct | 8400/8 | 8400/8 | 8400/8 | 8400/8 |
| `GfxReceiverSource` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `GfxReceiverInfo` | fixed_layout | extern_struct | 8224/8 | 8224/8 | 8224/8 | 8224/8 |
| `GfxReceiverUpdate` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxDriverOutputApi` | extensible | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `GfxNativeBootInfo` | extensible | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GfxNativeRegistration` | extensible | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `GfxNativeState` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxBootHoldRequest` | extensible | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GfxDriverDisplayApi` | extensible | extern_struct | 152/8 | 152/8 | 152/8 | 152/8 |
| `DriverResourceInfo` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `DriverFirmwareTableInfo` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `DriverResourceApi` | extensible | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `DriverHeapAllocation` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `DriverHeapStats` | extensible | extern_struct | 104/8 | 104/8 | 104/8 | 104/8 |
| `DriverHeapApi` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `DriverThreadRequest` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `DriverThreadStatus` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `DriverThreadStats` | extensible | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `DriverThreadApi` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `DriverSemaphoreStatus` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `DriverSemaphoreStats` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `DriverSemaphoreApi` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxModeStatus` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `GfxDriverModeJob` | extensible | extern_struct | 336/8 | 336/8 | 336/8 | 336/8 |
| `GfxDriverModeCompletion` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `DisplayPresentationStats` | extensible | extern_struct | 208/8 | 208/8 | 208/8 | 208/8 |
| `DisplayCursorInfo` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `DisplayCursorRequest` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `DisplayCursorStatus` | extensible | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `GfxDriverCursorJob` | extensible | extern_struct | 160/8 | 160/8 | 160/8 | 160/8 |
| `GfxDriverCursorCompletion` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxAudioRoute` | extensible | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `GfxBackendProfile` | extensible | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `GfxBackendInfo` | extensible | extern_struct | 152/8 | 152/8 | 152/8 | 152/8 |
| `GfxNativeAllocation` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxNativeStatus` | extensible | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GfxNativeProvider` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxNativeJob` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `GfxRenderRect` | fixed_layout | extern_struct | 16/4 | 16/4 | 16/4 | 16/4 |
| `GfxRenderCommand` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxRenderList` | fixed_layout | extern_struct | 1296/8 | 1296/8 | 1296/8 | 1296/8 |
| `DisplayPresentationInfo` | extensible | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `GfxOutputTarget` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxAdditionalOutput` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `MouseMotion` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `DisplaySetting` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `DisplayLayout` | fixed_layout | extern_struct | 536/8 | 536/8 | 536/8 | 536/8 |
| `DisplayControlRequest` | fixed_layout | extern_struct | 600/8 | 600/8 | 600/8 | 600/8 |
| `DisplayControlStatus` | fixed_layout | extern_struct | 616/8 | 616/8 | 616/8 | 616/8 |
| `DisplayControlExchange` | fixed_layout | extern_struct | 1248/8 | 1248/8 | 1248/8 | 1248/8 |
| `GfxSampleGrid` | fixed_layout | extern_struct | 64/4 | 64/4 | 64/4 | 64/4 |
| `GfxRenderGridList` | fixed_layout | extern_struct | 2320/8 | 2320/8 | 2320/8 | 2320/8 |
| `GfxOutputColorState` | extensible | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `GfxRenderColorProgram` | fixed_layout | extern_struct | 272/8 | 272/8 | 272/8 | 272/8 |
| `GfxRenderColorList` | fixed_layout | extern_struct | 1568/8 | 1568/8 | 1568/8 | 1568/8 |
| `GfxHdrMetadata` | fixed_layout | extern_struct | 24/2 | 24/2 | 24/2 | 24/2 |
| `GfxColorSignal` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxModeColorRequest` | fixed_layout | extern_struct | 1344/8 | 1344/8 | 1344/8 | 1344/8 |
| `GfxDriverModeColor` | fixed_layout | extern_struct | 152/8 | 152/8 | 152/8 | 152/8 |
| `DisplayColorSelection` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `DisplayColorRequest` | fixed_layout | extern_struct | 712/8 | 712/8 | 712/8 | 712/8 |
| `DisplayColorExchange` | fixed_layout | extern_struct | 1360/8 | 1360/8 | 1360/8 | 1360/8 |
| `GfxRefreshCapabilities` | fixed_layout | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `GfxRefreshStatus` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxRefreshMeasure` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxOutputRefresh` | fixed_layout | extern_struct | 272/8 | 272/8 | 272/8 | 272/8 |
| `GfxRefreshRequest` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `GfxDeviceBudgetRequest` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxDeviceBudgetState` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxTelemetryMetric` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GfxTelemetryRequest` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxTelemetryDemand` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxTelemetryState` | extensible | extern_struct | 544/8 | 544/8 | 544/8 | 544/8 |
| `GfxOutputPower` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `GfxPowerRequest` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `RemoteFrameLease` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `RemoteFrameCaptureStats` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `GfxVirtualRequest` | extensible | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `GfxVirtualStatus` | extensible | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `GfxVirtualToken` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `GfxVirtualJob` | extensible | extern_struct | 248/8 | 248/8 | 248/8 | 248/8 |
| `GfxVirtualCompletion` | extensible | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `GfxBackendProperties` | extensible | extern_struct | 288/8 | 288/8 | 288/8 | 288/8 |
| `GfxNativeSubmission` | extensible | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GfxNativeResource` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GfxNativeJobInfo` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxNativeBinding` | extensible | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `GfxQueueOwnerInfo` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `WindowGraphicsSurface` | fixed_layout | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `WindowGraphicsFormat` | fixed_layout | extern_struct | 56/4 | 56/4 | 56/4 | 56/4 |
| `WindowGraphicsConfig` | fixed_layout | extern_struct | 680/8 | 680/8 | 680/8 | 680/8 |
| `WindowGraphicsPublication` | fixed_layout | extern_struct | 800/8 | 800/8 | 800/8 | 800/8 |
| `WindowGraphicsRequest` | fixed_layout | extern_struct | 208/8 | 208/8 | 208/8 | 208/8 |
| `WindowGraphicsFrame` | fixed_layout | extern_struct | 408/8 | 408/8 | 408/8 | 408/8 |
| `WindowGraphicsReply` | fixed_layout | extern_struct | 1248/8 | 1248/8 | 1248/8 | 1248/8 |
| `WindowGraphicsConsumer` | fixed_layout | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `WindowGraphicsWait` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GfxRenderColorGridList` | fixed_layout | extern_struct | 2592/8 | 2592/8 | 2592/8 | 2592/8 |
| `CpuCapacity` | fixed_layout | extern_struct | 8/4 | 8/4 | 8/4 | 8/4 |
| `WindowModeIdentity` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `WindowModeRequest` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `WindowModeReply` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `WindowModeExchange` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `DriverModuleInfo` | extensible | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `GfxOutputBrightness` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `GfxBrightnessRequest` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `PlatformInputSnapshot` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `DriverPlatformApi` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `HidConsumerOp` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `DirectoryScanCursor` | extensible | extern_struct | 1088/8 | 1088/8 | 1088/8 | 1088/8 |
| `ProgramInstrumentationInfo` | extensible | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `ProgramLockPerformanceInfo` | extensible | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `ProgramStackPerformanceInfo` | extensible | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `ProgramStackFaultInfo` | extensible | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `ProgramKernelHeapCheck` | fixed_layout | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `ProgramKernelSchedulerCheck` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `ProgramKernelSmpCheck` | fixed_layout | extern_struct | 224/8 | 224/8 | 224/8 | 224/8 |
| `ProgramSmpTlbSnapshot` | fixed_layout | extern_struct | 184/8 | 184/8 | 184/8 | 184/8 |
| `ProgramKernelBlockQueueCheck` | fixed_layout | extern_struct | 240/8 | 240/8 | 240/8 | 240/8 |
| `ProgramKernelNvmeCheck` | fixed_layout | extern_struct | 296/8 | 296/8 | 296/8 | 296/8 |
| `ProgramKernelUsbCheck` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `SerialConfig` | extensible | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `SerialPortInfo` | extensible | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `SerialTransfer` | extensible | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `SerialStatus` | extensible | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `SerialBackend` | extensible | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `DriverSerialApi` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `CpuTopologyInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `CpuCacheTopologyInfo` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `ThreadPlacementRequest` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `ThreadPlacementInfo` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `CpuLifecycleInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `ProgramKernelCpuLifecycleCheck` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `CpuCapabilitiesInfo` | fixed_layout | extern_struct | 272/8 | 272/8 | 272/8 | 272/8 |
| `CpuFeatureInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `CpuRegisterInfo` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `ProgramKernelCpuRegisterCheck` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `CpuPowerInfo` | fixed_layout | extern_struct | 320/8 | 320/8 | 320/8 | 320/8 |
| `CpuPowerBackend` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `DriverCpuPowerApi` | extensible | extern_struct | 184/8 | 184/8 | 184/8 | 184/8 |
| `CpuPowerCounters` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `CpuPerformanceRequest` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `CpuPerformanceInfo` | fixed_layout | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `CpuPerformanceBackend` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `CpuRegisterWriteInfo` | fixed_layout | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `CpuCppcInfo` | fixed_layout | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `CpuCppcBackend` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `CpuPerformanceHint` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `CpuPerformanceHintInfo` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `PowerProfileRequest` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `PowerProfileInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `PowerCpuProfileInfo` | fixed_layout | extern_struct | 160/8 | 160/8 | 160/8 | 160/8 |
| `CpuFirmwareBackend` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `CpuFirmwareInfo` | fixed_layout | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `CpuIdleDescriptor` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `CpuIdlePolicy` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `CpuIdleInfo` | fixed_layout | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `CpuMachineInfo` | fixed_layout | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `CpuMachineBank` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `CpuMicrocodeInfo` | fixed_layout | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `CpuPmuInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `CpuPmuResult` | fixed_layout | extern_struct | 256/8 | 256/8 | 256/8 | 256/8 |
| `PmuWorkFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `CpuAccelerationInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `CpuAccelerationWork` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `CpuPureWorkFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `EntropySourceInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `EntropyDeviceReceipt` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `EntropyBackend` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `DriverEntropyApi` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `EntropyReadFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `ConsoleInputEvent` | fixed_layout | extern_struct | 16/4 | 16/4 | 16/4 | 16/4 |
| `ConsoleTextInfo` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `FpuObservationRequest` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `FpuObservationInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `ProgramLifecycleSnapshot` | extensible | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `DirectoryBatchCursor` | extensible | extern_struct | 2160/8 | 2160/8 | 2160/8 | 2160/8 |
| `DirectoryBatchEntry` | fixed_layout | extern_struct | 1120/8 | 1120/8 | 1120/8 | 1120/8 |
| `AudioBackendWriteReceipt` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `AudioBackendPlayback` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `AudioBackendFlow` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `AudioStreamExpectation` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `AudioStreamProgress` | fixed_layout | extern_struct | 152/8 | 152/8 | 152/8 | 152/8 |
| `AudioServiceStreamProgressRequest` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `AudioServiceStreamProgressState` | fixed_layout | extern_struct | 200/8 | 200/8 | 200/8 | 200/8 |
| `AudioServiceStreamFlowRequest` | fixed_layout | extern_struct | 72/8 | 72/8 | 72/8 | 72/8 |
| `AudioServiceStreamTrackedWriteRequest` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `ProgramObservationHandle` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `FileNameLimits` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `GuiPointerWindowIdentity` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `GuiPointerCaptureHandle` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `GuiPointerCaptureInfo` | fixed_layout | extern_struct | 104/8 | 104/8 | 104/8 | 104/8 |
| `GuiPointerHostRequest` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `GuiHostInputRequest` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `AudioOutputEpoch` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `AudioOutputEpochFn` | callback | c_callback | 8/8 | 8/8 | 8/8 | 8/8 |
| `AudioOutputProviderEpoch` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `AudioOutputCatalog` | fixed_layout | extern_struct | 224/8 | 224/8 | 224/8 | 224/8 |
| `DesktopEvidenceToken` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `DesktopEvidenceRequest` | fixed_layout | extern_struct | 136/8 | 136/8 | 136/8 | 136/8 |
| `DesktopEvidenceReply` | fixed_layout | extern_struct | 288/8 | 288/8 | 288/8 | 288/8 |
| `DesktopActionToken` | fixed_layout | extern_struct | 144/8 | 144/8 | 144/8 | 144/8 |
| `DesktopActionState` | fixed_layout | extern_struct | 168/8 | 168/8 | 168/8 | 168/8 |
| `DesktopActionRequest` | fixed_layout | extern_struct | 192/8 | 192/8 | 192/8 | 192/8 |
| `DesktopActionReply` | fixed_layout | extern_struct | 544/8 | 544/8 | 544/8 | 544/8 |
| `DesktopWindowExchange` | fixed_layout | extern_struct | 640/8 | 640/8 | 640/8 | 640/8 |
| `DesktopWindowReply` | fixed_layout | extern_struct | 640/8 | 640/8 | 640/8 | 640/8 |
| `DesktopFocusSnapshot` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `DesktopFocusReply` | fixed_layout | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `DesktopWindowExchangeV2` | fixed_layout | extern_struct | 752/8 | 752/8 | 752/8 | 752/8 |
| `FirmwareSystemUuidInfo` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `DesktopLinkToken` | fixed_layout | extern_struct | 96/8 | 96/8 | 96/8 | 96/8 |
| `DesktopLinkRequest` | fixed_layout | extern_struct | 1296/8 | 1296/8 | 1296/8 | 1296/8 |
| `DesktopLinkReply` | fixed_layout | extern_struct | 1800/8 | 1800/8 | 1800/8 | 1800/8 |
| `ServiceInventoryCursor` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `ServiceInventoryRow` | fixed_layout | extern_struct | 1448/8 | 1448/8 | 1448/8 | 1448/8 |
| `ServiceControlRequest` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `GuiGradientPaint` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `GuiGradientStop` | fixed_layout | extern_struct | 8/4 | 8/4 | 8/4 | 8/4 |
| `GuiWindowAppearance` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `FileIdentity2` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `FileMetadata2` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `DirectoryMetadataEntry2` | fixed_layout | extern_struct | 1136/8 | 1136/8 | 1136/8 | 1136/8 |
| `DirectoryMetadataCursor2` | extensible | extern_struct | 2184/8 | 2184/8 | 2184/8 | 2184/8 |
| `FontAdvance2` | fixed_layout | extern_struct | 8/4 | 8/4 | 8/4 | 8/4 |
| `FontAdvanceInfo2` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `WaitSource` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `WaitSetDeadline` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `WaitSetEvent` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `WaitSetBatch` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `WaitSourceRequest` | fixed_layout | extern_struct | 64/8 | 64/8 | 64/8 | 64/8 |
| `ClipboardOfferInfo` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `ClipboardOfferBegin` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `ClipboardOfferLease` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `ClipboardOfferFormat` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `ClipboardOfferTransfer` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `ClipboardOfferEnumerate` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `ClipboardOfferPage` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `ClipboardOfferChunk` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `NetworkAddress` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `NetworkEndpoint` | fixed_layout | extern_struct | 40/4 | 40/4 | 40/4 | 40/4 |
| `NetworkDeadline` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `NetworkProviderInfo` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `NetworkSocketRequest` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `NetworkSocketResult` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `NetworkResolveRequest` | fixed_layout | extern_struct | 392/8 | 392/8 | 392/8 | 392/8 |
| `NetworkResolvePage` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `NetworkResolveAnswer` | fixed_layout | extern_struct | 40/4 | 40/4 | 40/4 | 40/4 |
| `NetworkLinkRequest` | fixed_layout | extern_struct | 1576/8 | 1576/8 | 1576/8 | 1576/8 |
| `NetworkLinkInfo` | fixed_layout | extern_struct | 128/8 | 128/8 | 128/8 | 128/8 |
| `Ipv6FrameOp` | fixed_layout | extern_struct | 1680/8 | 1680/8 | 1680/8 | 1680/8 |
| `Ipv6InterfaceQuery` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `Ipv6InterfaceInfo` | fixed_layout | extern_struct | 296/8 | 296/8 | 296/8 | 296/8 |
| `Ipv6AddressInfo` | fixed_layout | extern_struct | 80/8 | 80/8 | 80/8 | 80/8 |
| `Ipv6RouteInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `Ipv6AddressConfig` | fixed_layout | extern_struct | 88/8 | 88/8 | 88/8 | 88/8 |
| `Ipv6Packet` | fixed_layout | extern_struct | 1656/8 | 1656/8 | 1656/8 | 1656/8 |
| `Icmpv6Message` | fixed_layout | extern_struct | 1576/4 | 1576/4 | 1576/4 | 1576/4 |
| `NdpPrefix` | fixed_layout | extern_struct | 32/4 | 32/4 | 32/4 | 32/4 |
| `NdpRequest` | fixed_layout | extern_struct | 1608/8 | 1608/8 | 1608/8 | 1608/8 |
| `NdpEvent` | fixed_layout | extern_struct | 328/4 | 328/4 | 328/4 | 328/4 |
| `NdpInfo` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `NetworkTransportRequest` | fixed_layout | extern_struct | 176/8 | 176/8 | 176/8 | 176/8 |
| `BytePipeEnd` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `BytePipePair` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `BytePipeProgress` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `BytePipeInfo` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `LaunchIoBinding` | fixed_layout | extern_struct | 32/8 | 32/8 | 32/8 | 32/8 |
| `LaunchIo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `Utf8ByteRange` | fixed_layout | extern_struct | 16/8 | 16/8 | 16/8 | 16/8 |
| `CompositionCaret` | fixed_layout | extern_struct | 24/4 | 24/4 | 24/4 | 24/4 |
| `CompositionProvider` | fixed_layout | extern_struct | 40/8 | 40/8 | 40/8 | 40/8 |
| `CompositionFocus` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `CompositionId` | fixed_layout | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `CompositionEvent` | fixed_layout | extern_struct | 184/8 | 184/8 | 184/8 | 184/8 |
| `CompositionFocusReply` | fixed_layout | extern_struct | 120/8 | 120/8 | 120/8 | 120/8 |
| `CompositionCapabilityReply` | fixed_layout | extern_struct | 48/8 | 48/8 | 48/8 | 48/8 |
| `AudioCaptureSourceId` | fixed_layout | extern_struct | 24/8 | 24/8 | 24/8 | 24/8 |
| `AudioCaptureFormat` | fixed_layout | extern_struct | 12/4 | 12/4 | 12/4 | 12/4 |
| `AudioCaptureHandle` | fixed_layout | extern_struct | 56/8 | 56/8 | 56/8 | 56/8 |
| `AudioCaptureSourceInfo` | fixed_layout | extern_struct | 112/8 | 112/8 | 112/8 | 112/8 |
| `AudioCaptureRequest` | fixed_layout | extern_struct | 104/8 | 104/8 | 104/8 | 104/8 |
| `AudioCaptureReply` | fixed_layout | extern_struct | 248/8 | 248/8 | 248/8 | 248/8 |

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

### `DeviceInventorySnapshotInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `snapshot_generation` | 8 | 8 | 8 | `u64` | - |
| `count` | 16 | 4 | 4 | `u32` | - |
| `required_count` | 20 | 4 | 4 | `u32` | - |
| `capacity` | 24 | 4 | 4 | `u32` | - |
| `flags` | 28 | 4 | 4 | `u32` | - |
| `with_driver` | 32 | 4 | 4 | `u32` | - |
| `without_driver` | 36 | 4 | 4 | `u32` | - |
| `unknown` | 40 | 4 | 4 | `u32` | - |
| `source_mask` | 44 | 4 | 4 | `u32` | - |
| `record_size` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `reserved1` | 56 | 8 | 8 | `u64` | - |

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

### `AudioOutputInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `id` | 8 | 64 | 1 | `[64]u8` | - |
| `name` | 72 | 64 | 1 | `[64]u8` | - |
| `kind` | 136 | 4 | 4 | `u32` | - |
| `availability` | 140 | 4 | 4 | `u32` | - |
| `flags` | 144 | 4 | 4 | `u32` | - |
| `preferred_rate` | 148 | 4 | 4 | `u32` | - |
| `channels` | 152 | 2 | 2 | `u16` | - |
| `format` | 154 | 2 | 2 | `u16` | - |
| `reserved` | 156 | 4 | 4 | `u32` | - |

### `AudioOutputQueryFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `AudioOutputSelectFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `AudioOutputActiveFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `AudioOutputExtension`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `query` | 0 | 8 | 8 | `AudioOutputQueryFn` | - |
| `select` | 8 | 8 | 8 | `AudioOutputSelectFn` | - |
| `active` | 16 | 8 | 8 | `AudioOutputActiveFn` | - |

### `AudioServiceOutputRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `service_epoch` | 8 | 8 | 8 | `u64` | - |
| `revision` | 16 | 8 | 8 | `u64` | - |
| `index` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |
| `id` | 32 | 64 | 1 | `[64]u8` | - |

### `AudioServiceOutputState`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1520 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `service_epoch` | 8 | 8 | 8 | `u64` | - |
| `revision` | 16 | 8 | 8 | `u64` | - |
| `count` | 24 | 4 | 4 | `u32` | - |
| `total` | 28 | 4 | 4 | `u32` | - |
| `index` | 32 | 4 | 4 | `u32` | - |
| `reason` | 36 | 4 | 4 | `u32` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |
| `desired_id` | 48 | 64 | 1 | `[64]u8` | - |
| `active_id` | 112 | 64 | 1 | `[64]u8` | - |
| `active_name` | 176 | 64 | 1 | `[64]u8` | - |
| `outputs` | 240 | 1280 | 4 | `[8]AudioOutputInfo` | - |

### `DirectoryChangeCursor`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `sequence` | 8 | 8 | 8 | `u64` | - |
| `node` | 16 | 8 | 8 | `u64` | - |
| `mount_generation` | 24 | 8 | 8 | `u64` | - |
| `mount_slot` | 32 | 4 | 4 | `u32` | - |
| `reserved` | 36 | 4 | 4 | `u32` | - |

### `FileCopyProgress`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `bytes` | 8 | 8 | 8 | `u64` | - |
| `source_size` | 16 | 8 | 8 | `u64` | - |
| `chunks` | 24 | 4 | 4 | `u32` | - |
| `max_chunk` | 28 | 4 | 4 | `u32` | - |

### `DisplayStateInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `policy` | 12 | 4 | 4 | `u32` | - |
| `reason` | 16 | 4 | 4 | `u32` | - |
| `revision` | 24 | 8 | 8 | `u64` | - |
| `device_generation` | 32 | 8 | 8 | `u64` | - |
| `reset_generation` | 40 | 8 | 8 | `u64` | - |
| `pending_generation` | 48 | 8 | 8 | `u64` | - |
| `adapter_id` | 56 | 4 | 4 | `u32` | - |
| `pending_adapter_id` | 60 | 4 | 4 | `u32` | - |
| `driver_owner` | 64 | 4 | 4 | `u32` | - |
| `pending_driver_owner` | 68 | 4 | 4 | `u32` | - |
| `backend_kind` | 72 | 4 | 4 | `u32` | - |
| `capabilities` | 76 | 4 | 4 | `u32` | - |
| `width` | 80 | 4 | 4 | `u32` | - |
| `height` | 84 | 4 | 4 | `u32` | - |
| `pitch` | 88 | 4 | 4 | `u32` | - |
| `bpp` | 92 | 2 | 2 | `u16` | - |
| `cache_policy` | 94 | 1 | 1 | `u8` | - |
| `mapping_kind` | 95 | 1 | 1 | `u8` | - |
| `boot_width` | 96 | 4 | 4 | `u32` | - |
| `boot_height` | 100 | 4 | 4 | `u32` | - |
| `boot_pitch` | 104 | 4 | 4 | `u32` | - |
| `boot_bpp` | 108 | 2 | 2 | `u16` | - |
| `reserved0` | 110 | 2 | 2 | `u16` | - |
| `boot_byte_length` | 112 | 8 | 8 | `u64` | - |
| `byte_length` | 120 | 8 | 8 | `u64` | - |
| `backend_name` | 128 | 24 | 1 | `[24]u8` | - |
| `fallback_name` | 152 | 24 | 1 | `[24]u8` | - |

### `GfxBufferHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `id` | 0 | 4 | 4 | `u32` | - |
| `reserved0` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |

### `GfxBufferDescriptor`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `byte_length` | 8 | 8 | 8 | `u64` | - |
| `alignment` | 16 | 8 | 8 | `u64` | - |
| `modifier` | 24 | 8 | 8 | `u64` | - |
| `width` | 32 | 4 | 4 | `u32` | - |
| `height` | 36 | 4 | 4 | `u32` | - |
| `format` | 40 | 4 | 4 | `u32` | - |
| `plane_count` | 44 | 4 | 4 | `u32` | - |
| `usage` | 48 | 4 | 4 | `u32` | - |
| `location` | 52 | 4 | 4 | `u32` | - |
| `adapter_id` | 56 | 4 | 4 | `u32` | - |
| `driver_owner` | 60 | 4 | 4 | `u32` | - |
| `device_generation` | 64 | 8 | 8 | `u64` | - |
| `plane_offsets` | 72 | 32 | 8 | `[4]u64` | - |
| `plane_pitches` | 104 | 32 | 8 | `[4]u64` | - |
| `reserved0` | 136 | 8 | 8 | `u64` | - |

### `GfxBufferReference`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `buffer` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `reference` | 24 | 16 | 8 | `GfxBufferHandle` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |

### `GfxBufferMap`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `lease` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `cpu_address` | 24 | 8 | 8 | `u64` | - |
| `byte_length` | 32 | 8 | 8 | `u64` | - |
| `cache_policy` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |

### `GfxBufferStats`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 136 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `objects` | 8 | 4 | 4 | `u32` | - |
| `references` | 12 | 4 | 4 | `u32` | - |
| `leases` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `committed_bytes` | 24 | 8 | 8 | `u64` | - |
| `retained_bytes` | 32 | 8 | 8 | `u64` | - |
| `budget_bytes` | 40 | 8 | 8 | `u64` | - |
| `producer_budget_bytes` | 48 | 8 | 8 | `u64` | - |
| `system_bytes` | 56 | 8 | 8 | `u64` | - |
| `device_bytes` | 64 | 8 | 8 | `u64` | - |
| `system_backed_bytes` | 72 | 8 | 8 | `u64` | - |
| `device_backed_bytes` | 80 | 8 | 8 | `u64` | - |
| `system_pinned_bytes` | 88 | 8 | 8 | `u64` | - |
| `device_pinned_bytes` | 96 | 8 | 8 | `u64` | - |
| `scanout_pinned_bytes` | 104 | 8 | 8 | `u64` | - |
| `device_mapped_bytes` | 112 | 8 | 8 | `u64` | - |
| `allocating_bytes` | 120 | 8 | 8 | `u64` | - |
| `destroying_bytes` | 128 | 8 | 8 | `u64` | - |

### `GfxDeviceRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `byte_offset` | 8 | 8 | 8 | `u64` | - |
| `byte_length` | 16 | 8 | 8 | `u64` | - |
| `gpu_virtual_address` | 24 | 8 | 8 | `u64` | - |
| `device_generation` | 32 | 8 | 8 | `u64` | - |
| `adapter_id` | 40 | 4 | 4 | `u32` | - |
| `access` | 44 | 4 | 4 | `u32` | - |
| `address_space` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `dma_mask` | 56 | 8 | 8 | `u64` | - |

### `GfxDeviceLease`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `lease` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `byte_offset` | 24 | 8 | 8 | `u64` | - |
| `byte_length` | 32 | 8 | 8 | `u64` | - |
| `gpu_virtual_address` | 40 | 8 | 8 | `u64` | - |
| `device_generation` | 48 | 8 | 8 | `u64` | - |
| `adapter_id` | 56 | 4 | 4 | `u32` | - |
| `driver_owner` | 60 | 4 | 4 | `u32` | - |
| `access` | 64 | 4 | 4 | `u32` | - |
| `address_space` | 68 | 4 | 4 | `u32` | - |
| `dma_mask` | 72 | 8 | 8 | `u64` | - |

### `GfxDmaSegment`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `dma_address` | 8 | 8 | 8 | `u64` | - |
| `byte_length` | 16 | 8 | 8 | `u64` | - |
| `next_offset` | 24 | 8 | 8 | `u64` | - |

### `GfxMmioRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `resource_base` | 8 | 8 | 8 | `u64` | - |
| `resource_bytes` | 16 | 8 | 8 | `u64` | - |
| `byte_offset` | 24 | 8 | 8 | `u64` | - |
| `byte_length` | 32 | 8 | 8 | `u64` | - |
| `cache_policy` | 40 | 4 | 4 | `u32` | - |
| `resource_flags` | 44 | 4 | 4 | `u32` | - |

### `GfxMmioWindow`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `cpu_address` | 24 | 8 | 8 | `u64` | - |
| `physical_address` | 32 | 8 | 8 | `u64` | - |
| `byte_length` | 40 | 8 | 8 | `u64` | - |
| `cache_policy` | 48 | 4 | 4 | `u32` | - |
| `flags` | 52 | 4 | 4 | `u32` | - |

### `GfxOwnedBufferReservation`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `buffer` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `reference` | 24 | 16 | 8 | `GfxBufferHandle` | - |
| `allocation_bytes` | 40 | 8 | 8 | `u64` | - |
| `cookie` | 48 | 8 | 8 | `u64` | - |
| `device_generation` | 56 | 8 | 8 | `u64` | - |
| `driver_generation` | 64 | 8 | 8 | `u64` | - |
| `adapter_id` | 72 | 4 | 4 | `u32` | - |
| `driver_owner` | 76 | 4 | 4 | `u32` | - |
| `reserved0` | 80 | 8 | 8 | `u64` | - |

### `GfxOwnedBufferRelease`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `buffer` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `cookie` | 24 | 8 | 8 | `u64` | - |
| `byte_length` | 32 | 8 | 8 | `u64` | - |
| `attempt` | 40 | 8 | 8 | `u64` | - |
| `device_generation` | 48 | 8 | 8 | `u64` | - |
| `driver_generation` | 56 | 8 | 8 | `u64` | - |
| `adapter_id` | 64 | 4 | 4 | `u32` | - |
| `driver_owner` | 68 | 4 | 4 | `u32` | - |
| `reserved0` | 72 | 8 | 8 | `u64` | - |

### `GfxDriverMemoryApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 8 / 256 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `buffer_create` | 8 | 8 | 8 | `u64` | - |
| `buffer_describe` | 16 | 8 | 8 | `u64` | - |
| `buffer_import` | 24 | 8 | 8 | `u64` | - |
| `buffer_release` | 32 | 8 | 8 | `u64` | - |
| `buffer_map` | 40 | 8 | 8 | `u64` | - |
| `buffer_unmap` | 48 | 8 | 8 | `u64` | - |
| `device_acquire` | 56 | 8 | 8 | `u64` | - |
| `device_segment` | 64 | 8 | 8 | `u64` | - |
| `device_release` | 72 | 8 | 8 | `u64` | - |
| `mmio_map` | 80 | 8 | 8 | `u64` | - |
| `mmio_unmap` | 88 | 8 | 8 | `u64` | - |
| `collect` | 96 | 8 | 8 | `u64` | - |
| `buffer_stats` | 104 | 8 | 8 | `u64` | - |
| `buffer_reserve` | 112 | 8 | 8 | `u64` | - |
| `buffer_commit` | 120 | 8 | 8 | `u64` | - |
| `buffer_abort` | 128 | 8 | 8 | `u64` | - |
| `buffer_take_release` | 136 | 8 | 8 | `u64` | - |
| `buffer_finish_release` | 144 | 8 | 8 | `u64` | - |
| `native_register` | 152 | 8 | 8 | `u64` | - |
| `native_unregister` | 160 | 8 | 8 | `u64` | - |
| `native_take` | 168 | 8 | 8 | `u64` | - |
| `native_complete` | 176 | 8 | 8 | `u64` | - |
| `memory_budget` | 184 | 8 | 8 | `u64` | - |
| `telemetry_exchange` | 192 | 8 | 8 | `u64` | - |
| `device_lost` | 200 | 8 | 8 | `u64` | - |
| `virtual_register` | 208 | 8 | 8 | `u64` | - |
| `virtual_unregister` | 216 | 8 | 8 | `u64` | - |
| `virtual_take` | 224 | 8 | 8 | `u64` | - |
| `virtual_complete` | 232 | 8 | 8 | `u64` | - |
| `reserved_span` | 240 | 8 | 8 | `u64` | - |
| `unmanaged_span` | 248 | 8 | 8 | `u64` | - |

### `GfxFence`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `slot` | 0 | 4 | 4 | `u32` | - |
| `adapter_id` | 4 | 4 | 4 | `u32` | - |
| `timeline` | 8 | 8 | 8 | `u64` | - |
| `point` | 16 | 8 | 8 | `u64` | - |
| `device_generation` | 24 | 8 | 8 | `u64` | - |
| `reset_generation` | 32 | 8 | 8 | `u64` | - |

### `GfxQueueConfig`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `policy` | 12 | 4 | 4 | `u32` | - |
| `capacity` | 16 | 4 | 4 | `u32` | - |
| `milestone` | 20 | 4 | 4 | `u32` | - |
| `device_generation` | 24 | 8 | 8 | `u64` | - |
| `reset_generation` | 32 | 8 | 8 | `u64` | - |

### `GfxQueueHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `timeline` | 8 | 8 | 8 | `u64` | - |

### `GfxSubmission`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 3 / 512 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `operation` | 8 | 4 | 4 | `u32` | - |
| `dependency_count` | 12 | 4 | 4 | `u32` | - |
| `deadline_ns` | 16 | 8 | 8 | `u64` | - |
| `frame_key` | 24 | 8 | 8 | `u64` | - |
| `source` | 32 | 16 | 8 | `GfxBufferHandle` | - |
| `target` | 48 | 16 | 8 | `GfxBufferHandle` | - |
| `source_offset` | 64 | 8 | 8 | `u64` | - |
| `target_offset` | 72 | 8 | 8 | `u64` | - |
| `byte_length` | 80 | 8 | 8 | `u64` | - |
| `dependencies` | 88 | 320 | 8 | `[8]GfxFence` | - |
| `row_count` | 408 | 4 | 4 | `u32` | - |
| `reserved0` | 412 | 4 | 4 | `u32` | - |
| `source_pitch` | 416 | 8 | 8 | `u64` | - |
| `target_pitch` | 424 | 8 | 8 | `u64` | - |
| `render` | 432 | 80 | 8 | `GfxRenderCommand` | - |

### `GfxFenceStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `fence` | 8 | 40 | 8 | `GfxFence` | - |
| `phase` | 48 | 4 | 4 | `u32` | - |
| `result` | 52 | 4 | 4 | `u32` | - |
| `milestone` | 56 | 4 | 4 | `u32` | - |
| `flags` | 60 | 4 | 4 | `u32` | - |
| `deadline_ns` | 64 | 8 | 8 | `u64` | - |
| `completed_ns` | 72 | 8 | 8 | `u64` | - |

### `GfxBackendBinding`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `milestone` | 12 | 4 | 4 | `u32` | - |
| `device_generation` | 16 | 8 | 8 | `u64` | - |
| `reset_generation` | 24 | 8 | 8 | `u64` | - |

### `GfxBackendRegistration`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `milestone` | 12 | 4 | 4 | `u32` | - |
| `notify_callback` | 16 | 8 | 8 | `u64` | - |
| `context` | 24 | 8 | 8 | `u64` | - |
| `operations` | 32 | 8 | 8 | `u64` | - |
| `memory_generation` | 40 | 8 | 8 | `u64` | - |

### `GfxDriverJob`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 4 / 296 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `fence` | 8 | 40 | 8 | `GfxFence` | - |
| `operation` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `source_buffer` | 56 | 16 | 8 | `GfxBufferHandle` | - |
| `target_buffer` | 72 | 16 | 8 | `GfxBufferHandle` | - |
| `byte_length` | 88 | 8 | 8 | `u64` | - |
| `source_offset` | 96 | 8 | 8 | `u64` | - |
| `target_offset` | 104 | 8 | 8 | `u64` | - |
| `row_count` | 112 | 4 | 4 | `u32` | - |
| `reserved1` | 116 | 4 | 4 | `u32` | - |
| `source_pitch` | 120 | 8 | 8 | `u64` | - |
| `target_pitch` | 128 | 8 | 8 | `u64` | - |
| `render` | 136 | 80 | 8 | `GfxRenderCommand` | - |
| `deadline_ns` | 216 | 8 | 8 | `u64` | - |
| `display_target` | 224 | 48 | 8 | `GfxOutputTarget` | - |
| `producer_kind` | 272 | 4 | 4 | `u32` | - |
| `producer_reserved` | 276 | 4 | 4 | `u32` | - |
| `producer_id` | 280 | 8 | 8 | `u64` | - |
| `producer_generation` | 288 | 8 | 8 | `u64` | - |

### `GfxDriverQueueApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 10 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `register_backend` | 8 | 8 | 8 | `u64` | - |
| `unregister_backend` | 16 | 8 | 8 | `u64` | - |
| `take` | 24 | 8 | 8 | `u64` | - |
| `complete` | 32 | 8 | 8 | `u64` | - |
| `reset` | 40 | 8 | 8 | `u64` | - |
| `segment` | 48 | 8 | 8 | `u64` | - |
| `retain_resource` | 56 | 8 | 8 | `u64` | - |
| `register_profile` | 64 | 8 | 8 | `u64` | - |
| `update_operations` | 72 | 8 | 8 | `u64` | - |
| `read_render_list` | 80 | 8 | 8 | `u64` | - |
| `retain_scanout` | 88 | 8 | 8 | `u64` | - |
| `begin_scanout` | 96 | 8 | 8 | `u64` | - |
| `scanout_retire_requested` | 104 | 8 | 8 | `u64` | - |
| `read_render_grid_list` | 112 | 8 | 8 | `u64` | - |
| `read_render_color_list` | 120 | 8 | 8 | `u64` | - |
| `publish_properties` | 128 | 8 | 8 | `u64` | - |
| `read_native_info` | 136 | 8 | 8 | `u64` | - |
| `read_native_data` | 144 | 8 | 8 | `u64` | - |
| `read_native_binding` | 152 | 8 | 8 | `u64` | - |
| `queue_owner_info` | 160 | 8 | 8 | `u64` | - |

### `GfxOutputId`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `adapter_id` | 0 | 4 | 4 | `u32` | - |
| `connector_id` | 4 | 4 | 4 | `u32` | - |
| `device_generation` | 8 | 8 | 8 | `u64` | - |
| `connection_generation` | 16 | 8 | 8 | `u64` | - |

### `GfxOutputMode`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `mode_id` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `width` | 16 | 4 | 4 | `u32` | - |
| `height` | 20 | 4 | 4 | `u32` | - |
| `pixel_clock_hz` | 24 | 8 | 8 | `u64` | - |
| `h_total` | 32 | 4 | 4 | `u32` | - |
| `h_sync_start` | 36 | 4 | 4 | `u32` | - |
| `h_sync_end` | 40 | 4 | 4 | `u32` | - |
| `v_total` | 44 | 4 | 4 | `u32` | - |
| `v_sync_start` | 48 | 4 | 4 | `u32` | - |
| `v_sync_end` | 52 | 4 | 4 | `u32` | - |
| `refresh_millihz` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |

### `GfxDisplayLimits`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `head_mask` | 12 | 4 | 4 | `u32` | - |
| `plane_mask` | 16 | 4 | 4 | `u32` | - |
| `pll_mask` | 20 | 4 | 4 | `u32` | - |
| `rotations` | 24 | 4 | 4 | `u32` | - |
| `colors` | 28 | 4 | 4 | `u32` | - |
| `bpc_mask` | 32 | 4 | 4 | `u32` | - |
| `pitch_alignment` | 36 | 4 | 4 | `u32` | - |
| `max_width` | 40 | 4 | 4 | `u32` | - |
| `max_height` | 44 | 4 | 4 | `u32` | - |
| `formats` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `modifiers` | 56 | 8 | 8 | `u64` | - |
| `bandwidth_bytes_per_second` | 64 | 8 | 8 | `u64` | - |
| `max_pixel_clock_hz` | 72 | 8 | 8 | `u64` | - |
| `total_pixel_clock_hz` | 80 | 8 | 8 | `u64` | - |

### `GfxOutputInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `topology_revision` | 32 | 8 | 8 | `u64` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `connector_kind` | 44 | 4 | 4 | `u32` | - |
| `mode_count` | 48 | 4 | 4 | `u32` | - |
| `preferred_mode_id` | 52 | 4 | 4 | `u32` | - |
| `edid_bytes` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |
| `possible_heads` | 64 | 4 | 4 | `u32` | - |
| `possible_planes` | 68 | 4 | 4 | `u32` | - |
| `possible_plls` | 72 | 4 | 4 | `u32` | - |
| `reserved1` | 76 | 4 | 4 | `u32` | - |
| `limits` | 80 | 88 | 8 | `GfxDisplayLimits` | - |

### `GfxDisplayRevision`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `revision` | 8 | 8 | 8 | `u64` | - |
| `capacity` | 16 | 4 | 4 | `u32` | - |
| `present` | 20 | 4 | 4 | `u32` | - |

### `GfxEdidBlock`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `block_index` | 32 | 4 | 4 | `u32` | - |
| `byte_count` | 36 | 4 | 4 | `u32` | - |
| `data` | 40 | 128 | 1 | `[128]u8` | - |

### `GfxScanoutState`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 152 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `output` | 8 | 24 | 8 | `GfxOutputId` | - |
| `mode_id` | 32 | 4 | 4 | `u32` | - |
| `head_id` | 36 | 4 | 4 | `u32` | - |
| `plane_id` | 40 | 4 | 4 | `u32` | - |
| `pll_id` | 44 | 4 | 4 | `u32` | - |
| `source_x` | 48 | 4 | 4 | `u32` | - |
| `source_y` | 52 | 4 | 4 | `u32` | - |
| `source_width` | 56 | 4 | 4 | `u32` | - |
| `source_height` | 60 | 4 | 4 | `u32` | - |
| `destination_x` | 64 | 4 | 4 | `u32` | - |
| `destination_y` | 68 | 4 | 4 | `u32` | - |
| `destination_width` | 72 | 4 | 4 | `u32` | - |
| `destination_height` | 76 | 4 | 4 | `u32` | - |
| `rotation` | 80 | 4 | 4 | `u32` | - |
| `color` | 84 | 4 | 4 | `u32` | - |
| `bits_per_color` | 88 | 4 | 4 | `u32` | - |
| `reserved0` | 92 | 4 | 4 | `u32` | - |
| `buffer` | 96 | 16 | 8 | `GfxBufferHandle` | - |
| `ready_fence` | 112 | 40 | 8 | `GfxFence` | - |

### `GfxAtomicState`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1240 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `topology_revision` | 8 | 8 | 8 | `u64` | - |
| `count` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `assignments` | 24 | 1216 | 8 | `[8]GfxScanoutState` | - |

### `GfxAtomicResult`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `topology_revision` | 8 | 8 | 8 | `u64` | - |
| `commit_sequence` | 16 | 8 | 8 | `u64` | - |
| `outcome` | 24 | 4 | 4 | `u32` | - |
| `retained` | 28 | 4 | 4 | `u32` | - |

### `GfxOutputPublication`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8400 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `backend` | 8 | 32 | 8 | `GfxBackendBinding` | - |
| `info` | 40 | 168 | 8 | `GfxOutputInfo` | - |
| `modes` | 208 | 4096 | 8 | `[64]GfxOutputMode` | - |
| `edid` | 4304 | 4096 | 1 | `[4096]u8` | - |

### `GfxReceiverSource`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `adapter_id` | 0 | 4 | 4 | `u32` | - |
| `reserved0` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |

### `GfxReceiverInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8224 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `connector_id` | 0 | 4 | 4 | `u32` | - |
| `connector_kind` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `mode_count` | 12 | 4 | 4 | `u32` | - |
| `preferred_mode_id` | 16 | 4 | 4 | `u32` | - |
| `edid_bytes` | 20 | 4 | 4 | `u32` | - |
| `reserved0` | 24 | 8 | 8 | `u64` | - |
| `modes` | 32 | 4096 | 8 | `[64]GfxOutputMode` | - |
| `edid` | 4128 | 4096 | 1 | `[4096]u8` | - |

### `GfxReceiverUpdate`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `source` | 8 | 16 | 8 | `GfxReceiverSource` | - |
| `sequence` | 24 | 8 | 8 | `u64` | - |
| `count` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `receivers` | 40 | 8 | 8 | `u64` | - |

### `GfxDriverOutputApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 10 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `publish` | 8 | 8 | 8 | `u64` | - |
| `withdraw` | 16 | 8 | 8 | `u64` | - |
| `register_source` | 24 | 8 | 8 | `u64` | - |
| `replace_receivers` | 32 | 8 | 8 | `u64` | - |
| `close_source` | 40 | 8 | 8 | `u64` | - |
| `mode_enable` | 48 | 8 | 8 | `u64` | - |
| `mode_take` | 56 | 8 | 8 | `u64` | - |
| `mode_complete` | 64 | 8 | 8 | `u64` | - |
| `audio_publish` | 72 | 8 | 8 | `u64` | - |
| `audio_query` | 80 | 8 | 8 | `u64` | - |
| `output_pause` | 88 | 8 | 8 | `u64` | - |
| `mode_restore` | 96 | 8 | 8 | `u64` | - |
| `mode_status` | 104 | 8 | 8 | `u64` | - |
| `color_publish` | 112 | 8 | 8 | `u64` | - |
| `mode_read_color` | 120 | 8 | 8 | `u64` | - |
| `refresh_publish` | 128 | 8 | 8 | `u64` | - |
| `refresh_read` | 136 | 8 | 8 | `u64` | - |
| `power_publish` | 144 | 8 | 8 | `u64` | - |
| `power_read` | 152 | 8 | 8 | `u64` | - |
| `brightness_publish` | 160 | 8 | 8 | `u64` | - |
| `brightness_read` | 168 | 8 | 8 | `u64` | - |

### `GfxNativeBootInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `physical_address` | 16 | 8 | 8 | `u64` | - |
| `byte_length` | 24 | 8 | 8 | `u64` | - |
| `width` | 32 | 4 | 4 | `u32` | - |
| `height` | 36 | 4 | 4 | `u32` | - |
| `pitch` | 40 | 4 | 4 | `u32` | - |
| `format` | 44 | 4 | 4 | `u32` | - |
| `policy` | 48 | 4 | 4 | `u32` | - |
| `state` | 52 | 4 | 4 | `u32` | - |

### `GfxNativeRegistration`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `backend` | 8 | 32 | 8 | `GfxBackendBinding` | - |
| `output` | 40 | 24 | 8 | `GfxOutputId` | - |
| `reference` | 64 | 16 | 8 | `GfxBufferHandle` | - |
| `name` | 80 | 24 | 1 | `[24]u8` | - |
| `context` | 104 | 8 | 8 | `u64` | - |
| `commit_callback` | 112 | 8 | 8 | `u64` | - |
| `restore_callback` | 120 | 8 | 8 | `u64` | - |

### `GfxNativeState`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `state` | 16 | 4 | 4 | `u32` | - |
| `outcome` | 20 | 4 | 4 | `u32` | - |
| `retained` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `GfxBootHoldRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `reference` | 24 | 16 | 8 | `GfxBufferHandle` | - |
| `context` | 40 | 8 | 8 | `u64` | - |
| `restore_callback` | 48 | 8 | 8 | `u64` | - |

### `GfxDriverDisplayApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 8 / 152 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `boot_info` | 8 | 8 | 8 | `u64` | - |
| `prepare` | 16 | 8 | 8 | `u64` | - |
| `transition` | 24 | 8 | 8 | `u64` | - |
| `schedule` | 32 | 8 | 8 | `u64` | - |
| `boot_hold` | 40 | 8 | 8 | `u64` | - |
| `boot_finish` | 48 | 8 | 8 | `u64` | - |
| `prepare_held` | 56 | 8 | 8 | `u64` | - |
| `presentation_stats` | 64 | 8 | 8 | `u64` | - |
| `cursor_configure` | 72 | 8 | 8 | `u64` | - |
| `cursor_take` | 80 | 8 | 8 | `u64` | - |
| `cursor_complete` | 88 | 8 | 8 | `u64` | - |
| `presentation_info` | 96 | 8 | 8 | `u64` | - |
| `output_register` | 104 | 8 | 8 | `u64` | - |
| `output_transition` | 112 | 8 | 8 | `u64` | - |
| `device_reset` | 120 | 8 | 8 | `u64` | - |
| `prepare_reset` | 128 | 8 | 8 | `u64` | - |
| `terminal_release` | 136 | 8 | 8 | `u64` | - |
| `resume_headless` | 144 | 8 | 8 | `u64` | - |

### `DriverResourceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 8 | 8 | `u64` | - |
| `byte_length` | 16 | 8 | 8 | `u64` | - |
| `module_generation` | 24 | 8 | 8 | `u64` | - |

### `DriverFirmwareTableInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 8 | 8 | `u64` | - |
| `byte_length` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `signature` | 32 | 4 | 4 | `u32` | - |
| `revision` | 36 | 4 | 4 | `u32` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |

### `DriverResourceApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 3 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `stat` | 8 | 8 | 8 | `u64` | - |
| `read_at` | 16 | 8 | 8 | `u64` | - |
| `now_ns` | 24 | 8 | 8 | `u64` | - |
| `acpi_stat` | 32 | 8 | 8 | `u64` | - |
| `acpi_read_at` | 40 | 8 | 8 | `u64` | - |
| `platform_query` | 48 | 8 | 8 | `u64` | - |
| `cpu_power_query` | 56 | 8 | 8 | `u64` | - |
| `entropy_query` | 64 | 8 | 8 | `u64` | - |

### `DriverHeapAllocation`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 8 | 8 | `u64` | - |
| `cpu_address` | 16 | 8 | 8 | `u64` | - |
| `byte_length` | 24 | 8 | 8 | `u64` | - |
| `alignment` | 32 | 4 | 4 | `u32` | - |
| `reserved` | 36 | 4 | 4 | `u32` | - |

### `DriverHeapStats`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 104 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `owner_epoch` | 8 | 8 | 8 | `u64` | - |
| `allocations` | 16 | 8 | 8 | `u64` | - |
| `bytes` | 24 | 8 | 8 | `u64` | - |
| `backing_bytes` | 32 | 8 | 8 | `u64` | - |
| `peak_bytes` | 40 | 8 | 8 | `u64` | - |
| `private_allocations` | 48 | 8 | 8 | `u64` | - |
| `allocation_calls` | 56 | 8 | 8 | `u64` | - |
| `allocation_failures` | 64 | 8 | 8 | `u64` | - |
| `releases` | 72 | 8 | 8 | `u64` | - |
| `release_failures` | 80 | 8 | 8 | `u64` | - |
| `pending_creates` | 88 | 4 | 4 | `u32` | - |
| `pending_releases` | 92 | 4 | 4 | `u32` | - |
| `closing` | 96 | 4 | 4 | `u32` | - |
| `reserved` | 100 | 4 | 4 | `u32` | - |

### `DriverHeapApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `allocate` | 8 | 8 | 8 | `u64` | - |
| `release` | 16 | 8 | 8 | `u64` | - |
| `stats` | 24 | 8 | 8 | `u64` | - |

### `DriverThreadRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handler` | 8 | 8 | 8 | `u64` | - |
| `context` | 16 | 8 | 8 | `u64` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |

### `DriverThreadStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 8 | 8 | `u64` | - |
| `owner_epoch` | 16 | 8 | 8 | `u64` | - |
| `task_generation` | 24 | 8 | 8 | `u64` | - |
| `task_id` | 32 | 4 | 4 | `u32` | - |
| `cpu_index` | 36 | 4 | 4 | `u32` | - |
| `state` | 40 | 4 | 4 | `u32` | - |
| `stop_requested` | 44 | 4 | 4 | `u32` | - |
| `result` | 48 | 4 | 4 | `i32` | - |
| `flags` | 52 | 4 | 4 | `u32` | - |
| `waiters` | 56 | 4 | 4 | `u32` | - |
| `reserved` | 60 | 4 | 4 | `u32` | - |

### `DriverThreadStats`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `owner_epoch` | 8 | 8 | 8 | `u64` | - |
| `records` | 16 | 8 | 8 | `u64` | - |
| `active` | 24 | 8 | 8 | `u64` | - |
| `completed` | 32 | 8 | 8 | `u64` | - |
| `private_records` | 40 | 8 | 8 | `u64` | - |
| `starts` | 48 | 8 | 8 | `u64` | - |
| `start_failures` | 56 | 8 | 8 | `u64` | - |
| `releases` | 64 | 8 | 8 | `u64` | - |
| `release_retries` | 72 | 8 | 8 | `u64` | - |
| `pending_creates` | 80 | 4 | 4 | `u32` | - |
| `pending_releases` | 84 | 4 | 4 | `u32` | - |
| `waiters` | 88 | 4 | 4 | `u32` | - |
| `closing` | 92 | 4 | 4 | `u32` | - |

### `DriverThreadApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `start` | 8 | 8 | 8 | `u64` | - |
| `stop` | 16 | 8 | 8 | `u64` | - |
| `join` | 24 | 8 | 8 | `u64` | - |
| `release` | 32 | 8 | 8 | `u64` | - |
| `status` | 40 | 8 | 8 | `u64` | - |
| `current` | 48 | 8 | 8 | `u64` | - |
| `sleep_ticks` | 56 | 8 | 8 | `u64` | - |
| `stats` | 64 | 8 | 8 | `u64` | - |
| `abort_current` | 72 | 8 | 8 | `u64` | - |
| `current_request` | 80 | 8 | 8 | `u64` | - |

### `DriverSemaphoreStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 8 | 8 | `u64` | - |
| `owner_epoch` | 16 | 8 | 8 | `u64` | - |
| `available` | 24 | 4 | 4 | `u32` | - |
| `maximum` | 28 | 4 | 4 | `u32` | - |
| `queued_waiters` | 32 | 4 | 4 | `u32` | - |
| `active_acquires` | 36 | 4 | 4 | `u32` | - |

### `DriverSemaphoreStats`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `owner_epoch` | 8 | 8 | 8 | `u64` | - |
| `records` | 16 | 8 | 8 | `u64` | - |
| `private_records` | 24 | 8 | 8 | `u64` | - |
| `creates` | 32 | 8 | 8 | `u64` | - |
| `create_failures` | 40 | 8 | 8 | `u64` | - |
| `destroys` | 48 | 8 | 8 | `u64` | - |
| `destroy_failures` | 56 | 8 | 8 | `u64` | - |
| `pending_creates` | 64 | 4 | 4 | `u32` | - |
| `pending_destroys` | 68 | 4 | 4 | `u32` | - |
| `active_acquires` | 72 | 4 | 4 | `u32` | - |
| `closing` | 76 | 4 | 4 | `u32` | - |

### `DriverSemaphoreApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `create` | 8 | 8 | 8 | `u64` | - |
| `acquire` | 16 | 8 | 8 | `u64` | - |
| `release` | 24 | 8 | 8 | `u64` | - |
| `destroy` | 32 | 8 | 8 | `u64` | - |
| `status` | 40 | 8 | 8 | `u64` | - |
| `stats` | 48 | 8 | 8 | `u64` | - |
| `context_flags` | 56 | 8 | 8 | `u64` | - |

### `GfxModeStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `ticket` | 8 | 8 | 8 | `u64` | - |
| `topology_revision` | 16 | 8 | 8 | `u64` | - |
| `commit_sequence` | 24 | 8 | 8 | `u64` | - |
| `confirmation_deadline_ns` | 32 | 8 | 8 | `u64` | - |
| `operation_deadline_ns` | 40 | 8 | 8 | `u64` | - |
| `phase` | 48 | 4 | 4 | `u32` | - |
| `outcome` | 52 | 4 | 4 | `u32` | - |
| `retained` | 56 | 4 | 4 | `u32` | - |
| `error_code` | 60 | 4 | 4 | `i32` | - |
| `output` | 64 | 24 | 8 | `GfxOutputId` | - |

### `GfxDriverModeJob`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 336 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `ticket` | 8 | 8 | 8 | `u64` | - |
| `sequence` | 16 | 8 | 8 | `u64` | - |
| `operation` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `backend` | 32 | 32 | 8 | `GfxBackendBinding` | - |
| `assignment` | 64 | 152 | 8 | `GfxScanoutState` | - |
| `mode` | 216 | 64 | 8 | `GfxOutputMode` | - |
| `reference` | 280 | 48 | 8 | `GfxBufferReference` | - |
| `deadline_ns` | 328 | 8 | 8 | `u64` | - |

### `GfxDriverModeCompletion`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `ticket` | 8 | 8 | 8 | `u64` | - |
| `sequence` | 16 | 8 | 8 | `u64` | - |
| `operation` | 24 | 4 | 4 | `u32` | - |
| `outcome` | 28 | 4 | 4 | `u32` | - |
| `quiesced` | 32 | 4 | 4 | `u32` | - |
| `error_code` | 36 | 4 | 4 | `i32` | - |

### `DisplayPresentationStats`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 208 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `head_id` | 12 | 4 | 4 | `u32` | - |
| `backend` | 16 | 32 | 8 | `GfxBackendBinding` | - |
| `display_generation` | 48 | 8 | 8 | `u64` | - |
| `sequence` | 56 | 8 | 8 | `u64` | - |
| `visible_sequence` | 64 | 8 | 8 | `u64` | - |
| `pending` | 72 | 4 | 4 | `u32` | - |
| `buffer_count` | 76 | 4 | 4 | `u32` | - |
| `acquired_count` | 80 | 8 | 8 | `u64` | - |
| `rendered_count` | 88 | 8 | 8 | `u64` | - |
| `submitted_count` | 96 | 8 | 8 | `u64` | - |
| `visible_count` | 104 | 8 | 8 | `u64` | - |
| `released_count` | 112 | 8 | 8 | `u64` | - |
| `rejected_count` | 120 | 8 | 8 | `u64` | - |
| `source_timeline` | 128 | 8 | 8 | `u64` | - |
| `source_point` | 136 | 8 | 8 | `u64` | - |
| `render_point` | 144 | 8 | 8 | `u64` | - |
| `window_point` | 152 | 8 | 8 | `u64` | - |
| `submitted_ns` | 160 | 8 | 8 | `u64` | - |
| `visible_ns` | 168 | 8 | 8 | `u64` | - |
| `gpu_timestamp` | 176 | 8 | 8 | `u64` | - |
| `irq_sequence` | 184 | 8 | 8 | `u64` | - |
| `irq_observed_ns` | 192 | 8 | 8 | `u64` | - |
| `released_ns` | 200 | 8 | 8 | `u64` | - |

### `DisplayCursorInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `head_id` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `backend` | 16 | 32 | 8 | `GfxBackendBinding` | - |
| `display_generation` | 48 | 8 | 8 | `u64` | - |
| `max_width` | 56 | 4 | 4 | `u32` | - |
| `max_height` | 60 | 4 | 4 | `u32` | - |
| `min_x` | 64 | 4 | 4 | `i32` | - |
| `min_y` | 68 | 4 | 4 | `i32` | - |
| `max_x` | 72 | 4 | 4 | `i32` | - |
| `max_y` | 76 | 4 | 4 | `i32` | - |

### `DisplayCursorRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `display_generation` | 8 | 8 | 8 | `u64` | - |
| `operation` | 16 | 4 | 4 | `u32` | - |
| `head_id` | 20 | 4 | 4 | `u32` | - |
| `reference` | 24 | 16 | 8 | `GfxBufferHandle` | - |
| `image_sequence` | 40 | 8 | 8 | `u64` | - |
| `x` | 48 | 4 | 4 | `i32` | - |
| `y` | 52 | 4 | 4 | `i32` | - |
| `hotspot_x` | 56 | 4 | 4 | `u32` | - |
| `hotspot_y` | 60 | 4 | 4 | `u32` | - |
| `width` | 64 | 4 | 4 | `u32` | - |
| `height` | 68 | 4 | 4 | `u32` | - |
| `pitch` | 72 | 8 | 8 | `u64` | - |
| `byte_length` | 80 | 8 | 8 | `u64` | - |

### `DisplayCursorStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `display_generation` | 8 | 8 | 8 | `u64` | - |
| `sequence` | 16 | 8 | 8 | `u64` | - |
| `completed` | 24 | 8 | 8 | `u64` | - |
| `image_sequence` | 32 | 8 | 8 | `u64` | - |
| `phase` | 40 | 4 | 4 | `u32` | - |
| `flags` | 44 | 4 | 4 | `u32` | - |
| `x` | 48 | 4 | 4 | `i32` | - |
| `y` | 52 | 4 | 4 | `i32` | - |
| `head_id` | 56 | 4 | 4 | `u32` | - |
| `error_code` | 60 | 4 | 4 | `i32` | - |
| `deadline_ns` | 64 | 8 | 8 | `u64` | - |

### `GfxDriverCursorJob`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `backend` | 8 | 32 | 8 | `GfxBackendBinding` | - |
| `sequence` | 40 | 8 | 8 | `u64` | - |
| `deadline_ns` | 48 | 8 | 8 | `u64` | - |
| `barrier_timeline` | 56 | 8 | 8 | `u64` | - |
| `barrier_point` | 64 | 8 | 8 | `u64` | - |
| `request` | 72 | 88 | 8 | `DisplayCursorRequest` | - |

### `GfxDriverCursorCompletion`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `sequence` | 8 | 8 | 8 | `u64` | - |
| `display_generation` | 16 | 8 | 8 | `u64` | - |
| `error_code` | 24 | 4 | 4 | `i32` | - |
| `outcome` | 28 | 4 | 4 | `u32` | - |
| `visibility` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |

### `GfxAudioRoute`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `source` | 8 | 16 | 8 | `GfxReceiverSource` | - |
| `receiver_sequence` | 24 | 8 | 8 | `u64` | - |
| `revision` | 32 | 8 | 8 | `u64` | - |
| `connector_id` | 40 | 4 | 4 | `u32` | - |
| `hda_location` | 44 | 4 | 4 | `u32` | - |
| `hda_device` | 48 | 4 | 4 | `u32` | - |
| `head_id` | 52 | 4 | 4 | `u32` | - |
| `device_entry` | 56 | 4 | 4 | `u32` | - |
| `state` | 60 | 4 | 4 | `u32` | - |
| `eld_bytes` | 64 | 4 | 4 | `u32` | - |
| `reserved0` | 68 | 4 | 4 | `u32` | - |
| `port_id` | 72 | 8 | 1 | `[8]u8` | - |
| `eld` | 80 | 96 | 1 | `[96]u8` | - |

### `GfxBackendProfile`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `interface_id_lo` | 8 | 8 | 8 | `u64` | - |
| `interface_id_hi` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 4 | 4 | `u32` | - |
| `data_bytes` | 28 | 4 | 4 | `u32` | - |
| `data` | 32 | 64 | 1 | `[64]u8` | - |

### `GfxBackendInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 2 / 152 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `binding` | 8 | 32 | 8 | `GfxBackendBinding` | - |
| `profile` | 40 | 96 | 8 | `GfxBackendProfile` | - |
| `operations` | 136 | 8 | 8 | `u64` | - |
| `memory_generation` | 144 | 8 | 8 | `u64` | - |

### `GfxNativeAllocation`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `kind` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `deadline_ns` | 24 | 8 | 8 | `u64` | - |
| `byte_length` | 32 | 8 | 8 | `u64` | - |
| `width` | 40 | 4 | 4 | `u32` | - |
| `height` | 44 | 4 | 4 | `u32` | - |
| `format` | 48 | 4 | 4 | `u32` | - |
| `usage` | 52 | 4 | 4 | `u32` | - |
| `layout` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |

### `GfxNativeStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `request` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `phase` | 24 | 4 | 4 | `u32` | - |
| `result` | 28 | 4 | 4 | `i32` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `deadline_ns` | 40 | 8 | 8 | `u64` | - |
| `completed_ns` | 48 | 8 | 8 | `u64` | - |

### `GfxNativeProvider`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `notify` | 24 | 8 | 8 | `u64` | - |
| `context` | 32 | 8 | 8 | `u64` | - |

### `GfxNativeJob`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `request` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `allocation` | 24 | 64 | 8 | `GfxNativeAllocation` | - |

### `GfxRenderRect`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `x` | 0 | 4 | 4 | `i32` | - |
| `y` | 4 | 4 | 4 | `i32` | - |
| `width` | 8 | 4 | 4 | `u32` | - |
| `height` | 12 | 4 | 4 | `u32` | - |

### `GfxRenderCommand`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 4 | 4 | `u32` | - |
| `filter` | 4 | 4 | 4 | `u32` | - |
| `blend` | 8 | 4 | 4 | `u32` | - |
| `transfer` | 12 | 4 | 4 | `u32` | - |
| `source_rect` | 16 | 16 | 4 | `GfxRenderRect` | - |
| `target_rect` | 32 | 16 | 4 | `GfxRenderRect` | - |
| `scissor` | 48 | 16 | 4 | `GfxRenderRect` | - |
| `color` | 64 | 4 | 4 | `u32` | - |
| `opacity` | 68 | 4 | 4 | `u32` | - |
| `reserved0` | 72 | 8 | 8 | `u64` | - |

### `GfxRenderList`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1296 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `count` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `commands` | 16 | 1280 | 8 | `[16]GfxRenderCommand` | - |

### `DisplayPresentationInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `head_id` | 12 | 4 | 4 | `u32` | - |
| `backend` | 16 | 32 | 8 | `GfxBackendBinding` | - |
| `display_generation` | 48 | 8 | 8 | `u64` | - |
| `sequence` | 56 | 8 | 8 | `u64` | - |
| `width` | 64 | 4 | 4 | `u32` | - |
| `height` | 68 | 4 | 4 | `u32` | - |
| `format` | 72 | 4 | 4 | `u32` | - |
| `policies` | 76 | 4 | 4 | `u32` | - |
| `buffer_count` | 80 | 4 | 4 | `u32` | - |
| `plane_count` | 84 | 4 | 4 | `u32` | - |
| `interval_ns` | 88 | 8 | 8 | `u64` | - |
| `observed_sequence` | 96 | 8 | 8 | `u64` | - |
| `observed_ns` | 104 | 8 | 8 | `u64` | - |
| `path` | 112 | 4 | 4 | `u32` | - |
| `reserved0` | 116 | 4 | 4 | `u32` | - |

### `GfxOutputTarget`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `connector_id` | 12 | 4 | 4 | `u32` | - |
| `device_generation` | 16 | 8 | 8 | `u64` | - |
| `connection_generation` | 24 | 8 | 8 | `u64` | - |
| `display_generation` | 32 | 8 | 8 | `u64` | - |
| `head_id` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |

### `GfxAdditionalOutput`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `backend` | 8 | 32 | 8 | `GfxBackendBinding` | - |
| `output` | 40 | 24 | 8 | `GfxOutputId` | - |
| `head_id` | 64 | 4 | 4 | `u32` | - |
| `width` | 68 | 4 | 4 | `u32` | - |
| `height` | 72 | 4 | 4 | `u32` | - |
| `format` | 76 | 4 | 4 | `u32` | - |
| `job_size` | 80 | 4 | 4 | `u32` | - |
| `flags` | 84 | 4 | 4 | `u32` | - |
| `reserved0` | 88 | 8 | 8 | `u64` | - |

### `MouseMotion`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `mouse` | 8 | 32 | 8 | `Mouse` | - |
| `motion_x` | 40 | 4 | 4 | `u32` | - |
| `motion_y` | 44 | 4 | 4 | `u32` | - |

### `DisplaySetting`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `adapter_id` | 0 | 8 | 8 | `u64` | - |
| `connector_id` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `receiver` | 16 | 16 | 1 | `[16]u8` | - |
| `x` | 32 | 4 | 4 | `i32` | - |
| `y` | 36 | 4 | 4 | `i32` | - |
| `width` | 40 | 4 | 4 | `u32` | - |
| `height` | 44 | 4 | 4 | `u32` | - |
| `scale` | 48 | 4 | 4 | `u32` | - |
| `rotation` | 52 | 4 | 4 | `u32` | - |
| `refresh_millihz` | 56 | 4 | 4 | `u32` | - |
| `clone_group` | 60 | 4 | 4 | `u32` | - |

### `DisplayLayout`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 536 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `topology_revision` | 8 | 8 | 8 | `u64` | - |
| `count` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |
| `outputs` | 24 | 512 | 8 | `[8]DisplaySetting` | - |

### `DisplayControlRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 600 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `owner` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `desktop_epoch` | 24 | 8 | 8 | `u64` | - |
| `request_id` | 32 | 8 | 8 | `u64` | - |
| `base_revision` | 40 | 8 | 8 | `u64` | - |
| `transaction_id` | 48 | 8 | 8 | `u64` | - |
| `action` | 56 | 4 | 4 | `u32` | - |
| `reserved` | 60 | 4 | 4 | `u32` | - |
| `layout` | 64 | 536 | 8 | `DisplayLayout` | - |

### `DisplayControlStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 616 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `desktop_epoch` | 8 | 8 | 8 | `u64` | - |
| `revision` | 16 | 8 | 8 | `u64` | - |
| `transaction_id` | 24 | 8 | 8 | `u64` | - |
| `request_id` | 32 | 8 | 8 | `u64` | - |
| `owner` | 40 | 16 | 8 | `ProgramProcessHandle` | - |
| `deadline_ns` | 56 | 8 | 8 | `u64` | - |
| `phase` | 64 | 4 | 4 | `u32` | - |
| `result` | 68 | 4 | 4 | `i32` | - |
| `flags` | 72 | 4 | 4 | `u32` | - |
| `reserved` | 76 | 4 | 4 | `u32` | - |
| `layout` | 80 | 536 | 8 | `DisplayLayout` | - |

### `DisplayControlExchange`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1248 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `desktop_owner` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |
| `status` | 32 | 616 | 8 | `DisplayControlStatus` | - |
| `request` | 648 | 600 | 8 | `DisplayControlRequest` | - |

### `GfxSampleGrid`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `enabled` | 0 | 4 | 4 | `u32` | - |
| `rotation` | 4 | 4 | 4 | `u32` | - |
| `scale` | 8 | 4 | 4 | `u32` | - |
| `pixel_width` | 12 | 4 | 4 | `u32` | - |
| `pixel_height` | 16 | 4 | 4 | `u32` | - |
| `target_x` | 20 | 4 | 4 | `i32` | - |
| `target_y` | 24 | 4 | 4 | `i32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |
| `viewport_x` | 32 | 4 | 4 | `i32` | - |
| `viewport_y` | 36 | 4 | 4 | `i32` | - |
| `viewport_width` | 40 | 4 | 4 | `u32` | - |
| `viewport_height` | 44 | 4 | 4 | `u32` | - |
| `guest_width` | 48 | 4 | 4 | `u32` | - |
| `guest_height` | 52 | 4 | 4 | `u32` | - |
| `source_x` | 56 | 4 | 4 | `u32` | - |
| `source_y` | 60 | 4 | 4 | `u32` | - |

### `GfxRenderGridList`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 2320 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `count` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `commands` | 16 | 1280 | 8 | `[16]GfxRenderCommand` | - |
| `grids` | 1296 | 1024 | 4 | `[16]GfxSampleGrid` | - |

### `GfxOutputColorState`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `revision` | 32 | 8 | 8 | `u64` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `format` | 44 | 4 | 4 | `u32` | - |
| `bpc` | 48 | 4 | 4 | `u32` | - |
| `primaries` | 52 | 4 | 4 | `u32` | - |
| `transfer` | 56 | 4 | 4 | `u32` | - |
| `range` | 60 | 4 | 4 | `u32` | - |
| `reference_white` | 64 | 4 | 4 | `u32` | - |
| `peak` | 68 | 4 | 4 | `u32` | - |
| `black` | 72 | 4 | 4 | `u32` | - |
| `formats` | 76 | 4 | 4 | `u32` | - |
| `depths` | 80 | 4 | 4 | `u32` | - |
| `color_spaces` | 84 | 4 | 4 | `u32` | - |
| `transfers` | 88 | 4 | 4 | `u32` | - |
| `ranges` | 92 | 4 | 4 | `u32` | - |
| `gamma_entries` | 96 | 4 | 4 | `u32` | - |
| `degamma_entries` | 100 | 4 | 4 | `u32` | - |
| `ctm_fraction_bits` | 104 | 4 | 4 | `u32` | - |
| `reserved0` | 108 | 4 | 4 | `u32` | - |
| `max_tmds_clock_hz` | 112 | 8 | 8 | `u64` | - |
| `dp_payload_bits_per_second` | 120 | 8 | 8 | `u64` | - |
| `link_kind` | 128 | 4 | 4 | `u32` | - |
| `link_flags` | 132 | 4 | 4 | `u32` | - |
| `dsc_depths` | 136 | 4 | 4 | `u32` | - |
| `max_frl_rate` | 140 | 4 | 4 | `u32` | - |
| `compressed_bpp_x16` | 144 | 4 | 4 | `u32` | - |
| `link_lanes` | 148 | 4 | 4 | `u32` | - |
| `link_rate_mbps` | 152 | 4 | 4 | `u32` | - |
| `h_active` | 156 | 4 | 4 | `u32` | - |
| `h_total` | 160 | 4 | 4 | `u32` | - |
| `reserved_link` | 164 | 4 | 4 | `u32` | - |
| `link_payload_bits_per_second` | 168 | 8 | 8 | `u64` | - |
| `pixel_clock_numerator` | 176 | 8 | 8 | `u64` | - |
| `pixel_clock_denominator` | 184 | 4 | 4 | `u32` | - |
| `v_active` | 188 | 4 | 4 | `u32` | - |

### `GfxRenderColorProgram`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 272 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `reserved0` | 8 | 8 | 8 | `u64` | - |
| `words` | 16 | 256 | 4 | `[64]u32` | - |

### `GfxRenderColorList`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1568 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `count` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `commands` | 16 | 1280 | 8 | `[16]GfxRenderCommand` | - |
| `program` | 1296 | 272 | 8 | `GfxRenderColorProgram` | - |

### `GfxHdrMetadata`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 2

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `primaries` | 0 | 12 | 2 | `[6]u16` | - |
| `white` | 12 | 4 | 2 | `[2]u16` | - |
| `max_mastering` | 16 | 2 | 2 | `u16` | - |
| `min_mastering` | 18 | 2 | 2 | `u16` | - |
| `max_cll` | 20 | 2 | 2 | `u16` | - |
| `max_fall` | 22 | 2 | 2 | `u16` | - |

### `GfxColorSignal`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `format` | 8 | 4 | 4 | `u32` | - |
| `bpc` | 12 | 4 | 4 | `u32` | - |
| `primaries` | 16 | 4 | 4 | `u32` | - |
| `transfer` | 20 | 4 | 4 | `u32` | - |
| `range` | 24 | 4 | 4 | `u32` | - |
| `pipeline` | 28 | 4 | 4 | `u32` | - |
| `reference_white` | 32 | 4 | 4 | `u32` | - |
| `peak` | 36 | 4 | 4 | `u32` | - |
| `black` | 40 | 4 | 4 | `u32` | - |
| `metadata_valid` | 44 | 4 | 4 | `u32` | - |
| `metadata` | 48 | 24 | 2 | `GfxHdrMetadata` | - |
| `reserved0` | 72 | 8 | 8 | `u64` | - |

### `GfxModeColorRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1344 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 1240 | 8 | `GfxAtomicState` | - |
| `signal` | 1248 | 80 | 8 | `GfxColorSignal` | - |
| `image` | 1328 | 16 | 8 | `GfxBufferHandle` | - |

### `GfxDriverModeColor`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 152 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `ticket` | 8 | 8 | 8 | `u64` | - |
| `sequence` | 16 | 8 | 8 | `u64` | - |
| `signal` | 24 | 80 | 8 | `GfxColorSignal` | - |
| `reference` | 104 | 48 | 8 | `GfxBufferReference` | - |

### `DisplayColorSelection`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `output` | 8 | 24 | 8 | `GfxOutputId` | - |
| `signal` | 32 | 80 | 8 | `GfxColorSignal` | - |

### `DisplayColorRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 712 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `base` | 0 | 600 | 8 | `DisplayControlRequest` | - |
| `color` | 600 | 112 | 8 | `DisplayColorSelection` | - |

### `DisplayColorExchange`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1360 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `base` | 0 | 1248 | 8 | `DisplayControlExchange` | - |
| `color` | 1248 | 112 | 8 | `DisplayColorSelection` | - |

### `GfxRefreshCapabilities`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `origin` | 12 | 4 | 4 | `u32` | - |
| `min_millihz` | 16 | 4 | 4 | `u32` | - |
| `max_millihz` | 20 | 4 | 4 | `u32` | - |
| `nominal_millihz` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `min_period_ns` | 32 | 8 | 8 | `u64` | - |
| `max_period_ns` | 40 | 8 | 8 | `u64` | - |
| `max_increase_ns` | 48 | 8 | 8 | `u64` | - |
| `max_decrease_ns` | 56 | 8 | 8 | `u64` | - |
| `max_vtotal` | 64 | 4 | 4 | `u32` | - |
| `reserved1` | 68 | 4 | 4 | `u32` | - |

### `GfxRefreshStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `sequence` | 8 | 8 | 8 | `u64` | - |
| `request_sequence` | 16 | 8 | 8 | `u64` | - |
| `phase` | 24 | 4 | 4 | `u32` | - |
| `reason` | 28 | 4 | 4 | `u32` | - |
| `policy` | 32 | 4 | 4 | `u32` | - |
| `scene` | 36 | 4 | 4 | `u32` | - |
| `core_point` | 40 | 8 | 8 | `u64` | - |
| `receipt` | 48 | 8 | 8 | `u64` | - |
| `since_ns` | 56 | 8 | 8 | `u64` | - |

### `GfxRefreshMeasure`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `sequence` | 8 | 8 | 8 | `u64` | - |
| `samples` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `observed_ns` | 24 | 8 | 8 | `u64` | - |
| `last_period_ns` | 32 | 8 | 8 | `u64` | - |
| `min_period_ns` | 40 | 8 | 8 | `u64` | - |
| `max_period_ns` | 48 | 8 | 8 | `u64` | - |
| `mean_period_ns` | 56 | 8 | 8 | `u64` | - |
| `millihz` | 64 | 4 | 4 | `u32` | - |
| `gaps` | 68 | 4 | 4 | `u32` | - |
| `reserved1` | 72 | 8 | 8 | `u64` | - |

### `GfxOutputRefresh`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 272 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `target` | 8 | 48 | 8 | `GfxOutputTarget` | - |
| `capabilities` | 56 | 72 | 8 | `GfxRefreshCapabilities` | - |
| `status` | 128 | 64 | 8 | `GfxRefreshStatus` | - |
| `measured` | 192 | 80 | 8 | `GfxRefreshMeasure` | - |

### `GfxRefreshRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `target` | 8 | 48 | 8 | `GfxOutputTarget` | - |
| `operation` | 56 | 4 | 4 | `u32` | - |
| `policy` | 60 | 4 | 4 | `u32` | - |
| `scene` | 64 | 4 | 4 | `u32` | - |
| `reserved0` | 68 | 4 | 4 | `u32` | - |
| `sequence` | 72 | 8 | 8 | `u64` | - |
| `deadline_ns` | 80 | 8 | 8 | `u64` | - |

### `GfxDeviceBudgetRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `operation` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `limit_bytes` | 24 | 8 | 8 | `u64` | - |

### `GfxDeviceBudgetState`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `limit_bytes` | 24 | 8 | 8 | `u64` | - |
| `charged_bytes` | 32 | 8 | 8 | `u64` | - |
| `shared_limit_bytes` | 40 | 8 | 8 | `u64` | - |
| `shared_charged_bytes` | 48 | 8 | 8 | `u64` | - |
| `shared_producer_limit_bytes` | 56 | 8 | 8 | `u64` | - |

### `GfxTelemetryMetric`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `status` | 0 | 4 | 4 | `u32` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `source_stamp` | 8 | 8 | 8 | `u64` | - |
| `values` | 16 | 32 | 8 | `[4]i64` | - |

### `GfxTelemetryRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `metric_mask` | 24 | 8 | 8 | `u64` | - |

### `GfxTelemetryDemand`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `until_ns` | 24 | 8 | 8 | `u64` | - |
| `metric_mask` | 32 | 8 | 8 | `u64` | - |

### `GfxTelemetryState`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 544 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `adapter_id` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `memory_generation` | 16 | 8 | 8 | `u64` | - |
| `sampled_ns` | 24 | 8 | 8 | `u64` | - |
| `valid_until_ns` | 32 | 8 | 8 | `u64` | - |
| `source` | 40 | 4 | 4 | `u32` | - |
| `state` | 44 | 4 | 4 | `u32` | - |
| `policy` | 48 | 4 | 4 | `u32` | - |
| `boost` | 52 | 4 | 4 | `u32` | - |
| `control_status` | 56 | 4 | 4 | `u32` | - |
| `reserved1` | 60 | 4 | 4 | `u32` | - |
| `metrics` | 64 | 480 | 8 | `[10]GfxTelemetryMetric` | - |

### `GfxOutputPower`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `capabilities` | 32 | 4 | 4 | `u32` | - |
| `phase` | 36 | 4 | 4 | `u32` | - |
| `sequence` | 40 | 8 | 8 | `u64` | - |
| `request_sequence` | 48 | 8 | 8 | `u64` | - |
| `since_ns` | 56 | 8 | 8 | `u64` | - |
| `control_receipt` | 64 | 8 | 8 | `u64` | - |
| `core_point` | 72 | 8 | 8 | `u64` | - |
| `window_point` | 80 | 8 | 8 | `u64` | - |
| `reason` | 88 | 4 | 4 | `u32` | - |
| `reserved0` | 92 | 4 | 4 | `u32` | - |

### `GfxPowerRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `off` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `sequence` | 40 | 8 | 8 | `u64` | - |
| `deadline_ns` | 48 | 8 | 8 | `u64` | - |
| `reserved1` | 56 | 8 | 8 | `u64` | - |

### `RemoteFrameLease`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `id` | 8 | 8 | 8 | `u64` | - |
| `pixels_addr` | 16 | 8 | 8 | `u64` | - |
| `capacity_pixels` | 24 | 8 | 8 | `u64` | - |
| `epoch` | 32 | 8 | 8 | `u64` | - |
| `acquired_ns` | 40 | 8 | 8 | `u64` | - |

### `RemoteFrameCaptureStats`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `consumers` | 8 | 4 | 4 | `u32` | - |
| `leases` | 12 | 4 | 4 | `u32` | - |
| `snapshots` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |
| `epoch` | 24 | 8 | 8 | `u64` | - |
| `revision` | 32 | 8 | 8 | `u64` | - |
| `live_bytes` | 40 | 8 | 8 | `u64` | - |
| `snapshot_bytes` | 48 | 8 | 8 | `u64` | - |
| `published_bytes` | 56 | 8 | 8 | `u64` | - |
| `snapshot_copy_bytes` | 64 | 8 | 8 | `u64` | - |
| `acquires` | 72 | 8 | 8 | `u64` | - |
| `misses` | 80 | 8 | 8 | `u64` | - |
| `max_reader_ns` | 88 | 8 | 8 | `u64` | - |

### `GfxVirtualRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `adapter_id` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `memory_generation` | 24 | 8 | 8 | `u64` | - |
| `parent` | 32 | 16 | 8 | `GfxBufferHandle` | - |
| `reference` | 48 | 16 | 8 | `GfxBufferHandle` | - |
| `byte_offset` | 64 | 8 | 8 | `u64` | - |
| `virtual_offset` | 72 | 8 | 8 | `u64` | - |
| `byte_length` | 80 | 8 | 8 | `u64` | - |
| `alignment` | 88 | 8 | 8 | `u64` | - |
| `fixed_address` | 96 | 8 | 8 | `u64` | - |
| `deadline_ns` | 104 | 8 | 8 | `u64` | - |
| `location` | 112 | 4 | 4 | `u32` | - |
| `reserved1` | 116 | 4 | 4 | `u32` | - |

### `GfxVirtualStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `resource` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `parent` | 24 | 16 | 8 | `GfxBufferHandle` | - |
| `kind` | 40 | 4 | 4 | `u32` | - |
| `flags` | 44 | 4 | 4 | `u32` | - |
| `result` | 48 | 4 | 4 | `i32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `address` | 56 | 8 | 8 | `u64` | - |
| `byte_length` | 64 | 8 | 8 | `u64` | - |
| `deadline_ns` | 72 | 8 | 8 | `u64` | - |

### `GfxVirtualToken`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `opaque0` | 0 | 8 | 8 | `u64` | - |
| `opaque1` | 8 | 8 | 8 | `u64` | - |
| `opaque2` | 16 | 8 | 8 | `u64` | - |

### `GfxVirtualJob`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 248 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `resource` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `operation` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `request` | 32 | 120 | 8 | `GfxVirtualRequest` | - |
| `parent_token` | 152 | 24 | 8 | `GfxVirtualToken` | - |
| `token` | 176 | 24 | 8 | `GfxVirtualToken` | - |
| `reference` | 200 | 48 | 8 | `GfxBufferReference` | - |

### `GfxVirtualCompletion`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `resource` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `operation` | 24 | 4 | 4 | `u32` | - |
| `result` | 28 | 4 | 4 | `i32` | - |
| `token` | 32 | 24 | 8 | `GfxVirtualToken` | - |
| `address` | 56 | 8 | 8 | `u64` | - |

### `GfxBackendProperties`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 288 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `interface_id_lo` | 8 | 8 | 8 | `u64` | - |
| `interface_id_hi` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 4 | 4 | `u32` | - |
| `data_bytes` | 28 | 4 | 4 | `u32` | - |
| `data` | 32 | 256 | 1 | `[256]u8` | - |

### `GfxNativeSubmission`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `interface_id_lo` | 8 | 8 | 8 | `u64` | - |
| `interface_id_hi` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 4 | 4 | `u32` | - |
| `command_bytes` | 28 | 4 | 4 | `u32` | - |
| `resource_count` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `commands` | 40 | 8 | 8 | `u64` | - |
| `resources` | 48 | 8 | 8 | `u64` | - |

### `GfxNativeResource`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `binding` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `access` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `GfxNativeJobInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `interface_id_lo` | 8 | 8 | 8 | `u64` | - |
| `interface_id_hi` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 4 | 4 | `u32` | - |
| `command_bytes` | 28 | 4 | 4 | `u32` | - |
| `resource_count` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |

### `GfxNativeBinding`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `binding` | 8 | 16 | 8 | `GfxBufferHandle` | - |
| `token` | 24 | 24 | 8 | `GfxVirtualToken` | - |
| `address` | 48 | 8 | 8 | `u64` | - |
| `byte_length` | 56 | 8 | 8 | `u64` | - |
| `access` | 64 | 4 | 4 | `u32` | - |
| `reserved0` | 68 | 4 | 4 | `u32` | - |

### `GfxQueueOwnerInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `timeline` | 8 | 8 | 8 | `u64` | - |
| `producer_kind` | 16 | 4 | 4 | `u32` | - |
| `closing` | 20 | 4 | 4 | `u32` | - |
| `producer_id` | 24 | 8 | 8 | `u64` | - |
| `producer_generation` | 32 | 8 | 8 | `u64` | - |
| `inflight_jobs` | 40 | 4 | 4 | `u32` | - |
| `retained_jobs` | 44 | 4 | 4 | `u32` | - |

### `WindowGraphicsSurface`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `service` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `desktop` | 24 | 16 | 8 | `ProgramProcessHandle` | - |
| `owner` | 40 | 16 | 8 | `ProgramProcessHandle` | - |
| `window_id` | 56 | 4 | 4 | `u32` | - |
| `reserved` | 60 | 4 | 4 | `u32` | - |
| `serial` | 64 | 8 | 8 | `u64` | - |

### `WindowGraphicsFormat`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `format` | 0 | 4 | 4 | `u32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `color` | 8 | 48 | 1 | `[48]u8` | - |

### `WindowGraphicsConfig`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 680 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `revision` | 8 | 8 | 8 | `u64` | - |
| `width` | 16 | 4 | 4 | `u32` | - |
| `height` | 20 | 4 | 4 | `u32` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `present_modes` | 28 | 4 | 4 | `u32` | - |
| `min_images` | 32 | 4 | 4 | `u32` | - |
| `max_images` | 36 | 4 | 4 | `u32` | - |
| `format_count` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |
| `backend` | 48 | 152 | 8 | `GfxBackendInfo` | - |
| `output` | 200 | 24 | 8 | `GfxOutputId` | - |
| `display_generation` | 224 | 8 | 8 | `u64` | - |
| `formats` | 232 | 448 | 4 | `[8]WindowGraphicsFormat` | - |

### `WindowGraphicsPublication`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 800 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `desktop` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `owner` | 24 | 16 | 8 | `ProgramProcessHandle` | - |
| `window_id` | 40 | 4 | 4 | `u32` | - |
| `action` | 44 | 4 | 4 | `u32` | - |
| `surface` | 48 | 72 | 8 | `WindowGraphicsSurface` | - |
| `config` | 120 | 680 | 8 | `WindowGraphicsConfig` | - |

### `WindowGraphicsRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 208 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `owner` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `action` | 24 | 4 | 4 | `u32` | - |
| `window_id` | 28 | 4 | 4 | `u32` | - |
| `surface` | 32 | 72 | 8 | `WindowGraphicsSurface` | - |
| `chain` | 104 | 8 | 8 | `u64` | - |
| `request_serial` | 112 | 8 | 8 | `u64` | - |
| `config_revision` | 120 | 8 | 8 | `u64` | - |
| `image_count` | 128 | 4 | 4 | `u32` | - |
| `image_slot` | 132 | 4 | 4 | `u32` | - |
| `format_index` | 136 | 4 | 4 | `u32` | - |
| `present_mode` | 140 | 4 | 4 | `u32` | - |
| `acquire_token` | 144 | 8 | 8 | `u64` | - |
| `source` | 152 | 16 | 8 | `GfxBufferHandle` | - |
| `fence` | 168 | 40 | 8 | `GfxFence` | - |

### `WindowGraphicsFrame`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 408 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `surface` | 8 | 72 | 8 | `WindowGraphicsSurface` | - |
| `chain` | 80 | 8 | 8 | `u64` | - |
| `config_revision` | 88 | 8 | 8 | `u64` | - |
| `image_slot` | 96 | 4 | 4 | `u32` | - |
| `flags` | 100 | 4 | 4 | `u32` | - |
| `acquire_token` | 104 | 8 | 8 | `u64` | - |
| `present_serial` | 112 | 8 | 8 | `u64` | - |
| `source` | 120 | 48 | 8 | `GfxBufferReference` | - |
| `descriptor` | 168 | 144 | 8 | `GfxBufferDescriptor` | - |
| `format` | 312 | 56 | 4 | `WindowGraphicsFormat` | - |
| `ready` | 368 | 40 | 8 | `GfxFence` | - |

### `WindowGraphicsReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1248 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `result` | 8 | 4 | 4 | `i32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `revision` | 16 | 8 | 8 | `u64` | - |
| `surface` | 24 | 72 | 8 | `WindowGraphicsSurface` | - |
| `chain` | 96 | 8 | 8 | `u64` | - |
| `image_slot` | 104 | 4 | 4 | `u32` | - |
| `reserved` | 108 | 4 | 4 | `u32` | - |
| `acquire_token` | 112 | 8 | 8 | `u64` | - |
| `wait_fence` | 120 | 40 | 8 | `GfxFence` | - |
| `config` | 160 | 680 | 8 | `WindowGraphicsConfig` | - |
| `frame` | 840 | 408 | 8 | `WindowGraphicsFrame` | - |

### `WindowGraphicsConsumer`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `desktop` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `action` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |
| `surface` | 32 | 72 | 8 | `WindowGraphicsSurface` | - |
| `chain` | 104 | 8 | 8 | `u64` | - |
| `image_slot` | 112 | 4 | 4 | `u32` | - |
| `result` | 116 | 4 | 4 | `i32` | - |
| `acquire_token` | 120 | 8 | 8 | `u64` | - |
| `fence` | 128 | 40 | 8 | `GfxFence` | - |
| `request_serial` | 168 | 8 | 8 | `u64` | - |

### `WindowGraphicsWait`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `owner` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `known_revision` | 24 | 8 | 8 | `u64` | - |
| `deadline_tick` | 32 | 8 | 8 | `u64` | - |

### `GfxRenderColorGridList`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 2592 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `count` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `commands` | 16 | 1280 | 8 | `[16]GfxRenderCommand` | - |
| `program` | 1296 | 272 | 8 | `GfxRenderColorProgram` | - |
| `grids` | 1568 | 1024 | 4 | `[16]GfxSampleGrid` | - |

### `CpuCapacity`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `available_cpus` | 0 | 4 | 4 | `u32` | - |
| `configured_cpus` | 4 | 4 | 4 | `u32` | - |

### `WindowModeIdentity`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `service` | 0 | 16 | 8 | `ProgramProcessHandle` | - |
| `desktop` | 16 | 16 | 8 | `ProgramProcessHandle` | - |
| `owner` | 32 | 16 | 8 | `ProgramProcessHandle` | - |
| `serial` | 48 | 8 | 8 | `u64` | - |
| `window_id` | 56 | 4 | 4 | `u32` | - |
| `reserved` | 60 | 4 | 4 | `u32` | - |

### `WindowModeRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 64 | 8 | `WindowModeIdentity` | - |
| `request_id` | 72 | 8 | 8 | `u64` | - |
| `action` | 80 | 4 | 4 | `u32` | - |
| `mode` | 84 | 4 | 4 | `u32` | - |

### `WindowModeReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 64 | 8 | `WindowModeIdentity` | - |
| `request_id` | 72 | 8 | 8 | `u64` | - |
| `result` | 80 | 4 | 4 | `i32` | - |
| `phase` | 84 | 4 | 4 | `u32` | - |
| `mode` | 88 | 4 | 4 | `u32` | - |
| `requested_mode` | 92 | 4 | 4 | `u32` | - |

### `WindowModeExchange`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 64 | 8 | `WindowModeIdentity` | - |
| `ack_request_id` | 72 | 8 | 8 | `u64` | - |
| `ack_result` | 80 | 4 | 4 | `i32` | - |
| `mode` | 84 | 4 | 4 | `u32` | - |
| `flags` | 88 | 4 | 4 | `u32` | - |
| `reserved` | 92 | 4 | 4 | `u32` | - |

### `DriverModuleInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `owner` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `module_generation` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |
| `driver_name` | 32 | 32 | 1 | `[32]u8` | - |
| `module_version` | 64 | 32 | 1 | `[32]u8` | - |
| `firmware_version` | 96 | 32 | 1 | `[32]u8` | - |

### `GfxOutputBrightness`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `path` | 32 | 4 | 4 | `u32` | - |
| `phase` | 36 | 4 | 4 | `u32` | - |
| `minimum` | 40 | 4 | 4 | `u32` | - |
| `maximum` | 44 | 4 | 4 | `u32` | - |
| `current` | 48 | 4 | 4 | `u32` | - |
| `flags` | 52 | 4 | 4 | `u32` | - |
| `reason` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |
| `sequence` | 64 | 8 | 8 | `u64` | - |
| `request_sequence` | 72 | 8 | 8 | `u64` | - |
| `since_ns` | 80 | 8 | 8 | `u64` | - |

### `GfxBrightnessRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 24 | 8 | `GfxOutputId` | - |
| `level` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `sequence` | 40 | 8 | 8 | `u64` | - |

### `PlatformInputSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `sequence` | 8 | 8 | 8 | `u64` | - |
| `brightness_up` | 16 | 8 | 8 | `u64` | - |
| `brightness_down` | 24 | 8 | 8 | `u64` | - |
| `lid_sequence` | 32 | 8 | 8 | `u64` | - |
| `lid_state` | 40 | 4 | 4 | `u32` | - |
| `capabilities` | 44 | 4 | 4 | `u32` | - |
| `sources` | 48 | 4 | 4 | `u32` | - |
| `reserved` | 52 | 4 | 4 | `u32` | - |
| `since_ns` | 56 | 8 | 8 | `u64` | - |

### `DriverPlatformApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `rsdp` | 8 | 8 | 8 | `u64` | - |
| `physical_view` | 16 | 8 | 8 | `u64` | - |
| `input_submit` | 24 | 8 | 8 | `u64` | - |

### `HidConsumerOp`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `summary_address` | 8 | 8 | 8 | `u64` | - |
| `report_len` | 16 | 4 | 4 | `u32` | - |
| `report_id` | 20 | 4 | 4 | `u32` | - |
| `capabilities` | 24 | 4 | 4 | `u32` | - |
| `pressed` | 28 | 4 | 4 | `u32` | - |
| `report` | 32 | 32 | 1 | `[32]u8` | - |

### `DirectoryScanCursor`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1088 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `change` | 8 | 40 | 8 | `DirectoryChangeCursor` | - |
| `owner_id` | 48 | 4 | 4 | `u32` | - |
| `owner_kind` | 52 | 4 | 4 | `u32` | - |
| `owner_generation` | 56 | 8 | 8 | `u64` | - |
| `backend` | 64 | 1024 | 8 | `[128]u64` | - |

### `ProgramInstrumentationInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `mode` | 8 | 4 | 4 | `u32` | - |
| `service_lock_stride` | 12 | 4 | 4 | `u32` | - |
| `work_critical_stride` | 16 | 4 | 4 | `u32` | - |
| `lock_count` | 20 | 4 | 4 | `u32` | - |
| `stack_group_count` | 24 | 4 | 4 | `u32` | - |
| `clock_source` | 28 | 4 | 4 | `u32` | - |
| `clock_generation` | 32 | 4 | 4 | `u32` | - |
| `clock_flags` | 36 | 4 | 4 | `u32` | - |
| `clock_resolution_ns` | 40 | 8 | 8 | `u64` | - |

### `ProgramLockPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `name` | 16 | 32 | 1 | `[32]u8` | - |
| `acquisitions` | 48 | 8 | 8 | `u64` | - |
| `nested_acquisitions` | 56 | 8 | 8 | `u64` | - |
| `collisions` | 64 | 8 | 8 | `u64` | - |
| `cpu_collisions` | 72 | 8 | 8 | `u64` | - |
| `wait_spins` | 80 | 8 | 8 | `u64` | - |
| `max_wait_spins` | 88 | 8 | 8 | `u64` | - |
| `hold_cycles` | 96 | 8 | 8 | `u64` | - |
| `max_hold_cycles` | 104 | 8 | 8 | `u64` | - |
| `order_violations` | 112 | 8 | 8 | `u64` | - |

### `ProgramStackPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `index` | 8 | 4 | 4 | `u32` | - |
| `kind` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |
| `name` | 24 | 32 | 1 | `[32]u8` | - |
| `created` | 56 | 8 | 8 | `u64` | - |
| `released` | 64 | 8 | 8 | `u64` | - |
| `reserve_max_bytes` | 72 | 8 | 8 | `u64` | - |
| `initial_commit_max_bytes` | 80 | 8 | 8 | `u64` | - |
| `committed_max_bytes` | 88 | 8 | 8 | `u64` | - |
| `high_water_total_bytes` | 96 | 8 | 8 | `u64` | - |
| `high_water_max_bytes` | 104 | 8 | 8 | `u64` | - |
| `create_cycles_total` | 112 | 8 | 8 | `u64` | - |
| `create_cycles_max` | 120 | 8 | 8 | `u64` | - |
| `release_cycles_total` | 128 | 8 | 8 | `u64` | - |
| `release_cycles_max` | 136 | 8 | 8 | `u64` | - |

### `ProgramStackFaultInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `sequence` | 16 | 8 | 8 | `u64` | - |
| `stack_kind` | 24 | 4 | 4 | `u32` | - |
| `reason` | 28 | 4 | 4 | `u32` | - |
| `vm_error` | 32 | 4 | 4 | `u32` | - |
| `exception_vector` | 36 | 4 | 4 | `u32` | - |
| `task_id` | 40 | 4 | 4 | `u32` | - |
| `instance_id` | 44 | 4 | 4 | `u32` | - |
| `thread_id` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `task_generation` | 56 | 8 | 8 | `u64` | - |
| `instance_generation` | 64 | 8 | 8 | `u64` | - |
| `thread_generation` | 72 | 8 | 8 | `u64` | - |
| `fault_address` | 80 | 8 | 8 | `u64` | - |
| `interrupted_rsp` | 88 | 8 | 8 | `u64` | - |
| `page_fault_error` | 96 | 8 | 8 | `u64` | - |
| `reserve_base` | 104 | 8 | 8 | `u64` | - |
| `reserve_bytes` | 112 | 8 | 8 | `u64` | - |
| `committed_base` | 120 | 8 | 8 | `u64` | - |
| `committed_bytes` | 128 | 8 | 8 | `u64` | - |
| `guard_base` | 136 | 8 | 8 | `u64` | - |
| `guard_bytes` | 144 | 8 | 8 | `u64` | - |
| `stack_top` | 152 | 8 | 8 | `u64` | - |
| `image_base` | 160 | 8 | 8 | `u64` | - |
| `image_bytes` | 168 | 8 | 8 | `u64` | - |
| `memory_tag` | 176 | 16 | 1 | `[16]u8` | - |

### `ProgramKernelHeapCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `cases_completed` | 16 | 4 | 4 | `u32` | - |
| `failed_case` | 20 | 4 | 4 | `u32` | - |
| `churn_ops` | 24 | 4 | 4 | `u32` | - |
| `acceptance_iterations` | 28 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `run_id` | 40 | 8 | 8 | `u64` | - |
| `before_used_bytes` | 48 | 8 | 8 | `u64` | - |
| `after_used_bytes` | 56 | 8 | 8 | `u64` | - |
| `before_active_blocks` | 64 | 8 | 8 | `u64` | - |
| `after_active_blocks` | 72 | 8 | 8 | `u64` | - |
| `owned_allocations` | 80 | 8 | 8 | `u64` | - |
| `owned_releases` | 88 | 8 | 8 | `u64` | - |
| `owned_live_blocks` | 96 | 8 | 8 | `u64` | - |
| `owned_live_bytes` | 104 | 8 | 8 | `u64` | - |
| `peak_owned_bytes` | 112 | 8 | 8 | `u64` | - |
| `owned_allocation_bytes` | 120 | 8 | 8 | `u64` | - |
| `expected_double_free_errors` | 128 | 8 | 8 | `u64` | - |
| `expected_vm_errors` | 136 | 8 | 8 | `u64` | - |
| `vm_reservations` | 144 | 8 | 8 | `u64` | - |
| `vm_releases` | 152 | 8 | 8 | `u64` | - |
| `vm_live_reservations` | 160 | 8 | 8 | `u64` | - |

### `ProgramKernelSchedulerCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `selected` | 12 | 4 | 4 | `u32` | - |
| `passed` | 16 | 4 | 4 | `u32` | - |
| `failed` | 20 | 4 | 4 | `u32` | - |
| `unavailable` | 24 | 4 | 4 | `u32` | - |
| `isolated` | 28 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 32 | 4 | 4 | `u32` | - |
| `live_tasks` | 36 | 4 | 4 | `u32` | - |
| `live_work` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |
| `run_id` | 48 | 8 | 8 | `u64` | - |
| `tasks_created` | 56 | 8 | 8 | `u64` | - |
| `tasks_reaped` | 64 | 8 | 8 | `u64` | - |
| `work_submitted` | 72 | 8 | 8 | `u64` | - |
| `work_released` | 80 | 8 | 8 | `u64` | - |
| `event_iterations` | 88 | 8 | 8 | `u64` | - |
| `if_checks` | 96 | 8 | 8 | `u64` | - |
| `deadline_tasks` | 104 | 8 | 8 | `u64` | - |
| `role_mask` | 112 | 8 | 8 | `u64` | - |
| `unwind_checks` | 120 | 8 | 8 | `u64` | - |

### `ProgramKernelSmpCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 224 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `online_count` | 16 | 4 | 4 | `u32` | - |
| `fail_stage` | 20 | 4 | 4 | `u32` | - |
| `worker_failures` | 24 | 4 | 4 | `u32` | - |
| `clock_regressions` | 28 | 4 | 4 | `u32` | - |
| `tlb_failures` | 32 | 4 | 4 | `u32` | - |
| `owner_failures` | 36 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 40 | 4 | 4 | `u32` | - |
| `isolated_mask` | 44 | 4 | 4 | `u32` | - |
| `clock_source` | 48 | 4 | 4 | `u32` | - |
| `clock_generation` | 52 | 4 | 4 | `u32` | - |
| `run_id` | 56 | 8 | 8 | `u64` | - |
| `online_mask` | 64 | 8 | 8 | `u64` | - |
| `placement_mask` | 72 | 8 | 8 | `u64` | - |
| `observed_mask` | 80 | 8 | 8 | `u64` | - |
| `tlb_ready_mask` | 88 | 8 | 8 | `u64` | - |
| `tlb_updated_mask` | 96 | 8 | 8 | `u64` | - |
| `owner_done_mask` | 104 | 8 | 8 | `u64` | - |
| `expected_checksum` | 112 | 8 | 8 | `u64` | - |
| `actual_checksum` | 120 | 8 | 8 | `u64` | - |
| `tlb_generation` | 128 | 8 | 8 | `u64` | - |
| `tlb_target_mask` | 136 | 8 | 8 | `u64` | - |
| `tlb_acknowledgement_mask` | 144 | 8 | 8 | `u64` | - |
| `tlb_offline_mask` | 152 | 8 | 8 | `u64` | - |
| `clock_registered_mask` | 160 | 8 | 8 | `u64` | - |
| `tasks_created` | 168 | 8 | 8 | `u64` | - |
| `tasks_reaped` | 176 | 8 | 8 | `u64` | - |
| `retained_task_count` | 184 | 8 | 8 | `u64` | - |
| `retained_frame_count` | 192 | 8 | 8 | `u64` | - |
| `retained_allocation_count` | 200 | 8 | 8 | `u64` | - |
| `mutex_operations` | 208 | 8 | 8 | `u64` | - |
| `retained_range_count` | 216 | 8 | 8 | `u64` | - |

### `ProgramSmpTlbSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 184 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `online_count` | 12 | 4 | 4 | `u32` | - |
| `schedulable_count` | 16 | 4 | 4 | `u32` | - |
| `clock_source` | 20 | 4 | 4 | `u32` | - |
| `clock_generation` | 24 | 4 | 4 | `u32` | - |
| `clock_flags` | 28 | 4 | 4 | `u32` | - |
| `clock_fallback_reason` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `online_mask` | 40 | 8 | 8 | `u64` | - |
| `schedulable_mask` | 48 | 8 | 8 | `u64` | - |
| `clock_registered_mask` | 56 | 8 | 8 | `u64` | - |
| `clock_frequency_hz` | 64 | 8 | 8 | `u64` | - |
| `clock_resolution_ns` | 72 | 8 | 8 | `u64` | - |
| `max_cpu_skew_ns` | 80 | 8 | 8 | `u64` | - |
| `calibration_error_ppm` | 88 | 8 | 8 | `u64` | - |
| `tlb_requests` | 96 | 8 | 8 | `u64` | - |
| `tlb_successes` | 104 | 8 | 8 | `u64` | - |
| `tlb_timeouts` | 112 | 8 | 8 | `u64` | - |
| `tlb_expected_timeouts` | 120 | 8 | 8 | `u64` | - |
| `tlb_ipis_sent` | 128 | 8 | 8 | `u64` | - |
| `tlb_acknowledgements` | 136 | 8 | 8 | `u64` | - |
| `tlb_offline_exclusions` | 144 | 8 | 8 | `u64` | - |
| `tlb_local_page_flushes` | 152 | 8 | 8 | `u64` | - |
| `tlb_local_full_reloads` | 160 | 8 | 8 | `u64` | - |
| `tlb_max_wait_spins` | 168 | 8 | 8 | `u64` | - |
| `tlb_generation` | 176 | 8 | 8 | `u64` | - |

### `ProgramKernelBlockQueueCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 240 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `selected_cases` | 16 | 4 | 4 | `u32` | - |
| `passed_cases` | 20 | 4 | 4 | `u32` | - |
| `failed_cases` | 24 | 4 | 4 | `u32` | - |
| `attempted_cases` | 28 | 4 | 4 | `u32` | - |
| `unavailable_cases` | 32 | 4 | 4 | `u32` | - |
| `fail_stage` | 36 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 40 | 4 | 4 | `u32` | - |
| `duplicate_disposition` | 44 | 4 | 4 | `u32` | - |
| `run_id` | 48 | 8 | 8 | `u64` | - |
| `tasks_created` | 56 | 8 | 8 | `u64` | - |
| `tasks_reaped` | 64 | 8 | 8 | `u64` | - |
| `retained_task_count` | 72 | 8 | 8 | `u64` | - |
| `controllers_registered` | 80 | 8 | 8 | `u64` | - |
| `controllers_unregistered` | 88 | 8 | 8 | `u64` | - |
| `retained_controller_count` | 96 | 8 | 8 | `u64` | - |
| `async_submissions` | 104 | 8 | 8 | `u64` | - |
| `async_completions` | 112 | 8 | 8 | `u64` | - |
| `completion_receipts` | 120 | 8 | 8 | `u64` | - |
| `duplicate_rejections` | 128 | 8 | 8 | `u64` | - |
| `late_rejections` | 136 | 8 | 8 | `u64` | - |
| `cancel_requests` | 144 | 8 | 8 | `u64` | - |
| `timeout_cancels` | 152 | 8 | 8 | `u64` | - |
| `reset_cancels` | 160 | 8 | 8 | `u64` | - |
| `resets` | 168 | 8 | 8 | `u64` | - |
| `read_ops` | 176 | 8 | 8 | `u64` | - |
| `write_ops` | 184 | 8 | 8 | `u64` | - |
| `flush_ops` | 192 | 8 | 8 | `u64` | - |
| `queue_high_water` | 200 | 8 | 8 | `u64` | - |
| `in_flight_high_water` | 208 | 8 | 8 | `u64` | - |
| `parallel_active_max` | 216 | 8 | 8 | `u64` | - |
| `retained_request_count` | 224 | 8 | 8 | `u64` | - |
| `retained_buffer_count` | 232 | 8 | 8 | `u64` | - |

### `ProgramKernelNvmeCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 296 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `unavailable_reason` | 16 | 4 | 4 | `u32` | - |
| `fail_stage` | 20 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 24 | 4 | 4 | `u32` | - |
| `sector_size` | 28 | 4 | 4 | `u32` | - |
| `device_slot` | 32 | 4 | 4 | `u32` | - |
| `native_receipt_flags` | 36 | 4 | 4 | `u32` | - |
| `observation_flags` | 40 | 4 | 4 | `u32` | - |
| `controller_index` | 44 | 4 | 4 | `u32` | - |
| `controller_generation` | 48 | 4 | 4 | `u32` | - |
| `namespace_generation` | 52 | 4 | 4 | `u32` | - |
| `namespace_id` | 56 | 4 | 4 | `u32` | - |
| `namespace_slot` | 60 | 4 | 4 | `u32` | - |
| `queue_id` | 64 | 4 | 4 | `u32` | - |
| `command_id` | 68 | 4 | 4 | `u32` | - |
| `hardware_status` | 72 | 4 | 4 | `u32` | - |
| `driver_result` | 76 | 4 | 4 | `i32` | - |
| `completed_bytes` | 80 | 4 | 4 | `u32` | - |
| `irq_mode` | 84 | 4 | 4 | `u32` | - |
| `driver_state_before` | 88 | 4 | 4 | `u32` | - |
| `driver_state_after` | 92 | 4 | 4 | `u32` | - |
| `run_id` | 96 | 8 | 8 | `u64` | - |
| `device_generation` | 104 | 8 | 8 | `u64` | - |
| `request_id` | 112 | 8 | 8 | `u64` | - |
| `backend_handle` | 120 | 8 | 8 | `u64` | - |
| `observed_handle` | 128 | 8 | 8 | `u64` | - |
| `irq_generation` | 136 | 8 | 8 | `u64` | - |
| `work_sequence` | 144 | 8 | 8 | `u64` | - |
| `command_sequence` | 152 | 8 | 8 | `u64` | - |
| `start_tick` | 160 | 8 | 8 | `u64` | - |
| `finish_tick` | 168 | 8 | 8 | `u64` | - |
| `data_checksum` | 176 | 8 | 8 | `u64` | - |
| `tasks_created` | 184 | 8 | 8 | `u64` | - |
| `tasks_reaped` | 192 | 8 | 8 | `u64` | - |
| `retained_task_count` | 200 | 8 | 8 | `u64` | - |
| `retained_device_pin_count` | 208 | 8 | 8 | `u64` | - |
| `retained_buffer_count` | 216 | 8 | 8 | `u64` | - |
| `callback_count` | 224 | 8 | 8 | `u64` | - |
| `worker_requests_before` | 232 | 8 | 8 | `u64` | - |
| `worker_requests_after` | 240 | 8 | 8 | `u64` | - |
| `worker_completions_before` | 248 | 8 | 8 | `u64` | - |
| `worker_completions_after` | 256 | 8 | 8 | `u64` | - |
| `async_submissions_before` | 264 | 8 | 8 | `u64` | - |
| `async_submissions_after` | 272 | 8 | 8 | `u64` | - |
| `async_completions_before` | 280 | 8 | 8 | `u64` | - |
| `async_completions_after` | 288 | 8 | 8 | `u64` | - |

### `ProgramKernelUsbCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `selected_cases` | 12 | 4 | 4 | `u32` | - |
| `attempted_cases` | 16 | 4 | 4 | `u32` | - |
| `passed_cases` | 20 | 4 | 4 | `u32` | - |
| `failed_cases` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `SerialConfig`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `baud_rate` | 8 | 4 | 4 | `u32` | - |
| `data_bits` | 12 | 1 | 1 | `u8` | - |
| `parity` | 13 | 1 | 1 | `u8` | - |
| `stop_bits` | 14 | 1 | 1 | `u8` | - |
| `flow_control` | 15 | 1 | 1 | `u8` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `reserved1` | 24 | 4 | 4 | `u32` | - |
| `reserved2` | 28 | 4 | 4 | `u32` | - |

### `SerialPortInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `port_id` | 8 | 8 | 8 | `u64` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `com_number` | 24 | 4 | 4 | `u32` | - |
| `flags` | 28 | 4 | 4 | `u32` | - |
| `capabilities` | 32 | 8 | 8 | `u64` | - |
| `name` | 40 | 16 | 1 | `[16]u8` | - |
| `hardware_identity` | 56 | 64 | 1 | `[64]u8` | - |
| `transport` | 120 | 4 | 4 | `u32` | - |
| `reserved` | 124 | 4 | 4 | `u32` | - |

### `SerialTransfer`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `requested` | 8 | 4 | 4 | `u32` | - |
| `completed` | 12 | 4 | 4 | `u32` | - |
| `status` | 16 | 4 | 4 | `i32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `overflows` | 24 | 8 | 8 | `u64` | - |

### `SerialStatus`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `line_status` | 12 | 4 | 4 | `u32` | - |
| `modem_status` | 16 | 4 | 4 | `u32` | - |
| `rx_pending` | 20 | 4 | 4 | `u32` | - |
| `tx_pending` | 24 | 4 | 4 | `u32` | - |
| `baud_rate` | 28 | 4 | 4 | `u32` | - |
| `rx_bytes` | 32 | 8 | 8 | `u64` | - |
| `tx_bytes` | 40 | 8 | 8 | `u64` | - |
| `rx_dropped` | 48 | 8 | 8 | `u64` | - |
| `line_errors` | 56 | 8 | 8 | `u64` | - |
| `tx_dropped` | 64 | 8 | 8 | `u64` | - |
| `generation` | 72 | 8 | 8 | `u64` | - |
| `last_error` | 80 | 4 | 4 | `i32` | - |
| `reserved` | 84 | 4 | 4 | `u32` | - |

### `SerialBackend`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `com_number` | 8 | 4 | 4 | `u32` | - |
| `resource_kind` | 12 | 4 | 4 | `u32` | - |
| `resource_base` | 16 | 8 | 8 | `u64` | - |
| `resource_length` | 24 | 8 | 8 | `u64` | - |
| `irq` | 32 | 4 | 4 | `u32` | - |
| `capabilities` | 36 | 4 | 4 | `u32` | - |
| `hardware_identity` | 40 | 64 | 1 | `[64]u8` | - |
| `context` | 104 | 8 | 8 | `u64` | - |
| `open` | 112 | 8 | 8 | `u64` | - |
| `configure` | 120 | 8 | 8 | `u64` | - |
| `read` | 128 | 8 | 8 | `u64` | - |
| `write` | 136 | 8 | 8 | `u64` | - |
| `drain` | 144 | 8 | 8 | `u64` | - |
| `status` | 152 | 8 | 8 | `u64` | - |
| `close` | 160 | 8 | 8 | `u64` | - |

### `DriverSerialApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `register_port` | 8 | 8 | 8 | `u64` | - |
| `unregister_port` | 16 | 8 | 8 | `u64` | - |
| `notify` | 24 | 8 | 8 | `u64` | - |
| `admission` | 32 | 8 | 8 | `u64` | - |

### `CpuTopologyInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `apic_id` | 12 | 4 | 4 | `u32` | - |
| `acpi_uid` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `start_epoch` | 24 | 8 | 8 | `u64` | - |
| `source_leaf` | 32 | 4 | 4 | `u32` | - |
| `geometry_status` | 36 | 4 | 4 | `u32` | - |
| `package_id` | 40 | 4 | 4 | `u32` | - |
| `core_id` | 44 | 4 | 4 | `u32` | - |
| `thread_id` | 48 | 4 | 4 | `u32` | - |
| `smt_shift` | 52 | 4 | 4 | `u32` | - |
| `package_shift` | 56 | 4 | 4 | `u32` | - |
| `threads_per_core_bound` | 60 | 4 | 4 | `u32` | - |
| `logical_per_package_bound` | 64 | 4 | 4 | `u32` | - |
| `core_type_source` | 68 | 4 | 4 | `u32` | - |
| `core_type` | 72 | 4 | 4 | `u32` | - |
| `native_model_id` | 76 | 4 | 4 | `u32` | - |
| `efficiency_rank` | 80 | 4 | 4 | `u32` | - |
| `cache_source_leaf` | 84 | 4 | 4 | `u32` | - |
| `cache_count` | 88 | 4 | 4 | `u32` | - |
| `cache_status` | 92 | 4 | 4 | `u32` | - |
| `vendor_name` | 96 | 12 | 1 | `[12]u8` | - |
| `configured_cpus` | 108 | 4 | 4 | `u32` | - |

### `CpuCacheTopologyInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `cache_index` | 12 | 4 | 4 | `u32` | - |
| `start_epoch` | 16 | 8 | 8 | `u64` | - |
| `source_leaf` | 24 | 4 | 4 | `u32` | - |
| `kind` | 28 | 4 | 4 | `u32` | - |
| `level` | 32 | 4 | 4 | `u32` | - |
| `line_bytes` | 36 | 4 | 4 | `u32` | - |
| `sharing_logical_bound` | 40 | 4 | 4 | `u32` | - |
| `sharing_shift` | 44 | 4 | 4 | `u32` | - |
| `cache_bytes` | 48 | 8 | 8 | `u64` | - |
| `property_flags` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |

### `ThreadPlacementRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `work_class` | 12 | 4 | 4 | `u32` | - |
| `preferred_cpu` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `reserved1` | 24 | 8 | 8 | `u64` | - |

### `ThreadPlacementInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `work_class` | 12 | 4 | 4 | `u32` | - |
| `preferred_cpu` | 16 | 4 | 4 | `u32` | - |
| `home_cpu` | 20 | 4 | 4 | `u32` | - |
| `running_cpu` | 24 | 4 | 4 | `u32` | - |
| `cpu_word_count` | 28 | 4 | 4 | `u32` | - |
| `request_revision` | 32 | 8 | 8 | `u64` | - |
| `applied_revision` | 40 | 8 | 8 | `u64` | - |
| `reserved0` | 48 | 8 | 8 | `u64` | - |
| `reserved1` | 56 | 8 | 8 | `u64` | - |

### `CpuLifecycleInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reason` | 20 | 4 | 4 | `u32` | - |
| `configured_cpus` | 24 | 4 | 4 | `u32` | - |
| `available_cpus` | 28 | 4 | 4 | `u32` | - |
| `epoch` | 32 | 8 | 8 | `u64` | - |
| `installed_epoch` | 40 | 8 | 8 | `u64` | - |
| `capacity_generation` | 48 | 8 | 8 | `u64` | - |
| `parked_epoch` | 56 | 8 | 8 | `u64` | - |
| `withdrawn_epoch` | 64 | 8 | 8 | `u64` | - |
| `stopped_epoch` | 72 | 8 | 8 | `u64` | - |
| `tlb_generation` | 80 | 8 | 8 | `u64` | - |
| `switch_serial` | 88 | 8 | 8 | `u64` | - |
| `offline_cycles` | 96 | 8 | 8 | `u64` | - |
| `tasks_migrated` | 104 | 4 | 4 | `u32` | - |
| `irq_retargets` | 108 | 4 | 4 | `u32` | - |
| `reserved0` | 112 | 4 | 4 | `u32` | - |
| `reserved1` | 116 | 4 | 4 | `u32` | - |
| `irq_epoch` | 120 | 8 | 8 | `u64` | - |

### `ProgramKernelCpuLifecycleCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `status` | 8 | 4 | 4 | `u32` | - |
| `selected` | 12 | 4 | 4 | `u32` | - |
| `passed` | 16 | 4 | 4 | `u32` | - |
| `failed` | 20 | 4 | 4 | `u32` | - |
| `cpu_index` | 24 | 4 | 4 | `u32` | - |
| `reason` | 28 | 4 | 4 | `u32` | - |
| `configured_cpus` | 32 | 4 | 4 | `u32` | - |
| `available_before` | 36 | 4 | 4 | `u32` | - |
| `available_offline` | 40 | 4 | 4 | `u32` | - |
| `available_after` | 44 | 4 | 4 | `u32` | - |
| `tasks_created` | 48 | 4 | 4 | `u32` | - |
| `tasks_reaped` | 52 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 56 | 4 | 4 | `u32` | - |
| `if_checks` | 60 | 4 | 4 | `u32` | - |
| `old_epoch` | 64 | 8 | 8 | `u64` | - |
| `new_epoch` | 72 | 8 | 8 | `u64` | - |
| `capacity_before` | 80 | 8 | 8 | `u64` | - |
| `capacity_after` | 88 | 8 | 8 | `u64` | - |
| `parked_epoch` | 96 | 8 | 8 | `u64` | - |
| `stopped_epoch` | 104 | 8 | 8 | `u64` | - |
| `tlb_generation` | 112 | 8 | 8 | `u64` | - |
| `switch_serial` | 120 | 8 | 8 | `u64` | - |

### `CpuCapabilitiesInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 272 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `feature_count` | 20 | 4 | 4 | `u32` | - |
| `max_basic_leaf` | 24 | 4 | 4 | `u32` | - |
| `max_extended_leaf` | 28 | 4 | 4 | `u32` | - |
| `max_hypervisor_leaf` | 32 | 4 | 4 | `u32` | - |
| `max_leaf7_subleaf` | 36 | 4 | 4 | `u32` | - |
| `family` | 40 | 4 | 4 | `u32` | - |
| `model` | 44 | 4 | 4 | `u32` | - |
| `stepping` | 48 | 4 | 4 | `u32` | - |
| `apic_id` | 52 | 4 | 4 | `u32` | - |
| `configured_cpus` | 56 | 4 | 4 | `u32` | - |
| `os_read_flags` | 60 | 4 | 4 | `u32` | - |
| `epoch` | 64 | 8 | 8 | `u64` | - |
| `capture_sequence` | 72 | 8 | 8 | `u64` | - |
| `cr0` | 80 | 8 | 8 | `u64` | - |
| `cr4` | 88 | 8 | 8 | `u64` | - |
| `xcr0` | 96 | 8 | 8 | `u64` | - |
| `efer` | 104 | 8 | 8 | `u64` | - |
| `pat` | 112 | 8 | 8 | `u64` | - |
| `base_mhz` | 120 | 4 | 4 | `u32` | - |
| `maximum_mhz` | 124 | 4 | 4 | `u32` | - |
| `bus_mhz` | 128 | 4 | 4 | `u32` | - |
| `crystal_hz` | 132 | 4 | 4 | `u32` | - |
| `tsc_denominator` | 136 | 4 | 4 | `u32` | - |
| `tsc_numerator` | 140 | 4 | 4 | `u32` | - |
| `pmu_version` | 144 | 4 | 4 | `u32` | - |
| `pmu_counters` | 148 | 4 | 4 | `u32` | - |
| `pmu_counter_width` | 152 | 4 | 4 | `u32` | - |
| `clflush_line_bytes` | 156 | 4 | 4 | `u32` | - |
| `legacy_inventory_msr_faults` | 160 | 4 | 4 | `u32` | - |
| `raw_hypervisor_maximum` | 164 | 4 | 4 | `u32` | - |
| `vendor_name` | 168 | 12 | 1 | `[12]u8` | - |
| `hypervisor_name` | 180 | 12 | 1 | `[12]u8` | - |
| `brand_name` | 192 | 48 | 1 | `[48]u8` | - |
| `recovered_msr_faults` | 240 | 8 | 8 | `u64` | - |
| `physical_address_bits` | 248 | 4 | 4 | `u32` | - |
| `virtual_address_bits` | 252 | 4 | 4 | `u32` | - |
| `supported_xcr0` | 256 | 8 | 8 | `u64` | - |
| `enabled_xsave_bytes` | 264 | 4 | 4 | `u32` | - |
| `maximum_xsave_bytes` | 268 | 4 | 4 | `u32` | - |

### `CpuFeatureInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `feature_index` | 12 | 4 | 4 | `u32` | - |
| `feature_id` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `hardware_state` | 24 | 4 | 4 | `u32` | - |
| `os_state` | 28 | 4 | 4 | `u32` | - |
| `use_state` | 32 | 4 | 4 | `u32` | - |
| `reason` | 36 | 4 | 4 | `u32` | - |
| `source_leaf` | 40 | 4 | 4 | `u32` | - |
| `source_subleaf` | 44 | 4 | 4 | `u32` | - |
| `source_register` | 48 | 4 | 4 | `u32` | - |
| `source_bit` | 52 | 4 | 4 | `u32` | - |
| `raw_value` | 56 | 4 | 4 | `u32` | - |
| `reserved0` | 60 | 4 | 4 | `u32` | - |
| `epoch` | 64 | 8 | 8 | `u64` | - |
| `control_value` | 72 | 8 | 8 | `u64` | - |
| `name` | 80 | 24 | 1 | `[24]u8` | - |
| `reserved1` | 104 | 8 | 8 | `u64` | - |

### `CpuRegisterInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `register_id` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `epoch` | 24 | 8 | 8 | `u64` | - |
| `value` | 32 | 8 | 8 | `u64` | - |
| `capture_sequence` | 40 | 8 | 8 | `u64` | - |
| `name` | 48 | 24 | 1 | `[24]u8` | - |
| `reserved1` | 72 | 8 | 8 | `u64` | - |

### `ProgramKernelCpuRegisterCheck`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `status` | 12 | 4 | 4 | `u32` | - |
| `passed` | 16 | 4 | 4 | `u32` | - |
| `failed` | 20 | 4 | 4 | `u32` | - |
| `if_checks` | 24 | 4 | 4 | `u32` | - |
| `reads` | 28 | 4 | 4 | `u32` | - |
| `writes` | 32 | 4 | 4 | `u32` | - |
| `faults` | 36 | 4 | 4 | `u32` | - |
| `cleanup_errors` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |
| `reserved1` | 48 | 4 | 4 | `u32` | - |
| `reserved2` | 52 | 4 | 4 | `u32` | - |
| `reserved3` | 56 | 4 | 4 | `u32` | - |
| `reserved4` | 60 | 4 | 4 | `u32` | - |
| `epoch` | 64 | 8 | 8 | `u64` | - |
| `capture_sequence` | 72 | 8 | 8 | `u64` | - |
| `faults_before` | 80 | 8 | 8 | `u64` | - |
| `faults_after` | 88 | 8 | 8 | `u64` | - |
| `flags_before` | 96 | 8 | 8 | `u64` | - |
| `flags_after` | 104 | 8 | 8 | `u64` | - |
| `reserved5` | 112 | 8 | 8 | `u64` | - |
| `reserved6` | 120 | 8 | 8 | `u64` | - |

### `CpuPowerInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 320 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `profile` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `valid_mask` | 24 | 4 | 4 | `u32` | - |
| `fault_mask` | 28 | 4 | 4 | `u32` | - |
| `unsupported_mask` | 32 | 4 | 4 | `u32` | - |
| `clock_generation` | 36 | 4 | 4 | `u32` | - |
| `clock_source` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |
| `epoch` | 48 | 8 | 8 | `u64` | - |
| `provider_generation` | 56 | 8 | 8 | `u64` | - |
| `sequence` | 64 | 8 | 8 | `u64` | - |
| `captured_ns` | 72 | 8 | 8 | `u64` | - |
| `previous_ns` | 80 | 8 | 8 | `u64` | - |
| `interval_ns` | 88 | 8 | 8 | `u64` | - |
| `active_hz` | 96 | 8 | 8 | `u64` | - |
| `reference_hz` | 104 | 8 | 8 | `u64` | - |
| `aperf` | 112 | 8 | 8 | `u64` | - |
| `mperf` | 120 | 8 | 8 | `u64` | - |
| `package_energy_raw` | 128 | 8 | 8 | `u64` | - |
| `core_energy_raw` | 136 | 8 | 8 | `u64` | - |
| `package_energy_uj` | 144 | 8 | 8 | `u64` | - |
| `core_energy_uj` | 152 | 8 | 8 | `u64` | - |
| `package_mask` | 160 | 8 | 8 | `u64` | - |
| `core_mask` | 168 | 8 | 8 | `u64` | - |
| `raw_microcode` | 176 | 8 | 8 | `u64` | - |
| `raw_thermal_status` | 184 | 8 | 8 | `u64` | - |
| `raw_temperature_target` | 192 | 8 | 8 | `u64` | - |
| `raw_energy_unit` | 200 | 8 | 8 | `u64` | - |
| `raw_reference` | 208 | 8 | 8 | `u64` | - |
| `microcode_revision` | 216 | 4 | 4 | `u32` | - |
| `package_energy_bits` | 220 | 4 | 4 | `u32` | - |
| `core_energy_bits` | 224 | 4 | 4 | `u32` | - |
| `energy_exponent` | 228 | 4 | 4 | `u32` | - |
| `thermal_current` | 232 | 4 | 4 | `u32` | - |
| `thermal_history` | 236 | 4 | 4 | `u32` | - |
| `package_leader` | 240 | 4 | 4 | `u32` | - |
| `core_leader` | 244 | 4 | 4 | `u32` | - |
| `temperature_millic` | 248 | 4 | 4 | `i32` | - |
| `reserved1` | 252 | 4 | 4 | `u32` | - |
| `vendor_name` | 256 | 12 | 1 | `[12]u8` | - |
| `profile_name` | 268 | 32 | 1 | `[32]u8` | - |
| `reserved2` | 300 | 4 | 4 | `u32` | - |
| `family` | 304 | 4 | 4 | `u32` | - |
| `model` | 308 | 4 | 4 | `u32` | - |
| `stepping` | 312 | 4 | 4 | `u32` | - |
| `reserved3` | 316 | 4 | 4 | `u32` | - |

### `CpuPowerBackend`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `context` | 8 | 8 | 8 | `u64` | - |
| `snapshot` | 16 | 8 | 8 | `u64` | - |
| `capture` | 24 | 8 | 8 | `u64` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |

### `DriverCpuPowerApi`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 6 / 184 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `register_backend` | 8 | 8 | 8 | `u64` | - |
| `unregister_backend` | 16 | 8 | 8 | `u64` | - |
| `current_cpu` | 24 | 8 | 8 | `u64` | - |
| `capabilities` | 32 | 8 | 8 | `u64` | - |
| `topology` | 40 | 8 | 8 | `u64` | - |
| `register_read` | 48 | 8 | 8 | `u64` | - |
| `clock` | 56 | 8 | 8 | `u64` | - |
| `counters_read` | 64 | 8 | 8 | `u64` | - |
| `feature` | 72 | 8 | 8 | `u64` | - |
| `register_performance` | 80 | 8 | 8 | `u64` | - |
| `control_acquire` | 88 | 8 | 8 | `u64` | - |
| `control_release` | 96 | 8 | 8 | `u64` | - |
| `register_compare_write` | 104 | 8 | 8 | `u64` | - |
| `register_cppc` | 112 | 8 | 8 | `u64` | - |
| `rank_publish` | 120 | 8 | 8 | `u64` | - |
| `firmware_register` | 128 | 8 | 8 | `u64` | - |
| `firmware_unregister` | 136 | 8 | 8 | `u64` | - |
| `firmware_execute` | 144 | 8 | 8 | `u64` | - |
| `firmware_control` | 152 | 8 | 8 | `u64` | - |
| `firmware_cpu_info` | 160 | 8 | 8 | `u64` | - |
| `idle_publish` | 168 | 8 | 8 | `u64` | - |
| `idle_policy` | 176 | 8 | 8 | `u64` | - |

### `CpuPowerCounters`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `aperf` | 24 | 8 | 8 | `u64` | - |
| `mperf` | 32 | 8 | 8 | `u64` | - |
| `captured_ns` | 40 | 8 | 8 | `u64` | - |
| `clock_generation` | 48 | 4 | 4 | `u32` | - |
| `clock_source` | 52 | 4 | 4 | `u32` | - |
| `capture_sequence` | 56 | 8 | 8 | `u64` | - |

### `CpuPerformanceRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `operation` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `lease` | 24 | 8 | 8 | `u64` | - |
| `minimum` | 32 | 4 | 4 | `u32` | - |
| `maximum` | 36 | 4 | 4 | `u32` | - |
| `desired` | 40 | 4 | 4 | `u32` | - |
| `epp` | 44 | 4 | 4 | `u32` | - |
| `flags` | 48 | 4 | 4 | `u32` | - |
| `reserved0` | 52 | 4 | 4 | `u32` | - |
| `expected_revision` | 56 | 8 | 8 | `u64` | - |

### `CpuPerformanceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `features` | 20 | 4 | 4 | `u32` | - |
| `valid_mask` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |
| `epoch` | 32 | 8 | 8 | `u64` | - |
| `provider_generation` | 40 | 8 | 8 | `u64` | - |
| `lease` | 48 | 8 | 8 | `u64` | - |
| `revision` | 56 | 8 | 8 | `u64` | - |
| `raw_enable` | 64 | 8 | 8 | `u64` | - |
| `raw_capabilities` | 72 | 8 | 8 | `u64` | - |
| `raw_request` | 80 | 8 | 8 | `u64` | - |
| `raw_package` | 88 | 8 | 8 | `u64` | - |
| `baseline_request` | 96 | 8 | 8 | `u64` | - |
| `last_written` | 104 | 8 | 8 | `u64` | - |
| `package_mask` | 112 | 8 | 8 | `u64` | - |
| `captured_ns` | 120 | 8 | 8 | `u64` | - |
| `minimum` | 128 | 4 | 4 | `u32` | - |
| `maximum` | 132 | 4 | 4 | `u32` | - |
| `desired` | 136 | 4 | 4 | `u32` | - |
| `epp` | 140 | 4 | 4 | `u32` | - |
| `highest` | 144 | 4 | 4 | `u32` | - |
| `guaranteed` | 148 | 4 | 4 | `u32` | - |
| `efficient` | 152 | 4 | 4 | `u32` | - |
| `lowest` | 156 | 4 | 4 | `u32` | - |
| `last_error` | 160 | 4 | 4 | `i32` | - |
| `attempted_id` | 164 | 4 | 4 | `u32` | - |
| `package_leader` | 168 | 4 | 4 | `u32` | - |
| `reserved1` | 172 | 4 | 4 | `u32` | - |

### `CpuPerformanceBackend`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `context` | 8 | 8 | 8 | `u64` | - |
| `execute` | 16 | 8 | 8 | `u64` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `CpuRegisterWriteInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `register_id` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `lease` | 24 | 8 | 8 | `u64` | - |
| `expected` | 32 | 8 | 8 | `u64` | - |
| `requested` | 40 | 8 | 8 | `u64` | - |
| `observed_before` | 48 | 8 | 8 | `u64` | - |
| `observed_after` | 56 | 8 | 8 | `u64` | - |
| `flags` | 64 | 4 | 4 | `u32` | - |
| `last_error` | 68 | 4 | 4 | `i32` | - |

### `CpuCppcInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `features` | 20 | 4 | 4 | `u32` | - |
| `valid_mask` | 24 | 4 | 4 | `u32` | - |
| `raw_valid_mask` | 28 | 4 | 4 | `u32` | - |
| `epoch` | 32 | 8 | 8 | `u64` | - |
| `provider_generation` | 40 | 8 | 8 | `u64` | - |
| `lease` | 48 | 8 | 8 | `u64` | - |
| `revision` | 56 | 8 | 8 | `u64` | - |
| `raw_enable` | 64 | 8 | 8 | `u64` | - |
| `raw_capability1` | 72 | 8 | 8 | `u64` | - |
| `raw_capability2` | 80 | 8 | 8 | `u64` | - |
| `raw_request` | 88 | 8 | 8 | `u64` | - |
| `raw_status` | 96 | 8 | 8 | `u64` | - |
| `baseline_request` | 104 | 8 | 8 | `u64` | - |
| `last_written` | 112 | 8 | 8 | `u64` | - |
| `qualified_mask` | 120 | 8 | 8 | `u64` | - |
| `captured_ns` | 128 | 8 | 8 | `u64` | - |
| `minimum` | 136 | 4 | 4 | `u32` | - |
| `maximum` | 140 | 4 | 4 | `u32` | - |
| `desired` | 144 | 4 | 4 | `u32` | - |
| `epp` | 148 | 4 | 4 | `u32` | - |
| `highest` | 152 | 4 | 4 | `u32` | - |
| `nominal` | 156 | 4 | 4 | `u32` | - |
| `lowest_nonlinear` | 160 | 4 | 4 | `u32` | - |
| `lowest` | 164 | 4 | 4 | `u32` | - |
| `last_error` | 168 | 4 | 4 | `i32` | - |
| `attempted_id` | 172 | 4 | 4 | `u32` | - |
| `hint_sequence` | 176 | 8 | 8 | `u64` | - |
| `clock_generation` | 184 | 4 | 4 | `u32` | - |
| `clock_source` | 188 | 4 | 4 | `u32` | - |

### `CpuCppcBackend`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `context` | 8 | 8 | 8 | `u64` | - |
| `execute` | 16 | 8 | 8 | `u64` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `CpuPerformanceHint`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `captured_ns` | 24 | 8 | 8 | `u64` | - |
| `scope_mask` | 32 | 8 | 8 | `u64` | - |
| `core_mask` | 40 | 8 | 8 | `u64` | - |
| `rank` | 48 | 4 | 4 | `u32` | - |
| `scale` | 52 | 4 | 4 | `u32` | - |
| `clock_generation` | 56 | 4 | 4 | `u32` | - |
| `clock_source` | 60 | 4 | 4 | `u32` | - |

### `CpuPerformanceHintInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `source` | 20 | 4 | 4 | `u32` | - |
| `clock_generation` | 24 | 4 | 4 | `u32` | - |
| `clock_source` | 28 | 4 | 4 | `u32` | - |
| `epoch` | 32 | 8 | 8 | `u64` | - |
| `provider_generation` | 40 | 8 | 8 | `u64` | - |
| `sequence` | 48 | 8 | 8 | `u64` | - |
| `captured_ns` | 56 | 8 | 8 | `u64` | - |
| `expires_ns` | 64 | 8 | 8 | `u64` | - |
| `scope_mask` | 72 | 8 | 8 | `u64` | - |
| `core_mask` | 80 | 8 | 8 | `u64` | - |
| `rank` | 88 | 4 | 4 | `u32` | - |
| `scale` | 92 | 4 | 4 | `u32` | - |

### `PowerProfileRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `profile` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `expected_service_generation` | 16 | 8 | 8 | `u64` | - |
| `expected_revision` | 24 | 8 | 8 | `u64` | - |
| `cpu_index` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |
| `reserved1` | 40 | 8 | 8 | `u64` | - |
| `reserved2` | 48 | 8 | 8 | `u64` | - |
| `reserved3` | 56 | 8 | 8 | `u64` | - |

### `PowerProfileInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `selected_profile` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `configured_cpus` | 20 | 4 | 4 | `u32` | - |
| `online_cpus` | 24 | 4 | 4 | `u32` | - |
| `backend_cpus` | 28 | 4 | 4 | `u32` | - |
| `service_generation` | 32 | 8 | 8 | `u64` | - |
| `revision` | 40 | 8 | 8 | `u64` | - |
| `applied_revision` | 48 | 8 | 8 | `u64` | - |
| `provider_generation` | 56 | 8 | 8 | `u64` | - |
| `owned_mask` | 64 | 8 | 8 | `u64` | - |
| `applied_mask` | 72 | 8 | 8 | `u64` | - |
| `pending_mask` | 80 | 8 | 8 | `u64` | - |
| `supported_mask` | 88 | 8 | 8 | `u64` | - |
| `last_error` | 96 | 4 | 4 | `i32` | - |
| `last_cpu` | 100 | 4 | 4 | `u32` | - |
| `config_revision` | 104 | 4 | 4 | `u32` | - |
| `config_error` | 108 | 4 | 4 | `i32` | - |
| `service_instance_id` | 112 | 4 | 4 | `u32` | - |
| `worker_count` | 116 | 4 | 4 | `u32` | - |
| `sticky_count` | 120 | 4 | 4 | `u32` | - |
| `reserved0` | 124 | 4 | 4 | `u32` | - |

### `PowerCpuProfileInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 160 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `backend` | 12 | 4 | 4 | `u32` | - |
| `state` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |
| `profile` | 24 | 4 | 4 | `u32` | - |
| `last_error` | 28 | 4 | 4 | `i32` | - |
| `cpu_epoch` | 32 | 8 | 8 | `u64` | - |
| `provider_generation` | 40 | 8 | 8 | `u64` | - |
| `lease` | 48 | 8 | 8 | `u64` | - |
| `revision` | 56 | 8 | 8 | `u64` | - |
| `applied_revision` | 64 | 8 | 8 | `u64` | - |
| `captured_ns` | 72 | 8 | 8 | `u64` | - |
| `minimum` | 80 | 4 | 4 | `u32` | - |
| `maximum` | 84 | 4 | 4 | `u32` | - |
| `desired` | 88 | 4 | 4 | `u32` | - |
| `epp` | 92 | 4 | 4 | `u32` | - |
| `lowest` | 96 | 4 | 4 | `u32` | - |
| `highest` | 100 | 4 | 4 | `u32` | - |
| `efficient` | 104 | 4 | 4 | `u32` | - |
| `nominal` | 108 | 4 | 4 | `u32` | - |
| `baseline_request` | 112 | 8 | 8 | `u64` | - |
| `last_written` | 120 | 8 | 8 | `u64` | - |
| `observed_request` | 128 | 8 | 8 | `u64` | - |
| `valid_mask` | 136 | 4 | 4 | `u32` | - |
| `reserved0` | 140 | 4 | 4 | `u32` | - |
| `worker_state` | 144 | 4 | 4 | `u32` | - |
| `reserved1` | 148 | 4 | 4 | `u32` | - |
| `service_generation` | 152 | 8 | 8 | `u64` | - |

### `CpuFirmwareBackend`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `context` | 8 | 8 | 8 | `u64` | - |
| `execute` | 16 | 8 | 8 | `u64` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `CpuFirmwareInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `backend` | 20 | 4 | 4 | `u32` | - |
| `valid_mask` | 24 | 4 | 4 | `u32` | - |
| `coordination` | 28 | 4 | 4 | `u32` | - |
| `epoch` | 32 | 8 | 8 | `u64` | - |
| `provider_generation` | 40 | 8 | 8 | `u64` | - |
| `firmware_generation` | 48 | 8 | 8 | `u64` | - |
| `lease` | 56 | 8 | 8 | `u64` | - |
| `revision` | 64 | 8 | 8 | `u64` | - |
| `domain_mask` | 72 | 8 | 8 | `u64` | - |
| `captured_ns` | 80 | 8 | 8 | `u64` | - |
| `minimum` | 88 | 4 | 4 | `u32` | - |
| `maximum` | 92 | 4 | 4 | `u32` | - |
| `desired` | 96 | 4 | 4 | `u32` | - |
| `epp` | 100 | 4 | 4 | `u32` | - |
| `lowest` | 104 | 4 | 4 | `u32` | - |
| `highest` | 108 | 4 | 4 | `u32` | - |
| `efficient` | 112 | 4 | 4 | `u32` | - |
| `nominal` | 116 | 4 | 4 | `u32` | - |
| `baseline_request` | 120 | 8 | 8 | `u64` | - |
| `last_written` | 128 | 8 | 8 | `u64` | - |
| `observed_request` | 136 | 8 | 8 | `u64` | - |
| `domain_id` | 144 | 4 | 4 | `u32` | - |
| `domain_cpus` | 148 | 4 | 4 | `u32` | - |
| `pstate_count` | 152 | 4 | 4 | `u32` | - |
| `package_revision` | 156 | 4 | 4 | `u32` | - |
| `last_error` | 160 | 4 | 4 | `i32` | - |
| `transport_spaces` | 164 | 4 | 4 | `u32` | - |
| `reserved0` | 168 | 4 | 4 | `u32` | - |
| `reserved1` | 172 | 4 | 4 | `u32` | - |
| `descriptor_identity` | 176 | 8 | 8 | `u64` | - |
| `reserved2` | 184 | 8 | 8 | `u64` | - |

### `CpuIdleDescriptor`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `firmware_generation` | 24 | 8 | 8 | `u64` | - |
| `descriptor_identity` | 32 | 8 | 8 | `u64` | - |
| `source` | 40 | 4 | 4 | `u32` | - |
| `state_count` | 44 | 4 | 4 | `u32` | - |
| `selected_index` | 48 | 4 | 4 | `u32` | - |
| `cstate_type` | 52 | 4 | 4 | `u32` | - |
| `entry_method` | 56 | 4 | 4 | `u32` | - |
| `entry_hint` | 60 | 4 | 4 | `u32` | - |
| `latency_us` | 64 | 4 | 4 | `u32` | - |
| `min_residency_us` | 68 | 4 | 4 | `u32` | - |
| `coordination` | 72 | 4 | 4 | `u32` | - |
| `context_loss` | 76 | 4 | 4 | `u32` | - |
| `declared_power_mw` | 80 | 4 | 4 | `u32` | - |
| `reason` | 84 | 4 | 4 | `u32` | - |
| `lpi_state_count` | 88 | 4 | 4 | `u32` | - |
| `reserved0` | 92 | 4 | 4 | `u32` | - |

### `CpuIdlePolicy`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider_generation` | 8 | 8 | 8 | `u64` | - |
| `enabled` | 16 | 4 | 4 | `u32` | - |
| `maximum_latency_us` | 20 | 4 | 4 | `u32` | - |
| `residency_factor` | 24 | 4 | 4 | `u32` | - |
| `reserved0` | 28 | 4 | 4 | `u32` | - |

### `CpuIdleInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `state` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `firmware_generation` | 24 | 8 | 8 | `u64` | - |
| `policy_generation` | 32 | 8 | 8 | `u64` | - |
| `descriptor_identity` | 40 | 8 | 8 | `u64` | - |
| `source` | 48 | 4 | 4 | `u32` | - |
| `state_count` | 52 | 4 | 4 | `u32` | - |
| `selected_index` | 56 | 4 | 4 | `u32` | - |
| `cstate_type` | 60 | 4 | 4 | `u32` | - |
| `entry_method` | 64 | 4 | 4 | `u32` | - |
| `entry_hint` | 68 | 4 | 4 | `u32` | - |
| `latency_us` | 72 | 4 | 4 | `u32` | - |
| `min_residency_us` | 76 | 4 | 4 | `u32` | - |
| `coordination` | 80 | 4 | 4 | `u32` | - |
| `context_loss` | 84 | 4 | 4 | `u32` | - |
| `declared_power_mw` | 88 | 4 | 4 | `u32` | - |
| `reason` | 92 | 4 | 4 | `u32` | - |
| `lpi_state_count` | 96 | 4 | 4 | `u32` | - |
| `capability_flags` | 100 | 4 | 4 | `u32` | - |
| `reserved0` | 104 | 4 | 4 | `u32` | - |
| `reserved1` | 108 | 4 | 4 | `u32` | - |
| `entry_attempts` | 112 | 8 | 8 | `u64` | - |
| `hlt_fallbacks` | 120 | 8 | 8 | `u64` | - |
| `cancelled_entries` | 128 | 8 | 8 | `u64` | - |
| `elapsed_ns` | 136 | 8 | 8 | `u64` | - |
| `last_elapsed_ns` | 144 | 8 | 8 | `u64` | - |
| `active_entries` | 152 | 8 | 8 | `u64` | - |
| `descriptor_revision` | 160 | 8 | 8 | `u64` | - |
| `residency_ns` | 168 | 8 | 8 | `u64` | - |
| `wake_latency_ns` | 176 | 8 | 8 | `u64` | - |
| `energy_uj` | 184 | 8 | 8 | `u64` | - |

### `CpuMachineInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `sequence` | 24 | 8 | 8 | `u64` | - |
| `mcg_cap` | 32 | 8 | 8 | `u64` | - |
| `mcg_status` | 40 | 8 | 8 | `u64` | - |
| `rip` | 48 | 8 | 8 | `u64` | - |
| `rsp` | 56 | 8 | 8 | `u64` | - |
| `rflags` | 64 | 8 | 8 | `u64` | - |
| `origin` | 72 | 4 | 4 | `u32` | - |
| `configured_cpus` | 76 | 4 | 4 | `u32` | - |
| `apic_id` | 80 | 4 | 4 | `u32` | - |
| `family` | 84 | 4 | 4 | `u32` | - |
| `model` | 88 | 4 | 4 | `u32` | - |
| `stepping` | 92 | 4 | 4 | `u32` | - |
| `profile` | 96 | 4 | 4 | `u32` | - |
| `bank_count` | 100 | 4 | 4 | `u32` | - |
| `stored_banks` | 104 | 4 | 4 | `u32` | - |
| `valid_banks` | 108 | 4 | 4 | `u32` | - |
| `read_faults` | 112 | 4 | 4 | `u32` | - |
| `bank_limit` | 116 | 4 | 4 | `u32` | - |
| `vendor_name` | 120 | 12 | 1 | `[12]u8` | - |
| `nested_errors` | 132 | 4 | 4 | `u32` | - |
| `reserved0` | 136 | 8 | 8 | `u64` | - |

### `CpuMachineBank`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `bank_index` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `sequence` | 24 | 8 | 8 | `u64` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `format` | 36 | 4 | 4 | `u32` | - |
| `status_msr` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |
| `status` | 48 | 8 | 8 | `u64` | - |
| `address` | 56 | 8 | 8 | `u64` | - |
| `misc` | 64 | 8 | 8 | `u64` | - |
| `config` | 72 | 8 | 8 | `u64` | - |
| `ipid` | 80 | 8 | 8 | `u64` | - |
| `syndrome` | 88 | 8 | 8 | `u64` | - |
| `status_after` | 96 | 8 | 8 | `u64` | - |
| `reserved1` | 104 | 8 | 8 | `u64` | - |

### `CpuMicrocodeInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `sequence` | 24 | 8 | 8 | `u64` | - |
| `status` | 32 | 4 | 4 | `u32` | - |
| `vendor` | 36 | 4 | 4 | `u32` | - |
| `signature` | 40 | 4 | 4 | `u32` | - |
| `platform_mask` | 44 | 4 | 4 | `u32` | - |
| `before_revision` | 48 | 4 | 4 | `u32` | - |
| `after_revision` | 52 | 4 | 4 | `u32` | - |
| `target_revision` | 56 | 4 | 4 | `u32` | - |
| `minimum_revision` | 60 | 4 | 4 | `u32` | - |
| `package_id` | 64 | 4 | 4 | `u32` | - |
| `package_bytes` | 68 | 4 | 4 | `u32` | - |
| `read_faults` | 72 | 4 | 4 | `u32` | - |
| `write_attempts` | 76 | 4 | 4 | `u32` | - |
| `before_features_hash` | 80 | 8 | 8 | `u64` | - |
| `after_features_hash` | 88 | 8 | 8 | `u64` | - |
| `admitted_features_hash` | 96 | 8 | 8 | `u64` | - |
| `package_sha256` | 104 | 32 | 1 | `[32]u8` | - |
| `configured_cpus` | 136 | 4 | 4 | `u32` | - |
| `reserved0` | 140 | 4 | 4 | `u32` | - |

### `CpuPmuInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `last_generation` | 24 | 8 | 8 | `u64` | - |
| `last_epoch` | 32 | 8 | 8 | `u64` | - |
| `profile` | 40 | 4 | 4 | `u32` | - |
| `reason` | 44 | 4 | 4 | `u32` | - |
| `pmu_version` | 48 | 4 | 4 | `u32` | - |
| `counter_count` | 52 | 4 | 4 | `u32` | - |
| `counter_width` | 56 | 4 | 4 | `u32` | - |
| `fixed_count` | 60 | 4 | 4 | `u32` | - |
| `fixed_width` | 64 | 4 | 4 | `u32` | - |
| `event_mask` | 68 | 4 | 4 | `u32` | - |
| `architectural_event_mask` | 72 | 4 | 4 | `u32` | - |
| `signature` | 76 | 4 | 4 | `u32` | - |
| `configured_cpus` | 80 | 4 | 4 | `u32` | - |
| `state` | 84 | 4 | 4 | `u32` | - |
| `inflight_generation` | 88 | 8 | 8 | `u64` | - |
| `inflight_epoch` | 96 | 8 | 8 | `u64` | - |
| `last_sequence` | 104 | 8 | 8 | `u64` | - |
| `reserved0` | 112 | 16 | 8 | `[2]u64` | - |

### `CpuPmuResult`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 256 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `sequence` | 32 | 8 | 8 | `u64` | - |
| `event_id` | 40 | 4 | 4 | `u32` | - |
| `profile` | 44 | 4 | 4 | `u32` | - |
| `status` | 48 | 4 | 4 | `u32` | - |
| `callback_result` | 52 | 4 | 4 | `i32` | - |
| `counter_width` | 56 | 4 | 4 | `u32` | - |
| `iterations` | 60 | 4 | 4 | `u32` | - |
| `read_faults` | 64 | 4 | 4 | `u32` | - |
| `write_attempts` | 68 | 4 | 4 | `u32` | - |
| `raw_before` | 72 | 8 | 8 | `u64` | - |
| `raw_after` | 80 | 8 | 8 | `u64` | - |
| `delta_modulo` | 88 | 8 | 8 | `u64` | - |
| `counter_mask` | 96 | 8 | 8 | `u64` | - |
| `saved_control` | 104 | 8 | 8 | `u64` | - |
| `saved_counter` | 112 | 8 | 8 | `u64` | - |
| `saved_global` | 120 | 8 | 8 | `u64` | - |
| `saved_status` | 128 | 8 | 8 | `u64` | - |
| `observed_control` | 136 | 8 | 8 | `u64` | - |
| `observed_counter` | 144 | 8 | 8 | `u64` | - |
| `observed_global` | 152 | 8 | 8 | `u64` | - |
| `observed_status` | 160 | 8 | 8 | `u64` | - |
| `original_if` | 168 | 8 | 8 | `u64` | - |
| `final_if` | 176 | 8 | 8 | `u64` | - |
| `begin_ns` | 184 | 8 | 8 | `u64` | - |
| `end_ns` | 192 | 8 | 8 | `u64` | - |
| `signature` | 200 | 4 | 4 | `u32` | - |
| `configured_cpus` | 204 | 4 | 4 | `u32` | - |
| `counter_index` | 208 | 4 | 4 | `u32` | - |
| `reserved0` | 212 | 4 | 4 | `u32` | - |
| `event_select` | 216 | 8 | 8 | `u64` | - |
| `reserved1` | 224 | 32 | 8 | `[4]u64` | - |

### `PmuWorkFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `CpuAccelerationInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `capture_sequence` | 24 | 8 | 8 | `u64` | - |
| `hardware_mask` | 32 | 8 | 8 | `u64` | - |
| `os_mask` | 40 | 8 | 8 | `u64` | - |
| `common_hardware_mask` | 48 | 8 | 8 | `u64` | - |
| `xcr0` | 56 | 8 | 8 | `u64` | - |
| `signature` | 64 | 4 | 4 | `u32` | - |
| `configured_cpus` | 68 | 4 | 4 | `u32` | - |
| `common_known_count` | 72 | 4 | 4 | `u32` | - |
| `feature_count` | 76 | 4 | 4 | `u32` | - |
| `reserved0` | 80 | 48 | 8 | `[6]u64` | - |

### `CpuAccelerationWork`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `cpu_index` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `capture_sequence` | 24 | 8 | 8 | `u64` | - |
| `work_kind` | 32 | 4 | 4 | `u32` | - |
| `iterations` | 36 | 4 | 4 | `u32` | - |
| `status` | 40 | 4 | 4 | `u32` | - |
| `callback_result` | 44 | 4 | 4 | `i32` | - |
| `original_if` | 48 | 8 | 8 | `u64` | - |
| `final_if` | 56 | 8 | 8 | `u64` | - |
| `begin_ns` | 64 | 8 | 8 | `u64` | - |
| `end_ns` | 72 | 8 | 8 | `u64` | - |
| `granted_mask` | 80 | 8 | 8 | `u64` | - |
| `xcr0` | 88 | 8 | 8 | `u64` | - |
| `clock_source` | 96 | 4 | 4 | `u32` | - |
| `clock_generation` | 100 | 4 | 4 | `u32` | - |
| `reserved0` | 104 | 24 | 8 | `[3]u64` | - |

### `CpuPureWorkFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `EntropySourceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `state` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `owner_epoch` | 24 | 8 | 8 | `u64` | - |
| `owner` | 32 | 4 | 4 | `u32` | - |
| `module_generation` | 36 | 4 | 4 | `u32` | - |
| `pci_address` | 40 | 4 | 4 | `u32` | - |
| `vendor_id` | 44 | 2 | 2 | `u16` | - |
| `device_id` | 46 | 2 | 2 | `u16` | - |
| `max_request_bytes` | 48 | 4 | 4 | `u32` | - |
| `last_result` | 52 | 4 | 4 | `i32` | - |
| `requests` | 56 | 8 | 8 | `u64` | - |
| `completed_requests` | 64 | 8 | 8 | `u64` | - |
| `completed_bytes` | 72 | 8 | 8 | `u64` | - |
| `dma_submitted` | 80 | 8 | 8 | `u64` | - |
| `dma_completed` | 88 | 8 | 8 | `u64` | - |
| `short_completions` | 96 | 8 | 8 | `u64` | - |
| `failed_requests` | 104 | 8 | 8 | `u64` | - |
| `last_device_flags` | 112 | 4 | 4 | `u32` | - |
| `reserved0` | 116 | 4 | 4 | `u32` | - |
| `reserved1` | 120 | 8 | 8 | `u64` | - |

### `EntropyDeviceReceipt`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `status` | 12 | 4 | 4 | `u32` | - |
| `requested_bytes` | 16 | 4 | 4 | `u32` | - |
| `completed_bytes` | 20 | 4 | 4 | `u32` | - |
| `last_used_length` | 24 | 4 | 4 | `u32` | - |
| `last_descriptor` | 28 | 4 | 4 | `u32` | - |
| `dma_submitted` | 32 | 8 | 8 | `u64` | - |
| `dma_completed` | 40 | 8 | 8 | `u64` | - |
| `short_completions` | 48 | 8 | 8 | `u64` | - |
| `begin_ns` | 56 | 8 | 8 | `u64` | - |
| `end_ns` | 64 | 8 | 8 | `u64` | - |
| `request_generation` | 72 | 8 | 8 | `u64` | - |
| `available_index_before` | 80 | 4 | 4 | `u32` | - |
| `available_index_after` | 84 | 4 | 4 | `u32` | - |
| `used_index_before` | 88 | 4 | 4 | `u32` | - |
| `used_index_after` | 92 | 4 | 4 | `u32` | - |
| `device_status` | 96 | 4 | 4 | `u32` | - |
| `pci_command` | 100 | 4 | 4 | `u32` | - |
| `clock_generation` | 104 | 4 | 4 | `u32` | - |
| `clock_source` | 108 | 4 | 4 | `u32` | - |
| `reserved0` | 112 | 16 | 8 | `[2]u64` | - |

### `EntropyBackend`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `max_request_bytes` | 12 | 4 | 4 | `u32` | - |
| `context` | 16 | 8 | 8 | `u64` | - |
| `pci_address` | 24 | 4 | 4 | `u32` | - |
| `vendor_id` | 28 | 2 | 2 | `u16` | - |
| `device_id` | 30 | 2 | 2 | `u16` | - |
| `read` | 32 | 8 | 8 | `u64` | - |
| `reserved0` | 40 | 24 | 8 | `[3]u64` | - |

### `DriverEntropyApi`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `register_backend` | 8 | 8 | 8 | `u64` | - |
| `unregister_backend` | 16 | 8 | 8 | `u64` | - |
| `reserved0` | 24 | 8 | 8 | `u64` | - |

### `EntropyReadFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `ConsoleInputEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `kind` | 4 | 4 | 4 | `u32` | - |
| `value` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |

### `ConsoleTextInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `encoding` | 8 | 4 | 4 | `u32` | - |
| `transcript_encoding` | 12 | 4 | 4 | `u32` | - |
| `pending_bytes` | 16 | 4 | 4 | `u32` | - |
| `decode_errors` | 20 | 4 | 4 | `u32` | - |
| `truncated_sequences` | 24 | 4 | 4 | `u32` | - |
| `flags` | 28 | 4 | 4 | `u32` | - |

### `FpuObservationRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `operation` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `token` | 16 | 8 | 8 | `u64` | - |
| `task_generation` | 24 | 8 | 8 | `u64` | - |
| `rip_begin` | 32 | 8 | 8 | `u64` | - |
| `rip_end` | 40 | 8 | 8 | `u64` | - |

### `FpuObservationInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `task_id` | 12 | 4 | 4 | `u32` | - |
| `task_generation` | 16 | 8 | 8 | `u64` | - |
| `token` | 24 | 8 | 8 | `u64` | - |
| `rip_begin` | 32 | 8 | 8 | `u64` | - |
| `rip_end` | 40 | 8 | 8 | `u64` | - |
| `timer_irqs` | 48 | 8 | 8 | `u64` | - |
| `timer_preemptions` | 56 | 8 | 8 | `u64` | - |
| `external_handlers` | 64 | 8 | 8 | `u64` | - |
| `observed_cpus` | 72 | 8 | 8 | `u64` | - |
| `last_rip` | 80 | 8 | 8 | `u64` | - |
| `last_handler` | 88 | 8 | 8 | `u64` | - |
| `last_irq` | 96 | 4 | 4 | `u32` | - |
| `last_owner` | 100 | 4 | 4 | `u32` | - |
| `last_cpu` | 104 | 4 | 4 | `u32` | - |
| `reserved0` | 108 | 4 | 4 | `u32` | - |
| `reserved1` | 112 | 8 | 8 | `u64` | - |
| `reserved2` | 120 | 8 | 8 | `u64` | - |

### `ProgramLifecycleSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `handle` | 8 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `task_id` | 24 | 4 | 4 | `u32` | - |
| `role` | 28 | 1 | 1 | `u8` | - |
| `app_class` | 29 | 1 | 1 | `u8` | - |
| `state` | 30 | 1 | 1 | `u8` | - |
| `flags` | 31 | 1 | 1 | `u8` | - |
| `exit_code` | 32 | 4 | 4 | `i32` | - |
| `window_id` | 36 | 4 | 4 | `i32` | - |

### `DirectoryBatchCursor`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 2160 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `change` | 8 | 40 | 8 | `DirectoryChangeCursor` | - |
| `parent_change` | 48 | 40 | 8 | `DirectoryChangeCursor` | - |
| `owner_id` | 88 | 4 | 4 | `u32` | - |
| `owner_kind` | 92 | 4 | 4 | `u32` | - |
| `owner_generation` | 96 | 8 | 8 | `u64` | - |
| `node_generation` | 104 | 4 | 4 | `u32` | - |
| `path_len` | 108 | 4 | 4 | `u32` | - |
| `path` | 112 | 1024 | 1 | `[1024]u8` | - |
| `backend` | 1136 | 1024 | 8 | `[128]u64` | - |

### `DirectoryBatchEntry`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `info` | 0 | 96 | 8 | `FileInfo` | - |
| `path` | 96 | 1024 | 1 | `[1024]u8` | - |

### `AudioBackendWriteReceipt`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `output_generation` | 16 | 8 | 8 | `u64` | - |
| `reset_generation` | 24 | 8 | 8 | `u64` | - |
| `first_frame` | 32 | 8 | 8 | `u64` | - |
| `frames` | 40 | 8 | 8 | `u64` | - |

### `AudioBackendPlayback`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `output_generation` | 16 | 8 | 8 | `u64` | - |
| `reset_generation` | 24 | 8 | 8 | `u64` | - |
| `accepted_frames` | 32 | 8 | 8 | `u64` | - |
| `dma_frames` | 40 | 8 | 8 | `u64` | - |
| `consumed_frames` | 48 | 8 | 8 | `u64` | - |
| `previous_output_generation` | 56 | 8 | 8 | `u64` | - |
| `previous_reset_generation` | 64 | 8 | 8 | `u64` | - |
| `previous_accepted_frames` | 72 | 8 | 8 | `u64` | - |
| `previous_dma_frames` | 80 | 8 | 8 | `u64` | - |
| `previous_consumed_frames` | 88 | 8 | 8 | `u64` | - |
| `rate` | 96 | 4 | 4 | `u32` | - |
| `channels` | 100 | 2 | 2 | `u16` | - |
| `format` | 102 | 2 | 2 | `u16` | - |
| `max_queue_frames` | 104 | 4 | 4 | `u32` | - |
| `reserved1` | 108 | 4 | 4 | `u32` | - |

### `AudioBackendFlow`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `source_due_ns` | 16 | 8 | 8 | `u64` | - |
| `low_water_frames` | 24 | 4 | 4 | `u32` | - |
| `high_water_frames` | 28 | 4 | 4 | `u32` | - |
| `output_generation` | 32 | 8 | 8 | `u64` | - |

### `AudioStreamExpectation`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `stream_generation` | 16 | 8 | 8 | `u64` | - |
| `source_due_ns` | 24 | 8 | 8 | `u64` | - |
| `low_water_frames` | 32 | 4 | 4 | `u32` | - |
| `high_water_frames` | 36 | 4 | 4 | `u32` | - |

### `AudioStreamProgress`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 152 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `stream_id` | 12 | 4 | 4 | `u32` | - |
| `stream_generation` | 16 | 8 | 8 | `u64` | - |
| `backend_generation` | 24 | 8 | 8 | `u64` | - |
| `output_generation` | 32 | 8 | 8 | `u64` | - |
| `reset_generation` | 40 | 8 | 8 | `u64` | - |
| `accepted_source_bytes` | 48 | 8 | 8 | `u64` | - |
| `accepted_frames` | 56 | 8 | 8 | `u64` | - |
| `backend_frames` | 64 | 8 | 8 | `u64` | - |
| `submitted_frames` | 72 | 8 | 8 | `u64` | - |
| `consumed_frames` | 80 | 8 | 8 | `u64` | - |
| `unconfirmed_frames` | 88 | 8 | 8 | `u64` | - |
| `queued_frames` | 96 | 8 | 8 | `u64` | - |
| `queue_age_ns` | 104 | 8 | 8 | `u64` | - |
| `observed_ns` | 112 | 8 | 8 | `u64` | - |
| `source_due_ns` | 120 | 8 | 8 | `u64` | - |
| `source_starvations` | 128 | 8 | 8 | `u64` | - |
| `rate` | 136 | 4 | 4 | `u32` | - |
| `channels` | 140 | 2 | 2 | `u16` | - |
| `format` | 142 | 2 | 2 | `u16` | - |
| `reserved0` | 144 | 4 | 4 | `u32` | - |
| `reserved1` | 148 | 4 | 4 | `u32` | - |

### `AudioServiceStreamProgressRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `stream_id` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `service_epoch` | 16 | 8 | 8 | `u64` | - |
| `stream_generation` | 24 | 8 | 8 | `u64` | - |

### `AudioServiceStreamProgressState`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 200 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `result` | 8 | 4 | 4 | `i32` | - |
| `stream_id` | 12 | 4 | 4 | `u32` | - |
| `service_epoch` | 16 | 8 | 8 | `u64` | - |
| `stream_generation` | 24 | 8 | 8 | `u64` | - |
| `suppressed_bytes` | 32 | 8 | 8 | `u64` | - |
| `accepted_source_bytes` | 40 | 8 | 8 | `u64` | - |
| `progress` | 48 | 152 | 8 | `AudioStreamProgress` | - |

### `AudioServiceStreamFlowRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 72 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `stream` | 0 | 32 | 8 | `AudioServiceStreamProgressRequest` | - |
| `expectation` | 32 | 40 | 8 | `AudioStreamExpectation` | - |

### `AudioServiceStreamTrackedWriteRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `magic` | 0 | 4 | 4 | `u32` | - |
| `version` | 4 | 2 | 2 | `u16` | - |
| `size` | 6 | 2 | 2 | `u16` | - |
| `stream_id` | 8 | 4 | 4 | `u32` | - |
| `byte_count` | 12 | 4 | 4 | `u32` | - |
| `service_epoch` | 16 | 8 | 8 | `u64` | - |
| `stream_generation` | 24 | 8 | 8 | `u64` | - |
| `source_due_ns` | 32 | 8 | 8 | `u64` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |

### `ProgramObservationHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `process` | 0 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `id` | 16 | 8 | 8 | `u64` | - |

### `FileNameLimits`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `size` | 0 | 4 | 4 | `u32` | - |
| `flags` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 4 | 4 | `u32` | - |
| `drive_letter` | 12 | 4 | 4 | `u32` | - |
| `mount_slot` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |
| `mount_generation` | 24 | 8 | 8 | `u64` | - |
| `max_path_bytes` | 32 | 4 | 4 | `u32` | - |
| `max_component_bytes` | 36 | 4 | 4 | `u32` | - |
| `max_component_utf16_units` | 40 | 4 | 4 | `u32` | - |
| `short_base_bytes` | 44 | 2 | 2 | `u16` | - |
| `short_extension_bytes` | 46 | 2 | 2 | `u16` | - |
| `name_rules` | 48 | 4 | 4 | `u32` | - |
| `atomic_rules` | 52 | 4 | 4 | `u32` | - |

### `GuiPointerWindowIdentity`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `owner` | 0 | 16 | 8 | `ProgramProcessHandle` | - |
| `epoch` | 16 | 8 | 8 | `u64` | - |
| `window_id` | 24 | 4 | 4 | `i32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |

### `GuiPointerCaptureHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `window` | 0 | 32 | 8 | `GuiPointerWindowIdentity` | - |
| `id` | 32 | 8 | 8 | `u64` | - |

### `GuiPointerCaptureInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 104 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `capture` | 0 | 40 | 8 | `GuiPointerCaptureHandle` | - |
| `desktop` | 40 | 16 | 8 | `ProgramProcessHandle` | - |
| `revision` | 56 | 8 | 8 | `u64` | - |
| `state` | 64 | 4 | 4 | `u32` | - |
| `mode` | 68 | 4 | 4 | `u32` | - |
| `reason` | 72 | 4 | 4 | `u32` | - |
| `capabilities` | 76 | 4 | 4 | `u32` | - |
| `buttons` | 80 | 4 | 4 | `u32` | - |
| `motion_x` | 84 | 4 | 4 | `u32` | - |
| `motion_y` | 88 | 4 | 4 | `u32` | - |
| `reserved` | 92 | 4 | 4 | `u32` | - |
| `cursor_x` | 96 | 4 | 4 | `i32` | - |
| `cursor_y` | 100 | 4 | 4 | `i32` | - |

### `GuiPointerHostRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `operation` | 0 | 4 | 4 | `u32` | - |
| `reason` | 4 | 4 | 4 | `u32` | - |
| `flags` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `capture` | 16 | 40 | 8 | `GuiPointerCaptureHandle` | - |
| `event` | 56 | 40 | 8 | `GuiEvent` | - |

### `GuiHostInputRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `window` | 0 | 32 | 8 | `GuiPointerWindowIdentity` | - |
| `event` | 32 | 40 | 8 | `GuiEvent` | - |
| `operation` | 72 | 4 | 4 | `u32` | - |
| `reason` | 76 | 4 | 4 | `u32` | - |

### `AudioOutputEpoch`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `count` | 16 | 4 | 4 | `u32` | - |
| `active_index` | 20 | 4 | 4 | `i32` | - |

### `AudioOutputEpochFn`

- Quelle: `API/ApiContract.json`
- Klasse: `callback`
- Repräsentation: `c_callback`
- Version/Größe/Alignment: 1 / 8 / 8

### `AudioOutputProviderEpoch`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `registration` | 0 | 8 | 8 | `u64` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `count` | 16 | 4 | 4 | `u32` | - |
| `active_index` | 20 | 4 | 4 | `i32` | - |

### `AudioOutputCatalog`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 224 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `registry_generation` | 8 | 8 | 8 | `u64` | - |
| `active_registration` | 16 | 8 | 8 | `u64` | - |
| `count` | 24 | 4 | 4 | `u32` | - |
| `provider_count` | 28 | 4 | 4 | `u32` | - |
| `providers` | 32 | 192 | 8 | `[8]AudioOutputProviderEpoch` | - |

### `DesktopEvidenceToken`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `broker` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `request` | 24 | 16 | 8 | `ProgramProcessHandle` | - |
| `process` | 40 | 16 | 8 | `ProgramProcessHandle` | - |
| `desktop` | 56 | 16 | 8 | `ProgramProcessHandle` | - |
| `epoch` | 72 | 24 | 8 | `[3]u64` | - |
| `serial` | 96 | 8 | 8 | `u64` | - |
| `intent` | 104 | 24 | 8 | `[3]u64` | - |

### `DesktopEvidenceRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 136 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `token` | 0 | 128 | 8 | `DesktopEvidenceToken` | - |
| `offset` | 128 | 4 | 4 | `u32` | - |
| `capacity` | 132 | 4 | 4 | `u32` | - |

### `DesktopEvidenceReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 288 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `token` | 0 | 128 | 8 | `DesktopEvidenceToken` | - |
| `result` | 128 | 4 | 4 | `i32` | - |
| `phase` | 132 | 4 | 4 | `u32` | - |
| `deadline` | 136 | 8 | 8 | `u64` | - |
| `completion` | 144 | 128 | 8 | `ProgramProcessCompletion` | - |
| `data_bytes` | 272 | 4 | 4 | `u32` | - |
| `raw_result` | 276 | 4 | 4 | `i32` | - |
| `revision` | 280 | 8 | 8 | `u64` | - |

### `DesktopActionToken`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 144 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `window` | 8 | 64 | 8 | `WindowModeIdentity` | - |
| `request` | 72 | 16 | 8 | `ProgramProcessHandle` | - |
| `controller` | 88 | 16 | 8 | `ProgramProcessHandle` | - |
| `epoch` | 104 | 24 | 8 | `[3]u64` | - |
| `grant` | 128 | 8 | 8 | `u64` | - |
| `rights` | 136 | 4 | 4 | `u32` | - |
| `reserved` | 140 | 4 | 4 | `u32` | - |

### `DesktopActionState`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 168 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `window` | 8 | 64 | 8 | `WindowModeIdentity` | - |
| `view_revision` | 72 | 8 | 8 | `u64` | - |
| `frame_before` | 80 | 8 | 8 | `u64` | - |
| `candidate_generation` | 88 | 8 | 8 | `u64` | - |
| `frame_generation` | 96 | 8 | 8 | `u64` | - |
| `composition_serial` | 104 | 8 | 8 | `u64` | - |
| `input_revision` | 112 | 8 | 8 | `u64` | - |
| `info` | 120 | 40 | 4 | `GuiWindowInfo` | - |
| `proof_flags` | 160 | 4 | 4 | `u32` | - |
| `reserved` | 164 | 4 | 4 | `u32` | - |

### `DesktopActionRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 192 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `token` | 0 | 144 | 8 | `DesktopActionToken` | - |
| `operation` | 144 | 8 | 8 | `u64` | - |
| `deadline` | 152 | 8 | 8 | `u64` | - |
| `kind` | 160 | 4 | 4 | `u32` | - |
| `flags` | 164 | 4 | 4 | `u32` | - |
| `x` | 168 | 4 | 4 | `i32` | - |
| `y` | 172 | 4 | 4 | `i32` | - |
| `width` | 176 | 4 | 4 | `i32` | - |
| `height` | 180 | 4 | 4 | `i32` | - |
| `frame_generation` | 184 | 8 | 8 | `u64` | - |

### `DesktopActionReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 544 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `request` | 0 | 192 | 8 | `DesktopActionRequest` | - |
| `result` | 192 | 4 | 4 | `i32` | - |
| `phase` | 196 | 4 | 4 | `u32` | - |
| `applied_tick` | 200 | 8 | 8 | `u64` | - |
| `applied` | 208 | 168 | 8 | `DesktopActionState` | - |
| `current` | 376 | 168 | 8 | `DesktopActionState` | - |

### `DesktopWindowExchange`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 640 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `mode` | 0 | 96 | 8 | `WindowModeExchange` | - |
| `state` | 96 | 168 | 8 | `DesktopActionState` | - |
| `ack` | 264 | 192 | 8 | `DesktopActionRequest` | - |
| `applied` | 456 | 168 | 8 | `DesktopActionState` | - |
| `applied_tick` | 624 | 8 | 8 | `u64` | - |
| `ack_result` | 632 | 4 | 4 | `i32` | - |
| `flags` | 636 | 4 | 4 | `u32` | - |

### `DesktopWindowReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 640 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `mode` | 0 | 96 | 8 | `WindowModeReply` | - |
| `action` | 96 | 544 | 8 | `DesktopActionReply` | - |

### `DesktopFocusSnapshot`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `window` | 8 | 64 | 8 | `WindowModeIdentity` | - |
| `view_revision` | 72 | 8 | 8 | `u64` | - |
| `input_revision` | 80 | 8 | 8 | `u64` | - |
| `observed_tick` | 88 | 8 | 8 | `u64` | - |
| `focus_state` | 96 | 4 | 4 | `u32` | - |
| `flags` | 100 | 4 | 4 | `u32` | - |
| `reserved` | 104 | 8 | 8 | `u64` | - |

### `DesktopFocusReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `result` | 0 | 4 | 4 | `i32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `snapshot` | 8 | 112 | 8 | `DesktopFocusSnapshot` | - |

### `DesktopWindowExchangeV2`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 752 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `previous` | 0 | 640 | 8 | `DesktopWindowExchange` | - |
| `focus` | 640 | 112 | 8 | `DesktopFocusSnapshot` | - |

### `FirmwareSystemUuidInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `source` | 8 | 4 | 4 | `u32` | - |
| `reserved` | 12 | 4 | 4 | `u32` | - |
| `uuid` | 16 | 16 | 1 | `[16]u8` | - |

### `DesktopLinkToken`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 96 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `service` | 8 | 16 | 8 | `ProgramProcessHandle` | - |
| `owner` | 24 | 16 | 8 | `ProgramProcessHandle` | - |
| `epoch` | 40 | 24 | 8 | `[3]u64` | - |
| `intent` | 64 | 24 | 8 | `[3]u64` | - |
| `serial` | 88 | 8 | 8 | `u64` | - |

### `DesktopLinkRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1296 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `token` | 0 | 96 | 8 | `DesktopLinkToken` | - |
| `deadline` | 96 | 8 | 8 | `u64` | - |
| `link_path` | 104 | 160 | 1 | `[160]u8` | - |
| `link_length` | 264 | 4 | 4 | `u32` | - |
| `reserved` | 268 | 4 | 4 | `u32` | - |
| `link_bytes` | 272 | 1024 | 1 | `[1024]u8` | - |

### `DesktopLinkReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1800 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `request` | 0 | 1296 | 8 | `DesktopLinkRequest` | - |
| `result` | 1296 | 4 | 4 | `i32` | - |
| `phase` | 1300 | 4 | 4 | `u32` | - |
| `desktop` | 1304 | 16 | 8 | `ProgramProcessHandle` | - |
| `process` | 1320 | 16 | 8 | `ProgramProcessHandle` | - |
| `accepted_tick` | 1336 | 8 | 8 | `u64` | - |
| `started_tick` | 1344 | 8 | 8 | `u64` | - |
| `ready_tick` | 1352 | 8 | 8 | `u64` | - |
| `cleanup_tick` | 1360 | 8 | 8 | `u64` | - |
| `content_generation` | 1368 | 8 | 8 | `u64` | - |
| `resolved_path` | 1376 | 160 | 1 | `[160]u8` | - |
| `resolved_args` | 1536 | 128 | 1 | `[128]u8` | - |
| `policy` | 1664 | 4 | 4 | `u32` | - |
| `flags` | 1668 | 4 | 4 | `u32` | - |
| `completion` | 1672 | 128 | 8 | `ProgramProcessCompletion` | - |

### `ServiceInventoryCursor`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `revision` | 0 | 8 | 8 | `u64` | - |
| `after_id` | 8 | 8 | 8 | `u64` | - |
| `total` | 16 | 8 | 8 | `u64` | - |
| `flags` | 24 | 4 | 4 | `u32` | - |
| `reserved` | 28 | 4 | 4 | `u32` | - |

### `ServiceInventoryRow`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1448 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `registration_id` | 0 | 8 | 8 | `u64` | - |
| `start_generation` | 8 | 8 | 8 | `u64` | - |
| `process` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `info` | 32 | 216 | 8 | `r4os.abi.ServiceInfo` | - |
| `path` | 248 | 1024 | 1 | `[1024]u8` | - |
| `args` | 1272 | 96 | 1 | `[96]u8` | - |
| `description` | 1368 | 80 | 1 | `[80]u8` | - |

### `ServiceControlRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `registration_id` | 0 | 8 | 8 | `u64` | - |
| `start_generation` | 8 | 8 | 8 | `u64` | - |
| `process` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `operation` | 32 | 4 | 4 | `u32` | - |
| `mode` | 36 | 4 | 4 | `u32` | - |
| `timeout_ticks` | 40 | 8 | 8 | `u64` | - |

### `GuiGradientPaint`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `stop_count` | 12 | 4 | 4 | `u32` | - |
| `start_x_bits` | 16 | 4 | 4 | `u32` | - |
| `start_y_bits` | 20 | 4 | 4 | `u32` | - |
| `end_x_bits` | 24 | 4 | 4 | `u32` | - |
| `end_y_bits` | 28 | 4 | 4 | `u32` | - |

### `GuiGradientStop`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `position_bits` | 0 | 4 | 4 | `u32` | - |
| `argb` | 4 | 4 | 4 | `u32` | - |

### `GuiWindowAppearance`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `window` | 0 | 32 | 8 | `GuiPointerWindowIdentity` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `title_background` | 36 | 4 | 4 | `u32` | - |
| `title_foreground` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |

### `FileIdentity2`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `mount_generation` | 0 | 8 | 8 | `u64` | - |
| `namespace_generation` | 8 | 8 | 8 | `u64` | - |
| `object_hi` | 16 | 8 | 8 | `u64` | - |
| `object_lo` | 24 | 8 | 8 | `u64` | - |
| `mount_slot` | 32 | 4 | 4 | `u32` | - |
| `provider` | 36 | 4 | 4 | `u32` | - |
| `flags` | 40 | 4 | 4 | `u32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |

### `FileMetadata2`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `identity` | 8 | 48 | 8 | `FileIdentity2` | - |
| `byte_size` | 56 | 8 | 8 | `u64` | - |
| `content_revision` | 64 | 8 | 8 | `u64` | - |
| `backend_node` | 72 | 8 | 8 | `u64` | - |
| `flags` | 80 | 4 | 4 | `u32` | - |
| `attributes` | 84 | 4 | 4 | `u32` | - |
| `drive_letter` | 88 | 4 | 4 | `u32` | - |
| `reserved0` | 92 | 4 | 4 | `u32` | - |
| `created_time` | 96 | 2 | 2 | `u16` | - |
| `created_date` | 98 | 2 | 2 | `u16` | - |
| `access_date` | 100 | 2 | 2 | `u16` | - |
| `modified_time` | 102 | 2 | 2 | `u16` | - |
| `modified_date` | 104 | 2 | 2 | `u16` | - |
| `reserved1` | 106 | 6 | 2 | `[3]u16` | - |

### `DirectoryMetadataEntry2`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1136 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `info` | 0 | 112 | 8 | `FileMetadata2` | - |
| `path` | 112 | 1024 | 1 | `[1024]u8` | - |

### `DirectoryMetadataCursor2`

- Quelle: `API/ApiContract.json`
- Klasse: `extensible`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 2184 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `namespace_generation` | 8 | 8 | 8 | `u64` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `scan` | 24 | 2160 | 8 | `DirectoryBatchCursor` | - |

### `FontAdvance2`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 8 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `byte_end` | 0 | 4 | 4 | `u32` | - |
| `prefix_width` | 4 | 4 | 4 | `u32` | - |

### `FontAdvanceInfo2`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `font_revision` | 8 | 8 | 8 | `u64` | - |
| `font_id` | 16 | 4 | 4 | `u32` | - |
| `text_bytes` | 20 | 4 | 4 | `u32` | - |
| `count` | 24 | 4 | 4 | `u32` | - |
| `required_count` | 28 | 4 | 4 | `u32` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `reserved0` | 36 | 4 | 4 | `u32` | - |

### `WaitSource`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `object` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `observed_revision` | 32 | 8 | 8 | `u64` | - |
| `user_tag` | 40 | 8 | 8 | `u64` | - |
| `deadline_ns` | 48 | 8 | 8 | `u64` | - |
| `clock_source` | 56 | 4 | 4 | `u32` | - |
| `clock_generation` | 60 | 4 | 4 | `u32` | - |
| `event_backend` | 64 | 4 | 4 | `u32` | - |
| `tick_hz` | 68 | 4 | 4 | `u32` | - |
| `reserved0` | 72 | 8 | 8 | `u64` | - |

### `WaitSetDeadline`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `absolute_ns` | 16 | 8 | 8 | `u64` | - |
| `last_ns` | 24 | 8 | 8 | `u64` | - |
| `clock_source` | 32 | 4 | 4 | `u32` | - |
| `clock_generation` | 36 | 4 | 4 | `u32` | - |
| `event_backend` | 40 | 4 | 4 | `u32` | - |
| `tick_hz` | 44 | 4 | 4 | `u32` | - |

### `WaitSetEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `registration` | 16 | 8 | 8 | `u64` | - |
| `user_tag` | 24 | 8 | 8 | `u64` | - |
| `revision` | 32 | 8 | 8 | `u64` | - |
| `status` | 40 | 4 | 4 | `i32` | - |
| `reserved0` | 44 | 4 | 4 | `u32` | - |

### `WaitSetBatch`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `outcome` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `count` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `configuration_revision` | 24 | 8 | 8 | `u64` | - |
| `next_registration` | 32 | 8 | 8 | `u64` | - |

### `WaitSourceRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 64 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `object` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `scope_id` | 32 | 8 | 8 | `u64` | - |
| `scope_generation` | 40 | 8 | 8 | `u64` | - |
| `user_tag` | 48 | 8 | 8 | `u64` | - |
| `observed_revision` | 56 | 8 | 8 | `u64` | - |

### `ClipboardOfferInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `revision` | 16 | 8 | 8 | `u64` | - |
| `max_offer_bytes` | 24 | 8 | 8 | `u64` | - |
| `payload_budget` | 32 | 8 | 8 | `u64` | - |
| `lease_ns` | 40 | 8 | 8 | `u64` | - |
| `max_items` | 48 | 4 | 4 | `u32` | - |
| `max_formats` | 52 | 4 | 4 | `u32` | - |
| `max_stages` | 56 | 4 | 4 | `u32` | - |
| `max_snapshots` | 60 | 4 | 4 | `u32` | - |
| `put_chunk` | 64 | 4 | 4 | `u32` | - |
| `read_chunk` | 68 | 4 | 4 | `u32` | - |
| `format_mask` | 72 | 4 | 4 | `u32` | - |
| `flags` | 76 | 4 | 4 | `u32` | - |

### `ClipboardOfferBegin`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `expected_revision` | 16 | 8 | 8 | `u64` | - |
| `total_bytes` | 24 | 8 | 8 | `u64` | - |

### `ClipboardOfferLease`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `id` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 8 | 8 | `u64` | - |
| `expires_ns` | 32 | 8 | 8 | `u64` | - |
| `state` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |

### `ClipboardOfferFormat`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `item` | 0 | 4 | 4 | `u32` | - |
| `format` | 4 | 4 | 4 | `u32` | - |
| `total_bytes` | 8 | 8 | 8 | `u64` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |

### `ClipboardOfferTransfer`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `id` | 16 | 8 | 8 | `u64` | - |
| `item` | 24 | 4 | 4 | `u32` | - |
| `format` | 28 | 4 | 4 | `u32` | - |
| `offset` | 32 | 8 | 8 | `u64` | - |
| `total_bytes` | 40 | 8 | 8 | `u64` | - |

### `ClipboardOfferEnumerate`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `id` | 16 | 8 | 8 | `u64` | - |
| `cursor` | 24 | 4 | 4 | `u32` | - |
| `capacity` | 28 | 4 | 4 | `u32` | - |

### `ClipboardOfferPage`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `id` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 8 | 8 | `u64` | - |
| `next` | 32 | 4 | 4 | `u32` | - |
| `count` | 36 | 4 | 4 | `u32` | - |
| `total` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |

### `ClipboardOfferChunk`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `id` | 16 | 8 | 8 | `u64` | - |
| `revision` | 24 | 8 | 8 | `u64` | - |
| `offset` | 32 | 8 | 8 | `u64` | - |
| `total_bytes` | 40 | 8 | 8 | `u64` | - |
| `bytes` | 48 | 4 | 4 | `u32` | - |
| `flags` | 52 | 4 | 4 | `u32` | - |

### `NetworkAddress`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `family` | 0 | 2 | 2 | `u16` | - |
| `reserved0` | 2 | 2 | 2 | `u16` | - |
| `scope_id` | 4 | 4 | 4 | `u32` | - |
| `interface_id` | 8 | 4 | 4 | `u32` | - |
| `reserved1` | 12 | 4 | 4 | `u32` | - |
| `bytes` | 16 | 16 | 1 | `[16]u8` | - |

### `NetworkEndpoint`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `address` | 0 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `port` | 32 | 2 | 2 | `u16` | - |
| `reserved` | 34 | 2 | 2 | `u16` | - |
| `flags` | 36 | 4 | 4 | `u32` | - |

### `NetworkDeadline`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `reserved0` | 12 | 4 | 4 | `u32` | - |
| `absolute_ns` | 16 | 8 | 8 | `u64` | - |
| `last_ns` | 24 | 8 | 8 | `u64` | - |
| `clock_source` | 32 | 4 | 4 | `u32` | - |
| `clock_generation` | 36 | 4 | 4 | `u32` | - |
| `event_backend` | 40 | 4 | 4 | `u32` | - |
| `tick_hz` | 44 | 4 | 4 | `u32` | - |

### `NetworkProviderInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `capabilities` | 16 | 8 | 8 | `u64` | - |
| `max_send` | 24 | 4 | 4 | `u32` | - |
| `max_recv` | 28 | 4 | 4 | `u32` | - |
| `max_answers` | 32 | 4 | 4 | `u32` | - |
| `page_capacity` | 36 | 4 | 4 | `u32` | - |
| `interface_id` | 40 | 4 | 4 | `u32` | - |
| `reserved` | 44 | 4 | 4 | `u32` | - |

### `NetworkSocketRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `socket` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `endpoint` | 32 | 40 | 4 | `r4os.abi.NetworkEndpoint` | - |
| `deadline` | 72 | 48 | 8 | `r4os.abi.NetworkDeadline` | - |
| `flags` | 120 | 4 | 4 | `u32` | - |
| `bytes` | 124 | 4 | 4 | `u32` | - |

### `NetworkSocketResult`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `socket` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `endpoint` | 32 | 40 | 4 | `r4os.abi.NetworkEndpoint` | - |
| `bytes` | 72 | 4 | 4 | `u32` | - |
| `original_bytes` | 76 | 4 | 4 | `u32` | - |
| `state` | 80 | 4 | 4 | `u32` | - |
| `flags` | 84 | 4 | 4 | `u32` | - |

### `NetworkResolveRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 392 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `query` | 16 | 8 | 8 | `u64` | - |
| `deadline` | 24 | 48 | 8 | `r4os.abi.NetworkDeadline` | - |
| `family` | 72 | 4 | 4 | `u32` | - |
| `policy` | 76 | 4 | 4 | `u32` | - |
| `cursor` | 80 | 4 | 4 | `u32` | - |
| `capacity` | 84 | 4 | 4 | `u32` | - |
| `server` | 88 | 40 | 4 | `r4os.abi.NetworkEndpoint` | - |
| `name_len` | 128 | 4 | 4 | `u32` | - |
| `reserved` | 132 | 4 | 4 | `u32` | - |
| `name` | 136 | 256 | 1 | `[256]u8` | - |

### `NetworkResolvePage`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `query` | 16 | 8 | 8 | `u64` | - |
| `expires_ns` | 24 | 8 | 8 | `u64` | - |
| `next` | 32 | 4 | 4 | `u32` | - |
| `count` | 36 | 4 | 4 | `u32` | - |
| `total` | 40 | 4 | 4 | `u32` | - |
| `flags` | 44 | 4 | 4 | `u32` | - |

### `NetworkResolveAnswer`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `address` | 0 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `ttl_seconds` | 32 | 4 | 4 | `u32` | - |
| `reserved` | 36 | 4 | 4 | `u32` | - |

### `NetworkLinkRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1576 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `op` | 8 | 4 | 4 | `u32` | - |
| `index` | 12 | 4 | 4 | `u32` | - |
| `interface_id` | 16 | 4 | 4 | `u32` | - |
| `reserved0` | 20 | 4 | 4 | `u32` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `bytes` | 32 | 4 | 4 | `u32` | - |
| `reserved1` | 36 | 4 | 4 | `u32` | - |
| `frame` | 40 | 1536 | 1 | `[1536]u8` | - |

### `NetworkLinkInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 128 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `index` | 8 | 4 | 4 | `u32` | - |
| `interface_id` | 12 | 4 | 4 | `u32` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `provider` | 24 | 8 | 8 | `u64` | - |
| `mtu` | 32 | 4 | 4 | `u32` | - |
| `flags` | 36 | 4 | 4 | `u32` | - |
| `mac` | 40 | 6 | 1 | `[6]u8` | - |
| `reserved` | 46 | 2 | 2 | `u16` | - |
| `clock` | 48 | 80 | 8 | `r4os.abi.MonotonicClockInfo` | - |

### `Ipv6FrameOp`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1680 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `link` | 8 | 128 | 8 | `r4os.abi.NetworkLinkInfo` | - |
| `bytes` | 136 | 4 | 4 | `u32` | - |
| `reserved` | 140 | 4 | 4 | `u32` | - |
| `frame` | 144 | 1536 | 1 | `[1536]u8` | - |

### `Ipv6InterfaceQuery`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `index` | 8 | 4 | 4 | `u32` | - |
| `interface_id` | 12 | 4 | 4 | `u32` | - |
| `provider` | 16 | 8 | 8 | `u64` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `cursor` | 32 | 4 | 4 | `u32` | - |
| `reserved` | 36 | 4 | 4 | `u32` | - |

### `Ipv6InterfaceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 296 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `link` | 8 | 128 | 8 | `r4os.abi.NetworkLinkInfo` | - |
| `revision` | 136 | 8 | 8 | `u64` | - |
| `capabilities` | 144 | 8 | 8 | `u64` | - |
| `address_count` | 152 | 4 | 4 | `u32` | - |
| `route_count` | 156 | 4 | 4 | `u32` | - |
| `max_packet` | 160 | 4 | 4 | `u32` | - |
| `reserved` | 164 | 4 | 4 | `u32` | - |
| `link_local` | 168 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `preferred` | 200 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `default_router` | 232 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `next_due_ns` | 264 | 8 | 8 | `u64` | - |
| `rx_packets` | 272 | 8 | 8 | `u64` | - |
| `tx_packets` | 280 | 8 | 8 | `u64` | - |
| `dropped_packets` | 288 | 8 | 8 | `u64` | - |

### `Ipv6AddressInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 80 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `address` | 8 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `provider` | 40 | 8 | 8 | `u64` | - |
| `generation` | 48 | 8 | 8 | `u64` | - |
| `preferred_until_ns` | 56 | 8 | 8 | `u64` | - |
| `valid_until_ns` | 64 | 8 | 8 | `u64` | - |
| `flags` | 72 | 4 | 4 | `u32` | - |
| `prefix_length` | 76 | 4 | 4 | `u32` | - |

### `Ipv6RouteInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `prefix` | 8 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `gateway` | 40 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `provider` | 72 | 8 | 8 | `u64` | - |
| `generation` | 80 | 8 | 8 | `u64` | - |
| `valid_until_ns` | 88 | 8 | 8 | `u64` | - |
| `prefix_length` | 96 | 4 | 4 | `u32` | - |
| `metric` | 100 | 4 | 4 | `u32` | - |
| `flags` | 104 | 4 | 4 | `u32` | - |
| `reserved` | 108 | 4 | 4 | `u32` | - |

### `Ipv6AddressConfig`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 88 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `interface_id` | 24 | 4 | 4 | `u32` | - |
| `flags` | 28 | 4 | 4 | `u32` | - |
| `address` | 32 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `prefix_length` | 64 | 4 | 4 | `u32` | - |
| `reserved` | 68 | 4 | 4 | `u32` | - |
| `preferred_lifetime_ns` | 72 | 8 | 8 | `u64` | - |
| `valid_lifetime_ns` | 80 | 8 | 8 | `u64` | - |

### `Ipv6Packet`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1656 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `source` | 24 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `destination` | 56 | 32 | 4 | `r4os.abi.NetworkAddress` | - |
| `deadline` | 88 | 48 | 8 | `r4os.abi.NetworkDeadline` | - |
| `next_header` | 136 | 4 | 4 | `u32` | - |
| `bytes` | 140 | 4 | 4 | `u32` | - |
| `flags` | 144 | 4 | 4 | `u32` | - |
| `reserved` | 148 | 4 | 4 | `u32` | - |
| `payload` | 152 | 1504 | 1 | `[1504]u8` | - |

### `Icmpv6Message`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1576 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `source` | 8 | 16 | 1 | `[16]u8` | - |
| `destination` | 24 | 16 | 1 | `[16]u8` | - |
| `reply_source` | 40 | 16 | 1 | `[16]u8` | - |
| `bytes` | 56 | 4 | 4 | `u32` | - |
| `flags` | 60 | 4 | 4 | `u32` | - |
| `next_header` | 64 | 4 | 4 | `u32` | - |
| `checksum` | 68 | 4 | 4 | `u32` | - |
| `payload` | 72 | 1504 | 1 | `[1504]u8` | - |

### `NdpPrefix`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `bytes` | 0 | 16 | 1 | `[16]u8` | - |
| `flags` | 16 | 4 | 4 | `u32` | - |
| `valid_lifetime_seconds` | 20 | 4 | 4 | `u32` | - |
| `preferred_lifetime_seconds` | 24 | 4 | 4 | `u32` | - |
| `prefix_length` | 28 | 4 | 4 | `u32` | - |

### `NdpRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 1608 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `interface_id` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |
| `now_ns` | 24 | 8 | 8 | `u64` | - |
| `clock_generation` | 32 | 4 | 4 | `u32` | - |
| `reserved` | 36 | 4 | 4 | `u32` | - |
| `source` | 40 | 16 | 1 | `[16]u8` | - |
| `destination` | 56 | 16 | 1 | `[16]u8` | - |
| `target` | 72 | 16 | 1 | `[16]u8` | - |
| `mac` | 88 | 6 | 1 | `[6]u8` | - |
| `reserved1` | 94 | 2 | 2 | `u16` | - |
| `hop_limit` | 96 | 4 | 4 | `u32` | - |
| `bytes` | 100 | 4 | 4 | `u32` | - |
| `payload` | 104 | 1504 | 1 | `[1504]u8` | - |

### `NdpEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 328 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `kind` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `target` | 16 | 16 | 1 | `[16]u8` | - |
| `mac` | 32 | 6 | 1 | `[6]u8` | - |
| `reserved0` | 38 | 2 | 2 | `u16` | - |
| `router_lifetime_seconds` | 40 | 4 | 4 | `u32` | - |
| `reachable_ms` | 44 | 4 | 4 | `u32` | - |
| `retransmit_ms` | 48 | 4 | 4 | `u32` | - |
| `mtu` | 52 | 4 | 4 | `u32` | - |
| `prefix_count` | 56 | 4 | 4 | `u32` | - |
| `reserved1` | 60 | 4 | 4 | `u32` | - |
| `prefixes` | 64 | 256 | 4 | `[8]r4os.abi.NdpPrefix` | - |
| `nonce` | 320 | 6 | 1 | `[6]u8` | - |
| `reserved2` | 326 | 2 | 2 | `u16` | - |

### `NdpInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `active_links` | 16 | 4 | 4 | `u32` | - |
| `max_links` | 20 | 4 | 4 | `u32` | - |
| `active_neighbors` | 24 | 4 | 4 | `u32` | - |
| `max_neighbors` | 28 | 4 | 4 | `u32` | - |
| `probes` | 32 | 4 | 4 | `u32` | - |
| `timeouts` | 36 | 4 | 4 | `u32` | - |
| `flags` | 40 | 8 | 8 | `u64` | - |

### `NetworkTransportRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 176 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 8 | 8 | `u64` | - |
| `broker` | 16 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `owner` | 32 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `request` | 48 | 128 | 8 | `r4os.abi.NetworkSocketRequest` | - |

### `BytePipeEnd`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `handle` | 0 | 8 | 8 | `u64` | - |
| `generation` | 8 | 8 | 8 | `u64` | - |
| `direction` | 16 | 4 | 4 | `u32` | - |
| `reserved` | 20 | 4 | 4 | `u32` | - |

### `BytePipePair`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `reader` | 8 | 24 | 8 | `r4os.abi.BytePipeEnd` | - |
| `writer` | 32 | 24 | 8 | `r4os.abi.BytePipeEnd` | - |

### `BytePipeProgress`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `bytes` | 8 | 8 | 8 | `u64` | - |
| `state` | 16 | 4 | 4 | `u32` | - |
| `flags` | 20 | 4 | 4 | `u32` | - |

### `BytePipeInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `capacity` | 8 | 8 | 8 | `u64` | - |
| `queued` | 16 | 8 | 8 | `u64` | - |
| `readers` | 24 | 4 | 4 | `u32` | - |
| `writers` | 28 | 4 | 4 | `u32` | - |
| `atomic_limit` | 32 | 8 | 8 | `u64` | - |
| `max_step` | 40 | 8 | 8 | `u64` | - |

### `LaunchIoBinding`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 32 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `kind` | 0 | 4 | 4 | `u32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `end` | 8 | 24 | 8 | `r4os.abi.BytePipeEnd` | - |

### `LaunchIo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `policy` | 8 | 4 | 4 | `u32` | - |
| `console_host` | 12 | 4 | 4 | `u32` | - |
| `stdin_binding` | 16 | 32 | 8 | `r4os.abi.LaunchIoBinding` | - |
| `stdout_binding` | 48 | 32 | 8 | `r4os.abi.LaunchIoBinding` | - |
| `stderr_binding` | 80 | 32 | 8 | `r4os.abi.LaunchIoBinding` | - |

### `Utf8ByteRange`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 16 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `start` | 0 | 8 | 8 | `u64` | - |
| `end` | 8 | 8 | 8 | `u64` | - |

### `CompositionCaret`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `x` | 0 | 4 | 4 | `i32` | - |
| `y` | 4 | 4 | 4 | `i32` | - |
| `width` | 8 | 4 | 4 | `u32` | - |
| `height` | 12 | 4 | 4 | `u32` | - |
| `scale_numerator` | 16 | 4 | 4 | `u32` | - |
| `scale_denominator` | 20 | 4 | 4 | `u32` | - |

### `CompositionProvider`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 40 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `process` | 8 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `generation` | 24 | 8 | 8 | `u64` | - |
| `features` | 32 | 4 | 4 | `u32` | - |
| `max_text_bytes` | 36 | 4 | 4 | `u32` | - |

### `CompositionFocus`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `window` | 8 | 64 | 8 | `r4os.abi.WindowModeIdentity` | - |
| `view_generation` | 72 | 8 | 8 | `u64` | - |
| `focus_generation` | 80 | 8 | 8 | `u64` | - |
| `input_revision` | 88 | 8 | 8 | `u64` | - |
| `observed_tick` | 96 | 8 | 8 | `u64` | - |
| `focused` | 104 | 4 | 4 | `u32` | - |
| `reserved` | 108 | 4 | 4 | `u32` | - |

### `CompositionId`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `window` | 0 | 64 | 8 | `r4os.abi.WindowModeIdentity` | - |
| `view_generation` | 64 | 8 | 8 | `u64` | - |
| `focus_generation` | 72 | 8 | 8 | `u64` | - |
| `owner_generation` | 80 | 8 | 8 | `u64` | - |
| `session_generation` | 88 | 8 | 8 | `u64` | - |
| `provider` | 96 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `provider_generation` | 112 | 8 | 8 | `u64` | - |

### `CompositionEvent`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 184 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `id` | 8 | 120 | 8 | `r4os.abi.CompositionId` | - |
| `sequence` | 128 | 8 | 8 | `u64` | - |
| `text_revision` | 136 | 8 | 8 | `u64` | - |
| `replacement` | 144 | 16 | 8 | `r4os.abi.Utf8ByteRange` | - |
| `selection` | 160 | 16 | 8 | `r4os.abi.Utf8ByteRange` | - |
| `kind` | 176 | 4 | 4 | `u32` | - |
| `text_bytes` | 180 | 4 | 4 | `u32` | - |

### `CompositionFocusReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 120 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `result` | 0 | 4 | 4 | `i32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `focus` | 8 | 112 | 8 | `r4os.abi.CompositionFocus` | - |

### `CompositionCapabilityReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 48 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `result` | 0 | 4 | 4 | `i32` | - |
| `reserved` | 4 | 4 | 4 | `u32` | - |
| `provider` | 8 | 40 | 8 | `r4os.abi.CompositionProvider` | - |

### `AudioCaptureSourceId`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 24 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `registration` | 0 | 8 | 8 | `u64` | - |
| `source` | 8 | 8 | 8 | `u64` | - |
| `generation` | 16 | 8 | 8 | `u64` | - |

### `AudioCaptureFormat`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 12 / 4

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `rate_hz` | 0 | 4 | 4 | `u32` | - |
| `channels` | 4 | 2 | 2 | `u16` | - |
| `sample_format` | 6 | 2 | 2 | `u16` | - |
| `frame_bytes` | 8 | 4 | 4 | `u32` | - |

### `AudioCaptureHandle`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 56 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `service` | 0 | 16 | 8 | `r4os.abi.ProgramProcessHandle` | - |
| `source` | 16 | 24 | 8 | `r4os.abi.AudioCaptureSourceId` | - |
| `stream` | 40 | 8 | 8 | `u64` | - |
| `generation` | 48 | 8 | 8 | `u64` | - |

### `AudioCaptureSourceInfo`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 112 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `id` | 8 | 24 | 8 | `r4os.abi.AudioCaptureSourceId` | - |
| `flags` | 32 | 4 | 4 | `u32` | - |
| `formats` | 36 | 4 | 4 | `u32` | - |
| `min_rate` | 40 | 4 | 4 | `u32` | - |
| `max_rate` | 44 | 4 | 4 | `u32` | - |
| `min_channels` | 48 | 2 | 2 | `u16` | - |
| `max_channels` | 50 | 2 | 2 | `u16` | - |
| `max_queue_frames` | 52 | 4 | 4 | `u32` | - |
| `clock_id` | 56 | 8 | 8 | `u64` | - |
| `clock_generation` | 64 | 8 | 8 | `u64` | - |
| `clock_frequency` | 72 | 8 | 8 | `u64` | - |
| `name` | 80 | 32 | 1 | `[32]u8` | - |

### `AudioCaptureRequest`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 104 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `op` | 8 | 4 | 4 | `u32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `handle` | 16 | 56 | 8 | `r4os.abi.AudioCaptureHandle` | - |
| `format` | 72 | 12 | 4 | `r4os.abi.AudioCaptureFormat` | - |
| `queue_frames` | 84 | 4 | 4 | `u32` | - |
| `frames` | 88 | 4 | 4 | `u32` | - |
| `buffer_bytes` | 92 | 4 | 4 | `u32` | - |
| `client_generation` | 96 | 8 | 8 | `u64` | - |

### `AudioCaptureReply`

- Quelle: `API/ApiContract.json`
- Klasse: `fixed_layout`
- Repräsentation: `extern_struct`
- Version/Größe/Alignment: 1 / 248 / 8

| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |
|---|---:|---:|---:|---|---|
| `version` | 0 | 4 | 4 | `u32` | - |
| `size` | 4 | 4 | 4 | `u32` | - |
| `result` | 8 | 4 | 4 | `i32` | - |
| `flags` | 12 | 4 | 4 | `u32` | - |
| `handle` | 16 | 56 | 8 | `r4os.abi.AudioCaptureHandle` | - |
| `source` | 72 | 112 | 8 | `r4os.abi.AudioCaptureSourceInfo` | - |
| `format` | 184 | 12 | 4 | `r4os.abi.AudioCaptureFormat` | - |
| `state` | 196 | 4 | 4 | `u32` | - |
| `queued_frames` | 200 | 4 | 4 | `u32` | - |
| `frames` | 204 | 4 | 4 | `u32` | - |
| `first_frame` | 208 | 8 | 8 | `u64` | - |
| `first_timestamp` | 216 | 8 | 8 | `u64` | - |
| `overrun_frames` | 224 | 8 | 8 | `u64` | - |
| `gap_frames` | 232 | 8 | 8 | `u64` | - |
| `bytes` | 240 | 4 | 4 | `u32` | - |
| `reserved` | 244 | 4 | 4 | `u32` | - |

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
| `driver_work_result_continue` | -8 | `i32` |
| `driver_work_result_wait` | -9 | `i32` |

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
| `file_stream_error_name_not_supported` | -64 | `i32` |
| `file_stream_error_name_too_long` | -65 | `i32` |

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
| `service_api_result_memory` | -20 | `i32` |
| `service_api_result_exhausted` | -21 | `i32` |
| `service_api_result_restart` | -22 | `i32` |

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

### `serial`

Geltung: `serial`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `serial_ok` | 0 | `i32` |
| `serial_error_invalid` | -1 | `i32` |
| `serial_error_not_found` | -2 | `i32` |
| `serial_error_busy` | -3 | `i32` |
| `serial_error_closed` | -4 | `i32` |
| `serial_error_stale` | -5 | `i32` |
| `serial_error_timeout` | -6 | `i32` |
| `serial_error_cancelled` | -7 | `i32` |
| `serial_error_no_memory` | -8 | `i32` |
| `serial_error_hardware` | -9 | `i32` |
| `serial_error_unsupported` | -10 | `i32` |
| `serial_error_overflow` | -11 | `i32` |
| `serial_error_would_block` | -12 | `i32` |
| `serial_error_owner` | -13 | `i32` |
| `serial_error_too_large` | -14 | `i32` |

### `device_snapshot`

Geltung: `device_snapshot`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `device_snapshot_result_ok` | 0 | `i32` |
| `device_snapshot_result_invalid` | -1 | `i32` |
| `device_snapshot_result_capacity` | -2 | `i32` |
| `device_snapshot_result_overflow` | -3 | `i32` |
| `device_snapshot_result_exhausted` | -4 | `i32` |
| `device_snapshot_result_no_memory` | -8 | `i32` |

### `file_metadata2`

Geltung: `file_metadata2`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `file_metadata2_result_found` | 1 | `i32` |
| `file_metadata2_result_missing` | 0 | `i32` |
| `file_metadata2_error_invalid` | -1 | `i32` |
| `file_metadata2_error_no_mount` | -3 | `i32` |
| `file_metadata2_result_end` | -5 | `i32` |
| `file_metadata2_error_path_bounds` | -7 | `i32` |
| `file_metadata2_error_io` | -9 | `i32` |
| `file_metadata2_error_restart` | -10 | `i32` |
| `file_metadata_error_unrepresentable` | -11 | `i32` |
| `file_metadata2_error_namespace_exhausted` | -12 | `i32` |
| `file_metadata2_error_unsupported` | -13 | `i32` |

### `font_metrics2`

Geltung: `font_metrics2`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `font_metrics2_ok` | 0 | `i32` |
| `font_metrics2_invalid` | -1 | `i32` |
| `font_metrics2_font` | -2 | `i32` |
| `font_metrics2_encoding` | -5 | `i32` |
| `font_metrics2_overflow` | -6 | `i32` |
| `font_metrics2_capacity` | -7 | `i32` |
| `font_metrics2_unavailable` | -9 | `i32` |
| `font_metrics2_stale` | -10 | `i32` |
| `font_metrics2_exhausted` | -12 | `i32` |

### `waitset`

Geltung: `waitset`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `waitset_ok` | 0 | `i32` |
| `waitset_error_invalid` | -13001 | `i32` |
| `waitset_error_context` | -13002 | `i32` |
| `waitset_error_stale` | -13003 | `i32` |
| `waitset_error_closed` | -13004 | `i32` |
| `waitset_error_capacity` | -13005 | `i32` |
| `waitset_error_busy` | -13006 | `i32` |
| `waitset_error_clock_unavailable` | -13007 | `i32` |
| `waitset_error_clock_changed` | -13008 | `i32` |
| `waitset_error_memory` | -13009 | `i32` |
| `waitset_error_exhausted` | -13010 | `i32` |
| `waitset_error_unsupported` | -13011 | `i32` |
| `waitset_error_release` | -13012 | `i32` |
| `waitset_error_owner` | -13013 | `i32` |
| `waitset_error_overflow` | -13014 | `i32` |

### `byte_pipe`

Geltung: `byte_pipe`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `byte_pipe_ok` | 0 | `i32` |
| `byte_pipe_error_invalid` | -14001 | `i32` |
| `byte_pipe_error_context` | -14002 | `i32` |
| `byte_pipe_error_stale` | -14003 | `i32` |
| `byte_pipe_error_owner` | -14004 | `i32` |
| `byte_pipe_error_direction` | -14005 | `i32` |
| `byte_pipe_error_capacity` | -14006 | `i32` |
| `byte_pipe_error_memory` | -14007 | `i32` |
| `byte_pipe_error_release` | -14008 | `i32` |
| `byte_pipe_error_exhausted` | -14009 | `i32` |
| `byte_pipe_error_clock_unavailable` | -14010 | `i32` |
| `byte_pipe_error_clock_changed` | -14011 | `i32` |
| `byte_pipe_error_unsupported` | -14012 | `i32` |

### `launch_io`

Geltung: `launch_io`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `launch_io_ok` | 0 | `i32` |
| `launch_io_error_invalid` | -15001 | `i32` |
| `launch_io_error_context` | -15002 | `i32` |
| `launch_io_error_stale` | -15003 | `i32` |
| `launch_io_error_owner` | -15004 | `i32` |
| `launch_io_error_direction` | -15005 | `i32` |
| `launch_io_error_capacity` | -15006 | `i32` |
| `launch_io_error_memory` | -15007 | `i32` |
| `launch_io_error_release` | -15008 | `i32` |
| `launch_io_error_exhausted` | -15009 | `i32` |
| `launch_io_error_unsupported` | -15010 | `i32` |
| `launch_io_error_not_found` | -15011 | `i32` |
| `launch_io_error_load` | -15012 | `i32` |
| `launch_io_error_start` | -15013 | `i32` |
| `launch_io_error_busy` | -15014 | `i32` |

### `composition`

Geltung: `composition`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `composition_ok` | 0 | `i32` |
| `composition_error_invalid` | -16001 | `i32` |
| `composition_error_encoding` | -16002 | `i32` |
| `composition_error_range` | -16003 | `i32` |
| `composition_error_capacity` | -16004 | `i32` |
| `composition_error_stale_session` | -16005 | `i32` |
| `composition_error_stale_text` | -16006 | `i32` |
| `composition_error_stale_view` | -16007 | `i32` |
| `composition_error_no_focus` | -16008 | `i32` |
| `composition_error_provider_changed` | -16009 | `i32` |
| `composition_error_exhausted` | -16010 | `i32` |
| `composition_error_no_provider` | -16011 | `i32` |
| `composition_error_unsupported` | -16012 | `i32` |

### `audio_capture`

Geltung: `audio_capture`, Einheit: `status_code`, Stabilität: `fixed_contract`.

| Name | Wert | Typ |
|---|---:|---|
| `audio_capture_ok` | 0 | `i32` |
| `audio_capture_error_unsupported` | -17001 | `i32` |
| `audio_capture_error_invalid` | -17002 | `i32` |
| `audio_capture_error_format` | -17003 | `i32` |
| `audio_capture_error_source_gone` | -17004 | `i32` |
| `audio_capture_error_would_block` | -17005 | `i32` |
| `audio_capture_error_timed_out` | -17006 | `i32` |
| `audio_capture_error_cancelled` | -17007 | `i32` |
| `audio_capture_error_capacity` | -17008 | `i32` |
| `audio_capture_error_stale` | -17009 | `i32` |
| `audio_capture_error_busy` | -17010 | `i32` |
| `audio_capture_error_clock_changed` | -17011 | `i32` |
| `audio_capture_error_exhausted` | -17012 | `i32` |
| `audio_capture_error_provider` | -17013 | `i32` |
| `audio_capture_error_unknown_outcome` | -17014 | `i32` |
| `audio_capture_error_overrun` | -17015 | `i32` |

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
| `audio_service_flag_duration_unavailable` | `16` | `u32` | flag | bitmask | `audio_service` | fixed_contract |
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
| `driver_api_version` | `39` | `u32` | version | number | `driver_api` | fixed_contract |
| `driver_api_thread_work_version` | `35` | `u32` | version | number | `driver_api` | fixed_contract |
| `driver_api_continuation_work_version` | `38` | `u32` | version | number | `driver_api` | fixed_contract |
| `driver_magic` | `826888260` | `u32` | magic | number | `driver` | fixed_contract |
| `driver_work_flag_from_irq` | `1` | `u32` | flag | bitmask | `driver_work` | fixed_contract |
| `driver_work_flag_continuation` | `2` | `u32` | flag | bitmask | `driver_work` | fixed_contract |
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
| `program_instance_flag_desktop_host` | `8` | `u8` | value | bit | `program_inventory` | fixed_contract |
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
| `r4xstart_r4audio_version` | `2` | `u32` | version | number | `r4xstart_r4audio` | fixed_contract |
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
| `file_update_atomic_checked_flag_long_stage` | `16` | `u32` | flag | bitmask | `file_update_atomic_checked` | fixed_contract |
| `vm_commit_resident_max_bytes` | `262144` | `u64` | value | bytes | `vm_commit` | fixed_contract |
| `audio_backend_outputs_version` | `3` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_backend_idle_version` | `4` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_kind_line_out` | `0` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_kind_speaker` | `1` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_kind_headphone` | `2` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_kind_hdmi` | `3` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_kind_display_port` | `4` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_unavailable` | `0` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_available` | `1` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_waiting_for_eld` | `2` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_invalid_eld` | `3` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_unsupported` | `4` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_failed` | `5` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_output_flag_active` | `1` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_service_op_outputs` | `9` | `u16` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_service_op_select_output` | `10` | `u16` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_control_magic` | `1329673298` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_preferred` | `0` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_auto_hdmi` | `1` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_auto_analog` | `2` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_preferred_unavailable` | `3` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_none_available` | `4` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_activation_failed` | `5` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_api_unavailable` | `6` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_reason_catalog_busy` | `7` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_state_flag_persist_pending` | `1` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `audio_output_state_flag_config_error` | `2` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `display_state_unavailable` | `0` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_bootfb` | `1` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_preparing` | `2` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_native` | `3` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_software_native` | `4` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_recovering` | `5` | `u32` | value | number | `display_state` | fixed_contract |
| `display_policy_automatic` | `0` | `u32` | value | number | `display_state` | fixed_contract |
| `display_policy_software` | `1` | `u32` | value | number | `display_state` | fixed_contract |
| `display_policy_software_once` | `2` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_none` | `0` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_no_native_backend` | `1` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_policy_disabled` | `2` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_backend_rejected` | `3` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_prepare_failed` | `4` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_commit_failed` | `5` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_device_lost` | `6` | `u32` | value | number | `display_state` | fixed_contract |
| `display_fallback_restore_failed` | `7` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_cap_cpu_present` | `1` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_cap_native_scanout` | `2` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_cap_firmware_writable` | `4` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_cap_software_fallback` | `8` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_cap_gpu_render` | `16` | `u32` | value | number | `display_state` | fixed_contract |
| `display_state_cap_async_present` | `32` | `u32` | value | number | `display_state` | fixed_contract |
| `display_summary_backend_native` | `2` | `u8` | value | number | `display_state` | fixed_contract |
| `display_mapping_native_scanout` | `2` | `u8` | value | number | `display_state` | fixed_contract |
| `display_present_backend_native_cpu` | `3` | `u32` | value | number | `display_state` | fixed_contract |
| `gfx_buffer_result_ok` | `1` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_invalid` | `-1` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_unavailable` | `-2` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_stale` | `-3` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_busy` | `-4` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_overflow` | `-5` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_unsupported` | `-6` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_oom` | `-7` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_budget` | `-8` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_capacity` | `-9` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_error_closed` | `-10` | `i32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_usage_cpu_read` | `1` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_usage_cpu_write` | `2` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_usage_transfer_source` | `4` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_usage_transfer_target` | `8` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_usage_render` | `16` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_usage_scanout` | `32` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_bytes` | `0` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_xrgb8888` | `875713112` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_argb8888` | `875713089` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_r8` | `538982482` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_nv12` | `842094158` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_p010` | `808530000` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_location_system` | `0` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_location_device_local` | `1` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_map_read` | `0` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_map_write` | `1` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_cache_unavailable` | `0` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_cache_write_back` | `1` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_cache_write_combining` | `2` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_cache_uncached` | `3` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_reference_immutable` | `1` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_reference_mapping_only` | `2` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_queue_ok` | `1` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_invalid` | `-1` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_unavailable` | `-2` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_stale` | `-3` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_busy` | `-4` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_overflow` | `-5` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_unsupported` | `-6` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_oom` | `-7` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_budget` | `-8` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_capacity` | `-9` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_closed` | `-10` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_wait_timeout` | `-11` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_wait_cancelled` | `-12` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_already_completed` | `-13` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_error_device_lost` | `-14` | `i32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_policy_fifo` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_policy_latest_frame` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_milestone_cpu_stores` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_milestone_device_execution` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_milestone_scanout` | `2` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_operation_copy` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_operation_barrier` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_phase_queued` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_phase_running` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_phase_terminal` | `2` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_pending` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_complete` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_cancelled` | `2` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_dropped` | `3` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_device_lost` | `4` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_timeout` | `5` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_failed` | `6` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_result_dependency_failed` | `7` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_flag_device_active` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_flag_resources_held` | `2` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_max_dependencies` | `8` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_capacity` | `32` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_fence_capacity` | `128` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `display_present_cap_cpu_store_completion` | `32` | `u32` | flag | bitmask | `display_present` | fixed_contract |
| `display_present_completion_cpu_stores` | `2` | `u32` | flag | bitmask | `display_present_completion` | fixed_contract |
| `gfx_queue_wait_completion` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_wait_resources_released` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_backend_capacity` | `17` | `u32` | value | count | `gfx_queue` | fixed_contract |
| `gfx_output_ok` | `1` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_invalid` | `-1` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_unavailable` | `-2` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_stale` | `-3` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_busy` | `-4` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_overflow` | `-5` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_unsupported` | `-6` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_capacity` | `-9` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_dependency` | `-15` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_bandwidth` | `-16` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_routing` | `-17` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_output_lost` | `-18` | `i32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_capacity` | `32` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_max_modes` | `64` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_max_edid_bytes` | `4096` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_max_assignments` | `8` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_connected` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_firmware_snapshot` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_active` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_fixed_geometry` | `8` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_connection_unknown` | `16` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_kind_hdmi` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_kind_displayport` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_kind_edp` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_kind_virtual` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_kind_firmware` | `5` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_limit_modeset` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_limit_scaling` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_limit_interlace` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_interlaced` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_h_positive` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_v_positive` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_preferred` | `8` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_420_only` | `16` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_geometry_only` | `32` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_mode_420_allowed` | `64` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_outcome_validated` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_outcome_applied` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_outcome_old_preserved` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_outcome_lost` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_retain_old` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_retain_new` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_queue_operation_upload` | `2` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_device_access_backing` | `4` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `driver_resource_ok` | `0` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_invalid` | `-1` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_owner` | `-2` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_stale` | `-3` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_source` | `-4` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_not_found` | `-5` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_io` | `-6` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_deadline` | `-7` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_error_busy` | `-8` | `i32` | value | number | `driver_resource` | fixed_contract |
| `driver_resource_max_read_bytes` | `65536` | `u32` | value | bytes | `driver_resource` | fixed_contract |
| `driver_heap_ok` | `0` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_invalid` | `-1` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_owner` | `-2` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_stale` | `-3` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_closed` | `-4` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_memory` | `-5` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_busy` | `-6` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_exhausted` | `-7` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_release` | `-8` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_heap_error_overflow` | `-9` | `i32` | value | number | `driver_heap` | fixed_contract |
| `driver_thread_ok` | `0` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_invalid` | `-1` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_owner` | `-2` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_stale` | `-3` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_closed` | `-4` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_memory` | `-5` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_busy` | `-6` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_cancelled` | `-7` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_timeout` | `-8` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_self_join` | `-9` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_context` | `-10` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_exhausted` | `-11` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_error_release` | `-12` | `i32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_flag_parallel` | `1` | `u32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_state_runnable` | `1` | `u32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_state_running` | `2` | `u32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_state_completed` | `3` | `u32` | value | number | `driver_thread` | fixed_contract |
| `driver_semaphore_ok` | `0` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_invalid` | `-1` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_owner` | `-2` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_stale` | `-3` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_closed` | `-4` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_memory` | `-5` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_busy` | `-6` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_timeout` | `-7` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_context` | `-8` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_overflow` | `-9` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_exhausted` | `-10` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_release` | `-11` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_error_cancelled` | `-12` | `i32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_context_irq` | `1` | `u32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_semaphore_context_sleepable` | `2` | `u32` | value | number | `driver_semaphore` | fixed_contract |
| `driver_thread_api_min_bytes` | `72` | `u32` | value | bytes | `driver_thread` | fixed_contract |
| `driver_thread_flag_abortable` | `2` | `u32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_flag_aborted` | `4` | `u32` | value | number | `driver_thread` | fixed_contract |
| `driver_thread_flag_sleeping` | `8` | `u32` | value | number | `driver_thread` | fixed_contract |
| `gfx_output_catalog_capacity` | `64` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_receiver_max_outputs` | `32` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_receiver_only` | `32` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_edid_missing` | `64` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_edid_invalid` | `128` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_receiver_incomplete` | `256` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_flag_query_failed` | `512` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_idle` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_queued` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_executing` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_awaiting_confirmation` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_confirming` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_reverting` | `5` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_confirmed` | `6` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_reverted` | `7` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_phase_lost` | `8` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_operation_apply` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_operation_confirm` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_operation_rollback` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_resolve_confirm` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_mode_resolve_rollback` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_error_timeout` | `-8` | `i32` | value | number | `gfx_output` | fixed_contract |
| `display_presentation_flag_available` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_presentation_flag_lost` | `2` | `u32` | value | number | `display` | fixed_contract |
| `display_presentation_pending_copy` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_presentation_pending_ready` | `2` | `u32` | value | number | `display` | fixed_contract |
| `display_presentation_pending_flip` | `4` | `u32` | value | number | `display` | fixed_contract |
| `display_presentation_pending_setup` | `8` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_cap_hardware` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_cap_straight_alpha` | `2` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_cap_hotspot` | `4` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_cap_offscreen` | `8` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_operation_prepare` | `0` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_operation_show` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_operation_move` | `2` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_operation_hide` | `3` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_operation_release` | `4` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_phase_idle` | `0` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_phase_queued` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_phase_active` | `2` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_phase_complete` | `3` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_phase_failed` | `4` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_phase_lost` | `5` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_state_image_ready` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_state_visible` | `2` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_state_suspended` | `16` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_state_unknown` | `4` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_state_claimed` | `8` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_visibility_hidden` | `0` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_visibility_visible` | `1` | `u32` | value | number | `display` | fixed_contract |
| `display_cursor_visibility_unknown` | `2` | `u32` | value | number | `display` | fixed_contract |
| `gfx_audio_route_absent` | `0` | `u32` | value | number | `display` | fixed_contract |
| `gfx_audio_route_pending` | `1` | `u32` | value | number | `display` | fixed_contract |
| `gfx_audio_route_ready` | `2` | `u32` | value | number | `display` | fixed_contract |
| `gfx_audio_route_unsupported` | `3` | `u32` | value | number | `display` | fixed_contract |
| `gfx_audio_route_failed` | `4` | `u32` | value | number | `display` | fixed_contract |
| `gfx_queue_operation_copy_rows` | `3` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_operation_render` | `4` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_blend_over` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_blend_replace` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_filter_bilinear` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_filter_nearest` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_kind_fill` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_kind_sample` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_transfer_identity` | `0` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_transfer_srgb_decode` | `1` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_transfer_srgb_encode` | `2` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_operation_present` | `5` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_queue_operation_render_list` | `6` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `gfx_render_list_capacity` | `16` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `display_presentation_info_active` | `1` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_lost` | `2` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_occluded` | `4` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_synchronized` | `8` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_visibility` | `16` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_native` | `32` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_direct` | `64` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_presentation_info_overlay` | `128` | `u32` | value | number | `display_presentation` | fixed_contract |
| `gfx_queue_operation_direct_present` | `7` | `u32` | value | number | `gfx_queue` | fixed_contract |
| `display_presentation_flag_direct` | `4` | `u32` | value | number | `display` | fixed_contract |
| `display_presentation_flag_polled` | `8` | `u32` | value | number | `display` | fixed_contract |
| `audio_output_reason_auto_display_port` | `8` | `u32` | identity | number | `audio_service_outputs` | fixed_contract |
| `gfx_output_kind_dvi` | `6` | `u32` | value | number | `gfx_outputs` | fixed_contract |
| `display_presentation_info_system_source` | `256` | `u32` | value | number | `display_presentation` | fixed_contract |
| `display_control_op_query` | `1808` | `u16` | identity | number | `display_control` | fixed_contract |
| `display_control_op_request` | `1809` | `u16` | identity | number | `display_control` | fixed_contract |
| `display_control_op_exchange` | `1810` | `u16` | identity | number | `display_control` | fixed_contract |
| `display_control_request_magic` | `1363424338` | `u32` | identity | number | `display_control` | fixed_contract |
| `display_control_status_magic` | `1396978770` | `u32` | identity | number | `display_control` | fixed_contract |
| `display_control_exchange_magic` | `1480864850` | `u32` | identity | number | `display_control` | fixed_contract |
| `gfx_queue_operation_render_grid_list` | `8` | `u32` | identity | number | `gfx_queue` | fixed_contract |
| `gfx_buffer_format_xrgb2101010` | `808669784` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_argb2101010` | `808669761` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_buffer_format_abgr16161616f` | `1211384385` | `u32` | value | number | `gfx_buffer` | fixed_contract |
| `gfx_output_color_known` | `1` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_color_active` | `2` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_color_identity` | `4` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_color_hdmi_metadata` | `8` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_color_dp_metadata` | `16` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_color_dp_vsc` | `32` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_color_scdc` | `64` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_queue_operation_render_color_list` | `9` | `u32` | identity | number | `gfx_queue` | fixed_contract |
| `gfx_render_transfer_color` | `3` | `u32` | identity | number | `gfx_queue` | fixed_contract |
| `display_control_op_color_request` | `1811` | `u16` | identity | number | `display_control` | fixed_contract |
| `display_control_op_color_exchange` | `1812` | `u16` | identity | number | `display_control` | fixed_contract |
| `gfx_refresh_cap_known` | `1` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_cap_capable` | `2` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_cap_independent_heads` | `4` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_cap_hdr` | `8` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_cap_lfc` | `16` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_policy_off` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_policy_fullscreen` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_policy_windows` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_operation_configure` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_operation_release` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_operation_flicker` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_operation_clear_fault` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_scene_fullscreen` | `1` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_scene_animated` | `2` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_scene_capture` | `4` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_refresh_phase_fixed` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_phase_enabling` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_phase_active` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_phase_disabling` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_phase_faulted` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_phase_lost` | `5` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_none` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_policy_off` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_idle` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_windowed` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_unavailable` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_transition` | `5` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_hdr` | `6` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_topology` | `7` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_capture` | `8` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_audio_clock` | `9` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_link_lost` | `10` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_timing_fault` | `11` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_user_flicker` | `12` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_refresh_reason_stale_clock` | `13` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_output_link_tmds` | `1` | `u32` | identity | number | `gfx_output` | fixed_contract |
| `gfx_output_link_frl` | `2` | `u32` | identity | number | `gfx_output` | fixed_contract |
| `gfx_output_link_dp_sst` | `3` | `u32` | identity | number | `gfx_output` | fixed_contract |
| `gfx_output_link_dp_mst` | `4` | `u32` | identity | number | `gfx_output` | fixed_contract |
| `gfx_output_link_fec` | `1` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_output_link_dsc` | `2` | `u32` | flag | bitmask | `gfx_output` | fixed_contract |
| `gfx_memory_budget_query` | `0` | `u32` | identity | number | `gfx_memory` | fixed_contract |
| `gfx_memory_budget_configure` | `1` | `u32` | identity | number | `gfx_memory` | fixed_contract |
| `gfx_memory_budget_closing` | `1` | `u32` | flag | bitmask | `gfx_memory` | fixed_contract |
| `gfx_telemetry_unavailable` | `0` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_changing` | `1` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_malformed` | `2` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_awaiting_change` | `3` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_fresh` | `4` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_stale` | `5` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_metric_mask` | `1023` | `u64` | flag | bitmask | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_timer_delta_valid` | `1` | `u32` | flag | bitmask | `gfx_telemetry` | fixed_contract |
| `gfx_output_flag_sleeping` | `1024` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_cap_signal` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_cap_sink` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_phase_on` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_phase_stopping` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_phase_off` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_phase_waking` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_phase_unavailable` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_reason_none` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_reason_link` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_reason_rejected` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_reason_timeout` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_reason_device_lost` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_power_reason_unsupported` | `5` | `u32` | value | number | `gfx_output` | fixed_contract |
| `notification_ok` | `0` | `i32` | value | number | `program` | fixed_contract |
| `notification_timeout` | `1` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_invalid` | `-1` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_stale` | `-2` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_closed` | `-3` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_context` | `-4` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_memory` | `-5` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_release` | `-6` | `i32` | value | number | `program` | fixed_contract |
| `notification_error_exhausted` | `-7` | `i32` | value | number | `program` | fixed_contract |
| `program_local_ok` | `0` | `i32` | value | number | `program` | fixed_contract |
| `program_local_existing` | `1` | `i32` | value | number | `program` | fixed_contract |
| `program_local_error_invalid` | `-1` | `i32` | value | number | `program` | fixed_contract |
| `program_local_error_context` | `-2` | `i32` | value | number | `program` | fixed_contract |
| `program_local_error_memory` | `-3` | `i32` | value | number | `program` | fixed_contract |
| `program_local_error_closed` | `-4` | `i32` | value | number | `program` | fixed_contract |
| `gfx_queue_operation_native` | `10` | `u32` | identity | number | `gfx_queue` | fixed_contract |
| `gfx_native_read_capacity` | `1024` | `u32` | identity | number | `gfx_queue` | fixed_contract |
| `gfx_virtual_flag_blocklinear` | `1` | `u32` | value | number | `gfx_virtual` | fixed_contract |
| `gfx_virtual_layout_shift` | `8` | `u32` | value | number | `gfx_virtual` | fixed_contract |
| `gfx_virtual_layout_mask` | `65280` | `u32` | value | number | `gfx_virtual` | fixed_contract |
| `gfx_virtual_layout_api_version` | `36` | `u32` | value | number | `gfx_virtual` | fixed_contract |
| `window_graphics_op_client` | `1824` | `u16` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_op_publish` | `1825` | `u16` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_op_consumer` | `1826` | `u16` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_op_wait` | `1827` | `u16` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_visible` | `1` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_fifo` | `1` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_mailbox` | `2` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_query` | `0` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_create_chain` | `1` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_attach` | `2` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_acquire` | `3` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_present` | `4` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_cancel_acquire` | `5` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_close_chain` | `6` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_chain_status` | `7` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_publish` | `0` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_remove` | `1` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_take` | `0` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_return` | `1` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_ok` | `1` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_not_ready` | `0` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_invalid` | `-1` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_unavailable` | `-2` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_stale` | `-3` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_busy` | `-4` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_capacity` | `-5` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_out_of_date` | `-6` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_device_lost` | `-7` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_closed` | `-8` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_not_owner` | `-9` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_failed` | `-10` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_timeout` | `-11` | `i32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_image_vacant` | `0` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_image_available` | `1` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_image_acquired` | `2` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_image_queued` | `3` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_image_leased` | `4` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_image_returning` | `5` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_release_fence` | `2` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `window_graphics_fence_released` | `1` | `u32` | flag | bitmask | `window_graphics` | fixed_contract |
| `gfx_queue_operation_render_color_grid_list` | `11` | `u32` | identity | number | `gfx_queue` | fixed_contract |
| `window_mode_op_query` | `1840` | `u16` | identity | number | `window_mode` | fixed_contract |
| `window_mode_op_request` | `1841` | `u16` | identity | number | `window_mode` | fixed_contract |
| `window_mode_op_exchange` | `1842` | `u16` | identity | number | `window_mode` | fixed_contract |
| `gui_window_flag_fullscreen` | `16` | `u32` | identity | number | `window_mode` | fixed_contract |
| `window_graphics_inspect` | `3` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `gfx_brightness_path_none` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_path_pwm` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_path_aux8` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_path_aux16` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_phase_unavailable` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_phase_ready` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_phase_failed` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_none` | `0` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_unsupported` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_firmware_owner` | `2` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_invalid_panel` | `3` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_timeout` | `4` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_io` | `5` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_reason_inactive` | `6` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_brightness_flag_current_known` | `1` | `u32` | value | number | `gfx_output` | fixed_contract |
| `gfx_telemetry_source_smu10` | `2` | `u32` | value | enum_value | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_partial_values` | `2` | `u32` | flag | bitmask | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_current_clocks` | `4` | `u32` | flag | bitmask | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_fabric_clock` | `8` | `u32` | flag | bitmask | `gfx_telemetry` | fixed_contract |
| `gfx_telemetry_value_mask` | `3840` | `u32` | flag | bitmask | `gfx_telemetry` | fixed_contract |
| `platform_input_kind_brightness_up` | `1` | `u32` | value | number | `input` | fixed_contract |
| `platform_input_kind_brightness_down` | `2` | `u32` | value | number | `input` | fixed_contract |
| `platform_input_kind_lid` | `3` | `u32` | value | number | `input` | fixed_contract |
| `platform_input_kind_capabilities` | `4` | `u32` | value | number | `input` | fixed_contract |
| `hid_report_op_consumer` | `3` | `u32` | value | number | `hid_report` | fixed_contract |
| `driver_api_owned_work_version` | `36` | `u32` | version | number | `driver_api` | fixed_contract |
| `driver_work_owner_busy` | `-32000` | `i32` | value | status | `driver_work` | fixed_contract |
| `window_graphics_headless` | `2` | `u32` | identity | number | `window_graphics` | fixed_contract |
| `performance_irq_coverage_instrumentation_disabled` | `32` | `u32` | flag | bitmask | `performance_irq_timing` | fixed_contract |
| `stack_fault_flag_task` | `1` | `u32` | flag | bitmask | `stack_fault` | fixed_contract |
| `stack_fault_flag_instance` | `2` | `u32` | flag | bitmask | `stack_fault` | fixed_contract |
| `stack_fault_flag_thread` | `4` | `u32` | flag | bitmask | `stack_fault` | fixed_contract |
| `stack_fault_flag_bounds` | `8` | `u32` | flag | bitmask | `stack_fault` | fixed_contract |
| `stack_fault_kind_unknown` | `0` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_kind_program_main` | `1` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_kind_program_thread` | `2` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_kind_kernel_task` | `3` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_kind_exception` | `4` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_unknown` | `0` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_reserve_exhausted` | `1` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_kernel_guard` | `2` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_physical_budget` | `3` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_vm_commit` | `4` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_growth_forbidden` | `5` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_protection` | `6` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_vm_guard` | `7` | `u32` | value | number | `stack_fault` | fixed_contract |
| `stack_fault_reason_continuation_headroom` | `8` | `u32` | value | number | `stack_fault` | fixed_contract |
| `kernel_heap_check_version` | `1` | `u32` | version | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_status_unavailable` | `0` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_status_passed` | `1` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_status_failed` | `2` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_status_busy` | `3` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_status_cancelled` | `4` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_flag_initialized` | `1` | `u32` | flag | bitmask | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_flag_cleanup_complete` | `2` | `u32` | flag | bitmask | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_none` | `0` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_rust_allocator` | `1` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_patterns` | `2` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_alignment` | `3` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_double_free` | `4` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_churn` | `5` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_acceptance` | `6` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_resident_commit` | `7` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_heap_check_case_cleanup` | `8` | `u32` | value | number | `kernel_heap_check` | fixed_contract |
| `kernel_scheduler_check_version` | `1` | `u32` | version | number | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_status_unavailable` | `0` | `u32` | value | number | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_status_passed` | `1` | `u32` | value | number | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_status_failed` | `2` | `u32` | value | number | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_status_busy` | `3` | `u32` | value | number | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_status_cancelled` | `4` | `u32` | value | number | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_sync` | `1` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_unwind` | `2` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_directed` | `4` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_fairness` | `8` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_inheritance` | `16` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_deadlines` | `32` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_fpu` | `64` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_workers` | `128` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_idle` | `256` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_case_all` | `127` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_isolated_timer_reprogram` | `1` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_isolated_timeout_batch_64` | `2` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_isolated_reserve_oom` | `4` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_scheduler_check_isolated_priority_boot` | `8` | `u32` | flag | bitmask | `kernel_scheduler_check` | fixed_contract |
| `kernel_smp_check_version` | `1` | `u32` | version | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_status_unavailable` | `0` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_status_passed` | `1` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_status_failed` | `2` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_status_busy` | `3` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_status_cancelled` | `4` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_flag_work_complete` | `1` | `u32` | flag | bitmask | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_flag_cleanup_complete` | `2` | `u32` | flag | bitmask | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_isolated_tlb_timeout` | `1` | `u32` | flag | bitmask | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_isolated_boot_extras` | `2` | `u32` | flag | bitmask | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_none` | `0` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_mapping` | `1` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_workers` | `2` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_tlb` | `3` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_clock` | `4` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_owner` | `5` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `kernel_smp_check_stage_cleanup` | `6` | `u32` | value | number | `kernel_smp_check` | fixed_contract |
| `smp_tlb_snapshot_version` | `1` | `u32` | version | number | `smp_tlb_snapshot` | fixed_contract |
| `smp_tlb_snapshot_flag_clock_available` | `1` | `u32` | flag | bitmask | `smp_tlb_snapshot` | fixed_contract |
| `smp_tlb_snapshot_flag_tlb_registered` | `2` | `u32` | flag | bitmask | `smp_tlb_snapshot` | fixed_contract |
| `smp_tlb_snapshot_flag_isolated_injection` | `4` | `u32` | flag | bitmask | `smp_tlb_snapshot` | fixed_contract |
| `kernel_smp_check_flag_partial_snapshot` | `4` | `u32` | flag | bitmask | `kernel_smp_check` | fixed_contract |
| `kernel_block_queue_check_version` | `1` | `u32` | version | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_status_unavailable` | `0` | `u32` | value | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_status_passed` | `1` | `u32` | value | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_status_failed` | `2` | `u32` | value | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_status_busy` | `3` | `u32` | value | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_status_cancelled` | `4` | `u32` | value | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_flag_work_complete` | `1` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_flag_cleanup_complete` | `2` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_flag_partial_snapshot` | `4` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_parallel` | `1` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_queue` | `2` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_reordered` | `4` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_lifetime` | `8` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_reset` | `16` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_timeout` | `32` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_flush` | `64` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_case_batch` | `128` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_cases_all` | `255` | `u32` | flag | bitmask | `kernel_block_queue_check` | fixed_contract |
| `kernel_block_queue_check_stage_cleanup` | `9` | `u32` | value | number | `kernel_block_queue_check` | fixed_contract |
| `kernel_nvme_check_version` | `1` | `u32` | version | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_status_unavailable` | `0` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_status_passed` | `1` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_status_failed` | `2` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_status_busy` | `3` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_status_cancelled` | `4` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_flag_work_complete` | `1` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_flag_cleanup_complete` | `2` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_flag_partial_snapshot` | `4` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_none` | `0` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_device` | `1` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_backend` | `2` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_observation` | `3` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_geometry` | `4` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_irq` | `5` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_unavailable_context` | `6` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_none` | `0` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_binding` | `1` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_buffer` | `2` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_read` | `3` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_observation` | `4` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_irq` | `5` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_stage_cleanup` | `6` | `u32` | value | number | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_receipt_runtime` | `1` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_receipt_asynchronous` | `2` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_receipt_completed` | `4` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `kernel_nvme_check_receipt_clean` | `8` | `u32` | flag | bitmask | `kernel_nvme_check` | fixed_contract |
| `storage_observation_version` | `1` | `u32` | version | number | `storage` | fixed_contract |
| `storage_request_flag_observation` | `1` | `u32` | flag | bitmask | `storage_request` | fixed_contract |
| `storage_observation_flag_irq` | `1` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_worker` | `2` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_cqe` | `4` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_dma_released` | `8` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_poll` | `16` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_cancel` | `32` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_epoch_changed` | `64` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_flag_not_submitted` | `128` | `u32` | flag | bitmask | `storage_observation` | fixed_contract |
| `storage_observation_irq_none` | `0` | `u32` | value | number | `storage_observation` | fixed_contract |
| `storage_observation_irq_msi` | `1` | `u32` | value | number | `storage_observation` | fixed_contract |
| `storage_observation_irq_msix` | `2` | `u32` | value | number | `storage_observation` | fixed_contract |
| `storage_backend_status_observation_supported` | `131072` | `u32` | flag | bitmask | `storage_backend_status` | fixed_contract |
| `storage_backend_status_cleanup_retained` | `262144` | `u32` | flag | bitmask | `storage_backend_status` | fixed_contract |
| `kernel_usb_check_version` | `1` | `u32` | version | number | `kernel_usb_check` | fixed_contract |
| `kernel_usb_check_status_unavailable` | `0` | `u32` | value | number | `kernel_usb_check` | fixed_contract |
| `kernel_usb_check_status_passed` | `1` | `u32` | value | number | `kernel_usb_check` | fixed_contract |
| `kernel_usb_check_status_failed` | `2` | `u32` | value | number | `kernel_usb_check` | fixed_contract |
| `kernel_usb_check_case_ring` | `1` | `u32` | flag | bitmask | `kernel_usb_check` | fixed_contract |
| `kernel_usb_check_case_router` | `2` | `u32` | flag | bitmask | `kernel_usb_check` | fixed_contract |
| `kernel_usb_check_cases_all` | `3` | `u32` | flag | bitmask | `kernel_usb_check` | fixed_contract |
| `serial_resource_io` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_resource_mmio` | `2` | `u32` | value | number | `serial` | fixed_contract |
| `serial_resource_opaque` | `3` | `u32` | value | number | `serial` | fixed_contract |
| `serial_cap_rx` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_cap_tx` | `2` | `u32` | value | number | `serial` | fixed_contract |
| `serial_cap_rts_cts` | `4` | `u32` | value | number | `serial` | fixed_contract |
| `serial_cap_line_status` | `8` | `u32` | value | number | `serial` | fixed_contract |
| `serial_cap_irq` | `16` | `u32` | value | number | `serial` | fixed_contract |
| `serial_port_present` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_port_open` | `2` | `u32` | value | number | `serial` | fixed_contract |
| `serial_port_debug_reserved` | `4` | `u32` | value | number | `serial` | fixed_contract |
| `serial_port_closing` | `8` | `u32` | value | number | `serial` | fixed_contract |
| `serial_port_hardware_error` | `16` | `u32` | value | number | `serial` | fixed_contract |
| `serial_port_fifo` | `32` | `u32` | value | number | `serial` | fixed_contract |
| `serial_event_rx` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_event_tx` | `2` | `u32` | value | number | `serial` | fixed_contract |
| `serial_event_state` | `4` | `u32` | value | number | `serial` | fixed_contract |
| `serial_event_error` | `8` | `u32` | value | number | `serial` | fixed_contract |
| `serial_event_modem` | `16` | `u32` | value | number | `serial` | fixed_contract |
| `serial_transfer_overflow` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_transfer_line_error` | `2` | `u32` | value | number | `serial` | fixed_contract |
| `serial_transfer_partial` | `4` | `u32` | value | number | `serial` | fixed_contract |
| `serial_close_abort` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_flow_none` | `0` | `u32` | value | number | `serial` | fixed_contract |
| `serial_flow_rts_cts` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_parity_none` | `0` | `u32` | value | number | `serial` | fixed_contract |
| `serial_parity_odd` | `1` | `u32` | value | number | `serial` | fixed_contract |
| `serial_parity_even` | `2` | `u32` | value | number | `serial` | fixed_contract |
| `serial_parity_mark` | `3` | `u32` | value | number | `serial` | fixed_contract |
| `serial_parity_space` | `4` | `u32` | value | number | `serial` | fixed_contract |
| `driver_api_serial_version` | `37` | `u32` | version | number | `serial` | fixed_contract |
| `cpu_topology_result_ok` | `1` | `i32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_result_end` | `0` | `i32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_result_invalid` | `-1` | `i32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_result_busy` | `-2` | `i32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_captured` | `1` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_geometry` | `2` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_acpi_uid` | `4` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_online` | `8` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_schedulable` | `16` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_bsp` | `32` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_core_type` | `64` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_efficiency` | `128` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_heterogeneous` | `256` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_asymmetric` | `512` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_qualified` | `1024` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_flag_acpi_conflict` | `2048` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_unavailable` | `0` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_known` | `1` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_malformed` | `2` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_identity` | `3` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_legacy_model` | `4` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_unqualified` | `5` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_inconsistent` | `6` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_geometry_starting` | `7` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_unavailable` | `0` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_complete` | `1` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_invalid` | `2` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_truncated` | `3` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_kind_data` | `1` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_kind_instruction` | `2` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `cpu_topology_cache_kind_unified` | `3` | `u32` | value | number | `cpu_topology` | fixed_contract |
| `thread_placement_version` | `1` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_cpu_none` | `4294967295` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_flag_default_cpus` | `1` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_flag_pending` | `2` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_flag_parallel` | `4` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_flag_internal_fixed` | `8` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_class_interactive` | `0` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_class_batch` | `1` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_class_preferred` | `2` | `u32` | value | number | `thread_placement` | fixed_contract |
| `thread_placement_error_capacity` | `-11` | `i32` | value | number | `thread_placement` | fixed_contract |
| `thread_create_flag_compute_worker` | `1` | `u32` | flag | bitmask | `thread_create` | fixed_contract |
| `thread_flag_compute_worker` | `8` | `u32` | flag | bitmask | `thread` | fixed_contract |
| `cpu_lifecycle_version` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_op_query` | `0` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_op_offline` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_op_online` | `2` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_ok` | `0` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_invalid` | `-1` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_busy` | `-2` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_index` | `-3` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_epoch` | `-4` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_context` | `-5` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_qualification` | `-6` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_error_state` | `-7` | `i32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_absent` | `0` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_detected` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_starting` | `2` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_entered` | `3` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_online` | `4` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_terminal_pending` | `5` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_terminal` | `6` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_failed` | `7` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_qualified` | `8` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_draining` | `9` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_parked` | `10` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_offline` | `11` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_state_stop_pending` | `12` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_none` | `0` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_fixed` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_kernel_context` | `2` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_resources` | `3` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_task_budget` | `4` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_page_owner` | `5` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_tlb` | `6` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_irq` | `7` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_timer` | `8` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_timeout` | `9` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_qualification` | `10` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_busy` | `11` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_caller` | `12` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_index` | `13` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_epoch` | `14` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_state` | `15` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_reason_terminal` | `16` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_online` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_schedulable` | `2` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_parked` | `4` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_tlb_enrolled` | `8` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_reusable` | `16` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_current_receipt` | `32` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_flag_terminal` | `64` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_status_unavailable` | `0` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_status_passed` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_status_failed` | `2` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_status_busy` | `3` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_fixed` | `1` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_kernel` | `2` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_page_owner` | `4` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_cycle` | `8` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_stale_epoch` | `16` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_runtime_tlb` | `32` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_lifecycle_check_case_all` | `63` | `u32` | value | number | `cpu_lifecycle` | fixed_contract |
| `cpu_capabilities_version` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_ok` | `0` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_end` | `1` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_invalid` | `-1` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_busy` | `-2` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_index` | `-3` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_epoch` | `-4` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_context` | `-5` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_offline` | `-6` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_unsupported` | `-7` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_error_fault` | `-8` | `i32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_captured` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_online` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_schedulable` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_signature` | `8` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_brand` | `16` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_hypervisor_present` | `32` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_hypervisor_valid` | `64` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_invalid_basic` | `128` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_invalid_extended` | `256` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_invalid_hypervisor` | `512` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_legacy_kvm_maximum` | `1024` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_nominal_frequency` | `2048` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_tsc_ratio` | `4096` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_flag_pmu` | `8192` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_cr0` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_cr4` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_xcr0` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_efer` | `8` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_pat` | `16` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_mtrr_default` | `32` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_capabilities_os_msr_fault` | `64` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_flag_raw` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_flag_module_required` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_flag_control` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_hardware_unknown` | `0` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_hardware_absent` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_hardware_present` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_os_unknown` | `0` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_os_disabled` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_os_enabled` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_os_not_applicable` | `3` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_use_unknown` | `0` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_no_owner` | `0` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_missing_leaf` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_vendor` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_absent` | `3` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_dependency` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_control_unknown` | `5` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_disabled` | `6` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_reason_no_os_control` | `7` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_x87` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_msr` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_fxsr` | `3` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_sse` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_sse2` | `5` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_sse3` | `6` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_ssse3` | `7` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_sse41` | `8` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_sse42` | `9` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_xsave` | `10` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_avx` | `11` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_avx2` | `12` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_avx512f` | `13` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_amx_tile` | `14` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_aes` | `15` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_pclmulqdq` | `16` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_vaes` | `17` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_vpclmulqdq` | `18` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_rdrand` | `19` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_rdseed` | `20` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_tsc` | `21` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_invariant_tsc` | `22` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_pat` | `23` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_mtrr` | `24` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_nx` | `25` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_page1gb` | `26` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_pcid` | `27` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_invpcid` | `28` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_fsgsbase` | `29` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_smep` | `30` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_smap` | `31` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_la57` | `32` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_clflush` | `33` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_clflushopt` | `34` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_clwb` | `35` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_monitor_mwait` | `36` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_arat` | `37` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_aperf_mperf` | `38` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_dts` | `39` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_turbo` | `40` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_hwp` | `41` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_hwp_epp` | `42` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_hwp_package` | `43` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_hw_feedback` | `44` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_intel_pmu` | `45` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_amd_cpb` | `46` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_amd_cppc` | `47` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_amd_effective_frequency_ro` | `48` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_amd_pmu` | `49` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_x2apic` | `50` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_tsc_deadline` | `51` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_efer` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_apic_base` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_pat` | `3` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_mtrr_cap` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_mperf` | `5` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_aperf` | `6` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_platform_info` | `7` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_flag_raw` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_status_unavailable` | `0` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_status_passed` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_status_failed` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_case_read_on` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_case_write_on` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_case_read_off` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_case_write_off` | `8` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_check_case_all` | `15` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_cx8` | `52` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_cmov` | `53` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_mmx` | `54` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_long_mode` | `55` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_power_version` | `1` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_cpu_none` | `4294967295` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_state_no_provider` | `0` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_state_no_sample` | `1` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_state_observed` | `2` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_state_stale` | `3` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_state_unsupported` | `4` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_state_virtual` | `5` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_profile_unsupported` | `0` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_profile_virtual` | `1` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_profile_intel_haswell` | `2` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_profile_amd_milan_b1` | `3` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_installed` | `1` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_sampled` | `2` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_virtual` | `4` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_stale` | `8` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_energy_discontinuity` | `16` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_package_shared` | `32` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_core_shared` | `64` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_active_hz` | `1` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_reference_hz` | `2` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_aperf` | `4` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_mperf` | `8` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_temperature` | `16` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_microcode` | `32` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_energy_unit` | `64` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_package_energy` | `128` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_core_energy` | `256` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_package_scope` | `512` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_core_scope` | `1024` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_valid_thermal_status` | `2048` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_backend_flag_parallel` | `1` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_register_id_microcode` | `8` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_temperature_target` | `9` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_thermal_status` | `10` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_energy_unit` | `11` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_package_energy` | `12` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_core_energy` | `13` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_pstate0` | `14` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_energy_unit` | `15` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_package_energy` | `16` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_core_energy` | `17` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_performance_op_inspect` | `0` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_op_apply` | `1` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_op_release` | `2` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_op_enable` | `3` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_unsupported` | `0` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_disabled` | `1` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_ready` | `2` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_owned` | `3` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_restored` | `4` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_uncertain` | `5` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_state_conflict` | `6` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_request_flag_epp` | `1` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_request_flag_sticky_enable` | `2` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_flag_epp` | `1` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_flag_sticky_enabled` | `2` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_flag_parameters_restored` | `4` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_flag_virtual` | `8` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_valid_enable` | `1` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_valid_capabilities` | `2` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_valid_request` | `4` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_valid_package` | `8` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_valid_scope` | `16` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_performance_valid_time` | `32` | `u32` | value | number | `cpu_performance` | fixed_contract |
| `cpu_register_write_flag_before` | `1` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_write_flag_attempted` | `2` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_write_flag_after` | `4` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_write_flag_written` | `8` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_hwp_enable` | `18` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_hwp_capabilities` | `19` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_hwp_request` | `20` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_intel_hwp_package` | `21` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_cppc_flag_rank_published` | `16` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_range` | `1` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_request` | `2` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_enable` | `4` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_status` | `8` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_current_limit` | `16` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_scope` | `32` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_time` | `64` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_valid_rank` | `128` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_raw_enable` | `1` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_raw_capability1` | `2` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_raw_capability2` | `4` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_raw_request` | `8` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_cppc_raw_status` | `16` | `u32` | value | number | `cpu_cppc` | fixed_contract |
| `cpu_performance_hint_state_unknown` | `0` | `u32` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_performance_hint_state_current` | `1` | `u32` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_performance_hint_state_stale` | `2` | `u32` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_performance_hint_flag_valid` | `1` | `u32` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_performance_hint_flag_group_ready` | `2` | `u32` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_performance_hint_source_cppc` | `1` | `u32` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_performance_hint_max_age_ns` | `1000000000` | `u64` | value | number | `cpu_performance_hint` | fixed_contract |
| `cpu_register_id_amd_cppc_capabilities1` | `22` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_cppc_enable` | `23` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_cppc_capabilities2` | `24` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_cppc_request` | `25` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_register_id_amd_cppc_status` | `26` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `power_profile_firmware` | `0` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_balanced` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_performance` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_saving` | `3` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_op_status` | `1` | `u16` | value | number | `power_profiles` | fixed_contract |
| `power_profile_op_select` | `2` | `u16` | value | number | `power_profiles` | fixed_contract |
| `power_profile_op_cpu` | `3` | `u16` | value | number | `power_profiles` | fixed_contract |
| `power_profile_op_quiesce` | `4` | `u16` | value | number | `power_profiles` | fixed_contract |
| `power_profile_op_resume` | `5` | `u16` | value | number | `power_profiles` | fixed_contract |
| `power_profile_op_reload` | `6` | `u16` | value | number | `power_profiles` | fixed_contract |
| `power_profile_request_flag_sticky_enable` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_firmware` | `0` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_unsupported` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_disabled` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_applying` | `3` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_applied` | `4` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_returning` | `5` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_retained` | `6` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_partial` | `7` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_state_quiesced` | `8` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_backend_none` | `0` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_backend_hwp` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_backend_cppc` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_flag_provider` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_flag_applied_complete` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_flag_pending_return` | `4` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_flag_quiesced` | `8` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_flag_config_valid` | `16` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_flag_sticky_enabled` | `32` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_flag_owned` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_flag_confirmed` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_flag_sticky_enabled` | `4` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_flag_foreign_control` | `8` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_flag_worker_retained` | `16` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_valid_request` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_valid_range` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_valid_time` | `4` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_cpu_valid_epp` | `8` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_absent` | `0` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_starting` | `1` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_idle` | `2` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_applying` | `3` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_active` | `4` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_returning` | `5` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_held` | `6` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_worker_complete` | `7` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_transition_action_halt` | `0` | `u32` | value | number | `power_transition` | fixed_contract |
| `power_transition_action_reboot` | `1` | `u32` | value | number | `power_transition` | fixed_contract |
| `power_transition_action_poweroff` | `2` | `u32` | value | number | `power_transition` | fixed_contract |
| `power_transition_error_invalid` | `-1` | `i32` | value | number | `power_transition` | fixed_contract |
| `power_transition_error_context` | `-2` | `i32` | value | number | `power_transition` | fixed_contract |
| `power_transition_error_busy` | `-3` | `i32` | value | number | `power_transition` | fixed_contract |
| `power_transition_error_retained` | `-4` | `i32` | value | number | `power_transition` | fixed_contract |
| `cpu_firmware_backend_none` | `0` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_backend_cppc` | `1` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_backend_pss` | `2` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_valid_range` | `1` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_valid_request` | `2` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_valid_time` | `4` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_valid_epp` | `8` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `cpu_firmware_valid_domain` | `16` | `u32` | value | number | `cpu_firmware` | fixed_contract |
| `power_profile_backend_acpi_cppc` | `3` | `u32` | value | number | `power_profiles` | fixed_contract |
| `power_profile_backend_acpi_pss` | `4` | `u32` | value | number | `power_profiles` | fixed_contract |
| `cpu_idle_reason_none` | `0` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_absent` | `1` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_malformed` | `2` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_coordination` | `3` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_lpi_context` | `4` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_entry_method` | `5` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_withdrawn` | `6` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_hypervisor` | `7` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_vendor` | `8` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_monitor` | `9` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_arat` | `10` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_invariant_tsc` | `11` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_substate` | `12` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_monitor_fsm` | `13` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_clock` | `14` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_timer` | `15` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_epoch` | `16` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_policy` | `17` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_idle_reason_short_budget` | `18` | `u32` | value | number | `cpu_idle` | fixed_contract |
| `cpu_machine_flag_mce` | `1` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_mca` | `2` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_msr` | `4` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_mce_enabled` | `8` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_cap_valid` | `16` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_status_valid` | `32` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_truncated` | `64` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_read_fault` | `128` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_smca_advertised` | `256` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_virtual` | `512` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_unsupported` | `1024` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_flag_prepared` | `2048` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_status_read` | `1` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_status_valid` | `2` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_address_read` | `4` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_misc_read` | `8` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_config_read` | `16` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_ipid_read` | `32` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_syndrome_read` | `64` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_unstable` | `128` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_read_fault` | `256` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_status_after_read` | `512` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_machine_bank_limit` | `64` | `u32` | value | number | `cpu_machine` | fixed_contract |
| `cpu_power_flag_mca_model` | `128` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_power_flag_smca_model` | `256` | `u32` | value | number | `cpu_power` | fixed_contract |
| `cpu_microcode_flag_before_valid` | `1` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_after_valid` | `2` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_bundle_valid` | `4` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_matched` | `8` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_payload_verified` | `16` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_virtual` | `32` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_update_attempt` | `64` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_post_features_fresh` | `128` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_features_changed` | `256` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_post_baseline` | `512` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_flag_initial_boot` | `1024` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_not_prepared` | `0` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_package_missing` | `1` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_unsupported_cpu` | `2` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_virtual_cpu` | `3` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_already_current` | `4` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_updated` | `5` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_firmware_prerequisite` | `6` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_package_rejected` | `7` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_revision_unavailable` | `8` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_load_failed` | `9` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_revision_mismatch` | `10` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_restart_verified` | `11` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_restart_requires_update` | `12` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_microcode_status_identity_changed` | `13` | `u32` | value | number | `cpu_microcode` | fixed_contract |
| `cpu_pmu_flag_exposed` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_virtual` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_qualified` | `4` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_online` | `8` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_busy` | `16` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_quarantined` | `32` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_last_result` | `64` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_flag_modulo_only` | `128` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_raw_before` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_raw_after` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_callback_started` | `4` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_callback_returned` | `8` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_restored` | `16` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_absolute_count` | `32` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_modulo_delta` | `64` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_overflow` | `128` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_identity_valid` | `256` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_snapshot_valid` | `512` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_if_preserved` | `1024` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_untouched` | `2048` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_full_width` | `4096` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_result_flag_within_budget` | `8192` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_profile_unknown` | `0` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_profile_intel_arch` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_profile_amd_milan_b1` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_none` | `0` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_no_pmu` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_virtual_cpu` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_unsupported_layout` | `3` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_unsupported_model` | `4` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_malformed` | `5` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_no_msr` | `6` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_offline` | `7` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_reason_quarantined` | `8` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_state_idle` | `0` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_state_active` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_state_quarantined` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_completed` | `0` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_busy` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_read_failed` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_write_failed` | `3` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_overflow` | `4` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_callback_aborted` | `5` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_identity_changed` | `6` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_restore_failed` | `7` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_status_clock_invalid` | `8` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_event_cycles` | `0` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_event_instructions` | `1` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_event_branches` | `2` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_event_branch_misses` | `3` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_event_cache_references` | `4` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_event_cache_misses` | `5` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_max_iterations` | `4096` | `u32` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_pmu_max_window_ns` | `2000000` | `u64` | value | number | `cpu_pmu` | fixed_contract |
| `cpu_feature_id_sha` | `56` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_erms` | `57` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_fsrm` | `58` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_bmi1` | `59` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_bmi2` | `60` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_feature_id_adx` | `61` | `u32` | value | number | `cpu_capabilities` | fixed_contract |
| `cpu_accel_feature_sha` | `1` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_feature_erms` | `2` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_feature_fsrm` | `4` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_feature_bmi1` | `8` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_feature_bmi2` | `16` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_feature_adx` | `32` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_info_flag_virtual` | `1` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_info_flag_online` | `2` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_info_flag_common_complete` | `4` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_info_flag_baseline_ready` | `8` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_callback_started` | `1` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_callback_returned` | `2` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_identity_valid` | `4` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_if_preserved` | `8` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_clock_valid` | `16` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_within_budget` | `32` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_feature_granted` | `64` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_flag_virtual` | `128` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_kind_baseline` | `0` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_kind_sha256` | `1` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_status_completed` | `0` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_status_callback_aborted` | `1` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_status_identity_changed` | `2` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_status_clock_unavailable` | `3` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_status_clock_regressed` | `4` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_work_status_over_budget` | `5` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_max_iterations` | `64` | `u32` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_max_window_ns` | `2000000` | `u64` | value | number | `cpu_acceleration` | fixed_contract |
| `cpu_accel_feature_rdrand` | `64` | `u32` | value | number | `entropy` | fixed_contract |
| `cpu_accel_work_kind_rdrand` | `2` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_max_request_bytes` | `4096` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_max_window_ns` | `250000000` | `u64` | value | number | `entropy` | fixed_contract |
| `entropy_state_unavailable` | `0` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_state_ready` | `1` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_state_closed` | `2` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_state_retained` | `3` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_state_removed` | `4` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_source_flag_registered` | `1` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_source_flag_virtual` | `2` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_source_flag_device` | `4` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_source_flag_verified_receipt` | `8` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_source_flag_quiesced` | `16` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_started` | `1` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_used` | `2` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_length_verified` | `4` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_within_budget` | `8` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_quiesced` | `16` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_cancelled` | `32` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_retained` | `64` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_receipt_flag_virtual` | `128` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_completed` | `0` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_unavailable` | `1` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_timeout` | `2` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_bad_completion` | `3` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_stopping` | `4` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_lost` | `5` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_device_status_retained` | `6` | `u32` | value | number | `entropy` | fixed_contract |
| `entropy_error_invalid` | `-1` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_busy` | `-2` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_unavailable` | `-3` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_stale` | `-4` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_timeout` | `-5` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_context` | `-6` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_device` | `-7` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_cancelled` | `-8` | `i32` | value | number | `entropy` | fixed_contract |
| `entropy_error_retained` | `-9` | `i32` | value | number | `entropy` | fixed_contract |
| `console_input_event_text` | `1` | `u32` | value | number | `console_input` | fixed_contract |
| `console_input_event_key` | `2` | `u32` | value | number | `console_input` | fixed_contract |
| `console_input_event_utf8_byte` | `3` | `u32` | value | number | `console_input` | fixed_contract |
| `console_input_event_batch_max` | `64` | `u32` | value | number | `console_input` | fixed_contract |
| `console_input_key_up` | `128` | `u32` | value | number | `console_input` | fixed_contract |
| `console_input_key_down` | `129` | `u32` | value | number | `console_input` | fixed_contract |
| `console_input_key_f3` | `130` | `u32` | value | number | `console_input` | fixed_contract |
| `console_text_utf8` | `65001` | `u32` | value | number | `console_text` | fixed_contract |
| `console_text_cp437` | `437` | `u32` | value | number | `console_text` | fixed_contract |
| `console_text_windows1252` | `1252` | `u32` | value | number | `console_text` | fixed_contract |
| `console_text_closed` | `1` | `u32` | value | number | `console_text` | fixed_contract |
| `fpu_observation_version` | `1` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_capabilities` | `0` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_begin` | `1` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_end` | `2` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_flag_available` | `1` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_flag_active` | `2` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_flag_closed` | `4` | `u32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_max_window_bytes` | `65536` | `u64` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_error_invalid` | `-1` | `i32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_error_unavailable` | `-2` | `i32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_error_busy` | `-3` | `i32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_error_stale` | `-4` | `i32` | value | number | `fpu_observation` | fixed_contract |
| `fpu_observation_error_exhausted` | `-5` | `i32` | value | number | `fpu_observation` | fixed_contract |
| `program_inventory_kind_lifecycle` | `4` | `u8` | value | enum_value | `program_inventory` | fixed_contract |
| `program_inventory_cursor_flag_lifecycle` | `2` | `u32` | value | bit | `program_inventory` | fixed_contract |
| `gui_activity_shared_clipboard` | `1` | `u32` | flag | bit | `gui_activity` | fixed_contract |
| `gui_activity_shared_directory` | `2` | `u32` | flag | bit | `gui_activity` | fixed_contract |
| `gui_activity_shared_all` | `3` | `u32` | value | bitmask | `gui_activity` | fixed_contract |
| `drive_info_flag_free_valid` | `1` | `u32` | flag | bitmask | `drive_info` | fixed_contract |
| `directory_batch_max_entries` | `8` | `u32` | value | count | `directory_batch` | fixed_contract |
| `directory_batch_work_steps` | `256` | `u32` | value | count | `directory_batch` | fixed_contract |
| `audio_backend_playback_version` | `5` | `u32` | version | number | `audio_outputs` | fixed_contract |
| `audio_playback_valid` | `1` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_playback_previous_valid` | `2` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_playback_running` | `4` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_playback_quiet` | `8` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_flow_continuous` | `1` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_source_valid` | `1` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_device_valid` | `2` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_age_valid` | `4` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_continuous` | `8` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_ended` | `16` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_unconfirmed` | `32` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_closed` | `64` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_progress_fresh` | `128` | `u32` | flag | bitmask | `audio_playback` | fixed_contract |
| `audio_service_op_stream_progress` | `11` | `u16` | value | number | `audio_service` | fixed_contract |
| `audio_service_op_stream_expectation` | `12` | `u16` | value | number | `audio_service` | fixed_contract |
| `audio_service_op_write_stream_tracked` | `13` | `u16` | value | number | `audio_service` | fixed_contract |
| `audio_service_op_close_stream_progress` | `14` | `u16` | value | number | `audio_service` | fixed_contract |
| `program_completion_flag_output_available` | `16` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_completion_flag_output_truncated` | `32` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_completion_flag_output_incomplete` | `64` | `u32` | flag | bitmask | `program_completion` | fixed_contract |
| `program_observation_flag_portable` | `1` | `u32` | flag | bitmask | `program_observation` | fixed_contract |
| `file_name_limits_flag_known` | `1` | `u32` | value | number | `file_name_limits` | fixed_contract |
| `file_name_limits_flag_mount_identity` | `2` | `u32` | value | number | `file_name_limits` | fixed_contract |
| `file_name_provider_fat32` | `2` | `u32` | value | number | `file_name_provider` | fixed_contract |
| `file_name_provider_ntfs` | `3` | `u32` | value | number | `file_name_provider` | fixed_contract |
| `file_name_rule_fat_long` | `1` | `u32` | value | number | `file_name_rules` | fixed_contract |
| `file_name_rule_append_create_short` | `2` | `u32` | value | number | `file_name_rules` | fixed_contract |
| `file_name_rule_ascii_casefold` | `4` | `u32` | value | number | `file_name_rules` | fixed_contract |
| `file_name_rule_ntfs_upcase` | `8` | `u32` | value | number | `file_name_rules` | fixed_contract |
| `file_name_atomic_stage_short` | `1` | `u32` | value | number | `file_name_atomic` | fixed_contract |
| `file_name_atomic_backup_short` | `2` | `u32` | value | number | `file_name_atomic` | fixed_contract |
| `file_name_atomic_owned_target_short` | `4` | `u32` | value | number | `file_name_atomic` | fixed_contract |
| `file_replace_atomic_error_name_not_supported` | `-64` | `i32` | value | number | `file_replace_atomic` | fixed_contract |
| `file_replace_atomic_error_name_too_long` | `-65` | `i32` | value | number | `file_replace_atomic` | fixed_contract |
| `gui_pointer_mode_drag` | `1` | `u32` | value | number | `gui_pointer_mode` | fixed_contract |
| `gui_pointer_mode_relative` | `2` | `u32` | value | number | `gui_pointer_mode` | fixed_contract |
| `gui_pointer_state_none` | `0` | `u32` | value | number | `gui_pointer_state` | fixed_contract |
| `gui_pointer_state_pending` | `1` | `u32` | value | number | `gui_pointer_state` | fixed_contract |
| `gui_pointer_state_active` | `2` | `u32` | value | number | `gui_pointer_state` | fixed_contract |
| `gui_pointer_state_released` | `3` | `u32` | value | number | `gui_pointer_state` | fixed_contract |
| `gui_pointer_state_cancelled` | `4` | `u32` | value | number | `gui_pointer_state` | fixed_contract |
| `gui_pointer_reason_none` | `0` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_explicit` | `1` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_focus_lost` | `2` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_window_closed` | `3` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_minimized` | `4` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_process_ended` | `5` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_desktop_changed` | `6` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_wm_conflict` | `7` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_source_unsupported` | `8` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_reason_input_overflow` | `9` | `u32` | value | number | `gui_pointer_reason` | fixed_contract |
| `gui_pointer_capability_drag` | `1` | `u32` | value | number | `gui_pointer_capability` | fixed_contract |
| `gui_pointer_capability_relative_physical` | `2` | `u32` | value | number | `gui_pointer_capability` | fixed_contract |
| `gui_pointer_capability_absolute_remote_drag` | `4` | `u32` | value | number | `gui_pointer_capability` | fixed_contract |
| `gui_pointer_capability_wheel_events` | `8` | `u32` | value | number | `gui_pointer_capability` | fixed_contract |
| `gui_pointer_source_physical_relative` | `1` | `u32` | value | number | `gui_pointer_source` | fixed_contract |
| `gui_pointer_source_remote_absolute` | `2` | `u32` | value | number | `gui_pointer_source` | fixed_contract |
| `gui_pointer_host_bind` | `0` | `u32` | value | number | `gui_pointer_host` | fixed_contract |
| `gui_pointer_host_snapshot` | `1` | `u32` | value | number | `gui_pointer_host` | fixed_contract |
| `gui_pointer_host_grant` | `2` | `u32` | value | number | `gui_pointer_host` | fixed_contract |
| `gui_pointer_host_cancel` | `3` | `u32` | value | number | `gui_pointer_host` | fixed_contract |
| `gui_pointer_host_deliver` | `4` | `u32` | value | number | `gui_pointer_host` | fixed_contract |
| `gui_pointer_host_unbind` | `5` | `u32` | value | number | `gui_pointer_host` | fixed_contract |
| `gui_pointer_error_invalid` | `-1` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_stale` | `-2` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_busy` | `-3` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_context` | `-4` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_unsupported` | `-5` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_queue_full` | `-6` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_exhausted` | `-7` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_error_unavailable` | `-8` | `i32` | value | number | `gui_pointer_error` | fixed_contract |
| `gui_pointer_host_flag_motion_snapshot` | `1` | `u32` | value | number | `gui_pointer_host_flags` | fixed_contract |
| `gui_host_input_operation_query` | `0` | `u32` | value | number | `gui_host_input_operation` | fixed_contract |
| `gui_host_input_operation_post` | `1` | `u32` | value | number | `gui_host_input_operation` | fixed_contract |
| `gui_host_input_operation_reset` | `2` | `u32` | value | number | `gui_host_input_operation` | fixed_contract |
| `gui_input_reset_reason_overflow` | `1` | `u32` | value | number | `gui_input_reset_reason` | fixed_contract |
| `gui_input_reset_reason_focus_lost` | `2` | `u32` | value | number | `gui_input_reset_reason` | fixed_contract |
| `gui_input_reset_reason_window_closed` | `3` | `u32` | value | number | `gui_input_reset_reason` | fixed_contract |
| `gui_input_reset_reason_desktop_changed` | `4` | `u32` | value | number | `gui_input_reset_reason` | fixed_contract |
| `gui_input_reset_reason_process_ended` | `5` | `u32` | value | number | `gui_input_reset_reason` | fixed_contract |
| `gui_host_input_error_invalid` | `-1` | `i32` | value | number | `gui_host_input_error` | fixed_contract |
| `gui_host_input_error_stale` | `-2` | `i32` | value | number | `gui_host_input_error` | fixed_contract |
| `gui_host_input_error_busy` | `-3` | `i32` | value | number | `gui_host_input_error` | fixed_contract |
| `gui_host_input_error_context` | `-4` | `i32` | value | number | `gui_host_input_error` | fixed_contract |
| `audio_duration_ticks_unavailable` | `18446744073709551615` | `u64` | value | ticks | `audio` | fixed_contract |
| `service_deadline_footer_magic` | `1279538258` | `u32` | magic | number | `service_api` | fixed_contract |
| `service_deadline_footer_version` | `1` | `u16` | version | version | `service_api` | fixed_contract |
| `net_service_tcp_deadline_poll` | `0` | `u64` | value | ticks | `tcp_service` | fixed_contract |
| `desktop_evidence_op_scope` | `4784` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_op_reserve` | `4785` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_op_offer` | `4786` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_op_ack` | `4787` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_op_status` | `4788` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_op_read` | `4789` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_op_release` | `4790` | `u16` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_reserved` | `1` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_waiting` | `2` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_offered` | `3` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_acknowledged` | `4` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_released` | `5` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_expired` | `6` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_phase_unavailable` | `7` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_ok` | `0` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_unknown` | `-1` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_invalid` | `-2` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_stale` | `-3` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_quota` | `-4` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_expired` | `-5` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_unavailable` | `-6` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_pending` | `-7` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_not_acknowledged` | `-8` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_result_released` | `-9` | `i32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_max_leases` | `16` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_reservation_ms` | `300000` | `u64` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_evidence_max_output_chunk` | `3808` | `u32` | value | number | `desktop_evidence` | fixed_contract |
| `desktop_action_op_scope` | `4800` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_grant` | `4801` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_command` | `4802` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_status` | `4803` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_release` | `4804` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_exchange` | `4805` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_app_view` | `4806` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_op_app_frame` | `4807` | `u16` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_kind_resize` | `1` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_kind_minimize` | `2` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_kind_restore` | `3` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_right_resize` | `1` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_right_minimize` | `2` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_right_restore` | `4` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_right_all` | `7` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_none` | `0` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_granted` | `1` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_pending` | `2` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_applied` | `3` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_rejected` | `4` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_expired` | `5` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_released` | `6` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_ended` | `7` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_ok` | `0` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_unknown` | `-1` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_invalid` | `-2` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_stale` | `-3` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_quota` | `-4` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_expired` | `-5` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_unavailable` | `-6` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_pending` | `-7` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_not_owner` | `-8` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_unsupported` | `-9` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_busy` | `-10` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_target_ended` | `-11` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_result_released` | `-12` | `i32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_proof_view` | `1` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_proof_composed` | `2` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_proof_app_fresh` | `4` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_proof_unsupported` | `8` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_proof_app_ack` | `16` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_proof_invisible` | `32` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_max_grants` | `16` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_max_timeout_ms` | `5000` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `gui_resize_action_view_key` | `1464686129` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `desktop_action_phase_unknown` | `8` | `u32` | value | number | `desktop_actions` | fixed_contract |
| `service_inventory_end` | `1` | `u32` | value | number | `service_inventory` | fixed_contract |
| `service_inventory_dynamic` | `2` | `u32` | value | number | `service_inventory` | fixed_contract |
| `service_inventory_page_rows` | `8` | `usize` | value | number | `service_inventory` | fixed_contract |
| `service_control_start` | `1` | `u32` | value | number | `service_control` | fixed_contract |
| `service_control_stop` | `2` | `u32` | value | number | `service_control` | fixed_contract |
| `service_control_restart` | `3` | `u32` | value | number | `service_control` | fixed_contract |
| `service_control_mode` | `4` | `u32` | value | number | `service_control` | fixed_contract |
| `service_control_remove` | `5` | `u32` | value | number | `service_control` | fixed_contract |
| `gui_frame_command_kind_gradient_rounded_rect` | `14` | `u32` | value | number | `gui_frame` | fixed_contract |
| `gui_gradient_kind_linear` | `1` | `u32` | value | number | `gui_gradient` | fixed_contract |
| `gui_gradient_kind_radial` | `2` | `u32` | value | number | `gui_gradient` | fixed_contract |
| `gui_gradient_max_stops` | `8` | `u32` | value | number | `gui_gradient` | fixed_contract |
| `gui_gradient_resource_version` | `1` | `u32` | version | number | `gui_gradient` | fixed_contract |
| `gui_gradient_min_r4draw_version` | `39` | `u32` | version | number | `gui_gradient` | fixed_contract |
| `device_snapshot_version` | `1` | `u32` | version | number | `device_snapshot` | fixed_contract |
| `device_snapshot_flag_complete` | `1` | `u32` | flag | bitmask | `device_snapshot` | fixed_contract |
| `device_snapshot_flag_independent_copies` | `2` | `u32` | flag | bitmask | `device_snapshot` | fixed_contract |
| `file_metadata2_version` | `1` | `u32` | version | number | `file_metadata2` | fixed_contract |
| `directory_metadata2_flag_bound` | `1` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_identity2_flag_namespace` | `1` | `u32` | flag | bitmask | `file_identity2` | fixed_contract |
| `file_identity2_flag_root` | `2` | `u32` | flag | bitmask | `file_identity2` | fixed_contract |
| `file_identity2_flag_fat_slot` | `4` | `u32` | flag | bitmask | `file_identity2` | fixed_contract |
| `file_identity2_flag_ntfs_record` | `8` | `u32` | flag | bitmask | `file_identity2` | fixed_contract |
| `file_metadata2_flag_exists` | `1` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_directory` | `2` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_identity_valid` | `4` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_byte_size_valid` | `8` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_content_revision_valid` | `16` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_backend_node_valid` | `32` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_dos_time_valid` | `64` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `file_metadata2_flag_reparse` | `128` | `u32` | flag | bitmask | `file_metadata2` | fixed_contract |
| `font_metrics2_version` | `1` | `u32` | version | number | `font_metrics2` | fixed_contract |
| `font_metrics2_flag_complete` | `1` | `u32` | flag | bitmask | `font_metrics2` | fixed_contract |
| `font_metrics2_max_bytes` | `4096` | `u32` | value | bytes | `font_metrics2` | fixed_contract |
| `waitset_version` | `1` | `u32` | version | number | `waitset` | fixed_contract |
| `waitset_max_sources` | `32` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_max_source_subscribers` | `32` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_notification` | `1` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_timer` | `2` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_flag_stop` | `1` | `u32` | flag | bitmask | `waitset` | fixed_contract |
| `waitset_deadline_poll` | `0` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_deadline_finite` | `1` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_deadline_forever` | `2` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_outcome_ready` | `0` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_outcome_timeout` | `1` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_outcome_closed` | `2` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_outcome_cancelled` | `3` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_event_ready` | `0` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_event_source_closed` | `1` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_event_clock_changed` | `2` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_flag_more` | `1` | `u32` | flag | bitmask | `waitset` | fixed_contract |
| `waitset_flag_rescan` | `2` | `u32` | flag | bitmask | `waitset` | fixed_contract |
| `waitset_flag_coalesced` | `4` | `u32` | flag | bitmask | `waitset` | fixed_contract |
| `waitset_source_io` | `3` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_process` | `4` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_thread` | `5` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_service_endpoint` | `6` | `u32` | value | number | `waitset` | fixed_contract |
| `waitset_source_gui_activity` | `7` | `u32` | value | number | `waitset` | fixed_contract |
| `clipboard_offer_version` | `1` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_max_offer_bytes` | `4194304` | `u64` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_payload_budget` | `33554432` | `u64` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_lease_ns` | `30000000000` | `u64` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_max_items` | `8` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_max_formats` | `16` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_max_stages` | `4` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_max_snapshots` | `16` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_put_chunk` | `4048` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_read_chunk` | `4040` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_state_writing` | `1` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_state_committed` | `2` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_state_snapshot` | `3` | `u32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_flag_eof` | `1` | `u32` | flag | bitmask | `clipboard_offer` | fixed_contract |
| `clipboard_offer_format_text_utf8` | `1` | `u32` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_format_png` | `2` | `u32` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_format_xrgb32` | `3` | `u32` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_format_file_list` | `4` | `u32` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_format_text_bytes` | `5` | `u32` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_info` | `64` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_begin` | `65` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_declare` | `66` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_put` | `67` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_commit` | `68` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_abort` | `69` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_snapshot` | `70` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_enumerate` | `71` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_read` | `72` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_release` | `73` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_op_status` | `74` | `u16` | identity | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_invalid` | `-6101` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_too_large` | `-6102` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_capacity` | `-6103` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_stale_revision` | `-6104` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_provider_changed` | `-6105` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_closed` | `-6106` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_unsupported` | `-6107` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_invalid_encoding` | `-6108` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_incomplete` | `-6109` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `clipboard_offer_error_not_found` | `-6110` | `i32` | value | number | `clipboard_offer` | fixed_contract |
| `network_family_ipv4` | `4` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_family_ipv6` | `6` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_cap_ipv4` | `1` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_ipv6` | `2` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_dns_a` | `4` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_dns_aaaa_codec` | `8` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_dns_aaaa` | `16` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_tcp` | `32` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_udp` | `64` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_listen` | `128` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_dual_stack` | `256` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_v4_mapped` | `512` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_datagram_truncate` | `1024` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_cap_retained_terminal` | `2048` | `u64` | flag | bitmask | `network_family` | fixed_contract |
| `network_policy_dual_stack` | `1` | `u32` | flag | bitmask | `network_family` | fixed_contract |
| `network_policy_v4_mapped` | `2` | `u32` | flag | bitmask | `network_family` | fixed_contract |
| `network_policy_fallback` | `4` | `u32` | flag | bitmask | `network_family` | fixed_contract |
| `network_flag_more` | `1` | `u32` | flag | bitmask | `network_family` | fixed_contract |
| `network_flag_truncated` | `2` | `u32` | flag | bitmask | `network_family` | fixed_contract |
| `network_state_ready` | `1` | `u32` | value | number | `network_family` | fixed_contract |
| `network_state_would_block` | `2` | `u32` | value | number | `network_family` | fixed_contract |
| `network_state_eof` | `3` | `u32` | value | number | `network_family` | fixed_contract |
| `network_state_reset` | `4` | `u32` | value | number | `network_family` | fixed_contract |
| `network_state_local_closed` | `5` | `u32` | value | number | `network_family` | fixed_contract |
| `network_state_timeout` | `6` | `u32` | value | number | `network_family` | fixed_contract |
| `network_max_answers` | `32` | `u32` | value | number | `network_family` | fixed_contract |
| `network_page_capacity` | `16` | `u32` | value | number | `network_family` | fixed_contract |
| `network_lease_ns` | `30000000000` | `u64` | value | number | `network_family` | fixed_contract |
| `network_op_info` | `1280` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_connect` | `1281` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_bind` | `1282` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_read` | `1283` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_write` | `1284` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_send` | `1285` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_recv` | `1286` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_close` | `1287` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_listen` | `1288` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_accept` | `1289` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_resolve` | `1290` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_op_release` | `1291` | `u16` | identity | number | `network_family` | fixed_contract |
| `net_service_op_tcp_connect_retained_result` | `797` | `u16` | identity | number | `network_family` | fixed_contract |
| `network_error_invalid` | `-6201` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_unsupported_family` | `-6202` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_unsupported_policy` | `-6203` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_unsupported_scope` | `-6204` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_provider_changed` | `-6205` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_bad_socket` | `-6206` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_capacity` | `-6207` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_clock_changed` | `-6208` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_timeout` | `-6209` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_would_block` | `-6210` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_reset` | `-6211` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_backend` | `-6212` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_not_found` | `-6213` | `i32` | value | number | `network_family` | fixed_contract |
| `network_error_truncated_dns` | `-6214` | `i32` | value | number | `network_family` | fixed_contract |
| `net_backend_cap_rx_multicast` | `2048` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ethernet_flag_ipv6` | `64` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ethernet_flag_multicast` | `128` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `network_link_op_identity` | `0` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `network_link_op_info` | `1` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `network_link_op_transmit` | `2` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `network_link_flag_available` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `network_link_flag_up` | `2` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `network_link_flag_multicast` | `4` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `network_link_flag_clock_valid` | `8` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_op_info` | `1536` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_address` | `1537` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_route` | `1538` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_configure` | `1539` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_send` | `1540` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_receive` | `1541` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_tick` | `1542` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_op_handle_rx` | `1543` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `icmpv6_op_parse` | `1568` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `icmpv6_op_seal` | `1569` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `icmpv6_op_checksum` | `1570` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `icmpv6_op_echo_reply` | `1571` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `icmpv6_op_error` | `1572` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_op_info` | `1600` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_op_handle_rx` | `1601` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_op_resolve` | `1602` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_op_confirm` | `1603` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_op_tick` | `1604` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_op_link_reset` | `1605` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_cap_packet` | `1` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_icmp` | `2` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_nd` | `4` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_dad` | `8` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_slaac` | `16` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_extensions` | `32` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_reassembly` | `64` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_pmtu` | `128` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_cap_static_address` | `256` | `u64` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_tentative` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_preferred` | `2` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_deprecated` | `4` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_duplicate` | `8` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_manual` | `16` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_slaac` | `32` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_address_flag_link_local` | `64` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_route_flag_on_link` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_route_flag_default` | `2` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_route_flag_router` | `4` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_route_flag_manual` | `8` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_config_remove` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_minimum_mtu` | `1280` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_payload_capacity` | `1504` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ipv6_prefix_capacity` | `8` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_action_none` | `0` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_action_resolved` | `1` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_action_multicast_probe` | `2` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_action_unicast_probe` | `3` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_action_timed_out` | `4` | `u32` | value | number | `ipv6_provider` | fixed_contract |
| `ndp_event_flag_mac_present` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ndp_event_flag_nonce_present` | `2` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ndp_event_flag_router` | `2147483648` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ndp_event_flag_solicited` | `1073741824` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ndp_event_flag_override` | `536870912` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ndp_request_fragmented` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ndp_confirm_probe_sent` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `ipv6_packet_flag_fragmented` | `1` | `u32` | flag | bitmask | `ipv6_provider` | fixed_contract |
| `network_transport_op_tick` | `1647` | `u32` | value | operation | `network_transport` | fixed_contract |
| `ipv6_op_prepare` | `1544` | `u32` | value | operation | `ipv6_provider` | fixed_contract |
| `net_service_op_tcp_listen_retained_result` | `798` | `u16` | value | number | `network_family` | fixed_contract |
| `network_error_packet_too_big` | `-6215` | `i32` | value | number | `network_family` | fixed_contract |
| `byte_pipe_reader` | `1` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_writer` | `2` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_ready` | `1` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_would_block` | `2` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_eof` | `3` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_broken_pipe` | `4` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_cancelled` | `5` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_timed_out` | `6` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `byte_pipe_closed` | `7` | `u32` | value | number | `byte_pipe` | fixed_contract |
| `launch_io_default` | `0` | `u32` | value | number | `launch_io` | fixed_contract |
| `launch_io_pipe` | `1` | `u32` | value | number | `launch_io` | fixed_contract |
| `composition_feature_utf8_grapheme` | `1` | `u32` | value | number | `composition` | fixed_contract |
| `composition_event_preedit` | `1` | `u32` | value | number | `composition` | fixed_contract |
| `composition_event_commit` | `2` | `u32` | value | number | `composition` | fixed_contract |
| `composition_event_cancel` | `3` | `u32` | value | number | `composition` | fixed_contract |
| `composition_op_capability` | `4920` | `u16` | value | number | `composition` | fixed_contract |
| `composition_op_focus` | `4921` | `u16` | value | number | `composition` | fixed_contract |
| `audio_capture_op_service` | `6100` | `u16` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_op_catalog` | `0` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_op_open` | `1` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_op_read` | `2` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_op_query` | `3` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_op_stop` | `4` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_op_close` | `5` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_source_adc` | `1` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_source_controlled` | `2` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_source_hardware_timestamp` | `4` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_reply_source` | `1` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_reply_hardware_stopped` | `2` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_reply_discontinuity` | `4` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_reply_hardware_timestamp` | `8` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_reply_open_pending` | `16` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_state_reserved` | `0` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_state_open` | `1` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_state_stopping` | `2` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_state_stopped` | `3` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_state_closed` | `4` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_state_source_gone` | `5` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_backend_magic` | `844120387` | `u32` | value | number | `audio_capture` | fixed_contract |
| `audio_capture_backend_version` | `1` | `u32` | value | number | `audio_capture` | fixed_contract |

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
| `r4xstart_r4audio_size` | `200` | `u32` | bytes | `r4xstart_r4audio` | fixed_contract |
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
| `serial_max_transfer_bytes` | `2147483647` | `u32` | bytes | `serial` | fixed_contract |
| `serial_bounce_bytes` | `256` | `u32` | bytes | `serial` | fixed_contract |
| `byte_pipe_max_capacity` | `65536` | `u64` | bytes | `byte_pipe` | fixed_contract |
| `byte_pipe_max_step` | `4096` | `u64` | bytes | `byte_pipe` | fixed_contract |
| `byte_pipe_max_references` | `32` | `u64` | number | `byte_pipe` | fixed_contract |
| `byte_pipe_max_pipes` | `64` | `u64` | number | `byte_pipe` | fixed_contract |
| `byte_pipe_max_payload` | `4194304` | `u64` | bytes | `byte_pipe` | fixed_contract |
| `byte_pipe_max_waiters` | `32` | `u64` | number | `byte_pipe` | fixed_contract |
| `composition_max_text_bytes` | `1024` | `u64` | bytes | `composition` | fixed_contract |
| `composition_max_document_bytes` | `65536` | `u64` | bytes | `composition` | fixed_contract |
| `audio_capture_max_sources_per_backend` | `32` | `u64` | count | `audio_capture` | fixed_contract |
| `audio_capture_max_sessions` | `4` | `u64` | count | `audio_capture` | fixed_contract |
| `audio_capture_max_queue_bytes` | `65536` | `u64` | bytes | `audio_capture` | fixed_contract |
| `audio_capture_max_read_bytes` | `2048` | `u64` | bytes | `audio_capture` | fixed_contract |
