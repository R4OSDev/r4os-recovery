const abi = @import("r4os_contract").abi;
const program = @import("program.zig");
const r4sys = @import("r4sys.zig");
const r4desk = @import("r4desk.zig");
const r4draw = @import("r4draw.zig");
const r4net = @import("r4net.zig");
const r4audio = @import("r4audio.zig");
const r4dev = @import("r4dev.zig");
const storage = @import("app_storage.zig");
const resource_facade = @import("app_resources.zig");
const service_facade = @import("app_services.zig");
const tray_facade = @import("app_tray.zig");
const network_facade = @import("app_network.zig");
const audio_facade = @import("app_audio.zig");
const device_facade = @import("app_devices.zig");
const web_facade = @import("app_web.zig");

pub const ErrorDomain = abi.R4ErrorDomain;
pub const Timeout = abi.R4Timeout;
pub const StopFlagStorage = abi.R4StopFlag;

pub const WaitState = enum(u8) {
    completed = abi.wait_state_completed,
    would_block = abi.wait_state_would_block,
    timed_out = abi.wait_state_timed_out,
    cancelled = abi.wait_state_cancelled,
    failed = abi.wait_state_failed,
};

pub const ServiceStopPolicy = program.ServiceStopPolicy;

pub const StopFlag = struct {
    storage: StopFlagStorage = .{},

    pub fn request(self: *StopFlag) void {
        @atomicStore(u32, &self.storage.value, 1, .release);
    }

    pub fn requested(self: *const StopFlag) bool {
        return @atomicLoad(u32, &self.storage.value, .acquire) != 0;
    }
};

pub fn classifyWait(raw_code: i32, timeout_code: i32, cancelled_code: i32, would_block_code: i32) WaitState {
    if (raw_code >= 0) return .completed;
    if (raw_code == timeout_code) return .timed_out;
    if (raw_code == cancelled_code) return .cancelled;
    if (raw_code == would_block_code) return .would_block;
    return .failed;
}

pub const SideEffectState = enum(u8) {
    none,
    atomic_success,
    confirmed_progress,
    may_have_occurred,
};

pub const Failure = struct {
    domain: ErrorDomain,
    raw_code: i32,
    progress: ?u64 = null,
    required_size: ?u64 = null,
    side_effects: SideEffectState = .none,

    pub fn fromRaw(domain: ErrorDomain, raw_code: i32) Failure {
        return .{ .domain = domain, .raw_code = raw_code };
    }
};

pub fn Outcome(comptime T: type) type {
    return union(enum) {
        value: T,
        failure: Failure,

        pub fn succeeded(self: @This()) bool {
            return switch (self) {
                .value => true,
                .failure => false,
            };
        }
    };
}

pub const AppProfile = abi.R4AppProfile;
pub const AppEntryFn = *const fn (*App) i32;

pub const App = @import("app2.zig").App;

pub fn Handle(comptime Tag: type, comptime Raw: type, comptime invalid: Raw) type {
    return struct {
        pub const tag_type = Tag;
        pub const raw_type = Raw;
        raw: Raw = invalid,
        owned: bool = false,

        pub fn ownedValue(raw: Raw) @This() {
            return .{ .raw = raw, .owned = true };
        }

        pub fn borrowedValue(raw: Raw) @This() {
            return .{ .raw = raw, .owned = false };
        }

        pub fn valid(self: *const @This()) bool {
            return self.raw != invalid;
        }

        pub fn applyCloseResult(self: *@This(), raw_code: i32) i32 {
            if (self.owned and raw_code >= 0) self.raw = invalid;
            return raw_code;
        }
    };
}

pub const ProgramTag = opaque {};
pub const ThreadTag = opaque {};
pub const IoRequestTag = opaque {};
pub const ServiceTag = opaque {};
pub const ServiceEndpointTag = opaque {};
pub const VmRegionTag = opaque {};
pub const WindowTag = opaque {};
pub const TcpConnectionTag = opaque {};
pub const IpcChannelTag = opaque {};
pub const AudioStreamTag = opaque {};
pub const SidSessionTag = opaque {};
pub const MidiSynthTag = opaque {};

pub const ProgramHandle = Handle(ProgramTag, u32, 0);
pub const ThreadHandle = Handle(ThreadTag, u32, 0);
pub const IoRequestHandle = Handle(IoRequestTag, u32, 0);
pub const ServiceHandle = Handle(ServiceTag, u32, 0);
pub const ServiceEndpointHandle = Handle(ServiceEndpointTag, u32, 0);
pub const VmRegionHandle = Handle(VmRegionTag, u32, 0);
pub const WindowHandle = Handle(WindowTag, i32, -1);
pub const TcpConnectionHandle = Handle(TcpConnectionTag, u32, 0);
pub const IpcChannelHandle = Handle(IpcChannelTag, u32, 0);
pub const AudioStreamHandle = Handle(AudioStreamTag, u32, 0);
pub const SidSessionHandle = Handle(SidSessionTag, u32, 0);
pub const MidiSynthHandle = Handle(MidiSynthTag, u32, 0);

comptime {
    if (@sizeOf(ErrorDomain) != 2) @compileError("ErrorDomain layout drift");
    if (@sizeOf(SideEffectState) != 1) @compileError("SideEffectState layout drift");
    if (@sizeOf(StopFlagStorage) != 4) @compileError("StopFlagStorage layout drift");
}

test "stop flag is cooperative and atomic" {
    var flag: StopFlag = .{};
    try @import("std").testing.expect(!flag.requested());
    flag.request();
    try @import("std").testing.expect(flag.requested());
}

test "wait classification preserves raw domain outside the classification" {
    try @import("std").testing.expectEqual(WaitState.timed_out, classifyWait(-8, -8, -9, -10));
    try @import("std").testing.expectEqual(WaitState.cancelled, classifyWait(-9, -8, -9, -10));
    try @import("std").testing.expectEqual(WaitState.would_block, classifyWait(-10, -8, -9, -10));
    try @import("std").testing.expectEqual(WaitState.failed, classifyWait(-11, -8, -9, -10));
}
