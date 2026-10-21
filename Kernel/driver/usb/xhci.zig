const bootlog = @import("../../kernel/bootlog.zig");
const diag_screen = @import("../../kernel/diag_screen.zig");
const k = @import("../../kernel/log.zig");
const paging = @import("../../memory/paging.zig");
const phys = @import("../../memory/phys.zig");
const pcie = @import("../../platform/pci_inventory.zig");
const sched_task = @import("../../sched/task.zig");
const scheduler = @import("../../sched/scheduler.zig");
const sync = @import("../../sched/sync.zig");
const timer = @import("../../kernel/timer.zig");
const irq_router = @import("../../kernel/irq_router.zig");
const usb_core = @import("core.zig");
const usb_host = @import("host_controller.zig");
const event_router = @import("xhci_event_router.zig");
const ring_cycle = @import("xhci_ring_cycle.zig");
const bulk_completion = @import("xhci_bulk_completion.zig");
const endpoint_context = @import("xhci_endpoint_context.zig");
const endpoint_recovery = @import("xhci_endpoint_recovery.zig");
const transfer_pool = @import("xhci_transfer_pool.zig");
const trb_chain = @import("xhci_trb_chain.zig");
const usb_timing = @import("usb_boot_timing.zig");
const usb_wait = @import("usb_boot_wait.zig");
const interrupts = @import("../../arch/x86_64/interrupts.zig");
const heap = @import("../../memory/heap.zig");

const MAP_BYTES: u64 = 0x10000;
const MAX_PORTS: usize = 16;
const MAX_USB_DEVICES: usize = 8;
const MAX_USB_CONFIGS: usize = 1;
const MAX_USB_INTERFACES: usize = 8;
const MAX_USB_ENDPOINTS: usize = 16;
const MAX_STRING_CHARS: usize = 32;
const MAX_SCRATCHPADS: usize = 32;
// Last-resort finite bound if both the IRQ timer and TSC are broken. Normal
// timeouts are owned by usb_wait.Deadline and never by this CPU-speed loop.
const COMMAND_WAIT_GUARD: u32 = 4_000_000_000;
const CONTROLLER_OWNERSHIP_TIMEOUT_TICKS: u64 = 15 * @as(u64, timer.DEFAULT_HZ);
const PORT_SERVICE_IDLE_TICKS: u64 = @max(1, (10 * @as(u64, timer.DEFAULT_HZ)) / 1000);
const EVENT_IRQ_POLL_TICKS: u64 = @max(1, @as(u64, timer.DEFAULT_HZ) / 100);
const TimeoutClock = enum { ticks, hpet, tsc, tsc_fallback, recovery_budget, cpu_guard };

const COMMAND_TRB_COUNT: usize = 256;
const EVENT_TRB_COUNT: usize = 256;

// Runtime selection, mapped rings and event routing share this controller
// owner. A device BOT transaction has a separate class owner and pins its
// exact runtime; a parked wait may hand the controller to HID and restore
// the pinned runtime before accessing its transfer state again.
//
// UnwindGuard is recursive (the protocol layers call nested xHCI helpers),
// generation-safe, usable during single-threaded boot and prevents hard kill
// until the exact outer owner has executed its defer.

const PCI_COMMAND_MEMORY: u16 = 1 << 1;
const PCI_COMMAND_BUS_MASTER: u16 = 1 << 2;

const CAP_CAPLENGTH: u64 = 0x00;
const CAP_HCSPARAMS1: u64 = 0x04;
const CAP_HCSPARAMS2: u64 = 0x08;
const CAP_HCSPARAMS3: u64 = 0x0C;
const CAP_HCCPARAMS1: u64 = 0x10;
const CAP_DBOFF: u64 = 0x14;
const CAP_RTSOFF: u64 = 0x18;
const CAP_HCCPARAMS2: u64 = 0x1C;

const OP_USBCMD: u64 = 0x00;
const OP_USBSTS: u64 = 0x04;
const OP_PAGESIZE: u64 = 0x08;
const OP_DNCTRL: u64 = 0x14;
const OP_CRCR: u64 = 0x18;
const OP_DCBAAP: u64 = 0x30;
const OP_CONFIG: u64 = 0x38;
const OP_PORT_BASE: u64 = 0x400;
const OP_PORT_STRIDE: u64 = 0x10;

const RT_MFINDEX: u64 = 0x00;
const RT_IR0_IMAN: u64 = 0x20;
const RT_IR0_IMOD: u64 = 0x24;
const RT_IR0_ERSTSZ: u64 = 0x28;
const RT_IR0_ERSTBA: u64 = 0x30;
const RT_IR0_ERDP: u64 = 0x38;

const XCAP_ID_LEGACY: u8 = 1;
const USBLEGSUP_BIOS_OWNED: u32 = 1 << 16;
const USBLEGSUP_OS_OWNED: u32 = 1 << 24;

const USBCMD_RUN: u32 = 1 << 0;
const USBCMD_HCRST: u32 = 1 << 1;
const USBCMD_INTE: u32 = 1 << 2;
const USBSTS_HCH: u32 = 1 << 0;
const USBSTS_EINT: u32 = 1 << 3;
const USBSTS_PCD: u32 = 1 << 4;
const USBSTS_CNR: u32 = 1 << 11;
const USBSTS_HCE: u32 = 1 << 12;

const TRB_CYCLE: u32 = 1 << 0;
const TRB_TYPE_SHIFT: u5 = 10;
const TRB_TYPE_LINK: u32 = 6;
const TRB_TYPE_ENABLE_SLOT: u32 = 9;
const TRB_TYPE_DISABLE_SLOT: u32 = 10;
const TRB_TYPE_ADDRESS_DEVICE: u32 = 11;
const TRB_TYPE_CONFIGURE_ENDPOINT: u32 = 12;
const TRB_TYPE_RESET_ENDPOINT: u32 = 14;
const TRB_TYPE_STOP_ENDPOINT: u32 = 15;
const TRB_TYPE_SET_TR_DEQUEUE_POINTER: u32 = 16;
const TRB_TYPE_NORMAL: u32 = 1;
const TRB_TYPE_SETUP_STAGE: u32 = 2;
const TRB_TYPE_DATA_STAGE: u32 = 3;
const TRB_TYPE_STATUS_STAGE: u32 = 4;
const TRB_TYPE_TRANSFER_EVENT: u32 = 32;
const TRB_TYPE_COMMAND_COMPLETION_EVENT: u32 = 33;
const TRB_LINK_TOGGLE_CYCLE: u32 = 1 << 1;
const TRB_CHAIN: u32 = 1 << 4;
const TRB_IOC: u32 = 1 << 5;
const TRB_IDT: u32 = 1 << 6;
const SETUP_TRT_IN_DATA: u32 = 3 << 16;
const DATA_STAGE_DIR_IN: u32 = 1 << 16;
const STATUS_STAGE_DIR_IN: u32 = 1 << 16;
const SETUP_TRT_OUT_DATA: u32 = 2 << 16;

const COMPLETION_SUCCESS: u8 = 1;
const COMPLETION_STALL_ERROR: u8 = 6;
const COMPLETION_SHORT_PACKET: u8 = 13;
const COMPLETION_EVENT_RING_FULL_ERROR: u8 = 21;
const ENDPOINT_RECOVERY_COMMAND_ATTEMPTS: u8 = 6;

const PORTSC_CCS: u32 = 1 << 0;
const PORTSC_PED: u32 = 1 << 1;
const PORTSC_PR: u32 = 1 << 4;
const PORTSC_PLS_MASK: u32 = 0x0F << 5;
const PORTSC_PLS_U0: u32 = 0;
const PORTSC_PP: u32 = 1 << 9;
const PORTSC_PIC_MASK: u32 = 0x3 << 14;
const PORTSC_WPR: u32 = 1 << 31;
const PORTSC_CSC: u32 = 1 << 17;
const PORTSC_CHANGE_MASK: u32 = (1 << 17) | (1 << 18) | (1 << 19) | (1 << 20) | (1 << 21) | (1 << 22) | (1 << 23);
const PORTSC_WRITE_PRESERVE_MASK: u32 = PORTSC_PP | PORTSC_PIC_MASK;

const IMAN_IP: u32 = 1 << 0;
const IMAN_IE: u32 = 1 << 1;
const ERDP_EHB: u64 = 1 << 3;

const CRCR_RCS: u64 = 1 << 0;

const COMMAND_RING_BYTES: usize = @intCast(phys.FRAME_SIZE);
const EVENT_RING_BYTES: usize = @intCast(phys.FRAME_SIZE);
const ERST_BYTES: usize = @intCast(phys.FRAME_SIZE);
const DCBAA_BYTES: usize = @intCast(phys.FRAME_SIZE);
const DEVICE_CONTEXT_BYTES: usize = @intCast(phys.FRAME_SIZE);
const INPUT_CONTEXT_BYTES: usize = @intCast(phys.FRAME_SIZE);
const EP0_RING_BYTES: usize = @intCast(phys.FRAME_SIZE);
const INTERRUPT_RING_BYTES: usize = @intCast(phys.FRAME_SIZE);
const INTERRUPT_BUFFER_BYTES: usize = @intCast(phys.FRAME_SIZE);
const BULK_BUFFER_BYTES: usize = trb_chain.MAX_TRANSFER_BYTES;
const BULK_BUFFER_FRAMES: u16 = @intCast(BULK_BUFFER_BYTES / @as(usize, @intCast(phys.FRAME_SIZE)));
const DESCRIPTOR_BYTES: usize = @intCast(phys.FRAME_SIZE);
const TRANSFER_TRB_COUNT: usize = 256;
const DEVICE_DESCRIPTOR_LEN: u16 = 18;
const CONFIG_DESCRIPTOR_HEADER_LEN: u16 = 9;
const USB_REQ_CLEAR_FEATURE: u8 = 0x01;
const USB_REQ_GET_DESCRIPTOR: u8 = 0x06;
const USB_REQ_SET_CONFIGURATION: u8 = 0x09;
const USB_FEATURE_ENDPOINT_HALT: u16 = 0x0000;
const HID_REQ_SET_IDLE: u8 = 0x0A;
const HID_REQ_SET_PROTOCOL: u8 = 0x0B;
const MSC_REQ_BULK_ONLY_RESET: u8 = 0xFF;
const USB_DESC_DEVICE: u8 = 0x01;
const USB_DESC_CONFIGURATION: u8 = 0x02;
const USB_DESC_STRING: u8 = 0x03;
const USB_DESC_INTERFACE: u8 = 0x04;
const USB_DESC_ENDPOINT: u8 = 0x05;
const USB_DESC_REPORT: u8 = 0x22;
const USB_DESC_HID: u8 = 0x21;
const USB_DESC_SS_ENDPOINT_COMPANION: u8 = 0x30;

const Trb = extern struct {
    parameter: u64,
    status: u32,
    control: u32,
};

const ErstEntry = extern struct {
    base: u64,
    size: u32,
    reserved: u32,
};

pub const PortStatus = struct {
    index: u8 = 0,
    portsc: u32 = 0,
    portpmsc: u32 = 0,
    portli: u32 = 0,
    porthlpmc: u32 = 0,
    change_bits: u32 = 0,
    link_state: u8 = 0,
    connected: bool = false,
    enabled: bool = false,
    powered: bool = false,
    debounce_ok: bool = false,
    reset_attempted: bool = false,
    reset_ok: bool = false,
    reset_reason: []const u8 = "not-started",
};

const PortPreparePhase = enum {
    startup,
    probe,
};

const ProbeRecord = struct {
    active: bool = false,
    port: u8 = 0,
    slot: u8 = 0,
    speed: u8 = 0,
    pls: u8 = 0,
    stage: []const u8 = "none",
    command_cc: u8 = 0,
    transfer_cc: u8 = 0,
    class_code: u8 = 0,
    subclass: u8 = 0,
    protocol: u8 = 0,
    vid: u16 = 0,
    pid: u16 = 0,
};

const DescriptorInterface = struct {
    valid: bool = false,
    number: u8 = 0,
    class_code: u8 = 0,
    subclass: u8 = 0,
    protocol: u8 = 0,
    endpoint_count: u8 = 0,
    first_endpoint_address: u8 = 0,
    first_endpoint_attributes: u8 = 0,
    first_endpoint_max_packet: u16 = 0,
    first_endpoint_interval: u8 = 0,
    interrupt_in_endpoint_address: u8 = 0,
    interrupt_in_endpoint_max_packet: u16 = 0,
    interrupt_in_endpoint_interval: u8 = 0,
    bulk_in_endpoint_address: u8 = 0,
    bulk_in_endpoint_max_packet: u16 = 0,
    bulk_in_endpoint_max_burst: u8 = 0,
    bulk_out_endpoint_address: u8 = 0,
    bulk_out_endpoint_max_packet: u16 = 0,
    bulk_out_endpoint_max_burst: u8 = 0,
    last_endpoint_address: u8 = 0,
    hid_descriptor_len: u8 = 0,
    hid_report_descriptor_len: u16 = 0,
};

const ControlDirection = enum {
    none,
    in,
    out,
};

pub const InterruptPollResult = enum {
    report,
    no_report,
    failed,
};

const ControlRequest = struct {
    request_type: u8 = 0,
    request: u8 = 0,
    value: u16 = 0,
    index_value: u16 = 0,
    length: u16 = 0,
    data_phys: u64 = 0,
    direction: ControlDirection = .none,
};

const DeviceRuntime = struct {
    active: bool = false,
    generation: u64 = 0,
    transaction_active: bool = false,
    transaction_task_id: u32 = 0,
    transaction_task_generation: u64 = 0,
    detach_pending: bool = false,
    slot_id: u8 = 0,
    port: u8 = 0,
    speed: u8 = 0,
    config_value: u8 = 0,
    vendor_id: u16 = 0,
    product_id: u16 = 0,
    device_context_phys: u64 = 0,
    input_context_phys: u64 = 0,
    ep0_ring_phys: u64 = 0,
    interrupt_ring_phys: u64 = 0,
    interrupt_buffer_phys: u64 = 0,
    bulk_in_ring_phys: u64 = 0,
    bulk_out_ring_phys: u64 = 0,
    bulk_buffer_phys: u64 = 0,
    bulk_buffer_frames: u16 = 0,
    descriptor_phys: u64 = 0,
    device_virt: u64 = 0,
    input_virt: u64 = 0,
    ep0_ring_virt: u64 = 0,
    interrupt_ring_virt: u64 = 0,
    interrupt_buffer_virt: u64 = 0,
    bulk_in_ring_virt: u64 = 0,
    bulk_out_ring_virt: u64 = 0,
    bulk_buffer_virt: u64 = 0,
    descriptor_virt: u64 = 0,
    ep0_enqueue: u16 = 0,
    ep0_cycle: u8 = 1,
    control_endpoint_faulted: bool = false,
    interrupt_enqueue: u16 = 0,
    interrupt_cycle: u8 = 1,
    interrupt_endpoint_id: u8 = 0,
    interrupt_endpoint_address: u8 = 0,
    interrupt_endpoint_max_packet: u16 = 0,
    interrupt_endpoint_interval_raw: u8 = 0,
    interrupt_endpoint_interval_context: u8 = 0,
    interrupt_endpoint_configured: bool = false,
    interrupt_endpoint_faulted: bool = false,
    interrupt_pending: bool = false,
    interrupt_pending_trb_phys: u64 = 0,
    interrupt_transfer_handle: u32 = 0,
    interrupt_pending_streak: u64 = 0,
    last_interrupt_ep_state: u8 = 0,
    last_interrupt_request_len: u32 = 0,
    last_interrupt_residue: u32 = 0,
    last_interrupt_actual_len: u32 = 0,
    last_interrupt_completion_code: u8 = 0,
    bulk_endpoints_configured: bool = false,
    bulk_endpoints_faulted: bool = false,
    bulk_in_endpoint_id: u8 = 0,
    bulk_in_endpoint_address: u8 = 0,
    bulk_in_endpoint_max_packet: u16 = 0,
    bulk_in_endpoint_max_burst: u8 = 0,
    bulk_out_endpoint_id: u8 = 0,
    bulk_out_endpoint_address: u8 = 0,
    bulk_out_endpoint_max_packet: u16 = 0,
    bulk_out_endpoint_max_burst: u8 = 0,
    bulk_in_enqueue: u16 = 0,
    bulk_in_cycle: u8 = 1,
    bulk_in_link_update_pending: bool = false,
    bulk_out_enqueue: u16 = 0,
    bulk_out_cycle: u8 = 1,
    bulk_out_link_update_pending: bool = false,
    // Per-device synchronous result state survives controller handoff.
    last_control_request_type: u8 = 0,
    last_control_request: u8 = 0,
    last_control_value: u16 = 0,
    last_control_index: u16 = 0,
    last_control_length: u16 = 0,
    last_control_direction: []const u8 = "none",
    last_control_completion_code: u8 = 0,
    last_control_residue: u32 = 0,
    last_control_ok: bool = false,
    last_bulk_direction: []const u8 = "none",
    last_bulk_result: []const u8 = "none",
    last_bulk_request_len: u32 = 0,
    last_bulk_residue: u32 = 0,
    last_bulk_actual_len: u32 = 0,
    last_bulk_completion_code: u8 = 0,
    last_wait_cancelled: bool = false,
    sync_transfer_incident: diag_screen.IncidentToken = .{},
};

pub const EndpointKind = enum {
    control,
    interrupt_in,
    bulk_in,
    bulk_out,
};

pub const DeviceHandle = struct {
    controller_id: u32 = 0,
    generation: u64 = 0,
    controller: []const u8 = "xhci",
    port: u8 = 0,
    slot_id: u8 = 0,
    speed: u8 = 0,
    config_value: u8 = 0,
    vendor_id: u16 = 0,
    product_id: u16 = 0,
};

pub const EndpointHandle = struct {
    device: DeviceHandle = .{},
    kind: EndpointKind = .control,
    address: u8 = 0,
    endpoint_id: u8 = 0,
    max_packet: u16 = 0,
    max_burst: u8 = 0,
    interval: u8 = 0,
};

pub const DeviceTransaction = struct {
    controller_id: u32,
    runtime_index: usize,
    generation: u64,
};

// The class owner must retain its own UnwindGuard until endDeviceTransaction.
// This pin spans CBW/data/CSW, recovery and retry pauses without retaining the
// shared controller owner. No detached/reused runtime can enter a new BOT.

fn transactionOwnedByCurrent(rt: *const DeviceRuntime) bool {
    if (!rt.transaction_active) return false;
    const task = scheduler.current();
    return rt.transaction_task_id == (if (task) |owner| owner.id else @as(u32, 0)) and
        rt.transaction_task_generation == (if (task) |owner| owner.generation else @as(u64, 0));
}

pub const Status = struct {
    probed: bool = false,
    present: bool = false,
    mapped: bool = false,
    device: pcie.Device = .{},
    command_before: u16 = 0,
    command_after: u16 = 0,
    bar0_raw: u32 = 0,
    bar1_raw: u32 = 0,
    bar_is_io: bool = false,
    bar_is_64: bool = false,
    mmio_phys: u64 = 0,
    mmio_virt: u64 = 0,
    caplength: u8 = 0,
    hciversion: u16 = 0,
    hcsparams1: u32 = 0,
    hcsparams2: u32 = 0,
    hcsparams3: u32 = 0,
    hccparams1: u32 = 0,
    hccparams2: u32 = 0,
    dboff: u32 = 0,
    rtsoff: u32 = 0,
    op_virt: u64 = 0,
    runtime_virt: u64 = 0,
    max_slots: u8 = 0,
    max_interrupters: u16 = 0,
    max_ports: u8 = 0,
    usbcmd: u32 = 0,
    usbsts: u32 = 0,
    pagesize: u32 = 0,
    dnctrl: u32 = 0,
    config: u32 = 0,
    mfindex: u32 = 0,
    iman0: u32 = 0,
    imod0: u32 = 0,
    erstsz0: u32 = 0,
    erstba0: u64 = 0,
    erdp0: u64 = 0,
    crcr: u64 = 0,
    dcbaap: u64 = 0,
    port_count_seen: u8 = 0,
    first_ports: [MAX_PORTS]PortStatus = .{PortStatus{}} ** MAX_PORTS,
    legacy_cap_offset: u32 = 0,
    legacy_usblegsup_before: u32 = 0,
    legacy_usblegsup_after: u32 = 0,
    bios_handoff: []const u8 = "not-started",
    controller_halted_before: bool = false,
    controller_stopped: bool = false,
    controller_reset_ok: bool = false,
    controller_running: bool = false,
    dma_ready: bool = false,
    context_size: u8 = 32,
    dcbaa_phys: u64 = 0,
    command_ring_phys: u64 = 0,
    event_ring_phys: u64 = 0,
    erst_phys: u64 = 0,
    scratchpad_array_phys: u64 = 0,
    scratchpad_count: u8 = 0,
    max_slots_enabled: u8 = 0,
    command_enqueue: u16 = 0,
    command_cycle: u8 = 1,
    event_dequeue: u16 = 0,
    event_cycle: u8 = 1,
    event_raw_cycle: u8 = 0,
    event_raw_type: u8 = 0,
    event_raw_code: u8 = 0,
    event_erdp_commits: u64 = 0,
    event_max_batch: u16 = 0,
    command_ring_wraps: u64 = 0,
    event_ring_wraps: u64 = 0,
    ep0_ring_wraps: u64 = 0,
    interrupt_ring_wraps: u64 = 0,
    bulk_in_ring_wraps: u64 = 0,
    bulk_out_ring_wraps: u64 = 0,
    commands: u64 = 0,
    events: u64 = 0,
    event_tick_deadline_waits: u64 = 0,
    event_hpet_deadline_waits: u64 = 0,
    event_tsc_deadline_waits: u64 = 0,
    event_guard_waits: u64 = 0,
    event_tick_timeouts: u64 = 0,
    event_hpet_timeouts: u64 = 0,
    event_guard_timeouts: u64 = 0,
    event_tsc_timeouts: u64 = 0,
    event_recovery_budget_timeouts: u64 = 0,
    event_cpu_guard_timeouts: u64 = 0,
    host_controller_id: u32 = 0,
    owner_id: u32 = 0,
    host_source: u32 = 0,
    irq_line: u8 = 0xFF,
    irq_pin: u8 = 0,
    irq_registered: bool = false,
    irq_mode: []const u8 = "poll",
    irq_count: u64 = 0,
    irq_handled: u64 = 0,
    irq_wakeups: u64 = 0,
    poll_fallbacks: u64 = 0,
    wait_calls: u64 = 0,
    wait_successes: u64 = 0,
    wait_timeouts: u64 = 0,
    wait_early_calls: u64 = 0,
    wait_runtime_calls: u64 = 0,
    wait_requested_ms: u64 = 0,
    wait_elapsed_ns: u64 = 0,
    wait_max_elapsed_ns: u64 = 0,
    wait_iterations: u64 = 0,
    wait_blocked_ticks: u64 = 0,
    last_wait_reason: []const u8 = "none",
    last_wait_phase: u8 = 0,
    last_wait_requested_ms: u32 = 0,
    last_wait_elapsed_ns: u64 = 0,
    last_wait_iterations: u64 = 0,
    last_wait_blocked_ticks: u64 = 0,
    last_wait_retry: u8 = 0,
    last_wait_success: bool = false,
    stale_events: u64 = 0,
    ring_full: u64 = 0,
    deferred_events_pending: usize = 0,
    deferred_events_queued: u64 = 0,
    deferred_events_delivered: u64 = 0,
    deferred_events_overflows: u64 = 0,
    deferred_events_purged: u64 = 0,
    deferred_events_high_water: usize = 0,
    retained_slots: u8 = 0,
    runtime_switches: u64 = 0,
    port_change_clears: u64 = 0,
    port_change_events: u64 = 0,
    port_change_queued: u64 = 0,
    port_change_coalesced: u64 = 0,
    port_change_invalid: u64 = 0,
    port_change_taken: u64 = 0,
    port_change_retries: u64 = 0,
    port_change_pending_mask: u16 = 0,
    port_change_pending: u8 = 0,
    port_change_high_water: u8 = 0,
    port_service_calls: u64 = 0,
    port_service_failures: u64 = 0,
    port_catalog_changes: u64 = 0,
    port_task_started: bool = false,
    port_task_id: u32 = 0,
    port_task_iterations: u64 = 0,
    port_debounce_failures: u64 = 0,
    port_power_requests: u64 = 0,
    port_u0_waits: u64 = 0,
    port_warm_resets: u64 = 0,
    port_disconnects: u64 = 0,
    reclaimed_slots: u64 = 0,
    disable_slot_commands: u64 = 0,
    disable_slot_failures: u64 = 0,
    enable_slot_attempted: bool = false,
    enable_slot_ok: bool = false,
    address_device_attempted: bool = false,
    address_device_ok: bool = false,
    get_descriptor_attempted: bool = false,
    get_descriptor_ok: bool = false,
    get_config_attempted: bool = false,
    get_config_ok: bool = false,
    get_strings_attempted: bool = false,
    get_strings_ok: bool = false,
    last_command_type: u8 = 0,
    last_completion_code: u8 = 0,
    last_transfer_completion_code: u8 = 0,
    last_event_type: u8 = 0,
    last_event_code: u8 = 0,
    last_event_slot: u8 = 0,
    last_event_endpoint: u8 = 0,
    last_event_parameter: u64 = 0,
    last_event_length: u32 = 0,
    last_stale_event_type: u8 = 0,
    last_stale_event_code: u8 = 0,
    last_stale_event_slot: u8 = 0,
    last_stale_event_endpoint: u8 = 0,
    last_slot_id: u8 = 0,
    addressed_slot_id: u8 = 0,
    addressed_port: u8 = 0,
    addressed_speed: u8 = 0,
    device_context_phys: u64 = 0,
    input_context_phys: u64 = 0,
    ep0_ring_phys: u64 = 0,
    interrupt_ring_phys: u64 = 0,
    interrupt_buffer_phys: u64 = 0,
    bulk_in_ring_phys: u64 = 0,
    bulk_out_ring_phys: u64 = 0,
    bulk_buffer_phys: u64 = 0,
    bulk_buffer_frames: u16 = 0,
    descriptor_phys: u64 = 0,
    ep0_enqueue: u16 = 0,
    ep0_cycle: u8 = 1,
    control_endpoint_faulted: bool = false,
    interrupt_enqueue: u16 = 0,
    interrupt_cycle: u8 = 1,
    interrupt_link_cycle: u8 = 0,
    interrupt_endpoint_id: u8 = 0,
    interrupt_endpoint_address: u8 = 0,
    interrupt_endpoint_max_packet: u16 = 0,
    interrupt_endpoint_interval_raw: u8 = 0,
    interrupt_endpoint_interval_context: u8 = 0,
    interrupt_endpoint_configured: bool = false,
    interrupt_endpoint_faulted: bool = false,
    interrupt_pending: bool = false,
    interrupt_pending_trb_phys: u64 = 0,
    interrupt_transfer_handle: u32 = 0,
    interrupt_pending_index: u16 = 0,
    interrupt_hw_dequeue: u64 = 0,
    bulk_endpoints_configured: bool = false,
    bulk_endpoints_faulted: bool = false,
    bulk_in_endpoint_id: u8 = 0,
    bulk_out_endpoint_id: u8 = 0,
    bulk_in_enqueue: u16 = 0,
    bulk_in_cycle: u8 = 1,
    bulk_in_link_update_pending: bool = false,
    bulk_out_enqueue: u16 = 0,
    bulk_out_cycle: u8 = 1,
    bulk_out_link_update_pending: bool = false,
    set_configuration_attempted: bool = false,
    set_configuration_ok: bool = false,
    hid_set_protocol_attempted: bool = false,
    hid_set_protocol_ok: bool = false,
    hid_set_idle_attempted: bool = false,
    hid_set_idle_ok: bool = false,
    interrupt_polls: u64 = 0,
    interrupt_reports: u64 = 0,
    interrupt_no_report: u64 = 0,
    // 0.56.16: Endpoint-Halt-Recovery (Port der Backup-XHCI.R4D-Phase-4).
    // recoveries: RESET_ENDPOINT+SET_TR_DEQUEUE nach Fehler-Completion oder
    // Halted-Befund; pending_timeouts: Anteil davon aus dem proaktiven
    // Pending-Check; halted_checks: EP-State-Lesungen aus dem Output-
    // Device-Context. Im fehlerfreien QEMU-Lauf bleiben recoveries und
    // pending_timeouts 0 (idle Pending ist bei HID normal, SET_IDLE=0).
    interrupt_recoveries: u64 = 0,
    interrupt_pending_timeouts: u64 = 0,
    interrupt_halted_checks: u64 = 0,
    interrupt_pending_streak: u64 = 0,
    last_interrupt_ep_state: u8 = 0,
    last_interrupt_request_len: u32 = 0,
    last_interrupt_residue: u32 = 0,
    last_interrupt_actual_len: u32 = 0,
    last_interrupt_completion_code: u8 = 0,
    control_transfers: u64 = 0,
    control_failures: u64 = 0,
    control_timeouts: u64 = 0,
    control_stalls: u64 = 0,
    control_short_packets: u64 = 0,
    last_control_request_type: u8 = 0,
    last_control_request: u8 = 0,
    last_control_value: u16 = 0,
    last_control_index: u16 = 0,
    last_control_length: u16 = 0,
    last_control_direction: []const u8 = "none",
    last_control_completion_code: u8 = 0,
    last_control_residue: u32 = 0,
    last_control_ok: bool = false,
    transfer_events: u64 = 0,
    bulk_transfers: u64 = 0,
    bulk_failures: u64 = 0,
    transfer_objects_active: u32 = 0,
    transfer_objects_high_water: u32 = 0,
    transfer_objects_submitted: u64 = 0,
    transfer_objects_completed: u64 = 0,
    transfer_objects_timed_out: u64 = 0,
    transfer_objects_cancelled: u64 = 0,
    transfer_objects_failed: u64 = 0,
    last_bulk_direction: []const u8 = "none",
    last_bulk_result: []const u8 = "none",
    last_bulk_request_len: u32 = 0,
    last_bulk_residue: u32 = 0,
    last_bulk_actual_len: u32 = 0,
    last_bulk_completion_code: u8 = 0,
    ports_probed: u8 = 0,
    non_hid_devices_skipped: u8 = 0,
    probe_record_count: u8 = 0,
    probe_records: [MAX_PORTS]ProbeRecord = .{ProbeRecord{}} ** MAX_PORTS,
    selected_mass_storage: bool = false,
    selected_hid_input: bool = false,
    descriptor_len: u8 = 0,
    descriptor_type: u8 = 0,
    usb_version_bcd: u16 = 0,
    device_class: u8 = 0,
    device_subclass: u8 = 0,
    device_protocol: u8 = 0,
    device_max_packet0: u8 = 0,
    device_vendor_id: u16 = 0,
    device_product_id: u16 = 0,
    device_version_bcd: u16 = 0,
    manufacturer_index: u8 = 0,
    product_index: u8 = 0,
    serial_index: u8 = 0,
    config_total_length: u16 = 0,
    config_value: u8 = 0,
    config_attributes: u8 = 0,
    config_max_power_ma: u16 = 0,
    interface_count: u8 = 0,
    interface_record_count: u8 = 0,
    interface_records: [MAX_USB_INTERFACES]usb_core.Interface = .{usb_core.Interface{}} ** MAX_USB_INTERFACES,
    endpoint_count: u8 = 0,
    descriptor_records: u8 = 0,
    descriptor_unknown: u8 = 0,
    descriptor_malformed: u8 = 0,
    hid_descriptor_count: u8 = 0,
    ss_endpoint_companion_count: u8 = 0,
    selected_interface_reason: []const u8 = "none",
    first_interface_number: u8 = 0,
    first_interface_class: u8 = 0,
    first_interface_subclass: u8 = 0,
    first_interface_protocol: u8 = 0,
    first_endpoint_address: u8 = 0,
    first_endpoint_attributes: u8 = 0,
    first_endpoint_max_packet: u16 = 0,
    first_endpoint_interval: u8 = 0,
    first_hid_descriptor_len: u8 = 0,
    first_hid_report_descriptor_len: u16 = 0,
    bulk_in_endpoint_address: u8 = 0,
    bulk_in_endpoint_max_packet: u16 = 0,
    bulk_in_endpoint_max_burst: u8 = 0,
    bulk_out_endpoint_address: u8 = 0,
    bulk_out_endpoint_max_packet: u16 = 0,
    bulk_out_endpoint_max_burst: u8 = 0,
    string_language_id: u16 = 0,
    manufacturer_len: u8 = 0,
    product_len: u8 = 0,
    serial_len: u8 = 0,
    manufacturer_string: [MAX_STRING_CHARS]u8 = .{0} ** MAX_STRING_CHARS,
    product_string: [MAX_STRING_CHARS]u8 = .{0} ** MAX_STRING_CHARS,
    serial_string: [MAX_STRING_CHARS]u8 = .{0} ** MAX_STRING_CHARS,
    connected_ports: u8 = 0,
    enabled_ports: u8 = 0,
    reset_ports: u8 = 0,
    failures: u64 = 0,
    timeouts: u64 = 0,
    reason: []const u8 = "not initialized",
    last_wait_cancelled: bool = false,
};

// Never reset during controller recovery: a reused slot/port must not revive
// an old storage handle, even when USB vendor/product identifiers match.

pub const TopologyHook = *const fn () callconv(.c) void;

