//! Update compatibility policy, independent of rendering and disk writes.
//! Preserve the user's bytes; require an unambiguous canonical R4OS entry.
const std = @import("std");
const setup = @import("r4os").storage_tools.installation;
const strings = [_][]const u8{
    "r4os.preload.image=PRELOAD.R4I",
    "r4os.preload.usb-r4p=HIDREPORT",
    "r4os.preload.usb-r4p=USBHID",
    "r4os.preload.usb-r4p=USBBOT",
    "r4os.preload.usb-r4p=USBSCSI",
};
const Entry = struct {
    protocol: []const u8 = "",
    path: []const u8 = "",
    modules: [5][]const u8 = .{""} ** 5,
    labels: [5][]const u8 = .{""} ** 5,
    count: usize = 0,
    invalid: bool = false,

    fn valid(self: Entry, boot: [16]u8) bool {
        if (self.invalid or !std.ascii.eqlIgnoreCase(self.protocol, "limine") or
            !reference(self.path, boot, setup.boot_paths[0]) or self.count != 5) return false;
        var seen: [5]bool = .{false} ** 5;
        for (self.modules, self.labels) |path, label| {
            var found = false;
            for (strings, 0..) |expected, i| if (reference(path, boot, setup.boot_paths[i + 1]) and std.mem.eql(u8, label, expected)) {
                if (seen[i]) return false;
                seen[i] = true;
                found = true;
            };
            if (!found) return false;
        }
        return true;
    }
};
fn reference(actual: []const u8, boot: [16]u8, path: []const u8) bool {
    var buffer: [320]u8 = undefined;
    const expected = std.fmt.bufPrint(&buffer, "guid({s}):/{s}", .{ setup.guid.format(boot), path }) catch return false;
    return std.ascii.eqlIgnoreCase(actual, expected);
}

pub fn verify(config: []const u8, boot: [16]u8) !void {
    if (config.len == 0 or config.len > 64 * 1024 or std.mem.indexOfScalar(u8, config, 0) != null) return error.IncompatibleBootConfig;
    var entry = Entry{};
    var matched: usize = 0;
    var lines = std.mem.splitScalar(u8, config, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        if (line[0] == '/') {
            if (entry.valid(boot)) matched += 1;
            entry = .{};
            continue;
        }
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const key = std.mem.trim(u8, line[0..colon], " \t");
        const value = std.mem.trim(u8, line[colon + 1 ..], " \t");
        if (std.ascii.eqlIgnoreCase(key, "protocol")) {
            if (entry.protocol.len != 0) entry.invalid = true;
            entry.protocol = value;
        } else if (std.ascii.eqlIgnoreCase(key, "path")) {
            if (entry.path.len != 0) entry.invalid = true;
            entry.path = value;
        } else if (std.ascii.eqlIgnoreCase(key, "module_path")) {
            if (entry.count >= 5) {
                entry.invalid = true;
            } else {
                entry.modules[entry.count] = value;
                entry.count += 1;
            }
        } else if (std.ascii.eqlIgnoreCase(key, "module_string")) {
            if (entry.count == 0 or entry.labels[entry.count - 1].len != 0) entry.invalid = true else entry.labels[entry.count - 1] = value;
        }
    }
    if (entry.valid(boot)) matched += 1;
    if (matched == 0) return error.IncompatibleBootConfig;
}

test "custom menu bytes are accepted; wrong GUID or mixed preload is refused" {
    const a = std.testing.allocator;
    var entropy: [7][16]u8 = .{.{0} ** 16} ** 7;
    for (&entropy, 0..) |*id, i| id[0] = @intCast(i + 1);
    const layout = try setup.Layout.prepare(4194304, 512, try setup.Identifiers.fromEntropy(entropy));
    const base = try layout.limineConfig(a, .local);
    defer a.free(base);
    const custom = try std.fmt.allocPrint(a, "# Keep my configuration\r\n{s}\n/Other OS\nprotocol: efi\npath: boot():/EFI/Other/start.efi\n", .{base});
    defer a.free(custom);
    try verify(custom, layout.ids.partitions[1]);
    try std.testing.expectError(error.IncompatibleBootConfig, verify(custom, layout.ids.partitions[2]));
    const at = std.mem.indexOf(u8, custom, "usb-r4p=HIDREPORT").?;
    custom[at] = 'x';
    try std.testing.expectError(error.IncompatibleBootConfig, verify(custom, layout.ids.partitions[1]));
}
