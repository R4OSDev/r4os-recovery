const abi = @import("r4os_contract").abi;

pub const interface_magic: u32 = 0x31493452;
pub const interface_header_version: u16 = 1;
pub const interface_header_size: u32 = 32;
pub const interface_alignment: usize = 8;
pub const required_flag_mask: u16 = 0x00ff;

pub const InterfaceHeader = extern struct {
    magic: u32,
    header_version: u16,
    flags: u16,
    size: u32,
    abi_major: u16,
    abi_minor: u16,
    interface_id_lo: u64,
    interface_id_hi: u64,
};

pub const Expectation = struct {
    interface_id_lo: u64,
    interface_id_hi: u64,
    abi_major: u16,
    min_revision: u16,
    required_size: u32,
    known_required_flags: u8 = 0,
};

pub const BindingError = error{
    InvalidImport,
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
    InvalidExpectation,
};

comptime {
    if (@sizeOf(InterfaceHeader) != interface_header_size or @alignOf(InterfaceHeader) != interface_alignment) {
        @compileError("Runtime-R4L interface header layout mismatch");
    }
    if (@offsetOf(InterfaceHeader, "magic") != 0 or
        @offsetOf(InterfaceHeader, "header_version") != 4 or
        @offsetOf(InterfaceHeader, "flags") != 6 or
        @offsetOf(InterfaceHeader, "size") != 8 or
        @offsetOf(InterfaceHeader, "abi_major") != 12 or
        @offsetOf(InterfaceHeader, "abi_minor") != 14 or
        @offsetOf(InterfaceHeader, "interface_id_lo") != 16 or
        @offsetOf(InterfaceHeader, "interface_id_hi") != 24)
    {
        @compileError("Runtime-R4L interface header offset mismatch");
    }
}

/// Prueft ausschliesslich den generischen Transport- und Headervertrag. Der
/// Kernel hat den Tabellenbereich bereits gegen die gepinnte Provider-
/// generation validiert; fachliche Slots prueft das libraryeigene Binding.
pub fn validateImport(item: *const abi.R4XStartImport, expected: Expectation) BindingError!*const InterfaceHeader {
    if (expected.interface_id_lo == 0 and expected.interface_id_hi == 0) return error.InvalidExpectation;
    if (expected.abi_major == 0 or expected.min_revision == 0 or
        expected.required_size < interface_header_size or expected.required_size % interface_alignment != 0)
    {
        return error.InvalidExpectation;
    }
    if (item.group_id != 0 or item.table == 0 or item.min_version == 0 or item.resolved_version == 0) return error.InvalidImport;
    if (item.min_version < expected.min_revision) return error.ManifestRevisionTooOld;
    if (item.resolved_version < item.min_version or item.resolved_version > 65535) return error.InvalidRevision;
    if (item.table % interface_alignment != 0) return error.MisalignedTable;

    const header: *const InterfaceHeader = @ptrFromInt(item.table);
    if (header.magic != interface_magic) return error.BadMagic;
    if (header.header_version != interface_header_version) return error.UnsupportedHeader;
    const unknown_required = (header.flags & required_flag_mask) & ~@as(u16, expected.known_required_flags);
    if (unknown_required != 0) return error.UnknownRequiredFlags;
    if (header.size < interface_header_size or header.size % interface_alignment != 0) return error.InvalidTableSize;
    if (header.interface_id_lo != expected.interface_id_lo or header.interface_id_hi != expected.interface_id_hi) return error.WrongInterface;
    if (header.abi_major != expected.abi_major) return error.WrongMajor;
    if (header.abi_minor == 0) return error.InvalidRevision;
    if (item.resolved_version != @as(u32, header.abi_minor)) return error.RevisionDrift;
    if (header.abi_minor < expected.min_revision) return error.RevisionTooOld;
    if (header.size < expected.required_size) return error.TableTooSmall;
    return header;
}

pub fn hasSlot(header: *const InterfaceHeader, byte_offset: u32) bool {
    if (byte_offset < interface_header_size or byte_offset % @sizeOf(u64) != 0) return false;
    return byte_offset <= header.size and @sizeOf(u64) <= header.size - byte_offset;
}

pub fn slotAddress(header: *const InterfaceHeader, byte_offset: u32) ?usize {
    if (!hasSlot(header, byte_offset)) return null;
    const address = @intFromPtr(header) + byte_offset;
    const slot: *const u64 = @ptrFromInt(address);
    if (slot.* == 0) return null;
    return @intCast(slot.*);
}

pub fn functionAt(comptime Fn: type, header: *const InterfaceHeader, byte_offset: u32) ?Fn {
    const address = slotAddress(header, byte_offset) orelse return null;
    return @ptrFromInt(address);
}

test "generic interface validation and safe slot access" {
    const Table = extern struct {
        header: InterfaceHeader,
        first: u64,
    };
    var table = Table{
        .header = .{
            .magic = interface_magic,
            .header_version = interface_header_version,
            .flags = 0,
            .size = @sizeOf(Table),
            .abi_major = 1,
            .abi_minor = 2,
            .interface_id_lo = 0x1020,
            .interface_id_hi = 0x3040,
        },
        .first = 0x1234,
    };
    const item = abi.R4XStartImport{
        .group_id = 0,
        .min_version = 2,
        .resolved_version = 2,
        .flags = 0,
        .module_name = 1,
        .symbol_name = 1,
        .table = @intFromPtr(&table),
    };
    const header = try validateImport(&item, .{
        .interface_id_lo = 0x1020,
        .interface_id_hi = 0x3040,
        .abi_major = 1,
        .min_revision = 2,
        .required_size = @sizeOf(Table),
    });
    try @import("std").testing.expectEqual(@as(?usize, 0x1234), slotAddress(header, 32));
    try @import("std").testing.expect(slotAddress(header, 40) == null);
}
