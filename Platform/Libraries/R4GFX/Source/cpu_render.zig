//! Ordered, allocation-free CPU 2D execution. The complete batch is checked
//! before any pixel or output mutation. Addresses are borrowed CPU maps;
//! backing lifetime, exclusivity and physical alias identity remain caller-owned.
const std = @import("std");
const c = @import("r4l_contract");
const Error = error{ Invalid, Unsupported, Overflow, Limit, Alias };
const Span = struct {
    start: u64,
    end: u64,
    fn overlaps(a: Span, b: Span) bool {
        return a.start < a.end and b.start < b.end and a.start < b.end and b.start < a.end;
    }
};
fn span(start: u64, length: u64) Error!Span {
    if (length != 0 and start == 0) return error.Invalid;
    return .{ .start = start, .end = std.math.add(u64, start, length) catch return error.Overflow };
}
fn bpp(format: u32) Error!u64 {
    return switch (format) {
        c.format_argb8888, c.format_xrgb8888 => 4,
        c.format_r8 => 1,
        else => error.Unsupported,
    };
}
fn imageSpan(image: *const c.R4GfxCpuImage) Error!Span {
    if (image.reserved != 0 or image.width == 0 or image.height == 0) return error.Invalid;
    const row = @as(u64, image.width) * try bpp(image.format);
    if (image.pitch < row) return error.Invalid;
    const length = std.math.mul(u64, image.pitch, image.height) catch return error.Overflow;
    if (length > image.byte_length) return error.Invalid;
    return span(image.cpu_address, length);
}
fn rect(image: *const c.R4GfxCpuImage, area: c.R4GfxRect) Error!void {
    if (area.x > image.width or area.y > image.height or area.width > image.width - area.x or area.height > image.height - area.y) return error.Invalid;
}
const Plan = struct {
    target: *const c.R4GfxCpuImage,
    source: ?*const c.R4GfxCpuImage = null,
    kind: enum { fill, copy, sample },
    pixels: u64,
    read_bytes: u64 = 0,
    write_bytes: u64,
};
fn plan(images: []const c.R4GfxCpuImage, command: *const c.R4GfxCpuDraw) Error!Plan {
    if (command.target_index >= images.len or command.reserved0 != 0 or command.reserved1 != 0) return error.Invalid;
    const target = &images[command.target_index];
    try rect(target, command.target_rect);
    const pixels = @as(u64, command.target_rect.width) * command.target_rect.height;
    if (pixels > c.render_max_pixels) return error.Limit;
    var result: Plan = .{ .target = target, .kind = .fill, .pixels = pixels, .write_bytes = pixels * try bpp(target.format) };
    if (command.operation == c.render_operation_fill) {
        if (command.source_index != 0 or command.sampler != 0 or command.opacity != 0 or
            command.source_rect.x != 0 or command.source_rect.y != 0 or command.source_rect.width != 0 or command.source_rect.height != 0) return error.Invalid;
        return result;
    }
    if (command.operation != c.render_operation_blit and command.operation != c.render_operation_over) return error.Unsupported;
    if (command.source_index >= images.len or command.color != 0 or command.opacity > 255) return error.Invalid;
    if (command.operation == c.render_operation_blit and command.opacity != 255) return error.Invalid;
    if (command.sampler != c.render_sampler_nearest and command.sampler != c.render_sampler_bilinear) return error.Unsupported;
    const source = &images[command.source_index];
    result.source = source;
    try rect(source, command.source_rect);
    if (pixels != 0 and (command.source_rect.width == 0 or command.source_rect.height == 0)) return error.Invalid;
    const source_bpp = try bpp(source.format);
    if ((source_bpp == 1) != ((try bpp(target.format)) == 1) or
        (command.operation == c.render_operation_over and source_bpp == 1)) return error.Unsupported;
    const copy = command.operation == c.render_operation_blit and source.format == target.format and
        command.source_rect.width == command.target_rect.width and command.source_rect.height == command.target_rect.height;
    if (pixels != 0 and (try imageSpan(source)).overlaps(try imageSpan(target))) {
        // Identical views permit ordinary memmove. Different virtual aliases
        // of the same backing are prohibited by the caller's map contract.
        if (!copy or source.cpu_address != target.cpu_address or source.pitch != target.pitch or
            source.width != target.width or source.height != target.height) return error.Alias;
    }
    result.kind = if (copy) .copy else .sample;
    result.read_bytes = pixels * source_bpp * @as(u64, if (!copy and command.sampler == c.render_sampler_bilinear) 4 else 1);
    if (command.operation == c.render_operation_over) result.read_bytes += pixels * 4;
    return result;
}
pub fn capabilities(output: *c.R4GfxRenderCaps) callconv(.c) i32 {
    if (@intFromPtr(output) == 0) return c.status_invalid;
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxRenderCaps), .backend = c.render_backend_software, .formats = c.render_format_xrgb8888 | c.render_format_argb8888 | c.render_format_r8, .operations = c.render_operation_fill | c.render_operation_blit | c.render_operation_over, .samplers = 3, .max_images = c.render_max_images, .max_commands = c.render_max_commands, .max_pixels = c.render_max_pixels, .features = c.render_feature_validate_first | c.render_feature_cpu_maps |
        c.render_feature_memmove | c.render_feature_premultiplied, .reserved = 0 };
    return c.status_ok;
}
pub fn execute(batch: *const c.R4GfxCpuBatch, output: *c.R4GfxCpuStats) callconv(.c) i32 {
    run(batch, output) catch |err| return switch (err) {
        error.Invalid => c.status_invalid,
        error.Unsupported => c.status_unsupported,
        error.Overflow => c.status_overflow,
        error.Limit => c.status_limit,
        error.Alias => c.status_alias,
    };
    return c.status_ok;
}
fn run(batch: *const c.R4GfxCpuBatch, output: *c.R4GfxCpuStats) Error!void {
    if (@intFromPtr(batch) == 0 or @intFromPtr(output) == 0 or batch.flags != 0 or batch.reserved != 0) return error.Invalid;
    if (batch.image_count > c.render_max_images or batch.command_count > c.render_max_commands or batch.pixel_budget > c.render_max_pixels) return error.Limit;
    if ((batch.image_count != 0 and batch.images % @alignOf(c.R4GfxCpuImage) != 0) or
        (batch.command_count != 0 and batch.commands % @alignOf(c.R4GfxCpuDraw) != 0)) return error.Invalid;
    const metadata = [_]Span{ try span(@intFromPtr(batch), @sizeOf(c.R4GfxCpuBatch)), try span(@intFromPtr(output), @sizeOf(c.R4GfxCpuStats)), try span(batch.images, @as(u64, batch.image_count) * @sizeOf(c.R4GfxCpuImage)), try span(batch.commands, @as(u64, batch.command_count) * @sizeOf(c.R4GfxCpuDraw)) };
    for ([_]usize{ 0, 2, 3 }) |i| if (metadata[1].overlaps(metadata[i])) return error.Alias;
    const images: []const c.R4GfxCpuImage = if (batch.image_count == 0) &.{} else @as([*]const c.R4GfxCpuImage, @ptrFromInt(batch.images))[0..batch.image_count];
    const commands: []const c.R4GfxCpuDraw = if (batch.command_count == 0) &.{} else @as([*]const c.R4GfxCpuDraw, @ptrFromInt(batch.commands))[0..batch.command_count];
    for (images) |*image| {
        const bytes = try imageSpan(image);
        for (metadata) |item| if (bytes.overlaps(item)) return error.Alias;
    }
    var stats: c.R4GfxCpuStats = .{ .read_bytes = 0, .write_bytes = 0, .pixels = 0, .commands = batch.command_count, .reserved = 0 };
    for (commands) |*command| {
        const item = try plan(images, command);
        stats.pixels += item.pixels; // Bounds above cap this sum at 2^34.
        if (stats.pixels > batch.pixel_budget) return error.Limit;
        stats.read_bytes += item.read_bytes;
        stats.write_bytes += item.write_bytes;
    }
    // Metadata cannot alias writable images. With the documented exclusive
    // caller ownership, the second pass cannot introduce a new validation
    // failure and needs no large per-command array on the caller's stack.
    for (commands) |*command| {
        const item = plan(images, command) catch unreachable;
        if (item.pixels == 0) continue;
        switch (item.kind) {
            .fill => fill(item.target, command),
            .copy => copyRect(item.source.?, item.target, command),
            .sample => sampled(item.source.?, item.target, command),
        }
    }
    output.* = stats;
}
fn address(image: *const c.R4GfxCpuImage, x: u64, y: u64) [*]u8 {
    return @ptrFromInt(image.cpu_address + y * image.pitch + x * (bpp(image.format) catch unreachable));
}
fn load(image: *const c.R4GfxCpuImage, x: u64, y: u64) u32 {
    const bytes = address(image, x, y);
    if (image.format == c.format_r8) return bytes[0];
    const value = std.mem.readInt(u32, bytes[0..4], .little);
    return if (image.format == c.format_xrgb8888) value | 0xff000000 else value;
}
fn put(image: *const c.R4GfxCpuImage, x: u64, y: u64, value: u32) void {
    const bytes = address(image, x, y);
    if (image.format == c.format_r8) bytes[0] = @truncate(value) else std.mem.writeInt(u32, bytes[0..4], if (image.format == c.format_xrgb8888) value & 0xffffff else value, .little);
}
fn fill(target: *const c.R4GfxCpuImage, command: *const c.R4GfxCpuDraw) void {
    const r = command.target_rect;
    const color = std.mem.nativeToLittle(u32, if (target.format == c.format_xrgb8888) command.color & 0xffffff else command.color);
    for (0..r.height) |y| {
        if (target.format == c.format_r8) {
            @memset(address(target, r.x, r.y + y)[0..r.width], @as(u8, @truncate(command.color)));
        } else {
            // Keep the Desktop fill path as a whole-row store. The CPU-map
            // contract permits unaligned addresses and nonaligned pitches.
            const row: [*]align(1) u32 = @ptrCast(address(target, r.x, r.y + y));
            @memset(row[0..r.width], color);
        }
    }
}
fn copyRect(source: *const c.R4GfxCpuImage, target: *const c.R4GfxCpuImage, command: *const c.R4GfxCpuDraw) void {
    const s = command.source_rect;
    const d = command.target_rect;
    const reverse = @intFromPtr(address(target, d.x, d.y)) > @intFromPtr(address(source, s.x, s.y));
    const bytes = @as(usize, d.width) * @as(usize, @intCast(bpp(source.format) catch unreachable));
    for (0..d.height) |yi| {
        const y = if (reverse) d.height - 1 - yi else yi;
        if (target.format == c.format_xrgb8888) {
            // Normalize the unused X byte in the same read/write pass.
            for (0..d.width) |xi| {
                const x = if (reverse) d.width - 1 - xi else xi;
                put(target, d.x + x, d.y + y, load(source, s.x + x, s.y + y));
            }
        } else {
            const from = address(source, s.x, s.y + y)[0..bytes];
            const to = address(target, d.x, d.y + y)[0..bytes];
            if (reverse) std.mem.copyBackwards(u8, to, from) else std.mem.copyForwards(u8, to, from);
        }
    }
}
const Axis = struct { first: u32, second: u32, weight: u32 };
fn axis(position: u64, source: u32, target: u32) Axis {
    const numerator = (position * 2 + 1) * source; // position <= bounded destination pixels.
    if (numerator <= target) return .{ .first = 0, .second = 0, .weight = 0 };
    const shifted = numerator - target;
    const denominator = @as(u64, target) * 2;
    const first: u32 = @intCast(@min(shifted / denominator, source - 1));
    return .{ .first = first, .second = @min(first +| 1, source - 1), .weight = @intCast((shifted % denominator) * 256 / denominator) };
}
fn lerp(a: u32, b: u32, weight: u32) u32 {
    var value: u32 = 0;
    inline for (.{ 0, 8, 16, 24 }) |shift| {
        const channel = (((a >> shift) & 255) * (256 - weight) + ((b >> shift) & 255) * weight + 128) >> 8;
        value |= channel << shift;
    }
    return value;
}
fn over(source: u32, target: u32, opacity: u32) u32 {
    const alpha = ((source >> 24) * opacity + 127) / 255;
    var value: u32 = 0;
    inline for (.{ 0, 8, 16, 24 }) |shift| {
        const src = (((source >> shift) & 255) * opacity + 127) / 255;
        const dst = (((target >> shift) & 255) * (255 - alpha) + 127) / 255;
        value |= @as(u32, @min(src + dst, 255)) << shift;
    }
    return value;
}
fn sampled(source: *const c.R4GfxCpuImage, target: *const c.R4GfxCpuImage, command: *const c.R4GfxCpuDraw) void {
    const s = command.source_rect;
    const d = command.target_rect;
    for (0..d.height) |y| for (0..d.width) |x| {
        var value: u32 = undefined;
        if (command.sampler == c.render_sampler_nearest) {
            const sx = (@as(u64, x) * 2 + 1) * s.width / (@as(u64, d.width) * 2);
            const sy = (@as(u64, y) * 2 + 1) * s.height / (@as(u64, d.height) * 2);
            value = load(source, s.x + sx, s.y + sy);
        } else {
            const sx = axis(x, s.width, d.width);
            const sy = axis(y, s.height, d.height);
            value = lerp(lerp(load(source, s.x + @as(u64, sx.first), s.y + @as(u64, sy.first)), load(source, s.x + @as(u64, sx.second), s.y + @as(u64, sy.first)), sx.weight), lerp(load(source, s.x + @as(u64, sx.first), s.y + @as(u64, sy.second)), load(source, s.x + @as(u64, sx.second), s.y + @as(u64, sy.second)), sx.weight), sy.weight);
        }
        if (command.operation == c.render_operation_over) value = over(value, load(target, d.x + x, d.y + y), command.opacity);
        put(target, d.x + x, d.y + y, value);
    };
}
