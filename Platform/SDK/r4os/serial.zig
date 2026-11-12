const abi = @import("r4os_contract").abi;
pub const Config = abi.SerialConfig;
pub const PortInfo = abi.SerialPortInfo;
pub const Transfer = abi.SerialTransfer;
pub const Status = abi.SerialStatus;
pub const OpenResult = struct { code: i32, handle: u64 = 0 };
pub const IoResult = struct { code: i32, info: Transfer = .{} };
/// Raw COM data and exact partial progress; timeouts use system logical ticks.
pub const Context = struct {
    table: *const abi.R4XStartR4Dev,
    pub fn init(table: *const abi.R4XStartR4Dev) ?Context {
        const self = Context{ .table = table };
        inline for (.{ "serial_count", "serial_port_at", "serial_open", "serial_configure", "serial_read", "serial_write", "serial_drain", "serial_status", "serial_cancel", "serial_close" }) |field| {
            if (self.function(field) == null) return null;
        }
        return self;
    }
    fn function(self: *const Context, comptime field: []const u8) ?@field(abi.R4DevFns, field) {
        if (self.table.magic != abi.r4xstart_r4dev_magic or self.table.abi_version < 21 or self.table.size < @offsetOf(abi.R4XStartR4Dev, field) + 8 or @field(self.table, field) == 0) return null;
        return @ptrFromInt(@field(self.table, field));
    }
    pub fn count(self: *const Context) u32 {
        const f = self.function("serial_count") orelse return 0;
        return f();
    }
    pub fn portAt(self: *const Context, index: u32, out: *PortInfo) i32 {
        const f = self.function("serial_port_at") orelse return abi.err_no_fn;
        return f(index, out);
    }
    pub fn find(self: *const Context, number: u32) ?PortInfo {
        const n = self.count();
        var i: u32 = 0;
        while (i < n) : (i += 1) {
            var info: PortInfo = .{};
            if (self.portAt(i, &info) == abi.serial_ok and info.com_number == number) return info;
        }
        return null;
    }
    pub fn open(self: *const Context, port: PortInfo, config: Config) OpenResult {
        const f = self.function("serial_open") orelse return .{ .code = abi.err_no_fn };
        var handle: u64 = 0;
        const code = f(port.port_id, port.generation, &config, &handle);
        return .{ .code = code, .handle = handle };
    }
    pub fn openNumber(self: *const Context, number: u32, config: Config) OpenResult {
        const port = self.find(number) orelse return .{ .code = abi.serial_error_not_found };
        return self.open(port, config);
    }
    pub fn configure(self: *const Context, handle: u64, config: Config) i32 {
        const f = self.function("serial_configure") orelse return abi.err_no_fn;
        return f(handle, &config);
    }
    pub fn read(self: *const Context, handle: u64, buffer: []u8, timeout_ticks: u64) IoResult {
        if (buffer.len > abi.serial_max_transfer_bytes) return .{ .code = abi.serial_error_too_large };
        const f = self.function("serial_read") orelse return .{ .code = abi.err_no_fn };
        var info: Transfer = .{};
        const code = f(handle, buffer.ptr, @intCast(buffer.len), timeout_ticks, &info);
        return .{ .code = code, .info = info };
    }
    pub fn write(self: *const Context, handle: u64, buffer: []const u8, timeout_ticks: u64) IoResult {
        if (buffer.len > abi.serial_max_transfer_bytes) return .{ .code = abi.serial_error_too_large };
        const f = self.function("serial_write") orelse return .{ .code = abi.err_no_fn };
        var info: Transfer = .{};
        const code = f(handle, buffer.ptr, @intCast(buffer.len), timeout_ticks, &info);
        return .{ .code = code, .info = info };
    }
    pub fn drain(self: *const Context, handle: u64, timeout_ticks: u64) i32 {
        const f = self.function("serial_drain") orelse return abi.err_no_fn;
        return f(handle, timeout_ticks);
    }
    pub fn status(self: *const Context, handle: u64, out: *Status) i32 {
        const f = self.function("serial_status") orelse return abi.err_no_fn;
        return f(handle, out);
    }
    pub fn cancel(self: *const Context, handle: u64) i32 {
        const f = self.function("serial_cancel") orelse return abi.err_no_fn;
        return f(handle);
    }
    /// Success alone releases the handle. Failure retains the same closing port.
    pub fn close(self: *const Context, handle: u64, flags: u32, timeout_ticks: u64) i32 {
        const f = self.function("serial_close") orelse return abi.err_no_fn;
        return f(handle, flags, timeout_ticks);
    }
};
