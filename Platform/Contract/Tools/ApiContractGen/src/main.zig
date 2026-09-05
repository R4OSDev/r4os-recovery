const std = @import("std");

const default_schema_path = "API/ApiContract.json";
const default_baseline_path = "API/ApiContract.baseline.json";
const default_payload_reference_path = "Generated/Docs/PayloadTypes.md";
const default_zig_abi_path = "Generated/SDK/Zig/abi_generated.zig";
const default_zig_exports_path = "Generated/SDK/Zig/abi_exports.zig";
const default_zig_facade_path = "Generated/SDK/Zig/abi.zig";
const default_kernel_abi_path = "Generated/Kernel/Zig/r4x_api_generated.zig";
const default_kernel_exports_path = "Generated/Kernel/Zig/r4x_api_exports.zig";
const default_c_abi_path = "Generated/SDK/C/include/r4os/abi_generated.h";
const default_zig_conformance_path = "Generated/Conformance/Zig/ApiContractConformanceGenerated.zig";
const default_c_conformance_path = "Generated/Conformance/C/ApiContractConformanceGenerated.c";
const default_operation_matrix_path = "Generated/Docs/OperationContracts.md";
const default_parity_report_path = "Generated/Docs/ZigCParity.json";
const default_api_inventory_path = "Generated/Inventory/API.json";
const default_group_output_root = "Generated/Groups";
const default_group_docs_root = "Generated/Docs/API";
const default_start_doc_path = "ABI/R4XStart.txt";
const default_r4l_contract_path = "ABI/R4LQuery.txt";

// Public payload declarations are owned by the schema; generated SDK and
// Kernel packages are projections of it, never secondary source locations.
const contract_zig_type_source = default_schema_path;
const zig_exports_begin = "// R4OS-ABI-GENERATED-EXPORTS:BEGIN\n";
const zig_exports_end = "// R4OS-ABI-GENERATED-EXPORTS:END\n";
const kernel_exports_begin = "// R4OS-KERNEL-API-GENERATED-EXPORTS:BEGIN\n";
const kernel_exports_end = "// R4OS-KERNEL-API-GENERATED-EXPORTS:END\n";
const start_doc_begin = "R4OS-CONTRACT-GENERATED:BEGIN R4XSTART\n";
const start_doc_end = "R4OS-CONTRACT-GENERATED:END R4XSTART\n";
const r4l_contract_begin = "R4OS-CONTRACT-GENERATED:BEGIN R4LQUERY\n";
const r4l_contract_end = "R4OS-CONTRACT-GENERATED:END R4LQUERY\n";
const max_contract_bytes: usize = 8 * 1024 * 1024;

const Action = enum { validate, check, write, selftest };
const Endianness = enum { little, big };
const SlotState = enum { function, reserved, tombstone };
const GroupKind = enum { kernel_table, r4l_library };
const TypeKind = enum { scalar, named, pointer, array, slice, optional };
const PointerKind = enum { single, many, sentinel };
const PointerDirection = enum { input, output, inout };
const PointerOwnership = enum { borrowed, caller_owned, callee_owned };
const PointerLifetime = enum { call, context, process, buffer };
const TypeClassification = enum { extensible, fixed_layout, @"opaque", callback };
const TypeRepresentation = enum { extern_struct, enum_value, flagset, c_callback, sdk_source };
const ContractStability = enum { fixed_contract, runtime_reported, internal };
const ConstantCategory = enum { magic, version, flag, identity, value };
const DefaultKind = enum { none, integer, boolean, empty, null_pointer, zero_array, empty_array };
const ApiExposure = enum { public, advanced, internal };
const BlockingRule = enum { nonblocking, may_block, blocking_wait };
const ThreadingRule = enum { immutable, thread_compatible, thread_safe, owner_thread_only, serialized_context, caller_serialized };
const TimeoutRule = enum { none, wait_budget, operation_deadline };
const CancelRule = enum { not_cancellable, cooperative_stop, request_cancel_on_deadline, shutdown_wakeup };
const TimeoutOutcomeRule = enum { none, state_unchanged, completion_wins, request_cancelled, outcome_unknown };
const ReentrancyRule = enum { reentrant, serialized, owner_thread_only };
const CallbackContextRule = enum { none, caller_thread, created_thread };
const BufferCompletionRule = enum { none, call, completion_or_cancel };
const ShutdownRule = enum { none, wait_then_close, request_close_wait_reap, cancel_wake_join_cleanup };
const OwnershipRule = enum { none, borrowed, caller_buffer, returns_owned_handle, consumes_owned_handle };
const CloseRule = enum { none, explicit_close_required, invalidates_on_success, path_based_no_handle };
const OutputRule = enum { none, success_only, progress_reported, valid_on_documented_error };
const SideEffectRule = enum { none, atomic_on_success, may_have_occurred, confirmed_progress };
const RetryRule = enum { idempotent, retry_from_reported_progress, never_automatic };
const BufferRule = enum { none, fixed_capacity, explicit_length, required_size_reported, caller_capacity_without_required_size };
const BufferLifetimeRule = enum { none, call, context, process };
const LanguageParity = enum { zig_and_c_required, internal_only };

const OperationSemantics = struct {
    exposure: ApiExposure,
    requirements: [][]const u8,
    optional_capability: bool,
    error_domain: []const u8,
    ownership: OwnershipRule,
    buffer_lifetime: BufferLifetimeRule,
    blocking: BlockingRule,
    threading: ThreadingRule,
    timeout: TimeoutRule,
    cancel: CancelRule,
    timeout_outcome: TimeoutOutcomeRule,
    reentrancy: ReentrancyRule,
    callback_context: CallbackContextRule,
    buffer_completion: BufferCompletionRule,
    shutdown: ShutdownRule,
    close_rule: CloseRule,
    outputs: OutputRule,
    side_effects: SideEffectRule,
    retry: RetryRule,
    buffer_too_small: BufferRule,
    language_parity: LanguageParity,
};

const Target = struct {
    architecture: []const u8,
    endianness: Endianness,
    pointer_size: u32,
    calling_convention: []const u8,
};

const AbiRoot = struct {
    name: []const u8,
    contract: []const u8,
};

const TypeRef = struct {
    kind: TypeKind,
    name: ?[]const u8 = null,
    pointer_kind: ?PointerKind = null,
    is_const: ?bool = null,
    sentinel: ?u32 = null,
    length: ?u32 = null,
    child: ?*TypeRef = null,
    direction: ?PointerDirection = null,
    nullable: ?bool = null,
    length_by: ?[]const u8 = null,
    ownership: ?PointerOwnership = null,
    lifetime: ?PointerLifetime = null,
};

const Parameter = struct {
    name: []const u8,
    type: TypeRef,
};

const Signature = struct {
    calling_convention: []const u8,
    parameters: []Parameter,
    returns: TypeRef,
};

const Entry = struct {
    symbol: []const u8,
    version: u32,
    required: bool,
    description: []const u8,
    signature: Signature,
};

const Metadata = struct {
    key: []const u8,
    value: []const u8,
};

const Field = struct {
    name: []const u8,
    offset: u32,
    type: TypeRef,
    description: []const u8,
    size: ?u32 = null,
    alignment: ?u32 = null,
    source_type: ?[]const u8 = null,
    default_kind: DefaultKind = .none,
    default_value: ?[]const u8 = null,
};

const StructContract = struct {
    name: []const u8,
    size: u32,
    fields: []Field,
};

const NamedValue = struct {
    name: []const u8,
    value: u32,
    description: []const u8,
};

const Callback = struct {
    name: []const u8,
    state: SlotState,
    required: bool,
    description: []const u8,
    signature: ?Signature = null,
};

const R4XStart = struct {
    magic: u32,
    abi_major: u32,
    abi_minor: u32,
    entry: Entry,
    metadata: []Metadata,
    context: StructContract,
    import_contract: StructContract,
    flags: []NamedValue,
    import_flags: []NamedValue,
    app_classes: []NamedValue,
    callbacks: []Callback,
};

const R4LQuery = struct {
    magic: u32,
    abi_version: u32,
    entry_symbol: []const u8,
    entry_version: u32,
    pointer_size: u32,
    layout: StructContract,
};

const Slot = struct {
    number: u32,
    offset: u32,
    name: []const u8,
    state: SlotState,
    required: bool,
    description: []const u8,
    signature: ?Signature = null,
    semantics: OperationSemantics,
};

const Group = struct {
    id: u32,
    name: []const u8,
    query_import: []const u8,
    kind: GroupKind,
    table_type: []const u8,
    fn_namespace: []const u8,
    required: bool,
    magic: u32,
    abi_version: u32,
    header_size: u32,
    pointer_size: u32,
    size: u32,
    slots: []Slot,
};

const AppProfile = struct {
    name: []const u8,
    value: u8,
    app_class: []const u8,
    required_groups: [][]const u8,
    optional_groups: [][]const u8,
    description: []const u8,
};

const ParityFixture = struct {
    id: []const u8,
    since: []const u8,
    scope: [][]const u8,
    zig_fixture: []const u8,
    c_fixture: []const u8,
    gate: []const u8,
};

const TypeDeclaration = struct {
    name: []const u8,
    source: []const u8,
    classification: TypeClassification,
    representation: TypeRepresentation,
    version: u32,
    size: u32,
    alignment: u32,
    source_layout: []const u8,
    size_field: ?[]const u8 = null,
    fields: []Field,
    values: []SignedNamedValue,
    callback: ?Signature = null,
    description: []const u8,
};

const OperationDeclaration = struct {
    name: []const u8,
    group: []const u8,
    root: []const u8,
    source_signature: []const u8,
    uses_types: [][]const u8,
    description: []const u8,
    semantics: OperationSemantics,
};

const StatusDomain = struct {
    name: []const u8,
    id: u16,
    description: []const u8,
};

const SignedNamedValue = struct {
    name: []const u8,
    value: i64,
    description: []const u8,
};

const SdkRoot = struct {
    name: []const u8,
    group: []const u8,
    source: []const u8,
    representation: []const u8,
    types: [][]const u8,
    operations: [][]const u8,
    description: []const u8,
};

const ErrorValue = struct {
    name: []const u8,
    value: i64,
    value_type: []const u8,
    description: []const u8,
};

const ErrorDomain = struct {
    name: []const u8,
    unit: []const u8,
    scope: []const u8,
    stability: ContractStability,
    values: []ErrorValue,
    description: []const u8,
};

const ContractConstant = struct {
    name: []const u8,
    value: []const u8,
    value_type: []const u8,
    category: ConstantCategory,
    unit: []const u8,
    scope: []const u8,
    stability: ContractStability,
    description: []const u8,
};

const ContractLimit = struct {
    name: []const u8,
    value: []const u8,
    value_type: []const u8,
    unit: []const u8,
    scope: []const u8,
    stability: ContractStability,
    description: []const u8,
};

const ArtifactField = struct {
    name: []const u8,
    description: []const u8,
};

const ArtifactMetadata = struct {
    container: []const u8,
    module_kinds: [][]const u8,
    r4x_required_metadata: []Metadata,
    extensible_fields: []ArtifactField,
};

const Contract = struct {
    schema_version: u32,
    baseline_id: []const u8,
    target: Target,
    abi_roots: []AbiRoot,
    r4x_start: R4XStart,
    r4l_query: R4LQuery,
    groups: []Group,
    app_profiles: []AppProfile,
    parity_fixtures: []ParityFixture,
    sdk_roots: []SdkRoot,
    types: []TypeDeclaration,
    operations: []OperationDeclaration,
    status_domains: []StatusDomain,
    error_domains: []ErrorDomain,
    constants: []ContractConstant,
    limits: []ContractLimit,
    artifact_metadata: ArtifactMetadata,
};

const Options = struct {
    action: Action = .validate,
    action_set: bool = false,
    update_baseline: bool = false,
    schema_path: []const u8 = default_schema_path,
    baseline_path: []const u8 = default_baseline_path,
    reference_path: []const u8 = default_payload_reference_path,
    zig_abi_path: []const u8 = default_zig_abi_path,
    zig_exports_path: []const u8 = default_zig_exports_path,
    kernel_abi_path: []const u8 = default_kernel_abi_path,
    kernel_exports_path: []const u8 = default_kernel_exports_path,
    c_abi_path: []const u8 = default_c_abi_path,
    zig_conformance_path: []const u8 = default_zig_conformance_path,
    c_conformance_path: []const u8 = default_c_conformance_path,
    start_doc_path: []const u8 = default_start_doc_path,
    r4l_contract_path: []const u8 = default_r4l_contract_path,
};

const ExpectedGroup = struct {
    id: u32,
    name: []const u8,
    kind: GroupKind,
    functions: usize,
    reserved: usize,
    tombstones: usize,
};

const phase_a_groups = [_]ExpectedGroup{
    // 0.69.46 appends generation-keyed registry snapshot paging and bounded
    // atomic registry batches at slots 120..122. 0.70.8 appends asynchronous
    // offset writes, file-size queries and advisory range locks at 123..125.
    // 0.76.8 appends fifteen storage inventory/claim/I/O/mount/use slots.
    .{ .id = 1, .name = "R4SYS", .kind = .kernel_table, .functions = 138, .reserved = 2, .tombstones = 1 },
    // 0.62.31 activates slot 36 for Unicode keyboard codepoints while the
    // original byte-oriented read_key remains ABI-compatible at slot 0.
    // The append-only console input transport occupies slot 52; 0.69.47
    // appends explicit remote-frame consumer lifetime at slots 53..55;
    // 0.69.48 adds one-generation multi-region publication at slot 56;
    // 0.69.67 appends the generation-bound console-input wait at slot 57;
    // 0.72.1 adds ordered layout-independent physical keys at slot 58.
    .{ .id = 2, .name = "R4DESK", .kind = .kernel_table, .functions = 58, .reserved = 1, .tombstones = 0 },
    // 0.62.3 used the first public R4DRAW extension slot for font_reload;
    // 0.62.4 added the transient glyph-row query, 0.62.41 appends the
    // font-neutral hosted Alpha8 coverage-mask transport, and 0.62.43 adds
    // transactional frame lifecycle, batch append, info and snapshot slots
    // 26..31. 0.69.47 appends the source-stride display rect at slot 32;
    // 0.69.48 adds canonical regions, capabilities and completion at 33..35;
    // 0.69.62 appends bounded GUI damage generations at slots 36..38;
    // 0.75.4 adds the one-lookup bulk glyph snapshot at slot 39; 0.75.5
    // appends the font-catalogue generation used by consumer caches at 40;
    // 0.75.16 adds replacement streams at 41..42 and 0.75.17 appends the
    // bounded shared-raster lifecycle at 43..48.
    .{ .id = 3, .name = "R4DRAW", .kind = .kernel_table, .functions = 49, .reserved = 0, .tombstones = 0 },
    // 0.69.12 activates the two preallocated R4NET extension slots for the
    // generation-bound service request path and its kernel-channel telemetry;
    // 0.75.18 appends the TCP burst/ACK/poll performance snapshot at slot 34.
    .{ .id = 4, .name = "R4NET", .kind = .kernel_table, .functions = 35, .reserved = 0, .tombstones = 0 },
    .{ .id = 5, .name = "R4AUDIO", .kind = .kernel_table, .functions = 19, .reserved = 2, .tombstones = 0 },
    // R4DEV extends the passive diagnostic tail through slot 41 with the
    // canonical PCI and input snapshots; slot 27 remains frozen.
    .{ .id = 6, .name = "R4DEV", .kind = .kernel_table, .functions = 40, .reserved = 2, .tombstones = 0 },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const options = try parseOptions(args);

    const schema_bytes = try cwd.readFileAlloc(io, options.schema_path, allocator, .limited(max_contract_bytes));
    defer allocator.free(schema_bytes);
    var parsed = try std.json.parseFromSlice(Contract, allocator, schema_bytes, .{});
    defer parsed.deinit();

    if (options.action == .selftest) {
        const baseline_bytes = try cwd.readFileAlloc(io, options.baseline_path, allocator, .limited(max_contract_bytes));
        defer allocator.free(baseline_bytes);
        var baseline = try std.json.parseFromSlice(Contract, allocator, baseline_bytes, .{});
        defer baseline.deinit();
        try validateContract(allocator, &parsed.value, &baseline.value);
        try runSelftest(allocator, &parsed.value, &baseline.value);
        std.debug.print("ApiContractGen selftest OK: 26/26 Mutationen erkannt; zentrale Runtime-R4L-Gruppen abgelehnt, gueltige Slot-/Payload-Appends, Extensible-Canaries und API-Inventarauswahl akzeptiert.\n", .{});
        return;
    }

    try validateInternal(&parsed.value, options.update_baseline);
    const payload_reference = try renderPayloadReference(allocator, &parsed.value);
    defer allocator.free(payload_reference);
    const zig_abi = try renderZigAbi(allocator, &parsed.value);
    defer allocator.free(zig_abi);
    const zig_exports = try renderZigExports(allocator, &parsed.value);
    defer allocator.free(zig_exports);
    const kernel_abi = try renderKernelAbi(allocator, &parsed.value);
    defer allocator.free(kernel_abi);
    const kernel_exports = try renderKernelExports(allocator, &parsed.value);
    defer allocator.free(kernel_exports);
    const c_abi = try renderCAbi(allocator, &parsed.value);
    defer allocator.free(c_abi);
    const zig_conformance = try renderZigConformance(allocator, &parsed.value);
    defer allocator.free(zig_conformance);
    const c_conformance = try renderCConformance(allocator, &parsed.value);
    defer allocator.free(c_conformance);
    const start_doc = try renderStartDoc(allocator, &parsed.value);
    defer allocator.free(start_doc);
    const r4l_contract = try renderR4LContract(allocator, &parsed.value);
    defer allocator.free(r4l_contract);

    if (options.action == .write and options.update_baseline) {
        const canonical = try canonicalAlloc(allocator, parsed.value);
        defer allocator.free(canonical);
        try cwd.writeFile(io, .{ .sub_path = options.schema_path, .data = canonical });
        try cwd.writeFile(io, .{ .sub_path = options.baseline_path, .data = canonical });
        try cwd.writeFile(io, .{ .sub_path = options.reference_path, .data = payload_reference });
        try cwd.writeFile(io, .{ .sub_path = options.zig_abi_path, .data = zig_abi });
        try cwd.writeFile(io, .{ .sub_path = options.zig_exports_path, .data = zig_exports });
        try cwd.writeFile(io, .{ .sub_path = options.kernel_abi_path, .data = kernel_abi });
        try cwd.writeFile(io, .{ .sub_path = options.kernel_exports_path, .data = kernel_exports });
        try writeGeneratedOutputs(io, cwd, allocator, &parsed.value, options, c_abi, zig_conformance, c_conformance, start_doc, r4l_contract);
        printHash(canonical);
        std.debug.print("ApiContractGen baseline written: {s}\n", .{options.baseline_path});
        return;
    }

    const baseline_bytes = try cwd.readFileAlloc(io, options.baseline_path, allocator, .limited(max_contract_bytes));
    defer allocator.free(baseline_bytes);
    var baseline = try std.json.parseFromSlice(Contract, allocator, baseline_bytes, .{});
    defer baseline.deinit();
    try validateContract(allocator, &parsed.value, &baseline.value);

    const canonical = try canonicalAlloc(allocator, parsed.value);
    defer allocator.free(canonical);
    switch (options.action) {
        .validate => {},
        .check => {
            if (!std.mem.eql(u8, schema_bytes, canonical)) return error.SchemaNotCanonical;
            const baseline_canonical = try canonicalAlloc(allocator, baseline.value);
            defer allocator.free(baseline_canonical);
            if (!std.mem.eql(u8, baseline_bytes, baseline_canonical)) return error.BaselineNotCanonical;
            const reference_bytes = try cwd.readFileAlloc(io, options.reference_path, allocator, .limited(max_contract_bytes));
            defer allocator.free(reference_bytes);
            if (!std.mem.eql(u8, reference_bytes, payload_reference)) return error.PayloadReferenceDrift;
            const zig_abi_bytes = try cwd.readFileAlloc(io, options.zig_abi_path, allocator, .limited(max_contract_bytes));
            defer allocator.free(zig_abi_bytes);
            if (!std.mem.eql(u8, zig_abi_bytes, zig_abi)) return error.ZigAbiDrift;
            try checkExactFile(io, cwd, allocator, options.zig_exports_path, zig_exports, error.ZigExportsDrift);
            const kernel_abi_bytes = try cwd.readFileAlloc(io, options.kernel_abi_path, allocator, .limited(max_contract_bytes));
            defer allocator.free(kernel_abi_bytes);
            if (!std.mem.eql(u8, kernel_abi_bytes, kernel_abi)) return error.KernelAbiDrift;
            try checkExactFile(io, cwd, allocator, options.kernel_exports_path, kernel_exports, error.KernelExportsDrift);
            try checkGeneratedOutputs(io, cwd, allocator, &parsed.value, options, c_abi, zig_conformance, c_conformance, start_doc, r4l_contract);
        },
        .write => {
            try cwd.writeFile(io, .{ .sub_path = options.schema_path, .data = canonical });
            try cwd.writeFile(io, .{ .sub_path = options.reference_path, .data = payload_reference });
            try cwd.writeFile(io, .{ .sub_path = options.zig_abi_path, .data = zig_abi });
            try cwd.writeFile(io, .{ .sub_path = options.zig_exports_path, .data = zig_exports });
            try cwd.writeFile(io, .{ .sub_path = options.kernel_abi_path, .data = kernel_abi });
            try cwd.writeFile(io, .{ .sub_path = options.kernel_exports_path, .data = kernel_exports });
            try writeGeneratedOutputs(io, cwd, allocator, &parsed.value, options, c_abi, zig_conformance, c_conformance, start_doc, r4l_contract);
        },
        .selftest => unreachable,
    }
    printHash(canonical);
    std.debug.print("ApiContractGen {s} OK: groups={d} slots={d} payloads={d} operations={d}.\n", .{ @tagName(options.action), parsed.value.groups.len, slotCount(&parsed.value), parsed.value.types.len, parsed.value.operations.len });
}

