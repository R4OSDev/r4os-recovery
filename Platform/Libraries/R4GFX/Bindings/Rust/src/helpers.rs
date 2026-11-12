//! Receiver parsing remains R4GFX-owned. Hardware admission and asynchronous
//! output/readback/profile owners are exposed through the checked raw boundary.
use crate::{Error, Heap, Result, raw as c, result, scalar, storage};
use alloc::boxed::Box;
use core::{marker::PhantomData, mem::MaybeUninit};
use r4os_sdk::App;

/// Retained original COLOR_V1 transform. Opening copies the profile bytes;
/// its native storage and allocator remain alive until the close acknowledgement.
pub struct ColorProfile<'a, 'h> {
    native: Box<MaybeUninit<c::R4GfxDisplayProfileOwner>>,
    _app: PhantomData<&'a App<'a>>,
    _heap: &'h Heap,
}
impl<'a, 'h> ColorProfile<'a, 'h> {
    pub fn open(
        app: &'a App<'a>,
        heap: &'h Heap,
        bytes: &[u8],
        intent: u32,
        flags: u32,
    ) -> Result<Self> {
        let mut colors = MaybeUninit::uninit();
        crate::required(unsafe {
            c::R4Library_colorClient(0, app.start_context(), colors.as_mut_ptr())
        })?;
        let allocator = heap.allocator()?;
        let mut native = storage();
        crate::required(unsafe {
            c::R4GfxDisplayProfileOwner_open(
                0,
                allocator.as_ptr(),
                colors.as_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                intent,
                flags,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            native,
            _app: PhantomData,
            _heap: heap,
        })
    }
    /// Use only unpublished pixels. On error discard the entire frame, since
    /// the original owner may have converted a prefix. Retain canonical SDR
    /// pixels separately, rather than feeding monitor-encoded pixels back in.
    pub fn apply_sdr(&mut self, pixels: &mut [u32], width: u32, height: u32) -> Result<()> {
        result(unsafe {
            c::R4GfxDisplayProfileOwner_applySdr(
                0,
                self.native.as_ptr(),
                pixels.as_mut_ptr(),
                pixels.len() as u64,
                width,
                height,
            )
        })?;
        Ok(())
    }
}
impl Drop for ColorProfile<'_, '_> {
    fn drop(&mut self) {
        assert!(
            scalar(unsafe { c::R4GfxDisplayProfileOwner_close(0, self.native.as_mut_ptr()) })
                == Ok(1),
            "native color profile release failed"
        );
    }
}
pub struct Receiver {
    native: Box<MaybeUninit<c::R4GfxEdidReport>>,
}
impl Receiver {
    pub fn parse(bytes: &[u8]) -> Result<Self> {
        let mut native = storage();
        result(unsafe {
            c::R4GfxEdid_parse(0, bytes.as_ptr(), bytes.len() as u64, native.as_mut_ptr())
        })?;
        Ok(Self { native })
    }
    pub fn complete(&self) -> Result<bool> {
        Ok(scalar(unsafe { c::R4GfxEdidReport_complete(0, self.native.as_ptr()) })? != 0)
    }
    pub fn digital(&self) -> Result<bool> {
        Ok(scalar(unsafe { c::R4GfxEdidReport_get_digital(self.native.as_ptr()) })? != 0)
    }
    pub fn mode_count(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4GfxEdidReport_get_mode_count(self.native.as_ptr()) })? as usize)
    }
    pub fn product(&self) -> Result<u16> {
        Ok(scalar(unsafe { c::R4GfxEdidReport_get_product(self.native.as_ptr()) })? as u16)
    }
    pub fn manufacturer(&self) -> Result<[u8; 3]> {
        let mut out = MaybeUninit::<[u8; 3]>::uninit();
        crate::required(unsafe {
            c::R4GfxEdidReport_get_manufacturer(self.native.as_ptr(), out.as_mut_ptr().cast())
        })?;
        // This declared three-byte array has no private layout or padding.
        Ok(unsafe { out.assume_init() })
    }
    pub fn timing(&self, index: usize) -> Result<(u32, u32, u32)> {
        let count = self.mode_count()?;
        if index >= count || count > 128 {
            return Err(Error::InvalidProvider);
        }
        let mut timings = MaybeUninit::<[c::R4GfxTimingTiming; 128]>::uninit();
        crate::required(unsafe {
            c::R4GfxEdidReport_get_modes(self.native.as_ptr(), timings.as_mut_ptr().cast())
        })?;
        let value = unsafe { timings.as_ptr().cast::<c::R4GfxTimingTiming>().add(index) };
        Ok((
            scalar(unsafe { c::R4GfxTimingTiming_get_width(value) })? as u32,
            scalar(unsafe { c::R4GfxTimingTiming_get_height(value) })? as u32,
            scalar(unsafe { c::R4GfxTimingTiming_millihz(0, value) })? as u32,
        ))
    }
}
