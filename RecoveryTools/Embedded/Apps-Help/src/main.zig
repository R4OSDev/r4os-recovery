const r4os = @import("r4os");

const path_max: usize = 128;
const path_env_max: usize = r4os.abi.environment_value_max;
const dir_entry_max: usize = 128;
const command_column: usize = 20;
const software_column: usize = 13;

const App = struct {
    sys: r4os.r4sys.Context,
    files: r4os.Files,

    fn write(self: *const App, text: []const u8) void {
        self.sys.write(text);
    }

    fn line(self: *const App, text: []const u8) void {
        self.write(text);
        self.write("\r\n");
    }
};

pub fn r4_app_main(contract: *r4os.App2) i32 {
    const files = contract.files() orelse return r4os.abi.err_no_fn;
    const app = App{ .sys = contract.system(), .files = files };
    const args = trim(contract.args());
    if (args.len == 0) {
        printBuiltins(&app);
        return 0;
    }
    if (equalsIgnoreCase(args, "/S") or equalsIgnoreCase(args, "-S") or equalsIgnoreCase(args, "S") or equalsIgnoreCase(args, "SOFTWARE") or equalsIgnoreCase(args, "/SOFTWARE")) {
        printSoftware(&app);
        return 0;
    }
    if (equalsIgnoreCase(args, "/?") or equalsIgnoreCase(args, "-?") or equalsIgnoreCase(args, "/HELP") or equalsIgnoreCase(args, "--HELP")) {
        printUsage(&app);
        return 0;
    }
    app.write("HELP: unknown option ");
    app.line(args);
    printUsage(&app);
    return 1;
}

fn printBuiltins(app: *const App) void {
    app.line("R4OS Terminal Help");
    app.line("==================");
    app.line("");
    app.line("Internal Commands");
    app.line("-----------------");

    printFileCommands(app);
    printSessionCommands(app);
    printSystemCommands(app);
    printLimitedCommands(app);

    app.line("");
    app.line("Type HELP /S to list Terminal software from the PATH.");
}

fn printFileCommands(app: *const App) void {
    app.line("");
    app.line("Files and Directories");
    printEntry(app, "DIR", "List directory contents", command_column);
    printEntry(app, "CD/CHDIR", "Show or change the current directory", command_column);
    printEntry(app, "MD/MKDIR", "Create a directory", command_column);
    printEntry(app, "RD/RMDIR", "Remove a directory", command_column);
    printEntry(app, "TYPE", "Print a file", command_column);
    printEntry(app, "MORE", "Print a file page-style", command_column);
    printEntry(app, "SORT", "Sort a text file", command_column);
    printEntry(app, "COPY", "Copy one file", command_column);
    printEntry(app, "DEL/ERASE", "Delete one file", command_column);
    printEntry(app, "REN/RENAME", "Rename a file", command_column);
}

fn printSessionCommands(app: *const App) void {
    app.line("");
    app.line("Session and Batch");
    printEntry(app, "PATH", "Show or set the session search path", command_column);
    printEntry(app, "PATH /P", "Show or set the persistent system PATH", command_column);
    printEntry(app, "PROMPT", "Show or set the prompt format", command_column);
    printEntry(app, "SET", "Show or set supported variables", command_column);
    printEntry(app, "ECHO", "Print text or control batch echo", command_column);
    printEntry(app, "REM", "Batch comment", command_column);
    printEntry(app, "PAUSE", "Wait for a key", command_column);
    printEntry(app, "SLEEP", "Wait for milliseconds", command_column);
    printEntry(app, "CLS", "Clear the console", command_column);
    printEntry(app, "VERIFY", "Show or set the verify flag", command_column);
    printEntry(app, "C:/D:", "Switch to a mounted drive", command_column);
    printEntry(app, "PATH=", "Set PATH using assignment syntax", command_column);
    printEntry(app, "PROMPT=", "Set PROMPT using assignment syntax", command_column);
}

fn printSystemCommands(app: *const App) void {
    app.line("");
    app.line("System");
    printEntry(app, "DATE", "Show the current date", command_column);
    printEntry(app, "TIME", "Show the current time", command_column);
    printEntry(app, "VOL", "Show volume information", command_column);
    printEntry(app, "VER", "Show the R4OS shell version", command_column);
    printEntry(app, "DESKTOP", "Return from Terminal Mode to Desktop", command_column);
    printEntry(app, "POWEROFF/SHUTDOWN", "Power off the system", command_column);
    printEntry(app, "REBOOT", "Reboot the system", command_column);
    printEntry(app, "HALT", "Halt the system", command_column);
}

