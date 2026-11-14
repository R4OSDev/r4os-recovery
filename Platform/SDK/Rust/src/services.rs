//! Endpoint ownership and the shared Zig service loop policy.
use crate::{
    App, abi, c_facades as c,
    resources::Timeout,
    storage::{Error, Result, length},
};
use core::{cell::Cell, ffi::CStr, marker::PhantomData};

pub use c::R4SdkServiceLoopMetrics as LoopMetrics;
mod actions;
mod evidence;
mod inventory;
mod links;
mod tray;
pub use actions::{FocusObservation, PointerStep, prepare_pointer_grant};
pub use evidence::{EvidenceLease, EvidenceReply, EvidenceToken, prepare_evidence};
pub use inventory::InventoryAction;
#[cfg(feature = "alloc")]
pub use inventory::ServiceInventory;
pub use links::{LinkReply, LinkRequest, LinkToken, link_supported, prepare_link_binding};
pub use tray::{Tray, TrayCall, TrayItem};
pub struct Control {
    pub raw_code: i32,
    pub info: abi::ServiceInfo,
}
/// A borrowed identity value paired with one generation-validated service
/// snapshot. It may name the terminal row's last retained process.
#[derive(Clone, Copy, Default)]
pub struct BoundDetail {
    pub detail: abi::ServiceDetail,
    pub process: abi::ProgramProcessHandle,
}
pub struct Services<'a> {
    app: c::R4App,
    context: *const abi::generation2::R4XStartContext2,
    context2: *const c::R4OS2Context,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
