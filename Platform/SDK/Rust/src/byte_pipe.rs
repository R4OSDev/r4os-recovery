//! Owned Query2 byte-pipe references. No implicit Dup, Drop, launch binding or
//! WaitSource. Explicit Close preserves its retry identity on release failure.
use crate::{abi, platform2};
use core::mem;
pub type Deadline = abi::WaitSetDeadline;
pub type Progress = abi::BytePipeProgress;
pub type Info = abi::BytePipeInfo;
pub use crate::wait_set::deadline;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
#[derive(Clone, Copy)]
pub(crate) struct Provider {
    pub(crate) functions: [u64; 7],
}
impl Provider {
    pub(crate) fn from_context(context: &platform2::Context<'_>) -> Result<Self, Error> {
        let offsets = [
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_create),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_dup),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_read),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_write),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_cancel),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_close),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, byte_pipe_info),
        ];
        let mut functions = [0; 7];
        for (out, offset) in functions.iter_mut().zip(offsets) {
            *out = context.lookup(1, offset as u32).map_err(Error)?;
        }
        Ok(Self { functions })
    }
}
pub struct Endpoint<'a, 'c> {
    _context: &'a platform2::Context<'c>,
    provider: Provider,
    value: abi::BytePipeEnd,
}
impl<'a, 'c> Endpoint<'a, 'c> {
    /// Borrowed raw identity; byte copies grant no additional reference.
    pub fn identity(&self) -> abi::BytePipeEnd {
        self.value
    }
    pub fn duplicate(&self) -> Result<Self, Error> {
        let call: abi::R4SysFns::byte_pipe_dup =
            unsafe { mem::transmute(self.provider.functions[1]) };
        let mut value = abi::BytePipeEnd::default();
        exact(unsafe { call(self.value, &mut value) })?;
        Ok(Self {
            _context: self._context,
            provider: self.provider,
            value,
        })
    }
    pub fn read(&self, storage: &mut [u8], limit: &Deadline) -> Result<Progress, Error> {
        let call: abi::R4SysFns::byte_pipe_read =
            unsafe { mem::transmute(self.provider.functions[2]) };
        let mut result = Progress::default();
        exact(unsafe {
            call(
                self.value,
                storage.as_mut_ptr(),
                storage.len() as u64,
                limit,
                &mut result,
            )
        })?;
        Ok(result)
    }
    pub fn write(&self, bytes: &[u8], limit: &Deadline) -> Result<Progress, Error> {
        let call: abi::R4SysFns::byte_pipe_write =
            unsafe { mem::transmute(self.provider.functions[3]) };
        let mut result = Progress::default();
        exact(unsafe {
            call(
                self.value,
                bytes.as_ptr(),
                bytes.len() as u64,
                limit,
                &mut result,
            )
        })?;
        Ok(result)
    }
    pub fn cancel(&self) -> Result<(), Error> {
        let call: abi::R4SysFns::byte_pipe_cancel =
            unsafe { mem::transmute(self.provider.functions[4]) };
        exact(unsafe { call(self.value) })
    }
    pub fn close(&mut self) -> Result<(), Error> {
        if self.value.handle == 0 {
            return Ok(());
        }
        let call: abi::R4SysFns::byte_pipe_close =
            unsafe { mem::transmute(self.provider.functions[5]) };
        exact(unsafe { call(self.value) })?;
        self.value = abi::BytePipeEnd::default();
        Ok(())
    }
    pub fn info(&self) -> Result<Info, Error> {
        let call: abi::R4SysFns::byte_pipe_info =
            unsafe { mem::transmute(self.provider.functions[6]) };
        let mut result = Info::default();
        exact(unsafe { call(self.value, &mut result) })?;
        Ok(result)
    }
}
pub struct Pair<'a, 'c> {
    pub reader: Endpoint<'a, 'c>,
    pub writer: Endpoint<'a, 'c>,
}
pub fn create<'a, 'c>(
    context: &'a platform2::Context<'c>,
    capacity: u64,
) -> Result<Pair<'a, 'c>, Error> {
    let provider = Provider::from_context(context)?;
    let call: abi::R4SysFns::byte_pipe_create = unsafe { mem::transmute(provider.functions[0]) };
    let mut pair = abi::BytePipePair::default();
    exact(unsafe { call(capacity, &mut pair) })?;
    Ok(Pair {
        reader: Endpoint {
            _context: context,
            provider,
            value: pair.reader,
        },
        writer: Endpoint {
            _context: context,
            provider,
            value: pair.writer,
        },
    })
}
