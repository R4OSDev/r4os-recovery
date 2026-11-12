const r4os = @import("r4os");

const Action = enum {
    show,
    show_all,
    renew,
    release,
};

const service_channel_dhcp: u32 = 2;
const service_channel_dns: u32 = 3;
const service_channel_tcp: u32 = 4;
const service_channel_udp: u32 = 5;

const App = struct {
    sys: r4os.r4sys.Context,
    net: r4os.r4net.Context,

    fn init(r4_app: *r4os.App2) ?App {
        return .{
            .sys = r4_app.system(),
            .net = r4_app.networkLowLevel() orelse return null,
        };
    }

    fn argsRaw(self: *const App) [*:0]const u8 {
        return self.sys.argsRaw();
    }

    fn write(self: *const App, value: []const u8) void {
        self.sys.write(value);
    }

    fn putc(self: *const App, ch: u8) void {
        self.sys.putc(ch);
    }

    fn printU64(self: *const App, value: u64) void {
        self.sys.printU64(value);
    }

    fn ipcChannel(self: *const App, channel_id: u32, out: *r4os.abi.IpcChannelInfo) i32 {
        return self.net.ipcChannel(channel_id, out);
    }

    fn netConfigGet(self: *const App, out: *r4os.abi.NetConfigSnapshot) i32 {
        return self.net.netConfigGet(out);
    }

    fn netDhcpRenew(self: *const App) i32 {
        return self.net.netDhcpRenewService();
    }

    fn netDhcpRelease(self: *const App) i32 {
        return self.net.netDhcpReleaseService();
    }

    fn netDhcpStatus(self: *const App, out: *r4os.abi.DhcpStatus) i32 {
        return self.net.netDhcpServiceStatus(out);
    }

    fn netDetailGet(self: *const App, adapter_index: u32, out: *r4os.abi.NetDetailSnapshot) i32 {
        return self.net.netDetailGet(adapter_index, out);
    }

    fn netConfigResultName(self: *const App, result: i32) []const u8 {
        return self.net.netConfigResultName(result);
    }

    fn netTxResultName(self: *const App, result: i32) []const u8 {
        return self.net.netTxResultName(result);
    }
};

