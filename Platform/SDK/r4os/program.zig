const abi = @import("r4os_contract").abi;
const std = @import("std");
const vm_allocator = @import("vm_allocator.zig");
const r4xstart = @import("r4xstart.zig");
const service_deadline = @import("service_deadline.zig");
const time_contract = @import("time_contract.zig");

pub const ServiceStopPolicy = enum(u8) {
    graceful = abi.service_stop_policy_graceful,
    kill_after_grace = abi.service_stop_policy_kill_after_grace,
};

// Bundle buendelt die pro Programm ueber R4XStart-Imports aufgeloesten
// R4L-Gruppentabellen. Es ist die einzige Laufzeitquelle der SDK-Contexts;
// reserved_runtime im rohen Startkontext bleibt ABI-reserviert und ist 0.
pub const Bundle = struct {
    raw: *const abi.R4XStartContext,
    sys: ?*const abi.R4XStartR4Sys = null,
    desk: ?*const abi.R4XStartR4Desk = null,
    draw: ?*const abi.R4XStartR4Draw = null,
    net: ?*const abi.R4XStartR4Net = null,
    audio: ?*const abi.R4XStartR4Audio = null,
    dev: ?*const abi.R4XStartR4Dev = null,
};

// Pro R4X-Instanz eigene BSS-Kopie (jedes Programm traegt sein SDK).
var bundle_storage: Bundle = undefined;
var bundle_initialized: bool = false;

// 0.56.41 (B2): Fallback fuer Kontexte ohne R4SYS-Tabelle.
const empty_sys_table: abi.R4XStartR4Sys = .{};

fn resolveGroupTable(comptime T: type, xs: r4xstart.Context, group: abi.R4LGroup, magic: u32, version: u32, size: u32) ?*const T {
    const item = xs.findImport(group) orelse return null;
    if ((item.flags & abi.r4xstart_import_flag_group_interface) == 0) return null;
    if (item.table == 0) return null;
    const table: *const T = @ptrFromInt(item.table);
    if (table.magic != magic) return null;
    if (table.abi_version < version or table.size < size) return null;
    return table;
}

pub fn bundleFromR4XStart(raw: *const abi.R4XStartContext) ?*const Bundle {
    if (bundle_initialized) return if (bundle_storage.raw == raw) &bundle_storage else null;
    const candidate = bundleValueFromR4XStart(raw) orelse return null;
    bundle_storage = candidate;
    bundle_initialized = true;
    return &bundle_storage;
}

// High-Level-App-Pfad: Der Aufrufer besitzt den Bundlewert. Damit koennen
// mehrere App-Objekte ohne globale Initialisierung oder geteilte Mutation
// aus unabhaengigen R4XStart-Kontexten aufgebaut werden.
pub fn bundleValueFromR4XStart(raw: *const abi.R4XStartContext) ?Bundle {
    if (raw.magic != abi.r4xstart_magic) return null;
    if (raw.abi_major != abi.r4xstart_abi_major) return null;
    if (raw.size < abi.r4xstart_context_size) return null;
    // Der Vertrag sind die R4L-Gruppentabellen; mindestens R4SYS muss
    // aufloesen. reserved_runtime wird nicht ausgewertet.
    const xs = r4xstart.Context.init(raw);
    const candidate = Bundle{
        .raw = raw,
        // R4SYS tail functions are append-only and optional. Accept the
        // stable table header; tableFn checks the exact size of each slot.
        .sys = resolveGroupTable(abi.R4XStartR4Sys, xs, .r4sys, abi.r4xstart_r4sys_magic, 1, @offsetOf(abi.R4XStartR4Sys, "write") + @sizeOf(usize)),
        .desk = resolveGroupTable(abi.R4XStartR4Desk, xs, .r4desk, abi.r4xstart_r4desk_magic, abi.r4xstart_r4desk_version, abi.r4xstart_r4desk_size),
        .draw = resolveGroupTable(abi.R4XStartR4Draw, xs, .r4draw, abi.r4xstart_r4draw_magic, abi.r4xstart_r4draw_version, abi.r4xstart_r4draw_size),
        // R4NET tail functions are optional and append-only. Keep older
        // kernels usable; tableFn checks the exact size of every requested
        // slot and netServiceRequest retains its raw-IPC fallback.
        .net = resolveGroupTable(abi.R4XStartR4Net, xs, .r4net, abi.r4xstart_r4net_magic, 1, @offsetOf(abi.R4XStartR4Net, "tcp_connect") + @sizeOf(usize)),
        .audio = resolveGroupTable(abi.R4XStartR4Audio, xs, .r4audio, abi.r4xstart_r4audio_magic, abi.r4xstart_r4audio_version, abi.r4xstart_r4audio_size),
        // R4DEV tail functions are optional and append-only. Older kernels
        // remain usable; tableFn checks the exact size of each requested slot.
        .dev = resolveGroupTable(abi.R4XStartR4Dev, xs, .r4dev, abi.r4xstart_r4dev_magic, 1, @offsetOf(abi.R4XStartR4Dev, "memory_summary") + @sizeOf(usize)),
    };
    if (candidate.sys == null) return null;
    return candidate;
}

const dns_r4x_service_name = "DNSSVC";
const dns_r4x_service_timeout_ms: u64 = 5000;
const dhcp_r4x_service_name = "DHCPSVC";
const dhcp_r4x_service_timeout_ms: u64 = 5000;
const tcp_r4x_service_name = "TCPSVC";
const tcp_r4x_service_timeout_ms: u64 = 5000;
const tcp_accept_default_wait_ms: u64 = 10000;
const tcp_accept_read_default_wait_ms: u64 = 3000;
const tcp_write_default_wait_ms: u64 = 1000;
const net_socket_completion_grace_ms: u64 = 250;
const udp_r4x_service_name = "UDPSVC";
const udp_r4x_service_timeout_ms: u64 = 5000;
const net_r4x_service_unavailable_error = "r4x-service-unavailable";
const time_r4x_service_name = "TIMESVC";
const time_r4x_service_timeout_ms: u64 = 1000;
const log_r4x_service_timeout_ms: u64 = 1000;
const audio_r4x_service_name = "AUDSVC";
const audio_r4x_service_timeout_ms: u64 = 1000;
const audio_service_payload_capacity: usize = 1024;

pub const EntryFn = *const fn (*Context) callconv(.c) i32;

pub const ResolverOptions = struct {
    server: ?[4]u8 = null,
};

pub const ResolverResult = struct {
    result: i32 = abi.dns_result_tx,
    answer: [4]u8 = .{0} ** 4,
    server: [4]u8 = .{0} ** 4,
    flags: u32 = 0,
    service_status: u32 = abi.net_service_status_failed,
    cache_hit: bool = false,
    cache_valid: bool = false,
    explicit_server: bool = false,
    cache_answer: [4]u8 = .{0} ** 4,
    cache_age_seconds: u32 = 0,
    cache_ttl_seconds: u32 = 0,
    cache_remaining_seconds: u32 = 0,
    queries_tx: u64 = 0,
    resolve_requests: u64 = 0,
    responses_rx: u64 = 0,
    a_records: u64 = 0,
    timeouts: u64 = 0,
    nxdomain: u64 = 0,
    tx_errors: u64 = 0,
    malformed: u64 = 0,
    cache_hits: u64 = 0,
    cache_stores: u64 = 0,
    last_id: u16 = 0,
    name_len: u16 = 0,
    name: [96]u8 = .{0} ** 96,
    last_error: [32]u8 = .{0} ** 32,
};

pub const NetSocketService = enum(u8) {
    tcp,
    udp,
};

pub const NetSocketRequest = struct {
    active: bool = false,
    service: NetSocketService = .tcp,
    op: u16 = 0,
    request_id: u32 = 0,
    service_handle: u32 = 0,
    request_len: u32 = 0,
    response_len: u32 = 0,
    header: abi.ServiceMessageHeader = .{},
    info: abi.ProgramIoInfo = .{},
    request: [abi.service_api_max_payload]u8 = .{0} ** abi.service_api_max_payload,
    response: [abi.service_api_max_payload]u8 = .{0} ** abi.service_api_max_payload,

    pub fn reset(self: *NetSocketRequest) void {
        self.* = .{};
    }

    pub fn completed(self: *const NetSocketRequest) bool {
        return self.active and self.info.state == abi.io_state_completed;
    }

    pub fn responseSlice(self: *const NetSocketRequest) []const u8 {
        const len = @min(@as(usize, @intCast(self.response_len)), self.response.len);
        return self.response[0..len];
    }

    pub fn tcpStatus(self: *const NetSocketRequest, out: *abi.NetServiceTcpStatus) bool {
        const response = self.responseSlice();
        if (!copyNetSocketStruct(abi.NetServiceTcpStatus, out, response)) return false;
        return out.magic == abi.net_service_tcp_status_magic and out.version == abi.net_service_tcp_status_version;
    }

    pub fn tcpResult(self: *const NetSocketRequest, out: *abi.NetServiceTcpResult) bool {
        const response = self.responseSlice();
        if (!copyNetSocketStruct(abi.NetServiceTcpResult, out, response)) return false;
        return out.magic == abi.net_service_tcp_result_magic and out.version == abi.net_service_tcp_result_version;
    }

    pub fn tcpData(self: *const NetSocketRequest, result: *const abi.NetServiceTcpResult) ?[]const u8 {
        const response = self.responseSlice();
        if (response.len < @sizeOf(abi.NetServiceTcpResult)) return null;
        const available = response[@sizeOf(abi.NetServiceTcpResult)..];
        if ((result.flags & abi.net_service_tcp_flag_data) == 0 or result.bytes == 0) return available[0..0];
        const len: usize = @intCast(result.bytes);
        if (len > available.len) return null;
        return available[0..len];
    }

    pub fn udpStatus(self: *const NetSocketRequest, out: *abi.NetServiceUdpStatus) bool {
        const response = self.responseSlice();
        if (!copyNetSocketStruct(abi.NetServiceUdpStatus, out, response)) return false;
        return out.magic == abi.net_service_udp_status_magic and out.version == abi.net_service_udp_status_version;
    }

    pub fn udpResult(self: *const NetSocketRequest, out: *abi.NetServiceUdpResult) bool {
        const response = self.responseSlice();
        if (!copyNetSocketStruct(abi.NetServiceUdpResult, out, response)) return false;
        return out.magic == abi.net_service_udp_result_magic and out.version == abi.net_service_udp_result_version;
    }

    pub fn udpData(self: *const NetSocketRequest, result: *const abi.NetServiceUdpResult) ?[]const u8 {
        const response = self.responseSlice();
        if (response.len < @sizeOf(abi.NetServiceUdpResult)) return null;
        const available = response[@sizeOf(abi.NetServiceUdpResult)..];
        if ((result.flags & abi.net_service_udp_flag_data) == 0 or result.bytes == 0) return available[0..0];
        const len: usize = @intCast(result.bytes);
        if (len > available.len) return null;
        return available[0..len];
    }
};

pub const TcpReadiness = struct {
    readable: bool = false,
    writable: bool = false,
    would_block: bool = false,
    terminal: bool = false,
    reset: bool = false,
    peer_closed: bool = false,
    pending_rx: u32 = 0,
    rx_window: u32 = 0,
    tx_window: u32 = 0,
    lifecycle_cause: u32 = abi.net_service_socket_lifecycle_unknown,
    service_status: u32 = abi.net_service_status_idle,
};

pub fn tcpResultReadiness(result: *const abi.NetServiceTcpResult) TcpReadiness {
    const status = serviceStatusCodeFromFlags(result.flags);
    const lifecycle = result.lifecycle_cause;
    return .{
        .readable = result.pending_rx != 0,
        .writable = result.tx_window != 0,
        .would_block = status == abi.net_service_status_would_block or lifecycle == abi.net_service_socket_lifecycle_would_block,
        .terminal = tcpLifecycleTerminal(lifecycle),
        .reset = lifecycle == abi.net_service_socket_lifecycle_reset,
        .peer_closed = lifecycle == abi.net_service_socket_lifecycle_peer_gone or lifecycle == abi.net_service_socket_lifecycle_closed,
        .pending_rx = result.pending_rx,
        .rx_window = result.rx_window,
        .tx_window = result.tx_window,
        .lifecycle_cause = lifecycle,
        .service_status = status,
    };
}

pub fn tcpResultReadable(result: *const abi.NetServiceTcpResult) bool {
    return tcpResultReadiness(result).readable;
}

pub fn tcpResultWritable(result: *const abi.NetServiceTcpResult) bool {
    return tcpResultReadiness(result).writable;
}

pub fn tcpResultTerminal(result: *const abi.NetServiceTcpResult) bool {
    return tcpResultReadiness(result).terminal;
}

fn tcpLifecycleTerminal(cause: u32) bool {
    return switch (cause) {
        abi.net_service_socket_lifecycle_closed,
        abi.net_service_socket_lifecycle_reset,
        abi.net_service_socket_lifecycle_peer_gone,
        abi.net_service_socket_lifecycle_local_abort,
        abi.net_service_socket_lifecycle_local_close,
        abi.net_service_socket_lifecycle_bad_handle,
        abi.net_service_socket_lifecycle_owner_mismatch,
        abi.net_service_socket_lifecycle_dropped,
        => true,
        else => false,
    };
}

pub fn entryAsm(comptime target: []const u8) []const u8 {
    return ".section .text.r4x_entry,\"ax\"\n" ++
        ".global r4x_entry\n" ++
        "r4x_entry:\n" ++
        "    jmp " ++ target ++ "\n";
}

