// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Public C symbols and isolated-compiler failure policy remain owned by R4VK.
const native = @import("r4native");
const compiler = @import("compiler.zig");
const implementation = native.memory.Runtime(struct {
    pub fn allocationScope() ?*Scope {
        return compiler.allocationScope();
    }
    pub fn allocationFailed() noreturn {
        compiler.r4vk_compiler_fail(2);
    }
});
pub const Scope = implementation.Scope;
pub const mallocUntracked = implementation.mallocUntracked;
pub const stats = implementation.stats;

pub export fn malloc(bytes: usize) callconv(.c) ?*anyopaque {
    return implementation.malloc(bytes);
}
pub export fn free(pointer: ?*anyopaque) callconv(.c) void {
    implementation.free(pointer);
}
pub export fn calloc(count: usize, width: usize) callconv(.c) ?*anyopaque {
    return implementation.calloc(count, width);
}
pub export fn realloc(pointer: ?*anyopaque, bytes: usize) callconv(.c) ?*anyopaque {
    return implementation.realloc(pointer, bytes);
}
pub export fn reallocarray(pointer: ?*anyopaque, count: usize, width: usize) callconv(.c) ?*anyopaque {
    return implementation.reallocarray(pointer, count, width);
}
pub export fn aligned_alloc(alignment: usize, bytes: usize) callconv(.c) ?*anyopaque {
    return implementation.aligned_alloc(alignment, bytes);
}
pub export fn posix_memalign(output: *?*anyopaque, alignment: usize, bytes: usize) callconv(.c) c_int {
    return implementation.posix_memalign(output, alignment, bytes);
}
