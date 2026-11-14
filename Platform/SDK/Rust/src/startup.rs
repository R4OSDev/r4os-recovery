//! Shared bounded import-name comparison. App2 owns start admission.
pub(crate) unsafe fn name_equals(address: u64, expected: &[u8]) -> bool {
    if address == 0 || expected.is_empty() || expected.len() > 31 {
        return false;
    }
    let p = address as *const u8;
    for (index, byte) in expected.iter().enumerate() {
        if !unsafe { *p.add(index) }.eq_ignore_ascii_case(byte) {
            return false;
        }
    }
    unsafe { *p.add(expected.len()) == 0 }
}
