use super::{Error, Result, required, scalar, view};
use crate::c_facades as c;
use core::{
    marker::{PhantomData, PhantomPinned},
    mem::MaybeUninit,
    pin::Pin,
};
/// The arena and its backing buffer remain pinned/borrowed through every
/// returned manifest. Drop discards caller-owned scratch; no global heap.
pub struct ArenaStorage {
    native: MaybeUninit<c::R4SdkDataArena>,
    _pin: PhantomPinned,
}
impl ArenaStorage {
    pub const fn new() -> Self {
        Self {
            native: MaybeUninit::uninit(),
            _pin: PhantomPinned,
        }
    }
}
impl Default for ArenaStorage {
    fn default() -> Self {
        Self::new()
    }
}
pub struct Arena<'s, 'b> {
    native: *mut c::R4SdkDataArena,
    _storage: PhantomData<Pin<&'s mut ArenaStorage>>,
    _bytes: PhantomData<&'b mut [u8]>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'b> Arena<'s, 'b> {
    pub(crate) fn allocator(&mut self) -> Result<MaybeUninit<c::R4SdkDataAllocator>> {
        let mut value = MaybeUninit::uninit();
        required(unsafe { c::R4SdkData_allocator(0, self.native, value.as_mut_ptr()) })?;
        Ok(value)
    }
    pub fn open(storage: Pin<&'s mut ArenaStorage>, bytes: &'b mut [u8]) -> Result<Self> {
        let native = unsafe { storage.get_unchecked_mut() }.native.as_mut_ptr();
        super::result(unsafe {
            c::R4SdkData_arena(0, native, bytes.as_mut_ptr(), bytes.len() as u64)
        })?;
        Ok(Self {
            native,
            _storage: PhantomData,
            _bytes: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn used(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4SdkData_used(0, self.native) })? as usize)
    }
    pub fn reset(&mut self) -> Result<()> {
        super::result(unsafe { c::R4SdkData_reset(0, self.native) })?;
        Ok(())
    }
    pub fn manifest<'a, 'i>(
        &'a mut self,
        path: &'i [u8],
        text: &'i [u8],
    ) -> Result<Manifest<'a, 'i>> {
        let mut allocator = MaybeUninit::uninit();
        required(unsafe { c::R4SdkData_allocator(0, self.native, allocator.as_mut_ptr()) })?;
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataManifest_parse(
                0,
                allocator.as_ptr(),
                path.as_ptr(),
                path.len() as u64,
                text.as_ptr(),
                text.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Manifest {
            native,
            path,
            text,
            _arena: PhantomData,
        })
    }
}
pub struct Manifest<'a, 'i> {
    native: MaybeUninit<c::R4SdkDataManifestManifest>,
    path: &'i [u8],
    text: &'i [u8],
    _arena: PhantomData<&'a mut ()>,
}
impl Manifest<'_, '_> {
    /// This field is a validated view of the original manifest input. Other
    /// allocated metadata/plan operations remain available in unsafe raw.
    pub fn name(&self) -> Result<&[u8]> {
        view(
            unsafe { c::R4SdkDataManifestManifest_get_name(self.native.as_ptr()) },
            self.text,
        )
    }
    pub fn input_path(&self) -> &[u8] {
        self.path
    }
    pub fn version(&self) -> Result<(u16, u16, u16)> {
        let mut v = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataManifestManifest_get_module_version(self.native.as_ptr(), v.as_mut_ptr())
        })?;
        let one = |n: u64| u16::try_from(n).map_err(|_| Error::InvalidNative);
        Ok((
            one(scalar(unsafe {
                c::R4SdkDataManifestModuleVersion_get_major(v.as_ptr())
            })?)?,
            one(scalar(unsafe {
                c::R4SdkDataManifestModuleVersion_get_minor(v.as_ptr())
            })?)?,
            one(scalar(unsafe {
                c::R4SdkDataManifestModuleVersion_get_patch(v.as_ptr())
            })?)?,
        ))
    }
    pub fn contract_plan<'o>(&self, out: &'o mut [u8]) -> Result<(&'o [u8], bool)> {
        let mut v = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataManifest_renderContractPlan(
                0,
                self.native.as_ptr(),
                out.as_mut_ptr(),
                out.len() as u64,
                v.as_mut_ptr(),
            )
        })?;
        let bytes = view(
            unsafe { c::R4SdkDataManifestRenderResult_get_bytes(v.as_ptr()) },
            out,
        )?;
        Ok((
            bytes,
            scalar(unsafe { c::R4SdkDataManifestRenderResult_get_ok(v.as_ptr()) })? != 0,
        ))
    }
}
