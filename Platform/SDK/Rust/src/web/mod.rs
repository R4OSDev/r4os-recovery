//! The original SDK HTML/CSS/layout/JavaScript/canvas engines. Storage is
//! supplied by the caller, so even the large JavaScript realm never needs a
//! temporary stack copy. Its exclusive storage loan pins the native address.
//! `raw` also exposes the complete typed owner surface, including advanced
//! font/image/form/runtime operations and their original retained loans.
use crate::{c_facades as c, data};
use core::{ffi::c_void, marker::PhantomData, mem::MaybeUninit};
pub mod raw {
    pub use crate::c_facades::*;
}
pub use data::{Error, Result};
mod document;
pub use document::{Document, Reflow, Stylesheet};
mod script;
pub use script::Script;
mod canvas;
pub use canvas::Canvas;
pub mod transport;

pub(crate) fn result(v: c::R4SdkWebSlot) -> Result<c::R4SdkWebSlot> {
    data::result(c::R4SdkDataSlot {
        ptr: v.ptr,
        length: v.length,
        bits: v.bits,
        status: v.status,
        flags: v.flags,
    })?;
    Ok(v)
}
pub(crate) fn required(v: c::R4SdkWebSlot) -> Result<c::R4SdkWebSlot> {
    let v = result(v)?;
    if v.flags & 1 == 0 {
        Err(Error::Unavailable)
    } else {
        Ok(v)
    }
}
pub(crate) fn scalar(v: c::R4SdkWebSlot) -> Result<u64> {
    Ok(required(v)?.bits)
}
pub(crate) fn output_view<T>(v: c::R4SdkWebSlot, owner: &[T]) -> Result<&[T]> {
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
pub(crate) fn object_view<T>(v: c::R4SdkWebSlot, owner: &MaybeUninit<T>) -> Result<&[u8]> {
    data::object_view(
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

/// Borrows the exact original arena until all programs/surfaces are freed.
pub struct Memory<'s, 'a> {
    pub(crate) native: *mut c::R4SdkWebMemory,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkWebMemory>>,
    _arena: PhantomData<&'a mut ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'a> Memory<'s, 'a> {
    /// # Safety
    /// Preserve this adapter, its original allocator and every outstanding loan
    /// until the final native program/surface/realm destruction has returned.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkWebMemory {
        self.native
    }
    pub fn from_arena(
        storage: &'s mut MaybeUninit<c::R4SdkWebMemory>,
        arena: &'a mut data::Arena<'_, '_>,
    ) -> Result<Self> {
        let allocator = arena.allocator()?;
        result(unsafe { c::R4SdkWeb_memory(0, storage.as_mut_ptr(), allocator.as_ptr()) })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _arena: PhantomData,
            _local: PhantomData,
        })
    }
    /// # Safety
    /// The original allocator and all its backing/context remain valid through
    /// this adapter and every derived realm/surface, including deinit callbacks.
    pub unsafe fn from_native(
        storage: &'s mut MaybeUninit<c::R4SdkWebMemory>,
        allocator: &c::R4SdkDataAllocator,
    ) -> Result<Self> {
        result(unsafe { c::R4SdkWeb_memory(0, storage.as_mut_ptr(), allocator) })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _arena: PhantomData,
            _local: PhantomData,
        })
    }
}
pub type CallbackFn = unsafe extern "C" fn(
    *mut c_void,
    u32,
    *const c::R4SdkWebSlot,
    u32,
    *mut c_void,
) -> c::R4SdkWebSlot;
/// The callback table and caller state are borrowed at stable addresses.
/// It contains a C function pointer; original Zig hooks always use SDK adapters.
pub struct Callbacks<'s, 'u> {
    pub(crate) native: *const c::R4SdkWebCallbackTable,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkWebCallbackTable>>,
    _user: PhantomData<&'u mut ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'u> Callbacks<'s, 'u> {
    /// # Safety
    /// Every enabled kind obeys its original signature and retention rules.
    /// Inputs borrow only this callback invocation. Aggregate/float results
    /// initialize exactly the supplied output object; error names must be
    /// resident. GC hooks may not allocate, execute JS or recursively collect.
    /// Reentrant callbacks may not create overlapping Rust mutable references.
    pub unsafe fn open<T>(
        storage: &'s mut MaybeUninit<c::R4SdkWebCallbackTable>,
        user: &'u mut T,
        mask: u64,
        invoke: CallbackFn,
    ) -> Result<Self> {
        result(unsafe {
            c::R4SdkWebCallbackTable_from_fields(
                storage.as_mut_ptr(),
                c::R4SdkWebSlot {
                    ptr: (user as *mut T).cast(),
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 1,
                },
                mask,
                c::R4SdkWebSlot {
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
    /// Preserve the descriptor/state loans for every native object retaining it.
    pub unsafe fn native(&self) -> *const c::R4SdkWebCallbackTable {
        self.native
    }
}
