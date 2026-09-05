const std = @import("std");

const max_file_bytes: usize = 4 * 1024 * 1024;
const interface_header_size: u32 = 32;
const pointer_size: u32 = 8;

const Action = enum { check, write, selftest };
const PointerKind = enum { value, single, many };
const Direction = enum { value, input, output, inout };
const Ownership = enum { none, borrowed, caller_owned, library_owned };
const Lifetime = enum { none, call, handle, provider_generation };
const Blocking = enum { nonblocking, may_block, blocking };
const Threading = enum { thread_safe, caller_serialized, handle_serialized, owner_thread };
const Reentrancy = enum { reentrant, serialized, not_reentrant };

const TypeRef = struct {
    name: []const u8,
    pointer: PointerKind = .value,
    is_const: bool = false,
    nullable: bool = false,
};

const Parameter = struct {
    name: []const u8,
    type: TypeRef,
    direction: Direction,
    ownership: Ownership,
    lifetime: Lifetime,
    length_by: ?[]const u8 = null,
    description: []const u8,
};

const Operation = struct {
    blocking: Blocking,
    threading: Threading,
    reentrancy: Reentrancy,
    error_domain: []const u8,
    ownership: []const u8,
};

const FunctionContract = struct {
    name: []const u8,
    c_name: []const u8,
    symbol: []const u8,
    slot: u16,
    since_revision: u16,
    returns: TypeRef,
    parameters: []Parameter,
    operation: Operation,
    description: []const u8,
};

const InterfaceContract = struct {
    export_name: []const u8,
    symbol: []const u8,
    zig_name: []const u8,
    zig_type: []const u8,
    c_type: []const u8,
    abi_major: u16,
    revision: u16,
    interface_id_lo: u64,
    interface_id_hi: u64,
    known_required_flags: u16 = 0,
    functions: []FunctionContract,
    description: []const u8,
};

const FieldContract = struct {
    name: []const u8,
    offset: u32,
    type: TypeRef,
    description: []const u8,
};

const StructContract = struct {
    name: []const u8,
    size: u32,
    alignment: u32,
    fields: []FieldContract,
    description: []const u8,
};

const NamedValue = struct {
    zig_name: []const u8,
    c_name: []const u8,
    type: []const u8,
    value: i64,
    description: []const u8,
};

const Rule = struct {
    name: []const u8,
    text: []const u8,
};

const Contract = struct {
    schema_version: u32,
    module_name: []const u8,
    zig_client: []const u8,
    c_prefix: []const u8,
    c_header: []const u8,
    description: []const u8,
    interfaces: []InterfaceContract,
    types: []StructContract = &.{},
    constants: []NamedValue = &.{},
    errors: []NamedValue = &.{},
    ownership_rules: []Rule,
};

const Options = struct {
    action: ?Action = null,
    update_baseline: bool = false,
    module_name: ?[]const u8 = null,
    exports: std.ArrayList([]const u8) = .empty,
    contract_path: ?[]const u8 = null,
    baseline_path: ?[]const u8 = null,
    implementation_zig_path: ?[]const u8 = null,
    binding_zig_path: ?[]const u8 = null,
    binding_c_path: ?[]const u8 = null,
    fixture_zig_path: ?[]const u8 = null,
    fixture_c_path: ?[]const u8 = null,
    docs_path: ?[]const u8 = null,
};

const Paths = struct {
    action: Action,
    update_baseline: bool,
    module_name: []const u8,
    exports: []const []const u8,
    contract: []const u8,
    baseline: []const u8,
    implementation_zig: []const u8,
    binding_zig: []const u8,
    binding_c: []const u8,
    fixture_zig: []const u8,
    fixture_c: []const u8,
    docs: []const u8,
};

const Layout = struct { size: u32, alignment: u32 };

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const paths = try parseOptions(allocator, args);
    defer allocator.free(paths.exports);

    const contract_bytes = try cwd.readFileAlloc(io, paths.contract, allocator, .limited(max_file_bytes));
    defer allocator.free(contract_bytes);
    var parsed = try std.json.parseFromSlice(Contract, allocator, contract_bytes, .{});
    defer parsed.deinit();
    try validateContract(&parsed.value);
    try validateManifestIdentity(&parsed.value, paths.module_name, paths.exports);

    const canonical = try canonicalAlloc(allocator, parsed.value);
    defer allocator.free(canonical);
    const implementation_zig = try renderImplementationZig(allocator, &parsed.value);
    defer allocator.free(implementation_zig);
    const binding_zig = try renderBindingZig(allocator, &parsed.value);
    defer allocator.free(binding_zig);
    const binding_c = try renderBindingC(allocator, &parsed.value);
    defer allocator.free(binding_c);
    const fixture_zig = try renderFixtureZig(allocator, &parsed.value);
    defer allocator.free(fixture_zig);
    const fixture_c = try renderFixtureC(allocator, &parsed.value);
    defer allocator.free(fixture_c);
    const docs = try renderDocs(allocator, &parsed.value);
    defer allocator.free(docs);

    if (!(paths.action == .write and paths.update_baseline)) {
        const baseline_bytes = try cwd.readFileAlloc(io, paths.baseline, allocator, .limited(max_file_bytes));
        defer allocator.free(baseline_bytes);
        var baseline = try std.json.parseFromSlice(Contract, allocator, baseline_bytes, .{});
        defer baseline.deinit();
        try validateContract(&baseline.value);
        const baseline_canonical = try canonicalAlloc(allocator, baseline.value);
        defer allocator.free(baseline_canonical);
        if (!std.mem.eql(u8, baseline_bytes, baseline_canonical)) return error.BaselineNotCanonical;
        try ensureBaselineMatches(canonical, baseline_canonical);
    }

    switch (paths.action) {
        .check => {
            if (!std.mem.eql(u8, contract_bytes, canonical)) return error.ContractNotCanonical;
            try checkFile(io, cwd, allocator, paths.implementation_zig, implementation_zig, error.ImplementationZigDrift);
            try checkFile(io, cwd, allocator, paths.binding_zig, binding_zig, error.BindingZigDrift);
            try checkFile(io, cwd, allocator, paths.binding_c, binding_c, error.BindingCDrift);
            try checkFile(io, cwd, allocator, paths.fixture_zig, fixture_zig, error.FixtureZigDrift);
            try checkFile(io, cwd, allocator, paths.fixture_c, fixture_c, error.FixtureCDrift);
            try checkFile(io, cwd, allocator, paths.docs, docs, error.DocumentationDrift);
        },
        .write => {
            try cwd.writeFile(io, .{ .sub_path = paths.contract, .data = canonical });
            if (paths.update_baseline) try cwd.writeFile(io, .{ .sub_path = paths.baseline, .data = canonical });
            try cwd.writeFile(io, .{ .sub_path = paths.implementation_zig, .data = implementation_zig });
            try cwd.writeFile(io, .{ .sub_path = paths.binding_zig, .data = binding_zig });
            try cwd.writeFile(io, .{ .sub_path = paths.binding_c, .data = binding_c });
            try cwd.writeFile(io, .{ .sub_path = paths.fixture_zig, .data = fixture_zig });
            try cwd.writeFile(io, .{ .sub_path = paths.fixture_c, .data = fixture_c });
            try cwd.writeFile(io, .{ .sub_path = paths.docs, .data = docs });
        },
        .selftest => try runMutationSelftest(allocator, &parsed.value, canonical),
    }

    std.debug.print("R4LContractGen {s} OK: {s}, interfaces={d}, types={d}.\n", .{
        @tagName(paths.action),
        parsed.value.module_name,
        parsed.value.interfaces.len,
        parsed.value.types.len,
    });
}

