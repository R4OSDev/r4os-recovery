//! Generic Runtime-R4L transport. Library IDs, records, slots and operation
//! contracts remain in each library's generated consumer crate.
use crate::{App, App2, abi};
use core::{marker::PhantomData, mem};

pub const INTERFACE_MAGIC: u32 = 0x3149_3452;
pub const HEADER_VERSION: u16 = 1;
const HEADER_BYTES: u32 = 32;
const REQUIRED_FLAGS: u16 = 0x00ff;

/// SDK-owned common transport header, shared with r4os/runtime_r4l.zig and
/// C r4os/r4l.h. Library-specific records are generated from their contracts.
#[repr(C)]
#[derive(Clone, Copy, Debug, Default)]
pub struct InterfaceHeader {
    pub magic: u32,
    pub header_version: u16,
    pub flags: u16,
    pub size: u32,
    pub abi_major: u16,
    pub abi_minor: u16,
    pub interface_id_lo: u64,
    pub interface_id_hi: u64,
}
const _: () = {
    assert!(mem::size_of::<InterfaceHeader>() == 32);
    assert!(mem::align_of::<InterfaceHeader>() == 8);
    assert!(mem::offset_of!(InterfaceHeader, magic) == 0);
    assert!(mem::offset_of!(InterfaceHeader, header_version) == 4);
    assert!(mem::offset_of!(InterfaceHeader, flags) == 6);
    assert!(mem::offset_of!(InterfaceHeader, size) == 8);
    assert!(mem::offset_of!(InterfaceHeader, abi_major) == 12);
    assert!(mem::offset_of!(InterfaceHeader, abi_minor) == 14);
    assert!(mem::offset_of!(InterfaceHeader, interface_id_lo) == 16);
    assert!(mem::offset_of!(InterfaceHeader, interface_id_hi) == 24);
};

#[derive(Clone, Copy, Debug)]
pub struct Expectation {
    pub interface_id_lo: u64,
    pub interface_id_hi: u64,
    pub abi_major: u16,
    pub min_revision: u16,
    pub required_size: u32,
    pub known_required_flags: u8,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    MissingImport,
    InvalidImport,
    InvalidExpectation,
    ManifestRevisionTooOld,
    MisalignedTable,
    BadMagic,
    UnsupportedHeader,
    UnknownRequiredFlags,
    InvalidTableSize,
    WrongInterface,
    WrongMajor,
    InvalidRevision,
    RevisionDrift,
    RevisionTooOld,
    TableTooSmall,
    MissingSlot,
    InvalidQuery,
}

