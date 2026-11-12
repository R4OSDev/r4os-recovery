//! Normal application entry on the actual generation2 contract.
use crate::{abi, c_facades as c, heap, platform2};
use core::{ffi::CStr, marker::PhantomData, mem};

pub(crate) type Memory = c::R4App2Memory;
#[repr(C)]
pub struct ImportSpec {
    pub module_name: *const u8,
    pub symbol_name: *const u8,
    pub minimum: u32,
    pub optional: u32,
    pub group_id: u32,
    pub reserved: u32,
}
// Sharing the immutable descriptor exposes only scalar values and raw name
// pointers. Dereferencing those names occurs at the unsafe startup boundary,
// whose caller retains their immutable resident storage through entry return.
unsafe impl Sync for ImportSpec {}
pub struct StartupInfo<'a> {
    pub profile: u32,
    pub app_class: u32,
    pub required_groups: u32,
    pub imports: &'a [ImportSpec],
}
#[repr(C)]
struct RawStartupInfo {
    profile: u32,
    app_class: u32,
    required_groups: u32,
    import_count: u32,
    imports: *const ImportSpec,
}
unsafe extern "C" {
    fn R4SdkApp2InitRaw(raw: *const platform2::abi::R4XStartContext2, output: *mut Memory) -> i32;
    fn R4SdkApp2Init(
        raw: *const platform2::abi::R4XStartContext2,
        expected: *const RawStartupInfo,
        output: *mut Memory,
    ) -> i32;
}
pub struct App<'a> {
    context: platform2::Context<'a>,
    pub(crate) memory: Memory,
    name: &'static CStr,
    local: PhantomData<*mut ()>,
}
impl<'a> App<'a> {
    /// # Safety
    /// The actual generation2 start, immutable import descriptors and names,
    /// and declared table prefixes stay resident through the exact entry.
    /// All caller and buffer loans must
    /// retire before it returns. This borrowed App is neither Send nor Sync.
    pub unsafe fn from_raw(
        raw: *const platform2::abi::R4XStartContext2,
        expected: &StartupInfo<'_>,
        name: &'static CStr,
    ) -> Result<Self, i32> {
        if raw.is_null()
            || !(raw as usize).is_multiple_of(mem::align_of::<platform2::abi::R4XStartContext2>())
        {
            return Err(-12);
        }
        let mut memory = unsafe { mem::zeroed() };
        let facts = RawStartupInfo {
            profile: expected.profile,
            app_class: expected.app_class,
            required_groups: expected.required_groups,
            import_count: u32::try_from(expected.imports.len()).map_err(|_| -13)?,
            imports: expected.imports.as_ptr(),
        };
        let rc = unsafe { R4SdkApp2Init(raw, &facts, &mut memory) };
        if rc < 0 {
            return Err(rc);
        }
        let context = unsafe { platform2::Context::new(&*raw) }.map_err(|_| -12)?;
        Ok(Self {
            context,
            memory,
            name,
            local: PhantomData,
        })
    }
    pub fn context(&self) -> &platform2::Context<'a> {
        &self.context
    }
    /// Opt into SDK helper/entropy callbacks from an already admitted raw
    /// generation2 context. This does not install the global allocator or call
    /// an application main; the immutable original context remains borrowed.
    pub fn from_context(
        context: &platform2::Context<'a>,
        name: &'static CStr,
    ) -> Result<Self, i32> {
        let mut memory = unsafe { mem::zeroed() };
        let rc = unsafe { R4SdkApp2InitRaw(context.raw(), &mut memory) };
        if rc < 0 {
            return Err(rc);
        }
        Ok(Self {
            context: unsafe { platform2::Context::new(context.raw()) }.map_err(|_| -12)?,
            memory,
            name,
            local: PhantomData,
        })
    }
    pub(crate) fn native_context(&self) -> *const c::R4OS2Context {
        self.context.native()
    }
    pub fn start_context(&self) -> &'a platform2::abi::R4XStartContext2 {
        self.context.raw()
    }
    pub fn import(&self, module: &str, symbol: &str) -> Option<&abi::R4XStartImport> {
        self.context.import(module, symbol)
    }
    pub fn name(&self) -> &'static CStr {
        self.name
    }
    pub fn instance_id(&self) -> u64 {
        self.start_context().instance_id
    }
    pub fn args(&self) -> &'a [u8] {
        self.context.args()
    }
    pub fn should_close(&self) -> bool {
        self.context.should_close()
    }
    pub fn yield_current(&self) {
        let _ = self.context.yield_current();
    }
    pub fn sleep(&self, ticks: u64) {
        let address = match self.context.lookup(
            1,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, sleep_ticks) as u32,
        ) {
            Ok(address) => address,
            Err(_) => return,
        };
        let callback: abi::R4SysFns::sleep_ticks = unsafe { mem::transmute(address) };
        unsafe { callback(ticks) };
    }
    pub fn write(&self, text: &str) -> i32 {
        let length = match u32::try_from(text.len()) {
            Ok(n) => n,
            Err(_) => return abi::err_no_fn,
        };
        let address = match self.context.lookup(
            1,
            mem::offset_of!(platform2::abi::R4XStartR4Sys2, write) as u32,
        ) {
            Ok(a) => a,
            Err(e) => return e,
        };
        let function: abi::R4SysFns::write = unsafe { mem::transmute(address) };
        unsafe { function(text.as_ptr(), length) }
    }
    pub fn heap(&self) -> Result<heap::Heap<'_>, heap::Error> {
        heap::Heap::new2(self)
    }
    pub fn system(&self) -> crate::storage::Result<crate::storage::System<'_>> {
        crate::storage::System::new2(self)
    }
    pub fn resources(&self) -> crate::resources::Result<crate::resources::Resources<'_>> {
        crate::resources::Resources::new2(self)
    }
    pub fn services(&self) -> crate::storage::Result<crate::services::Services<'_>> {
        crate::services::Services::new2(self)
    }
    pub fn network(&self) -> crate::storage::Result<crate::network::Network<'_>> {
        crate::network::Network::new2(self)
    }
    pub fn serial(&self) -> crate::storage::Result<crate::serial::Serial<'_>> {
        crate::serial::Serial::new2(self)
    }
    pub fn platform<'s, 'b>(
        &'b self,
        storage: core::pin::Pin<&'s mut crate::platform::PlatformStorage>,
    ) -> crate::storage::Result<crate::platform::Platform<'s, 'b>> {
        crate::platform::Platform::open2(storage, self)
    }
    pub fn audio_capture(
        &self,
        transport_ticks: u64,
    ) -> Result<crate::audio_capture::Client<'_>, crate::audio_capture::Error> {
        crate::audio_capture::Client::connect(self.context(), transport_ticks)
    }
    pub fn arg_cursor(
        &self,
        policy: crate::cli::ArgPolicy,
    ) -> Result<crate::cli::ArgCursor<'_>, crate::cli::ArgError> {
        crate::cli::ArgCursor::new(self.args(), policy)
    }
    pub fn clock(&self) -> crate::time::Clock<'_, 'a> {
        crate::time::Clock::new2(self)
    }
    pub fn wait_set(
        &self,
        capacity: u32,
    ) -> Result<crate::wait_set::WaitSet<'_, 'a>, crate::wait_set::Error> {
        crate::wait_set::WaitSet::new(self.context(), capacity)
    }
    pub fn byte_pipe(
        &self,
        capacity: u64,
    ) -> Result<crate::byte_pipe::Pair<'_, 'a>, crate::byte_pipe::Error> {
        crate::byte_pipe::create(self.context(), capacity)
    }
    pub fn stdio(&self) -> Result<crate::launch_io::Stdio<'_, 'a>, crate::launch_io::Error> {
        crate::launch_io::Stdio::open(self.context())
    }
    pub fn network_family(
        &self,
        service: crate::network_family::Service,
    ) -> Result<crate::network_family::Client<'_>, crate::network_family::Error> {
        crate::network_family::Client::connect(self.context(), service)
    }
    pub fn text_metrics<'b>(
        &'b self,
        source: &'b str,
        storage: &'b mut [mem::MaybeUninit<abi::FontAdvance2>],
    ) -> Result<crate::text_metrics::Cache<'b>, crate::text_metrics::Error> {
        crate::text_metrics::Cache::new(self.context(), source, storage)
    }
    pub fn file_picker<'b>(
        &'b self,
        first: &'b mut [mem::MaybeUninit<crate::file_picker::Row>],
        second: &'b mut [mem::MaybeUninit<crate::file_picker::Row>],
        mode: crate::file_picker::Mode,
        extension: &[u8],
    ) -> Result<crate::file_picker::Session<'b>, crate::file_picker::Error> {
        crate::file_picker::Session::new(self.context(), first, second, mode, extension)
    }
    pub fn clipboard_offers(
        &self,
    ) -> Result<crate::clipboard_offer::Client<'_>, crate::clipboard_offer::Error> {
        crate::clipboard_offer::Client::connect(self.context())
    }
    pub fn composition_client(
        &self,
        timeout_ticks: u64,
    ) -> Result<crate::text_composition::Client<'_>, crate::text_composition::Error> {
        crate::text_composition::Client::connect(self.context(), timeout_ticks)
    }
    pub fn inventory_reader<'b, T: crate::inventory::Row>(
        &'b self,
        records: &'b mut [mem::MaybeUninit<T>],
        page_limit: u32,
        sample: crate::time::checked::ClockSample,
        timeout: crate::resources::Timeout,
    ) -> Result<crate::inventory::InventoryReader<'b, T>, crate::inventory::Error> {
        crate::inventory::InventoryReader::new(self.context(), records, page_limit, sample, timeout)
    }
    pub fn device_snapshot<'b>(
        &'b self,
        records: &'b mut [mem::MaybeUninit<abi::DeviceInventoryRecord>],
    ) -> Result<crate::device_snapshot::Snapshot<'b>, crate::device_snapshot::Error> {
        crate::device_snapshot::Snapshot::new(self.context(), records)
    }
}

