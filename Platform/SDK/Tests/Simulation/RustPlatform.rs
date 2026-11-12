#![cfg(test)]
#[path = "PreciseClock.rs"]
mod precise_clock;
#[path = "AudioWritePlatform.rs"]
mod audio_write25;
#[path = "RustGraphics.rs"]
mod visual_regression;
use core::{mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    App, ImportSpec, StartupInfo, abi,
    platform::{
        Platform, PlatformStorage, Resampler, WriteCursor, WriteKind, WriteProgress, raw as c,
    },
    resources::Timeout,
};
unsafe extern "C" {
    fn sdk_budget_c_case() -> i32;
    fn sdk_audio_c_case() -> i32;
    fn sdk_platform_oracle_tables(
        sys: *mut abi::R4XStartR4Sys,
        audio: *mut abi::R4XStartR4Audio,
        dev: *mut abi::R4XStartR4Dev,
    );
    fn sdk_platform_oracle_mode(mode: u32);
    fn sdk_platform_oracle_connections() -> u32;
    fn sdk_platform_oracle_reply_fault(action: u16, fault: u32, at: u32);
    fn sdk_platform_oracle_last_stream() -> u32;
}
#[test]
fn checked_budget_c_peer_uses_the_same_native_owner() {
    assert_eq!(unsafe { sdk_budget_c_case() }, 0);
}
#[test]
fn original_platform_owners_preserve_frames_progress_and_explicit_close() {
    assert_eq!(unsafe { sdk_audio_c_case() }, 0);
    let (mut sys, mut audio, mut dev) = (
        abi::R4XStartR4Sys::default(),
        abi::R4XStartR4Audio::default(),
        abi::R4XStartR4Dev::default(),
    );
    unsafe { sdk_platform_oracle_tables(&mut sys, &mut audio, &mut dev) };
    let records = [
        (
            abi::R4LGroup::r4sys,
            c"R4SYS",
            &sys as *const _ as u64,
            sys.magic,
            sys.abi_version,
            sys.size,
        ),
        (
            abi::R4LGroup::r4audio,
            c"R4AUDIO",
            &audio as *const _ as u64,
            audio.magic,
            audio.abi_version,
            audio.size,
        ),
        (
            abi::R4LGroup::r4dev,
            c"R4DEV",
            &dev as *const _ as u64,
            dev.magic,
            dev.abi_version,
            dev.size,
        ),
    ];
    let imports = records.map(|(group, name, table, _, _, _)| abi::R4XStartImport {
        group_id: group.0,
        module_name: name.as_ptr() as u64,
        symbol_name: c"Query".as_ptr() as u64,
        flags: abi::r4xstart_import_flag_group_interface,
        min_version: 1,
        resolved_version: 1,
        table,
    });
    let specs = records.map(|(group, name, _, magic, version, size)| ImportSpec {
        module_name: name.to_bytes(),
        symbol_name: b"Query",
        group_id: group.0,
        minimum: 1,
        optional: false,
        magic,
        version,
        size,
    });
    let context = abi::R4XStartContext {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: imports.as_ptr() as u64,
        import_count: 3,
        ..Default::default()
    };
    let expected = StartupInfo {
        app_class: abi::R4XStartAppClass::console,
        required_groups: records.iter().fold(0, |m, r| m | (1 << r.0.0)),
        imports: &specs,
    };
    let app = unsafe { App::from_raw(&context, &expected, c"PlatformParity") }.unwrap();
    let mut storage = pin!(PlatformStorage::new());
    let platform = Platform::open(storage.as_mut(), &app).unwrap();
    let audio = platform.audio().unwrap();
    let mut invalid_format = MaybeUninit::uninit();
    let raw = unsafe {
        c::R4SdkAudioAudio_openStream(
            0,
            audio.native(),
            48000,
            2,
            2,
            0x10000,
            &abi::R4Timeout {
                kind: abi::timeout_kind_forever,
                ..Default::default()
            },
            invalid_format.as_mut_ptr(),
        )
    };
    assert_eq!(raw.status, 0);
    assert_eq!(
        unsafe { c::R4SdkAudioOpenResult_get_failure(invalid_format.as_ptr()) }.bits as i32,
        abi::service_api_result_invalid
    );
    assert!(
        audio
            .open_stream(192001, 2, 0x10000, Timeout::Forever)
            .is_err()
    );
    assert!(
        audio
            .open_stream(48000, 3, 0x10000, Timeout::Forever)
            .is_err()
    );
    let mut stream = audio
        .open_stream(48000, 2, 0x10000, Timeout::Forever)
        .unwrap();
    assert!(stream.valid().unwrap());
    let input = [0u8; 16];
    unsafe { sdk_platform_oracle_mode(1) };
    let p = stream.write(&input, Timeout::Forever, true).unwrap();
    assert_eq!(p.accepted, 4);
    assert_eq!(p.kind, WriteKind::Retry);
    let mut cursor = WriteCursor::new(16, 4).unwrap().unwrap();
    assert!(WriteCursor::new(15, 4).unwrap().is_none());
    cursor.apply(p).unwrap();
    assert_eq!(cursor.remaining().unwrap(), 12);
    assert_eq!(
        cursor
            .apply(WriteProgress {
                accepted: 3,
                kind: WriteKind::Retry,
                raw: 0
            })
            .unwrap()
            .kind,
        WriteKind::Invalid
    );
    assert_eq!(cursor.remaining().unwrap(), 12);
    for (mode, kind) in [
        (2, WriteKind::Retry),
        (3, WriteKind::TimedOut),
        (4, WriteKind::Failure),
    ] {
        unsafe { sdk_platform_oracle_mode(mode) };
        let p = stream.write(&input, Timeout::Forever, false).unwrap();
        assert_eq!(p.kind, kind);
        assert_eq!(p.accepted, if mode == 4 { 0 } else { 4 });
    }
    unsafe { sdk_platform_oracle_mode(0) };
    let p = stream.write(&input[..12], Timeout::Forever, false).unwrap();
    assert_eq!(p.kind, WriteKind::Complete);
    cursor.apply(p).unwrap();
    assert_eq!(cursor.remaining().unwrap(), 0);
    assert_eq!(
        stream
            .write(&input[..3], Timeout::Forever, false)
            .unwrap()
            .kind,
        WriteKind::Failure
    );
    // The exact accepted prefix survives an unrelated or malformed second
    // reply, at both the four-byte and full service-chunk boundaries.
    for length in [16usize, 8192] {
        let input = [0x42u8; 8192];
        for fault in [1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15, 16] {
            unsafe {
                sdk_platform_oracle_mode(if length == 16 { 1 } else { 0 });
                sdk_platform_oracle_reply_fault(abi::audio_service_op_write_stream, fault, 2);
            }
            let failed = stream
                .write(&input[..length], Timeout::Forever, false)
                .unwrap();
            let prefix = if length == 16 { 4 } else { 4076 };
            assert_eq!(failed.kind, WriteKind::Failure);
            assert_eq!(
                failed.raw,
                if fault == 16 {
                    abi::service_api_result_bad_handle
                } else {
                    abi::service_api_result_invalid
                }
            );
            assert_eq!(failed.accepted, prefix);
            let mut cursor = WriteCursor::new(length, 4).unwrap().unwrap();
            cursor.apply(failed).unwrap();
            assert_eq!(cursor.remaining().unwrap(), length - prefix);
            assert!(stream.valid().unwrap());
            assert_eq!(unsafe { sdk_platform_oracle_last_stream() }, 91);
            assert_eq!(unsafe { sdk_platform_oracle_connections() }, 1);
        }
    }
    for operation in [
        abi::audio_service_op_set_stream_volume,
        abi::audio_service_op_close_stream,
    ] {
        for fault in [1, 2, 3, 4, 5, 6, 7, 8, 16] {
            unsafe { sdk_platform_oracle_reply_fault(operation, fault, 1) };
            let result = if operation == abi::audio_service_op_close_stream {
                stream.close(Timeout::Forever)
            } else {
                stream.set_volume(0x8000, Timeout::Forever)
            };
            assert!(result.is_err());
            assert!(stream.valid().unwrap());
            assert_eq!(unsafe { sdk_platform_oracle_last_stream() }, 91);
            assert_eq!(unsafe { sdk_platform_oracle_connections() }, 1);
        }
    }
    unsafe {
        sdk_platform_oracle_reply_fault(0, 0, 0);
        sdk_platform_oracle_mode(0);
    }
    stream.set_volume(0x8000, Timeout::Forever).unwrap();
    stream.close(Timeout::Forever).unwrap();
    assert!(!stream.valid().unwrap());
    assert!(stream.close(Timeout::Forever).is_err());
    assert_eq!(unsafe { sdk_platform_oracle_connections() }, 0);
    for fault in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] {
        unsafe { sdk_platform_oracle_reply_fault(abi::audio_service_op_open_stream, fault, 1) };
        assert!(
            audio
                .open_stream(48000, 2, 0x10000, Timeout::Forever)
                .is_err()
        );
        assert_eq!(unsafe { sdk_platform_oracle_connections() }, 0);
    }
    unsafe { sdk_platform_oracle_reply_fault(abi::audio_service_op_open_stream, 16, 1) };
    assert!(
        matches!(audio.open_stream(48000, 2, 0x10000, Timeout::Forever), Err(r4os_sdk::storage::Error::Raw(raw)) if raw == abi::service_api_result_bad_handle)
    );
    assert_eq!(unsafe { sdk_platform_oracle_connections() }, 0);
    unsafe { sdk_platform_oracle_reply_fault(0, 0, 0) };
    let mut regular = audio
        .open_stream(48000, 2, 0x10000, Timeout::Forever)
        .unwrap();
    assert!(regular.valid().unwrap());
    regular.close(Timeout::Forever).unwrap();
    assert!(platform.devices().memory().unwrap().is_some());
    assert!(platform.devices().inventory().is_ok());
    assert!(matches!(
        platform.devices().record(9999),
        Err(r4os_sdk::storage::Error::Unavailable)
    ));
    let mut summary = abi::ProgramInstanceStorageSummary::default();
    let raw_dev = unsafe { platform.devices().native() };
    let current =
        unsafe { c::R4SdkGfxDeviceContext_programInstanceStorageSummary(0, raw_dev, &mut summary) };
    assert_eq!(current.bits as i32, 1);
    assert_eq!(summary.version, 2);
    dev.program_instance_storage_summary_v2 = 0;
    assert_eq!(dev.program_instance_storage_summary_v2, 0);
    summary.version = 777;
    let unavailable =
        unsafe { c::R4SdkGfxDeviceContext_programInstanceStorageSummary(0, raw_dev, &mut summary) };
    assert_eq!(unavailable.bits as i32, abi::err_no_fn);
    assert_eq!(summary.version, 777);
    let mut perf = MaybeUninit::uninit();
    let owner = unsafe { c::R4SdkPlatformDevices(platform.native()) };
    assert_eq!(
        unsafe { c::R4SdkDevicesDevices_performance(0, owner, perf.as_mut_ptr()) }.status,
        0
    );
    assert_eq!(
        unsafe {
            c::R4SdkDevicesPerformanceView_programInstanceStorage(0, perf.as_ptr(), &mut summary)
        }
        .flags
            & 1,
        0
    );
    let mut resampler = Resampler::new().unwrap();
    resampler.begin(48000, 2, 1).unwrap();
    let direct = resampler
        .take_direct(&input, 48000, 2, 1, 12)
        .unwrap()
        .unwrap();
    assert_eq!(direct, &input[..12]);
    assert_eq!(direct.as_ptr(), input.as_ptr());
    let mut out = [0u8; 64];
    resampler.begin(48000, 1, 2).unwrap();
    let count = resampler
        .convert(&[0, 128, 255], 48000, 1, 2, &mut out)
        .unwrap();
    let tail = resampler.finish(&mut out[count..]).unwrap();
    assert_eq!(count + tail, 12);
    assert_eq!(&out[..4], &[0, 128, 0, 128]);
    assert_eq!(resampler.pending_tail_bytes().unwrap(), 0);
    let mut native = MaybeUninit::uninit();
    assert_eq!(
        unsafe {
            c::R4SdkPlatformOpenNative(
                c::R4SdkGui_ABI_FINGERPRINT ^ 1,
                native.as_mut_ptr(),
                &context,
            )
        },
        abi::io_error_invalid
    );
    let no_audio_imports = [imports[0], imports[2]];
    let no_audio_specs = [specs[0], specs[2]];
    let no_audio_context = abi::R4XStartContext {
        imports: no_audio_imports.as_ptr() as u64,
        import_count: 2,
        ..context
    };
    let no_audio_expected = StartupInfo {
        app_class: abi::R4XStartAppClass::console,
        required_groups: (1 << abi::R4LGroup::r4sys.0) | (1 << abi::R4LGroup::r4dev.0),
        imports: &no_audio_specs,
    };
    let app_without_audio =
        unsafe { App::from_raw(&no_audio_context, &no_audio_expected, c"NoAudio") }.unwrap();
    let mut no_audio_storage = pin!(PlatformStorage::new());
    let no_audio_platform = Platform::open(no_audio_storage.as_mut(), &app_without_audio).unwrap();
    let service_only_audio = no_audio_platform.audio().unwrap();
    let mut service_only_stream = service_only_audio
        .open_stream(48000, 2, 0x10000, Timeout::Forever)
        .unwrap();
    service_only_stream.close(Timeout::Forever).unwrap();
    assert_eq!(unsafe { sdk_platform_oracle_connections() }, 0);
    // Direct raw synthesizer operations still have no R4AUDIO provider.
    let raw_audio = unsafe { c::R4SdkPlatformAudioRaw(no_audio_platform.native()) };
    assert_eq!(
        unsafe { c::R4SdkAudioContext_audioOpenStream(0, raw_audio, 48000, 2, 1) }.bits as i32,
        abi::err_no_group
    );
    assert!(no_audio_platform.devices().memory().unwrap().is_some());
}