/// A checked view borrowed from the exact loader-owned App. It cannot be
/// moved to another thread or outlive that App/provider loan.
#[derive(Debug)]
pub struct Interface<'a> {
    header: &'a InterfaceHeader,
    _local: PhantomData<*mut ()>,
}
impl<'a> Interface<'a> {
    pub fn new2(
        app: &'a App2<'_>,
        module: &str,
        export: &str,
        expected: Expectation,
    ) -> Result<Self, Error> {
        check_expectation(expected)?;
        query2(app, module)?;
        let item = app.import(module, export).ok_or(Error::MissingImport)?;
        let header = unsafe { validate(item, expected) }?;
        Ok(Self {
            header,
            _local: PhantomData,
        })
    }
    pub fn optional2(
        app: &'a App2<'_>,
        module: &str,
        export: &str,
        expected: Expectation,
    ) -> Result<Option<Self>, Error> {
        check_expectation(expected)?;
        let Some(item) = app.import(module, export) else {
            return Ok(None);
        };
        if item.table == 0
            && item.resolved_version == 0
            && item.group_id == 0
            && item.flags == 0
            && item.min_version != 0
        {
            return Ok(None);
        }
        Self::new2(app, module, export, expected).map(Some)
    }
    pub fn new(
        app: &'a App<'_>,
        module: &str,
        export: &str,
        expected: Expectation,
    ) -> Result<Self, Error> {
        Self::new2(app, module, export, expected)
    }
    /// Absence is accepted explicitly. Malformed/incompatible loaded tables
    /// still return their precise error, never a substituted implementation.
    pub fn optional(
        app: &'a App<'_>,
        module: &str,
        export: &str,
        expected: Expectation,
    ) -> Result<Option<Self>, Error> {
        check_expectation(expected)?;
        let Some(item) = app.import(module, export) else {
            return Ok(None);
        };
        if item.table == 0
            && item.resolved_version == 0
            && item.group_id == 0
            && item.flags == 0
            && item.min_version != 0
        {
            return Ok(None);
        }
        Self::new(app, module, export, expected).map(Some)
    }
    pub fn header(&self) -> &InterfaceHeader {
        self.header
    }
    pub fn slot_address(&self, offset: u32) -> Option<usize> {
        if offset < HEADER_BYTES
            || !offset.is_multiple_of(8)
            || offset > self.header.size
            || 8 > self.header.size - offset
        {
            return None;
        }
        // The loader pins and validates the provider range; header shape and
        // the exact declared size were admitted before constructing this view.
        let slot = unsafe {
            (core::ptr::from_ref(self.header).cast::<u8>())
                .add(offset as usize)
                .cast::<u64>()
        };
        let address = unsafe { slot.read() } as usize;
        if address == 0 { None } else { Some(address) }
    }
    /// # Safety
    /// F must be the matching pointer-sized C ABI function type from the
    /// library contract. A returned function remains valid only for this
    /// exact provider loan; preserve operation ownership/threading on calls.
    pub unsafe fn function<F: Copy>(&self, offset: u32) -> Option<F> {
        if mem::size_of::<F>() != mem::size_of::<usize>() {
            return None;
        }
        let address = self.slot_address(offset)?;
        Some(unsafe { mem::transmute_copy::<usize, F>(&address) })
    }
}

// The unsafe App constructor/real loader guarantee resident immutable table
// storage and the declared slot range. No arbitrary raw-pointer safe API.
unsafe fn validate(
    item: &abi::R4XStartImport,
    expected: Expectation,
) -> Result<&InterfaceHeader, Error> {
    check_expectation(expected)?;
    if item.group_id != 0 || item.table == 0 || item.min_version == 0 || item.resolved_version == 0
    {
        return Err(Error::InvalidImport);
    }
    if item.min_version < u32::from(expected.min_revision) {
        return Err(Error::ManifestRevisionTooOld);
    }
    if item.resolved_version < item.min_version || item.resolved_version > u16::MAX.into() {
        return Err(Error::InvalidRevision);
    }
    if !item.table.is_multiple_of(8) {
        return Err(Error::MisalignedTable);
    }
    let header = unsafe { &*(item.table as *const InterfaceHeader) };
    if header.magic != INTERFACE_MAGIC {
        return Err(Error::BadMagic);
    }
    if header.header_version != HEADER_VERSION {
        return Err(Error::UnsupportedHeader);
    }
    if (header.flags & REQUIRED_FLAGS) & !u16::from(expected.known_required_flags) != 0 {
        return Err(Error::UnknownRequiredFlags);
    }
    if header.size < HEADER_BYTES
        || !header.size.is_multiple_of(8)
        || item.table.checked_add(u64::from(header.size)).is_none()
    {
        return Err(Error::InvalidTableSize);
    }
    if header.interface_id_lo != expected.interface_id_lo
        || header.interface_id_hi != expected.interface_id_hi
    {
        return Err(Error::WrongInterface);
    }
    if header.abi_major != expected.abi_major {
        return Err(Error::WrongMajor);
    }
    if header.abi_minor == 0 {
        return Err(Error::InvalidRevision);
    }
    if item.resolved_version != u32::from(header.abi_minor) {
        return Err(Error::RevisionDrift);
    }
    if header.abi_minor < expected.min_revision {
        return Err(Error::RevisionTooOld);
    }
    if header.size < expected.required_size {
        return Err(Error::TableTooSmall);
    }
    Ok(header)
}

