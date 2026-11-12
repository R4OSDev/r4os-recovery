//! One explicit total deadline over the real AUDSVC stream owner.
use crate::{abi, c_facades as c, platform, platform2::Context, resources::Timeout};
use core::{
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type Progress = c::R4SdkAudioWriteProgress;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
/// Whole PCM and the original stream stay borrowed until the writer ends.
/// Actual synchronous return ends each callback loan. Cancel never closes
/// the stream or acknowledges playback. No automatic replay of uncertainty.
pub struct Writer<'a> {
    raw: c::R4SdkAudioWriter,
    _source: &'a [u8],
    _stream: PhantomData<&'a mut ()>,
    _context: PhantomData<&'a Context<'a>>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Writer<'a> {
    pub fn new(
        stream: &'a mut platform::Stream<'_>,
        source: &'a [u8],
        timeout: Timeout,
    ) -> Result<Self, Error> {
        let provider = c::R4SdkAudioWriterProvider {
            legacy: stream.writer_native(),
            call: None,
            monotonic: None,
            service_handle: 0,
            stream_id: 0,
            frame_bytes: 0,
            reserved0: 0,
        };
        // The shared owner derives the frame width from this actual typed stream.
        unsafe { Self::initialize(source, timeout, provider) }
    }
    /// # Safety
    /// channel/stream must be live, caller-owned AUDSVC handles. They, provider
    /// code and captured native state remain valid and exclusively borrowed
    /// until this writer ends. No close or concurrent RPC. Native callbacks
    /// obey the canonical synchronous wire/clock contracts and retain nothing.
    pub unsafe fn from_native_handles(
        context: &'a Context<'a>,
        channel: u32,
        stream: u32,
        frame_bytes: u32,
        source: &'a [u8],
        timeout: Timeout,
    ) -> Result<Self, Error> {
        let call = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_call) as u32,
            )
            .map_err(Error)?;
        let clock = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, monotonic_clock) as u32,
            )
            .map_err(Error)?;
        let provider = c::R4SdkAudioWriterProvider {
            legacy: core::ptr::null_mut(),
            call: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) }),
            monotonic: Some(unsafe {
                mem::transmute::<u64, abi::R4SysFns::monotonic_clock>(clock)
            }),
            service_handle: channel,
            stream_id: stream,
            frame_bytes,
            reserved0: 0,
        };
        let _ = context;
        unsafe { Self::initialize(source, timeout, provider) }
    }
    unsafe fn initialize(
        source: &'a [u8],
        timeout: Timeout,
        provider: c::R4SdkAudioWriterProvider,
    ) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkAudioWriterInit(
                c::R4SdkWireSpan {
                    address: source.as_ptr() as u64,
                    length: source.len() as u64,
                },
                provider,
                timeout.raw(),
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _source: source,
            _stream: PhantomData,
            _context: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkAudioWriterGetProgress(&self.raw, out.as_mut_ptr()) })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn write_once(&mut self, stop: bool) -> Result<Progress, Error> {
        self.write_bounded(1, stop)
    }
    pub fn write_bounded(&mut self, calls: u32, stop: bool) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkAudioWriterStep(&mut self.raw, calls, stop as u32, out.as_mut_ptr())
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn cancel(&mut self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkAudioWriterCancel(&mut self.raw, out.as_mut_ptr()) })?;
        Ok(unsafe { out.assume_init() })
    }
}
