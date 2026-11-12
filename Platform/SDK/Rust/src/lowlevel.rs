//! Explicit raw R4X entry. Original context/ABI and caller-owned resources;
//! no normal App main invocation or implicit entropy/heap initialization.
pub use crate::abi as contract;
use crate::{App, StartupInfo, abi};
use core::{ffi::CStr, mem};
pub type Context<'a> = App<'a>;
/// # Safety
/// Called only from the exact current loader entry. All admitted context and
/// table bytes stay immutable/resident until every instance task has retired.
#[doc(hidden)]
pub unsafe fn invoke(
    raw: *const abi::R4XStartContext,
    expected: &StartupInfo<'_>,
    name: &'static CStr,
    entry: unsafe extern "C" fn(*const abi::R4XStartContext) -> i32,
) -> i32 {
    let view = match unsafe { App::from_raw(raw, expected, name) } {
        Ok(v) => v,
        Err(e) => return e,
    };
    crate::bind_panic_callbacks(
        view.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, write))
            .unwrap_or(0) as u64,
        view.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, program_exit))
            .unwrap_or(0) as u64,
    );
    let code = unsafe { entry(raw) };
    crate::clear_panic_callbacks();
    code
}
/// Explicit initialization for users choosing SDK entropy/global allocation.
/// The same original instance owner retains heap/task cleanup on process exit.
pub fn initialize_runtime(view: &Context<'_>) -> Result<(), i32> {
    let status = unsafe { crate::c_facades::R4SdkBindProgramEntropy(view.start_context()) };
    if status < 0 {
        return Err(status);
    }
    #[cfg(all(feature = "alloc", target_os = "none"))]
    crate::heap::install(view).map_err(|_| -17)?;
    Ok(())
}
/// Emits the real R4XStart symbol. The callback receives the raw loader context;
/// admission/panic scope are shared infrastructure, no App-main adapter runs.
#[macro_export]
macro_rules! lowlevel_entry {
    ($entry:path) => {
        const _: unsafe extern "C" fn(*const $crate::abi::R4XStartContext) -> i32 = $entry;
        #[unsafe(no_mangle)]
        #[unsafe(link_section = ".text.r4xstart_entry")]
        pub unsafe extern "C" fn R4XStart(raw: *const $crate::abi::R4XStartContext) -> i32 {
            use $crate as __r4os_startup;
            let expected = include!(env!("R4OS_STARTUP_INFO_FILE"));
            unsafe {
                $crate::lowlevel::invoke(
                    raw,
                    &expected,
                    core::ffi::CStr::from_bytes_with_nul_unchecked(
                        concat!(env!("R4OS_MODULE_NAME"), "\0").as_bytes(),
                    ),
                    $entry,
                )
            }
        }
    };
}
/// A checked view for explicitly chosen helpers; it does not initialize a heap,
/// bind entropy, create a window or call an application main function.
#[macro_export]
macro_rules! lowlevel_context {
    ($raw:expr) => {{
        use $crate as __r4os_startup;
        let expected = include!(env!("R4OS_STARTUP_INFO_FILE"));
        $crate::App::from_raw(
            $raw,
            &expected,
            core::ffi::CStr::from_bytes_with_nul_unchecked(
                concat!(env!("R4OS_MODULE_NAME"), "\0").as_bytes(),
            ),
        )
    }};
}

/// Explicitly install the existing generation2 global heap. Checked App2
/// admission already binds its SDK callback/entropy scope; no old table is used.
pub fn initialize_runtime2(view: &crate::App2<'_>) -> Result<(), i32> {
    #[cfg(all(feature = "alloc", target_os = "none"))]
    crate::heap::install2(view).map_err(|_| -17)?;
    #[cfg(not(all(feature = "alloc", target_os = "none")))]
    let _ = view;
    Ok(())
}

/// Explicit SDK-helper view of an already admitted raw generation2 context.
/// App2 construction binds SDK callback/entropy scope; allocation remains an
/// explicit initialize_runtime2 choice. The original raw entry stays unchanged.
#[macro_export]
macro_rules! lowlevel_context2 {
    ($context:expr) => {{
        $crate::App2::from_context($context, unsafe {
            core::ffi::CStr::from_bytes_with_nul_unchecked(
                concat!(env!("R4OS_MODULE_NAME"), "\0").as_bytes(),
            )
        })
    }};
}
