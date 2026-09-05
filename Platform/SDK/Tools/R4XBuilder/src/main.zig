// R4OS R4XBuilder
//
// Builds native R4X programs, R4D drivers, and R4P protocols from raw code bytes.

const std = @import("std");

const R4X_R4D_HEADER_SIZE: usize = 32;
const R4P_HEADER_SIZE: usize = 64;
const R4M_HEADER_SIZE: usize = 64;
const R4M_SECTION_SIZE: usize = 32;
const R4M_ENTRY_SIZE: usize = 16;
const R4M_IMPORT_SIZE: usize = 16;
const R4M_EXPORT_SIZE: usize = 16;
const R4M_RELOCATION_SIZE: usize = 24;
const ARCH_X86_64: u16 = 1;
const R4X_VERSION: u16 = 2;
const R4D_VERSION: u32 = 1;
const R4P_VERSION: u16 = 1;
const R4M_VERSION: u16 = 1;
const R4D_API_VERSION: u32 = 11;
const R4P_API_VERSION: u32 = 1;
const MAX_PROTOCOL_DEPENDENCIES: usize = 16;
const MAX_MODULE_IMPORTS: usize = 16;
const MAX_MODULE_EXPORTS: usize = 16;
const MAX_MODULE_RELOCATIONS: usize = 4096;
const R4X_FLAG_APP_CLASS_CONSOLE: u32 = 0x00000001;
const R4X_FLAG_APP_CLASS_GUI: u32 = 0x00000002;
const R4X_FLAG_APP_CLASS_SERVICE: u32 = 0x00000004;
const R4X_KNOWN_FLAGS: u32 = R4X_FLAG_APP_CLASS_CONSOLE | R4X_FLAG_APP_CLASS_GUI | R4X_FLAG_APP_CLASS_SERVICE;
const R4M_SECTION_FLAG_ALLOC: u32 = 0x00000001;
const R4M_SECTION_FLAG_EXEC: u32 = 0x00000002;
const R4M_SECTION_FLAG_WRITE: u32 = 0x00000004;
const R4M_SECTION_FLAG_BSS: u32 = 0x00000008;
const R4M_RELOC_ABS64: u32 = 1;
const R4M_RELOC_REL32: u32 = 2;
const R4M_RELOC_BASE_REL64: u32 = 3;
const R4M_RELOC_IMPORT_SLOT64: u32 = 4;
// Ressourcenbereich (0.61.12): eine non-alloc-Section .rsrc mit flachem
// Verzeichnis. Layoutwahrheit ist Contract/ABI/R4M0.txt - der Gastpacker
// r4pack_core schreibt DASSELBE Layout und muss bytegleich bleiben.
const RSRC_SECTION_NAME: []const u8 = ".rsrc";
const RSRC_ENTRY_SIZE: usize = 16;
const RSRC_MAX_ENTRIES: usize = 64;
const RSRC_TYPE_ICON: u16 = 1;
const RSRC_TYPE_HELP: u16 = 2;
const RSRC_TYPE_FILE: u16 = 3;
const RSRC_MAX_NAME_LEN: usize = 63;
const ELF_ET_REL: u16 = 1;
const ELF_SHT_SYMTAB: u32 = 2;
const ELF_SHT_RELA: u32 = 4;
const ELF_SHT_NOBITS: u32 = 8;
const ELF_R_X86_64_64: u32 = 1;
const ELF_R_X86_64_PC32: u32 = 2;
const ELF_R_X86_64_PLT32: u32 = 4;
const ELF_R_X86_64_REX_GOTPCRELX: u32 = 42;

const RelaxedGotPcRelxForm = enum {
    rip_relative,
    absolute_imm32,
    other,
};

const Format = enum {
    r4x,
    r4l,
    r4d,
    r4p,
};

const AppClass = enum {
    auto,
    console,
    gui,
    service,
};

const DriverType = enum(u16) {
    audio = 1,
    storage = 2,
    input = 3,
    synth = 4,
    net = 5,
    display = 6,
    misc = 255,
};

const ProtocolCategory = enum(u16) {
    net = 1,
    usb = 2,
    audio = 3,
    data = 4,
    misc = 255,
};

const ModuleKind = enum(u16) {
    r4x = 1,
    r4l = 2,
    r4d = 3,
    r4p = 4,
    platform_api_provider_reserved = 5,
    kernel_module_reserved = 6,
};

const ModuleExport = struct {
    name: []const u8,
    section: ?[]const u8,
    offset: u32,
    version: u32,
    /// Nur beim ELF-Eingang gesetzt. Vor writeR4M wird das Symbol in die
    /// konkrete R4M0-Section plus Offset aufgeloest.
    elf_symbol: ?[]const u8 = null,
};

const ModuleImport = struct {
    module: []const u8,
    symbol: []const u8,
    min_version: u32,
    flags: u32,
};

const ModuleRelocation = struct {
    kind: u32,
    patch_section: []const u8,
    patch_offset: u32,
    target_section: []const u8,
    target_offset: u32,
    addend: i32,
};

const InputSection = struct {
    name: []const u8,
    data: []const u8,
    mem_size: u32,
    alignment: u32,
    flags: u32,
};

/// Eine Ressource, wie sie von der Kommandozeile kommt; die Bytes werden
/// erst beim Bau der .rsrc-Section gelesen und validiert.
const ResourceSpec = struct {
    typ: u16,
    /// Nur fuer RSRC_TYPE_FILE; Icons und Help sind namenlos.
    name: []const u8,
    path: []const u8,
};

fn wU16(buf: []u8, off: usize, value: u16) void {
    std.mem.writeInt(u16, buf[off..][0..2], value, .little);
}

fn wU32(buf: []u8, off: usize, value: u32) void {
    std.mem.writeInt(u32, buf[off..][0..4], value, .little);
}

fn rU16(buf: []const u8, off: usize) u16 {
    return std.mem.readInt(u16, buf[off..][0..2], .little);
}

fn rU32(buf: []const u8, off: usize) u32 {
    return std.mem.readInt(u32, buf[off..][0..4], .little);
}

fn rU64(buf: []const u8, off: usize) u64 {
    return std.mem.readInt(u64, buf[off..][0..8], .little);
}

fn rI64(buf: []const u8, off: usize) i64 {
    return @bitCast(rU64(buf, off));
}