#[test]
fn generation2_c_and_rust_admit_identical_prefixes_and_reject_mixed_records() {
    use r4os_sdk::platform2::{Context, Error, abi as a};
    unsafe extern "C" {
        fn sdk_platform2_admission(raw: *const a::R4XStartContext2, called: *mut i32) -> i32;
    }
    extern "C" fn write(data: *const u8, length: u32) -> i32 {
        if length == 4 && unsafe { core::slice::from_raw_parts(data, 4) } == b"API2" {
            -20002
        } else {
            -1
        }
    }
    fn check(
        raw: &a::R4XStartContext2,
        table: &a::R4XStartR4Sys2,
        imports: &[r4os_sdk::abi::R4XStartImport],
        expected: Option<Error>,
        called: i32,
    ) {
        // The ABI transports integer addresses. Keep each mutated backing
        // explicitly observed before the real foreign/unsafe reads.
        let _ = core::hint::black_box((table, imports));
        let value = unsafe { Context::new(raw) };
        if let Some(error) = expected {
            assert_eq!(value.err(), Some(error));
        } else {
            let value = value.unwrap();
            assert!(core::ptr::eq(value.raw(), raw));
            assert!(value.group(1).is_some());
            assert!(value.group(0).is_none() && value.group(7).is_none());
            assert_eq!(value.lookup(7, 16), Err(r4os_sdk::abi::err_no_group));
            assert_eq!(value.lookup(1, 0), Err(r4os_sdk::abi::err_no_fn));
            assert_eq!(value.lookup(1, 0xfffffff8), Err(r4os_sdk::abi::err_no_fn));
            let function = value.lookup(1, core::mem::offset_of!(a::R4XStartR4Sys2, write) as u32);
            if called == -20002 {
                let write: a::R4SysFns2::write = unsafe { core::mem::transmute(function.unwrap()) };
                assert_eq!(unsafe { write(b"API2".as_ptr(), 4) }, -20002);
            } else {
                assert_eq!(function, Err(r4os_sdk::abi::err_no_fn));
            }
        }
        let mut result = 12345;
        assert_eq!(
            unsafe { sdk_platform2_admission(raw, &mut result) },
            expected.map_or(0, |error| error as i32)
        );
        assert_eq!(result, if expected.is_none() { called } else { 12345 });
    }
    let mut sys = a::R4XStartR4Sys2 {
        write: write as *const () as u64,
        ..Default::default()
    };
    let import = r4os_sdk::abi::R4XStartImport {
        group_id: 1,
        resolved_version: 2,
        table: core::ptr::addr_of_mut!(sys) as u64,
        ..Default::default()
    };
    let mut rows = [import, import];
    let mut raw = a::R4XStartContext2 {
        imports: rows.as_mut_ptr() as u64,
        import_count: 1,
        ..Default::default()
    };
    check(&raw, &sys, &rows, None, -20002);
    raw.abi_major = 1;
    check(&raw, &sys, &rows, Some(Error::InvalidContext), 0);
    raw.abi_major = 2;
    raw.size = 119;
    check(&raw, &sys, &rows, Some(Error::InvalidContext), 0);
    raw.size = 120;
    raw.import_count = 33;
    check(&raw, &sys, &rows, Some(Error::InvalidImports), 0);
    raw.import_count = 1;
    raw.imports += 1;
    check(&raw, &sys, &rows, Some(Error::InvalidImports), 0);
    raw.imports -= 1;
    rows[0].resolved_version = 1;
    check(&raw, &sys, &rows, Some(Error::MixedGeneration), 0);
    rows[0] = import;
    rows[0].group_id = 7;
    check(&raw, &sys, &rows, Some(Error::InvalidImports), 0);
    rows[0] = import;
    rows[0].group_id = 2;
    check(&raw, &sys, &rows, Some(Error::MissingSystem), 0);
    rows[0] = import;
    rows[0].table = 0;
    check(&raw, &sys, &rows, Some(Error::MissingSystem), 0);
    raw.import_count = 2;
    check(&raw, &sys, &rows, Some(Error::DuplicateGroup), 0);
    raw.import_count = 1;
    rows[0] = import;
    sys.magic = (r4os_sdk::abi::R4XStartR4Sys::default()).magic;
    check(&raw, &sys, &rows, Some(Error::InvalidTable), 0);
    sys.magic = a::R4SYS_MAGIC;
    sys.size = 15;
    check(&raw, &sys, &rows, Some(Error::InvalidTable), 0);
    sys.size = 16;
    check(&raw, &sys, &rows, None, -20001);
    sys.size = core::mem::size_of_val(&sys) as u32;
    sys.abi_version = 0;
    check(&raw, &sys, &rows, Some(Error::InvalidTable), 0);
    sys.abi_version = 1;
    rows[0].group_id = 0;
    rows[0].resolved_version = 1;
    raw.import_count = 2;
    check(&raw, &sys, &rows, None, -20002);
}

