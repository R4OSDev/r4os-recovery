//! Pure rational schedule of accepted PCM; no hardware playback guarantee.
use crate::{c_facades as c, time::checked::ClockSample};
use core::mem::MaybeUninit;
pub type SourceDeadline = c::R4SdkPcmSourceDeadline;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
pub struct Pacer {
    raw: c::R4SdkPcmSourcePacer,
}
impl Pacer {
    pub fn new(
        rate: u32,
        frame_bytes: u32,
        lead_frames: u64,
        sample: ClockSample,
    ) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkPcmSourceInit(
                rate,
                frame_bytes,
                lead_frames,
                sample.raw(),
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
        })
    }
    pub fn accepted(
        &mut self,
        bytes: u64,
        write_started: ClockSample,
    ) -> Result<SourceDeadline, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkPcmSourceAccepted(&mut self.raw, bytes, write_started.raw(), out.as_mut_ptr())
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn deadline(
        &mut self,
        sample: ClockSample,
        finish_source: bool,
    ) -> Result<SourceDeadline, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkPcmSourceGetDeadline(
                &mut self.raw,
                sample.raw(),
                finish_source as u32,
                out.as_mut_ptr(),
            )
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn pause(&mut self, sample: ClockSample) -> Result<(), Error> {
        exact(unsafe { c::R4SdkPcmSourcePause(&mut self.raw, sample.raw(), 0) })
    }
    pub fn resume_source(&mut self, sample: ClockSample) -> Result<(), Error> {
        exact(unsafe { c::R4SdkPcmSourcePause(&mut self.raw, sample.raw(), 1) })
    }
    pub fn reset(
        &mut self,
        rate: u32,
        frame_bytes: u32,
        lead_frames: u64,
        sample: ClockSample,
    ) -> Result<(), Error> {
        let next = Self::new(rate, frame_bytes, lead_frames, sample)?;
        *self = next;
        Ok(())
    }
}