fn exact(rc: i32) -> Result<()> {
    if rc == 0 { Ok(()) } else { Err(Error::Raw(rc)) }
}
impl<'a> Services<'a> {
    pub fn new(app: &'a App<'_>) -> Result<Self> {
        Self::new2(app)
    }
    pub fn new2(app: &'a crate::app2::App<'_>) -> Result<Self> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe { c::R4SdkAppFacade2(app.native_context(), &app.memory, &mut raw) })?;
        Ok(Self {
            app: raw,
            context: core::ptr::null(),
            context2: app.native_context(),
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    fn raw(&self) -> c::R4Services {
        c::R4Services {
            app: core::ptr::from_ref(&self.app).cast_mut(),
        }
    }
    pub fn available(&self) -> bool {
        unsafe { c::r4_services_available(&self.raw()) != 0 }
    }
    pub fn tray(&self) -> Result<Tray<'_>> {
        Tray::new(self)
    }
    pub fn open(&self, name: &CStr) -> Result<Connection<'_>> {
        let mut value = unsafe { core::mem::zeroed() };
        exact(unsafe { c::r4_services_open(&mut self.raw(), name.as_ptr().cast(), &mut value) })?;
        Ok(Connection {
            owner: self,
            handle: value.raw,
            info: value.info,
        })
    }
    pub fn register(&self, name: &CStr, flags: u32) -> Result<Endpoint<'_>> {
        let mut value = unsafe { core::mem::zeroed() };
        exact(unsafe {
            c::r4_services_register(&mut self.raw(), name.as_ptr().cast(), flags, &mut value)
        })?;
        Ok(Endpoint {
            owner: self,
            handle: Cell::new(value.raw),
            info: value.info,
        })
    }
    /// Contents are private staging until explicit EOF. A failure does not
    /// publish a partially refreshed inventory.
    pub fn details(&self, staging: &mut [abi::ServiceDetail]) -> Result<usize> {
        let n = unsafe {
            if self.context2.is_null() {
                c::R4SdkServiceDetails(self.context, staging.as_mut_ptr(), length(staging.len())?)
            } else {
                c::R4SdkServiceDetails2(self.context2, staging.as_mut_ptr(), length(staging.len())?)
            }
        };
        if n < 0 {
            return Err(Error::Raw(n));
        }
        if n as usize > staging.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(n as usize)
    }
    // One direct forwarding boundary for the existing service control slots.
    #[allow(clippy::too_many_arguments)]
    fn control(
        &self,
        operation: u32,
        name: &CStr,
        path: Option<&CStr>,
        args: Option<&CStr>,
        mode: u32,
        description: Option<&CStr>,
        ticks: u64,
    ) -> Control {
        let pointer = |v: Option<&CStr>| v.map_or(core::ptr::null(), |s| s.as_ptr().cast());
        let mut info = abi::ServiceInfo::default();
        let raw_code = unsafe {
            if self.context2.is_null() {
                c::R4SdkServiceControl(
                    self.context,
                    operation,
                    name.as_ptr().cast(),
                    pointer(path),
                    pointer(args),
                    mode,
                    pointer(description),
                    ticks,
                    &mut info,
                )
            } else {
                c::R4SdkServiceControl2(
                    self.context2,
                    operation,
                    name.as_ptr().cast(),
                    pointer(path),
                    pointer(args),
                    mode,
                    pointer(description),
                    ticks,
                    &mut info,
                )
            }
        };
        Control { raw_code, info }
    }
    pub fn status(&self, name: &CStr) -> Control {
        self.control(0, name, None, None, 0, None, 0)
    }
    pub fn start(&self, name: &CStr) -> Control {
        self.control(1, name, None, None, 0, None, 0)
    }
    pub fn stop(&self, name: &CStr, timeout: Timeout) -> Control {
        let mut ticks = 0;
        let rc = unsafe {
            c::r4_timeout_to_ticks(
                timeout.raw(),
                c::r4_services_monotonic_hz(self.raw().app),
                &mut ticks,
            )
        };
        if rc != 0 {
            return Control {
                raw_code: rc,
                info: abi::ServiceInfo::default(),
            };
        }
        self.control(2, name, None, None, 0, None, ticks)
    }
    pub fn stop_bound(
        &self,
        name: &CStr,
        process: &abi::ProgramProcessHandle,
        timeout: Timeout,
    ) -> Control {
        let mut info = abi::ServiceInfo::default();
        let raw_code = unsafe {
            c::r4_services_stop_bound(
                &self.raw(),
                name.as_ptr().cast(),
                process,
                timeout.raw(),
                &mut info,
            )
        };
        Control { raw_code, info }
    }
    pub fn restart(&self, name: &CStr) -> Control {
        self.control(3, name, None, None, 0, None, 0)
    }
    pub fn install(
        &self,
        name: &CStr,
        path: &crate::path::FilePath,
        args: &CStr,
        mode: u32,
        description: &CStr,
    ) -> Control {
        self.control(
            4,
            name,
            Some(path.as_c_str()),
            Some(args),
            mode,
            Some(description),
            0,
        )
    }
    pub fn remove(&self, name: &CStr) -> Control {
        self.control(5, name, None, None, 0, None, 0)
    }
    pub fn set_start_mode(&self, name: &CStr, mode: u32) -> Control {
        self.control(6, name, None, None, mode, None, 0)
    }
    pub fn info(&self, index: u32) -> Control {
        let mut info = abi::ServiceInfo::default();
        let raw_code = unsafe {
            if self.context2.is_null() {
                c::R4SdkServiceInfo(self.context, index, &mut info)
            } else {
                c::R4SdkServiceInfo2(self.context2, index, &mut info)
            }
        };
        Control { raw_code, info }
    }
    pub fn bound_detail(&self, name: &CStr) -> Result<BoundDetail> {
        let mut value = BoundDetail::default();
        exact(unsafe {
            c::r4_services_bound_detail(
                &self.raw(),
                name.as_ptr().cast(),
                &mut value.detail,
                &mut value.process,
            )
        })?;
        Ok(value)
    }
    pub fn detail(&self, name: &CStr) -> (i32, abi::ServiceDetail) {
        let mut info = abi::ServiceDetail::default();
        let code = unsafe {
            if self.context2.is_null() {
                c::R4SdkServiceDetail(self.context, name.as_ptr().cast(), &mut info)
            } else {
                c::R4SdkServiceDetail2(self.context2, name.as_ptr().cast(), &mut info)
            }
        };
        (code, info)
    }
}
pub enum Call {
    Response {
        header: abi::ServiceMessageHeader,
        bytes: usize,
    },
    TimedOut,
    RemoteFailure(i32),
}
pub struct Connection<'a> {
    owner: &'a Services<'a>,
    handle: u32,
    pub info: abi::ServiceInfo,
}
impl Connection<'_> {
    pub fn handle(&self) -> u32 {
        self.handle
    }
    fn raw(&self) -> c::R4ServiceConnection {
        c::R4ServiceConnection {
            app: self.owner.raw().app,
            raw: self.handle,
            owned: 1,
            reserved: [0; 3],
            info: self.info,
        }
    }
    pub fn call(
        &mut self,
        op: u16,
        request: &[u8],
        out: &mut [u8],
        timeout: Timeout,
    ) -> Result<Call> {
        let mut value = self.raw();
        let result = unsafe {
            c::r4_service_connection_call(
                &mut value,
                op,
                request.as_ptr().cast(),
                length(request.len())?,
                out.as_mut_ptr().cast(),
                length(out.len())?,
                timeout.raw(),
            )
        };
        self.handle = value.raw;
        match result.kind {
            0 if result.bytes as usize <= out.len() => Ok(Call::Response {
                header: result.header,
                bytes: result.bytes as usize,
            }),
            0 => Err(Error::InvalidProvider),
            1 => Ok(Call::TimedOut),
            2 => Ok(Call::RemoteFailure(result.raw_code)),
            _ => Err(Error::Raw(result.raw_code)),
        }
    }
    pub fn close(&mut self) -> Result<()> {
        if self.handle == 0 {
            return Ok(());
        }
        let mut value = self.raw();
        let rc = unsafe { c::r4_service_connection_close(&mut value) };
        self.handle = value.raw;
        self.info = value.info;
        if self.handle == 0 { Ok(()) } else { exact(rc) }
    }
}
impl Drop for Connection<'_> {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
pub enum Receive {
    Message {
        header: abi::ServiceMessageHeader,
        bytes: usize,
    },
    WouldBlock,
}
pub struct Endpoint<'a> {
    owner: &'a Services<'a>,
    handle: Cell<u32>,
    pub info: abi::ServiceInfo,
}
impl Endpoint<'_> {
    pub fn handle(&self) -> u32 {
        self.handle.get()
    }
    fn raw(&self) -> c::R4ServiceEndpoint {
        c::R4ServiceEndpoint {
            app: self.owner.raw().app,
            raw: self.handle(),
            owned: 1,
            reserved: [0; 3],
            info: self.info,
        }
    }
    pub fn wait(&self, timeout: Timeout) -> Result<Option<u32>> {
        let mut value = self.raw();
        let result = unsafe { c::r4_service_endpoint_wait(&mut value, timeout.raw()) };
        self.handle.set(value.raw);
        match result.kind {
            0 => Ok(Some(result.pending)),
            1 => Ok(None),
            _ => Err(Error::Raw(result.raw_code)),
        }
    }
    pub fn receive(&self, out: &mut [u8]) -> Result<Receive> {
        let mut value = self.raw();
        let result = unsafe {
            c::r4_service_endpoint_recv(&mut value, out.as_mut_ptr().cast(), length(out.len())?)
        };
        self.handle.set(value.raw);
        match result.kind {
            0 if result.bytes as usize <= out.len() => Ok(Receive::Message {
                header: result.header,
                bytes: result.bytes as usize,
            }),
            0 => Err(Error::InvalidProvider),
            1 => Ok(Receive::WouldBlock),
            _ => Err(Error::Raw(result.raw_code)),
        }
    }
    pub fn reply(&self, request_id: u32, status: i32, bytes: &[u8]) -> i32 {
        let Ok(n) = length(bytes.len()) else {
            return abi::service_api_result_payload_too_large;
        };
        let mut value = self.raw();
        let rc = unsafe {
            c::r4_service_endpoint_reply(&mut value, request_id, status, bytes.as_ptr().cast(), n)
        };
        self.handle.set(value.raw);
        rc
    }
    /// A cancelled request is harmless; an invalid endpoint remains an error.
    pub fn reply_if_pending(&self, request_id: u32, status: i32, bytes: &[u8]) -> i32 {
        unsafe { c::R4SdkCompletedReply(self.reply(request_id, status, bytes)) }
    }
    pub fn close(&mut self) -> Result<()> {
        if self.handle() == 0 {
            return Ok(());
        }
        let mut value = self.raw();
        let rc = unsafe { c::r4_service_endpoint_unregister(&mut value) };
        self.handle.set(value.raw);
        self.info = value.info;
        if self.handle() == 0 {
            Ok(())
        } else {
            exact(rc)
        }
    }
    pub fn service_loop(&self, stop_check_ms: u64, drain_limit: u32) -> Result<ServiceLoop<'_>> {
        let mut state = unsafe { core::mem::zeroed() };
        exact(unsafe {
            if self.owner.context2.is_null() {
                c::R4SdkServiceLoopInit(
                    self.owner.context,
                    self.handle(),
                    stop_check_ms,
                    drain_limit,
                    &mut state,
                )
            } else {
                c::R4SdkServiceLoopInit2(
                    self.owner.context2,
                    self.handle(),
                    stop_check_ms,
                    drain_limit,
                    &mut state,
                )
            }
        })?;
        Ok(ServiceLoop {
            endpoint: self,
            state,
        })
    }
}
impl Drop for Endpoint<'_> {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
pub enum Wake {
    Requests(u32),
    Deadline,
    Idle,
    Stop,
}
pub enum BatchStep {
    Request,
    Complete,
    Yielded,
}
pub struct ServiceLoop<'a> {
    endpoint: &'a Endpoint<'a>,
    state: c::R4SdkServiceLoop,
}
impl<'a> ServiceLoop<'a> {
    pub fn metrics(&self) -> &LoopMetrics {
        &self.state.metrics
    }
    pub fn wait(&mut self, deadline: Option<u64>) -> Result<Wake> {
        let v = unsafe {
            if self.endpoint.owner.context2.is_null() {
                c::R4SdkServiceLoopWait(
                    self.endpoint.owner.context,
                    &mut self.state,
                    deadline.is_some() as u32,
                    deadline.unwrap_or(0),
                )
            } else {
                c::R4SdkServiceLoopWait2(
                    self.endpoint.owner.context2,
                    &mut self.state,
                    deadline.is_some() as u32,
                    deadline.unwrap_or(0),
                )
            }
        };
        match v.kind {
            0 => Ok(Wake::Requests(v.value as u32)),
            1 => Ok(Wake::Deadline),
            2 => Ok(Wake::Idle),
            3 => Ok(Wake::Stop),
            _ => Err(Error::Raw(v.value)),
        }
    }
    pub fn batch(&mut self, announced: u32) -> Result<Batch<'_, 'a>> {
        let mut state = unsafe { core::mem::zeroed() };
        exact(unsafe {
            if self.endpoint.owner.context2.is_null() {
                c::R4SdkServiceLoopBatch(
                    self.endpoint.owner.context,
                    &mut self.state,
                    announced,
                    &mut state,
                )
            } else {
                c::R4SdkServiceLoopBatch2(
                    self.endpoint.owner.context2,
                    &mut self.state,
                    announced,
                    &mut state,
                )
            }
        })?;
        Ok(Batch { owner: self, state })
    }
    pub fn drain<F: FnMut() -> i32>(&mut self, announced: u32, mut handler: F) -> i32 {
        unsafe extern "C" fn invoke<F: FnMut() -> i32>(data: *mut core::ffi::c_void) -> i32 {
            unsafe { (&mut *data.cast::<F>())() }
        }
        unsafe {
            if self.endpoint.owner.context2.is_null() {
                c::R4SdkServiceLoopDrain(
                    self.endpoint.owner.context,
                    &mut self.state,
                    announced,
                    Some(invoke::<F>),
                    core::ptr::from_mut(&mut handler).cast(),
                )
            } else {
                c::R4SdkServiceLoopDrain2(
                    self.endpoint.owner.context2,
                    &mut self.state,
                    announced,
                    Some(invoke::<F>),
                    core::ptr::from_mut(&mut handler).cast(),
                )
            }
        }
    }
    pub fn format_report(&self, name: &[u8], out: &mut [u8]) -> Result<usize> {
        let rc = unsafe {
            if self.endpoint.owner.context2.is_null() {
                c::R4SdkServiceLoopReport(
                    self.endpoint.owner.context,
                    &self.state,
                    name.as_ptr().cast(),
                    length(name.len())?,
                    out.as_mut_ptr(),
                    length(out.len())?,
                )
            } else {
                c::R4SdkServiceLoopReport2(
                    self.endpoint.owner.context2,
                    &self.state,
                    name.as_ptr().cast(),
                    length(name.len())?,
                    out.as_mut_ptr(),
                    length(out.len())?,
                )
            }
        };
        if rc < 0 {
            Err(Error::Raw(rc))
        } else if rc as usize > out.len() {
            Err(Error::InvalidProvider)
        } else {
            Ok(rc as usize)
        }
    }
}
pub struct Batch<'a, 'b> {
    owner: &'a mut ServiceLoop<'b>,
    state: c::R4SdkServiceBatch,
}
impl Batch<'_, '_> {
    pub fn next_request(&mut self) -> Result<BatchStep> {
        let v = unsafe {
            if self.owner.endpoint.owner.context2.is_null() {
                c::R4SdkServiceBatchNext(
                    self.owner.endpoint.owner.context,
                    &mut self.owner.state,
                    &mut self.state,
                )
            } else {
                c::R4SdkServiceBatchNext2(
                    self.owner.endpoint.owner.context2,
                    &mut self.owner.state,
                    &mut self.state,
                )
            }
        };
        match v.kind {
            0 => Ok(BatchStep::Request),
            1 => Ok(BatchStep::Complete),
            2 => Ok(BatchStep::Yielded),
            _ => Err(Error::Raw(v.value)),
        }
    }
}

pub use actions::{ActionReply, ActionRequest, ActionToken, action_frame_ready, prepare_actions};
