const std = @import("std");
const r4os = @import("r4os");
const runtime = @import("runtime.zig");
const abi = runtime.abi;

pub const name = "R4STD";
pub const import_config_v1 = "R4STD:CONFIG_V1:1";
pub const max_path_len: usize = r4os.path.file_path_max;
pub const max_file_bytes: usize = abi.max_file_bytes;
pub const max_output_bytes: usize = abi.max_output_bytes;

pub const result_ok: i32 = abi.config_result_ok;
pub const result_defaulted: i32 = abi.config_result_defaulted;
pub const result_created: i32 = abi.config_result_created;
pub const result_recovered: i32 = abi.config_result_recovered;
pub const error_invalid_path: i32 = abi.config_error_invalid_path;
pub const error_invalid_key: i32 = abi.config_error_invalid_key;
pub const error_buffer_too_small: i32 = abi.config_error_buffer_too_small;
pub const error_write_failed: i32 = abi.config_error_write_failed;
pub const error_rename_failed: i32 = abi.config_error_rename_failed;
pub const error_invalid_value: i32 = abi.config_error_invalid_value;
pub const error_verify_failed: i32 = abi.config_error_verify_failed;
pub const error_recovery_failed: i32 = abi.config_error_recovery_failed;
pub const error_read_failed: i32 = abi.config_error_read_failed;

pub fn ok(result: i32) bool {
    return result >= 0;
}

pub fn parseFilePath(bytes: []const u8) r4os.path.Error!r4os.path.FilePath {
    return r4os.path.FilePath.parse(bytes);
}

pub fn parseAbsoluteFilePath(bytes: []const u8) r4os.path.Error!r4os.path.AbsoluteFilePath {
    return r4os.path.AbsoluteFilePath.parse(bytes);
}

pub fn parseRelativeFilePath(bytes: []const u8) r4os.path.Error!r4os.path.RelativeFilePath {
    return r4os.path.RelativeFilePath.parse(bytes);
}

pub fn parseRegistryPath(bytes: []const u8) r4os.path.Error!r4os.path.RegistryPath {
    return r4os.path.RegistryPath.parse(bytes);
}

pub fn pathsEqualIgnoreCase(left: []const u8, right: []const u8) bool {
    return r4os.path.equalsIgnoreCase(left, right);
}

pub fn readString(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: []const u8, out: []u8) i32 {
    _ = ctx;
    var scalar: u64 = 0;
    return read(std.mem.span(path), key, abi.config_kind_string, fallback, 0, out, &scalar);
}

pub fn readBool(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: bool, out: *bool) i32 {
    _ = ctx;
    var scalar: u64 = 0;
    const result = read(std.mem.span(path), key, abi.config_kind_bool, "", @intFromBool(fallback), emptyOutput(), &scalar);
    out.* = scalar != 0;
    return result;
}

pub fn readU32(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: u32, out: *u32) i32 {
    _ = ctx;
    var scalar: u64 = 0;
    const result = read(std.mem.span(path), key, abi.config_kind_u32, "", fallback, emptyOutput(), &scalar);
    out.* = std.math.cast(u32, scalar) orelse fallback;
    return result;
}

pub fn readI32(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: i32, out: *i32) i32 {
    _ = ctx;
    var scalar: u64 = 0;
    const result = read(std.mem.span(path), key, abi.config_kind_i32, "", fallback, emptyOutput(), &scalar);
    out.* = @bitCast(std.math.cast(u32, scalar) orelse @as(u32, @bitCast(fallback)));
    return result;
}

pub fn readRgb24(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: u32, out: *u32) i32 {
    _ = ctx;
    var scalar: u64 = 0;
    const result = read(std.mem.span(path), key, abi.config_kind_rgb24, "", fallback, emptyOutput(), &scalar);
    out.* = std.math.cast(u32, scalar) orelse fallback;
    return result;
}

pub fn writeString(ctx: anytype, path: [*:0]const u8, key: []const u8, value: []const u8) i32 {
    _ = ctx;
    return write(std.mem.span(path), key, abi.config_kind_string, value, 0);
}

pub fn writeBool(ctx: anytype, path: [*:0]const u8, key: []const u8, value: bool) i32 {
    _ = ctx;
    return write(std.mem.span(path), key, abi.config_kind_bool, "", @intFromBool(value));
}

pub fn writeU32(ctx: anytype, path: [*:0]const u8, key: []const u8, value: u32) i32 {
    _ = ctx;
    return write(std.mem.span(path), key, abi.config_kind_u32, "", value);
}

pub fn writeI32(ctx: anytype, path: [*:0]const u8, key: []const u8, value: i32) i32 {
    _ = ctx;
    return write(std.mem.span(path), key, abi.config_kind_i32, "", value);
}

pub fn writeRgb24(ctx: anytype, path: [*:0]const u8, key: []const u8, value: u32) i32 {
    _ = ctx;
    return write(std.mem.span(path), key, abi.config_kind_rgb24, "", value);
}

pub fn saveDocument(ctx: anytype, path: [*:0]const u8, bytes: []const u8) i32 {
    _ = ctx;
    if (!runtime.hasConfig()) return abi.status_unavailable;
    const path_bytes = std.mem.span(path);
    return runtime.config().save_document(runtime.rawAddress(), path_bytes.ptr, path_bytes.len, bytes.ptr, bytes.len);
}

pub fn recoverDocumentSave(ctx: anytype, path: [*:0]const u8) i32 {
    _ = ctx;
    if (!runtime.hasConfig()) return abi.status_unavailable;
    const path_bytes = std.mem.span(path);
    return runtime.config().recover_document(runtime.rawAddress(), path_bytes.ptr, path_bytes.len);
}

pub fn hasDocumentSaveLeftovers(ctx: anytype, path: [*:0]const u8) bool {
    _ = ctx;
    if (!runtime.hasConfig()) return true;
    const path_bytes = std.mem.span(path);
    return runtime.config().has_leftovers(runtime.rawAddress(), path_bytes.ptr, path_bytes.len) != 0;
}

fn read(path: []const u8, key: []const u8, kind: u32, fallback: []const u8, fallback_scalar: i64, out: []u8, scalar: *u64) i32 {
    if (!runtime.hasConfig()) return abi.status_unavailable;
    return runtime.config().read(
        runtime.rawAddress(),
        path.ptr,
        path.len,
        key.ptr,
        key.len,
        kind,
        fallback.ptr,
        fallback.len,
        fallback_scalar,
        out.ptr,
        out.len,
        scalar,
    );
}

fn write(path: []const u8, key: []const u8, kind: u32, value: []const u8, scalar: i64) i32 {
    if (!runtime.hasConfig()) return abi.status_unavailable;
    return runtime.config().write(runtime.rawAddress(), path.ptr, path.len, key.ptr, key.len, kind, value.ptr, value.len, scalar);
}

fn emptyOutput() []u8 {
    const Empty = struct {
        var byte: u8 = 0;
    };
    return @as([*]u8, @ptrCast(&Empty.byte))[0..0];
}
