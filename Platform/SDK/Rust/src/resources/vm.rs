use super::*;
#[must_use = "the VM owner requires its exact release acknowledgement"]
pub struct VmRegion<'a> {
    raw: c::R4VmRegion,
    _owner: &'a Resources<'a>,
}
impl Resources<'_> {
    pub fn reserve_vm(&self, size: u64, alignment: u64, flags: u64) -> Result<VmRegion<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe {
            c::r4_resources_reserve_vm(&mut self.raw(), size, alignment, flags, &mut raw)
        })?;
        Ok(VmRegion { raw, _owner: self })
    }
}
impl VmRegion<'_> {
    pub fn valid(&self) -> bool {
        unsafe { c::r4_vm_region_valid(&self.raw) != 0 }
    }
    pub fn info(&mut self) -> Result<abi::ProgramVmRegionInfo> {
        let mut value = abi::ProgramVmRegionInfo::default();
        exact(unsafe { c::r4_vm_region_query(&mut self.raw, &mut value) })?;
        Ok(value)
    }
    pub fn commit(&mut self, offset: u64, length: u64) -> Result<()> {
        self.commit_flags(offset, length, 0)
    }
    pub fn commit_flags(&mut self, offset: u64, length: u64, flags: u64) -> Result<()> {
        exact(unsafe { c::r4_vm_region_commit_flags(&mut self.raw, offset, length, flags) })
    }
    pub fn decommit(&mut self, offset: u64, length: u64) -> Result<()> {
        exact(unsafe { c::r4_vm_region_decommit(&mut self.raw, offset, length) })
    }
    pub fn release(&mut self) -> Result<()> {
        exact(unsafe { c::r4_vm_region_release(&mut self.raw) })
    }
    /// # Safety
    /// This complete range is committed, writable, initialized and disjoint
    /// from other live references. Retain those properties until the borrow
    /// ends. Counts in VM metadata alone do not establish page coverage.
    pub unsafe fn bytes_mut(&mut self, offset: u64, length: usize) -> Result<&mut [u8]> {
        let info = self.info()?;
        let end = offset.checked_add(length as u64).ok_or(Error::Length)?;
        let address = info.base.checked_add(offset).ok_or(Error::Length)?;
        if end > info.len || address == 0 || length > isize::MAX as usize {
            return Err(Error::Length);
        }
        Ok(unsafe { core::slice::from_raw_parts_mut(address as *mut u8, length) })
    }
}
