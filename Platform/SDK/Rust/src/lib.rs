#![no_std]
//! Normal R4X runtime and borrowed SDK facades. Layouts, callbacks and constants
//! come from the matched Contract crate. `alloc` is optional; panic aborts.

use core::sync::atomic::{AtomicU64, Ordering};
use core::{ffi::CStr, mem};
pub use r4os_contract as abi;
pub mod app2;
pub use app2::App as App2;
pub use app2::App;
pub mod audio_capture;
pub mod audio_write;
pub mod bounded_text;
pub mod byte_pipe;
pub mod c_facades;
pub mod cli;
pub mod clipboard_offer;
pub mod data;
pub mod device_snapshot;
pub mod directory_page;
pub mod driver;
pub mod file_picker;
pub mod graphics;
pub mod gui;
pub mod heap;
pub mod inventory;
pub mod launch_io;
pub mod lowlevel;
mod memory;
pub mod metadata2;
pub mod network;
pub mod network_family;
#[path = "generated/network.rs"]
mod network_methods;
pub mod path;
pub mod pcm_source;
pub mod physical_storage;
pub mod platform;
pub mod platform2;
pub mod protocol;
pub mod published_frame;
pub mod r4l;
pub mod registry_diagnostics;
pub mod registry_hive;
pub mod resources;
pub mod serial;
pub mod services;
mod startup;
pub mod storage;
pub mod technical2;
pub mod text_composition;
pub mod text_metrics;
pub mod time;
pub mod transfer;
pub mod update;
pub mod wait_set;
pub mod web;
pub mod wire;
pub use app2::{ImportSpec, StartupInfo};

// Resident callbacks survive worker calls without a root App/context loan.
static PANIC_WRITE: AtomicU64 = AtomicU64::new(0);
static PANIC_EXIT: AtomicU64 = AtomicU64::new(0);
pub(crate) fn bind_panic_callbacks(write: u64, exit: u64) {
    PANIC_WRITE.store(write, Ordering::Release);
    PANIC_EXIT.store(exit, Ordering::Release);
}
pub(crate) fn clear_panic_callbacks() {
    PANIC_WRITE.store(0, Ordering::Release);
    PANIC_EXIT.store(0, Ordering::Release);
}

fn facade_app(app: &App<'_>) -> storage::Result<c_facades::R4App> {
    let mut value = unsafe { mem::zeroed() };
    let rc = unsafe { c_facades::R4SdkAppFacade2(app.native_context(), &app.memory, &mut value) };
    if rc == 0 {
        Ok(value)
    } else {
        Err(storage::Error::Raw(rc))
    }
}

impl<'a> App<'a> {
    pub fn drive_info_geometry(&self, index: u32) -> Option<abi::DriveInfo> {
        let address = self.sys_slot(mem::offset_of!(
            abi::generation2::R4XStartR4Sys2,
            drive_info_geometry
        ))?;
        let function: abi::R4SysFns::drive_info_geometry = unsafe { mem::transmute(address) };
        let mut out = abi::DriveInfo::default();
        (unsafe { function(index, &mut out) } > 0).then_some(out)
    }

    pub fn directory_batch(
        &self,
        path: &core::ffi::CStr,
        cursor: &mut abi::DirectoryBatchCursor,
        out: &mut [abi::DirectoryBatchEntry],
    ) -> Option<i32> {
        let address = self.sys_slot(mem::offset_of!(
            abi::generation2::R4XStartR4Sys2,
            directory_batch
        ))?;
        let function: abi::R4SysFns::directory_batch = unsafe { mem::transmute(address) };
        let capacity = u32::try_from(out.len()).ok()?;
        Some(unsafe {
            function(
                path.as_ptr().cast(),
                cursor,
                if out.is_empty() {
                    core::ptr::null_mut()
                } else {
                    out.as_mut_ptr()
                },
                capacity,
            )
        })
    }