pub const Context = struct {
    // Rein tabellenbasiert: Die Signatur-Wahrheit sind die benannten
    // Fn-Typ-Namespaces abi.R4SysFns..R4DevFns.
    bundle: ?*const Bundle = null,

    pub fn initBundle(bundle: *const Bundle) Context {
        return .{ .bundle = bundle };
    }

    const TableFieldState = enum {
        no_group,
        beyond_size,
        null_pointer,
        tombstone,
        available,
    };

    fn isTombstone(comptime Table: type, comptime field: []const u8) bool {
        return Table == abi.R4XStartR4Sys and std.mem.eql(u8, field, "reserved_shell_run");
    }

    fn tableFieldState(comptime Table: type, table: ?*const Table, comptime field: []const u8) TableFieldState {
        const t = table orelse return .no_group;
        const end = @offsetOf(Table, field) + @sizeOf(usize);
        if (t.size < end) return .beyond_size;
        if (isTombstone(Table, field)) return .tombstone;
        if (@field(t.*, field) == 0) return .null_pointer;
        return .available;
    }

    // Gruppen-Helper liefern den ueber den passenden Fn-Namespace typisierten
    // Tabellen-Funktionszeiger oder null, wenn Tabelle/Feld fehlt.
    // Anfuege-Sicherheit und Tombstones werden an einer Stelle bewertet.
    fn tableFn(comptime Fns: type, comptime Table: type, table: ?*const Table, comptime field: []const u8) ?@field(Fns, field) {
        if (tableFieldState(Table, table, field) != .available) return null;
        return @ptrFromInt(@field(table.?.*, field));
    }

    // 0.57.5: Unavailable-Basissatz der i32-Wrapper - unterscheidet die
    // fehlende Gruppentabelle (err_no_group) vom fehlenden/zu neuen
    // Tabellenfeld (err_no_fn). `group` ist der Bundle-Feldname
    // ("sys".."dev").
    fn unavailable(self: *const Context, comptime group: []const u8) i32 {
        const b = self.bundle orelse return abi.err_no_group;
        if (@field(b.*, group) == null) return abi.err_no_group;
        return abi.err_no_fn;
    }

    fn sysFn(self: *const Context, comptime field: []const u8) ?@field(abi.R4SysFns, field) {
        const b = self.bundle orelse return null;
        return tableFn(abi.R4SysFns, abi.R4XStartR4Sys, b.sys, field);
    }

    fn deskFn(self: *const Context, comptime field: []const u8) ?@field(abi.R4DeskFns, field) {
        const b = self.bundle orelse return null;
        return tableFn(abi.R4DeskFns, abi.R4XStartR4Desk, b.desk, field);
    }

    fn drawFn(self: *const Context, comptime field: []const u8) ?@field(abi.R4DrawFns, field) {
        const b = self.bundle orelse return null;
        return tableFn(abi.R4DrawFns, abi.R4XStartR4Draw, b.draw, field);
    }

    fn netFn(self: *const Context, comptime field: []const u8) ?@field(abi.R4NetFns, field) {
        const b = self.bundle orelse return null;
        return tableFn(abi.R4NetFns, abi.R4XStartR4Net, b.net, field);
    }

    fn audioFn(self: *const Context, comptime field: []const u8) ?@field(abi.R4AudioFns, field) {
        const b = self.bundle orelse return null;
        return tableFn(abi.R4AudioFns, abi.R4XStartR4Audio, b.audio, field);
    }

    fn devFn(self: *const Context, comptime field: []const u8) ?@field(abi.R4DevFns, field) {
        const b = self.bundle orelse return null;
        return tableFn(abi.R4DevFns, abi.R4XStartR4Dev, b.dev, field);
    }

    // 0.57.2: ehrliche Vertragspruefung - ersetzt die frueheren
    // supports*-Versionsgates (seit 0.56.41 konstant): vorhanden ist,
    // was die importierte Gruppentabelle als Feld traegt.
    pub fn hasSysFn(self: *const Context, comptime field: []const u8) bool {
        return self.sysFn(field) != null;
    }

    pub fn hasDeskFn(self: *const Context, comptime field: []const u8) bool {
        return self.deskFn(field) != null;
    }

    pub fn hasDrawFn(self: *const Context, comptime field: []const u8) bool {
        return self.drawFn(field) != null;
    }

    pub fn hasNetFn(self: *const Context, comptime field: []const u8) bool {
        return self.netFn(field) != null;
    }

    pub fn hasAudioFn(self: *const Context, comptime field: []const u8) bool {
        return self.audioFn(field) != null;
    }

    pub fn hasDevFn(self: *const Context, comptime field: []const u8) bool {
        return self.devFn(field) != null;
    }

    pub fn allocator(self: *const Context) std.mem.Allocator {
        // 0.56.41 (B2): Allokator ueber die R4SYS-Tabelle; ohne Tabelle
        // liefert die leere Default-Tabelle einen sauber fehlschlagenden
        // Allokator (supportsVmApi=false, vm-Felder bleiben 0).
        const b = self.bundle orelse return vm_allocator.allocator(&empty_sys_table);
        const t = b.sys orelse return vm_allocator.allocator(&empty_sys_table);
        return vm_allocator.allocator(t);
    }

    pub fn allocatorStats(self: *const Context) vm_allocator.Stats {
        _ = self;
        return vm_allocator.stats();
    }

    pub fn allocatorTrim(self: *const Context) void {
        const b = self.bundle orelse return;
        const t = b.sys orelse return;
        vm_allocator.trim(t);
    }

    pub fn memorySummary(self: *const Context) ?abi.ProgramMemorySummary {
        var out: abi.ProgramMemorySummary = .{};
        const table_fn = self.devFn("memory_summary") orelse return null;
        if (table_fn(&out) != 0) return null;
        return out;
    }

    pub fn memoryBlockCount(self: *const Context) u32 {
        const table_fn = self.devFn("memory_block_count") orelse return 0;
        return table_fn();
    }

    pub fn memoryBlock(self: *const Context, index: u32) ?abi.ProgramMemoryBlockInfo {
        var out: abi.ProgramMemoryBlockInfo = .{};
        const table_fn = self.devFn("memory_block") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn memoryPressure(self: *const Context) ?abi.ProgramMemoryPressureSnapshot {
        var out: abi.ProgramMemoryPressureSnapshot = .{};
        const table_fn = self.devFn("memory_pressure_snapshot") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn memoryReclaimProbe(self: *const Context, requested_frames: u32) ?abi.ProgramMemoryReclaimProbe {
        var out: abi.ProgramMemoryReclaimProbe = .{};
        const table_fn = self.devFn("memory_reclaim_probe") orelse return null;
        if (table_fn(requested_frames, &out) < 0) return null;
        return out;
    }

    pub fn memoryBackingStoreProbe(self: *const Context, path: [*:0]const u8, requested_bytes: u64, flags: u32) ?abi.ProgramMemoryBackingStoreProbe {
        var out: abi.ProgramMemoryBackingStoreProbe = .{};
        const table_fn = self.devFn("memory_backing_store_probe") orelse return null;
        if (table_fn(path, requested_bytes, flags, &out) < 0) return null;
        return out;
    }

    pub fn memoryBackingStoreSlotProbe(self: *const Context, path: [*:0]const u8, backing_bytes: u64, operation: u32, requested_slots: u64, reservation_id: u32, owner_kind: u32, owner_id: u32, region_id: u32, flags: u32) ?abi.ProgramMemoryBackingStoreSlotProbe {
        var out: abi.ProgramMemoryBackingStoreSlotProbe = .{};
        const table_fn = self.devFn("memory_backing_store_slot_probe") orelse return null;
        if (table_fn(path, backing_bytes, operation, requested_slots, reservation_id, owner_kind, owner_id, region_id, flags, &out) < 0) return null;
        return out;
    }

    pub fn memoryPagerGateProbe(self: *const Context, path: [*:0]const u8, backing_bytes: u64, region_id: u32, requested_bytes: u64, flags: u32) ?abi.ProgramMemoryPagerGateProbe {
        var out: abi.ProgramMemoryPagerGateProbe = .{};
        const table_fn = self.devFn("memory_pager_gate_probe") orelse return null;
        if (table_fn(path, backing_bytes, region_id, requested_bytes, flags, &out) < 0) return null;
        return out;
    }

    pub fn memoryPageIoProbe(self: *const Context, path: [*:0]const u8, backing_bytes: u64, operation: u32, region_id: u32, region_offset: u64, reservation_id: u32, slot_index: u64, page_count: u64, owner_kind: u32, owner_id: u32, expected_generation: u64, page: []u8, flags: u32) ?abi.ProgramMemoryPageIoProbe {
        const page_len_u64: u64 = @intCast(page.len);
        if (page_count == 0 or page_count > (page_len_u64 / 4096)) return null;
        var out: abi.ProgramMemoryPageIoProbe = .{};
        const table_fn = self.devFn("memory_page_io_probe") orelse return null;
        if (table_fn(path, backing_bytes, operation, region_id, region_offset, reservation_id, slot_index, page_count, owner_kind, owner_id, expected_generation, page.ptr, flags, &out) < 0) return null;
        return out;
    }

    pub fn memoryVmPageStateProbe(self: *const Context, region_id: u32, region_offset: u64, page_count: u64, operation: u32, slot_reservation_id: u32, slot_index: u64, slot_generation: u64, flags: u32) ?abi.ProgramMemoryVmPageStateProbe {
        var out: abi.ProgramMemoryVmPageStateProbe = .{};
        const table_fn = self.devFn("memory_vm_page_state_probe") orelse return null;
        if (table_fn(region_id, region_offset, page_count, operation, slot_reservation_id, slot_index, slot_generation, flags, &out) < 0) return null;
        return out;
    }

    pub fn performanceSummary(self: *const Context) ?abi.ProgramPerformanceSummary {
        var out: abi.ProgramPerformanceSummary = .{};
        const table_fn = self.devFn("performance_summary") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn programInstanceStorageSummary(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        out.* = .{};
        out.version = 2;
        out.size = @sizeOf(abi.ProgramInstanceStorageSummary);
        if (self.devFn("program_instance_storage_summary_v2")) |table_fn| return table_fn(out);
        return self.programInstanceStorageSummaryLegacy(out);
    }

    pub fn programInstanceStorageSummaryLegacy(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        const table_fn = self.devFn("program_instance_storage_summary") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programInstanceStorageSummaryV2(self: *const Context, out: *abi.ProgramInstanceStorageSummary) i32 {
        const table_fn = self.devFn("program_instance_storage_summary_v2") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programInstanceStorageSelfTest(self: *const Context, out: *abi.ProgramInstanceStorageSelfTestResult) i32 {
        const table_fn = self.devFn("program_instance_storage_self_test") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programRegistrySummary(self: *const Context, out: *abi.ProgramRegistrySummary) i32 {
        const table_fn = self.devFn("program_registry_summary") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programRegistrySelfTest(self: *const Context, out: *abi.ProgramRegistrySelfTestResult) i32 {
        const table_fn = self.devFn("program_registry_self_test") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programRegistrySummaryV2(self: *const Context, out: *abi.ProgramRegistrySummaryV2) i32 {
        const table_fn = self.devFn("program_registry_summary_v2") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programRegistrySelfTestV2(self: *const Context, out: *abi.ProgramRegistrySelfTestResultV2) i32 {
        const table_fn = self.devFn("program_registry_self_test_v2") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn executionInventorySummary(self: *const Context, out: *abi.ProgramInventorySummary) i32 {
        const table_fn = self.devFn("execution_inventory_summary") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn kernelVersion(self: *const Context, out: *abi.KernelVersion) i32 {
        const table_fn = self.devFn("kernel_version") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn programRegistrySummaryLegacy(self: *const Context, out: *abi.ProgramRegistrySummary) i32 {
        return self.programRegistrySummary(out);
    }

    pub fn programRegistrySelfTestLegacy(self: *const Context, out: *abi.ProgramRegistrySelfTestResult) i32 {
        return self.programRegistrySelfTest(out);
    }

    pub fn performanceTask(self: *const Context, index: u32) ?abi.ProgramTaskPerformanceInfo {
        var out: abi.ProgramTaskPerformanceInfo = .{};
        const table_fn = self.devFn("performance_task") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn performanceStorage(self: *const Context, index: u32) ?abi.ProgramStoragePerformanceInfo {
        var out: abi.ProgramStoragePerformanceInfo = .{};
        const table_fn = self.devFn("performance_storage") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn performanceBootPhase(self: *const Context, index: u32) ?abi.ProgramBootPhasePerformanceInfo {
        var out: abi.ProgramBootPhasePerformanceInfo = .{};
        const table_fn = self.devFn("performance_boot_phase") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn performanceBootPhaseClock(self: *const Context, index: u32) ?abi.ProgramBootPhaseClockInfo {
        var out: abi.ProgramBootPhaseClockInfo = .{};
        const table_fn = self.devFn("performance_boot_phase_clock") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn performanceBootSummary(self: *const Context) ?abi.ProgramBootPerformanceInfo {
        var out: abi.ProgramBootPerformanceInfo = .{};
        const table_fn = self.devFn("performance_boot_summary") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn performanceDriverWork(self: *const Context, owner: u32) ?abi.ProgramDriverWorkPerformanceInfo {
        var out: abi.ProgramDriverWorkPerformanceInfo = .{};
        const table_fn = self.devFn("performance_driver_work") orelse return null;
        if (table_fn(owner, &out) <= 0) return null;
        return out;
    }

    pub fn performancePciInventory(self: *const Context) ?abi.ProgramPciInventoryPerformanceInfo {
        var out: abi.ProgramPciInventoryPerformanceInfo = .{};
        const table_fn = self.devFn("performance_pci_inventory") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn performanceInput(self: *const Context) ?abi.ProgramInputPerformanceInfo {
        var out: abi.ProgramInputPerformanceInfo = .{};
        const table_fn = self.devFn("performance_input") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn performanceIrqTiming(self: *const Context, irq: u32) ?abi.ProgramIrqTimingInfo {
        var out: abi.ProgramIrqTimingInfo = .{};
        const table_fn = self.devFn("performance_irq_timing") orelse return null;
        if (table_fn(irq, &out) <= 0) return null;
        return out;
    }

    pub fn memoryVmReserveProbe(self: *const Context, requested_bytes: u64) ?abi.ProgramVmReserveProbe {
        var out: abi.ProgramVmReserveProbe = .{};
        const table_fn = self.devFn("memory_vm_reserve_probe") orelse return null;
        if (table_fn(requested_bytes, &out) != 0) return null;
        return out;
    }

    pub fn vmReserve(self: *const Context, size: u64, alignment: u64, flags: u64) ?abi.ProgramVmRegionInfo {
        var out: abi.ProgramVmRegionInfo = .{};
        if (self.vmReserveRaw(size, alignment, flags, &out) != abi.vm_ok) return null;
        return out;
    }

    pub fn vmReserveRaw(self: *const Context, size: u64, alignment: u64, flags: u64, out: *abi.ProgramVmRegionInfo) i32 {
        if (!self.hasSysFn("vm_reserve")) {
            out.* = .{};
            return abi.vm_error_no_instance;
        }
        const table_fn = self.sysFn("vm_reserve") orelse return self.unavailable("sys");
        return table_fn(size, alignment, flags, out);
    }

    pub fn vmCommit(self: *const Context, region_id: u32, offset: u64, len: u64) i32 {
        return self.vmCommitFlags(region_id, offset, len, 0);
    }

    pub fn vmCommitFlags(self: *const Context, region_id: u32, offset: u64, len: u64, flags: u64) i32 {
        const table_fn = self.sysFn("vm_commit") orelse return self.unavailable("sys");
        return table_fn(region_id, offset, len, flags);
    }

    pub fn vmDecommit(self: *const Context, region_id: u32, offset: u64, len: u64) i32 {
        const table_fn = self.sysFn("vm_decommit") orelse return self.unavailable("sys");
        return table_fn(region_id, offset, len);
    }

    pub fn vmRelease(self: *const Context, region_id: u32) i32 {
        const table_fn = self.sysFn("vm_release") orelse return self.unavailable("sys");
        return table_fn(region_id);
    }

    pub fn vmQuery(self: *const Context, region_id: u32) ?abi.ProgramVmRegionInfo {
        var out: abi.ProgramVmRegionInfo = .{};
        if (self.vmQueryRaw(region_id, &out) != abi.vm_ok) return null;
        return out;
    }

    pub fn vmQueryRaw(self: *const Context, region_id: u32, out: *abi.ProgramVmRegionInfo) i32 {
        const table_fn = self.sysFn("vm_query") orelse return self.unavailable("sys");
        return table_fn(region_id, out);
    }

    pub fn pagingSummary(self: *const Context) ?abi.PagingSummary {
        var out: abi.PagingSummary = .{};
        const table_fn = self.devFn("paging_summary") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn displaySummary(self: *const Context) ?abi.DisplaySummary {
        var out: abi.DisplaySummary = .{};
        const table_fn = self.devFn("display_summary") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn hardwareSummary(self: *const Context) ?abi.HardwareSummary {
        var out: abi.HardwareSummary = .{};
        const table_fn = self.devFn("hardware_summary") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn bootInfoSummary(self: *const Context) ?abi.BootInfoSummary {
        var out: abi.BootInfoSummary = .{};
        const table_fn = self.devFn("boot_info_summary") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn bootInfoMemoryCount(self: *const Context) u32 {
        const table_fn = self.devFn("boot_info_memory_count") orelse return 0;
        return table_fn();
    }

    pub fn bootInfoMemoryEntry(self: *const Context, index: u32) ?abi.BootInfoMemoryEntry {
        var out: abi.BootInfoMemoryEntry = .{};
        const table_fn = self.devFn("boot_info_memory_entry") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn print(self: *const Context, value: [*:0]const u8) void {
        const write_fn = self.sysFn("write") orelse return;
        var len: usize = 0;
        while (value[len] != 0) : (len += 1) {}
        if (len == 0) return;
        _ = write_fn(value, @intCast(len));
    }

    pub fn putc(self: *const Context, ch: u8) void {
        if (self.sysFn("putc")) |table_fn| table_fn(ch);
    }

    pub fn write(self: *const Context, value: []const u8) void {
        if (value.len == 0) return;
        if (self.sysFn("write")) |write_fn| {
            var offset: usize = 0;
            while (offset < value.len) {
                const count = @min(value.len - offset, std.math.maxInt(i32));
                const written = write_fn(value[offset..].ptr, @intCast(count));
                if (written <= 0) {
                    for (value[offset..]) |ch| self.putc(ch);
                    return;
                }
                offset += @min(count, @as(usize, @intCast(written)));
            }
            return;
        }
        for (value) |ch| self.putc(ch);
    }

    pub fn println(self: *const Context, value: []const u8) void {
        self.write(value);
        self.write("\r\n");
    }

    pub fn clear(self: *const Context, rgb: u32) void {
        if (self.drawFn("clear")) |table_fn| table_fn(rgb);
    }

    pub fn rect(self: *const Context, x: i32, y: i32, w: u32, h: u32, rgb: u32) void {
        if (self.drawFn("rect")) |table_fn| table_fn(x, y, w, h, rgb);
    }

    pub fn text(self: *const Context, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) void {
        if (self.drawFn("text")) |table_fn| table_fn(x, y, value, fg, bg);
    }

    pub fn screenWidth(self: *const Context) u32 {
        const table_fn = self.drawFn("screen_width") orelse return 0;
        return table_fn();
    }

    pub fn screenHeight(self: *const Context) u32 {
        const table_fn = self.drawFn("screen_height") orelse return 0;
        return table_fn();
    }

    pub fn mouseState(self: *const Context, out: *abi.Mouse) void {
        if (self.deskFn("mouse_state")) |table_fn| table_fn(out);
    }

    pub fn mouseShow(self: *const Context) void {
        if (self.deskFn("mouse_show")) |table_fn| table_fn();
    }

    pub fn mouseHide(self: *const Context) void {
        if (self.deskFn("mouse_hide")) |table_fn| table_fn();
    }

    pub fn argsRaw(self: *const Context) [*:0]const u8 {
        const b = self.bundle orelse return "";
        if (b.raw.args == 0) return "";
        return @ptrFromInt(b.raw.args);
    }

    pub fn envGet(self: *const Context, name: [*:0]const u8, out: []u8) i32 {
        const table_fn = self.sysFn("env_get") orelse return self.unavailable("sys");
        return table_fn(name, out.ptr, @intCast(out.len));
    }

    pub fn envSet(self: *const Context, name: [*:0]const u8, value: []const u8) i32 {
        const table_fn = self.sysFn("env_set") orelse return self.unavailable("sys");
        return table_fn(name, value.ptr, @intCast(value.len));
    }

    pub fn readKey(self: *const Context) u8 {
        const table_fn = self.deskFn("read_key") orelse return 0;
        return table_fn();
    }

    pub fn readKeyCodepoint(self: *const Context) u32 {
        const table_fn = self.deskFn("read_key_codepoint") orelse return self.readKey();
        return table_fn();
    }

    pub fn keyboardLayoutCurrent(self: *const Context, out: *abi.KeyboardLayoutInfo) i32 {
        const table_fn = self.deskFn("keyboard_layout_current") orelse return self.unavailable("desk");
        return table_fn(out);
    }

    pub fn keyboardLayoutAt(self: *const Context, index: u32, out: *abi.KeyboardLayoutInfo) i32 {
        const table_fn = self.deskFn("keyboard_layout_at") orelse return self.unavailable("desk");
        return table_fn(index, out);
    }

    pub fn keyboardLayoutSet(self: *const Context, name: [*:0]const u8) i32 {
        const table_fn = self.deskFn("keyboard_layout_set") orelse return self.unavailable("desk");
        return table_fn(name);
    }

    pub fn ticks(self: *const Context) u64 {
        const table_fn = self.sysFn("ticks") orelse return 0;
        return table_fn();
    }

    pub fn sleepTicks(self: *const Context, duration: u64) void {
        if (self.sysFn("sleep_ticks")) |table_fn| table_fn(duration);
    }

    pub fn timeSecondsSinceMidnight(self: *const Context) u32 {
        const table_fn = self.sysFn("time_seconds_since_midnight") orelse return 0;
        return table_fn();
    }

    pub fn timeState(self: *const Context) abi.TimeState {
        var out: abi.TimeState = .{};
        if (self.sysFn("time_state")) |table_fn| table_fn(&out);
        return out;
    }

    pub fn timeSetState(self: *const Context, next: *const abi.TimeState) i32 {
        const table_fn = self.sysFn("time_set_state") orelse return self.unavailable("sys");
        return table_fn(next);
    }

    pub fn monotonicClock(self: *const Context, out: *abi.MonotonicClockInfo) i32 {
        out.* = .{};
        const table_fn = self.sysFn("monotonic_clock") orelse return self.unavailable("sys");
        return table_fn(out);
    }

    pub fn bootReady(self: *const Context) i32 {
        const table_fn = self.sysFn("boot_ready") orelse return abi.boot_ready_error_not_boot_shell;
        return table_fn();
    }

    pub fn monotonicNanoseconds(self: *const Context) ?u64 {
        var clock: abi.MonotonicClockInfo = .{};
        if (self.monotonicClock(&clock) <= 0) return null;
        if ((clock.flags & abi.monotonic_clock_flag_valid) == 0 or
            clock.frequency_hz != abi.monotonic_clock_frequency_hz)
        {
            return null;
        }
        return clock.instant_ns;
    }

    pub fn bootLogInfo(self: *const Context) ?abi.BootLogInfo {
        var out: abi.BootLogInfo = .{};
        const table_fn = self.sysFn("boot_log_info") orelse return null;
        if (table_fn(&out) <= 0) return null;
        return out;
    }

    pub fn bootLogRead(self: *const Context, offset: u32, out: []u8) i32 {
        if (out.len == 0) return 0;
        const table_fn = self.sysFn("boot_log_read") orelse return self.unavailable("sys");
        return table_fn(offset, out.ptr, @intCast(out.len));
    }

    pub fn monotonicHz(self: *const Context) u32 {
        var clock: abi.MonotonicClockInfo = .{};
        if (self.monotonicClock(&clock) > 0 and clock.event_effective_hz != 0)
            return clock.event_effective_hz;
        return self.timeState().monotonic_hz;
    }

    pub fn ticksFromMilliseconds(self: *const Context, ms: u64) u64 {
        const hz_raw = self.monotonicHz();
        const hz: u64 = if (hz_raw == 0) 100 else hz_raw;
        const ticks_value = (ms * hz + 999) / 1000;
        return if (ticks_value == 0) 1 else ticks_value;
    }

    pub fn monotonicBackend(self: *const Context) abi.TimeBackend {
        var clock: abi.MonotonicClockInfo = .{};
        const raw = if (self.monotonicClock(&clock) > 0)
            clock.event_backend
        else
            self.timeState().monotonic_backend;
        return switch (raw) {
            0 => .pit,
            1 => .hpet,
            2 => .lapic,
            else => .pit,
        };
    }

    pub fn systemHalt(self: *const Context) noreturn {
        if (self.sysFn("system_halt")) |table_fn| table_fn();
        while (true) self.taskYield();
    }

    pub fn systemReboot(self: *const Context) noreturn {
        if (self.sysFn("system_reboot")) |table_fn| table_fn();
        while (true) self.taskYield();
    }

    pub fn programRun(self: *const Context, path: [*:0]const u8, args: [*:0]const u8) i32 {
        const table_fn = self.sysFn("program_run") orelse return self.unavailable("sys");
        return table_fn(path, args);
    }

    pub fn programLaunch(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        const table_fn = self.sysFn("program_launch") orelse return self.unavailable("sys");
        return table_fn(path, args, @intFromEnum(policy));
    }

    pub fn programSpawn(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        const table_fn = self.sysFn("program_spawn") orelse return self.unavailable("sys");
        return table_fn(path, args, @intFromEnum(policy));
    }

    pub fn programSpawnHandle(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, out_handle: *abi.ProgramProcessHandle) i32 {
        const table_fn = self.sysFn("program_spawn_handle") orelse return self.unavailable("sys");
        return table_fn(path, args, @intFromEnum(policy), out_handle);
    }

    pub fn programOpenHandle(self: *const Context, instance_id: u32, out_handle: *abi.ProgramProcessHandle) i32 {
        const table_fn = self.sysFn("program_open_handle") orelse return self.unavailable("sys");
        return table_fn(instance_id, out_handle);
    }

    pub fn programHandleStatus(self: *const Context, handle: *const abi.ProgramProcessHandle, out: *abi.ProgramInstanceInfo) i32 {
        const table_fn = self.sysFn("program_handle_status") orelse return self.unavailable("sys");
        return table_fn(handle, out);
    }

    pub fn programHandleRequestClose(self: *const Context, handle: *const abi.ProgramProcessHandle) i32 {
        const table_fn = self.sysFn("program_handle_request_close") orelse return self.unavailable("sys");
        return table_fn(handle);
    }

    pub fn programHandleKill(self: *const Context, handle: *const abi.ProgramProcessHandle) i32 {
        const table_fn = self.sysFn("program_handle_kill") orelse return self.unavailable("sys");
        return table_fn(handle);
    }

    pub fn programHandleWait(self: *const Context, handle: *const abi.ProgramProcessHandle, timeout_ticks: u64, out: *abi.ProgramProcessCompletion) i32 {
        const table_fn = self.sysFn("program_handle_wait") orelse return self.unavailable("sys");
        return table_fn(handle, timeout_ticks, out);
    }

    pub fn programHandleReap(self: *const Context, handle: *const abi.ProgramProcessHandle, out: *abi.ProgramProcessCompletion) i32 {
        const table_fn = self.sysFn("program_handle_reap") orelse return self.unavailable("sys");
        return table_fn(handle, out);
    }

    pub fn programCompletionRead(self: *const Context, handle: *const abi.ProgramProcessHandle, offset: u32, out: []u8, out_read: *u32) i32 {
        if (out.len > std.math.maxInt(u32)) return abi.program_handle_error_output_range;
        const table_fn = self.sysFn("program_completion_read") orelse return self.unavailable("sys");
        return table_fn(handle, offset, out.ptr, @intCast(out.len), out_read);
    }

    pub fn programSpawnWithConsoleHost(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind) i32 {
        const table_fn = self.deskFn("program_spawn_with_console_host") orelse return self.unavailable("desk");
        return table_fn(path, args, @intFromEnum(policy), @intFromEnum(host));
    }

    pub fn programSpawnWithConsoleHostHandle(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind, out_handle: *abi.ProgramProcessHandle) i32 {
        const table_fn = self.deskFn("program_spawn_with_console_host_handle") orelse return self.unavailable("desk");
        return table_fn(path, args, @intFromEnum(policy), @intFromEnum(host), out_handle);
    }

    pub fn programReapInstance(self: *const Context, instance_id: u32) i32 {
        const table_fn = self.sysFn("program_reap_instance") orelse return self.unavailable("sys");
        return table_fn(instance_id);
    }

    pub fn programRequestClose(self: *const Context, instance_id: u32) i32 {
        const table_fn = self.sysFn("program_request_close") orelse return self.unavailable("sys");
        return table_fn(instance_id);
    }

    pub fn programShouldClose(self: *const Context) bool {
        const table_fn = self.sysFn("program_should_close") orelse return false;
        return table_fn() != 0;
    }

    pub fn programKill(self: *const Context, instance_id: u32) i32 {
        const table_fn = self.sysFn("program_kill") orelse return self.unavailable("sys");
        return table_fn(instance_id);
    }

    pub fn programInstance(self: *const Context, index: u32, out: *abi.ProgramInstanceInfo) i32 {
        const table_fn = self.sysFn("program_instance") orelse return self.unavailable("sys");
        return table_fn(index, out);
    }

    pub fn programInventoryBegin(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: *abi.ProgramInventorySummary) i32 {
        const table_fn = self.sysFn("program_inventory_begin") orelse return self.unavailable("sys");
        return table_fn(cursor, out);
    }

    pub fn programInventoryPrograms(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramInstanceSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        if (out.len == 0 or out.len > @as(usize, abi.program_inventory_page_max)) return abi.program_handle_error_invalid;
        const table_fn = self.sysFn("program_inventory_programs") orelse return self.unavailable("sys");
        return table_fn(cursor, out.ptr, @intCast(out.len), page);
    }

    pub fn programInventoryTasks(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramTaskSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        if (out.len == 0 or out.len > @as(usize, abi.program_inventory_page_max)) return abi.program_handle_error_invalid;
        const table_fn = self.sysFn("program_inventory_tasks") orelse return self.unavailable("sys");
        return table_fn(cursor, out.ptr, @intCast(out.len), page);
    }

    pub fn programInventoryThreads(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramThreadSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        if (out.len == 0 or out.len > @as(usize, abi.program_inventory_page_max)) return abi.program_handle_error_invalid;
        const table_fn = self.sysFn("program_inventory_threads") orelse return self.unavailable("sys");
        return table_fn(cursor, out.ptr, @intCast(out.len), page);
    }

    pub fn threadCreateRaw(self: *const Context, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64, flags: u32, out_thread_id: *u32) i32 {
        const table_fn = self.sysFn("thread_create") orelse return self.unavailable("sys");
        return table_fn(entry, arg, stack_reserve_bytes, flags, out_thread_id);
    }

    pub fn threadCreate(self: *const Context, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64) ?u32 {
        var id: u32 = 0;
        if (self.threadCreateRaw(entry, arg, stack_reserve_bytes, 0, &id) != abi.thread_ok) return null;
        return id;
    }

    pub fn threadCreateHandle(self: *const Context, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64, flags: u32, out_handle: *abi.ProgramJoinHandle) i32 {
        const table_fn = self.sysFn("thread_create_handle") orelse return self.unavailable("sys");
        return table_fn(entry, arg, stack_reserve_bytes, flags, out_handle);
    }

    pub fn threadExit(self: *const Context, exit_code: i32) noreturn {
        if (self.sysFn("thread_exit")) |table_fn| table_fn(exit_code);
        while (true) self.taskYield();
    }

    pub fn threadJoin(self: *const Context, thread_id: u32, timeout_ticks: u64, out_exit_code: *i32) i32 {
        const table_fn = self.sysFn("thread_join") orelse return self.unavailable("sys");
        return table_fn(thread_id, timeout_ticks, out_exit_code);
    }

    pub fn threadHandleJoin(self: *const Context, handle: *const abi.ProgramJoinHandle, timeout_ticks: u64, out_exit_code: *i32) i32 {
        const table_fn = self.sysFn("thread_handle_join") orelse return self.unavailable("sys");
        return table_fn(handle, timeout_ticks, out_exit_code);
    }

    pub fn threadJoinTimeout(self: *const Context, thread_id: u32, timeout: time_contract.Timeout, out_exit_code: *i32) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.thread_error_invalid;
        return self.threadJoin(thread_id, timeout_ticks_value, out_exit_code);
    }

    pub fn threadCurrent(self: *const Context) u32 {
        const table_fn = self.sysFn("thread_current") orelse return 0;
        return table_fn();
    }

    pub fn threadStatus(self: *const Context, thread_id: u32, out: *abi.ProgramThreadInfo) i32 {
        const table_fn = self.sysFn("thread_status") orelse return self.unavailable("sys");
        return table_fn(thread_id, out);
    }

    pub fn threadHandleStatus(self: *const Context, handle: *const abi.ProgramJoinHandle, out: *abi.ProgramThreadInfo) i32 {
        const table_fn = self.sysFn("thread_handle_status") orelse return self.unavailable("sys");
        return table_fn(handle, out);
    }

    pub fn ioFileRead(self: *const Context, path: [*:0]const u8, out: []u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_read") orelse return self.unavailable("sys");
        return table_fn(path, out.ptr, @intCast(out.len), flags, out_request_id);
    }

    pub fn ioFileReadAt(self: *const Context, path: [*:0]const u8, offset: u64, out: []u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_read_at") orelse return self.unavailable("sys");
        return table_fn(path, offset, out.ptr, @intCast(out.len), flags, out_request_id);
    }

    pub fn ioFileWrite(self: *const Context, path: [*:0]const u8, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_write") orelse return self.unavailable("sys");
        return table_fn(path, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileAppend(self: *const Context, path: [*:0]const u8, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_append") orelse return self.unavailable("sys");
        return table_fn(path, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileWriteAt(self: *const Context, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_write_at") orelse return self.unavailable("sys");
        return table_fn(path, offset, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileInfo(self: *const Context, path: [*:0]const u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_info") orelse return self.unavailable("sys");
        return table_fn(path, flags, out_request_id);
    }

    pub fn ioFileLock(self: *const Context, path: [*:0]const u8, offset: u64, length: u64, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_lock") orelse return self.unavailable("sys");
        return table_fn(path, offset, length, flags, out_request_id);
    }

    pub fn ioFileStreamBegin(self: *const Context, path: [*:0]const u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_stream_begin") orelse return self.unavailable("sys");
        return table_fn(path, flags, out_request_id);
    }

    pub fn ioFileStreamWrite(self: *const Context, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_stream_write") orelse return self.unavailable("sys");
        return table_fn(path, offset, data.ptr, @intCast(data.len), flags, out_request_id);
    }

    pub fn ioFileStreamFinish(self: *const Context, path: [*:0]const u8, expected_size: u64, flags: u32, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_stream_finish") orelse return self.unavailable("sys");
        return table_fn(path, expected_size, flags, out_request_id);
    }

    pub fn ioFileStreamAbort(self: *const Context, path: [*:0]const u8, out_request_id: *u32) i32 {
        const table_fn = self.sysFn("io_file_stream_abort") orelse return self.unavailable("sys");
        return table_fn(path, out_request_id);
    }

    pub fn ioServiceCall(self: *const Context, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout_ticks: u64, flags: u32, out_request_id: *u32) i32 {
        if (request.len > abi.service_api_max_payload) return abi.service_api_result_payload_too_large;
        if (response.len > abi.service_api_max_payload) return abi.service_api_result_invalid;
        const table_fn = self.sysFn("io_service_call") orelse return self.unavailable("sys");
        return table_fn(handle, op, request.ptr, @intCast(request.len), response_header, response.ptr, @intCast(response.len), timeout_ticks, flags, out_request_id);
    }

    pub fn ioStatus(self: *const Context, request_id: u32, out: *abi.ProgramIoInfo) i32 {
        const table_fn = self.sysFn("io_status") orelse return self.unavailable("sys");
        return table_fn(request_id, out);
    }

    pub fn ioWait(self: *const Context, request_id: u32, timeout_ticks: u64, out: *abi.ProgramIoInfo) i32 {
        const table_fn = self.sysFn("io_wait") orelse return self.unavailable("sys");
        return table_fn(request_id, timeout_ticks, out);
    }

    pub fn ioWaitTimeout(self: *const Context, request_id: u32, timeout: time_contract.Timeout, out: *abi.ProgramIoInfo) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.io_error_invalid;
        return self.ioWait(request_id, timeout_ticks_value, out);
    }

    pub fn ioClose(self: *const Context, request_id: u32) i32 {
        const table_fn = self.sysFn("io_close") orelse return self.unavailable("sys");
        return table_fn(request_id);
    }

    pub fn programSetWindow(self: *const Context, instance_id: u32, window_id: i32) i32 {
        const table_fn = self.deskFn("program_set_window") orelse return self.unavailable("desk");
        return table_fn(instance_id, window_id);
    }

    pub fn programSetWindowHandle(self: *const Context, handle: *const abi.ProgramProcessHandle, window_id: i32) i32 {
        const table_fn = self.deskFn("program_set_window_handle") orelse return self.unavailable("desk");
        return table_fn(handle, window_id);
    }

    pub fn programSetConsoleHost(self: *const Context, instance_id: u32, host: abi.ConsoleHostKind) i32 {
        const table_fn = self.deskFn("program_set_console_host") orelse return self.unavailable("desk");
        return table_fn(instance_id, @intFromEnum(host));
    }

    pub fn programCurrentConsoleHost(self: *const Context) abi.ConsoleHostKind {
        const table_fn = self.deskFn("program_current_console_host") orelse return .none;
        return parseConsoleHostKind(table_fn());
    }

    pub fn programRequestDesktop(self: *const Context) i32 {
        const table_fn = self.deskFn("program_request_desktop") orelse return self.unavailable("desk");
        return table_fn();
    }

    pub fn programRequestHostLaunch(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        const table_fn = self.deskFn("program_request_host_launch") orelse return self.unavailable("desk");
        return table_fn(path, args, @intFromEnum(policy));
    }

    pub fn programTakeHostLaunch(self: *const Context, instance_id: u32, out: *abi.ProgramHostLaunchRequest) i32 {
        const table_fn = self.deskFn("program_take_host_launch") orelse return self.unavailable("desk");
        return table_fn(instance_id, out);
    }

    pub fn programWindowId(self: *const Context) i32 {
        const table_fn = self.deskFn("program_window_id") orelse return self.unavailable("desk");
        return table_fn();
    }

    pub fn guiWindowInfo(self: *const Context, out: *abi.GuiWindowInfo) i32 {
        const table_fn = self.deskFn("gui_window_info") orelse return self.unavailable("desk");
        return table_fn(out);
    }

    pub fn guiSetWindowInfo(self: *const Context, instance_id: u32, info: *const abi.GuiWindowInfo) i32 {
        const table_fn = self.deskFn("gui_set_window_info") orelse return self.unavailable("desk");
        return table_fn(instance_id, info);
    }

    pub fn guiPollEvent(self: *const Context, out: *abi.GuiEvent) i32 {
        const table_fn = self.deskFn("gui_poll_event") orelse return self.unavailable("desk");
        return table_fn(out);
    }

    pub fn guiPushEvent(self: *const Context, instance_id: u32, event: *const abi.GuiEvent) i32 {
        const table_fn = self.deskFn("gui_push_event") orelse return self.unavailable("desk");
        return table_fn(instance_id, event);
    }

    pub fn guiSetText(self: *const Context, value: [*:0]const u8) i32 {
        const table_fn = self.deskFn("gui_set_text") orelse return self.unavailable("desk");
        return table_fn(value);
    }

    pub fn guiText(self: *const Context, instance_id: u32, out: []u8) i32 {
        const table_fn = self.deskFn("gui_text") orelse return self.unavailable("desk");
        return table_fn(instance_id, out.ptr, @intCast(out.len));
    }

    pub fn guiRevision(self: *const Context, instance_id: u32) u32 {
        const table_fn = self.deskFn("gui_revision") orelse return 0;
        return table_fn(instance_id);
    }

    pub fn programClass(self: *const Context, path: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        const table_fn = self.sysFn("program_class") orelse return self.unavailable("sys");
        return table_fn(path, @intFromEnum(policy));
    }

    pub fn guiClear(self: *const Context, rgb: u32) i32 {
        const table_fn = self.drawFn("gui_clear") orelse return self.unavailable("draw");
        return table_fn(rgb);
    }

    pub fn guiRect(self: *const Context, x: i32, y: i32, w: u32, h: u32, rgb: u32) i32 {
        const table_fn = self.drawFn("gui_rect") orelse return self.unavailable("draw");
        return table_fn(x, y, w, h, rgb);
    }

    pub fn guiDrawText(self: *const Context, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) i32 {
        const table_fn = self.drawFn("gui_draw_text") orelse return self.unavailable("draw");
        return table_fn(x, y, value, fg, bg);
    }

    pub fn guiCommand(self: *const Context, instance_id: u32, index: u32, out: *abi.GuiCommand) i32 {
        const table_fn = self.deskFn("gui_command") orelse return self.unavailable("desk");
        return table_fn(instance_id, index, out);
    }

    pub fn guiBlit(self: *const Context, x: i32, y: i32, w: u32, h: u32, scale: u32, pixels: []const u32) i32 {
        if (pixels.len == 0) return -1;
        const table_fn = self.drawFn("gui_blit") orelse return self.unavailable("draw");
        return table_fn(x, y, w, h, scale, pixels.ptr, @intCast(pixels.len));
    }

    pub fn guiBlendAlpha8(self: *const Context, x: i32, y: i32, w: u32, h: u32, stride: u32, rgb: u32, alpha: []const u8) i32 {
        if (alpha.len == 0 or alpha.len > std.math.maxInt(u32)) return -1;
        const table_fn = self.drawFn("gui_blend_alpha8") orelse return self.unavailable("draw");
        return table_fn(x, y, w, h, stride, rgb, alpha.ptr, @intCast(alpha.len));
    }

    pub fn guiRasterRead(self: *const Context, instance_id: u32, offset: u32, out: []u32) i32 {
        if (out.len == 0) return 0;
        const table_fn = self.drawFn("gui_raster_read") orelse return self.unavailable("draw");
        return table_fn(instance_id, offset, out.ptr, @intCast(out.len));
    }

    pub fn supportsGuiFrameContract(self: *const Context) bool {
        return self.hasDrawFn("gui_frame_begin") and
            self.hasDrawFn("gui_frame_append") and
            self.hasDrawFn("gui_frame_commit") and
            self.hasDrawFn("gui_frame_cancel") and
            self.hasDrawFn("gui_frame_info") and
            self.hasDrawFn("gui_frame_read");
    }

    pub fn supportsGuiFrameDamageContract(self: *const Context) bool {
        return self.supportsGuiFrameContract() and
            self.hasDrawFn("gui_frame_begin_damage") and
            self.hasDrawFn("gui_frame_generation_info") and
            self.hasDrawFn("gui_frame_generation_read");
    }

    pub fn supportsGuiFrameStreamingContract(self: *const Context) bool {
        return self.supportsGuiFrameDamageContract() and
            self.hasDrawFn("gui_frame_begin_replace") and
            self.hasDrawFn("gui_frame_stream_info");
    }

    pub fn supportsGuiSharedRasterContract(self: *const Context) bool {
        return self.supportsGuiFrameStreamingContract() and
            self.hasDrawFn("gui_shared_raster_create") and
            self.hasDrawFn("gui_shared_raster_destroy") and
            self.hasDrawFn("gui_shared_raster_map_write") and
            self.hasDrawFn("gui_shared_raster_publish") and
            self.hasDrawFn("gui_shared_raster_acquire") and
            self.hasDrawFn("gui_shared_raster_release");
    }

    pub fn guiFrameBegin(self: *const Context) i32 {
        const table_fn = self.drawFn("gui_frame_begin") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn guiFrameBeginDamage(self: *const Context, regions: []const abi.DisplayDamageRect) i32 {
        if (regions.len == 0 or regions.len > abi.gui_frame_max_damage_regions) return abi.gui_frame_error_invalid;
        const table_fn = self.drawFn("gui_frame_begin_damage") orelse return self.unavailable("draw");
        return table_fn(regions.ptr, @intCast(regions.len));
    }

    pub fn guiFrameBeginReplace(self: *const Context, regions: []const abi.DisplayDamageRect) i32 {
        if (regions.len == 0 or regions.len > abi.gui_frame_max_damage_regions) return abi.gui_frame_error_invalid;
        const table_fn = self.drawFn("gui_frame_begin_replace") orelse return self.unavailable("draw");
        return table_fn(regions.ptr, @intCast(regions.len));
    }

    pub fn guiFrameAppend(self: *const Context, commands: []const abi.GuiFrameCommand, resources: []const u8) i32 {
        const table_fn = self.drawFn("gui_frame_append") orelse return self.unavailable("draw");
        const command_ptr: ?[*]const abi.GuiFrameCommand = if (commands.len == 0) null else commands.ptr;
        const resource_ptr: ?[*]const u8 = if (resources.len == 0) null else resources.ptr;
        return table_fn(command_ptr, @intCast(commands.len), resource_ptr, @intCast(resources.len));
    }

    pub fn guiFrameCommit(self: *const Context) i32 {
        const table_fn = self.drawFn("gui_frame_commit") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn guiFrameCancel(self: *const Context) i32 {
        const table_fn = self.drawFn("gui_frame_cancel") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn guiFrameInfo(self: *const Context, handle: ?*const abi.ProgramProcessHandle, out: *abi.GuiFrameInfo) i32 {
        const table_fn = self.drawFn("gui_frame_info") orelse return self.unavailable("draw");
        out.version = abi.gui_frame_info_version;
        out.size = abi.gui_frame_info_size;
        return table_fn(handle, out);
    }

    pub fn guiFrameRead(self: *const Context, handle: *const abi.ProgramProcessHandle, expected_generation: u64, commands: []abi.GuiFrameCommand, resources: []u8, out: *abi.GuiFrameInfo) i32 {
        const table_fn = self.drawFn("gui_frame_read") orelse return self.unavailable("draw");
        const command_ptr: ?[*]abi.GuiFrameCommand = if (commands.len == 0) null else commands.ptr;
        const resource_ptr: ?[*]u8 = if (resources.len == 0) null else resources.ptr;
        out.version = abi.gui_frame_info_version;
        out.size = abi.gui_frame_info_size;
        return table_fn(handle, expected_generation, command_ptr, @intCast(commands.len), resource_ptr, @intCast(resources.len), out);
    }

    pub fn guiFrameGenerationInfo(self: *const Context, handle: *const abi.ProgramProcessHandle, generation: u64, out: *abi.GuiFrameGenerationInfo) i32 {
        const table_fn = self.drawFn("gui_frame_generation_info") orelse return self.unavailable("draw");
        out.version = abi.gui_frame_generation_info_version;
        out.size = abi.gui_frame_generation_info_size;
        return table_fn(handle, generation, out);
    }

    pub fn guiFrameGenerationRead(self: *const Context, handle: *const abi.ProgramProcessHandle, generation: u64, commands: []abi.GuiFrameCommand, resources: []u8, regions: []abi.DisplayDamageRect, out: *abi.GuiFrameGenerationInfo) i32 {
        const table_fn = self.drawFn("gui_frame_generation_read") orelse return self.unavailable("draw");
        const command_ptr: ?[*]abi.GuiFrameCommand = if (commands.len == 0) null else commands.ptr;
        const resource_ptr: ?[*]u8 = if (resources.len == 0) null else resources.ptr;
        const region_ptr: ?[*]abi.DisplayDamageRect = if (regions.len == 0) null else regions.ptr;
        out.version = abi.gui_frame_generation_info_version;
        out.size = abi.gui_frame_generation_info_size;
        return table_fn(handle, generation, command_ptr, @intCast(commands.len), resource_ptr, @intCast(resources.len), region_ptr, @intCast(regions.len), out);
    }

    pub fn guiFrameStreamInfo(self: *const Context, handle: *const abi.ProgramProcessHandle, out: *abi.GuiFrameStreamInfo) i32 {
        const table_fn = self.drawFn("gui_frame_stream_info") orelse return self.unavailable("draw");
        out.version = abi.gui_frame_stream_info_version;
        out.size = abi.gui_frame_stream_info_size;
        return table_fn(handle, out);
    }

    pub fn guiSharedRasterCreate(self: *const Context, info: *const abi.GuiSharedRasterCreateInfo, out_handle: *abi.GuiSharedRasterHandle) i32 {
        const table_fn = self.drawFn("gui_shared_raster_create") orelse return self.unavailable("draw");
        return table_fn(info, out_handle);
    }

    pub fn guiSharedRasterDestroy(self: *const Context, handle: *const abi.GuiSharedRasterHandle) i32 {
        const table_fn = self.drawFn("gui_shared_raster_destroy") orelse return self.unavailable("draw");
        return table_fn(handle);
    }

    pub fn guiSharedRasterMapWrite(self: *const Context, handle: *const abi.GuiSharedRasterHandle, out_map: *abi.GuiSharedRasterWriteMap) i32 {
        const table_fn = self.drawFn("gui_shared_raster_map_write") orelse return self.unavailable("draw");
        out_map.version = abi.gui_shared_raster_write_map_version;
        out_map.size = abi.gui_shared_raster_write_map_size;
        return table_fn(handle, out_map);
    }

    pub fn guiSharedRasterPublish(self: *const Context, map: *const abi.GuiSharedRasterWriteMap, out_generation: *u64) i32 {
        const table_fn = self.drawFn("gui_shared_raster_publish") orelse return self.unavailable("draw");
        return table_fn(map, out_generation);
    }

    pub fn guiSharedRasterAcquire(
        self: *const Context,
        frame_owner: *const abi.ProgramProcessHandle,
        frame_generation: u64,
        raster_handle: *const abi.GuiSharedRasterHandle,
        raster_generation: u64,
        out_map: *abi.GuiSharedRasterMap,
    ) i32 {
        const table_fn = self.drawFn("gui_shared_raster_acquire") orelse return self.unavailable("draw");
        out_map.version = abi.gui_shared_raster_map_version;
        out_map.size = abi.gui_shared_raster_map_size;
        return table_fn(frame_owner, frame_generation, raster_handle, raster_generation, out_map);
    }

    pub fn guiSharedRasterRelease(self: *const Context, lease: *const abi.GuiSharedRasterLease) i32 {
        const table_fn = self.drawFn("gui_shared_raster_release") orelse return self.unavailable("draw");
        return table_fn(lease);
    }

    pub fn guiSetTitle(self: *const Context, value: [*:0]const u8) i32 {
        const table_fn = self.deskFn("gui_set_title") orelse return self.unavailable("desk");
        return table_fn(value);
    }

    pub fn guiTitle(self: *const Context, instance_id: u32, out: []u8) i32 {
        const table_fn = self.deskFn("gui_title") orelse return self.unavailable("desk");
        return table_fn(instance_id, out.ptr, @intCast(out.len));
    }

    pub fn guiSetMinSize(self: *const Context, w: i32, h: i32) i32 {
        const table_fn = self.deskFn("gui_set_min_size") orelse return self.unavailable("desk");
        return table_fn(w, h);
    }

    pub fn guiMinSize(self: *const Context, instance_id: u32, out: *abi.GuiSize) i32 {
        const table_fn = self.deskFn("gui_min_size") orelse return self.unavailable("desk");
        return table_fn(instance_id, out);
    }

    pub fn guiPresent(self: *const Context) i32 {
        const table_fn = self.drawFn("gui_present") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn consoleOutput(self: *const Context, instance_id: u32, out: []u8) i32 {
        const table_fn = self.deskFn("console_output") orelse return self.unavailable("desk");
        return table_fn(instance_id, out.ptr, @intCast(out.len));
    }

    pub fn consoleRevision(self: *const Context, instance_id: u32) u32 {
        const table_fn = self.deskFn("console_revision") orelse return 0;
        return table_fn(instance_id);
    }

    pub fn consoleState(self: *const Context, instance_id: u32, out: *abi.ConsoleState) i32 {
        const table_fn = self.deskFn("console_state") orelse return self.unavailable("desk");
        return table_fn(instance_id, out);
    }

    pub fn consoleSetMetrics(self: *const Context, instance_id: u32, cols: u32, rows: u32) i32 {
        const table_fn = self.deskFn("console_set_metrics") orelse return self.unavailable("desk");
        return table_fn(instance_id, cols, rows);
    }

    pub fn consolePushKey(self: *const Context, instance_id: u32, key: u8) i32 {
        const table_fn = self.deskFn("console_push_key") orelse return self.unavailable("desk");
        return table_fn(instance_id, key);
    }

    pub fn consolePushInput(self: *const Context, instance_id: u32, data: []const u8) i32 {
        if (data.len > std.math.maxInt(u32)) return -1;
        const table_fn = self.deskFn("console_push_input") orelse return self.unavailable("desk");
        const data_ptr: [*]const u8 = if (data.len == 0) @ptrCast("") else data.ptr;
        return table_fn(instance_id, data_ptr, @intCast(data.len));
    }

    pub fn consoleWrite(self: *const Context, stream: abi.ConsoleStream, data: []const u8) i32 {
        const table_fn = self.deskFn("console_write") orelse return self.unavailable("desk");
        return table_fn(@intFromEnum(stream), data.ptr, @intCast(data.len));
    }

    pub fn stdout(self: *const Context, data: []const u8) i32 {
        return self.consoleWrite(.stdout, data);
    }

    pub fn stderr(self: *const Context, data: []const u8) i32 {
        return self.consoleWrite(.stderr, data);
    }

    pub fn consoleRead(self: *const Context, out: []u8) i32 {
        const table_fn = self.deskFn("console_read") orelse return self.unavailable("desk");
        return table_fn(out.ptr, @intCast(out.len));
    }

    pub fn consoleInputWait(self: *const Context, last_generation: u64, timeout_ticks: u64, out_generation: *u64) i32 {
        out_generation.* = last_generation;
        const table_fn = self.deskFn("console_input_wait") orelse return abi.console_input_wait_error_unsupported;
        return table_fn(last_generation, timeout_ticks, out_generation);
    }

    pub fn physicalKeyPoll(self: *const Context, out: *abi.PhysicalKeyEvent) i32 {
        out.* = .{};
        const table_fn = self.deskFn("physical_key_poll") orelse return abi.physical_key_poll_error_unsupported;
        return table_fn(out);
    }

    pub fn displayRevision(self: *const Context) u32 {
        const table_fn = self.drawFn("display_revision") orelse return 0;
        return table_fn();
    }

    pub fn displayBeginFrame(self: *const Context) i32 {
        const table_fn = self.drawFn("display_begin_frame") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn displayBeginFrameRect(self: *const Context, x: i32, y: i32, w: u32, h: u32) i32 {
        const table_fn = self.drawFn("display_begin_frame_rect") orelse return self.unavailable("draw");
        return table_fn(x, y, w, h);
    }

    pub fn displayPresent(self: *const Context) i32 {
        const table_fn = self.drawFn("display_present") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn displayXrgb32Blit(self: *const Context, x: i32, y: i32, w: u32, h: u32, pixels: []const u32) i32 {
        const blit_fn = self.drawFn("display_blit_xrgb32") orelse return self.unavailable("draw");
        return blit_fn(x, y, w, h, pixels.ptr, @intCast(pixels.len));
    }

    pub fn displayXrgb32BlitStride(self: *const Context, x: i32, y: i32, w: u32, h: u32, source_stride_pixels: u32, pixels: []const u32) i32 {
        const blit_fn = self.drawFn("display_blit_xrgb32_stride") orelse return self.unavailable("draw");
        return blit_fn(x, y, w, h, pixels.ptr, @intCast(pixels.len), source_stride_pixels);
    }

    pub fn supportsDisplayPresentRegions(self: *const Context) bool {
        return self.hasDrawFn("display_present_regions") and
            self.hasDrawFn("display_present_capabilities") and
            self.hasDrawFn("display_present_completion");
    }

    pub fn displayPresentRegions(self: *const Context, request: *const abi.DisplayPresentRequest, pixels: []const u32, regions: []const abi.DisplayDamageRect, out: *abi.DisplayPresentResult) i32 {
        const present_fn = self.drawFn("display_present_regions") orelse return abi.display_present_error_unavailable;
        return present_fn(request, pixels.ptr, @intCast(pixels.len), regions.ptr, @intCast(regions.len), out);
    }

    pub fn displayPresentCapabilities(self: *const Context, out: *abi.DisplayPresentCapabilities) i32 {
        const capabilities_fn = self.drawFn("display_present_capabilities") orelse return abi.display_present_error_unavailable;
        return capabilities_fn(out);
    }

    pub fn displayPresentCompletion(self: *const Context, fence: u64, out: *abi.DisplayPresentCompletion) i32 {
        const completion_fn = self.drawFn("display_present_completion") orelse return abi.display_present_error_unavailable;
        return completion_fn(fence, out);
    }

    pub fn clipboardWrite(self: *const Context, data: []const u8) i32 {
        const table_fn = self.deskFn("clipboard_write") orelse return self.unavailable("desk");
        return table_fn(data.ptr, @intCast(data.len));
    }

    pub fn clipboardRead(self: *const Context, out: []u8) i32 {
        const table_fn = self.deskFn("clipboard_read") orelse return self.unavailable("desk");
        return table_fn(out.ptr, @intCast(out.len));
    }

    pub fn clipboardRevision(self: *const Context) u32 {
        const table_fn = self.deskFn("clipboard_revision") orelse return 0;
        return table_fn();
    }

    pub fn clipboardInfo(self: *const Context, out: *abi.ClipboardInfo) i32 {
        const table_fn = self.deskFn("clipboard_info") orelse return self.unavailable("desk");
        return table_fn(out);
    }

    pub fn clipboardClear(self: *const Context) i32 {
        const table_fn = self.deskFn("clipboard_clear") orelse return self.unavailable("desk");
        return table_fn();
    }

    pub fn supportsRemoteFrame(self: *const Context) bool {
        return self.hasDeskFn("remote_frame_info") and
            self.hasDeskFn("remote_frame_read") and
            self.hasDeskFn("remote_frame_wait") and
            self.hasDeskFn("remote_frame_publish");
    }

    pub fn remoteFrameInfo(self: *const Context, out: *abi.RemoteFrameInfo) i32 {
        const table_fn = self.deskFn("remote_frame_info") orelse return abi.remote_frame_error_unsupported;
        return table_fn(out);
    }

    pub fn remoteFrameRead(self: *const Context, offset_pixels: u32, out: []u32, out_info: *abi.RemoteFrameInfo) i32 {
        const table_fn = self.deskFn("remote_frame_read") orelse return abi.remote_frame_error_unsupported;
        return table_fn(offset_pixels, out.ptr, @intCast(out.len), out_info);
    }

    pub fn remoteFrameWait(self: *const Context, last_revision: u32, timeout_ticks: u64, out: *abi.RemoteFrameInfo) i32 {
        const table_fn = self.deskFn("remote_frame_wait") orelse return abi.remote_frame_error_unsupported;
        return table_fn(last_revision, timeout_ticks, out);
    }

    pub fn remoteFrameWaitTimeout(self: *const Context, last_revision: u32, timeout: time_contract.Timeout, out: *abi.RemoteFrameInfo) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.remote_frame_error_invalid;
        return self.remoteFrameWait(last_revision, timeout_ticks_value, out);
    }

    pub fn desktopActivityWait(self: *const Context, last_seq: u64, timeout_ticks: u64, out_seq: *u64) i32 {
        const table_fn = self.deskFn("desktop_activity_wait") orelse return abi.remote_frame_error_unsupported;
        return table_fn(last_seq, timeout_ticks, out_seq);
    }

    pub fn desktopActivityWaitTimeout(self: *const Context, last_seq: u64, timeout: time_contract.Timeout, out_seq: *u64) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.remote_frame_error_invalid;
        return self.desktopActivityWait(last_seq, timeout_ticks_value, out_seq);
    }

    pub fn supportsRemoteFrameMap(self: *const Context) bool {
        return self.hasDeskFn("remote_frame_map");
    }

    pub fn remoteFrameMap(self: *const Context, out: *abi.RemoteFrameMapInfo) i32 {
        const table_fn = self.deskFn("remote_frame_map") orelse return abi.remote_frame_error_unsupported;
        return table_fn(out);
    }

    pub fn remoteFramePublish(self: *const Context, info: *const abi.RemoteFrameInfo, pixels: []const u32) i32 {
        const table_fn = self.deskFn("remote_frame_publish") orelse return abi.remote_frame_error_unsupported;
        return table_fn(info, pixels.ptr, @intCast(pixels.len));
    }

    pub fn supportsRemoteFrameRegions(self: *const Context) bool {
        return self.hasDeskFn("remote_frame_publish_regions");
    }

    pub fn remoteFramePublishRegions(self: *const Context, info: *const abi.RemoteFrameInfo, pixels: []const u32, regions: []const abi.DisplayDamageRect) i32 {
        const table_fn = self.deskFn("remote_frame_publish_regions") orelse return abi.remote_frame_error_unsupported;
        return table_fn(info, pixels.ptr, @intCast(pixels.len), regions.ptr, @intCast(regions.len));
    }

    pub fn supportsRemoteFrameDemand(self: *const Context) bool {
        return self.hasDeskFn("remote_frame_acquire") and
            self.hasDeskFn("remote_frame_release") and
            self.hasDeskFn("remote_frame_consumers");
    }

    pub fn remoteFrameAcquire(self: *const Context) i32 {
        const table_fn = self.deskFn("remote_frame_acquire") orelse return abi.remote_frame_error_unsupported;
        return table_fn();
    }

    pub fn remoteFrameRelease(self: *const Context) i32 {
        const table_fn = self.deskFn("remote_frame_release") orelse return abi.remote_frame_error_unsupported;
        return table_fn();
    }

    pub fn remoteFrameConsumers(self: *const Context) u32 {
        const table_fn = self.deskFn("remote_frame_consumers") orelse return 0;
        return table_fn();
    }

    pub fn supportsRemoteInput(self: *const Context) bool {
        return self.hasDeskFn("remote_input_push") and
            self.hasDeskFn("remote_input_poll") and
            self.hasDeskFn("remote_input_status");
    }

    pub fn remoteInputPush(self: *const Context, event: *const abi.RemoteInputEvent) i32 {
        const table_fn = self.deskFn("remote_input_push") orelse return abi.remote_input_error_unsupported;
        return table_fn(event);
    }

    pub fn remoteInputPoll(self: *const Context, out: *abi.RemoteInputEvent) i32 {
        const table_fn = self.deskFn("remote_input_poll") orelse return abi.remote_input_error_unsupported;
        return table_fn(out);
    }

    pub fn remoteInputStatus(self: *const Context, out: *abi.RemoteInputStatus) i32 {
        const table_fn = self.deskFn("remote_input_status") orelse return abi.remote_input_error_unsupported;
        return table_fn(out);
    }

    pub fn fontCount(self: *const Context) u32 {
        const table_fn = self.drawFn("font_count") orelse return 0;
        return table_fn();
    }

    pub fn fontInfo(self: *const Context, font_id: u32, out: *abi.GuiFontInfo) i32 {
        if (!self.hasDrawFn("gui_set_font")) {
            if (font_id != abi.gui_font_builtin_id) return 0;
            out.* = .{
                .id = abi.gui_font_builtin_id,
                .kind = 0,
                .flags = abi.gui_font_flag_renderable | abi.gui_font_flag_builtin,
                .weight = 400,
                .width = 8,
                .height = 8,
                .max_advance = 8,
                .line_height = 8,
                .baseline = 7,
                .glyph_count = 95,
                .strike_count = 1,
            };
            copyFixedZ(out.family[0..], "R4OS");
            copyFixedZ(out.face[0..], "Builtin 8x8");
            copyFixedZ(out.style[0..], "Regular");
            copyFixedZ(out.status[0..], "builtin fallback");
            return 1;
        }
        const table_fn = self.drawFn("font_info") orelse return self.unavailable("draw");
        return table_fn(font_id, out);
    }

    pub fn fontMeasure(self: *const Context, font_id: u32, value: [*:0]const u8, out: *abi.GuiTextMetrics) i32 {
        if (!self.hasDrawFn("gui_set_font")) {
            out.* = fallbackTextMetrics(value);
            return 0;
        }
        const table_fn = self.drawFn("font_measure") orelse return self.unavailable("draw");
        return table_fn(font_id, value, out);
    }

    /// Returns one rendered glyph row from the R4DRAW runtime font cache.
    /// A zero result also represents an unavailable optional operation.
    pub fn fontGlyphRow(self: *const Context, font_id: u32, codepoint: u32, row: u32) u64 {
        const table_fn = self.drawFn("font_glyph_row") orelse return 0;
        return table_fn(font_id, codepoint, row);
    }

    /// Retrieves a complete cached glyph in one R4DRAW-v6 call. On older
    /// kernels the SDK composes the fixed-capacity result from font_info and
    /// font_glyph_row; proportional glyph metrics then degrade to face width
    /// and maximum advance while pixels remain exact.
    pub fn fontGlyphBitmap(self: *const Context, font_id: u32, codepoint: u32, out: *abi.GuiGlyphBitmap) i32 {
        if (codepoint > 0x10FFFF) return -1;
        if (self.drawFn("font_glyph_bitmap")) |table_fn| return table_fn(font_id, codepoint, out);
        if (!self.hasDrawFn("font_glyph_row")) return self.unavailable("draw");

        var info: abi.GuiFontInfo = .{};
        const info_result = self.fontInfo(font_id, &info);
        if (info_result <= 0) return if (info_result < 0) info_result else -2;
        var bitmap = abi.GuiGlyphBitmap{
            .width = @min(info.width, 64),
            .height = @min(info.height, @as(u32, @typeInfo(@TypeOf((abi.GuiGlyphBitmap{}).rows)).array.len)),
            .advance = info.max_advance,
            .line_height = info.line_height,
            .baseline = info.baseline,
        };
        var row: u32 = 0;
        while (row < bitmap.height) : (row += 1) bitmap.rows[row] = self.fontGlyphRow(font_id, codepoint, row);
        out.* = bitmap;
        return 0;
    }

    /// Returns the non-zero generation paired with live font catalogue ids.
    /// Pre-v7 R4DRAW tables expose no reload generation and use stable 1.
    pub fn fontRevision(self: *const Context) u32 {
        const table_fn = self.drawFn("font_revision") orelse return 1;
        const revision = table_fn();
        return if (revision == 0) 1 else revision;
    }

    /// Rebuilds the R4DRAW catalogue from C:\R4OS\FONTS.  Returns the number
    /// of renderable fonts, or a negative draw error when the scan failed.
    pub fn fontReload(self: *const Context) i32 {
        const table_fn = self.drawFn("font_reload") orelse return self.unavailable("draw");
        return table_fn();
    }

    pub fn guiSetFont(self: *const Context, font_id: u32) i32 {
        const table_fn = self.drawFn("gui_set_font") orelse return self.unavailable("draw");
        return table_fn(font_id);
    }

    pub fn guiFont(self: *const Context, instance_id: u32, out: *abi.GuiFontInfo) i32 {
        const table_fn = self.drawFn("gui_font") orelse return self.unavailable("draw");
        return table_fn(instance_id, out);
    }

    pub fn guiDrawTextEx(self: *const Context, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32, font_id: u32, flags: u32) i32 {
        const table_fn = self.drawFn("gui_draw_text_ex") orelse return self.unavailable("draw");
        return table_fn(x, y, value, fg, bg, font_id, flags);
    }

    pub fn textFont(self: *const Context, font_id: u32, x: i32, y: i32, value: [*:0]const u8, fg: u32, bg: u32) void {
        if (!self.hasDrawFn("gui_set_font")) {
            self.text(x, y, value, fg, bg);
            return;
        }
        if (self.drawFn("text_font")) |table_fn| table_fn(font_id, x, y, value, fg, bg);
    }

    pub fn programStatus(self: *const Context, out: *abi.ProgramStatus) void {
        if (self.sysFn("program_status")) |table_fn| table_fn(out);
    }

    pub fn systemPoweroff(self: *const Context) noreturn {
        if (self.sysFn("system_poweroff")) |table_fn| table_fn();
        while (true) self.taskYield();
    }

    pub fn taskYield(self: *const Context) void {
        if (self.sysFn("task_yield")) |table_fn| table_fn();
    }

    pub fn fileRead(self: *const Context, path: [*:0]const u8, out: []u8) i32 {
        const table_fn = self.sysFn("file_read") orelse return self.unavailable("sys");
        return table_fn(path, out.ptr, @intCast(out.len));
    }

    /// Groesse einer eingebetteten R4M0-Ressource (0.61.13). name nur fuer
    /// Typ file (3); Icons (1) adressieren ueber index, help (2) ist einmalig.
    pub fn moduleResourceStat(self: *const Context, module_path: [*:0]const u8, resource_type: u32, resource_index: u32, name: ?[*:0]const u8) i32 {
        const table_fn = self.sysFn("module_resource_stat") orelse return self.unavailable("sys");
        return table_fn(module_path, resource_type, resource_index, name);
    }

    /// Liest eine eingebettete Ressource komplett; zu kleiner Buffer ist ein
    /// sichtbarer Fehler, keine stille Truncation.
    pub fn moduleResourceRead(self: *const Context, module_path: [*:0]const u8, resource_type: u32, resource_index: u32, name: ?[*:0]const u8, out: []u8) i32 {
        const table_fn = self.sysFn("module_resource_read") orelse return self.unavailable("sys");
        return table_fn(module_path, resource_type, resource_index, name, out.ptr, @intCast(out.len));
    }

    /// Pfad der EIGENEN Moduldatei - damit ein Programm seine eingebetteten
    /// Ressourcen liest, ohne den Installationspfad zu raten.
    pub fn programModulePath(self: *const Context, out: []u8) i32 {
        const table_fn = self.sysFn("program_module_path") orelse return self.unavailable("sys");
        return table_fn(out.ptr, @intCast(out.len));
    }

    pub fn programModuleRunning(self: *const Context, module_path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("program_module_running") orelse return self.unavailable("sys");
        return table_fn(module_path);
    }

    pub fn fileWrite(self: *const Context, path: [*:0]const u8, data: []const u8) i32 {
        const table_fn = self.sysFn("file_write") orelse return self.unavailable("sys");
        return table_fn(path, data.ptr, @intCast(data.len));
    }

    pub fn fileReadAt(self: *const Context, path: [*:0]const u8, offset: u32, out: []u8) i32 {
        const table_fn = self.sysFn("file_read_at") orelse return self.unavailable("sys");
        return table_fn(path, offset, out.ptr, @intCast(out.len));
    }

    pub fn fileAppend(self: *const Context, path: [*:0]const u8, data: []const u8) i32 {
        const table_fn = self.sysFn("file_append") orelse return self.unavailable("sys");
        return table_fn(path, data.ptr, @intCast(data.len));
    }

    pub fn fileStreamBegin(self: *const Context, path: [*:0]const u8, flags: u32) i32 {
        const table_fn = self.sysFn("file_stream_begin") orelse return self.unavailable("sys");
        return table_fn(path, flags);
    }

    pub fn fileStreamWrite(self: *const Context, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32) i32 {
        const table_fn = self.sysFn("file_stream_write") orelse return self.unavailable("sys");
        return table_fn(path, offset, data.ptr, @intCast(data.len), flags);
    }

    pub fn fileStreamFinish(self: *const Context, path: [*:0]const u8, expected_size: u64, flags: u32) i32 {
        const table_fn = self.sysFn("file_stream_finish") orelse return self.unavailable("sys");
        return table_fn(path, expected_size, flags);
    }

    pub fn fileStreamAbort(self: *const Context, path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("file_stream_abort") orelse return self.unavailable("sys");
        return table_fn(path);
    }

    pub fn dirList(self: *const Context, path: [*:0]const u8, out: []u8) i32 {
        const table_fn = self.sysFn("dir_list") orelse return self.unavailable("sys");
        return table_fn(path, out.ptr, @intCast(out.len));
    }

    pub fn dirEntry(self: *const Context, path: [*:0]const u8, index: u32, out: []u8) i32 {
        const table_fn = self.sysFn("dir_entry") orelse return self.unavailable("sys");
        return table_fn(path, index, out.ptr, @intCast(out.len));
    }

    pub fn driveInfo(self: *const Context, index: u32) ?abi.DriveInfo {
        var out: abi.DriveInfo = .{};
        const table_fn = self.sysFn("drive_info") orelse return null;
        if (table_fn(index, &out) <= 0) return null;
        return out;
    }

    pub fn fileInfoRaw(self: *const Context, path: [*:0]const u8, out: *abi.FileInfo) i32 {
        const table_fn = self.sysFn("file_info") orelse return self.unavailable("sys");
        return table_fn(path, out);
    }

    pub fn fileInfo(self: *const Context, path: [*:0]const u8) ?abi.FileInfo {
        var out: abi.FileInfo = .{};
        if (self.fileInfoRaw(path, &out) <= 0) return null;
        return out;
    }

    pub fn fileDelete(self: *const Context, path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("file_delete") orelse return self.unavailable("sys");
        return table_fn(path);
    }

    pub fn fileDeleteIfMatch(
        self: *const Context,
        path: [*:0]const u8,
        expected_size: u64,
        expected_checksum: u32,
    ) i32 {
        const table_fn = self.sysFn("file_delete_if_match") orelse return self.unavailable("sys");
        return table_fn(path, expected_size, expected_checksum);
    }

    /// Declares the create-only publish intent of an already open stream
    /// (0.60.30), so the durable claim brackets the whole transfer.
    pub fn fileStreamDeclarePublish(
        self: *const Context,
        staged_path: [*:0]const u8,
        target_path: [*:0]const u8,
        backup_path: [*:0]const u8,
        protocol: u32,
    ) i32 {
        const table_fn = self.sysFn("file_stream_declare_publish") orelse
            return self.unavailable("sys");
        return table_fn(staged_path, target_path, backup_path, protocol);
    }

    /// Backend-exact name collation (0.60.24): 1 = same object on this
    /// volume, 0 = different, negative = the question could not be answered.
    pub fn pathNamesEqualCollated(
        self: *const Context,
        left_path: [*:0]const u8,
        right_path: [*:0]const u8,
    ) i32 {
        const table_fn = self.sysFn("path_names_equal_collated") orelse
            return self.unavailable("sys");
        return table_fn(left_path, right_path);
    }

    /// Per-payload checked SYSUPD cleanup under one filesystem gate
    /// (0.60.23).
    pub fn fileUpdateCleanupChecked(
        self: *const Context,
        target_path: [*:0]const u8,
        staged_path: [*:0]const u8,
        backup_path: [*:0]const u8,
        previous_backup_path: [*:0]const u8,
        new_size: u64,
        new_checksum: u32,
        old_size: u64,
        old_checksum: u32,
        previous_size: u64,
        previous_checksum: u32,
        flags: u32,
    ) i32 {
        const table_fn = self.sysFn("file_update_cleanup_checked") orelse
            return self.unavailable("sys");
        return table_fn(
            target_path,
            staged_path,
            backup_path,
            previous_backup_path,
            new_size,
            new_checksum,
            old_size,
            old_checksum,
            previous_size,
            previous_checksum,
            flags,
        );
    }

    pub fn fileUpdateAtomicChecked(
        self: *const Context,
        target_path: [*:0]const u8,
        staged_path: [*:0]const u8,
        backup_path: [*:0]const u8,
        new_size: u64,
        new_checksum: u32,
        old_size: u64,
        old_checksum: u32,
        flags: u32,
    ) i32 {
        const table_fn = self.sysFn("file_update_atomic_checked") orelse
            return self.unavailable("sys");
        return table_fn(
            target_path,
            staged_path,
            backup_path,
            new_size,
            new_checksum,
            old_size,
            old_checksum,
            flags,
        );
    }

    pub fn dirCreate(self: *const Context, path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("dir_create") orelse return self.unavailable("sys");
        return table_fn(path);
    }

    pub fn dirDelete(self: *const Context, path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("dir_delete") orelse return self.unavailable("sys");
        return table_fn(path);
    }

    pub fn fileRename(self: *const Context, old_path: [*:0]const u8, new_path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("file_rename") orelse return self.unavailable("sys");
        return table_fn(old_path, new_path);
    }

    pub fn fileCopy(self: *const Context, src_path: [*:0]const u8, dst_path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("file_copy") orelse return self.unavailable("sys");
        return table_fn(src_path, dst_path);
    }

    pub fn fileMove(self: *const Context, src_path: [*:0]const u8, dst_path: [*:0]const u8) i32 {
        const table_fn = self.sysFn("file_move") orelse return self.unavailable("sys");
        return table_fn(src_path, dst_path);
    }

    pub fn fileReplaceAtomic(self: *const Context, target_path: [*:0]const u8, staged_path: [*:0]const u8, backup_path: [*:0]const u8, flags: u32) i32 {
        const table_fn = self.sysFn("file_replace_atomic") orelse return self.unavailable("sys");
        return table_fn(target_path, staged_path, backup_path, flags);
    }

    pub fn exists(self: *const Context, path: [*:0]const u8) bool {
        const info = self.fileInfo(path) orelse return false;
        return info.exists != 0;
    }

    pub fn registryKeyInfo(self: *const Context, key_path: [*:0]const u8, out: *abi.RegistryKeyInfo) i32 {
        const table_fn = self.sysFn("registry_key_info") orelse return self.unavailable("sys");
        return table_fn(key_path, out);
    }

    pub fn registryEnumKey(self: *const Context, key_path: [*:0]const u8, index: u32, out: []u8) i32 {
        const table_fn = self.sysFn("registry_enum_key") orelse return self.unavailable("sys");
        return table_fn(key_path, index, out.ptr, @intCast(out.len));
    }

    pub fn registryEnumValue(self: *const Context, key_path: [*:0]const u8, index: u32, out: *abi.RegistryValueInfo) i32 {
        const table_fn = self.sysFn("registry_enum_value") orelse return self.unavailable("sys");
        return table_fn(key_path, index, out);
    }

    pub fn registryGetValue(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, out_info: *abi.RegistryValueInfo, out: []u8) i32 {
        const table_fn = self.sysFn("registry_get_value") orelse return self.unavailable("sys");
        return table_fn(key_path, value_name, out_info, out.ptr, @intCast(out.len));
    }

    pub fn registrySetValue(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value_type: u16, data: []const u8) i32 {
        const table_fn = self.sysFn("registry_set_value") orelse return self.unavailable("sys");
        return table_fn(key_path, value_name, value_type, data.ptr, @intCast(data.len));
    }

    pub fn registryDeleteValue(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8) i32 {
        const table_fn = self.sysFn("registry_delete_value") orelse return self.unavailable("sys");
        return table_fn(key_path, value_name);
    }

    pub fn registrySnapshotBegin(self: *const Context, key_path: [*:0]const u8, kind: u32, cursor: *abi.RegistrySnapshotCursor) i32 {
        const table_fn = self.sysFn("registry_snapshot_begin") orelse return self.unavailable("sys");
        return table_fn(key_path, kind, cursor);
    }

    pub fn registrySnapshotPage(self: *const Context, cursor: *abi.RegistrySnapshotCursor, entries: []abi.RegistrySnapshotEntry, data: []u8, out_page: *abi.RegistrySnapshotPageInfo) i32 {
        const table_fn = self.sysFn("registry_snapshot_page") orelse return self.unavailable("sys");
        return table_fn(cursor, entries.ptr, @intCast(entries.len), data.ptr, @intCast(data.len), out_page);
    }

    pub fn registryBatchMutate(self: *const Context, operations: []const abi.RegistryBatchOperation, blob: []const u8, out_result: *abi.RegistryBatchResult) i32 {
        const table_fn = self.sysFn("registry_batch_mutate") orelse return self.unavailable("sys");
        return table_fn(operations.ptr, @intCast(operations.len), blob.ptr, @intCast(blob.len), out_result);
    }

    pub fn registrySetString(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: []const u8) i32 {
        return self.registrySetValue(key_path, value_name, abi.registry_value_type_string, value);
    }

    pub fn registrySetU32(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: u32) i32 {
        var data: [4]u8 = .{ 0, 0, 0, 0 };
        data[0] = @intCast(value & 0xff);
        data[1] = @intCast((value >> 8) & 0xff);
        data[2] = @intCast((value >> 16) & 0xff);
        data[3] = @intCast((value >> 24) & 0xff);
        return self.registrySetValue(key_path, value_name, abi.registry_value_type_u32, data[0..]);
    }

    pub fn registrySetU64(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: u64) i32 {
        var data: [8]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0 };
        data[0] = @intCast(value & 0xff);
        data[1] = @intCast((value >> 8) & 0xff);
        data[2] = @intCast((value >> 16) & 0xff);
        data[3] = @intCast((value >> 24) & 0xff);
        data[4] = @intCast((value >> 32) & 0xff);
        data[5] = @intCast((value >> 40) & 0xff);
        data[6] = @intCast((value >> 48) & 0xff);
        data[7] = @intCast((value >> 56) & 0xff);
        return self.registrySetValue(key_path, value_name, abi.registry_value_type_u64, data[0..]);
    }

    pub fn registrySetBool(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: bool) i32 {
        var data: [1]u8 = .{if (value) 1 else 0};
        return self.registrySetValue(key_path, value_name, abi.registry_value_type_bool, data[0..]);
    }

    pub fn registrySetBinary(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: []const u8) i32 {
        return self.registrySetValue(key_path, value_name, abi.registry_value_type_binary, value);
    }

    pub fn audioOpenStream(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat) i32 {
        const table_fn = self.audioFn("audio_open_stream") orelse return self.unavailable("audio");
        return table_fn(rate, channels, @intFromEnum(format));
    }

    pub fn audioWrite(self: *const Context, stream_id: u32, data: []const u8) i32 {
        const table_fn = self.audioFn("audio_write") orelse return self.unavailable("audio");
        return table_fn(stream_id, data.ptr, @intCast(data.len));
    }

    pub fn audioClose(self: *const Context, stream_id: u32) i32 {
        const table_fn = self.audioFn("audio_close") orelse return self.unavailable("audio");
        return table_fn(stream_id);
    }

    pub fn audioSetVolume(self: *const Context, stream_id: u32, fixed_volume: u32) i32 {
        const table_fn = self.audioFn("audio_set_volume") orelse return self.unavailable("audio");
        return table_fn(stream_id, fixed_volume);
    }

    pub fn sidAcquire(self: *const Context) i32 {
        const table_fn = self.audioFn("sid_acquire") orelse return self.unavailable("audio");
        return table_fn();
    }

    pub fn sidWriteRegister(self: *const Context, handle: u32, reg: u8, value: u8) i32 {
        const table_fn = self.audioFn("sid_write_register") orelse return self.unavailable("audio");
        return table_fn(handle, reg, value);
    }

    pub fn sidRelease(self: *const Context, handle: u32) i32 {
        const table_fn = self.audioFn("sid_release") orelse return self.unavailable("audio");
        return table_fn(handle);
    }

    pub fn midiOpenSynth(self: *const Context, backend: [*:0]const u8) i32 {
        const table_fn = self.audioFn("midi_open_synth") orelse return self.unavailable("audio");
        return table_fn(backend);
    }

    pub fn midiSend(self: *const Context, handle: u32, channel: u8, status: u8, data1: u8, data2: u8) i32 {
        const table_fn = self.audioFn("midi_send") orelse return self.unavailable("audio");
        return table_fn(handle, channel, status, data1, data2);
    }

    pub fn midiRender(self: *const Context, handle: u32, frames: u16) i32 {
        if (frames == 0 or frames > 1024) return abi.service_api_result_invalid;
        return self.midiSend(handle, 0, 0, @truncate(frames), @truncate(frames >> 8));
    }

    pub fn midiClose(self: *const Context, handle: u32) i32 {
        const table_fn = self.audioFn("midi_close") orelse return self.unavailable("audio");
        return table_fn(handle);
    }

    pub fn opl3WriteRegister(self: *const Context, bank: u8, reg: u8, value: u8) i32 {
        const table_fn = self.audioFn("opl3_write_register") orelse return self.unavailable("audio");
        return table_fn(bank, reg, value);
    }

    pub fn opl3Reset(self: *const Context) i32 {
        const table_fn = self.audioFn("opl3_reset") orelse return self.unavailable("audio");
        return table_fn();
    }

    pub fn opl3RenderBlock(self: *const Context) i32 {
        const table_fn = self.audioFn("opl3_render_block") orelse return self.unavailable("audio");
        return table_fn();
    }

    pub fn opl3Stop(self: *const Context) i32 {
        const table_fn = self.audioFn("opl3_stop") orelse return self.unavailable("audio");
        return table_fn();
    }

    pub fn sidLoadData(self: *const Context, handle: u32, load_addr: u16, data: []const u8) i32 {
        const table_fn = self.audioFn("sid_load_data") orelse return self.unavailable("audio");
        return table_fn(handle, load_addr, data.ptr, @intCast(data.len));
    }

    pub fn sidInit(self: *const Context, handle: u32, init_addr: u16, song: u16) i32 {
        const table_fn = self.audioFn("sid_init") orelse return self.unavailable("audio");
        return table_fn(handle, init_addr, song);
    }

    pub fn sidPlayFrame(self: *const Context, handle: u32, play_addr: u16, frame_hz: u16) i32 {
        const table_fn = self.audioFn("sid_play_frame") orelse return self.unavailable("audio");
        return table_fn(handle, play_addr, frame_hz);
    }

    pub fn sidStop(self: *const Context, handle: u32) i32 {
        const table_fn = self.audioFn("sid_stop") orelse return self.unavailable("audio");
        return table_fn(handle);
    }

    pub fn sidModelName(self: *const Context) [*:0]const u8 {
        const table_fn = self.audioFn("sid_model_name") orelse return "";
        return table_fn();
    }

    pub fn deviceInventorySummary(self: *const Context, out: *abi.DeviceInventorySummary) i32 {
        const table_fn = self.devFn("device_inventory_summary") orelse return self.unavailable("dev");
        return table_fn(out);
    }

    pub fn deviceInventoryRecord(self: *const Context, index: u32, out: *abi.DeviceInventoryRecord) i32 {
        const table_fn = self.devFn("device_inventory_record") orelse return self.unavailable("dev");
        return table_fn(index, out);
    }

    pub fn ipcOpen(self: *const Context, channel_id: u32) i32 {
        const table_fn = self.netFn("ipc_open") orelse return self.unavailable("net");
        return table_fn(channel_id);
    }

    pub fn ipcSend(self: *const Context, channel_id: u32, data: []const u8) i32 {
        const table_fn = self.netFn("ipc_send") orelse return self.unavailable("net");
        return table_fn(channel_id, data.ptr, @intCast(data.len));
    }

    pub fn ipcRecv(self: *const Context, channel_id: u32, out: []u8) i32 {
        const table_fn = self.netFn("ipc_recv") orelse return self.unavailable("net");
        return table_fn(channel_id, out.ptr, @intCast(out.len));
    }

    pub fn ipcPoll(self: *const Context, channel_id: u32) i32 {
        const table_fn = self.netFn("ipc_poll") orelse return self.unavailable("net");
        return table_fn(channel_id);
    }

    pub fn ipcClose(self: *const Context, channel_id: u32) i32 {
        const table_fn = self.netFn("ipc_close") orelse return self.unavailable("net");
        return table_fn(channel_id);
    }

    pub fn ipcSummary(self: *const Context, out: *abi.IpcSummary) i32 {
        const table_fn = self.netFn("ipc_summary") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn ipcChannel(self: *const Context, channel_id: u32, out: *abi.IpcChannelInfo) i32 {
        const table_fn = self.netFn("ipc_channel") orelse return self.unavailable("net");
        return table_fn(channel_id, out);
    }

    pub fn ipcPerformance(self: *const Context, channel_id: u32, out: *abi.IpcPerformanceSummary) i32 {
        const table_fn = self.netFn("ipc_performance") orelse return self.unavailable("net");
        return table_fn(channel_id, out);
    }

    pub fn serviceInfo(self: *const Context, index: u32, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_info") orelse return self.unavailable("sys");
        return table_fn(index, out);
    }

    pub fn serviceStatus(self: *const Context, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_status") orelse return self.unavailable("sys");
        return table_fn(name, out);
    }

    pub fn serviceOpen(self: *const Context, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_open") orelse return self.unavailable("sys");
        return table_fn(name, out);
    }

    pub fn serviceClose(self: *const Context, handle: u32) i32 {
        const table_fn = self.sysFn("service_close") orelse return self.unavailable("sys");
        return table_fn(handle);
    }

    pub fn serviceCall(self: *const Context, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout_ticks: u64) i32 {
        if (request.len > abi.service_api_max_payload) return abi.service_api_result_payload_too_large;
        if (response.len > abi.service_api_max_payload) return abi.service_api_result_invalid;
        const table_fn = self.sysFn("service_call") orelse return self.unavailable("sys");
        return table_fn(handle, op, request.ptr, @intCast(request.len), response_header, response.ptr, @intCast(response.len), timeout_ticks);
    }

    pub fn serviceCallTimeout(self: *const Context, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout: time_contract.Timeout) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.service_api_result_invalid;
        return self.serviceCall(handle, op, request, response_header, response, timeout_ticks_value);
    }

    pub fn serviceEndpointRegister(self: *const Context, name: [*:0]const u8, flags: u32, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_endpoint_register") orelse return self.unavailable("sys");
        return table_fn(name, flags, out);
    }

    pub fn serviceEndpointUnregister(self: *const Context, handle: u32) i32 {
        const table_fn = self.sysFn("service_endpoint_unregister") orelse return self.unavailable("sys");
        return table_fn(handle);
    }

    pub fn serviceEndpointPoll(self: *const Context, handle: u32) i32 {
        const table_fn = self.sysFn("service_endpoint_poll") orelse return self.unavailable("sys");
        return table_fn(handle);
    }

    // 0.56.19: Blockierendes Endpoint-Warten (API-Version 149). Liefert
    // wie Poll die Anzahl anstehender Requests (0 = Timeout ohne Arbeit).
    pub fn serviceEndpointWait(self: *const Context, handle: u32, timeout_ticks: u64) i32 {
        if (!self.hasSysFn("service_endpoint_wait")) {
            return abi.service_api_result_invalid;
        }
        const table_fn = self.sysFn("service_endpoint_wait") orelse return self.unavailable("sys");
        return table_fn(handle, timeout_ticks);
    }

    pub fn serviceEndpointWaitTimeout(self: *const Context, handle: u32, timeout: time_contract.Timeout) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.service_api_result_invalid;
        return self.serviceEndpointWait(handle, timeout_ticks_value);
    }

    pub fn serviceEndpointRecv(self: *const Context, handle: u32, header: *abi.ServiceMessageHeader, out: []u8) i32 {
        if (out.len > abi.service_api_max_payload) return abi.service_api_result_invalid;
        const table_fn = self.sysFn("service_endpoint_recv") orelse return self.unavailable("sys");
        return table_fn(handle, header, out.ptr, @intCast(out.len));
    }

    pub fn serviceEndpointReply(self: *const Context, handle: u32, request_id: u32, status: i32, payload: []const u8) i32 {
        if (payload.len > abi.service_api_max_payload) return abi.service_api_result_payload_too_large;
        const table_fn = self.sysFn("service_endpoint_reply") orelse return self.unavailable("sys");
        return table_fn(handle, request_id, status, payload.ptr, @intCast(payload.len));
    }

    pub fn serviceDetail(self: *const Context, index: u32, out: *abi.ServiceDetail) i32 {
        const table_fn = self.sysFn("service_detail") orelse return self.unavailable("sys");
        return table_fn(index, out);
    }

    pub fn serviceDetailByName(self: *const Context, name: [*:0]const u8, out: *abi.ServiceDetail) i32 {
        const table_fn = self.sysFn("service_detail_by_name") orelse return self.unavailable("sys");
        return table_fn(name, out);
    }

    pub fn serviceStart(self: *const Context, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_start") orelse return self.unavailable("sys");
        return table_fn(name, out);
    }

    pub fn serviceStop(self: *const Context, name: [*:0]const u8, out: *abi.ServiceInfo, timeout_ticks: u64) i32 {
        const table_fn = self.sysFn("service_stop") orelse return self.unavailable("sys");
        return table_fn(name, out, timeout_ticks);
    }

    pub fn serviceStopWithPolicy(self: *const Context, name: [*:0]const u8, out: *abi.ServiceInfo, timeout: time_contract.Timeout, policy: ServiceStopPolicy) i32 {
        const timeout_ticks_value = time_contract.timeoutToTicks(timeout, self.monotonicHz()) catch return abi.service_api_result_invalid;
        const stopped = self.serviceStop(name, out, timeout_ticks_value);
        if (stopped != abi.service_api_result_timeout or policy == .graceful) return stopped;
        if (out.instance_id == 0 or self.programKill(out.instance_id) < 0) return abi.service_api_result_stop_failed;
        return self.serviceStatus(name, out);
    }

    pub fn serviceRestart(self: *const Context, name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_restart") orelse return self.unavailable("sys");
        return table_fn(name, out);
    }

    pub fn serviceSetStartMode(self: *const Context, name: [*:0]const u8, start_mode: u32, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_set_start_mode") orelse return self.unavailable("sys");
        return table_fn(name, start_mode, out);
    }

    pub fn serviceInstall(self: *const Context, name: [*:0]const u8, path: [*:0]const u8, args: [*:0]const u8, start_mode: u32, description: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        const table_fn = self.sysFn("service_install") orelse return self.unavailable("sys");
        return table_fn(name, path, args, start_mode, description, out);
    }

    pub fn serviceRemove(self: *const Context, name: [*:0]const u8) i32 {
        const table_fn = self.sysFn("service_remove") orelse return self.unavailable("sys");
        return table_fn(name);
    }

    pub fn serialLinkStatus(self: *const Context, out: *abi.SerialLinkStatus) i32 {
        const table_fn = self.netFn("serial_link_status") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn serialLinkPoll(self: *const Context) i32 {
        const table_fn = self.netFn("serial_link_poll") orelse return self.unavailable("net");
        return table_fn();
    }

    pub fn serialLinkSendMessage(self: *const Context, data: []const u8) i32 {
        if (data.len > abi.serial_link_payload_max) return abi.serial_link_result_too_large;
        const table_fn = self.netFn("serial_link_send_message") orelse return self.unavailable("net");
        return table_fn(data.ptr, @intCast(data.len));
    }

    pub fn serialLinkHostTest(self: *const Context) i32 {
        const table_fn = self.netFn("serial_link_host_test") orelse return self.unavailable("net");
        return table_fn();
    }

    pub fn serialLinkInbox(self: *const Context, out: *abi.SerialLinkMessage) i32 {
        const table_fn = self.netFn("serial_link_inbox") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn timeServiceStatus(self: *const Context, out: *abi.TimeServiceStatus) i32 {
        return self.timeServiceCall(abi.time_service_op_status, "", out);
    }

    pub fn timeServiceReload(self: *const Context, out: *abi.TimeServiceStatus) i32 {
        return self.timeServiceCall(abi.time_service_op_reload, "", out);
    }

    pub fn timeServiceSetTimezone(self: *const Context, timezone_index: u32, out: *abi.TimeServiceStatus) i32 {
        var request = abi.TimeServiceConfig{
            .timezone_index = timezone_index,
            .flags = abi.time_service_config_flag_timezone_index,
        };
        return self.timeServiceSetConfig(&request, out);
    }

    pub fn timeServiceSetClockFormat(self: *const Context, clock_format: u32, out: *abi.TimeServiceStatus) i32 {
        var request = abi.TimeServiceConfig{
            .clock_format = clock_format,
            .flags = abi.time_service_config_flag_clock_format,
        };
        return self.timeServiceSetConfig(&request, out);
    }

    pub fn timeServiceSetDate(self: *const Context, year: u16, month: u8, day: u8, out: *abi.TimeServiceStatus) i32 {
        var request = abi.TimeServiceConfig{
            .date_year = year,
            .date_month = month,
            .date_day = day,
            .flags = abi.time_service_config_flag_date,
        };
        return self.timeServiceSetConfig(&request, out);
    }

    pub fn timeServiceSetConfig(self: *const Context, request: *const abi.TimeServiceConfig, out: *abi.TimeServiceStatus) i32 {
        const bytes: [*]const u8 = @ptrCast(request);
        return self.timeServiceCall(abi.time_service_op_set_config, bytes[0..@sizeOf(abi.TimeServiceConfig)], out);
    }

    pub fn logServiceStatus(self: *const Context, out: *abi.LogServiceStatus) i32 {
        var response: [@sizeOf(abi.LogServiceStatus)]u8 = undefined;
        const got = self.logServiceCall(abi.log_service_op_status, "", response[0..]);
        if (got < 0) return got;
        if (got < @as(i32, @intCast(@sizeOf(abi.LogServiceStatus)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.LogServiceStatus)], response[0..]);
        if (out.magic != abi.log_service_status_magic or out.version != abi.log_service_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    pub fn logServiceSources(self: *const Context, query: *const abi.LogServiceSourceQuery, out: *abi.LogServiceSourcePage) i32 {
        var response: [@sizeOf(abi.LogServiceSourcePage)]u8 = undefined;
        const request_bytes: [*]const u8 = @ptrCast(query);
        const got = self.logServiceCall(abi.log_service_op_sources, request_bytes[0..@sizeOf(abi.LogServiceSourceQuery)], response[0..]);
        if (got < 0) return got;
        if (got < @as(i32, @intCast(@sizeOf(abi.LogServiceSourcePage)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.LogServiceSourcePage)], response[0..]);
        if (out.magic != abi.log_service_source_page_magic or out.version != abi.log_service_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    pub fn logServiceRecords(self: *const Context, query: *const abi.LogServiceRecordQuery, out: *abi.LogServiceRecordPage) i32 {
        var response: [@sizeOf(abi.LogServiceRecordPage)]u8 = undefined;
        const request_bytes: [*]const u8 = @ptrCast(query);
        const got = self.logServiceCall(abi.log_service_op_records, request_bytes[0..@sizeOf(abi.LogServiceRecordQuery)], response[0..]);
        if (got < 0) return got;
        if (got < @as(i32, @intCast(@sizeOf(abi.LogServiceRecordPage)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.LogServiceRecordPage)], response[0..]);
        if (out.magic != abi.log_service_record_page_magic or out.version != abi.log_service_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    pub fn logServiceExport(self: *const Context, query: *const abi.LogServiceRecordQuery, out: *abi.LogServiceExportPage) i32 {
        var response: [@sizeOf(abi.LogServiceExportPage)]u8 = undefined;
        const request_bytes: [*]const u8 = @ptrCast(query);
        const got = self.logServiceCall(abi.log_service_op_export, request_bytes[0..@sizeOf(abi.LogServiceRecordQuery)], response[0..]);
        if (got < 0) return got;
        if (got < @as(i32, @intCast(@sizeOf(abi.LogServiceExportPage)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.LogServiceExportPage)], response[0..]);
        if (out.magic != abi.log_service_export_magic or out.version != abi.log_service_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    pub fn logServiceWrite(self: *const Context, severity: u8, origin: []const u8, message: []const u8) i32 {
        return self.logServiceWriteRecord(abi.log_service_source_application, abi.log_record_type_event, severity, origin, message);
    }

    pub fn logServiceWriteRecord(self: *const Context, source_id: u32, record_type: u8, severity: u8, origin: []const u8, message: []const u8) i32 {
        const stored_text_len = @min(message.len, abi.log_service_text_bytes - 1);
        const stored_origin_len = @min(origin.len, abi.log_service_origin_bytes - 1);
        var request = abi.LogServiceWriteRequest{
            .severity = severity,
            .record_type = record_type,
            .source_id = source_id,
            .flags = if (message.len > stored_text_len) abi.log_service_record_flag_truncated else 0,
            .text_len = @intCast(stored_text_len),
            .origin_len = @intCast(stored_origin_len),
        };
        copyFixedZ(request.origin[0..], origin);
        copyFixedZ(request.text[0..], message);
        const request_bytes: [*]const u8 = @ptrCast(&request);
        var response: [@sizeOf(abi.LogServiceStatus)]u8 = undefined;
        const got = self.logServiceCall(abi.log_service_op_write, request_bytes[0..@sizeOf(abi.LogServiceWriteRequest)], response[0..]);
        if (got < 0) return got;
        if (got < @as(i32, @intCast(@sizeOf(abi.LogServiceStatus)))) return abi.service_api_result_buffer_too_small;
        return abi.service_api_result_ok;
    }

    pub fn audioServiceStatus(self: *const Context, out: *abi.AudioServiceStatus) i32 {
        return self.audioServiceCallStatus(abi.audio_service_op_status, "", out);
    }

    pub fn audioServiceSetMasterVolume(self: *const Context, fixed_volume: u32, out: *abi.AudioServiceStatus) i32 {
        var request = abi.AudioServiceVolumeRequest{ .fixed_volume = fixed_volume };
        const bytes: [*]const u8 = @ptrCast(&request);
        return self.audioServiceCallStatus(abi.audio_service_op_set_master_volume, bytes[0..@sizeOf(abi.AudioServiceVolumeRequest)], out);
    }

    pub fn audioServiceMasterState(self: *const Context, out: *abi.AudioServiceMasterState) i32 {
        return self.audioServiceCallMasterState(abi.audio_service_op_master_status, "", out);
    }

    pub fn audioServiceSetMasterState(self: *const Context, request: *const abi.AudioServiceMasterRequest, out: *abi.AudioServiceMasterState) i32 {
        return self.audioServiceCallMasterState(abi.audio_service_op_set_master_state, std.mem.asBytes(request), out);
    }

    pub fn audioServiceOpenStream(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat) i32 {
        var result: abi.AudioServiceStreamResult = .{};
        return self.audioServiceOpenStreamResult(rate, channels, format, 0x0001_0000, &result);
    }

    pub fn audioServiceOpenStreamResult(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat, fixed_volume: u32, out: *abi.AudioServiceStreamResult) i32 {
        var request = abi.AudioServiceStreamOpenRequest{
            .rate = rate,
            .channels = channels,
            .format = @intFromEnum(format),
            .fixed_volume = fixed_volume,
        };
        const bytes: [*]const u8 = @ptrCast(&request);
        const rc = self.audioServiceCallResult(abi.audio_service_op_open_stream, bytes[0..@sizeOf(abi.AudioServiceStreamOpenRequest)], out);
        if (rc != abi.service_api_result_ok) return rc;
        return out.result;
    }

    pub inline fn audioServiceWrite(self: *const Context, stream_id: u32, data: []const u8) i32 {
        if (data.len == 0) return 0;
        if (data.len > @as(usize, @intCast(std.math.maxInt(i32)))) return abi.service_api_result_payload_too_large;

        const header_size = @sizeOf(abi.AudioServiceStreamWriteRequest);
        var payload: [audio_service_payload_capacity]u8 = undefined;
        const max_chunk = payload.len - header_size;
        var offset: usize = 0;
        var total: i32 = 0;
        while (offset < data.len) {
            const chunk_len = @min(max_chunk, data.len - offset);
            var request = abi.AudioServiceStreamWriteRequest{
                .stream_id = stream_id,
                .byte_count = @intCast(chunk_len),
            };
            const request_bytes: [*]const u8 = @ptrCast(&request);
            var index: usize = 0;
            while (index < header_size) : (index += 1) {
                payload[index] = request_bytes[index];
            }
            index = 0;
            while (index < chunk_len) : (index += 1) {
                payload[header_size + index] = data.ptr[offset + index];
            }

            var result: abi.AudioServiceStreamResult = .{};
            const rc = self.audioServiceCallResult(abi.audio_service_op_write_stream, payload[0 .. header_size + chunk_len], &result);
            if (rc != abi.service_api_result_ok) return rc;
            if (result.result < 0) return result.result;
            total += @intCast(result.bytes);
            offset += chunk_len;
        }
        return total;
    }

    pub fn audioServiceClose(self: *const Context, stream_id: u32) i32 {
        var request = abi.AudioServiceStreamControlRequest{ .stream_id = stream_id };
        const bytes: [*]const u8 = @ptrCast(&request);
        var result: abi.AudioServiceStreamResult = .{};
        const rc = self.audioServiceCallResult(abi.audio_service_op_close_stream, bytes[0..@sizeOf(abi.AudioServiceStreamControlRequest)], &result);
        if (rc != abi.service_api_result_ok) return rc;
        return result.result;
    }

    pub fn audioServiceSetVolume(self: *const Context, stream_id: u32, fixed_volume: u32) i32 {
        var request = abi.AudioServiceStreamControlRequest{ .stream_id = stream_id, .fixed_volume = fixed_volume };
        const bytes: [*]const u8 = @ptrCast(&request);
        var result: abi.AudioServiceStreamResult = .{};
        const rc = self.audioServiceCallResult(abi.audio_service_op_set_stream_volume, bytes[0..@sizeOf(abi.AudioServiceStreamControlRequest)], &result);
        if (rc != abi.service_api_result_ok) return rc;
        return result.result;
    }

    fn timeServiceCall(self: *const Context, op: u16, payload: []const u8, out: *abi.TimeServiceStatus) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(time_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok or info.handle == 0) return handle_rc;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [@sizeOf(abi.TimeServiceStatus)]u8 = .{0} ** @sizeOf(abi.TimeServiceStatus);
        const got = self.serviceCall(info.handle, op, payload, &header, response[0..], self.ticksFromMilliseconds(time_r4x_service_timeout_ms));
        if (got < 0) return got;
        if (header.status != abi.service_api_result_ok) return header.status;
        if (got < @as(i32, @intCast(@sizeOf(abi.TimeServiceStatus)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.TimeServiceStatus)], response[0..]);
        if (out.magic != abi.time_service_status_magic or out.version != abi.time_service_status_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    fn logServiceCall(self: *const Context, op: u16, payload: []const u8, response: []u8) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(abi.log_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok) return handle_rc;
        if (info.handle == 0) return abi.service_api_result_no_endpoint;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        @memset(response, 0);
        const got = self.serviceCall(info.handle, op, payload, &header, response, self.ticksFromMilliseconds(log_r4x_service_timeout_ms));
        if (got < 0) return got;
        if (header.status != abi.service_api_result_ok) return header.status;
        return got;
    }

    fn audioServiceCallStatus(self: *const Context, op: u16, payload: []const u8, out: *abi.AudioServiceStatus) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(audio_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok) return handle_rc;
        if (info.handle == 0) return abi.service_api_result_no_endpoint;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [@sizeOf(abi.AudioServiceStatus)]u8 = .{0} ** @sizeOf(abi.AudioServiceStatus);
        const got = self.serviceCall(info.handle, op, payload, &header, response[0..], self.ticksFromMilliseconds(audio_r4x_service_timeout_ms));
        if (got < 0) return got;
        if (header.status != abi.service_api_result_ok) return header.status;
        if (got < @as(i32, @intCast(@sizeOf(abi.AudioServiceStatus)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.AudioServiceStatus)], response[0..]);
        if (out.magic != abi.audio_service_status_magic or out.version != abi.audio_service_status_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    fn audioServiceCallMasterState(self: *const Context, op: u16, payload: []const u8, out: *abi.AudioServiceMasterState) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(audio_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok) return handle_rc;
        if (info.handle == 0) return abi.service_api_result_no_endpoint;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [@sizeOf(abi.AudioServiceMasterState)]u8 = .{0} ** @sizeOf(abi.AudioServiceMasterState);
        const got = self.serviceCall(info.handle, op, payload, &header, response[0..], self.ticksFromMilliseconds(audio_r4x_service_timeout_ms));
        if (got < 0) return got;
        if (header.status != abi.service_api_result_ok) return header.status;
        if (got != @as(i32, @intCast(@sizeOf(abi.AudioServiceMasterState)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.AudioServiceMasterState)], response[0..]);
        if (out.magic != abi.audio_master_state_magic or out.version != abi.audio_master_state_version or out.size != @sizeOf(abi.AudioServiceMasterState)) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    fn audioServiceCallResult(self: *const Context, op: u16, payload: []const u8, out: *abi.AudioServiceStreamResult) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(audio_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok) return handle_rc;
        if (info.handle == 0) return abi.service_api_result_no_endpoint;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [@sizeOf(abi.AudioServiceStreamResult)]u8 = .{0} ** @sizeOf(abi.AudioServiceStreamResult);
        const got = self.serviceCall(info.handle, op, payload, &header, response[0..], self.ticksFromMilliseconds(audio_r4x_service_timeout_ms));
        if (got < 0) return got;
        if (header.status != abi.service_api_result_ok) return header.status;
        if (got < @as(i32, @intCast(@sizeOf(abi.AudioServiceStreamResult)))) return abi.service_api_result_buffer_too_small;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.AudioServiceStreamResult)], response[0..]);
        if (out.magic != abi.audio_service_result_magic or out.version != abi.audio_service_result_version) return abi.service_api_result_invalid;
        return abi.service_api_result_ok;
    }

    pub fn netServiceRequest(self: *const Context, channel_id: u32, op: u16, request_id: u32, payload: []const u8, out: []u8) i32 {
        if (payload.len > abi.ipc_max_message_size - abi.net_service_header_size) return abi.net_service_result_bad_request;
        if (out.len < abi.net_service_header_size or out.len > abi.ipc_max_message_size) return abi.net_service_result_bad_request;

        const client_id = self.netServiceClientId();
        if (self.netFn("net_service_request")) |table_fn| {
            return table_fn(
                channel_id,
                op,
                request_id,
                client_id,
                payload.ptr,
                @intCast(payload.len),
                out.ptr,
                @intCast(out.len),
            );
        }

        var message: [abi.ipc_max_message_size]u8 = undefined;
        writeNetServiceHeader(message[0..], channel_id, op, request_id, client_id, abi.net_service_result_ok, @intCast(payload.len)) orelse return abi.net_service_result_bad_request;
        if (payload.len != 0) @memcpy(message[abi.net_service_header_size .. abi.net_service_header_size + payload.len], payload);
        if (self.ipcSend(channel_id, message[0 .. abi.net_service_header_size + payload.len]) < 0) return abi.net_service_result_bad_service;
        var attempts: usize = 0;
        while (attempts < abi.ipc_queue_depth + 1) : (attempts += 1) {
            const got = self.ipcRecv(channel_id, out);
            if (got <= 0) return abi.net_service_result_bad_service;
            const response = out[0..@as(usize, @intCast(got))];
            if (netServiceResponseMatches(response, channel_id, op, request_id)) return got;
        }
        return abi.net_service_result_bad_service;
    }

    pub fn netServiceClientId(self: *const Context) u16 {
        // Pseudo-eindeutige Client-ID aus der Adresse des R4XStart-Kontexts;
        // der Kontext ist pro Programminstanz eindeutig.
        const b = self.bundle orelse return 1;
        const raw = @intFromPtr(b.raw);
        const id: u16 = @intCast(raw & 0xFFFF);
        return if (id == 0) 1 else id;
    }

    pub fn netServicePayload(self: *const Context, response: []const u8, status: *i32) ?[]const u8 {
        _ = self;
        if (response.len < abi.net_service_header_size) return null;
        if (readU32(response, 0) != abi.net_service_magic or readU16(response, 4) != abi.net_service_version) return null;
        const payload_len = readU16(response, 18);
        if (abi.net_service_header_size + payload_len > response.len) return null;
        status.* = readI32(response, 20);
        return response[abi.net_service_header_size .. abi.net_service_header_size + payload_len];
    }

    pub fn netSocketBegin(self: *const Context, service: NetSocketService, op: u16, payload_in: []const u8, timeout_ticks: u64, request: *NetSocketRequest) i32 {
        if (payload_in.len > request.request.len) return abi.io_error_too_large;
        if (request.active) return abi.io_error_busy;
        // NetSocketRequest owns every buffer referenced by the asynchronous
        // kernel request. Do not submit unless the complete wait/close path is
        // available, otherwise a caller could never end that pointer lifetime.
        if (!self.hasSysFn("service_open") or
            !self.hasSysFn("service_close") or
            !self.hasSysFn("io_service_call") or
            !self.hasSysFn("io_wait") or
            !self.hasSysFn("io_close"))
        {
            return self.unavailable("sys");
        }

        request.* = .{
            .active = true,
            .service = service,
            .op = op,
            .request_len = @intCast(payload_in.len),
        };
        if (payload_in.len != 0) @memcpy(request.request[0..payload_in.len], payload_in);

        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(netSocketServiceName(service), &info);
        if (handle_rc != abi.service_api_result_ok or info.handle == 0) {
            request.reset();
            return if (handle_rc < 0) handle_rc else abi.service_api_result_no_endpoint;
        }
        request.service_handle = info.handle;

        var request_id: u32 = 0;
        const submit_rc = self.ioServiceCall(
            info.handle,
            op,
            request.request[0..payload_in.len],
            &request.header,
            request.response[0..],
            timeout_ticks,
            0,
            &request_id,
        );
        if (submit_rc != abi.io_ok) {
            _ = self.serviceClose(info.handle);
            request.reset();
            return submit_rc;
        }
        request.request_id = request_id;
        return abi.io_ok;
    }

    pub fn netSocketStatus(self: *const Context, request: *NetSocketRequest) i32 {
        if (!request.active or request.request_id == 0) return abi.io_error_not_found;
        const rc = self.ioStatus(request.request_id, &request.info);
        if (rc == abi.io_ok) updateNetSocketResponseLen(request);
        return rc;
    }

    pub fn netSocketWait(self: *const Context, request: *NetSocketRequest, timeout_ticks: u64) i32 {
        if (!request.active or request.request_id == 0) return abi.io_error_not_found;
        const rc = self.ioWait(request.request_id, timeout_ticks, &request.info);
        if (rc == abi.io_ok) updateNetSocketResponseLen(request);
        return rc;
    }

    pub fn netSocketClose(self: *const Context, request: *NetSocketRequest) i32 {
        if (!request.active or request.request_id == 0) return abi.io_error_not_found;
        const close_rc = self.ioClose(request.request_id);
        if (close_rc != abi.io_ok and close_rc != abi.io_error_not_found) return close_rc;
        const handle = request.service_handle;
        request.reset();
        if (handle != 0) _ = self.serviceClose(handle);
        return close_rc;
    }

    // Stack-local NetSocketRequests must not disappear while the async worker
    // still owns pointers into them. A finite caller wait may expire before a
    // loaded worker even starts its own service timeout, so close can report
    // BUSY. Drain that exact request without a second timeout, then retry the
    // release. The caller still observes its original finite timeout result.
    fn netSocketDrainAndClose(self: *const Context, request: *NetSocketRequest) void {
        while (request.active and request.request_id != 0) {
            const close_rc = self.netSocketClose(request);
            if (close_rc != abi.io_error_busy) return;

            while (self.netSocketWait(request, abi.io_wait_forever) == abi.io_error_busy) {
                self.sleepTicks(1);
            }
        }
    }

    pub fn netSocketWaitAndClose(self: *const Context, request: *NetSocketRequest, timeout_ticks: u64) i32 {
        const wait_rc = self.netSocketWait(request, timeout_ticks);
        if (wait_rc != abi.io_ok) return wait_rc;
        return self.netSocketClose(request);
    }

    fn netSocketServiceTimeoutTicks(self: *const Context, wait_ticks: u64, default_timeout_ms: u64) u64 {
        if (wait_ticks == abi.io_wait_forever) return self.ticksFromMilliseconds(default_timeout_ms);
        return if (wait_ticks == 0) 1 else wait_ticks;
    }

    fn netSocketCompletionWaitTicks(self: *const Context, service_timeout_ticks: u64, wait_ticks: u64) u64 {
        if (wait_ticks == abi.io_wait_forever) return abi.io_wait_forever;
        return service_timeout_ticks +| self.ticksFromMilliseconds(net_socket_completion_grace_ms);
    }

    pub fn tcpBeginStatusService(self: *const Context, request: *NetSocketRequest) i32 {
        return self.tcpBeginStatusServiceWithTimeout(request, self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms));
    }

    pub fn tcpBeginStatusServiceWithTimeout(self: *const Context, request: *NetSocketRequest, timeout_ticks: u64) i32 {
        return self.netSocketBegin(.tcp, abi.net_service_op_tcp_status_result, "", timeout_ticks, request);
    }

    pub fn tcpBeginServiceResult(self: *const Context, op: u16, payload_in: []const u8, request: *NetSocketRequest) i32 {
        return self.tcpBeginServiceResultWithTimeout(op, payload_in, request, self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms));
    }

    pub fn tcpBeginServiceResultWithTimeout(self: *const Context, op: u16, payload_in: []const u8, request: *NetSocketRequest, timeout_ticks: u64) i32 {
        return self.netSocketBegin(.tcp, op, payload_in, timeout_ticks, request);
    }

    pub fn tcpBeginConnectService(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, request: *NetSocketRequest) i32 {
        var payload: [6]u8 = .{ a, b, c, d, 0, 0 };
        writeU16(payload[0..], 4, port);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_connect_result, payload[0..], request);
    }

    pub fn tcpBeginWriteChunkService(self: *const Context, handle: u32, data: []const u8, request: *NetSocketRequest) i32 {
        if (data.len > abi.net_service_tcp_write_max) return abi.io_error_too_large;
        var payload: [abi.net_service_tcp_message_payload_max]u8 = .{0} ** abi.net_service_tcp_message_payload_max;
        writeU32(payload[0..], 0, handle);
        if (data.len != 0) @memcpy(payload[4 .. 4 + data.len], data);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_write_result, payload[0 .. 4 + data.len], request);
    }

    pub fn tcpBeginReadService(self: *const Context, handle: u32, capacity: usize, request: *NetSocketRequest) i32 {
        const max_len: u16 = @intCast(@min(capacity, abi.net_service_tcp_read_max));
        var payload: [6]u8 = .{0} ** 6;
        writeU32(payload[0..], 0, handle);
        writeU16(payload[0..], 4, max_len);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_read_result, payload[0..], request);
    }

    pub fn tcpBeginPollService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        var payload: [4]u8 = .{0} ** 4;
        writeU32(payload[0..], 0, handle);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_poll_result, payload[0..], request);
    }

    pub fn tcpBeginListenService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        var payload: [2]u8 = .{0} ** 2;
        writeU16(payload[0..], 0, port);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_listen_result, payload[0..], request);
    }

    pub fn tcpBeginAcceptService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        var payload: [2]u8 = .{0} ** 2;
        writeU16(payload[0..], 0, port);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_accept_result, payload[0..], request);
    }

    pub fn tcpBeginAcceptPollService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        var payload: [2]u8 = .{0} ** 2;
        writeU16(payload[0..], 0, port);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_accept_poll_result, payload[0..], request);
    }

    pub fn tcpBeginAcceptReadService(self: *const Context, port: u16, capacity: usize, request: *NetSocketRequest) i32 {
        const max_len: u16 = @intCast(@min(capacity, abi.net_service_tcp_read_max));
        var payload: [4]u8 = .{0} ** 4;
        writeU16(payload[0..], 0, port);
        writeU16(payload[0..], 2, max_len);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_accept_read_result, payload[0..], request);
    }

    pub fn tcpBeginCloseService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        var payload: [4]u8 = .{0} ** 4;
        writeU32(payload[0..], 0, handle);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_close_result, payload[0..], request);
    }

    pub fn tcpBeginAbortService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        var payload: [4]u8 = .{0} ** 4;
        writeU32(payload[0..], 0, handle);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_abort_result, payload[0..], request);
    }

    pub fn tcpBeginRetransmitService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        var payload: [4]u8 = .{0} ** 4;
        writeU32(payload[0..], 0, handle);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_retransmit_result, payload[0..], request);
    }

    pub fn tcpBeginCloseListenService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        var payload: [2]u8 = .{0} ** 2;
        writeU16(payload[0..], 0, port);
        return self.tcpBeginServiceResult(abi.net_service_op_tcp_close_listen_result, payload[0..], request);
    }

    pub fn udpBeginStatusService(self: *const Context, request: *NetSocketRequest) i32 {
        return self.netSocketBegin(.udp, abi.net_service_op_udp_status_result, "", self.ticksFromMilliseconds(udp_r4x_service_timeout_ms), request);
    }

    pub fn udpBeginServiceResult(self: *const Context, op: u16, payload_in: []const u8, request: *NetSocketRequest) i32 {
        return self.netSocketBegin(.udp, op, payload_in, self.ticksFromMilliseconds(udp_r4x_service_timeout_ms), request);
    }

    pub fn udpBeginBindService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        var payload: [2]u8 = .{0} ** 2;
        writeU16(payload[0..], 0, port);
        return self.udpBeginServiceResult(abi.net_service_op_udp_bind_result, payload[0..], request);
    }

    pub fn udpBeginSendToService(self: *const Context, handle: u32, dest_ip: [4]u8, dest_port: u16, payload_in: []const u8, request: *NetSocketRequest) i32 {
        if (payload_in.len > abi.net_service_udp_send_max) return abi.io_error_too_large;
        var payload: [abi.net_service_tcp_message_payload_max]u8 = .{0} ** abi.net_service_tcp_message_payload_max;
        writeU32(payload[0..], 0, handle);
        payload[4] = dest_ip[0];
        payload[5] = dest_ip[1];
        payload[6] = dest_ip[2];
        payload[7] = dest_ip[3];
        writeU16(payload[0..], 8, dest_port);
        if (payload_in.len != 0) @memcpy(payload[10 .. 10 + payload_in.len], payload_in);
        return self.udpBeginServiceResult(abi.net_service_op_udp_sendto_result, payload[0 .. 10 + payload_in.len], request);
    }

    pub fn udpBeginRecvFromService(self: *const Context, handle: u32, capacity: usize, request: *NetSocketRequest) i32 {
        const max_len: u16 = @intCast(@min(capacity, abi.net_service_udp_read_max));
        var payload: [6]u8 = .{0} ** 6;
        writeU32(payload[0..], 0, handle);
        writeU16(payload[0..], 4, max_len);
        return self.udpBeginServiceResult(abi.net_service_op_udp_recv_result, payload[0..], request);
    }

    pub fn udpBeginCloseService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        var payload: [4]u8 = .{0} ** 4;
        writeU32(payload[0..], 0, handle);
        return self.udpBeginServiceResult(abi.net_service_op_udp_close_result, payload[0..], request);
    }

    pub fn netResolveA(self: *const Context, name: []const u8, options: ResolverOptions, out: *ResolverResult) i32 {
        out.* = .{};
        var structured: abi.NetServiceDnsResult = .{};
        const service_result = if (options.server) |server|
            self.netDnsResolveServerServiceResult(server, name, &structured)
        else
            self.netDnsResolveServiceResult(name, &structured);

        if (service_result == 0) {
            fillResolverFromService(out, structured);
            return out.result;
        }

        out.result = service_result;
        out.service_status = abi.net_service_status_failed;
        copyFixedZ(out.last_error[0..], "dns-service-request-error");
        if (options.server) |server| {
            out.server = server;
            out.explicit_server = true;
        }
        return service_result;
    }

    pub fn netDnsResolveService(self: *const Context, name: []const u8, out: *[4]u8) i32 {
        return self.netDnsResolveServiceOp(abi.net_service_op_dns_resolve_a, name, out);
    }

    pub fn netDnsResolveServerService(self: *const Context, server: [4]u8, name: []const u8, out: *[4]u8) i32 {
        if (name.len > abi.ipc_max_message_size - abi.net_service_header_size - 4) return abi.dns_result_name;
        var request: [abi.ipc_max_message_size - abi.net_service_header_size]u8 = .{0} ** (abi.ipc_max_message_size - abi.net_service_header_size);
        request[0] = server[0];
        request[1] = server[1];
        request[2] = server[2];
        request[3] = server[3];
        if (name.len != 0) @memcpy(request[4 .. 4 + name.len], name);
        return self.netDnsResolveServiceOp(abi.net_service_op_dns_resolve_a_server, request[0 .. 4 + name.len], out);
    }

    fn netDnsResolveServiceOp(self: *const Context, op: u16, payload_in: []const u8, out: *[4]u8) i32 {
        var structured: abi.NetServiceDnsResult = .{};
        const result_op: u16 = if (op == abi.net_service_op_dns_resolve_a_server)
            abi.net_service_op_dns_resolve_a_server_result
        else
            abi.net_service_op_dns_resolve_a_result;
        if (self.netDnsResolveServiceResultOp(result_op, payload_in, &structured) == 0) {
            out.* = structured.answer;
            return structured.result;
        }
        return abi.dns_result_tx;
    }

    pub fn netDnsResolveServiceResult(self: *const Context, name: []const u8, out: *abi.NetServiceDnsResult) i32 {
        return self.netDnsResolveServiceResultOp(abi.net_service_op_dns_resolve_a_result, name, out);
    }

    pub fn netDnsResolveServerServiceResult(self: *const Context, server: [4]u8, name: []const u8, out: *abi.NetServiceDnsResult) i32 {
        if (name.len > abi.ipc_max_message_size - abi.net_service_header_size - 4) return abi.dns_result_name;
        var request: [abi.ipc_max_message_size - abi.net_service_header_size]u8 = .{0} ** (abi.ipc_max_message_size - abi.net_service_header_size);
        request[0] = server[0];
        request[1] = server[1];
        request[2] = server[2];
        request[3] = server[3];
        if (name.len != 0) @memcpy(request[4 .. 4 + name.len], name);
        return self.netDnsResolveServiceResultOp(abi.net_service_op_dns_resolve_a_server_result, request[0 .. 4 + name.len], out);
    }

    pub fn netDnsServiceStatusRaw(self: *const Context, out: *abi.NetServiceDnsStatus) i32 {
        if (self.netDnsR4xServiceStatusRaw(out) == 0) return 0;
        markDnsServiceUnavailableStatus(out);
        return 0;
    }

    fn netDnsResolveServiceResultOp(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceDnsResult) i32 {
        if (self.netDnsR4xServiceResultOp(op, payload_in, out) == 0) return 0;
        markDnsServiceUnavailableResult(out, op);
        return 0;
    }

    fn netDnsR4xServiceStatusRaw(self: *const Context, out: *abi.NetServiceDnsStatus) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(dns_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok or info.handle == 0) return -1;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [abi.service_api_max_payload]u8 = undefined;
        const got = self.serviceCall(info.handle, abi.net_service_op_dns_status_result, "", &header, response[0..], self.ticksFromMilliseconds(dns_r4x_service_timeout_ms));
        if (got < @as(i32, @intCast(@sizeOf(abi.NetServiceDnsStatus))) or header.status != abi.service_api_result_ok) return -1;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.NetServiceDnsStatus)], response[0..@sizeOf(abi.NetServiceDnsStatus)]);
        if (out.magic != abi.net_service_dns_status_magic or out.version != abi.net_service_dns_status_version) return -1;
        return 0;
    }

    fn netDnsR4xServiceResultOp(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceDnsResult) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(dns_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok or info.handle == 0) return abi.dns_result_tx;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [abi.service_api_max_payload]u8 = undefined;
        const got = self.serviceCall(info.handle, op, payload_in, &header, response[0..], self.ticksFromMilliseconds(dns_r4x_service_timeout_ms));
        if (got < @as(i32, @intCast(@sizeOf(abi.NetServiceDnsResult))) or header.status != abi.service_api_result_ok) return abi.dns_result_tx;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.NetServiceDnsResult)], response[0..@sizeOf(abi.NetServiceDnsResult)]);
        if (out.magic != abi.net_service_dns_result_magic or out.version != abi.net_service_dns_result_version) return abi.dns_result_tx;
        return 0;
    }

    pub fn netDhcpAcquireService(self: *const Context) i32 {
        return self.netDhcpServiceAction(abi.net_service_op_dhcp_acquire_result, abi.net_service_op_dhcp_acquire);
    }

    pub fn netDhcpRenewService(self: *const Context) i32 {
        return self.netDhcpServiceAction(abi.net_service_op_dhcp_renew_result, abi.net_service_op_dhcp_renew);
    }

    pub fn netDhcpReleaseService(self: *const Context) i32 {
        return self.netDhcpServiceAction(abi.net_service_op_dhcp_release_result, abi.net_service_op_dhcp_release);
    }

    pub fn netDhcpServiceStatus(self: *const Context, out: *abi.DhcpStatus) i32 {
        var structured: abi.NetServiceDhcpStatus = .{};
        if (self.netDhcpServiceStatusRaw(&structured) != 0) return -1;
        out.* = .{
            .discover_tx = structured.discover_tx,
            .offer_rx = structured.offer_rx,
            .request_tx = structured.request_tx,
            .ack_rx = structured.ack_rx,
            .nak_rx = structured.nak_rx,
            .release_tx = structured.release_tx,
            .retries = structured.retries,
            .timeouts = structured.timeouts,
            .release_errors = structured.release_errors,
            .malformed = structured.malformed,
            .self_tests = structured.self_tests,
            .xid = structured.xid,
            .offered_ip = structured.offered_ip,
            .server_ip = structured.server_ip,
            .netmask = structured.netmask,
            .gateway_ip = structured.gateway_ip,
            .dns_ip = structured.dns_ip,
            .lease_seconds = structured.lease_seconds,
            .renew_seconds = structured.renew_seconds,
            .rebind_seconds = structured.rebind_seconds,
            .flags = dhcpStatusFlagsFromService(structured.flags),
            .last_attempt = @intCast(@min(structured.last_attempt, 0xFF)),
            .last_type = @intCast(@min(structured.last_type, 0xFF)),
            .runtime_state = structured.runtime_state,
            .last_error = structured.last_error,
        };
        return 1;
    }

    pub fn netDhcpServiceStatusRaw(self: *const Context, out: *abi.NetServiceDhcpStatus) i32 {
        if (self.netDhcpR4xServiceStatusRaw(out) == 0) return 0;
        markDhcpServiceUnavailableStatus(out);
        return 0;
    }

    pub fn netDhcpServiceAction(self: *const Context, result_op: u16, _: u16) i32 {
        var structured: abi.NetServiceDhcpResult = .{};
        if (self.netDhcpServiceActionResult(result_op, &structured) == 0) return netTxResultFromCode(structured.result);
        return abi.net_tx_backend_error;
    }

    pub fn netDhcpServiceActionResult(self: *const Context, op: u16, out: *abi.NetServiceDhcpResult) i32 {
        if (self.netDhcpR4xServiceActionResult(op, out) == 0) return 0;
        markDhcpServiceUnavailableResult(out, op);
        return 0;
    }

    fn netDhcpR4xServiceStatusRaw(self: *const Context, out: *abi.NetServiceDhcpStatus) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(dhcp_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok or info.handle == 0) return -1;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [abi.service_api_max_payload]u8 = undefined;
        const got = self.serviceCall(info.handle, abi.net_service_op_dhcp_status_result, "", &header, response[0..], self.ticksFromMilliseconds(dhcp_r4x_service_timeout_ms));
        if (got < @as(i32, @intCast(@sizeOf(abi.NetServiceDhcpStatus))) or header.status != abi.service_api_result_ok) return -1;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.NetServiceDhcpStatus)], response[0..@sizeOf(abi.NetServiceDhcpStatus)]);
        if (out.magic != abi.net_service_dhcp_status_magic or out.version != abi.net_service_dhcp_status_version) return -1;
        return 0;
    }

    fn netDhcpR4xServiceActionResult(self: *const Context, op: u16, out: *abi.NetServiceDhcpResult) i32 {
        var info: abi.ServiceInfo = .{};
        const handle_rc = self.serviceOpen(dhcp_r4x_service_name, &info);
        if (handle_rc != abi.service_api_result_ok or info.handle == 0) return abi.net_tx_backend_error;
        defer _ = self.serviceClose(info.handle);

        var header: abi.ServiceMessageHeader = .{};
        var response: [abi.service_api_max_payload]u8 = undefined;
        var request: [service_deadline.footer_size]u8 = undefined;
        const timeout_ticks = self.ticksFromMilliseconds(dhcp_r4x_service_timeout_ms);
        const deadline_tick = self.ticks() +| timeout_ticks;
        const payload = service_deadline.append(request[0..], "", deadline_tick) orelse return abi.net_tx_backend_error;
        const got = self.serviceCall(info.handle, op, payload, &header, response[0..], timeout_ticks);
        if (got < @as(i32, @intCast(@sizeOf(abi.NetServiceDhcpResult))) or header.status != abi.service_api_result_ok) return abi.net_tx_backend_error;
        const out_bytes: [*]u8 = @ptrCast(out);
        @memcpy(out_bytes[0..@sizeOf(abi.NetServiceDhcpResult)], response[0..@sizeOf(abi.NetServiceDhcpResult)]);
        if (out.magic != abi.net_service_dhcp_result_magic or out.version != abi.net_service_dhcp_result_version) return abi.net_tx_backend_error;
        return 0;
    }

    pub fn udpServiceStatusRaw(self: *const Context, out: *abi.NetServiceUdpStatus) i32 {
        if (self.udpR4xServiceStatusRaw(out) == 0) return 0;
        markUdpServiceUnavailableStatus(out);
        return 0;
    }

    pub fn udpServiceResult(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceUdpResult, data_out: []u8) i32 {
        if (self.udpR4xServiceResult(op, payload_in, out, data_out) == 0) return 0;
        markUdpServiceUnavailableResult(out, op);
        return 0;
    }

    fn udpR4xServiceStatusRaw(self: *const Context, out: *abi.NetServiceUdpStatus) i32 {
        var request: NetSocketRequest = .{};
        if (self.udpBeginStatusService(&request) != abi.io_ok) return -1;
        defer self.netSocketDrainAndClose(&request);
        if (self.netSocketWait(&request, abi.io_wait_forever) != abi.io_ok) return -1;
        if (request.info.result < @as(i32, @intCast(@sizeOf(abi.NetServiceUdpStatus))) or request.header.status != abi.service_api_result_ok) return -1;
        if (!request.udpStatus(out)) return -1;
        return 0;
    }

    fn udpR4xServiceResult(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceUdpResult, data_out: []u8) i32 {
        var request: NetSocketRequest = .{};
        if (self.udpBeginServiceResult(op, payload_in, &request) != abi.io_ok) return -1;
        defer self.netSocketDrainAndClose(&request);
        if (self.netSocketWait(&request, abi.io_wait_forever) != abi.io_ok) return -1;
        if (request.info.result < @as(i32, @intCast(@sizeOf(abi.NetServiceUdpResult))) or request.header.status != abi.service_api_result_ok) return -1;
        if (!request.udpResult(out)) return -1;
        const available = request.udpData(out) orelse return -1;
        if ((out.flags & abi.net_service_udp_flag_data) != 0 and out.bytes != 0) {
            if (out.bytes > available.len or out.bytes > data_out.len) return -1;
            @memcpy(data_out[0..@as(usize, @intCast(out.bytes))], available[0..@as(usize, @intCast(out.bytes))]);
        }
        return 0;
    }

    pub fn udpBindService(self: *const Context, port: u16) i32 {
        var request: [2]u8 = .{0} ** 2;
        writeU16(request[0..], 0, port);
        var structured: abi.NetServiceUdpResult = .{};
        if (self.udpServiceResult(abi.net_service_op_udp_bind_result, request[0..], &structured, "") == 0) {
            if (structured.result == 0 and (structured.flags & abi.net_service_udp_flag_handle_valid) != 0) return @intCast(structured.handle);
            return structured.result;
        }
        return -1;
    }

    pub fn udpSendToService(self: *const Context, handle: u32, dest_ip: [4]u8, dest_port: u16, payload_in: []const u8) i32 {
        if (payload_in.len > abi.net_service_udp_send_max) return abi.net_tx_too_large;
        var request: [abi.net_service_tcp_message_payload_max]u8 = .{0} ** abi.net_service_tcp_message_payload_max;
        writeU32(request[0..], 0, handle);
        request[4] = dest_ip[0];
        request[5] = dest_ip[1];
        request[6] = dest_ip[2];
        request[7] = dest_ip[3];
        writeU16(request[0..], 8, dest_port);
        if (payload_in.len != 0) @memcpy(request[10 .. 10 + payload_in.len], payload_in);
        var structured: abi.NetServiceUdpResult = .{};
        if (self.udpServiceResult(abi.net_service_op_udp_sendto_result, request[0 .. 10 + payload_in.len], &structured, "") == 0) return structured.result;
        return abi.net_tx_backend_error;
    }

    pub fn udpRecvFromService(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload_out: []u8) i32 {
        var structured: abi.NetServiceUdpResult = .{};
        return self.udpRecvFromServiceResult(handle, out, payload_out, &structured);
    }

    pub fn udpRecvFromServiceResult(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload_out: []u8, result: *abi.NetServiceUdpResult) i32 {
        const max_len: u16 = @intCast(@min(payload_out.len, abi.net_service_udp_read_max));
        if (max_len == 0) return 0;
        var request: [6]u8 = .{0} ** 6;
        writeU32(request[0..], 0, handle);
        writeU16(request[0..], 4, max_len);
        if (self.udpServiceResult(abi.net_service_op_udp_recv_result, request[0..], result, payload_out) != 0) return -1;
        if (result.result != 0) return result.result;
        out.* = .{
            .source_ip = result.source_ip,
            .dest_ip = result.dest_ip,
            .source_port = result.source_port,
            .dest_port = result.dest_port,
            .length = @intCast(@min(result.bytes, 0xFFFF)),
        };
        return @intCast(result.bytes);
    }

    pub fn udpRecvFromWaitService(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload_out: []u8, wait_ticks: u64) i32 {
        if (payload_out.len == 0) return 0;
        const start = self.ticks();
        while (true) {
            var structured: abi.NetServiceUdpResult = .{};
            const got = self.udpRecvFromServiceResult(handle, out, payload_out, &structured);
            if (got < 0) return got;
            if (got > 0 or (structured.flags & abi.net_service_udp_flag_data) != 0) return got;
            if (serviceStatusCodeFromFlags(structured.flags) != abi.net_service_status_would_block) return got;
            if (wait_ticks == 0 or self.ticks() - start >= wait_ticks) return 0;
            self.sleepTicks(1);
        }
    }

    pub fn udpCloseService(self: *const Context, handle: u32) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        var structured: abi.NetServiceUdpResult = .{};
        if (self.udpServiceResult(abi.net_service_op_udp_close_result, request[0..], &structured, "") != 0) return -1;
        return structured.result;
    }

    pub fn tcpServiceStatusRaw(self: *const Context, out: *abi.NetServiceTcpStatus) i32 {
        if (self.tcpR4xServiceStatusRaw(out) == 0) return 0;
        markTcpServiceUnavailableStatus(out);
        return 0;
    }

    pub fn tcpServiceStatusRawWait(self: *const Context, out: *abi.NetServiceTcpStatus, wait_ticks: u64) i32 {
        if (self.tcpR4xServiceStatusRawWait(out, wait_ticks) == 0) return 0;
        markTcpServiceUnavailableStatus(out);
        return 0;
    }

    pub fn tcpServiceResult(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceTcpResult, data_out: []u8) i32 {
        if (self.tcpR4xServiceResult(op, payload_in, out, data_out) == 0) return 0;
        markTcpServiceUnavailableResult(out, op);
        return 0;
    }

    pub fn tcpServiceResultWait(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceTcpResult, data_out: []u8, wait_ticks: u64) i32 {
        if (self.tcpR4xServiceResultWait(op, payload_in, out, data_out, wait_ticks) == 0) return 0;
        markTcpServiceUnavailableResult(out, op);
        return 0;
    }

    fn tcpR4xServiceStatusRaw(self: *const Context, out: *abi.NetServiceTcpStatus) i32 {
        return self.tcpR4xServiceStatusRawWait(out, abi.io_wait_forever);
    }

    fn tcpR4xServiceStatusRawWait(self: *const Context, out: *abi.NetServiceTcpStatus, wait_ticks: u64) i32 {
        const service_timeout_ticks = self.netSocketServiceTimeoutTicks(wait_ticks, tcp_r4x_service_timeout_ms);
        const completion_wait_ticks = self.netSocketCompletionWaitTicks(service_timeout_ticks, wait_ticks);
        var request: NetSocketRequest = .{};
        if (self.tcpBeginStatusServiceWithTimeout(&request, service_timeout_ticks) != abi.io_ok) return -1;
        defer self.netSocketDrainAndClose(&request);
        if (self.netSocketWait(&request, completion_wait_ticks) != abi.io_ok) return -1;
        if (request.info.result < @as(i32, @intCast(@sizeOf(abi.NetServiceTcpStatus))) or request.header.status != abi.service_api_result_ok) return -1;
        if (!request.tcpStatus(out)) return -1;
        return 0;
    }

    fn tcpR4xServiceResult(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceTcpResult, data_out: []u8) i32 {
        return self.tcpR4xServiceResultWait(op, payload_in, out, data_out, abi.io_wait_forever);
    }

    fn tcpR4xServiceResultWait(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceTcpResult, data_out: []u8, wait_ticks: u64) i32 {
        const service_timeout_ticks = self.netSocketServiceTimeoutTicks(wait_ticks, tcp_r4x_service_timeout_ms);
        const completion_wait_ticks = self.netSocketCompletionWaitTicks(service_timeout_ticks, wait_ticks);
        var request: NetSocketRequest = .{};
        if (self.tcpBeginServiceResultWithTimeout(op, payload_in, &request, service_timeout_ticks) != abi.io_ok) return -1;
        defer self.netSocketDrainAndClose(&request);
        if (self.netSocketWait(&request, completion_wait_ticks) != abi.io_ok) return -1;
        if (request.info.result < @as(i32, @intCast(@sizeOf(abi.NetServiceTcpResult))) or request.header.status != abi.service_api_result_ok) return -1;
        if (!request.tcpResult(out)) return -1;
        const available = request.tcpData(out) orelse return -1;
        if ((out.flags & abi.net_service_tcp_flag_data) != 0 and out.bytes != 0) {
            if (out.bytes > available.len or out.bytes > data_out.len) return -1;
            @memcpy(data_out[0..@as(usize, @intCast(out.bytes))], available[0..@as(usize, @intCast(out.bytes))]);
        }
        return 0;
    }

    pub fn tcpConnectServiceResult(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpConnectServiceResultWait(a, b, c, d, port, result, self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms));
    }

    pub fn tcpConnectServiceResultWait(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [6]u8 = .{ a, b, c, d, 0, 0 };
        writeU16(request[0..], 4, port);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_connect_result, request[0..], result, "", wait_ticks) != 0) return -1;
        if (result.result == 0 and (result.flags & abi.net_service_tcp_flag_handle_valid) != 0) return @intCast(result.handle);
        return result.result;
    }

    pub fn tcpConnectService(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16) i32 {
        return self.tcpConnectServiceWait(a, b, c, d, port, self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms));
    }

    pub fn tcpConnectServiceWait(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, wait_ticks: u64) i32 {
        var request: [6]u8 = .{ a, b, c, d, 0, 0 };
        writeU16(request[0..], 4, port);
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_connect_result, request[0..], &structured, "", wait_ticks) == 0) {
            if (structured.result == 0 and (structured.flags & abi.net_service_tcp_flag_handle_valid) != 0) return @intCast(structured.handle);
            return -1;
        }
        return -1;
    }

    pub fn tcpWriteService(self: *const Context, handle: u32, data: []const u8) i32 {
        if (data.len == 0) return 0;
        return self.tcpWritePacedServiceBounded(handle, data, self.ticksFromMilliseconds(tcp_write_default_wait_ms), self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms));
    }

    pub fn tcpWriteChunkServiceResult(self: *const Context, handle: u32, data: []const u8, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpWriteChunkServiceResultWait(handle, data, result, abi.io_wait_forever);
    }

    pub fn tcpWriteChunkServiceResultWait(self: *const Context, handle: u32, data: []const u8, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        if (data.len > abi.net_service_tcp_write_max) return -1;
        var request: [abi.net_service_tcp_message_payload_max]u8 = .{0} ** abi.net_service_tcp_message_payload_max;
        writeU32(request[0..], 0, handle);
        if (data.len != 0) @memcpy(request[4 .. 4 + data.len], data);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_write_result, request[0 .. 4 + data.len], result, "", wait_ticks) != 0) return -1;
        if (result.result == 0) return @intCast(result.bytes);
        return result.result;
    }

    pub fn tcpWritePacedService(self: *const Context, handle: u32, data: []const u8, wait_ticks: u64) i32 {
        return self.tcpWritePacedServiceBounded(handle, data, wait_ticks, abi.io_wait_forever);
    }

    pub fn tcpWritePacedServiceBounded(self: *const Context, handle: u32, data: []const u8, wait_ticks: u64, service_wait_ticks: u64) i32 {
        var offset: usize = 0;
        while (offset < data.len) {
            const chunk_len = @min(data.len - offset, abi.net_service_tcp_write_max);
            const written = self.tcpWriteChunkServiceWait(handle, data[offset .. offset + chunk_len], service_wait_ticks);
            if (written == 0) {
                // Poll only after the optimistic write proved that the
                // remote window/catalog cannot currently accept progress.
                const window = self.tcpWaitForTxWindowServiceBounded(handle, wait_ticks, service_wait_ticks);
                if (window < 0) return -1;
                if (window == 0) return -1;
                continue;
            }
            if (written < 0) return -1;
            const written_len: usize = @intCast(written);
            if (written_len == 0 or written_len > chunk_len) return -1;
            offset += written_len;
        }
        return @intCast(data.len);
    }

    pub fn tcpWaitForTxWindowService(self: *const Context, handle: u32, wait_ticks: u64) i32 {
        return self.tcpWaitForTxWindowServiceBounded(handle, wait_ticks, abi.io_wait_forever);
    }

    pub fn tcpWaitForTxWindowServiceBounded(self: *const Context, handle: u32, wait_ticks: u64, service_wait_ticks: u64) i32 {
        var poll: abi.NetServiceTcpResult = .{};
        if (self.tcpPollServiceWait(handle, &poll, service_wait_ticks) < 0) return -1;
        var readiness = tcpResultReadiness(&poll);
        if (readiness.terminal) return -1;
        if (readiness.writable) return @intCast(readiness.tx_window);
        if (wait_ticks == 0) return 0;

        const start = self.ticks();
        while (self.ticks() - start < wait_ticks) {
            self.sleepTicks(1);
            poll = .{};
            if (self.tcpPollServiceWait(handle, &poll, service_wait_ticks) < 0) return -1;
            readiness = tcpResultReadiness(&poll);
            if (readiness.terminal) return -1;
            if (readiness.writable) return @intCast(readiness.tx_window);
        }
        return 0;
    }

    pub fn tcpWriteChunkService(self: *const Context, handle: u32, data: []const u8) i32 {
        return self.tcpWriteChunkServiceWait(handle, data, abi.io_wait_forever);
    }

    pub fn tcpWriteChunkServiceWait(self: *const Context, handle: u32, data: []const u8, wait_ticks: u64) i32 {
        if (data.len > abi.net_service_tcp_write_max) return -1;
        var request: [abi.net_service_tcp_message_payload_max]u8 = .{0} ** abi.net_service_tcp_message_payload_max;
        writeU32(request[0..], 0, handle);
        if (data.len != 0) @memcpy(request[4 .. 4 + data.len], data);
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_write_result, request[0 .. 4 + data.len], &structured, "", wait_ticks) == 0) {
            if (structured.result == 0) return @intCast(structured.bytes);
            return -1;
        }
        return -1;
    }

    pub fn tcpReadServiceResult(self: *const Context, handle: u32, out: []u8, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpReadServiceResultWait(handle, out, result, abi.io_wait_forever);
    }

    pub fn tcpReadServiceResultWait(self: *const Context, handle: u32, out: []u8, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        const max_len: u16 = @intCast(@min(out.len, abi.net_service_tcp_read_max));
        var request: [6]u8 = .{0} ** 6;
        writeU32(request[0..], 0, handle);
        writeU16(request[0..], 4, max_len);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_read_result, request[0..], result, out, wait_ticks) != 0) return -1;
        if (result.result != 0) return result.result;
        return @intCast(result.bytes);
    }

    pub fn tcpReadService(self: *const Context, handle: u32, out: []u8) i32 {
        return self.tcpReadServiceWait(handle, out, abi.io_wait_forever);
    }

    pub fn tcpReadServiceWait(self: *const Context, handle: u32, out: []u8, wait_ticks: u64) i32 {
        const max_len: u16 = @intCast(@min(out.len, abi.net_service_tcp_read_max));
        var request: [6]u8 = .{0} ** 6;
        writeU32(request[0..], 0, handle);
        writeU16(request[0..], 4, max_len);
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_read_result, request[0..], &structured, out, wait_ticks) == 0) {
            if (structured.result != 0) return -1;
            return @intCast(structured.bytes);
        }
        return -1;
    }

    pub fn tcpReadAvailableService(self: *const Context, handle: u32, out: []u8) i32 {
        var total: usize = 0;
        while (total < out.len) {
            const got = self.tcpReadService(handle, out[total..]);
            if (got < 0) return if (total == 0) -1 else @intCast(total);
            if (got == 0) break;

            const got_len: usize = @intCast(got);
            total += got_len;
            if (got_len < abi.net_service_tcp_read_max) break;
        }
        return @intCast(total);
    }

    pub fn tcpReadWaitService(self: *const Context, handle: u32, out: []u8, wait_ticks: u64) i32 {
        return self.tcpReadWaitServiceBounded(handle, out, wait_ticks, abi.io_wait_forever);
    }

    // 0.56.39: Consume-sicherer Warte-Read. Der POLL bleibt budgetiert
    // (idempotent, Retry gefahrlos), aber der DATEN-KONSUMIERENDE Read
    // laeuft mit io_wait_forever: ein Service-Timeout auf dem Read-Op
    // kann die Antwort eines BEREITS AUSGEFUEHRTEN Reads verwerfen -
    // die Bytes sind dann aus dem Kernel-RX konsumiert und fuer immer
    // verloren (FTP-STOR-Befund: exakt tcp_read_max fehlte bei
    // trotzdem gemeldetem 226; endpoint timeout/cancel-Zaehler belegten
    // die verworfenen Calls). Gleiches Prinzip wie der 0.56.5-
    // tx_seq-Schutz, nur dass Reads keine Retry-Verifikation haben
    // koennen - deshalb darf der Read-Call selbst nicht verfallen.
    pub fn tcpReadWaitServiceConsumeSafe(self: *const Context, handle: u32, out: []u8, wait_ticks: u64, poll_wait_ticks: u64) i32 {
        if (out.len == 0) return 0;

        var poll: abi.NetServiceTcpResult = .{};
        if (self.tcpPollServiceWait(handle, &poll, poll_wait_ticks) < 0) return -1;
        var readiness = tcpResultReadiness(&poll);
        if (readiness.readable) return self.tcpReadServiceWait(handle, out, abi.io_wait_forever);
        if (readiness.terminal) return -1;
        if (wait_ticks == 0) return 0;

        const start = self.ticks();
        while (self.ticks() - start < wait_ticks) {
            poll = .{};
            if (self.tcpPollServiceWait(handle, &poll, poll_wait_ticks) < 0) return -1;
            readiness = tcpResultReadiness(&poll);
            if (readiness.readable) {
                return self.tcpReadServiceWait(handle, out, abi.io_wait_forever);
            }
            if (readiness.terminal) return -1;
            self.sleepTicks(1);
        }
        return 0;
    }

    pub fn tcpReadWaitServiceBounded(self: *const Context, handle: u32, out: []u8, wait_ticks: u64, service_wait_ticks: u64) i32 {
        if (out.len == 0) return 0;

        var poll: abi.NetServiceTcpResult = .{};
        if (self.tcpPollServiceWait(handle, &poll, service_wait_ticks) < 0) return -1;
        var readiness = tcpResultReadiness(&poll);
        if (readiness.readable) return self.tcpReadServiceWait(handle, out, service_wait_ticks);
        if (readiness.terminal) return -1;
        if (wait_ticks == 0) return 0;

        const start = self.ticks();
        while (self.ticks() - start < wait_ticks) {
            poll = .{};
            if (self.tcpPollServiceWait(handle, &poll, service_wait_ticks) < 0) return -1;
            readiness = tcpResultReadiness(&poll);
            if (readiness.readable) {
                return self.tcpReadServiceWait(handle, out, service_wait_ticks);
            }
            if (readiness.terminal) return -1;
            self.sleepTicks(1);
        }
        return 0;
    }

    pub fn tcpReadAvailableWaitService(self: *const Context, handle: u32, out: []u8, wait_ticks: u64) i32 {
        if (out.len == 0) return 0;
        const first = self.tcpReadWaitService(handle, out, wait_ticks);
        if (first <= 0) return first;

        var total: usize = @intCast(first);
        while (total < out.len) {
            const got = self.tcpReadService(handle, out[total..]);
            if (got < 0) return @intCast(total);
            if (got == 0) break;

            const got_len: usize = @intCast(got);
            total += got_len;
            if (got_len < abi.net_service_tcp_read_max) break;
        }
        return @intCast(total);
    }

    pub fn tcpListenServiceResult(self: *const Context, port: u16, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpListenServiceResultWait(port, result, abi.io_wait_forever);
    }

    pub fn tcpListenServiceResultWait(self: *const Context, port: u16, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [2]u8 = .{0} ** 2;
        writeU16(request[0..], 0, port);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_listen_result, request[0..], result, "", wait_ticks) != 0) return -1;
        return result.result;
    }

    pub fn tcpListenService(self: *const Context, port: u16) i32 {
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpListenServiceResult(port, &structured) != 0) return -1;
        return if (structured.result == 0) 0 else -1;
    }

    pub fn tcpPollService(self: *const Context, handle: u32, out: *abi.NetServiceTcpResult) i32 {
        return self.tcpPollServiceWait(handle, out, abi.io_wait_forever);
    }

    pub fn tcpPollServiceWait(self: *const Context, handle: u32, out: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_poll_result, request[0..], out, "", wait_ticks) == 0) {
            return if (out.result == 0) 0 else -1;
        }
        return -1;
    }

    pub fn tcpReadinessFromResult(self: *const Context, result: *const abi.NetServiceTcpResult) TcpReadiness {
        _ = self;
        return tcpResultReadiness(result);
    }

    pub fn tcpReadinessReadable(self: *const Context, result: *const abi.NetServiceTcpResult) bool {
        _ = self;
        return tcpResultReadable(result);
    }

    pub fn tcpReadinessWritable(self: *const Context, result: *const abi.NetServiceTcpResult) bool {
        _ = self;
        return tcpResultWritable(result);
    }

    pub fn tcpReadinessTerminal(self: *const Context, result: *const abi.NetServiceTcpResult) bool {
        _ = self;
        return tcpResultTerminal(result);
    }

    pub fn tcpAcceptServiceResult(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.tcpAcceptWaitServiceResultWait(
            port,
            result,
            structured,
            self.ticksFromMilliseconds(tcp_accept_default_wait_ms),
            self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms),
        );
    }

    pub fn tcpAcceptPollServiceResult(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.tcpAcceptPollServiceResultWait(port, result, structured, abi.io_wait_forever);
    }

    pub fn tcpAcceptPollServiceResultWait(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        result.* = .{};
        var request: [2]u8 = .{0} ** 2;
        writeU16(request[0..], 0, port);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_accept_poll_result, request[0..], structured, "", wait_ticks) != 0) return -1;
        if ((structured.flags & abi.net_service_tcp_flag_timeout) != 0) return 0;
        if (structured.result != 0) return structured.result;
        if ((structured.flags & abi.net_service_tcp_flag_handle_valid) == 0) return -1;
        result.conn_id = structured.handle;
        result.bytes = 0;
        return 1;
    }

    pub fn tcpAcceptWaitServiceResult(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.tcpAcceptWaitServiceResultWait(port, result, structured, wait_ticks, self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms));
    }

    pub fn tcpAcceptWaitServiceResultWait(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, wait_ticks: u64, service_wait_ticks: u64) i32 {
        const start = self.ticks();
        while (true) {
            const rc = self.tcpAcceptPollServiceResultWait(port, result, structured, service_wait_ticks);
            if (rc == 1 and result.conn_id != 0) return 1;
            if (rc != 0) return rc;
            if (wait_ticks == 0) return 0;
            if (wait_ticks != abi.io_wait_forever and self.ticks() - start >= wait_ticks) return 0;
            self.sleepTicks(1);
        }
    }

    pub fn tcpAcceptService(self: *const Context, port: u16, result: *abi.TcpAcceptResult) i32 {
        var structured: abi.NetServiceTcpResult = .{};
        const rc = self.tcpAcceptServiceResult(port, result, &structured);
        if (rc == 1) return 1;
        if (rc == 0) return 0;
        return -1;
    }

    pub fn tcpCloseServiceResult(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpCloseServiceResultWait(handle, result, abi.io_wait_forever);
    }

    pub fn tcpCloseServiceResultWait(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_close_result, request[0..], result, "", wait_ticks) != 0) return -1;
        return result.result;
    }

    pub fn tcpAbortServiceResult(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpAbortServiceResultWait(handle, result, abi.io_wait_forever);
    }

    pub fn tcpAbortServiceResultWait(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_abort_result, request[0..], result, "", wait_ticks) != 0) return -1;
        return result.result;
    }

    pub fn tcpAbortService(self: *const Context, handle: u32) i32 {
        return self.tcpAbortServiceWait(handle, abi.io_wait_forever);
    }

    pub fn tcpAbortServiceWait(self: *const Context, handle: u32, wait_ticks: u64) i32 {
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpAbortServiceResultWait(handle, &structured, wait_ticks) != 0) return -1;
        return if (structured.result == 0) 0 else -1;
    }

    pub fn tcpRetransmitServiceResult(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpRetransmitServiceResultWait(handle, result, abi.io_wait_forever);
    }

    pub fn tcpRetransmitServiceResultWait(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_retransmit_result, request[0..], result, "", wait_ticks) != 0) return -1;
        return result.result;
    }

    pub fn tcpRetransmitService(self: *const Context, handle: u32) i32 {
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpRetransmitServiceResult(handle, &structured) != 0) return -1;
        return if (structured.result == 0) 0 else -1;
    }

    pub fn tcpCloseService(self: *const Context, handle: u32) i32 {
        return self.tcpCloseServiceWait(handle, abi.io_wait_forever);
    }

    pub fn tcpCloseServiceWait(self: *const Context, handle: u32, wait_ticks: u64) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_close_result, request[0..], &structured, "", wait_ticks) == 0) {
            return if (structured.result == 0) 0 else -1;
        }
        return -1;
    }

    pub fn tcpCloseListenServiceResult(self: *const Context, port: u16, result: *abi.NetServiceTcpResult) i32 {
        return self.tcpCloseListenServiceResultWait(port, result, abi.io_wait_forever);
    }

    pub fn tcpCloseListenServiceResultWait(self: *const Context, port: u16, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        var request: [2]u8 = .{0} ** 2;
        writeU16(request[0..], 0, port);
        if (self.tcpServiceResultWait(abi.net_service_op_tcp_close_listen_result, request[0..], result, "", wait_ticks) != 0) return -1;
        return result.result;
    }

    pub fn tcpCloseListenService(self: *const Context, port: u16) i32 {
        return self.tcpCloseListenServiceWait(port, abi.io_wait_forever);
    }

    pub fn tcpCloseListenServiceWait(self: *const Context, port: u16, wait_ticks: u64) i32 {
        var structured: abi.NetServiceTcpResult = .{};
        if (self.tcpCloseListenServiceResultWait(port, &structured, wait_ticks) != 0) return -1;
        return if (structured.result == 0) 0 else -1;
    }

    pub fn tcpAcceptPollReadServiceResult(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.tcpAcceptPollReadServiceResultWait(
            port,
            out,
            result,
            structured,
            self.ticksFromMilliseconds(tcp_accept_default_wait_ms),
            self.ticksFromMilliseconds(tcp_accept_read_default_wait_ms),
            self.ticksFromMilliseconds(tcp_r4x_service_timeout_ms),
        );
    }

    pub fn tcpAcceptPollReadServiceResultWait(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, accept_wait_ticks: u64, read_wait_ticks: u64, service_wait_ticks: u64) i32 {
        result.* = .{};
        structured.* = .{};
        if (out.len == 0) return 0;

        const accepted = self.tcpAcceptWaitServiceResultWait(port, result, structured, accept_wait_ticks, service_wait_ticks);
        if (accepted != 1) return accepted;
        if (result.conn_id == 0) return -1;

        const conn_id = result.conn_id;
        const got = self.tcpReadWaitServiceBounded(conn_id, out, read_wait_ticks, service_wait_ticks);
        if (got <= 0) {
            _ = self.tcpAbortServiceWait(conn_id, service_wait_ticks);
            result.* = .{};
            structured.* = .{
                .action = abi.net_service_tcp_action_accept_read,
                .result = if (got == 0) abi.tcp_result_ok else abi.tcp_result_no_connection,
                .flags = (if (got == 0) abi.net_service_tcp_flag_timeout else 0) | ((if (got == 0) abi.net_service_status_would_block else abi.net_service_status_failed) << abi.net_service_status_shift),
                .service_status = if (got == 0) abi.net_service_status_would_block else abi.net_service_status_failed,
            };
            copyFixedZ(structured.last_error[0..], if (got == 0) "accept-read-timeout" else "accept-read-failed");
            return got;
        }

        result.bytes = @intCast(got);
        structured.action = abi.net_service_tcp_action_accept_read;
        structured.result = abi.tcp_result_ok;
        structured.handle = conn_id;
        structured.bytes = @intCast(got);
        structured.flags = structured.flags & ~@as(u32, abi.net_service_status_mask);
        structured.flags = structured.flags & ~@as(u32, abi.net_service_tcp_flag_timeout);
        structured.flags |= abi.net_service_tcp_flag_ok | abi.net_service_tcp_flag_data | abi.net_service_tcp_flag_handle_valid | (abi.net_service_status_ok << abi.net_service_status_shift);
        structured.service_status = abi.net_service_status_ok;
        return got;
    }

    pub fn tcpAcceptPollReadService(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult) i32 {
        var structured: abi.NetServiceTcpResult = .{};
        return self.tcpAcceptPollReadServiceResult(port, out, result, &structured);
    }

    pub fn tcpAcceptReadServiceResult(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.tcpAcceptPollReadServiceResult(port, out, result, structured);
    }

    pub fn tcpAcceptReadService(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult) i32 {
        return self.tcpAcceptPollReadService(port, out, result);
    }

    pub fn tcpConnect(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16) i32 {
        const table_fn = self.netFn("tcp_connect") orelse return self.unavailable("net");
        return table_fn(a, b, c, d, port);
    }

    pub fn tcpWrite(self: *const Context, conn_id: u32, data: []const u8) i32 {
        const table_fn = self.netFn("tcp_write") orelse return self.unavailable("net");
        return table_fn(conn_id, data.ptr, @intCast(data.len));
    }

    pub fn tcpRead(self: *const Context, conn_id: u32, out: []u8) i32 {
        const table_fn = self.netFn("tcp_read") orelse return self.unavailable("net");
        return table_fn(conn_id, out.ptr, @intCast(out.len));
    }

    pub fn tcpClose(self: *const Context, conn_id: u32) i32 {
        const table_fn = self.netFn("tcp_close") orelse return self.unavailable("net");
        return table_fn(conn_id);
    }

    pub fn tcpSummary(self: *const Context, out: *abi.TcpSummary) i32 {
        const table_fn = self.netFn("tcp_summary") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn tcpPerformance(self: *const Context, out: *abi.TcpPerformanceInfo) i32 {
        const table_fn = self.netFn("tcp_performance") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn tcpConnection(self: *const Context, index: u32, out: *abi.TcpConnectionInfo) i32 {
        const table_fn = self.netFn("tcp_connection") orelse return self.unavailable("net");
        return table_fn(index, out);
    }

    pub fn tcpEchoListenOnce(self: *const Context, port: u16, out: []u8) i32 {
        const table_fn = self.netFn("tcp_echo_listen_once") orelse return self.unavailable("net");
        return table_fn(port, out.ptr, @intCast(out.len));
    }

    pub fn tcpAcceptReadOnce(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult) i32 {
        const table_fn = self.netFn("tcp_accept_read_once") orelse return self.unavailable("net");
        return table_fn(port, out.ptr, @intCast(out.len), result);
    }

    pub fn netIpv4Send(self: *const Context, a: u8, b: u8, c: u8, d: u8, protocol: u8, payload: []const u8) i32 {
        const table_fn = self.netFn("net_ipv4_send") orelse return self.unavailable("net");
        return table_fn(a, b, c, d, protocol, payload.ptr, @intCast(payload.len));
    }

    pub fn netIpv4Recv(self: *const Context, protocol: u8, out: *abi.NetIpv4Packet, payload: []u8) i32 {
        const table_fn = self.netFn("net_ipv4_recv") orelse return self.unavailable("net");
        return table_fn(protocol, out, payload.ptr, @intCast(payload.len));
    }

    pub fn udpBind(self: *const Context, port: u16) i32 {
        var request: [2]u8 = .{0} ** 2;
        writeU16(request[0..], 0, port);
        var structured: abi.NetServiceUdpResult = .{};
        if (self.udpServiceResult(abi.net_service_op_udp_bind_result, request[0..], &structured, "") == 0) {
            if (structured.result == 0 and (structured.flags & abi.net_service_udp_flag_handle_valid) != 0) return @intCast(structured.handle);
            return structured.result;
        }
        return -1;
    }

    pub fn udpSendTo(self: *const Context, handle: u32, dest_ip: [4]u8, dest_port: u16, payload: []const u8) i32 {
        if (payload.len > abi.net_service_udp_send_max) return abi.net_tx_too_large;
        var request: [abi.net_service_tcp_message_payload_max]u8 = .{0} ** abi.net_service_tcp_message_payload_max;
        writeU32(request[0..], 0, handle);
        request[4] = dest_ip[0];
        request[5] = dest_ip[1];
        request[6] = dest_ip[2];
        request[7] = dest_ip[3];
        writeU16(request[0..], 8, dest_port);
        if (payload.len != 0) @memcpy(request[10 .. 10 + payload.len], payload);
        var structured: abi.NetServiceUdpResult = .{};
        if (self.udpServiceResult(abi.net_service_op_udp_sendto_result, request[0 .. 10 + payload.len], &structured, "") == 0) return structured.result;
        return abi.net_tx_backend_error;
    }

    pub fn udpRecvFrom(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload: []u8) i32 {
        var structured: abi.NetServiceUdpResult = .{ .magic = 0 };
        return self.udpRecvFromServiceResult(handle, out, payload, &structured);
    }

    pub fn udpRecvFromWait(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload: []u8, timeout_ticks: u64) i32 {
        var structured: abi.NetServiceUdpResult = .{ .magic = 0 };
        const got = self.udpRecvFromServiceResult(handle, out, payload, &structured);
        if (got < 0) return got;
        if (got != 0 or timeout_ticks == 0) return got;
        return self.udpRecvFromWaitService(handle, out, payload, timeout_ticks);
    }

    pub fn udpClose(self: *const Context, handle: u32) i32 {
        var request: [4]u8 = .{0} ** 4;
        writeU32(request[0..], 0, handle);
        var structured: abi.NetServiceUdpResult = .{};
        if (self.udpServiceResult(abi.net_service_op_udp_close_result, request[0..], &structured, "") == 0) return structured.result;
        return -1;
    }

    pub fn udpStatus(self: *const Context, out: *abi.UdpStatus) i32 {
        var service_status: abi.NetServiceUdpStatus = .{};
        if (self.udpServiceStatusRaw(&service_status) != 0) return -1;
        out.* = .{
            .active_sockets = service_status.active_sockets,
            .max_sockets = service_status.max_sockets,
            .queued_packets = service_status.queued_packets,
            .queue_limit = service_status.queue_limit,
            .payload_max = service_status.payload_max,
            .delivered = service_status.delivered,
            .drops = service_status.drops,
            .last_error = service_status.last_error,
        };
        return 0;
    }

    pub fn netConfigGet(self: *const Context, out: *abi.NetConfigSnapshot) i32 {
        const table_fn = self.netFn("net_config_get") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn netConfigSet(self: *const Context, request: *const abi.NetConfigRequest) i32 {
        const table_fn = self.netFn("net_config_set") orelse return self.unavailable("net");
        return table_fn(request);
    }

    pub fn netDnsResolve(self: *const Context, name: []const u8, out: *[4]u8) i32 {
        const table_fn = self.netFn("net_dns_resolve") orelse return self.unavailable("net");
        return table_fn(name.ptr, @intCast(name.len), out);
    }

    pub fn netDnsResolveServer(self: *const Context, server: [4]u8, name: []const u8, out: *[4]u8) i32 {
        const table_fn = self.netFn("net_dns_resolve_server") orelse return self.unavailable("net");
        return table_fn(server[0], server[1], server[2], server[3], name.ptr, @intCast(name.len), out);
    }

    pub fn netDhcpAcquire(self: *const Context) i32 {
        const table_fn = self.netFn("net_dhcp_acquire") orelse return self.unavailable("net");
        return table_fn();
    }

    pub fn netDhcpRenew(self: *const Context) i32 {
        const table_fn = self.netFn("net_dhcp_renew") orelse return self.unavailable("net");
        return table_fn();
    }

    pub fn netDhcpRelease(self: *const Context) i32 {
        const table_fn = self.netFn("net_dhcp_release") orelse return self.unavailable("net");
        return table_fn();
    }

    pub fn netDhcpStatus(self: *const Context, out: *abi.DhcpStatus) i32 {
        const table_fn = self.netFn("net_dhcp_status") orelse return self.unavailable("net");
        return table_fn(out);
    }

    pub fn netDetailGet(self: *const Context, adapter_index: u32, out: *abi.NetDetailSnapshot) i32 {
        const table_fn = self.netFn("net_detail_get") orelse return self.unavailable("net");
        return table_fn(adapter_index, out);
    }

    pub fn netDiagRun(self: *const Context, op: u32, out: *abi.NetDiagResult) i32 {
        const table_fn = self.netFn("net_diag_run") orelse return self.unavailable("net");
        return table_fn(op, out);
    }

    pub fn protocolStatus(self: *const Context, role: []const u8, out: *abi.ProtocolStatus) i32 {
        if (!self.hasDevFn("protocol_dispatch") or role.len > std.math.maxInt(u32)) return -1;
        const table_fn = self.devFn("protocol_status") orelse return self.unavailable("dev");
        return table_fn(role.ptr, @intCast(role.len), out);
    }

    pub fn protocolDispatch(self: *const Context, role: []const u8, op: u32, in_buffer: *const abi.ProtocolBuffer, out_buffer: *abi.ProtocolBuffer) i32 {
        if (!self.hasDevFn("protocol_dispatch") or role.len > std.math.maxInt(u32)) return -1;
        const table_fn = self.devFn("protocol_dispatch") orelse return self.unavailable("dev");
        return table_fn(role.ptr, @intCast(role.len), op, in_buffer, out_buffer);
    }

    pub fn netDnsResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.dns_result_ok => "ok",
            abi.dns_result_short => "short",
            abi.dns_result_header => "header",
            abi.dns_result_qname => "qname",
            abi.dns_result_question => "question",
            abi.dns_result_aname => "aname",
            abi.dns_result_answer => "answer",
            abi.dns_result_atype => "atype",
            abi.dns_result_buffer_small => "buffer-small",
            abi.dns_result_name => "name",
            abi.dns_result_nxdomain => "nxdomain",
            abi.dns_result_timeout => "timeout",
            abi.dns_result_no_server => "no-server",
            abi.dns_result_tx => "tx-error",
            else => "unknown",
        };
    }

    pub fn netDhcpResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.dhcp_result_ok => "ok",
            abi.dhcp_result_ignored => "ignored",
            abi.dhcp_result_shape => "shape",
            abi.dhcp_result_no_type => "no-type",
            abi.dhcp_result_buffer_small => "buffer-small",
            else => "unknown",
        };
    }

    pub fn netUdpResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.udp_result_ok => "ok",
            abi.udp_result_not_udp => "not-udp",
            abi.udp_result_short => "short",
            abi.udp_result_length => "length",
            abi.udp_result_checksum => "checksum",
            abi.udp_result_buffer_small => "buffer-small",
            else => "unknown",
        };
    }

    pub fn netTcpResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.tcp_result_ok => "ok",
            abi.tcp_result_not_tcp => "not-tcp",
            abi.tcp_result_no_connection => "no-connection",
            abi.tcp_result_bad_state => "bad-state",
            abi.tcp_result_buffer_small => "buffer-small",
            abi.tcp_result_short => "short",
            abi.tcp_result_checksum => "checksum",
            else => "unknown",
        };
    }

    pub fn netServiceResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.net_service_result_ok => "ok",
            abi.net_service_result_bad_request => "bad-request",
            abi.net_service_result_bad_service => "bad-service",
            abi.net_service_result_bad_op => "bad-op",
            else => "unknown",
        };
    }

    pub fn netServiceStatusCode(self: *const Context, flags: u32) u32 {
        _ = self;
        return serviceStatusCodeFromFlags(flags);
    }

    pub fn netServiceStatusName(self: *const Context, flags: u32) []const u8 {
        return self.netServiceStatusCodeName(self.netServiceStatusCode(flags));
    }

    pub fn netServiceStatusCodeName(self: *const Context, code: u32) []const u8 {
        _ = self;
        return switch (code) {
            abi.net_service_status_idle => "idle",
            abi.net_service_status_pending => "pending",
            abi.net_service_status_ok => "ok",
            abi.net_service_status_timeout => "timeout",
            abi.net_service_status_failed => "failed",
            abi.net_service_status_cancelled => "cancelled",
            abi.net_service_status_would_block => "would-block",
            else => "failed",
        };
    }

    pub fn netSocketLifecycleName(self: *const Context, cause: u32) []const u8 {
        _ = self;
        return socketLifecycleName(cause);
    }

    pub fn netServiceSemanticFlags(self: *const Context, flags: u32) u32 {
        _ = self;
        return flags & ~abi.net_service_status_mask;
    }

    pub fn netConfigResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.net_config_ok => "ok",
            abi.net_config_no_adapter => "no-adapter",
            abi.net_config_invalid_ip => "invalid-ip",
            abi.net_config_write_failed => "write-failed",
            abi.net_config_live_apply_failed => "live-apply-failed",
            abi.net_config_unsupported => "unsupported",
            abi.net_config_buffer_small => "buffer-small",
            else => "unknown",
        };
    }

    pub fn netTxResultName(self: *const Context, result: i32) []const u8 {
        _ = self;
        return switch (result) {
            abi.net_tx_ok => "ok",
            abi.net_tx_no_adapter => "no-adapter",
            abi.net_tx_link_down => "link-down",
            abi.net_tx_busy => "busy",
            abi.net_tx_too_large => "too-large",
            abi.net_tx_unsupported => "unsupported",
            abi.net_tx_backend_error => "backend-error",
            else => "unknown",
        };
    }

    pub fn printU64(self: *const Context, value: u64) void {
        var buf: [20]u8 = undefined;
        var pos = buf.len;
        var n = value;
        if (n == 0) {
            self.putc('0');
            return;
        }
        while (n > 0) {
            pos -= 1;
            buf[pos] = '0' + @as(u8, @intCast(n % 10));
            n /= 10;
        }
        self.write(buf[pos..]);
    }

    pub fn printI32(self: *const Context, value: i32) void {
        if (value < 0) {
            self.putc('-');
            self.printU64(@intCast(-@as(i64, value)));
        } else {
            self.printU64(@intCast(value));
        }
    }

    pub fn printHexU32(self: *const Context, value: u32) void {
        self.write("0x");
        var shift: u5 = 28;
        while (true) {
            const nibble: u8 = @intCast((value >> shift) & 0xF);
            self.putc(if (nibble < 10) '0' + nibble else 'A' + (nibble - 10));
            if (shift == 0) break;
            shift -= 4;
        }
    }
};