fn parseOptions(args: []const []const u8) !Options {
    var out: Options = .{};
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--validate")) {
            try setAction(&out, .validate);
        } else if (std.mem.eql(u8, arg, "--check")) {
            try setAction(&out, .check);
        } else if (std.mem.eql(u8, arg, "--write")) {
            try setAction(&out, .write);
        } else if (std.mem.eql(u8, arg, "--selftest")) {
            try setAction(&out, .selftest);
        } else if (std.mem.eql(u8, arg, "--baseline")) {
            out.update_baseline = true;
        } else if (std.mem.eql(u8, arg, "--schema")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.schema_path = args[i];
        } else if (std.mem.eql(u8, arg, "--baseline-path")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.baseline_path = args[i];
        } else if (std.mem.eql(u8, arg, "--reference")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.reference_path = args[i];
        } else if (std.mem.eql(u8, arg, "--zig-abi")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.zig_abi_path = args[i];
        } else if (std.mem.eql(u8, arg, "--zig-exports")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.zig_exports_path = args[i];
        } else if (std.mem.eql(u8, arg, "--kernel-abi")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.kernel_abi_path = args[i];
        } else if (std.mem.eql(u8, arg, "--kernel-exports")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.kernel_exports_path = args[i];
        } else if (std.mem.eql(u8, arg, "--c-abi")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.c_abi_path = args[i];
        } else if (std.mem.eql(u8, arg, "--zig-conformance")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.zig_conformance_path = args[i];
        } else if (std.mem.eql(u8, arg, "--c-conformance")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            out.c_conformance_path = args[i];
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "/?")) {
            printUsage();
            return error.HelpRequested;
        } else {
            std.debug.print("ApiContractGen: unknown argument {s}\n", .{arg});
            return error.BadArgument;
        }
    }
    if (out.update_baseline and out.action != .write) return error.BaselineRequiresWrite;
    return out;
}

fn setAction(options: *Options, action: Action) !void {
    if (options.action_set) return error.MultipleActions;
    options.action = action;
    options.action_set = true;
}

fn printUsage() void {
    std.debug.print(
        \\Usage: api-contract-gen [--validate|--check|--write|--selftest]
        \\       [--schema PATH] [--baseline-path PATH] [--reference PATH]
        \\       [--zig-abi PATH] [--zig-exports PATH]
        \\       [--kernel-abi PATH] [--kernel-exports PATH]
        \\       [--c-abi PATH] [--zig-conformance PATH] [--c-conformance PATH]
        \\       --write --baseline   # controlled baseline update
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

fn renderZigAbi(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(
        allocator,
        "// Generated by ApiContractGen from ApiContract.json. DO NOT EDIT.\n" ++
            "// This file intentionally has no BOM.\n\n",
    );

    for (contract.constants) |constant| {
        if (std.mem.indexOfScalar(u8, constant.name, '.') != null) continue;
        try appendZigValue(&out, allocator, constant.name, constant.value_type, constant.value);
    }
    for (contract.limits) |limit| {
        if (std.mem.indexOfScalar(u8, limit.name, '.') != null) continue;
        try appendZigValue(&out, allocator, limit.name, limit.value_type, limit.value);
    }
    for (contract.error_domains) |domain| for (domain.values) |value| {
        if (std.mem.indexOfScalar(u8, value.name, '.') != null) continue;
        try appendFmt(&out, allocator, "pub const {s}: {s} = {d};\n", .{ value.name, value.value_type, value.value });
    };

    try out.appendSlice(allocator, "\npub const R4ErrorDomain = enum(u16) {\n");
    for (contract.status_domains) |domain| try appendFmt(&out, allocator, "    {s} = {d},\n", .{ domain.name, domain.id });
    try out.appendSlice(allocator, "};\n");

    try out.appendSlice(allocator, "\npub const R4XStartAppClass = enum(u32) {\n");
    for (contract.r4x_start.app_classes) |item| try appendFmt(&out, allocator, "    {s} = {d},\n", .{ item.name, item.value });
    try out.appendSlice(allocator, "};\n\npub const R4AppProfile = enum(u8) {\n");
    for (contract.app_profiles) |profile| try appendFmt(&out, allocator, "    {s} = {d},\n", .{ profile.name, profile.value });
    try out.appendSlice(allocator, "};\n\npub const R4LGroup = enum(u32) {\n");
    for (contract.groups) |group| {
        try out.appendSlice(allocator, "    ");
        try appendLower(&out, allocator, group.name);
        try appendFmt(&out, allocator, " = {d},\n", .{group.id});
    }
    try out.appendSlice(allocator, "};\n\npub const R4PlatformApiMeta = struct { name: []const u8, group: R4LGroup, query_import: []const u8 };\n");
    try out.appendSlice(allocator, "pub const r4_platform_apis = [_]R4PlatformApiMeta{\n");
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        try out.appendSlice(allocator, "    .{ .name = \"");
        try out.appendSlice(allocator, group.name);
        try out.appendSlice(allocator, "\", .group = .");
        try appendLower(&out, allocator, group.name);
        try appendFmt(&out, allocator, ", .query_import = \"{s}\" }},\n", .{group.query_import});
    }
    try out.appendSlice(allocator, "};\n\n");

    try out.appendSlice(allocator, "pub const R4AppProfileMeta = struct { name: []const u8, app_class: R4XStartAppClass, required_groups: u32, optional_groups: u32 };\n");
    try out.appendSlice(allocator, "pub const r4_app_profiles = [_]R4AppProfileMeta{\n");
    for (contract.app_profiles) |profile| {
        try appendFmt(&out, allocator, "    .{{ .name = \"{s}\", .app_class = .{s}, .required_groups = {d}, .optional_groups = {d} }},\n", .{
            profile.name,
            profile.app_class,
            groupMask(contract, profile.required_groups),
            groupMask(contract, profile.optional_groups),
        });
    }
    // Emitted multi-line on purpose: the generated files are checked with
    // `zig fmt --check` like every other source, and a single-line function
    // body would keep them permanently unformatted.
    try out.appendSlice(allocator, "};\npub fn r4AppProfileMeta(profile: R4AppProfile) R4AppProfileMeta {\n    return r4_app_profiles[@intFromEnum(profile)];\n}\n\n");

    try appendStructContract(&out, allocator, &contract.r4x_start.context);
    try appendStructContract(&out, allocator, &contract.r4x_start.import_contract);
    try appendStructContract(&out, allocator, &contract.r4l_query.layout);

    for (contract.r4x_start.callbacks) |callback| if (callback.signature) |signature| {
        try out.appendSlice(allocator, "pub const R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn = ");
        try appendSignature(&out, allocator, &signature);
        try out.appendSlice(allocator, ";\n");
    };
    try out.appendSlice(allocator, "\n");

    for (contract.types) |payload| {
        if (!std.mem.eql(u8, payload.source, contract_zig_type_source)) continue;
        try appendTypeDeclaration(&out, allocator, &payload);
    }

    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        try appendFnNamespace(&out, allocator, &group);
        try appendGroupTable(&out, allocator, &group);
    }

    try out.appendSlice(
        allocator,
        "pub const R4ApiSlotState = enum(u8) { function, reserved, tombstone };\n" ++
            "pub const R4ApiSlotMeta = struct { number: u32, offset: u32, name: []const u8, state: R4ApiSlotState, required: bool };\n\n",
    );
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        try appendFmt(&out, allocator, "pub const {s}Slots = [_]R4ApiSlotMeta{{\n", .{group.fn_namespace[0 .. group.fn_namespace.len - 3]});
        for (group.slots) |slot| {
            try appendFmt(&out, allocator, "    .{{ .number = {d}, .offset = {d}, .name = \"{s}\", .state = .{s}, .required = {s} }},\n", .{
                slot.number,
                slot.offset,
                slot.name,
                @tagName(slot.state),
                if (slot.required) "true" else "false",
            });
        }
        try out.appendSlice(allocator, "};\n\n");
    }

    try out.appendSlice(allocator, "comptime {\n");
    try appendLayoutAssertions(&out, allocator, &contract.r4x_start.context);
    try appendLayoutAssertions(&out, allocator, &contract.r4x_start.import_contract);
    try appendLayoutAssertions(&out, allocator, &contract.r4l_query.layout);
    for (contract.types) |payload| {
        if (!std.mem.eql(u8, payload.source, contract_zig_type_source) or payload.representation != .extern_struct) continue;
        try appendTypeLayoutAssertions(&out, allocator, &payload);
    }
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        try appendFmt(&out, allocator, "    if (@sizeOf({s}) != {d}) @compileError(\"generated ABI size drift: {s}\");\n", .{ group.table_type, group.size, group.table_type });
        for (group.slots) |slot| try appendFmt(&out, allocator, "    if (@offsetOf({s}, \"{s}\") != {d}) @compileError(\"generated ABI offset drift: {s}.{s}\");\n", .{ group.table_type, slot.name, slot.offset, group.table_type, slot.name });
    }
    try out.appendSlice(allocator, "}\n");
    return out.toOwnedSlice(allocator);
}

fn renderKernelAbi(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    const common = try renderZigAbi(allocator, contract);
    defer allocator.free(common);
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, common);
    try out.appendSlice(allocator, "\n// Typed kernel provider contracts and table builders.\n");
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        const base = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        try appendFmt(&out, allocator, "pub const {s}Provider = struct {{\n", .{base});
        for (group.slots) |slot| {
            if (slot.state != .function) continue;
            try appendFmt(&out, allocator, "    {s}: {s}.{s},\n", .{ slot.name, group.fn_namespace, slot.name });
        }
        try out.appendSlice(allocator, "};\n\n");
        try appendFmt(&out, allocator, "pub fn build{s}Table(provider: {s}Provider) {s} {{\n    return .{{\n", .{ base, base, group.table_type });
        try appendFmt(&out, allocator, "        .magic = {d},\n        .abi_version = {d},\n        .size = {d},\n        .flags = 0,\n", .{ group.magic, group.abi_version, group.size });
        for (group.slots) |slot| {
            if (slot.state == .function) {
                try appendFmt(&out, allocator, "        .{s} = @intFromPtr(provider.{s}),\n", .{ slot.name, slot.name });
            } else {
                try appendFmt(&out, allocator, "        .{s} = 0,\n", .{slot.name});
            }
        }
        try out.appendSlice(allocator, "    };\n}\n\n");
    }
    // The loop leaves a separator blank line after the last table.  The
    // generated file is checked with `zig fmt --check` like every other
    // source, so it has to end with exactly one newline.
    while (out.items.len >= 2 and
        out.items[out.items.len - 1] == '\n' and
        out.items[out.items.len - 2] == '\n')
    {
        out.items.len -= 1;
    }
    return out.toOwnedSlice(allocator);
}

fn renderCAbi(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "/* Generated by ApiContractGen from ApiContract.json. DO NOT EDIT. */\n" ++
        "#ifndef R4OS_ABI_GENERATED_H\n#define R4OS_ABI_GENERATED_H\n\n" ++
        "#include <stddef.h>\n#include <stdint.h>\n\n" ++
        "#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n" ++
        "#if UINTPTR_MAX != 0xffffffffffffffffull\n#error \"R4OS C ABI requires a 64-bit target\"\n#endif\n\n");

    for (contract.constants) |constant| {
        try appendCValueMacro(&out, allocator, constant.name, constant.value_type, constant.value);
    }
    for (contract.limits) |limit| {
        try appendCValueMacro(&out, allocator, limit.name, limit.value_type, limit.value);
    }
    for (contract.error_domains) |domain| for (domain.values) |value| {
        var buffer: [32]u8 = undefined;
        const rendered = try std.fmt.bufPrint(&buffer, "{d}", .{value.value});
        try appendCValueMacro(&out, allocator, value.name, value.value_type, rendered);
    };
    try out.appendSlice(allocator, "\ntypedef enum R4ErrorDomain {\n");
    for (contract.status_domains, 0..) |domain, index| {
        try out.appendSlice(allocator, "    R4_ERROR_DOMAIN_");
        try appendUpper(&out, allocator, domain.name);
        try appendFmt(&out, allocator, " = {d}{s}\n", .{ domain.id, if (index + 1 == contract.status_domains.len) "" else "," });
    }
    try out.appendSlice(allocator, "} R4ErrorDomain;\n\n");

    for (contract.groups) |group| {
        try out.appendSlice(allocator, "#define R4L_GROUP_");
        try appendUpper(&out, allocator, group.name);
        try appendFmt(&out, allocator, " {d}u\n", .{group.id});
    }
    for (contract.r4x_start.app_classes) |app_class| {
        try out.appendSlice(allocator, "#define R4XSTART_APP_CLASS_");
        try appendUpper(&out, allocator, app_class.name);
        try appendFmt(&out, allocator, " {d}u\n", .{app_class.value});
    }
    try out.appendSlice(allocator, "\ntypedef enum R4AppProfile {\n");
    for (contract.app_profiles, 0..) |profile, index| {
        try out.appendSlice(allocator, "    R4_APP_PROFILE_");
        try appendUpper(&out, allocator, profile.name);
        try appendFmt(&out, allocator, " = {d}{s}\n", .{ profile.value, if (index + 1 == contract.app_profiles.len) "" else "," });
    }
    try out.appendSlice(allocator, "} R4AppProfile;\n");
    for (contract.app_profiles) |profile| {
        try out.appendSlice(allocator, "#define R4_APP_PROFILE_");
        try appendUpper(&out, allocator, profile.name);
        try appendFmt(&out, allocator, "_REQUIRED_GROUPS {d}u\n", .{groupMask(contract, profile.required_groups)});
        try out.appendSlice(allocator, "#define R4_APP_PROFILE_");
        try appendUpper(&out, allocator, profile.name);
        try appendFmt(&out, allocator, "_OPTIONAL_GROUPS {d}u\n", .{groupMask(contract, profile.optional_groups)});
    }
    try out.appendSlice(allocator, "\n");

    // C declarations are order-sensitive while Zig declarations are not.
    // Forward-declare every generated extern struct so append-only payloads
    // may embed an existing named contract without duplicating ABI truth or
    // depending on the presentation order of the JSON type inventory.
    for (contract.types) |payload| {
        if (!std.mem.eql(u8, payload.source, contract_zig_type_source) or payload.representation != .extern_struct) continue;
        try out.appendSlice(allocator, "typedef struct ");
        try appendCTypeName(&out, allocator, payload.name);
        try out.append(allocator, ' ');
        try appendCTypeName(&out, allocator, payload.name);
        try out.appendSlice(allocator, ";\n");
    }
    try out.appendSlice(allocator, "\n");

    const c_struct_states = try allocator.alloc(u8, contract.types.len);
    defer allocator.free(c_struct_states);
    @memset(c_struct_states, 0);
    for (contract.types, 0..) |_, index| try appendCStructOrdered(&out, allocator, contract, index, c_struct_states);
    for (contract.types) |payload| {
        if (!std.mem.eql(u8, payload.source, contract_zig_type_source) or payload.representation != .c_callback) continue;
        try appendCCallback(&out, allocator, &payload);
    }
    try appendCStructContract(&out, allocator, &contract.r4x_start.context);
    try appendCStructContract(&out, allocator, &contract.r4x_start.import_contract);
    try appendCStructContract(&out, allocator, &contract.r4l_query.layout);

    for (contract.r4x_start.callbacks) |callback| if (callback.signature) |signature| {
        try out.appendSlice(allocator, "typedef ");
        try appendCType(&out, allocator, &signature.returns, false);
        try out.appendSlice(allocator, " (*R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn)(");
        try appendCParameters(&out, allocator, signature.parameters);
        try out.appendSlice(allocator, ");\n");
    };
    try out.appendSlice(allocator, "\n");

    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        const base = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        for (group.slots) |slot| {
            if (slot.state != .function) continue;
            try out.appendSlice(allocator, "typedef ");
            try appendCType(&out, allocator, &slot.signature.?.returns, false);
            try out.appendSlice(allocator, " (*");
            try out.appendSlice(allocator, base);
            try appendPascal(&out, allocator, slot.name);
            try out.appendSlice(allocator, "Fn)(");
            try appendCParameters(&out, allocator, slot.signature.?.parameters);
            try out.appendSlice(allocator, ");\n");
        }
        try appendCGroupTable(&out, allocator, &group);
    }

    try out.appendSlice(allocator, "\n/* Complete generated size/offset/signature conformance. */\n");
    try appendCLayoutAssertions(&out, allocator, contract.r4x_start.context.name, contract.r4x_start.context.size, contract.r4x_start.context.fields, false);
    try appendCLayoutAssertions(&out, allocator, contract.r4x_start.import_contract.name, contract.r4x_start.import_contract.size, contract.r4x_start.import_contract.fields, false);
    try appendCLayoutAssertions(&out, allocator, contract.r4l_query.layout.name, contract.r4l_query.layout.size, contract.r4l_query.layout.fields, false);
    for (contract.types) |payload| {
        if (!std.mem.eql(u8, payload.source, contract_zig_type_source) or payload.representation != .extern_struct) continue;
        try appendCLayoutAssertions(&out, allocator, payload.name, payload.size, payload.fields, true);
    }
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        try appendFmt(&out, allocator, "_Static_assert(sizeof({s}) == {d}u, \"{s} size mismatch\");\n", .{ group.table_type, group.size, group.table_type });
        const base = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        for (group.slots) |slot| {
            try appendFmt(&out, allocator, "_Static_assert(offsetof({s}, {s}) == {d}u, \"{s}.{s} offset mismatch\");\n", .{ group.table_type, slot.name, slot.offset, group.table_type, slot.name });
            if (slot.state == .function) {
                try out.appendSlice(allocator, "_Static_assert(sizeof(");
                try out.appendSlice(allocator, base);
                try appendPascal(&out, allocator, slot.name);
                try out.appendSlice(allocator, "Fn) == sizeof(uintptr_t), \"generated function pointer size mismatch\");\n");
            }
        }
    }
    try out.appendSlice(allocator, "\n#ifdef __cplusplus\n}\n#endif\n\n#endif\n");
    return out.toOwnedSlice(allocator);
}

