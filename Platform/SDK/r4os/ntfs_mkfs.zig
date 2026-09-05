// Standalone host-model entry point; the canonical builder also serves
// r4os.storage_tools with that namespace's format definitions.
const implementation = @import("ntfs_builder.zig").WithFormat(@import("ntfs_format"));
pub const Builder = implementation.Builder;
pub const Meta = implementation.Meta;
pub const Error = implementation.Error;
