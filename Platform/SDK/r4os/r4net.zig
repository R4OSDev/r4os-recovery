const abi = @import("r4os_contract").abi;
const program = @import("program.zig");

pub const name = "R4NET";
pub const import_query = "R4NET:Query:1";
pub const group = abi.R4LGroup.r4net;
pub const abi_version = abi.r4l_abi_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4net.h";
pub const query_contract = "Repositories/Contract/ABI/R4LQuery.txt";
pub const ResolverOptions = program.ResolverOptions;
pub const ResolverResult = program.ResolverResult;
pub const NetSocketService = program.NetSocketService;
pub const NetSocketRequest = program.NetSocketRequest;
pub const TcpReadiness = program.TcpReadiness;
pub const tcpResultReadiness = program.tcpResultReadiness;
pub const tcpResultReadable = program.tcpResultReadable;
pub const tcpResultWritable = program.tcpResultWritable;
pub const tcpResultTerminal = program.tcpResultTerminal;

pub const Context = struct {
    base: program.Context,

    pub fn init(bundle: *const program.Bundle) Context {
        return .{ .base = program.Context.initBundle(bundle) };
    }

    pub fn fromProgram(ctx: program.Context) Context {
        return .{ .base = ctx };
    }

    // 0.57.2: ehrliche Vertragspruefung (ersetzt supports*-Versionsgates).
    pub fn hasFn(self: *const Context, comptime field: []const u8) bool {
        return self.base.hasNetFn(field);
    }

    pub fn ipcOpen(self: *const Context, channel_id: u32) i32 {
        return self.base.ipcOpen(channel_id);
    }

    pub fn ipcSend(self: *const Context, channel_id: u32, data: []const u8) i32 {
        return self.base.ipcSend(channel_id, data);
    }

    pub fn ipcRecv(self: *const Context, channel_id: u32, out: []u8) i32 {
        return self.base.ipcRecv(channel_id, out);
    }

    pub fn ipcPoll(self: *const Context, channel_id: u32) i32 {
        return self.base.ipcPoll(channel_id);
    }

    pub fn ipcClose(self: *const Context, channel_id: u32) i32 {
        return self.base.ipcClose(channel_id);
    }

    pub fn ipcSummary(self: *const Context, out: *abi.IpcSummary) i32 {
        return self.base.ipcSummary(out);
    }

    pub fn ipcChannel(self: *const Context, channel_id: u32, out: *abi.IpcChannelInfo) i32 {
        return self.base.ipcChannel(channel_id, out);
    }

    pub fn ipcPerformance(self: *const Context, channel_id: u32, out: *abi.IpcPerformanceSummary) i32 {
        return self.base.ipcPerformance(channel_id, out);
    }

    pub fn netServiceRequest(self: *const Context, channel_id: u32, op: u16, request_id: u32, payload: []const u8, out: []u8) i32 {
        return self.base.netServiceRequest(channel_id, op, request_id, payload, out);
    }

    pub fn netServiceClientId(self: *const Context) u16 {
        return self.base.netServiceClientId();
    }

    pub fn netServicePayload(self: *const Context, response: []const u8, status: *i32) ?[]const u8 {
        return self.base.netServicePayload(response, status);
    }

    pub fn netSocketLifecycleName(self: *const Context, cause: u32) []const u8 {
        return self.base.netSocketLifecycleName(cause);
    }

    pub fn netSocketBegin(self: *const Context, service: NetSocketService, op: u16, payload_in: []const u8, timeout_ticks: u64, request: *NetSocketRequest) i32 {
        return self.base.netSocketBegin(service, op, payload_in, timeout_ticks, request);
    }

    pub fn netSocketStatus(self: *const Context, request: *NetSocketRequest) i32 {
        return self.base.netSocketStatus(request);
    }

    pub fn netSocketWait(self: *const Context, request: *NetSocketRequest, timeout_ticks: u64) i32 {
        return self.base.netSocketWait(request, timeout_ticks);
    }

    pub fn netSocketClose(self: *const Context, request: *NetSocketRequest) i32 {
        return self.base.netSocketClose(request);
    }

    pub fn netSocketWaitAndClose(self: *const Context, request: *NetSocketRequest, timeout_ticks: u64) i32 {
        return self.base.netSocketWaitAndClose(request, timeout_ticks);
    }

    pub fn netResolveA(self: *const Context, name_value: []const u8, options: ResolverOptions, out: *ResolverResult) i32 {
        return self.base.netResolveA(name_value, options, out);
    }

    pub fn netDnsResolveService(self: *const Context, name_value: []const u8, out: *[4]u8) i32 {
        return self.base.netDnsResolveService(name_value, out);
    }

    pub fn netDnsResolveServerService(self: *const Context, server: [4]u8, name_value: []const u8, out: *[4]u8) i32 {
        return self.base.netDnsResolveServerService(server, name_value, out);
    }

    pub fn netDnsResolveServiceResult(self: *const Context, name_value: []const u8, out: *abi.NetServiceDnsResult) i32 {
        return self.base.netDnsResolveServiceResult(name_value, out);
    }

    pub fn netDnsResolveServerServiceResult(self: *const Context, server: [4]u8, name_value: []const u8, out: *abi.NetServiceDnsResult) i32 {
        return self.base.netDnsResolveServerServiceResult(server, name_value, out);
    }

    pub fn netDnsServiceStatusRaw(self: *const Context, out: *abi.NetServiceDnsStatus) i32 {
        return self.base.netDnsServiceStatusRaw(out);
    }

    pub fn netDhcpAcquireService(self: *const Context) i32 {
        return self.base.netDhcpAcquireService();
    }

    pub fn netDhcpRenewService(self: *const Context) i32 {
        return self.base.netDhcpRenewService();
    }

    pub fn netDhcpReleaseService(self: *const Context) i32 {
        return self.base.netDhcpReleaseService();
    }

    pub fn netDhcpServiceStatus(self: *const Context, out: *abi.DhcpStatus) i32 {
        return self.base.netDhcpServiceStatus(out);
    }

    pub fn netDhcpServiceStatusRaw(self: *const Context, out: *abi.NetServiceDhcpStatus) i32 {
        return self.base.netDhcpServiceStatusRaw(out);
    }

    pub fn netDhcpServiceAction(self: *const Context, result_op: u16, fallback_op: u16) i32 {
        return self.base.netDhcpServiceAction(result_op, fallback_op);
    }

    pub fn netDhcpServiceActionResult(self: *const Context, op: u16, out: *abi.NetServiceDhcpResult) i32 {
        return self.base.netDhcpServiceActionResult(op, out);
    }

    pub fn udpServiceStatusRaw(self: *const Context, out: *abi.NetServiceUdpStatus) i32 {
        return self.base.udpServiceStatusRaw(out);
    }

    pub fn udpServiceResult(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceUdpResult, data_out: []u8) i32 {
        return self.base.udpServiceResult(op, payload_in, out, data_out);
    }

    pub fn udpBindService(self: *const Context, port: u16) i32 {
        return self.base.udpBindService(port);
    }

    pub fn udpSendToService(self: *const Context, handle: u32, dest_ip: [4]u8, dest_port: u16, payload_in: []const u8) i32 {
        return self.base.udpSendToService(handle, dest_ip, dest_port, payload_in);
    }

    pub fn udpRecvFromService(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload_out: []u8) i32 {
        return self.base.udpRecvFromService(handle, out, payload_out);
    }

    pub fn udpRecvFromServiceResult(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload_out: []u8, result: *abi.NetServiceUdpResult) i32 {
        return self.base.udpRecvFromServiceResult(handle, out, payload_out, result);
    }

    pub fn udpRecvFromWaitService(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload_out: []u8, wait_ticks: u64) i32 {
        return self.base.udpRecvFromWaitService(handle, out, payload_out, wait_ticks);
    }

    pub fn udpCloseService(self: *const Context, handle: u32) i32 {
        return self.base.udpCloseService(handle);
    }

    pub fn udpBeginStatusService(self: *const Context, request: *NetSocketRequest) i32 {
        return self.base.udpBeginStatusService(request);
    }

    pub fn udpBeginServiceResult(self: *const Context, op: u16, payload_in: []const u8, request: *NetSocketRequest) i32 {
        return self.base.udpBeginServiceResult(op, payload_in, request);
    }

    pub fn udpBeginBindService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        return self.base.udpBeginBindService(port, request);
    }

    pub fn udpBeginSendToService(self: *const Context, handle: u32, dest_ip: [4]u8, dest_port: u16, payload_in: []const u8, request: *NetSocketRequest) i32 {
        return self.base.udpBeginSendToService(handle, dest_ip, dest_port, payload_in, request);
    }

    pub fn udpBeginRecvFromService(self: *const Context, handle: u32, capacity: usize, request: *NetSocketRequest) i32 {
        return self.base.udpBeginRecvFromService(handle, capacity, request);
    }

    pub fn udpBeginCloseService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        return self.base.udpBeginCloseService(handle, request);
    }

    pub fn serialLinkStatus(self: *const Context, out: *abi.SerialLinkStatus) i32 {
        return self.base.serialLinkStatus(out);
    }

    pub fn serialLinkPoll(self: *const Context) i32 {
        return self.base.serialLinkPoll();
    }

    pub fn serialLinkSendMessage(self: *const Context, data: []const u8) i32 {
        return self.base.serialLinkSendMessage(data);
    }

    pub fn serialLinkHostTest(self: *const Context) i32 {
        return self.base.serialLinkHostTest();
    }

    pub fn serialLinkInbox(self: *const Context, out: *abi.SerialLinkMessage) i32 {
        return self.base.serialLinkInbox(out);
    }

    pub fn tcpServiceStatusRaw(self: *const Context, out: *abi.NetServiceTcpStatus) i32 {
        return self.base.tcpServiceStatusRaw(out);
    }

    pub fn tcpServiceStatusRawWait(self: *const Context, out: *abi.NetServiceTcpStatus, wait_ticks: u64) i32 {
        return self.base.tcpServiceStatusRawWait(out, wait_ticks);
    }

    pub fn tcpServiceResult(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceTcpResult, data_out: []u8) i32 {
        return self.base.tcpServiceResult(op, payload_in, out, data_out);
    }

    pub fn tcpServiceResultWait(self: *const Context, op: u16, payload_in: []const u8, out: *abi.NetServiceTcpResult, data_out: []u8, wait_ticks: u64) i32 {
        return self.base.tcpServiceResultWait(op, payload_in, out, data_out, wait_ticks);
    }

    pub fn tcpConnectServiceResult(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpConnectServiceResult(a, b, c, d, port, result);
    }

    pub fn tcpConnectServiceResultWait(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpConnectServiceResultWait(a, b, c, d, port, result, wait_ticks);
    }

    pub fn tcpConnectService(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16) i32 {
        return self.base.tcpConnectService(a, b, c, d, port);
    }

    pub fn tcpConnectServiceWait(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, wait_ticks: u64) i32 {
        return self.base.tcpConnectServiceWait(a, b, c, d, port, wait_ticks);
    }

    pub fn tcpWriteChunkServiceResult(self: *const Context, handle: u32, data: []const u8, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpWriteChunkServiceResult(handle, data, result);
    }

    pub fn tcpWriteChunkServiceResultWait(self: *const Context, handle: u32, data: []const u8, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpWriteChunkServiceResultWait(handle, data, result, wait_ticks);
    }

    pub fn tcpWritePacedService(self: *const Context, handle: u32, data: []const u8, wait_ticks: u64) i32 {
        return self.base.tcpWritePacedService(handle, data, wait_ticks);
    }

    pub fn tcpWritePacedServiceBounded(self: *const Context, handle: u32, data: []const u8, wait_ticks: u64, service_wait_ticks: u64) i32 {
        return self.base.tcpWritePacedServiceBounded(handle, data, wait_ticks, service_wait_ticks);
    }

    pub fn tcpWaitForTxWindowService(self: *const Context, handle: u32, wait_ticks: u64) i32 {
        return self.base.tcpWaitForTxWindowService(handle, wait_ticks);
    }

    pub fn tcpWaitForTxWindowServiceBounded(self: *const Context, handle: u32, wait_ticks: u64, service_wait_ticks: u64) i32 {
        return self.base.tcpWaitForTxWindowServiceBounded(handle, wait_ticks, service_wait_ticks);
    }

    pub fn tcpWriteChunkService(self: *const Context, handle: u32, data: []const u8) i32 {
        return self.base.tcpWriteChunkService(handle, data);
    }

    pub fn tcpWriteChunkServiceWait(self: *const Context, handle: u32, data: []const u8, wait_ticks: u64) i32 {
        return self.base.tcpWriteChunkServiceWait(handle, data, wait_ticks);
    }

    pub fn tcpWriteService(self: *const Context, handle: u32, data: []const u8) i32 {
        return self.base.tcpWriteService(handle, data);
    }

    pub fn tcpReadServiceResult(self: *const Context, handle: u32, out: []u8, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpReadServiceResult(handle, out, result);
    }

    pub fn tcpReadServiceResultWait(self: *const Context, handle: u32, out: []u8, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpReadServiceResultWait(handle, out, result, wait_ticks);
    }

    pub fn tcpReadService(self: *const Context, handle: u32, out: []u8) i32 {
        return self.base.tcpReadService(handle, out);
    }

    pub fn tcpReadServiceWait(self: *const Context, handle: u32, out: []u8, wait_ticks: u64) i32 {
        return self.base.tcpReadServiceWait(handle, out, wait_ticks);
    }

    pub fn tcpReadAvailableService(self: *const Context, handle: u32, out: []u8) i32 {
        return self.base.tcpReadAvailableService(handle, out);
    }

    pub fn tcpReadWaitService(self: *const Context, handle: u32, out: []u8, wait_ticks: u64) i32 {
        return self.base.tcpReadWaitService(handle, out, wait_ticks);
    }

    pub fn tcpReadWaitServiceBounded(self: *const Context, handle: u32, out: []u8, wait_ticks: u64, service_wait_ticks: u64) i32 {
        return self.base.tcpReadWaitServiceBounded(handle, out, wait_ticks, service_wait_ticks);
    }

    pub fn tcpReadWaitServiceConsumeSafe(self: *const Context, handle: u32, out: []u8, wait_ticks: u64, poll_wait_ticks: u64) i32 {
        return self.base.tcpReadWaitServiceConsumeSafe(handle, out, wait_ticks, poll_wait_ticks);
    }

    pub fn tcpReadAvailableWaitService(self: *const Context, handle: u32, out: []u8, wait_ticks: u64) i32 {
        return self.base.tcpReadAvailableWaitService(handle, out, wait_ticks);
    }

    pub fn tcpListenServiceResult(self: *const Context, port: u16, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpListenServiceResult(port, result);
    }

    pub fn tcpListenServiceResultWait(self: *const Context, port: u16, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpListenServiceResultWait(port, result, wait_ticks);
    }

    pub fn tcpListenService(self: *const Context, port: u16) i32 {
        return self.base.tcpListenService(port);
    }

    pub fn tcpPollService(self: *const Context, handle: u32, out: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpPollService(handle, out);
    }

    pub fn tcpPollServiceWait(self: *const Context, handle: u32, out: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpPollServiceWait(handle, out, wait_ticks);
    }

    pub fn tcpReadinessFromResult(self: *const Context, result: *const abi.NetServiceTcpResult) TcpReadiness {
        return self.base.tcpReadinessFromResult(result);
    }

    pub fn tcpReadinessReadable(self: *const Context, result: *const abi.NetServiceTcpResult) bool {
        return self.base.tcpReadinessReadable(result);
    }

    pub fn tcpReadinessWritable(self: *const Context, result: *const abi.NetServiceTcpResult) bool {
        return self.base.tcpReadinessWritable(result);
    }

    pub fn tcpReadinessTerminal(self: *const Context, result: *const abi.NetServiceTcpResult) bool {
        return self.base.tcpReadinessTerminal(result);
    }

    pub fn tcpAcceptServiceResult(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpAcceptServiceResult(port, result, structured);
    }

    pub fn tcpAcceptPollServiceResult(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpAcceptPollServiceResult(port, result, structured);
    }

    pub fn tcpAcceptPollServiceResultWait(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpAcceptPollServiceResultWait(port, result, structured, wait_ticks);
    }

    pub fn tcpAcceptWaitServiceResult(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpAcceptWaitServiceResult(port, result, structured, wait_ticks);
    }

    pub fn tcpAcceptWaitServiceResultWait(self: *const Context, port: u16, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, wait_ticks: u64, service_wait_ticks: u64) i32 {
        return self.base.tcpAcceptWaitServiceResultWait(port, result, structured, wait_ticks, service_wait_ticks);
    }

    pub fn tcpAcceptService(self: *const Context, port: u16, result: *abi.TcpAcceptResult) i32 {
        return self.base.tcpAcceptService(port, result);
    }

    pub fn tcpCloseServiceResult(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpCloseServiceResult(handle, result);
    }

    pub fn tcpCloseServiceResultWait(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpCloseServiceResultWait(handle, result, wait_ticks);
    }

    pub fn tcpAbortServiceResult(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpAbortServiceResult(handle, result);
    }

    pub fn tcpAbortServiceResultWait(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpAbortServiceResultWait(handle, result, wait_ticks);
    }

    pub fn tcpAbortService(self: *const Context, handle: u32) i32 {
        return self.base.tcpAbortService(handle);
    }

    pub fn tcpAbortServiceWait(self: *const Context, handle: u32, wait_ticks: u64) i32 {
        return self.base.tcpAbortServiceWait(handle, wait_ticks);
    }

    pub fn tcpRetransmitServiceResult(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpRetransmitServiceResult(handle, result);
    }

    pub fn tcpRetransmitServiceResultWait(self: *const Context, handle: u32, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpRetransmitServiceResultWait(handle, result, wait_ticks);
    }

    pub fn tcpRetransmitService(self: *const Context, handle: u32) i32 {
        return self.base.tcpRetransmitService(handle);
    }

    pub fn tcpCloseService(self: *const Context, handle: u32) i32 {
        return self.base.tcpCloseService(handle);
    }

    pub fn tcpCloseServiceWait(self: *const Context, handle: u32, wait_ticks: u64) i32 {
        return self.base.tcpCloseServiceWait(handle, wait_ticks);
    }

    pub fn tcpCloseListenServiceResult(self: *const Context, port: u16, result: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpCloseListenServiceResult(port, result);
    }

    pub fn tcpCloseListenServiceResultWait(self: *const Context, port: u16, result: *abi.NetServiceTcpResult, wait_ticks: u64) i32 {
        return self.base.tcpCloseListenServiceResultWait(port, result, wait_ticks);
    }

    pub fn tcpCloseListenService(self: *const Context, port: u16) i32 {
        return self.base.tcpCloseListenService(port);
    }

    pub fn tcpCloseListenServiceWait(self: *const Context, port: u16, wait_ticks: u64) i32 {
        return self.base.tcpCloseListenServiceWait(port, wait_ticks);
    }

    pub fn tcpAcceptPollReadServiceResult(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpAcceptPollReadServiceResult(port, out, result, structured);
    }

    pub fn tcpAcceptPollReadServiceResultWait(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult, accept_wait_ticks: u64, read_wait_ticks: u64, service_wait_ticks: u64) i32 {
        return self.base.tcpAcceptPollReadServiceResultWait(port, out, result, structured, accept_wait_ticks, read_wait_ticks, service_wait_ticks);
    }

    pub fn tcpAcceptPollReadService(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult) i32 {
        return self.base.tcpAcceptPollReadService(port, out, result);
    }

    pub fn tcpAcceptReadServiceResult(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult, structured: *abi.NetServiceTcpResult) i32 {
        return self.base.tcpAcceptReadServiceResult(port, out, result, structured);
    }

    pub fn tcpAcceptReadService(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult) i32 {
        return self.base.tcpAcceptReadService(port, out, result);
    }

    pub fn tcpBeginStatusService(self: *const Context, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginStatusService(request);
    }

    pub fn tcpBeginServiceResult(self: *const Context, op: u16, payload_in: []const u8, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginServiceResult(op, payload_in, request);
    }

    pub fn tcpBeginConnectService(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginConnectService(a, b, c, d, port, request);
    }

    pub fn tcpBeginWriteChunkService(self: *const Context, handle: u32, data: []const u8, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginWriteChunkService(handle, data, request);
    }

    pub fn tcpBeginReadService(self: *const Context, handle: u32, capacity: usize, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginReadService(handle, capacity, request);
    }

    pub fn tcpBeginPollService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginPollService(handle, request);
    }

    pub fn tcpBeginListenService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginListenService(port, request);
    }

    pub fn tcpBeginAcceptService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginAcceptService(port, request);
    }

    pub fn tcpBeginAcceptPollService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginAcceptPollService(port, request);
    }

    pub fn tcpBeginAcceptReadService(self: *const Context, port: u16, capacity: usize, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginAcceptReadService(port, capacity, request);
    }

    pub fn tcpBeginCloseService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginCloseService(handle, request);
    }

    pub fn tcpBeginAbortService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginAbortService(handle, request);
    }

    pub fn tcpBeginRetransmitService(self: *const Context, handle: u32, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginRetransmitService(handle, request);
    }

    pub fn tcpBeginCloseListenService(self: *const Context, port: u16, request: *NetSocketRequest) i32 {
        return self.base.tcpBeginCloseListenService(port, request);
    }

    pub fn tcpConnect(self: *const Context, a: u8, b: u8, c: u8, d: u8, port: u16) i32 {
        return self.base.tcpConnect(a, b, c, d, port);
    }

    pub fn tcpWrite(self: *const Context, conn_id: u32, data: []const u8) i32 {
        return self.base.tcpWrite(conn_id, data);
    }

    pub fn tcpRead(self: *const Context, conn_id: u32, out: []u8) i32 {
        return self.base.tcpRead(conn_id, out);
    }

    pub fn tcpClose(self: *const Context, conn_id: u32) i32 {
        return self.base.tcpClose(conn_id);
    }

    pub fn tcpSummary(self: *const Context, out: *abi.TcpSummary) i32 {
        return self.base.tcpSummary(out);
    }

    pub fn tcpPerformance(self: *const Context, out: *abi.TcpPerformanceInfo) i32 {
        return self.base.tcpPerformance(out);
    }

    pub fn tcpConnection(self: *const Context, index: u32, out: *abi.TcpConnectionInfo) i32 {
        return self.base.tcpConnection(index, out);
    }

    pub fn tcpEchoListenOnce(self: *const Context, port: u16, out: []u8) i32 {
        return self.base.tcpEchoListenOnce(port, out);
    }

    pub fn tcpAcceptReadOnce(self: *const Context, port: u16, out: []u8, result: *abi.TcpAcceptResult) i32 {
        return self.base.tcpAcceptReadOnce(port, out, result);
    }

    pub fn netIpv4Send(self: *const Context, a: u8, b: u8, c: u8, d: u8, protocol_id: u8, payload: []const u8) i32 {
        return self.base.netIpv4Send(a, b, c, d, protocol_id, payload);
    }

    pub fn netIpv4Recv(self: *const Context, protocol_id: u8, out: *abi.NetIpv4Packet, payload: []u8) i32 {
        return self.base.netIpv4Recv(protocol_id, out, payload);
    }

    pub fn udpBind(self: *const Context, port: u16) i32 {
        return self.base.udpBind(port);
    }

    pub fn udpSendTo(self: *const Context, handle: u32, dest_ip: [4]u8, dest_port: u16, payload: []const u8) i32 {
        return self.base.udpSendTo(handle, dest_ip, dest_port, payload);
    }

    pub fn udpRecvFrom(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload: []u8) i32 {
        return self.base.udpRecvFrom(handle, out, payload);
    }

    pub fn udpRecvFromWait(self: *const Context, handle: u32, out: *abi.UdpRecvInfo, payload: []u8, timeout_ticks: u64) i32 {
        return self.base.udpRecvFromWait(handle, out, payload, timeout_ticks);
    }

    pub fn udpClose(self: *const Context, handle: u32) i32 {
        return self.base.udpClose(handle);
    }

    pub fn udpStatus(self: *const Context, out: *abi.UdpStatus) i32 {
        return self.base.udpStatus(out);
    }

    pub fn netConfigGet(self: *const Context, out: *abi.NetConfigSnapshot) i32 {
        return self.base.netConfigGet(out);
    }

    pub fn netConfigSet(self: *const Context, request: *const abi.NetConfigRequest) i32 {
        return self.base.netConfigSet(request);
    }

    pub fn netDnsResolve(self: *const Context, name_value: []const u8, out: *[4]u8) i32 {
        return self.base.netDnsResolve(name_value, out);
    }

    pub fn netDnsResolveServer(self: *const Context, server: [4]u8, name_value: []const u8, out: *[4]u8) i32 {
        return self.base.netDnsResolveServer(server, name_value, out);
    }

    pub fn netDhcpAcquire(self: *const Context) i32 {
        return self.base.netDhcpAcquire();
    }

    pub fn netDhcpRenew(self: *const Context) i32 {
        return self.base.netDhcpRenew();
    }

    pub fn netDhcpRelease(self: *const Context) i32 {
        return self.base.netDhcpRelease();
    }

    pub fn netDhcpStatus(self: *const Context, out: *abi.DhcpStatus) i32 {
        return self.base.netDhcpStatus(out);
    }

    pub fn netDetailGet(self: *const Context, adapter_index: u32, out: *abi.NetDetailSnapshot) i32 {
        return self.base.netDetailGet(adapter_index, out);
    }

    pub fn netDiagRun(self: *const Context, op: u32, out: *abi.NetDiagResult) i32 {
        return self.base.netDiagRun(op, out);
    }

    pub fn netDnsResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netDnsResultName(result);
    }

    pub fn netDhcpResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netDhcpResultName(result);
    }

    pub fn netUdpResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netUdpResultName(result);
    }

    pub fn netTcpResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netTcpResultName(result);
    }

    pub fn netServiceResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netServiceResultName(result);
    }

    pub fn netServiceStatusName(self: *const Context, flags: u32) []const u8 {
        return self.base.netServiceStatusName(flags);
    }

    pub fn netServiceStatusCode(self: *const Context, flags: u32) u32 {
        return self.base.netServiceStatusCode(flags);
    }

    pub fn netServiceStatusCodeName(self: *const Context, code: u32) []const u8 {
        return self.base.netServiceStatusCodeName(code);
    }

    pub fn netServiceSemanticFlags(self: *const Context, flags: u32) u32 {
        return self.base.netServiceSemanticFlags(flags);
    }

    pub fn netConfigResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netConfigResultName(result);
    }

    pub fn netTxResultName(self: *const Context, result: i32) []const u8 {
        return self.base.netTxResultName(result);
    }
};

test "r4net exposes project and ABI metadata" {
    const std = @import("std");
    try std.testing.expectEqualStrings("R4NET", name);
    try std.testing.expectEqualStrings("R4NET:Query:1", import_query);
    try std.testing.expectEqual(@as(u32, 4), @intFromEnum(group));
    try std.testing.expectEqual(abi.r4l_abi_version, abi_version);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4net.h", c_header);
}