fn writeNetServiceHeader(out: []u8, channel_id: u32, op: u16, request_id: u32, client_id: u16, status: i32, payload_len: u16) ?void {
    if (out.len < abi.net_service_header_size) return null;
    writeU32(out, 0, abi.net_service_magic);
    writeU16(out, 4, abi.net_service_version);
    writeU16(out, 6, @intCast(channel_id));
    writeU16(out, 8, op);
    writeU16(out, 10, 0);
    writeU32(out, 12, request_id);
    writeU16(out, 16, client_id);
    writeU16(out, 18, payload_len);
    writeI32(out, 20, status);
}

fn netServiceResponseMatches(response: []const u8, channel_id: u32, op: u16, request_id: u32) bool {
    if (response.len < abi.net_service_header_size) return false;
    if (readU32(response, 0) != abi.net_service_magic or readU16(response, 4) != abi.net_service_version) return false;
    if (readU16(response, 6) != @as(u16, @intCast(channel_id))) return false;
    if (readU16(response, 8) != op) return false;
    if (readU32(response, 12) != request_id) return false;
    const payload_len = readU16(response, 18);
    return abi.net_service_header_size + payload_len <= response.len;
}

fn writeU16(out: []u8, offset: usize, value: u16) void {
    out[offset] = @intCast(value & 0xFF);
    out[offset + 1] = @intCast(value >> 8);
}

