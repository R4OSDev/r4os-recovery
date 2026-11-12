//! Shared subsystem catalogue, launch, window/input, cooperative runtime and
//! persistence owners. `raw` exposes every typed original native operation.
//! Native views retain their exact source/context/buffer and callback loans.
use crate::{c_facades as c, data};
use core::{ffi::c_void, marker::PhantomData, mem::MaybeUninit};
pub use data::{Error, Result};
pub mod raw {
    pub use crate::c_facades::*;
}
mod launch;
pub use launch::{Launch, LaunchOption, encode_launch};
mod clock;
pub use clock::{Clock, Pacer};
mod runtime;
pub use runtime::{Command, Config, Cycle, Runtime};
fn result(v: c::R4SdkSubsystemSlot) -> Result<c::R4SdkSubsystemSlot> {
    data::result(c::R4SdkDataSlot {
        ptr: v.ptr,
        length: v.length,
        bits: v.bits,
        status: v.status,
        flags: v.flags,
    })?;
    Ok(v)
}
fn required(v: c::R4SdkSubsystemSlot) -> Result<c::R4SdkSubsystemSlot> {
    let v = result(v)?;
    if v.flags & 1 == 0 {
        Err(Error::Unavailable)
    } else {
        Ok(v)
    }
}
fn view(v: c::R4SdkSubsystemSlot, owner: &[u8]) -> Result<&[u8]> {
    data::view(
        c::R4SdkDataSlot {
            ptr: v.ptr,
            length: v.length,
            bits: v.bits,
            status: v.status,
            flags: v.flags,
        },
        owner,
    )
}
pub type CallbackFn = unsafe extern "C" fn(
    *mut c_void,
    u32,
    *const c::R4SdkSubsystemSlot,
    u32,
    *mut c_void,
) -> c::R4SdkSubsystemSlot;
/// Exact original callback descriptor; it does not own guest or media policy.
pub struct Callbacks<'s, 'u> {
    native: *const c::R4SdkSubsystemCallbackTable,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkSubsystemCallbackTable>>,
    _user: PhantomData<&'u mut ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'u> Callbacks<'s, 'u> {
    /// # Safety
    /// Every enabled kind follows its original signature and initializes the
    /// exact native output supplied by the SDK. Arguments are synchronous
    /// loans; never retain them or reenter overlapping Rust loans. Stateful
    /// host, audio and save backends retain their real resource identities
    /// until actual close/drain/release. Busy never means completion. Named
    /// callback errors are resident declared native errors, never Zig numbers.
    pub unsafe fn open<T>(
        storage: &'s mut MaybeUninit<c::R4SdkSubsystemCallbackTable>,
        user: &'u mut T,
        mask: u64,
        invoke: CallbackFn,
    ) -> Result<Self> {
        result(unsafe {
            c::R4SdkSubsystemCallbackTable_from_fields(
                storage.as_mut_ptr(),
                c::R4SdkSubsystemSlot {
                    ptr: (user as *mut T).cast(),
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 1,
                },
                mask,
                c::R4SdkSubsystemSlot {
                    ptr: invoke as *const () as *mut c_void,
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 1,
                },
            )
        })?;
        Ok(Self {
            native: storage.as_ptr(),
            _storage: PhantomData,
            _user: PhantomData,
            _local: PhantomData,
        })
    }
    /// # Safety
    /// Derived drivers/streams/stores borrow both descriptor and user state.
    /// Keep the exact addresses through the last original close/drain/release.
    pub unsafe fn native(&self) -> *const c::R4SdkSubsystemCallbackTable {
        self.native
    }
}

mod catalog;
pub use catalog::{Candidate, Catalog, Resolution};
