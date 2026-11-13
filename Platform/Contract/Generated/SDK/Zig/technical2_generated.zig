// Generated from canonical API/Generation2.json. DO NOT EDIT.
const base = @import("abi.zig");
pub const driver_api2_magic: u32 = 843665476;
pub const driver_api2_version: u32 = 1;
pub const protocol_api2_magic: u32 = 843665488;
pub const protocol_api2_version: u32 = 1;
pub const audio_backend2_magic: u32 = 843208001;
pub const audio_backend2_version: u32 = 3;
pub const AudioBackendStatusFn2 = *const fn (?*anyopaque, *AudioBackendStatus2) callconv(.c) i32;
pub const AudioBackendRegisterFn2 = *const fn ([*:0]const u8, *const AudioBackend2) callconv(.c) i32;
pub const AudioCaptureRegisterFn2 = *const fn ([*:0]const u8, *const AudioCaptureBackend2) callconv(.c) i32;
pub const DriverApi2 = extern struct {
    magic: u32,
    version: u32,
    size: u32,
    reserved: u32,
    log_info: *const fn ([*:0]const u8) callconv(.c) void,
    log_warn: *const fn ([*:0]const u8) callconv(.c) void,
    log_error: *const fn ([*:0]const u8) callconv(.c) void,
    port_inb: *const fn (u16) callconv(.c) u8,
    port_outb: *const fn (u16, u8) callconv(.c) void,
    alloc_dma_buffer: *const fn (u32, u32) callconv(.c) u64,
    free_dma_buffer: *const fn (u64, u32) callconv(.c) void,
    request_irq: *const fn (u8, *const anyopaque) callconv(.c) i32,
    release_irq: *const fn (u8) callconv(.c) i32,
    get_option: *const fn ([*:0]const u8, [*:0]const u8) callconv(.c) [*:0]const u8,
    register_storage_backend: *const fn ([*:0]const u8, *const anyopaque) callconv(.c) i32,
    register_input_backend: *const fn ([*:0]const u8, *const anyopaque) callconv(.c) i32,
    register_mixer_backend: *const fn ([*:0]const u8, *const anyopaque) callconv(.c) i32,
    register_net_backend: *const fn ([*:0]const u8, *const anyopaque) callconv(.c) i32,
    alloc_dma_region: *const fn (u32, u32, *base.DmaBuffer) callconv(.c) i32,
    free_dma_region: *const fn (*base.DmaBuffer) callconv(.c) void,
    pci_device_count: *const fn () callconv(.c) u32,
    pci_device_at: *const fn (u32, *base.PciDeviceInfo) callconv(.c) i32,
    pci_find_by_class: *const fn (u8, u8, u32, *base.PciDeviceInfo) callconv(.c) i32,
    pci_read_config32: *const fn (u8, u8, u8, u8, u16) callconv(.c) u32,
    pci_write_config32: *const fn (u8, u8, u8, u8, u16, u32) callconv(.c) i32,
    pci_read_bar: *const fn (u8, u8, u8, u8, u8) callconv(.c) u32,
    pci_enable_bus_master: *const fn (u8, u8, u8, u8, u32) callconv(.c) i32,
    irq_register: *const fn (u8, base.IrqHandler, usize, u32) callconv(.c) i32,
    irq_unregister: *const fn (u8, base.IrqHandler, usize) callconv(.c) i32,
    irq_stats: *const fn (u8, *base.IrqStats) callconv(.c) i32,
    pci_map_bar: *const fn (u8, u8, u8, u8, u8, u32, u32, *base.MmioRegion) callconv(.c) i32,
    port_inw: *const fn (u16) callconv(.c) u16,
    port_outw: *const fn (u16, u16) callconv(.c) void,
    port_inl: *const fn (u16) callconv(.c) u32,
    port_outl: *const fn (u16, u32) callconv(.c) void,
    net_receive_frame: *const fn (i32, [*]const u8, u32) callconv(.c) i32,
    register_audio_output_backend: AudioBackendRegisterFn2,
    unregister_audio_backend: *const fn ([*:0]const u8) callconv(.c) i32,
    tick_count: *const fn () callconv(.c) u64,
    timer_frequency: *const fn () callconv(.c) u32,
    wait_ticks: *const fn (u64) callconv(.c) void,
    register_synth_engine_v2: *const fn ([*:0]const u8, *const base.SynthEngine) callconv(.c) i32,
    unregister_storage_backend: *const fn ([*:0]const u8) callconv(.c) i32,
    storage_backend_recovery_begin: *const fn ([*:0]const u8) callconv(.c) i32,
    storage_backend_recovery_finish: *const fn ([*:0]const u8, i32) callconv(.c) i32,
    register_usb_host_controller: *const fn ([*:0]const u8, *const base.UsbHostController) callconv(.c) i32,
    unregister_usb_host_controller: *const fn ([*:0]const u8) callconv(.c) i32,
    driver_work_submit: *const fn (base.DriverWorkHandler, usize, u32, *u32) callconv(.c) i32,
    driver_work_cancel: *const fn (u32) callconv(.c) i32,
    driver_completion_wait: *const fn (u32, u64, *i32) callconv(.c) i32,
    driver_completion_status: *const fn (u32, *base.DriverCompletionStatus) callconv(.c) i32,
    driver_completion_release: *const fn (u32) callconv(.c) i32,
    driver_work_summary: *const fn (*base.DriverWorkSummary) callconv(.c) i32,
    pci_enable_msi: *const fn (u8, u8, u8, u8) callconv(.c) i32,
    alloc_dma_region_constrained: *const fn (u32, u32, u64, *base.DmaBuffer) callconv(.c) i32,
    pci_disable_msi: *const fn (u8, u8, u8, u8) callconv(.c) i32,
    protocol_dispatch: ?*const fn ([*:0]const u8, u32, *const base.ProtocolBuffer, *base.ProtocolBuffer) callconv(.c) i32 = null,
    dma_pin_buffer: *const fn (u64, u32, u32, *base.DmaPinnedBuffer) callconv(.c) i32,
    dma_map_pinned: *const fn (*const base.DmaPinnedBuffer, *const base.DmaConstraints, u32, *base.DmaMapping) callconv(.c) i32,
    dma_sync_for_device: *const fn (*const base.DmaMapping) callconv(.c) i32,
    dma_sync_for_cpu: *const fn (*const base.DmaMapping) callconv(.c) i32,
    dma_unmap: *const fn (*base.DmaMapping) callconv(.c) i32,
    dma_unpin_buffer: *const fn (*base.DmaPinnedBuffer) callconv(.c) i32,
    driver_work_submit_request: *const fn (*const base.DriverWorkRequest, *u32) callconv(.c) i32,
    activate_usb_host_controller: *const fn ([*:0]const u8, u32) callconv(.c) i32,
    register_display_blit_backend: *const fn ([*:0]const u8, *const base.DisplayBlitBackend) callconv(.c) i32,
    unregister_display_blit_backend: *const fn ([*:0]const u8) callconv(.c) i32,
    net_schedule_rx: *const fn (i32) callconv(.c) i32,
    net_backend_query: *const fn (i32, *base.NetBackendNegotiation) callconv(.c) i32,
    net_receive_packet: *const fn (i32, *const base.NetPacket) callconv(.c) i32,
    gfx_memory_query: ?*const fn (*base.GfxDriverMemoryApi) callconv(.c) i32 = null,
    gfx_queue_query: ?*const fn (*base.GfxDriverQueueApi) callconv(.c) i32 = null,
    gfx_output_query: ?*const fn (*base.GfxDriverOutputApi) callconv(.c) i32 = null,
    gfx_display_query: ?*const fn (*base.GfxDriverDisplayApi) callconv(.c) i32 = null,
    resource_query: ?*const fn (*base.DriverResourceApi) callconv(.c) i32 = null,
    heap_query: ?*const fn (*base.DriverHeapApi) callconv(.c) i32 = null,
    monotonic_clock: ?*const fn (*base.MonotonicClockInfo) callconv(.c) i32 = null,
    thread_query: ?*const fn (*base.DriverThreadApi) callconv(.c) i32 = null,
    semaphore_query: ?*const fn (*base.DriverSemaphoreApi) callconv(.c) i32 = null,
    dma_sync_range_for_device: ?*const fn (*const base.DmaMapping, u32, u32) callconv(.c) i32 = null,
    dma_sync_range_for_cpu: ?*const fn (*const base.DmaMapping, u32, u32) callconv(.c) i32 = null,
    driver_work_submit_owned: ?*const fn (base.DriverWorkHandler, usize, *u32) callconv(.c) i32 = null,
    serial_query: ?*const fn (*base.DriverSerialApi) callconv(.c) i32 = null,
    register_audio_output_epoch: ?*const fn ([*:0]const u8, base.AudioOutputEpochFn) callconv(.c) i32 = null,
    register_audio_capture_backend: ?AudioCaptureRegisterFn2 = null,
};
comptime {
    if (@sizeOf(DriverApi2) != 664 or @alignOf(DriverApi2) != 8) @compileError("Canonical technical layout");
    if (@offsetOf(DriverApi2, "magic") != 0) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "version") != 4) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "size") != 8) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "reserved") != 12) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "log_info") != 16) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "log_warn") != 24) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "log_error") != 32) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "port_inb") != 40) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "port_outb") != 48) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "alloc_dma_buffer") != 56) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "free_dma_buffer") != 64) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "request_irq") != 72) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "release_irq") != 80) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "get_option") != 88) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_storage_backend") != 96) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_input_backend") != 104) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_mixer_backend") != 112) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_net_backend") != 120) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "alloc_dma_region") != 128) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "free_dma_region") != 136) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_device_count") != 144) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_device_at") != 152) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_find_by_class") != 160) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_read_config32") != 168) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_write_config32") != 176) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_read_bar") != 184) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_enable_bus_master") != 192) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "irq_register") != 200) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "irq_unregister") != 208) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "irq_stats") != 216) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_map_bar") != 224) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "port_inw") != 232) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "port_outw") != 240) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "port_inl") != 248) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "port_outl") != 256) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "net_receive_frame") != 264) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_audio_output_backend") != 272) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "unregister_audio_backend") != 280) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "tick_count") != 288) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "timer_frequency") != 296) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "wait_ticks") != 304) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_synth_engine_v2") != 312) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "unregister_storage_backend") != 320) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "storage_backend_recovery_begin") != 328) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "storage_backend_recovery_finish") != 336) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_usb_host_controller") != 344) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "unregister_usb_host_controller") != 352) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_work_submit") != 360) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_work_cancel") != 368) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_completion_wait") != 376) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_completion_status") != 384) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_completion_release") != 392) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_work_summary") != 400) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_enable_msi") != 408) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "alloc_dma_region_constrained") != 416) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "pci_disable_msi") != 424) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "protocol_dispatch") != 432) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_pin_buffer") != 440) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_map_pinned") != 448) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_sync_for_device") != 456) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_sync_for_cpu") != 464) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_unmap") != 472) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_unpin_buffer") != 480) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_work_submit_request") != 488) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "activate_usb_host_controller") != 496) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_display_blit_backend") != 504) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "unregister_display_blit_backend") != 512) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "net_schedule_rx") != 520) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "net_backend_query") != 528) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "net_receive_packet") != 536) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "gfx_memory_query") != 544) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "gfx_queue_query") != 552) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "gfx_output_query") != 560) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "gfx_display_query") != 568) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "resource_query") != 576) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "heap_query") != 584) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "monotonic_clock") != 592) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "thread_query") != 600) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "semaphore_query") != 608) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_sync_range_for_device") != 616) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "dma_sync_range_for_cpu") != 624) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "driver_work_submit_owned") != 632) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "serial_query") != 640) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_audio_output_epoch") != 648) @compileError("Canonical technical field");
    if (@offsetOf(DriverApi2, "register_audio_capture_backend") != 656) @compileError("Canonical technical field");
}
pub const ProtocolApi2 = extern struct {
    magic: u32,
    version: u32,
    size: u32,
    reserved: u32,
    log_info: *const fn ([*:0]const u8) callconv(.c) void,
    log_warn: *const fn ([*:0]const u8) callconv(.c) void,
    log_error: *const fn ([*:0]const u8) callconv(.c) void,
    register_role: *const fn ([*:0]const u8, u32, u32) callconv(.c) i32,
    set_status: *const fn (u32, [*:0]const u8) callconv(.c) i32,
    dependency_status: *const fn ([*:0]const u8) callconv(.c) i32,
    alloc: *const fn (u32, u32) callconv(.c) ?*anyopaque,
    free: *const fn (?*anyopaque, u32) callconv(.c) void,
    file_read: *const fn ([*:0]const u8, [*]u8, u32) callconv(.c) i32,
    cpu_acceleration_info: ?*const fn (*base.CpuAccelerationInfo) callconv(.c) i32 = null,
    cpu_acceleration_work: ?*const fn (u32, u32, ?*const base.CpuPureWorkFn, u64, *base.CpuAccelerationWork) callconv(.c) i32 = null,
    entropy_source_info: ?*const fn (*base.EntropySourceInfo) callconv(.c) i32 = null,
    entropy_fill: ?*const fn ([*]u8, u32) callconv(.c) i32 = null,
    protocol_dispatch: ?*const fn ([*]const u8, u32, u32, *const base.ProtocolBuffer, *base.ProtocolBuffer) callconv(.c) i32 = null,
    link_io: ?*const fn (*const base.NetworkLinkRequest, *base.NetworkLinkInfo) callconv(.c) i32 = null,
    process_status: ?*const fn (*const base.ProgramProcessHandle, *base.ProgramInstanceInfo) callconv(.c) i32 = null,
};
comptime {
    if (@sizeOf(ProtocolApi2) != 144 or @alignOf(ProtocolApi2) != 8) @compileError("Canonical technical layout");
    if (@offsetOf(ProtocolApi2, "magic") != 0) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "version") != 4) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "size") != 8) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "reserved") != 12) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "log_info") != 16) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "log_warn") != 24) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "log_error") != 32) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "register_role") != 40) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "set_status") != 48) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "dependency_status") != 56) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "alloc") != 64) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "free") != 72) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "file_read") != 80) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "cpu_acceleration_info") != 88) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "cpu_acceleration_work") != 96) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "entropy_source_info") != 104) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "entropy_fill") != 112) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "protocol_dispatch") != 120) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "link_io") != 128) @compileError("Canonical technical field");
    if (@offsetOf(ProtocolApi2, "process_status") != 136) @compileError("Canonical technical field");
}
pub const AudioBackendStatus2 = extern struct {
    active: u32 = 0,
    writes: u64 = 0,
    underruns: u64 = 0,
    errors: u64 = 0,
    last_result: i32 = 0,
    reserved: u32 = 0,
    refills: u64 = 0,
    silence_refills: u64 = 0,
    buffer_bytes: u64 = 0,
    queued_buffers: u64 = 0,
    last_buffer_bytes: u64 = 0,
};
comptime {
    if (@sizeOf(AudioBackendStatus2) != 80 or @alignOf(AudioBackendStatus2) != 8) @compileError("Canonical technical layout");
    if (@offsetOf(AudioBackendStatus2, "active") != 0) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "writes") != 8) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "underruns") != 16) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "errors") != 24) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "last_result") != 32) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "reserved") != 36) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "refills") != 40) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "silence_refills") != 48) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "buffer_bytes") != 56) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "queued_buffers") != 64) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackendStatus2, "last_buffer_bytes") != 72) @compileError("Canonical technical field");
}
pub const AudioBackend2 = extern struct {
    magic: u32 = audio_backend2_magic,
    version: u32 = audio_backend2_version,
    size: u32 = @sizeOf(AudioBackend2),
    flags: u32 = 0,
    formats: u32 = base.audio_backend_format_s16le,
    min_rate: u32 = 0,
    max_rate: u32 = 0,
    preferred_rate: u32 = 48000,
    max_channels: u16 = 2,
    reserved: u16 = 0,
    context: ?*anyopaque = null,
    write_pcm: ?*const fn (?*anyopaque, [*]const u8, u32, u32, u16, u16) callconv(.c) i32 = null,
    stop: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
    shutdown: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
    status: ?AudioBackendStatusFn2 = null,
    output_query: ?@FieldType(base.AudioOutputExtension, "query") = null,
    output_select: ?@FieldType(base.AudioOutputExtension, "select") = null,
    output_active: ?@FieldType(base.AudioOutputExtension, "active") = null,
    idle: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
    write_tracked: ?*const fn (?*anyopaque, [*]const u8, u32, u32, u16, u16, *base.AudioBackendWriteReceipt) callconv(.c) i32 = null,
    playback: ?*const fn (?*anyopaque, *base.AudioBackendPlayback) callconv(.c) i32 = null,
    flow: ?*const fn (?*anyopaque, *const base.AudioBackendFlow) callconv(.c) i32 = null,
};
comptime {
    if (@sizeOf(AudioBackend2) != 136 or @alignOf(AudioBackend2) != 8) @compileError("Canonical technical layout");
    if (@offsetOf(AudioBackend2, "magic") != 0) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "version") != 4) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "size") != 8) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "flags") != 12) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "formats") != 16) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "min_rate") != 20) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "max_rate") != 24) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "preferred_rate") != 28) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "max_channels") != 32) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "reserved") != 34) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "context") != 40) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "write_pcm") != 48) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "stop") != 56) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "shutdown") != 64) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "status") != 72) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "output_query") != 80) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "output_select") != 88) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "output_active") != 96) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "idle") != 104) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "write_tracked") != 112) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "playback") != 120) @compileError("Canonical technical field");
    if (@offsetOf(AudioBackend2, "flow") != 128) @compileError("Canonical technical field");
}
pub const AudioCaptureBackend2 = extern struct {
    magic: u32 = base.audio_capture_backend_magic,
    version: u32 = 1,
    size: u32 = @sizeOf(AudioCaptureBackend2),
    flags: u32 = 0,
    context: ?*anyopaque = null,
    io: ?*const fn (?*anyopaque, *const base.AudioCaptureRequest, *base.AudioCaptureReply, [*]u8, u32) callconv(.c) i32 = null,
    shutdown: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
};
comptime {
    if (@sizeOf(AudioCaptureBackend2) != 40 or @alignOf(AudioCaptureBackend2) != 8) @compileError("Canonical technical layout");
    if (@offsetOf(AudioCaptureBackend2, "magic") != 0) @compileError("Canonical technical field");
    if (@offsetOf(AudioCaptureBackend2, "version") != 4) @compileError("Canonical technical field");
    if (@offsetOf(AudioCaptureBackend2, "size") != 8) @compileError("Canonical technical field");
    if (@offsetOf(AudioCaptureBackend2, "flags") != 12) @compileError("Canonical technical field");
    if (@offsetOf(AudioCaptureBackend2, "context") != 16) @compileError("Canonical technical field");
    if (@offsetOf(AudioCaptureBackend2, "io") != 24) @compileError("Canonical technical field");
    if (@offsetOf(AudioCaptureBackend2, "shutdown") != 32) @compileError("Canonical technical field");
}
