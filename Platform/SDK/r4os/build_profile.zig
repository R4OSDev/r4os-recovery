//! SDK-owned build data, interpreted for the host build graph.
const std = @import("std");
const source = @embedFile("../Profiles/Build.json");

pub fn load(allocator: std.mem.Allocator) std.json.Value {
    const value = std.json.parseFromSliceLeaky(std.json.Value, allocator, source, .{}) catch
        @panic("SdkProfileInvalidBuildJson");
    if (get(value, "schema").integer != 1) @panic("SdkProfileSchemaMismatch");
    return value;
}

pub fn get(object: std.json.Value, key: []const u8) std.json.Value {
    return object.object.get(key) orelse @panic("SdkProfileMissingField");
}

pub fn codegen(allocator: std.mem.Allocator, id: []const u8) std.json.Value {
    return get(get(load(allocator), "codegen"), id);
}

fn optimize(value: std.json.Value) std.builtin.OptimizeMode {
    return std.meta.stringToEnum(std.builtin.OptimizeMode, value.string) orelse
        @panic("SdkProfileInvalidOptimization");
}

// Alignment uses offsets, so parsing scalars at comptime never converts a
// compile-time buffer pointer to a runtime integer. No allocated slice escapes.
const CompileStorage = struct {
    bytes: [512 * 1024]u8 align(64) = undefined,
    used: usize = 0,

    fn allocate(context: *anyopaque, length: usize, alignment: std.mem.Alignment, _: usize) ?[*]u8 {
        const self: *CompileStorage = @ptrCast(@alignCast(context));
        const offset = std.mem.alignForward(usize, self.used, alignment.toByteUnits());
        if (offset > self.bytes.len or length > self.bytes.len - offset) return null;
        self.used = offset + length;
        return self.bytes[offset..].ptr;
    }

    fn allocator(self: *CompileStorage) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &.{
            .alloc = allocate,
            .resize = std.mem.Allocator.noResize,
            .remap = std.mem.Allocator.noRemap,
            .free = std.mem.Allocator.noFree,
        } };
    }
};

const StaticBuild = struct {
    schema: u32,
    codegen: struct {
        module: struct {
            pic: bool,
            red_zone: bool,
            single_threaded: bool,
            strip: bool,
            stack_check: bool,
            stack_protector: bool,
            sanitize_c: std.zig.SanitizeC,
            link_emit_relocs: bool,
            link_gc_sections: bool,
            bundle_compiler_rt: bool,
            link_libc: bool,
            optimization: struct { default: enum { size, speed }, size: std.builtin.OptimizeMode, speed: std.builtin.OptimizeMode },
        },
        runtime: struct { optimize: std.builtin.OptimizeMode },
        host: struct { optimize: std.builtin.OptimizeMode, debug_optimize: std.builtin.OptimizeMode, packager_optimize: std.builtin.OptimizeMode },
    },
};

pub const defaults = blk: {
    @setEvalBranchQuota(3_000_000);
    var storage: CompileStorage = .{};
    const root = std.json.parseFromSliceLeaky(StaticBuild, storage.allocator(), source, .{ .ignore_unknown_fields = true }) catch
        @panic("SdkProfileInvalidBuildDefaults");
    if (root.schema != 1) @panic("SdkProfileSchemaMismatch");
    const module = root.codegen.module;
    break :blk .{
        .pic = module.pic,
        .red_zone = module.red_zone,
        .single_threaded = module.single_threaded,
        .strip = module.strip,
        .stack_check = module.stack_check,
        .stack_protector = module.stack_protector,
        .link_gc_sections = module.link_gc_sections,
        .bundle_compiler_rt = module.bundle_compiler_rt,
        .link_libc = module.link_libc,
        .sanitize_c = module.sanitize_c,
        .emit_relocs = module.link_emit_relocs,
        .optimize_default = switch (module.optimization.default) {
            .size => module.optimization.size,
            .speed => module.optimization.speed,
        },
        .optimization_kind = module.optimization.default,
        .optimize_size = module.optimization.size,
        .optimize_speed = module.optimization.speed,
        .runtime_optimize = root.codegen.runtime.optimize,
        .host_optimize = root.codegen.host.optimize,
        .debug_optimize = root.codegen.host.debug_optimize,
        .packager_optimize = root.codegen.host.packager_optimize,
    };
};

pub fn requireOptimize(b: *std.Build, mode: std.builtin.OptimizeMode) void {
    for (get(codegen(b.allocator, "module"), "allowed_optimize_modes").array.items) |entry| {
        if (std.mem.eql(u8, entry.string, @tagName(mode))) return;
    }
    @panic("SdkProfileOptimizationOverride");
}

