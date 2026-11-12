//! Ordinary resident R4P providers. The kernel serializes each real module
//! callback and binds its exact PPI identity. Resources close explicitly;
//! a logical session receipt never unloads code or proves hardware retirement.
use crate::abi;
use core::{cell::Cell, ffi::CStr, marker::PhantomData, num::NonZeroU64, ptr::NonNull};
pub type Result<T> = core::result::Result<T, i32>;
pub struct Protocol<'a> {
    api: &'a abi::ProtocolApi,
    _local: PhantomData<*mut ()>,
}
impl<'a> Protocol<'a> {
    /// # Safety
    /// The full current immutable loader table remains resident for 'a.
    /// Every call runs under this exact module's current PPI execution scope;
    /// a copied pointer does not grant another task/module ownership.
    pub unsafe fn from_raw(raw: *const abi::ProtocolApi) -> Result<Self> {
        if raw.is_null() || !(raw as usize).is_multiple_of(8) {
            return Err(-1);
        }
        let (magic, version, size) = unsafe { ((*raw).magic, (*raw).version, (*raw).size) };
        if magic != abi::protocol_magic
            || version != abi::protocol_api_version
            || (size as usize) < core::mem::size_of::<abi::ProtocolApi>()
        {
            return Err(-1);
        }
        Ok(Self {
            api: unsafe { &*raw },
            _local: PhantomData,
        })
    }
    pub fn log(&self, text: &CStr) {
        unsafe { (self.api.log_info)(text.as_ptr().cast()) }
    }
    pub fn warn(&self, text: &CStr) {
        unsafe { (self.api.log_warn)(text.as_ptr().cast()) }
    }
    pub fn error(&self, text: &CStr) {
        unsafe { (self.api.log_error)(text.as_ptr().cast()) }
    }
    pub fn register(&self, role: &CStr, category: abi::ProtocolCategory, flags: u32) -> i32 {
        unsafe { (self.api.register_role)(role.as_ptr().cast(), u32::from(category.0), flags) }
    }
    pub fn set_status(&self, state: abi::ProtocolState, note: &CStr) -> i32 {
        unsafe { (self.api.set_status)(state.0, note.as_ptr().cast()) }
    }
    pub fn dependency(&self, role: &CStr) -> i32 {
        unsafe { (self.api.dependency_status)(role.as_ptr().cast()) }
    }
    pub fn read_file(&self, path: &CStr, out: &mut [u8]) -> Result<usize> {
        if out.len() > u32::MAX as usize {
            return Err(-1);
        }
        let n = unsafe {
            (self.api.file_read)(path.as_ptr().cast(), out.as_mut_ptr(), out.len() as u32)
        };
        if n < 0 {
            Err(n)
        } else if n as usize > out.len() {
            Err(-1)
        } else {
            Ok(n as usize)
        }
    }
    pub fn allocate(&self, bytes: u32, alignment: u32) -> Result<Allocation<'_>> {
        if bytes == 0 || !alignment.is_power_of_two() {
            return Err(-1);
        }
        let pointer = NonNull::new(unsafe { (self.api.alloc)(bytes, alignment) }).ok_or(-1)?;
        Ok(Allocation {
            owner: self,
            pointer: Some(pointer),
            bytes,
        })
    }
    /// # Safety
    /// Preserve exact PPI scope, pure-work ISA grants, optional capabilities
    /// and all original pointer/callback lifetimes on advanced raw operations.
    pub unsafe fn raw(&self) -> &abi::ProtocolApi {
        self.api
    }
}
#[must_use = "session/callback backing remains until explicit release after quiescence"]
pub struct Allocation<'a> {
    owner: &'a Protocol<'a>,
    pointer: Option<NonNull<core::ffi::c_void>>,
    bytes: u32,
}
impl Allocation<'_> {
    pub fn pointer(&self) -> Option<NonNull<core::ffi::c_void>> {
        self.pointer
    }
    pub fn bytes(&self) -> u32 {
        self.bytes
    }
    /// # Safety
    /// Every caller/session/dispatch reference is closed, including cancelled
    /// or failed operations. Only the original exact CPU allocation is freed.
    /// The current synchronous ProtocolApi free has no error/result channel.
    pub unsafe fn release(&mut self) {
        if let Some(p) = self.pointer.take() {
            unsafe { (self.owner.api.free)(p.as_ptr(), self.bytes) }
        }
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GateError {
    Busy,
    Closed,
    Stale,
    Exhausted,
}
#[derive(Debug)]
pub struct Closed {
    owner: NonNull<Gate>,
    epoch: u64,
}
/// Local logical admission. Epochs belong to this provider/session, not to
/// kernel module slots. Logical release never frees backing or invokes code.
pub struct Gate {
    epoch: Cell<u64>,
    active: Cell<u32>,
    phase: Cell<u8>,
    _local: PhantomData<*mut ()>,
}
impl Gate {
    pub const fn new(epoch: NonZeroU64) -> Self {
        Self {
            epoch: Cell::new(epoch.get()),
            active: Cell::new(0),
            phase: Cell::new(0),
            _local: PhantomData,
        }
    }
    pub fn enter(&self) -> core::result::Result<Lease<'_>, GateError> {
        if self.phase.get() != 0 {
            return Err(GateError::Closed);
        }
        let active = self
            .active
            .get()
            .checked_add(1)
            .ok_or(GateError::Exhausted)?;
        self.active.set(active);
        Ok(Lease {
            owner: self,
            epoch: self.epoch.get(),
        })
    }
    pub fn close(&self) -> core::result::Result<Closed, GateError> {
        self.phase.set(1);
        if self.active.get() != 0 {
            return Err(GateError::Busy);
        }
        self.phase.set(2);
        Ok(Closed {
            owner: NonNull::from(self),
            epoch: self.epoch.get(),
        })
    }
    pub fn reset(
        &mut self,
        receipt: Closed,
        next: NonZeroU64,
    ) -> core::result::Result<(), GateError> {
        if !core::ptr::eq(self, receipt.owner.as_ptr())
            || self.phase.get() != 2
            || self.active.get() != 0
            || receipt.epoch != self.epoch.get()
            || next.get() <= receipt.epoch
        {
            return Err(GateError::Stale);
        }
        self.epoch.set(next.get());
        self.phase.set(0);
        Ok(())
    }
    pub fn active(&self) -> u32 {
        self.active.get()
    }
    pub fn epoch(&self) -> u64 {
        self.epoch.get()
    }
}
#[must_use = "retain the logical callback/session loan until actual finish"]
pub struct Lease<'a> {
    owner: &'a Gate,
    epoch: u64,
}
impl Drop for Lease<'_> {
    fn drop(&mut self) {
        assert_eq!(self.epoch, self.owner.epoch.get());
        let n = self.owner.active.get();
        assert!(n != 0);
        self.owner.active.set(n - 1);
    }
}
#[macro_export]
macro_rules! protocol_entry{
    ($init:path,$shutdown:path,$query:path,$dispatch:path)=>{
        core::arch::global_asm!(
            ".pushsection .text.r4p_entries,\"ax\",@progbits",
            ".global r4p_init_entry","r4p_init_entry:",".byte 0xe9",".long {init} - . - 4",
            ".global r4p_shutdown_entry","r4p_shutdown_entry:",".byte 0xe9",".long {shutdown} - . - 4",
            ".global r4p_query_entry","r4p_query_entry:",".byte 0xe9",".long {query} - . - 4",
            ".global r4p_dispatch_entry","r4p_dispatch_entry:",".byte 0xe9",".long {dispatch} - . - 4",".popsection",
            init=sym $init,shutdown=sym $shutdown,query=sym $query,dispatch=sym $dispatch);
        const _:unsafe extern "C" fn(*const $crate::abi::ProtocolApi)->i32=$init;
        const _:unsafe extern "C" fn()->i32=$shutdown;
        const _:unsafe extern "C" fn(*mut $crate::abi::ProtocolStatus)->i32=$query;
        const _:unsafe extern "C" fn(u32,*const $crate::abi::ProtocolBuffer,*mut $crate::abi::ProtocolBuffer)->i32=$dispatch;
    };
}
