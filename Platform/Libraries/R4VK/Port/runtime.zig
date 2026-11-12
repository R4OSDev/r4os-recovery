// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r4os = @import("r4os");
pub const threads = @import("r4native").threads;
const application = @import("r4native").application;
pub const memory = @import("memory.zig");
pub const time = @import("time.zig");
pub const math = @import("math.zig");
pub const loader = @import("loader.zig");
pub const compiler = @import("compiler.zig");
pub const platform = @import("platform.zig");
pub const console = @import("console.zig");
pub const window = @import("window.zig");

pub fn bind(kernel: *const r4os.abi.R4XStartR4Sys) bool {
    if (kernel.abi_version < 21 or kernel.size < @offsetOf(r4os.abi.R4XStartR4Sys, "thread_current_handle") + 8) return false;
    inline for (.{ "vm_reserve", "vm_commit", "vm_release", "program_local_get", "program_local_publish", "sleep_ticks" }) |field|
        if (@field(kernel.*, field) == 0) return false;
    return threads.bind(kernel);
}

pub fn bind2(raw: *const r4os.platform2.abi.R4XStartContext2) bool {
    const context = r4os.platform2.Context.init(raw) catch return false;
    if (!threads.bind2(context.system() orelse return false) or !application.bind2(raw)) return false;
    const saved = application.snapshot() orelse return false;
    return platform.bind2(&saved.generation2.context);
}

comptime {
    _ = @import("cpp.zig");
    _ = memory;
    _ = time;
    _ = math;
    _ = loader;
    _ = console;
    _ = window;
}
