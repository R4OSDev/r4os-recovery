//! Complete, generation-bound views over the existing program owners.
//! Partial/capacity/restart/clock/provider outcomes never authorize Missing.
pub use crate::transfer::{Error, PlatformClock};
use crate::{
    abi, c_facades as c, platform2,
    resources::Timeout,
    time::checked::{ClockSample, DeadlineBudget},
};
use core::{
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type NativeProvider = c::R4SdkInventoryProvider;
mod sealed {
    pub trait Sealed {}
}
/// Only the canonical Full/Lifecycle records can back a typed reader.
pub trait Row: sealed::Sealed + Copy {
    #[doc(hidden)]
    const MODE: u32;
}
impl sealed::Sealed for abi::ProgramInstanceSnapshot {}
impl Row for abi::ProgramInstanceSnapshot {
    const MODE: u32 = 0;
}
impl sealed::Sealed for abi::ProgramLifecycleSnapshot {}
impl Row for abi::ProgramLifecycleSnapshot {
    const MODE: u32 = 1;
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Initial = 0,
    More = 1,
    Complete = 2,
    WouldBlock = 3,
    Restart = 4,
    Failed = 5,
    NoProvider = 6,
    Capacity = 7,
    Cancelled = 8,
    TimedOut = 9,
    ClockFailed = 10,
    InvalidProvider = 11,
}
impl Status {
    fn read(value: u32) -> Result<Self, Error> {
        Ok(match value {
            0 => Self::Initial,
            1 => Self::More,
            2 => Self::Complete,
            3 => Self::WouldBlock,
            4 => Self::Restart,
            5 => Self::Failed,
            6 => Self::NoProvider,
            7 => Self::Capacity,
            8 => Self::Cancelled,
            9 => Self::TimedOut,
            10 => Self::ClockFailed,
            11 => Self::InvalidProvider,
            _ => return Err(Error(-1)),
        })
    }
}
#[derive(Debug, Clone, Copy)]
pub struct Progress {
    pub snapshot_generation: u64,
    pub staged_count: u32,
    pub total: Option<u32>,
    pub status: Status,
    pub error_code: i32,
    pub complete: bool,
    pub terminal: bool,
    pub in_call: bool,
    pub restarts: u32,
}
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
fn progress(raw: c::R4SdkInventoryProgress) -> Result<Progress, Error> {
    Ok(Progress {
        snapshot_generation: raw.snapshot_generation,
        staged_count: raw.staged_count,
        total: if raw.flags & 8 != 0 {
            Some(raw.total)
        } else {
            None
        },
        status: Status::read(raw.status)?,
        error_code: raw.error_code,
        complete: raw.flags & 1 != 0,
        terminal: raw.flags & 2 != 0,
        in_call: raw.flags & 4 != 0,
        restarts: raw.restarts,
    })
}
/// Found borrows the completed view; it never retains a process or proves its
/// present liveness/physical retirement. Missing is a complete membership view.
pub enum Lookup<'view, T> {
    Found {
        snapshot_generation: u64,
        record: &'view T,
    },
    Missing {
        snapshot_generation: u64,
    },
    Unknown {
        status: Status,
        error_code: i32,
    },
}
pub type ProgramInventoryReader<'a> = InventoryReader<'a, abi::ProgramInstanceSnapshot>;
pub type LifecycleReader<'a> = InventoryReader<'a, abi::ProgramLifecycleSnapshot>;
pub struct InventoryReader<'a, T: Row> {
    raw: c::R4SdkInventoryReader,
    records: &'a mut [MaybeUninit<T>],
    _owner: PhantomData<(&'a platform2::Context<'a>, &'a NativeProvider)>,
    _local: PhantomData<*mut ()>,
}
fn provider(ctx: &platform2::Context<'_>, mode: u32) -> Result<NativeProvider, Error> {
    let mut p = NativeProvider {
        full_begin: None,
        full_page: None,
        lifecycle_begin: None,
        lifecycle_page: None,
    };
    if mode == 0 {
        let begin = ctx
            .lookup(
                1,
                mem::offset_of!(platform2::abi::R4XStartR4Sys2, program_inventory_begin) as u32,
            )
            .map_err(Error)?;
        let page = ctx
            .lookup(
                1,
                mem::offset_of!(platform2::abi::R4XStartR4Sys2, program_inventory_programs) as u32,
            )
            .map_err(Error)?;
        p.full_begin =
            Some(unsafe { mem::transmute::<u64, abi::R4SysFns::program_inventory_begin>(begin) });
        p.full_page =
            Some(unsafe { mem::transmute::<u64, abi::R4SysFns::program_inventory_programs>(page) });
    } else {
        let begin = ctx
            .lookup(
                1,
                mem::offset_of!(platform2::abi::R4XStartR4Sys2, program_lifecycle_begin) as u32,
            )
            .map_err(Error)?;
        let page = ctx
            .lookup(
                1,
                mem::offset_of!(platform2::abi::R4XStartR4Sys2, program_lifecycle_programs) as u32,
            )
            .map_err(Error)?;
        p.lifecycle_begin =
            Some(unsafe { mem::transmute::<u64, abi::R4SysFns::program_lifecycle_begin>(begin) });
        p.lifecycle_page =
            Some(unsafe { mem::transmute::<u64, abi::R4SysFns::program_lifecycle_programs>(page) });
    }
    Ok(p)
}
impl<'a, T: Row> InventoryReader<'a, T> {
    fn shape(records: &[MaybeUninit<T>]) -> Result<(c::R4SdkWireSpan, u32), Error> {
        let capacity = u32::try_from(records.len()).map_err(|_| Error(-2))?;
        let bytes = records
            .len()
            .checked_mul(mem::size_of::<T>())
            .ok_or(Error(-2))?;
        Ok((
            c::R4SdkWireSpan {
                address: records.as_ptr() as u64,
                length: bytes as u64,
            },
            capacity,
        ))
    }
    fn relative(
        records: &'a mut [MaybeUninit<T>],
        page_limit: u32,
        provider: NativeProvider,
        sample: ClockSample,
        timeout: Timeout,
    ) -> Result<Self, Error> {
        let (span, capacity) = Self::shape(records)?;
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkInventoryInit(
                T::MODE,
                span,
                capacity,
                page_limit,
                provider,
                sample.raw(),
                timeout.raw(),
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            records,
            _owner: PhantomData,
            _local: PhantomData,
        })
    }
    fn absolute(
        records: &'a mut [MaybeUninit<T>],
        page_limit: u32,
        provider: NativeProvider,
        deadline: &DeadlineBudget,
    ) -> Result<Self, Error> {
        let (span, capacity) = Self::shape(records)?;
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkInventoryInitAbsolute(
                T::MODE,
                span,
                capacity,
                page_limit,
                provider,
                deadline.raw(),
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            records,
            _owner: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn new(
        ctx: &'a platform2::Context<'_>,
        records: &'a mut [MaybeUninit<T>],
        page_limit: u32,
        sample: ClockSample,
        timeout: Timeout,
    ) -> Result<Self, Error> {
        Self::relative(
            records,
            page_limit,
            provider(ctx, T::MODE)?,
            sample,
            timeout,
        )
    }
    pub fn with_deadline(
        ctx: &'a platform2::Context<'_>,
        records: &'a mut [MaybeUninit<T>],
        page_limit: u32,
        deadline: &DeadlineBudget,
    ) -> Result<Self, Error> {
        Self::absolute(records, page_limit, provider(ctx, T::MODE)?, deadline)
    }
    /// # Safety
    /// Borrow the actual synchronous native provider/code/platform lifetime in
    /// this client until the reader is dropped. Callbacks initialize their
    /// complete bounded output records, retain no buffers and release their
    /// original locks before return. No synthetic diagnostic fallback for Life.
    pub unsafe fn from_native_provider(
        records: &'a mut [MaybeUninit<T>],
        page_limit: u32,
        provider: &'a NativeProvider,
        sample: ClockSample,
        timeout: Timeout,
    ) -> Result<Self, Error> {
        Self::relative(records, page_limit, *provider, sample, timeout)
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkInventoryGetProgress(&self.raw, out.as_mut_ptr()) })?;
        progress(unsafe { out.assume_init() })
    }
    /// Copied acquisition metadata. A matching current epoch can renew a
    /// caller's previous complete view. Use `view` for newly acquired rows.
    pub fn cursor(&self) -> abi::ProgramInventoryCursor {
        self.raw.cursor
    }
    pub fn cancel(&mut self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkInventoryCancel(&mut self.raw, out.as_mut_ptr()) })?;
        progress(unsafe { out.assume_init() })
    }
    /// Invalidate the complete/restarted view and begin again under the SAME
    /// outer budget. No registry operation, sleep or timer rebasing here.
    pub fn restart(&mut self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkInventoryRestart(&mut self.raw, out.as_mut_ptr()) })?;
        progress(unsafe { out.assume_init() })
    }
    pub fn step<C: FnMut() -> Result<ClockSample, Error>>(
        &mut self,
        stop: bool,
        clock: &mut C,
    ) -> Result<Progress, Error> {
        unsafe extern "C" fn sample<C: FnMut() -> Result<ClockSample, Error>>(
            raw: *mut core::ffi::c_void,
            out: *mut c::R4SdkClockSample,
        ) -> i32 {
            let source = unsafe { &mut *raw.cast::<C>() };
            match source() {
                Ok(sample) => {
                    unsafe { out.write(sample.raw()) };
                    0
                }
                Err(e) => e.0,
            }
        }
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkInventoryStep(
                &mut self.raw,
                u32::from(stop),
                Some(sample::<C>),
                (clock as *mut C).cast(),
                out.as_mut_ptr(),
            )
        })?;
        progress(unsafe { out.assume_init() })
    }
    /// Complete only. Uninitialized/partial staging is never exposed as &[T].
    /// The borrow prevents restart/mutation while a view or Found row is held.
    pub fn view(&self) -> Result<&[T], Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkInventoryGetView(&self.raw, out.as_mut_ptr()) })?;
        let span = unsafe { out.assume_init() };
        let (storage, _) = Self::shape(self.records)?;
        if span.address != storage.address
            || span.length > storage.length
            || span.length % (mem::size_of::<T>() as u64) != 0
        {
            return Err(Error(-1));
        }
        let count = (span.length / (mem::size_of::<T>() as u64)) as usize;
        // The sealed record layout and original provider contract are checked
        // by the shared owner before Complete; only initialized rows are read.
        Ok(unsafe { core::slice::from_raw_parts(self.records.as_ptr().cast::<T>(), count) })
    }
    pub fn find_exact(&self, handle: abi::ProgramProcessHandle) -> Result<Lookup<'_, T>, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkInventoryFindExact(&self.raw, handle, out.as_mut_ptr()) })?;
        let found = unsafe { out.assume_init() };
        match found.disposition {
            0 => Ok(Lookup::Unknown {
                status: Status::read(found.status)?,
                error_code: found.error_code,
            }),
            1 | 2 => {
                if found.status != 2
                    || found.snapshot_generation != self.raw.cursor.snapshot_generation
                {
                    return Err(Error(-1));
                }
                let view = self.view()?;
                if found.disposition == 1 {
                    Ok(Lookup::Found {
                        snapshot_generation: found.snapshot_generation,
                        record: view.get(found.index as usize).ok_or(Error(-1))?,
                    })
                } else {
                    Ok(Lookup::Missing {
                        snapshot_generation: found.snapshot_generation,
                    })
                }
            }
            _ => Err(Error(-1)),
        }
    }
}
impl InventoryReader<'_, abi::ProgramInstanceSnapshot> {
    /// Coherent BEGIN summary, not an atomic final state/VM snapshot or retain.
    pub fn summary(&self) -> Result<abi::ProgramInventorySummary, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkInventoryGetSummary(&self.raw, out.as_mut_ptr()) })?;
        Ok(unsafe { out.assume_init() })
    }
}
