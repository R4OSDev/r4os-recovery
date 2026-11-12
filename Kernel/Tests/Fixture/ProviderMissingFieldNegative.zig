const api = @import("contract2");

// Group providers deliberately allow absent optional slots in the current
// canonical Contract. Technical DriverApi2 still requires its real prefix
// callbacks: a header alone must never compile as a usable driver provider.
comptime {
    const provider: api.DriverApi2 = .{ .magic = api.driver_magic, .version = api.driver_version, .size = @sizeOf(api.DriverApi2), .reserved = 0 };
    _ = provider;
}
