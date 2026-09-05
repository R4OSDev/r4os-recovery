const abi = @import("r4os_contract").abi;
const path_contract = @import("path.zig");
const r4sys = @import("r4sys.zig");
const time_contract = @import("time_contract.zig");

pub const PathZ = path_contract.PathZ;
pub const Timeout = time_contract.Timeout;

pub const ProcessOpen = union(enum) {
    process: ProcessHandle,
    failure: i32,
};

pub const ProcessInfo = union(enum) {
    value: abi.ProgramInstanceInfo,
    missing,
    failure: i32,
};

pub const ProcessWait = union(enum) {
    exited: i32,
    would_block,
    timed_out,
    failure: i32,
};

pub const ProcessReady = union(enum) {
    ready: abi.ProgramProcessCompletion,
    would_block,
    timed_out,
    failure: i32,
};

pub const ProcessRead = union(enum) {
    bytes: u32,
    would_block,
    failure: i32,
};

pub const JoinOpen = union(enum) {
    handle: JoinHandle,
    failure: i32,
};

pub const ThreadInfo = union(enum) {
    value: abi.ProgramThreadInfo,
    failure: i32,
};

pub const JoinWait = union(enum) {
    exited: i32,
    timed_out,
    failure: i32,
};

pub const VmOpen = union(enum) {
    region: VmRegion,
    failure: i32,
};

pub const VmInfo = union(enum) {
    value: abi.ProgramVmRegionInfo,
    failure: i32,
};

pub const IoOpen = union(enum) {
    request: IoRequest,
    failure: i32,
};

pub const IoInfo = union(enum) {
    value: abi.ProgramIoInfo,
    failure: i32,
};

pub const IoWait = union(enum) {
    completed: abi.ProgramIoInfo,
    timed_out,
    failure: i32,
};

