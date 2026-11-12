//! Language-boundary adapters, with no codec/font/image implementation.
const std = @import("std");
const r4os = @import("r4os");

pub const Session = struct {
    bundle: r4os.program.Bundle,
    app2: ?r4os.App2 = null,
    sys: r4os.r4sys.Context,
};
pub fn openSession(output: *Session, raw: *const r4os.abi.R4XStartContext) bool {
    const bundle = r4os.program.bundleValueFromR4XStart(raw) orelse return false;
    output.* = .{ .bundle = bundle, .sys = undefined };
    output.sys = r4os.r4sys.Context.init(&output.bundle);
    return true;
}
pub fn openSession2(output: *Session, raw: *const r4os.platform2.abi.R4XStartContext2) bool {
    const profile: r4os.AppProfile = if (raw.app_class == @intFromEnum(r4os.abi.R4XStartAppClass.service)) .service else .console;
    const app = switch (r4os.App2.init(raw, profile)) {
        .value => |value| value,
        .failure => return false,
    };
    output.* = .{ .bundle = undefined, .app2 = app, .sys = undefined };
    output.sys = output.app2.?.system();
    return true;
}
pub fn system(session: *Session) *r4os.r4sys.Context {
    return &session.sys;
}

/// Callbacks use their original C ABI. The caller retains this descriptor at
/// its exact address until every object/allocation using it has been freed.
pub const Memory = struct {
    user: ?*anyopaque = null,
    allocate: *const fn (?*anyopaque, usize, usize) callconv(.c) ?[*]u8,
    release: *const fn (?*anyopaque, [*]u8, usize, usize) callconv(.c) void,
    pub fn allocator(self: *Memory) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &vtable };
    }
    const vtable: std.mem.Allocator.VTable = .{ .alloc = alloc, .resize = resize, .remap = remap, .free = free };
    fn alloc(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, _: usize) ?[*]u8 {
        const self: *Memory = @ptrCast(@alignCast(ctx));
        return self.allocate(self.user, len, alignment.toByteUnits());
    }
    fn resize(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) bool {
        return false;
    }
    fn remap(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) ?[*]u8 {
        return null;
    }
    fn free(ctx: *anyopaque, bytes: []u8, alignment: std.mem.Alignment, _: usize) void {
        const self: *Memory = @ptrCast(@alignCast(ctx));
        self.release(self.user, bytes.ptr, bytes.len, alignment.toByteUnits());
    }
};
/// Explicitly release a slice returned by a helper with the same allocator.
pub fn freeBytes(allocator: std.mem.Allocator, bytes: []u8) void {
    allocator.free(bytes);
}

/// Concrete clients for the public color/JPEG specializations. Foreign
/// consumers never need to invent the private Zig client layout.
pub fn colorClient(raw: *const r4os.abi.R4XStartContext) !@import("r4gfx_binding").ColorV1Client {
    return @import("r4gfx_binding").ColorV1Client.init(raw);
}
pub fn colorClient2(raw: *const r4os.platform2.abi.R4XStartContext2) !@import("r4gfx_binding").ColorV1Client {
    return @import("r4gfx_binding").ColorV1Client.init2(raw);
}
pub fn videoClient(raw: *const r4os.abi.R4XStartContext) !@import("../../R4VIDEO/Bindings/Zig/r4video.zig").VideoV1Client {
    return @import("../../R4VIDEO/Bindings/Zig/r4video.zig").VideoV1Client.init(raw);
}

pub fn deviceClient(raw: *const r4os.abi.R4XStartContext) !@import("r4gfx_binding").DeviceV1Client {
    return @import("r4gfx_binding").DeviceV1Client.init(raw);
}
pub fn deviceClient2(raw: *const r4os.platform2.abi.R4XStartContext2) !@import("r4gfx_binding").DeviceV1Client {
    return @import("r4gfx_binding").DeviceV1Client.init2(raw);
}
pub fn renderClient(raw: *const r4os.abi.R4XStartContext) !@import("r4gfx_binding").RenderV1Client {
    return @import("r4gfx_binding").RenderV1Client.init(raw);
}
pub fn graphicsClient(raw: *const r4os.abi.R4XStartContext) !@import("r4gfx_binding").ApiV1Client {
    return @import("r4gfx_binding").ApiV1Client.init(raw);
}
pub fn encoderClient(raw: *const r4os.abi.R4XStartContext) !@import("../../R4ENC/Bindings/Zig/r4enc.zig").EncodeV1Client {
    return @import("../../R4ENC/Bindings/Zig/r4enc.zig").EncodeV1Client.init(raw);
}
pub fn acoClient(raw: *const r4os.abi.R4XStartContext) !@import("r4aco").CompilerV1Client {
    return @import("r4aco").CompilerV1Client.init(raw);
}
pub fn nakClient(raw: *const r4os.abi.R4XStartContext) !@import("r4nak").CompilerV1Client {
    return @import("r4nak").CompilerV1Client.init(raw);
}

/// Initialize at the final address before deriving contexts or starting a
/// worker; retain the exact application for every derived native loan.
pub fn application(output: *r4os.App, raw: *const r4os.abi.R4XStartContext, profile: r4os.AppProfile) i32 {
    return switch (r4os.App.init(raw, profile)) {
        .value => |value| blk: {
            output.* = value;
            break :blk 0;
        },
        .failure => |failure| failure.raw_code,
    };
}
pub fn applicationSystem(app: *const r4os.App) r4os.r4sys.Context {
    return app.system();
}
pub fn applicationDraw(app: *const r4os.App) ?r4os.r4draw.Context {
    return app.drawing();
}
pub fn application2(output: *r4os.App2, raw: *const r4os.platform2.abi.R4XStartContext2, profile: r4os.AppProfile) i32 {
    return switch (r4os.App2.init(raw, profile)) {
        .value => |value| blk: {
            output.* = value;
            break :blk 0;
        },
        .failure => |failure| failure.raw_code,
    };
}
pub fn applicationSystem2(app: *const r4os.App2) r4os.r4sys.Context {
    return app.system();
}
pub fn applicationDraw2(app: *const r4os.App2) ?r4os.r4draw.Context {
    return app.drawing();
}
