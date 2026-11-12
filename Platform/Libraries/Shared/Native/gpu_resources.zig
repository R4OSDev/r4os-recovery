// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const nv = @import("r4nv_binding");
const amd = @import("r4amd");
const amd_media = @import("r4amd_media");
pub const Provider = enum { nvidia, amd };
const Budget = @import("native_allocation").Budget;

pub const Error = error{ Invalid, Unsupported, NoMemory, Busy, Stale, Timeout, Internal };
pub const granule: u64 = 65536;
pub const address_limit: u64 = 1 << 40; // Video method addresses, not the GPU's VA width.
const duration_ns: u64 = 5_000_000_000;
const modifier_base: u64 = 0x0300000000606010; // Uncompressed Turing generic kind 6.
pub const Clock = *const fn () ?a.MonotonicClockInfo;

pub const Engine = enum {
    decode,
    encode,
    jpeg,
    graphics,

    pub fn mask(self: Engine) u32 {
        return switch (self) {
            .decode, .jpeg => nv.native_engine_video,
            .encode => nv.native_engine_encode,
            .graphics => nv.native_engine_graphics,
        };
    }
};

fn payload(value: anytype) bool {
    return value.version == 1 and value.size >= @sizeOf(@TypeOf(value));
}
fn valid(value: a.GfxBufferHandle) bool {
    return value.id != 0 and value.generation != 0 and value.reserved0 == 0;
}
fn equal(left: anytype, right: @TypeOf(left)) bool {
    return std.meta.eql(left, right);
}
fn result(rc: i32) Error!void {
    return switch (rc) {
        1 => {},
        a.gfx_buffer_error_oom, a.gfx_buffer_error_budget, a.gfx_buffer_error_capacity => error.NoMemory,
        a.gfx_buffer_error_busy => error.Busy,
        a.gfx_buffer_error_stale, a.gfx_buffer_error_closed, a.gfx_queue_error_device_lost => error.Stale,
        a.gfx_queue_error_wait_timeout, a.gfx_queue_error_wait_cancelled => error.Timeout,
        a.gfx_buffer_error_unsupported, a.gfx_buffer_error_unavailable, a.err_no_fn, a.err_no_group => error.Unsupported,
        a.gfx_buffer_error_invalid, a.gfx_buffer_error_overflow => error.Invalid,
        else => error.Internal,
    };
}
fn rounded(bytes: u64) Error!usize {
    if (bytes == 0 or bytes > address_limit - granule) return error.Invalid;
    return @intCast(std.mem.alignForward(u64, bytes, granule));
}
fn extent(offset: u64, bytes: u64, limit: u64) bool {
    return bytes != 0 and bytes <= limit and offset <= limit - bytes;
}