pub const Resources = struct {
    sys: r4sys.Context,

    pub fn available(self: *const Resources) bool {
        return self.sys.hasFn("program_spawn_handle") and self.sys.hasFn("program_open_handle") and
            self.sys.hasFn("program_handle_status") and self.sys.hasFn("program_handle_request_close") and
            self.sys.hasFn("program_handle_kill") and self.sys.hasFn("program_handle_wait") and
            self.sys.hasFn("program_handle_reap") and self.sys.hasFn("program_completion_read") and
            self.sys.hasFn("thread_create_handle") and self.sys.hasFn("thread_handle_join") and
            self.sys.hasFn("thread_handle_status") and self.sys.hasFn("vm_reserve") and
            self.sys.hasFn("vm_release") and self.sys.hasFn("io_wait") and
            self.sys.hasFn("io_close");
    }

    pub fn spawn(self: *const Resources, path: PathZ, args: [*:0]const u8, policy: abi.LaunchPolicy) ProcessOpen {
        var handle: abi.ProgramProcessHandle = .{};
        const status = self.sys.programSpawnHandle(path.ptr, args, policy, &handle);
        if (status != abi.program_handle_ok) return .{ .failure = status };
        return .{ .process = ProcessHandle.fromAbi(self.sys, handle, true) };
    }

    pub fn spawnWithConsoleHost(self: *const Resources, path: PathZ, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind) ProcessOpen {
        var handle: abi.ProgramProcessHandle = .{};
        const status = self.sys.programSpawnWithConsoleHostHandle(path.ptr, args, policy, host, &handle);
        if (status != abi.program_handle_ok) return .{ .failure = status };
        return .{ .process = ProcessHandle.fromAbi(self.sys, handle, true) };
    }

    pub fn openProcess(self: *const Resources, instance_id: u32) ProcessOpen {
        if (instance_id == 0) return .{ .failure = abi.program_handle_error_invalid };
        var handle: abi.ProgramProcessHandle = .{};
        const status = self.sys.programOpenHandle(instance_id, &handle);
        if (status != abi.program_handle_ok) return .{ .failure = status };
        return .{ .process = ProcessHandle.fromAbi(self.sys, handle, false) };
    }

    pub fn createThread(self: *const Resources, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64) JoinOpen {
        var handle: abi.ProgramJoinHandle = .{};
        const raw = self.sys.threadCreateHandle(entry, arg, stack_reserve_bytes, 0, &handle);
        if (raw != abi.thread_ok) return .{ .failure = raw };
        return .{ .handle = .{ .sys = self.sys, .handle = handle, .owned = true } };
    }

    pub fn reserveVm(self: *const Resources, size: u64, alignment: u64, flags: u64) VmOpen {
        var info: abi.ProgramVmRegionInfo = .{};
        const raw = self.sys.vmReserveRaw(size, alignment, flags, &info);
        if (raw != abi.vm_ok) return .{ .failure = raw };
        return .{ .region = .{ .sys = self.sys, .raw = info.id, .owned = true, .last_info = info } };
    }

    pub fn asyncRead(self: *const Resources, path: PathZ, out: []u8, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileRead(path.ptr, out, flags, &id);
        return self.ioOpen(raw, id, .{ .mutable = out });
    }

    pub fn asyncReadAt(self: *const Resources, path: PathZ, offset: u64, out: []u8, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileReadAt(path.ptr, offset, out, flags, &id);
        return self.ioOpen(raw, id, .{ .mutable = out });
    }

    pub fn asyncWrite(self: *const Resources, path: PathZ, data: []const u8, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileWrite(path.ptr, data, flags, &id);
        return self.ioOpen(raw, id, .{ .read_only = data });
    }

    pub fn asyncAppend(self: *const Resources, path: PathZ, data: []const u8, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileAppend(path.ptr, data, flags, &id);
        return self.ioOpen(raw, id, .{ .read_only = data });
    }

    pub fn asyncWriteAt(self: *const Resources, path: PathZ, offset: u64, data: []const u8, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileWriteAt(path.ptr, offset, data, flags, &id);
        return self.ioOpen(raw, id, .{ .read_only = data });
    }

    pub fn asyncFileInfo(self: *const Resources, path: PathZ, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileInfo(path.ptr, flags, &id);
        return self.ioOpen(raw, id, .none);
    }

    pub fn asyncFileLock(self: *const Resources, path: PathZ, offset: u64, length: u64, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileLock(path.ptr, offset, length, flags, &id);
        return self.ioOpen(raw, id, .none);
    }

    pub fn asyncStreamBegin(self: *const Resources, path: PathZ, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileStreamBegin(path.ptr, flags, &id);
        return self.ioOpen(raw, id, .none);
    }

    pub fn asyncStreamWrite(self: *const Resources, path: PathZ, offset: u64, data: []const u8, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileStreamWrite(path.ptr, offset, data, flags, &id);
        return self.ioOpen(raw, id, .{ .read_only = data });
    }

    pub fn asyncStreamFinish(self: *const Resources, path: PathZ, expected_size: u64, flags: u32) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileStreamFinish(path.ptr, expected_size, flags, &id);
        return self.ioOpen(raw, id, .none);
    }

    pub fn asyncStreamAbort(self: *const Resources, path: PathZ) IoOpen {
        var id: u32 = 0;
        const raw = self.sys.ioFileStreamAbort(path.ptr, &id);
        return self.ioOpen(raw, id, .none);
    }

    fn ioOpen(self: *const Resources, raw: i32, id: u32, binding: IoBufferBinding) IoOpen {
        if (raw != abi.io_ok) return .{ .failure = raw };
        return .{ .request = .{ .sys = self.sys, .raw = id, .owned = true, .binding = binding } };
    }
};

