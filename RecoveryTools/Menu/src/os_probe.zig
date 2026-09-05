// Best-effort readable markers, never update authorization or code execution.
const std = @import("std");
pub const Names = packed struct(u8) {
    windows: bool = false,
    linux: bool = false,
    r4os: bool = false,
    reserved: u5 = 0,
    pub fn merge(self: *Names, other: Names) void {
        self.windows = self.windows or other.windows;
        self.linux = self.linux or other.linux;
        self.r4os = self.r4os or other.r4os;
    }
    pub fn text(self: Names, out: []u8) []const u8 {
        var used: usize = 0;
        for ([_]bool{ self.windows, self.linux, self.r4os }, [_][]const u8{ "Windows", "Linux", "R4OS" }) |found, name| {
            if (!found) continue;
            const comma: []const u8 = if (used == 0) "" else ", ";
            if (used + comma.len + name.len > out.len) break;
            @memcpy(out[used..][0..comma.len], comma);
            used += comma.len;
            @memcpy(out[used..][0..name.len], name);
            used += name.len;
        }
        return out[0..used];
    }
};
pub const Probe = struct {
    context: *anyopaque,
    read_at: *const fn (*anyopaque, []const u8, u32, []u8) ?usize,
    entry: *const fn (*anyopaque, []const u8, u32, []u8) ?[]const u8,

    fn signature(self: Probe, path: []const u8, offset: u32, expected: []const u8) bool {
        var buffer: [16]u8 = undefined;
        const got = self.read_at(self.context, path, offset, buffer[0..expected.len]) orelse return false;
        return got == expected.len and std.mem.eql(u8, buffer[0..got], expected);
    }
    fn linuxKernel(self: Probe, path: []const u8) bool {
        // Linux x86 boot protocol, not a filename/GRUB/EFI vendor guess.
        return self.signature(path, 0x1fe, "\x55\xaa") and self.signature(path, 0x202, "HdrS");
    }
    pub fn detect(self: Probe) Names {
        var result = Names{};
        result.windows = (self.signature("Windows\\System32\\ntoskrnl.exe", 0, "MZ") and
            self.signature("Windows\\System32\\config\\SYSTEM", 0, "regf")) or
            (self.signature("EFI\\Microsoft\\Boot\\bootmgfw.efi", 0, "MZ") and self.signature("EFI\\Microsoft\\Boot\\BCD", 0, "regf"));
        result.linux = self.linuxKernel("vmlinuz") or self.linuxKernel("boot\\vmlinuz");
        var name_buffer: [256]u8 = undefined;
        var path_buffer: [280]u8 = undefined;
        if (!result.linux) for (0..64) |i| {
            const name = self.entry(self.context, "boot", @intCast(i), &name_buffer) orelse break;
            if (!std.mem.startsWith(u8, name, "vmlinuz") and !std.mem.startsWith(u8, name, "bzImage")) continue;
            if (std.mem.indexOfAny(u8, name, "\\/:") != null) continue;
            const path = std.fmt.bufPrint(&path_buffer, "boot\\{s}", .{name}) catch continue;
            if (self.linuxKernel(path)) {
                result.linux = true;
                break;
            }
        };
        var version: [256]u8 = undefined;
        if (self.read_at(self.context, "R4OS\\CONFIG\\VERSION.R4S", 0, &version)) |size| {
            var lines = std.mem.splitScalar(u8, version[0..size], '\n');
            while (lines.next()) |raw| {
                const line = std.mem.trim(u8, raw, "\xef\xbb\xbf \r\t");
                const prefix = "RELEASE_VERSION=";
                if (!std.mem.startsWith(u8, line, prefix)) continue;
                var parts = std.mem.splitScalar(u8, line[prefix.len..], '.');
                var count: usize = 0;
                var valid = true;
                while (parts.next()) |p| {
                    count += 1;
                    if (p.len == 0) valid = false;
                    for (p) |c| if (!std.ascii.isDigit(c)) {
                        valid = false;
                    };
                }
                result.r4os = valid and count == 3 and self.signature("R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X", 0, "R4M0");
            }
        }
        return result;
    }
};

test "multiple readable OS markers aggregate; labels and unreadable files stay blank" {
    const Fixture = struct {
        strong: bool = false,
        fn read(ctx: *anyopaque, path: []const u8, offset: u32, out: []u8) ?usize {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            const bytes: []const u8 = if (std.mem.eql(u8, path, "R4OS\\CONFIG\\VERSION.R4S")) "RELEASE_VERSION=0.76.14\n" else if (!self.strong) return null else if (std.mem.endsWith(u8, path, "ntoskrnl.exe")) "MZ" else if (std.mem.endsWith(u8, path, "config\\SYSTEM")) "regf" else if (std.mem.endsWith(u8, path, "TERMINAL.R4X")) "R4M0" else if (std.mem.eql(u8, path, "vmlinuz") and offset == 0x1fe) "\x55\xaa" else if (std.mem.eql(u8, path, "vmlinuz") and offset == 0x202) "HdrS" else return null;
            const n = @min(bytes.len, out.len);
            @memcpy(out[0..n], bytes[0..n]);
            return n;
        }
        fn entry(_: *anyopaque, _: []const u8, _: u32, _: []u8) ?[]const u8 {
            return null;
        }
    };
    var fixture = Fixture{};
    const probe = Probe{ .context = &fixture, .read_at = Fixture.read, .entry = Fixture.entry };
    var text: [32]u8 = undefined;
    try std.testing.expectEqualStrings("", probe.detect().text(&text));
    fixture.strong = true;
    try std.testing.expectEqualStrings("Windows, Linux, R4OS", probe.detect().text(&text));
}
