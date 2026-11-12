//! Exact Query2 metadata and borrowed bounded directory pages.
use crate::{abi, platform2::Context};
use core::{ffi::CStr, mem::MaybeUninit};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);

pub fn query(context: &Context<'_>, path: &CStr) -> Result<Option<abi::FileMetadata2>, Error> {
    let address = context
        .lookup(
            1,
            core::mem::offset_of!(abi::generation2::R4XStartR4Sys2, file_metadata2) as u32,
        )
        .map_err(Error)?;
    let call: abi::R4SysFns::file_metadata2 = unsafe { core::mem::transmute(address) };
    let mut output = MaybeUninit::uninit();
    match unsafe { call(path.as_ptr().cast(), output.as_mut_ptr()) } {
        1 => Ok(Some(unsafe { output.assume_init() })),
        0 => Ok(None),
        code => Err(Error(code)),
    }
}

pub fn identity(value: &abi::FileMetadata2) -> Option<&abi::FileIdentity2> {
    (value.flags & abi::file_metadata2_flag_identity_valid != 0).then_some(&value.identity)
}
pub fn file_size(value: &abi::FileMetadata2) -> Option<u64> {
    (value.flags & abi::file_metadata2_flag_byte_size_valid != 0).then_some(value.byte_size)
}

pub enum Page<'a> {
    Rows(&'a [abi::DirectoryMetadataEntry2]),
    Progress,
    End,
    Restart,
}

/// Context/code, path and whole storage remain borrowed. Returned rows borrow
/// this directory; further calls/reset/storage mutation require their real end.
/// A complete traversal must be assembled privately and discarded on Restart.
pub struct Directory<'a> {
    context: &'a Context<'a>,
    path: &'a CStr,
    storage: &'a mut [MaybeUninit<abi::DirectoryMetadataEntry2>],
    cursor: abi::DirectoryMetadataCursor2,
}
impl<'a> Directory<'a> {
    pub fn new(
        context: &'a Context<'a>,
        path: &'a CStr,
        storage: &'a mut [MaybeUninit<abi::DirectoryMetadataEntry2>],
    ) -> Result<Self, Error> {
        if storage.is_empty() || storage.len() > abi::directory_batch_max_entries as usize {
            return Err(Error(abi::file_metadata2_error_invalid));
        }
        Ok(Self {
            context,
            path,
            storage,
            cursor: Default::default(),
        })
    }
    fn call(&mut self, validate: bool) -> Result<i32, Error> {
        let address = self
            .context
            .lookup(
                1,
                core::mem::offset_of!(abi::generation2::R4XStartR4Sys2, directory_metadata_batch2)
                    as u32,
            )
            .map_err(Error)?;
        let call: abi::R4SysFns::directory_metadata_batch2 =
            unsafe { core::mem::transmute(address) };
        Ok(unsafe {
            call(
                if validate {
                    core::ptr::null()
                } else {
                    self.path.as_ptr().cast()
                },
                &mut self.cursor,
                if validate {
                    core::ptr::null_mut()
                } else {
                    self.storage.as_mut_ptr().cast()
                },
                if validate {
                    0
                } else {
                    self.storage.len() as u32
                },
            )
        })
    }
    pub fn next_page(&mut self) -> Result<Page<'_>, Error> {
        let count = self.call(false)?;
        match count {
            0 => Ok(Page::Progress),
            -5 => Ok(Page::End),
            -10 => Ok(Page::Restart),
            n if n > 0 && n as usize <= self.storage.len() => Ok(Page::Rows(unsafe {
                core::slice::from_raw_parts(self.storage.as_ptr().cast(), n as usize)
            })),
            code => Err(Error(code)),
        }
    }
    pub fn validate(&mut self) -> Result<(), Error> {
        match self.call(true)? {
            0 => Ok(()),
            code => Err(Error(code)),
        }
    }
    pub fn reset(&mut self) {
        self.cursor = Default::default();
    }
}
