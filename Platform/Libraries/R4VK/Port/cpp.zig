// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// The same native process/thread owners used by the other C++ providers.
// Emulated TLS control words in the shared library remain immutable.
const native = @import("r4native");
const compiler = @import("compiler.zig");
const finalizers = native.finalizers.Runtime(native.memory.Runtime(native.memory.Unscoped));
pub export fn __emutls_get_address(control: *const native.thread_local.Control) callconv(.c) *anyopaque {
    return native.thread_local.getAddress(control) orelse compiler.r4vk_compiler_fail(1);
}
pub export fn r4native_cpp_state(key: *const anyopaque, bytes: usize, alignment: usize, callback: native.process_local.Initializer) callconv(.c) ?*anyopaque {
    return native.process_local.initializedBlob(key, bytes, alignment, callback);
}
pub export fn r4native_register_finalizer(callback: finalizers.PlainCallback) callconv(.c) c_int {
    return if (finalizers.registerPlain(callback)) 0 else -1;
}
pub export fn r4native_fatal(_: [*:0]const u8) callconv(.c) noreturn {
    compiler.r4vk_compiler_fail(3);
}