fn appendCValueMacro(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value_type: []const u8, value: []const u8) !void {
    try out.appendSlice(allocator, "#define ");
    try appendCMacroName(out, allocator, name);
    try out.append(allocator, ' ');
    const signed = value.len != 0 and value[0] == '-';
    if (std.mem.eql(u8, value_type, "string")) {
        try appendCStringLiteral(out, allocator, value);
    } else if (std.mem.eql(u8, value_type, "i32")) {
        try appendFmt(out, allocator, "((int32_t){s})", .{value});
    } else if (std.mem.eql(u8, value_type, "i16")) {
        try appendFmt(out, allocator, "((int16_t){s})", .{value});
    } else if (std.mem.eql(u8, value_type, "i64")) {
        try appendFmt(out, allocator, "((int64_t){s})", .{value});
    } else if (std.mem.eql(u8, value_type, "u64") or std.mem.eql(u8, value_type, "usize")) {
        try appendFmt(out, allocator, "{s}ull", .{value});
    } else if (signed) {
        try out.appendSlice(allocator, value);
    } else {
        try appendFmt(out, allocator, "{s}u", .{value});
    }
    try out.append(allocator, '\n');
}

fn appendCMacroName(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8) !void {
    if (name.len >= 2 and std.ascii.toLower(name[0]) == 'r' and name[1] == '4') {
        try appendCIdentifierUpper(out, allocator, name);
    } else if (std.mem.startsWith(u8, name, "remote_")) {
        try out.appendSlice(allocator, "R4_");
        try appendCIdentifierUpper(out, allocator, name);
    } else {
        try out.appendSlice(allocator, "R4OS_");
        try appendCIdentifierUpper(out, allocator, name);
    }
}

fn appendCIdentifierUpper(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    for (value) |char| try out.append(allocator, if (std.ascii.isAlphanumeric(char) or char == '_') std.ascii.toUpper(char) else '_');
}

fn appendCStringLiteral(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    try out.append(allocator, '"');
    for (value) |char| switch (char) {
        '\\', '"' => {
            try out.append(allocator, '\\');
            try out.append(allocator, char);
        },
        '\n' => try out.appendSlice(allocator, "\\n"),
        '\r' => try out.appendSlice(allocator, "\\r"),
        '\t' => try out.appendSlice(allocator, "\\t"),
        else => try out.append(allocator, char),
    };
    try out.append(allocator, '"');
}

fn appendCStruct(out: *std.ArrayList(u8), allocator: std.mem.Allocator, payload: *const TypeDeclaration) !void {
    try out.appendSlice(allocator, "typedef struct ");
    try appendCTypeName(out, allocator, payload.name);
    try out.appendSlice(allocator, " {\n");
    for (payload.fields) |field| {
        try out.appendSlice(allocator, "    ");
        try appendCDeclaration(out, allocator, &field.type, field.name);
        try out.appendSlice(allocator, ";\n");
    }
    try out.appendSlice(allocator, "} ");
    try appendCTypeName(out, allocator, payload.name);
    try out.appendSlice(allocator, ";\n\n");
}

fn appendCStructOrdered(out: *std.ArrayList(u8), allocator: std.mem.Allocator, contract: *const Contract, index: usize, states: []u8) anyerror!void {
    const payload = &contract.types[index];
    if (!std.mem.eql(u8, payload.source, contract_zig_type_source) or payload.representation != .extern_struct) return;
    if (states[index] == 2) return;
    if (states[index] == 1) return error.CStructDependencyCycle;
    states[index] = 1;
    for (payload.fields) |field| try appendCValueDependencies(out, allocator, contract, &field.type, states);
    try appendCStruct(out, allocator, payload);
    states[index] = 2;
}

fn appendCValueDependencies(out: *std.ArrayList(u8), allocator: std.mem.Allocator, contract: *const Contract, type_ref: *const TypeRef, states: []u8) anyerror!void {
    switch (type_ref.kind) {
        .named => {
            for (contract.types, 0..) |payload, index| {
                if (!std.mem.eql(u8, payload.name, type_ref.name.?)) continue;
                try appendCStructOrdered(out, allocator, contract, index, states);
                return;
            }
        },
        .array, .optional => try appendCValueDependencies(out, allocator, contract, type_ref.child.?, states),
        .scalar, .pointer, .slice => {},
    }
}

fn appendCCallback(out: *std.ArrayList(u8), allocator: std.mem.Allocator, payload: *const TypeDeclaration) !void {
    const signature = payload.callback.?;
    try out.appendSlice(allocator, "typedef ");
    try appendCType(out, allocator, &signature.returns, false);
    try out.appendSlice(allocator, " (*");
    try appendCTypeName(out, allocator, payload.name);
    try out.appendSlice(allocator, ")(");
    try appendCParameters(out, allocator, signature.parameters);
    try out.appendSlice(allocator, ");\n\n");
}

fn appendCStructContract(out: *std.ArrayList(u8), allocator: std.mem.Allocator, layout: *const StructContract) !void {
    try appendFmt(out, allocator, "typedef struct {s} {{\n", .{layout.name});
    for (layout.fields) |field| {
        try out.appendSlice(allocator, "    ");
        try appendCDeclaration(out, allocator, &field.type, field.name);
        try out.appendSlice(allocator, ";\n");
    }
    try appendFmt(out, allocator, "}} {s};\n\n", .{layout.name});
}

fn appendCGroupTable(out: *std.ArrayList(u8), allocator: std.mem.Allocator, group: *const Group) !void {
    try appendFmt(out, allocator, "\ntypedef struct {s} {{\n    uint32_t magic;\n    uint32_t abi_version;\n    uint32_t size;\n    uint32_t flags;\n", .{group.table_type});
    for (group.slots) |slot| try appendFmt(out, allocator, "    uintptr_t {s};\n", .{slot.name});
    try appendFmt(out, allocator, "}} {s};\n\n", .{group.table_type});
}

fn appendCParameters(out: *std.ArrayList(u8), allocator: std.mem.Allocator, parameters: []const Parameter) !void {
    if (parameters.len == 0) {
        try out.appendSlice(allocator, "void");
        return;
    }
    for (parameters, 0..) |parameter, index| {
        if (index != 0) try out.appendSlice(allocator, ", ");
        try appendCDeclaration(out, allocator, &parameter.type, parameter.name);
    }
}

fn appendCDeclaration(out: *std.ArrayList(u8), allocator: std.mem.Allocator, type_ref: *const TypeRef, name: []const u8) !void {
    if (type_ref.kind == .array) {
        try appendCType(out, allocator, type_ref.child.?, false);
        try appendFmt(out, allocator, " {s}[{d}]", .{ name, type_ref.length.? });
        return;
    }
    if (type_ref.kind == .pointer and type_ref.child.?.kind == .array) {
        try appendCType(out, allocator, type_ref.child.?.child.?, type_ref.is_const == true);
        try appendFmt(out, allocator, " (*{s})[{d}]", .{ name, type_ref.child.?.length.? });
        return;
    }
    try appendCType(out, allocator, type_ref, false);
    try appendFmt(out, allocator, " {s}", .{name});
}

fn appendCType(out: *std.ArrayList(u8), allocator: std.mem.Allocator, type_ref: *const TypeRef, force_const: bool) !void {
    switch (type_ref.kind) {
        .scalar => {
            if (force_const) try out.appendSlice(allocator, "const ");
            const name = type_ref.name.?;
            if (std.mem.eql(u8, name, "u8")) try out.appendSlice(allocator, "uint8_t") else if (std.mem.eql(u8, name, "u16")) try out.appendSlice(allocator, "uint16_t") else if (std.mem.eql(u8, name, "u32")) try out.appendSlice(allocator, "uint32_t") else if (std.mem.eql(u8, name, "u64")) try out.appendSlice(allocator, "uint64_t") else if (std.mem.eql(u8, name, "i16")) try out.appendSlice(allocator, "int16_t") else if (std.mem.eql(u8, name, "i32")) try out.appendSlice(allocator, "int32_t") else if (std.mem.eql(u8, name, "i64")) try out.appendSlice(allocator, "int64_t") else if (std.mem.eql(u8, name, "usize")) try out.appendSlice(allocator, "uintptr_t") else if (std.mem.eql(u8, name, "bool")) try out.appendSlice(allocator, "uint8_t") else if (std.mem.eql(u8, name, "void") or std.mem.eql(u8, name, "anyopaque")) try out.appendSlice(allocator, "void") else return error.UnsupportedCScalar;
        },
        .named => {
            if (force_const) try out.appendSlice(allocator, "const ");
            try appendCTypeName(out, allocator, type_ref.name.?);
        },
        .pointer => {
            try appendCType(out, allocator, type_ref.child.?, type_ref.is_const == true);
            try out.appendSlice(allocator, " *");
        },
        .optional => try appendCType(out, allocator, type_ref.child.?, force_const),
        .array, .slice => return error.UnsupportedCStandaloneType,
    }
}

fn appendCTypeName(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8) !void {
    if (std.mem.eql(u8, name, "R4XStartContext") or std.mem.eql(u8, name, "R4XStartImport") or std.mem.eql(u8, name, "R4LQuery")) {
        try out.appendSlice(allocator, name);
        return;
    }
    if (!std.mem.startsWith(u8, name, "R4")) try out.appendSlice(allocator, "R4");
    for (name) |char| try out.append(allocator, if (char == '.') '_' else char);
}

fn appendCLayoutAssertions(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, size: u32, fields: []const Field, prefix_r4: bool) !void {
    try out.appendSlice(allocator, "_Static_assert(sizeof(");
    if (prefix_r4) try appendCTypeName(out, allocator, name) else try out.appendSlice(allocator, name);
    try appendFmt(out, allocator, ") == {d}u, \"{s} size mismatch\");\n", .{ size, name });
    for (fields) |field| {
        try out.appendSlice(allocator, "_Static_assert(offsetof(");
        if (prefix_r4) try appendCTypeName(out, allocator, name) else try out.appendSlice(allocator, name);
        try appendFmt(out, allocator, ", {s}) == {d}u, \"{s}.{s} offset mismatch\");\n", .{ field.name, field.offset, name, field.name });
    }
}

fn renderZigConformance(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "// Generated by ApiContractGen. DO NOT EDIT.\nconst abi = @import(\"r4os_contract_abi\");\n\ncomptime {\n");
    try appendZigConformanceLayout(&out, allocator, contract.r4x_start.context.name, contract.r4x_start.context.size, contract.r4x_start.context.fields);
    try appendZigConformanceLayout(&out, allocator, contract.r4x_start.import_contract.name, contract.r4x_start.import_contract.size, contract.r4x_start.import_contract.fields);
    try appendZigConformanceLayout(&out, allocator, contract.r4l_query.layout.name, contract.r4l_query.layout.size, contract.r4l_query.layout.fields);
    for (contract.types) |payload| {
        if (!std.mem.eql(u8, payload.source, contract_zig_type_source) or payload.representation != .extern_struct) continue;
        try appendZigConformanceLayout(&out, allocator, payload.name, payload.size, payload.fields);
    }
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        try appendFmt(&out, allocator, "    if (@sizeOf(abi.{s}) != {d}) @compileError(\"{s} size\");\n", .{ group.table_type, group.size, group.table_type });
        for (group.slots) |slot| {
            try appendFmt(&out, allocator, "    if (@offsetOf(abi.{s}, \"{s}\") != {d}) @compileError(\"{s}.{s} offset\");\n", .{ group.table_type, slot.name, slot.offset, group.table_type, slot.name });
            if (slot.state == .function) try appendFmt(&out, allocator, "    if (@sizeOf(abi.{s}.{s}) != 8) @compileError(\"{s}.{s} signature\");\n", .{ group.fn_namespace, slot.name, group.fn_namespace, slot.name });
        }
    }
    var has_runtime_group = false;
    for (contract.groups) |group| if (group.kind == .r4l_library) {
        has_runtime_group = true;
    };
    if (!has_runtime_group) {
        try out.appendSlice(allocator, "}\n\ntest \"generated API contract compiles\" {}\n");
        return out.toOwnedSlice(allocator);
    }
    try out.appendSlice(allocator, "}\n\ntest \"generated API contract compiles\" {\n");
    for (contract.groups) |group| {
        if (group.kind != .r4l_library) continue;
        try out.appendSlice(allocator, "    _ = abi.R4LGroup.");
        try appendLower(&out, allocator, group.name);
        try out.appendSlice(allocator, ";\n");
    }
    try out.appendSlice(allocator, "}\n");
    return out.toOwnedSlice(allocator);
}

fn appendZigConformanceLayout(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, size: u32, fields: []const Field) !void {
    try appendFmt(out, allocator, "    if (@sizeOf(abi.{s}) != {d}) @compileError(\"{s} size\");\n", .{ name, size, name });
    for (fields) |field| try appendFmt(out, allocator, "    if (@offsetOf(abi.{s}, \"{s}\") != {d}) @compileError(\"{s}.{s} offset\");\n", .{ name, field.name, field.offset, name, field.name });
}

fn renderCConformance(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "/* Generated by ApiContractGen. DO NOT EDIT. */\n#include <r4os/abi_generated.h>\n\n");
    for (contract.r4x_start.callbacks) |callback| if (callback.signature != null) {
        try out.appendSlice(allocator, "static R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn r4os_probe_start_");
        try out.appendSlice(allocator, callback.name);
        try out.appendSlice(allocator, " = (R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn)0;\n");
    };
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        const base = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        for (group.slots) |slot| {
            if (slot.state != .function) continue;
            try out.appendSlice(allocator, "static ");
            try out.appendSlice(allocator, base);
            try appendPascal(&out, allocator, slot.name);
            try out.appendSlice(allocator, "Fn r4os_probe_");
            try appendLower(&out, allocator, group.name);
            try out.append(allocator, '_');
            try out.appendSlice(allocator, slot.name);
            try out.appendSlice(allocator, " = (");
            try out.appendSlice(allocator, base);
            try appendPascal(&out, allocator, slot.name);
            try out.appendSlice(allocator, "Fn)0;\n");
        }
    }
    try out.appendSlice(allocator, "\nint r4os_api_contract_conformance_generated(void) { return 0; }\n");
    return out.toOwnedSlice(allocator);
}

fn renderR4LGenerated(allocator: std.mem.Allocator, contract: *const Contract, group: *const Group) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "// Generated by ApiContractGen from ApiContract.json. DO NOT EDIT.\n\n");
    try appendFmt(&out, allocator, "pub const r4l_abi_magic: u32 = {d};\npub const r4l_abi_version: u32 = {d};\npub const r4l_query_struct_size: u32 = {d};\npub const r4l_query_struct_len: usize = r4l_query_struct_size;\n\n", .{ contract.r4l_query.magic, contract.r4l_query.abi_version, contract.r4l_query.layout.size });
    try appendStructContract(&out, allocator, &contract.r4l_query.layout);
    try appendFmt(&out, allocator, "pub const name = \"{s}\";\npub const group_id: u32 = {d};\npub const import_query = \"{s}\";\n\n", .{ group.name, group.id, group.query_import });
    try out.appendSlice(allocator, "pub const query = R4LQuery{\n");
    for (contract.r4l_query.layout.fields) |field| {
        if (std.mem.eql(u8, field.name, "magic")) try appendFmt(&out, allocator, "    .magic = {d},\n", .{contract.r4l_query.magic}) else if (std.mem.eql(u8, field.name, "abi_version")) try appendFmt(&out, allocator, "    .abi_version = {d},\n", .{contract.r4l_query.abi_version}) else if (std.mem.eql(u8, field.name, "size")) try appendFmt(&out, allocator, "    .size = {d},\n", .{contract.r4l_query.layout.size}) else if (std.mem.eql(u8, field.name, "group")) try appendFmt(&out, allocator, "    .group = {d},\n", .{group.id}) else try appendFmt(&out, allocator, "    .{s} = 0,\n", .{field.name});
    }
    try out.appendSlice(allocator, "};\n");
    return out.toOwnedSlice(allocator);
}

