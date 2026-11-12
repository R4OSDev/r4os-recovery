const std = @import("std");
const links = @import("../../Display/links.zig");
const t = std.testing;

pub fn check() !void {
    const clock = links.Clock.nvidia(0x80000000 | 594_000_000);
    try t.expectEqual(@as(u64, 593_406_594), try clock.ceilHz());
    try t.expect(links.tmdsFits(clock, 10, 741_758_242));
    try t.expect(!links.tmdsFits(clock, 10, 741_758_241));
    const high = try links.rgbDemand(.{ .numerator = 1_188_000_000 }, 10);
    try t.expect(!high.fits(try links.dp8b10bPayload(30, 4))); //4K120 RGB10 exceeds HBR3x4.
    const rgb8 = try links.rgbDemand(.{ .numerator = 1_080_000_000 }, 8);
    try t.expect(!rgb8.fits(25_920_000_000)); //No space remains for link framing.
    try t.expect(rgb8.fits(25_920_000_001));
    try t.expectError(error.Unsupported, links.dp8b10bPayload(0x01, 4)); //UHBR is a separate encoding.
    try t.expectError(error.Unsupported, links.dp8b10bPayload(30, 3));
    const maximal: links.Demand = .{ .clock = .{ .numerator = std.math.maxInt(u64) }, .bpp_x16 = 65535 };
    try t.expect(!maximal.fits(std.math.maxInt(u64)));
    try t.expectError(error.Bandwidth, maximal.ceilBitsPerSecond());
    const fractional: links.Demand = .{ .clock = .{ .numerator = 1001, .denominator = 1000 }, .bpp_x16 = 129 };
    try t.expectEqual(@as(u64, 9), try fractional.ceilBitsPerSecond());
    try t.expect(!fractional.fits(8) and fractional.fits(9));

    // HF-VSDB: FRL4x12G, DSC1.2/RGB8+10, eight400MHz slices,16KiB chunks.
    var data = [_]u8{ 0xd8, 0x5d, 0xc4, 1, 120, 0x80, 0x60, 0, 0, 0, 0x89, 0x65, 15 };
    const hdmi = try links.Hdmi.parse(&data);
    try t.expect(hdmi.max_frl == .lanes4_12g and !hdmi.extended_unsupported);
    try t.expect(hdmi.dsc.supported_fields and hdmi.dsc.bpc_mask == 3 and hdmi.dsc.all_bpp);
    try t.expect(hdmi.dsc.max_slices == 8 and hdmi.dsc.max_slice_clock_mhz == 400 and hdmi.dsc.max_chunk_bytes == 16384);
    try t.expectEqual(@as(u64, 42_666_666_666), hdmi.max_frl.codingCeiling());
    try t.expect(links.Frl.lanes3_3g.lanes() == 3 and links.Frl.lanes4_6g.gigabits() == 6);
    const valid = data;
    for (0..6) |bad| {
        data = valid;
        switch (bad) {
            0 => data[6] = 0x70, //Unknown future FRL enum cannot grant a link.
            1 => data[5] = 0, //SCDC absent.
            2 => data[11] = 0x68, //Reserved slice count.
            3 => data[11] = 0x75, //Unknown compressed FRL enum.
            4 => data[12] = 0, //Unspecified chunk capacity.
            5 => data[12] = 0xc1, //Reserved bits.
            else => unreachable,
        }
        const invalid = try links.Hdmi.parse(&data);
        try t.expect(invalid.extended_unsupported and !invalid.dsc.supported_fields);
    }
    data = valid;
    for (11..13) |length| {
        const short = try links.Hdmi.parse(data[0..length]);
        try t.expect(short.dsc.advertised and !short.dsc.supported_fields and short.extended_unsupported);
    }
    const ordinary = try links.Hdmi.parse(data[0..7]);
    try t.expect(!ordinary.dsc.advertised and ordinary.max_frl == .lanes4_12g);
    try t.expectError(error.Descriptor, links.Hdmi.parse(data[0..6]));
}