#[test]
fn generation2_real_start_adapters_match_c_and_reject_wrong_admission() {
    use r4os_sdk::platform2::{self, Context, StartupInfo, abi as a};
    unsafe extern "C" {
        fn sdk_platform2_start_case(
            raw: *const a::R4XStartContext2,
            class: u32,
            mask: u32,
            count: u32,
        ) -> i32;
    }
    unsafe extern "C" fn write(data: *const u8, len: u32) -> i32 {
        if unsafe { core::slice::from_raw_parts(data, len as usize) } == b"API2" {
            -20002
        } else {
            -2
        }
    }
    fn main(context: &Context<'_>) -> i32 {
        let raw = context
            .lookup(1, core::mem::offset_of!(a::R4XStartR4Sys2, write) as u32)
            .unwrap();
        let callback: a::R4SysFns2::write = unsafe { core::mem::transmute(raw) };
        unsafe { callback(b"API2".as_ptr(), 4) }
    }
    let sys = a::R4XStartR4Sys2 {
        write: write as *const () as u64,
        ..Default::default()
    };
    let imports = [abi::R4XStartImport {
        group_id: 1,
        min_version: 2,
        resolved_version: 2,
        flags: abi::r4xstart_import_flag_group_interface,
        table: (&sys as *const _) as u64,
        ..Default::default()
    }];
    let mut raw = a::R4XStartContext2 {
        app_class: 1,
        imports: imports.as_ptr() as u64,
        import_count: 1,
        ..Default::default()
    };
    for (class, mask, count, result) in [
        (1, 2, 1, -20002),
        (3, 2, 1, -1),
        (1, 10, 1, -1),
        (1, 2, 2, -1),
    ] {
        let info = StartupInfo {
            app_class: class,
            required_groups: mask,
            import_count: count,
        };
        assert_eq!(unsafe { platform2::start(&raw, info, main) }, result);
        assert_eq!(
            unsafe { sdk_platform2_start_case(&raw, class, mask, count) },
            result
        );
    }
    raw.size = 119;
    assert_eq!(
        unsafe {
            platform2::start(
                &raw,
                StartupInfo {
                    app_class: 1,
                    required_groups: 2,
                    import_count: 1,
                },
                main,
            )
        },
        -1
    );
    assert_eq!(unsafe { sdk_platform2_start_case(&raw, 1, 2, 1) }, -1);
}
