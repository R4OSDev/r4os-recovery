//! Concrete adapters for the existing web owners. No engine or policy lives here.
const std = @import("std");
const cb = @import("web_callback_bridge.zig");
const font = @import("web_font.zig");
const layout = @import("web_layout.zig");
const js = @import("javascript.zig");
const runtime = @import("web_runtime.zig");
const canvas = @import("web_canvas.zig");
pub const Error = error{MissingCallback};

fn make(comptime T: type, table: *const cb.Table, comptime mappings: anytype) Error!T {
    var value: T = undefined;
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime std.mem.eql(u8, field.name, "context")) {
            @field(value, field.name) = @ptrCast(@constCast(table));
        } else {
            const selected: ?usize = comptime blk: {
                for (mappings, 0..) |mapping, i| if (std.mem.eql(u8, field.name, mapping[0])) break :blk i;
                break :blk null;
            };
            if (comptime selected != null) {
                const mapping = mappings[selected.?];
                const optional = @typeInfo(field.type) == .optional;
                const Pointer = if (optional) @typeInfo(field.type).optional.child else field.type;
                @field(value, field.name) = if (table.has(mapping[1])) cb.pointer(Pointer, mapping[2], mapping[1]) else if (optional) null else return error.MissingCallback;
            } else {
                const ptr: *const field.type = @ptrCast(@alignCast(field.default_value_ptr orelse @compileError("unmapped required web field " ++ field.name)));
                @field(value, field.name) = ptr.*;
            }
        }
    }
    return value;
}
pub fn glyphSupport(table: *const cb.Table) font.GlyphSupport {
    return make(font.GlyphSupport, table, .{.{ "callback", cb.Kind.glyph_support, 0 }}) catch unreachable;
}
pub fn fontProvider(table: *const cb.Table) layout.FontProvider {
    return make(layout.FontProvider, table, .{ .{ "resolve", cb.Kind.font_resolve, 0 }, .{ "measure", cb.Kind.font_measure, 0 } }) catch unreachable;
}
pub fn runResolver(table: *const cb.Table, family: []const u8, size: i32, weight: u16, italic: bool) Error!font.RunResolver(layout.FontFace) {
    if (!table.has(.font_resolve)) return error.MissingCallback;
    return .{ .context = @ptrCast(@constCast(table)), .callback = cb.pointer(@typeInfo(@FieldType(layout.FontProvider, "resolve")).optional.child, 0, .font_resolve), .family = family, .size = size, .weight = weight, .italic = italic };
}
pub fn imageResolver(table: *const cb.Table) layout.ImageResolver {
    return make(layout.ImageResolver, table, .{ .{ "resolve", cb.Kind.image_resolve, 0 }, .{ "resolve_role", cb.Kind.image_resolve_role, 0 } }) catch unreachable;
}
pub fn fontCatalog(table: *const cb.Table) Error!font.CatalogReader {
    return make(font.CatalogReader, table, .{ .{ "revision", cb.Kind.catalog_revision, 0 }, .{ "count", cb.Kind.catalog_count, 0 }, .{ "info", cb.Kind.catalog_info, 0 } });
}
pub fn stop(table: *const cb.Table, interval: usize) js.Stop {
    var value = make(js.Stop, table, .{.{ "requested", cb.Kind.js_cancel, 0 }}) catch unreachable;
    value.check_interval = interval;
    return value;
}
pub fn clock(table: *const cb.Table) js.ClockSource {
    return make(js.ClockSource, table, .{ .{ "now_milliseconds", cb.Kind.js_clock, 0 }, .{ "offset_minutes", cb.Kind.js_offset, 0 } }) catch unreachable;
}
pub fn rejectionTracker(table: *const cb.Table) js.PromiseRejectionTracker {
    return make(js.PromiseRejectionTracker, table, .{.{ "track", cb.Kind.promise_rejection, 1 }}) catch unreachable;
}
pub fn rootMarker(table: *const cb.Table) js.ExternalRootMarker {
    return make(js.ExternalRootMarker, table, .{ .{ "mark", cb.Kind.root_mark, 1 }, .{ "mark_weak", cb.Kind.root_mark_weak, 1 }, .{ "sweep", cb.Kind.root_sweep, 1 } }) catch unreachable;
}
pub fn programAllocator(table: *const cb.Table) Error!js.ProgramAllocator {
    return make(js.ProgramAllocator, table, .{ .{ "create", cb.Kind.program_create, 0 }, .{ "destroy", cb.Kind.program_destroy, 0 }, .{ "allocate", cb.Kind.program_allocate, 0 }, .{ "free", cb.Kind.program_free, 0 } });
}
pub fn canvasAllocator(table: *const cb.Table) Error!canvas.Allocator {
    return make(canvas.Allocator, table, .{ .{ "allocate", cb.Kind.canvas_allocate, 0 }, .{ "free", cb.Kind.canvas_free, 0 } });
}
pub fn resourceHandler(table: *const cb.Table) runtime.ResourceHandler {
    return make(runtime.ResourceHandler, table, .{.{ "complete", cb.Kind.resource_complete, 0 }}) catch unreachable;
}
pub fn fontSourceHandler(table: *const cb.Table) runtime.FontSourceHandler {
    return make(runtime.FontSourceHandler, table, .{ .{ "local_available", cb.Kind.font_local, 0 }, .{ "cached_available", cb.Kind.font_cached, 0 } }) catch unreachable;
}
pub fn resourceObserver(table: *const cb.Table) runtime.ResourceObserver {
    return make(runtime.ResourceObserver, table, .{.{ "report", cb.Kind.resource_report, 0 }}) catch unreachable;
}
pub fn frameLookup(table: *const cb.Table) runtime.FrameLookup {
    return make(runtime.FrameLookup, table, .{.{ "inspect", cb.Kind.frame_lookup, 0 }}) catch unreachable;
}
pub fn scriptObserver(table: *const cb.Table) runtime.ScriptObserver {
    return make(runtime.ScriptObserver, table, .{.{ "report", cb.Kind.script_report, 0 }}) catch unreachable;
}
pub fn monotonicClock(table: *const cb.Table) runtime.MonotonicClock {
    return make(runtime.MonotonicClock, table, .{.{ "now_milliseconds", cb.Kind.monotonic_clock, 0 }}) catch unreachable;
}
pub fn hostFunction() js.HostFunction {
    return cb.pointer(js.HostFunction, 1, .js_host_function);
}
pub fn hostGet() js.HostPropertyGet {
    return cb.pointer(js.HostPropertyGet, 1, .js_host_get);
}
pub fn hostSet() js.HostPropertySet {
    return cb.pointer(js.HostPropertySet, 1, .js_host_set);
}
pub fn callbackContext(table: *const cb.Table) *anyopaque {
    return @ptrCast(@constCast(table));
}