    pub fn window_info(&self) -> Result<abi::GuiWindowInfo, i32> {
        let f: abi::R4DeskFns::gui_window_info = unsafe {
            mem::transmute(
                self.desk_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Desk2,
                    gui_window_info
                ))
                .ok_or(-2)?,
            )
        };
        let mut info = abi::GuiWindowInfo::default();
        let rc = unsafe { f(&mut info) };
        if rc < 0 || info.window_id < 0 {
            Err(if rc < 0 { rc } else { -3 })
        } else {
            Ok(info)
        }
    }

    pub fn set_title(&self, title: &CStr) -> Result<(), i32> {
        let f: abi::R4DeskFns::gui_set_title = unsafe {
            mem::transmute(
                self.desk_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Desk2,
                    gui_set_title
                ))
                .ok_or(-2)?,
            )
        };
        check(unsafe { f(title.as_ptr().cast()) })
    }

    pub fn clear(&self, color: u32) -> Result<(), i32> {
        let f: abi::R4DrawFns::gui_clear = unsafe {
            mem::transmute(
                self.draw_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Draw2,
                    gui_clear
                ))
                .ok_or(-2)?,
            )
        };
        check(unsafe { f(color) })
    }

    pub fn text(
        &self,
        x: i32,
        y: i32,
        text: &CStr,
        color: u32,
        background: u32,
    ) -> Result<(), i32> {
        let f: abi::R4DrawFns::gui_draw_text = unsafe {
            mem::transmute(
                self.draw_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Draw2,
                    gui_draw_text
                ))
                .ok_or(-2)?,
            )
        };
        check(unsafe { f(x, y, text.as_ptr().cast(), color, background) })
    }

    pub fn present(&self) -> Result<(), i32> {
        let f: abi::R4DrawFns::gui_present = unsafe {
            mem::transmute(
                self.draw_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Draw2,
                    gui_present
                ))
                .ok_or(-2)?,
            )
        };
        check(unsafe { f() })
    }

    pub fn poll_event(&self) -> Result<Option<abi::GuiEvent>, i32> {
        let f: abi::R4DeskFns::gui_poll_event = unsafe {
            mem::transmute(
                self.desk_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Desk2,
                    gui_poll_event
                ))
                .ok_or(-2)?,
            )
        };
        let mut event = abi::GuiEvent::default();
        let rc = unsafe { f(&mut event) };
        if rc < 0 {
            Err(rc)
        } else if rc == 0 {
            Ok(None)
        } else {
            Ok(Some(event))
        }
    }

    pub fn wait_event(&self, ticks: u64) -> Result<Option<abi::GuiEvent>, i32> {
        if let Some(event) = self.poll_event()? {
            return Ok(Some(event));
        }
        self.sleep(ticks.max(1));
        self.poll_event()
    }

    pub fn register_service(&self) -> Result<Service<'_, 'a>, i32> {
        if self.start_context().app_class != abi::R4XStartAppClass::service.0 {
            return Err(-1);
        }
        let f: abi::R4SysFns::service_endpoint_register = unsafe {
            mem::transmute(
                self.sys_slot(mem::offset_of!(
                    abi::generation2::R4XStartR4Sys2,
                    service_endpoint_register
                ))
                .ok_or(-2)?,
            )
        };
        let mut info = abi::ServiceInfo::default();
        let rc = unsafe { f(self.name().as_ptr().cast(), 0, &mut info) };
        if rc < 0 || info.handle == 0 {
            return Err(if rc < 0 { rc } else { -3 });
        }
        Ok(Service {
            app: self,
            handle: info.handle,
        })
    }

    fn sys_slot(&self, offset: usize) -> Option<usize> {
        self.context()
            .lookup(1, u32::try_from(offset).ok()?)
            .ok()
            .map(|v| v as usize)
    }

    fn desk_slot(&self, offset: usize) -> Option<usize> {
        self.context()
            .lookup(2, u32::try_from(offset).ok()?)
            .ok()
            .map(|v| v as usize)
    }

    fn draw_slot(&self, offset: usize) -> Option<usize> {
        self.context()
            .lookup(3, u32::try_from(offset).ok()?)
            .ok()
            .map(|v| v as usize)
    }

    pub fn imports(&self) -> &[abi::R4XStartImport] {
        self.context().imports()
    }

    pub fn system_api(&self) -> Option<&abi::generation2::R4XStartR4Sys2> {
        let address = self.context().group(1)?;
        Some(unsafe { &*(address as *const abi::generation2::R4XStartR4Sys2) })
    }

    pub fn desktop_api(&self) -> Option<&abi::generation2::R4XStartR4Desk2> {
        let address = self.context().group(2)?;
        Some(unsafe { &*(address as *const abi::generation2::R4XStartR4Desk2) })
    }

    pub fn drawing_api(&self) -> Option<&abi::generation2::R4XStartR4Draw2> {
        let address = self.context().group(3)?;
        Some(unsafe { &*(address as *const abi::generation2::R4XStartR4Draw2) })
    }

    pub fn network_api(&self) -> Option<&abi::generation2::R4XStartR4Net2> {
        let address = self.context().group(4)?;
        Some(unsafe { &*(address as *const abi::generation2::R4XStartR4Net2) })
    }

    pub fn audio_api(&self) -> Option<&abi::generation2::R4XStartR4Audio2> {
        let address = self.context().group(5)?;
        Some(unsafe { &*(address as *const abi::generation2::R4XStartR4Audio2) })
    }

    pub fn device_api(&self) -> Option<&abi::generation2::R4XStartR4Dev2> {
        let address = self.context().group(6)?;
        Some(unsafe { &*(address as *const abi::generation2::R4XStartR4Dev2) })
    }
}

