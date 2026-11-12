//! Canonical R4MF/R4M0 import syntax. Host code generation consumes the
//! validated fields; language runtimes never parse the manifest grammar.
const std = @import("std");
const abi = @import("r4os_contract").abi;

pub const Spec = struct {
    module_name: []const u8,
    symbol_name: []const u8,
    minimum: u16,
    optional: bool,
};

pub fn platformGroupId(name: []const u8) ?u32 {
    for (abi.r4_platform_apis) |group| {
        if (std.ascii.eqlIgnoreCase(name, group.name)) return @intFromEnum(group.group);
    }
    return null;
}

pub fn parse(value: []const u8) error{InvalidImport}!Spec {
    var parts = std.mem.splitScalar(u8, value, ':');
    const module_name = parts.next() orelse return error.InvalidImport;
    const symbol_name = parts.next() orelse return error.InvalidImport;
    const major = parts.next() orelse return error.InvalidImport;
    const flags_text = parts.next();
    if (parts.next() != null or module_name.len == 0 or symbol_name.len == 0 or major.len == 0) return error.InvalidImport;
    const flags = if (flags_text) |text| std.fmt.parseUnsigned(u32, text, 10) catch return error.InvalidImport else 0;
    if (flags > 1 or (flags != 0 and platformGroupId(module_name) != null)) return error.InvalidImport;
    for (module_name) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_' and byte != '-') return error.InvalidImport;
    for (symbol_name) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidImport;
    const minimum = std.fmt.parseUnsigned(u16, major, 10) catch return error.InvalidImport;
    if (minimum == 0) return error.InvalidImport;
    return .{ .module_name = module_name, .symbol_name = symbol_name, .minimum = minimum, .optional = flags == 1 };
}
