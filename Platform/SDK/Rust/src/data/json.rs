use super::{Data, Error, Result, result, scalar, view};
use crate::c_facades as c;
use core::{marker::PhantomData, mem::MaybeUninit};
/// Borrows its exact protocol context, document bytes and private depth stack.
/// No parser or persistent protocol job is embedded in this value.
pub struct Json<'c, 'b> {
    native: MaybeUninit<c::R4SdkDataJsonDocument>,
    bytes: &'b [u8],
    _depth: PhantomData<&'b mut [u8]>,
    _context: PhantomData<&'c ()>,
    _local: PhantomData<*mut ()>,
}
impl<'c, 'b> Json<'c, 'b> {
    pub(super) fn open(
        context: &'c Data<'_, '_>,
        bytes: &'b [u8],
        depth: &'b mut [u8],
    ) -> Result<Self> {
        if bytes.len() > u32::MAX as usize || depth.len() > u32::MAX as usize {
            return Err(Error::Bounds);
        }
        let mut native = MaybeUninit::uninit();
        result(unsafe {
            c::R4SdkData_json(
                0,
                native.as_mut_ptr(),
                context.native,
                bytes.as_ptr(),
                bytes.len() as u64,
                depth.as_mut_ptr(),
                depth.len() as u64,
            )
        })?;
        Ok(Self {
            native,
            bytes,
            _depth: PhantomData,
            _context: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn token(&self) -> Result<u32> {
        u32::try_from(scalar(unsafe {
            c::R4SdkDataJsonDocument_token(0, self.native.as_ptr())
        })?)
        .map_err(|_| Error::InvalidNative)
    }
    pub fn token_bytes(&self) -> Result<Option<&[u8]>> {
        let v = result(unsafe { c::R4SdkDataJsonDocument_tokenBytes(0, self.native.as_ptr()) })?;
        if v.flags & 1 == 0 {
            Ok(None)
        } else {
            Ok(Some(view(v, self.bytes)?))
        }
    }
    pub fn next_token(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkDataJsonDocument_next(0, self.native.as_mut_ptr()) })?;
        Ok(())
    }
    pub fn select(&mut self, path: &[u8]) -> Result<()> {
        if path.len() > u32::MAX as usize {
            return Err(Error::Bounds);
        }
        result(unsafe {
            c::R4SdkDataJsonDocument_select(
                0,
                self.native.as_mut_ptr(),
                path.as_ptr(),
                path.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn value<'o>(&mut self, out: &'o mut [u8]) -> Result<&'o [u8]> {
        if out.len() > u32::MAX as usize {
            return Err(Error::Bounds);
        }
        let v = unsafe {
            c::R4SdkDataJsonDocument_value(
                0,
                self.native.as_mut_ptr(),
                out.as_mut_ptr(),
                out.len() as u64,
            )
        };
        view(v, out)
    }
    pub fn read<'o>(&mut self, path: &[u8], out: &'o mut [u8]) -> Result<&'o [u8]> {
        self.select(path)?;
        self.value(out)
    }
    pub fn read_u64(&mut self, path: &[u8]) -> Result<u64> {
        if path.len() > u32::MAX as usize {
            return Err(Error::Bounds);
        }
        scalar(unsafe {
            c::R4SdkDataJsonDocument_readU64(
                0,
                self.native.as_mut_ptr(),
                path.as_ptr(),
                path.len() as u64,
            )
        })
    }
    pub fn enter(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkDataJsonDocument_enter(0, self.native.as_mut_ptr()) })?;
        Ok(())
    }
    pub fn next_element(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkDataJsonDocument_nextElement(0, self.native.as_mut_ptr()) })?;
        Ok(())
    }
    fn edit<'o>(
        &mut self,
        op: u8,
        path: &[u8],
        value: &[u8],
        out: &'o mut [u8],
    ) -> Result<&'o [u8]> {
        if path.len() > u32::MAX as usize
            || value.len() > u32::MAX as usize
            || out.len() > u32::MAX as usize
        {
            return Err(Error::Bounds);
        }
        let v = unsafe {
            match op {
                0 => c::R4SdkDataJsonDocument_set(
                    0,
                    self.native.as_mut_ptr(),
                    path.as_ptr(),
                    path.len() as u64,
                    value.as_ptr(),
                    value.len() as u64,
                    out.as_mut_ptr(),
                    out.len() as u64,
                ),
                1 => c::R4SdkDataJsonDocument_remove(
                    0,
                    self.native.as_mut_ptr(),
                    path.as_ptr(),
                    path.len() as u64,
                    out.as_mut_ptr(),
                    out.len() as u64,
                ),
                2 => c::R4SdkDataJsonDocument_insert(
                    0,
                    self.native.as_mut_ptr(),
                    path.as_ptr(),
                    path.len() as u64,
                    value.as_ptr(),
                    value.len() as u64,
                    out.as_mut_ptr(),
                    out.len() as u64,
                ),
                _ => return Err(Error::Bounds),
            }
        };
        view(v, out)
    }
    pub fn set<'o>(&mut self, path: &[u8], value: &[u8], out: &'o mut [u8]) -> Result<&'o [u8]> {
        self.edit(0, path, value, out)
    }
    pub fn remove<'o>(&mut self, path: &[u8], out: &'o mut [u8]) -> Result<&'o [u8]> {
        self.edit(1, path, &[], out)
    }
    pub fn insert<'o>(&mut self, path: &[u8], value: &[u8], out: &'o mut [u8]) -> Result<&'o [u8]> {
        self.edit(2, path, value, out)
    }
}
