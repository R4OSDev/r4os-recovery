//! Shared entropy policy. Optional RDRAND needs a fresh CPU grant and CF;
//! a registered device is the alternative. No pool, clocks or ID substitutes.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const cpu = @import("cpu_acceleration.zig");
pub const InfoFn = abi.R4SysFns.entropy_source_info;
pub const FillFn = abi.R4SysFns.entropy_fill;
pub const Provider = struct {
    info: ?InfoFn = null,
    device: ?FillFn = null,
    hardware_info: ?cpu.InfoFn = null,
    hardware: ?cpu.WorkFn = null,

    /// Publish callbacks before workers start; an empty provider clears the
    /// former scope. The caller retains its real callback owner lifetime.
    pub fn bind(self: Provider) void {
        provider = self;
    }

    pub fn available(self: Provider) bool {
        if (self.hardware != null) if (self.hardware_info) |get| {
            var info: abi.CpuAccelerationInfo = .{};
            if (get(&info) == 0 and info.version == 1 and info.size >= 128 and
                info.os_mask & abi.cpu_accel_feature_rdrand != 0) return true;
        };
        if (self.device != null) if (self.info) |get| {
            var info: abi.EntropySourceInfo = .{};
            if (get(&info) == 0 and info.version == 1 and info.size >= 128 and
                info.state == abi.entropy_state_ready and info.generation != 0 and
                info.max_request_bytes > 0 and info.max_request_bytes <= abi.entropy_max_request_bytes)
                return true;
        };
        return false;
    }
    pub fn fill(self: Provider, out: []u8) bool {
        if (out.len == 0) return true;
        if (self.hardware) |work| {
            if (hardwareFill(work, out)) return true;
            std.crypto.secureZero(u8, out);
        }
        if (self.device) |read| {
            var maximum: u32 = abi.entropy_max_request_bytes;
            if (self.info) |get| {
                var info: abi.EntropySourceInfo = .{};
                if (get(&info) != 0 or info.version != 1 or info.size < 128 or
                    info.state != abi.entropy_state_ready or info.generation == 0 or
                    info.max_request_bytes == 0 or info.max_request_bytes > maximum)
                {
                    std.crypto.secureZero(u8, out);
                    return false;
                }
                maximum = info.max_request_bytes;
            }
            var offset: usize = 0;
            while (offset < out.len) {
                const bytes: u32 = @intCast(@min(out.len - offset, maximum));
                if (read(out.ptr + offset, bytes) != @as(i32, @intCast(bytes))) break;
                offset += bytes;
            }
            if (offset == out.len) return true;
        }
        std.crypto.secureZero(u8, out);
        return false;
    }
};

// Bound once by module startup, before it publishes workers/callbacks. Kernel
// functions stay resident; each request authenticates the live device source.
var provider: Provider = .{};
pub fn bindProgram(context: *const @import("program.zig").Context) void {
    provider = .{ .info = context.entropyInfoFunction(), .device = context.entropyFillFunction(), .hardware_info = context.cpuAccelerationInfoFunction(), .hardware = context.cpuAccelerationWorkFunction() };
}
pub fn bindProtocol(api: *const abi.ProtocolApi) void {
    provider = .{ .hardware_info = cpu.protocolInfo(api), .hardware = cpu.protocolWork(api) };
    if (api.size >= @offsetOf(abi.ProtocolApi, "entropy_source_info") + 8) provider.info = api.entropy_source_info;
    if (api.size >= @offsetOf(abi.ProtocolApi, "entropy_fill") + 8) provider.device = api.entropy_fill;
}
pub fn available() bool {
    return provider.available();
}
pub fn fill(out: []u8) bool {
    return provider.fill(out);
}
pub fn sourceInfo(out: *abi.EntropySourceInfo) i32 {
    const get = provider.info orelse return abi.entropy_error_unavailable;
    return get(out);
}

const Stage = struct { words: [64]u64 = @splat(0) };
test "Protocol2 entropy binding rejects old headers and drops retired callbacks" {
    const Fake = struct {
        fn info(out: *abi.EntropySourceInfo) callconv(.c) i32 {
            out.* = .{ .state = abi.entropy_state_ready, .generation = 1, .max_request_bytes = 64 };
            return 0;
        }
        fn read(out: [*]u8, bytes: u32) callconv(.c) i32 {
            @memset(out[0..bytes], 0x56);
            return @intCast(bytes);
        }
    };
    var api: abi.ProtocolApi2 = undefined;
    @memset(std.mem.asBytes(&api), 0);
    api.magic = @import("technical2.zig").abi.protocol_magic;
    api.version = @import("technical2.zig").abi.protocol_version;
    api.size = 120;
    api.entropy_source_info = Fake.info;
    api.entropy_fill = Fake.read;
    const context = @import("protocol2.zig").Context.init(&api);
    context.bindEntropy();
    defer Provider.bind(.{});
    var out: [64]u8 = @splat(0);
    try std.testing.expect(available());
    try std.testing.expect(fill(&out));
    for (out) |byte| try std.testing.expectEqual(@as(u8, 0x56), byte);
    api.magic = abi.protocol_magic;
    context.bindEntropy();
    try std.testing.expect(!available());
    try std.testing.expect(!fill(&out));
    for (out) |byte| try std.testing.expectEqual(@as(u8, 0), byte);
    api.magic = @import("technical2.zig").abi.protocol_magic;
    api.size = 119;
    context.bindEntropy();
    try std.testing.expect(!available());
    api.size = 120;
    context.bindEntropy();
    try std.testing.expect(available());
    Provider.bind(.{});
    try std.testing.expect(!available());
}
fn hardwareFill(work: cpu.WorkFn, out: []u8) bool {
    var offset: usize = 0;
    while (offset < out.len) {
        var stage: Stage = .{};
        defer std.crypto.secureZero(u8, std.mem.asBytes(&stage));
        const bytes = @min(out.len - offset, @sizeOf(Stage));
        const words: u32 = @intCast((bytes + 7) / 8);
        var receipt: abi.CpuAccelerationWork = .{};
        const callback: abi.CpuPureWorkFn = hardwareWork;
        if (work(abi.cpu_accel_work_kind_rdrand, words, &callback, @intFromPtr(&stage), &receipt) != 0 or
            !cpu.accepted(&receipt, abi.cpu_accel_work_kind_rdrand, words)) return false;
        @memcpy(out[offset..][0..bytes], std.mem.asBytes(&stage)[0..bytes]);
        offset += bytes;
    }
    return true;
}
fn hardwareWork(context: u64, count: u32) callconv(.c) i32 {
    if (count == 0 or count > 64 or context == 0) return -1;
    const stage: *Stage = @ptrFromInt(context);
    return if (drawWords(rdrand64, stage.words[0..count])) 0 else -1;
}
fn drawWords(comptime draw: anytype, out: []u64) bool {
    for (out) |*word| {
        var attempt: u8 = 0;
        var value: ?u64 = null;
        while (attempt < 10 and value == null) : (attempt += 1) value = @call(.always_inline, draw, .{});
        word.* = value orelse return false;
    }
    return true;
}
inline fn rdrand64() ?u64 {
    var value: u64 = 0;
    var success: u8 = 0;
    asm volatile (
        \\rdrand %[value]
        \\setc %[success]
        : [value] "=r" (value),
          [success] "=r" (success),
    );
    return if (success != 0) value else null;
}

