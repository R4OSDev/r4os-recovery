const bridge = @import("net_bridge_support.zig");
const abi = bridge.abi;
// Init is for fresh, unsubmitted storage only. Active native workers retain
// pointers into this exact object until the owner accepts close.
pub export fn R4SdkNetRequestInit(value: *bridge.Request) callconv(.c) void { bridge.request(value).reset(); }
pub export fn R4SdkNetRequestReset(value: *bridge.Request) callconv(.c) i32 {
    if (bridge.request(value).active) return abi.io_error_busy;
    bridge.request(value).reset();
    return 0;
}
pub export fn R4SdkNetRequestActive(value: *const bridge.Request) callconv(.c) u32 { return @intFromBool(bridge.requestConst(value).active); }
pub export fn R4SdkNetRequestCompleted(value: *const bridge.Request) callconv(.c) u32 { return @intFromBool(bridge.requestConst(value).completed()); }
pub export fn R4SdkNetRequestInfo(value: *const bridge.Request, out: *abi.ProgramIoInfo) callconv(.c) void { out.* = bridge.requestConst(value).info; }
pub export fn R4SdkNetRequestHeader(value: *const bridge.Request, out: *abi.ServiceMessageHeader) callconv(.c) u32 {
    const request = bridge.requestConst(value);
    if (!request.completed()) return 0;
    out.* = request.header;
    return 1;
}
pub export fn R4SdkNetRequestResponse(value: *const bridge.Request) callconv(.c) bridge.Slice {
    const request = bridge.requestConst(value);
    return bridge.slice(if (request.completed()) request.responseSlice() else null);
}
pub export fn R4SdkNetRequestTcpStatus(value: *const bridge.Request, out: *abi.NetServiceTcpStatus) callconv(.c) u32 {
    const request = bridge.requestConst(value);
    return @intFromBool(request.completed() and request.tcpStatus(out));
}
pub export fn R4SdkNetRequestTcpResult(value: *const bridge.Request, out: *abi.NetServiceTcpResult) callconv(.c) u32 {
    const request = bridge.requestConst(value);
    return @intFromBool(request.completed() and request.tcpResult(out));
}
pub export fn R4SdkNetRequestTcpData(value: *const bridge.Request, result: *const abi.NetServiceTcpResult) callconv(.c) bridge.Slice {
    const request = bridge.requestConst(value);
    return bridge.slice(if (request.completed()) request.tcpData(result) else null);
}
pub export fn R4SdkNetRequestUdpStatus(value: *const bridge.Request, out: *abi.NetServiceUdpStatus) callconv(.c) u32 {
    const request = bridge.requestConst(value);
    return @intFromBool(request.completed() and request.udpStatus(out));
}
pub export fn R4SdkNetRequestUdpResult(value: *const bridge.Request, out: *abi.NetServiceUdpResult) callconv(.c) u32 {
    const request = bridge.requestConst(value);
    return @intFromBool(request.completed() and request.udpResult(out));
}
pub export fn R4SdkNetRequestUdpData(value: *const bridge.Request, result: *const abi.NetServiceUdpResult) callconv(.c) bridge.Slice {
    const request = bridge.requestConst(value);
    return bridge.slice(if (request.completed()) request.udpData(result) else null);
}
