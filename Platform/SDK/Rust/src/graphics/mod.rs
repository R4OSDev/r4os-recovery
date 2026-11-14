//! Current graphics owners, independent of windows and Desktop policy.
//! `raw` reaches every public Zig graphics helper through the shared native
//! boundary. Resources close explicitly: Drop is never a fence/reset receipt.
use crate::{
    App, abi, c_facades as c,
    storage::{Error, Result},
};
use core::{
    marker::{PhantomData, PhantomPinned},
    mem::MaybeUninit,
    pin::Pin,
    ptr::NonNull,
};
pub mod raw {
    pub use crate::c_facades::*;
}
mod groups;
pub use groups::{Buffers, Outputs, Queues};

pub struct GraphicsStorage {
    value: MaybeUninit<c::R4SdkGfxContext>,
    _pin: PhantomPinned,
}
impl Default for GraphicsStorage {
    fn default() -> Self {
        Self::new()
    }
}
impl GraphicsStorage {
    pub const fn new() -> Self {
        Self {
            value: MaybeUninit::uninit(),
            _pin: PhantomPinned,
        }
    }
}
pub struct Graphics<'s, 'a> {
    draw: NonNull<c::R4SdkGuiDrawContext>,
    dev: NonNull<c::R4SdkGfxDeviceContext>,
    _storage: PhantomData<Pin<&'s mut GraphicsStorage>>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'a> Graphics<'s, 'a> {
    pub fn open(storage: Pin<&'s mut GraphicsStorage>, app: &'a App<'_>) -> Result<Self> {
        Self::open2(storage, app)
    }
    pub fn buffers(&self) -> Buffers<'_> {
        Buffers::new(self.draw)
    }
    pub fn open2(
        storage: Pin<&'s mut GraphicsStorage>,
        app: &'a crate::app2::App<'_>,
    ) -> Result<Self> {
        let native = unsafe { storage.get_unchecked_mut() }.value.as_mut_ptr();
        let rc = unsafe { c::R4SdkGfxOpen2(native, app.start_context()) };
        if rc != 0 {
            return Err(Error::Raw(rc));
        }
        Ok(Self {
            draw: NonNull::new(unsafe { c::R4SdkGfxDraw(native) }).ok_or(Error::InvalidProvider)?,
            dev: NonNull::new(unsafe { c::R4SdkGfxDevice(native) })
                .ok_or(Error::InvalidProvider)?,
            _storage: PhantomData,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn outputs(&self) -> Outputs<'_> {
        Outputs::new(self.draw)
    }
    pub fn queues(&self) -> Queues<'_> {
        Queues::new(self.draw)
    }
    /// # Safety
    /// Borrow only while this context and its App live. Preserve native
    /// resource, mapping, producer, retention and exact completion contracts.
    pub unsafe fn native_draw(&self) -> *mut c::R4SdkGuiDrawContext {
        self.draw.as_ptr()
    }
    /// # Safety
    /// Preserve the same context lifetime and native status-owner contracts.
    pub unsafe fn native_device(&self) -> *mut c::R4SdkGfxDeviceContext {
        self.dev.as_ptr()
    }
    pub fn telemetry(&self, input: &abi::GfxTelemetryRequest) -> Result<abi::GfxTelemetryState> {
        let mut out = abi::GfxTelemetryState::default();
        positive(unsafe {
            c::R4SdkGuiDrawContext_gfxTelemetry(0, self.draw.as_ptr(), input, &mut out)
        })?;
        Ok(out)
    }
    pub fn telemetry_for_adapter(&self, adapter: u32, mask: u64) -> Result<abi::GfxTelemetryState> {
        let mut out = abi::GfxTelemetryState::default();
        positive(unsafe {
            c::R4SdkGui_telemetryForAdapter(0, self.draw.as_ptr(), adapter, mask, &mut out)
        })?;
        Ok(out)
    }
    pub fn snapshot(&self) -> Result<Option<Snapshot>> {
        let mut native = MaybeUninit::uninit();
        let result = transport(unsafe {
            c::R4SdkGraphicsStatusSnapshot_read(0, self.dev.as_ptr(), native.as_mut_ptr())
        })?;
        Ok(if result.flags & 1 == 0 {
            None
        } else {
            Some(Snapshot { native })
        })
    }
    pub fn present_capabilities(&self) -> Result<abi::DisplayPresentCapabilities> {
        let mut out = abi::DisplayPresentCapabilities::default();
        code(unsafe {
            c::R4SdkGuiDrawContext_displayPresentCapabilities(0, self.draw.as_ptr(), &mut out)
        })?;
        Ok(out)
    }
    pub fn present_completion(&self, fence: u64) -> Result<abi::DisplayPresentCompletion> {
        let mut out = abi::DisplayPresentCompletion::default();
        code(unsafe {
            c::R4SdkGuiDrawContext_displayPresentCompletion(0, self.draw.as_ptr(), fence, &mut out)
        })?;
        Ok(out)
    }
    /// # Safety
    /// Caller owns the selected output and its present interval. Inputs remain
    /// valid as required by the current backend. Submit/copy is not visibility.
    pub unsafe fn present_regions(
        &self,
        request: &abi::DisplayPresentRequest,
        pixels: &[u32],
        regions: &[abi::DisplayDamageRect],
    ) -> Result<abi::DisplayPresentResult> {
        let mut out = abi::DisplayPresentResult::default();
        code(unsafe {
            c::R4SdkGuiDrawContext_displayPresentRegions(
                0,
                self.draw.as_ptr(),
                request,
                pixels.as_ptr(),
                pixels.len() as u64,
                regions.as_ptr(),
                regions.len() as u64,
                &mut out,
            )
        })?;
        Ok(out)
    }
}
pub(crate) fn transport(value: c::R4SdkGuiSlot) -> Result<c::R4SdkGuiSlot> {
    if value.status < 0 {
        Err(Error::Raw(value.status))
    } else if value.flags & 2 != 0 {
        Err(Error::InvalidProvider)
    } else {
        Ok(value)
    }
}
pub(crate) fn code(value: c::R4SdkGuiSlot) -> Result<i32> {
    let value = transport(value)?.bits as i32;
    if value < 0 {
        Err(Error::Raw(value))
    } else {
        Ok(value)
    }
}
pub(crate) fn positive(value: c::R4SdkGuiSlot) -> Result<()> {
    match code(value)? {
        1 => Ok(()),
        other => Err(Error::Raw(other)),
    }
}
fn text_view(value: c::R4SdkGuiSlot, _output: &mut [u8]) -> Result<&str> {
    let value = transport(value)?;
    let size = usize::try_from(value.length).map_err(|_| Error::Length)?;
    if size > isize::MAX as usize || (size != 0 && value.ptr.is_null()) {
        return Err(Error::InvalidProvider);
    }
    // Reborrow caller bytes through the current Rust loan, not through a
    // foreign pointer preceding its retag. Outside this buffer the two shared
    // Zig formatters return only resident constant strings.
    let address = value.ptr as usize;
    let base = _output.as_ptr() as usize;
    let offset = address.checked_sub(base);
    let bytes = if size == 0 {
        &[]
    } else if let Some(offset) = offset.filter(|&n| n <= _output.len()) {
        _output
            .get(offset..offset.checked_add(size).ok_or(Error::Length)?)
            .ok_or(Error::InvalidProvider)?
    } else {
        unsafe { core::slice::from_raw_parts(value.ptr.cast::<u8>(), size) }
    };
    core::str::from_utf8(bytes).map_err(|_| Error::InvalidProvider)
}
pub fn telemetry_line<'a>(
    output: &'a mut [u8],
    state: &abi::GfxTelemetryState,
    index: usize,
) -> Result<&'a str> {
    let value = unsafe {
        c::R4SdkGfxTelemetry_formatLine(
            0,
            output.as_mut_ptr(),
            output.len() as u64,
            state,
            index as u64,
        )
    };
    text_view(value, output)
}
pub struct Snapshot {
    native: MaybeUninit<c::R4SdkGraphicsStatusSnapshot>,
}
impl Snapshot {
    pub fn display(&self) -> Result<abi::DisplayStateInfo> {
        let mut out = abi::DisplayStateInfo::default();
        transport(unsafe {
            c::R4SdkGraphicsStatusSnapshot_get_display(self.native.as_ptr(), &mut out)
        })?;
        Ok(out)
    }
    pub fn driver(&self) -> Result<Option<abi::DriverModuleInfo>> {
        let mut out = abi::DriverModuleInfo::default();
        let value = transport(unsafe {
            c::R4SdkGraphicsStatusSnapshot_get_driver(self.native.as_ptr(), &mut out)
        })?;
        Ok(if value.flags & 1 == 0 {
            None
        } else {
            Some(out)
        })
    }
    pub fn line<'a>(&self, output: &'a mut [u8], index: usize) -> Result<&'a str> {
        let value = unsafe {
            c::R4SdkGraphicsStatusSnapshot_line(
                0,
                self.native.as_ptr(),
                output.as_mut_ptr(),
                output.len() as u64,
                index as u64,
            )
        };
        text_view(value, output)
    }
}