pub const ProcessHandle = struct {
    sys: r4sys.Context,
    raw: u32 = 0,
    owned: bool = false,
    generation: u64 = 0,
    handle_reserved: u32 = 0,
    extension_reserved: u32 = 0,

    fn fromAbi(sys: r4sys.Context, handle: abi.ProgramProcessHandle, owned: bool) ProcessHandle {
        return .{
            .sys = sys,
            .raw = handle.instance_id,
            .owned = owned,
            .generation = handle.generation,
            .handle_reserved = handle.reserved,
        };
    }

    fn abiHandle(self: *const ProcessHandle) abi.ProgramProcessHandle {
        return .{
            .instance_id = self.raw,
            .reserved = self.handle_reserved,
            .generation = self.generation,
        };
    }

    fn invalidate(self: *ProcessHandle) void {
        self.raw = 0;
        self.generation = 0;
        self.handle_reserved = 0;
        self.extension_reserved = 0;
    }

    pub fn valid(self: *const ProcessHandle) bool {
        return self.raw != 0 and self.generation != 0 and self.handle_reserved == 0 and self.extension_reserved == 0;
    }

    pub fn instanceId(self: *const ProcessHandle) u32 {
        return self.raw;
    }

    pub fn status(self: *const ProcessHandle) ProcessInfo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var info: abi.ProgramInstanceInfo = .{};
        const handle = self.abiHandle();
        const status_code = self.sys.programHandleStatus(&handle, &info);
        if (status_code == abi.program_handle_error_not_found) return .missing;
        if (status_code != abi.program_handle_ok) return .{ .failure = status_code };
        return .{ .value = info };
    }

    pub fn requestClose(self: *ProcessHandle) i32 {
        if (!self.valid()) return abi.err_closed;
        const handle = self.abiHandle();
        return self.sys.programHandleRequestClose(&handle);
    }

    pub fn kill(self: *ProcessHandle) i32 {
        if (!self.valid()) return abi.err_closed;
        const handle = self.abiHandle();
        return self.sys.programHandleKill(&handle);
    }

    pub fn waitReady(self: *ProcessHandle, timeout: Timeout) ProcessReady {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const timeout_ticks = time_contract.timeoutToTicks(timeout, self.sys.monotonicHz()) catch return .{ .failure = abi.program_handle_error_invalid };
        var completion: abi.ProgramProcessCompletion = .{};
        const handle = self.abiHandle();
        const status_code = self.sys.programHandleWait(&handle, timeout_ticks, &completion);
        if (status_code == abi.program_handle_error_timeout) return .timed_out;
        if (status_code == abi.program_handle_error_would_block) return .would_block;
        if (status_code != abi.program_handle_ok) return .{ .failure = status_code };
        return .{ .ready = completion };
    }

    pub fn completionRead(self: *const ProcessHandle, offset: u32, out: []u8) ProcessRead {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var read: u32 = 0;
        const handle = self.abiHandle();
        const status_code = self.sys.programCompletionRead(&handle, offset, out, &read);
        if (status_code == abi.program_handle_error_would_block) return .would_block;
        if (status_code != abi.program_handle_ok) return .{ .failure = status_code };
        return .{ .bytes = read };
    }

    pub fn reap(self: *ProcessHandle) ProcessWait {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        var completion: abi.ProgramProcessCompletion = .{};
        const handle = self.abiHandle();
        const status_code = self.sys.programHandleReap(&handle, &completion);
        if (status_code == abi.program_handle_error_would_block) return .would_block;
        if (status_code != abi.program_handle_ok) return .{ .failure = status_code };
        self.invalidate();
        return .{ .exited = completion.exit_code };
    }

    pub fn wait(self: *ProcessHandle, timeout: Timeout) ProcessWait {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        return switch (self.waitReady(timeout)) {
            .ready => self.reap(),
            .would_block => .would_block,
            .timed_out => .timed_out,
            .failure => |status_code| .{ .failure = status_code },
        };
    }
};

pub const JoinHandle = struct {
    sys: r4sys.Context,
    handle: abi.ProgramJoinHandle = .{},
    owned: bool = false,

    pub fn valid(self: *const JoinHandle) bool {
        return self.handle.thread_id != 0 and
            self.handle.instance_id != 0 and
            self.handle.thread_generation != 0 and
            self.handle.instance_generation != 0 and
            self.handle.reserved == 0;
    }

    pub fn status(self: *const JoinHandle) ThreadInfo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var info: abi.ProgramThreadInfo = .{};
        const raw_code = self.sys.threadHandleStatus(&self.handle, &info);
        if (raw_code != abi.thread_ok) return .{ .failure = raw_code };
        return .{ .value = info };
    }

    pub fn join(self: *JoinHandle, timeout: Timeout) JoinWait {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        if (!self.owned) return .{ .failure = abi.err_not_owned };
        const ticks = time_contract.timeoutToTicks(timeout, self.sys.monotonicHz()) catch return .{ .failure = abi.thread_error_invalid };
        var exit_code: i32 = 0;
        const raw_code = self.sys.threadHandleJoin(&self.handle, ticks, &exit_code);
        if (raw_code == abi.thread_error_timeout) return .timed_out;
        if (raw_code == abi.thread_error_not_found) {
            self.handle = .{};
            return .{ .failure = abi.err_closed };
        }
        if (raw_code != abi.thread_ok) return .{ .failure = raw_code };
        self.handle = .{};
        return .{ .exited = exit_code };
    }
};