pub fn main(init: std.process.Init) !void {
    const a = init.gpa;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    var output_path: ?[]const u8 = null;
    var code_path: ?[]const u8 = null;
    var rodata_path: ?[]const u8 = null;
    var data_path: ?[]const u8 = null;
    var elf_path: ?[]const u8 = null;
    var inspect_path: ?[]const u8 = null;
    var format: Format = .r4x;
    var emit_common_container = false;
    var app_class: AppClass = .auto;
    var driver_type: DriverType = .misc;
    var driver_name: []const u8 = "DRIVER";
    var module_name: ?[]const u8 = null;
    var bss_size: u32 = 0;
    var r4d_init_code_offset: u32 = 0;
    var r4d_shutdown_code_offset: ?u32 = null;
    var protocol_name: []const u8 = "PROTOCOL";
    var protocol_role: []const u8 = "misc.protocol";
    var protocol_category: ProtocolCategory = .misc;
    var r4p_init_code_offset: u32 = 0;
    var r4p_shutdown_code_offset: ?u32 = null;
    var r4p_query_code_offset: ?u32 = null;
    var r4p_dispatch_code_offset: ?u32 = null;
    var dependencies: [MAX_PROTOCOL_DEPENDENCIES][]const u8 = undefined;
    var dependency_count: usize = 0;
    const metadata = try init.arena.allocator().alloc([]const u8, args.len);
    var metadata_count: usize = 0;
    var module_imports: [MAX_MODULE_IMPORTS]ModuleImport = undefined;
    var module_import_count: usize = 0;
    var module_exports: [MAX_MODULE_EXPORTS]ModuleExport = undefined;
    var module_export_count: usize = 0;
    var module_relocations: [MAX_MODULE_RELOCATIONS]ModuleRelocation = undefined;
    var module_relocation_count: usize = 0;
    var resource_specs: [RSRC_MAX_ENTRIES]ResourceSpec = undefined;
    var icon_count: usize = 0;
    var help_count: usize = 0;
    var file_resource_count: usize = 0;
    var resource_count: usize = 0;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--output")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            output_path = args[i];
        } else if (std.mem.eql(u8, arg, "--code")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            code_path = args[i];
        } else if (std.mem.eql(u8, arg, "--rodata")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            rodata_path = args[i];
        } else if (std.mem.eql(u8, arg, "--data")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            data_path = args[i];
        } else if (std.mem.eql(u8, arg, "--elf") or std.mem.eql(u8, arg, "--object")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            elf_path = args[i];
        } else if (std.mem.eql(u8, arg, "--inspect")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            inspect_path = args[i];
        } else if (std.mem.eql(u8, arg, "--r4m") or std.mem.eql(u8, arg, "--common-module")) {
            emit_common_container = true;
        } else if (std.mem.eql(u8, arg, "--kind")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            format = parseModuleKindFormat(args[i]) orelse return error.BadArgs;
            if (format == .r4l) emit_common_container = true;
        } else if (std.mem.eql(u8, arg, "--app-class")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            app_class = parseAppClass(args[i]) orelse return error.BadArgs;
        } else if (std.mem.eql(u8, arg, "--format")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            format = parseFormat(args[i]) orelse return error.BadArgs;
            if (format == .r4l) emit_common_container = true;
        } else if (std.mem.eql(u8, arg, "--r4x")) {
            format = .r4x;
        } else if (std.mem.eql(u8, arg, "--r4l")) {
            format = .r4l;
            emit_common_container = true;
        } else if (std.mem.eql(u8, arg, "--r4d")) {
            format = .r4d;
        } else if (std.mem.eql(u8, arg, "--r4p")) {
            format = .r4p;
        } else if (std.mem.eql(u8, arg, "--driver-type")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            driver_type = parseDriverType(args[i]) orelse return error.BadArgs;
        } else if (std.mem.eql(u8, arg, "--name")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            driver_name = args[i];
            protocol_name = args[i];
            module_name = args[i];
        } else if (std.mem.eql(u8, arg, "--module-name")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            module_name = args[i];
        } else if (std.mem.eql(u8, arg, "--role") or std.mem.eql(u8, arg, "--protocol-role")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            protocol_role = args[i];
        } else if (std.mem.eql(u8, arg, "--category") or std.mem.eql(u8, arg, "--protocol-category")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            protocol_category = parseProtocolCategory(args[i]) orelse return error.BadArgs;
        } else if (std.mem.eql(u8, arg, "--dependency")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (dependency_count >= dependencies.len) return error.TooManyDependencies;
            i += 1;
            dependencies[dependency_count] = args[i];
            dependency_count += 1;
        } else if (std.mem.eql(u8, arg, "--meta")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (metadata_count >= metadata.len) return error.TooManyMetadataEntries;
            i += 1;
            metadata[metadata_count] = args[i];
            metadata_count += 1;
        } else if (std.mem.eql(u8, arg, "--init-offset")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            const parsed = try std.fmt.parseInt(u32, args[i], 10);
            r4d_init_code_offset = parsed;
            r4p_init_code_offset = parsed;
        } else if (std.mem.eql(u8, arg, "--shutdown-offset")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            const parsed = try std.fmt.parseInt(u32, args[i], 10);
            r4d_shutdown_code_offset = parsed;
            r4p_shutdown_code_offset = parsed;
        } else if (std.mem.eql(u8, arg, "--query-offset")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            r4p_query_code_offset = try std.fmt.parseInt(u32, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--dispatch-offset")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            r4p_dispatch_code_offset = try std.fmt.parseInt(u32, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--bss-size")) {
            if (i + 1 >= args.len) return error.BadArgs;
            i += 1;
            bss_size = try std.fmt.parseInt(u32, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--export")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (module_export_count >= module_exports.len) return error.TooManyExports;
            i += 1;
            module_exports[module_export_count] = try parseModuleExport(args[i]);
            module_export_count += 1;
        } else if (std.mem.eql(u8, arg, "--import")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (module_import_count >= module_imports.len) return error.TooManyImports;
            i += 1;
            module_imports[module_import_count] = parseModuleImport(args[i]) orelse return error.BadArgs;
            module_import_count += 1;
        } else if (std.mem.eql(u8, arg, "--reloc")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (module_relocation_count >= module_relocations.len) return error.TooManyRelocations;
            i += 1;
            module_relocations[module_relocation_count] = try parseModuleRelocation(args[i]);
            module_relocation_count += 1;
        } else if (std.mem.eql(u8, arg, "--icon")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (resource_count >= resource_specs.len) return error.TooManyResources;
            i += 1;
            resource_specs[resource_count] = .{ .typ = RSRC_TYPE_ICON, .name = "", .path = args[i] };
            resource_count += 1;
            icon_count += 1;
        } else if (std.mem.eql(u8, arg, "--help-file")) {
            if (i + 1 >= args.len) return error.BadArgs;
            if (resource_count >= resource_specs.len) return error.TooManyResources;
            if (help_count != 0) {
                std.debug.print("--help-file given twice; a module carries at most one helpfile\n", .{});
                return error.BadArgs;
            }
            i += 1;
            resource_specs[resource_count] = .{ .typ = RSRC_TYPE_HELP, .name = "", .path = args[i] };
            resource_count += 1;
            help_count += 1;
        } else if (std.mem.eql(u8, arg, "--resource")) {
            // Zwei Argumente (Name, Pfad) statt NAME:pfad - ein Windows-Pfad
            // enthaelt selbst Doppelpunkte.
            if (i + 2 >= args.len) return error.BadArgs;
            if (resource_count >= resource_specs.len) return error.TooManyResources;
            i += 1;
            const resource_name = args[i];
            i += 1;
            resource_specs[resource_count] = .{ .typ = RSRC_TYPE_FILE, .name = resource_name, .path = args[i] };
            resource_count += 1;
            file_resource_count += 1;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return error.BadArgs;
        }
    }

    if (inspect_path) |path| {
        const image = cwd.readFileAlloc(io, path, a, .unlimited) catch |err| {
            std.debug.print("Cannot read module file '{s}': {s}\n", .{ path, @errorName(err) });
            return err;
        };
        defer a.free(image);
        try inspectR4M(path, image);
        return;
    }

    const out = output_path orelse {
        std.debug.print("--output missing\n", .{});
        return error.BadArgs;
    };
    if (code_path != null and elf_path != null) {
        std.debug.print("--code and --elf cannot be used together\n", .{});
        return error.BadArgs;
    }
    if (elf_path != null and (rodata_path != null or data_path != null)) {
        std.debug.print("--rodata/--data cannot be combined with --elf\n", .{});
        return error.BadArgs;
    }

    const code: []const u8 = if (code_path) |code_file| blk: {
        const bytes = cwd.readFileAlloc(io, code_file, a, .unlimited) catch |err| {
            std.debug.print("Cannot read code file '{s}': {s}\n", .{ code_file, @errorName(err) });
            return err;
        };
        break :blk bytes;
    } else &.{};
    defer if (code_path != null) a.free(code);

    const rodata: []const u8 = if (rodata_path) |path| blk: {
        const bytes = cwd.readFileAlloc(io, path, a, .unlimited) catch |err| {
            std.debug.print("Cannot read rodata file '{s}': {s}\n", .{ path, @errorName(err) });
            return err;
        };
        break :blk bytes;
    } else &.{};
    defer if (rodata_path != null) a.free(rodata);

    const data: []const u8 = if (data_path) |path| blk: {
        const bytes = cwd.readFileAlloc(io, path, a, .unlimited) catch |err| {
            std.debug.print("Cannot read data file '{s}': {s}\n", .{ path, @errorName(err) });
            return err;
        };
        break :blk bytes;
    } else &.{};
    defer if (data_path != null) a.free(data);

    const elf: []const u8 = if (elf_path) |path| blk: {
        const bytes = cwd.readFileAlloc(io, path, a, .unlimited) catch |err| {
            std.debug.print("Cannot read ELF/object file '{s}' : {s}\n", .{ path, @errorName(err) });
            return err;
        };
        break :blk bytes;
    } else &.{};
    defer if (elf_path != null) a.free(elf);

    if (code_path == null and elf_path == null) {
        std.debug.print("--code or --elf missing\n", .{});
        return error.BadArgs;
    }
    if (code_path != null and code.len == 0) return error.EmptyCode;
    if (code.len > std.math.maxInt(u32)) return error.CodeTooLarge;
    if (rodata.len > std.math.maxInt(u32) or data.len > std.math.maxInt(u32)) return error.CodeTooLarge;

    // Die .rsrc-Bytes entstehen VOR dem Sectionaufbau, damit beide Pfade
    // (raw und ELF) dieselbe Section anhaengen.
    const rsrc_data: ?[]u8 = if (resource_count != 0)
        try buildResourceSection(a, cwd, io, resource_specs[0..resource_count])
    else
        null;
    defer if (rsrc_data) |bytes| a.free(bytes);

    if (emit_common_container) {
        var raw_sections_buf: [5]InputSection = undefined;
        var sections_owned: ?[]InputSection = null;
        defer if (sections_owned) |sections| a.free(sections);
        var elf_relocations_owned: ?[]ModuleRelocation = null;
        defer if (elf_relocations_owned) |relocations| a.free(relocations);
        var combined_relocations_owned: ?[]ModuleRelocation = null;
        defer if (combined_relocations_owned) |relocations| a.free(relocations);

        const sections = if (elf_path != null) blk: {
            const parsed = try parseElfSections(a, elf);
            sections_owned = parsed;
            break :blk parsed;
        } else blk: {
            var section_count: usize = 1;
            raw_sections_buf[0] = .{
                .name = ".text",
                .data = code,
                .mem_size = @intCast(code.len),
                .alignment = 16,
                .flags = R4M_SECTION_FLAG_ALLOC | R4M_SECTION_FLAG_EXEC,
            };
            if (rodata.len != 0) {
                raw_sections_buf[section_count] = .{
                    .name = ".rodata",
                    .data = rodata,
                    .mem_size = @intCast(rodata.len),
                    .alignment = 16,
                    .flags = R4M_SECTION_FLAG_ALLOC,
                };
                section_count += 1;
            }
            if (data.len != 0) {
                raw_sections_buf[section_count] = .{
                    .name = ".data",
                    .data = data,
                    .mem_size = @intCast(data.len),
                    .alignment = 16,
                    .flags = R4M_SECTION_FLAG_ALLOC | R4M_SECTION_FLAG_WRITE,
                };
                section_count += 1;
            }
            if (bss_size != 0) {
                raw_sections_buf[section_count] = .{
                    .name = ".bss",
                    .data = &.{},
                    .mem_size = bss_size,
                    .alignment = 16,
                    .flags = R4M_SECTION_FLAG_ALLOC | R4M_SECTION_FLAG_WRITE | R4M_SECTION_FLAG_BSS,
                };
                section_count += 1;
            }
            break :blk raw_sections_buf[0..section_count];
        };
        // .rsrc als LETZTE Section anhaengen, ohne alloc-Flag. Der ELF-Pfad
        // liefert ein eigenes Array, der raw-Pfad den Stackpuffer - beide
        // bekommen dieselbe Erweiterung.
        const sections_final = if (rsrc_data) |bytes| blk: {
            const extended = try a.alloc(InputSection, sections.len + 1);
            @memcpy(extended[0..sections.len], sections);
            extended[sections.len] = .{
                .name = RSRC_SECTION_NAME,
                .data = bytes,
                .mem_size = @intCast(bytes.len),
                .alignment = 16,
                .flags = 0,
            };
            if (sections_owned) |owned| a.free(owned);
            sections_owned = extended;
            break :blk extended;
        } else sections;

        if (elf_path != null) {
            try resolveElfExportSymbols(elf, sections_final, module_exports[0..module_export_count]);
        } else {
            for (module_exports[0..module_export_count]) |exp| {
                if (exp.elf_symbol != null) return error.SymbolicExportRequiresElf;
            }
        }

        const relocations = if (elf_path != null) blk: {
            const parsed = try parseElfRelocations(a, elf, sections_final);
            elf_relocations_owned = parsed;
            if (module_relocation_count == 0) break :blk parsed;
            const total = module_relocation_count + parsed.len;
            const combined = try a.alloc(ModuleRelocation, total);
            @memcpy(combined[0..module_relocation_count], module_relocations[0..module_relocation_count]);
            @memcpy(combined[module_relocation_count..total], parsed);
            combined_relocations_owned = combined;
            break :blk combined;
        } else module_relocations[0..module_relocation_count];

        try writeR4M(cwd, io, a, .{
            .out = out,
            .format = format,
            .sections = sections_final,
            .module_name = module_name,
            .driver_name = driver_name,
            .protocol_name = protocol_name,
            .app_class = app_class,
            .imports = module_imports[0..module_import_count],
            .exports = module_exports[0..module_export_count],
            .relocations = relocations,
            .metadata = metadata[0..metadata_count],
        });
        return;
    }

    std.debug.print("Legacy module format not supported; use --r4m/--kind for R4M0 modules\n", .{});
    return error.LegacyModuleFormatUnsupported;
}

