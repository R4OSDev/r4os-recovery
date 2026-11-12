//! Explicit generation-2 view, independent of the existing App binding.
pub use crate::abi::generation2 as abi;
use core::{ffi::c_void, marker::PhantomData, mem};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[repr(i32)]
pub enum Error {
    InvalidContext = 1,
    InvalidImports = 2,
    MixedGeneration = 3,
    DuplicateGroup = 4,
    MissingSystem = 5,
    InvalidTable = 6,
}

/// SDK-private C/Zig context-view layout. This owns no start or table storage.
#[repr(C)]
pub struct Context<'a> {
    raw: &'a abi::R4XStartContext2,
    tables: [u64; 6],
    local: PhantomData<*mut ()>,
}
impl<'a> Context<'a> {
    /// # Safety
    /// Imports and each table's declared initialized prefix remain readable
    /// for this view's lifetime. They belong to the actual start generation.
    /// Table function calls retain their own caller and buffer contracts.
    pub unsafe fn new(raw: &'a abi::R4XStartContext2) -> Result<Self, Error> {
        if raw.magic != abi::START_MAGIC
            || raw.abi_major != 2
            || raw.size < mem::size_of_val(raw) as u32
        {
            return Err(Error::InvalidContext);
        }
        if raw.args_len > isize::MAX as u64
            || (raw.args_len != 0 && raw.args == 0)
            || raw.args.checked_add(raw.args_len).is_none()
        {
            return Err(Error::InvalidContext);
        }
        if raw.import_count > 32
            || (raw.import_count != 0
                && (raw.imports == 0
                    || !raw
                        .imports
                        .is_multiple_of(mem::align_of::<crate::abi::R4XStartImport>() as u64)))
        {
            return Err(Error::InvalidImports);
        }
        let mut result = Self {
            raw,
            tables: [0; 6],
            local: PhantomData,
        };
        let mut seen = 0u8;
        if raw.import_count != 0 {
            let imports = unsafe {
                core::slice::from_raw_parts(
                    raw.imports as *const crate::abi::R4XStartImport,
                    raw.import_count as usize,
                )
            };
            for item in imports {
                if item.group_id == 0 {
                    continue;
                }
                if item.group_id > 6 {
                    return Err(Error::InvalidImports);
                }
                if item.resolved_version != 2 {
                    return Err(Error::MixedGeneration);
                }
                let index = (item.group_id - 1) as usize;
                let bit = 1u8 << index;
                if seen & bit != 0 {
                    return Err(Error::DuplicateGroup);
                }
                seen |= bit;
                result.tables[index] = item.table;
            }
        }
        if result.tables[0] == 0 {
            return Err(Error::MissingSystem);
        }
        if result.group(1).is_none() {
            return Err(Error::InvalidTable);
        }
        Ok(result)
    }
    pub fn raw(&self) -> &'a abi::R4XStartContext2 {
        self.raw
    }
    pub fn imports(&self) -> &[crate::abi::R4XStartImport] {
        if self.raw.import_count == 0 {
            return &[];
        }
        unsafe {
            core::slice::from_raw_parts(
                self.raw.imports as *const crate::abi::R4XStartImport,
                self.raw.import_count as usize,
            )
        }
    }
    pub fn import(&self, module: &str, symbol: &str) -> Option<&crate::abi::R4XStartImport> {
        self.imports().iter().find(|entry| unsafe {
            crate::startup::name_equals(entry.module_name, module.as_bytes())
                && crate::startup::name_equals(entry.symbol_name, symbol.as_bytes())
        })
    }
    pub(crate) fn native(&self) -> *const crate::c_facades::R4OS2Context {
        // The SDK-private view has the same raw pointer and six table addresses
        // in all three languages. The actual start remains its own 120-byte ABI.
        core::ptr::from_ref(self).cast()
    }
    pub fn args(&self) -> &'a [u8] {
        if self.raw.args_len == 0 {
            return &[];
        }
        unsafe {
            core::slice::from_raw_parts(self.raw.args as *const u8, self.raw.args_len as usize)
        }
    }
    pub fn should_close(&self) -> bool {
        if self.raw.flags & crate::abi::r4xstart_flag_close_supported == 0
            || self.raw.should_close == 0
        {
            return true;
        }
        let callback: abi::R4XStartShouldCloseFn2 =
            unsafe { mem::transmute(self.raw.should_close) };
        unsafe { callback(self.raw) != 0 }
    }
    pub fn yield_current(&self) -> bool {
        if self.raw.flags & crate::abi::r4xstart_flag_yield_supported == 0 || self.raw.r#yield == 0
        {
            return false;
        }
        let callback: abi::R4XStartYieldFn2 = unsafe { mem::transmute(self.raw.r#yield) };
        unsafe { callback(self.raw) };
        true
    }
    /// The Contract supplies the slot offset and C function signature.
    /// Resolving an address neither invokes it nor changes its buffer loans.
    pub fn lookup(&self, group: u32, offset: u32) -> Result<u64, i32> {
        let table = self.group(group).ok_or(crate::abi::err_no_group)?;
        let size = unsafe { *(table.cast::<u32>()).add(2) };
        if offset < 16 || !offset.is_multiple_of(8) || u64::from(offset) + 8 > u64::from(size) {
            return Err(crate::abi::err_no_fn);
        }
        let address = (table as usize)
            .checked_add(offset as usize)
            .ok_or(crate::abi::err_no_fn)?;
        let slot = unsafe { *(address as *const u64) };
        if slot == 0 {
            Err(crate::abi::err_no_fn)
        } else {
            Ok(slot)
        }
    }
    pub fn group(&self, group: u32) -> Option<*const c_void> {
        const MAGIC: [u32; 6] = [
            abi::R4SYS_MAGIC,
            abi::R4DESK_MAGIC,
            abi::R4DRAW_MAGIC,
            abi::R4NET_MAGIC,
            abi::R4AUDIO_MAGIC,
            abi::R4DEV_MAGIC,
        ];
        if !(1..=6).contains(&group) {
            return None;
        }
        let address = self.tables[(group - 1) as usize];
        if address == 0 || !address.is_multiple_of(8) {
            return None;
        }
        // Read only the promised header, never form a full-table reference
        // for a shorter compatible prefix.
        let header = address as *const u32;
        if unsafe { *header } != MAGIC[(group - 1) as usize]
            || unsafe { *header.add(1) } < 1
            || unsafe { *header.add(2) } < 16
        {
            return None;
        }
        Some(address as *const c_void)
    }
}

const _: () = {
    assert!(mem::size_of::<Context<'_>>() == mem::size_of::<crate::c_facades::R4OS2Context>());
    assert!(mem::align_of::<Context<'_>>() == mem::align_of::<crate::c_facades::R4OS2Context>());
    assert!(mem::offset_of!(Context<'_>, raw) == 0);
    assert!(mem::offset_of!(Context<'_>, tables) == 8);
};

#[derive(Clone, Copy)]
pub struct StartupInfo {
    pub app_class: u32,
    pub required_groups: u32,
    pub import_count: u32,
}
/// # Safety
/// Exact current loader context and all its imported prefixes remain resident
/// throughout this entry. The callback receives a non-Send borrowed view.
#[doc(hidden)]
pub unsafe fn start(
    raw: *const abi::R4XStartContext2,
    info: StartupInfo,
    main: fn(&Context<'_>) -> i32,
) -> i32 {
    if raw.is_null() || !(raw as usize).is_multiple_of(mem::align_of::<abi::R4XStartContext2>()) {
        return -1;
    }
    let raw = unsafe { &*raw };
    let context = match unsafe { Context::new(raw) } {
        Ok(v) => v,
        Err(_) => return -1,
    };
    if raw.app_class != info.app_class || raw.import_count != info.import_count {
        return -1;
    }
    for i in 0..6 {
        if info.required_groups & (1 << (i + 1)) != 0 && context.group((i + 1) as u32).is_none() {
            return -1;
        }
    }
    // No old App/allocator/entropy binder is attached to this raw generation.
    // Panics use the kernel's existing module-fault termination boundary.
    main(&context)
}
#[macro_export]
macro_rules! lowlevel_entry2 {
    ($main:path) => {
        #[unsafe(no_mangle)]
        #[unsafe(link_section = ".text.r4xstart_entry")]
        pub unsafe extern "C" fn R4XStart2(
            raw: *const $crate::platform2::abi::R4XStartContext2,
        ) -> i32 {
            use $crate as __r4os_startup;
            let info = include!(env!("R4OS_STARTUP_INFO_FILE"));
            unsafe { $crate::platform2::start(raw, info, $main) }
        }
    };
}
