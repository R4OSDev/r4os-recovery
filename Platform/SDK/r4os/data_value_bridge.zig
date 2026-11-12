//! SDK-local scalar data transport. The compiler selects the
//! original owner function and native types. Private values remain opaque.
const std = @import("std");
const schema = @import("data_bridge_schema.zig");
const core = @import("native_value_bridge.zig");
const bridge = core.Engine(schema);
pub const Slot = core.Slot;
comptime {
    if (@import("generated/data_fingerprint.zig").fingerprint != schema.fingerprint) @compileError("Data helper boundary drift: regenerate before compiling consumers");
}
pub export fn R4SdkDataVerifyAbi(fingerprint: u64) callconv(.c) i32 {
    return if (fingerprint == schema.fingerprint) 0 else schema.abi.io_error_invalid;
}
pub export fn R4SdkDataInvoke(fingerprint: u64, operation: u32, values: ?[*]const Slot, count: u32, output: ?*anyopaque) callconv(.c) Slot {
    return bridge.invoke(fingerprint, operation, values, count, output);
}
pub export fn R4SdkDataConstruct(fingerprint: u64, type_id: u32, values: ?[*]const Slot, count: u32, output: ?*anyopaque) callconv(.c) Slot {
    return bridge.construct(fingerprint, type_id, values, count, output);
}
pub export fn R4SdkDataInspect(fingerprint: u64, type_id: u32, source: ?*anyopaque, output: ?*anyopaque) callconv(.c) Slot {
    return bridge.inspect(fingerprint, type_id, source, output);
}
pub export fn R4SdkDataField(fingerprint: u64, type_id: u32, field_index: u32, source: ?*anyopaque, update: ?*const Slot, output: ?*anyopaque) callconv(.c) Slot {
    return bridge.fieldAccess(fingerprint, type_id, field_index, source, update, output);
}