fn renderStartDoc(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, start_doc_begin ++ "Dieser Block wird aus ApiContract.json erzeugt und darf nicht von Hand geaendert werden.\n\nKonstanten\n----------\n\n");
    try appendFmt(&out, allocator, "    R4XSTART_MAGIC        = 0x{X:0>8}\n    R4XSTART_ABI_MAJOR    = {d}\n    R4XSTART_ABI_MINOR    = {d}\n    R4XSTART_CONTEXT_SIZE = {d}\n    R4XSTART_IMPORT_SIZE  = {d}\n\n", .{ contract.r4x_start.magic, contract.r4x_start.abi_major, contract.r4x_start.abi_minor, contract.r4x_start.context.size, contract.r4x_start.import_contract.size });
    try appendContractLayout(&out, allocator, &contract.r4x_start.context);
    try appendContractLayout(&out, allocator, &contract.r4x_start.import_contract);
    try out.appendSlice(allocator, "Gruppen-IDs\n-----------\n\n");
    for (contract.groups) |group| try appendFmt(&out, allocator, "    {d} = {s}\n", .{ group.id, group.name });
    try out.appendSlice(allocator, "\nApp-Profile\n-----------\n\n");
    for (contract.app_profiles) |profile| try appendFmt(&out, allocator, "    {s} -> app.class={s}, required-mask=0x{X}, optional-mask=0x{X}\n", .{ profile.name, profile.app_class, groupMask(contract, profile.required_groups), groupMask(contract, profile.optional_groups) });
    try out.appendSlice(allocator, "\nGruppentabellen\n---------------\n\n");
    for (contract.groups) |group| if (group.kind == .kernel_table) try appendFmt(&out, allocator, "    R4XSTART_{s}_VERSION = {d}\n    R4XSTART_{s}_SIZE    = {d}\n", .{ group.name, group.abi_version, group.name, group.size });
    try out.appendSlice(allocator, "\nDie sechs eingebauten Platform APIs beginnen jeweils mit magic, abi_version, size und flags;\ndanach folgen die im Schema definierten 8-Byte-Slots. Externe Runtime-R4Ls\nbesitzen libraryeigene Vertraege und werden hier nicht zentral registriert.\n\n" ++ start_doc_end);
    return out.toOwnedSlice(allocator);
}

fn renderR4LContract(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, r4l_contract_begin ++ "Dieser Block wird aus ApiContract.json erzeugt und darf nicht von Hand geaendert werden.\n\n");
    try appendContractLayout(&out, allocator, &contract.r4l_query.layout);
    try appendFmt(&out, allocator, "Magic: 0x{X:0>8}\nVersion: {d}\nPointergroesse: {d}\nEntry: {s}:{d}\n\nGruppen-IDs\n-----------\n\n", .{ contract.r4l_query.magic, contract.r4l_query.abi_version, contract.r4l_query.pointer_size, contract.r4l_query.entry_symbol, contract.r4l_query.entry_version });
    for (contract.groups) |group| try appendFmt(&out, allocator, "    {d} = {s} ({s})\n", .{ group.id, group.name, @tagName(group.kind) });
    try out.appendSlice(allocator, "\nDiese Gruppen-IDs identifizieren eingebaute Platform APIs und keine R4L-Dateien.\nExterne Runtime-R4Ls besitzen eigene, versionierte Funktionstabellen und werden hier nicht zentral registriert.\n\n" ++ r4l_contract_end);
    return out.toOwnedSlice(allocator);
}

fn appendContractLayout(out: *std.ArrayList(u8), allocator: std.mem.Allocator, layout: *const StructContract) !void {
    try appendFmt(out, allocator, "{s}\n", .{layout.name});
    for (layout.name) |_| try out.append(allocator, '-');
    try out.appendSlice(allocator, "\n\nOffset  Typ  Feld\n");
    for (layout.fields) |field| {
        try appendFmt(out, allocator, "{d:<7} ", .{field.offset});
        try appendTypeRef(out, allocator, &field.type);
        try appendFmt(out, allocator, "  {s}\n", .{field.name});
    }
    try appendFmt(out, allocator, "\nGroesse: {d} Byte\n\n", .{layout.size});
}

fn renderApiReference(allocator: std.mem.Allocator, group: *const Group) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try appendFmt(&out, allocator, "\xEF\xBB\xBF# Plattformgruppe {s}\n\n<!-- R4OS-APIREF:BEGIN {s} (generiert von ApiContractGen aus ApiContract.json - NICHT von Hand editieren) -->\n## Tabellen-Referenz {s} (generiert)\n\n", .{ group.name, group.name, group.name });
    var function_count: usize = 0;
    for (group.slots) |slot| if (slot.state == .function) {
        function_count += 1;
    };
    try appendFmt(&out, allocator, "Kernel-Gruppentabelle `{s}` v{d}, {d} Bytes, {d} Funktionsfelder und {d} Slots insgesamt.\nSignatur-Wahrheit: `abi.{s}` (Feldname == Tabellenfeld).\nEin Feld ist nutzbar, wenn `hasFn(\"feld\")` es als vorhanden meldet.\n\n| Slot | Offset | Zustand | Tabellenfeld | Signatur |\n| ---: | ---: | --- | --- | --- |\n", .{ group.table_type, group.abi_version, group.size, function_count, group.slots.len, group.fn_namespace });
    for (group.slots) |slot| {
        try appendFmt(&out, allocator, "| {d} | {d} | {s} | `{s}` | ", .{ slot.number, slot.offset, @tagName(slot.state), slot.name });
        if (slot.signature) |signature| {
            try out.append(allocator, '`');
            try appendSignature(&out, allocator, &signature);
            try out.append(allocator, '`');
        } else try out.appendSlice(allocator, "-");
        try out.appendSlice(allocator, " |\n");
    }
    try appendFmt(&out, allocator, "<!-- R4OS-APIREF:END {s} -->", .{group.name});
    return out.toOwnedSlice(allocator);
}

fn renderOperationMatrix(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "\xEF\xBB\xBF# Öffentlicher Operationsvertrag\n\n" ++
        "Diese Matrix wird vollständig aus `ApiContract.json` erzeugt. Sie ist die lesbare Sicht auf " ++
        "Reife, Anforderungen, Fehler, Besitz, Blocking, Threading, Lifecycle und Wiederholung. " ++
        "Manuelle Änderungen sind nicht zulässig.\n\n");
    var functions: usize = 0;
    var public_count: usize = 0;
    var advanced_count: usize = 0;
    var internal_count: usize = 0;
    for (contract.groups) |group| for (group.slots) |slot| {
        if (slot.state == .function) functions += 1;
        switch (slot.semantics.exposure) {
            .public => public_count += 1,
            .advanced => advanced_count += 1,
            .internal => internal_count += 1,
        }
    };
    try appendFmt(&out, allocator, "- Physische Gruppenslots: {d}; Funktionen: {d}; reserviert/Tombstone: {d}\n- Sichtbarkeit: public={d}, advanced={d}, internal={d}\n- Zentrale SDK-only-Operationen: {d}\n- Statusdomänen: {d}\n- Sprachparität: public/advanced verlangt Zig und C; internal bleibt intern\n\n", .{ slotCount(contract), functions, slotCount(contract) - functions, public_count, advanced_count, internal_count, contract.operations.len, contract.status_domains.len });
    try out.appendSlice(allocator, "## Statusdomänen\n\n| ID | Name | Bedeutung |\n|---:|---|---|\n");
    for (contract.status_domains) |domain| try appendFmt(&out, allocator, "| {d} | `{s}` | {s} |\n", .{ domain.id, domain.name, domain.description });
    try out.appendSlice(allocator, "\n");
    try out.appendSlice(allocator, "## Gruppenslots\n\n| Gruppe | Slot | Operation | Zustand | Sicht | Anforderungen | Optional | Fehlerdomäne | Besitz | Bufferleben | Blocking | Threading | Close | Outputs | Seiteneffekt | Retry | Buffer-too-small | Parität | Timeout | Cancel | Timeout-Ausgang | Reentrancy | Callback | Buffer-Abschluss | Shutdown |\n|---|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n");
    for (contract.groups) |group| for (group.slots) |slot| {
        try appendFmt(&out, allocator, "| {s} | {d} | `{s}` | {s} | {s} | ", .{ group.name, slot.number, slot.name, @tagName(slot.state), @tagName(slot.semantics.exposure) });
        try appendJoined(&out, allocator, slot.semantics.requirements, ", ");
        try appendFmt(&out, allocator, " | {s} | `{s}` | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} | {s} |\n", .{
            if (slot.semantics.optional_capability) "ja" else "nein",
            slot.semantics.error_domain,
            @tagName(slot.semantics.ownership),
            @tagName(slot.semantics.buffer_lifetime),
            @tagName(slot.semantics.blocking),
            @tagName(slot.semantics.threading),
            @tagName(slot.semantics.close_rule),
            @tagName(slot.semantics.outputs),
            @tagName(slot.semantics.side_effects),
            @tagName(slot.semantics.retry),
            @tagName(slot.semantics.buffer_too_small),
            @tagName(slot.semantics.language_parity),
            @tagName(slot.semantics.timeout),
            @tagName(slot.semantics.cancel),
            @tagName(slot.semantics.timeout_outcome),
            @tagName(slot.semantics.reentrancy),
            @tagName(slot.semantics.callback_context),
            @tagName(slot.semantics.buffer_completion),
            @tagName(slot.semantics.shutdown),
        });
    };
    return out.toOwnedSlice(allocator);
}

fn renderParityReport(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    var group_functions: usize = 0;
    for (contract.groups) |group| for (group.slots) |slot| if (slot.state == .function) {
        group_functions += 1;
    };
    const signature_count = group_functions + contract.operations.len;
    try appendFmt(&out, allocator, "{{\n  \"schema_version\": 1,\n  \"source\": \"{s}\",\n  \"source_schema_version\": {d},\n  \"source_baseline_id\": ", .{ default_schema_path, contract.schema_version });
    try appendJsonString(&out, allocator, contract.baseline_id);
    try appendFmt(&out, allocator, ",\n  \"summary\": {{\n    \"group_function_signatures\": {d},\n    \"sdk_operation_contracts\": {d},\n    \"parity_entries\": {d},\n    \"cross_language_fixtures\": {d}\n  }},\n  \"signature_parity\": [\n", .{ group_functions, contract.operations.len, signature_count, contract.parity_fixtures.len });
    var entry_index: usize = 0;
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        const c_base = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        for (group.slots) |slot| {
            if (slot.state != .function) continue;
            if (entry_index != 0) try out.appendSlice(allocator, ",\n");
            try out.appendSlice(allocator, "    {\n      \"id\": ");
            const id = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ group.name, slot.name });
            defer allocator.free(id);
            try appendJsonString(&out, allocator, id);
            try out.appendSlice(allocator, ",\n      \"kind\": \"group_slot\",\n      \"exposure\": ");
            try appendJsonString(&out, allocator, @tagName(slot.semantics.exposure));
            try out.appendSlice(allocator, ",\n      \"language_parity\": ");
            try appendJsonString(&out, allocator, @tagName(slot.semantics.language_parity));
            try out.appendSlice(allocator, ",\n      \"zig_contract\": ");
            const zig_name = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ group.fn_namespace, slot.name });
            defer allocator.free(zig_name);
            try appendJsonString(&out, allocator, zig_name);
            var c_name: std.ArrayList(u8) = .empty;
            defer c_name.deinit(allocator);
            try c_name.appendSlice(allocator, c_base);
            try appendPascal(&c_name, allocator, slot.name);
            try c_name.appendSlice(allocator, "Fn");
            try out.appendSlice(allocator, ",\n      \"c_contract\": ");
            try appendJsonString(&out, allocator, c_name.items);
            try out.appendSlice(allocator, ",\n      \"coverage\": \"generated_signature\"\n    }");
            entry_index += 1;
        }
    }
    for (contract.operations) |operation| {
        if (entry_index != 0) try out.appendSlice(allocator, ",\n");
        try out.appendSlice(allocator, "    {\n      \"id\": ");
        try appendJsonString(&out, allocator, operation.name);
        try out.appendSlice(allocator, ",\n      \"kind\": \"sdk_operation\",\n      \"exposure\": ");
        try appendJsonString(&out, allocator, @tagName(operation.semantics.exposure));
        try out.appendSlice(allocator, ",\n      \"language_parity\": ");
        try appendJsonString(&out, allocator, @tagName(operation.semantics.language_parity));
        try out.appendSlice(allocator, ",\n      \"zig_contract\": ");
        try appendJsonString(&out, allocator, operation.source_signature);
        try out.appendSlice(allocator, ",\n      \"c_contract\": ");
        try appendJsonString(&out, allocator, operation.name);
        try out.appendSlice(allocator, ",\n      \"coverage\": \"facade_contract\"\n    }");
        entry_index += 1;
    }
    try out.appendSlice(allocator, "\n  ],\n  \"cross_language_fixtures\": ");
    const fixtures = try canonicalAlloc(allocator, contract.parity_fixtures);
    defer allocator.free(fixtures);
    var line_start: usize = 0;
    while (line_start < fixtures.len) {
        const line_end = std.mem.indexOfScalarPos(u8, fixtures, line_start, '\n') orelse fixtures.len;
        if (line_start == 0) {
            try out.appendSlice(allocator, fixtures[line_start..line_end]);
        } else if (line_start < fixtures.len - 1) {
            try out.appendSlice(allocator, "  ");
            try out.appendSlice(allocator, fixtures[line_start..line_end]);
        }
        if (line_end < fixtures.len - 1) try out.append(allocator, '\n');
        line_start = line_end + 1;
    }
    try out.appendSlice(allocator, "\n}\n");
    return out.toOwnedSlice(allocator);
}

fn renderApiInventory(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var group_function_count: usize = 0;
    var sdk_operation_count: usize = 0;
    var public_count: usize = 0;
    var advanced_count: usize = 0;
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        for (group.slots) |slot| {
            if (slot.state != .function or slot.semantics.exposure == .internal) continue;
            group_function_count += 1;
            switch (slot.semantics.exposure) {
                .public => public_count += 1,
                .advanced => advanced_count += 1,
                .internal => unreachable,
            }
        }
    }
    for (contract.operations) |operation| {
        if (operation.semantics.exposure == .internal) continue;
        sdk_operation_count += 1;
        switch (operation.semantics.exposure) {
            .public => public_count += 1,
            .advanced => advanced_count += 1,
            .internal => unreachable,
        }
    }

    try appendFmt(
        &out,
        allocator,
        "{{\n" ++
            "  \"schema_version\": 1,\n" ++
            "  \"generated_from\": \"{s}\",\n" ++
            "  \"contract_schema_version\": {d},\n" ++
            "  \"summary\": {{\n" ++
            "    \"function_count\": {d},\n" ++
            "    \"group_slot_count\": {d},\n" ++
            "    \"sdk_only_count\": {d},\n" ++
            "    \"public_count\": {d},\n" ++
            "    \"advanced_count\": {d}\n" ++
            "  }},\n" ++
            "  \"functions\": [\n",
        .{
            default_schema_path,
            contract.schema_version,
            group_function_count + sdk_operation_count,
            group_function_count,
            sdk_operation_count,
            public_count,
            advanced_count,
        },
    );

    var entry_index: usize = 0;
    for (contract.groups) |group| {
        if (group.kind != .kernel_table) continue;
        for (group.slots) |slot| {
            if (slot.state != .function or slot.semantics.exposure == .internal) continue;
            if (entry_index != 0) try out.appendSlice(allocator, ",\n");
            const name = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ group.name, slot.name });
            defer allocator.free(name);
            try out.appendSlice(allocator, "    {\n      \"name\": ");
            try appendJsonString(&out, allocator, name);
            try out.appendSlice(allocator, ",\n      \"group\": ");
            try appendJsonString(&out, allocator, group.name);
            try appendFmt(&out, allocator, ",\n      \"kind\": \"group_slot\",\n      \"slot\": {d},\n      \"exposure\": ", .{slot.number});
            try appendJsonString(&out, allocator, @tagName(slot.semantics.exposure));
            try out.appendSlice(allocator, ",\n      \"description\": ");
            try appendJsonString(&out, allocator, slot.description);
            try out.appendSlice(allocator, ",\n      \"locations\": {\n        \"sdk\": ");
            try appendJsonString(&out, allocator, default_zig_abi_path);
            try out.appendSlice(allocator, ",\n        \"provider\": ");
            try appendJsonString(&out, allocator, default_kernel_abi_path);
            try out.appendSlice(allocator, "\n      }\n    }");
            entry_index += 1;
        }
    }

    for (contract.operations) |operation| {
        if (operation.semantics.exposure == .internal) continue;
        if (entry_index != 0) try out.appendSlice(allocator, ",\n");
        const root = findSdkRoot(contract, operation.root) orelse return error.InventorySdkRootMissing;
        try out.appendSlice(allocator, "    {\n      \"name\": ");
        try appendJsonString(&out, allocator, operation.name);
        try out.appendSlice(allocator, ",\n      \"group\": ");
        try appendJsonString(&out, allocator, operation.group);
        try out.appendSlice(allocator, ",\n      \"kind\": \"sdk_only\",\n      \"slot\": null,\n      \"exposure\": ");
        try appendJsonString(&out, allocator, @tagName(operation.semantics.exposure));
        try out.appendSlice(allocator, ",\n      \"description\": ");
        try appendJsonString(&out, allocator, operation.description);
        try out.appendSlice(allocator, ",\n      \"locations\": {\n        \"sdk\": ");
        try appendJsonString(&out, allocator, root.source);
        try out.appendSlice(allocator, ",\n        \"provider\": null\n      }\n    }");
        entry_index += 1;
    }

    try out.appendSlice(allocator, "\n  ]\n}\n");
    return out.toOwnedSlice(allocator);
}

fn appendJsonString(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    const rendered = try std.json.Stringify.valueAlloc(allocator, value, .{});
    defer allocator.free(rendered);
    try out.appendSlice(allocator, rendered);
}

fn appendJoined(out: *std.ArrayList(u8), allocator: std.mem.Allocator, values: []const []const u8, separator: []const u8) !void {
    for (values, 0..) |value, index| {
        if (index != 0) try out.appendSlice(allocator, separator);
        try out.appendSlice(allocator, value);
    }
}

