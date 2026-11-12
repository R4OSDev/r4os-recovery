// Generated from API/Generation2.json and canonical technical ABI types. DO NOT EDIT.
const std = @import("std");
const base = @import("abi.zig");
pub const driver_api2_magic: u32 = 843665476;
pub const driver_api2_version: u32 = 1 + base.driver_api_version - 39;
pub const protocol_api2_magic: u32 = 843665488;
pub const protocol_api2_version: u32 = 1 + base.protocol_api_version - 1;
pub const audio_backend2_magic: u32 = 843208001;
pub const audio_backend2_version: u32 = 3;
const driver_drops = [_][]const u8{"register_audio_backend","register_synth_engine",};
const status_drops = [_][]const u8{"last_write_ticks","max_write_ticks","total_write_ticks","last_refill_ticks","max_refill_ticks","total_refill_ticks",};

fn compact(comptime Source: type, comptime drops: []const []const u8) type {
    const fields = @typeInfo(Source).@"struct".fields;
    var names: [fields.len - drops.len][:0]const u8 = undefined;
    var types: [names.len]type = undefined;
    var attributes: [names.len]std.builtin.Type.StructField.Attributes = undefined;
    var count: usize = 0;
    for (fields) |field| {
        var drop = false;
        for (drops) |name| if (std.mem.eql(u8, field.name, name)) {
            drop = true;
        };
        if (drop) continue;
        names[count] = field.name;
        types[count] = if (Source == base.DriverApi and std.mem.eql(u8, field.name, "register_audio_output_backend")) AudioBackendRegisterFn2 else field.type;
        attributes[count] = .{ .default_value_ptr = field.default_value_ptr, .@"align" = field.alignment };
        count += 1;
    }
    if (count != names.len) @compileError("Generation2 technical removal set drift");
    return @Struct(.@"extern", null, &names, &types, &attributes);
}

pub const AudioBackendStatus2 = compact(base.AudioBackendStatus, &status_drops);
pub const AudioBackendStatusFn2 = *const fn (?*anyopaque, *AudioBackendStatus2) callconv(.c) i32;
pub const AudioBackendRegisterFn2 = *const fn ([*:0]const u8, *const AudioBackend2) callconv(.c) i32;