// Only immutable links/PCI identities are read under runtime admission.
// Instances remain resident; their own owner protects hardware and runtime.
var instances: [64]?*Instance = .{null} ** 64;
var instance_count: usize = 0;
pub fn firstInstance() ?*Instance {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    return if (instance_count == 0) null else instances[0];
}
pub fn instanceAt(index: usize) ?*Instance {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    return if (index < instance_count) instances[index] else null;
}
pub fn forId(id: u32) ?*Instance {
    if (id == 0) return null;
    var i: usize = 0;
    while (instanceAt(i)) |instance| : (i += 1) {
        if (instance.id() == id) return instance;
    }
    return null;
}
pub fn forPci(device: pcie.Device) ?*Instance {
    var i: usize = 0;
    while (instanceAt(i)) |instance| : (i += 1) {
        const d = instance.pci_device;
        if (d.bus == device.bus and d.device == device.device and d.function == device.function and
            d.vendor_id == device.vendor_id and d.device_id == device.device_id) return instance;
    }
    return null;
}
fn forTask(task: *sched_task.Task) ?*Instance {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    for (instances[0..instance_count]) |entry| {
        const instance = entry.?;
        if (@atomicLoad(u32, &instance.port_task_id, .acquire) == task.id and instance.port_task_generation == task.generation) return instance;
    }
    return null;
}
fn ensureInstance(device: pcie.Device) ?*Instance {
    if (forPci(device)) |instance| return instance;
    const storage = heap.alloc(@sizeOf(Instance), @alignOf(Instance)) orelse return null;
    const instance: *Instance = @ptrCast(@alignCast(storage.ptr));
    instance.* = .{ .pci_device = device };
    const hex = "0123456789ABCDEF";
    instance.name = .{ 'X', 'H', 'C', 'I', '@', hex[device.bus >> 4], hex[device.bus & 15], ':', hex[device.device >> 4], hex[device.device & 15], '.', hex[device.function] };
    instance.name_len = if (device.vendor_id == 0) 4 else 12;
    instance.canonical_backend.context = instance;
    const flags = interrupts.saveAndDisableRuntime();
    if (forPci(device)) |existing| {
        interrupts.restore(flags);
        _ = heap.free(storage);
        return existing;
    }
    if (instance_count == instances.len) {
        interrupts.restore(flags);
        _ = heap.free(storage);
        return null;
    }
    instances[instance_count] = instance;
    instance_count += 1;
    interrupts.restore(flags);
    return instance;
}
pub fn activate(owner_id: u32, source: u32) i32 {
    var result: i32 = -1;
    var i: usize = 0;
    var found = false;
    while (pcie.deviceAt(i)) |device| : (i += 1) {
        if (device.class_code != 12 or device.subclass != 3 or device.prog_if != 0x30) continue;
        found = true;
        const instance = ensureInstance(device) orelse continue;
        if (!instance.acquireControllerOwnership()) continue;
        const rc = instance.activate(owner_id, source);
        instance.releaseControllerOwnership();
        if (result < 0 and rc >= 0) result = rc;
    }
    if (!found) {
        const instance = ensureInstance(.{}) orelse return -1;
        if (!instance.acquireControllerOwnership()) return -1;
        defer instance.releaseControllerOwnership();
        result = instance.activate(owner_id, source);
    }
    return result;
}
pub fn probe() bool {
    return activate(0, 0) >= 0;
}
pub fn status() Status {
    return if (firstInstance()) |instance| instance.status() else .{};
}
pub fn setTopologyHook(hook: ?TopologyHook) void {
    var i: usize = 0;
    while (instanceAt(i)) |instance| : (i += 1) instance.setTopologyHook(hook);
}
pub fn startPortTask() bool {
    var all = true;
    var i: usize = 0;
    while (instanceAt(i)) |instance| : (i += 1) {
        if (!instance.acquireControllerOwnership()) {
            all = false;
            continue;
        }
        const started = instance.startPortTask();
        instance.releaseControllerOwnership();
        all = started and all;
    }
    return all;
}

// XHCI.R4D is an activation boundary only. The kernel-resident backend owns
// the controller from this call through registry cleanup/unload, so no R4D
// code maps BARs or allocates a second DMA domain.

// The xHCI event ring is shared by commands, transfers and root-port
// changes. A controller-owned task is therefore the single autonomous
// drainer for idle-time port events; class drivers only receive a catalog
// notification after the controller transaction has ended.

fn portTaskMain() callconv(.c) void {
    const instance = forTask(scheduler.current() orelse return) orelse return;
    while (true) {
        if (@atomicLoad(bool, &instance.port_task_stop, .acquire)) {
            instance.restoreControllerOwnership(1);
            if (@atomicLoad(bool, &instance.port_task_stop, .acquire)) {
                @atomicStore(bool, &instance.port_task_started, false, .release);
                @atomicStore(u32, &instance.port_task_id, 0, .release);
                instance.releaseControllerOwnership();
                return;
            }
            instance.releaseControllerOwnership();
        }
        if (@atomicLoad(bool, &instance.irq_registered, .acquire)) {
            if (instance.event_irq.wait(PORT_SERVICE_IDLE_TICKS)) {
                _ = @atomicRmw(u64, &instance.irq_wakeups_async, .Add, 1, .monotonic);
            } else _ = @atomicRmw(u64, &instance.poll_fallbacks_async, .Add, 1, .monotonic);
        } else {
            scheduler.sleepTicksWithReason(PORT_SERVICE_IDLE_TICKS, "xhci-port-idle");
            _ = @atomicRmw(u64, &instance.poll_fallbacks_async, .Add, 1, .monotonic);
        }
        _ = instance.servicePortChanges();
        _ = @atomicRmw(u64, &instance.port_task_iterations, .Add, 1, .monotonic);
    }
}
fn eventIrqHandler(_: u8, raw_context: usize) callconv(.c) u32 {
    const instance: *Instance = @ptrFromInt(raw_context);
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    if (!@atomicLoad(bool, &instance.irq_registered, .acquire)) return 0;
    const op = instance.irq_op;
    const runtime = instance.irq_runtime;
    if (op == 0 or runtime == 0) return 0;
    const status_value = volatileRead32(op + OP_USBSTS);
    const iman = volatileRead32(runtime + RT_IR0_IMAN);
    if ((status_value & (USBSTS_EINT | USBSTS_PCD)) == 0 and (iman & IMAN_IP) == 0) return 0;
    _ = @atomicRmw(u64, &instance.irq_count_async, .Add, 1, .monotonic);
    @as(*volatile u32, @ptrFromInt(runtime + RT_IR0_IMAN)).* = (iman & ~IMAN_IE) | IMAN_IP;
    if ((status_value & (USBSTS_EINT | USBSTS_PCD)) != 0)
        @as(*volatile u32, @ptrFromInt(op + OP_USBSTS)).* = status_value & (USBSTS_EINT | USBSTS_PCD);
    _ = @atomicRmw(u64, &instance.irq_handled_async, .Add, 1, .monotonic);
    instance.event_irq.signal();
    return irq_router.IRQ_RESULT_HANDLED;
}

fn deviceFromUsbHost(handle: *const usb_host.DeviceHandle) DeviceHandle {
    return .{
        .controller_id = handle.controller_id,
        .port = handle.port,
        .slot_id = handle.slot_id,
        .speed = handle.speed,
        .config_value = handle.config_value,
        .vendor_id = handle.vendor_id,
        .product_id = handle.product_id,
    };
}

fn endpointFromUsbHost(handle: *const usb_host.EndpointHandle) ?EndpointHandle {
    return .{
        .device = deviceFromUsbHost(&handle.device),
        .kind = switch (handle.kind) {
            0 => .control,
            1 => .interrupt_in,
            2 => .bulk_in,
            3 => .bulk_out,
            else => return null,
        },
        .address = handle.address,
        .endpoint_id = handle.endpoint_id,
        .max_packet = handle.max_packet,
        .interval = handle.interval,
        .max_burst = handle.max_burst,
    };
}

fn hostPortScan(raw_context: ?*anyopaque) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    return if (instance.servicePortChanges()) 1 else 0;
}

fn hostAddressDevice(raw_context: ?*anyopaque, port: u8, out: *usb_host.DeviceHandle) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    if (!instance.selectDeviceByPort(port)) return -2;
    const handle = DeviceHandle{
        .controller_id = instance.id(),
        .port = instance.current.addressed_port,
        .slot_id = instance.current.addressed_slot_id,
        .speed = instance.current.addressed_speed,
        .config_value = instance.current.config_value,
        .vendor_id = instance.current.device_vendor_id,
        .product_id = instance.current.device_product_id,
    };
    out.* = instance.usbHostDeviceHandle(handle);
    return 0;
}

fn hostConfigureDevice(raw_context: ?*anyopaque, raw: *const usb_host.DeviceHandle, configuration: u8) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    var handle = deviceFromUsbHost(raw);
    if (!instance.selectDeviceHandle(&handle)) return -2;
    if (!instance.selectedDeviceAllowsMutation()) return -2;
    if (configuration != 0) instance.current.config_value = configuration;
    return if (instance.setFirstConfiguration()) 0 else -3;
}

fn hostControlTransfer(raw_context: ?*anyopaque, raw_device: *const usb_host.DeviceHandle, raw_request: *const usb_host.ControlRequest, buffer: [*]u8, len: u32) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    var device = deviceFromUsbHost(raw_device);
    if (!instance.selectDeviceHandle(&device) or instance.first_descriptor_virt == 0) return -2;
    if (!instance.selectedDeviceAllowsMutation()) return -2;
    if (raw_request.length > len or raw_request.length > DESCRIPTOR_BYTES) return -3;
    const direction: ControlDirection = switch (raw_request.direction) {
        0 => .none,
        1 => .in,
        2 => .out,
        else => return -4,
    };
    const scratch: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
    const transfer_len: usize = raw_request.length;
    if (direction == .out and transfer_len != 0) @memcpy(scratch[0..transfer_len], buffer[0..transfer_len]);
    if (direction == .in and transfer_len != 0) @memset(scratch[0..transfer_len], 0);
    const ok = instance.submitControl(.{
        .request_type = raw_request.request_type,
        .request = raw_request.request,
        .value = raw_request.value,
        .index_value = raw_request.index_value,
        .length = raw_request.length,
        .data_phys = if (direction == .none) 0 else instance.current.descriptor_phys,
        .direction = direction,
    });
    if (!ok) return -5;
    const actual = @as(u32, raw_request.length) - instance.current.last_control_residue;
    if (direction == .in and actual != 0) @memcpy(buffer[0..actual], scratch[0..actual]);
    return @intCast(actual);
}

fn hostBulkTransfer(raw_context: ?*anyopaque, raw: *const usb_host.EndpointHandle, buffer: [*]u8, len: u32, direction: u32) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    var endpoint = endpointFromUsbHost(raw) orelse return -2;
    const bytes = buffer[0..len];
    const ok = switch (direction) {
        1 => endpoint.kind == .bulk_in and instance.bulkInForHandle(&endpoint, bytes),
        2 => endpoint.kind == .bulk_out and instance.bulkOutForHandle(&endpoint, bytes),
        else => false,
    };
    if (!ok) return -3;
    return @intCast(instance.current.last_bulk_actual_len);
}

fn hostInterruptTransfer(raw_context: ?*anyopaque, raw: *const usb_host.EndpointHandle, buffer: [*]u8, len: u32, actual: *u32) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    var endpoint = endpointFromUsbHost(raw) orelse return -2;
    const result = instance.pollInterruptInReportStatus(&endpoint, buffer[0..len]);
    actual.* = @intCast(instance.lastInterruptActualLength());
    return switch (result) {
        .report => 1,
        .no_report => 0,
        .failed => -3,
    };
}

fn hostResetPort(raw_context: ?*anyopaque, port: u8) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    return if (instance.resetPort(port)) 0 else -2;
}

fn hostClearHalt(raw_context: ?*anyopaque, raw: *const usb_host.EndpointHandle) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    var endpoint = endpointFromUsbHost(raw) orelse return -2;
    return if (instance.clearEndpointHaltForHandle(&endpoint.device, endpoint.address)) 0 else -3;
}

fn hostResetEndpoint(raw_context: ?*anyopaque, raw: *const usb_host.EndpointHandle) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    var endpoint = endpointFromUsbHost(raw) orelse return -2;
    return if (instance.resetEndpointStateForHandle(&endpoint.device, endpoint.address)) 0 else -3;
}

fn hostPoll(raw_context: ?*anyopaque) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    return if (instance.servicePortChanges()) 1 else 0;
}

fn hostShutdown(raw_context: ?*anyopaque) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    const ok = instance.teardownForReprobe();
    if (ok) {
        @atomicStore(u32, &instance.registration_id, 0, .release);
        instance.current.probed = false;
        instance.current.controller_running = false;
        instance.current.present = false;
        instance.current.reason = "xHCI backend unloaded";
    } else {
        instance.current.reason = "xHCI unload deferred or halt failed; resources retained";
    }
    return if (ok) 0 else -2;
}

fn hostStatus(raw_context: ?*anyopaque, out: *usb_host.Status) callconv(.c) i32 {
    const instance: *Instance = @ptrCast(@alignCast(raw_context orelse return -1));
    if (!instance.acquireControllerOwnership()) return -1;
    defer instance.releaseControllerOwnership();
    const snapshot = instance.status();
    const transfer_snapshot = instance.transfer_objects.snapshot();
    out.* = .{
        .state = if (snapshot.controller_running) 1 else if (snapshot.present) 0 else 2,
        .source = snapshot.host_source,
        .ports = snapshot.port_count_seen,
        .devices = usb_core.countController(instance.id()),
        .transfers = snapshot.control_transfers + snapshot.bulk_transfers + snapshot.interrupt_polls,
        .failures = snapshot.failures,
        .flags = instance.canonical_backend.flags,
        .queue_depth = transfer_pool.MAX_TRANSFERS,
        .max_transfer_bytes = trb_chain.MAX_TRANSFER_BYTES,
        .active_transfers = transfer_snapshot.active,
        .completions = transfer_snapshot.completed,
        .interrupts = snapshot.irq_handled,
        .polls = snapshot.poll_fallbacks,
        .cancellations = transfer_snapshot.cancelled,
    };
    return 0;
}

fn sameDeviceTarget(a: DeviceHandle, b: DeviceHandle) bool {
    if (a.port == 0 or b.port == 0 or a.slot_id == 0 or b.slot_id == 0) return false;
    return a.port == b.port and a.slot_id == b.slot_id and
        (a.generation == 0 or b.generation == 0 or a.generation == b.generation);
}

fn phaseReason(phase: PortPreparePhase, startup_reason: []const u8, probe_reason: []const u8) []const u8 {
    return switch (phase) {
        .startup => startup_reason,
        .probe => probe_reason,
    };
}

const SelectedDeviceKind = enum {
    mass_storage,
    hid_input,
    generic,
};

fn portLinkState(portsc: u32) u32 {
    return (portsc & PORTSC_PLS_MASK) >> 5;
}

fn portLinkStateName(pls: u8) []const u8 {
    return switch (pls) {
        0 => "U0",
        1 => "U1",
        2 => "U2",
        3 => "U3",
        4 => "Disabled",
        5 => "RxDetect",
        6 => "Inactive",
        7 => "Polling",
        8 => "Recovery",
        9 => "HotReset",
        10 => "Compliance",
        11 => "Test",
        15 => "Resume",
        else => "Reserved",
    };
}

fn freeRuntimeFrames(rt: *DeviceRuntime) void {
    freeDmaFrame(&rt.descriptor_phys);
    freeDmaFrames(&rt.bulk_buffer_phys, rt.bulk_buffer_frames);
    rt.bulk_buffer_frames = 0;
    freeDmaFrame(&rt.bulk_out_ring_phys);
    freeDmaFrame(&rt.bulk_in_ring_phys);
    freeDmaFrame(&rt.interrupt_buffer_phys);
    freeDmaFrame(&rt.interrupt_ring_phys);
    freeDmaFrame(&rt.ep0_ring_phys);
    freeDmaFrame(&rt.input_context_phys);
    freeDmaFrame(&rt.device_context_phys);
    rt.* = .{};
}

fn freeDmaFrame(frame: *u64) void {
    if (frame.* == 0) return;
    phys.freeFrame(frame.*);
    frame.* = 0;
}

fn freeDmaFrames(base: *u64, count: u16) void {
    if (base.* == 0) return;
    if (count <= 1) {
        phys.freeFrame(base.*);
    } else {
        phys.freeContiguousFrames(base.*, count);
    }
    base.* = 0;
}

const PortServiceOutcome = struct {
    catalog_changed: bool = false,
    retry: bool = false,
};

fn initRing(ring_virt: u64, ring_phys: u64) void {
    if (ring_virt == 0 or ring_phys == 0) return;
    const ring: [*]Trb = @ptrFromInt(ring_virt);
    var i: usize = 0;
    while (i < TRANSFER_TRB_COUNT) : (i += 1) ring[i] = .{ .parameter = 0, .status = 0, .control = 0 };
    ring[TRANSFER_TRB_COUNT - 1] = .{
        .parameter = ring_phys,
        .status = 0,
        .control = trbType(TRB_TYPE_LINK) | TRB_LINK_TOGGLE_CYCLE | TRB_CYCLE,
    };
}

fn clampU8(value: u8, min_value: u8, max_value: u8) u8 {
    if (value < min_value) return min_value;
    if (value > max_value) return max_value;
    return value;
}

fn floorLog2U16(input: u16) u8 {
    var value = input;
    var result: u8 = 0;
    while (value > 1) : (value >>= 1) {
        result += 1;
    }
    return result;
}

fn encodeInterruptInterval(speed: u8, descriptor_interval: u8) u8 {
    const raw: u8 = if (descriptor_interval == 0) 1 else descriptor_interval;
    return switch (speed) {
        // xHCI table 6-12: LS/FS interrupt bInterval is linear milliseconds.
        // The Endpoint Context stores 125us * 2^Interval, rounded down.
        1, 2 => clampU8(floorLog2U16(@as(u16, raw) * 8), 3, 10),
        // HS/SS interrupt bInterval is already an exponent in 125us units.
        else => clampU8(raw - 1, 0, 15),
    };
}

fn endpointContext(input: [*]u32, ctx_dwords: usize, dci: u8) [*]u32 {
    return input + (ctx_dwords * (@as(usize, dci) + 1));
}

fn endpointDci(endpoint_address: u8) u8 {
    const number: u8 = endpoint_address & 0x0F;
    if (number == 0) return 0;
    return number * 2 + if ((endpoint_address & 0x80) != 0) @as(u8, 1) else @as(u8, 0);
}

const EndpointFaultClass = enum { control, interrupt, bulk };

// Recovery must operate on the already-addressed device which failed. Never
// fall through to the normal selector: that path refreshes/reclaims runtimes
// and may enumerate a replacement on the same physical port.

// BOT reset recovery clears the device-side halt/toggle, but STOP plus
// SET_TR_DEQUEUE_POINTER does not reset the xHC's data-toggle/sequence state.
// Once both bulk endpoints are safely stopped, one Configure Endpoint command
// with Drop+Add for both directions reinitializes that host-side state as one
// indivisible recovery step (xHCI 4.6.6).

/// Transfers ownership of the most recent synchronous-transfer timeout
/// generation to the protocol layer. Once taken, a later xHCI operation must
/// not close that exact incident behind the protocol owner's back.
const BulkSubmission = struct {
    trb_phys: [event_router.MAX_TRANSFER_TRB_POINTERS]u64 = .{0} ** event_router.MAX_TRANSFER_TRB_POINTERS,
    trb_count: u8 = 0,
};

const BulkTrbSubmission = struct {
    trb_phys: u64,
};

fn controlDirectionName(direction: ControlDirection) []const u8 {
    return switch (direction) {
        .none => "none",
        .in => "in",
        .out => "out",
    };
}

// 0.56.16: Endpoint-Halt-Recovery (Port der Backup-XHCI.R4D-Phase-4).
const EP_STATE_HALTED: u8 = 2;
const EP_STATE_ERROR: u8 = 4;
const PENDING_HALT_CHECK_MASK: u64 = 63; // EP-State alle 64 Pending-Polls lesen

// EP-State aus dem OUTPUT-Device-Context lesen. OFFSET-FALLE: der
// Device-Context hat KEINEN Input-Control-Context - Slot liegt bei 0,
// Endpoint-DCI n bei ctx_dwords*n (NICHT n+1 wie im Input-Context,
// vgl. endpointContext()). Ein falscher Offset laese den falschen EP
// und wuerde spurious resetten (Maus sofort tot).

// RESET_ENDPOINT holt den EP aus Halted, SET_TR_DEQUEUE_POINTER setzt den
// Controller-Cursor konsistent auf unsere aktuelle Enqueue-Position (mit
// DCS=aktuellem Cycle-Bit). Danach ist interrupt_pending falsch-frei und
// der naechste Poll setzt einen frischen Transfer auf.

const InterruptSubmission = struct {
    trb_phys: u64,
    enqueue: u16,
    producer_cycle: u8,
    advance: ring_cycle.Advance,
};

fn bumpDescriptorCounter(counter: *u8) void {
    if (counter.* != 0xFF) counter.* += 1;
}

fn isMassStorageCandidate(candidate: *const DescriptorInterface) bool {
    return candidate.valid and
        candidate.class_code == 0x08 and
        candidate.subclass == 0x06 and
        candidate.protocol == 0x50 and
        candidate.bulk_in_endpoint_address != 0 and
        candidate.bulk_out_endpoint_address != 0;
}

fn isBootHidCandidate(candidate: *const DescriptorInterface) bool {
    return candidate.valid and
        candidate.class_code == 0x03 and
        candidate.subclass == 0x01 and
        (candidate.protocol == 0x01 or candidate.protocol == 0x02) and
        candidate.interrupt_in_endpoint_address != 0;
}

fn descriptorCandidateRank(candidate: *const DescriptorInterface) u8 {
    if (isMassStorageCandidate(candidate)) return 4;
    if (isBootHidCandidate(candidate)) return 3;
    if (candidate.valid and candidate.first_endpoint_address != 0) return 2;
    if (candidate.valid) return 1;
    return 0;
}

fn descriptorCandidateReason(candidate: *const DescriptorInterface) []const u8 {
    if (isMassStorageCandidate(candidate)) return "mass-storage-bulk";
    if (isBootHidCandidate(candidate)) {
        if (candidate.protocol == 0x01) return "hid-boot-keyboard";
        if (candidate.protocol == 0x02) return "hid-boot-mouse";
        return "hid-boot";
    }
    if (candidate.valid and candidate.first_endpoint_address != 0) return "first-endpoint-interface";
    if (candidate.valid) return "first-interface";
    return "none";
}

fn selectDescriptorCandidate(candidate: *const DescriptorInterface, selected: *DescriptorInterface) void {
    if (!candidate.valid) return;
    if (descriptorCandidateRank(candidate) > descriptorCandidateRank(selected)) selected.* = candidate.*;
}

const XhciEvent = event_router.Event;

fn runtimeInterruptOwnerMatch(rt: *const DeviceRuntime) ?event_router.Match {
    if (!rt.active or !rt.interrupt_pending or rt.interrupt_pending_trb_phys == 0) return null;
    if (rt.slot_id == 0 or rt.interrupt_endpoint_id == 0) return null;
    return event_router.transferMatch(rt.slot_id, rt.interrupt_endpoint_id, rt.interrupt_pending_trb_phys);
}

// Ein Event-Batch wird bis zum Cycle-Mismatch geleert. Erst danach geben wir
// die konsumierten Slots gemeinsam per ERDP an den xHC zurueck. Das folgt der
// xHCI-Empfehlung fuer Event-Ring-Full-Fortschritt und vermeidet einen MMIO-
// Write pro Event. Das gesuchte Event wird lokal behalten, fremde Events
// werden waehrend desselben Batches weiter sauber geroutet.

fn persistentDiagPuts(text: []const u8) void {
    // boot_status keeps a non-visible output hook installed throughout the
    // runtime, so every log byte is already mirrored into bootlog. Writing
    // bootlog directly here duplicated and fragmented the same timeout line.
    k.puts(text);
}

fn persistentDiagDec(value: u64) void {
    k.putDec(value);
}

fn persistentDiagHex(value: u64, digits: u8) void {
    k.putHex(value, digits);
}

fn toggleCycle(cycle: *u8) void {
    cycle.* = if (cycle.* == 0) 1 else 0;
}

fn updateLinkTrb(ring_virt: u64, count: usize, cycle: u8, continues_td: bool) void {
    if (ring_virt == 0 or count == 0) return;
    const ring: [*]Trb = @ptrFromInt(ring_virt);
    const idx = count - 1;
    // Nutz-TRBs muessen vollstaendig sichtbar sein, bevor das Cycle-Bit den
    // Link an den xHC uebergibt (xHCI Producer-Publish-Reihenfolge).
    dmaFence();
    ring[idx].control = ring_cycle.publishedLinkControl(ring[idx].control, cycle, continues_td);
    dmaFence();
}

fn maxPacketForSpeed(speed: u8) u16 {
    return switch (speed) {
        4 => 512, // SuperSpeed control endpoint 0.
        3 => 64, // High-speed control endpoint 0.
        2 => 8, // Low-speed control endpoint 0.
        1 => 64, // Full-speed devices may legally use up to 64 bytes.
        else => 8,
    };
}

fn readLe16(bytes: [*]const u8, offset: usize) u16 {
    return @as(u16, bytes[offset]) | (@as(u16, bytes[offset + 1]) << 8);
}

fn trbType(value: u32) u32 {
    return value << TRB_TYPE_SHIFT;
}

fn dmaFence() void {
    asm volatile ("mfence");
}

fn allocFrameZero() ?u64 {
    const frame = phys.allocFrame() orelse return null;
    zeroFrame(phys.physToVirt(frame));
    return frame;
}

fn allocContiguousZero(frame_count: u16) ?u64 {
    if (frame_count == 0) return null;
    const base = phys.allocContiguousFrames(frame_count) orelse return null;
    const bytes: [*]u8 = @ptrFromInt(phys.physToVirt(base));
    @memset(bytes[0 .. @as(usize, frame_count) * @as(usize, @intCast(phys.FRAME_SIZE))], 0);
    return base;
}

fn zeroFrame(virt: u64) void {
    const bytes: [*]u8 = @ptrFromInt(virt);
    @memset(bytes[0..@intCast(phys.FRAME_SIZE)], 0);
}

fn mapMmio(base: u64, bytes: u64) bool {
    var mapped: u64 = 0;
    while (mapped < bytes) : (mapped += paging.PAGE_SIZE) {
        const phys_page = (base + mapped) & ~(paging.PAGE_SIZE - 1);
        const virt_page = phys.physToVirt(phys_page);
        if (!paging.isMapped(virt_page)) {
            if (!paging.mapPage(virt_page, phys_page, paging.WRITABLE | paging.CACHE_DISABLE | paging.NO_EXECUTE)) return false;
        }
    }
    return true;
}

fn volatileRead32(address: u64) u32 {
    const ptr: *const volatile u32 = @ptrFromInt(address);
    return ptr.*;
}

fn volatileRead64(address: u64) u64 {
    const ptr: *const volatile u64 = @ptrFromInt(address);
    return ptr.*;
}