fn writeU32(out: []u8, offset: usize, value: u32) void {
    writeU16(out, offset, @intCast(value & 0xFFFF));
    writeU16(out, offset + 2, @intCast(value >> 16));
}

fn writeI32(out: []u8, offset: usize, value: i32) void {
    writeU32(out, offset, @bitCast(value));
}

fn readU16(in_bytes: []const u8, offset: usize) u16 {
    return @as(u16, in_bytes[offset]) | (@as(u16, in_bytes[offset + 1]) << 8);
}

fn readU32(in_bytes: []const u8, offset: usize) u32 {
    return @as(u32, readU16(in_bytes, offset)) | (@as(u32, readU16(in_bytes, offset + 2)) << 16);
}

fn readI32(in_bytes: []const u8, offset: usize) i32 {
    return @bitCast(readU32(in_bytes, offset));
}

fn fillResolverFromService(out: *ResolverResult, structured: abi.NetServiceDnsResult) void {
    out.* = .{
        .result = structured.result,
        .answer = structured.answer,
        .server = structured.server,
        .flags = structured.flags,
        .service_status = serviceStatusCodeFromFlags(structured.flags),
        .cache_hit = (structured.flags & abi.net_service_dns_flag_cache_hit) != 0,
        .cache_valid = (structured.flags & abi.net_service_dns_flag_cache_valid) != 0,
        .explicit_server = (structured.flags & abi.net_service_dns_flag_explicit_server) != 0,
        .cache_answer = structured.cache_answer,
        .cache_age_seconds = structured.cache_age_seconds,
        .cache_ttl_seconds = structured.cache_ttl_seconds,
        .cache_remaining_seconds = structured.cache_remaining_seconds,
        .queries_tx = structured.queries_tx,
        .resolve_requests = structured.resolve_requests,
        .responses_rx = structured.responses_rx,
        .a_records = structured.a_records,
        .timeouts = structured.timeouts,
        .nxdomain = structured.nxdomain,
        .tx_errors = structured.tx_errors,
        .malformed = structured.malformed,
        .cache_hits = structured.cache_hits,
        .cache_stores = structured.cache_stores,
        .last_id = structured.last_id,
        .name_len = structured.name_len,
        .name = structured.name,
        .last_error = structured.last_error,
    };
}

