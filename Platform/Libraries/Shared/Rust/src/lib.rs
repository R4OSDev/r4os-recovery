#![no_std]
//! Higher library consumers. Link the library-owned helper objects explicitly;
//! the platform SDK does not contain a second standard/codec/font library.
extern crate alloc;
use alloc::{
    alloc::{Layout, alloc, dealloc},
    boxed::Box,
};
use core::{cell::UnsafeCell, marker::PhantomData, mem::MaybeUninit};
pub use r4os_sdk::abi;
pub use r4os_text_core as text_core;
#[path = "../../../R4FONT/Bindings/Rust/src/helpers.rs"]
pub mod font;
#[path = "../../../R4GFX/Bindings/Rust/src/helpers.rs"]
pub mod graphics;
#[path = "../../../R4IMG/Bindings/Rust/src/helpers.rs"]
pub mod image;
#[path = "../../../R4ENC/Bindings/Rust/src/helpers.rs"]
pub mod media;
pub mod raw;
#[path = "../../../R4STD/Bindings/Rust/src/helpers.rs"]
pub mod standard;
#[path = "../../../R4VIDEO/Bindings/Rust/src/helpers.rs"]
pub mod video;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Transport(i32),
    Native(&'static str),
    Unavailable,
    InvalidProvider,
}
pub type Result<T> = core::result::Result<T, Error>;
pub(crate) fn result(value: raw::R4LibrariesSlot) -> Result<raw::R4LibrariesSlot> {
    if value.status != 0 {
        return Err(Error::Transport(value.status));
    }
    if value.flags & 2 != 0 {
        if value.ptr.is_null() || value.length > 256 {
            return Err(Error::InvalidProvider);
        }
        // The bridge returns the original resident Zig error-name literal.
        let bytes = unsafe { core::slice::from_raw_parts(value.ptr.cast(), value.length as usize) };
        return Err(Error::Native(
            core::str::from_utf8(bytes).map_err(|_| Error::InvalidProvider)?,
        ));
    }
    Ok(value)
}
pub(crate) fn required(value: raw::R4LibrariesSlot) -> Result<raw::R4LibrariesSlot> {
    let value = result(value)?;
    if value.flags & 1 == 0 {
        Err(Error::Unavailable)
    } else {
        Ok(value)
    }
}
pub(crate) fn scalar(value: raw::R4LibrariesSlot) -> Result<u64> {
    Ok(required(value)?.bits)
}
pub(crate) fn storage<T>() -> Box<MaybeUninit<T>> {
    Box::new(MaybeUninit::uninit())
}
pub(crate) fn view<T>(value: raw::R4LibrariesSlot, owner: &[T]) -> Result<&[T]> {
    let value = required(value)?;
    let count = usize::try_from(value.length).map_err(|_| Error::InvalidProvider)?;
    if count == 0 {
        return Ok(&owner[..0]);
    }
    let start = owner.as_ptr() as usize;
    let ptr = value.ptr as usize;
    let width = core::mem::size_of::<T>();
    if width == 0 || ptr < start || !(ptr - start).is_multiple_of(width) {
        return Err(Error::InvalidProvider);
    }
    let offset = (ptr - start) / width;
    owner
        .get(offset..offset.checked_add(count).ok_or(Error::InvalidProvider)?)
        .ok_or(Error::InvalidProvider)
}

/// A stable callback descriptor over Rust's existing allocator. Every native
/// object borrowing it retains a Rust loan; allocation algorithms stay native.
pub struct Heap {
    native: Box<UnsafeCell<MaybeUninit<raw::R4LibraryMemory>>>,
    _local: PhantomData<*mut ()>,
}
impl Heap {
    pub fn new() -> Result<Self> {
        let native = Box::new(UnsafeCell::new(MaybeUninit::uninit()));
        result(unsafe {
            raw::R4LibraryMemory_create(
                native.get().cast(),
                allocate as *const () as usize as u64,
                release as *const () as usize as u64,
            )
        })?;
        Ok(Self {
            native,
            _local: PhantomData,
        })
    }
    pub(crate) fn allocator(&self) -> Result<MaybeUninit<raw::R4LibraryAllocator>> {
        let mut out = MaybeUninit::uninit();
        required(unsafe {
            raw::R4LibraryMemory_allocator(0, self.native.get().cast(), out.as_mut_ptr())
        })?;
        Ok(out)
    }
}
unsafe extern "C" fn allocate(
    _: *mut core::ffi::c_void,
    bytes: usize,
    alignment: usize,
) -> *mut u8 {
    let Ok(layout) = Layout::from_size_align(bytes.max(1), alignment) else {
        return core::ptr::null_mut();
    };
    unsafe { alloc(layout) }
}
unsafe extern "C" fn release(
    _: *mut core::ffi::c_void,
    ptr: *mut u8,
    bytes: usize,
    alignment: usize,
) {
    if let Ok(layout) = Layout::from_size_align(bytes.max(1), alignment) {
        unsafe { dealloc(ptr, layout) };
    }
}
