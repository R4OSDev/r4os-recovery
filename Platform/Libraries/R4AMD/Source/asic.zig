// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Paired ASIC identities for pure encoders. Hardware admission belongs to R4D.
pub fn Profiles(comptime c: type) type {
    return struct {
        pub const Family = enum { picasso, raven2 };
        pub fn engines(device: u32, gc: u32, sdma: u32) ?Family {
            if (device != 0x15d8) return null;
            if (gc == c.gc_9_1_0 and sdma == c.sdma_4_1_0) return .picasso;
            if (gc == c.gc_9_2_2 and sdma == c.sdma_4_1_1) return .raven2;
            return null;
        }
        pub fn image(device: u32, gc: u32, revision: u32) ?Family {
            if (device != 0x15d8) return null;
            if (gc == c.gc_9_1_0 and revision >= 0x41 and revision <= 0x48) return .picasso;
            if (gc == c.gc_9_2_2 and revision >= 0x81 and revision <= 0x88) return .raven2;
            return null;
        }
        pub fn media(device: u32, gc: u32, vcn: u32, firmware: u32) bool {
            if (device != 0x15d8) return false;
            return (gc == c.gc_9_1_0 and vcn == c.vcn_1_0_0 and firmware == c.picasso_vcn_firmware) or
                (gc == c.gc_9_2_2 and vcn == c.vcn_1_0_1 and firmware == c.raven2_vcn_firmware);
        }
        pub fn shaderBase(device: u32, gc: u32, revision: u32) ?usize {
            return switch (image(device, gc, revision) orelse return null) { .picasso => 0, .raven2 => c.shader_raven2_base };
        }
    };
}
