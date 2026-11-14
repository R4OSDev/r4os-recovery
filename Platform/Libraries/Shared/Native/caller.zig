// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Inputs borrow current resident imports; snapshots live at their final address.
const std = @import("std");
const r = @import("r4os");
const a2 = r.platform2.abi;
pub const Input = union(enum) {
    generation2: r.platform2.Context,
    pub fn init(address_: u64) error{Invalid}!Input {
        if (address_ == 0 or address_ % 8 != 0 or @addWithOverflow(address_, @sizeOf(a2.R4XStartContext2))[1] != 0) return error.Invalid;
        const raw: *const a2.R4XStartContext2 = @ptrFromInt(address_);
        return .{ .generation2 = r.platform2.Context.init(raw) catch return error.Invalid };
    }
    pub fn address(self: Input) u64 {
        return @intFromPtr(self.generation2.raw);
    }
    pub fn bytes(_: Input) usize {
        return @sizeOf(a2.R4XStartContext2);
    }
    pub fn instance(self: Input) u64 {
        return self.generation2.raw.instance_id;
    }
    pub fn base(self: *const Input) r.program.Context {
        return .{ .generation2 = &self.generation2 };
    }
    pub fn system(self: *const Input) r.r4sys.Context {
        return .{ .base = self.base() };
    }
};
pub const Snapshot = union(enum) {
    generation2: struct { raw: a2.R4XStartContext2, context: r.platform2.Context, c_view: r.platform2.CView },
    pub fn init(self: *Snapshot, input: Input) void {
        self.* = .{ .generation2 = .{ .raw = input.generation2.raw.*, .context = input.generation2, .c_view = undefined } };
        self.generation2.context.raw = &self.generation2.raw;
        self.generation2.c_view = self.generation2.context.cView();
    }
    pub fn matches(self: *const Snapshot, input: Input) bool {
        return std.meta.eql(self.generation2.raw, input.generation2.raw.*);
    }
    pub fn base(self: *const Snapshot) r.program.Context {
        return .{ .generation2 = &self.generation2.context };
    }
    pub fn client(self: *const Snapshot, comptime Client: type) !Client {
        return Client.init2(&self.generation2.raw);
    }
    pub fn system(self: *const Snapshot) r.r4sys.Context {
        return .{ .base = self.base() };
    }
    pub fn address(self: *const Snapshot) u64 {
        return @intFromPtr(&self.generation2.raw);
    }
    pub fn instance(self: *const Snapshot) u64 {
        return self.generation2.raw.instance_id;
    }
};
