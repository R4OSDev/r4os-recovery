// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Optional vendor protocols meet only at the common BO/queue boundary.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const c = @import("r4l_contract");
const nv = @import("r4nv_binding");
const amd = @import("r4amd_binding");

pub const Selection = struct { backend: u32, operations: u32 };
pub const Registry = struct {
    nvidia: ?nv.BackendV1Client = null,
    amdgpu: ?amd.BackendV1Client = null,

    pub fn init(raw: *const a.R4XStartContext, software: bool) Registry {
        if (software) return .{};
        return .{ .nvidia = nv.BackendV1Client.init(raw) catch null, .amdgpu = amd.BackendV1Client.init(raw) catch null };
    }
    pub fn initCaller(caller: *const @import("library_caller").Snapshot, software: bool) Registry {
        if (software) return .{};
        return .{ .nvidia = caller.client(nv.BackendV1Client) catch null, .amdgpu = caller.client(amd.BackendV1Client) catch null };
    }
    pub fn available(self: Registry) bool { return self.nvidia != null or self.amdgpu != null; }
    pub fn negotiate(self: Registry, snapshot: a.GfxBackendInfo) ?Selection {
        // Operations and the memory epoch belong to the current provider;
        // neither may be inferred from a shorter device/queue snapshot.
        if (snapshot.version != 1 or snapshot.size < @sizeOf(a.GfxBackendInfo) or snapshot.memory_generation == 0) return null;
        const profile = snapshot.profile;
        const binding = snapshot.binding;
        if (profile.version != 1 or profile.size < @sizeOf(a.GfxBackendProfile) or profile.revision != 1 or profile.data_bytes > profile.data.len) return null;
        for (profile.data[profile.data_bytes..]) |byte| if (byte != 0) return null;
        const operations = snapshot.operations;
        if (operations & (@as(u64, 1) << a.gfx_queue_operation_copy) == 0) return null;
        if (profile.interface_id_lo == nv.backend_v1_header.interface_id_lo and profile.interface_id_hi == nv.backend_v1_header.interface_id_hi) {
            const client = self.nvidia orelse return null;
            if (profile.data_bytes != @sizeOf(nv.R4NvDriverProfile)) return null;
            const details = std.mem.bytesToValue(nv.R4NvDriverProfile, profile.data[0..@sizeOf(nv.R4NvDriverProfile)]);
            // Reject an AMD/unknown identity before entering any NVIDIA code.
            if (details.version != 1 or details.size != @sizeOf(nv.R4NvDriverProfile) or details.vendor_id != 0x10de or details.reserved0 != 0 or details.reserved1 != 0) return null;
            var features: nv.R4NvFeatures = undefined;
            if (client.negotiate(&.{ .version = 1, .size = @sizeOf(nv.R4NvDeviceProfile), .vendor_id = details.vendor_id,
                .copy_class = details.copy_class, .rm_release = details.rm_release, .command_abi = details.command_abi,
                .adapter_id = binding.adapter_id, .flags = 0, .device_generation = binding.device_generation, .reset_generation = binding.reset_generation }, &features) != nv.status_ok or
                features.version != 1 or features.size != @sizeOf(nv.R4NvFeatures) or features.command_abi != details.command_abi or
                features.copy_class != details.copy_class or features.features & nv.feature_copy_linear == 0 or features.reserved != 0) return null;
            var result: u32 = c.device_gpu_copy;
            if (operations & 8 != 0 and features.features & nv.feature_copy_rows != 0) {
                result |= c.device_gpu_copy_rows;
                if (features.features & nv.feature_copy_layout != 0) result |= c.device_gpu_copy_layout;
            }
            if (operations & 16 != 0) result |= c.device_gpu_render;
            if (operations & 32 != 0) result |= c.device_gpu_present;
            if (operations & 64 != 0) result |= c.device_gpu_render_list;
            if (operations & 128 != 0) result |= c.device_gpu_direct;
            if (operations & 256 != 0) result |= c.device_gpu_grid;
            if (operations & 512 != 0) result |= c.device_gpu_color;
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_render_color_grid_list) != 0) result |= c.device_gpu_color_grid;
            return .{ .backend = c.render_backend_nvidia, .operations = result };
        }
        if (profile.interface_id_lo == amd.backend_v1_header.interface_id_lo and profile.interface_id_hi == amd.backend_v1_header.interface_id_hi) {
            const client = self.amdgpu orelse return null;
            if (profile.data_bytes != @sizeOf(amd.R4AmdDriverProfile)) return null;
            const details = std.mem.bytesToValue(amd.R4AmdDriverProfile, profile.data[0..@sizeOf(amd.R4AmdDriverProfile)]);
            if (details.version != amd.profile_version or details.size != @sizeOf(amd.R4AmdDriverProfile) or details.vendor_id != amd.vendor_id or details.reserved != 0) return null;
            var features: amd.R4AmdFeatures = undefined;
            if (client.negotiate(&.{ .version = 1, .size = @sizeOf(amd.R4AmdDeviceProfile), .vendor_id = details.vendor_id,
                .device_id = details.device_id, .gc_version = details.gc_version, .sdma_version = details.sdma_version, .command_abi = details.command_abi,
                .flags = 0, .adapter_id = binding.adapter_id, .reserved = 0, .device_generation = binding.device_generation, .reset_generation = binding.reset_generation }, &features) != amd.status_ok or
                features.version != 1 or features.size != @sizeOf(amd.R4AmdFeatures) or features.command_abi != details.command_abi or
                features.features & amd.feature_copy_linear == 0 or features.gpu_address_bits < 32 or features.gpu_address_bits > 64 or
                features.max_command_words == 0 or features.reserved0 != 0 or features.reserved1 != 0) return null;
            var result: u32 = c.device_gpu_copy;
            if (operations & 8 != 0 and features.features & amd.feature_copy_rows != 0) {
                result |= c.device_gpu_copy_rows;
                if (features.features & amd.feature_copy_layout != 0) result |= c.device_gpu_copy_layout;
            }
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_render) != 0) result |= c.device_gpu_render;
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_render_list) != 0) result |= c.device_gpu_render_list;
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_render_grid_list) != 0) result |= c.device_gpu_grid;
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_render_color_list) != 0) result |= c.device_gpu_color;
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_render_color_grid_list) != 0) result |= c.device_gpu_color_grid;
            if (operations & (@as(u64, 1) << a.gfx_queue_operation_present) != 0) result |= c.device_gpu_present;
            return .{ .backend = c.render_backend_amd, .operations = result };
        }
        return null;
    }
};

pub fn hardware(backend: u32) bool { return backend == c.render_backend_nvidia or backend == c.render_backend_amd; }
