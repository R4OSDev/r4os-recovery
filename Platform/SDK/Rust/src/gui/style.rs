//! Application-local values; all drawing and layout still execute in Zig.
use super::{Session, c, slot};
use crate::storage::Result;
use core::mem::MaybeUninit;

pub struct Style {
    pub(super) native: MaybeUninit<c::R4SdkGuiStyle>,
}
impl Style {
    pub fn light() -> Result<Self> {
        Self::create(false)
    }
    pub fn dark() -> Result<Self> {
        Self::create(true)
    }
    fn create(dark: bool) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        slot(unsafe {
            if dark {
                c::R4SdkGuiStyle_dark(0, native.as_mut_ptr())
            } else {
                c::R4SdkGuiStyle_light(0, native.as_mut_ptr())
            }
        })?;
        Ok(Self { native })
    }
    /// Select current renderable system font IDs again after FontChanged.
    /// The value retains no window/context pointer or lifetime ownership.
    pub fn for_window(window: &mut Session<'_, '_>, dark: bool) -> Result<Self> {
        let base = Self::create(dark)?;
        let mut native = MaybeUninit::uninit();
        slot(unsafe {
            c::R4SdkGuiStyle_withSystemFonts(
                0,
                base.native.as_ptr(),
                window.native_draw(),
                native.as_mut_ptr(),
            )
        })?;
        Ok(Self { native })
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum ButtonState {
    Normal = c::R4SdkGuiButtonState_normal,
    Hover = c::R4SdkGuiButtonState_hover,
    Pressed = c::R4SdkGuiButtonState_pressed,
    Disabled = c::R4SdkGuiButtonState_disabled,
}
