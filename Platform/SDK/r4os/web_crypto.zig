const std = @import("std");

pub const Error = error{
    EntropyUnavailable,
    UnsupportedAlgorithm,
    OutputTooSmall,
};

pub const max_random_bytes: usize = 65_536;

pub fn secureEntropyAvailable() bool {
    return (cpuid(1, 0).ecx & (@as(u32, 1) << 30)) != 0;
}

pub fn fillSecureRandom(out: []u8) bool {
    if (!secureEntropyAvailable()) return false;
    var offset: usize = 0;
    while (offset < out.len) {
        var attempt: u8 = 0;
        var value: ?u64 = null;
        while (attempt < 10 and value == null) : (attempt += 1) value = rdrand64();
        const word = value orelse {
            @memset(out, 0);
            return false;
        };
        const count = @min(@as(usize, 8), out.len - offset);
        for (0..count) |index| out[offset + index] = @truncate(word >> @intCast(index * 8));
        offset += count;
    }
    return true;
}

pub fn digest(algorithm: []const u8, input: []const u8, output: []u8) Error![]const u8 {
    if (!std.ascii.eqlIgnoreCase(algorithm, "SHA-256")) return error.UnsupportedAlgorithm;
    if (output.len < std.crypto.hash.sha2.Sha256.digest_length) return error.OutputTooSmall;
    var result: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(input, &result, .{});
    @memcpy(output[0..result.len], result[0..]);
    return output[0..result.len];
}

const CpuId = struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
};

fn cpuid(leaf: u32, subleaf: u32) CpuId {
    var eax: u32 = leaf;
    var ebx: u32 = 0;
    var ecx: u32 = subleaf;
    var edx: u32 = 0;
    asm volatile ("cpuid"
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [leaf] "{eax}" (leaf),
          [subleaf] "{ecx}" (subleaf),
    );
    return .{ .eax = eax, .ebx = ebx, .ecx = ecx, .edx = edx };
}

fn rdrand64() ?u64 {
    var value: u64 = 0;
    var success: u8 = 0;
    asm volatile (
        \\rdrand %[value]
        \\setc %[success]
        : [value] "=r" (value),
          [success] "=r" (success),
    );
    return if (success != 0) value else null;
}

test "SHA-256 digest is deterministic and validated" {
    var output: [32]u8 = undefined;
    const result = try digest("sha-256", "abc", output[0..]);
    const expected = [_]u8{ 0xBA, 0x78, 0x16, 0xBF, 0x8F, 0x01, 0xCF, 0xEA, 0x41, 0x41, 0x40, 0xDE, 0x5D, 0xAE, 0x22, 0x23, 0xB0, 0x03, 0x61, 0xA3, 0x96, 0x17, 0x7A, 0x9C, 0xB4, 0x10, 0xFF, 0x61, 0xF2, 0x00, 0x15, 0xAD };
    try std.testing.expectEqualSlices(u8, &expected, result);
    try std.testing.expectError(error.UnsupportedAlgorithm, digest("SHA-1", "abc", output[0..]));
}
