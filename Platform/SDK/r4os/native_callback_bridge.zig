//! Shared exact-signature native callback marshalling. Each owner keeps its
//! own descriptor/kind protocol and lifetime rules; no policy is shared here.
const std = @import("std");
const codec = @import("native_value_bridge.zig");
pub const Slot = codec.Slot;
fn base(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .error_union => |e| base(e.payload),
        .optional => |o| base(o.child),
        else => T,
    };
}
fn arg(comptime T: type, value: *const T) Slot {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union", .array, .float => .{ .ptr = @ptrCast(@constCast(value)), .flags = codec.present },
        .optional => |o| if (value.* != null) arg(o.child, &value.*.?) else .{},
        else => codec.store(T, value.*, null) catch @panic("invalid native callback argument"),
    };
}
fn returned(comptime T: type, response: Slot, output: ?*anyopaque) T {
    if (response.status != 0) @panic("native callback transport failure");
    if (comptime @typeInfo(T) == .error_union) {
        const e = @typeInfo(T).error_union;
        if (response.flags & codec.native_error != 0) return (codec.decode(e.error_set, response) catch @panic("invalid callback error name")).value;
        return returned(e.payload, response, output);
    }
    if (response.flags & codec.native_error != 0) @panic("unexpected callback error");
    if (comptime T == void) return {};
    if (comptime @typeInfo(T) == .optional) {
        if (response.flags & codec.present == 0) return null;
        return @as(T, returned(@typeInfo(T).optional.child, response, output));
    }
    if (response.flags & codec.present == 0) @panic("missing callback result");
    if (comptime @typeInfo(T) == .@"struct" or @typeInfo(T) == .@"union" or @typeInfo(T) == .array or @typeInfo(T) == .float) {
        if (response.ptr != output or output == null) @panic("callback must initialize supplied native output");
    }
    return (codec.decode(T, response) catch @panic("invalid callback result")).value;
}
fn dispatch(comptime Table: type, comptime F: type, comptime context_index: usize, comptime kind: anytype, values: std.meta.ArgsTuple(F)) @typeInfo(F).@"fn".return_type.? {
    const meta = @typeInfo(F).@"fn";
    const R = meta.return_type.?;
    const C = @TypeOf(values[context_index]);
    const address = if (comptime @typeInfo(C) == .optional) values[context_index] orelse @panic("missing callback table") else values[context_index];
    const table: *const Table = @ptrCast(@alignCast(address));
    if (!table.has(kind)) @panic("unavailable callback kind");
    var arguments: [meta.params.len]Slot = undefined;
    inline for (meta.params, 0..) |p, i| arguments[i] = arg(p.type.?, &values[i]);
    // The callback sees the actual caller user pointer, never the SDK table.
    arguments[context_index] = .{ .ptr = table.user, .flags = if (table.user != null) codec.present else 0 };
    var storage: base(R) = undefined;
    const output: ?*anyopaque = if (comptime base(R) == void) null else @ptrCast(&storage);
    const response = table.invoke.?(table.user, @intFromEnum(kind), &arguments, arguments.len, output);
    return returned(R, response, output);
}

/// Return an exact original Zig function pointer. Only the inner invocation
/// crosses C, through scalar Slots and pointers (including floating data).
pub fn Adapter(comptime Table: type, comptime Pointer: type, comptime context_index: usize, comptime kind: anytype) type {
    const F = @typeInfo(Pointer).pointer.child;
    const info = @typeInfo(F).@"fn";
    const R = info.return_type.?;
    const P = struct {
        fn at(comptime n: usize) type {
            return info.params[n].type.?;
        }
    };
    return switch (info.params.len) {
        1 => struct {
            pub fn call(a: P.at(0)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{a});
            }
        },
        2 => struct {
            pub fn call(a: P.at(0), b: P.at(1)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{ a, b });
            }
        },
        3 => struct {
            pub fn call(a: P.at(0), b: P.at(1), c: P.at(2)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{ a, b, c });
            }
        },
        4 => struct {
            pub fn call(a: P.at(0), b: P.at(1), c: P.at(2), d: P.at(3)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{ a, b, c, d });
            }
        },
        5 => struct {
            pub fn call(a: P.at(0), b: P.at(1), c: P.at(2), d: P.at(3), e: P.at(4)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{ a, b, c, d, e });
            }
        },
        6 => struct {
            pub fn call(a: P.at(0), b: P.at(1), c: P.at(2), d: P.at(3), e: P.at(4), f: P.at(5)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{ a, b, c, d, e, f });
            }
        },
        7 => struct {
            pub fn call(a: P.at(0), b: P.at(1), c: P.at(2), d: P.at(3), e: P.at(4), f: P.at(5), g: P.at(6)) callconv(info.calling_convention) R {
                return dispatch(Table, F, context_index, kind, .{ a, b, c, d, e, f, g });
            }
        },
        else => @compileError("native callback arity needs an explicit adapter"),
    };
}
pub fn pointer(comptime Table: type, comptime T: type, comptime context_index: usize, comptime kind: anytype) T {
    return &Adapter(Table, T, context_index, kind).call;
}