fn serviceStatusCodeFromFlags(flags: u32) u32 {
    const raw = (flags & abi.net_service_status_mask) >> abi.net_service_status_shift;
    return if (raw <= abi.net_service_status_would_block) raw else abi.net_service_status_failed;
}

fn socketLifecycleName(cause: u32) []const u8 {
    return switch (cause) {
        abi.net_service_socket_lifecycle_active => "active",
        abi.net_service_socket_lifecycle_closed => "closed",
        abi.net_service_socket_lifecycle_reset => "reset",
        abi.net_service_socket_lifecycle_timeout => "timeout",
        abi.net_service_socket_lifecycle_peer_gone => "peer-gone",
        abi.net_service_socket_lifecycle_local_abort => "local-abort",
        abi.net_service_socket_lifecycle_local_close => "local-close",
        abi.net_service_socket_lifecycle_pending_close => "pending-close",
        abi.net_service_socket_lifecycle_would_block => "would-block",
        abi.net_service_socket_lifecycle_bad_handle => "bad-handle",
        abi.net_service_socket_lifecycle_owner_mismatch => "owner-mismatch",
        abi.net_service_socket_lifecycle_listener => "listener",
        abi.net_service_socket_lifecycle_dropped => "dropped",
        else => "unknown",
    };
}

