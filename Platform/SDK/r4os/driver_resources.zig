const std = @import("std");
const abi = @import("r4os_contract").abi;

/// Non-owning references to the authenticated driver's loaded container and
/// optional kernel-owned boot ACPI tables. The two handle spaces are distinct.
/// No close is needed. Read failure can leave partial bytes in output.
pub const Context = struct {
    table: abi.DriverResourceApi,
    pub fn entropy(self: *const Context) ?@import("driver_entropy.zig").Context {
        if (!self.has("entropy_query")) return null;
        var result: abi.DriverEntropyApi = .{};
        const callback: *const fn (*abi.DriverEntropyApi) callconv(.c) i32 = @ptrFromInt(self.table.entropy_query);
        if (callback(&result) != 0 or result.version != 1 or result.size < 32 or
            result.register_backend == 0 or result.unregister_backend == 0) return null;
        return .{ .table = result };
    }
    pub fn cpuPower(self: *const Context) ?@import("driver_cpu_power.zig").Context {
        if (!self.has("cpu_power_query")) return null;
        var result: abi.DriverCpuPowerApi = .{};
        const callback: *const fn (*abi.DriverCpuPowerApi) callconv(.c) i32 = @ptrFromInt(self.table.cpu_power_query);
        if (callback(&result) != abi.cpu_capabilities_ok or result.version != 1 or result.size < 64) return null;
        const ctx = @import("driver_cpu_power.zig").Context{ .table = result };
        inline for (.{ "register_backend", "unregister_backend", "current_cpu", "capabilities", "topology", "register_read", "clock" }) |field| {
            if (!ctx.has(field)) return null;
        }
        return ctx;
    }
    pub fn platform(self: *const Context) ?Platform {
        if (!self.has("platform_query")) return null;
        var result: abi.DriverPlatformApi = .{};
        const callback: *const fn (*abi.DriverPlatformApi) callconv(.c) i32 = @ptrFromInt(self.table.platform_query);
        if (callback(&result) != abi.driver_resource_ok or result.version != 1 or result.size < @sizeOf(abi.DriverPlatformApi) or
            result.rsdp == 0 or result.physical_view == 0 or result.input_submit == 0) return null;
        return .{ .table = result };
    }
    pub fn supportsAcpi(self: *const Context) bool {
        return self.has("acpi_stat") and self.has("acpi_read_at");
    }
    pub fn acpiStat(self: *const Context, signature: [4]u8, index: u32, output: *abi.DriverFirmwareTableInfo) i32 {
        if (!self.has("acpi_stat")) return abi.err_no_fn;
        const callback: *const fn (u32, u32, *abi.DriverFirmwareTableInfo) callconv(.c) i32 = @ptrFromInt(self.table.acpi_stat);
        return callback(std.mem.readInt(u32, &signature, .little), index, output);
    }
    pub fn acpiReadAt(self: *const Context, handle: u64, offset: u64, output: []u8, deadline_ns: u64) i32 {
        if (!self.has("acpi_read_at")) return abi.err_no_fn;
        if (output.len == 0 or output.len > abi.driver_resource_max_read_bytes) return abi.driver_resource_error_invalid;
        const callback: *const fn (u64, u64, [*]u8, u32, u64) callconv(.c) i32 = @ptrFromInt(self.table.acpi_read_at);
        return callback(handle, offset, output.ptr, @intCast(output.len), deadline_ns);
    }
    pub fn stat(self: *const Context, name: []const u8, output: *abi.DriverResourceInfo) i32 {
        if (!self.has("stat")) return abi.err_no_fn;
        if (name.len == 0 or name.len > 63) return abi.driver_resource_error_invalid;
        const callback: *const fn ([*]const u8, u32, *abi.DriverResourceInfo) callconv(.c) i32 = @ptrFromInt(self.table.stat);
        return callback(name.ptr, @intCast(name.len), output);
    }
    pub fn readAt(self: *const Context, handle: u64, offset: u64, output: []u8, deadline_ns: u64) i32 {
        if (!self.has("read_at")) return abi.err_no_fn;
        if (output.len == 0 or output.len > abi.driver_resource_max_read_bytes) return abi.driver_resource_error_invalid;
        const callback: *const fn (u64, u64, [*]u8, u32, u64) callconv(.c) i32 = @ptrFromInt(self.table.read_at);
        return callback(handle, offset, output.ptr, @intCast(output.len), deadline_ns);
    }
    pub fn nowNs(self: *const Context) u64 {
        if (!self.has("now_ns")) return std.math.maxInt(u64);
        const callback: *const fn () callconv(.c) u64 = @ptrFromInt(self.table.now_ns);
        return callback();
    }
    fn has(self: *const Context, comptime field: []const u8) bool {
        return self.table.version == 1 and self.table.size >= @offsetOf(abi.DriverResourceApi, field) + 8 and @field(self.table, field) != 0;
    }
};

pub const Platform = struct {
    table: abi.DriverPlatformApi,
    pub fn rsdp(self: *const Platform) u64 {
        const callback: *const fn () callconv(.c) u64 = @ptrFromInt(self.table.rsdp);
        return callback();
    }
    pub fn physicalView(self: *const Platform, physical: u64, bytes: u64) ?[*]u8 {
        var address: u64 = 0;
        const callback: *const fn (u64, u64, *u64) callconv(.c) i32 = @ptrFromInt(self.table.physical_view);
        if (callback(physical, bytes, &address) != abi.driver_resource_ok or address == 0) return null;
        return @ptrFromInt(address);
    }
    pub fn input(self: *const Platform, kind: u32, value: u32) i32 {
        const callback: *const fn (u32, u32) callconv(.c) i32 = @ptrFromInt(self.table.input_submit);
        return callback(kind, value);
    }
};
