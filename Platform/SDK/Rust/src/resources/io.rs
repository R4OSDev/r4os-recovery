use super::*;
#[derive(Clone, Copy, Debug)]
pub enum WriteKind {
    Replace,
    Append,
    At(u64),
    Stream(u64),
}
pub enum IoOperation<'b> {
    Read {
        buffer: &'b mut [u8],
        offset: Option<u64>,
    },
    Write {
        buffer: &'b [u8],
        kind: WriteKind,
    },
    FileInfo,
    FileLock {
        offset: u64,
        length: u64,
    },
    StreamBegin,
    StreamFinish {
        expected: u64,
    },
    StreamAbort,
    Service {
        handle: u32,
        op: u16,
        request: &'b [u8],
        header: &'b mut abi::ServiceMessageHeader,
        response: &'b mut [u8],
        timeout_ticks: u64,
    },
}
#[derive(Clone, Copy, Debug)]
pub enum IoControl {
    FileInfo,
    FileLock { offset: u64, length: u64 },
    StreamBegin,
    StreamFinish { expected: u64 },
    StreamAbort,
}
#[must_use = "wait/cancellation do not release retained I/O buffers; close must acknowledge"]
pub struct IoRequest<'a, 'b> {
    raw: c::R4IoRequest,
    _owner: &'a Resources<'a>,
    _buffers: PhantomData<&'b mut [u8]>,
}
impl Resources<'_> {
    /// # Safety
    /// All buffers (including service request/header/response) stay resident
    /// and obey their read/write alias contract until the exact close ACK,
    /// even if this request is forgotten, dropped, timed out or cancelled.
    /// No mutable App/owner borrow may cross a foreign module callback.
    /// Native admission copies the path; it is not a retained buffer.
    pub unsafe fn io<'a, 'b>(
        &'a self,
        file: Option<&FilePath>,
        operation: IoOperation<'b>,
        flags: u32,
    ) -> Result<IoRequest<'a, 'b>> {
        let p = if let Some(file) = file {
            path(file)
        } else {
            c::R4PathZ {
                ptr: core::ptr::null(),
                length: 0,
            }
        };
        if p.ptr.is_null() && !matches!(operation, IoOperation::Service { .. }) {
            return Err(Error::Raw(abi::io_error_invalid));
        }
        let mut raw = unsafe { core::mem::zeroed() };
        let rc = unsafe {
            match operation {
                IoOperation::Read {
                    buffer,
                    offset: None,
                } => c::r4_resources_async_read(
                    &mut self.raw(),
                    p,
                    buffer.as_mut_ptr(),
                    buffer.len() as u64,
                    flags,
                    &mut raw,
                ),
                IoOperation::Read {
                    buffer,
                    offset: Some(offset),
                } => c::r4_resources_async_read_at(
                    &mut self.raw(),
                    p,
                    offset,
                    buffer.as_mut_ptr(),
                    buffer.len() as u64,
                    flags,
                    &mut raw,
                ),
                IoOperation::Write {
                    buffer,
                    kind: WriteKind::Replace,
                } => c::r4_resources_async_write(
                    &mut self.raw(),
                    p,
                    buffer.as_ptr(),
                    buffer.len() as u64,
                    flags,
                    &mut raw,
                ),
                IoOperation::Write {
                    buffer,
                    kind: WriteKind::Append,
                } => c::r4_resources_async_append(
                    &mut self.raw(),
                    p,
                    buffer.as_ptr(),
                    buffer.len() as u64,
                    flags,
                    &mut raw,
                ),
                IoOperation::Write {
                    buffer,
                    kind: WriteKind::At(offset),
                } => c::r4_resources_async_write_at(
                    &mut self.raw(),
                    p,
                    offset,
                    buffer.as_ptr(),
                    buffer.len() as u64,
                    flags,
                    &mut raw,
                ),
                IoOperation::Write {
                    buffer,
                    kind: WriteKind::Stream(offset),
                } => c::r4_resources_async_stream_write(
                    &mut self.raw(),
                    p,
                    offset,
                    buffer.as_ptr(),
                    buffer.len() as u64,
                    flags,
                    &mut raw,
                ),
                IoOperation::FileInfo => {
                    c::r4_resources_async_file_info(&mut self.raw(), p, flags, &mut raw)
                }
                IoOperation::FileLock { offset, length } => c::r4_resources_async_file_lock(
                    &mut self.raw(),
                    p,
                    offset,
                    length,
                    flags,
                    &mut raw,
                ),
                IoOperation::StreamBegin => {
                    c::r4_resources_async_stream_begin(&mut self.raw(), p, flags, &mut raw)
                }
                IoOperation::StreamFinish { expected } => c::r4_resources_async_stream_finish(
                    &mut self.raw(),
                    p,
                    expected,
                    flags,
                    &mut raw,
                ),
                IoOperation::StreamAbort => {
                    c::r4_resources_async_stream_abort(&mut self.raw(), p, &mut raw)
                }
                IoOperation::Service {
                    handle,
                    op,
                    request,
                    header,
                    response,
                    timeout_ticks,
                } => c::r4_resources_async_service_call(
                    &mut self.raw(),
                    handle,
                    op,
                    request.as_ptr(),
                    crate::storage::length(request.len())?,
                    header,
                    response.as_mut_ptr(),
                    crate::storage::length(response.len())?,
                    timeout_ticks,
                    flags,
                    &mut raw,
                ),
            }
        };
        exact(rc)?;
        if unsafe { c::r4_io_request_valid(&raw) } == 0 {
            return Err(Error::InvalidProvider);
        }
        Ok(IoRequest {
            raw,
            _owner: self,
            _buffers: PhantomData,
        })
    }
    /// Buffer-free admission. A completed file-lock operation owns a distinct
    /// native file lock; closing its I/O receipt does not unlock that range.
    pub fn io_control(
        &self,
        file: &FilePath,
        control: IoControl,
        flags: u32,
    ) -> Result<IoRequest<'_, 'static>> {
        let op = match control {
            IoControl::FileInfo => IoOperation::FileInfo,
            IoControl::FileLock { offset, length } => IoOperation::FileLock { offset, length },
            IoControl::StreamBegin => IoOperation::StreamBegin,
            IoControl::StreamFinish { expected } => IoOperation::StreamFinish { expected },
            IoControl::StreamAbort => IoOperation::StreamAbort,
        };
        unsafe { self.io(Some(file), op, flags) }
    }
}
impl IoRequest<'_, '_> {
    pub fn valid(&self) -> bool {
        unsafe { c::r4_io_request_valid(&self.raw) != 0 }
    }
    pub fn id(&self) -> u32 {
        self.raw.raw
    }
    pub fn buffers_held(&self) -> bool {
        unsafe { c::r4_io_request_buffers_held(&self.raw) != 0 }
    }
    pub fn status(&mut self) -> Result<abi::ProgramIoInfo> {
        let mut value = abi::ProgramIoInfo::default();
        exact(unsafe { c::r4_io_request_status(&mut self.raw, &mut value) })?;
        Ok(value)
    }
    /// Completion carries native operation status/result/partial progress.
    /// A completed failure is still a completed receipt, not an admission error.
    pub fn wait(&mut self, timeout: Timeout) -> Result<Wait<abi::ProgramIoInfo>> {
        match outcome(unsafe { c::r4_io_request_wait(&mut self.raw, timeout.raw()) })? {
            Wait::Completed(_) => Ok(Wait::Completed(self.raw.last_info)),
            Wait::WouldBlock => Ok(Wait::WouldBlock),
            Wait::TimedOut => Ok(Wait::TimedOut),
        }
    }
    pub fn close(&mut self) -> Result<()> {
        exact(unsafe { c::r4_io_request_close(&mut self.raw) })
    }
    pub fn release_buffers(&mut self) -> Result<()> {
        exact(unsafe { c::r4_io_request_release_buffers(&mut self.raw) })
    }
}

