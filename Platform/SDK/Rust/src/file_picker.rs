//! Shared bounded SDK controller; the canonical metadata provider owns I/O.
use crate::{abi, c_facades as c, platform2::Context};
use core::{
    ffi::CStr,
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type Row = c::R4SdkFilePickerRow;
pub type Progress = c::R4SdkFilePickerProgress;
pub type Decision = c::R4SdkFilePickerDecision;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Mode {
    Open,
    Save,
}
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
fn span(bytes: &[u8]) -> c::R4SdkWireSpan {
    c::R4SdkWireSpan {
        address: bytes.as_ptr() as u64,
        length: bytes.len() as u64,
    }
}
/// Both whole row buffers, Context and provider code remain borrowed. Page
/// slices borrow self and cannot coexist with a subsequently used mutable
/// begin/step/cancel. This stores no Kernel handle or inter-call mount lease.
pub struct Session<'a> {
    raw: c::R4SdkFilePicker,
    _context: &'a Context<'a>,
    a: &'a mut [MaybeUninit<Row>],
    b: &'a mut [MaybeUninit<Row>],
    _local: PhantomData<*mut ()>,
}
impl<'a> Session<'a> {
    pub(crate) fn native(&self) -> *const c::R4SdkFilePicker {
        &self.raw
    }
    pub fn new(
        context: &'a Context<'a>,
        a: &'a mut [MaybeUninit<Row>],
        b: &'a mut [MaybeUninit<Row>],
        mode: Mode,
        extension: &[u8],
    ) -> Result<Self, Error> {
        let info = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, file_metadata2) as u32,
            )
            .map_err(Error)?;
        let batch = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, directory_metadata_batch2) as u32,
            )
            .map_err(Error)?;
        let provider = c::R4SdkFilePickerProvider {
            info: Some(unsafe { mem::transmute::<u64, abi::R4SysFns::file_metadata2>(info) }),
            batch: Some(unsafe {
                mem::transmute::<u64, abi::R4SysFns::directory_metadata_batch2>(batch)
            }),
            filter: None,
            filter_context: core::ptr::null_mut(),
        };
        // Context's native creation contract owns these exact callbacks/code.
        unsafe { Self::from_native_provider(context, a, b, mode, extension, provider) }
    }
    /// # Safety
    /// Provider code, filter context and any captured external state must
    /// remain valid/exclusively owned for this session lifetime and obey the
    /// canonical metadata and non-retaining synchronous filter contracts.
    /// No callback may concurrently mutate this owner or end its real loans.
    pub unsafe fn from_native_provider(
        context: &'a Context<'a>,
        a: &'a mut [MaybeUninit<Row>],
        b: &'a mut [MaybeUninit<Row>],
        mode: Mode,
        extension: &[u8],
        provider: c::R4SdkFilePickerProvider,
    ) -> Result<Self, Error> {
        if !(4..=256).contains(&a.len()) || b.len() < a.len() {
            return Err(Error(-202));
        }
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkFilePickerInit(
                c::R4SdkWireSpan {
                    address: a.as_ptr() as u64,
                    length: mem::size_of_val(a) as u64,
                },
                c::R4SdkWireSpan {
                    address: b.as_ptr() as u64,
                    length: mem::size_of_val(b) as u64,
                },
                a.len() as u32,
                match mode {
                    Mode::Open => 1,
                    Mode::Save => 2,
                },
                span(extension),
                provider,
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _context: context,
            a,
            b,
            _local: PhantomData,
        })
    }
    pub fn begin(&mut self, path: &CStr, page: u32) -> Result<(), Error> {
        exact(unsafe { c::R4SdkFilePickerBegin(&mut self.raw, span(path.to_bytes()), page) })
    }
    pub fn step(&mut self, budget: u32) -> Result<Progress, Error> {
        exact(unsafe { c::R4SdkFilePickerStep(&mut self.raw, budget) })?;
        self.progress()
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkFilePickerGetProgress(&self.raw, out.as_mut_ptr()) })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn rows(&self) -> Result<&[Row], Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkFilePickerView(&self.raw, output.as_mut_ptr()) })?;
        let view = unsafe { output.assume_init() };
        let valid = (view.address == self.a.as_ptr() as u64
            && view.length <= mem::size_of_val(self.a) as u64)
            || (view.address == self.b.as_ptr() as u64
                && view.length <= mem::size_of_val(self.b) as u64);
        if !valid || !view.length.is_multiple_of(mem::size_of::<Row>() as u64) {
            return Err(Error(-205));
        }
        // The single exact owner initialized the whole published rows, and
        // exclusive whole buffers stay borrowed until this view ends.
        Ok(unsafe {
            core::slice::from_raw_parts(
                view.address as *const Row,
                (view.length / mem::size_of::<Row>() as u64) as usize,
            )
        })
    }
    pub fn directory(&self) -> Result<&CStr, Error> {
        if self.progress()?.flags & 1 == 0 {
            return Err(Error(-204));
        }
        CStr::from_bytes_until_nul(&self.raw.directory_path).map_err(|_| Error(-205))
    }
    pub fn filename(&self) -> Result<&CStr, Error> {
        CStr::from_bytes_until_nul(&self.raw.filename).map_err(|_| Error(-205))
    }
    pub fn set_name(&mut self, value: &str) -> Result<(), Error> {
        exact(unsafe { c::R4SdkFilePickerName(&mut self.raw, span(value.as_bytes())) })
    }
    pub fn select(&mut self, revision: u64, index: u32, visible: u32) -> Result<(), Error> {
        exact(unsafe { c::R4SdkFilePickerSelect(&mut self.raw, revision, index, visible) })
    }
    pub fn activate(
        &mut self,
        revision: u64,
        use_name: bool,
        allow_overwrite: bool,
    ) -> Result<Decision, Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkFilePickerActivate(
                &mut self.raw,
                revision,
                use_name as u32,
                allow_overwrite as u32,
                output.as_mut_ptr(),
            )
        })?;
        Ok(unsafe { output.assume_init() })
    }
    pub fn key(&mut self, key: u8, visible: u32) -> Result<Decision, Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkFilePickerKey(&mut self.raw, key, visible, output.as_mut_ptr()) })?;
        Ok(unsafe { output.assume_init() })
    }
    pub fn focus(&mut self, focus: u32, pressed: u32) -> Result<(), Error> {
        exact(unsafe { c::R4SdkFilePickerFocus(&mut self.raw, focus, pressed) })
    }
    pub fn cancel(&mut self) -> Result<Decision, Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkFilePickerCancel(&mut self.raw, output.as_mut_ptr()) })?;
        Ok(unsafe { output.assume_init() })
    }
    /// Last confirmed whole observation; not an open handle or current-file
    /// assertion. Failed navigation/activation and Cancel leave it intact.
    pub fn selection(&self) -> &Decision {
        &self.raw.confirmed
    }
}
