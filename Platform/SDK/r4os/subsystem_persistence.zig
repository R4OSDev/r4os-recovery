const std = @import("std");
const contract_root = @import("r4os_contract");
const storage = @import("app_storage.zig");
const system = @import("r4sys.zig");

const R4os = struct {
    pub const abi = contract_root.abi;
    pub const app_storage = storage;
    pub const AbsoluteFilePath = storage.AbsoluteFilePath;
    pub const r4sys = system;
};
const r4os = R4os;

pub const digest_bytes: usize = 32;
pub const digest_hex_bytes: usize = digest_bytes * 2;
pub const FileKind = enum { sram, rtc, sram_delta };

// Save/recovery needs only size and type. Generation2 identities and hash-
// based filenames must never be narrowed into the legacy FileInfo shape.
const PathShape = union(enum) {
    value: struct { size: u64, is_dir: u8 },
    missing,
    failure: i32,
};
fn pathShape(files: *const storage.Files, path: storage.PathZ) PathShape {
    if (files.sys.base.generation2 != null) {
        return switch (files.metadata(path)) {
            .found => |info| blk: {
                if (info.version != 1 or info.size < @sizeOf(r4os.abi.FileMetadata2) or
                    info.flags & r4os.abi.file_metadata2_flag_exists == 0)
                    break :blk .{ .failure = r4os.abi.file_metadata2_error_unsupported };
                const directory = info.flags & r4os.abi.file_metadata2_flag_directory != 0;
                if (!directory and info.flags & r4os.abi.file_metadata2_flag_byte_size_valid == 0)
                    break :blk .{ .failure = r4os.abi.file_metadata2_error_unsupported };
                break :blk .{ .value = .{ .size = if (directory) 0 else info.byte_size, .is_dir = @intFromBool(directory) } };
            },
            .missing => .missing,
            .failure => |code| .{ .failure = code },
        };
    }
    return switch (files.info(path)) {
        .value => |info| .{ .value = .{ .size = info.size, .is_dir = info.is_dir } },
        .missing => .missing,
        .failure => |code| .{ .failure = code },
    };
}

pub fn digestHex(digest: *const [digest_bytes]u8, out: *[digest_hex_bytes]u8) []const u8 {
    const alphabet = "0123456789ABCDEF";
    for (digest, 0..) |byte, index| {
        out[index * 2] = alphabet[byte >> 4];
        out[index * 2 + 1] = alphabet[byte & 0x0F];
    }
    return out[0..];
}

pub const ReadResult = enum {
    ok,
    missing,
    wrong_size,
    io,
};

pub const BackendError = error{
    Busy,
    Io,
    Full,
    Unsupported,
};

/// Stable source-level port shared by subsystem-owned cartridge policies and
/// the R4OS App-Files implementation below. This is compiled into each
/// consumer and introduces neither an R4L nor a platform ABI.
pub const Backend = struct {
    context: *anyopaque,
    acquire_fn: *const fn (*anyopaque, *const [digest_bytes]u8, u64) BackendError!void,
    release_fn: *const fn (*anyopaque, *const [digest_bytes]u8, u64) BackendError!void,
    read_exact_fn: *const fn (*anyopaque, *const [digest_bytes]u8, FileKind, []u8) ReadResult,
    write_atomic_fn: *const fn (*anyopaque, *const [digest_bytes]u8, FileKind, []const u8) BackendError!void,
    poll_fn: ?*const fn (*anyopaque) BackendError!void = null,
    drain_fn: ?*const fn (*anyopaque) BackendError!void = null,
    pending_fn: ?*const fn (*anyopaque) bool = null,

    pub fn acquire(self: Backend, digest: *const [digest_bytes]u8, generation: u64) BackendError!void {
        return self.acquire_fn(self.context, digest, generation);
    }

    pub fn release(self: Backend, digest: *const [digest_bytes]u8, generation: u64) BackendError!void {
        return self.release_fn(self.context, digest, generation);
    }

    pub fn readExact(self: Backend, digest: *const [digest_bytes]u8, kind: FileKind, out: []u8) ReadResult {
        return self.read_exact_fn(self.context, digest, kind, out);
    }

    pub fn writeAtomic(self: Backend, digest: *const [digest_bytes]u8, kind: FileKind, bytes: []const u8) BackendError!void {
        return self.write_atomic_fn(self.context, digest, kind, bytes);
    }

    /// A baseline checkpoint must follow all older deltas. Async backends
    /// provide both callbacks; synchronous stores are already drained.
    pub fn drain(self: Backend) BackendError!void {
        if (self.drain_fn) |callback| try callback(self.context) else try self.poll();
    }

    pub fn pending(self: Backend) bool {
        return if (self.pending_fn) |callback| callback(self.context) else false;
    }

    pub fn poll(self: Backend) BackendError!void {
        if (self.poll_fn) |callback| try callback(self.context);
    }
};

/// Runtime form of the same store configuration for non-Zig consumers.
/// Keep paths, validation context and scratch stable through the last backend
/// release/drain. Only the serialized writer may use record_scratch.
pub const Configuration = struct {
    save_root: []const u8,
    root_directories: []const []const u8,
    rtc_record_bytes: usize = 0,
    delta_record_bytes: usize = 0,
    record_scratch: []u8 = &.{},
    context: ?*anyopaque = null,
    validate_rtc: ?*const fn (?*anyopaque, []const u8) bool = null,
    validate_delta: ?*const fn (?*anyopaque, []const u8) bool = null,

    pub fn valid(self: *const Configuration) bool {
        _ = storage.AbsoluteFilePath.parse(self.save_root) catch return false;
        if (self.save_root.len == 0 or self.save_root[self.save_root.len - 1] != '\\') return false;
        if (self.record_scratch.len < @max(self.rtc_record_bytes, self.delta_record_bytes)) return false;
        if (self.rtc_record_bytes != 0 and self.validate_rtc == null) return false;
        if (self.delta_record_bytes != 0 and self.validate_delta == null) return false;
        for (self.root_directories) |path| _ = storage.AbsoluteFilePath.parse(path) catch return false;
        return true;
    }
};

