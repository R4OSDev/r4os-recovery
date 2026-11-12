//! Current transaction/metadata owner cases in the SDK package root.
const std = @import("std");
const sdk = @import("../../r4os.zig");
test {
    inline for (.{ sdk.version_info, sdk.r4u_manifest, sdk.r4u_manifest.paths, sdk.r4u_artifact, sdk.system_update_inventory, sdk.system_update_recovery, sdk.system_update_batch, sdk.system_update_backup, sdk.update_catalog }) |M| std.testing.refAllDecls(M);
}

test "kernel asset plan binds the installed BOOT guid and actual Limine entries" {
    const owner = @import("../../r4os/system_update_asset_system.zig");
    const guid = "11111111-2222-4333-8444-555555555555";
    const valid = "/R4OS\n protocol: limine\n path: guid(11111111-2222-4333-8444-555555555555):/boot/r4os.elf\n/R4OS Recovery\n path: guid(other):/CURRENT/recovery.elf\n";
    try std.testing.expect(owner.kernelConfigMatches(valid, guid));
    try std.testing.expect(!owner.kernelConfigMatches(valid, "aaaaaaaa-2222-4333-8444-555555555555"));
    try std.testing.expect(!owner.kernelConfigMatches("/R4OS\n path: boot():/other.elf\n", guid));
    try std.testing.expect(!owner.kernelConfigMatches("/R4OS\n protocol: limine\n", guid));
    try std.testing.expect(!owner.kernelConfigMatches("/R4OS\n protocol: linux\n path: guid(11111111-2222-4333-8444-555555555555):/boot/r4os.elf\n", guid));
    try std.testing.expect(!owner.kernelConfigMatches("/R4OS Recovery\n path: boot():/boot/r4os.elf\n", guid));
    try std.testing.expect(!owner.kernelConfigMatches(valid ++ "/R4OS Software Graphics\n path: guid(11111111-2222-4333-8444-555555555555):/boot/r4os.elf\n path: guid(11111111-2222-4333-8444-555555555555):/boot/r4os.elf\n", guid));
}