pub const Device = struct {
    binding: a.GfxBackendBinding,
    memory_generation: u64,
    va_start: u64,
    va_end: u64,
    class: u32,
    engine: Engine = .decode,
    provider: Provider = .nvidia,

    // Architecture selects a packet format. Actual engine/class admission is
    // performed by the native queue on submission; no GR template is required.
    pub fn query(base: r.program.Context, adapter: u32) Error!Device {
        return queryFor(base, adapter, .decode);
    }
    pub fn queryFor(base: r.program.Context, adapter: u32, engine: Engine) Error!Device {
        if (adapter == 0) return error.Invalid;
        const q: r.gfx_queue.Context = .{ .base = base };
        var found: ?a.GfxBackendInfo = null;
        for (0..a.gfx_queue_backend_capacity) |index| {
            var info: a.GfxBackendInfo = .{};
            const rc = q.backendInfo(@intCast(index), &info);
            if (rc == 0) break;
            try result(rc);
            if (!payload(info) or !payload(info.binding)) return error.Internal;
            if (info.binding.adapter_id == adapter) {
                found = info;
                break;
            }
        }
        const info = found orelse return error.Unsupported;
        const profile = info.profile;
        if (profile.interface_id_lo == amd.backend_v1_header.interface_id_lo and profile.interface_id_hi == amd.backend_v1_header.interface_id_hi) return queryAmd(q, info, engine);
        if (info.binding.milestone != a.gfx_queue_milestone_device_execution or
            info.binding.device_generation == 0 or info.binding.reset_generation == 0 or info.memory_generation == 0 or
            info.operations & (@as(u64, 1) << a.gfx_queue_operation_native) == 0 or
            !payload(profile) or profile.interface_id_lo != nv.backend_v1_header.interface_id_lo or
            profile.interface_id_hi != nv.backend_v1_header.interface_id_hi or profile.revision != 1 or
            profile.data_bytes != @sizeOf(nv.R4NvDriverProfile)) return error.Unsupported;
        const protocol = std.mem.bytesToValue(nv.R4NvDriverProfile, profile.data[0..@sizeOf(nv.R4NvDriverProfile)]);
        if (!payload(protocol) or protocol.vendor_id != 0x10de or protocol.rm_release != nv.rm_release or
            protocol.command_abi != nv.command_abi or protocol.reserved0 != 0 or protocol.reserved1 != 0) return error.Unsupported;
        var properties: a.GfxBackendProperties = .{};
        try result(q.backendProperties(&info.binding, &properties));
        if (!payload(properties) or properties.interface_id_lo != profile.interface_id_lo or
            properties.interface_id_hi != profile.interface_id_hi or properties.revision != nv.architecture_version or
            properties.data_bytes != @sizeOf(nv.R4NvArchitecture)) return error.Unsupported;
        for (properties.data[properties.data_bytes..]) |byte| if (byte != 0) return error.Invalid;
        const arch = std.mem.bytesToValue(nv.R4NvArchitecture, properties.data[0..@sizeOf(nv.R4NvArchitecture)]);
        const class: u32 = switch (arch.chipset) {
            0x172, 0x173, 0x174, 0x176, 0x177 => switch (engine) { .decode => 0xc7b0, .encode => 0xc7b7, .graphics => 0xc797, .jpeg => return error.Unsupported },
            0x192, 0x193, 0x194, 0x196, 0x197 => switch (engine) { .decode => 0xc9b0, .encode => 0xc9b7, .graphics => 0xc997, .jpeg => return error.Unsupported },
            else => return error.Unsupported,
        };
        // This path uses persistent write-back system BOs. Require the driver's
        // acknowledged CPU/GPU coherency policy, never infer it from PCI IDs.
        const flags = nv.architecture_image_layouts | nv.architecture_host_coherent;
        if (arch.version != properties.revision or arch.size != @sizeOf(nv.R4NvArchitecture) or
            arch.vendor_id != 0x10de or arch.rm_release != nv.rm_release or arch.flags != flags or
            arch.bind_alignment != granule or arch.va_start == 0 or arch.va_start >= arch.va_end or
            arch.va_start >= address_limit or arch.va_end > (@as(u64, 1) << 49) or
            (arch.va_start | arch.va_end) % granule != 0) return error.Unsupported;
        if (arch.memory_generation != info.memory_generation) return error.Stale;
        if (engine == .graphics and (arch.graphics_class != class or
            arch.shader_model != (if (class == 0xc797) @as(u32, 86) else 89))) return error.Unsupported;
        return .{ .binding = info.binding, .memory_generation = arch.memory_generation,
            .va_start = arch.va_start, .va_end = @min(arch.va_end, address_limit), .class = class, .engine = engine };
    }
    pub fn queryProvider(base: r.program.Context, adapter: u32, engine: Engine, provider: Provider) Error!Device {
        const device = try queryFor(base, adapter, engine);
        if (device.provider != provider) return error.Unsupported;
        return device;
    }
    /// Eligibility is deliberately separate from each library's implemented
    /// codec set. A valid source profile alone must never start a decoder.
    pub fn mediaCaps(self: Device, codec: u32, profile: u32, depth: u32, chroma: u32) Error!amd.R4AmdMediaCaps {
        if (self.provider != .amd or self.engine == .graphics) return error.Unsupported;
        return amd_media.Provider(amd).limits(.{ .version = 1, .size = @sizeOf(amd.R4AmdMediaQuery), .vendor_id = amd.vendor_id,
            .device_id = 0x15d8, .gc_version = switch (self.class) {
                amd.vcn_1_0_0 => amd.gc_9_1_0, amd.vcn_1_0_1 => amd.gc_9_2_2, else => return error.Unsupported },
            .vcn_version = self.class, .firmware_version = if (self.class == amd.vcn_1_0_1) amd.raven2_vcn_firmware else amd.picasso_vcn_firmware,
            .operation = @intFromBool(self.engine == .encode), .codec = codec, .profile = profile, .bit_depth = depth, .chroma = chroma,
            .width = 0, .height = 0, .flags = 0, .reserved = 0 });
    }
    fn queryAmd(q: r.gfx_queue.Context, info: a.GfxBackendInfo, engine: Engine) Error!Device {
        const profile = info.profile;
        if (info.binding.milestone != a.gfx_queue_milestone_device_execution or info.binding.device_generation == 0 or
            info.binding.reset_generation == 0 or info.memory_generation == 0 or info.operations & (@as(u64, 1) << a.gfx_queue_operation_native) == 0 or
            !payload(profile) or profile.revision != 1 or profile.data_bytes != @sizeOf(amd.R4AmdDriverProfile)) return error.Unsupported;
        const protocol = std.mem.bytesToValue(amd.R4AmdDriverProfile, profile.data[0..@sizeOf(amd.R4AmdDriverProfile)]);
        const raven2 = protocol.gc_version == amd.gc_9_2_2 and protocol.sdma_version == amd.sdma_4_1_1;
        const picasso = protocol.gc_version == amd.gc_9_1_0 and protocol.sdma_version == amd.sdma_4_1_0;
        if (!payload(protocol) or protocol.vendor_id != amd.vendor_id or protocol.device_id != 0x15d8 or (!picasso and !raven2) or
            protocol.command_abi != amd.command_abi or protocol.reserved != 0) return error.Unsupported;
        var properties: a.GfxBackendProperties = .{};
        try result(q.backendProperties(&info.binding, &properties));
        if (!payload(properties) or properties.interface_id_lo != amd.image_v1_header.interface_id_lo or
            properties.interface_id_hi != amd.image_v1_header.interface_id_hi or properties.revision != 3 or
            properties.data_bytes != @sizeOf(amd.R4AmdDeviceFactsV3)) return error.Unsupported;
        const value = std.mem.bytesToValue(amd.R4AmdDeviceFactsV3, properties.data[0..@sizeOf(amd.R4AmdDeviceFactsV3)]);
        const facts = value.facts; const arch = facts.architecture;
        if (!payload(facts) or !payload(arch) or arch.vendor_id != amd.vendor_id or arch.device_id != 0x15d8 or
            arch.gc_version != protocol.gc_version or arch.sdma_version != protocol.sdma_version or arch.flags != 0 or arch.reserved != 0 or
            arch.chip_revision < (if (raven2) @as(u32, 0x81) else 0x41) or arch.chip_revision > (if (raven2) @as(u32, 0x88) else 0x48) or
            arch.bind_alignment != 4096 or facts.flags & ~@as(u32, 15) != 0 or facts.flags & 3 != 3 or facts.reserved != 0 or
            facts.va_start != amd.native_va_start or facts.va_end != amd.native_va_end or value.native_binding_capacity < 24 or
            value.max_backing_bytes == 0) return error.Unsupported;
        if (arch.memory_generation != info.memory_generation) return error.Stale;
        if (engine != .graphics and facts.flags & amd.device_fact_vcn1_ready == 0) return error.Unsupported;
        if (engine == .jpeg and facts.flags & amd.device_fact_jpeg1_submit == 0) return error.Unsupported;
        return .{ .binding = info.binding, .memory_generation = arch.memory_generation, .va_start = facts.va_start,
            .va_end = facts.va_end, .class = if (engine == .graphics) arch.gc_version else if (raven2) amd.vcn_1_0_1 else amd.vcn_1_0_0,
            .engine = engine, .provider = .amd };
    }
};

