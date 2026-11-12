// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Canonical native C math is compiled into each consuming library.
const native = @import("r4native").math;
pub const llroundf = native.llroundf;
pub const llround = native.llround;
pub const lroundf = native.lroundf;
pub const lround = native.lround;
pub const lrintf = native.lrintf;
pub const lrint = native.lrint;
pub const copysignf = native.copysignf;
pub const copysign = native.copysign;
pub const frexpf = native.frexpf;
pub const frexp = native.frexp;
comptime { _ = native; }