pub const VmRegion = struct {
    sys: r4sys.Context,
    raw: u32 = 0,
    owned: bool = false,
    last_info: abi.ProgramVmRegionInfo = .{},

    pub fn valid(self: *const VmRegion) bool {
        return self.raw != 0;
    }

    pub fn info(self: *VmRegion) VmInfo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var current: abi.ProgramVmRegionInfo = .{};
        const raw_code = self.sys.vmQueryRaw(self.raw, &current);
        if (raw_code != abi.vm_ok) return .{ .failure = raw_code };
        self.last_info = current;
        return .{ .value = current };
    }

    pub fn commit(self: *VmRegion, offset: u64, len: u64) i32 {
        if (!self.valid()) return abi.err_closed;
        return self.sys.vmCommit(self.raw, offset, len);
    }

    pub fn decommit(self: *VmRegion, offset: u64, len: u64) i32 {
        if (!self.valid()) return abi.err_closed;
        return self.sys.vmDecommit(self.raw, offset, len);
    }

    pub fn release(self: *VmRegion) i32 {
        if (!self.valid()) return abi.err_closed;
        if (!self.owned) return abi.err_not_owned;
        const raw_code = self.sys.vmRelease(self.raw);
        if (raw_code == abi.vm_ok) {
            self.raw = 0;
            self.last_info = .{};
            return raw_code;
        }
        if (raw_code == abi.vm_error_invalid_range) {
            self.raw = 0;
            self.last_info = .{};
            return abi.err_closed;
        }
        return raw_code;
    }
};

pub const IoBufferBinding = union(enum) {
    none,
    mutable: []u8,
    read_only: []const u8,
};

pub const IoRequest = struct {
    sys: r4sys.Context,
    raw: u32 = 0,
    owned: bool = false,
    binding: IoBufferBinding = .none,
    last_info: abi.ProgramIoInfo = .{},

    pub fn valid(self: *const IoRequest) bool {
        return self.raw != 0;
    }

    pub fn buffersHeld(self: *const IoRequest) bool {
        if (!self.valid()) return false;
        return switch (self.binding) {
            .none => false,
            .mutable, .read_only => true,
        };
    }

    pub fn releaseBuffers(self: *IoRequest) i32 {
        if (self.buffersHeld()) return abi.err_buffer_in_use;
        self.binding = .none;
        return abi.io_ok;
    }

    pub fn status(self: *IoRequest) IoInfo {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        var info: abi.ProgramIoInfo = .{};
        const raw_code = self.sys.ioStatus(self.raw, &info);
        if (raw_code != abi.io_ok) return .{ .failure = raw_code };
        self.last_info = info;
        return .{ .value = info };
    }

    pub fn wait(self: *IoRequest, timeout: Timeout) IoWait {
        if (!self.valid()) return .{ .failure = abi.err_closed };
        const ticks = time_contract.timeoutToTicks(timeout, self.sys.monotonicHz()) catch return .{ .failure = abi.io_error_invalid };
        var info: abi.ProgramIoInfo = .{};
        const raw_code = self.sys.ioWait(self.raw, ticks, &info);
        if (raw_code == abi.io_error_timeout) return .timed_out;
        if (raw_code != abi.io_ok) return .{ .failure = raw_code };
        self.last_info = info;
        return .{ .completed = info };
    }

    pub fn close(self: *IoRequest) i32 {
        if (!self.valid()) return abi.err_closed;
        if (!self.owned) return abi.err_not_owned;
        const raw_code = self.sys.ioClose(self.raw);
        if (raw_code == abi.io_ok) {
            self.raw = 0;
            self.binding = .none;
            return raw_code;
        }
        if (raw_code == abi.io_error_not_found) {
            self.raw = 0;
            self.binding = .none;
            return abi.err_closed;
        }
        return raw_code;
    }
};
