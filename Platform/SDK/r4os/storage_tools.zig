//! Shared userland/host partitioning and filesystem maintenance tools.
pub const io = @import("storage_tools/io.zig");
pub const host_file = @import("storage_tools/host_file.zig");
pub const partition = @import("storage_tools/partition.zig");
pub const fat32 = @import("storage_tools/fat32.zig");
pub const ntfs_format = @import("ntfs_format.zig");
pub const ntfs = @import("ntfs_builder.zig").WithFormat(ntfs_format);

pub fn standardNtfsMetadata() ntfs.Meta {
    return @import("storage_tools/ntfs_metadata.zig").standard(ntfs.Meta);
}
pub const ntfs_resize = @import("storage_tools/ntfs_resize.zig");
pub const ntfs_extend = ntfs_resize;
pub const gpt_repair = @import("storage_tools/gpt_repair.zig");
