//! Select existing owner cases through the SDK's canonical package root.
const std = @import("std");
const sdk = @import("../../r4os.zig");
test {
    inline for (.{ sdk.json, sdk.zip, sdk.ico, sdk.raster, sdk.web_encoding, sdk.web_url, sdk.web_crypto, sdk.version_info, sdk.r4mf, sdk.r4u_artifact }) |M| std.testing.refAllDecls(M);
}
