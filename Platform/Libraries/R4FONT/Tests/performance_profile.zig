const std = @import("std");
const r4font = @import("r4font");

const iterations: usize = 5000;
const sample_count: usize = 7;

pub fn main(init: std.process.Init) !void {
    var decoder = try r4font.Decoder.init(init.gpa, r4font.default_allocation_limit);
    defer decoder.deinit();
    var face = try decoder.openFace(@embedFile("Fixtures/sample-glyf.ttf"), 0);
    defer face.deinit();
    const glyph = face.glyphIndex('A');
    const alpha = try init.gpa.alloc(u8, 64 * 1024);
    defer init.gpa.free(alpha);

    _ = try face.rasterize(glyph, 32, alpha);
    var samples: [sample_count]u64 = undefined;
    var digest: u64 = 0;
    for (&samples) |*sample| {
        const started = std.Io.Clock.awake.now(init.io);
        for (0..iterations) |_| {
            const raster = try face.rasterize(glyph, 32, alpha);
            digest +%= raster.width;
            digest +%= raster.height;
            digest +%= raster.alpha[raster.alpha.len / 2];
        }
        const ended = std.Io.Clock.awake.now(init.io);
        const delta = ended.nanoseconds - started.nanoseconds;
        if (delta <= 0) return error.ProfileClockUnavailable;
        sample.* = @intCast(delta);
    }
    std.mem.doNotOptimizeAway(digest);
    std.debug.print(
        "R4FONT_PROFILE workload=glyph-raster-32px iterations={d} samples_ns={any} digest={d}\n",
        .{ iterations, samples, digest },
    );
}