// Stable, single-worker owner. Every Resource borrows this Context and its
// budget until close succeeds. The caller retains both through all codec and
// public loans. Failed operations leave exact handles for later cleanup.
pub const Context = struct {
    base: r.program.Context,
    device: Device,
    budget: *Budget,
    clock: Clock,
    timeout_ns: u64 = duration_ns,
    until_ns: u64 = 0, // Optional whole-job bound shared by preparation/codec.
    queue: a.GfxQueueHandle = .{},
    fence: a.GfxFence = .{},
    poisoned: bool = false,

    fn buffers(self: *const Context) r.gfx_buffers.Context {
        return .{ .base = self.base };
    }
    fn queues(self: *const Context) r.gfx_queue.Context {
        return .{ .base = self.base };
    }
    fn instant(self: *const Context) Error!a.MonotonicClockInfo {
        const clock = self.clock() orelse return error.Internal;
        if (clock.flags & a.monotonic_clock_flag_valid == 0 or clock.frequency_hz != 1_000_000_000 or
            clock.event_frequency_numerator == 0 or clock.event_frequency_denominator == 0) return error.Internal;
        return clock;
    }
    pub fn deadline(self: *const Context) Error!u64 {
        if (self.timeout_ns == 0 or self.timeout_ns > duration_ns) return error.Invalid;
        const now = (try self.instant()).instant_ns;
        const local = std.math.add(u64, now, self.timeout_ns) catch return error.Internal;
        if (self.until_ns == 0) return local;
        if (self.until_ns <= now) return error.Timeout;
        return @min(local, self.until_ns);
    }
    fn ticks(self: *const Context, until: u64) Error!u64 {
        const clock = try self.instant();
        if (until <= clock.instant_ns) return error.Timeout;
        const numerator: u128 = @as(u128, until - clock.instant_ns) * clock.event_frequency_numerator;
        const denominator: u128 = @as(u128, clock.event_frequency_denominator) * 1_000_000_000;
        return @intCast(@min((numerator + denominator - 1) / denominator, std.math.maxInt(u64) - 1));
    }

    pub const Loan = struct { resource: *const Resource, write: bool };
    // All indirect references (DPB, status, scratch and commands) are listed.
    // The common broker snapshots independent BO/VA loans before returning.
    pub fn submit(self: *Context, commands: *const Resource, command_bytes: u32, loans: []const Loan) Error!void {
        if (self.poisoned) return error.Stale;
        if (self.fence.timeline != 0) return error.Busy;
        if (!commands.ready or commands.owner != self or command_bytes == 0 or command_bytes % 4 != 0 or
            command_bytes > commands.descriptor.byte_length or loans.len > 63) return error.Invalid;
        var bindings: [64]a.GfxNativeResource = undefined;
        bindings[0] = .{ .binding = commands.binding };
        var count: usize = 1;
        for (loans) |loan| {
            const resource = loan.resource;
            if (!resource.ready or resource.owner != self or !valid(resource.binding)) return error.Invalid;
            var duplicate = false;
            for (bindings[0..count]) |*entry| if (equal(entry.binding, resource.binding)) {
                entry.access |= @intFromBool(loan.write);
                duplicate = true;
                break;
            };
            if (!duplicate) {
                bindings[count] = .{ .binding = resource.binding, .access = @intFromBool(loan.write) };
                count += 1;
            }
        }
        if (self.device.provider == .amd and (self.device.engine == .graphics or command_bytes % 64 != 0 or command_bytes > 8192 or count > 32)) return error.Unsupported;
        // JPEG1's kernel worker reads/copies the system IB into VMID0. Its
        // ordinary CPU read cannot coexist with a producer's persistent write.
        if (self.device.provider == .amd and self.device.engine == .jpeg and valid(commands.mapping.lease)) return error.Busy;
        const until = try self.deadline();
        if (self.queue.timeline == 0) {
            const binding = self.device.binding;
            try result(self.queues().open(&.{ .adapter_id = binding.adapter_id, .capacity = 1,
                .milestone = binding.milestone, .device_generation = binding.device_generation,
                .reset_generation = binding.reset_generation }, &self.queue));
            if (!payload(self.queue) or self.queue.timeline == 0) return error.Internal;
        }
        const packet = extern struct { header: nv.R4NvNativeSubmitHeader, push: nv.R4NvNativePush }{
            .header = .{ .version = nv.native_submit_version, .size = @sizeOf(nv.R4NvNativeSubmitHeader),
                .engine_mask = self.device.engine.mask(), .push_count = 1, .reserved0 = 0, .reserved1 = 0 },
            .push = .{ .address = commands.address, .byte_length = command_bytes, .flags = 0 },
        };
        const amd_packet = extern struct { header: amd.R4AmdNativeSubmit, ib: amd.R4AmdNativeIb }{
            .header = .{ .version = 1, .size = @sizeOf(amd.R4AmdNativeSubmit), .engine = if (self.device.engine == .jpeg) 4 else if (self.device.engine == .decode) 2 else 3,
                .ib_count = 1, .flags = 0, .reserved0 = 0, .reserved1 = 0 },
            .ib = .{ .address = commands.address, .dwords = command_bytes / 4, .binding_index = 0 },
        };
        const submission: a.GfxSubmission = .{ .operation = a.gfx_queue_operation_native, .deadline_ns = until };
        var native: a.GfxNativeSubmission = .{ .interface_id_lo = nv.backend_v1_header.interface_id_lo,
            .interface_id_hi = nv.backend_v1_header.interface_id_hi, .revision = 1,
            .command_bytes = @sizeOf(@TypeOf(packet)), .commands = @intFromPtr(&packet),
            .resource_count = @intCast(count), .resources = @intFromPtr(&bindings) };
        if (self.device.provider == .amd) {
            native.interface_id_lo = amd.backend_v1_header.interface_id_lo; native.interface_id_hi = amd.backend_v1_header.interface_id_hi;
            native.command_bytes = @sizeOf(@TypeOf(amd_packet)); native.commands = @intFromPtr(&amd_packet);
        }
        // WB stores precede the doorbell; the driver owns HOST WFI/SYS_MEMBAR
        // and semaphore completion. No MMIO or private physical pinning here.
        asm volatile ("mfence" ::: .{ .memory = true });
        var status: a.GfxFenceStatus = .{};
        try result(self.queues().submitNative(&self.queue, &submission, &native, &status));
        self.fence = status.fence;
        errdefer self.poisoned = true;
        if (!self.matches(status) or status.deadline_ns != until) return error.Internal;
        try self.wait(until);
    }
    fn matches(self: *const Context, status: a.GfxFenceStatus) bool {
        return payload(status) and equal(status.fence, self.fence) and self.fence.adapter_id == self.device.binding.adapter_id and
            self.fence.timeline == self.queue.timeline and self.fence.point != 0 and
            self.fence.device_generation == self.device.binding.device_generation and
            self.fence.reset_generation == self.device.binding.reset_generation and
            status.milestone == a.gfx_queue_milestone_device_execution and
            status.flags & ~@as(u32, 3) == 0 and status.phase <= a.gfx_queue_phase_terminal;
    }
    fn wait(self: *Context, until: u64) Error!void {
        var status: a.GfxFenceStatus = .{};
        try result(self.queues().wait(&self.fence, try self.ticks(until), a.gfx_queue_wait_resources_released, &status));
        if (!self.matches(status) or status.phase != a.gfx_queue_phase_terminal or status.flags != 0) return error.Internal;
        try result(self.queues().release(&self.fence));
        self.fence = .{};
        if (status.result != a.gfx_queue_result_complete) return switch (status.result) {
            a.gfx_queue_result_timeout, a.gfx_queue_result_cancelled => error.Timeout,
            a.gfx_queue_result_device_lost => error.Stale,
            else => error.Internal,
        };
        asm volatile ("mfence" ::: .{ .memory = true });
        // This is only ordered engine completion. The codec owner must inspect
        // fresh picture status before publishing output or reusing scratch.
    }
    pub fn close(self: *Context) Error!void {
        self.poisoned = true;
        if (self.fence.timeline != 0) {
            var status: a.GfxFenceStatus = .{};
            try result(self.queues().query(&self.fence, &status));
            if (!self.matches(status)) return error.Internal;
            if (status.phase != a.gfx_queue_phase_terminal) {
                const rc = self.queues().cancel(&self.fence);
                if (rc != a.gfx_queue_error_already_completed) try result(rc);
                return error.Busy;
            }
            if (status.flags != 0) return error.Busy;
            try result(self.queues().release(&self.fence));
            self.fence = .{};
        }
        if (self.queue.timeline != 0) {
            const rc = self.queues().close(&self.queue);
            // A reset may already have removed an empty queue. Only after the
            // exact outstanding fence was physically released above is Stale
            // an idempotent queue-close receipt; it never retires a job or BO.
            if (rc != a.gfx_queue_error_stale) try result(rc);
            self.queue = .{};
        }
    }
};

