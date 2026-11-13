#![no_std]

use r4os_contract as abi;

#[unsafe(no_mangle)]
/// # Safety
/// Context, table and the callable table slot remain valid through this call.
pub unsafe extern "C" fn r4os_rust_generation2(
    context: *const abi::generation2::R4XStartContext2,
    table: *const abi::generation2::R4XStartR4Sys2,
) -> i32 {
    let context = unsafe { &*context };
    let table = unsafe { &*table };
    assert_eq!(
        (context.magic, context.abi_major, context.size),
        (abi::generation2::START_MAGIC, 2, 120)
    );
    assert_eq!(
        (table.magic, table.size),
        (
            abi::generation2::R4SYS_MAGIC,
            core::mem::size_of_val(table) as u32
        )
    );
    assert_ne!(table.write, 0);
    let default = abi::generation2::R4XStartContext2::default();
    assert_eq!(
        (default.magic, default.abi_major, default.size),
        (abi::generation2::START_MAGIC, 2, 120)
    );
    let default = abi::generation2::R4XStartR4Sys2::default();
    assert_eq!(
        (default.magic, default.abi_version, default.size),
        (
            abi::generation2::R4SYS_MAGIC,
            6,
            core::mem::size_of_val(&default) as u32
        )
    );
    let call: abi::generation2::R4SysFns2::write = unsafe { core::mem::transmute(table.write as usize) };
    unsafe { call(b"API2".as_ptr(), 4) }
}

