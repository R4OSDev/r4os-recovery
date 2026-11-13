//! Recovery's own provider construction. Layouts and identities come only
//! from the pinned canonical Contract; both transition generations share
//! the existing mechanism/owner callbacks and retirement paths.
const std = @import("std");
pub const abi = @import("r4os_contract2");

pub var sys: abi.R4XStartR4Sys2 = .{};
pub var desk: abi.R4XStartR4Desk2 = .{};
pub var draw: abi.R4XStartR4Draw2 = .{};
pub var net: abi.R4XStartR4Net2 = .{};
pub var audio: abi.R4XStartR4Audio2 = .{};
pub var dev: abi.R4XStartR4Dev2 = .{};

// Only callback addresses and the current canonical header are published.
// Missing owner mechanisms remain absent. Structural checks retain the exact
// C ABI of legitimate Recovery-private shared payload names.
pub fn buildGroup(comptime Table: type, comptime Namespace: type, functions: anytype) Table {
    @setEvalBranchQuota(2_000_000);
    var result: Table = .{};
    inline for (std.meta.fields(@TypeOf(functions))) |field| {
        if (!@hasField(Table, field.name) or !@hasDecl(Namespace, field.name)) @compileError("Unknown current Recovery callback: " ++ field.name);
        const Function = @field(Namespace, field.name);
        @field(result, field.name) = @intFromPtr(callback(Function, @field(functions, field.name)));
    }
    return result;
}

pub fn group(id: u32) ?u64 {
    return switch (id) {
        1 => @intFromPtr(&sys),
        2 => @intFromPtr(&desk),
        3 => @intFromPtr(&draw),
        4 => @intFromPtr(&net),
        5 => @intFromPtr(&audio),
        6 => @intFromPtr(&dev),
        else => null,
    };
}

/// Explicit ABI check for the older Recovery-private technical descriptor
/// names. Pointer/callback casts below are permitted only when their entire
/// structural C ABI is equal. A changed descriptor needs its own adapter.
pub fn sameAbi(comptime A: type, comptime B: type) bool {
    if (A == B) return true;
    if (std.meta.activeTag(@typeInfo(A)) != std.meta.activeTag(@typeInfo(B))) return false;
    return switch (@typeInfo(A)) {
        .void, .noreturn, .bool => true,
        .int => |a| a.bits == @typeInfo(B).int.bits and a.signedness == @typeInfo(B).int.signedness,
        .float => |a| a.bits == @typeInfo(B).float.bits,
        .@"enum" => |a| sameAbi(a.tag_type, @typeInfo(B).@"enum".tag_type),
        .optional => |a| sameAbi(a.child, @typeInfo(B).optional.child),
        .pointer => |a| blk: {
            const other = @typeInfo(B).pointer;
            if (a.size != other.size or a.is_const != other.is_const or a.is_allowzero != other.is_allowzero or a.alignment != other.alignment) break :blk false;
            break :blk sameAbi(a.child, other.child);
        },
        .array => |a| a.len == @typeInfo(B).array.len and sameAbi(a.child, @typeInfo(B).array.child),
        .@"struct" => |a| blk: {
            const other = @typeInfo(B).@"struct";
            if (@sizeOf(A) != @sizeOf(B) or @alignOf(A) != @alignOf(B) or a.fields.len != other.fields.len or a.layout != other.layout) break :blk false;
            for (a.fields, other.fields) |left, right| {
                if (!std.mem.eql(u8, left.name, right.name) or @offsetOf(A, left.name) != @offsetOf(B, right.name) or !sameAbi(left.type, right.type)) break :blk false;
            }
            break :blk true;
        },
        .@"fn" => |a| blk: {
            const other = @typeInfo(B).@"fn";
            if (a.params.len != other.params.len or !std.meta.eql(a.calling_convention, other.calling_convention) or a.is_var_args != other.is_var_args or !sameAbi(a.return_type.?, other.return_type.?)) break :blk false;
            for (a.params, other.params) |left, right| if (!sameAbi(left.type.?, right.type.?)) break :blk false;
            break :blk true;
        },
        .@"opaque" => false,
        else => false,
    };
}

pub fn callback(comptime T: type, value: anytype) T {
    const Pointer = if (@typeInfo(T) == .optional) @typeInfo(T).optional.child else T;
    comptime {
        @setEvalBranchQuota(500_000);
        if (!sameAbi(Pointer, @TypeOf(value))) @compileError("Recovery callback ABI requires an explicit adapter: " ++ @typeName(@TypeOf(value)) ++ " -> " ++ @typeName(Pointer));
    }
    const result: Pointer = @ptrCast(value);
    return result;
}
