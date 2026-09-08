const std = @import("std");

pub const Error = error{
    EntropyUnavailable,
    UnsupportedAlgorithm,
    OutputTooSmall,
};

pub const max_random_bytes: usize = 65_536;

const secure_random = @import("secure_random.zig");
pub const secureEntropyAvailable = secure_random.available;
pub const fillSecureRandom = secure_random.fill;

pub fn digest(algorithm: []const u8, input: []const u8, output: []u8) Error![]const u8 {
    if (!std.ascii.eqlIgnoreCase(algorithm, "SHA-256")) return error.UnsupportedAlgorithm;
    if (output.len < std.crypto.hash.sha2.Sha256.digest_length) return error.OutputTooSmall;
    var result: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(input, &result, .{});
    @memcpy(output[0..result.len], result[0..]);
    return output[0..result.len];
}

test "SHA-256 digest is deterministic and validated" {
    var output: [32]u8 = undefined;
    const result = try digest("sha-256", "abc", output[0..]);
    const expected = [_]u8{ 0xBA, 0x78, 0x16, 0xBF, 0x8F, 0x01, 0xCF, 0xEA, 0x41, 0x41, 0x40, 0xDE, 0x5D, 0xAE, 0x22, 0x23, 0xB0, 0x03, 0x61, 0xA3, 0x96, 0x17, 0x7A, 0x9C, 0xB4, 0x10, 0xFF, 0x61, 0xF2, 0x00, 0x15, 0xAD };
    try std.testing.expectEqualSlices(u8, &expected, result);
    try std.testing.expectError(error.UnsupportedAlgorithm, digest("SHA-1", "abc", output[0..]));
}
