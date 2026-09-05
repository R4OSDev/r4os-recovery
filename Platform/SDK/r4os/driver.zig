const abi = @import("r4os_contract").abi;

pub const r4d_shutdown_entry_offset: u32 = 5;

pub fn entriesAsm(comptime init_target: []const u8, comptime shutdown_target: []const u8) []const u8 {
    return ".section .text.r4d_entries,\"ax\"\n" ++
        ".global r4d_init_entry\n" ++
        "r4d_init_entry:\n" ++
        "    jmp " ++ init_target ++ "\n" ++
        ".global r4d_shutdown_entry\n" ++
        "r4d_shutdown_entry:\n" ++
        "    jmp " ++ shutdown_target ++ "\n";
}

pub const Context = struct {
    api: *const abi.DriverApi,

    pub fn init(api: *const abi.DriverApi) Context {
        return .{ .api = api };
    }

    pub fn apiMagic(self: *const Context) u32 {
        return self.api.magic;
    }

    pub fn apiVersion(self: *const Context) u32 {
        return self.api.version;
    }

    pub fn apiSize(self: *const Context) u32 {
        return self.api.size;
    }

    pub fn apiHeaderValid(self: *const Context) bool {
        return self.api.magic == abi.driver_magic and self.api.size >= 16;
    }

    pub fn supportsDriverApi(self: *const Context, min_version: u32, min_size: u32) bool {
        return self.apiHeaderValid() and self.api.version >= min_version and self.api.size >= min_size;
    }

    pub fn apiCompatible(self: *const Context) bool {
        return self.supportsDriverApi(abi.driver_api_version, @intCast(@sizeOf(abi.DriverApi)));
    }

    pub fn logInfo(self: *const Context, text: [*:0]const u8) void {
        self.api.log_info(text);
    }

    pub fn logWarn(self: *const Context, text: [*:0]const u8) void {
        self.api.log_warn(text);
    }

    pub fn logError(self: *const Context, text: [*:0]const u8) void {
        self.api.log_error(text);
    }

    pub fn portInb(self: *const Context, port: u16) u8 {
        return self.api.port_inb(port);
    }

    pub fn portOutb(self: *const Context, port: u16, value: u8) void {
        self.api.port_outb(port, value);
    }

    pub fn portInw(self: *const Context, port: u16) u16 {
        return self.api.port_inw(port);
    }

    pub fn portOutw(self: *const Context, port: u16, value: u16) void {
        self.api.port_outw(port, value);
    }

    pub fn portInl(self: *const Context, port: u16) u32 {
        return self.api.port_inl(port);
    }

    pub fn portOutl(self: *const Context, port: u16, value: u32) void {
        self.api.port_outl(port, value);
    }

    pub fn getOption(self: *const Context, driver_name: [*:0]const u8, key: [*:0]const u8) [*:0]const u8 {
        return self.api.get_option(driver_name, key);
    }

    pub fn registerSynthEngine(self: *const Context, name: [*:0]const u8, engine: *const anyopaque) i32 {
        return self.api.register_synth_engine(name, engine);
    }

    pub fn registerSynthEngineEx(self: *const Context, name: [*:0]const u8, engine: *const abi.SynthEngine) i32 {
        return self.api.register_synth_engine_v2(name, engine);
    }

    pub fn registerAudioOutputBackend(self: *const Context, name: [*:0]const u8, backend: *const abi.AudioBackend) i32 {
        return self.api.register_audio_output_backend(name, backend);
    }

    pub fn unregisterAudioBackend(self: *const Context, name: [*:0]const u8) i32 {
        return self.api.unregister_audio_backend(name);
    }

    pub fn registerNetBackend(self: *const Context, name: [*:0]const u8, backend: *const abi.NetBackend) i32 {
        return self.api.register_net_backend(name, backend);
    }

    pub fn registerStorageBackend(self: *const Context, name: [*:0]const u8, backend: *const abi.StorageBackend) i32 {
        return self.api.register_storage_backend(name, backend);
    }

    pub fn unregisterStorageBackend(self: *const Context, name: [*:0]const u8) i32 {
        return self.api.unregister_storage_backend(name);
    }

    pub fn storageBackendRecoveryBegin(self: *const Context, name: [*:0]const u8) i32 {
        return self.api.storage_backend_recovery_begin(name);
    }

    pub fn storageBackendRecoveryFinish(self: *const Context, name: [*:0]const u8, ok: bool) i32 {
        return self.api.storage_backend_recovery_finish(name, if (ok) 1 else 0);
    }

    pub fn registerUsbHostController(self: *const Context, name: [*:0]const u8, backend: *const abi.UsbHostController) i32 {
        return self.api.register_usb_host_controller(name, backend);
    }

    pub fn unregisterUsbHostController(self: *const Context, name: [*:0]const u8) i32 {
        return self.api.unregister_usb_host_controller(name);
    }

    pub fn activateUsbHostController(self: *const Context, name: [*:0]const u8, source: u32) i32 {
        return self.api.activate_usb_host_controller(name, source);
    }

    pub fn registerDisplayBlitBackend(self: *const Context, name: [*:0]const u8, backend: *const abi.DisplayBlitBackend) i32 {
        return self.api.register_display_blit_backend(name, backend);
    }

    pub fn unregisterDisplayBlitBackend(self: *const Context, name: [*:0]const u8) i32 {
        return self.api.unregister_display_blit_backend(name);
    }

    pub fn netReceiveFrame(self: *const Context, adapter_index: i32, frame: []const u8) i32 {
        return self.api.net_receive_frame(adapter_index, frame.ptr, @intCast(frame.len));
    }

    /// IRQ-safe work publication. The handler acknowledges the device cause
    /// first, then asks Netcore to poll this adapter in the `net-rx` task.
    pub fn netScheduleRx(self: *const Context, adapter_index: i32) i32 {
        return self.api.net_schedule_rx(adapter_index);
    }

    /// Reads the immutable capability selection produced during backend
    /// registration. Optional rejected bits keep the canonical flat path;
    /// required rejected bits prevent registration.
    pub fn netBackendQuery(self: *const Context, adapter_index: i32, out: *abi.NetBackendNegotiation) i32 {
        return self.api.net_backend_query(adapter_index, out);
    }

    /// Submits a task-side RX packet. The descriptor always carries the
    /// canonical flat bytes; return 1 means those bytes were accepted with
    /// software fallback after optional metadata was stripped.
    pub fn netReceivePacket(self: *const Context, adapter_index: i32, packet: *const abi.NetPacket) i32 {
        return self.api.net_receive_packet(adapter_index, packet);
    }

    pub fn allocDmaRegion(self: *const Context, bytes: u32, alignment: u32, out: *abi.DmaBuffer) i32 {
        return self.api.alloc_dma_region(bytes, alignment, out);
    }

    pub fn allocDmaRegionConstrained(self: *const Context, bytes: u32, alignment: u32, max_phys_addr: u64, out: *abi.DmaBuffer) i32 {
        return self.api.alloc_dma_region_constrained(bytes, alignment, max_phys_addr, out);
    }

    pub fn freeDmaRegion(self: *const Context, buffer: *abi.DmaBuffer) void {
        self.api.free_dma_region(buffer);
    }

    pub fn pinDmaBuffer(self: *const Context, buffer: []u8, out: *abi.DmaPinnedBuffer) i32 {
        if (buffer.len == 0 or buffer.len > abi.dma_mapping_max_bytes) return -2;
        return self.api.dma_pin_buffer(@intFromPtr(buffer.ptr), @intCast(buffer.len), 0, out);
    }

    pub fn pinDmaConstBuffer(self: *const Context, buffer: []const u8, out: *abi.DmaPinnedBuffer) i32 {
        if (buffer.len == 0 or buffer.len > abi.dma_mapping_max_bytes) return -2;
        return self.api.dma_pin_buffer(@intFromPtr(buffer.ptr), @intCast(buffer.len), 0, out);
    }

    pub fn mapDmaPinned(self: *const Context, pin: *const abi.DmaPinnedBuffer, constraints: *const abi.DmaConstraints, direction: u32, out: *abi.DmaMapping) i32 {
        return self.api.dma_map_pinned(pin, constraints, direction, out);
    }

    pub fn syncDmaForDevice(self: *const Context, mapping: *const abi.DmaMapping) i32 {
        return self.api.dma_sync_for_device(mapping);
    }

    pub fn syncDmaForCpu(self: *const Context, mapping: *const abi.DmaMapping) i32 {
        return self.api.dma_sync_for_cpu(mapping);
    }

    pub fn unmapDma(self: *const Context, mapping: *abi.DmaMapping) i32 {
        return self.api.dma_unmap(mapping);
    }

    pub fn unpinDmaBuffer(self: *const Context, pin: *abi.DmaPinnedBuffer) i32 {
        return self.api.dma_unpin_buffer(pin);
    }

    pub fn pciDeviceCount(self: *const Context) u32 {
        return self.api.pci_device_count();
    }

    pub fn pciDeviceAt(self: *const Context, index: u32, out: *abi.PciDeviceInfo) i32 {
        return self.api.pci_device_at(index, out);
    }

    pub fn pciFindByClass(self: *const Context, class_code: u8, subclass: u8, start_index: u32, out: *abi.PciDeviceInfo) i32 {
        return self.api.pci_find_by_class(class_code, subclass, start_index, out);
    }

    pub fn pciReadConfig32(self: *const Context, info: abi.PciDeviceInfo, offset: u16) u32 {
        return self.api.pci_read_config32(info.bus_kind, info.bus, info.device, info.function, offset);
    }

    pub fn pciWriteConfig32(self: *const Context, info: abi.PciDeviceInfo, offset: u16, value: u32) i32 {
        return self.api.pci_write_config32(info.bus_kind, info.bus, info.device, info.function, offset, value);
    }

    pub fn pciReadBar(self: *const Context, info: abi.PciDeviceInfo, index: u8) u32 {
        return self.api.pci_read_bar(info.bus_kind, info.bus, info.device, info.function, index);
    }

    pub fn pciEnableBusMaster(self: *const Context, info: abi.PciDeviceInfo, flags: u32) i32 {
        return self.api.pci_enable_bus_master(info.bus_kind, info.bus, info.device, info.function, flags);
    }

    pub fn pciMapBar(self: *const Context, info: abi.PciDeviceInfo, index: u8, bytes: u32, flags: u32, out: *abi.MmioRegion) i32 {
        return self.api.pci_map_bar(info.bus_kind, info.bus, info.device, info.function, index, bytes, flags, out);
    }

    pub fn irqRegister(self: *const Context, irq: u8, handler: abi.IrqHandler, context: usize, flags: u32) i32 {
        return self.api.irq_register(irq, handler, context, flags);
    }

    pub fn pciEnableMsi(self: *const Context, info: abi.PciDeviceInfo) i32 {
        return self.api.pci_enable_msi(info.bus_kind, info.bus, info.device, info.function);
    }

    pub fn pciDisableMsi(self: *const Context, info: abi.PciDeviceInfo) i32 {
        return self.api.pci_disable_msi(info.bus_kind, info.bus, info.device, info.function);
    }

    pub fn irqUnregister(self: *const Context, irq: u8, handler: abi.IrqHandler, context: usize) i32 {
        return self.api.irq_unregister(irq, handler, context);
    }

    pub fn irqStats(self: *const Context, irq: u8, out: *abi.IrqStats) i32 {
        return self.api.irq_stats(irq, out);
    }

    pub fn workSubmit(self: *const Context, handler: abi.DriverWorkHandler, context: usize, flags: u32, out_handle: *u32) i32 {
        return self.api.driver_work_submit(handler, context, flags, out_handle);
    }

    pub fn workSubmitRequest(self: *const Context, request: *const abi.DriverWorkRequest, out_handle: *u32) i32 {
        return self.api.driver_work_submit_request(request, out_handle);
    }

    pub fn workCancel(self: *const Context, handle: u32) i32 {
        return self.api.driver_work_cancel(handle);
    }

    pub fn completionWait(self: *const Context, handle: u32, timeout_ticks: u64, out_result: *i32) i32 {
        return self.api.driver_completion_wait(handle, timeout_ticks, out_result);
    }

    pub fn completionStatus(self: *const Context, handle: u32, out: *abi.DriverCompletionStatus) i32 {
        return self.api.driver_completion_status(handle, out);
    }

    pub fn completionRelease(self: *const Context, handle: u32) i32 {
        return self.api.driver_completion_release(handle);
    }

    pub fn workSummary(self: *const Context, out: *abi.DriverWorkSummary) i32 {
        return self.api.driver_work_summary(out);
    }

    pub fn tickCount(self: *const Context) u64 {
        return self.api.tick_count();
    }

    pub fn timerFrequency(self: *const Context) u32 {
        return self.api.timer_frequency();
    }

    pub fn waitTicks(self: *const Context, ticks: u64) void {
        self.api.wait_ticks(ticks);
    }

    pub fn protocolDispatch(self: *const Context, role: [*:0]const u8, op: u32, in_buffer: *const abi.ProtocolBuffer, out_buffer: *abi.ProtocolBuffer) i32 {
        const dispatch = self.api.protocol_dispatch orelse return abi.service_api_result_no_endpoint;
        return dispatch(role, op, in_buffer, out_buffer);
    }
};
