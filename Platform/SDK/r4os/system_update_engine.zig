const r4os = @import("r4os");
const std = @import("std");
const system_update_recovery = r4os.system_update_recovery;
const r4u_manifest = r4os.r4u_manifest;
const r4u_artifact = r4os.r4u_artifact;
const system_update_inventory = r4os.system_update_inventory;
const system_update_batch = r4os.system_update_batch;

const header_size: usize = r4u_manifest.header_size;
const manifest_max: usize = 32 * 1024;
// Worst case: 32 payloads x 4 paths x up to 1023 bytes (0.60.19 limits)
// plus header lines. R4U_JOURNAL=4 binds release, package, concrete
// components and the durable inventory completion phase; v2/v3 journals
// remain readable for interrupted older transactions.
const journal_max: usize = system_update_recovery.journal_max;
// 0.60.14: 64-KB-Chunks statt 4 KB - zusammen mit dem NTFS-Deferred-
// Stream-Pfad faellt das Staging von ~5 Device-Flushes pro 4 KB auf
// wenige Flushes pro Stream.  Die Puffer sind modulstatisch (SYSUPD ist
// single-threaded), damit sie nicht auf dem Task-Stack liegen.
const io_chunk: usize = 65536;
var stream_io_buf: [io_chunk]u8 = undefined;
var checksum_io_buf: [io_chunk]u8 = undefined;
var inventory_source_buf: [system_update_inventory.max_bytes]u8 = undefined;
var inventory_render_buf: [system_update_inventory.max_bytes]u8 = undefined;
var inventory_workspace: system_update_inventory.Inventory = undefined;
const checksum_seed: u32 = system_update_recovery.checksum_seed;
const max_package_payloads: usize = system_update_recovery.max_package_payloads;
const max_payloads: usize = system_update_recovery.max_payloads;
const max_path: usize = system_update_recovery.max_path;
comptime {
    if (max_path != @as(usize, r4os.abi.file_path_max_bytes) + 1)
        @compileError("SYSUPD recovery path capacity must match the R4SYS ABI");
}
const default_inbox = "C:\\R4OS\\UPDATE\\INBOX";
const update_root = "C:\\R4OS\\UPDATE";
const staged_root = "C:\\R4OS\\UPDATE\\STAGED";
const journal_paths = [2][*:0]const u8{
    "C:\\R4OS\\UPDATE\\STAGED\\SYSUPD0.JRN",
    "C:\\R4OS\\UPDATE\\STAGED\\SYSUPD1.JRN",
};
const update_lock_path = "C:\\R4OS\\UPDATE\\STAGED\\SYSLOCK.LCK";
const inventory_path = "C:\\R4OS\\CONFIG\\MODULES.JSON";
const version_path = "C:\\R4OS\\CONFIG\\VERSION.R4S";
const batch_journal_paths = [2][*:0]const u8{
    "C:\\R4OS\\UPDATE\\STAGED\\SYSBCH0.JRN",
    "C:\\R4OS\\UPDATE\\STAGED\\SYSBCH1.JRN",
};
const test_interrupt_after_first_commit_path = "C:\\R4OS\\UPDATE\\STAGED\\TST05914.FLT";
const test_interrupt_before_inventory_commit_path = "C:\\R4OS\\UPDATE\\STAGED\\TST06312A.FLT";
const test_interrupt_after_inventory_commit_path = "C:\\R4OS\\UPDATE\\STAGED\\TST06312B.FLT";
const progress_unit: u64 = 1024 * 1024;
// R4SYS file I/O reports confirmed progress and explicitly permits retry from
// that progress. Real NTFS hardware can transiently reject a read, report a
// false lookup miss or reject a stream append even though the block device
// itself reports no error. Reads and lookups are idempotent; an ambiguous
// stream write is recovered by aborting its private stage and rebuilding that
// stage from byte zero.
const transient_read_attempt_limit: u32 = 3;
const transient_stage_attempt_limit: u32 = 3;
const transient_io_retry_delay_ticks: u64 = 1;

const FileLookupStatus = enum {
    found,
    not_found,
    io,
};

const PayloadMatchStatus = enum {
    match,
    mismatch,
    io,
};

const PayloadPathState = enum {
    match,
    not_found,
    other,
    io,
};

const PrivateStageSettleStatus = enum {
    reusable,
    conflict,
    io,
};

const PackageVerifyStatus = enum {
    ok,
    not_found,
    invalid,
    incompatible,
    conflict,
    io,
};

const RequirementPolicy = enum {
    current,
    deferred_batch,
};

const VersionRead = union(enum) {
    found: []const u8,
    not_found,
    invalid,
    io,
};

const VersionMatchStatus = enum {
    match,
    mismatch,
    io,
};

const JournalLookupStatus = enum {
    found,
    not_found,
    io,
};

const JournalPhase = system_update_recovery.JournalPhase;

const CommitResult = enum {
    ok,
    failed,
    io,
    interrupted,
};

const UpdateLockStatus = enum {
    acquired,
    busy,
    io,
};

pub const Operation = enum {
    verify,
    apply,
    stage,
    commit_batch,
    resume_batch,
    resume_transaction,
    confirm_release,
    status,
};

pub const State = enum {
    idle,
    verified,
    preparing,
    staging,
    installing,
    verifying,
    installed,
    staged,
    pending_restart,
    restart_required,
    rolling_back,
    rolled_back,
    interrupted,
    incompatible,
    busy,
    failed,
};

pub const Result = struct {
    operation: Operation,
    state: State,
    exit_code: i32,
    package: [r4u_manifest.package_name_max_bytes + 1]u8 = .{0} ** (r4u_manifest.package_name_max_bytes + 1),
    package_len: usize = 0,
    package_version: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    package_version_len: usize = 0,
    release: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    release_len: usize = 0,
    reason: [64]u8 = .{0} ** 64,
    reason_len: usize = 0,
    activation: r4u_manifest.InstallMode = .live,
    priority: r4u_manifest.Priority = .normal,
    /// Number of transport payloads declared by the immutable R4U.
    payload_count: u32 = 0,
    /// Durable transaction steps, including the internal inventory step.
    transaction_step_count: u32 = 0,
    component_count: u32 = 0,
    committed_count: u32 = 0,
    inventory_consistent: bool = false,
    transaction_generation: u64 = 0,
    batch_generation: u64 = 0,
    batch_package_count: u32 = 0,
    batch_current_package: u32 = 0,
    restart_required: bool = false,

    pub fn packageText(self: *const Result) []const u8 {
        return self.package[0..self.package_len];
    }

    pub fn packageVersionText(self: *const Result) []const u8 {
        return self.package_version[0..self.package_version_len];
    }

    pub fn releaseText(self: *const Result) []const u8 {
        return self.release[0..self.release_len];
    }

    pub fn reasonText(self: *const Result) []const u8 {
        return self.reason[0..self.reason_len];
    }
};

const Header = struct {
    manifest_len: u64 = 0,
    payload_len: u64 = 0,
    manifest_checksum: u32 = 0,
    payload_checksum: u32 = 0,
    package_checksum: u32 = 0,
    payload_count: u32 = 0,
    flags: u32 = 0,
};

const PayloadEntry = struct {
    target_path: [max_path:0]u8 = .{0} ** max_path,
    target_len: usize = 0,
    stage_path: [max_path:0]u8 = .{0} ** max_path,
    stage_len: usize = 0,
    backup_path: [max_path:0]u8 = .{0} ** max_path,
    backup_len: usize = 0,
    previous_backup_path: [max_path:0]u8 = .{0} ** max_path,
    previous_backup_len: usize = 0,
    previous_backup_known: bool = false,
    previous_backup_size: u64 = 0,
    previous_backup_checksum: u32 = 0,
    name: []const u8 = "",
    kind: []const u8 = "",
    class: r4os.r4sys.SystemReplaceClass = .unknown,
    size: u64 = 0,
    checksum: u32 = 0,
    offset: u64 = 0,
    already_applied: bool = false,
    target_existed: bool = false,
    old_known: bool = false,
    old_size: u64 = 0,
    old_checksum: u32 = 0,
    committed: bool = false,
    rolled_back: bool = false,
    replace_required: bool = true,
    component_index: ?u32 = null,

    fn targetText(self: *const PayloadEntry) []const u8 {
        return self.target_path[0..self.target_len];
    }

    fn stageText(self: *const PayloadEntry) []const u8 {
        return self.stage_path[0..self.stage_len];
    }

    fn backupText(self: *const PayloadEntry) []const u8 {
        return self.backup_path[0..self.backup_len];
    }

    fn previousBackupText(self: *const PayloadEntry) []const u8 {
        return self.previous_backup_path[0..self.previous_backup_len];
    }

    fn targetPtr(self: *const PayloadEntry) [*:0]const u8 {
        return @ptrCast(self.target_path[0..].ptr);
    }

    fn stagePtr(self: *const PayloadEntry) [*:0]const u8 {
        return @ptrCast(self.stage_path[0..].ptr);
    }

    fn backupPtr(self: *const PayloadEntry) [*:0]const u8 {
        return @ptrCast(self.backup_path[0..].ptr);
    }

    fn previousBackupPtr(self: *const PayloadEntry) [*:0]const u8 {
        return @ptrCast(self.previous_backup_path[0..].ptr);
    }
};

const ComponentEntry = struct {
    payload_index: u32 = 0,
    kind: r4u_manifest.ComponentKind = .r4x,
    name_storage: [r4u_manifest.component_name_max_bytes + 1]u8 = .{0} ** (r4u_manifest.component_name_max_bytes + 1),
    name: []const u8 = "",
    target_path: [max_path]u8 = .{0} ** max_path,
    target_len: usize = 0,
    version_storage: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    version: []const u8 = "",
    install: r4u_manifest.InstallMode = .live,

    fn targetText(self: *const ComponentEntry) []const u8 {
        return self.target_path[0..self.target_len];
    }
};

const RequirementEntry = struct {
    kind: r4u_manifest.ComponentKind = .r4x,
    name: []const u8 = "",
    target_path: [max_path:0]u8 = .{0} ** max_path,
    target_len: usize = 0,
    version: []const u8 = "",
    state: r4u_manifest.RequirementState = .installed,

    fn targetText(self: *const RequirementEntry) []const u8 {
        return self.target_path[0..self.target_len];
    }

    fn targetPtr(self: *const RequirementEntry) [*:0]const u8 {
        return @ptrCast(self.target_path[0..].ptr);
    }
};

const PackageInfo = struct {
    source_path: []const u8 = "",
    header: Header = .{},
    package: []const u8 = "",
    package_version: []const u8 = "",
    release: []const u8 = "",
    title: []const u8 = "",
    description: []const u8 = "",
    activation: r4u_manifest.InstallMode = .live,
    priority: r4u_manifest.Priority = .normal,
    payloads_expected: u32 = 0,
    components_expected: u32 = 0,
    requirements_expected: u32 = 0,
    payload_count: u32 = 0,
    component_count: u32 = 0,
    requirement_count: u32 = 0,
    rollback_count: u32 = 0,
    payload_bytes: u64 = 0,
    streamed_bytes: u64 = 0,
    staged_bytes: u64 = 0,
    reboot: bool = false,
    needs_reboot: bool = false,
    package_digest: u32 = 0,
    manifest_checksum: u32 = 0,
    component_digest: u32 = checksum_seed,
    package_length: u64 = 0,
    transaction_generation: u64 = 0,
    source_version: [32:0]u8 = .{0} ** 32,
    source_version_len: usize = 0,
    payloads: [max_payloads]PayloadEntry = .{PayloadEntry{}} ** max_payloads,
    components: [max_package_payloads]ComponentEntry = .{ComponentEntry{}} ** max_package_payloads,
    requirements: [max_package_payloads]RequirementEntry = .{RequirementEntry{}} ** max_package_payloads,
};

const JournalPayload = system_update_recovery.JournalPayload;
const TransactionJournal = system_update_recovery.TransactionJournal;

var journal_write_buffer: [journal_max]u8 = undefined;
var journal_read_buffers: [2][journal_max]u8 = undefined;
// Keep all >130-KB path/payload/journal workspaces out of the 64-KB initial
// program stack.  SYSUPD is single-threaded, so commands reuse this compact
// static set instead of forcing stack growth and deferred stack reaping.
var command_path_workspace: [max_path:0]u8 = .{0} ** max_path;
var command_manifest_workspace: [manifest_max]u8 = undefined;
var primary_info_workspace: PackageInfo = .{};
var secondary_info_workspace: PackageInfo = .{};
var command_journal_workspace: TransactionJournal = .{};
var newest_journal_workspace: TransactionJournal = .{};
var previous_journal_workspace: TransactionJournal = .{};
var batch_info_workspace: PackageInfo = .{};
var batch_journal_workspace: system_update_batch.BatchJournal = .{};
var batch_verify_journal_workspace: system_update_batch.BatchJournal = .{};
var batch_read_buffers: [2][system_update_batch.journal_max]u8 = undefined;
var batch_write_buffer: [system_update_batch.journal_max]u8 = undefined;
var batch_plan_packages: [system_update_batch.max_packages]system_update_batch.PlanPackage = .{system_update_batch.PlanPackage{}} ** system_update_batch.max_packages;
var batch_plan_components: [system_update_batch.max_components]system_update_batch.PlanComponent = undefined;
var batch_plan_requirements: [system_update_batch.max_requirements]system_update_batch.PlanRequirement = undefined;
var batch_component_names: [system_update_batch.max_components][r4u_manifest.component_name_max_bytes + 1]u8 = .{.{0} ** (r4u_manifest.component_name_max_bytes + 1)} ** system_update_batch.max_components;
var batch_component_targets: [system_update_batch.max_components][max_path]u8 = .{.{0} ** max_path} ** system_update_batch.max_components;
var batch_component_versions: [system_update_batch.max_components][r4u_manifest.version_max_bytes + 1]u8 = .{.{0} ** (r4u_manifest.version_max_bytes + 1)} ** system_update_batch.max_components;
var batch_requirement_names: [system_update_batch.max_requirements][r4u_manifest.component_name_max_bytes + 1]u8 = .{.{0} ** (r4u_manifest.component_name_max_bytes + 1)} ** system_update_batch.max_requirements;
var batch_requirement_targets: [system_update_batch.max_requirements][max_path]u8 = .{.{0} ** max_path} ** system_update_batch.max_requirements;
var batch_requirement_versions: [system_update_batch.max_requirements][r4u_manifest.version_max_bytes + 1]u8 = .{.{0} ** (r4u_manifest.version_max_bytes + 1)} ** system_update_batch.max_requirements;
var batch_order_workspace: [system_update_batch.max_packages]u8 = undefined;
var release_render_workspace: [96]u8 = undefined;
var active_kernel_version: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1);
var active_kernel_version_len: usize = 0;
var last_reason: [64]u8 = .{0} ** 64;
var last_reason_len: usize = 0;
var last_status_has_journal = false;
var last_status_has_batch = false;

pub const Engine = struct {
    app: *r4os.App,
    ctx: r4os.r4sys.Context,

    pub fn init(app: *r4os.App) Engine {
        refreshActiveKernelVersion(app);
        return .{ .app = app, .ctx = app.system() };
    }

    pub fn verify(self: *Engine, path: []const u8) Result {
        resetTypedResult();
        const exit_code = verifyCommand(&self.ctx, path);
        return typedResult(.verify, exit_code, &primary_info_workspace, null, null);
    }

    /// Verifies package bytes, manifest, payload identities and targets before
    /// a restart batch is staged. Cross-package installed requirements remain
    /// deferred to the batch planner and its final commit preflight.
    pub fn verifyForBatch(self: *Engine, path: []const u8) Result {
        resetTypedResult();
        const exit_code = verifyForBatchCommand(&self.ctx, path);
        return typedResult(.verify, exit_code, &primary_info_workspace, null, null);
    }

    pub fn apply(self: *Engine, path: []const u8) Result {
        resetTypedResult();
        const exit_code = applyCommand(&self.ctx, path);
        return typedResult(.apply, exit_code, &primary_info_workspace, &command_journal_workspace, null);
    }

    pub fn stage(self: *Engine, path: []const u8) Result {
        resetTypedResult();
        const exit_code = stageCommand(&self.ctx, path);
        return typedResult(.stage, exit_code, &primary_info_workspace, null, &batch_journal_workspace);
    }

    pub fn commitBatch(self: *Engine) Result {
        resetTypedResult();
        const exit_code = commitBatchCommand(&self.ctx);
        return typedResult(.commit_batch, exit_code, &batch_info_workspace, &command_journal_workspace, &batch_journal_workspace);
    }

    pub fn resumeBatch(self: *Engine) Result {
        resetTypedResult();
        const exit_code = resumeBatchCommand(&self.ctx);
        return typedResult(.resume_batch, exit_code, &batch_info_workspace, &command_journal_workspace, &batch_journal_workspace);
    }

    pub fn resumeTransaction(self: *Engine) Result {
        resetTypedResult();
        const exit_code = resumeCommand(&self.ctx);
        return typedResult(.resume_transaction, exit_code, &primary_info_workspace, &command_journal_workspace, null);
    }

    /// Publishes VERSION.R4S only after the caller has proved that a purely
    /// live catalog target is complete. The write itself remains journaled
    /// by the system update engine and is source-release bound.
    pub fn confirmLiveRelease(self: *Engine, source_release: []const u8, target_release: []const u8) Result {
        resetTypedResult();
        const exit_code = confirmLiveReleaseCommand(&self.ctx, source_release, target_release);
        return typedResult(.confirm_release, exit_code, &primary_info_workspace, null, null);
    }

    pub fn status(self: *Engine) Result {
        resetTypedResult();
        last_status_has_journal = false;
        last_status_has_batch = false;
        const exit_code = statusCommand(&self.ctx);
        return typedResult(
            .status,
            exit_code,
            null,
            if (last_status_has_journal) &command_journal_workspace else null,
            if (last_status_has_batch) &batch_journal_workspace else null,
        );
    }
};

pub fn runTerminal(r4_app: *r4os.App) i32 {
    var engine = Engine.init(r4_app);
    const ctx = engine.ctx;
    const args = trim(spanZ(ctx.argsRaw()));
    if (args.len == 0 or equalsIgnoreCase(args, "/?") or equalsIgnoreCase(args, "-?") or equalsIgnoreCase(args, "--help")) {
        printUsage(&ctx);
        return 0;
    }

    var pos: usize = 0;
    const command = nextToken(args, &pos) orelse {
        printUsage(&ctx);
        return 1;
    };
    if (equalsIgnoreCase(command, "VERIFY")) {
        const path = trim(args[pos..]);
        if (path.len == 0) {
            fail(&ctx, "VERIFY", "missing-path");
            return 1;
        }
        return engine.verify(path).exit_code;
    }
    if (equalsIgnoreCase(command, "APPLY")) {
        const path = trim(args[pos..]);
        if (path.len == 0) {
            fail(&ctx, "APPLY", "missing-path");
            return 1;
        }
        return engine.apply(path).exit_code;
    }
    if (equalsIgnoreCase(command, "STAGE")) {
        const path = trim(args[pos..]);
        if (path.len == 0) {
            fail(&ctx, "STAGE", "missing-path");
            return 1;
        }
        return engine.stage(path).exit_code;
    }
    if (equalsIgnoreCase(command, "COMMIT")) {
        return engine.commitBatch().exit_code;
    }
    if (equalsIgnoreCase(command, "ABORT-BATCH")) {
        return abortPreparedBatchCommand(&ctx);
    }
    if (equalsIgnoreCase(command, "RESUME-BATCH")) {
        return engine.resumeBatch().exit_code;
    }
    if (equalsIgnoreCase(command, "RESUME")) {
        return engine.resumeTransaction().exit_code;
    }
    if (equalsIgnoreCase(command, "STATUS")) {
        return engine.status().exit_code;
    }

    ctx.write("SYSUPD: unknown command ");
    ctx.println(command);
    printUsage(&ctx);
    return 1;
}

fn refreshActiveKernelVersion(r4_app: *const r4os.App) void {
    active_kernel_version_len = 0;
    @memset(active_kernel_version[0..], 0);
    const dev = r4_app.devicesLowLevel() orelse return;
    const version = dev.kernelVersion() orelse return;
    const rendered = r4os.version_info.formatKernelVersion(version, active_kernel_version[0 .. active_kernel_version.len - 1]) orelse return;
    active_kernel_version_len = rendered.len;
}

fn resetTypedResult() void {
    clearTypedReason();
}

fn clearTypedReason() void {
    @memset(last_reason[0..], 0);
    last_reason_len = 0;
}

fn typedResult(
    operation: Operation,
    exit_code: i32,
    info: ?*const PackageInfo,
    journal: ?*const TransactionJournal,
    batch: ?*const system_update_batch.BatchJournal,
) Result {
    var result: Result = .{
        .operation = operation,
        .state = stateForResult(operation, exit_code, journal, batch),
        .exit_code = exit_code,
    };
    if (info) |package_info| {
        result.package_len = copyTypedText(result.package[0..], package_info.package);
        result.package_version_len = copyTypedText(result.package_version[0..], package_info.package_version);
        result.release_len = copyTypedText(result.release[0..], package_info.release);
        result.activation = package_info.activation;
        result.priority = package_info.priority;
        result.payload_count = package_info.payloads_expected;
        result.transaction_step_count = package_info.payload_count;
        result.component_count = package_info.component_count;
        result.transaction_generation = package_info.transaction_generation;
    }
    if (journal) |transaction| {
        if (result.package_version_len == 0)
            result.package_version_len = copyTypedText(result.package_version[0..], transaction.packageVersionText());
        if (result.release_len == 0)
            result.release_len = copyTypedText(result.release[0..], transaction.releaseText());
        if (result.payload_count == 0) result.payload_count = transaction.package_payload_count;
        result.transaction_step_count = transaction.payload_count;
        if (result.component_count == 0) result.component_count = transaction.component_count;
        result.committed_count = transaction.committed_count;
        result.inventory_consistent = transaction.component_count == 0 or
            ((transaction.phase == .inventory or transaction.phase == .applied or transaction.phase == .cleanup) and
                transaction.payload_count == transaction.package_payload_count + 1 and
                transaction.committed_count == transaction.payload_count);
        if (result.transaction_generation == 0) result.transaction_generation = transaction.transaction_generation;
        result.activation = if (transaction.reboot) .restart else result.activation;
        result.priority = if (transaction.foundation) .foundation else result.priority;
        result.restart_required = transaction.phase == .post_boot;
    }
    if (batch) |batch_journal| {
        if (batch_journal.valid) {
            result.batch_generation = batch_journal.batch_generation;
            result.batch_package_count = batch_journal.package_count;
            result.batch_current_package = batch_journal.current_package;
            result.restart_required = result.restart_required or
                batch_journal.phase == .pending_restart;
            if (result.release_len == 0)
                result.release_len = copyTypedText(result.release[0..], batch_journal.targetReleaseText());
        }
    }
    result.reason_len = copyTypedText(result.reason[0..], last_reason[0..last_reason_len]);
    return result;
}

fn stateForResult(
    operation: Operation,
    exit_code: i32,
    journal: ?*const TransactionJournal,
    batch: ?*const system_update_batch.BatchJournal,
) State {
    if (exit_code == 75) return .interrupted;
    if (exit_code == 2) return .incompatible;
    if (exit_code != 0) {
        if (equalsIgnoreCase(last_reason[0..last_reason_len], "transaction-active")) return .busy;
        return .failed;
    }
    if (operation == .verify) return .verified;
    if (journal) |transaction| {
        if (transaction.phase == .post_boot) return .restart_required;
    }
    if (batch) |batch_journal| {
        if (batch_journal.valid) {
            return switch (batch_journal.phase) {
                .staged, .verifying, .staging => .staged,
                .committing => .installing,
                .pending_restart => .pending_restart,
                .installed => .installed,
                .failed => .failed,
                .rolling_back => .rolling_back,
                .rolled_back => .rolled_back,
            };
        }
    }
    if (journal) |transaction| {
        return switch (transaction.phase) {
            .prepare => .preparing,
            .stage => .staging,
            .commit => .installing,
            .verify => .verifying,
            .inventory => .installing,
            .applied, .cleanup => .installed,
            .post_boot => .pending_restart,
            .rollback => .rolling_back,
            .rolled_back => .rolled_back,
        };
    }
    return if (operation == .status) .idle else .installed;
}

fn copyTypedText(destination: []u8, source: []const u8) usize {
    const length = @min(destination.len, source.len);
    if (length != 0) @memcpy(destination[0..length], source[0..length]);
    return length;
}

