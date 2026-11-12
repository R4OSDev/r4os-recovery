const r4os = @import("r4os");

var driver_api: ?*const r4os.r4dev.DriverApi2 = null;
var activated = false;

comptime {
    if (!@import("builtin").is_test) asm (r4os.technical2.driverEntriesAsm("xhci_init", "xhci_shutdown"));
}

// XHCI.R4D is deliberately a thin activation owner. The kernel backend is
// the sole PCI/MMIO/DMA, transfer-ring, event and shutdown implementation.
// This keeps module ownership/unload visible without probing the controller
// twice or exporting kernel hardware internals into a loadable module.
export fn xhci_init(api: *const r4os.r4dev.DriverApi2) callconv(.c) i32 {
    var ctx = r4os.r4dev.DriverContext2.init(api);
    if (!ctx.requires(.{ "activate_usb_host_controller", "unregister_usb_host_controller" })) {
        ctx.logError("XHCI.R4D driver api mismatch");
        return -3;
    }
    driver_api = api;
    const result = ctx.activateUsbHostController("XHCI", r4os.abi.usb_host_source_preload);
    if (result < 0) {
        driver_api = null;
        ctx.logError("XHCI.R4D canonical host activation failed");
        return result;
    }
    activated = true;
    ctx.logInfo("XHCI.R4D canonical kernel host activated; owner=preload");
    return 0;
}

export fn xhci_shutdown() callconv(.c) i32 {
    if (!activated) {
        driver_api = null;
        return 0;
    }
    const api = driver_api orelse return -1;
    var ctx = r4os.r4dev.DriverContext2.init(api);
    const result = ctx.unregisterUsbHostController("XHCI");
    if (result == 0) {
        activated = false;
        driver_api = null;
    }
    return result;
}

test "xHCI module stays an activation-only owner" {
    const testing = @import("std").testing;
    try testing.expect(@sizeOf(@TypeOf(driver_api)) == @sizeOf(?*const r4os.r4dev.DriverApi2));
}