pub const Resource = struct {
    owner: ?*Context = null,
    backing: a.GfxBufferReference = .{},
    descriptor: a.GfxBufferDescriptor = .{},
    mapping: a.GfxBufferMap = .{},
    pending: a.GfxBufferHandle = .{},
    range: a.GfxBufferHandle = .{},
    binding: a.GfxBufferHandle = .{},
    address: u64 = 0,
    charged: usize = 0,
    ready: bool = false,
    retiring: bool = false,
    borrowed: bool = false,

    /// A retained external BO already charged by its input/session owner. That
    /// owner must outlive this VA loan and every submitted fence. No extra CPU
    /// map, allocation, reference release or duplicate budget charge occurs.
    pub fn borrow(self: *Resource, ctx: *Context, backing: a.GfxBufferReference) Error!void {
        if (self.owner != null) return error.Busy;
        if (ctx.poisoned) return error.Stale;
        if (!payload(backing) or !valid(backing.reference) or !valid(backing.buffer) or
            backing.reserved0 != 0 or backing.flags & ~a.gfx_buffer_reference_immutable != 0) return error.Invalid;
        var d: a.GfxBufferDescriptor = .{};
        try result(ctx.buffers().describe(&backing.reference, &d));
        if (!payload(d) or d.reserved0 != 0 or d.byte_length == 0 or d.byte_length >= address_limit or
            d.byte_length % granule != 0 or d.alignment < @as(u64, if (ctx.device.provider == .amd) 4096 else granule) or !std.math.isPowerOfTwo(d.alignment) or
            d.usage & a.gfx_buffer_usage_transfer_source == 0) return error.Unsupported;
        if (d.location == a.gfx_buffer_location_device_local) {
            if (d.adapter_id != ctx.device.binding.adapter_id or d.device_generation != ctx.device.memory_generation or
                d.driver_owner == 0) return error.Stale;
        } else if (d.location != a.gfx_buffer_location_system or d.modifier != 0 or d.adapter_id != 0 or
            d.device_generation != 0 or d.driver_owner != 0) return error.Unsupported;
        if (ctx.device.provider == .amd and d.modifier != 0) return error.Unsupported;
        if (d.modifier != 0 and (d.modifier & ~@as(u64, 15) != modifier_base or d.modifier & 15 > 5)) return error.Unsupported;
        const until = try ctx.deadline();
        self.owner = ctx;
        self.borrowed = true;
        self.backing = backing;
        self.descriptor = d;
        try self.bind(until);
    }

    fn begin(self: *Resource, ctx: *Context, bytes: usize) Error!u64 {
        if (self.owner != null) return error.Busy;
        if (ctx.poisoned) return error.Stale;
        const until = try ctx.deadline();
        if (!ctx.budget.reserve(bytes)) return error.NoMemory;
        self.owner = ctx;
        self.charged = bytes;
        return until;
    }
    pub fn system(self: *Resource, ctx: *Context, bytes: u64) Error!void {
        const size = try rounded(bytes);
        const until = try self.begin(ctx, size);
        const requested: a.GfxBufferDescriptor = .{ .byte_length = size, .alignment = granule,
            .usage = a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write |
                a.gfx_buffer_usage_transfer_source | a.gfx_buffer_usage_transfer_target };
        try result(ctx.buffers().create(&requested, &self.backing));
        try self.describe(false);
        if (self.descriptor.format != a.gfx_buffer_format_bytes or self.descriptor.plane_count != 0 or
            self.descriptor.modifier != 0 or self.descriptor.byte_length != size) return error.Invalid;
        try result(ctx.buffers().mapPersistent(&self.backing.reference, a.gfx_buffer_map_write, 0, size, &self.mapping));
        if (!payload(self.mapping) or !valid(self.mapping.lease) or self.mapping.cpu_address == 0 or
            self.mapping.byte_length != size or self.mapping.cpu_address > std.math.maxInt(usize) - size or
            self.mapping.cache_policy != a.gfx_buffer_cache_write_back or self.mapping.reserved0 != 0) return error.Unsupported;
        @memset(@as([*]u8, @ptrFromInt(self.mapping.cpu_address))[0..size], 0);
        try self.bind(until);
    }
    pub fn video(self: *Resource, ctx: *Context, bytes: u64) Error!void {
        const size = try rounded(bytes);
        const until = try self.begin(ctx, size);
        try self.native(.{ .byte_length = size, .usage = 12 }, until);
        try self.describe(true);
        if (self.descriptor.format != a.gfx_buffer_format_bytes or self.descriptor.plane_count != 0 or
            self.descriptor.modifier != 0 or self.descriptor.byte_length != size) return error.Invalid;
        try self.bind(until);
    }
    pub fn yuv(self: *Resource, ctx: *Context, width: u32, height: u32, depth: u32) Error!void {
        if (ctx.device.provider != .amd) {
            if (depth != 8) return error.Unsupported;
            return self.nv12(ctx, width, height);
        }
        const layout = amd_media.Surface.plan(width, height, depth) catch return error.Unsupported;
        const until = try self.begin(ctx, @intCast(layout.bytes));
        const format: u32 = if (depth == 8) a.gfx_buffer_format_nv12 else a.gfx_buffer_format_p010;
        try self.native(.{ .kind = 1, .width = width, .height = height, .format = format, .usage = 28, .layout = 0 }, until);
        try self.describe(true);
        const d = self.descriptor;
        if (d.format != format or d.plane_count != 2 or d.width != width or d.height != height or d.modifier != 0 or
            d.byte_length != layout.bytes or d.plane_offsets[0] != 0 or d.plane_offsets[1] != layout.chroma_offset or
            d.plane_pitches[0] != layout.pitch or d.plane_pitches[1] != layout.pitch or d.plane_offsets[2] != 0 or d.plane_offsets[3] != 0 or
            d.plane_pitches[2] != 0 or d.plane_pitches[3] != 0) return error.Unsupported;
        try self.bind(until);
    }
    pub fn nv12(self: *Resource, ctx: *Context, width: u32, height: u32) Error!void {
        if (ctx.device.provider == .amd) return self.yuv(ctx, width, height, 8);
        if (width == 0 or height == 0 or width > 4096 or height > 4096 or (width | height) % 16 != 0) return error.Invalid;
        // Native allocation chooses an authenticated modifier. At least 32
        // storage rows guarantee >=2 GOBs for NVDEC even for a 16-row picture.
        const storage_height = @max(height, 32);
        const pitch = std.mem.alignForward(u64, width, 64);
        const upper = try rounded(pitch * std.mem.alignForward(u64, storage_height, 256));
        const chroma_upper = try rounded(pitch * std.mem.alignForward(u64, storage_height / 2, 256));
        const until = try self.begin(ctx, upper + chroma_upper);
        try self.native(.{ .kind = 1, .width = width, .height = storage_height,
            .format = a.gfx_buffer_format_nv12, .usage = 28, .layout = 1 }, until);
        try self.describe(true);
        const d = self.descriptor;
        if (d.format != a.gfx_buffer_format_nv12 or d.plane_count != 2 or d.width != width or d.height != storage_height or
            d.modifier & ~@as(u64, 15) != modifier_base or d.modifier & 15 < 1 or d.modifier & 15 > 5 or
            d.plane_pitches[0] != pitch or d.plane_pitches[1] != pitch or d.plane_offsets[0] != 0 or
            d.plane_offsets[1] % granule != 0 or d.plane_offsets[2] != 0 or d.plane_offsets[3] != 0 or
            d.plane_pitches[2] != 0 or d.plane_pitches[3] != 0) return error.Unsupported;
        const block_rows: u64 = @as(u64, 8) << @intCast(d.modifier & 15);
        const luma = pitch * std.mem.alignForward(u64, storage_height, block_rows);
        const chroma = pitch * std.mem.alignForward(u64, storage_height / 2, block_rows);
        if (d.plane_offsets[1] < luma or !extent(0, luma, d.byte_length) or
            !extent(d.plane_offsets[1], chroma, d.byte_length)) return error.Invalid;
        try self.bind(until);
    }
    fn native(self: *Resource, allocation: a.GfxNativeAllocation, until: u64) Error!void {
        const ctx = self.owner.?;
        var request = allocation;
        request.adapter_id = ctx.device.binding.adapter_id;
        request.memory_generation = ctx.device.memory_generation;
        request.deadline_ns = until;
        var status: a.GfxNativeStatus = .{};
        try result(ctx.buffers().nativeStart(&request, &status));
        self.pending = status.request;
        if (!valid(self.pending)) return error.Internal;
        try result(ctx.buffers().nativeWait(&self.pending, try ctx.ticks(until), &status));
        if (!payload(status) or !equal(status.request, self.pending) or status.phase != 2 or
            status.deadline_ns != until or status.reserved0 != 0 or status.flags != 0) return error.Internal;
        try result(status.result);
        try result(ctx.buffers().nativeReceive(&self.pending, &self.backing));
        self.pending = .{}; // Receive consumes the request.
    }
    fn describe(self: *Resource, device_local: bool) Error!void {
        const ctx = self.owner.?;
        if (!payload(self.backing) or !valid(self.backing.reference) or !valid(self.backing.buffer) or
            self.backing.flags != 0 or self.backing.reserved0 != 0) return error.Internal;
        try result(ctx.buffers().describe(&self.backing.reference, &self.descriptor));
        const d = self.descriptor;
        if (!payload(d) or d.reserved0 != 0 or d.byte_length == 0 or d.byte_length > self.charged or
            d.byte_length % granule != 0 or d.alignment < @as(u64, if (ctx.device.provider == .amd) 4096 else granule) or !std.math.isPowerOfTwo(d.alignment) or
            d.usage & 12 != 12) return error.Invalid;
        if (device_local) {
            if (d.location != a.gfx_buffer_location_device_local or d.adapter_id != ctx.device.binding.adapter_id or
                d.device_generation != ctx.device.memory_generation or d.driver_owner == 0 or d.usage & 3 != 0) return error.Stale;
        } else if (d.location != a.gfx_buffer_location_system or d.adapter_id != 0 or d.driver_owner != 0 or
            d.device_generation != 0 or d.usage & 3 != 3) return error.Invalid;
        const excess = self.charged - @as(usize, @intCast(d.byte_length));
        if (excess != 0) ctx.budget.release(excess);
        self.charged = @intCast(d.byte_length);
    }
    fn virtual(self: *Resource, request: a.GfxVirtualRequest, output: *a.GfxBufferHandle, expected: u64) Error!u64 {
        const ctx = self.owner.?;
        var status: a.GfxVirtualStatus = .{};
        try result(ctx.base.gfxVirtualStart(&request, &status));
        output.* = status.resource;
        if (!valid(output.*)) return error.Internal;
        try result(ctx.base.gfxVirtualWait(output, 0, try ctx.ticks(request.deadline_ns), &status));
        if (!payload(status) or !equal(status.resource, output.*) or !equal(status.parent, request.parent) or
            status.reserved0 != 0 or status.kind != request.kind or status.byte_length != request.byte_length or
            status.deadline_ns != request.deadline_ns or status.flags & 1 == 0 or status.flags & ~@as(u32, 15) != 0) return error.Internal;
        try result(status.result);
        if (status.flags != 1 or status.address % granule != 0 or status.address < ctx.device.va_start or
            !extent(status.address, status.byte_length, ctx.device.va_end) or
            (expected != 0 and expected != status.address)) return error.Unsupported;
        return status.address;
    }
    fn bind(self: *Resource, until: u64) Error!void {
        const ctx = self.owner.?;
        const d = self.descriptor;
        var request: a.GfxVirtualRequest = .{ .kind = 1, .adapter_id = ctx.device.binding.adapter_id,
            .memory_generation = ctx.device.memory_generation, .deadline_ns = until,
            .byte_length = d.byte_length, .alignment = granule,
            .location = @intFromBool(d.location == a.gfx_buffer_location_device_local),
            .flags = if (d.modifier != 0) a.gfx_virtual_flag_blocklinear | (6 << a.gfx_virtual_layout_shift) else 0 };
        // RM chooses the VA; reject an out-of-range result before encoding any
        // 40-bit method. Fixed addresses must never collide with another client.
        self.address = try self.virtual(request, &self.range, 0);
        request.kind = 2;
        request.flags = 0;
        request.alignment = 0;
        request.location = 0;
        request.parent = self.range;
        request.reference = self.backing.reference;
        _ = try self.virtual(request, &self.binding, self.address);
        self.ready = true;
    }
    pub fn mappedBytes(self: *Resource) Error![]u8 {
        if (!self.ready or self.owner == null or self.owner.?.poisoned or self.owner.?.fence.timeline != 0 or
            !valid(self.mapping.lease)) return error.Busy;
        return @as([*]u8, @ptrFromInt(self.mapping.cpu_address))[0..@intCast(self.mapping.byte_length)];
    }
    /// Explicit CPU ownership handoff for a driver-copied system IB. The BO
    /// and GPU address remain retained; only the CPU write lease is removed.
    pub fn suspendCpu(self: *Resource) Error!void {
        const ctx = self.owner orelse return error.Invalid;
        if (!self.ready or ctx.poisoned or ctx.fence.timeline != 0) return error.Busy;
        if (!valid(self.mapping.lease)) return;
        try result(ctx.buffers().unmap(&self.mapping.lease));
        self.mapping = .{};
    }
    pub fn resumeCpu(self: *Resource) Error!void {
        const ctx = self.owner orelse return error.Invalid;
        if (!self.ready or ctx.poisoned or ctx.fence.timeline != 0) return error.Busy;
        if (valid(self.mapping.lease)) return;
        const size = self.descriptor.byte_length;
        if (self.descriptor.location != a.gfx_buffer_location_system or self.descriptor.format != a.gfx_buffer_format_bytes) return error.Unsupported;
        errdefer self.ready = false; // A partial/invalid map is retained for close only.
        try result(ctx.buffers().mapPersistent(&self.backing.reference, a.gfx_buffer_map_write, 0, size, &self.mapping));
        if (!payload(self.mapping) or !valid(self.mapping.lease) or self.mapping.cpu_address == 0 or
            self.mapping.byte_length != size or self.mapping.cpu_address > std.math.maxInt(usize) - size or
            self.mapping.cache_policy != a.gfx_buffer_cache_write_back or self.mapping.reserved0 != 0) return error.Unsupported;
    }
    // Used only by the codec worker when replacing sequence scratch. All
    // resources share one deadline; the GUI-facing retirement path uses close.
    pub fn closeUntil(self: *Resource, until: u64) Error!void {
        self.close() catch |err| {
            if (err != error.Busy or !self.retiring or !valid(self.range)) return err;
            const ctx = self.owner.?;
            var status: a.GfxVirtualStatus = .{};
            try result(ctx.base.gfxVirtualWait(&self.range, 1, try ctx.ticks(until), &status));
            try self.close();
        };
    }
    pub fn close(self: *Resource) Error!void {
        const ctx = self.owner orelse return;
        self.ready = false;
        // Parent close retires every child and owns any late successful map.
        // Wait for the distinct retirement ACK, not the old creation result.
        if (valid(self.range)) {
            if (!self.retiring) {
                try result(ctx.base.gfxVirtualClose(&self.range, 0));
                self.retiring = true;
            }
            var status: a.GfxVirtualStatus = .{};
            try result(ctx.base.gfxVirtualQuery(&self.range, &status));
            if (!payload(status) or !equal(status.resource, self.range)) return error.Internal;
            if (status.flags & 6 != 6) return error.Busy;
            if (status.flags & ~@as(u32, 7) != 0) return error.Internal;
            try result(ctx.base.gfxVirtualClose(&self.range, 1));
            self.range = .{};
            self.binding = .{};
        }
        if (valid(self.mapping.lease)) {
            try result(ctx.buffers().unmap(&self.mapping.lease));
            self.mapping = .{};
        }
        if (valid(self.pending)) {
            // On timeout nativeClose transfers late allocation cleanup to the
            // resident broker. There is no caller pointer in that request.
            try result(ctx.buffers().nativeClose(&self.pending));
            self.pending = .{};
        }
        if (valid(self.backing.reference)) {
            if (!self.borrowed) try result(ctx.buffers().release(&self.backing.reference));
            self.backing = .{};
        }
        if (self.charged != 0) ctx.budget.release(self.charged);
        self.* = .{};
    }
};