fn parseFormat(value: []const u8) ?Format {
    if (std.ascii.eqlIgnoreCase(value, "r4x")) return .r4x;
    if (std.ascii.eqlIgnoreCase(value, "r4l")) return .r4l;
    if (std.ascii.eqlIgnoreCase(value, "r4d")) return .r4d;
    if (std.ascii.eqlIgnoreCase(value, "r4p")) return .r4p;
    return null;
}

fn parseModuleKindFormat(value: []const u8) ?Format {
    if (std.ascii.eqlIgnoreCase(value, "app")) return .r4x;
    if (std.ascii.eqlIgnoreCase(value, "program")) return .r4x;
    if (std.ascii.eqlIgnoreCase(value, "library")) return .r4l;
    if (std.ascii.eqlIgnoreCase(value, "driver")) return .r4d;
    if (std.ascii.eqlIgnoreCase(value, "protocol")) return .r4p;
    return parseFormat(value);
}

fn parseAppClass(value: []const u8) ?AppClass {
    if (std.ascii.eqlIgnoreCase(value, "auto")) return .auto;
    if (std.ascii.eqlIgnoreCase(value, "console")) return .console;
    if (std.ascii.eqlIgnoreCase(value, "gui")) return .gui;
    if (std.ascii.eqlIgnoreCase(value, "service")) return .service;
    return null;
}

fn appClassFlags(value: AppClass) u32 {
    return switch (value) {
        .auto => 0,
        .console => R4X_FLAG_APP_CLASS_CONSOLE,
        .gui => R4X_FLAG_APP_CLASS_GUI,
        .service => R4X_FLAG_APP_CLASS_SERVICE,
    };
}

fn parseDriverType(value: []const u8) ?DriverType {
    if (std.ascii.eqlIgnoreCase(value, "audio")) return .audio;
    if (std.ascii.eqlIgnoreCase(value, "storage")) return .storage;
    if (std.ascii.eqlIgnoreCase(value, "input")) return .input;
    if (std.ascii.eqlIgnoreCase(value, "synth")) return .synth;
    if (std.ascii.eqlIgnoreCase(value, "net")) return .net;
    if (std.ascii.eqlIgnoreCase(value, "display")) return .display;
    if (std.ascii.eqlIgnoreCase(value, "misc")) return .misc;
    return null;
}

fn parseProtocolCategory(value: []const u8) ?ProtocolCategory {
    if (std.ascii.eqlIgnoreCase(value, "net")) return .net;
    if (std.ascii.eqlIgnoreCase(value, "network")) return .net;
    if (std.ascii.eqlIgnoreCase(value, "usb")) return .usb;
    if (std.ascii.eqlIgnoreCase(value, "audio")) return .audio;
    if (std.ascii.eqlIgnoreCase(value, "synth")) return .audio;
    if (std.ascii.eqlIgnoreCase(value, "data")) return .data;
    if (std.ascii.eqlIgnoreCase(value, "misc")) return .misc;
    if (std.ascii.eqlIgnoreCase(value, "test")) return .misc;
    return null;
}

const R4MOptions = struct {
    out: []const u8,
    format: Format,
    sections: []const InputSection,
    module_name: ?[]const u8,
    driver_name: []const u8,
    protocol_name: []const u8,
    app_class: AppClass,
    imports: []const ModuleImport,
    exports: []const ModuleExport,
    relocations: []const ModuleRelocation,
    metadata: []const []const u8,
};

fn writeR4M(cwd: std.Io.Dir, io: std.Io, a: std.mem.Allocator, opts: R4MOptions) !void {
    const kind = moduleKindFromFormat(opts.format);
    const name = opts.module_name orelse switch (opts.format) {
        .r4x => "APP",
        .r4l => "LIB",
        .r4d => opts.driver_name,
        .r4p => opts.protocol_name,
    };
    if (name.len == 0) return error.BadModuleName;

    const section_count: usize = opts.sections.len;
    const entry_count: usize = 1;
    const import_count = opts.imports.len;
    const export_count = opts.exports.len;
    const reloc_count = opts.relocations.len;
    if (import_count > MAX_MODULE_IMPORTS or export_count > MAX_MODULE_EXPORTS or reloc_count > std.math.maxInt(u32)) return error.BadArgs;
    if (section_count == 0) return error.BadR4MSectionTable;

    var string_len: usize = 0;
    string_len += name.len + 1;
    for (opts.imports) |import| {
        string_len += import.module.len + 1;
        string_len += import.symbol.len + 1;
    }
    for (opts.exports) |exp| {
        string_len += exp.name.len + 1;
    }
    for (opts.metadata) |entry| {
        string_len += entry.len + 1;
    }

    const section_off = R4M_HEADER_SIZE;
    const entry_off = section_off + section_count * R4M_SECTION_SIZE;
    const import_off = entry_off + entry_count * R4M_ENTRY_SIZE;
    const export_off = import_off + import_count * R4M_IMPORT_SIZE;
    const reloc_off = export_off + export_count * R4M_EXPORT_SIZE;
    var section_file_offsets: [64]u32 = undefined;
    if (section_count > section_file_offsets.len) return error.TooManySections;
    var cursor = alignForward(reloc_off + reloc_count * R4M_RELOCATION_SIZE, 16);
    for (opts.sections, 0..) |section, index| {
        if (section.mem_size < section.data.len) return error.BadR4MSectionSize;
        if (section.alignment == 0 or !std.math.isPowerOfTwo(section.alignment)) return error.BadR4MSectionAlignment;
        if (section.data.len > std.math.maxInt(u32)) return error.CodeTooLarge;
        if (section.data.len == 0) {
            section_file_offsets[index] = 0;
        } else {
            cursor = alignForward(cursor, @intCast(section.alignment));
            section_file_offsets[index] = @intCast(cursor);
            cursor += section.data.len;
        }
    }
    const string_off = cursor;
    const total_len = string_off + string_len;
    if (total_len > std.math.maxInt(u32)) return error.ImageTooLarge;

    const image = try a.alloc(u8, total_len);
    defer a.free(image);
    @memset(image, 0);

    var string_cursor = string_off;
    const module_name_off = putZ(image, &string_cursor, name);
    _ = module_name_off;

    var import_module_offsets: [MAX_MODULE_IMPORTS]u32 = undefined;
    var import_symbol_offsets: [MAX_MODULE_IMPORTS]u32 = undefined;
    for (opts.imports, 0..) |import, index| {
        import_module_offsets[index] = @intCast(putZ(image, &string_cursor, import.module));
        import_symbol_offsets[index] = @intCast(putZ(image, &string_cursor, import.symbol));
    }

    var export_name_offsets: [MAX_MODULE_EXPORTS]u32 = undefined;
    for (opts.exports, 0..) |exp, index| {
        export_name_offsets[index] = @intCast(putZ(image, &string_cursor, exp.name));
    }
    for (opts.metadata) |entry| {
        const off = putZ(image, &string_cursor, entry);
        _ = off;
    }

    @memcpy(image[0..4], "R4M0");
    wU16(image, 4, R4M_VERSION);
    wU16(image, 6, ARCH_X86_64);
    wU16(image, 8, @intFromEnum(kind));
    wU16(image, 10, R4M_HEADER_SIZE);
    wU32(image, 12, r4mFlags(opts.format, opts.app_class));
    wU32(image, 16, @intCast(section_off));
    wU32(image, 20, @intCast(section_count));
    wU32(image, 24, if (import_count == 0) 0 else @as(u32, @intCast(import_off)));
    wU32(image, 28, @intCast(import_count));
    wU32(image, 32, if (export_count == 0) 0 else @as(u32, @intCast(export_off)));
    wU32(image, 36, @intCast(export_count));
    wU32(image, 40, if (reloc_count == 0) 0 else @as(u32, @intCast(reloc_off)));
    wU32(image, 44, @intCast(reloc_count));
    wU32(image, 48, @intCast(entry_off));
    wU32(image, 52, @intCast(entry_count));
    wU32(image, 56, @intCast(string_off));
    wU32(image, 60, @intCast(string_len));

    var entry_section_index: u32 = 0;
    for (opts.sections, 0..) |section, index| {
        if ((section.flags & R4M_SECTION_FLAG_EXEC) != 0) {
            entry_section_index = @intCast(index);
            break;
        }
    }
    for (opts.sections, 0..) |section, index| {
        writeSection(
            image,
            section_off + index * R4M_SECTION_SIZE,
            section.name,
            section.flags,
            section_file_offsets[index],
            @intCast(section.data.len),
            section.mem_size,
            section.alignment,
        );
        if (section.data.len != 0) {
            const off: usize = @intCast(section_file_offsets[index]);
            @memcpy(image[off .. off + section.data.len], section.data);
        }
    }

    writeEntry(image, entry_off, entryKindFromFormat(opts.format), entry_section_index, 0, 0);
    for (opts.imports, 0..) |_, index| {
        const off = import_off + index * R4M_IMPORT_SIZE;
        wU32(image, off + 0, import_module_offsets[index]);
        wU32(image, off + 4, import_symbol_offsets[index]);
        wU32(image, off + 8, opts.imports[index].min_version);
        wU32(image, off + 12, opts.imports[index].flags);
    }
    for (opts.exports, 0..) |exp, index| {
        const off = export_off + index * R4M_EXPORT_SIZE;
        const export_section = if (exp.section) |section_name|
            resolveSectionIndex(opts.sections, section_name) orelse return error.BadExportSection
        else
            entry_section_index;
        wU32(image, off + 0, export_name_offsets[index]);
        wU32(image, off + 4, export_section);
        wU32(image, off + 8, exp.offset);
        wU32(image, off + 12, exp.version);
    }
    for (opts.relocations, 0..) |reloc, index| {
        const patch_section = resolveSectionIndex(opts.sections, reloc.patch_section) orelse return error.BadRelocationSection;
        const target_section = if (reloc.kind == R4M_RELOC_IMPORT_SLOT64)
            try parseImportRelocationTarget(reloc.target_section, import_count)
        else
            resolveSectionIndex(opts.sections, reloc.target_section) orelse return error.BadRelocationSection;
        const off = reloc_off + index * R4M_RELOCATION_SIZE;
        wU32(image, off + 0, reloc.kind);
        wU32(image, off + 4, patch_section);
        wU32(image, off + 8, reloc.patch_offset);
        wU32(image, off + 12, target_section);
        wU32(image, off + 16, reloc.target_offset);
        wU32(image, off + 20, @bitCast(reloc.addend));
    }

    try inspectR4M(opts.out, image);
    try cwd.writeFile(io, .{ .sub_path = opts.out, .data = image });
    std.debug.print("R4M0 created: {s} ({s}, {d} code bytes, sections={d}, imports={d}, exports={d}, relocs={d})\n", .{
        opts.out,
        @tagName(opts.format),
        totalSectionDataSize(opts.sections),
        section_count,
        import_count,
        export_count,
        reloc_count,
    });
}

