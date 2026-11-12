//! Select LLVM's inline page probes before target machine code generation.
//! Out-of-line Zig probes run after stack realignment and cannot cover its gap.
const std = @import("std");
const old = "\"probe-stack\"=\"__zig_probe_stack\"";
const replacement = "\"probe-stack\"=\"inline-asm\"";

pub fn run(io: std.Io, input_path: []const u8, output_path: []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    const input = try cwd.openFile(io, input_path, .{});
    defer input.close(io);
    const output = try cwd.createFile(io, output_path, .{});
    defer output.close(io);
    var read_buffer: [64 * 1024]u8 = undefined;
    var write_buffer: [64 * 1024]u8 = undefined;
    var file_reader = input.reader(io, &read_buffer);
    var file_writer = output.writer(io, &write_buffer);
    const reader = &file_reader.interface;
    const writer = &file_writer.interface;
    while (true) {
        const prefix = reader.peek("attributes #".len) catch |err| switch (err) {
            error.EndOfStream => {
                try writer.writeAll(reader.buffered());
                break;
            },
            else => return err,
        };
        if (std.mem.eql(u8, prefix, "attributes #")) {
            const line = try reader.takeDelimiterInclusive('\n');
            if (std.mem.indexOf(u8, line, old)) |at| {
                try writer.writeAll(line[0..at]);
                try writer.writeAll(replacement);
                try writer.writeAll(line[at + old.len ..]);
            } else {
                if (std.mem.indexOf(u8, line, "\"probe-stack\"=") != null and
                    std.mem.indexOf(u8, line, replacement) == null) return error.UnknownStackProbeContract;
                try writer.writeAll(line);
            }
        } else {
            // Constants can occupy very large single lines. Stream them
            // unchanged instead of allocating a module-sized text buffer.
            _ = reader.streamDelimiter(writer, '\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            reader.toss(1);
            try writer.writeByte('\n');
        }
    }
    try writer.flush();
}
