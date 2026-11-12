const std = @import("std");

pub const rust_profile = "r4os-rust-r4x-v2";
pub const rust_tools = "r4os-rust-tools-v1";
pub const rust_build_plan_schema: u32 = 2;
// Admission and availability are different facts. The host driver changes
// this only after source -> ELF -> R4M0 and real R4XStart qualification.
pub const rust_host_builder = true;

pub const Execution = enum { host, native_r4os };
pub const Request = struct {
    platform_generation: u8 = 1,
    language: []const u8,
    kind: []const u8,
    app_class: ?[]const u8 = null,
    entry_mode: ?[]const u8 = null,
    role: ?[]const u8 = null,
    execution: Execution = .host,
};
pub const Decision = struct {
    supported: bool,
    code: []const u8,
    reason: []const u8,
    failure: ?anyerror = null,
    owner_contract: []const u8 = "",
    missing_steps: []const []const u8 = &.{},
};

pub fn rust(kind: []const u8, entry: []const u8, role: ?[]const u8, execution: Execution) Decision {
    if (std.mem.eql(u8, kind, "R4L")) {
        if (execution == .native_r4os) return .{ .supported = false, .code = "rust-native-compiler-unavailable", .reason = "Rust providers require the pinned host compiler.", .failure = error.RustNativeCompilerUnavailable };
        return .{ .supported = true, .code = "supported", .reason = "Rust R4L provider with library-owned contract/baseline, generated typed tables, declared Query/exports and caller-owned resources." };
    }
    if (std.mem.eql(u8, kind, "R4D")) {
        if (execution == .native_r4os) return .{ .supported = false, .code = "rust-native-compiler-unavailable", .reason = "Rust drivers require the pinned host compiler.", .failure = error.RustNativeCompilerUnavailable };
        return .{ .supported = true, .code = "supported", .reason = "Rust R4D with manifest-selected driver entries, original R4DEV owner admission and explicit resource quiescence." };
    }
    if (std.mem.eql(u8, kind, "R4P")) {
        if (execution == .native_r4os) return .{ .supported = false, .code = "rust-native-compiler-unavailable", .reason = "Rust protocols require the pinned host compiler.", .failure = error.RustNativeCompilerUnavailable };
        return .{ .supported = true, .code = "supported", .reason = "Rust R4P with original entries/metadata, serialized PPI callbacks, explicit provider/session close and resident module code." };
    }
    if (role) |value| if (!std.mem.eql(u8, value, "subsystem")) return .{ .supported = false, .code = "rust-unknown-module-role", .reason = "Only the manifest-defined subsystem role is supported.", .failure = error.RustSubsystemUnsupported, .owner_contract = "Contract/Module/R4MFv2.txt" };
    if (!std.ascii.eqlIgnoreCase(entry, "app") and !std.ascii.eqlIgnoreCase(entry, "lowlevel")) return .{ .supported = false, .code = "rust-entry-unsupported", .reason = "Rust R4X requires an explicit app or lowlevel entry.", .failure = error.RustLowlevelUnsupported };
    if (execution == .native_r4os) return .{ .supported = false, .code = "rust-native-compiler-unavailable", .reason = "Rust compilation requires the pinned Windows/Linux host tools; R4OS has no native Rust compiler.", .failure = error.RustNativeCompilerUnavailable, .owner_contract = "SDK/Rust/README.txt", .missing_steps = &.{"Independent native R4OS Rust compiler/toolchain port and qualification"} };
    return .{ .supported = true, .code = "supported", .reason = if (role != null) "Rust GUI R4X subsystem host with explicit app/lowlevel entry, canonical ID/formats/catalogue, R4SUBSYS1 and shared video/input/audio/persistence helpers; GUI manifest validation still applies." else if (std.ascii.eqlIgnoreCase(entry, "lowlevel")) "Rust R4X with a checked manifest-selected raw start and explicitly selected SDK runtime helpers." else "Rust R4X app console/gui/service semantic profile; compiler installation is a separate check." };
}

pub fn requireRustHost(kind: []const u8, entry: []const u8, role: ?[]const u8) !void {
    const decision = rust(kind, entry, role, .host);
    if (decision.failure) |err| return err;
    if (!rust_host_builder) return error.RustHostBuilderNotYetQualified;
}

pub fn query(request: Request) Decision {
    if (request.platform_generation != 1 and request.platform_generation != 2) return .{ .supported = false, .code = "unknown-platform-generation", .reason = "Only declared platform generations have a build profile." };
    if (!std.mem.eql(u8, request.kind, "R4X") and !std.mem.eql(u8, request.kind, "R4L") and !std.mem.eql(u8, request.kind, "R4D") and !std.mem.eql(u8, request.kind, "R4P")) return .{ .supported = false, .code = "unknown-module-kind", .reason = "Unknown module kind has no build profile." };
    if (std.mem.eql(u8, request.language, "Rust")) return rust(request.kind, request.entry_mode orelse "", request.role, request.execution);
    if (!std.mem.eql(u8, request.language, "Zig") and !std.mem.eql(u8, request.language, "C")) return .{ .supported = false, .code = "unknown-language", .reason = "Only manifest-admitted languages have a build profile." };
    if (request.execution == .native_r4os) {
        if (!std.mem.eql(u8, request.language, "C")) return .{ .supported = false, .code = "native-zig-compiler-unavailable", .reason = "R4OS has no native Zig compiler; use the host SDK." };
        if (request.role != null) return .{ .supported = false, .code = "native-r4cc-subsystem-unavailable", .reason = "Native R4CC does not yet build subsystem-role metadata; use the host SDK." };
        if (!std.mem.eql(u8, request.kind, "R4X") or !std.mem.eql(u8, request.entry_mode orelse "", "app") or std.mem.eql(u8, request.app_class orelse "", "service")) return .{ .supported = false, .code = "native-r4cc-profile-unsupported", .reason = "Native R4BUILD/R4CC supports one C source, R4X app console/gui and exact class imports only; C language syntax remains the R4CC subset." };
        return .{ .supported = true, .code = "native-r4cc-subset", .reason = "One C source, R4X app console or gui, exact class imports, R4CC C subset and bounded native resources. This is not the Zig/Clang host compiler." };
    }

    return .{ .supported = true, .code = "supported", .reason = "Existing host SDK Zig or Zig/Clang C module path; manifest, owner contract and source/dependency requirements still apply." };
}