/// Baut den Inhalt der .rsrc-Section nach Contract/ABI/R4M0.txt.
///
/// Das Layout laesst bewusst keinen Freiheitsgrad: Eintraege erst icons nach
/// Index, dann help, dann files in Ankunftsreihenfolge; Namen in
/// Eintragsreihenfolge; Blobs in Eintragsreihenfolge, je 16-aligned; alle
/// Paddingbytes null. Nur so kann der Gastpacker r4pack_core fuer gleiche
/// Eingaben bytegleich bleiben.
fn buildResourceSection(a: std.mem.Allocator, cwd: std.Io.Dir, io: std.Io, specs: []const ResourceSpec) ![]u8 {
    var ordered: [RSRC_MAX_ENTRIES]ResourceSpec = undefined;
    var ordered_count: usize = 0;
    // Stabile Vertragsreihenfolge unabhaengig von der Argumentreihenfolge.
    inline for (.{ RSRC_TYPE_ICON, RSRC_TYPE_HELP, RSRC_TYPE_FILE }) |wanted| {
        for (specs) |spec| {
            if (spec.typ == wanted) {
                ordered[ordered_count] = spec;
                ordered_count += 1;
            }
        }
    }

    var blobs: [RSRC_MAX_ENTRIES][]u8 = undefined;
    var loaded: usize = 0;
    errdefer for (blobs[0..loaded]) |blob| a.free(blob);

    var icon_index: u16 = 0;
    var names_len: usize = 0;
    for (ordered[0..ordered_count], 0..) |spec, index| {
        var bytes = cwd.readFileAlloc(io, spec.path, a, .unlimited) catch |err| {
            std.debug.print("Cannot read resource file '{s}': {s}\n", .{ spec.path, @errorName(err) });
            return err;
        };
        blobs[index] = bytes;
        loaded += 1;
        switch (spec.typ) {
            RSRC_TYPE_ICON => {
                try validateIcoBytes(spec.path, bytes);
                icon_index += 1;
            },
            RSRC_TYPE_HELP => {
                // Projekttextdateien tragen laut Konvention ein BOM; das
                // Terminal soll es nie sehen.
                if (bytes.len >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF) {
                    const stripped = try a.alloc(u8, bytes.len - 3);
                    @memcpy(stripped, bytes[3..]);
                    a.free(bytes);
                    bytes = stripped;
                    blobs[index] = bytes;
                }
            },
            RSRC_TYPE_FILE => {
                try validateResourceName(spec.name);
                for (ordered[0..index]) |prior| {
                    if (prior.typ == RSRC_TYPE_FILE and std.ascii.eqlIgnoreCase(prior.name, spec.name)) {
                        std.debug.print("Duplicate resource name '{s}'\n", .{spec.name});
                        return error.DuplicateResourceName;
                    }
                }
                names_len += spec.name.len + 1;
            },
            else => unreachable,
        }
        if (bytes.len == 0) {
            std.debug.print("Empty resource file '{s}'\n", .{spec.path});
            return error.EmptyResource;
        }
        if (bytes.len > std.math.maxInt(u32)) return error.CodeTooLarge;
    }

    // Layout berechnen: Header, Records, Namen, dann Blobs 16-aligned.
    const header_len = 4 + ordered_count * RSRC_ENTRY_SIZE;
    var cursor = header_len + names_len;
    var data_offs: [RSRC_MAX_ENTRIES]u32 = undefined;
    for (blobs[0..ordered_count], 0..) |blob, index| {
        cursor = alignForward(cursor, 16);
        data_offs[index] = @intCast(cursor);
        cursor += blob.len;
    }
    const total = cursor;
    if (total > std.math.maxInt(u32)) return error.ImageTooLarge;

    const out = try a.alloc(u8, total);
    errdefer a.free(out);
    @memset(out, 0);
    wU32(out, 0, @intCast(ordered_count));
    var name_cursor: usize = header_len;
    icon_index = 0;
    for (ordered[0..ordered_count], 0..) |spec, index| {
        const off = 4 + index * RSRC_ENTRY_SIZE;
        wU16(out, off + 0, spec.typ);
        var entry_index: u16 = 0;
        var name_off: u32 = 0;
        if (spec.typ == RSRC_TYPE_ICON) {
            entry_index = icon_index;
            icon_index += 1;
        } else if (spec.typ == RSRC_TYPE_FILE) {
            name_off = @intCast(putZ(out, &name_cursor, spec.name));
        }
        wU16(out, off + 2, entry_index);
        wU32(out, off + 4, name_off);
        wU32(out, off + 8, data_offs[index]);
        wU32(out, off + 12, @intCast(blobs[index].len));
        @memcpy(out[data_offs[index] .. data_offs[index] + blobs[index].len], blobs[index]);
    }
    for (blobs[0..ordered_count]) |blob| a.free(blob);
    return out;
}

/// Ressourcenname nach R4M0-Vertrag: 1 bis 63 Bytes druckbares ASCII ohne
/// Pfadtrenner und Doppelpunkt. Dieselbe Regel prueft module_manifest.zig
/// auf Manifestebene; hier faengt sie Direktaufrufer des Builders.
fn validateResourceName(name: []const u8) !void {
    if (name.len == 0 or name.len > RSRC_MAX_NAME_LEN) return error.BadResourceName;
    for (name) |byte| {
        if (byte < 0x21 or byte > 0x7E) return error.BadResourceName;
        if (byte == '/' or byte == '\\' or byte == ':') return error.BadResourceName;
    }
}

/// Prueft ein Icon gegen die Faehigkeiten des SDK-ICO-Parsers (ico.zig):
/// klassischer Container (type=1), KEIN PNG-komprimierter Eintrag, und
/// mindestens ein 32x32-Eintrag in 32 bpp BGRA oder 8 bpp Palette.
/// Ein unpassendes Icon ist ein BAUFEHLER, kein schwarzes Rechteck auf dem
/// Desktop zur Laufzeit.
fn validateIcoBytes(path: []const u8, bytes: []const u8) !void {
    if (bytes.len < 6 or rU16(bytes, 0) != 0 or rU16(bytes, 2) != 1) {
        std.debug.print("Icon '{s}' is not a classic ICO container\n", .{path});
        return error.BadIconFile;
    }
    const entry_count = rU16(bytes, 4);
    if (entry_count == 0) {
        std.debug.print("Icon '{s}' has no entries\n", .{path});
        return error.BadIconFile;
    }
    var usable = false;
    var index: usize = 0;
    while (index < entry_count) : (index += 1) {
        const off = 6 + index * 16;
        if (off + 16 > bytes.len) {
            std.debug.print("Icon '{s}' entry {d} outside file\n", .{ path, index });
            return error.BadIconFile;
        }
        const width: u32 = if (bytes[off] == 0) 256 else bytes[off];
        const height: u32 = if (bytes[off + 1] == 0) 256 else bytes[off + 1];
        const image_off = rU32(bytes, off + 12);
        const image_size = rU32(bytes, off + 8);
        if (@as(u64, image_off) + image_size > bytes.len) {
            std.debug.print("Icon '{s}' entry {d} data outside file\n", .{ path, index });
            return error.BadIconFile;
        }
        const is_png = image_size >= 8 and bytes[image_off] == 0x89 and bytes[image_off + 1] == 'P' and bytes[image_off + 2] == 'N' and bytes[image_off + 3] == 'G';
        if (is_png) {
            std.debug.print("Icon '{s}' entry {d} is PNG-compressed; ico.zig cannot decode PNG entries\n", .{ path, index });
            return error.BadIconFile;
        }
        if (image_size >= 16 and width == 32 and height == 32) {
            const bits = rU16(bytes, @as(usize, image_off) + 14);
            if (bits == 32 or bits == 8) usable = true;
        }
    }
    if (!usable) {
        std.debug.print("Icon '{s}' has no 32x32 entry in 32 bpp BGRA or 8 bpp palette\n", .{path});
        return error.BadIconFile;
    }
}

fn totalSectionDataSize(sections: []const InputSection) usize {
    var total: usize = 0;
    for (sections) |section| total += section.data.len;
    return total;
}

fn resolveSectionIndex(sections: []const InputSection, name: []const u8) ?u32 {
    for (sections, 0..) |section, index| {
        if (std.ascii.eqlIgnoreCase(section.name, name)) return @intCast(index);
    }
    return null;
}

const ElfSectionHeader = struct {
    name: []const u8,
    sh_type: u32,
    flags: u64,
    addr: u64,
    file_off: u64,
    size: u64,
    link: u32,
    info: u32,
    alignment: u64,
    entsize: u64,
};

const ResolvedElfSymbol = struct {
    section: []const u8,
    offset: u32,
};

fn resolveElfExportSymbols(elf: []const u8, sections: []const InputSection, exports: []ModuleExport) !void {
    for (exports) |*exp| {
        const symbol = exp.elf_symbol orelse continue;
        const resolved = try findElfExportSymbol(elf, sections, symbol);
        exp.section = resolved.section;
        exp.offset = resolved.offset;
        exp.elf_symbol = null;
    }
}