fn netTxResultFromCode(code: i32) i32 {
    return switch (code) {
        abi.net_tx_ok,
        abi.net_tx_no_adapter,
        abi.net_tx_link_down,
        abi.net_tx_busy,
        abi.net_tx_too_large,
        abi.net_tx_unsupported,
        abi.net_tx_backend_error,
        => code,
        else => abi.net_tx_backend_error,
    };
}

fn dhcpStatusFlagsFromService(flags: u32) u32 {
    var out: u32 = 0;
    if ((flags & abi.net_service_dhcp_flag_bound) != 0) out |= abi.dhcp_status_flag_bound;
    if ((flags & abi.net_service_dhcp_flag_dns_configured) != 0) out |= abi.dhcp_status_flag_dns_configured;
    if ((flags & abi.net_service_dhcp_flag_pending) != 0) out |= abi.dhcp_status_flag_pending;
    if ((flags & abi.net_service_dhcp_flag_desired) != 0) out |= abi.dhcp_status_flag_desired;
    if ((flags & abi.net_service_dhcp_flag_task_started) != 0) out |= abi.dhcp_status_flag_task_started;
    if ((flags & abi.net_service_dhcp_flag_link_up) != 0) out |= abi.dhcp_status_flag_link_up;
    if ((flags & abi.net_service_dhcp_flag_retry_wait) != 0) out |= abi.dhcp_status_flag_retry_wait;
    return out;
}

