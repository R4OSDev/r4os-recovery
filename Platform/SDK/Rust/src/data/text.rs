use super::{Error, Result, object_view, optional_bytes, required, result, scalar, view};
use crate::c_facades as c;
use core::mem::MaybeUninit;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Encoding {
    Utf8,
    Windows1252,
}
impl Encoding {
    pub fn parse(label: &[u8]) -> Result<Self> {
        match u32::try_from(scalar(unsafe {
            c::R4SdkDataEncoding_parseLabel(0, label.as_ptr(), label.len() as u64)
        })?)
        .map_err(|_| Error::InvalidNative)?
        {
            c::R4SdkDataEncodingEncoding_utf8 => Ok(Self::Utf8),
            c::R4SdkDataEncodingEncoding_windows_1252 => Ok(Self::Windows1252),
            _ => Err(Error::InvalidNative),
        }
    }
}
pub struct Decoder {
    native: MaybeUninit<c::R4SdkDataEncodingDecoder>,
}
impl Decoder {
    pub fn new(encoding: Encoding, fatal: bool, ignore_bom: bool) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataEncodingDecoder_init(
                0,
                match encoding {
                    Encoding::Utf8 => c::R4SdkDataEncodingEncoding_utf8,
                    Encoding::Windows1252 => c::R4SdkDataEncodingEncoding_windows_1252,
                },
                fatal.into(),
                ignore_bom.into(),
                native.as_mut_ptr(),
            )
        })?;
        Ok(Self { native })
    }
    pub fn from_packed(state: u64) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataEncodingDecoder_fromPackedState(0, state, native.as_mut_ptr())
        })?;
        Ok(Self { native })
    }
    pub fn packed(&self) -> Result<u64> {
        scalar(unsafe { c::R4SdkDataEncodingDecoder_packState(0, self.native.as_ptr()) })
    }
    pub fn decode<'o>(&mut self, input: &[u8], out: &'o mut [u8], stream: bool) -> Result<&'o str> {
        let v = unsafe {
            c::R4SdkDataEncodingDecoder_decode(
                0,
                self.native.as_mut_ptr(),
                input.as_ptr(),
                input.len() as u64,
                out.as_mut_ptr(),
                out.len() as u64,
                stream.into(),
            )
        };
        core::str::from_utf8(view(v, out)?).map_err(|_| Error::InvalidNative)
    }
}
/// Returns the original UTF16 read-unit count and whole UTF8 bytes written.
pub fn encode_into(input: &str, out: &mut [u8]) -> Result<(usize, usize)> {
    let mut progress = MaybeUninit::uninit();
    required(unsafe {
        c::R4SdkDataEncoding_encodeInto(
            0,
            input.as_ptr(),
            input.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
            progress.as_mut_ptr(),
        )
    })?;
    Ok((
        scalar(unsafe { c::R4SdkDataEncodingEncodeIntoResult_get_read(progress.as_ptr()) })?
            as usize,
        scalar(unsafe { c::R4SdkDataEncodingEncodeIntoResult_get_written(progress.as_ptr()) })?
            as usize,
    ))
}
pub fn resolve_url<'o>(
    origin: &[u8],
    base_suffix: &[u8],
    reference: &[u8],
    out: &'o mut [u8],
) -> Result<&'o [u8]> {
    let v = unsafe {
        c::R4SdkDataUrl_resolveReference(
            0,
            origin.as_ptr(),
            origin.len() as u64,
            base_suffix.as_ptr(),
            base_suffix.len() as u64,
            reference.as_ptr(),
            reference.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
        )
    };
    view(v, out)
}
pub struct SearchParams {
    native: MaybeUninit<c::R4SdkDataUrlSearchParams>,
}
impl SearchParams {
    pub fn new(query: &[u8]) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkDataUrlSearchParams_init(
                0,
                query.as_ptr(),
                query.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Self { native })
    }
    pub fn count(&self) -> Result<usize> {
        Ok(
            scalar(unsafe { c::R4SdkDataUrlSearchParams_get_count(self.native.as_ptr()) })?
                as usize,
        )
    }
    pub fn pair(&self, index: usize) -> Result<(&[u8], &[u8])> {
        if index >= self.count()? {
            return Err(Error::Bounds);
        }
        Ok((
            object_view(
                unsafe { c::R4SdkDataUrlSearchParams_name(0, self.native.as_ptr(), index as u64) },
                &self.native,
            )?,
            object_view(
                unsafe { c::R4SdkDataUrlSearchParams_value(0, self.native.as_ptr(), index as u64) },
                &self.native,
            )?,
        ))
    }
    pub fn get(&self, name: &[u8]) -> Result<Option<&[u8]>> {
        let v = result(unsafe {
            c::R4SdkDataUrlSearchParams_get(
                0,
                self.native.as_ptr(),
                name.as_ptr(),
                name.len() as u64,
            )
        })?;
        if v.flags & 1 == 0 {
            Ok(None)
        } else {
            Ok(Some(object_view(v, &self.native)?))
        }
    }
    pub fn has(&self, name: &[u8], value: Option<&[u8]>) -> Result<bool> {
        Ok(scalar(unsafe {
            c::R4SdkDataUrlSearchParams_has(
                0,
                self.native.as_ptr(),
                name.as_ptr(),
                name.len() as u64,
                optional_bytes(value),
            )
        })? != 0)
    }
    pub fn append(&mut self, name: &[u8], value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkDataUrlSearchParams_append(
                0,
                self.native.as_mut_ptr(),
                name.as_ptr(),
                name.len() as u64,
                value.as_ptr(),
                value.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn set(&mut self, name: &[u8], value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkDataUrlSearchParams_set(
                0,
                self.native.as_mut_ptr(),
                name.as_ptr(),
                name.len() as u64,
                value.as_ptr(),
                value.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn delete(&mut self, name: &[u8], value: Option<&[u8]>) -> Result<()> {
        result(unsafe {
            c::R4SdkDataUrlSearchParams_delete(
                0,
                self.native.as_mut_ptr(),
                name.as_ptr(),
                name.len() as u64,
                optional_bytes(value),
            )
        })?;
        Ok(())
    }
    pub fn sort(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkDataUrlSearchParams_sort(0, self.native.as_mut_ptr()) })?;
        Ok(())
    }
    pub fn replace(&mut self, query: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkDataUrlSearchParams_replace(
                0,
                self.native.as_mut_ptr(),
                query.as_ptr(),
                query.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn serialize<'o>(&self, out: &'o mut [u8]) -> Result<&'o [u8]> {
        let v = unsafe {
            c::R4SdkDataUrlSearchParams_serialize(
                0,
                self.native.as_ptr(),
                out.as_mut_ptr(),
                out.len() as u64,
            )
        };
        view(v, out)
    }
}