fn printUsage(ctx: *const r4os.r4sys.Context) void {
    ctx.println("SYSUPD.R4X - R4OS system file updater");
    ctx.println("");
    ctx.println("Usage:");
    ctx.println("  SYSUPD VERIFY C:\\R4OS\\UPDATE\\INBOX\\UPDATE.R4U");
    ctx.println("  SYSUPD APPLY  C:\\R4OS\\UPDATE\\INBOX\\UPDATE.R4U");
    ctx.println("  SYSUPD STAGE  C:\\R4OS\\UPDATE\\INBOX\\UPDATE.R4U");
    ctx.println("  SYSUPD COMMIT");
    ctx.println("  SYSUPD ABORT-BATCH");
    ctx.println("  SYSUPD RESUME-BATCH");
    ctx.println("  SYSUPD RESUME");
    ctx.println("  SYSUPD STATUS");
    ctx.println("");
    ctx.println("APPLY stages payloads beside their targets, writes a journal, uses R4SYS replace and keeps SCP/SFTP as transport only.");
}

fn verifyCommand(ctx: *const r4os.r4sys.Context, path_raw: []const u8) i32 {
    return verifyWithPolicy(ctx, path_raw, .current, "VERIFY");
}

fn verifyForBatchCommand(ctx: *const r4os.r4sys.Context, path_raw: []const u8) i32 {
    return verifyWithPolicy(ctx, path_raw, .deferred_batch, "VERIFY-BATCH");
}

fn verifyWithPolicy(
    ctx: *const r4os.r4sys.Context,
    path_raw: []const u8,
    requirement_policy: RequirementPolicy,
    command: []const u8,
) i32 {
    command_path_workspace = .{0} ** max_path;
    primary_info_workspace = .{};
    const path_buf = command_path_workspace[0..];
    const manifest_buf = command_manifest_workspace[0..];
    const info = &primary_info_workspace;
    // VERIFY is deliberately side-effect free. STATUS/APPLY own directory
    // materialization; a package that is not already a final Inbox object is
    // not made visible or repaired by verification.
    const verify_status = readAndVerifyPackage(ctx, path_raw, path_buf, manifest_buf, info, false, requirement_policy, command);
    if (verify_status != .ok) return packageVerifyExitCode(verify_status);
    if (!validatePackageTargets(ctx, info, command)) return 1;

    ctx.write("SYSUPD ");
    ctx.write(command);
    ctx.write(" result: OK package=");
    ctx.write(info.package);
    ctx.write(" package-version=");
    ctx.write(info.package_version);
    ctx.write(" current-release=");
    var current_version_buf: [32]u8 = .{0} ** 32;
    switch (readCurrentVersionStatus(ctx, current_version_buf[0..])) {
        .found => |version| ctx.write(version),
        .not_found, .invalid, .io => ctx.write("unknown"),
    }
    ctx.write(" release=");
    ctx.write(info.release);
    ctx.write(" payloads=");
    ctx.printU64(info.payload_count);
    ctx.write(" bytes=");
    ctx.printU64(info.payload_bytes);
    ctx.write(" streamed=");
    ctx.printU64(info.streamed_bytes);
    ctx.write(" reboot=");
    ctx.write(if (info.reboot) "yes" else "no");
    ctx.write(" activation=");
    ctx.write(info.activation.text());
    ctx.write(" priority=");
    ctx.write(info.priority.text());
    ctx.write(" components=");
    ctx.printU64(info.component_count);
    ctx.write(" requires=");
    ctx.printU64(info.requirement_count);
    ctx.write(" inbox=");
    ctx.write(default_inbox);
    ctx.write(" staged=");
    ctx.println(staged_root);
    return 0;
}

fn applyCommand(ctx: *const r4os.r4sys.Context, path_raw: []const u8) i32 {
    command_path_workspace = .{0} ** max_path;
    primary_info_workspace = .{};
    const path_buf = command_path_workspace[0..];
    const manifest_buf = command_manifest_workspace[0..];
    const info = &primary_info_workspace;
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "APPLY", "update-dirs");
        return 1;
    }
    switch (acquireUpdateLock(ctx, false)) {
        .acquired => {},
        .busy => {
            fail(ctx, "APPLY", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "APPLY", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);

    var previous: ?*const TransactionJournal = null;
    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .found => {
            // journalFromInfo reuses command_journal_workspace for the new
            // transaction. Keep the terminal predecessor in its own static
            // workspace until every newly introduced target (including the
            // inventory payload) has inherited its last-good backup.
            previous_journal_workspace = command_journal_workspace;
            previous = &previous_journal_workspace;
        },
        .not_found => {},
        .io => {
            fail(ctx, "APPLY", "journal-read");
            return 1;
        },
    }
    if (previous) |journal| {
        if (!phaseTerminal(journal.phase)) {
            fail(ctx, "APPLY", "resume-required");
            return 1;
        }
        if (journal.transaction_generation == std.math.maxInt(u64)) {
            fail(ctx, "APPLY", "transaction-generation-exhausted");
            return 1;
        }
        info.transaction_generation = journal.transaction_generation + 1;
    } else {
        info.transaction_generation = 1;
    }
    var current_version_buf: [32]u8 = .{0} ** 32;
    const current_version = switch (readCurrentVersionStatus(ctx, current_version_buf[0..])) {
        .found => |version| version,
        .not_found, .invalid => {
            fail(ctx, "APPLY", "source-version");
            return 1;
        },
        .io => {
            fail(ctx, "APPLY", "source-version-read");
            return 1;
        },
    };
    info.source_version_len = copyTextZ(info.source_version[0..], current_version) orelse {
        fail(ctx, "APPLY", "source-version-length");
        return 1;
    };

    const verify_status = readAndVerifyPackage(ctx, path_raw, path_buf, manifest_buf, info, false, .current, "APPLY");
    if (verify_status != .ok) return packageVerifyExitCode(verify_status);
    if (!packageIsPureLiveR4x(info)) {
        fail(ctx, "APPLY", "restart-required");
        return 1;
    }
    switch (packageProgramRunningStatus(ctx, info)) {
        .satisfied => {},
        .missing => {
            fail(ctx, "APPLY", "program-running");
            return 1;
        },
        .io => {
            fail(ctx, "APPLY", "program-state");
            return 1;
        },
    }
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => if (!system_update_batch.phaseTerminal(batch_journal_workspace.phase)) {
            fail(ctx, "APPLY", "restart-batch-pending");
            return 1;
        },
        .not_found => {},
        .io => {
            fail(ctx, "APPLY", "batch-read");
            return 1;
        },
    }
    if (!assignInternalPaths(ctx, info, "APPLY") or !validateTargetAliases(ctx, info, "APPLY")) return 1;

    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        var entry = &info.payloads[index];
        var target_info: r4os.abi.FileInfo = .{};
        switch (fileInfoStatus(ctx, entry.targetPtr(), &target_info)) {
            .found => {
                if (target_info.is_dir != 0) {
                    fail(ctx, "APPLY", "target-type");
                    return 1;
                }
                const old_checksum = checksumFileRange(ctx, entry.targetPtr(), 0, target_info.size) orelse {
                    fail(ctx, "APPLY", "target-read");
                    return 1;
                };
                entry.target_existed = true;
                entry.old_known = true;
                entry.old_size = target_info.size;
                entry.old_checksum = old_checksum;
                entry.replace_required = target_info.size != entry.size or old_checksum != entry.checksum;
            },
            .not_found => {
                entry.target_existed = false;
                entry.old_known = false;
                entry.replace_required = true;
            },
            .io => {
                fail(ctx, "APPLY", "target-info");
                return 1;
            },
        }
        entry.already_applied = !entry.replace_required;
    }
    if (!bindPreviousBackups(ctx, info, previous)) {
        fail(ctx, "APPLY", "previous-backup-read");
        return 1;
    }
    // Previous-generation backup paths are learned only after the first
    // alias pass.  They must be disjoint from every package and payload path
    // before cleanup authority is persisted in the journal.
    if (!validateTargetAliases(ctx, info, "APPLY")) return 1;

    const journal = &command_journal_workspace;
    journalFromInfo(info, .prepare, journal);
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, "APPLY", "journal-prepare");
        return 1;
    }

    const stage_status = streamPackagePayloadsWithTransientRetry(ctx, path_buf.ptr, info.header, manifest_buf[0..@intCast(info.header.manifest_len)], info, true, "APPLY");
    if (stage_status != .ok) {
        if (stage_status == .io or stage_status == .conflict)
            return packageVerifyExitCode(stage_status);
        journal.phase = .rollback;
        _ = writeInactiveJournal(ctx, journal);
        _ = rollbackTransactionReverse(ctx, info, journal);
        return packageVerifyExitCode(stage_status);
    }
    syncJournalFromInfo(journal, info, .stage);
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, "APPLY", "journal-stage");
        return 1;
    }

    switch (commitTransaction(ctx, info, journal)) {
        .ok => {},
        .failed => {
            _ = rollbackTransactionReverse(ctx, info, journal);
            return 1;
        },
        .io => return 1,
        .interrupted => {
            ctx.println("SYSUPD APPLY result: INTERRUPTED phase=commit payload=1 resume=required");
            return 75;
        },
    }

    journal.phase = .verify;
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, "APPLY", "journal-verify");
        return 1;
    }
    const committed_verify = verifyCommittedPayloads(ctx, info);
    if (committed_verify == .io) {
        fail(ctx, "APPLY", "target-verify-read");
        return 1;
    }
    if (committed_verify != .match) {
        fail(ctx, "APPLY", "target-verify");
        _ = rollbackTransactionReverse(ctx, info, journal);
        return 1;
    }

    switch (completeInventoryPhase(ctx, info, journal, previous, "APPLY")) {
        .ok => {},
        .failed => {
            _ = rollbackTransactionReverse(ctx, info, journal);
            return 1;
        },
        .io => return 1,
        .interrupted => {
            ctx.println("SYSUPD APPLY result: INTERRUPTED phase=inventory resume=required");
            return 75;
        },
    }

    journal.phase = .applied;
    journal.reboot = info.reboot;
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, "APPLY", "journal-applied");
        return 1;
    }
    if (!cleanupTransaction(ctx, info, journal)) {
        fail(ctx, "APPLY", "cleanup");
        return 1;
    }

    ctx.write("SYSUPD APPLY result: OK package=");
    ctx.write(info.package);
    ctx.write(" package-version=");
    ctx.write(info.package_version);
    ctx.write(" release=");
    ctx.write(info.release);
    ctx.write(" payloads=");
    ctx.printU64(info.payloads_expected);
    ctx.write(" applied=");
    ctx.printU64(info.payloads_expected);
    ctx.write(" bytes=");
    ctx.printU64(info.payload_bytes);
    ctx.write(" streamed=");
    ctx.printU64(info.streamed_bytes);
    ctx.write(" staged=");
    ctx.printU64(info.staged_bytes);
    ctx.write(" reboot=");
    ctx.write(if (info.reboot) "yes" else "no");
    ctx.write(" transaction=");
    ctx.printU64(info.transaction_generation);
    ctx.write(" journal=");
    ctx.println(if (journal.slot == 0) "SYSUPD0.JRN" else "SYSUPD1.JRN");
    return 0;
}

const CurrentRequirementStatus = enum {
    satisfied,
    missing,
    io,
};

fn requirementCurrentlySatisfied(
    ctx: *const r4os.r4sys.Context,
    info: *const PackageInfo,
    requirement: *const RequirementEntry,
) CurrentRequirementStatus {
    if (requirement.state == .installed and requirementSatisfiedByOffer(info, requirement))
        return .satisfied;
    if (requirement.state == .active) {
        const current = active_kernel_version[0..active_kernel_version_len];
        return if (requirement.kind == .kernel and current.len != 0 and
            (r4u_manifest.compareVersions(current, requirement.version) orelse -1) >= 0)
            .satisfied
        else
            .missing;
    }

    var file_info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, requirement.targetPtr(), &file_info)) {
        .found => {},
        .not_found => return .missing,
        .io => return .io,
    }
    if (file_info.is_dir != 0 or file_info.size == 0) return .missing;
    const identity = r4u_artifact.inspect(ArtifactFileReader{
        .ctx = ctx,
        .path = requirement.targetPtr(),
        .base = 0,
        .size = file_info.size,
    }, file_info.size) orelse return .missing;
    return if (identity.kind == requirement.kind and
        std.ascii.eqlIgnoreCase(identity.nameText(), requirement.name) and
        (r4u_manifest.compareVersions(identity.versionText(), requirement.version) orelse -1) >= 0)
        .satisfied
    else
        .missing;
}

fn allRequirementsCurrentlySatisfied(
    ctx: *const r4os.r4sys.Context,
    info: *const PackageInfo,
) CurrentRequirementStatus {
    var index: usize = 0;
    while (index < info.requirement_count) : (index += 1) {
        const status = requirementCurrentlySatisfied(ctx, info, &info.requirements[index]);
        if (status != .satisfied) return status;
    }
    return .satisfied;
}

fn packageIsPureLiveR4x(info: *const PackageInfo) bool {
    if (info.activation != .live or info.component_count == 0) return false;
    var index: usize = 0;
    while (index < info.component_count) : (index += 1) {
        if (info.components[index].kind != .r4x or info.components[index].install != .live)
            return false;
    }
    return true;
}

fn packageProgramRunningStatus(
    ctx: *const r4os.r4sys.Context,
    info: *const PackageInfo,
) CurrentRequirementStatus {
    var index: usize = 0;
    while (index < info.component_count) : (index += 1) {
        const component = &info.components[index];
        if (component.kind != .r4x or component.payload_index >= info.payload_count) return .missing;
        const rc = ctx.programModuleRunning(info.payloads[component.payload_index].targetPtr());
        if (rc < 0) return .io;
        if (rc > 0) return .missing;
    }
    return .satisfied;
}

fn stageCommand(ctx: *const r4os.r4sys.Context, path_raw: []const u8) i32 {
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "STAGE", "update-dirs");
        return 1;
    }
    command_path_workspace = .{0} ** max_path;
    primary_info_workspace = .{};
    const info = &primary_info_workspace;
    const verify_status = readAndVerifyPackage(
        ctx,
        path_raw,
        command_path_workspace[0..],
        command_manifest_workspace[0..],
        info,
        false,
        .deferred_batch,
        "STAGE",
    );
    if (verify_status != .ok) return packageVerifyExitCode(verify_status);
    if (!validatePackageTargets(ctx, info, "STAGE")) return 1;

    var pending_batch = false;
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => pending_batch = !system_update_batch.phaseTerminal(batch_journal_workspace.phase),
        .not_found => {},
        .io => {
            fail(ctx, "STAGE", "batch-read");
            return 1;
        },
    }
    if (packageIsPureLiveR4x(info) and !pending_batch) {
        switch (allRequirementsCurrentlySatisfied(ctx, info)) {
            .satisfied => {},
            .missing => return stageRestartPackage(ctx, info),
            .io => {
                fail(ctx, "STAGE", "requirement-read");
                return 1;
            },
        }
        switch (packageProgramRunningStatus(ctx, info)) {
            .satisfied => return applyCommand(ctx, path_raw),
            .missing => return stageRestartPackage(ctx, info),
            .io => {
                fail(ctx, "STAGE", "program-state");
                return 1;
            },
        }
    }
    return stageRestartPackage(ctx, info);
}

fn stageRestartPackage(ctx: *const r4os.r4sys.Context, verified: *const PackageInfo) i32 {
    switch (acquireUpdateLock(ctx, false)) {
        .acquired => {},
        .busy => {
            fail(ctx, "STAGE", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "STAGE", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);

    var current_release_buf: [32]u8 = .{0} ** 32;
    const current_release = switch (readCurrentVersionStatus(ctx, current_release_buf[0..])) {
        .found => |version| version,
        .not_found, .invalid => {
            fail(ctx, "STAGE", "source-version");
            return 1;
        },
        .io => {
            fail(ctx, "STAGE", "source-version-read");
            return 1;
        },
    };

    var next_batch_generation: u64 = 1;
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {
            if (system_update_batch.phaseTerminal(batch_journal_workspace.phase)) {
                if (batch_journal_workspace.batch_generation == std.math.maxInt(u64)) {
                    fail(ctx, "STAGE", "batch-generation-exhausted");
                    return 1;
                }
                next_batch_generation = batch_journal_workspace.batch_generation + 1;
                batch_journal_workspace = .{};
            } else if (batch_journal_workspace.phase != .staged) {
                fail(ctx, "STAGE", "batch-not-stageable");
                return 1;
            }
        },
        .not_found => batch_journal_workspace = .{},
        .io => {
            fail(ctx, "STAGE", "batch-read");
            return 1;
        },
    }

    const batch = &batch_journal_workspace;
    if (batch.package_count == 0) {
        batch.batch_generation = next_batch_generation;
        batch.phase = .staged;
        batch.source_release_len = copyTextZ(batch.source_release[0..], current_release) orelse {
            fail(ctx, "STAGE", "source-version-length");
            return 1;
        };
        batch.target_release_len = copyTextZ(batch.target_release[0..], verified.release) orelse {
            fail(ctx, "STAGE", "target-version-length");
            return 1;
        };
    } else if (!std.mem.eql(u8, batch.sourceReleaseText(), current_release) or
        !std.mem.eql(u8, batch.targetReleaseText(), verified.release))
    {
        fail(ctx, "STAGE", "batch-release-mismatch");
        return 1;
    }
    if (batch.package_count >= system_update_batch.max_packages) {
        fail(ctx, "STAGE", "batch-full");
        return 1;
    }
    var index: usize = 0;
    while (index < batch.package_count) : (index += 1) {
        const prior = &batch.packages[index];
        if (pathEqualsIgnoreCase(prior.pathText(), verified.source_path) or
            std.ascii.eqlIgnoreCase(prior.packageText(), verified.package))
        {
            fail(ctx, "STAGE", "package-already-staged");
            return 1;
        }
    }

    var entry = &batch.packages[batch.package_count];
    entry.* = .{ .order = @intCast(batch.package_count) };
    entry.path_len = copyTextZ(entry.path[0..], verified.source_path) orelse return 1;
    entry.package_len = copyTextZ(entry.package[0..], verified.package) orelse return 1;
    entry.package_version_len = copyTextZ(entry.package_version[0..], verified.package_version) orelse return 1;
    entry.release_len = copyTextZ(entry.release[0..], verified.release) orelse return 1;
    entry.package_length = verified.package_length;
    entry.package_digest = verified.package_digest;
    entry.manifest_checksum = verified.manifest_checksum;
    entry.component_digest = verified.component_digest;
    entry.activation = verified.activation;
    entry.priority = verified.priority;
    batch.package_count += 1;
    batch.current_package = 0;
    batch.reason_len = 0;
    batch.valid = true;
    if (!writeInactiveBatchJournal(ctx, batch)) {
        fail(ctx, "STAGE", "batch-journal-write");
        return 1;
    }
    ctx.write("SYSUPD STAGE result: OK state=Staged package=");
    ctx.write(verified.package);
    ctx.write(" batch=");
    ctx.printU64(batch.batch_generation);
    ctx.write(" packages=");
    ctx.printU64(batch.package_count);
    ctx.write(" release=");
    ctx.println(batch.targetReleaseText());
    return 0;
}

const BatchPlanSummary = struct {
    payload_count: usize = 0,
    component_count: usize = 0,
    requirement_count: usize = 0,
};

fn batchEntryMatchesInfo(
    entry: *const system_update_batch.PackageEntry,
    info: *const PackageInfo,
) bool {
    return pathEqualsIgnoreCase(entry.pathText(), info.source_path) and
        std.ascii.eqlIgnoreCase(entry.packageText(), info.package) and
        std.mem.eql(u8, entry.packageVersionText(), info.package_version) and
        std.mem.eql(u8, entry.releaseText(), info.release) and
        entry.package_length == info.package_length and
        entry.package_digest == info.package_digest and
        entry.manifest_checksum == info.manifest_checksum and
        entry.component_digest == info.component_digest and
        entry.activation == info.activation and
        entry.priority == info.priority;
}

fn copyPlanText(out: []u8, value: []const u8) ?[]const u8 {
    if (value.len >= out.len) return null;
    @memset(out, 0);
    @memcpy(out[0..value.len], value);
    return out[0..value.len];
}

fn preverifyBatch(
    ctx: *const r4os.r4sys.Context,
    batch: *system_update_batch.BatchJournal,
) ?BatchPlanSummary {
    if (batch.phase != .staged or batch.package_count == 0) {
        fail(ctx, "COMMIT", "batch-not-staged");
        return null;
    }
    var summary: BatchPlanSummary = .{};
    var package_index: usize = 0;
    while (package_index < batch.package_count) : (package_index += 1) {
        primary_info_workspace = .{};
        command_path_workspace = .{0} ** max_path;
        const entry = &batch.packages[package_index];
        const status = readAndVerifyPackage(
            ctx,
            entry.pathText(),
            command_path_workspace[0..],
            command_manifest_workspace[0..],
            &primary_info_workspace,
            false,
            .deferred_batch,
            "COMMIT",
        );
        if (status != .ok or !batchEntryMatchesInfo(entry, &primary_info_workspace)) {
            if (status == .ok) fail(ctx, "COMMIT", "package-binding-changed");
            return null;
        }
        if (summary.payload_count + primary_info_workspace.payload_count > max_package_payloads or
            summary.component_count + primary_info_workspace.component_count > system_update_batch.max_components or
            summary.requirement_count + primary_info_workspace.requirement_count > system_update_batch.max_requirements)
        {
            fail(ctx, "COMMIT", "batch-capacity");
            return null;
        }
        batch_plan_packages[package_index] = .{ .priority = primary_info_workspace.priority };
        var component_index: usize = 0;
        while (component_index < primary_info_workspace.component_count) : (component_index += 1) {
            const source = &primary_info_workspace.components[component_index];
            const target_index = summary.component_count + component_index;
            const name = copyPlanText(batch_component_names[target_index][0..], source.name) orelse return null;
            const target = copyPlanText(batch_component_targets[target_index][0..], source.targetText()) orelse return null;
            const version = copyPlanText(batch_component_versions[target_index][0..], source.version) orelse return null;
            batch_plan_components[target_index] = .{
                .package_index = @intCast(package_index),
                .kind = source.kind,
                .name = name,
                .target = target,
                .version = version,
            };
        }
        var requirement_index: usize = 0;
        while (requirement_index < primary_info_workspace.requirement_count) : (requirement_index += 1) {
            const source = &primary_info_workspace.requirements[requirement_index];
            const target_index = summary.requirement_count + requirement_index;
            const name = copyPlanText(batch_requirement_names[target_index][0..], source.name) orelse return null;
            const target = copyPlanText(batch_requirement_targets[target_index][0..], source.targetText()) orelse return null;
            const version = copyPlanText(batch_requirement_versions[target_index][0..], source.version) orelse return null;
            const current = requirementCurrentlySatisfied(ctx, &primary_info_workspace, source);
            if (current == .io) {
                fail(ctx, "COMMIT", "requirement-read");
                return null;
            }
            batch_plan_requirements[target_index] = .{
                .package_index = @intCast(package_index),
                .kind = source.kind,
                .name = name,
                .target = target,
                .version = version,
                .current_satisfied = current == .satisfied,
            };
        }
        summary.payload_count += primary_info_workspace.payload_count;
        summary.component_count += primary_info_workspace.component_count;
        summary.requirement_count += primary_info_workspace.requirement_count;
    }
    const order = system_update_batch.planOrder(
        batch_plan_packages[0..batch.package_count],
        batch_plan_components[0..summary.component_count],
        batch_plan_requirements[0..summary.requirement_count],
        batch_order_workspace[0..],
    ) catch |err| {
        fail(ctx, "COMMIT", switch (err) {
            error.DuplicateComponent => "duplicate-component",
            error.UnresolvedRequirement => "unresolved-requirement",
            error.DependencyCycle => "dependency-cycle",
            else => "batch-plan",
        });
        return null;
    };
    package_index = 0;
    while (package_index < order.len) : (package_index += 1)
        batch.packages[order[package_index]].order = @intCast(package_index);
    return summary;
}

fn sameBatchSnapshot(
    left: *const system_update_batch.BatchJournal,
    right: *const system_update_batch.BatchJournal,
) bool {
    if (left.batch_generation != right.batch_generation or
        left.journal_generation != right.journal_generation or
        left.phase != right.phase or
        left.package_count != right.package_count or
        !std.mem.eql(u8, left.sourceReleaseText(), right.sourceReleaseText()) or
        !std.mem.eql(u8, left.targetReleaseText(), right.targetReleaseText())) return false;
    var index: usize = 0;
    while (index < left.package_count) : (index += 1) {
        const a = &left.packages[index];
        const b = &right.packages[index];
        if (!pathEqualsIgnoreCase(a.pathText(), b.pathText()) or
            a.package_digest != b.package_digest or a.package_length != b.package_length or
            a.manifest_checksum != b.manifest_checksum or a.component_digest != b.component_digest)
            return false;
    }
    return true;
}

fn captureTargetStates(
    ctx: *const r4os.r4sys.Context,
    info: *PackageInfo,
    command: []const u8,
) bool {
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        if (!captureTargetState(ctx, &info.payloads[index], command)) return false;
    }
    return true;
}

