//! Fractional-tick work budgets require the admitted precise platform source.
use r4os_sdk::{App, ImportSpec, StartupInfo, abi as a, storage::Error, time::Clock};
use std::sync::atomic::{AtomicI32, Ordering};
static MODE: AtomicI32 = AtomicI32::new(0);
static CALENDAR_CALLS: AtomicI32 = AtomicI32::new(0);
#[test]
fn checked_budgets_keep_clock_and_retry_limits_through_native_owner() {
    use r4os_sdk::{resources::Timeout, time::checked::*};
    for hz in [100, 128, 333, 1000] {
        assert_eq!(milliseconds_to_ticks(0, hz), Ok(0));
        assert_eq!(milliseconds_to_ticks(1, hz), Ok(1));
        assert_eq!(milliseconds_to_ticks(1000, hz), Ok(hz.into()));
    }
    assert_eq!(milliseconds_to_ticks(u64::MAX, 1000), Ok(u64::MAX));
    assert_eq!(milliseconds_to_ticks(u64::MAX, 1001), Err(Error::Overflow));
    assert_eq!(milliseconds_to_ticks(0, 0), Err(Error::UnknownFrequency));
    assert_eq!(timeout_ticks(Timeout::Poll, 0), Ok(BudgetValue::Poll));
    assert_eq!(timeout_ticks(Timeout::Forever, 0), Ok(BudgetValue::Forever));
    assert_eq!(
        timeout_ticks(Timeout::AfterNanos(u64::MAX), 1_000_000_000),
        Ok(BudgetValue::Finite(u64::MAX))
    );
    let mut info = a::MonotonicClockInfo {
        flags: a::monotonic_clock_flag_valid,
        source: 1,
        generation: 9,
        resolution_ns: 1,
        instant_ns: 100,
        event_requested_hz: 333,
        event_effective_hz: 334,
        ..Default::default()
    };
    let sample = ClockSample::from_info(&info).unwrap();
    assert_eq!(sample.tick_hz(), 333);
    let mut deadline = DeadlineBudget::new(sample, Timeout::AfterNanos(10)).unwrap();
    info.generation = 10;
    assert_eq!(
        deadline.remaining(ClockSample::from_info(&info).unwrap()),
        Err(Error::ClockChanged)
    );
    info.generation = 9;
    info.instant_ns = 109;
    assert_eq!(
        deadline.remaining(ClockSample::from_info(&info).unwrap()),
        Ok(BudgetValue::Finite(1))
    );
    assert_eq!(deadline.remaining(sample), Err(Error::ClockRegressed));
    info.instant_ns = u64::MAX;
    assert!(matches!(
        DeadlineBudget::new(
            ClockSample::from_info(&info).unwrap(),
            Timeout::AfterNanos(1)
        ),
        Err(Error::Overflow)
    ));
    let mut spin =
        DriverPollBudget::timed(sample, Timeout::AfterNanos(20), 8, PollContext::Irq).unwrap();
    for _ in 0..8 {
        assert_eq!(spin.step(Some(sample), false), PollOutcome::Proceed);
    }
    assert_eq!(spin.remaining(Some(sample)).unwrap().iterations, 0);
    assert_eq!(spin.step(Some(sample), false), PollOutcome::Expired);
    assert!(matches!(
        DriverPollBudget::timed(sample, Timeout::Forever, 8, PollContext::Task),
        Err(Error::InvalidBudget)
    ));
    let mut spin = DriverPollBudget::iterations(3, PollContext::NoSleep).unwrap();
    assert_eq!(spin.step(None, true), PollOutcome::Stop);
    assert_eq!(spin.step(None, false), PollOutcome::Stop);
}
unsafe extern "C" fn state(out: *mut a::TimeState) {
    CALENDAR_CALLS.fetch_add(1, Ordering::Relaxed);
    unsafe {
        out.write(a::TimeState {
            monotonic_ticks: 1,
            monotonic_hz: 1,
            ..Default::default()
        });
    }
}
unsafe extern "C" fn ticks() -> u64 {
    123
}
unsafe extern "C" fn precise(out: *mut a::MonotonicClockInfo) -> i32 {
    let mode = MODE.load(Ordering::Relaxed);
    unsafe {
        out.write(a::MonotonicClockInfo {
            flags: if mode == 1 {
                0
            } else {
                a::monotonic_clock_flag_valid
            },
            frequency_hz: if mode == 2 {
                1_000_000
            } else {
                a::monotonic_clock_frequency_hz
            },
            instant_ns: 1_000_250_001,
            event_requested_hz: if mode == 5 { 250 } else { 1000 },
            event_effective_hz: if mode == 5 { 251 } else { 1001 },
            ..Default::default()
        });
    }
    match mode {
        3 => 0,
        4 => -13,
        _ => 1,
    }
}
fn with(table: &a::generation2::R4XStartR4Sys2, run: impl FnOnce(&App<'_>)) {
    let import = [a::R4XStartImport {
        group_id: 1,
        min_version: 2,
        resolved_version: 2,
        flags: a::r4xstart_import_flag_group_interface,
        module_name: c"R4SYS".as_ptr() as u64,
        symbol_name: c"Query2".as_ptr() as u64,
        table: table as *const _ as u64,
        ..Default::default()
    }];
    let raw = a::generation2::R4XStartContext2 {
        app_class: a::R4XStartAppClass::console.0,
        instance_id: 86,
        flags: a::r4xstart_flag_imports_valid,
        imports: import.as_ptr() as u64,
        import_count: 1,
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
    let expected = StartupInfo {
        profile: 0,
        app_class: a::R4XStartAppClass::console.0,
        required_groups: 2,
        imports: &imports,
    };
    let app = unsafe { App::from_raw(&raw, &expected, c"CLOCK") }.unwrap();
    run(&app);
}
#[test]
fn sub_tick_nanoseconds_require_valid_admission_and_never_substitute_ticks() {
    let mut table = a::generation2::R4XStartR4Sys2 {
        time_state: state as *const () as u64,
        monotonic_clock: precise as *const () as u64,
        ticks: ticks as *const () as u64,
        ..Default::default()
    };
    with(&table, |app| {
        let clock = Clock::new(app);
        let coarse = clock.state().unwrap();
        assert_eq!((coarse.monotonic_ticks, coarse.monotonic_hz), (1, 1));
        let calendar_calls = CALENDAR_CALLS.load(Ordering::Relaxed);
        MODE.store(0, Ordering::Relaxed);
        assert_eq!(clock.precise_instant().unwrap().nanoseconds, 1_000_250_001);
        for (mode, rate) in [(0, 1000), (5, 250)] {
            MODE.store(mode, Ordering::Relaxed);
            let current = clock.monotonic().unwrap();
            assert_eq!(current.event_requested_hz, rate);
            assert_eq!(clock.ticks().unwrap(), 123);
            assert_eq!(current.instant_ns, 1_000_250_001);
        }
        for mode in [1, 2] {
            MODE.store(mode, Ordering::Relaxed);
            assert!(matches!(
                clock.precise_instant(),
                Err(Error::InvalidProvider)
            ));
        }
        MODE.store(3, Ordering::Relaxed);
        assert!(matches!(clock.precise_instant(), Err(Error::Unavailable)));
        MODE.store(4, Ordering::Relaxed);
        assert!(matches!(clock.precise_instant(), Err(Error::Raw(-13))));
        assert_eq!(CALENDAR_CALLS.load(Ordering::Relaxed), calendar_calls);
    });
    table.monotonic_clock = 0;
    with(&table, |app| {
        assert!(matches!(
            Clock::new(app).precise_instant(),
            Err(Error::Raw(a::err_no_fn))
        ))
    });
    MODE.store(0, Ordering::Relaxed);
}
