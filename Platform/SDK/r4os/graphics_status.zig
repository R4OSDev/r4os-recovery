//! UI projection of coherent display ownership and loaded R4D metadata.
const std = @import("std");
const a = @import("r4os_contract").abi;
const dev_api = @import("r4dev.zig");

pub const Snapshot = struct {
    display: a.DisplayStateInfo,
    driver: ?a.DriverModuleInfo = null,
    adapter_name: [48]u8 = @splat(0),

    pub fn read(dev: *const dev_api.Context) ?Snapshot {
        const before = dev.displayState() orelse return null;
        const driver = if (before.driver_owner != 0) dev.driverModuleInfo(before.driver_owner) else null;
        var result: Snapshot = .{ .display = before };
        var inventory: a.DeviceInventorySummary = .{};
        if (before.adapter_id != 0 and dev.deviceInventorySummary(&inventory) >= 0 and inventory.truncated == 0 and inventory.total <= 4096) {
            for (0..inventory.total) |i| {
                var record: a.DeviceInventoryRecord = .{};
                if (dev.deviceInventoryRecord(@intCast(i), &record) < 0) break;
                if (result.matchesAdapter(record)) { result.adapter_name = record.name; result.adapter_name[47] = 0; break; }
            }
        }
        const after = dev.displayState() orelse return null;
        if (!sameOwner(before, after)) return null;
        result.display = after;
        result.driver = if (driver) |value|
            if (value.owner == after.driver_owner and value.generation != 0 and value.module_generation != 0) value else null
            else null;
        return result;
    }

    pub fn matchesAdapter(self: *const Snapshot, record: a.DeviceInventoryRecord) bool {
        if (self.display.adapter_id == 0 or record.flags & 1 == 0) return false;
        return self.display.adapter_id == (0x01000000 | (@as(u32, record.bus_no) << 8) |
            (@as(u32, record.device_no) << 3) | record.function_no);
    }

    pub fn line(self: *const Snapshot, out: []u8, index: usize) []const u8 {
        const s = self.display;
        return switch (index) {
            0 => std.fmt.bufPrint(out, "Output: {s} ({s})", .{ z(&s.backend_name), state(s.state) }) catch "",
            1 => if (s.adapter_id == 0) "GPU identity: not assigned by the framebuffer" else if (self.adapter_name[0] != 0)
                std.fmt.bufPrint(out, "Active GPU: {s}", .{z(&self.adapter_name)}) catch ""
                else std.fmt.bufPrint(out, "Active adapter: {X:0>8}", .{s.adapter_id}) catch "",
            2 => if (self.driver) |d| std.fmt.bufPrint(out, "Loaded driver: {s} {s}{s}", .{
                z(&d.driver_name), version(&d.module_version), if (d.flags & 1 != 0) " (quarantined)" else "" }) catch ""
                else if (s.driver_owner == 0 and s.state == a.display_state_bootfb) "Loaded driver: built-in framebuffer" else "Loaded driver version: unavailable",
            3 => if (self.driver) |d| std.fmt.bufPrint(out, "Firmware bundle: {s}", .{version(&d.firmware_version)}) catch ""
                else "Firmware bundle: unavailable",
            4 => std.fmt.bufPrint(out, "Current boot: {s}", .{policy(s.policy)}) catch "",
            5 => reason(s.reason),
            6 => std.fmt.bufPrint(out, "Software fallback: {s}", .{
                if (s.capabilities & a.display_state_cap_software_fallback != 0) z(&s.fallback_name) else "unavailable" }) catch "",
            7 => if (s.capabilities & a.display_state_cap_native_scanout != 0)
                "Native graphics: experimental; physical acceptance pending"
                else "Software presentation; native scanout is inactive",
            else => "",
        };
    }
};

pub fn sameOwner(before: a.DisplayStateInfo, after: a.DisplayStateInfo) bool {
    return before.revision == after.revision and before.device_generation == after.device_generation and
        before.reset_generation == after.reset_generation and before.driver_owner == after.driver_owner and
        before.adapter_id == after.adapter_id;
}
pub fn z(bytes: []const u8) []const u8 { return std.mem.sliceTo(bytes, 0); }
fn version(bytes: []const u8) []const u8 { const value = z(bytes); return if (value.len == 0) "unknown" else value; }
pub fn policy(value: u32) []const u8 {
    return switch (value) { 0 => "Automatic", 1 => "Software", 2 => "Software (this boot only)", else => "Unknown" };
}
pub fn state(value: u32) []const u8 {
    return switch (value) { 0 => "unavailable", 1 => "boot framebuffer", 2 => "preparing", 3 => "native", 4 => "software on native output", 5 => "recovering", else => "unknown" };
}
pub fn reason(value: u32) []const u8 {
    return switch (value) {
        0 => "No fallback error reported",
        1 => "No verified native output is active",
        2 => "Software graphics selected by boot policy",
        3 => "Native backend rejected; prerequisites were not met",
        4 => "Native output preparation failed",
        5 => "Native output activation failed",
        6 => "Graphics device lost; check the available fallback",
        7 => "Output restoration failed; recovery may be required",
        else => "Unknown graphics status",
    };
}
