use super::{MaybeUninit, Result, c, required, result};
/// Original pause-adjusted guest clock. Host tick frequency is explicit.
pub struct Clock {
    native: MaybeUninit<c::R4SdkSubsystemRuntimeGuestClock>,
}
impl Clock {
    pub fn new(hz: u32, tick: u64) -> Result<Self> {
        let mut out = Self {
            native: MaybeUninit::uninit(),
        };
        required(unsafe {
            c::R4SdkSubsystemRuntimeGuestClock_init(0, hz, tick, out.native.as_mut_ptr())
        })?;
        Ok(out)
    }
    pub fn sync(&mut self, tick: u64) -> Result<u64> {
        Ok(required(unsafe {
            c::R4SdkSubsystemRuntimeGuestClock_sync(0, self.native.as_mut_ptr(), tick)
        })?
        .bits)
    }
    pub fn pause(&mut self, tick: u64) -> Result<()> {
        result(unsafe {
            c::R4SdkSubsystemRuntimeGuestClock_pause(0, self.native.as_mut_ptr(), tick)
        })?;
        Ok(())
    }
    pub fn resume(&mut self, tick: u64) -> Result<()> {
        result(unsafe {
            c::R4SdkSubsystemRuntimeGuestClock_resumeAt(0, self.native.as_mut_ptr(), tick)
        })?;
        Ok(())
    }
    pub fn reset(&mut self, tick: u64) -> Result<()> {
        result(unsafe {
            c::R4SdkSubsystemRuntimeGuestClock_reset(0, self.native.as_mut_ptr(), tick)
        })?;
        Ok(())
    }
    pub fn ticks_until(&self, deadline_ns: u64) -> Result<u64> {
        Ok(required(unsafe {
            c::R4SdkSubsystemRuntimeGuestClock_ticksUntil(0, self.native.as_ptr(), deadline_ns)
        })?
        .bits)
    }
}
pub struct Pacer {
    native: MaybeUninit<c::R4SdkSubsystemRuntimePacer>,
}
impl Pacer {
    pub fn new(hz: u32) -> Result<Self> {
        let mut out = Self {
            native: MaybeUninit::uninit(),
        };
        required(unsafe { c::R4SdkSubsystemRuntimePacer_initHz(0, hz, out.native.as_mut_ptr()) })?;
        Ok(out)
    }
    pub fn reset(&mut self, ns: u64) -> Result<()> {
        result(unsafe { c::R4SdkSubsystemRuntimePacer_reset(0, self.native.as_mut_ptr(), ns) })?;
        Ok(())
    }
    pub fn take(&mut self, ns: u64) -> Result<bool> {
        Ok(required(unsafe {
            c::R4SdkSubsystemRuntimePacer_take(0, self.native.as_mut_ptr(), ns)
        })?
        .bits
            != 0)
    }
    pub fn deadline(&self) -> Result<u64> {
        Ok(
            required(unsafe { c::R4SdkSubsystemRuntimePacer_deadline(0, self.native.as_ptr()) })?
                .bits,
        )
    }
}
