//! Typed byte paths using the existing SDK C facade's normalization core.
use crate::abi;
use crate::c_facades::{R4SdkFilePath, R4SdkRegistryPath};
use core::ffi::CStr;
pub const FILE_PATH_MAX: usize = abi::file_path_max_bytes as usize;
pub const REGISTRY_PATH_MAX: usize = abi::registry_path_max_bytes as usize;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Empty,
    TooLong,
    ComponentTooLong,
    EmbeddedNul,
    InvalidCharacter,
    WrongKind,
    RootTraversal,
    Runtime(i32),
}
fn status(raw: i32) -> Result<(), Error> {
    match raw {
        0 => Ok(()),
        -1 => Err(Error::Empty),
        -2 => Err(Error::TooLong),
        -3 => Err(Error::ComponentTooLong),
        -4 => Err(Error::EmbeddedNul),
        -5 => Err(Error::InvalidCharacter),
        -6 => Err(Error::WrongKind),
        -7 => Err(Error::RootTraversal),
        other => Err(Error::Runtime(other)),
    }
}
#[derive(Clone, Debug)]
#[repr(C)]
pub struct FilePath {
    bytes: [u8; FILE_PATH_MAX + 1],
    length: u16,
    absolute: u8,
    reserved: u8,
}
impl FilePath {
    pub fn parse(input: &[u8]) -> Result<Self, Error> {
        Self::with_kind(input, -1)
    }
    fn with_kind(input: &[u8], kind: i32) -> Result<Self, Error> {
        let mut out = Self {
            bytes: [0; FILE_PATH_MAX + 1],
            length: 0,
            absolute: 0,
            reserved: 0,
        };
        status(unsafe {
            R4SdkFilePath(
                input.as_ptr(),
                input.len() as u64,
                kind,
                out.bytes.as_mut_ptr(),
                out.bytes.len() as u64,
                &mut out.length,
                &mut out.absolute,
            )
        })?;
        Ok(out)
    }
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes[..self.length as usize]
    }
    pub fn as_c_str(&self) -> &CStr {
        // Only successful owner normalization constructs this private storage.
        unsafe { CStr::from_bytes_with_nul_unchecked(&self.bytes[..=self.length as usize]) }
    }
    pub fn is_absolute(&self) -> bool {
        self.absolute != 0
    }
    pub(crate) fn as_raw(&self) -> &crate::c_facades::R4FilePath {
        unsafe { &*(self as *const Self).cast() }
    }
}
#[derive(Clone, Debug)]
pub struct AbsoluteFilePath(FilePath);
impl AbsoluteFilePath {
    pub fn parse(input: &[u8]) -> Result<Self, Error> {
        FilePath::with_kind(input, 1).map(Self)
    }
    pub fn as_path(&self) -> &FilePath {
        &self.0
    }
}
#[derive(Clone, Debug)]
pub struct RelativeFilePath(FilePath);
impl RelativeFilePath {
    pub fn parse(input: &[u8]) -> Result<Self, Error> {
        FilePath::with_kind(input, 0).map(Self)
    }
    pub fn as_path(&self) -> &FilePath {
        &self.0
    }
}
#[derive(Clone, Debug)]
#[repr(C)]
pub struct RegistryPath {
    bytes: [u8; REGISTRY_PATH_MAX + 1],
    length: u16,
}
impl RegistryPath {
    pub fn parse(input: &[u8]) -> Result<Self, Error> {
        let mut out = Self {
            bytes: [0; REGISTRY_PATH_MAX + 1],
            length: 0,
        };
        status(unsafe {
            R4SdkRegistryPath(
                input.as_ptr(),
                input.len() as u64,
                out.bytes.as_mut_ptr(),
                out.bytes.len() as u64,
                &mut out.length,
            )
        })?;
        Ok(out)
    }
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes[..self.length as usize]
    }
    pub fn as_c_str(&self) -> &CStr {
        unsafe { CStr::from_bytes_with_nul_unchecked(&self.bytes[..=self.length as usize]) }
    }
    pub(crate) fn as_raw(&self) -> &crate::c_facades::R4RegistryPath {
        unsafe { &*(self as *const Self).cast() }
    }
}
const _: () = {
    use crate::c_facades::{R4FilePath, R4RegistryPath};
    assert!(core::mem::size_of::<FilePath>() == core::mem::size_of::<R4FilePath>());
    assert!(core::mem::align_of::<FilePath>() == core::mem::align_of::<R4FilePath>());
    assert!(core::mem::offset_of!(FilePath, length) == core::mem::offset_of!(R4FilePath, length));
    assert!(
        core::mem::offset_of!(FilePath, absolute) == core::mem::offset_of!(R4FilePath, absolute)
    );
    assert!(
        core::mem::offset_of!(FilePath, reserved) == core::mem::offset_of!(R4FilePath, reserved)
    );
    assert!(core::mem::size_of::<RegistryPath>() == core::mem::size_of::<R4RegistryPath>());
    assert!(core::mem::align_of::<RegistryPath>() == core::mem::align_of::<R4RegistryPath>());
    assert!(
        core::mem::offset_of!(RegistryPath, length)
            == core::mem::offset_of!(R4RegistryPath, length)
    );
};
pub fn equals_ignore_case(left: &[u8], right: &[u8]) -> bool {
    left.eq_ignore_ascii_case(right)
}
