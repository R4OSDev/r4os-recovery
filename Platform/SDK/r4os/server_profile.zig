const std = @import("std");
const r4sys = @import("r4sys.zig");

pub const config_path: [*:0]const u8 = "C:\\R4OS\\CONFIG\\R4OSSERVER.R4S";
pub const credentials_path: [*:0]const u8 = "C:\\R4OS\\SECRETS\\R4OSSERVER.R4S";

pub const Profile = enum {
    public,
    lan,

    pub fn registrationUsesTls(self: Profile) bool {
        return self == .public;
    }
};

pub const Error = error{
    ConfigMissing,
    ConfigInvalid,
    ProfileMissing,
    ProfileInvalid,
};

/// The profile is explicit and contains no server address or credentials.
/// Data services use HTTPS in either profile.
pub fn load(ctx: *const r4sys.Context) Error!Profile {
    var bytes: [512]u8 = undefined;
    const count = ctx.fileRead(config_path, &bytes);
    if (count == -3) return error.ConfigMissing;
    if (count <= 0 or count >= bytes.len) return error.ConfigInvalid;
    return parse(bytes[0..@intCast(count)]);
}

pub fn parse(document: []const u8) Error!Profile {
    var data = document;
    if (std.mem.startsWith(u8, data, "\xef\xbb\xbf")) data = data[3..];
    var schema_seen = false;
    var selected: ?Profile = null;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, "\r");
        if (line.len == 0 or line[0] == '#') continue;
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse return error.ConfigInvalid;
        const key = line[0..separator];
        const value = line[separator + 1 ..];
        if (std.mem.eql(u8, key, "SCHEMA")) {
            if (schema_seen or !std.mem.eql(u8, value, "R4OS_SERVER_CLIENT")) return error.ConfigInvalid;
            schema_seen = true;
        } else if (std.mem.eql(u8, key, "PROFILE")) {
            if (selected != null) return error.ConfigInvalid;
            selected = if (std.mem.eql(u8, value, "PUBLIC"))
                .public
            else if (std.mem.eql(u8, value, "LAN"))
                .lan
            else
                return error.ProfileInvalid;
        }
    }
    if (!schema_seen) return error.ConfigInvalid;
    return selected orelse error.ProfileMissing;
}

test "server profile requires explicit transport choice" {
    try std.testing.expectEqual(Profile.public, try parse("SCHEMA=R4OS_SERVER_CLIENT\nPROFILE=PUBLIC\n"));
    try std.testing.expectEqual(Profile.lan, try parse("SCHEMA=R4OS_SERVER_CLIENT\r\nPROFILE=LAN\r\n"));
    try std.testing.expectError(error.ProfileMissing, parse("SCHEMA=R4OS_SERVER_CLIENT\n"));
    try std.testing.expectError(error.ProfileInvalid, parse("SCHEMA=R4OS_SERVER_CLIENT\nPROFILE=AUTO\n"));
    try std.testing.expectError(error.ConfigInvalid, parse("SCHEMA=R4OS_SERVER_CLIENT\nPROFILE=LAN\nPROFILE=PUBLIC\n"));
}