fn findElfExportSymbol(elf: []const u8, sections: []const InputSection, wanted: []const u8) !ResolvedElfSymbol {
    if (elf.len < 64) return error.BadElf;
    if (elf[0] != 0x7F or elf[1] != 'E' or elf[2] != 'L' or elf[3] != 'F') return error.BadElfMagic;
    if (elf[4] != 2 or elf[5] != 1 or rU16(elf, 18) != 0x3E) return error.UnsupportedElf;

    const elf_type = rU16(elf, 16);
    const shoff64 = rU64(elf, 40);
    const shentsize = rU16(elf, 58);
    const shnum = rU16(elf, 60);
    const shstrndx = rU16(elf, 62);
    if (shoff64 > std.math.maxInt(usize)) return error.BadElfSectionTable;
    const shoff: usize = @intCast(shoff64);
    if (shentsize < 64 or shnum == 0 or shstrndx >= shnum) return error.BadElfSectionTable;
    try checkRangeUsize(elf.len, shoff, @as(usize, shentsize) * @as(usize, shnum));
    const shstr = sectionBytes(elf, shoff, shentsize, shstrndx) orelse return error.BadElfStringTable;

    var result: ?ResolvedElfSymbol = null;
    var table_index: u16 = 0;
    while (table_index < shnum) : (table_index += 1) {
        const symtab = readElfSectionHeader(elf, shoff, shentsize, shstr, table_index) orelse return error.BadElfSectionTable;
        if (symtab.sh_type != ELF_SHT_SYMTAB) continue;
        if (symtab.entsize < 24 or symtab.size % symtab.entsize != 0 or symtab.link >= shnum) return error.BadElfSymbolTable;
        try checkRangeU64(elf.len, symtab.file_off, symtab.size);
        const strings = sectionBytes(elf, shoff, shentsize, @intCast(symtab.link)) orelse return error.BadElfStringTable;
        const symbol_count = symtab.size / symtab.entsize;
        var symbol_index: u64 = 0;
        while (symbol_index < symbol_count) : (symbol_index += 1) {
            const symbol_off: usize = @intCast(symtab.file_off + symbol_index * symtab.entsize);
            const name = elfSectionName(strings, rU32(elf, symbol_off)) orelse continue;
            if (!std.mem.eql(u8, name, wanted)) continue;
            const binding = elf[symbol_off + 4] >> 4;
            if (binding != 1 and binding != 2) continue;
            const symbol_section = rU16(elf, symbol_off + 6);
            if (symbol_section == 0 or symbol_section >= shnum) return error.BadElfExportSymbol;
            const section_header = readElfSectionHeader(elf, shoff, shentsize, shstr, symbol_section) orelse return error.BadElfSectionTable;
            const r4m_name = r4mElfSectionName(section_header.name) orelse return error.UnsupportedElfExportSection;
            const r4m_index = resolveSectionIndex(sections, r4m_name) orelse return error.UnsupportedElfExportSection;
            const offset64 = try elfSectionOffset(elf_type, rU64(elf, symbol_off + 8), section_header.addr);
            if (offset64 > std.math.maxInt(u32) or offset64 >= sections[@intCast(r4m_index)].mem_size) return error.BadElfExportOffset;
            if (result != null) return error.DuplicateElfExportSymbol;
            result = .{ .section = sections[@intCast(r4m_index)].name, .offset = @intCast(offset64) };
        }
    }
    return result orelse error.ElfExportSymbolNotFound;
}

fn parseElfSections(a: std.mem.Allocator, elf: []const u8) ![]InputSection {
    if (elf.len < 64) return error.BadElf;
    if (elf[0] != 0x7F or elf[1] != 'E' or elf[2] != 'L' or elf[3] != 'F') return error.BadElfMagic;
    if (elf[4] != 2 or elf[5] != 1) return error.UnsupportedElf;
    if (rU16(elf, 18) != 0x3E) return error.UnsupportedElf;

    const shoff64 = rU64(elf, 40);
    const shentsize = rU16(elf, 58);
    const shnum = rU16(elf, 60);
    const shstrndx = rU16(elf, 62);
    if (shoff64 > std.math.maxInt(usize)) return error.BadElfSectionTable;
    const shoff: usize = @intCast(shoff64);
    if (shentsize < 64 or shnum == 0 or shstrndx >= shnum) return error.BadElfSectionTable;
    const section_table_size = @as(usize, shentsize) * @as(usize, shnum);
    try checkRangeUsize(elf.len, shoff, section_table_size);

    const shstr = sectionBytes(elf, shoff, shentsize, shstrndx) orelse return error.BadElfStringTable;
    var section_buf: [64]InputSection = undefined;
    var count: usize = 0;

    var idx: u16 = 0;
    while (idx < shnum) : (idx += 1) {
        const sh = shoff + @as(usize, idx) * shentsize;
        const name_off = rU32(elf, sh + 0);
        const elf_name = elfSectionName(shstr, name_off) orelse continue;
        const name = r4mElfSectionName(elf_name) orelse continue;
        const sh_type = rU32(elf, sh + 4);
        const sh_flags = rU64(elf, sh + 8);
        const file_off64 = rU64(elf, sh + 24);
        const size64 = rU64(elf, sh + 32);
        const align64 = rU64(elf, sh + 48);
        if (size64 > std.math.maxInt(u32)) return error.ElfSectionTooLarge;
        if (align64 > std.math.maxInt(u32)) return error.BadElfSectionAlignment;

        const size: u32 = @intCast(size64);
        if (size == 0) continue;
        const alignment: u32 = if (align64 == 0) 1 else @intCast(align64);
        const flags = r4mFlagsFromElf(name, sh_flags, sh_type);
        const data = if (sh_type == 8) &.{} else blk: {
            if (file_off64 > std.math.maxInt(usize)) return error.BadElfSectionRange;
            const file_off: usize = @intCast(file_off64);
            const size_usize: usize = @intCast(size);
            if (file_off > elf.len or size_usize > elf.len - file_off) return error.BadElfSectionRange;
            break :blk elf[file_off .. file_off + size_usize];
        };
        if (count >= section_buf.len) return error.TooManySections;
        section_buf[count] = .{
            .name = name,
            .data = data,
            .mem_size = size,
            .alignment = alignment,
            .flags = flags,
        };
        count += 1;
    }
    if (count == 0) return error.NoLoadableElfSections;
    const sections = try a.alloc(InputSection, count);
    @memcpy(sections, section_buf[0..count]);
    return sections;
}

fn parseElfRelocations(a: std.mem.Allocator, elf: []const u8, sections: []const InputSection) ![]ModuleRelocation {
    if (elf.len < 64) return error.BadElf;
    if (elf[0] != 0x7F or elf[1] != 'E' or elf[2] != 'L' or elf[3] != 'F') return error.BadElfMagic;
    if (elf[4] != 2 or elf[5] != 1) return error.UnsupportedElf;
    if (rU16(elf, 18) != 0x3E) return error.UnsupportedElf;

    const elf_type = rU16(elf, 16);
    const shoff64 = rU64(elf, 40);
    const shentsize = rU16(elf, 58);
    const shnum = rU16(elf, 60);
    const shstrndx = rU16(elf, 62);
    if (shoff64 > std.math.maxInt(usize)) return error.BadElfSectionTable;
    const shoff: usize = @intCast(shoff64);
    if (shentsize < 64 or shnum == 0 or shstrndx >= shnum) return error.BadElfSectionTable;
    const section_table_size = @as(usize, shentsize) * @as(usize, shnum);
    try checkRangeUsize(elf.len, shoff, section_table_size);

    const shstr = sectionBytes(elf, shoff, shentsize, shstrndx) orelse return error.BadElfStringTable;
    var relocation_capacity: usize = 0;
    var capacity_index: u16 = 0;
    while (capacity_index < shnum) : (capacity_index += 1) {
        const rela = readElfSectionHeader(elf, shoff, shentsize, shstr, capacity_index) orelse return error.BadElfSectionTable;
        if (rela.sh_type != ELF_SHT_RELA) continue;
        if (rela.entsize < 24 or rela.size % rela.entsize != 0) return error.BadElfRelocation;
        const section_count = rela.size / rela.entsize;
        if (section_count > std.math.maxInt(usize) - relocation_capacity) return error.TooManyRelocations;
        relocation_capacity += @intCast(section_count);
    }
    const out = try a.alloc(ModuleRelocation, relocation_capacity);
    errdefer a.free(out);
    var count: usize = 0;

    var idx: u16 = 0;
    while (idx < shnum) : (idx += 1) {
        const rela = readElfSectionHeader(elf, shoff, shentsize, shstr, idx) orelse return error.BadElfSectionTable;
        if (rela.sh_type != ELF_SHT_RELA) continue;
        if (rela.info >= shnum or rela.link >= shnum) return error.BadElfRelocation;

        const patch_header = readElfSectionHeader(elf, shoff, shentsize, shstr, @intCast(rela.info)) orelse return error.BadElfSectionTable;
        const patch_name = r4mElfSectionName(patch_header.name) orelse continue;
        const patch_section_index = resolveSectionIndex(sections, patch_name) orelse return error.BadElfRelocationSection;

        const symtab = readElfSectionHeader(elf, shoff, shentsize, shstr, @intCast(rela.link)) orelse return error.BadElfSectionTable;
        if (symtab.sh_type != ELF_SHT_SYMTAB or symtab.entsize < 24) return error.BadElfSymbolTable;
        try checkRangeU64(elf.len, symtab.file_off, symtab.size);
        try checkRangeU64(elf.len, rela.file_off, rela.size);
        if (rela.entsize < 24 or rela.size % rela.entsize != 0) return error.BadElfRelocation;
        const reloc_count = rela.size / rela.entsize;
        const sym_count = symtab.size / symtab.entsize;

        var rel_index: u64 = 0;
        while (rel_index < reloc_count) : (rel_index += 1) {
            const rel_off: usize = @intCast(rela.file_off + rel_index * rela.entsize);
            const patch_value = rU64(elf, rel_off + 0);
            const info = rU64(elf, rel_off + 8);
            const addend64 = rI64(elf, rel_off + 16);
            const symbol_index = info >> 32;
            const elf_reloc_type: u32 = @intCast(info & 0xffff_ffff);
            const r4m_kind = r4mRelocKindFromElf(elf_reloc_type) orelse {
                if (elf_reloc_type == 0) continue;
                // R_X86_64_REX_GOTPCRELX is a linker-relaxation hint, not a
                // portable description of the final patch. LLD can leave the
                // same relocation type on both RIP-relative LEA displacements
                // and absolute signed-32 immediates (for example ADD/CMP).
                // R4M0 intentionally has no load-address-limited ABS32 kind.
                if (elf_reloc_type == ELF_R_X86_64_REX_GOTPCRELX)
                    return error.UnsupportedRelaxedGotPcRelx;
                return error.UnsupportedElfRelocation;
            };
            if (symbol_index >= sym_count) return error.BadElfRelocation;
            const r4m_addend64 = if (r4m_kind == R4M_RELOC_REL32) addend64 + 4 else addend64;
            if (r4m_addend64 < std.math.minInt(i32) or r4m_addend64 > std.math.maxInt(i32)) return error.BadElfRelocationAddend;

            const sym_off: usize = @intCast(symtab.file_off + symbol_index * symtab.entsize);
            const sym_section_index = rU16(elf, sym_off + 6);
            const sym_value = rU64(elf, sym_off + 8);
            if (sym_section_index == 0 or sym_section_index >= shnum) return error.UnsupportedElfRelocationTarget;
            const target_header = readElfSectionHeader(elf, shoff, shentsize, shstr, sym_section_index) orelse return error.BadElfSectionTable;
            const target_name = r4mElfSectionName(target_header.name) orelse return error.UnsupportedElfRelocationTarget;
            const target_section_index = resolveSectionIndex(sections, target_name) orelse return error.UnsupportedElfRelocationTarget;

            const patch_offset64 = try elfSectionOffset(elf_type, patch_value, patch_header.addr);
            const target_offset64 = try elfSectionOffset(elf_type, sym_value, target_header.addr);
            if (patch_offset64 > std.math.maxInt(u32) or target_offset64 > std.math.maxInt(u32)) return error.BadElfRelocationRange;
            if (patch_offset64 >= sections[@intCast(patch_section_index)].mem_size) return error.BadElfRelocationRange;
            if (target_offset64 >= sections[@intCast(target_section_index)].mem_size) return error.BadElfRelocationRange;
            out[count] = .{
                .kind = r4m_kind,
                .patch_section = sections[@intCast(patch_section_index)].name,
                .patch_offset = @intCast(patch_offset64),
                .target_section = sections[@intCast(target_section_index)].name,
                .target_offset = @intCast(target_offset64),
                .addend = @intCast(r4m_addend64),
            };
            count += 1;
        }
    }

    return try a.realloc(out, count);
}

