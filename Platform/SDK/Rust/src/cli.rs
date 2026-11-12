//! R4OS argument grammar and whole UTF8 diagnostic records. The shared static
//! SDK owner implements parsing, admission, prefix accounting and sink policy.
use crate::{abi, c_facades as c, platform2, time::checked::BudgetValue};
use core::{
    ffi::CStr,
    marker::PhantomData,
    mem::{self, MaybeUninit},
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ArgError {
    pub code: i32,
    pub offset: usize,
}
#[derive(Debug, Clone, Copy)]
pub enum Quotes {
    None,
    FullToken,
}
#[derive(Debug, Clone, Copy)]
pub struct ArgPolicy {
    pub quotes: Quotes,
    pub slash: bool,
    pub dash: bool,
    pub max_bytes: usize,
}
impl Default for ArgPolicy {
    fn default() -> Self {
        Self {
            quotes: Quotes::FullToken,
            slash: true,
            dash: false,
            max_bytes: 4096,
        }
    }
}
pub struct ArgCursor<'a> {
    raw: c::R4SdkArgCursor,
    input: &'a [u8],
}
#[derive(Clone, Copy)]
pub struct ArgToken<'a> {
    raw: c::R4SdkArgToken,
    input: &'a [u8],
}
pub struct Switch<'a> {
    pub name: &'a [u8],
    pub value: Option<&'a [u8]>,
}
impl<'a> ArgCursor<'a> {
    pub fn new(input: &'a [u8], policy: ArgPolicy) -> Result<Self, ArgError> {
        let mut raw = MaybeUninit::uninit();
        let mut failure = MaybeUninit::<c::R4SdkArgFailure>::zeroed();
        let policy = c::R4SdkArgPolicy {
            quotes: match policy.quotes {
                Quotes::None => 0,
                Quotes::FullToken => 1,
            },
            switches: u32::from(policy.slash) | (u32::from(policy.dash) << 1),
            max_bytes: policy.max_bytes as u64,
        };
        let rc = unsafe {
            c::R4SdkArgInit(
                input.as_ptr(),
                input.len() as u64,
                policy,
                raw.as_mut_ptr(),
                failure.as_mut_ptr(),
            )
        };
        if rc != 0 {
            return Err(ArgError {
                code: rc,
                offset: unsafe { failure.assume_init() }.offset as usize,
            });
        }
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            input,
        })
    }
    pub fn next_token(&mut self) -> Result<Option<ArgToken<'a>>, ArgError> {
        let mut raw = MaybeUninit::uninit();
        let mut failure = MaybeUninit::<c::R4SdkArgFailure>::zeroed();
        let rc = unsafe { c::R4SdkArgNext(&mut self.raw, raw.as_mut_ptr(), failure.as_mut_ptr()) };
        match rc {
            0 => Ok(Some(ArgToken {
                raw: unsafe { raw.assume_init() },
                input: self.input,
            })),
            1 => Ok(None),
            _ => Err(ArgError {
                code: rc,
                offset: unsafe { failure.assume_init() }.offset as usize,
            }),
        }
    }
    fn remaining(&self, trim: u32) -> Result<&'a [u8], ArgError> {
        let (mut start, mut len) = (0, 0);
        let rc = unsafe { c::R4SdkArgRemaining(&self.raw, trim, &mut start, &mut len) };
        if rc != 0 {
            return Err(ArgError {
                code: rc,
                offset: self.raw.position as usize,
            });
        }
        self.input
            .get(
                start as usize..(start as usize).checked_add(len as usize).ok_or(ArgError {
                    code: -7,
                    offset: 0,
                })?,
            )
            .ok_or(ArgError {
                code: -7,
                offset: 0,
            })
    }
    pub fn remaining_raw(&self) -> Result<&'a [u8], ArgError> {
        self.remaining(0)
    }
    pub fn remaining_arguments(&self) -> Result<&'a [u8], ArgError> {
        self.remaining(1)
    }
}
impl<'a> ArgToken<'a> {
    pub fn bytes(&self) -> &'a [u8] {
        &self.input[self.raw.value_start as usize..self.raw.value_end as usize]
    }
    pub fn quoted(&self) -> bool {
        self.raw.flags & 1 != 0
    }
    pub fn raw_bytes(&self) -> &'a [u8] {
        &self.input[self.raw.raw_start as usize..self.raw.raw_end as usize]
    }
    pub fn switch_parts(&self) -> Result<Option<Switch<'a>>, ArgError> {
        let mut result = MaybeUninit::uninit();
        let rc = unsafe {
            c::R4SdkArgSwitchParts(
                self.input.as_ptr(),
                self.input.len() as u64,
                self.raw,
                result.as_mut_ptr(),
            )
        };
        if rc != 0 {
            return Err(ArgError {
                code: rc,
                offset: self.raw.raw_start as usize,
            });
        }
        let result = unsafe { result.assume_init() };
        if result.is_switch == 0 {
            return Ok(None);
        }
        let span = |start: u64, len: u64| {
            self.input
                .get(start as usize..(start as usize).checked_add(len as usize)?)
        };
        let invalid = ArgError {
            code: -7,
            offset: self.raw.raw_start as usize,
        };
        Ok(Some(Switch {
            name: span(result.name_start, result.name_length).ok_or(invalid)?,
            value: if result.has_value == 0 {
                None
            } else {
                Some(span(result.value_start, result.value_length).ok_or(invalid)?)
            },
        }))
    }
    pub fn switch_is(&self, name: &[u8]) -> Result<bool, ArgError> {
        Ok(self
            .switch_parts()?
            .is_some_and(|s| s.name.eq_ignore_ascii_case(name)))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DiagnosticError(pub i32);
fn exact(rc: i32) -> Result<(), DiagnosticError> {
    if rc == 0 {
        Ok(())
    } else {
        Err(DiagnosticError(rc))
    }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Severity {
    Debug = 0,
    Info = 1,
    Warning = 2,
    Error = 3,
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SinkKind {
    Accepted = 0,
    WouldBlock = 1,
    Failed = 2,
    Uncertain = 3,
}
#[derive(Debug, Clone, Copy)]
pub struct Ack {
    pub accepted_bytes: u32,
    pub kind: SinkKind,
    pub error_code: i32,
}
impl Ack {
    pub fn accepted(bytes: u32) -> Self {
        Self {
            accepted_bytes: bytes,
            kind: SinkKind::Accepted,
            error_code: 0,
        }
    }
    fn raw(self) -> c::R4SdkDiagnosticAck {
        c::R4SdkDiagnosticAck {
            accepted_bytes: self.accepted_bytes,
            kind: self.kind as u32,
            error_code: self.error_code,
            reserved: 0,
        }
    }
    fn from_raw(raw: c::R4SdkDiagnosticAck) -> Self {
        Self {
            accepted_bytes: raw.accepted_bytes,
            kind: match raw.kind {
                0 => SinkKind::Accepted,
                1 => SinkKind::WouldBlock,
                2 => SinkKind::Failed,
                _ => SinkKind::Uncertain,
            },
            error_code: raw.error_code,
        }
    }
}
/// A byte fragment can start or end inside a scalar after partial transport
/// acceptance. It is deliberately not a str. Never retained past callback return.
pub struct Chunk<'a> {
    pub bytes: &'a [u8],
    pub total: u32,
    pub offset: u32,
    pub severity: Severity,
}
impl Chunk<'_> {
    fn raw(&self) -> Option<c::R4SdkDiagnosticChunk> {
        let length = u32::try_from(self.bytes.len()).ok()?;
        if length > i32::MAX as u32 || self.offset.checked_add(length)? > self.total {
            return None;
        }
        Some(c::R4SdkDiagnosticChunk {
            data: self.bytes.as_ptr(),
            length,
            total: self.total,
            offset: self.offset,
            severity: self.severity as u32,
        })
    }
}
fn invalid_chunk() -> Ack {
    Ack {
        accepted_bytes: 0,
        kind: SinkKind::Failed,
        error_code: -10001,
    }
}
pub type AppendResult = c::R4SdkDiagnosticAppend;
pub type FlushResult = c::R4SdkDiagnosticFlush;
pub type Stats = c::R4SdkDiagnosticStats;
pub type DiscardResult = c::R4SdkDiagnosticDiscard;
pub struct BoundedDiagnosticBuffer<'a> {
    raw: c::R4SdkDiagnosticBuffer,
    _storage: PhantomData<&'a mut [u8]>,
    _local: PhantomData<*mut ()>,
}
impl<'a> BoundedDiagnosticBuffer<'a> {
    pub fn new(storage: &'a mut [u8]) -> Result<Self, DiagnosticError> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDiagnosticInit(storage.as_mut_ptr(), storage.len() as u64, raw.as_mut_ptr())
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _storage: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn append_record(
        &mut self,
        text: &str,
        severity: Severity,
    ) -> Result<AppendResult, DiagnosticError> {
        let mut result = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDiagnosticAppendRecord(
                &mut self.raw,
                text.as_ptr(),
                text.len() as u64,
                severity as u32,
                result.as_mut_ptr(),
            )
        })?;
        Ok(unsafe { result.assume_init() })
    }
    pub fn flush_once<F>(
        &mut self,
        max_bytes: u32,
        mut sink: F,
    ) -> Result<FlushResult, DiagnosticError>
    where
        F: for<'b> FnMut(Chunk<'b>) -> Ack,
    {
        unsafe extern "C" fn invoke<F>(
            context: *mut core::ffi::c_void,
            raw: *const c::R4SdkDiagnosticChunk,
        ) -> c::R4SdkDiagnosticAck
        where
            F: for<'b> FnMut(Chunk<'b>) -> Ack,
        {
            let callback = unsafe { &mut *context.cast::<F>() };
            let raw = unsafe { &*raw };
            let chunk = Chunk {
                bytes: unsafe { core::slice::from_raw_parts(raw.data, raw.length as usize) },
                total: raw.total,
                offset: raw.offset,
                severity: match raw.severity {
                    0 => Severity::Debug,
                    1 => Severity::Info,
                    2 => Severity::Warning,
                    _ => Severity::Error,
                },
            };
            callback(chunk).raw()
        }
        let mut result = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDiagnosticFlushOnce(
                &mut self.raw,
                max_bytes,
                Some(invoke::<F>),
                (&mut sink as *mut F).cast(),
                result.as_mut_ptr(),
            )
        })?;
        Ok(unsafe { result.assume_init() })
    }
    pub fn stats(&self) -> Result<Stats, DiagnosticError> {
        let mut r = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDiagnosticReadStats(&self.raw, r.as_mut_ptr()) })?;
        Ok(unsafe { r.assume_init() })
    }
    /// Explicit local discard; never a peer cancellation or hardware stop ACK.
    pub fn discard(&mut self) -> Result<DiscardResult, DiagnosticError> {
        let mut r = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDiagnosticDiscardAll(&mut self.raw, r.as_mut_ptr()) })?;
        Ok(unsafe { r.assume_init() })
    }
}
pub struct ConsoleSink<'a> {
    raw: c::R4SdkDiagnosticConsole,
    _provider: PhantomData<&'a platform2::Context<'a>>,
}
impl<'a> ConsoleSink<'a> {
    pub fn new(
        context: &'a platform2::Context<'_>,
        stream: abi::ConsoleStream,
    ) -> Result<Self, i32> {
        let address = context.lookup(
            2,
            mem::offset_of!(platform2::abi::R4XStartR4Desk2, console_write) as u32,
        )?;
        if stream != abi::ConsoleStream::stdout && stream != abi::ConsoleStream::stderr {
            return Err(-10001);
        }
        Ok(Self {
            raw: c::R4SdkDiagnosticConsole {
                write: Some(unsafe {
                    mem::transmute::<u64, abi::R4DeskFns::console_write>(address)
                }),
                stream: stream.0,
                reserved: 0,
            },
            _provider: PhantomData,
        })
    }
    pub fn send(&mut self, chunk: Chunk<'_>) -> Ack {
        let Some(raw) = chunk.raw() else {
            return invalid_chunk();
        };
        Ack::from_raw(unsafe {
            c::R4SdkDiagnosticConsoleSend(
                (&mut self.raw as *mut c::R4SdkDiagnosticConsole).cast(),
                &raw,
            )
        })
    }
}
pub struct FileSink<'a> {
    raw: c::R4SdkDiagnosticFile,
    _provider: PhantomData<&'a platform2::Context<'a>>,
    _path: PhantomData<&'a CStr>,
}
impl<'a> FileSink<'a> {
    /// Appends to an already prepared path. No hidden creation/truncation.
    pub fn new(context: &'a platform2::Context<'_>, path: &'a CStr) -> Result<Self, i32> {
        let address = context.lookup(
            1,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, file_append) as u32,
        )?;
        Ok(Self {
            raw: c::R4SdkDiagnosticFile {
                append: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::file_append>(address) }),
                path: path.as_ptr().cast(),
            },
            _provider: PhantomData,
            _path: PhantomData,
        })
    }
    pub fn send(&mut self, chunk: Chunk<'_>) -> Ack {
        let Some(raw) = chunk.raw() else {
            return invalid_chunk();
        };
        Ack::from_raw(unsafe {
            c::R4SdkDiagnosticFileSend((&mut self.raw as *mut c::R4SdkDiagnosticFile).cast(), &raw)
        })
    }
}
/// Explicitly close a pending handle before dropping. Forgetting a pending
/// handle leaks a service reference; no callback retains origin/payload bytes.
#[must_use]
pub struct LogSink<'a> {
    raw: c::R4SdkDiagnosticLog,
    _provider: PhantomData<&'a platform2::Context<'a>>,
    _origin: PhantomData<&'a str>,
    _local: PhantomData<*mut ()>,
}
impl<'a> LogSink<'a> {
    pub fn new(
        context: &'a platform2::Context<'_>,
        origin: &'a str,
        ticks: BudgetValue,
    ) -> Result<Self, i32> {
        let (kind, value) = match ticks {
            BudgetValue::Poll => (0, 0),
            BudgetValue::Finite(n) if n > 0 && n < u64::MAX => (1, n),
            _ => return Err(-10001),
        };
        let open = context.lookup(
            1,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, service_open) as u32,
        )?;
        let call = context.lookup(
            1,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, service_call) as u32,
        )?;
        let close = context.lookup(
            1,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, service_close) as u32,
        )?;
        Ok(Self {
            raw: c::R4SdkDiagnosticLog {
                open: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_open>(open) }),
                call: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) }),
                close: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::service_close>(close) }),
                origin: origin.as_ptr(),
                origin_length: origin.len() as u64,
                call_ticks: c::R4SdkBudgetValue {
                    kind,
                    reserved: 0,
                    value,
                },
                active_handle: 0,
                last_close_error: 0,
                busy: 0,
                reserved: 0,
            },
            _provider: PhantomData,
            _origin: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn send(&mut self, chunk: Chunk<'_>) -> Ack {
        let Some(raw) = chunk.raw() else {
            return invalid_chunk();
        };
        Ack::from_raw(unsafe {
            c::R4SdkDiagnosticLogSend((&mut self.raw as *mut c::R4SdkDiagnosticLog).cast(), &raw)
        })
    }
    pub fn close_pending(&mut self) -> Result<(), DiagnosticError> {
        exact(unsafe { c::R4SdkDiagnosticLogClose(&mut self.raw) })
    }
    pub fn pending_handle(&self) -> u32 {
        self.raw.active_handle
    }
    pub fn last_close_error(&self) -> i32 {
        self.raw.last_close_error
    }
}
