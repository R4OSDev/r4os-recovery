//! Data algorithms and protocol facades retain their original SDK owners.
const std = @import("std");
pub const json = @import("json.zig");
pub const zip = @import("zip.zig");
pub const ico = @import("ico.zig");
pub const raster = @import("raster.zig");
pub const random = @import("secure_random.zig");
pub const cpu = @import("cpu_acceleration.zig");
pub const memory = @import("cpu_memory.zig");
pub const crypto = @import("web_crypto.zig");
pub const encoding = @import("web_encoding.zig");
pub const url = @import("web_url.zig");
pub const project = @import("r4cp.zig");
pub const conversion = @import("r4cp_convert.zig");
pub const manifest = @import("module_manifest.zig");
pub const version = @import("version_info.zig");
pub const metadata = @import("r4u_manifest.zig");
pub const artifact = @import("r4u_artifact.zig");
pub const adapters = @import("data_helper_adapters.zig");
pub const hash = @import("crypto_sha256.zig").Sha256(noWork);
fn noWork() ?cpu.WorkFn {
    return null;
}
pub const modules = .{ json, zip, ico, raster, random, cpu, memory, crypto, encoding, url, project, conversion, manifest, version, metadata, artifact, adapters, hash };
pub fn moduleType(comptime T: type) bool {
    if (T == @This()) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return T == manifest.capabilities or T == manifest.rust_project or T == manifest.import_spec or T == manifest.startup_metadata or T == metadata.paths or T == @import("r4os_contract").abi;
}
pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    if (T == adapters.Context or T == adapters.Arena) return true;
    const name = @typeName(T);
    inline for (.{ "array_list.", "hash_map.", "mem.Allocator", "heap.", "atomic.", "crypto.", "program.", "r4sys.", "r4dev.", "Io.", "std." }) |prefix| {
        if (std.mem.startsWith(u8, name, prefix)) return true;
    }
    return false;
}
test {
    inline for (modules) |M| std.testing.refAllDecls(M);
}