fn checkGeneratedOutputs(io: std.Io, cwd: std.Io.Dir, allocator: std.mem.Allocator, contract: *const Contract, options: Options, c_abi: []const u8, zig_conformance: []const u8, c_conformance: []const u8, start_doc: []const u8, r4l_contract: []const u8) !void {
    try checkExactFile(io, cwd, allocator, options.c_abi_path, c_abi, error.CAbiDrift);
    try checkExactFile(io, cwd, allocator, options.zig_conformance_path, zig_conformance, error.ZigConformanceDrift);
    try checkExactFile(io, cwd, allocator, options.c_conformance_path, c_conformance, error.CConformanceDrift);
    const operation_matrix = try renderOperationMatrix(allocator, contract);
    defer allocator.free(operation_matrix);
    try checkExactFile(io, cwd, allocator, default_operation_matrix_path, operation_matrix, error.OperationMatrixDrift);
    const parity_report = try renderParityReport(allocator, contract);
    defer allocator.free(parity_report);
    try checkExactFile(io, cwd, allocator, default_parity_report_path, parity_report, error.ParityReportDrift);
    const api_inventory = try renderApiInventory(allocator, contract);
    defer allocator.free(api_inventory);
    try checkExactFile(io, cwd, allocator, default_api_inventory_path, api_inventory, error.ApiInventoryDrift);
    const zig_exports = try renderZigExports(allocator, contract);
    defer allocator.free(zig_exports);
    const zig_facade = try cwd.readFileAlloc(io, default_zig_facade_path, allocator, .limited(max_contract_bytes));
    defer allocator.free(zig_facade);
    try checkGeneratedFacade(zig_facade, zig_exports, zig_exports_begin, zig_exports_end);
    const start_doc_bytes = try cwd.readFileAlloc(io, options.start_doc_path, allocator, .limited(max_contract_bytes));
    defer allocator.free(start_doc_bytes);
    try checkGeneratedFacade(start_doc_bytes, start_doc, start_doc_begin, start_doc_end);
    const r4l_doc = try cwd.readFileAlloc(io, options.r4l_contract_path, allocator, .limited(max_contract_bytes));
    defer allocator.free(r4l_doc);
    try checkGeneratedFacade(r4l_doc, r4l_contract, r4l_contract_begin, r4l_contract_end);
    for (contract.groups) |group| {
        const r4l_generated = try renderR4LGenerated(allocator, contract, &group);
        defer allocator.free(r4l_generated);
        const r4l_path = try std.fmt.allocPrint(allocator, "{s}/{s}/api_contract_generated.zig", .{ default_group_output_root, group.name });
        defer allocator.free(r4l_path);
        try checkExactFile(io, cwd, allocator, r4l_path, r4l_generated, error.R4LGeneratedDrift);
        if (group.kind == .kernel_table) {
            const api_reference = try renderApiReference(allocator, &group);
            defer allocator.free(api_reference);
            const doc_path = try std.fmt.allocPrint(allocator, "{s}/{s}.md", .{ default_group_docs_root, group.name });
            defer allocator.free(doc_path);
            try checkExactFile(io, cwd, allocator, doc_path, api_reference, error.ApiReferenceDrift);
        }
    }
}

fn writeGeneratedOutputs(io: std.Io, cwd: std.Io.Dir, allocator: std.mem.Allocator, contract: *const Contract, options: Options, c_abi: []const u8, zig_conformance: []const u8, c_conformance: []const u8, start_doc: []const u8, r4l_contract: []const u8) !void {
    try cwd.writeFile(io, .{ .sub_path = options.c_abi_path, .data = c_abi });
    try cwd.writeFile(io, .{ .sub_path = options.zig_conformance_path, .data = zig_conformance });
    try cwd.writeFile(io, .{ .sub_path = options.c_conformance_path, .data = c_conformance });
    const operation_matrix = try renderOperationMatrix(allocator, contract);
    defer allocator.free(operation_matrix);
    try cwd.writeFile(io, .{ .sub_path = default_operation_matrix_path, .data = operation_matrix });
    const parity_report = try renderParityReport(allocator, contract);
    defer allocator.free(parity_report);
    try cwd.writeFile(io, .{ .sub_path = default_parity_report_path, .data = parity_report });
    const api_inventory = try renderApiInventory(allocator, contract);
    defer allocator.free(api_inventory);
    try cwd.writeFile(io, .{ .sub_path = default_api_inventory_path, .data = api_inventory });
    const zig_exports = try renderZigExports(allocator, contract);
    defer allocator.free(zig_exports);
    try writeGeneratedFacade(io, cwd, allocator, default_zig_facade_path, zig_exports, zig_exports_begin, zig_exports_end);
    try writeGeneratedFacade(io, cwd, allocator, options.start_doc_path, start_doc, start_doc_begin, start_doc_end);
    try writeGeneratedFacade(io, cwd, allocator, options.r4l_contract_path, r4l_contract, r4l_contract_begin, r4l_contract_end);
    for (contract.groups) |group| {
        const r4l_generated = try renderR4LGenerated(allocator, contract, &group);
        defer allocator.free(r4l_generated);
        const r4l_path = try std.fmt.allocPrint(allocator, "{s}/{s}/api_contract_generated.zig", .{ default_group_output_root, group.name });
        defer allocator.free(r4l_path);
        try cwd.writeFile(io, .{ .sub_path = r4l_path, .data = r4l_generated });
        if (group.kind == .kernel_table) {
            const api_reference = try renderApiReference(allocator, &group);
            defer allocator.free(api_reference);
            const doc_path = try std.fmt.allocPrint(allocator, "{s}/{s}.md", .{ default_group_docs_root, group.name });
            defer allocator.free(doc_path);
            try cwd.writeFile(io, .{ .sub_path = doc_path, .data = api_reference });
        }
    }
}

fn checkExactFile(io: std.Io, cwd: std.Io.Dir, allocator: std.mem.Allocator, path: []const u8, expected: []const u8, mismatch: anyerror) !void {
    const actual = try cwd.readFileAlloc(io, path, allocator, .limited(max_contract_bytes));
    defer allocator.free(actual);
    if (!std.mem.eql(u8, actual, expected)) return mismatch;
}

fn appendZigValue(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value_type: []const u8, value: []const u8) !void {
    if (std.mem.eql(u8, value_type, "comptime_int")) {
        try appendFmt(out, allocator, "pub const {s} = {s};\n", .{ name, value });
    } else {
        try appendFmt(out, allocator, "pub const {s}: {s} = {s};\n", .{ name, value_type, value });
    }
}

fn appendLower(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    for (value) |char| try out.append(allocator, std.ascii.toLower(char));
}

fn appendUpper(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    for (value) |char| try out.append(allocator, std.ascii.toUpper(char));
}

fn appendPascal(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    var upper = true;
    for (value) |char| {
        if (char == '_') {
            upper = true;
        } else {
            try out.append(allocator, if (upper) std.ascii.toUpper(char) else char);
            upper = false;
        }
    }
}

fn appendStructContract(out: *std.ArrayList(u8), allocator: std.mem.Allocator, layout: *const StructContract) !void {
    try appendFmt(out, allocator, "pub const {s} = extern struct {{\n", .{layout.name});
    for (layout.fields) |field| try appendZigField(out, allocator, &field);
    try out.appendSlice(allocator, "};\n\n");
}

fn appendTypeDeclaration(out: *std.ArrayList(u8), allocator: std.mem.Allocator, payload: *const TypeDeclaration) !void {
    switch (payload.representation) {
        .extern_struct => {
            try appendFmt(out, allocator, "pub const {s} = extern struct {{\n", .{payload.name});
            for (payload.fields) |field| try appendZigField(out, allocator, &field);
            try out.appendSlice(allocator, "};\n\n");
        },
        .enum_value => {
            try appendFmt(out, allocator, "pub const {s} = enum({s}) {{\n", .{ payload.name, payload.source_layout });
            for (payload.values) |value| try appendFmt(out, allocator, "    {s} = {d},\n", .{ value.name, value.value });
            try out.appendSlice(allocator, "};\n\n");
        },
        .c_callback => {
            try appendFmt(out, allocator, "pub const {s} = ", .{payload.name});
            try appendSignature(out, allocator, &payload.callback.?);
            try out.appendSlice(allocator, ";\n\n");
        },
        else => unreachable,
    }
}

fn appendZigField(out: *std.ArrayList(u8), allocator: std.mem.Allocator, field: *const Field) !void {
    try appendFmt(out, allocator, "    {s}: ", .{field.name});
    try appendTypeRef(out, allocator, &field.type);
    switch (field.default_kind) {
        .none => {},
        .integer, .boolean => try appendFmt(out, allocator, " = {s}", .{field.default_value.?}),
        .empty => try out.appendSlice(allocator, " = .{}"),
        .null_pointer => try out.appendSlice(allocator, " = null"),
        .zero_array => try appendFmt(out, allocator, " = .{{0}} ** {d}", .{field.type.length.?}),
        .empty_array => {
            try out.appendSlice(allocator, " = .{");
            try appendTypeRef(out, allocator, field.type.child.?);
            try appendFmt(out, allocator, "{{}}}} ** {d}", .{field.type.length.?});
        },
    }
    try out.appendSlice(allocator, ",\n");
}

fn appendTypeRef(out: *std.ArrayList(u8), allocator: std.mem.Allocator, type_ref: *const TypeRef) !void {
    switch (type_ref.kind) {
        .scalar, .named => try out.appendSlice(allocator, type_ref.name.?),
        .pointer => {
            if (type_ref.nullable == true) try out.append(allocator, '?');
            switch (type_ref.pointer_kind.?) {
                .single => try out.append(allocator, '*'),
                .many => try out.appendSlice(allocator, "[*]"),
                .sentinel => try appendFmt(out, allocator, "[*:{d}]", .{type_ref.sentinel.?}),
            }
            if (type_ref.is_const == true) try out.appendSlice(allocator, "const ");
            try appendTypeRef(out, allocator, type_ref.child.?);
        },
        .array => {
            try appendFmt(out, allocator, "[{d}]", .{type_ref.length.?});
            try appendTypeRef(out, allocator, type_ref.child.?);
        },
        .slice => {
            try out.appendSlice(allocator, "[]");
            if (type_ref.is_const == true) try out.appendSlice(allocator, "const ");
            try appendTypeRef(out, allocator, type_ref.child.?);
        },
        .optional => {
            try out.append(allocator, '?');
            try appendTypeRef(out, allocator, type_ref.child.?);
        },
    }
}

fn appendSignature(out: *std.ArrayList(u8), allocator: std.mem.Allocator, signature: *const Signature) !void {
    try out.appendSlice(allocator, "*const fn (");
    for (signature.parameters, 0..) |parameter, index| {
        if (index != 0) try out.appendSlice(allocator, ", ");
        try appendTypeRef(out, allocator, &parameter.type);
    }
    try out.appendSlice(allocator, ") callconv(.c) ");
    try appendTypeRef(out, allocator, &signature.returns);
}

fn appendFnNamespace(out: *std.ArrayList(u8), allocator: std.mem.Allocator, group: *const Group) !void {
    try appendFmt(out, allocator, "pub const {s} = struct {{\n", .{group.fn_namespace});
    for (group.slots) |slot| {
        if (slot.state != .function) continue;
        try appendFmt(out, allocator, "    pub const {s} = ", .{slot.name});
        try appendSignature(out, allocator, &slot.signature.?);
        try out.appendSlice(allocator, ";\n");
    }
    try out.appendSlice(allocator, "};\n\n");
}

fn appendGroupTable(out: *std.ArrayList(u8), allocator: std.mem.Allocator, group: *const Group) !void {
    try appendFmt(
        out,
        allocator,
        "pub const {s} = extern struct {{\n    magic: u32 = {d},\n    abi_version: u32 = {d},\n    size: u32 = {d},\n    flags: u32 = 0,\n",
        .{ group.table_type, group.magic, group.abi_version, group.size },
    );
    for (group.slots) |slot| try appendFmt(out, allocator, "    {s}: usize = 0,\n", .{slot.name});
    try out.appendSlice(allocator, "};\n\n");
}

fn appendLayoutAssertions(out: *std.ArrayList(u8), allocator: std.mem.Allocator, layout: *const StructContract) !void {
    try appendFmt(out, allocator, "    if (@sizeOf({s}) != {d}) @compileError(\"generated ABI size drift: {s}\");\n", .{ layout.name, layout.size, layout.name });
    for (layout.fields) |field| try appendFmt(out, allocator, "    if (@offsetOf({s}, \"{s}\") != {d}) @compileError(\"generated ABI offset drift: {s}.{s}\");\n", .{ layout.name, field.name, field.offset, layout.name, field.name });
}

fn appendTypeLayoutAssertions(out: *std.ArrayList(u8), allocator: std.mem.Allocator, payload: *const TypeDeclaration) !void {
    try appendFmt(out, allocator, "    if (@sizeOf({s}) != {d}) @compileError(\"generated ABI size drift: {s}\");\n", .{ payload.name, payload.size, payload.name });
    try appendFmt(out, allocator, "    if (@alignOf({s}) != {d}) @compileError(\"generated ABI alignment drift: {s}\");\n", .{ payload.name, payload.alignment, payload.name });
    for (payload.fields) |field| try appendFmt(out, allocator, "    if (@offsetOf({s}, \"{s}\") != {d}) @compileError(\"generated ABI offset drift: {s}.{s}\");\n", .{ payload.name, field.name, field.offset, payload.name, field.name });
}

fn renderZigExports(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, zig_exports_begin ++ "const generated = @import(\"abi_generated.zig\");\n");
    for (contract.constants) |constant| if (std.mem.indexOfScalar(u8, constant.name, '.') == null) try appendZigExport(&out, allocator, constant.name);
    for (contract.limits) |limit| if (std.mem.indexOfScalar(u8, limit.name, '.') == null) try appendZigExport(&out, allocator, limit.name);
    for (contract.error_domains) |domain| for (domain.values) |value| {
        if (std.mem.indexOfScalar(u8, value.name, '.') == null) try appendZigExport(&out, allocator, value.name);
    };
    try appendZigExport(&out, allocator, "R4ErrorDomain");
    try appendZigExport(&out, allocator, "R4XStartAppClass");
    try appendZigExport(&out, allocator, "R4AppProfile");
    try appendZigExport(&out, allocator, "R4AppProfileMeta");
    try appendZigExport(&out, allocator, "r4_app_profiles");
    try appendZigExport(&out, allocator, "r4AppProfileMeta");
    try appendZigExport(&out, allocator, "R4LGroup");
    try appendZigExport(&out, allocator, "R4PlatformApiMeta");
    try appendZigExport(&out, allocator, "r4_platform_apis");
    try appendZigExport(&out, allocator, contract.r4x_start.context.name);
    try appendZigExport(&out, allocator, contract.r4x_start.import_contract.name);
    try appendZigExport(&out, allocator, contract.r4l_query.layout.name);
    for (contract.r4x_start.callbacks) |callback| if (callback.signature != null) {
        try out.appendSlice(allocator, "pub const R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn = generated.R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn;\n");
    };
    for (contract.types) |payload| if (std.mem.eql(u8, payload.source, contract_zig_type_source)) try appendZigExport(&out, allocator, payload.name);
    try appendZigExport(&out, allocator, "R4ApiSlotState");
    try appendZigExport(&out, allocator, "R4ApiSlotMeta");
    for (contract.groups) |group| if (group.kind == .kernel_table) {
        try appendZigExport(&out, allocator, group.fn_namespace);
        try appendZigExport(&out, allocator, group.table_type);
        const prefix = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        try out.appendSlice(allocator, "pub const ");
        try out.appendSlice(allocator, prefix);
        try out.appendSlice(allocator, "Slots = generated.");
        try out.appendSlice(allocator, prefix);
        try out.appendSlice(allocator, "Slots;\n");
    };
    try out.appendSlice(allocator, zig_exports_end);
    return out.toOwnedSlice(allocator);
}

fn renderKernelExports(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, kernel_exports_begin ++ "const generated = @import(\"r4x_api_generated.zig\");\n");
    for (contract.constants) |constant| if (std.mem.indexOfScalar(u8, constant.name, '.') == null) try appendZigExport(&out, allocator, constant.name);
    for (contract.limits) |limit| if (std.mem.indexOfScalar(u8, limit.name, '.') == null) try appendZigExport(&out, allocator, limit.name);
    for (contract.error_domains) |domain| for (domain.values) |value| {
        if (std.mem.indexOfScalar(u8, value.name, '.') == null) try appendZigExport(&out, allocator, value.name);
    };
    try appendZigExport(&out, allocator, "R4ErrorDomain");
    try appendZigExport(&out, allocator, "R4XStartAppClass");
    try appendZigExport(&out, allocator, "R4AppProfile");
    try appendZigExport(&out, allocator, "R4AppProfileMeta");
    try appendZigExport(&out, allocator, "r4_app_profiles");
    try appendZigExport(&out, allocator, "r4AppProfileMeta");
    try appendZigExport(&out, allocator, "R4LGroup");
    try appendZigExport(&out, allocator, "R4PlatformApiMeta");
    try appendZigExport(&out, allocator, "r4_platform_apis");
    try appendZigExport(&out, allocator, contract.r4x_start.context.name);
    try appendZigExport(&out, allocator, contract.r4x_start.import_contract.name);
    try appendZigExport(&out, allocator, contract.r4l_query.layout.name);
    for (contract.r4x_start.callbacks) |callback| if (callback.signature != null) {
        try out.appendSlice(allocator, "pub const R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn = generated.R4XStart");
        try appendPascal(&out, allocator, callback.name);
        try out.appendSlice(allocator, "Fn;\n");
    };
    for (contract.types) |payload| if (std.mem.eql(u8, payload.source, contract_zig_type_source)) try appendZigExport(&out, allocator, payload.name);
    try appendZigExport(&out, allocator, "R4ApiSlotState");
    try appendZigExport(&out, allocator, "R4ApiSlotMeta");
    for (contract.groups) |group| if (group.kind == .kernel_table) {
        try appendZigExport(&out, allocator, group.fn_namespace);
        try appendZigExport(&out, allocator, group.table_type);
        const base = group.fn_namespace[0 .. group.fn_namespace.len - 3];
        try out.appendSlice(allocator, "pub const ");
        try out.appendSlice(allocator, base);
        try out.appendSlice(allocator, "Slots = generated.");
        try out.appendSlice(allocator, base);
        try out.appendSlice(allocator, "Slots;\n");
        try out.appendSlice(allocator, "pub const ");
        try out.appendSlice(allocator, base);
        try out.appendSlice(allocator, "Provider = generated.");
        try out.appendSlice(allocator, base);
        try out.appendSlice(allocator, "Provider;\n");
        try out.appendSlice(allocator, "pub const build");
        try out.appendSlice(allocator, base);
        try out.appendSlice(allocator, "Table = generated.build");
        try out.appendSlice(allocator, base);
        try out.appendSlice(allocator, "Table;\n");
    };
    try out.appendSlice(allocator, kernel_exports_end);
    return out.toOwnedSlice(allocator);
}