// Exact resident native controller; no selected-global context.
pub const Instance = struct {
    pci_device: pcie.Device = .{},
    name: [12]u8 = .{0} ** 12,
    name_len: usize = 0,
    registration_id: u32 = 0,
    port_task_generation: u64 = 0,
    irq_op: u64 = 0,
    irq_runtime: u64 = 0,
    irq_count_async: u64 = 0,
    irq_handled_async: u64 = 0,
    irq_wakeups_async: u64 = 0,
    poll_fallbacks_async: u64 = 0,
    service_failures_async: u64 = 0,
    controller_ownership: sync.UnwindGuard = sync.UnwindGuard.init("xhci-controller"),
    current: Status = .{},
    command_ring_virt: u64 = 0,
    event_ring_virt: u64 = 0,
    erst_virt: u64 = 0,
    dcbaa_virt: u64 = 0,
    scratchpad_array_virt: u64 = 0,
    scratchpad_frames: [MAX_SCRATCHPADS]u64 = .{0} ** MAX_SCRATCHPADS,
    first_device_virt: u64 = 0,
    first_input_virt: u64 = 0,
    first_ep0_ring_virt: u64 = 0,
    first_interrupt_ring_virt: u64 = 0,
    first_interrupt_buffer_virt: u64 = 0,
    first_bulk_in_ring_virt: u64 = 0,
    first_bulk_out_ring_virt: u64 = 0,
    first_bulk_buffer_virt: u64 = 0,
    first_descriptor_virt: u64 = 0,
    runtimes: [MAX_USB_DEVICES]DeviceRuntime = .{DeviceRuntime{}} ** MAX_USB_DEVICES,
    runtime_generation: u64 = 0,
    active_runtime_index: ?usize = null,
    deferred_events: event_router.Mailbox = event_router.Mailbox.init(),
    pending_port_changes: event_router.PortChanges = event_router.PortChanges.init(),
    transfer_objects: transfer_pool.Pool = transfer_pool.Pool.init(),
    last_sync_transfer_incident: diag_screen.IncidentToken = .{},
    active_command: ?event_router.Match = null,
    topology_hook: ?TopologyHook = null,
    port_task_started: bool = false,
    port_task_stop: bool = false,
    port_task_id: u32 = 0,
    port_task_iterations: u64 = 0,
    event_irq: sync.Event = sync.Event.initMode(false, .auto_reset),
    irq_registered: bool = false,
    activated_owner_id: u32 = 0,
    canonical_backend: usb_host.Descriptor = .{
        .flags = usb_host.FLAG_PORT_SCAN |
            usb_host.FLAG_CONTROL |
            usb_host.FLAG_BULK |
            usb_host.FLAG_INTERRUPT |
            usb_host.FLAG_EVENT_IRQ |
            usb_host.FLAG_POLL_FALLBACK |
            usb_host.FLAG_MULTI_TRANSFER |
            usb_host.FLAG_HOTPLUG,
        .port_scan = hostPortScan,
        .address_device = hostAddressDevice,
        .configure_device = hostConfigureDevice,
        .control_transfer = hostControlTransfer,
        .bulk_transfer = hostBulkTransfer,
        .interrupt_transfer = hostInterruptTransfer,
        .reset_port = hostResetPort,
        .clear_halt = hostClearHalt,
        .reset_endpoint = hostResetEndpoint,
        .poll = hostPoll,
        .shutdown = hostShutdown,
        .status = hostStatus,
    },

    pub fn id(instance: *Instance) u32 {
        return @atomicLoad(u32, &instance.registration_id, .acquire);
    }
    pub fn nameSlice(instance: *Instance) []const u8 {
        return instance.name[0..instance.name_len];
    }

    pub fn acquireControllerOwnership(instance: *Instance) bool {
        if (instance.controller_ownership.enter(CONTROLLER_OWNERSHIP_TIMEOUT_TICKS)) return true;
        const incident_token = diag_screen.beginResolvableIncident();
        diag_screen.line("[XHCI] controller ownership timeout");
        _ = diag_screen.resolveIncident(incident_token);
        k.puts("[XHCI] controller ownership timeout\r\n");
        return false;
    }

    pub fn releaseControllerOwnership(instance: *Instance) void {
        if (!instance.controller_ownership.leave()) {
            const incident_token = diag_screen.beginResolvableIncident();
            diag_screen.line("[XHCI] controller ownership release mismatch");
            _ = diag_screen.resolveIncident(incident_token);
            k.puts("[XHCI] controller ownership release mismatch\r\n");
        }
    }

    pub fn beginDeviceTransaction(instance: *Instance, handle: *DeviceHandle) ?DeviceTransaction {
        if (scheduler.current()) |task| {
            const controller_guard: u32 = if (instance.controller_ownership.ownedByCurrent()) 1 else 0;
            if (task.unwind_guard_count <= controller_guard) return null;
        }
        if (!instance.acquireControllerOwnership()) return null;
        defer instance.releaseControllerOwnership();
        if (!instance.selectDeviceHandle(handle) or !instance.deviceHandleCurrent(handle.*)) return null;
        const index = instance.active_runtime_index orelse return null;
        const rt = &instance.runtimes[index];
        if (rt.transaction_active or rt.detach_pending) return null;
        const task = scheduler.current();
        rt.transaction_active = true;
        rt.transaction_task_id = if (task) |owner| owner.id else 0;
        rt.transaction_task_generation = if (task) |owner| owner.generation else 0;
        return .{ .controller_id = instance.id(), .runtime_index = index, .generation = rt.generation };
    }

    pub fn endDeviceTransaction(instance: *Instance, transaction: DeviceTransaction) void {
        if (transaction.controller_id != instance.id()) @panic("xHCI controller epoch changed during transaction");
        instance.restoreControllerOwnership(1);
        defer instance.releaseControllerOwnership();
        const rt = &instance.runtimes[transaction.runtime_index];
        if (!rt.active or rt.generation != transaction.generation or !transactionOwnedByCurrent(rt))
            @panic("xHCI device transaction ownership mismatch");
        rt.transaction_active = false;
        rt.transaction_task_id = 0;
        rt.transaction_task_generation = 0;
        if (rt.detach_pending) instance.pending_port_changes.retry(rt.port);
    }

    fn selectedDeviceAllowsMutation(instance: *Instance) bool {
        const index = instance.active_runtime_index orelse return true;
        const rt = &instance.runtimes[index];
        return !rt.detach_pending and (!rt.transaction_active or transactionOwnedByCurrent(rt));
    }

    fn restoreControllerOwnership(instance: *Instance, depth: u32) void {
        if (!instance.controller_ownership.enter(sync.WAIT_FOREVER))
            @panic("xHCI retained transaction could not restore controller ownership");
        var restored: u32 = 1;
        while (restored < depth) : (restored += 1) {
            if (!instance.controller_ownership.tryEnter()) @panic("xHCI controller nesting mismatch");
        }
    }

    fn idleDeviceWait(instance: *Instance, wait: *usb_wait.Wait) void {
        const index = instance.active_runtime_index orelse {
            wait.idle();
            return;
        };
        if (scheduler.current() == null or !transactionOwnedByCurrent(&instance.runtimes[index])) {
            wait.idle();
            return;
        }
        if (!wait.mayBlockOnIdle()) {
            wait.pollOnce();
            return;
        }
        const generation = instance.runtimes[index].generation;
        const depth = instance.controller_ownership.depth;
        if (depth == 0 or !instance.controller_ownership.ownedByCurrent()) @panic("xHCI wait without controller ownership");
        instance.persistActiveRuntime();
        var released: u32 = 0;
        while (released < depth) : (released += 1) instance.releaseControllerOwnership();
        wait.idle();
        instance.restoreControllerOwnership(depth);
        if (!instance.runtimes[index].active or instance.runtimes[index].generation != generation or !instance.activateRuntime(index))
            @panic("xHCI pinned runtime changed during wait");
    }

    pub fn statusForDevice(instance: *Instance, handle: DeviceHandle) ?Status {
        if (!instance.acquireControllerOwnership()) return null;
        defer instance.releaseControllerOwnership();
        const index = instance.runtimeIndexForIdentity(handle.slot_id, handle.port) orelse return null;
        if (instance.runtimes[index].generation != handle.generation or !instance.activateRuntime(index)) return null;
        return instance.status();
    }

    pub fn takeSyncTransferIncidentForDevice(instance: *Instance, handle: DeviceHandle) diag_screen.IncidentToken {
        if (!instance.acquireControllerOwnership()) return .{};
        defer instance.releaseControllerOwnership();
        const index = instance.runtimeIndexForIdentity(handle.slot_id, handle.port) orelse return .{};
        if (instance.runtimes[index].generation != handle.generation or !instance.activateRuntime(index)) return .{};
        return instance.takeLastSyncTransferIncidentToken();
    }

    pub fn probe(instance: *Instance) bool {
        return instance.probeOwned(0, 0);
    }

    pub fn activate(instance: *Instance, owner_id: u32, source: u32) i32 {
        if (usb_host.findByName(instance.nameSlice()) != null) return -2;
        _ = instance.probeOwned(owner_id, source);
        const index = usb_host.findByName(instance.nameSlice()) orelse return -3;
        return @intCast(index);
    }

    fn probeOwned(instance: *Instance, owner_id: u32, source: u32) bool {
        instance.closeLastSyncTransferIncident();
        if (!instance.teardownForReprobe()) {
            instance.current.failures += 1;
            instance.current.reason = "xHCI reprobe teardown could not halt controller";
            bootlog.puts("[XHCI][WARN] reprobe teardown retained active DMA\r\n");
            return false;
        }
        instance.current = .{ .probed = true };
        if (usb_host.count() == 0) usb_wait.resetMetrics();
        instance.command_ring_virt = 0;
        instance.event_ring_virt = 0;
        instance.erst_virt = 0;
        instance.dcbaa_virt = 0;
        instance.scratchpad_array_virt = 0;
        instance.scratchpad_frames = .{0} ** MAX_SCRATCHPADS;
        instance.first_device_virt = 0;
        instance.first_input_virt = 0;
        instance.first_ep0_ring_virt = 0;
        instance.first_interrupt_ring_virt = 0;
        instance.first_interrupt_buffer_virt = 0;
        instance.first_bulk_in_ring_virt = 0;
        instance.first_bulk_out_ring_virt = 0;
        instance.first_bulk_buffer_virt = 0;
        instance.first_descriptor_virt = 0;
        instance.runtimes = .{DeviceRuntime{}} ** MAX_USB_DEVICES;
        instance.active_runtime_index = null;
        instance.deferred_events.reset();
        instance.pending_port_changes.reset();
        instance.transfer_objects.reset();
        instance.last_sync_transfer_incident = .{};
        instance.active_command = null;
        const event_flags = interrupts.saveAndDisableRuntime();
        instance.event_irq.reset();
        interrupts.restore(event_flags);
        @atomicStore(bool, &instance.irq_registered, false, .release);
        instance.activated_owner_id = owner_id;
        @atomicStore(bool, &instance.port_task_stop, false, .release);
        usb_core.removeController(instance.id());
        instance.canonical_backend.source = source;
        const host_index = if (source == 0)
            usb_host.registerBuiltIn(instance.nameSlice(), &instance.canonical_backend)
        else
            usb_host.register(instance.nameSlice(), &instance.canonical_backend, owner_id);
        const registered_index = host_index orelse {
            instance.current.reason = "xHCI host registry owner already exists";
            return false;
        };
        instance.current.host_controller_id = usb_host.controllerId(registered_index);
        @atomicStore(u32, &instance.registration_id, instance.current.host_controller_id, .release);
        instance.current.owner_id = owner_id;
        instance.current.host_source = source;
        defer _ = usb_host.setState(registered_index, if (instance.current.controller_running) .active else .failed);
        const ps = pcie.status();
        if (ps.xhci_count == 0) {
            instance.current.reason = "no xHCI controller found";
            instance.current.bios_handoff = "not-needed";
            bootlog.puts("[XHCI] not found\r\n");
            return false;
        }

        instance.current.present = true;
        instance.current.device = instance.pci_device;
        const irq_route = pcie.readInterruptRoute(instance.current.device);
        instance.current.irq_line = irq_route.line;
        instance.current.irq_pin = irq_route.pin;
        instance.current.command_before = pcie.readCommand(instance.current.device);
        instance.current.bar0_raw = pcie.readBar(instance.current.device, 0);
        instance.current.bar1_raw = pcie.readBar(instance.current.device, 1);
        instance.current.bar_is_io = (instance.current.bar0_raw & 0x1) != 0;
        instance.current.bar_is_64 = ((instance.current.bar0_raw >> 1) & 0x3) == 0x2;
        if (instance.current.bar_is_io) {
            instance.current.failures += 1;
            instance.current.reason = "BAR0 is I/O space, expected MMIO";
            bootlog.puts("[XHCI][WARN] BAR0 is I/O space\r\n");
            return false;
        }

        instance.current.mmio_phys = pcie.readBar64(instance.current.device, 0) & 0xFFFF_FFFF_FFFF_FFF0;
        if (instance.current.mmio_phys == 0) {
            instance.current.failures += 1;
            instance.current.reason = "BAR0 MMIO base is zero";
            bootlog.puts("[XHCI][WARN] BAR0 MMIO base is zero\r\n");
            return false;
        }
        if (!mapMmio(instance.current.mmio_phys, MAP_BYTES)) {
            instance.current.failures += 1;
            instance.current.reason = "failed to map xHCI MMIO";
            bootlog.puts("[XHCI][WARN] MMIO map failed\r\n");
            return false;
        }

        instance.current.mapped = true;
        instance.current.mmio_virt = phys.physToVirt(instance.current.mmio_phys);
        instance.enablePciMemoryAndBusMaster();
        instance.readCapabilities();
        instance.handleBiosHandoff();
        instance.readOperational();
        instance.readRuntime();
        instance.readPorts();
        _ = instance.initController();
        instance.readOperational();
        instance.readRuntime();
        instance.readPorts();
        instance.current.reason = if (instance.current.get_config_ok)
            "xHCI controller running; first USB configuration parsed"
        else if (instance.current.get_descriptor_ok)
            "xHCI controller running; first USB device descriptor read"
        else if (instance.current.address_device_ok)
            "xHCI controller running; first USB device addressed"
        else if (instance.current.controller_running)
            "xHCI controller running; USB enumeration core active"
        else if (instance.current.dma_ready)
            "xHCI DMA prepared; controller did not reach running state"
        else
            "diagnostic MMIO mapped; xHCI init incomplete";
        instance.logSummary();
        return true;
    }

    pub fn status(instance: *Instance) Status {
        if (!instance.acquireControllerOwnership()) return .{ .reason = "xHCI instance busy" };
        defer instance.releaseControllerOwnership();
        var result = instance.current;
        result.irq_count = @atomicLoad(u64, &instance.irq_count_async, .monotonic);
        result.irq_handled = @atomicLoad(u64, &instance.irq_handled_async, .monotonic);
        result.irq_wakeups = @atomicLoad(u64, &instance.irq_wakeups_async, .monotonic);
        result.poll_fallbacks = @atomicLoad(u64, &instance.poll_fallbacks_async, .monotonic);
        result.port_service_failures +%= @atomicLoad(u64, &instance.service_failures_async, .monotonic);
        const waits = usb_wait.metrics();
        result.wait_calls = waits.calls;
        result.wait_successes = waits.successes;
        result.wait_timeouts = waits.timeouts;
        result.wait_early_calls = waits.early_calls;
        result.wait_runtime_calls = waits.runtime_calls;
        result.wait_requested_ms = waits.requested_ms;
        result.wait_elapsed_ns = waits.elapsed_ns;
        result.wait_max_elapsed_ns = waits.max_elapsed_ns;
        result.wait_iterations = waits.iterations;
        result.wait_blocked_ticks = waits.blocked_ticks;
        result.last_wait_reason = waits.last_reason;
        result.last_wait_phase = @intFromEnum(waits.last_phase);
        result.last_wait_requested_ms = waits.last_requested_ms;
        result.last_wait_elapsed_ns = waits.last_elapsed_ns;
        result.last_wait_iterations = waits.last_iterations;
        result.last_wait_blocked_ticks = waits.last_blocked_ticks;
        result.last_wait_retry = waits.last_retry;
        result.last_wait_success = waits.last_success;
        if (instance.first_interrupt_ring_virt != 0) {
            const ring: [*]const Trb = @ptrFromInt(instance.first_interrupt_ring_virt);
            result.interrupt_link_cycle = @intFromBool((ring[TRANSFER_TRB_COUNT - 1].control & TRB_CYCLE) != 0);
        }
        if (result.interrupt_pending and
            result.interrupt_pending_trb_phys >= result.interrupt_ring_phys)
        {
            const offset = result.interrupt_pending_trb_phys - result.interrupt_ring_phys;
            if ((offset % @sizeOf(Trb)) == 0) {
                const index = offset / @sizeOf(Trb);
                if (index < TRANSFER_TRB_COUNT - 1) result.interrupt_pending_index = @intCast(index);
            }
        }
        if (instance.event_ring_virt != 0 and result.event_dequeue < EVENT_TRB_COUNT) {
            const event_addr = instance.event_ring_virt + @as(u64, result.event_dequeue) * @sizeOf(Trb);
            const control = volatileRead32(event_addr + 12);
            result.event_raw_cycle = @intFromBool((control & TRB_CYCLE) != 0);
            result.event_raw_type = @truncate((control >> TRB_TYPE_SHIFT) & 0x3F);
            result.event_raw_code = @truncate(volatileRead32(event_addr + 8) >> 24);
        }
        result.interrupt_hw_dequeue = instance.readInterruptHardwareDequeue();
        if (result.mapped and result.mmio_virt != 0) {
            result.usbsts = instance.readOp32(OP_USBSTS);
            result.iman0 = instance.readRt32(RT_IR0_IMAN);
            result.erdp0 = instance.readRt64(RT_IR0_ERDP);
        }
        const deferred = instance.deferred_events.snapshot();
        result.deferred_events_pending = deferred.pending;
        result.deferred_events_queued = deferred.queued;
        result.deferred_events_delivered = deferred.delivered;
        result.deferred_events_overflows = deferred.overflows;
        result.deferred_events_purged = deferred.purged;
        result.deferred_events_high_water = deferred.high_water;
        const ports = instance.pending_port_changes.snapshot();
        result.port_change_events = ports.events;
        result.port_change_queued = ports.queued;
        result.port_change_coalesced = ports.coalesced;
        result.port_change_invalid = ports.invalid;
        result.port_change_taken = ports.taken;
        result.port_change_retries = ports.retries;
        result.port_change_pending_mask = ports.pending_mask;
        result.port_change_pending = ports.pending;
        result.port_change_high_water = ports.high_water;
        result.port_task_started = @atomicLoad(bool, &instance.port_task_started, .acquire);
        result.port_task_id = @atomicLoad(u32, &instance.port_task_id, .acquire);
        result.port_task_iterations = @atomicLoad(u64, &instance.port_task_iterations, .acquire);
        const transfers = instance.transfer_objects.snapshot();
        result.transfer_objects_active = transfers.active;
        result.transfer_objects_high_water = transfers.high_water;
        result.transfer_objects_submitted = transfers.submitted;
        result.transfer_objects_completed = transfers.completed;
        result.transfer_objects_timed_out = transfers.timed_out;
        result.transfer_objects_cancelled = transfers.cancelled;
        result.transfer_objects_failed = transfers.failed;
        result.irq_registered = @atomicLoad(bool, &instance.irq_registered, .acquire);
        return result;
    }

    pub fn setTopologyHook(instance: *Instance, hook: ?TopologyHook) void {
        const flags = interrupts.saveAndDisableRuntime();
        defer interrupts.restore(flags);
        instance.topology_hook = hook;
    }

    pub fn startPortTask(instance: *Instance) bool {
        if (@atomicLoad(bool, &instance.port_task_started, .acquire)) return true;
        if (!instance.current.present or !instance.current.controller_running or instance.event_ring_virt == 0) return true;
        _ = instance.startEventIrq();
        const worker = sched_task.createKernelThreadBlockedWithRole("xhci-port", portTaskMain, .short_completion) orelse return false;
        const flags = interrupts.saveAndDisableRuntime();
        instance.port_task_generation = worker.generation;
        @atomicStore(u32, &instance.port_task_id, worker.id, .release);
        @atomicStore(bool, &instance.port_task_started, true, .release);
        interrupts.restore(flags);
        // No global/task-local selected controller. The blocked task is bound
        // by its immutable ID and generation before it can reach its entry.
        if (!scheduler.wakeTask(worker, .signaled)) @panic("unpublished xHCI worker was not blocked");
        return true;
    }

    pub fn servicePortChanges(instance: *Instance) bool {
        if (!instance.acquireControllerOwnership()) {
            _ = @atomicRmw(u64, &instance.service_failures_async, .Add, 1, .monotonic);
            return false;
        }
        const catalog_changed = if (instance.current.present and instance.current.controller_running and instance.event_ring_virt != 0) instance.servicePortChangesLocked() else false;
        instance.releaseControllerOwnership();
        if (catalog_changed) {
            const hook = block: {
                const flags = interrupts.saveAndDisableRuntime();
                defer interrupts.restore(flags);
                break :block instance.topology_hook;
            };
            if (hook) |callback| callback();
        }
        return catalog_changed;
    }

    fn servicePortChangesLocked(instance: *Instance) bool {
        instance.current.port_service_calls +%= 1;
        const events_before = instance.pending_port_changes.snapshot().events;
        instance.drainMaintenanceEventBatch();

        var catalog_changed = false;
        var budget: usize = 0;
        while (budget < MAX_PORTS) : (budget += 1) {
            const port = instance.pending_port_changes.takeNext() orelse break;
            const outcome = instance.servicePendingPortChange(port);
            if (outcome.catalog_changed) catalog_changed = true;
            if (outcome.retry) {
                instance.pending_port_changes.retry(port);
                break;
            }
        }
        if ((instance.readOp32(OP_USBSTS) & USBSTS_PCD) != 0) {
            instance.writeOp32(OP_USBSTS, USBSTS_PCD);
            _ = instance.readOp32(OP_USBSTS);
        }
        if (catalog_changed) instance.current.port_catalog_changes +%= 1;
        if (instance.pending_port_changes.snapshot().events != events_before or catalog_changed) instance.emitPortServiceMarker();
        instance.rearmEventIrq();
        return catalog_changed;
    }

    fn startEventIrq(instance: *Instance) bool {
        const flags = interrupts.saveAndDisableRuntime();
        defer interrupts.restore(flags);
        if (@atomicLoad(bool, &instance.irq_registered, .acquire)) return true;
        if (instance.current.irq_line == 0xff or instance.current.irq_line == 0 or instance.current.irq_line >= irq_router.MAX_IRQS) {
            instance.current.irq_mode = "poll-fallback";
            return false;
        }
        const rc = irq_router.register(instance.current.irq_line, eventIrqHandler, @intFromPtr(instance), irq_router.IRQ_FLAG_SHARED | irq_router.IRQ_FLAG_LEVEL_LOW, instance.activated_owner_id);
        if (rc != 0) {
            instance.current.irq_mode = "poll-fallback";
            return false;
        }
        instance.irq_op = instance.current.op_virt;
        instance.irq_runtime = instance.current.runtime_virt;
        @atomicStore(bool, &instance.irq_registered, true, .release);
        instance.current.irq_registered = true;
        instance.current.irq_mode = "intx-event";
        instance.writeOp32(OP_USBCMD, instance.readOp32(OP_USBCMD) | USBCMD_INTE);
        instance.rearmEventIrq();
        return true;
    }
    fn stopEventIrq(instance: *Instance) void {
        const flags = interrupts.saveAndDisableRuntime();
        defer interrupts.restore(flags);
        if (instance.current.mapped and instance.current.op_virt != 0 and instance.current.runtime_virt != 0) {
            instance.writeRt32(RT_IR0_IMAN, 0);
            instance.writeOp32(OP_USBCMD, instance.readOp32(OP_USBCMD) & ~USBCMD_INTE);
        }
        if (@atomicRmw(bool, &instance.irq_registered, .Xchg, false, .acq_rel))
            _ = irq_router.unregister(instance.current.irq_line, eventIrqHandler, @intFromPtr(instance));
        instance.irq_op = 0;
        instance.irq_runtime = 0;
        instance.current.irq_registered = false;
        instance.current.irq_mode = "poll";
    }

    fn rearmEventIrq(instance: *Instance) void {
        if (!@atomicLoad(bool, &instance.irq_registered, .acquire) or !instance.current.controller_running) return;
        instance.writeRt32(RT_IR0_IMAN, IMAN_IE);
        _ = instance.readRt32(RT_IR0_IMAN);
    }

    fn emitPortServiceMarker(instance: *Instance) void {
        const ports = instance.pending_port_changes.snapshot();
        k.puts("[XHCIPORT] events=");
        k.putDec(ports.events);
        k.puts(" pending=");
        k.putDec(ports.pending);
        k.puts(" queued=");
        k.putDec(ports.queued);
        k.puts(" coalesced=");
        k.putDec(ports.coalesced);
        k.puts(" invalid=");
        k.putDec(ports.invalid);
        k.puts(" taken=");
        k.putDec(ports.taken);
        k.puts(" retries=");
        k.putDec(ports.retries);
        k.puts(" failures=");
        k.putDec(instance.current.port_service_failures);
        k.puts(" catalog_changes=");
        k.putDec(instance.current.port_catalog_changes);
        k.puts("\r\n");
    }

    fn drainMaintenanceEventBatch(instance: *Instance) void {
        var processed: u16 = 0;
        var guard: u32 = 0;
        while (guard < 1024) : (guard += 1) {
            const event = instance.pollEvent() orelse break;
            processed +%= 1;
            instance.routeForeignEvent(event);
        }
        instance.commitEventBatch(processed);
    }

    pub fn usbHostDeviceHandle(instance: *Instance, handle: DeviceHandle) usb_host.DeviceHandle {
        if (handle.controller_id != instance.id()) return .{};
        return .{
            .controller_id = handle.controller_id,
            .port = handle.port,
            .slot_id = handle.slot_id,
            .speed = handle.speed,
            .config_value = handle.config_value,
            .vendor_id = handle.vendor_id,
            .product_id = handle.product_id,
        };
    }

    pub fn usbHostEndpointHandle(instance: *Instance, handle: EndpointHandle) usb_host.EndpointHandle {
        return .{
            .device = instance.usbHostDeviceHandle(handle.device),
            .kind = switch (handle.kind) {
                .control => 0,
                .interrupt_in => 1,
                .bulk_in => 2,
                .bulk_out => 3,
            },
            .address = handle.address,
            .endpoint_id = handle.endpoint_id,
            .max_packet = handle.max_packet,
            .interval = handle.interval,
            .max_burst = handle.max_burst,
        };
    }

    pub fn deviceHandleFromCore(instance: *Instance, dev: *const usb_core.Device) DeviceHandle {
        if (dev.controller_id != instance.id()) return .{};
        return .{
            .controller_id = dev.controller_id,
            .generation = dev.generation,
            .controller = dev.controller,
            .port = dev.port,
            .slot_id = dev.slot_id,
            .speed = dev.speed,
            .config_value = dev.config_value,
            .vendor_id = dev.vendor_id,
            .product_id = dev.product_id,
        };
    }

    pub fn interruptInHandleFromCore(instance: *Instance, dev: *const usb_core.Device) EndpointHandle {
        return .{
            .device = instance.deviceHandleFromCore(dev),
            .kind = .interrupt_in,
            .address = dev.first_endpoint_address,
            .endpoint_id = endpointDci(dev.first_endpoint_address),
            .max_packet = dev.first_endpoint_max_packet,
            .interval = dev.first_endpoint_interval,
        };
    }

    pub fn bulkInHandleFromCore(instance: *Instance, dev: *const usb_core.Device) EndpointHandle {
        return .{
            .device = instance.deviceHandleFromCore(dev),
            .kind = .bulk_in,
            .address = dev.bulk_in_endpoint_address,
            .endpoint_id = endpointDci(dev.bulk_in_endpoint_address),
            .max_packet = dev.bulk_in_endpoint_max_packet,
            .max_burst = dev.bulk_in_endpoint_max_burst,
        };
    }

    pub fn bulkOutHandleFromCore(instance: *Instance, dev: *const usb_core.Device) EndpointHandle {
        return .{
            .device = instance.deviceHandleFromCore(dev),
            .kind = .bulk_out,
            .address = dev.bulk_out_endpoint_address,
            .endpoint_id = endpointDci(dev.bulk_out_endpoint_address),
            .max_packet = dev.bulk_out_endpoint_max_packet,
            .max_burst = dev.bulk_out_endpoint_max_burst,
        };
    }

    pub fn selectDeviceHandle(instance: *Instance, handle: *DeviceHandle) bool {
        if (handle.controller_id != instance.id()) return false;
        if (handle.port == 0) return false;
        if (@atomicLoad(bool, &instance.port_task_started, .acquire)) {
            instance.refreshPortSnapshotByNumber(handle.port);
        } else {
            // Boot-time callers run before the autonomous owner exists and still
            // need the legacy complete refresh. Runtime callers use the targeted
            // port read and leave lifecycle work to the controller-owned task.
            instance.refreshPortsAndReclaim();
        }
        if (!instance.portIsConnected(handle.port)) return false;
        if (handle.slot_id != 0) {
            const i = instance.runtimeIndexForIdentity(handle.slot_id, handle.port) orelse return false;
            if (instance.runtimes[i].detach_pending or
                (handle.generation != 0 and instance.runtimes[i].generation != handle.generation)) return false;
            if (!instance.activateRuntimeByIdentity(handle.slot_id, handle.port)) return false;
            if (instance.current.addressed_slot_id != handle.slot_id or instance.current.addressed_port != handle.port) return false;
            instance.refreshHandleFromCurrent(handle);
            return true;
        }
        if (!instance.selectDeviceByPort(handle.port)) return false;
        instance.refreshHandleFromCurrent(handle);
        return true;
    }

    fn refreshHandleFromCurrent(instance: *Instance, handle: *DeviceHandle) void {
        handle.controller_id = instance.id();
        handle.generation = if (instance.runtimeIndexForIdentity(instance.current.addressed_slot_id, instance.current.addressed_port)) |i| instance.runtimes[i].generation else 0;
        handle.controller = instance.nameSlice();
        handle.slot_id = instance.current.addressed_slot_id;
        handle.port = instance.current.addressed_port;
        handle.speed = instance.current.addressed_speed;
        handle.config_value = instance.current.config_value;
        handle.vendor_id = instance.current.device_vendor_id;
        handle.product_id = instance.current.device_product_id;
    }

    pub fn deviceHandleCurrent(instance: *Instance, handle: DeviceHandle) bool {
        if (handle.controller_id != instance.id()) return false;
        if (handle.generation == 0 or handle.port == 0 or handle.port > instance.current.port_count_seen) return false;
        instance.refreshPortSnapshotByNumber(handle.port);
        const port = instance.current.first_ports[handle.port - 1];
        if (!port.connected or (port.change_bits & PORTSC_CSC) != 0) return false;
        const index = instance.runtimeIndexForIdentity(handle.slot_id, handle.port) orelse return false;
        return instance.runtimes[index].generation == handle.generation and !instance.runtimes[index].detach_pending;
    }

    fn enablePciMemoryAndBusMaster(instance: *Instance) void {
        const wanted = instance.current.command_before | PCI_COMMAND_MEMORY | PCI_COMMAND_BUS_MASTER;
        _ = pcie.writeCommand(instance.current.device, wanted);
        instance.current.command_after = pcie.readCommand(instance.current.device);
    }

    fn readCapabilities(instance: *Instance) void {
        instance.current.caplength = instance.read8(CAP_CAPLENGTH);
        instance.current.hciversion = instance.read16(CAP_CAPLENGTH + 2);
        instance.current.hcsparams1 = instance.read32(CAP_HCSPARAMS1);
        instance.current.hcsparams2 = instance.read32(CAP_HCSPARAMS2);
        instance.current.hcsparams3 = instance.read32(CAP_HCSPARAMS3);
        instance.current.hccparams1 = instance.read32(CAP_HCCPARAMS1);
        instance.current.dboff = instance.read32(CAP_DBOFF);
        instance.current.rtsoff = instance.read32(CAP_RTSOFF);
        instance.current.hccparams2 = instance.read32(CAP_HCCPARAMS2);
        instance.current.max_slots = @truncate(instance.current.hcsparams1 & 0xFF);
        instance.current.max_interrupters = @truncate((instance.current.hcsparams1 >> 8) & 0x7FF);
        instance.current.max_ports = @truncate((instance.current.hcsparams1 >> 24) & 0xFF);
        instance.current.op_virt = instance.current.mmio_virt + instance.current.caplength;
        instance.current.runtime_virt = instance.current.mmio_virt + (instance.current.rtsoff & 0xFFFF_FFE0);
    }

    fn handleBiosHandoff(instance: *Instance) void {
        const xecp_dwords = (instance.current.hccparams1 >> 16) & 0xFFFF;
        if (xecp_dwords == 0) {
            instance.current.bios_handoff = "no-extended-caps";
            return;
        }
        var offset: u32 = xecp_dwords * 4;
        var guard: u32 = 0;
        while (offset >= 0x20 and offset + 4 <= MAP_BYTES and guard < 32) : (guard += 1) {
            const cap = instance.read32(offset);
            const cap_id: u8 = @truncate(cap & 0xFF);
            const next: u8 = @truncate((cap >> 8) & 0xFF);
            if (cap_id == XCAP_ID_LEGACY) {
                instance.current.legacy_cap_offset = offset;
                instance.current.legacy_usblegsup_before = instance.read32(offset);
                if ((instance.current.legacy_usblegsup_before & USBLEGSUP_BIOS_OWNED) == 0) {
                    instance.current.legacy_usblegsup_after = instance.current.legacy_usblegsup_before;
                    instance.current.bios_handoff = "not-needed";
                    return;
                }
                instance.write32(offset, instance.current.legacy_usblegsup_before | USBLEGSUP_OS_OWNED);
                var wait = usb_wait.Wait.begin(
                    usb_timing.XHCI_BIOS_HANDOFF_TIMEOUT_MS,
                    "xhci-bios-handoff",
                    0,
                );
                while ((instance.read32(offset) & USBLEGSUP_BIOS_OWNED) != 0 and !wait.expired()) wait.idle();
                instance.current.legacy_usblegsup_after = instance.read32(offset);
                const released = (instance.current.legacy_usblegsup_after & USBLEGSUP_BIOS_OWNED) == 0;
                _ = wait.finish(released);
                if (released) {
                    instance.current.bios_handoff = "ok";
                } else {
                    instance.current.timeouts += 1;
                    instance.current.bios_handoff = "timeout";
                }
                return;
            }
            if (next == 0) break;
            offset += @as(u32, next) * 4;
        }
        instance.current.bios_handoff = "no-legacy-cap";
    }

    fn initController(instance: *Instance) bool {
        instance.current.controller_halted_before = (instance.readOp32(OP_USBSTS) & USBSTS_HCH) != 0;
        if (!instance.stopController()) return false;
        if (!instance.resetController()) return false;
        instance.readCapabilities();
        if (!instance.allocControllerMemory()) {
            instance.freeControllerMemory();
            return false;
        }
        instance.setupRingsAndContexts();
        if (!instance.runController()) {
            if (instance.stopController()) instance.freeControllerMemory();
            return false;
        }
        instance.readPorts();
        instance.resetConnectedPorts();
        _ = instance.enumerateFirstConnectedDevice();
        return true;
    }

    fn stopController(instance: *Instance) bool {
        var cmd = instance.readOp32(OP_USBCMD);
        cmd &= ~USBCMD_RUN;
        instance.writeOp32(OP_USBCMD, cmd);
        if (!instance.waitOpSet(
            OP_USBSTS,
            USBSTS_HCH,
            usb_timing.XHCI_CONTROLLER_HALT_TIMEOUT_MS,
            "xhci-controller-halt",
        )) {
            instance.current.timeouts += 1;
            instance.current.reason = "timeout waiting for xHCI halt";
            return false;
        }
        instance.current.controller_stopped = true;
        instance.current.controller_running = false;
        return true;
    }

    fn resetController(instance: *Instance) bool {
        instance.writeOp32(OP_USBCMD, instance.readOp32(OP_USBCMD) | USBCMD_HCRST);
        if (!instance.waitOpClear(
            OP_USBCMD,
            USBCMD_HCRST,
            usb_timing.XHCI_CONTROLLER_RESET_TIMEOUT_MS,
            "xhci-controller-reset",
        )) {
            instance.current.timeouts += 1;
            instance.current.reason = "timeout waiting for xHCI reset bit clear";
            return false;
        }
        if (!instance.waitOpClear(
            OP_USBSTS,
            USBSTS_CNR,
            usb_timing.XHCI_CONTROLLER_READY_TIMEOUT_MS,
            "xhci-controller-ready",
        )) {
            instance.current.timeouts += 1;
            instance.current.reason = "timeout waiting for controller not ready";
            return false;
        }
        instance.writeOp32(OP_USBSTS, USBSTS_EINT | USBSTS_PCD | USBSTS_HCE);
        instance.current.controller_reset_ok = true;
        return true;
    }

    fn allocControllerMemory(instance: *Instance) bool {
        instance.current.dcbaa_phys = allocFrameZero() orelse return instance.failAlloc("dcbaa");
        instance.current.command_ring_phys = allocFrameZero() orelse return instance.failAlloc("command ring");
        instance.current.event_ring_phys = allocFrameZero() orelse return instance.failAlloc("event ring");
        instance.current.erst_phys = allocFrameZero() orelse return instance.failAlloc("erst");
        instance.dcbaa_virt = phys.physToVirt(instance.current.dcbaa_phys);
        instance.command_ring_virt = phys.physToVirt(instance.current.command_ring_phys);
        instance.event_ring_virt = phys.physToVirt(instance.current.event_ring_phys);
        instance.erst_virt = phys.physToVirt(instance.current.erst_phys);
        instance.current.context_size = if ((instance.current.hccparams1 & (1 << 2)) != 0) 64 else 32;
        if (!instance.allocScratchpads()) return false;
        instance.current.dma_ready = true;
        return true;
    }

    fn teardownForReprobe(instance: *Instance) bool {
        if (!instance.current.probed) return true;
        for (&instance.runtimes) |*rt| if (rt.transaction_active) return false;
        @atomicStore(bool, &instance.port_task_stop, true, .release);
        instance.stopEventIrq();
        instance.persistActiveRuntime();
        if (instance.current.mapped and instance.current.mmio_virt != 0) {
            if (!instance.stopController()) return false;
        }
        instance.freeAllRuntimes();
        instance.freeControllerMemory();
        if (instance.current.present) {
            _ = pcie.writeCommand(instance.current.device, instance.current.command_before);
            instance.current.command_after = pcie.readCommand(instance.current.device);
        }
        usb_core.removeController(instance.id());
        return true;
    }

    fn freeControllerMemory(instance: *Instance) void {
        if (instance.current.mapped and instance.current.op_virt != 0 and instance.current.runtime_virt != 0) {
            instance.writeRt32(RT_IR0_IMAN, 0);
            instance.writeRt32(RT_IR0_ERSTSZ, 0);
            instance.writeRt64(RT_IR0_ERSTBA, 0);
            instance.writeRt64(RT_IR0_ERDP, 0);
            instance.writeOp32(OP_CONFIG, 0);
            instance.writeOp64(OP_CRCR, 0);
            instance.writeOp64(OP_DCBAAP, 0);
            dmaFence();
        }
        var i: usize = 0;
        while (i < instance.scratchpad_frames.len) : (i += 1) {
            freeDmaFrame(&instance.scratchpad_frames[i]);
        }
        freeDmaFrame(&instance.current.scratchpad_array_phys);
        freeDmaFrame(&instance.current.erst_phys);
        freeDmaFrame(&instance.current.event_ring_phys);
        freeDmaFrame(&instance.current.command_ring_phys);
        freeDmaFrame(&instance.current.dcbaa_phys);
        instance.scratchpad_array_virt = 0;
        instance.scratchpad_frames = .{0} ** MAX_SCRATCHPADS;
        instance.erst_virt = 0;
        instance.event_ring_virt = 0;
        instance.command_ring_virt = 0;
        instance.dcbaa_virt = 0;
        instance.current.scratchpad_count = 0;
        instance.current.dma_ready = false;
    }

    fn failAlloc(instance: *Instance, name: []const u8) bool {
        _ = name;
        instance.current.failures += 1;
        instance.current.reason = "failed to allocate xHCI DMA frame";
        return false;
    }

    fn allocScratchpads(instance: *Instance) bool {
        const count = instance.scratchpadCount();
        instance.current.scratchpad_count = count;
        if (count == 0) return true;
        if (count > MAX_SCRATCHPADS) {
            instance.current.failures += 1;
            instance.current.reason = "too many xHCI scratchpad buffers";
            return false;
        }
        instance.current.scratchpad_array_phys = allocFrameZero() orelse return instance.failAlloc("scratchpad array");
        instance.scratchpad_array_virt = phys.physToVirt(instance.current.scratchpad_array_phys);
        const entries: [*]u64 = @ptrFromInt(instance.scratchpad_array_virt);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            const frame = allocFrameZero() orelse return instance.failAlloc("scratchpad");
            instance.scratchpad_frames[i] = frame;
            entries[i] = frame;
        }
        const dcbaa: [*]u64 = @ptrFromInt(instance.dcbaa_virt);
        dcbaa[0] = instance.current.scratchpad_array_phys;
        return true;
    }

    fn setupRingsAndContexts(instance: *Instance) void {
        instance.initCommandRing();
        instance.initEventRing();
        // Alle Ring-/ERST-Schreibvorgaenge muessen sichtbar sein, bevor ERSTBA
        // die interne Event-Ring-State-Machine des xHC startet.
        dmaFence();
        instance.current.max_slots_enabled = instance.current.max_slots;
        instance.writeOp64(OP_DCBAAP, instance.current.dcbaa_phys);
        instance.writeOp64(OP_CRCR, instance.current.command_ring_phys | CRCR_RCS);
        instance.writeOp32(OP_CONFIG, instance.current.max_slots_enabled);
        instance.writeRt32(RT_IR0_IMOD, 0);
        instance.writeRt32(RT_IR0_ERSTSZ, 1);
        instance.writeRt64(RT_IR0_ERDP, instance.current.event_ring_phys);
        // xHCI 4.9.4: ERSTBA zuletzt; dieser Write setzt die Event-Ring-
        // State-Machine in den Startzustand. IE bleibt waehrend des fruehen
        // Poll-Boots aus und wird erst nach IRQ-Router-/Schedulerstart aktiviert.
        instance.writeRt64(RT_IR0_ERSTBA, instance.current.erst_phys);
        instance.writeRt32(RT_IR0_IMAN, IMAN_IP);
        _ = instance.readRt32(RT_IR0_IMAN);
        instance.current.crcr = instance.readOp64(OP_CRCR);
        instance.current.dcbaap = instance.readOp64(OP_DCBAAP);
        instance.current.config = instance.readOp32(OP_CONFIG);
        instance.current.erstsz0 = instance.readRt32(RT_IR0_ERSTSZ);
        instance.current.erstba0 = instance.readRt64(RT_IR0_ERSTBA);
        instance.current.erdp0 = instance.readRt64(RT_IR0_ERDP);
        instance.current.iman0 = instance.readRt32(RT_IR0_IMAN);
        instance.current.imod0 = instance.readRt32(RT_IR0_IMOD);
    }

    fn initCommandRing(instance: *Instance) void {
        const ring: [*]Trb = @ptrFromInt(instance.command_ring_virt);
        var i: usize = 0;
        while (i < COMMAND_TRB_COUNT) : (i += 1) ring[i] = .{ .parameter = 0, .status = 0, .control = 0 };
        ring[COMMAND_TRB_COUNT - 1] = .{
            .parameter = instance.current.command_ring_phys,
            .status = 0,
            .control = trbType(TRB_TYPE_LINK) | TRB_LINK_TOGGLE_CYCLE,
        };
        instance.current.command_enqueue = 0;
        instance.current.command_cycle = 1;
        instance.current.command_ring_wraps = 0;
    }

    fn initEventRing(instance: *Instance) void {
        instance.deferred_events.reset();
        instance.transfer_objects.reset();
        instance.active_command = null;
        const ring: [*]Trb = @ptrFromInt(instance.event_ring_virt);
        var i: usize = 0;
        while (i < EVENT_TRB_COUNT) : (i += 1) ring[i] = .{ .parameter = 0, .status = 0, .control = 0 };
        const erst: [*]ErstEntry = @ptrFromInt(instance.erst_virt);
        erst[0] = .{ .base = instance.current.event_ring_phys, .size = EVENT_TRB_COUNT, .reserved = 0 };
        instance.current.event_dequeue = 0;
        instance.current.event_cycle = 1;
        instance.current.event_ring_wraps = 0;
        instance.current.event_erdp_commits = 0;
        instance.current.event_max_batch = 0;
    }

    fn runController(instance: *Instance) bool {
        instance.writeOp32(OP_USBSTS, USBSTS_EINT | USBSTS_PCD | USBSTS_HCE);
        instance.writeOp32(OP_USBCMD, instance.readOp32(OP_USBCMD) | USBCMD_RUN);
        if (!instance.waitOpClear(
            OP_USBSTS,
            USBSTS_HCH,
            usb_timing.XHCI_CONTROLLER_RUN_TIMEOUT_MS,
            "xhci-controller-run",
        )) {
            instance.current.timeouts += 1;
            instance.current.reason = "timeout waiting for xHCI run";
            return false;
        }
        instance.current.controller_running = true;
        return true;
    }

    fn resetConnectedPorts(instance: *Instance) void {
        instance.current.connected_ports = 0;
        instance.current.enabled_ports = 0;
        instance.current.reset_ports = 0;
        var i: usize = 0;
        while (i < @as(usize, instance.current.port_count_seen)) : (i += 1) {
            var p = instance.current.first_ports[i];
            _ = instance.preparePortState(i, &p, .startup);
            if (p.connected) instance.current.connected_ports += 1;
            if (p.enabled) instance.current.enabled_ports += 1;
            instance.current.first_ports[i] = p;
        }
    }

    fn refreshPortStatus(instance: *Instance, p: *PortStatus, index_value: usize) void {
        const base = OP_PORT_BASE + (@as(u64, index_value) * OP_PORT_STRIDE);
        p.portsc = instance.readOp32(base);
        p.portpmsc = instance.readOp32(base + 0x04);
        p.portli = instance.readOp32(base + 0x08);
        p.porthlpmc = instance.readOp32(base + 0x0C);
        p.change_bits = p.portsc & PORTSC_CHANGE_MASK;
        p.link_state = @truncate(portLinkState(p.portsc));
        p.connected = (p.portsc & PORTSC_CCS) != 0;
        p.enabled = (p.portsc & PORTSC_PED) != 0;
        p.powered = (p.portsc & PORTSC_PP) != 0;
    }

    fn preparePortState(instance: *Instance, index: usize, p: *PortStatus, phase: PortPreparePhase) bool {
        instance.refreshPortStatus(p, index);
        const was_debounced = p.debounce_ok;
        const initial_changes = instance.clearPortChanges(index);
        if (initial_changes != 0) {
            p.change_bits |= initial_changes;
            instance.refreshPortStatus(p, index);
        }
        if (!p.connected) {
            p.debounce_ok = false;
            p.reset_reason = "no-device";
            return false;
        }
        p.debounce_ok = was_debounced and (initial_changes & PORTSC_CSC) == 0;
        if (!p.debounce_ok and !instance.debounceConnectedPort(index, p)) {
            p.reset_reason = phaseReason(phase, "debounce-timeout", "probe-debounce-timeout");
            instance.current.port_debounce_failures += 1;
            return false;
        }
        if (!instance.ensurePortPower(index, p)) {
            p.reset_reason = phaseReason(phase, "power-timeout", "probe-power-timeout");
            return false;
        }
        // HCRST deliberately does not reset downstream ports. In particular a
        // SuperSpeed port may survive the firmware handoff as Enabled/U0 while
        // its device still owns the firmware-assigned USB address. Every startup
        // enumeration therefore performs one real port reset even in U0.
        const force_enumeration_reset = phase == .startup and !p.reset_attempted;
        if (!p.enabled or force_enumeration_reset) {
            p.reset_attempted = true;
            p.reset_ok = instance.resetPort(@intCast(index));
            p.reset_reason = phaseReason(phase, if (p.reset_ok) "reset-enabled" else "reset-timeout", if (p.reset_ok) "probe-reset-enabled" else "probe-reset-timeout");
            if (p.reset_ok) instance.current.reset_ports += 1;
            instance.refreshPortStatus(p, index);
            if (p.reset_ok and p.connected and p.enabled) {
                _ = usb_wait.millisecondsWithReason(
                    usb_timing.PORT_RESET_RECOVERY_MS,
                    "xhci-port-reset-recovery",
                    0,
                );
                instance.refreshPortStatus(p, index);
            }
        }
        if (p.enabled and portLinkState(p.portsc) != PORTSC_PLS_U0) {
            if (instance.waitPortU0(@intCast(index), p)) {
                p.reset_reason = phaseReason(phase, "waited-u0", "probe-waited-u0");
            } else {
                p.reset_attempted = true;
                p.reset_ok = instance.warmResetPort(@intCast(index));
                instance.current.port_warm_resets += 1;
                p.reset_reason = phaseReason(phase, if (p.reset_ok) "warm-reset-u0" else "warm-reset-timeout", if (p.reset_ok) "probe-warm-reset-u0" else "probe-warm-reset-timeout");
                if (p.reset_ok) instance.current.reset_ports += 1;
                instance.refreshPortStatus(p, index);
                if (p.connected and p.enabled and portLinkState(p.portsc) != PORTSC_PLS_U0 and instance.waitPortU0(@intCast(index), p)) {
                    p.reset_reason = phaseReason(phase, "warm-reset-waited-u0", "probe-warm-waited-u0");
                }
            }
        } else if (p.connected and p.enabled and p.reset_reason.len == 0) {
            p.reset_reason = phaseReason(phase, "already-enabled", "probe-already-enabled");
        } else if (p.connected and p.enabled and !p.reset_attempted) {
            p.reset_reason = phaseReason(phase, "already-enabled", "probe-already-enabled");
        }
        _ = instance.clearPortChanges(index);
        instance.refreshPortStatus(p, index);
        return p.connected and p.enabled and portLinkState(p.portsc) == PORTSC_PLS_U0;
    }

    fn clearPortChanges(instance: *Instance, index: usize) u32 {
        const base = OP_PORT_BASE + (@as(u64, index) * OP_PORT_STRIDE);
        const portsc = instance.readOp32(base);
        const changes = portsc & PORTSC_CHANGE_MASK;
        if (changes != 0) {
            instance.writeOp32(base, (portsc & PORTSC_WRITE_PRESERVE_MASK) | changes);
            instance.current.port_change_clears += 1;
        }
        return changes;
    }

    fn debounceConnectedPort(instance: *Instance, index: usize, p: *PortStatus) bool {
        const base = OP_PORT_BASE + (@as(u64, index) * OP_PORT_STRIDE);
        const observed_mask = PORTSC_CCS | PORTSC_PED | PORTSC_PLS_MASK | PORTSC_PR | PORTSC_WPR;
        var last = instance.readOp32(base);
        var wait = usb_wait.Wait.begin(
            usb_timing.XHCI_PORT_DEBOUNCE_TIMEOUT_MS,
            "xhci-port-debounce",
            0,
        );
        var stable = usb_wait.Deadline.begin(usb_timing.XHCI_PORT_DEBOUNCE_STABLE_MS);
        while (!wait.expired()) {
            const now = instance.readOp32(base);
            if ((now & PORTSC_CCS) == 0) {
                stable.finish();
                _ = wait.finish(false);
                instance.refreshPortStatus(p, index);
                return false;
            }
            if ((now & observed_mask) != (last & observed_mask)) {
                stable.finish();
                stable = usb_wait.Deadline.begin(usb_timing.XHCI_PORT_DEBOUNCE_STABLE_MS);
                last = now;
            } else if (stable.expiredAny()) {
                stable.finish();
                _ = wait.finish(true);
                instance.refreshPortStatus(p, index);
                p.debounce_ok = true;
                return true;
            }
            if (@atomicLoad(bool, &instance.irq_registered, .acquire) and scheduler.current() != null) {
                if (instance.event_irq.wait(EVENT_IRQ_POLL_TICKS)) {
                    instance.current.irq_wakeups +%= 1;
                } else {
                    instance.current.poll_fallbacks +%= 1;
                }
            } else {
                instance.current.poll_fallbacks +%= 1;
                wait.idle();
            }
        }
        stable.finish();
        _ = wait.finish(false);
        instance.refreshPortStatus(p, index);
        p.debounce_ok = false;
        return false;
    }

    fn ensurePortPower(instance: *Instance, index: usize, p: *PortStatus) bool {
        if (p.powered) return true;
        const base = OP_PORT_BASE + (@as(u64, index) * OP_PORT_STRIDE);
        instance.current.port_power_requests += 1;
        const before = instance.readOp32(base);
        instance.writeOp32(base, (before & PORTSC_WRITE_PRESERVE_MASK) | PORTSC_PP | (before & PORTSC_CHANGE_MASK));
        var wait = usb_wait.Wait.begin(
            usb_timing.XHCI_PORT_POWER_TIMEOUT_MS,
            "xhci-port-power",
            0,
        );
        while (!wait.expired()) {
            instance.refreshPortStatus(p, index);
            if (!p.connected) {
                _ = wait.finish(false);
                return false;
            }
            if (p.powered) {
                _ = wait.finish(true);
                return true;
            }
            wait.idle();
        }
        _ = wait.finish(false);
        instance.current.timeouts += 1;
        return false;
    }

    fn resetPort(instance: *Instance, index_value: u8) bool {
        if (instance.runtimeIndexForPort(index_value +| 1)) |index| {
            if (instance.runtimes[index].transaction_active) return false;
        }
        const base = OP_PORT_BASE + (@as(u64, index_value) * OP_PORT_STRIDE);
        const before = instance.readOp32(base);
        _ = instance.clearPortChanges(@intCast(index_value));
        const value = (before & PORTSC_WRITE_PRESERVE_MASK) | PORTSC_PR;
        instance.writeOp32(base, value);
        var wait = usb_wait.Wait.begin(
            usb_timing.XHCI_PORT_RESET_TIMEOUT_MS,
            "xhci-port-reset",
            0,
        );
        while (!wait.expired()) {
            const portsc = instance.readOp32(base);
            if ((portsc & PORTSC_PR) == 0 and ((portsc & PORTSC_PED) != 0 or (portsc & PORTSC_CCS) == 0)) {
                _ = instance.clearPortChanges(@intCast(index_value));
                _ = wait.finish(true);
                return true;
            }
            wait.idle();
        }
        _ = wait.finish(false);
        instance.current.timeouts += 1;
        return false;
    }

    fn warmResetPort(instance: *Instance, index_value: u8) bool {
        if (instance.runtimeIndexForPort(index_value +| 1)) |index| {
            if (instance.runtimes[index].transaction_active) return false;
        }
        const base = OP_PORT_BASE + (@as(u64, index_value) * OP_PORT_STRIDE);
        const before = instance.readOp32(base);
        _ = instance.clearPortChanges(@intCast(index_value));
        instance.writeOp32(base, (before & PORTSC_WRITE_PRESERVE_MASK) | PORTSC_WPR);
        var wait = usb_wait.Wait.begin(
            usb_timing.XHCI_PORT_WARM_RESET_TIMEOUT_MS,
            "xhci-port-warm-reset",
            0,
        );
        while (!wait.expired()) {
            const portsc = instance.readOp32(base);
            if ((portsc & PORTSC_WPR) == 0) {
                _ = instance.clearPortChanges(@intCast(index_value));
                const ready = (portsc & PORTSC_CCS) == 0 or
                    ((portsc & PORTSC_PED) != 0 and portLinkState(portsc) == PORTSC_PLS_U0);
                _ = wait.finish(ready);
                return ready;
            }
            wait.idle();
        }
        _ = wait.finish(false);
        instance.current.timeouts += 1;
        return false;
    }

    fn waitPortU0(instance: *Instance, index_value: u8, p: *PortStatus) bool {
        const index_usize: usize = @intCast(index_value);
        instance.current.port_u0_waits += 1;
        var wait = usb_wait.Wait.begin(
            usb_timing.XHCI_PORT_U0_TIMEOUT_MS,
            "xhci-port-u0",
            0,
        );
        while (!wait.expired()) {
            instance.refreshPortStatus(p, index_usize);
            if ((p.portsc & PORTSC_CCS) == 0) {
                _ = wait.finish(false);
                return false;
            }
            if ((p.portsc & PORTSC_PED) != 0 and portLinkState(p.portsc) == PORTSC_PLS_U0) {
                _ = wait.finish(true);
                return true;
            }
            wait.idle();
        }
        _ = wait.finish(false);
        return false;
    }

    fn enableSlotSmoke(instance: *Instance) bool {
        instance.current.enable_slot_attempted = true;
        const completion = instance.submitCommand(0, 0, trbType(TRB_TYPE_ENABLE_SLOT)) orelse return false;
        instance.current.enable_slot_ok = completion.code == COMPLETION_SUCCESS;
        instance.current.last_completion_code = completion.code;
        instance.current.last_slot_id = completion.slot_id;
        if (!instance.current.enable_slot_ok) instance.current.failures += 1;
        return instance.current.enable_slot_ok;
    }

    fn enumerateFirstConnectedDevice(instance: *Instance) bool {
        instance.refreshPortsAndReclaim();
        var mass_storage_port: ?usize = null;
        var hid_port: ?usize = null;
        var fallback_port: ?usize = null;
        var found_configured_device = false;
        var i: usize = 0;
        while (i < @as(usize, instance.current.port_count_seen)) : (i += 1) {
            if (!instance.preparePortForProbe(i)) continue;
            if (!instance.probePortDevice(i)) {
                instance.disableCurrentSlotForScan();
                continue;
            }
            if (instance.current.get_config_ok) {
                found_configured_device = true;
                instance.publishCurrentCoreDevice();
                if (instance.isMassStorageBulk()) {
                    if (mass_storage_port == null) mass_storage_port = i;
                } else if (instance.isBootHidInput()) {
                    if (hid_port == null) hid_port = i;
                } else {
                    if (fallback_port == null) fallback_port = i;
                    instance.current.non_hid_devices_skipped += 1;
                }
                instance.persistActiveRuntime();
                continue;
            }
            instance.disableCurrentSlotForScan();
        }

        if (mass_storage_port) |port_index| {
            return instance.selectPortDevice(port_index, .mass_storage);
        }
        if (hid_port) |port_index| {
            return instance.selectPortDevice(port_index, .hid_input);
        }
        if (fallback_port) |port_index| {
            return instance.selectPortDevice(port_index, .generic);
        }
        return found_configured_device;
    }

    pub fn selectDeviceByPort(instance: *Instance, port: u8) bool {
        if (port == 0) return false;
        if (instance.activateRuntimeByPort(port)) return true;
        if (instance.current.addressed_slot_id != 0 and instance.current.addressed_port == port and instance.current.get_config_ok) return true;
        var i: usize = 0;
        while (i < @as(usize, instance.current.port_count_seen)) : (i += 1) {
            if (instance.current.first_ports[i].index != port) continue;
            instance.disableCurrentSlotForScan();
            return instance.selectPortDevice(i, .generic);
        }
        return false;
    }

    fn selectPortDevice(instance: *Instance, port_index: usize, kind: SelectedDeviceKind) bool {
        if (instance.activateRuntimeByPort(instance.current.first_ports[port_index].index)) {
            switch (kind) {
                .mass_storage => instance.current.selected_mass_storage = true,
                .hid_input => instance.current.selected_hid_input = true,
                .generic => {},
            }
            return true;
        }
        if (!instance.probePortDevice(port_index)) {
            instance.disableCurrentSlotForScan();
            return false;
        }
        if (!instance.current.get_config_ok) {
            instance.disableCurrentSlotForScan();
            return false;
        }
        switch (kind) {
            .mass_storage => instance.current.selected_mass_storage = true,
            .hid_input => instance.current.selected_hid_input = true,
            .generic => {},
        }
        instance.publishCurrentCoreDevice();
        return true;
    }

    fn firstEnabledPort(instance: *Instance) ?usize {
        var i: usize = 0;
        while (i < @as(usize, instance.current.port_count_seen)) : (i += 1) {
            if (instance.portEnabled(i)) return i;
        }
        return null;
    }

    fn portEnabled(instance: *Instance, index: usize) bool {
        if (index >= @as(usize, instance.current.port_count_seen)) return false;
        const p = instance.current.first_ports[index];
        return (p.portsc & PORTSC_CCS) != 0 and (p.portsc & PORTSC_PED) != 0 and portLinkState(p.portsc) == PORTSC_PLS_U0;
    }

    fn preparePortForProbe(instance: *Instance, index: usize) bool {
        if (index >= @as(usize, instance.current.port_count_seen)) return false;
        var p = instance.current.first_ports[index];
        const ready = instance.preparePortState(index, &p, .probe);
        instance.current.first_ports[index] = p;
        return ready;
    }

    fn probePortDevice(instance: *Instance, port_index: usize) bool {
        instance.persistActiveRuntime();
        instance.active_runtime_index = null;
        instance.resetFirstEnumerationFields();
        instance.current.ports_probed += 1;
        const record_index = instance.beginProbeRecord(port_index);
        if (!instance.enableSlotSmoke()) {
            instance.updateProbeRecord(record_index, "enable-slot-failed");
            return false;
        }
        instance.current.addressed_slot_id = instance.current.last_slot_id;
        instance.current.addressed_port = instance.current.first_ports[port_index].index;
        instance.current.addressed_speed = @truncate((instance.current.first_ports[port_index].portsc >> 10) & 0x0F);
        instance.updateProbeRecord(record_index, "slot-enabled");
        if (!instance.allocFirstDeviceRuntime()) {
            instance.updateProbeRecord(record_index, "alloc-failed");
            return false;
        }
        instance.setupFirstInputContext(port_index);
        if (!instance.addressFirstDevice()) {
            instance.updateProbeRecord(record_index, "address-failed");
            return false;
        }
        instance.updateProbeRecord(record_index, "addressed");
        if (!instance.getFirstDeviceDescriptor()) {
            instance.updateProbeRecord(record_index, "device-desc-failed");
            return false;
        }
        instance.updateProbeRecord(record_index, "device-desc");
        if (!instance.getFirstConfigDescriptor()) {
            instance.updateProbeRecord(record_index, "config-desc-failed");
            return false;
        }
        _ = instance.getFirstStringDescriptors();
        instance.updateProbeRecord(record_index, "configured");
        return instance.current.get_config_ok;
    }

    fn beginProbeRecord(instance: *Instance, port_index: usize) usize {
        const idx = @as(usize, instance.current.probe_record_count);
        if (idx >= MAX_PORTS) return MAX_PORTS - 1;
        const p = instance.current.first_ports[port_index];
        instance.current.probe_records[idx] = .{
            .active = true,
            .port = p.index,
            .speed = @truncate((p.portsc >> 10) & 0x0F),
            .pls = @truncate(portLinkState(p.portsc)),
            .stage = "start",
        };
        instance.current.probe_record_count += 1;
        return idx;
    }

    fn updateProbeRecord(instance: *Instance, index_value: usize, stage: []const u8) void {
        if (index_value >= MAX_PORTS) return;
        var r = &instance.current.probe_records[index_value];
        if (!r.active) return;
        r.stage = stage;
        r.slot = instance.current.addressed_slot_id;
        r.command_cc = instance.current.last_completion_code;
        r.transfer_cc = instance.current.last_transfer_completion_code;
        r.class_code = instance.current.first_interface_class;
        r.subclass = instance.current.first_interface_subclass;
        r.protocol = instance.current.first_interface_protocol;
        r.vid = instance.current.device_vendor_id;
        r.pid = instance.current.device_product_id;
    }

    fn resetFirstEnumerationFields(instance: *Instance) void {
        instance.current.address_device_attempted = false;
        instance.current.address_device_ok = false;
        instance.current.get_descriptor_attempted = false;
        instance.current.get_descriptor_ok = false;
        instance.current.get_config_attempted = false;
        instance.current.get_config_ok = false;
        instance.current.get_strings_attempted = false;
        instance.current.get_strings_ok = false;
        instance.current.set_configuration_attempted = false;
        instance.current.set_configuration_ok = false;
        instance.current.hid_set_protocol_attempted = false;
        instance.current.hid_set_protocol_ok = false;
        instance.current.hid_set_idle_attempted = false;
        instance.current.hid_set_idle_ok = false;
        instance.current.interrupt_endpoint_configured = false;
        instance.current.interrupt_endpoint_faulted = false;
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_transfer_handle = 0;
        instance.current.interrupt_pending_streak = 0;
        instance.current.last_interrupt_ep_state = 0;
        instance.current.interrupt_endpoint_id = 0;
        instance.current.interrupt_endpoint_address = 0;
        instance.current.interrupt_endpoint_max_packet = 0;
        instance.current.interrupt_endpoint_interval_raw = 0;
        instance.current.interrupt_endpoint_interval_context = 0;
        instance.current.interrupt_enqueue = 0;
        instance.current.interrupt_cycle = 1;
        instance.current.last_interrupt_request_len = 0;
        instance.current.last_interrupt_residue = 0;
        instance.current.last_interrupt_actual_len = 0;
        instance.current.last_interrupt_completion_code = 0;
        instance.current.bulk_endpoints_configured = false;
        instance.current.bulk_endpoints_faulted = false;
        instance.current.bulk_in_endpoint_id = 0;
        instance.current.bulk_out_endpoint_id = 0;
        instance.current.bulk_in_enqueue = 0;
        instance.current.bulk_in_cycle = 1;
        instance.current.bulk_in_link_update_pending = false;
        instance.current.bulk_out_enqueue = 0;
        instance.current.bulk_out_cycle = 1;
        instance.current.bulk_out_link_update_pending = false;
        instance.current.selected_mass_storage = false;
        instance.current.selected_hid_input = false;
        instance.current.last_control_request_type = 0;
        instance.current.last_control_request = 0;
        instance.current.last_control_value = 0;
        instance.current.last_control_index = 0;
        instance.current.last_control_length = 0;
        instance.current.last_control_direction = "none";
        instance.current.last_control_completion_code = 0;
        instance.current.last_control_residue = 0;
        instance.current.last_control_ok = false;
        instance.current.control_endpoint_faulted = false;
        instance.current.descriptor_len = 0;
        instance.current.descriptor_type = 0;
        instance.current.usb_version_bcd = 0;
        instance.current.device_class = 0;
        instance.current.device_subclass = 0;
        instance.current.device_protocol = 0;
        instance.current.device_max_packet0 = 0;
        instance.current.device_vendor_id = 0;
        instance.current.device_product_id = 0;
        instance.current.device_version_bcd = 0;
        instance.current.manufacturer_index = 0;
        instance.current.product_index = 0;
        instance.current.serial_index = 0;
        instance.current.config_total_length = 0;
        instance.current.config_value = 0;
        instance.current.config_attributes = 0;
        instance.current.config_max_power_ma = 0;
        instance.current.interface_count = 0;
        instance.current.interface_record_count = 0;
        instance.current.interface_records = .{usb_core.Interface{}} ** MAX_USB_INTERFACES;
        instance.current.endpoint_count = 0;
        instance.current.descriptor_records = 0;
        instance.current.descriptor_unknown = 0;
        instance.current.descriptor_malformed = 0;
        instance.current.hid_descriptor_count = 0;
        instance.current.ss_endpoint_companion_count = 0;
        instance.current.selected_interface_reason = "none";
        instance.current.first_interface_number = 0;
        instance.current.first_interface_class = 0;
        instance.current.first_interface_subclass = 0;
        instance.current.first_interface_protocol = 0;
        instance.current.first_endpoint_address = 0;
        instance.current.first_endpoint_attributes = 0;
        instance.current.first_endpoint_max_packet = 0;
        instance.current.first_endpoint_interval = 0;
        instance.current.first_hid_descriptor_len = 0;
        instance.current.first_hid_report_descriptor_len = 0;
        instance.current.bulk_in_endpoint_address = 0;
        instance.current.bulk_in_endpoint_max_packet = 0;
        instance.current.bulk_in_endpoint_max_burst = 0;
        instance.current.bulk_out_endpoint_address = 0;
        instance.current.bulk_out_endpoint_max_packet = 0;
        instance.current.bulk_out_endpoint_max_burst = 0;
        instance.current.string_language_id = 0;
        instance.current.manufacturer_len = 0;
        instance.current.product_len = 0;
        instance.current.serial_len = 0;
        @memset(instance.current.manufacturer_string[0..], 0);
        @memset(instance.current.product_string[0..], 0);
        @memset(instance.current.serial_string[0..], 0);
    }

    fn isBootHidInput(instance: *Instance) bool {
        return instance.current.first_interface_class == 0x03 and
            instance.current.first_interface_subclass == 0x01 and
            (instance.current.first_interface_protocol == 0x01 or instance.current.first_interface_protocol == 0x02) and
            (instance.current.first_endpoint_address & 0x80) != 0 and
            (instance.current.first_endpoint_attributes & 0x03) == 0x03;
    }

    fn isMassStorageBulk(instance: *Instance) bool {
        return instance.current.first_interface_class == 0x08 and
            instance.current.first_interface_subclass == 0x06 and
            instance.current.first_interface_protocol == 0x50 and
            instance.current.bulk_in_endpoint_address != 0 and
            instance.current.bulk_out_endpoint_address != 0;
    }

    fn disableCurrentSlotForScan(instance: *Instance) void {
        if (instance.current.addressed_slot_id == 0) return;
        const slot = instance.current.addressed_slot_id;
        const port = instance.current.addressed_port;
        if (instance.runtimeIndexForSlot(slot)) |index| {
            if (instance.deferRuntimeDetach(&instance.runtimes[index])) return;
        }
        if (!instance.disableSlot(slot)) return;
        if (port != 0) _ = usb_core.removeByPort(instance.nameSlice(), port);
        instance.releaseRuntimeBySlot(slot);
        instance.current.addressed_slot_id = 0;
        instance.current.addressed_port = 0;
        instance.current.control_endpoint_faulted = false;
        instance.current.interrupt_endpoint_configured = false;
        instance.current.interrupt_endpoint_faulted = false;
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_transfer_handle = 0;
        instance.current.interrupt_pending_streak = 0;
        instance.current.interrupt_endpoint_id = 0;
        instance.current.interrupt_endpoint_address = 0;
        instance.current.interrupt_endpoint_max_packet = 0;
        instance.current.interrupt_endpoint_interval_raw = 0;
        instance.current.interrupt_endpoint_interval_context = 0;
        instance.current.bulk_endpoints_configured = false;
        instance.current.bulk_endpoints_faulted = false;
    }

    fn disableSlot(instance: *Instance, slot: u8) bool {
        if (slot == 0) return false;
        instance.current.disable_slot_commands += 1;
        const control = trbType(TRB_TYPE_DISABLE_SLOT) | (@as(u32, slot) << 24);
        const completion = instance.submitCommand(0, 0, control);
        const ok = completion != null and completion.?.code == COMPLETION_SUCCESS;
        if (!ok) {
            instance.current.disable_slot_failures += 1;
        }
        if (ok and instance.dcbaa_virt != 0) {
            const dcbaa: [*]u64 = @ptrFromInt(instance.dcbaa_virt);
            dcbaa[slot] = 0;
            dmaFence();
        }
        return ok;
    }

    fn allocFirstDeviceRuntime(instance: *Instance) bool {
        if (instance.current.addressed_slot_id == 0) return false;
        const runtime_index = instance.runtimeIndexForSlot(instance.current.addressed_slot_id) orelse instance.allocateRuntime(instance.current.addressed_slot_id, instance.current.addressed_port, instance.current.addressed_speed) orelse return false;
        if (!instance.activateRuntime(runtime_index)) return false;
        if (instance.first_device_virt == 0 or instance.first_input_virt == 0 or instance.first_ep0_ring_virt == 0 or instance.first_descriptor_virt == 0) return false;
        const device: [*]u8 = @ptrFromInt(instance.first_device_virt);
        const input: [*]u8 = @ptrFromInt(instance.first_input_virt);
        const descriptor: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        const interrupt_buffer: [*]u8 = @ptrFromInt(instance.first_interrupt_buffer_virt);
        const bulk_buffer: [*]u8 = @ptrFromInt(instance.first_bulk_buffer_virt);
        @memset(device[0..DEVICE_CONTEXT_BYTES], 0);
        @memset(input[0..INPUT_CONTEXT_BYTES], 0);
        @memset(descriptor[0..DESCRIPTOR_BYTES], 0);
        @memset(interrupt_buffer[0..INTERRUPT_BUFFER_BYTES], 0);
        @memset(bulk_buffer[0..BULK_BUFFER_BYTES], 0);
        const dcbaa: [*]u64 = @ptrFromInt(instance.dcbaa_virt);
        dcbaa[instance.current.addressed_slot_id] = instance.current.device_context_phys;
        instance.initEp0Ring();
        instance.initInterruptRing();
        instance.initBulkRings();
        return true;
    }

    fn allocateRuntime(instance: *Instance, slot_id: u8, port: u8, speed: u8) ?usize {
        _ = instance.deferred_events.purgeSlot(slot_id);
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.runtimes[i].active) continue;
            if (instance.runtime_generation == 0xffff_ffff_ffff_ffff) return null;
            instance.runtime_generation += 1;
            var rt = &instance.runtimes[i];
            rt.* = .{
                .active = true,
                .generation = instance.runtime_generation,
                .slot_id = slot_id,
                .port = port,
                .speed = speed,
            };
            rt.device_context_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "device context");
            rt.input_context_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "input context");
            rt.ep0_ring_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "ep0 ring");
            rt.interrupt_ring_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "interrupt ring");
            rt.interrupt_buffer_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "interrupt buffer");
            rt.bulk_in_ring_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "bulk in ring");
            rt.bulk_out_ring_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "bulk out ring");
            rt.bulk_buffer_frames = BULK_BUFFER_FRAMES;
            rt.bulk_buffer_phys = allocContiguousZero(BULK_BUFFER_FRAMES) orelse return instance.failAllocRuntime(i, "bulk buffer");
            rt.descriptor_phys = allocFrameZero() orelse return instance.failAllocRuntime(i, "descriptor");
            rt.device_virt = phys.physToVirt(rt.device_context_phys);
            rt.input_virt = phys.physToVirt(rt.input_context_phys);
            rt.ep0_ring_virt = phys.physToVirt(rt.ep0_ring_phys);
            rt.interrupt_ring_virt = phys.physToVirt(rt.interrupt_ring_phys);
            rt.interrupt_buffer_virt = phys.physToVirt(rt.interrupt_buffer_phys);
            rt.bulk_in_ring_virt = phys.physToVirt(rt.bulk_in_ring_phys);
            rt.bulk_out_ring_virt = phys.physToVirt(rt.bulk_out_ring_phys);
            rt.bulk_buffer_virt = phys.physToVirt(rt.bulk_buffer_phys);
            rt.descriptor_virt = phys.physToVirt(rt.descriptor_phys);
            instance.current.retained_slots += 1;
            return i;
        }
        instance.current.failures += 1;
        instance.current.reason = "xHCI runtime table full";
        return null;
    }

    fn failAllocRuntime(instance: *Instance, index_value: usize, what: []const u8) ?usize {
        freeRuntimeFrames(&instance.runtimes[index_value]);
        _ = instance.failAlloc(what);
        return null;
    }

    fn activateRuntimeByPort(instance: *Instance, port: u8) bool {
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.runtimes[i].active and instance.runtimes[i].port == port) return instance.activateRuntime(i);
        }
        return false;
    }

    fn activateRuntimeBySlot(instance: *Instance, slot_id: u8) bool {
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.runtimes[i].active and instance.runtimes[i].slot_id == slot_id) return instance.activateRuntime(i);
        }
        return false;
    }

    fn activateRuntimeByIdentity(instance: *Instance, slot_id: u8, port: u8) bool {
        const index_value = instance.runtimeIndexForIdentity(slot_id, port) orelse return false;
        return instance.activateRuntime(index_value);
    }

    fn runtimeIndexForSlot(instance: *Instance, slot_id: u8) ?usize {
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.runtimes[i].active and instance.runtimes[i].slot_id == slot_id) return i;
        }
        return null;
    }

    fn runtimeIndexForIdentity(instance: *Instance, slot_id: u8, port: u8) ?usize {
        if (slot_id == 0 or port == 0) return null;
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.runtimes[i].active and
                instance.runtimes[i].slot_id == slot_id and
                instance.runtimes[i].port == port)
                return i;
        }
        return null;
    }

    fn activateRuntime(instance: *Instance, index_value: usize) bool {
        if (index_value >= instance.runtimes.len or !instance.runtimes[index_value].active) return false;
        if (instance.active_runtime_index) |active| {
            if (active == index_value) {
                instance.persistActiveRuntime();
                return true;
            }
            instance.persistActiveRuntime();
        }
        instance.active_runtime_index = index_value;
        instance.current.runtime_switches += 1;
        instance.loadRuntime(index_value);
        return true;
    }

    fn persistActiveRuntime(instance: *Instance) void {
        const idx = instance.active_runtime_index orelse return;
        if (idx >= instance.runtimes.len or !instance.runtimes[idx].active) return;
        var rt = &instance.runtimes[idx];
        rt.slot_id = instance.current.addressed_slot_id;
        rt.port = instance.current.addressed_port;
        rt.speed = instance.current.addressed_speed;
        rt.config_value = instance.current.config_value;
        rt.vendor_id = instance.current.device_vendor_id;
        rt.product_id = instance.current.device_product_id;
        rt.device_context_phys = instance.current.device_context_phys;
        rt.input_context_phys = instance.current.input_context_phys;
        rt.ep0_ring_phys = instance.current.ep0_ring_phys;
        rt.interrupt_ring_phys = instance.current.interrupt_ring_phys;
        rt.interrupt_buffer_phys = instance.current.interrupt_buffer_phys;
        rt.bulk_in_ring_phys = instance.current.bulk_in_ring_phys;
        rt.bulk_out_ring_phys = instance.current.bulk_out_ring_phys;
        rt.bulk_buffer_phys = instance.current.bulk_buffer_phys;
        rt.bulk_buffer_frames = instance.current.bulk_buffer_frames;
        rt.descriptor_phys = instance.current.descriptor_phys;
        rt.device_virt = instance.first_device_virt;
        rt.input_virt = instance.first_input_virt;
        rt.ep0_ring_virt = instance.first_ep0_ring_virt;
        rt.interrupt_ring_virt = instance.first_interrupt_ring_virt;
        rt.interrupt_buffer_virt = instance.first_interrupt_buffer_virt;
        rt.bulk_in_ring_virt = instance.first_bulk_in_ring_virt;
        rt.bulk_out_ring_virt = instance.first_bulk_out_ring_virt;
        rt.bulk_buffer_virt = instance.first_bulk_buffer_virt;
        rt.descriptor_virt = instance.first_descriptor_virt;
        rt.ep0_enqueue = instance.current.ep0_enqueue;
        rt.ep0_cycle = instance.current.ep0_cycle;
        rt.control_endpoint_faulted = instance.current.control_endpoint_faulted;
        rt.interrupt_enqueue = instance.current.interrupt_enqueue;
        rt.interrupt_cycle = instance.current.interrupt_cycle;
        rt.interrupt_endpoint_id = instance.current.interrupt_endpoint_id;
        rt.interrupt_endpoint_address = instance.current.interrupt_endpoint_address;
        rt.interrupt_endpoint_max_packet = instance.current.interrupt_endpoint_max_packet;
        rt.interrupt_endpoint_interval_raw = instance.current.interrupt_endpoint_interval_raw;
        rt.interrupt_endpoint_interval_context = instance.current.interrupt_endpoint_interval_context;
        rt.interrupt_endpoint_configured = instance.current.interrupt_endpoint_configured;
        rt.interrupt_endpoint_faulted = instance.current.interrupt_endpoint_faulted;
        rt.interrupt_pending = instance.current.interrupt_pending;
        rt.interrupt_pending_trb_phys = instance.current.interrupt_pending_trb_phys;
        rt.interrupt_transfer_handle = instance.current.interrupt_transfer_handle;
        rt.interrupt_pending_streak = instance.current.interrupt_pending_streak;
        rt.last_interrupt_ep_state = instance.current.last_interrupt_ep_state;
        rt.last_interrupt_request_len = instance.current.last_interrupt_request_len;
        rt.last_interrupt_residue = instance.current.last_interrupt_residue;
        rt.last_interrupt_actual_len = instance.current.last_interrupt_actual_len;
        rt.last_interrupt_completion_code = instance.current.last_interrupt_completion_code;
        rt.bulk_endpoints_configured = instance.current.bulk_endpoints_configured;
        rt.bulk_endpoints_faulted = instance.current.bulk_endpoints_faulted;
        rt.bulk_in_endpoint_id = instance.current.bulk_in_endpoint_id;
        rt.bulk_in_endpoint_address = instance.current.bulk_in_endpoint_address;
        rt.bulk_in_endpoint_max_packet = instance.current.bulk_in_endpoint_max_packet;
        rt.bulk_in_endpoint_max_burst = instance.current.bulk_in_endpoint_max_burst;
        rt.bulk_out_endpoint_id = instance.current.bulk_out_endpoint_id;
        rt.bulk_out_endpoint_address = instance.current.bulk_out_endpoint_address;
        rt.bulk_out_endpoint_max_packet = instance.current.bulk_out_endpoint_max_packet;
        rt.bulk_out_endpoint_max_burst = instance.current.bulk_out_endpoint_max_burst;
        rt.bulk_in_enqueue = instance.current.bulk_in_enqueue;
        rt.bulk_in_cycle = instance.current.bulk_in_cycle;
        rt.bulk_in_link_update_pending = instance.current.bulk_in_link_update_pending;
        rt.bulk_out_enqueue = instance.current.bulk_out_enqueue;
        rt.bulk_out_cycle = instance.current.bulk_out_cycle;
        rt.bulk_out_link_update_pending = instance.current.bulk_out_link_update_pending;
        inline for (.{ "last_control_request_type", "last_control_request", "last_control_value", "last_control_index", "last_control_length", "last_control_direction", "last_control_completion_code", "last_control_residue", "last_control_ok", "last_bulk_direction", "last_bulk_result", "last_bulk_request_len", "last_bulk_residue", "last_bulk_actual_len", "last_bulk_completion_code", "last_wait_cancelled" }) |field| @field(rt, field) = @field(instance.current, field);
        rt.sync_transfer_incident = instance.last_sync_transfer_incident;
    }

    fn loadRuntime(instance: *Instance, index_value: usize) void {
        const rt = instance.runtimes[index_value];
        instance.current.addressed_slot_id = rt.slot_id;
        instance.current.addressed_port = rt.port;
        instance.current.addressed_speed = rt.speed;
        instance.current.config_value = rt.config_value;
        instance.current.device_vendor_id = rt.vendor_id;
        instance.current.device_product_id = rt.product_id;
        instance.current.get_config_ok = rt.config_value != 0;
        instance.current.device_context_phys = rt.device_context_phys;
        instance.current.input_context_phys = rt.input_context_phys;
        instance.current.ep0_ring_phys = rt.ep0_ring_phys;
        instance.current.interrupt_ring_phys = rt.interrupt_ring_phys;
        instance.current.interrupt_buffer_phys = rt.interrupt_buffer_phys;
        instance.current.bulk_in_ring_phys = rt.bulk_in_ring_phys;
        instance.current.bulk_out_ring_phys = rt.bulk_out_ring_phys;
        instance.current.bulk_buffer_phys = rt.bulk_buffer_phys;
        instance.current.bulk_buffer_frames = rt.bulk_buffer_frames;
        instance.current.descriptor_phys = rt.descriptor_phys;
        instance.first_device_virt = rt.device_virt;
        instance.first_input_virt = rt.input_virt;
        instance.first_ep0_ring_virt = rt.ep0_ring_virt;
        instance.first_interrupt_ring_virt = rt.interrupt_ring_virt;
        instance.first_interrupt_buffer_virt = rt.interrupt_buffer_virt;
        instance.first_bulk_in_ring_virt = rt.bulk_in_ring_virt;
        instance.first_bulk_out_ring_virt = rt.bulk_out_ring_virt;
        instance.first_bulk_buffer_virt = rt.bulk_buffer_virt;
        instance.first_descriptor_virt = rt.descriptor_virt;
        instance.current.ep0_enqueue = rt.ep0_enqueue;
        instance.current.ep0_cycle = rt.ep0_cycle;
        instance.current.control_endpoint_faulted = rt.control_endpoint_faulted;
        instance.current.interrupt_enqueue = rt.interrupt_enqueue;
        instance.current.interrupt_cycle = rt.interrupt_cycle;
        instance.current.interrupt_endpoint_id = rt.interrupt_endpoint_id;
        instance.current.interrupt_endpoint_address = rt.interrupt_endpoint_address;
        instance.current.interrupt_endpoint_max_packet = rt.interrupt_endpoint_max_packet;
        instance.current.interrupt_endpoint_interval_raw = rt.interrupt_endpoint_interval_raw;
        instance.current.interrupt_endpoint_interval_context = rt.interrupt_endpoint_interval_context;
        instance.current.interrupt_endpoint_configured = rt.interrupt_endpoint_configured;
        instance.current.interrupt_endpoint_faulted = rt.interrupt_endpoint_faulted;
        instance.current.interrupt_pending = rt.interrupt_pending;
        instance.current.interrupt_transfer_handle = rt.interrupt_transfer_handle;
        instance.current.interrupt_pending_trb_phys = rt.interrupt_pending_trb_phys;
        instance.current.interrupt_pending_streak = rt.interrupt_pending_streak;
        instance.current.last_interrupt_ep_state = rt.last_interrupt_ep_state;
        instance.current.last_interrupt_request_len = rt.last_interrupt_request_len;
        instance.current.last_interrupt_residue = rt.last_interrupt_residue;
        instance.current.last_interrupt_actual_len = rt.last_interrupt_actual_len;
        instance.current.last_interrupt_completion_code = rt.last_interrupt_completion_code;
        instance.current.bulk_endpoints_configured = rt.bulk_endpoints_configured;
        instance.current.bulk_endpoints_faulted = rt.bulk_endpoints_faulted;
        instance.current.bulk_in_endpoint_id = rt.bulk_in_endpoint_id;
        instance.current.bulk_in_endpoint_address = rt.bulk_in_endpoint_address;
        instance.current.bulk_in_endpoint_max_packet = rt.bulk_in_endpoint_max_packet;
        instance.current.bulk_in_endpoint_max_burst = rt.bulk_in_endpoint_max_burst;
        instance.current.bulk_out_endpoint_id = rt.bulk_out_endpoint_id;
        instance.current.bulk_out_endpoint_address = rt.bulk_out_endpoint_address;
        instance.current.bulk_out_endpoint_max_packet = rt.bulk_out_endpoint_max_packet;
        instance.current.bulk_out_endpoint_max_burst = rt.bulk_out_endpoint_max_burst;
        instance.current.bulk_in_enqueue = rt.bulk_in_enqueue;
        instance.current.bulk_in_cycle = rt.bulk_in_cycle;
        instance.current.bulk_in_link_update_pending = rt.bulk_in_link_update_pending;
        instance.current.bulk_out_enqueue = rt.bulk_out_enqueue;
        instance.current.bulk_out_cycle = rt.bulk_out_cycle;
        instance.current.bulk_out_link_update_pending = rt.bulk_out_link_update_pending;
        inline for (.{ "last_control_request_type", "last_control_request", "last_control_value", "last_control_index", "last_control_length", "last_control_direction", "last_control_completion_code", "last_control_residue", "last_control_ok", "last_bulk_direction", "last_bulk_result", "last_bulk_request_len", "last_bulk_residue", "last_bulk_actual_len", "last_bulk_completion_code", "last_wait_cancelled" }) |field| @field(instance.current, field) = @field(rt, field);
        instance.last_sync_transfer_incident = rt.sync_transfer_incident;
    }

    fn releaseRuntimeBySlot(instance: *Instance, slot_id: u8) void {
        if (instance.runtimeIndexForSlot(slot_id)) |index| {
            if (instance.deferRuntimeDetach(&instance.runtimes[index])) return;
        }
        _ = instance.deferred_events.purgeSlot(slot_id);
        _ = instance.transfer_objects.purgeSlot(slot_id);
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (!instance.runtimes[i].active or instance.runtimes[i].slot_id != slot_id) continue;
            const was_active = instance.active_runtime_index != null and instance.active_runtime_index.? == i;
            if (was_active) instance.closeLastSyncTransferIncident() else {
                _ = diag_screen.resolveIncident(instance.runtimes[i].sync_transfer_incident);
            }
            freeRuntimeFrames(&instance.runtimes[i]);
            if (instance.current.retained_slots > 0) instance.current.retained_slots -= 1;
            if (was_active) {
                instance.active_runtime_index = null;
                instance.clearCurrentRuntimeSelection(slot_id);
            }
            return;
        }
    }

    fn freeAllRuntimes(instance: *Instance) void {
        for (&instance.runtimes) |*rt| freeRuntimeFrames(rt);
        instance.runtimes = .{DeviceRuntime{}} ** MAX_USB_DEVICES;
        instance.active_runtime_index = null;
        instance.current.retained_slots = 0;
        instance.clearCurrentRuntimeSelection(instance.current.addressed_slot_id);
    }

    fn deferRuntimeDetach(instance: *Instance, rt: *DeviceRuntime) bool {
        if (!rt.transaction_active) return false;
        rt.detach_pending = true;
        instance.pending_port_changes.retry(rt.port);
        return true;
    }

    fn clearCurrentRuntimeSelection(instance: *Instance, slot_id: u8) void {
        if (slot_id != 0 and instance.current.addressed_slot_id != slot_id) return;
        instance.current.addressed_slot_id = 0;
        instance.current.addressed_port = 0;
        instance.current.addressed_speed = 0;
        instance.current.config_value = 0;
        instance.current.device_vendor_id = 0;
        instance.current.device_product_id = 0;
        instance.current.get_config_ok = false;
        instance.current.device_context_phys = 0;
        instance.current.input_context_phys = 0;
        instance.current.ep0_ring_phys = 0;
        instance.current.interrupt_ring_phys = 0;
        instance.current.interrupt_buffer_phys = 0;
        instance.current.bulk_in_ring_phys = 0;
        instance.current.bulk_out_ring_phys = 0;
        instance.current.bulk_buffer_phys = 0;
        instance.current.bulk_buffer_frames = 0;
        instance.current.descriptor_phys = 0;
        instance.first_device_virt = 0;
        instance.first_input_virt = 0;
        instance.first_ep0_ring_virt = 0;
        instance.first_interrupt_ring_virt = 0;
        instance.first_interrupt_buffer_virt = 0;
        instance.first_bulk_in_ring_virt = 0;
        instance.first_bulk_out_ring_virt = 0;
        instance.first_bulk_buffer_virt = 0;
        instance.first_descriptor_virt = 0;
        instance.current.control_endpoint_faulted = false;
        instance.current.interrupt_endpoint_configured = false;
        instance.current.interrupt_endpoint_faulted = false;
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_transfer_handle = 0;
        instance.current.interrupt_pending_streak = 0;
        instance.current.interrupt_endpoint_id = 0;
        instance.current.interrupt_endpoint_address = 0;
        instance.current.interrupt_endpoint_max_packet = 0;
        instance.current.interrupt_endpoint_interval_raw = 0;
        instance.current.interrupt_endpoint_interval_context = 0;
        instance.current.bulk_endpoints_configured = false;
        instance.current.bulk_endpoints_faulted = false;
        instance.current.bulk_in_endpoint_id = 0;
        instance.current.bulk_in_endpoint_address = 0;
        instance.current.bulk_in_endpoint_max_packet = 0;
        instance.current.bulk_in_endpoint_max_burst = 0;
        instance.current.bulk_out_endpoint_id = 0;
        instance.current.bulk_out_endpoint_address = 0;
        instance.current.bulk_out_endpoint_max_packet = 0;
        instance.current.bulk_out_endpoint_max_burst = 0;
    }

    fn reclaimDisconnectedRuntimes(instance: *Instance) void {
        instance.persistActiveRuntime();
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (!instance.runtimes[i].active) continue;
            const slot = instance.runtimes[i].slot_id;
            const port = instance.runtimes[i].port;
            if (slot == 0 or port == 0 or instance.portIsConnected(port)) continue;
            if (instance.deferRuntimeDetach(&instance.runtimes[i])) continue;
            instance.current.port_disconnects += 1;
            if (!instance.disableSlot(slot)) continue;
            _ = usb_core.removeByPort(instance.nameSlice(), port);
            instance.releaseRuntimeBySlot(slot);
            instance.current.reclaimed_slots += 1;
            if (instance.current.addressed_slot_id == slot) {
                instance.current.addressed_slot_id = 0;
                instance.current.addressed_port = 0;
                instance.current.control_endpoint_faulted = false;
                instance.current.interrupt_endpoint_configured = false;
                instance.current.interrupt_endpoint_faulted = false;
                instance.current.interrupt_pending = false;
                instance.current.interrupt_pending_trb_phys = 0;
                instance.current.interrupt_transfer_handle = 0;
                instance.current.interrupt_pending_streak = 0;
                instance.current.interrupt_endpoint_id = 0;
                instance.current.interrupt_endpoint_address = 0;
                instance.current.interrupt_endpoint_max_packet = 0;
                instance.current.interrupt_endpoint_interval_raw = 0;
                instance.current.interrupt_endpoint_interval_context = 0;
                instance.current.bulk_endpoints_configured = false;
                instance.current.bulk_endpoints_faulted = false;
            }
        }
    }

    fn refreshPortsAndReclaim(instance: *Instance) void {
        if (!instance.current.present or instance.current.mmio_virt == 0 or !instance.current.controller_running) return;
        instance.readOperational();
        instance.readRuntime();
        instance.readPorts();
        instance.reclaimDisconnectedRuntimes();
    }

    fn servicePendingPortChange(instance: *Instance, port: u8) PortServiceOutcome {
        if (port == 0 or port > instance.current.port_count_seen or port > @as(u8, MAX_PORTS)) {
            instance.current.port_service_failures +%= 1;
            return .{};
        }

        const index: usize = @intCast(port - 1);
        var snapshot = instance.current.first_ports[index];
        instance.refreshPortStatus(&snapshot, index);
        instance.storePortSnapshot(index, snapshot);

        const runtime_index = instance.runtimeIndexForPort(port);
        const action = event_router.decidePortAction(
            runtime_index != null,
            snapshot.connected,
            (snapshot.change_bits & PORTSC_CSC) != 0,
        );
        var catalog_changed = false;

        if (action == .remove or action == .replace) {
            if (runtime_index) |runtime| {
                if (!instance.reclaimRuntimeForPort(runtime, port)) {
                    instance.current.port_service_failures +%= 1;
                    instance.current.reason = "xHCI hotplug reclaim failed";
                    return .{ .retry = true };
                }
                instance.current.port_disconnects +%= 1;
                catalog_changed = true;
            }
        }

        if (action == .acknowledge or action == .remove) {
            instance.acknowledgePortChanges(index);
            return .{ .catalog_changed = catalog_changed };
        }

        var prepared = instance.current.first_ports[index];
        // A newly attached or replaced device has not passed the boot-time reset
        // pass. Use the startup preparation contract so even an already enabled
        // SuperSpeed port receives the mandatory enumeration reset. PortStatus
        // deliberately retains boot diagnostics across ordinary refreshes, so a
        // reused physical port must discard the previous device's preparation
        // state before starting the new lifecycle.
        prepared.debounce_ok = false;
        prepared.reset_attempted = false;
        prepared.reset_ok = false;
        prepared.reset_reason = "hotplug-not-started";
        if (!instance.preparePortState(index, &prepared, .startup)) {
            instance.storePortSnapshot(index, prepared);
            instance.current.port_service_failures +%= 1;
            instance.current.reason = "xHCI hotplug port not ready";
            return .{ .catalog_changed = catalog_changed };
        }
        instance.storePortSnapshot(index, prepared);

        if (!instance.probePortDevice(index) or !instance.current.get_config_ok) {
            instance.disableCurrentSlotForScan();
            instance.acknowledgePortChanges(index);
            instance.current.port_service_failures +%= 1;
            instance.current.reason = "xHCI hotplug enumeration failed";
            return .{ .catalog_changed = catalog_changed };
        }
        instance.publishCurrentCoreDevice();
        instance.persistActiveRuntime();
        instance.acknowledgePortChanges(index);
        return .{ .catalog_changed = true };
    }

    fn runtimeIndexForPort(instance: *Instance, port: u8) ?usize {
        var index: usize = 0;
        while (index < instance.runtimes.len) : (index += 1) {
            if (instance.runtimes[index].active and instance.runtimes[index].port == port) return index;
        }
        return null;
    }

    fn reclaimRuntimeForPort(instance: *Instance, runtime_index: usize, port: u8) bool {
        if (runtime_index >= instance.runtimes.len or !instance.runtimes[runtime_index].active) return true;
        if (instance.deferRuntimeDetach(&instance.runtimes[runtime_index])) return false;
        instance.persistActiveRuntime();
        const slot = instance.runtimes[runtime_index].slot_id;
        if (slot == 0 or instance.runtimes[runtime_index].port != port) return false;
        if (!instance.disableSlot(slot)) return false;
        _ = usb_core.removeByPort(instance.nameSlice(), port);
        instance.releaseRuntimeBySlot(slot);
        instance.current.reclaimed_slots +%= 1;
        return true;
    }

    fn acknowledgePortChanges(instance: *Instance, index: usize) void {
        _ = instance.clearPortChanges(index);
        var snapshot = instance.current.first_ports[index];
        instance.refreshPortStatus(&snapshot, index);
        instance.storePortSnapshot(index, snapshot);
    }

    fn storePortSnapshot(instance: *Instance, index: usize, snapshot: PortStatus) void {
        if (index >= @as(usize, instance.current.port_count_seen) or index >= MAX_PORTS) return;
        const previous = instance.current.first_ports[index];
        if (previous.connected != snapshot.connected) {
            if (snapshot.connected) {
                instance.current.connected_ports +|= 1;
            } else if (instance.current.connected_ports > 0) {
                instance.current.connected_ports -= 1;
            }
        }
        if (previous.enabled != snapshot.enabled) {
            if (snapshot.enabled) {
                instance.current.enabled_ports +|= 1;
            } else if (instance.current.enabled_ports > 0) {
                instance.current.enabled_ports -= 1;
            }
        }
        instance.current.first_ports[index] = snapshot;
    }

    fn refreshPortSnapshotByNumber(instance: *Instance, port: u8) void {
        if (port == 0 or port > instance.current.port_count_seen) return;
        const index: usize = @intCast(port - 1);
        var snapshot = instance.current.first_ports[index];
        instance.refreshPortStatus(&snapshot, index);
        instance.storePortSnapshot(index, snapshot);
    }

    fn portIsConnected(instance: *Instance, port: u8) bool {
        var i: usize = 0;
        while (i < @as(usize, instance.current.port_count_seen)) : (i += 1) {
            const p = instance.current.first_ports[i];
            if (p.index == port) return p.connected;
        }
        return false;
    }

    fn initEp0Ring(instance: *Instance) void {
        const ring: [*]Trb = @ptrFromInt(instance.first_ep0_ring_virt);
        var i: usize = 0;
        while (i < TRANSFER_TRB_COUNT) : (i += 1) ring[i] = .{ .parameter = 0, .status = 0, .control = 0 };
        ring[TRANSFER_TRB_COUNT - 1] = .{
            .parameter = instance.current.ep0_ring_phys,
            .status = 0,
            .control = trbType(TRB_TYPE_LINK) | TRB_LINK_TOGGLE_CYCLE,
        };
        instance.current.ep0_enqueue = 0;
        instance.current.ep0_cycle = 1;
        instance.current.control_endpoint_faulted = false;
    }

    fn initInterruptRing(instance: *Instance) void {
        if (instance.currentInterruptOwnerMatch()) |owner| _ = instance.deferred_events.purge(owner);
        instance.releaseInterruptTransfer(true);
        const ring: [*]Trb = @ptrFromInt(instance.first_interrupt_ring_virt);
        var i: usize = 0;
        while (i < TRANSFER_TRB_COUNT) : (i += 1) ring[i] = .{ .parameter = 0, .status = 0, .control = 0 };
        ring[TRANSFER_TRB_COUNT - 1] = .{
            .parameter = instance.current.interrupt_ring_phys,
            .status = 0,
            .control = trbType(TRB_TYPE_LINK) | TRB_LINK_TOGGLE_CYCLE,
        };
        instance.current.interrupt_enqueue = 0;
        instance.current.interrupt_cycle = 1;
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_transfer_handle = 0;
        instance.current.interrupt_pending_streak = 0;
    }

    fn initBulkRings(instance: *Instance) void {
        initRing(instance.first_bulk_in_ring_virt, instance.current.bulk_in_ring_phys);
        initRing(instance.first_bulk_out_ring_virt, instance.current.bulk_out_ring_phys);
        instance.current.bulk_in_enqueue = 0;
        instance.current.bulk_in_cycle = 1;
        instance.current.bulk_out_enqueue = 0;
        instance.current.bulk_out_cycle = 1;
    }

    fn setupFirstInputContext(instance: *Instance, port_index: usize) void {
        const input: [*]u32 = @ptrFromInt(instance.first_input_virt);
        const ctx_dwords = @as(usize, instance.current.context_size) / 4;
        const input_control = input;
        input_control[0] = 0;
        input_control[1] = 0x3;

        const slot = input + ctx_dwords;
        slot[0] = (@as(u32, instance.current.addressed_speed) << 20) | (1 << 27);
        slot[1] = @as(u32, instance.current.first_ports[port_index].index) << 16;
        slot[2] = 0;
        slot[3] = 0;

        const ep0 = input + (ctx_dwords * 2);
        ep0[0] = 0;
        ep0[1] = (3 << 1) | (4 << 3) | (@as(u32, maxPacketForSpeed(instance.current.addressed_speed)) << 16);
        ep0[2] = @truncate(instance.current.ep0_ring_phys | 1);
        ep0[3] = @truncate((instance.current.ep0_ring_phys | 1) >> 32);
        ep0[4] = 8;
    }

    fn addressFirstDevice(instance: *Instance) bool {
        instance.current.address_device_attempted = true;
        const control = trbType(TRB_TYPE_ADDRESS_DEVICE) | (@as(u32, instance.current.addressed_slot_id) << 24);
        const completion = instance.submitCommand(instance.current.input_context_phys, 0, control) orelse return false;
        instance.current.last_completion_code = completion.code;
        instance.current.last_slot_id = completion.slot_id;
        instance.current.address_device_ok = completion.code == COMPLETION_SUCCESS;
        if (!instance.current.address_device_ok) instance.current.failures += 1;
        if (instance.current.address_device_ok) {
            _ = usb_wait.millisecondsWithReason(
                usb_timing.SET_ADDRESS_SETTLE_MS,
                "xhci-address-settle",
                0,
            );
        }
        return instance.current.address_device_ok;
    }

    fn getFirstDeviceDescriptor(instance: *Instance) bool {
        instance.current.get_descriptor_attempted = true;
        const desc: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        @memset(desc[0..DESCRIPTOR_BYTES], 0);
        if (!instance.submitControlIn(USB_REQ_GET_DESCRIPTOR, @as(u16, USB_DESC_DEVICE) << 8, 0, DEVICE_DESCRIPTOR_LEN, instance.current.descriptor_phys)) return false;
        instance.parseDeviceDescriptor();
        instance.current.get_descriptor_ok = instance.current.descriptor_len == DEVICE_DESCRIPTOR_LEN and instance.current.descriptor_type == USB_DESC_DEVICE;
        if (!instance.current.get_descriptor_ok) instance.current.failures += 1;
        return instance.current.get_descriptor_ok;
    }

    fn getFirstConfigDescriptor(instance: *Instance) bool {
        instance.current.get_config_attempted = true;
        const desc: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        @memset(desc[0..DESCRIPTOR_BYTES], 0);
        if (!instance.submitControlIn(USB_REQ_GET_DESCRIPTOR, @as(u16, USB_DESC_CONFIGURATION) << 8, 0, CONFIG_DESCRIPTOR_HEADER_LEN, instance.current.descriptor_phys)) return false;
        const total = readLe16(desc, 2);
        instance.current.config_total_length = total;
        if (desc[0] < CONFIG_DESCRIPTOR_HEADER_LEN or desc[1] != USB_DESC_CONFIGURATION or total < CONFIG_DESCRIPTOR_HEADER_LEN or total > DESCRIPTOR_BYTES) {
            instance.current.failures += 1;
            return false;
        }
        @memset(desc[0..DESCRIPTOR_BYTES], 0);
        if (!instance.submitControlIn(USB_REQ_GET_DESCRIPTOR, @as(u16, USB_DESC_CONFIGURATION) << 8, 0, total, instance.current.descriptor_phys)) return false;
        instance.parseConfigDescriptor(total);
        instance.current.get_config_ok = instance.current.config_total_length == total and instance.current.interface_count > 0;
        if (!instance.current.get_config_ok) instance.current.failures += 1;
        return instance.current.get_config_ok;
    }

    fn getFirstStringDescriptors(instance: *Instance) bool {
        instance.current.get_strings_attempted = true;
        instance.current.manufacturer_len = 0;
        instance.current.product_len = 0;
        instance.current.serial_len = 0;
        @memset(instance.current.manufacturer_string[0..], 0);
        @memset(instance.current.product_string[0..], 0);
        @memset(instance.current.serial_string[0..], 0);

        if (instance.current.manufacturer_index == 0 and instance.current.product_index == 0 and instance.current.serial_index == 0) {
            instance.current.get_strings_ok = true;
            return true;
        }

        instance.current.string_language_id = instance.readFirstStringLanguage() orelse 0x0409;
        var ok = true;
        if (instance.current.manufacturer_index != 0) {
            ok = instance.readAsciiStringDescriptor(instance.current.manufacturer_index, instance.current.string_language_id, &instance.current.manufacturer_string, &instance.current.manufacturer_len) and ok;
        }
        if (instance.current.product_index != 0) {
            ok = instance.readAsciiStringDescriptor(instance.current.product_index, instance.current.string_language_id, &instance.current.product_string, &instance.current.product_len) and ok;
        }
        if (instance.current.serial_index != 0) {
            ok = instance.readAsciiStringDescriptor(instance.current.serial_index, instance.current.string_language_id, &instance.current.serial_string, &instance.current.serial_len) and ok;
        }
        instance.current.get_strings_ok = ok;
        if (!ok) instance.current.failures += 1;
        return ok;
    }

    fn readFirstStringLanguage(instance: *Instance) ?u16 {
        const desc: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        @memset(desc[0..DESCRIPTOR_BYTES], 0);
        if (!instance.submitControlIn(USB_REQ_GET_DESCRIPTOR, @as(u16, USB_DESC_STRING) << 8, 0, 4, instance.current.descriptor_phys)) return null;
        if (desc[0] < 4 or desc[1] != USB_DESC_STRING) return null;
        return readLe16(desc, 2);
    }

    fn readAsciiStringDescriptor(instance: *Instance, index_value: u8, lang: u16, out: *[MAX_STRING_CHARS]u8, out_len: *u8) bool {
        @memset(out.*[0..], 0);
        out_len.* = 0;
        const desc: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        @memset(desc[0..DESCRIPTOR_BYTES], 0);
        if (!instance.submitControlIn(USB_REQ_GET_DESCRIPTOR, (@as(u16, USB_DESC_STRING) << 8) | index_value, lang, 255, instance.current.descriptor_phys)) return false;
        const length: usize = @min(@as(usize, @intCast(desc[0])), 255);
        if (length < 2 or desc[1] != USB_DESC_STRING) return false;

        var offset: usize = 2;
        var n: usize = 0;
        while (offset + 1 < length and n < MAX_STRING_CHARS) : ({
            offset += 2;
            n += 1;
        }) {
            const codepoint = readLe16(desc, offset);
            out.*[n] = if (codepoint >= 0x20 and codepoint <= 0x7E) @intCast(codepoint) else '?';
        }
        out_len.* = @intCast(n);
        return true;
    }

    fn publishCurrentCoreDevice(instance: *Instance) void {
        _ = usb_core.publishOrReplaceByPort(.{
            .controller_id = instance.id(),
            .generation = if (instance.active_runtime_index) |i| instance.runtimes[i].generation else 0,
            .configured = instance.current.get_config_ok,
            .controller = instance.nameSlice(),
            .slot_id = instance.current.addressed_slot_id,
            .port = instance.current.addressed_port,
            .speed = instance.current.addressed_speed,
            .usb_version_bcd = instance.current.usb_version_bcd,
            .vendor_id = instance.current.device_vendor_id,
            .product_id = instance.current.device_product_id,
            .device_version_bcd = instance.current.device_version_bcd,
            .device_class = instance.current.device_class,
            .device_subclass = instance.current.device_subclass,
            .device_protocol = instance.current.device_protocol,
            .config_value = instance.current.config_value,
            .config_attributes = instance.current.config_attributes,
            .config_max_power_ma = instance.current.config_max_power_ma,
            .interface_count = instance.current.interface_count,
            .interface_record_count = instance.current.interface_record_count,
            .interfaces = instance.current.interface_records,
            .endpoint_count = instance.current.endpoint_count,
            .first_interface_number = instance.current.first_interface_number,
            .first_interface_class = instance.current.first_interface_class,
            .first_interface_subclass = instance.current.first_interface_subclass,
            .first_interface_protocol = instance.current.first_interface_protocol,
            .first_endpoint_address = instance.current.first_endpoint_address,
            .first_endpoint_attributes = instance.current.first_endpoint_attributes,
            .first_endpoint_max_packet = instance.current.first_endpoint_max_packet,
            .first_endpoint_interval = instance.current.first_endpoint_interval,
            .bulk_in_endpoint_address = instance.current.bulk_in_endpoint_address,
            .bulk_in_endpoint_max_packet = instance.current.bulk_in_endpoint_max_packet,
            .bulk_in_endpoint_max_burst = instance.current.bulk_in_endpoint_max_burst,
            .bulk_out_endpoint_address = instance.current.bulk_out_endpoint_address,
            .bulk_out_endpoint_max_packet = instance.current.bulk_out_endpoint_max_packet,
            .bulk_out_endpoint_max_burst = instance.current.bulk_out_endpoint_max_burst,
            .hid_descriptor_len = instance.current.first_hid_descriptor_len,
            .hid_report_descriptor_len = instance.current.first_hid_report_descriptor_len,
            .string_language_id = instance.current.string_language_id,
            .manufacturer_len = instance.current.manufacturer_len,
            .product_len = instance.current.product_len,
            .serial_len = instance.current.serial_len,
            .manufacturer_string = instance.current.manufacturer_string,
            .product_string = instance.current.product_string,
            .serial_string = instance.current.serial_string,
        });
    }

    pub fn configureFirstInterruptInEndpoint(instance: *Instance, endpoint_address: u8, max_packet: u16, interval: u8) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        if (!instance.current.get_config_ok or instance.current.addressed_slot_id == 0 or instance.first_input_virt == 0 or instance.first_interrupt_ring_virt == 0) return false;
        if (instance.current.interrupt_endpoint_faulted) return false;
        if ((endpoint_address & 0x80) == 0) return false;
        const endpoint_number: u8 = endpoint_address & 0x0F;
        if (endpoint_number == 0) return false;
        const dci: u8 = endpoint_number * 2 + 1;
        if (dci >= 32) return false;
        if (instance.currentInterruptOwnerMatch()) |owner| _ = instance.deferred_events.purge(owner);
        instance.releaseInterruptTransfer(true);
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_pending_streak = 0;

        const input: [*]u32 = @ptrFromInt(instance.first_input_virt);
        @memset(input[0 .. INPUT_CONTEXT_BYTES / 4], 0);
        const ctx_dwords = @as(usize, instance.current.context_size) / 4;
        input[1] = (@as(u32, 1) << @as(u5, @intCast(dci))) | 0x1;

        const slot = input + ctx_dwords;
        slot[0] = (@as(u32, instance.current.addressed_speed) << 20) | (@as(u32, dci) << 27);
        slot[1] = @as(u32, instance.current.addressed_port) << 16;

        const ep = endpointContext(input, ctx_dwords, dci);
        const ep_type: u32 = 7; // Interrupt IN
        const mps: u16 = if (max_packet == 0) 8 else max_packet;
        const context_interval = encodeInterruptInterval(instance.current.addressed_speed, interval);
        instance.current.interrupt_endpoint_id = dci;
        instance.current.interrupt_endpoint_address = endpoint_address;
        instance.current.interrupt_endpoint_max_packet = mps;
        instance.current.interrupt_endpoint_interval_raw = interval;
        instance.current.interrupt_endpoint_interval_context = context_interval;
        ep[0] = @as(u32, context_interval) << 16;
        ep[1] = (3 << 1) | (ep_type << 3) | (@as(u32, mps) << 16);
        const interrupt_dequeue = instance.current.interrupt_ring_phys +
            @as(u64, instance.current.interrupt_enqueue) * @sizeOf(Trb) |
            @as(u64, if (instance.current.interrupt_cycle != 0) 1 else 0);
        ep[2] = @truncate(interrupt_dequeue);
        ep[3] = @truncate(interrupt_dequeue >> 32);
        ep[4] = @as(u32, mps) | (@as(u32, mps) << 16);

        const control = trbType(TRB_TYPE_CONFIGURE_ENDPOINT) | (@as(u32, instance.current.addressed_slot_id) << 24);
        const completion = instance.submitCommand(instance.current.input_context_phys, 0, control) orelse {
            // The command may have reached hardware even if its completion was
            // lost.  Never issue another Add-Configure against unknown contexts.
            instance.current.interrupt_endpoint_faulted = true;
            return false;
        };
        instance.current.last_completion_code = completion.code;
        instance.current.last_slot_id = completion.slot_id;
        instance.current.interrupt_endpoint_configured = completion.code == COMPLETION_SUCCESS;
        if (instance.current.interrupt_endpoint_configured) {
            instance.current.interrupt_endpoint_faulted = false;
            return true;
        }
        instance.current.interrupt_endpoint_faulted = true;
        instance.current.failures += 1;
        return false;
    }

    pub fn configureInterruptInEndpointHandle(instance: *Instance, handle: *EndpointHandle) bool {
        if (handle.kind != .interrupt_in) return false;
        if (!instance.selectDeviceHandle(&handle.device)) return false;
        if (!instance.configureFirstInterruptInEndpoint(handle.address, handle.max_packet, handle.interval)) return false;
        instance.refreshHandleFromCurrent(&handle.device);
        handle.endpoint_id = instance.current.interrupt_endpoint_id;
        return true;
    }

    pub fn configureFirstBulkEndpoints(
        instance: *Instance,
        in_address: u8,
        in_max_packet: u16,
        in_max_burst: u8,
        out_address: u8,
        out_max_packet: u16,
        out_max_burst: u8,
    ) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        if (!instance.current.get_config_ok or instance.current.addressed_slot_id == 0 or instance.first_input_virt == 0) return false;
        if (instance.current.bulk_endpoints_faulted) return false;
        if (instance.first_bulk_in_ring_virt == 0 or instance.first_bulk_out_ring_virt == 0) return false;
        if ((in_address & 0x80) == 0 or (out_address & 0x80) != 0) return false;
        const in_dci = endpointDci(in_address);
        const out_dci = endpointDci(out_address);
        if (in_dci == 0 or out_dci == 0 or in_dci >= 32 or out_dci >= 32) return false;
        const max_dci = if (in_dci > out_dci) in_dci else out_dci;

        const input: [*]u32 = @ptrFromInt(instance.first_input_virt);
        @memset(input[0 .. INPUT_CONTEXT_BYTES / 4], 0);
        const ctx_dwords = @as(usize, instance.current.context_size) / 4;
        input[1] = (@as(u32, 1) << @as(u5, @intCast(in_dci))) |
            (@as(u32, 1) << @as(u5, @intCast(out_dci))) | 0x1;

        const slot = input + ctx_dwords;
        slot[0] = (@as(u32, instance.current.addressed_speed) << 20) | (@as(u32, max_dci) << 27);
        slot[1] = @as(u32, instance.current.addressed_port) << 16;

        const in_dequeue = instance.current.bulk_in_ring_phys +
            @as(u64, instance.current.bulk_in_enqueue) * @sizeOf(Trb) |
            @as(u64, if (instance.current.bulk_in_cycle != 0) 1 else 0);
        const out_dequeue = instance.current.bulk_out_ring_phys +
            @as(u64, instance.current.bulk_out_enqueue) * @sizeOf(Trb) |
            @as(u64, if (instance.current.bulk_out_cycle != 0) 1 else 0);
        const in_fields = instance.setupBulkEpContext(input, ctx_dwords, in_dci, true, in_dequeue, in_max_packet, in_max_burst);
        const out_fields = instance.setupBulkEpContext(input, ctx_dwords, out_dci, false, out_dequeue, out_max_packet, out_max_burst);

        const control = trbType(TRB_TYPE_CONFIGURE_ENDPOINT) | (@as(u32, instance.current.addressed_slot_id) << 24);
        const completion = instance.submitCommand(instance.current.input_context_phys, 0, control) orelse {
            // Lost Configure completion leaves Add-Context ownership unknown.
            // A blind repeat is not an idempotent operation.
            instance.current.bulk_endpoints_faulted = true;
            return false;
        };
        instance.current.last_completion_code = completion.code;
        instance.current.last_slot_id = completion.slot_id;
        instance.current.bulk_endpoints_configured = completion.code == COMPLETION_SUCCESS;
        if (instance.current.bulk_endpoints_configured) {
            instance.current.bulk_endpoints_faulted = false;
            instance.current.bulk_in_endpoint_id = in_dci;
            instance.current.bulk_out_endpoint_id = out_dci;
            instance.current.bulk_in_endpoint_address = in_address;
            instance.current.bulk_in_endpoint_max_packet = in_fields.max_packet;
            instance.current.bulk_in_endpoint_max_burst = in_fields.max_burst;
            instance.current.bulk_out_endpoint_address = out_address;
            instance.current.bulk_out_endpoint_max_packet = out_fields.max_packet;
            instance.current.bulk_out_endpoint_max_burst = out_fields.max_burst;
            return true;
        }
        instance.current.bulk_endpoints_faulted = true;
        instance.current.failures += 1;
        return false;
    }

    pub fn configureBulkEndpointHandles(instance: *Instance, in_handle: *EndpointHandle, out_handle: *EndpointHandle) bool {
        if (in_handle.kind != .bulk_in or out_handle.kind != .bulk_out) return false;
        if (!sameDeviceTarget(in_handle.device, out_handle.device)) return false;
        if (!instance.selectDeviceHandle(&in_handle.device)) return false;
        out_handle.device = in_handle.device;
        if (!instance.configureFirstBulkEndpoints(
            in_handle.address,
            in_handle.max_packet,
            in_handle.max_burst,
            out_handle.address,
            out_handle.max_packet,
            out_handle.max_burst,
        )) return false;
        instance.refreshHandleFromCurrent(&in_handle.device);
        out_handle.device = in_handle.device;
        in_handle.endpoint_id = instance.current.bulk_in_endpoint_id;
        in_handle.max_packet = instance.current.bulk_in_endpoint_max_packet;
        in_handle.max_burst = instance.current.bulk_in_endpoint_max_burst;
        out_handle.endpoint_id = instance.current.bulk_out_endpoint_id;
        out_handle.max_packet = instance.current.bulk_out_endpoint_max_packet;
        out_handle.max_burst = instance.current.bulk_out_endpoint_max_burst;
        return true;
    }

    fn setupBulkEpContext(
        instance: *Instance,
        input: [*]u32,
        ctx_dwords: usize,
        dci: u8,
        in_dir: bool,
        ring_dequeue: u64,
        max_packet: u16,
        max_burst: u8,
    ) endpoint_context.BulkFields {
        const ep = endpointContext(input, ctx_dwords, dci);
        const fields = endpoint_context.bulkFields(instance.current.addressed_speed, in_dir, max_packet, max_burst);
        ep[0] = fields.dword0;
        ep[1] = fields.dword1;
        ep[2] = @truncate(ring_dequeue);
        ep[3] = @truncate(ring_dequeue >> 32);
        ep[4] = fields.dword4;
        return fields;
    }

    fn endpointRingBase(instance: *Instance, endpoint_address: u8) ?u64 {
        if (endpoint_address == instance.current.bulk_in_endpoint_address) return instance.current.bulk_in_ring_phys;
        if (endpoint_address == instance.current.bulk_out_endpoint_address) return instance.current.bulk_out_ring_phys;
        if (endpoint_address == instance.current.interrupt_endpoint_address) return instance.current.interrupt_ring_phys;
        return null;
    }

    fn endpointRingDequeue(instance: *Instance, endpoint_address: u8) ?u64 {
        const base = instance.endpointRingBase(endpoint_address) orelse return null;
        if (endpoint_address == instance.current.bulk_in_endpoint_address) {
            return base + @as(u64, instance.current.bulk_in_enqueue) * @sizeOf(Trb) |
                @as(u64, if (instance.current.bulk_in_cycle != 0) 1 else 0);
        } else if (endpoint_address == instance.current.bulk_out_endpoint_address) {
            return base + @as(u64, instance.current.bulk_out_enqueue) * @sizeOf(Trb) |
                @as(u64, if (instance.current.bulk_out_cycle != 0) 1 else 0);
        } else if (endpoint_address == instance.current.interrupt_endpoint_address) {
            return base + @as(u64, instance.current.interrupt_enqueue) * @sizeOf(Trb) |
                @as(u64, if (instance.current.interrupt_cycle != 0) 1 else 0);
        }
        return null;
    }

    fn controlRingDequeue(instance: *Instance) ?u64 {
        if (instance.current.ep0_ring_phys == 0 or instance.first_ep0_ring_virt == 0) return null;
        return instance.current.ep0_ring_phys +
            @as(u64, instance.current.ep0_enqueue) * @sizeOf(Trb) |
            @as(u64, if (instance.current.ep0_cycle != 0) 1 else 0);
    }

    fn endpointState(instance: *Instance, dci: u8) ?endpoint_recovery.EndpointState {
        if (instance.first_device_virt == 0 or dci == 0) return null;
        dmaFence();
        // The output context is DMA-owned by the xHC.  Every recovery-state
        // iteration must perform a real memory read; a normal pointer lets the
        // compiler reuse the value across STOP/RESET command completions.
        const context_address = instance.first_device_virt +
            @as(u64, instance.current.context_size) * @as(u64, dci);
        return endpoint_recovery.stateFromRaw(@truncate(volatileRead32(context_address) & 0x7));
    }

    fn markDciRecoveryFailed(instance: *Instance, dci: u8, fault_class: EndpointFaultClass) void {
        instance.current.failures +%= 1;
        instance.current.reason = "xHCI endpoint recovery failed";
        const incident_token = diag_screen.beginResolvableIncident();
        diag_screen.write("[XHCI] endpoint recovery failed slot=");
        diag_screen.writeDec(instance.current.addressed_slot_id);
        diag_screen.write(" ep=");
        diag_screen.writeDec(dci);
        diag_screen.write(" state=");
        if (instance.endpointState(dci)) |state| {
            diag_screen.writeDec(@intFromEnum(state));
        } else {
            diag_screen.write("unknown");
        }
        diag_screen.write(" cc=");
        diag_screen.writeDec(instance.current.last_completion_code);
        diag_screen.endLine();
        _ = diag_screen.resolveIncident(incident_token);
        switch (fault_class) {
            .control => instance.current.control_endpoint_faulted = true,
            .interrupt => instance.current.interrupt_endpoint_faulted = true,
            .bulk => instance.current.bulk_endpoints_faulted = true,
        }
    }

    fn markEndpointRecoveryFailed(instance: *Instance, endpoint_address: u8) void {
        const dci = endpointDci(endpoint_address);
        const fault_class: EndpointFaultClass =
            if (endpoint_address == instance.current.interrupt_endpoint_address)
                .interrupt
            else
                .bulk;
        instance.markDciRecoveryFailed(dci, fault_class);
    }

    fn endpointRecoveryCommandWithin(
        instance: *Instance,
        control: u32,
        parameter: u64,
        recovery_budget: ?*const usb_wait.Deadline,
    ) ?u8 {
        // A missing command completion must never inherit a successful/stall
        // completion code from an earlier recovery step.
        instance.current.last_completion_code = 0xFF;
        const event = instance.submitCommandWithin(parameter, 0, control, recovery_budget) orelse return null;
        instance.current.last_completion_code = event.code;
        instance.current.last_slot_id = event.slot_id;
        return event.code;
    }

    fn drainUnresolvedTransferDci(instance: *Instance, dci: u8) void {
        const handle = instance.transfer_objects.timedOutHandle(instance.current.addressed_slot_id, dci) orelse return;
        const owner = instance.transfer_objects.matchForHandle(handle) orelse return;
        _ = instance.drainEventBatch(owner);
        _ = instance.deferred_events.purge(owner);
        _ = instance.transfer_objects.cancel(handle);
        _ = instance.transfer_objects.release(handle);
        // USBMSC takes ownership before recovery. Any token still held here was
        // abandoned by a direct xHCI caller and reaches its terminal boundary
        // once the timed-out TD has been purged/skipped.
        instance.closeLastSyncTransferIncident();
    }

    pub fn setFirstConfigurationForHid(instance: *Instance) bool {
        return instance.setFirstConfiguration();
    }

    pub fn setConfigurationForHandle(instance: *Instance, handle: *DeviceHandle) bool {
        if (!instance.selectDeviceHandle(handle)) return false;
        return instance.setFirstConfiguration();
    }

    pub fn setFirstConfiguration(instance: *Instance) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        instance.current.set_configuration_attempted = true;
        instance.current.set_configuration_ok = instance.submitControlNoData(0x00, USB_REQ_SET_CONFIGURATION, instance.current.config_value, 0);
        return instance.current.set_configuration_ok;
    }

    fn recoveryPortReady(instance: *Instance, port: u8) bool {
        if (!instance.current.present or
            !instance.current.controller_running or
            instance.current.mmio_virt == 0 or
            port == 0 or
            port > instance.current.port_count_seen)
            return false;
        const portsc = instance.readOp32(
            OP_PORT_BASE + @as(u64, port - 1) * OP_PORT_STRIDE,
        );
        return (portsc & PORTSC_CCS) != 0 and
            (portsc & PORTSC_PED) != 0 and
            portLinkState(portsc) == PORTSC_PLS_U0;
    }

    fn selectExistingRuntimeForRecovery(
        instance: *Instance,
        handle: *DeviceHandle,
        recovery_budget: ?*const usb_wait.Deadline,
    ) bool {
        if (recovery_budget) |budget| {
            if (budget.expiredAny()) return false;
        }
        const index_value = instance.runtimeIndexForIdentity(handle.slot_id, handle.port) orelse return false;
        if (instance.runtimes[index_value].detach_pending or
            (handle.generation != 0 and instance.runtimes[index_value].generation != handle.generation)) return false;
        if (instance.runtimes[index_value].transaction_active and !transactionOwnedByCurrent(&instance.runtimes[index_value])) return false;
        if (!instance.recoveryPortReady(handle.port)) return false;
        if (recovery_budget) |budget| {
            if (budget.expiredAny()) return false;
        }
        if (!instance.activateRuntime(index_value)) return false;
        if (instance.current.addressed_slot_id != handle.slot_id or
            instance.current.addressed_port != handle.port)
            return false;
        if (recovery_budget) |budget| {
            if (budget.expiredAny()) return false;
        }
        instance.refreshHandleFromCurrent(handle);
        return true;
    }

    pub fn resetMassStorageInterfaceForHandle(instance: *Instance, handle: *DeviceHandle, interface_number: u8) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, null)) return false;
        return instance.resetFirstMassStorageInterface(interface_number);
    }

    pub fn resetMassStorageInterfaceForHandleWithin(
        instance: *Instance,
        handle: *DeviceHandle,
        interface_number: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, recovery_budget)) return false;
        return instance.resetFirstMassStorageInterfaceWithin(interface_number, recovery_budget);
    }

    pub fn resetFirstMassStorageInterface(instance: *Instance, interface_number: u8) bool {
        return instance.submitControlNoData(0x21, MSC_REQ_BULK_ONLY_RESET, 0, interface_number);
    }

    fn resetFirstMassStorageInterfaceWithin(
        instance: *Instance,
        interface_number: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        return instance.submitControlNoDataWithin(0x21, MSC_REQ_BULK_ONLY_RESET, 0, interface_number, recovery_budget);
    }

    pub fn clearEndpointHaltForHandle(instance: *Instance, handle: *DeviceHandle, endpoint_address: u8) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, null)) return false;
        return instance.clearFirstEndpointHalt(endpoint_address);
    }

    pub fn clearEndpointHaltForHandleWithin(
        instance: *Instance,
        handle: *DeviceHandle,
        endpoint_address: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, recovery_budget)) return false;
        return instance.clearFirstEndpointHaltWithin(endpoint_address, recovery_budget);
    }

    pub fn clearFirstEndpointHalt(instance: *Instance, endpoint_address: u8) bool {
        return instance.submitControlNoData(0x02, USB_REQ_CLEAR_FEATURE, USB_FEATURE_ENDPOINT_HALT, endpoint_address);
    }

    fn clearFirstEndpointHaltWithin(
        instance: *Instance,
        endpoint_address: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        return instance.submitControlNoDataWithin(
            0x02,
            USB_REQ_CLEAR_FEATURE,
            USB_FEATURE_ENDPOINT_HALT,
            endpoint_address,
            recovery_budget,
        );
    }

    pub fn reconfigureMassStorageBulkEndpointsForHandleWithin(
        instance: *Instance,
        handle: *DeviceHandle,
        in_endpoint_address: u8,
        out_endpoint_address: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, recovery_budget)) return false;
        if (!instance.reconfigureStoppedBulkEndpointsWithin(
            in_endpoint_address,
            out_endpoint_address,
            recovery_budget,
        )) return false;
        instance.refreshHandleFromCurrent(handle);
        return true;
    }

    fn reconfigureStoppedBulkEndpointsWithin(
        instance: *Instance,
        in_endpoint_address: u8,
        out_endpoint_address: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        // Every early validation/budget/state failure belongs to this Configure
        // attempt; never report a successful completion code left by an earlier
        // Stop Endpoint or Set TR Dequeue Pointer command.
        instance.current.last_completion_code = 0xFF;
        const in_dci = endpointDci(in_endpoint_address);
        const out_dci = endpointDci(out_endpoint_address);
        if (instance.current.addressed_slot_id == 0 or
            instance.first_input_virt == 0 or
            instance.first_device_virt == 0 or
            in_dci == 0 or
            out_dci == 0 or
            in_dci >= 32 or
            out_dci >= 32 or
            (in_endpoint_address & 0x80) == 0 or
            (out_endpoint_address & 0x80) != 0 or
            in_endpoint_address != instance.current.bulk_in_endpoint_address or
            out_endpoint_address != instance.current.bulk_out_endpoint_address)
        {
            return instance.failBulkReconfigure("xHCI BOT bulk identity invalid");
        }
        if (recovery_budget.expiredAny()) {
            return instance.failBulkReconfigure("xHCI BOT bulk reconfigure budget expired");
        }
        const in_state = instance.endpointState(in_dci) orelse
            return instance.failBulkReconfigure("xHCI BOT bulk IN state missing");
        const out_state = instance.endpointState(out_dci) orelse
            return instance.failBulkReconfigure("xHCI BOT bulk OUT state missing");
        if (in_state != .stopped or out_state != .stopped) {
            return instance.failBulkReconfigure("xHCI BOT bulk endpoint not stopped");
        }
        const in_dequeue = instance.endpointRingDequeue(in_endpoint_address) orelse
            return instance.failBulkReconfigure("xHCI BOT bulk IN dequeue missing");
        const out_dequeue = instance.endpointRingDequeue(out_endpoint_address) orelse
            return instance.failBulkReconfigure("xHCI BOT bulk OUT dequeue missing");

        const input: [*]u32 = @ptrFromInt(instance.first_input_virt);
        @memset(input[0 .. INPUT_CONTEXT_BYTES / 4], 0);
        const ctx_dwords = @as(usize, instance.current.context_size) / 4;
        const in_bit = @as(u32, 1) << @as(u5, @intCast(in_dci));
        const out_bit = @as(u32, 1) << @as(u5, @intCast(out_dci));
        // D0/A0 follows the Configure Endpoint Drop+Add rule: Slot is Add-only;
        // EP0 must be absent; both bulk DCIs appear in both masks.
        input[0] = in_bit | out_bit;
        input[1] = 0x1 | in_bit | out_bit;

        dmaFence();
        instance.copyOutputSlotContextToInput(input + ctx_dwords);
        const in_ep = endpointContext(input, ctx_dwords, in_dci);
        const out_ep = endpointContext(input, ctx_dwords, out_dci);
        instance.copyOutputEndpointContextToInput(in_ep, in_dci);
        instance.copyOutputEndpointContextToInput(out_ep, out_dci);
        in_ep[2] = @truncate(in_dequeue);
        in_ep[3] = @truncate(in_dequeue >> 32);
        out_ep[2] = @truncate(out_dequeue);
        out_ep[3] = @truncate(out_dequeue >> 32);

        instance.current.bulk_endpoints_configured = false;
        instance.current.bulk_endpoints_faulted = true;
        const control = trbType(TRB_TYPE_CONFIGURE_ENDPOINT) |
            (@as(u32, instance.current.addressed_slot_id) << 24);
        const completion = instance.submitCommandWithin(
            instance.current.input_context_phys,
            0,
            control,
            recovery_budget,
        ) orelse return instance.failBulkReconfigure("xHCI BOT bulk reconfigure timeout");
        instance.current.last_completion_code = completion.code;
        instance.current.last_slot_id = completion.slot_id;
        if (completion.code != COMPLETION_SUCCESS or
            completion.slot_id != instance.current.addressed_slot_id)
        {
            return instance.failBulkReconfigure("xHCI BOT bulk reconfigure rejected");
        }
        instance.current.bulk_endpoints_configured = true;
        instance.current.bulk_endpoints_faulted = false;
        return true;
    }

    fn copyOutputSlotContextToInput(instance: *Instance, destination: [*]u32) void {
        const source = instance.first_device_virt;
        // Only architected Input Slot Context fields may cross from the xHC-owned
        // Output Context. Device Address, Slot State and every RsvdO byte are
        // output-only; RsvdZ fields must be submitted as zero.
        destination[0] = volatileRead32(source) & ~(@as(u32, 1) << 24);
        destination[1] = volatileRead32(source + 4);
        destination[2] = volatileRead32(source + 8) & ~(@as(u32, 0xF) << 18);
        destination[3] = 0;
    }

    fn copyOutputEndpointContextToInput(instance: *Instance, destination: [*]u32, dci: u8) void {
        const source = instance.first_device_virt +
            @as(u64, instance.current.context_size) * @as(u64, dci);
        // Endpoint State plus DW0[7:3] are not valid Input fields. DW1 bit 0 and
        // bit 6 are RsvdZ. Input storage is already zeroed, so copy only DW0..4
        // and leave the CSZ-dependent RsvdO tail untouched.
        destination[0] = volatileRead32(source) & 0xFFFF_FF00;
        destination[1] = volatileRead32(source + 4) & ~@as(u32, 0x41);
        destination[4] = volatileRead32(source + 16);
    }

    fn failBulkReconfigure(instance: *Instance, reason: []const u8) bool {
        instance.current.failures +%= 1;
        instance.current.reason = reason;
        instance.current.bulk_endpoints_configured = false;
        instance.current.bulk_endpoints_faulted = true;
        const incident_token = diag_screen.beginResolvableIncident();
        diag_screen.write("[XHCI] BOT bulk reconfigure failed slot=");
        diag_screen.writeDec(instance.current.addressed_slot_id);
        diag_screen.write(" in=");
        diag_screen.writeDec(instance.current.bulk_in_endpoint_id);
        diag_screen.write(" out=");
        diag_screen.writeDec(instance.current.bulk_out_endpoint_id);
        diag_screen.write(" cc=");
        diag_screen.writeDec(instance.current.last_completion_code);
        diag_screen.endLine();
        _ = diag_screen.resolveIncident(incident_token);
        return false;
    }

    pub fn resetEndpointStateForHandle(instance: *Instance, handle: *DeviceHandle, endpoint_address: u8) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, null)) return false;
        return instance.resetFirstEndpointState(endpoint_address);
    }

    pub fn resetEndpointStateForHandleWithin(
        instance: *Instance,
        handle: *DeviceHandle,
        endpoint_address: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        if (!instance.selectExistingRuntimeForRecovery(handle, recovery_budget)) return false;
        return instance.resetFirstEndpointStateWithin(endpoint_address, recovery_budget);
    }

    pub fn resetFirstEndpointState(instance: *Instance, endpoint_address: u8) bool {
        return instance.resetFirstEndpointStateWithinOptional(endpoint_address, null);
    }

    fn resetFirstEndpointStateWithin(
        instance: *Instance,
        endpoint_address: u8,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        return instance.resetFirstEndpointStateWithinOptional(endpoint_address, recovery_budget);
    }

    fn resetFirstEndpointStateWithinOptional(
        instance: *Instance,
        endpoint_address: u8,
        recovery_budget: ?*const usb_wait.Deadline,
    ) bool {
        if (instance.current.addressed_slot_id == 0) return false;
        const dci = endpointDci(endpoint_address);
        if (dci == 0 or dci >= 32) return false;
        const dequeue = instance.endpointRingDequeue(endpoint_address) orelse {
            instance.markEndpointRecoveryFailed(endpoint_address);
            return false;
        };
        const fault_class: EndpointFaultClass =
            if (endpoint_address == instance.current.interrupt_endpoint_address)
                .interrupt
            else
                .bulk;
        return instance.recoverEndpointDci(dci, dequeue, fault_class, recovery_budget);
    }

    fn recoverControlEndpoint(instance: *Instance, recovery_budget: ?*const usb_wait.Deadline) bool {
        if (instance.current.addressed_slot_id == 0) return false;
        const dequeue = instance.controlRingDequeue() orelse {
            instance.markDciRecoveryFailed(1, .control);
            return false;
        };
        return instance.recoverEndpointDci(1, dequeue, .control, recovery_budget);
    }

    fn recoverEndpointDci(
        instance: *Instance,
        dci: u8,
        dequeue: u64,
        fault_class: EndpointFaultClass,
        recovery_budget: ?*const usb_wait.Deadline,
    ) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        if (dci == 0 or dci >= 32) return false;
        const ep_field = @as(u32, dci) << 16;
        const slot_field = @as(u32, instance.current.addressed_slot_id) << 24;
        // Endpoint state is asynchronous.  In particular, a Running endpoint
        // may become Halted/Error while STOP_ENDPOINT is being executed; xHCI
        // reports that specified race as Context State Error.  Re-read and
        // continue the bounded state machine instead of invalidating USBMSC.
        var attempt: u8 = 0;
        while (attempt < ENDPOINT_RECOVERY_COMMAND_ATTEMPTS) : (attempt += 1) {
            if (recovery_budget) |budget| {
                if (budget.expiredAny()) break;
            }
            const state = instance.endpointState(dci) orelse break;
            const action = endpoint_recovery.prepareAction(state);
            const control = switch (action) {
                .stop => trbType(TRB_TYPE_STOP_ENDPOINT) | ep_field | slot_field,
                .reset => trbType(TRB_TYPE_RESET_ENDPOINT) | ep_field | slot_field,
                .set_dequeue => trbType(TRB_TYPE_SET_TR_DEQUEUE_POINTER) | ep_field | slot_field,
                .reconfigure => break,
            };
            const parameter: u64 = if (action == .set_dequeue) dequeue else 0;
            const code = instance.endpointRecoveryCommandWithin(control, parameter, recovery_budget) orelse break;
            if (endpoint_recovery.completionNeedsStateRefresh(code)) continue;
            if (code != COMPLETION_SUCCESS) break;
            if (action == .set_dequeue) {
                // Never rewind a live transfer ring.  STOP/RESET first, then
                // skip the failed TD by publishing the current producer+DCS.
                instance.drainUnresolvedTransferDci(dci);
                switch (fault_class) {
                    .control => instance.current.control_endpoint_faulted = false,
                    .interrupt => instance.current.interrupt_endpoint_faulted = false,
                    .bulk => instance.current.bulk_endpoints_faulted = false,
                }
                return true;
            }
            // STOP and RESET publish the new state before their command
            // completion. Re-read it and finish with SET_TR_DEQUEUE_POINTER.
        }
        instance.markDciRecoveryFailed(dci, fault_class);
        return false;
    }

    pub fn setHidBootProtocolForHandle(instance: *Instance, handle: *DeviceHandle, interface_number: u8) bool {
        if (!instance.selectDeviceHandle(handle)) return false;
        return instance.setFirstHidBootProtocol(interface_number);
    }

    pub fn setFirstHidBootProtocol(instance: *Instance, interface_number: u8) bool {
        instance.current.hid_set_protocol_attempted = true;
        instance.current.hid_set_protocol_ok = instance.submitControlNoData(0x21, HID_REQ_SET_PROTOCOL, 0, interface_number);
        return instance.current.hid_set_protocol_ok;
    }

    pub fn setHidIdleForHandle(instance: *Instance, handle: *DeviceHandle, interface_number: u8) bool {
        if (!instance.selectDeviceHandle(handle)) return false;
        return instance.setFirstHidIdle(interface_number);
    }

    pub fn setFirstHidIdle(instance: *Instance, interface_number: u8) bool {
        instance.current.hid_set_idle_attempted = true;
        instance.current.hid_set_idle_ok = instance.submitControlNoData(0x21, HID_REQ_SET_IDLE, 0, interface_number);
        return instance.current.hid_set_idle_ok;
    }

    pub fn getHidReportDescriptorForHandle(instance: *Instance, handle: *DeviceHandle, interface_number: u8, expected_len: u16, out: []u8) ?usize {
        if (!instance.selectDeviceHandle(handle)) return null;
        if (!instance.selectedDeviceAllowsMutation()) return null;
        if (expected_len == 0 or out.len == 0 or instance.first_descriptor_virt == 0) return null;
        var len: u16 = expected_len;
        if (len > DESCRIPTOR_BYTES) len = @intCast(DESCRIPTOR_BYTES);
        if (len > out.len) len = @intCast(out.len);
        const desc: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        @memset(desc[0..len], 0);
        if (!instance.submitControlInTyped(0x81, USB_REQ_GET_DESCRIPTOR, @as(u16, USB_DESC_REPORT) << 8, interface_number, len, instance.current.descriptor_phys)) return null;
        // submitControlWithin rejects impossible residue and a Success event with
        // a non-zero residue, so this subtraction is now proof-carrying.
        const actual_u32 = @as(u32, len) - instance.current.last_control_residue;
        const actual: usize = @intCast(actual_u32);
        var i: usize = 0;
        while (i < actual) : (i += 1) out[i] = desc[i];
        instance.refreshHandleFromCurrent(handle);
        return actual;
    }

    pub fn pollFirstInterruptInReport(instance: *Instance, out: []u8) bool {
        return instance.pollFirstInterruptInReportStatus(out) == .report;
    }

    pub fn pollFirstInterruptInReportStatus(instance: *Instance, out: []u8) InterruptPollResult {
        if (!instance.current.interrupt_endpoint_configured or instance.first_interrupt_ring_virt == 0 or instance.first_interrupt_buffer_virt == 0) return .failed;
        if (out.len == 0 or out.len > INTERRUPT_BUFFER_BYTES) return .failed;
        instance.current.interrupt_polls += 1;
        if (instance.current.interrupt_pending and instance.current.interrupt_pending_trb_phys == 0) {
            instance.releaseInterruptTransfer(true);
            instance.current.interrupt_pending = false;
            instance.current.interrupt_pending_streak = 0;
        }
        if (!instance.current.interrupt_pending) {
            const buf: [*]u8 = @ptrFromInt(instance.first_interrupt_buffer_virt);
            @memset(buf[0..out.len], 0);
            instance.current.last_interrupt_request_len = @intCast(out.len);
            instance.current.last_interrupt_residue = 0;
            instance.current.last_interrupt_actual_len = 0;
            instance.current.last_interrupt_completion_code = 0;
            const submission = instance.writeInterruptTrb(
                instance.current.interrupt_buffer_phys,
                @intCast(out.len),
                trbType(TRB_TYPE_NORMAL) | TRB_IOC,
            );
            instance.current.interrupt_pending_trb_phys = submission.trb_phys;
            const expected = event_router.transferMatch(
                instance.current.addressed_slot_id,
                instance.current.interrupt_endpoint_id,
                submission.trb_phys,
            );
            instance.current.interrupt_transfer_handle = instance.transfer_objects.begin(
                .interrupt_in,
                expected,
                timer.tickCount(),
            ) orelse {
                instance.current.interrupt_pending_trb_phys = 0;
                instance.current.failures += 1;
                return .failed;
            };
            dmaFence();
            instance.current.interrupt_pending = true;
            instance.current.interrupt_pending_streak = 0;
            instance.writeDoorbell(instance.current.addressed_slot_id, instance.current.interrupt_endpoint_id);
            if (submission.advance.wrapped) {
                instance.current.interrupt_ring_wraps += 1;
                instance.emitInterruptWrapMarker(submission.enqueue, submission.producer_cycle, submission.advance);
            }
        }
        const expected = event_router.transferMatch(
            instance.current.addressed_slot_id,
            instance.current.interrupt_endpoint_id,
            instance.current.interrupt_pending_trb_phys,
        );
        const completion = instance.pollInterruptCompletion(expected) orelse {
            instance.current.interrupt_no_report += 1;
            // 0.56.16: Proaktiver Halted-Check (Befund 7.2/7.3). Ein lange
            // pendender Transfer ist bei HID normal (SET_IDLE=0: Report nur
            // bei Aenderung) - ein Fehlerfall liegt erst vor, wenn der EP im
            // Output-Device-Context Halted/Error meldet. Dann Recovery und
            // frisch aufsetzen; ohne Befund bleibt der Transfer stehen.
            instance.current.interrupt_pending_streak +%= 1;
            if ((instance.current.interrupt_pending_streak & PENDING_HALT_CHECK_MASK) == 0) {
                if (instance.interruptEndpointState()) |state| {
                    instance.current.last_interrupt_ep_state = state;
                    if (state == EP_STATE_HALTED or state == EP_STATE_ERROR) {
                        _ = instance.recoverInterruptEndpoint(true);
                    }
                }
            }
            return .no_report;
        };
        if (instance.current.interrupt_transfer_handle != 0) {
            _ = instance.transfer_objects.complete(instance.current.interrupt_transfer_handle, completion);
            _ = instance.transfer_objects.release(instance.current.interrupt_transfer_handle);
            instance.current.interrupt_transfer_handle = 0;
        }
        instance.current.last_transfer_completion_code = completion.code;
        instance.current.last_interrupt_completion_code = completion.code;
        instance.current.last_interrupt_residue = completion.length;
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_pending_streak = 0;
        // Short Packet ist fuer Interrupt-IN kein Endpoint-Fehler. Die Residue
        // beschreibt dabei genau die kuerzere Nutzlaenge des HID-Reports.
        const requested = instance.current.last_interrupt_request_len;
        const completion_ok =
            (completion.code == COMPLETION_SUCCESS and completion.length == 0) or
            (completion.code == COMPLETION_SHORT_PACKET and completion.length <= requested);
        if (!completion_ok) {
            instance.current.last_interrupt_actual_len = 0;
            instance.current.failures += 1;
            // 0.56.16: Fehler-Completion (Stall/Babble/Transaction-Error)
            // haltet den Endpoint. RESET_ENDPOINT + SET_TR_DEQUEUE_POINTER
            // statt dauerhaft .failed - der naechste Poll setzt frisch auf
            // (Maus-tot-Root-Cause vom Produktionspfad).
            _ = instance.recoverInterruptEndpoint(false);
            return .no_report;
        }
        instance.current.last_interrupt_actual_len = requested - completion.length;
        if (instance.current.last_interrupt_actual_len == 0) {
            instance.current.interrupt_no_report += 1;
            return .no_report;
        }
        const buf: [*]u8 = @ptrFromInt(instance.first_interrupt_buffer_virt);
        const copy_len: usize = @min(out.len, @as(usize, @intCast(instance.current.last_interrupt_actual_len)));
        var i: usize = 0;
        while (i < copy_len) : (i += 1) out[i] = buf[i];
        instance.current.interrupt_reports += 1;
        return .report;
    }

    pub fn lastInterruptActualLength(instance: *Instance) usize {
        return @intCast(instance.current.last_interrupt_actual_len);
    }

    pub fn lastInterruptRequestedLength(instance: *Instance) usize {
        return @intCast(instance.current.last_interrupt_request_len);
    }

    pub fn lastInterruptResidue(instance: *Instance) u32 {
        return instance.current.last_interrupt_residue;
    }

    pub fn takeLastSyncTransferIncidentToken(instance: *Instance) diag_screen.IncidentToken {
        const token = instance.last_sync_transfer_incident;
        instance.last_sync_transfer_incident = .{};
        return token;
    }

    fn closeLastSyncTransferIncident(instance: *Instance) void {
        if (instance.last_sync_transfer_incident.valid()) {
            _ = diag_screen.resolveIncident(instance.last_sync_transfer_incident);
            instance.last_sync_transfer_incident = .{};
        }
    }

    pub fn pollInterruptInReport(instance: *Instance, handle: *EndpointHandle, out: []u8) bool {
        return instance.pollInterruptInReportStatus(handle, out) == .report;
    }

    pub fn pollInterruptInReportStatus(instance: *Instance, handle: *EndpointHandle, out: []u8) InterruptPollResult {
        if (handle.kind != .interrupt_in) return .failed;
        if (!instance.selectDeviceHandle(&handle.device)) return .failed;
        if (instance.current.interrupt_endpoint_faulted) return .failed;
        if (!instance.current.interrupt_endpoint_configured or instance.current.interrupt_endpoint_address != handle.address) {
            if (!instance.configureInterruptInEndpointHandle(handle)) return .failed;
        }
        return instance.pollFirstInterruptInReportStatus(out);
    }

    pub fn bulkOut(instance: *Instance, data: []const u8) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        instance.beginBulkRecord(false, data.len);
        if (!instance.current.bulk_endpoints_configured or instance.current.bulk_endpoints_faulted or instance.first_bulk_out_ring_virt == 0 or instance.first_bulk_buffer_virt == 0) {
            instance.current.last_bulk_result = "not-ready";
            return false;
        }
        if (data.len == 0 or data.len > BULK_BUFFER_BYTES) {
            instance.current.last_bulk_result = "bad-length";
            return false;
        }
        if (instance.transfer_objects.timedOutHandle(instance.current.addressed_slot_id, instance.current.bulk_out_endpoint_id) != null) {
            instance.current.last_bulk_result = "recovery-required";
            return false;
        }
        const buf: [*]u8 = @ptrFromInt(instance.first_bulk_buffer_virt);
        @memcpy(buf[0..data.len], data);
        const submission = instance.writeBulkTrbChain(false, instance.current.bulk_buffer_phys, @intCast(data.len)) orelse {
            instance.current.last_bulk_result = "chain-failed";
            return false;
        };
        const expected = event_router.transferTdMatch(instance.current.addressed_slot_id, instance.current.bulk_out_endpoint_id, submission.trb_phys, submission.trb_count);
        const transfer_handle = instance.transfer_objects.begin(.bulk_out, expected, timer.tickCount()) orelse {
            instance.current.last_bulk_result = "transfer-table-full";
            return false;
        };
        var retain_transfer = false;
        defer {
            if (!retain_transfer) _ = instance.transfer_objects.release(transfer_handle);
        }
        dmaFence();
        instance.current.bulk_transfers += 1;
        instance.writeDoorbell(instance.current.addressed_slot_id, instance.current.bulk_out_endpoint_id);
        const completion = instance.waitTransferCompletion(expected) orelse {
            _ = instance.transfer_objects.markTimeout(transfer_handle);
            retain_transfer = true;
            instance.current.bulk_failures += 1;
            instance.current.last_bulk_result = if (instance.current.last_wait_cancelled) "device-detached" else "timeout";
            return false;
        };
        _ = instance.transfer_objects.complete(transfer_handle, completion);
        instance.current.last_transfer_completion_code = completion.code;
        instance.recordBulkCompletion(false, @intCast(data.len), completion);
        const evaluated = bulk_completion.evaluate(false, @intCast(data.len), completion.code, completion.length);
        if (!evaluated.accepted) {
            instance.current.bulk_failures += 1;
            return false;
        }
        return true;
    }

    pub fn bulkOutForHandle(instance: *Instance, handle: *EndpointHandle, data: []const u8) bool {
        if (handle.kind != .bulk_out) return false;
        if (!instance.selectDeviceHandle(&handle.device)) return false;
        if (!instance.current.bulk_endpoints_configured or instance.current.bulk_out_endpoint_address != handle.address) return false;
        return instance.bulkOut(data);
    }

    pub fn bulkIn(instance: *Instance, out: []u8) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        instance.beginBulkRecord(true, out.len);
        if (!instance.current.bulk_endpoints_configured or instance.current.bulk_endpoints_faulted or instance.first_bulk_in_ring_virt == 0 or instance.first_bulk_buffer_virt == 0) {
            instance.current.last_bulk_result = "not-ready";
            return false;
        }
        if (out.len == 0 or out.len > BULK_BUFFER_BYTES) {
            instance.current.last_bulk_result = "bad-length";
            return false;
        }
        if (instance.transfer_objects.timedOutHandle(instance.current.addressed_slot_id, instance.current.bulk_in_endpoint_id) != null) {
            instance.current.last_bulk_result = "recovery-required";
            return false;
        }
        const buf: [*]u8 = @ptrFromInt(instance.first_bulk_buffer_virt);
        @memset(buf[0..out.len], 0);
        const submission = instance.writeBulkTrbChain(true, instance.current.bulk_buffer_phys, @intCast(out.len)) orelse {
            instance.current.last_bulk_result = "chain-failed";
            return false;
        };
        const expected = event_router.transferTdMatch(instance.current.addressed_slot_id, instance.current.bulk_in_endpoint_id, submission.trb_phys, submission.trb_count);
        const transfer_handle = instance.transfer_objects.begin(.bulk_in, expected, timer.tickCount()) orelse {
            instance.current.last_bulk_result = "transfer-table-full";
            return false;
        };
        var retain_transfer = false;
        defer {
            if (!retain_transfer) _ = instance.transfer_objects.release(transfer_handle);
        }
        dmaFence();
        instance.current.bulk_transfers += 1;
        instance.writeDoorbell(instance.current.addressed_slot_id, instance.current.bulk_in_endpoint_id);
        const completion = instance.waitTransferCompletion(expected) orelse {
            _ = instance.transfer_objects.markTimeout(transfer_handle);
            retain_transfer = true;
            instance.current.bulk_failures += 1;
            instance.current.last_bulk_result = if (instance.current.last_wait_cancelled) "device-detached" else "timeout";
            return false;
        };
        _ = instance.transfer_objects.complete(transfer_handle, completion);
        instance.current.last_transfer_completion_code = completion.code;
        instance.recordBulkCompletion(true, @intCast(out.len), completion);
        const evaluated = bulk_completion.evaluate(true, @intCast(out.len), completion.code, completion.length);
        if (!evaluated.accepted) {
            instance.current.bulk_failures += 1;
            return false;
        }
        const actual: usize = @intCast(evaluated.actual_len);
        var i: usize = 0;
        while (i < actual) : (i += 1) out[i] = buf[i];
        return true;
    }

    pub fn bulkInForHandle(instance: *Instance, handle: *EndpointHandle, out: []u8) bool {
        if (handle.kind != .bulk_in) return false;
        if (!instance.selectDeviceHandle(&handle.device)) return false;
        if (!instance.current.bulk_endpoints_configured or instance.current.bulk_in_endpoint_address != handle.address) return false;
        return instance.bulkIn(out);
    }

    fn pollInterruptCompletion(instance: *Instance, expected: event_router.Match) ?XhciEvent {
        return instance.pollMatchingEvent(expected);
    }

    fn writeBulkTrbChain(instance: *Instance, in_dir: bool, parameter: u64, bytes: u32) ?BulkSubmission {
        const plan = trb_chain.build(parameter, bytes) orelse return null;
        var out: BulkSubmission = .{};
        const segment_count: usize = plan.count;
        var index: usize = 0;
        while (index < segment_count) : (index += 1) {
            const segment = plan.segments[index];
            const remaining_trbs: u32 = @intCast(segment_count - index - 1);
            const status_value = segment.len | (@as(u32, @intCast(@min(remaining_trbs, 31))) << 17);
            const last = index + 1 == segment_count;
            const control = trbType(TRB_TYPE_NORMAL) | if (last) TRB_IOC else TRB_CHAIN;
            const submission = instance.writeBulkTrb(in_dir, segment.phys, status_value, control);
            out.trb_phys[out.trb_count] = submission.trb_phys;
            out.trb_count += 1;
        }
        return out;
    }

    fn writeBulkTrb(instance: *Instance, in_dir: bool, parameter: u64, status_value: u32, control_extra: u32) BulkTrbSubmission {
        const ring: [*]Trb = @ptrFromInt(if (in_dir) instance.first_bulk_in_ring_virt else instance.first_bulk_out_ring_virt);
        const enqueue = if (in_dir) instance.current.bulk_in_enqueue else instance.current.bulk_out_enqueue;
        const ring_phys = if (in_dir) instance.current.bulk_in_ring_phys else instance.current.bulk_out_ring_phys;
        const trb_phys = ring_phys + @as(u64, enqueue) * @sizeOf(Trb);
        const cycle = if ((if (in_dir) instance.current.bulk_in_cycle else instance.current.bulk_out_cycle) != 0) TRB_CYCLE else 0;
        ring[enqueue] = .{ .parameter = parameter, .status = status_value, .control = control_extra | cycle };
        const producer_cycle = if (in_dir) instance.current.bulk_in_cycle else instance.current.bulk_out_cycle;
        const advance = ring_cycle.afterSubmission(enqueue, producer_cycle, TRANSFER_TRB_COUNT);
        if (advance.wrapped) {
            updateLinkTrb(
                if (in_dir) instance.first_bulk_in_ring_virt else instance.first_bulk_out_ring_virt,
                TRANSFER_TRB_COUNT,
                advance.link_cycle,
                (control_extra & TRB_CHAIN) != 0,
            );
        }
        if (in_dir) {
            instance.current.bulk_in_enqueue = advance.next_enqueue;
            instance.current.bulk_in_cycle = advance.next_producer_cycle;
            instance.current.bulk_in_link_update_pending = false;
            if (advance.wrapped) {
                instance.current.bulk_in_ring_wraps += 1;
            }
        } else {
            instance.current.bulk_out_enqueue = advance.next_enqueue;
            instance.current.bulk_out_cycle = advance.next_producer_cycle;
            instance.current.bulk_out_link_update_pending = false;
            if (advance.wrapped) {
                instance.current.bulk_out_ring_wraps += 1;
            }
        }
        return .{ .trb_phys = trb_phys };
    }

    fn beginBulkRecord(instance: *Instance, in_dir: bool, requested: usize) void {
        // A caller must take a timeout token before starting another transfer.
        // If it did not, the previous operation has reached a terminal boundary;
        // close its generation instead of silently discarding the only owner.
        instance.closeLastSyncTransferIncident();
        instance.current.last_bulk_direction = if (in_dir) "in" else "out";
        instance.current.last_bulk_result = "submitted";
        instance.current.last_bulk_request_len = @intCast(@min(requested, @as(usize, 0xFFFF_FFFF)));
        instance.current.last_bulk_residue = 0;
        instance.current.last_bulk_actual_len = 0;
        instance.current.last_bulk_completion_code = 0;
    }

    fn recordBulkCompletion(instance: *Instance, in_dir: bool, requested: u32, completion: XhciEvent) void {
        instance.current.last_bulk_completion_code = completion.code;
        instance.current.last_bulk_residue = completion.length;
        const evaluated = bulk_completion.evaluate(in_dir, requested, completion.code, completion.length);
        instance.current.last_bulk_actual_len = evaluated.actual_len;
        instance.current.last_bulk_result = if (evaluated.accepted)
            (if (completion.code == COMPLETION_SHORT_PACKET) "short" else "ok")
        else if (completion.length > requested or
            (completion.code == COMPLETION_SUCCESS and completion.length != 0))
            "bad-residue"
        else
            "completion-error";
    }

    fn recordControlRequest(instance: *Instance, req: *const ControlRequest) void {
        instance.current.last_control_request_type = req.request_type;
        instance.current.last_control_request = req.request;
        instance.current.last_control_value = req.value;
        instance.current.last_control_index = req.index_value;
        instance.current.last_control_length = req.length;
        instance.current.last_control_direction = controlDirectionName(req.direction);
        instance.current.last_control_completion_code = 0;
        instance.current.last_control_residue = 0;
        instance.current.last_control_ok = false;
    }

    fn submitControl(instance: *Instance, req: ControlRequest) bool {
        return instance.submitControlWithin(req, null);
    }

    fn submitControlWithin(
        instance: *Instance,
        req: ControlRequest,
        recovery_budget: ?*const usb_wait.Deadline,
    ) bool {
        if (!instance.selectedDeviceAllowsMutation()) return false;
        // Starting another synchronous transfer abandons an unclaimed earlier
        // timeout token. USBMSC takes its token before entering BOT recovery.
        instance.closeLastSyncTransferIncident();
        if (instance.current.addressed_slot_id == 0 or instance.first_ep0_ring_virt == 0) return false;
        if (instance.current.control_endpoint_faulted) return false;
        if (req.direction != .none and (req.length == 0 or req.data_phys == 0)) return false;
        if (instance.transfer_objects.timedOutHandle(instance.current.addressed_slot_id, 1) != null) return false;
        if (recovery_budget) |budget| {
            if (budget.expiredAny()) return false;
        }
        instance.recordControlRequest(&req);

        const setup_transfer_type: u32 = switch (req.direction) {
            .none => 0,
            .in => SETUP_TRT_IN_DATA,
            .out => SETUP_TRT_OUT_DATA,
        };
        const setup = (@as(u64, req.request_type)) |
            (@as(u64, req.request) << 8) |
            (@as(u64, req.value) << 16) |
            (@as(u64, req.index_value) << 32) |
            (@as(u64, req.length) << 48);
        var control_trb_phys: [event_router.MAX_TRANSFER_TRB_POINTERS]u64 = .{0} ** event_router.MAX_TRANSFER_TRB_POINTERS;
        var control_trb_count: u8 = 0;
        control_trb_phys[control_trb_count] = instance.writeTransferTrb(setup, 8, trbType(TRB_TYPE_SETUP_STAGE) | TRB_IDT | setup_transfer_type);
        control_trb_count += 1;

        if (req.direction != .none) {
            const data_control = trbType(TRB_TYPE_DATA_STAGE) | if (req.direction == .in) DATA_STAGE_DIR_IN else 0;
            control_trb_phys[control_trb_count] = instance.writeTransferTrb(req.data_phys, req.length, data_control);
            control_trb_count += 1;
        }

        const status_direction = req.direction != .in;
        const status_control = trbType(TRB_TYPE_STATUS_STAGE) | TRB_IOC | if (status_direction) STATUS_STAGE_DIR_IN else 0;
        control_trb_phys[control_trb_count] = instance.writeTransferTrb(0, 0, status_control);
        control_trb_count += 1;
        const expected = event_router.transferTdMatch(instance.current.addressed_slot_id, 1, control_trb_phys, control_trb_count);
        const transfer_handle = instance.transfer_objects.begin(.control, expected, timer.tickCount()) orelse return false;
        var retain_transfer = false;
        defer {
            if (!retain_transfer) _ = instance.transfer_objects.release(transfer_handle);
        }
        dmaFence();
        instance.current.control_transfers += 1;
        instance.writeDoorbell(instance.current.addressed_slot_id, 1);
        const completion = instance.waitTransferCompletionWithin(expected, recovery_budget) orelse {
            _ = instance.transfer_objects.markTimeout(transfer_handle);
            retain_transfer = true;
            instance.current.last_control_completion_code = 0xFF;
            if (!instance.current.last_wait_cancelled) instance.current.control_timeouts += 1;
            instance.current.control_failures += 1;
            if (!instance.current.last_wait_cancelled) _ = instance.recoverControlEndpoint(recovery_budget);
            // EP0 has no protocol-layer timeout owner. The recovery diagnostics
            // have already joined this generation, so retain their evidence and
            // close it at the control-operation boundary.
            instance.closeLastSyncTransferIncident();
            return false;
        };
        _ = instance.transfer_objects.complete(transfer_handle, completion);
        instance.current.last_transfer_completion_code = completion.code;
        instance.current.last_control_completion_code = completion.code;
        instance.current.last_control_residue = completion.length;
        const residue_valid = completion.length <= req.length;
        instance.current.last_control_ok =
            (completion.code == COMPLETION_SUCCESS and completion.length == 0) or
            (req.direction == .in and
                completion.code == COMPLETION_SHORT_PACKET and
                residue_valid);
        if (instance.current.last_control_ok) {
            if (req.length != 0 and completion.length != 0) instance.current.control_short_packets += 1;
            return true;
        }

        instance.current.control_failures += 1;
        if (completion.code == COMPLETION_STALL_ERROR) instance.current.control_stalls += 1;
        instance.current.reason = "xHCI control transfer failed";
        _ = instance.recoverControlEndpoint(recovery_budget);
        return false;
    }

    fn submitControlNoData(instance: *Instance, request_type: u8, request: u8, value: u16, index_value: u16) bool {
        return instance.submitControlNoDataWithinOptional(request_type, request, value, index_value, null);
    }

    fn submitControlNoDataWithin(
        instance: *Instance,
        request_type: u8,
        request: u8,
        value: u16,
        index_value: u16,
        recovery_budget: *const usb_wait.Deadline,
    ) bool {
        return instance.submitControlNoDataWithinOptional(
            request_type,
            request,
            value,
            index_value,
            recovery_budget,
        );
    }

    fn submitControlNoDataWithinOptional(
        instance: *Instance,
        request_type: u8,
        request: u8,
        value: u16,
        index_value: u16,
        recovery_budget: ?*const usb_wait.Deadline,
    ) bool {
        return instance.submitControlWithin(.{
            .request_type = request_type,
            .request = request,
            .value = value,
            .index_value = index_value,
            .direction = .none,
        }, recovery_budget);
    }

    fn interruptEndpointState(instance: *Instance) ?u8 {
        if (instance.current.interrupt_endpoint_id == 0) return null;
        instance.current.interrupt_halted_checks +%= 1;
        const state = instance.endpointState(instance.current.interrupt_endpoint_id) orelse return null;
        return @intFromEnum(state);
    }

    fn readInterruptHardwareDequeue(instance: *Instance) u64 {
        if (instance.first_device_virt == 0 or instance.current.interrupt_endpoint_id == 0) return 0;
        const context_bytes = @as(u64, instance.current.context_size) * @as(u64, instance.current.interrupt_endpoint_id);
        const endpoint = instance.first_device_virt + context_bytes;
        const low = volatileRead32(endpoint + 8);
        const high = volatileRead32(endpoint + 12);
        return (@as(u64, high) << 32) | low;
    }

    fn recoverInterruptEndpoint(instance: *Instance, from_pending: bool) bool {
        const slot = instance.current.addressed_slot_id;
        const ep_id = instance.current.interrupt_endpoint_id;
        if (slot == 0 or ep_id == 0) return false;
        const pending_owner = instance.currentInterruptOwnerMatch();
        if (pending_owner) |owner| _ = instance.deferred_events.purge(owner);
        instance.releaseInterruptTransfer(true);
        instance.current.interrupt_recoveries +%= 1;
        if (from_pending) instance.current.interrupt_pending_timeouts +%= 1;
        const ok = instance.resetFirstEndpointState(instance.current.interrupt_endpoint_address);
        if (pending_owner) |owner| _ = instance.deferred_events.purge(owner);
        instance.current.interrupt_pending = false;
        instance.current.interrupt_pending_trb_phys = 0;
        instance.current.interrupt_pending_streak = 0;
        dmaFence();
        return ok;
    }

    fn releaseInterruptTransfer(instance: *Instance, cancel: bool) void {
        if (instance.current.interrupt_transfer_handle == 0) return;
        if (cancel) _ = instance.transfer_objects.cancel(instance.current.interrupt_transfer_handle);
        _ = instance.transfer_objects.release(instance.current.interrupt_transfer_handle);
        instance.current.interrupt_transfer_handle = 0;
    }

    fn writeInterruptTrb(instance: *Instance, parameter: u64, status_value: u32, control_extra: u32) InterruptSubmission {
        const ring: [*]Trb = @ptrFromInt(instance.first_interrupt_ring_virt);
        const enqueue = instance.current.interrupt_enqueue;
        const trb_phys = instance.current.interrupt_ring_phys + @as(u64, enqueue) * @sizeOf(Trb);
        const producer_cycle = instance.current.interrupt_cycle;
        const cycle = if (producer_cycle != 0) TRB_CYCLE else 0;
        ring[enqueue] = .{ .parameter = parameter, .status = status_value, .control = control_extra | cycle };
        const advance = ring_cycle.afterSubmission(enqueue, producer_cycle, TRANSFER_TRB_COUNT);
        if (advance.wrapped) {
            // Der Link gehoert noch zum alten Umlauf: erst mit dem alten PCS an
            // den xHC uebergeben, dann lokal auf das PCS des neuen Umlaufs gehen.
            updateLinkTrb(instance.first_interrupt_ring_virt, TRANSFER_TRB_COUNT, advance.link_cycle, false);
        }
        instance.current.interrupt_enqueue = advance.next_enqueue;
        instance.current.interrupt_cycle = advance.next_producer_cycle;
        return .{
            .trb_phys = trb_phys,
            .enqueue = enqueue,
            .producer_cycle = producer_cycle,
            .advance = advance,
        };
    }

    fn emitInterruptWrapMarker(instance: *Instance, enqueue: u16, producer_cycle: u8, advance: ring_cycle.Advance) void {
        const deferred = instance.deferred_events.snapshot();
        k.puts("[USBHIDWRAP] wraps=");
        k.putDec(instance.current.interrupt_ring_wraps);
        k.puts(" submitted_enqueue=");
        k.putDec(enqueue);
        k.puts(" enqueue=");
        k.putDec(instance.current.interrupt_enqueue);
        k.puts(" next_enqueue=");
        k.putDec(advance.next_enqueue);
        k.puts(" submitted_pcs=");
        k.putDec(producer_cycle);
        k.puts(" pcs=");
        k.putDec(instance.current.interrupt_cycle);
        k.puts(" next_producer_cycle=");
        k.putDec(advance.next_producer_cycle);
        k.puts(" link_c=");
        k.putDec(advance.link_cycle);
        k.puts(" reports=");
        k.putDec(instance.current.interrupt_reports);
        k.puts(" recoveries=");
        k.putDec(instance.current.interrupt_recoveries);
        k.puts(" pending_timeouts=");
        k.putDec(instance.current.interrupt_pending_timeouts);
        k.puts(" deferred_overflows=");
        k.putDec(deferred.overflows);
        k.puts(" event_wraps=");
        k.putDec(instance.current.event_ring_wraps);
        k.puts(" event_commits=");
        k.putDec(instance.current.event_erdp_commits);
        k.puts(" ring_full=");
        k.putDec(instance.current.ring_full);
        k.puts(" stale_events=");
        k.putDec(instance.current.stale_events);
        k.puts("\r\n");
    }

    fn submitControlIn(instance: *Instance, request: u8, value: u16, index_value: u16, length: u16, data_phys: u64) bool {
        return instance.submitControlInTyped(0x80, request, value, index_value, length, data_phys);
    }

    fn submitControlInTyped(instance: *Instance, request_type: u8, request: u8, value: u16, index_value: u16, length: u16, data_phys: u64) bool {
        return instance.submitControl(.{
            .request_type = request_type,
            .request = request,
            .value = value,
            .index_value = index_value,
            .length = length,
            .data_phys = data_phys,
            .direction = .in,
        });
    }

    fn writeTransferTrb(instance: *Instance, parameter: u64, status_value: u32, control_extra: u32) u64 {
        const ring: [*]Trb = @ptrFromInt(instance.first_ep0_ring_virt);
        const enqueue = instance.current.ep0_enqueue;
        const trb_phys = instance.current.ep0_ring_phys + @as(u64, enqueue) * @sizeOf(Trb);
        const cycle = if (instance.current.ep0_cycle != 0) TRB_CYCLE else 0;
        ring[enqueue] = .{ .parameter = parameter, .status = status_value, .control = control_extra | cycle };
        const advance = ring_cycle.afterSubmission(enqueue, instance.current.ep0_cycle, TRANSFER_TRB_COUNT);
        if (advance.wrapped) {
            updateLinkTrb(instance.first_ep0_ring_virt, TRANSFER_TRB_COUNT, advance.link_cycle, (control_extra & TRB_CHAIN) != 0);
            instance.current.ep0_ring_wraps += 1;
        }
        instance.current.ep0_enqueue = advance.next_enqueue;
        instance.current.ep0_cycle = advance.next_producer_cycle;
        return trb_phys;
    }

    fn waitTransferCompletion(instance: *Instance, expected: event_router.Match) ?XhciEvent {
        return instance.waitTransferCompletionWithin(expected, null);
    }

    fn waitTransferCompletionWithin(
        instance: *Instance,
        expected: event_router.Match,
        recovery_budget: ?*const usb_wait.Deadline,
    ) ?XhciEvent {
        if (instance.waitMatchingEventWithin(expected, recovery_budget)) |event| return event;
        if (!instance.current.last_wait_cancelled) instance.current.timeouts += 1;
        instance.current.reason = if (instance.current.last_wait_cancelled) "USB device detached during transfer" else "timeout waiting for xHCI transfer event";
        return null;
    }

    fn parseDeviceDescriptor(instance: *Instance) void {
        const d: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        instance.current.descriptor_len = d[0];
        instance.current.descriptor_type = d[1];
        instance.current.usb_version_bcd = readLe16(d, 2);
        instance.current.device_class = d[4];
        instance.current.device_subclass = d[5];
        instance.current.device_protocol = d[6];
        instance.current.device_max_packet0 = d[7];
        instance.current.device_vendor_id = readLe16(d, 8);
        instance.current.device_product_id = readLe16(d, 10);
        instance.current.device_version_bcd = readLe16(d, 12);
        instance.current.manufacturer_index = d[14];
        instance.current.product_index = d[15];
        instance.current.serial_index = d[16];
    }

    fn recordEndpointForCandidate(instance: *Instance, candidate: *DescriptorInterface, address: u8, attributes: u8, max_packet: u16, interval: u8) void {
        if (!candidate.valid) {
            bumpDescriptorCounter(&instance.current.descriptor_malformed);
            return;
        }
        bumpDescriptorCounter(&candidate.endpoint_count);
        candidate.last_endpoint_address = address;
        if (candidate.first_endpoint_address == 0) {
            candidate.first_endpoint_address = address;
            candidate.first_endpoint_attributes = attributes;
            candidate.first_endpoint_max_packet = max_packet;
            candidate.first_endpoint_interval = interval;
        }

        const transfer_type = attributes & 0x03;
        if (transfer_type == 0x03 and (address & 0x80) != 0 and candidate.interrupt_in_endpoint_address == 0) {
            candidate.interrupt_in_endpoint_address = address;
            candidate.interrupt_in_endpoint_max_packet = max_packet;
            candidate.interrupt_in_endpoint_interval = interval;
        } else if (transfer_type == 0x02) {
            if ((address & 0x80) != 0 and candidate.bulk_in_endpoint_address == 0) {
                candidate.bulk_in_endpoint_address = address;
                candidate.bulk_in_endpoint_max_packet = max_packet;
            } else if ((address & 0x80) == 0 and candidate.bulk_out_endpoint_address == 0) {
                candidate.bulk_out_endpoint_address = address;
                candidate.bulk_out_endpoint_max_packet = max_packet;
            }
        }
    }

    fn recordSsEndpointCompanionForCandidate(instance: *Instance, candidate: *DescriptorInterface, descriptor: [*]const u8, len: u8) void {
        if (!candidate.valid or len < 6 or candidate.last_endpoint_address == 0) {
            bumpDescriptorCounter(&instance.current.descriptor_malformed);
            candidate.last_endpoint_address = 0;
            return;
        }

        const max_burst = descriptor[2];
        if (max_burst > 15) {
            bumpDescriptorCounter(&instance.current.descriptor_malformed);
            candidate.last_endpoint_address = 0;
            return;
        }

        const address = candidate.last_endpoint_address;
        if (address == candidate.bulk_in_endpoint_address) {
            candidate.bulk_in_endpoint_max_burst = max_burst;
        } else if (address == candidate.bulk_out_endpoint_address) {
            candidate.bulk_out_endpoint_max_burst = max_burst;
        }
        candidate.last_endpoint_address = 0;
    }

    fn recordHidDescriptorForCandidate(instance: *Instance, candidate: *DescriptorInterface, descriptor: [*]const u8, len: u8) void {
        if (!candidate.valid) {
            bumpDescriptorCounter(&instance.current.descriptor_malformed);
            return;
        }
        candidate.hid_descriptor_len = len;
        if (len < 9) {
            bumpDescriptorCounter(&instance.current.descriptor_malformed);
            return;
        }
        const descriptor_count = descriptor[5];
        var offset: usize = 6;
        var seen: u8 = 0;
        while (seen < descriptor_count and offset + 3 <= len) : (seen += 1) {
            const kind = descriptor[offset];
            const desc_len = readLe16(descriptor, offset + 1);
            if (kind == USB_DESC_REPORT and candidate.hid_report_descriptor_len == 0) {
                candidate.hid_report_descriptor_len = desc_len;
            }
            offset += 3;
        }
    }

    fn publishSelectedDescriptorInterface(instance: *Instance, selected: *const DescriptorInterface) void {
        instance.current.selected_interface_reason = descriptorCandidateReason(selected);
        instance.current.first_interface_number = selected.number;
        instance.current.first_interface_class = selected.class_code;
        instance.current.first_interface_subclass = selected.subclass;
        instance.current.first_interface_protocol = selected.protocol;
        instance.current.first_endpoint_address = selected.first_endpoint_address;
        instance.current.first_endpoint_attributes = selected.first_endpoint_attributes;
        instance.current.first_endpoint_max_packet = selected.first_endpoint_max_packet;
        instance.current.first_endpoint_interval = selected.first_endpoint_interval;
        instance.current.first_hid_descriptor_len = selected.hid_descriptor_len;
        instance.current.first_hid_report_descriptor_len = selected.hid_report_descriptor_len;
        if (isBootHidCandidate(selected)) {
            instance.current.first_endpoint_address = selected.interrupt_in_endpoint_address;
            instance.current.first_endpoint_attributes = 0x03;
            instance.current.first_endpoint_max_packet = selected.interrupt_in_endpoint_max_packet;
            instance.current.first_endpoint_interval = selected.interrupt_in_endpoint_interval;
        }
        if (isMassStorageCandidate(selected)) {
            instance.current.bulk_in_endpoint_address = selected.bulk_in_endpoint_address;
            instance.current.bulk_in_endpoint_max_packet = selected.bulk_in_endpoint_max_packet;
            instance.current.bulk_in_endpoint_max_burst = selected.bulk_in_endpoint_max_burst;
            instance.current.bulk_out_endpoint_address = selected.bulk_out_endpoint_address;
            instance.current.bulk_out_endpoint_max_packet = selected.bulk_out_endpoint_max_packet;
            instance.current.bulk_out_endpoint_max_burst = selected.bulk_out_endpoint_max_burst;
        }
    }

    fn parseConfigDescriptor(instance: *Instance, total: u16) void {
        const d: [*]u8 = @ptrFromInt(instance.first_descriptor_virt);
        instance.current.config_total_length = readLe16(d, 2);
        instance.current.interface_count = d[4];
        instance.current.interface_record_count = 0;
        instance.current.interface_records = .{usb_core.Interface{}} ** MAX_USB_INTERFACES;
        instance.current.config_value = d[5];
        instance.current.config_attributes = d[7];
        instance.current.config_max_power_ma = @as(u16, d[8]) * 2;
        instance.current.endpoint_count = 0;
        instance.current.descriptor_records = 0;
        instance.current.descriptor_unknown = 0;
        instance.current.descriptor_malformed = 0;
        instance.current.hid_descriptor_count = 0;
        instance.current.ss_endpoint_companion_count = 0;
        instance.current.selected_interface_reason = "none";
        instance.current.first_interface_number = 0;
        instance.current.first_interface_class = 0;
        instance.current.first_interface_subclass = 0;
        instance.current.first_interface_protocol = 0;
        instance.current.first_endpoint_address = 0;
        instance.current.first_endpoint_attributes = 0;
        instance.current.first_endpoint_max_packet = 0;
        instance.current.first_endpoint_interval = 0;
        instance.current.first_hid_descriptor_len = 0;
        instance.current.first_hid_report_descriptor_len = 0;
        instance.current.bulk_in_endpoint_address = 0;
        instance.current.bulk_in_endpoint_max_packet = 0;
        instance.current.bulk_in_endpoint_max_burst = 0;
        instance.current.bulk_out_endpoint_address = 0;
        instance.current.bulk_out_endpoint_max_packet = 0;
        instance.current.bulk_out_endpoint_max_burst = 0;

        var offset: usize = CONFIG_DESCRIPTOR_HEADER_LEN;
        const limit: usize = total;
        var active: DescriptorInterface = .{};
        var selected: DescriptorInterface = .{};
        while (offset + 2 <= limit) {
            const len = d[offset];
            const dtype = d[offset + 1];
            if (len < 2 or offset + len > limit) {
                bumpDescriptorCounter(&instance.current.descriptor_malformed);
                break;
            }
            bumpDescriptorCounter(&instance.current.descriptor_records);
            if (dtype != USB_DESC_ENDPOINT and dtype != USB_DESC_SS_ENDPOINT_COMPANION) {
                active.last_endpoint_address = 0;
            }

            if (dtype == USB_DESC_INTERFACE) {
                if (len >= 9) {
                    selectDescriptorCandidate(&active, &selected);
                    instance.recordDescriptorInterface(&active);
                    active = .{
                        .valid = true,
                        .number = d[offset + 2],
                        .class_code = d[offset + 5],
                        .subclass = d[offset + 6],
                        .protocol = d[offset + 7],
                    };
                } else {
                    bumpDescriptorCounter(&instance.current.descriptor_malformed);
                }
            } else if (dtype == USB_DESC_ENDPOINT) {
                if (len < 7) {
                    bumpDescriptorCounter(&instance.current.descriptor_malformed);
                    offset += len;
                    continue;
                }
                bumpDescriptorCounter(&instance.current.endpoint_count);
                const address = d[offset + 2];
                const attributes = d[offset + 3];
                const max_packet = readLe16(d, offset + 4);
                instance.recordEndpointForCandidate(&active, address, attributes, max_packet, d[offset + 6]);
            } else if (dtype == USB_DESC_HID) {
                bumpDescriptorCounter(&instance.current.hid_descriptor_count);
                instance.recordHidDescriptorForCandidate(&active, d + offset, len);
            } else if (dtype == USB_DESC_SS_ENDPOINT_COMPANION) {
                bumpDescriptorCounter(&instance.current.ss_endpoint_companion_count);
                instance.recordSsEndpointCompanionForCandidate(&active, d + offset, len);
            } else if (dtype != USB_DESC_CONFIGURATION and dtype != USB_DESC_STRING and dtype != USB_DESC_DEVICE) {
                bumpDescriptorCounter(&instance.current.descriptor_unknown);
            }
            offset += len;
        }
        selectDescriptorCandidate(&active, &selected);
        instance.recordDescriptorInterface(&active);
        instance.publishSelectedDescriptorInterface(&selected);
    }

    fn recordDescriptorInterface(instance: *Instance, candidate: *const DescriptorInterface) void {
        if (!candidate.valid) return;
        if (instance.current.interface_record_count >= MAX_USB_INTERFACES) {
            bumpDescriptorCounter(&instance.current.descriptor_malformed);
            return;
        }
        const index: usize = @intCast(instance.current.interface_record_count);
        instance.current.interface_records[index] = .{
            .active = true,
            .number = candidate.number,
            .class_code = candidate.class_code,
            .subclass = candidate.subclass,
            .protocol = candidate.protocol,
            .endpoint_count = candidate.endpoint_count,
            .first_endpoint_address = candidate.first_endpoint_address,
            .first_endpoint_attributes = candidate.first_endpoint_attributes,
            .first_endpoint_max_packet = candidate.first_endpoint_max_packet,
            .first_endpoint_interval = candidate.first_endpoint_interval,
            .hid_descriptor_len = candidate.hid_descriptor_len,
            .hid_report_descriptor_len = candidate.hid_report_descriptor_len,
            .interrupt_in_endpoint_address = candidate.interrupt_in_endpoint_address,
            .interrupt_in_endpoint_max_packet = candidate.interrupt_in_endpoint_max_packet,
            .interrupt_in_endpoint_interval = candidate.interrupt_in_endpoint_interval,
            .bulk_in_endpoint_address = candidate.bulk_in_endpoint_address,
            .bulk_in_endpoint_max_burst = candidate.bulk_in_endpoint_max_burst,
            .bulk_out_endpoint_address = candidate.bulk_out_endpoint_address,
            .bulk_out_endpoint_max_burst = candidate.bulk_out_endpoint_max_burst,
        };
        instance.current.interface_record_count += 1;
    }

    fn currentInterruptOwnerMatch(instance: *Instance) ?event_router.Match {
        if (!instance.current.interrupt_pending or instance.current.interrupt_pending_trb_phys == 0) return null;
        if (instance.current.addressed_slot_id == 0 or instance.current.interrupt_endpoint_id == 0) return null;
        return event_router.transferMatch(
            instance.current.addressed_slot_id,
            instance.current.interrupt_endpoint_id,
            instance.current.interrupt_pending_trb_phys,
        );
    }

    fn eventHasLiveOwner(instance: *Instance, event: XhciEvent) bool {
        if (instance.transfer_objects.owns(event)) return true;
        if (instance.active_command) |owner| {
            if (event_router.matches(event, owner)) return true;
        }
        if (instance.currentInterruptOwnerMatch()) |owner| {
            if (event_router.matches(event, owner)) return true;
        }
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.active_runtime_index != null and instance.active_runtime_index.? == i) continue;
            if (runtimeInterruptOwnerMatch(&instance.runtimes[i])) |owner| {
                if (event_router.matches(event, owner)) return true;
            }
        }
        return false;
    }

    fn clearOverflowedInterruptOwner(instance: *Instance, event: XhciEvent) bool {
        if (instance.transfer_objects.matchingHandle(event)) |handle| {
            _ = instance.transfer_objects.cancel(handle);
            _ = instance.transfer_objects.release(handle);
        }
        if (instance.currentInterruptOwnerMatch()) |owner| {
            if (event_router.matches(event, owner)) {
                instance.current.interrupt_pending = false;
                instance.current.interrupt_pending_trb_phys = 0;
                instance.current.interrupt_transfer_handle = 0;
                instance.current.interrupt_pending_streak = 0;
                return true;
            }
        }
        var i: usize = 0;
        while (i < instance.runtimes.len) : (i += 1) {
            if (instance.active_runtime_index != null and instance.active_runtime_index.? == i) continue;
            if (runtimeInterruptOwnerMatch(&instance.runtimes[i])) |owner| {
                if (!event_router.matches(event, owner)) continue;
                instance.runtimes[i].interrupt_pending = false;
                instance.runtimes[i].interrupt_pending_trb_phys = 0;
                instance.runtimes[i].interrupt_transfer_handle = 0;
                instance.runtimes[i].interrupt_pending_streak = 0;
                return true;
            }
        }
        return false;
    }

    fn routeForeignEvent(instance: *Instance, event: XhciEvent) void {
        if (instance.pending_port_changes.route(event, instance.current.port_count_seen)) return;
        if (instance.eventHasLiveOwner(event)) {
            switch (instance.deferred_events.enqueue(event)) {
                .queued => return,
                .overflow => {
                    _ = instance.clearOverflowedInterruptOwner(event);
                },
            }
        }
        instance.recordStaleEvent(event);
        instance.current.stale_events += 1;
    }

    fn pollMatchingEvent(instance: *Instance, expected: event_router.Match) ?XhciEvent {
        if (instance.deferred_events.take(expected)) |event| return event;
        return instance.drainEventBatch(expected);
    }

    fn drainEventBatch(instance: *Instance, expected: event_router.Match) ?XhciEvent {
        var matched: ?XhciEvent = null;
        var processed: u16 = 0;
        var guard: u32 = 0;
        while (guard < 1024) : (guard += 1) {
            const event = instance.pollEvent() orelse break;
            processed +%= 1;
            if (matched == null and event_router.matches(event, expected)) {
                matched = event;
            } else {
                instance.routeForeignEvent(event);
            }
        }
        instance.commitEventBatch(processed);
        return matched;
    }

    fn waitMatchingEvent(instance: *Instance, expected: event_router.Match) ?XhciEvent {
        return instance.waitMatchingEventWithin(expected, null);
    }

    fn waitMatchingEventWithin(
        instance: *Instance,
        expected: event_router.Match,
        recovery_budget: ?*const usb_wait.Deadline,
    ) ?XhciEvent {
        instance.current.last_wait_cancelled = false;
        if (instance.deferred_events.take(expected)) |event| return event;
        if (instance.drainEventBatch(expected)) |event| return event;
        var wait = usb_wait.Wait.begin(
            usb_timing.XHCI_EVENT_TIMEOUT_MS,
            "xhci-event",
            0,
        );
        const deadline = &wait.deadline;
        const uses_tick_deadline = deadline.usesTickDeadline();
        const uses_hpet_deadline = deadline.usesHpetDeadline();
        const uses_tsc_deadline = deadline.usesTscDeadline();
        if (uses_tick_deadline) {
            instance.current.event_tick_deadline_waits +%= 1;
        } else if (uses_hpet_deadline) {
            instance.current.event_hpet_deadline_waits +%= 1;
        } else if (uses_tsc_deadline) {
            instance.current.event_tsc_deadline_waits +%= 1;
        } else {
            instance.current.event_guard_waits +%= 1;
        }
        var guard: u32 = 0;
        var timeout_clock: TimeoutClock = .cpu_guard;
        while (true) : (guard +%= 1) {
            if (instance.active_runtime_index) |index| {
                if (transactionOwnedByCurrent(&instance.runtimes[index]) and instance.runtimes[index].detach_pending) {
                    instance.current.last_wait_cancelled = true;
                    _ = wait.finish(false);
                    return null;
                }
            }
            if (recovery_budget) |budget| {
                if (budget.expiredAny()) {
                    timeout_clock = .recovery_budget;
                    break;
                }
            }
            if (deadline.expired()) {
                timeout_clock = .ticks;
                break;
            }
            if (deadline.hpetExpired()) {
                timeout_clock = .hpet;
                break;
            }
            if (deadline.tscExpired()) {
                timeout_clock = if (deadline.usesFallbackTsc()) .tsc_fallback else .tsc;
                break;
            }
            if (instance.drainEventBatch(expected)) |event| {
                _ = wait.finish(true);
                return event;
            }
            if (instance.deferred_events.take(expected)) |event| {
                _ = wait.finish(true);
                return event;
            }
            if (guard >= COMMAND_WAIT_GUARD) {
                timeout_clock = .cpu_guard;
                break;
            }
            instance.idleDeviceWait(&wait);
        }
        const elapsed_ticks = deadline.elapsedTicks();
        const elapsed_hpet = deadline.elapsedHpet();
        const elapsed_tsc = deadline.elapsedTsc();
        _ = wait.finish(false);
        if (timeout_clock == .ticks) {
            instance.current.event_tick_timeouts +%= 1;
        } else if (timeout_clock == .hpet) {
            instance.current.event_hpet_timeouts +%= 1;
        } else if (timeout_clock == .recovery_budget) {
            instance.current.event_recovery_budget_timeouts +%= 1;
        } else if (timeout_clock == .tsc or timeout_clock == .tsc_fallback) {
            instance.current.event_tsc_timeouts +%= 1;
        } else {
            instance.current.event_guard_timeouts +%= 1;
            instance.current.event_cpu_guard_timeouts +%= 1;
        }
        // This executes in the same non-preemptible kernel path that timed out,
        // so it remains visible even when the scheduler and desktop are wedged.
        // A generation-bound token lets the exact recovered transfer close this
        // incident without allowing a stale completion to clear newer evidence.
        const incident_token = diag_screen.beginResolvableIncident();
        switch (expected) {
            .transfer => {
                // Do not overwrite an older exact owner with an invalid token
                // merely because another reporter currently owns the screen.
                if (incident_token.valid()) {
                    instance.closeLastSyncTransferIncident();
                    instance.last_sync_transfer_incident = incident_token;
                }
            },
            .command => {},
        }
        diag_screen.write("[XHCI] event timeout owner=");
        switch (expected) {
            .transfer => |transfer| {
                diag_screen.write("transfer slot=");
                diag_screen.writeDec(transfer.slot_id);
                diag_screen.write(" ep=");
                diag_screen.writeDec(transfer.endpoint_id);
                diag_screen.write(" trb=");
                diag_screen.writeHex(transfer.trb_phys[0]);
            },
            .command => |command| {
                diag_screen.write("command trb=");
                diag_screen.writeHex(command.trb_phys);
            },
        }
        diag_screen.write(" clock=");
        diag_screen.write(switch (timeout_clock) {
            .ticks => "ticks",
            .hpet => "hpet",
            .tsc => "tsc",
            .tsc_fallback => "tsc-fallback",
            .recovery_budget => "recovery-budget",
            .cpu_guard => "cpu-guard",
        });
        diag_screen.write(" elapsed_ticks=");
        diag_screen.writeDec(elapsed_ticks);
        diag_screen.write(" elapsed_hpet=");
        diag_screen.writeDec(elapsed_hpet);
        diag_screen.write(" elapsed_tsc=");
        diag_screen.writeDec(elapsed_tsc);
        diag_screen.write(" guard=");
        diag_screen.writeDec(guard);
        diag_screen.endLine();
        instance.persistXhciTimeout(expected, timeout_clock, elapsed_ticks, elapsed_hpet, elapsed_tsc, guard);
        instance.diagXhciTimeoutState(expected);
        switch (expected) {
            .transfer => {},
            .command => {
                // Command submission has no higher protocol owner. Its timeout
                // and hardware snapshot are complete when this call returns.
                _ = diag_screen.resolveIncident(incident_token);
            },
        }
        return null;
    }

    fn persistXhciTimeout(
        instance: *Instance,
        expected: event_router.Match,
        timeout_clock: TimeoutClock,
        elapsed_ticks: u64,
        elapsed_hpet: u64,
        elapsed_tsc: u64,
        guard: u32,
    ) void {
        persistentDiagPuts("[XHCI] event timeout owner=");
        switch (expected) {
            .transfer => |transfer| {
                persistentDiagPuts("transfer slot=");
                persistentDiagDec(transfer.slot_id);
                persistentDiagPuts(" ep=");
                persistentDiagDec(transfer.endpoint_id);
                persistentDiagPuts(" trb=0x");
                persistentDiagHex(transfer.trb_phys[0], 16);
            },
            .command => |command| {
                persistentDiagPuts("command trb=0x");
                persistentDiagHex(command.trb_phys, 16);
            },
        }
        persistentDiagPuts(" clock=");
        persistentDiagPuts(switch (timeout_clock) {
            .ticks => "ticks",
            .hpet => "hpet",
            .tsc => "tsc",
            .tsc_fallback => "tsc-fallback",
            .recovery_budget => "recovery-budget",
            .cpu_guard => "cpu-guard",
        });
        persistentDiagPuts(" elapsed_ticks=");
        persistentDiagDec(elapsed_ticks);
        persistentDiagPuts(" elapsed_hpet=");
        persistentDiagDec(elapsed_hpet);
        persistentDiagPuts(" elapsed_tsc=");
        persistentDiagDec(elapsed_tsc);
        persistentDiagPuts(" guard=");
        persistentDiagDec(guard);
        persistentDiagPuts("\r\n");

        persistentDiagPuts("[XHCI] hw usbcmd=0x");
        persistentDiagHex(instance.readOp32(OP_USBCMD), 8);
        persistentDiagPuts(" usbsts=0x");
        persistentDiagHex(instance.readOp32(OP_USBSTS), 8);
        persistentDiagPuts(" iman=0x");
        persistentDiagHex(instance.readRt32(RT_IR0_IMAN), 8);
        persistentDiagPuts(" erdp=0x");
        persistentDiagHex(instance.readRt64(RT_IR0_ERDP), 16);
        persistentDiagPuts("\r\n");
    }

    fn diagXhciTimeoutState(instance: *Instance, expected: event_router.Match) void {
        const next_event_control = if (instance.event_ring_virt != 0)
            volatileRead32(instance.event_ring_virt + @as(u64, instance.current.event_dequeue) * @sizeOf(Trb) + 12)
        else
            0;
        diag_screen.write("[XHCI] hw usbcmd=");
        diag_screen.writeHex(instance.readOp32(OP_USBCMD));
        diag_screen.write(" usbsts=");
        diag_screen.writeHex(instance.readOp32(OP_USBSTS));
        diag_screen.write(" iman=");
        diag_screen.writeHex(instance.readRt32(RT_IR0_IMAN));
        diag_screen.write(" erdp=");
        diag_screen.writeHex(instance.readRt64(RT_IR0_ERDP));
        diag_screen.endLine();

        diag_screen.write("[XHCI] ring deq=");
        diag_screen.writeDec(instance.current.event_dequeue);
        diag_screen.write(" cycle=");
        diag_screen.writeDec(instance.current.event_cycle);
        diag_screen.write(" next=");
        diag_screen.writeHex(next_event_control);
        diag_screen.write(" events=");
        diag_screen.writeDec(instance.current.events);
        diag_screen.write(" last=");
        diag_screen.writeDec(instance.current.last_event_type);
        diag_screen.write("/");
        diag_screen.writeDec(instance.current.last_event_code);
        diag_screen.endLine();

        switch (expected) {
            .transfer => |transfer| {
                diag_screen.write("[XHCI] target epstate=");
                if (instance.endpointState(transfer.endpoint_id)) |state| {
                    diag_screen.writeDec(@intFromEnum(state));
                } else {
                    diag_screen.write("unknown");
                }
                if (instance.current.addressed_port != 0) {
                    const port_offset = OP_PORT_BASE +
                        @as(u64, instance.current.addressed_port - 1) * OP_PORT_STRIDE;
                    diag_screen.write(" portsc=");
                    diag_screen.writeHex(instance.readOp32(port_offset));
                }
                diag_screen.endLine();
            },
            .command => {},
        }
    }

    fn submitCommand(instance: *Instance, parameter: u64, status_value: u32, control_extra: u32) ?XhciEvent {
        return instance.submitCommandWithin(parameter, status_value, control_extra, null);
    }

    fn submitCommandWithin(
        instance: *Instance,
        parameter: u64,
        status_value: u32,
        control_extra: u32,
        recovery_budget: ?*const usb_wait.Deadline,
    ) ?XhciEvent {
        if (!instance.current.controller_running or instance.command_ring_virt == 0) return null;
        if (instance.active_command != null) return null;
        if (recovery_budget) |budget| {
            if (budget.expiredAny()) return null;
        }
        const enqueue = instance.current.command_enqueue;
        if (enqueue >= COMMAND_TRB_COUNT - 1) {
            instance.current.ring_full += 1;
            return null;
        }
        const ring: [*]Trb = @ptrFromInt(instance.command_ring_virt);
        const command_trb_phys = instance.current.command_ring_phys + @as(u64, enqueue) * @sizeOf(Trb);
        const cycle = if (instance.current.command_cycle != 0) TRB_CYCLE else 0;
        ring[enqueue] = .{ .parameter = parameter, .status = status_value, .control = control_extra | cycle };
        dmaFence();
        instance.current.last_command_type = @truncate((control_extra >> TRB_TYPE_SHIFT) & 0x3F);
        instance.current.commands += 1;
        const advance = ring_cycle.afterSubmission(enqueue, instance.current.command_cycle, COMMAND_TRB_COUNT);
        if (advance.wrapped) {
            updateLinkTrb(instance.command_ring_virt, COMMAND_TRB_COUNT, advance.link_cycle, false);
            instance.current.command_ring_wraps += 1;
        }
        instance.current.command_enqueue = advance.next_enqueue;
        instance.current.command_cycle = advance.next_producer_cycle;
        const expected = event_router.commandMatch(command_trb_phys);
        instance.active_command = expected;
        defer instance.active_command = null;
        instance.writeDoorbell(0, 0);
        return instance.waitCommandCompletionWithin(expected, recovery_budget);
    }

    fn waitCommandCompletion(instance: *Instance, expected: event_router.Match) ?XhciEvent {
        return instance.waitCommandCompletionWithin(expected, null);
    }

    fn waitCommandCompletionWithin(
        instance: *Instance,
        expected: event_router.Match,
        recovery_budget: ?*const usb_wait.Deadline,
    ) ?XhciEvent {
        if (instance.waitMatchingEventWithin(expected, recovery_budget)) |event| return event;
        if (!instance.current.last_wait_cancelled) instance.current.timeouts += 1;
        instance.current.reason = if (instance.current.last_wait_cancelled) "USB device detached during command" else "timeout waiting for xHCI command completion";
        return null;
    }

    fn pollEvent(instance: *Instance) ?XhciEvent {
        const event_addr = instance.event_ring_virt + @as(u64, instance.current.event_dequeue) * @sizeOf(Trb);
        const expected = if (instance.current.event_cycle != 0) TRB_CYCLE else 0;

        // Der xHC publiziert ein Event ueber dessen Cycle-Bit. Dieses Bit muss
        // deshalb volatil zuerst gelesen werden; erst nach der DMA-Barriere sind
        // Parameter und Status ein gueltiger Snapshot. Ein zweiter Control-Read
        // schliesst aus, dass wir einen noch nicht vollstaendig sichtbaren Slot
        // auswerten.
        const published_control = volatileRead32(event_addr + 12);
        if ((published_control & TRB_CYCLE) != expected) return null;
        dmaFence();
        const parameter = volatileRead64(event_addr);
        const status_value = volatileRead32(event_addr + 8);
        const control = volatileRead32(event_addr + 12);
        if ((control & TRB_CYCLE) != expected) return null;

        instance.current.events += 1;
        instance.advanceEventRing();
        const event_type: u8 = @truncate((control >> TRB_TYPE_SHIFT) & 0x3F);
        const code: u8 = @truncate((status_value >> 24) & 0xFF);
        if (code == COMPLETION_EVENT_RING_FULL_ERROR) instance.current.ring_full += 1;
        if (event_type == TRB_TYPE_TRANSFER_EVENT) instance.current.transfer_events += 1;
        const out = XhciEvent{
            .event_type = event_type,
            .code = code,
            .slot_id = @truncate((control >> 24) & 0xFF),
            .endpoint_id = @truncate((control >> 16) & 0x1F),
            .parameter = parameter,
            .length = status_value & 0x00FF_FFFF,
            .control = control,
        };
        instance.recordLastEvent(out);
        return out;
    }

    fn advanceEventRing(instance: *Instance) void {
        instance.current.event_dequeue += 1;
        if (instance.current.event_dequeue >= EVENT_TRB_COUNT) {
            instance.current.event_dequeue = 0;
            instance.current.event_cycle = if (instance.current.event_cycle == 0) 1 else 0;
            instance.current.event_ring_wraps += 1;
        }
    }

    fn commitEventBatch(instance: *Instance, processed: u16) void {
        if (processed == 0) return;
        if (processed > instance.current.event_max_batch) instance.current.event_max_batch = processed;

        // Polling-Betrieb ohne USBCMD.INTE: Status/IP trotzdem W1C quittieren,
        // damit EHB und die Interrupter-State-Machine auf realer Hardware nicht
        // ueber viele Ringumlaeufe in einem alten Pending-Zustand bleiben.
        dmaFence();
        if ((instance.readOp32(OP_USBSTS) & USBSTS_EINT) != 0) {
            instance.writeOp32(OP_USBSTS, USBSTS_EINT);
            _ = instance.readOp32(OP_USBSTS);
        }
        const iman = instance.readRt32(RT_IR0_IMAN);
        if ((iman & IMAN_IP) != 0) {
            instance.writeRt32(RT_IR0_IMAN, iman | IMAN_IP);
            _ = instance.readRt32(RT_IR0_IMAN);
        }
        const dequeue = instance.current.event_ring_phys + @as(u64, instance.current.event_dequeue) * @sizeOf(Trb);
        instance.writeRt64(RT_IR0_ERDP, dequeue | ERDP_EHB);
        _ = instance.readRt64(RT_IR0_ERDP);
        instance.current.event_erdp_commits +%= 1;
        instance.rearmEventIrq();
    }

    fn recordLastEvent(instance: *Instance, event: XhciEvent) void {
        instance.current.last_event_type = event.event_type;
        instance.current.last_event_code = event.code;
        instance.current.last_event_slot = event.slot_id;
        instance.current.last_event_endpoint = event.endpoint_id;
        instance.current.last_event_parameter = event.parameter;
        instance.current.last_event_length = event.length;
    }

    fn recordStaleEvent(instance: *Instance, event: XhciEvent) void {
        instance.current.last_stale_event_type = event.event_type;
        instance.current.last_stale_event_code = event.code;
        instance.current.last_stale_event_slot = event.slot_id;
        instance.current.last_stale_event_endpoint = event.endpoint_id;
    }

    fn readOperational(instance: *Instance) void {
        instance.current.usbcmd = instance.readOp32(OP_USBCMD);
        instance.current.usbsts = instance.readOp32(OP_USBSTS);
        instance.current.pagesize = instance.readOp32(OP_PAGESIZE);
        instance.current.dnctrl = instance.readOp32(OP_DNCTRL);
        instance.current.crcr = instance.readOp64(OP_CRCR);
        instance.current.dcbaap = instance.readOp64(OP_DCBAAP);
        instance.current.config = instance.readOp32(OP_CONFIG);
    }

    fn readRuntime(instance: *Instance) void {
        if (instance.current.rtsoff == 0) return;
        instance.current.mfindex = instance.readRt32(RT_MFINDEX);
        instance.current.iman0 = instance.readRt32(RT_IR0_IMAN);
        instance.current.imod0 = instance.readRt32(RT_IR0_IMOD);
        instance.current.erstsz0 = instance.readRt32(RT_IR0_ERSTSZ);
        instance.current.erstba0 = instance.readRt64(RT_IR0_ERSTBA);
        instance.current.erdp0 = instance.readRt64(RT_IR0_ERDP);
    }

    fn readPorts(instance: *Instance) void {
        const count = if (instance.current.max_ports < MAX_PORTS) @as(usize, instance.current.max_ports) else MAX_PORTS;
        instance.current.port_count_seen = @intCast(count);
        instance.current.connected_ports = 0;
        instance.current.enabled_ports = 0;
        var i: usize = 0;
        while (i < count) : (i += 1) {
            const base = OP_PORT_BASE + (@as(u64, i) * OP_PORT_STRIDE);
            const old = instance.current.first_ports[i];
            const portsc = instance.readOp32(base);
            const connected = (portsc & PORTSC_CCS) != 0;
            const enabled = (portsc & PORTSC_PED) != 0;
            const powered = (portsc & PORTSC_PP) != 0;
            if (connected) instance.current.connected_ports += 1;
            if (enabled) instance.current.enabled_ports += 1;
            instance.current.first_ports[i] = .{
                .index = @intCast(i + 1),
                .portsc = portsc,
                .portpmsc = instance.readOp32(base + 0x04),
                .portli = instance.readOp32(base + 0x08),
                .porthlpmc = instance.readOp32(base + 0x0C),
                .change_bits = portsc & PORTSC_CHANGE_MASK,
                .link_state = @truncate(portLinkState(portsc)),
                .connected = connected,
                .enabled = enabled,
                .powered = powered,
                .debounce_ok = old.debounce_ok,
                .reset_attempted = old.reset_attempted,
                .reset_ok = old.reset_ok,
                .reset_reason = old.reset_reason,
            };
        }
    }

    fn readOp32(instance: *Instance, offset: u64) u32 {
        return instance.read32(@as(u64, instance.current.caplength) + offset);
    }

    fn writeOp32(instance: *Instance, offset: u64, value: u32) void {
        instance.write32(@as(u64, instance.current.caplength) + offset, value);
    }

    fn readOp64(instance: *Instance, offset: u64) u64 {
        const low = instance.readOp32(offset);
        const high = instance.readOp32(offset + 4);
        return (@as(u64, high) << 32) | low;
    }

    fn writeOp64(instance: *Instance, offset: u64, value: u64) void {
        instance.writeOp32(offset, @truncate(value));
        instance.writeOp32(offset + 4, @truncate(value >> 32));
    }

    fn readRt32(instance: *Instance, offset: u64) u32 {
        return instance.read32((instance.current.rtsoff & 0xFFFF_FFE0) + offset);
    }

    fn writeRt32(instance: *Instance, offset: u64, value: u32) void {
        instance.write32((instance.current.rtsoff & 0xFFFF_FFE0) + offset, value);
    }

    fn readRt64(instance: *Instance, offset: u64) u64 {
        const low = instance.readRt32(offset);
        const high = instance.readRt32(offset + 4);
        return (@as(u64, high) << 32) | low;
    }

    fn writeRt64(instance: *Instance, offset: u64, value: u64) void {
        instance.writeRt32(offset, @truncate(value));
        instance.writeRt32(offset + 4, @truncate(value >> 32));
    }

    fn writeDoorbell(instance: *Instance, index_value: u8, target: u32) void {
        instance.write32((instance.current.dboff & 0xFFFF_FFFC) + @as(u64, index_value) * 4, target);
    }

    fn waitOpSet(instance: *Instance, offset: u64, mask: u32, timeout_ms: u32, reason: []const u8) bool {
        var wait = usb_wait.Wait.begin(timeout_ms, reason, 0);
        while (!wait.expired()) {
            if ((instance.readOp32(offset) & mask) == mask) {
                _ = wait.finish(true);
                return true;
            }
            wait.idle();
        }
        _ = wait.finish(false);
        return false;
    }

    fn waitOpClear(instance: *Instance, offset: u64, mask: u32, timeout_ms: u32, reason: []const u8) bool {
        var wait = usb_wait.Wait.begin(timeout_ms, reason, 0);
        while (!wait.expired()) {
            if ((instance.readOp32(offset) & mask) == 0) {
                _ = wait.finish(true);
                return true;
            }
            wait.idle();
        }
        _ = wait.finish(false);
        return false;
    }

    fn scratchpadCount(instance: *Instance) u8 {
        const low = (instance.current.hcsparams2 >> 27) & 0x1F;
        const high = (instance.current.hcsparams2 >> 21) & 0x1F;
        return @truncate((high << 5) | low);
    }

    fn read8(instance: *Instance, offset: u64) u8 {
        const ptr: *volatile u8 = @ptrFromInt(instance.current.mmio_virt + offset);
        return ptr.*;
    }

    fn read16(instance: *Instance, offset: u64) u16 {
        const ptr: *volatile u16 = @ptrFromInt(instance.current.mmio_virt + offset);
        return ptr.*;
    }

    fn read32(instance: *Instance, offset: u64) u32 {
        const ptr: *volatile u32 = @ptrFromInt(instance.current.mmio_virt + offset);
        return ptr.*;
    }

    fn write32(instance: *Instance, offset: u64, value: u32) void {
        const ptr: *volatile u32 = @ptrFromInt(instance.current.mmio_virt + offset);
        ptr.* = value;
    }

    fn logSummary(instance: *Instance) void {
        bootlog.puts("[XHCI] ");
        bootlog.putDec(instance.current.device.bus);
        bootlog.puts(":");
        bootlog.putDec(instance.current.device.device);
        bootlog.puts(".");
        bootlog.putDec(instance.current.device.function);
        bootlog.puts(" mmio=0x");
        bootlog.putHex(instance.current.mmio_phys, 16);
        bootlog.puts(" hci=0x");
        bootlog.putHex(instance.current.hciversion, 4);
        bootlog.puts(" slots=");
        bootlog.putDec(instance.current.max_slots);
        bootlog.puts(" ports=");
        bootlog.putDec(instance.current.max_ports);
        bootlog.puts(" sts=0x");
        bootlog.putHex(instance.current.usbsts, 8);
        bootlog.puts(" handoff=");
        bootlog.puts(instance.current.bios_handoff);
        bootlog.puts("\r\n");
    }
};