fn captureTargetState(
    ctx: *const r4os.r4sys.Context,
    entry: *PayloadEntry,
    command: []const u8,
) bool {
    var target_info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, entry.targetPtr(), &target_info)) {
        .found => {
            if (target_info.is_dir != 0) {
                fail(ctx, command, "target-type");
                return false;
            }
            const old_checksum = checksumFileRange(ctx, entry.targetPtr(), 0, target_info.size) orelse {
                fail(ctx, command, "target-read");
                return false;
            };
            entry.target_existed = true;
            entry.old_known = true;
            entry.old_size = target_info.size;
            entry.old_checksum = old_checksum;
            entry.replace_required = target_info.size != entry.size or old_checksum != entry.checksum;
        },
        .not_found => {
            entry.target_existed = false;
            entry.old_known = false;
            entry.replace_required = true;
        },
        .io => {
            fail(ctx, command, "target-info");
            return false;
        },
    }
    entry.already_applied = !entry.replace_required;
    return true;
}

fn packageIndexAtOrder(batch: *const system_update_batch.BatchJournal, order: usize) ?usize {
    var index: usize = 0;
    while (index < batch.package_count) : (index += 1) {
        if (batch.packages[index].order == order) return index;
    }
    return null;
}

fn copyPackageIntoBatch(
    destination: *PackageInfo,
    source: *const PackageInfo,
    payload_base: usize,
    component_base: usize,
) bool {
    if (payload_base + source.payload_count > max_package_payloads or
        component_base + source.component_count > max_package_payloads) return false;
    var index: usize = 0;
    while (index < source.payload_count) : (index += 1) {
        destination.payloads[payload_base + index] = source.payloads[index];
        destination.payloads[payload_base + index].name = "";
        destination.payloads[payload_base + index].kind = "";
        if (destination.payloads[payload_base + index].component_index) |component_index|
            destination.payloads[payload_base + index].component_index = @intCast(component_base + component_index);
    }
    index = 0;
    while (index < source.component_count) : (index += 1) {
        const from = &source.components[index];
        var to = &destination.components[component_base + index];
        to.* = .{
            .payload_index = @intCast(payload_base + from.payload_index),
            .kind = from.kind,
            .install = from.install,
        };
        const name_len = copyTextZ(to.name_storage[0..], from.name) orelse return false;
        to.name = to.name_storage[0..name_len];
        to.target_len = copyTypedText(to.target_path[0..], from.targetText());
        const version_len = copyTextZ(to.version_storage[0..], from.version) orelse return false;
        to.version = to.version_storage[0..version_len];
    }
    return true;
}

fn prepareBatchInventoryData(
    ctx: *const r4os.r4sys.Context,
    info: *const PackageInfo,
    command: []const u8,
) InventoryDataStatus {
    var file_info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, inventory_path, &file_info)) {
        .found => {},
        .not_found => {
            fail(ctx, command, "inventory-not-found");
            return .failed;
        },
        .io => {
            fail(ctx, command, "inventory-info");
            return .io;
        },
    }
    if (file_info.is_dir != 0 or file_info.size == 0 or file_info.size > system_update_inventory.max_bytes) {
        fail(ctx, command, "inventory-size");
        return .failed;
    }
    inventory_source_length = @intCast(file_info.size);
    if (!readExactAt(ctx, inventory_path, 0, inventory_source_buf[0..inventory_source_length]).ok) {
        fail(ctx, command, "inventory-read");
        return .io;
    }
    if (!system_update_inventory.Inventory.parse(inventory_source_buf[0..inventory_source_length], &inventory_workspace)) {
        fail(ctx, command, "inventory-invalid");
        return .failed;
    }
    var index: usize = 0;
    while (index < info.component_count) : (index += 1) {
        const component = &info.components[index];
        if (!inventory_workspace.upsert(.{
            .name = component.name,
            .kind = component.kind,
            .version = component.version,
            .target = component.targetText(),
        })) {
            fail(ctx, command, "inventory-upsert");
            return .failed;
        }
    }
    const rendered = inventory_workspace.render(inventory_render_buf[0..]) orelse {
        fail(ctx, command, "inventory-render");
        return .failed;
    };
    return .{ .ready = rendered };
}

fn appendGeneratedPayload(
    ctx: *const r4os.r4sys.Context,
    info: *PackageInfo,
    target_path: []const u8,
    bytes: []const u8,
    command: []const u8,
) CommitResult {
    if (info.payload_count >= max_payloads or bytes.len == 0) return .failed;
    const index: usize = @intCast(info.payload_count);
    var entry = &info.payloads[index];
    entry.* = .{ .size = bytes.len, .checksum = checksum(bytes), .class = .config };
    entry.target_len = copyTextZ(entry.target_path[0..], target_path) orelse return .failed;
    entry.stage_len = buildInternal83Name(entry.stage_path[0..], entry.targetText(), 'S', info.transaction_generation, index) orelse return .failed;
    entry.backup_len = buildInternal83Name(entry.backup_path[0..], entry.targetText(), 'B', info.transaction_generation, index) orelse return .failed;
    info.payload_count += 1;
    if (!captureTargetState(ctx, entry, command)) return .failed;
    if (!entry.replace_required) return .ok;
    switch (payloadPathState(ctx, entry.stagePtr(), entry.size, entry.checksum)) {
        .match => return .ok,
        .other => return .failed,
        .io => return .io,
        .not_found => {},
    }
    var writer: r4os.file_stream.WriterState = undefined;
    if (!r4os.file_stream.begin(ctx, &writer, entry.stagePtr(), r4os.abi.file_stream_open_create)) {
        if (!settlePrivateStageOrFail(ctx, entry, command)) return .failed;
        return .io;
    }
    if (!r4os.file_stream.write(ctx, &writer, bytes) or !r4os.file_stream.finish(ctx, &writer)) {
        if (!settlePrivateStageOrFail(ctx, entry, command)) return .failed;
        return .io;
    }
    info.staged_bytes += bytes.len;
    return .ok;
}

/// Discards only a restart batch that has not acquired a durable transaction
/// journal. Every private stage is reconstructed from the still-bound package
/// and removed by size+checksum; targets and retained backups are untouched.
fn abortPreparedBatchCommand(ctx: *const r4os.r4sys.Context) i32 {
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "ABORT-BATCH", "update-dirs");
        return 1;
    }
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {},
        .not_found => {
            ctx.println("SYSUPD ABORT-BATCH result: OK state=Idle");
            return 0;
        },
        .io => {
            fail(ctx, "ABORT-BATCH", "batch-read");
            return 1;
        },
    }
    if (!batchPreparationAbortable(batch_journal_workspace.phase)) {
        fail(ctx, "ABORT-BATCH", "batch-not-abortable");
        return 1;
    }

    switch (acquireUpdateLock(ctx, false)) {
        .acquired => {},
        .busy => {
            fail(ctx, "ABORT-BATCH", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "ABORT-BATCH", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {},
        .not_found, .io => {
            fail(ctx, "ABORT-BATCH", "batch-reread");
            return 1;
        },
    }
    const batch = &batch_journal_workspace;
    if (!batchPreparationAbortable(batch.phase)) {
        fail(ctx, "ABORT-BATCH", "batch-not-abortable");
        return 1;
    }

    var transaction_generation: u64 = 1;
    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .found => {
            if (!phaseTerminal(command_journal_workspace.phase)) {
                fail(ctx, "ABORT-BATCH", "resume-required");
                return 1;
            }
            if (command_journal_workspace.transaction_generation == std.math.maxInt(u64)) {
                fail(ctx, "ABORT-BATCH", "transaction-generation-exhausted");
                return 1;
            }
            transaction_generation = command_journal_workspace.transaction_generation + 1;
        },
        .not_found => {},
        .io => {
            fail(ctx, "ABORT-BATCH", "journal-read");
            return 1;
        },
    }

    batch_info_workspace = .{
        .source_path = batch.packages[packageIndexAtOrder(batch, 0) orelse return 1].pathText(),
        .package = "RESTART-BATCH",
        .package_version = batch.targetReleaseText(),
        .release = batch.targetReleaseText(),
        .activation = .restart,
        .reboot = true,
        .transaction_generation = transaction_generation,
    };
    const info = &batch_info_workspace;
    var payload_base: usize = 0;
    var component_base: usize = 0;
    var order: usize = 0;
    while (order < batch.package_count) : (order += 1) {
        const package_index = packageIndexAtOrder(batch, order) orelse {
            fail(ctx, "ABORT-BATCH", "batch-order");
            return 1;
        };
        const binding = &batch.packages[package_index];
        primary_info_workspace = .{ .transaction_generation = transaction_generation };
        command_path_workspace = .{0} ** max_path;
        const package_info = &primary_info_workspace;
        const status = readAndVerifyPackage(
            ctx,
            binding.pathText(),
            command_path_workspace[0..],
            command_manifest_workspace[0..],
            package_info,
            false,
            .deferred_batch,
            "ABORT-BATCH",
        );
        if (status != .ok or !batchEntryMatchesInfo(binding, package_info)) {
            if (status == .ok) fail(ctx, "ABORT-BATCH", "package-binding-changed");
            return 1;
        }
        if (!assignInternalPathsAt(ctx, package_info, "ABORT-BATCH", payload_base) or
            !copyPackageIntoBatch(info, package_info, payload_base, component_base))
        {
            fail(ctx, "ABORT-BATCH", "batch-copy");
            return 1;
        }
        payload_base += package_info.payload_count;
        component_base += package_info.component_count;
    }
    info.payload_count = @intCast(payload_base);
    info.component_count = @intCast(component_base);

    const inventory = switch (prepareBatchInventoryData(ctx, info, "ABORT-BATCH")) {
        .ready => |bytes| bytes,
        .failed, .io => return 1,
    };
    if (info.payload_count >= max_payloads) {
        fail(ctx, "ABORT-BATCH", "batch-capacity");
        return 1;
    }
    const inventory_index: usize = @intCast(info.payload_count);
    var inventory_entry = &info.payloads[inventory_index];
    inventory_entry.* = .{ .size = inventory.len, .checksum = checksum(inventory), .class = .config };
    inventory_entry.target_len = copyTextZ(inventory_entry.target_path[0..], inventory_path) orelse return 1;
    inventory_entry.stage_len = buildInternal83Name(
        inventory_entry.stage_path[0..],
        inventory_entry.targetText(),
        'S',
        transaction_generation,
        inventory_index,
    ) orelse return 1;
    inventory_entry.backup_len = buildInternal83Name(
        inventory_entry.backup_path[0..],
        inventory_entry.targetText(),
        'B',
        transaction_generation,
        inventory_index,
    ) orelse return 1;
    info.payload_count += 1;

    switch (deleteStagedPayloads(ctx, info)) {
        .ok => {},
        .conflict => {
            fail(ctx, "ABORT-BATCH", "stage-conflict");
            return 1;
        },
        .io => {
            fail(ctx, "ABORT-BATCH", "stage-delete");
            return 1;
        },
        else => unreachable,
    }

    const aborted_package_count = batch.package_count;
    for (batch_journal_paths) |path| {
        if (ctx.fileDelete(path) < 0) {
            fail(ctx, "ABORT-BATCH", "batch-delete");
            return 1;
        }
    }
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .not_found => {},
        .found => {
            fail(ctx, "ABORT-BATCH", "batch-delete-incomplete");
            return 1;
        },
        .io => {
            fail(ctx, "ABORT-BATCH", "batch-delete-read");
            return 1;
        },
    }
    ctx.write("SYSUPD ABORT-BATCH result: OK state=Idle packages=");
    ctx.printU64(aborted_package_count);
    ctx.write(" stages=");
    ctx.printU64(info.payload_count);
    ctx.println("");
    return 0;
}

fn batchPreparationAbortable(phase: system_update_batch.Phase) bool {
    return phase == .staged or phase == .verifying or phase == .staging;
}

fn commitBatchCommand(ctx: *const r4os.r4sys.Context) i32 {
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "COMMIT", "update-dirs");
        return 1;
    }
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {},
        .not_found => {
            fail(ctx, "COMMIT", "batch-not-found");
            return 1;
        },
        .io => {
            fail(ctx, "COMMIT", "batch-read");
            return 1;
        },
    }
    _ = preverifyBatch(ctx, &batch_journal_workspace) orelse return 1;
    batch_verify_journal_workspace = batch_journal_workspace;

    switch (acquireUpdateLock(ctx, false)) {
        .acquired => {},
        .busy => {
            fail(ctx, "COMMIT", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "COMMIT", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {},
        .not_found, .io => {
            fail(ctx, "COMMIT", "batch-reread");
            return 1;
        },
    }
    if (!sameBatchSnapshot(&batch_verify_journal_workspace, &batch_journal_workspace)) {
        fail(ctx, "COMMIT", "batch-changed");
        return 1;
    }
    var index: usize = 0;
    while (index < batch_journal_workspace.package_count) : (index += 1)
        batch_journal_workspace.packages[index].order = batch_verify_journal_workspace.packages[index].order;
    batch_journal_workspace.phase = .verifying;
    if (!writeInactiveBatchJournal(ctx, &batch_journal_workspace)) {
        fail(ctx, "COMMIT", "batch-verifying-journal");
        return 1;
    }
    return commitPreparedBatchLocked(ctx, &batch_journal_workspace);
}

fn batchPackageSourcesDisjoint(
    ctx: *const r4os.r4sys.Context,
    batch: *const system_update_batch.BatchJournal,
    info: *const PackageInfo,
) bool {
    var package_index: usize = 0;
    while (package_index < batch.package_count) : (package_index += 1) {
        const source = batch.packages[package_index].pathText();
        var payload_index: usize = 0;
        while (payload_index < info.payload_count) : (payload_index += 1) {
            const payload = &info.payloads[payload_index];
            if (packagePathsAlias(ctx, source, payload.targetText()) or
                packagePathsAlias(ctx, source, payload.stageText()) or
                packagePathsAlias(ctx, source, payload.backupText()))
            {
                fail(ctx, "COMMIT", "package-target-alias");
                return false;
            }
        }
    }
    return true;
}

fn setBatchReason(batch: *system_update_batch.BatchJournal, reason: []const u8) void {
    batch.reason_len = copyTextZ(batch.reason[0..], reason) orelse 0;
}

fn commitPreparedBatchLocked(
    ctx: *const r4os.r4sys.Context,
    batch: *system_update_batch.BatchJournal,
) i32 {
    var transaction_bound = false;
    defer if (!transaction_bound) restoreRetryableBatchPreparation(ctx, batch);

    var previous: ?*const TransactionJournal = null;
    var transaction_generation: u64 = 1;
    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .found => {
            if (!phaseTerminal(command_journal_workspace.phase)) {
                fail(ctx, "COMMIT", "resume-required");
                return 1;
            }
            if (command_journal_workspace.transaction_generation == std.math.maxInt(u64)) {
                fail(ctx, "COMMIT", "transaction-generation-exhausted");
                return 1;
            }
            previous_journal_workspace = command_journal_workspace;
            previous = &previous_journal_workspace;
            transaction_generation = command_journal_workspace.transaction_generation + 1;
        },
        .not_found => {},
        .io => {
            fail(ctx, "COMMIT", "journal-read");
            return 1;
        },
    }

    batch_info_workspace = .{
        .source_path = batch.packages[packageIndexAtOrder(batch, 0) orelse return 1].pathText(),
        .package = "RESTART-BATCH",
        .package_version = batch.targetReleaseText(),
        .release = batch.targetReleaseText(),
        .activation = .restart,
        .reboot = true,
        .transaction_generation = transaction_generation,
    };
    const info = &batch_info_workspace;
    info.source_version_len = copyTextZ(info.source_version[0..], batch.sourceReleaseText()) orelse {
        fail(ctx, "COMMIT", "source-version-length");
        return 1;
    };
    batch.phase = .staging;
    batch.current_package = 0;
    setBatchReason(batch, "");
    if (!writeInactiveBatchJournal(ctx, batch)) return 1;

    var payload_base: usize = 0;
    var component_base: usize = 0;
    var order: usize = 0;
    while (order < batch.package_count) : (order += 1) {
        const package_index = packageIndexAtOrder(batch, order) orelse {
            fail(ctx, "COMMIT", "batch-order");
            return 1;
        };
        const binding = &batch.packages[package_index];
        primary_info_workspace = .{ .transaction_generation = transaction_generation };
        command_path_workspace = .{0} ** max_path;
        const package_info = &primary_info_workspace;
        const status = readAndVerifyPackage(
            ctx,
            binding.pathText(),
            command_path_workspace[0..],
            command_manifest_workspace[0..],
            package_info,
            false,
            .deferred_batch,
            "COMMIT",
        );
        if (status != .ok or !batchEntryMatchesInfo(binding, package_info)) {
            if (status == .ok) fail(ctx, "COMMIT", "package-binding-changed");
            return 1;
        }
        if (!assignInternalPathsAt(ctx, package_info, "COMMIT", payload_base) or
            !captureTargetStates(ctx, package_info, "COMMIT") or
            !validateTargetAliases(ctx, package_info, "COMMIT")) return 1;
        const stage_status = streamPackagePayloadsWithTransientRetry(
            ctx,
            command_path_workspace[0..].ptr,
            package_info.header,
            command_manifest_workspace[0..@intCast(package_info.header.manifest_len)],
            package_info,
            true,
            "COMMIT",
        );
        if (stage_status != .ok) return packageVerifyExitCode(stage_status);
        if (!copyPackageIntoBatch(info, package_info, payload_base, component_base)) {
            fail(ctx, "COMMIT", "batch-copy");
            return 1;
        }
        info.payload_bytes += package_info.payload_bytes;
        info.streamed_bytes += package_info.streamed_bytes;
        info.staged_bytes += package_info.staged_bytes;
        info.package_length = std.math.add(u64, info.package_length, package_info.package_length) catch return 1;
        info.package_digest = checksumUpdate(info.package_digest, std.mem.asBytes(&binding.package_digest));
        info.manifest_checksum = checksumUpdate(info.manifest_checksum, std.mem.asBytes(&binding.manifest_checksum));
        info.component_digest = checksumUpdate(info.component_digest, std.mem.asBytes(&binding.component_digest));
        if (package_info.priority == .foundation) info.priority = .foundation;
        payload_base += package_info.payload_count;
        component_base += package_info.component_count;
        batch.current_package = @intCast(order + 1);
        if (!writeInactiveBatchJournal(ctx, batch)) return 1;
    }
    info.payload_count = @intCast(payload_base);
    info.payloads_expected = @intCast(payload_base);
    info.component_count = @intCast(component_base);
    info.components_expected = @intCast(component_base);
    if (!batchPackageSourcesDisjoint(ctx, batch, info) or !validateTargetAliases(ctx, info, "COMMIT")) return 1;

    const inventory = switch (prepareBatchInventoryData(ctx, info, "COMMIT")) {
        .ready => |bytes| bytes,
        .failed => return 1,
        .io => return 1,
    };
    switch (appendGeneratedPayload(ctx, info, inventory_path, inventory, "COMMIT")) {
        .ok => {},
        .failed => {
            fail(ctx, "COMMIT", "inventory-stage");
            return 1;
        },
        .io => {
            fail(ctx, "COMMIT", "inventory-stage-io");
            return 1;
        },
        .interrupted => unreachable,
    }
    if (!bindPreviousBackups(ctx, info, previous) or
        !batchPackageSourcesDisjoint(ctx, batch, info) or
        !validateTargetAliases(ctx, info, "COMMIT")) return 1;

    const journal = &command_journal_workspace;
    journalFromInfo(info, .stage, journal);
    journal.batch = true;
    journal.reboot = true;
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, "COMMIT", "journal-stage");
        return 1;
    }
    transaction_bound = true;
    batch.phase = .committing;
    batch.current_package = 0;
    if (!writeInactiveBatchJournal(ctx, batch)) return 1;

    var io = SysUpdRecoveryIo{ .ctx = ctx };
    const forward = system_update_recovery.resumeBatchForward(&io, journal);
    if (forward != .ok) {
        if (forward == .conflict) {
            batch.phase = .rolling_back;
            setBatchReason(batch, "commit-conflict");
            _ = writeInactiveBatchJournal(ctx, batch);
            const rollback = system_update_recovery.rollbackToTerminal(&io, journal);
            batch.phase = if (rollback == .ok) .rolled_back else .failed;
            setBatchReason(batch, if (rollback == .ok) "commit-rolled-back" else "rollback-failed");
            _ = writeInactiveBatchJournal(ctx, batch);
        }
        fail(ctx, "COMMIT", system_update_recovery.replayStatusName(forward));
        return 1;
    }
    infoFromJournal(journal, info);
    batch.phase = .pending_restart;
    batch.current_package = batch.package_count;
    if (!writeInactiveBatchJournal(ctx, batch)) {
        fail(ctx, "COMMIT", "batch-pending-restart");
        return 1;
    }
    ctx.write("SYSUPD COMMIT result: OK state=Pending restart batch=");
    ctx.printU64(batch.batch_generation);
    ctx.write(" packages=");
    ctx.printU64(batch.package_count);
    ctx.write(" release=");
    ctx.println(batch.targetReleaseText());
    ctx.systemReboot();
}

fn restoreRetryableBatchPreparation(
    ctx: *const r4os.r4sys.Context,
    batch: *system_update_batch.BatchJournal,
) void {
    if (batch.phase != .verifying and batch.phase != .staging) return;
    batch.phase = .staged;
    batch.current_package = 0;
    setBatchReason(batch, "prepare-retry");
    _ = writeInactiveBatchJournal(ctx, batch);
}

fn verifyPostBootComponents(
    ctx: *const r4os.r4sys.Context,
    journal: *const TransactionJournal,
) PackageVerifyStatus {
    var index: usize = 0;
    while (index < journal.component_count) : (index += 1) {
        const component = &journal.components[index];
        if (component.payload_index >= journal.package_payload_count) return .invalid;
        const payload = &journal.payloads[component.payload_index];
        var file_info: r4os.abi.FileInfo = .{};
        switch (fileInfoStatus(ctx, payload.targetPtr(), &file_info)) {
            .found => {},
            .not_found => return .invalid,
            .io => return .io,
        }
        if (file_info.is_dir != 0 or file_info.size == 0) return .invalid;
        const identity = r4u_artifact.inspect(ArtifactFileReader{
            .ctx = ctx,
            .path = payload.targetPtr(),
            .base = 0,
            .size = file_info.size,
        }, file_info.size) orelse return .invalid;
        const kind = manifestComponentKind(component.kind);
        if (identity.kind != kind or
            !std.ascii.eqlIgnoreCase(identity.nameText(), component.nameText()) or
            !std.mem.eql(u8, identity.versionText(), component.versionText())) return .invalid;
        if (kind == .kernel) {
            const active = active_kernel_version[0..active_kernel_version_len];
            if (active.len == 0 or !std.mem.eql(u8, active, component.versionText())) return .incompatible;
        }
    }
    return .ok;
}

fn renderReleaseVersion(version: []const u8) ?[]const u8 {
    if (!versionTextValid(version)) return null;
    const prefix = "\xEF\xBB\xBFRELEASE_VERSION=";
    const suffix = "\n";
    if (prefix.len + version.len + suffix.len > release_render_workspace.len) return null;
    var len: usize = 0;
    @memcpy(release_render_workspace[len .. len + prefix.len], prefix);
    len += prefix.len;
    @memcpy(release_render_workspace[len .. len + version.len], version);
    len += version.len;
    @memcpy(release_render_workspace[len .. len + suffix.len], suffix);
    len += suffix.len;
    return release_render_workspace[0..len];
}

