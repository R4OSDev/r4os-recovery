// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Nonblocking canonical BO/VA owner for native graphics uploads and views.
//! A close request and the later physical retirement ACK are distinct states.
const std = @import("std");
const a = @import("r4os").abi;
const nv = @import("r4nv_binding");
const amd = @import("r4amd_binding");
const d = @import("device.zig");
pub const granule: u64 = 65536;
pub const modifier_base: u64 = 0x0300000000606010;
pub const Profile = struct {
    binding: a.GfxBackendBinding,
    memory_generation: u64,
    va_start: u64,
    va_end: u64,
    graphics_class: u32,
    backend: u32 = d.c.render_backend_nvidia,
    pub fn query(device: *d.Device) d.Error!Profile {
        if (device.backend() == d.c.render_backend_amd) return queryAmd(device);
        const selected = device.selected;
        if (device.backend() != d.c.render_backend_nvidia or selected.binding.adapter_id == 0 or selected.operations & 16 == 0 or
            selected.operations & (@as(u64, 1) << a.gfx_queue_operation_native) == 0) return error.Unsupported;
        var properties: a.GfxBackendProperties = .{};
        try d.platform(device.queues().backendProperties(&selected.binding, &properties));
        if (!payload(properties) or properties.interface_id_lo != nv.backend_v1_header.interface_id_lo or
            properties.interface_id_hi != nv.backend_v1_header.interface_id_hi or properties.revision != nv.architecture_version or
            properties.data_bytes != @sizeOf(nv.R4NvArchitecture)) return error.Unsupported;
        for (properties.data[properties.data_bytes..]) |byte| if (byte != 0) return error.Invalid;
        const arch = std.mem.bytesToValue(nv.R4NvArchitecture, properties.data[0..@sizeOf(nv.R4NvArchitecture)]);
        if (arch.version != properties.revision or arch.size != @sizeOf(nv.R4NvArchitecture) or arch.vendor_id != 0x10de or
            arch.rm_release != nv.rm_release or arch.flags != nv.architecture_host_coherent | nv.architecture_image_layouts or
            arch.bind_alignment != granule or arch.va_start == 0 or arch.va_start >= arch.va_end or
            arch.va_start >= (@as(u64, 1) << 40) or arch.va_end > (@as(u64, 1) << 49) or
            (arch.va_start | arch.va_end) % granule != 0) return error.Unsupported;
        if (arch.memory_generation != selected.memory_generation) return error.Stale;
        var info: nv.R4NvRenderInfo = undefined;
        const client = device.caller.client(nv.RenderV1Client) catch return error.Unsupported;
        if (client.render_info(arch.graphics_class, &info) != nv.status_ok or info.version != 1 or info.size != @sizeOf(nv.R4NvRenderInfo) or
            info.graphics_class != arch.graphics_class or info.shader_model != arch.shader_model) return error.Unsupported;
        return .{ .binding = selected.binding, .memory_generation = arch.memory_generation, .va_start = arch.va_start, .va_end = @min(arch.va_end, @as(u64, 1) << 40), .graphics_class = arch.graphics_class };
    }
    fn queryAmd(device: *d.Device) d.Error!Profile {
        const selected = device.selected;
        if (selected.binding.adapter_id == 0 or selected.memory_generation == 0 or selected.operations & 16 == 0 or
            selected.operations & (@as(u64, 1) << a.gfx_queue_operation_native) == 0) return error.Unsupported;
        var properties: a.GfxBackendProperties = .{};
        try d.platform(device.queues().backendProperties(&selected.binding, &properties));
        if (!payload(properties) or properties.interface_id_lo != amd.image_v1_header.interface_id_lo or
            properties.interface_id_hi != amd.image_v1_header.interface_id_hi or
            ((properties.revision != 1 or properties.data_bytes != @sizeOf(amd.R4AmdArchitecture)) and
             (properties.revision != 2 or properties.data_bytes != @sizeOf(amd.R4AmdDeviceFacts)) and
             (properties.revision != 3 or properties.data_bytes != @sizeOf(amd.R4AmdDeviceFactsV3)))) return error.Unsupported;
        for (properties.data[properties.data_bytes..]) |byte| if (byte != 0) return error.Invalid;
        const arch = std.mem.bytesToValue(amd.R4AmdArchitecture, properties.data[0..@sizeOf(amd.R4AmdArchitecture)]);
        try @import("amd_images.zig").validateArchitecture(arch, selected);
        if (arch.gb_addr_config == 0) return error.Unsupported;
        if (arch.memory_generation != selected.memory_generation) return error.Stale;
        return .{ .binding = selected.binding, .memory_generation = arch.memory_generation, .va_start = amd.native_va_start, .va_end = amd.native_va_end, .graphics_class = 0, .backend = d.c.render_backend_amd };
    }
};
pub fn payload(value: anytype) bool {
    return value.version == 1 and value.size >= @sizeOf(@TypeOf(value));
}
fn valid(value: a.GfxBufferHandle) bool {
    return value.id != 0 and value.generation != 0 and value.reserved0 == 0;
}
fn equal(left: anytype, right: @TypeOf(left)) bool {
    return std.meta.eql(left, right);
}