fn parseOptions(allocator: std.mem.Allocator, args: []const []const u8) !Paths {
    var options: Options = .{};
    errdefer options.exports.deinit(allocator);
    var index: usize = 1;
    while (index < args.len) : (index += 1) {
        const arg = args[index];
        if (std.mem.eql(u8, arg, "--check")) {
            try setAction(&options, .check);
        } else if (std.mem.eql(u8, arg, "--write")) {
            try setAction(&options, .write);
        } else if (std.mem.eql(u8, arg, "--selftest")) {
            try setAction(&options, .selftest);
        } else if (std.mem.eql(u8, arg, "--update-baseline")) {
            options.update_baseline = true;
        } else if (std.mem.eql(u8, arg, "--module-name")) {
            if (options.module_name != null) return error.DuplicateModuleName;
            options.module_name = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--export")) {
            try options.exports.append(allocator, try nextArg(args, &index));
        } else if (std.mem.eql(u8, arg, "--contract")) {
            options.contract_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--baseline")) {
            options.baseline_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--implementation-zig")) {
            options.implementation_zig_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--binding-zig")) {
            options.binding_zig_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--binding-c")) {
            options.binding_c_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--fixture-zig")) {
            options.fixture_zig_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--fixture-c")) {
            options.fixture_c_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--docs")) {
            options.docs_path = try nextArg(args, &index);
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            return error.HelpRequested;
        } else {
            return error.UnknownArgument;
        }
    }
    const action = options.action orelse return error.MissingAction;
    if (options.update_baseline and action != .write) return error.BaselineUpdateRequiresWrite;
    const module_name = options.module_name orelse return error.MissingModuleName;
    if (options.exports.items.len == 0) return error.MissingManifestExports;
    const contract = options.contract_path orelse return error.MissingContractPath;
    const baseline = options.baseline_path orelse return error.MissingBaselinePath;
    const implementation_zig = options.implementation_zig_path orelse return error.MissingImplementationZigPath;
    const binding_zig = options.binding_zig_path orelse return error.MissingBindingZigPath;
    const binding_c = options.binding_c_path orelse return error.MissingBindingCPath;
    const fixture_zig = options.fixture_zig_path orelse return error.MissingFixtureZigPath;
    const fixture_c = options.fixture_c_path orelse return error.MissingFixtureCPath;
    const docs = options.docs_path orelse return error.MissingDocsPath;
    const exports = try options.exports.toOwnedSlice(allocator);
    return .{
        .action = action,
        .update_baseline = options.update_baseline,
        .module_name = module_name,
        .exports = exports,
        .contract = contract,
        .baseline = baseline,
        .implementation_zig = implementation_zig,
        .binding_zig = binding_zig,
        .binding_c = binding_c,
        .fixture_zig = fixture_zig,
        .fixture_c = fixture_c,
        .docs = docs,
    };
}

fn nextArg(args: []const []const u8, index: *usize) ![]const u8 {
    index.* += 1;
    if (index.* >= args.len or args[index.*].len == 0) return error.MissingArgument;
    return args[index.*];
}

fn setAction(options: *Options, action: Action) !void {
    if (options.action != null) return error.DuplicateAction;
    options.action = action;
}

fn printUsage() void {
    std.debug.print(
        \\Usage: r4l-contract-gen --check|--write|--selftest
        \\       --module-name NAME --export PUBLIC:ELF_SYMBOL:REVISION [--export ...]
        \\       --contract PATH --baseline PATH
        \\       --implementation-zig PATH --binding-zig PATH --binding-c PATH
        \\       --fixture-zig PATH --fixture-c PATH --docs PATH
        \\       [--update-baseline]  # only together with --write
        \\
    , .{});
}

fn canonicalAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    const raw = try std.json.Stringify.valueAlloc(allocator, value, .{
        .whitespace = .indent_2,
        .emit_null_optional_fields = false,
    });
    defer allocator.free(raw);
    const out = try allocator.alloc(u8, raw.len + 1);
    @memcpy(out[0..raw.len], raw);
    out[raw.len] = '\n';
    return out;
}

fn checkFile(io: std.Io, cwd: std.Io.Dir, allocator: std.mem.Allocator, path: []const u8, expected: []const u8, drift: anyerror) !void {
    const actual = try cwd.readFileAlloc(io, path, allocator, .limited(max_file_bytes));
    defer allocator.free(actual);
    if (!std.mem.eql(u8, actual, expected)) return drift;
}

fn ensureBaselineMatches(current: []const u8, baseline: []const u8) !void {
    if (!std.mem.eql(u8, current, baseline)) return error.BaselineDrift;
}

