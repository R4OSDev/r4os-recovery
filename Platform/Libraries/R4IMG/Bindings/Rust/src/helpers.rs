//! CPU image consumers; all decoding, scaling and metadata policy stay native.
use crate::{Error, Result, raw as c, required, scalar, view};
use core::{marker::PhantomData, mem::MaybeUninit};
use r4os_sdk::App;

pub struct Images<'a> {
    native: MaybeUninit<c::R4ImgHelpersContext>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Format {
    Png,
    Jpeg,
    Bmp,
    Svg,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Info {
    pub format: Format,
    pub width: u32,
    pub height: u32,
    pub channels: u8,
}
impl Info {
    fn read(value: *const c::R4ImgHelpersInfo) -> Result<Self> {
        Ok(Self {
            format: match scalar(unsafe { c::R4ImgHelpersInfo_get_format(value) })? {
                0 => Format::Png,
                1 => Format::Jpeg,
                2 => Format::Bmp,
                3 => Format::Svg,
                _ => return Err(Error::InvalidProvider),
            },
            width: scalar(unsafe { c::R4ImgHelpersInfo_get_width(value) })? as u32,
            height: scalar(unsafe { c::R4ImgHelpersInfo_get_height(value) })? as u32,
            channels: scalar(unsafe { c::R4ImgHelpersInfo_get_channels(value) })? as u8,
        })
    }
    fn native(self) -> Result<MaybeUninit<c::R4ImgHelpersInfo>> {
        let mut out = MaybeUninit::uninit();
        let format = match self.format {
            Format::Png => 0,
            Format::Jpeg => 1,
            Format::Bmp => 2,
            Format::Svg => 3,
        };
        required(unsafe {
            c::R4ImgHelpersInfo_from_fields(
                out.as_mut_ptr(),
                format,
                self.width,
                self.height,
                self.channels,
            )
        })?;
        Ok(out)
    }
    pub fn pixel_count(self) -> Result<usize> {
        let native = self.native()?;
        Ok(scalar(unsafe { c::R4ImgHelpersInfo_pixelCount(0, native.as_ptr()) })? as usize)
    }
}
pub struct Image<'p> {
    pub info: Info,
    pub pixels: &'p mut [u32],
}
impl<'a> Images<'a> {
    pub fn open(app: &'a App<'_>) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4ImgHelpersContext_init(0, app.start_context(), native.as_mut_ptr())
        })?;
        Ok(Self {
            native,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn probe(&self, bytes: &[u8], content_type: &str) -> Result<Info> {
        let mut info = MaybeUninit::uninit();
        required(unsafe {
            c::R4ImgHelpersContext_probe(
                0,
                self.native.as_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                content_type.as_ptr(),
                content_type.len() as u64,
                info.as_mut_ptr(),
            )
        })?;
        Info::read(info.as_ptr())
    }
    pub fn scratch_bytes(&self, info: Info, encoded_bytes: usize) -> Result<usize> {
        let native = info.native()?;
        Ok(scalar(unsafe {
            c::R4ImgHelpersContext_scratchBytesFor(
                0,
                self.native.as_ptr(),
                native.as_ptr(),
                encoded_bytes as u64,
            )
        })? as usize)
    }
    pub fn decode<'p>(
        &self,
        bytes: &[u8],
        content_type: &str,
        pixels: &'p mut [u32],
        scratch: &mut [u8],
    ) -> Result<Image<'p>> {
        let mut image = MaybeUninit::uninit();
        required(unsafe {
            c::R4ImgHelpersContext_decode(
                0,
                self.native.as_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                content_type.as_ptr(),
                content_type.len() as u64,
                pixels.as_mut_ptr(),
                pixels.len() as u64,
                scratch.as_mut_ptr(),
                scratch.len() as u64,
                image.as_mut_ptr(),
            )
        })?;
        Self::image(image.as_ptr(), pixels)
    }
    pub fn decode_svg<'p>(
        &self,
        bytes: &[u8],
        pixels: &'p mut [u32],
        scratch: &mut [u8],
        width: u32,
        height: u32,
    ) -> Result<Image<'p>> {
        let mut options = MaybeUninit::uninit();
        let mut image = MaybeUninit::uninit();
        required(unsafe { c::R4ImgHelpersSvgRenderOptions_create(options.as_mut_ptr()) })?;
        required(unsafe {
            c::R4ImgHelpersContext_decodeSvgAt(
                0,
                self.native.as_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                b"image/svg+xml".as_ptr(),
                13,
                pixels.as_mut_ptr(),
                pixels.len() as u64,
                scratch.as_mut_ptr(),
                scratch.len() as u64,
                width,
                height,
                options.as_ptr(),
                image.as_mut_ptr(),
            )
        })?;
        Self::image(image.as_ptr(), pixels)
    }
    fn image<'p>(native: *const c::R4ImgHelpersImage, pixels: &'p mut [u32]) -> Result<Image<'p>> {
        let mut info = MaybeUninit::uninit();
        required(unsafe { c::R4ImgHelpersImage_get_info(native, info.as_mut_ptr()) })?;
        let length = view(unsafe { c::R4ImgHelpersImage_get_pixels(native) }, pixels)?.len();
        Ok(Image {
            info: Info::read(info.as_ptr())?,
            pixels: &mut pixels[..length],
        })
    }
    pub fn scale_composite<'p>(
        &self,
        image: &Image<'_>,
        destination: &'p mut [u32],
        width: u32,
        height: u32,
        background: u32,
    ) -> Result<&'p mut [u32]> {
        let info = image.info.native()?;
        let mut native = MaybeUninit::uninit();
        // The original input slice is mutable in Zig but scaling only reads it.
        required(unsafe {
            c::R4ImgHelpersImage_create(
                native.as_mut_ptr(),
                info.as_ptr(),
                image.pixels.as_ptr().cast_mut(),
                image.pixels.len() as u64,
            )
        })?;
        let length = view(
            unsafe {
                c::R4ImgHelpersContext_scaleComposite(
                    0,
                    self.native.as_ptr(),
                    native.as_ptr(),
                    destination.as_mut_ptr(),
                    destination.len() as u64,
                    width,
                    height,
                    background,
                )
            },
            destination,
        )?
        .len();
        Ok(&mut destination[..length])
    }
}
/// Optional PNG16 interface. Metadata/ICC and precision remain R4IMG-owned;
/// explicit color conversion and native JPEG orchestration are in `raw`.
pub struct Png<'a> {
    native: MaybeUninit<c::R4ImgHelpersPngContext>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
