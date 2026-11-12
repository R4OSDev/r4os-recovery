use super::{MaybeUninit, PhantomData, Result, c, required, result, view};
/// Source slices remain immutable until encoding has returned.
#[repr(transparent)]
pub struct LaunchOption<'a> {
    native: MaybeUninit<c::R4SdkSubsystemLaunchOption>,
    _source: PhantomData<&'a [u8]>,
}
impl<'a> LaunchOption<'a> {
    pub fn new(key: &'a [u8], value: &'a [u8]) -> Result<Self> {
        let mut out = Self {
            native: MaybeUninit::uninit(),
            _source: PhantomData,
        };
        result(unsafe {
            c::R4SdkSubsystemLaunchOption_create(
                out.native.as_mut_ptr(),
                key.as_ptr(),
                key.len() as u64,
                value.as_ptr(),
                value.len() as u64,
            )
        })?;
        Ok(out)
    }
}
pub fn encode_launch<'o>(
    guest: &[u8],
    options: &[LaunchOption<'_>],
    out: &'o mut [u8],
) -> Result<&'o [u8]> {
    let v = required(unsafe {
        c::R4SdkSubsystemLaunch_encode(
            0,
            guest.as_ptr(),
            guest.len() as u64,
            options.as_ptr().cast(),
            options.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
        )
    })?;
    view(v, out)
}
pub struct Launch<'a> {
    native: MaybeUninit<c::R4SdkSubsystemLaunchRequest>,
    source: &'a [u8],
}
impl<'a> Launch<'a> {
    pub fn parse(source: &'a [u8]) -> Result<Self> {
        let mut out = Self {
            native: MaybeUninit::uninit(),
            source,
        };
        required(unsafe {
            c::R4SdkSubsystemLaunch_parse(
                0,
                source.as_ptr(),
                source.len() as u64,
                out.native.as_mut_ptr(),
            )
        })?;
        Ok(out)
    }
    pub fn guest(&self) -> Result<&[u8]> {
        view(
            unsafe { c::R4SdkSubsystemLaunchRequest_get_guest_path(self.native.as_ptr()) },
            self.source,
        )
    }
    pub fn option_count(&self) -> Result<usize> {
        let value = required(unsafe {
            c::R4SdkSubsystemLaunchRequest_get_option_count(self.native.as_ptr())
        })?;
        value.bits.try_into().map_err(|_| super::Error::Bounds)
    }
    pub fn option(&self, key: &[u8]) -> Result<Option<&[u8]>> {
        let v = result(unsafe {
            c::R4SdkSubsystemLaunchRequest_option(
                0,
                self.native.as_ptr(),
                key.as_ptr(),
                key.len() as u64,
            )
        })?;
        if v.flags & 1 == 0 {
            Ok(None)
        } else {
            Ok(Some(view(v, self.source)?))
        }
    }
}