fn copyFixedZ(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const count = @min(value.len, out.len - 1);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
}

fn serviceUnavailableFlags() u32 {
    return abi.net_service_status_failed << abi.net_service_status_shift;
}

fn markDnsServiceUnavailableStatus(out: *abi.NetServiceDnsStatus) void {
    out.* = .{
        .flags = serviceUnavailableFlags(),
        .last_result = abi.dns_result_tx,
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn markDnsServiceUnavailableResult(out: *abi.NetServiceDnsResult, op: u16) void {
    out.* = .{
        .action = dnsServiceActionFromOp(op),
        .result = abi.dns_result_tx,
        .flags = serviceUnavailableFlags(),
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn markDhcpServiceUnavailableStatus(out: *abi.NetServiceDhcpStatus) void {
    out.* = .{
        .flags = serviceUnavailableFlags(),
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn markDhcpServiceUnavailableResult(out: *abi.NetServiceDhcpResult, op: u16) void {
    out.* = .{
        .action = dhcpServiceActionFromOp(op),
        .result = abi.net_tx_backend_error,
        .flags = serviceUnavailableFlags(),
    };
}

fn markTcpServiceUnavailableStatus(out: *abi.NetServiceTcpStatus) void {
    out.* = .{
        .flags = serviceUnavailableFlags(),
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn markTcpServiceUnavailableResult(out: *abi.NetServiceTcpResult, op: u16) void {
    out.* = .{
        .action = tcpServiceActionFromOp(op),
        .result = -1,
        .flags = serviceUnavailableFlags(),
        .service_status = abi.net_service_status_failed,
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn markUdpServiceUnavailableStatus(out: *abi.NetServiceUdpStatus) void {
    out.* = .{
        .flags = serviceUnavailableFlags(),
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn markUdpServiceUnavailableResult(out: *abi.NetServiceUdpResult, op: u16) void {
    out.* = .{
        .action = udpServiceActionFromOp(op),
        .result = -1,
        .flags = serviceUnavailableFlags(),
        .service_status = abi.net_service_status_failed,
    };
    copyFixedZ(out.last_error[0..], net_r4x_service_unavailable_error);
}

fn netSocketServiceName(service: NetSocketService) [*:0]const u8 {
    return switch (service) {
        .tcp => tcp_r4x_service_name,
        .udp => udp_r4x_service_name,
    };
}

fn updateNetSocketResponseLen(request: *NetSocketRequest) void {
    if (request.info.state == abi.io_state_completed and request.info.result > 0) {
        const len: usize = @intCast(request.info.result);
        request.response_len = @intCast(@min(len, request.response.len));
    }
}

fn copyNetSocketStruct(comptime T: type, out: *T, response: []const u8) bool {
    if (response.len < @sizeOf(T)) return false;
    const out_bytes: [*]u8 = @ptrCast(out);
    @memcpy(out_bytes[0..@sizeOf(T)], response[0..@sizeOf(T)]);
    return true;
}

fn dnsServiceActionFromOp(op: u16) u16 {
    return switch (op) {
        abi.net_service_op_dns_resolve_a_server, abi.net_service_op_dns_resolve_a_server_result => abi.net_service_dns_action_resolve_a_server,
        else => abi.net_service_dns_action_resolve_a,
    };
}

fn dhcpServiceActionFromOp(op: u16) u16 {
    return switch (op) {
        abi.net_service_op_dhcp_renew, abi.net_service_op_dhcp_renew_result => abi.net_service_dhcp_action_renew,
        abi.net_service_op_dhcp_release, abi.net_service_op_dhcp_release_result => abi.net_service_dhcp_action_release,
        else => abi.net_service_dhcp_action_acquire,
    };
}

fn tcpServiceActionFromOp(op: u16) u16 {
    return switch (op) {
        abi.net_service_op_tcp_write, abi.net_service_op_tcp_write_result => abi.net_service_tcp_action_write,
        abi.net_service_op_tcp_read, abi.net_service_op_tcp_read_result => abi.net_service_tcp_action_read,
        abi.net_service_op_tcp_close, abi.net_service_op_tcp_close_result => abi.net_service_tcp_action_close,
        abi.net_service_op_tcp_listen, abi.net_service_op_tcp_listen_result => abi.net_service_tcp_action_listen,
        abi.net_service_op_tcp_accept_read, abi.net_service_op_tcp_accept_read_result => abi.net_service_tcp_action_accept_read,
        abi.net_service_op_tcp_close_listen, abi.net_service_op_tcp_close_listen_result => abi.net_service_tcp_action_close_listen,
        abi.net_service_op_tcp_poll, abi.net_service_op_tcp_poll_result => abi.net_service_tcp_action_poll,
        abi.net_service_op_tcp_accept, abi.net_service_op_tcp_accept_result => abi.net_service_tcp_action_accept,
        abi.net_service_op_tcp_abort_result => abi.net_service_tcp_action_abort,
        abi.net_service_op_tcp_accept_poll_result => abi.net_service_tcp_action_accept_poll,
        abi.net_service_op_tcp_retransmit_result => abi.net_service_tcp_action_retransmit,
        else => abi.net_service_tcp_action_connect,
    };
}

fn udpServiceActionFromOp(op: u16) u16 {
    return switch (op) {
        abi.net_service_op_udp_sendto, abi.net_service_op_udp_sendto_result => abi.net_service_udp_action_sendto,
        abi.net_service_op_udp_recv, abi.net_service_op_udp_recv_result => abi.net_service_udp_action_recv,
        abi.net_service_op_udp_close, abi.net_service_op_udp_close_result => abi.net_service_udp_action_close,
        else => abi.net_service_udp_action_bind,
    };
}

fn parseConsoleHostKind(value: u32) abi.ConsoleHostKind {
    return switch (value) {
        @intFromEnum(abi.ConsoleHostKind.terminal_window) => .terminal_window,
        @intFromEnum(abi.ConsoleHostKind.terminal_mode) => .terminal_mode,
        else => .none,
    };
}

fn fallbackTextMetrics(value: [*:0]const u8) abi.GuiTextMetrics {
    var line_w: u32 = 0;
    var max_w: u32 = 0;
    var lines: u32 = 1;
    var visible: u32 = 0;
    var i: usize = 0;
    while (i < 4096 and value[i] != 0) {
        const ch = value[i];
        const consumed = fallbackUtf8SequenceLength(value, i, 4096);
        i += consumed;
        if (ch == '\r') continue;
        if (ch == '\n') {
            if (line_w > max_w) max_w = line_w;
            line_w = 0;
            lines += 1;
            visible += @intCast(consumed);
            continue;
        }
        line_w += 8;
        visible += @intCast(consumed);
    }
    if (line_w > max_w) max_w = line_w;
    return .{
        .width = max_w,
        .height = lines * 8,
        .line_height = 8,
        .baseline = 7,
        .visible_bytes = visible,
    };
}

fn fallbackUtf8SequenceLength(value: [*:0]const u8, start: usize, limit: usize) usize {
    const first = value[start];
    if (first < 0x80) return 1;
    const expected: usize = if (first >= 0xC2 and first <= 0xDF)
        2
    else if (first >= 0xE0 and first <= 0xEF)
        3
    else if (first >= 0xF0 and first <= 0xF4)
        4
    else
        return 1;
    if (expected > limit -| start) return 1;
    var offset: usize = 1;
    while (offset < expected) : (offset += 1) {
        if (value[start + offset] == 0 or (value[start + offset] & 0xC0) != 0x80) return 1;
    }
    if (first == 0xE0 and value[start + 1] < 0xA0) return 1;
    if (first == 0xED and value[start + 1] >= 0xA0) return 1;
    if (first == 0xF0 and value[start + 1] < 0x90) return 1;
    if (first == 0xF4 and value[start + 1] >= 0x90) return 1;
    return expected;
}

var test_table_write_calls: u32 = 0;
var test_table_write_length: u32 = 0;

fn testTableWrite(_: [*]const u8, len: u32) callconv(.c) i32 {
    test_table_write_calls += 1;
    test_table_write_length = len;
    return @intCast(len);
}

var test_net_socket_close_calls: u32 = 0;
var test_net_socket_wait_calls: u32 = 0;
var test_net_socket_service_close_calls: u32 = 0;
var test_net_socket_drain_valid: bool = true;

fn testNetSocketIoClose(request_id: u32) callconv(.c) i32 {
    if (request_id != 77) test_net_socket_drain_valid = false;
    test_net_socket_close_calls += 1;
    return if (test_net_socket_close_calls == 1) abi.io_error_busy else abi.io_ok;
}

fn testNetSocketIoWait(request_id: u32, timeout_ticks: u64, out: *abi.ProgramIoInfo) callconv(.c) i32 {
    if (request_id != 77 or timeout_ticks != abi.io_wait_forever) test_net_socket_drain_valid = false;
    test_net_socket_wait_calls += 1;
    out.* = .{
        .request_id = request_id,
        .state = abi.io_state_completed,
    };
    return abi.io_ok;
}

fn testNetSocketServiceClose(handle: u32) callconv(.c) i32 {
    if (handle != 33) test_net_socket_drain_valid = false;
    test_net_socket_service_close_calls += 1;
    return abi.service_api_result_ok;
}

test "net socket drain keeps stack request alive until busy async close completes" {
    test_net_socket_close_calls = 0;
    test_net_socket_wait_calls = 0;
    test_net_socket_service_close_calls = 0;
    test_net_socket_drain_valid = true;

    var raw: abi.R4XStartContext = .{};
    var table: abi.R4XStartR4Sys = .{};
    table.size = @intCast(@sizeOf(abi.R4XStartR4Sys));
    table.io_wait = @intFromPtr(&testNetSocketIoWait);
    table.io_close = @intFromPtr(&testNetSocketIoClose);
    table.service_close = @intFromPtr(&testNetSocketServiceClose);
    var bundle: Bundle = .{ .raw = &raw, .sys = &table };
    const ctx = Context.initBundle(&bundle);

    const before_canary: u64 = 0x1122_3344_5566_7788;
    const after_canary: u64 = 0x8877_6655_4433_2211;
    var guarded = struct {
        before: u64,
        request: NetSocketRequest,
        after: u64,
    }{
        .before = before_canary,
        .request = .{
            .active = true,
            .request_id = 77,
            .service_handle = 33,
        },
        .after = after_canary,
    };

    ctx.netSocketDrainAndClose(&guarded.request);

    try std.testing.expect(test_net_socket_drain_valid);
    try std.testing.expectEqual(@as(u32, 2), test_net_socket_close_calls);
    try std.testing.expectEqual(@as(u32, 1), test_net_socket_wait_calls);
    try std.testing.expectEqual(@as(u32, 1), test_net_socket_service_close_calls);
    try std.testing.expectEqual(before_canary, guarded.before);
    try std.testing.expectEqual(after_canary, guarded.after);
    try std.testing.expect(!guarded.request.active);
    try std.testing.expectEqual(@as(u32, 0), guarded.request.request_id);
    try std.testing.expectEqual(@as(u32, 0), guarded.request.service_handle);
}

test "program context accepts present fields in a shorter append-only table" {
    var raw: abi.R4XStartContext = .{};
    var table: abi.R4XStartR4Sys = .{};
    table.size = @intCast(@offsetOf(abi.R4XStartR4Sys, "write") + @sizeOf(usize));
    table.write = @intFromPtr(&testTableWrite);
    table.putc = @intFromPtr(&testTableWrite);
    var bundle: Bundle = .{ .raw = &raw, .sys = &table };
    const ctx = Context.initBundle(&bundle);

    try std.testing.expect(ctx.hasSysFn("write"));
    try std.testing.expect(!ctx.hasSysFn("putc"));
    try std.testing.expectEqual(Context.TableFieldState.available, Context.tableFieldState(abi.R4XStartR4Sys, bundle.sys, "write"));
    try std.testing.expectEqual(Context.TableFieldState.beyond_size, Context.tableFieldState(abi.R4XStartR4Sys, bundle.sys, "putc"));
    test_table_write_calls = 0;
    test_table_write_length = 0;
    ctx.write("one-batched-write");
    try std.testing.expectEqual(@as(u32, 1), test_table_write_calls);
    try std.testing.expectEqual(@as(u32, 17), test_table_write_length);
}

test "program context distinguishes missing group null pointer and tombstone" {
    var raw: abi.R4XStartContext = .{};
    var missing_bundle: Bundle = .{ .raw = &raw };
    const missing = Context.initBundle(&missing_bundle);
    try std.testing.expectEqual(abi.err_no_group, missing.guiClear(0));
    try std.testing.expectEqual(Context.TableFieldState.no_group, Context.tableFieldState(abi.R4XStartR4Draw, null, "gui_clear"));

    var draw: abi.R4XStartR4Draw = .{};
    var null_bundle: Bundle = .{ .raw = &raw, .draw = &draw };
    const null_field = Context.initBundle(&null_bundle);
    try std.testing.expectEqual(abi.err_no_fn, null_field.guiClear(0));
    try std.testing.expectEqual(Context.TableFieldState.null_pointer, Context.tableFieldState(abi.R4XStartR4Draw, null_bundle.draw, "gui_clear"));

    var sys: abi.R4XStartR4Sys = .{};
    sys.reserved_shell_run = 1;
    try std.testing.expectEqual(Context.TableFieldState.tombstone, Context.tableFieldState(abi.R4XStartR4Sys, &sys, "reserved_shell_run"));
}

var test_net_service_direct_calls: u32 = 0;
var test_net_service_raw_send_calls: u32 = 0;
var test_net_service_raw_recv_calls: u32 = 0;
var test_net_service_request_id: u32 = 0;
var test_net_service_op: u16 = 0;

fn testNetServiceDirect(
    channel_id: u32,
    op: u16,
    request_id: u32,
    client_id: u16,
    payload: [*]const u8,
    payload_len: u32,
    out: [*]u8,
    out_capacity: u32,
) callconv(.c) i32 {
    test_net_service_direct_calls += 1;
    if (channel_id != abi.ipc_channel_net_dns or op != abi.net_service_op_dns_status_result or request_id != 91 or client_id == 0) return -1;
    if (payload_len != 3 or !std.mem.eql(u8, payload[0..3], "abc") or out_capacity < 3) return -1;
    @memcpy(out[0..3], "new");
    return 3;
}

fn testNetServiceRawSend(channel_id: u32, data: [*]const u8, len: u32) callconv(.c) i32 {
    test_net_service_raw_send_calls += 1;
    if (channel_id != abi.ipc_channel_net_dns or len < abi.net_service_header_size) return -1;
    const request = data[0..len];
    test_net_service_op = readU16(request, 8);
    test_net_service_request_id = readU32(request, 12);
    return @intCast(len);
}

fn testNetServiceRawRecv(channel_id: u32, out: [*]u8, max_len: u32) callconv(.c) i32 {
    test_net_service_raw_recv_calls += 1;
    if (channel_id != abi.ipc_channel_net_dns or max_len < abi.net_service_header_size + 3) return -1;
    const response = out[0..max_len];
    writeNetServiceHeader(
        response,
        channel_id,
        test_net_service_op,
        test_net_service_request_id,
        1,
        abi.net_service_result_ok,
        3,
    ) orelse return -1;
    @memcpy(response[abi.net_service_header_size .. abi.net_service_header_size + 3], "old");
    return @intCast(abi.net_service_header_size + 3);
}

test "network service request prefers the generation-bound tail function" {
    test_net_service_direct_calls = 0;
    test_net_service_raw_send_calls = 0;
    test_net_service_raw_recv_calls = 0;

    var raw: abi.R4XStartContext = .{};
    var table: abi.R4XStartR4Net = .{};
    table.size = @intCast(@sizeOf(abi.R4XStartR4Net));
    table.net_service_request = @intFromPtr(&testNetServiceDirect);
    table.ipc_send = @intFromPtr(&testNetServiceRawSend);
    table.ipc_recv = @intFromPtr(&testNetServiceRawRecv);
    var bundle: Bundle = .{ .raw = &raw, .net = &table };
    const ctx = Context.initBundle(&bundle);
    var out: [abi.net_service_header_size + 16]u8 = undefined;

    const got = ctx.netServiceRequest(abi.ipc_channel_net_dns, abi.net_service_op_dns_status_result, 91, "abc", out[0..]);
    try std.testing.expectEqual(@as(i32, 3), got);
    try std.testing.expectEqualStrings("new", out[0..3]);
    try std.testing.expectEqual(@as(u32, 1), test_net_service_direct_calls);
    try std.testing.expectEqual(@as(u32, 0), test_net_service_raw_send_calls);
    try std.testing.expectEqual(@as(u32, 0), test_net_service_raw_recv_calls);
}

test "network service request retains raw IPC fallback for an older table" {
    test_net_service_direct_calls = 0;
    test_net_service_raw_send_calls = 0;
    test_net_service_raw_recv_calls = 0;
    test_net_service_request_id = 0;
    test_net_service_op = 0;

    var raw: abi.R4XStartContext = .{};
    var table: abi.R4XStartR4Net = .{};
    table.size = @intCast(@offsetOf(abi.R4XStartR4Net, "net_service_request"));
    table.ipc_send = @intFromPtr(&testNetServiceRawSend);
    table.ipc_recv = @intFromPtr(&testNetServiceRawRecv);
    var bundle: Bundle = .{ .raw = &raw, .net = &table };
    const ctx = Context.initBundle(&bundle);
    var out: [abi.net_service_header_size + 3]u8 = undefined;

    const got = ctx.netServiceRequest(abi.ipc_channel_net_dns, abi.net_service_op_dns_status_result, 92, "xyz", out[0..]);
    try std.testing.expectEqual(@as(i32, abi.net_service_header_size + 3), got);
    try std.testing.expectEqualStrings("old", out[abi.net_service_header_size..]);
    try std.testing.expectEqual(@as(u32, 0), test_net_service_direct_calls);
    try std.testing.expectEqual(@as(u32, 1), test_net_service_raw_send_calls);
    try std.testing.expectEqual(@as(u32, 1), test_net_service_raw_recv_calls);
}