pub const Resource = struct {
    backing: a.GfxBufferReference = .{},
    descriptor: a.GfxBufferDescriptor = .{},
    map: a.GfxBufferMap = .{},
    range: a.GfxBufferHandle = .{},
    binding: a.GfxBufferHandle = .{},
    address: u64 = 0,
    deadline: u64 = 0,
    ready: bool = false,
    retiring: bool = false,
    failed: ?d.Error = null,

    pub fn live(self: *const Resource) bool {
        return self.backing.reference.id != 0 or self.range.id != 0 or self.map.lease.id != 0;
    }
    pub fn import(self: *Resource, device: *d.Device, profile: Profile, reference: a.GfxBufferHandle, deadline: u64) d.Error!void {
        if (self.live() or !valid(reference)) return error.Invalid;
        self.deadline = deadline;
        try d.platform(device.buffers().import(&reference, &self.backing));
        try self.describe(device, profile);
    }
    pub fn system(self: *Resource, device: *d.Device, profile: Profile, deadline: u64) d.Error!void {
        if (self.live()) return error.Busy;
        self.deadline = deadline;
        try d.platform(device.buffers().create(&.{ .byte_length = granule, .alignment = granule, .usage = a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write | a.gfx_buffer_usage_transfer_source | a.gfx_buffer_usage_transfer_target }, &self.backing));
        try self.describe(device, profile);
        try d.platform(device.buffers().mapPersistent(&self.backing.reference, a.gfx_buffer_map_write, 0, granule, &self.map));
        if (!payload(self.map) or !valid(self.map.lease) or self.map.cpu_address == 0 or self.map.cpu_address % 4 != 0 or
            self.map.byte_length != granule or self.map.cpu_address > std.math.maxInt(u64) - granule or
            self.map.cache_policy != a.gfx_buffer_cache_write_back or self.map.reserved0 != 0) return error.Unsupported;
        @memset(self.bytes(), 0);
    }
    fn describe(self: *Resource, device: *d.Device, profile: Profile) d.Error!void {
        if (!payload(self.backing) or !valid(self.backing.reference) or !valid(self.backing.buffer) or
            self.backing.flags != 0 or self.backing.reserved0 != 0) return error.Invalid;
        try d.platform(device.buffers().describe(&self.backing.reference, &self.descriptor));
        const desc = self.descriptor;
        if (!payload(desc) or desc.reserved0 != 0 or desc.byte_length == 0 or desc.byte_length % 4096 != 0 or
            desc.alignment < 4096 or !std.math.isPowerOfTwo(desc.alignment)) return error.Unsupported;
        if (desc.modifier != 0) {
            if (profile.backend == d.c.render_backend_amd) {
                const sw = (desc.modifier >> 8) & 31;
                const allowed: u64 = 0x0200000000000001 | (31 << 8) | (7 << 21) | (7 << 24);
                if (desc.modifier & ~allowed != 0 or desc.modifier & 0xff000000000000ff != 0x0200000000000001 or
                    (sw != 9 and sw != 10 and sw != 22 and sw != 25 and sw != 26 and sw != 27)) return error.Unsupported;
            } else if (desc.modifier & ~@as(u64, 15) != modifier_base or desc.modifier & 15 > 5) return error.Unsupported;
        }
        if (desc.location == a.gfx_buffer_location_device_local) {
            if (desc.adapter_id != profile.binding.adapter_id or desc.device_generation != profile.memory_generation or desc.driver_owner == 0) return error.Stale;
        } else if (desc.location != a.gfx_buffer_location_system or desc.adapter_id != 0 or desc.device_generation != 0 or
            desc.driver_owner != 0 or desc.modifier != 0) return error.Unsupported;
    }
    pub fn bytes(self: *Resource) []u8 {
        std.debug.assert(valid(self.map.lease) and self.map.byte_length == granule);
        return @as([*]u8, @ptrFromInt(self.map.cpu_address))[0..granule];
    }
    fn query(self: *Resource, device: *d.Device, profile: Profile, handle: a.GfxBufferHandle, parent: a.GfxBufferHandle, kind: u32) d.Error!bool {
        var result: a.GfxVirtualStatus = .{};
        const trace = @import("native_diagnostics.zig").Trace.init(device);
        errdefer |err| trace.detail("R4GFX virtual-query error={s} expected={d}:{d} parent={d}:{d} kind={d} bytes={d} deadline={d}; actual={d}:{d} parent={d}:{d} kind={d} bytes={d} deadline={d} flags={x} result={d} address={x}",
            .{ @errorName(err), handle.id, handle.generation, parent.id, parent.generation, kind, self.descriptor.byte_length, self.deadline,
                result.resource.id, result.resource.generation, result.parent.id, result.parent.generation, result.kind,
                result.byte_length, result.deadline_ns, result.flags, result.result, result.address });
        try d.platform(device.base().gfxVirtualQuery(&handle, &result));
        if (!payload(result) or !equal(result.resource, handle) or !equal(result.parent, parent) or result.kind != kind or
            result.byte_length != self.descriptor.byte_length or result.deadline_ns != self.deadline or result.reserved0 != 0 or
            result.flags & ~@as(u32, 15) != 0) return error.Invalid;
        // Bit 3 is the common owner's in-flight driver claim. Its result is
        // still zero until bit 0 publishes the exact create completion; a
        // claimed request is not a failed or usable mapping.
        if (result.flags & 1 == 0) {
            if (result.result != 0) return error.Invalid;
            if (result.flags & 6 != 0) return error.Stale;
            return false;
        }
        try d.platform(result.result);
        if (result.flags != 1 or result.address % granule != 0 or result.address < profile.va_start or
            result.address >= profile.va_end or result.byte_length > profile.va_end - result.address or
            (self.address != 0 and self.address != result.address)) return error.Unsupported;
        self.address = result.address;
        return true;
    }
    // One start/query transition per step, never a wait or an unbounded loop.
    pub fn step(self: *Resource, device: *d.Device, profile: Profile) d.Error!bool {
        return self.advance(device, profile) catch |err| {
            if (err != error.Busy) @import("native_diagnostics.zig").Trace.init(device).detail(
                "R4GFX virtual-step error={s} BO={d}:{d} range={d}:{d} binding={d}:{d} bytes={d} deadline={d} ready={} retiring={} CPU-lease={d}:{d}",
                .{ @errorName(err), self.backing.buffer.id, self.backing.buffer.generation, self.range.id, self.range.generation,
                    self.binding.id, self.binding.generation, self.descriptor.byte_length, self.deadline, self.ready, self.retiring,
                    self.map.lease.id, self.map.lease.generation });
            return err;
        };
    }
    fn advance(self: *Resource, device: *d.Device, profile: Profile) d.Error!bool {
        if (self.failed) |err| return err;
        if (self.retiring) return error.Busy;
        if (self.ready) return true;
        if (!valid(self.backing.reference)) return error.Invalid;
        const base = device.base();
        if (!valid(self.range)) {
            var result: a.GfxVirtualStatus = .{};
            try d.platform(base.gfxVirtualStart(&.{ .kind = 1, .adapter_id = profile.binding.adapter_id, .memory_generation = profile.memory_generation, .deadline_ns = self.deadline, .byte_length = self.descriptor.byte_length, .alignment = granule, .location = @intFromBool(self.descriptor.location == a.gfx_buffer_location_device_local), .flags = if (self.descriptor.modifier != 0 and profile.backend == d.c.render_backend_nvidia) a.gfx_virtual_flag_blocklinear | (6 << a.gfx_virtual_layout_shift) else 0 }, &result));
            self.range = result.resource;
            if (!valid(self.range)) return error.Invalid;
            return false;
        }
        if (!valid(self.binding)) {
            if (!try self.query(device, profile, self.range, .{}, 1)) return false;
            var result: a.GfxVirtualStatus = .{};
            try d.platform(base.gfxVirtualStart(&.{ .kind = 2, .adapter_id = profile.binding.adapter_id, .memory_generation = profile.memory_generation, .parent = self.range, .reference = self.backing.reference, .byte_length = self.descriptor.byte_length, .deadline_ns = self.deadline }, &result));
            self.binding = result.resource;
            if (!valid(self.binding)) return error.Invalid;
            return false;
        }
        self.ready = try self.query(device, profile, self.binding, self.range, 2);
        return self.ready;
    }
    pub fn close(self: *Resource, device: *d.Device) d.Error!void {
        self.ready = false;
        if (valid(self.range)) {
            const base = device.base();
            if (!self.retiring) {
                try d.platform(base.gfxVirtualClose(&self.range, 0));
                self.retiring = true;
            }
            var result: a.GfxVirtualStatus = .{};
            try d.platform(base.gfxVirtualQuery(&self.range, &result));
            if (!payload(result) or !equal(result.resource, self.range) or result.flags & ~@as(u32, 15) != 0) return error.Invalid;
            if (result.flags & 6 != 6) return error.Busy;
            try d.platform(base.gfxVirtualClose(&self.range, 1));
            self.range = .{};
            self.binding = .{};
        }
        if (valid(self.map.lease)) {
            try d.platform(device.buffers().unmap(&self.map.lease));
            self.map = .{};
        }
        if (valid(self.backing.reference)) {
            try d.platform(device.buffers().release(&self.backing.reference));
            self.backing = .{};
        }
        self.* = .{};
    }
};
