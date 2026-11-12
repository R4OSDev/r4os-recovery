use r4os_sdk::{
    abi, audio_write::Writer, pcm_source::Pacer, platform2::Context, resources::Timeout,
    time::checked::ClockSample,
};
unsafe extern "C" {
    fn sdk_audio25_tables(sys: *mut abi::generation2::R4XStartR4Sys2, mode: u32);
    fn sdk_audio25_calls() -> u32;
    fn sdk_audio25_c_case() -> i32;
}
#[test]
fn actual_audio_writer_c_rust_total_budget_prefix_poll_uncertain() {
    assert_eq!(unsafe { sdk_audio25_c_case() }, 0);
    // The ordinary App2/Platform/Stream route enters the same Zig writer.
    {
        use r4os_sdk::{
            app2::{App, ImportSpec, StartupInfo},
            platform::{PlatformStorage, WriteKind},
        };
        let mut sys = abi::generation2::R4XStartR4Sys2::default();
        unsafe { sdk_audio25_tables(&mut sys, 0) };
        let import = abi::R4XStartImport {
            group_id: 1,
            min_version: 2,
            resolved_version: 2,
            flags: abi::r4xstart_import_flag_group_interface,
            module_name: c"R4SYS".as_ptr() as u64,
            symbol_name: c"Query2".as_ptr() as u64,
            table: &sys as *const _ as u64,
            ..Default::default()
        };
        let raw = abi::generation2::R4XStartContext2 {
            instance_id: 43,
            app_class: abi::R4XStartAppClass::console.0,
            flags: abi::r4xstart_flag_imports_valid,
            import_count: 1,
            imports: &import as *const _ as u64,
            ..Default::default()
        };
        let imports = [ImportSpec {
            module_name: c"R4SYS".as_ptr().cast(),
            symbol_name: c"Query2".as_ptr().cast(),
            minimum: 2,
            optional: 0,
            group_id: 1,
            reserved: 0,
        }];
        let facts = StartupInfo {
            profile: abi::R4AppProfile::console.0 as u32,
            app_class: abi::R4XStartAppClass::console.0,
            required_groups: 2,
            imports: &imports,
        };
        let app = unsafe { App::from_raw(&raw, &facts, c"AUDIO43") }.unwrap();
        let mut storage = core::pin::pin!(PlatformStorage::default());
        let platform = app.platform(storage.as_mut()).unwrap();
        let audio = platform.audio().unwrap();
        let mut stream = audio
            .open_stream(48000, 2, 65536, Timeout::Forever)
            .unwrap();
        let progress = stream
            .write(&[0; 64], Timeout::AfterNanos(10_000_000), false)
            .unwrap();
        assert_eq!(progress.kind, WriteKind::TimedOut);
        assert_eq!(progress.accepted, 16);
        assert_eq!(unsafe { sdk_audio25_calls() }, 4);
        stream.close(Timeout::Forever).unwrap();
    }
    for mode in 0..4 {
        let mut sys = abi::generation2::R4XStartR4Sys2::default();
        unsafe { sdk_audio25_tables(&mut sys, mode) };
        let import = abi::R4XStartImport {
            group_id: 1,
            resolved_version: 2,
            table: &sys as *const _ as u64,
            ..Default::default()
        };
        let raw = abi::generation2::R4XStartContext2 {
            import_count: 1,
            imports: &import as *const _ as u64,
            ..Default::default()
        };
        let context = unsafe { Context::new(&raw) }.unwrap();
        let data = [0u8; 64];
        let mut w = unsafe {
            Writer::from_native_handles(&context, 7, 42, 4, &data, Timeout::AfterNanos(10_000_000))
        }
        .unwrap();
        let p = w.write_bounded(64, false).unwrap();
        assert_eq!(
            unsafe { sdk_audio25_calls() },
            if mode == 0 { 4 } else { 1 }
        );
        assert_eq!(p.io.bytes, if mode == 0 { 16 } else { 0 });
        assert_eq!(
            p.io.outcome,
            if mode == 0 {
                4
            } else if mode == 1 {
                2
            } else {
                7
            }
        );
        assert_eq!(p.service_flags_valid, if mode <= 1 { 1 } else { 0 });
        if mode != 1 {
            let _ = w.write_once(false).unwrap();
            assert_eq!(
                unsafe { sdk_audio25_calls() },
                if mode == 0 { 4 } else { 1 }
            );
        }
    }
}
#[test]
fn actual_pcm_source_c_rust_rational_clock_pause_reset() {
    let mut info = abi::MonotonicClockInfo {
        flags: 1,
        source: 1,
        generation: 41,
        resolution_ns: 1,
        event_requested_hz: 1000,
        ..Default::default()
    };
    let initial = ClockSample::from_info(&info).unwrap();
    let mut p = Pacer::new(44100, 4, 0, initial).unwrap();
    let d = p.accepted(4, initial).unwrap();
    assert_eq!(
        (d.accepted_frames, d.source_end_ns, d.wait_ns),
        (1, 22676, 22676)
    );
    assert_eq!(
        p.accepted(3, initial).err(),
        Some(r4os_sdk::pcm_source::Error(-303))
    );
    info.generation += 1;
    assert_eq!(
        p.deadline(ClockSample::from_info(&info).unwrap(), true)
            .err(),
        Some(r4os_sdk::pcm_source::Error(-102))
    );
    p.pause(initial).unwrap();
    assert_eq!(p.deadline(initial, true).unwrap().wait_ns, 0);
    assert_eq!(
        p.accepted(4, initial).err(),
        Some(r4os_sdk::pcm_source::Error(-306))
    );
    p.resume_source(initial).unwrap();
    p.reset(48000, 4, 7680, initial).unwrap();
    assert_eq!(p.accepted(3840, initial).unwrap().accepted_frames, 960);
}
