// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Class, shader target and immutable program bytes form one profile. Never
//! infer a shader ISA from PCI enumeration order or a marketing generation.
const std = @import("std");
const base = @import("Generated/Shaders/shaders.zig");
pub const Program = base.Program;
pub const Profile = struct {
    class: u32,
    sm: u16,
    compiler_id: [32]u8,
    compiler_abi: u32,
    resource_abi: u32,
    programs: []const Program,

    pub fn offset(self: Profile, index: usize) u32 {
        var result: u32 = 0;
        for (self.programs[0..index]) |item|
            result += std.mem.alignForward(u32, 128 + @as(u32, @intCast(item.code.len)), 128);
        return result;
    }
    pub fn bytes(self: Profile) u32 { return self.offset(self.programs.len); }
    pub fn program(self: Profile, id: u32) ?*const Program {
        for (self.programs) |*item| if (item.profile == id) return item;
        return null;
    }
};
fn from(comptime class: u32, comptime source: type) Profile {
    const converted = comptime blk: {
        var output: [source.programs.len]Program = undefined;
        for (source.programs, &output) |item, *target| {
            for (std.meta.fields(Program)) |field| @field(target, field.name) = @field(item, field.name);
        }
        break :blk output;
    };
    return .{ .class = class, .sm = source.sm, .compiler_id = source.compiler_id,
        .compiler_abi = source.compiler_abi, .resource_abi = source.resource_abi, .programs = &converted };
}
pub const catalog = [_]Profile{
    from(0xc597, @import("Generated/Shaders/SM75/shaders.zig")),
    from(0xc797, base),
    from(0xc997, @import("Generated/Shaders/SM89/shaders.zig")),
    from(0xcd97, @import("Generated/Shaders/SM120/shaders.zig")),
};
pub fn get(class: u32) ?Profile {
    for (catalog) |profile| if (profile.class == class) return profile;
    return null;
}
pub const max_bytes = blk: {
    var maximum: u32 = 0;
    for (catalog) |profile| maximum = @max(maximum, profile.bytes());
    break :blk maximum;
};
