//! Shared static SDK ReadExact/WriteAll steps. A callback really returns
//! before its buffer loan ends. No hidden async admission, wait, retry or ACK.
use crate::{
    abi, c_facades as c, platform2,
    resources::Timeout,
    time::checked::{BudgetValue, ClockSample, DeadlineBudget},
};
use core::{
    ffi::CStr,
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IoKind {
    Progress = 0,
    Eof = 1,
    WouldBlock = 2,
    TimedOut = 3,
    Closed = 4,
    Failed = 5,
    Uncertain = 6,
}
#[derive(Debug, Clone, Copy)]
pub struct Ack {
    pub bytes: u32,
    pub kind: IoKind,
    pub error_code: i32,
}
impl Ack {
    pub fn bytes(n: u32) -> Self {
        Self {
            bytes: n,
            kind: IoKind::Progress,
            error_code: 0,
        }
    }
    fn raw(self) -> c::R4SdkTransferAck {
        c::R4SdkTransferAck {
            bytes: self.bytes,
            kind: self.kind as u32,
            error_code: self.error_code,
            reserved: 0,
        }
    }
    fn from_raw(r: c::R4SdkTransferAck) -> Self {
        Self {
            bytes: r.bytes,
            kind: match r.kind {
                0 => IoKind::Progress,
                1 => IoKind::Eof,
                2 => IoKind::WouldBlock,
                3 => IoKind::TimedOut,
                4 => IoKind::Closed,
                5 => IoKind::Failed,
                _ => IoKind::Uncertain,
            },
            error_code: r.error_code,
        }
    }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Outcome {
    Pending = 0,
    Complete = 1,
    WouldBlock = 2,
    Eof = 3,
    TimedOut = 4,
    Cancelled = 5,
    Failed = 6,
    Uncertain = 7,
    ClockFailed = 8,
    InvalidProgress = 9,
    Closed = 10,
}
#[derive(Debug, Clone, Copy)]
pub struct Progress {
    pub bytes: u64,
    pub total: u64,
    pub last_bytes: u32,
    pub outcome: Outcome,
    pub error_code: i32,
    pub goal_met: bool,
    pub terminal: bool,
    pub in_call: bool,
    pub effect_uncertain: bool,
}
fn progress(r: c::R4SdkTransferProgress) -> Result<Progress, Error> {
    let outcome = match r.outcome {
        0 => Outcome::Pending,
        1 => Outcome::Complete,
        2 => Outcome::WouldBlock,
        3 => Outcome::Eof,
        4 => Outcome::TimedOut,
        5 => Outcome::Cancelled,
        6 => Outcome::Failed,
        7 => Outcome::Uncertain,
        8 => Outcome::ClockFailed,
        9 => Outcome::InvalidProgress,
        10 => Outcome::Closed,
        _ => return Err(Error(-1)),
    };
    Ok(Progress {
        bytes: r.bytes,
        total: r.total,
        last_bytes: r.last_bytes,
        outcome,
        error_code: r.error_code,
        goal_met: r.flags & 1 != 0,
        terminal: r.flags & 2 != 0,
        in_call: r.flags & 4 != 0,
        effect_uncertain: r.flags & 8 != 0,
    })
}
#[derive(Clone, Copy)]
pub struct Budget<'a> {
    raw: &'a c::R4SdkDeadlineBudget,
}
impl Budget<'_> {
    /// Remaining nanoseconds in the same epoch; never resets the outer end.
    pub fn remaining(self, sample: ClockSample) -> Result<BudgetValue, Error> {
        let mut copy = *self.raw;
        let mut value = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDeadlineBudgetRemaining(&mut copy, sample.raw(), value.as_mut_ptr())
        })?;
        let value = unsafe { value.assume_init() };
        match (value.kind, value.value) {
            (0, 0) => Ok(BudgetValue::Poll),
            (1, n) if n > 0 => Ok(BudgetValue::Finite(n)),
            (2, 0) => Ok(BudgetValue::Forever),
            _ => Err(Error(-104)),
        }
    }
}
pub struct ReadChunk<'a> {
    pub offset: u64,
    pub bytes: &'a mut [u8],
    pub budget: Budget<'a>,
}
pub struct WriteChunk<'a> {
    pub offset: u64,
    pub bytes: &'a [u8],
    pub budget: Budget<'a>,
}
struct State {
    raw: c::R4SdkTransfer,
    _local: PhantomData<*mut ()>,
}
impl State {
    fn new(mode: u32, total: usize, initial: ClockSample, timeout: Timeout) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkTransferInit(
                mode,
                total as u64,
                initial.raw(),
                timeout.raw(),
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _local: PhantomData,
        })
    }
    fn absolute(mode: u32, total: usize, deadline: &DeadlineBudget) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkTransferInitAbsolute(mode, total as u64, deadline.raw(), raw.as_mut_ptr())
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _local: PhantomData,
        })
    }
    fn progress(&self) -> Result<Progress, Error> {
        let mut r = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkTransferGetProgress(&self.raw, r.as_mut_ptr()) })?;
        progress(unsafe { r.assume_init() })
    }
    fn cancel(&mut self) -> Result<Progress, Error> {
        let mut r = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkTransferCancel(&mut self.raw, r.as_mut_ptr()) })?;
        progress(unsafe { r.assume_init() })
    }
}
unsafe extern "C" fn clock<C: FnMut() -> Result<ClockSample, Error>>(
    raw: *mut core::ffi::c_void,
    out: *mut c::R4SdkClockSample,
) -> i32 {
    let callback = unsafe { &mut *raw.cast::<C>() };
    match callback() {
        Ok(sample) => {
            unsafe { out.write(sample.raw()) };
            0
        }
        Err(e) => e.0,
    }
}
pub struct ReadExact<'a> {
    state: State,
    bytes: &'a mut [u8],
}
impl<'a> ReadExact<'a> {
    pub fn new(bytes: &'a mut [u8], initial: ClockSample, timeout: Timeout) -> Result<Self, Error> {
        Ok(Self {
            state: State::new(0, bytes.len(), initial, timeout)?,
            bytes,
        })
    }
    pub fn with_deadline(bytes: &'a mut [u8], deadline: &DeadlineBudget) -> Result<Self, Error> {
        Ok(Self {
            state: State::absolute(0, bytes.len(), deadline)?,
            bytes,
        })
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        self.state.progress()
    }
    pub fn cancel(&mut self) -> Result<Progress, Error> {
        self.state.cancel()
    }
    pub fn confirmed(&self) -> &[u8] {
        &self.bytes[..self.state.raw.bytes as usize]
    }
    pub fn step<C, F>(
        &mut self,
        limit: u32,
        stop: bool,
        clock_source: &mut C,
        mut reader: F,
    ) -> Result<Progress, Error>
    where
        C: FnMut() -> Result<ClockSample, Error>,
        F: for<'b> FnMut(ReadChunk<'b>) -> Ack,
    {
        unsafe extern "C" fn invoke<F: for<'b> FnMut(ReadChunk<'b>) -> Ack>(
            raw: *mut core::ffi::c_void,
            offset: u64,
            data: *mut u8,
            length: u32,
            deadline: *const c::R4SdkDeadlineBudget,
        ) -> c::R4SdkTransferAck {
            let f = unsafe { &mut *raw.cast::<F>() };
            f(ReadChunk {
                offset,
                bytes: unsafe { core::slice::from_raw_parts_mut(data, length as usize) },
                budget: Budget {
                    raw: unsafe { &*deadline },
                },
            })
            .raw()
        }
        let offset = usize::try_from(self.state.raw.bytes).map_err(|_| Error(-1))?;
        let target = self.bytes.get_mut(offset..).ok_or(Error(-1))?;
        let mut result = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkTransferReadStep(
                &mut self.state.raw,
                target.as_mut_ptr(),
                target.len() as u64,
                limit,
                u32::from(stop),
                Some(clock::<C>),
                (clock_source as *mut C).cast(),
                Some(invoke::<F>),
                (&mut reader as *mut F).cast(),
                result.as_mut_ptr(),
            )
        })?;
        progress(unsafe { result.assume_init() })
    }
}
pub struct WriteAll<'a> {
    state: State,
    bytes: &'a [u8],
}
impl<'a> WriteAll<'a> {
    pub fn new(bytes: &'a [u8], initial: ClockSample, timeout: Timeout) -> Result<Self, Error> {
        Ok(Self {
            state: State::new(1, bytes.len(), initial, timeout)?,
            bytes,
        })
    }
    pub fn with_deadline(bytes: &'a [u8], deadline: &DeadlineBudget) -> Result<Self, Error> {
        Ok(Self {
            state: State::absolute(1, bytes.len(), deadline)?,
            bytes,
        })
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        self.state.progress()
    }
    pub fn cancel(&mut self) -> Result<Progress, Error> {
        self.state.cancel()
    }
    pub fn step<C, F>(
        &mut self,
        limit: u32,
        stop: bool,
        clock_source: &mut C,
        mut writer: F,
    ) -> Result<Progress, Error>
    where
        C: FnMut() -> Result<ClockSample, Error>,
        F: for<'b> FnMut(WriteChunk<'b>) -> Ack,
    {
        unsafe extern "C" fn invoke<F: for<'b> FnMut(WriteChunk<'b>) -> Ack>(
            raw: *mut core::ffi::c_void,
            offset: u64,
            data: *const u8,
            length: u32,
            deadline: *const c::R4SdkDeadlineBudget,
        ) -> c::R4SdkTransferAck {
            let f = unsafe { &mut *raw.cast::<F>() };
            f(WriteChunk {
                offset,
                bytes: unsafe { core::slice::from_raw_parts(data, length as usize) },
                budget: Budget {
                    raw: unsafe { &*deadline },
                },
            })
            .raw()
        }
        let offset = usize::try_from(self.state.raw.bytes).map_err(|_| Error(-1))?;
        let source = self.bytes.get(offset..).ok_or(Error(-1))?;
        let mut result = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkTransferWriteStep(
                &mut self.state.raw,
                source.as_ptr(),
                source.len() as u64,
                limit,
                u32::from(stop),
                Some(clock::<C>),
                (clock_source as *mut C).cast(),
                Some(invoke::<F>),
                (&mut writer as *mut F).cast(),
                result.as_mut_ptr(),
            )
        })?;
        progress(unsafe { result.assume_init() })
    }
}
type Provider<'a> = PhantomData<&'a platform2::Context<'a>>;
fn lookup(ctx: &platform2::Context<'_>, offset: usize) -> Result<u64, Error> {
    ctx.lookup(1, offset as u32).map_err(Error)
}
fn count(n: usize) -> Option<u32> {
    u32::try_from(n).ok().filter(|n| *n <= i32::MAX as u32)
}
fn invalid() -> Ack {
    Ack {
        bytes: 0,
        kind: IoKind::Failed,
        error_code: -11001,
    }
}
pub struct PlatformClock<'a> {
    raw: c::R4SdkTransferPlatformClock,
    _provider: Provider<'a>,
}
impl<'a> PlatformClock<'a> {
    pub fn new(ctx: &'a platform2::Context<'_>) -> Result<Self, Error> {
        let address = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, monotonic_clock),
        )?;
        Ok(Self {
            raw: c::R4SdkTransferPlatformClock {
                read: Some(unsafe {
                    mem::transmute::<u64, abi::R4SysFns::monotonic_clock>(address)
                }),
            },
            _provider: PhantomData,
        })
    }
    pub fn sample(&mut self) -> Result<ClockSample, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkTransferReadClock(
                (&mut self.raw as *mut c::R4SdkTransferPlatformClock).cast(),
                out.as_mut_ptr(),
            )
        })?;
        Ok(ClockSample::from_raw(unsafe { out.assume_init() }))
    }
}
pub struct FileReader<'a> {
    raw: c::R4SdkTransferFileRead,
    _provider: Provider<'a>,
    _path: PhantomData<&'a CStr>,
}
impl<'a> FileReader<'a> {
    pub fn new(ctx: &'a platform2::Context<'_>, path: &'a CStr, base: u64) -> Result<Self, Error> {
        let a = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, file_read_at),
        )?;
        Ok(Self {
            raw: c::R4SdkTransferFileRead {
                read: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::file_read_at>(a) }),
                path: path.as_ptr().cast(),
                base_offset: base,
            },
            _provider: PhantomData,
            _path: PhantomData,
        })
    }
    pub fn read(&mut self, chunk: ReadChunk<'_>) -> Ack {
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        Ack::from_raw(unsafe {
            c::R4SdkTransferReadFile(
                (&mut self.raw as *mut c::R4SdkTransferFileRead).cast(),
                chunk.offset,
                chunk.bytes.as_mut_ptr(),
                n,
                chunk.budget.raw,
            )
        })
    }
}
pub struct FileAppender<'a> {
    raw: c::R4SdkTransferFileAppend,
    _provider: Provider<'a>,
    _path: PhantomData<&'a CStr>,
}
impl<'a> FileAppender<'a> {
    pub fn new(ctx: &'a platform2::Context<'_>, path: &'a CStr) -> Result<Self, Error> {
        let a = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, file_append),
        )?;
        Ok(Self {
            raw: c::R4SdkTransferFileAppend {
                append: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::file_append>(a) }),
                path: path.as_ptr().cast(),
            },
            _provider: PhantomData,
            _path: PhantomData,
        })
    }
    pub fn write(&mut self, chunk: WriteChunk<'_>) -> Ack {
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        Ack::from_raw(unsafe {
            c::R4SdkTransferAppendFile(
                (&mut self.raw as *mut c::R4SdkTransferFileAppend).cast(),
                chunk.offset,
                chunk.bytes.as_ptr(),
                n,
                chunk.budget.raw,
            )
        })
    }
}
pub struct FileStreamWriter<'a> {
    raw: c::R4SdkTransferFileStream,
    _provider: Provider<'a>,
    _path: PhantomData<&'a CStr>,
}
impl<'a> FileStreamWriter<'a> {
    pub fn new(ctx: &'a platform2::Context<'_>, path: &'a CStr, base: u64) -> Result<Self, Error> {
        let a = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, file_stream_write),
        )?;
        Ok(Self {
            raw: c::R4SdkTransferFileStream {
                write: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::file_stream_write>(a) }),
                path: path.as_ptr().cast(),
                base_offset: base,
            },
            _provider: PhantomData,
            _path: PhantomData,
        })
    }
    pub fn write(&mut self, chunk: WriteChunk<'_>) -> Ack {
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        Ack::from_raw(unsafe {
            c::R4SdkTransferFileStreamWrite(
                (&mut self.raw as *mut c::R4SdkTransferFileStream).cast(),
                chunk.offset,
                chunk.bytes.as_ptr(),
                n,
                chunk.budget.raw,
            )
        })
    }
}
pub struct Tcp<'a> {
    raw: c::R4SdkTransferTcp,
    _provider: Provider<'a>,
}
impl<'a> Tcp<'a> {
    /// # Safety
    /// Borrow actual TCPSVC endpoint and socket owners in this client's
    /// identity, held valid for this view. This view never closes either.
    pub unsafe fn from_borrowed_handles(
        ctx: &'a platform2::Context<'_>,
        service: u32,
        socket: u32,
    ) -> Result<Self, Error> {
        if service == 0 || socket == 0 {
            return Err(Error(-11001));
        }
        let call = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, service_call),
        )?;
        let mono = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, monotonic_clock),
        )?;
        let ticks = lookup(ctx, mem::offset_of!(platform2::abi::R4XStartR4Sys2, ticks))?;
        Ok(Self {
            raw: c::R4SdkTransferTcp {
                call: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) }),
                monotonic: Some(unsafe {
                    mem::transmute::<u64, abi::R4SysFns::monotonic_clock>(mono)
                }),
                ticks: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::ticks>(ticks) }),
                service_handle: service,
                socket_handle: socket,
            },
            _provider: PhantomData,
        })
    }
    pub fn read(&mut self, chunk: ReadChunk<'_>) -> Ack {
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        Ack::from_raw(unsafe {
            c::R4SdkTransferTcpRead(
                (&mut self.raw as *mut c::R4SdkTransferTcp).cast(),
                chunk.offset,
                chunk.bytes.as_mut_ptr(),
                n,
                chunk.budget.raw,
            )
        })
    }
    pub fn write(&mut self, chunk: WriteChunk<'_>) -> Ack {
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        Ack::from_raw(unsafe {
            c::R4SdkTransferTcpWrite(
                (&mut self.raw as *mut c::R4SdkTransferTcp).cast(),
                chunk.offset,
                chunk.bytes.as_ptr(),
                n,
                chunk.budget.raw,
            )
        })
    }
}
pub struct ServiceReply<'a> {
    raw: c::R4SdkTransferServiceReply,
    _provider: Provider<'a>,
    _request: &'a [u8],
    _scratch: &'a mut [u8],
}
impl<'a> ServiceReply<'a> {
    /// # Safety
    /// The actual borrowed service endpoint remains owned and valid in this
    /// client through every call. The operation returns one bounded reply.
    pub unsafe fn from_borrowed_handle(
        ctx: &'a platform2::Context<'_>,
        service: u32,
        op: u16,
        request: &'a [u8],
        scratch: &'a mut [u8],
    ) -> Result<Self, Error> {
        if service == 0 || request.len() > 4096 || scratch.len() > 4096 {
            return Err(Error(-11001));
        }
        let call = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, service_call),
        )?;
        let mono = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, monotonic_clock),
        )?;
        Ok(Self {
            raw: c::R4SdkTransferServiceReply {
                call: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) }),
                monotonic: Some(unsafe {
                    mem::transmute::<u64, abi::R4SysFns::monotonic_clock>(mono)
                }),
                service_handle: service,
                op,
                reserved: 0,
                request: c::R4SdkWireSpan {
                    address: request.as_ptr() as u64,
                    length: request.len() as u64,
                },
                scratch: c::R4SdkWireSpan {
                    address: scratch.as_mut_ptr() as u64,
                    length: scratch.len() as u64,
                },
                position: 0,
                length: 0,
                loaded: 0,
                flags: 0,
            },
            _provider: PhantomData,
            _request: request,
            _scratch: scratch,
        })
    }
    pub fn read(&mut self, chunk: ReadChunk<'_>) -> Ack {
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        Ack::from_raw(unsafe {
            c::R4SdkTransferServiceRead(
                (&mut self.raw as *mut c::R4SdkTransferServiceReply).cast(),
                chunk.offset,
                chunk.bytes.as_mut_ptr(),
                n,
                chunk.budget.raw,
            )
        })
    }
}
pub struct ServiceResponse<'a> {
    pub offset: u64,
    pub request: &'a [u8],
    pub header: &'a abi::ServiceMessageHeader,
    pub response: &'a [u8],
}
pub struct ServiceSink<'a, F> {
    raw: c::R4SdkTransferServiceSink,
    decode: F,
    _provider: Provider<'a>,
}
impl<'a, F: for<'b> FnMut(ServiceResponse<'b>) -> Ack> ServiceSink<'a, F> {
    /// # Safety
    /// The actual borrowed endpoint stays owned and valid in this client.
    /// The decoder follows this operation's explicit confirmed-prefix wire
    /// contract. A reply byte count alone is never a write acknowledgement.
    pub unsafe fn from_borrowed_handle(
        ctx: &'a platform2::Context<'_>,
        service: u32,
        op: u16,
        decode: F,
    ) -> Result<Self, Error> {
        if service == 0 {
            return Err(Error(-11001));
        }
        let call = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, service_call),
        )?;
        let mono = lookup(
            ctx,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, monotonic_clock),
        )?;
        Ok(Self {
            raw: c::R4SdkTransferServiceSink {
                call: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) }),
                monotonic: Some(unsafe {
                    mem::transmute::<u64, abi::R4SysFns::monotonic_clock>(mono)
                }),
                decode: None,
                decoder_context: core::ptr::null_mut(),
                service_handle: service,
                op,
                reserved: 0,
            },
            decode,
            _provider: PhantomData,
        })
    }
    pub fn write(&mut self, chunk: WriteChunk<'_>) -> Ack {
        unsafe extern "C" fn invoke<F: for<'b> FnMut(ServiceResponse<'b>) -> Ack>(
            raw: *mut core::ffi::c_void,
            offset: u64,
            request: *const u8,
            request_len: u32,
            header: *const abi::ServiceMessageHeader,
            response: *const u8,
            response_len: u32,
        ) -> c::R4SdkTransferAck {
            let f = unsafe { &mut *raw.cast::<F>() };
            f(ServiceResponse {
                offset,
                request: unsafe { core::slice::from_raw_parts(request, request_len as usize) },
                header: unsafe { &*header },
                response: unsafe { core::slice::from_raw_parts(response, response_len as usize) },
            })
            .raw()
        }
        let Some(n) = count(chunk.bytes.len()) else {
            return invalid();
        };
        self.raw.decode = Some(invoke::<F>);
        self.raw.decoder_context = (&mut self.decode as *mut F).cast();
        let ack = unsafe {
            c::R4SdkTransferServiceWrite(
                (&mut self.raw as *mut c::R4SdkTransferServiceSink).cast(),
                chunk.offset,
                chunk.bytes.as_ptr(),
                n,
                chunk.budget.raw,
            )
        };
        self.raw.decoder_context = core::ptr::null_mut();
        Ack::from_raw(ack)
    }
}
