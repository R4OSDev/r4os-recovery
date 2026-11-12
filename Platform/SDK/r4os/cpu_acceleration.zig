//! Optional CPU leaf execution. Cached information is only a dispatch hint;
//! every optional instruction needs a fresh kernel grant for this exact call.
const abi = @import("r4os_contract").abi;
pub const WorkFn = abi.R4DevFns.cpu_acceleration_work;
pub const InfoFn = abi.R4DevFns.cpu_acceleration_info;

pub fn protocolWork(api: *const abi.ProtocolApi) ?WorkFn {
    if (api.size < @offsetOf(abi.ProtocolApi, "cpu_acceleration_work") + @sizeOf(usize)) return null;
    return api.cpu_acceleration_work;
}
pub fn protocolInfo(api: *const abi.ProtocolApi) ?InfoFn {
    if (api.size < @offsetOf(abi.ProtocolApi, "cpu_acceleration_info") + @sizeOf(usize)) return null;
    return api.cpu_acceleration_info;
}
pub fn accepted(v: *const abi.CpuAccelerationWork, kind: u32, iterations: u32) bool {
    const required = abi.cpu_accel_work_flag_callback_started | abi.cpu_accel_work_flag_callback_returned |
        abi.cpu_accel_work_flag_identity_valid | abi.cpu_accel_work_flag_if_preserved |
        abi.cpu_accel_work_flag_clock_valid | abi.cpu_accel_work_flag_within_budget |
        abi.cpu_accel_work_flag_feature_granted;
    return v.version == 1 and v.size >= @sizeOf(abi.CpuAccelerationWork) and
        v.status == abi.cpu_accel_work_status_completed and v.callback_result == 0 and
        v.work_kind == kind and v.iterations == iterations and v.epoch != 0 and
        v.capture_sequence != 0 and v.flags & required == required and
        v.original_if == 512 and v.final_if == 512 and
        v.end_ns >= v.begin_ns and v.end_ns - v.begin_ns <= abi.cpu_accel_max_window_ns and
        (v.clock_source == 1 or v.clock_source == 2) and
        (kind != abi.cpu_accel_work_kind_sha256 or (v.granted_mask & abi.cpu_accel_feature_sha != 0 and v.xcr0 & 7 == 7)) and
        (kind != abi.cpu_accel_work_kind_rdrand or v.granted_mask & abi.cpu_accel_feature_rdrand != 0);
}
