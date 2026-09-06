//! Read the Recovery-owned named ELF section, never a magic-byte search.
const std = @import("std");
fn integer(comptime T: type, bytes: []const u8, at: usize) T {
    return std.mem.readInt(T, bytes[at..][0..@sizeOf(T)], .little);
}
pub fn verify(elf: []const u8, runtime: []const u8, version: []const u8, kernel: []const u8, required: bool) !void {
    if (elf.len < 64 or !std.mem.eql(u8, elf[0..6], "\x7fELF\x02\x01") or integer(u16, elf, 18) != 62) return error.RecoveryPairMismatch;
    const start = integer(u64, elf, 40);
    const stride = integer(u16, elf, 58);
    const count = integer(u16, elf, 60);
    const strings = integer(u16, elf, 62);
    if (stride < 64 or count == 0 or count > 4096 or strings >= count or start > elf.len or count > (elf.len - start) / stride) return error.RecoveryPairMismatch;
    const names_header = elf[@intCast(start + @as(u64, strings) * stride)..][0..64];
    const names_start = integer(u64, names_header, 24);
    const names_size = integer(u64, names_header, 32);
    if (names_start > elf.len or names_size > elf.len - names_start) return error.RecoveryPairMismatch;
    const names = elf[@intCast(names_start)..][0..@intCast(names_size)];
    var found = false;
    for (0..count) |i| {
        const header = elf[@intCast(start + i * stride)..][0..64];
        const index = integer(u32, header, 0);
        if (index >= names.len) return error.RecoveryPairMismatch;
        const end = std.mem.indexOfScalarPos(u8, names, index, 0) orelse return error.RecoveryPairMismatch;
        if (!std.mem.eql(u8, names[index..end], ".r4os.recovery.pair")) continue;
        const offset = integer(u64, header, 24);
        if (found or integer(u32, header, 4) != 1 or integer(u64, header, 32) != 112 or offset > elf.len or 112 > elf.len - offset) return error.RecoveryPairMismatch;
        const bytes = elf[@intCast(offset)..][0..112];
        var hash: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(runtime, &hash, .{});
        if (!std.mem.eql(u8, bytes[0..8], "R4RECOV1") or integer(u64, bytes, 8) != runtime.len or
            !std.mem.eql(u8, bytes[16..48], &hash) or !std.mem.eql(u8, std.mem.sliceTo(bytes[48..80], 0), version) or
            !std.mem.eql(u8, std.mem.sliceTo(bytes[80..112], 0), kernel)) return error.RecoveryPairMismatch;
        found = true;
    }
    if (required and !found) return error.RecoveryPairMismatch;
}