fn validateContract(contract: *const Contract) !void {
    if (contract.schema_version != 1) return error.UnsupportedSchemaVersion;
    try validateModuleName(contract.module_name);
    try validateIdentifier(contract.zig_client);
    try validateIdentifier(contract.c_prefix);
    if (contract.c_header.len == 0 or !std.ascii.eqlIgnoreCase(std.fs.path.extension(contract.c_header), ".h")) return error.InvalidCHeader;
    if (contract.description.len == 0 or contract.interfaces.len == 0 or contract.ownership_rules.len == 0) return error.IncompleteContract;

    for (contract.types, 0..) |typ, type_index| {
        try validateIdentifier(typ.name);
        if (typ.size == 0 or typ.alignment == 0 or !std.math.isPowerOfTwo(typ.alignment) or typ.description.len == 0) return error.InvalidTypeLayout;
        for (contract.types[0..type_index]) |prior| if (std.mem.eql(u8, typ.name, prior.name)) return error.DuplicateType;
        var cursor: u32 = 0;
        var max_alignment: u32 = 1;
        for (typ.fields, 0..) |field, field_index| {
            try validateIdentifier(field.name);
            if (field.description.len == 0 or field.type.pointer != .value or field.type.nullable or field.type.is_const) return error.InvalidStructField;
            for (typ.fields[0..field_index]) |prior| if (std.mem.eql(u8, field.name, prior.name)) return error.DuplicateField;
            const layout = try typeLayout(contract, field.type);
            cursor = alignForward(cursor, layout.alignment);
            if (field.offset != cursor) return error.StructFieldOffsetDrift;
            cursor += layout.size;
            max_alignment = @max(max_alignment, layout.alignment);
        }
        if (typ.alignment != max_alignment or typ.size != alignForward(cursor, max_alignment)) return error.StructLayoutDrift;
    }

    try validateNamedValues(contract, contract.constants, false);
    try validateNamedValues(contract, contract.errors, true);
    for (contract.constants) |constant| {
        for (contract.errors) |err| {
            if (std.mem.eql(u8, constant.zig_name, err.zig_name) or std.mem.eql(u8, constant.c_name, err.c_name)) return error.DuplicateValueName;
        }
    }

    for (contract.interfaces, 0..) |interface, interface_index| {
        try validateExportName(interface.export_name);
        try validateIdentifier(interface.symbol);
        try validateIdentifier(interface.zig_name);
        try validateIdentifier(interface.zig_type);
        try validateIdentifier(interface.c_type);
        if (interface.abi_major == 0 or interface.revision == 0 or
            (interface.interface_id_lo == 0 and interface.interface_id_hi == 0) or
            (interface.known_required_flags & 0xff00) != 0 or interface.description.len == 0)
        {
            return error.InvalidInterface;
        }
        for (contract.interfaces[0..interface_index]) |prior| {
            if (std.ascii.eqlIgnoreCase(interface.export_name, prior.export_name) or
                std.mem.eql(u8, interface.symbol, prior.symbol) or
                std.mem.eql(u8, interface.zig_name, prior.zig_name) or
                std.mem.eql(u8, interface.zig_type, prior.zig_type) or
                std.mem.eql(u8, interface.c_type, prior.c_type)) return error.DuplicateInterface;
        }
        for (interface.functions, 0..) |function, function_index| {
            try validateIdentifier(function.name);
            try validateIdentifier(function.c_name);
            try validateIdentifier(function.symbol);
            if (function.slot != function_index or function.since_revision == 0 or function.since_revision > interface.revision or
                function.description.len == 0 or function.operation.error_domain.len == 0 or function.operation.ownership.len == 0)
            {
                return error.InvalidFunction;
            }
            if (function.returns.pointer != .value) return error.IncompleteReturnPointerContract;
            if (function.returns.nullable or function.returns.is_const) return error.InvalidReturnContract;
            _ = try typeLayout(contract, function.returns);
            for (interface.functions[0..function_index]) |prior| {
                if (std.mem.eql(u8, function.name, prior.name) or std.mem.eql(u8, function.c_name, prior.c_name) or std.mem.eql(u8, function.symbol, prior.symbol)) return error.DuplicateFunction;
            }
            for (function.parameters, 0..) |parameter, parameter_index| {
                try validateIdentifier(parameter.name);
                if (parameter.description.len == 0) return error.InvalidParameter;
                _ = try typeLayout(contract, parameter.type);
                for (function.parameters[0..parameter_index]) |prior| if (std.mem.eql(u8, parameter.name, prior.name)) return error.DuplicateParameter;
                if (parameter.type.pointer == .value) {
                    if (parameter.direction != .value or parameter.ownership != .none or parameter.lifetime != .none or parameter.length_by != null or parameter.type.nullable or parameter.type.is_const) return error.InvalidValueParameter;
                } else {
                    if (parameter.direction == .value or parameter.ownership == .none or parameter.lifetime == .none) return error.IncompletePointerContract;
                    if (parameter.type.pointer == .many) {
                        const length_name = parameter.length_by orelse return error.MissingBufferLength;
                        var found = false;
                        for (function.parameters) |candidate| {
                            if (std.mem.eql(u8, candidate.name, length_name)) found = true;
                        }
                        if (!found) return error.BadBufferLengthReference;
                    }
                }
            }
        }
    }

    for (contract.ownership_rules, 0..) |rule, index| {
        if (rule.name.len == 0 or rule.text.len == 0) return error.InvalidOwnershipRule;
        for (contract.ownership_rules[0..index]) |prior| if (std.mem.eql(u8, rule.name, prior.name)) return error.DuplicateOwnershipRule;
    }
}

const ManifestExport = struct {
    name: []const u8,
    symbol: []const u8,
    revision: u16,
};

fn validateManifestIdentity(contract: *const Contract, module_name: []const u8, export_specs: []const []const u8) !void {
    if (!std.mem.eql(u8, contract.module_name, module_name)) return error.ManifestModuleNameDrift;
    if (export_specs.len != contract.interfaces.len) return error.ManifestExportCountDrift;

    for (export_specs, 0..) |spec, index| {
        const expected = try parseManifestExport(spec);
        for (export_specs[0..index]) |prior_spec| {
            const prior = try parseManifestExport(prior_spec);
            if (std.ascii.eqlIgnoreCase(expected.name, prior.name)) return error.DuplicateManifestExport;
        }

        var match: ?InterfaceContract = null;
        for (contract.interfaces) |interface| {
            if (std.ascii.eqlIgnoreCase(interface.export_name, expected.name)) {
                match = interface;
                break;
            }
        }
        const interface = match orelse return error.ManifestExportNameDrift;
        if (!std.mem.eql(u8, interface.symbol, expected.symbol)) return error.ManifestExportSymbolDrift;
        if (interface.revision != expected.revision) return error.ManifestExportRevisionDrift;
    }
}

