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

pub const App = struct {
    raw: *const abi.R4XStartContext,
    bundle: program.Bundle,
    profile: AppProfile,

    pub fn init(raw: *const abi.R4XStartContext, profile: AppProfile) Outcome(App) {
        const bundle = program.bundleValueFromR4XStart(raw) orelse return .{ .failure = .{
            .domain = .contract,
            .raw_code = abi.err_no_group,
        } };
        const meta = abi.r4AppProfileMeta(profile);
        if (!bundleSatisfies(&bundle, meta.required_groups)) return .{ .failure = .{
            .domain = .contract,
            .raw_code = abi.err_no_group,
        } };
        return .{ .value = .{ .raw = raw, .bundle = bundle, .profile = profile } };
    }

    pub fn args(self: *const App) []const u8 {
        if (self.raw.args == 0 or self.raw.args_len == 0) return &.{};
        const ptr: [*]const u8 = @ptrFromInt(self.raw.args);
        return ptr[0..self.raw.args_len];
    }

    pub fn profileMeta(self: *const App) abi.R4AppProfileMeta {
        return abi.r4AppProfileMeta(self.profile);
    }

    /// Generischer Startkontext fuer libraryeigene Runtime-R4L-Bindings.
    /// Das SDK kennt weder deren Namen noch deren fachliche Tabellen.
    pub fn startContext(self: *const App) *const abi.R4XStartContext {
        return self.raw;
    }

    pub fn hasGroup(self: *const App, group: abi.R4LGroup) bool {
        return bundleHasGroup(&self.bundle, group);
    }

    pub fn lowLevel(self: *const App) program.Context {
        return program.Context.initBundle(&self.bundle);
    }

    pub fn system(self: *const App) r4sys.Context {
        return r4sys.Context.init(&self.bundle);
    }

    pub fn desktop(self: *const App) ?r4desk.Context {
        if (!self.hasGroup(.r4desk)) return null;
        return r4desk.Context.init(&self.bundle);
    }

    pub fn drawing(self: *const App) ?r4draw.Context {
        if (!self.hasGroup(.r4draw)) return null;
        return r4draw.Context.init(&self.bundle);
    }

    pub fn networkLowLevel(self: *const App) ?r4net.Context {
        if (!self.hasGroup(.r4net)) return null;
        return r4net.Context.init(&self.bundle);
    }

    pub fn network(self: *const App) ?network_facade.Network {
        const net = self.networkLowLevel() orelse return null;
        const result = network_facade.Network{ .sys = self.system(), .net = net };
        return if (result.available()) result else null;
    }

    pub fn audioLowLevel(self: *const App) ?r4audio.Context {
        if (!self.hasGroup(.r4audio)) return null;
        return r4audio.Context.init(&self.bundle);
    }

    pub fn audio(self: *const App) ?audio_facade.Audio {
        const raw = self.audioLowLevel() orelse return null;
        const result = audio_facade.Audio{ .sys = self.system(), .raw = raw };
        return if (result.available()) result else null;
    }

    pub fn devicesLowLevel(self: *const App) ?r4dev.Context {
        if (!self.hasGroup(.r4dev)) return null;
        return r4dev.Context.init(&self.bundle);
    }

    pub fn devices(self: *const App) ?device_facade.Devices {
        const raw = self.devicesLowLevel() orelse return null;
        const result = device_facade.Devices{ .raw = raw };
        return if (result.available()) result else null;
    }

    pub fn web(self: *const App) ?web_facade.WebTransport {
        const net = self.network() orelse return null;
        const dev = self.devicesLowLevel() orelse return null;
        const result = web_facade.WebTransport{ .network = net, .dev = dev };
        return if (result.available()) result else null;
    }

    pub fn console(self: *const App) ?storage.Console {
        const sys = self.system();
        if (!sys.hasFn("write") or !sys.hasFn("putc")) return null;
        return .{ .sys = sys };
    }

    pub fn files(self: *const App) ?storage.Files {
        const result = storage.Files{ .sys = self.system() };
        return if (result.available()) result else null;
    }

    pub fn registry(self: *const App) ?storage.Registry {
        const result = storage.Registry{ .sys = self.system() };
        return if (result.available()) result else null;
    }

    pub fn resources(self: *const App) resource_facade.Resources {
        return .{ .sys = self.system() };
    }

    pub fn services(self: *const App) ?service_facade.Services {
        const result = service_facade.Services{ .sys = self.system() };
        return if (result.available()) result else null;
    }

    pub fn tray(self: *const App) tray_facade.OpenResult {
        return tray_facade.Tray.open(self.system(), self.raw.instance_id);
    }

    pub fn window(self: *const App, timers: []@import("app_gui.zig").Timer) ?@import("app_gui.zig").Window {
        const desk = self.desktop() orelse return null;
        const draw = self.drawing() orelse return null;
        return @import("app_gui.zig").Window.init(self.system(), desk, draw, timers);
    }

    pub fn shouldClose(self: *const App) bool {
        return self.lowLevel().programShouldClose();
    }

    pub fn yield(self: *const App) void {
        self.lowLevel().taskYield();
    }

    pub fn ticks(self: *const App) u64 {
        return self.lowLevel().ticks();
    }

    pub fn allocator(self: *const App) ?@import("std").mem.Allocator {
        const low = self.lowLevel();
        if (!low.hasSysFn("vm_reserve") or !low.hasSysFn("vm_commit") or
            !low.hasSysFn("vm_decommit") or !low.hasSysFn("vm_release")) return null;
        return low.allocator();
    }
};

fn bundleSatisfies(bundle: *const program.Bundle, required_mask: u32) bool {
    inline for ([_]abi.R4LGroup{ .r4sys, .r4desk, .r4draw, .r4net, .r4audio, .r4dev }) |group| {
        const mask = @as(u32, 1) << @intFromEnum(group);
        if ((required_mask & mask) != 0 and !bundleHasGroup(bundle, group)) return false;
    }
    return true;
}

fn bundleHasGroup(bundle: *const program.Bundle, group: abi.R4LGroup) bool {
    return switch (group) {
        .r4sys => bundle.sys != null,
        .r4desk => bundle.desk != null,
        .r4draw => bundle.draw != null,
        .r4net => bundle.net != null,
        .r4audio => bundle.audio != null,
        .r4dev => bundle.dev != null,
    };
}

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
