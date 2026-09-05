// Recovery admission uses the common keyboard queue and frozen HID protocols.
// It deliberately admits no pointing device; normal R4OS keeps its defaults.
const hid = @import("../driver/usb/hid.zig");
const xhci = @import("../driver/usb/xhci.zig");
const registry = @import("../driver/registry.zig");
const r4p = @import("../program/r4p.zig");
const log = @import("log.zig");

pub fn init() bool {
    // Load protocols before entering controller ownership (module I/O may wait).
    if (!r4p.hasActiveR4p("usb.hid_boot") or !r4p.hasActiveR4p("usb.hid_report")) return false;
    const slot = registry.beginLoad("USBHID", 3, 1);
    const bound = hid.initWithOptions(.{ .bind_mouse = false });
    const status = hid.status();
    if (slot) |index| {
        registry.setState(index, if (!status.initialized) .failed else if (bound) .active else .initialized);
    }
    if (!status.initialized or status.mouse_bound) return false;
    if (!xhci.startPortTask()) return false;
    if (bound and !hid.startPollTask()) return false;
    log.puts("[RECOVERYINPUT] ready=1 keyboard_usb=");
    log.putDec(@intFromBool(status.keyboard_bound));
    log.puts(" mouse=0 protocols=USBHID,HIDREPORT reason=");
    log.puts(status.reason);
    log.puts("\r\n");
    return true;
}
