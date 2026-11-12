#![no_std]
//! Normal R4X runtime and borrowed SDK facades. Layouts, callbacks and constants
//! come from the matched Contract crate. `alloc` is optional; panic aborts.

use core::sync::atomic::{AtomicU64, Ordering};
use core::{ffi::CStr, marker::PhantomData, mem, ptr};
pub use r4os_contract as abi;
pub mod app2;
pub use app2::App as App2;
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
pub use startup::{ImportSpec, StartupInfo};

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
    let rc = unsafe { c_facades::R4SdkAppFacade(app.start_context(), &mut value) };
    if rc == 0 {
        Ok(value)
    } else {
        Err(storage::Error::Raw(rc))
    }
}

pub struct App<'a> {
    context: &'a abi::R4XStartContext,
    name: &'static CStr,
    // These helpers belong to this executing instance, not to another thread.
    _local: PhantomData<*mut ()>,
}

impl<'a> App<'a> {
    /// # Safety
    /// `raw` and the loader-owned imports/tables must remain resident for the
    /// exact R4X call. Provider tables must honor their immutable ABI, including
    /// the complete readable header/slot range. The entry macro receives that
    /// loader guarantee and supplies manifest-derived facts.
    pub unsafe fn from_raw(
        raw: *const abi::R4XStartContext,
        expected: &StartupInfo<'_>,
        name: &'static CStr,
    ) -> Result<Self, i32> {
        let context = unsafe { startup::validate(raw, expected) }?;
        Ok(Self {
            context,
            name,
            _local: PhantomData,
        })
    }

    /// Immutable loader context, pinned until this exact entry returns.
    pub fn start_context(&self) -> &abi::R4XStartContext {
        self.context
    }

    pub fn imports(&self) -> &[abi::R4XStartImport] {
        unsafe { startup::entries(self.context) }
    }

    /// An unresolved optional provider remains an entry with a zero address.
    pub fn import(&self, module: &str, symbol: &str) -> Option<&abi::R4XStartImport> {
        self.imports().iter().find(|entry| unsafe {
            startup::name_equals(entry.module_name, module.as_bytes())
                && startup::name_equals(entry.symbol_name, symbol.as_bytes())
        })
    }

