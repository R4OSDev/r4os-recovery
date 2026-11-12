//! Web-only dispatch keeps its large engines out of data-only consumers.
const core = @import("native_bridge_schema.zig").Catalogue(@import("web_helper_owners.zig"), @import("r4os_contract").abi);
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
