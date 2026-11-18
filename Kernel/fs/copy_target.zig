// A paired filesystem request excludes other writers until publication and
// cleanup finish. Private sibling names must also be distinct by FS collation.
const vfs = @import("vfs.zig");

var sequence: u32 = 0;
const hex = "0123456789ABCDEF";

pub const Target = struct {
    volume: vfs.Volume,
    parent: vfs.NodeRef,
    name: []const u8,
    stage: [12]u8 = "~C000000.TMP".*,
    backup: [12]u8 = "~C000000.BAK".*,

    pub fn select(volume: vfs.Volume, parent: vfs.NodeRef, name: []const u8) ?Target {
        var target = Target{ .volume = volume, .parent = parent, .name = name };
        names: for (0..128) |_| {
            const id = @atomicRmw(u32, &sequence, .Add, 1, .monotonic);
            for (0..6) |i| target.stage[i + 2] = hex[(id >> @intCast(4 * (5 - i))) & 15];
            @memcpy(target.backup[0..8], target.stage[0..8]);
            for ([_][]const u8{ &target.stage, &target.backup }) |sibling| {
                const equal = vfs.namesEqualCollated(volume, name, sibling) orelse return null;
                if (equal or (target.lookup(sibling) catch return null) != null) continue :names;
            }
            return target;
        }
        return null;
    }

    fn lookup(self: *const Target, name: []const u8) error{Io}!?vfs.Entry {
        var entry: vfs.Entry = undefined;
        return switch (vfs.lookupRecoveryEntryStatus(self.volume, self.parent, name, &entry)) {
            .found => entry,
            .not_found => null,
            .io => error.Io,
        };
    }

    fn samePayload(a: vfs.Entry, b: vfs.Entry) bool {
        return !a.isDir() and !b.isDir() and a.node == b.node and
            a.node_generation == b.node_generation and a.size == b.size;
    }

    fn remove(self: *const Target, name: []const u8, expected: vfs.Entry) bool {
        return switch (vfs.deleteFileIfIdentity(self.volume, self.parent, name, expected)) {
            .deleted, .not_found => true,
            .io, .mismatch => false,
        };
    }

    fn finish(self: *const Target, original: ?vfs.Entry) bool {
        return if (original) |old| self.remove(&self.backup, old) else true;
    }

    fn createFrom(self: *const Target, name: []const u8) bool {
        return vfs.publishStagedCopy(self.volume, self.parent, name, self.name);
    }

    fn install(self: *const Target, replacing: bool) bool {
        if (!replacing) return self.createFrom(&self.stage);
        return vfs.replaceFileAtomic(self.volume, self.parent, self.name, &self.stage, &self.backup, true) == .ok;
    }

    pub fn publish(self: *const Target, original: ?vfs.Entry) bool {
        const staged = (self.lookup(&self.stage) catch return false) orelse return false;
        if (self.install(original != null)) return self.finish(original);

        // The first write can have reached disk despite an I/O error. Never
        // delete by name once the staged chain may already belong to target.
        for (0..2) |attempt| {
            const target = self.lookup(self.name) catch return false;
            const stage = self.lookup(&self.stage) catch return false;
            const backup = self.lookup(&self.backup) catch return false;
            if (stage) |s| if (!samePayload(s, staged)) return false;
            if (backup) |b| if (original == null or !samePayload(b, original.?)) return false;
            const new_target = if (target) |t| samePayload(t, staged) else false;
            const old_target = if (target) |t| original != null and samePayload(t, original.?) else false;
            if (new_target and stage == null) return vfs.flushVolume(self.volume) and self.finish(original);
            if (target != null and !new_target and !old_target) return false;
            if (attempt == 0 and stage != null) {
                if (self.install(original != null)) return self.finish(original);
                continue;
            }
            if (!new_target and backup != null and !self.createFrom(&self.backup)) return false;
            if (!new_target and stage != null and (old_target or original == null or backup != null)) {
                _ = self.remove(&self.stage, staged);
            }
            return false;
        }
        return false;
    }
};
