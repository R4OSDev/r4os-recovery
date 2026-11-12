const std = @import("std");
const r4img = @import("r4img");

const width: u32 = 1920;
const height: u32 = 1080;
const rounds: usize = 2;
const sample_count: usize = 7;

pub fn main(init: std.process.Init) !void {
    const pixel_count = @as(usize, width) * height;
    const source_pixels = try init.gpa.alloc(u32, pixel_count);
    defer init.gpa.free(source_pixels);
    const destination = try init.gpa.alloc(u32, pixel_count);
    defer init.gpa.free(destination);

    for (source_pixels, 0..) |*pixel, index| {
        const value: u32 = @truncate(index *% 2_654_435_761);
        pixel.* = 0xFF000000 | (value & 0x00FFFFFF);
    }
    const source = r4img.Image{
        .info = .{ .format = .png, .width = width, .height = height, .channels = 4 },
        .pixels = source_pixels,
    };

    _ = try r4img.scaleComposite(source, destination, width, height, 0x00102030);
    var samples: [sample_count]u64 = undefined;
    var digest: u64 = 0;
    for (&samples) |*sample| {
        const started = std.Io.Clock.awake.now(init.io);
        for (0..rounds) |_| {
            const result = try r4img.scaleComposite(source, destination, width, height, 0x00102030);
            digest +%= result[0];
            digest +%= result[result.len / 2];
            digest +%= result[result.len - 1];
        }
        const ended = std.Io.Clock.awake.now(init.io);
        const delta = ended.nanoseconds - started.nanoseconds;
        if (delta <= 0) return error.ProfileClockUnavailable;
        sample.* = @intCast(delta);
    }
    std.mem.doNotOptimizeAway(digest);
    std.debug.print(
        "R4IMG_PROFILE workload=opaque-bilinear-1920x1080 rounds={d} samples_ns={any} digest={d}\n",
        .{ rounds, samples, digest },
    );
}
