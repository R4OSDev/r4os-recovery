use super::*;
pub struct Audio<'a> {
    pub(super) native: NonNull<c::R4SdkAudioAudio>,
    pub(super) _loan: PhantomData<&'a ()>,
    pub(super) _local: PhantomData<*mut ()>,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WriteKind {
    Complete,
    Retry,
    TimedOut,
    Failure,
    Invalid,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct WriteProgress {
    pub accepted: usize,
    pub kind: WriteKind,
    pub raw: i32,
}
fn checked(result: *const c::R4SdkAudioResult) -> Result<()> {
    match value(unsafe { c::R4SdkAudioResult_inspect(result) })?.bits as u32 {
        c::R4SdkAudioResult_TAG_ok => Ok(()),
        c::R4SdkAudioResult_TAG_timed_out => Err(Error::Raw(abi::service_api_result_timeout)),
        c::R4SdkAudioResult_TAG_failure => Err(Error::Raw(
            value(unsafe { c::R4SdkAudioResult_get_failure(result) })?.bits as i32,
        )),
        _ => Err(Error::InvalidProvider),
    }
}
impl Audio<'_> {
    pub fn status(&self, t: crate::resources::Timeout) -> Result<abi::AudioServiceStatus> {
        let mut out = abi::AudioServiceStatus::default();
        let mut result = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkAudioAudio_status(
                0,
                self.native.as_ptr(),
                &timeout(t),
                &mut out,
                result.as_mut_ptr(),
            )
        })?;
        checked(result.as_ptr())?;
        Ok(out)
    }
    pub fn open_stream(
        &self,
        rate: u32,
        channels: u16,
        volume: u32,
        t: crate::resources::Timeout,
    ) -> Result<Stream<'_>> {
        let mut result = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkAudioAudio_openStream(
                0,
                self.native.as_ptr(),
                rate,
                channels,
                1,
                volume,
                &timeout(t),
                result.as_mut_ptr(),
            )
        })?;
        let tag = value(unsafe { c::R4SdkAudioOpenResult_inspect(result.as_ptr()) })?.bits as u32;
        match tag {
            c::R4SdkAudioOpenResult_TAG_stream => {
                let mut native = MaybeUninit::uninit();
                value(unsafe {
                    c::R4SdkAudioOpenResult_get_stream(result.as_ptr(), native.as_mut_ptr())
                })?;
                Ok(Stream {
                    native,
                    _loan: PhantomData,
                    _local: PhantomData,
                })
            }
            c::R4SdkAudioOpenResult_TAG_timed_out => {
                Err(Error::Raw(abi::service_api_result_timeout))
            }
            c::R4SdkAudioOpenResult_TAG_no_service => Err(Error::Raw(
                value(unsafe { c::R4SdkAudioOpenResult_get_no_service(result.as_ptr()) })?.bits
                    as i32,
            )),
            c::R4SdkAudioOpenResult_TAG_failure => Err(Error::Raw(
                value(unsafe { c::R4SdkAudioOpenResult_get_failure(result.as_ptr()) })?.bits as i32,
            )),
            _ => Err(Error::InvalidProvider),
        }
    }
    /// # Safety
    /// All generated Audio/AdvancedAudio methods borrow this owner and App;
    /// native synth/DMA acceptance never implies audible playback.
    pub unsafe fn native(&self) -> *mut c::R4SdkAudioAudio {
        self.native.as_ptr()
    }
}
#[must_use = "Close the stream explicitly; Drop is not a native close receipt."]
pub struct Stream<'a> {
    native: MaybeUninit<c::R4SdkAudioAudioStream>,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl Stream<'_> {
    pub(crate) fn writer_native(&mut self) -> *mut c::R4SdkAudioAudioStream {
        self.native.as_mut_ptr()
    }
    pub fn valid(&self) -> Result<bool> {
        Ok(value(unsafe { c::R4SdkAudioAudioStream_valid(0, self.native.as_ptr()) })?.bits != 0)
    }
    pub fn write(
        &mut self,
        data: &[u8],
        t: crate::resources::Timeout,
        once: bool,
    ) -> Result<WriteProgress> {
        let mut out = MaybeUninit::uninit();
        let result = unsafe {
            if once {
                c::R4SdkAudioAudioStream_writeOnce(
                    0,
                    self.native.as_mut_ptr(),
                    data.as_ptr(),
                    data.len() as u64,
                    &timeout(t),
                    out.as_mut_ptr(),
                )
            } else {
                c::R4SdkAudioAudioStream_write(
                    0,
                    self.native.as_mut_ptr(),
                    data.as_ptr(),
                    data.len() as u64,
                    &timeout(t),
                    out.as_mut_ptr(),
                )
            }
        };
        value(result)?;
        let tag = value(unsafe { c::R4SdkAudioWriteResult_inspect(out.as_ptr()) })?.bits as u32;
        let (accepted, kind, raw) = match tag {
            c::R4SdkAudioWriteResult_TAG_written => (
                value(unsafe { c::R4SdkAudioWriteResult_get_written(out.as_ptr()) })?.bits as usize,
                WriteKind::Complete,
                0,
            ),
            c::R4SdkAudioWriteResult_TAG_busy => (
                value(unsafe { c::R4SdkAudioWriteResult_get_busy(out.as_ptr()) })?.bits as usize,
                WriteKind::Retry,
                abi::service_api_result_busy,
            ),
            c::R4SdkAudioWriteResult_TAG_timed_out => (
                value(unsafe { c::R4SdkAudioWriteResult_get_timed_out(out.as_ptr()) })?.bits
                    as usize,
                WriteKind::TimedOut,
                abi::service_api_result_timeout,
            ),
            c::R4SdkAudioWriteResult_TAG_failure => {
                let mut f = MaybeUninit::uninit();
                value(unsafe {
                    c::R4SdkAudioWriteResult_get_failure(out.as_ptr(), f.as_mut_ptr())
                })?;
                (
                    value(unsafe { c::R4SdkAudioWriteFailure_get_written(f.as_ptr()) })?.bits
                        as usize,
                    WriteKind::Failure,
                    value(unsafe { c::R4SdkAudioWriteFailure_get_raw(f.as_ptr()) })?.bits as i32,
                )
            }
            _ => return Err(Error::InvalidProvider),
        };
        if accepted > data.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(WriteProgress {
            accepted,
            kind,
            raw,
        })
    }
    pub fn close(&mut self, t: crate::resources::Timeout) -> Result<()> {
        let mut out = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkAudioAudioStream_close(
                0,
                self.native.as_mut_ptr(),
                &timeout(t),
                out.as_mut_ptr(),
            )
        })?;
        checked(out.as_ptr())
    }
    pub fn set_volume(&mut self, volume: u32, t: crate::resources::Timeout) -> Result<()> {
        let mut out = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkAudioAudioStream_setVolume(
                0,
                self.native.as_mut_ptr(),
                volume,
                &timeout(t),
                out.as_mut_ptr(),
            )
        })?;
        checked(out.as_ptr())
    }
}
pub struct WriteCursor {
    native: MaybeUninit<c::R4SdkAudioWriteCursor>,
}
impl WriteCursor {
    pub fn new(total: usize, frame_bytes: usize) -> Result<Option<Self>> {
        let mut native = MaybeUninit::uninit();
        let r = value(unsafe {
            c::R4SdkAudioWriteCursor_init(0, total as u64, frame_bytes as u64, native.as_mut_ptr())
        })?;
        Ok(if r.flags & 1 != 0 {
            Some(Self { native })
        } else {
            None
        })
    }
    pub fn remaining(&self) -> Result<usize> {
        Ok(
            value(unsafe { c::R4SdkAudioWriteCursor_remaining(0, self.native.as_ptr()) })?.bits
                as usize,
        )
    }
    pub fn apply(&mut self, progress: WriteProgress) -> Result<WriteProgress> {
        let mut r = MaybeUninit::uninit();
        match progress.kind {
            WriteKind::Complete => {
                value(unsafe {
                    c::R4SdkAudioWriteResult_set_written(r.as_mut_ptr(), progress.accepted as u64)
                })?;
            }
            WriteKind::Retry => {
                value(unsafe {
                    c::R4SdkAudioWriteResult_set_busy(r.as_mut_ptr(), progress.accepted as u64)
                })?;
            }
            WriteKind::TimedOut => {
                value(unsafe {
                    c::R4SdkAudioWriteResult_set_timed_out(r.as_mut_ptr(), progress.accepted as u64)
                })?;
            }
            WriteKind::Failure => {
                let mut f = MaybeUninit::uninit();
                value(unsafe {
                    c::R4SdkAudioWriteFailure_from_fields(
                        f.as_mut_ptr(),
                        progress.raw,
                        progress.accepted as u64,
                    )
                })?;
                value(unsafe { c::R4SdkAudioWriteResult_set_failure(r.as_mut_ptr(), f.as_ptr()) })?;
            }
            WriteKind::Invalid => return Err(Error::InvalidProvider),
        }
        let mut out = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkAudioWriteCursor_apply(
                0,
                self.native.as_mut_ptr(),
                r.as_ptr(),
                out.as_mut_ptr(),
            )
        })?;
        let kind = match value(unsafe { c::R4SdkAudioWriteAdvance_get_outcome(out.as_ptr()) })?.bits
            as u32
        {
            c::R4SdkAudioWriteOutcome_complete => WriteKind::Complete,
            c::R4SdkAudioWriteOutcome_retry => WriteKind::Retry,
            c::R4SdkAudioWriteOutcome_timed_out => WriteKind::TimedOut,
            c::R4SdkAudioWriteOutcome_failure => WriteKind::Failure,
            _ => WriteKind::Invalid,
        };
        Ok(WriteProgress {
            accepted: value(unsafe { c::R4SdkAudioWriteAdvance_get_accepted(out.as_ptr()) })?.bits
                as usize,
            kind,
            raw: value(unsafe { c::R4SdkAudioWriteAdvance_get_raw(out.as_ptr()) })?.bits as i32,
        })
    }
}
