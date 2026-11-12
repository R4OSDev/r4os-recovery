//! Font resources over the original decoder. A face borrows its decoder and
//! source bytes; the decoder borrows its context and stable allocator.
use crate::{Error, Heap, Result, raw as c, required, result, scalar, storage, view};
use alloc::boxed::Box;
use core::{marker::PhantomData, mem::MaybeUninit};
use r4os_sdk::App;

pub struct Fonts<'a> {
    native: MaybeUninit<c::R4FontHelpersContext>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Fonts<'a> {
    pub fn open(app: &'a App<'_>) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4FontHelpersContext_init(0, app.start_context(), native.as_mut_ptr())
        })?;
        Ok(Self {
            native,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn decoder<'f, 'h>(
        &'f self,
        heap: &'h Heap,
        allocation_limit: usize,
    ) -> Result<Decoder<'f, 'h>> {
        let allocator = heap.allocator()?;
        let mut native = storage();
        required(unsafe {
            c::R4FontHelpersContext_createDecoder(
                0,
                self.native.as_ptr(),
                allocator.as_ptr(),
                allocation_limit as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Decoder {
            native,
            _fonts: PhantomData,
            _heap: PhantomData,
        })
    }
}
pub struct Decoder<'f, 'h> {
    native: Box<MaybeUninit<c::R4FontHelpersDecoder>>,
    _fonts: PhantomData<&'f Fonts<'f>>,
    _heap: PhantomData<&'h Heap>,
}
impl Decoder<'_, '_> {
    pub fn open_face<'d, 'b>(
        &'d mut self,
        bytes: &'b [u8],
        face_index: u32,
    ) -> Result<Face<'d, 'b>> {
        let mut native = storage();
        required(unsafe {
            c::R4FontHelpersDecoder_openFace(
                0,
                self.native.as_mut_ptr(),
                bytes.as_ptr(),
                bytes.len() as u64,
                face_index,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Face {
            native,
            _decoder: PhantomData,
            _bytes: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn allocated_bytes(&self) -> Result<usize> {
        let mut out = MaybeUninit::uninit();
        required(unsafe {
            c::R4FontHelpersDecoder_diagnostics(0, self.native.as_ptr(), out.as_mut_ptr())
        })?;
        Ok(
            scalar(unsafe { c::R4FontHelpersDiagnostics_get_current_bytes(out.as_ptr()) })?
                as usize,
        )
    }
}
impl Drop for Decoder<'_, '_> {
    fn drop(&mut self) {
        assert!(
            result(unsafe { c::R4FontHelpersDecoder_deinit(0, self.native.as_mut_ptr()) }).is_ok(),
            "native decoder release failed"
        );
    }
}
pub struct Face<'d, 'b> {
    native: Box<MaybeUninit<c::R4FontHelpersFace>>,
    _decoder: PhantomData<&'d mut ()>,
    _bytes: PhantomData<&'b [u8]>,
    _local: PhantomData<*mut ()>,
}
pub struct FaceInfo<'f> {
    pub glyph_count: u32,
    pub units_per_em: u32,
    pub family: &'f [u8],
    pub style: &'f [u8],
}
pub struct Raster<'o> {
    pub width: u32,
    pub height: u32,
    pub left: i32,
    pub top: i32,
    pub advance_x_26_6: i32,
    pub alpha: &'o mut [u8],
}
impl Face<'_, '_> {
    pub fn info(&self) -> Result<FaceInfo<'_>> {
        let mut out = MaybeUninit::uninit();
        required(unsafe { c::R4FontHelpersFace_info(0, self.native.as_ptr(), out.as_mut_ptr()) })?;
        let family = required(unsafe { c::R4FontHelpersFaceInfo_get_family(out.as_ptr()) })?;
        let style = required(unsafe { c::R4FontHelpersFaceInfo_get_style(out.as_ptr()) })?;
        // Provider-owned name views remain borrowed from this exact face.
        fn name<'a>(value: c::R4LibrariesSlot, _: &'a Face<'_, '_>) -> Result<&'a [u8]> {
            let length = usize::try_from(value.length).map_err(|_| Error::InvalidProvider)?;
            if length == 0 {
                return Ok(&[]);
            }
            if value.ptr.is_null() || length > isize::MAX as usize {
                return Err(Error::InvalidProvider);
            }
            Ok(unsafe { core::slice::from_raw_parts(value.ptr.cast(), length) })
        }
        Ok(FaceInfo {
            glyph_count: scalar(unsafe { c::R4FontHelpersFaceInfo_get_glyph_count(out.as_ptr()) })?
                as u32,
            units_per_em: scalar(unsafe {
                c::R4FontHelpersFaceInfo_get_units_per_em(out.as_ptr())
            })? as u32,
            family: name(family, self)?,
            style: name(style, self)?,
        })
    }
    pub fn glyph_index(&self, scalar_value: char) -> Result<u32> {
        Ok(scalar(unsafe {
            c::R4FontHelpersFace_glyphIndex(0, self.native.as_ptr(), scalar_value as u32)
        })? as u32)
    }
    pub fn kerning(&self, left: u32, right: u32) -> Result<[i32; 2]> {
        let mut out = MaybeUninit::<[i32; 2]>::uninit();
        required(unsafe {
            c::R4FontHelpersFace_kerning(
                0,
                self.native.as_ptr(),
                left,
                right,
                out.as_mut_ptr().cast(),
            )
        })?;
        // The original return type is exactly [2]i32, with no padding.
        Ok(unsafe { out.assume_init() })
    }
    pub fn rasterize<'o>(
        &self,
        glyph_index: u32,
        pixel_height: u32,
        output: &'o mut [u8],
    ) -> Result<Raster<'o>> {
        let mut raster = MaybeUninit::uninit();
        required(unsafe {
            c::R4FontHelpersFace_rasterize(
                0,
                self.native.as_ptr(),
                glyph_index,
                pixel_height,
                output.as_mut_ptr(),
                output.len() as u64,
                raster.as_mut_ptr(),
            )
        })?;
        let length = view(
            unsafe { c::R4FontHelpersRaster_get_alpha(raster.as_ptr()) },
            output,
        )?
        .len();
        Ok(Raster {
            width: scalar(unsafe { c::R4FontHelpersRaster_get_width(raster.as_ptr()) })? as u32,
            height: scalar(unsafe { c::R4FontHelpersRaster_get_height(raster.as_ptr()) })? as u32,
            left: scalar(unsafe { c::R4FontHelpersRaster_get_left(raster.as_ptr()) })? as i32,
            top: scalar(unsafe { c::R4FontHelpersRaster_get_top(raster.as_ptr()) })? as i32,
            advance_x_26_6: scalar(unsafe {
                c::R4FontHelpersRaster_get_advance_x_26_6(raster.as_ptr())
            })? as i32,
            alpha: &mut output[..length],
        })
    }
}
impl Drop for Face<'_, '_> {
    fn drop(&mut self) {
        assert!(
            result(unsafe { c::R4FontHelpersFace_deinit(0, self.native.as_mut_ptr()) }).is_ok(),
            "native face release failed"
        );
    }
}

/// Owned output of the original FON/FNT converter. The allocator stays alive
/// until the original native free has run; input bytes need not be retained.
pub struct Imported<'h> {
    bytes: *mut u8,
    length: usize,
    heap: &'h Heap,
}
impl Imported<'_> {
    pub fn bytes(&self) -> &[u8] {
        unsafe { core::slice::from_raw_parts(self.bytes, self.length) }
    }
}
pub fn import<'h>(
    heap: &'h Heap,
    source: &[u8],
    source_name: &[u8],
    face_index: usize,
) -> Result<Imported<'h>> {
    let allocator = heap.allocator()?;
    let answer = required(unsafe {
        c::R4FontImport_convert(
            0,
            allocator.as_ptr(),
            source.as_ptr(),
            source.len() as u64,
            source_name.as_ptr(),
            source_name.len() as u64,
            face_index as u64,
        )
    })?;
    if answer.ptr.is_null() || answer.length > isize::MAX as u64 {
        return Err(Error::InvalidProvider);
    }
    Ok(Imported {
        bytes: answer.ptr.cast(),
        length: answer.length as usize,
        heap,
    })
}
impl Drop for Imported<'_> {
    fn drop(&mut self) {
        let allocator = self.heap.allocator().expect("live allocator descriptor");
        assert!(
            result(unsafe {
                c::R4Library_freeBytes(0, allocator.as_ptr(), self.bytes, self.length as u64)
            })
            .is_ok(),
            "native imported-font release failed"
        );
    }
}
