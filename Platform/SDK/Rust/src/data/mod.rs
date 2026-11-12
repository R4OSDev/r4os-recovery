//! Original SDK data algorithms and protocol facades. No parser, codec or
//! cryptographic implementation is duplicated in Rust. `raw` retains every
//! typed native operation and its original pointer/allocator/job contracts.
use crate::{App, c_facades as c};
use core::{
    marker::{PhantomData, PhantomPinned},
    mem::MaybeUninit,
    pin::Pin,
};
pub mod raw {
    pub use crate::c_facades::*;
}
mod text;
pub use text::{Decoder, Encoding, SearchParams, encode_into, resolve_url};
mod hash;
pub use hash::{MemoryPolicy, Random, Sha256, digest};
mod json;
pub use json::Json;
mod metadata;
pub use metadata::{Arena, ArenaStorage, Manifest};
mod image;
pub use image::{Bitmap as IconBitmap, Icon, Raster};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Transport(i32),
    Native(&'static str),
    Unavailable,
    InvalidNative,
    Bounds,
}
pub type Result<T> = core::result::Result<T, Error>;
pub(crate) fn result(value: c::R4SdkDataSlot) -> Result<c::R4SdkDataSlot> {
    if value.status != 0 {
        return Err(Error::Transport(value.status));
    }
    if value.flags & 2 != 0 {
        if value.ptr.is_null() || value.length == 0 || value.length > 255 {
            return Err(Error::InvalidNative);
        }
        // Native error names are immutable resident SDK literals.
        let bytes = unsafe { core::slice::from_raw_parts(value.ptr.cast(), value.length as usize) };
        return Err(Error::Native(
            core::str::from_utf8(bytes).map_err(|_| Error::InvalidNative)?,
        ));
    }
    Ok(value)
}
pub(crate) fn required(value: c::R4SdkDataSlot) -> Result<c::R4SdkDataSlot> {
    let v = result(value)?;
    if v.flags & 1 == 0 {
        Err(Error::Unavailable)
    } else {
        Ok(v)
    }
}
pub(crate) fn scalar(value: c::R4SdkDataSlot) -> Result<u64> {
    Ok(required(value)?.bits)
}
pub(crate) fn view<T>(value: c::R4SdkDataSlot, owner: &[T]) -> Result<&[T]> {
    let v = required(value)?;
    let count = usize::try_from(v.length).map_err(|_| Error::Bounds)?;
    if count == 0 {
        return Ok(&owner[..0]);
    }
    let ptr = v.ptr as usize;
    let start = owner.as_ptr() as usize;
    let width = core::mem::size_of::<T>();
    if width == 0 || ptr < start || !(ptr - start).is_multiple_of(width) {
        return Err(Error::InvalidNative);
    }
    let offset = (ptr - start) / width;
    owner
        .get(offset..offset.checked_add(count).ok_or(Error::Bounds)?)
        .ok_or(Error::InvalidNative)
}
/// The original owner selects initialized bytes within its own storage; no
/// foreign code reads the rest of the private representation or its padding.
pub(crate) fn object_view<T>(value: c::R4SdkDataSlot, owner: &MaybeUninit<T>) -> Result<&[u8]> {
    let v = required(value)?;
    let n = usize::try_from(v.length).map_err(|_| Error::Bounds)?;
    if n == 0 {
        return Ok(&[]);
    }
    let start = owner.as_ptr() as usize;
    let ptr = v.ptr as usize;
    if ptr < start
        || ptr - start > core::mem::size_of::<T>()
        || n > core::mem::size_of::<T>() - (ptr - start)
    {
        return Err(Error::InvalidNative);
    }
    Ok(unsafe { core::slice::from_raw_parts(v.ptr.cast(), n) })
}
pub(crate) fn optional_bytes(bytes: Option<&[u8]>) -> c::R4SdkDataSlot {
    match bytes {
        Some(b) => c::R4SdkDataSlot {
            ptr: b.as_ptr().cast_mut().cast(),
            length: b.len() as u64,
            bits: 0,
            status: 0,
            flags: 1,
        },
        None => c::R4SdkDataSlot {
            ptr: core::ptr::null_mut(),
            length: 0,
            bits: 0,
            status: 0,
            flags: 0,
        },
    }
}
pub struct DataStorage {
    native: MaybeUninit<c::R4SdkDataContext>,
    _pin: PhantomPinned,
}
impl DataStorage {
    pub const fn new() -> Self {
        Self {
            native: MaybeUninit::uninit(),
            _pin: PhantomPinned,
        }
    }
}
impl Default for DataStorage {
    fn default() -> Self {
        Self::new()
    }
}
pub struct Data<'s, 'a> {
    native: *const c::R4SdkDataContext,
    _storage: PhantomData<Pin<&'s mut DataStorage>>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'a> Data<'s, 'a> {
    pub fn open(storage: Pin<&'s mut DataStorage>, app: &'a App<'_>) -> Result<Self> {
        // Capture once before native subcontexts acquire self-pointers.
        let native = unsafe { storage.get_unchecked_mut() }.native.as_mut_ptr();
        if scalar(unsafe { c::R4SdkData_open(0, native, app.start_context()) })? != 1 {
            return Err(Error::Unavailable);
        }
        Ok(Self {
            native,
            _storage: PhantomData,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn json<'c, 'b>(&'c self, bytes: &'b [u8], depth: &'b mut [u8]) -> Result<Json<'c, 'b>> {
        Json::open(self, bytes, depth)
    }
    pub fn sha256(&self) -> Result<Sha256<'_>> {
        Sha256::open(Some(self.native))
    }
    pub fn random(&self) -> Result<Random<'_>> {
        Random::open(self.native)
    }
    /// # Safety
    /// Retain this Data loan, its pinned storage and App through all derived
    /// views/jobs. Preserve every original native context and buffer contract.
    pub unsafe fn native(&self) -> *const c::R4SdkDataContext {
        self.native
    }
}
