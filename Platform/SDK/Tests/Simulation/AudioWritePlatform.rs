use super::*;
static mut ORIGINAL_CALL: Option<abi::R4SysFns::service_call> = None;
// The unchanged original oracle leaves header.payload_len=0 even for a
// 120-byte result. This serialized fixture supplies only that omitted
// transport-envelope field; body/stream/open/write/close stay original.
unsafe extern "C" fn complete_envelope(
    channel: u32,
    op: u16,
    request: *const u8,
    length: u32,
    header: *mut abi::ServiceMessageHeader,
    response: *mut u8,
    capacity: u32,
    ticks: u64,
) -> i32 {
    let call = unsafe { ORIGINAL_CALL }.unwrap();
    let result = unsafe {
        call(
            channel, op, request, length, header, response, capacity, ticks,
        )
    };
    if result >= 0 {
        unsafe { (*header).payload_len = u16::try_from(result).unwrap_or(0) };
    }
    result
}
unsafe extern "C" fn fixed_clock(out: *mut abi::MonotonicClockInfo) -> i32 {
    unsafe {
        *out = abi::MonotonicClockInfo {
            flags: 1,
            source: 1,
            generation: 41,
            resolution_ns: 1,
            event_requested_hz: 1000,
            ..Default::default()
        }
    };
    1
}
#[test]
fn total_writer_borrows_the_actual_original_platform_stream() {
    let (mut sys, mut audio, mut dev) = (
        abi::R4XStartR4Sys::default(),
        abi::R4XStartR4Audio::default(),
        abi::R4XStartR4Dev::default(),
    );
    unsafe { sdk_platform_oracle_tables(&mut sys, &mut audio, &mut dev) };
    unsafe {
        ORIGINAL_CALL = Some(core::mem::transmute::<usize, abi::R4SysFns::service_call>(
            sys.service_call,
        ))
    };
    sys.service_call = complete_envelope as *const () as usize;
    sys.monotonic_clock = fixed_clock as *const () as usize;
    let import = abi::R4XStartImport {
        group_id: 1,
        module_name: c"R4SYS".as_ptr() as u64,
        symbol_name: c"Query".as_ptr() as u64,
        flags: abi::r4xstart_import_flag_group_interface,
        min_version: 1,
        resolved_version: 1,
        table: &sys as *const _ as u64,
    };
    let spec = ImportSpec {
        module_name: b"R4SYS",
        symbol_name: b"Query",
        group_id: abi::R4LGroup::r4sys.0,
        minimum: 1,
        optional: false,
        magic: sys.magic,
        version: sys.abi_version,
        size: sys.size,
    };
    let context = abi::R4XStartContext {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: &import as *const _ as u64,
        import_count: 1,
        ..Default::default()
    };
    let expected = StartupInfo {
        app_class: abi::R4XStartAppClass::console,
        required_groups: 2,
        imports: core::slice::from_ref(&spec),
    };
    let app = unsafe { App::from_raw(&context, &expected, c"AudioWriter") }.unwrap();
    let mut storage = pin!(PlatformStorage::new());
    let platform = Platform::open(storage.as_mut(), &app).unwrap();
    let audio = platform.audio().unwrap();
    let mut stream = audio.open_stream(48000, 2, 0, Timeout::Forever).unwrap();
    let data = [0u8; 12];
    unsafe { sdk_platform_oracle_mode(0) };
    {
        let mut w =
            r4os_sdk::audio_write::Writer::new(&mut stream, &data, Timeout::Forever).unwrap();
        let p = w.write_bounded(64, false).unwrap();
        assert_eq!((p.io.bytes, p.accepted_frames, p.io.outcome), (12, 3, 1));
    }
    assert!(stream.valid().unwrap());
    stream.close(Timeout::Forever).unwrap();
    assert!(!stream.valid().unwrap());
    assert_eq!(unsafe { sdk_platform_oracle_connections() }, 0);
}