fn confirmLiveReleaseCommand(ctx: *const r4os.r4sys.Context, source_release: []const u8, target_release: []const u8) i32 {
    primary_info_workspace = .{
        .package = "RELEASE-CONFIRM",
        .package_version = target_release,
        .release = target_release,
        .activation = .live,
    };
    const info = &primary_info_workspace;
    if (!versionTextValid(source_release) or !versionTextValid(target_release) or
        (r4u_manifest.compareVersions(target_release, source_release) orelse 0) <= 0)
    {
        fail(ctx, "CONFIRM-RELEASE", "release-version");
        return 1;
    }
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "CONFIRM-RELEASE", "update-dirs");
        return 1;
    }
    switch (acquireUpdateLock(ctx, false)) {
        .acquired => {},
        .busy => {
            fail(ctx, "CONFIRM-RELEASE", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "CONFIRM-RELEASE", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);

    var current_buf: [32]u8 = .{0} ** 32;
    const current = switch (readCurrentVersionStatus(ctx, current_buf[0..])) {
        .found => |value| value,
        .not_found, .invalid => {
            fail(ctx, "CONFIRM-RELEASE", "source-version");
            return 1;
        },
        .io => {
            fail(ctx, "CONFIRM-RELEASE", "source-version-read");
            return 1;
        },
    };
    if (std.mem.eql(u8, current, target_release)) return 0;
    if (!std.mem.eql(u8, current, source_release)) {
        fail(ctx, "CONFIRM-RELEASE", "source-version-changed");
        return 1;
    }
    info.source_version_len = copyTextZ(info.source_version[0..], source_release) orelse return 1;

    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => if (!system_update_batch.phaseTerminal(batch_journal_workspace.phase)) {
            fail(ctx, "CONFIRM-RELEASE", "restart-batch-pending");
            return 1;
        },
        .not_found => {},
        .io => {
            fail(ctx, "CONFIRM-RELEASE", "batch-read");
            return 1;
        },
    }

    var previous: ?*const TransactionJournal = null;
    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .found => {
            if (!phaseTerminal(command_journal_workspace.phase)) {
                fail(ctx, "CONFIRM-RELEASE", "resume-required");
                return 1;
            }
            if (command_journal_workspace.transaction_generation == std.math.maxInt(u64)) {
                fail(ctx, "CONFIRM-RELEASE", "transaction-generation-exhausted");
                return 1;
            }
            previous_journal_workspace = command_journal_workspace;
            previous = &previous_journal_workspace;
            info.transaction_generation = command_journal_workspace.transaction_generation + 1;
        },
        .not_found => info.transaction_generation = 1,
        .io => {
            fail(ctx, "CONFIRM-RELEASE", "journal-read");
            return 1;
        },
    }

    const rendered = renderReleaseVersion(target_release) orelse {
        fail(ctx, "CONFIRM-RELEASE", "version-render");
        return 1;
    };
    switch (appendGeneratedPayload(ctx, info, version_path, rendered, "CONFIRM-RELEASE")) {
        .ok => {},
        .failed, .io => return 1,
        .interrupted => unreachable,
    }
    if (!bindPreviousBackups(ctx, info, previous) or !validateTargetAliases(ctx, info, "CONFIRM-RELEASE")) return 1;

    const journal = &command_journal_workspace;
    journalFromInfo(info, .stage, journal);
    if (!writeInactiveJournal(ctx, journal)) return 1;
    switch (commitTransaction(ctx, info, journal)) {
        .ok => {},
        .failed => {
            _ = rollbackTransactionReverse(ctx, info, journal);
            return 1;
        },
        .io => return 1,
        .interrupted => return 75,
    }
    journal.phase = .verify;
    if (!writeInactiveJournal(ctx, journal)) return 1;
    if (verifyCommittedPayloads(ctx, info) != .match) {
        fail(ctx, "CONFIRM-RELEASE", "target-verify");
        _ = rollbackTransactionReverse(ctx, info, journal);
        return 1;
    }
    journal.phase = .applied;
    if (!writeInactiveJournal(ctx, journal) or !cleanupTransaction(ctx, info, journal)) {
        fail(ctx, "CONFIRM-RELEASE", "cleanup");
        return 1;
    }
    return 0;
}

fn finalizeBatchPostBootLocked(
    ctx: *const r4os.r4sys.Context,
    batch: *system_update_batch.BatchJournal,
    journal: *TransactionJournal,
) i32 {
    if (!journal.batch or journal.phase != .post_boot or
        !std.mem.eql(u8, journal.sourceReleaseText(), batch.sourceReleaseText()) or
        !std.mem.eql(u8, journal.releaseText(), batch.targetReleaseText()))
    {
        fail(ctx, "RESUME-BATCH", "postboot-binding");
        return 1;
    }
    infoFromJournal(journal, &batch_info_workspace);
    if (verifyCommittedPayloads(ctx, &batch_info_workspace) != .match) {
        fail(ctx, "RESUME-BATCH", "postboot-targets");
        return 1;
    }
    const component_status = verifyPostBootComponents(ctx, journal);
    if (component_status != .ok) {
        fail(ctx, "RESUME-BATCH", if (component_status == .io) "postboot-component-read" else "postboot-component");
        return 1;
    }

    var current_release_buf: [32]u8 = .{0} ** 32;
    const current_release = switch (readCurrentVersionStatus(ctx, current_release_buf[0..])) {
        .found => |version| version,
        .not_found, .invalid => {
            fail(ctx, "RESUME-BATCH", "postboot-release");
            return 1;
        },
        .io => {
            fail(ctx, "RESUME-BATCH", "postboot-release-read");
            return 1;
        },
    };
    const version_already_bound = journal.payload_count == journal.package_payload_count + 2;
    if (version_already_bound) {
        if (!std.mem.eql(u8, current_release, batch.targetReleaseText())) {
            fail(ctx, "RESUME-BATCH", "postboot-release-target");
            return 1;
        }
    } else {
        if (journal.payload_count != journal.package_payload_count + 1 or
            !std.mem.eql(u8, current_release, batch.sourceReleaseText()))
        {
            fail(ctx, "RESUME-BATCH", "postboot-release-source");
            return 1;
        }
        const rendered = renderReleaseVersion(batch.targetReleaseText()) orelse return 1;
        switch (appendGeneratedPayload(ctx, &batch_info_workspace, version_path, rendered, "RESUME-BATCH")) {
            .ok => {},
            .failed => {
                fail(ctx, "RESUME-BATCH", "version-stage");
                return 1;
            },
            .io => {
                fail(ctx, "RESUME-BATCH", "version-stage-io");
                return 1;
            },
            .interrupted => unreachable,
        }
        if (!validateTargetAliases(ctx, &batch_info_workspace, "RESUME-BATCH")) return 1;
        syncJournalFromInfo(journal, &batch_info_workspace, .commit);
        journal.batch = true;
        journal.reboot = true;
        if (!writeInactiveJournal(ctx, journal)) return 1;
        var io = SysUpdRecoveryIo{ .ctx = ctx };
        const forward = system_update_recovery.resumeBatchForward(&io, journal);
        if (forward != .ok) {
            fail(ctx, "RESUME-BATCH", system_update_recovery.replayStatusName(forward));
            return 1;
        }
        infoFromJournal(journal, &batch_info_workspace);
    }

    journal.phase = .applied;
    if (!writeInactiveJournal(ctx, journal) or !cleanupTransaction(ctx, &batch_info_workspace, journal)) {
        fail(ctx, "RESUME-BATCH", "postboot-cleanup");
        return 1;
    }
    batch.phase = .installed;
    batch.current_package = batch.package_count;
    setBatchReason(batch, "");
    if (!writeInactiveBatchJournal(ctx, batch)) return 1;
    ctx.write("SYSUPD RESUME-BATCH result: OK state=Installed batch=");
    ctx.printU64(batch.batch_generation);
    ctx.write(" release=");
    ctx.println(batch.targetReleaseText());
    return 0;
}

fn resumeBatchCommand(ctx: *const r4os.r4sys.Context) i32 {
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "RESUME-BATCH", "update-dirs");
        return 1;
    }
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {},
        .not_found => {
            fail(ctx, "RESUME-BATCH", "batch-not-found");
            return 1;
        },
        .io => {
            fail(ctx, "RESUME-BATCH", "batch-read");
            return 1;
        },
    }
    if (system_update_batch.phaseTerminal(batch_journal_workspace.phase)) {
        ctx.write("SYSUPD RESUME-BATCH result: OK state=");
        ctx.println(batch_journal_workspace.phase.text());
        return 0;
    }

    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .not_found => {
            if (batch_journal_workspace.phase == .staged or
                batch_journal_workspace.phase == .verifying or
                batch_journal_workspace.phase == .staging)
            {
                batch_journal_workspace.phase = .staged;
                batch_journal_workspace.current_package = 0;
                if (!writeInactiveBatchJournal(ctx, &batch_journal_workspace)) return 1;
                return commitBatchCommand(ctx);
            }
            fail(ctx, "RESUME-BATCH", "transaction-not-found");
            return 1;
        },
        .found => {},
        .io => {
            fail(ctx, "RESUME-BATCH", "journal-read");
            return 1;
        },
    }
    if (!command_journal_workspace.batch and
        phaseTerminal(command_journal_workspace.phase) and
        (batch_journal_workspace.phase == .staged or
            batch_journal_workspace.phase == .verifying or
            batch_journal_workspace.phase == .staging))
    {
        batch_journal_workspace.phase = .staged;
        batch_journal_workspace.current_package = 0;
        setBatchReason(&batch_journal_workspace, "prepare-retry");
        if (!writeInactiveBatchJournal(ctx, &batch_journal_workspace)) return 1;
        return commitBatchCommand(ctx);
    }
    if (!command_journal_workspace.batch) {
        fail(ctx, "RESUME-BATCH", "not-batch-transaction");
        return 1;
    }
    switch (acquireUpdateLock(ctx, true)) {
        .acquired => {},
        .busy => {
            fail(ctx, "RESUME-BATCH", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "RESUME-BATCH", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => {},
        .not_found, .io => return 1,
    }
    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .found => {},
        .not_found, .io => return 1,
    }
    const journal = &command_journal_workspace;
    if (!journal.batch) return 1;
    if (journal.phase == .stage or journal.phase == .commit) {
        batch_journal_workspace.phase = .committing;
        if (!writeInactiveBatchJournal(ctx, &batch_journal_workspace)) return 1;
        var io = SysUpdRecoveryIo{ .ctx = ctx };
        const forward = system_update_recovery.resumeBatchForward(&io, journal);
        if (forward != .ok) {
            if (forward == .conflict) {
                batch_journal_workspace.phase = .rolling_back;
                setBatchReason(&batch_journal_workspace, "resume-conflict");
                _ = writeInactiveBatchJournal(ctx, &batch_journal_workspace);
                const rollback = system_update_recovery.rollbackToTerminal(&io, journal);
                batch_journal_workspace.phase = if (rollback == .ok) .rolled_back else .failed;
                _ = writeInactiveBatchJournal(ctx, &batch_journal_workspace);
            }
            fail(ctx, "RESUME-BATCH", system_update_recovery.replayStatusName(forward));
            return 1;
        }
        batch_journal_workspace.phase = .pending_restart;
        batch_journal_workspace.current_package = batch_journal_workspace.package_count;
        if (!writeInactiveBatchJournal(ctx, &batch_journal_workspace)) return 1;
        ctx.println("SYSUPD RESUME-BATCH result: OK state=Pending restart");
        ctx.systemReboot();
    }
    if (journal.phase == .post_boot)
        return finalizeBatchPostBootLocked(ctx, &batch_journal_workspace, journal);
    if (journal.phase == .applied) {
        // Post-boot verification has already proved the running kernel,
        // installed artifacts, inventory and release. A transient cleanup
        // failure must remain retryable at runtime just as it is in the
        // allocation-free boot recovery path; rolling back or requiring a
        // second reboot here would discard a safely applied transaction.
        if (!std.mem.eql(u8, journal.sourceReleaseText(), batch_journal_workspace.sourceReleaseText()) or
            !std.mem.eql(u8, journal.releaseText(), batch_journal_workspace.targetReleaseText()))
        {
            fail(ctx, "RESUME-BATCH", "applied-binding");
            return 1;
        }
        infoFromJournal(journal, &batch_info_workspace);
        if (!cleanupTransaction(ctx, &batch_info_workspace, journal)) {
            fail(ctx, "RESUME-BATCH", "applied-cleanup");
            return 1;
        }
    }
    if (journal.phase == .rolled_back) {
        batch_journal_workspace.phase = .rolled_back;
        setBatchReason(&batch_journal_workspace, "transaction-rolled-back");
        return if (writeInactiveBatchJournal(ctx, &batch_journal_workspace)) 0 else 1;
    }
    if (journal.phase == .cleanup) {
        batch_journal_workspace.phase = .installed;
        batch_journal_workspace.current_package = batch_journal_workspace.package_count;
        setBatchReason(&batch_journal_workspace, "");
        if (!writeInactiveBatchJournal(ctx, &batch_journal_workspace)) return 1;
        ctx.write("SYSUPD RESUME-BATCH result: OK state=Installed batch=");
        ctx.printU64(batch_journal_workspace.batch_generation);
        ctx.write(" release=");
        ctx.println(batch_journal_workspace.targetReleaseText());
        return 0;
    }
    fail(ctx, "RESUME-BATCH", "transaction-state");
    return 1;
}

fn resumeCommand(ctx: *const r4os.r4sys.Context) i32 {
    return resumeTransaction(ctx);
}

fn resumeTransaction(ctx: *const r4os.r4sys.Context) i32 {
    if (!ensureUpdateDirectories(ctx)) {
        fail(ctx, "RESUME", "update-dirs");
        return 1;
    }
    // The journal snapshot belongs to the exclusive update lease. Reading it
    // first allowed a second RESUME to acquire the lease just after the first
    // process completed and then continue from its stale non-terminal copy.
    switch (acquireUpdateLock(ctx, true)) {
        .acquired => {},
        .busy => {
            fail(ctx, "RESUME", "transaction-active");
            return 1;
        },
        .io => {
            fail(ctx, "RESUME", "lock-io");
            return 1;
        },
    }
    defer releaseUpdateLock(ctx);

    const journal = &command_journal_workspace;
    switch (readNewestValidJournalInto(ctx, journal)) {
        .found => {},
        .not_found => {
            fail(ctx, "RESUME", "journal-not-found");
            return 1;
        },
        .io => {
            fail(ctx, "RESUME", "journal-read");
            return 1;
        },
    }
    if (journal.batch) {
        fail(ctx, "RESUME", "use-resume-batch");
        return 1;
    }
    if (phaseTerminal(journal.phase)) {
        ctx.write("SYSUPD RESUME result: OK state=");
        ctx.println(phaseName(journal.phase));
        return 0;
    }

    const info = &primary_info_workspace;
    infoFromJournal(journal, info);
    if (journal.phase == .applied) {
        // Every payload is already committed and verified.  The boot adapter
        // enters the same shared cleanup path without reopening the package;
        // RESUME must not roll a valid applied transaction back merely because
        // its transport package was removed from the inbox meanwhile.
        if (!cleanupTransaction(ctx, info, journal)) return 1;
        ctx.println("SYSUPD RESUME result: OK state=cleanup");
        return 0;
    }
    if (journal.phase == .rollback) {
        return if (rollbackTransactionReverse(ctx, info, journal)) 0 else 1;
    }
    if (journal.phase == .inventory) {
        switch (resumeInventoryPhase(ctx, info, journal, "RESUME")) {
            .ok => {},
            .failed => {
                _ = rollbackTransactionReverse(ctx, info, journal);
                return 1;
            },
            .io => return 1,
            .interrupted => {
                ctx.println("SYSUPD RESUME result: INTERRUPTED phase=inventory");
                return 75;
            },
        }
        journal.phase = .applied;
        if (!writeInactiveJournal(ctx, journal)) return 1;
        if (!cleanupTransaction(ctx, info, journal)) return 1;
        ctx.println("SYSUPD RESUME result: OK state=inventory-complete");
        return 0;
    }

    command_path_workspace = .{0} ** max_path;
    secondary_info_workspace = .{ .transaction_generation = journal.transaction_generation };
    const path_buf = command_path_workspace[0..];
    const manifest_buf = command_manifest_workspace[0..];
    const package_info = &secondary_info_workspace;
    const verify_status = readAndVerifyPackage(ctx, journal.sourceText(), path_buf, manifest_buf, package_info, false, .current, "RESUME");
    if (verify_status == .io) {
        // A transient storage failure must leave the durable transaction
        // untouched. Starting rollback here multiplies the failing I/O path
        // and can destroy the only last-good copy.
        return 1;
    }
    const version_match = exactSourceVersionMatchStatus(ctx, journal);
    if (version_match == .io) {
        fail(ctx, "RESUME", "source-version-read");
        return 1;
    }
    if (verify_status != .ok or !journalMatchesPackage(journal, package_info) or version_match != .match) {
        journal.phase = .rollback;
        _ = writeInactiveJournal(ctx, journal);
        return if (rollbackTransactionReverse(ctx, info, journal)) 0 else 1;
    }
    if (!assignInternalPaths(ctx, package_info, "RESUME") or !bindPackageToJournal(ctx, package_info, journal)) {
        journal.phase = .rollback;
        _ = writeInactiveJournal(ctx, journal);
        return if (rollbackTransactionReverse(ctx, info, journal)) 0 else 1;
    }
    info.* = package_info.*;

    if (journal.phase == .prepare) {
        const stage_status = streamPackagePayloadsWithTransientRetry(ctx, path_buf.ptr, info.header, manifest_buf[0..@intCast(info.header.manifest_len)], info, true, "RESUME");
        if (stage_status != .ok) {
            if (stage_status == .io or stage_status == .conflict) return packageVerifyExitCode(stage_status);
            journal.phase = .rollback;
            _ = writeInactiveJournal(ctx, journal);
            return if (rollbackTransactionReverse(ctx, info, journal)) packageVerifyExitCode(stage_status) else 1;
        }
        syncJournalFromInfo(journal, info, .stage);
        if (!writeInactiveJournal(ctx, journal)) return 1;
    }
    switch (commitTransaction(ctx, info, journal)) {
        .ok => {},
        .failed => {
            _ = rollbackTransactionReverse(ctx, info, journal);
            return 1;
        },
        .io => return 1,
        .interrupted => {
            ctx.println("SYSUPD RESUME result: INTERRUPTED phase=commit payload=1");
            return 75;
        },
    }
    journal.phase = .verify;
    if (!writeInactiveJournal(ctx, journal)) return 1;
    const committed_verify = verifyCommittedPayloads(ctx, info);
    if (committed_verify == .io) return 1;
    if (committed_verify != .match) {
        _ = rollbackTransactionReverse(ctx, info, journal);
        return 1;
    }
    switch (completeInventoryPhase(ctx, info, journal, null, "RESUME")) {
        .ok => {},
        .failed => {
            _ = rollbackTransactionReverse(ctx, info, journal);
            return 1;
        },
        .io => return 1,
        .interrupted => {
            ctx.println("SYSUPD RESUME result: INTERRUPTED phase=inventory");
            return 75;
        },
    }
    journal.phase = .applied;
    if (!writeInactiveJournal(ctx, journal)) return 1;
    if (!cleanupTransaction(ctx, info, journal)) return 1;
    ctx.println("SYSUPD RESUME result: OK");
    return 0;
}

fn statusCommand(ctx: *const r4os.r4sys.Context) i32 {
    // STATUS is the documented first remote step: it materializes the
    // update tree and reports whether the directories really exist.
    const dirs_ok = ensureUpdateDirectories(ctx);
    switch (readNewestValidBatchInto(ctx, &batch_journal_workspace)) {
        .found => last_status_has_batch = true,
        .not_found => {},
        .io => {
            fail(ctx, "STATUS", "batch-read");
            return 1;
        },
    }
    switch (readNewestValidJournalInto(ctx, &command_journal_workspace)) {
        .found => last_status_has_journal = true,
        .not_found => {
            ctx.write("SYSUPD STATUS: ");
            if (last_status_has_batch) {
                ctx.write("batch state=");
                ctx.write(batch_journal_workspace.phase.text());
                ctx.write(" batch=");
                ctx.printU64(batch_journal_workspace.batch_generation);
                ctx.write(" progress=");
                ctx.printU64(batch_journal_workspace.current_package);
                ctx.write("/");
                ctx.printU64(batch_journal_workspace.package_count);
                ctx.write(" release=");
                ctx.write(batch_journal_workspace.targetReleaseText());
                if (batch_journal_workspace.reason_len != 0) {
                    ctx.write(" reason=");
                    ctx.write(batch_journal_workspace.reasonText());
                }
            } else {
                ctx.write("idle");
            }
            ctx.write(" inbox=");
            ctx.write(default_inbox);
            ctx.write(" staged=");
            ctx.write(staged_root);
            ctx.write(" dirs=");
            ctx.println(if (dirs_ok) "ok" else "missing");
            return if (dirs_ok) 0 else 1;
        },
        .io => {
            fail(ctx, "STATUS", "journal-read");
            return 1;
        },
    }
    const journal = &command_journal_workspace;
    ctx.write("SYSUPD STATUS: journal state=");
    ctx.write(phaseName(journal.phase));
    ctx.write(" transaction=");
    ctx.printU64(journal.transaction_generation);
    ctx.write(" generation=");
    ctx.printU64(journal.journal_generation);
    ctx.write(" release=");
    ctx.write(journal.releaseText());
    ctx.write(" package-version=");
    ctx.write(journal.packageVersionText());
    ctx.write(" components=");
    ctx.printU64(journal.component_count);
    ctx.write(" priority=");
    ctx.write(if (journal.foundation) "foundation" else "normal");
    ctx.write(" applied=");
    ctx.printU64(journal.committed_count);
    ctx.write("/");
    ctx.printU64(journal.payload_count);
    ctx.write(" reboot=");
    ctx.write(if (journal.reboot) "yes" else "no");
    ctx.write(" source=");
    ctx.write(journal.sourceText());
    if (last_status_has_batch) {
        ctx.write(" batch-state=");
        ctx.write(batch_journal_workspace.phase.text());
        ctx.write(" batch=");
        ctx.printU64(batch_journal_workspace.batch_generation);
        ctx.write(" batch-progress=");
        ctx.printU64(batch_journal_workspace.current_package);
        ctx.write("/");
        ctx.printU64(batch_journal_workspace.package_count);
        if (batch_journal_workspace.reason_len != 0) {
            ctx.write(" reason=");
            ctx.write(batch_journal_workspace.reasonText());
        }
    }
    ctx.write(" dirs=");
    ctx.println(if (dirs_ok) "ok" else "missing");
    return if (dirs_ok) 0 else 1;
}

fn readAndVerifyPackage(
    ctx: *const r4os.r4sys.Context,
    path_raw: []const u8,
    path_buf: []u8,
    manifest_buf: []u8,
    info: *PackageInfo,
    stage_payloads: bool,
    requirement_policy: RequirementPolicy,
    command: []const u8,
) PackageVerifyStatus {
    const package_path = normalizePackagePath(path_buf, path_raw) orelse {
        fail(ctx, command, "bad-package-path");
        return .invalid;
    };
    if (!startsWithIgnoreCase(package_path.text, default_inbox ++ "\\")) {
        fail(ctx, command, "package-not-in-inbox");
        return .invalid;
    }
    info.source_path = package_path.text;

    var file_info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, package_path.ptr, &file_info)) {
        .found => {},
        .not_found => {
            fail(ctx, command, "package-not-found");
            return .not_found;
        },
        .io => {
            fail(ctx, command, "package-info");
            return .io;
        },
    }
    if (file_info.is_dir != 0 or file_info.size < header_size) {
        fail(ctx, command, "package-size");
        return .invalid;
    }

    var header_bytes: [header_size]u8 = undefined;
    if (!readExactAt(ctx, package_path.ptr, 0, header_bytes[0..]).ok) {
        fail(ctx, command, "header-read");
        return .io;
    }
    const header = parseHeader(header_bytes[0..]) orelse {
        fail(ctx, command, "bad-header");
        return .invalid;
    };
    if (header.manifest_len == 0 or header.manifest_len > manifest_max or header.payload_count == 0) {
        fail(ctx, command, "bad-manifest-length");
        return .invalid;
    }
    if (header.payload_count > max_package_payloads) {
        fail(ctx, command, "payload-too-many");
        return .invalid;
    }
    const manifest_end = std.math.add(u64, @as(u64, header_size), header.manifest_len) catch {
        fail(ctx, command, "package-length");
        return .invalid;
    };
    const package_end = std.math.add(u64, manifest_end, header.payload_len) catch {
        fail(ctx, command, "package-length");
        return .invalid;
    };
    if (package_end != file_info.size) {
        fail(ctx, command, "package-length");
        return .invalid;
    }
    info.header = header;
    info.package_digest = header.package_checksum;
    info.manifest_checksum = header.manifest_checksum;
    info.package_length = file_info.size;

    const manifest_len: usize = @intCast(header.manifest_len);
    if (manifest_buf.len < manifest_len) {
        fail(ctx, command, "manifest-buffer");
        return .invalid;
    }
    if (!readExactAt(ctx, package_path.ptr, header_size, manifest_buf[0..manifest_len]).ok) {
        fail(ctx, command, "manifest-read");
        return .io;
    }
    const manifest = manifest_buf[0..manifest_len];
    if (checksum(manifest) != header.manifest_checksum) {
        fail(ctx, command, "manifest-checksum");
        return .invalid;
    }
    const manifest_status = verifyManifest(ctx, manifest, header, info, command);
    if (manifest_status != .ok) return manifest_status;

    if (!validatePayloadLayout(ctx, header, info, command)) return .invalid;
    if (!validatePackageArtifactComponents(ctx, package_path.ptr, info, command)) return .invalid;
    if (requirement_policy == .current) {
        const requirement_status = validateRequirements(ctx, info, command);
        if (requirement_status != .ok) return requirement_status;
    }
    return streamPackagePayloadsWithTransientRetry(ctx, package_path.ptr, header, manifest, info, stage_payloads, command);
}

