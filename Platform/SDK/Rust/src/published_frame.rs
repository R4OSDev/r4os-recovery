//! Scoped complete-frame loans over the original serialized copy Presenter.
use crate::{c_facades as c, subsystems::Callbacks};
use core::{
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type Rectangle = c::R4SdkPublishedFrameRect;
pub type Presentation = c::R4SdkPublishedFramePresentation;
pub type Progress = c::R4SdkPublishedFrameProgress;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
#[derive(Clone, Copy)]
pub struct Stamp {
    pub binding_generation: u64,
    pub revision: u64,
    pub palette_revision: u64,
}
#[derive(Clone, Copy)]
pub enum Damage {
    Full,
    None { base_revision: u64 },
    Rectangle { base_revision: u64, rect: Rectangle },
}
fn damage(raw: &mut c::R4SdkPublishedFrameLease, value: Damage) {
    match value {
        Damage::Full => {}
        Damage::None { base_revision } => {
            raw.damage_kind = 2;
            raw.damage_base_revision = base_revision;
        }
        Damage::Rectangle {
            base_revision,
            rect,
        } => {
            raw.damage_kind = 1;
            raw.damage_base_revision = base_revision;
            raw.damage = rect;
        }
    }
}
fn span<T>(values: &[T]) -> c::R4SdkWireSpan {
    c::R4SdkWireSpan {
        address: values.as_ptr() as u64,
        length: mem::size_of_val(values) as u64,
    }
}
/// Producer-owned complete publication, never a working-frame claim inferred
/// from a pointer. Whole immutable source/palette loans survive inside Frame.
pub struct Published<'a> {
    raw: c::R4SdkPublishedFrameLease,
    _pixels: PhantomData<&'a [u8]>,
    _palette: PhantomData<&'a [u32]>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Published<'a> {
    /// # Safety
    /// Pixels are one fully published packed frame, with a truthful nonreused
    /// producer binding/revision and damage base. The producer never exposes
    /// working_frame and does not mutate/free the whole source through this
    /// immutable loan. No concurrent publisher or hardware/fence inference.
    pub unsafe fn xrgb(
        pixels: &'a [u32],
        width: u32,
        height: u32,
        stamp: Stamp,
        changed: Damage,
    ) -> Result<Self, Error> {
        let stride = width.checked_mul(4).ok_or(Error(-403))?;
        let mut raw = c::R4SdkPublishedFrameLease {
            pixels: span(pixels),
            palette: c::R4SdkWireSpan {
                address: 0,
                length: 0,
            },
            binding_generation: stamp.binding_generation,
            revision: stamp.revision,
            palette_revision: stamp.palette_revision,
            damage_base_revision: 0,
            width,
            height,
            stride_bytes: stride,
            format: 1,
            damage_kind: 0,
            flags: 1,
            reserved0: 0,
            reserved1: 0,
            damage: Rectangle {
                x: 0,
                y: 0,
                w: 0,
                h: 0,
            },
        };
        damage(&mut raw, changed);
        Ok(Self {
            raw,
            _pixels: PhantomData,
            _palette: PhantomData,
            _local: PhantomData,
        })
    }
    /// # Safety
    /// Same complete-publication contract as xrgb; the whole palette has at
    /// least256initialized colors and a truthful nonzero monotonic palette
    /// revision. Hold both whole buffers immutable through the frame loan.
    pub unsafe fn indexed(
        pixels: &'a [u8],
        palette: &'a [u32],
        width: u32,
        height: u32,
        stamp: Stamp,
        changed: Damage,
    ) -> Self {
        let mut raw = c::R4SdkPublishedFrameLease {
            pixels: span(pixels),
            palette: span(palette),
            binding_generation: stamp.binding_generation,
            revision: stamp.revision,
            palette_revision: stamp.palette_revision,
            damage_base_revision: 0,
            width,
            height,
            stride_bytes: width,
            format: 0,
            damage_kind: 0,
            flags: 1,
            reserved0: 0,
            reserved1: 0,
            damage: Rectangle {
                x: 0,
                y: 0,
                w: 0,
                h: 0,
            },
        };
        damage(&mut raw, changed);
        Self {
            raw,
            _pixels: PhantomData,
            _palette: PhantomData,
            _local: PhantomData,
        }
    }
}
#[derive(Clone, Copy, Default)]
pub struct CopyFeatures {
    pub indexed8: bool,
    pub xrgb32_nearest: bool,
}
/// The original callback descriptor/code/context and whole scratch stay
/// borrowed. Only synchronous copied-resource backends; !Send. Native opaque
/// storage remains MaybeUninit because original private padding is not data.
pub struct Bridge<'a> {
    raw: MaybeUninit<c::R4SdkPublishedFrameBridge>,
    _scratch: &'a mut [u32],
    _callbacks: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Bridge<'a> {
    pub fn new(
        callbacks: &'a Callbacks<'_, '_>,
        scratch: &'a mut [u32],
        features: CopyFeatures,
    ) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        let flags = features.indexed8 as u32 | ((features.xrgb32_nearest as u32) << 1);
        exact(unsafe {
            c::R4SdkPublishedFrameInit(
                callbacks.native(),
                scratch.as_mut_ptr(),
                scratch.len() as u64,
                flags,
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw,
            _scratch: scratch,
            _callbacks: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn bind(&mut self, generation: u64) -> Result<(), Error> {
        exact(unsafe { c::R4SdkPublishedFrameBind(self.raw.as_mut_ptr(), generation) })
    }
    pub fn pause(&mut self, paused: bool) -> Result<(), Error> {
        exact(unsafe { c::R4SdkPublishedFramePause(self.raw.as_mut_ptr(), paused as u32) })
    }
    pub fn close(&mut self) -> Result<(), Error> {
        exact(unsafe { c::R4SdkPublishedFrameClose(self.raw.as_mut_ptr()) })
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkPublishedFrameGetProgress(self.raw.as_ptr(), out.as_mut_ptr()) })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn sync<'b, 'source>(
        &'b mut self,
        published: Published<'source>,
    ) -> Result<Frame<'b, 'source, 'a>, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkPublishedFrameSync(self.raw.as_mut_ptr(), published.raw, out.as_mut_ptr())
        })?;
        Ok(Frame {
            bridge: self,
            _published: published,
            acquisition: unsafe { out.assume_init() },
        })
    }
}
impl Drop for Bridge<'_> {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkPublishedFrameClose(self.raw.as_mut_ptr()) };
    }
}
/// Only this scoped ticket can present. It borrows Bridge and both whole
/// immutable producer buffers; Drop detaches the actual Presenter first.
/// Forgetting a Frame leaves the owner Busy until close, and exposes no safe
/// way to render its stale source. No physical GPU/PPU/DMA fence receipt.
pub struct Frame<'b, 'source, 'owner> {
    bridge: &'b mut Bridge<'owner>,
    _published: Published<'source>,
    acquisition: c::R4SdkPublishedFrameAcquisition,
}
impl Frame<'_, '_, '_> {
    pub fn updated(&self) -> bool {
        self.acquisition.kind == 1
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        self.bridge.progress()
    }
    pub fn present(&mut self, width: i32, height: i32) -> Result<Presentation, Error> {
        let mut out = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkPublishedFramePresent(
                self.bridge.raw.as_mut_ptr(),
                self.acquisition.ticket,
                width,
                height,
                out.as_mut_ptr(),
            )
        })?;
        Ok(unsafe { out.assume_init() })
    }
}
impl Drop for Frame<'_, '_, '_> {
    fn drop(&mut self) {
        let _ = unsafe {
            c::R4SdkPublishedFrameRelease(self.bridge.raw.as_mut_ptr(), self.acquisition.ticket)
        };
    }
}
