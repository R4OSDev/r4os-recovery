//! Generation-bound inventory, whole-device/partition targets and explicit
//! claims/use leases. No direct driver access or implicit destructive action.
use crate::{
    abi, c_facades as c,
    path::FilePath,
    storage::{Result, System, length, status},
};
pub struct Storage<'a> {
    system: &'a System<'a>,
}
impl<'a> Storage<'a> {
    pub(crate) fn new(system: &'a System<'a>) -> Self {
        Self { system }
    }
    fn raw(&self) -> c::R4Storage {
        c::R4Storage {
            system: core::ptr::from_ref(self.system.raw()).cast_mut(),
        }
    }
    pub fn available(&self) -> bool {
        unsafe { c::r4_storage_available(&self.raw()) != 0 }
    }
    pub fn inventory(&self) -> Result<abi::StorageInventory> {
        let mut out = abi::StorageInventory::default();
        status(unsafe { c::r4_storage_inventory(&mut self.raw(), &mut out) })?;
        Ok(out)
    }
    pub fn device(&self, generation: u64, slot: u32) -> Result<abi::StorageDeviceInfo> {
        let mut out = abi::StorageDeviceInfo::default();
        status(unsafe { c::r4_storage_device(&mut self.raw(), generation, slot, &mut out) })?;
        Ok(out)
    }
    pub fn partition(
        &self,
        generation: u64,
        device: &abi::StorageDeviceRef,
        slot: u32,
    ) -> Result<abi::StoragePartitionInfo> {
        let mut out = abi::StoragePartitionInfo::default();
        status(unsafe {
            c::r4_storage_partition(&mut self.raw(), generation, device, slot, &mut out)
        })?;
        Ok(out)
    }
    pub fn volume(&self, generation: u64, slot: u32) -> Result<abi::StorageVolumeInfo> {
        let mut out = abi::StorageVolumeInfo::default();
        status(unsafe { c::r4_storage_volume(&mut self.raw(), generation, slot, &mut out) })?;
        Ok(out)
    }
    pub fn whole_device(disk: &abi::StorageDeviceInfo) -> abi::StorageTarget {
        unsafe { c::r4_storage_whole_device(disk) }
    }
    pub fn read(&self, target: &abi::StorageTarget, lba: u64, out: &mut [u8]) -> Result<()> {
        status(unsafe {
            c::r4_storage_read(
                &mut self.raw(),
                target,
                lba,
                out.as_mut_ptr(),
                length(out.len())?,
            )
        })
    }
    pub fn claim(&self, target: &abi::StorageTarget) -> Result<Claim<'_>> {
        let mut id = 0;
        status(unsafe { c::r4_storage_claim_begin(&mut self.raw(), target, &mut id) })?;
        Ok(Claim {
            storage: Self::new(self.system),
            id,
        })
    }
    pub fn rescan(&self, device: &abi::StorageDeviceRef) -> Result<()> {
        status(unsafe { c::r4_storage_rescan(&mut self.raw(), device) })
    }
    pub fn mount(&self, target: &abi::StorageTarget, letter: u8) -> Result<abi::StorageVolumeRef> {
        let mut out = abi::StorageVolumeRef::default();
        status(unsafe { c::r4_storage_mount(&mut self.raw(), target, letter, &mut out) })?;
        Ok(out)
    }
    pub fn unmount(&self, volume: &abi::StorageVolumeRef) -> Result<()> {
        status(unsafe { c::r4_storage_unmount(&mut self.raw(), volume) })
    }
    pub fn begin_use(&self, path: &FilePath) -> Result<Use<'_>> {
        let mut id = 0;
        status(unsafe {
            c::r4_storage_use_begin(&mut self.raw(), path.as_c_str().as_ptr().cast(), &mut id)
        })?;
        Ok(Use {
            storage: Self::new(self.system),
            id,
        })
    }
    pub fn begin_transfer_use(&self, path: &FilePath) -> Result<Use<'_>> {
        let mut id = 0;
        status(unsafe {
            c::r4_storage_transfer_use_begin(
                &mut self.raw(),
                path.as_c_str().as_ptr().cast(),
                &mut id,
            )
        })?;
        Ok(Use {
            storage: Self::new(self.system),
            id,
        })
    }
}
#[must_use = "end the claim and inspect the real completion/remount result"]
pub struct Claim<'a> {
    storage: Storage<'a>,
    id: u64,
}
impl Claim<'_> {
    pub fn id(&self) -> u64 {
        self.id
    }
    pub fn read(&self, lba: u64, out: &mut [u8]) -> Result<()> {
        status(unsafe {
            c::r4_storage_claim_read(
                &mut self.storage.raw(),
                self.id,
                lba,
                out.as_mut_ptr(),
                length(out.len())?,
            )
        })
    }
    pub fn write(&self, lba: u64, bytes: &[u8]) -> Result<()> {
        status(unsafe {
            c::r4_storage_claim_write(
                &mut self.storage.raw(),
                self.id,
                lba,
                bytes.as_ptr(),
                length(bytes.len())?,
            )
        })
    }
    pub fn flush(&self) -> Result<()> {
        status(unsafe { c::r4_storage_claim_flush(&mut self.storage.raw(), self.id) })
    }
    /// BUSY retains `id`; completed I/O/remount failure consumes it. Inspect
    /// both the result and `id`, exactly as in the existing C owner.
    pub fn end(&mut self, keep_unmounted: bool) -> Result<()> {
        status(unsafe {
            c::r4_storage_claim_end(
                &mut self.storage.raw(),
                &mut self.id,
                i32::from(keep_unmounted),
            )
        })
    }
}
#[must_use = "end the use lease and inspect its acknowledgement"]
pub struct Use<'a> {
    storage: Storage<'a>,
    id: u64,
}
impl Use<'_> {
    pub fn id(&self) -> u64 {
        self.id
    }
    pub fn end(&mut self) -> Result<()> {
        status(unsafe { c::r4_storage_use_end(&mut self.storage.raw(), &mut self.id) })
    }
}