fn packageVerifyExitCode(status: PackageVerifyStatus) i32 {
    return switch (status) {
        .ok => 0,
        .incompatible => 2,
        .not_found, .invalid, .conflict, .io => 1,
    };
}

fn parseHeader(buf: []const u8) ?Header {
    if (buf.len < header_size) return null;
    if (!memEql(buf[0..4], r4u_manifest.header_magic)) return null;
    if (rU16(buf, 4) != r4u_manifest.header_version or rU16(buf, 6) != header_size) return null;
    const flags = rU32(buf, 40);
    if ((flags & ~@as(u32, 1)) != 0) return null;
    for (buf[44..header_size]) |byte| {
        if (byte != 0) return null;
    }
    return .{
        .manifest_len = rU64(buf, 8),
        .payload_len = rU64(buf, 16),
        .manifest_checksum = rU32(buf, 24),
        .payload_checksum = rU32(buf, 28),
        .package_checksum = rU32(buf, 32),
        .payload_count = rU32(buf, 36),
        .flags = flags,
    };
}

fn verifyManifest(
    ctx: *const r4os.r4sys.Context,
    manifest: []const u8,
    header: Header,
    info: *PackageInfo,
    command: []const u8,
) PackageVerifyStatus {
    var saw_magic = false;
    var saw_package = false;
    var saw_package_version = false;
    var saw_release = false;
    var saw_title = false;
    var saw_description = false;
    var saw_activation = false;
    var saw_priority = false;
    var saw_abi = false;
    var saw_payloads = false;
    var saw_components = false;
    var saw_requirements = false;
    var line_pos: usize = 0;
    while (nextLine(manifest, &line_pos)) |line_raw| {
        const line = stripTrailingCr(line_raw);
        if (line.len == 0) continue;
        if (equalsIgnoreCase(line, "R4U_MANIFEST=2")) {
            if (saw_magic) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_magic = true;
        } else if (startsWith(line, "PACKAGE=")) {
            if (saw_package) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_package = true;
            info.package = line["PACKAGE=".len..];
        } else if (startsWith(line, "PACKAGE_VERSION=")) {
            if (saw_package_version) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_package_version = true;
            info.package_version = line["PACKAGE_VERSION=".len..];
        } else if (startsWith(line, "RELEASE=")) {
            if (saw_release) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_release = true;
            info.release = line["RELEASE=".len..];
        } else if (startsWith(line, "TITLE=")) {
            if (saw_title) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_title = true;
            info.title = line["TITLE=".len..];
        } else if (startsWith(line, "DESCRIPTION=")) {
            if (saw_description) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_description = true;
            info.description = line["DESCRIPTION=".len..];
        } else if (startsWith(line, "ACTIVATION=")) {
            if (saw_activation) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_activation = true;
            info.activation = r4u_manifest.InstallMode.parse(line["ACTIVATION=".len..]) orelse {
                fail(ctx, command, "manifest-activation");
                return .invalid;
            };
        } else if (startsWith(line, "PRIORITY=")) {
            if (saw_priority) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            saw_priority = true;
            info.priority = r4u_manifest.Priority.parse(line["PRIORITY=".len..]) orelse {
                fail(ctx, command, "manifest-priority");
                return .invalid;
            };
        } else if (startsWith(line, "PAYLOADS=")) {
            if (saw_payloads) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            info.payloads_expected = parseU32(line["PAYLOADS=".len..]) orelse {
                fail(ctx, command, "manifest-payload-count");
                return .invalid;
            };
            saw_payloads = true;
        } else if (startsWith(line, "COMPONENTS=")) {
            if (saw_components) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            info.components_expected = parseU32(line["COMPONENTS=".len..]) orelse {
                fail(ctx, command, "manifest-component-count");
                return .invalid;
            };
            saw_components = true;
        } else if (startsWith(line, "REQUIRES=")) {
            if (saw_requirements) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            info.requirements_expected = parseU32(line["REQUIRES=".len..]) orelse {
                fail(ctx, command, "manifest-requirement-count");
                return .invalid;
            };
            saw_requirements = true;
        } else if (startsWith(line, "ABI;")) {
            if (saw_abi) {
                fail(ctx, command, "manifest-duplicate-field");
                return .invalid;
            }
            if (!verifyAbiLine(line)) {
                fail(ctx, command, "manifest-abi");
                return .incompatible;
            }
            saw_abi = true;
        } else if (startsWith(line, "PAYLOAD;")) {
            if (!verifyPayloadLine(ctx, line, header, info, command)) return .invalid;
        } else if (startsWith(line, "ROLLBACK;")) {
            if (!verifyRollbackLine(ctx, line, info, command)) return .invalid;
        } else if (startsWith(line, "COMPONENT;")) {
            if (!verifyComponentLine(ctx, line, info, command)) return .invalid;
            info.component_digest = checksumUpdate(info.component_digest, line);
            info.component_digest = checksumUpdate(info.component_digest, "\n");
        } else if (startsWith(line, "REQUIRE;")) {
            if (!verifyRequirementLine(ctx, line, info, command)) return .invalid;
            info.component_digest = checksumUpdate(info.component_digest, line);
            info.component_digest = checksumUpdate(info.component_digest, "\n");
        } else {
            fail(ctx, command, "manifest-line");
            return .invalid;
        }
    }

    if (!saw_magic or !saw_package or !saw_package_version or !saw_release or
        !saw_title or !saw_description or !saw_activation or !saw_priority or
        !saw_abi or !saw_payloads or !saw_components or !saw_requirements or
        !validManifestToken(info.package))
    {
        fail(ctx, command, "manifest-required-fields");
        return .invalid;
    }
    if (info.payloads_expected != header.payload_count or
        info.payload_count != header.payload_count or
        info.rollback_count != header.payload_count or
        info.components_expected != info.component_count or
        info.requirements_expected != info.requirement_count)
    {
        fail(ctx, command, "payload-count");
        return .invalid;
    }
    if (!r4u_manifest.validSemanticVersion(info.package_version) or
        !r4u_manifest.validSemanticVersion(info.release) or
        !r4u_manifest.validDisplayText(info.title, r4u_manifest.title_max_bytes) or
        !r4u_manifest.validDisplayText(info.description, r4u_manifest.description_max_bytes))
    {
        fail(ctx, command, "manifest-metadata");
        return .invalid;
    }
    var derived_class: r4u_manifest.DerivedClass = .{};
    var has_unversioned_payload = false;
    var payload_index: usize = 0;
    while (payload_index < info.payload_count) : (payload_index += 1) {
        const payload = &info.payloads[payload_index];
        if (r4u_manifest.componentKindForPayload(payload.kind, payload.targetText())) |_| {
            if (payload.component_index == null) {
                fail(ctx, command, "component-missing");
                return .invalid;
            }
        } else {
            has_unversioned_payload = true;
            if (payload.component_index != null) {
                fail(ctx, command, "component-unversioned");
                return .invalid;
            }
        }
    }
    var component_index: usize = 0;
    while (component_index < info.component_count) : (component_index += 1) {
        const component = &info.components[component_index];
        r4u_manifest.includeComponent(&derived_class, component.kind, component.targetText());
    }
    const header_restart = (header.flags & 1) != 0;
    if (derived_class.activation != info.activation or derived_class.priority != info.priority or
        header_restart != (info.activation == .restart))
    {
        fail(ctx, command, "manifest-derived-class");
        return .invalid;
    }
    if (has_unversioned_payload and info.requirement_count == 0) {
        fail(ctx, command, "unversioned-requirement");
        return .invalid;
    }
    info.reboot = info.activation == .restart;
    return .ok;
}

fn verifyPayloadLine(ctx: *const r4os.r4sys.Context, line: []const u8, header: Header, info: *PackageInfo, command: []const u8) bool {
    if (!lineFieldsKnown(line, &.{ "index", "name", "target", "kind", "size", "checksum", "offset", "abi" })) {
        fail(ctx, command, "payload-fields");
        return false;
    }
    const manifest_index = parseU32(fieldValue(line, "index=") orelse "") orelse {
        fail(ctx, command, "payload-index");
        return false;
    };
    const target = fieldValue(line, "target=") orelse {
        fail(ctx, command, "payload-target");
        return false;
    };
    const kind = fieldValue(line, "kind=") orelse {
        fail(ctx, command, "payload-kind");
        return false;
    };
    const size = parseU64(fieldValue(line, "size=") orelse "") orelse {
        fail(ctx, command, "payload-size");
        return false;
    };
    const expected_checksum = parseU32(fieldValue(line, "checksum=") orelse "") orelse {
        fail(ctx, command, "payload-checksum-field");
        return false;
    };
    const offset = parseU64(fieldValue(line, "offset=") orelse "") orelse {
        fail(ctx, command, "payload-offset");
        return false;
    };
    if (offset > header.payload_len or size > header.payload_len - offset) {
        fail(ctx, command, "payload-range");
        return false;
    }
    if (info.payload_count >= max_package_payloads) {
        fail(ctx, command, "payload-too-many");
        return false;
    }

    const index: usize = @intCast(info.payload_count);
    if (manifest_index != info.payload_count) {
        fail(ctx, command, "payload-index");
        return false;
    }
    var entry = &info.payloads[index];
    entry.* = .{};
    entry.name = fieldValue(line, "name=") orelse "";
    entry.kind = kind;
    entry.size = size;
    entry.checksum = expected_checksum;
    entry.offset = offset;
    entry.target_len = (normalizeAbsolutePath(entry.target_path[0..], target) orelse {
        fail(ctx, command, "payload-target-length");
        return false;
    }).len;
    if (!validTarget(entry.targetText())) {
        fail(ctx, command, "payload-bad-target");
        return false;
    }
    if (!kindMatchesTarget(kind, entry.targetText())) {
        fail(ctx, command, "payload-kind-target");
        return false;
    }
    var canonical_target_buffer: [max_path]u8 = undefined;
    if (r4u_manifest.canonicalInventoryTarget(canonical_target_buffer[0..], entry.targetText())) |canonical_target| {
        if (r4u_manifest.isManagedStateTarget(canonical_target)) {
            fail(ctx, command, if (endsWithIgnoreCase(canonical_target, "/VERSION.R4S"))
                "release-version-payload-forbidden"
            else
                "inventory-payload-forbidden");
            return false;
        }
    }
    entry.class = r4os.r4sys.classifySystemPath(entry.targetText());
    if (r4os.r4sys.systemReplaceNeedsReboot(entry.class)) info.needs_reboot = true;
    info.payload_count += 1;
    info.payload_bytes = std.math.add(u64, info.payload_bytes, size) catch {
        fail(ctx, command, "payload-bytes-overflow");
        return false;
    };
    return true;
}

fn verifyComponentLine(ctx: *const r4os.r4sys.Context, line: []const u8, info: *PackageInfo, command: []const u8) bool {
    if (!lineFieldsKnown(line, &.{ "payload", "kind", "name", "target", "version", "install" })) {
        fail(ctx, command, "component-fields");
        return false;
    }
    const payload_index = parseU32(fieldValue(line, "payload=") orelse "") orelse {
        fail(ctx, command, "component-payload");
        return false;
    };
    if (payload_index >= info.payload_count or info.component_count >= max_package_payloads) {
        fail(ctx, command, "component-payload");
        return false;
    }
    var payload = &info.payloads[payload_index];
    if (payload.component_index != null) {
        fail(ctx, command, "component-duplicate-payload");
        return false;
    }
    const kind = r4u_manifest.ComponentKind.parse(fieldValue(line, "kind=") orelse "") orelse {
        fail(ctx, command, "component-kind");
        return false;
    };
    const expected_kind = r4u_manifest.componentKindForPayload(payload.kind, payload.targetText()) orelse {
        fail(ctx, command, "component-unversioned");
        return false;
    };
    if (kind != expected_kind) {
        fail(ctx, command, "component-kind-payload");
        return false;
    }
    const name = fieldValue(line, "name=") orelse "";
    const version = fieldValue(line, "version=") orelse "";
    const install = r4u_manifest.InstallMode.parse(fieldValue(line, "install=") orelse "") orelse {
        fail(ctx, command, "component-install");
        return false;
    };
    if (!r4u_manifest.validToken(name, r4u_manifest.component_name_max_bytes) or
        !r4u_manifest.validSemanticVersion(version))
    {
        fail(ctx, command, "component-identity");
        return false;
    }
    const target_raw = fieldValue(line, "target=") orelse "";
    const index: usize = @intCast(info.component_count);
    var component = &info.components[index];
    component.* = .{};
    component.target_len = (r4u_manifest.canonicalInventoryTarget(component.target_path[0..], target_raw) orelse {
        fail(ctx, command, "component-target");
        return false;
    }).len;
    if (!componentTargetMatchesKind(kind, component.targetText()) or
        !std.ascii.eqlIgnoreCase(name, componentNameFromTarget(component.targetText(), kind)))
    {
        fail(ctx, command, "component-target-identity");
        return false;
    }
    var payload_target_buffer: [max_path]u8 = undefined;
    const payload_target = r4u_manifest.canonicalInventoryTarget(payload_target_buffer[0..], payload.targetText()) orelse {
        fail(ctx, command, "component-payload-target");
        return false;
    };
    if (!r4u_manifest.targetEquals(payload_target, component.targetText()) or
        install != r4u_manifest.installModeFor(kind, component.targetText()))
    {
        fail(ctx, command, "component-binding");
        return false;
    }
    var prior_index: usize = 0;
    while (prior_index < info.component_count) : (prior_index += 1) {
        const prior = &info.components[prior_index];
        if ((kind == prior.kind and std.ascii.eqlIgnoreCase(name, prior.name)) or
            r4u_manifest.targetEquals(component.targetText(), prior.targetText()))
        {
            fail(ctx, command, "component-duplicate");
            return false;
        }
    }
    const name_len = copyTextZ(component.name_storage[0..], name) orelse {
        fail(ctx, command, "component-name-length");
        return false;
    };
    const version_len = copyTextZ(component.version_storage[0..], version) orelse {
        fail(ctx, command, "component-version-length");
        return false;
    };
    component.payload_index = payload_index;
    component.kind = kind;
    component.name = component.name_storage[0..name_len];
    component.version = component.version_storage[0..version_len];
    component.install = install;
    payload.component_index = @intCast(index);
    info.component_count += 1;
    return true;
}

fn verifyRequirementLine(ctx: *const r4os.r4sys.Context, line: []const u8, info: *PackageInfo, command: []const u8) bool {
    if (!lineFieldsKnown(line, &.{ "kind", "name", "target", "version", "state" }) or info.requirement_count >= max_package_payloads) {
        fail(ctx, command, "requirement-fields");
        return false;
    }
    const kind = r4u_manifest.ComponentKind.parse(fieldValue(line, "kind=") orelse "") orelse {
        fail(ctx, command, "requirement-kind");
        return false;
    };
    const name = fieldValue(line, "name=") orelse "";
    const version = fieldValue(line, "version=") orelse "";
    const state = r4u_manifest.RequirementState.parse(fieldValue(line, "state=") orelse "") orelse {
        fail(ctx, command, "requirement-state");
        return false;
    };
    if (!r4u_manifest.validToken(name, r4u_manifest.component_name_max_bytes) or
        !r4u_manifest.validSemanticVersion(version) or
        (state == .active and kind != .kernel))
    {
        fail(ctx, command, "requirement-identity");
        return false;
    }
    const index: usize = @intCast(info.requirement_count);
    var requirement = &info.requirements[index];
    requirement.* = .{};
    requirement.target_len = (r4u_manifest.canonicalInventoryTarget(
        requirement.target_path[0..max_path],
        fieldValue(line, "target=") orelse "",
    ) orelse {
        fail(ctx, command, "requirement-target");
        return false;
    }).len;
    requirement.target_path[requirement.target_len] = 0;
    if (!componentTargetMatchesKind(kind, requirement.targetText()) or
        !std.ascii.eqlIgnoreCase(name, componentNameFromTarget(requirement.targetText(), kind)))
    {
        fail(ctx, command, "requirement-target-identity");
        return false;
    }
    var prior_index: usize = 0;
    while (prior_index < info.requirement_count) : (prior_index += 1) {
        const prior = &info.requirements[prior_index];
        if ((kind == prior.kind and std.ascii.eqlIgnoreCase(name, prior.name)) or
            r4u_manifest.targetEquals(requirement.targetText(), prior.targetText()))
        {
            fail(ctx, command, "requirement-duplicate");
            return false;
        }
    }
    requirement.kind = kind;
    requirement.name = name;
    requirement.version = version;
    requirement.state = state;
    info.requirement_count += 1;
    return true;
}

fn verifyRollbackLine(ctx: *const r4os.r4sys.Context, line: []const u8, info: *PackageInfo, command: []const u8) bool {
    if (!lineFieldsKnown(line, &.{ "target", "backup", "strategy" })) {
        fail(ctx, command, "rollback-fields");
        return false;
    }
    const target = fieldValue(line, "target=") orelse {
        fail(ctx, command, "rollback-target");
        return false;
    };
    const backup = fieldValue(line, "backup=") orelse {
        fail(ctx, command, "rollback-backup");
        return false;
    };
    var canonical_target_buf: [max_path]u8 = undefined;
    const canonical_target = normalizeAbsolutePath(canonical_target_buf[0..], target) orelse {
        fail(ctx, command, "rollback-path");
        return false;
    };
    var canonical_backup_buf: [max_path]u8 = undefined;
    const canonical_backup = normalizeAbsolutePath(canonical_backup_buf[0..], backup) orelse {
        fail(ctx, command, "rollback-path");
        return false;
    };
    if (!validTarget(canonical_target) or !validRollbackBackup(canonical_backup)) {
        fail(ctx, command, "rollback-path");
        return false;
    }
    if (info.rollback_count >= info.payload_count or
        !pathEqualsIgnoreCase(
            canonical_target,
            info.payloads[@intCast(info.rollback_count)].targetText(),
        ))
    {
        fail(ctx, command, "rollback-target-mismatch");
        return false;
    }
    if (!equalsIgnoreCase(fieldValue(line, "strategy=") orelse "", "replace")) {
        fail(ctx, command, "rollback-strategy");
        return false;
    }
    info.rollback_count += 1;
    return true;
}

fn verifyAbiLine(line: []const u8) bool {
    return lineFieldsKnown(line, &.{ "R4M0", "R4L", "R4D", "R4P", "R4XSTART", "R4U_COMPONENTS" }) and
        equalsIgnoreCase(fieldValue(line, "R4M0=") orelse "", "1") and
        equalsIgnoreCase(fieldValue(line, "R4L=") orelse "", "1") and
        equalsIgnoreCase(fieldValue(line, "R4D=") orelse "", "1") and
        equalsIgnoreCase(fieldValue(line, "R4P=") orelse "", "1") and
        equalsIgnoreCase(fieldValue(line, "R4XSTART=") orelse "", "1") and
        equalsIgnoreCase(fieldValue(line, "R4U_COMPONENTS=") orelse "", "1");
}

fn validatePayloadLayout(ctx: *const r4os.r4sys.Context, header: Header, info: *const PackageInfo, command: []const u8) bool {
    var cursor: u64 = 0;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        const entry = &info.payloads[index];
        if (entry.offset != cursor or entry.size > header.payload_len - cursor) {
            fail(ctx, command, "payload-layout");
            return false;
        }
        cursor += entry.size;
    }
    if (cursor != header.payload_len) {
        fail(ctx, command, "payload-layout");
        return false;
    }
    return true;
}

const ArtifactFileReader = struct {
    ctx: *const r4os.r4sys.Context,
    path: [*:0]const u8,
    base: u64,
    size: u64,

    pub fn readAt(self: ArtifactFileReader, offset: u64, out: []u8) bool {
        if (offset > self.size or out.len > self.size - offset) return false;
        const absolute = std.math.add(u64, self.base, offset) catch return false;
        return readExactAt(self.ctx, self.path, absolute, out).ok;
    }
};

fn validatePackageArtifactComponents(
    ctx: *const r4os.r4sys.Context,
    package_path: [*:0]const u8,
    info: *const PackageInfo,
    command: []const u8,
) bool {
    const payload_base = std.math.add(u64, header_size, info.header.manifest_len) catch {
        fail(ctx, command, "component-artifact-range");
        return false;
    };
    var index: usize = 0;
    while (index < info.component_count) : (index += 1) {
        const component = &info.components[index];
        const payload = &info.payloads[component.payload_index];
        const base = std.math.add(u64, payload_base, payload.offset) catch {
            fail(ctx, command, "component-artifact-range");
            return false;
        };
        const identity = r4u_artifact.inspect(ArtifactFileReader{
            .ctx = ctx,
            .path = package_path,
            .base = base,
            .size = payload.size,
        }, payload.size) orelse {
            fail(ctx, command, "component-artifact-metadata");
            return false;
        };
        if (identity.kind != component.kind or
            !std.ascii.eqlIgnoreCase(identity.nameText(), component.name) or
            !std.mem.eql(u8, identity.versionText(), component.version))
        {
            fail(ctx, command, "component-artifact-mismatch");
            return false;
        }
    }
    return true;
}

fn validateRequirements(
    ctx: *const r4os.r4sys.Context,
    info: *const PackageInfo,
    command: []const u8,
) PackageVerifyStatus {
    var index: usize = 0;
    while (index < info.requirement_count) : (index += 1) {
        const requirement = &info.requirements[index];
        if (requirement.state == .installed and requirementSatisfiedByOffer(info, requirement)) continue;
        if (requirement.state == .active) {
            const current = active_kernel_version[0..active_kernel_version_len];
            if (requirement.kind != .kernel or
                current.len == 0 or
                (r4u_manifest.compareVersions(current, requirement.version) orelse -1) < 0)
            {
                incompatible(ctx, command, "active-component", if (current.len == 0) "missing" else current, requirement.version);
                return .incompatible;
            }
            continue;
        }

        var file_info: r4os.abi.FileInfo = .{};
        switch (fileInfoStatus(ctx, requirement.targetPtr(), &file_info)) {
            .found => {},
            .not_found => {
                incompatible(ctx, command, "installed-component", "missing", requirement.version);
                return .incompatible;
            },
            .io => {
                fail(ctx, command, "requirement-artifact-read");
                return .io;
            },
        }
        if (file_info.is_dir != 0 or file_info.size == 0) {
            incompatible(ctx, command, "installed-component", "invalid", requirement.version);
            return .incompatible;
        }
        const identity = r4u_artifact.inspect(ArtifactFileReader{
            .ctx = ctx,
            .path = requirement.targetPtr(),
            .base = 0,
            .size = file_info.size,
        }, file_info.size) orelse {
            incompatible(ctx, command, "installed-component", "invalid", requirement.version);
            return .incompatible;
        };
        if (identity.kind != requirement.kind or
            !std.ascii.eqlIgnoreCase(identity.nameText(), requirement.name) or
            (r4u_manifest.compareVersions(identity.versionText(), requirement.version) orelse -1) < 0)
        {
            incompatible(ctx, command, "installed-component", identity.versionText(), requirement.version);
            return .incompatible;
        }
    }
    return .ok;
}

fn requirementSatisfiedByOffer(info: *const PackageInfo, requirement: *const RequirementEntry) bool {
    var index: usize = 0;
    while (index < info.component_count) : (index += 1) {
        const component = &info.components[index];
        if (component.kind == requirement.kind and
            std.ascii.eqlIgnoreCase(component.name, requirement.name) and
            r4u_manifest.targetEquals(component.targetText(), requirement.targetText()) and
            (r4u_manifest.compareVersions(component.version, requirement.version) orelse -1) >= 0)
        {
            return true;
        }
    }
    return false;
}

fn streamPackagePayloadsWithTransientRetry(
    ctx: *const r4os.r4sys.Context,
    package_path: [*:0]const u8,
    header: Header,
    manifest: []const u8,
    info: *PackageInfo,
    stage_payloads: bool,
    command: []const u8,
) PackageVerifyStatus {
    const attempt_limit = if (stage_payloads) transient_stage_attempt_limit else transient_read_attempt_limit;
    var attempt: u32 = 0;
    while (attempt < attempt_limit) : (attempt += 1) {
        info.streamed_bytes = 0;
        const status = streamPackagePayloads(ctx, package_path, header, manifest, info, stage_payloads, command);
        if (status != .io or attempt + 1 >= attempt_limit) return status;
        clearTypedReason();
        ctx.write("SYSUPD ");
        ctx.write(command);
        ctx.write(" retry: transient-stream attempt=");
        ctx.printU64(attempt + 2);
        ctx.write("/");
        ctx.printU64(attempt_limit);
        ctx.println("");
        ctx.sleepTicks(transient_io_retry_delay_ticks);
    }
    unreachable;
}

