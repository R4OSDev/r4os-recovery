// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");

/// Stable owner, retained until every allocation, worker and surface reservation
/// is returned. Limits never change while the owner is in use. A stream has
/// exactly one aggregate runtime parent; no locks span allocation or kernel I/O.
pub const Budget = struct {
    limit: usize,
    parent: ?*Budget = null,
    used: std.atomic.Value(usize) = .init(0),

    fn claim(self: *Budget, bytes: usize) bool {
        var old = self.used.load(.monotonic);
        while (true) {
            if (old > self.limit or bytes > self.limit - old) return false;
            if (self.used.cmpxchgWeak(old, old + bytes, .acq_rel, .monotonic)) |observed|
                old = observed
            else
                return true;
        }
    }
    pub fn reserve(self: *Budget, bytes: usize) bool {
        if (bytes == 0) return false;
        if (self.parent) |parent| {
            std.debug.assert(parent != self and parent.parent == null);
            if (!parent.claim(bytes)) return false;
            if (!self.claim(bytes)) {
                parent.giveBack(bytes);
                return false;
            }
            return true;
        }
        return self.claim(bytes);
    }
    fn giveBack(self: *Budget, bytes: usize) void {
        const old = self.used.fetchSub(bytes, .acq_rel);
        if (bytes == 0 or old < bytes) @trap();
    }
    pub fn release(self: *Budget, bytes: usize) void {
        // Keep the aggregate reservation until its leaf has returned it.
        self.giveBack(bytes);
        if (self.parent) |parent| parent.giveBack(bytes);
    }
    pub fn liveBytes(self: *const Budget) usize {
        return self.used.load(.acquire);
    }
};
