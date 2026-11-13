const services = @import("kernel/services.zig");

test "service module reset tests are reachable" {
    _ = services.API_VERSION;
}

test "typed TCP retains drained FIN and RST until explicit owner close" {
    const tcp = @import("net/tcp.zig");
    tcp.reset();
    try @import("std").testing.expect(tcp.performanceContractProbe());
}
