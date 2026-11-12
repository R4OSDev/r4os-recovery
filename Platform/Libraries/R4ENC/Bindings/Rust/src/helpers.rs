//! Recording/pixel helpers invoke the original bounded owner algorithms.
use crate::{Error, Result, raw as c, required, result, scalar, storage};
use alloc::boxed::Box;
use core::mem::MaybeUninit;

pub struct Mux {
    native: Box<MaybeUninit<c::R4EncMuxWriter>>,
}
impl Mux {
    pub fn new(width: u32, height: u32) -> Result<Self> {
        let mut native = storage();
        required(unsafe { c::R4EncMuxWriter_create(native.as_mut_ptr(), width, height) })?;
        Ok(Self { native })
    }
    /// Set the original writer's CICP transfer/chroma metadata before any
    /// packets. Pixel conversion and validation remain with their owners.
    pub fn with_color(
        width: u32,
        height: u32,
        transfer: u8,
        centered_chroma: bool,
    ) -> Result<Self> {
        let mut writer = Self::new(width, height)?;
        let mut color = MaybeUninit::uninit();
        required(unsafe {
            c::R4EncMuxColor_from_fields(color.as_mut_ptr(), transfer, u8::from(centered_chroma))
        })?;
        result(unsafe { c::R4EncMuxWriter_set_color(writer.native.as_mut_ptr(), color.as_ptr()) })?;
        Ok(writer)
    }
    /// The sink runs synchronously and must acknowledge every byte before
    /// returning true. Failure preserves the original failed-writer state;
    /// the caller discards the staged file. No packet/sink loan is retained.
    pub fn packet<F: FnMut(&[u8]) -> bool>(
        &mut self,
        bytes: &[u8],
        key: bool,
        pts_ns: i64,
        duration_ns: u64,
        mut write: F,
    ) -> Result<()> {
        unsafe extern "C" fn callback<F: FnMut(&[u8]) -> bool>(
            context: *mut core::ffi::c_void,
            bytes: *const u8,
            length: usize,
        ) -> u8 {
            if context.is_null() || length > isize::MAX as usize || (bytes.is_null() && length != 0)
            {
                return 0;
            }
            let data = if length == 0 {
                &[]
            } else {
                unsafe { core::slice::from_raw_parts(bytes, length) }
            };
            u8::from(unsafe { (&mut *context.cast::<F>())(data) })
        }
        let mut sink = MaybeUninit::uninit();
        let context = c::R4LibrariesSlot {
            ptr: (&mut write as *mut F).cast(),
            length: 0,
            bits: 0,
            status: 0,
            flags: 1,
        };
        required(unsafe {
            c::R4MediaSink_from_fields(
                sink.as_mut_ptr(),
                context,
                callback::<F> as *const () as usize as u64,
            )
        })?;
        result(unsafe {
            c::R4Media_muxPacket(
                0,
                self.native.as_mut_ptr(),
                sink.as_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                u8::from(key),
                pts_ns,
                duration_ns,
            )
        })
        .map(|_| ())
    }
    pub fn frames(&self) -> Result<u64> {
        scalar(unsafe { c::R4EncMuxWriter_get_frames(self.native.as_ptr()) })
    }
    pub fn failed(&self) -> Result<bool> {
        Ok(scalar(unsafe { c::R4EncMuxWriter_get_failed(self.native.as_ptr()) })? != 0)
    }
}
pub struct Nv12 {
    native: MaybeUninit<c::R4EncPixelsLayout>,
}
impl Nv12 {
    pub fn new(width: u32, height: u32, amd_vcn1: bool) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            if amd_vcn1 {
                c::R4EncPixelsLayout_initAmd(0, width, height, native.as_mut_ptr())
            } else {
                c::R4EncPixelsLayout_init(0, width, height, native.as_mut_ptr())
            }
        })?;
        Ok(Self { native })
    }
    pub fn bytes(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4EncPixelsLayout_get_bytes(self.native.as_ptr()) })? as usize)
    }
    pub fn pitch(&self) -> Result<u32> {
        Ok(scalar(unsafe { c::R4EncPixelsLayout_get_pitch(self.native.as_ptr()) })? as u32)
    }
    pub fn uv_offset(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4EncPixelsLayout_get_uv_offset(self.native.as_ptr()) })? as usize)
    }
    pub fn rows(
        &self,
        pixels: &[u32],
        stride: u32,
        output: &mut [u8],
        first: u32,
        count: u32,
    ) -> Result<()> {
        result(unsafe {
            c::R4EncPixels_rows(
                0,
                pixels.as_ptr(),
                pixels.len() as u64,
                stride,
                self.native.as_ptr(),
                output.as_mut_ptr(),
                output.len() as u64,
                first,
                count,
            )
        })
        .map(|_| ())
    }
}
#[repr(u32)]
pub enum BuiltinShader {
    Fullscreen,
    Color,
    Copy,
    Fill,
    Shared,
    Sample,
}
pub fn shader(kind: BuiltinShader) -> Result<&'static [u32]> {
    let value = required(unsafe { c::R4Media_shader(0, kind as u32) })?;
    if value.ptr.is_null()
        || !(value.ptr as usize).is_multiple_of(4)
        || value.length > (isize::MAX as u64) / 4
    {
        return Err(Error::InvalidProvider);
    }
    // Original immutable R4ACO shader data resident in the consumer image.
    Ok(unsafe { core::slice::from_raw_parts(value.ptr.cast(), value.length as usize) })
}
