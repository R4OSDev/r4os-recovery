use super::*;
use core::sync::atomic::{AtomicU32, Ordering};
/// Shared atomic stop intent. Requesting it never acknowledges work completion.
#[repr(transparent)]
pub struct StopFlag(AtomicU32);
impl Default for StopFlag {
    fn default() -> Self {
        Self::new()
    }
}
impl StopFlag {
    pub const fn new() -> Self {
        Self(AtomicU32::new(0))
    }
    pub fn request(&self) {
        self.0.store(1, Ordering::Release);
    }
    pub fn requested(&self) -> bool {
        self.0.load(Ordering::Acquire) != 0
    }
    /// Reset only after the previous users have acknowledged their completion.
    pub fn clear(&mut self) {
        *self.0.get_mut() = 0;
    }
}
const _: () = {
    assert!(core::mem::size_of::<StopFlag>() == core::mem::size_of::<abi::R4StopFlag>());
    assert!(core::mem::align_of::<StopFlag>() == core::mem::align_of::<abi::R4StopFlag>());
};
#[must_use = "close the exact native notification after its waiters finish"]
pub struct Notification<'a> {
    owner: &'a Resources<'a>,
    handle: u64,
}
impl Resources<'_> {
    pub fn notification(&self) -> Result<Notification<'_>> {
        let mut handle = 0;
        exact(unsafe { c::r4_resources_notification_create(&mut self.raw(), &mut handle) })?;
        if handle == 0 {
            return Err(Error::InvalidProvider);
        }
        Ok(Notification {
            owner: self,
            handle,
        })
    }
}
impl Notification<'_> {
    pub fn valid(&self) -> bool {
        self.handle != 0
    }
    pub fn handle(&self) -> u64 {
        self.handle
    }
    pub fn sequence(&self) -> Result<u64> {
        if !self.valid() {
            return Err(Error::Raw(abi::err_closed));
        }
        let mut sequence = 0;
        exact(unsafe {
            c::r4_resources_notification_query(&mut self.owner.raw(), self.handle, &mut sequence)
        })?;
        Ok(sequence)
    }
    pub fn notify(&self, count: u32) -> Result<()> {
        if !self.valid() {
            return Err(Error::Raw(abi::err_closed));
        }
        exact(unsafe {
            c::r4_resources_notification_notify(&mut self.owner.raw(), self.handle, count)
        })
    }
    pub fn wait(&self, observed: u64, timeout: Timeout) -> Result<Wait<()>> {
        if !self.valid() {
            return Err(Error::Raw(abi::err_closed));
        }
        match unsafe {
            c::r4_resources_notification_wait(
                &mut self.owner.raw(),
                self.handle,
                observed,
                self.owner.timeout_ticks(timeout)?,
            )
        } {
            abi::notification_ok => Ok(Wait::Completed(())),
            abi::notification_timeout => Ok(Wait::TimedOut),
            raw => Err(Error::Raw(raw)),
        }
    }
    pub fn close(&mut self) -> Result<()> {
        if !self.valid() {
            return Err(Error::Raw(abi::err_closed));
        }
        exact(unsafe { c::r4_resources_notification_close(&mut self.owner.raw(), self.handle) })?;
        self.handle = 0;
        Ok(())
    }
}
