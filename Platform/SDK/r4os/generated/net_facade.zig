// Generated from compiler-typed r4net.Context; do not edit.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const net = @import("../r4net.zig");
const program = @import("../program.zig");
const bridge = @import("../net_bridge_support.zig");
pub export fn R4SdkNet_ipcOpen(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcOpen(p0);
    return value;
}
pub export fn R4SdkNet2_ipcOpen(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcOpen(p0);
    return value;
}
pub export fn R4SdkNet_ipcSend(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcSend(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_ipcSend(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcSend(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_ipcRecv(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcRecv(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_ipcRecv(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcRecv(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_ipcPoll(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcPoll(p0);
    return value;
}
pub export fn R4SdkNet2_ipcPoll(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcPoll(p0);
    return value;
}
pub export fn R4SdkNet_ipcClose(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcClose(p0);
    return value;
}
pub export fn R4SdkNet2_ipcClose(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcClose(p0);
    return value;
}
pub export fn R4SdkNet_ipcSummary(context: *const abi.R4XStartContext, p0: *abi.IpcSummary) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcSummary(p0);
    return value;
}
pub export fn R4SdkNet2_ipcSummary(context: *const @import("../platform2.zig").Context, p0: *abi.IpcSummary) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcSummary(p0);
    return value;
}
pub export fn R4SdkNet_ipcChannel(context: *const abi.R4XStartContext, p0: u32, p1: *abi.IpcChannelInfo) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcChannel(p0, p1);
    return value;
}
pub export fn R4SdkNet2_ipcChannel(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.IpcChannelInfo) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcChannel(p0, p1);
    return value;
}
pub export fn R4SdkNet_ipcPerformance(context: *const abi.R4XStartContext, p0: u32, p1: *abi.IpcPerformanceSummary) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.ipcPerformance(p0, p1);
    return value;
}
pub export fn R4SdkNet2_ipcPerformance(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.IpcPerformanceSummary) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.ipcPerformance(p0, p1);
    return value;
}
pub export fn R4SdkNet_netServiceRequest(context: *const abi.R4XStartContext, p0: u32, p1: u16, p2: u32, p3: [*]const u8, n3: u32, p4: [*]u8, n4: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceRequest(p0, p1, p2, p3[0..n3], p4[0..n4]);
    return value;
}
pub export fn R4SdkNet2_netServiceRequest(context: *const @import("../platform2.zig").Context, p0: u32, p1: u16, p2: u32, p3: [*]const u8, n3: u32, p4: [*]u8, n4: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceRequest(p0, p1, p2, p3[0..n3], p4[0..n4]);
    return value;
}
pub export fn R4SdkNet_netServiceClientId(context: *const abi.R4XStartContext) callconv(.c) u16 {
    const bundle = bridge.bundle(context) orelse return 0;
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceClientId();
    return value;
}
pub export fn R4SdkNet2_netServiceClientId(context: *const @import("../platform2.zig").Context) callconv(.c) u16 {
    _ = context.system() orelse return 0;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceClientId();
    return value;
}
pub export fn R4SdkNet_netServicePayload(context: *const abi.R4XStartContext, p0: [*]const u8, n0: u32, p1: *i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netServicePayload(p0[0..n0], p1);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netServicePayload(context: *const @import("../platform2.zig").Context, p0: [*]const u8, n0: u32, p1: *i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServicePayload(p0[0..n0], p1);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netSocketLifecycleName(context: *const abi.R4XStartContext, p0: u32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netSocketLifecycleName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netSocketLifecycleName(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netSocketLifecycleName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netSocketBegin(context: *const abi.R4XStartContext, p0: u8, p1: u16, p2: [*]const u8, n2: u32, p3: u64, p4: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const enum0: program.NetSocketService = switch (p0) { 0 => .tcp, 1 => .udp, else => return abi.io_error_invalid };
    const value = owner.netSocketBegin(enum0, p1, p2[0..n2], p3, bridge.request(p4));
    return value;
}
pub export fn R4SdkNet2_netSocketBegin(context: *const @import("../platform2.zig").Context, p0: u8, p1: u16, p2: [*]const u8, n2: u32, p3: u64, p4: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const enum0: program.NetSocketService = switch (p0) { 0 => .tcp, 1 => .udp, else => return abi.io_error_invalid };
    const value = owner.netSocketBegin(enum0, p1, p2[0..n2], p3, bridge.request(p4));
    return value;
}
pub export fn R4SdkNet_netSocketStatus(context: *const abi.R4XStartContext, p0: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netSocketStatus(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet2_netSocketStatus(context: *const @import("../platform2.zig").Context, p0: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netSocketStatus(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet_netSocketWait(context: *const abi.R4XStartContext, p0: *bridge.Request, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netSocketWait(bridge.request(p0), p1);
    return value;
}
pub export fn R4SdkNet2_netSocketWait(context: *const @import("../platform2.zig").Context, p0: *bridge.Request, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netSocketWait(bridge.request(p0), p1);
    return value;
}
pub export fn R4SdkNet_netSocketClose(context: *const abi.R4XStartContext, p0: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netSocketClose(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet2_netSocketClose(context: *const @import("../platform2.zig").Context, p0: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netSocketClose(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet_netSocketWaitAndClose(context: *const abi.R4XStartContext, p0: *bridge.Request, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netSocketWaitAndClose(bridge.request(p0), p1);
    return value;
}
pub export fn R4SdkNet2_netSocketWaitAndClose(context: *const @import("../platform2.zig").Context, p0: *bridge.Request, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netSocketWaitAndClose(bridge.request(p0), p1);
    return value;
}
pub export fn R4SdkNet_netResolveA(context: *const abi.R4XStartContext, p0: [*]const u8, n0: u32, p1: bridge.Options, p2: *bridge.ResolverResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    var result2: program.ResolverResult = .{};
    const value = owner.netResolveA(p0[0..n0], .{ .server = if (p1.has_server != 0) p1.server else null }, &result2);
    p2.* = bridge.flatten(bridge.ResolverResult, result2);
    return value;
}
pub export fn R4SdkNet2_netResolveA(context: *const @import("../platform2.zig").Context, p0: [*]const u8, n0: u32, p1: bridge.Options, p2: *bridge.ResolverResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    var result2: program.ResolverResult = .{};
    const value = owner.netResolveA(p0[0..n0], .{ .server = if (p1.has_server != 0) p1.server else null }, &result2);
    p2.* = bridge.flatten(bridge.ResolverResult, result2);
    return value;
}
pub export fn R4SdkNet_netDnsResolveService(context: *const abi.R4XStartContext, p0: [*]const u8, n0: u32, p1: *[4]u8) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResolveService(p0[0..n0], p1);
    return value;
}
pub export fn R4SdkNet2_netDnsResolveService(context: *const @import("../platform2.zig").Context, p0: [*]const u8, n0: u32, p1: *[4]u8) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResolveService(p0[0..n0], p1);
    return value;
}
pub export fn R4SdkNet_netDnsResolveServerService(context: *const abi.R4XStartContext, p0: *const [4]u8, p1: [*]const u8, n1: u32, p2: *[4]u8) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResolveServerService(p0.*, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_netDnsResolveServerService(context: *const @import("../platform2.zig").Context, p0: *const [4]u8, p1: [*]const u8, n1: u32, p2: *[4]u8) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResolveServerService(p0.*, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_netDnsResolveServiceResult(context: *const abi.R4XStartContext, p0: [*]const u8, n0: u32, p1: *abi.NetServiceDnsResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResolveServiceResult(p0[0..n0], p1);
    return value;
}
pub export fn R4SdkNet2_netDnsResolveServiceResult(context: *const @import("../platform2.zig").Context, p0: [*]const u8, n0: u32, p1: *abi.NetServiceDnsResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResolveServiceResult(p0[0..n0], p1);
    return value;
}
pub export fn R4SdkNet_netDnsResolveServerServiceResult(context: *const abi.R4XStartContext, p0: *const [4]u8, p1: [*]const u8, n1: u32, p2: *abi.NetServiceDnsResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResolveServerServiceResult(p0.*, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_netDnsResolveServerServiceResult(context: *const @import("../platform2.zig").Context, p0: *const [4]u8, p1: [*]const u8, n1: u32, p2: *abi.NetServiceDnsResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResolveServerServiceResult(p0.*, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_netDnsServiceStatusRaw(context: *const abi.R4XStartContext, p0: *abi.NetServiceDnsStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet2_netDnsServiceStatusRaw(context: *const @import("../platform2.zig").Context, p0: *abi.NetServiceDnsStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet_netDhcpAcquireService(context: *const abi.R4XStartContext) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpAcquireService();
    return value;
}
pub export fn R4SdkNet2_netDhcpAcquireService(context: *const @import("../platform2.zig").Context) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpAcquireService();
    return value;
}
pub export fn R4SdkNet_netDhcpRenewService(context: *const abi.R4XStartContext) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpRenewService();
    return value;
}
pub export fn R4SdkNet2_netDhcpRenewService(context: *const @import("../platform2.zig").Context) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpRenewService();
    return value;
}
pub export fn R4SdkNet_netDhcpReleaseService(context: *const abi.R4XStartContext) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpReleaseService();
    return value;
}
pub export fn R4SdkNet2_netDhcpReleaseService(context: *const @import("../platform2.zig").Context) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpReleaseService();
    return value;
}
pub export fn R4SdkNet_netDhcpServiceStatus(context: *const abi.R4XStartContext, p0: *abi.DhcpStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpServiceStatus(p0);
    return value;
}
pub export fn R4SdkNet2_netDhcpServiceStatus(context: *const @import("../platform2.zig").Context, p0: *abi.DhcpStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpServiceStatus(p0);
    return value;
}
pub export fn R4SdkNet_netDhcpServiceStatusRaw(context: *const abi.R4XStartContext, p0: *abi.NetServiceDhcpStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet2_netDhcpServiceStatusRaw(context: *const @import("../platform2.zig").Context, p0: *abi.NetServiceDhcpStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet_netDhcpServiceAction(context: *const abi.R4XStartContext, p0: u16, p1: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpServiceAction(p0, p1);
    return value;
}
pub export fn R4SdkNet2_netDhcpServiceAction(context: *const @import("../platform2.zig").Context, p0: u16, p1: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpServiceAction(p0, p1);
    return value;
}
pub export fn R4SdkNet_netDhcpServiceActionResult(context: *const abi.R4XStartContext, p0: u16, p1: *abi.NetServiceDhcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpServiceActionResult(p0, p1);
    return value;
}
pub export fn R4SdkNet2_netDhcpServiceActionResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.NetServiceDhcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpServiceActionResult(p0, p1);
    return value;
}
pub export fn R4SdkNet_udpServiceStatusRaw(context: *const abi.R4XStartContext, p0: *abi.NetServiceUdpStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet2_udpServiceStatusRaw(context: *const @import("../platform2.zig").Context, p0: *abi.NetServiceUdpStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet_udpServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: [*]const u8, n1: u32, p2: *abi.NetServiceUdpResult, p3: [*]u8, n3: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpServiceResult(p0, p1[0..n1], p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet2_udpServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]const u8, n1: u32, p2: *abi.NetServiceUdpResult, p3: [*]u8, n3: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpServiceResult(p0, p1[0..n1], p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet_udpBindService(context: *const abi.R4XStartContext, p0: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBindService(p0);
    return value;
}
pub export fn R4SdkNet2_udpBindService(context: *const @import("../platform2.zig").Context, p0: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBindService(p0);
    return value;
}
pub export fn R4SdkNet_udpSendToService(context: *const abi.R4XStartContext, p0: u32, p1: *const [4]u8, p2: u16, p3: [*]const u8, n3: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpSendToService(p0, p1.*, p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet2_udpSendToService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *const [4]u8, p2: u16, p3: [*]const u8, n3: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpSendToService(p0, p1.*, p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet_udpRecvFromService(context: *const abi.R4XStartContext, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpRecvFromService(p0, p1, p2[0..n2]);
    return value;
}
pub export fn R4SdkNet2_udpRecvFromService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpRecvFromService(p0, p1, p2[0..n2]);
    return value;
}
pub export fn R4SdkNet_udpRecvFromServiceResult(context: *const abi.R4XStartContext, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32, p3: *abi.NetServiceUdpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpRecvFromServiceResult(p0, p1, p2[0..n2], p3);
    return value;
}
pub export fn R4SdkNet2_udpRecvFromServiceResult(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32, p3: *abi.NetServiceUdpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpRecvFromServiceResult(p0, p1, p2[0..n2], p3);
    return value;
}
pub export fn R4SdkNet_udpRecvFromWaitService(context: *const abi.R4XStartContext, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpRecvFromWaitService(p0, p1, p2[0..n2], p3);
    return value;
}
pub export fn R4SdkNet2_udpRecvFromWaitService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpRecvFromWaitService(p0, p1, p2[0..n2], p3);
    return value;
}
pub export fn R4SdkNet_udpCloseService(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpCloseService(p0);
    return value;
}
pub export fn R4SdkNet2_udpCloseService(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpCloseService(p0);
    return value;
}
pub export fn R4SdkNet_udpBeginStatusService(context: *const abi.R4XStartContext, p0: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBeginStatusService(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet2_udpBeginStatusService(context: *const @import("../platform2.zig").Context, p0: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBeginStatusService(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet_udpBeginServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: [*]const u8, n1: u32, p2: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBeginServiceResult(p0, p1[0..n1], bridge.request(p2));
    return value;
}
pub export fn R4SdkNet2_udpBeginServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]const u8, n1: u32, p2: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBeginServiceResult(p0, p1[0..n1], bridge.request(p2));
    return value;
}
pub export fn R4SdkNet_udpBeginBindService(context: *const abi.R4XStartContext, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBeginBindService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_udpBeginBindService(context: *const @import("../platform2.zig").Context, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBeginBindService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_udpBeginSendToService(context: *const abi.R4XStartContext, p0: u32, p1: *const [4]u8, p2: u16, p3: [*]const u8, n3: u32, p4: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBeginSendToService(p0, p1.*, p2, p3[0..n3], bridge.request(p4));
    return value;
}
pub export fn R4SdkNet2_udpBeginSendToService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *const [4]u8, p2: u16, p3: [*]const u8, n3: u32, p4: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBeginSendToService(p0, p1.*, p2, p3[0..n3], bridge.request(p4));
    return value;
}
pub export fn R4SdkNet_udpBeginRecvFromService(context: *const abi.R4XStartContext, p0: u32, p1: usize, p2: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBeginRecvFromService(p0, p1, bridge.request(p2));
    return value;
}
pub export fn R4SdkNet2_udpBeginRecvFromService(context: *const @import("../platform2.zig").Context, p0: u32, p1: usize, p2: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBeginRecvFromService(p0, p1, bridge.request(p2));
    return value;
}
pub export fn R4SdkNet_udpBeginCloseService(context: *const abi.R4XStartContext, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBeginCloseService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_udpBeginCloseService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBeginCloseService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpServiceStatusRaw(context: *const abi.R4XStartContext, p0: *abi.NetServiceTcpStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet2_tcpServiceStatusRaw(context: *const @import("../platform2.zig").Context, p0: *abi.NetServiceTcpStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpServiceStatusRaw(p0);
    return value;
}
pub export fn R4SdkNet_tcpServiceStatusRawWait(context: *const abi.R4XStartContext, p0: *abi.NetServiceTcpStatus, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpServiceStatusRawWait(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpServiceStatusRawWait(context: *const @import("../platform2.zig").Context, p0: *abi.NetServiceTcpStatus, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpServiceStatusRawWait(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: [*]u8, n3: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpServiceResult(p0, p1[0..n1], p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet2_tcpServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: [*]u8, n3: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpServiceResult(p0, p1[0..n1], p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet_tcpServiceResultWait(context: *const abi.R4XStartContext, p0: u16, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: [*]u8, n3: u32, p4: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpServiceResultWait(p0, p1[0..n1], p2, p3[0..n3], p4);
    return value;
}
pub export fn R4SdkNet2_tcpServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: [*]u8, n3: u32, p4: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpServiceResultWait(p0, p1[0..n1], p2, p3[0..n3], p4);
    return value;
}
pub export fn R4SdkNet_tcpConnectServiceResult(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpConnectServiceResult(p0, p1, p2, p3, p4, p5);
    return value;
}
pub export fn R4SdkNet2_tcpConnectServiceResult(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpConnectServiceResult(p0, p1, p2, p3, p4, p5);
    return value;
}
pub export fn R4SdkNet_tcpConnectServiceResultWait(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: *abi.NetServiceTcpResult, p6: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpConnectServiceResultWait(p0, p1, p2, p3, p4, p5, p6);
    return value;
}
pub export fn R4SdkNet2_tcpConnectServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: *abi.NetServiceTcpResult, p6: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpConnectServiceResultWait(p0, p1, p2, p3, p4, p5, p6);
    return value;
}
pub export fn R4SdkNet_tcpConnectService(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpConnectService(p0, p1, p2, p3, p4);
    return value;
}
pub export fn R4SdkNet2_tcpConnectService(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpConnectService(p0, p1, p2, p3, p4);
    return value;
}
pub export fn R4SdkNet_tcpConnectServiceWait(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpConnectServiceWait(p0, p1, p2, p3, p4, p5);
    return value;
}
pub export fn R4SdkNet2_tcpConnectServiceWait(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpConnectServiceWait(p0, p1, p2, p3, p4, p5);
    return value;
}
pub export fn R4SdkNet_tcpWriteChunkServiceResult(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWriteChunkServiceResult(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpWriteChunkServiceResult(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWriteChunkServiceResult(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpWriteChunkServiceResultWait(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWriteChunkServiceResultWait(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpWriteChunkServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWriteChunkServiceResultWait(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpWritePacedService(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWritePacedService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpWritePacedService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWritePacedService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpWritePacedServiceBounded(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32, p2: u64, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWritePacedServiceBounded(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpWritePacedServiceBounded(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32, p2: u64, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWritePacedServiceBounded(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpWaitForTxWindowService(context: *const abi.R4XStartContext, p0: u32, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWaitForTxWindowService(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpWaitForTxWindowService(context: *const @import("../platform2.zig").Context, p0: u32, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWaitForTxWindowService(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpWaitForTxWindowServiceBounded(context: *const abi.R4XStartContext, p0: u32, p1: u64, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWaitForTxWindowServiceBounded(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpWaitForTxWindowServiceBounded(context: *const @import("../platform2.zig").Context, p0: u32, p1: u64, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWaitForTxWindowServiceBounded(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpWriteChunkService(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWriteChunkService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpWriteChunkService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWriteChunkService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpWriteChunkServiceWait(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWriteChunkServiceWait(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpWriteChunkServiceWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWriteChunkServiceWait(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpWriteService(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWriteService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpWriteService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWriteService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpReadServiceResult(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadServiceResult(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpReadServiceResult(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadServiceResult(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpReadServiceResultWait(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadServiceResultWait(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpReadServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadServiceResultWait(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpReadService(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpReadService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpReadServiceWait(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadServiceWait(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpReadServiceWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadServiceWait(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpReadAvailableService(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadAvailableService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpReadAvailableService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadAvailableService(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpReadWaitService(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadWaitService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpReadWaitService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadWaitService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpReadWaitServiceBounded(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: u64, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadWaitServiceBounded(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpReadWaitServiceBounded(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: u64, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadWaitServiceBounded(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpReadWaitServiceConsumeSafe(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: u64, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadWaitServiceConsumeSafe(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpReadWaitServiceConsumeSafe(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: u64, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadWaitServiceConsumeSafe(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpReadAvailableWaitService(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadAvailableWaitService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpReadAvailableWaitService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadAvailableWaitService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpListenServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpListenServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpListenServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpListenServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpListenServiceResultWait(context: *const abi.R4XStartContext, p0: u16, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpListenServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpListenServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpListenServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpListenService(context: *const abi.R4XStartContext, p0: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpListenService(p0);
    return value;
}
pub export fn R4SdkNet2_tcpListenService(context: *const @import("../platform2.zig").Context, p0: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpListenService(p0);
    return value;
}
pub export fn R4SdkNet_tcpPollService(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpPollService(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpPollService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpPollService(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpPollServiceWait(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpPollServiceWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpPollServiceWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpPollServiceWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpReadinessFromResult(context: *const abi.R4XStartContext, p0: *const abi.NetServiceTcpResult) callconv(.c) bridge.Readiness {
    const bundle = bridge.bundle(context) orelse return std.mem.zeroes(bridge.Readiness);
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadinessFromResult(p0);
    return bridge.flatten(bridge.Readiness, value);
}
pub export fn R4SdkNet2_tcpReadinessFromResult(context: *const @import("../platform2.zig").Context, p0: *const abi.NetServiceTcpResult) callconv(.c) bridge.Readiness {
    _ = context.system() orelse return std.mem.zeroes(bridge.Readiness);
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadinessFromResult(p0);
    return bridge.flatten(bridge.Readiness, value);
}
pub export fn R4SdkNet_tcpReadinessReadable(context: *const abi.R4XStartContext, p0: *const abi.NetServiceTcpResult) callconv(.c) u8 {
    const bundle = bridge.bundle(context) orelse return 0;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadinessReadable(p0);
    return @intFromBool(value);
}
pub export fn R4SdkNet2_tcpReadinessReadable(context: *const @import("../platform2.zig").Context, p0: *const abi.NetServiceTcpResult) callconv(.c) u8 {
    _ = context.system() orelse return 0;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadinessReadable(p0);
    return @intFromBool(value);
}
pub export fn R4SdkNet_tcpReadinessWritable(context: *const abi.R4XStartContext, p0: *const abi.NetServiceTcpResult) callconv(.c) u8 {
    const bundle = bridge.bundle(context) orelse return 0;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadinessWritable(p0);
    return @intFromBool(value);
}
pub export fn R4SdkNet2_tcpReadinessWritable(context: *const @import("../platform2.zig").Context, p0: *const abi.NetServiceTcpResult) callconv(.c) u8 {
    _ = context.system() orelse return 0;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadinessWritable(p0);
    return @intFromBool(value);
}
pub export fn R4SdkNet_tcpReadinessTerminal(context: *const abi.R4XStartContext, p0: *const abi.NetServiceTcpResult) callconv(.c) u8 {
    const bundle = bridge.bundle(context) orelse return 0;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpReadinessTerminal(p0);
    return @intFromBool(value);
}
pub export fn R4SdkNet2_tcpReadinessTerminal(context: *const @import("../platform2.zig").Context, p0: *const abi.NetServiceTcpResult) callconv(.c) u8 {
    _ = context.system() orelse return 0;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpReadinessTerminal(p0);
    return @intFromBool(value);
}
pub export fn R4SdkNet_tcpAcceptServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptServiceResult(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptServiceResult(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpAcceptPollServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptPollServiceResult(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptPollServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptPollServiceResult(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpAcceptPollServiceResultWait(context: *const abi.R4XStartContext, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptPollServiceResultWait(p0, p1, p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptPollServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptPollServiceResultWait(p0, p1, p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpAcceptWaitServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptWaitServiceResult(p0, p1, p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptWaitServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptWaitServiceResult(p0, p1, p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpAcceptWaitServiceResultWait(context: *const abi.R4XStartContext, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult, p3: u64, p4: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptWaitServiceResultWait(p0, p1, p2, p3, p4);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptWaitServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.TcpAcceptResult, p2: *abi.NetServiceTcpResult, p3: u64, p4: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptWaitServiceResultWait(p0, p1, p2, p3, p4);
    return value;
}
pub export fn R4SdkNet_tcpAcceptService(context: *const abi.R4XStartContext, p0: u16, p1: *abi.TcpAcceptResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptService(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptService(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.TcpAcceptResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptService(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpCloseServiceResult(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpCloseServiceResult(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpCloseServiceResultWait(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpCloseServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpAbortServiceResult(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAbortServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpAbortServiceResult(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAbortServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpAbortServiceResultWait(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAbortServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpAbortServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAbortServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpAbortService(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAbortService(p0);
    return value;
}
pub export fn R4SdkNet2_tcpAbortService(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAbortService(p0);
    return value;
}
pub export fn R4SdkNet_tcpAbortServiceWait(context: *const abi.R4XStartContext, p0: u32, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAbortServiceWait(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpAbortServiceWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAbortServiceWait(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpRetransmitServiceResult(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpRetransmitServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpRetransmitServiceResult(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpRetransmitServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpRetransmitServiceResultWait(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpRetransmitServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpRetransmitServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpRetransmitServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpRetransmitService(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpRetransmitService(p0);
    return value;
}
pub export fn R4SdkNet2_tcpRetransmitService(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpRetransmitService(p0);
    return value;
}
pub export fn R4SdkNet_tcpCloseService(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseService(p0);
    return value;
}
pub export fn R4SdkNet2_tcpCloseService(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseService(p0);
    return value;
}
pub export fn R4SdkNet_tcpCloseServiceWait(context: *const abi.R4XStartContext, p0: u32, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseServiceWait(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpCloseServiceWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseServiceWait(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpCloseListenServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseListenServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpCloseListenServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseListenServiceResult(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpCloseListenServiceResultWait(context: *const abi.R4XStartContext, p0: u16, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseListenServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet2_tcpCloseListenServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: *abi.NetServiceTcpResult, p2: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseListenServiceResultWait(p0, p1, p2);
    return value;
}
pub export fn R4SdkNet_tcpCloseListenService(context: *const abi.R4XStartContext, p0: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseListenService(p0);
    return value;
}
pub export fn R4SdkNet2_tcpCloseListenService(context: *const @import("../platform2.zig").Context, p0: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseListenService(p0);
    return value;
}
pub export fn R4SdkNet_tcpCloseListenServiceWait(context: *const abi.R4XStartContext, p0: u16, p1: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpCloseListenServiceWait(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpCloseListenServiceWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpCloseListenServiceWait(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpAcceptPollReadServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult, p3: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptPollReadServiceResult(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptPollReadServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult, p3: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptPollReadServiceResult(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpAcceptPollReadServiceResultWait(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult, p3: *abi.NetServiceTcpResult, p4: u64, p5: u64, p6: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptPollReadServiceResultWait(p0, p1[0..n1], p2, p3, p4, p5, p6);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptPollReadServiceResultWait(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult, p3: *abi.NetServiceTcpResult, p4: u64, p5: u64, p6: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptPollReadServiceResultWait(p0, p1[0..n1], p2, p3, p4, p5, p6);
    return value;
}
pub export fn R4SdkNet_tcpAcceptPollReadService(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptPollReadService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptPollReadService(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptPollReadService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpAcceptReadServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult, p3: *abi.NetServiceTcpResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptReadServiceResult(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptReadServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult, p3: *abi.NetServiceTcpResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptReadServiceResult(p0, p1[0..n1], p2, p3);
    return value;
}
pub export fn R4SdkNet_tcpAcceptReadService(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptReadService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptReadService(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptReadService(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_tcpBeginStatusService(context: *const abi.R4XStartContext, p0: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginStatusService(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet2_tcpBeginStatusService(context: *const @import("../platform2.zig").Context, p0: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginStatusService(bridge.request(p0));
    return value;
}
pub export fn R4SdkNet_tcpBeginServiceResult(context: *const abi.R4XStartContext, p0: u16, p1: [*]const u8, n1: u32, p2: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginServiceResult(p0, p1[0..n1], bridge.request(p2));
    return value;
}
pub export fn R4SdkNet2_tcpBeginServiceResult(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]const u8, n1: u32, p2: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginServiceResult(p0, p1[0..n1], bridge.request(p2));
    return value;
}
pub export fn R4SdkNet_tcpBeginConnectService(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginConnectService(p0, p1, p2, p3, p4, bridge.request(p5));
    return value;
}
pub export fn R4SdkNet2_tcpBeginConnectService(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginConnectService(p0, p1, p2, p3, p4, bridge.request(p5));
    return value;
}
pub export fn R4SdkNet_tcpBeginWriteChunkService(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32, p2: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginWriteChunkService(p0, p1[0..n1], bridge.request(p2));
    return value;
}
pub export fn R4SdkNet2_tcpBeginWriteChunkService(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32, p2: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginWriteChunkService(p0, p1[0..n1], bridge.request(p2));
    return value;
}
pub export fn R4SdkNet_tcpBeginReadService(context: *const abi.R4XStartContext, p0: u32, p1: usize, p2: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginReadService(p0, p1, bridge.request(p2));
    return value;
}
pub export fn R4SdkNet2_tcpBeginReadService(context: *const @import("../platform2.zig").Context, p0: u32, p1: usize, p2: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginReadService(p0, p1, bridge.request(p2));
    return value;
}
pub export fn R4SdkNet_tcpBeginPollService(context: *const abi.R4XStartContext, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginPollService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginPollService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginPollService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginListenService(context: *const abi.R4XStartContext, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginListenService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginListenService(context: *const @import("../platform2.zig").Context, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginListenService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginAcceptService(context: *const abi.R4XStartContext, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginAcceptService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginAcceptService(context: *const @import("../platform2.zig").Context, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginAcceptService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginAcceptPollService(context: *const abi.R4XStartContext, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginAcceptPollService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginAcceptPollService(context: *const @import("../platform2.zig").Context, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginAcceptPollService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginAcceptReadService(context: *const abi.R4XStartContext, p0: u16, p1: usize, p2: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginAcceptReadService(p0, p1, bridge.request(p2));
    return value;
}
pub export fn R4SdkNet2_tcpBeginAcceptReadService(context: *const @import("../platform2.zig").Context, p0: u16, p1: usize, p2: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginAcceptReadService(p0, p1, bridge.request(p2));
    return value;
}
pub export fn R4SdkNet_tcpBeginCloseService(context: *const abi.R4XStartContext, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginCloseService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginCloseService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginCloseService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginAbortService(context: *const abi.R4XStartContext, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginAbortService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginAbortService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginAbortService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginRetransmitService(context: *const abi.R4XStartContext, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginRetransmitService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginRetransmitService(context: *const @import("../platform2.zig").Context, p0: u32, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginRetransmitService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpBeginCloseListenService(context: *const abi.R4XStartContext, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpBeginCloseListenService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet2_tcpBeginCloseListenService(context: *const @import("../platform2.zig").Context, p0: u16, p1: *bridge.Request) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpBeginCloseListenService(p0, bridge.request(p1));
    return value;
}
pub export fn R4SdkNet_tcpConnect(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpConnect(p0, p1, p2, p3, p4);
    return value;
}
pub export fn R4SdkNet2_tcpConnect(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpConnect(p0, p1, p2, p3, p4);
    return value;
}
pub export fn R4SdkNet_tcpWrite(context: *const abi.R4XStartContext, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpWrite(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpWrite(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]const u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpWrite(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpRead(context: *const abi.R4XStartContext, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpRead(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpRead(context: *const @import("../platform2.zig").Context, p0: u32, p1: [*]u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpRead(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpClose(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpClose(p0);
    return value;
}
pub export fn R4SdkNet2_tcpClose(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpClose(p0);
    return value;
}
pub export fn R4SdkNet_tcpSummary(context: *const abi.R4XStartContext, p0: *abi.TcpSummary) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpSummary(p0);
    return value;
}
pub export fn R4SdkNet2_tcpSummary(context: *const @import("../platform2.zig").Context, p0: *abi.TcpSummary) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpSummary(p0);
    return value;
}
pub export fn R4SdkNet_tcpPerformance(context: *const abi.R4XStartContext, p0: *abi.TcpPerformanceInfo) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpPerformance(p0);
    return value;
}
pub export fn R4SdkNet2_tcpPerformance(context: *const @import("../platform2.zig").Context, p0: *abi.TcpPerformanceInfo) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpPerformance(p0);
    return value;
}
pub export fn R4SdkNet_tcpConnection(context: *const abi.R4XStartContext, p0: u32, p1: *abi.TcpConnectionInfo) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpConnection(p0, p1);
    return value;
}
pub export fn R4SdkNet2_tcpConnection(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.TcpConnectionInfo) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpConnection(p0, p1);
    return value;
}
pub export fn R4SdkNet_tcpEchoListenOnce(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpEchoListenOnce(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet2_tcpEchoListenOnce(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpEchoListenOnce(p0, p1[0..n1]);
    return value;
}
pub export fn R4SdkNet_tcpAcceptReadOnce(context: *const abi.R4XStartContext, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.tcpAcceptReadOnce(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_tcpAcceptReadOnce(context: *const @import("../platform2.zig").Context, p0: u16, p1: [*]u8, n1: u32, p2: *abi.TcpAcceptResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.tcpAcceptReadOnce(p0, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_netIpv4Send(context: *const abi.R4XStartContext, p0: u8, p1: u8, p2: u8, p3: u8, p4: u8, p5: [*]const u8, n5: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netIpv4Send(p0, p1, p2, p3, p4, p5[0..n5]);
    return value;
}
pub export fn R4SdkNet2_netIpv4Send(context: *const @import("../platform2.zig").Context, p0: u8, p1: u8, p2: u8, p3: u8, p4: u8, p5: [*]const u8, n5: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netIpv4Send(p0, p1, p2, p3, p4, p5[0..n5]);
    return value;
}
pub export fn R4SdkNet_netIpv4Recv(context: *const abi.R4XStartContext, p0: u8, p1: *abi.NetIpv4Packet, p2: [*]u8, n2: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netIpv4Recv(p0, p1, p2[0..n2]);
    return value;
}
pub export fn R4SdkNet2_netIpv4Recv(context: *const @import("../platform2.zig").Context, p0: u8, p1: *abi.NetIpv4Packet, p2: [*]u8, n2: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netIpv4Recv(p0, p1, p2[0..n2]);
    return value;
}
pub export fn R4SdkNet_udpBind(context: *const abi.R4XStartContext, p0: u16) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpBind(p0);
    return value;
}
pub export fn R4SdkNet2_udpBind(context: *const @import("../platform2.zig").Context, p0: u16) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpBind(p0);
    return value;
}
pub export fn R4SdkNet_udpSendTo(context: *const abi.R4XStartContext, p0: u32, p1: *const [4]u8, p2: u16, p3: [*]const u8, n3: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpSendTo(p0, p1.*, p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet2_udpSendTo(context: *const @import("../platform2.zig").Context, p0: u32, p1: *const [4]u8, p2: u16, p3: [*]const u8, n3: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpSendTo(p0, p1.*, p2, p3[0..n3]);
    return value;
}
pub export fn R4SdkNet_udpRecvFrom(context: *const abi.R4XStartContext, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpRecvFrom(p0, p1, p2[0..n2]);
    return value;
}
pub export fn R4SdkNet2_udpRecvFrom(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpRecvFrom(p0, p1, p2[0..n2]);
    return value;
}
pub export fn R4SdkNet_udpRecvFromWait(context: *const abi.R4XStartContext, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32, p3: u64) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpRecvFromWait(p0, p1, p2[0..n2], p3);
    return value;
}
pub export fn R4SdkNet2_udpRecvFromWait(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.UdpRecvInfo, p2: [*]u8, n2: u32, p3: u64) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpRecvFromWait(p0, p1, p2[0..n2], p3);
    return value;
}
pub export fn R4SdkNet_udpClose(context: *const abi.R4XStartContext, p0: u32) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpClose(p0);
    return value;
}
pub export fn R4SdkNet2_udpClose(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpClose(p0);
    return value;
}
pub export fn R4SdkNet_udpStatus(context: *const abi.R4XStartContext, p0: *abi.UdpStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.udpStatus(p0);
    return value;
}
pub export fn R4SdkNet2_udpStatus(context: *const @import("../platform2.zig").Context, p0: *abi.UdpStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.udpStatus(p0);
    return value;
}
pub export fn R4SdkNet_netConfigGet(context: *const abi.R4XStartContext, p0: *abi.NetConfigSnapshot) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netConfigGet(p0);
    return value;
}
pub export fn R4SdkNet2_netConfigGet(context: *const @import("../platform2.zig").Context, p0: *abi.NetConfigSnapshot) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netConfigGet(p0);
    return value;
}
pub export fn R4SdkNet_netConfigSet(context: *const abi.R4XStartContext, p0: *const abi.NetConfigRequest) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netConfigSet(p0);
    return value;
}
pub export fn R4SdkNet2_netConfigSet(context: *const @import("../platform2.zig").Context, p0: *const abi.NetConfigRequest) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netConfigSet(p0);
    return value;
}
pub export fn R4SdkNet_netDnsResolve(context: *const abi.R4XStartContext, p0: [*]const u8, n0: u32, p1: *[4]u8) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResolve(p0[0..n0], p1);
    return value;
}
pub export fn R4SdkNet2_netDnsResolve(context: *const @import("../platform2.zig").Context, p0: [*]const u8, n0: u32, p1: *[4]u8) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResolve(p0[0..n0], p1);
    return value;
}
pub export fn R4SdkNet_netDnsResolveServer(context: *const abi.R4XStartContext, p0: *const [4]u8, p1: [*]const u8, n1: u32, p2: *[4]u8) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResolveServer(p0.*, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet2_netDnsResolveServer(context: *const @import("../platform2.zig").Context, p0: *const [4]u8, p1: [*]const u8, n1: u32, p2: *[4]u8) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResolveServer(p0.*, p1[0..n1], p2);
    return value;
}
pub export fn R4SdkNet_netDhcpAcquire(context: *const abi.R4XStartContext) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpAcquire();
    return value;
}
pub export fn R4SdkNet2_netDhcpAcquire(context: *const @import("../platform2.zig").Context) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpAcquire();
    return value;
}
pub export fn R4SdkNet_netDhcpRenew(context: *const abi.R4XStartContext) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpRenew();
    return value;
}
pub export fn R4SdkNet2_netDhcpRenew(context: *const @import("../platform2.zig").Context) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpRenew();
    return value;
}
pub export fn R4SdkNet_netDhcpRelease(context: *const abi.R4XStartContext) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpRelease();
    return value;
}
pub export fn R4SdkNet2_netDhcpRelease(context: *const @import("../platform2.zig").Context) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpRelease();
    return value;
}
pub export fn R4SdkNet_netDhcpStatus(context: *const abi.R4XStartContext, p0: *abi.DhcpStatus) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpStatus(p0);
    return value;
}
pub export fn R4SdkNet2_netDhcpStatus(context: *const @import("../platform2.zig").Context, p0: *abi.DhcpStatus) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpStatus(p0);
    return value;
}
pub export fn R4SdkNet_netDetailGet(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetDetailSnapshot) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDetailGet(p0, p1);
    return value;
}
pub export fn R4SdkNet2_netDetailGet(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetDetailSnapshot) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDetailGet(p0, p1);
    return value;
}
pub export fn R4SdkNet_netDiagRun(context: *const abi.R4XStartContext, p0: u32, p1: *abi.NetDiagResult) callconv(.c) i32 {
    const bundle = bridge.bundle(context) orelse return abi.err_no_group;
    const owner = net.Context.init(&bundle);
    const value = owner.netDiagRun(p0, p1);
    return value;
}
pub export fn R4SdkNet2_netDiagRun(context: *const @import("../platform2.zig").Context, p0: u32, p1: *abi.NetDiagResult) callconv(.c) i32 {
    _ = context.system() orelse return abi.err_no_group;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDiagRun(p0, p1);
    return value;
}
pub export fn R4SdkNet_netDnsResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netDnsResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netDnsResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDnsResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netDhcpResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netDhcpResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netDhcpResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netDhcpResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netUdpResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netUdpResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netUdpResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netUdpResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netTcpResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netTcpResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netTcpResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netTcpResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netServiceResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netServiceResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netServiceStatusName(context: *const abi.R4XStartContext, p0: u32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceStatusName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netServiceStatusName(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceStatusName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netServiceStatusCode(context: *const abi.R4XStartContext, p0: u32) callconv(.c) u32 {
    const bundle = bridge.bundle(context) orelse return 0;
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceStatusCode(p0);
    return value;
}
pub export fn R4SdkNet2_netServiceStatusCode(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) u32 {
    _ = context.system() orelse return 0;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceStatusCode(p0);
    return value;
}
pub export fn R4SdkNet_netServiceStatusCodeName(context: *const abi.R4XStartContext, p0: u32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceStatusCodeName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netServiceStatusCodeName(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceStatusCodeName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netServiceSemanticFlags(context: *const abi.R4XStartContext, p0: u32) callconv(.c) u32 {
    const bundle = bridge.bundle(context) orelse return 0;
    const owner = net.Context.init(&bundle);
    const value = owner.netServiceSemanticFlags(p0);
    return value;
}
pub export fn R4SdkNet2_netServiceSemanticFlags(context: *const @import("../platform2.zig").Context, p0: u32) callconv(.c) u32 {
    _ = context.system() orelse return 0;
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netServiceSemanticFlags(p0);
    return value;
}
pub export fn R4SdkNet_netConfigResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netConfigResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netConfigResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netConfigResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet_netTxResultName(context: *const abi.R4XStartContext, p0: i32) callconv(.c) bridge.Slice {
    const bundle = bridge.bundle(context) orelse return .{};
    const owner = net.Context.init(&bundle);
    const value = owner.netTxResultName(p0);
    return bridge.slice(value);
}
pub export fn R4SdkNet2_netTxResultName(context: *const @import("../platform2.zig").Context, p0: i32) callconv(.c) bridge.Slice {
    _ = context.system() orelse return .{};
    const owner = net.Context.fromProgram(.{ .generation2 = context });
    const value = owner.netTxResultName(p0);
    return bridge.slice(value);
}
