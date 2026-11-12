use super::{Callbacks, MaybeUninit, PhantomData, Result, c, required, result};
#[derive(Clone, Copy)]
pub struct Config {
    pub slice_budget: u32,
    pub max_input_events: u16,
    pub max_wait_ticks: u64,
    pub idle_retry_ticks: u64,
}
impl Default for Config {
    fn default() -> Self {
        Self {
            slice_budget: 262_144,
            max_input_events: 64,
            max_wait_ticks: u64::MAX,
            idle_retry_ticks: 1,
        }
    }
}
#[derive(Clone, Copy)]
#[repr(u32)]
pub enum Command {
    Pause = 1,
    Resume = 2,
    TogglePause = 3,
    Reset = 4,
    Mute = 5,
    Unmute = 6,
    ToggleMute = 7,
    Close = 8,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Cycle {
    Wait(u64),
    Finished { state: u32, exit_code: i32 },
}
/// Cooperative original runtime with caller-provided host/guest callbacks.
/// The safe constructor disables audio; complete bounded PCM/R4AudioSink
/// configuration and native window/persistence integration remain in `raw`.
pub struct Runtime<'a> {
    native: MaybeUninit<c::R4SdkSubsystemRuntimeRuntime>,
    guest: MaybeUninit<c::R4SdkSubsystemRuntimeGuestDriver>,
    host: MaybeUninit<c::R4SdkSubsystemRuntimeHostDriver>,
    _callbacks: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
    initialized: bool,
}
impl<'a> Runtime<'a> {
    pub fn new(
        config: Config,
        hz: u32,
        tick: u64,
        guest: &'a Callbacks<'_, '_>,
        host: &'a Callbacks<'_, '_>,
    ) -> Result<Self> {
        let mut out = Self {
            native: MaybeUninit::uninit(),
            guest: MaybeUninit::uninit(),
            host: MaybeUninit::uninit(),
            _callbacks: PhantomData,
            _local: PhantomData,
            initialized: false,
        };
        let mut cfg = MaybeUninit::uninit();
        result(unsafe {
            c::R4SdkSubsystemRuntimeConfig_from_fields(
                cfg.as_mut_ptr(),
                config.slice_budget,
                config.max_input_events,
                config.max_wait_ticks,
                config.idle_retry_ticks,
            )
        })?;
        required(unsafe {
            c::R4SdkSubsystem_guestDriver(0, guest.native, out.guest.as_mut_ptr())
        })?;
        required(unsafe { c::R4SdkSubsystem_hostDriver(0, host.native, out.host.as_mut_ptr()) })?;
        required(unsafe {
            c::R4SdkSubsystemRuntimeRuntime_init(
                0,
                cfg.as_ptr(),
                hz,
                tick,
                c::R4SdkSubsystemSlot {
                    ptr: core::ptr::null_mut(),
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 0,
                },
                out.native.as_mut_ptr(),
            )
        })?;
        out.initialized = true;
        Ok(out)
    }
    pub fn request(&mut self, command: Command, tick: u64) -> Result<()> {
        result(unsafe {
            c::R4SdkSubsystemRuntimeRuntime_request(
                0,
                self.native.as_mut_ptr(),
                command as u32,
                tick,
                self.guest.as_ptr(),
            )
        })?;
        Ok(())
    }
    pub fn cycle(&mut self, tick: u64) -> Result<Cycle> {
        let mut out = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkSubsystemRuntimeRuntime_cycle(
                0,
                self.native.as_mut_ptr(),
                tick,
                self.guest.as_ptr(),
                self.host.as_ptr(),
                out.as_mut_ptr(),
            )
        })?;
        let tag =
            required(unsafe { c::R4SdkSubsystemRuntimeCycleResult_inspectNative(out.as_ptr()) })?
                .bits;
        if tag == 0 {
            Ok(Cycle::Wait(
                required(unsafe { c::R4SdkSubsystemRuntimeCycleResult_get_wait(out.as_ptr()) })?
                    .bits,
            ))
        } else {
            Ok(Cycle::Finished {
                state: self.state()?,
                exit_code: required(unsafe {
                    c::R4SdkSubsystemRuntimeRuntime_get_exit_code(self.native.as_ptr())
                })?
                .bits as i32,
            })
        }
    }
    pub fn state(&self) -> Result<u32> {
        Ok(
            required(unsafe { c::R4SdkSubsystemRuntimeRuntime_get_state(self.native.as_ptr()) })?
                .bits as u32,
        )
    }
    /// # Safety
    /// Retain the original callback/buffer/resource loans. Do not attach
    /// borrowed audio buffers through this pointer and then use a safe move,
    /// drop or forget as a resource release. Advanced configurations are raw.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkSubsystemRuntimeRuntime {
        self.native.as_mut_ptr()
    }
}
impl Drop for Runtime<'_> {
    fn drop(&mut self) {
        if self.initialized {
            let _ =
                unsafe { c::R4SdkSubsystemRuntimeRuntime_shutdown(0, self.native.as_mut_ptr()) };
        }
    }
}