fn parseManifestExport(value: []const u8) !ManifestExport {
    var parts: [3][]const u8 = undefined;
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, value, ':');
    while (it.next()) |part| {
        if (count >= parts.len or part.len == 0) return error.InvalidManifestExport;
        parts[count] = part;
        count += 1;
    }
    if (count != parts.len) return error.InvalidManifestExport;
    try validateExportName(parts[0]);
    try validateIdentifier(parts[1]);
    const revision = std.fmt.parseUnsigned(u16, parts[2], 10) catch return error.InvalidManifestExport;
    if (revision == 0) return error.InvalidManifestExport;
    return .{ .name = parts[0], .symbol = parts[1], .revision = revision };
}

fn validateNamedValues(contract: *const Contract, values: []const NamedValue, require_negative: bool) !void {
    for (values, 0..) |value, index| {
        try validateIdentifier(value.zig_name);
        try validateIdentifier(value.c_name);
        if (value.description.len == 0) return error.InvalidNamedValue;
        const type_ref = TypeRef{ .name = value.type };
        _ = try typeLayout(contract, type_ref);
        if (require_negative and value.value >= 0) return error.ErrorMustBeNegative;
        for (values[0..index]) |prior| {
            if (std.mem.eql(u8, value.zig_name, prior.zig_name) or std.mem.eql(u8, value.c_name, prior.c_name) or
                (require_negative and value.value == prior.value)) return error.DuplicateValue;
        }
    }
}

fn validateModuleName(name: []const u8) !void {
    if (name.len == 0 or name.len > 31) return error.InvalidModuleName;
    for (name) |byte| if (!std.ascii.isUpper(byte) and !std.ascii.isDigit(byte) and byte != '_' and byte != '-') return error.InvalidModuleName;
}

