//! R4D ownership. Every device/backend keeps its own state and generation.
//! Native helpers remain the original Zig owners, available through `raw`.
//! Resources close explicitly; dropping a Rust value never attests hardware
//! quiescence, cancels a callback, frees DMA or unloads a driver.
use crate::{abi, c_facades as c};
use core::{ffi::CStr, marker::PhantomData, mem::MaybeUninit};
pub mod raw {
    pub use crate::c_facades::*;
}
pub type Result<T> = core::result::Result<T, i32>;
pub(crate) fn code(s: c::R4SdkDriverSlot) -> Result<i32> {
    if s.status < 0 {
        return Err(s.status);
    }
    if s.flags & 2 != 0 {
        return Err(-1);
    }
    let v = s.bits as i32;
    if v < 0 { Err(v) } else { Ok(v) }
}
/// Borrow of the exact loader-owned current DriverApi. Not Send/Sync.
pub struct Driver<'a> {
    raw: c::R4SdkDriverContext,
    _api: PhantomData<&'a abi::DriverApi>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Driver<'a> {
    /// # Safety
    /// api is the original immutable resident loader table; the caller runs
    /// under this exact driver's admitted init/shutdown/callback context.
    /// Its full current readable range stays valid for 'a. Copying a table
    /// or storing this view does not grant another task owner admission.
    pub unsafe fn from_raw(api: *const abi::DriverApi) -> Result<Self> {
        if api.is_null() || !(api as usize).is_multiple_of(8) {
            return Err(-1);
        }
        let (magic, version, size) = unsafe { ((*api).magic, (*api).version, (*api).size) };
        if magic != abi::driver_magic
            || version < abi::driver_api_version
            || (size as usize) < core::mem::size_of::<abi::DriverApi>()
        {
            return Err(-1);
        }
        let mut out = MaybeUninit::uninit();
        code(unsafe { c::R4SdkDriverContext_init(0, api, out.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { out.assume_init() },
            _api: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn log(&self, text: &CStr) {
        unsafe {
            c::R4SdkDriverContext_logInfo(0, &self.raw, text.as_ptr().cast());
        }
    }
    pub fn ticks(&self) -> u64 {
        unsafe { c::R4SdkDriverContext_tickCount(0, &self.raw) }.bits
    }
    pub fn clock_sample(
        &self,
    ) -> core::result::Result<crate::time::checked::ClockSample, crate::time::checked::Error> {
        let mut info = abi::MonotonicClockInfo::default();
        let result = code(unsafe { c::R4SdkDriverContext_monotonicClock(0, &self.raw, &mut info) });
        if !matches!(result, Ok(n) if n > 0) {
            return Err(crate::time::checked::Error::ClockUnavailable);
        }
        crate::time::checked::ClockSample::from_info(&info)
    }
    pub fn wait_ticks(&self, ticks: u64) {
        unsafe {
            c::R4SdkDriverContext_waitTicks(0, &self.raw, ticks);
        }
    }
    pub fn pci_device(&self, index: u32) -> Result<abi::PciDeviceInfo> {
        let mut info = abi::PciDeviceInfo::default();
        code(unsafe { c::R4SdkDriverContext_pciDeviceAt(0, &self.raw, index, &mut info) })?;
        Ok(info)
    }
    pub fn threads(&self) -> Result<Threads<'_>> {
        let mut out = MaybeUninit::uninit();
        let slot = unsafe { c::R4SdkDriverContext_threads(0, &self.raw, out.as_mut_ptr()) };
        code(slot)?;
        if slot.flags & 1 == 0 {
            return Err(-1);
        }
        Ok(Threads {
            raw: unsafe { out.assume_init() },
            _owner: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn heap(&self) -> Result<Heap<'_>> {
        let mut out = MaybeUninit::uninit();
        let slot = unsafe { c::R4SdkDriverContext_heap(0, &self.raw, out.as_mut_ptr()) };
        code(slot)?;
        if slot.flags & 1 == 0 {
            return Err(-1);
        }
        Ok(Heap {
            raw: unsafe { out.assume_init() },
            _owner: PhantomData,
            _local: PhantomData,
        })
    }
    /// # Safety
    /// Preserve this exact loader context's lifetime/admission and every
    /// native resource contract. The pointer is not a transferable capability.
    pub unsafe fn native(&self) -> *const c::R4SdkDriverContext {
        &self.raw
    }
    /// # Safety
    /// Callback and context remain resident and synchronized until this exact
    /// ticket reaches terminal status and release succeeds. No exclusive Rust
    /// reference may span a callback that aliases its owner.
    pub unsafe fn work(
        &self,
        handler: unsafe extern "C" fn(usize) -> i32,
        context: usize,
        flags: u32,
    ) -> Result<Work<'_>> {
        let mut handle = 0;
        code(unsafe {
            c::R4SdkDriverContext_workSubmit(
                0,
                &self.raw,
                handler as usize as u64,
                context as u64,
                flags,
                &mut handle,
            )
        })?;
        if handle == 0 {
            return Err(-1);
        }
        Ok(Work {
            driver: self,
            handle,
        })
    }
    /// # Safety
    /// Buffer is resident and exclusive to this device's DMA protocol until
    /// unmap/unpin succeeds. Preserve its address even if the token is lost.
    pub unsafe fn pin(&self, bytes: *mut u8, length: usize) -> Result<Dma<'_>> {
        let mut pin = abi::DmaPinnedBuffer::default();
        code(unsafe {
            c::R4SdkDriverContext_pinDmaBuffer(0, &self.raw, bytes, length as u64, &mut pin)
        })?;
        Ok(Dma {
            driver: self,
            pin,
            mapping: abi::DmaMapping::default(),
        })
    }
    /// # Safety
    /// The exact IRQ/handler/context tuple belongs to this device and all
    /// callback storage remains resident through successful unregister.
    pub unsafe fn irq(
        &self,
        line: u8,
        handler: unsafe extern "C" fn(u8, usize) -> u32,
        context: usize,
        flags: u32,
    ) -> Result<Irq<'_>> {
        code(unsafe {
            c::R4SdkDriverContext_irqRegister(
                0,
                &self.raw,
                line,
                handler as usize as u64,
                context as u64,
                flags,
            )
        })?;
        Ok(Irq {
            driver: self,
            line,
            handler,
            context,
            active: true,
        })
    }
}
#[must_use = "keep the exact ticket until terminal status and acknowledged release"]
pub struct Work<'a> {
    driver: &'a Driver<'a>,
    handle: u32,
}
impl Work<'_> {
    pub fn handle(&self) -> u32 {
        self.handle
    }
    pub fn cancel(&self) -> Result<i32> {
        code(unsafe { c::R4SdkDriverContext_workCancel(0, &self.driver.raw, self.handle) })
    }
    pub fn status(&self) -> Result<abi::DriverCompletionStatus> {
        let mut out = abi::DriverCompletionStatus::default();
        code(unsafe {
            c::R4SdkDriverContext_completionStatus(0, &self.driver.raw, self.handle, &mut out)
        })?;
        Ok(out)
    }
    pub fn wait(&self, ticks: u64) -> Result<i32> {
        let mut out = 0;
        code(unsafe {
            c::R4SdkDriverContext_completionWait(0, &self.driver.raw, self.handle, ticks, &mut out)
        })?;
        Ok(out)
    }
    pub fn release(&mut self) -> Result<()> {
        if self.handle == 0 {
            return Ok(());
        }
        let s = self.status()?;
        if s.state != abi::driver_work_state_completed
            && s.state != abi::driver_work_state_cancelled
        {
            return Err(abi::driver_work_owner_busy);
        }
        code(unsafe { c::R4SdkDriverContext_completionRelease(0, &self.driver.raw, self.handle) })?;
        self.handle = 0;
        Ok(())
    }
}
#[must_use = "DMA remains resident until exact unmap/unpin after device quiescence"]
pub struct Dma<'a> {
    driver: &'a Driver<'a>,
    pin: abi::DmaPinnedBuffer,
    mapping: abi::DmaMapping,
}
impl Dma<'_> {
    pub fn pin_identity(&self) -> &abi::DmaPinnedBuffer {
        &self.pin
    }
    pub fn mapping(&self) -> Option<&abi::DmaMapping> {
        if self.mapping.handle != 0 {
            Some(&self.mapping)
        } else {
            None
        }
    }
    pub fn map(&mut self, constraints: &abi::DmaConstraints, direction: u32) -> Result<()> {
        if self.pin.handle == 0 || self.mapping.handle != 0 {
            return Err(-1);
        }
        code(unsafe {
            c::R4SdkDriverContext_mapDmaPinned(
                0,
                &self.driver.raw,
                &self.pin,
                constraints,
                direction,
                &mut self.mapping,
            )
        })?;
        Ok(())
    }
    /// # Safety
    /// Caller has the real device/ring/callback quiescence proof for this
    /// mapping and its current reset epoch. Timeout, cancel and an old reset
    /// are not proof. On any refusal retain this token and its backing storage.
    pub unsafe fn close(&mut self) -> Result<()> {
        if self.mapping.handle != 0 {
            code(unsafe {
                c::R4SdkDriverContext_unmapDma(0, &self.driver.raw, &mut self.mapping)
            })?;
        }
        if self.pin.handle != 0 {
            code(unsafe {
                c::R4SdkDriverContext_unpinDmaBuffer(0, &self.driver.raw, &mut self.pin)
            })?;
        }
        Ok(())
    }
}
#[must_use = "unregister exact IRQ tuple and inspect its quiescence result"]
pub struct Irq<'a> {
    driver: &'a Driver<'a>,
    line: u8,
    handler: unsafe extern "C" fn(u8, usize) -> u32,
    context: usize,
    active: bool,
}
impl Irq<'_> {
    /// # Safety
    /// Device interrupt production is stopped or otherwise handled by its
    /// owner protocol; callback storage stays resident on every refusal.
    pub unsafe fn close(&mut self) -> Result<()> {
        if self.active {
            code(unsafe {
                c::R4SdkDriverContext_irqUnregister(
                    0,
                    &self.driver.raw,
                    self.line,
                    self.handler as usize as u64,
                    self.context as u64,
                )
            })?;
            self.active = false;
        }
        Ok(())
    }
}
/// Snapshot of the original owner-bound task interface, never an R4X task.
pub struct Threads<'a> {
    raw: c::R4SdkDriverThreadsContext,
    _owner: PhantomData<&'a Driver<'a>>,
    _local: PhantomData<*mut ()>,
}
impl Threads<'_> {
    /// # Safety
    /// Exact callback/context storage stays resident through terminal join
    /// and release. Abortable callbacks can bypass Rust destructors; keep all
    /// recovery in the resident owner. No exclusive borrow across callbacks.
    pub unsafe fn start(
        &self,
        handler: unsafe extern "C" fn(usize) -> i32,
        context: usize,
        flags: u32,
    ) -> Result<Task<'_>> {
        let mut handle = 0;
        code(unsafe {
            c::R4SdkDriverThreadsContext_start(
                0,
                &self.raw,
                handler as usize as u64,
                context as u64,
                flags,
                &mut handle,
            )
        })?;
        if handle == 0 {
            return Err(-1);
        }
        Ok(Task {
            threads: self,
            handle,
            joined: false,
        })
    }
}
#[must_use = "stop does not join; retain callback state until join and release succeed"]
pub struct Task<'a> {
    threads: &'a Threads<'a>,
    handle: u64,
    joined: bool,
}
impl Task<'_> {
    pub fn handle(&self) -> u64 {
        self.handle
    }
    pub fn stop(&self) -> Result<i32> {
        code(unsafe { c::R4SdkDriverThreadsContext_stop(0, &self.threads.raw, self.handle) })
    }
    pub fn status(&self) -> Result<abi::DriverThreadStatus> {
        let mut out = abi::DriverThreadStatus::default();
        code(unsafe {
            c::R4SdkDriverThreadsContext_status(0, &self.threads.raw, self.handle, &mut out)
        })?;
        Ok(out)
    }
    pub fn join(&mut self, ticks: u64) -> Result<i32> {
        let mut result = 0;
        code(unsafe {
            c::R4SdkDriverThreadsContext_join(0, &self.threads.raw, self.handle, ticks, &mut result)
        })?;
        self.joined = true;
        Ok(result)
    }
    pub fn release(&mut self) -> Result<()> {
        if self.handle == 0 {
            return Ok(());
        }
        if !self.joined || self.status()?.state != abi::driver_thread_state_completed {
            return Err(-1);
        }
        code(unsafe { c::R4SdkDriverThreadsContext_release(0, &self.threads.raw, self.handle) })?;
        self.handle = 0;
        Ok(())
    }
}
/// Resident CPU heap of this exact driver, separate from the R4X allocator.
pub struct Heap<'a> {
    raw: c::R4SdkDriverHeapContext,
    _owner: PhantomData<&'a Driver<'a>>,
    _local: PhantomData<*mut ()>,
}
impl Heap<'_> {
    pub fn stats(&self) -> Result<abi::DriverHeapStats> {
        let mut out = abi::DriverHeapStats::default();
        code(unsafe { c::R4SdkDriverHeapContext_stats(0, &self.raw, &mut out) })?;
        Ok(out)
    }
    pub fn allocate(&self, bytes: u64, alignment: u32) -> Result<Allocation<'_>> {
        let mut raw = abi::DriverHeapAllocation::default();
        code(unsafe {
            c::R4SdkDriverHeapContext_allocate(0, &self.raw, bytes, alignment, &mut raw)
        })?;
        if raw.handle == 0 {
            return Err(-1);
        }
        Ok(Allocation { heap: self, raw })
    }
}
#[must_use = "release CPU storage only after all callback, task and DMA loans end"]
pub struct Allocation<'a> {
    heap: &'a Heap<'a>,
    raw: abi::DriverHeapAllocation,
}
impl Allocation<'_> {
    pub fn identity(&self) -> &abi::DriverHeapAllocation {
        &self.raw
    }
    /// # Safety
    /// No CPU, callback, task, DMA or pinned-memory reference to this allocation
    /// remains. A failed release retains the exact allocation and handle.
    pub unsafe fn release(&mut self) -> Result<()> {
        if self.raw.handle != 0 {
            code(unsafe { c::R4SdkDriverHeapContext_release(0, &self.heap.raw, self.raw.handle) })?;
            self.raw = abi::DriverHeapAllocation::default();
        }
        Ok(())
    }
}
/// Emit the unchanged two-jump R4D entry. Functions use the ordinary C ABI:
/// init(*const DriverApi)->i32 and shutdown()->i32. Bodies own all state.
#[macro_export]
macro_rules! driver_entry {
    ($init:path,$shutdown:path)=>{
        core::arch::global_asm!(
            ".pushsection .text.r4d_entries,\"ax\",@progbits",
            ".global r4d_init_entry", "r4d_init_entry:", ".byte 0xe9", ".long {init} - . - 4",
            ".global r4d_shutdown_entry", "r4d_shutdown_entry:", ".byte 0xe9", ".long {shutdown} - . - 4", ".popsection",
            init=sym $init,shutdown=sym $shutdown);
        const _: unsafe extern "C" fn(*const $crate::abi::DriverApi)->i32=$init;
        const _: unsafe extern "C" fn()->i32=$shutdown;
    };
}
