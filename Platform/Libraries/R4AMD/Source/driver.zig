// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! The same CPU providers linked into AMDGPU's SIMD-capable driver worker.
pub const c = @import("r4amd");
pub const render = @import("render_impl.zig").Provider(c);
pub const images = @import("images_impl.zig").Provider(c);
pub const batch = @import("render_batch.zig").Provider(c, @import("r4os").abi);
pub const yuv = @import("render_yuv.zig").Provider(c, @import("r4os").abi);

pub const media = @import("media.zig");
