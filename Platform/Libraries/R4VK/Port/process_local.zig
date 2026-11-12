// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// R4VK's private C names delegate to the shared native process owner.
const local = @import("r4native").process_local;
pub const lookup = local.lookup;
pub const getOrCreate = local.getOrCreate;

pub export fn r4vk_state_ensure(key: *const anyopaque, bytes: usize, alignment: usize) callconv(.c) bool {
    return local.ensureBlob(key, bytes, alignment);
}
pub export fn r4vk_state_get(key: *const anyopaque) callconv(.c) ?*anyopaque {
    return local.getBlob(key);
}