pub fn r4_app_main(r4_app: *r4os.App2) i32 {
    const ctx = App.init(r4_app) orelse return r4os.abi.err_no_group;
    const args = trim(zSlice(ctx.argsRaw()));
    const action = parseAction(args) orelse {
        usage(&ctx);
        return 1;
    };

    var action_result: i32 = r4os.abi.net_tx_ok;
    switch (action) {
        .show, .show_all => {},
        .renew => {
            action_result = ctx.netDhcpRenew();
            ctx.write("IPCONFIG renew: ");
            ctx.write(ctx.netTxResultName(action_result));
            ctx.write("\r\n\r\n");
        },
        .release => {
            action_result = ctx.netDhcpRelease();
            ctx.write("IPCONFIG release: ");
            ctx.write(ctx.netTxResultName(action_result));
            ctx.write("\r\n\r\n");
        },
    }

    var snapshot: r4os.abi.NetConfigSnapshot = .{};
    const result = ctx.netConfigGet(&snapshot);
    if (result != r4os.abi.net_config_ok) {
        ctx.write("IPCONFIG: net config read failed: ");
        ctx.write(ctx.netConfigResultName(result));
        ctx.write("\r\n");
        return 1;
    }

    ctx.write("R4OS IP Configuration\r\n\r\n");
    ctx.write("Adapter . . . . . . . . . . : ");
    if ((snapshot.flags & r4os.abi.net_config_flag_adapter_present) != 0) {
        writeZ(&ctx, snapshot.adapter_name[0..]);
    } else {
        ctx.write("none");
    }
    ctx.write("\r\n");

    ctx.write("Link . . . . . . . . . . . : ");
    if ((snapshot.flags & r4os.abi.net_config_flag_link_up) != 0) {
        ctx.write("up");
    } else {
        writeZOr(&ctx, snapshot.link[0..], "down");
    }
    ctx.write("\r\n");

    ctx.write("MAC Address . . . . . . . : ");
    if ((snapshot.flags & r4os.abi.net_config_flag_adapter_present) != 0) {
        writeMac(&ctx, snapshot.mac);
    } else {
        ctx.write("--");
    }
    ctx.write("\r\n");

    ctx.write("MTU . . . . . . . . . . . . : ");
    ctx.printU64(snapshot.mtu);
    ctx.write("\r\n");

    ctx.write("IPv4 Address . . . . . . . : ");
    writeIpv4(&ctx, snapshot.local_ip);
    ctx.write("\r\n");
    ctx.write("Subnet Mask . . . . . . . : ");
    writeIpv4(&ctx, snapshot.netmask);
    ctx.write("\r\n");
    ctx.write("Default Gateway . . . . . : ");
    writeIpv4(&ctx, snapshot.gateway_ip);
    ctx.write("\r\n");
    ctx.write("DNS Server . . . . . . . . : ");
    if ((snapshot.flags & r4os.abi.net_config_flag_dns_configured) != 0) {
        writeIpv4(&ctx, snapshot.dns_ip);
    } else {
        ctx.write("not configured");
    }
    ctx.write("\r\n");

    ctx.write("Source . . . . . . . . . . : ");
    writeZOr(&ctx, snapshot.source[0..], "unknown");
    ctx.write("\r\n");
    ctx.write("Last Error . . . . . . . . : ");
    writeZOr(&ctx, snapshot.last_error[0..], "none");
    ctx.write("\r\n");
    ctx.write("Adapters . . . . . . . . . : ");
    ctx.printU64(snapshot.adapter_count);
    ctx.write("\r\n");
    ctx.write("Invalid Options . . . . . : ");
    ctx.printU64(snapshot.invalid_options);
    ctx.write("\r\n");

    if (action == .show_all or action == .renew or action == .release) {
        var dhcp_status: r4os.abi.DhcpStatus = .{};
        if (ctx.netDhcpStatus(&dhcp_status) > 0) {
            ctx.write("\r\nDHCP Lease\r\n");
            printDhcpStatus(&ctx, dhcp_status);
        } else {
            ctx.write("\r\nDHCP Lease\r\n");
            ctx.write("Status . . . . . . . . . : unavailable\r\n");
        }
    }

    if (action == .show_all) {
        var detail: r4os.abi.NetDetailSnapshot = .{};
        ctx.write("\r\nNetwork Detail\r\n");
        if (ctx.netDetailGet(0, &detail) > 0) {
            printNetworkDetail(&ctx, detail);
        } else {
            ctx.write("Status . . . . . . . . . : unavailable\r\n");
        }
    }

    if ((snapshot.flags & r4os.abi.net_config_flag_adapter_present) == 0) return 1;
    return if (action_result == r4os.abi.net_tx_ok) 0 else 1;
}

fn parseAction(args: []const u8) ?Action {
    if (args.len == 0) return .show;
    if (equalsIgnoreCase(args, "/ALL") or equalsIgnoreCase(args, "-ALL")) return .show_all;
    if (equalsIgnoreCase(args, "/RENEW") or equalsIgnoreCase(args, "-RENEW")) return .renew;
    if (equalsIgnoreCase(args, "/RELEASE") or equalsIgnoreCase(args, "-RELEASE")) return .release;
    return null;
}

fn usage(ctx: *const App) void {
    ctx.write("Usage: IPCONFIG [/ALL|/RENEW|/RELEASE]\r\n");
}