#[unsafe(no_mangle)]
/// # Safety
/// The caller retains one fully initialized ProtocolApi for this call.
pub unsafe extern "C" fn r4os_rust_protocol_alloc(
    api: *const abi::ProtocolApi,
    bytes: u32,
    alignment: u32,
) -> *mut core::ffi::c_void {
    let api = unsafe { &*api };
    assert_eq!(api.magic, 0x81234567);
    assert_eq!(api.size as usize, core::mem::size_of::<abi::ProtocolApi>());
    unsafe { (api.alloc)(bytes, alignment) }
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_model_name() -> *const u8 {
    c"SID-ABI".as_ptr().cast()
}

#[unsafe(no_mangle)]
/// # Safety
/// The caller retains a readable exact handle and four event records.
pub unsafe extern "C" fn r4os_rust_console_events(
    handle: *const abi::ProgramProcessHandle,
    events: *const abi::ConsoleInputEvent,
    count: u32,
) -> i32 {
    assert_eq!(count, 4);
    let handle = unsafe { handle.read() };
    assert_eq!(handle.instance_id, 37);
    assert_eq!(handle.reserved, 0);
    assert_eq!(handle.generation, 0xfedcba9876543210);
    let events = unsafe { core::slice::from_raw_parts(events, count as usize) };
    for (event, (kind, value)) in
        events
            .iter()
            .zip([(1, 0x20ac), (2, 0x80), (3, 0x81), (1, 0x1f600)])
    {
        assert_eq!(
            (event.version, event.kind, event.value, event.flags),
            (1, kind, value, 0)
        );
    }
    3
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo<'_>) -> ! {
    // A rejected test contract traps immediately, including on a host caller.
    unsafe { core::arch::asm!("ud2", options(noreturn, nostack)) }
}

unsafe extern "C" fn write(data: *const u8, len: u32) -> i32 {
    assert_eq!(len, 9);
    assert!(!data.is_null());
    // SAFETY: the fixture supplies the live nine-byte source for this call.
    let data = unsafe { core::slice::from_raw_parts(data, len as usize) };
    assert_eq!(data, b"R4OS-Rust");
    -12345
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_write() -> abi::R4SysFns::write {
    write
}

#[unsafe(no_mangle)]
/// # Safety
/// `callback` must accept the live fixture bytes for the duration of the call.
pub unsafe extern "C" fn r4os_rust_call_write(callback: abi::R4SysFns::write) -> i32 {
    // SAFETY: bytes are immutable static storage; callback was supplied by the fixture.
    unsafe { callback(b"R4OS-Rust".as_ptr(), 9) }
}

unsafe extern "C" fn service_call(
    id: u32,
    opcode: u16,
    request: *const u8,
    request_len: u32,
    header: *mut abi::ServiceMessageHeader,
    reply: *mut u8,
    capacity: u32,
    deadline: u64,
) -> i32 {
    assert_eq!(id, 0xfedc_ba98);
    assert_eq!(opcode, 0xabc7);
    assert_eq!(request_len, 9);
    assert_eq!(capacity, 3);
    assert_eq!(deadline, 0xfedc_ba98_7654_3210);
    // SAFETY: each pointer refers to the exact caller-owned fixture allocation.
    unsafe {
        assert_eq!(write(request, request_len), -12345);
        (*header).op = opcode;
        (*header).request_id = id;
        (*header).status = -32767;
        (*header).payload_len = 3;
        core::ptr::copy_nonoverlapping(b"ACK".as_ptr(), reply, 3);
    }
    -32767
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_service_call() -> abi::R4SysFns::service_call {
    service_call
}

#[unsafe(no_mangle)]
/// # Safety
/// The fixture keeps `request` and `ticket` alive and exclusively owns the output.
pub unsafe extern "C" fn r4os_rust_driver_work(
    request: *const abi::DriverWorkRequest,
    ticket: *mut u32,
) -> i32 {
    // SAFETY: caller supplies an initialized canonical request, including its callback.
    let request = unsafe { &*request };
    assert_eq!(request.version, abi::driver_work_request_version);
    assert_eq!(
        request.size as usize,
        core::mem::size_of::<abi::DriverWorkRequest>()
    );
    assert_eq!(request.serial_key, 0x8123_4567_89ab_cdef);
    assert_eq!(request.deadline_tick, 0xfedc_ba98_7654_3210);
    assert_eq!(request.budget_ticks, 4);
    // SAFETY: callback and context belong to the live request; output is caller-owned.
    unsafe {
        *ticket = 0xfedc_ba98;
        (request.handler)(request.context)
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// A supplied callback must accept the live context for this synchronous call.
pub unsafe extern "C" fn r4os_rust_optional_callback(
    callback: Option<abi::DriverWorkHandler>,
    context: usize,
) -> i32 {
    match callback {
        None => abi::err_no_fn,
        // SAFETY: the test supplies a C callback accepting this fixture context.
        Some(callback) => unsafe { callback(context) },
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// Both descriptors and the source data must remain live for this synchronous call.
pub unsafe extern "C" fn r4os_rust_protocol_buffer(
    source: *const abi::ProtocolBuffer,
    output: *mut abi::ProtocolBuffer,
) -> i32 {
    // SAFETY: caller owns two separate canonical descriptors; no data is dereferenced.
    unsafe {
        assert_eq!((*source).len, 9);
        assert_eq!((*source).capacity, 16);
        assert_eq!((*source).flags, 0x8000_0001);
        *output = *source;
    }
    17
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_enum(value: abi::DriverType) -> abi::DriverType {
    assert_eq!(value, abi::DriverType::net);
    abi::DriverType::display
}

#[unsafe(no_mangle)]
/// # Safety
/// `output` must refer to a writable, aligned canonical message header.
pub unsafe extern "C" fn r4os_rust_default_header(output: *mut abi::ServiceMessageHeader) {
    // SAFETY: caller exclusively owns the output fixture.
    unsafe { output.write(abi::ServiceMessageHeader::default()) };
}

// Only ABI transport peers: no CPU/register operation or hardware counter.
unsafe extern "C" fn pmu_measure(
    cpu: u32,
    epoch: u64,
    event: u32,
    iterations: u32,
    work: *const abi::PmuWorkFn,
    context: u64,
    output: *mut abi::CpuPmuResult,
) -> i32 {
    assert_eq!(cpu, 0xfedc_ba98);
    assert_eq!(epoch, 0xfedc_ba98_7654_3210);
    assert_eq!(event, abi::cpu_pmu_event_branch_misses);
    assert_eq!(iterations, abi::cpu_pmu_max_iterations);
    if work.is_null() || !work.is_aligned() || output.is_null() || !output.is_aligned() {
        return abi::cpu_capabilities_error_invalid;
    }
    // SAFETY: the fixture retains the borrowed function slot and exclusive
    // output. Check zero bits before materializing a nonnull Rust function.
    let result = unsafe {
        if work.cast::<u64>().read() == 0
            || (*output).version != 1
            || (*output).size < core::mem::size_of::<abi::CpuPmuResult>() as u32
        {
            return abi::cpu_capabilities_error_invalid;
        }
        work.read()(context, iterations)
    };
    // SAFETY: only the fixed256-byte result is copied; caller tail remains.
    unsafe {
        output.write(abi::CpuPmuResult {
            cpu_index: cpu,
            epoch,
            generation: 0x8123_4567_89ab_cdef,
            event_id: event,
            iterations,
            callback_result: result,
            status: abi::cpu_pmu_status_callback_aborted,
            // No physical data is invented by an ABI-only fixture.
            flags: abi::cpu_pmu_result_flag_callback_started
                | abi::cpu_pmu_result_flag_callback_returned,
            ..Default::default()
        });
    }
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_pmu_measure() -> abi::R4DevFns::cpu_pmu_measure {
    pmu_measure
}

// Pure ABI peers only: no optional ISA, clock or physical CPU observation.
unsafe extern "C" fn acceleration_info(output: *mut abi::CpuAccelerationInfo) -> i32 {
    if output.is_null() || !output.is_aligned() {
        return abi::cpu_capabilities_error_invalid;
    }
    unsafe {
        if (*output).version != 1 || (*output).size < 128 {
            return abi::cpu_capabilities_error_invalid;
        }
        output.write(abi::CpuAccelerationInfo {
            cpu_index: 0xfedc_ba98,
            epoch: 0xfedc_ba98_7654_3210,
            capture_sequence: 0x8123_4567_89ab_cdef,
            flags: abi::cpu_accel_info_flag_virtual,
            hardware_mask: 63,
            common_hardware_mask: 31,
            xcr0: 7,
            ..Default::default()
        });
    }
    0
}
unsafe extern "C" fn acceleration_work(
    kind: u32,
    iterations: u32,
    slot: *const abi::CpuPureWorkFn,
    context: u64,
    output: *mut abi::CpuAccelerationWork,
) -> i32 {
    assert_eq!(kind, abi::cpu_accel_work_kind_sha256);
    assert_eq!(iterations, 64);
    if slot.is_null() || !slot.is_aligned() || output.is_null() || !output.is_aligned() {
        return abi::cpu_capabilities_error_invalid;
    }
    let result = unsafe {
        if slot.cast::<u64>().read() == 0 || (*output).version != 1 || (*output).size < 128 {
            return abi::cpu_capabilities_error_invalid;
        }
        slot.read()(context, iterations)
    };
    unsafe {
        output.write(abi::CpuAccelerationWork {
            cpu_index: 0xfedc_ba98,
            epoch: 0xfedc_ba98_7654_3210,
            work_kind: kind,
            iterations,
            callback_result: result,
            status: abi::cpu_accel_work_status_callback_aborted,
            flags: abi::cpu_accel_work_flag_callback_started
                | abi::cpu_accel_work_flag_callback_returned,
            ..Default::default()
        });
    }
    0
}
#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_acceleration_info() -> abi::R4DevFns::cpu_acceleration_info {
    acceleration_info
}
#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_acceleration_work() -> abi::R4DevFns::cpu_acceleration_work {
    acceleration_work
}

// ABI transport peers only, not an actual random source or device receipt.
unsafe extern "C" fn entropy_source_info(output: *mut abi::EntropySourceInfo) -> i32 {
    if output.is_null() || !output.is_aligned() {
        return abi::entropy_error_invalid;
    }
    unsafe {
        if (*output).version != 1 || (*output).size < 128 {
            return abi::entropy_error_invalid;
        }
        output.write(abi::EntropySourceInfo {
            state: abi::entropy_state_retained,
            flags: abi::entropy_source_flag_device | abi::entropy_source_flag_virtual,
            generation: 0x8123_4567_89ab_cdef,
            owner_epoch: 0xfedc_ba98_7654_3210,
            owner: 0xfedc_ba98,
            vendor_id: 0x1af4,
            device_id: 0x1044,
            last_result: -30021,
            ..Default::default()
        });
    }
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_entropy_info() -> abi::R4SysFns::entropy_source_info {
    entropy_source_info
}

#[unsafe(no_mangle)]
/// # Safety
/// Fixture supplies resident canonical descriptor, seventeen writable bytes
/// and an exclusive initialized versioned receipt for this synchronous call.
pub unsafe extern "C" fn r4os_rust_entropy_callback(
    backend: *const abi::EntropyBackend,
    data: *mut u8,
    bytes: u32,
    output: *mut abi::EntropyDeviceReceipt,
) -> i32 {
    if backend.is_null()
        || !backend.is_aligned()
        || data.is_null()
        || output.is_null()
        || !output.is_aligned()
    {
        return abi::entropy_error_invalid;
    }
    let descriptor = unsafe { backend.read() };
    if descriptor.version != 1 || descriptor.size < 64 || descriptor.read == 0 || bytes != 17 {
        return abi::entropy_error_invalid;
    }
    if unsafe { (*output).version != 1 || (*output).size < 128 } {
        return abi::entropy_error_invalid;
    }
    // The canonical descriptor transports pointer bits, like existing R4D
    // backend tables. Validate nonzero before materializing the typed value.
    let callback: abi::EntropyReadFn = unsafe { core::mem::transmute(descriptor.read) };
    unsafe { callback(descriptor.context, data, bytes, output) }
}
