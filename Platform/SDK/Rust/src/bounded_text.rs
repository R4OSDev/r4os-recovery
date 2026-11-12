//! Exact UTF8 buffers and presentation-only grapheme truncation from R4STD.
use crate::c_facades as c;
pub fn valid(bytes: &[u8]) -> bool {
    unsafe { c::R4SdkTextValid(bytes.as_ptr(), bytes.len() as u64) != 0 }
}
pub fn assign_z(out: &mut [u8], bytes: &[u8]) -> bool {
    unsafe {
        c::R4SdkTextAssign(
            out.as_mut_ptr(),
            out.len() as u64,
            bytes.as_ptr(),
            bytes.len() as u64,
        ) != 0
    }
}
pub fn label_z(out: &mut [u8], bytes: &[u8]) -> bool {
    unsafe {
        c::R4SdkTextLabel(
            out.as_mut_ptr(),
            out.len() as u64,
            bytes.as_ptr(),
            bytes.len() as u64,
        ) != 0
    }
}
pub fn load_prefix(bytes: &[u8], capacity: usize, truncated: bool) -> Option<usize> {
    let mut n = 0;
    if unsafe {
        c::R4SdkTextPrefix(
            bytes.as_ptr(),
            bytes.len() as u64,
            capacity as u64,
            i32::from(truncated),
            &mut n,
        )
    } != 0
    {
        Some(n as usize)
    } else {
        None
    }
}
/// The next current R4STD extended-grapheme byte boundary. Offsets clamp
/// to length; invalid UTF8 returns None. No display-width or normalization.
pub fn next_boundary(bytes: &[u8], offset: usize) -> Option<usize> {
    let mut out = 0;
    (unsafe { c::R4SdkTextNext(bytes.as_ptr(), bytes.len() as u64, offset as u64, &mut out) } != 0)
        .then_some(out as usize)
}
/// The previous boundary from that same original owner and byte contract.
pub fn previous_boundary(bytes: &[u8], offset: usize) -> Option<usize> {
    let mut out = 0;
    (unsafe { c::R4SdkTextPrevious(bytes.as_ptr(), bytes.len() as u64, offset as u64, &mut out) }
        != 0)
        .then_some(out as usize)
}
