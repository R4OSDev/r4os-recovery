const std = @import("std");
const path_contract = @import("path.zig");

/// Versioned applications may occupy an ordinary chosen directory. This is
/// a path classification only, never permission to overwrite an existing
/// file. Native replay capability, identity and lifecycle are checked later.
pub fn applicationTarget(value: []const u8) bool {
    var segments = std.mem.tokenizeAny(u8, value, "/\\");
    while (segments.next()) |segment| if (std.mem.eql(u8, segment, ".") or std.mem.eql(u8, segment, "..")) return false;
    var buffer: [1024]u8 = undefined;
    const native = if (value.len > 0 and value[0] == '/') std.fmt.bufPrint(&buffer, "C:{s}", .{value}) catch return false else value;
    const parsed = path_contract.AbsoluteFilePath.parse(native) catch return false;
    const path = parsed.bytes();
    return std.ascii.endsWithIgnoreCase(path, ".R4X") and
        !std.ascii.startsWithIgnoreCase(path, "C:\\BOOT\\");
}

// Package companions have no separate installed component identity. Boot
// preloads mirror the separately versioned protocol/driver components.
// The same scope must be understood by packer, updater and early recovery.
pub const CompanionKind = enum { license, source, preload };
pub const companion_recovery_kernel = "0.1.199";
pub const preload_recovery_kernel = "0.1.208";

pub fn companionKind(path: []const u8) ?CompanionKind {
    if (preloadTarget(path)) return .preload;
    const scopes = .{
        .{ "C:/R4OS/LICENSES/", CompanionKind.license },
        .{ "C:/R4OS/SOURCES/", CompanionKind.source },
    };
    inline for (scopes) |scope| {
        const prefix = scope[0];
        if (path.len > prefix.len and samePath(path[0..prefix.len], prefix)) {
            var parts = std.mem.tokenizeAny(u8, path[prefix.len..], "/\\");
            while (parts.next()) |part| {
                if (std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..") or
                    part[part.len - 1] == '.' or part[part.len - 1] == ' ') return null;
                for (part) |byte| {
                    if (byte < 0x20 or byte >= 0x7f or
                        std.mem.indexOfScalar(u8, "\"*:;<>?|", byte) != null) return null;
                }
            }
            if (path[path.len - 1] == '/' or path[path.len - 1] == '\\') return null;
            return scope[1];
        }
    }
    return null;
}

fn samePath(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        const l = if (left == '\\') '/' else std.ascii.toUpper(left);
        const r = if (right == '\\') '/' else std.ascii.toUpper(right);
        if (l != r) return false;
    }
    return true;
}

/// Exact managed boot leaves only; no bootloader/configuration or arbitrary
/// BOOT path enters the update journal through this companion kind.
pub fn preloadTarget(path: []const u8) bool {
    for ([_][]const u8{ "/boot/preload.r4i", "/boot/preload/hidreport.r4p", "/boot/preload/usbhid.r4p", "/boot/preload/usbbot.r4p", "/boot/preload/usbscsi.r4p" }) |target|
        if (samePath(path, target)) return true;
    return false;
}

test "application update targets preserve chosen paths and reject boot, traversal and invalid Unicode" {
    for ([_][]const u8{ "C:\\Games\\Solitaire\\SOLITAIRE_7A292B66.R4X", "D:\\Apps\\Grüße\\APP.R4X", "/Games/APP.R4X" }) |value|
        try std.testing.expect(applicationTarget(value));
    for ([_][]const u8{ "C:\\BOOT\\APP.R4X", "/boot/APP.R4X", "C:\\Apps\\..\\APP.R4X", "C:\\Apps\\\xff.R4X", "C:\\Apps\\DATA.TXT", "relative.R4X" }) |value|
        try std.testing.expect(!applicationTarget(value));
}
