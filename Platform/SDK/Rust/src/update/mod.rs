//! Original update, inventory, journal, recovery and StorageTools owners.
//! The complete typed native surface is in `raw`; advanced borrowed plans
//! retain their exact source/allocator/device loans and explicit receipts.
use crate::{c_facades as c, data};
use core::{ffi::c_void, marker::PhantomData, mem::MaybeUninit};
pub use data::{Error, Result};
pub mod raw {
    pub use crate::c_facades::*;
}
mod journal;
pub use journal::{Inventory, Journal, ReplayStatus};
mod storage;
pub use storage::{Device, Fat32Plan, MemoryBlock};
mod catalog;
pub use catalog::{Catalog, Profile};
mod host;
pub use host::HostFile;
fn result(v: c::R4SdkUpdateSlot) -> Result<c::R4SdkUpdateSlot> {
    data::result(c::R4SdkDataSlot {
        ptr: v.ptr,
        length: v.length,
        bits: v.bits,
        status: v.status,
        flags: v.flags,
    })?;
    Ok(v)
}
fn required(v: c::R4SdkUpdateSlot) -> Result<c::R4SdkUpdateSlot> {
    let v = result(v)?;
    if v.flags & 1 == 0 {
        Err(Error::Unavailable)
    } else {
        Ok(v)
    }
}
fn view(v: c::R4SdkUpdateSlot, out: &[u8]) -> Result<&[u8]> {
    let v = required(v)?;
    data::view(
        c::R4SdkDataSlot {
            ptr: v.ptr,
            length: v.length,
            bits: v.bits,
            status: v.status,
            flags: v.flags,
        },
        out,
    )
}
pub type CallbackFn = unsafe extern "C" fn(
    *mut c_void,
    u32,
    *const c::R4SdkUpdateSlot,
    u32,
    *mut c_void,
) -> c::R4SdkUpdateSlot;
/// Stable, synchronous I/O descriptor. It owns no transaction policy.
pub struct Callbacks<'s, 'u> {
    native: *const c::R4SdkUpdateCallbackTable,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkUpdateCallbackTable>>,
    _user: PhantomData<&'u mut ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'u> Callbacks<'s, 'u> {
    /// # Safety
    /// Each enabled kind obeys its original signature. Slot inputs live only
    /// for the callback. Mutations and journal persistence return true only
    /// after the real exact identity/durability receipt. Never retain native
    /// pointers or reenter overlapping Rust loans. Source callbacks use the
    /// declared SourceError names, not foreign Zig error numbers.
    pub unsafe fn open<T>(
        storage: &'s mut MaybeUninit<c::R4SdkUpdateCallbackTable>,
        user: &'u mut T,
        mask: u64,
        invoke: CallbackFn,
    ) -> Result<Self> {
        result(unsafe {
            c::R4SdkUpdateCallbackTable_from_fields(
                storage.as_mut_ptr(),
                c::R4SdkUpdateSlot {
                    ptr: (user as *mut T).cast(),
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 1,
                },
                mask,
                c::R4SdkUpdateSlot {
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
    pub fn archive(&self) -> Result<()> {
        result(unsafe { c::R4SdkUpdate_archive(0, self.native) })?;
        Ok(())
    }
    /// # Safety
    /// Retain table/user/identities until every derived synchronous operation
    /// returns. Stored plans and devices may retain this descriptor longer.
    pub unsafe fn native(&self) -> *const c::R4SdkUpdateCallbackTable {
        self.native
    }
}
