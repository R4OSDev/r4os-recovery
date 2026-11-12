use super::*;
/// The original Zig streaming PCM converter; native state holds samples and
/// numeric offsets, never a foreign input pointer or Rust self-reference.
pub struct Resampler {
    native: MaybeUninit<c::R4SdkPcmResamplerState>,
}
impl Resampler {
    pub fn new() -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        value(unsafe { c::R4SdkPcmResamplerState_create(native.as_mut_ptr()) })?;
        Ok(Self { native })
    }
    pub fn begin(&mut self, rate: u32, channels: u16, format: u16) -> Result<()> {
        value(unsafe {
            c::R4SdkPcmResamplerState_beginChunk(
                0,
                self.native.as_mut_ptr(),
                rate,
                channels,
                format,
            )
        })?;
        Ok(())
    }
    pub fn convert(
        &mut self,
        input: &[u8],
        rate: u32,
        channels: u16,
        format: u16,
        output: &mut [u8],
    ) -> Result<usize> {
        let count = value(unsafe {
            c::R4SdkPcm_convertStreamingToStereoS16(
                0,
                self.native.as_mut_ptr(),
                input.as_ptr(),
                input.len() as u64,
                rate,
                channels,
                format,
                output.as_mut_ptr(),
                output.len() as u64,
            )
        })?
        .bits as usize;
        if count > output.len() {
            Err(Error::InvalidProvider)
        } else {
            Ok(count)
        }
    }
    pub fn finish(&mut self, output: &mut [u8]) -> Result<usize> {
        let n = value(unsafe {
            c::R4SdkPcm_finishStreamingToStereoS16(
                0,
                self.native.as_mut_ptr(),
                output.as_mut_ptr(),
                output.len() as u64,
            )
        })?
        .bits as usize;
        if n > output.len() {
            Err(Error::InvalidProvider)
        } else {
            Ok(n)
        }
    }
    pub fn pending_tail_bytes(&self) -> Result<usize> {
        Ok(value(unsafe { c::R4SdkPcm_pendingTailBytes(0, self.native.as_ptr()) })?.bits as usize)
    }
    pub fn take_direct<'a>(
        &mut self,
        input: &'a [u8],
        rate: u32,
        channels: u16,
        format: u16,
        max_bytes: usize,
    ) -> Result<Option<&'a [u8]>> {
        let r = value(unsafe {
            c::R4SdkPcm_takeDirectChunk(
                0,
                self.native.as_mut_ptr(),
                input.as_ptr(),
                input.len() as u64,
                rate,
                channels,
                format,
                max_bytes as u64,
            )
        })?;
        if r.flags & 1 == 0 {
            return Ok(None);
        }
        if r.length == 0 {
            return Ok(Some(&input[..0]));
        }
        let offset = (r.ptr as usize)
            .checked_sub(input.as_ptr() as usize)
            .ok_or(Error::InvalidProvider)?;
        let end = offset
            .checked_add(usize::try_from(r.length).map_err(|_| Error::Length)?)
            .ok_or(Error::Length)?;
        input
            .get(offset..end)
            .map(Some)
            .ok_or(Error::InvalidProvider)
    }
}
