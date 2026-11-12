//! Shared native GUI owners. No widget, Unicode, shape or raster algorithm is
//! reimplemented here. `raw` exposes the complete compiler-typed C boundary;
//! its native storage must be held in `MaybeUninit`, never read as byte data.
use crate::{
    c_facades as c,
    storage::{Error, Result},
};
pub mod raw {
    pub use crate::c_facades::*;
}
mod input;
mod session;
mod style;
mod text;
pub use input::InputQueue;
pub use session::{Event, Paint, PreparedTextPaint, Role, Session, SessionStorage, TimerStorage};
pub use style::{ButtonState, Style};
pub use text::{TextArea, TextField, TextFieldMode};
/// Semantic events from the shared loop; distinct from raw GuiEventKind.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum EventKind {
    Close = c::R4SdkGuiEventKind_close,
    Resize = c::R4SdkGuiEventKind_resize,
    Key = c::R4SdkGuiEventKind_key,
    MouseDown = c::R4SdkGuiEventKind_mouse_down,
    MouseUp = c::R4SdkGuiEventKind_mouse_up,
    MouseMove = c::R4SdkGuiEventKind_mouse_move,
    Command = c::R4SdkGuiEventKind_command,
    Clipboard = c::R4SdkGuiEventKind_clipboard,
    Timer = c::R4SdkGuiEventKind_timer,
    Unknown = c::R4SdkGuiEventKind_unknown,
    FocusGained = c::R4SdkGuiEventKind_focus_gained,
    FocusLost = c::R4SdkGuiEventKind_focus_lost,
    FontChanged = c::R4SdkGuiEventKind_font_changed,
    MouseWheel = c::R4SdkGuiEventKind_wheel,
    MouseRelative = c::R4SdkGuiEventKind_relative,
    PointerCapture = c::R4SdkGuiEventKind_pointer_capture,
    InputReset = c::R4SdkGuiEventKind_input_reset,
}
impl Event {
    pub fn kind(&self) -> Option<EventKind> {
        Some(match self.kind {
            c::R4SdkGuiEventKind_close => EventKind::Close,
            c::R4SdkGuiEventKind_resize => EventKind::Resize,
            c::R4SdkGuiEventKind_key => EventKind::Key,
            c::R4SdkGuiEventKind_mouse_down => EventKind::MouseDown,
            c::R4SdkGuiEventKind_mouse_up => EventKind::MouseUp,
            c::R4SdkGuiEventKind_mouse_move => EventKind::MouseMove,
            c::R4SdkGuiEventKind_command => EventKind::Command,
            c::R4SdkGuiEventKind_clipboard => EventKind::Clipboard,
            c::R4SdkGuiEventKind_timer => EventKind::Timer,
            c::R4SdkGuiEventKind_unknown => EventKind::Unknown,
            c::R4SdkGuiEventKind_focus_gained => EventKind::FocusGained,
            c::R4SdkGuiEventKind_focus_lost => EventKind::FocusLost,
            c::R4SdkGuiEventKind_font_changed => EventKind::FontChanged,
            c::R4SdkGuiEventKind_wheel => EventKind::MouseWheel,
            c::R4SdkGuiEventKind_relative => EventKind::MouseRelative,
            c::R4SdkGuiEventKind_pointer_capture => EventKind::PointerCapture,
            c::R4SdkGuiEventKind_input_reset => EventKind::InputReset,
            _ => return None,
        })
    }
}

fn slot(value: c::R4SdkGuiSlot) -> Result<c::R4SdkGuiSlot> {
    if value.status < 0 {
        Err(Error::Raw(value.status))
    } else if value.flags & 2 != 0 {
        Err(Error::InvalidProvider)
    } else {
        Ok(value)
    }
}
fn code(value: c::R4SdkGuiSlot) -> Result<i32> {
    let rc = slot(value)?.bits as i32;
    if rc < 0 { Err(Error::Raw(rc)) } else { Ok(rc) }
}
fn boolean(value: c::R4SdkGuiSlot) -> Result<bool> {
    Ok(slot(value)?.bits != 0)
}
fn exact(value: i32) -> Result<()> {
    if value == 0 {
        Ok(())
    } else {
        Err(Error::Raw(value))
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rect {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}
impl Rect {
    fn native(self) -> Result<core::mem::MaybeUninit<c::R4SdkGuiRect>> {
        if self.x.checked_add(self.width).is_none() || self.y.checked_add(self.height).is_none() {
            return Err(Error::Length);
        }
        let mut out = core::mem::MaybeUninit::uninit();
        slot(unsafe {
            c::R4SdkGuiRect_from_fields(out.as_mut_ptr(), self.x, self.y, self.width, self.height)
        })?;
        Ok(out)
    }
}
