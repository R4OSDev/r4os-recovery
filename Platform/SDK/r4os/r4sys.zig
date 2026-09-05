const abi = @import("r4os_contract").abi;
const program = @import("program.zig");
const std = @import("std");
const time_contract = @import("time_contract.zig");

pub const name = "R4SYS";
pub const import_query = "R4SYS:Query:1";
pub const group = abi.R4LGroup.r4sys;
pub const abi_version = abi.r4l_abi_version;
pub const contract = "Repositories/Contract/API/Groups.txt";
pub const provider_repository = "Repositories/Kernel";
pub const c_header = "Repositories/SDK/Shared/C/include/r4os/r4sys.h";
pub const query_contract = "Repositories/Contract/ABI/R4LQuery.txt";
pub const dir_entry_result_end: i32 = -5;
pub const dir_entry_error_io: i32 = -9;

pub const system_replace_result_ok: i32 = 0;
pub const system_replace_error_invalid: i32 = -1;
pub const system_replace_error_unsupported: i32 = -2;
pub const system_replace_error_not_found: i32 = -3;
pub const system_replace_error_bad_path: i32 = -4;
pub const system_replace_error_backup_failed: i32 = -5;
pub const system_replace_error_replace_failed: i32 = -6;
pub const system_replace_error_verify_failed: i32 = -7;
pub const system_replace_error_rollback_failed: i32 = -8;
pub const system_replace_error_io: i32 = -9;

pub const file_replace_atomic_result_ok: i32 = 0;
pub const file_replace_atomic_error_invalid: i32 = -1;
pub const file_replace_atomic_error_unsupported: i32 = -2;
pub const file_replace_atomic_error_not_found: i32 = -3;
pub const file_replace_atomic_error_bad_path: i32 = -4;
pub const file_replace_atomic_error_alias: i32 = -5;
pub const file_replace_atomic_error_conflict: i32 = -6;
pub const file_replace_atomic_error_io: i32 = -7;
pub const file_replace_atomic_error_not_atomic: i32 = -8;
pub const file_replace_atomic_flag_consume_stage: u32 = 1 << 0;
pub const file_replace_atomic_flag_require_target_absent: u32 = 1 << 1;
pub const file_replace_atomic_flag_require_owned_stage: u32 = 1 << 2;
pub const file_delete_if_match_result_not_found: i32 = 0;
pub const file_delete_if_match_result_deleted: i32 = 1;
pub const file_delete_if_match_error_invalid: i32 = -1;
pub const file_delete_if_match_error_unsupported: i32 = -2;
pub const file_delete_if_match_error_conflict: i32 = -3;
pub const file_delete_if_match_error_io: i32 = -4;
pub const file_update_atomic_checked_result_ok: i32 = 0;
pub const file_update_atomic_checked_error_invalid: i32 = -1;
pub const file_update_atomic_checked_error_unsupported: i32 = -2;
pub const file_update_atomic_checked_error_bad_path: i32 = -3;
pub const file_update_atomic_checked_error_conflict: i32 = -4;
pub const file_update_atomic_checked_error_io: i32 = -5;
pub const file_update_atomic_checked_error_not_atomic: i32 = -6;
pub const file_update_atomic_checked_flag_forward: u32 = 1 << 0;
pub const file_update_atomic_checked_flag_rollback: u32 = 1 << 1;
pub const file_update_atomic_checked_flag_target_existed: u32 = 1 << 2;
pub const file_update_atomic_checked_flag_old_known: u32 = 1 << 3;
// Declared create-only publish intent (0.60.30).
pub const file_stream_publish_protocol_sftp = abi.file_stream_publish_protocol_sftp;
pub const file_stream_publish_protocol_scp = abi.file_stream_publish_protocol_scp;
pub const file_stream_publish_protocol_ftp = abi.file_stream_publish_protocol_ftp;
pub const file_stream_declare_publish_result_ok: i32 = 0;
pub const file_stream_declare_publish_error_invalid: i32 = -1;
pub const file_stream_declare_publish_error_unsupported: i32 = -2;
pub const file_stream_declare_publish_error_bad_path: i32 = -3;
pub const file_stream_declare_publish_error_not_found: i32 = -4;
pub const file_stream_declare_publish_error_not_atomic: i32 = -5;
pub const file_stream_declare_publish_error_io: i32 = -6;
// Backend-exact name collation (0.60.24).
pub const path_names_equal_result_different: i32 = 0;
pub const path_names_equal_result_equal: i32 = 1;
pub const path_names_equal_error_invalid: i32 = -1;
pub const path_names_equal_error_unsupported: i32 = -2;
pub const path_names_equal_error_bad_path: i32 = -3;
pub const path_names_equal_error_not_same_volume: i32 = -4;
// Per-payload checked cleanup (0.60.23).
pub const file_update_cleanup_checked_result_ok: i32 = 0;
pub const file_update_cleanup_checked_error_invalid: i32 = -1;
pub const file_update_cleanup_checked_error_unsupported: i32 = -2;
pub const file_update_cleanup_checked_error_bad_path: i32 = -3;
pub const file_update_cleanup_checked_error_conflict: i32 = -4;
pub const file_update_cleanup_checked_error_io: i32 = -5;
pub const file_update_cleanup_checked_error_not_atomic: i32 = -6;
pub const file_update_cleanup_checked_flag_target_existed: u32 = 1 << 0;
pub const file_update_cleanup_checked_flag_old_known: u32 = 1 << 1;
pub const file_update_cleanup_checked_flag_previous_known: u32 = 1 << 2;
pub const program_module_running_result_idle: i32 = 0;
pub const program_module_running_result_running: i32 = 1;
pub const program_module_running_error_invalid: i32 = -1;
pub const program_module_running_error_unavailable: i32 = -2;
pub const file_stream_open_lease = abi.file_stream_open_lease;
pub const file_stream_finish_keep_ownership: u32 = 1 << 0;

pub const system_replace_flag_allow_temp: u32 = 1 << 0;
pub const system_replace_flag_allow_missing_target: u32 = 1 << 1;
pub const system_replace_flag_reboot_required: u32 = 1 << 16;
pub const system_replace_flag_flush_boundary: u32 = 1 << 17;
pub const system_replace_flag_backup_created: u32 = 1 << 18;
pub const system_replace_flag_rollback_attempted: u32 = 1 << 19;

pub const SystemReplaceClass = enum(u8) {
    unknown,
    boot_kernel,
    system_library,
    driver,
    protocol,
    service,
    software,
    font,
    config,
    sdk,
    temp,
    /// Payload on another mounted volume (NTFS data disk, boot partition):
    /// plain atomic file replacement without service/driver semantics.
    data,
};

pub const SystemReplacePlan = struct {
    target_path: [*:0]const u8,
    staged_path: [*:0]const u8,
    backup_path: [*:0]const u8,
    class: SystemReplaceClass = .unknown,
    flags: u32 = 0,
    result: i32 = system_replace_error_invalid,
    target_exists: bool = false,
    backup_exists: bool = false,
    target_size: u64 = 0,
    staged_size: u64 = 0,
    backup_size: u64 = 0,

    pub fn ok(self: *const SystemReplacePlan) bool {
        return self.result == system_replace_result_ok;
    }

    pub fn rebootRequired(self: *const SystemReplacePlan) bool {
        return (self.flags & system_replace_flag_reboot_required) != 0;
    }

    pub fn className(self: *const SystemReplacePlan) []const u8 {
        return systemReplaceClassName(self.class);
    }
};

/// Explicit update-only plan.  Unlike the historical SystemReplacePlan this
/// plan is applied through the no-fallback R4SYS/FAT ownership-transfer slot.
pub const SystemReplaceAtomicPlan = struct {
    target_path: [*:0]const u8,
    staged_path: [*:0]const u8,
    backup_path: [*:0]const u8,
    class: SystemReplaceClass = .unknown,
    flags: u32 = 0,
    result: i32 = system_replace_error_invalid,
    target_exists: bool = false,
    target_size: u64 = 0,
    staged_size: u64 = 0,

    pub fn ok(self: *const SystemReplaceAtomicPlan) bool {
        return self.result == system_replace_result_ok;
    }

    pub fn rebootRequired(self: *const SystemReplaceAtomicPlan) bool {
        return (self.flags & system_replace_flag_reboot_required) != 0;
    }
};

