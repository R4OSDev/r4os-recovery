//! Transport facts and exact admission arithmetic. A receiver advertisement
//! never grants a source encoder, successful training or physical validation.
//! Field references: NVIDIA570.144 nvtiming.h / NVT_HDMI_FORUM_VSDB_PAYLOAD,
//! nvt_edidext_861.c / parseCta861HdmiForumDataBlock and ctrl0073specific.h.
const std = @import("std");

pub const Error = error{ Descriptor, Unsupported, Bandwidth };
pub const Clock = struct {
    numerator: u64,
    denominator: u32 = 1,

    pub fn valid(self: Clock) bool { return self.numerator != 0 and self.denominator != 0; }
    pub fn ceilHz(self: Clock) Error!u64 {
        if (!self.valid()) return error.Descriptor;
        return @intCast((@as(u128, self.numerator) + self.denominator - 1) / self.denominator);
    }
    /// Exact pixel clock from the NV display clock's optional1000/1001 flag.
    pub fn nvidia(raw: u32) Clock {
        return .{ .numerator = @as(u64, raw & 0x7fffffff) * @as(u64, if (raw >> 31 != 0) 1000 else 1),
            .denominator = if (raw >> 31 != 0) 1001 else 1 };
    }
    pub fn atMost(self: Clock, hz: u64) bool {
        return self.valid() and @as(u128, self.numerator) <= @as(u128, hz) * self.denominator;
    }
};
pub const Demand = struct {
    clock: Clock,
    /// DSC uses fractional bits per pixel. Uncompressed RGB is3*bpc*16.
    bpp_x16: u16,

    pub fn fits(self: Demand, payload_bps: u64) bool {
        return self.clock.valid() and self.bpp_x16 != 0 and payload_bps != 0 and
            @as(u128, self.clock.numerator) * self.bpp_x16 <
            @as(u128, payload_bps) * self.clock.denominator * 16;
    }
    pub fn ceilBitsPerSecond(self: Demand) Error!u64 {
        if (!self.clock.valid() or self.bpp_x16 == 0) return error.Descriptor;
        const denominator: u128 = @as(u128, self.clock.denominator) * 16;
        const value = (@as(u128, self.clock.numerator) * self.bpp_x16 + denominator - 1) / denominator;
        return std.math.cast(u64, value) orelse error.Bandwidth;
    }
};
pub fn rgbDemand(clock: Clock, bpc: u8) Error!Demand {
    if (!clock.valid() or (bpc != 8 and bpc != 10 and bpc != 12 and bpc != 16)) return error.Descriptor;
    return .{ .clock = clock, .bpp_x16 = @as(u16, bpc) * 3 * 16 };
}
pub fn tmdsFits(clock: Clock, bpc: u8, max_character_hz: u64) bool {
    if (!clock.valid() or max_character_hz == 0 or (bpc != 8 and bpc != 10 and bpc != 12 and bpc != 16)) return false;
    return @as(u128, clock.numerator) * bpc <= @as(u128, max_character_hz) * clock.denominator * 8;
}
pub fn dp8b10bPayload(rate: u8, lanes: u8) Error!u64 {
    // DPCD 0x001: RBR/HBR/HBR2/HBR3. UHBR needs its own128b/132b owner.
    if ((rate != 6 and rate != 10 and rate != 20 and rate != 30) or
        (lanes != 1 and lanes != 2 and lanes != 4)) return error.Unsupported;
    return @as(u64, rate) * 27_000_000 * 8 * lanes;
}
pub const Frl = enum(u8) {
    none = 0, lanes3_3g = 1, lanes3_6g = 2, lanes4_6g = 3,
    lanes4_8g = 4, lanes4_10g = 5, lanes4_12g = 6,
    pub fn decode(raw: u8) Error!Frl {
        if (raw > 6) return error.Unsupported;
        return @enumFromInt(raw);
    }
    pub fn lanes(self: Frl) u8 { return switch (self) { .none => 0, .lanes3_3g, .lanes3_6g => 3, else => 4 }; }
    pub fn gigabits(self: Frl) u8 {
        return switch (self) { .none => 0, .lanes3_3g => 3, .lanes3_6g, .lanes4_6g => 6,
            .lanes4_8g => 8, .lanes4_10g => 10, .lanes4_12g => 12 };
    }
    /// Only a coding ceiling: RM must additionally admit metering, blanking,
    /// packet/FEC overhead and audio for the precise requested timing.
    pub fn codingCeiling(self: Frl) u64 {
        return @as(u64, self.lanes()) * self.gigabits() * 1_000_000_000 * 16 / 18;
    }
};
pub const HdmiDsc = struct {
    advertised: bool = false,
    supported_fields: bool = false,
    bpc_mask: u8 = 0, //8/10/12/16bpc
    all_bpp: bool = false,
    native_420: bool = false,
    max_slices: u8 = 0,
    max_slice_clock_mhz: u16 = 0,
    max_frl: Frl = .none,
    max_chunk_bytes: u32 = 0,
};
pub const Hdmi = struct {
    max_frl_raw: u8 = 0,
    max_frl: Frl = .none,
    extended_unsupported: bool = false,
    dsc: HdmiDsc = .{},

    /// HF-VSDB payload includes the three OUI bytes; HF-SCDB has the same
    /// offsets after its extended tag and two reserved bytes.
    pub fn parse(data: []const u8) Error!Hdmi {
        if (data.len < 7 or data.len > 31 or data[3] != 1) return error.Descriptor;
        var result: Hdmi = .{ .max_frl_raw = data[6] >> 4 };
        result.max_frl = Frl.decode(result.max_frl_raw) catch blk: {
            result.extended_unsupported = true; break :blk .none;
        };
        if (result.max_frl != .none and data[5] & 0x80 == 0) {
            result.extended_unsupported = true; result.max_frl = .none;
        }
        if (data.len <= 10) return result;
        result.dsc.advertised = data[10] & 0x80 != 0;
        if (!result.dsc.advertised) return result;
        result.dsc.all_bpp = data[10] & 8 != 0;
        result.dsc.native_420 = data[10] & 0x40 != 0;
        result.dsc.bpc_mask = 1 | ((data[10] & 7) << 1);
        if (data.len < 13) { result.extended_unsupported = true; return result; }
        const slices = [_]u8{ 0, 1, 2, 4, 8, 8, 12, 16 };
        const slice_code = data[11] & 15;
        if (slice_code == 0 or slice_code >= slices.len or data[12] & 0xc0 != 0 or data[12] & 63 == 0) {
            result.extended_unsupported = true; return result;
        }
        result.dsc.max_frl = Frl.decode(data[11] >> 4) catch {
            result.extended_unsupported = true; return result;
        };
        if (result.max_frl == .none or result.dsc.max_frl == .none or
            @intFromEnum(result.dsc.max_frl) > @intFromEnum(result.max_frl)) {
            result.extended_unsupported = true; return result;
        }
        result.dsc.max_slices = slices[slice_code];
        result.dsc.max_slice_clock_mhz = if (slice_code <= 4) 340 else 400;
        result.dsc.max_chunk_bytes = (@as(u32, data[12] & 63) + 1) * 1024;
        result.dsc.supported_fields = true;
        return result;
    }
};