pub struct Image16<'p> {
    pub info: Info,
    pub rgba: &'p mut [u16],
}
impl<'a> Png<'a> {
    pub fn open(app: &'a App<'_>) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4ImgHelpersPngContext_init(0, app.start_context(), native.as_mut_ptr())
        })?;
        Ok(Self {
            native,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn scratch_bytes(&self, info: Info, encoded_bytes: usize) -> Result<usize> {
        let info = info.native()?;
        Ok(scalar(unsafe {
            c::R4ImgHelpersPngContext_pngScratchBytes16(
                0,
                self.native.as_ptr(),
                info.as_ptr(),
                encoded_bytes as u64,
            )
        })? as usize)
    }
    pub fn icc_profile<'p>(&self, bytes: &[u8], output: &'p mut [u8]) -> Result<&'p [u8]> {
        view(
            unsafe {
                c::R4ImgHelpersPngContext_pngIccProfile(
                    0,
                    self.native.as_ptr(),
                    bytes.as_ptr(),
                    bytes.len() as u64,
                    output.as_mut_ptr(),
                    output.len() as u64,
                )
            },
            output,
        )
    }
    pub fn decode<'p>(
        &self,
        bytes: &[u8],
        rgba: &'p mut [u16],
        scratch: &mut [u8],
    ) -> Result<Image16<'p>> {
        let mut image = MaybeUninit::uninit();
        let mut info = MaybeUninit::uninit();
        required(unsafe {
            c::R4ImgHelpersPngContext_pngDecode16(
                0,
                self.native.as_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                rgba.as_mut_ptr(),
                rgba.len() as u64,
                scratch.as_mut_ptr(),
                scratch.len() as u64,
                image.as_mut_ptr(),
            )
        })?;
        required(unsafe { c::R4ImgHelpersImage16_get_info(image.as_ptr(), info.as_mut_ptr()) })?;
        let length = view(
            unsafe { c::R4ImgHelpersImage16_get_rgba(image.as_ptr()) },
            rgba,
        )?
        .len();
        Ok(Image16 {
            info: Info::read(info.as_ptr())?,
            rgba: &mut rgba[..length],
        })
    }
}
