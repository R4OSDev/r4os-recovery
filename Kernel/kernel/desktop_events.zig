// 0.56.28: Gemeinsames Desktop-Aktivitaets-Event. Input- und
// Fenster-Ereignisquellen (PS/2-Keyboard/-Mouse, USB-HID via
// injectScancode/Mouse-Packets, RDP-remoteInputPush, GUI-/Console-
// Revision-Bumps in r4x.zig) signalisieren hier; der Desktop wartet
// mit desktopActivityWait statt in einem festen Sleep-Poll-Raster.
// Sequenznummer + waitUnless-Praedikat machen den Wait Lost-Wakeup-
// sicher (Muster 0.56.19/0.56.22). signal() ist IRQ-tauglich:
// WaitQueue.wakeAll arbeitet unter dem Scheduler-Runtime-Owner und weckt den
// durch seinen intrusiven WaitNode generationstreu gebundenen Task wie der
// Timer-Tick.
const sync = @import("../sched/sync.zig");

var activity: sync.WaitQueue = sync.WaitQueue.init();
var signal_seq: u64 = 0;

pub fn signal() void {
    _ = activity.bumpSequenceAndWakeAll(&signal_seq);
}

pub fn sequence() u64 {
    return activity.readSequence(&signal_seq);
}

const WaitCtx = struct {
    last_seq: u64,
};

fn predStillWaitActivity(raw: *anyopaque) bool {
    const c: *WaitCtx = @ptrCast(@alignCast(raw));
    return signal_seq == c.last_seq;
}

// Compare again in the scheduler enrollment critical section. Each caller
// supplies its actual deadline; input, completion or stop can wake it earlier.
pub fn wait(last_seq: u64, timeout_ticks: u64, out_seq: *u64) i32 {
    var current = sequence();
    if (current == last_seq and timeout_ticks != 0) {
        var ctx = WaitCtx{ .last_seq = last_seq };
        const result = activity.waitUnless(timeout_ticks, "desk-activity", predStillWaitActivity, &ctx);
        current = sequence();
        if (result == .failed and current == last_seq) return -1;
    }
    out_seq.* = current;
    return @intFromBool(current != last_seq);
}
