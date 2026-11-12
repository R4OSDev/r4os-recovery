const std = @import("std");
const r4sys = @import("r4sys.zig");
const server_profile = @import("server_profile.zig");
const server_targets = @import("server_targets.zig");
const storage = @import("app_storage.zig");

pub const public_path: [*:0]const u8 = "C:\\R4OS\\SECRETS\\PUBLIC.R4S";
pub const bootstrap_url = "https://138.201.253.143:4022/api/v1/registration/bootstrap";
pub const bootstrap_content_type = "application/vnd.r4os.registration-v1";

pub const Kind = enum {
    registration,
    benchmark_bearer,
};

pub const Error = error{
    CredentialsMissing,
    CredentialsInvalid,
    SecretMissing,
    SecretInvalid,
    CredentialsConflict,
    CredentialsWrite,
};

pub const Secret = struct {
    data: [256]u8 = .{0} ** 256,
    len: u16 = 0,

    pub fn bytes(self: *const Secret) []const u8 {
        return self.data[0..self.len];
    }

    pub fn clear(self: *Secret) void {
        std.crypto.secureZero(u8, &self.data);
        self.len = 0;
    }
};

/// Operator credentials are local and absent from the default image.
/// Automatically issued public credentials live separately; callers clear both.
pub fn load(ctx: *const r4sys.Context, kind: Kind) Error!Secret {
    var document: [1024]u8 = undefined;
    defer std.crypto.secureZero(u8, &document);
    const count = ctx.fileRead(server_profile.credentials_path, &document);
    if (count == -3) return error.CredentialsMissing;
    if (count <= 0 or count >= document.len) return error.CredentialsInvalid;
    return parse(document[0..@intCast(count)], kind);
}

pub fn parse(document: []const u8, kind: Kind) Error!Secret {
    var data = document;
    if (std.mem.startsWith(u8, data, "\xef\xbb\xbf")) data = data[3..];
    const wanted = switch (kind) {
        .registration => "REGISTRATION_SECRET",
        .benchmark_bearer => "BENCHMARK_BEARER",
    };
    var schema_seen = false;
    var selected: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, "\r");
        if (line.len == 0 or line[0] == '#') continue;
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse return error.CredentialsInvalid;
        const key = line[0..separator];
        const value = line[separator + 1 ..];
        if (std.mem.eql(u8, key, "SCHEMA")) {
            if (schema_seen or !std.mem.eql(u8, value, "R4OS_SERVER_CREDENTIALS")) return error.CredentialsInvalid;
            schema_seen = true;
        } else if (std.mem.eql(u8, key, wanted)) {
            if (selected != null) return error.CredentialsInvalid;
            selected = value;
        }
    }
    if (!schema_seen) return error.CredentialsInvalid;
    const value = selected orelse return error.SecretMissing;
    if (value.len == 0 or value.len > 256) return error.SecretInvalid;
    for (value) |byte| {
        if (byte < 0x21 or byte > 0x7e) return error.SecretInvalid;
    }
    var secret: Secret = .{};
    @memcpy(secret.data[0..value.len], value);
    secret.len = @intCast(value.len);
    return secret;
}

test "server credentials are local, explicit and bounded" {
    var secret = try parse("SCHEMA=R4OS_SERVER_CREDENTIALS\nREGISTRATION_SECRET=sample-secret\n", .registration);
    defer secret.clear();
    try std.testing.expectEqualStrings("sample-secret", secret.bytes());
    try std.testing.expectError(error.SecretMissing, parse("SCHEMA=R4OS_SERVER_CREDENTIALS\n", .benchmark_bearer));
    try std.testing.expectError(error.SecretInvalid, parse("SCHEMA=R4OS_SERVER_CREDENTIALS\nBENCHMARK_BEARER=bad token\n", .benchmark_bearer));
}

/// Automatic issuance is restricted to official PUBLIC endpoints. A custom
/// address/port never silently falls back to the public service.
pub fn publicBootstrapAllowed(profile: server_profile.Profile, target: server_targets.Target, component: server_targets.Component) bool {
    const port: u16 = switch (component) {
        .app_center => 4022,
        .updates => 4023,
        .benchmarks => 4024,
    };
    return profile == .public and target.port == port and std.mem.eql(u8, target.host(), server_targets.default_ip);
}

pub fn loadPublic(ctx: *const r4sys.Context) Error!Secret {
    var document: [512]u8 = undefined;
    defer std.crypto.secureZero(u8, &document);
    const count = ctx.fileRead(public_path, &document);
    if (count == -3) return error.CredentialsMissing;
    if (count <= 0 or count >= document.len) return error.CredentialsInvalid;
    return parsePublic(document[0..@intCast(count)]);
}

