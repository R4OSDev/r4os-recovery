//! Normal application entry on the real generation2 context. The App owns
//! its validated view and private callback record; borrowed facades and args
//! must retire before it moves or the exact entry returns.
const std = @import("std");
const platform2 = @import("platform2.zig");
const allocator_source = @import("allocator_source.zig");
const contract = @import("app_contract.zig");
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

pub const ImportSpec = extern struct {
    module_name: [*:0]const u8,
    symbol_name: [*:0]const u8,
    minimum: u32,
    optional: u32,
    group_id: u32,
    reserved: u32 = 0,
};
pub const StartupInfo = extern struct {
    profile: u32,
    app_class: u32,
    required_groups: u32,
    import_count: u32,
    imports: ?[*]const ImportSpec,
};

pub const App = struct {
    raw: *const platform2.abi.R4XStartContext2,
    context: platform2.Context,
    memory: allocator_source.Memory,
    profile: abi.R4AppProfile,

    pub fn init(raw: *const platform2.abi.R4XStartContext2, profile: abi.R4AppProfile) contract.Outcome(App) {
        const context = platform2.Context.init(raw) catch return failure(-12);
        const meta = abi.r4AppProfileMeta(profile);
        // LaunchPolicy may select either application class. Service admission
        // always binds the declared service profile to the actual service role.
        const class_matches = switch (meta.app_class) {
            .console, .gui => raw.app_class == @intFromEnum(abi.R4XStartAppClass.console) or
                raw.app_class == @intFromEnum(abi.R4XStartAppClass.gui),
            .service => raw.app_class == @intFromEnum(abi.R4XStartAppClass.service),
            .auto => false,
        };
        if (!class_matches or raw.flags & abi.r4xstart_flag_imports_valid == 0) return failure(-12);
        inline for (std.meta.tags(abi.R4LGroup)) |group| {
            if (meta.required_groups & (@as(u32, 1) << @as(u5, @intCast(@intFromEnum(group)))) != 0 and
                !hasContextGroup(&context, group)) return failure(-15);
        }
        return .{ .value = .{
            .raw = raw,
            .context = context,
            .memory = allocator_source.Memory.fromContext2(&context),
            .profile = profile,
        } };
    }

    pub fn initDeclared(raw: *const platform2.abi.R4XStartContext2, expected: *const StartupInfo) contract.Outcome(App) {
        if (expected.profile > @intFromEnum(abi.R4AppProfile.service) or
            expected.import_count > 32 or
            (expected.import_count != 0 and expected.imports == null)) return failure(-13);
        const profile: abi.R4AppProfile = @enumFromInt(expected.profile);
        const meta = abi.r4AppProfileMeta(profile);
        if (expected.app_class != @intFromEnum(meta.app_class) or
            expected.required_groups != meta.required_groups) return failure(-12);
        const initialized = init(raw, profile);
        const app = switch (initialized) {
            .value => |value| value,
            .failure => |f| return .{ .failure = f },
        };
        if (raw.import_count != expected.import_count) return failure(-13);
        if (raw.import_count == 0) return .{ .value = app };
        const actual: [*]const abi.R4XStartImport = @ptrFromInt(raw.imports);
        const specs = expected.imports.?[0..expected.import_count];
        for (actual[0..raw.import_count], specs) |item, spec| {
            if (spec.reserved != 0 or spec.minimum == 0 or spec.optional > 1 or
                item.min_version != spec.minimum or item.group_id != spec.group_id or
                !nameEquals(item.module_name, spec.module_name) or
                !nameEquals(item.symbol_name, spec.symbol_name)) return failure(-14);
            if (item.table == 0) {
                if (spec.optional != 1 or spec.group_id != 0 or item.resolved_version != 0 or item.flags != 0) return failure(-14);
                continue;
            }
            if (item.resolved_version < spec.minimum) return failure(-14);
            if (spec.group_id == 0) {
                if (item.flags != 0) return failure(-14);
                continue; // Independent R4Ls retain their own named contracts.
            }
            if (spec.optional != 0 or spec.group_id > 6 or spec.minimum != 2 or
                item.resolved_version != 2 or
                !std.ascii.eqlIgnoreCase(std.mem.span(spec.symbol_name), "Query2") or
                item.flags != abi.r4xstart_import_flag_group_interface) return failure(-14);
            if (!hasContextGroup(&app.context, @enumFromInt(spec.group_id))) return failure(-15);
        }
        return .{ .value = app };
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
    pub fn startContext(self: *const App) *const platform2.abi.R4XStartContext2 {
        return self.raw;
    }

    pub fn hasGroup(self: *const App, group: abi.R4LGroup) bool {
        return switch (group) {
            .r4sys => self.context.system() != null,
            .r4desk => self.context.desktop() != null,
            .r4draw => self.context.drawing() != null,
            .r4net => self.context.network() != null,
            .r4audio => self.context.audio() != null,
            .r4dev => self.context.devices() != null,
        };
    }

    pub fn lowLevel(self: *const App) program.Context {
        return .{ .generation2 = &self.context, .memory2 = &self.memory };
    }

    pub fn system(self: *const App) r4sys.Context {
        return r4sys.Context.fromProgram(self.lowLevel());
    }

    pub fn inventoryProvider(self: *const App, mode: @import("inventory_api.zig").Mode) error{NoProvider}!@import("inventory_api.zig").Provider {
        return @import("inventory_api.zig").fromContext2(&self.context, mode);
    }

    pub fn deviceSnapshotProvider(self: *const App) @import("device_snapshot_api.zig").Error!@import("device_snapshot_api.zig").Provider {
        return @import("device_snapshot_api.zig").fromContext2(&self.context);
    }

    pub fn clock(self: *const App) error{NoProvider}!@import("stream_adapters.zig").PlatformClock {
        return @import("stream_adapters.zig").PlatformClock.fromContext2(&self.context);
    }

    pub fn argCursor(self: *const App, policy: @import("arg_cursor.zig").Policy, detail: *@import("arg_cursor.zig").Failure) @import("arg_cursor.zig").Error!@import("arg_cursor.zig").ArgCursor {
        return @import("arg_cursor.zig").ArgCursor.init(self.args(), policy, detail);
    }

    pub fn waitSet(self: *const App, capacity: u32, out: *@import("wait_set.zig").Set) i32 {
        return @import("wait_set.zig").Set.init(&self.context, capacity, out);
    }

    pub fn bytePipe(self: *const App, capacity: u64, out: *@import("byte_pipe.zig").Pair) i32 {
        return @import("byte_pipe.zig").create(&self.context, capacity, out);
    }

    pub fn stdio(self: *const App, out: *@import("launch_io.zig").Stdio) i32 {
        return @import("launch_io.zig").Stdio.init(&self.context, out);
    }

    pub fn networkFamily(self: *const App, service: @import("network_family.zig").Service, out: *@import("network_family.zig").Client) i32 {
        return @import("network_family.zig").Client.connect(&self.context, service, out);
    }

    pub fn audioCapture(self: *const App, transport_ticks: u64, out: *@import("audio_capture.zig").Client) i32 {
        return @import("audio_capture.zig").Client.connect(&self.context, transport_ticks, out);
    }

    pub fn textMetricsProvider(self: *const App) @import("text_metrics_api.zig").Binding {
        return @import("text_metrics_api.zig").provider2(&self.context);
    }

    pub fn filePickerProvider(self: *const App) @import("file_picker_api.zig").Binding {
        return @import("file_picker_api.zig").provider2(&self.context);
    }

    pub fn clipboardOffers(self: *const App, out: *@import("clipboard_offer.zig").Client) i32 {
        return @import("clipboard_offer.zig").Client.connect(&self.context, out);
    }

    pub fn compositionClient(self: *const App, timeout_ticks: u64, out: *@import("text_composition_client.zig").Client) i32 {
        return @import("text_composition_client.zig").Client.connect(&self.context, timeout_ticks, out);
    }

    pub fn desktop(self: *const App) ?r4desk.Context {
        if (!self.hasGroup(.r4desk)) return null;
        return r4desk.Context.fromProgram(self.lowLevel());
    }

    pub fn drawing(self: *const App) ?r4draw.Context {
        if (!self.hasGroup(.r4draw)) return null;
        return r4draw.Context.fromProgram(self.lowLevel());
    }

    pub fn networkLowLevel(self: *const App) ?r4net.Context {
        if (!self.hasGroup(.r4net)) return null;
        return r4net.Context.fromProgram(self.lowLevel());
    }

    pub fn network(self: *const App) ?network_facade.Network {
        const net = self.networkLowLevel() orelse return null;
        const result = network_facade.Network{ .sys = self.system(), .net = net };
        return if (result.available()) result else null;
    }

    pub fn audioLowLevel(self: *const App) ?r4audio.Context {
        if (!self.hasGroup(.r4audio)) return null;
        return r4audio.Context.fromProgram(self.lowLevel());
    }

    pub fn audio(self: *const App) ?audio_facade.Audio {
        const raw = self.audioLowLevel() orelse return null;
        const result = audio_facade.Audio{ .sys = self.system(), .raw = raw };
        return if (result.available()) result else null;
    }

    pub fn devicesLowLevel(self: *const App) ?r4dev.Context {
        if (!self.hasGroup(.r4dev)) return null;
        return r4dev.Context.fromProgram(self.lowLevel());
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

fn failure(code: i32) contract.Outcome(App) {
    return .{ .failure = .{ .domain = .contract, .raw_code = code } };
}
fn nameEquals(address: u64, expected: [*:0]const u8) bool {
    if (address == 0) return false;
    const name = std.mem.span(expected);
    if (name.len == 0 or name.len > 31) return false;
    const value: [*]const u8 = @ptrFromInt(address);
    return std.ascii.eqlIgnoreCase(value[0..name.len], name) and value[name.len] == 0;
}
fn hasContextGroup(context: *const platform2.Context, group: abi.R4LGroup) bool {
    return switch (group) {
        .r4sys => context.system() != null,
        .r4desk => context.desktop() != null,
        .r4draw => context.drawing() != null,
        .r4net => context.network() != null,
        .r4audio => context.audio() != null,
        .r4dev => context.devices() != null,
    };
}
comptime {
    if (@sizeOf(ImportSpec) != 32 or @sizeOf(StartupInfo) != 24) @compileError("SDK startup2 facts layout");
}