fn check_expectation(expected: Expectation) -> Result<(), Error> {
    if (expected.interface_id_lo == 0 && expected.interface_id_hi == 0)
        || expected.abi_major == 0
        || expected.min_revision == 0
        || expected.required_size < HEADER_BYTES
        || !expected.required_size.is_multiple_of(8)
    {
        return Err(Error::InvalidExpectation);
    }
    Ok(())
}

/// Read a standalone library's current Query metadata. Query is a descriptor,
/// not its named API table and not an old kernel/provider bridge.
pub fn query<'a>(app: &'a App<'_>, module: &str) -> Result<&'a abi::generation2::R4LQuery2, Error> {
    query2(app, module)
}

/// Technical Query2 admission leaves the independent named API revision alone.
pub fn query2<'a>(
    app: &'a App2<'_>,
    module: &str,
) -> Result<&'a abi::generation2::R4LQuery2, Error> {
    let item = app.import(module, "Query2").ok_or(Error::MissingImport)?;
    if item.group_id != 0 || item.min_version != 2 || item.resolved_version != 2 || item.table == 0
    {
        return Err(Error::InvalidImport);
    }
    if !item
        .table
        .is_multiple_of(mem::align_of::<abi::generation2::R4LQuery2>() as u64)
    {
        return Err(Error::MisalignedTable);
    }
    let table = unsafe { &*(item.table as *const abi::generation2::R4LQuery2) };
    if table.magic != abi::generation2::QUERY_MAGIC
        || table.abi_version != 2
        || table.size != mem::size_of::<abi::generation2::R4LQuery2>() as u32
        || table.group != 0
        || table.reserved != 0
    {
        return Err(Error::InvalidQuery);
    }
    Ok(table)
}

/// Const provider header from the generated library-owned expectation.
/// Use the exact current table size/revision/flags; the loader verifies exports.
pub const fn provider_header(expected: Expectation) -> InterfaceHeader {
    InterfaceHeader {
        magic: INTERFACE_MAGIC,
        header_version: HEADER_VERSION,
        flags: expected.known_required_flags as u16,
        size: expected.required_size,
        abi_major: expected.abi_major,
        abi_minor: expected.min_revision,
        interface_id_lo: expected.interface_id_lo,
        interface_id_hi: expected.interface_id_hi,
    }
}
/// Ordinary standalone metadata uses the current technical descriptor.
pub const PROVIDER_QUERY: abi::generation2::R4LQuery2 = PROVIDER_QUERY2;
/// Normal provider entry and Query2 export. API tables are declared by the
/// library's generated contract and explicitly exported by its own manifest.
/// Library state/allocators/callbacks belong to each explicit caller/session;
/// never use an R4X-global allocator as a shared library heap.
#[macro_export]
macro_rules! r4l_provider {
    ($query:ident) => {
        $crate::r4l_provider2!($query);
    };
}

/// Generation2 admission for independent library-owned interfaces. The API
/// records and each caller's allocators/callbacks remain library-owned.
pub const PROVIDER_QUERY2: abi::generation2::R4LQuery2 = abi::generation2::R4LQuery2 {
    magic: abi::generation2::QUERY_MAGIC,
    abi_version: 2,
    size: core::mem::size_of::<abi::generation2::R4LQuery2>() as u32,
    group: 0,
    reserved: 0,
};
#[macro_export]
macro_rules! r4l_provider2 {
    ($query:ident) => {
        #[unsafe(no_mangle)]
        pub extern "C" fn r4l_entry() {}
        #[unsafe(no_mangle)]
        #[unsafe(link_section = ".data.r4l_exports")]
        pub static $query: $crate::abi::generation2::R4LQuery2 = $crate::r4l::PROVIDER_QUERY2;
    };
}