#[cfg(feature = "alloc")]
mod owned {
    extern crate alloc;
    use super::*;
    use alloc::boxed::Box;
    /// Every pending destination has a stable heap address, including a service
    /// response header. These buffers are inaccessible until native close ACK.
    pub enum IoBuffers {
        Bytes(Box<[u8]>),
        Service {
            request: Box<[u8]>,
            header: Box<abi::ServiceMessageHeader>,
            response: Box<[u8]>,
        },
    }
    pub struct IoOpenError {
        pub error: Error,
        pub buffers: IoBuffers,
    }
    // Consume Box ownership before lending native pointers. Moving a Box while
    // retaining references derived from its Unique pointer is not our pinning
    // contract. Raw ownership is reconstructed only after the exact ACK.
    enum RetainedBuffers {
        Bytes(*mut [u8]),
        Service {
            request: *mut [u8],
            header: *mut abi::ServiceMessageHeader,
            response: *mut [u8],
        },
    }
    impl RetainedBuffers {
        fn own(buffers: IoBuffers) -> Self {
            match buffers {
                IoBuffers::Bytes(bytes) => Self::Bytes(Box::into_raw(bytes)),
                IoBuffers::Service {
                    request,
                    header,
                    response,
                } => Self::Service {
                    request: Box::into_raw(request),
                    header: Box::into_raw(header),
                    response: Box::into_raw(response),
                },
            }
        }
        // No kernel access remains when ownership is reconstructed.
        unsafe fn recover(self) -> IoBuffers {
            unsafe {
                match self {
                    Self::Bytes(bytes) => IoBuffers::Bytes(Box::from_raw(bytes)),
                    Self::Service {
                        request,
                        header,
                        response,
                    } => IoBuffers::Service {
                        request: Box::from_raw(request),
                        header: Box::from_raw(header),
                        response: Box::from_raw(response),
                    },
                }
            }
        }
    }
    #[must_use = "close and retrieve the buffers after the native acknowledgement"]
    pub struct OwnedIo<'a> {
        request: IoRequest<'a, 'static>,
        buffers: Option<RetainedBuffers>,
    }
    impl Resources<'_> {
        pub fn io_read(
            &self,
            file: &FilePath,
            buffer: Box<[u8]>,
            offset: Option<u64>,
            flags: u32,
        ) -> core::result::Result<OwnedIo<'_>, IoOpenError> {
            let retained = RetainedBuffers::own(IoBuffers::Bytes(buffer));
            let RetainedBuffers::Bytes(pointer) = retained else {
                unreachable!()
            };
            match unsafe {
                self.io(
                    Some(file),
                    IoOperation::Read {
                        buffer: &mut *pointer,
                        offset,
                    },
                    flags,
                )
            } {
                Ok(request) => Ok(OwnedIo {
                    request,
                    buffers: Some(retained),
                }),
                Err(error) => Err(IoOpenError {
                    error,
                    buffers: unsafe { retained.recover() },
                }),
            }
        }
        pub fn io_write(
            &self,
            file: &FilePath,
            buffer: Box<[u8]>,
            kind: WriteKind,
            flags: u32,
        ) -> core::result::Result<OwnedIo<'_>, IoOpenError> {
            let retained = RetainedBuffers::own(IoBuffers::Bytes(buffer));
            let RetainedBuffers::Bytes(pointer) = retained else {
                unreachable!()
            };
            match unsafe {
                self.io(
                    Some(file),
                    IoOperation::Write {
                        buffer: &*pointer,
                        kind,
                    },
                    flags,
                )
            } {
                Ok(request) => Ok(OwnedIo {
                    request,
                    buffers: Some(retained),
                }),
                Err(error) => Err(IoOpenError {
                    error,
                    buffers: unsafe { retained.recover() },
                }),
            }
        }
        #[allow(clippy::too_many_arguments)]
        pub fn io_service(
            &self,
            handle: u32,
            op: u16,
            request: Box<[u8]>,
            header: Box<abi::ServiceMessageHeader>,
            response: Box<[u8]>,
            timeout_ticks: u64,
            flags: u32,
        ) -> core::result::Result<OwnedIo<'_>, IoOpenError> {
            let retained = RetainedBuffers::own(IoBuffers::Service {
                request,
                header,
                response,
            });
            let RetainedBuffers::Service {
                request,
                header,
                response,
            } = retained
            else {
                unreachable!()
            };
            match unsafe {
                self.io(
                    None,
                    IoOperation::Service {
                        handle,
                        op,
                        request: &*request,
                        header: &mut *header,
                        response: &mut *response,
                        timeout_ticks,
                    },
                    flags,
                )
            } {
                Ok(io) => Ok(OwnedIo {
                    request: io,
                    buffers: Some(retained),
                }),
                Err(error) => Err(IoOpenError {
                    error,
                    buffers: unsafe { retained.recover() },
                }),
            }
        }
    }
    impl OwnedIo<'_> {
        pub fn valid(&self) -> bool {
            self.request.valid()
        }
        pub fn id(&self) -> u32 {
            self.request.id()
        }
        pub fn status(&mut self) -> Result<abi::ProgramIoInfo> {
            self.request.status()
        }
        pub fn wait(&mut self, timeout: Timeout) -> Result<Wait<abi::ProgramIoInfo>> {
            self.request.wait(timeout)
        }
        pub fn close(&mut self) -> Result<()> {
            self.request.close()
        }
        pub fn take_buffers(&mut self) -> Result<IoBuffers> {
            if self.valid() {
                return Err(Error::Raw(abi::err_buffer_in_use));
            }
            let retained = self.buffers.take().ok_or(Error::Raw(abi::err_closed))?;
            Ok(unsafe { retained.recover() })
        }
    }
    impl Drop for OwnedIo<'_> {
        fn drop(&mut self) {
            if self.request.valid() {
                let _ = self.request.close();
                if self.request.valid() {
                    // Busy/cancel/error is not an ACK. Keep all addresses alive;
                    // instance retirement remains the final native owner.
                    // Raw ownership deliberately remains resident.
                    let _ = self.buffers.take();
                }
            }
            if let Some(retained) = self.buffers.take() {
                drop(unsafe { retained.recover() });
            }
        }
    }
}
#[cfg(feature = "alloc")]
pub use owned::{IoBuffers, IoOpenError, OwnedIo};
