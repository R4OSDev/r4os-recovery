use super::{Error, MaybeUninit, PhantomData, Result, c, required, result};
/// A scoped native block device. Its owner is exclusively borrowed; a copied
/// native descriptor is not a new claim or a new durability receipt.
pub struct Device<'a> {
    pub(super) native: MaybeUninit<c::R4SdkUpdateBlockDevice>,
    pub(super) _owner: PhantomData<&'a mut ()>,
    pub(super) _local: PhantomData<*mut ()>,
}
impl Device<'_> {
    pub fn sectors(&self) -> Result<u64> {
        Ok(required(unsafe { c::R4SdkUpdateBlockDevice_get_sectors(self.native.as_ptr()) })?.bits)
    }
    pub fn read(&mut self, lba: u64, out: &mut [u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkUpdateBlockDevice_read(
                0,
                self.native.as_ptr(),
                lba,
                out.as_mut_ptr(),
                out.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn write(&mut self, lba: u64, bytes: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkUpdateBlockDevice_write(
                0,
                self.native.as_ptr(),
                lba,
                bytes.as_ptr(),
                bytes.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn flush(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkUpdateBlockDevice_flush(0, self.native.as_ptr()) })?;
        Ok(())
    }
    /// # Safety
    /// Retain the original owner/claim/callback/source identities until all
    /// referencing plans and device operations have really returned.
    pub unsafe fn native(&mut self) -> *const c::R4SdkUpdateBlockDevice {
        self.native.as_ptr()
    }
}
pub struct MemoryBlock<'s, 'b> {
    native: *mut c::R4SdkUpdateBlockMemory,
    bytes: *mut u8,
    len: usize,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkUpdateBlockMemory>>,
    _backing: PhantomData<&'b mut [u8]>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'b> MemoryBlock<'s, 'b> {
    pub fn open(
        storage: &'s mut MaybeUninit<c::R4SdkUpdateBlockMemory>,
        bytes: &'b mut [u8],
    ) -> Result<Self> {
        if bytes.is_empty() || !bytes.len().is_multiple_of(512) {
            return Err(Error::Bounds);
        }
        result(unsafe {
            c::R4SdkUpdateBlockMemory_create(
                storage.as_mut_ptr(),
                bytes.as_mut_ptr(),
                bytes.len() as u64,
            )
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            bytes: bytes.as_mut_ptr(),
            len: bytes.len(),
            _storage: PhantomData,
            _backing: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn device(&mut self) -> Result<Device<'_>> {
        let mut out = Device {
            native: MaybeUninit::uninit(),
            _owner: PhantomData,
            _local: PhantomData,
        };
        required(unsafe {
            c::R4SdkUpdateBlockMemory_device(0, self.native, out.native.as_mut_ptr())
        })?;
        Ok(out)
    }
    pub fn bytes(&self) -> &[u8] {
        unsafe { core::slice::from_raw_parts(self.bytes, self.len) }
    }
}
/// Original FAT32 geometry/label/formatter; no source buffer is retained.
pub struct Fat32Plan {
    native: MaybeUninit<c::R4SdkUpdateFat32Plan>,
}
impl Fat32Plan {
    pub fn prepare(
        sectors: u64,
        hidden: u64,
        label: &[u8],
        serial: u32,
        sectors_per_cluster: u32,
    ) -> Result<Self> {
        let mut out = Self {
            native: MaybeUninit::uninit(),
        };
        required(unsafe {
            c::R4SdkUpdateFat32Plan_prepare(
                0,
                sectors,
                hidden,
                label.as_ptr(),
                label.len() as u64,
                serial,
                sectors_per_cluster,
                out.native.as_mut_ptr(),
            )
        })?;
        Ok(out)
    }
    pub fn execute(&self, device: &mut Device<'_>, full: bool, work: &mut [u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkUpdateFat32Plan_execute(
                0,
                self.native.as_ptr(),
                device.native.as_ptr(),
                full as u8,
                work.as_mut_ptr(),
                work.len() as u64,
            )
        })?;
        Ok(())
    }
}
