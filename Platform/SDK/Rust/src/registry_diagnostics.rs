//! Existing private-image registry diagnostic backup/restore policy. Serialize
//! the diagnostic and retain the exact admitted paths until restoration ends.
use crate::{c_facades as c, path::FilePath, storage::System};
pub struct Paths<'a> {
    pub hive: &'a FilePath,
    pub tmp: &'a FilePath,
    pub bak: &'a FilePath,
    pub original: &'a FilePath,
    pub stage: &'a FilePath,
    pub displaced: &'a FilePath,
}
impl Paths<'_> {
    fn raw(&self) -> c::R4RegistryTestPaths {
        c::R4RegistryTestPaths {
            hive: self.hive.as_c_str().as_ptr().cast(),
            tmp: self.tmp.as_c_str().as_ptr().cast(),
            bak: self.bak.as_c_str().as_ptr().cast(),
            original: self.original.as_c_str().as_ptr().cast(),
            stage: self.stage.as_c_str().as_ptr().cast(),
            displaced: self.displaced.as_c_str().as_ptr().cast(),
        }
    }
}
pub fn private_image(system: &System<'_>) -> bool {
    unsafe {
        c::R4SdkRegistrySelfTest(
            system.raw(),
            0,
            core::ptr::null(),
            0,
            core::ptr::null_mut(),
            0,
            core::ptr::null_mut(),
            0,
        ) == 1
    }
}
pub fn backup(
    system: &System<'_>,
    paths: &Paths<'_>,
    original: &mut [u8],
    check: &mut [u8],
) -> Option<bool> {
    match unsafe {
        c::R4SdkRegistrySelfTest(
            system.raw(),
            1,
            &paths.raw(),
            0,
            original.as_mut_ptr(),
            original.len() as u64,
            check.as_mut_ptr(),
            check.len() as u64,
        )
    } {
        0 => Some(false),
        1 => Some(true),
        _ => None,
    }
}
pub fn restore(
    system: &System<'_>,
    paths: &Paths<'_>,
    had_original: bool,
    original: &mut [u8],
    check: &mut [u8],
) -> bool {
    unsafe {
        c::R4SdkRegistrySelfTest(
            system.raw(),
            2,
            &paths.raw(),
            i32::from(had_original),
            original.as_mut_ptr(),
            original.len() as u64,
            check.as_mut_ptr(),
            check.len() as u64,
        ) == 1
    }
}
