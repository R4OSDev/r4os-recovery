# Plattformgruppe R4NET

<!-- R4OS-APIREF:BEGIN R4NET (generiert von ApiContractGen aus ApiContract.json - NICHT von Hand editieren) -->
## Tabellen-Referenz R4NET (generiert)

Kernel-Gruppentabelle `R4XStartR4Net` v2, 296 Bytes, 35 Funktionsfelder und 35 Slots insgesamt.
Signatur-Wahrheit: `abi.R4NetFns` (Feldname == Tabellenfeld).
Ein Feld ist nutzbar, wenn `hasFn("feld")` es als vorhanden meldet.

| Slot | Offset | Zustand | Tabellenfeld | Signatur |
| ---: | ---: | --- | --- | --- |
| 0 | 16 | function | `tcp_connect` | `*const fn (u8, u8, u8, u8, u16) callconv(.c) i32` |
| 1 | 24 | function | `tcp_write` | `*const fn (u32, [*]const u8, u32) callconv(.c) i32` |
| 2 | 32 | function | `tcp_read` | `*const fn (u32, [*]u8, u32) callconv(.c) i32` |
| 3 | 40 | function | `tcp_close` | `*const fn (u32) callconv(.c) i32` |
| 4 | 48 | function | `tcp_summary` | `*const fn (*TcpSummary) callconv(.c) i32` |
| 5 | 56 | function | `tcp_connection` | `*const fn (u32, *TcpConnectionInfo) callconv(.c) i32` |
| 6 | 64 | function | `tcp_echo_listen_once` | `*const fn (u16, [*]u8, u32) callconv(.c) i32` |
| 7 | 72 | function | `tcp_accept_read_once` | `*const fn (u16, [*]u8, u32, *TcpAcceptResult) callconv(.c) i32` |
| 8 | 80 | function | `net_ipv4_send` | `*const fn (u8, u8, u8, u8, u8, [*]const u8, u32) callconv(.c) i32` |
| 9 | 88 | function | `net_ipv4_recv` | `*const fn (u8, *NetIpv4Packet, [*]u8, u32) callconv(.c) i32` |
| 10 | 96 | function | `net_config_get` | `*const fn (*NetConfigSnapshot) callconv(.c) i32` |
| 11 | 104 | function | `net_config_set` | `*const fn (*const NetConfigRequest) callconv(.c) i32` |
| 12 | 112 | function | `net_dns_resolve` | `*const fn ([*]const u8, u32, *[4]u8) callconv(.c) i32` |
| 13 | 120 | function | `net_dns_resolve_server` | `*const fn (u8, u8, u8, u8, [*]const u8, u32, *[4]u8) callconv(.c) i32` |
| 14 | 128 | function | `net_dhcp_acquire` | `*const fn () callconv(.c) i32` |
| 15 | 136 | function | `net_dhcp_renew` | `*const fn () callconv(.c) i32` |
| 16 | 144 | function | `net_dhcp_release` | `*const fn () callconv(.c) i32` |
| 17 | 152 | function | `net_dhcp_status` | `*const fn (*DhcpStatus) callconv(.c) i32` |
| 18 | 160 | function | `net_detail_get` | `*const fn (u32, *NetDetailSnapshot) callconv(.c) i32` |
| 19 | 168 | function | `net_diag_run` | `*const fn (u32, *NetDiagResult) callconv(.c) i32` |
| 20 | 176 | function | `ipc_open` | `*const fn (u32) callconv(.c) i32` |
| 21 | 184 | function | `ipc_send` | `*const fn (u32, [*]const u8, u32) callconv(.c) i32` |
| 22 | 192 | function | `ipc_recv` | `*const fn (u32, [*]u8, u32) callconv(.c) i32` |
| 23 | 200 | function | `ipc_poll` | `*const fn (u32) callconv(.c) i32` |
| 24 | 208 | function | `ipc_close` | `*const fn (u32) callconv(.c) i32` |
| 25 | 216 | function | `ipc_summary` | `*const fn (*IpcSummary) callconv(.c) i32` |
| 26 | 224 | function | `ipc_channel` | `*const fn (u32, *IpcChannelInfo) callconv(.c) i32` |
| 27 | 232 | function | `serial_link_status` | `*const fn (*SerialLinkStatus) callconv(.c) i32` |
| 28 | 240 | function | `serial_link_poll` | `*const fn () callconv(.c) i32` |
| 29 | 248 | function | `serial_link_send_message` | `*const fn ([*]const u8, u32) callconv(.c) i32` |
| 30 | 256 | function | `serial_link_host_test` | `*const fn () callconv(.c) i32` |
| 31 | 264 | function | `serial_link_inbox` | `*const fn (*SerialLinkMessage) callconv(.c) i32` |
| 32 | 272 | function | `net_service_request` | `*const fn (u32, u16, u32, u16, [*]const u8, u32, [*]u8, u32) callconv(.c) i32` |
| 33 | 280 | function | `ipc_performance` | `*const fn (u32, *IpcPerformanceSummary) callconv(.c) i32` |
| 34 | 288 | function | `tcp_performance` | `*const fn (*TcpPerformanceInfo) callconv(.c) i32` |
<!-- R4OS-APIREF:END R4NET -->