pub fn entryAsm(comptime target: []const u8) []const u8 {
    return program.entryAsm(target);
}

pub fn systemReplaceClassName(class: SystemReplaceClass) []const u8 {
    return switch (class) {
        .boot_kernel => "boot-kernel",
        .system_library => "system-library",
        .driver => "driver",
        .protocol => "protocol",
        .service => "service",
        .software => "software",
        .font => "font",
        .config => "config",
        .sdk => "sdk",
        .temp => "temp",
        .data => "data",
        .unknown => "unknown",
    };
}

pub fn systemReplaceResultName(result: i32) []const u8 {
    return switch (result) {
        system_replace_result_ok => "ok",
        system_replace_error_invalid => "invalid",
        system_replace_error_unsupported => "unsupported",
        system_replace_error_not_found => "not-found",
        system_replace_error_bad_path => "bad-path",
        system_replace_error_backup_failed => "backup-failed",
        system_replace_error_replace_failed => "replace-failed",
        system_replace_error_verify_failed => "verify-failed",
        system_replace_error_rollback_failed => "rollback-failed",
        system_replace_error_io => "io",
        else => "unknown",
    };
}

pub fn fileUpdateAtomicCheckedResultName(result: i32) []const u8 {
    return switch (result) {
        file_update_atomic_checked_result_ok => "ok",
        file_update_atomic_checked_error_invalid => "invalid",
        file_update_atomic_checked_error_unsupported => "unsupported",
        file_update_atomic_checked_error_bad_path => "bad-path",
        file_update_atomic_checked_error_conflict => "conflict",
        file_update_atomic_checked_error_io => "io",
        file_update_atomic_checked_error_not_atomic => "not-atomic",
        else => "unknown",
    };
}

pub fn systemReplaceNeedsReboot(class: SystemReplaceClass) bool {
    return switch (class) {
        .boot_kernel,
        .system_library,
        .driver,
        .protocol,
        .service,
        .software,
        .font,
        .sdk,
        => true,
        .config, .temp, .data, .unknown => false,
    };
}

pub fn classifySystemPath(path_raw: []const u8) SystemReplaceClass {
    const path = trimPath(path_raw);
    if (path.len == 0) return .unknown;
    if (pathEquals(path, "/boot/r4os.elf") or pathEquals(path, "\\boot\\r4os.elf")) return .boot_kernel;
    if (pathEquals(path, "C:\\CONFIG.R4S")) return .config;
    if (pathHasPrefix(path, "C:\\R4OS\\LIBS\\") and endsWithIgnoreCase(path, ".R4L")) return .system_library;
    if (pathHasPrefix(path, "C:\\R4OS\\DRIVERS\\") and endsWithIgnoreCase(path, ".R4D")) return .driver;
    if (pathHasPrefix(path, "C:\\R4OS\\PROTOCOLS\\") and endsWithIgnoreCase(path, ".R4P")) return .protocol;
    if (pathHasPrefix(path, "C:\\R4OS\\SERVICES\\") and endsWithIgnoreCase(path, ".R4X")) return .service;
    if (pathHasPrefix(path, "C:\\R4OS\\SOFTWARE\\")) return .software;
    if (pathHasPrefix(path, "C:\\R4OS\\SUBSYSTEMS\\") and endsWithIgnoreCase(path, ".R4X")) return .software;
    if (pathHasPrefix(path, "C:\\R4OS\\FONTS\\") and endsWithIgnoreCase(path, ".R4F")) return .font;
    if (pathHasPrefix(path, "C:\\R4OS\\CONFIG\\")) return .config;
    if (pathHasPrefix(path, "C:\\R4OS\\SDK\\")) return .sdk;
    if (pathHasPrefix(path, "C:\\TEMP\\")) return .temp;
    if (isForeignDrivePath(path)) return .data;
    return .unknown;
}

/// Payload targets on other mounted volumes (e.g. an NTFS data disk or the
/// FAT32 boot partition once it carries a letter) form the generic "data"
/// replace class: plain atomic file replacement, no service semantics.
fn isForeignDrivePath(path: []const u8) bool {
    if (path.len < 4) return false;
    const letter = if (path[0] >= 'a' and path[0] <= 'z') path[0] - 32 else path[0];
    if (letter < 'A' or letter > 'Z' or letter == 'C') return false;
    return path[1] == ':' and (path[2] == '\\' or path[2] == '/');
}

const SystemFileLookupStatus = enum(u8) {
    found,
    not_found,
    io,
};

fn systemFileLookup(sys: anytype, path: [*:0]const u8, out: *abi.FileInfo) SystemFileLookupStatus {
    out.* = .{};
    const rc = sys.fileInfoRaw(path, out);
    if (rc < 0) return .io;
    if (rc == 0 or out.exists == 0) return .not_found;
    return .found;
}

pub fn prepareSystemReplace(sys: anytype, target_path: [*:0]const u8, staged_path: [*:0]const u8, backup_path: [*:0]const u8, flags: u32) SystemReplacePlan {
    var plan = SystemReplacePlan{
        .target_path = target_path,
        .staged_path = staged_path,
        .backup_path = backup_path,
        .flags = flags,
    };
    const target = std.mem.span(target_path);
    const staged = std.mem.span(staged_path);
    const backup = std.mem.span(backup_path);
    if (target.len == 0 or staged.len == 0 or backup.len == 0) return plan;
    if (pathEquals(target, staged) or pathEquals(target, backup) or pathEquals(staged, backup)) return plan;

    plan.class = classifySystemPath(target);
    if (plan.class == .unknown or (plan.class == .temp and (flags & system_replace_flag_allow_temp) == 0)) {
        plan.result = system_replace_error_bad_path;
        return plan;
    }
    if (!sameParentPath(target, staged) or !sameParentPath(target, backup)) {
        plan.result = system_replace_error_bad_path;
        return plan;
    }
    if (systemReplaceNeedsReboot(plan.class)) plan.flags |= system_replace_flag_reboot_required;
    plan.flags |= system_replace_flag_flush_boundary;

    var staged_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, staged_path, &staged_info)) {
        .found => {},
        .not_found => {
            plan.result = system_replace_error_not_found;
            return plan;
        },
        .io => {
            plan.result = system_replace_error_io;
            return plan;
        },
    }
    if (staged_info.is_dir != 0) return plan;
    plan.staged_size = staged_info.size;

    var target_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, target_path, &target_info)) {
        .found => {
            if (target_info.is_dir != 0) return plan;
            plan.target_exists = true;
            plan.target_size = target_info.size;
        },
        .not_found => {
            if ((flags & system_replace_flag_allow_missing_target) == 0) {
                plan.result = system_replace_error_not_found;
                return plan;
            }
        },
        .io => {
            plan.result = system_replace_error_io;
            return plan;
        },
    }

    var backup_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, backup_path, &backup_info)) {
        .found => {
            if (backup_info.is_dir != 0) return plan;
            plan.backup_exists = true;
            plan.backup_size = backup_info.size;
        },
        .not_found => {},
        .io => {
            plan.result = system_replace_error_io;
            return plan;
        },
    }

    plan.result = system_replace_result_ok;
    return plan;
}

