//! Borrowed generation2 technical tables; the original driver/PPI execution
//! owner authenticates each call. No Drop implies device or DMA quiescence.
use crate::abi;
use core::{ffi::CStr, marker::PhantomData, mem};

pub struct Driver<'a> {
    table: abi::DriverApi2,
    _callbacks: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Driver<'a> {
    /// # Safety
    /// The exact immutable loader table and every declared mandatory callback
    /// are readable/valid for 'a under this driver's admitted execution scope.
    pub unsafe fn from_raw(raw: *const abi::DriverApi2) -> Result<Self, i32> {
        if raw.is_null() || !(raw as usize).is_multiple_of(8) {
            return Err(-1);
        }
        let prefix = mem::offset_of!(abi::DriverApi2, register_audio_capture_backend);
        let valid = unsafe {
            (*raw).magic == abi::driver_api2_magic
                && (*raw).version >= abi::driver_api2_version
                && (*raw).size as usize >= prefix
                && (*raw).reserved == 0
        };
        if !valid {
            return Err(-1);
        }
        let readable = unsafe { (*raw).size as usize };
        let mut table = mem::MaybeUninit::<abi::DriverApi2>::zeroed();
        unsafe {
            core::ptr::copy_nonoverlapping(
                raw.cast::<u8>(),
                table.as_mut_ptr().cast::<u8>(),
                prefix,
            );
        }
        if readable >= prefix + mem::size_of::<usize>() {
            unsafe {
                core::ptr::copy_nonoverlapping(
                    raw.cast::<u8>().add(prefix),
                    table.as_mut_ptr().cast::<u8>().add(prefix),
                    mem::size_of::<usize>(),
                );
            }
        }
        let mut table = unsafe { table.assume_init() };
        table.size = readable.min(mem::size_of::<abi::DriverApi2>()) as u32;
        Ok(Self {
            table,
            _callbacks: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn raw(&self) -> &abi::DriverApi2 {
        &self.table
    }
    pub fn log(&self, text: &CStr) {
        unsafe { (self.table.log_info)(text.as_ptr().cast()) }
    }
    pub fn clock_sample(
        &self,
    ) -> Result<crate::time::checked::ClockSample, crate::time::checked::Error> {
        let callback = self
            .table
            .monotonic_clock
            .ok_or(crate::time::checked::Error::ClockUnavailable)?;
        let mut info = abi::MonotonicClockInfo::default();
        if unsafe { callback(&mut info) } <= 0 {
            return Err(crate::time::checked::Error::ClockUnavailable);
        }
        crate::time::checked::ClockSample::from_info(&info)
    }
    /// # Safety
    /// Descriptor and all callback/context backing stay immutable and resident
    /// through actual unregister/terminal retirement, even after partial error.
    pub unsafe fn register_audio(&self, name: &CStr, backend: *const abi::AudioBackend2) -> i32 {
        unsafe { (self.table.register_audio_output_backend)(name.as_ptr().cast(), backend) }
    }
    /// # Safety
    /// Immutable input descriptor/context/code remain retained until genuine
    /// hardware shutdown and original registry retirement acknowledge release.
    pub unsafe fn register_capture(
        &self,
        name: &CStr,
        input: *const abi::AudioCaptureBackend2,
    ) -> i32 {
        match self.table.register_audio_capture_backend {
            Some(register) => unsafe { register(name.as_ptr().cast(), input) },
            None => abi::audio_capture_error_unsupported,
        }
    }
}
pub struct Protocol<'a> {
    table: abi::ProtocolApi2,
    _callbacks: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Protocol<'a> {
    /// # Safety
    /// The immutable declared prefix and callbacks remain valid for 'a in the
    /// real PPI scope. Only complete readable slots are copied; a short original
    /// table never becomes a reference to the larger current Rust type.
    pub unsafe fn from_raw(raw: *const abi::ProtocolApi2) -> Result<Self, i32> {
        if raw.is_null() || !(raw as usize).is_multiple_of(8) {
            return Err(-1);
        }
        let prefix = mem::offset_of!(abi::ProtocolApi2, protocol_dispatch);
        let valid = unsafe {
            (*raw).magic == abi::protocol_api2_magic
                && (*raw).version >= abi::protocol_api2_version
                && (*raw).size as usize >= prefix
                && (*raw).reserved == 0
        };
        if !valid {
            return Err(-1);
        }
        let readable = unsafe { (*raw).size as usize };
        let mut table = mem::MaybeUninit::<abi::ProtocolApi2>::zeroed();
        // The original prefix initializes every mandatory function pointer.
        // Missing optional slots keep a valid null representation; partial
        // pointer bytes are never copied or interpreted as a callback.
        unsafe {
            core::ptr::copy_nonoverlapping(
                raw.cast::<u8>(),
                table.as_mut_ptr().cast::<u8>(),
                prefix,
            );
        }
        for offset in [
            mem::offset_of!(abi::ProtocolApi2, protocol_dispatch),
            mem::offset_of!(abi::ProtocolApi2, link_io),
            mem::offset_of!(abi::ProtocolApi2, process_status),
        ] {
            if readable >= offset + mem::size_of::<usize>() {
                unsafe {
                    core::ptr::copy_nonoverlapping(
                        raw.cast::<u8>().add(offset),
                        table.as_mut_ptr().cast::<u8>().add(offset),
                        mem::size_of::<usize>(),
                    );
                }
            }
        }
        let mut table = unsafe { table.assume_init() };
        // raw() borrows this known-size copy, so never advertise inaccessible
        // future provider slots beyond its actual backing allocation.
        table.size = readable.min(mem::size_of::<abi::ProtocolApi2>()) as u32;
        Ok(Self {
            table,
            _callbacks: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn raw(&self) -> &abi::ProtocolApi2 {
        &self.table
    }
}
#[macro_export]
macro_rules! driver_entry2 {
    ($init:path,$shutdown:path)=>{
        core::arch::global_asm!(
            ".pushsection .text.r4d_entries,\"ax\",@progbits",
            ".global DriverInit2", "DriverInit2:", ".byte 0xe9", ".long {init} - . - 4",
            ".global DriverShutdown", "DriverShutdown:", ".byte 0xe9", ".long {shutdown} - . - 4", ".popsection",
            init=sym $init,shutdown=sym $shutdown);
        const _: unsafe extern "C" fn(*const $crate::abi::DriverApi2)->i32=$init;
        const _: unsafe extern "C" fn()->i32=$shutdown;
    };
}
#[macro_export]
macro_rules! protocol_entry2 {
    ($init:path,$shutdown:path,$query:path,$dispatch:path)=>{
        core::arch::global_asm!(
            ".pushsection .text.r4p_entries,\"ax\",@progbits",
            ".global ProtocolInit2", "ProtocolInit2:", ".byte 0xe9", ".long {init} - . - 4",
            ".global ProtocolShutdown", "ProtocolShutdown:", ".byte 0xe9", ".long {shutdown} - . - 4",
            ".global ProtocolQuery", "ProtocolQuery:", ".byte 0xe9", ".long {query} - . - 4",
            ".global ProtocolDispatch", "ProtocolDispatch:", ".byte 0xe9", ".long {dispatch} - . - 4", ".popsection",
            init=sym $init,shutdown=sym $shutdown,query=sym $query,dispatch=sym $dispatch);
        const _: unsafe extern "C" fn(*const $crate::abi::ProtocolApi2)->i32=$init;
        const _: unsafe extern "C" fn()->i32=$shutdown;
        const _: unsafe extern "C" fn(*mut $crate::abi::ProtocolStatus)->i32=$query;
        const _: unsafe extern "C" fn(u32,*const $crate::abi::ProtocolBuffer,*mut $crate::abi::ProtocolBuffer)->i32=$dispatch;
    };
}
