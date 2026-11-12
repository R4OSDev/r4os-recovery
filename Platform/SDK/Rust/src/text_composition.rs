//! Copied editor-thread state over the original shared SDK composition owner.
//! Acquire current focus/provider outside GUI/text locks. Pass copied current
//! scope at every event; actual local focus/view/provider loss must Refresh or
//! Cancel before later events. No document/provider pointer is retained.
use crate::{abi as a, c_facades as c, platform2::Context};
use core::{
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type Id = a::CompositionId;
pub type Focus = a::CompositionFocus;
pub type Provider = a::CompositionProvider;
pub type Event = a::CompositionEvent;
pub type Caret = a::CompositionCaret;
pub type Range = a::Utf8ByteRange;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
fn span(bytes: &[u8]) -> c::R4SdkWireSpan {
    c::R4SdkWireSpan {
        address: bytes.as_ptr() as u64,
        length: bytes.len() as u64,
    }
}
/// A replacement owner needs a new nonreused generation within its full window
/// lifetime. Do not clone a live state. Preedit views cannot coexist with a
/// subsequently used mutable transition. Init fully initializes its byte array.
pub struct Session {
    raw: c::R4SdkComposition,
    _local: PhantomData<*mut ()>,
}
impl Session {
    pub(crate) fn native_mut(&mut self) -> *mut c::R4SdkComposition {
        &mut self.raw
    }
    pub fn new(owner_generation: u64) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkCompositionInit(owner_generation, raw.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _local: PhantomData,
        })
    }
    pub fn begin(
        &mut self,
        focus: Focus,
        provider: Provider,
        revision: u64,
        document: &str,
        replacement: Range,
        caret: Caret,
    ) -> Result<Id, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkCompositionBegin(
                &mut self.raw,
                &focus,
                &provider,
                revision,
                &span(document.as_bytes()),
                &replacement,
                &caret,
                out.as_mut_ptr(),
            )
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn refresh(
        &mut self,
        focus: Focus,
        provider: Provider,
        revision: u64,
    ) -> Result<(), Error> {
        exact(unsafe { c::R4SdkCompositionRefresh(&mut self.raw, &focus, &provider, revision) })
    }
    // Keep the atomic ABI operation and all of its borrowed document fields
    // in one call; no intermediate setter can publish a partial transition.
    #[allow(clippy::too_many_arguments)]
    pub fn apply(
        &mut self,
        focus: Focus,
        provider: Provider,
        event: &Event,
        text: &str,
        document: &mut [u8],
        length: &mut usize,
        revision: &mut u64,
    ) -> Result<(), Error> {
        let mut count = *length as u64;
        let storage = span(document);
        exact(unsafe {
            c::R4SdkCompositionApply(
                &mut self.raw,
                &focus,
                &provider,
                event,
                &span(text.as_bytes()),
                &storage,
                &mut count,
                revision,
            )
        })?;
        *length = count as usize;
        Ok(())
    }
    pub fn cancel(&mut self, id: Id) -> Result<(), Error> {
        exact(unsafe { c::R4SdkCompositionCancel(&mut self.raw, &id) })
    }
    pub fn preedit(&self) -> Result<&str, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkCompositionPreedit(&self.raw, out.as_mut_ptr()) })?;
        let view = unsafe { out.assume_init() };
        if view.address != self.raw.r#data.as_ptr() as u64
            || view.length > a::composition_max_text_bytes
        {
            return Err(Error(a::composition_error_invalid));
        }
        let bytes = &self.raw.r#data[..view.length as usize];
        core::str::from_utf8(bytes).map_err(|_| Error(a::composition_error_encoding))
    }
    pub fn caret(
        &mut self,
        focus: Focus,
        provider: Provider,
        revision: u64,
    ) -> Result<Caret, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkCompositionCaret(&mut self.raw, &focus, &provider, revision, out.as_mut_ptr())
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn set_caret(
        &mut self,
        focus: Focus,
        provider: Provider,
        revision: u64,
        caret: Caret,
    ) -> Result<(), Error> {
        exact(unsafe {
            c::R4SdkCompositionSetCaret(&mut self.raw, &focus, &provider, revision, &caret)
        })
    }
    pub fn surrounding(
        &mut self,
        focus: Focus,
        provider: Provider,
        revision: u64,
        document: &str,
        range: Range,
        storage: &mut [u8],
    ) -> Result<usize, Error> {
        let mut out = 0;
        exact(unsafe {
            c::R4SdkCompositionSurrounding(
                &mut self.raw,
                &focus,
                &provider,
                revision,
                &span(document.as_bytes()),
                &range,
                &span(storage),
                &mut out,
            )
        })?;
        Ok(out as usize)
    }
}
/// Separate, explicit original WINSVC service channel, no automatic retry or
/// fallback. A copied reply's result/capability is distinct from transport.
pub struct Client<'a> {
    _context: &'a Context<'a>,
    call: a::R4SysFns::service_call,
    close: a::R4SysFns::service_close,
    handle: u32,
    timeout_ticks: u64,
    _local: PhantomData<*mut ()>,
}
impl<'a> Client<'a> {
    pub fn connect(context: &'a Context<'a>, timeout_ticks: u64) -> Result<Self, Error> {
        if timeout_ticks == 0 {
            return Err(Error(a::composition_error_invalid));
        }
        let open = context
            .lookup(
                1,
                mem::offset_of!(a::generation2::R4XStartR4Sys2, service_open) as u32,
            )
            .map_err(Error)?;
        let call = context
            .lookup(
                1,
                mem::offset_of!(a::generation2::R4XStartR4Sys2, service_call) as u32,
            )
            .map_err(Error)?;
        let close = context
            .lookup(
                1,
                mem::offset_of!(a::generation2::R4XStartR4Sys2, service_close) as u32,
            )
            .map_err(Error)?;
        let open: a::R4SysFns::service_open = unsafe { mem::transmute(open) };
        let mut info = a::ServiceInfo::default();
        exact(unsafe { open(c"WINSVC".as_ptr().cast(), &mut info) })?;
        if info.handle == 0 {
            return Err(Error(a::composition_error_unsupported));
        }
        Ok(Self {
            _context: context,
            call: unsafe { mem::transmute::<u64, a::R4SysFns::service_call>(call) },
            close: unsafe { mem::transmute::<u64, a::R4SysFns::service_close>(close) },
            handle: info.handle,
            timeout_ticks,
            _local: PhantomData,
        })
    }
    pub fn close(&mut self) -> Result<(), Error> {
        if self.handle == 0 {
            return Err(Error(a::composition_error_invalid));
        }
        let code = unsafe { (self.close)(self.handle) };
        if code < 0 {
            return Err(Error(code));
        }
        self.handle = 0;
        Ok(())
    }
    fn rpc<T: Copy>(&mut self, op: u16, request: &[u8]) -> Result<T, Error> {
        if self.handle == 0 {
            return Err(Error(a::composition_error_invalid));
        }
        let mut out = MaybeUninit::<T>::uninit();
        let mut header = a::ServiceMessageHeader::default();
        let code = unsafe {
            (self.call)(
                self.handle,
                op,
                request.as_ptr(),
                request.len() as u32,
                &mut header,
                out.as_mut_ptr().cast(),
                mem::size_of::<T>() as u32,
                self.timeout_ticks,
            )
        };
        if code < 0 {
            return Err(Error(code));
        }
        if header.status == a::service_api_result_bad_op {
            return Err(Error(a::composition_error_unsupported));
        }
        if header.status != 0 {
            return Err(Error(if header.status < 0 {
                header.status
            } else {
                a::composition_error_invalid
            }));
        }
        if code as usize != mem::size_of::<T>() {
            return Err(Error(a::composition_error_invalid));
        }
        // Private callers select only fixed padding-free integer wire records.
        Ok(unsafe { out.assume_init() })
    }
    pub fn capability(&mut self) -> Result<a::CompositionCapabilityReply, Error> {
        let value: a::CompositionCapabilityReply = self.rpc(a::composition_op_capability, &[])?;
        let p = value.provider;
        if value.reserved != 0
            || p.version != 1
            || p.size != mem::size_of::<Provider>() as u32
            || p.max_text_bytes == 0
            || u64::from(p.max_text_bytes) > a::composition_max_text_bytes
            || p.features > 1
        {
            return Err(Error(a::composition_error_invalid));
        }
        if p.features == 0 {
            if value.result != a::composition_error_no_provider
                || p.process.instance_id != 0
                || p.process.reserved != 0
                || p.process.generation != 0
                || p.generation != 0
            {
                return Err(Error(a::composition_error_invalid));
            }
        } else if value.result != 0
            || p.process.instance_id == 0
            || p.process.reserved != 0
            || p.process.generation == 0
            || p.generation == 0
        {
            return Err(Error(a::composition_error_invalid));
        }
        Ok(value)
    }
    pub fn focus(
        &mut self,
        expected: a::WindowModeIdentity,
    ) -> Result<a::CompositionFocusReply, Error> {
        let bytes = unsafe {
            core::slice::from_raw_parts(
                (&expected as *const a::WindowModeIdentity).cast(),
                mem::size_of_val(&expected),
            )
        };
        let value: a::CompositionFocusReply = self.rpc(a::composition_op_focus, bytes)?;
        if value.reserved != 0
            || !matches!(
                value.result,
                0 | a::composition_error_no_focus | a::composition_error_stale_view
            )
        {
            return Err(Error(a::composition_error_invalid));
        }
        if value.result == 0 {
            let f = value.focus;
            let handles = [f.window.service, f.window.desktop, f.window.owner];
            if f.version != 1
                || f.size != mem::size_of::<Focus>() as u32
                || f.reserved != 0
                || f.focused != 1
                || f.window.reserved != 0
                || f.window.serial == 0
                || f.view_generation == 0
                || f.focus_generation == 0
                || f.input_revision == 0
                || f.observed_tick == 0
                || handles
                    .iter()
                    .any(|h| h.instance_id == 0 || h.generation == 0 || h.reserved != 0)
                || !same_window(f.window, expected)
            {
                return Err(Error(a::composition_error_invalid));
            }
        }
        Ok(value)
    }
}
fn same_window(x: a::WindowModeIdentity, y: a::WindowModeIdentity) -> bool {
    let id = |h: a::ProgramProcessHandle, k: a::ProgramProcessHandle| {
        h.instance_id == k.instance_id && h.reserved == k.reserved && h.generation == k.generation
    };
    id(x.service, y.service)
        && id(x.desktop, y.desktop)
        && id(x.owner, y.owner)
        && x.serial == y.serial
        && x.window_id == y.window_id
        && x.reserved == y.reserved
}