/// Config supplies only the installed save root and RTC container validator;
/// cartridge enablement, dirty policy, record codecs and clocks stay with the
/// consuming subsystem.
pub fn R4osStore(comptime Config: type) type {
    const dynamic = Config == Configuration;
    const ConfigView = if (dynamic) *const Configuration else void;
    comptime {
        if (!dynamic and (!@hasDecl(Config, "save_root") or
            !@hasDecl(Config, "root_directories") or
            !@hasDecl(Config, "rtc_record_bytes") or
            !@hasDecl(Config, "validateRtc")))
        {
            @compileError("subsystem persistence config is incomplete");
        }
    }
    return struct {
        const PathRole = enum { sram, rtc, lock, atomic_lock, sram_stage, rtc_stage, sram_backup, rtc_backup, sram_delta, delta_stage, delta_backup };
        const create_retry_attempts: usize = 8;
        const create_retry_delay_ms: u64 = 25;

        pub const FailureStage = enum {
            none,
            async_unavailable,
            async_allocate,
            async_start,
            async_join,
            save_root,
            lock_begin,
            lock_write,
            lock_finish,
            lock_abort,
            atomic_cleanup,
            atomic_begin,
            atomic_begin_create,
            atomic_begin_write,
            atomic_begin_finish,
            atomic_begin_abort,
            atomic_release,
            atomic_recover,
            atomic_stage,
            atomic_stage_begin,
            atomic_stage_write,
            atomic_stage_finish,
            atomic_stage_verify,
            atomic_publish,
            sram_info,
            sram_read,
            rtc_info,
            rtc_read,
        };

        pub const RecoveryTestState = struct {
            target_size: ?u64,
            stage_size: ?u64,
            backup_size: ?u64,
        };

        pub const Store = struct {
            files: r4os.app_storage.Files,
            lock_writer: ?r4os.app_storage.OwnedStageWriter = null,
            lock_generation: u64 = 0,
            lock_digest: [digest_bytes]u8 = .{0} ** digest_bytes,
            failure_stage: FailureStage = .none,
            failure_code: i32 = 0,

            configuration: ConfigView = if (dynamic) undefined else {},
            pub const init = if (dynamic) initConfigured else initStatic;
            fn initStatic(files: r4os.app_storage.Files) Store {
                return .{ .files = files };
            }
            fn initConfigured(files: r4os.app_storage.Files, configuration: *const Configuration) Store {
                return .{ .files = files, .configuration = configuration };
            }

            pub fn backend(self: *Store) Backend {
                return .{
                    .context = self,
                    .acquire_fn = acquire,
                    .release_fn = release,
                    .read_exact_fn = readExact,
                    .write_atomic_fn = writeAtomic,
                };
            }

            pub fn failureStageName(self: *const Store) []const u8 {
                return @tagName(self.failure_stage);
            }

            pub fn failureCode(self: *const Store) i32 {
                return self.failure_code;
            }

            pub fn removeTestFiles(self: *Store, digest: *const [digest_bytes]u8) void {
                // The self-test may start from an image where the save root does not
                // exist yet. Avoid delete operations through a missing parent chain;
                // production Session.open creates the same hierarchy before acquiring
                // its lease.
                ensureSaveRoot(self.configuration, &self.files) catch return;
                for ([_]PathRole{
                    PathRole.sram,
                    PathRole.rtc,
                    PathRole.lock,
                    PathRole.atomic_lock,
                    PathRole.sram_stage,
                    PathRole.rtc_stage,
                    PathRole.sram_backup,
                    PathRole.rtc_backup,
                    PathRole.sram_delta,
                    PathRole.delta_stage,
                    PathRole.delta_backup,
                }) |role| {
                    const path = makePath(self.configuration, digest, role) catch continue;
                    _ = self.files.delete(path.asZ());
                }
            }

            /// Diagnostic-only fixture for the in-image persistence gate. The caller
            /// must use a synthetic cartridge digest: this deliberately leaves the
            /// exact namespace tuple produced by an interrupted first publish leg.
            pub fn prepareInterruptedPublishForTest(
                self: *Store,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
                bytes: []const u8,
            ) BackendError!void {
                if (self.lock_writer != null) return error.Busy;
                try ensureSaveRoot(self.configuration, &self.files);
                const transaction = makePath(self.configuration, digest, .atomic_lock) catch return error.Io;
                const target = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram,
                    .rtc => .rtc,
                    .sram_delta => .sram_delta,
                }) catch return error.Io;
                const stage = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram_stage,
                    .rtc => .rtc_stage,
                    .sram_delta => .delta_stage,
                }) catch return error.Io;
                const backup = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram_backup,
                    .rtc => .rtc_backup,
                    .sram_delta => .delta_backup,
                }) catch return error.Io;
                try removeAtomicScratch(self, &transaction);
                try removeAtomicScratch(self, &stage);
                try removeAtomicScratch(self, &backup);

                const previous_size = (try pathSizeVisibleWithRetry(self, &target, .atomic_stage)) orelse {
                    self.recordFailure(.atomic_stage, r4os.r4sys.file_replace_atomic_error_not_found);
                    return error.Io;
                };
                var writer = switch (self.files.streamWriter(stage.asZ(), r4os.abi.file_stream_open_replace)) {
                    .writer => |value| value,
                    .failure => |fault| {
                        self.recordFailure(.atomic_stage, fault);
                        return mapOpenFault(fault);
                    },
                };
                var finished = false;
                defer if (!finished) {
                    _ = writer.abort();
                };
                var offset: usize = 0;
                while (offset < bytes.len) {
                    const end = @min(offset + 16 * 1024, bytes.len);
                    switch (writer.write(bytes[offset..end])) {
                        .ok => {},
                        .failure => |fault| {
                            self.recordFailure(.atomic_stage, fault);
                            return mapOpenFault(fault);
                        },
                        .missing => {
                            self.recordFailure(.atomic_stage, 0);
                            return error.Io;
                        },
                    }
                    offset = end;
                }
                switch (writer.finish()) {
                    .ok => finished = true,
                    .failure => |fault| {
                        self.recordFailure(.atomic_stage, fault);
                        return mapOpenFault(fault);
                    },
                    .missing => {
                        self.recordFailure(.atomic_stage, 0);
                        return error.Io;
                    },
                }
                const staged_size = (try pathSizeVisibleWithRetry(self, &stage, .atomic_stage)) orelse {
                    self.recordFailure(.atomic_stage, r4os.r4sys.file_replace_atomic_error_not_found);
                    return error.Io;
                };
                if (staged_size != bytes.len) {
                    self.recordFailure(.atomic_stage, r4os.abi.file_stream_error_size_mismatch);
                    return error.Io;
                }

                for (0..create_retry_attempts) |attempt| {
                    switch (self.files.rename(target.asZ(), backup.asZ())) {
                        .ok => break,
                        .missing => {
                            const visible_backup = try pathSizeVisibleWithRetry(self, &backup, .atomic_stage);
                            if (visible_backup != null and visible_backup.? == previous_size) break;
                            self.recordFailure(.atomic_stage, r4os.r4sys.file_replace_atomic_error_not_found);
                            return error.Io;
                        },
                        .failure => |fault| {
                            if (attempt + 1 == create_retry_attempts) {
                                self.recordFailure(.atomic_stage, fault);
                                return mapOpenFault(fault);
                            }
                            waitForCreateRetry(&self.files);
                            continue;
                        },
                    }
                }
                const backup_size = (try pathSizeVisibleWithRetry(self, &backup, .atomic_stage)) orelse {
                    self.recordFailure(.atomic_stage, r4os.r4sys.file_replace_atomic_error_not_found);
                    return error.Io;
                };
                if (backup_size != previous_size) {
                    self.recordFailure(.atomic_stage, r4os.abi.file_stream_error_size_mismatch);
                    return error.Io;
                }
                if (try pathSizeWithRetry(self, &target, .atomic_stage) != null) {
                    self.recordFailure(.atomic_stage, r4os.r4sys.file_replace_atomic_error_conflict);
                    return error.Io;
                }
                self.failure_stage = .none;
                self.failure_code = 0;
            }

            pub fn recoveryTestStateForTest(
                self: *Store,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
            ) BackendError!RecoveryTestState {
                const target = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram,
                    .rtc => .rtc,
                    .sram_delta => .sram_delta,
                }) catch return error.Io;
                const stage = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram_stage,
                    .rtc => .rtc_stage,
                    .sram_delta => .delta_stage,
                }) catch return error.Io;
                const backup = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram_backup,
                    .rtc => .rtc_backup,
                    .sram_delta => .delta_backup,
                }) catch return error.Io;
                return .{
                    .target_size = try pathSizeWithRetry(self, &target, .atomic_recover),
                    .stage_size = try pathSizeWithRetry(self, &stage, .atomic_recover),
                    .backup_size = try pathSizeWithRetry(self, &backup, .atomic_recover),
                };
            }

            fn acquire(context: *anyopaque, digest: *const [digest_bytes]u8, generation: u64) BackendError!void {
                const self: *Store = @ptrCast(@alignCast(context));
                if (self.lock_writer != null) return error.Busy;
                self.failure_stage = .none;
                self.failure_code = 0;
                ensureSaveRoot(self.configuration, &self.files) catch |fault| {
                    self.recordFailure(.save_root, 0);
                    return fault;
                };
                const path = makePath(self.configuration, digest, .lock) catch return error.Io;
                for (0..create_retry_attempts) |attempt| {
                    const writer = createOwnedLock(self, &path, generation) catch |fault| {
                        if (fault != error.Io or self.failure_stage == .lock_abort or attempt + 1 == create_retry_attempts) return fault;
                        waitForCreateRetry(&self.files);
                        continue;
                    };
                    self.lock_writer = writer;
                    self.lock_generation = generation;
                    self.lock_digest = digest.*;
                    self.failure_stage = .none;
                    self.failure_code = 0;
                    return;
                }
                unreachable;
            }

            fn release(context: *anyopaque, digest: *const [digest_bytes]u8, generation: u64) BackendError!void {
                const self: *Store = @ptrCast(@alignCast(context));
                if (self.lock_writer == null) return;
                if (self.lock_generation != generation or !std.mem.eql(u8, self.lock_digest[0..], digest[0..])) return error.Io;
                const path = makePath(self.configuration, digest, .lock) catch return error.Io;
                if (!abortOwnedPathWithRetry(self, &path)) return error.Io;
                self.lock_writer = null;
                self.lock_generation = 0;
            }

            fn readExact(
                context: *anyopaque,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
                out: []u8,
            ) ReadResult {
                const self: *Store = @ptrCast(@alignCast(context));
                if (self.lock_writer == null or !std.mem.eql(u8, self.lock_digest[0..], digest[0..])) {
                    self.recordFailure(.atomic_recover, r4os.r4sys.file_replace_atomic_error_conflict);
                    return .io;
                }
                recoverPendingKind(self, digest, kind, out.len) catch return .io;
                const path = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram,
                    .rtc => .rtc,
                    .sram_delta => .sram_delta,
                }) catch return .io;
                const info = info_retry: {
                    for (0..create_retry_attempts) |attempt| {
                        switch (pathShape(&self.files, path.asZ())) {
                            .value => |value| break :info_retry value,
                            .missing => return .missing,
                            .failure => |fault| {
                                if (attempt + 1 == create_retry_attempts) {
                                    self.recordFailure(if (kind == .sram) .sram_info else .rtc_info, fault);
                                    return .io;
                                }
                                waitForCreateRetry(&self.files);
                            },
                        }
                    }
                    unreachable;
                };
                if (info.is_dir != 0 or info.size != out.len) return .wrong_size;
                var offset: usize = 0;
                while (offset < out.len) {
                    const transferred = switch (self.files.readAt(path.asZ(), @intCast(offset), out[offset..])) {
                        .bytes => |count| count,
                        .end => return .io,
                        .failure => |fault| {
                            self.recordFailure(if (kind == .sram) .sram_read else .rtc_read, fault);
                            return .io;
                        },
                    };
                    if (transferred == 0 or transferred > out.len - offset) return .io;
                    offset += transferred;
                }
                return .ok;
            }

            fn writeAtomic(
                context: *anyopaque,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
                bytes: []const u8,
            ) BackendError!void {
                const self: *Store = @ptrCast(@alignCast(context));
                if (self.lock_writer == null or !std.mem.eql(u8, self.lock_digest[0..], digest[0..])) return error.Busy;
                const transaction = makePath(self.configuration, digest, .atomic_lock) catch return error.Io;
                const target = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram,
                    .rtc => .rtc,
                    .sram_delta => .sram_delta,
                }) catch return error.Io;
                const stage = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram_stage,
                    .rtc => .rtc_stage,
                    .sram_delta => .delta_stage,
                }) catch return error.Io;
                const backup = makePath(self.configuration, digest, switch (kind) {
                    .sram => .sram_backup,
                    .rtc => .rtc_backup,
                    .sram_delta => .delta_backup,
                }) catch return error.Io;
                try beginAtomicTransaction(self, &transaction);
                var transaction_held = true;
                defer if (transaction_held) {
                    _ = abortOwnedPathWithRetryAtStage(self, &transaction, .atomic_release);
                };
                // Never discard a previous stage or its last-good backup. A lost I/O
                // acknowledgement may have crossed either NTFS visibility point, so
                // the idempotent replacement must first finish that exact tuple.
                try recoverAtomicKind(self, kind, bytes.len, &target, &stage, &backup);
                try writeStageSnapshotWithRetry(self, kind, &stage, bytes);
                try replaceAtomicWithRetry(self, &target, &stage, &backup, .atomic_publish);
                const published_size = try pathSizeVisibleWithRetry(self, &target, .atomic_publish);
                if (published_size == null) {
                    self.recordFailure(.atomic_publish, r4os.r4sys.file_replace_atomic_error_not_found);
                    return error.Io;
                }
                if (published_size.? != bytes.len) {
                    self.recordFailure(.atomic_publish, r4os.abi.file_stream_error_size_mismatch);
                    return error.Io;
                }
                if (kind != .sram) try validateRecordAt(self, kind, &target, .atomic_publish);
                try removeAtomicScratch(self, &backup);
                if (!abortOwnedPathWithRetryAtStage(self, &transaction, .atomic_release)) return error.Io;
                transaction_held = false;
                self.failure_stage = .none;
                self.failure_code = 0;
            }

            fn recordFailure(self: *Store, stage: FailureStage, code: i32) void {
                self.failure_stage = stage;
                self.failure_code = code;
            }
        };

        /// NTFS can transiently lose ordinary name visibility between Stream Begin,
        /// Write and Finish even though the private stage namespace remains owned by
        /// this cartridge transaction. Retry only those namespace/I/O outcomes. An
        /// incomplete attempt is ownership-aborted and removed before the next Begin;
        /// invalid data, conflicts and capacity failures remain immediate failures.
        fn writeStageSnapshotWithRetry(
            self: *Store,
            kind: FileKind,
            stage: *const r4os.AbsoluteFilePath,
            bytes: []const u8,
        ) BackendError!void {
            for (0..create_retry_attempts) |attempt| {
                writeStageSnapshotOnce(self, stage, bytes) catch |fault| {
                    const failure_stage = self.failure_stage;
                    const failure_code = self.failure_code;
                    if (!retryablePrivateStreamFault(failure_code) or attempt + 1 == create_retry_attempts) return fault;

                    // recoverAtomicKind has already completed every older durable
                    // stage, so this private name can only belong to this failed
                    // attempt while the per-digest transaction lease is held.
                    removeAtomicScratch(self, stage) catch |cleanup_fault| return cleanup_fault;
                    self.recordFailure(failure_stage, failure_code);
                    waitForCreateRetry(&self.files);
                    continue;
                };

                const staged_size = (try pathSizeVisibleWithRetry(self, stage, .atomic_stage_verify)) orelse {
                    self.recordFailure(.atomic_stage_verify, r4os.abi.file_stream_error_not_found);
                    return error.Io;
                };
                if (staged_size != bytes.len) {
                    self.recordFailure(.atomic_stage_verify, r4os.abi.file_stream_error_size_mismatch);
                    return error.Io;
                }
                if (kind != .sram) try validateRecordAt(self, kind, stage, .atomic_stage_verify);
                return;
            }
            unreachable;
        }

        fn writeStageSnapshotOnce(
            self: *Store,
            stage: *const r4os.AbsoluteFilePath,
            bytes: []const u8,
        ) BackendError!void {
            var writer = switch (self.files.streamWriter(stage.asZ(), r4os.abi.file_stream_open_replace)) {
                .writer => |value| value,
                .failure => |fault| {
                    self.recordFailure(.atomic_stage_begin, fault);
                    return mapOpenFault(fault);
                },
            };
            var finished = false;
            defer if (!finished) {
                _ = writer.abort();
            };

            var offset: usize = 0;
            while (offset < bytes.len) {
                const end = @min(offset + 16 * 1024, bytes.len);
                switch (writer.write(bytes[offset..end])) {
                    .ok => {},
                    .failure => |fault| {
                        self.recordFailure(.atomic_stage_write, fault);
                        return mapOpenFault(fault);
                    },
                    .missing => {
                        self.recordFailure(.atomic_stage_write, r4os.abi.file_stream_error_not_found);
                        return error.Io;
                    },
                }
                offset = end;
            }
            switch (writer.finish()) {
                .ok => finished = true,
                .failure => |fault| {
                    self.recordFailure(.atomic_stage_finish, fault);
                    return mapOpenFault(fault);
                },
                .missing => {
                    self.recordFailure(.atomic_stage_finish, r4os.abi.file_stream_error_not_found);
                    return error.Io;
                },
            }
        }

        fn retryablePrivateStreamFault(code: i32) bool {
            return code == r4os.abi.file_stream_error_not_found or code == r4os.abi.file_stream_error_io;
        }

        const async_write_stack: u64 = 128 * 1024;

        const AsyncWriteResult = enum {
            pending,
            ok,
            busy,
            io,
            full,
            unsupported,
        };

        const AsyncWriteJob = struct {
            store: *Store,
            digest: [digest_bytes]u8,
            kind: FileKind,
            bytes: []u8,
            sequence: u64,
            result: AsyncWriteResult = .pending,
        };

        const ActiveWrite = struct {
            job: *AsyncWriteJob,
            handle: r4os.abi.ProgramJoinHandle,
        };

        pub const AsyncStats = struct {
            enqueued: u64 = 0,
            started: u64 = 0,
            completed: u64 = 0,
            coalesced: u64 = 0,
            errors: u64 = 0,
            maximum_queued: u8 = 0,
            snapshot_bytes: u64 = 0,
            written_bytes: u64 = 0,
        };

        /// Product persistence wrapper. The emulation thread only copies an immutable
        /// SRAM/RTC or bounded delta snapshot; a joinable app thread performs the
        /// atomic namespace transaction. One worker serializes all kinds so the writer
        /// lease never need cross-thread locking. New snapshots are coalesced per kind,
        /// while close drains every accepted write before releasing the cartridge.
        pub const AsyncStore = struct {
            allocator: std.mem.Allocator,
            store: Store,
            active: ?ActiveWrite = null,
            pending: [3]?*AsyncWriteJob = .{ null, null, null },
            next_sequence: u64 = 1,
            latched_failure: ?BackendError = null,
            stats: AsyncStats = .{},

            pub const init = if (dynamic) initConfigured else initStatic;
            fn initStatic(files: r4os.app_storage.Files, allocator: std.mem.Allocator) AsyncStore {
                return .{ .allocator = allocator, .store = Store.init(files) };
            }
            fn initConfigured(files: r4os.app_storage.Files, allocator: std.mem.Allocator, configuration: *const Configuration) AsyncStore {
                return .{ .allocator = allocator, .store = Store.init(files, configuration) };
            }

            pub fn backend(self: *AsyncStore) Backend {
                return .{
                    .context = self,
                    .acquire_fn = acquire,
                    .release_fn = release,
                    .read_exact_fn = readExact,
                    .write_atomic_fn = writeAtomic,
                    .poll_fn = poll,
                    .drain_fn = drainBackend,
                    .pending_fn = pendingBackend,
                };
            }

            pub fn failureStageName(self: *const AsyncStore) []const u8 {
                return self.store.failureStageName();
            }

            pub fn failureCode(self: *const AsyncStore) i32 {
                return self.store.failureCode();
            }

            pub fn removeTestFiles(self: *AsyncStore, digest: *const [digest_bytes]u8) void {
                self.store.removeTestFiles(digest);
            }

            fn acquire(context: *anyopaque, digest: *const [digest_bytes]u8, generation: u64) BackendError!void {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                if (self.active != null or self.pendingCount() != 0) return error.Busy;
                if (!self.store.files.sys.hasFn("thread_create_handle") or !self.store.files.sys.hasFn("thread_handle_join")) {
                    self.store.recordFailure(.async_unavailable, r4os.abi.thread_error_unsupported);
                    return error.Unsupported;
                }
                self.latched_failure = null;
                try self.store.backend().acquire(digest, generation);
            }

            fn release(context: *anyopaque, digest: *const [digest_bytes]u8, generation: u64) BackendError!void {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                var write_fault: ?BackendError = null;
                self.drain() catch |fault| {
                    write_fault = fault;
                };
                var release_fault: ?BackendError = null;
                self.store.backend().release(digest, generation) catch |fault| {
                    release_fault = fault;
                };
                self.clearPending();
                if (write_fault) |fault| return fault;
                if (self.latched_failure) |fault| return fault;
                if (release_fault) |fault| return fault;
            }

            fn readExact(
                context: *anyopaque,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
                out: []u8,
            ) ReadResult {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                if (self.active != null or self.pendingCount() != 0) return .io;
                return self.store.backend().readExact(digest, kind, out);
            }

            fn writeAtomic(
                context: *anyopaque,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
                bytes: []const u8,
            ) BackendError!void {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                try self.pollOne(0);
                if (self.latched_failure) |fault| return fault;
                if (self.store.lock_writer == null or !std.mem.eql(u8, self.store.lock_digest[0..], digest[0..])) return error.Busy;

                const job = try self.createJob(digest, kind, bytes);
                self.stats.enqueued +%= 1;
                self.stats.snapshot_bytes +%= bytes.len;
                if (self.active == null) {
                    self.startJob(job) catch |fault| {
                        self.destroyJob(job);
                        return fault;
                    };
                } else {
                    const index = kindIndex(kind);
                    if (self.pending[index]) |older| {
                        self.destroyJob(older);
                        self.stats.coalesced +%= 1;
                    }
                    self.pending[index] = job;
                }
                self.recordMaximumQueued();
            }

            fn poll(context: *anyopaque) BackendError!void {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                try self.pollOne(0);
            }

            fn createJob(
                self: *AsyncStore,
                digest: *const [digest_bytes]u8,
                kind: FileKind,
                bytes: []const u8,
            ) BackendError!*AsyncWriteJob {
                const snapshot = self.allocator.dupe(u8, bytes) catch {
                    self.store.recordFailure(.async_allocate, r4os.abi.thread_error_no_memory);
                    return error.Full;
                };
                errdefer self.allocator.free(snapshot);
                const job = self.allocator.create(AsyncWriteJob) catch {
                    self.store.recordFailure(.async_allocate, r4os.abi.thread_error_no_memory);
                    return error.Full;
                };
                job.* = .{
                    .store = &self.store,
                    .digest = digest.*,
                    .kind = kind,
                    .bytes = snapshot,
                    .sequence = self.next_sequence,
                };
                self.next_sequence +%= 1;
                if (self.next_sequence == 0) self.next_sequence = 1;
                return job;
            }

            fn startJob(self: *AsyncStore, job: *AsyncWriteJob) BackendError!void {
                std.debug.assert(self.active == null);
                var handle: r4os.abi.ProgramJoinHandle = .{};
                const rc = self.store.files.sys.threadCreateHandle(asyncWriteWorker, @intFromPtr(job), async_write_stack, 0, &handle);
                if (rc != r4os.abi.thread_ok) {
                    self.store.recordFailure(.async_start, rc);
                    return mapThreadFault(rc);
                }
                self.active = .{ .job = job, .handle = handle };
                self.stats.started +%= 1;
            }

            fn pollOne(self: *AsyncStore, timeout_ticks: u64) BackendError!void {
                if (self.latched_failure) |fault| return fault;
                if (self.active) |active| {
                    var exit_code: i32 = 0;
                    const rc = self.store.files.sys.threadHandleJoin(&active.handle, timeout_ticks, &exit_code);
                    if (rc == r4os.abi.thread_error_timeout) return;
                    self.active = null;
                    self.stats.completed +%= 1;
                    const job = active.job;
                    const result = if (rc == r4os.abi.thread_ok and exit_code == 0) job.result else AsyncWriteResult.io;
                    if (result == .ok) self.stats.written_bytes +%= job.bytes.len;
                    if (rc != r4os.abi.thread_ok or exit_code != 0) self.store.recordFailure(.async_join, if (rc != r4os.abi.thread_ok) rc else exit_code);
                    self.destroyJob(job);
                    if (asyncResultFault(result)) |fault| {
                        self.stats.errors +%= 1;
                        self.latched_failure = fault;
                        self.clearPending();
                        return fault;
                    }
                }

                if (self.active == null) if (self.takeOldestPending()) |job| {
                    self.startJob(job) catch |fault| {
                        self.destroyJob(job);
                        self.stats.errors +%= 1;
                        self.latched_failure = fault;
                        self.clearPending();
                        return fault;
                    };
                };
                if (self.latched_failure) |fault| return fault;
            }

            fn drainBackend(context: *anyopaque) BackendError!void {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                try self.drain();
            }

            fn pendingBackend(context: *anyopaque) bool {
                const self: *AsyncStore = @ptrCast(@alignCast(context));
                return self.active != null or self.pendingCount() != 0;
            }

            fn drain(self: *AsyncStore) BackendError!void {
                while (self.active != null or self.pendingCount() != 0) {
                    if (self.active == null) {
                        const job = self.takeOldestPending() orelse break;
                        self.startJob(job) catch |fault| {
                            self.destroyJob(job);
                            self.stats.errors +%= 1;
                            self.latched_failure = fault;
                            self.clearPending();
                            return fault;
                        };
                    }
                    try self.pollOne(r4os.abi.thread_wait_forever);
                }
                if (self.latched_failure) |fault| return fault;
            }

            fn takeOldestPending(self: *AsyncStore) ?*AsyncWriteJob {
                var selected: ?usize = null;
                for (self.pending, 0..) |candidate, index| {
                    if (candidate == null) continue;
                    if (selected == null or candidate.?.sequence < self.pending[selected.?].?.sequence) selected = index;
                }
                const index = selected orelse return null;
                const job = self.pending[index].?;
                self.pending[index] = null;
                return job;
            }

            fn clearPending(self: *AsyncStore) void {
                for (&self.pending) |*candidate| {
                    if (candidate.*) |job| self.destroyJob(job);
                    candidate.* = null;
                }
            }

            fn pendingCount(self: *const AsyncStore) u8 {
                var count: u8 = 0;
                for (self.pending) |candidate| count += @intFromBool(candidate != null);
                return count;
            }

            fn recordMaximumQueued(self: *AsyncStore) void {
                const queued = self.pendingCount() + @as(u8, @intFromBool(self.active != null));
                self.stats.maximum_queued = @max(self.stats.maximum_queued, queued);
            }

            fn destroyJob(self: *AsyncStore, job: *AsyncWriteJob) void {
                self.allocator.free(job.bytes);
                self.allocator.destroy(job);
            }
        };

        fn asyncWriteWorker(arg: u64) callconv(.c) i32 {
            const job: *AsyncWriteJob = @ptrFromInt(arg);
            job.store.backend().writeAtomic(&job.digest, job.kind, job.bytes) catch |fault| {
                job.result = asyncResultForFault(fault);
                return 0;
            };
            job.result = .ok;
            return 0;
        }

        fn kindIndex(kind: FileKind) usize {
            return switch (kind) {
                .sram => 0,
                .rtc => 1,
                .sram_delta => 2,
            };
        }

        fn asyncResultForFault(fault: BackendError) AsyncWriteResult {
            return switch (fault) {
                error.Busy => .busy,
                error.Io => .io,
                error.Full => .full,
                error.Unsupported => .unsupported,
            };
        }

        fn asyncResultFault(result: AsyncWriteResult) ?BackendError {
            return switch (result) {
                .pending, .io => error.Io,
                .busy => error.Busy,
                .full => error.Full,
                .unsupported => error.Unsupported,
                .ok => null,
            };
        }

        fn mapThreadFault(code: i32) BackendError {
            return switch (code) {
                r4os.abi.thread_error_no_memory, r4os.abi.thread_error_no_slots => error.Full,
                r4os.abi.thread_error_unsupported => error.Unsupported,
                else => error.Io,
            };
        }

        fn removeAtomicScratch(self: *Store, path: *const r4os.AbsoluteFilePath) BackendError!void {
            for (0..create_retry_attempts) |attempt| {
                switch (self.files.delete(path.asZ())) {
                    .ok, .missing => return,
                    .failure => |fault| {
                        if (attempt + 1 == create_retry_attempts) {
                            self.recordFailure(.atomic_cleanup, fault);
                            return mapOpenFault(fault);
                        }
                        waitForCreateRetry(&self.files);
                    },
                }
            }
            unreachable;
        }

        const AtomicRecoveryState = enum {
            clean,
            resume_stage,
            cleanup_backup,
            orphan_backup,
        };

        fn classifyAtomicRecovery(stage_exists: bool, backup_exists: bool, target_exists: bool) AtomicRecoveryState {
            if (stage_exists) return .resume_stage;
            if (!backup_exists) return .clean;
            return if (target_exists) .cleanup_backup else .orphan_backup;
        }

        fn recoverPendingKind(
            self: *Store,
            digest: *const [digest_bytes]u8,
            kind: FileKind,
            expected_size: usize,
        ) BackendError!void {
            const transaction = makePath(self.configuration, digest, .atomic_lock) catch return error.Io;
            try beginAtomicTransaction(self, &transaction);
            var transaction_held = true;
            defer if (transaction_held) {
                _ = abortOwnedPathWithRetryAtStage(self, &transaction, .atomic_release);
            };

            const target = makePath(self.configuration, digest, switch (kind) {
                .sram => .sram,
                .rtc => .rtc,
                .sram_delta => .sram_delta,
            }) catch return error.Io;
            const stage = makePath(self.configuration, digest, switch (kind) {
                .sram => .sram_stage,
                .rtc => .rtc_stage,
                .sram_delta => .delta_stage,
            }) catch return error.Io;
            const backup = makePath(self.configuration, digest, switch (kind) {
                .sram => .sram_backup,
                .rtc => .rtc_backup,
                .sram_delta => .delta_backup,
            }) catch return error.Io;
            try recoverAtomicKind(self, kind, expected_size, &target, &stage, &backup);
            if (!abortOwnedPathWithRetryAtStage(self, &transaction, .atomic_release)) return error.Io;
            transaction_held = false;
        }

        fn recoverAtomicKind(
            self: *Store,
            kind: FileKind,
            expected_size: usize,
            target: *const r4os.AbsoluteFilePath,
            stage: *const r4os.AbsoluteFilePath,
            backup: *const r4os.AbsoluteFilePath,
        ) BackendError!void {
            const stage_size = try pathSizeWithRetry(self, stage, .atomic_recover);
            const stage_exists = stage_size != null;
            const backup_exists = try pathExistsWithRetry(self, backup, .atomic_recover);
            const recovery_target_size = if (!stage_exists and backup_exists)
                try pathSizeVisibleWithRetry(self, target, .atomic_recover)
            else
                null;
            const target_exists = recovery_target_size != null;

            switch (classifyAtomicRecovery(stage_exists, backup_exists, target_exists)) {
                .clean => return,
                .resume_stage => {
                    if (stage_size.? != expected_size) {
                        self.recordFailure(.atomic_recover, r4os.abi.file_stream_error_size_mismatch);
                        return error.Io;
                    }
                    if (kind != .sram) try validateRecordAt(self, kind, stage, .atomic_recover);
                    try replaceAtomicWithRetry(self, target, stage, backup, .atomic_recover);
                    const target_size = try pathSizeVisibleWithRetry(self, target, .atomic_recover);
                    if (target_size == null) {
                        self.recordFailure(.atomic_recover, r4os.r4sys.file_replace_atomic_error_not_found);
                        return error.Io;
                    }
                    if (target_size.? != expected_size) {
                        self.recordFailure(.atomic_recover, r4os.abi.file_stream_error_size_mismatch);
                        return error.Io;
                    }
                    if (kind != .sram) try validateRecordAt(self, kind, target, .atomic_recover);
                    try removeAtomicScratch(self, backup);
                },
                .cleanup_backup => {
                    if (recovery_target_size.? != expected_size) {
                        self.recordFailure(.atomic_recover, r4os.abi.file_stream_error_size_mismatch);
                        return error.Io;
                    }
                    if (kind != .sram) try validateRecordAt(self, kind, target, .atomic_recover);
                    try removeAtomicScratch(self, backup);
                },
                .orphan_backup => {
                    // The backup is the only known durable object. Preserve it for a
                    // later diagnostic/recovery build instead of converting a
                    // metadata failure into permanent save loss.
                    self.recordFailure(.atomic_recover, r4os.r4sys.file_replace_atomic_error_not_found);
                    return error.Io;
                },
            }
        }

        fn pathSizeWithRetry(
            self: *Store,
            path: *const r4os.AbsoluteFilePath,
            failure_stage: FailureStage,
        ) BackendError!?u64 {
            for (0..create_retry_attempts) |attempt| {
                switch (pathShape(&self.files, path.asZ())) {
                    .value => |info| {
                        if (info.is_dir == 0) return info.size;
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_conflict);
                        return error.Io;
                    },
                    .missing => return null,
                    .failure => |fault| {
                        if (attempt + 1 == create_retry_attempts) {
                            self.recordFailure(failure_stage, fault);
                            return mapOpenFault(fault);
                        }
                        waitForCreateRetry(&self.files);
                    },
                }
            }
            unreachable;
        }

        /// A successful atomic replacement can become durable one metadata gate
        /// before an ordinary lookup observes the canonical name. Retry both an I/O
        /// result and a transient Missing result before deciding that no target is
        /// resolvable; the backup stays untouched throughout this window.
        fn pathSizeVisibleWithRetry(
            self: *Store,
            path: *const r4os.AbsoluteFilePath,
            failure_stage: FailureStage,
        ) BackendError!?u64 {
            for (0..create_retry_attempts) |attempt| {
                switch (pathShape(&self.files, path.asZ())) {
                    .value => |info| {
                        if (info.is_dir == 0) return info.size;
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_conflict);
                        return error.Io;
                    },
                    .missing => {
                        if (attempt + 1 == create_retry_attempts) return null;
                        waitForCreateRetry(&self.files);
                    },
                    .failure => |fault| {
                        if (attempt + 1 == create_retry_attempts) {
                            self.recordFailure(failure_stage, fault);
                            return mapOpenFault(fault);
                        }
                        waitForCreateRetry(&self.files);
                    },
                }
            }
            unreachable;
        }

        fn validateRecordAt(
            self: *Store,
            kind: FileKind,
            path: *const r4os.AbsoluteFilePath,
            failure_stage: FailureStage,
        ) BackendError!void {
            const delta_bytes = if (dynamic) self.configuration.delta_record_bytes else if (@hasDecl(Config, "delta_record_bytes")) Config.delta_record_bytes else 0;
            const rtc_bytes = if (dynamic) self.configuration.rtc_record_bytes else Config.rtc_record_bytes;
            var buffer: [if (dynamic) 0 else @max(Config.rtc_record_bytes, if (@hasDecl(Config, "delta_record_bytes")) Config.delta_record_bytes else 0)]u8 = undefined;
            const length = if (kind == .rtc) rtc_bytes else delta_bytes;
            if (length == 0) return error.Unsupported;
            if (dynamic and self.configuration.record_scratch.len < length) return error.Unsupported;
            const encoded = if (dynamic) self.configuration.record_scratch[0..length] else buffer[0..length];
            var offset: usize = 0;
            while (offset < encoded.len) {
                const transferred = read_retry: {
                    for (0..create_retry_attempts) |attempt| {
                        switch (self.files.readAt(path.asZ(), @intCast(offset), encoded[offset..])) {
                            .bytes => |count| break :read_retry count,
                            .end => {
                                self.recordFailure(failure_stage, r4os.abi.file_stream_error_size_mismatch);
                                return error.Io;
                            },
                            .failure => |fault| {
                                if (attempt + 1 == create_retry_attempts) {
                                    self.recordFailure(failure_stage, fault);
                                    return mapOpenFault(fault);
                                }
                                waitForCreateRetry(&self.files);
                            },
                        }
                    }
                    unreachable;
                };
                if (transferred == 0 or transferred > encoded.len - offset) {
                    self.recordFailure(failure_stage, r4os.abi.file_stream_error_size_mismatch);
                    return error.Io;
                }
                offset += transferred;
            }
            const valid = if (dynamic) blk: {
                const validator = (if (kind == .rtc) self.configuration.validate_rtc else self.configuration.validate_delta) orelse break :blk false;
                break :blk validator(self.configuration.context, encoded);
            } else if (kind == .rtc) Config.validateRtc(encoded) else if (@hasDecl(Config, "validateDelta")) Config.validateDelta(encoded) else false;
            if (!valid) {
                self.recordFailure(failure_stage, r4os.abi.file_stream_error_invalid);
                return error.Io;
            }
        }

        fn beginAtomicTransaction(
            self: *Store,
            transaction: *const r4os.AbsoluteFilePath,
        ) BackendError!void {
            try removeAtomicScratch(self, transaction);
            for (0..create_retry_attempts) |attempt| {
                var writer = switch (self.files.ownedCreateWriter(transaction.asZ())) {
                    .writer => |value| value,
                    .failure => |fault| {
                        self.recordFailure(.atomic_begin_create, fault);
                        if (!retryablePrivateStreamFault(fault) or attempt + 1 == create_retry_attempts)
                            return mapOpenFault(fault);

                        // Begin may have published the private lease while losing
                        // its acknowledgement. Abort releases a still-bound slot;
                        // if ownership was already lost, the next lease Begin alone
                        // is allowed to reclaim the transient orphan.
                        if (!abortOwnedPathWithRetryAtStage(self, transaction, .atomic_begin_abort)) return error.Io;
                        self.recordFailure(.atomic_begin_create, fault);
                        waitForCreateRetry(&self.files);
                        continue;
                    },
                };

                const lock_body = "R4OS_SUBSYSTEM_ATOMIC_LOCK=1\n";
                const write_fault: ?i32 = switch (writer.write(lock_body)) {
                    .ok => null,
                    .failure => |fault| fault,
                    .missing => r4os.abi.file_stream_error_not_found,
                };
                if (write_fault) |fault| {
                    self.recordFailure(.atomic_begin_write, fault);
                    if (!abortOwnedPathWithRetryAtStage(self, transaction, .atomic_begin_abort)) return error.Io;
                    self.recordFailure(.atomic_begin_write, fault);
                    if (!retryablePrivateStreamFault(fault) or attempt + 1 == create_retry_attempts)
                        return mapOpenFault(fault);
                    waitForCreateRetry(&self.files);
                    continue;
                }

                const finish_fault: ?i32 = switch (writer.finishKeepOwnership()) {
                    .ok => return,
                    .failure => |fault| fault,
                    .missing => r4os.abi.file_stream_error_not_found,
                };
                const fault = finish_fault.?;
                self.recordFailure(.atomic_begin_finish, fault);
                if (!abortOwnedPathWithRetryAtStage(self, transaction, .atomic_begin_abort)) return error.Io;
                self.recordFailure(.atomic_begin_finish, fault);
                if (!retryablePrivateStreamFault(fault) or attempt + 1 == create_retry_attempts)
                    return mapOpenFault(fault);
                waitForCreateRetry(&self.files);
            }
            unreachable;
        }

        fn pathExistsWithRetry(
            self: *Store,
            path: *const r4os.AbsoluteFilePath,
            failure_stage: FailureStage,
        ) BackendError!bool {
            for (0..create_retry_attempts) |attempt| {
                switch (pathShape(&self.files, path.asZ())) {
                    .value => |info| {
                        if (info.is_dir == 0) return true;
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_conflict);
                        return error.Io;
                    },
                    .missing => return false,
                    .failure => |fault| {
                        if (attempt + 1 == create_retry_attempts) {
                            self.recordFailure(failure_stage, fault);
                            return mapOpenFault(fault);
                        }
                        waitForCreateRetry(&self.files);
                    },
                }
            }
            unreachable;
        }

        fn replaceAtomicWithRetry(
            self: *Store,
            target: *const r4os.AbsoluteFilePath,
            stage: *const r4os.AbsoluteFilePath,
            backup: *const r4os.AbsoluteFilePath,
            failure_stage: FailureStage,
        ) BackendError!void {
            for (0..create_retry_attempts) |attempt| {
                switch (self.files.replaceAtomic(target.asZ(), stage.asZ(), backup.asZ(), .{})) {
                    .ok => return,
                    .unsupported => {
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_unsupported);
                        return error.Unsupported;
                    },
                    .conflict => {
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_conflict);
                        return error.Busy;
                    },
                    .missing => {
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_not_found);
                        return error.Io;
                    },
                    .bad_path => {
                        self.recordFailure(failure_stage, r4os.r4sys.file_replace_atomic_error_bad_path);
                        return error.Io;
                    },
                    .failure => |fault| {
                        if (fault != r4os.r4sys.file_replace_atomic_error_io or attempt + 1 == create_retry_attempts) {
                            self.recordFailure(failure_stage, fault);
                            return error.Io;
                        }
                        waitForCreateRetry(&self.files);
                    },
                }
            }
            unreachable;
        }

        /// Exposes only the two durable data names for product diagnostics. Atomic
        /// staging, backups and writer leases remain private implementation details.
        pub const dataPath = if (dynamic) dataPathConfigured else dataPathStatic;
        fn dataPathStatic(digest: *const [digest_bytes]u8, kind: FileKind) !r4os.AbsoluteFilePath {
            return dataPathWithConfig({}, digest, kind);
        }
        fn dataPathConfigured(configuration: *const Configuration, digest: *const [digest_bytes]u8, kind: FileKind) !r4os.AbsoluteFilePath {
            return dataPathWithConfig(configuration, digest, kind);
        }
        fn dataPathWithConfig(configuration: ConfigView, digest: *const [digest_bytes]u8, kind: FileKind) !r4os.AbsoluteFilePath {
            return makePath(configuration, digest, switch (kind) {
                .sram => .sram,
                .rtc => .rtc,
                .sram_delta => .sram_delta,
            });
        }

        fn ensureSaveRoot(configuration: ConfigView, files: *const r4os.app_storage.Files) BackendError!void {
            if (dynamic and !configuration.valid()) return error.Unsupported;
            for (if (dynamic) configuration.root_directories else Config.root_directories) |raw| {
                const path = r4os.AbsoluteFilePath.parse(raw) catch return error.Io;
                var visible = false;
                for (0..create_retry_attempts) |attempt| {
                    _ = files.createDirectory(path.asZ());
                    visible = switch (pathShape(files, path.asZ())) {
                        .value => |info| info.is_dir != 0,
                        .missing, .failure => false,
                    };
                    if (visible) break;
                    if (attempt + 1 != create_retry_attempts) waitForCreateRetry(files);
                }
                if (!visible) return error.Io;
            }
        }

        fn createOwnedLock(
            self: *Store,
            path: *const r4os.AbsoluteFilePath,
            generation: u64,
        ) BackendError!r4os.app_storage.OwnedStageWriter {
            var writer = switch (self.files.ownedCreateWriter(path.asZ())) {
                .writer => |value| value,
                .failure => |fault| {
                    self.recordFailure(.lock_begin, fault);
                    if (fault == r4os.abi.file_stream_error_io and !abortOwnedPathWithRetry(self, path)) return error.Io;
                    return mapOpenFault(fault);
                },
            };

            var body: [96]u8 = undefined;
            const lock_body = std.fmt.bufPrint(body[0..], "R4OS_SUBSYSTEM_SAVE_LOCK=1\nGENERATION={d}\n", .{generation}) catch {
                if (!abortOwnedPathWithRetry(self, path)) return error.Io;
                return error.Io;
            };
            switch (writer.write(lock_body)) {
                .ok => {},
                .failure => |fault| {
                    self.recordFailure(.lock_write, fault);
                    if (!abortOwnedPathWithRetry(self, path)) return error.Io;
                    return mapOpenFault(fault);
                },
                .missing => {
                    self.recordFailure(.lock_write, 0);
                    if (!abortOwnedPathWithRetry(self, path)) return error.Io;
                    return error.Io;
                },
            }
            switch (writer.finishKeepOwnership()) {
                .ok => {},
                .failure => |fault| {
                    self.recordFailure(.lock_finish, fault);
                    if (!abortOwnedPathWithRetry(self, path)) return error.Io;
                    return mapOpenFault(fault);
                },
                .missing => {
                    self.recordFailure(.lock_finish, 0);
                    if (!abortOwnedPathWithRetry(self, path)) return error.Io;
                    return error.Io;
                },
            }
            return writer;
        }

        /// A failed stream operation may have crossed its namespace visibility point
        /// while losing the acknowledgement. Abort is ownership-checked by R4SYS, so
        /// bounded retries can retire only this process' exact lease before Begin is
        /// attempted again; a competing cartridge instance is never deleted by path.
        fn abortOwnedPathWithRetry(self: *Store, path: *const r4os.AbsoluteFilePath) bool {
            return abortOwnedPathWithRetryAtStage(self, path, .lock_abort);
        }

        fn abortOwnedPathWithRetryAtStage(
            self: *Store,
            path: *const r4os.AbsoluteFilePath,
            failure_stage: FailureStage,
        ) bool {
            for (0..create_retry_attempts) |attempt| {
                const raw = self.files.sys.fileStreamAbort(path.asZ().ptr);
                if (raw == r4os.abi.file_stream_result_ok or raw == r4os.abi.file_stream_error_not_found) return true;
                if (raw != r4os.abi.file_stream_error_io or attempt + 1 == create_retry_attempts) {
                    self.recordFailure(failure_stage, raw);
                    return false;
                }
                waitForCreateRetry(&self.files);
            }
            unreachable;
        }

        fn waitForCreateRetry(files: *const r4os.app_storage.Files) void {
            const delay = @max(@as(u64, 1), files.sys.ticksFromMilliseconds(create_retry_delay_ms));
            files.sys.sleepTicks(delay);
        }

        fn makePath(configuration: ConfigView, digest: *const [digest_bytes]u8, role: PathRole) !r4os.AbsoluteFilePath {
            if (dynamic and !configuration.valid()) return error.Unsupported;
            const save_root = if (dynamic) configuration.save_root else Config.save_root;
            if (role == .atomic_lock or role == .sram_stage or role == .rtc_stage or role == .sram_backup or role == .rtc_backup or role == .delta_stage or role == .delta_backup) {
                var token: [10]u8 = undefined;
                makeAtomicToken(digest, &token);
                const discriminator: u8 = switch (role) {
                    .atomic_lock => 'L',
                    .sram_stage => 'N',
                    .sram_backup => 'B',
                    .rtc_stage => 'T',
                    .rtc_backup => 'R',
                    .delta_stage => 'D',
                    .delta_backup => 'E',
                    else => unreachable,
                };
                var short_raw: [160]u8 = undefined;
                const rendered = try std.fmt.bufPrint(short_raw[0..], "{s}{s}.{c}{s}", .{
                    save_root,
                    token[0..8],
                    discriminator,
                    token[8..10],
                });
                return r4os.AbsoluteFilePath.parse(rendered);
            }

            var digest_text: [digest_hex_bytes]u8 = undefined;
            const hash = digestHex(digest, &digest_text);
            const suffix = switch (role) {
                .sram => ".SAV",
                .rtc => ".RTC",
                .sram_delta => ".SDJ",
                .delta_stage => unreachable,
                .delta_backup => unreachable,
                .lock => ".LCK",
                .atomic_lock => unreachable,
                .sram_stage => ".SAV.NEW",
                .rtc_stage => ".RTC.NEW",
                .sram_backup => ".SAV.BAK",
                .rtc_backup => ".RTC.BAK",
            };
            var raw: [192]u8 = undefined;
            const rendered = try std.fmt.bufPrint(raw[0..], "{s}{s}{s}", .{ save_root, hash, suffix });
            return r4os.AbsoluteFilePath.parse(rendered);
        }

        /// R4SYS's no-fallback atomic primitive deliberately requires private stage
        /// and backup basenames to fit 8.3. Ten Base32 digits retain 50 digest bits;
        /// the role discriminator makes transaction names distinct. A retained
        /// create-only `.Lxx` lease serializes the compressed namespace, so even a
        /// rare 50-bit collision fails closed before either stage can be touched.
        fn makeAtomicToken(digest: *const [digest_bytes]u8, out: *[10]u8) void {
            const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
            var accumulator: u64 = 0;
            for (digest[0..7]) |byte| accumulator = (accumulator << 8) | byte;
            accumulator >>= 6;
            for (0..out.len) |index| {
                const shift: u6 = @intCast((out.len - index - 1) * 5);
                out[index] = alphabet[@as(usize, @intCast((accumulator >> shift) & 0x1F))];
            }
        }

        fn mapOpenFault(fault: i32) BackendError {
            return switch (fault) {
                r4os.abi.file_stream_error_exists => error.Busy,
                r4os.abi.file_stream_error_unsupported => error.Unsupported,
                r4os.abi.file_stream_error_too_large => error.Full,
                else => error.Io,
            };
        }

        pub fn wallSeconds(state: r4os.abi.TimeState) ?i64 {
            if (state.valid == 0 or state.month < 1 or state.month > 12 or state.hour > 23 or state.minute > 59 or state.second > 60) return null;
            const month_days = [_]u8{ 31, if (isLeap(state.year)) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
            if (state.day < 1 or state.day > month_days[state.month - 1]) return null;
            const year: i64 = state.year;
            const month: i64 = state.month;
            const day: i64 = state.day;
            const adjusted_year = year - @intFromBool(month <= 2);
            const era = @divFloor(adjusted_year, 400);
            const year_of_era = adjusted_year - era * 400;
            const adjusted_month = month + (if (month > 2) @as(i64, -3) else 9);
            const day_of_year = @divFloor(153 * adjusted_month + 2, 5) + day - 1;
            const day_of_era = year_of_era * 365 + @divFloor(year_of_era, 4) - @divFloor(year_of_era, 100) + day_of_year;
            const days = era * 146097 + day_of_era - 719468;
            return days * 86400 + @as(i64, state.hour) * 3600 + @as(i64, state.minute) * 60 + state.second;
        }

        fn isLeap(year: u16) bool {
            return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0);
        }

        test "canonical save path stays below the installed subsystem" {
            if (dynamic) return;
            const digest = [_]u8{0xAB} ** digest_bytes;
            const canonical = try dataPath(&digest, .sram);

            try std.testing.expect(std.mem.startsWith(u8, canonical.bytes(), Config.save_root));
            try std.testing.expect(std.mem.endsWith(u8, canonical.bytes(), ".SAV"));
            try std.testing.expect(std.mem.indexOf(u8, canonical.bytes(), "\\APPDATA\\") == null);

            // Exercise the real recovery size lookup, not a shortened name:
            // 64hex+.SAV and a wide backend node cannot become FileInfo.
            const p2 = @import("platform2.zig");
            const Peer = struct {
                var flags: u32 = 0;
                fn metadata(_: [*:0]const u8, out: *r4os.abi.FileMetadata2) callconv(.c) i32 {
                    out.* = .{ .flags = flags, .byte_size = 4, .backend_node = @as(u64, 1) << 40 };
                    return 1;
                }
            };
            Peer.flags = r4os.abi.file_metadata2_flag_exists | r4os.abi.file_metadata2_flag_byte_size_valid |
                r4os.abi.file_metadata2_flag_backend_node_valid;
            var sys: p2.abi.R4XStartR4Sys2 = .{};
            sys.file_metadata2 = @intFromPtr(&Peer.metadata);
            var imports = [_]r4os.abi.R4XStartImport{.{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) }};
            var start: p2.abi.R4XStartContext2 = .{ .imports = @intFromPtr(&imports), .import_count = imports.len };
            const context = try p2.Context.init(&start);
            const files = storage.Files{ .sys = system.Context.fromProgram(.{ .generation2 = &context }) };
            try std.testing.expectEqual(r4os.abi.file_metadata2_error_unsupported, files.info(canonical.asZ()).failure);
            var store = Store.init(files);
            try std.testing.expectEqual(@as(?u64, 4), try pathSizeWithRetry(&store, &canonical, .sram_info));
            Peer.flags = r4os.abi.file_metadata2_flag_exists;
            if (pathSizeWithRetry(&store, &canonical, .sram_info)) |_| {
                return error.UnknownSizeAccepted;
            } else |_| {}
            try std.testing.expectEqual(FailureStage.sram_info, store.failure_stage);
            try std.testing.expectEqual(r4os.abi.file_metadata2_error_unsupported, store.failure_code);
        }

        test "atomic recovery never removes an orphaned last-good backup" {
            try std.testing.expectEqual(AtomicRecoveryState.clean, classifyAtomicRecovery(false, false, false));
            try std.testing.expectEqual(AtomicRecoveryState.resume_stage, classifyAtomicRecovery(true, false, false));
            try std.testing.expectEqual(AtomicRecoveryState.resume_stage, classifyAtomicRecovery(true, true, false));
            try std.testing.expectEqual(AtomicRecoveryState.cleanup_backup, classifyAtomicRecovery(false, true, true));
            try std.testing.expectEqual(AtomicRecoveryState.orphan_backup, classifyAtomicRecovery(false, true, false));
        }

        test "private stream retries are limited to transient namespace outcomes" {
            try std.testing.expect(retryablePrivateStreamFault(r4os.abi.file_stream_error_not_found));
            try std.testing.expect(retryablePrivateStreamFault(r4os.abi.file_stream_error_io));
            try std.testing.expect(!retryablePrivateStreamFault(r4os.abi.file_stream_error_invalid));
            try std.testing.expect(!retryablePrivateStreamFault(r4os.abi.file_stream_error_exists));
            try std.testing.expect(!retryablePrivateStreamFault(r4os.abi.file_stream_error_size_mismatch));
            try std.testing.expect(!retryablePrivateStreamFault(r4os.abi.file_stream_error_too_large));
        }
    };
}