pub fn strings(allocator: std.mem.Allocator, array: std.json.Value) []const []const u8 {
    const result = allocator.alloc([]const u8, array.array.items.len) catch @panic("OOM");
    for (array.array.items, result) |item, *out| out.* = item.string;
    return result;
}

pub fn moduleFlags(allocator: std.mem.Allocator) []const []const u8 {
    return strings(allocator, get(codegen(allocator, "module"), "c_flags"));
}

pub fn policyString(allocator: std.mem.Allocator, id: []const u8, field: []const u8) []const u8 {
    return get(codegen(allocator, id), field).string;
}

pub fn irArguments(allocator: std.mem.Allocator, mode: std.builtin.OptimizeMode) []const []const u8 {
    const policy = codegen(allocator, "module");
    const flags = strings(allocator, get(policy, "ir_flags"));
    const result = allocator.alloc([]const u8, flags.len + 1) catch @panic("OOM");
    result[0] = get(get(policy, "ir_optimization"), @tagName(mode)).string;
    @memcpy(result[1..], flags);
    return result;
}

pub fn requireProjectFlags(b: *std.Build, kind: []const u8, name: []const u8, flags: []const []const u8) void {
    const policy = get(codegen(b.allocator, "module"), "project_c_flags");
    const allowed = get(policy, "modules").object.get(b.fmt("{s}:{s}", .{ kind, name }));
    for (flags) |flag| {
        var admitted = false;
        for (get(policy, "allowed_exact").array.items) |entry| {
            if (std.mem.eql(u8, entry.string, flag)) admitted = true;
        }
        for (get(policy, "allowed_prefixes").array.items) |entry| {
            if (std.mem.startsWith(u8, flag, entry.string)) admitted = true;
        }
        if (allowed) |entries| for (entries.array.items) |entry| {
            if (std.mem.eql(u8, entry.string, flag)) admitted = true;
        };
        if (!admitted) @panic(b.fmt("SdkProfileCFlagOverride: {s}:{s} {s}", .{ kind, name, flag }));
    }
}

pub const Requirement = struct {
    name: []const u8,
    leaf: u32,
    subleaf: u32,
    register: enum { eax, ebx, ecx, edx },
    bit: u5,
    zig_features: []const []const u8,
    c_flag: ?[]const u8 = null,
    rust_feature: ?[]const u8 = null,
};
pub const Cpu = struct {
    format: u32,
    name: []const u8,
    cpu_model: []const u8,
    xcr0_mask: u64,
    tuning_features: []const []const u8,
    requirements: []const Requirement,
};

pub fn cpu(allocator: std.mem.Allocator) Cpu {
    const root = load(allocator);
    const id = get(get(get(root, "profiles"), "r4os-zig-module-v1"), "cpu").string;
    return std.json.parseFromValueLeaky(Cpu, allocator, get(get(root, "cpu_baselines"), id), .{}) catch
        @panic("SdkProfileInvalidCpuBaseline");
}

fn feature(name: []const u8) std.Target.x86.Feature {
    return std.meta.stringToEnum(std.Target.x86.Feature, name) orelse @panic("SdkProfileUnknownCpuFeature");
}

pub fn target(b: *std.Build) std.Build.ResolvedTarget {
    const profile = cpu(b.allocator);
    if (!std.mem.eql(u8, profile.cpu_model, "x86_64")) @panic("SdkProfileUnsupportedCpuModel");
    var isa = std.Target.Cpu.Feature.Set.empty;
    for (profile.requirements) |requirement| {
        for (requirement.zig_features) |name| isa.addFeature(@intFromEnum(feature(name)));
    }
    const resolved = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .cpu_model = .{ .explicit = &std.Target.x86.cpu.x86_64 },
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
        .cpu_features_add = isa,
    });
    var accounted = isa;
    for (profile.tuning_features) |name| accounted.addFeature(@intFromEnum(feature(name)));
    if (!std.meta.eql(accounted, resolved.result.cpu.features))
        @panic("SdkProfileImplicitCpuFeatureMismatch");
    return resolved;
}

pub fn cFlags(allocator: std.mem.Allocator) []const []const u8 {
    var result: std.ArrayList([]const u8) = .empty;
    for (cpu(allocator).requirements) |requirement| {
        if (requirement.c_flag) |flag| result.append(allocator, flag) catch @panic("OOM");
    }
    return result.toOwnedSlice(allocator) catch @panic("OOM");
}

pub fn hostOptimize(b: *std.Build, fallback: std.builtin.OptimizeMode) std.builtin.OptimizeMode {
    const mode = b.option(std.builtin.OptimizeMode, "optimize", "SDK-approved host optimization") orelse fallback;
    for (get(codegen(b.allocator, "host"), "allowed_optimize_modes").array.items) |entry| {
        if (std.mem.eql(u8, entry.string, @tagName(mode))) return mode;
    }
    @panic("SdkHostOptimizationOverride");
}
