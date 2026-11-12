//! Optional copied Start2 binding requests and borrowed child stdio refs.
//! Copies never Dup. No implicit Drop can hide failed backing release; close
//! explicitly or let the exact process's physical reaper close its references.
//! Default Console retains legacy byte/count/routing semantics, Poll only;
//! no EOF or atomic-write guarantee. Original console wait/events are separate.
use crate::{
    abi as a,
    byte_pipe::{self, Provider},
    platform2,
};
pub use byte_pipe::Error;
use core::{
    ffi::CStr,
    mem::{self, MaybeUninit},
    slice,
};
pub type Request = a::LaunchIo;
pub type Binding = a::LaunchIoBinding;
pub fn pipe_binding(end: a::BytePipeEnd) -> Binding {
    Binding {
        kind: a::launch_io_pipe,
        end,
        ..Binding::default()
    }
}
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
pub fn launch(
    context: &platform2::Context<'_>,
    path: &CStr,
    args: &CStr,
    request: &Request,
) -> Result<a::ProgramProcessHandle, Error> {
    let address = context
        .lookup(
            1,
            mem::offset_of!(a::generation2::R4XStartR4Sys2, program_launch_io) as u32,
        )
        .map_err(Error)?;
    let call: a::R4SysFns::program_launch_io = unsafe { mem::transmute(address) };
    let mut out = a::ProgramProcessHandle::default();
    exact(unsafe {
        call(
            path.as_ptr().cast(),
            args.as_ptr().cast(),
            request,
            &mut out,
        )
    })?;
    Ok(out)
}
fn console_poll(d: &byte_pipe::Deadline) -> Result<(), Error> {
    if d.version != 1 || d.size as usize != mem::size_of::<byte_pipe::Deadline>() || d.reserved0 != 0
    {
        return Err(Error(a::byte_pipe_error_invalid));
    }
    if d.kind != 0 {
        return Err(Error(a::byte_pipe_error_unsupported));
    }
    if d.absolute_ns != 0
        || d.last_ns != 0
        || d.clock_source != 0
        || d.clock_generation != 0
        || d.event_backend != 0
        || d.tick_hz != 0
    {
        return Err(Error(a::byte_pipe_error_invalid));
    }
    Ok(())
}
pub struct Stdio<'a, 'c> {
    context: &'a platform2::Context<'c>,
    snapshot: Request,
    pipes: Option<Provider>,
}
impl<'a, 'c> Stdio<'a, 'c> {
    pub fn open(context: &'a platform2::Context<'c>) -> Result<Self, Error> {
        let address = context
            .lookup(
                1,
                mem::offset_of!(a::generation2::R4XStartR4Sys2, program_stdio) as u32,
            )
            .map_err(Error)?;
        let call: a::R4SysFns::program_stdio = unsafe { mem::transmute(address) };
        let mut snapshot = Request::default();
        exact(unsafe { call(&mut snapshot) })?;
        if snapshot.version != 1 || snapshot.size as usize != mem::size_of::<Request>() {
            return Err(Error(a::launch_io_error_invalid));
        }
        let bindings = [
            snapshot.stdin_binding,
            snapshot.stdout_binding,
            snapshot.stderr_binding,
        ];
        if bindings
            .iter()
            .any(|b| b.reserved != 0 || b.kind > a::launch_io_pipe)
        {
            return Err(Error(a::launch_io_error_invalid));
        }
        let pipes = if bindings.iter().any(|b| b.kind == a::launch_io_pipe) {
            Some(Provider::from_context(context)?)
        } else {
            None
        };
        Ok(Self {
            context,
            snapshot,
            pipes,
        })
    }
    /// Borrowed identity only; a byte copy/query never retains another reference.
    pub fn binding(&self, stream: u32) -> Option<Binding> {
        match stream {
            0 => Some(self.snapshot.stdin_binding),
            1 => Some(self.snapshot.stdout_binding),
            2 => Some(self.snapshot.stderr_binding),
            _ => None,
        }
    }
    pub fn read(
        &self,
        storage: &mut [u8],
        limit: &byte_pipe::Deadline,
    ) -> Result<byte_pipe::Progress, Error> {
        if storage.is_empty() {
            return Err(Error(a::byte_pipe_error_invalid));
        }
        let b = self.snapshot.stdin_binding;
        if b.kind == a::launch_io_pipe {
            let p = self.pipes.ok_or(Error(a::byte_pipe_error_unsupported))?;
            let call: a::R4SysFns::byte_pipe_read = unsafe { mem::transmute(p.functions[2]) };
            let mut out = byte_pipe::Progress::default();
            exact(unsafe {
                call(
                    b.end,
                    storage.as_mut_ptr(),
                    storage.len() as u64,
                    limit,
                    &mut out,
                )
            })?;
            return Ok(out);
        }
        console_poll(limit)?;
        let address = self
            .context
            .lookup(
                2,
                mem::offset_of!(a::generation2::R4XStartR4Desk2, console_read) as u32,
            )
            .map_err(Error)?;
        let call: a::R4DeskFns::console_read = unsafe { mem::transmute(address) };
        let mut staged = MaybeUninit::<[u8; a::byte_pipe_max_step as usize]>::uninit();
        let count = storage.len().min(a::byte_pipe_max_step as usize);
        let rc = unsafe { call(staged.as_mut_ptr().cast(), count as u32) };
        if rc < 0 {
            return Err(Error(rc));
        }
        let n = rc as usize;
        if n > count {
            return Err(Error(a::byte_pipe_error_invalid));
        }
        storage[..n]
            .copy_from_slice(unsafe { slice::from_raw_parts(staged.as_ptr().cast::<u8>(), n) });
        Ok(byte_pipe::Progress {
            bytes: n as u64,
            state: if n != 0 {
                a::byte_pipe_ready
            } else {
                a::byte_pipe_would_block
            },
            ..Default::default()
        })
    }
    /// Default-console bytes mean the original call's consumed input, not pipe
    /// admission or physical delivery. Pipe bytes retain exact accepted-prefix rules.
    pub fn write(
        &self,
        stream: u32,
        bytes: &[u8],
        limit: &byte_pipe::Deadline,
    ) -> Result<byte_pipe::Progress, Error> {
        let b = self
            .binding(stream)
            .ok_or(Error(a::byte_pipe_error_invalid))?;
        if stream == 0 || bytes.is_empty() {
            return Err(Error(a::byte_pipe_error_invalid));
        }
        if b.kind == a::launch_io_pipe {
            let p = self.pipes.ok_or(Error(a::byte_pipe_error_unsupported))?;
            let call: a::R4SysFns::byte_pipe_write = unsafe { mem::transmute(p.functions[3]) };
            let mut out = byte_pipe::Progress::default();
            exact(unsafe { call(b.end, bytes.as_ptr(), bytes.len() as u64, limit, &mut out) })?;
            return Ok(out);
        }
        console_poll(limit)?;
        let address = self
            .context
            .lookup(
                2,
                mem::offset_of!(a::generation2::R4XStartR4Desk2, console_write) as u32,
            )
            .map_err(Error)?;
        let call: a::R4DeskFns::console_write = unsafe { mem::transmute(address) };
        let count = bytes.len().min(a::byte_pipe_max_step as usize);
        let rc = unsafe { call(stream, bytes.as_ptr(), count as u32) };
        if rc < 0 {
            return Err(Error(rc));
        }
        let n = rc as usize;
        if n > count {
            return Err(Error(a::byte_pipe_error_invalid));
        }
        Ok(byte_pipe::Progress {
            bytes: n as u64,
            state: if n != 0 {
                a::byte_pipe_ready
            } else {
                a::byte_pipe_would_block
            },
            ..Default::default()
        })
    }
    pub fn cancel(&self, stream: u32) -> Result<(), Error> {
        let b = self
            .binding(stream)
            .ok_or(Error(a::byte_pipe_error_invalid))?;
        if b.kind != a::launch_io_pipe {
            return Err(Error(a::byte_pipe_error_unsupported));
        }
        let p = self.pipes.ok_or(Error(a::byte_pipe_error_unsupported))?;
        let call: a::R4SysFns::byte_pipe_cancel = unsafe { mem::transmute(p.functions[4]) };
        exact(unsafe { call(b.end) })
    }
    pub fn close(&mut self, stream: u32) -> Result<(), Error> {
        let b = match stream {
            0 => &mut self.snapshot.stdin_binding,
            1 => &mut self.snapshot.stdout_binding,
            2 => &mut self.snapshot.stderr_binding,
            _ => return Err(Error(a::byte_pipe_error_invalid)),
        };
        if b.kind != a::launch_io_pipe {
            return Err(Error(a::byte_pipe_error_unsupported));
        }
        if b.end.handle == 0 {
            return Ok(());
        }
        let p = self.pipes.ok_or(Error(a::byte_pipe_error_unsupported))?;
        let call: a::R4SysFns::byte_pipe_close = unsafe { mem::transmute(p.functions[5]) };
        exact(unsafe { call(b.end) })?;
        b.end = a::BytePipeEnd::default();
        Ok(())
    }
}