fn appendZigExport(out: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8) !void {
    try appendFmt(out, allocator, "pub const {s} = generated.{s};\n", .{ name, name });
}

fn checkGeneratedFacade(facade: []const u8, expected: []const u8, begin_marker: []const u8, end_marker: []const u8) !void {
    const begin = std.mem.indexOf(u8, facade, begin_marker) orelse return error.GeneratedFacadeExportsMissing;
    const end_start = std.mem.indexOfPos(u8, facade, begin, end_marker) orelse return error.GeneratedFacadeExportsMissing;
    const end = end_start + end_marker.len;
    if (!std.mem.eql(u8, facade[begin..end], expected)) return error.GeneratedFacadeExportsDrift;
    if (std.mem.indexOfPos(u8, facade, end, begin_marker) != null) return error.GeneratedFacadeDuplicateExports;
}

fn writeGeneratedFacade(io: std.Io, cwd: std.Io.Dir, allocator: std.mem.Allocator, path: []const u8, exports: []const u8, begin_marker: []const u8, end_marker: []const u8) !void {
    const facade = try cwd.readFileAlloc(io, path, allocator, .limited(max_contract_bytes));
    defer allocator.free(facade);
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(allocator);
    if (std.mem.indexOf(u8, facade, begin_marker)) |begin| {
        const end_start = std.mem.indexOfPos(u8, facade, begin, end_marker) orelse return error.GeneratedFacadeExportsMissing;
        const end = end_start + end_marker.len;
        try out.appendSlice(allocator, facade[0..begin]);
        try out.appendSlice(allocator, exports);
        try out.appendSlice(allocator, facade[end..]);
    } else {
        try out.appendSlice(allocator, exports);
        try out.append(allocator, '\n');
        try out.appendSlice(allocator, facade);
    }
    try cwd.writeFile(io, .{ .sub_path = path, .data = out.items });
}

fn renderPayloadReference(allocator: std.mem.Allocator, contract: *const Contract) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "\xEF\xBB\xBF# Öffentliche API-Payloads\n\n");
    try out.appendSlice(
        allocator,
        "Diese Datei wird deterministisch aus `API/ApiContract.json` erzeugt. " ++
            "Manuelle Änderungen sind nicht zulässig.\n\n" ++
            "Kernel-, Zig- und C-Program-ABI, R4L-Identitaeten, Contractlayouts, " ++
            "API-Referenzen und Conformance-Fixtures werden produktiv aus diesem Schema erzeugt; " ++
            "handgeschriebene Dateien bleiben nur Fassaden oder erklaerende Texte.\n\n",
    );
    try appendFmt(&out, allocator, "- Schema: v{d}, Baseline `{s}`\n", .{ contract.schema_version, contract.baseline_id });
    try appendFmt(&out, allocator, "- Reachability: {d} von {d} Typen aufgelöst oder explizit klassifiziert\n", .{ contract.types.len, contract.types.len });
    try appendFmt(&out, allocator, "- Zentrale SDK-only-Wurzeln: {d}; Runtime-R4Ls besitzen libraryeigene Vertraege\n", .{contract.sdk_roots.len});
    try appendFmt(&out, allocator, "- Operationen: {d}; Fehlerdomänen: {d}; Konstanten: {d}; Limits: {d}\n\n", .{ contract.operations.len, contract.error_domains.len, contract.constants.len, contract.limits.len });

    try out.appendSlice(allocator, "## App-Profile\n\n| Profil | R4X-Klasse | Pflichtgruppen | Optionale Gruppen |\n|---|---|---|---|\n");
    for (contract.app_profiles) |profile| {
        try appendFmt(&out, allocator, "| `{s}` | `{s}` | ", .{ profile.name, profile.app_class });
        for (profile.required_groups, 0..) |name, index| try appendFmt(&out, allocator, "{s}`{s}`", .{ if (index == 0) "" else ", ", name });
        try out.appendSlice(allocator, " | ");
        for (profile.optional_groups, 0..) |name, index| try appendFmt(&out, allocator, "{s}`{s}`", .{ if (index == 0) "" else ", ", name });
        try out.appendSlice(allocator, " |\n");
    }

    try out.appendSlice(allocator, "\n## Layoutvertrag\n\n| Typ | Klasse | Repräsentation | Schema | Kernel | Zig | C-Vertrag |\n|---|---|---|---:|---:|---:|---:|\n");
    for (contract.types) |payload| {
        try appendFmt(&out, allocator, "| `{s}` | {s} | {s} | {d}/{d} | {d}/{d} | {d}/{d} | {d}/{d} |\n", .{
            payload.name,
            @tagName(payload.classification),
            @tagName(payload.representation),
            payload.size,
            payload.alignment,
            payload.size,
            payload.alignment,
            payload.size,
            payload.alignment,
            payload.size,
            payload.alignment,
        });
    }

    try out.appendSlice(allocator, "\n## Typdetails\n");
    for (contract.types) |payload| {
        try appendFmt(&out, allocator, "\n### `{s}`\n\n- Quelle: `{s}`\n- Klasse: `{s}`\n- Repräsentation: `{s}`\n- Version/Größe/Alignment: {d} / {d} / {d}\n", .{
            payload.name,
            payload.source,
            @tagName(payload.classification),
            @tagName(payload.representation),
            payload.version,
            payload.size,
            payload.alignment,
        });
        if (payload.fields.len != 0) {
            try out.appendSlice(allocator, "\n| Feld | Offset | Größe | Align | Quelltyp | Pointer-/Buffervertrag |\n|---|---:|---:|---:|---|---|\n");
            for (payload.fields) |field| {
                const pointer_contract = try pointerContractAlloc(allocator, &field.type);
                defer allocator.free(pointer_contract);
                try appendFmt(&out, allocator, "| `{s}` | {d} | {d} | {d} | `{s}` | {s} |\n", .{ field.name, field.offset, field.size.?, field.alignment.?, field.source_type.?, pointer_contract });
            }
        }
        if (payload.values.len != 0) {
            try out.appendSlice(allocator, "\n| Wert | Nummer |\n|---|---:|\n");
            for (payload.values) |value| try appendFmt(&out, allocator, "| `{s}` | {d} |\n", .{ value.name, value.value });
        }
    }

    try out.appendSlice(allocator, "\n## Fehlerdomänen\n");
    for (contract.error_domains) |domain| {
        try appendFmt(&out, allocator, "\n### `{s}`\n\nGeltung: `{s}`, Einheit: `{s}`, Stabilität: `{s}`.\n\n| Name | Wert | Typ |\n|---|---:|---|\n", .{ domain.name, domain.scope, domain.unit, @tagName(domain.stability) });
        for (domain.values) |value| try appendFmt(&out, allocator, "| `{s}` | {d} | `{s}` |\n", .{ value.name, value.value, value.value_type });
    }

    try out.appendSlice(allocator, "\n## Konstanten\n\n| Name | Wert | Typ | Kategorie | Einheit | Geltung | Stabilität |\n|---|---|---|---|---|---|---|\n");
    for (contract.constants) |constant| {
        try appendFmt(&out, allocator, "| `{s}` | `{s}` | `{s}` | {s} | {s} | `{s}` | {s} |\n", .{ constant.name, constant.value, constant.value_type, @tagName(constant.category), constant.unit, constant.scope, @tagName(constant.stability) });
    }

    try out.appendSlice(allocator, "\n## Limits\n\n| Name | Wert | Typ | Einheit | Geltung | Klassifikation |\n|---|---:|---|---|---|---|\n");
    for (contract.limits) |limit| {
        try appendFmt(&out, allocator, "| `{s}` | `{s}` | `{s}` | {s} | `{s}` | {s} |\n", .{ limit.name, limit.value, limit.value_type, limit.unit, limit.scope, @tagName(limit.stability) });
    }
    return out.toOwnedSlice(allocator);
}

fn pointerContractAlloc(allocator: std.mem.Allocator, type_ref: *const TypeRef) ![]u8 {
    if (type_ref.kind == .pointer or type_ref.kind == .slice) {
        return std.fmt.allocPrint(allocator, "{s}, nullable={any}, length={s}, {s}, lifetime={s}", .{
            @tagName(type_ref.direction.?),
            type_ref.nullable.?,
            type_ref.length_by.?,
            @tagName(type_ref.ownership.?),
            @tagName(type_ref.lifetime.?),
        });
    }
    return allocator.dupe(u8, "-");
}

fn appendFmt(out: *std.ArrayList(u8), allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) !void {
    const rendered = try std.fmt.allocPrint(allocator, format, args);
    defer allocator.free(rendered);
    try out.appendSlice(allocator, rendered);
}

fn printHash(bytes: []const u8) void {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    var hex: [digest.len * 2]u8 = undefined;
    const alphabet = "0123456789abcdef";
    for (digest, 0..) |byte, i| {
        hex[i * 2] = alphabet[byte >> 4];
        hex[i * 2 + 1] = alphabet[byte & 0x0f];
    }
    std.debug.print("ApiContractGen canonical sha256={s}\n", .{hex[0..]});
}

fn slotCount(contract: *const Contract) usize {
    var count: usize = 0;
    for (contract.groups) |group| count += group.slots.len;
    return count;
}

fn validateContract(allocator: std.mem.Allocator, current: *const Contract, baseline: *const Contract) !void {
    try validateInternal(current, false);
    try validateInternal(baseline, true);
    try requireCanonicalEqual(allocator, current.target, baseline.target, error.TargetDrift);
    try requireCanonicalEqual(allocator, current.abi_roots, baseline.abi_roots, error.AbiRootDrift);
    try requireCanonicalEqual(allocator, current.r4x_start, baseline.r4x_start, error.R4XStartDrift);
    try requireCanonicalEqual(allocator, current.r4l_query, baseline.r4l_query, error.R4LQueryDrift);
    try requireCanonicalEqual(allocator, current.app_profiles, baseline.app_profiles, error.AppProfileDrift);
    try requireCanonicalEqual(allocator, current.parity_fixtures, baseline.parity_fixtures, error.ParityFixtureDrift);
    try requireCanonicalEqual(allocator, current.sdk_roots, baseline.sdk_roots, error.SdkRootDrift);
    try validateTypeEvolution(allocator, current.types, baseline.types);
    try requireCanonicalEqual(allocator, current.operations, baseline.operations, error.OperationDrift);
    try requireCanonicalEqual(allocator, current.status_domains, baseline.status_domains, error.StatusDomainDrift);
    try requireCanonicalEqual(allocator, current.error_domains, baseline.error_domains, error.ErrorDomainDrift);
    try requireCanonicalEqual(allocator, current.constants, baseline.constants, error.ConstantDrift);
    try requireCanonicalEqual(allocator, current.limits, baseline.limits, error.LimitDrift);
    try requireCanonicalEqual(allocator, current.artifact_metadata, baseline.artifact_metadata, error.ArtifactMetadataDrift);
    if (!std.mem.eql(u8, current.baseline_id, baseline.baseline_id)) return error.BaselineIdentityDrift;
    if (current.groups.len != baseline.groups.len) return error.GroupCountDrift;

    for (baseline.groups, 0..) |old_group, group_index| {
        const group = &current.groups[group_index];
        if (group.id != old_group.id or
            !std.mem.eql(u8, group.name, old_group.name) or
            !std.mem.eql(u8, group.query_import, old_group.query_import) or
            !std.mem.eql(u8, group.table_type, old_group.table_type) or
            !std.mem.eql(u8, group.fn_namespace, old_group.fn_namespace) or
            group.kind != old_group.kind or group.required != old_group.required or
            group.magic != old_group.magic or group.header_size != old_group.header_size or
            group.pointer_size != old_group.pointer_size)
        {
            return error.GroupIdentityDrift;
        }
        if (group.slots.len < old_group.slots.len) return error.SlotRemoved;
        for (old_group.slots, 0..) |old_slot, slot_index| {
            try requireCanonicalEqual(allocator, group.slots[slot_index], old_slot, error.SlotDrift);
        }
        if (group.slots.len == old_group.slots.len) {
            if (group.abi_version != old_group.abi_version) return error.VersionWithoutAppend;
        } else if (group.abi_version <= old_group.abi_version) {
            return error.AppendWithoutVersionBump;
        }
    }
}

fn validateTypeEvolution(allocator: std.mem.Allocator, current: []const TypeDeclaration, baseline: []const TypeDeclaration) !void {
    if (current.len < baseline.len) return error.TypeCountDrift;
    for (baseline) |old_type| {
        const payload = for (current) |candidate| {
            if (std.mem.eql(u8, candidate.name, old_type.name)) break candidate;
        } else return error.TypeCountDrift;
        if (!std.mem.eql(u8, payload.name, old_type.name) or
            !std.mem.eql(u8, payload.source, old_type.source) or
            payload.classification != old_type.classification or
            payload.representation != old_type.representation or
            payload.alignment != old_type.alignment or
            !std.mem.eql(u8, payload.source_layout, old_type.source_layout) or
            !optionalStringEqual(payload.size_field, old_type.size_field) or
            !std.mem.eql(u8, payload.description, old_type.description) or
            payload.callback != null or old_type.callback != null or
            payload.values.len != old_type.values.len)
        {
            if (payload.classification == .callback and old_type.classification == .callback) {
                try requireCanonicalEqual(allocator, payload, old_type, error.TypeDrift);
                continue;
            }
            return error.TypeDrift;
        }
        try requireCanonicalEqual(allocator, payload.values, old_type.values, error.EnumValueDrift);
        if (payload.classification != .extensible) {
            try requireCanonicalEqual(allocator, payload, old_type, error.TypeDrift);
            continue;
        }
        if (payload.fields.len < old_type.fields.len) return error.TypeFieldRemoved;
        for (old_type.fields, 0..) |old_field, field_index| {
            try requireCanonicalEqual(allocator, payload.fields[field_index], old_field, error.TypeFieldDrift);
        }
        if (payload.fields.len == old_type.fields.len) {
            if (payload.version != old_type.version or payload.size != old_type.size) return error.TypeVersionWithoutAppend;
        } else {
            if (payload.version <= old_type.version or payload.size <= old_type.size) return error.TypeAppendWithoutVersionBump;
            if (payload.fields[old_type.fields.len].offset < old_type.size) return error.TypeAppendNotAtEnd;
        }
    }
}

fn optionalStringEqual(a: ?[]const u8, b: ?[]const u8) bool {
    if (a == null or b == null) return a == null and b == null;
    return std.mem.eql(u8, a.?, b.?);
}

fn requireCanonicalEqual(allocator: std.mem.Allocator, a: anytype, b: @TypeOf(a), mismatch: anyerror) !void {
    const left = try canonicalAlloc(allocator, a);
    defer allocator.free(left);
    const right = try canonicalAlloc(allocator, b);
    defer allocator.free(right);
    if (!std.mem.eql(u8, left, right)) return mismatch;
}

fn validateInternal(contract: *const Contract, phase_a_exact: bool) !void {
    if (contract.schema_version != 11) return error.SchemaVersion;
    if (!std.mem.eql(u8, contract.baseline_id, "standalone-contract-0.64.11")) return error.BaselineIdentity;
    if (!std.mem.eql(u8, contract.target.architecture, "x86_64") or
        contract.target.endianness != .little or contract.target.pointer_size != 8 or
        !std.mem.eql(u8, contract.target.calling_convention, "c")) return error.TargetIdentity;
    if (contract.abi_roots.len < 3) return error.AbiRootsMissing;
    try validateStart(&contract.r4x_start);
    try validateQuery(&contract.r4l_query);
    if (contract.groups.len != phase_a_groups.len) return error.GroupCount;

    for (contract.groups, 0..) |group, index| {
        const expected = phase_a_groups[index];
        if (group.id != expected.id or !std.mem.eql(u8, group.name, expected.name) or group.kind != expected.kind) return error.GroupOrder;
        var expected_import_buf: [32]u8 = undefined;
        const expected_import = std.fmt.bufPrint(&expected_import_buf, "{s}:Query:1", .{group.name}) catch return error.QueryImport;
        if (!std.mem.eql(u8, group.query_import, expected_import)) return error.QueryImport;
        if (group.required != std.mem.eql(u8, group.name, "R4SYS")) return error.GroupRequired;
        var function_count: usize = 0;
        var reserved_count: usize = 0;
        var tombstone_count: usize = 0;
        if (group.kind == .r4l_library) {
            if (group.table_type.len != 0 or group.fn_namespace.len != 0 or group.magic != 0 or group.abi_version != 1 or group.header_size != 0 or group.pointer_size != 8 or group.size != 0 or group.slots.len != 0) return error.LibraryGroupLayout;
        } else {
            if (group.table_type.len == 0 or group.fn_namespace.len == 0 or group.magic == 0 or group.abi_version == 0 or group.header_size != 16 or group.pointer_size != 8) return error.TableHeader;
            const derived_size = group.header_size + @as(u32, @intCast(group.slots.len)) * group.pointer_size;
            if (group.size != derived_size) return error.TableSize;
            for (group.slots, 0..) |slot, slot_index| {
                if (slot.number != slot_index) return error.SlotNumber;
                if (slot.offset != group.header_size + @as(u32, @intCast(slot_index)) * group.pointer_size) return error.SlotOffset;
                if (slot.name.len == 0 or slot.description.len == 0) return error.SlotText;
                if (slot.state == .function and slot.semantics.exposure != .internal and
                    isInventoryPlaceholderDescription(slot.description)) return error.InventoryDescriptionPlaceholder;
                for (group.slots[0..slot_index]) |previous| {
                    if (std.mem.eql(u8, previous.name, slot.name)) return error.DuplicateSlotName;
                }
                switch (slot.state) {
                    .function => {
                        function_count += 1;
                        if (slot.signature == null) return error.FunctionWithoutSignature;
                        try validateSignature(&slot.signature.?);
                    },
                    .reserved => {
                        reserved_count += 1;
                        if (slot.required or slot.signature != null) return error.ReservedReuse;
                    },
                    .tombstone => {
                        tombstone_count += 1;
                        if (slot.required or slot.signature != null) return error.TombstoneReuse;
                    },
                }
                try validateOperationSemantics(&slot.semantics, slot.state != .function);
            }
        }
        if (phase_a_exact) {
            if (function_count != expected.functions or reserved_count != expected.reserved or tombstone_count != expected.tombstones) return error.PhaseABaselineCount;
        } else if (function_count < expected.functions or reserved_count < expected.reserved or tombstone_count < expected.tombstones) return error.PhaseABaselineCount;

        for (contract.groups[0..index]) |previous| {
            if (previous.id == group.id) return error.DuplicateGroupId;
            if (std.mem.eql(u8, previous.name, group.name)) return error.DuplicateGroupName;
            if (std.mem.eql(u8, previous.query_import, group.query_import)) return error.DuplicateQueryImport;
            if (group.magic != 0 and previous.magic == group.magic) return error.DuplicateGroupMagic;
        }
    }
    try validateSdkRoots(contract);
    try validateAppProfiles(contract);
    try validateParityFixtures(contract);
    try validatePublicTypes(contract);
    try validateOperations(contract);
    try validateStatusDomains(contract);
    try validateValueContracts(contract);
    try validateReachability(contract);
    if (!std.mem.eql(u8, contract.artifact_metadata.container, "R4M0")) return error.ArtifactContainer;
}