fn printDhcpStatus(ctx: *const App, status: r4os.abi.DhcpStatus) void {
    ctx.write("State . . . . . . . . . . : ");
    if ((status.flags & r4os.abi.dhcp_status_flag_bound) != 0) {
        ctx.write("bound");
    } else if (equalsIgnoreCase(spanZ(status.last_error[0..]), "released") or equalsIgnoreCase(spanZ(status.last_error[0..]), "no-lease")) {
        ctx.write("released");
    } else {
        ctx.write("unbound");
    }
    ctx.write("\r\n");

    ctx.write("Client IP . . . . . . . . : ");
    writeIpv4(ctx, status.offered_ip);
    ctx.write("\r\n");
    ctx.write("Server IP . . . . . . . . : ");
    writeIpv4(ctx, status.server_ip);
    ctx.write("\r\n");
    ctx.write("Gateway . . . . . . . . . : ");
    writeIpv4(ctx, status.gateway_ip);
    ctx.write("\r\n");
    ctx.write("DNS Server . . . . . . . . : ");
    if ((status.flags & r4os.abi.dhcp_status_flag_dns_configured) != 0) {
        writeIpv4(ctx, status.dns_ip);
    } else {
        ctx.write("not configured");
    }
    ctx.write("\r\n");

    ctx.write("Lease/Renew/Rebind . . . : ");
    ctx.printU64(status.lease_seconds);
    ctx.write("/");
    ctx.printU64(status.renew_seconds);
    ctx.write("/");
    ctx.printU64(status.rebind_seconds);
    ctx.write(" seconds\r\n");

    ctx.write("Discover/Offer . . . . . : ");
    ctx.printU64(status.discover_tx);
    ctx.write("/");
    ctx.printU64(status.offer_rx);
    ctx.write("\r\n");
    ctx.write("Request/Ack/Nak . . . . . : ");
    ctx.printU64(status.request_tx);
    ctx.write("/");
    ctx.printU64(status.ack_rx);
    ctx.write("/");
    ctx.printU64(status.nak_rx);
    ctx.write("\r\n");
    ctx.write("Release . . . . . . . . . : ");
    ctx.printU64(status.release_tx);
    ctx.write("\r\n");
    ctx.write("Retries/Timeouts . . . . : ");
    ctx.printU64(status.retries);
    ctx.write("/");
    ctx.printU64(status.timeouts);
    ctx.write("\r\n");
    ctx.write("Last Error . . . . . . . : ");
    writeZOr(ctx, status.last_error[0..], "none");
    ctx.write("\r\n");
}

