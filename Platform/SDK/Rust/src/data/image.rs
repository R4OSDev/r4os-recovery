use super::{Error, Result, required, result, scalar, view};
use crate::c_facades as c;
use core::{marker::PhantomData, mem::MaybeUninit};
pub struct Raster<'a> {
    native: MaybeUninit<c::R4SdkDataRasterImage>,
    pixels: &'a mut [u32],
}
impl<'a> Raster<'a> {
    pub fn new(pixels: &'a mut [u32], width: u32, height: u32, background: u32) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataRaster_init(
                0,
                pixels.as_mut_ptr(),
                pixels.len() as u64,
                width,
                height,
                background,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Self { native, pixels })
    }
    pub fn pixels(&self) -> Result<&[u32]> {
        view(
            unsafe { c::R4SdkDataRasterImage_pixelsConst(0, self.native.as_ptr()) },
            self.pixels,
        )
    }
    pub fn pixel(&self, x: u32, y: u32) -> Result<Option<u32>> {
        let v = result(unsafe { c::R4SdkDataRasterImage_pixelAt(0, self.native.as_ptr(), x, y) })?;
        Ok(if v.flags & 1 == 0 {
            None
        } else {
            Some(v.bits as u32)
        })
    }
    pub fn set(&mut self, x: u32, y: u32, color: u32) -> Result<bool> {
        Ok(scalar(unsafe {
            c::R4SdkDataRasterImage_setPixel(0, self.native.as_ptr(), x, y, color)
        })? != 0)
    }
    pub fn fill(&mut self, color: u32) -> Result<()> {
        result(unsafe { c::R4SdkDataRasterImage_fill(0, self.native.as_ptr(), color) })?;
        Ok(())
    }
    pub fn resize(&mut self, width: u32, height: u32, background: u32) -> Result<()> {
        result(unsafe {
            c::R4SdkDataRasterImage_resize(0, self.native.as_mut_ptr(), width, height, background)
        })?;
        Ok(())
    }
}
pub struct Icon<'a> {
    bytes: &'a [u8],
    native: MaybeUninit<c::R4SdkDataIcoDirectory>,
}
impl<'a> Icon<'a> {
    pub fn open(bytes: &'a [u8]) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataIco_parseDirectory(
                0,
                bytes.as_ptr(),
                bytes.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Self { bytes, native })
    }
    pub fn count(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4SdkDataIcoDirectory_get_count(self.native.as_ptr()) })? as usize)
    }
    pub fn bitmap(&self, index: usize) -> Result<Bitmap<'a>> {
        if index >= self.count()? {
            return Err(Error::Bounds);
        }
        let mut entry = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataIco_entryAt(
                0,
                self.bytes.as_ptr(),
                self.bytes.len() as u64,
                index as u64,
                entry.as_mut_ptr(),
            )
        })?;
        self.decode(unsafe { entry.assume_init_ref() })
    }
    /// Select and decode with the original ICO owner's size/depth policy.
    pub fn best_bitmap(&self, preferred_size: u16) -> Result<Bitmap<'a>> {
        let mut entry = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataIco_chooseBest(
                0,
                self.bytes.as_ptr(),
                self.bytes.len() as u64,
                preferred_size,
                entry.as_mut_ptr(),
            )
        })?;
        self.decode(unsafe { entry.assume_init_ref() })
    }
    fn decode(&self, entry: &c::R4SdkDataIcoEntry) -> Result<Bitmap<'a>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataIco_parseBmpImage(
                0,
                self.bytes.as_ptr(),
                self.bytes.len() as u64,
                entry,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Bitmap {
            bytes: self.bytes,
            native,
            _source: PhantomData,
        })
    }
}
pub struct Bitmap<'a> {
    bytes: &'a [u8],
    native: MaybeUninit<c::R4SdkDataIcoBitmapImage>,
    _source: PhantomData<&'a [u8]>,
}
impl Bitmap<'_> {
    /// Copy nearest-neighbour RGB/alpha pixels through one native call. Stride
    /// counts pixels; padding is preserved. All borrows end at return.
    pub fn copy_scaled_pixels(
        &self,
        rgb: &mut [u32],
        alpha: &mut [u8],
        width: u32,
        height: u32,
        stride: usize,
    ) -> Result<()> {
        if scalar(unsafe {
            c::R4SdkDataIco_copyScaledPixels(
                0,
                self.bytes.as_ptr(),
                self.bytes.len() as u64,
                self.native.as_ptr(),
                rgb.as_mut_ptr(),
                rgb.len() as u64,
                alpha.as_mut_ptr(),
                alpha.len() as u64,
                width,
                height,
                stride as u64,
            )
        })? == 0
        {
            return Err(Error::Bounds);
        }
        Ok(())
    }
    pub fn dimensions(&self) -> Result<(u32, u32)> {
        Ok((
            scalar(unsafe { c::R4SdkDataIcoBitmapImage_get_width(self.native.as_ptr()) })? as u32,
            scalar(unsafe { c::R4SdkDataIcoBitmapImage_get_height(self.native.as_ptr()) })? as u32,
        ))
    }
    pub fn pixel(&self, x: u32, y: u32) -> Result<Option<(u32, u8)>> {
        let mut v = MaybeUninit::uninit();
        let s = result(unsafe {
            c::R4SdkDataIco_pixelAt(
                0,
                self.bytes.as_ptr(),
                self.bytes.len() as u64,
                self.native.as_ptr(),
                x,
                y,
                v.as_mut_ptr(),
            )
        })?;
        if s.flags & 1 == 0 {
            return Ok(None);
        }
        Ok(Some((
            scalar(unsafe { c::R4SdkDataIcoPixel_get_rgb(v.as_ptr()) })? as u32,
            scalar(unsafe { c::R4SdkDataIcoPixel_get_alpha(v.as_ptr()) })? as u8,
        )))
    }
}
