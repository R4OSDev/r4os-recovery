//! The media clock preserves the original pause/seek/regression semantics.
//! Advanced Session/Composition/Audio remain in raw: retain every target,
//! decoder frame, callback and buffer through the original release receipts.
use crate::{Result, raw as c, required, result, scalar};
use core::mem::MaybeUninit;
pub struct Clock {
    native: MaybeUninit<c::R4VideoPlaybackClockClock>,
}
impl Clock {
    pub fn new(now: u64, position: i64) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4VideoPlaybackClockClock_init(0, now, position, native.as_mut_ptr())
        })?;
        Ok(Self { native })
    }
    pub fn position(&mut self, now: u64) -> Result<i64> {
        Ok(scalar(unsafe {
            c::R4VideoPlaybackClockClock_position(0, self.native.as_mut_ptr(), now)
        })? as i64)
    }
    pub fn pause(&mut self, now: u64, paused: bool) -> Result<()> {
        result(unsafe {
            c::R4VideoPlaybackClockClock_setPaused(
                0,
                self.native.as_mut_ptr(),
                now,
                u8::from(paused),
            )
        })
        .map(|_| ())
    }
    pub fn seek(&mut self, now: u64, position: i64) -> Result<()> {
        result(unsafe {
            c::R4VideoPlaybackClockClock_seek(0, self.native.as_mut_ptr(), now, position)
        })
        .map(|_| ())
    }
    pub fn sample_time(origin: i64, frames: u64, rate: u32) -> Result<i64> {
        Ok(scalar(unsafe { c::R4VideoPlaybackClock_sampleTime(0, origin, frames, rate) })? as i64)
    }
}
