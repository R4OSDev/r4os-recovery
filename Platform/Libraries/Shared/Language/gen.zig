const std = @import("std");
const schema = @import("schema");
const header = @import("c_header.zig");
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 3 and args.len != 4) return error.UsageWriteCheckHeaderAndNativeFingerprintOrDumpPath;
    var output: std.Io.Writer.Allocating = .init(init.arena.allocator());
    @setEvalBranchQuota(32_000_000);
    if (std.mem.eql(u8, args[1], "dump")) {
        try output.writer.print("Libraries types={d} functions={d}\n", .{ schema.types.len, schema.functions.len });
        inline for (schema.types, 0..) |T, i| try output.writer.print("T{d}: {s} size={d} align={d}\n", .{ i, @typeName(T), @sizeOf(T), @alignOf(T) });
        inline for (schema.functions, 0..) |f, i| try output.writer.print("F{d}: {s}.{s}: {s}\n", .{ i, @typeName(f.owner), f.name, @typeName(@TypeOf(@field(f.owner, f.name))) });
    } else {
        if (args.len != 4) return error.UsageWriteCheckHeaderAndNativeFingerprintOrDumpPath;
        try header.emit(&output.writer);
    }
    if (std.mem.eql(u8, args[1], "check")) {
        const actual = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], init.arena.allocator(), .limited(8 * 1024 * 1024));
        if (!std.mem.eql(u8, actual, output.written())) return error.GeneratedLibraryHeaderDrift;
    } else if (std.mem.eql(u8, args[1], "write") or std.mem.eql(u8, args[1], "dump")) {
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[2], .data = output.written() });
    } else return error.UsageWriteCheckOrDumpPath;
    if (args.len == 4) {
        const expected = std.fmt.comptimePrint("// Generated from the compiler-typed Libraries catalogue. Do not edit.\npub const fingerprint:u64={d};\n", .{schema.fingerprint});
        if (std.mem.eql(u8, args[1], "check")) {
            const actual = try std.Io.Dir.cwd().readFileAlloc(init.io, args[3], init.arena.allocator(), .limited(4096));
            if (!std.mem.eql(u8, actual, expected)) return error.GeneratedLibraryFingerprintDrift;
        } else try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[3], .data = expected });
    }
}
