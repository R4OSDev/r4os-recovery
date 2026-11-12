// Generated from compiler-typed r4net.Context; do not edit.
use crate::{abi, c_facades as c};
use crate::network::{Network, SocketService, ResolverOptions, ResolverResult, TcpReadiness, RawRequest};
#[allow(clippy::needless_lifetimes, clippy::let_and_return, clippy::too_many_arguments)]
impl Network<'_> {
    pub fn ipc_open<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcOpen(self.context, p0) } else { c::R4SdkNet2_ipcOpen(self.context2, p0) } };
        value
    }
    pub fn ipc_send<'b>(&'b self, p0: u32, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcSend(self.context, p0, p1.as_ptr(), p1.len() as u32) } else { c::R4SdkNet2_ipcSend(self.context2, p0, p1.as_ptr(), p1.len() as u32) } };
        value
    }
    pub fn ipc_recv<'b>(&'b self, p0: u32, p1: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcRecv(self.context, p0, p1.as_mut_ptr(), p1.len() as u32) } else { c::R4SdkNet2_ipcRecv(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32) } };
        value
    }
    pub fn ipc_poll<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcPoll(self.context, p0) } else { c::R4SdkNet2_ipcPoll(self.context2, p0) } };
        value
    }
    pub fn ipc_close<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcClose(self.context, p0) } else { c::R4SdkNet2_ipcClose(self.context2, p0) } };
        value
    }
    pub fn ipc_summary<'b>(&'b self, p0: &'b mut abi::IpcSummary) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcSummary(self.context, p0) } else { c::R4SdkNet2_ipcSummary(self.context2, p0) } };
        value
    }
    pub fn ipc_channel<'b>(&'b self, p0: u32, p1: &'b mut abi::IpcChannelInfo) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcChannel(self.context, p0, p1) } else { c::R4SdkNet2_ipcChannel(self.context2, p0, p1) } };
        value
    }
    pub fn ipc_performance<'b>(&'b self, p0: u32, p1: &'b mut abi::IpcPerformanceSummary) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_ipcPerformance(self.context, p0, p1) } else { c::R4SdkNet2_ipcPerformance(self.context2, p0, p1) } };
        value
    }
    pub fn net_service_request<'b>(&'b self, p0: u32, p1: u16, p2: u32, p3: &'b [u8], p4: &'b mut [u8]) -> i32 {
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        if p4.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceRequest(self.context, p0, p1, p2, p3.as_ptr(), p3.len() as u32, p4.as_mut_ptr(), p4.len() as u32) } else { c::R4SdkNet2_netServiceRequest(self.context2, p0, p1, p2, p3.as_ptr(), p3.len() as u32, p4.as_mut_ptr(), p4.len() as u32) } };
        value
    }
    pub fn net_service_client_id<'b>(&'b self) -> u16 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceClientId(self.context) } else { c::R4SdkNet2_netServiceClientId(self.context2) } };
        value
    }
    pub fn net_service_payload<'b>(&'b self, p0: &'b [u8], p1: &'b mut i32) -> Option<&'b [u8]> {
        if p0.len() > u32::MAX as usize { return None; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServicePayload(self.context, p0.as_ptr(), p0.len() as u32, p1) } else { c::R4SdkNet2_netServicePayload(self.context2, p0.as_ptr(), p0.len() as u32, p1) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_socket_lifecycle_name<'b>(&'b self, p0: u32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netSocketLifecycleName(self.context, p0) } else { c::R4SdkNet2_netSocketLifecycleName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn net_socket_begin<'b>(&'b self, p0: SocketService, p1: u16, p2: &'b [u8], p3: u64, p4: &'b mut RawRequest) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netSocketBegin(self.context, p0 as u8, p1, p2.as_ptr(), p2.len() as u32, p3, p4) } else { c::R4SdkNet2_netSocketBegin(self.context2, p0 as u8, p1, p2.as_ptr(), p2.len() as u32, p3, p4) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn net_socket_status<'b>(&'b self, p0: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netSocketStatus(self.context, p0) } else { c::R4SdkNet2_netSocketStatus(self.context2, p0) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn net_socket_wait<'b>(&'b self, p0: &'b mut RawRequest, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netSocketWait(self.context, p0, p1) } else { c::R4SdkNet2_netSocketWait(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn net_socket_close<'b>(&'b self, p0: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netSocketClose(self.context, p0) } else { c::R4SdkNet2_netSocketClose(self.context2, p0) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn net_socket_wait_and_close<'b>(&'b self, p0: &'b mut RawRequest, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netSocketWaitAndClose(self.context, p0, p1) } else { c::R4SdkNet2_netSocketWaitAndClose(self.context2, p0, p1) } };
        value
    }
    pub fn net_resolve_a<'b>(&'b self, p0: &'b [u8], p1: ResolverOptions, p2: &'b mut ResolverResult) -> i32 {
        if p0.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netResolveA(self.context, p0.as_ptr(), p0.len() as u32, p1, p2) } else { c::R4SdkNet2_netResolveA(self.context2, p0.as_ptr(), p0.len() as u32, p1, p2) } };
        value
    }
    pub fn net_dns_resolve_service<'b>(&'b self, p0: &'b [u8], p1: &'b mut [u8; 4]) -> i32 {
        if p0.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResolveService(self.context, p0.as_ptr(), p0.len() as u32, p1.as_mut_ptr()) } else { c::R4SdkNet2_netDnsResolveService(self.context2, p0.as_ptr(), p0.len() as u32, p1.as_mut_ptr()) } };
        value
    }
    pub fn net_dns_resolve_server_service<'b>(&'b self, p0: [u8; 4], p1: &'b [u8], p2: &'b mut [u8; 4]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResolveServerService(self.context, p0.as_ptr(), p1.as_ptr(), p1.len() as u32, p2.as_mut_ptr()) } else { c::R4SdkNet2_netDnsResolveServerService(self.context2, p0.as_ptr(), p1.as_ptr(), p1.len() as u32, p2.as_mut_ptr()) } };
        value
    }
    pub fn net_dns_resolve_service_result<'b>(&'b self, p0: &'b [u8], p1: &'b mut abi::NetServiceDnsResult) -> i32 {
        if p0.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResolveServiceResult(self.context, p0.as_ptr(), p0.len() as u32, p1) } else { c::R4SdkNet2_netDnsResolveServiceResult(self.context2, p0.as_ptr(), p0.len() as u32, p1) } };
        value
    }
    pub fn net_dns_resolve_server_service_result<'b>(&'b self, p0: [u8; 4], p1: &'b [u8], p2: &'b mut abi::NetServiceDnsResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResolveServerServiceResult(self.context, p0.as_ptr(), p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_netDnsResolveServerServiceResult(self.context2, p0.as_ptr(), p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn net_dns_service_status_raw<'b>(&'b self, p0: &'b mut abi::NetServiceDnsStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsServiceStatusRaw(self.context, p0) } else { c::R4SdkNet2_netDnsServiceStatusRaw(self.context2, p0) } };
        value
    }
    pub fn net_dhcp_acquire_service<'b>(&'b self) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpAcquireService(self.context) } else { c::R4SdkNet2_netDhcpAcquireService(self.context2) } };
        value
    }
    pub fn net_dhcp_renew_service<'b>(&'b self) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpRenewService(self.context) } else { c::R4SdkNet2_netDhcpRenewService(self.context2) } };
        value
    }
    pub fn net_dhcp_release_service<'b>(&'b self) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpReleaseService(self.context) } else { c::R4SdkNet2_netDhcpReleaseService(self.context2) } };
        value
    }
    pub fn net_dhcp_service_status<'b>(&'b self, p0: &'b mut abi::DhcpStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpServiceStatus(self.context, p0) } else { c::R4SdkNet2_netDhcpServiceStatus(self.context2, p0) } };
        value
    }
    pub fn net_dhcp_service_status_raw<'b>(&'b self, p0: &'b mut abi::NetServiceDhcpStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpServiceStatusRaw(self.context, p0) } else { c::R4SdkNet2_netDhcpServiceStatusRaw(self.context2, p0) } };
        value
    }
    pub fn net_dhcp_service_action<'b>(&'b self, p0: u16, p1: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpServiceAction(self.context, p0, p1) } else { c::R4SdkNet2_netDhcpServiceAction(self.context2, p0, p1) } };
        value
    }
    pub fn net_dhcp_service_action_result<'b>(&'b self, p0: u16, p1: &'b mut abi::NetServiceDhcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpServiceActionResult(self.context, p0, p1) } else { c::R4SdkNet2_netDhcpServiceActionResult(self.context2, p0, p1) } };
        value
    }
    pub fn udp_service_status_raw<'b>(&'b self, p0: &'b mut abi::NetServiceUdpStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpServiceStatusRaw(self.context, p0) } else { c::R4SdkNet2_udpServiceStatusRaw(self.context2, p0) } };
        value
    }
    pub fn udp_service_result<'b>(&'b self, p0: u16, p1: &'b [u8], p2: &'b mut abi::NetServiceUdpResult, p3: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpServiceResult(self.context, p0, p1.as_ptr(), p1.len() as u32, p2, p3.as_mut_ptr(), p3.len() as u32) } else { c::R4SdkNet2_udpServiceResult(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2, p3.as_mut_ptr(), p3.len() as u32) } };
        value
    }
    pub fn udp_bind_service<'b>(&'b self, p0: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBindService(self.context, p0) } else { c::R4SdkNet2_udpBindService(self.context2, p0) } };
        value
    }
    pub fn udp_send_to_service<'b>(&'b self, p0: u32, p1: [u8; 4], p2: u16, p3: &'b [u8]) -> i32 {
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpSendToService(self.context, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32) } else { c::R4SdkNet2_udpSendToService(self.context2, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32) } };
        value
    }
    pub fn udp_recv_from_service<'b>(&'b self, p0: u32, p1: &'b mut abi::UdpRecvInfo, p2: &'b mut [u8]) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpRecvFromService(self.context, p0, p1, p2.as_mut_ptr(), p2.len() as u32) } else { c::R4SdkNet2_udpRecvFromService(self.context2, p0, p1, p2.as_mut_ptr(), p2.len() as u32) } };
        value
    }
    pub fn udp_recv_from_service_result<'b>(&'b self, p0: u32, p1: &'b mut abi::UdpRecvInfo, p2: &'b mut [u8], p3: &'b mut abi::NetServiceUdpResult) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpRecvFromServiceResult(self.context, p0, p1, p2.as_mut_ptr(), p2.len() as u32, p3) } else { c::R4SdkNet2_udpRecvFromServiceResult(self.context2, p0, p1, p2.as_mut_ptr(), p2.len() as u32, p3) } };
        value
    }
    pub fn udp_recv_from_wait_service<'b>(&'b self, p0: u32, p1: &'b mut abi::UdpRecvInfo, p2: &'b mut [u8], p3: u64) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpRecvFromWaitService(self.context, p0, p1, p2.as_mut_ptr(), p2.len() as u32, p3) } else { c::R4SdkNet2_udpRecvFromWaitService(self.context2, p0, p1, p2.as_mut_ptr(), p2.len() as u32, p3) } };
        value
    }
    pub fn udp_close_service<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpCloseService(self.context, p0) } else { c::R4SdkNet2_udpCloseService(self.context2, p0) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn udp_begin_status_service<'b>(&'b self, p0: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBeginStatusService(self.context, p0) } else { c::R4SdkNet2_udpBeginStatusService(self.context2, p0) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn udp_begin_service_result<'b>(&'b self, p0: u16, p1: &'b [u8], p2: &'b mut RawRequest) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBeginServiceResult(self.context, p0, p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_udpBeginServiceResult(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn udp_begin_bind_service<'b>(&'b self, p0: u16, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBeginBindService(self.context, p0, p1) } else { c::R4SdkNet2_udpBeginBindService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn udp_begin_send_to_service<'b>(&'b self, p0: u32, p1: [u8; 4], p2: u16, p3: &'b [u8], p4: &'b mut RawRequest) -> i32 {
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBeginSendToService(self.context, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32, p4) } else { c::R4SdkNet2_udpBeginSendToService(self.context2, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32, p4) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn udp_begin_recv_from_service<'b>(&'b self, p0: u32, p1: usize, p2: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBeginRecvFromService(self.context, p0, p1 as u64, p2) } else { c::R4SdkNet2_udpBeginRecvFromService(self.context2, p0, p1 as u64, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn udp_begin_close_service<'b>(&'b self, p0: u32, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBeginCloseService(self.context, p0, p1) } else { c::R4SdkNet2_udpBeginCloseService(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_service_status_raw<'b>(&'b self, p0: &'b mut abi::NetServiceTcpStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpServiceStatusRaw(self.context, p0) } else { c::R4SdkNet2_tcpServiceStatusRaw(self.context2, p0) } };
        value
    }
    pub fn tcp_service_status_raw_wait<'b>(&'b self, p0: &'b mut abi::NetServiceTcpStatus, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpServiceStatusRawWait(self.context, p0, p1) } else { c::R4SdkNet2_tcpServiceStatusRawWait(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_service_result<'b>(&'b self, p0: u16, p1: &'b [u8], p2: &'b mut abi::NetServiceTcpResult, p3: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpServiceResult(self.context, p0, p1.as_ptr(), p1.len() as u32, p2, p3.as_mut_ptr(), p3.len() as u32) } else { c::R4SdkNet2_tcpServiceResult(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2, p3.as_mut_ptr(), p3.len() as u32) } };
        value
    }
    pub fn tcp_service_result_wait<'b>(&'b self, p0: u16, p1: &'b [u8], p2: &'b mut abi::NetServiceTcpResult, p3: &'b mut [u8], p4: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpServiceResultWait(self.context, p0, p1.as_ptr(), p1.len() as u32, p2, p3.as_mut_ptr(), p3.len() as u32, p4) } else { c::R4SdkNet2_tcpServiceResultWait(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2, p3.as_mut_ptr(), p3.len() as u32, p4) } };
        value
    }
    pub fn tcp_connect_service_result<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpConnectServiceResult(self.context, p0, p1, p2, p3, p4, p5) } else { c::R4SdkNet2_tcpConnectServiceResult(self.context2, p0, p1, p2, p3, p4, p5) } };
        value
    }
    pub fn tcp_connect_service_result_wait<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: &'b mut abi::NetServiceTcpResult, p6: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpConnectServiceResultWait(self.context, p0, p1, p2, p3, p4, p5, p6) } else { c::R4SdkNet2_tcpConnectServiceResultWait(self.context2, p0, p1, p2, p3, p4, p5, p6) } };
        value
    }
    pub fn tcp_connect_service<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpConnectService(self.context, p0, p1, p2, p3, p4) } else { c::R4SdkNet2_tcpConnectService(self.context2, p0, p1, p2, p3, p4) } };
        value
    }
    pub fn tcp_connect_service_wait<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpConnectServiceWait(self.context, p0, p1, p2, p3, p4, p5) } else { c::R4SdkNet2_tcpConnectServiceWait(self.context2, p0, p1, p2, p3, p4, p5) } };
        value
    }
    pub fn tcp_write_chunk_service_result<'b>(&'b self, p0: u32, p1: &'b [u8], p2: &'b mut abi::NetServiceTcpResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWriteChunkServiceResult(self.context, p0, p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpWriteChunkServiceResult(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_write_chunk_service_result_wait<'b>(&'b self, p0: u32, p1: &'b [u8], p2: &'b mut abi::NetServiceTcpResult, p3: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWriteChunkServiceResultWait(self.context, p0, p1.as_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpWriteChunkServiceResultWait(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_write_paced_service<'b>(&'b self, p0: u32, p1: &'b [u8], p2: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWritePacedService(self.context, p0, p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpWritePacedService(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_write_paced_service_bounded<'b>(&'b self, p0: u32, p1: &'b [u8], p2: u64, p3: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWritePacedServiceBounded(self.context, p0, p1.as_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpWritePacedServiceBounded(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_wait_for_tx_window_service<'b>(&'b self, p0: u32, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWaitForTxWindowService(self.context, p0, p1) } else { c::R4SdkNet2_tcpWaitForTxWindowService(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_wait_for_tx_window_service_bounded<'b>(&'b self, p0: u32, p1: u64, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWaitForTxWindowServiceBounded(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpWaitForTxWindowServiceBounded(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_write_chunk_service<'b>(&'b self, p0: u32, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWriteChunkService(self.context, p0, p1.as_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpWriteChunkService(self.context2, p0, p1.as_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_write_chunk_service_wait<'b>(&'b self, p0: u32, p1: &'b [u8], p2: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWriteChunkServiceWait(self.context, p0, p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpWriteChunkServiceWait(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_write_service<'b>(&'b self, p0: u32, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWriteService(self.context, p0, p1.as_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpWriteService(self.context2, p0, p1.as_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_read_service_result<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: &'b mut abi::NetServiceTcpResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadServiceResult(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpReadServiceResult(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_read_service_result_wait<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: &'b mut abi::NetServiceTcpResult, p3: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadServiceResultWait(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpReadServiceResultWait(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_read_service<'b>(&'b self, p0: u32, p1: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadService(self.context, p0, p1.as_mut_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpReadService(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_read_service_wait<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadServiceWait(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpReadServiceWait(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_read_available_service<'b>(&'b self, p0: u32, p1: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadAvailableService(self.context, p0, p1.as_mut_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpReadAvailableService(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_read_wait_service<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadWaitService(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpReadWaitService(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_read_wait_service_bounded<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: u64, p3: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadWaitServiceBounded(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpReadWaitServiceBounded(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_read_wait_service_consume_safe<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: u64, p3: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadWaitServiceConsumeSafe(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpReadWaitServiceConsumeSafe(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_read_available_wait_service<'b>(&'b self, p0: u32, p1: &'b mut [u8], p2: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadAvailableWaitService(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpReadAvailableWaitService(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_listen_service_result<'b>(&'b self, p0: u16, p1: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpListenServiceResult(self.context, p0, p1) } else { c::R4SdkNet2_tcpListenServiceResult(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_listen_service_result_wait<'b>(&'b self, p0: u16, p1: &'b mut abi::NetServiceTcpResult, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpListenServiceResultWait(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpListenServiceResultWait(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_listen_service<'b>(&'b self, p0: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpListenService(self.context, p0) } else { c::R4SdkNet2_tcpListenService(self.context2, p0) } };
        value
    }
    pub fn tcp_poll_service<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpPollService(self.context, p0, p1) } else { c::R4SdkNet2_tcpPollService(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_poll_service_wait<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpPollServiceWait(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpPollServiceWait(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_readiness_from_result<'b>(&'b self, p0: &'b abi::NetServiceTcpResult) -> TcpReadiness {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadinessFromResult(self.context, p0) } else { c::R4SdkNet2_tcpReadinessFromResult(self.context2, p0) } };
        value
    }
    pub fn tcp_readiness_readable<'b>(&'b self, p0: &'b abi::NetServiceTcpResult) -> bool {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadinessReadable(self.context, p0) } else { c::R4SdkNet2_tcpReadinessReadable(self.context2, p0) } };
        value != 0
    }
    pub fn tcp_readiness_writable<'b>(&'b self, p0: &'b abi::NetServiceTcpResult) -> bool {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadinessWritable(self.context, p0) } else { c::R4SdkNet2_tcpReadinessWritable(self.context2, p0) } };
        value != 0
    }
    pub fn tcp_readiness_terminal<'b>(&'b self, p0: &'b abi::NetServiceTcpResult) -> bool {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpReadinessTerminal(self.context, p0) } else { c::R4SdkNet2_tcpReadinessTerminal(self.context2, p0) } };
        value != 0
    }
    pub fn tcp_accept_service_result<'b>(&'b self, p0: u16, p1: &'b mut abi::TcpAcceptResult, p2: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptServiceResult(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpAcceptServiceResult(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_accept_poll_service_result<'b>(&'b self, p0: u16, p1: &'b mut abi::TcpAcceptResult, p2: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptPollServiceResult(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpAcceptPollServiceResult(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_accept_poll_service_result_wait<'b>(&'b self, p0: u16, p1: &'b mut abi::TcpAcceptResult, p2: &'b mut abi::NetServiceTcpResult, p3: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptPollServiceResultWait(self.context, p0, p1, p2, p3) } else { c::R4SdkNet2_tcpAcceptPollServiceResultWait(self.context2, p0, p1, p2, p3) } };
        value
    }
    pub fn tcp_accept_wait_service_result<'b>(&'b self, p0: u16, p1: &'b mut abi::TcpAcceptResult, p2: &'b mut abi::NetServiceTcpResult, p3: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptWaitServiceResult(self.context, p0, p1, p2, p3) } else { c::R4SdkNet2_tcpAcceptWaitServiceResult(self.context2, p0, p1, p2, p3) } };
        value
    }
    pub fn tcp_accept_wait_service_result_wait<'b>(&'b self, p0: u16, p1: &'b mut abi::TcpAcceptResult, p2: &'b mut abi::NetServiceTcpResult, p3: u64, p4: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptWaitServiceResultWait(self.context, p0, p1, p2, p3, p4) } else { c::R4SdkNet2_tcpAcceptWaitServiceResultWait(self.context2, p0, p1, p2, p3, p4) } };
        value
    }
    pub fn tcp_accept_service<'b>(&'b self, p0: u16, p1: &'b mut abi::TcpAcceptResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptService(self.context, p0, p1) } else { c::R4SdkNet2_tcpAcceptService(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_close_service_result<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseServiceResult(self.context, p0, p1) } else { c::R4SdkNet2_tcpCloseServiceResult(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_close_service_result_wait<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseServiceResultWait(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpCloseServiceResultWait(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_abort_service_result<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAbortServiceResult(self.context, p0, p1) } else { c::R4SdkNet2_tcpAbortServiceResult(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_abort_service_result_wait<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAbortServiceResultWait(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpAbortServiceResultWait(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_abort_service<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAbortService(self.context, p0) } else { c::R4SdkNet2_tcpAbortService(self.context2, p0) } };
        value
    }
    pub fn tcp_abort_service_wait<'b>(&'b self, p0: u32, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAbortServiceWait(self.context, p0, p1) } else { c::R4SdkNet2_tcpAbortServiceWait(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_retransmit_service_result<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpRetransmitServiceResult(self.context, p0, p1) } else { c::R4SdkNet2_tcpRetransmitServiceResult(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_retransmit_service_result_wait<'b>(&'b self, p0: u32, p1: &'b mut abi::NetServiceTcpResult, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpRetransmitServiceResultWait(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpRetransmitServiceResultWait(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_retransmit_service<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpRetransmitService(self.context, p0) } else { c::R4SdkNet2_tcpRetransmitService(self.context2, p0) } };
        value
    }
    pub fn tcp_close_service<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseService(self.context, p0) } else { c::R4SdkNet2_tcpCloseService(self.context2, p0) } };
        value
    }
    pub fn tcp_close_service_wait<'b>(&'b self, p0: u32, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseServiceWait(self.context, p0, p1) } else { c::R4SdkNet2_tcpCloseServiceWait(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_close_listen_service_result<'b>(&'b self, p0: u16, p1: &'b mut abi::NetServiceTcpResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseListenServiceResult(self.context, p0, p1) } else { c::R4SdkNet2_tcpCloseListenServiceResult(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_close_listen_service_result_wait<'b>(&'b self, p0: u16, p1: &'b mut abi::NetServiceTcpResult, p2: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseListenServiceResultWait(self.context, p0, p1, p2) } else { c::R4SdkNet2_tcpCloseListenServiceResultWait(self.context2, p0, p1, p2) } };
        value
    }
    pub fn tcp_close_listen_service<'b>(&'b self, p0: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseListenService(self.context, p0) } else { c::R4SdkNet2_tcpCloseListenService(self.context2, p0) } };
        value
    }
    pub fn tcp_close_listen_service_wait<'b>(&'b self, p0: u16, p1: u64) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpCloseListenServiceWait(self.context, p0, p1) } else { c::R4SdkNet2_tcpCloseListenServiceWait(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_accept_poll_read_service_result<'b>(&'b self, p0: u16, p1: &'b mut [u8], p2: &'b mut abi::TcpAcceptResult, p3: &'b mut abi::NetServiceTcpResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptPollReadServiceResult(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpAcceptPollReadServiceResult(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_accept_poll_read_service_result_wait<'b>(&'b self, p0: u16, p1: &'b mut [u8], p2: &'b mut abi::TcpAcceptResult, p3: &'b mut abi::NetServiceTcpResult, p4: u64, p5: u64, p6: u64) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptPollReadServiceResultWait(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3, p4, p5, p6) } else { c::R4SdkNet2_tcpAcceptPollReadServiceResultWait(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3, p4, p5, p6) } };
        value
    }
    pub fn tcp_accept_poll_read_service<'b>(&'b self, p0: u16, p1: &'b mut [u8], p2: &'b mut abi::TcpAcceptResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptPollReadService(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpAcceptPollReadService(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn tcp_accept_read_service_result<'b>(&'b self, p0: u16, p1: &'b mut [u8], p2: &'b mut abi::TcpAcceptResult, p3: &'b mut abi::NetServiceTcpResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptReadServiceResult(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } else { c::R4SdkNet2_tcpAcceptReadServiceResult(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2, p3) } };
        value
    }
    pub fn tcp_accept_read_service<'b>(&'b self, p0: u16, p1: &'b mut [u8], p2: &'b mut abi::TcpAcceptResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptReadService(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpAcceptReadService(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_status_service<'b>(&'b self, p0: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginStatusService(self.context, p0) } else { c::R4SdkNet2_tcpBeginStatusService(self.context2, p0) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_service_result<'b>(&'b self, p0: u16, p1: &'b [u8], p2: &'b mut RawRequest) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginServiceResult(self.context, p0, p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpBeginServiceResult(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_connect_service<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16, p5: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginConnectService(self.context, p0, p1, p2, p3, p4, p5) } else { c::R4SdkNet2_tcpBeginConnectService(self.context2, p0, p1, p2, p3, p4, p5) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_write_chunk_service<'b>(&'b self, p0: u32, p1: &'b [u8], p2: &'b mut RawRequest) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginWriteChunkService(self.context, p0, p1.as_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpBeginWriteChunkService(self.context2, p0, p1.as_ptr(), p1.len() as u32, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_read_service<'b>(&'b self, p0: u32, p1: usize, p2: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginReadService(self.context, p0, p1 as u64, p2) } else { c::R4SdkNet2_tcpBeginReadService(self.context2, p0, p1 as u64, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_poll_service<'b>(&'b self, p0: u32, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginPollService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginPollService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_listen_service<'b>(&'b self, p0: u16, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginListenService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginListenService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_accept_service<'b>(&'b self, p0: u16, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginAcceptService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginAcceptService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_accept_poll_service<'b>(&'b self, p0: u16, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginAcceptPollService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginAcceptPollService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_accept_read_service<'b>(&'b self, p0: u16, p1: usize, p2: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginAcceptReadService(self.context, p0, p1 as u64, p2) } else { c::R4SdkNet2_tcpBeginAcceptReadService(self.context2, p0, p1 as u64, p2) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_close_service<'b>(&'b self, p0: u32, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginCloseService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginCloseService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_abort_service<'b>(&'b self, p0: u32, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginAbortService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginAbortService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_retransmit_service<'b>(&'b self, p0: u32, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginRetransmitService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginRetransmitService(self.context2, p0, p1) } };
        value
    }
    /// # Safety
    /// Keep this exact initialized request at a stable address, including
    /// its buffers, until native close succeeds. Forgetting it cannot cancel
    /// native work. Use OwnedRequest for safe owned admission.
    pub unsafe fn tcp_begin_close_listen_service<'b>(&'b self, p0: u16, p1: &'b mut RawRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpBeginCloseListenService(self.context, p0, p1) } else { c::R4SdkNet2_tcpBeginCloseListenService(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_connect<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpConnect(self.context, p0, p1, p2, p3, p4) } else { c::R4SdkNet2_tcpConnect(self.context2, p0, p1, p2, p3, p4) } };
        value
    }
    pub fn tcp_write<'b>(&'b self, p0: u32, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpWrite(self.context, p0, p1.as_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpWrite(self.context2, p0, p1.as_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_read<'b>(&'b self, p0: u32, p1: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpRead(self.context, p0, p1.as_mut_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpRead(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_close<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpClose(self.context, p0) } else { c::R4SdkNet2_tcpClose(self.context2, p0) } };
        value
    }
    pub fn tcp_summary<'b>(&'b self, p0: &'b mut abi::TcpSummary) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpSummary(self.context, p0) } else { c::R4SdkNet2_tcpSummary(self.context2, p0) } };
        value
    }
    pub fn tcp_performance<'b>(&'b self, p0: &'b mut abi::TcpPerformanceInfo) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpPerformance(self.context, p0) } else { c::R4SdkNet2_tcpPerformance(self.context2, p0) } };
        value
    }
    pub fn tcp_connection<'b>(&'b self, p0: u32, p1: &'b mut abi::TcpConnectionInfo) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpConnection(self.context, p0, p1) } else { c::R4SdkNet2_tcpConnection(self.context2, p0, p1) } };
        value
    }
    pub fn tcp_echo_listen_once<'b>(&'b self, p0: u16, p1: &'b mut [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpEchoListenOnce(self.context, p0, p1.as_mut_ptr(), p1.len() as u32) } else { c::R4SdkNet2_tcpEchoListenOnce(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32) } };
        value
    }
    pub fn tcp_accept_read_once<'b>(&'b self, p0: u16, p1: &'b mut [u8], p2: &'b mut abi::TcpAcceptResult) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_tcpAcceptReadOnce(self.context, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } else { c::R4SdkNet2_tcpAcceptReadOnce(self.context2, p0, p1.as_mut_ptr(), p1.len() as u32, p2) } };
        value
    }
    pub fn net_ipv4_send<'b>(&'b self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u8, p5: &'b [u8]) -> i32 {
        if p5.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netIpv4Send(self.context, p0, p1, p2, p3, p4, p5.as_ptr(), p5.len() as u32) } else { c::R4SdkNet2_netIpv4Send(self.context2, p0, p1, p2, p3, p4, p5.as_ptr(), p5.len() as u32) } };
        value
    }
    pub fn net_ipv4_recv<'b>(&'b self, p0: u8, p1: &'b mut abi::NetIpv4Packet, p2: &'b mut [u8]) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netIpv4Recv(self.context, p0, p1, p2.as_mut_ptr(), p2.len() as u32) } else { c::R4SdkNet2_netIpv4Recv(self.context2, p0, p1, p2.as_mut_ptr(), p2.len() as u32) } };
        value
    }
    pub fn udp_bind<'b>(&'b self, p0: u16) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpBind(self.context, p0) } else { c::R4SdkNet2_udpBind(self.context2, p0) } };
        value
    }
    pub fn udp_send_to<'b>(&'b self, p0: u32, p1: [u8; 4], p2: u16, p3: &'b [u8]) -> i32 {
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpSendTo(self.context, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32) } else { c::R4SdkNet2_udpSendTo(self.context2, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32) } };
        value
    }
    pub fn udp_recv_from<'b>(&'b self, p0: u32, p1: &'b mut abi::UdpRecvInfo, p2: &'b mut [u8]) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpRecvFrom(self.context, p0, p1, p2.as_mut_ptr(), p2.len() as u32) } else { c::R4SdkNet2_udpRecvFrom(self.context2, p0, p1, p2.as_mut_ptr(), p2.len() as u32) } };
        value
    }
    pub fn udp_recv_from_wait<'b>(&'b self, p0: u32, p1: &'b mut abi::UdpRecvInfo, p2: &'b mut [u8], p3: u64) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpRecvFromWait(self.context, p0, p1, p2.as_mut_ptr(), p2.len() as u32, p3) } else { c::R4SdkNet2_udpRecvFromWait(self.context2, p0, p1, p2.as_mut_ptr(), p2.len() as u32, p3) } };
        value
    }
    pub fn udp_close<'b>(&'b self, p0: u32) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpClose(self.context, p0) } else { c::R4SdkNet2_udpClose(self.context2, p0) } };
        value
    }
    pub fn udp_status<'b>(&'b self, p0: &'b mut abi::UdpStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_udpStatus(self.context, p0) } else { c::R4SdkNet2_udpStatus(self.context2, p0) } };
        value
    }
    pub fn net_config_get<'b>(&'b self, p0: &'b mut abi::NetConfigSnapshot) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netConfigGet(self.context, p0) } else { c::R4SdkNet2_netConfigGet(self.context2, p0) } };
        value
    }
    pub fn net_config_set<'b>(&'b self, p0: &'b abi::NetConfigRequest) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netConfigSet(self.context, p0) } else { c::R4SdkNet2_netConfigSet(self.context2, p0) } };
        value
    }
    pub fn net_dns_resolve<'b>(&'b self, p0: &'b [u8], p1: &'b mut [u8; 4]) -> i32 {
        if p0.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResolve(self.context, p0.as_ptr(), p0.len() as u32, p1.as_mut_ptr()) } else { c::R4SdkNet2_netDnsResolve(self.context2, p0.as_ptr(), p0.len() as u32, p1.as_mut_ptr()) } };
        value
    }
    pub fn net_dns_resolve_server<'b>(&'b self, p0: [u8; 4], p1: &'b [u8], p2: &'b mut [u8; 4]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResolveServer(self.context, p0.as_ptr(), p1.as_ptr(), p1.len() as u32, p2.as_mut_ptr()) } else { c::R4SdkNet2_netDnsResolveServer(self.context2, p0.as_ptr(), p1.as_ptr(), p1.len() as u32, p2.as_mut_ptr()) } };
        value
    }
    pub fn net_dhcp_acquire<'b>(&'b self) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpAcquire(self.context) } else { c::R4SdkNet2_netDhcpAcquire(self.context2) } };
        value
    }
    pub fn net_dhcp_renew<'b>(&'b self) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpRenew(self.context) } else { c::R4SdkNet2_netDhcpRenew(self.context2) } };
        value
    }
    pub fn net_dhcp_release<'b>(&'b self) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpRelease(self.context) } else { c::R4SdkNet2_netDhcpRelease(self.context2) } };
        value
    }
    pub fn net_dhcp_status<'b>(&'b self, p0: &'b mut abi::DhcpStatus) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpStatus(self.context, p0) } else { c::R4SdkNet2_netDhcpStatus(self.context2, p0) } };
        value
    }
    pub fn net_detail_get<'b>(&'b self, p0: u32, p1: &'b mut abi::NetDetailSnapshot) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDetailGet(self.context, p0, p1) } else { c::R4SdkNet2_netDetailGet(self.context2, p0, p1) } };
        value
    }
    pub fn net_diag_run<'b>(&'b self, p0: u32, p1: &'b mut abi::NetDiagResult) -> i32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDiagRun(self.context, p0, p1) } else { c::R4SdkNet2_netDiagRun(self.context2, p0, p1) } };
        value
    }
    pub fn net_dns_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDnsResultName(self.context, p0) } else { c::R4SdkNet2_netDnsResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_dhcp_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netDhcpResultName(self.context, p0) } else { c::R4SdkNet2_netDhcpResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_udp_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netUdpResultName(self.context, p0) } else { c::R4SdkNet2_netUdpResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_tcp_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netTcpResultName(self.context, p0) } else { c::R4SdkNet2_netTcpResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_service_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceResultName(self.context, p0) } else { c::R4SdkNet2_netServiceResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_service_status_name<'b>(&'b self, p0: u32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceStatusName(self.context, p0) } else { c::R4SdkNet2_netServiceStatusName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_service_status_code<'b>(&'b self, p0: u32) -> u32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceStatusCode(self.context, p0) } else { c::R4SdkNet2_netServiceStatusCode(self.context2, p0) } };
        value
    }
    pub fn net_service_status_code_name<'b>(&'b self, p0: u32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceStatusCodeName(self.context, p0) } else { c::R4SdkNet2_netServiceStatusCodeName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_service_semantic_flags<'b>(&'b self, p0: u32) -> u32 {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netServiceSemanticFlags(self.context, p0) } else { c::R4SdkNet2_netServiceSemanticFlags(self.context2, p0) } };
        value
    }
    pub fn net_config_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netConfigResultName(self.context, p0) } else { c::R4SdkNet2_netConfigResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
    pub fn net_tx_result_name<'b>(&'b self, p0: i32) -> Option<&'b [u8]> {
        let value = unsafe { if self.context2.is_null() { c::R4SdkNet_netTxResultName(self.context, p0) } else { c::R4SdkNet2_netTxResultName(self.context2, p0) } };
        // Owner returns only a view of the input or resident label storage.
        unsafe { crate::network::view(value) }
    }
}
#[cfg(feature = "alloc")]
#[allow(clippy::needless_lifetimes)]
impl crate::network::OwnedRequest<'_> {
    pub fn net_socket_begin<'b>(&'b mut self, p0: SocketService, p1: u16, p2: &'b [u8], p3: u64) -> i32 {
        if p2.len() > u32::MAX as usize { return abi::io_error_invalid; }
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_netSocketBegin(self.network.context, p0 as u8, p1, p2.as_ptr(), p2.len() as u32, p3, self.raw.as_ptr()) } else { c::R4SdkNet2_netSocketBegin(self.network.context2, p0 as u8, p1, p2.as_ptr(), p2.len() as u32, p3, self.raw.as_ptr()) } }
    }
    pub fn net_socket_status<'b>(&'b mut self) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_netSocketStatus(self.network.context, self.raw.as_ptr()) } else { c::R4SdkNet2_netSocketStatus(self.network.context2, self.raw.as_ptr()) } }
    }
    pub fn net_socket_wait<'b>(&'b mut self, p1: u64) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_netSocketWait(self.network.context, self.raw.as_ptr(), p1) } else { c::R4SdkNet2_netSocketWait(self.network.context2, self.raw.as_ptr(), p1) } }
    }
    pub fn net_socket_close<'b>(&'b mut self) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_netSocketClose(self.network.context, self.raw.as_ptr()) } else { c::R4SdkNet2_netSocketClose(self.network.context2, self.raw.as_ptr()) } }
    }
    pub fn net_socket_wait_and_close<'b>(&'b mut self, p1: u64) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_netSocketWaitAndClose(self.network.context, self.raw.as_ptr(), p1) } else { c::R4SdkNet2_netSocketWaitAndClose(self.network.context2, self.raw.as_ptr(), p1) } }
    }
    pub fn udp_begin_status_service<'b>(&'b mut self) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_udpBeginStatusService(self.network.context, self.raw.as_ptr()) } else { c::R4SdkNet2_udpBeginStatusService(self.network.context2, self.raw.as_ptr()) } }
    }
    pub fn udp_begin_service_result<'b>(&'b mut self, p0: u16, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_udpBeginServiceResult(self.network.context, p0, p1.as_ptr(), p1.len() as u32, self.raw.as_ptr()) } else { c::R4SdkNet2_udpBeginServiceResult(self.network.context2, p0, p1.as_ptr(), p1.len() as u32, self.raw.as_ptr()) } }
    }
    pub fn udp_begin_bind_service<'b>(&'b mut self, p0: u16) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_udpBeginBindService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_udpBeginBindService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn udp_begin_send_to_service<'b>(&'b mut self, p0: u32, p1: [u8; 4], p2: u16, p3: &'b [u8]) -> i32 {
        if p3.len() > u32::MAX as usize { return abi::io_error_invalid; }
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_udpBeginSendToService(self.network.context, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32, self.raw.as_ptr()) } else { c::R4SdkNet2_udpBeginSendToService(self.network.context2, p0, p1.as_ptr(), p2, p3.as_ptr(), p3.len() as u32, self.raw.as_ptr()) } }
    }
    pub fn udp_begin_recv_from_service<'b>(&'b mut self, p0: u32, p1: usize) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_udpBeginRecvFromService(self.network.context, p0, p1 as u64, self.raw.as_ptr()) } else { c::R4SdkNet2_udpBeginRecvFromService(self.network.context2, p0, p1 as u64, self.raw.as_ptr()) } }
    }
    pub fn udp_begin_close_service<'b>(&'b mut self, p0: u32) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_udpBeginCloseService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_udpBeginCloseService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_status_service<'b>(&'b mut self) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginStatusService(self.network.context, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginStatusService(self.network.context2, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_service_result<'b>(&'b mut self, p0: u16, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginServiceResult(self.network.context, p0, p1.as_ptr(), p1.len() as u32, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginServiceResult(self.network.context2, p0, p1.as_ptr(), p1.len() as u32, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_connect_service<'b>(&'b mut self, p0: u8, p1: u8, p2: u8, p3: u8, p4: u16) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginConnectService(self.network.context, p0, p1, p2, p3, p4, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginConnectService(self.network.context2, p0, p1, p2, p3, p4, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_write_chunk_service<'b>(&'b mut self, p0: u32, p1: &'b [u8]) -> i32 {
        if p1.len() > u32::MAX as usize { return abi::io_error_invalid; }
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginWriteChunkService(self.network.context, p0, p1.as_ptr(), p1.len() as u32, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginWriteChunkService(self.network.context2, p0, p1.as_ptr(), p1.len() as u32, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_read_service<'b>(&'b mut self, p0: u32, p1: usize) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginReadService(self.network.context, p0, p1 as u64, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginReadService(self.network.context2, p0, p1 as u64, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_poll_service<'b>(&'b mut self, p0: u32) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginPollService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginPollService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_listen_service<'b>(&'b mut self, p0: u16) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginListenService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginListenService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_accept_service<'b>(&'b mut self, p0: u16) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginAcceptService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginAcceptService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_accept_poll_service<'b>(&'b mut self, p0: u16) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginAcceptPollService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginAcceptPollService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_accept_read_service<'b>(&'b mut self, p0: u16, p1: usize) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginAcceptReadService(self.network.context, p0, p1 as u64, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginAcceptReadService(self.network.context2, p0, p1 as u64, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_close_service<'b>(&'b mut self, p0: u32) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginCloseService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginCloseService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_abort_service<'b>(&'b mut self, p0: u32) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginAbortService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginAbortService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_retransmit_service<'b>(&'b mut self, p0: u32) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginRetransmitService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginRetransmitService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
    pub fn tcp_begin_close_listen_service<'b>(&'b mut self, p0: u16) -> i32 {
        unsafe { if self.network.context2.is_null() { c::R4SdkNet_tcpBeginCloseListenService(self.network.context, p0, self.raw.as_ptr()) } else { c::R4SdkNet2_tcpBeginCloseListenService(self.network.context2, p0, self.raw.as_ptr()) } }
    }
}