fn validateParityFixtures(contract: *const Contract) !void {
    if (contract.parity_fixtures.len != 1) return error.ParityFixtureCount;
    const fixture = contract.parity_fixtures[0];
    if (!std.mem.eql(u8, fixture.id, "platform-abi-06411") or
        !std.mem.eql(u8, fixture.since, "0.64.11") or
        fixture.scope.len == 0 or
        !std.mem.eql(u8, fixture.zig_fixture, default_zig_conformance_path) or
        !std.mem.eql(u8, fixture.c_fixture, default_c_conformance_path) or
        !std.mem.eql(u8, fixture.gate, "zig build test")) return error.ParityFixtureIdentity;
}

fn validateAppProfiles(contract: *const Contract) !void {
    const expected = [_][]const u8{ "console", "desktop", "service" };
    if (contract.app_profiles.len != expected.len) return error.AppProfileCount;
    for (contract.app_profiles, 0..) |profile, index| {
        if (!std.mem.eql(u8, profile.name, expected[index]) or profile.value != index or profile.description.len == 0) return error.AppProfileIdentity;
        if (findAppClass(contract, profile.app_class) == null) return error.AppProfileClass;
        if (!containsName(profile.required_groups, "R4SYS")) return error.AppProfileSystemRequired;
        for (profile.required_groups) |name| {
            if (findGroup(contract, name) == null or containsName(profile.optional_groups, name)) return error.AppProfileGroup;
        }
        for (profile.optional_groups) |name| if (findGroup(contract, name) == null) return error.AppProfileGroup;
    }
}

fn findAppClass(contract: *const Contract, name: []const u8) ?u32 {
    for (contract.r4x_start.app_classes) |item| if (std.mem.eql(u8, item.name, name)) return item.value;
    return null;
}

fn findGroup(contract: *const Contract, name: []const u8) ?*const Group {
    for (contract.groups) |*group| if (std.mem.eql(u8, group.name, name)) return group;
    return null;
}

fn findSdkRoot(contract: *const Contract, name: []const u8) ?*const SdkRoot {
    for (contract.sdk_roots) |*root| if (std.mem.eql(u8, root.name, name)) return root;
    return null;
}

fn containsName(names: []const []const u8, wanted: []const u8) bool {
    for (names) |name| if (std.mem.eql(u8, name, wanted)) return true;
    return false;
}

fn groupMask(contract: *const Contract, names: []const []const u8) u32 {
    var mask: u32 = 0;
    for (names) |name| {
        const group = findGroup(contract, name) orelse continue;
        mask |= @as(u32, 1) << @intCast(group.id);
    }
    return mask;
}

fn validateSdkRoots(contract: *const Contract) !void {
    if (contract.sdk_roots.len != 0) return error.CentralSdkRootForbidden;
}

fn validatePublicTypes(contract: *const Contract) !void {
    if (contract.types.len < 90) return error.PayloadTypeCoverage;
    for (contract.types, 0..) |payload, index| {
        if (payload.name.len == 0 or payload.source.len == 0 or payload.description.len == 0 or payload.version == 0) return error.PayloadTypeMetadata;
        for (contract.types[0..index]) |previous| if (std.mem.eql(u8, previous.name, payload.name)) return error.DuplicatePayloadType;
        switch (payload.classification) {
            .callback => {
                if (payload.representation != .c_callback or payload.callback == null or payload.fields.len != 0 or payload.values.len != 0 or payload.size != 8 or payload.alignment != 8) return error.CallbackTypeShape;
                try validateSignature(&payload.callback.?);
            },
            .@"opaque" => {
                if (payload.fields.len != 0 or payload.values.len != 0 or payload.callback != null) return error.OpaqueTypeShape;
            },
            .extensible, .fixed_layout => switch (payload.representation) {
                .extern_struct, .sdk_source => {
                    if (payload.fields.len == 0 or payload.values.len != 0 or payload.callback != null or payload.size == 0 or payload.alignment == 0) return error.StructTypeShape;
                    try validatePayloadFields(contract, &payload);
                    if (payload.classification == .extensible) {
                        if (payload.fields.len < 2 or
                            !std.mem.eql(u8, payload.fields[0].name, "version") or payload.fields[0].offset != 0 or
                            !std.mem.eql(u8, payload.fields[1].name, "size") or payload.fields[1].offset != 4 or
                            payload.size_field == null or !std.mem.eql(u8, payload.size_field.?, "size")) return error.ExtensibleTypeShape;
                    } else if (payload.size_field != null) return error.FixedTypeSizeField;
                },
                .enum_value, .flagset => {
                    if (payload.fields.len != 0 or payload.values.len == 0 or payload.callback != null or payload.size == 0 or payload.alignment == 0 or payload.size_field != null) return error.EnumTypeShape;
                    try validateSignedValues(payload.values);
                },
                else => return error.PayloadRepresentation,
            },
        }
    }
}

fn validatePayloadFields(contract: *const Contract, payload: *const TypeDeclaration) !void {
    for (payload.fields, 0..) |field, index| {
        if (field.name.len == 0 or field.description.len == 0 or field.size == null or field.alignment == null or field.source_type == null or field.source_type.?.len == 0) return error.PayloadFieldMetadata;
        if (field.alignment.? == 0 or field.offset % field.alignment.? != 0 or field.offset + field.size.? > payload.size) {
            std.debug.print("ApiContractGen payload field layout mismatch: {s}.{s} offset={d} size={d} align={d}\n", .{ payload.name, field.name, field.offset, field.size.?, field.alignment.? });
            return error.PayloadFieldLayout;
        }
        for (payload.fields[0..index]) |previous| {
            if (std.mem.eql(u8, previous.name, field.name)) return error.DuplicatePayloadField;
            const previous_end = previous.offset + previous.size.?;
            const field_end = field.offset + field.size.?;
            if (field.offset < previous_end and previous.offset < field_end) return error.PayloadFieldOverlap;
        }
        try validateType(&field.type);
        try validateFieldDefault(&field);
        try validateResolvedTypeRef(contract, &field.type);
        if (payload.representation == .extern_struct and containsHostDependentAbiType(&field.type)) return error.HostDependentAbiType;
        if (resolvedTypeWidth(contract, &field.type)) |width| {
            if (width != field.size.?) return error.PayloadFieldTypeSize;
        }
    }
    if (payload.size % payload.alignment != 0) return error.PayloadSize;
}

fn validateFieldDefault(field: *const Field) !void {
    switch (field.default_kind) {
        .none, .empty, .null_pointer, .zero_array, .empty_array => if (field.default_value != null) return error.FieldDefaultShape,
        .integer => {
            if (field.default_value == null or field.default_value.?.len == 0) return error.FieldDefaultShape;
            _ = std.fmt.parseInt(i128, field.default_value.?, 10) catch return error.FieldDefaultValue;
        },
        .boolean => {
            if (field.default_value == null or
                (!std.mem.eql(u8, field.default_value.?, "true") and !std.mem.eql(u8, field.default_value.?, "false"))) return error.FieldDefaultValue;
        },
    }
    switch (field.default_kind) {
        .null_pointer => if (field.type.kind != .pointer or field.type.nullable != true) return error.FieldDefaultType,
        .zero_array, .empty_array => if (field.type.kind != .array) return error.FieldDefaultType,
        .empty => if (field.type.kind != .named) return error.FieldDefaultType,
        .boolean => if (field.type.kind != .scalar or !std.mem.eql(u8, field.type.name.?, "bool")) return error.FieldDefaultType,
        else => {},
    }
}

fn containsHostDependentAbiType(type_ref: *const TypeRef) bool {
    if (type_ref.kind == .slice or type_ref.kind == .optional) return true;
    if (type_ref.kind == .scalar and (std.mem.eql(u8, type_ref.name.?, "usize") or std.mem.eql(u8, type_ref.name.?, "isize"))) return true;
    return if (type_ref.child) |child| containsHostDependentAbiType(child) else false;
}

fn validateSignedValues(values: []const SignedNamedValue) !void {
    for (values, 0..) |value, index| {
        if (value.name.len == 0 or value.description.len == 0) return error.NamedValueText;
        for (values[0..index]) |previous| {
            if (std.mem.eql(u8, previous.name, value.name)) return error.DuplicateNamedValue;
            if (previous.value == value.value) return error.DuplicateNamedValueNumber;
        }
    }
}

fn validateOperations(contract: *const Contract) !void {
    if (contract.operations.len != 0) return error.CentralSdkOperationForbidden;
}

fn isInventoryPlaceholderDescription(description: []const u8) bool {
    if (!std.mem.endsWith(u8, description, " operation.")) return false;
    return std.mem.startsWith(u8, description, "R4");
}

fn validateOperationSemantics(semantics: *const OperationSemantics, physical_internal: bool) !void {
    if (semantics.requirements.len == 0 or semantics.error_domain.len == 0) return error.OperationSemanticsMissing;
    for (semantics.requirements, 0..) |requirement, index| {
        if (requirement.len == 0) return error.OperationRequirementMissing;
        for (semantics.requirements[0..index]) |previous| if (std.mem.eql(u8, previous, requirement)) return error.DuplicateOperationRequirement;
    }
    if (physical_internal) {
        if (semantics.exposure != .internal or semantics.optional_capability or semantics.ownership != .none or
            semantics.buffer_lifetime != .none or semantics.blocking != .nonblocking or semantics.close_rule != .none or
            semantics.outputs != .none or semantics.side_effects != .none or semantics.retry != .never_automatic or
            semantics.buffer_too_small != .none or semantics.language_parity != .internal_only or
            semantics.timeout != .none or semantics.cancel != .not_cancellable or semantics.timeout_outcome != .none or
            semantics.reentrancy != .serialized or semantics.callback_context != .none or
            semantics.buffer_completion != .none or semantics.shutdown != .none) return error.InternalSlotSemantics;
        return;
    }
    if (semantics.exposure == .internal) {
        if (semantics.language_parity != .internal_only) return error.InternalOperationParity;
    } else if (semantics.language_parity != .zig_and_c_required) return error.PublicOperationParity;
    if (semantics.retry == .retry_from_reported_progress and
        (semantics.outputs != .progress_reported or semantics.side_effects != .confirmed_progress)) return error.ProgressRetryContract;
    if (semantics.buffer_too_small == .required_size_reported and semantics.outputs == .none) return error.RequiredSizeWithoutOutput;
    if (semantics.close_rule == .explicit_close_required and semantics.ownership != .returns_owned_handle) return error.CloseOwnershipContract;
    if (semantics.close_rule == .invalidates_on_success and semantics.ownership != .consumes_owned_handle) return error.InvalidateOwnershipContract;
    if (semantics.close_rule == .path_based_no_handle and
        (semantics.ownership == .returns_owned_handle or semantics.ownership == .consumes_owned_handle)) return error.PathHandleContract;
    if (semantics.blocking == .blocking_wait and semantics.timeout == .none) return error.BlockingWaitWithoutTimeout;
    if (semantics.timeout == .none and semantics.timeout_outcome != .none) return error.TimeoutOutcomeWithoutTimeout;
    if (semantics.timeout != .none and semantics.timeout_outcome == .none) return error.TimeoutWithoutOutcome;
    if (semantics.cancel == .request_cancel_on_deadline and
        (semantics.timeout != .operation_deadline or semantics.timeout_outcome != .request_cancelled)) return error.RequestCancelContract;
    if (semantics.reentrancy == .owner_thread_only and semantics.threading != .owner_thread_only) return error.OwnerThreadContract;
    if (semantics.threading == .owner_thread_only and semantics.reentrancy != .owner_thread_only) return error.OwnerThreadReentrancy;
    if (semantics.buffer_lifetime == .process and semantics.buffer_completion != .completion_or_cancel) return error.AsyncBufferCompletion;
    if (semantics.buffer_completion == .completion_or_cancel and semantics.buffer_lifetime != .process) return error.AsyncBufferLifetime;
}

fn validateStatusDomains(contract: *const Contract) !void {
    if (contract.status_domains.len == 0) return error.StatusDomainsMissing;
    for (contract.status_domains, 0..) |domain, index| {
        if (domain.name.len == 0 or domain.description.len == 0 or domain.id != index) return error.StatusDomainMetadata;
        for (contract.status_domains[0..index]) |previous| if (std.mem.eql(u8, previous.name, domain.name)) return error.DuplicateStatusDomain;
    }
    for (contract.groups) |group| for (group.slots) |slot| {
        if (slot.semantics.exposure == .internal) continue;
        if (!hasStatusDomain(contract, slot.semantics.error_domain)) return error.OperationStatusDomainMissing;
    };
    for (contract.operations) |operation| {
        if (operation.semantics.exposure == .internal) continue;
        if (!hasStatusDomain(contract, operation.semantics.error_domain)) return error.OperationStatusDomainMissing;
    }
}

fn hasStatusDomain(contract: *const Contract, name: []const u8) bool {
    for (contract.status_domains) |domain| if (std.mem.eql(u8, domain.name, name)) return true;
    return false;
}

fn validateValueContracts(contract: *const Contract) !void {
    if (contract.error_domains.len == 0 or contract.constants.len == 0 or contract.limits.len == 0) return error.ValueContractsMissing;
    for (contract.error_domains, 0..) |domain, domain_index| {
        if (domain.name.len == 0 or domain.unit.len == 0 or domain.scope.len == 0 or domain.description.len == 0 or domain.values.len == 0) return error.ErrorDomainMetadata;
        for (contract.error_domains[0..domain_index]) |previous| if (std.mem.eql(u8, previous.name, domain.name)) return error.DuplicateErrorDomain;
        for (domain.values, 0..) |value, value_index| {
            if (value.name.len == 0 or value.value_type.len == 0 or value.description.len == 0) return error.ErrorValueMetadata;
            for (domain.values[0..value_index]) |previous| {
                if (std.mem.eql(u8, previous.name, value.name)) return error.DuplicateErrorValue;
            }
        }
    }
    for (contract.constants, 0..) |constant, index| {
        if (constant.name.len == 0 or constant.value.len == 0 or constant.value_type.len == 0 or constant.unit.len == 0 or constant.scope.len == 0 or constant.description.len == 0) return error.ConstantMetadata;
        for (contract.constants[0..index]) |previous| if (std.mem.eql(u8, previous.name, constant.name)) return error.DuplicateConstant;
    }
    for (contract.limits, 0..) |limit, index| {
        if (limit.name.len == 0 or limit.value.len == 0 or limit.value_type.len == 0 or limit.unit.len == 0 or limit.scope.len == 0 or limit.description.len == 0) return error.LimitMetadata;
        for (contract.limits[0..index]) |previous| if (std.mem.eql(u8, previous.name, limit.name)) return error.DuplicateLimit;
    }
}

fn validateReachability(contract: *const Contract) !void {
    try validateAbiBoundaryTypeRef(contract, &contract.r4x_start.entry.signature.returns);
    for (contract.r4x_start.entry.signature.parameters) |parameter| try validateAbiBoundaryTypeRef(contract, &parameter.type);
    for (contract.r4x_start.context.fields) |field| try validateAbiBoundaryTypeRef(contract, &field.type);
    for (contract.r4x_start.import_contract.fields) |field| try validateAbiBoundaryTypeRef(contract, &field.type);
    for (contract.r4x_start.callbacks) |callback| if (callback.signature) |signature| {
        try validateAbiBoundaryTypeRef(contract, &signature.returns);
        for (signature.parameters) |parameter| try validateAbiBoundaryTypeRef(contract, &parameter.type);
    };
    for (contract.r4l_query.layout.fields) |field| try validateAbiBoundaryTypeRef(contract, &field.type);
    for (contract.groups) |group| for (group.slots) |slot| if (slot.signature) |signature| {
        try validateAbiBoundaryTypeRef(contract, &signature.returns);
        for (signature.parameters) |parameter| try validateAbiBoundaryTypeRef(contract, &parameter.type);
    };
}

fn validateAbiBoundaryTypeRef(contract: *const Contract, type_ref: *const TypeRef) !void {
    try validateResolvedTypeRef(contract, type_ref);
    if (containsHostDependentAbiType(type_ref)) return error.HostDependentAbiType;
    if (type_ref.kind == .named) {
        if (findType(contract, type_ref.name.?)) |payload| {
            if (payload.representation == .sdk_source) return error.SdkSourceTypeAtAbiBoundary;
        }
    }
}

fn validateResolvedTypeRef(contract: *const Contract, type_ref: *const TypeRef) !void {
    if (type_ref.kind == .named and findType(contract, type_ref.name.?) == null and !isRootTypeName(type_ref.name.?)) {
        std.debug.print("ApiContractGen unresolved payload type: {s}\n", .{type_ref.name.?});
        return error.UnresolvedPayloadType;
    }
    if (type_ref.child) |child| try validateResolvedTypeRef(contract, child);
}