    pub fn name(&self) -> &'static CStr {
        self.name
    }
    pub fn instance_id(&self) -> u64 {
        self.context.instance_id
    }
    pub fn heap(&self) -> Result<heap::Heap<'_>, heap::Error> {
        heap::Heap::new(self)
    }
    pub fn args(&self) -> &[u8] {
        if self.context.args == 0 || self.context.args_len == 0 {
            return &[];
        }
        unsafe {
            core::slice::from_raw_parts(
                self.context.args as *const u8,
                self.context.args_len as usize,
            )
        }
    }
    pub fn write(&self, text: &str) -> i32 {
        if text.len() > u32::MAX as usize {
            return -1;
        }
        let Some(address) = self.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, write)) else {
            return -2;
        };
        let f: abi::R4SysFns::write = unsafe { mem::transmute(address) };
        unsafe { f(text.as_ptr(), text.len() as u32) }
    }
    pub fn sleep(&self, ticks: u64) {
        if let Some(address) = self.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, sleep_ticks)) {
            let f: abi::R4SysFns::sleep_ticks = unsafe { mem::transmute(address) };
            unsafe { f(ticks) };
        }
    }
    pub fn should_close(&self) -> bool {
        if self.context.flags & abi::r4xstart_flag_close_supported != 0
            && self.context.should_close != 0
        {
            let f: abi::R4XStartShouldCloseFn =
                unsafe { mem::transmute(self.context.should_close as usize) };
            return unsafe { f(self.context) != 0 };
        }
        if let Some(address) =
            self.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, program_should_close))
        {
            let f: abi::R4SysFns::program_should_close = unsafe { mem::transmute(address) };
            return unsafe { f() != 0 };
        }
        false
    }
    /// Mounted scalar geometry without invoking the potentially cold FREE query.
    /// Free fields remain unknown; no fallback to the full query.
    pub fn drive_info_geometry(&self, index: u32) -> Option<abi::DriveInfo> {
        let address = self.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, drive_info_geometry))?;
        let function: abi::R4SysFns::drive_info_geometry = unsafe { mem::transmute(address) };
        let mut out = abi::DriveInfo::default();
        (unsafe { function(index, &mut out) } > 0).then_some(out)
    }
    /// Complete directory records, or an empty slice to validate an existing
    /// bound scan without advancing. No kernel resources survive the call.
    pub fn directory_batch(
        &self,
        path: &core::ffi::CStr,
        cursor: &mut abi::DirectoryBatchCursor,
        out: &mut [abi::DirectoryBatchEntry],
    ) -> Option<i32> {
        let address = self.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, directory_batch))?;
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
    fn table_slot(
        &self,
        group: abi::R4LGroup,
        magic: u32,
        minimum: u32,
        offset: usize,
    ) -> Option<usize> {
        let entry = self.imports().iter().find(|e| e.group_id == group.0)?;
        if entry.flags & abi::r4xstart_import_flag_group_interface == 0 || entry.table == 0 {
            return None;
        }
        let base = entry.table as *const u8;
        // Header offsets are the canonical common prefix, asserted below.
        let actual_magic = unsafe {
            ptr::read_unaligned(
                base.add(mem::offset_of!(abi::R4XStartR4Sys, magic))
                    .cast::<u32>(),
            )
        };
        let version = unsafe {
            ptr::read_unaligned(
                base.add(mem::offset_of!(abi::R4XStartR4Sys, abi_version))
                    .cast::<u32>(),
            )
        };
        let size = unsafe {
            ptr::read_unaligned(
                base.add(mem::offset_of!(abi::R4XStartR4Sys, size))
                    .cast::<u32>(),
            )
        };
        if actual_magic != magic
            || version < minimum
            || (size as usize) < offset.checked_add(mem::size_of::<usize>())?
        {
            return None;
        }
        let value = unsafe { ptr::read_unaligned(base.add(offset).cast::<usize>()) };
        if value == 0 { None } else { Some(value) }
    }
    fn sys_slot(&self, offset: usize) -> Option<usize> {
        self.table_slot(
            abi::R4LGroup::r4sys,
            abi::r4xstart_r4sys_magic,
            abi::R4XStartR4Sys::default().abi_version,
            offset,
        )
    }
    fn desk_slot(&self, offset: usize) -> Option<usize> {
        self.table_slot(
            abi::R4LGroup::r4desk,
            abi::r4xstart_r4desk_magic,
            abi::R4XStartR4Desk::default().abi_version,
            offset,
        )
    }
    fn draw_slot(&self, offset: usize) -> Option<usize> {
        self.table_slot(
            abi::R4LGroup::r4draw,
            abi::r4xstart_r4draw_magic,
            abi::R4XStartR4Draw::default().abi_version,
            offset,
        )
    }

    pub fn system_api(&self) -> Option<&abi::R4XStartR4Sys> {
        unsafe {
            startup::table(
                self.context,
                abi::R4LGroup::r4sys,
                abi::r4xstart_r4sys_magic,
                abi::R4XStartR4Sys::default().abi_version,
            )
        }
    }
    pub fn desktop_api(&self) -> Option<&abi::R4XStartR4Desk> {
        unsafe {
            startup::table(
                self.context,
                abi::R4LGroup::r4desk,
                abi::r4xstart_r4desk_magic,
                abi::R4XStartR4Desk::default().abi_version,
            )
        }
    }
    pub fn drawing_api(&self) -> Option<&abi::R4XStartR4Draw> {
        unsafe {
            startup::table(
                self.context,
                abi::R4LGroup::r4draw,
                abi::r4xstart_r4draw_magic,
                abi::R4XStartR4Draw::default().abi_version,
            )
        }
    }
    pub fn network_api(&self) -> Option<&abi::R4XStartR4Net> {
        unsafe {
            startup::table(
                self.context,
                abi::R4LGroup::r4net,
                abi::r4xstart_r4net_magic,
                abi::R4XStartR4Net::default().abi_version,
            )
        }
    }
    pub fn audio_api(&self) -> Option<&abi::R4XStartR4Audio> {
        unsafe {
            startup::table(
                self.context,
                abi::R4LGroup::r4audio,
                abi::r4xstart_r4audio_magic,
                abi::R4XStartR4Audio::default().abi_version,
            )
        }
    }
    pub fn device_api(&self) -> Option<&abi::R4XStartR4Dev> {
        unsafe {
            startup::table(
                self.context,
                abi::R4LGroup::r4dev,
                abi::r4xstart_r4dev_magic,
                abi::R4XStartR4Dev::default().abi_version,
            )
        }
    }

    /// The regular R4OS host creates/binds the GUI window before R4XStart.
    pub fn window_info(&self) -> Result<abi::GuiWindowInfo, i32> {
        let f: abi::R4DeskFns::gui_window_info = unsafe {
            mem::transmute(
                self.desk_slot(mem::offset_of!(abi::R4XStartR4Desk, gui_window_info))
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
                self.desk_slot(mem::offset_of!(abi::R4XStartR4Desk, gui_set_title))
                    .ok_or(-2)?,
            )
        };
        check(unsafe { f(title.as_ptr().cast()) })
    }
    pub fn clear(&self, color: u32) -> Result<(), i32> {
        let f: abi::R4DrawFns::gui_clear = unsafe {
            mem::transmute(
                self.draw_slot(mem::offset_of!(abi::R4XStartR4Draw, gui_clear))
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
                self.draw_slot(mem::offset_of!(abi::R4XStartR4Draw, gui_draw_text))
                    .ok_or(-2)?,
            )
        };
        check(unsafe { f(x, y, text.as_ptr().cast(), color, background) })
    }
    pub fn present(&self) -> Result<(), i32> {
        let f: abi::R4DrawFns::gui_present = unsafe {
            mem::transmute(
                self.draw_slot(mem::offset_of!(abi::R4XStartR4Draw, gui_present))
                    .ok_or(-2)?,
            )
        };
        check(unsafe { f() })
    }
    pub fn poll_event(&self) -> Result<Option<abi::GuiEvent>, i32> {
        let f: abi::R4DeskFns::gui_poll_event = unsafe {
            mem::transmute(
                self.desk_slot(mem::offset_of!(abi::R4XStartR4Desk, gui_poll_event))
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
    /// A bounded event wait leaves the scheduler ready list while idle.
    pub fn wait_event(&self, ticks: u64) -> Result<Option<abi::GuiEvent>, i32> {
        if let Some(event) = self.poll_event()? {
            return Ok(Some(event));
        }
        self.sleep(ticks.max(1));
        self.poll_event()
    }
    pub fn register_service(&self) -> Result<Service<'_, 'a>, i32> {
        if self.context.app_class != abi::R4XStartAppClass::service.0 {
            return Err(-1);
        }
        let f: abi::R4SysFns::service_endpoint_register = unsafe {
            mem::transmute(
                self.sys_slot(mem::offset_of!(
                    abi::R4XStartR4Sys,
                    service_endpoint_register
                ))
                .ok_or(-2)?,
            )
        };
        let mut info = abi::ServiceInfo::default();
        let rc = unsafe { f(self.name.as_ptr().cast(), 0, &mut info) };
        if rc < 0 || info.handle == 0 {
            return Err(if rc < 0 { rc } else { -3 });
        }
        Ok(Service {
            app: self,
            handle: info.handle,
        })
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
                    .sys_slot(mem::offset_of!(abi::R4XStartR4Sys, service_endpoint_wait))
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
        let Some(address) = self
            .app
            .sys_slot(mem::offset_of!(abi::R4XStartR4Sys, service_endpoint_recv))
        else {
            return -2;
        };
        if data.len() > u32::MAX as usize {
            return -1;
        }
        let f: abi::R4SysFns::service_endpoint_recv = unsafe { mem::transmute(address) };
        unsafe { f(self.handle, header, data.as_mut_ptr(), data.len() as u32) }
    }
    pub fn reply(&self, request: u32, status: i32, data: &[u8]) -> i32 {
        let Some(address) = self
            .app
            .sys_slot(mem::offset_of!(abi::R4XStartR4Sys, service_endpoint_reply))
        else {
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
            abi::R4XStartR4Sys,
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
    raw: *const abi::R4XStartContext,
    expected: &StartupInfo<'_>,
    name: &'static CStr,
    main: fn(&mut App<'_>) -> i32,
) -> i32 {
    let mut app = match unsafe { App::from_raw(raw, expected, name) } {
        Ok(a) => a,
        Err(e) => return e,
    };
    let entropy_status = unsafe { c_facades::R4SdkBindProgramEntropy(raw) };
    if entropy_status < 0 {
        return entropy_status;
    }
    bind_panic_callbacks(
        app.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, write))
            .unwrap_or(0) as u64,
        app.sys_slot(mem::offset_of!(abi::R4XStartR4Sys, program_exit))
            .unwrap_or(0) as u64,
    );
    #[cfg(all(feature = "alloc", target_os = "none"))]
    if heap::install(&app).is_err() {
        clear_panic_callbacks();
        return -17;
    }
    let code = main(&mut app);
    clear_panic_callbacks();
    code
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
        #[unsafe(no_mangle)]
        #[unsafe(link_section = ".text.r4xstart_entry")]
        pub unsafe extern "C" fn R4XStart(raw: *const $crate::abi::R4XStartContext) -> i32 {
            use $crate as __r4os_startup;
            let startup = include!(env!("R4OS_STARTUP_INFO_FILE"));
            unsafe {
                $crate::start(
                    raw,
                    &startup,
                    core::ffi::CStr::from_bytes_with_nul_unchecked(
                        concat!(env!("R4OS_MODULE_NAME"), "\0").as_bytes(),
                    ),
                    $main,
                )
            }
        }
    };
}

const _: () = {
    assert!(
        mem::offset_of!(abi::R4XStartR4Sys, magic) == mem::offset_of!(abi::R4XStartR4Desk, magic)
    );
    assert!(
        mem::offset_of!(abi::R4XStartR4Sys, abi_version)
            == mem::offset_of!(abi::R4XStartR4Draw, abi_version)
    );
    assert!(
        mem::offset_of!(abi::R4XStartR4Sys, size) == mem::offset_of!(abi::R4XStartR4Desk, size)
    );
    assert!(
        mem::offset_of!(abi::R4XStartR4Sys, size) == mem::offset_of!(abi::R4XStartR4Draw, size)
    );
};

pub mod subsystems;
