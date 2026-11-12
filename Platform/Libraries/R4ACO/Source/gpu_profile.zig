// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Exact external ASIC revisions; never reuse gfx902 cache entries for gfx909.
pub fn select(device: u32, revision: u32) ?u32 {
    if (device != 0x15d8) return null;
    if (revision >= 0x41 and revision <= 0x48) return 902;
    if (revision >= 0x81 and revision <= 0x88) return 909;
    return null;
}
