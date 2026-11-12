//! Typed ownership/state views of the existing C application socket owner.
use super::{Network, c};
use crate::{abi, resources::Timeout};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Ipv4Address(pub [u8; 4]);
impl Ipv4Address {
    pub fn is_unspecified(self) -> bool {
        unsafe { c::r4_ipv4_is_unspecified(c::R4Ipv4Address { octets: self.0 }) != 0 }
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SocketAddress {
    pub address: Ipv4Address,
    pub port: u16,
}
impl SocketAddress {
    fn raw(self) -> c::R4SocketAddress {
        c::R4SocketAddress {
            address: c::R4Ipv4Address {
                octets: self.address.0,
            },
            port: self.port,
            reserved: 0,
        }
    }
    fn from_raw(raw: c::R4SocketAddress) -> Self {
        Self {
            address: Ipv4Address(raw.address.octets),
            port: raw.port,
        }
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SocketState {
    Ok,
    WouldBlock,
    TimedOut,
    Reset,
    PeerClosed,
    Closed,
    NotFound,
    NoService,
    Failed,
    /// The operation was submitted but its reply is unavailable or invalid.
    /// A read/write may already have taken effect; do not retry automatically.
    OutcomeUnknown,
    Unknown(u32),
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SocketOutcome {
    pub state: SocketState,
    pub raw_code: i32,
    /// Confirmed service prefix only when `confirmed_bytes()` returns Some.
    /// This is buffering/transmission progress, not a peer acknowledgement.
    pub bytes: usize,
}
impl SocketOutcome {
    fn from_raw(raw: c::R4NetResult) -> Self {
        Self {
            state: match raw.kind {
                0 => SocketState::Ok,
                1 => SocketState::WouldBlock,
                2 => SocketState::TimedOut,
                3 => SocketState::Reset,
                4 => SocketState::PeerClosed,
                5 => SocketState::Closed,
                6 => SocketState::NotFound,
                7 => SocketState::NoService,
                8 => SocketState::Failed,
                9 => SocketState::OutcomeUnknown,
                n => SocketState::Unknown(n),
            },
            raw_code: raw.raw_code,
            bytes: raw.bytes as usize,
        }
    }
    fn failure(code: i32) -> Self {
        Self {
            state: SocketState::Failed,
            raw_code: code,
            bytes: 0,
        }
    }
    pub fn confirmed_bytes(&self) -> Option<usize> {
        (self.state != SocketState::OutcomeUnknown).then_some(self.bytes)
    }
}
/// One validated readiness snapshot, independent of transferred byte progress.
/// Peer termination leaves the owned local handle available for drain/close.
#[derive(Clone, Copy)]
pub struct TcpPoll {
    pub outcome: SocketOutcome,
    pub readiness: Option<super::TcpReadiness>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CloseLifecycle {
    Unknown,
    Active,
    Closed,
    Reset,
    Timeout,
    PeerGone,
    LocalAbort,
    LocalClose,
    PendingClose,
    WouldBlock,
    BadHandle,
    OwnerMismatch,
    Listener,
    Dropped,
    Other(u32),
}
impl CloseLifecycle {
    fn from_raw(value: u32) -> Self {
        match value {
            0 => Self::Unknown,
            1 => Self::Active,
            2 => Self::Closed,
            3 => Self::Reset,
            4 => Self::Timeout,
            5 => Self::PeerGone,
            6 => Self::LocalAbort,
            7 => Self::LocalClose,
            8 => Self::PendingClose,
            9 => Self::WouldBlock,
            10 => Self::BadHandle,
            11 => Self::OwnerMismatch,
            12 => Self::Listener,
            13 => Self::Dropped,
            other => Self::Other(other),
        }
    }
}

/// TCPSVC's close ACK releases the frontend handle. `pending_shutdown`
/// explicitly reports that the network shutdown has not completed yet.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct TcpCloseReceipt {
    pub outcome: SocketOutcome,
    pub operation: u16,
    pub action: u16,
    pub ack: u32,
    pub lifecycle: CloseLifecycle,
    pub service_status: u32,
    pub accepted: bool,
    pub pending_shutdown: bool,
    pub frontend_released: bool,
    pub submitted: bool,
}
impl Network<'_> {
    pub fn available(&self) -> bool {
        unsafe { c::r4_network_available(&self.raw()) != 0 }
    }
    pub fn resolve_a(
        &self,
        name: &[u8],
        server: Option<Ipv4Address>,
        timeout: Timeout,
    ) -> Result<Ipv4Address, SocketOutcome> {
        let Ok(len) = u32::try_from(name.len()) else {
            return Err(SocketOutcome::failure(abi::service_api_result_invalid));
        };
        let mut resolver = unsafe { c::r4_network_resolver(self.raw()) };
        let mut out = c::R4Ipv4Address { octets: [0; 4] };
        let server = server.map(|address| c::R4Ipv4Address { octets: address.0 });
        let result = SocketOutcome::from_raw(unsafe {
            c::r4_resolver_resolve_a(
                &mut resolver,
                name.as_ptr(),
                len,
                server
                    .as_ref()
                    .map_or(core::ptr::null(), core::ptr::from_ref),
                timeout.raw(),
                &mut out,
            )
        });
        if result.state == SocketState::Ok {
            Ok(Ipv4Address(out.octets))
        } else {
            Err(result)
        }
    }
    pub fn connect_tcp(
        &self,
        remote: SocketAddress,
        timeout: Timeout,
    ) -> Result<TcpSocket<'_>, SocketOutcome> {
        let mut raw = unsafe { core::mem::zeroed() };
        let result = SocketOutcome::from_raw(unsafe {
            c::r4_network_connect_tcp(&mut self.raw(), remote.raw(), timeout.raw(), &mut raw)
        });
        if result.state == SocketState::Ok {
            Ok(TcpSocket { raw, network: self })
        } else {
            Err(result)
        }
    }
    pub fn listen_tcp(
        &self,
        port: u16,
        timeout: Timeout,
    ) -> Result<TcpListener<'_>, SocketOutcome> {
        let mut raw = unsafe { core::mem::zeroed() };
        let result = SocketOutcome::from_raw(unsafe {
            c::r4_network_listen_tcp(&mut self.raw(), port, timeout.raw(), &mut raw)
        });
        if result.state == SocketState::Ok {
            Ok(TcpListener { raw, network: self })
        } else {
            Err(result)
        }
    }
    pub fn bind_udp(&self, port: u16, timeout: Timeout) -> Result<UdpSocket<'_>, SocketOutcome> {
        let mut raw = unsafe { core::mem::zeroed() };
        let result = SocketOutcome::from_raw(unsafe {
            c::r4_network_bind_udp(&mut self.raw(), port, timeout.raw(), &mut raw)
        });
        if result.state == SocketState::Ok {
            Ok(UdpSocket {
                raw,
                _network: self,
            })
        } else {
            Err(result)
        }
    }
    /// Borrow an existing socket ID; close retains the native NOT_OWNED result.
    pub fn borrow_tcp(&self, id: u32, remote: SocketAddress) -> TcpSocket<'_> {
        TcpSocket {
            raw: c::R4TcpSocket {
                network: self.raw(),
                raw: id,
                owned: 0,
                reserved: [0; 3],
                remote: remote.raw(),
            },
            network: self,
        }
    }
    pub fn borrow_udp(&self, id: u32, local_port: u16) -> UdpSocket<'_> {
        UdpSocket {
            raw: c::R4UdpSocket {
                network: self.raw(),
                raw: id,
                local_port,
                owned: 0,
                reserved: 0,
            },
            _network: self,
        }
    }
}
pub struct TcpSocket<'a> {
    raw: c::R4TcpSocket,
    network: &'a Network<'a>,
}
impl TcpSocket<'_> {
    pub fn handle(&self) -> u32 {
        self.raw.raw
    }
    pub fn remote(&self) -> SocketAddress {
        SocketAddress::from_raw(self.raw.remote)
    }
    pub fn valid(&self) -> bool {
        unsafe { c::r4_tcp_socket_valid(&self.raw) != 0 }
    }
    pub fn write(&mut self, bytes: &[u8], timeout: Timeout) -> SocketOutcome {
        let Ok(n) = u32::try_from(bytes.len()) else {
            return SocketOutcome::failure(abi::net_tx_too_large);
        };
        SocketOutcome::from_raw(unsafe {
            c::r4_tcp_socket_write(&mut self.raw, bytes.as_ptr(), n, timeout.raw())
        })
    }
    pub fn read(&mut self, out: &mut [u8], timeout: Timeout) -> SocketOutcome {
        SocketOutcome::from_raw(unsafe {
            c::r4_tcp_socket_read(
                &mut self.raw,
                out.as_mut_ptr(),
                out.len().min(u32::MAX as usize) as u32,
                timeout.raw(),
            )
        })
    }
    /// The snapshot can be readable and peer-closed simultaneously.
    pub fn readiness(&mut self, timeout: Timeout) -> TcpPoll {
        let raw = unsafe { c::r4_tcp_socket_readiness(&mut self.raw, timeout.raw()) };
        TcpPoll {
            outcome: SocketOutcome::from_raw(raw.result),
            readiness: (raw.available != 0).then_some(raw.readiness),
        }
    }
    /// State-only compatibility poll; pending_rx is not transferred bytes.
    pub fn poll(&mut self, timeout: Timeout) -> SocketOutcome {
        SocketOutcome::from_raw(unsafe { c::r4_tcp_socket_poll(&mut self.raw, timeout.raw()) })
    }
    pub fn close(&mut self, timeout: Timeout) -> SocketOutcome {
        SocketOutcome::from_raw(unsafe { c::r4_tcp_socket_close(&mut self.raw, timeout.raw()) })
    }
    pub fn close_receipt(&mut self, timeout: Timeout) -> TcpCloseReceipt {
        let raw = unsafe { c::r4_tcp_socket_close_receipt(&mut self.raw, timeout.raw()) };
        TcpCloseReceipt {
            outcome: SocketOutcome::from_raw(raw.outcome),
            operation: raw.operation,
            action: raw.action,
            ack: raw.ack,
            lifecycle: CloseLifecycle::from_raw(raw.lifecycle_cause),
            service_status: raw.service_status,
            accepted: raw.accepted != 0,
            pending_shutdown: raw.pending_shutdown != 0,
            frontend_released: raw.frontend_released != 0,
            submitted: raw.submitted != 0,
        }
    }
    pub fn network(&self) -> &Network<'_> {
        self.network
    }
}
impl Drop for TcpSocket<'_> {
    fn drop(&mut self) {
        if self.raw.raw != 0 && self.raw.owned != 0 {
            let _ = self.close(Timeout::Poll);
        }
    }
}
pub struct TcpListener<'a> {
    raw: c::R4TcpListener,
    network: &'a Network<'a>,
}
impl<'a> TcpListener<'a> {
    pub fn port(&self) -> u16 {
        self.raw.port
    }
    pub fn valid(&self) -> bool {
        unsafe { c::r4_tcp_listener_valid(&self.raw) != 0 }
    }
    pub fn accept(&mut self, timeout: Timeout) -> Result<TcpSocket<'a>, SocketOutcome> {
        let mut raw = unsafe { core::mem::zeroed() };
        let result = SocketOutcome::from_raw(unsafe {
            c::r4_tcp_listener_accept(&mut self.raw, timeout.raw(), &mut raw)
        });
        if result.state == SocketState::Ok {
            Ok(TcpSocket {
                raw,
                network: self.network,
            })
        } else {
            Err(result)
        }
    }
    pub fn close(&mut self, timeout: Timeout) -> SocketOutcome {
        SocketOutcome::from_raw(unsafe { c::r4_tcp_listener_close(&mut self.raw, timeout.raw()) })
    }
}
impl Drop for TcpListener<'_> {
    fn drop(&mut self) {
        if self.raw.port != 0 && self.raw.owned != 0 {
            let _ = self.close(Timeout::Poll);
        }
    }
}
pub struct UdpSocket<'a> {
    raw: c::R4UdpSocket,
    _network: &'a Network<'a>,
}
pub struct Datagram {
    pub source: SocketAddress,
    pub destination: SocketAddress,
    pub bytes: usize,
}
impl UdpSocket<'_> {
    pub fn handle(&self) -> u32 {
        self.raw.raw
    }
    pub fn local_port(&self) -> u16 {
        self.raw.local_port
    }
    pub fn valid(&self) -> bool {
        unsafe { c::r4_udp_socket_valid(&self.raw) != 0 }
    }
    pub fn send_to(&mut self, to: SocketAddress, bytes: &[u8], timeout: Timeout) -> SocketOutcome {
        let Ok(n) = u32::try_from(bytes.len()) else {
            return SocketOutcome::failure(abi::net_tx_too_large);
        };
        SocketOutcome::from_raw(unsafe {
            c::r4_udp_socket_send_to(&mut self.raw, to.raw(), bytes.as_ptr(), n, timeout.raw())
        })
    }
    pub fn receive_from(&mut self, out: &mut [u8], timeout: Timeout) -> (SocketOutcome, Datagram) {
        let mut info = unsafe { core::mem::zeroed() };
        let result = SocketOutcome::from_raw(unsafe {
            c::r4_udp_socket_receive_from(
                &mut self.raw,
                out.as_mut_ptr(),
                out.len().min(u32::MAX as usize) as u32,
                timeout.raw(),
                &mut info,
            )
        });
        (
            result,
            Datagram {
                source: SocketAddress::from_raw(info.source),
                destination: SocketAddress::from_raw(info.destination),
                bytes: info.bytes as usize,
            },
        )
    }
    pub fn close(&mut self, timeout: Timeout) -> SocketOutcome {
        SocketOutcome::from_raw(unsafe { c::r4_udp_socket_close(&mut self.raw, timeout.raw()) })
    }
}
impl Drop for UdpSocket<'_> {
    fn drop(&mut self) {
        if self.raw.raw != 0 && self.raw.owned != 0 {
            let _ = self.close(Timeout::Poll);
        }
    }
}
