//! Reuse the C tray owner, including exact process identity and epoch changes.
use super::{Error, Result, Services, Timeout, c};
use crate::abi;
pub type TrayCall = c::R4TrayCallResult;
pub struct TrayItem<'a> {
    pub id: u64,
    pub revision: u64,
    pub flags: u32,
    pub status_flags: u32,
    pub tooltip: &'a str,
    pub icon: &'a [u32],
}
pub struct Tray<'a> {
    raw: c::R4Tray,
    _owner: &'a Services<'a>,
}
impl<'a> Tray<'a> {
    pub(super) fn new(owner: &'a Services<'a>) -> Result<Self> {
        let mut raw = unsafe { core::mem::zeroed() };
        let rc = unsafe { c::r4_app_tray(owner.raw().app, &mut raw) };
        if rc != 0 {
            return Err(Error::Raw(rc));
        }
        Ok(Self { raw, _owner: owner })
    }
    pub fn owner(&self) -> abi::ProgramProcessHandle {
        self.raw.owner
    }
    pub fn desktop_epoch(&self) -> u64 {
        self.raw.desktop_epoch
    }
    pub fn status(&mut self, id: u64, timeout: Timeout) -> TrayCall {
        unsafe { c::r4_tray_status(&mut self.raw, id, timeout.raw()) }
    }
    pub fn upsert(&mut self, item: TrayItem<'_>, timeout: Timeout) -> Result<TrayCall> {
        if item.tooltip.len() > abi::tray_tooltip_bytes
            || item.icon.len() != abi::tray_icon_pixel_count
        {
            return Err(Error::Raw(abi::tray_result_bad_request));
        }
        let value = c::R4TrayItem {
            id: item.id,
            revision: item.revision,
            flags: item.flags,
            status_flags: item.status_flags,
            tooltip: item.tooltip.as_ptr(),
            tooltip_length: item.tooltip.len() as u16,
            icon: item.icon.as_ptr(),
        };
        Ok(unsafe { c::r4_tray_upsert(&mut self.raw, &value, timeout.raw()) })
    }
    pub fn remove(&mut self, id: u64, timeout: Timeout) -> TrayCall {
        unsafe { c::r4_tray_remove(&mut self.raw, id, timeout.raw()) }
    }
    /// Native server-side event budget is finite; Forever is rejected by the
    /// shared owner. The response retains sequence/epoch/result separately.
    pub fn wait_event(&mut self, after: u64, timeout: Timeout) -> TrayCall {
        unsafe { c::r4_tray_wait_event(&mut self.raw, after, timeout.raw()) }
    }
}
