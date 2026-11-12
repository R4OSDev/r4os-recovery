//! Existing networking owners projected to slices and canonical records.
//! Native status codes and partial counts remain distinct. Raw borrowed async
//! admission is unsafe; OwnedRequest owns its stable buffers even if forgotten.
use crate::{App, abi, c_facades as c};
use core::marker::PhantomData;
mod sockets;
pub use sockets::{
    CloseLifecycle, Datagram, Ipv4Address, SocketAddress, SocketOutcome, SocketState,
    TcpCloseReceipt, TcpListener, TcpPoll, TcpSocket, UdpSocket,
};
#[cfg(feature = "alloc")]
extern crate alloc;
pub type ResolverOptions = c::R4SdkResolverOptions;
pub type ResolverResult = c::R4SdkResolverResult;
pub type TcpReadiness = c::R4SdkTcpReadiness;
pub type RawRequest = c::R4SdkNetRequest;
#[repr(u8)]
#[derive(Clone, Copy)]
pub enum SocketService {
    Tcp = 0,
    Udp = 1,
}
pub struct Network<'a> {
    pub(crate) context: *const abi::R4XStartContext,
    pub(crate) context2: *const c::R4OS2Context,
    app: c::R4App,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Network<'a> {
    pub fn new(app: &'a App<'_>) -> crate::storage::Result<Self> {
        Ok(Self {
            context: app.start_context(),
            context2: core::ptr::null(),
            app: crate::facade_app(app)?,
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn new2(app: &'a crate::app2::App<'_>) -> crate::storage::Result<Self> {
        let mut facade = unsafe { core::mem::zeroed() };
        let rc = unsafe { c::R4SdkAppFacade2(app.native_context(), &app.memory, &mut facade) };
        if rc != 0 {
            return Err(crate::storage::Error::Raw(rc));
        }
        Ok(Self {
            context: core::ptr::null(),
            context2: app.native_context(),
            app: facade,
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    fn raw(&self) -> c::R4Network {
        c::R4Network {
            app: core::ptr::from_ref(&self.app).cast_mut(),
        }
    }
    #[cfg(feature = "alloc")]
    pub fn request(&self) -> OwnedRequest<'_> {
        OwnedRequest::new(self)
    }
}
/// # Safety
/// The caller proves that the native slice points into a live borrowed buffer
/// or resident owner data and that the returned lifetime does not exceed it.
pub(crate) unsafe fn view<'a>(v: c::R4SdkNetSlice) -> Option<&'a [u8]> {
    if v.valid == 0 || v.length > isize::MAX as u64 {
        return None;
    }
    if v.length == 0 {
        return Some(&[]);
    }
    if v.ptr.is_null() {
        return None;
    }
    Some(unsafe { core::slice::from_raw_parts(v.ptr, v.length as usize) })
}

#[cfg(feature = "alloc")]
pub struct OwnedRequest<'a> {
    pub(crate) network: &'a Network<'a>,
    pub(crate) raw: core::ptr::NonNull<RawRequest>,
}
#[cfg(feature = "alloc")]
impl<'a> OwnedRequest<'a> {
    fn new(network: &'a Network<'a>) -> Self {
        // Transfer ownership before giving a native worker any address. A
        // moved Rust Box must never assert unique access to loaned buffers.
        // Native private storage may contain uninitialized padding. Keep it
        // MaybeUninit for its complete lifetime; only native getters inspect it.
        let value = alloc::boxed::Box::new(core::mem::MaybeUninit::<RawRequest>::zeroed());
        let raw = core::ptr::NonNull::new(alloc::boxed::Box::into_raw(value).cast()).unwrap();
        unsafe { c::R4SdkNetRequestInit(raw.as_ptr()) };
        Self { network, raw }
    }
    pub fn active(&self) -> bool {
        unsafe { c::R4SdkNetRequestActive(self.raw.as_ptr()) != 0 }
    }
    pub fn completed(&self) -> bool {
        unsafe { c::R4SdkNetRequestCompleted(self.raw.as_ptr()) != 0 }
    }
    pub fn info(&self) -> abi::ProgramIoInfo {
        let mut out = abi::ProgramIoInfo::default();
        unsafe { c::R4SdkNetRequestInfo(self.raw.as_ptr(), &mut out) };
        out
    }
    pub fn header(&self) -> Option<abi::ServiceMessageHeader> {
        let mut out = abi::ServiceMessageHeader::default();
        if unsafe { c::R4SdkNetRequestHeader(self.raw.as_ptr(), &mut out) } != 0 {
            Some(out)
        } else {
            None
        }
    }
    pub fn response(&self) -> Option<&[u8]> {
        unsafe { view(c::R4SdkNetRequestResponse(self.raw.as_ptr())) }
    }
    pub fn tcp_status(&self) -> Option<abi::NetServiceTcpStatus> {
        let mut out = abi::NetServiceTcpStatus::default();
        if unsafe { c::R4SdkNetRequestTcpStatus(self.raw.as_ptr(), &mut out) } != 0 {
            Some(out)
        } else {
            None
        }
    }
    pub fn tcp_result(&self) -> Option<abi::NetServiceTcpResult> {
        let mut out = abi::NetServiceTcpResult::default();
        if unsafe { c::R4SdkNetRequestTcpResult(self.raw.as_ptr(), &mut out) } != 0 {
            Some(out)
        } else {
            None
        }
    }
    pub fn tcp_data(&self, result: &abi::NetServiceTcpResult) -> Option<&[u8]> {
        unsafe { view(c::R4SdkNetRequestTcpData(self.raw.as_ptr(), result)) }
    }
    pub fn udp_status(&self) -> Option<abi::NetServiceUdpStatus> {
        let mut out = abi::NetServiceUdpStatus::default();
        if unsafe { c::R4SdkNetRequestUdpStatus(self.raw.as_ptr(), &mut out) } != 0 {
            Some(out)
        } else {
            None
        }
    }
    pub fn udp_result(&self) -> Option<abi::NetServiceUdpResult> {
        let mut out = abi::NetServiceUdpResult::default();
        if unsafe { c::R4SdkNetRequestUdpResult(self.raw.as_ptr(), &mut out) } != 0 {
            Some(out)
        } else {
            None
        }
    }
    pub fn udp_data(&self, result: &abi::NetServiceUdpResult) -> Option<&[u8]> {
        unsafe { view(c::R4SdkNetRequestUdpData(self.raw.as_ptr(), result)) }
    }
    pub fn status(&mut self) -> i32 {
        unsafe {
            if self.network.context2.is_null() {
                c::R4SdkNet_netSocketStatus(self.network.context, self.raw.as_ptr())
            } else {
                c::R4SdkNet2_netSocketStatus(self.network.context2, self.raw.as_ptr())
            }
        }
    }
    pub fn wait(&mut self, ticks: u64) -> i32 {
        unsafe {
            if self.network.context2.is_null() {
                c::R4SdkNet_netSocketWait(self.network.context, self.raw.as_ptr(), ticks)
            } else {
                c::R4SdkNet2_netSocketWait(self.network.context2, self.raw.as_ptr(), ticks)
            }
        }
    }
    pub fn close(&mut self) -> i32 {
        if !self.active() {
            return 0;
        }
        unsafe {
            if self.network.context2.is_null() {
                c::R4SdkNet_netSocketClose(self.network.context, self.raw.as_ptr())
            } else {
                c::R4SdkNet2_netSocketClose(self.network.context2, self.raw.as_ptr())
            }
        }
    }
    pub fn reset(&mut self) -> i32 {
        unsafe { c::R4SdkNetRequestReset(self.raw.as_ptr()) }
    }
}
#[cfg(feature = "alloc")]
impl Drop for OwnedRequest<'_> {
    fn drop(&mut self) {
        let _ = self.close();
        // BUSY or another error retains the allocation for the native instance
        // reaper. Neither Drop nor mem::forget can free active worker storage.
        if !self.active() {
            unsafe {
                drop(alloc::boxed::Box::from_raw(
                    self.raw
                        .as_ptr()
                        .cast::<core::mem::MaybeUninit<RawRequest>>(),
                ))
            };
        }
    }
}