fn readElfSectionHeader(elf: []const u8, shoff: usize, shentsize: u16, shstr: []const u8, index: usize) ?ElfSectionHeader {
    const sh = shoff + index * @as(usize, shentsize);
    if (sh > elf.len or @as(usize, shentsize) > elf.len - sh) return null;
    const name_off = rU32(elf, sh + 0);
    const name = elfSectionName(shstr, name_off) orelse return null;
    return .{
        .name = name,
        .sh_type = rU32(elf, sh + 4),
        .flags = rU64(elf, sh + 8),
        .addr = rU64(elf, sh + 16),
        .file_off = rU64(elf, sh + 24),
        .size = rU64(elf, sh + 32),
        .link = rU32(elf, sh + 40),
        .info = rU32(elf, sh + 44),
        .alignment = rU64(elf, sh + 48),
        .entsize = rU64(elf, sh + 56),
    };
}

fn r4mRelocKindFromElf(elf_reloc_type: u32) ?u32 {
    return switch (elf_reloc_type) {
        ELF_R_X86_64_64 => R4M_RELOC_ABS64,
        ELF_R_X86_64_PC32, ELF_R_X86_64_PLT32 => R4M_RELOC_REL32,
        else => null,
    };
}

// The four-byte relocation field follows these three instruction bytes.
// This classifier is diagnostic/test evidence only: neither form is
// accepted as an R4M relocation because one ELF relocation type can denote
// both forms in the same linked image.
fn classifyRelaxedGotPcRelx(prefix: [3]u8) RelaxedGotPcRelxForm {
    const rex = prefix[0];
    const opcode = prefix[1];
    const mod_rm = prefix[2];
    const has_rex = (rex & 0xf0) == 0x40;
    const mod = mod_rm >> 6;
    const rm = mod_rm & 0x07;

    if (has_rex and opcode == 0x8d and mod == 0 and rm == 5)
        return .rip_relative;
    if (has_rex and (rex & 0x08) != 0 and opcode == 0x81 and mod == 3)
        return .absolute_imm32;
    return .other;
}

test "REX GOTPCRELX is not blindly mapped to an R4M relocation" {
    try std.testing.expectEqual(@as(?u32, null), r4mRelocKindFromElf(ELF_R_X86_64_REX_GOTPCRELX));

    // Observed final LLD forms from the contract fixture: one is a valid
    // PC-relative displacement, two are absolute signed-32 addresses.
    try std.testing.expectEqual(RelaxedGotPcRelxForm.rip_relative, classifyRelaxedGotPcRelx(.{ 0x48, 0x8d, 0x05 }));
    try std.testing.expectEqual(RelaxedGotPcRelxForm.absolute_imm32, classifyRelaxedGotPcRelx(.{ 0x48, 0x81, 0xc0 }));
    try std.testing.expectEqual(RelaxedGotPcRelxForm.absolute_imm32, classifyRelaxedGotPcRelx(.{ 0x48, 0x81, 0xff }));
}

test "portable ELF relocation mapping remains full-width or relative" {
    try std.testing.expectEqual(@as(?u32, R4M_RELOC_ABS64), r4mRelocKindFromElf(ELF_R_X86_64_64));
    try std.testing.expectEqual(@as(?u32, R4M_RELOC_REL32), r4mRelocKindFromElf(ELF_R_X86_64_PC32));
    try std.testing.expectEqual(@as(?u32, R4M_RELOC_REL32), r4mRelocKindFromElf(ELF_R_X86_64_PLT32));
}

fn elfSectionOffset(elf_type: u16, value: u64, section_addr: u64) !u64 {
    if (elf_type == ELF_ET_REL) return value;
    if (value < section_addr) return error.BadElfRelocationRange;
    return value - section_addr;
}

fn sectionBytes(elf: []const u8, shoff: usize, shentsize: u16, index: u16) ?[]const u8 {
    const sh = shoff + @as(usize, index) * shentsize;
    const file_off64 = rU64(elf, sh + 24);
    const size64 = rU64(elf, sh + 32);
    if (file_off64 > std.math.maxInt(usize) or size64 > std.math.maxInt(usize)) return null;
    const file_off: usize = @intCast(file_off64);
    const size: usize = @intCast(size64);
    if (file_off > elf.len or size > elf.len - file_off) return null;
    return elf[file_off .. file_off + size];
}

fn elfSectionName(strings: []const u8, off_u32: u32) ?[]const u8 {
    const off: usize = @intCast(off_u32);
    if (off >= strings.len) return null;
    const end_rel = std.mem.indexOfScalar(u8, strings[off..], 0) orelse return null;
    return strings[off .. off + end_rel];
}

fn r4mElfSectionName(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, ".text") or std.mem.startsWith(u8, name, ".text.")) return ".text";
    if (std.mem.eql(u8, name, ".rodata") or std.mem.startsWith(u8, name, ".rodata.")) return ".rodata";
    if (std.mem.eql(u8, name, ".data") or std.mem.startsWith(u8, name, ".data.")) return ".data";
    if (std.mem.eql(u8, name, ".bss") or std.mem.startsWith(u8, name, ".bss.")) return ".bss";
    return null;
}

fn r4mFlagsFromElf(name: []const u8, elf_flags: u64, sh_type: u32) u32 {
    var flags: u32 = R4M_SECTION_FLAG_ALLOC;
    if ((elf_flags & 0x4) != 0 or std.mem.eql(u8, name, ".text")) flags |= R4M_SECTION_FLAG_EXEC;
    if ((elf_flags & 0x1) != 0 or std.mem.eql(u8, name, ".data") or std.mem.eql(u8, name, ".bss")) flags |= R4M_SECTION_FLAG_WRITE;
    if (sh_type == 8 or std.mem.eql(u8, name, ".bss")) flags |= R4M_SECTION_FLAG_BSS;
    return flags;
}

fn writeSection(image: []u8, off: usize, name: []const u8, flags: u32, file_off: u32, file_size: u32, mem_size: u32, alignment: u32) void {
    const name_field = image[off..][0..8];
    @memset(name_field, 0);
    const n = @min(name.len, name_field.len);
    @memcpy(name_field[0..n], name[0..n]);
    wU32(image, off + 8, flags);
    wU32(image, off + 12, file_off);
    wU32(image, off + 16, file_size);
    wU32(image, off + 20, mem_size);
    wU32(image, off + 24, alignment);
    wU32(image, off + 28, 0);
}

fn writeEntry(image: []u8, off: usize, kind: u32, section_index: u32, section_offset: u32, flags: u32) void {
    wU32(image, off + 0, kind);
    wU32(image, off + 4, section_index);
    wU32(image, off + 8, section_offset);
    wU32(image, off + 12, flags);
}

fn putZ(image: []u8, cursor: *usize, value: []const u8) usize {
    const off = cursor.*;
    @memcpy(image[off .. off + value.len], value);
    image[off + value.len] = 0;
    cursor.* = off + value.len + 1;
    return off;
}

fn moduleKindFromFormat(format: Format) ModuleKind {
    return switch (format) {
        .r4x => .r4x,
        .r4l => .r4l,
        .r4d => .r4d,
        .r4p => .r4p,
    };
}

fn entryKindFromFormat(format: Format) u32 {
    return switch (format) {
        .r4x => 1,
        .r4l => 2,
        .r4d => 3,
        .r4p => 4,
    };
}

fn r4mFlags(format: Format, app_class: AppClass) u32 {
    return switch (format) {
        .r4x => appClassFlags(app_class),
        else => 0,
    };
}

fn parseModuleExport(value: []const u8) !ModuleExport {
    if (value.len == 0) return error.BadArgs;
    var parts: [4][]const u8 = undefined;
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, value, ':');
    while (it.next()) |part| {
        if (count >= parts.len) return error.BadArgs;
        parts[count] = part;
        count += 1;
    }
    if (count == 1) return .{ .name = value, .section = null, .offset = 0, .version = 1 };
    if (count == 2) {
        if (parts[0].len == 0 or parts[1].len == 0) return error.BadArgs;
        return .{
            .name = parts[0],
            .section = null,
            .offset = try std.fmt.parseInt(u32, parts[1], 10),
            .version = 1,
        };
    }
    if (count == 3 and parts[1].len > 1 and parts[1][0] == '@') {
        if (parts[0].len == 0 or parts[2].len == 0) return error.BadArgs;
        return .{
            .name = parts[0],
            .section = null,
            .offset = 0,
            .version = try std.fmt.parseInt(u32, parts[2], 10),
            .elf_symbol = parts[1][1..],
        };
    }
    if (count == 3 and !looksLikeSectionName(parts[1])) {
        if (parts[0].len == 0 or parts[1].len == 0) return error.BadArgs;
        return .{
            .name = parts[0],
            .section = null,
            .offset = try std.fmt.parseInt(u32, parts[1], 10),
            .version = try std.fmt.parseInt(u32, parts[2], 10),
        };
    }
    if (count == 3 or count == 4) {
        if (parts[0].len == 0 or parts[1].len == 0 or parts[2].len == 0) return error.BadArgs;
        return .{
            .name = parts[0],
            .section = parts[1],
            .offset = try std.fmt.parseInt(u32, parts[2], 10),
            .version = if (count == 4) try std.fmt.parseInt(u32, parts[3], 10) else 1,
        };
    }
    return error.BadArgs;
}