test "missing source and short or later failed device clear the whole output" {
    const Fake = struct {
        var calls: usize = 0;
        fn read(data: [*]u8, bytes: u32) callconv(.c) i32 {
            calls += 1;
            @memset(data[0..bytes], 0x53);
            return if (calls == 1) @intCast(bytes) else @intCast(bytes - 1);
        }
    };
    var out: [5001]u8 = @splat(0x77);
    try std.testing.expect(!(Provider{}).available());
    try std.testing.expect(!(Provider{}).fill(&out));
    try std.testing.expectEqual(@as(u8, 0), out[0] | out[5000]);
    @memset(&out, 0x77);
    try std.testing.expect(!(Provider{ .device = Fake.read }).fill(&out));
    try std.testing.expectEqual(@as(usize, 2), Fake.calls);
    for (out) |byte| try std.testing.expectEqual(@as(u8, 0), byte);
}
test "CF failure is bounded and cannot turn unchanged instruction bits into success" {
    const Fake = struct {
        var calls: u32 = 0;
        fn draw() ?u64 {
            calls += 1;
            return null;
        }
    };
    var words: [2]u64 = @splat(0x77);
    try std.testing.expect(!drawWords(Fake.draw, &words));
    try std.testing.expectEqual(@as(u32, 10), Fake.calls);
}
test "rejected CPU window never executes optional host instructions and device recovers" {
    const Fake = struct {
        var rejected: u32 = 0;
        fn work(kind: u32, iterations: u32, callback: ?*const abi.CpuPureWorkFn, context: u64, receipt: *abi.CpuAccelerationWork) callconv(.c) i32 {
            _ = iterations;
            _ = callback;
            _ = context;
            _ = receipt;
            std.debug.assert(kind == abi.cpu_accel_work_kind_rdrand);
            rejected += 1;
            return abi.cpu_capabilities_error_unsupported;
        }
        fn read(data: [*]u8, bytes: u32) callconv(.c) i32 {
            @memset(data[0..bytes], 0x53);
            return @intCast(bytes);
        }
    };
    var out: [517]u8 = @splat(0);
    try std.testing.expect((Provider{ .hardware = Fake.work, .device = Fake.read }).fill(&out));
    try std.testing.expectEqual(@as(u32, 1), Fake.rejected);
    for (out) |byte| try std.testing.expectEqual(@as(u8, 0x53), byte);
}

test "old ProtocolApi ends at an inaccessible page before optional entropy slots" {
    if (@import("builtin").os.tag != .linux) return error.SkipZigTest;
    const page = 4096;
    const region = try std.posix.mmap(null, page * 3, .{}, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(region);
    try std.testing.expectEqual(@as(usize, 0), std.os.linux.mprotect(region.ptr + page, page, .{ .READ = true, .WRITE = true }));
    for ([_]usize{ 88, 104, 112 }) |size| {
        @memset(region[page * 2 - size .. page * 2], 0);
        const api: *abi.ProtocolApi = @ptrCast(@alignCast(region.ptr + page * 2 - size));
        api.version = 1;
        api.size = @intCast(size);
        bindProtocol(api);
        try std.testing.expect(!available());
        var out: [17]u8 = @splat(0x77);
        try std.testing.expect(!fill(&out));
        for (out) |byte| try std.testing.expectEqual(@as(u8, 0), byte);
    }
}
test "registered maximum bounds every device call" {
    const Fake = struct {
        var calls: u32 = 0;
        fn info(out: *abi.EntropySourceInfo) callconv(.c) i32 {
            out.* = .{ .state = abi.entropy_state_ready, .generation = 1, .max_request_bytes = 7 };
            return 0;
        }
        fn read(data: [*]u8, bytes: u32) callconv(.c) i32 {
            std.debug.assert(bytes <= 7);
            calls += 1;
            @memset(data[0..bytes], 0x53);
            return @intCast(bytes);
        }
    };
    var out: [17]u8 = undefined;
    try std.testing.expect((Provider{ .info = Fake.info, .device = Fake.read }).fill(&out));
    try std.testing.expectEqual(@as(u32, 3), Fake.calls);
}
