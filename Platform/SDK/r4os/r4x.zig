const abi = @import("r4os_contract").abi;
const r4xstart = @import("r4xstart.zig");

pub const StartContext = abi.R4XStartContext;
pub const Import = abi.R4XStartImport;
pub const R4Sys = r4xstart.R4Sys;
pub const R4Desk = r4xstart.R4Desk;
pub const R4Draw = r4xstart.R4Draw;

pub fn entryAsm(comptime target: []const u8) []const u8 {
    return r4xstart.entryAsm(target);
}

pub fn init(raw: *const StartContext) Context {
    return Context.init(raw);
}

pub const Context = struct {
    start: r4xstart.Context,

    pub fn init(raw: *const StartContext) Context {
        return .{ .start = r4xstart.Context.init(raw) };
    }

    pub fn valid(self: *const Context) bool {
        return self.start.valid();
    }

    pub fn args(self: *const Context) []const u8 {
        return self.start.args();
    }

    pub fn importCount(self: *const Context) u32 {
        return self.start.importCount();
    }

    pub fn importAt(self: *const Context, index: usize) ?*const Import {
        return self.start.importAt(index);
    }

    pub fn findImport(self: *const Context, group: abi.R4LGroup) ?*const Import {
        return self.start.findImport(group);
    }

    pub fn findImportNamed(self: *const Context, module_name: []const u8, symbol_name: []const u8) ?*const Import {
        return self.start.findImportNamed(module_name, symbol_name);
    }

    pub fn r4sys(self: *const Context) ?R4Sys {
        return self.start.r4sys();
    }

    pub fn r4desk(self: *const Context) ?R4Desk {
        return self.start.r4desk();
    }

    pub fn r4draw(self: *const Context) ?R4Draw {
        return self.start.r4draw();
    }
};