pub fn applySystemReplace(sys: anytype, plan: *SystemReplacePlan) i32 {
    if (plan.result != system_replace_result_ok) return plan.result;
    if (plan.backup_exists) {
        if (sys.fileDelete(plan.backup_path) < 0) {
            plan.result = system_replace_error_backup_failed;
            return plan.result;
        }
        var removed_backup: abi.FileInfo = .{};
        if (systemFileLookup(sys, plan.backup_path, &removed_backup) != .not_found) {
            plan.result = system_replace_error_backup_failed;
            return plan.result;
        }
        plan.backup_exists = false;
    }

    if (plan.target_exists) {
        if (sys.fileRename(plan.target_path, plan.backup_path) <= 0) {
            plan.result = system_replace_error_backup_failed;
            return plan.result;
        }
        plan.flags |= system_replace_flag_backup_created;
    }

    if (sys.fileRename(plan.staged_path, plan.target_path) <= 0) {
        const rolled_back = rollbackSystemReplace(sys, plan);
        plan.result = if (rolled_back) system_replace_error_replace_failed else system_replace_error_rollback_failed;
        return plan.result;
    }

    var verify: abi.FileInfo = .{};
    switch (systemFileLookup(sys, plan.target_path, &verify)) {
        .found => {},
        .not_found => {
            const rolled_back = rollbackSystemReplace(sys, plan);
            plan.result = if (rolled_back) system_replace_error_verify_failed else system_replace_error_rollback_failed;
            return plan.result;
        },
        .io => {
            // The replace may already be durable. Never start a destructive
            // rollback merely because its verification read was ambiguous.
            plan.result = system_replace_error_io;
            return plan.result;
        },
    }
    if (verify.is_dir != 0 or verify.size != plan.staged_size) {
        const rolled_back = rollbackSystemReplace(sys, plan);
        plan.result = if (rolled_back) system_replace_error_verify_failed else system_replace_error_rollback_failed;
        return plan.result;
    }

    plan.target_exists = true;
    plan.target_size = verify.size;
    plan.result = system_replace_result_ok;
    return plan.result;
}

fn rollbackSystemReplace(sys: anytype, plan: *SystemReplacePlan) bool {
    plan.flags |= system_replace_flag_rollback_attempted;
    if (!plan.target_exists) {
        if (sys.fileDelete(plan.target_path) < 0) return false;
        var removed_target: abi.FileInfo = .{};
        return systemFileLookup(sys, plan.target_path, &removed_target) == .not_found;
    }
    if (sys.fileDelete(plan.target_path) < 0) return false;
    var removed_target: abi.FileInfo = .{};
    if (systemFileLookup(sys, plan.target_path, &removed_target) != .not_found) return false;
    if (sys.fileRename(plan.backup_path, plan.target_path) <= 0) return false;
    var restored_target: abi.FileInfo = .{};
    if (systemFileLookup(sys, plan.target_path, &restored_target) != .found) return false;
    return restored_target.is_dir == 0 and restored_target.size == plan.target_size;
}

pub fn prepareSystemReplaceAtomic(sys: anytype, target_path: [*:0]const u8, staged_path: [*:0]const u8, backup_path: [*:0]const u8, flags: u32) SystemReplaceAtomicPlan {
    var plan = SystemReplaceAtomicPlan{
        .target_path = target_path,
        .staged_path = staged_path,
        .backup_path = backup_path,
        .flags = flags,
    };
    const target = std.mem.span(target_path);
    const staged = std.mem.span(staged_path);
    const backup = std.mem.span(backup_path);
    if (target.len == 0 or staged.len == 0 or backup.len == 0) return plan;
    if (pathEquals(target, staged) or pathEquals(target, backup) or pathEquals(staged, backup)) return plan;
    if (!sameParentPath(target, staged) or !sameParentPath(target, backup)) {
        plan.result = system_replace_error_bad_path;
        return plan;
    }

    plan.class = classifySystemPath(target);
    if (plan.class == .unknown or (plan.class == .temp and (flags & system_replace_flag_allow_temp) == 0)) {
        plan.result = system_replace_error_bad_path;
        return plan;
    }
    if (systemReplaceNeedsReboot(plan.class)) plan.flags |= system_replace_flag_reboot_required;
    plan.flags |= system_replace_flag_flush_boundary;

    var staged_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, staged_path, &staged_info)) {
        .found => {},
        .not_found => {
            plan.result = system_replace_error_not_found;
            return plan;
        },
        .io => {
            plan.result = system_replace_error_io;
            return plan;
        },
    }
    if (staged_info.is_dir != 0) return plan;
    plan.staged_size = staged_info.size;
    var target_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, target_path, &target_info)) {
        .found => {
            if (target_info.is_dir != 0) return plan;
            plan.target_exists = true;
            plan.target_size = target_info.size;
        },
        .not_found => {
            if ((flags & system_replace_flag_allow_missing_target) == 0) {
                plan.result = system_replace_error_not_found;
                return plan;
            }
        },
        .io => {
            plan.result = system_replace_error_io;
            return plan;
        },
    }
    var backup_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, backup_path, &backup_info)) {
        .found => {
            plan.result = system_replace_error_backup_failed;
            return plan;
        },
        .not_found => {},
        .io => {
            plan.result = system_replace_error_io;
            return plan;
        },
    }
    plan.result = system_replace_result_ok;
    return plan;
}

pub fn applySystemReplaceAtomic(sys: anytype, plan: *SystemReplaceAtomicPlan) i32 {
    if (plan.result != system_replace_result_ok) return plan.result;
    const rc = sys.fileReplaceAtomic(plan.target_path, plan.staged_path, plan.backup_path, file_replace_atomic_flag_consume_stage);
    if (rc != file_replace_atomic_result_ok) {
        plan.result = if (rc == file_replace_atomic_error_not_atomic or rc == file_replace_atomic_error_unsupported)
            system_replace_error_unsupported
        else if (rc == file_replace_atomic_error_not_found)
            system_replace_error_not_found
        else
            system_replace_error_replace_failed;
        return plan.result;
    }
    var target_info: abi.FileInfo = .{};
    switch (systemFileLookup(sys, plan.target_path, &target_info)) {
        .found => {},
        .not_found => {
            plan.result = system_replace_error_verify_failed;
            return plan.result;
        },
        .io => {
            plan.result = system_replace_error_io;
            return plan.result;
        },
    }
    if (target_info.is_dir != 0 or target_info.size != plan.staged_size) {
        plan.result = system_replace_error_verify_failed;
        return plan.result;
    }
    if (plan.target_exists) plan.flags |= system_replace_flag_backup_created;
    plan.result = system_replace_result_ok;
    return plan.result;
}

pub fn rollbackSystemReplaceAtomic(sys: anytype, plan: *SystemReplaceAtomicPlan) bool {
    plan.flags |= system_replace_flag_rollback_attempted;
    if (!plan.target_exists) {
        const deleted = sys.fileDelete(plan.target_path);
        if (deleted < 0) return false;
        var removed_target: abi.FileInfo = .{};
        return systemFileLookup(sys, plan.target_path, &removed_target) == .not_found;
    }
    const rc = sys.fileReplaceAtomic(plan.target_path, plan.backup_path, plan.staged_path, file_replace_atomic_flag_consume_stage);
    if (rc != file_replace_atomic_result_ok) return false;
    var target_info: abi.FileInfo = .{};
    if (systemFileLookup(sys, plan.target_path, &target_info) != .found) return false;
    return target_info.is_dir == 0 and target_info.size == plan.target_size;
}

