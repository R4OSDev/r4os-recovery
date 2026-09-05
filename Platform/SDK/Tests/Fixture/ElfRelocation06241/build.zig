const std = @import("std");

pub fn build(b: *std.Build) void {
    addFixture(b, "reloc-pic.elf", true, &.{"-fPIC"});
    addFixture(b, "reloc-large.elf", false, &.{
        "-fno-pic",
        "-mcmodel=large",
    });
}

fn addFixture(b: *std.Build, name: []const u8, pic: bool, model_flags: []const []const u8) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
    });
    const module = b.createModule(.{
        .target = target,
        .optimize = .ReleaseFast,
        .strip = false,
        .pic = pic,
        .red_zone = false,
        .sanitize_c = .off,
        .stack_check = false,
        .stack_protector = false,
        .link_libc = false,
    });

    const common_flags: []const []const u8 = &.{
        "-std=c11",
        "-ffreestanding",
        "-fno-builtin",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-fno-asynchronous-unwind-tables",
        "-mno-red-zone",
    };
    const flags = b.allocator.alloc([]const u8, common_flags.len + model_flags.len) catch @panic("OOM");
    @memcpy(flags[0..common_flags.len], common_flags);
    @memcpy(flags[common_flags.len..], model_flags);
    module.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{ "consumer.c", "provider.c" },
        .flags = flags,
    });

    const exe = b.addExecutable(.{ .name = name, .root_module = module });
    exe.entry = .{ .symbol_name = "R4XStart" };
    exe.link_emit_relocs = true;
    exe.setLinkerScript(b.path("../../../r4os/linker/r4os_module.ld"));
    b.installArtifact(exe);
}
