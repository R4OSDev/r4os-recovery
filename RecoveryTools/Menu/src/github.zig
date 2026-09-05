// Release-channel policy; HTTP, DNS, TLS and JSON parsing use the shared SDK.
const std = @import("std");
const r4os = @import("r4os");
const package = @import("package.zig");
pub const Kind = package.Kind;
pub const Profile = enum { slim, full };
pub const max_metadata_bytes = 1024 * 1024;
pub const Asset = struct {
    kind: Kind,
    profile: Profile,
    version: []const u8,
    name: []const u8,
    url: []const u8,
    bytes: u64,
    sha256: [32]u8,
};
pub fn repository(kind: Kind) []const u8 {
    return if (kind == .r4os) "r4os-distribution" else "r4os-recovery";
}
pub fn api(kind: Kind) []const u8 {
    return if (kind == .r4os)
        "https://api.github.com/repos/R4OSDev/r4os-distribution/releases/latest"
    else
        "https://api.github.com/repos/R4OSDev/r4os-recovery/releases/latest";
}
pub fn allowTarget(_: ?*anyopaque, raw: []const u8) bool {
    const url = switch (r4os.http.parseUrl(raw)) {
        .value => |v| v,
        else => return false,
    };
    if (url.scheme != .https or url.port != 443) return false;
    for ([_][]const u8{ "api.github.com", "github.com", "release-assets.githubusercontent.com", "objects.githubusercontent.com", "github-releases.githubusercontent.com" }) |host|
        if (std.ascii.eqlIgnoreCase(url.host, host)) return true;
    return false;
}
pub fn select(allocator: std.mem.Allocator, bytes: []const u8, kind: Kind, profile: Profile) !Asset {
    if (bytes.len == 0 or bytes.len > max_metadata_bytes) return error.ReleaseMetadata;
    const Entry = struct {
        name: []const u8,
        browser_download_url: []const u8,
        state: []const u8,
        size: u64,
        digest: ?[]const u8 = null,
    };
    const Release = struct {
        tag_name: []const u8,
        draft: bool,
        prerelease: bool,
        published_at: ?[]const u8,
        assets: []const Entry,
    };
    const parsed = try std.json.parseFromSlice(Release, allocator, bytes, .{ .allocate = .alloc_always, .ignore_unknown_fields = true, .max_value_len = 8192 });
    // Returned strings belong to the caller's arena.
    const release = parsed.value;
    if (release.draft or release.prerelease or release.published_at == null or release.published_at.?.len == 0 or release.assets.len > 128) return error.NoCompatibleRelease;
    const version = if (std.mem.startsWith(u8, release.tag_name, "v")) release.tag_name[1..] else release.tag_name;
    if (version.len > 32 or r4os.version_info.parseSemanticVersion(version) == null) return error.NoCompatibleRelease;
    var name_buffer: [128]u8 = undefined;
    const wanted = if (kind == .r4os)
        try std.fmt.bufPrint(&name_buffer, "R4OS-{s}-{s}-x86_64.zip", .{ version, @tagName(profile) })
    else
        try std.fmt.bufPrint(&name_buffer, "R4OS-Recovery-{s}-x86_64.zip", .{version});
    var found: ?Asset = null;
    for (release.assets) |entry| {
        if (!std.mem.eql(u8, entry.name, wanted)) continue;
        if (found != null or !std.mem.eql(u8, entry.state, "uploaded") or entry.size < 22 or entry.size > package.max_archive_bytes) return error.ReleaseMetadata;
        const digest = entry.digest orelse return error.ReleaseMetadata;
        if (digest.len != 71 or !std.mem.startsWith(u8, digest, "sha256:")) return error.ReleaseMetadata;
        var sha256: [32]u8 = undefined;
        _ = std.fmt.hexToBytes(&sha256, digest[7..]) catch return error.ReleaseMetadata;
        var url_buffer: [512]u8 = undefined;
        const wanted_url = try std.fmt.bufPrint(&url_buffer, "https://github.com/R4OSDev/{s}/releases/download/{s}/{s}", .{ repository(kind), release.tag_name, wanted });
        if (!std.mem.eql(u8, entry.browser_download_url, wanted_url)) return error.ReleaseMetadata;
        found = .{ .kind = kind, .profile = profile, .version = version, .name = entry.name, .url = entry.browser_download_url, .bytes = entry.size, .sha256 = sha256 };
    }
    return found orelse error.NoCompatibleRelease;
}
pub fn matches(asset: Asset, prepared: *const package.Prepared) bool {
    if (asset.kind != prepared.kind or !std.mem.eql(u8, asset.version, prepared.version())) return false;
    if (prepared.system) |system| return std.mem.eql(u8, asset.name, system.asset) and std.mem.eql(u8, @tagName(asset.profile), system.profile);
    return true;
}

test "release selection binds stable channel, profile, asset name and digest" {
    const input =
        \\{"tag_name":"v0.76.25","draft":false,"prerelease":false,"published_at":"2026-09-05T00:00:00Z","ignored":1,"assets":[
        \\{"name":"Source.zip","state":"uploaded","size":100,"browser_download_url":"https://example.com/source"},
        \\{"name":"R4OS-0.76.25-full-x86_64.zip","state":"uploaded","size":100,"digest":"sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","browser_download_url":"https://github.com/R4OSDev/r4os-distribution/releases/download/v0.76.25/R4OS-0.76.25-full-x86_64.zip"}]}
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const asset = try select(a, input, .r4os, .full);
    try std.testing.expectEqualStrings("0.76.25", asset.version);
    try std.testing.expectEqual(@as(u8, 0xef), asset.sha256[31]);
    try std.testing.expectError(error.NoCompatibleRelease, select(a, input, .r4os, .slim));
    try std.testing.expectError(error.NoCompatibleRelease, select(a, input, .recovery, .full));
    for ([_][]const u8{ "\"draft\":false", "\"prerelease\":false" }) |field| {
        const replacement = try std.mem.replaceOwned(u8, a, field, "false", "true");
        const changed = try std.mem.replaceOwned(u8, a, input, field, replacement);
        try std.testing.expectError(error.NoCompatibleRelease, select(a, changed, .r4os, .full));
    }
    for ([_][]const u8{ "http://github.com/file", "https://github.com.evil.test/file", "https://evil.github.com/file", "https://user@github.com/file", "https://github.com:444/file" }) |url|
        try std.testing.expect(!allowTarget(null, url));
    try std.testing.expect(allowTarget(null, "https://release-assets.githubusercontent.com/abc?token=x"));
}
