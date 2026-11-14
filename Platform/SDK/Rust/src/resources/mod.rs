//! Native instance resources. Contexts stay local; close and completion are
//! explicit. Borrowed asynchronous buffers require unsafe admission because
//! forgetting a Rust request does not cancel a native worker.
pub use crate::storage::{Error, Result};
use crate::{App, abi, c_facades as c, path::FilePath};
use core::{ffi::CStr, marker::PhantomData};
mod io;
mod notification;
mod process;
mod thread;
mod vm;
#[cfg(feature = "alloc")]
pub use io::{IoBuffers, IoOpenError, OwnedIo};
pub use io::{IoControl, IoOperation, IoRequest, WriteKind};
pub use notification::{Notification, StopFlag};
pub use process::{Inventory, Lifecycle, Observation, Process};
pub use thread::{JoinHandle, Placement};
pub use vm::VmRegion;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Timeout {
    Poll,
    AfterNanos(u64),
    Forever,
}
impl Timeout {
    pub(crate) fn raw(self) -> abi::R4Timeout {
        let mut value = abi::R4Timeout::default();
        match self {
            Self::Poll => value.kind = abi::timeout_kind_poll,
            Self::AfterNanos(n) => {
                value.kind = abi::timeout_kind_finite;
                value.nanoseconds = n;
            }
            Self::Forever => value.kind = abi::timeout_kind_forever,
        }
        value
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Wait<T> {
    Completed(T),
    WouldBlock,
    TimedOut,
}
pub(crate) fn exact(raw: i32) -> Result<()> {
    if raw == 0 {
        Ok(())
    } else {
        Err(Error::Raw(raw))
    }
}
pub(crate) fn outcome(value: c::R4ResourceWait) -> Result<Wait<i32>> {
    match value.kind {
        0 => Ok(Wait::Completed(value.value)),
        1 => Ok(Wait::WouldBlock),
        2 => Ok(Wait::TimedOut),
        _ => Err(Error::Raw(value.value)),
    }
}
pub(crate) fn path(value: &FilePath) -> c::R4PathZ {
    c::R4PathZ {
        ptr: value.as_c_str().as_ptr().cast(),
        length: value.as_bytes().len() as u16,
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct LocalPublication {
    pub value: u64,
    pub inserted: bool,
}

pub struct Resources<'a> {
    app: c::R4App,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Resources<'a> {
    /// # Safety
    /// This resources object and its application stay stationary and resident
    /// throughout every synchronous native call using the returned descriptor.
    /// Preserve each operation's ownership, generation and buffer contracts.
    pub unsafe fn native(&self) -> c::R4Resources {
        self.raw()
    }
    pub fn new(app: &'a App<'_>) -> Result<Self> {
        Self::new2(app)
    }
    pub fn new2(app: &'a crate::app2::App<'_>) -> Result<Self> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe { c::R4SdkAppFacade2(app.native_context(), &app.memory, &mut raw) })?;
        Ok(Self {
            app: raw,
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    pub(crate) fn raw(&self) -> c::R4Resources {
        // Existing C operations read this immutable App; mutable parameters
        // refer to their own operation/handle state, never to the App.
        c::R4Resources {
            app: core::ptr::from_ref(&self.app).cast_mut(),
        }
    }
    pub fn available(&self) -> bool {
        unsafe { c::r4_resources_available(&self.raw()) != 0 }
    }
    pub fn timeout_ticks(&self, timeout: Timeout) -> Result<u64> {
        let mut ticks = 0;
        exact(unsafe { c::r4_resource_timeout_ticks(&mut self.raw(), timeout.raw(), &mut ticks) })?;
        Ok(ticks)
    }
    pub fn capacity(&self) -> Result<abi::CpuCapacity> {
        let mut value = abi::CpuCapacity::default();
        exact(unsafe { c::r4_resources_cpu_capacity(&mut self.raw(), &mut value) })?;
        Ok(value)
    }
    pub fn local_get(&self, key: u64) -> Result<u64> {
        let mut value = 0;
        exact(unsafe { c::r4_resources_program_local_get(&mut self.raw(), key, &mut value) })?;
        Ok(value)
    }
    pub fn local_publish(&self, key: u64, value: u64) -> Result<LocalPublication> {
        let mut actual = 0;
        let raw = unsafe {
            c::r4_resources_program_local_publish(&mut self.raw(), key, value, &mut actual)
        };
        match raw {
            abi::program_local_ok => Ok(LocalPublication {
                value: actual,
                inserted: true,
            }),
            abi::program_local_existing => Ok(LocalPublication {
                value: actual,
                inserted: false,
            }),
            _ => Err(Error::Raw(raw)),
        }
    }
    pub fn module_path(&self, buffer: &mut [u8]) -> Result<usize> {
        let raw = unsafe {
            c::r4_resources_program_module_path(
                &mut self.raw(),
                buffer.as_mut_ptr(),
                crate::storage::length(buffer.len())?,
            )
        };
        if raw < 0 {
            return Err(Error::Raw(raw));
        }
        if raw as usize > buffer.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(raw as usize)
    }
    pub fn module_running(&self, path: &FilePath) -> Result<bool> {
        let raw = unsafe {
            c::r4_resources_program_module_running(&mut self.raw(), path.as_c_str().as_ptr().cast())
        };
        if raw < 0 {
            Err(Error::Raw(raw))
        } else {
            Ok(raw != 0)
        }
    }
    /// Native program_run dispatch: returns call status, not the child's exit
    /// code. No mutable App/Resources borrow crosses the foreign entry.
    pub fn run(&self, path: &FilePath, args: &CStr) -> i32 {
        unsafe {
            c::r4_resources_program_run(
                &mut self.raw(),
                path.as_c_str().as_ptr().cast(),
                args.as_ptr().cast(),
            )
        }
    }
    pub fn launch(&self, path: &FilePath, args: &CStr, policy: abi::LaunchPolicy) -> i32 {
        unsafe {
            c::r4_resources_program_launch(
                &mut self.raw(),
                path.as_c_str().as_ptr().cast(),
                args.as_ptr().cast(),
                policy.0,
            )
        }
    }
    /// Raw non-owning instance launch, distinct from a generation-bound spawn.
    pub fn spawn_instance(&self, path: &FilePath, args: &CStr, policy: abi::LaunchPolicy) -> i32 {
        unsafe {
            c::r4_resources_program_spawn(
                &mut self.raw(),
                path.as_c_str().as_ptr().cast(),
                args.as_ptr().cast(),
                policy.0,
            )
        }
    }
    pub fn class(&self, path: &FilePath, policy: abi::LaunchPolicy) -> i32 {
        unsafe {
            c::r4_resources_program_class(
                &mut self.raw(),
                path.as_c_str().as_ptr().cast(),
                policy.0,
            )
        }
    }
    pub fn instance(&self, index: u32) -> Result<abi::ProgramInstanceInfo> {
        let mut value = abi::ProgramInstanceInfo::default();
        exact(unsafe { c::r4_resources_program_instance(&mut self.raw(), index, &mut value) })?;
        Ok(value)
    }
    pub fn yield_now(&self) {
        unsafe { c::r4_resource_yield(self.raw().app) }
    }
    pub fn program_status(&self) -> Result<abi::ProgramStatus> {
        let mut value = abi::ProgramStatus::default();
        exact(unsafe { c::r4_resources_program_status(&mut self.raw(), &mut value) })?;
        Ok(value)
    }
    pub fn set_console_host(&self, id: u32, host: abi::ConsoleHostKind) -> Result<()> {
        exact(unsafe { c::r4_resources_program_set_console_host(&mut self.raw(), id, host.0) })
    }
    pub fn current_console_host(&self) -> abi::ConsoleHostKind {
        abi::ConsoleHostKind(unsafe {
            c::r4_resources_program_current_console_host(&mut self.raw())
        })
    }
    pub fn request_desktop(&self) -> Result<()> {
        exact(unsafe { c::r4_resources_program_request_desktop(&mut self.raw()) })
    }
    pub fn spawn_instance_with_console_host(
        &self,
        file: &FilePath,
        args: &CStr,
        policy: abi::LaunchPolicy,
        host: abi::ConsoleHostKind,
    ) -> i32 {
        unsafe {
            c::r4_resources_program_spawn_with_console_host(
                &mut self.raw(),
                file.as_c_str().as_ptr().cast(),
                args.as_ptr().cast(),
                policy.0,
                host.0,
            )
        }
    }
    /// Raw ID operations retain their distinct native semantics. They never
    /// replace a failed generation-bound operation.
    pub fn request_close_instance(&self, id: u32) -> i32 {
        unsafe { c::r4_resources_program_request_close(&mut self.raw(), id) }
    }
    pub fn kill_instance(&self, id: u32) -> i32 {
        unsafe { c::r4_resources_program_kill(&mut self.raw(), id) }
    }
    pub fn reap_instance(&self, id: u32) -> i32 {
        unsafe { c::r4_resources_program_reap_instance(&mut self.raw(), id) }
    }
    /// # Safety
    /// Terminate only the intended current instance, with no live Rust loans
    /// into foreign code. An accepted transition does not return.
    pub unsafe fn exit_process(&self, code: i32, reason: u32) -> Result<core::convert::Infallible> {
        let raw = unsafe { c::r4_resources_program_exit(&mut self.raw(), code, reason) };
        Err(if raw == 0 {
            Error::InvalidProvider
        } else {
            Error::Raw(raw)
        })
    }
}