// Independent magic precedes version: old descriptor versions2/3/4/5 can
// never interpret this record or its smaller status callback by accident.
pub const AudioBackend2 = extern struct {
    magic: u32 = audio_backend2_magic,
    version: u32 = audio_backend2_version,
    size: u32 = @sizeOf(AudioBackend2),
    flags: u32 = 0,
    formats: u32 = base.audio_backend_format_s16le,
    min_rate: u32 = 0,
    max_rate: u32 = 0,
    preferred_rate: u32 = 48000,
    max_channels: u16 = 2,
    reserved: u16 = 0,
    context: ?*anyopaque = null,
    write_pcm: @FieldType(base.AudioBackend, "write_pcm") = null,
    stop: @FieldType(base.AudioBackend, "stop") = null,
    shutdown: @FieldType(base.AudioBackend, "shutdown") = null,
    status: ?AudioBackendStatusFn2 = null,
    output_query: ?@FieldType(base.AudioOutputExtension, "query") = null,
    output_select: ?@FieldType(base.AudioOutputExtension, "select") = null,
    output_active: ?@FieldType(base.AudioOutputExtension, "active") = null,
    idle: @FieldType(base.AudioBackend, "stop") = null,
    write_tracked: ?*const fn (?*anyopaque, [*]const u8, u32, u32, u16, u16, *base.AudioBackendWriteReceipt) callconv(.c) i32 = null,
    playback: ?*const fn (?*anyopaque, *base.AudioBackendPlayback) callconv(.c) i32 = null,
    flow: ?*const fn (?*anyopaque, *const base.AudioBackendFlow) callconv(.c) i32 = null,
};
// Separate immutable input extension: no existing AudioBackend2 field grows.
// Its original R4D registration retains descriptor/code/context until genuine
// capture shutdown ACK; no request or service queue pointer survives IO.
pub const AudioCaptureBackend2 = extern struct {
    magic: u32 = base.audio_capture_backend_magic,
    version: u32 = 1,
    size: u32 = @sizeOf(AudioCaptureBackend2),
    flags: u32 = 0,
    context: ?*anyopaque = null,
    io: ?*const fn (?*anyopaque, *const base.AudioCaptureRequest, *base.AudioCaptureReply, [*]u8, u32) callconv(.c) i32 = null,
    shutdown: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
};
pub const AudioCaptureRegisterFn2 = *const fn ([*:0]const u8, *const AudioCaptureBackend2) callconv(.c) i32;
fn extendDriver() type {
    const Prefix = compact(base.DriverApi, &driver_drops);
    const fields = @typeInfo(Prefix).@"struct".fields;
    var names: [fields.len + 1][:0]const u8 = undefined;
    var types: [names.len]type = undefined;
    var attributes: [names.len]std.builtin.Type.StructField.Attributes = undefined;
    for (fields, 0..) |field, i| {
        names[i] = field.name;
        types[i] = field.type;
        attributes[i] = .{ .default_value_ptr = field.default_value_ptr, .@"align" = field.alignment };
    }
    const missing: ?AudioCaptureRegisterFn2 = null;
    names[fields.len] = "register_audio_capture_backend";
    types[fields.len] = @TypeOf(missing);
    attributes[fields.len] = .{ .default_value_ptr = @ptrCast(&missing) };
    return @Struct(.@"extern", null, &names, &types, &attributes);
}
pub const DriverApi2 = extendDriver();
// Append only in the independent generation2 namespace. The complete legacy
// ProtocolApi120 and every earlier ProtocolApi2 field retain their offsets.
fn extendProtocol() type {
    const fields = @typeInfo(base.ProtocolApi).@"struct".fields;
    var names: [fields.len + 3][:0]const u8 = undefined;
    var types: [names.len]type = undefined;
    var attributes: [names.len]std.builtin.Type.StructField.Attributes = undefined;
    for (fields, 0..) |field, i| {
        names[i] = field.name;
        types[i] = field.type;
        attributes[i] = .{ .default_value_ptr = field.default_value_ptr, .@"align" = field.alignment };
    }
    const no_dispatch: ?base.R4DevFns.protocol_dispatch = null;
    const LinkIo = *const fn (*const base.NetworkLinkRequest, *base.NetworkLinkInfo) callconv(.c) i32;
    const no_link: ?LinkIo = null;
    const no_poll: ?base.R4SysFns.program_handle_status = null;
    names[fields.len] = "protocol_dispatch";
    types[fields.len] = @TypeOf(no_dispatch);
    attributes[fields.len] = .{ .default_value_ptr = @ptrCast(&no_dispatch) };
    names[fields.len + 1] = "link_io";
    types[fields.len + 1] = @TypeOf(no_link);
    attributes[fields.len + 1] = .{ .default_value_ptr = @ptrCast(&no_link) };
    names[fields.len + 2] = "process_status";
    types[fields.len + 2] = @TypeOf(no_poll);
    attributes[fields.len + 2] = .{ .default_value_ptr = @ptrCast(&no_poll) };
    return @Struct(.@"extern", null, &names, &types, &attributes);
}
pub const ProtocolApi2 = extendProtocol();

comptime {
    if (@sizeOf(DriverApi2) != @sizeOf(base.DriverApi) - 8 or @offsetOf(DriverApi2, "register_audio_capture_backend") != @sizeOf(base.DriverApi) - 16 or @sizeOf(ProtocolApi2) != @sizeOf(base.ProtocolApi) + 24) @compileError("Generation2 technical tables");
    if (@offsetOf(ProtocolApi2, "protocol_dispatch") != 120 or @offsetOf(ProtocolApi2, "link_io") != 128 or @offsetOf(ProtocolApi2, "process_status") != 136 or @offsetOf(ProtocolApi2, "entropy_fill") != 112) @compileError("Generation2 protocol prefix drift");
    if (@hasField(DriverApi2, "register_audio_backend") or @hasField(DriverApi2, "register_synth_engine")) @compileError("Generation2 retired registration");
    if (@sizeOf(AudioBackendStatus2) != 80 or @sizeOf(AudioBackend2) != 136 or @offsetOf(AudioBackend2, "status") != 72) @compileError("Generation2 audio layout");
}
