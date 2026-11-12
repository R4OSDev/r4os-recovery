use super::{Error, MaybeUninit, PhantomData, Result, c, required, result, view};
use crate::data::Data;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Profile {
    Slim = c::R4SdkUpdateInventoryProfile_slim,
    Full = c::R4SdkUpdateInventoryProfile_full,
    Test = c::R4SdkUpdateInventoryProfile_test_image,
}
/// Original strict catalogue schema over JSON.R4P. Its selected strings borrow
/// immutable input; neither the temporary parser nor workspace is retained.
pub struct Catalog<'s, 'b> {
    native: *mut c::R4SdkUpdateCatalogCatalogRelease,
    input: &'b [u8],
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkUpdateCatalogCatalogRelease>>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'b> Catalog<'s, 'b> {
    pub fn parse(
        storage: &'s mut MaybeUninit<c::R4SdkUpdateCatalogCatalogRelease>,
        workspace: &mut MaybeUninit<c::R4SdkUpdateCatalogCatalogRelease>,
        data: &Data<'_, '_>,
        input: &'b [u8],
        depth: &mut [u8],
        profile: Profile,
        local_release: &[u8],
    ) -> Result<Self> {
        if input.len() > u32::MAX as usize || depth.len() > u32::MAX as usize {
            return Err(Error::Bounds);
        }
        let mut document = MaybeUninit::uninit();
        unsafe {
            let v = c::R4SdkData_json(
                0,
                document.as_mut_ptr(),
                data.native(),
                input.as_ptr(),
                input.len() as u64,
                depth.as_mut_ptr(),
                depth.len() as u64,
            );
            crate::data::result(v)?;
            result(c::R4SdkUpdate_parseCatalog(
                0,
                document.as_mut_ptr(),
                profile as u32,
                local_release.as_ptr(),
                local_release.len() as u64,
                workspace.as_mut_ptr(),
                storage.as_mut_ptr(),
            ))?;
        }
        Ok(Self {
            native: storage.as_mut_ptr(),
            input,
            _storage: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn release(&self) -> Result<&[u8]> {
        view(
            unsafe { c::R4SdkUpdateCatalogCatalogRelease_get_release(self.native) },
            self.input,
        )
    }
    pub fn package_count(&self) -> Result<usize> {
        Ok(
            required(unsafe { c::R4SdkUpdateCatalogCatalogRelease_get_package_count(self.native) })?
                .bits as usize,
        )
    }
    pub fn required_count(&self) -> Result<usize> {
        Ok(
            required(unsafe {
                c::R4SdkUpdateCatalogCatalogRelease_get_required_count(self.native)
            })?
            .bits as usize,
        )
    }
    /// # Safety
    /// All input strings remain borrowed; plans/requirements may retain them.
    /// Preserve exact package/component identity and original planner policy.
    pub unsafe fn native(&self) -> *const c::R4SdkUpdateCatalogCatalogRelease {
        self.native
    }
}
