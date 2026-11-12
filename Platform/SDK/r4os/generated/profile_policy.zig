// Generated from Profiles/Build.json by Tools/Sync-ProfilePolicy.ps1. DO NOT EDIT.
pub const source_sha256 = "7435a451cc58d6d3220d4c54a576b1702f3d34ae8f8b0290f83e1a98c3bd516f";
pub const Profile = struct { id: []const u8, language: []const u8, role: []const u8, kind: []const u8, generation: u8, explicit_platform: bool };
pub const profiles = [_]Profile{
    .{ .id = "r4os-c-generation2", .language = "C", .role = "module", .kind = "R4X", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-c-module-v1", .language = "C", .role = "module", .kind = "", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-c-r4d-generation2", .language = "C", .role = "module", .kind = "R4D", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-c-r4p-generation2", .language = "C", .role = "module", .kind = "R4P", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-host-tools-v1", .language = "Zig", .role = "host", .kind = "", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-kernel-rust-v1", .language = "Rust", .role = "kernel", .kind = "", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-native-graphics-v1", .language = "C++", .role = "native", .kind = "", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-recovery-zig-v1", .language = "Zig", .role = "recovery", .kind = "", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-rust-generation2", .language = "Rust", .role = "module", .kind = "R4X", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-rust-r4d-generation2", .language = "Rust", .role = "module", .kind = "R4D", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-rust-r4d-v1", .language = "Rust", .role = "module", .kind = "R4D", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-rust-r4l-v1", .language = "Rust", .role = "module", .kind = "R4L", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-rust-r4p-generation2", .language = "Rust", .role = "module", .kind = "R4P", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-rust-r4p-v1", .language = "Rust", .role = "module", .kind = "R4P", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-rust-r4x-lowlevel-v1", .language = "Rust", .role = "module", .kind = "R4X", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-rust-r4x-v2", .language = "Rust", .role = "module", .kind = "R4X", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-zig-generation2", .language = "Zig", .role = "module", .kind = "R4X", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-zig-module-v1", .language = "Zig", .role = "module", .kind = "", .generation = 1, .explicit_platform = false },
    .{ .id = "r4os-zig-r4d-generation2", .language = "Zig", .role = "module", .kind = "R4D", .generation = 2, .explicit_platform = true },
    .{ .id = "r4os-zig-r4p-generation2", .language = "Zig", .role = "module", .kind = "R4P", .generation = 2, .explicit_platform = true },
};
pub const ModuleDefault = struct { language: []const u8, kind: []const u8, entry: []const u8, profile: []const u8 };
pub const module_defaults = [_]ModuleDefault{
    .{ .language = "Zig", .kind = "R4X", .entry = "", .profile = "r4os-zig-module-v1" },
    .{ .language = "Zig", .kind = "R4L", .entry = "", .profile = "r4os-zig-module-v1" },
    .{ .language = "Zig", .kind = "R4D", .entry = "", .profile = "r4os-zig-module-v1" },
    .{ .language = "Zig", .kind = "R4P", .entry = "", .profile = "r4os-zig-module-v1" },
    .{ .language = "C", .kind = "R4X", .entry = "", .profile = "r4os-c-module-v1" },
    .{ .language = "C", .kind = "R4L", .entry = "", .profile = "r4os-c-module-v1" },
    .{ .language = "C", .kind = "R4D", .entry = "", .profile = "r4os-c-module-v1" },
    .{ .language = "C", .kind = "R4P", .entry = "", .profile = "r4os-c-module-v1" },
    .{ .language = "Rust", .kind = "R4X", .entry = "app", .profile = "r4os-rust-r4x-v2" },
    .{ .language = "Rust", .kind = "R4X", .entry = "lowlevel", .profile = "r4os-rust-r4x-lowlevel-v1" },
    .{ .language = "Rust", .kind = "R4L", .entry = "", .profile = "r4os-rust-r4l-v1" },
    .{ .language = "Rust", .kind = "R4D", .entry = "", .profile = "r4os-rust-r4d-v1" },
    .{ .language = "Rust", .kind = "R4P", .entry = "", .profile = "r4os-rust-r4p-v1" },
};