pub struct Service<'a, 'context> {
    app: &'a App<'context>,
    handle: u32,
}
impl Service<'_, '_> {
    pub fn handle(&self) -> u32 {
        self.handle
    }
    pub fn wait(&self, ticks: u64) -> Result<(), i32> {
        let f: abi::R4SysFns::service_endpoint_wait = unsafe {
            mem::transmute(
                self.app
                    .sys_slot(mem::offset_of!(
                        abi::generation2::R4XStartR4Sys2,
                        service_endpoint_wait
                    ))
                    .ok_or(-2)?,
            )
        };
        let rc = unsafe { f(self.handle, ticks.max(1)) };
        if rc == abi::service_api_result_timeout {
            Ok(())
        } else {
            check(rc)
        }
    }
    pub fn receive(&self, header: &mut abi::ServiceMessageHeader, data: &mut [u8]) -> i32 {
        let Some(address) = self.app.sys_slot(mem::offset_of!(
            abi::generation2::R4XStartR4Sys2,
            service_endpoint_recv
        )) else {
            return -2;
        };
        if data.len() > u32::MAX as usize {
            return -1;
        }
        let f: abi::R4SysFns::service_endpoint_recv = unsafe { mem::transmute(address) };
        unsafe { f(self.handle, header, data.as_mut_ptr(), data.len() as u32) }
    }
    pub fn reply(&self, request: u32, status: i32, data: &[u8]) -> i32 {
        let Some(address) = self.app.sys_slot(mem::offset_of!(
            abi::generation2::R4XStartR4Sys2,
            service_endpoint_reply
        )) else {
            return -2;
        };
        if data.len() > u32::MAX as usize {
            return -1;
        }
        let f: abi::R4SysFns::service_endpoint_reply = unsafe { mem::transmute(address) };
        unsafe {
            f(
                self.handle,
                request,
                status,
                data.as_ptr(),
                data.len() as u32,
            )
        }
    }
    /// Clear the handle after unregister or acknowledgement that it is retired.
    pub fn close(&mut self) -> Result<(), i32> {
        let rc = self.unregister();
        // The service owner may retire this exact endpoint before waking Stop.
        if rc >= 0 || rc == abi::service_api_result_bad_handle {
            self.handle = 0;
            Ok(())
        } else {
            Err(rc)
        }
    }
    fn unregister(&self) -> i32 {
        let Some(address) = self.app.sys_slot(mem::offset_of!(
            abi::generation2::R4XStartR4Sys2,
            service_endpoint_unregister
        )) else {
            return -2;
        };
        let f: abi::R4SysFns::service_endpoint_unregister = unsafe { mem::transmute(address) };
        unsafe { f(self.handle) }
    }
}
impl Drop for Service<'_, '_> {
    fn drop(&mut self) {
        if self.handle != 0 {
            let _ = self.unregister();
        }
    }
}
fn check(rc: i32) -> Result<(), i32> {
    if rc < 0 { Err(rc) } else { Ok(()) }
}
/// # Safety
/// Called only by the SDK entry macro under the loader's R4XStart contract.
/// Platform providers must remain resident until all tasks of this exact
/// instance retire. Optional alloc retains only that provider identity across
/// workers, never a root App/Context loan.
#[doc(hidden)]
pub unsafe fn start(
    raw: *const abi::generation2::R4XStartContext2,
    expected: &StartupInfo<'_>,
    name: &'static CStr,
    main: fn(&mut App<'_>) -> i32,
) -> i32 {
    unsafe { app2::start(raw, expected, name, main) }
}

#[cfg(target_os = "none")]
#[panic_handler]
fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
    struct Writer(Option<abi::R4SysFns::write>);
    impl core::fmt::Write for Writer {
        fn write_str(&mut self, text: &str) -> core::fmt::Result {
            let write = self.0.ok_or(core::fmt::Error)?;
            let length = u32::try_from(text.len()).map_err(|_| core::fmt::Error)?;
            if unsafe { write(text.as_ptr(), length) } < 0 {
                Err(core::fmt::Error)
            } else {
                Ok(())
            }
        }
    }
    let address = PANIC_WRITE.load(Ordering::Acquire);
    let write = if address == 0 {
        None
    } else {
        Some(unsafe { mem::transmute::<u64, abi::R4SysFns::write>(address) })
    };
    let _ = core::fmt::write(&mut Writer(write), format_args!("[RUST] panic: {}\n", info));
    let address = PANIC_EXIT.load(Ordering::Acquire);
    if address != 0 {
        let exit: abi::R4SysFns::program_exit = unsafe { mem::transmute(address) };
        let _ = unsafe { exit(-101, abi::program_exit_reason_failed as u32) };
    }
    // Missing/rejected terminal calls fault the actual module. Never unwind
    // across a native boundary or park a corrupt process in an idle loop.
    unsafe { core::arch::asm!("ud2", options(noreturn)) }
}

#[macro_export]
macro_rules! app {
    ($main:path) => {
        $crate::app2!($main);
    };
}

const _: () = {
    assert!(
        mem::offset_of!(abi::generation2::R4XStartR4Sys2, magic)
            == mem::offset_of!(abi::generation2::R4XStartR4Desk2, magic)
    );
    assert!(
        mem::offset_of!(abi::generation2::R4XStartR4Sys2, abi_version)
            == mem::offset_of!(abi::generation2::R4XStartR4Draw2, abi_version)
    );
    assert!(
        mem::offset_of!(abi::generation2::R4XStartR4Sys2, size)
            == mem::offset_of!(abi::generation2::R4XStartR4Desk2, size)
    );
    assert!(
        mem::offset_of!(abi::generation2::R4XStartR4Sys2, size)
            == mem::offset_of!(abi::generation2::R4XStartR4Draw2, size)
    );
};

pub mod subsystems;
