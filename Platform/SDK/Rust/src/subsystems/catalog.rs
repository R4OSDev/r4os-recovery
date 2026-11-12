use super::{Callbacks, Error, MaybeUninit, PhantomData, Result, c, required, result, view};
/// Projection of the single installed MODULES.JSON. Strings and normalized
/// arrays borrow the input and its validated native inventory workspace.
pub struct Catalog<'s, 'w, 'b> {
    native: *mut c::R4SdkSubsystemCatalogCatalog,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkSubsystemCatalogCatalog>>,
    _workspace: PhantomData<&'w mut MaybeUninit<c::R4SdkUpdateInventoryInventory>>,
    _source: PhantomData<&'b [u8]>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'w, 'b> Catalog<'s, 'w, 'b> {
    pub fn load(
        storage: &'s mut MaybeUninit<c::R4SdkSubsystemCatalogCatalog>,
        workspace: &'w mut MaybeUninit<c::R4SdkUpdateInventoryInventory>,
        source: &'b [u8],
        verifier: &Callbacks<'_, '_>,
    ) -> Result<Self> {
        let mut verify = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkSubsystem_hostVerifier(0, verifier.native, verify.as_mut_ptr())
        })?;
        result(unsafe {
            c::R4SdkSubsystemCatalogCatalog_loadInstalled(
                0,
                source.as_ptr(),
                source.len() as u64,
                workspace.as_mut_ptr(),
                storage.as_mut_ptr(),
                verify.as_ptr(),
            )
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _workspace: PhantomData,
            _source: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn count(&self) -> Result<usize> {
        Ok(
            required(unsafe { c::R4SdkSubsystemCatalogCatalog_get_count(self.native) })?.bits
                as usize,
        )
    }
    pub fn render<'o>(&self, out: &'o mut [u8]) -> Result<&'o [u8]> {
        view(
            required(unsafe {
                c::R4SdkSubsystemCatalogCatalog_render(
                    0,
                    self.native,
                    out.as_mut_ptr(),
                    out.len() as u64,
                )
            })?,
            out,
        )
    }
    pub fn resolve<'a>(
        &'a self,
        path: &'a [u8],
        prefix: &'a [u8],
        size: u64,
        complete: bool,
    ) -> Result<Resolution<'a>> {
        let mut input = MaybeUninit::uninit();
        let mut policy = MaybeUninit::uninit();
        let mut out = Resolution {
            native: MaybeUninit::uninit(),
            _catalog: PhantomData,
            _local: PhantomData,
        };
        result(unsafe {
            c::R4SdkSubsystemCatalogInput_create(
                input.as_mut_ptr(),
                path.as_ptr(),
                path.len() as u64,
                prefix.as_ptr(),
                prefix.len() as u64,
                size,
                u8::from(complete),
            )
        })?;
        result(unsafe { c::R4SdkSubsystemCatalogPolicy_create(policy.as_mut_ptr()) })?;
        result(unsafe {
            c::R4SdkSubsystemCatalog_resolve(
                0,
                self.native,
                input.as_ptr(),
                policy.as_ptr(),
                out.native.as_mut_ptr(),
            )
        })?;
        Ok(out)
    }
    /// # Safety
    /// Preserve the inventory/input loans and all original catalogue invariants.
    pub unsafe fn native(&self) -> *const c::R4SdkSubsystemCatalogCatalog {
        self.native
    }
}
pub struct Resolution<'a> {
    native: MaybeUninit<c::R4SdkSubsystemCatalogResolution>,
    _catalog: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl Resolution<'_> {
    pub fn state(&self) -> Result<u32> {
        Ok(
            required(unsafe { c::R4SdkSubsystemCatalogResolution_get_state(self.native.as_ptr()) })?
                .bits as u32,
        )
    }
    pub fn count(&self) -> Result<usize> {
        Ok(
            required(unsafe { c::R4SdkSubsystemCatalogResolution_get_count(self.native.as_ptr()) })?
                .bits as usize,
        )
    }
    pub fn selected(&self) -> Result<Option<Candidate<'_>>> {
        let mut out = Candidate {
            native: MaybeUninit::uninit(),
            _resolution: PhantomData,
        };
        let v = result(unsafe {
            c::R4SdkSubsystemCatalogResolution_selected(
                0,
                self.native.as_ptr(),
                out.native.as_mut_ptr(),
            )
        })?;
        if v.flags & 1 == 0 {
            Ok(None)
        } else {
            Ok(Some(out))
        }
    }
}
pub struct Candidate<'a> {
    native: MaybeUninit<c::R4SdkSubsystemCatalogCandidate>,
    _resolution: PhantomData<&'a ()>,
}
impl Candidate<'_> {
    fn bytes(&self, v: c::R4SdkSubsystemSlot) -> Result<&[u8]> {
        let v = required(v)?;
        let n = usize::try_from(v.length).map_err(|_| Error::Bounds)?;
        if n == 0 {
            return Ok(&[]);
        }
        if v.ptr.is_null() || n > isize::MAX as usize {
            return Err(Error::InvalidNative);
        }
        Ok(unsafe { core::slice::from_raw_parts(v.ptr.cast(), n) })
    }
    pub fn subsystem_id(&self) -> Result<&[u8]> {
        self.bytes(unsafe {
            c::R4SdkSubsystemCatalogCandidate_get_subsystem_id(self.native.as_ptr())
        })
    }
    pub fn format(&self) -> Result<&[u8]> {
        self.bytes(unsafe { c::R4SdkSubsystemCatalogCandidate_get_format_id(self.native.as_ptr()) })
    }
    pub fn host(&self) -> Result<&[u8]> {
        self.bytes(unsafe { c::R4SdkSubsystemCatalogCandidate_get_host_path(self.native.as_ptr()) })
    }
    pub fn name(&self) -> Result<&[u8]> {
        self.bytes(unsafe {
            c::R4SdkSubsystemCatalogCandidate_get_display_name(self.native.as_ptr())
        })
    }
}