/// Exact versioned read-registration document; role/bearer fields are rejected.
pub fn parsePublic(document: []const u8) Error!Secret {
    if (document.len == 0 or document.len >= 512) return error.CredentialsInvalid;
    var seen: u8 = 0;
    var selected: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, document, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.CredentialsInvalid;
        const key = line[0..eq];
        const value = line[eq + 1 ..];
        const bit: u8 = if (std.mem.eql(u8, key, "SCHEMA") and std.mem.eql(u8, value, "R4OS_PUBLIC_REGISTRATION")) 1 else if (std.mem.eql(u8, key, "VERSION") and std.mem.eql(u8, value, "1")) 2 else if (std.mem.eql(u8, key, "SCOPE") and std.mem.eql(u8, value, "REGISTRATION_READ")) 4 else if (std.mem.eql(u8, key, "REGISTRATION_SECRET")) 8 else return error.CredentialsInvalid;
        if (seen & bit != 0) return error.CredentialsInvalid;
        seen |= bit;
        if (bit == 8) selected = value;
    }
    if (seen != 15) return error.CredentialsInvalid;
    const value = selected.?;
    if (value.len != 69 or !std.mem.startsWith(u8, value, "R4C1_")) return error.SecretInvalid;
    for (value[5..]) |c| if (!std.ascii.isDigit(c) and !(c >= 'a' and c <= 'f')) return error.SecretInvalid;
    var secret: Secret = .{};
    @memcpy(secret.data[0..value.len], value);
    secret.len = @intCast(value.len);
    return secret;
}

/// Same-directory owned create-only publication. Never replaces operator data
/// or an existing PUBLIC.R4S, even if another creator wins during this write.
pub fn persistPublic(files: anytype, document: []const u8, nonce: u64) Error!void {
    var secret = try parsePublic(document);
    defer secret.clear();
    const target = storage.AbsoluteFilePath.parse(std.mem.span(public_path)) catch unreachable;
    switch (files.info(target.asZ())) {
        .missing => {},
        else => return error.CredentialsConflict,
    }
    const directory = storage.AbsoluteFilePath.parse("C:\\R4OS\\SECRETS") catch unreachable;
    switch (files.info(directory.asZ())) {
        .value => |info| if (info.is_dir == 0) return error.CredentialsWrite,
        .missing => if (files.createDirectory(directory.asZ()) != .ok) return error.CredentialsWrite,
        .failure => return error.CredentialsWrite,
    }
    var stage_buffer: [96]u8 = undefined;
    var backup_buffer: [96]u8 = undefined;
    // Atomic replacement requires 8.3 names for its temporary entries.
    // Create-only admission and the owned stream retain exact file identity.
    const temporary_id: u20 = @truncate(nonce);
    const stage_text = std.fmt.bufPrint(&stage_buffer, "C:\\R4OS\\SECRETS\\PUB{X}.NEW", .{temporary_id}) catch unreachable;
    const backup_text = std.fmt.bufPrint(&backup_buffer, "C:\\R4OS\\SECRETS\\PUB{X}.BAK", .{temporary_id}) catch unreachable;
    const stage = storage.AbsoluteFilePath.parse(stage_text) catch unreachable;
    const backup = storage.AbsoluteFilePath.parse(backup_text) catch unreachable;
    var writer = switch (files.ownedCreateWriter(stage.asZ())) {
        .writer => |value| value,
        .failure => return error.CredentialsWrite,
    };
    defer _ = writer.abort();
    if (writer.write(document) != .ok or writer.finishKeepOwnership() != .ok) return error.CredentialsWrite;
    switch (files.replaceAtomic(target.asZ(), stage.asZ(), backup.asZ(), .{
        .consume_stage = true,
        .require_target_absent = true,
        .require_owned_stage = true,
    })) {
        .ok => {},
        .conflict => return error.CredentialsConflict,
        else => return error.CredentialsWrite,
    }
    var readback: [512]u8 = undefined;
    defer std.crypto.secureZero(u8, &readback);
    const count = switch (files.read(target.asZ(), &readback)) {
        .bytes => |n| n,
        else => return error.CredentialsWrite,
    };
    if (count != document.len or !std.mem.eql(u8, readback[0..count], document)) return error.CredentialsWrite;
}

test "server credentials public issuance is strict and endpoint bounded" {
    const document = "SCHEMA=R4OS_PUBLIC_REGISTRATION\nVERSION=1\nSCOPE=REGISTRATION_READ\nREGISTRATION_SECRET=R4C1_" ++ "a" ** 64 ++ "\n";
    var secret = try parsePublic(document);
    defer secret.clear();
    try std.testing.expectEqual(@as(usize, 69), secret.bytes().len);
    try std.testing.expectError(error.CredentialsInvalid, parsePublic(document ++ "BENCHMARK_BEARER=forbidden\n"));
    try std.testing.expectError(error.CredentialsInvalid, parsePublic(document ++ "VERSION=1\n"));
    try std.testing.expectError(error.CredentialsInvalid, parsePublic("SCHEMA=R4OS_PUBLIC_REGISTRATION\nVERSION=2\n"));
    try std.testing.expectError(error.SecretInvalid, parsePublic("SCHEMA=R4OS_PUBLIC_REGISTRATION\nVERSION=1\nSCOPE=REGISTRATION_READ\nREGISTRATION_SECRET=R4C1_bad\n"));
    var target = server_targets.Target{ .ip = .{ .octets = .{ 138, 201, 253, 143 } }, .ip_text = "138.201.253.143".*, .ip_len = 15, .port = 4022 };
    try std.testing.expect(publicBootstrapAllowed(.public, target, .app_center));
    try std.testing.expect(!publicBootstrapAllowed(.lan, target, .app_center));
    target.port = 443;
    try std.testing.expect(!publicBootstrapAllowed(.public, target, .app_center));
    target.port = 4022;
    target.ip_text[0] = '1';
    target.ip_text[1] = '2';
    try std.testing.expect(!publicBootstrapAllowed(.public, target, .app_center));
}