fn printNetworkDetail(ctx: *const App, detail: r4os.abi.NetDetailSnapshot) void {
    ctx.write("Adapter State . . . . . . : ");
    writeZOr(ctx, detail.adapter.state[0..], "unknown");
    ctx.write("\r\n");

    ctx.write("Backend IRQ/Poll . . . . . : irq=");
    if (detail.adapter.irq_line == 0xFF) ctx.write("-") else ctx.printU64(detail.adapter.irq_line);
    ctx.write(" registered=");
    ctx.write(if ((detail.flags & r4os.abi.net_detail_flag_irq_registered) != 0) "yes" else "no");
    ctx.write(" hits=");
    ctx.printU64(detail.adapter.irq_count);
    ctx.write(" poll=");
    ctx.printU64(detail.adapter.poll_count);
    ctx.write(" fallback=");
    ctx.printU64(detail.adapter.poll_fallbacks);
    ctx.write(" isr=0x");
    writeHexU16(ctx, detail.adapter.last_isr);
    ctx.write("\r\n");

    ctx.write("Core Traffic . . . . . . . : accepted-rx=");
    ctx.printU64(detail.adapter.rx_packets);
    ctx.write("/");
    ctx.printU64(detail.adapter.rx_bytes);
    ctx.write(" submitted-tx=");
    ctx.printU64(detail.adapter.tx_packets);
    ctx.write("/");
    ctx.printU64(detail.adapter.tx_bytes);
    ctx.write(" drop=");
    ctx.printU64(detail.adapter.drops);
    ctx.write(" err=");
    ctx.printU64(detail.adapter.errors);
    ctx.write("\r\n");

    ctx.write("Backend DMA . . . . . . . . : completed-rx=");
    ctx.printU64(detail.adapter.backend_rx_packets);
    ctx.write(" completed-tx=");
    ctx.printU64(detail.adapter.backend_tx_packets);
    ctx.write(" drop=");
    ctx.printU64(detail.adapter.backend_drops);
    ctx.write(" err=");
    ctx.printU64(detail.adapter.backend_errors);
    ctx.write("\r\n");

    ctx.write("Errors Detail . . . . . . . : total=");
    ctx.printU64(networkErrorTotal(ctx, detail));
    ctx.write(" packet=");
    ctx.printU64(networkPacketErrors(detail));
    ctx.write(" proto=");
    ctx.printU64(networkProtocolErrors(detail));
    ctx.write(" last=");
    writeZOr(ctx, detail.adapter.last_error[0..], "none");
    ctx.write("/");
    writeZOr(ctx, detail.tcp_last_error[0..], "none");
    ctx.write("\r\n");

    ctx.write("ARP Cache . . . . . . . . : ");
    if ((detail.flags & r4os.abi.net_detail_flag_arp_cache_valid) != 0) {
        writeIpv4(ctx, detail.arp.cache_ip);
        ctx.write("=");
        writeMac(ctx, detail.arp.cache_mac);
        ctx.write(" age=");
        ctx.printU64(detail.arp.cache_age_ticks);
        ctx.write("/");
        ctx.printU64(detail.arp.cache_ttl_ticks);
    } else {
        ctx.write("empty");
    }
    ctx.write("\r\n");

    ctx.write("ARP Resolve . . . . . . . : hit=");
    ctx.printU64(detail.arp.cache_hits);
    ctx.write(" attempts=");
    ctx.printU64(detail.arp.resolve_attempts);
    ctx.write(" retry=");
    ctx.printU64(detail.arp.resolve_retries);
    ctx.write(" timeout=");
    ctx.printU64(detail.arp.resolve_timeouts);
    ctx.write(" pending=");
    ctx.printU64(detail.arp.pending_packets);
    ctx.write(" drop=");
    ctx.printU64(detail.arp.pending_drops);
    ctx.write("\r\n");

    ctx.write("UDP . . . . . . . . . . . : rx=");
    ctx.printU64(detail.udp.rx_packets);
    ctx.write(" tx=");
    ctx.printU64(detail.udp.tx_packets);
    ctx.write(" dhcp=");
    ctx.printU64(detail.udp.dhcp_rx);
    ctx.write(" dns=");
    ctx.printU64(detail.udp.dns_rx);
    ctx.write(" malformed=");
    ctx.printU64(detail.udp.malformed);
    ctx.write(" checksum=");
    ctx.printU64(detail.udp.checksum_errors);
    ctx.write("\r\n");

    ctx.write("DNS Detail . . . . . . . . : q=");
    ctx.printU64(detail.dns.queries_tx);
    ctx.write(" resp=");
    ctx.printU64(detail.dns.responses_rx);
    ctx.write(" answer=");
    writeIpv4(ctx, detail.dns.last_answer);
    ctx.write(" last=");
    writeZOr(ctx, detail.dns.last_error[0..], "none");
    ctx.write("\r\n");

    ctx.write("TCP Detail . . . . . . . . : active=");
    ctx.printU64(detail.tcp.active_connections);
    ctx.write("/");
    ctx.printU64(detail.tcp.max_connections);
    ctx.write(" listen=");
    ctx.printU64(detail.tcp.active_listeners);
    ctx.write(" tx=");
    ctx.printU64(detail.tcp.data_tx);
    ctx.write(" rx=");
    ctx.printU64(detail.tcp.data_rx);
    ctx.write(" retrans=");
    ctx.printU64(detail.tcp.retransmits);
    ctx.write(" drop=");
    ctx.printU64(detail.tcp.rx_drops);
    ctx.write("\r\n");

    ctx.write("TCP Connections . . . . . : ");
    ctx.printU64(detail.tcp_connection_count);
    ctx.write("/");
    ctx.printU64(r4os.abi.net_detail_max_tcp_connections);
    ctx.write("\r\n");

    ctx.write("Protocol Runtime . . . . . : eth=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_ethernet]);
    ctx.write(" arp=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_arp]);
    ctx.write(" ip=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_ipv4]);
    ctx.write(" icmp=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_icmp]);
    ctx.write(" udp=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_udp]);
    ctx.write(" dhcp=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_dhcp]);
    ctx.write(" dns=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_dns]);
    ctx.write(" tcp=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_tcp]);
    ctx.write(" r4sl=");
    writeRuntimeSource(ctx, detail.protocols[r4os.abi.net_detail_protocol_serial_link]);
    ctx.write(" fail=");
    ctx.printU64(protocolFailures(detail));
    ctx.write(" req=");
    ctx.printU64(r4pRequiredCount(detail));
    ctx.write("\r\n");

    printIpcService(ctx, service_channel_dhcp);
    printIpcService(ctx, service_channel_dns);
    printIpcService(ctx, service_channel_tcp);
    printIpcService(ctx, service_channel_udp);
}

fn printIpcService(ctx: *const App, channel_id: u32) void {
    var info: r4os.abi.IpcChannelInfo = .{};
    if (ctx.ipcChannel(channel_id, &info) <= 0) return;
    ctx.write("IPC Service ");
    writeZOr(ctx, info.name[0..], shortServiceName(channel_id));
    ctx.write(" . . . . : channel=");
    ctx.printU64(channel_id);
    ctx.write(" active=");
    ctx.write(if (info.active != 0) "yes" else "no");
    ctx.write(" queued=");
    ctx.printU64(info.queued);
    ctx.write("/");
    ctx.printU64(info.queue_depth);
    ctx.write(" tx=");
    ctx.printU64(info.sends);
    ctx.write(" rx=");
    ctx.printU64(info.receives);
    ctx.write(" drop=");
    ctx.printU64(info.drops);
    ctx.write("\r\n");
}

fn writeRuntimeSource(ctx: *const App, value: r4os.abi.NetDetailProtocolRuntime) void {
    ctx.write(runtimeSource(value));
}

fn runtimeSource(value: r4os.abi.NetDetailProtocolRuntime) []const u8 {
    if (value.active_r4p != 0) return "r4p";
    if (value.builtin_fallback != 0) return "legacy";
    return switch (value.r4p_state) {
        r4os.abi.net_detail_r4p_state_missing => "miss",
        r4os.abi.net_detail_r4p_state_loaded => "load",
        r4os.abi.net_detail_r4p_state_blocked => "block",
        r4os.abi.net_detail_r4p_state_error => "err",
        r4os.abi.net_detail_r4p_state_disabled => "off",
        else => "unk",
    };
}

fn protocolFailures(detail: r4os.abi.NetDetailSnapshot) u64 {
    var total: u64 = 0;
    var i: usize = 0;
    while (i < detail.protocols.len) : (i += 1) total += detail.protocols[i].dispatch_failures;
    return total;
}

fn r4pRequiredCount(detail: r4os.abi.NetDetailSnapshot) u64 {
    var total: u64 = 0;
    var i: usize = 0;
    while (i < detail.protocols.len) : (i += 1) {
        if (detail.protocols[i].builtin_fallback == 0 and
            detail.protocols[i].fallback_policy == r4os.abi.net_detail_fallback_policy_none and
            detail.protocols[i].fallback_decision == r4os.abi.net_detail_fallback_decision_none)
        {
            total += 1;
        }
    }
    return total;
}

fn networkPacketErrors(detail: r4os.abi.NetDetailSnapshot) u64 {
    return detail.adapter.drops +
        detail.adapter.errors +
        detail.ethernet.dropped_short +
        detail.ethernet.dropped_filter +
        detail.ethernet.unknown_ethertype +
        detail.arp.malformed +
        detail.arp.pending_drops +
        detail.ipv4.dropped_short +
        detail.ipv4.dropped_version +
        detail.ipv4.dropped_checksum +
        detail.ipv4.dropped_fragment +
        detail.ipv4.dropped_destination +
        detail.ipv4.dropped_tx_too_large +
        detail.ipv4.malformed +
        detail.icmp.malformed +
        detail.icmp.checksum_errors +
        detail.udp.dropped_short +
        detail.udp.dropped_length +
        detail.udp.checksum_errors +
        detail.udp.malformed +
        detail.dhcp.malformed +
        detail.dhcp.release_errors +
        detail.dns.malformed +
        detail.dns.tx_errors +
        detail.tcp.rx_drops +
        detail.tcp.checksum_errors;
}

fn networkProtocolErrors(detail: r4os.abi.NetDetailSnapshot) u64 {
    return detail.arp.resolve_timeouts +
        detail.arp.resolve_misses +
        detail.dns.timeouts +
        detail.dns.nxdomain +
        detail.tcp.timeouts +
        detail.tcp.rst_rx +
        protocolFailures(detail);
}

fn networkErrorTotal(ctx: *const App, detail: r4os.abi.NetDetailSnapshot) u64 {
    var service_errors: u64 = 0;
    var channel_id: u32 = service_channel_dhcp;
    while (channel_id <= service_channel_udp) : (channel_id += 1) {
        var info: r4os.abi.IpcChannelInfo = .{};
        if (ctx.ipcChannel(channel_id, &info) > 0) service_errors += info.drops;
    }
    return networkPacketErrors(detail) + networkProtocolErrors(detail) + service_errors;
}

fn shortServiceName(channel_id: u32) []const u8 {
    return switch (channel_id) {
        service_channel_dhcp => "net.dhcp",
        service_channel_dns => "net.dns",
        service_channel_tcp => "net.tcp",
        service_channel_udp => "net.udp",
        else => "ipc",
    };
}

fn writeIpv4(ctx: *const App, ip: [4]u8) void {
    ctx.printU64(ip[0]);
    ctx.putc('.');
    ctx.printU64(ip[1]);
    ctx.putc('.');
    ctx.printU64(ip[2]);
    ctx.putc('.');
    ctx.printU64(ip[3]);
}

fn writeMac(ctx: *const App, mac: [6]u8) void {
    var index: usize = 0;
    while (index < mac.len) : (index += 1) {
        if (index != 0) ctx.putc(':');
        writeHexByte(ctx, mac[index]);
    }
}

fn writeHexByte(ctx: *const App, value: u8) void {
    const digits = "0123456789ABCDEF";
    ctx.putc(digits[value >> 4]);
    ctx.putc(digits[value & 0x0F]);
}

fn writeHexU16(ctx: *const App, value: u16) void {
    writeHexByte(ctx, @truncate(value >> 8));
    writeHexByte(ctx, @truncate(value));
}

fn writeZ(ctx: *const App, value: []const u8) void {
    ctx.write(spanZ(value));
}

fn writeZOr(ctx: *const App, value: []const u8, fallback: []const u8) void {
    const text = spanZ(value);
    if (text.len == 0) {
        ctx.write(fallback);
    } else {
        ctx.write(text);
    }
}

fn spanZ(value: []const u8) []const u8 {
    var end: usize = 0;
    while (end < value.len and value[end] != 0) : (end += 1) {}
    return value[0..end];
}

fn zSlice(ptr: [*:0]const u8) []const u8 {
    var len: usize = 0;
    while (ptr[len] != 0) : (len += 1) {}
    return ptr[0..len];
}

fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isSpace(value[start])) : (start += 1) {}
    while (end > start and isSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var index: usize = 0;
    while (index < a.len) : (index += 1) {
        if (asciiUpper(a[index]) != asciiUpper(b[index])) return false;
    }
    return true;
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - 32;
    return ch;
}
