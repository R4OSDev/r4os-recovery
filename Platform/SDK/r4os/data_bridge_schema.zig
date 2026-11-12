//! Original SDK data helper catalogue; no algorithm implementations.
const core = @import("native_bridge_schema.zig").Catalogue(@import("data_helper_owners.zig"), @import("r4os_contract").abi);
pub const abi = core.abi;
pub const owners = core.owners;
pub const modules = core.modules;
pub const types = core.types;
pub const functions = core.functions;
pub const fingerprint = core.fingerprint;
pub const context = core.context;
pub const canonical = core.canonical;
pub const typeId = core.typeId;
pub const stableName = core.stableName;

pub fn nativeName(comptime T: type) []const u8 {
    return @import("data_bridge_names.zig").nativeName(@This(), T);
}
