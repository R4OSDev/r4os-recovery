//! One actual passive capture, then borrowed pages of its complete frozen copy.
//! No implicit retry, second collection, Kernel snapshot handle or device retain.
pub use crate::transfer::Error;
use crate::{abi, c_facades as c, platform2};
use core::{
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type NativeProvider = c::R4SdkDeviceSnapshotProvider;
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Initial = 0,
    Complete = 1,
    Capacity = 2,
    Failed = 3,
    NoProvider = 4,
    Cancelled = 5,
    Closed = 6,
    InvalidProvider = 7,
}
impl Status {
    fn read(n: u32) -> Result<Self, Error> {
        Ok(match n {
            0 => Self::Initial,
            1 => Self::Complete,
            2 => Self::Capacity,
            3 => Self::Failed,
            4 => Self::NoProvider,
            5 => Self::Cancelled,
            6 => Self::Closed,
            7 => Self::InvalidProvider,
            _ => return Err(Error(-1)),
        })
    }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PageStatus {
    More = 1,
    Complete = 2,
    Restart = 3,
}
pub struct Progress {
    pub info: abi::DeviceInventorySnapshotInfo,
    pub status: Status,
    pub error_code: i32,
    pub complete: bool,
    pub terminal: bool,
    pub in_call: bool,
    pub stop_requested: bool,
}
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
fn progress(raw: c::R4SdkDeviceSnapshotProgress) -> Result<Progress, Error> {
    Ok(Progress {
        info: raw.info,
        status: Status::read(raw.status)?,
        error_code: raw.error_code,
        complete: raw.flags & 1 != 0,
        terminal: raw.flags & 2 != 0,
        in_call: raw.flags & 4 != 0,
        stop_requested: raw.flags & 8 != 0,
    })
}
pub struct Cursor {
    raw: c::R4SdkDeviceSnapshotCursor,
}
impl Cursor {
    pub fn snapshot_generation(&self) -> u64 {
        self.raw.snapshot_generation
    }
    pub fn next_index(&self) -> u32 {
        self.raw.next_index
    }
}
pub struct Page<'view> {
    pub records: &'view [abi::DeviceInventoryRecord],
    pub snapshot_generation: u64,
    pub total: u32,
    pub next_index: u32,
    pub status: PageStatus,
}
/// Whole caller storage and actual provider owners stay borrowed. Holding any
/// view/page prevents capture, close, mutation or drop while that view is used.
pub struct Snapshot<'a> {
    raw: c::R4SdkDeviceSnapshot,
    storage: &'a mut [MaybeUninit<abi::DeviceInventoryRecord>],
    _owner: PhantomData<(&'a platform2::Context<'a>, &'a NativeProvider)>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Snapshot<'a> {
    fn initialize(
        storage: &'a mut [MaybeUninit<abi::DeviceInventoryRecord>],
        provider: NativeProvider,
    ) -> Result<Self, Error> {
        let capacity = u32::try_from(storage.len()).map_err(|_| Error(-2))?;
        let length = storage
            .len()
            .checked_mul(mem::size_of::<abi::DeviceInventoryRecord>())
            .ok_or(Error(-2))?;
        let span = c::R4SdkWireSpan {
            address: storage.as_ptr() as u64,
            length: length as u64,
        };
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeviceSnapshotInit(span, capacity, provider, raw.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            storage,
            _owner: PhantomData,
            _local: PhantomData,
        })
    }
    /// Resolve only the actual optional capture slot; old Kernel capability
    /// remains explicit err_no_fn instead of repeated legacy index calls.
    pub fn new(
        ctx: &'a platform2::Context<'a>,
        storage: &'a mut [MaybeUninit<abi::DeviceInventoryRecord>],
    ) -> Result<Self, Error> {
        let address = ctx
            .lookup(
                6,
                mem::offset_of!(platform2::abi::R4XStartR4Dev2, device_inventory_capture) as u32,
            )
            .map_err(Error)?;
        let capture = Some(unsafe {
            mem::transmute::<u64, abi::R4DevFns::device_inventory_capture>(address)
        });
        Self::initialize(storage, NativeProvider { capture })
    }
    /// # Safety
    /// The native provider follows the canonical synchronous capture contract,
    /// fully initializes every row reported as successful, and retains no
    /// output pointer. Its code, metadata owners, mapping and exclusive loans
    /// must actually remain valid for 'a. Missing pointers remain unavailable.
    pub unsafe fn from_native_provider(
        provider: &'a NativeProvider,
        storage: &'a mut [MaybeUninit<abi::DeviceInventoryRecord>],
    ) -> Result<Self, Error> {
        Self::initialize(storage, *provider)
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeviceSnapshotGetProgress(&self.raw, out.as_mut_ptr()) })?;
        progress(unsafe { out.assume_init() })
    }
    /// One synchronous owner call. Refresh/retry is explicit and invalidates
    /// all previous cursors. The provider performs no persistent Kernel loan.
    pub fn capture(&mut self, stop: bool) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDeviceSnapshotCapture(&mut self.raw, u32::from(stop), out.as_mut_ptr())
        })?;
        progress(unsafe { out.assume_init() })
    }
    pub fn cancel(&mut self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeviceSnapshotCancel(&mut self.raw, out.as_mut_ptr()) })?;
        progress(unsafe { out.assume_init() })
    }
    /// Discard this SDK view; no hardware or Kernel resource acknowledgement.
    pub fn close(&mut self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeviceSnapshotClose(&mut self.raw, out.as_mut_ptr()) })?;
        progress(unsafe { out.assume_init() })
    }
    pub fn view(&self) -> Result<&[abi::DeviceInventoryRecord], Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeviceSnapshotGetView(&self.raw, out.as_mut_ptr()) })?;
        let span = unsafe { out.assume_init() };
        let size = mem::size_of::<abi::DeviceInventoryRecord>() as u64;
        let bytes = (self.storage.len() as u64)
            .checked_mul(size)
            .ok_or(Error(-1))?;
        if span.address != self.storage.as_ptr() as u64
            || span.length > bytes
            || !span.length.is_multiple_of(size)
        {
            return Err(Error(-1));
        }
        let count = (span.length / size) as usize;
        // Only shared-owner validated Complete publishes initialized rows.
        Ok(unsafe { core::slice::from_raw_parts(self.storage.as_ptr().cast(), count) })
    }
    pub fn begin_pages(&self) -> Result<Cursor, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeviceSnapshotBeginPages(&self.raw, out.as_mut_ptr()) })?;
        Ok(Cursor {
            raw: unsafe { out.assume_init() },
        })
    }
    /// O(1), no provider call or repeated full row scan. A stale cursor returns
    /// Restart with no records; discard the whole partial traversal explicitly.
    pub fn page<'view>(&'view self, cursor: &mut Cursor, limit: u32) -> Result<Page<'view>, Error> {
        let mut span = MaybeUninit::uninit();
        let mut info = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDeviceSnapshotPage(
                &self.raw,
                &mut cursor.raw,
                limit,
                span.as_mut_ptr(),
                info.as_mut_ptr(),
            )
        })?;
        let span = unsafe { span.assume_init() };
        let info = unsafe { info.assume_init() };
        let status = match info.status {
            1 => PageStatus::More,
            2 => PageStatus::Complete,
            3 => PageStatus::Restart,
            _ => return Err(Error(-1)),
        };
        if status == PageStatus::Restart {
            if span.length != 0 || info.returned != 0 {
                return Err(Error(-1));
            }
            return Ok(Page {
                records: &[],
                snapshot_generation: info.snapshot_generation,
                total: info.total,
                next_index: info.next_index,
                status,
            });
        }
        let start = info
            .next_index
            .checked_sub(info.returned)
            .ok_or(Error(-1))? as usize;
        let end = info.next_index as usize;
        let size = mem::size_of::<abi::DeviceInventoryRecord>() as u64;
        let expected = if info.returned == 0 {
            0
        } else {
            (self.storage.as_ptr() as u64)
                .checked_add((start as u64).checked_mul(size).ok_or(Error(-1))?)
                .ok_or(Error(-1))?
        };
        if info.snapshot_generation != self.raw.info.snapshot_generation
            || info.total != self.raw.info.count
            || info.returned > limit
            || span.address != expected
            || span.length != u64::from(info.returned) * size
        {
            return Err(Error(-1));
        }
        if (status == PageStatus::Complete) != (info.next_index == info.total) {
            return Err(Error(-1));
        }
        let records = self.view()?.get(start..end).ok_or(Error(-1))?;
        Ok(Page {
            records,
            snapshot_generation: info.snapshot_generation,
            total: info.total,
            next_index: info.next_index,
            status,
        })
    }
}