/// # Safety
/// Only the SDK entry macro calls this with the complete generated facts and
/// a loader-pinned exact generation2 entry.
#[doc(hidden)]
pub unsafe fn start(
    raw: *const platform2::abi::R4XStartContext2,
    expected: &StartupInfo<'_>,
    name: &'static CStr,
    main: fn(&mut App<'_>) -> i32,
) -> i32 {
    let mut app = match unsafe { App::from_raw(raw, expected, name) } {
        Ok(a) => a,
        Err(e) => return e,
    };
    crate::bind_panic_callbacks(
        app.context()
            .lookup(
                1,
                mem::offset_of!(platform2::abi::R4XStartR4Sys2, write) as u32,
            )
            .unwrap_or(0),
        app.context()
            .lookup(
                1,
                mem::offset_of!(platform2::abi::R4XStartR4Sys2, program_exit) as u32,
            )
            .unwrap_or(0),
    );
    #[cfg(all(feature = "alloc", target_os = "none"))]
    if heap::install2(&app).is_err() {
        crate::clear_panic_callbacks();
        return -17;
    }
    let result = main(&mut app);
    crate::clear_panic_callbacks();
    result
}
#[macro_export]
macro_rules! app2 {
    ($main:path) => {
        #[unsafe(no_mangle)]
        #[unsafe(link_section = ".text.r4xstart_entry")]
        pub unsafe extern "C" fn R4XStart2(
            raw: *const $crate::platform2::abi::R4XStartContext2,
        ) -> i32 {
            use $crate as __r4os_startup;
            let startup = include!(env!("R4OS_STARTUP_INFO_FILE"));
            unsafe {
                $crate::app2::start(
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
    assert!(mem::size_of::<Memory>() == 128);
    assert!(mem::size_of::<ImportSpec>() == 32);
    assert!(mem::size_of::<RawStartupInfo>() == 24);
};
