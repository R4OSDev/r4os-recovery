const std = @import("std");
const owner = @import("system_update_engine").removal;
const plan = owner.Plan{ .request_id = "a" ** 64, .target = "C:\\Apps\\DEMO.R4X", .name = "DEMO", .version = "1.0.0", .previous = .{ .size = 16, .checksum = 123, .sha256 = ("b" ** 64).* } };
const Io = struct {
    record: ?owner.Record = null,
    receipt: ?owner.Record = null,
    present: bool = true,
    inventory: bool = true,
    active: bool = false,
    changed: bool = false,
    stop: bool = false,
    fail_after_delete: bool = false,
    deletes: usize = 0,
    pub fn load(self: *Io) !?owner.Record {
        return self.record;
    }
    pub fn history(self: *Io, _: []const u8) !?owner.Record {
        return self.receipt;
    }
    pub fn archive(self: *Io, record: owner.Record) !void {
        self.receipt = record;
    }
    pub fn recordExists(self: *Io, _: []const u8) !bool {
        return self.record != null;
    }
    pub fn admit(self: *Io, _: owner.Plan) !void {
        if (self.changed) return error.Changed;
        if (!self.present or !self.inventory) return error.Missing;
    }
    pub fn persist(self: *Io, record: *owner.Record) !void {
        if (self.fail_after_delete and record.phase == .payload_removed) {
            self.fail_after_delete = false;
            return error.LostReply;
        }
        record.generation += 1;
        self.record = record.*;
    }
    pub fn cancelled(self: *Io) bool {
        return self.stop;
    }
    pub fn running(self: *Io, _: owner.Plan) !bool {
        return self.active;
    }
    pub fn absent(self: *Io, _: owner.Plan) !bool {
        return !self.present;
    }
    pub fn inventoryAbsent(self: *Io, _: owner.Plan) !bool {
        return !self.inventory;
    }
    pub fn delete(self: *Io, _: owner.Plan) !void {
        self.present = false;
        self.deletes += 1;
    }
    pub fn removeInventory(self: *Io, _: *owner.Record) !void {
        self.inventory = false;
    }
};
test "application removal waits for close and repeats without deleting again" {
    var io = Io{ .active = true };
    try std.testing.expectEqual(owner.State.waiting_for_close, (try owner.execute(&io, plan)).state);
    try std.testing.expect(io.present and io.inventory and io.deletes == 0);
    io.active = false;
    try std.testing.expectEqual(owner.State.removed, (try owner.execute(&io, plan)).state);
    _ = try owner.execute(&io, plan);
    try std.testing.expect(!io.present and !io.inventory and io.deletes == 1);
    io.present = true;
    try std.testing.expectError(error.RemoveTargetReappeared, owner.execute(&io, plan));
}
test "application removal resumes a lost checkpoint after actual deletion" {
    var io = Io{ .fail_after_delete = true };
    try std.testing.expectError(error.LostReply, owner.execute(&io, plan));
    try std.testing.expect(!io.present and io.inventory);
    io.stop = true; // Cancellation after an ambiguous actual delete must settle inventory.
    _ = try owner.execute(&io, plan);
    try std.testing.expect(!io.inventory and io.deletes == 1);
}
test "application removal rejects changed files foreign requests and system assets" {
    var io = Io{ .changed = true };
    try std.testing.expectError(error.Changed, owner.execute(&io, plan));
    try std.testing.expect(io.present and io.deletes == 0);
    io.changed = false;
    io.active = true;
    _ = try owner.execute(&io, plan);
    var foreign = plan;
    foreign.request_id = "c" ** 64;
    try std.testing.expectError(error.RemoveForeignTransaction, owner.execute(&io, foreign));
    io.stop = true;
    try std.testing.expectEqual(owner.State.cancelled, (try owner.execute(&io, plan)).state);
    try std.testing.expect(io.present and io.inventory);
    var system = plan;
    system.target = "C:\\R4OS\\LIBS\\DEMO.R4L";
    try std.testing.expectError(error.RemovePlan, system.validate());
    system.target = "C:\\BOOT\\KERNEL.R4X";
    try std.testing.expectError(error.RemovePlan, system.validate());
}
