// Read the actual mounted runtime, never infer recovery from the current
// directory or the presence of a config file on an offline installation.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const Context = @import("r4sys.zig").Context;

pub fn isRecovery(sys: *const Context) bool {
    const runtime = sys.driveInfo('C' - 'A') orelse return false;
    if (runtime.mounted == 0 or runtime.role != abi.drive_role_ram) return false;
    var buffer: [256]u8 = undefined;
    const count = sys.fileRead("C:\\R4OS\\CONFIG\\RECOVERY.R4S", &buffer);
    if (count <= 0) return false;
    var lines = std.mem.splitScalar(u8, buffer[0..@intCast(count)], '\n');
    var format = false;
    var ram = false;
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, std.mem.trimStart(u8, raw, "\xef\xbb\xbf"), "\r");
        format = format or std.mem.eql(u8, line, "RECOVERY_FORMAT=1");
        ram = ram or std.mem.eql(u8, line, "RUNTIME_VOLUME=RAM");
    }
    return format and ram;
}

pub fn offlineRepairAllowed(sys: *const Context, path: []const u8) bool {
    // Transfer services normalize their paths to rooted DOS spelling first.
    // Relative paths and RAM targets cannot obtain the offline exception.
    if (path.len < 3 or path[1] != ':' or (path[2] != '\\' and path[2] != '/')) return false;
    const letter = std.ascii.toUpper(path[0]);
    if (letter < 'A' or letter > 'Z' or letter == 'C' or !isRecovery(sys)) return false;
    const target = sys.driveInfo(letter - 'A') orelse return false;
    return target.mounted != 0 and target.role != abi.drive_role_ram;
}
