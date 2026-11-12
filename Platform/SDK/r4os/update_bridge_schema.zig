pub const owners = @import("update_helper_owners.zig");
const C = @import("native_bridge_schema.zig").Catalogue(owners, @import("r4os_contract").abi);
pub const abi = C.abi;
pub const modules = C.modules;
pub const context = C.context;
pub const canonical = C.canonical;
pub const types = C.types;
pub const functions = C.functions;
pub const typeId = C.typeId;
pub const stableName = C.stableName;
pub const fingerprint = C.fingerprint;

pub fn nativeName(comptime T: type) []const u8 {
    return @import("update_type_names.zig").nativeName(@This(), T);
}