#[cfg(test)]
mod tests {
    use super::*;
    unsafe extern "C" fn twice(value: u64) -> u64 {
        value * 2
    }
    #[repr(C)]
    struct Table {
        header: InterfaceHeader,
        slot: u64,
    }
    #[test]
    fn exact_transport_header_slots_and_required_optional_flags() {
        let mut table = Table {
            header: InterfaceHeader {
                magic: INTERFACE_MAGIC,
                header_version: HEADER_VERSION,
                flags: 0x101,
                size: 40,
                abi_major: 1,
                abi_minor: 2,
                interface_id_lo: 0x1020,
                interface_id_hi: 0x3040,
            },
            slot: twice as *const () as u64,
        };
        let expected = Expectation {
            interface_id_lo: 0x1020,
            interface_id_hi: 0x3040,
            abi_major: 1,
            min_revision: 2,
            required_size: 40,
            known_required_flags: 1,
        };
        let mut item: abi::R4XStartImport = unsafe { mem::zeroed() };
        item.table = core::ptr::from_ref(&table) as u64;
        item.min_version = 2;
        item.resolved_version = 2;
        let check = |table: &Table, item: &abi::R4XStartImport, expected| {
            core::hint::black_box(table);
            unsafe { validate(item, expected).map(|header| header.size) }
        };
        assert_eq!(check(&table, &item, expected), Ok(40));
        {
            let header = unsafe { validate(&item, expected) }.unwrap();
            let interface = Interface {
                header,
                _local: PhantomData,
            };
            assert!(interface.slot_address(24).is_none());
            assert!(interface.slot_address(33).is_none());
            assert!(interface.slot_address(40).is_none());
            assert!(unsafe { interface.function::<u32>(32) }.is_none());
            let call: unsafe extern "C" fn(u64) -> u64 = unsafe { interface.function(32) }.unwrap();
            assert_eq!(unsafe { call(7) }, 14);
        }
        assert_eq!(
            check(
                &table,
                &item,
                Expectation {
                    required_size: 36,
                    ..expected
                }
            ),
            Err(Error::InvalidExpectation)
        );
        item.table += 1;
        assert_eq!(check(&table, &item, expected), Err(Error::MisalignedTable));
        item.table -= 1;
        item.min_version = 1;
        assert_eq!(
            check(&table, &item, expected),
            Err(Error::ManifestRevisionTooOld)
        );
        item.min_version = 2;
        item.resolved_version = 3;
        assert_eq!(check(&table, &item, expected), Err(Error::RevisionDrift));
        item.resolved_version = 2;
        table.header.flags = 0x102;
        assert_eq!(
            check(&table, &item, expected),
            Err(Error::UnknownRequiredFlags)
        );
        table.header.flags = 0x200; // Unknown optional bits retain their meaning.
        assert_eq!(check(&table, &item, expected), Ok(40));
        table.header.magic = 0;
        assert_eq!(check(&table, &item, expected), Err(Error::BadMagic));
        table.header.magic = INTERFACE_MAGIC;
        table.header.size = 32;
        assert_eq!(check(&table, &item, expected), Err(Error::TableTooSmall));
        table.header.size = 39;
        assert_eq!(check(&table, &item, expected), Err(Error::InvalidTableSize));
        table.header.size = 40;
        table.header.abi_major = 2;
        assert_eq!(check(&table, &item, expected), Err(Error::WrongMajor));
        table.header.abi_major = 1;
        table.header.interface_id_lo ^= 1;
        assert_eq!(check(&table, &item, expected), Err(Error::WrongInterface));
        table.header.interface_id_lo ^= 1;
        table.slot = 0;
        core::hint::black_box(&table);
        let header = unsafe { validate(&item, expected) }.unwrap();
        let interface = Interface {
            header,
            _local: PhantomData,
        };
        assert!(interface.slot_address(32).is_none());
    }
}
