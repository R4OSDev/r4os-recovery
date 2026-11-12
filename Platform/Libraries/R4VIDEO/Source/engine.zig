// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const c = @import("r4l_contract");
const native = @import("r4native");
const runtime = @import("runtime");
const sync = native.threading;
const Surface = @import("surface.zig").Surface;
const gpu = @import("gpu_resources");
const max_decoders = 16;
const max_packets = 16;
const max_frames = 16;
const max_packet_bytes = 8 * 1024 * 1024;
const max_threads = 16;
const poll_ns = 5_000_000;

// C declarations are translated in the owning root module, with its manifest
// include paths. The native implementation and this worker share codec.h.
pub fn Implementation(comptime ff: type) type {
    return struct {
        const Self = @This();
        const GpuDecoder = @import("hardware_decoder.zig").Implementation(ff);
        const Life = enum { empty, creating, active, reaping, closed, destroying };
        const RuntimePhase = enum { unopened, opening, ready, closing, closed };
        const PacketState = enum { free, queued, working };
        const FrameState = enum { empty, building, ready, leased, returning, retiring, ack_ready, acknowledged, discard };
        const Packet = struct { state: PacketState = .free, value: c.R4VideoPacket = std.mem.zeroes(c.R4VideoPacket) };
        const Image = struct {
            state: FrameState = .empty,
            surface: Surface = .{},
            native_frame: ff.struct_r4video_codec_frame = std.mem.zeroes(ff.struct_r4video_codec_frame),
            frame: c.R4VideoFrame = std.mem.zeroes(c.R4VideoFrame),
            receipt: c.R4VideoReceipt = std.mem.zeroes(c.R4VideoReceipt),
            fence_released: bool = false,
            // Retain an acknowledged consumer token while the worker prepares
            // its replacement. Public slot reuse occurs at the next Receive.
            acknowledged_lease: c.R4VideoLease = std.mem.zeroes(c.R4VideoLease),
            acknowledged_receipt: c.R4VideoReceipt = std.mem.zeroes(c.R4VideoReceipt),
        };
        const Slot = struct {
            life: Life = .empty,
            generation: u64 = 0,
            owner: runtime.Owner = .{ .memory = .{ .limit = 0 }, .workers = .{ .limit = 0 }, .process_generation = 0 },
            decoder: ?*Decoder = null,
            // Registry-owned numeric ranges, also retained during destruction.
            // Output validation never follows a worker's changing input pointer.
            input_address: u64 = 0,
            input_bytes: u64 = 0,
        };
        const Process = struct {
            mutex: sync.Mutex = .{},
            phase: RuntimePhase = .unopened,
            result: i32 = c.ok,
            generation: u64 = 0,
            serial: u64 = 0,
            limit: u32 = 0,
            memory: runtime.Budget = .{ .limit = 0 },
            workers: runtime.Budget = .{ .limit = 0 },
            // Exactly one retirement worker, separate from decoder concurrency.
            retirement: runtime.Owner = .{ .memory = .{ .limit = 0 }, .workers = .{ .limit = 1 }, .process_generation = 0 },
            thread: ff.pthread_t = std.mem.zeroes(ff.pthread_t),
            event: u64 = 0,
            stopping: std.atomic.Value(bool) = .init(false),
            slots: [max_decoders]Slot = @splat(.{}),
        };
        const Decoder = struct {
            mutex: sync.Mutex = .{},
            process: *Process,
            slot: *Slot,
            config: c.R4VideoConfig,
            event: u64 = 0,
            thread: ff.pthread_t = std.mem.zeroes(ff.pthread_t),
            exited: std.atomic.Value(bool) = .init(false),
            joined: bool = false,
            phase: u32 = c.phase_open,
            generation: u64 = 1,
            request: u64 = 0,
            completed: u64 = 0,
            completed_operation: u32 = c.control_query,
            seen_request: u64 = 0,
            return_cursor: usize = 0,
            operation: u32 = c.control_query,
            last_error: i32 = c.ok,
            token: u64 = 0,
            input: ?[*]u8 = null,
            packets: [max_packets]Packet = @splat(.{}),
            head: usize = 0,
            tail: usize = 0,
            queued: u32 = 0,
            images: [max_frames]Image = @splat(.{}),
            // Only coordinator touches native codec, active packet and receive
            // state. Public requests change phase under mutex; never the codec.
            codec: ?*ff.struct_r4video_codec = null,
            gpu_decoder: ?GpuDecoder = null,
            gpu_pending: bool = false,
            active_packet: ?usize = null,
            need_receive: bool = false,
            drain_sent: bool = false,
        };
        var key: u8 = 0;
        fn initialize(value: *Process) void {
            value.* = .{};
        }
        fn host() sync.Host {
            return sync.Host.bound().?;
        }
        fn lock(mutex: *sync.Mutex) void {
            if (mutex.lock(&host(), sync.forever) != sync.success) runtime.fatal("R4VIDEO: owner lock failed\n");
        }
        fn unlock(mutex: *sync.Mutex) void {
            if (mutex.unlock(&host()) != sync.success) runtime.fatal("R4VIDEO: owner unlock failed\n");
        }
        fn wake(event: u64) void {
            if (event != 0 and host().notify(event, 1) != a.notification_ok) runtime.fatal("R4VIDEO: notification failed\n");
        }
        fn now() u64 {
            return (native.time.read() orelse runtime.fatal("R4VIDEO: clock unavailable\n")).instant_ns;
        }
        fn process() ?*Process {
            if (!runtime.applicationBound()) return null;
            return native.process_local.lookup(Process, &key) catch null;
        }
        fn buffers() r.gfx_buffers.Context {
            return .{ .base = native.application.snapshot().?.base() };
        }
        fn queues() r.gfx_queue.Context {
            return .{ .base = native.application.snapshot().?.base() };
        }
        fn payload(value: anytype) bool {
            return value.version == 1 and value.size == @sizeOf(@TypeOf(value));
        }
        fn pointerValid(comptime T: type, pointer: *const T) bool {
            const address = @intFromPtr(pointer);
            return address != 0 and address % @alignOf(T) == 0 and address <= std.math.maxInt(u64) - @sizeOf(T);
        }
        fn overlap(address: u64, bytes: u64, other: u64, count: u64) bool {
            return address < other +| count and other < address +| bytes;
        }
        // Called with the process owner held. Public outputs may never overwrite
        // the registry or a live private decoder/input allocation.
        fn safeOutput(p: *Process, output: anytype) bool {
            const T = @typeInfo(@TypeOf(output)).pointer.child;
            if (!pointerValid(T, output) or overlap(@intFromPtr(output), @sizeOf(T), @intFromPtr(p), @sizeOf(Process))) return false;
            for (&p.slots) |*slot| if (slot.decoder) |d| {
                if (overlap(@intFromPtr(output), @sizeOf(T), @intFromPtr(d), @sizeOf(Decoder)) or
                    overlap(@intFromPtr(output), @sizeOf(T), slot.input_address, slot.input_bytes)) return false;
            };
            return true;
        }
        fn runtimeMatches(p: *const Process, handle: c.R4VideoRuntime) bool {
            return handle.address == @intFromPtr(p) and handle.generation != 0 and handle.generation == p.generation;
        }
        fn decoderHandle(d: *const Decoder) c.R4VideoDecoder {
            return .{ .address = @intFromPtr(d.slot), .generation = d.slot.generation };
        }
        fn find(p: *Process, handle: c.R4VideoDecoder) ?*Slot {
            for (&p.slots) |*slot| if (@intFromPtr(slot) == handle.address and slot.generation == handle.generation and handle.generation != 0 and
                slot.life != .empty and slot.life != .creating and slot.life != .destroying) return slot;
            return null;
        }
        const Guard = struct {
            d: *Decoder,
            fn leave(self: Guard) void {
                unlock(&self.d.mutex);
            }
        };
        const AcquireError = error{ Invalid, Stale, Busy };
        fn acquireCode(err: AcquireError) i32 {
            return switch (err) {
                error.Invalid => c.error_invalid,
                error.Stale => c.error_stale,
                error.Busy => c.error_busy,
            };
        }
        fn acquire(handle: *const c.R4VideoDecoder) AcquireError!Guard {
            return acquireOutput(handle, null);
        }
        fn acquireOutput(handle: *const c.R4VideoDecoder, output: anytype) AcquireError!Guard {
            if (!pointerValid(c.R4VideoDecoder, handle)) return error.Invalid;
            const p = process() orelse return error.Stale;
            if (p.mutex.tryLock(&host()) != sync.success) return error.Busy;
            defer unlock(&p.mutex);
            const slot = find(p, handle.*) orelse return error.Stale;
            const d = slot.decoder orelse return error.Stale;
            if (@TypeOf(output) != @TypeOf(null)) {
                if (!safeOutput(p, output)) return error.Invalid;
            }
            if (d.mutex.tryLock(&host()) != sync.success) return error.Busy;
            return .{ .d = d };
        }
        fn state(d: *const Decoder) c.R4VideoState {
            var ready: u32 = 0;
            var leased: u32 = 0;
            for (&d.images) |*image| switch (image.state) {
                .ready => ready += 1,
                .leased, .returning, .retiring, .ack_ready => leased += 1,
                else => {},
            };
            return .{ .version = 1, .size = @sizeOf(c.R4VideoState), .stream_generation = d.generation, .pending_request = d.request, .completed_request = d.completed, .memory_bytes = d.slot.owner.memory.liveBytes(), .phase = d.phase, .queued_packets = d.queued, .ready_frames = ready, .leased_frames = leased, .last_error = d.last_error, .reserved = 0 };
        }
        fn complete(d: *Decoder, phase: u32) void {
            d.phase = phase;
            if (d.request != 0) {
                d.completed = d.request;
                d.completed_operation = d.operation;
                d.request = 0;
            }
        }
        fn fail(d: *Decoder, result: i32) void {
            lock(&d.mutex);
            defer unlock(&d.mutex);
            d.last_error = if (result < 0) result else c.error_internal;
            if (d.phase != c.phase_closing) complete(d, c.phase_failed);
        }
        fn caps(input: c.R4VideoCapsQuery, output: *c.R4VideoCaps) i32 {
            var query = input;
            if (!payload(query)) return c.error_invalid;
            if (query.profile == c.profile_default) query.profile = switch (query.codec) {
                c.codec_h264 => c.profile_h264_baseline,
                c.codec_hevc => if (query.bit_depth == 10) 2 else 1,
                c.codec_vp9 => if (query.bit_depth == 10) 2 else 0,
                c.codec_mpeg2 => 4,
                c.codec_vc1 => 3,
                c.codec_jpeg => 0,
                else => return c.error_unsupported,
            };
            if (query.chroma != c.chroma_420) return c.error_unsupported;
            if (query.codec == c.codec_h264) {
                if (query.bit_depth != 8 or (query.profile != c.profile_h264_baseline and query.profile != c.profile_h264_main and query.profile != c.profile_h264_high)) return c.error_unsupported;
            } else {
                if (query.backend != c.backend_amd) return c.error_unsupported;
                const supported = switch (query.codec) {
                    c.codec_hevc => (query.profile == 1 and query.bit_depth == 8) or (query.profile == 2 and query.bit_depth == 10),
                    c.codec_vp9 => (query.profile == 0 and query.bit_depth == 8) or (query.profile == 2 and query.bit_depth == 10),
                    c.codec_mpeg2 => (query.profile == 4 or query.profile == 5) and query.bit_depth == 8,
                    c.codec_vc1 => query.profile == 3 and query.bit_depth == 8,
                    c.codec_jpeg => query.profile == 0 and query.bit_depth == 8,
                    else => false,
                };
                if (!supported) return c.error_unsupported;
            }
            var device: ?gpu.Device = null;
            if (query.backend == c.backend_nvidia or query.backend == c.backend_amd) {
                device = gpuDevice(query.adapter_id, if (query.backend == c.backend_amd) .amd else .nvidia, query.codec) catch |err| return gpuCode(err);
                if (query.backend == c.backend_amd) _ = device.?.mediaCaps(query.codec, query.profile, query.bit_depth, query.chroma) catch |err| return gpuCode(err);
            } else if (query.backend != c.backend_software or query.adapter_id != 0) return c.error_unsupported;
            output.* = .{ .version = 1, .size = @sizeOf(c.R4VideoCaps), .query = query, .min_width = 16, .min_height = 16, .max_width = 4096, .max_height = 4096, .max_level = 51, .output_formats = c.formats_yuv420p, .max_packet_bytes = max_packet_bytes, .max_pending_packets = max_packets, .max_frame_leases = max_frames, .device_generation = 0, .reset_generation = 0, .flags = 0, .reserved = 0 };
            if (device) |value| {
                output.output_formats = if (query.bit_depth == 10) c.formats_p010 else c.formats_nv12;
                if (value.provider == .amd) {
                    output.min_width = if (query.codec == c.codec_vp9) 16 else 64;
                    output.min_height = output.min_width;
                    output.max_level = switch (query.codec) {
                        c.codec_h264 => 51,
                        c.codec_hevc => 186,
                        c.codec_vp9 => 62,
                        c.codec_mpeg2 => 0, // MPEG2 level codes are not monotonically ordered.
                        c.codec_vc1 => 4,
                        else => 0,
                    };
                }
                output.device_generation = value.binding.device_generation;
                output.reset_generation = value.binding.reset_generation;
            }
            return c.ok;
        }
        fn gpuCode(err: anyerror) i32 {
            return switch (err) {
                error.Unsupported => c.error_unsupported,
                error.NoMemory => c.error_no_memory,
                error.Busy => c.error_busy,
                error.Stale, error.Timeout => c.error_device_lost,
                else => c.error_invalid,
            };
        }
        fn gpuDevice(adapter: u32, provider: gpu.Provider, codec: u32) !gpu.Device {
            if (adapter == 0) return error.Unsupported;
            const caller = native.application.snapshot() orelse return error.Unsupported;
            const base = caller.base();
            if (caller.* == .legacy and (caller.legacy.bundle.draw orelse return error.Unsupported).abi_version < a.gfx_virtual_layout_api_version) return error.Unsupported;
            inline for (.{ "gfx_queue_backend_info", "gfx_queue_backend_properties", "gfx_queue_open", "gfx_queue_close", "gfx_queue_submit_native", "gfx_fence_query", "gfx_fence_wait", "gfx_fence_cancel", "gfx_fence_release", "gfx_buffer_create", "gfx_buffer_describe", "gfx_buffer_release", "gfx_buffer_map_persistent", "gfx_buffer_unmap", "gfx_native_start", "gfx_native_wait", "gfx_native_receive", "gfx_native_close", "gfx_virtual_start", "gfx_virtual_query", "gfx_virtual_close", "gfx_virtual_wait" }) |field|
                if (!base.hasDrawFn(field)) return error.Unsupported;
            return gpu.Device.queryProvider(base, adapter, if (codec == c.codec_jpeg) .jpeg else .decode, provider);
        }

        pub fn open(input: *const c.R4VideoStartup, output: *c.R4VideoRuntime) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoStartup, input) or !pointerValid(c.R4VideoRuntime, output)) return c.error_invalid;
            const config = input.*;
            if (!payload(config) or config.memory_limit == 0 or config.memory_limit > std.math.maxInt(usize) or
                config.max_decoders == 0 or config.max_decoders > max_decoders or config.thread_limit > 256) return c.error_invalid;
            const caller = native.caller.Input.init(config.application) catch return c.error_invalid;
            const base = caller.base();
            inline for (.{ "gfx_buffer_create", "gfx_buffer_describe", "gfx_buffer_release", "gfx_buffer_map", "gfx_buffer_unmap", "gfx_fence_query", "gfx_fence_release" }) |field| {
                if (!base.hasDrawFn(field)) return c.error_unsupported;
            }
            if (!runtime.bindAddress(config.application)) return c.error_closed;
            const p = native.process_local.getOrCreate(Process, &key, initialize) orelse return c.error_no_memory;
            lock(&p.mutex);
            if (!safeOutput(p, output)) {
                unlock(&p.mutex);
                return c.error_invalid;
            }
            if (p.phase != .unopened) {
                const rc: i32 = if (p.phase == .closing or p.phase == .closed) c.error_closed else c.error_busy;
                unlock(&p.mutex);
                return rc;
            }
            const identity = native.threads.thrd_current();
            const capacity = native.process.cpuCapacity() orelse {
                unlock(&p.mutex);
                return c.error_internal;
            };
            p.generation = identity.instance_generation;
            p.limit = config.max_decoders;
            p.memory = .{ .limit = @intCast(config.memory_limit) };
            p.workers = .{ .limit = if (config.thread_limit == 0) @min(@max(capacity.available_cpus, 1), 64) else config.thread_limit };
            p.retirement = .{ .memory = .{ .limit = @intCast(config.memory_limit), .parent = &p.memory }, .workers = .{ .limit = 1 }, .process_generation = p.generation };
            p.phase = .opening;
            unlock(&p.mutex);
            var success = false;
            defer if (!success) {
                if (p.event != 0 and host().close(p.event) != a.notification_ok)
                    runtime.fatal("R4VIDEO: failed runtime admission event cleanup\n");
                p.event = 0;
                lock(&p.mutex);
                p.phase = .unopened;
                unlock(&p.mutex);
            };
            defer {
                if (!runtime.releaseCaller()) runtime.fatal("R4VIDEO: caller TLS release failed\n");
            }
            if (host().create(&p.event) != a.notification_ok) return c.error_no_memory;
            const scope = runtime.enter(&p.retirement) orelse return c.error_no_memory;
            defer scope.leave();
            if (ff.pthread_create(&p.thread, null, retireWorker, p) != 0) return c.error_no_memory;
            lock(&p.mutex);
            p.phase = .ready;
            output.* = .{ .address = @intFromPtr(p), .generation = p.generation };
            unlock(&p.mutex);
            success = true;
            return c.ok;
        }
        pub fn queryCaps(handle: *const c.R4VideoRuntime, query: *const c.R4VideoCapsQuery, output: *c.R4VideoCaps) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoRuntime, handle) or !pointerValid(c.R4VideoCapsQuery, query)) return c.error_invalid;
            const p = process() orelse return c.error_stale;
            lock(&p.mutex);
            defer unlock(&p.mutex);
            if (!runtimeMatches(p, handle.*)) return c.error_stale;
            if (p.phase != .ready) return c.error_closed;
            if (!safeOutput(p, output)) return c.error_invalid;
            return caps(query.*, output);
        }
        pub fn create(handle: *const c.R4VideoRuntime, input: *const c.R4VideoConfig, output: *c.R4VideoDecoder) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoRuntime, handle) or !pointerValid(c.R4VideoConfig, input)) return c.error_invalid;
            var config = input.*;
            var supported: c.R4VideoCaps = undefined;
            if (!payload(config) or config.flags != 0 or config.memory_limit == 0 or config.memory_limit > std.math.maxInt(usize) or
                config.pending_packets == 0 or config.pending_packets > max_packets or config.frame_leases == 0 or config.frame_leases > max_frames or
                config.max_width < 16 or config.max_width > 4096 or config.max_height < 16 or config.max_height > 4096 or config.threads > max_threads) return c.error_invalid;
            const admitted = caps(config.query, &supported);
            if (admitted != c.ok) return admitted;
            config.query = supported.query;
            const hardware = config.query.backend == c.backend_nvidia or config.query.backend == c.backend_amd;
            if (config.max_width < supported.min_width or config.max_height < supported.min_height) return c.error_unsupported;
            if (hardware) config.threads = 1;
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
            if (config.memory_limit > p.memory.limit or config.threads > p.workers.limit) {
                unlock(&p.mutex);
                return c.error_no_memory;
            }
            if (config.threads == 0) config.threads = @intCast(@min(p.workers.limit, max_threads));
            var chosen: ?*Slot = null;
            for (p.slots[0..p.limit]) |*slot| if (slot.life == .empty) {
                chosen = slot;
                break;
            };
            const slot = chosen orelse {
                unlock(&p.mutex);
                return c.error_busy;
            };
            if (p.serial == std.math.maxInt(u64)) {
                unlock(&p.mutex);
                return c.error_internal;
            }
            p.serial += 1;
            slot.generation = p.serial;
            slot.life = .creating;
            slot.owner = .{ .memory = .{ .limit = @intCast(config.memory_limit), .parent = &p.memory }, .workers = .{ .limit = config.threads, .parent = &p.workers }, .process_generation = p.generation };
            unlock(&p.mutex);
            const scope = runtime.enter(&slot.owner) orelse {
                lock(&p.mutex);
                slot.life = .empty;
                unlock(&p.mutex);
                return c.error_no_memory;
            };
            defer {
                scope.leave();
                if (!runtime.releaseCaller()) runtime.fatal("R4VIDEO: caller TLS release failed\n");
            }
            const d: *Decoder = @ptrCast(@alignCast(runtime.memory.malloc(@sizeOf(Decoder)) orelse {
                lock(&p.mutex);
                slot.life = .empty;
                unlock(&p.mutex);
                return c.error_no_memory;
            }));
            d.* = .{ .process = p, .slot = slot, .config = config };
            lock(&p.mutex);
            slot.decoder = d;
            unlock(&p.mutex);
            var success = false;
            defer if (!success) {
                ff.r4video_codec_close(&d.codec);
                // codec_open performs no picture allocation. The GPU callbacks
                // start only after the worker accepts its first packet.
                if (d.gpu_decoder) |*decoder| decoder.close() catch runtime.fatal("R4VIDEO: GPU admission ownership remains\n");
                if (d.input) |bytes| runtime.memory.free(bytes);
                if (d.event != 0 and host().close(d.event) != a.notification_ok) runtime.fatal("R4VIDEO: failed admission event cleanup\n");
                runtime.memory.free(d);
                lock(&p.mutex);
                slot.decoder = null;
                slot.input_address = 0;
                slot.input_bytes = 0;
                slot.life = .empty;
                unlock(&p.mutex);
            };
            d.input = @ptrCast(runtime.memory.malloc(@as(usize, config.pending_packets) * max_packet_bytes) orelse return c.error_no_memory);
            lock(&p.mutex);
            slot.input_address = @intFromPtr(d.input.?);
            slot.input_bytes = @as(u64, config.pending_packets) * max_packet_bytes;
            unlock(&p.mutex);
            if (host().create(&d.event) != a.notification_ok) return c.error_no_memory;
            var callbacks: ff.struct_r4video_nvdec_ops = undefined;
            if (hardware) {
                const device = gpuDevice(config.query.adapter_id, if (config.query.backend == c.backend_amd) .amd else .nvidia, config.query.codec) catch |err| return gpuCode(err);
                if (device.binding.device_generation != supported.device_generation or device.binding.reset_generation != supported.reset_generation) return c.error_stale;
                d.gpu_decoder = GpuDecoder.init(.{ .base = buffers().base, .device = device, .budget = &slot.owner.memory, .clock = native.time.read });
                callbacks = d.gpu_decoder.?.ops();
            }
            const codec_config: ff.struct_r4video_codec_config = .{ .profile = config.query.profile, .max_width = config.max_width, .max_height = config.max_height, .threads = if (config.threads <= 2) 1 else config.threads - 1, .max_packet_bytes = max_packet_bytes, .nvdec = if (hardware) &callbacks else null, .codec = config.query.codec, .bit_depth = config.query.bit_depth };
            const opened = ff.r4video_codec_open(&codec_config, &d.codec);
            if (opened != c.ok) return opened;
            ff.r4video_codec_set_notify(d.codec, codecNotify, d);
            if (ff.pthread_create(&d.thread, null, decodeWorker, d) != 0) return c.error_no_memory;
            lock(&p.mutex);
            slot.decoder = d;
            slot.life = .active;
            unlock(&p.mutex);
            success = true;
            output.* = decoderHandle(d);
            return c.ok;
        }
        pub fn send(handle: *const c.R4VideoDecoder, input: *const c.R4VideoPacket) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoPacket, input)) return c.error_invalid;
            const packet = input.*;
            if (!payload(packet) or packet.reserved != 0 or packet.flags & ~@as(u32, 7) != 0 or packet.data_address == 0 or
                packet.data_bytes == 0 or packet.data_bytes > max_packet_bytes or packet.data_address > std.math.maxInt(u64) - packet.data_bytes) return c.error_invalid;
            const guard = acquire(handle) catch |err| return acquireCode(err);
            const d = guard.d;
            if (packet.stream_generation != d.generation) {
                guard.leave();
                return c.error_stale;
            }
            if (d.phase != c.phase_open) {
                const rc = if (d.phase == c.phase_failed) d.last_error else if (d.phase >= c.phase_closing) c.error_closed else c.error_busy;
                guard.leave();
                return rc;
            }
            const item = &d.packets[d.tail];
            if (item.state != .free) {
                guard.leave();
                return c.again;
            }
            const target = d.input.?[d.tail * max_packet_bytes ..][0..@intCast(packet.data_bytes)];
            // Input/output are copied before publication. No allocations or
            // native codec work occur in this bounded public critical section.
            if (overlap(packet.data_address, packet.data_bytes, @intFromPtr(d), @sizeOf(Decoder)) or
                overlap(packet.data_address, packet.data_bytes, @intFromPtr(d.input.?), @as(u64, d.config.pending_packets) * max_packet_bytes))
            {
                guard.leave();
                return c.error_invalid;
            }
            @memcpy(target, @as([*]const u8, @ptrFromInt(packet.data_address))[0..target.len]);
            item.value = packet;
            item.value.data_address = @intFromPtr(target.ptr);
            item.state = .queued;
            d.tail = (d.tail + 1) % d.config.pending_packets;
            d.queued += 1;
            const event = d.event;
            guard.leave();
            wake(event);
            return c.ok;
        }
        pub fn receive(handle: *const c.R4VideoDecoder, output: *c.R4VideoFrame) callconv(.c) i32 {
            const guard = acquireOutput(handle, output) catch |err| return acquireCode(err);
            defer guard.leave();
            const d = guard.d;
            if (d.phase == c.phase_failed) return d.last_error;
            if (d.phase == c.phase_flushing) return c.error_busy;
            if (d.phase >= c.phase_closing) return c.error_closed;
            var chosen: ?*Image = null;
            for (d.images[0..d.config.frame_leases]) |*image| if (image.state == .ready) {
                if (chosen == null or image.frame.lease.token < chosen.?.frame.lease.token) chosen = image;
            };
            const image = chosen orelse return if (d.phase == c.phase_drained) c.eos else c.again;
            image.state = .leased;
            image.acknowledged_lease = std.mem.zeroes(c.R4VideoLease);
            image.acknowledged_receipt = std.mem.zeroes(c.R4VideoReceipt);
            output.* = image.frame;
            return c.ok;
        }
        pub fn release(lease: *const c.R4VideoLease, input: *const c.R4VideoReceipt) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoLease, lease) or !pointerValid(c.R4VideoReceipt, input)) return c.error_invalid;
            const value = lease.*;
            const receipt = input.*;
            if (!payload(receipt) or receipt.reserved != 0 or receipt.result > 0 or value.token == 0) return c.error_invalid;
            var guard = acquire(&value.decoder) catch |err| return acquireCode(err);
            const d = guard.d;
            var chosen: ?*Image = null;
            for (d.images[0..d.config.frame_leases]) |*image| if (std.meta.eql(image.acknowledged_lease, value)) {
                const rc: i32 = if (std.meta.eql(image.acknowledged_receipt, receipt)) c.ok else c.error_invalid;
                guard.leave();
                return rc;
            };
            for (d.images[0..d.config.frame_leases]) |*image| if (image.frame.lease.token == value.token and
                image.frame.lease.stream_generation == value.stream_generation)
            {
                chosen = image;
                break;
            };
            const image = chosen orelse {
                guard.leave();
                return c.error_stale;
            };
            switch (image.state) {
                .returning, .retiring, .ack_ready, .acknowledged => {
                    if (!std.meta.eql(image.receipt, receipt)) {
                        guard.leave();
                        return c.error_invalid;
                    }
                    const accepted = image.state == .ack_ready or image.state == .acknowledged;
                    const notify = image.state == .ack_ready;
                    if (accepted) {
                        image.acknowledged_lease = value;
                        image.acknowledged_receipt = receipt;
                        image.state = .acknowledged;
                    }
                    const event = d.event;
                    guard.leave();
                    if (notify) wake(event);
                    return if (accepted) c.ok else c.again;
                },
                .leased => {},
                else => {
                    guard.leave();
                    return c.error_stale;
                },
            }
            // Validate the supplied real fence before accepting ownership. The
            // public caller serializes this lease; worker cannot revoke it.
            guard.leave();
            const fence: a.GfxFence = @bitCast(receipt.fence);
            if (!std.meta.eql(fence, a.GfxFence{})) {
                if (fence.timeline == 0 or fence.point == 0 or fence.device_generation == 0 or fence.reset_generation == 0) return c.error_invalid;
                var status: a.GfxFenceStatus = .{};
                const q = queues();
                if (q.query(&fence, &status) != a.gfx_queue_ok or !std.meta.eql(status.fence, fence)) return c.error_stale;
            }
            guard = acquire(&value.decoder) catch |err| return acquireCode(err);
            if (image.state != .leased or !std.meta.eql(image.frame.lease, value)) {
                guard.leave();
                return c.error_stale;
            }
            image.receipt = receipt;
            image.fence_released = false;
            image.state = .returning;
            const event = d.event;
            guard.leave();
            wake(event);
            return c.again;
        }
        pub fn control(handle: *const c.R4VideoDecoder, input: *const c.R4VideoControl, output: *c.R4VideoState) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoControl, input) or !pointerValid(c.R4VideoState, output)) return c.error_invalid;
            const request = input.*;
            if (!payload(request) or request.reserved != 0 or request.operation > c.control_close or
                (request.operation == c.control_query and request.request_id != 0) or (request.operation != c.control_query and request.request_id == 0)) return c.error_invalid;
            const guard = acquireOutput(handle, output) catch |err| return acquireCode(err);
            const d = guard.d;
            var notify = false;
            if (request.operation != c.control_query) {
                if (request.request_id == d.request or request.request_id == d.completed) {
                    if (request.operation != (if (request.request_id == d.request) d.operation else d.completed_operation)) {
                        guard.leave();
                        return c.error_invalid;
                    }
                } else {
                    if (d.request != 0) {
                        guard.leave();
                        return c.error_busy;
                    }
                    if (request.request_id <= d.completed) {
                        guard.leave();
                        return c.error_stale;
                    }
                    if (d.phase == c.phase_closed or d.phase == c.phase_closing) {
                        guard.leave();
                        return c.error_closed;
                    }
                    if (d.phase == c.phase_failed and request.operation != c.control_close) {
                        const rc = d.last_error;
                        guard.leave();
                        return rc;
                    }
                    d.operation = request.operation;
                    d.request = request.request_id;
                    d.phase = switch (request.operation) {
                        c.control_drain => c.phase_draining,
                        c.control_flush => c.phase_flushing,
                        else => c.phase_closing,
                    };
                    notify = true;
                }
            }
            output.* = state(d);
            const event = d.event;
            guard.leave();
            if (notify) wake(event);
            return c.ok;
        }
        pub fn destroy(handle: *const c.R4VideoDecoder) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoDecoder, handle)) return c.error_invalid;
            const p = process() orelse return c.error_stale;
            if (p.mutex.tryLock(&host()) != sync.success) return c.error_busy;
            const slot = find(p, handle.*) orelse {
                unlock(&p.mutex);
                return c.error_stale;
            };
            const d = slot.decoder.?;
            if (d.mutex.tryLock(&host()) != sync.success) {
                unlock(&p.mutex);
                return c.error_busy;
            }
            if (slot.life != .closed or d.phase != c.phase_closed or !d.joined) {
                unlock(&d.mutex);
                unlock(&p.mutex);
                return c.error_busy;
            }
            slot.life = .destroying;
            unlock(&d.mutex);
            unlock(&p.mutex);
            if (d.event != 0) {
                if (host().close(d.event) != a.notification_ok) {
                    lock(&p.mutex);
                    slot.life = .closed;
                    unlock(&p.mutex);
                    return c.error_busy;
                }
                d.event = 0;
            }
            if (d.mutex.destroy(&host()) != sync.success) {
                lock(&p.mutex);
                slot.life = .closed;
                unlock(&p.mutex);
                return c.error_busy;
            }
            runtime.memory.free(d);
            if (slot.owner.memory.liveBytes() != 0 or slot.owner.workers.liveBytes() != 0) runtime.fatal("R4VIDEO: decoder ownership remains after close\n");
            lock(&p.mutex);
            slot.decoder = null;
            slot.input_address = 0;
            slot.input_bytes = 0;
            slot.life = .empty;
            unlock(&p.mutex);
            return c.ok;
        }
        pub fn finish(handle: *const c.R4VideoRuntime, timeout_ns: u64) callconv(.c) i32 {
            if (!pointerValid(c.R4VideoRuntime, handle)) return c.error_invalid;
            const p = process() orelse return c.error_stale;
            lock(&p.mutex);
            if (!runtimeMatches(p, handle.*)) {
                unlock(&p.mutex);
                return c.error_stale;
            }
            if (p.phase == .closed) {
                const rc = p.result;
                unlock(&p.mutex);
                return rc;
            }
            for (&p.slots) |*slot| if (slot.life != .empty) {
                unlock(&p.mutex);
                return c.error_busy;
            };
            if (p.phase != .ready and p.phase != .closing) {
                unlock(&p.mutex);
                return c.error_busy;
            }
            p.phase = .closing;
            p.stopping.store(true, .release);
            unlock(&p.mutex);
            const deadline = now() +| timeout_ns;
            if (p.thread.start != null) {
                wake(p.event);
                while (true) {
                    var sequence: u64 = 0;
                    if (host().query(p.event, &sequence) != a.notification_ok) return c.error_internal;
                    const joined = ff.r4video_pthread_tryjoin(&p.thread);
                    if (joined == 0) break;
                    if (joined != ff.EBUSY) return c.error_internal;
                    if (now() >= deadline) return c.error_busy;
                    _ = host().waitUntil(p.event, sequence, @min(deadline, now() +| poll_ns));
                }
            }
            if (p.event != 0) {
                if (host().close(p.event) != a.notification_ok) return c.error_busy;
                p.event = 0;
            }
            if (p.memory.liveBytes() != 0 or p.workers.liveBytes() != 0) return c.error_busy;
            const closed = runtime.finishNative();
            if (closed == .pending) return c.error_busy;
            lock(&p.mutex);
            p.phase = .closed;
            p.result = if (closed == .complete) c.ok else c.error_internal;
            const rc = p.result;
            unlock(&p.mutex);
            return rc;
        }

        fn retireWorker(argument: ?*anyopaque) callconv(.c) ?*anyopaque {
            const p: *Process = @ptrCast(@alignCast(argument.?));
            while (!p.stopping.load(.acquire)) {
                var sequence: u64 = 0;
                if (host().query(p.event, &sequence) != a.notification_ok) runtime.fatal("R4VIDEO: retirement event failed\n");
                var pending = false;
                for (&p.slots) |*slot| {
                    lock(&p.mutex);
                    if ((slot.life != .active and slot.life != .reaping) or slot.decoder == null) {
                        unlock(&p.mutex);
                        continue;
                    }
                    const d = slot.decoder.?;
                    if (!d.exited.load(.acquire)) {
                        unlock(&p.mutex);
                        continue;
                    }
                    slot.life = .reaping;
                    unlock(&p.mutex);
                    if (!d.joined) {
                        const result = ff.r4video_pthread_tryjoin(&d.thread);
                        if (result == ff.EBUSY) {
                            pending = true;
                            continue;
                        }
                        if (result != 0) runtime.fatal("R4VIDEO: coordinator join failed\n");
                        d.joined = true;
                    }
                    lock(&p.mutex);
                    lock(&d.mutex);
                    complete(d, c.phase_closed);
                    slot.life = .closed;
                    unlock(&d.mutex);
                    unlock(&p.mutex);
                }
                if (!p.stopping.load(.acquire)) _ = host().waitUntil(p.event, sequence, if (pending) now() +| poll_ns else sync.forever);
            }
            // Exact join, not this notification, is the retirement boundary.
            wake(p.event);
            return null;
        }
        fn decodeWorker(argument: ?*anyopaque) callconv(.c) ?*anyopaque {
            const d: *Decoder = @ptrCast(@alignCast(argument.?));
            while (true) {
                var sequence: u64 = 0;
                if (host().query(d.event, &sequence) != a.notification_ok) runtime.fatal("R4VIDEO: decoder event failed\n");
                const action = step(d);
                switch (action) {
                    .progress => continue,
                    .exit => break,
                    .wait, .poll => _ = host().waitUntil(d.event, sequence, if (action == .poll) now() +| poll_ns else sync.forever),
                }
            }
            d.exited.store(true, .release);
            wake(d.process.event);
            return null;
        }
        const Action = enum { progress, wait, poll, exit };
        fn codecNotify(context: ?*anyopaque) callconv(.c) void {
            const d: *Decoder = @ptrCast(@alignCast(context.?));
            wake(d.event);
        }
        fn pendingReturns(d: *const Decoder) bool {
            if (d.gpu_pending) return true;
            for (d.images[0..d.config.frame_leases]) |*image| if (image.state == .returning or image.state == .retiring or image.state == .discard) return true;
            return false;
        }
        fn cleanImage(d: *Decoder, image: *Image, discard: bool) bool {
            // Claimed by this worker under mutex. Receipt and storage remain
            // immutable until it publishes ack_ready or empty below.
            if (!discard and !image.fence_released) {
                const fence: a.GfxFence = @bitCast(image.receipt.fence);
                if (!std.meta.eql(fence, a.GfxFence{})) {
                    const q = queues();
                    var status: a.GfxFenceStatus = .{};
                    const rc = q.query(&fence, &status);
                    if (rc != a.gfx_queue_ok or !std.meta.eql(status.fence, fence)) {
                        fail(d, c.error_stale);
                        return false;
                    }
                    if (status.phase != a.gfx_queue_phase_terminal or status.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) != 0) return false;
                    if (q.release(&fence) != a.gfx_queue_ok) return false;
                }
                image.fence_released = true;
            }
            if (image.native_frame.image != null) {
                // Preserve the AVFrame through public acknowledgement. Reaping
                // a DPB-free image at ack_ready would allow early BO reuse.
                if (discard) ff.r4video_codec_release(&image.native_frame);
                lock(&d.mutex);
                image.state = if (discard) .empty else .ack_ready;
                unlock(&d.mutex);
                return true;
            }
            const memory = buffers();
            lock(&d.mutex);
            const recycle = !discard and (d.phase == c.phase_open or d.phase == c.phase_draining or d.phase == c.phase_drained);
            unlock(&d.mutex);
            // A prior close attempt may have partially retired this surface
            // while Flush was pending. Finish that retirement even if Flush
            // has since completed; partial storage must never become a cache.
            if (recycle and image.surface.ready) {
                image.surface.recycle() catch {
                    fail(d, c.error_internal);
                    return false;
                };
            } else image.surface.close(&memory) catch return false;
            lock(&d.mutex);
            image.state = if (discard) .empty else .ack_ready;
            unlock(&d.mutex);
            return true;
        }
        fn step(d: *Decoder) Action {
            // Acknowledged GPU outputs can now release their FFmpeg loan. This
            // worker is the only codec/image owner, including during shutdown.
            lock(&d.mutex);
            for (d.images[0..d.config.frame_leases]) |*image| if (image.state == .acknowledged and image.native_frame.image != null) {
                var released = image.native_frame;
                image.native_frame = std.mem.zeroes(ff.struct_r4video_codec_frame);
                unlock(&d.mutex);
                ff.r4video_codec_release(&released);
                return .progress;
            };
            unlock(&d.mutex);
            d.gpu_pending = false;
            if (d.gpu_decoder) |*decoder| decoder.reap() catch |err| {
                d.gpu_pending = true;
                if (err != error.Busy) fail(d, gpuCode(err));
            };
            // Frame-thread admission may fail after receive returned AGAIN.
            // Its notification resumes this owner even without another packet.
            if (d.codec) |codec| {
                const rejected = ff.r4video_codec_error(codec);
                if (rejected != c.ok) fail(d, rejected);
            }
            // Always service returns, including while Drain is backpressured or
            // the codec has failed. One bounded resource action per pass.
            lock(&d.mutex);
            for (0..d.config.frame_leases) |step_index| {
                const image_index = (d.return_cursor + step_index) % d.config.frame_leases;
                const image = &d.images[image_index];
                if (image.state == .returning or image.state == .discard) {
                    d.return_cursor = (image_index + 1) % d.config.frame_leases;
                    const discard = image.state == .discard;
                    image.state = .retiring;
                    unlock(&d.mutex);
                    if (cleanImage(d, image, discard)) return .progress;
                    lock(&d.mutex);
                    image.state = if (discard) .discard else .returning;
                    unlock(&d.mutex);
                    // A pending fence must not prevent unrelated frames or input
                    // from progressing. Continue with native work this pass.
                    lock(&d.mutex);
                    break;
                }
            }
            const phase = d.phase;
            if (d.request != 0 and d.seen_request != d.request) {
                d.seen_request = d.request;
                if (phase == c.phase_draining) d.drain_sent = false;
            }
            if (phase == c.phase_flushing or phase == c.phase_closing or phase == c.phase_failed) {
                for (d.packets[0..d.config.pending_packets]) |*packet| packet.state = .free;
                d.queued = 0;
                d.head = 0;
                d.tail = 0;
                d.active_packet = null;
                d.need_receive = false;
                d.drain_sent = false;
                var discard = false;
                for (d.images[0..d.config.frame_leases]) |*image| {
                    if (image.state == .ready or image.state == .building) image.state = .discard;
                    // Free cached outputs on Flush/Close/error as well. A token
                    // awaiting public acknowledgement remains a delivered lease.
                    if ((image.state == .empty or image.state == .acknowledged) and !image.surface.empty()) image.state = .discard;
                    if (image.state == .discard) discard = true;
                }
                const returns_pending = pendingReturns(d);
                if (discard) {
                    unlock(&d.mutex);
                    return .poll;
                }
                if (phase == c.phase_flushing) {
                    if (d.generation == std.math.maxInt(u64)) {
                        unlock(&d.mutex);
                        fail(d, c.error_internal);
                        return .progress;
                    }
                    unlock(&d.mutex);
                    ff.r4video_codec_flush(d.codec);
                    if (d.gpu_decoder) |*decoder| decoder.flush();
                    lock(&d.mutex);
                    d.generation += 1;
                    d.last_error = c.ok;
                    complete(d, c.phase_open);
                    unlock(&d.mutex);
                    return .progress;
                }
                unlock(&d.mutex);
                if (d.codec != null) ff.r4video_codec_close(&d.codec);
                if (d.gpu_decoder) |*decoder| decoder.close() catch |err| {
                    if (err != error.Busy) fail(d, gpuCode(err));
                    // Outstanding public images wake us via Release; pending
                    // driver retirement also needs finite worker polling.
                    d.gpu_pending = decoder.pendingRetirement();
                    return if (returns_pending or d.gpu_pending) .poll else .wait;
                };
                if (phase == c.phase_failed) return if (returns_pending) .poll else .wait;
                lock(&d.mutex);
                for (d.images[0..d.config.frame_leases]) |*image| switch (image.state) {
                    .empty, .acknowledged => {},
                    else => {
                        const polling = pendingReturns(d);
                        unlock(&d.mutex);
                        return if (polling) .poll else .wait;
                    },
                };
                const input = d.input;
                d.input = null;
                unlock(&d.mutex);
                if (input) |bytes| runtime.memory.free(bytes);
                return .exit;
            }
            if (phase == c.phase_drained) {
                const polling = pendingReturns(d);
                unlock(&d.mutex);
                return if (polling) .poll else .wait;
            }
            if (d.need_receive) {
                var available: ?*Image = null;
                for (d.images[0..d.config.frame_leases]) |*image| if (image.state == .empty or image.state == .acknowledged) {
                    available = image;
                    break;
                };
                const image = available orelse {
                    const polling = pendingReturns(d);
                    unlock(&d.mutex);
                    return if (polling) .poll else .wait;
                };
                image.state = .building;
                // Producer work may reuse storage. Keep the separate last
                // acknowledgement until Receive publishes a new consumer loan.
                image.frame = std.mem.zeroes(c.R4VideoFrame);
                image.receipt = std.mem.zeroes(c.R4VideoReceipt);
                image.fence_released = false;
                const generation = d.generation;
                unlock(&d.mutex);
                var decoded: ff.struct_r4video_codec_frame = std.mem.zeroes(ff.struct_r4video_codec_frame);
                const received = ff.r4video_codec_receive(d.codec, &decoded);
                if (received != c.ok) {
                    lock(&d.mutex);
                    image.state = .empty;
                    if (received == c.again or received == c.eos) d.need_receive = false;
                    if (received == c.eos) {
                        if (d.phase == c.phase_draining) {
                            complete(d, c.phase_drained);
                        } else if (d.phase == c.phase_open) {
                            d.last_error = c.error_internal;
                            complete(d, c.phase_failed);
                        }
                    }
                    unlock(&d.mutex);
                    if (received != c.again and received != c.eos) fail(d, received);
                    return .progress;
                }
                defer ff.r4video_codec_release(&decoded);
                const memory = buffers();
                if (d.gpu_decoder) |*decoder| {
                    if (decoded.hardware_image == null or decoder.describe(decoded.hardware_image) == null) {
                        lock(&d.mutex);
                        image.state = .discard;
                        unlock(&d.mutex);
                        fail(d, c.error_device_lost);
                        return .progress;
                    }
                } else image.surface.upload(&memory, &d.slot.owner.memory, .{
                    .data = .{ @ptrCast(decoded.data[0]), @ptrCast(decoded.data[1]), @ptrCast(decoded.data[2]) },
                    .pitch = decoded.pitch,
                    .width = decoded.width,
                    .height = decoded.height,
                }) catch |err| {
                    lock(&d.mutex);
                    image.state = .discard;
                    unlock(&d.mutex);
                    fail(d, if (err == error.NoMemory) c.error_no_memory else c.error_internal);
                    return .progress;
                };
                lock(&d.mutex);
                if (d.phase == c.phase_flushing or d.phase == c.phase_closing or d.phase == c.phase_failed) {
                    image.state = .discard;
                    unlock(&d.mutex);
                    return .progress;
                }
                if (d.token == std.math.maxInt(u64)) {
                    image.state = .discard;
                    unlock(&d.mutex);
                    fail(d, c.error_internal);
                    return .progress;
                }
                d.token += 1;
                image.frame = makeFrame(d, image, decoded, generation);
                if (decoded.hardware_image != null) {
                    image.native_frame = decoded;
                    decoded = std.mem.zeroes(ff.struct_r4video_codec_frame);
                }
                image.state = .ready;
                unlock(&d.mutex);
                return .progress;
            }
            if (d.active_packet == null and d.queued != 0) {
                const index = d.head;
                const packet = &d.packets[index];
                if (packet.state != .queued) {
                    unlock(&d.mutex);
                    fail(d, c.error_internal);
                    return .progress;
                }
                packet.state = .working;
                d.active_packet = index;
                d.head = (d.head + 1) % d.config.pending_packets;
                d.queued -= 1;
            }
            if (d.active_packet) |index| {
                const packet = d.packets[index].value;
                unlock(&d.mutex);
                const input: ff.struct_r4video_codec_packet = .{ .bytes = @ptrFromInt(packet.data_address), .size = packet.data_bytes, .tag = packet.tag, .pts = packet.pts_ns, .dts = packet.dts_ns, .duration = packet.duration_ns, .flags = packet.flags };
                const sent = ff.r4video_codec_send(d.codec, &input);
                lock(&d.mutex);
                if (sent != c.again) {
                    d.packets[index].state = .free;
                    d.active_packet = null;
                }
                if (sent == c.ok or sent == c.again) d.need_receive = true;
                unlock(&d.mutex);
                if (sent != c.ok and sent != c.again) fail(d, sent);
                return .progress;
            }
            if (phase == c.phase_draining and !d.drain_sent) {
                unlock(&d.mutex);
                const drained = ff.r4video_codec_drain(d.codec);
                lock(&d.mutex);
                if (drained == c.ok) {
                    d.drain_sent = true;
                    d.need_receive = true;
                }
                if (drained == c.again) d.need_receive = true;
                if (drained == c.eos) complete(d, c.phase_drained);
                unlock(&d.mutex);
                if (drained != c.ok and drained != c.again and drained != c.eos) fail(d, drained);
                return .progress;
            }
            const polling = pendingReturns(d);
            unlock(&d.mutex);
            return if (polling) .poll else .wait;
        }
        fn makeFrame(d: *Decoder, image: *const Image, frame: ff.struct_r4video_codec_frame, generation: u64) c.R4VideoFrame {
            var result: c.R4VideoFrame = std.mem.zeroes(c.R4VideoFrame);
            result.version = 1;
            result.size = @sizeOf(c.R4VideoFrame);
            result.lease = .{ .decoder = decoderHandle(d), .token = d.token, .stream_generation = generation };
            result.tag = frame.tag;
            result.pts_ns = frame.pts;
            result.dts_ns = frame.dts;
            result.duration_ns = frame.duration;
            result.coded_width = frame.width;
            result.coded_height = frame.height;
            result.crop_x = frame.crop_x;
            result.crop_y = frame.crop_y;
            result.crop_width = frame.crop_width;
            result.crop_height = frame.crop_height;
            result.sar_num = frame.sar_num;
            result.sar_den = frame.sar_den;
            result.format = c.format_yuv420p;
            result.plane_count = 3;
            result.color = .{ .version = 1, .size = @sizeOf(c.R4VideoColor), .primaries = frame.primaries, .transfer = frame.transfer, .range = frame.range, .matrix = frame.matrix, .chroma_location = frame.chroma_location, .bit_depth = d.config.query.bit_depth, .reference_white = 0, .peak = 0, .black = 0, .flags = 0 };
            if (frame.hardware_image != null) {
                const buffer = d.gpu_decoder.?.describe(frame.hardware_image).?;
                result.format = if (d.config.query.bit_depth == 10) c.format_p010 else c.format_nv12;
                result.plane_count = 2;
                inline for (.{ "plane0", "plane1" }, 0..) |field, index| {
                    @field(result, field) = .{ .buffer = @bitCast(buffer.backing.buffer), .reference = @bitCast(buffer.backing.reference), .offset = buffer.descriptor.plane_offsets[index], .pitch = buffer.descriptor.plane_pitches[index], .row_bytes = @as(u64, frame.width) * @as(u64, if (d.config.query.bit_depth == 10) 2 else 1), .rows = if (index == 0) frame.height else (frame.height + 1) / 2, .reserved = 0 };
                }
            } else inline for (.{ "plane0", "plane1", "plane2" }, 0..) |field, index| {
                const plane = &image.surface.planes[index];
                @field(result, field) = .{ .buffer = @bitCast(plane.backing.buffer), .reference = @bitCast(plane.backing.reference), .offset = plane.descriptor.plane_offsets[0], .pitch = plane.descriptor.plane_pitches[0], .row_bytes = plane.row_bytes, .rows = plane.rows, .reserved = 0 };
            }
            result.flags = frame.flags;
            return result;
        }
    };
}