fn printLimitedCommands(app: *const App) void {
    app.line("");
    app.line("Reserved or Limited");
    printEntry(app, "COLOR", "Reserved; console colors are not available yet", command_column);
    printEntry(app, "GOTO/CALL/SHIFT", "Reserved batch control flow", command_column);
    printEntry(app, "IF/FOR", "Reserved batch control flow", command_column);
    printEntry(app, ">", "Built-in output redirection", command_column);
    printEntry(app, ">>", "Built-in output append redirection", command_column);
    printEntry(app, "|/<", "Recognized, not available yet", command_column);
}

fn printSoftware(app: *const App) void {
    app.line("R4OS Terminal Software");
    app.line("======================");
    app.line("");
    app.line("PATH");
    var path_env: [path_env_max]u8 = undefined;
    const path_len_raw = app.sys.envGet("PATH", path_env[0..]);
    if (path_len_raw < 0) {
        app.line("  <PATH unavailable>");
        app.line("");
        app.line("Programs found: 0");
        return;
    }
    const path = path_env[0..@as(usize, @intCast(path_len_raw))];
    app.write("  ");
    app.line(path);

    var total: u32 = 0;
    var pos: usize = 0;
    while (nextPathDirectory(path, &pos)) |dir| {
        total += printSoftwareDir(app, dir);
    }

    app.line("");
    app.write("Programs found: ");
    writeDec(app, total);
    app.line("");
}

fn printUsage(app: *const App) void {
    app.line("HELP.R4X - R4OS terminal help");
    app.line("");
    app.line("Usage:");
    app.line("  HELP       List internal Terminal commands");
    app.line("  HELP /S    List software in the Terminal PATH");
}

fn printSoftwareDir(app: *const App, dir: []const u8) u32 {
    app.line("");
    app.line(dir);

    var directory = r4os.FilePath.parse(dir) catch {
        app.line("  <path too long>");
        return 0;
    };

    var entry_buf: [dir_entry_max]u8 = .{0} ** dir_entry_max;
    var iterator = app.files.iterate(directory.asZ());
    var count: u32 = 0;
    while (true) {
        const entry = switch (iterator.next(entry_buf[0..])) {
            .entry => |entry| entry,
            .end => break,
            .failure => break,
        };
        if (entry.kind != .file) continue;
        const full = entry.path;
        const name = baseName(full);
        if (!hasR4XExtension(name)) continue;
        if (!classifiesAsProgram(app, full)) continue;

        const display = stripR4XExtension(name);
        printEntry(app, display, softwareSummary(display), software_column);
        count += 1;
    }

    if (count == 0) app.line("  <none>");
    return count;
}

fn classifiesAsProgram(app: *const App, path: []const u8) bool {
    var path_buf: [path_max:0]u8 = .{0} ** path_max;
    const path_z = copyZ(path_buf[0..], path) orelse return false;
    return app.sys.programClass(path_z, .auto) > 0;
}

fn softwareSummary(name: []const u8) []const u8 {
    if (equalsIgnoreCase(name, "HELP")) return "Terminal help";
    if (equalsIgnoreCase(name, "TERMINAL")) return "Terminal shell";
    if (equalsIgnoreCase(name, "SERVMAN")) return "Service manager";
    if (equalsIgnoreCase(name, "BOOTINFO")) return "Boot information";
    if (equalsIgnoreCase(name, "SYSINFO")) return "System information";
    if (equalsIgnoreCase(name, "SYSUPD")) return "System update verifier and applier";
    if (equalsIgnoreCase(name, "REG")) return "Registry tool";
    if (equalsIgnoreCase(name, "PING")) return "Network ping";
    if (equalsIgnoreCase(name, "IPCONFIG")) return "Network configuration";
    if (equalsIgnoreCase(name, "DHCP")) return "DHCP control";
    if (equalsIgnoreCase(name, "DNSLOOKUP")) return "DNS lookup";
    if (equalsIgnoreCase(name, "NETCAT")) return "TCP client";
    if (equalsIgnoreCase(name, "TCPECHO")) return "TCP echo test";
    if (equalsIgnoreCase(name, "HTTPGET")) return "HTTP GET client";
    if (equalsIgnoreCase(name, "SEND")) return "Serial-link send";
    if (equalsIgnoreCase(name, "RECV")) return "Serial-link receive";
    if (equalsIgnoreCase(name, "BEEP")) return "Audio beep test";
    if (equalsIgnoreCase(name, "SYNTH")) return "Synth/audio player";
    if (equalsIgnoreCase(name, "FSDIAG")) return "Filesystem diagnostics";
    if (equalsIgnoreCase(name, "R4CFGD")) return "Config diagnostics";
    if (equalsIgnoreCase(name, "AUDIOD")) return "Audio diagnostics";
    if (equalsIgnoreCase(name, "CLIPD")) return "Clipboard diagnostics";
    if (equalsIgnoreCase(name, "SYNTHD")) return "Synth diagnostics";
    if (equalsIgnoreCase(name, "INPUTD")) return "Input diagnostics";
    if (equalsIgnoreCase(name, "BOOTDIAG")) return "Boot diagnostics";
    if (equalsIgnoreCase(name, "LOADERD")) return "Loader diagnostics";
    if (equalsIgnoreCase(name, "STACKD")) return "Stack diagnostics";
    if (equalsIgnoreCase(name, "APPHEAPD")) return "Application heap diagnostics";
    if (equalsIgnoreCase(name, "CLEANUPD")) return "Cleanup diagnostics";
    if (equalsIgnoreCase(name, "NETSVC")) return "Network service diagnostics";
    if (equalsIgnoreCase(name, "NETR4P")) return "Network protocol diagnostics";
    if (equalsIgnoreCase(name, "R4SLD")) return "Serial-link diagnostics";
    if (equalsIgnoreCase(name, "NETDIAG")) return "Network diagnostics";
    if (equalsIgnoreCase(name, "USBDIAG")) return "USB diagnostics";
    if (equalsIgnoreCase(name, "STORDIAG")) return "Storage diagnostics";
    if (equalsIgnoreCase(name, "DISPLAYD")) return "Display diagnostics";
    if (equalsIgnoreCase(name, "HWDIAG")) return "Hardware diagnostics";
    if (equalsIgnoreCase(name, "MEMSUITE")) return "Memory diagnostics";
    if (equalsIgnoreCase(name, "STDDIAG")) return "Standard library diagnostics";
    if (equalsIgnoreCase(name, "SVCAPPD")) return "Service app diagnostics";
    return "R4X program";
}