/// Codec-worker-owned YUV images. Codec, DPB and presentation holds are
/// independent; neither a flush nor a cancelled fence releases consumer data.
/// The broker remains authoritative for the adapter's shared binding budget.
pub fn ImagePool(comptime capacity: usize) type {
    if (capacity == 0 or capacity > 24) @compileError("bounded media image pool");
    return struct {
        const Self = @This();
        pub const Token = struct { slot: u32, serial: u64 };
        pub const Hold = enum { codec, reference, consumer };
        const State = enum { empty, writing, complete, aborted };
        const Image = struct {
            resource: Resource = .{},
            serial: u64 = 0,
            epoch: u64 = 0,
            state: State = .empty,
            holds: [3]u32 = @splat(0),
        };
        images: [capacity]Image = @splat(.{}),
        serial: u64 = 0,
        closing: bool = false,

        fn get(self: *Self, token: Token) Error!*Image {
            if (token.slot >= capacity or token.serial == 0) return error.Stale;
            const image = &self.images[token.slot];
            if (image.serial != token.serial or image.state == .empty) return error.Stale;
            return image;
        }
        pub fn allocate(self: *Self, ctx: *Context, width: u32, height: u32, depth: u32, epoch: u64) Error!Token {
            if (self.closing or ctx.poisoned) return error.Stale;
            if (epoch == 0 or ctx.device.provider != .amd) return error.Invalid;
            try self.reap();
            const slot = for (&self.images, 0..) |*image, i| {
                if (image.state == .empty) break i;
            } else return error.Busy;
            const serial = std.math.add(u64, self.serial, 1) catch return error.NoMemory;
            const image = &self.images[slot];
            image.* = .{ .serial = serial, .epoch = epoch, .state = .writing, .holds = .{ 1, 0, 0 } };
            self.serial = serial;
            image.resource.yuv(ctx, width, height, depth) catch |err| {
                image.state = .aborted;
                image.holds = @splat(0);
                // Even a failed allocation owns its late request until reap.
                self.reap() catch {};
                return err;
            };
            return .{ .slot = @intCast(slot), .serial = serial };
        }
        pub fn resource(self: *Self, token: Token) Error!*const Resource {
            const image = try self.get(token);
            if (image.state != .writing and image.state != .complete) return error.Invalid;
            return &image.resource;
        }
        /// Call only with a freshly read codec feedback result. Fence success
        /// proves retirement, never that a bitstream produced a valid picture.
        pub fn finish(self: *Self, token: Token, codec_succeeded: bool) Error!void {
            const image = try self.get(token);
            if (image.state != .writing) return error.Invalid;
            const ctx = image.resource.owner orelse return error.Stale;
            if (ctx.fence.timeline != 0) return error.Busy;
            if (ctx.poisoned) return error.Stale;
            image.state = if (codec_succeeded) .complete else .aborted;
        }
        pub fn abort(self: *Self, token: Token) Error!void {
            const image = try self.get(token);
            if (image.state != .writing) return error.Invalid;
            image.state = .aborted;
        }
        pub fn retain(self: *Self, token: Token, hold: Hold) Error!void {
            const image = try self.get(token);
            if (image.state != .complete or self.closing) return error.Invalid;
            const count = &image.holds[@intFromEnum(hold)];
            count.* = std.math.add(u32, count.*, 1) catch return error.NoMemory;
        }
        pub fn release(self: *Self, token: Token, hold: Hold) Error!void {
            const image = try self.get(token);
            const count = &image.holds[@intFromEnum(hold)];
            if (count.* == 0) return error.Invalid;
            if (image.state == .writing) return error.Busy;
            count.* -= 1;
        }
        pub fn references(self: *Self, tokens: []const Token, epoch: u64, loans: []Context.Loan) Error![]Context.Loan {
            if (tokens.len > 17 or loans.len < tokens.len or epoch == 0) return error.Invalid;
            var checked: [17]Context.Loan = undefined;
            var ctx: ?*Context = null;
            for (tokens, 0..) |token, i| {
                const image = try self.get(token);
                if (image.state != .complete or image.epoch != epoch or image.holds[@intFromEnum(Hold.reference)] == 0 or
                    !image.resource.ready) return error.Stale;
                if (ctx) |owner| { if (image.resource.owner != owner) return error.Invalid; }
                ctx = image.resource.owner;
                for (tokens[0..i]) |earlier| if (equal(earlier, token)) return error.Invalid;
                checked[i] = .{ .resource = &image.resource, .write = false };
            }
            @memcpy(loans[0..tokens.len], checked[0..tokens.len]);
            return loans[0..tokens.len];
        }
        pub fn published(self: *Self, token: Token) Error!*const Resource {
            const image = try self.get(token);
            if (image.state != .complete or image.holds[@intFromEnum(Hold.consumer)] == 0 or !image.resource.ready) return error.Invalid;
            return &image.resource;
        }
        pub fn reap(self: *Self) Error!void {
            for (&self.images) |*image| {
                if (image.state == .empty or image.holds[0] != 0 or image.holds[1] != 0 or image.holds[2] != 0) continue;
                image.resource.close() catch |err| { if (err == error.Busy) continue; return err; };
                image.* = .{};
            }
        }
        pub fn close(self: *Self) Error!void {
            self.closing = true;
            try self.reap();
            for (&self.images) |*image| if (image.state != .empty) return error.Busy;
        }
    };
}
