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

// This is a value projection by canonical field name. An old table pointer
// is never reinterpreted as a compact new table. Missing provider slots stay
// zero; a newer schema/header does not fabricate a capability.
fn project(comptime T: type, source: anytype) T {
    var value: T = .{};
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime @offsetOf(T, field.name) >= 16 and @hasField(@TypeOf(source), field.name))
            @field(value, field.name) = @field(source, field.name);
    }
    return value;
}

pub fn configure(s: anytype, d: anytype, r: anytype, n: anytype, a: anytype, v: anytype) void {
    sys = project(abi.R4XStartR4Sys2, s);
    desk = project(abi.R4XStartR4Desk2, d);
    draw = project(abi.R4XStartR4Draw2, r);
    net = project(abi.R4XStartR4Net2, n);
    audio = project(abi.R4XStartR4Audio2, a);
    dev = project(abi.R4XStartR4Dev2, v);
    const system = @import("r4sys.zig");
    sys.file_metadata2 = @intFromPtr(@as(abi.R4SysFns2.file_metadata2, &system.fileMetadata2));
    sys.directory_metadata_batch2 = @intFromPtr(@as(abi.R4SysFns2.directory_metadata_batch2, &system.directoryMetadataBatch2));
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
