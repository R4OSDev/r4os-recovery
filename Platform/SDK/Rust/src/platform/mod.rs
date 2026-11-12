//! General current Audio/Device/Power owners, independent of Desktop.
use crate::{
    App, abi, c_facades as c,
    storage::{Error, Result},
};
use core::{
    marker::{PhantomData, PhantomPinned},
    mem::MaybeUninit,
    pin::Pin,
    ptr::NonNull,
};
pub mod raw {
    pub use crate::c_facades::*;
}
mod audio;
mod devices;
mod pcm;
mod power;
pub use audio::{Audio, Stream, WriteCursor, WriteKind, WriteProgress};
pub use devices::Devices;
pub use pcm::Resampler;
pub use power::Power;
pub struct PlatformStorage {
    native: MaybeUninit<c::R4SdkPlatformContext>,
    _pin: PhantomPinned,
}
impl Default for PlatformStorage {
    fn default() -> Self {
        Self::new()
    }
}
impl PlatformStorage {
    pub const fn new() -> Self {
        Self {
            native: MaybeUninit::uninit(),
            _pin: PhantomPinned,
        }
    }
}
pub struct Platform<'s, 'a> {
    native: NonNull<c::R4SdkPlatformContext>,
    _storage: PhantomData<Pin<&'s mut PlatformStorage>>,
    _app: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'a> Platform<'s, 'a> {
    pub fn open(storage: Pin<&'s mut PlatformStorage>, app: &'a App<'_>) -> Result<Self> {
        let native = unsafe { storage.get_unchecked_mut() }.native.as_mut_ptr();
        let code = unsafe { c::R4SdkPlatformOpen(native, app.start_context()) };
        if code != 0 {
            return Err(Error::Raw(code));
        }
        Ok(Self {
            native: NonNull::new(native).ok_or(Error::InvalidProvider)?,
            _storage: PhantomData,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn open2(
        storage: Pin<&'s mut PlatformStorage>,
        app: &'a crate::app2::App<'_>,
    ) -> Result<Self> {
        let native = unsafe { storage.get_unchecked_mut() }.native.as_mut_ptr();
        let code = unsafe { c::R4SdkPlatformOpen2(native, app.native_context()) };
        if code != 0 {
            return Err(Error::Raw(code));
        }
        Ok(Self {
            native: NonNull::new(native).ok_or(Error::InvalidProvider)?,
            _storage: PhantomData,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn audio(&self) -> Result<Audio<'_>> {
        let raw = NonNull::new(unsafe { c::R4SdkPlatformAudio(self.native.as_ptr()) })
            .ok_or(Error::InvalidProvider)?;
        if value(unsafe { c::R4SdkAudioAudio_available(0, raw.as_ptr()) })?.bits == 0 {
            return Err(Error::Unavailable);
        }
        Ok(Audio {
            native: raw,
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn devices(&self) -> Devices<'_> {
        Devices {
            native: unsafe { c::R4SdkPlatformDevice(self.native.as_ptr()) },
            _loan: PhantomData,
            _local: PhantomData,
        }
    }
    pub fn power(&self, timeout: crate::resources::Timeout) -> Result<Power<'_>> {
        Power::open(
            unsafe { c::R4SdkPlatformSystem(self.native.as_ptr()) },
            timeout,
        )
    }
    pub fn clock(&self) -> Result<abi::MonotonicClockInfo> {
        let mut out = abi::MonotonicClockInfo::default();
        let status = code(unsafe {
            c::R4SdkGuiSystemContext_monotonicClock(
                0,
                c::R4SdkPlatformSystem(self.native.as_ptr()),
                &mut out,
            )
        })?;
        if status == 0 {
            return Err(Error::Unavailable);
        }
        Ok(out)
    }
    /// # Safety
    /// Every subcontext borrows this exact pinned storage and App. Explicit
    /// work, callback ABI/lifetimes and hardware receipts remain the caller's.
    pub unsafe fn native(&self) -> *mut c::R4SdkPlatformContext {
        self.native.as_ptr()
    }
}
fn value(result: c::R4SdkGuiSlot) -> Result<c::R4SdkGuiSlot> {
    if result.status < 0 {
        Err(Error::Raw(result.status))
    } else if result.flags & 2 != 0 {
        Err(Error::InvalidProvider)
    } else {
        Ok(result)
    }
}
fn code(result: c::R4SdkGuiSlot) -> Result<i32> {
    let rc = value(result)?.bits as i32;
    if rc < 0 { Err(Error::Raw(rc)) } else { Ok(rc) }
}
fn timeout(t: crate::resources::Timeout) -> abi::R4Timeout {
    t.raw()
}
