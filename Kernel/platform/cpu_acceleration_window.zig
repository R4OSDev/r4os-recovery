// Port of the canonical CPU work receipt policy. The caller supplies the
// actual local CPU/clock boundary; this part never grants hardware itself.
const c = @import("../program/generation2.zig").abi.shared;
pub fn run(initial: c.CpuAccelerationWork, hw: anytype) c.CpuAccelerationWork {
    var value = initial;
    if (!hw.current()) {
        value.status = c.cpu_accel_work_status_identity_changed;
        return value;
    }
    value.flags |= c.cpu_accel_work_flag_identity_valid | c.cpu_accel_work_flag_feature_granted;
    const begin = hw.now() orelse {
        value.status = c.cpu_accel_work_status_clock_unavailable;
        return value;
    };
    value.begin_ns = begin;
    if (!hw.current()) {
        value.flags &= ~c.cpu_accel_work_flag_identity_valid;
        value.status = c.cpu_accel_work_status_identity_changed;
        return value;
    }
    value.flags |= c.cpu_accel_work_flag_callback_started;
    value.callback_result = hw.work(value.iterations);
    value.flags |= c.cpu_accel_work_flag_callback_returned;
    if (!hw.current()) {
        value.flags &= ~c.cpu_accel_work_flag_identity_valid;
        value.status = c.cpu_accel_work_status_identity_changed;
        return value;
    }
    const end = hw.now() orelse {
        value.status = c.cpu_accel_work_status_clock_unavailable;
        return value;
    };
    value.end_ns = end;
    if (end < begin) {
        value.status = c.cpu_accel_work_status_clock_regressed;
        return value;
    }
    value.flags |= c.cpu_accel_work_flag_clock_valid;
    if (end - begin > c.cpu_accel_max_window_ns) {
        value.status = c.cpu_accel_work_status_over_budget;
        return value;
    }
    value.flags |= c.cpu_accel_work_flag_within_budget;
    if (value.callback_result != 0) value.status = c.cpu_accel_work_status_callback_aborted;
    return value;
}
