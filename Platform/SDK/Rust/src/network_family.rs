//! Copied family-aware service RPCs. Exclusive channel; no implicit retries.
use crate::{abi, platform2::Context, time::checked};
use core::{marker::PhantomData, mem};
#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub struct Error(pub i32);
const INVALID: Error = Error(abi::network_error_invalid);
#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub enum Service {
    Dns,
    Tcp,
    Udp,
}
pub fn deadline(budget: &checked::DeadlineBudget) -> Result<abi::NetworkDeadline, Error> {
    let b = budget.raw();
    if b.kind > 2
        || b.reserved != 0
        || b.identity.source == 0
        || b.identity.generation == 0
        || b.kind != 2 && b.deadline_ns < b.last_ns
        || b.kind == 2 && b.deadline_ns != 0
    {
        return Err(INVALID);
    }
    Ok(abi::NetworkDeadline {
        kind: b.kind,
        absolute_ns: b.deadline_ns,
        last_ns: b.last_ns,
        clock_source: b.identity.source,
        clock_generation: b.identity.generation,
        event_backend: b.identity.event_backend,
        tick_hz: b.identity.tick_hz,
        ..abi::NetworkDeadline::default()
    })
}
fn address_valid(x: abi::NetworkAddress) -> bool {
    x.reserved0 == 0
        && x.reserved1 == 0
        && (x.family == 6 || x.family == 4 && x.bytes[4..].iter().all(|x| *x == 0))
}
fn endpoint_valid(x: abi::NetworkEndpoint) -> bool {
    x.reserved == 0 && x.flags == 0 && address_valid(x.address)
}
// All instantiated request/reply types are fixed integer-only, padding-free
// wire records. There are no references, invalid bit patterns or foreign enums.
fn bytes<T>(x: &T) -> &[u8] {
    unsafe { core::slice::from_raw_parts(core::ptr::from_ref(x).cast(), mem::size_of::<T>()) }
}
trait Record: Copy {}
impl Record for abi::NetworkProviderInfo {}
impl Record for abi::NetworkSocketResult {}
impl Record for abi::NetworkResolvePage {}
fn decode<T: Record>(x: &[u8]) -> Result<T, Error> {
    if x.len() != mem::size_of::<T>()
        || u32::from_le_bytes(x[..4].try_into().map_err(|_| INVALID)?) != 1
        || u32::from_le_bytes(x[4..8].try_into().map_err(|_| INVALID)?)
            != mem::size_of::<T>() as u32
    {
        return Err(INVALID);
    }
    Ok(unsafe { x.as_ptr().cast::<T>().read_unaligned() })
}
#[must_use]
pub struct Client<'a> {
    _context: &'a Context<'a>,
    call: abi::R4SysFns::service_call,
    close: abi::R4SysFns::service_close,
    handle: u32,
    service: Service,
    timeout_ticks: u64,
    _local: PhantomData<*mut ()>,
}
impl<'a> Client<'a> {
    pub fn connect(context: &'a Context<'a>, service: Service) -> Result<Self, Error> {
        let open = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_open) as u32,
            )
            .map_err(Error)?;
        let call = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_call) as u32,
            )
            .map_err(Error)?;
        let close = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_close) as u32,
            )
            .map_err(Error)?;
        let open = unsafe { mem::transmute::<u64, abi::R4SysFns::service_open>(open) };
        let mut info = abi::ServiceInfo::default();
        let name = match service {
            Service::Dns => c"DNSSVC",
            Service::Tcp => c"TCPSVC",
            Service::Udp => c"UDPSVC",
        };
        let rc = unsafe { open(name.as_ptr().cast(), &mut info) };
        if rc != 0 {
            return Err(Error(rc));
        }
        if info.handle == 0 {
            return Err(Error(abi::service_api_result_no_endpoint));
        }
        Ok(Self {
            _context: context,
            call: unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) },
            close: unsafe { mem::transmute::<u64, abi::R4SysFns::service_close>(close) },
            handle: info.handle,
            service,
            timeout_ticks: 500,
            _local: PhantomData,
        })
    }
    pub fn close(&mut self) -> Result<(), Error> {
        if self.handle == 0 {
            return Err(Error(abi::network_error_bad_socket));
        }
        let rc = unsafe { (self.close)(self.handle) };
        if rc < 0 {
            return Err(Error(rc));
        }
        self.handle = 0;
        Ok(())
    }
    pub fn set_timeout_ticks(&mut self, value: u64) {
        self.timeout_ticks = value;
    }
    fn rpc(&mut self, op: u16, request: &[u8], response: &mut [u8]) -> Result<usize, Error> {
        if self.handle == 0 {
            return Err(Error(abi::network_error_bad_socket));
        }
        if request.len() > 4096 || response.len() > 4096 {
            return Err(INVALID);
        }
        let mut header = abi::ServiceMessageHeader::default();
        let rc = unsafe {
            (self.call)(
                self.handle,
                op,
                request.as_ptr(),
                request.len() as u32,
                &mut header,
                response.as_mut_ptr(),
                response.len() as u32,
                self.timeout_ticks,
            )
        };
        if rc < 0 {
            return Err(Error(rc));
        }
        if rc as usize > response.len() {
            return Err(INVALID);
        }
        if header.status == abi::service_api_result_bad_op {
            return Err(Error(abi::err_no_fn));
        }
        if header.status != 0 {
            return Err(if header.status < 0 {
                Error(header.status)
            } else {
                INVALID
            });
        }
        Ok(rc as usize)
    }
    pub fn info(&mut self) -> Result<abi::NetworkProviderInfo, Error> {
        let mut response = [0; mem::size_of::<abi::NetworkProviderInfo>()];
        let count = self.rpc(abi::network_op_info, &[], &mut response)?;
        let x: abi::NetworkProviderInfo = decode(&response[..count])?;
        if x.provider == 0
            || x.reserved != 0
            || x.capabilities & !4095 != 0
            || x.max_send > 3968
            || x.max_recv > 4008
            || x.max_answers > 32
            || x.page_capacity > 16
        {
            return Err(INVALID);
        }
        Ok(x)
    }
    /// Write/Send return a confirmed prefix without payload. Read/Recv copy
    /// data only after validating the complete reply. Every suffix stays owned
    /// by its caller; no transport failure grants resource retirement.
    pub fn socket(
        &mut self,
        op: u16,
        request: abi::NetworkSocketRequest,
        data: &[u8],
        out: &mut [u8],
    ) -> Result<abi::NetworkSocketResult, Error> {
        if self.service == Service::Dns
            || !(abi::network_op_connect..=abi::network_op_accept).contains(&op)
            || request.version != 1
            || request.size != mem::size_of_val(&request) as u32
            || request.provider == 0
            || data.len() > 3968
            || out.len() > 4008
        {
            return Err(INVALID);
        }
        let sending = op == abi::network_op_write || op == abi::network_op_send;
        let receiving = op == abi::network_op_read || op == abi::network_op_recv;
        if data.len() != if sending { request.bytes as usize } else { 0 }
            || receiving && request.bytes as usize > out.len()
        {
            return Err(INVALID);
        }
        let mut payload = [0; 4096];
        let prefix = mem::size_of_val(&request);
        payload[..prefix].copy_from_slice(bytes(&request));
        payload[prefix..prefix + data.len()].copy_from_slice(data);
        let mut response = [0; 4096];
        let count = self.rpc(op, &payload[..prefix + data.len()], &mut response)?;
        let base = mem::size_of::<abi::NetworkSocketResult>();
        if count < base {
            return Err(INVALID);
        }
        let x: abi::NetworkSocketResult = decode(&response[..base])?;
        let accepted = op == abi::network_op_accept && x.state == abi::network_state_ready;
        if x.provider != request.provider
            || x.socket == 0
            || x.generation == 0
            || request.socket != 0
                && !accepted
                && (x.socket != request.socket || x.generation != request.generation)
            || accepted && x.socket == request.socket && x.generation == request.generation
            || !endpoint_valid(x.endpoint)
            || !(1..=6).contains(&x.state)
            || x.flags & !abi::network_flag_truncated != 0
            || x.bytes > request.bytes
            || x.original_bytes < x.bytes
            || count != base + if receiving { x.bytes as usize } else { 0 }
        {
            return Err(INVALID);
        }
        if op != abi::network_op_recv && (x.flags != 0 || x.original_bytes != x.bytes)
            || op == abi::network_op_recv
                && ((x.flags & abi::network_flag_truncated != 0) != (x.original_bytes > x.bytes))
        {
            return Err(INVALID);
        }
        if receiving {
            out[..x.bytes as usize].copy_from_slice(&response[base..base + x.bytes as usize]);
        }
        Ok(x)
    }
    pub fn resolve(
        &mut self,
        request: abi::NetworkResolveRequest,
        answers: &mut [abi::NetworkResolveAnswer],
    ) -> Result<abi::NetworkResolvePage, Error> {
        if self.service != Service::Dns
            || request.capacity == 0
            || request.capacity > 16
            || request.capacity as usize > answers.len()
        {
            return Err(INVALID);
        }
        let mut response = [0; 4096];
        let count = self.rpc(abi::network_op_resolve, bytes(&request), &mut response)?;
        let base = mem::size_of::<abi::NetworkResolvePage>();
        if count < base {
            return Err(INVALID);
        }
        let x: abi::NetworkResolvePage = decode(&response[..base])?;
        if request.provider == 0
            || x.provider != request.provider
            || x.query == 0
            || request.query != 0 && x.query != request.query
            || x.expires_ns == 0
            || x.total == 0
            || x.total > 32
            || x.count == 0
            || x.count > request.capacity
            || request.cursor > x.total
            || x.count > x.total - request.cursor
            || x.next != request.cursor + x.count
            || x.flags
                != if x.next < x.total {
                    abi::network_flag_more
                } else {
                    0
                }
            || count != base + x.count as usize * mem::size_of::<abi::NetworkResolveAnswer>()
        {
            return Err(INVALID);
        }
        let mut values = [abi::NetworkResolveAnswer::default(); 16];
        let size = mem::size_of::<abi::NetworkResolveAnswer>();
        for (i, value) in values[..x.count as usize].iter_mut().enumerate() {
            *value = unsafe {
                response[base + i * size..]
                    .as_ptr()
                    .cast::<abi::NetworkResolveAnswer>()
                    .read_unaligned()
            };
            if !address_valid(value.address)
                || value.reserved != 0
                || request.query == 0 && u32::from(value.address.family) != request.family
            {
                return Err(INVALID);
            }
        }
        answers[..x.count as usize].copy_from_slice(&values[..x.count as usize]);
        Ok(x)
    }
    pub fn release(&mut self, provider: u64, query: u64) -> Result<(), Error> {
        if self.service != Service::Dns {
            return Err(INVALID);
        }
        let request = abi::NetworkResolveRequest {
            provider,
            query,
            family: 0,
            capacity: 0,
            ..abi::NetworkResolveRequest::default()
        };
        let mut response = [0; 1];
        if self.rpc(abi::network_op_release, bytes(&request), &mut response)? != 0 {
            return Err(INVALID);
        }
        Ok(())
    }
}
