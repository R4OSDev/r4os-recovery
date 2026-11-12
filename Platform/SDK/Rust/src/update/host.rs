use super::{Device, MaybeUninit, PhantomData, Result, c, required, result};
/// Host-only existing-file adapter. The original HostFile and std.Io backend
/// stay pinned through every device loan. Guest calls report HostOnly.
pub struct HostFile<'s> {
    native: *mut c::R4SdkUpdateHostFile,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkUpdateHostFile>>,
    _local: PhantomData<*mut ()>,
}
impl<'s> HostFile<'s> {
    pub fn open(storage: &'s mut MaybeUninit<c::R4SdkUpdateHostFile>, path: &[u8]) -> Result<Self> {
        result(unsafe {
            c::R4SdkUpdateHost_open(0, storage.as_mut_ptr(), path.as_ptr(), path.len() as u64)
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn acquire(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkUpdateHost_acquire(0, self.native) })?;
        Ok(())
    }
    pub fn release(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkUpdateHost_release(0, self.native) })?;
        Ok(())
    }
    pub fn resize(&mut self, sectors: u64) -> Result<()> {
        result(unsafe { c::R4SdkUpdateHost_resize(0, self.native, sectors) })?;
        Ok(())
    }
    pub fn device(&mut self) -> Result<Device<'_>> {
        let mut out = Device {
            native: MaybeUninit::uninit(),
            _owner: PhantomData,
            _local: PhantomData,
        };
        required(unsafe {
            c::R4SdkUpdateHost_device(
                0,
                self.native,
                c::R4SdkUpdateSlot {
                    ptr: core::ptr::null_mut(),
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 0,
                },
                out.native.as_mut_ptr(),
            )
        })?;
        Ok(out)
    }
}
impl Drop for HostFile<'_> {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkUpdateHost_close(0, self.native) };
    }
}
