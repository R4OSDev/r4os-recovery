use super::{Callbacks, Memory, Result, c, required, result, scalar};
use core::{marker::PhantomData, mem::MaybeUninit};
/// Owns one exact runtime/program pair and their allocator/callback loans.
/// Values stay inside the realm; convenience results are converted/copied
/// before any subsequent execution or GC can recycle a cell ID.
pub struct Script<'s, 'm, 'c> {
    native: *mut c::R4SdkWebJsRuntime,
    program: *mut c::R4SdkWebJsProgram,
    _storage: PhantomData<(
        &'s mut MaybeUninit<c::R4SdkWebJsRuntime>,
        &'s mut MaybeUninit<c::R4SdkWebJsProgram>,
    )>,
    _memory: PhantomData<&'m mut ()>,
    _callbacks: PhantomData<&'c ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'm, 'c> Script<'s, 'm, 'c> {
    pub fn open(
        storage: &'s mut MaybeUninit<c::R4SdkWebJsRuntime>,
        program: &'s mut MaybeUninit<c::R4SdkWebJsProgram>,
        memory: &'m mut Memory<'_, '_>,
        callbacks: Option<&'c Callbacks<'_, '_>>,
    ) -> Result<Self> {
        required(unsafe { c::R4SdkWebJsProgram_create(program.as_mut_ptr()) })?;
        let mut allocator = MaybeUninit::uninit();
        required(unsafe { c::R4SdkWeb_memoryPrograms(0, memory.native, allocator.as_mut_ptr()) })?;
        result(unsafe {
            c::R4SdkWebJsRuntime_initialize(0, storage.as_mut_ptr(), allocator.as_ptr())
        })?;
        let mut self_ = Self {
            native: storage.as_mut_ptr(),
            program: program.as_mut_ptr(),
            _storage: PhantomData,
            _memory: PhantomData,
            _callbacks: PhantomData,
            _local: PhantomData,
        };
        result(unsafe { c::R4SdkWebJsRuntime_init(0, self_.native) })?;
        if let Some(table) = callbacks {
            self_.bind(table)?;
        }
        Ok(self_)
    }
    fn bind(&mut self, callbacks: &Callbacks<'_, '_>) -> Result<()> {
        let mut clock = MaybeUninit::uninit();
        let mut stop = MaybeUninit::uninit();
        let mut roots = MaybeUninit::uninit();
        let mut rejection = MaybeUninit::uninit();
        required(unsafe { c::R4SdkWeb_clock(0, callbacks.native, clock.as_mut_ptr()) })?;
        required(unsafe { c::R4SdkWeb_stop(0, callbacks.native, 1, stop.as_mut_ptr()) })?;
        required(unsafe { c::R4SdkWeb_rootMarker(0, callbacks.native, roots.as_mut_ptr()) })?;
        required(unsafe {
            c::R4SdkWeb_rejectionTracker(0, callbacks.native, rejection.as_mut_ptr())
        })?;
        result(unsafe { c::R4SdkWebJsRuntime_setClockSource(0, self.native, clock.as_ptr()) })?;
        result(unsafe { c::R4SdkWebJsRuntime_setStop(0, self.native, stop.as_ptr()) })?;
        result(unsafe {
            c::R4SdkWebJsRuntime_setExternalRootMarker(0, self.native, roots.as_ptr())
        })?;
        result(unsafe {
            c::R4SdkWebJsRuntime_setPromiseRejectionTracker(0, self.native, rejection.as_ptr())
        })?;
        Ok(())
    }
    pub fn budget(&mut self, steps: usize) -> Result<()> {
        result(unsafe { c::R4SdkWebJsRuntime_setStepBudget(0, self.native, steps as u64) })?;
        Ok(())
    }
    fn evaluate(&mut self, source: &[u8]) -> Result<MaybeUninit<c::R4SdkWebJsValue>> {
        let mut value = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkWebJsRuntime_evaluateSource(
                0,
                self.native,
                self.program,
                source.as_ptr(),
                source.len() as u64,
                value.as_mut_ptr(),
            )
        })?;
        Ok(value)
    }
    pub fn number(&mut self, source: &[u8]) -> Result<f64> {
        let v = self.evaluate(source)?;
        let mut out = 0.;
        required(unsafe {
            c::R4SdkWebJsRuntime_valueNumber(0, self.native, v.as_ptr(), &mut out)
        })?;
        Ok(out)
    }
    pub fn boolean(&mut self, source: &[u8]) -> Result<bool> {
        let v = self.evaluate(source)?;
        Ok(scalar(unsafe { c::R4SdkWebJsRuntime_valueBoolean(0, self.native, v.as_ptr()) })? != 0)
    }
    pub fn collect(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkWebJsRuntime_collectGarbage(0, self.native) })?;
        Ok(())
    }
    /// # Safety
    /// Preserve the original realm, program, GC rooting, reentrancy and callback
    /// contracts. Returned raw Values are never safe long-lived Rust handles.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkWebJsRuntime {
        self.native
    }
}
impl Drop for Script<'_, '_, '_> {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkWebJsRuntime_deinit(0, self.native) };
    }
}