fn validateExportName(name: []const u8) !void {
    if (name.len == 0 or name.len > 31 or !std.ascii.isAlphabetic(name[0])) return error.InvalidExportName;
    for (name[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidExportName;
}

fn validateIdentifier(name: []const u8) !void {
    if (name.len == 0 or (!std.ascii.isAlphabetic(name[0]) and name[0] != '_')) return error.InvalidIdentifier;
    for (name[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidIdentifier;
}

fn typeLayout(contract: *const Contract, type_ref: TypeRef) !Layout {
    if (type_ref.pointer != .value) {
        _ = try typeLayout(contract, .{ .name = type_ref.name });
        return .{ .size = pointer_size, .alignment = pointer_size };
    }
    if (std.mem.eql(u8, type_ref.name, "void")) return .{ .size = 0, .alignment = 1 };
    if (std.mem.eql(u8, type_ref.name, "u8") or std.mem.eql(u8, type_ref.name, "i8")) return .{ .size = 1, .alignment = 1 };
    if (std.mem.eql(u8, type_ref.name, "u16") or std.mem.eql(u8, type_ref.name, "i16")) return .{ .size = 2, .alignment = 2 };
    if (std.mem.eql(u8, type_ref.name, "u32") or std.mem.eql(u8, type_ref.name, "i32")) return .{ .size = 4, .alignment = 4 };
    if (std.mem.eql(u8, type_ref.name, "u64") or std.mem.eql(u8, type_ref.name, "i64")) return .{ .size = 8, .alignment = 8 };
    for (contract.types) |typ| if (std.mem.eql(u8, type_ref.name, typ.name)) return .{ .size = typ.size, .alignment = typ.alignment };
    return error.UnknownAbiType;
}

fn alignForward(value: u32, alignment: u32) u32 {
    return (value + alignment - 1) & ~(alignment - 1);
}

fn tableSize(interface: InterfaceContract) u32 {
    return interface_header_size + @as(u32, @intCast(interface.functions.len)) * pointer_size;
}

fn emit(out: *std.ArrayList(u8), allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) !void {
    const text = try std.fmt.allocPrint(allocator, format, args);
    defer allocator.free(text);
    try out.appendSlice(allocator, text);
}

fn renderImplementationZig(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "// Generated by R4LContractGen. Do not edit.\nconst r4os = @import(\"r4os\");\n\npub const InterfaceHeader = r4os.runtime_r4l.InterfaceHeader;\n");
    try renderZigDefinitions(&out, allocator, contract);
    return try out.toOwnedSlice(allocator);
}

fn renderBindingZig(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "// Generated by R4LContractGen. Do not edit.\nconst r4os = @import(\"r4os\");\n\npub const InterfaceHeader = r4os.runtime_r4l.InterfaceHeader;\n");
    try renderZigDefinitions(&out, allocator, contract);
    for (contract.interfaces) |interface| {
        try emit(&out, allocator, "\npub const {s}Client = struct {{\n    header: *const InterfaceHeader,\n\n    pub fn init(raw: *const r4os.abi.R4XStartContext) !{s}Client {{\n        const item = r4os.r4xstart.Context.init(raw).findImportNamed(module_name, {s}_export_name) orelse return error.MissingImport;\n        const header = try r4os.runtime_r4l.validateImport(item, .{{\n            .interface_id_lo = 0x{x},\n            .interface_id_hi = 0x{x},\n            .abi_major = {d},\n            .min_revision = {d},\n            .required_size = {d},\n            .known_required_flags = {d},\n        }});\n", .{ interface.zig_type, interface.zig_type, interface.zig_name, interface.interface_id_lo, interface.interface_id_hi, interface.abi_major, interface.revision, tableSize(interface), interface.known_required_flags });
        for (interface.functions) |function| {
            try emit(&out, allocator, "        if (r4os.runtime_r4l.slotAddress(header, {d}) == null) return error.MissingSlot;\n", .{interface_header_size + @as(u32, function.slot) * pointer_size});
        }
        try emit(&out, allocator, "        return .{{ .header = header }};\n    }}\n", .{});
        for (interface.functions) |function| {
            const fn_type = try functionTypeNameAlloc(allocator, interface.zig_type, function.name);
            defer allocator.free(fn_type);
            try emit(&out, allocator, "\n    pub fn {s}(self: *const {s}Client", .{ function.name, interface.zig_type });
            for (function.parameters) |parameter| {
                try emit(&out, allocator, ", {s}: ", .{parameter.name});
                try renderZigType(&out, allocator, parameter.type);
            }
            try out.appendSlice(allocator, ") ");
            try renderZigType(&out, allocator, function.returns);
            try emit(&out, allocator, " {{\n        const function = r4os.runtime_r4l.functionAt({s}, self.header, {d}) orelse unreachable;\n        ", .{ fn_type, interface_header_size + @as(u32, function.slot) * pointer_size });
            if (!std.mem.eql(u8, function.returns.name, "void") or function.returns.pointer != .value) try out.appendSlice(allocator, "return ");
            try out.appendSlice(allocator, "function(");
            for (function.parameters, 0..) |parameter, index| {
                if (index != 0) try out.appendSlice(allocator, ", ");
                try out.appendSlice(allocator, parameter.name);
            }
            try out.appendSlice(allocator, ");\n    }\n");
        }
        try out.appendSlice(allocator, "};\n");
    }
    return try out.toOwnedSlice(allocator);
}

fn renderZigDefinitions(out: *std.ArrayList(u8), allocator: std.mem.Allocator, contract: *const Contract) !void {
    try emit(out, allocator, "\npub const module_name = \"{s}\";\n", .{contract.module_name});
    for (contract.types) |typ| {
        try emit(out, allocator, "\npub const {s} = extern struct {{\n", .{typ.name});
        for (typ.fields) |field| {
            try emit(out, allocator, "    {s}: ", .{field.name});
            try renderZigType(out, allocator, field.type);
            try out.appendSlice(allocator, ",\n");
        }
        try out.appendSlice(allocator, "};\n");
    }
    for (contract.constants) |constant| try emit(out, allocator, "pub const {s}: {s} = {d};\n", .{ constant.zig_name, constant.type, constant.value });
    for (contract.errors) |err| try emit(out, allocator, "pub const {s}: {s} = {d};\n", .{ err.zig_name, err.type, err.value });
    for (contract.interfaces) |interface| {
        try emit(out, allocator, "\npub const {s}_export_name = \"{s}\";\npub const {s}_revision: u16 = {d};\npub const {s}_header = InterfaceHeader{{\n    .magic = r4os.runtime_r4l.interface_magic,\n    .header_version = r4os.runtime_r4l.interface_header_version,\n    .flags = {d},\n    .size = {d},\n    .abi_major = {d},\n    .abi_minor = {d},\n    .interface_id_lo = 0x{x},\n    .interface_id_hi = 0x{x},\n}};\n", .{ interface.zig_name, interface.export_name, interface.zig_name, interface.revision, interface.zig_name, interface.known_required_flags, tableSize(interface), interface.abi_major, interface.revision, interface.interface_id_lo, interface.interface_id_hi });
        for (interface.functions) |function| {
            const fn_type = try functionTypeNameAlloc(allocator, interface.zig_type, function.name);
            defer allocator.free(fn_type);
            try emit(out, allocator, "pub const {s} = *const fn (", .{fn_type});
            for (function.parameters, 0..) |parameter, index| {
                if (index != 0) try out.appendSlice(allocator, ", ");
                try emit(out, allocator, "{s}: ", .{parameter.name});
                try renderZigType(out, allocator, parameter.type);
            }
            try out.appendSlice(allocator, ") callconv(.c) ");
            try renderZigType(out, allocator, function.returns);
            try out.appendSlice(allocator, ";\n");
        }
        try emit(out, allocator, "pub const {s} = extern struct {{\n    header: InterfaceHeader,\n", .{interface.zig_type});
        for (interface.functions) |function| {
            const fn_type = try functionTypeNameAlloc(allocator, interface.zig_type, function.name);
            defer allocator.free(fn_type);
            try emit(out, allocator, "    {s}: {s},\n", .{ function.name, fn_type });
        }
        try out.appendSlice(allocator, "};\n");
    }
}

fn renderZigType(out: *std.ArrayList(u8), allocator: std.mem.Allocator, type_ref: TypeRef) !void {
    if (type_ref.pointer == .value) {
        try out.appendSlice(allocator, type_ref.name);
        return;
    }
    if (type_ref.nullable) try out.append(allocator, '?');
    try out.appendSlice(allocator, if (type_ref.pointer == .single) "*" else "[*]");
    if (type_ref.is_const) try out.appendSlice(allocator, "const ");
    try out.appendSlice(allocator, type_ref.name);
}

fn renderBindingC(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "/* Generated by R4LContractGen. Do not edit. */\n#ifndef ");
    try appendUpperIdentifier(&out, allocator, contract.module_name);
    try out.appendSlice(allocator, "_R4L_BINDING_H\n#define ");
    try appendUpperIdentifier(&out, allocator, contract.module_name);
    try out.appendSlice(allocator, "_R4L_BINDING_H\n\n#include <stddef.h>\n#include <stdint.h>\n#include <r4os/r4l.h>\n\n");
    for (contract.types) |typ| {
        try emit(&out, allocator, "typedef struct {s} {{\n", .{typ.name});
        for (typ.fields) |field| {
            try out.appendSlice(allocator, "    ");
            try renderCType(&out, allocator, field.type);
            try emit(&out, allocator, " {s};\n", .{field.name});
        }
        try emit(&out, allocator, "}} {s};\n", .{typ.name});
        try emit(&out, allocator, "_Static_assert(sizeof({s}) == {d}u, \"{s} size mismatch\");\n", .{ typ.name, typ.size, typ.name });
        for (typ.fields) |field| try emit(&out, allocator, "_Static_assert(offsetof({s}, {s}) == {d}u, \"{s}.{s} offset mismatch\");\n", .{ typ.name, field.name, field.offset, typ.name, field.name });
        try out.append(allocator, '\n');
    }
    for (contract.constants) |constant| try emit(&out, allocator, "#define {s} (({s}){d})\n", .{ constant.c_name, try cPrimitiveName(constant.type), constant.value });
    for (contract.errors) |err| try emit(&out, allocator, "#define {s} (({s}){d})\n", .{ err.c_name, try cPrimitiveName(err.type), err.value });
    for (contract.interfaces) |interface| {
        try out.append(allocator, '\n');
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try emit(&out, allocator, "_EXPORT_NAME \"{s}\"\n", .{interface.export_name});
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try emit(&out, allocator, "_ABI_MAJOR {d}u\n", .{interface.abi_major});
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try emit(&out, allocator, "_REVISION {d}u\n", .{interface.revision});
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try emit(&out, allocator, "_INTERFACE_ID_LO 0x{x}ull\n", .{interface.interface_id_lo});
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try emit(&out, allocator, "_INTERFACE_ID_HI 0x{x}ull\n", .{interface.interface_id_hi});
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try emit(&out, allocator, "_TABLE_SIZE {d}u\n", .{tableSize(interface)});
        try out.appendSlice(allocator, "#define ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try out.appendSlice(allocator, "_HEADER_INITIALIZER { R4L_INTERFACE_MAGIC, R4L_INTERFACE_HEADER_VERSION, 0u, ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try out.appendSlice(allocator, "_TABLE_SIZE, ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try out.appendSlice(allocator, "_ABI_MAJOR, ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try out.appendSlice(allocator, "_REVISION, ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try out.appendSlice(allocator, "_INTERFACE_ID_LO, ");
        try appendUpperIdentifier(&out, allocator, contract.module_name);
        try out.append(allocator, '_');
        try appendUpperIdentifier(&out, allocator, interface.zig_name);
        try out.appendSlice(allocator, "_INTERFACE_ID_HI }\n");
        for (interface.functions) |function| {
            const fn_type = try cFunctionTypeNameAlloc(allocator, interface.c_type, function.name);
            defer allocator.free(fn_type);
            try out.appendSlice(allocator, "typedef ");
            try renderCType(&out, allocator, function.returns);
            try emit(&out, allocator, " (*{s})(", .{fn_type});
            if (function.parameters.len == 0) {
                try out.appendSlice(allocator, "void");
            } else for (function.parameters, 0..) |parameter, index| {
                if (index != 0) try out.appendSlice(allocator, ", ");
                try renderCType(&out, allocator, parameter.type);
                try emit(&out, allocator, " {s}", .{parameter.name});
            }
            try out.appendSlice(allocator, ");\n");
        }
        try emit(&out, allocator, "typedef struct {s} {{\n    R4LInterfaceHeader header;\n", .{interface.c_type});
        for (interface.functions) |function| {
            const fn_type = try cFunctionTypeNameAlloc(allocator, interface.c_type, function.name);
            defer allocator.free(fn_type);
            try emit(&out, allocator, "    {s} {s};\n", .{ fn_type, function.name });
        }
        try emit(&out, allocator, "}} {s};\n_Static_assert(sizeof({s}) == {d}u, \"{s} size mismatch\");\n", .{ interface.c_type, interface.c_type, tableSize(interface), interface.c_type });
        for (interface.functions) |function| try emit(&out, allocator, "_Static_assert(offsetof({s}, {s}) == {d}u, \"{s}.{s} offset mismatch\");\n", .{ interface.c_type, function.name, interface_header_size + @as(u32, function.slot) * pointer_size, interface.c_type, function.name });
        try emit(&out, allocator, "typedef struct {s}Client {{ const R4LInterfaceHeader *header; }} {s}Client;\n\nstatic inline int32_t {s}_{s}_init(const R4XStartContext *ctx, {s}Client *out_client) {{\n    if (out_client == 0) return R4L_BINDING_INVALID_EXPECTATION;\n    out_client->header = 0;\n    const R4XStartImport *item = r4xstart_find_import_named(ctx, \"{s}\", \"{s}\");\n    const R4LInterfaceExpectation expected = {{ 0x{x}ull, 0x{x}ull, {d}u, {d}u, {d}u, {d}u, 0u }};\n    const R4LInterfaceHeader *header = 0;\n    int32_t status = r4l_validate_import(item, &expected, &header);\n    if (status != R4L_BINDING_OK) return status;\n", .{ interface.c_type, interface.c_type, contract.c_prefix, interface.zig_name, interface.c_type, contract.module_name, interface.export_name, interface.interface_id_lo, interface.interface_id_hi, interface.abi_major, interface.revision, tableSize(interface), interface.known_required_flags });
        for (interface.functions) |function| try emit(&out, allocator, "    if (r4l_slot_address(header, {d}u) == 0) return R4L_BINDING_TABLE_TOO_SMALL;\n", .{interface_header_size + @as(u32, function.slot) * pointer_size});
        try out.appendSlice(allocator, "    out_client->header = header;\n    return R4L_BINDING_OK;\n}\n");
        for (interface.functions) |function| {
            const fn_type = try cFunctionTypeNameAlloc(allocator, interface.c_type, function.name);
            defer allocator.free(fn_type);
            try out.appendSlice(allocator, "\nstatic inline ");
            try renderCType(&out, allocator, function.returns);
            try emit(&out, allocator, " {s}({s}Client *client", .{ function.c_name, interface.c_type });
            for (function.parameters) |parameter| {
                try out.appendSlice(allocator, ", ");
                try renderCType(&out, allocator, parameter.type);
                try emit(&out, allocator, " {s}", .{parameter.name});
            }
            try emit(&out, allocator, ") {{\n    {s} function = ({s})r4l_slot_address(client->header, {d}u);\n    ", .{ fn_type, fn_type, interface_header_size + @as(u32, function.slot) * pointer_size });
            if (!std.mem.eql(u8, function.returns.name, "void") or function.returns.pointer != .value) try out.appendSlice(allocator, "return ");
            try out.appendSlice(allocator, "function(");
            for (function.parameters, 0..) |parameter, index| {
                if (index != 0) try out.appendSlice(allocator, ", ");
                try out.appendSlice(allocator, parameter.name);
            }
            try out.appendSlice(allocator, ");\n}\n");
        }
    }
    try out.appendSlice(allocator, "\n#endif\n");
    return try out.toOwnedSlice(allocator);
}

fn renderCType(out: *std.ArrayList(u8), allocator: std.mem.Allocator, type_ref: TypeRef) !void {
    if (type_ref.pointer != .value and type_ref.is_const) try out.appendSlice(allocator, "const ");
    if (cPrimitiveName(type_ref.name)) |name| {
        try out.appendSlice(allocator, name);
    } else |_| {
        try out.appendSlice(allocator, type_ref.name);
    }
    if (type_ref.pointer != .value) try out.appendSlice(allocator, " *");
}

fn cPrimitiveName(name: []const u8) ![]const u8 {
    if (std.mem.eql(u8, name, "void")) return "void";
    if (std.mem.eql(u8, name, "u8")) return "uint8_t";
    if (std.mem.eql(u8, name, "u16")) return "uint16_t";
    if (std.mem.eql(u8, name, "u32")) return "uint32_t";
    if (std.mem.eql(u8, name, "u64")) return "uint64_t";
    if (std.mem.eql(u8, name, "i8")) return "int8_t";
    if (std.mem.eql(u8, name, "i16")) return "int16_t";
    if (std.mem.eql(u8, name, "i32")) return "int32_t";
    if (std.mem.eql(u8, name, "i64")) return "int64_t";
    return error.NotPrimitive;
}

fn renderFixtureZig(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "// Generated by R4LContractGen. Do not edit.\nconst std = @import(\"std\");\nconst implementation = @import(\"implementation\");\nconst binding = @import(\"binding\");\n\ncomptime {\n");
    for (contract.types) |typ| {
        try emit(&out, allocator, "    if (@sizeOf(implementation.{s}) != {d} or @sizeOf(binding.{s}) != {d}) @compileError(\"{s} size drift\");\n", .{ typ.name, typ.size, typ.name, typ.size, typ.name });
        for (typ.fields) |field| try emit(&out, allocator, "    if (@offsetOf(implementation.{s}, \"{s}\") != {d} or @offsetOf(binding.{s}, \"{s}\") != {d}) @compileError(\"{s}.{s} offset drift\");\n", .{ typ.name, field.name, field.offset, typ.name, field.name, field.offset, typ.name, field.name });
    }
    for (contract.interfaces) |interface| {
        try emit(&out, allocator, "    if (@sizeOf(implementation.{s}) != {d} or @sizeOf(binding.{s}) != {d}) @compileError(\"{s} size drift\");\n", .{ interface.zig_type, tableSize(interface), interface.zig_type, tableSize(interface), interface.zig_type });
        for (interface.functions) |function| try emit(&out, allocator, "    if (@offsetOf(implementation.{s}, \"{s}\") != {d} or @offsetOf(binding.{s}, \"{s}\") != {d}) @compileError(\"{s}.{s} slot drift\");\n", .{ interface.zig_type, function.name, interface_header_size + @as(u32, function.slot) * pointer_size, interface.zig_type, function.name, interface_header_size + @as(u32, function.slot) * pointer_size, interface.zig_type, function.name });
    }
    try out.appendSlice(allocator, "}\n\ntest \"generated implementation and binding views are identical\" {\n");
    for (contract.interfaces) |interface| try emit(&out, allocator, "    try std.testing.expectEqual(implementation.{s}_header.size, binding.{s}_header.size);\n    try std.testing.expectEqual(implementation.{s}_header.interface_id_lo, binding.{s}_header.interface_id_lo);\n", .{ interface.zig_name, interface.zig_name, interface.zig_name, interface.zig_name });
    try out.appendSlice(allocator, "}\n");
    return try out.toOwnedSlice(allocator);
}

fn renderFixtureC(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    return try std.fmt.allocPrint(allocator, "/* Generated by R4LContractGen. Do not edit. */\n#include \"{s}\"\n\nint {s}_generated_contract_conformance(void) {{ return 0; }}\n", .{ contract.c_header, contract.c_prefix });
}

fn renderDocs(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "\xef\xbb\xbf");
    try emit(&out, allocator, "{s} Runtime-R4L API\n", .{contract.module_name});
    for (0..contract.module_name.len + " Runtime-R4L API".len) |_| try out.append(allocator, '=');
    try emit(&out, allocator, "\n\n{s}\n\n", .{contract.description});
    for (contract.interfaces) |interface| {
        try emit(&out, allocator, "{s}\n", .{interface.export_name});
        for (0..interface.export_name.len) |_| try out.append(allocator, '-');
        try emit(&out, allocator, "\n\n{s}\n\n- ELF-Symbol: `{s}`\n- ABI-Major: {d}\n- Revision: {d}\n- Interface-ID: `0x{x}:0x{x}`\n- Tabellengroesse: {d} Byte\n\n", .{ interface.description, interface.symbol, interface.abi_major, interface.revision, interface.interface_id_hi, interface.interface_id_lo, tableSize(interface) });
        for (interface.functions) |function| {
            try emit(&out, allocator, "- Slot {d}, Offset {d}: `{s}` - {s}\n  Semantik: {s}, {s}, {s}; Fehlerdomaene `{s}`; Besitz: {s}.\n", .{ function.slot, interface_header_size + @as(u32, function.slot) * pointer_size, function.name, function.description, @tagName(function.operation.blocking), @tagName(function.operation.threading), @tagName(function.operation.reentrancy), function.operation.error_domain, function.operation.ownership });
        }
        try out.append(allocator, '\n');
    }
    if (contract.types.len != 0) {
        try out.appendSlice(allocator, "Typen\n-----\n\n");
        for (contract.types) |typ| try emit(&out, allocator, "- `{s}`: {d} Byte, Alignment {d}. {s}\n", .{ typ.name, typ.size, typ.alignment, typ.description });
        try out.append(allocator, '\n');
    }
    try out.appendSlice(allocator, "Besitzregeln\n------------\n\n");
    for (contract.ownership_rules) |rule| try emit(&out, allocator, "- {s}: {s}\n", .{ rule.name, rule.text });
    return try out.toOwnedSlice(allocator);
}

fn functionTypeNameAlloc(allocator: std.mem.Allocator, interface_name: []const u8, function_name: []const u8) ![]u8 {
    const suffix = try pascalAlloc(allocator, function_name);
    defer allocator.free(suffix);
    return try std.fmt.allocPrint(allocator, "{s}{s}Fn", .{ interface_name, suffix });
}

fn cFunctionTypeNameAlloc(allocator: std.mem.Allocator, interface_name: []const u8, function_name: []const u8) ![]u8 {
    return functionTypeNameAlloc(allocator, interface_name, function_name);
}

fn pascalAlloc(allocator: std.mem.Allocator, value: []const u8) ![]u8 {
    const out = try allocator.alloc(u8, value.len);
    var length: usize = 0;
    var upper = true;
    for (value) |byte| {
        if (byte == '_') {
            upper = true;
            continue;
        }
        out[length] = if (upper and byte >= 'a' and byte <= 'z') byte - ('a' - 'A') else byte;
        length += 1;
        upper = false;
    }
    return try allocator.realloc(out, length);
}

fn appendUpperIdentifier(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    for (value) |byte| {
        const rendered = if (byte == '-') '_' else if (byte >= 'a' and byte <= 'z') byte - ('a' - 'A') else byte;
        try out.append(allocator, rendered);
    }
}

fn runMutationSelftest(allocator: std.mem.Allocator, contract: *const Contract, canonical: []const u8) !void {
    if (contract.interfaces.len == 0 or contract.interfaces[0].functions.len == 0 or contract.types.len == 0) return error.SelftestFixtureIncomplete;

    var slot_contract = contract.*;
    const slot_interfaces = try allocator.dupe(InterfaceContract, contract.interfaces);
    defer allocator.free(slot_interfaces);
    slot_contract.interfaces = slot_interfaces;
    const slot_functions = try allocator.dupe(FunctionContract, contract.interfaces[0].functions);
    defer allocator.free(slot_functions);
    slot_interfaces[0].functions = slot_functions;
    slot_functions[0].slot += 1;
    try expectRejectedMutation(allocator, slot_contract, canonical);

    var signature_contract = contract.*;
    const signature_interfaces = try allocator.dupe(InterfaceContract, contract.interfaces);
    defer allocator.free(signature_interfaces);
    signature_contract.interfaces = signature_interfaces;
    const signature_functions = try allocator.dupe(FunctionContract, contract.interfaces[0].functions);
    defer allocator.free(signature_functions);
    signature_interfaces[0].functions = signature_functions;
    signature_functions[0].returns.name = if (std.mem.eql(u8, signature_functions[0].returns.name, "i32")) "i64" else "i32";
    try expectRejectedMutation(allocator, signature_contract, canonical);

    var layout_contract = contract.*;
    const layout_types = try allocator.dupe(StructContract, contract.types);
    defer allocator.free(layout_types);
    layout_contract.types = layout_types;
    layout_types[0].size += 8;
    try expectRejectedMutation(allocator, layout_contract, canonical);
}

fn expectRejectedMutation(allocator: std.mem.Allocator, contract: Contract, original: []const u8) !void {
    validateContract(&contract) catch return;
    const mutated = try canonicalAlloc(allocator, contract);
    defer allocator.free(mutated);
    ensureBaselineMatches(mutated, original) catch |err| {
        if (err == error.BaselineDrift) return;
        return err;
    };
    return error.MutationNotDetected;
}

test "explicit paths and baseline updates cannot be implicit" {
    const good = [_][]const u8{
        "r4l-contract-gen", "--check",       "--module-name", "ACME",          "--export",             "API_V1:acme_api_v1:1",
        "--contract",       "contract.json", "--baseline",    "baseline.json", "--implementation-zig", "implementation.zig",
        "--binding-zig",    "binding.zig",   "--binding-c",   "binding.h",     "--fixture-zig",        "fixture.zig",
        "--fixture-c",      "fixture.c",     "--docs",        "API.md",
    };
    const parsed = try parseOptions(std.testing.allocator, &good);
    defer std.testing.allocator.free(parsed.exports);
    try std.testing.expectEqual(Action.check, parsed.action);
    try std.testing.expectEqualStrings("binding.h", parsed.binding_c);
    try std.testing.expectEqualStrings("ACME", parsed.module_name);
    try std.testing.expectEqualStrings("API_V1:acme_api_v1:1", parsed.exports[0]);

    const bad = [_][]const u8{
        "r4l-contract-gen",     "--check",            "--update-baseline", "--contract",  "contract.json", "--baseline", "baseline.json",
        "--implementation-zig", "implementation.zig", "--binding-zig",     "binding.zig", "--binding-c",   "binding.h",  "--fixture-zig",
        "fixture.zig",          "--fixture-c",        "fixture.c",         "--docs",      "API.md",
    };
    try std.testing.expectError(error.BaselineUpdateRequiresWrite, parseOptions(std.testing.allocator, &bad));
}

test "contract check rejects slot signature and layout drift" {
    const parameter = Parameter{
        .name = "value",
        .type = .{ .name = "i64" },
        .direction = .value,
        .ownership = .none,
        .lifetime = .none,
        .description = "Input value.",
    };
    var functions = [_]FunctionContract{.{
        .name = "add",
        .c_name = "acme_add",
        .symbol = "acme_add_impl",
        .slot = 0,
        .since_revision = 1,
        .returns = .{ .name = "i64" },
        .parameters = @constCast(&[_]Parameter{parameter}),
        .operation = .{ .blocking = .nonblocking, .threading = .thread_safe, .reentrancy = .reentrant, .error_domain = "none", .ownership = "none" },
        .description = "Adds a value.",
    }};
    var interfaces = [_]InterfaceContract{.{
        .export_name = "API_V1",
        .symbol = "acme_api_v1",
        .zig_name = "api_v1",
        .zig_type = "ApiV1",
        .c_type = "AcmeApiV1",
        .abi_major = 1,
        .revision = 1,
        .interface_id_lo = 1,
        .interface_id_hi = 2,
        .functions = &functions,
        .description = "API.",
    }};
    var types = [_]StructContract{.{
        .name = "Pair",
        .size = 16,
        .alignment = 8,
        .fields = @constCast(&[_]FieldContract{
            .{ .name = "left", .offset = 0, .type = .{ .name = "i64" }, .description = "Left." },
            .{ .name = "right", .offset = 8, .type = .{ .name = "i64" }, .description = "Right." },
        }),
        .description = "Pair.",
    }};
    const rules = [_]Rule{.{ .name = "none", .text = "No transferred ownership." }};
    const contract = Contract{
        .schema_version = 1,
        .module_name = "ACME",
        .zig_client = "Acme",
        .c_prefix = "acme",
        .c_header = "acme.h",
        .description = "Fixture.",
        .interfaces = &interfaces,
        .types = &types,
        .ownership_rules = @constCast(&rules),
    };
    const allocator = std.testing.allocator;
    try validateContract(&contract);
    try validateManifestIdentity(&contract, "ACME", &.{"API_V1:acme_api_v1:1"});
    try std.testing.expectError(error.ManifestModuleNameDrift, validateManifestIdentity(&contract, "OTHER", &.{"API_V1:acme_api_v1:1"}));
    try std.testing.expectError(error.ManifestExportRevisionDrift, validateManifestIdentity(&contract, "ACME", &.{"API_V1:acme_api_v1:2"}));
    try std.testing.expectError(error.ManifestExportSymbolDrift, validateManifestIdentity(&contract, "ACME", &.{"API_V1:other_symbol:1"}));
    const original = try canonicalAlloc(allocator, contract);
    defer allocator.free(original);
    functions[0].slot = 1;
    try expectRejectedMutation(allocator, contract, original);
    functions[0].slot = 0;
    functions[0].returns.name = "i32";
    try expectRejectedMutation(allocator, contract, original);
    functions[0].returns.name = "i64";
    types[0].size = 24;
    try expectRejectedMutation(allocator, contract, original);
}