fn looksLikeSectionName(value: []const u8) bool {
    return value.len != 0 and value[0] == '.';
}

fn parseModuleImport(value: []const u8) ?ModuleImport {
    if (value.len == 0) return null;
    var parts: [4][]const u8 = undefined;
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, value, ':');
    while (it.next()) |part| {
        if (count >= parts.len) return null;
        parts[count] = part;
        count += 1;
    }
    if (count >= 2) {
        if (parts[0].len == 0 or parts[1].len == 0) return null;
        return .{
            .module = parts[0],
            .symbol = parts[1],
            .min_version = if (count >= 3) std.fmt.parseInt(u32, parts[2], 10) catch return null else 0,
            .flags = if (count >= 4) std.fmt.parseInt(u32, parts[3], 10) catch return null else 0,
        };
    }
    const idx = std.mem.indexOfScalar(u8, value, '.') orelse return null;
    if (idx == 0 or idx + 1 >= value.len) return null;
    return .{
        .module = value[0..idx],
        .symbol = value[idx + 1 ..],
        .min_version = 0,
        .flags = 0,
    };
}

fn parseModuleRelocation(value: []const u8) !ModuleRelocation {
    var parts: [6][]const u8 = undefined;
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, value, ':');
    while (it.next()) |part| {
        if (count >= parts.len) return error.BadRelocation;
        parts[count] = part;
        count += 1;
    }
    if (count < 5) return error.BadRelocation;
    return .{
        .kind = try parseRelocationKind(parts[0]),
        .patch_section = parts[1],
        .patch_offset = try std.fmt.parseInt(u32, parts[2], 10),
        .target_section = parts[3],
        .target_offset = try std.fmt.parseInt(u32, parts[4], 10),
        .addend = if (count >= 6) try std.fmt.parseInt(i32, parts[5], 10) else 0,
    };
}

fn parseRelocationKind(value: []const u8) !u32 {
    if (std.ascii.eqlIgnoreCase(value, "abs64")) return R4M_RELOC_ABS64;
    if (std.ascii.eqlIgnoreCase(value, "rel32") or std.ascii.eqlIgnoreCase(value, "rip32")) return R4M_RELOC_REL32;
    if (std.ascii.eqlIgnoreCase(value, "base_rel64") or std.ascii.eqlIgnoreCase(value, "baserel64")) return R4M_RELOC_BASE_REL64;
    if (std.ascii.eqlIgnoreCase(value, "import_slot64") or std.ascii.eqlIgnoreCase(value, "import64")) return R4M_RELOC_IMPORT_SLOT64;
    if (std.mem.startsWith(u8, value, "raw")) return std.fmt.parseInt(u32, value[3..], 10);
    return std.fmt.parseInt(u32, value, 10);
}

fn parseImportRelocationTarget(value: []const u8, import_count: usize) !u32 {
    const digits = if (std.mem.startsWith(u8, value, "import"))
        value["import".len..]
    else if (std.mem.startsWith(u8, value, "#"))
        value[1..]
    else
        value;
    if (digits.len == 0) return error.BadRelocationImport;
    const index = try std.fmt.parseInt(u32, digits, 10);
    if (index >= import_count) return error.BadRelocationImport;
    return index;
}

fn alignForward(value: usize, alignment: usize) usize {
    return (value + alignment - 1) & ~(alignment - 1);
}

fn inspectR4M(path: []const u8, image: []const u8) !void {
    if (image.len < 4) return error.BadR4MHeader;
    if (std.mem.eql(u8, image[0..4], "R4X0") or std.mem.eql(u8, image[0..4], "R4D0") or std.mem.eql(u8, image[0..4], "R4P0")) {
        std.debug.print("Legacy module format not supported: {s}\n", .{path});
        return error.LegacyModuleFormatUnsupported;
    }
    if (image.len < R4M_HEADER_SIZE) return error.BadR4MHeader;
    if (!std.mem.eql(u8, image[0..4], "R4M0")) return error.BadR4MMagic;
    const version = rU16(image, 4);
    const arch = rU16(image, 6);
    const kind_raw = rU16(image, 8);
    const header_size = rU16(image, 10);
    const flags = rU32(image, 12);
    const section_off = rU32(image, 16);
    const section_count = rU32(image, 20);
    const import_off = rU32(image, 24);
    const import_count = rU32(image, 28);
    const export_off = rU32(image, 32);
    const export_count = rU32(image, 36);
    const reloc_off = rU32(image, 40);
    const reloc_count = rU32(image, 44);
    const entry_off = rU32(image, 48);
    const entry_count = rU32(image, 52);
    const meta_off = rU32(image, 56);
    const meta_size = rU32(image, 60);

    if (version != R4M_VERSION) return error.BadR4MVersion;
    if (arch != ARCH_X86_64) return error.BadR4MArch;
    if (header_size != R4M_HEADER_SIZE) return error.BadR4MHeader;
    if (moduleKindName(kind_raw) == null) return error.BadR4MKind;
    if (kind_raw == @intFromEnum(ModuleKind.r4x)) {
        if ((flags & ~R4X_KNOWN_FLAGS) != 0) return error.BadR4MFlags;
        if (appClassFlagCount(flags) > 1) return error.BadR4MAppClass;
    }
    if (section_count == 0) return error.BadR4MSectionTable;

    try checkTable(image.len, section_off, section_count, R4M_SECTION_SIZE, true);
    try checkTable(image.len, entry_off, entry_count, R4M_ENTRY_SIZE, true);
    try checkTable(image.len, import_off, import_count, R4M_IMPORT_SIZE, false);
    try checkTable(image.len, export_off, export_count, R4M_EXPORT_SIZE, false);
    try checkTable(image.len, reloc_off, reloc_count, 24, false);
    if (meta_size != 0) try checkRange(image.len, meta_off, meta_size);

    var section_mem_sizes: [64]u32 = undefined;
    if (section_count > section_mem_sizes.len) return error.TooManySections;
    // Ressourcenvertrag: hoechstens EINE Section ohne alloc-Flag, sie heisst
    // .rsrc und traegt sonst keine Flags; jede andere Section muss alloc
    // tragen. Entry, Exports und Relocations duerfen nie auf sie zeigen.
    var rsrc_section: ?usize = null;
    var rsrc_file_off: u32 = 0;
    var rsrc_file_size: u32 = 0;
    var idx: usize = 0;
    while (idx < section_count) : (idx += 1) {
        const off = @as(usize, @intCast(section_off)) + idx * R4M_SECTION_SIZE;
        const section_flags = rU32(image, off + 8);
        const file_off = rU32(image, off + 12);
        const file_size = rU32(image, off + 16);
        const mem_size = rU32(image, off + 20);
        const alignment = rU32(image, off + 24);
        if (mem_size < file_size) return error.BadR4MSectionSize;
        if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) return error.BadR4MSectionAlignment;
        if (file_size != 0) try checkRange(image.len, file_off, file_size);
        section_mem_sizes[idx] = mem_size;
        const name_bytes = image[off .. off + 8];
        const name_end = std.mem.indexOfScalar(u8, name_bytes, 0) orelse 8;
        const section_name = name_bytes[0..name_end];
        if ((section_flags & 0x1) == 0) {
            if (!std.mem.eql(u8, section_name, RSRC_SECTION_NAME)) return error.BadR4MNonAllocSection;
            if (section_flags != 0) return error.BadR4MResourceSectionFlags;
            if (rsrc_section != null) return error.BadR4MDuplicateResourceSection;
            rsrc_section = idx;
            rsrc_file_off = file_off;
            rsrc_file_size = file_size;
        } else if (std.mem.eql(u8, section_name, RSRC_SECTION_NAME)) {
            return error.BadR4MResourceSectionFlags;
        }
    }

    idx = 0;
    while (idx < entry_count) : (idx += 1) {
        const off = @as(usize, @intCast(entry_off)) + idx * R4M_ENTRY_SIZE;
        const section_index = rU32(image, off + 4);
        const section_offset = rU32(image, off + 8);
        if (section_index >= section_count) return error.BadR4MEntrySection;
        if (rsrc_section != null and section_index == rsrc_section.?) return error.BadR4MEntrySection;
        if (section_offset >= section_mem_sizes[@intCast(section_index)]) return error.BadR4MEntryOffset;
    }

    idx = 0;
    while (idx < import_count) : (idx += 1) {
        const off = @as(usize, @intCast(import_off)) + idx * R4M_IMPORT_SIZE;
        try checkZ(image, rU32(image, off + 0));
        try checkZ(image, rU32(image, off + 4));
    }

    idx = 0;
    while (idx < export_count) : (idx += 1) {
        const off = @as(usize, @intCast(export_off)) + idx * R4M_EXPORT_SIZE;
        const name_off = rU32(image, off + 0);
        const section_index = rU32(image, off + 4);
        const section_offset = rU32(image, off + 8);
        try checkZ(image, name_off);
        if (section_index >= section_count) return error.BadR4MExportSection;
        if (rsrc_section != null and section_index == rsrc_section.?) return error.BadR4MExportSection;
        if (section_offset >= section_mem_sizes[@intCast(section_index)]) return error.BadR4MExportOffset;
    }

    var reloc_abs64: u32 = 0;
    var reloc_rel32: u32 = 0;
    var reloc_base64: u32 = 0;
    var reloc_import64: u32 = 0;
    var reloc_unknown: u32 = 0;
    idx = 0;
    while (idx < reloc_count) : (idx += 1) {
        const off = @as(usize, @intCast(reloc_off)) + idx * R4M_RELOCATION_SIZE;
        const reloc_kind = rU32(image, off + 0);
        const patch_section = rU32(image, off + 4);
        const patch_offset = rU32(image, off + 8);
        const target_section = rU32(image, off + 12);
        const target_offset = rU32(image, off + 16);
        if (patch_section >= section_count) return error.BadR4MRelocationSection;
        if (rsrc_section != null and patch_section == rsrc_section.?) return error.BadR4MRelocationSection;
        const patch_size = relocationPatchSize(reloc_kind);
        if (patch_offset > section_mem_sizes[@intCast(patch_section)] or patch_size > section_mem_sizes[@intCast(patch_section)] - patch_offset) return error.BadR4MRelocationOffset;
        if (reloc_kind == R4M_RELOC_IMPORT_SLOT64) {
            if (target_section >= import_count) return error.BadR4MRelocationImport;
        } else {
            if (target_section >= section_count) return error.BadR4MRelocationSection;
            if (rsrc_section != null and target_section == rsrc_section.?) return error.BadR4MRelocationSection;
            if (target_offset >= section_mem_sizes[@intCast(target_section)]) return error.BadR4MRelocationTarget;
        }
        switch (reloc_kind) {
            R4M_RELOC_ABS64 => reloc_abs64 += 1,
            R4M_RELOC_REL32 => reloc_rel32 += 1,
            R4M_RELOC_BASE_REL64 => reloc_base64 += 1,
            R4M_RELOC_IMPORT_SLOT64 => reloc_import64 += 1,
            else => reloc_unknown += 1,
        }
    }

    var rsrc_entry_count: u32 = 0;
    if (rsrc_section != null) {
        rsrc_entry_count = try validateResourceDirectory(image, rsrc_file_off, rsrc_file_size);
    }

    if (kind_raw == @intFromEnum(ModuleKind.r4x)) {
        std.debug.print("R4M0 inspect OK: {s} kind={s} sections={} entries={} imports={} exports={} relocs={} flags=0x{x} r4x.class={s}\n", .{
            path,
            moduleKindName(kind_raw).?,
            section_count,
            entry_count,
            import_count,
            export_count,
            reloc_count,
            flags,
            appClassNameFromFlags(flags),
        });
    } else {
        std.debug.print("R4M0 inspect OK: {s} kind={s} sections={} entries={} imports={} exports={} relocs={} flags=0x{x}\n", .{
            path,
            moduleKindName(kind_raw).?,
            section_count,
            entry_count,
            import_count,
            export_count,
            reloc_count,
            flags,
        });
    }
    if (reloc_count != 0) {
        std.debug.print("  reloc-types: abs64={} rel32={} base_rel64={} import_slot64={} unknown={}\n", .{
            reloc_abs64,
            reloc_rel32,
            reloc_base64,
            reloc_import64,
            reloc_unknown,
        });
    }
    if (rsrc_section != null) {
        try printResourceDirectory(image, rsrc_file_off, rsrc_entry_count);
    }
}

