// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Provider selection for the existing worker and input/packet lifetime.
const r = @import("r4os");
const gpu = @import("gpu_resources");
const nv = @import("gpu_backend");
pub fn Implementation(comptime ff: type) type {
    const amd = @import("amd_encoder").Implementation(ff);
    return struct {
        const Budget = @import("native_allocation").Budget;
        pub const Error = nv.Error || amd.Error;
        pub const Config = union(enum) {
            nvidia: nv.Config,
            amd: amd.Config,
            pub fn from(value: anytype) Error!Config {
                return switch (value.query.backend) {
                    1 => .{ .nvidia = try nv.Config.from(value) },
                    2 => .{ .amd = try amd.Config.from(value) },
                    else => error.Unsupported,
                };
            }
        };
        pub const Devices = union(enum) {
            nvidia: nv.Devices,
            amd: gpu.Device,
            pub fn query(base: r.program.Context, adapter: u32, backend: u32) Error!Devices {
                return switch (backend) {
                    1 => .{ .nvidia = try nv.Devices.query(base, adapter) },
                    2 => .{ .amd = try gpu.Device.queryProvider(base, adapter, .encode, .amd) },
                    else => error.Unsupported,
                };
            }
        };
        pub const Backend = struct {
            state: union(enum) { nvidia: nv.Backend, amd: amd.Backend },
            failed: bool = false,
            closed: bool = false,
            pub fn init(base: r.program.Context, devices: Devices, budget: *Budget, clock: gpu.Clock, config: Config) Backend {
                return .{ .state = switch (config) {
                    .nvidia => |settings| .{ .nvidia = nv.Backend.init(base, devices.nvidia, budget, clock, settings) },
                    .amd => |settings| .{ .amd = amd.Backend.init(base, devices.amd, budget, clock, settings) },
                } };
            }
            fn refresh(self: *Backend) void {
                switch (self.state) {
                    inline else => |*backend| {
                        self.failed = backend.failed;
                        self.closed = backend.closed;
                    },
                }
            }
            pub fn encode(self: *Backend, input: anytype, force: bool, output: []u8, until: u64) Error!amd.Packet {
                defer self.refresh();
                return switch (self.state) {
                    inline else => |*backend| blk: {
                        const packet = try backend.encode(input, force, output, until);
                        break :blk .{ .bytes = packet.bytes, .key = packet.key };
                    },
                };
            }
            pub fn retireInput(self: *Backend) Error!void {
                defer self.refresh();
                switch (self.state) {
                    inline else => |*backend| try backend.retireInput(),
                }
            }
            pub fn reset(self: *Backend) Error!void {
                defer self.refresh();
                switch (self.state) {
                    inline else => |*backend| try backend.reset(),
                }
            }
            pub fn close(self: *Backend) Error!void {
                defer self.refresh();
                switch (self.state) {
                    inline else => |*backend| try backend.close(),
                }
            }
        };
    };
}
