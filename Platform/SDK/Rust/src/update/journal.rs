use super::{Callbacks, Error, MaybeUninit, PhantomData, Result, c, required, view};
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum ReplayStatus {
    Ok = c::R4SdkUpdateRecoveryReplayStatus_ok,
    Invalid = c::R4SdkUpdateRecoveryReplayStatus_invalid,
    Conflict = c::R4SdkUpdateRecoveryReplayStatus_conflict,
    Io = c::R4SdkUpdateRecoveryReplayStatus_io,
}
fn status(v: c::R4SdkUpdateSlot) -> Result<ReplayStatus> {
    match required(v)?.bits as u32 {
        c::R4SdkUpdateRecoveryReplayStatus_ok => Ok(ReplayStatus::Ok),
        c::R4SdkUpdateRecoveryReplayStatus_invalid => Ok(ReplayStatus::Invalid),
        c::R4SdkUpdateRecoveryReplayStatus_conflict => Ok(ReplayStatus::Conflict),
        c::R4SdkUpdateRecoveryReplayStatus_io => Ok(ReplayStatus::Io),
        _ => Err(Error::InvalidNative),
    }
}
/// The original v5 journal copies its path/version/component bindings. Its
/// views borrow this exclusive native storage, independent of input text.
pub struct Journal<'s> {
    native: *mut c::R4SdkUpdateRecoveryTransactionJournal,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkUpdateRecoveryTransactionJournal>>,
    _local: PhantomData<*mut ()>,
}
impl<'s> Journal<'s> {
    pub fn parse(
        storage: &'s mut MaybeUninit<c::R4SdkUpdateRecoveryTransactionJournal>,
        input: &[u8],
        slot: u8,
    ) -> Result<Self> {
        if required(unsafe {
            c::R4SdkUpdateRecovery_parseJournalInto(
                0,
                input.as_ptr(),
                input.len() as u64,
                slot,
                storage.as_mut_ptr(),
            )
        })?
        .bits
            == 0
        {
            return Err(Error::InvalidNative);
        }
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn phase(&self) -> Result<u32> {
        Ok(
            required(unsafe { c::R4SdkUpdateRecoveryTransactionJournal_get_phase(self.native) })?
                .bits as u32,
        )
    }
    pub fn source(&self) -> Result<&[u8]> {
        let v = required(unsafe {
            c::R4SdkUpdateRecoveryTransactionJournal_sourceText(0, self.native)
        })?;
        data_object_view(v, unsafe {
            &*self
                .native
                .cast::<MaybeUninit<c::R4SdkUpdateRecoveryTransactionJournal>>()
        })
    }
    pub fn serialize<'o>(&self, out: &'o mut [u8]) -> Result<&'o [u8]> {
        view(
            unsafe {
                c::R4SdkUpdateRecovery_serializeJournal(
                    0,
                    self.native,
                    out.as_mut_ptr(),
                    out.len() as u64,
                )
            },
            out,
        )
    }
    pub fn check_last_good(&self, io: &Callbacks<'_, '_>) -> Result<ReplayStatus> {
        status(unsafe { c::R4SdkUpdate_checkLastGood(0, io.native, self.native) })
    }
    pub fn rollback(&mut self, io: &Callbacks<'_, '_>) -> Result<ReplayStatus> {
        status(unsafe { c::R4SdkUpdate_rollbackToTerminal(0, io.native, self.native) })
    }
    pub fn resume(&mut self, io: &Callbacks<'_, '_>) -> Result<ReplayStatus> {
        status(unsafe { c::R4SdkUpdate_resumeBatchForward(0, io.native, self.native) })
    }
    pub fn cleanup(&mut self, io: &Callbacks<'_, '_>) -> Result<ReplayStatus> {
        status(unsafe { c::R4SdkUpdate_cleanupToTerminal(0, io.native, self.native) })
    }
    /// # Safety
    /// Preserve all native invariants and exact transaction identity. A stale
    /// commit/persist receipt never authorizes a fresh mutation.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkUpdateRecoveryTransactionJournal {
        self.native
    }
}
fn data_object_view<T>(v: c::R4SdkUpdateSlot, owner: &MaybeUninit<T>) -> Result<&[u8]> {
    crate::data::object_view(
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
/// Inventory strings borrow the immutable input. Parsing/rendering use the
/// original owner; advanced upserts must retain every inserted string loan.
pub struct Inventory<'s, 'b> {
    native: *mut c::R4SdkUpdateInventoryInventory,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkUpdateInventoryInventory>>,
    _input: PhantomData<&'b [u8]>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'b> Inventory<'s, 'b> {
    pub fn parse(
        storage: &'s mut MaybeUninit<c::R4SdkUpdateInventoryInventory>,
        input: &'b [u8],
    ) -> Result<Self> {
        if required(unsafe {
            c::R4SdkUpdateInventoryInventory_parse(
                0,
                input.as_ptr(),
                input.len() as u64,
                storage.as_mut_ptr(),
            )
        })?
        .bits
            == 0
        {
            return Err(Error::InvalidNative);
        }
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _input: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn count(&self) -> Result<usize> {
        Ok(
            required(unsafe { c::R4SdkUpdateInventoryInventory_get_count(self.native) })?.bits
                as usize,
        )
    }
    pub fn profile(&self) -> Result<u32> {
        Ok(
            required(unsafe { c::R4SdkUpdateInventoryInventory_get_profile(self.native) })?.bits
                as u32,
        )
    }
    pub fn serialize<'o>(&self, out: &'o mut [u8]) -> Result<&'o [u8]> {
        view(
            unsafe {
                c::R4SdkUpdateInventoryInventory_render(
                    0,
                    self.native,
                    out.as_mut_ptr(),
                    out.len() as u64,
                )
            },
            out,
        )
    }
    /// # Safety
    /// Inserted descriptor strings must outlive this inventory, alongside the
    /// original immutable input. Invalidate views before mutation.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkUpdateInventoryInventory {
        self.native
    }
}