fn streamPackagePayloads(
    ctx: *const r4os.r4sys.Context,
    package_path: [*:0]const u8,
    header: Header,
    manifest: []const u8,
    info: *PackageInfo,
    stage_payloads: bool,
    command: []const u8,
) PackageVerifyStatus {
    const payload_base = std.math.add(
        u64,
        @as(u64, @intCast(header_size)),
        header.manifest_len,
    ) catch return .invalid;
    var payload_hash = checksum_seed;
    var package_hash = checksumUpdate(checksum_seed, manifest);
    var total_done: u64 = 0;
    var next_progress = progress_unit;
    const buf = stream_io_buf[0..];

    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        var entry = &info.payloads[index];
        var entry_hash = checksum_seed;
        var writer: r4os.file_stream.WriterState = undefined;
        var write_stage = false;

        if (stage_payloads) {
            switch (payloadPathState(ctx, entry.targetPtr(), entry.size, entry.checksum)) {
                .match => {
                    entry.already_applied = true;
                    // Never delete the stage after observing N at the target:
                    // during a crash-transient ownership transfer T and S can
                    // be aliases of the same FAT chain/NTFS record. The
                    // checked commit primitive recognizes and detaches that
                    // exact alias under one namespace gate. A true no-op
                    // payload never owned the generated stage at all.
                },
                .io => {
                    fail(ctx, command, "target-read");
                    return .io;
                },
                .not_found, .other => switch (payloadPathState(ctx, entry.stagePtr(), entry.size, entry.checksum)) {
                    .match => {},
                    .io => {
                        fail(ctx, command, "stage-read");
                        return .io;
                    },
                    .other => {
                        // Generation-derived 8.3 names are bounded and may
                        // collide with an orphan from an ancient transaction.
                        // Never truncate an object that is not byte-identical
                        // to this journal's payload.
                        fail(ctx, command, "stage-conflict");
                        return .conflict;
                    },
                    .not_found => {
                        if (!r4os.file_stream.begin(ctx, &writer, entry.stagePtr(), r4os.abi.file_stream_open_create)) {
                            // Begin may have completed the create but lost its
                            // completion. Settle retries the ownership-checked
                            // Abort and proves that the private path is either
                            // absent or already contains the complete payload.
                            if (!settlePrivateStageOrFail(ctx, entry, command)) return .conflict;
                            fail(ctx, command, "stage-open");
                            return .io;
                        }
                        write_stage = true;
                    },
                },
            }
        }

        var entry_done: u64 = 0;
        while (entry_done < entry.size) {
            const want_u64 = @min(@as(u64, @intCast(buf.len)), entry.size - entry_done);
            const want: usize = @intCast(want_u64);
            const absolute = std.math.add(u64, payload_base, total_done) catch return .invalid;
            if (absolute > std.math.maxInt(u32)) {
                if (write_stage and !settlePrivateStageOrFail(ctx, entry, command)) return .conflict;
                fail(ctx, command, "payload-offset");
                return .invalid;
            }
            if (!readExactAt(ctx, package_path, absolute, buf[0..want]).ok) {
                if (write_stage and !settlePrivateStageOrFail(ctx, entry, command)) return .conflict;
                fail(ctx, command, "payload-read");
                return .io;
            }
            payload_hash = checksumUpdate(payload_hash, buf[0..want]);
            package_hash = checksumUpdate(package_hash, buf[0..want]);
            entry_hash = checksumUpdate(entry_hash, buf[0..want]);
            if (write_stage and !r4os.file_stream.write(ctx, &writer, buf[0..want])) {
                if (!settlePrivateStageOrFail(ctx, entry, command)) return .conflict;
                fail(ctx, command, "stage-write");
                return .io;
            }

            entry_done += want;
            total_done += want;
            info.streamed_bytes = total_done;
            while (stage_payloads and total_done >= next_progress and next_progress <= header.payload_len) {
                printApplyProgress(ctx, total_done, header.payload_len);
                next_progress += progress_unit;
            }
        }

        if (entry_hash != entry.checksum) {
            if (write_stage and !settlePrivateStageOrFail(ctx, entry, command)) return .conflict;
            if (stage_payloads) _ = deleteStagedPayloads(ctx, info);
            fail(ctx, command, "payload-checksum");
            return .invalid;
        }
        if (write_stage) {
            if (!r4os.file_stream.finish(ctx, &writer)) {
                if (!settlePrivateStageOrFail(ctx, entry, command)) return .conflict;
                fail(ctx, command, "stage-finish");
                return .io;
            }
            info.staged_bytes += entry.size;
        }
    }

    if (total_done != header.payload_len) {
        if (stage_payloads) _ = deleteStagedPayloads(ctx, info);
        fail(ctx, command, "payload-length");
        return .invalid;
    }
    if (payload_hash != header.payload_checksum) {
        if (stage_payloads) _ = deleteStagedPayloads(ctx, info);
        fail(ctx, command, "payload-checksum");
        return .invalid;
    }
    if (package_hash != header.package_checksum) {
        if (stage_payloads) _ = deleteStagedPayloads(ctx, info);
        fail(ctx, command, "package-checksum");
        return .invalid;
    }
    return .ok;
}

fn printApplyProgress(ctx: *const r4os.r4sys.Context, done: u64, total: u64) void {
    ctx.write("SYSUPD APPLY progress: streamed_bytes=");
    ctx.printU64(done);
    ctx.write(" total=");
    ctx.printU64(total);
    ctx.println("");
}

fn deleteStagedPayloads(ctx: *const r4os.r4sys.Context, info: *const PackageInfo) PackageVerifyStatus {
    var result: PackageVerifyStatus = .ok;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        const entry = &info.payloads[index];
        if (entry.already_applied) continue;
        switch (deleteStageIfMatching(ctx, entry)) {
            .ok => {},
            .conflict => result = .conflict,
            .io => if (result != .conflict) {
                result = .io;
            },
            else => unreachable,
        }
    }
    return result;
}

fn payloadTargetMatchStatus(ctx: *const r4os.r4sys.Context, entry: *const PayloadEntry) PayloadMatchStatus {
    return payloadPathMatchStatus(ctx, entry.targetPtr(), entry.size, entry.checksum);
}

fn payloadStageMatchStatus(ctx: *const r4os.r4sys.Context, entry: *const PayloadEntry) PayloadMatchStatus {
    return payloadPathMatchStatus(ctx, entry.stagePtr(), entry.size, entry.checksum);
}

fn payloadPathMatchStatus(ctx: *const r4os.r4sys.Context, path: [*:0]const u8, size: u64, expected_checksum: u32) PayloadMatchStatus {
    return switch (payloadPathState(ctx, path, size, expected_checksum)) {
        .match => .match,
        .not_found, .other => .mismatch,
        .io => .io,
    };
}

fn payloadPathState(ctx: *const r4os.r4sys.Context, path: [*:0]const u8, size: u64, expected_checksum: u32) PayloadPathState {
    var info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, path, &info)) {
        .found => {},
        .not_found => return .not_found,
        .io => return .io,
    }
    if (info.is_dir != 0 or info.size != size) return .other;
    const actual = checksumFileRange(ctx, path, 0, size) orelse return .io;
    return if (actual == expected_checksum) .match else .other;
}

/// Releases an ambiguously failed create-only stream without ever deleting by
/// pathname alone. R4SYS Abort is identity-bound to the caller's live stream
/// slot, but its own lookup, delete or flush can fail transiently. A single
/// ignored Abort therefore used to leave a partial private stage behind; the
/// outer stream retry then reported that same partial file as stage-conflict.
///
/// Retry Abort while ownership can still be proven. Afterwards the path must
/// be absent, or contain the complete expected payload (for example when a
/// successful Finish acknowledgement was lost). A different unowned object
/// remains a hard conflict and is never truncated or deleted.
fn settlePrivateStageAfterStreamError(
    ctx: *const r4os.r4sys.Context,
    entry: *const PayloadEntry,
) PrivateStageSettleStatus {
    var attempt: u32 = 0;
    while (attempt < transient_stage_attempt_limit) : (attempt += 1) {
        const abort_result = ctx.fileStreamAbort(entry.stagePtr());
        const state = payloadPathState(ctx, entry.stagePtr(), entry.size, entry.checksum);
        switch (state) {
            .not_found => return .reusable,
            .match => {
                if (abort_result == r4os.abi.file_stream_result_ok or
                    abort_result == r4os.abi.file_stream_error_not_found)
                    return .reusable;
            },
            .other => {
                if (abort_result == r4os.abi.file_stream_error_not_found)
                    return .conflict;
            },
            .io => {},
        }
        if (attempt + 1 < transient_stage_attempt_limit)
            ctx.sleepTicks(transient_io_retry_delay_ticks);
    }
    return .io;
}

fn settlePrivateStageOrFail(
    ctx: *const r4os.r4sys.Context,
    entry: *const PayloadEntry,
    command: []const u8,
) bool {
    return switch (settlePrivateStageAfterStreamError(ctx, entry)) {
        .reusable => true,
        .conflict => blk: {
            fail(ctx, command, "stage-conflict");
            break :blk false;
        },
        .io => blk: {
            fail(ctx, command, "stage-abort");
            break :blk false;
        },
    };
}

fn deleteStageIfMatching(ctx: *const r4os.r4sys.Context, entry: *const PayloadEntry) PackageVerifyStatus {
    return deleteFileIfMatching(ctx, entry.stagePtr(), entry.size, entry.checksum);
}

fn fileInfoStatus(
    ctx: *const r4os.r4sys.Context,
    path: [*:0]const u8,
    out: *r4os.abi.FileInfo,
) FileLookupStatus {
    var attempt: u32 = 0;
    while (attempt < transient_read_attempt_limit) : (attempt += 1) {
        out.* = .{};
        const rc = ctx.fileInfoRaw(path, out);
        if (rc > 0 and out.exists != 0) return .found;
        if (attempt + 1 >= transient_read_attempt_limit)
            return if (rc < 0) .io else .not_found;
        ctx.sleepTicks(transient_io_retry_delay_ticks);
    }
    unreachable;
}

fn deleteFileIfMatching(
    ctx: *const r4os.r4sys.Context,
    path: [*:0]const u8,
    expected_size: u64,
    expected_checksum: u32,
) PackageVerifyStatus {
    return switch (ctx.fileDeleteIfMatch(path, expected_size, expected_checksum)) {
        r4os.r4sys.file_delete_if_match_result_deleted,
        r4os.r4sys.file_delete_if_match_result_not_found,
        => .ok,
        r4os.r4sys.file_delete_if_match_error_conflict => .conflict,
        else => .io,
    };
}

fn journalFromInfo(info: *const PackageInfo, phase: JournalPhase, journal: *TransactionJournal) void {
    journal.* = .{
        .transaction_generation = info.transaction_generation,
        .phase = phase,
        .package_digest = info.package_digest,
        .package_length = info.package_length,
        .manifest_checksum = info.manifest_checksum,
        .component_digest = info.component_digest,
        .component_count = info.component_count,
        .components_bound = true,
        .foundation = info.priority == .foundation,
        .package_payload_count = info.payloads_expected,
        .payload_count = info.payload_count,
        .reboot = info.reboot,
    };
    journal.source_len = copyTextZ(journal.source_path[0..], info.source_path) orelse 0;
    journal.source_version_len = copyTextZ(journal.source_version[0..], info.source_version[0..info.source_version_len]) orelse 0;
    journal.target_version_len = copyTextZ(journal.target_version[0..], info.release) orelse 0;
    journal.package_version_len = copyTextZ(journal.package_version[0..], info.package_version) orelse 0;
    syncJournalFromInfo(journal, info, phase);
}

fn syncJournalFromInfo(journal: *TransactionJournal, info: *const PackageInfo, phase: JournalPhase) void {
    journal.phase = phase;
    journal.package_payload_count = info.payloads_expected;
    journal.payload_count = info.payload_count;
    journal.committed_count = 0;
    journal.rollback_count = 0;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        const source = &info.payloads[index];
        var target = &journal.payloads[index];
        target.target_len = copyTextZ(target.target_path[0..], source.targetText()) orelse 0;
        target.stage_len = copyTextZ(target.stage_path[0..], source.stageText()) orelse 0;
        target.backup_len = copyTextZ(target.backup_path[0..], source.backupText()) orelse 0;
        target.previous_backup_len = copyTextZ(target.previous_backup_path[0..], source.previousBackupText()) orelse 0;
        target.previous_backup_known = source.previous_backup_known;
        target.previous_backup_size = source.previous_backup_size;
        target.previous_backup_checksum = source.previous_backup_checksum;
        target.size = source.size;
        target.checksum = source.checksum;
        target.target_existed = source.target_existed;
        target.old_known = source.old_known;
        target.old_size = source.old_size;
        target.old_checksum = source.old_checksum;
        target.committed = source.committed;
        target.rolled_back = source.rolled_back;
        target.replace_required = source.replace_required;
        if (source.committed) journal.committed_count += 1;
        if (source.rolled_back) journal.rollback_count += 1;
    }
    journal.component_count = info.component_count;
    journal.components_bound = true;
    index = 0;
    while (index < info.component_count) : (index += 1) {
        const source = &info.components[index];
        var target = &journal.components[index];
        target.payload_index = source.payload_index;
        target.kind = journalComponentKind(source.kind);
        target.name_len = copyTextZ(target.name[0..], source.name) orelse 0;
        target.target_len = copyTextZ(target.target[0..], source.targetText()) orelse 0;
        target.version_len = copyTextZ(target.version[0..], source.version) orelse 0;
    }
}

fn journalComponentKind(kind: r4u_manifest.ComponentKind) system_update_recovery.JournalComponentKind {
    return switch (kind) {
        .kernel => .kernel,
        .r4x => .r4x,
        .r4l => .r4l,
        .r4d => .r4d,
        .r4p => .r4p,
    };
}

fn manifestComponentKind(kind: system_update_recovery.JournalComponentKind) r4u_manifest.ComponentKind {
    return switch (kind) {
        .kernel => .kernel,
        .r4x => .r4x,
        .r4l => .r4l,
        .r4d => .r4d,
        .r4p => .r4p,
    };
}

fn commitTransaction(ctx: *const r4os.r4sys.Context, info: *PackageInfo, journal: *TransactionJournal) CommitResult {
    journal.phase = .commit;
    if (!writeInactiveJournal(ctx, journal)) return .io;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        var entry = &info.payloads[index];
        if (!entry.replace_required) {
            const target_state = payloadPathState(ctx, entry.targetPtr(), entry.size, entry.checksum);
            if (target_state == .io) {
                printApplyReplaceFailure(ctx, "target-read", entry, r4os.r4sys.system_replace_error_replace_failed);
                return .io;
            }
            if (target_state != .match) {
                printApplyReplaceFailure(ctx, "target-conflict", entry, r4os.r4sys.system_replace_error_verify_failed);
                return .failed;
            }
            entry.committed = true;
        } else {
            var checked_flags = r4os.r4sys.file_update_atomic_checked_flag_forward;
            if (entry.target_existed)
                checked_flags |= r4os.r4sys.file_update_atomic_checked_flag_target_existed;
            if (entry.old_known)
                checked_flags |= r4os.r4sys.file_update_atomic_checked_flag_old_known;
            const replace_rc = ctx.fileUpdateAtomicChecked(
                entry.targetPtr(),
                entry.stagePtr(),
                entry.backupPtr(),
                entry.size,
                entry.checksum,
                entry.old_size,
                entry.old_checksum,
                checked_flags,
            );
            if (replace_rc != r4os.r4sys.file_update_atomic_checked_result_ok) {
                printApplyReplaceFailure(ctx, "replace-checked", entry, replace_rc);
                return if (replace_rc == r4os.r4sys.file_update_atomic_checked_error_io)
                    .io
                else
                    .failed;
            }
            entry.committed = true;
        }
        syncJournalFromInfo(journal, info, .commit);
        if (!writeInactiveJournal(ctx, journal)) return .io;
        if (index == 0) {
            const fault_delete = ctx.fileDelete(test_interrupt_after_first_commit_path);
            if (fault_delete < 0) return .io;
            if (fault_delete > 0) {
                ctx.println("SYSUPD05914 fault-injection=after-first-commit journal=durable");
                return .interrupted;
            }
        }
    }
    return .ok;
}

fn verifyCommittedPayloads(ctx: *const r4os.r4sys.Context, info: *const PackageInfo) PayloadMatchStatus {
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        if (!info.payloads[index].committed) return .mismatch;
        const status = payloadTargetMatchStatus(ctx, &info.payloads[index]);
        if (status != .match) return status;
    }
    return .match;
}

const InventoryDataStatus = union(enum) {
    ready: []const u8,
    failed,
    io,
};

fn completeInventoryPhase(
    ctx: *const r4os.r4sys.Context,
    info: *PackageInfo,
    journal: *TransactionJournal,
    previous: ?*const TransactionJournal,
    command: []const u8,
) CommitResult {
    // Configuration-only packages do not change the component inventory.
    if (info.component_count == 0) return .ok;
    if (info.payload_count != info.payloads_expected or info.payload_count >= max_payloads) {
        fail(ctx, command, "inventory-payload-count");
        return .failed;
    }

    const rendered = switch (prepareInventoryData(ctx, info, command)) {
        .ready => |bytes| bytes,
        .failed => return .failed,
        .io => return .io,
    };
    const inventory_index: usize = @intCast(info.payload_count);
    var entry = &info.payloads[inventory_index];
    entry.* = .{
        .name = "MODULES.JSON",
        .kind = "inventory",
        .class = .config,
        .size = rendered.len,
        .checksum = checksum(rendered),
        .target_existed = true,
        .old_known = true,
        .old_size = inventory_source_length,
        .old_checksum = checksum(inventory_source_buf[0..inventory_source_length]),
    };
    entry.target_len = copyTextZ(entry.target_path[0..], inventory_path) orelse {
        fail(ctx, command, "inventory-target-path");
        return .failed;
    };
    entry.stage_len = buildInternal83Name(
        entry.stage_path[0..],
        entry.targetText(),
        'S',
        info.transaction_generation,
        inventory_index,
    ) orelse {
        fail(ctx, command, "inventory-stage-path");
        return .failed;
    };
    entry.backup_len = buildInternal83Name(
        entry.backup_path[0..],
        entry.targetText(),
        'B',
        info.transaction_generation,
        inventory_index,
    ) orelse {
        fail(ctx, command, "inventory-backup-path");
        return .failed;
    };
    entry.replace_required = entry.old_size != entry.size or entry.old_checksum != entry.checksum;
    entry.already_applied = !entry.replace_required;
    info.payload_count += 1;

    if (!bindPreviousBackups(ctx, info, previous)) {
        fail(ctx, command, "inventory-previous-backup-read");
        return .failed;
    }
    if (!validateTargetAliases(ctx, info, command)) return .failed;
    syncJournalFromInfo(journal, info, .inventory);
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, command, "journal-inventory");
        return .io;
    }
    return finishInventoryPhase(ctx, info, journal, rendered, command);
}

fn resumeInventoryPhase(
    ctx: *const r4os.r4sys.Context,
    info: *PackageInfo,
    journal: *TransactionJournal,
    command: []const u8,
) CommitResult {
    if (!journal.components_bound or journal.component_count == 0 or
        journal.payload_count != journal.package_payload_count + 1 or
        info.payload_count != journal.payload_count)
    {
        fail(ctx, command, "inventory-journal-shape");
        return .failed;
    }
    const rendered = switch (prepareInventoryData(ctx, info, command)) {
        .ready => |bytes| bytes,
        .failed => return .failed,
        .io => return .io,
    };
    const entry = &info.payloads[@intCast(info.payloads_expected)];
    if (!pathEqualsIgnoreCase(entry.targetText(), inventory_path) or
        entry.size != rendered.len or entry.checksum != checksum(rendered))
    {
        fail(ctx, command, "inventory-journal-content");
        return .failed;
    }
    return finishInventoryPhase(ctx, info, journal, rendered, command);
}

var inventory_source_length: usize = 0;

fn prepareInventoryData(
    ctx: *const r4os.r4sys.Context,
    info: *const PackageInfo,
    command: []const u8,
) InventoryDataStatus {
    var file_info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, inventory_path, &file_info)) {
        .found => {},
        .not_found => {
            fail(ctx, command, "inventory-not-found");
            return .failed;
        },
        .io => {
            fail(ctx, command, "inventory-info");
            return .io;
        },
    }
    if (file_info.is_dir != 0 or file_info.size == 0 or file_info.size > system_update_inventory.max_bytes) {
        fail(ctx, command, "inventory-size");
        return .failed;
    }
    inventory_source_length = @intCast(file_info.size);
    if (!readExactAt(ctx, inventory_path, 0, inventory_source_buf[0..inventory_source_length]).ok) {
        fail(ctx, command, "inventory-read");
        return .io;
    }
    if (!system_update_inventory.Inventory.parse(
        inventory_source_buf[0..inventory_source_length],
        &inventory_workspace,
    )) {
        fail(ctx, command, "inventory-invalid");
        return .failed;
    }

    var component_index: usize = 0;
    while (component_index < info.component_count) : (component_index += 1) {
        const component = &info.components[component_index];
        if (component.payload_index >= info.payloads_expected) {
            fail(ctx, command, "inventory-component-payload");
            return .failed;
        }
        const payload = &info.payloads[component.payload_index];
        var canonical_payload_buffer: [max_path]u8 = undefined;
        const canonical_payload = r4u_manifest.canonicalInventoryTarget(
            canonical_payload_buffer[0..],
            payload.targetText(),
        ) orelse {
            fail(ctx, command, "inventory-component-target");
            return .failed;
        };
        if (!r4u_manifest.targetEquals(canonical_payload, component.targetText())) {
            fail(ctx, command, "inventory-component-target");
            return .failed;
        }
        var artifact_info: r4os.abi.FileInfo = .{};
        switch (fileInfoStatus(ctx, payload.targetPtr(), &artifact_info)) {
            .found => {},
            .not_found => {
                fail(ctx, command, "inventory-artifact-missing");
                return .failed;
            },
            .io => {
                fail(ctx, command, "inventory-artifact-read");
                return .io;
            },
        }
        if (artifact_info.is_dir != 0 or artifact_info.size == 0) {
            fail(ctx, command, "inventory-artifact-invalid");
            return .failed;
        }
        const identity = r4u_artifact.inspect(ArtifactFileReader{
            .ctx = ctx,
            .path = payload.targetPtr(),
            .base = 0,
            .size = artifact_info.size,
        }, artifact_info.size) orelse {
            fail(ctx, command, "inventory-artifact-metadata");
            return .failed;
        };
        if (identity.kind != component.kind or
            !std.ascii.eqlIgnoreCase(identity.nameText(), component.name) or
            !std.mem.eql(u8, identity.versionText(), component.version))
        {
            fail(ctx, command, "inventory-artifact-mismatch");
            return .failed;
        }
        // The slices below remain stable until render. Their values are used
        // only after the installed artifact independently proved the same
        // kind, identity and exact (also downgraded) version.
        if (!inventory_workspace.upsert(.{
            .name = component.name,
            .kind = component.kind,
            .version = component.version,
            .target = component.targetText(),
        })) {
            fail(ctx, command, "inventory-upsert");
            return .failed;
        }
    }
    const rendered = inventory_workspace.render(inventory_render_buf[0..]) orelse {
        fail(ctx, command, "inventory-render");
        return .failed;
    };
    return .{ .ready = rendered };
}