fn trimPath(value: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = value.len;
    while (start < end and isPathSpace(value[start])) : (start += 1) {}
    while (end > start and isPathSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn isPathSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn pathEquals(a_raw: []const u8, b_raw: []const u8) bool {
    const a = trimPath(a_raw);
    const b = trimPath(b_raw);
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (pathChar(a[i]) != pathChar(b[i])) return false;
    }
    return true;
}

fn pathHasPrefix(path_raw: []const u8, prefix_raw: []const u8) bool {
    const path = trimPath(path_raw);
    const prefix = trimPath(prefix_raw);
    if (path.len < prefix.len) return false;
    var i: usize = 0;
    while (i < prefix.len) : (i += 1) {
        if (pathChar(path[i]) != pathChar(prefix[i])) return false;
    }
    return true;
}

fn endsWithIgnoreCase(path_raw: []const u8, suffix_raw: []const u8) bool {
    const path = trimPath(path_raw);
    const suffix = trimPath(suffix_raw);
    if (path.len < suffix.len) return false;
    return pathEquals(path[path.len - suffix.len ..], suffix);
}

fn sameParentPath(a_raw: []const u8, b_raw: []const u8) bool {
    const a = trimPath(a_raw);
    const b = trimPath(b_raw);
    const a_len = parentPrefixLen(a) orelse return false;
    const b_len = parentPrefixLen(b) orelse return false;
    return pathEquals(a[0..a_len], b[0..b_len]);
}

fn parentPrefixLen(path: []const u8) ?usize {
    if (path.len == 0) return null;
    var index = path.len;
    while (index > 0) {
        index -= 1;
        if (path[index] == '\\' or path[index] == '/') {
            if (index == 0) return 1;
            if (index == 2 and path.len >= 3 and path[1] == ':') return 3;
            return index + 1;
        }
    }
    return null;
}

fn pathChar(ch: u8) u8 {
    if (ch == '/') return '\\';
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

// Liefert das SDK-Bundle mit den aus dem R4XStart-Kontext aufgeloesten
// R4L-Gruppentabellen. Consumer reichen es unveraendert an die jeweiligen
// Gruppen-Context.init-Funktionen weiter.
pub fn bundleFromR4XStart(raw: *const abi.R4XStartContext) ?*const program.Bundle {
    return program.bundleFromR4XStart(raw);
}

pub fn contextFromR4XStart(raw: *const abi.R4XStartContext) ?Context {
    const bundle = program.bundleFromR4XStart(raw) orelse return null;
    return Context.init(bundle);
}

// Fehler- und Typkonstanten der R4M0-Ressourcen-Lese-API (0.61.13).
// Wahrheit ist der Kernel (Code/Kernel/program/r4sys.zig); die Werte sind
// Teil des eingefrorenen Fachdomaenen-Vertrags der Slots.
pub const module_resource_type_icon: u32 = 1;
pub const module_resource_type_help: u32 = 2;
pub const module_resource_type_file: u32 = 3;
pub const module_resource_error_invalid: i32 = -1;
pub const module_resource_error_volume: i32 = -2;
pub const module_resource_error_not_found: i32 = -3;
pub const module_resource_error_bad_module: i32 = -4;
pub const module_resource_error_no_resources: i32 = -5;
pub const module_resource_error_no_entry: i32 = -6;
pub const module_resource_error_too_small: i32 = -7;
pub const module_resource_error_io: i32 = -8;

pub const Context = struct {
    base: program.Context,

    pub fn init(bundle: *const program.Bundle) Context {
        return .{ .base = program.Context.initBundle(bundle) };
    }

    pub fn fromProgram(ctx: program.Context) Context {
        return .{ .base = ctx };
    }

    // 0.57.2: ehrliche Vertragspruefung (ersetzt supports*-Versionsgates).
    pub fn hasFn(self: *const Context, comptime field: []const u8) bool {
        return self.base.hasSysFn(field);
    }

    // Vertragsauskunft direkt aus der R4SYS-Gruppentabelle.
    pub fn contractValid(self: *const Context) bool {
        const b = self.base.bundle orelse return false;
        return b.sys != null;
    }

    pub fn tableAbiVersion(self: *const Context) u32 {
        const b = self.base.bundle orelse return 0;
        const table = b.sys orelse return 0;
        return table.abi_version;
    }

    pub fn tableSize(self: *const Context) u32 {
        const b = self.base.bundle orelse return 0;
        const table = b.sys orelse return 0;
        return table.size;
    }

    pub fn argsRaw(self: *const Context) [*:0]const u8 {
        return self.base.argsRaw();
    }

    pub fn envGet(self: *const Context, env_name: [*:0]const u8, out: []u8) i32 {
        return self.base.envGet(env_name, out);
    }

    pub fn envSet(self: *const Context, env_name: [*:0]const u8, value: []const u8) i32 {
        return self.base.envSet(env_name, value);
    }

    pub fn readKey(self: *const Context) u8 {
        return self.base.readKey();
    }

    pub fn consoleRead(self: *const Context, out: []u8) i32 {
        return self.base.consoleRead(out);
    }

    pub fn consoleInputWait(self: *const Context, last_generation: u64, timeout_ticks: u64, out_generation: *u64) i32 {
        return self.base.consoleInputWait(last_generation, timeout_ticks, out_generation);
    }

    pub fn print(self: *const Context, value: [*:0]const u8) void {
        self.base.print(value);
    }

    pub fn putc(self: *const Context, ch: u8) void {
        self.base.putc(ch);
    }

    pub fn write(self: *const Context, value: []const u8) void {
        self.base.write(value);
    }

    pub fn println(self: *const Context, value: []const u8) void {
        self.base.println(value);
    }

    pub fn printU64(self: *const Context, value: u64) void {
        self.base.printU64(value);
    }

    pub fn printI32(self: *const Context, value: i32) void {
        self.base.printI32(value);
    }

    pub fn printHexU32(self: *const Context, value: u32) void {
        self.base.printHexU32(value);
    }

    pub fn ticks(self: *const Context) u64 {
        return self.base.ticks();
    }

    pub fn sleepTicks(self: *const Context, duration: u64) void {
        self.base.sleepTicks(duration);
    }

    pub fn timeSecondsSinceMidnight(self: *const Context) u32 {
        return self.base.timeSecondsSinceMidnight();
    }

    pub fn timeState(self: *const Context) abi.TimeState {
        return self.base.timeState();
    }

    pub fn timeSetState(self: *const Context, next: *const abi.TimeState) i32 {
        return self.base.timeSetState(next);
    }

    pub fn bootLogInfo(self: *const Context) ?abi.BootLogInfo {
        return self.base.bootLogInfo();
    }

    pub fn bootLogRead(self: *const Context, offset: u32, out: []u8) i32 {
        return self.base.bootLogRead(offset, out);
    }

    pub fn timeServiceStatus(self: *const Context, out: *abi.TimeServiceStatus) i32 {
        return self.base.timeServiceStatus(out);
    }

    pub fn timeServiceReload(self: *const Context, out: *abi.TimeServiceStatus) i32 {
        return self.base.timeServiceReload(out);
    }

    pub fn timeServiceSetTimezone(self: *const Context, timezone_index: u32, out: *abi.TimeServiceStatus) i32 {
        return self.base.timeServiceSetTimezone(timezone_index, out);
    }

    pub fn timeServiceSetClockFormat(self: *const Context, clock_format: u32, out: *abi.TimeServiceStatus) i32 {
        return self.base.timeServiceSetClockFormat(clock_format, out);
    }

    pub fn timeServiceSetDate(self: *const Context, year: u16, month: u8, day: u8, out: *abi.TimeServiceStatus) i32 {
        return self.base.timeServiceSetDate(year, month, day, out);
    }

    pub fn timeServiceSetConfig(self: *const Context, request: *const abi.TimeServiceConfig, out: *abi.TimeServiceStatus) i32 {
        return self.base.timeServiceSetConfig(request, out);
    }

    pub fn logServiceStatus(self: *const Context, out: *abi.LogServiceStatus) i32 {
        return self.base.logServiceStatus(out);
    }

    pub fn logServiceSources(self: *const Context, query: *const abi.LogServiceSourceQuery, out: *abi.LogServiceSourcePage) i32 {
        return self.base.logServiceSources(query, out);
    }

    pub fn logServiceRecords(self: *const Context, query: *const abi.LogServiceRecordQuery, out: *abi.LogServiceRecordPage) i32 {
        return self.base.logServiceRecords(query, out);
    }

    pub fn logServiceExport(self: *const Context, query: *const abi.LogServiceRecordQuery, out: *abi.LogServiceExportPage) i32 {
        return self.base.logServiceExport(query, out);
    }

    pub fn logServiceWrite(self: *const Context, severity: u8, origin: []const u8, message: []const u8) i32 {
        return self.base.logServiceWrite(severity, origin, message);
    }

    pub fn logServiceWriteRecord(self: *const Context, source_id: u32, record_type: u8, severity: u8, origin: []const u8, message: []const u8) i32 {
        return self.base.logServiceWriteRecord(source_id, record_type, severity, origin, message);
    }

    pub fn audioServiceStatus(self: *const Context, out: *abi.AudioServiceStatus) i32 {
        return self.base.audioServiceStatus(out);
    }

    pub fn audioServiceSetMasterVolume(self: *const Context, fixed_volume: u32, out: *abi.AudioServiceStatus) i32 {
        return self.base.audioServiceSetMasterVolume(fixed_volume, out);
    }

    pub fn audioServiceMasterState(self: *const Context, out: *abi.AudioServiceMasterState) i32 {
        return self.base.audioServiceMasterState(out);
    }

    pub fn audioServiceSetMasterState(self: *const Context, request: *const abi.AudioServiceMasterRequest, out: *abi.AudioServiceMasterState) i32 {
        return self.base.audioServiceSetMasterState(request, out);
    }

    pub fn audioServiceOpenStream(self: *const Context, rate: u32, channels: u16, format: abi.AudioFormat) i32 {
        return self.base.audioServiceOpenStream(rate, channels, format);
    }

    pub inline fn audioServiceWrite(self: *const Context, stream_id: u32, data: []const u8) i32 {
        return self.base.audioServiceWrite(stream_id, data);
    }

    pub fn audioServiceClose(self: *const Context, stream_id: u32) i32 {
        return self.base.audioServiceClose(stream_id);
    }

    pub fn audioServiceSetVolume(self: *const Context, stream_id: u32, fixed_volume: u32) i32 {
        return self.base.audioServiceSetVolume(stream_id, fixed_volume);
    }

    pub fn ticksFromMilliseconds(self: *const Context, ms: u64) u64 {
        return self.base.ticksFromMilliseconds(ms);
    }

    pub fn monotonicHz(self: *const Context) u32 {
        return self.base.monotonicHz();
    }

    pub fn monotonicClock(self: *const Context, out: *abi.MonotonicClockInfo) i32 {
        return self.base.monotonicClock(out);
    }

    pub fn bootReady(self: *const Context) i32 {
        return self.base.bootReady();
    }

    pub fn monotonicNanoseconds(self: *const Context) ?u64 {
        return self.base.monotonicNanoseconds();
    }

    pub fn monotonicBackend(self: *const Context) abi.TimeBackend {
        return self.base.monotonicBackend();
    }

    pub fn systemHalt(self: *const Context) noreturn {
        self.base.systemHalt();
    }

    pub fn systemReboot(self: *const Context) noreturn {
        self.base.systemReboot();
    }

    pub fn systemPoweroff(self: *const Context) noreturn {
        self.base.systemPoweroff();
    }

    pub fn taskYield(self: *const Context) void {
        self.base.taskYield();
    }

    pub fn programRun(self: *const Context, path: [*:0]const u8, args: [*:0]const u8) i32 {
        return self.base.programRun(path, args);
    }

    pub fn programLaunch(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        return self.base.programLaunch(path, args, policy);
    }

    pub fn programSpawn(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        return self.base.programSpawn(path, args, policy);
    }

    pub fn programSpawnHandle(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, out_handle: *abi.ProgramProcessHandle) i32 {
        return self.base.programSpawnHandle(path, args, policy, out_handle);
    }

    pub fn programOpenHandle(self: *const Context, instance_id: u32, out_handle: *abi.ProgramProcessHandle) i32 {
        return self.base.programOpenHandle(instance_id, out_handle);
    }

    pub fn programHandleStatus(self: *const Context, handle: *const abi.ProgramProcessHandle, out: *abi.ProgramInstanceInfo) i32 {
        return self.base.programHandleStatus(handle, out);
    }

    pub fn programHandleRequestClose(self: *const Context, handle: *const abi.ProgramProcessHandle) i32 {
        return self.base.programHandleRequestClose(handle);
    }

    pub fn programHandleKill(self: *const Context, handle: *const abi.ProgramProcessHandle) i32 {
        return self.base.programHandleKill(handle);
    }

    pub fn programHandleWait(self: *const Context, handle: *const abi.ProgramProcessHandle, timeout_ticks: u64, out: *abi.ProgramProcessCompletion) i32 {
        return self.base.programHandleWait(handle, timeout_ticks, out);
    }

    pub fn programHandleReap(self: *const Context, handle: *const abi.ProgramProcessHandle, out: *abi.ProgramProcessCompletion) i32 {
        return self.base.programHandleReap(handle, out);
    }

    pub fn programCompletionRead(self: *const Context, handle: *const abi.ProgramProcessHandle, offset: u32, out: []u8, out_read: *u32) i32 {
        return self.base.programCompletionRead(handle, offset, out, out_read);
    }

    pub fn programSpawnWithConsoleHost(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind) i32 {
        return self.base.programSpawnWithConsoleHost(path, args, policy, host);
    }

    pub fn programSpawnWithConsoleHostHandle(self: *const Context, path: [*:0]const u8, args: [*:0]const u8, policy: abi.LaunchPolicy, host: abi.ConsoleHostKind, out_handle: *abi.ProgramProcessHandle) i32 {
        return self.base.programSpawnWithConsoleHostHandle(path, args, policy, host, out_handle);
    }

    pub fn programReapInstance(self: *const Context, instance_id: u32) i32 {
        return self.base.programReapInstance(instance_id);
    }

    pub fn programRequestClose(self: *const Context, instance_id: u32) i32 {
        return self.base.programRequestClose(instance_id);
    }

    pub fn programShouldClose(self: *const Context) bool {
        return self.base.programShouldClose();
    }

    pub fn programKill(self: *const Context, instance_id: u32) i32 {
        return self.base.programKill(instance_id);
    }

    pub fn programInstance(self: *const Context, index: u32, out: *abi.ProgramInstanceInfo) i32 {
        return self.base.programInstance(index, out);
    }

    pub fn programInventoryBegin(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: *abi.ProgramInventorySummary) i32 {
        return self.base.programInventoryBegin(cursor, out);
    }

    pub fn programInventoryPrograms(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramInstanceSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        return self.base.programInventoryPrograms(cursor, out, page);
    }

    pub fn programInventoryTasks(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramTaskSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        return self.base.programInventoryTasks(cursor, out, page);
    }

    pub fn programInventoryThreads(self: *const Context, cursor: *abi.ProgramInventoryCursor, out: []abi.ProgramThreadSnapshot, page: *abi.ProgramInventoryPageInfo) i32 {
        return self.base.programInventoryThreads(cursor, out, page);
    }

    pub fn threadCreateRaw(self: *const Context, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64, flags: u32, out_thread_id: *u32) i32 {
        return self.base.threadCreateRaw(entry, arg, stack_reserve_bytes, flags, out_thread_id);
    }

    pub fn threadCreate(self: *const Context, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64) ?u32 {
        return self.base.threadCreate(entry, arg, stack_reserve_bytes);
    }

    pub fn threadCreateHandle(self: *const Context, entry: abi.ThreadEntryFn, arg: u64, stack_reserve_bytes: u64, flags: u32, out_handle: *abi.ProgramJoinHandle) i32 {
        return self.base.threadCreateHandle(entry, arg, stack_reserve_bytes, flags, out_handle);
    }

    pub fn threadExit(self: *const Context, exit_code: i32) noreturn {
        self.base.threadExit(exit_code);
    }

    pub fn threadJoin(self: *const Context, thread_id: u32, timeout_ticks: u64, out_exit_code: *i32) i32 {
        return self.base.threadJoin(thread_id, timeout_ticks, out_exit_code);
    }

    pub fn threadHandleJoin(self: *const Context, handle: *const abi.ProgramJoinHandle, timeout_ticks: u64, out_exit_code: *i32) i32 {
        return self.base.threadHandleJoin(handle, timeout_ticks, out_exit_code);
    }

    pub fn threadCurrent(self: *const Context) u32 {
        return self.base.threadCurrent();
    }

    pub fn threadStatus(self: *const Context, thread_id: u32, out: *abi.ProgramThreadInfo) i32 {
        return self.base.threadStatus(thread_id, out);
    }

    pub fn threadHandleStatus(self: *const Context, handle: *const abi.ProgramJoinHandle, out: *abi.ProgramThreadInfo) i32 {
        return self.base.threadHandleStatus(handle, out);
    }

    pub fn ioFileRead(self: *const Context, path: [*:0]const u8, out: []u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileRead(path, out, flags, out_request_id);
    }

    pub fn ioFileReadAt(self: *const Context, path: [*:0]const u8, offset: u64, out: []u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileReadAt(path, offset, out, flags, out_request_id);
    }

    pub fn ioFileWrite(self: *const Context, path: [*:0]const u8, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileWrite(path, data, flags, out_request_id);
    }

    pub fn ioFileAppend(self: *const Context, path: [*:0]const u8, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileAppend(path, data, flags, out_request_id);
    }

    pub fn ioFileWriteAt(self: *const Context, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileWriteAt(path, offset, data, flags, out_request_id);
    }

    pub fn ioFileInfo(self: *const Context, path: [*:0]const u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileInfo(path, flags, out_request_id);
    }

    pub fn ioFileLock(self: *const Context, path: [*:0]const u8, offset: u64, length: u64, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileLock(path, offset, length, flags, out_request_id);
    }

    pub fn ioFileStreamBegin(self: *const Context, path: [*:0]const u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileStreamBegin(path, flags, out_request_id);
    }

    pub fn ioFileStreamWrite(self: *const Context, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileStreamWrite(path, offset, data, flags, out_request_id);
    }

    pub fn ioFileStreamFinish(self: *const Context, path: [*:0]const u8, expected_size: u64, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioFileStreamFinish(path, expected_size, flags, out_request_id);
    }

    pub fn ioFileStreamAbort(self: *const Context, path: [*:0]const u8, out_request_id: *u32) i32 {
        return self.base.ioFileStreamAbort(path, out_request_id);
    }

    pub fn ioServiceCall(self: *const Context, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout_ticks: u64, flags: u32, out_request_id: *u32) i32 {
        return self.base.ioServiceCall(handle, op, request, response_header, response, timeout_ticks, flags, out_request_id);
    }

    pub fn ioStatus(self: *const Context, request_id: u32, out: *abi.ProgramIoInfo) i32 {
        return self.base.ioStatus(request_id, out);
    }

    pub fn ioWait(self: *const Context, request_id: u32, timeout_ticks: u64, out: *abi.ProgramIoInfo) i32 {
        return self.base.ioWait(request_id, timeout_ticks, out);
    }

    pub fn ioClose(self: *const Context, request_id: u32) i32 {
        return self.base.ioClose(request_id);
    }

    pub fn programStatus(self: *const Context, out: *abi.ProgramStatus) void {
        self.base.programStatus(out);
    }

    pub fn programClass(self: *const Context, path: [*:0]const u8, policy: abi.LaunchPolicy) i32 {
        return self.base.programClass(path, policy);
    }

    pub fn programSetConsoleHost(self: *const Context, instance_id: u32, host: abi.ConsoleHostKind) i32 {
        return self.base.programSetConsoleHost(instance_id, host);
    }

    pub fn consoleOutput(self: *const Context, instance_id: u32, out: []u8) i32 {
        return self.base.consoleOutput(instance_id, out);
    }

    pub fn consoleRevision(self: *const Context, instance_id: u32) u32 {
        return self.base.consoleRevision(instance_id);
    }

    pub fn consoleState(self: *const Context, instance_id: u32, out: *abi.ConsoleState) i32 {
        return self.base.consoleState(instance_id, out);
    }

    pub fn consoleSetMetrics(self: *const Context, instance_id: u32, cols: u32, rows: u32) i32 {
        return self.base.consoleSetMetrics(instance_id, cols, rows);
    }

    pub fn consolePushKey(self: *const Context, instance_id: u32, key: u8) i32 {
        return self.base.consolePushKey(instance_id, key);
    }

    pub fn consolePushInput(self: *const Context, instance_id: u32, data: []const u8) i32 {
        return self.base.consolePushInput(instance_id, data);
    }

    pub fn programCurrentConsoleHost(self: *const Context) abi.ConsoleHostKind {
        return self.base.programCurrentConsoleHost();
    }

    pub fn programRequestDesktop(self: *const Context) i32 {
        return self.base.programRequestDesktop();
    }

    pub fn serviceInfo(self: *const Context, index: u32, out: *abi.ServiceInfo) i32 {
        return self.base.serviceInfo(index, out);
    }

    pub fn serviceStatus(self: *const Context, service_name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        return self.base.serviceStatus(service_name, out);
    }

    pub fn serviceOpen(self: *const Context, service_name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        return self.base.serviceOpen(service_name, out);
    }

    pub fn serviceClose(self: *const Context, handle: u32) i32 {
        return self.base.serviceClose(handle);
    }

    pub fn serviceCall(self: *const Context, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout_ticks: u64) i32 {
        return self.base.serviceCall(handle, op, request, response_header, response, timeout_ticks);
    }

    pub fn serviceCallTimeout(self: *const Context, handle: u32, op: u16, request: []const u8, response_header: *abi.ServiceMessageHeader, response: []u8, timeout: time_contract.Timeout) i32 {
        return self.base.serviceCallTimeout(handle, op, request, response_header, response, timeout);
    }

    pub fn serviceEndpointRegister(self: *const Context, service_name: [*:0]const u8, flags: u32, out: *abi.ServiceInfo) i32 {
        return self.base.serviceEndpointRegister(service_name, flags, out);
    }

    pub fn serviceEndpointUnregister(self: *const Context, handle: u32) i32 {
        return self.base.serviceEndpointUnregister(handle);
    }

    pub fn serviceEndpointPoll(self: *const Context, handle: u32) i32 {
        return self.base.serviceEndpointPoll(handle);
    }

    // 0.56.19: Blockierendes Endpoint-Warten (0 = Timeout ohne Arbeit).
    pub fn serviceEndpointWait(self: *const Context, handle: u32, timeout_ticks: u64) i32 {
        return self.base.serviceEndpointWait(handle, timeout_ticks);
    }

    pub fn serviceEndpointWaitTimeout(self: *const Context, handle: u32, timeout: time_contract.Timeout) i32 {
        return self.base.serviceEndpointWaitTimeout(handle, timeout);
    }

    pub fn serviceEndpointRecv(self: *const Context, handle: u32, header: *abi.ServiceMessageHeader, out: []u8) i32 {
        return self.base.serviceEndpointRecv(handle, header, out);
    }

    pub fn serviceEndpointReply(self: *const Context, handle: u32, request_id: u32, status: i32, payload: []const u8) i32 {
        return self.base.serviceEndpointReply(handle, request_id, status, payload);
    }

    pub fn serviceDetail(self: *const Context, index: u32, out: *abi.ServiceDetail) i32 {
        return self.base.serviceDetail(index, out);
    }

    pub fn serviceDetailByName(self: *const Context, service_name: [*:0]const u8, out: *abi.ServiceDetail) i32 {
        return self.base.serviceDetailByName(service_name, out);
    }

    pub fn serviceStart(self: *const Context, service_name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        return self.base.serviceStart(service_name, out);
    }

    pub fn serviceStop(self: *const Context, service_name: [*:0]const u8, out: *abi.ServiceInfo, timeout_ticks: u64) i32 {
        return self.base.serviceStop(service_name, out, timeout_ticks);
    }

    pub fn serviceRestart(self: *const Context, service_name: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        return self.base.serviceRestart(service_name, out);
    }

    pub fn serviceSetStartMode(self: *const Context, service_name: [*:0]const u8, start_mode: u32, out: *abi.ServiceInfo) i32 {
        return self.base.serviceSetStartMode(service_name, start_mode, out);
    }

    pub fn serviceInstall(self: *const Context, service_name: [*:0]const u8, path: [*:0]const u8, args: [*:0]const u8, start_mode: u32, description: [*:0]const u8, out: *abi.ServiceInfo) i32 {
        return self.base.serviceInstall(service_name, path, args, start_mode, description, out);
    }

    pub fn serviceRemove(self: *const Context, service_name: [*:0]const u8) i32 {
        return self.base.serviceRemove(service_name);
    }

    pub fn fileRead(self: *const Context, path: [*:0]const u8, out: []u8) i32 {
        return self.base.fileRead(path, out);
    }

    pub fn moduleResourceStat(self: *const Context, module_path: [*:0]const u8, resource_type: u32, resource_index: u32, resource_name: ?[*:0]const u8) i32 {
        return self.base.moduleResourceStat(module_path, resource_type, resource_index, resource_name);
    }

    pub fn moduleResourceRead(self: *const Context, module_path: [*:0]const u8, resource_type: u32, resource_index: u32, resource_name: ?[*:0]const u8, out: []u8) i32 {
        return self.base.moduleResourceRead(module_path, resource_type, resource_index, resource_name, out);
    }

    pub fn programModulePath(self: *const Context, out: []u8) i32 {
        return self.base.programModulePath(out);
    }

    pub fn programModuleRunning(self: *const Context, module_path: [*:0]const u8) i32 {
        return self.base.programModuleRunning(module_path);
    }

    pub fn fileWrite(self: *const Context, path: [*:0]const u8, data: []const u8) i32 {
        return self.base.fileWrite(path, data);
    }

    pub fn fileReadAt(self: *const Context, path: [*:0]const u8, offset: u32, out: []u8) i32 {
        return self.base.fileReadAt(path, offset, out);
    }

    pub fn fileAppend(self: *const Context, path: [*:0]const u8, data: []const u8) i32 {
        return self.base.fileAppend(path, data);
    }

    pub fn fileStreamBegin(self: *const Context, path: [*:0]const u8, flags: u32) i32 {
        return self.base.fileStreamBegin(path, flags);
    }

    pub fn fileStreamWrite(self: *const Context, path: [*:0]const u8, offset: u64, data: []const u8, flags: u32) i32 {
        return self.base.fileStreamWrite(path, offset, data, flags);
    }

    pub fn fileStreamFinish(self: *const Context, path: [*:0]const u8, expected_size: u64, flags: u32) i32 {
        return self.base.fileStreamFinish(path, expected_size, flags);
    }

    pub fn fileStreamAbort(self: *const Context, path: [*:0]const u8) i32 {
        return self.base.fileStreamAbort(path);
    }

    pub fn dirList(self: *const Context, path: [*:0]const u8, out: []u8) i32 {
        return self.base.dirList(path, out);
    }

    pub fn dirEntry(self: *const Context, path: [*:0]const u8, index: u32, out: []u8) i32 {
        return self.base.dirEntry(path, index, out);
    }

    pub fn driveInfo(self: *const Context, index: u32) ?abi.DriveInfo {
        return self.base.driveInfo(index);
    }

    pub fn fileInfo(self: *const Context, path: [*:0]const u8) ?abi.FileInfo {
        return self.base.fileInfo(path);
    }

    pub fn fileInfoRaw(self: *const Context, path: [*:0]const u8, out: *abi.FileInfo) i32 {
        return self.base.fileInfoRaw(path, out);
    }

    pub fn fileDelete(self: *const Context, path: [*:0]const u8) i32 {
        return self.base.fileDelete(path);
    }

    pub fn fileDeleteIfMatch(
        self: *const Context,
        path: [*:0]const u8,
        expected_size: u64,
        expected_checksum: u32,
    ) i32 {
        return self.base.fileDeleteIfMatch(path, expected_size, expected_checksum);
    }

    /// Declares the create-only publish intent of an already open stream
    /// (0.60.30).
    pub fn fileStreamDeclarePublish(
        self: *const Context,
        staged_path: [*:0]const u8,
        target_path: [*:0]const u8,
        backup_path: [*:0]const u8,
        protocol: u32,
    ) i32 {
        return self.base.fileStreamDeclarePublish(staged_path, target_path, backup_path, protocol);
    }

    /// Backend-exact name collation (0.60.24).
    pub fn pathNamesEqualCollated(
        self: *const Context,
        left_path: [*:0]const u8,
        right_path: [*:0]const u8,
    ) i32 {
        return self.base.pathNamesEqualCollated(left_path, right_path);
    }

    /// Per-payload checked SYSUPD cleanup under one filesystem gate
    /// (0.60.23).
    pub fn fileUpdateCleanupChecked(
        self: *const Context,
        target_path: [*:0]const u8,
        staged_path: [*:0]const u8,
        backup_path: [*:0]const u8,
        previous_backup_path: [*:0]const u8,
        new_size: u64,
        new_checksum: u32,
        old_size: u64,
        old_checksum: u32,
        previous_size: u64,
        previous_checksum: u32,
        flags: u32,
    ) i32 {
        return self.base.fileUpdateCleanupChecked(
            target_path,
            staged_path,
            backup_path,
            previous_backup_path,
            new_size,
            new_checksum,
            old_size,
            old_checksum,
            previous_size,
            previous_checksum,
            flags,
        );
    }

    pub fn fileUpdateAtomicChecked(
        self: *const Context,
        target_path: [*:0]const u8,
        staged_path: [*:0]const u8,
        backup_path: [*:0]const u8,
        new_size: u64,
        new_checksum: u32,
        old_size: u64,
        old_checksum: u32,
        flags: u32,
    ) i32 {
        return self.base.fileUpdateAtomicChecked(
            target_path,
            staged_path,
            backup_path,
            new_size,
            new_checksum,
            old_size,
            old_checksum,
            flags,
        );
    }

    pub fn dirCreate(self: *const Context, path: [*:0]const u8) i32 {
        return self.base.dirCreate(path);
    }

    pub fn dirDelete(self: *const Context, path: [*:0]const u8) i32 {
        return self.base.dirDelete(path);
    }

    pub fn fileRename(self: *const Context, old_path: [*:0]const u8, new_path: [*:0]const u8) i32 {
        return self.base.fileRename(old_path, new_path);
    }

    pub fn fileCopy(self: *const Context, src_path: [*:0]const u8, dst_path: [*:0]const u8) i32 {
        return self.base.fileCopy(src_path, dst_path);
    }

    pub fn fileMove(self: *const Context, src_path: [*:0]const u8, dst_path: [*:0]const u8) i32 {
        return self.base.fileMove(src_path, dst_path);
    }

    pub fn fileReplaceAtomic(self: *const Context, target_path: [*:0]const u8, staged_path: [*:0]const u8, backup_path: [*:0]const u8, flags: u32) i32 {
        return self.base.fileReplaceAtomic(target_path, staged_path, backup_path, flags);
    }

    pub fn systemReplacePrepare(self: *const Context, target_path: [*:0]const u8, staged_path: [*:0]const u8, backup_path: [*:0]const u8, flags: u32) SystemReplacePlan {
        return prepareSystemReplace(self, target_path, staged_path, backup_path, flags);
    }

    pub fn systemReplaceApply(self: *const Context, plan: *SystemReplacePlan) i32 {
        return applySystemReplace(self, plan);
    }

    pub fn systemReplacePrepareAtomic(self: *const Context, target_path: [*:0]const u8, staged_path: [*:0]const u8, backup_path: [*:0]const u8, flags: u32) SystemReplaceAtomicPlan {
        return prepareSystemReplaceAtomic(self, target_path, staged_path, backup_path, flags);
    }

    pub fn systemReplaceApplyAtomic(self: *const Context, plan: *SystemReplaceAtomicPlan) i32 {
        return applySystemReplaceAtomic(self, plan);
    }

    pub fn systemReplaceRollbackAtomic(self: *const Context, plan: *SystemReplaceAtomicPlan) bool {
        return rollbackSystemReplaceAtomic(self, plan);
    }

    pub fn exists(self: *const Context, path: [*:0]const u8) bool {
        return self.base.exists(path);
    }

    pub fn registryKeyInfo(self: *const Context, key_path: [*:0]const u8, out: *abi.RegistryKeyInfo) i32 {
        return self.base.registryKeyInfo(key_path, out);
    }

    pub fn registryEnumKey(self: *const Context, key_path: [*:0]const u8, index: u32, out: []u8) i32 {
        return self.base.registryEnumKey(key_path, index, out);
    }

    pub fn registryEnumValue(self: *const Context, key_path: [*:0]const u8, index: u32, out: *abi.RegistryValueInfo) i32 {
        return self.base.registryEnumValue(key_path, index, out);
    }

    pub fn registryGetValue(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, out_info: *abi.RegistryValueInfo, out: []u8) i32 {
        return self.base.registryGetValue(key_path, value_name, out_info, out);
    }

    pub fn registrySetValue(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value_type: u16, data: []const u8) i32 {
        return self.base.registrySetValue(key_path, value_name, value_type, data);
    }

    pub fn registryDeleteValue(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8) i32 {
        return self.base.registryDeleteValue(key_path, value_name);
    }

    pub fn registrySnapshotBegin(self: *const Context, key_path: [*:0]const u8, kind: u32, cursor: *abi.RegistrySnapshotCursor) i32 {
        return self.base.registrySnapshotBegin(key_path, kind, cursor);
    }

    pub fn registrySnapshotPage(self: *const Context, cursor: *abi.RegistrySnapshotCursor, entries: []abi.RegistrySnapshotEntry, data: []u8, out_page: *abi.RegistrySnapshotPageInfo) i32 {
        return self.base.registrySnapshotPage(cursor, entries, data, out_page);
    }

    pub fn registryBatchMutate(self: *const Context, operations: []const abi.RegistryBatchOperation, blob: []const u8, out_result: *abi.RegistryBatchResult) i32 {
        return self.base.registryBatchMutate(operations, blob, out_result);
    }

    pub fn registrySetString(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: []const u8) i32 {
        return self.base.registrySetString(key_path, value_name, value);
    }

    pub fn registrySetU32(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: u32) i32 {
        return self.base.registrySetU32(key_path, value_name, value);
    }

    pub fn registrySetU64(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: u64) i32 {
        return self.base.registrySetU64(key_path, value_name, value);
    }

    pub fn registrySetBool(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: bool) i32 {
        return self.base.registrySetBool(key_path, value_name, value);
    }

    pub fn registrySetBinary(self: *const Context, key_path: [*:0]const u8, value_name: [*:0]const u8, value: []const u8) i32 {
        return self.base.registrySetBinary(key_path, value_name, value);
    }

    pub fn vmReserve(self: *const Context, size: u64, alignment: u64, flags: u64) ?abi.ProgramVmRegionInfo {
        return self.base.vmReserve(size, alignment, flags);
    }

    pub fn vmReserveRaw(self: *const Context, size: u64, alignment: u64, flags: u64, out: *abi.ProgramVmRegionInfo) i32 {
        return self.base.vmReserveRaw(size, alignment, flags, out);
    }

    pub fn vmCommit(self: *const Context, region_id: u32, offset: u64, len: u64) i32 {
        return self.base.vmCommit(region_id, offset, len);
    }

    pub fn vmCommitFlags(self: *const Context, region_id: u32, offset: u64, len: u64, flags: u64) i32 {
        return self.base.vmCommitFlags(region_id, offset, len, flags);
    }

    pub fn vmDecommit(self: *const Context, region_id: u32, offset: u64, len: u64) i32 {
        return self.base.vmDecommit(region_id, offset, len);
    }

    pub fn vmRelease(self: *const Context, region_id: u32) i32 {
        return self.base.vmRelease(region_id);
    }

    pub fn vmQuery(self: *const Context, region_id: u32) ?abi.ProgramVmRegionInfo {
        return self.base.vmQuery(region_id);
    }

    pub fn vmQueryRaw(self: *const Context, region_id: u32, out: *abi.ProgramVmRegionInfo) i32 {
        return self.base.vmQueryRaw(region_id, out);
    }

    pub fn allocator(self: *const Context) std.mem.Allocator {
        return self.base.allocator();
    }

    pub fn allocatorStats(self: *const Context) @import("vm_allocator.zig").Stats {
        return self.base.allocatorStats();
    }

    pub fn allocatorTrim(self: *const Context) void {
        self.base.allocatorTrim();
    }
};

test "r4sys exposes project and ABI metadata" {
    try std.testing.expectEqualStrings("R4SYS", name);
    try std.testing.expectEqualStrings("R4SYS:Query:1", import_query);
    try std.testing.expectEqual(@as(u32, 1), @intFromEnum(group));
    try std.testing.expectEqual(abi.r4l_abi_version, abi_version);
    try std.testing.expectEqualStrings("Repositories/Kernel", provider_repository);
    try std.testing.expectEqualStrings("Repositories/SDK/Shared/C/include/r4os/r4sys.h", c_header);
}

test "r4sys classifies system replacement targets" {
    try std.testing.expectEqual(SystemReplaceClass.boot_kernel, classifySystemPath("/boot/r4os.elf"));
    try std.testing.expectEqual(SystemReplaceClass.system_library, classifySystemPath("C:\\R4OS\\LIBS\\R4STD.R4L"));
    try std.testing.expectEqual(SystemReplaceClass.driver, classifySystemPath("C:/R4OS/DRIVERS/RTL8139.R4D"));
    try std.testing.expectEqual(SystemReplaceClass.protocol, classifySystemPath("C:\\R4OS\\PROTOCOLS\\NETTCP.R4P"));
    try std.testing.expectEqual(SystemReplaceClass.service, classifySystemPath("C:\\R4OS\\SERVICES\\SSHD.R4X"));
    try std.testing.expectEqual(SystemReplaceClass.software, classifySystemPath("C:\\R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X"));
    try std.testing.expectEqual(SystemReplaceClass.software, classifySystemPath("C:\\R4OS\\SUBSYSTEMS\\r4os.gb\\R4GB.R4X"));
    try std.testing.expectEqual(SystemReplaceClass.unknown, classifySystemPath("C:\\R4OS\\SUBSYSTEMS\\r4os.gb\\README.TXT"));
    try std.testing.expectEqual(SystemReplaceClass.font, classifySystemPath("C:\\R4OS\\FONTS\\TERMINAL8.R4F"));
    try std.testing.expectEqual(SystemReplaceClass.config, classifySystemPath("C:\\R4OS\\CONFIG\\VERSION.R4S"));
    try std.testing.expectEqual(SystemReplaceClass.config, classifySystemPath("C:\\CONFIG.R4S"));
    try std.testing.expectEqual(SystemReplaceClass.sdk, classifySystemPath("C:\\R4OS\\SDK\\Contract\\ABI\\R4LQuery.txt"));
    try std.testing.expectEqual(SystemReplaceClass.temp, classifySystemPath("C:\\TEMP\\SYSREPL.TXT"));
    try std.testing.expectEqual(SystemReplaceClass.data, classifySystemPath("D:\\R4OS\\LIBS\\R4STD.R4L"));
    try std.testing.expectEqual(SystemReplaceClass.unknown, classifySystemPath("C:\\R4OS\\UNBEKANNT\\X.BIN"));
}

test "r4sys system replacement contract keeps atomic sibling boundary" {
    try std.testing.expect(systemReplaceNeedsReboot(.boot_kernel));
    try std.testing.expect(systemReplaceNeedsReboot(.system_library));
    try std.testing.expect(!systemReplaceNeedsReboot(.config));
    try std.testing.expect(!systemReplaceNeedsReboot(.temp));
    try std.testing.expect(sameParentPath("C:\\R4OS\\LIBS\\R4STD.R4L", "C:/R4OS/LIBS/R4STD.NEW"));
    try std.testing.expect(!sameParentPath("C:\\R4OS\\LIBS\\R4STD.R4L", "C:\\R4OS\\UPDATE\\STAGED\\R4STD.NEW"));
    try std.testing.expectEqualStrings("bad-path", systemReplaceResultName(system_replace_error_bad_path));
    try std.testing.expectEqualStrings("system-library", systemReplaceClassName(.system_library));
}