test "server credentials publish preserves existing data on failures and races" {
    const Fake = struct {
        const Self = @This();
        target: [512]u8 = undefined,
        target_len: usize = 0,
        stage: [512]u8 = undefined,
        stage_len: usize = 0,
        fail_write: bool = false,
        fail_commit: bool = false,
        race: bool = false,
        aborted: u32 = 0,
        stage_name_length: usize = 0,
        backup_name_length: usize = 0,
        const Writer = struct {
            owner: *Self,
            pub fn write(w: *@This(), bytes: []const u8) storage.Operation {
                if (w.owner.fail_write) return .{ .failure = -7 };
                @memcpy(w.owner.stage[0..bytes.len], bytes);
                w.owner.stage_len = bytes.len;
                return .ok;
            }
            pub fn finishKeepOwnership(_: *@This()) storage.Operation {
                return .ok;
            }
            pub fn abort(w: *@This()) storage.Operation {
                w.owner.stage_len = 0;
                w.owner.aborted += 1;
                return .ok;
            }
        };
        pub fn info(self: *Self, name: storage.PathZ) storage.FileInfoResult {
            var value = std.mem.zeroes(@import("r4os_contract").abi.FileInfo);
            value.exists = 1;
            if (std.mem.eql(u8, name.bytes(), "C:\\R4OS\\SECRETS")) {
                value.is_dir = 1;
                return .{ .value = value };
            }
            if (self.target_len == 0) return .missing;
            return .{ .value = value };
        }
        pub fn createDirectory(_: *Self, _: storage.PathZ) storage.Operation {
            return .ok;
        }
        pub fn ownedCreateWriter(self: *Self, name: storage.PathZ) union(enum) { writer: Writer, failure: i32 } {
            self.stage_name_length = name.bytes().len - "C:\\R4OS\\SECRETS\\".len;
            return .{ .writer = .{ .owner = self } };
        }
        pub fn replaceAtomic(self: *Self, _: storage.PathZ, _: storage.PathZ, backup: storage.PathZ, options: storage.AtomicReplaceOptions) storage.AtomicReplaceResult {
            std.debug.assert(options.consume_stage and options.require_target_absent and options.require_owned_stage);
            self.backup_name_length = backup.bytes().len - "C:\\R4OS\\SECRETS\\".len;
            if (self.race) {
                @memcpy(self.target[0..7], "foreign");
                self.target_len = 7;
                return .conflict;
            }
            if (self.fail_commit) return .{ .failure = -7 };
            @memcpy(self.target[0..self.stage_len], self.stage[0..self.stage_len]);
            self.target_len = self.stage_len;
            return .ok;
        }
        pub fn read(self: *Self, _: storage.PathZ, out: []u8) storage.Transfer {
            @memcpy(out[0..self.target_len], self.target[0..self.target_len]);
            return .{ .bytes = @intCast(self.target_len) };
        }
    };
    const document = "SCHEMA=R4OS_PUBLIC_REGISTRATION\nVERSION=1\nSCOPE=REGISTRATION_READ\nREGISTRATION_SECRET=R4C1_" ++ "b" ** 64 ++ "\n";
    var good: Fake = .{};
    try persistPublic(&good, document, 0x1234_5678_89ab_cdef);
    try std.testing.expectEqual(@as(usize, 12), good.stage_name_length);
    try std.testing.expectEqual(@as(usize, 12), good.backup_name_length);
    try std.testing.expectEqualStrings(document, good.target[0..good.target_len]);
    try std.testing.expectEqual(@as(u32, 1), good.aborted);
    try std.testing.expectError(error.CredentialsConflict, persistPublic(&good, document, 11));
    try std.testing.expectEqualStrings(document, good.target[0..good.target_len]);
    for ([_]Fake{ .{ .fail_write = true }, .{ .fail_commit = true }, .{ .race = true } }) |scenario| {
        var fs = scenario;
        if (fs.race) {
            try std.testing.expectError(error.CredentialsConflict, persistPublic(&fs, document, 12));
            try std.testing.expectEqualStrings("foreign", fs.target[0..fs.target_len]);
        } else {
            try std.testing.expectError(error.CredentialsWrite, persistPublic(&fs, document, 12));
            try std.testing.expectEqual(@as(usize, 0), fs.target_len);
        }
        try std.testing.expectEqual(@as(usize, 0), fs.stage_len);
        try std.testing.expectEqual(@as(u32, 1), fs.aborted);
    }
}