fn finishInventoryPhase(
    ctx: *const r4os.r4sys.Context,
    info: *PackageInfo,
    journal: *TransactionJournal,
    rendered: []const u8,
    command: []const u8,
) CommitResult {
    const index: usize = @intCast(info.payloads_expected);
    var entry = &info.payloads[index];
    const target_state = payloadTargetMatchStatus(ctx, entry);
    if (target_state == .io) {
        fail(ctx, command, "inventory-target-read");
        return .io;
    }
    if (!entry.committed and target_state != .match) {
        const stage_state = payloadPathState(ctx, entry.stagePtr(), entry.size, entry.checksum);
        switch (stage_state) {
            .match => {},
            .not_found => {
                var writer: r4os.file_stream.WriterState = undefined;
                if (!r4os.file_stream.begin(ctx, &writer, entry.stagePtr(), r4os.abi.file_stream_open_create)) {
                    if (!settlePrivateStageOrFail(ctx, entry, command)) return .failed;
                    fail(ctx, command, "inventory-stage-begin");
                    return .io;
                }
                if (!r4os.file_stream.write(ctx, &writer, rendered) or !r4os.file_stream.finish(ctx, &writer)) {
                    if (!settlePrivateStageOrFail(ctx, entry, command)) return .failed;
                    fail(ctx, command, "inventory-stage-write");
                    return .io;
                }
                info.staged_bytes += rendered.len;
            },
            .other => {
                fail(ctx, command, "inventory-stage-conflict");
                return .failed;
            },
            .io => {
                fail(ctx, command, "inventory-stage-read");
                return .io;
            },
        }
    }

    const before_fault = ctx.fileDelete(test_interrupt_before_inventory_commit_path);
    if (before_fault < 0) return .io;
    if (before_fault > 0) {
        ctx.println("SYSUPD06312 fault-injection=before-inventory-commit journal=durable");
        return .interrupted;
    }

    const commit_result = commitInventoryPayload(ctx, entry);
    if (commit_result != .ok) return commit_result;
    syncJournalFromInfo(journal, info, .inventory);
    if (!writeInactiveJournal(ctx, journal)) {
        fail(ctx, command, "journal-inventory-commit");
        return .io;
    }

    const after_fault = ctx.fileDelete(test_interrupt_after_inventory_commit_path);
    if (after_fault < 0) return .io;
    if (after_fault > 0) {
        ctx.println("SYSUPD06312 fault-injection=after-inventory-commit journal=durable");
        return .interrupted;
    }
    const verify = payloadTargetMatchStatus(ctx, entry);
    if (verify == .io) {
        fail(ctx, command, "inventory-target-read");
        return .io;
    }
    if (verify != .match) {
        fail(ctx, command, "inventory-target-verify");
        return .failed;
    }
    return .ok;
}

fn commitInventoryPayload(ctx: *const r4os.r4sys.Context, entry: *PayloadEntry) CommitResult {
    switch (payloadTargetMatchStatus(ctx, entry)) {
        .match => {
            entry.committed = true;
            return .ok;
        },
        .io => return .io,
        .mismatch => {},
    }
    if (!entry.replace_required) return .failed;

    const old_state = if (entry.target_existed and entry.old_known)
        payloadPathState(ctx, entry.targetPtr(), entry.old_size, entry.old_checksum)
    else
        payloadPathState(ctx, entry.targetPtr(), 0, 0);
    if (entry.target_existed) {
        if (!entry.old_known or old_state != .match) return if (old_state == .io) .io else .failed;
    } else if (old_state != .not_found) {
        return if (old_state == .io) .io else .failed;
    }
    const stage_state = payloadPathState(ctx, entry.stagePtr(), entry.size, entry.checksum);
    if (stage_state != .match) return if (stage_state == .io) .io else .failed;

    var checked_flags = r4os.r4sys.file_update_atomic_checked_flag_forward;
    if (entry.target_existed) checked_flags |= r4os.r4sys.file_update_atomic_checked_flag_target_existed;
    if (entry.old_known) checked_flags |= r4os.r4sys.file_update_atomic_checked_flag_old_known;
    const replace_rc = ctx.fileUpdateAtomicChecked(
        entry.targetPtr(),
        entry.stagePtr(),
        entry.backupPtr(),
        entry.size,
        entry.checksum,
        entry.old_size,
        entry.old_checksum,
        checked_flags,
    );
    if (replace_rc != r4os.r4sys.file_update_atomic_checked_result_ok) {
        printApplyReplaceFailure(ctx, "inventory-replace", entry, replace_rc);
        return if (replace_rc == r4os.r4sys.file_update_atomic_checked_error_io) .io else .failed;
    }
    entry.committed = true;
    return .ok;
}

const SysUpdRecoveryIo = struct {
    ctx: *const r4os.r4sys.Context,

    pub fn pathState(
        self: *const SysUpdRecoveryIo,
        path: []const u8,
        expected_size: u64,
        expected_checksum: u32,
    ) system_update_recovery.PathState {
        return switch (payloadPathState(
            self.ctx,
            recoveryPathPtr(path),
            expected_size,
            expected_checksum,
        )) {
            .match => .match,
            .not_found => .not_found,
            .other => .other,
            .io => .io,
        };
    }

    pub fn presence(
        self: *const SysUpdRecoveryIo,
        path: []const u8,
    ) system_update_recovery.PresenceState {
        var info: r4os.abi.FileInfo = .{};
        return switch (fileInfoStatus(self.ctx, recoveryPathPtr(path), &info)) {
            .found => if (info.is_dir == 0) .file else .other,
            .not_found => .not_found,
            .io => .io,
        };
    }

    pub fn rollbackPayload(
        self: *const SysUpdRecoveryIo,
        entry: *const JournalPayload,
    ) system_update_recovery.MutationStatus {
        var flags = r4os.r4sys.file_update_atomic_checked_flag_rollback;
        if (entry.target_existed)
            flags |= r4os.r4sys.file_update_atomic_checked_flag_target_existed;
        if (entry.old_known)
            flags |= r4os.r4sys.file_update_atomic_checked_flag_old_known;
        const rc = self.ctx.fileUpdateAtomicChecked(
            entry.targetPtr(),
            entry.stagePtr(),
            entry.backupPtr(),
            entry.size,
            entry.checksum,
            entry.old_size,
            entry.old_checksum,
            flags,
        );
        if (rc == r4os.r4sys.file_update_atomic_checked_result_ok) return .ok;
        return if (rc == r4os.r4sys.file_update_atomic_checked_error_io)
            .io
        else
            .conflict;
    }

    pub fn commitPayload(
        self: *const SysUpdRecoveryIo,
        entry: *const JournalPayload,
    ) system_update_recovery.MutationStatus {
        if (!entry.replace_required) {
            return switch (payloadPathState(
                self.ctx,
                entry.targetPtr(),
                entry.size,
                entry.checksum,
            )) {
                .match => .ok,
                .not_found, .other => .conflict,
                .io => .io,
            };
        }
        var flags = r4os.r4sys.file_update_atomic_checked_flag_forward;
        if (entry.target_existed)
            flags |= r4os.r4sys.file_update_atomic_checked_flag_target_existed;
        if (entry.old_known)
            flags |= r4os.r4sys.file_update_atomic_checked_flag_old_known;
        const rc = self.ctx.fileUpdateAtomicChecked(
            entry.targetPtr(),
            entry.stagePtr(),
            entry.backupPtr(),
            entry.size,
            entry.checksum,
            entry.old_size,
            entry.old_checksum,
            flags,
        );
        if (rc == r4os.r4sys.file_update_atomic_checked_result_ok) return .ok;
        return if (rc == r4os.r4sys.file_update_atomic_checked_error_io)
            .io
        else
            .conflict;
    }

    pub fn deleteIfMatch(
        self: *const SysUpdRecoveryIo,
        path: []const u8,
        expected_size: u64,
        expected_checksum: u32,
    ) system_update_recovery.MutationStatus {
        return switch (deleteFileIfMatching(
            self.ctx,
            recoveryPathPtr(path),
            expected_size,
            expected_checksum,
        )) {
            .ok => .ok,
            .conflict => .conflict,
            .io => .io,
            else => unreachable,
        };
    }

    /// Per-payload checked cleanup under ONE filesystem gate (0.60.23).
    ///
    /// Target, stage, current backup and previous backup are verified and
    /// acted upon by a single kernel operation, so nothing can mutate between
    /// the check and the deletion it authorizes.  An inherited backup without
    /// a recorded fingerprint is deliberately KEPT: one extra last-good file
    /// is safe, deleting an unidentifiable object is not.
    pub fn cleanupPayload(
        self: *const SysUpdRecoveryIo,
        entry: *const system_update_recovery.JournalPayload,
    ) system_update_recovery.MutationStatus {
        var flags: u32 = 0;
        if (entry.target_existed) flags |= r4os.r4sys.file_update_cleanup_checked_flag_target_existed;
        if (entry.old_known) flags |= r4os.r4sys.file_update_cleanup_checked_flag_old_known;
        if (entry.previous_backup_known) flags |= r4os.r4sys.file_update_cleanup_checked_flag_previous_known;

        // An empty previous path means "nothing inherited to rotate"; the
        // same-name case is not a rotation either.  The empty case uses an
        // explicit sentinel literal - a zero-length slice has no zero
        // terminator to point at.
        const empty_path: [*:0]const u8 = "";
        const rotate_previous = entry.previous_backup_len != 0 and
            !system_update_recovery.pathEqualsIgnoreCase(entry.previousBackupText(), entry.backupText());
        const previous_ptr: [*:0]const u8 = if (rotate_previous)
            recoveryPathPtr(entry.previousBackupText())
        else
            empty_path;

        const rc = self.ctx.fileUpdateCleanupChecked(
            recoveryPathPtr(entry.targetText()),
            recoveryPathPtr(entry.stageText()),
            recoveryPathPtr(entry.backupText()),
            previous_ptr,
            entry.size,
            entry.checksum,
            entry.old_size,
            entry.old_checksum,
            entry.previous_backup_size,
            entry.previous_backup_checksum,
            flags,
        );
        return switch (rc) {
            r4os.r4sys.file_update_cleanup_checked_result_ok => .ok,
            r4os.r4sys.file_update_cleanup_checked_error_conflict => .conflict,
            else => .io,
        };
    }

    pub fn persist(
        self: *const SysUpdRecoveryIo,
        journal: *TransactionJournal,
    ) bool {
        return writeInactiveJournal(self.ctx, journal);
    }
};

fn recoveryPathPtr(path: []const u8) [*:0]const u8 {
    // Every shared-core path slice points into a zero-filled sentinel-backed
    // journal field.  Keeping this conversion in the adapter makes that
    // lifetime contract explicit at the R4SYS ABI boundary.
    return @ptrCast(path.ptr);
}

fn rollbackTransactionReverse(ctx: *const r4os.r4sys.Context, info: *PackageInfo, journal: *TransactionJournal) bool {
    // PackageInfo owns the forward/package view; the durable journal is the
    // sole replay truth.  Synchronize once, then let both R4X and boot recovery
    // execute the identical identity-bound state machine.
    syncJournalFromInfo(journal, info, .rollback);
    var io = SysUpdRecoveryIo{ .ctx = ctx };
    const status = system_update_recovery.rollbackToTerminal(&io, journal);
    if (status != .ok) {
        fail(ctx, "ROLLBACK", system_update_recovery.replayStatusName(status));
        return false;
    }
    return true;
}

fn cleanupTransaction(ctx: *const r4os.r4sys.Context, info: *const PackageInfo, journal: *TransactionJournal) bool {
    syncJournalFromInfo(journal, info, .applied);
    var io = SysUpdRecoveryIo{ .ctx = ctx };
    const status = system_update_recovery.cleanupToTerminal(&io, journal);
    if (status != .ok) {
        fail(ctx, "CLEANUP", system_update_recovery.replayStatusName(status));
        return false;
    }
    return true;
}

fn bindPreviousBackups(ctx: *const r4os.r4sys.Context, info: *PackageInfo, previous: ?*const TransactionJournal) bool {
    const prior = previous orelse return true;
    if (!phaseTerminal(prior.phase)) return true;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        var entry = &info.payloads[index];
        var old_index: usize = 0;
        while (old_index < prior.payload_count) : (old_index += 1) {
            const stored = &prior.payloads[old_index];
            if (!pathEqualsIgnoreCase(entry.targetText(), stored.target_path[0..stored.target_len])) continue;
            // A successful replacement of an existing target creates the
            // newest last-good object at `backup`.  Every other terminal
            // shape (no-op, create-only, or rolled back) merely inherits the
            // previous generation's retained backup.
            const produced_backup = prior.phase == .cleanup and
                stored.replace_required and stored.target_existed;
            const old_backup = if (produced_backup)
                stored.backup_path[0..stored.backup_len]
            else
                stored.previous_backup_path[0..stored.previous_backup_len];
            if (old_backup.len != 0) {
                entry.previous_backup_len = copyTextZ(entry.previous_backup_path[0..], old_backup) orelse return false;
                if (produced_backup) {
                    entry.previous_backup_known = stored.old_known;
                    entry.previous_backup_size = stored.old_size;
                    entry.previous_backup_checksum = stored.old_checksum;
                } else {
                    entry.previous_backup_known = stored.previous_backup_known;
                    entry.previous_backup_size = stored.previous_backup_size;
                    entry.previous_backup_checksum = stored.previous_backup_checksum;
                }
                if (!entry.previous_backup_known) {
                    var previous_info: r4os.abi.FileInfo = .{};
                    switch (fileInfoStatus(ctx, entry.previousBackupPtr(), &previous_info)) {
                        .found => {
                            if (previous_info.is_dir != 0) return false;
                            entry.previous_backup_checksum = checksumFileRange(
                                ctx,
                                entry.previousBackupPtr(),
                                0,
                                previous_info.size,
                            ) orelse return false;
                            entry.previous_backup_size = previous_info.size;
                            entry.previous_backup_known = true;
                        },
                        .not_found => entry.previous_backup_len = 0,
                        .io => return false,
                    }
                }
            }
            break;
        }
    }
    return true;
}

fn acquireUpdateLock(ctx: *const r4os.r4sys.Context, allow_resume: bool) UpdateLockStatus {
    if (!allow_resume) {
        switch (readNewestValidJournalInto(ctx, &newest_journal_workspace)) {
            .found => {
                if (!phaseTerminal(newest_journal_workspace.phase)) return .busy;
            },
            .not_found => {},
            .io => return .io,
        }
    }
    const open_flags = r4os.abi.file_stream_open_create |
        r4os.r4sys.file_stream_open_lease;
    const begin_rc = ctx.fileStreamBegin(update_lock_path, open_flags);
    if (begin_rc != r4os.abi.file_stream_result_ok)
        return if (begin_rc == r4os.abi.file_stream_error_exists) .busy else .io;
    var acquired = false;
    defer if (!acquired) {
        _ = ctx.fileStreamAbort(update_lock_path);
    };
    const lock_body = "SYSUPD_LOCK=1\n";
    if (ctx.fileStreamWrite(update_lock_path, 0, lock_body, 0) != @as(i32, @intCast(lock_body.len)))
        return .io;
    if (ctx.fileStreamFinish(
        update_lock_path,
        lock_body.len,
        r4os.r4sys.file_stream_finish_keep_ownership,
    ) != r4os.abi.file_stream_result_ok)
        return .io;
    acquired = true;
    return .acquired;
}

fn releaseUpdateLock(ctx: *const r4os.r4sys.Context) void {
    _ = ctx.fileStreamAbort(update_lock_path);
}

fn phaseTerminal(phase: JournalPhase) bool {
    return system_update_recovery.phaseTerminal(phase);
}

fn exactSourceVersionMatchStatus(ctx: *const r4os.r4sys.Context, journal: *const TransactionJournal) VersionMatchStatus {
    var current_buf: [32]u8 = .{0} ** 32;
    const current = switch (readCurrentVersionStatus(ctx, current_buf[0..])) {
        .found => |version| version,
        .not_found, .invalid => return .mismatch,
        .io => return .io,
    };
    if (equalsIgnoreCase(current, journal.sourceVersionText())) return .match;
    return if (journal.component_count == 0 and journal.manifest_checksum == 0 and
        journal.committed_count == journal.payload_count and
        equalsIgnoreCase(current, journal.targetVersionText()))
        .match
    else
        .mismatch;
}

fn journalMatchesPackage(journal: *const TransactionJournal, info: *const PackageInfo) bool {
    return journal.package_digest == info.package_digest and
        journal.package_length == info.package_length and
        journal.manifest_checksum == info.manifest_checksum and
        journal.component_digest == info.component_digest and
        journal.component_count == info.component_count and
        journal.foundation == (info.priority == .foundation) and
        equalsIgnoreCase(journal.sourceText(), info.source_path) and
        equalsIgnoreCase(journal.releaseText(), info.release) and
        equalsIgnoreCase(journal.packageVersionText(), info.package_version) and
        journal.package_payload_count == info.payload_count;
}

fn bindPackageToJournal(ctx: *const r4os.r4sys.Context, info: *PackageInfo, journal: *const TransactionJournal) bool {
    if (info.payload_count != journal.package_payload_count) return false;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        var entry = &info.payloads[index];
        const stored = &journal.payloads[index];
        if (!pathEqualsIgnoreCase(entry.targetText(), stored.target_path[0..stored.target_len]) or
            !pathEqualsIgnoreCase(entry.stageText(), stored.stage_path[0..stored.stage_len]) or
            !pathEqualsIgnoreCase(entry.backupText(), stored.backup_path[0..stored.backup_len]) or
            entry.size != stored.size or entry.checksum != stored.checksum)
        {
            fail(ctx, "RESUME", "journal-payload-mismatch");
            return false;
        }
        entry.target_existed = stored.target_existed;
        entry.old_known = stored.old_known;
        entry.old_size = stored.old_size;
        entry.old_checksum = stored.old_checksum;
        entry.committed = stored.committed;
        entry.rolled_back = stored.rolled_back;
        entry.replace_required = stored.replace_required;
        entry.previous_backup_len = copyTextZ(entry.previous_backup_path[0..], stored.previous_backup_path[0..stored.previous_backup_len]) orelse 0;
        entry.previous_backup_known = stored.previous_backup_known;
        entry.previous_backup_size = stored.previous_backup_size;
        entry.previous_backup_checksum = stored.previous_backup_checksum;
    }
    return true;
}

fn infoFromJournal(journal: *const TransactionJournal, info: *PackageInfo) void {
    info.* = .{
        .source_path = journal.sourceText(),
        .release = journal.releaseText(),
        .package_version = journal.packageVersionText(),
        .payload_count = journal.payload_count,
        .payloads_expected = journal.package_payload_count,
        .component_count = journal.component_count,
        .components_expected = journal.component_count,
        .rollback_count = journal.payload_count,
        .package_digest = journal.package_digest,
        .manifest_checksum = journal.manifest_checksum,
        .component_digest = journal.component_digest,
        .package_length = journal.package_length,
        .transaction_generation = journal.transaction_generation,
        .reboot = journal.reboot,
        .activation = if (journal.reboot) .restart else .live,
        .priority = if (journal.foundation) .foundation else .normal,
    };
    info.source_version_len = copyTextZ(info.source_version[0..], journal.sourceVersionText()) orelse 0;
    if (journal.components_bound) {
        var component_index: usize = 0;
        while (component_index < journal.component_count) : (component_index += 1) {
            const stored = &journal.components[component_index];
            var component = &info.components[component_index];
            component.payload_index = stored.payload_index;
            component.kind = manifestComponentKind(stored.kind);
            const name_len = copyTextZ(component.name_storage[0..], stored.nameText()) orelse 0;
            component.name = component.name_storage[0..name_len];
            component.target_len = copyTypedText(component.target_path[0..], stored.targetText());
            const version_len = copyTextZ(component.version_storage[0..], stored.versionText()) orelse 0;
            component.version = component.version_storage[0..version_len];
        }
    }
    var index: usize = 0;
    while (index < journal.payload_count) : (index += 1) {
        const stored = &journal.payloads[index];
        var entry = &info.payloads[index];
        entry.target_len = copyTextZ(entry.target_path[0..], stored.target_path[0..stored.target_len]) orelse 0;
        entry.stage_len = copyTextZ(entry.stage_path[0..], stored.stage_path[0..stored.stage_len]) orelse 0;
        entry.backup_len = copyTextZ(entry.backup_path[0..], stored.backup_path[0..stored.backup_len]) orelse 0;
        entry.previous_backup_len = copyTextZ(entry.previous_backup_path[0..], stored.previous_backup_path[0..stored.previous_backup_len]) orelse 0;
        entry.previous_backup_known = stored.previous_backup_known;
        entry.previous_backup_size = stored.previous_backup_size;
        entry.previous_backup_checksum = stored.previous_backup_checksum;
        entry.size = stored.size;
        entry.checksum = stored.checksum;
        entry.class = r4os.r4sys.classifySystemPath(entry.targetText());
        entry.target_existed = stored.target_existed;
        entry.old_known = stored.old_known;
        entry.old_size = stored.old_size;
        entry.old_checksum = stored.old_checksum;
        entry.committed = stored.committed;
        entry.rolled_back = stored.rolled_back;
        entry.replace_required = stored.replace_required;
    }
}

fn readNewestValidJournalInto(ctx: *const r4os.r4sys.Context, out: *TransactionJournal) JournalLookupStatus {
    out.* = .{};
    var lengths: [journal_paths.len]usize = .{0} ** journal_paths.len;
    var present: [journal_paths.len]bool = .{false} ** journal_paths.len;
    var valid: [journal_paths.len]bool = .{false} ** journal_paths.len;
    var generations: [journal_paths.len]u64 = .{0} ** journal_paths.len;
    var slot: usize = 0;
    while (slot < journal_paths.len) : (slot += 1) {
        var info: r4os.abi.FileInfo = .{};
        switch (fileInfoStatus(ctx, journal_paths[slot], &info)) {
            .found => {},
            .not_found => continue,
            .io => return .io,
        }
        present[slot] = true;
        if (info.is_dir != 0 or info.size == 0 or info.size > journal_max) {
            continue;
        }
        const expected_len: usize = @intCast(info.size);
        if (!readExactAt(ctx, journal_paths[slot], 0, journal_read_buffers[slot][0..expected_len]).ok) return .io;
        lengths[slot] = expected_len;
        if (!parseJournalInto(
            journal_read_buffers[slot][0..expected_len],
            @intCast(slot),
            out,
        )) {
            continue;
        }
        valid[slot] = true;
        generations[slot] = out.journal_generation;
    }
    const selected: usize = switch (system_update_recovery.selectNewestSlot(
        present,
        valid,
        generations,
    )) {
        .selected => |selected_slot| selected_slot,
        .not_found => {
            out.* = .{};
            return .not_found;
        },
        .invalid => {
            out.* = .{};
            return .io;
        },
    };
    // The scan deliberately reuses `out` as its parse scratch.  Reparse the
    // selected slot once so no third ~130-KB TransactionJournal has to live
    // in every short-lived SYSUPD process image.
    if (!parseJournalInto(
        journal_read_buffers[selected][0..lengths[selected]],
        @intCast(selected),
        out,
    )) return .io;
    return .found;
}

fn readNewestValidBatchInto(
    ctx: *const r4os.r4sys.Context,
    out: *system_update_batch.BatchJournal,
) JournalLookupStatus {
    out.* = .{};
    var lengths: [batch_journal_paths.len]usize = .{0} ** batch_journal_paths.len;
    var present: [batch_journal_paths.len]bool = .{false} ** batch_journal_paths.len;
    var valid: [batch_journal_paths.len]bool = .{false} ** batch_journal_paths.len;
    var generations: [batch_journal_paths.len]u64 = .{0} ** batch_journal_paths.len;
    var slot: usize = 0;
    while (slot < batch_journal_paths.len) : (slot += 1) {
        var info: r4os.abi.FileInfo = .{};
        switch (fileInfoStatus(ctx, batch_journal_paths[slot], &info)) {
            .found => {},
            .not_found => continue,
            .io => return .io,
        }
        present[slot] = true;
        if (info.is_dir != 0 or info.size == 0 or info.size > system_update_batch.journal_max) continue;
        const expected_len: usize = @intCast(info.size);
        if (!readExactAt(ctx, batch_journal_paths[slot], 0, batch_read_buffers[slot][0..expected_len]).ok) return .io;
        lengths[slot] = expected_len;
        if (!system_update_batch.parseJournalInto(
            batch_read_buffers[slot][0..expected_len],
            @intCast(slot),
            out,
        )) continue;
        valid[slot] = true;
        generations[slot] = out.journal_generation;
    }
    const selected: usize = switch (system_update_batch.selectNewestSlot(present, valid, generations)) {
        .selected => |selected_slot| selected_slot,
        .not_found => {
            out.* = .{};
            return .not_found;
        },
        .invalid => {
            out.* = .{};
            return .io;
        },
    };
    if (!system_update_batch.parseJournalInto(
        batch_read_buffers[selected][0..lengths[selected]],
        @intCast(selected),
        out,
    )) return .io;
    return .found;
}