/// Validiert das .rsrc-Verzeichnis strikt gegen den Vertrag: count 1..64,
/// Records vollstaendig im Bereich, Typen bekannt, Vertragsreihenfolge
/// (icons nach Index, dann help, dann files), Namen nur bei Typ file und
/// nullterminiert im Bereich, Blobs 16-aligned und mindestens 1 Byte.
fn validateResourceDirectory(image: []const u8, file_off: u32, file_size: u32) !u32 {
    if (file_size < 4) return error.BadR4MResourceDirectory;
    const base: usize = @intCast(file_off);
    const count = rU32(image, base);
    if (count == 0 or count > RSRC_MAX_ENTRIES) return error.BadR4MResourceDirectory;
    const header_len = 4 + @as(usize, count) * RSRC_ENTRY_SIZE;
    if (header_len > file_size) return error.BadR4MResourceDirectory;

    var expected_icon_index: u16 = 0;
    var seen_help = false;
    var seen_file = false;
    var idx: usize = 0;
    while (idx < count) : (idx += 1) {
        const off = base + 4 + idx * RSRC_ENTRY_SIZE;
        const typ = rU16(image, off + 0);
        const entry_index = rU16(image, off + 2);
        const name_off = rU32(image, off + 4);
        const data_off = rU32(image, off + 8);
        const size = rU32(image, off + 12);
        switch (typ) {
            RSRC_TYPE_ICON => {
                if (seen_help or seen_file) return error.BadR4MResourceOrder;
                if (entry_index != expected_icon_index) return error.BadR4MResourceOrder;
                expected_icon_index += 1;
                if (name_off != 0) return error.BadR4MResourceDirectory;
            },
            RSRC_TYPE_HELP => {
                if (seen_help or seen_file) return error.BadR4MResourceOrder;
                seen_help = true;
                if (entry_index != 0 or name_off != 0) return error.BadR4MResourceDirectory;
            },
            RSRC_TYPE_FILE => {
                seen_file = true;
                if (entry_index != 0) return error.BadR4MResourceDirectory;
                if (name_off == 0 or name_off >= file_size) return error.BadR4MResourceDirectory;
                const name_abs: usize = base + @as(usize, name_off);
                const limit: usize = base + @as(usize, file_size);
                const end = std.mem.indexOfScalar(u8, image[name_abs..limit], 0) orelse return error.BadR4MResourceDirectory;
                if (end == 0 or end > RSRC_MAX_NAME_LEN) return error.BadR4MResourceDirectory;
            },
            else => return error.BadR4MResourceDirectory,
        }
        if (size == 0) return error.BadR4MResourceDirectory;
        if (data_off % 16 != 0) return error.BadR4MResourceAlignment;
        if (@as(u64, data_off) + size > file_size) return error.BadR4MResourceDirectory;
    }
    return count;
}

fn printResourceDirectory(image: []const u8, file_off: u32, count: u32) !void {
    const base: usize = @intCast(file_off);
    std.debug.print("  rsrc: {} entr{s}\n", .{ count, if (count == 1) "y" else "ies" });
    var idx: usize = 0;
    while (idx < count) : (idx += 1) {
        const off = base + 4 + idx * RSRC_ENTRY_SIZE;
        const typ = rU16(image, off + 0);
        const entry_index = rU16(image, off + 2);
        const name_off = rU32(image, off + 4);
        const size = rU32(image, off + 12);
        switch (typ) {
            RSRC_TYPE_ICON => std.debug.print("    icon[{}] {} bytes\n", .{ entry_index, size }),
            RSRC_TYPE_HELP => std.debug.print("    help {} bytes\n", .{size}),
            RSRC_TYPE_FILE => {
                const name_abs: usize = base + @as(usize, name_off);
                const end = std.mem.indexOfScalar(u8, image[name_abs..], 0) orelse unreachable;
                std.debug.print("    file {s} {} bytes\n", .{ image[name_abs .. name_abs + end], size });
            },
            else => unreachable,
        }
    }
}

fn appClassFlagCount(flags: u32) u8 {
    var count: u8 = 0;
    if ((flags & R4X_FLAG_APP_CLASS_CONSOLE) != 0) count += 1;
    if ((flags & R4X_FLAG_APP_CLASS_GUI) != 0) count += 1;
    if ((flags & R4X_FLAG_APP_CLASS_SERVICE) != 0) count += 1;
    return count;
}

fn appClassNameFromFlags(flags: u32) []const u8 {
    if ((flags & R4X_FLAG_APP_CLASS_CONSOLE) != 0) return "console";
    if ((flags & R4X_FLAG_APP_CLASS_GUI) != 0) return "gui";
    if ((flags & R4X_FLAG_APP_CLASS_SERVICE) != 0) return "service";
    return "auto";
}

fn relocationPatchSize(kind: u32) u32 {
    return switch (kind) {
        R4M_RELOC_REL32 => 4,
        R4M_RELOC_ABS64, R4M_RELOC_BASE_REL64, R4M_RELOC_IMPORT_SLOT64 => 8,
        else => 1,
    };
}

fn checkTable(image_len: usize, off: u32, count: u32, item_size: usize, required: bool) !void {
    if (count == 0) {
        if (required) return error.BadR4MTable;
        return;
    }
    if (off == 0) return error.BadR4MTable;
    const bytes = @as(u64, count) * item_size;
    if (bytes > std.math.maxInt(u32)) return error.BadR4MTable;
    try checkRange(image_len, off, @intCast(bytes));
}

fn checkRange(image_len: usize, off_u32: u32, size_u32: u32) !void {
    const off: usize = @intCast(off_u32);
    const size: usize = @intCast(size_u32);
    if (off > image_len or size > image_len - off) return error.BadR4MRange;
}

fn checkRangeU64(image_len: usize, off_u64: u64, size_u64: u64) !void {
    if (off_u64 > std.math.maxInt(usize) or size_u64 > std.math.maxInt(usize)) return error.BadR4MRange;
    try checkRangeUsize(image_len, @intCast(off_u64), @intCast(size_u64));
}

fn checkRangeUsize(image_len: usize, off: usize, size: usize) !void {
    if (off > image_len or size > image_len - off) return error.BadR4MRange;
}

fn checkZ(image: []const u8, off_u32: u32) !void {
    const off: usize = @intCast(off_u32);
    if (off >= image.len) return error.BadR4MString;
    if (std.mem.indexOfScalar(u8, image[off..], 0) == null) return error.BadR4MString;
}

fn moduleKindName(kind: u16) ?[]const u8 {
    return switch (kind) {
        @intFromEnum(ModuleKind.r4x) => "r4x",
        @intFromEnum(ModuleKind.r4l) => "r4l",
        @intFromEnum(ModuleKind.r4d) => "r4d",
        @intFromEnum(ModuleKind.r4p) => "r4p",
        @intFromEnum(ModuleKind.platform_api_provider_reserved) => "platform_api_provider_reserved",
        @intFromEnum(ModuleKind.kernel_module_reserved) => "kernel_module_reserved",
        else => null,
    };
}

test "ELF exports retain a symbolic source until section resolution" {
    const symbolic = try parseModuleExport("API_V1:@acme_api_v1:3");
    try std.testing.expectEqualStrings("API_V1", symbolic.name);
    try std.testing.expectEqualStrings("acme_api_v1", symbolic.elf_symbol.?);
    try std.testing.expectEqual(@as(u32, 3), symbolic.version);
    try std.testing.expect(symbolic.section == null);

    const fixed = try parseModuleExport("Query:.data:40:1");
    try std.testing.expectEqualStrings(".data", fixed.section.?);
    try std.testing.expectEqual(@as(u32, 40), fixed.offset);
    try std.testing.expect(fixed.elf_symbol == null);
}
