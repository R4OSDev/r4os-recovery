//! R4M0's two optional immutable app title colors; shared by manifest and packer.
const std = @import("std");
pub const background_key = "gui.title.background";
pub const foreground_key = "gui.title.foreground";
pub const Appearance = struct { flags: u32 = 0, background: u32 = 0, foreground: u32 = 0 };

fn rgb(text: []const u8) !u32 {
    if (text.len != 6) return error.InvalidTitleColor;
    var value: u32 = 0;
    for (text) |ch| {
        const digit: u32 = switch (ch) {
            '0'...'9' => ch - '0',
            'a'...'f' => ch - 'a' + 10,
            'A'...'F' => ch - 'A' + 10,
            else => return error.InvalidTitleColor,
        };
        value = (value << 4) | digit;
    }
    return value;
}

pub fn parse(entries: []const []const u8) !Appearance {
    var result: Appearance = .{};
    for (entries) |entry| {
        const eq = std.mem.indexOfScalar(u8, entry, '=') orelse {
            if (std.ascii.eqlIgnoreCase(entry, background_key) or std.ascii.eqlIgnoreCase(entry, foreground_key)) return error.InvalidTitleColor;
            continue;
        };
        const key = entry[0..eq];
        inline for (.{ background_key, foreground_key }, 0..) |expected, index| {
            if (std.ascii.eqlIgnoreCase(key, expected)) {
                if (!std.mem.eql(u8, key, expected)) return error.InvalidTitleColorKey;
                const bit: u32 = 1 << index;
                if (result.flags & bit != 0) return error.DuplicateTitleColor;
                const color = try rgb(entry[eq + 1 ..]);
                result.flags |= bit;
                if (index == 0) result.background = color else result.foreground = color;
            }
        }
    }
    return result;
}

test "immutable title colors distinguish missing black and invalid admission" {
    try std.testing.expectEqual(Appearance{}, try parse(&.{"feature=ordinary"}));
    try std.testing.expectEqual(Appearance{ .flags = 3, .background = 0, .foreground = 0xffeedd }, try parse(&.{ "gui.title.background=000000", "gui.title.foreground=FfEeDd" }));
    try std.testing.expectError(error.DuplicateTitleColor, parse(&.{ "gui.title.background=123456", "gui.title.background=123456" }));
    try std.testing.expectError(error.InvalidTitleColorKey, parse(&.{"GUI.title.foreground=ffffff"}));
    try std.testing.expectError(error.InvalidTitleColor, parse(&.{"gui.title.background"}));
    inline for (.{ "fff", "#ffffff", "12345g", "ffffff00", " ffffff", "ffffff " }) |bad| {
        try std.testing.expectError(error.InvalidTitleColor, parse(&.{"gui.title.background=" ++ bad}));
    }
}