fn writeInactiveBatchJournal(
    ctx: *const r4os.r4sys.Context,
    journal: *system_update_batch.BatchJournal,
) bool {
    if (!ensureUpdateDirectories(ctx)) return false;
    const previous_slot = journal.slot;
    const previous_generation = journal.journal_generation;
    const previous_valid = journal.valid;
    var durable = false;
    defer if (!durable) {
        journal.slot = previous_slot;
        journal.journal_generation = previous_generation;
        journal.valid = previous_valid;
    };
    var slot: u8 = 0;
    var next_generation: u64 = 1;
    switch (readNewestValidBatchInto(ctx, &batch_verify_journal_workspace)) {
        .found => {
            if (batch_verify_journal_workspace.journal_generation == std.math.maxInt(u64)) return false;
            slot = 1 - batch_verify_journal_workspace.slot;
            next_generation = batch_verify_journal_workspace.journal_generation + 1;
        },
        .not_found => {},
        .io => return false,
    }
    journal.slot = slot;
    journal.journal_generation = next_generation;
    journal.valid = true;
    const encoded = system_update_batch.serializeJournal(journal, batch_write_buffer[0..]) orelse return false;
    const len = encoded.len;
    _ = ctx.fileWrite(batch_journal_paths[slot], encoded);
    if (!readExactAt(ctx, batch_journal_paths[slot], 0, batch_read_buffers[slot][0..len]).ok or
        !std.mem.eql(u8, encoded, batch_read_buffers[slot][0..len]))
    {
        return false;
    }
    if (!system_update_batch.parseJournalInto(
        batch_read_buffers[slot][0..len],
        slot,
        &batch_verify_journal_workspace,
    )) return false;
    durable = batch_verify_journal_workspace.batch_generation == journal.batch_generation and
        batch_verify_journal_workspace.journal_generation == journal.journal_generation and
        batch_verify_journal_workspace.phase == journal.phase and
        batch_verify_journal_workspace.package_count == journal.package_count;
    return durable;
}

fn writeInactiveJournal(ctx: *const r4os.r4sys.Context, journal: *TransactionJournal) bool {
    if (!ensureUpdateDirectories(ctx)) return false;
    const previous_slot = journal.slot;
    const previous_generation = journal.journal_generation;
    const previous_valid = journal.valid;
    var durable = false;
    defer if (!durable) {
        journal.slot = previous_slot;
        journal.journal_generation = previous_generation;
        journal.valid = previous_valid;
    };
    var slot: u8 = 0;
    var next_generation: u64 = 1;
    switch (readNewestValidJournalInto(ctx, &newest_journal_workspace)) {
        .found => {
            if (newest_journal_workspace.journal_generation == std.math.maxInt(u64)) return false;
            slot = 1 - newest_journal_workspace.slot;
            next_generation = newest_journal_workspace.journal_generation + 1;
        },
        .not_found => {},
        .io => return false,
    }
    journal.slot = slot;
    journal.journal_generation = next_generation;
    journal.valid = true;

    const out = journal_write_buffer[0..];
    const encoded = system_update_recovery.serializeJournal(journal, out) orelse return false;
    const len = encoded.len;

    const target_path = journal_paths[slot];
    // A negative/short completion can still describe a durable write. Read
    // the inactive slot back once and accept only the exact intended,
    // checksummed generation; never overwrite the other slot on ambiguity.
    _ = ctx.fileWrite(target_path, encoded);
    if (!readExactAt(ctx, target_path, 0, journal_read_buffers[slot][0..len]).ok) return false;
    if (!std.mem.eql(u8, out[0..len], journal_read_buffers[slot][0..len])) return false;
    const expected_transaction_generation = journal.transaction_generation;
    const expected_journal_generation = journal.journal_generation;
    const expected_phase = journal.phase;
    if (!parseJournalInto(journal_read_buffers[slot][0..len], slot, &newest_journal_workspace)) return false;
    durable = newest_journal_workspace.transaction_generation == expected_transaction_generation and
        newest_journal_workspace.journal_generation == expected_journal_generation and
        newest_journal_workspace.phase == expected_phase;
    return durable;
}

fn parseJournalInto(data: []const u8, slot: u8, journal: *TransactionJournal) bool {
    return system_update_recovery.parseJournalInto(data, slot, journal);
}

fn phaseName(phase: JournalPhase) []const u8 {
    return system_update_recovery.phaseName(phase);
}

/// Creates the UPDATE/INBOX/STAGED tree and verifies it really exists.
/// dirCreate alone is not enough: its 0 return covers both "already
/// there" and a failed create, and a fresh system image ships without
/// the UPDATE tree, so the first SFTP upload had no inbox (real Lenovo
/// finding).  Every command entry point runs this ensure.
fn ensureUpdateDirectories(ctx: *const r4os.r4sys.Context) bool {
    return ensureDirectory(ctx, update_root) and
        ensureDirectory(ctx, default_inbox) and
        ensureDirectory(ctx, staged_root);
}

fn ensureDirectory(ctx: *const r4os.r4sys.Context, path: [:0]const u8) bool {
    if (ctx.dirCreate(path) < 0) return false;
    var info: r4os.abi.FileInfo = .{};
    return fileInfoStatus(ctx, path, &info) == .found and info.is_dir != 0;
}

fn printApplyReplaceFailure(ctx: *const r4os.r4sys.Context, phase: []const u8, entry: *const PayloadEntry, result: i32) void {
    ctx.write("SYSUPD APPLY result: FAILED reason=");
    ctx.write(phase);
    ctx.write("-");
    ctx.write(r4os.r4sys.fileUpdateAtomicCheckedResultName(result));
    ctx.write(" target=");
    ctx.println(entry.targetText());
}

fn validTarget(value: []const u8) bool {
    if (value.len == 0 or value.len >= max_path) return false;
    if (std.mem.indexOf(u8, value, "..") != null) return false;
    for (value) |ch| {
        if (ch < ' ' or ch == ';' or ch == '|') return false;
    }
    return r4os.r4sys.classifySystemPath(value) != .unknown;
}

fn validManifestToken(value: []const u8) bool {
    if (value.len == 0 or value.len > 48) return false;
    for (value) |ch| {
        if (ch <= ' ' or ch >= 0x7F or ch == ';' or ch == '|' or ch == '=') return false;
    }
    return true;
}

fn componentTargetMatchesKind(kind: r4u_manifest.ComponentKind, target: []const u8) bool {
    return switch (kind) {
        .kernel => r4u_manifest.targetEquals(target, "/boot/r4os.elf"),
        .r4l => startsWithIgnoreCase(target, "/R4OS/LIBS/") and endsWithIgnoreCase(target, ".R4L"),
        .r4d => startsWithIgnoreCase(target, "/R4OS/DRIVERS/") and endsWithIgnoreCase(target, ".R4D"),
        .r4p => startsWithIgnoreCase(target, "/R4OS/PROTOCOLS/") and endsWithIgnoreCase(target, ".R4P"),
        .r4x => target.len > 1 and target[0] == '/' and endsWithIgnoreCase(target, ".R4X"),
    };
}

fn componentNameFromTarget(target: []const u8, kind: r4u_manifest.ComponentKind) []const u8 {
    if (kind == .kernel) return "KERNEL";
    const name = baseName(target);
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return name;
    return name[0..dot];
}

fn lineFieldsKnown(line: []const u8, allowed: []const []const u8) bool {
    var seen: [16]bool = .{false} ** 16;
    if (allowed.len > seen.len) return false;
    var split = std.mem.splitScalar(u8, line, ';');
    _ = split.next() orelse return false;
    var count: usize = 0;
    while (split.next()) |field| {
        const equals = std.mem.indexOfScalar(u8, field, '=') orelse return false;
        const key = field[0..equals];
        var found: ?usize = null;
        for (allowed, 0..) |candidate, index| {
            if (std.mem.eql(u8, key, candidate)) {
                found = index;
                break;
            }
        }
        const index = found orelse return false;
        if (seen[index]) return false;
        seen[index] = true;
        count += 1;
    }
    return count == allowed.len;
}

fn validRollbackBackup(value: []const u8) bool {
    if (value.len == 0 or value.len >= max_path) return false;
    if (std.mem.indexOf(u8, value, "..") != null) return false;
    for (value) |ch| {
        if (ch < ' ' or ch == ';' or ch == '|') return false;
    }
    return true;
}

fn kindMatchesTarget(kind: []const u8, target: []const u8) bool {
    const class = r4os.r4sys.classifySystemPath(target);
    return equalsIgnoreCase(kind, r4os.r4sys.systemReplaceClassName(class));
}

const ExactReadResult = struct {
    ok: bool = false,
    completed: usize = 0,
    last_result: i32 = 0,
    retries: u32 = 0,
};

fn readExactAt(
    ctx: *const r4os.r4sys.Context,
    path: [*:0]const u8,
    offset: u64,
    out: []u8,
) ExactReadResult {
    var result = ExactReadResult{};
    var no_progress_attempts: u32 = 0;
    while (result.completed < out.len) {
        const absolute = std.math.add(u64, offset, result.completed) catch {
            result.last_result = -8;
            return result;
        };
        if (absolute > std.math.maxInt(u32)) {
            result.last_result = -8;
            return result;
        }
        const remaining = out.len - result.completed;
        const request_len = @min(remaining, @as(usize, std.math.maxInt(i32)));
        const rc = ctx.fileReadAt(
            path,
            @intCast(absolute),
            out[result.completed .. result.completed + request_len],
        );
        result.last_result = rc;
        if (rc > 0 and rc <= @as(i32, @intCast(request_len))) {
            result.completed += @intCast(rc);
            no_progress_attempts = 0;
            continue;
        }
        no_progress_attempts += 1;
        if (no_progress_attempts >= transient_read_attempt_limit) return result;
        result.retries += 1;
        ctx.sleepTicks(transient_io_retry_delay_ticks);
    }
    result.ok = true;
    return result;
}

fn checksumFileRange(ctx: *const r4os.r4sys.Context, path: [*:0]const u8, offset: u64, len: u64) ?u32 {
    return checksumFileRangeSeed(ctx, path, offset, len, checksum_seed);
}

fn checksumFileRangeSeed(ctx: *const r4os.r4sys.Context, path: [*:0]const u8, offset: u64, len: u64, seed: u32) ?u32 {
    var out = seed;
    var done: u64 = 0;
    const buf = checksum_io_buf[0..];
    while (done < len) {
        const want_u64 = @min(@as(u64, @intCast(buf.len)), len - done);
        const want: usize = @intCast(want_u64);
        const absolute = std.math.add(u64, offset, done) catch return null;
        if (absolute > std.math.maxInt(u32)) return null;
        if (!readExactAt(ctx, path, absolute, buf[0..want]).ok) return null;
        out = checksumUpdate(out, buf[0..want]);
        done += want;
    }
    return out;
}

fn checksum(data: []const u8) u32 {
    return system_update_recovery.checksum(data);
}

fn checksumUpdate(seed: u32, data: []const u8) u32 {
    return system_update_recovery.checksumUpdate(seed, data);
}

fn readCurrentVersionStatus(ctx: *const r4os.r4sys.Context, out: []u8) VersionRead {
    var info: r4os.abi.FileInfo = .{};
    switch (fileInfoStatus(ctx, "C:\\R4OS\\CONFIG\\VERSION.R4S", &info)) {
        .found => {},
        .not_found => return .not_found,
        .io => return .io,
    }
    if (info.is_dir != 0 or info.size == 0 or info.size > 256) return .invalid;
    var file_buf: [256]u8 = undefined;
    if (!readExactAt(ctx, "C:\\R4OS\\CONFIG\\VERSION.R4S", 0, file_buf[0..@intCast(info.size)]).ok) return .io;
    const data = file_buf[0..@intCast(info.size)];
    var pos: usize = 0;
    var found_len: ?usize = null;
    while (nextLine(data, &pos)) |line_raw| {
        const line = trim(stripBom(line_raw));
        if (startsWith(line, "RELEASE_VERSION=")) {
            if (found_len != null) return .invalid;
            const value = trim(line["RELEASE_VERSION=".len..]);
            if (value.len == 0 or value.len >= out.len or !versionTextValid(value)) return .invalid;
            @memcpy(out[0..value.len], value);
            found_len = value.len;
        }
    }
    const len = found_len orelse return .invalid;
    return .{ .found = out[0..len] };
}

fn versionTextValid(value: []const u8) bool {
    return system_update_recovery.versionTextValid(value);
}

fn compareVersions(a_raw: []const u8, b_raw: []const u8) ?i8 {
    if (!versionTextValid(a_raw) or !versionTextValid(b_raw)) return null;
    var a_pos: usize = 0;
    var b_pos: usize = 0;
    while (a_pos < a_raw.len or b_pos < b_raw.len) {
        const a_part = nextVersionPart(a_raw, &a_pos) orelse return null;
        const b_part = nextVersionPart(b_raw, &b_pos) orelse return null;
        if (a_part < b_part) return -1;
        if (a_part > b_part) return 1;
    }
    return 0;
}

fn nextVersionPart(value: []const u8, pos: *usize) ?u32 {
    if (pos.* >= value.len) return 0;
    var out: u32 = 0;
    while (pos.* < value.len and value[pos.*] >= '0' and value[pos.*] <= '9') : (pos.* += 1) {
        out = std.math.mul(u32, out, 10) catch return null;
        out = std.math.add(u32, out, @as(u32, value[pos.*] - '0')) catch return null;
    }
    if (pos.* < value.len) pos.* += 1;
    return out;
}

fn fieldValue(line: []const u8, key: []const u8) ?[]const u8 {
    var pos: usize = 0;
    var found: ?[]const u8 = null;
    while (pos <= line.len) {
        const next = std.mem.indexOfScalarPos(u8, line, pos, ';') orelse line.len;
        const part = line[pos..next];
        if (startsWith(part, key)) {
            if (found != null) return null;
            found = part[key.len..];
        }
        if (next == line.len) break;
        pos = next + 1;
    }
    return found;
}

fn parseYesNo(value: []const u8) ?bool {
    if (equalsIgnoreCase(value, "no")) return false;
    if (equalsIgnoreCase(value, "yes")) return true;
    return null;
}

fn fail(ctx: *const r4os.r4sys.Context, command: []const u8, reason: []const u8) void {
    @memset(last_reason[0..], 0);
    last_reason_len = copyTypedText(last_reason[0..], reason);
    ctx.write("SYSUPD ");
    ctx.write(command);
    ctx.write(" result: FAILED reason=");
    ctx.println(reason);
}

fn incompatible(ctx: *const r4os.r4sys.Context, command: []const u8, reason: []const u8, current: []const u8, required: []const u8) void {
    @memset(last_reason[0..], 0);
    last_reason_len = copyTypedText(last_reason[0..], reason);
    ctx.write("SYSUPD ");
    ctx.write(command);
    ctx.write(" result: INCOMPATIBLE reason=");
    ctx.write(reason);
    ctx.write(" current=");
    ctx.write(current);
    ctx.write(" required=");
    ctx.println(required);
}

fn nextToken(value: []const u8, pos: *usize) ?[]const u8 {
    while (pos.* < value.len and isSpace(value[pos.*])) : (pos.* += 1) {}
    if (pos.* >= value.len) return null;
    const start = pos.*;
    while (pos.* < value.len and !isSpace(value[pos.*])) : (pos.* += 1) {}
    return value[start..pos.*];
}

fn nextLine(value: []const u8, pos: *usize) ?[]const u8 {
    if (pos.* >= value.len) return null;
    const start = pos.*;
    while (pos.* < value.len and value[pos.*] != '\n') : (pos.* += 1) {}
    const end = pos.*;
    if (pos.* < value.len and value[pos.*] == '\n') pos.* += 1;
    return value[start..end];
}

fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isSpace(value[start])) : (start += 1) {}
    while (end > start and isSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn stripTrailingCr(value: []const u8) []const u8 {
    if (value.len != 0 and value[value.len - 1] == '\r') return value[0 .. value.len - 1];
    return value;
}

fn stripBom(value: []const u8) []const u8 {
    if (value.len >= 3 and value[0] == 0xEF and value[1] == 0xBB and value[2] == 0xBF) return value[3..];
    return value;
}

const PackagePath = struct {
    ptr: [*:0]const u8,
    text: []const u8,
};

fn normalizePackagePath(out: []u8, value_raw: []const u8) ?PackagePath {
    const value = stripQuotes(trim(value_raw));
    const text = normalizeAbsolutePath(out, value) orelse return null;
    return .{ .ptr = @ptrCast(out.ptr), .text = text };
}

fn normalizeAbsolutePath(out: []u8, value: []const u8) ?[]const u8 {
    return system_update_recovery.normalizeAbsolutePath(out, value);
}

fn appendNormalizedPathTail(out: []u8, out_len: *usize, value: []const u8) bool {
    for (value) |ch| {
        const normalized = if (isPathSeparator(ch)) '\\' else ch;
        if (!appendNormalizedPathByte(out, out_len, normalized)) return false;
    }
    return true;
}

fn appendNormalizedPathByte(out: []u8, out_len: *usize, ch: u8) bool {
    if (out_len.* + 1 >= out.len) return false;
    out[out_len.*] = ch;
    out_len.* += 1;
    return true;
}

fn assignInternalPaths(ctx: *const r4os.r4sys.Context, info: *PackageInfo, command: []const u8) bool {
    return assignInternalPathsAt(ctx, info, command, 0);
}

fn assignInternalPathsAt(
    ctx: *const r4os.r4sys.Context,
    info: *PackageInfo,
    command: []const u8,
    first_index: usize,
) bool {
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        var entry = &info.payloads[index];
        const transaction_index = first_index + index;
        entry.stage_len = buildInternal83Name(entry.stage_path[0..], entry.targetText(), 'S', info.transaction_generation, transaction_index) orelse {
            fail(ctx, command, "stage-8.3-path");
            return false;
        };
        entry.backup_len = buildInternal83Name(entry.backup_path[0..], entry.targetText(), 'B', info.transaction_generation, transaction_index) orelse {
            fail(ctx, command, "backup-8.3-path");
            return false;
        };
    }
    return true;
}

fn buildInternal83Name(out: []u8, target: []const u8, prefix: u8, transaction_generation: u64, index: usize) ?usize {
    return system_update_recovery.buildInternal83Name(
        out,
        target,
        prefix,
        transaction_generation,
        index,
    );
}

/// Decides whether two package paths would land on the SAME object.
///
/// A byte-wise ASCII fold is only a proof for ASCII: NTFS resolves names
/// through `$UpCase`, which folds many further pairs, so two targets could
/// look distinct here and still be one file on the volume - two payloads
/// silently writing into each other.  The kernel is therefore asked for the
/// volume's own collation, and only when that cannot answer (different
/// volumes, malformed name, older kernel without the slot) does the
/// conservative ASCII fold remain as a fallback.  A fold that says "equal"
/// is always honoured; the backend is consulted to catch the cases it would
/// MISS.
/// Module-owned so the comparison never puts two full paths on a task stack.
var alias_left_z: [max_path:0]u8 = .{0} ** max_path;
var alias_right_z: [max_path:0]u8 = .{0} ** max_path;

fn copyPathZ(out: *[max_path:0]u8, value: []const u8) ?[*:0]const u8 {
    if (value.len == 0 or value.len > max_path) return null;
    @memset(out[0..], 0);
    @memcpy(out[0..value.len], value);
    return @ptrCast(out[0..].ptr);
}

fn packagePathsAlias(ctx: *const r4os.r4sys.Context, left: []const u8, right: []const u8) bool {
    if (pathEqualsIgnoreCase(left, right)) return true;
    const left_ptr = copyPathZ(&alias_left_z, left) orelse return false;
    const right_ptr = copyPathZ(&alias_right_z, right) orelse return false;
    return ctx.pathNamesEqualCollated(left_ptr, right_ptr) ==
        r4os.r4sys.path_names_equal_result_equal;
}

fn validateTargetAliases(ctx: *const r4os.r4sys.Context, info: *const PackageInfo, command: []const u8) bool {
    if (!validatePackageTargets(ctx, info, command)) return false;
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        const entry = &info.payloads[index];
        var path_index: usize = 0;
        while (path_index < 4) : (path_index += 1) {
            const path = packagePayloadPath(entry, path_index);
            if (path.len == 0) continue;
            if (packagePathsAlias(ctx, info.source_path, path)) {
                fail(ctx, command, "package-target-alias");
                return false;
            }
            var other_index: usize = index;
            while (other_index < info.payload_count) : (other_index += 1) {
                const other = &info.payloads[other_index];
                var other_path_index: usize = if (other_index == index) path_index + 1 else 0;
                while (other_path_index < 4) : (other_path_index += 1) {
                    const other_path = packagePayloadPath(other, other_path_index);
                    if (other_path.len == 0 or !packagePathsAlias(ctx, path, other_path)) continue;
                    fail(ctx, command, "payload-path-alias");
                    return false;
                }
            }
        }
    }
    return true;
}

fn packagePayloadPath(entry: *const PayloadEntry, index: usize) []const u8 {
    return switch (index) {
        0 => entry.targetText(),
        1 => entry.stageText(),
        2 => entry.backupText(),
        3 => entry.previousBackupText(),
        else => &[_]u8{},
    };
}

/// Performs the target policy that VERIFY and APPLY must agree on before any
/// journal or stage file is written. Existing long filenames are supported:
/// FAT changes only their stable short directory entry. A missing long target
/// would require publishing a new multi-entry LFN run and is therefore not an
/// atomic update target.
fn validatePackageTargets(ctx: *const r4os.r4sys.Context, info: *const PackageInfo, command: []const u8) bool {
    var index: usize = 0;
    while (index < info.payload_count) : (index += 1) {
        const entry = &info.payloads[index];
        if (!validateShortName83Text(baseName(entry.targetText()))) {
            var target_info: r4os.abi.FileInfo = .{};
            switch (fileInfoStatus(ctx, entry.targetPtr(), &target_info)) {
                .found => {},
                .not_found => {
                    fail(ctx, command, "target-lfn-missing");
                    return false;
                },
                .io => {
                    fail(ctx, command, "target-info");
                    return false;
                },
            }
        }
        if (pathEqualsIgnoreCase(info.source_path, entry.targetText())) {
            fail(ctx, command, "package-target-alias");
            return false;
        }
        var other: usize = index + 1;
        while (other < info.payload_count) : (other += 1) {
            if (pathEqualsIgnoreCase(entry.targetText(), info.payloads[other].targetText())) {
                fail(ctx, command, "payload-path-alias");
                return false;
            }
        }
    }
    return true;
}

fn validateShortName83Text(name: []const u8) bool {
    return system_update_recovery.validateShortName83Text(name);
}

fn baseName(path: []const u8) []const u8 {
    var index = path.len;
    while (index > 0) : (index -= 1) {
        if (isPathSeparator(path[index - 1])) return path[index..];
    }
    return path;
}

fn pathEqualsIgnoreCase(a: []const u8, b: []const u8) bool {
    return system_update_recovery.pathEqualsIgnoreCase(a, b);
}

fn endsWithIgnoreCase(value: []const u8, suffix: []const u8) bool {
    if (value.len < suffix.len) return false;
    return equalsIgnoreCase(value[value.len - suffix.len ..], suffix);
}

fn hexDigit(value: u4) u8 {
    return if (value < 10) '0' + @as(u8, value) else 'A' + @as(u8, value - 10);
}

fn copyTextZ(out: []u8, value: []const u8) ?usize {
    if (value.len + 1 > out.len) return null;
    @memset(out, 0);
    @memcpy(out[0..value.len], value);
    return value.len;
}

fn stripQuotes(value: []const u8) []const u8 {
    if (value.len >= 2 and ((value[0] == '"' and value[value.len - 1] == '"') or (value[0] == '\'' and value[value.len - 1] == '\''))) {
        return trim(value[1 .. value.len - 1]);
    }
    return value;
}

fn isPathSeparator(ch: u8) bool {
    return ch == '\\' or ch == '/';
}

fn isDriveLetter(ch: u8) bool {
    const upper_ch = std.ascii.toUpper(ch);
    return upper_ch >= 'A' and upper_ch <= 'Z';
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and memEql(value[0..prefix.len], prefix);
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    if (value.len < prefix.len) return false;
    var i: usize = 0;
    while (i < prefix.len) : (i += 1) {
        const a = if (value[i] == '/') '\\' else value[i];
        const b = if (prefix[i] == '/') '\\' else prefix[i];
        if (std.ascii.toUpper(a) != std.ascii.toUpper(b)) return false;
    }
    return true;
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    return a.len == b.len and startsWithIgnoreCase(a, b);
}

fn spanZ(value: [*:0]const u8) []const u8 {
    return std.mem.span(value);
}

fn memEql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn parseU32(value: []const u8) ?u32 {
    const v = parseU64(value) orelse return null;
    if (v > std.math.maxInt(u32)) return null;
    return @intCast(v);
}

fn parseU64(value_raw: []const u8) ?u64 {
    const value = trim(value_raw);
    if (value.len == 0) return null;
    var out: u64 = 0;
    for (value) |ch| {
        if (ch < '0' or ch > '9') return null;
        out = std.math.mul(u64, out, 10) catch return null;
        out = std.math.add(u64, out, @as(u64, ch - '0')) catch return null;
    }
    return out;
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