fn printEntry(app: *const App, name: []const u8, summary: []const u8, column: usize) void {
    app.write("  ");
    app.write(name);
    if (name.len >= column) {
        app.write("  ");
    } else {
        var i = name.len;
        while (i < column) : (i += 1) app.write(" ");
    }
    app.line(summary);
}

fn writeDec(app: *const App, value: u32) void {
    var buf: [10]u8 = undefined;
    var pos = buf.len;
    var n = value;
    if (n == 0) {
        app.write("0");
        return;
    }
    while (n > 0) {
        pos -= 1;
        buf[pos] = '0' + @as(u8, @intCast(n % 10));
        n /= 10;
    }
    app.write(buf[pos..]);
}

fn copyZ(out: []u8, text: []const u8) ?[*:0]const u8 {
    if (out.len == 0 or text.len >= out.len) return null;
    if (text.len != 0) @memcpy(out[0..text.len], text);
    out[text.len] = 0;
    return @ptrCast(out.ptr);
}

fn zSpan(ptr: [*:0]const u8) []const u8 {
    var len: usize = 0;
    while (ptr[len] != 0) : (len += 1) {}
    return ptr[0..len];
}

fn spanZ(bytes: []const u8) []const u8 {
    var len: usize = 0;
    while (len < bytes.len and bytes[len] != 0) : (len += 1) {}
    return bytes[0..len];
}

fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = value.len;
    while (start < end and (value[start] == ' ' or value[start] == '\t' or value[start] == '\r' or value[start] == '\n')) : (start += 1) {}
    while (end > start and (value[end - 1] == ' ' or value[end - 1] == '\t' or value[end - 1] == '\r' or value[end - 1] == '\n')) : (end -= 1) {}
    return value[start..end];
}

fn nextPathDirectory(path: []const u8, pos: *usize) ?[]const u8 {
    while (pos.* <= path.len) {
        while (pos.* < path.len and path[pos.*] == ';') : (pos.* += 1) {}
        if (pos.* >= path.len) return null;
        const start = pos.*;
        while (pos.* < path.len and path[pos.*] != ';') : (pos.* += 1) {}
        const end = pos.*;
        if (pos.* < path.len and path[pos.*] == ';') pos.* += 1;
        const dir = trim(path[start..end]);
        if (dir.len != 0) return dir;
    }
    return null;
}

fn baseName(path: []const u8) []const u8 {
    var start: usize = 0;
    var i: usize = 0;
    while (i < path.len) : (i += 1) {
        if (path[i] == '\\' or path[i] == '/') start = i + 1;
    }
    return path[start..];
}

fn hasR4XExtension(name: []const u8) bool {
    if (name.len < 4) return false;
    return equalsIgnoreCase(name[name.len - 4 ..], ".R4X");
}

fn stripR4XExtension(name: []const u8) []const u8 {
    if (hasR4XExtension(name)) return name[0 .. name.len - 4];
    return name;
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (upper(a[i]) != upper(b[i])) return false;
    }
    return true;
}

fn upper(value: u8) u8 {
    if (value >= 'a' and value <= 'z') return value - ('a' - 'A');
    return value;
}