/// A stable borrowed allocator adapter, also usable with the data boundary's
/// original FixedBufferAllocator. Keep it and its backing alive through all
/// programs, canvas surfaces, and their exact destroy/free acknowledgements.
pub const Memory = struct { allocator: std.mem.Allocator };
pub fn memory(output: *Memory, allocator: std.mem.Allocator) void {
    output.* = .{ .allocator = allocator };
}
fn createProgram(ctx: *anyopaque) ?*js.Program {
    const self: *Memory = @ptrCast(@alignCast(ctx));
    const program = self.allocator.create(js.Program) catch return null;
    program.* = .{};
    return program;
}
fn destroyProgram(ctx: *anyopaque, program: *js.Program) void {
    const self: *Memory = @ptrCast(@alignCast(ctx));
    self.allocator.destroy(program);
}
fn allocate(ctx: *anyopaque, len: usize, alignment: usize) ?[*]u8 {
    const self: *Memory = @ptrCast(@alignCast(ctx));
    if (!std.math.isPowerOfTwo(alignment)) return null;
    return self.allocator.rawAlloc(len, .fromByteUnits(alignment), @returnAddress());
}
fn free(ctx: *anyopaque, ptr: [*]u8, len: usize, alignment: usize) void {
    const self: *Memory = @ptrCast(@alignCast(ctx));
    self.allocator.rawFree(ptr[0..len], .fromByteUnits(alignment), @returnAddress());
}
pub fn memoryPrograms(self: *Memory) js.ProgramAllocator {
    return .{ .context = self, .create = createProgram, .destroy = destroyProgram, .allocate = allocate, .free = free };
}
pub fn memoryCanvas(self: *Memory) canvas.Allocator {
    return .{ .context = self, .allocate = allocate, .free = free };
}