fn resolvedTypeWidth(contract: *const Contract, type_ref: *const TypeRef) ?u32 {
    return switch (type_ref.kind) {
        .pointer => 8,
        .slice => 16,
        .optional => null,
        .array => if (resolvedTypeWidth(contract, type_ref.child.?)) |child_width| type_ref.length.? * child_width else null,
        .named => if (findType(contract, type_ref.name.?)) |payload| payload.size else null,
        .scalar => if (std.mem.eql(u8, type_ref.name.?, "u8") or std.mem.eql(u8, type_ref.name.?, "i8") or std.mem.eql(u8, type_ref.name.?, "bool")) 1 else if (std.mem.eql(u8, type_ref.name.?, "u16") or std.mem.eql(u8, type_ref.name.?, "i16")) 2 else if (std.mem.eql(u8, type_ref.name.?, "u32") or std.mem.eql(u8, type_ref.name.?, "i32")) 4 else if (std.mem.eql(u8, type_ref.name.?, "u64") or std.mem.eql(u8, type_ref.name.?, "i64") or std.mem.eql(u8, type_ref.name.?, "usize") or std.mem.eql(u8, type_ref.name.?, "isize")) 8 else if (std.mem.eql(u8, type_ref.name.?, "u128") or std.mem.eql(u8, type_ref.name.?, "i128")) 16 else null,
    };
}

fn findType(contract: *const Contract, name: []const u8) ?*const TypeDeclaration {
    for (contract.types) |*payload| if (std.mem.eql(u8, payload.name, name)) return payload;
    return null;
}

fn payloadTypeIsReferenced(contract: *const Contract, name: []const u8) bool {
    for (contract.types) |payload| {
        for (payload.fields) |field| {
            if (typeRefReferencesName(&field.type, name)) return true;
        }
    }
    return false;
}

fn typeRefReferencesName(type_ref: *const TypeRef, name: []const u8) bool {
    if (type_ref.name) |candidate| {
        if (std.mem.eql(u8, candidate, name)) return true;
    }
    if (type_ref.child) |child| return typeRefReferencesName(child, name);
    return false;
}

fn testApiInventoryRendering(allocator: std.mem.Allocator, contract: *const Contract) !void {
    const inventory = try renderApiInventory(allocator, contract);
    defer allocator.free(inventory);

    for (contract.groups) |group| {
        for (group.slots) |slot| {
            const qualified_name = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ group.name, slot.name });
            defer allocator.free(qualified_name);
            const needle = try std.fmt.allocPrint(allocator, "\"name\": \"{s}\"", .{qualified_name});
            defer allocator.free(needle);
            const expected = group.kind == .kernel_table and slot.state == .function and slot.semantics.exposure != .internal;
            if ((std.mem.indexOf(u8, inventory, needle) != null) != expected) return error.ApiInventorySelection;
        }
    }
    for (contract.operations) |operation| {
        const needle = try std.fmt.allocPrint(allocator, "\"name\": \"{s}\"", .{operation.name});
        defer allocator.free(needle);
        const expected = operation.semantics.exposure != .internal;
        if ((std.mem.indexOf(u8, inventory, needle) != null) != expected) return error.ApiInventorySelection;
    }
}

fn findOperation(contract: *const Contract, name: []const u8) ?*const OperationDeclaration {
    for (contract.operations) |*operation| if (std.mem.eql(u8, operation.name, name)) return operation;
    return null;
}

fn isRootTypeName(name: []const u8) bool {
    return std.mem.eql(u8, name, "R4XStartContext") or std.mem.eql(u8, name, "R4XStartImport") or std.mem.eql(u8, name, "R4LQuery");
}

fn validateStart(start: *const R4XStart) !void {
    if (start.magic != 0x53583452 or start.abi_major != 1 or start.abi_minor != 1) return error.R4XStartIdentity;
    if (!std.mem.eql(u8, start.entry.symbol, "R4XStart") or start.entry.version != 1 or !start.entry.required) return error.R4XEntryIdentity;
    try validateSignature(&start.entry.signature);
    if (start.context.size != 128 or !std.mem.eql(u8, start.context.name, "R4XStartContext")) return error.ContextIdentity;
    if (start.import_contract.size != 40 or !std.mem.eql(u8, start.import_contract.name, "R4XStartImport")) return error.ImportIdentity;
    try validateStruct(&start.context);
    try validateStruct(&start.import_contract);
    if (!hasMetadata(start.metadata, "r4x.start", "r4xstart") or
        !hasMetadata(start.metadata, "r4x.entry", "R4XStart") or
        !hasMetadata(start.metadata, "r4x.context", "R4XStartContext")) return error.StartMetadata;
    try validateNamedValues(start.flags);
    try validateNamedValues(start.import_flags);
    try validateNamedValues(start.app_classes);
    for (start.callbacks, 0..) |callback, index| {
        if (callback.name.len == 0 or callback.description.len == 0) return error.CallbackText;
        for (start.callbacks[0..index]) |previous| if (std.mem.eql(u8, previous.name, callback.name)) return error.DuplicateCallback;
        if (callback.state == .function) {
            if (callback.signature == null) return error.FunctionWithoutSignature;
            try validateSignature(&callback.signature.?);
        } else if (callback.signature != null or callback.required) return error.CallbackState;
    }
}

fn validateQuery(query: *const R4LQuery) !void {
    if (query.magic != 0x314C3452 or query.abi_version != 1 or
        !std.mem.eql(u8, query.entry_symbol, "Query") or query.entry_version != 1 or
        query.pointer_size != 8 or query.layout.size != 32 or
        !std.mem.eql(u8, query.layout.name, "R4LQuery")) return error.R4LQueryIdentity;
    try validateStruct(&query.layout);
}

fn validateStruct(layout: *const StructContract) !void {
    if (layout.name.len == 0 or layout.fields.len == 0) return error.StructEmpty;
    var last_end: u32 = 0;
    for (layout.fields, 0..) |field, index| {
        if (field.name.len == 0 or field.description.len == 0) return error.FieldText;
        if (index != 0 and field.offset < last_end) return error.FieldOrder;
        for (layout.fields[0..index]) |previous| if (std.mem.eql(u8, previous.name, field.name)) return error.DuplicateField;
        try validateType(&field.type);
        try validateFieldDefault(&field);
        last_end = field.offset + typeWidth(&field.type);
    }
    if (last_end > layout.size) return error.StructSize;
}

fn validateNamedValues(values: []const NamedValue) !void {
    for (values, 0..) |value, index| {
        if (value.name.len == 0 or value.description.len == 0) return error.NamedValueText;
        for (values[0..index]) |previous| {
            if (std.mem.eql(u8, previous.name, value.name)) return error.DuplicateNamedValue;
            if (previous.value == value.value) return error.DuplicateNamedValueNumber;
        }
    }
}

fn validateSignature(signature: *const Signature) !void {
    if (!std.mem.eql(u8, signature.calling_convention, "c")) return error.CallingConvention;
    try validateType(&signature.returns);
    for (signature.parameters, 0..) |parameter, index| {
        if (parameter.name.len == 0) return error.ParameterName;
        for (signature.parameters[0..index]) |previous| if (std.mem.eql(u8, previous.name, parameter.name)) return error.DuplicateParameterName;
        try validateType(&parameter.type);
    }
}

fn validateType(type_ref: *const TypeRef) !void {
    switch (type_ref.kind) {
        .scalar, .named => {
            if (type_ref.name == null or type_ref.name.?.len == 0 or type_ref.child != null or hasPointerContract(type_ref)) return error.TypeShape;
        },
        .pointer => {
            if (type_ref.pointer_kind == null or type_ref.is_const == null or type_ref.child == null or type_ref.name != null) return error.TypeShape;
            if (type_ref.pointer_kind.? == .sentinel and type_ref.sentinel == null) return error.TypeShape;
            if (type_ref.direction == null or type_ref.nullable == null or type_ref.length_by == null or type_ref.ownership == null or type_ref.lifetime == null) return error.PointerContractMissing;
            try validateType(type_ref.child.?);
        },
        .array => {
            if (type_ref.length == null or type_ref.length.? == 0 or type_ref.child == null or type_ref.name != null or hasPointerContract(type_ref)) return error.TypeShape;
            try validateType(type_ref.child.?);
        },
        .slice => {
            if (type_ref.is_const == null or type_ref.child == null or type_ref.name != null or type_ref.pointer_kind != null or type_ref.direction == null or type_ref.nullable == null or type_ref.ownership == null or type_ref.lifetime == null or type_ref.length_by == null) return error.TypeShape;
            try validateType(type_ref.child.?);
        },
        .optional => {
            if (type_ref.child == null or type_ref.name != null or hasPointerContract(type_ref)) return error.TypeShape;
            try validateType(type_ref.child.?);
        },
    }
}

fn hasPointerContract(type_ref: *const TypeRef) bool {
    return type_ref.pointer_kind != null or type_ref.is_const != null or type_ref.sentinel != null or type_ref.direction != null or type_ref.nullable != null or type_ref.length_by != null or type_ref.ownership != null or type_ref.lifetime != null;
}

fn typeWidth(type_ref: *const TypeRef) u32 {
    return switch (type_ref.kind) {
        .pointer => 8,
        .slice => 16,
        .optional => typeWidth(type_ref.child.?),
        .array => type_ref.length.? * typeWidth(type_ref.child.?),
        .named => 8,
        .scalar => if (std.mem.eql(u8, type_ref.name.?, "u8") or std.mem.eql(u8, type_ref.name.?, "i8") or std.mem.eql(u8, type_ref.name.?, "bool")) 1 else if (std.mem.eql(u8, type_ref.name.?, "u16") or std.mem.eql(u8, type_ref.name.?, "i16")) 2 else if (std.mem.eql(u8, type_ref.name.?, "u32") or std.mem.eql(u8, type_ref.name.?, "i32")) 4 else 8,
    };
}

fn hasMetadata(metadata: []const Metadata, key: []const u8, value: []const u8) bool {
    for (metadata) |item| if (std.mem.eql(u8, item.key, key) and std.mem.eql(u8, item.value, value)) return true;
    return false;
}

fn runSelftest(allocator: std.mem.Allocator, contract: *Contract, baseline: *const Contract) !void {
    const group = &contract.groups[0];

    std.mem.swap(Slot, &group.slots[0], &group.slots[1]);
    try expectRejected(allocator, contract, baseline);
    std.mem.swap(Slot, &group.slots[0], &group.slots[1]);

    const old_slots = group.slots;
    const old_size = group.size;
    group.slots = old_slots[0 .. old_slots.len - 1];
    group.size -= 8;
    try expectRejected(allocator, contract, baseline);
    group.slots = old_slots;
    group.size = old_size;

    const old_signature = group.slots[0].signature.?;
    var changed_signature = old_signature;
    changed_signature.returns.name = "u64";
    group.slots[0].signature = changed_signature;
    try expectRejected(allocator, contract, baseline);
    group.slots[0].signature = old_signature;

    const old_slot_semantics = group.slots[0].semantics;
    group.slots[0].semantics.exposure = .internal;
    try expectRejected(allocator, contract, baseline);
    group.slots[0].semantics = old_slot_semantics;

    const old_slot_description = group.slots[0].description;
    group.slots[0].description = "R4SYS write operation.";
    try expectRejected(allocator, contract, baseline);
    group.slots[0].description = old_slot_description;

    const old_status_domain_id = contract.status_domains[0].id;
    contract.status_domains[0].id = 99;
    try expectRejected(allocator, contract, baseline);
    contract.status_domains[0].id = old_status_domain_id;

    var reserved_index: usize = 0;
    while (group.slots[reserved_index].state != .reserved) : (reserved_index += 1) {}
    const old_reserved = group.slots[reserved_index];
    group.slots[reserved_index].state = .function;
    group.slots[reserved_index].signature = group.slots[0].signature;
    try expectRejected(allocator, contract, baseline);
    group.slots[reserved_index] = old_reserved;

    const old_entry = contract.r4x_start.entry.symbol;
    contract.r4x_start.entry.symbol = "Program" ++ "Start";
    try expectRejected(allocator, contract, baseline);
    contract.r4x_start.entry.symbol = old_entry;

    const old_query = contract.r4l_query.entry_symbol;
    contract.r4l_query.entry_symbol = "LegacyQuery";
    try expectRejected(allocator, contract, baseline);
    contract.r4l_query.entry_symbol = old_query;

    const old_id = contract.groups[1].id;
    contract.groups[1].id = contract.groups[0].id;
    try expectRejected(allocator, contract, baseline);
    contract.groups[1].id = old_id;

    const old_kind = contract.groups[1].kind;
    contract.groups[1].kind = .r4l_library;
    try expectRejected(allocator, contract, baseline);
    contract.groups[1].kind = old_kind;

    const old_magic = contract.groups[1].magic;
    contract.groups[1].magic = contract.groups[0].magic;
    try expectRejected(allocator, contract, baseline);
    contract.groups[1].magic = old_magic;

    const old_version = group.abi_version;
    group.abi_version += 1;
    try expectRejected(allocator, contract, baseline);
    group.abi_version = old_version;

    group.size += 8;
    try expectRejected(allocator, contract, baseline);
    group.size -= 8;

    const original_slots = group.slots;
    const extended_slots = try allocator.alloc(Slot, original_slots.len + 1);
    defer allocator.free(extended_slots);
    @memcpy(extended_slots[0..original_slots.len], original_slots);
    extended_slots[original_slots.len] = .{
        .number = @intCast(original_slots.len),
        .offset = group.header_size + @as(u32, @intCast(original_slots.len)) * group.pointer_size,
        .name = "phase_a_append_probe",
        .state = .function,
        .required = false,
        .description = "Selftest append probe.",
        .signature = original_slots[0].signature,
        .semantics = original_slots[0].semantics,
    };
    group.slots = extended_slots;
    group.size += group.pointer_size;
    try expectRejected(allocator, contract, baseline);
    group.abi_version += 1;
    try validateContract(allocator, contract, baseline);
    group.abi_version -= 1;
    group.size -= group.pointer_size;
    group.slots = original_slots;

    var fixed_index: usize = 0;
    while (contract.types[fixed_index].classification != .fixed_layout or contract.types[fixed_index].fields.len < 2) : (fixed_index += 1) {}
    const fixed_payload = &contract.types[fixed_index];
    std.mem.swap(Field, &fixed_payload.fields[0], &fixed_payload.fields[1]);
    try expectRejected(allocator, contract, baseline);
    std.mem.swap(Field, &fixed_payload.fields[0], &fixed_payload.fields[1]);

    const fixed_fields = fixed_payload.fields;
    fixed_payload.fields = fixed_fields[0 .. fixed_fields.len - 1];
    try expectRejected(allocator, contract, baseline);
    fixed_payload.fields = fixed_fields;

    const old_field_type = fixed_payload.fields[0].type;
    if (fixed_payload.fields[0].type.kind == .scalar) {
        fixed_payload.fields[0].type.name = if (std.mem.eql(u8, fixed_payload.fields[0].type.name.?, "u64")) "u32" else "u64";
    } else {
        fixed_payload.fields[0].type = .{ .kind = .scalar, .name = "u64" };
    }
    try expectRejected(allocator, contract, baseline);
    fixed_payload.fields[0].type = old_field_type;

    var array_type_index: usize = 0;
    var array_field_index: usize = 0;
    outer: while (array_type_index < contract.types.len) : (array_type_index += 1) {
        for (contract.types[array_type_index].fields, 0..) |field, field_index| {
            if (field.type.kind == .array) {
                array_field_index = field_index;
                break :outer;
            }
        }
    }
    const old_array_length = contract.types[array_type_index].fields[array_field_index].type.length.?;
    contract.types[array_type_index].fields[array_field_index].type.length.? += 1;
    try expectRejected(allocator, contract, baseline);
    contract.types[array_type_index].fields[array_field_index].type.length = old_array_length;

    const old_error_value = contract.error_domains[0].values[0].value;
    contract.error_domains[0].values[0].value -%= 1;
    try expectRejected(allocator, contract, baseline);
    contract.error_domains[0].values[0].value = old_error_value;

    var flag_index: usize = 0;
    while (contract.constants[flag_index].category != .flag) : (flag_index += 1) {}
    var other_flag_index = flag_index + 1;
    while (contract.constants[other_flag_index].category != .flag) : (other_flag_index += 1) {}
    const old_flag_value = contract.constants[flag_index].value;
    contract.constants[flag_index].value = contract.constants[other_flag_index].value;
    try expectRejected(allocator, contract, baseline);
    contract.constants[flag_index].value = old_flag_value;

    const old_limit_value = contract.limits[0].value;
    contract.limits[0].value = "999999";
    try expectRejected(allocator, contract, baseline);
    contract.limits[0].value = old_limit_value;

    var extensible_index: usize = 0;
    while (contract.types[extensible_index].classification != .extensible or
        payloadTypeIsReferenced(contract, contract.types[extensible_index].name)) : (extensible_index += 1)
    {}
    const extensible = &contract.types[extensible_index];
    const original_fields = extensible.fields;
    const extended_fields = try allocator.alloc(Field, original_fields.len + 1);
    defer allocator.free(extended_fields);
    @memcpy(extended_fields[0..original_fields.len], original_fields);
    extended_fields[original_fields.len] = .{
        .name = "extension_probe",
        .offset = extensible.size,
        .type = .{ .kind = .scalar, .name = "u64" },
        .description = "Selftest extensible append probe.",
        .size = 8,
        .alignment = 8,
        .source_type = "u64",
    };
    const old_payload_size = extensible.size;
    const old_payload_version = extensible.version;
    extensible.fields = extended_fields;
    extensible.size += 8;
    try expectRejected(allocator, contract, baseline);
    extensible.version += 1;
    try validateContract(allocator, contract, baseline);
    extensible.version = old_payload_version;
    extensible.size = old_payload_size;
    extensible.fields = original_fields;

    try testExtensibleBufferCanaries();
    try testApiInventoryRendering(allocator, contract);

    try validateContract(allocator, contract, baseline);
}

fn testExtensibleBufferCanaries() !void {
    const payload = [_]u8{ 1, 0, 0, 0, 16, 0, 0, 0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8 };
    for ([_]usize{ 8, payload.len, 24 }) |caller_size| {
        var target: [32]u8 = .{0xCC} ** 32;
        const copied = copyExtensiblePayload(target[0..], caller_size, payload[0..]);
        const expected = @min(caller_size, payload.len);
        if (copied != expected or !std.mem.eql(u8, target[0..expected], payload[0..expected])) return error.ExtensibleCopyLength;
        for (target[expected..]) |byte| if (byte != 0xCC) return error.ExtensibleCanaryOverwrite;
    }
}

fn copyExtensiblePayload(target: []u8, caller_size: usize, payload: []const u8) usize {
    const count = @min(target.len, @min(caller_size, payload.len));
    @memcpy(target[0..count], payload[0..count]);
    return count;
}

fn expectRejected(allocator: std.mem.Allocator, contract: *const Contract, baseline: *const Contract) !void {
    validateContract(allocator, contract, baseline) catch return;
    return error.MutationNotRejected;
}
