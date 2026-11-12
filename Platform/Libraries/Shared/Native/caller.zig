// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// An admitted caller view is borrowed only while constructing a snapshot.
// The snapshot itself lives in caller-owned or process-owned stable storage.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const a2 = r.platform2.abi;

pub const Input = union(enum) {
    legacy: r.program.Bundle,
    generation2: r.platform2.Context,

    pub fn init(raw_address: u64) error{Invalid}!Input {
        if (raw_address == 0 or raw_address % 8 != 0 or @addWithOverflow(raw_address, 16)[1] != 0) return error.Invalid;
        const magic: *const u32 = @ptrFromInt(raw_address);
        if (magic.* == a2.start_magic) {
            if (@addWithOverflow(raw_address, @sizeOf(a2.R4XStartContext2))[1] != 0) return error.Invalid;
            const raw: *const a2.R4XStartContext2 = @ptrFromInt(raw_address);
            return .{ .generation2 = r.platform2.Context.init(raw) catch return error.Invalid };
        }
        if (magic.* != a.r4xstart_magic or @addWithOverflow(raw_address, @sizeOf(a.R4XStartContext))[1] != 0) return error.Invalid;
        const raw: *const a.R4XStartContext = @ptrFromInt(raw_address);
        return .{ .legacy = r.program.bundleValueFromR4XStart(raw) orelse return error.Invalid };
    }
    pub fn address(self: Input) u64 {
        return switch (self) {
            .legacy => |view| @intFromPtr(view.raw),
            .generation2 => |view| @intFromPtr(view.raw),
        };
    }
    pub fn bytes(self: Input) usize {
        return switch (self) {
            .legacy => @sizeOf(a.R4XStartContext),
            .generation2 => @sizeOf(a2.R4XStartContext2),
        };
    }
    pub fn instance(self: Input) u64 {
        return switch (self) {
            .legacy => |view| view.raw.instance_id,
            .generation2 => |view| view.raw.instance_id,
        };
    }
    pub fn base(self: *const Input) r.program.Context {
        return switch (self.*) {
            .legacy => .initBundle(&self.legacy),
            .generation2 => .{ .generation2 = &self.generation2 },
        };
    }
    pub fn system(self: *const Input) r.r4sys.Context {
        return .{ .base = self.base() };
    }
};

pub const Snapshot = union(enum) {
    legacy: struct { raw: a.R4XStartContext, bundle: r.program.Bundle },
    generation2: struct { raw: a2.R4XStartContext2, context: r.platform2.Context, c_view: r.platform2.CView },

    // Initialize at the final address: each view refers to this object's raw
    // record, while names/import arrays remain borrowed from the real process.
    pub fn init(self: *Snapshot, input: Input) void {
        switch (input) {
            .legacy => |view| {
                self.* = .{ .legacy = .{ .raw = view.raw.*, .bundle = view } };
                self.legacy.bundle.raw = &self.legacy.raw;
            },
            .generation2 => |view| {
                self.* = .{ .generation2 = .{ .raw = view.raw.*, .context = view, .c_view = undefined } };
                self.generation2.context.raw = &self.generation2.raw;
                self.generation2.c_view = self.generation2.context.cView();
            },
        }
    }
    pub fn matches(self: *const Snapshot, input: Input) bool {
        return switch (self.*) {
            .legacy => switch (input) {
                .legacy => |view| std.meta.eql(self.legacy.raw, view.raw.*),
                .generation2 => false,
            },
            .generation2 => switch (input) {
                .legacy => false,
                .generation2 => |view| std.meta.eql(self.generation2.raw, view.raw.*),
            },
        };
    }
    pub fn base(self: *const Snapshot) r.program.Context {
        return switch (self.*) {
            .legacy => .initBundle(&self.legacy.bundle),
            .generation2 => .{ .generation2 = &self.generation2.context },
        };
    }
    pub fn client(self: *const Snapshot, comptime Client: type) !Client {
        return switch (self.*) {
            .legacy => Client.init(&self.legacy.raw),
            .generation2 => Client.init2(&self.generation2.raw),
        };
    }
    pub fn system(self: *const Snapshot) r.r4sys.Context {
        return .{ .base = self.base() };
    }
    pub fn address(self: *const Snapshot) u64 {
        return switch (self.*) {
            .legacy => @intFromPtr(&self.legacy.raw),
            .generation2 => @intFromPtr(&self.generation2.raw),
        };
    }
    pub fn instance(self: *const Snapshot) u64 {
        return switch (self.*) {
            .legacy => self.legacy.raw.instance_id,
            .generation2 => self.generation2.raw.instance_id,
        };
    }
};
