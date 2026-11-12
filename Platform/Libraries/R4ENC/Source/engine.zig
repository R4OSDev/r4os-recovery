// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const c = @import("r4l_contract");
const native = @import("r4native");
const runtime = @import("runtime");
const sync = native.threading;
const input = @import("encode_input");
const Flow = @import("flow.zig").Flow(c);
const Input = input.Input(c);
const limit = @import("flow.zig").limit;
const packet_limit = 8 * 1024 * 1024;
const poll_ns = 5_000_000;

pub fn Implementation(comptime codec: type) type {
    const gpu_backend = @import("native_encoder").Implementation(codec);
    return struct {
        const Life = enum { empty, creating, live, destroying };
        const Slot = struct {
            life: Life = .empty,
            generation: u64 = 0,
            owner: runtime.Owner = .{ .memory = .{ .limit = 0 }, .workers = .{ .limit = 0 }, .process_generation = 0 },
            body: ?*Encoder = null,
            output_address: u64 = 0,
            output_bytes: u64 = 0,
            scratch_address: u64 = 0,
            scratch_bytes: u64 = 0,
        };
        const Process = struct {
            mutex: sync.Mutex = .{},
            phase: enum { unopened, ready, closing, closed } = .unopened,
            generation: u64 = 0,
            serial: u64 = 0,
            max_encoders: u32 = 0,
            memory: runtime.Budget = .{ .limit = 0 },
            workers: runtime.Budget = .{ .limit = 0 },
            slots: [limit]Slot = @splat(.{}),
        };
        const Encoder = struct {
            process: *Process,
            slot: *Slot,
            config: c.R4EncConfig,
            flow: Flow,
            mutex: sync.Mutex = .{},
            event: u64 = 0,
            worker: runtime.Worker = undefined,
            inputs: [limit]Input = @splat(.{}),
            packets: [limit]c.R4EncPacket = @splat(std.mem.zeroes(c.R4EncPacket)),
            output: ?[*]u8 = null,
            scratch: ?[*]u8 = null,
            codec: ?*codec.struct_r4enc_codec = null,
            native_backend: ?gpu_backend.Backend = null,
            active_result: ?i32 = null,
            active_bytes: u64 = 0,
            active_flags: u32 = 0,
            active_deadline: u64 = 0,
        };
        var key: u8 = 0;
        fn initialize(value: *Process) void {
            value.* = .{};
        }
        fn host() sync.Host {
            return sync.Host.bound().?;
        }
        fn lock(mutex: *sync.Mutex) void {
            if (mutex.lock(&host(), sync.forever) != sync.success) runtime.fatal("R4ENC: owner lock failed\n");
        }
        fn unlock(mutex: *sync.Mutex) void {
            if (mutex.unlock(&host()) != sync.success) runtime.fatal("R4ENC: owner unlock failed\n");
        }
        fn wake(event: u64) void {
            if (host().notify(event, 1) != a.notification_ok) runtime.fatal("R4ENC: notification failed\n");
        }
        fn now() u64 {
            return (native.time.read() orelse runtime.fatal("R4ENC: clock unavailable\n")).instant_ns;
        }
        fn process() ?*Process {
            if (!runtime.applicationBound()) return null;
            return native.process_local.lookup(Process, &key) catch null;
        }
        fn buffers() r.gfx_buffers.Context {
            return .{ .base = native.application.snapshot().?.base() };
        }
        fn queues() r.gfx_queue.Context {
            return .{ .base = buffers().base };
        }
        fn payload(value: anytype) bool {
            return value.version == 1 and value.size == @sizeOf(@TypeOf(value));
        }
        fn valid(comptime T: type, pointer: *const T) bool {
            const address = @intFromPtr(pointer);
            return address != 0 and address % @alignOf(T) == 0 and address <= std.math.maxInt(usize) - @sizeOf(T);
        }
        fn overlap(address: u64, bytes: u64, other: u64, count: u64) bool {
            return address < other +| count and other < address +| bytes;
        }
        // Registry-owned numeric ranges remain stable through a worker's
        // mutations and even while Destroy retires its allocations.
        fn safeOutput(p: *Process, output: anytype) bool {
            const T = @typeInfo(@TypeOf(output)).pointer.child;
            if (!valid(T, output)) return false;
            const address = @intFromPtr(output);
            if (overlap(address, @sizeOf(T), @intFromPtr(p), @sizeOf(Process))) return false;
            for (&p.slots) |*slot| if (slot.body) |body| {
                if (overlap(address, @sizeOf(T), @intFromPtr(body), @sizeOf(Encoder)) or
                    overlap(address, @sizeOf(T), slot.output_address, slot.output_bytes) or
                    overlap(address, @sizeOf(T), slot.scratch_address, slot.scratch_bytes)) return false;
            };
            return true;
        }
        fn runtimeMatches(p: *Process, handle: c.R4EncRuntime) bool {
            return handle.address == @intFromPtr(p) and handle.generation != 0 and handle.generation == p.generation;
        }
        fn encoderHandle(d: *Encoder) c.R4EncEncoder {
            return .{ .address = @intFromPtr(d), .generation = d.slot.generation };
        }
        fn find(p: *Process, handle: c.R4EncEncoder) ?*Slot {
            for (&p.slots) |*slot| if (slot.life == .live and slot.generation == handle.generation and handle.generation != 0) {
                if (slot.body) |body| if (@intFromPtr(body) == handle.address) return slot;
            };
            return null;
        }
        const Guard = struct {
            d: *Encoder,
            fn leave(self: Guard) void {
                unlock(&self.d.mutex);
            }
        };
        fn acquire(handle: *const c.R4EncEncoder, output: anytype) error{ Invalid, Stale, Busy }!Guard {
            if (!valid(c.R4EncEncoder, handle)) return error.Invalid;
            const p = process() orelse return error.Stale;
            if (p.mutex.tryLock(&host()) != sync.success) return error.Busy;
            defer unlock(&p.mutex);
            const slot = find(p, handle.*) orelse return error.Stale;
            if (@TypeOf(output) != @TypeOf(null)) if (!safeOutput(p, output)) return error.Invalid;
            const d = slot.body.?;
            if (d.mutex.tryLock(&host()) != sync.success) return error.Busy;
            return .{ .d = d };
        }
        fn code(err: anyerror) i32 {
            return switch (err) {
                error.Invalid, error.Overflow, error.Bounds => c.error_invalid,
                error.Unsupported => c.error_unsupported,
                error.NoMemory => c.error_no_memory,
                error.Busy => c.error_busy,
                error.Stale => c.error_stale,
                error.Closed => c.error_closed,
                error.Cancelled => c.error_cancelled,
                error.Failed, error.Timeout, error.Encode, error.MissingStatus, error.Bitstream, error.Capacity => c.error_encode,
                else => c.error_internal,
            };
        }
        fn caps(query: c.R4EncCapsQuery, output: *c.R4EncCaps) i32 {
            if (!payload(query)) return c.error_invalid;
            if (query.backend == c.backend_amd) {
                if (!runtime.applicationBound()) return c.error_unsupported;
                const device = @import("gpu_resources").Device.queryProvider(buffers().base, query.adapter_id, .encode, .amd) catch |err| return code(err);
                var actual = query;
                if (actual.profile == c.profile_default) actual.profile = if (query.codec == c.codec_h264) c.profile_h264_baseline else c.profile_hevc_main;
                const limits = device.mediaCaps(actual.codec, actual.profile, actual.bit_depth, actual.chroma) catch |err| return code(err);
                output.* = .{ .version = 1, .size = @sizeOf(c.R4EncCaps), .query = actual, .min_width = limits.min_width, .min_height = limits.min_height, .max_width = limits.max_width, .max_height = limits.max_height, .max_level = if (actual.codec == c.codec_h264) 52 else 186, .input_formats = c.formats_nv12, .rate_modes = c.rates_cqp | c.rates_cbr | c.rates_vbr, .max_pending_frames = limit, .max_packet_leases = limit, .flags = 0, .max_packet_bytes = packet_limit, .device_generation = device.binding.device_generation, .reset_generation = device.binding.reset_generation };
                return c.ok;
            }
            if (query.codec != c.codec_h264 or
                (query.profile != c.profile_default and query.profile != c.profile_h264_baseline) or
                query.bit_depth != 8 or query.chroma != c.chroma_420) return c.error_unsupported;
            var device_generation: u64 = 0;
            var reset_generation: u64 = 0;
            if (query.backend == c.backend_software) {
                if (query.adapter_id != 0) return c.error_unsupported;
            } else if (query.backend == c.backend_nvidia) {
                if (query.adapter_id == 0 or !runtime.applicationBound()) return c.error_unsupported;
                const devices = gpu_backend.Devices.query(buffers().base, query.adapter_id, query.backend) catch |err| return code(err);
                device_generation = devices.nvidia.encode.binding.device_generation;
                reset_generation = devices.nvidia.encode.binding.reset_generation;
            } else return c.error_unsupported;
            var actual = query;
            actual.profile = c.profile_h264_baseline;
            output.* = .{ .version = 1, .size = @sizeOf(c.R4EncCaps), .query = actual, .min_width = 16, .min_height = 16, .max_width = 4096, .max_height = 4096, .max_level = 51, .input_formats = c.formats_nv12 | c.formats_yuv420p, .rate_modes = c.rates_cqp, .max_pending_frames = limit, .max_packet_leases = limit, .flags = 0, .max_packet_bytes = packet_limit, .device_generation = device_generation, .reset_generation = reset_generation };
            return c.ok;
        }
        pub fn open(input_config: *const c.R4EncStartup, output: *c.R4EncRuntime) i32 {
            if (!valid(c.R4EncStartup, input_config) or !valid(c.R4EncRuntime, output)) return c.error_invalid;
            const config = input_config.*;
            if (!payload(config) or config.memory_limit == 0 or config.memory_limit > std.math.maxInt(usize) or
                config.max_encoders == 0 or config.max_encoders > limit or config.thread_limit > limit) return c.error_invalid;
            const caller = native.caller.Input.init(config.application) catch return c.error_invalid;
            const base = caller.base();
            inline for (.{ "gfx_buffer_import", "gfx_buffer_describe", "gfx_buffer_release", "gfx_buffer_map", "gfx_buffer_unmap", "gfx_fence_query" }) |field|
                if (!base.hasDrawFn(field)) return c.error_unsupported;
            if (!runtime.bindAddress(config.application)) return c.error_unsupported;
            const p = native.process_local.getOrCreate(Process, &key, initialize) orelse return c.error_no_memory;
            lock(&p.mutex);
            defer unlock(&p.mutex);
            if (!safeOutput(p, output)) return c.error_invalid;
            if (p.phase != .unopened) return if (p.phase == .ready) c.error_busy else c.error_closed;
            const identity = native.threads.thrd_current();
            if (identity.instance_generation == 0) return c.error_internal;
            const capacity = native.process.cpuCapacity() orelse return c.error_internal;
            p.memory = .{ .limit = @intCast(config.memory_limit) };
            p.workers = .{ .limit = if (config.thread_limit == 0) @min(capacity.available_cpus, limit) else config.thread_limit };
            p.generation = identity.instance_generation;
            p.max_encoders = config.max_encoders;
            p.phase = .ready;
            output.* = .{ .address = @intFromPtr(p), .generation = p.generation };
            return c.ok;
        }
        pub fn queryCaps(handle: *const c.R4EncRuntime, query: *const c.R4EncCapsQuery, output: *c.R4EncCaps) i32 {
            if (!valid(c.R4EncRuntime, handle) or !valid(c.R4EncCapsQuery, query)) return c.error_invalid;
            const p = process() orelse return c.error_stale;
            lock(&p.mutex);
            defer unlock(&p.mutex);
            if (!runtimeMatches(p, handle.*)) return c.error_stale;
            if (p.phase != .ready) return c.error_closed;
            if (!safeOutput(p, output)) return c.error_invalid;
            return caps(query.*, output);
        }
        pub fn create(handle: *const c.R4EncRuntime, input_config: *const c.R4EncConfig, output: *c.R4EncEncoder) i32 {
            if (!valid(c.R4EncRuntime, handle) or !valid(c.R4EncConfig, input_config)) return c.error_invalid;
            var config = input_config.*;
            if (!payload(config) or !payload(config.rate) or !payload(config.color) or config.flags & ~c.config_allow_skip != 0 or
                config.memory_limit == 0 or config.memory_limit > std.math.maxInt(usize) or config.width < 16 or config.height < 16 or
                config.width > 4096 or config.height > 4096 or (config.width | config.height) & 1 != 0 or
                config.max_packet_bytes == 0 or config.max_packet_bytes > packet_limit or config.work_timeout_ns == 0 or
                config.work_timeout_ns == std.math.maxInt(u64)) return c.error_invalid;
            const flow = Flow.init(config.pending_frames, config.packet_leases) catch |err| return code(err);
            var supported: c.R4EncCaps = undefined;
            const supported_rc = caps(config.query, &supported);
            if (supported_rc != c.ok) return supported_rc;
            config.query = supported.query;
            const native_config: ?gpu_backend.Config = if (config.query.backend != c.backend_software)
                gpu_backend.Config.from(config) catch |err| return code(err)
            else
                null;
            const devices: ?gpu_backend.Devices = if (native_config != null)
                gpu_backend.Devices.query(buffers().base, config.query.adapter_id, config.query.backend) catch |err| return code(err)
            else
                null;
            const p = process() orelse return c.error_stale;
            lock(&p.mutex);
            if (!runtimeMatches(p, handle.*)) {
                unlock(&p.mutex);
                return c.error_stale;
            }
            if (p.phase != .ready) {
                unlock(&p.mutex);
                return c.error_closed;
            }
            if (!safeOutput(p, output)) {
                unlock(&p.mutex);
                return c.error_invalid;
            }
            if (config.memory_limit > p.memory.limit) {
                unlock(&p.mutex);
                return c.error_no_memory;
            }
            var candidate: ?*Slot = null;
            for (p.slots[0..p.max_encoders]) |*slot| if (slot.life == .empty) {
                candidate = slot;
                break;
            };
            const slot = candidate orelse {
                unlock(&p.mutex);
                return c.error_busy;
            };
            if (p.serial == std.math.maxInt(u64)) {
                unlock(&p.mutex);
                return c.error_internal;
            }
            p.serial += 1;
            slot.* = .{ .life = .creating, .generation = p.serial, .owner = .{ .memory = .{ .limit = @intCast(config.memory_limit), .parent = &p.memory }, .workers = .{ .limit = 1, .parent = &p.workers }, .process_generation = p.generation } };
            unlock(&p.mutex);
            var committed = false;
            defer if (!committed) {
                lock(&p.mutex);
                slot.* = .{};
                unlock(&p.mutex);
            };
            const scope = runtime.enter(&slot.owner) orelse return c.error_no_memory;
            defer {
                scope.leave();
                if (!runtime.releaseCaller()) runtime.fatal("R4ENC: caller TLS retirement failed\n");
            }
            const d: *Encoder = @ptrCast(@alignCast(runtime.memory.malloc(@sizeOf(Encoder)) orelse return c.error_no_memory));
            d.* = .{ .process = p, .slot = slot, .config = config, .flow = flow };
            if (native_config) |settings| d.native_backend = gpu_backend.Backend.init(buffers().base, devices.?, &slot.owner.memory, native.time.read, settings);
            lock(&p.mutex);
            slot.body = d;
            unlock(&p.mutex);
            defer if (!committed) {
                codec.r4enc_codec_close(&d.codec);
                if (d.event != 0 and host().close(d.event) != a.notification_ok) runtime.fatal("R4ENC: failed admission event cleanup\n");
                runtime.memory.free(d.output);
                runtime.memory.free(d.scratch);
                runtime.memory.free(d);
            };
            const output_bytes: usize = @intCast(config.max_packet_bytes * config.packet_leases);
            const scratch_bytes: usize = if (native_config == null) @as(usize, config.width) * config.height * 3 / 2 else 0;
            d.output = @ptrCast(runtime.memory.malloc(output_bytes) orelse return c.error_no_memory);
            if (scratch_bytes != 0) d.scratch = @ptrCast(runtime.memory.malloc(scratch_bytes) orelse return c.error_no_memory);
            lock(&p.mutex);
            slot.output_address = @intFromPtr(d.output.?);
            slot.output_bytes = output_bytes;
            slot.scratch_address = if (d.scratch) |pointer| @intFromPtr(pointer) else 0;
            slot.scratch_bytes = scratch_bytes;
            unlock(&p.mutex);
            if (host().create(&d.event) != a.notification_ok) return c.error_no_memory;
            if (native_config == null) {
                const rc = codec.r4enc_codec_open(@ptrCast(&config), &d.codec);
                if (rc != c.ok) return rc;
            }
            d.worker = .{ .owner = &slot.owner, .entry = worker, .argument = d };
            if (!d.worker.start()) return c.error_no_memory;
            lock(&p.mutex);
            slot.life = .live;
            output.* = encoderHandle(d);
            unlock(&p.mutex);
            committed = true;
            return c.ok;
        }
        pub fn send(handle: *const c.R4EncEncoder, frame: *const c.R4EncFrame) i32 {
            if (!valid(c.R4EncFrame, frame)) return c.error_invalid;
            const value = frame.*;
            const guard = acquire(handle, null) catch |err| return code(err);
            const d = guard.d;
            const slot = d.flow.reserve(value.stream_generation) catch |err| {
                guard.leave();
                return if (err == error.Busy) c.again else code(err);
            };
            d.inputs[slot].admit(&buffers(), &d.slot.owner.memory, value, d.config.width, d.config.height) catch |err| {
                d.flow.reject(slot);
                if (d.inputs[slot].empty()) d.flow.discard(slot);
                const event = d.event;
                guard.leave();
                wake(event);
                return code(err);
            };
            d.flow.commit(slot);
            const event = d.event;
            guard.leave();
            wake(event);
            return c.ok;
        }
        pub fn receive(handle: *const c.R4EncEncoder, output: *c.R4EncPacket) i32 {
            const guard = acquire(handle, output) catch |err| return code(err);
            defer guard.leave();
            const d = guard.d;
            const i = (d.flow.receive() catch |err| return code(err)) orelse {
                if (d.flow.phase == c.phase_drained or d.flow.phase == c.phase_closed) return c.eos;
                if (d.flow.phase == c.phase_failed and d.flow.inputsEmpty()) return d.flow.last_error;
                return c.again;
            };
            var value = d.packets[i];
            value.lease = .{ .encoder = encoderHandle(d), .token = d.flow.outputs[i].token, .stream_generation = d.flow.outputs[i].generation };
            output.* = value;
            return c.ok;
        }
        pub fn release(lease: *const c.R4EncLease) i32 {
            if (!valid(c.R4EncLease, lease)) return c.error_invalid;
            const value = lease.*;
            const guard = acquire(&value.encoder, null) catch |err| return code(err);
            const d = guard.d;
            d.flow.release(value.token, value.stream_generation) catch |err| {
                guard.leave();
                return code(err);
            };
            const event = d.event;
            guard.leave();
            wake(event);
            return c.ok;
        }
        fn snapshot(d: *Encoder) c.R4EncState {
            var queued: u32 = 0;
            var ready: u32 = 0;
            for (d.flow.inputs[0..d.flow.input_limit]) |item| if (item.state == .queued or item.state == .active) {
                queued += 1;
            };
            for (d.flow.outputs[0..d.flow.output_limit]) |item| if (item.state == .ready) {
                ready += 1;
            };
            return .{ .version = 1, .size = @sizeOf(c.R4EncState), .stream_generation = d.flow.generation, .pending_request = d.flow.pending, .completed_request = d.flow.completed, .memory_bytes = d.slot.owner.memory.liveBytes(), .accepted_frames = d.flow.accepted, .encoded_frames = d.flow.encoded, .skipped_frames = d.flow.skipped, .output_bytes = d.flow.bytes, .phase = d.flow.phase, .queued_frames = queued, .ready_packets = ready, .leased_packets = d.flow.leased(), .last_error = d.flow.last_error, .reserved = 0 };
        }
        pub fn control(handle: *const c.R4EncEncoder, request: *const c.R4EncControl, output: *c.R4EncState) i32 {
            if (!valid(c.R4EncControl, request)) return c.error_invalid;
            const value = request.*;
            if (!payload(value) or value.reserved != 0 or value.operation > c.control_close or
                (value.operation == c.control_query and value.request_id != 0)) return c.error_invalid;
            const guard = acquire(handle, output) catch |err| return code(err);
            const d = guard.d;
            if (value.operation != c.control_query) d.flow.request(value.request_id, value.operation) catch |err| {
                guard.leave();
                return code(err);
            };
            output.* = snapshot(d);
            const event = d.event;
            guard.leave();
            if (value.operation != c.control_query) wake(event);
            return c.ok;
        }
        pub fn destroy(handle: *const c.R4EncEncoder) i32 {
            if (!valid(c.R4EncEncoder, handle)) return c.error_invalid;
            const p = process() orelse return c.error_stale;
            if (p.mutex.tryLock(&host()) != sync.success) return c.error_busy;
            const slot = find(p, handle.*) orelse {
                unlock(&p.mutex);
                return c.error_stale;
            };
            const d = slot.body.?;
            if (d.mutex.tryLock(&host()) != sync.success) {
                unlock(&p.mutex);
                return c.error_busy;
            }
            if (d.flow.phase != c.phase_closed) {
                unlock(&d.mutex);
                unlock(&p.mutex);
                return c.error_busy;
            }
            slot.life = .destroying;
            unlock(&d.mutex);
            unlock(&p.mutex);
            var done = false;
            defer if (!done) {
                lock(&p.mutex);
                slot.life = .live;
                unlock(&p.mutex);
            };
            if (d.worker.charged) d.worker.tryJoin() catch |err| return code(err);
            if (d.event != 0) {
                if (host().close(d.event) != a.notification_ok) return c.error_internal;
                d.event = 0;
            }
            if (d.mutex.destroy(&host()) != sync.success) return c.error_busy;
            runtime.memory.free(d.output);
            runtime.memory.free(d.scratch);
            runtime.memory.free(d);
            if (slot.owner.memory.liveBytes() != 0 or slot.owner.workers.liveBytes() != 0) runtime.fatal("R4ENC: owner resources remain after join\n");
            lock(&p.mutex);
            slot.* = .{};
            unlock(&p.mutex);
            done = true;
            return c.ok;
        }
        pub fn finish(handle: *const c.R4EncRuntime, timeout_ns: u64) i32 {
            if (!valid(c.R4EncRuntime, handle) or timeout_ns == std.math.maxInt(u64)) return c.error_invalid;
            const p = process() orelse return c.error_stale;
            const until = now() +| timeout_ns;
            while (true) {
                lock(&p.mutex);
                if (!runtimeMatches(p, handle.*)) {
                    unlock(&p.mutex);
                    return c.error_stale;
                }
                if (p.phase == .closed) {
                    unlock(&p.mutex);
                    return c.ok;
                }
                var live = false;
                for (&p.slots) |*slot| if (slot.life != .empty) {
                    live = true;
                    break;
                };
                if (!live) p.phase = .closing;
                unlock(&p.mutex);
                if (!live and runtime.finishNative()) {
                    if (p.memory.liveBytes() != 0 or p.workers.liveBytes() != 0) return c.error_internal;
                    lock(&p.mutex);
                    p.phase = .closed;
                    unlock(&p.mutex);
                    return c.ok;
                }
                const current = now();
                if (current >= until) return c.error_busy;
                const sequence = current +| @min(poll_ns, until - current);
                native.time.os_time_nanosleep_until(@intCast(@min(sequence, std.math.maxInt(i64))));
            }
        }
        const Action = enum { progress, poll, idle, stop };
        fn worker(argument: ?*anyopaque, _: bool) callconv(.c) c_int {
            const d: *Encoder = @ptrCast(@alignCast(argument.?));
            while (true) {
                var sequence: u64 = 0;
                if (host().query(d.event, &sequence) != a.notification_ok) runtime.fatal("R4ENC: event query failed\n");
                switch (step(d)) {
                    .stop => return 0,
                    .progress => continue,
                    .poll => _ = host().waitUntil(d.event, sequence, now() +| poll_ns),
                    .idle => _ = host().waitUntil(d.event, sequence, sync.forever),
                }
            }
        }
        fn step(d: *Encoder) Action {
            lock(&d.mutex);
            if (d.flow.phase == c.phase_closed) {
                unlock(&d.mutex);
                return .stop;
            }
            const cancelling = d.flow.phase == c.phase_aborting or d.flow.phase == c.phase_closing;
            for (d.flow.inputs[0..d.flow.input_limit], 0..) |*item, i| {
                if (item.state != .retiring and !(cancelling and item.state == .queued)) continue;
                item.state = .retiring;
                unlock(&d.mutex);
                d.inputs[i].close(&buffers()) catch |err| {
                    if (err != error.Busy) {
                        lock(&d.mutex);
                        d.flow.last_error = code(err);
                        unlock(&d.mutex);
                    }
                    return .poll;
                };
                lock(&d.mutex);
                d.flow.discard(i);
                unlock(&d.mutex);
                return .progress;
            }
            if (d.flow.active == null) if (d.flow.take()) |_| {
                d.active_result = null;
                d.active_bytes = 0;
                d.active_flags = 0;
                d.active_deadline = now() +| d.config.work_timeout_ns;
            };
            if (d.flow.active) |claim| {
                const frame = d.inputs[claim.input].frame;
                if (d.active_result == null and cancelling) d.active_result = c.error_cancelled;
                if (d.active_result == null and d.flow.phase == c.phase_failed) d.active_result = d.flow.last_error;
                unlock(&d.mutex);
                if (d.active_result == null) {
                    if (now() >= d.active_deadline) d.active_result = c.error_encode else if (d.native_backend) |*backend| {
                        const data = d.output.? + claim.output * @as(usize, @intCast(d.config.max_packet_bytes));
                        if (backend.encode(&d.inputs[claim.input], claim.force_idr or frame.flags & c.frame_force_idr != 0, data[0..@intCast(d.config.max_packet_bytes)], d.active_deadline)) |packet| {
                            d.active_bytes = packet.bytes;
                            d.active_flags = if (packet.key) c.packet_key | c.packet_config else 0;
                            d.active_result = if (now() >= d.active_deadline) c.error_encode else c.ok;
                        } else |err| {
                            if (err == error.Busy and !backend.failed) return .poll;
                            d.active_result = code(err);
                        }
                    } else if (d.inputs[claim.input].mapCpu(&buffers(), &queues())) |view| {
                        var planes: [3][*c]const u8 = undefined;
                        var pitches = view.pitches;
                        if (view.interleaved) {
                            const y_bytes: usize = @as(usize, view.width) * view.height;
                            const uv_bytes = y_bytes / 4;
                            const scratch = d.scratch.?;
                            view.copyPlanar(.{ scratch[0..y_bytes], scratch[y_bytes..][0..uv_bytes], scratch[y_bytes + uv_bytes ..][0..uv_bytes] }) catch unreachable;
                            planes = .{ scratch, scratch + y_bytes, scratch + y_bytes + uv_bytes };
                            pitches = .{ view.width, view.width / 2, view.width / 2 };
                        } else {
                            for (0..3) |i| planes[i] = view.planes[i].?;
                        }
                        const data = d.output.? + claim.output * @as(usize, @intCast(d.config.max_packet_bytes));
                        d.active_result = codec.r4enc_codec_encode(d.codec, &planes, &pitches, frame.pts_ns, @intFromBool(claim.force_idr or frame.flags & c.frame_force_idr != 0), data, d.config.max_packet_bytes, &d.active_bytes, &d.active_flags);
                        if (now() >= d.active_deadline) d.active_result = c.error_encode;
                    } else |err| {
                        if (err == error.Busy) return .poll;
                        d.active_result = code(err);
                    }
                }
                if (d.native_backend) |*backend| backend.retireInput() catch |err| {
                    if (err != error.Busy) {
                        lock(&d.mutex);
                        d.flow.last_error = code(err);
                        unlock(&d.mutex);
                    }
                    return .poll;
                };
                d.inputs[claim.input].close(&buffers()) catch |err| {
                    if (err != error.Busy) {
                        lock(&d.mutex);
                        d.flow.last_error = code(err);
                        unlock(&d.mutex);
                    }
                    return .poll;
                };
                const result = d.active_result.?;
                const bytes = if (result == c.ok) d.active_bytes else 0;
                const flags = if (result == c.ok) d.active_flags else 0;
                lock(&d.mutex);
                d.packets[claim.output] = .{ .version = 1, .size = @sizeOf(c.R4EncPacket), .lease = std.mem.zeroes(c.R4EncLease), .tag = frame.tag, .pts_ns = frame.pts_ns, .dts_ns = frame.pts_ns, .duration_ns = frame.duration_ns, .data_address = if (bytes != 0) @intFromPtr(d.output.?) + claim.output * d.config.max_packet_bytes else 0, .data_bytes = bytes, .flags = flags, .result = result };
                d.flow.finish(claim, bytes, flags, result);
                unlock(&d.mutex);
                return .progress;
            }
            if (d.flow.phase == c.phase_closing and d.flow.inputsEmpty() and d.codec != null) {
                unlock(&d.mutex);
                codec.r4enc_codec_close(&d.codec);
                return .progress;
            }
            if (d.native_backend) |*backend| {
                if (d.flow.phase == c.phase_closing and d.flow.inputsEmpty() and !backend.closed) {
                    unlock(&d.mutex);
                    backend.close() catch |err| {
                        if (err != error.Busy) {
                            lock(&d.mutex);
                            d.flow.last_error = code(err);
                            unlock(&d.mutex);
                        }
                        return .poll;
                    };
                    return .progress;
                }
                if (d.flow.phase == c.phase_aborting and d.flow.inputsEmpty()) {
                    unlock(&d.mutex);
                    const result = backend.reset();
                    lock(&d.mutex);
                    result catch |err| {
                        // Close may have superseded Abort while the lock was
                        // released. Preserve that requested retirement path.
                        if (d.flow.phase != c.phase_closing) d.flow.phase = c.phase_failed;
                        d.flow.last_error = code(err);
                    };
                }
            }
            d.flow.progress(true, if (d.native_backend) |*backend| backend.closed else d.codec == null);
            const stopped = d.flow.phase == c.phase_closed;
            unlock(&d.mutex);
            return if (stopped) .stop else .idle;
        }
    };
}
