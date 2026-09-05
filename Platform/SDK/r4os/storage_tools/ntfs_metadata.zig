//! Frozen, volume-independent data from the existing NTFS reference fixture.
//! Its byte identities and origin are recorded in ntfs_metadata/provenance.json.
pub fn standard(comptime Meta: type) Meta {
    return .{
        .upcase = @embedFile("ntfs_metadata/upcase.bin"),
        .upcase_info = @embedFile("ntfs_metadata/upcase_info.bin"),
        .attrdef = @embedFile("ntfs_metadata/attrdef.bin"),
        .sds_prefix = @embedFile("ntfs_metadata/secure_sds_prefix.bin"),
        .sdh_root = @embedFile("ntfs_metadata/secure_sdh_root.bin"),
        .sii_root = @embedFile("ntfs_metadata/secure_sii_root.bin"),
        .sdh_alloc = @embedFile("ntfs_metadata/secure_SDH_alloc.bin"),
        .sii_alloc = @embedFile("ntfs_metadata/secure_SII_alloc.bin"),
        .sdh_bitmap = @embedFile("ntfs_metadata/secure_SDH_bitmap.bin"),
        .sii_bitmap = @embedFile("ntfs_metadata/secure_SII_bitmap.bin"),
        .objid_o_root = @embedFile("ntfs_metadata/extend_objid_o_root.bin"),
        .quota_o_root = @embedFile("ntfs_metadata/extend_quota_o_root.bin"),
        .quota_q_root = @embedFile("ntfs_metadata/extend_quota_q_root.bin"),
        .reparse_r_root = @embedFile("ntfs_metadata/extend_reparse_r_root.bin"),
        .root_sd = @embedFile("ntfs_metadata/root_sd.bin"),
        .boot_sd = @embedFile("ntfs_metadata/boot_sd.bin"),
    };
}
