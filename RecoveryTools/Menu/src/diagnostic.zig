// Explicit /UISMOKE guest acceptance. The visible console still receives
// physical keyboard events; this second standard Terminal is never drawn.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;

pub const Session = struct {
    handle: abi.ProgramProcessHandle = .{},
    saved: [4096]u8 = undefined,
    length: usize = 0,
    clear_count: u32 = std.math.maxInt(u32),
    scrolled: bool = false,

    pub fn observe(self: *Session, sys: r4os.r4sys.Context, state: abi.ConsoleState) void {
        if (self.handle.instance_id == 0) return;
        if (state.clear_count != self.clear_count) {
            self.clear_count = state.clear_count;
            var text: [80]u8 = undefined;
            sys.write(std.fmt.bufPrint(&text, "[RECOVERYUI] console-clear={d}\r\n", .{state.clear_count}) catch return);
        }
        if (!self.scrolled and state.scrollback_lines > state.rows) {
            self.scrolled = true;
            sys.write("[RECOVERYUI] console-scroll=1\r\n");
        }
    }

    pub fn begin(self: *Session, sys: r4os.r4sys.Context, desk: r4os.r4desk.Context) bool {
        if (sys.programSpawnWithConsoleHostHandle("C:\\R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X", "/NOAUTOEXEC", .console, .terminal_window, &self.handle) < 0) return false;
        const deadline = sys.ticks() + sys.ticksFromMilliseconds(5000);
        var sent = false;
        while (sys.ticks() < deadline) {
            const got = desk.consoleOutput(self.handle.instance_id, &self.saved);
            if (got > 0 and got <= self.saved.len) {
                const output = self.saved[0..@intCast(got)];
                if (std.mem.endsWith(u8, std.mem.trimEnd(u8, output, " \r\n"), ">")) {
                    if (!sent) {
                        if (desk.consolePushInput(self.handle.instance_id, "ECHO REMOTE-SESSION-KEPT\n") < 0) return false;
                        sent = true;
                    } else if (std.mem.count(u8, output, "REMOTE-SESSION-KEPT") == 2) {
                        self.length = output.len;
                        sys.write("[RECOVERYUI] independent-session=READY\r\n");
                        return true;
                    }
                }
            }
            sys.sleepTicks(1);
        }
        sys.write("[RECOVERYUI] independent-session=TIMEOUT output:\r\n");
        const got = desk.consoleOutput(self.handle.instance_id, &self.saved);
        if (got > 0 and got <= self.saved.len) sys.write(self.saved[0..@intCast(got)]);
        return false;
    }

    pub fn finish(self: *Session, sys: r4os.r4sys.Context, desk: r4os.r4desk.Context) bool {
        if (self.handle.instance_id == 0) return true;
        var current: [4096]u8 = undefined;
        const got = desk.consoleOutput(self.handle.instance_id, &current);
        if (got != self.length or !std.mem.eql(u8, self.saved[0..self.length], current[0..self.length])) return false;
        if (desk.consolePushInput(self.handle.instance_id, "EXIT\n") < 0) return false;
        var done = abi.ProgramProcessCompletion{};
        if (sys.programHandleWait(&self.handle, sys.ticksFromMilliseconds(5000), &done) != abi.program_handle_ok or done.exit_code != 0) return false;
        if (sys.programHandleReap(&self.handle, &done) != abi.program_handle_ok) return false;
        self.handle = .{};
        sys.write("[RECOVERYUI] independent-session=UNCHANGED cleanup=OK\r\n");
        return true;
    }

    pub fn close(self: *Session, sys: r4os.r4sys.Context) void {
        if (self.handle.instance_id == 0) return;
        _ = sys.programHandleRequestClose(&self.handle);
        var done = abi.ProgramProcessCompletion{};
        if (sys.programHandleWait(&self.handle, sys.ticksFromMilliseconds(5000), &done) == abi.program_handle_ok)
            _ = sys.programHandleReap(&self.handle, &done);
    }
};
