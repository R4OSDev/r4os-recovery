const std = @import("std");
const r4os = @import("r4os");
fn require(ok: bool) !void {
    if (!ok) return error.Oracle;
}
fn Caller(comptime B: type) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        state: *B.R4L66State,
        close_fn: B.ApiV1CloseFn,
        generation: u64,
        memory: ?*[2]u64 = null,
        notifies: u32 = 0,
        releases: u32 = 0,
        attempts: u32 = 0,
        fail_allocate: bool = false,
        fail_release: bool = false,
        fn allocate(owner: u64, bytes: u64) callconv(.c) u64 {
            const self: *Self = @ptrFromInt(owner);
            if (bytes != 16 or self.fail_allocate or self.memory != null) return 0;
            const memory = self.allocator.create([2]u64) catch return 0;
            self.memory = memory;
            return @intFromPtr(memory);
        }
        fn release(owner: u64, address: u64) callconv(.c) i32 {
            const self: *Self = @ptrFromInt(owner);
            self.attempts += 1;
            if (self.fail_release) {
                self.fail_release = false;
                return -44;
            }
            const memory = self.memory orelse return -50;
            if (@intFromPtr(memory) != address) return -51;
            self.allocator.destroy(memory);
            self.memory = null;
            self.releases += 1;
            return 0;
        }
        fn notify(owner: u64, generation: u64, value: u64) callconv(.c) i32 {
            const self: *Self = @ptrFromInt(owner);
            if (generation != self.generation or value == 0 or self.close_fn(self.state, generation) != -2) return -77;
            self.notifies += 1;
            return 0;
        }
    };
}
fn runOne(comptime B: type, app: *r4os.App, tag: u64) !void {
    const client = try B.ApiV1Client.init(app.startContext());
    const C = Caller(B);
    const qi = r4os.r4xstart.Context.init(app.startContext()).findImportNamed(B.module_name, "Query") orelse return error.MissingQuery;
    try require(qi.table != 0 and qi.resolved_version == 1);
    const query: *const r4os.abi.R4LQuery = @ptrFromInt(qi.table);
    try require(query.magic == r4os.abi.r4l_abi_magic and query.abi_version == r4os.abi.r4l_abi_version and query.group == 0 and query.kernel_bridge == 0);
    const close_fn = r4os.runtime_r4l.functionAt(B.ApiV1CloseFn, client.header, 48).?;
    var a = std.mem.zeroes(B.R4L66State);
    var b = std.mem.zeroes(B.R4L66State);
    var ca = C{ .allocator = app.allocator().?, .state = &a, .close_fn = close_fn, .generation = 11, .fail_allocate = true };
    var cb = C{ .allocator = app.allocator().?, .state = &b, .close_fn = close_fn, .generation = 22 };
    try require(client.open(&a, @intFromPtr(&ca), 11, @intFromPtr(&C.allocate), @intFromPtr(&C.release), @intFromPtr(&C.notify)) == -4 and a.active == 0 and a.in_callback == 0);
    ca.fail_allocate = false;
    try require(client.open(&a, @intFromPtr(&ca), 11, @intFromPtr(&C.allocate), @intFromPtr(&C.release), @intFromPtr(&C.notify)) == 0);
    try require(client.open(&b, @intFromPtr(&cb), 22, @intFromPtr(&C.allocate), @intFromPtr(&C.release), @intFromPtr(&C.notify)) == 0);
    try require(a.allocation != 0 and b.allocation != 0 and a.allocation != b.allocation);
    var value: u64 = 999;
    var sum: u64 = 0;
    try require(client.work(&a, 99, 100, &value) == -3 and value == 999 and ca.notifies == 0);
    try require(client.work(&a, 11, 100, &value) == 0 and value == 101 + tag);
    sum += value;
    try require(client.work(&b, 22, 200, &value) == 0 and value == 201 + tag);
    sum += value;
    const held = a.allocation;
    ca.fail_release = true;
    try require(client.close(&a, 99) == -3 and a.allocation == held and ca.attempts == 0);
    try require(client.close(&a, 11) == -44 and a.active == 1 and a.allocation == held and ca.releases == 0);
    try require(client.close(&a, 11) == 0 and a.active == 0 and a.allocation == 0 and ca.releases == 1);
    try require(client.work(&b, 22, 300, &value) == 0 and value == 302 + tag);
    sum += value;
    try require(client.close(&a, 11) == -1 and client.close(&b, 22) == 0 and b.active == 0);
    try require(ca.notifies == 1 and cb.notifies == 2 and ca.attempts == 2 and cb.attempts == 1 and cb.releases == 1 and sum == 604 + 3 * tag);
    app.system().println(if (tag == 0x43) "PASS R4L66 L66C work=805 sessions=2 callbacks=3 failed-release-held=1 heap=exact" else "PASS R4L66 L66R work=850 sessions=2 callbacks=3 failed-release-held=1 heap=exact");
}
fn run(app: *r4os.App) !void {
    const before = r4os.vm_allocator.stats();
    try runOne(@import("c_provider"), app, 0x43);
    try runOne(@import("rust_provider"), app, 0x52);
    const after = r4os.vm_allocator.stats();
    try require(before.active_allocations == after.active_allocations and before.active_bytes == after.active_bytes);
    app.system().println("PASS R4L66 independent Zig generated clients and exact active heap release");
}
pub fn r4_app_main(app: *r4os.App) i32 {
    run(app) catch |err| {
        app.system().println(@errorName(err));
        return 1;
    };
    return 0;
}
